# i18n prototype (step prototype, 2026-10-16)

The researched approach works in WOLF//OVERRIDE. I tested it in a scratch export of `origin/main` at
1cf8d73, with Godot 4.7.2.stable.official.ed1daf0bf. Nothing went onto a branch of the repository and
no English line changed. The whole change is one patch, `evidence/game.patch`. It applies cleanly to a
fresh `git archive origin/main` (checked with `git apply --check`).

**What it proves:**

- Extraction works with Godot's own POT generator, run headless.
- Settings has a LANGUAGE row. The game starts in the OS language and falls back to English.
- The PO files load at runtime.
- Text is translated where it is drawn and redrawn when the language changes. This covers the title,
  a hint, the top card, a narration box and a knockdown card.
- es-419, de and ja were translated by Claude and back-translated independently by Codex. The checks
  from the pipeline step ran on the result.
- A subset Noto Sans JP fallback font draws all the Japanese.
- Pseudolocalization covers the whole game.
- A headless suite passes, and so do the game's other 24 suites.
- 45 stills render with 0 tofu.

**What it also found:**

- Some overflows, listed below.
- A font-metrics trap: a CJK fallback font makes every Latin line taller.
- A few things the real wiring job must design differently.

The translations are proof samples only. A native speaker has not reviewed them, and the story and
WOLF wording stay Nathanial's.

## What was built (scratch only)

### 1. Extraction: Godot's own generator, headless

- **What runs:** `tools/extract_pot.sh` with `tools/pot_addon/` (the one copy of the tool). It installs
  an EditorPlugin for one run of `godot --headless --editor` and emits `file_selected` on the
  LocalizationEditor's save dialog. That runs the real `TranslationTemplateGenerator`. Afterwards it
  removes the plugin and restores `project.godot` byte for byte.
- **Origin:** the research-godot step proved this route. Its plugin moved here, and
  the research-godot step's folder (`../godot/probe/pot_probe/`) keeps only its fixture.
- **What it scans:** the project's new `internationalization/locale/translations_pot_files`, written by
  `tools/i18n_tool.py potfiles`. That is every scene and script except `scripts/debug/` (out of scope)
  and the tests.
- **Result:** `evidence/messages.pot` with **149 msgids**. On main the same generator found 75 (research
  step). By reference location:
  - `scripts/main.gd` 97
  - `scenes/main.tscn` 40
  - `scripts/game_settings.gd` 13
  - `scripts/junction_room.gd` 9
  - `scenes/studio_logo.tscn` 1

  The editor run took 5 s after the import; the scratch import itself took 9 s. Log:
  `evidence/logs/pot.log`.

**The marker that makes the const style extractable: `I18n.KEY.tr(CONST)`.**

- `KEY` is a `RefCounted` with `set_message_translation(false)`, so the call returns its argument
  untranslated. Godot's GDScript parser plugin matches the method name `tr` only, so it still extracts
  the constant.
