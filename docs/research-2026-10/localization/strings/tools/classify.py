"""Turn candidate literals into the WOLF//OVERRIDE player-string inventory (i18n, research-strings).

Purpose: holds the human review of every candidate from candidates.py: which literals a player
reads, what class of text each is, what it inserts at run time, whether a gendered language
needs to know the engineer's gender to translate it, plurals, and whether the words are pixels in
a texture. It also adds the text that is not a GDScript or scene literal: the exported changelog,
the key names Godot generates, and the words painted into textures.

Contract:
    python3 -I classify.py <project_dir> <candidates.json> <out inventory.json> <out summary.json>
      <project_dir>  apps/game of origin/main (an archive copy; read only)
    inventory.json: one entry per string occurrence with
      path, line, class, text, dynamic (bool), inserts (list), gender_risk (bool),
      gender_langs (list of ISO 639-1 codes among es fr it pt de pl ru uk), gender_note,
      plural (bool), plural_note, baked ("no" | "label" | "pixels"), words, in_scope (bool),
      shown (bool), notes
    summary.json: per-class counts (strings, unique strings, words), totals, British spellings.

Gotchas:
  - Line numbers are at origin/main 1cf8d73. Classes for main.gd are given by line ranges
    (MAIN_CLASS); if main.gd changes, re-run extract_literals.py and re-check those ranges.
  - "words" counts what a translator translates: BBCode tags, %s/%d/{name} placeholders and a
    leading speaker tag ("WOLF:", "%s:") are not counted; a word is a whitespace-separated run
    with a letter or digit in it (DialogueBoxes.word_count also splits on spaces).
  - gender_risk is a reviewed judgement, written out per line in GENDER below with the reason;
    it is about the engineer (they/them, docs/decisions.md S1-03). WOLF is he/his and fixed
    masculine in every target language, so his lines carry no risk.
  - The changelog is one entry per non-empty line of assets/changelog.txt, which
    scripts/export_changelog.py writes from apps/docs/content/docs/changelog.mdx.
"""
from __future__ import annotations

import json
import re
import sys
from collections import Counter, defaultdict

# Literals the review found to be data, not player text: node, effect and property names,
# AudioServer bus ids used as config keys, glue formats, log-only push_warning messages.
EXCLUDE = {
    "scripts/bypass_handle.gd": {"Wheel"},
    "scripts/floor_reflection.gd": None,  # None: the whole file
    "scripts/fx_presets.gd": None,
    "scripts/room_depth.gd": None,
    "scripts/sentry.gd": None,
    "scripts/sfx_bank.gd": None,  # node names, a bus id and push_error/push_warning text
    "scripts/pause_overlay.gd": None,
    "scripts/studio_logo.gd": None,  # one push_warning
    "scripts/records_room.gd": {"Depth"},
    "scripts/junction_room.gd": {"Dent", "Depth", "Recesses", "Door", "Sentry", "Tank"},
    "scripts/game_settings.gd": {"FPSLabel", "FPSOptions", "Button",
                                 "Settings file is too large; using defaults.",
                                 "Settings file has unexpected content; using defaults.",
                                 "Settings file could not be read; using defaults."},
    "scripts/main.gd": {"Impact", "Glow", "Recap", "Accent", "[lb]", "[color=#73DDF5][b]%s[/b][/color]",
                        "[b]%s[/b]", "{name}", "%s\n%s", "%s / %s"},
}
EXCLUDE_LINES = {("scripts/game_settings.gd", 70), ("scripts/game_settings.gd", 122),
                 ("scripts/junction_room.gd", 471), ("scripts/main.gd", 4451)}

