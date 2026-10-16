# Plan: the build, as small PRs

The order in which the game gets its 10 languages, once Nathanial approves the list and the defaults in
[DECISIONS.md](DECISIONS.md). Each PR is small, playable on its own and named for what it changes. The
design is [DESIGN.md](DESIGN.md) and the translation process is [PIPELINE.md](PIPELINE.md).

## When it starts

**Where this research lands.** On October 16, 2026 Nathanial decided that notes live in Notion, written
through Codex. The repository keeps only rules, decisions, the asset register, credits and
`docs/NOTES.md`, an index of the Notion pages. The branch `codex/notes-to-notion` (1a73189, in flight)
moves the existing notes there and deletes `docs/research-2026-10/`. So:
- **The write-up goes to Notion:** README, LANGUAGES, DECISIONS, PLAN, PIPELINE and DESIGN, under the
  Game Hub's "Notes & Research" page. The first L PR adds its row to `docs/NOTES.md` (or the notes job
  does, if it lands later).
- **This branch is not merged.** `codex/localization-research` stays on GitHub with its tools, data,
  evidence and prototype, as the starting point for the game-wiring job. The Notion pages link those
  files as GitHub permalinks at the branch head. L1 and L2 move the parts that live on into the game and
  `scripts/i18n/`; everything else is cited by path and commit on this branch.
- **No conflict with the notes move:** this branch no longer edits `docs/research-2026-10/README.md`,
  and its own folder is new.

