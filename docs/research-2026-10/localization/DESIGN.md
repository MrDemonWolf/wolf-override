# Design: languages in the Godot game

How WOLF//OVERRIDE (Godot 4.7.2, `apps/game`) gets its languages. The prototype tested this design on
`main` at 1cf8d73 in a scratch copy only ([prototype/README.md](prototype/README.md); the whole change is
`prototype/evidence/game.patch`). Every Godot behaviour below cites either the 4.7.2-stable source
(ed1daf0bf) or our own headless measurement in `godot/evidence/` and `prototype/evidence/`. Nothing here
is wired into the game yet. The build order is [PLAN.md](PLAN.md).

## The rule: English stays the game's internal text

Constants, `status_line`, saves, comparisons and tests keep the English words. Text is translated only
where it is drawn.

**Why this rule:**
- Code compares English text in at least five places: the key tokens, speaker tags, the speaker's
  colour, end-card topics and `DialogueBoxes`' word and sentence rules (STRINGS.md). Translating at the
  source would break all of them at once.
- The save stores the choice the player saw as English (`selected_text`). With English internal, an
  old save quotes the right line in any language, and no save version changes.
- About 270 test checks assert English. All 25 suites passed with no test edits in the prototype, once
  with es, de and ja and again with Russian added.
- Nathanial's approved wording stays byte-identical, as the lighter-game plan already requires.

**Text reaches the screen in one of three ways** (documented once, in the `I18n` class):

| Kind of text | How it is translated | Examples |
|---|---|---|
| A Control whose whole text is one message | Godot's auto-translate: the Control gets the English and translates itself, also when the language changes (`scene/main/node.cpp`, `auto_translate_mode`; the root's default is ALWAYS) | title buttons, Settings captions |
| Text worked out every frame | `tr()` where it is worked out; templates are translated first and filled after (`tr(RETRY_PROMPT) % key`) | hints, tutorial prompt, RETRY prompt |
| Text kept between frames | stays English, and is translated where it is drawn by `I18n.shown()` and `I18n.lines()`; its Label has auto-translate off, so nothing is translated twice | `status_line` (narration, knockdown cards), the top card |

**Extraction marker for constants: `I18n.KEY.tr(CONST)`.**
- `KEY` is an object with message translation turned off, so the call returns its argument unchanged.
- Godot's GDScript parser plugin matches the method name `tr` only
  (`modules/gdscript/editor/gdscript_translation_parser_plugin.cpp`), so it still extracts the
  constant. The prototype measured it extracting across classes and through a const-array index.
- `tr()` cannot be called in a `static func` (a parse error) or in a `const` initialiser (not a
  constant expression), both measured in `godot/evidence/static.txt`. So the English stays in the
  `const` and the mark sits at the use site.

## One shared locale module: `scripts/i18n.gd` (`class_name I18n`)

All locale code lives here once. The prototype's version is in `prototype/evidence/game.patch`.

**The language table, `LANGUAGES`.** One list holds every per-language fact, and everything else reads
it:
- the Godot code and the picker name (in its own language);
- the font fallback (none, JP, SC, TC or KR);
- the reading speed in characters per second;
- the row character limit;
- the plural form count;
- the review state (machine-translated or reviewed).

ConPaws' history is why there is one list. Its language list drifted three times between the picker,
`CFBundleLocalizations`, the Swift widget tables and the Intl data imports. It now keeps one list plus
parity tests (`apps/native/src/lib/supported-locales.ts`). Here a test checks that
`project.godot`'s `internationalization/locale/translations`, the `.po` files on disk, the picker and
the export presets all match the table.

**The resolver, `resolve()`.** It turns a locale into an offered language with an explicit table, as
ConPaws' `resolveDeviceLocale` does:
- `es` is Latin America unless the region is ES;
- Portuguese goes to `pt_BR`;
- Chinese goes by script, then region: Hant, TW, HK and MO go to `zh_Hant`, the rest to `zh_Hans`;
- `no` and `nn` go to `nb` (Tier 3);
- `uk` goes to `en`, never `ru`.