# main.gd classes by line (inclusive ranges, first match wins). Reviewed against the code.
MAIN_CLASS = [
    ((10, 10), "changelog_screen"), ((98, 98), "hint"), ((159, 160), "narration"),
    ((162, 163), "dialogue"), ((166, 166), "hint"), ((167, 167), "dialogue"), ((168, 168), "hint"),
    ((169, 171), "narration"), ((172, 176), "hint"), ((177, 180), "narration"), ((182, 182), "hint"),
    ((183, 183), "system_message"), ((184, 185), "title_menu"), ((188, 188), "system_message"),
    ((191, 191), "narration"), ((192, 193), "death_card"), ((196, 202), "opening"),
    ((227, 241), "end_card"), ((243, 247), "title_menu"), ((249, 249), "dialogue"),
    ((251, 257), "narration"), ((258, 264), "dialogue"), ((267, 268), "narration"),
    ((269, 272), "dialogue"), ((276, 277), "narration"), ((278, 278), "dialogue"),
    ((280, 281), "narration"), ((344, 346), "death_card"), ((399, 399), "choice"),
    ((403, 407), "narration"), ((414, 414), "dialogue"), ((417, 418), "hint"),
    ((425, 426), "dialogue"), ((430, 440), "refusal"), ((455, 456), "dialogue"),
    ((559, 559), "dialogue"), ((828, 828), "window_title"), ((950, 950), "changelog_screen"),
    ((1237, 1237), "dialogue"), ((1640, 1640), "choice"), ((1795, 1830), "credits_screen"),
    ((1863, 1883), "settings"), ((1885, 1885), "pause_menu"), ((1923, 1923), "settings"),
    ((2002, 2004), "pause_menu"), ((2184, 2184), "system_message"), ((2239, 2254), "restore_line"),
    ((2283, 2283), "dialogue"), ((2293, 2293), "narration"), ((2333, 2333), "narration"),
    ((2344, 2347), "dialogue"), ((2359, 2362), "narration"), ((2367, 2378), "dialogue"),
    ((2389, 2403), "narration"), ((2459, 2459), "dialogue"), ((2469, 2469), "narration"),
    ((2480, 2481), "dialogue"), ((2490, 2490), "system_message"), ((2499, 2501), "system_message"),
    ((2508, 2517), "narration"), ((2523, 2523), "dialogue"), ((2551, 2551), "narration"),
    ((2588, 2591), "hint"), ((2790, 2790), "dialogue"), ((2800, 2802), "narration"),
    ((2887, 2921), "narration"), ((3092, 3092), "narration"), ((3181, 3181), "dialogue"),
    ((3445, 3445), "dialogue"), ((3558, 3610), "narration"), ((4343, 4343), "end_card"),
    ((4346, 4346), "hud_button"), ((4352, 4352), "touch_ui"), ((4358, 4369), "tutorial"),
    ((4377, 4377), "top_card"), ((4378, 4381), "hint"), ((4387, 4387), "top_card"),
    ((4389, 4389), "hint"), ((4407, 4418), "top_card"), ((4425, 4470), "prompt_token"),
    ((4462, 4462), "speaker_tag"), ((4800, 4800), "choice"), ((4885, 5024), "hint"),
    ((5030, 5058), "objective"),
]

