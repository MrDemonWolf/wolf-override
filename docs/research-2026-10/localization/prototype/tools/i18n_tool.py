#!/usr/bin/env python3
"""The i18n prototype's one Python tool: the font subset, the PO files, their checks and the counts.

Purpose
    Every step of the prototype that is not a Godot run lives here once, as a subcommand:

    potfiles GAME             prints project.godot's translations_pot_files line for GAME (apps/game):
                              every scene and script the player can meet (tests, tools and the debug
                              tools are left out; the debug strings are out of scope per the strings step).
    subset SRC OUT TRANS      writes OUT, a subset of the OpenType font SRC (Noto Sans JP) holding
                              printable ASCII, kana, CJK punctuation, full-width forms, "日本語" (the
                              language list's own name) and every character of TRANS's "ja" texts;
                              prints its size next to SRC's and a JIS X 0208 level-1 subset's (measure).
    fill POT TRANS OUTDIR     writes OUTDIR/<lang>.po for every language in TRANS from the POT: each
                              message keeps the POT's comments and gets TRANS's context as a "#." note
                              and its translation, stamped "# machine-translated by Claude, unreviewed".
    backprompt PODIR OUT      writes the Codex back-translation prompt: the translated texts only, by id,
                              with no English, so the back-translation is independent.
    check POT PODIR BACK OUT  every automated gate on the PO files, as JSON at OUT: msgfmt --check-format,
                              the research-pipeline step's per-line measures (placeholders, speaker tag,
                              line breaks, glossary; ../../pipeline/tools/trial.py, imported, not copied),
                              the "E:" key token the hint bar replaces, the script guard (no letters of
                              another script; see SCRIPT_GUARD), and chrF of Codex's back-translation
                              (BACK, JSON) against the English.
    hardcoded POT INVENTORY OUT
                              player-facing strings of the strings step's inventory (in scope and shown)
                              whose text is no msgid of POT, by file, as JSON at OUT.

Contract
    python3 -I tools/i18n_tool.py <subcommand> ...   (stdlib only; `subset` needs hb-subset, `check`
    needs msgfmt, both from Homebrew). Paths are arguments; nothing outside them is written.
    TRANS is translations/claude.json: {"context": {msgid: note}, "translations": {lang: {msgid: text}}}.

Gotchas
    - The PO parser here reads what Godot's generator and this tool write (msgctxt, msgid, msgid_plural,
      msgstr, msgstr[n], comments, continued strings); it is not a general gettext parser.
    - Godot reads "Language:" from the PO header and drops an empty "Plural-Forms:" with an error
      (core/string/plural_rules.cpp), so the header always carries the language's real rule.
    - "es" is Latin-American Spanish: Godot reduces es-419 to "es" (see I18n.LANGUAGES), but the glossary
      and style packet name it es-419, so the checker maps it back.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
PIPELINE_TOOLS = HERE.parent.parent / "pipeline" / "tools"
sys.path.insert(0, str(PIPELINE_TOOLS))
import trial  # noqa: E402  (the research-pipeline step's measures: chrf, check_line, PLACEHOLDER)

#: gettext Plural-Forms per language (CLDR; the same rules Godot's core/string/locales.h holds). Russian
#: has three forms (1, 21 / 2-4, 22-24 / 0, 5-20, 11-14), which the design step added with ru.
PLURALS = {"es": "nplurals=2; plural=(n != 1);", "de": "nplurals=2; plural=(n != 1);", "ja": "nplurals=1; plural=0;",
           "ru": "nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);"}
#: The style packet's and glossary's names for the PO languages.
GLOSSARY_LANG = {"es": "es-419", "de": "de", "ja": "ja", "ru": "ru"}
#: Languages written in Cyrillic; every other language here is written in Latin letters or in Japanese.
CYRILLIC_LANGS = {"ru"}
#: The script guard, ported once from ConPaws' locales-script test (written there after a Russian word
#: slipped into its pt-BR file): a Latin-script or Japanese text holds no Cyrillic letter, and a Cyrillic
#: text holds no Latin letter outside the glossary's "keep" words (WOLF, the "E:" key token, the studio
#: and person names, placeholders), which stay as written in every language. It catches look-alike swaps
#: both ways; a Cyrillic "Е:" for the key token passes it (no Latin letter is left) but fails key_token_ok,
#: since the hint bar replaces only the Latin "E:".
SCRIPT_GUARD = {"cyrillic": re.compile(r"[\u0400-\u04FF]"), "latin": re.compile(r"[A-Za-z]")}
#: Ranges every Japanese subset keeps whatever the texts use: printable ASCII, CJK symbols and
#: punctuation, hiragana, katakana, half- and full-width forms (so a later line's kana never tofus).
JA_BASE_RANGES = [(0x20, 0x7E), (0x3000, 0x303F), (0x3040, 0x309F), (0x30A0, 0x30FF), (0xFF00, 0xFFEF)]
#: The language list's own Japanese name (I18n.LANGUAGES), drawn in every language.
JA_ALWAYS = "日本語"
#: The hint bar replaces "E:" with the bound key (main.gd _refresh_ui), so it must survive. Counted only
#: where no letter comes before it: "PAUSE:" ends in "E:" too (the game's own replace is a plain
#: substring replace and would hit it; see PROTOTYPE.md).
KEY_TOKEN = re.compile(r"(?<![^\W\d_])E:")
#: Skipped by `potfiles`: tests and the debug tools (out of scope), and anything outside scenes/scripts.
POT_SKIP = ("scripts/debug/",)


# ------------------------------------------------------------------------------------------- PO files

def _unquote(text: str) -> str:
    """A PO string literal's contents, unescaped (\\n, \\t, \\", \\\\)."""
    return json.loads(text) if text.startswith('"') else text


