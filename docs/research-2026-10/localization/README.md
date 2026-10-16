# Localization research, October 15-16, 2026

How WOLF//OVERRIDE should support more languages: which ones, how in Godot 4.7.2, how the
translations get made and checked, and in what order to build it. This is research, a prototype in a
scratch copy, and a plan for Nathanial's approval. **No game file and no English line changed.** The
build starts only after he answers [DECISIONS.md](DECISIONS.md).

**What Nathanial asked:**
- October 15, 2026: "Next big thing we should do is like we did on mrdemonwolf/conpaws: let's support
  multi langs on our game. Let's do of course USA and EU and Mexican, maybe a few. Make a list of what
  langs we should support, and we can do the translations on the device using AI, whatever works, and
  use whatever is needed to get this working on Godot."
- October 16: "support the top 10". This job received it from the main Claude Code session, which
  relayed his message; his exact words are in that session, not in this repository. If he meant the
  world's 10 most-spoken languages exactly, that is an option in D1.

**The answer in short:**
- **Ten languages, shipped as 12 language files:** English (US), Chinese (Simplified and Traditional),
  Russian, Spanish (Latin America and Spain), Portuguese (Brazil), German, Japanese, French, Korean and
  Polish.
  - They cover about 94% of Steam users and all three of his regions.
  - Five of them are also in the world's top 10 by speakers. The other five swaps are explained with
    numbers.
- **The translations:** AI translates at build time, a second AI checks each line independently,
  automated checks and people review the result, and the game ships fixed files. Nothing is translated
  on the player's device while they play: Godot has no way to call the phone's or the Mac's translator,
  that output could not be tested or checked for fit before players see it, and it needs language
  downloads and prompts ([PIPELINE.md](PIPELINE.md)).
- **What it costs:** no new money now. The AI work runs on the Claude and ChatGPT subscriptions he
  already has (token use in PIPELINE.md), Weblate's review site is free for public projects, and the
  Noto fonts are free. Before a paid release: one paid native proofreader per language for the story
  lines (about 1,460 English words each), at a price not yet researched.
- **When players get it:** the first language is Spanish (PR L9 in [PLAN.md](PLAN.md)). That comes after
  about 17 to 19 agent days of groundwork and wiring, plus 1.5 days for Spanish itself. The groundwork
  (6 days) can start now; the wiring waits for `codex/opening-dock` to merge. No calendar date is set:
  it depends on that merge and on his answers in [DECISIONS.md](DECISIONS.md).
- **Who checks it:** the automated checks and an independent AI back-translation on every line; then
  native-speaker volunteers on Weblate, and one paid proofreader per language before a paid release.
  Who recruits and runs the reviewers is not planned yet. Every final word is his.
- **What players see:** the game starts in their computer's or phone's language if it is offered, and
  in English if not. Settings gets a LANGUAGE choice that names each language in itself (Deutsch, 日本語)
  with a "machine translation" tag until native review. Any line not translated yet shows in English.
  Stills: [the Spanish title](prototype/stills/1280x720-es-title.png) and
  [a Japanese story box](prototype/stills/1280x720-ja-narration.png).
- **In Godot:** English stays the internal text and is translated where it is drawn. There is one
  shared language module, one PO catalog (language file) per language, Godot's own extraction tool, and
  bundled fonts for Chinese, Japanese and Korean that go on only for their language.
- **The prototype proves one language from each script family in the 10:** Latin (es, de), the
  Chinese-Japanese-Korean family (ja) and Cyrillic (ru).

## Read in this order

