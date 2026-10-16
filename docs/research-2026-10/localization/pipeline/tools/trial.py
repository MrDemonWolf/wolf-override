#!/usr/bin/env python3
"""The research-pipeline step's one trial tool: builds the Codex prompt and checks every translation.

Purpose
    The step compares three translators (Claude, Codex, Apple's on-device Translation) on the 12
    sample lines in ../lines.json for es-419, de and ja. This file holds every piece of logic the
    trial needs, so no check is written twice:

    prompt   writes the one Codex prompt (style packet + lines + Claude's outputs to back-translate).
    check    scores every translation file in ../out and writes ../out/scores.json and
             ../out/side_by_side.md.
    glyphs   reports which candidate languages each game font cannot draw.
    po DIR   writes DIR/messages.pot from lines.json and DIR/<lang>.po from Claude's translations,
             with the per-line context as "#." translator comments, to rehearse the gettext
             update flow (msgmerge / fuzzy) on real game lines.

Contract
    python3 -I tools/trial.py prompt <out_prompt.txt>
    python3 -I tools/trial.py check            (run with the scratch venv's python for font metrics)
    Inputs are read from the pipeline folder this file sits under; nothing outside it is touched.
    Translation files look like {"translations": {lang: {line_id: text}}}; back-translation files
    like {"back": {translator: {lang: {line_id: english}}}}.

Measures (all automated; tone and gender are judged by a person and kept in ../out/judgments.json)
    placeholders  positional printf tokens (%s, %d, %02d, %.1f ... and a literal %%) must equal the
                  English line's in number AND order; named tokens ({name}, {current}, {0}: any
                  {word}) must equal them as a multiset, in any order, since reordering is what names
                  are for. (bbcode_ok, the BBCode tag check, is used by the prototype's i18n_tool.py.)
    tag           a line that starts "WOLF: " in English must start with it in the translation.
    breaks        the count of authored "\\n" must match (Apple doubled them in the trial).
    glossary      every glossary term in the English line must appear in its required/variant form.
    glyphs        every character must be in the game's font cmap (Roboto body, Montserrat buttons).
    width         estimated pixel width ratio vs English: sum of default-instance advances at the
                  surface's font size, no kerning or shaping. A missing glyph counts as 1 em, which is
                  what a CJK fallback font roughly takes. Estimate only; the real gate is an overflow
                  render in the game.
    drift         chrF (character 6-gram F-score, beta 2, Popović 2015) between each back-translation
                  and the English source, 0..100. A cheap automatic proxy: it punishes paraphrase as
                  well as wrong meaning, so it flags lines for a human rather than deciding them.

Gotchas
    - Speaker tags and placeholders are compared before anything else; a translation that breaks
      one fails regardless of its other scores.
    - fontTools is optional: without it (plain python3 -I) glyph and width columns are "n/a".
"""
from __future__ import annotations

import json
import re
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "out"
#: The game's own font files. ROOT is docs/research-2026-10/localization/pipeline, so the repository root
#: is four levels up. (As run in the session scratch, the tool read copies of these two files from
#: ROOT/fonts; the filed copy reads the originals instead of keeping a second copy of each font.)
FONT_DIR = ROOT.parents[3] / "apps" / "game" / "assets" / "fonts"
LANGS = ["es-419", "de", "ja"]
#: Positional inserts filled by Godot's String % operator, in its full printf form: any run of the
#: modifiers it reads (- + u 0-9 . *) before a conversion it accepts (s c d o x X f v; String::sprintf in
#: core/string/ustring.cpp, 4.7.2-stable). The whole token is compared, so "%02d" turned into "%d" or a
#: dropped "%.1f" is a mismatch. "%%" is a token too: String % reads it as a literal percent, so a stray
#: "%%d" (Apple's Japanese L03 in the trial) silently eats a placeholder and must count as a mismatch.
#: A space is not a modifier, so "100% sure" holds no token.
POSITIONAL = re.compile(r"%%|%[-+u0-9.*]*[scdoxXfv]")
#: Named inserts filled by String.format: {name} on the end card, the build plan's {current} and {total},
#: and indexed ones such as {0}. Any word of letters, digits and _ counts, so a misspelt or dropped one is
#: caught: String.format leaves an unknown key on screen as literal text, and msgfmt's c-format check
#: ignores braces.
NAMED = re.compile(r"\{[A-Za-z0-9_]+\}")
#: A BBCode tag as RichTextLabel reads it: [b], [/b], [color=#ff8800], [font_size=19]. The credits are one
#: BBCode msgid, so its tags must survive translation.
BBCODE = re.compile(r"\[(/?)([a-z_]+)(?:=[^\]]*)?\]")