Only then does it fall back to Godot's own `compare_locales`. On a tie Godot picks the translation added
last, so a tie must never decide (LANGUAGES.md, "How the OS language picks a file").

**Choosing and keeping the language:**
- `saved()` uses the language saved in `settings.cfg`, `[general] language`.
- With none saved, it uses the locale Godot started in. That is `OS.get_locale()`, unless `--language`
  or `internationalization/locale/test` overrides it (`core/string/translation_server.cpp`, `setup`).
- `apply()` sets the fallback font for the language, then calls `TranslationServer.set_locale()`.

**Redrawing on a change.** `set_locale` sends `NOTIFICATION_TRANSLATION_CHANGED` to every node
(`scene/main/scene_tree.cpp`).
- Auto-translating Controls redraw themselves.
- Main redraws the top card from its English source and refits the station labels.
- Hints, prompts and dialogue boxes are recomputed every frame anyway.
- The prototype measured the title, an opening narration box, the name card, the location card, a
  hint, a knockdown card and the RETRY prompt each redrawing with their inserts, in es, de, ja and ru.

**Formatted lines.**
- `I18n.format(template, inserts)` builds the English line and remembers its template.
  `I18n.shown()` then translates the template and fills it again.
- Lines with speaker tags are translated piece by piece, so the tags stay outside the translated
  text. This is a stopgap until speaker and words are stored apart (below).

**Checks the tests and the render driver share:**
- `missing_glyphs(text, font)`: uses `Font.has_char`, which never asks OS fonts.
- `overflows(control)`: compares a Control against the width its anchors and offsets give it. A
  Control grows to its minimum size, so comparing it with its own rect never fires.

## One catalog per language

**Format: gettext PO, one file per language** (`apps/game/i18n/<code>.po`).
- **PO loads at runtime with no import.** `core/io/translation_loader_po.cpp` reads `.po` and `.mo`,
  and takes the locale from the `Language:` header.
- **Exports carry the file raw** (measured: "Storing File: res://i18n_probe/ja.po").
- **Fuzzy entries are skipped**, so an unreviewed change never ships: the loader drops any entry after
  a `fuzzy` comment (measured). `#.` notes give translators context.
- **Plurals and contexts work:**
  - `msgctxt` "verb" against "adjective" gave Abrir / Abierto.
  - Russian `tr_n` gave 1 клапан, 2 клапана, 5 клапанов, 11 клапанов, 21 клапан, 22 клапана
    (`godot/evidence/runtime.txt`).
- **An empty `Plural-Forms:` header logs an error** (`core/string/plural_rules.cpp`), so every file
  carries its language's rule.
- **CSV was ruled out.** Godot 4.7's CSV importer has context and plural columns
  (`editor/import/resource_importer_csv_translation.cpp`), but it keeps every language in one sheet.
  It has no fuzzy or review state, needs an editor import and cannot load at runtime.

**Locale codes** are in LANGUAGES.md: `en`, `zh_Hans`, `zh_Hant`, `ru`, `es` (Latin America),
`es_ES`, `pt_BR`, `de`, `ja`, `fr`, `ko` and `pl`. Godot reduces `es-419` to `es` because its parser
keeps only two-letter upper-case regions (`Locale::Locale`), so the Latin-American file is `es`.

**Registration.** The files are listed in `project.godot`, `internationalization/locale/translations`,
which `main/main.cpp` loads once at start-up. The same tool that writes the PO files keeps this line in
step with `LANGUAGES`.

**Outside `res://`.** The template (`messages.pot`), the glossary and the per-language style guides live
in a repository-root `i18n/` folder. A template inside the project is scanned or imported (a CSV
template is imported as an empty translation, measured), and a `.json` inside it would be exported.

## One extraction tool