**What has landed.** Four branches this research waited for have merged: lighter-1, p0-text,
corridor-additions and doors (PRs #75, #76, #78 and #79). The lighter-game plan is the ordered refactor
of `main.gd`; it is in git at `1cf8d73:docs/research-2026-10/lighter-game/PLAN.md` and in Notion as
"Lighter game". Of its steps, S00 (the `scripts/parity` harness and `BASELINE.md`, which this plan's
parity gates use), S03, S22 and S23 (the door art swaps, no text) have landed.

**The opening dock.** `codex/opening-dock` (9b6a2e3) is now a backup branch, and the dock is being redone
as a scratch art job. Phase 1 therefore waits for **the opening-dock work to land, whichever branch
carries it**, not for that branch to merge. What the backup changes, as a guide to what the redo may
touch: against `main` it changes `main.gd` (549 lines added, 53 removed), `main.tscn`, `m0_state.gd` and
`m0_actor.gd`; adds `greybox_bay.gd` (931 lines), `dock_paint_data.gd` and `dock_shapes_data.gd`; and edits
or adds tests (`git diff --stat origin/main...origin/codex/opening-dock`, 68 files).
- It also adds a line break to four `INTRO_LINES` (two in the middle of a sentence, two between
  sentences) and splits one box into two. The line-break gate treats such breaks as layout (DESIGN.md,
  "Layout breaks never bind a translation"), and the first PR after the dock lands moves the
  prototype's opening check to the new msgids.
- If the backup branch is retired, nothing here depends on it: the first PR after the redo lands
  re-runs the strings inventory against whatever it brings, and L6 onward starts from there.

- **Can start now,** because it touches none of those files: PRs L1-L5, and the parts of L7d that live
  in `dialogue_boxes.gd`.
- **Starts after the opening-dock work lands:** everything that touches `main.gd`, `main.tscn` or
  `m0_state.gd` (L6 onward). The first PR after it lands re-runs the strings inventory, since the new
  room may add text.
- **The lighter-game plan's remaining steps.** Six of them touch the same files as this plan, and each
  is an IDENTICAL step with the four-route screenshot parity (DESIGN.md, "How the lighter-game plan's
  text steps fit"):

| Lighter step | Touches | Order with this plan |
|---|---|---|
| S01 hud-dirty (on-change HUD writes, the `settings_menu.prompt()` cache) | the key names and prompts L7a and L7b translate | Before L7a; L7a adds the cache clear on `NOTIFICATION_TRANSLATION_CHANGED` and a test that switches language and reads a prompt. If S01 comes later, it carries that clear. |
| S05 helpers (text tables, Hud `key()` and `localise()`, Choice record) | the lines L7b and L7c mark | Default: S05 lands first as its own lighter PR. Otherwise L7b and L7c build those parts and carry its parity gate and effort (below). |
| S08 hud (the Hud view model) | the HUD text L7b marks | The same as S05. |
| S09 title-pause-settings | the title buttons and Settings rows | Before L6, L7a and L8. If it has not started when L6 is due, L6 and L7a go first (no English pixel changes) and S09 carries the LANGUAGE row and auto-translate modes over. |
| S10 endcard-theme | the end card, `settings_menu.tscn`, `settings_theme.tres` | The same as S09; before L7c's end-card text where it can. |
| S11 intro-beatsaver (IntroSequence, BeatSaver) | `INTRO_LINES` and the opening boxes L7c marks | After the opening-dock work lands and before L7c's opening lines; otherwise S11 moves the marks with the lines and carries the opening check in `i18n_test`. |
| S12 room-base (NamePlate) | the station plates | Before L8's plate work (D3). |
| S13-S15 room beats | where hints and objectives live | Either order: beats return English msgids, marked at their tables. |

  **L8 retakes the R1 baseline** (the lighter plan's reference screenshots of route R1, the title and
  menus). L8 is a visible change to the title, so it lands after S09 and S10, and its approved stills
  become the lighter plan's new title-and-menus baseline.

## Gates every PR passes

These are on top of the gates each PR names below:
- `scripts/check-game.sh`: all suites pass, with the language pinned to English from L1 on.
- `python3 -I scripts/check-copies.py --base origin/main`: no copied code.
- **The English stays byte-identical** unless Nathanial approved a wording change. The lighter-game
  plan's risk 2 check compares the set of English literals before and after.
- **Every new or moved function gets developer comments:** purpose, contract, units, gotchas and why.
- **Docs:** player-facing changes update the public changelog (`apps/docs/content/docs/changelog.mdx`,
  then `scripts/export_changelog.py`) and the guide page they touch. Tool and test changes update
  `development/testing.mdx`.
- **Honest claims.** A still or a headless test proves neither game feel nor readability in play
  (AGENT.md). Each language gets one played route before any "reads well" claim.
- **After each milestone,** update Notion and the Codex board through Codex (the process rule).

The **effort** column is an estimate in agent working days, including the gates. It is not measured.
An agent day is about one working day of one Claude Code session doing the PR and its checks. It is not
calendar time: the calendar also waits on Nathanial's answers, reviews, the shared heavy-run slot and
other jobs. **A rough guide, as an estimate only:** Spanish (L9) needs about 20 agent days of PRs, so
about 4 working weeks after his answers if one PR runs at a time and nothing waits, and later if the
opening-dock work, reviews or the heavy slot hold it up. The event to watch for: Spanish can be in the
first release about 13 to 15 PR days after the opening-dock work lands, if Phase 0 is done by then
(Phase 1's 11 to 13 days plus L9's 1.5).

## Phase 0: foundation (can start now)

| PR | What changes | Its gates | Effort |
|---|---|---|---|
| **L1 `i18n-foundation`** | `apps/game/i18n/languages.json`, the one language table, grown from the prototype's `tools/languages.json` with the picker names, font chain, reading speed and review state (only `en` enabled). `scripts/i18n.gd` reads it once at start into `LANGUAGES` and holds the resolver table (DESIGN.md, "How Godot picks a file for the system language"), `saved()`, `apply()` (which keeps only the chosen language's catalog registered, so a missing line shows English and never a sibling file's text), the `KEY.tr` marker, `format()`, `shown()` (with the prototype's guard: a translation whose inserts differ shows the English line) and `lines()`, `missing_glyphs()`, and the build's `overflows()`: containers judged by their outermost Container, trimmed text counted as an overflow, both axes (DESIGN.md, "The prototype's overflow check has four blind spots"). `internationalization/locale/fallback = en`. `check-game.sh` and CI pass `--language en` to every suite. `tests/i18n_test.gd` starts with the resolver, the pinned language, the per-language glyph check (each language with only its own font chain) and the sibling case: with test catalogs for `zh_Hans` and `zh_Hant`, a line only `zh_Hans` has shows English at zh_Hant. | The new suite, with a planted overflow for each blind spot that must fail, and the sibling case failing when `apply()` keeps every catalog. A run with the OS locale set to es must still pass the English suites. No visible change. | 1.5 |
| **L2 `i18n-tooling`** | Moves the prototype's tools into `scripts/i18n/`: `i18n_tool.py` (with the pipeline trial's measures folded in), `extract_pot.sh` and `pot_addon/`. `i18n_tool.py` reads `apps/game/i18n/languages.json`, the same file `I18n` reads, and the prototype's `tools/languages.json` goes, so there is one language list for the game and the tools. **No second capture driver:** the existing `scripts/parity/capture.gd` (on `main`; it already drives routes R1-R4 into saved states, shoots stills at fixed moments, sets the size and touch layout and dumps UI text) gets a `--language <code>` option (any code in `I18n.LANGUAGES`, plus `pseudo`) and the `I18n.overflows()` / `missing_glyphs()` audit beside its UI dump, and `scripts/parity/run.sh` passes the option through. The prototype's `i18n_capture.gd` is not moved; it stays on this research branch as the record of how the prototype's stills were made. **Two release gates** join `check`, with the marks they need: a `review` state per language in `languages.json` (`machine` or `reviewed`, added in L1), and a `#. i18n: story` mark on every story-critical line (written in L7c). `check --release` then fails on any fuzzy entry in a language marked `reviewed`, and on any untranslated line marked `story`. Adds `i18n/` at the repository root. CI gets a Python gates job that fails when `i18n_tool.py check` exits 1, a "POT is fresh" check, and a check that `project.godot`'s `translations_pot_files` equals `i18n_tool.py potfiles`, which lists every `.tscn` and `.gd` at any depth except the tests, the debug tools and add-ons (so a new script such as `greybox_bay.gd`, or the lighter plan's `scenes/ui/end_card.tscn`, cannot stay out of the POT). The as-run copies stay on the research branch (`codex/localization-research`) and are cited by path and commit, so nothing is copied. | check-copies; `i18n_tool.py check` exits 0 on the prototype's four PO files with every gate (placeholders printf and named, BBCode, tag, line breaks, key token, script, glossary, the engineer's gender, name case, plural forms and the header's rule, sibling files, fuzzy notes, conflicting marks); the five negative controls make it exit 1 and fail as recorded; `i18n_tool.py selftest` passes (115 planted cases), plus planted cases for `--release`; `scripts/parity/run.sh` with `--language es` and `pseudo` gives the four routes' stills and an audit, and the English run's parity is unchanged; a test that every language in `languages.json` has its `.po`, its `project.godot` entry and its picker row, and nothing else does; `development/testing.mdx` describes the tools. | 1.5 |
| **L3 `export-templates-icu`** | `scripts/get-export-templates.sh` also unpacks `templates/icudt_godot.dat`, and `verify_export_templates` checks its hash. | A macOS `--export-pack` with a CJK `.po` registered logs no "editor embedded text server data" fallback. | 0.5 |
| **L4 `fonts-cjk`** | Noto Sans SC, TC, JP and KR subsets (D7's default: fixed common sets), each keeping its Noto name (only "Source" is reserved) and each with its OFL text headed by Adobe's copyright line, a manifest entry and `.import`. Not wired yet. `allow_system_fallback` goes off on the game's fonts, so a missing glyph looks the same on every device. If the lighter-game S25b Latin subset happens, it takes its ranges from `LANGUAGES` (Latin-1, Latin Extended-A, Cyrillic). | A glyph test per CJK subset against a fixed character list; a size budget check (D7, fonts and ICU data together); the credits and legal pages list the fonts. | 1 |
| **L5 `glossary-style`** | `i18n/glossary.json` and `i18n/style/<code>.md` for the 10 languages, from the pipeline's packet with Nathanial's D9 and D11 answers. Claude sets up the Weblate project (D8): the repository's PO files, the glossary and the style guides, ready for volunteers when L9 opens Spanish. | The checker reads them; native reviewers can read them; Weblate shows a test line with its notes. No game change. | 1.5 |

## Phase 1: wiring (after the opening-dock work lands)

| PR | What changes | Its gates | Effort |
|---|---|---|---|
| **L6 `settings-language`** | The LANGUAGE row in a GENERAL tab (D10), with the list's own font chain, saved as `[general] language`; the "machine translation" tag on a second row of the open list and as a note under the row (DESIGN.md, "Settings"). With one language it stays hidden. | `ui_controls_test` and `settings_test`; the picker checks in `i18n_test`, including every tag drawable by the list's font chain; a Settings still in en and pseudo; `controls/settings.mdx`; a changelog line once it is visible. | 1 |
| **L7a `mark-menus`** | Title, pause, Settings captions and tooltips, input names and the rebind prompt: auto-translate for scene text, `KEY.tr` for code captions. The volume and rebind rows show display names, not bus or device ids. Key names use `DisplayServer.keyboard_get_label_from_physical`. | The pseudo audit finds 0 untranslated text on the title, pause and Settings stills; the `hardcoded` count for `game_settings.gd` and the menus reaches 0; the key-name change gets a still on an AZERTY layout. | 1.5 |
| **L7b `mark-hud`** (after S05 and S08, or with their Hud parts) | Hints, objectives, top cards and the tutorial. The key tokens `E:`, `HOLD E:`, `Press E` and `press 2` become placeholders filled after `tr()`. "CONTINUE" gets a `msgctxt` (a context tag, so one English word can have two translations) for the touch button. | The pseudo audit on the corridor, Records and junction hint stills; the prompt checks in `m0_scene_test` stay green; the touch layout stills. If it builds S05's or S08's parts: the lighter plan's four-route screenshot parity in English and an empty UI-dump diff. | 1.5 (2.5 with S05 and S08's Hud parts) |
| **L7c `mark-story`** (after S05, or with its text tables and Choice record) | Narration, dialogue, refusals, knockdown cards, restore lines, choices and the end card. Speaker and words are stored apart and the colour goes by speaker id. Lines with inserts use `I18n.format` and named placeholders. Lines whose breaks carry meaning get `#. i18n: keep-breaks`. Every one of the inventory's 26 gender-risk lines gets its `# TRANSLATORS: i18n: engineer=...` mark (and `slot=choice` on the three checkpoint callbacks), which the gender gate and the back-translation read, and every story-critical line its `story` mark for L2's release gate. The save keeps English (DESIGN.md). | `approved_wording_test` unchanged; the `hardcoded` count in code reaches 0; the pseudo audit on every story still; an old save loads and WOLF quotes its choice in pseudo. If it builds S05's parts: the four-route screenshot parity in English. | 3 (4 with S05's tables and Choice record) |
| **L7d `boxes-per-language`** | `DialogueBoxes`: one shared `fits()` (the two copies go); `…` and the «» „“ 「」 quote pairs; per-language characters a second and cap; per-script row rule with a balanced two-row split; `LONG_LINE_WORDS` gets a character equivalent; the station-name wrap uses `TextParagraph`. The rules come from `LANGUAGES`. | `text_boxes_test` loops every language × every `TextSize` step; stills of a Japanese box with no lone short last row. | 2 (the parts in `dialogue_boxes.gd` can start now) |
| **L8 `layout-for-languages`** (after S09, S10 and S12) | D10's title layout: wider buttons (the longest measured is 213 px for es NEW GAME), a CONTINUE note that wraps to two rows, room for the Brand line, PAUSE and the touch USE button. The station plates' fit and their neighbours, if D3 translates them. | `KNOWN_OVERFLOWS` empty with L1's overflow check (trimmed text and height count) on the title, menus, Settings rows, HUD, plates, the end card, the choice rows and the credits, each in a state that shows it; 0 overflows under pseudo +30% on every still; `text_boxes_test`'s existing overlap checks (station names, touch, top card, prompts) run in every language and pass, with no new overlap check written; a played route on desktop and touch for the layout; the title-and-menus parity baseline retaken after Nathanial approves; a changelog line. | 2 |