def read_po(path: Path) -> list[dict]:
    """Every entry of the PO/POT at ``path``: {"comments": [...], "msgctxt", "msgid", "msgid_plural",
    "msgstr": [..]}; the header is the entry whose msgid is ""."""
    entries: list[dict] = []
    entry: dict = {"comments": [], "msgstr": []}
    field = None
    for raw in path.read_text(encoding="utf-8").splitlines() + [""]:
        line = raw.strip()
        if not line:
            if "msgid" in entry:
                entries.append(entry)
            entry, field = {"comments": [], "msgstr": []}, None
            continue
        if line.startswith("#"):
            entry["comments"].append(line)
            continue
        match = re.match(r'^(msgctxt|msgid_plural|msgid|msgstr(?:\[\d+\])?)\s+(".*")$', line)
        if match:
            field, value = match.group(1), _unquote(match.group(2))
            if field.startswith("msgstr"):
                entry["msgstr"].append(value)
            else:
                entry[field] = value
        elif line.startswith('"') and field:
            if field.startswith("msgstr"):
                entry["msgstr"][-1] += _unquote(line)
            else:
                entry[field] += _unquote(line)
    return entries


def _quote(text: str) -> str:
    """``text`` as a PO string literal, split after each \\n as gettext tools do."""
    if "\n" not in text[:-1]:
        return json.dumps(text, ensure_ascii=False)
    parts = text.split("\n")
    pieces = [part + "\n" for part in parts[:-1]] + ([parts[-1]] if parts[-1] else [])
    return '""\n' + "\n".join(json.dumps(piece, ensure_ascii=False) for piece in pieces)


def write_entry(entry: dict) -> str:
    """One PO entry as text (comments, then msgctxt/msgid/msgid_plural/msgstr)."""
    out = list(entry["comments"])
    if "msgctxt" in entry:
        out.append("msgctxt " + _quote(entry["msgctxt"]))
    out.append("msgid " + _quote(entry["msgid"]))
    if "msgid_plural" in entry:
        out.append("msgid_plural " + _quote(entry["msgid_plural"]))
        out += [f"msgstr[{i}] " + _quote(text) for i, text in enumerate(entry["msgstr"])]
    else:
        out.append("msgstr " + _quote(entry["msgstr"][0] if entry["msgstr"] else ""))
    return "\n".join(out)