- **The POT comes from Godot's own generator, run headless.**
  - 4.7.2 has no command-line switch for it, and `TranslationTemplateGenerator` is not bound to
    scripts (`editor/translations/localization_editor.cpp` is its only caller).
  - The prototype's `tools/extract_pot.sh` installs `tools/pot_addon/` for one
    `godot --headless --editor` run. The plugin emits `file_selected` on the localization editor's
    save dialog, which runs the real generator.
  - It took about 5 s after the import.
  - Moved to `scripts/i18n/`, it is the one extractor. It depends on editor internals, so a Godot
    update is checked against it. A CI step fails when the committed POT differs from a fresh
    extraction.
- **Don't write a second extractor.**
  - The pipeline step proposed a Python extractor that mirrors Godot's rules. It would be a second
    parser, and it would drift from Godot's.
  - The strings step's `extract_literals.py` stays a research tool: the inventory that shows what is
    not yet marked (`i18n_tool.py hardcoded`), not a source of msgids.
  - If text ever moves into data files, an `EditorTranslationParserPlugin` (public API,
    `editor/plugins/editor_plugin.cpp`) teaches the same generator to read them.
- **One Python tool, `scripts/i18n/i18n_tool.py`,** moved from `prototype/tools/` with the measures it
  imports from the pipeline step folded in. It covers:
  - writing and merging the PO files (with `msgmerge` for updates);
  - every gate (PIPELINE.md);
  - the hardcoded-strings report;
  - the font subsets.
- **What the generator extracts:**
  - `tr`, `tr_n`, `atr` and `atr_n` calls whose argument reduces to a constant;
  - `.text`, `.tooltip_text` and `.placeholder_text` assignments;
  - `add_item`-style calls;
  - scene `text`, `title` and `tooltip_text` properties;
  - `# TRANSLATORS:` comments, which become `#.` notes.

  It skips lines marked `# NO_TRANSLATE` and `TranslationServer.translate("...")`. It also writes no
  `#, c-format` flag, so the tool adds one wherever a msgid has `%s` or `%d`. Without the flag,
  `msgfmt --check-format` checks nothing (measured).

## Settings: the LANGUAGE option

- **The row.** The prototype put a LANGUAGE row under FULLSCREEN on the DISPLAY tab. It has 215 px
  before TEXT SIZE's caption, which trims "Español (Latinoamérica)" on the button (the open list shows
  it whole). The default for decision D10 is a new **GENERAL** tab holding LANGUAGE, laid out like the
  other tabs.
- **Names.** Each language is named in its own language (LANGUAGES.md) and the list is never
  translated.
- **The list's font.** The list draws with its own font chain: the game font plus tiny CJK subsets
  holding only the picker's names. So 日本語, 한국어, 简体中文 and 繁體中文 draw in every language
  without putting a CJK font behind the game's fonts.
- **The setting.**
  - It is saved with the other settings.
  - With none saved, the game follows the OS.
  - The list follows changes made anywhere, through `NOTIFICATION_TRANSLATION_CHANGED` (the prototype
    fixed a bug here).
  - There is no "follow the system" entry. The first run follows the OS, and a pick is kept.
- **Unreviewed languages** carry a short tag in their own language (PIPELINE.md).

## Fonts

**Latin and Cyrillic need nothing new.** The game's Roboto-Variable and Montserrat-Variable cover the
letters of es, pt_BR, fr, de and pl, and Cyrillic for ru (also it, tr, uk and vi for later tiers). This
was measured with `Font.has_char` (`godot/evidence/fonts.txt`) and fontTools (`pipeline/`). The
prototype's suite checked every character of the Russian samples against the theme fonts with no
fallback: none missing, and Roboto's line height unchanged.

Two exceptions:
- Both fonts lack U+202F, the narrow no-break space French uses before `; : ! ?`. French text uses
  U+00A0 instead.