- Measured in the POT:
  - `I18n.KEY.tr(INTRO_LINES[1])` (a const array index) → `#: scripts/main.gd:1718`
  - `I18n.KEY.tr(JunctionRoom.VENT_REASON)` (another class's const) → `#: scripts/junction_room.gd:774`
    and `#: scripts/main.gd:5216`
- This lets English stay the internal text and be translated only where it is drawn (see 2).

**What the generator misses:**

- **Consts that are never passed to `tr()` or `KEY.tr()`.** Godot reads no const member. This is most
  of the story text today; the count is in section 4.
- **Format flags.** Godot writes no `#, c-format` flag (measured), so `tools/i18n_tool.py fill` adds it
  wherever the msgid has `%s` or `%d`. Without it, `msgfmt --check-format` checks nothing.
- **Tagged lines.** A line that keeps its speaker tag inside the const ("DIRECTOR: ...") cannot give the
  tag-free msgid that display-time translation needs. I left those rows out of the marker
  (`Main._intro_keys`). The wiring job should store speaker and words apart.
- **Text that is not GDScript:** `changelog.txt` and the 3 phrases painted in `corridor-seal-atlas.png`.
- **Engine key names:** `OS.get_keycode_string` returns English names such as "Escape" (see 4).

### 2. Locale plumbing

`scripts/i18n.gd` (`class_name I18n`) holds all of the locale code once.

**The language list:** `LANGUAGES` holds `en`, `es` (shown as "Español (Latinoamérica)"), `de` and `ja`.
Godot reduces es-419 to `es`, so a Spain file would be `es_ES`.

**Choosing the language:**

- `resolve()` maps a locale to a language the game has, or to `en`. Measured: es_MX, es_419, es-419 and
  es_ES give es; de_AT gives de; ja_JP gives ja; fr_FR, pt_BR and "" give en.
- `saved()` uses the language saved in `settings.cfg` under `[general] language`. With none saved, it
  uses the locale Godot started in: the OS's, unless `--language` or `internationalization/locale/test`
  overrides it.
- `apply()` calls `TranslationServer.set_locale`.

**Loading translations:** `project.godot` lists `res://i18n/{es,de,ja}.po` in
`internationalization/locale/translations`. Godot loads them raw at start-up, with no import step.

**Settings:** the DISPLAY tab has a LANGUAGE row under FULLSCREEN (`game_settings.gd`).
- The list is never translated. Its own font chain draws "日本語" in every language.
- It follows language changes made elsewhere, through `NOTIFICATION_TRANSLATION_CHANGED`.
- The choice is saved with the other settings.

**Three ways text reaches the screen translated** (documented in the `I18n` class):

1. **Whole-message Controls keep auto-translate.** This covers scene buttons and Settings captions.
   Continue's code-set text and note stay English internally and are marked with `KEY.tr`.
2. **Text worked out every frame calls `tr()` where it is worked out.** This covers every `_context_hint`
   return (the corridor and Records hints), the tutorial prompt, the opening hint and the RETRY prompt.
   - Templates are translated before they are filled: `tr(RETRY_PROMPT) % key`.
   - The `E:` key token is replaced after translation.
3. **Text kept between frames stays English and is translated where it is drawn.**
   - `status_line` (narration and knockdown cards) goes through `I18n.shown()`. Formatted lines are
     built with `I18n.format(template, inserts)` so the template can be translated and filled again.
   - The top card goes through `I18n.lines()`, line by line.
   - Their Labels (story, speaker, hud, hint and tutorial) have auto-translate off, so nothing is
     translated twice.

**Refreshing on a language change:**

- `Main._notification(NOTIFICATION_TRANSLATION_CHANGED)` redraws the top card from its English source
  without showing it again, and refits the station labels.
- Hints, prompts and dialogue boxes are recomputed every frame. The dialogue split key holds the
  translated line, so boxes split again on their own.
- Measured in `i18n_test`: the title, the opening narration box, the name card, the location card, the
  hint, the knockdown card and the RETRY prompt each redraw in the new language with their inserts.

**English stays the internal state:**

- `status_line`, save data, comparisons and the roughly 270 English test asserts are unchanged.
- That is why all 24 existing suites pass with no test edits.

**DialogueBoxes:**

- It now breaks after `。！？` and the clause marks `；，、` with no following space, and rejoins those
  pieces with no space.
- Without this, the Japanese knockdown card was one box too long for two rows (measured: the `ja`
  fits check failed before the change and passes after it).

### 3. Translations (es-419, de, ja), made with the pipeline the research chose

| Step | What happened |
| --- | --- |
| Source | 34 msgids drawn on the prototype's frames (`translations/claude.json`, with a context note per line) |
| Translator | Claude (this session), with `../pipeline/style_packet.md` and `../pipeline/glossary.json`. The engineer is never gendered: `MAINTENANCE ENGINEER` became INGENIERÍA DE MANTENIMIENTO, WARTUNGSTECHNIK and 保守技術者. WOLF is "he". |
| PO files | `tools/i18n_tool.py fill` writes POT comments, `#. TRANSLATORS:` context, `# machine-translated by Claude (Anthropic), unreviewed`, `#, c-format`, and Plural-Forms per language |
| Independent check | Codex (ChatGPT subscription, read-only sandbox, no API key in the environment) back-translated all 102 texts **without seeing the English** and added a note on anything ambiguous or gendered. It used 37,015 input and 3,007 output tokens. |
| Gates (`tools/i18n_tool.py check`, `evidence/po_check.json`) | `msgfmt --check-format --check-header`: rc 0 for all three. The pipeline step's measures (placeholders, speaker tag, line breaks, glossary; imported from `../pipeline/tools/trial.py`, not copied) plus the `E:` token: **0 failures out of 102**. Drift (chrF < 35 on lines over 4 words): **2 flags, both es** (the next table). Mean chrF of the back-translations against the English: es 77.1, de 70.5, ja 77.4. |
| Negative control | A broken copy of es.po (`%s` dropped, `%s` changed to `%d`, `E:` removed) failed all three: msgfmt found 2 fatal errors and the token check caught the third (`evidence/po_check_negative_control.json`) |
| Overflow loop | The overflow gate caught 2 title buttons (section 5). de SETTINGS "EINSTELLUNGEN" became "OPTIONEN", which fits; Codex back-translated it as OPTIONS in a second session. es "NUEVA PARTIDA" stays: the shorter "NUEVO JUEGO" still needs 193 px of the 186 px slot (measured). |

**What the back-translation caught** (a person decides; the prototype keeps the samples as they are):

| Language | Line | What Codex reported |
| --- | --- | --- |
| es | "Head right to the breaker." and "Or head right to the breaker." (drift flags) | "interruptor" back-translates as "switch", and so do the CHECK and ARM objectives. The glossary needs a word for breaker. |
| es | BLOQUEO for LOCKDOWN | Reads as "blockage". |
| de | "HALTEN E:" | Unnatural word order. It is forced by the `E:` token; see finding 6. |
| de | VERSORGUNGSKNOTEN | Reads as "supply node". |
| ja | 所長 | Reads as "head of the facility". Whether the Director is a title or a name is Nathanial's decision. |

The style packet's ask to avoid gendered nouns for the engineer held. Codex noted that every engineer
noun is neutral: "Names a discipline or department, not an individual engineer", and for ja "The role
is not gendered".

### 4. Fonts

**The Japanese fallback:**

| | |
| --- | --- |
| Source | `NotoSansJP-Regular.otf` from notofonts/noto-cjk `Sans/SubsetOTF/JP`. That file last changed in commit 165c01b46ea5 (2021-04-30); the latest Sans release is Sans2.004, 2022-01-27. SHA-256 dff723ba…5073, 4,533,028 B. |
| Licence | `Sans/LICENSE`: SIL OFL 1.1, bundled as `assets/fonts/NotoSansJP-OFL.txt`. The LICENSE file has no copyright line or Reserved Font Name line, so the RFN question stays open. |
| Prototype subset | 139,224 B, 673 code points: ASCII, CJK punctuation, kana, full-width forms, "日本語" and every character of the ja texts. All 82 code points beyond those ranges are in JIS X 0208 level 1. Made with hb-subset 14.6.0 (`tools/i18n_tool.py subset`). |
| Size estimate for the full game | Measured on a test subset of kana plus all 2,965 JIS level-1 kanji: 878,736 B. |

**Measured trap: a CJK fallback makes every Latin line taller.**

- `Font.get_height()` takes the tallest font in the chain. With Noto behind Roboto, Roboto's line
  height grew from 15 to 18 px at 12 px, from 21 to 25 px at 17 px, and from 28 to 34 px at 23 px. The
  shaped string height stayed the same.
- With the fallback on in every language, `m0_scene_test` and `text_boxes_test` failed: the
  COOLANT RELAY name overlapped its COOLANT FAULT tag, and the touch dialogue box overlapped the
  ◀ and USE buttons.
- So `I18n.use_japanese_fallback()` puts Noto behind Roboto and Montserrat **only while Japanese is on**,
  and the language list has its own chain (`I18n.language_list_font`). After that, all suites pass.
- In Japanese, lines are about 19% taller. The ja stills fit, but the wiring job should check every
  surface in Japanese.

**Glyph test:** `i18n_test` checks 235 distinct characters against Roboto-Regular, Montserrat-Semibold
and Montserrat-Bold with the Japanese chain, using `Font.has_char` (which never asks OS fonts): 0
missing. The render audit found 0 tofu in 45 frames, which hold 492 visible texts in all (inside the
container, which has no Japanese system fonts).

### 5. Pseudolocalization, and what is still hardcoded

**Pseudolocalization:**

- It is Godot's built-in one, with expansion 0.3, `[` and `]`, and accents and doubled vowels off.
  Accents would break the `E:` token and `{name}`, as the research found.
- It is switched on for the whole game at runtime (`TranslationServer.pseudolocalization_enabled`). The
  `pseudo` stills and `i18n_test` use it.
- In the pseudo frames, every visible Label and Button went through translation except the language
  name "English", which is never translated by design. 0 untranslated (`stills/audit-*.json`).
- The knockdown card keeps the engineer's name: `[_________The relief vent let go under Rowan.`

**Hardcoded: player-facing strings that are not in the POT** (`tools/i18n_tool.py hardcoded`, using
the strings step's inventory of 650 player-facing strings; `evidence/hardcoded.json`):

- **165 are in the POT and 485 are not.**
- Of the 485, 213 are the changelog, 3 are painted texture text and 8 are engine key names. That leaves
  **261 in code**.

| File | Player strings | In POT | Not in POT |
| --- | --- | --- | --- |
| scripts/main.gd | 285 | 100 | 185 |
| scripts/game_settings.gd | 54 | 12 | 42 |
| scripts/junction_room.gd | 30 | 13 | 17 |
| scripts/m0_state.gd | 8 | 0 | 8 |
| scripts/records_room.gd | 7 | 0 | 7 |
| scripts/bypass_handle.gd | 2 | 0 | 2 |
| scenes/main.tscn | 39 | 39 | 0 |
| scenes/studio_logo.tscn | 1 | 1 | 0 |
| assets/changelog.txt | 213 | 0 | 213 |
| assets/props/corridor-seal-atlas.png (painted) | 3 | 0 | 3 |
| Godot key names (core/os/keyboard.cpp) | 8 | 0 | 8 |

The 485, by kind: changelog 213, narration 47, dialogue 35, hints 34 (Junction and lane hints, not yet
wrapped), settings 27, station labels 26, input names 19, end card 13, prompt tokens 12, refusals 10,
choices 7, restore lines 7, input action names 6, system messages 5, and 3 or fewer each for the rest
(painted text, death cards, opening, engineer names, top cards, speaker tags, pause menu, touch UI,
tutorial and the changelog screen).

### 6. Stills (render.sh, container only, each run under the heavy slot)

- **Runs:** i18n-proto-7 (`--screen 1280x720`, 25 frames, about 1.5 min) and i18n-proto-8
  (`--screen 2400x1080`, 20 frames, touch layout as in the earlier phone captures). Both used
  `--fixed-fps 60`.
- **Driver:** `capture/i18n_capture.gd`. It audits every frame for overflow (`I18n.overflows`, shared
  with the test), tofu (`I18n.missing_glyphs`) and, in pseudo frames, untranslated text.
- **Earlier runs i18n-proto-1 to -6** found the bugs this version fixes:
  - the always-on fallback;
  - a Settings row 240 px wide that covered TEXT SIZE;
  - the list not following the language;
  - overflow that the old check missed.

  They were deleted.
- **Image size:** at 2400x1080 the saved image is **1920x1080** (measured). `project.godot` sets no
  stretch aspect (the default is keep), so the game most likely draws 16:9 between pillarbox bars and
  the image is that area. That is inferred, not measured. The phone frames in
  `how-it-should-play/playthrough` are 2400 px wide, so the aspect has changed since then.

Overflow findings from the audit (designed width from the scene → width the text needs):

| Control | Where | Designed → needed |
| --- | --- | --- |
| Title NEW GAME, es "NUEVA PARTIDA" | 1280 and phone | 186 → 213 px (runs into CONTINUAR; pinned as the one known overflow in `i18n_test`) |
| Title Brand, de "MRDEMONWOLF, INC. PRÄSENTIERT" | 1280 and phone | 280 → 298 px |
| Touch USE showing "CONTINUE", translated as the title's CONTINUE | phone, opening | 155 → 185 (de FORTSETZEN), 173 (es), 188 (ja コンティニュー). Also the wrong meaning: see finding 2. |
| Pseudo (+30%) | 1280 and phone | PAUSE 88 → 100; touch CONTINUE 155 → 195; title NEW GAME 186 → 197; Credit 424 → 529; game title logo 430 → 512 (it should not be translated at all) |

Station plates are not translated yet (that is a decision). Under pseudo, the junction's OVERLOAD
BREAKER and RELIEF VENT plates touch, and the audit does not check neighbours.

Stills index (`stills/<size>/<language>-<frame>.png`; en, es, de, ja and pseudo for every row):

| Frame | Shows | 1280x720 | 2400x1080 window (1920x1080 image) |
| --- | --- | --- | --- |
| title | Title menu: Brand, chapter line, the five buttons, the credit line | `stills/1280x720/*-title.png` | `stills/2400x1080/*-title.png` |
| settings | Settings DISPLAY tab with the LANGUAGE row (the list shows the current language) | `stills/1280x720/*-settings.png` | (not captured) |
| narration | Opening, second box: "The Director thinks WOLF is still in standby." with the 03:17 card and the CONTINUE/PAUSE hint | `stills/1280x720/*-narration.png` | `stills/2400x1080/*-narration.png` (touch) |
| hint | Corridor at the purge display: the location card (MAINTENANCE / LOCKDOWN, CHECK THE BREAKER) and the "E: read the Director's purge display." hint | `stills/1280x720/*-hint.png` | `stills/2400x1080/*-hint.png` (touch: "USE:" instead of the key) |
| knockdown | Service Junction, vent knockdown card with the engineer's name and the RETRY prompt | `stills/1280x720/*-knockdown.png` | `stills/2400x1080/*-knockdown.png` (touch: TAP RETRY) |

Audits: `stills/audit-1280x720.json` and `stills/audit-2400x1080.json`. Each lists every frame's
visible-text count, overflow, tofu and untranslated text. Render logs:
`evidence/logs/render-i18n-proto-{7,8}.log`.

What the stills show (I looked at them, I did not play the game):

- The ja title, hint, narration, settings and knockdown frames draw cleanly with the Noto fallback.
- The es title button overlaps (see the table).
- The de title fits.
- Two ja boxes leave a lone short last row, "た。" and "いる。". This is a per-script row rule for the
  wiring job.
- The key names stay English ("Escape").
- The station plates and the touch prompts (USE, TAP RETRY, RETRY, DEBUG) stay English. Their text is
  untranslated or not wrapped.

### 7. Headless checks

**The new suite, `tests/i18n_test.gd`: pass, 84 checks.** It reuses `tests/support/game_suite.gd` and
covers:

- the resolver and its fallback, and a saved language beating the start-up locale;
- the PO files loading from `project.godot`;
- the title buttons translating (with English kept internally) and fitting, with es NEW GAME as the one
  pinned overflow;
- the language list (every name, never translated, following changes);
- the narration box in es, then redrawn in ja and de, keeping its line break;
- the name card and location card in de, es and ja;
- the hint with the bound key in es and ja;
- the knockdown card with the name inserted in es and ja, its RETRY prompt, and the ja boxes fitting
  two rows;
- the Japanese fallback on only in ja (Roboto line height 21 → 25 → 21);
- glyph coverage;
- pseudolocalization keeping the name.

**Every suite:** `scripts/check-game.sh` with `CHECK_JOBS=2`, under the heavy slot, passed **25 of 25
in 374 s** (`evidence/logs/check-game-results.txt`).

**Copy check:** `scripts/check-copies.py` found no copied code (406 files). I ran it on a scratch-git
commit of the patch plus `tools/` and `capture/`, filed where landing would put them
(`docs/research-2026-10/localization/prototype/`).

## Findings for the wiring job

1. **Keep English as the internal text; translate at the display boundary.** The prototype's three
   patterns cover every surface touched so far, keep the roughly 270 English asserts valid and keep
   saves language-free. That also answers the strings step's point that the save stores the choice's
   English wording. Use `I18n.KEY.tr(CONST)` (or tr() where the text is worked out) at every use site.
2. **Some msgids need msgctxt.** "CONTINUE" is both the title's "continue a save" and the touch button's
   "advance the dialogue". Godot's auto-translate gave the touch button the title's meaning (ja
   コンティニュー). Use `tr(text, context)` for one of them.
3. **Store speaker and words apart.** Inline tags ("DIRECTOR: ...") cannot be extracted as tag-free
   msgids (the `_intro_keys` marker is a stopgap). Speaker names are drawn untranslated for now.
4. **Turn auto-translate off on proper names.** The game-title logo and the hidden actor tags get
   pseudolocalized. Set `auto_translate_mode = DISABLED` on `GameTitle`.
5. **Chain CJK fallbacks per language** (`I18n.use_japanese_fallback`). Never chain them always: it
   grows every Latin line.
6. **Replace substring key tokens with placeholders.** The hint bar replaces `"E:"`, `"HOLD E:"`,
   `"Press E"` and `"press 2"` as substrings. "PAUSE:" itself contains "E:", translators must keep
   English tokens (`HALTEN E:`, `長押し E:`), and the `HOLD E:` toggle replace never matches a
   translation. Use `{use}`-style placeholders filled after `tr()`.
7. **Pin English in the test runs.** `I18n.saved()` follows the start-up locale, so on a machine whose
   OS language is es, de or ja the English-asserting suites would see that language. check-game.sh
   should pass `--language en` or set `internationalization/locale/test`. CI's locale is untested.
8. **`is_node_ready()` is already true inside `_ready`** (measured backtrace). Settings applies the
   language in Main's `_ready`, before the rooms exist, so the refresh handler waits for `junction_room`.
9. **The overflow check must compare against the designed width.** A Control grows to its minimum size,
   so "the text is wider than the control" never fires. `I18n.overflows` compares against the width its
   anchors and offsets give it. Labels built in code with no width are skipped, and the check does not
   compare neighbours.
10. **Still open from research:** per-locale reading speed (the boxes use the same 0.05 s per character
    for ja), per-script row limits (the ja orphan rows), the English key names
    (`DisplayServer.keyboard_get_label_from_physical`), the painted atlas text, the changelog,
    `icudt_godot.dat` in the export templates, and device tests of `.lproj` and Android locales.

## Decisions for Nathanial

- **Where LANGUAGE lives.** The DISPLAY tab is full: the row has 215 px before TEXT SIZE's caption, so
  "Español (Latinoamérica)" is trimmed on the button (the list shows it whole). Options: a new GENERAL
  tab, or a wider layout.
- **The es NEW GAME button.** Wider title buttons, or a shorter word than "NUEVA PARTIDA" (even
  "NUEVO JUEGO" needs 193 of 186 px). The same question applies to the de Brand line and the touch
  USE button.
- **Whether station plates (BREAKER, SAFE POINT, TANK RELEASE) are translated or stay English
  signage.**
- **Glossary words:** breaker (es "interruptor" reads as "switch"), LOCKDOWN (es BLOQUEO), the
  Director's title (ja 所長), and German word order around key prompts.
- **Japanese line breaking:** whether CJK boxes get a shorter row limit, or a balanced two-row split,
  to avoid lone last rows.

## Files

- `PROTOTYPE.md`: this file.
- `evidence/game.patch`: the whole game change, binary font included. Apply it to origin/main 1cf8d73
  with `git apply`. It holds `scripts/i18n.gd`, `tests/i18n_test.gd`, `i18n/{es,de,ja}.po`, the Noto
  subset and its OFL, and edits to `main.gd`, `game_settings.gd`, `junction_room.gd`,
  `dialogue_boxes.gd`, `project.godot` and `assets/manifest.json` (provenance entry).
- `evidence/messages.pot`: the generated POT.
- `evidence/po_check.json`: the gates on the final PO files.
- `evidence/po_check_negative_control.json`: the gates on the broken copy.
- `evidence/hardcoded.json`: the strings missing from the POT, by file and line.
- `evidence/codex/`: both Codex prompts and their JSON event streams.
- `evidence/logs/`: the POT run, the i18n_test log, all suite results and the two render logs.
- `translations/claude.json`: the source translations, with context and revision notes.
- `translations/codex_back.json`: the back-translations, with session ids.
- `tools/i18n_tool.py`: `potfiles`, `subset`, `fill`, `backprompt`, `check` and `hardcoded`. It imports
  `../pipeline/tools/trial.py` for the pipeline step's measures.
- `tools/extract_pot.sh` and `tools/pot_addon/`: extraction.
- `tools/heavy.sh`: runs one command under the shared heavy slot.
- `capture/i18n_capture.gd`: the render driver.
- `stills/`: the two audits (the 45 PNGs stayed in the session scratch; a few key stills are filed with the Russian run).

Reproduce, from a scratch export of main with the patch applied (ROOT holds `apps/game`):

```sh
bash tools/heavy.sh bash tools/extract_pot.sh ROOT evidence/messages.pot LOGS
python3 -I tools/i18n_tool.py fill evidence/messages.pot translations/claude.json ROOT/apps/game/i18n
python3 -I tools/i18n_tool.py backprompt ROOT/apps/game/i18n PROMPT   # then: codex exec --sandbox read-only - < PROMPT
python3 -I tools/i18n_tool.py check evidence/messages.pot ROOT/apps/game/i18n translations/codex_back.json OUT.json
python3 -I tools/i18n_tool.py hardcoded evidence/messages.pot ../strings-inventory.json OUT.json
(cd ROOT && bash scripts/check-game.sh --suite i18n_test LOGS WORK)
(cd ROOT && bash tools/heavy.sh bash tools/render/render.sh --screen 1280x720 --name i18n-proto-N --driver capture apps/game OUT -- --fixed-fps 60 --script res://review_capture/i18n_capture.gd -- --size=1280x720)
```

## Runs, sessions and sources

- **Heavy runs (all under `dedupe/heavy.sh`, released after each):**
  - 2 import and POT runs;
  - 2 full check-game runs (the first found the fallback bug);
  - 8 render runs, i18n-proto-1 to -8. One loop attempt failed before rendering because zsh did not
    split its arguments; it created no cache.
- **No windows were opened.**
  - Godot ran only headless with isolated HOMEs, or in the render container.
  - The Apple Translation probe was not used.
- **Codex sessions (ChatGPT subscription, both archived):**
  - `01a143f0-8b81-7703-972f-13e21953fd61`: 102 back-translations.
  - `01a14409-6eb1-7db2-8ef1-f6f3714d953b`: 2 shortened buttons.
- **Sources:**
  - The Godot 4.7.2-stable source paths cited by the research-godot step: `modules/gdscript/editor/
    gdscript_translation_parser_plugin.cpp` (method-name match, no const members),
    `editor/translations/localization_editor.cpp:411-430` (the dialog route) and
    `core/string/translation_server.cpp` (standardize_locale, setup).
  - https://github.com/notofonts/noto-cjk (Sans/SubsetOTF/JP/NotoSansJP-Regular.otf, Sans/LICENSE;
    fetched 2026-10-16; GitHub API for the commit and release dates).
  - The pipeline step's style packet, glossary and trial measures (chrF: Popović 2015).
  - Everything else is my own measurement in this step: logs and JSON under `evidence/` and `stills/`.

## Deleted after the step

Each item was deleted by its literal path:

- `proto/game`: the scratch export of origin/main, about 681 MB, holding:
  - its `.godot` import;
  - the throwaway local git used for diffs and the copy check;
  - the applied prototype.
- `proto/work`: the one-off patch scripts, test and check logs, the check homes, the Codex working
  folder and raw outputs, and the broken-PO copy. Everything kept from it was copied into `evidence/`
  first.
- `proto/dl`: the downloaded 4.5 MB NotoSansJP-Regular.otf and LICENSE. They are reproducible from the
  URL and the SHA-256 above.
- `proto/tools/__pycache__` and `pipeline/tools/__pycache__`.
- The render caches `~/Library/Caches/wolf-override-render/i18n-proto-1` through `-8`.

The isolated Godot homes were removed by the scripts that made them (extract_pot.sh's trap, and
check-game.sh's own cleanup).

**Moved, not deleted:** the research-godot step's POT plugin is now `tools/pot_addon/`. Its old place
holds `MOVED.txt`, which points here.