def messages(path: Path) -> dict[str, dict]:
    """The entries of a PO/POT by msgid, header left out."""
    return {e["msgid"]: e for e in read_po(path) if e["msgid"]}


# ---------------------------------------------------------------------------------------- subcommands

def potfiles(game: Path) -> None:
    """Prints the translations_pot_files setting for every player-facing scene and script of ``game``."""
    files = sorted(p.relative_to(game).as_posix() for p in list(game.glob("scenes/*.tscn")) + list(game.glob("scripts/**/*.gd")))
    kept = [f"res://{f}" for f in files if not f.startswith(POT_SKIP)]
    print("locale/translations_pot_files=PackedStringArray(" + ", ".join(json.dumps(f) for f in kept) + ")")


def subset(src: Path, out: Path, trans: Path) -> None:
    """Writes the Japanese fallback subset and prints its size against the full font and a JIS L1 set."""
    texts = json.loads(trans.read_text(encoding="utf-8"))["translations"]["ja"].values()
    used = {ord(c) for text in texts for c in text if c != "\n"} | {ord(c) for c in JA_ALWAYS}
    base = {cp for lo, hi in JA_BASE_RANGES for cp in range(lo, hi + 1)}
    kanji = sorted(cp for cp in used if cp not in base)
    _hb_subset(src, out, base | used)
    # Measure only: JIS X 0208 level-1 kanji (EUC-JP rows 0xB0-0xCF), the usual "everyday" set.
    level1 = set()
    for row in range(0xB0, 0xD0):
        for cell in range(0xA1, 0xFF):
            try:
                level1.add(ord(bytes([row, cell]).decode("euc_jp")))
            except UnicodeDecodeError:
                pass
    measure = out.with_name(out.stem + "-jis-l1-measure" + out.suffix)
    _hb_subset(src, measure, base | used | level1)
    print(json.dumps({
        "source_bytes": src.stat().st_size, "subset_bytes": out.stat().st_size, "subset_codepoints": len(base | used),
        "codepoints_beyond_base_in_texts": len(kanji), "kanji_not_in_jis_l1": "".join(chr(c) for c in kanji if c not in level1),
        "jis_l1_kanji": len(level1), "jis_l1_subset_bytes": measure.stat().st_size,
    }, ensure_ascii=False, indent=1))
    measure.unlink()


def _hb_subset(src: Path, out: Path, codepoints: set[int]) -> None:
    """hb-subset of ``src`` to ``out`` keeping ``codepoints`` (glyph names dropped, layout kept)."""
    unicodes = ",".join(f"{cp:04X}" for cp in sorted(codepoints))
    subprocess.run(["hb-subset", f"--output-file={out}", f"--unicodes={unicodes}", str(src)], check=True)