- Montserrat has only 8 of 144 Greek glyphs (Tier 3).

**CJK: one bundled Noto subset per language, chained only while that language is on.**
- **Why bundle?** The OS fallback is not reliable. On the Mac, 5 of 30 Japanese glyphs and all 13
  Chinese glyphs came out as tofu (measured). There is no OS font fallback on web exports at all, and
  the 4.7 docs call Android's unreliable. The ship check turns `allow_system_fallback` off.
- **Which fonts?** Noto Sans SC, TC, JP and KR, from notofonts/noto-cjk (SIL OFL 1.1; the licence file
  ships next to each font, as the prototype's `NotoSansJP-OFL.txt` does). A subset counts as a
  Modified Version under the OFL. Whether the subset may keep the Noto name is the open Reserved Font
  Name question (decision D7).
- **One per language, because of Han unification.** A Simplified Chinese font draws Japanese kanji in
  Chinese shapes, so each language gets its own font.
- **Only while that language is on, because of a measured trap.** `Font.get_height()` takes the
  tallest font in the chain. With Noto behind Roboto, Roboto's line height grew from 21 to 25 px at
  17 px, which moved every Latin label and broke 2 suites. The prototype's `I18n.use_japanese_fallback`
  became `use_fallback(language)`, and in Japanese lines are about 19% taller. Every surface is checked
  in each CJK language.

**Sizes:**

| Subset | Bytes | Measured or estimate |
|---|---|---|
| Noto Sans JP, prototype texts only (673 code points) | 139,224 | measured |
| Noto Sans JP, kana + all 2,965 JIS level-1 kanji | 878,736 | measured |
| Noto Sans JP Regular, full OTF | 4,533,028 | measured |
| Simplified Chinese, GB2312 level 1 (3,755 hanzi) | 1,375,388 | measured on an Apple system font, so an estimate for Noto SC |
| Noto Sans TC (common Big5) and KR (2,350 KS X 1001 Hangul) | about 1-1.5 MB each | estimate, not measured |
| Full Noto Sans CJK SC | about 16 MB | CTAN listing |

The default for decision D7 is fixed common-character subsets, about 1 MB each and 4-5 MB for all four
(estimate). They never need re-subsetting when the English changes. The glyph test guards them.

**The lighter-game plan's amendment says "fonts are subset to Latin" (S25b).** That subset must keep
Latin Extended-A and Cyrillic for pl and ru, plus Latin Extended Additional if Vietnamese ever ships.
The S25b PR takes its ranges from the `LANGUAGES` table instead of a fixed Latin set.

**Line breaking.**
- CJK and Thai break lines with ICU dictionary data, `icudt_godot.dat` (4,797,472 B measured).
- The export adds it on its own once a ja, zh, ko or th translation is registered (measured). In the
  measured export it came from the editor's embedded copy, because `scripts/get-export-templates.sh`
  unpacks only four template files. That script also unpacks `templates/icudt_godot.dat` and checks
  its hash.
- The line-break locale is the current `TranslationServer` locale
  (`modules/text_server_adv/text_server_adv.cpp`).

## Dialogue boxes and TextSize (the P0 text work)

`DialogueBoxes` and `TextSize` came in with p0-text (PR #76). They keep working, with these changes:

**Split after translating.**
- `main.gd` translates the whole line, then calls `DialogueBoxes.split`, and the Story label has
  auto-translate off. Otherwise each box would be translated after the split, and box-sized keys never
  match. The prototype does this.
- The fit rule `main.gd _dialogue_fits` and `text_boxes_test.gd`'s fit callable are two copies of one
  rule. The wiring PR moves it into `DialogueBoxes.fits()`, and both callers use that.

**Speaker and words apart.**
- A line's speaker is data, not text inside the msgid. `"%s: " % speaker` is composed in code, so a
  translation never carries a tag.
- A fullwidth colon `WOLF：` was not recognised as a tag (measured), and French puts a space before
  the colon.
- The colour is chosen by speaker id, not by comparing `"WOLF"` or `"DIRECTOR"` text.
- Speaker names are translated by their own msgids with the context "speaker". WOLF and the engineer's
  name stay as written.

**Sentence and clause breaks.**
- The prototype added `。！？` as sentence ends and `；，、` as clause marks that need no following
  space. Without them, a Japanese knockdown box was one box too long (measured).
- Still to add: `…`; the quote pairs «…», „…“, „…”, “…”, 「…」 and 『…』 for quote tracking; and `¿ ¡` as openers.

**Per-language reading speed.** `read_seconds` uses 0.05 s a character, which is 20 characters a
second, Netflix's English adult speed. A Chinese box counts as one word, so the per-word rule never
applies to it. Netflix's adult speeds by language:

| Language | Netflix speed |
|---|---|
| zh-Hans | 9 cps |
| ja | 4 cps |
| ko | 12 cps |
| Castilian and Latin-American Spanish | 17 cps |
| English | 20 cps |

The `LANGUAGES` table holds characters per second, and the cap scales with it. At 4 cps the current
7 s cap covers only 28 Japanese characters. These numbers are a starting point. Nathanial can tune them
after play.

**Per-script row limits.**
- `MAX_ROW_CHARACTERS` (42) falls back to the pixel width when a row has no spaces. At 17 px in the
  440 px column, a row holds about 25 hanzi (measured).
- Netflix's limits are 16 characters for zh and ko and 13 for ja, but the game's boxes are not TV
  subtitles.
- The default: CJK rows run to the column width, and boxes split into two balanced rows, so no short
  last row is left alone (the prototype's ja stills showed "た。" and "いる。" alone on a row).
- `LONG_LINE_WORDS` (20 words) gets a character equivalent for CJK, to be tuned from stills.

**TextSize.**
- The factor (100-200%) multiplies font sizes in every language.
- The box-fit test runs each language at each `TextSize.STEPS` value.
- The station-name wrap splits on spaces, which fails for CJK names. It moves to `TextParagraph`
  breaking, as `DialogueBoxes.rows` already uses.

## How the lighter-game plan's text steps fit

The lighter-game plan (`../lighter-game/PLAN.md`) is the ordered refactor of `main.gd`. Its steps S05,
S08 and S13-S15 touch the same text:

| Lighter step | What it does to text | How languages ride on it |
|---|---|---|
| **S05 helpers** | Per-room text tables (byte-identical); a Choice record; the Hud's `key()` and `localise()` | The text tables are where the `I18n.KEY.tr` marks go, once per table entry. A Choice keeps answer ids, not words. `localise()` *is* the key-token fill: build it once, as placeholders filled after `tr()`. Don't build a substring replace and then a placeholder fill. |
| **S08 hud** | A Hud script with a view model (status, hint, objective, card key), applied only on change; a prompt cache cleared on rebind or device change | The view model holds English keys and their inserts, and the Hud translates when it applies them. That is the display boundary. The prompt cache is also cleared on `NOTIFICATION_TRANSLATION_CHANGED`. |
| **S13-S15 corridor, Records and junction beats** | Hints and objectives move into each room's beats | Each beat returns English msgids, marked at its table. Nothing in the beats calls `tr()`. |

**Order.** Either order works, but don't mark every line twice:
- If S05 has not landed when the text-marking PRs start, the marking PR builds S05's per-room text
  tables at the same time.
- If S08 lands after the language wiring, the prototype's `I18n.shown()` and `I18n.lines()` calls
  move from `main._refresh_ui` into the Hud with it.

The lighter plan's rule "strings stay byte-identical" stays true, because English does not change.

## Tests that assert English

- **Nothing to rewrite.** English is the internal text, so `approved_wording_test`, `m0_scene_test`
  and the others keep asserting English and keep passing (measured: 25 of 25 suites in the prototype).
- **Pin the language.** `I18n.saved()` follows the start-up locale, so on a Mac set to Spanish, German
  or Japanese the English suites would draw that language. `scripts/check-game.sh` passes
  `--language en` to each suite, and the CI workflow does the same. The CI runner's locale is
  untested.
- **New per-language checks,** in `tests/i18n_test.gd` (the prototype's, extended):
  - the resolver table;
  - every PO file loads and matches `LANGUAGES`;
  - the picker;
  - redraw on a change;
  - the fallback font on only for its language;
  - every character of every translation drawable by the bundled chain with OS fallback off;
  - no overflow on the title, menus, HUD and station plates in every language, with known overflows
    pinned by name;
  - pseudolocalization reaching composed text.
- **The box fit runs per language.** `text_boxes_test` loops its corpus over every language and
  `TextSize` step.
- **The Python gates** (`i18n_tool.py check`) run in CI without Godot.
- **Stills per language,** from `prototype/capture/i18n_capture.gd` moved to `scripts/i18n/`, are
  review evidence, not a test. A still proves neither game feel nor readability in play (AGENT.md).

**Pseudolocalization** is Godot's own (`internationalization/pseudolocalization/*`).
- Turn accents and doubled vowels off. They turned `{name}` into `{ήáám̀éé}` and `[b]` into `[ḅ]`
  (measured), and they break the `E:` token.
- Use expansion 0.3 with brackets.
- It reaches every auto-translating Label even before any `tr()` wiring, so it can audit the current
  game straight away.

## Export settings

- **Raw catalogs.** With `export_filter="all_resources"` (both presets today), the export carries the
  `.po` files raw and `icudt_godot.dat` for CJK.
- **Per-preset languages.** Presets have no locale filter in 4.7.2 (`editor/export/editor_export_preset.cpp`).
  A preset that should ship fewer languages, such as a mainland-China build, overrides
  `internationalization/locale/translations` with a feature tag.
- **The app name stays "WOLF//OVERRIDE" in every language.** Leave
  `application/config/name_localized` empty and give the name no translation.
  - The macOS export still writes `Contents/Resources/<locale>.lproj/InfoPlist.strings` for each loaded
    locale (`platform/macos/export/export_plugin.cpp`). Forum evidence says that is what the App Store
    lists as the app's languages; this needs a TestFlight or store check.
  - Godot names those folders `pt_BR.lproj` and `zh_Hans.lproj`, not Apple's `pt-BR`. Also to be
    checked on a device.
- **Phones.** There are no iOS or Android presets yet (`apps/game/export_presets.cfg` has macOS and
  Windows).
  - When they come, Android 13's per-app language needs a hand-added `locales_config`, which Godot
    does not generate.
  - Godot's Android template has no `values-pt-rBR` folder (`platform/android/java/app/res`).
- **The templates.** `scripts/get-export-templates.sh` unpacks and verifies
  `templates/icudt_godot.dat` with the other template files.
- **Store pages are typed into the stores,** not built by the engine: Steamworks, App Store Connect
  and Play Console. Steam lists only the languages that ship (PIPELINE.md).

## Where the files go

| Path | What |
|---|---|
| `apps/game/scripts/i18n.gd` | the one locale module |
| `apps/game/i18n/<code>.po` | one catalog per language (shipped) |
| `apps/game/assets/fonts/NotoSans{SC,TC,JP,KR}-Subset.otf` and `-OFL.txt` | CJK fallbacks, each with its licence and a manifest entry |
| `apps/game/tests/i18n_test.gd` | the language suite |
| `i18n/messages.pot`, `i18n/glossary.json`, `i18n/style/<code>.md` | template, glossary and style guides (repository root, outside `res://`) |
| `scripts/i18n/i18n_tool.py`, `extract_pot.sh`, `pot_addon/`, `i18n_capture.gd` | the one tool, the extractor and the render driver, moved from `prototype/` |
