# Plan: the build, as small PRs

The order in which the game gets its 10 languages, once Nathanial approves the list and the defaults in
[DECISIONS.md](DECISIONS.md). Each PR is small, playable on its own and named for what it changes. The
design is [DESIGN.md](DESIGN.md) and the translation process is [PIPELINE.md](PIPELINE.md).

## When it starts

**The four branches this research waited for have merged:** lighter-1, p0-text, corridor-additions and
doors (PRs #75, #76, #78 and #79). **One branch is in flight:** `codex/opening-dock`. Against `main` it
touches `main.gd` (+602 lines), `main.tscn`, `m0_state.gd` and `m0_actor.gd`, and adds a new room
script, `greybox_bay.gd`.

- **Can start now,** because it touches none of those files: PRs L1-L5, and the parts of L7d that live
  in `dialogue_boxes.gd`.
- **Starts after `codex/opening-dock` merges:** everything that touches `main.gd`, `main.tscn` or
  `m0_state.gd` (L6 onward). The first PR after the merge re-runs the strings inventory, since the new
  room may add text.
- **The lighter-game plan.** Its S05 (text tables, the Hud's `key()` and `localise()`, the Choice record)
  and S08 (the Hud view model) touch the same lines as L7. The L7 PRs build those parts of S05 and S08
  as they go, so no line is marked twice (DESIGN.md, "How the lighter-game plan's text steps fit"). If
  S05 or S08 lands first, L7 builds on it instead.

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

## Phase 0: foundation (can start now)

| PR | What changes | Its gates | Effort |
|---|---|---|---|
| **L1 `i18n-foundation`** | `scripts/i18n.gd` with the full `LANGUAGES` table (only `en` enabled), the resolver table (LANGUAGES.md), `saved()` and `apply()`, the `KEY.tr` marker, `format()`, `shown()` and `lines()`, `missing_glyphs()` and `overflows()`. `internationalization/locale/fallback = en`. `check-game.sh` and CI pass `--language en` to every suite. `tests/i18n_test.gd` starts with the resolver and the pinned language. | The new suite. A run with the OS locale set to es must still pass the English suites. No visible change. | 1 |
| **L2 `i18n-tooling`** | Moves the prototype's tools into `scripts/i18n/`: `i18n_tool.py` (with the pipeline trial's measures folded in), `extract_pot.sh`, `pot_addon/` and `i18n_capture.gd`. Adds `i18n/` at the repository root. CI gets a Python gates job and a "POT is fresh" check. **The as-run copies under `docs/research-2026-10/localization/{prototype,pipeline}/tools/` are deleted in the same PR** and cited by path and commit. | check-copies; `i18n_tool.py check` passes on the prototype's four PO files; the negative controls fail as recorded; `development/testing.mdx` describes the tools. | 1.5 |
| **L3 `export-templates-icu`** | `scripts/get-export-templates.sh` also unpacks `templates/icudt_godot.dat`, and `verify_export_templates` checks its hash. | A macOS `--export-pack` with a CJK `.po` registered logs no "editor embedded text server data" fallback. | 0.5 |
| **L4 `fonts-cjk`** | Noto Sans SC, TC, JP and KR subsets (D7's default: fixed common sets), each with its OFL text, manifest entry and `.import`. Not wired yet. If the lighter-game S25b Latin subset happens, it takes its ranges from `LANGUAGES` (Latin-1, Latin Extended-A, Cyrillic). | A glyph test per CJK subset against a fixed character list; a size budget check (D7); the Reserved Font Name question settled; the credits and legal pages list the fonts. | 1 |
| **L5 `glossary-style`** | `i18n/glossary.json` and `i18n/style/<code>.md` for the 10 languages, from the pipeline's packet with Nathanial's D9 and D11 answers. | The checker reads them; native reviewers can read them. No game change. | 1.5 |

## Phase 1: wiring (after `codex/opening-dock` merges)

| PR | What changes | Its gates | Effort |
|---|---|---|---|
| **L6 `settings-language`** | The LANGUAGE row in a GENERAL tab (D10), with the list's own font chain, saved as `[general] language`. With one language it stays hidden. | `ui_controls_test` and `settings_test`; the picker checks in `i18n_test`; a Settings still in en and pseudo; `controls/settings.mdx`; a changelog line once it is visible. | 1 |
| **L7a `mark-menus`** | Title, pause, Settings captions and tooltips, input names and the rebind prompt: auto-translate for scene text, `KEY.tr` for code captions. The volume and rebind rows show display names, not bus or device ids. Key names use `DisplayServer.keyboard_get_label_from_physical`. | The pseudo audit finds 0 untranslated text on the title, pause and Settings stills; the `hardcoded` count for `game_settings.gd` and the menus reaches 0; the key-name change gets a still on an AZERTY layout. | 1.5 |
| **L7b `mark-hud`** (with S05's Hud `key()` and `localise()`) | Hints, objectives, top cards and the tutorial. The key tokens `E:`, `HOLD E:`, `Press E` and `press 2` become placeholders filled after `tr()`. "CONTINUE" gets a `msgctxt` for the touch button. | The pseudo audit on the corridor, Records and junction hint stills; the prompt checks in `m0_scene_test` stay green; the touch layout stills. | 1.5 |
| **L7c `mark-story`** (with S05's text tables and Choice record) | Narration, dialogue, refusals, knockdown cards, restore lines, choices and the end card. Speaker and words are stored apart and the colour goes by speaker id. Lines with inserts use `I18n.format` and named placeholders. The save keeps English (DESIGN.md). | `approved_wording_test` unchanged; the `hardcoded` count in code reaches 0; the pseudo audit on every story still; an old save loads and WOLF quotes its choice in pseudo. | 3 |
| **L7d `boxes-per-language`** | `DialogueBoxes`: one shared `fits()` (the two copies go); `…` and the «» „“ 「」 quote pairs; per-language characters a second and cap; per-script row rule with a balanced two-row split; `LONG_LINE_WORDS` gets a character equivalent; the station-name wrap uses `TextParagraph`. The rules come from `LANGUAGES`. | `text_boxes_test` loops every language × every `TextSize` step; stills of a Japanese box with no lone short last row. | 2 (the parts in `dialogue_boxes.gd` can start now) |
| **L8 `layout-for-languages`** | D10's title layout: wider buttons (the longest measured is 213 px for es NEW GAME), a CONTINUE note that wraps to two rows, room for the Brand line, PAUSE and the touch USE button. The station plates' fit and their neighbours, if D3 translates them. | `KNOWN_OVERFLOWS` empty; 0 overflows under pseudo +30% on every still; an overlap check between neighbouring plates; a played route on desktop and touch for the layout; a changelog line. | 1.5 |

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
| **L9** | es (Latin America) and the es_ES adaptation pass | the resolver sends es_MX, es_AR and es_US to `es` and es_ES to `es_ES`; Spain's text differs only where the adaptation rules say | 1.5 |
| **L10** | pt_BR, fr, de | fr uses U+00A0 before `; : ! ?`; de and fr long-word layout stills | 2.5 |
| **L11** | pl and ru | the Slavic rules: no past tense about the engineer; the name only in the nominative; no one-letter word at a row's end (a new `i18n_tool.py` gate); a native reviewer reads the gendered lines first | 2 |
| **L12** | ja, ko, zh_Hans and the zh_Hant conversion and review | each turns on its own Noto fallback and only that one (the line-height check per language); reading speed and row rules; `icudt_godot.dat` in the export (L3); ko particles after names | 3 |
| **L13 `exports-and-stores`** | all | macOS export: the `.lproj` folders and the App Store's language list, checked on TestFlight. Windows export. Steam's language table lists only the shipped languages, with the AI disclosure (D2). Phone presets come later: Android `locales_config`, `values-pt-rBR`. | 1.5 |

**The changelog and the credits** follow D4. By default the credits screen translates its role text but
no names, and the in-game changelog stays English under a translated heading with a link. Translating
the changelog would add about 13,500 words per language, about 6 times the rest of the game.

**Native review** (D8) runs alongside, from L9 on. Before any paid release, each language's story lines
carry reviewer stamps.

## Totals (estimate)

| Phase | Agent days | Notes |
|---|---|---|
| Phase 0 | about 5.5 | |
| Phase 1 | about 10.5 | |
| Phase 2 | about 10.5 | the four language PRs plus exports and stores |
| **All** | **about 26.5** | |

Not counted:
- Nathanial's decisions;
- native review time;
- store setup;
- the site (D6).

Of the 26.5 days, Phase 0's 5.5 can run now, alongside the dock job, and so can the parts of L7d
that live in `dialogue_boxes.gd`.

## Afterwards

- The tiers after the 10 (LANGUAGES.md) are each one PR through the same gates.
- Italian or Polish, whichever is not in the 10, is the first of them.
- The site's localization (D6) is its own plan.
