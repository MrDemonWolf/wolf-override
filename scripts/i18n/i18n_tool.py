#!/usr/bin/env python3
"""The game's one i18n tool: the PO files, every translation gate, the POT file list, the bundled
fallback fonts and the counts.

Purpose
    Every localization step that is not a Godot run lives here once, as a subcommand:

    potfiles GAME [--check]   prints project.godot's translations_pot_files line for GAME (apps/game):
                              every .tscn and .gd at any depth except POT_SKIP (the tests, the debug
                              tools, add-ons and the import cache), so a new subfolder is never missed.
                              With --check it prints nothing and exits 1 when GAME's project.godot holds
                              another list (CI runs it, so a new script cannot stay out of the POT).
    fonts CACHE               rebuilds the bundled fallback fonts (PR L4, decision D7): each CJK
                              language's Noto Sans subset cut to its fixed common set (fixed_charset),
                              from the recorded Noto release (NOTO_SOURCES, downloaded into CACHE and
                              checked by SHA-256), the symbols font behind Roboto (symbols_font) and the
                              character lists the game's glyph test reads (CHARSETS_FILE). Prints the
                              sizes. Rerun only to change a set; the outputs are committed. It ends
                              with `pickerfonts`, so the picker's cuts follow a changed subset.
    pickerfonts               rebuilds only the language list's tiny fonts (PR L6, picker_fonts): for
                              every language whose row names a "picker_font", its own picker name and
                              "machine translation" tag cut from its committed fallback subset, with
                              Montserrat's vertical metrics. Needs no download. Prints the sizes.
    fill POT TRANS OUTDIR     writes OUTDIR/<lang>.po for every language in TRANS from the POT: each
                              message keeps the POT's comments and gets TRANS's context as a "#." note,
                              its marks as "#. i18n: ..." (MARKS) and its translation, stamped
                              "# machine-translated by Claude, unreviewed".
    backprompt PODIR OUT      writes the Codex back-translation prompt: the translated texts only, keyed
                              by language and entry_key, with no English, so the back-translation is
                              independent. Each text says who speaks and how the engineer appears; each
                              answer carries a structured "engineer_gendered" next to its free-text notes.
    check POT PODIR OUT [--back BACK] [--release]
                              every automated gate on the PO files in PODIR (apps/game/i18n), as JSON at
                              OUT: msgfmt --check-format, the per-line measures (printf and named
                              placeholders, BBCode tags, speaker tag, glossary's required and avoid forms:
                              line_measures, folded in from the research pipeline step's trial tool), line
                              breaks (BREAKS_KEEP), the "E:" key token (KEY_TOKEN), the script
                              guard (SCRIPT_GUARD), the
                              engineer-gender gate (gendered_words, and the back-translation's
                              engineer_gendered), the Slavic name-case gate (NAME_CASE), the plural forms of
                              every msgstr[n], the sibling-file completeness gate (family_gaps), and chrF of
                              Codex's back-translation (BACK, JSON; optional) against the English. With
                              --release it also runs the release gates (release_problems): no fuzzy entry
                              in a language whose review state is "reviewed", and no untranslated or fuzzy
                              line marked "#. i18n: story". Exits 1 when any language fails (a failed line,
                              a non-zero msgfmt, a sibling gap or a release problem), so CI can gate on it.
                              A PODIR with no PO file passes: only English exists until PR L9.
    glossary                  checks the glossary (i18n/glossary.json) and the style guides (i18n/style/)
                              against each other and languages.json (glossary_problems): every covered
                              language has a form for every term and a guide with every section, forms
                              pass their script guard, open terms require nothing. Exits 1 on any problem.
    selftest OUT              runs the gates above on fixed planted cases (SELFTEST, FAMILY_SELFTEST,
                              RELEASE_SELFTEST, GLOSSARY_SELFTEST) and writes the result as JSON at OUT;
                              exits 1 if a planted error passes or a clean line fails. The negative control
                              for gates no real msgid exercises yet (named and printf placeholders, BBCode,
                              plural forms, the "you", pronoun and name-case checks, sibling files, the
                              release gates, the glossary's avoid forms and its shape).
    hardcoded POT INVENTORY OUT
                              player-facing strings of the strings step's inventory (in scope and shown)
                              whose text is no msgid of POT, by file, as JSON at OUT.

Contract
    python3 -I -B scripts/i18n/i18n_tool.py <subcommand> ...   (stdlib only; `fonts` and `pickerfonts` need hb-subset and
    hb-info, `check` needs msgfmt, both from gettext and harfbuzz in Homebrew or apt). Paths are arguments,
    read from the current folder; nothing outside them is written, except that `fonts` rewrites the
    fallback fonts and character lists it owns (FONTS, below) and `pickerfonts` the picker fonts. Two files are read from the repository
    this tool sits in: every per-language fact from apps/game/i18n/languages.json (LANGUAGES, the same
    table the game's I18n reads, so the game and the tools never keep two lists), the glossary from
    i18n/glossary.json (GLOSSARY_FILE) and the style guides from i18n/style/ (STYLE_DIR). A PO whose
    language is not in the table stops `check`.
    TRANS is a translations file: {"context": {msgid: note}, "marks": {msgid: "engineer=... slot=...
    speaker=..."}, "translations": {lang: {msgid: text}}} (the prototype's translations/claude.json).
    BACK is {"back": {"<lang>-<entry_key>": {"english": ..., "notes": ..., "engineer_gendered": bool}}}.

Gotchas
    - The PO parser here reads what Godot's generator and this tool write (msgctxt, msgid, msgid_plural,
      msgstr, msgstr[n], comments, continued strings); it is not a general gettext parser.
    - Godot reads "Language:" from the PO header (4.7.2-stable core/io/translation_loader_po.cpp). It
      rejects the whole file when the header entry is missing ("No config found"), when a msgid_plural
      entry comes and the header has no "Plural-Forms:" line at all, or when a plural entry has another
      number of msgstr[n] than the rule's nplurals. A Plural-Forms line whose value does not parse is NOT
      rejected: PluralRules::parse fails and Translation falls back to the rule of its locale at parse
      time, still the default "en" (n != 1, 2 forms), because "Language:" is applied after the parse. So
      a 1-form (ja, ko, zh) or 3-form (ru, pl) file is then rejected by the msgstr[n] count, but a 2-form
      file (es, de, fr, pt_BR) loads silently with the English rule, which is wrong for fr and pt_BR at
      n = 0. `check` therefore compares the header's rule with languages.json word for word
      (plural_header_ok) rather than trusting the header's nplurals; msgfmt --check-header catches a
      rule that does not parse.
    - Godot skips the next message after ANY comment line that contains "fuzzy" (`l.contains("fuzzy")`,
      the same loader), not only a "#, fuzzy" flag, so a translator note or mark with the word in it
      silently drops a translated line. is_fuzzy mirrors the loader, `check` fails a language with such a
      note (fuzzy_notes) and `fill` refuses to write one.
    - "es" is Latin-American Spanish: Godot reduces es-419 to "es", but the glossary and style packet name
      it es-419; languages.json's "glossary" field maps it back.
    - The gender gate is a heuristic, not a parser: it can flag a correct line (a noun that ends like a
      past-tense verb, a pronoun that means WOLF) and miss a gendered form it has no pattern for. It reads
      the engineer's role on each line from its marks, so a gender-risk line with no mark is checked only
      next to its name slot. A flag is resolved by rewording or by a reviewer's "# gender-ok: <name>
      <date>" comment on the entry; native review of the gender-risk lines (PIPELINE.md) stays the real
      check.
    - Run with python3 -I -B so nothing is written next to the tool (no __pycache__ in the repository).

History
    Moved from the research branch codex/localization-research at 520cad1
    (docs/research-2026-10/localization/prototype/tools/i18n_tool.py; its fix-step versions are cited
    there) in PR L2 of the localization plan. The measures it imported from that branch's
    pipeline/tools/trial.py (placeholders_ok, bbcode_ok, chrf and check_line's tag and glossary checks)
    are folded in here, so the build keeps one copy; trial.py's font-width estimate and glyph report are
    not, since the game's own glyph and overflow checks (I18n, tests/i18n_test.gd) replace them.
"""
from __future__ import annotations

import copy
import hashlib
import json
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent
#: The repository this tool sits in (scripts/i18n/ is two levels down).
REPO = HERE.parent.parent

#: The one per-language table: glossary key, script, family, plural rule, gender rule and the name-case
#: flag for every language the tools know, in the same file the game's I18n reads into I18n.LANGUAGES
#: (PR L1). Read once here, so the game, the picker and the gates never keep two lists.
LANGUAGES_FILE = REPO / "apps" / "game" / "i18n" / "languages.json"
_TABLE = json.loads(LANGUAGES_FILE.read_text(encoding="utf-8"))
LANGUAGES: dict[str, dict] = _TABLE["languages"]
#: The glossary the per-line gate reads: "keep" (words copied through untranslated in every script),
#: "inherit" (es-ES takes es-419's forms) and "terms" (per English term and glossary key, the "required"
#: form a translation must contain, its accepted "variants" and the "avoid" forms it must not; the file's
#: "_about" has every field). Outside res:// on purpose: a .json inside the game would be exported
#: (DESIGN.md, "Outside res://"). PR L5 grew it from the research trial's glossary to the 10 languages with
#: decisions D9 and D11.
GLOSSARY_FILE = REPO / "i18n" / "glossary.json"

# ------------------------------------------------------------------------- per-line measures
# Folded in from the research pipeline step's trial tool (codex/localization-research at 520cad1,
# docs/research-2026-10/localization/pipeline/tools/trial.py), which this tool used to import.

#: Positional inserts filled by Godot's String % operator, in its full printf form: any run of the
#: modifiers it reads (- + u 0-9 . *) before a conversion it accepts (s c d o x X f v; String::sprintf in
#: core/string/ustring.cpp, 4.7.2-stable). The whole token is compared, so "%02d" turned into "%d" or a
#: dropped "%.1f" is a mismatch. "%%" is a token too: String % reads it as a literal percent, so a stray
#: "%%d" (Apple's Japanese line in the pipeline trial) silently eats a placeholder and must count as a
#: mismatch. A space is not a modifier, so "100% sure" holds no token.
POSITIONAL = re.compile(r"%%|%[-+u0-9.*]*[scdoxXfv]")
#: Named inserts filled by String.format: {name} on the end card, the build plan's {current} and {total},
#: and indexed ones such as {0}. Any word of letters, digits and _ counts, so a misspelt or dropped one is
#: caught: String.format leaves an unknown key on screen as literal text, and msgfmt's c-format check
#: ignores braces.
NAMED = re.compile(r"\{[A-Za-z0-9_]+\}")
#: A BBCode tag as RichTextLabel reads it: [b], [/b], [color=#ff8800], [font_size=19]. The credits are one
#: BBCode msgid, so its tags must survive translation.
BBCODE = re.compile(r"\[(/?)([a-z_]+)(?:=[^\]]*)?\]")
#: The speaker tag a WOLF line starts with in English; DialogueBoxes reads it to colour the box, so a
#: translation must keep it in front.
WOLF_TAG = "WOLF: "