# Engineer gender review (they/them engineer; targets es fr it pt de pl ru uk). Keyed by a unique
# substring of the English. Value: (languages, reason).
SLAVIC = ["pl", "ru", "uk"]
ALL8 = ["es", "fr", "it", "pt", "de", "pl", "ru", "uk"]
PAST = "past-tense verb with the engineer as subject agrees in gender (pl zostawił/zostawiła, ru оставил/оставила, uk залишив/залишила)"
YOU_PAST = "WOLF addresses the engineer in the past tense; the verb agrees with 'you' (pl powiedziałeś/powiedziałaś, ru сказал/сказала, uk сказав/сказала)"
NAME_CASE = "the name is inserted as an object; pl/ru/uk decline it, and how (Rowan -> Rowana / Рована, or left undeclined) depends on the name's grammatical gender"
GENDER = {
    "The handle holds where %s left it.": (SLAVIC, PAST),
    "{name} told WOLF the risk. WOLF took": (SLAVIC, PAST),
    "{name} told WOLF the risk, then cranked": (SLAVIC, PAST),
    "{name} rushed WOLF.": (SLAVIC, PAST),
    "{name} copied the timestamp": (SLAVIC, PAST),
    "so {name} timed the drop alone.": (["es", "fr", "it", "pt", "pl", "ru", "uk"], PAST + "; 'alone' is an adjective in es solo/sola, fr seul/seule, it da solo/da sola, pt sozinho/sozinha, pl sam/sama, ru один/одна (de allein is invariant)"),
    "WOLF held back while {name} timed the drop.": (SLAVIC, PAST),
    "WOLF broke off while {name} timed the drop.": (SLAVIC, PAST),
    "You told me the truth at the relay.": (SLAVIC, YOU_PAST),
    "you'd have sent me in blind.": (SLAVIC, "conditional addressed to the engineer agrees in gender (pl wysłałbyś/wysłałabyś, ru отправил(а) бы, uk відправив/відправила б)"),
    "I refused. You found another way.": (SLAVIC, YOU_PAST + " (said, found)"),
    "I chose the relay. We made it.": (SLAVIC, YOU_PAST + " (You said)"),
    "I made my call. You cranked the bypass anyway.": (SLAVIC, YOU_PAST + " (said, cranked)"),
    "I took the relay because you told me the truth.": (SLAVIC, YOU_PAST),
    "I offered the relay; you cranked the bypass.": (SLAVIC, YOU_PAST),
    "Thank you for telling me.": (SLAVIC, "natural renderings use a past verb for the engineer (ru спасибо, что сказал(а); pl dzięki, że powiedziałeś/powiedziałaś); avoidable with a noun phrase"),
    "crank it yourself, or let WOLF": (["ru", "uk", "pl"], "'yourself' is usually rendered with a gendered emphatic pronoun (ru сам/сама, uk сам/сама, pl sam/sama); avoidable by rewording"),
    "%s\nMAINTENANCE ENGINEER": (ALL8, "job title is a gendered noun: es ingeniero/ingeniera, fr ingénieur/ingénieure, it ingegnere/ingegnera, pt engenheiro/engenheira, de Wartungsingenieur/Wartungsingenieurin, uk інженер/інженерка; pl inżynier and ru инженер default to the masculine form for everyone"),
    "The relief vent let go under %s.": (SLAVIC, NAME_CASE + " (instrumental: pl pod Rowanem)"),
    "The door went with %s in front of it.": (SLAVIC, NAME_CASE + " (instrumental: pl przed Rowanem)"),
    "The sentry saw %s out in the open.": (SLAVIC, NAME_CASE + " (accusative)"),
    "The sentry ran %s down.": (SLAVIC, NAME_CASE + " (accusative)"),
    "The coolant cloud caught %s.": (SLAVIC, NAME_CASE + " (accusative)"),
    "It has %s; get back over the rubble.": (SLAVIC, NAME_CASE + " (accusative)"),
    "The sentry loses %s behind the rubble": (SLAVIC, NAME_CASE + " (accusative)"),
    "to wait for %s's call.": (SLAVIC, NAME_CASE + " (genitive possessive)"),
}
# Lines that read as the engineer but carry no gender in the eight languages (kept for the record).
NO_GENDER_NOTE = {
    "%s keeps WOLF's systems running.": "present tense; no agreement",
    "%s knows what a fault looks like": "present tense; no agreement",
    "%s keeps a local copy": "present tense; no agreement",
    "%s copies the timestamp through": "present tense; no agreement",
    "WOLF: %s. That name sounds like you.": "no agreement",
}

PLURAL = {
    "HOLD E: crank the valve, %d of %d turns.": "counted noun after a number ('turns'); pl/ru/uk pick the noun form from the number (here the total, PressureLine.TURNS_NEEDED = 3, which is fixed)",
    "The valve gives. %d of %d turns.": "counted noun after a number ('turns'); see above",
}

