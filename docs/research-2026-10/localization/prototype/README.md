# The localization prototype

The design in [../DESIGN.md](../DESIGN.md), tried in WOLF//OVERRIDE, in a scratch copy only. Two steps
built it on October 16, 2026:
- the **prototype step** did English, Latin-American Spanish, German and Japanese;
- the **design step** added Russian, the Cyrillic proof among the top 10.

Both steps worked on a scratch export of `main` at 1cf8d73 with Godot 4.7.2.stable.official.ed1daf0bf.
Nothing went onto a game branch and no English line changed. The whole change is one patch,
[`evidence/game.patch`](evidence/game.patch), font included. It applies cleanly to a fresh
`git archive` of `main` at 1cf8d73 (checked with `git apply --check` after the Russian change, and again after the fix step added Adobe's
copyright line to the font's licence text).

The translations are proof samples only. No native speaker has reviewed them, and the story and WOLF
wording stay Nathanial's.

## What it proves

**The top 10 use three script families,** and the prototype proves one language from each:
- Latin: es, de;
- CJK: ja;
- Cyrillic: ru.

Chinese and Korean work the same way as Japanese, each with its own Noto subset. French, Portuguese
and Polish work the same way as es and de.

| Claim | Evidence |
|---|---|
| Godot's own POT generator runs headless and extracts the game's text, constants included | `evidence/messages.pot`: 149 msgids, against 75 on `main`; `evidence/logs/pot.txt` |
| Settings has a LANGUAGE row. The game starts in the OS language and falls back to English | `tests/i18n_test.gd` (resolver and picker checks) |
| The PO files load at runtime with no import step | the same suite |
| Text is translated where it is drawn, and redraws when the language changes: the title, a narration box, the name card, the location card, a hint, a knockdown card with the engineer's name, and the RETRY prompt | the same suite, in es, de, ja and ru |
| Every translation passes the pipeline's gates, and broken copies fail them | `evidence/po_check.json`; `evidence/po_check_negative_control.json` (es); `evidence/po_check_negative_control_ru.json` (ru); `evidence/po_check_negative_control_gender.json` (ru and es, the engineer gendered); `evidence/po_check_negative_control_fix2.json` ("you" lines, pronouns, the name case and a sibling `es_ES` file); `evidence/gate_selftest.json` (54 planted cases) |
| A subset Noto Sans JP fallback draws all the Japanese | the glyph checks; 0 tofu in the render audits |
| Russian needs no fallback font: Roboto and Montserrat draw every Cyrillic character, and the line height stays 21 px at 17 px | the suite's "Russian chains no fallback" checks |
| The Russian knockdown card keeps the name in the nominative and shows no gender | the suite; the gender and name-case gates and Codex's `engineer_gendered: false` in `evidence/po_check.json` |
| Godot's pseudolocalization reaches the whole game | the suite; the pseudo stills |
| The game's other 24 suites still pass | `evidence/logs/check-game-results.txt` (prototype step: 25 of 25); `evidence/logs/check-game-results-ru.txt` (design step: 24 of 24 with Russian; see "Headless checks") |

## How it is built

Details and reasons are in DESIGN.md. In short:

**`scripts/i18n.gd` (`class_name I18n`)** holds all the locale code:
- `LANGUAGES`: `en`, `es` ("Español (Latinoamérica)"), `de`, `ja`, and `ru` ("Русский");
- the resolver;
- the saved setting;
- `apply()`;
- the Japanese fallback, which goes on only while Japanese is on;
- the `KEY.tr()` extraction marker;
- `format()`, `shown()` and `lines()` for text kept between frames;
- the `missing_glyphs()` and `overflows()` checks that the suite and the render driver share.

**English stays the internal text.**
- Scene buttons and Settings captions use Godot's auto-translate.
- Hints and prompts call `tr()` where they are worked out.
- `status_line` and the top card are translated where they are drawn.

**Code changes outside `I18n`:**
- 41 `I18n.KEY.tr()` marks and 53 `tr()` calls in all (the prototype step's count), nearly all in
  `main.gd`.
- `game_settings.gd`: the LANGUAGE row.
- `junction_room.gd`: two marks, on the vent and cloud knockdown reasons.
- `dialogue_boxes.gd`: `。！？` and `；，、` now end sentences and clauses with no space after them.

**`i18n/{es,de,ja,ru}.po`** are written by `tools/i18n_tool.py fill` from the POT and
`translations/claude.json`.

## Translations

| Step | es-419, de, ja (prototype step) | ru (design step) |
|---|---|---|
| Source | the 34 msgids the stills show, each with a context note (`translations/claude.json`) | the same 34 |
| Translator | Claude, with `../pipeline/style_packet.md` and `../pipeline/glossary.json` | Claude, with the same packet and glossary, after adding their Russian rules |
| Independent back-translation, not shown the English | Codex session `01a143f0-8b81-7703-972f-13e21953fd61` (102 texts) | Codex session `01a14426-2248-7773-8edf-2c4cb6fa3ef8` (34 texts) |
| `msgfmt --check-format --check-header` | rc 0 for each | rc 0 |
| Gate failures | 0 of 102 | 0 of 34 |
| Drift flags | 2, both es ("interruptor" reads as "switch") | 0 |
| Mean chrF | es 77.1, de 70.5, ja 77.4 | 64.0 |

**Re-run by the fix-2 step** with its gates and a new back-translation of all 136 lines (Codex session
`01a146cf-4beb-7f42-8d61-726071ffb149`, which also answers `engineer_gendered` and knows who speaks and
how the engineer appears in each line): 0 gate failures in any language; `engineer_gendered` false on
all 136; drift flags es 2 (the same two), ja 1 and ru 1, both literal round trips of correct lines; mean
chrF es 77.4, de 71.3, ja 78.3, ru 62.4. That run's answers replaced the earlier ones in
`translations/codex_back.json`.

**Fixed after the overflow gate:** de SETTINGS changed from EINSTELLUNGEN to OPTIONEN. Codex session
`01a14409-6eb1-7db2-8ef1-f6f3714d953b` back-translated the new word.

**How the Russian follows the style rules:**
- **The name card names a department, not a gendered noun:** СЛУЖБА ТЕХОБСЛУЖИВАНИЯ, "maintenance
  service". The other languages do the same: es INGENIERÍA DE MANTENIMIENTO, de WARTUNGSTECHNIK,
  ja 保守技術者.
- **The knockdown card keeps the name in the nominative, with no past tense about the engineer:**
  - "Сорвало предохранительный клапан, а %s — прямо на решётке." (The relief valve blew, and %s is
    right on the grate.)
  - "Страж заметил: %s на открытом месте." (The sentry noticed: %s is out in the open.)
  - The English puts the name where Russian would need a case ending ("under Rowan", "saw Rowan").
  - Codex's notes found no gender marker for the engineer. They noted the masculine forms for WOLF
    (сам) and the sentry (заметил), which are both correct.
- **Station plates are quoted in their own nominative form:** «БЕЗОПАСНАЯ ТОЧКА», «СБРОС БАКА».
- **WOLF stays undeclined** ("с WOLF"), **and the key token stays a Latin "E:".**

**What the back-translations caught.** A person decides; the samples stay as they are.

| Language | Line | What Codex reported |
|---|---|---|
| es | "Head right to the breaker." and "Or head right to the breaker." | "interruptor" reads as "switch" (the two drift flags) |
| es | BLOQUEO for LOCKDOWN | reads as "blockage" |
| de | "HALTEN E:" | unnatural word order, forced by the `E:` token |
| de | VERSORGUNGSKNOTEN | reads as "supply node" |
| ja | 所長 | reads as "head of the facility" |
| ru | «СБРОС БАКА» for TANK RELEASE | reads as "TANK RESET" (сброс is both drop and reset) |
| ru | БЛОКИРОВКА for LOCKDOWN | reads as "lockout" |
| ru | рубильник for breaker | reads as "knife switch". Chosen because автомат, the everyday word, also means an assault rifle. |

## Fonts

| | |
|---|---|
| Japanese fallback | Noto Sans JP Regular from notofonts/noto-cjk `Sans/SubsetOTF/JP` (last changed in commit 165c01b46ea5, 2021-04-30; Sans 2.004 released 2022-01-27). 4,533,028 B, SHA-256 `dff723ba…5073`. SIL OFL 1.1, bundled as `NotoSansJP-OFL.txt`. |
| Prototype subset | 139,224 B, 673 code points: ASCII, CJK punctuation, kana, full-width forms, "日本語" and every character of the ja texts. Made with hb-subset 14.6.0 (`tools/i18n_tool.py subset`). |
| Full-game size estimate | 878,736 B for kana plus all 2,965 JIS level-1 kanji (measured) |
| The trap | `Font.get_height()` takes the tallest font in the chain. With Noto behind Roboto, Roboto's line height grew from 15 to 18 px at 12 px, from 21 to 25 at 17 and from 28 to 34 at 23. That broke 2 suites, so the fallback goes on only in Japanese. |
| Glyph check | 296 distinct characters across the four languages, against Roboto-Regular, Montserrat-Semibold and Montserrat-Bold with the Japanese fallback on: 0 missing. Russian was also checked with no fallback at all: 0 missing. Because the fallback was on for every language, a CJK character in a Latin file would have passed; the build checks each language with its own chain (DESIGN.md). |
| Naming | The subset may keep the name "Noto Sans JP". The only Reserved Font Name is "Source": Google Fonts' `ofl/notosansjp/OFL.txt` reads "Copyright 2014-2021 Adobe (http://www.adobe.com/), with Reserved Font Name 'Source'", and the font's name table records no reserved name (ID 0: "© 2014-2021 Adobe", read with fontTools 4.60.1 by the fix step). The upstream `Sans/LICENSE` lacks that copyright line, which OFL condition 2 asks for with every copy, so the fix step added it to the top of the patch's `NotoSansJP-OFL.txt` and updated the manifest entry. That changed two text files only, so no test was re-run. |

## Overflows: the gate and the stills

`I18n.overflows()` compares a control against the width its anchors and offsets give it. The suite
pins every known overflow by name in `KNOWN_OVERFLOWS`, so any new overflow fails it. Measured:

| Control | Designed width | es | de | ja | ru |
|---|---|---|---|---|---|
| Title NEW GAME button | 186 px | **213** (NUEVA PARTIDA; NUEVO JUEGO would need 193) | fits | fits | fits |
| Title CONTINUE button | 186 px | fits | fits | fits | **199** (ПРОДОЛЖИТЬ) |
| Title Brand line ("MRDEMONWOLF, INC. PRESENTS") | 280 px | fits | **298** | fits | **321** |
| Title CONTINUE note (shown only with no save; one row) | 388 px | **485** | **510** | **480** | **671** |
| PAUSE button | 88 px | fits | fits | fits | 91 (render audit only) |
| Touch USE button showing CONTINUE | 155 px | 173 | 185 | 188 | 211 (render audit only) |

**Findings:**
- **The CONTINUE note overflows in every language.** The prototype step's render audit never saw it
  in es, de or ja: its English pass had saved a checkpoint by then, which hides the note. The design
  step's fresh Russian run showed it, and the suite now checks the note directly.
- **The touch USE button has two problems.** It also has the wrong meaning: Godot's auto-translate gives
  it the title's "continue a save" sense. That needs a `msgctxt`.
- **Pseudolocalization (+30%) adds:** PAUSE 88 → 100, NEW GAME 186 → 197, the credit line 424 → 529,
  and the game title logo 430 → 512. The logo should not be translated at all.
- **Neighbours are not compared.** Under pseudo, the junction's OVERLOAD BREAKER and RELIEF VENT plates
  touch. The audit does not compare neighbours.
- **What this check cannot see.** `I18n.overflows()` skips Controls inside Containers (all of Settings,
  the end card), counts trimmed or clipped text as fitting (Settings trims with "…"), checks width only,
  and compares no neighbours. So "fits" in the table above means "fits by this check". The build's
  version and the reuse of `text_boxes_test`'s overlap checks are in [../DESIGN.md](../DESIGN.md)
  ("The prototype's overflow check has four blind spots").

These wait for Nathanial's layout decision ([../DECISIONS.md](../DECISIONS.md), D10).

## Stills

The stills come from `tools/render/render.sh`, in the container only, under the heavy slot, with
`--fixed-fps 60` and the driver `capture/i18n_capture.gd`:
- **The prototype step:** runs i18n-proto-7 (`--screen 1280x720`) and i18n-proto-8
  (`--screen 2400x1080`, touch layout) made 45 frames in en, es, de, ja and pseudo.
- **The design step:** runs i18n-design-ru-1 and -2 made the same frames in ru (9), with the driver's
  new `--languages=ru`.
- **What was filed:** the 54 frames stayed in the session scratch. The nine below were filed at 960 px
  wide (256 colours). At 2400x1080 the saved image is 1920x1080 (measured); the likely reason, the
  game's default 16:9 stretch, is inferred. So the "touch layout" stills show the touch controls at
  16:9, not at a 20:9 phone's shape. The measured pixel widths still hold under the canvas stretch.
- **The audits:** `stills/audit-1280x720.json` and `stills/audit-2400x1080.json` list every frame's
  visible-text count, overflow, tofu and untranslated text, for all 54 frames.

| File | Shows | Look for |
|---|---|---|
| `stills/1280x720-es-title.png` | the title in Spanish | NUEVA PARTIDA running into CONTINUAR |
| `stills/1280x720-ru-title.png` | the title in Russian | the Brand line under the logo, ПРОДОЛЖИТЬ wider than its slot, the CONTINUE note running off screen |
| `stills/1280x720-de-hint.png` | the corridor's first hint and location card in German | the key named in the hint; station plates still English |
| `stills/1280x720-ja-narration.png` | the opening's second narration box in Japanese | the Noto fallback drawing kana and kanji; the 03:17 card |
| `stills/1280x720-ja-knockdown.png` | the vent knockdown card in Japanese | a lone short last row ("た。") |
| `stills/1280x720-ja-settings.png` | Settings, DISPLAY tab, in Japanese | the LANGUAGE row (言語, 日本語); most Settings captions still English, since they are not marked yet |
| `stills/1280x720-ru-knockdown.png` | the vent knockdown card in Russian | the name in the nominative; the one-letter word "а" left at the end of a row |
| `stills/2400x1080-ru-narration.png` | the opening on the touch layout in Russian | the touch USE button reading ПРОДОЛЖИТЬ (wrong sense, too wide); "в" left at the end of a row; the touch hint still English |
| `stills/1280x720-pseudo-knockdown.png` | English with pseudolocalization | every line bracketed and padded; the name kept |

What the stills show (looked at, not played):
- Japanese and Russian draw cleanly, with 0 tofu.
- **Russian leaves one-letter words at the end of a row:** "а" and "в". Russian typesetting binds them
  to the next word, and Polish does the same with its one-letter words. The style rule and a gate are
  in [../PIPELINE.md](../PIPELINE.md) and [../PLAN.md](../PLAN.md).
- **Still English:**
  - the key names ("Escape");
  - the station plates (decision D3);
  - the touch prompts (TAP CONTINUE, USE, TAP RETRY);
  - most Settings captions.

  None of them is marked yet.

## Headless checks

**The language suite.** `tests/i18n_test.gd` reuses `tests/support/game_suite.gd` and passes with
**120 checks** (`evidence/logs/i18n_test-ru.txt`). It covers:
- the resolver, including ru_RU and ru_KZ to ru, and uk_UA to English;
- the catalogs;
- the title texts in five languages, with known overflows pinned;
- the picker;
- the narration box redrawn in es, ja, de and ru;
- the name card and location card;
- the hint with the bound key;
- the knockdown card with the name in es, ja and ru, and its boxes fitting two rows;
- the Japanese fallback on only in Japanese;
- Russian with no fallback;
- glyph coverage;
- pseudolocalization.

**Every suite:**
- **The prototype step:** `scripts/check-game.sh` with `CHECK_JOBS=2` passed 25 of 25 in 374 s.
- **The design step:**
  - The same full run with Russian passed 24 of 24 of the game's other suites in 375 s.
  - Its `i18n_test` failed on one check, the Russian CONTINUE overflow.
  - check-game's changed-files gate flagged the font's `.import` file, which the prototype's patch
    lacked.
  - The overflow is now pinned, with the title overflows the suite then measured. The `.import` file is
    in the patch, and `i18n_test` passes alone.
  - The full run was not repeated, to keep the Mac calm: the other suites' code did not change after
    it.

**Copies.** `scripts/check-copies.py --base origin/main` found no copied code on the branch that files
this record.

## Files

- **`evidence/game.patch`:** the whole game change, font and its `.import` included. It adds:
  - `scripts/i18n.gd`, `tests/i18n_test.gd` and `i18n/{es,de,ja,ru}.po`;
  - the Noto subset, its OFL and a manifest provenance entry;
  - edits to `main.gd`, `game_settings.gd`, `junction_room.gd`, `dialogue_boxes.gd` and
    `project.godot`.
- **`evidence/messages.pot`:** the generated POT.
- **`evidence/po_check*.json`:** the gate report and the four negative controls, all re-run by the fix-2
  step with its tool (PIPELINE.md lists each planted error). The earlier versions are these paths at
  commit 9a59e0e.
- **`evidence/gate_selftest.json`:** `i18n_tool.py selftest`, 54 fixed planted cases, mostly for the gates
  no prototype msgid exercises yet.
- **`evidence/hardcoded.json`:** the shown strings still missing from the POT, by file and line.
- **`evidence/codex/`:** the Codex prompts and their JSON event streams (the prototype step's two, the
  design step's `*_ru.*`, the fix-2 step's `*_fix2.*`).
- **`evidence/logs/`:** the POT run, the suite logs and results, and the four render logs that made the
  filed stills.
  - They are filed as `.txt`, because the repository ignores `*.log` under `docs/`. The research-godot
    step's measurement logs in `../godot/evidence/` are `.txt` for the same reason.
  - The scratch paths are shortened to `<scratch>`.
- **`translations/claude.json`:** the sample translations, with a context note and the `#. i18n:` marks
  per line, and the revision notes.
- **`translations/codex_back.json`:** the fix-2 step's 136 back-translations, keyed by language and
  `entry_key`, with the session id. The earlier position-keyed answers are this path at commit 9a59e0e.
- **`tools/i18n_tool.py`:**
  - Its subcommands are `potfiles`, `subset`, `fill`, `backprompt`, `check`, `selftest` and `hardcoded`.
  - The fix step added the engineer-gender gate (with the back-translation's `engineer_gendered` field),
    the plural-form gate over every `msgstr[n]`, the `keep-breaks` line-break rule, named placeholders
    (in `trial.py`) and `selftest`. The as-run version is at commit 65a6db7.
  - The fix-2 step moved every per-language fact into `tools/languages.json`, the one table the tool
    reads; made the gender gate read each line's `#. i18n:` marks ("you" lines, pronouns, the vocative);
    added the name-case, BBCode and sibling-file gates and printf-width placeholders (in `trial.py`);
    keyed the back-translations by message; made `potfiles` walk every folder; and made `check` exit 1
    on any failure. The version before it is at commit 9a59e0e.
  - It imports `../pipeline/tools/trial.py` for the pipeline step's measures; nothing is copied.
  - The design step added the Russian plural rule, plural-form counts from it, and the script guard
    ported from ConPaws.
- **`tools/extract_pot.sh` and `tools/pot_addon/`:** the extraction. The research-godot step proved the
  route, and its plugin moved here.
- **`tools/heavy.sh`:** runs one command under the shared heavy-run slot, read from `HEAVY_SLOTS`.
- **`capture/i18n_capture.gd`:** the render driver, with `--languages=` added by the design step. It
  re-implements part of `scripts/parity/capture.gd` (on `main`), so the build does not move it: L2 adds
  `--language` and the language audit to that driver instead (PLAN.md), and this file stays here as the
  record of how the stills were made.
- **`stills/`:** the nine stills above and the two audits.

**To reproduce**, start from a scratch export of `main` at 1cf8d73 with the patch applied. ROOT holds
`apps/game`; HEAVY_SLOTS is the session's slot script.

```sh
bash tools/heavy.sh bash tools/extract_pot.sh ROOT evidence/messages.pot LOGS
python3 -I -B tools/i18n_tool.py fill evidence/messages.pot translations/claude.json ROOT/apps/game/i18n
python3 -I -B tools/i18n_tool.py backprompt PODIR PROMPT   # then: codex exec --sandbox read-only --skip-git-repo-check --json - < PROMPT
python3 -I -B tools/i18n_tool.py check evidence/messages.pot ROOT/apps/game/i18n translations/codex_back.json OUT.json
python3 -I -B tools/i18n_tool.py selftest OUT.json
python3 -I -B tools/i18n_tool.py hardcoded evidence/messages.pot ../strings-inventory.json OUT.json
(cd ROOT && bash scripts/check-game.sh --suite i18n_test LOGS WORK)
(cd ROOT && bash DOCS/prototype/tools/heavy.sh bash tools/render/render.sh --screen 1280x720 --name i18n-NAME \
  --driver DOCS/prototype/capture apps/game OUT -- --fixed-fps 60 \
  --script res://review_capture/i18n_capture.gd -- --size=1280x720 [--languages=ru])
```

## Runs, sessions and sources

**Heavy runs, each under the shared slot and released after:**
- **Prototype step:**
  - 2 import and POT runs;
  - 2 full check-game runs;
  - 8 renders, i18n-proto-1 to -8. Runs 1 to 6 found bugs and were superseded.
- **Design step:**
  - 1 full check-game run;
  - 1 slot hold for the two renders i18n-design-ru-1 and -2.
  - A first launch of the check stopped at once on a quoting bug in `heavy.sh`, before it took the
    slot. The bug is fixed, and noted in the script.

**No windows were opened.** Godot ran headless with isolated HOMEs, or in the render container.

**Codex sessions,** all through the ChatGPT subscription, all archived:
- `01a143f0-8b81-7703-972f-13e21953fd61`
- `01a14409-6eb1-7db2-8ef1-f6f3714d953b`
- `01a14426-2248-7773-8edf-2c4cb6fa3ef8`
- `01a146cf-4beb-7f42-8d61-726071ffb149` (fix-2 step)

**Sources:**
- Godot 4.7.2-stable source, as cited in DESIGN.md.
- https://github.com/notofonts/noto-cjk (`Sans/SubsetOTF/JP/NotoSansJP-Regular.otf`, `Sans/LICENSE`;
  fetched October 16, 2026).
- The pipeline step's style packet, glossary and measures (chrF: Popović 2015).
- Everything else is our own measurement: the logs and JSON under `evidence/` and `stills/`.

**Deleted after each step**, by literal path:
- **The prototype step:**
  - its 681 MB scratch export with its `.godot` import and throwaway git;
  - its work folder: logs, homes, the Codex working folder and the broken-PO copy (kept items were
    copied to `evidence/` first);
  - the 4.5 MB Noto download;
  - its `__pycache__` folders;
  - the render caches `~/Library/Caches/wolf-override-render/i18n-proto-1` to `-8`.
- **The design step:** listed in [../README.md](../README.md).