def placeholders_ok(english: str, text: str) -> bool:
    """True when ``text`` keeps ``english``'s inserts: the positional ones (POSITIONAL) in the same
    order, since %s and %d are filled left to right, and the named ones (NAMED) as a multiset, since a
    translator may move them. Pure."""
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
    Pure."""
    if Counter(m.group(0) for m in BBCODE.finditer(english)) != Counter(m.group(0) for m in BBCODE.finditer(text)):
        return False
    return _bbcode_nests(text) or not _bbcode_nests(english)


def chrf(hypothesis: str, reference: str, max_n: int = 6, beta: float = 2.0) -> float:
    """chrF (Popović 2015: character n-gram F-score up to ``max_n``, recall weighted by ``beta``) of
    ``hypothesis`` against ``reference``, 0..100, case and spaces ignored. Used on a back-translation
    against the English: a cheap drift proxy that punishes paraphrase as well as wrong meaning, so it only
    flags a line for a person (PIPELINE.md, "chrF on its own is not a gate"). Pure."""
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


def term_used(term: str, english: str) -> bool:
    """True when the English line ``english`` uses the glossary ``term``: an all-capitals term ("SAFE
    POINT", a plate) anywhere, any other term only as a whole word and in that case, so "breaker" does
    not match "Breaker" at a sentence's start (give that a capitalised term of its own if it matters).
    Pure."""
    return term in english if term.isupper() else bool(re.search(r"\b" + re.escape(term) + r"\b", english))


def term_form(forms: dict, glossary_key: str, glossary: dict) -> dict | None:
    """One term's form for ``glossary_key`` (a languages.json "glossary" value such as "es-419"): its own
    entry in ``forms`` (a glossary "terms" value), else the entry of the key it inherits from (the
    glossary's "inherit": es-ES takes es-419's), else None (the term is not checked in that language).
    Pure."""
    if glossary_key in forms:
        return forms[glossary_key]
    base = glossary.get("inherit", {}).get(glossary_key)
    return forms.get(base) if base else None


def glossary_missing(english: str, text: str, glossary_key: str, glossary: dict) -> list[str]:
    """The glossary terms ``english`` uses (term_used) whose required form or one of its accepted
    "variants" for ``glossary_key`` is not in ``text`` (exact, case-sensitive substrings: for Slavic
    languages "required" is a stem every case form contains). A term with no form for the language
    (term_form), or an "open" one whose "required" is null and which has no variants, is not checked:
    its word is still a reviewer's. Pure."""
    missing = []
    for term, forms in glossary["terms"].items():
        form = term_form(forms, glossary_key, glossary)
        if form is None or not term_used(term, english):
            continue
        allowed = [f for f in [form.get("required")] + form.get("variants", []) if f]
        if allowed and not any(f in text for f in allowed):
            missing.append(term)
    return missing


def glossary_avoided(english: str, text: str, glossary_key: str, glossary: dict) -> list[str]:
    """The "avoid" forms ``text`` contains for the glossary terms ``english`` uses, in ``glossary_key``'s
    form (term_form), each as "<term>: <form>". An avoid form is a word a back-translation or decision D11
    showed to be a wrong reading (es "interruptor" for breaker reads as "switch"). It is matched
    case-insensitively at the start of a word, so plates in capitals and inflected forms (автомата) are
    caught; a longer word that merely starts with it (автоматически) is flagged too, and is resolved by
    narrowing the avoid list, not by the translator. Only lines that use the term are read, so the word
    stays free elsewhere. Pure."""
    found = []
    for term, forms in glossary["terms"].items():
        form = term_form(forms, glossary_key, glossary)
        if form is None or not term_used(term, english):
            continue
        for bad in form.get("avoid", []):
            if re.search(r"(?<!\w)" + re.escape(bad), text, re.IGNORECASE):
                found.append(f"{term}: {bad}")
    return found


def line_measures(english: str, text: str, glossary_key: str, glossary: dict) -> dict:
    """The language-independent measures of one translation ``text`` of ``english``: placeholders_ok,
    wolf_ok (WOLF named at least as often; reported, not a gate), tag_ok (a line that starts with
    WOLF_TAG keeps it in front), char_ratio (length against the English; reported), glossary_missing and
    glossary_avoided. `check` adds the per-language gates. Pure."""
    return {
        "placeholders_ok": placeholders_ok(english, text),
        "wolf_ok": text.count("WOLF") >= english.count("WOLF"),
        "tag_ok": (not english.startswith(WOLF_TAG)) or text.startswith(WOLF_TAG),
        "char_ratio": round(len(text) / len(english), 2),
        "glossary_missing": glossary_missing(english, text, glossary_key, glossary),
        "glossary_avoided": glossary_avoided(english, text, glossary_key, glossary),
    }


#: The script guard, ported once from ConPaws' locales-script test (written there after a Russian word
#: slipped into its pt-BR file): a Latin-script or CJK text holds no Cyrillic letter, and a Cyrillic
#: text holds no Latin letter outside the glossary's "keep" words (WOLF, the "E:" key token, the studio
#: and person names, placeholders), which stay as written in every language. It catches look-alike swaps
#: both ways; a Cyrillic "Е:" for the key token passes it (no Latin letter is left) but fails key_token_ok,
#: since the hint bar replaces only the Latin "E:".
SCRIPT_GUARD = {"cyrillic": re.compile(r"[\u0400-\u04FF]"), "latin": re.compile(r"[A-Za-z]")}
#: Where the CJK fallback fonts come from (PR L4, decision D7): the Noto Sans CJK 2.004 release of
#: notofonts/noto-cjk, its region-specific subset OTFs (each a whole language font, not yet cut down).
NOTO_RELEASE = "https://github.com/notofonts/noto-cjk/releases/download/Sans2.004/"
#: Per language: the release asset, the Regular OTF inside it and that OTF's SHA-256 (measured on
#: October 16, 2026; the Japanese one matches the research prototype's dff723ba...5073).
NOTO_SOURCES = {
    "ja": ("16_NotoSansJP.zip", "NotoSansJP-Regular.otf", "dff723ba59d57d136764a04b9b2d03205544f7cd785a711442d6d2d085ac5073"),
    "ko": ("17_NotoSansKR.zip", "NotoSansKR-Regular.otf", "69975a0ac8472717870aefeab0a4d52739308d90856b9955313b2ad5e0148d68"),
    "zh_Hans": ("18_NotoSansSC.zip", "NotoSansSC-Regular.otf", "faa6c9df652116dde789d351359f3d7e5d2285a2b2a1f04a2d7244df706d5ea9"),
    "zh_Hant": ("19_NotoSansTC.zip", "NotoSansTC-Regular.otf", "5bab0cb3c1cf89dde07c4a95a4054b195afbcfe784d69d75c340780712237537"),
}
#: Each CJK language's national common-character set, as (codec, rows): a row is (first lead byte, last
#: lead byte, trail-byte ranges, last code or None), decoded cell by cell. Sources: JIS X 0208 rows 1-8
#: (symbols, kana) and 16-47 (the 2,965 level-1 kanji) in EUC-JP; GB 2312 rows 1-9 (symbols) and 16-55
#: (the 3,755 level-1 hanzi); Big5's symbols (A140-A3BF) and its 5,401 frequently used hanzi
#: (A440-C67E); KS X 1001 rows 1-12 (symbols, jamo) and 16-40 (the 2,350 Hangul syllables) in EUC-KR.
#: Korean leaves out hanja: modern game text is written in Hangul.
CJK_STANDARD_SETS = {
    "ja": ("euc_jp", [(0xA1, 0xA8, [(0xA1, 0xFE)], None), (0xB0, 0xCF, [(0xA1, 0xFE)], None)]),
    "zh_Hans": ("gb2312", [(0xA1, 0xA9, [(0xA1, 0xFE)], None), (0xB0, 0xD7, [(0xA1, 0xFE)], None)]),
    "zh_Hant": ("big5", [(0xA1, 0xA3, [(0x40, 0x7E), (0xA1, 0xFE)], 0xA3BF), (0xA4, 0xC6, [(0x40, 0x7E), (0xA1, 0xFE)], 0xC67E)]),
    "ko": ("euc_kr", [(0xA1, 0xAC, [(0xA1, 0xFE)], None), (0xB0, 0xC8, [(0xA1, 0xFE)], None)]),
}
#: Kept in every CJK subset: CJK symbols and punctuation, and the full-width forms and signs
#: (U+FF01-FF60, U+FFE0-FFE6), which every CJK text may use whatever its standard lists.
CJK_COMMON_RANGES = [(0x3000, 0x303F), (0xFF01, 0xFF60), (0xFFE0, 0xFFE6)]
#: Kept in one language's subset only: Japanese keeps all of hiragana (U+3097-3098 are unassigned) and
#: katakana (with the marks the JIS rows lack) and the half-width katakana; Korean keeps all of the compatibility jamo (ㅋㅋ).
CJK_EXTRA_RANGES = {"ja": [(0x3041, 0x3096), (0x3099, 0x309F), (0x30A0, 0x30FF), (0xFF61, 0xFF9F)], "ko": [(0x3131, 0x318E)]}
#: Characters below this are left out of the CJK subsets: Latin, Greek and Cyrillic, which the game's
#: Roboto and Montserrat draw first anyway (the fallback is only asked for what they lack).
CJK_MIN_CODEPOINT = 0x2000
#: The game's English characters that Roboto (the body font) lacks and Montserrat has (measured with
#: hb-info): the arrow in the debug overlay's relay line (main.gd debug_snapshot), the empty square of
#: the debug zones' toggles and the touch arrows of the tutorial prompt (main.gd). With the OS fallback
#: off (PR L4) they come from SYMBOLS_FONT, chained behind Roboto; tests/i18n_test.gd fails when the
#: game's text gains another character a theme font cannot draw.
SYMBOLS = "\u2192\u25a1\u25b6\u25c0"
#: The symbols fallback: SYMBOLS cut from Montserrat with Roboto's vertical metrics (symbols_font).
SYMBOLS_FONT = REPO / "apps" / "game" / "assets" / "fonts" / "Montserrat-Symbols-Subset.ttf"
#: The font the language list draws with (Montserrat-Semibold.tres's base): the picker fonts take its
#: vertical metrics (picker_fonts), so chaining them behind it leaves the list's row height alone.
PICKER_REFERENCE_FONT = REPO / "apps" / "game" / "assets" / "fonts" / "Montserrat-Variable.ttf"
#: The fixed character lists the CJK subsets are cut to and the game's glyph test reads. Under tests/,
#: which the export leaves out (export_presets.cfg), since the game itself never needs them.
CHARSETS_FILE = REPO / "apps" / "game" / "tests" / "support" / "cjk_charsets.json"
#: The prototype's hint bar replaced "E:" with the bound key, so it had to survive. Since PR L7b the HUD's
#: key is a %s placeholder filled after tr() (HudText, apps/game/scripts/hud_text.gd) and no msgid holds
#: "E:", so the gate now only fails a translation that adds one (the counts must stay equal, at zero).
#: Counted only where no letter comes before it: "PAUSE:" ends in "E:" too.
KEY_TOKEN = re.compile(r"(?<![^\W\d_])E:")
#: The comment that marks a msgid whose authored line breaks carry meaning (the name card's
#: "%s\nMAINTENANCE ENGINEER", a choice list), written by the build as "#. i18n: keep-breaks". Only those
#: msgids must keep the English break count. Every other "\n" is layout sized for English (the
#: codex/opening-dock branch adds such breaks mid-sentence), so a translation may drop it and let
#: DialogueBoxes break rows for its own language; it may not add breaks (Apple's doubling in the trial).
BREAKS_KEEP = "i18n: keep-breaks"
#: Where the engineer's first name goes in a msgid: the positional %s of the knockdown cards and
#: narration, or {name} on the end card.
NAME_SLOT = re.compile(r"%s|\{name\}")
#: The per-line marks a msgid carries as an extracted comment, "#. i18n: <word> <key=value> ...": the
#: build writes them in the source as "# TRANSLATORS: i18n: ..." (Godot's generator turns that into a
#: "#." note), the prototype's `fill` from TRANS's "marks". Keys read here:
#:   engineer=name,you,third,self  how the engineer appears: named by the slot, addressed as "you",
#:                            referred to without the slot ("the engineer", "they", the name card), or
#:                            speaking (the six lines tagged with the engineer's upper-case name);
#:   slot=key|choice          what a %s holds when it is not the name (a key name, a quoted choice);
#:   speaker=WOLF|narrator|hint|ui   who says the line (given to the back-translator).
#: With no engineer= mark, a msgid with a NAME_SLOT counts as engineer=name unless slot= says otherwise
#: (the safe default: more lines checked). Every inventory gender-risk line gets a mark in PR L7c.
MARKS = re.compile(r"i18n:\s*(.*)")
#: Clause boundaries: a gendered form only counts in the same clause as the name ("Страж заметил: %s"
#: is the sentry's verb, cut off by the colon).
CLAUSE_SPLIT = re.compile(r"[,:;.!?\u2014\u2013()\n«»„“”「」]")
#: Phrase boundaries for the apposition check: CLAUSE_SPLIT without the comma and the dashes, which in
#: "%s, усталая, идёт" or "%s — раненая" set off a word that still describes the name. Only the words
#: after the name are read this way; before it a comma usually ends another subject's clause.
APPOSITION_SPLIT = re.compile(r"[:;.!?()\n«»„“”「」]")
#: The comma and dashes an apposition is set off with, turned into spaces before the words are counted.
APPOSITION_MARKS = re.compile(r"[,\u2014\u2013]")
#: Punctuation stripped from each word's ends before it is matched (Spanish ¡ ¿, quotes, ellipsis).
WORD_STRIP = "\"'…-¡¿"
#: Sentence boundaries for the pronoun check, in Latin, Cyrillic and CJK punctuation.
SENTENCE_SPLIT = re.compile(r"[.!?\n。！？]")
#: How many words on each side of the name are read: subject and verb, or name and adjective, sit
#: within three words in every sample line; a wider window mostly adds other people's verbs.
GENDER_WINDOW = 3
#: A letter glued to the name slot ("заметил %sа"): a case ending, which Slavic languages add to names
#: and which depends on the name's gender. Checked for languages whose row sets name_case.
NAME_CASE = re.compile(r"(?:%s|\{name\})[^\W\d_]")
#: Skipped by `potfiles`, the only exclusions: the tests and the debug tools (out of scope per the strings
#: step), the editor add-ons and Godot's import cache. Every other .tscn and .gd under the game is listed.
POT_SKIP = ("tests/", "scripts/debug/", "addons/", ".godot/")


def gender_rule(lang: str) -> dict[str, re.Pattern]:
    """The compiled gender rule of ``lang`` (LANGUAGES[lang]["gender"] in languages.json, with any
    "extends" row filled in), as {"forms", "near_forms", "you", "first_person", "first_forms", "pronouns",
    "person_words"} -> pattern, missing keys left out. Empty for a language with no rule. Pure; patterns are case-insensitive."""
    name = LANGUAGES.get(lang, {}).get("gender")
    fields: dict[str, str] = {}
    while name:
        row = _TABLE["gender_rules"][name]
        for key, value in row.items():
            fields.setdefault(key, value)
        name = row.get("extends")
    fields.pop("extends", None)
    return {key: re.compile(value, re.IGNORECASE) for key, value in fields.items()}


def plural_count(lang: str) -> int:
    """nplurals of ``lang``'s Plural-Forms rule in languages.json."""
    return nplurals(LANGUAGES[lang]["plural_forms"])


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


def entry_key(entry: dict) -> str:
    """A stable id for a message: the first 10 hex digits of SHA-1 over msgctxt + EOT + msgid (gettext's
    own context separator). The back-translations are filed by it, so adding, removing or reordering PO
    entries (msgmerge after an English change) never attaches an answer to the wrong line."""
    raw = (entry.get("msgctxt", "") + "\x04" + entry["msgid"]).encode("utf-8")
    return hashlib.sha1(raw).hexdigest()[:10]


def is_fuzzy(entry: dict) -> bool:
    """True when Godot's PO loader skips the entry: any of its comment lines contains "fuzzy" (case-
    sensitive, as the loader's String.contains), the gettext "#, fuzzy" flag or any other comment (see
    Gotchas). The line then falls to another file of the same language, or to English: DESIGN.md."""
    return any("fuzzy" in c for c in entry["comments"])


def fuzzy_notes(entry: dict) -> list[str]:
    """The entry's comment lines that contain "fuzzy" but are not a "#," flag line: a translator note or
    mark that makes Godot skip a line nobody marked fuzzy (Gotchas). Empty when there is none."""
    return [c for c in entry["comments"] if "fuzzy" in c and not c.startswith("#,")]


def _mark_values(entry: dict) -> dict[str, list[str]]:
    """Every value each "#. i18n:" mark key has on the entry, in comment order. One msgid used at two
    call sites gets one "#." note from each site (Godot's generator keeps both, the first as
    "#. TRANSLATORS: i18n: ...", the second as "#. i18n: ..."), so a key can appear twice."""
    found: dict[str, list[str]] = {}
    for comment in entry["comments"]:
        match = MARKS.search(comment) if comment.startswith("#.") else None
        for word in (match.group(1).split() if match else []):
            key, _, value = word.partition("=")
            found.setdefault(key, []).append(value)
    return found


def marks(entry: dict) -> dict[str, str]:
    """The entry's "#. i18n: ..." marks (MARKS) as {key: value}; a bare word such as keep-breaks maps to
    "". Read from extracted comments only ("#." lines), where the generator and `fill` put them. When a
    key has two different values the last wins here, and mark_conflicts reports it so `check` fails."""
    return {key: values[-1] for key, values in _mark_values(entry).items()}


#: The mark keys whose value changes what the gender gate and the back-translation are told; two call
#: sites of one msgid that disagree on one of them make `check` fail (mark_conflicts).
CONFLICT_KEYS = ("engineer", "slot", "speaker")


def mark_conflicts(entry: dict) -> list[str]:
    """The CONFLICT_KEYS that carry two different values on the entry (one msgid marked engineer=name at
    one call site and slot=key or engineer=you at another), sorted. Empty when the marks agree. Pure."""
    values = _mark_values(entry)
    return sorted(key for key in CONFLICT_KEYS if len(set(values.get(key, []))) > 1)


def engineer_roles(entry: dict) -> set[str]:
    """How the engineer appears in the entry's msgid: a subset of {"name", "you", "third", "self"} from its
    engineer= mark, or {"name"} when it has a NAME_SLOT and no mark says the slot holds something else."""
    found = marks(entry)
    if "engineer" in found:
        return {role for role in found["engineer"].split(",") if role}
    has_slot = NAME_SLOT.search(entry["msgid"]) and found.get("slot") not in ("key", "choice")
    return {"name"} if has_slot else set()


# ---------------------------------------------------------------------------------------- subcommands

def pot_files(game: Path) -> list[str]:
    """Every .tscn and .gd under ``game`` (apps/game), at any depth, as sorted res:// paths, except
    POT_SKIP. Walking the whole tree is what makes the CI equality check meaningful: a scene in a new
    subfolder (the lighter plan's scenes/ui/) is listed without anyone adding it. Pure (reads the tree)."""
    files = sorted(p.relative_to(game).as_posix() for p in list(game.rglob("*.tscn")) + list(game.rglob("*.gd")))
    return [f"res://{f}" for f in files if not f.startswith(POT_SKIP)]


#: The project.godot key (under [internationalization]) that lists the files Godot's POT generator reads.
POT_FILES_KEY = "locale/translations_pot_files"


def potfiles(game: Path, check_only: bool = False) -> None:
    """Prints the translations_pot_files line for ``game`` (pot_files), ready for project.godot. With
    ``check_only`` it prints nothing when ``game``/project.godot already holds exactly that line, and
    otherwise names the files to add or drop and exits 1 (the CI check)."""
    line = POT_FILES_KEY + "=PackedStringArray(" + ", ".join(json.dumps(f) for f in pot_files(game)) + ")"
    if not check_only:
        print(line)
        return
    project = (game / "project.godot").read_text(encoding="utf-8")
    current = next((row for row in project.splitlines() if row.startswith(POT_FILES_KEY + "=")), None)
    if current == line:
        return
    listed = set(re.findall(r'"([^"]*)"', current or ""))
    wanted = set(pot_files(game))
    sys.exit(f"{POT_FILES_KEY} in {game / 'project.godot'} is out of date: add {sorted(wanted - listed)}, "
             f"drop {sorted(listed - wanted)} (or fix the order); paste the line `i18n_tool.py potfiles` prints")


def fixed_charset(code: str) -> str:
    """The wanted character set of CJK language ``code`` (decision D7): every character of its national
    standard's common set (CJK_STANDARD_SETS, read through Python's own codecs, so no list is copied by
    hand), CJK_COMMON_RANGES and CJK_EXTRA_RANGES, and the language's own picker name and "machine
    translation" tag from LANGUAGES, minus everything below CJK_MIN_CODEPOINT (the game fonts draw those
    first). Pure; the characters come back sorted by code point, so the file written from it is stable.
    `fonts` keeps only those the Noto font has (font_codepoints)."""
    codec, rows = CJK_STANDARD_SETS[code]
    points = {cp for lo, hi in CJK_COMMON_RANGES + CJK_EXTRA_RANGES.get(code, []) for cp in range(lo, hi + 1)}
    for lead_lo, lead_hi, trail_ranges, last in rows:
        for lead in range(lead_lo, lead_hi + 1):
            for trail_lo, trail_hi in trail_ranges:
                for trail in range(trail_lo, trail_hi + 1):
                    if last is not None and (lead << 8 | trail) > last:
                        continue
                    try:
                        points.update(ord(c) for c in bytes([lead, trail]).decode(codec))
                    except UnicodeDecodeError:
                        pass  # an unassigned cell of the standard
    points.update(ord(c) for c in own_characters(code))
    return "".join(chr(cp) for cp in sorted(points) if cp >= CJK_MIN_CODEPOINT)


def own_characters(code: str) -> str:
    """The characters of language ``code``'s own picker name and "machine translation" tag (its
    LANGUAGES row's "name" and "machine_tag") from CJK_MIN_CODEPOINT up, each once, sorted by code point:
    what its fallback subset must hold (fixed_charset, fonts) and all its picker font holds
    (picker_fonts). Spaces and Latin letters are left out, since the game fonts draw them first. Pure."""
    row = LANGUAGES[code]
    return "".join(sorted({c for c in str(row["name"]) + str(row.get("machine_tag") or "") if ord(c) >= CJK_MIN_CODEPOINT}))


def fonts(cache: Path) -> None:
    """Rebuilds the bundled fallback fonts (PR L4) and prints their sizes as JSON. For every language
    whose LANGUAGES row names a "fallback_font": fetches its NOTO_SOURCES zip into ``cache`` unless it is
    there, checks the OTF's SHA-256, and writes that file as an hb-subset of the OTF to fixed_charset.
    Then writes SYMBOLS_FONT (symbols_font) and CHARSETS_FILE, the lists the game's glyph test checks
    each subset against. Side effects: downloads into ``cache`` and rewrites those files in the
    repository; Godot's .import files and the asset register are kept by hand."""
    import urllib.request
    import zipfile
    cache.mkdir(parents=True, exist_ok=True)
    sizes, charsets = {}, {}
    for code, row in LANGUAGES.items():
        if not row.get("fallback_font"):
            continue
        asset, member, sha = NOTO_SOURCES[code]
        archive = cache / asset
        if not archive.exists():
            urllib.request.urlretrieve(NOTO_RELEASE + asset, archive)
        data = zipfile.ZipFile(archive).read(member)
        if hashlib.sha256(data).hexdigest() != sha:
            sys.exit(f"{archive}:{member} is not the recorded Noto file (SHA-256 {sha})")
        source = cache / member
        source.write_bytes(data)
        wanted = fixed_charset(code)
        have = font_codepoints(source)
        charsets[code] = "".join(c for c in wanted if ord(c) in have)
        lacking = "".join(c for c in wanted if ord(c) not in have)
        own = set(own_characters(code))
        if own & set(lacking):
            sys.exit(f"{member} cannot draw {code}'s own name or tag: {''.join(sorted(own & set(lacking)))}")
        out = _game_path(row["fallback_font"])
        _hb_subset(source, out, {ord(c) for c in charsets[code]})
        sizes[code] = {"characters": len(charsets[code]), "not_in_noto": lacking, "source_bytes": len(data),
                       "subset_bytes": out.stat().st_size}
    symbols_font()
    if font_codepoints(SYMBOLS_FONT) != {ord(c) for c in SYMBOLS}:
        sys.exit(f"{SYMBOLS_FONT} lacks some of SYMBOLS")
    about = ("The fixed character set of each CJK fallback subset (decision D7), written by "
             "`scripts/i18n/i18n_tool.py fonts` from the national standards' common sets (i18n_tool.py, "
             "fixed_charset), each cut to the characters its Noto font has; tests/i18n_test.gd checks that every character is drawable by that "
             "language's subset. Do not edit by hand: change the tool and rerun it.")
    CHARSETS_FILE.write_text(json.dumps({"_about": about, "charsets": charsets}, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    sizes["symbols"] = {"characters": len(SYMBOLS), "subset_bytes": SYMBOLS_FONT.stat().st_size}
    sizes["picker"] = picker_fonts()
    print(json.dumps(sizes, indent=1))


def picker_fonts() -> dict[str, dict]:
    """Writes the language list's own fonts (PR L6; DESIGN.md, "Settings: the LANGUAGE option") and
    returns their sizes by language. For every LANGUAGES row with a "picker_font": that language's
    own_characters cut with hb-subset from its committed "fallback_font" (which `fonts` cut to hold them,
    so no download is needed), then given Montserrat-Variable.ttf's vertical metrics
    (match_vertical_metrics), because the list draws with Montserrat and a fallback with taller metrics
    would make every row of the list taller (Font.get_height is the tallest of the chain). The game
    chains all of them behind the list's font at once (I18n.picker_font), so 日本語, 한국어, 简体中文
    and 繁體中文 and their tags draw in every language without a CJK font behind the game's own fonts.
    Side effect: rewrites those files; their .import files and the asset register are kept by hand."""
    sizes = {}
    for code, row in LANGUAGES.items():
        if not row.get("picker_font"):
            continue
        source, out = _game_path(row["fallback_font"]), _game_path(row["picker_font"])
        wanted = own_characters(code)
        lacking = "".join(c for c in wanted if ord(c) not in font_codepoints(source))
        if lacking:
            sys.exit(f"{source} cannot draw {code}'s own name or tag ({lacking}): rerun `fonts`")
        _hb_subset(source, out, {ord(c) for c in wanted})
        match_vertical_metrics(out, PICKER_REFERENCE_FONT)
        sizes[code] = {"characters": wanted, "subset_bytes": out.stat().st_size}
    return sizes


def symbols_font() -> None:
    """Writes SYMBOLS_FONT: SYMBOLS cut from Montserrat-Variable.ttf at weight 400 (Roboto-Regular.tres's
    weight), with its vertical metrics scaled down to Roboto's (match_vertical_metrics), so chaining it
    behind Roboto draws those characters without changing Roboto's line height. Side effect: rewrites
    that file."""
    fonts_dir = REPO / "apps" / "game" / "assets" / "fonts"
    _hb_subset(fonts_dir / "Montserrat-Variable.ttf", SYMBOLS_FONT, {ord(c) for c in SYMBOLS}, ["--instance=wght=400"])
    match_vertical_metrics(SYMBOLS_FONT, fonts_dir / "Roboto-Variable.ttf")


def font_codepoints(path: Path) -> set[int]:
    """The code points the font at ``path`` maps to a glyph (its cmap), read with HarfBuzz's hb-info."""
    listing = subprocess.run(["hb-info", "--list-unicodes", str(path)], check=True, capture_output=True, text=True).stdout
    return {int(m, 16) for m in re.findall(r"^U\+([0-9A-F]+)\t", listing, re.M)}


def _tables(data: bytes) -> dict[str, tuple[int, int, int]]:
    """The sfnt table directory of font ``data``: tag -> (record offset, table offset, table length)."""
    count = int.from_bytes(data[4:6], "big")
    tables = {}
    for i in range(count):
        record = 12 + 16 * i
        tag = data[record:record + 4].decode("latin-1")
        tables[tag] = (record, int.from_bytes(data[record + 8:record + 12], "big"), int.from_bytes(data[record + 12:record + 16], "big"))
    return tables


def _checksum(block: bytes) -> int:
    """The OpenType checksum of ``block``: the sum of its big-endian uint32 words, zero-padded, mod 2^32."""
    block += b"\0" * (-len(block) % 4)
    return sum(int.from_bytes(block[i:i + 4], "big") for i in range(0, len(block), 4)) & 0xFFFFFFFF


def match_vertical_metrics(path: Path, reference: Path) -> None:
    """Rewrites the vertical metrics of the font at ``path`` (hhea ascender, descender and line gap;
    OS/2 typo ascender, descender, line gap and win ascent and descent) to ``reference``'s, scaled by
    the two fonts' units per em and rounded toward zero, then fixes the table checksums and head's
    checkSumAdjustment. Why: Godot's Font.get_height() is the tallest of the whole fallback chain
    (DESIGN.md, "Fonts"), and FreeType takes a face's ascent from hhea (falling back to OS/2), so a
    fallback whose metrics are no larger than its base font's leaves the base's line height alone.
    Stdlib only (struct-free byte edits), so the tool needs no fontTools. Side effect: rewrites ``path``."""
    data, ref = bytearray(path.read_bytes()), reference.read_bytes()
    tables, ref_tables = _tables(bytes(data)), _tables(ref)

    def field(blob: bytes, where: dict, tag: str, offset: int, signed: bool) -> int:
        start = where[tag][1] + offset
        return int.from_bytes(blob[start:start + 2], "big", signed=signed)

    scale = field(data, tables, "head", 18, False) / field(ref, ref_tables, "head", 18, False)
    # (table, offset, signed): hhea ascender, descender, lineGap; OS/2 sTypoAscender, sTypoDescender,
    # sTypoLineGap, usWinAscent, usWinDescent (OpenType spec offsets).
    fields = [("hhea", 4, True), ("hhea", 6, True), ("hhea", 8, True), ("OS/2", 68, True), ("OS/2", 70, True),
              ("OS/2", 72, True), ("OS/2", 74, False), ("OS/2", 76, False)]
    for tag, offset, signed in fields:
        value = int(field(ref, ref_tables, tag, offset, signed) * scale)  # int() rounds toward zero
        start = tables[tag][1] + offset
        data[start:start + 2] = value.to_bytes(2, "big", signed=signed)
    head = tables["head"][1]
    data[head + 8:head + 12] = bytes(4)  # checkSumAdjustment is left out of every checksum
    for record, offset, length in tables.values():
        data[record + 4:record + 8] = _checksum(bytes(data[offset:offset + length])).to_bytes(4, "big")
    data[head + 8:head + 12] = ((0xB1B0AFBA - _checksum(bytes(data))) & 0xFFFFFFFF).to_bytes(4, "big")
    path.write_bytes(bytes(data))


def _game_path(resource: str) -> Path:
    """The file in the repository behind a game path such as "res://assets/fonts/x.otf"."""
    return REPO / "apps" / "game" / resource.removeprefix("res://")


def _hb_subset(src: Path, out: Path, codepoints: set[int], extra: list[str] | None = None) -> None:
    """hb-subset of ``src`` to ``out`` keeping ``codepoints`` (glyph names dropped, layout kept);
    ``extra`` adds hb-subset options such as --instance."""
    unicodes = ",".join(f"{cp:04X}" for cp in sorted(codepoints))
    subprocess.run(["hb-subset", f"--output-file={out}", f"--unicodes={unicodes}", *(extra or []), str(src)], check=True)


def fill(pot: Path, trans: Path, outdir: Path) -> None:
    """Writes one PO per language from the POT and the translations file. Each entry gets TRANS's context
    as a "#. TRANSLATORS:" note and its marks (TRANS "marks", by msgid) as "#. i18n: ..." (MARKS), the
    header gets the language's Plural-Forms from languages.json, and a msgid with a printf insert gets
    "#, c-format" so msgfmt --check-format compares the inserts."""
    data = json.loads(trans.read_text(encoding="utf-8"))
    entries = read_po(pot)
    outdir.mkdir(parents=True, exist_ok=True)
    # gettext's header date form; the run's own time, so the file says when it was written.
    revised = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M+0000")
    for lang, texts in data["translations"].items():
        unused = set(texts) - {e["msgid"] for e in entries}
        if unused:
            sys.exit(f"{lang}: translations for msgids the POT lacks: {sorted(unused)}")
        out = []
        for entry in entries:
            if not entry["msgid"]:
                header = ("Project-Id-Version: WOLF OVERRIDE\\n", f"PO-Revision-Date: {revised}\\n",
                          "Last-Translator: Claude (Anthropic), machine translation, unreviewed\\n", "Language-Team: none\\n", "MIME-Version: 1.0\\n",
                          "Content-Type: text/plain; charset=UTF-8\\n", "Content-Transfer-Encoding: 8bit\\n",
                          f"Language: {lang}\\n", f"Plural-Forms: {LANGUAGES[lang]['plural_forms']}\\n")
                out.append("# Machine translation by Claude (Anthropic); no native speaker has reviewed it yet.\n"
                           'msgid ""\nmsgstr ""\n' + "\n".join(f'"{h}"' for h in header))
                continue
            # A plural entry gets one msgstr per plural form of the language.
            forms = plural_count(lang) if "msgid_plural" in entry else 1
            done = dict(entry, comments=list(entry["comments"]), msgstr=[""] * forms)
            if any(token != "%%" for token in POSITIONAL.findall(entry["msgid"])) and not any(c.startswith("#,") for c in done["comments"]):
                # Godot's generator writes no format flag; with it msgfmt --check-format compares the
                # translation's printf inserts with the msgid's (the pipeline step's msgfmt gate).
                done["comments"].append("#, c-format")
            mark = data.get("marks", {}).get(entry["msgid"])
            note = data["context"].get(entry["msgid"])
            if "fuzzy" in f"{mark} {note}":
                # Godot would skip the line for the word alone (Gotchas), so it never reaches a PO.
                sys.exit(f"the note or mark for {entry['msgid']!r} contains 'fuzzy'; reword it")
            if mark:
                done["comments"].insert(0, f"#. i18n: {mark}")
            if note:
                done["comments"].insert(0, f"#. TRANSLATORS: {note}")
            if entry["msgid"] in texts:
                done["comments"].insert(0, "# machine-translated by Claude (Anthropic), unreviewed")
                done["msgstr"] = [texts[entry["msgid"]]]
            out.append(write_entry(done))
        (outdir / f"{lang}.po").write_text("\n\n".join(out) + "\n", encoding="utf-8")
        print(f"{lang}.po: {len(texts)} of {len(entries) - 1} messages translated")


#: How the back-translation prompt names each engineer role (engineer_roles) for one text.
ROLE_WORDS = {"name": "named (their first name fills %s or {name})", "you": "addressed as 'you'",
              "third": "referred to without their name", "self": "speaking (first person)"}


def backprompt(podir: Path, out: Path) -> None:
    """The Codex prompt: back-translate every translated, non-fuzzy message, given without its English.
    Each text carries its id (language + entry_key, so answers survive a msgmerge), who speaks and how the
    engineer appears (from its marks), which the engineer_gendered answer needs for "you" lines and lines
    with no name slot. Plural entries send msgstr[0] only; the plural gate checks the other forms."""
    items = {}
    for po in sorted(podir.glob("*.po")):
        lang = po.stem
        for entry in (e for e in read_po(po) if e["msgid"] and e["msgstr"] and e["msgstr"][0] and not is_fuzzy(e)):
            found, roles = marks(entry), engineer_roles(entry)
            slot = {"key": "%s is a key name", "choice": "%s is an answer the engineer chose, quoted"}.get(found.get("slot", ""), "")
            items[f"{lang}-{entry_key(entry)}"] = {
                "language": LANGUAGES[lang]["glossary"], "speaker": found.get("speaker", "unknown"),
                "engineer": "; ".join([ROLE_WORDS[r] for r in sorted(roles)] + ([slot] if slot else [])) or "not in this text",
                "text": entry["msgstr"][0]}
    out.write_text(
        "You are checking game UI and dialogue translations by back-translating them. Translate each text below "
        "into plain, literal English, keeping placeholders (%s, %d), the token 'E:' and line breaks (\\n) exactly "
        "as they appear. Do not guess what the original English was; translate only what is written. Context: a "
        "2D sci-fi game; WOLF is a robot wolf (he), the Director a human (he), the sentry a machine; the player "
        "character is a non-binary engineer (they/them). Each item says who speaks ('speaker': WOLF, narrator, "
        "hint for the hint bar that addresses the player, ui) and how the engineer appears in it ('engineer'). "
        "After each back-translation add 'notes' listing anything ambiguous, unidiomatic or gendered in the "
        "source text (empty string if none), and 'engineer_gendered': true only if the text shows the "
        "grammatical gender of the engineer: when the engineer is addressed, by a verb, adjective or participle "
        "agreeing with 'you'; when named or referred to, by a past-tense ending, an agreeing adjective or "
        "participle, a gendered job noun or a gendered pronoun (he/she, 彼/彼女, 他/她, 그/그녀); false "
        "otherwise, including when only WOLF, the Director or the sentry is gendered. Answer with JSON only: "
        '{"back": {"<id>": {"english": "...", "notes": "...", "engineer_gendered": false}}}. Do not run any '
        "commands or read any files.\n\n"
        + json.dumps(items, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"{len(items)} texts in {out}")


def script_ok(text: str, lang: str, keep: list[str]) -> bool:
    """The script guard (SCRIPT_GUARD) for one translation ``text`` in ``lang``."""
    if LANGUAGES[lang]["script"] != "cyrillic":
        return not SCRIPT_GUARD["cyrillic"].search(text)
    for word in sorted(keep, key=len, reverse=True):
        text = text.replace(word, "")
    return not SCRIPT_GUARD["latin"].search(text)


# ------------------------------------------------------------------ glossary and style guides
#: The per-language style guides (PR L5): i18n/style/<glossary key>.md for every key the glossary covers,
#: plus README.md, the rules every language shares. Outside res:// with the glossary (DESIGN.md).
STYLE_DIR = REPO / "i18n" / "style"
#: The shared guide's file stem; every per-language guide links it.
STYLE_SHARED = "README"
#: The headings every per-language guide carries, in any order, so a native reviewer finds the same
#: things in every language and a new guide cannot leave out the engineer's rules (decision D9).
STYLE_SECTIONS = ("## Address and register", "## The engineer", "## WOLF", "## Names",
                  "## Quotes and punctuation", "## Open questions")
#: A glossary form's states: "trial" (the research trial's word), "proposed" (written in PR L5; gated)
#: and "open" (a reviewer's word: "required" is null and only "avoid" is gated).
GLOSSARY_STATUSES = ("trial", "proposed", "open")
#: The fields a glossary form may hold besides "status" and "required"; each is a list of strings.
GLOSSARY_LISTS = ("variants", "proposals", "avoid")


def glossary_codes(glossary: dict) -> dict[str, str]:
    """The Godot locale code of each glossary key ``glossary`` covers ("es-419" -> "es"), from
    languages.json's "glossary" fields; a key no row names is left out (glossary_problems reports it).
    Pure."""
    by_key = {row["glossary"]: code for code, row in LANGUAGES.items()}
    return {key: by_key[key] for key in glossary.get("languages", []) if key in by_key}


def glossary_problems(glossary: dict, styles: dict[str, str]) -> list[str]:
    """Every way ``glossary`` (i18n/glossary.json, parsed) and ``styles`` (style guide text by file stem,
    read_styles) fall short of the shape the gates and the reviewers rely on, as readable lines; empty
    when both are sound. Checked: each covered key is a languages.json "glossary" value and has a style
    guide with every STYLE_SECTIONS heading, and no guide is for another key; "inherit" maps covered keys;
    every term has a "note" and a form for every covered key that inherits nothing; each form has a known
    status, a "required" string unless open (null when open), list fields only, and no "avoid" form that
    is also an accepted one; every word (forms and the stored names) passes its language's script guard
    (script_ok), so no Latin plate word slips into the Russian glossary; Korean names carry a particle
    class. Pure: the selftest plants broken copies through it."""
    problems: list[str] = []
    keys = glossary.get("languages", [])
    codes = glossary_codes(glossary)
    keep = glossary.get("keep", [])
    problems += [f"languages: {key} is no languages.json glossary key" for key in keys if key not in codes]
    inherit = glossary.get("inherit", {})
    problems += [f"inherit: {k} -> {v} names a key the glossary does not cover" for k, v in inherit.items()
                 if k not in keys or v not in keys]
    for term, forms in glossary.get("terms", {}).items():
        if not str(forms.get("note", "")).strip():
            problems.append(f"{term}: no note")
        for key in sorted(set(forms) - {"note"} - set(keys)):
            problems.append(f"{term}: form for {key}, which the glossary does not cover")
        for key in keys:
            form = forms.get(key)
            if form is None:
                if key not in inherit:
                    problems.append(f"{term}: no form for {key}")
                continue
            status = form.get("status")
            if status not in GLOSSARY_STATUSES:
                problems.append(f"{term} [{key}]: status {status!r} is not one of {GLOSSARY_STATUSES}")
            required = form.get("required")
            if status == "open" and required is not None:
                problems.append(f"{term} [{key}]: open, so 'required' must be null")
            if status != "open" and not (isinstance(required, str) and required):
                problems.append(f"{term} [{key}]: {status}, so it needs a 'required' form")
            for field in sorted(set(form) - {"status", "required", *GLOSSARY_LISTS}):
                problems.append(f"{term} [{key}]: unknown field {field!r}")
            if not all(isinstance(form.get(field, []), list) for field in GLOSSARY_LISTS):
                problems.append(f"{term} [{key}]: {', '.join(GLOSSARY_LISTS)} must be lists")
                continue
            accepted = {f.casefold() for f in [required] + form.get("variants", []) if f}
            problems += [f"{term} [{key}]: avoid form {bad!r} is also accepted" for bad in form.get("avoid", [])
                         if bad.casefold() in accepted]
            words = [w for w in [required] + [w for field in GLOSSARY_LISTS for w in form.get(field, [])] if w]
            if key in codes:
                problems += [f"{term} [{key}]: {word!r} fails the {LANGUAGES[codes[key]]['script']} script guard"
                             for word in words if not script_ok(word, codes[key], keep)]
    for name, written in glossary.get("names", {}).items():
        for key, word in written.items():
            if key == "ko_particles":
                if word not in ("consonant", "vowel"):
                    problems.append(f"names {name}: ko_particles must be 'consonant' or 'vowel'")
            elif key not in codes:
                problems.append(f"names {name}: {key} is not a covered key")
            elif not script_ok(word, codes[key], keep):
                problems.append(f"names {name} [{key}]: {word!r} fails the script guard")
        if "ko" in written and "ko_particles" not in written:
            problems.append(f"names {name}: a Korean name needs its ko_particles")
    if STYLE_SHARED not in styles:
        problems.append(f"style: no {STYLE_SHARED}.md, the shared guide")
    for key in keys:
        text = styles.get(key)
        if text is None:
            problems.append(f"style: no {key}.md")
            continue
        lines = set(text.splitlines())
        problems += [f"style {key}.md: no '{heading}' section" for heading in STYLE_SECTIONS if heading not in lines]
        if f"({STYLE_SHARED}.md)" not in text:
            problems.append(f"style {key}.md: does not link the shared guide ({STYLE_SHARED}.md)")
    problems += [f"style: {stem}.md is for no covered key" for stem in sorted(set(styles) - set(keys) - {STYLE_SHARED})]
    return problems


def read_styles() -> dict[str, str]:
    """Every style guide in STYLE_DIR as {file stem: text}."""
    return {path.stem: path.read_text(encoding="utf-8") for path in sorted(STYLE_DIR.glob("*.md"))}


def glossary_check() -> None:
    """The `glossary` subcommand: prints glossary_problems for the repository's glossary and style guides
    and exits 1 when there is any (CI runs it), else prints what it covered. Writes nothing."""
    glossary = json.loads(GLOSSARY_FILE.read_text(encoding="utf-8"))
    problems = glossary_problems(glossary, read_styles())
    for problem in problems:
        print(problem)
    if problems:
        sys.exit(1)
    forms = [form for forms in glossary["terms"].values() for key, form in forms.items() if key != "note"]
    print(f"glossary: {len(glossary['terms'])} terms in {len(glossary['languages'])} languages "
          f"({sum(f['status'] == 'open' for f in forms)} forms still open), {len(read_styles())} style guides: sound")


def gendered_words(text: str, lang: str, roles: set[str]) -> list[str]:
    """The words of ``text`` that show the engineer's gender in ``lang``, for a line where the engineer
    appears as ``roles`` (engineer_roles). Six checks, from gender_rule(lang):
      1. name: a "forms" or "near_forms" word within GENDER_WINDOW words before a NAME_SLOT in its clause
         (CLAUSE_SPLIT), or after it across a comma or dash (APPOSITION_SPLIT: "%s, усталая,",
         "%s — раненая", "%s, la nueva técnica");
      2. you: a "near_forms" word within GENDER_WINDOW words of a second-person pronoun ("Tu es assise",
         "Ты усталая");
      3. clause: every "forms" word in a clause that holds a second-person pronoun ("you"; this catches
         the vocative "%s, ты была права"), and, when the engineer is addressed or referred to without
         the name (roles "you" or "third"), in every clause with no first-person subject pronoun, so
         WOLF's own "Я отказался" stays clear while "Ты нашла" is flagged. Words that are first person
         by their ending ("first_forms", Polish "Odmówiłem") are WOLF's and skipped;
      4. self: when the engineer speaks ("self"), every "forms" and "first_forms" word;
      5. pronoun: a gendered third-person pronoun ("pronouns") anywhere for "third", or in the sentence
         holding the name and the one after it for "name" ("%s ist ... Sie wartet", "彼女は%sだ");
      6. person word: a gendered noun or honorific for a person ("person_words": 女の子, 小姐, 언니)
         anywhere in a line where the engineer appears at all.
    Empty for a line with no roles or a language with no rule. Each word once, in order. Pure.
    A heuristic: a pronoun that means WOLF or the sentry next to the name is flagged too (a look, cleared
    by a "# gender-ok:" stamp), and a gendered word it has no pattern for is missed (native review;
    PIPELINE.md lists the form classes it does not cover)."""
    rule = gender_rule(lang)
    if not rule or not roles:
        return []
    forms, near_forms, first_forms, hits = rule.get("forms"), rule.get("near_forms"), rule.get("first_forms"), []

    def flag(words: list[str], own_too: bool = False, near: bool = False) -> None:
        """Adds each of ``words`` that is a gendered form: "forms" always, "near_forms" when ``near``
        (the word sits next to the name or a "you"), first-person forms only when ``own_too``."""
        for word in words:
            bare = word.strip(WORD_STRIP).lower()
            if first_forms and first_forms.match(bare):
                if own_too:
                    hits.append(bare)
            elif (forms and forms.match(bare)) or (near and near_forms and near_forms.match(bare)):
                hits.append(bare)

    for clause in CLAUSE_SPLIT.split(text):
        words = clause.split()
        if "name" in roles:
            for index, word in enumerate(words):
                if NAME_SLOT.search(word):
                    flag(words[max(0, index - GENDER_WINDOW):index], near=True)
        if "you" in rule:
            for index, word in enumerate(words):
                if rule["you"].search(word.strip(WORD_STRIP).lower()):
                    flag(words[max(0, index - GENDER_WINDOW):index] + words[index + 1:index + 1 + GENDER_WINDOW], near=True)
        addressed = "you" in rule and rule["you"].search(clause)
        about = bool(roles & {"you", "third"}) and not ("first_person" in rule and rule["first_person"].search(clause))
        if "self" in roles:
            flag(words, own_too=True)
        elif addressed or about:
            flag(words)
    if "name" in roles:
        for phrase in APPOSITION_SPLIT.split(text):
            words = APPOSITION_MARKS.sub(" ", phrase).split()
            for index, word in enumerate(words):
                if NAME_SLOT.search(word):
                    flag(words[index + 1:index + 1 + GENDER_WINDOW], near=True)
    if "pronouns" in rule and roles & {"name", "third"}:
        # Empty pieces (". \n" ends one sentence twice) are dropped, so "the next sentence" is a real one.
        sentences = [piece for piece in SENTENCE_SPLIT.split(text) if piece.strip()]
        for index, sentence in enumerate(sentences):
            if "third" in roles or NAME_SLOT.search(sentence) or (index and NAME_SLOT.search(sentences[index - 1])):
                hits += [match.group(0).strip().lower() for match in rule["pronouns"].finditer(sentence)]
    if "person_words" in rule:
        hits += [match.group(0).lower() for match in rule["person_words"].finditer(text)]
    return list(dict.fromkeys(hits))


def name_case_ok(text: str, lang: str, roles: set[str]) -> bool:
    """False when ``lang`` declines names (languages.json name_case) and a letter is glued to the name
    slot in ``text`` (NAME_CASE), the case ending PIPELINE.md's nominative-only rule forbids."""
    return not (LANGUAGES[lang].get("name_case") and "name" in roles and NAME_CASE.search(text))


def family_gaps(po_entries: dict[str, list[dict]]) -> dict[str, list[str]]:
    """For every language whose family (languages.json) has two or more PO files here: the msgids that a
    sibling file translates but this one leaves untranslated, fuzzy or with an empty plural form. Godot
    looks each message up in every loaded file of the language (core/string/translation_domain.cpp,
    get_message_from_translations, 4.7.2), so such a gap shows the sibling's text (Simplified characters
    in a Traditional line, Latin-American Spanish in Spain's file), not English. A line no file of the
    family translates falls to English and is no gap; languages with no sibling are left out. Pure."""
    def done(entries: list[dict]) -> set[tuple[str, str]]:
        return {(e.get("msgctxt", ""), e["msgid"]) for e in entries if e["msgid"] and e["msgstr"] and all(e["msgstr"]) and not is_fuzzy(e)}

    families: dict[str, list[str]] = {}
    for lang in po_entries:
        families.setdefault(LANGUAGES[lang]["family"], []).append(lang)
    gaps: dict[str, list[str]] = {}
    for langs in families.values():
        if len(langs) < 2:
            continue
        translated = {lang: done(po_entries[lang]) for lang in langs}
        for lang in langs:
            elsewhere = set().union(*(translated[other] for other in langs if other != lang))
            gaps[lang] = sorted(msgid for _, msgid in elsewhere - translated[lang])
    return gaps


def header_plural_rule(header: str) -> str | None:
    """The value of a PO header's "Plural-Forms:" line with its whitespace collapsed, or None when the
    header has no such line."""
    match = re.search(r"^Plural-Forms:(.*)$", header, re.MULTILINE)
    return " ".join(match.group(1).split()) if match else None


def plural_header_ok(header: str, lang: str) -> bool:
    """True when the PO header's Plural-Forms value is ``lang``'s rule in languages.json, word for word
    (whitespace aside). Not "it parses": Godot loads a 2-form file whose rule does not parse with the
    English rule and no error (Gotchas), so only an exact match proves the shipped rule."""
    return header_plural_rule(header) == " ".join(LANGUAGES[lang]["plural_forms"].split())


def nplurals(header: str) -> int:
    """The nplurals of a PO header's Plural-Forms line (1 when the header has none)."""
    match = re.search(r"nplurals\s*=\s*(\d+)", header)
    return int(match.group(1)) if match else 1


def plural_problems(entry: dict, forms: int) -> list[str]:
    """What is wrong with a plural entry's msgstr[n] for a language with ``forms`` plural forms: the
    wrong number of forms, an empty form, or a form whose inserts differ from its English (form 0 against
    msgid, the others against msgid_plural; placeholders_ok). Empty for a non-plural entry. A wrong
    count matters beyond the line: Godot's PO loader rejects the whole file for it, as it does for a
    msgid_plural under a header with no Plural-Forms line (core/io/translation_loader_po.cpp; an
    unparsable rule is plural_header_ok's job, see Gotchas)."""
    if "msgid_plural" not in entry:
        return []
    problems = [] if len(entry["msgstr"]) == forms else [f"{len(entry['msgstr'])} forms, the header says {forms}"]
    for index, text in enumerate(entry["msgstr"]):
        english = entry["msgid"] if index == 0 else entry["msgid_plural"]
        if not text:
            problems.append(f"msgstr[{index}] is empty")
        elif not placeholders_ok(english, text):
            problems.append(f"msgstr[{index}] inserts differ from the English")
    return problems


#: The mark a story-critical line carries ("#. i18n: story", written as "# TRANSLATORS: i18n: story" in
#: the source by PR L7c): a release may not ship it untranslated in any language (release_problems).
STORY_MARK = "story"


def _message_id(entry: dict) -> tuple[str, str]:
    """An entry's (msgctxt, msgid): what makes a message one message ("CONTINUE" with a context tag is
    another message than plain "CONTINUE")."""
    return entry.get("msgctxt", ""), entry["msgid"]


def release_problems(entries: list[dict], pot_entries: list[dict], review: str) -> list[str]:
    """The release gates (PIPELINE.md, "When the English changes", step 7) for one language's PO
    ``entries`` against the POT's ``pot_entries``, where ``review`` is the language's review state in
    languages.json ("machine" or "reviewed"):
      - in a "reviewed" language, every fuzzy entry (is_fuzzy), since msgmerge marks a line fuzzy when
        its English changed and a reviewed language may not ship a line nobody re-read;
      - in any language, every message marked STORY_MARK (in the POT or the PO) that the PO lacks, leaves
        empty (any msgstr[n]) or has fuzzy, since Godot then shows the English line in the middle of
        the story.
    Each problem is one sentence naming the msgid. Empty when the language may ship. Pure.
    Not part of the everyday `check`: a language in progress has many untranslated lines on purpose
    (the prototype's left 115 each), so only release CI runs `check --release`."""
    problems = []
    if review == "reviewed":
        problems += [f"fuzzy in a reviewed language: {e['msgid']!r}" for e in entries if e["msgid"] and is_fuzzy(e)]
    by_id = {_message_id(e): e for e in entries if e["msgid"]}
    story = {_message_id(e) for e in pot_entries + entries if e["msgid"] and STORY_MARK in marks(e)}
    for key in sorted(story):
        entry = by_id.get(key)
        if entry is None or not entry["msgstr"] or not all(entry["msgstr"]):
            problems.append(f"story line untranslated: {key[1]!r}")
        elif is_fuzzy(entry):
            problems.append(f"story line fuzzy: {key[1]!r}")
    return problems


#: The per-line gates that must all hold for a line to pass (each a boolean measure in the report).
LINE_GATES = ("placeholders_ok", "tag_ok", "breaks_ok", "key_token_ok", "script_ok", "bbcode_ok", "gender_ok", "name_case_ok")


def check(pot: Path, podir: Path, out: Path, back: Path | None = None, release: bool = False) -> None:
    """Runs every automated gate on the PO files in ``podir``, writes the report to ``out`` and exits 1
    when any language fails: a failed line, a non-zero msgfmt, a gap in a language with a sibling file
    (family_gaps), a header Plural-Forms rule other than languages.json's (plural_header_ok), a comment
    that would make Godot skip a line (fuzzy_notes), a msgid whose call sites disagree on a mark
    (mark_conflicts, in the POT or the PO), or, with ``release``, a release problem (release_problems).
    ``back`` is the back-translation file; without it no line has a back-translation (back_missing) and
    only the back-translation's own gate is skipped. A PO whose language is not in languages.json stops
    the run; a ``podir`` with no PO file writes a report with no language and passes."""
    glossary = json.loads(GLOSSARY_FILE.read_text(encoding="utf-8"))
    backs = json.loads(back.read_text(encoding="utf-8"))["back"] if back is not None else {}
    pot_entries = read_po(pot)
    po_entries = {po.stem: read_po(po) for po in sorted(podir.glob("*.po"))}
    unknown = sorted(set(po_entries) - set(LANGUAGES))
    if unknown:
        sys.exit(f"PO files for languages missing from {LANGUAGES_FILE.name}: {unknown}")
    gaps = family_gaps(po_entries)
    pot_conflicts = {msgid: mark_conflicts(entry) for msgid, entry in messages(pot).items() if mark_conflicts(entry)}
    report: dict = {"pot_messages": len(messages(pot)), "pot_mark_conflicts": pot_conflicts, "release": release, "languages": {}}
    for lang, entries in po_entries.items():
        fmt = subprocess.run(["msgfmt", "--check-format", "--check-header", "-o", "/dev/null", "--statistics", str(podir / f"{lang}.po")],
                             capture_output=True, text=True)
        rows = []
        header = next((e["msgstr"][0] for e in entries if not e["msgid"] and e["msgstr"]), "")
        translated = [e for e in entries if e["msgid"] and e["msgstr"] and e["msgstr"][0] and not is_fuzzy(e)]
        for entry in translated:
            english, text = entry["msgid"], entry["msgstr"][0]
            roles = engineer_roles(entry)
            measures = line_measures(english, text, LANGUAGES[lang]["glossary"], glossary)
            keep_breaks = any(BREAKS_KEEP in c for c in entry["comments"])
            measures["breaks_ok"] = (text.count("\n") == english.count("\n")) if keep_breaks else text.count("\n") <= english.count("\n")
            measures["key_token_ok"] = len(KEY_TOKEN.findall(english)) == len(KEY_TOKEN.findall(text))
            measures["script_ok"] = script_ok(text, lang, glossary["keep"])
            measures["bbcode_ok"] = bbcode_ok(english, text)
            gender_stamped = any(c.startswith("# gender-ok:") for c in entry["comments"])
            measures["engineer_roles"] = sorted(roles)
            measures["gender_words"] = gendered_words(text, lang, roles)
            measures["gender_ok"] = gender_stamped or not measures["gender_words"]
            measures["name_case_ok"] = name_case_ok(text, lang, roles)
            measures["plural_problems"] = plural_problems(entry, plural_count(lang))
            measures["back_key"] = f"{lang}-{entry_key(entry)}"
            item = backs.get(measures["back_key"])
            measures["back_engineer_gendered"] = item.get("engineer_gendered") if item else None
            if item:
                measures["back"] = item["english"]
                measures["back_notes"] = item.get("notes", "")
                measures["chrf"] = chrf(item["english"], english)
                measures["drift_flag"] = measures["chrf"] < 35 and len(english.split()) > 4
            # A missing answer or one filed before the engineer_gendered field existed reads None: no
            # verdict, so only an explicit true fails the line (back_missing counts the lines with none).
            back_gender_ok = gender_stamped or measures["back_engineer_gendered"] is not True
            measures["ok"] = (all(measures[k] for k in LINE_GATES) and back_gender_ok
                              and not measures["glossary_missing"] and not measures["glossary_avoided"]
                              and not measures["plural_problems"])
            rows.append({"msgid": english, "msgstr": text, **measures})
        failed = [r["msgid"] for r in rows if not r["ok"]]
        notes = [e["msgid"] for e in entries if e["msgid"] and fuzzy_notes(e)]
        conflicts = {e["msgid"]: mark_conflicts(e) for e in entries if e["msgid"] and mark_conflicts(e)}
        header_ok = plural_header_ok(header, lang)
        shipping = release_problems(entries, pot_entries, LANGUAGES[lang].get("review", "")) if release else []
        report["languages"][lang] = {
            "ok": (fmt.returncode == 0 and not failed and not gaps.get(lang) and header_ok and not notes
                   and not conflicts and not pot_conflicts and not shipping),
            "release_problems": shipping,
            "msgfmt_rc": fmt.returncode, "msgfmt": (fmt.stdout + fmt.stderr).strip(),
            "plural_header_ok": header_ok, "fuzzy_notes": notes, "mark_conflicts": conflicts,
            "translated": len(translated), "fuzzy": [e["msgid"] for e in entries if e["msgid"] and is_fuzzy(e)],
            "family_gaps": gaps.get(lang), "failed": failed,
            "back_missing": sum(1 for r in rows if "back" not in r),
            "drift_flags": [r["msgid"] for r in rows if r.get("drift_flag")], "rows": rows,
        }
    out.write_text(json.dumps(report, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    for lang, data in report["languages"].items():
        gap = "" if data["family_gaps"] is None else f", {len(data['family_gaps'])} sibling gaps"
        print(f"{lang}: msgfmt rc {data['msgfmt_rc']} ({data['msgfmt']}); {data['translated']} checked, "
              f"{len(data['failed'])} failed, {len(data['drift_flags'])} drift flags, "
              f"{data['back_missing']} without a back-translation{gap}"
              + (f", {len(data['release_problems'])} release problems" if release else ""))
    if not report["languages"]:
        print(f"no PO files in {podir}: nothing to check")
    if pot_conflicts:
        print(f"the POT's call sites disagree on marks: {pot_conflicts}")
    if pot_conflicts or not all(data["ok"] for data in report["languages"].values()):
        sys.exit(1)


#: The planted cases `selftest` runs: (gate, language, English, translation, should it pass, engineer
#: mark). For "plural_header" the translation slot holds a PO header, for "fuzzy_note" and "marks" an
#: entry's comment lines. Each gate gets clean lines that must pass (some are the prototype's real Russian knockdown
#: lines, which put another subject's verb or an impersonal verb near the name) and planted errors that
#: must fail; the reviewers' planted gender lines of October 16 are among them. An empty mark means the
#: default (engineer=name when the line has a slot).
SELFTEST = [
    ("placeholders", "ru", "{current} of {total} turns.", "{current} из {total} оборотов.", True, ""),
    ("placeholders", "ja", "{current} of {total} turns.", "{total}回中{current}回。", True, ""),
    ("placeholders", "ru", "{current} of {total} turns.", "{current} из {totl} оборотов.", False, ""),
    ("placeholders", "ru", "{current} of {total} turns.", "{current} оборотов.", False, ""),
    ("placeholders", "de", "HOLD %s: crank, %d of %d.", "%d von %d: HALTEN %s.", False, ""),
    ("placeholders", "de", "%02d:%02d left", "noch %02d", False, ""),
    ("placeholders", "de", "%.1f s", "s", False, ""),
    ("placeholders", "ru", "{0} of {1}", "{1}", False, ""),
    ("placeholders", "ru", "{0} of {1}", "{0} из {1}", True, ""),
    ("placeholders", "fr", "%d%% done", "%d %% fait", True, ""),
    ("bbcode", "de", "[b]%s[/b] waits.", "[b]%s wartet.", False, ""),
    ("bbcode", "de", "[center][b]CREDITS[/b][/center]", "[center][b]MITWIRKENDE[/b][/center]", True, ""),
    ("bbcode", "de", "[color=#ff8800]WOLF[/color]", "[color=#00ff00]WOLF[/color]", False, ""),
    ("bbcode", "de", "[b]A[/b] [i]B[/i]", "[i]B[/i] [b]A[/b]", True, ""),
    ("bbcode", "de", "[b][i]A[/i][/b]", "[b][i]A[/b][/i]", False, ""),
    ("gender", "ru", "", "Сорвало предохранительный клапан, а %s — прямо на решётке.", True, ""),
    ("gender", "ru", "", "Страж заметил: %s на открытом месте.", True, ""),
    ("gender", "ru", "", "%s стояла на решётке, и клапан сорвало.", False, ""),
    ("gender", "ru", "", "%s был прямо на решётке.", False, ""),
    ("gender", "ru", "", "%s, ты была права.", False, ""),
    ("gender", "ru", "", "WOLF: Ты сказала мне правду у реле.", False, "you"),
    ("gender", "ru", "", "WOLF: Ты сказала «%s»\nЯ отказался. Ты нашла другой путь.", False, "you"),
    ("gender", "ru", "", "WOLF: Я отказался. Спасибо за правду.", True, "you"),
    ("gender", "ru", "", "Страж увидел её на открытом месте.", False, "third"),
    ("gender", "pl", "", "%s stoi na kratce.", True, ""),
    ("gender", "pl", "", "%s stała na kratce.", False, ""),
    ("gender", "pl", "", "WOLF: Powiedziałaś mi prawdę.", False, "you"),
    ("gender", "pl", "", "WOLF: Dziękuję za prawdę. Biorę przekaźnik.", True, "you"),
    ("gender", "pl", "", "WOLF: Odmówiłem. Znalazłaś inną drogę.", False, "you"),
    ("gender", "pl", "", "WOLF: Odmówiłem. Dziękuję.", True, "you"),
    ("gender", "pl", "", "Odmówiłam.", False, "self"),
    ("gender", "es", "", "La válvula de alivio cedió y %s quedó sobre la rejilla.", True, ""),
    ("gender", "es", "", "%s estaba sola sobre la rejilla.", False, ""),
    ("gender", "es", "", "WOLF: Estabas sola en la rejilla.", False, "you"),
    ("gender", "fr", "", "%s est restée seule sur la grille.", False, ""),
    ("gender", "de", "", "%s stand allein auf dem Gitter.", True, ""),
    ("gender", "de", "", "%s ist die Ingenieurin. Sie wartet.", False, ""),
    ("gender", "de", "", "Der Wächter hat %s gesehen.\nSie soll am Tank bleiben.", False, ""),
    ("gender", "ja", "", "%sは格子の上にいる。", True, ""),
    ("gender", "ja", "", "彼女は%sだ。", False, ""),
    ("gender", "zh_Hans", "", "%s站在格栅上。", True, ""),
    ("gender", "zh_Hans", "", "她是%s。", False, ""),
    # The review-feasibility-3 planted lines (October 16): the commonest feminine and masculine forms
    # per language. Each must fail; the clean lines after each language must still pass.
    ("gender", "fr", "", "%s est sortie.", False, ""),
    ("gender", "fr", "", "%s est partie.", False, ""),
    ("gender", "fr", "", "%s est morte.", False, ""),
    ("gender", "fr", "", "%s est mort.", False, ""),
    ("gender", "fr", "", "%s est heureuse.", False, ""),
    ("gender", "fr", "", "%s est heureux.", False, ""),
    ("gender", "fr", "", "WOLF : Tu es assise.", False, "you"),
    ("gender", "fr", "", "WOLF : Tu es assis.", False, "you"),
    ("gender", "fr", "", "%s, la technicienne, ouvre la vanne.", False, ""),
    ("gender", "fr", "", "%s ouvre la porte de la sortie.", True, ""),
    ("gender", "fr", "", "WOLF : Tu vois la porte ? Va vers la batterie.", True, "you"),
    ("gender", "es", "", "%s está muerta.", False, ""),
    ("gender", "es", "", "%s está muerto.", False, ""),
    ("gender", "es", "", "%s está despierta.", False, ""),
    ("gender", "es", "", "%s, la nueva técnica, revisa el panel.", False, ""),
    ("gender", "es", "", "%s, el nuevo técnico, revisa el panel.", False, ""),
    ("gender", "es", "", "WOLF: ¿Estás cansada?", False, "you"),
    ("gender", "es", "", "%s abre la puerta de salida.", True, ""),
    ("gender", "pt_BR", "", "%s está morta.", False, ""),
    ("gender", "pt_BR", "", "%s está morto.", False, ""),
    ("gender", "pt_BR", "", "WOLF: Você está certa.", False, "you"),
    ("gender", "pt_BR", "", "%s abre a porta da escada.", True, ""),
    ("gender", "pl", "", "%s jest zmęczona.", False, ""),
    ("gender", "pl", "", "%s jest zmęczony.", False, ""),
    ("gender", "pl", "", "%s jest ranna.", False, ""),
    ("gender", "pl", "", "WOLF: Jesteś zmęczona.", False, "you"),
    ("gender", "pl", "", "WOLF: Jesteś pewny?", False, "you"),
    ("gender", "pl", "", "%s stoi przy ścianie, strona druga.", True, ""),
    ("gender", "ru", "", "%s, усталая, идёт к реле.", False, ""),
    ("gender", "ru", "", "%s, усталый, идёт к реле.", False, ""),
    ("gender", "ru", "", "%s — раненая.", False, ""),
    ("gender", "ru", "", "Инженерка %s у реле.", False, ""),
    ("gender", "ru", "", "Техничка %s у реле.", False, ""),
    ("gender", "ru", "", "%s уверена.", False, ""),
    ("gender", "ru", "", "WOLF: Ты усталая.", False, "you"),
    ("gender", "ru", "", "%s — у стены, а дверь закрыта.", True, ""),
    ("gender", "ru", "", "WOLF: Иди к большой двери. Найди рубильник.", True, "you"),
    ("gender", "de", "", "%s ist Wartungstechnikerin.", False, ""),
    ("gender", "de", "", "%s ist Wartungsingenieur.", False, ""),
    ("gender", "de", "", "WARTUNGSINGENIEURIN", False, "third"),
    ("gender", "de", "", "%s öffnet die Tür. Die Wartungstechnik wartet.", True, ""),
    ("gender", "it", "", "%s è stanca.", False, ""),
    ("gender", "it", "", "%s è stanco.", False, ""),
    ("gender", "it", "", "%s apre la porta.", True, ""),
    ("gender", "ja", "", "%sさんは女の子だ。", False, ""),
    ("gender", "ja", "", "%sくん、格子から離れて。", False, ""),
    ("gender", "ja", "", "%sさんは格子の上にいる。ちゃんと見て。", True, ""),
    ("gender", "zh_Hans", "", "%s小姐在格栅上。", False, ""),
    ("gender", "zh_Hans", "", "%s在格栅上。", True, ""),
    ("gender", "ko", "", "%s 씨는 여자다.", False, ""),
    ("gender", "ko", "", "%s 씨는 격자 위에 있다.", True, ""),
    ("name_case", "ru", "", "Страж заметил %sа на открытом месте.", False, ""),
    ("name_case", "ru", "", "Страж заметил: %s на открытом месте.", True, ""),
    ("name_case", "pl", "", "Strażnik zobaczył %sa.", False, ""),
    ("name_case", "ja", "", "%sは無事だ。", True, ""),
    ("plural", "ru", "The valve gives. %d of %d turns.", ["Клапан поддаётся. %d из %d оборота.", "Клапан поддаётся. %d из %d оборотов.", "Клапан поддаётся. %d из %d оборотов."], True, ""),
    ("plural", "ru", "The valve gives. %d of %d turns.", ["Клапан поддаётся. %d из %d оборота.", "Клапан поддаётся. %d из %d оборотов."], False, ""),
    ("plural", "ru", "The valve gives. %d of %d turns.", ["Клапан поддаётся. %d из %d оборота.", "Клапан поддаётся. %d оборотов.", "Клапан поддаётся. %d из %d оборотов."], False, ""),
    # Header rules: Godot loads fr with an unparsable rule silently as English (Gotchas).
    ("plural_header", "fr", "", "Language: fr\nPlural-Forms: nplurals=2; plural=(n > 1);\n", True, ""),
    ("plural_header", "fr", "", "Language: fr\nPlural-Forms: nplurals=2; plural=(n != 1);\n", False, ""),
    ("plural_header", "fr", "", "Language: fr\nPlural-Forms: nplurals=2; plural=n >> 1\n", False, ""),
    ("plural_header", "ru", "", "Language: ru\n", False, ""),
    # Comment lines: any "fuzzy" outside a "#," flag line makes Godot skip the line (fuzzy_notes).
    ("fuzzy_note", "de", "", ["#. TRANSLATORS: the gauge reading is fuzzy on purpose"], False, ""),
    ("fuzzy_note", "de", "", ["#, c-format", "#. TRANSLATORS: the gauge reading is vague on purpose"], True, ""),
    # Two call sites of one msgid (mark_conflicts).
    ("marks", "de", "", ["#. TRANSLATORS: i18n: engineer=name", "#. i18n: engineer=name"], True, ""),
    ("marks", "de", "", ["#. TRANSLATORS: i18n: engineer=name", "#. i18n: slot=key"], True, ""),
    ("marks", "de", "", ["#. TRANSLATORS: i18n: engineer=name", "#. i18n: engineer=you"], False, ""),
    ("marks", "de", "", ["#. TRANSLATORS: i18n: slot=choice", "#. i18n: slot=key"], False, ""),
    # The glossary gate on the repository's own i18n/glossary.json (glossary_missing, glossary_avoided):
    # required forms, avoid forms (decision D11), open terms, es-ES inheriting es-419, capitalised variants.
    ("glossary", "es", "Head right to the breaker.", "Ve a la derecha, al disyuntor.", True, ""),
    ("glossary", "es", "Head right to the breaker.", "Ve a la derecha, al interruptor.", False, ""),
    ("glossary", "es_ES", "Head right to the breaker.", "Id a la derecha, al interruptor.", False, ""),
    ("glossary", "es", "Open the door.", "Abre el interruptor de la puerta.", True, ""),
    ("glossary", "es_ES", "Get to the SAFE POINT.", "Ve al PUNTO SEGURO.", True, ""),
    ("glossary", "es_ES", "Get to the SAFE POINT.", "Ve al LUGAR SEGURO.", False, ""),
    ("glossary", "es", "CHAPTER 1  /  LOCKDOWN", "CAPÍTULO 1  /  CIERRE DE EMERGENCIA", True, ""),
    ("glossary", "es", "CHAPTER 1  /  LOCKDOWN", "CAPÍTULO 1  /  BLOQUEO", False, ""),
    ("glossary", "ru", "Get to the TANK RELEASE.", "Иди к пульту «ОТЦЕПКА БАКА».", True, ""),
    ("glossary", "ru", "Get to the TANK RELEASE.", "Иди к пульту «СБРОС БАКА».", False, ""),
    ("glossary", "ru", "Find the breaker.", "Найди автомат.", False, ""),
    ("glossary", "ru", "The sentry stops on the mark.", "Страж останавливается на отметке.", True, ""),
    ("glossary", "pt_BR", "The coolant cloud is thick.", "A nuvem de líquido de arrefecimento é densa.", True, ""),
    ("glossary", "pt_BR", "The coolant cloud is thick.", "A nuvem de refrigerante é densa.", False, ""),
    ("glossary", "de", "Get to the SAFE POINT.", "Geh zum SICHERUNGSPUNKT.", True, ""),
    ("glossary", "ja", "Get to the SAFE POINT.", "安全な場所へ。", False, ""),
]
#: Planted cases for glossary_problems: (what, a change made to a copy of the repository's glossary and
#: style guides, must it report a problem). The first is the files as they are, which must be sound.
GLOSSARY_SELFTEST = [
    ("the repository's glossary and style guides", lambda g, s: None, False),
    ("a Russian form in Latin letters", lambda g, s: g["terms"]["relay"]["ru"].update(required="rele"), True),
    ("a Cyrillic letter in a German form", lambda g, s: g["terms"]["relay"]["de"].update(required="Relaиs"), True),
    ("an open form with a required word", lambda g, s: g["terms"]["breaker"]["es-419"].update(required="disyuntor"), True),
    ("a proposed form with no required word", lambda g, s: g["terms"]["relay"]["fr"].update(required=None), True),
    ("an unknown status", lambda g, s: g["terms"]["relay"]["de"].update(status="final"), True),
    ("an avoided word that is also accepted", lambda g, s: g["terms"]["coolant"]["pt-BR"].update(variants=["Refrigerante"]), True),
    ("a term with no French form", lambda g, s: g["terms"]["relay"].pop("fr"), True),
    ("a term with no note", lambda g, s: g["terms"]["relay"].pop("note"), True),
    ("a language key languages.json does not know", lambda g, s: g["languages"].append("xx"), True),
    ("a Korean name with no particle class", lambda g, s: g["names"]["Alex"].pop("ko_particles"), True),
    ("a covered language with no style guide", lambda g, s: s.pop("ko"), True),
    ("a style guide without the engineer's section", lambda g, s: s.update(pl=s["pl"].replace("## The engineer\n", "")), True),
    ("a style guide for a language the glossary does not cover", lambda g, s: s.update(it=s["de"]), True),
    ("no shared style guide", lambda g, s: s.pop(STYLE_SHARED), True),
]
#: Planted sibling-file cases for family_gaps: (what, {lang: {msgid: (msgstr, fuzzy)}}, languages that
#: must report a gap).
FAMILY_SELFTEST = [
    ("es and es_ES both translate A and B", {"es": {"A": ("a", False), "B": ("b", False)}, "es_ES": {"A": ("a", False), "B": ("b", False)}}, []),
    ("es_ES misses B, so B would show the es text", {"es": {"A": ("a", False), "B": ("b", False)}, "es_ES": {"A": ("a", False)}}, ["es_ES"]),
    ("zh_Hant has B fuzzy, so B would show Simplified", {"zh_Hans": {"A": ("a", False), "B": ("b", False)}, "zh_Hant": {"A": ("a", False), "B": ("b", True)}}, ["zh_Hant"]),
    ("es and es_ES both miss B: English shows, no gap", {"es": {"A": ("a", False)}, "es_ES": {"A": ("a", False)}}, []),
    ("es alone misses B: English shows, no gap", {"es": {"A": ("a", False)}}, []),
]

#: Planted cases for the release gates (release_problems): (what, review state, PO entries, POT entries,
#: must it report a problem). An entry is (msgid, msgstr list, fuzzy, story-marked); the story mark is
#: written the way the generator writes it ("#. TRANSLATORS: i18n: story").
RELEASE_SELFTEST = [
    ("machine language, one fuzzy line: may ship", "machine", [("A", ["a"], True, False)], [("A", [""], False, False)], False),
    ("reviewed language, one fuzzy line: may not ship", "reviewed", [("A", ["a"], True, False)], [("A", [""], False, False)], True),
    ("reviewed language, every line translated: may ship", "reviewed", [("A", ["a"], False, False), ("B", ["b"], False, False)], [("A", [""], False, False), ("B", [""], False, False)], False),
    ("story line translated: may ship", "machine", [("S", ["s"], False, True)], [("S", [""], False, True)], False),
    ("story line left empty: may not ship", "machine", [("S", [""], False, True)], [("S", [""], False, True)], True),
    ("story line fuzzy in a machine language: may not ship", "machine", [("S", ["s"], True, True)], [("S", [""], False, True)], True),
    ("story line missing from the PO (marked in the POT only): may not ship", "machine", [("A", ["a"], False, False)], [("A", [""], False, False), ("S", [""], False, True)], True),
    ("story plural with an empty form: may not ship", "machine", [("S", ["s", ""], False, True)], [("S", ["", ""], False, True)], True),
    ("untranslated line with no story mark: may ship", "machine", [("A", [""], False, False)], [("A", [""], False, False)], False),
]


def _planted_entries(rows: list[tuple]) -> list[dict]:
    """RELEASE_SELFTEST's (msgid, msgstr list, fuzzy, story) rows as parsed PO entries (read_po's form),
    with the gettext fuzzy flag and the story mark as comment lines. Pure."""
    return [{"msgid": msgid, "msgstr": list(texts),
             "comments": (["#, fuzzy"] if fuzzy else []) + ([f"#. TRANSLATORS: i18n: {STORY_MARK}"] if story else [])}
            for msgid, texts, fuzzy, story in rows]


def selftest(out: Path) -> None:
    """Runs SELFTEST, FAMILY_SELFTEST, RELEASE_SELFTEST and GLOSSARY_SELFTEST through the gates, writes
    each case's result to ``out`` and exits 1 on a mismatch. Reads the repository's glossary and style
    guides (the glossary cases test the real terms); writes nothing else."""
    glossary = json.loads(GLOSSARY_FILE.read_text(encoding="utf-8"))
    styles = read_styles()
    results = []
    for gate, lang, english, text, expected, mark in SELFTEST:
        if gate == "glossary":
            key = LANGUAGES[lang]["glossary"]
            passed = not glossary_missing(english, text, key, glossary) and not glossary_avoided(english, text, key, glossary)
        elif gate == "placeholders":
            passed = placeholders_ok(english, text)
        elif gate == "bbcode":
            passed = bbcode_ok(english, text)
        elif gate in ("gender", "name_case"):
            roles = engineer_roles({"msgid": text, "comments": [f"#. i18n: engineer={mark}"] if mark else []})
            passed = (not gendered_words(text, lang, roles)) if gate == "gender" else name_case_ok(text, lang, roles)
        elif gate == "plural_header":
            passed = plural_header_ok(text, lang)
        elif gate == "fuzzy_note":
            passed = not fuzzy_notes({"comments": text})
        elif gate == "marks":
            passed = not mark_conflicts({"comments": text})
        else:
            passed = not plural_problems({"msgid": english, "msgid_plural": english, "msgstr": text}, plural_count(lang))
        results.append({"gate": gate, "language": lang, "english": english, "translation": text, "engineer": mark,
                        "expected_pass": expected, "passed": passed, "as_expected": passed == expected})
    for what, files, expected_gaps in FAMILY_SELFTEST:
        po = {lang: [{"msgid": msgid, "comments": ["#, fuzzy"] if fuzzy else [], "msgstr": [text]} for msgid, (text, fuzzy) in texts.items()]
              for lang, texts in files.items()}
        flagged = sorted(lang for lang, gap in family_gaps(po).items() if gap)
        results.append({"gate": "family", "case": what, "expected_gaps": expected_gaps, "gaps": flagged,
                        "as_expected": flagged == sorted(expected_gaps)})
    for what, review, po, pot, expect_problem in RELEASE_SELFTEST:
        found = release_problems(_planted_entries(po), _planted_entries(pot), review)
        results.append({"gate": "release", "case": what, "expected_problem": expect_problem, "problems": found,
                        "as_expected": bool(found) == expect_problem})
    for what, change, expect_problem in GLOSSARY_SELFTEST:
        planted_glossary, planted_styles = copy.deepcopy(glossary), dict(styles)
        change(planted_glossary, planted_styles)
        found = glossary_problems(planted_glossary, planted_styles)
        results.append({"gate": "glossary_shape", "case": what, "expected_problem": expect_problem, "problems": found,
                        "as_expected": bool(found) == expect_problem})
    wrong = [r for r in results if not r["as_expected"]]
    out.write_text(json.dumps({"cases": len(results), "as_expected": len(results) - len(wrong), "results": results},
                              ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"selftest: {len(results) - len(wrong)} of {len(results)} cases as expected")
    if wrong:
        sys.exit(1)


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


def main(argv: list[str]) -> None:
    """Runs the subcommand ``argv`` names (see the module notes); a wrong call prints the notes and exits
    1. Flags (--check, --back BACK, --release) are read only where the notes list them."""
    args, flags, back = [], set(), None
    rest = iter(argv[1:])
    for arg in rest:
        if arg == "--back":
            back = Path(next(rest, ""))
        elif arg.startswith("--"):
            flags.add(arg)
        else:
            args.append(Path(arg))
    plain = {"fonts": (fonts, 1), "fill": (fill, 3), "backprompt": (backprompt, 2), "selftest": (selftest, 1),
             "hardcoded": (hardcoded, 3), "glossary": (glossary_check, 0),
             "pickerfonts": (lambda: print(json.dumps(picker_fonts(), ensure_ascii=False, indent=1)), 0)}
    command = argv[0] if argv else ""
    if command == "potfiles" and len(args) == 1 and flags <= {"--check"} and back is None:
        potfiles(args[0], "--check" in flags)
    elif command == "check" and len(args) == 3 and flags <= {"--release"}:
        check(*args, back=back, release="--release" in flags)
    elif command in plain and len(args) == plain[command][1] and not flags and back is None:
        plain[command][0](*args)
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