def placeholders_ok(english: str, text: str) -> bool:
    """True when ``text`` keeps ``english``'s inserts: the positional ones (POSITIONAL) in the same
    order, since %s and %d are filled left to right, and the named ones (NAMED) as a multiset, since a
    translator may move them. Pure; no side effects."""
    return (POSITIONAL.findall(english) == POSITIONAL.findall(text)
            and Counter(NAMED.findall(english)) == Counter(NAMED.findall(text)))


def _bbcode_nests(text: str) -> bool:
    """True when every closing tag in ``text`` closes the innermost open tag and none stays open."""
    stack: list[str] = []
    for match in BBCODE.finditer(text):
        if not match.group(1):
            stack.append(match.group(2))
        elif not stack or stack.pop() != match.group(2):
            return False
    return not stack


def bbcode_ok(english: str, text: str) -> bool:
    """True when ``text`` has exactly ``english``'s BBCode tags, attribute values included, as a multiset
    (a translator may move a bold word), and they nest properly wherever the English does (a tag with no
    closing form, such as [br], makes the English itself not nest, and then only the multiset counts).
    Pure; no side effects."""
    if Counter(m.group(0) for m in BBCODE.finditer(english)) != Counter(m.group(0) for m in BBCODE.finditer(text)):
        return False
    return _bbcode_nests(text) or not _bbcode_nests(english)
#: The letters each candidate language needs beyond ASCII, for the glyph-coverage report. CJK is
#: reported as a count of sample characters instead, since no Latin font covers it.
ALPHABETS = {
    "es": "ÁÉÍÓÚÑÜáéíóúñü¿¡«»", "pt-BR": "ÀÁÂÃÇÉÊÍÓÔÕÚàáâãçéêíóôõú", "fr": "ÀÂÆÇÉÈÊËÎÏÔŒÙÛÜŸàâæçéèêëîïôœùûüÿ«» ",
    "de": "ÄÖÜßẞäöü„“‚‘", "it": "ÀÈÉÌÒÙàèéìòù", "nl": "ĲĳËÏëï", "pl": "ĄĆĘŁŃÓŚŹŻąćęłńóśźż„”",
    "tr": "ÇĞİÖŞÜçğıöşü", "ru": "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя«»",
    "uk": "ЄІЇҐєіїґʼ", "vi": "ĂÂĐÊÔƠƯăâđêôơưạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ",
    "ja": "。、「」ー・あいうえおかきくけこアイウエオカキクケコ漢字日本語", "zh-Hans": "，。“”简体中文汉字", "ko": "가나다라마바사아자차카타파하한국어",
}
#: Font file and pixel size per surface, from apps/game/assets/fonts/game_theme.tres (body Roboto,
#: controls Montserrat) and the sizes in main.gd (DIALOGUE_FONT_SIZE 23, end-card button 19) and
#: junction_room.gd (LABEL_FONT_SIZE 12). Hint and card sizes are approximated by the dialogue size.
SURFACE_FONT = {
    "dialogue": ("Roboto-Variable.ttf", 23), "hint": ("Roboto-Variable.ttf", 23),
    "card": ("Roboto-Variable.ttf", 23), "recap": ("Roboto-Variable.ttf", 17),
    "label": ("Roboto-Variable.ttf", 12), "button": ("Montserrat-Variable.ttf", 19),
}


def load(name: str) -> dict:
    """The JSON file ``name`` under the pipeline folder."""
    return json.loads((ROOT / name).read_text(encoding="utf-8"))


def lines() -> list[dict]:
    return load("lines.json")["lines"]


# ---------------------------------------------------------------- prompt

def build_prompt(target: Path) -> None:
    """Writes the single Codex prompt: translate independently, then back-translate Claude's lines."""
    packet = (ROOT / "style_packet.md").read_text(encoding="utf-8")
    sample = [{k: line[k] for k in ("id", "text", "context")} for line in lines()]
    claude = load("out/claude.json")["translations"]
    target.write_text(
        packet
        + "\n\nTASK 1. Translate each line below into es-419, de and ja, following the rules above.\n"
        + json.dumps(sample, ensure_ascii=False, indent=1)
        + "\n\nTASK 2. Independently back-translate these existing translations into literal English "
        "(say what they actually say, do not repair them). Keep placeholders as they are.\n"
        + json.dumps(claude, ensure_ascii=False, indent=1)
        + "\n\nReply with ONLY one JSON object, no prose, no code fence: "
        '{"translations": {"es-419": {"L01": "..."}, "de": {...}, "ja": {...}}, '
        '"back": {"claude": {"es-419": {"L01": "..."}, "de": {...}, "ja": {...}}}}. '
        "Do not run any commands or read any files.\n",
        encoding="utf-8",
    )


# ---------------------------------------------------------------- measures