TOKEN_NOTE = ("the hint bar rewrites the English 'E:' / 'HOLD E:' prefix at run time into the bound "
              "key or button (main.gd _refresh_ui: hint.replace), so a translation must keep that exact token")


def words(text: str) -> int:
    t = re.sub(r"\[[^\]]*\]", " ", text)
    t = re.sub(r"%[sd%]|\{name\}", " ", t)
    t = re.sub(r"^(WOLF|DIRECTOR / PURGE|DIRECTOR|%s): ", "", t)
    return sum(1 for w in t.split() if re.search(r"[A-Za-z0-9]", w))


def main_class(line: int) -> str:
    for (lo, hi), cls in MAIN_CLASS:
        if lo <= line <= hi and not (cls == "prompt_token" and line == 4462):
            return cls
    return "unclassified"


def scene_class(ctx: str) -> str:
    node = ctx.rsplit(".", 1)[0]
    if node.endswith("/Tag"):
        return "actor_tag_hidden"
    for key, cls in (("CreditsBody", "credits"), ("CreditsScreen", "credits_screen"), ("ChangelogScreen", "changelog_screen"),
                     ("TitleScreen", "title_menu"), ("PauseMenu", "pause_menu"), ("SettingsMenu", "settings"),
                     ("TouchControls", "touch_ui"), ("TutorialPrompt", "tutorial"), ("PauseButton", "hud_button")):
        if key in node:
            return cls
    return "station_label"


def classify_literal(e: dict) -> str:
    p, line, text = e["path"], e["line"], e["text"]
    if p == "scenes/studio_logo.tscn":
        return "studio_logo"
    if p == "scenes/main.tscn":
        return scene_class(e["context"])
    if p == "scripts/main.gd":
        return main_class(line)
    if p == "scripts/game_settings.gd":
        if line == 8:
            return "input_action_name"
        if 520 <= line <= 560:
            return "input_name"
        return "settings"
    if p == "scripts/junction_room.gd":
        return "death_card" if 394 <= line <= 403 else "station_label"
    if p in ("scripts/records_room.gd", "scripts/bypass_handle.gd"):
        return "station_label"
    if p == "scripts/m0_state.gd":
        return {10: "engineer_name", 21: "choice", 22: "choice"}.get(line, "dialogue")
    return "unclassified"