def fill(pot: Path, trans: Path, outdir: Path) -> None:
    """Writes one PO per language from the POT and the translations file."""
    data = json.loads(trans.read_text(encoding="utf-8"))
    entries = read_po(pot)
    outdir.mkdir(parents=True, exist_ok=True)
    for lang, texts in data["translations"].items():
        unused = set(texts) - {e["msgid"] for e in entries}
        if unused:
            sys.exit(f"{lang}: translations for msgids the POT lacks: {sorted(unused)}")
        out = []
        for entry in entries:
            if not entry["msgid"]:
                header = ("Project-Id-Version: WOLF//OVERRIDE i18n prototype\\n", "PO-Revision-Date: 2026-10-16 00:00+0000\\n",
                          "Last-Translator: Claude (Anthropic), machine translation, unreviewed\\n", "Language-Team: none\\n", "MIME-Version: 1.0\\n",
                          "Content-Type: text/plain; charset=UTF-8\\n", "Content-Transfer-Encoding: 8bit\\n",
                          f"Language: {lang}\\n", f"Plural-Forms: {PLURALS[lang]}\\n")
                out.append("# Sample translations for the scratch prototype (proof only; not reviewed).\n"
                           'msgid ""\nmsgstr ""\n' + "\n".join(f'"{h}"' for h in header))
                continue
            # A plural entry gets one msgstr per plural form of the language (its PLURALS nplurals).
            forms = int(PLURALS[lang].split(";")[0].split("=")[1]) if "msgid_plural" in entry else 1
            done = dict(entry, comments=list(entry["comments"]), msgstr=[""] * forms)
            if re.search(r"%[sd]", entry["msgid"]) and not any(c.startswith("#,") for c in done["comments"]):
                # Godot's generator writes no format flag; with it msgfmt --check-format compares the
                # translation's %s/%d with the msgid's (the pipeline step's msgfmt gate).
                done["comments"].append("#, c-format")
            note = data["context"].get(entry["msgid"])
            if note:
                done["comments"].insert(0, f"#. TRANSLATORS: {note}")
            if entry["msgid"] in texts:
                done["comments"].insert(0, "# machine-translated by Claude (Anthropic), unreviewed")
                done["msgstr"] = [texts[entry["msgid"]]]
            out.append(write_entry(done))
        (outdir / f"{lang}.po").write_text("\n\n".join(out) + "\n", encoding="utf-8")
        print(f"{lang}.po: {len(texts)} of {len(entries) - 1} messages translated")