## Phase 2: the languages

Each language PR follows PIPELINE.md, one batch per scene:
1. Claude translates.
2. Codex back-translates independently, and the session is archived.
3. The gates run.
4. The language is labelled "machine translation" in its own language until review.

The gates every language PR names:
- `msgfmt --check-format --check-header`, and every `i18n_tool.py check` gate with no failure. Drift
  flags are listed in the PR for a person to look at.
- `i18n_test` for the language: it loads, redraws, every character is drawable with OS fallback off,
  nothing overflows, and every box fits at every TEXT SIZE step.
- **Stills** in the container (`render.sh`, an `i18n-` named run under the heavy slot):
  - frames: title, Settings, the opening box, the corridor hint, a Records line, the junction
    knockdown card and the end card;
  - at 1280x720 and on the touch layout;
  - looked at by a person, with what they show written in the PR.
- **One played route** in that language before any readability claim.
- **Docs:** the credits name the tools and any reviewers; a changelog line ("Spanish (Latin America),
  machine-translated, review in progress"); the get-game page and the store notes list the language.

| PR | Languages | Extra gates | Effort |
|---|---|---|---|
| **L9** | es (Latin America) and the es_ES adaptation pass, plus the Spanish part of L13 (Steam's language table rows and the AI disclosure, D2), so Spanish can reach players with the first release after L9 rather than waiting for L13 | the resolver sends es_MX, es_AR and es_US to `es` and es_ES to `es_ES`; Spain's text differs only where the adaptation rules say; the sibling gate: `es` and `es_ES` translate the same lines, none fuzzy | 1.5 |
| **L10** | pt_BR, fr, de | fr uses U+00A0 before `; : ! ?`; de and fr long-word layout stills | 2.5 |
| **L11** | pl and ru | the Slavic rules: no past tense about the engineer (the gender gate, with every gender-risk line marked in L7c); the name only in the nominative (the name-case gate, already in the tool); no one-letter word at a row's end (a new `i18n_tool.py` gate); a native reviewer reads the gendered lines first | 2 |
| **L12** | ja, ko, zh_Hans and the zh_Hant conversion and review | the sibling gate for `zh_Hans` and `zh_Hant`; each turns on its own Noto fallback and only that one (the line-height check per language); reading speed and row rules; `icudt_godot.dat` in the export (L3); ko particles after names | 3 |
| **L13 `exports-and-stores`** | all | macOS export: the `.lproj` folders and the App Store's language list, checked on TestFlight. Windows export. Steam's language table lists only the shipped languages (Spanish's rows already went in with L9), with the AI disclosure (D2). Phone presets come later: Android `locales_config`, `values-pt-rBR`. | 1.5 |

**The changelog and the credits** follow D4. By default the credits screen translates its role text but
no names, and the in-game changelog stays English under a translated heading with a link. Translating
the changelog would add about 13,500 more words per language, nearly five times the rest of the
game (2,860 words).

**Native review** (D8) runs alongside, from L9 on. Before any paid release, each language's story lines
carry reviewer stamps.

## Totals (estimate)

| Phase | Agent days | Notes |
|---|---|---|
| Phase 0 | about 6 | |
| Phase 1 | about 11, or about 13 if L7 builds S05's and S08's parts | the 2 extra days are those lighter steps' work and their screenshot parity |
| Phase 2 | about 10.5 | the four language PRs plus exports and stores |
| **All** | **about 27.5, or 29.5 with S05 and S08 inside L7** | |

Not counted:
- Nathanial's decisions;
- native review time;
- **one played route per language, about 11** (every file but English), by a person, before any "reads
  well" claim (AGENT.md); not estimated, since it is play time, not agent time;
- the lighter plan's S09, S10 and S12 themselves, which are its own PRs;
- store setup;
- the site (D6).

Of these days, Phase 0's 6 can run now, alongside the dock job, and so can the parts of L7d that live
in `dialogue_boxes.gd`.

## Afterwards

- The tiers after the 10 (LANGUAGES.md) are each one PR through the same gates.
- Italian or Polish, whichever is not in the 10, is the first of them.
- The site's localization (D6) is its own plan.