def inserts_of(e: dict, cls: str) -> list[str]:
    """What a literal splices in at run time (reviewed per call site in main.gd and friends)."""
    t, line = e["text"], e["line"]
    out = []
    if "{name}" in t:
        out.append("engineer_first_name")
    if t.startswith("%s: ") or "\n%s: " in t:
        out.append("engineer_first_name_upper (as the speaker tag)")
    special = {
        159: ["engineer_first_name"], 160: ["engineer_first_name"], 171: ["engineer_first_name"],
        172: ["number", "number"], 176: ["number", "number"], 256: ["engineer_first_name"],
        344: ["key_or_button_name"], 405: ["engineer_first_name"], 406: ["engineer_first_name"],
        456: ["concatenated: WOLF_DOOR_WARNING (main.gd 455)"],
        1237: ["engineer_full_name"], 1640: ["line: RELAY_QUESTION", "choice_text x2 (quoted)"],
        1871: ["number", "number"], 2004: ["key_or_button_name"],
        2254: ["concatenated: M0State.checkpoint_callback()"], 2499: ["concatenated: M0State.checkpoint_callback()"],
        2481: ["line fragment chosen from main.gd 2480"], 2508: ["engineer_first_name"],
        2802: ["engineer_first_name"], 3445: ["choice_text x2 (quoted)"], 3591: ["number", "number"],
        4343: ["key_or_button_name"], 4360: ["key_name x2"], 4361: ["key_or_button_name"],
        4364: ["line: move label"], 4369: ["line: read label"],
        4378: ["key_or_button_name x2"], 4381: ["key_or_button_name"], 4389: ["key_or_button_name"],
        4407: ["engineer_full_name_upper"], 4468: ["key_or_button_name"], 4470: ["key_or_button_name"],
        4953: ["number", "number"],
    }
    # A line can hold a placeholder literal and a fixed one ("TAP CONTINUE" if touch else "%s  CONTINUE");
    # only the literal with a placeholder, or a concatenation site, takes the line's inserts.
    concat = line in (456, 2254, 2499)
    if e["path"] == "scripts/main.gd" and line in special and not out and ("%" in t or concat):
        out.extend(special[line])
    if e["path"] == "scripts/m0_state.gd" and "%s" in t:
        out.append("saved_choice_text (the English the player saw, read back from the save)")
    if e["path"] == "scripts/junction_room.gd" and "%s" in t:
        out.append("engineer_first_name")
    if e["path"] == "scripts/junction_room.gd" and "%d" in t:
        out.extend(["number", "number"])
    if e["path"] == "scripts/game_settings.gd":
        out.extend({234: ["bus_name (AudioServer bus id shown as text)"],
                    420: ["input_kind_id ('keyboard'/'controller', an internal id shown as text)", "action_name"],
                    450: ["action_name (or the action id with '_' -> ' ' as fallback)"],
                    524: ["number"], 546: ["number", "sign"], 559: ["number"], 397: ["line", "line"]}.get(e["line"], []))
    if t.startswith(("E: ", "HOLD E: ")) or "Press E" in t or "press 2" in t:
        out.append("key_or_button_name (replaces the English 'E'/'2' token)")
    return out


def gender_of(text: str):
    for key, (langs, why) in GENDER.items():
        if key in text:
            return True, langs, why
    for key, why in NO_GENDER_NOTE.items():
        if key in text:
            return False, [], why
    return False, [], ""


def entry(path, line, cls, text, *, dynamic=False, inserts=(), baked="no", in_scope=True, shown=True, notes=""):
    g, langs, why = gender_of(text)
    plural_note = next((v for k, v in PLURAL.items() if k in text), "")
    return {
        "path": path, "line": line, "class": cls, "text": text, "dynamic": bool(dynamic or inserts),
        "inserts": list(inserts), "gender_risk": g, "gender_langs": langs, "gender_note": why,
        "plural": bool(plural_note), "plural_note": plural_note, "baked": baked,
        "words": words(text), "in_scope": in_scope, "shown": shown, "notes": notes,
    }


def notes_for(e: dict, cls: str) -> str:
    t = e["text"]
    n = []
    if cls == "prompt_token":
        n.append("English pattern that _refresh_ui/_shown_line search for and replace; it never shows alone")
    if cls == "speaker_tag":
        n.append("shown in the speaker column; also parsed out of 'TAG: words' by DialogueBoxes.tag_of")
    if t.startswith(("E: ", "HOLD E: ")):
        n.append(TOKEN_NOTE)
    if re.match(r"^(WOLF|DIRECTOR|%s): ", t) or "\nWOLF: " in t or ". WOLF: " in t:
        n.append("speaker tags are inline ('WOLF: ...') and split off by DialogueBoxes; a translation must keep 'TAG: ' (French typography would put a space before the colon)")
    if "\n" in t and cls not in ("credits", "changelog"):
        n.append("hand-placed line break(s) for the English row lengths")
    if re.match(r"^[A-Z]+  ", t) and cls == "end_card":
        n.append("row is split at the first double space into TOPIC and text (main.gd _show_end_card)")
    if e["path"] == "scenes/main.tscn" and e["line"] in (418, 473, 482):
        n.append("scene placeholder; main.gd overwrites it at run time")
    if cls == "engineer_name":
        n.append("provisional display name (docs/game-bible.md); names are not translated but are inflected in pl/ru/uk")
    if cls == "credits":
        n.append("one BBCode RichTextLabel blob; personal and product names stay as written")
    if cls == "input_action_name" and e["text"] in ("Master", "Music", "Effects", "Voice"):
        pass
    if e["path"] == "scripts/game_settings.gd" and e["line"] == 9:
        n.append("AudioServer bus name doubles as the slider label ('%s volume')")
    if cls == "station_label":
        n.append("live Label styled as a plate in the world, not pixels; TextSize.world_factor caps its growth at 150% and _fit_label fits it")
    return "; ".join(n)