def backprompt(podir: Path, out: Path) -> None:
    """The Codex prompt: back-translate every translated message, given without its English."""
    items = {}
    for po in sorted(podir.glob("*.po")):
        lang = po.stem
        for index, entry in enumerate(e for e in read_po(po) if e["msgid"] and e["msgstr"] and e["msgstr"][0]):
            items[f"{lang}-{index:02d}"] = {"language": GLOSSARY_LANG[lang], "text": entry["msgstr"][0]}
    out.write_text(
        "You are checking game UI and dialogue translations by back-translating them. Translate each text below "
        "into plain, literal English, keeping placeholders (%s, %d), the token 'E:' and line breaks (\\n) exactly "
        "as they appear. Do not guess what the original English was; translate only what is written. Context: a "
        "2D sci-fi game; WOLF is a robot wolf (he), the Director a human (he), the player character is a "
        "non-binary engineer whose first name fills %s. After each back-translation add 'notes' listing anything "
        "ambiguous, unidiomatic or gendered in the source text (empty string if none). Answer with JSON only: "
        '{"back": {"<id>": {"english": "...", "notes": "..."}}}. Do not run any commands or read any files.\n\n'
        + json.dumps(items, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"{len(items)} texts in {out}")


def script_ok(text: str, lang: str, keep: list[str]) -> bool:
    """The script guard (SCRIPT_GUARD) for one translation ``text`` in ``lang``."""
    if lang not in CYRILLIC_LANGS:
        return not SCRIPT_GUARD["cyrillic"].search(text)
    for word in sorted(keep, key=len, reverse=True):
        text = text.replace(word, "")
    return not SCRIPT_GUARD["latin"].search(text)


def check(pot: Path, podir: Path, back: Path, out: Path) -> None:
    """Runs every automated gate on the PO files and writes the report."""
    glossary = trial.load("glossary.json")
    fonts = trial.Fonts()
    backs = json.loads(back.read_text(encoding="utf-8"))["back"] if back.exists() else {}
    report: dict = {"pot_messages": len(messages(pot)), "languages": {}}
    for po in sorted(podir.glob("*.po")):
        lang = po.stem
        fmt = subprocess.run(["msgfmt", "--check-format", "--check-header", "-o", "/dev/null", "--statistics", str(po)],
                             capture_output=True, text=True)
        rows = []
        translated = [e for e in read_po(po) if e["msgid"] and e["msgstr"] and e["msgstr"][0]]
        for index, entry in enumerate(translated):
            english, text = entry["msgid"], entry["msgstr"][0]
            measures = trial.check_line({"text": english, "surface": "dialogue"}, text, GLOSSARY_LANG[lang], glossary, fonts)
            measures.pop("missing_glyphs", None)  # the game's own glyph test (i18n_test.gd) checks the real font chain
            measures.pop("width_ratio_est", None)
            measures["key_token_ok"] = len(KEY_TOKEN.findall(english)) == len(KEY_TOKEN.findall(text))
            measures["script_ok"] = script_ok(text, lang, glossary["keep"])
            item = backs.get(f"{lang}-{index:02d}")
            if item:
                measures["back"] = item["english"]
                measures["back_notes"] = item.get("notes", "")
                measures["chrf"] = trial.chrf(item["english"], english)
                measures["drift_flag"] = measures["chrf"] < 35 and len(english.split()) > 4
            measures["ok"] = all(measures[k] for k in ("placeholders_ok", "tag_ok", "breaks_ok", "key_token_ok", "script_ok")) and not measures["glossary_missing"]
            rows.append({"msgid": english, "msgstr": text, **measures})
        report["languages"][lang] = {
            "msgfmt_rc": fmt.returncode, "msgfmt": (fmt.stdout + fmt.stderr).strip(),
            "translated": len(translated), "failed": [r["msgid"] for r in rows if not r["ok"]],
            "drift_flags": [r["msgid"] for r in rows if r.get("drift_flag")], "rows": rows,
        }
    out.write_text(json.dumps(report, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    for lang, data in report["languages"].items():
        print(f"{lang}: msgfmt rc {data['msgfmt_rc']} ({data['msgfmt']}); {data['translated']} checked, "
              f"{len(data['failed'])} failed, {len(data['drift_flags'])} drift flags")


def hardcoded(pot: Path, inventory: Path, out: Path) -> None:
    """Player-facing inventory strings that are no msgid of the POT, by file."""
    msgids = set(messages(pot))
    rows = [e for e in json.loads(inventory.read_text(encoding="utf-8")) if e["in_scope"] and e["shown"]]
    by_file: dict[str, dict] = {}
    for row in rows:
        entry = by_file.setdefault(row["path"], {"strings": 0, "in_pot": 0, "missing": []})
        entry["strings"] += 1
        if row["text"] in msgids:
            entry["in_pot"] += 1
        else:
            entry["missing"].append({"line": row["line"], "class": row["class"], "text": row["text"]})
    total = len(rows)
    covered = sum(f["in_pot"] for f in by_file.values())
    summary = {"inventory_player_strings": total, "in_pot": covered, "not_in_pot": total - covered,
               "by_file": {path: {"strings": f["strings"], "in_pot": f["in_pot"], "not_in_pot": len(f["missing"])} for path, f in sorted(by_file.items())},
               "by_class_not_in_pot": {}}
    for f in by_file.values():
        for miss in f["missing"]:
            summary["by_class_not_in_pot"][miss["class"]] = summary["by_class_not_in_pot"].get(miss["class"], 0) + 1
    out.write_text(json.dumps({"summary": summary, "missing": {p: f["missing"] for p, f in sorted(by_file.items())}}, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=1))


if __name__ == "__main__":
    commands = {"potfiles": (potfiles, 1), "subset": (subset, 3), "fill": (fill, 3), "backprompt": (backprompt, 2),
                "check": (check, 4), "hardcoded": (hardcoded, 3)}
    if len(sys.argv) < 2 or sys.argv[1] not in commands or len(sys.argv) - 2 != commands[sys.argv[1]][1]:
        sys.exit(__doc__)
    commands[sys.argv[1]][0](*(Path(a) for a in sys.argv[2:]))