def chrf(hypothesis: str, reference: str, max_n: int = 6, beta: float = 2.0) -> float:
    """chrF (Popović 2015) of ``hypothesis`` against ``reference``, 0..100, spaces ignored."""
    hyp, ref = hypothesis.replace(" ", "").lower(), reference.replace(" ", "").lower()
    precisions, recalls = [], []
    for n in range(1, max_n + 1):
        h = Counter(hyp[i:i + n] for i in range(len(hyp) - n + 1))
        r = Counter(ref[i:i + n] for i in range(len(ref) - n + 1))
        if not h or not r:
            continue
        overlap = sum((h & r).values())
        precisions.append(overlap / sum(h.values()))
        recalls.append(overlap / sum(r.values()))
    if not precisions:
        return 0.0
    p, r = sum(precisions) / len(precisions), sum(recalls) / len(recalls)
    return 0.0 if p + r == 0 else round(100 * (1 + beta ** 2) * p * r / (beta ** 2 * p + r), 1)


class Fonts:
    """cmap and advance widths of the game's two fonts, or None when fontTools is missing."""

    def __init__(self) -> None:
        self.ok = False
        try:
            from fontTools.ttLib import TTFont  # type: ignore[import-not-found]
        except ImportError:
            return
        self.tables = {}
        for name in {f for f, _ in SURFACE_FONT.values()}:
            font = TTFont(FONT_DIR / name)
            self.tables[name] = (font.getBestCmap(), font["hmtx"].metrics, font["head"].unitsPerEm)
        self.ok = True

    def missing(self, text: str, surface: str) -> list[str]:
        cmap = self.tables[SURFACE_FONT[surface][0]][0]
        return sorted({c for c in text if c != "\n" and ord(c) not in cmap})

    def width(self, text: str, surface: str) -> float:
        """Estimated px width of the widest authored row of ``text`` on ``surface``."""
        name, size = SURFACE_FONT[surface]
        cmap, metrics, upem = self.tables[name]
        rows = []
        for row in text.split("\n"):
            units = sum(metrics[cmap[ord(c)]][0] if ord(c) in cmap else upem for c in row)
            rows.append(units * size / upem)
        return max(rows)


def check_line(line: dict, text: str, lang: str, glossary: dict, fonts: Fonts) -> dict:
    """Every automated measure for one translation of one line."""
    english = line["text"]
    result: dict = {
        "placeholders_ok": placeholders_ok(english, text),
        "wolf_ok": text.count("WOLF") >= english.count("WOLF"),
        "tag_ok": (not english.startswith("WOLF: ")) or text.startswith("WOLF: "),
        "breaks_ok": english.count("\n") == text.count("\n"),
        "char_ratio": round(len(text) / len(english), 2),
    }
    missing_terms = []
    for term, forms in glossary["terms"].items():
        hit = term in english if term.isupper() else re.search(r"\b" + re.escape(term) + r"\b", english)
        if hit and lang in forms:
            allowed = [forms[lang]["required"]] + forms[lang].get("variants", [])
            if not any(form in text for form in allowed):
                missing_terms.append(term)
    result["glossary_missing"] = missing_terms
    if fonts.ok:
        result["missing_glyphs"] = "".join(fonts.missing(text, line["surface"]))
        result["width_ratio_est"] = round(fonts.width(text, line["surface"]) / fonts.width(english, line["surface"]), 2)
    return result


# ---------------------------------------------------------------- check

def translation_sets() -> dict[str, dict]:
    """translator -> {lang: {id: text}} for Claude, Codex and Apple (Apple read from its probe output)."""
    sets = {"claude": load("out/claude.json")["translations"]}
    if (OUT / "codex.json").exists():
        sets["codex"] = load("out/codex.json")["translations"]
    apple = load("out/apple.json")
    by_lang: dict = {}
    for row in apple["trials"]:
        if row.get("translation"):
            by_lang.setdefault(row["target"].split(" ")[0], {})[row["id"]] = row["translation"]
    sets["apple"] = by_lang
    return sets


def back_translations() -> dict:
    """translator -> back-translator -> {lang: {id: english}} from every source that produced one."""
    back: dict = {}
    apple = load("out/apple.json")
    for row in apple["trials"]:
        if row.get("backTranslation"):
            back.setdefault("apple", {}).setdefault("apple", {}).setdefault(row["target"].split(" ")[0], {})[row["id"]] = row["backTranslation"]
    for row in apple.get("backChecks", []):
        if row.get("backTranslation"):
            back.setdefault(row["translator"], {}).setdefault("apple", {}).setdefault(row["target"], {})[row["id"]] = row["backTranslation"]
    for name, back_by in (("codex.json", "codex"), ("claude_back.json", "claude")):
        if (OUT / name).exists():
            for translator, by_lang in load("out/" + name).get("back", {}).items():
                back.setdefault(translator, {})[back_by] = by_lang
    return back