| File | What it is |
|---|---|
| [LANGUAGES.md](LANGUAGES.md) | The recommended list: the 10 beside the world's top 10, every swap with its numbers, Nathanial's three regions, the picker names, the OS-locale mapping, and the tiers after the 10 |
| [DECISIONS.md](DECISIONS.md) | The 11 questions only Nathanial can answer, each with a recommended default |
| [DESIGN.md](DESIGN.md) | The Godot architecture: one locale module, one catalog per language, one extractor, one test suite; the Settings option; fonts; dialogue boxes and TEXT SIZE; the lighter-game plan's text steps; the tests that assert English; exports |
| [PIPELINE.md](PIPELINE.md) | How translations are made, checked, reviewed, labelled and updated; the style rules for the they/them engineer, WOLF and inserted names |
| [STRINGS.md](STRINGS.md) | What there is to translate (650 shown strings, 16,362 words; 2,860 without the changelog), with [strings-inventory.json](strings-inventory.json) beside it |
| [PLAN.md](PLAN.md) | The build as small PRs in order, each with its gates and an effort estimate (about 27.5 agent days, 29.5 if L7 also builds the lighter plan's S05 and S08); what can start before `codex/opening-dock` merges |
| [prototype/README.md](prototype/README.md) | The prototype: what it proves, the measured overflows, the nine key stills and how to reproduce it |

## Tool map: one current copy of each tool

| Folder | Made by | Holds |
|---|---|---|
| `markets/tools/` | research-markets step | `steamlang.py`: parses the Steam survey's language table. `steamapps.py`: peer games' Steam language lists. `locale_probe.gd`: Godot locale codes and font glyph samples. |
| `markets/data/` | the same; the 14-month table by the fix step | The Steam language table (14 months) and the page behind each month, the 16 peer games' language lists and counts |
| `godot/probe/` | research-godot step | The headless probes: runtime, static and const `tr()`, fonts and chains, dialogue boxes, ICU data, start-up locale; their PO fixtures; the POT run's sample script (`pot_probe/i18n_probe/`). The POT plugin itself moved to `prototype/tools/pot_addon/`. |
| `godot/tools/export_pack.sh` | the same | The import and export-pack run (as-run name `bin/heavy_run.sh`; its slot and POT parts are now `prototype/tools/heavy.sh` and `extract_pot.sh`) |
| `godot/evidence/` | the same | The probes' measured output, `game.pot` from `main`, and `measurements.txt` |
| `strings/tools/` | research-strings step | `extract_literals.py`, `candidates.py`, `classify.py` and `test_asserts.py`; their outputs `summary.json` and `test_asserts.json`; the inventory is `../strings-inventory.json` |
| `pipeline/` | research-pipeline step | `tools/trial.py` (the trial's prompt, measures and scores); `probe/apple_translate_probe.swift` (query-only); the 12 trial lines; the style packet and glossary (the design step added Russian); `out/` with every translator's output, the scores, the judgments and the gettext rehearsal |
| `prototype/` | prototype step; design step for Russian | `tools/i18n_tool.py` (imports `../pipeline/tools/trial.py`), `extract_pot.sh` with `pot_addon/`, `heavy.sh`; `capture/i18n_capture.gd`; the translations; `evidence/` (the game patch, POT, gate reports, Codex records, run outputs); `stills/` |

**Filing rules applied:**
- Scratch paths are shortened to `<scratch>`.
- Measurement and run logs are filed as `.txt`, because the repository ignores `*.log` under `docs/`.
- No downloaded third-party file was filed. The saved Steam survey pages, the Wayback captures, the peer
  games' raw API replies and the AppMagic PDF are cited by URL instead, as `.gitignore` asks for
  `docs/**/dl/`.
- The only third-party file in this folder is the Noto Sans JP subset inside `prototype/evidence/game.patch`.
  It is under SIL OFL 1.1, and its licence text travels with it in the patch.
- The intermediate `literals.json` (2.8 MB) and `candidates.json` were left out. `strings/tools/`
  rebuilds them from `main` at 1cf8d73.

## How it was made

Six steps ran on October 15 and 16, 2026, as one Claude Code workflow for Nathanial:
1. **research-markets:** the language list from Steam, mobile, speaker and English-proficiency data.
2. **research-godot:** Godot 4.7.2's localization features, read in the 4.7.2-stable source and the
   4.7 docs and measured headless.
3. **research-strings:** the inventory of player text.
4. **research-pipeline:** a trial of Claude, Codex and Apple's on-device Translation on 12 real lines,
   and a study of ConPaws' localization.
5. **prototype:** the design built in a scratch copy, in es, de and ja.
6. **design:** these documents; Russian added to the prototype; the records filed here.
7. **fix** (after three reviews): the Steam table recomputed over all 14 survey months; the gender,
   named-placeholder and plural gates built and proved with planted errors; the overflow gate, the
   lighter-game steps and the opening-dock line breaks planned; the Noto naming question settled; the
   test claims corrected; and the reader's summaries added.

**Heavy runs** (Godot imports, full test runs and renders) took one shared slot, so Nathanial's Mac
stayed calm:
- Godot ran only headless, with isolated HOMEs.
- Every still was rendered in the container by `tools/render/render.sh`, in runs named `i18n-...`.
- No game or Godot window was opened.

**Codex sessions**, all through the ChatGPT subscription and all archived:

| Session | Step | What it did |
|---|---|---|
| `01a143d1-a4b4-7a23-be45-2e550a2fc217` | pipeline | the trial |
| `01a143f0-8b81-7703-972f-13e21953fd61` | prototype | 102 back-translations |
| `01a14409-6eb1-7db2-8ef1-f6f3714d953b` | prototype | 2 shortened buttons |
| `01a14426-2248-7773-8edf-2c4cb6fa3ef8` | design | 34 Russian back-translations |

No paid service, API key or new account was used.

## Credits

- **WOLF//OVERRIDE, its story, characters and wording, and every decision here:** Nathanial Henniges.
  The translations in this folder are proof samples. His English stays the source, and he approves
  every final word.
- **Research, measurements, tools, sample translations and these notes:** Claude (Claude Code,
  Anthropic), working for Nathanial.
- **Independent back-translations and the trial's second translations:** Codex (OpenAI, codex-cli
  0.162.1).
- **Tools:**
  - Godot 4.7.2 (godotengine.org);
  - GNU gettext 1.0 (`msgfmt`, `msgmerge`);
  - HarfBuzz `hb-subset` 14.6.0;
  - fontTools 4.60.1;
  - ImageMagick (the still thumbnails);
  - Apple's Translation framework (a query-only probe on macOS 27.0.1);
  - Docker with Colima, for the render container.
- **The font in the prototype:** Noto Sans JP (Noto CJK, notofonts/noto-cjk, Sans 2.004), SIL OFL 1.1.
- **ConPaws**, Nathanial's own app, read only: its 23-locale list, picker names and locale tests are
  the model for the one-list and parity-test rules here.
- **Outside sources:**
  - Steam's Hardware & Software Survey and its store API;
  - the Wayback Machine;
  - Ethnologue (via Wikipedia);
  - EF EPI;
  - Sensor Tower, AppMagic, Newzoo and game e.V. (via their published summaries);
  - W3Techs and Internet World Stats;
  - Apple, Google Play and Steamworks documentation;
  - the Godot 4.7 docs and source;
  - Netflix's Timed Text Style Guides;
  - W3C;
  - Weblate and Crowdin;
  - legal and market reporting on Quebec, China and Russia.

  Each is cited with its URL and date where it is used, mostly in LANGUAGES.md and PIPELINE.md.
  They informed the recommendations. None of them is a contributor to or endorser of the game.

## Deleted by the design step

Each item was deleted by its literal path:
- `<scratch>/i18n/design/game`: the 681 MB scratch export of `main` with the prototype patch, its
  `.godot` import and its throwaway git.
- `<scratch>/i18n/design/work`: the Russian Codex working folder and prompt, the check and suite logs,
  the full-size Russian stills and the broken-PO copy. Kept items were copied here first.
- `<scratch>/i18n/design/applycheck`: the copy used for `git apply --check`.
- `~/Library/Caches/wolf-override-render/i18n-design-ru-1` and `i18n-design-ru-2`: the render caches.
- `<scratch>/i18n/repo`: the clone this branch was committed from, after the last push.

The research steps' own scratch folders (`<scratch>/i18n/{research-markets,godot,strings,pipeline,proto}`)
were left for the workflow's own clean-up. Everything cited from them is filed here.

## Deleted by the fix step

The machine restart had already emptied `<scratch>`. The fix step re-cloned this branch to
`<scratch>/i18n/repo`, worked in `<scratch>/i18n/fix-1`, ran no Godot import, render or full check
(so it took no heavy slot), started no Codex session, and deleted by literal path:
- `<scratch>/i18n/fix-1`: the Steam and Wayback pages, a scratch copy of `main` with the prototype
  patch applied (no `.godot` import), the planted-error PO copies, a fontTools venv and the gate
  outputs before they were copied here;
- `<scratch>/i18n/repo`: the clone, after the last push.