def main(project: str, cand_path: str, out_path: str, summary_path: str) -> None:
    cands = json.load(open(cand_path, encoding="utf-8"))
    inv = []
    for e in cands:
        p, text = e["path"], e["text"]
        if e["debug"]:
            inv.append(entry(p, e["line"], "debug", text, in_scope=False, notes="debug tools; out of scope"))
            continue
        ex = EXCLUDE.get(p, set())
        if p in EXCLUDE and (ex is None or text in ex):
            continue
        if (p, e["line"]) in EXCLUDE_LINES:
            continue
        if p == "scripts/game_settings.gd" and e["line"] == 9:
            cls = "settings"
        else:
            cls = classify_literal(e)
        ins = inserts_of(e, cls)
        dyn = bool(ins) or "%" in text or cls == "prompt_token"
        shown = cls != "actor_tag_hidden"
        inv.append(entry("apps/game/" + p, e["line"], cls, text, dynamic=dyn, inserts=ins, shown=shown,
                         baked="label" if cls == "station_label" else "no", notes=notes_for(e, cls)))
    # The in-game changelog: exported text, one entry per line.
    with open(f"{project}/assets/changelog.txt", encoding="utf-8") as fh:
        for i, row in enumerate(fh.read().split("\n"), 1):
            if row.strip():
                inv.append(entry("apps/game/assets/changelog.txt", i, "changelog", row,
                                 notes="exported by scripts/export_changelog.py from apps/docs/content/docs/changelog.mdx; dates in US form"
                                 + ("; mentions 'the engineer' (gendered noun in es fr it pt de pl ru uk)" if re.search(r"\bengineer", row) else "")))
                if re.search(r"\bengineer", row):
                    inv[-1].update(gender_risk=True, gender_langs=ALL8,
                                   gender_note="'the engineer' is a gendered noun and they/their pronouns have no neutral equivalent in these languages")
    # Key names the engine generates (OS.get_keycode_string on the physical keycode; US QWERTY names
    # in English whatever the layout or language): the default bindings from main.gd _install_inputs.
    for key in ("A", "D", "Left", "Right", "E", "1", "2", "Escape"):
        inv.append(entry("godot:core/os/keyboard.cpp", 0, "input_name", key, dynamic=True,
                         notes="generated by OS.get_keycode_string(physical_keycode) in game_settings.gd prompt()/binding_label(); English names and US QWERTY labels (AZERTY shows A for the key printed Q); DisplayServer.keyboard_get_label_from_physical gives the printed label"))
    # Words painted into textures (checked by eye on every room plate and prop, 2026-10-16).
    for text, region in (("DOOR 4B-07", "hood stencil, atlas about x 60-260 y 55-130 (CORRIDOR_SEAL_FRAME_REGION)"),
                         ("SECTOR 4B", "wall stencil, atlas about x 760-855 y 80-110 (CORRIDOR_SEAL_WALL_REGION)"),
                         ("RESTRICTED AREA", "plate, atlas about x 765-880 y 160-195 (CORRIDOR_SEAL_WALL_REGION)")):
        inv.append(entry("apps/game/assets/props/corridor-seal-atlas.png", 0, "baked_art", text, baked="pixels",
                         notes=f"{region}; typeset in Roboto by the door tools (manifest entry corridor-seal-atlas), not by the image tool"))
    json.dump(inv, open(out_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    scope = [e for e in inv if e["in_scope"] and e["shown"]]
    by = defaultdict(lambda: {"strings": 0, "unique": set(), "words": 0, "unique_words": 0, "dynamic": 0, "gender_risk": 0, "plural": 0})
    for e in scope:
        b = by[e["class"]]
        b["strings"] += 1
        if e["text"] not in b["unique"]:
            b["unique"].add(e["text"])
            b["unique_words"] += e["words"]
        b["words"] += e["words"]
        b["dynamic"] += e["dynamic"]
        b["gender_risk"] += e["gender_risk"]
        b["plural"] += e["plural"]
    classes = {k: {**{kk: vv for kk, vv in v.items() if kk != "unique"}, "unique": len(v["unique"])} for k, v in sorted(by.items())}
    uniq = {}
    for e in scope:
        uniq.setdefault(e["text"], e["words"])
    brit = re.compile(r"\b(centre\w*|colou?r\w*|neighbour\w*|behaviour\w*|favour\w*|honour\w*|grey|metres?|litres?|licence|defence|\w+is(e|ed|es|ing|ation)|cancelled|travell\w+|labelled|modelled|towards|programme|whilst|amongst|analyse\w*|catalogue|judgement|galvanis\w*|vapour|aluminium|practise)\b", re.I)
    british = Counter()
    where = defaultdict(list)
    for e in scope:
        for m in brit.finditer(e["text"]):
            w = m.group(0)
            if re.fullmatch(r"(?i)(otherwise|raise\w*|rise[sn]?|noise\w*|wise|precise\w*|exercise\w*|promise\w*|surprise\w*|advise\w*|revise\w*|devise\w*|comprise\w*|concise|disguise\w*|cruise\w*|praise\w*|poise\w*|premise\w*|franchise|expertise|enterprise|televise\w*|supervise\w*|improvise\w*|chastise\w*|despise\w*|arise\w*|paradise|merchandise|demise|compromise\w*|excise|incise\w*|apprise\w*|reprise|clockwise|likewise|anticlockwise|counterclockwise|color\w*)", w):
                continue
            british[w.lower()] += 1
            where[w.lower()].append(f"{e['path']}:{e['line']}")
    summary = {
        "classes": classes,
        "in_scope_strings": len(scope), "in_scope_unique": len(uniq),
        "in_scope_words": sum(e["words"] for e in scope), "in_scope_unique_words": sum(uniq.values()),
        "without_changelog": {
            "strings": sum(1 for e in scope if e["class"] != "changelog"),
            "unique": len({e["text"] for e in scope if e["class"] != "changelog"}),
            "unique_words": sum(w for t, w in uniq.items() if t not in {e["text"] for e in scope if e["class"] == "changelog"}),
        },
        "debug_strings": sum(1 for e in inv if e["class"] == "debug"),
        "hidden_strings": sum(1 for e in inv if not e["shown"]),
        "british_spellings": {w: {"count": c, "where": where[w][:12]} for w, c in british.most_common()},
        "gender_lines": [f"{e['path']}:{e['line']} {e['text'][:90]!r} -> {','.join(e['gender_langs'])}" for e in scope if e["gender_risk"] and e["class"] != "changelog"],
        "gender_changelog_lines": sum(1 for e in scope if e["gender_risk"] and e["class"] == "changelog"),
        "unclassified": [f"{e['path']}:{e['line']} {e['text'][:60]!r}" for e in inv if e["class"] == "unclassified"],
    }
    json.dump(summary, open(summary_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(json.dumps({k: summary[k] for k in ("in_scope_strings", "in_scope_unique", "in_scope_words", "in_scope_unique_words", "without_changelog", "debug_strings", "hidden_strings")}))


if __name__ == "__main__":
    main(*sys.argv[1:5])