def check() -> None:
    glossary = load("glossary.json")
    fonts = Fonts()
    sets, back = translation_sets(), back_translations()
    scores: dict = {}
    md = ["# Side by side (proof samples only; English is the source of truth)\n"]
    for line in lines():
        md.append(f"\n## {line['id']} {line['kind']}\n\nEN: `{line['text']!r}`\n")
        md.append("| lang | translator | translation | back-translations (by) | auto flags |\n|---|---|---|---|---|")
        for lang in LANGS:
            for translator, by_lang in sets.items():
                text = by_lang.get(lang, {}).get(line["id"])
                if text is None:
                    continue
                measures = check_line(line, text, lang, glossary, fonts)
                drift = {}
                backs = []
                for by, langs in back.get(translator, {}).items():
                    bt = langs.get(lang, {}).get(line["id"])
                    if bt:
                        drift[by] = chrf(bt, line["text"])
                        backs.append(f"{by}: {bt!r} (chrF {drift[by]})")
                measures["drift_chrf"] = drift
                scores.setdefault(lang, {}).setdefault(translator, {})[line["id"]] = measures
                flags = [k for k in ("placeholders_ok", "wolf_ok", "tag_ok", "breaks_ok") if not measures[k]]
                flags += [f"glossary:{t}" for t in measures["glossary_missing"]]
                if measures.get("missing_glyphs"):
                    flags.append(f"glyphs:{len(measures['missing_glyphs'])}")
                flags.append(f"w×{measures.get('width_ratio_est', 'n/a')}")
                cell = lambda s: s.replace("|", "\\|").replace("\n", "⏎")
                md.append(f"| {lang} | {translator} | {cell(text)} | {cell('<br>'.join(backs))} | {', '.join(flags)} |")
    (OUT / "scores.json").write_text(json.dumps(scores, ensure_ascii=False, indent=1), encoding="utf-8")
    (OUT / "side_by_side.md").write_text("\n".join(md) + "\n", encoding="utf-8")
    # A compact summary on stdout: hard failures per translator and language.
    for lang, by_tr in scores.items():
        for translator, by_id in by_tr.items():
            hard = sum(1 for m in by_id.values() if not (m["placeholders_ok"] and m["tag_ok"] and m["breaks_ok"] and m["wolf_ok"]))
            gloss = sum(len(m["glossary_missing"]) for m in by_id.values())
            drifts = [v for m in by_id.values() for v in m["drift_chrf"].values()]
            mean = round(sum(drifts) / len(drifts), 1) if drifts else "n/a"
            widest = max((m.get("width_ratio_est", 0) for m in by_id.values()), default=0)
            print(f"{lang:7} {translator:7} hard-fail lines {hard:2}  glossary misses {gloss:2}  mean chrF {mean}  widest w×{widest}")


def glyphs() -> None:
    """Prints, per font, which candidate languages' letters are missing (the font half of the glyph gate)."""
    fonts = Fonts()
    if not fonts.ok:
        sys.exit("glyphs needs fontTools (run with the scratch venv's python)")
    for name, (cmap, _, _) in fonts.tables.items():
        print(name)
        for lang, letters in ALPHABETS.items():
            missing = "".join(c for c in letters if ord(c) not in cmap)
            print(f"  {lang:8} {'ok' if not missing else f'missing {len(missing)}/{len(letters)}: {missing[:24]}'}")


def _po_quote(text: str) -> str:
    """``text`` as a PO string literal (backslash, quote and newline escaped)."""
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def write_po(folder: Path) -> None:
    """The POT for the sample lines plus one PO per trial language, as the real pipeline would keep them."""
    folder.mkdir(parents=True, exist_ok=True)
    header = 'msgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n'
    claude = load("out/claude.json")["translations"]
    for lang in [None] + LANGS:
        out = [header + (f'"Language: {lang}\\n"\n' if lang else "")]
        for line in lines():
            out.append(f"#. {line['context']}\n#: {line['source']}\n"
                       f"msgid {_po_quote(line['text'])}\nmsgstr {_po_quote(claude[lang][line['id']] if lang else '')}\n")
        (folder / (f"{lang}.po" if lang else "messages.pot")).write_text("\n".join(out), encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) >= 2 and sys.argv[1] == "prompt" and len(sys.argv) == 3:
        build_prompt(Path(sys.argv[2]))
    elif sys.argv[1:] == ["check"]:
        check()
    elif sys.argv[1:] == ["glyphs"]:
        glyphs()
    elif len(sys.argv) == 3 and sys.argv[1] == "po":
        write_po(Path(sys.argv[2]))
    else:
        sys.exit(__doc__)
