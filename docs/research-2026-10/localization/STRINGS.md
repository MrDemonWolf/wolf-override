# What there is to translate

An inventory of every string a player can read in WOLF//OVERRIDE at `main` 1cf8d73 (October 16,
2026). Every branch merged before it was taken (lighter-1, p0-text, corridor-additions and doors, PRs
#75, #76, #78 and #79). The in-flight `codex/opening-dock` branch is not in it. That branch reflows
`INTRO_LINES` and changes one hint condition, so it adds no new kind of text, but every `main.gd` line
number below will move when it merges.

**The data:** [`strings-inventory.json`](strings-inventory.json) has 980 entries, one per string
occurrence. Each entry gives:
- `path` and `line`;
- `class`;
- `text`;
- `dynamic` and `inserts`: whether it is built at run time, and from what;
- `gender_risk`, `gender_langs` and `gender_note`: whether a gendered language needs the engineer's
  gender;
- `plural`;
- `baked`: `no`, `label` or `pixels`;
- `words`;
- `in_scope` and `shown`;
- `notes`.

**The tools** are in `strings/tools/`, run in this order:
1. `extract_literals.py`: every literal in the scripts and scenes.
2. `candidates.py`: drops the obvious data.
3. `classify.py`: the reviewed classification, written as tables in the file.
4. `test_asserts.py`: the tests that pin English.

`strings/summary.json` and `strings/test_asserts.json` are their outputs. The two large intermediate
files (`literals.json`, 2.8 MB, and `candidates.json`) were not filed: the first two tools rebuild them
from `main` at 1cf8d73.

## How much

| | Strings | Unique | Words |
|---|---|---|---|
| Shown to players, everything | 650 | 613 | 16,362 |
| The in-game changelog alone | 213 | 213 | 13,502 (83% of all words) |
| **Everything except the changelog** | **437** | **400** | **2,763** |
| Debug tools (out of scope, listed only) | 328 | | about 980 |
| On hidden labels | 2 | | |

Without the changelog, the words split roughly as:
- story text, about 1,460 words: opening, dialogue, narration, refusals, knockdown cards, end card,
  choices and restore lines;
- hints, objectives, tutorial and top cards, about 640;
- the credits, one BBCode block of 214;
- menus, settings, input names and station labels, the rest.

The public site (`apps/docs`, 22 `.mdx` pages, about 37,700 words) is a separate job and is not counted
here (decision D6).

**By class (shown strings / words):**

| Class | Strings | Words | | Class | Strings | Words |
|---|---|---|---|---|---|---|
| changelog | 213 | 13,502 | | title menu | 15 | 52 |
| hints | 75 | 564 | | objectives | 16 | 51 |
| narration | 47 | 533 | | changelog screen | 7 | 45 |
| dialogue | 35 | 463 | | system messages | 6 | 41 |
| credits | 1 | 214 | | choices | 7 | 36 |
| settings | 53 | 183 | | pause menu | 11 | 35 |
| end card | 15 | 103 | | tutorial | 8 | 27 |
| refusals | 10 | 91 | | prompt tokens | 12 | 24 |
| knockdown (death) cards | 10 | 85 | | input names | 19 | 22 |
| restore lines | 7 | 80 | | top cards | 6 | 18 |
| opening | 7 | 70 | | credits screen | 7 | 14 |
| station labels | 37 | 68 | | input action names, touch buttons, engineer names, painted text, speaker tags, studio logo, window title, HUD button | 1-7 each | 1-11 each |

## The hard cases

**Built at run time: 101 of the 437.**

| Insert | Strings |
|---|---|
| A key or button name | 35 |
| The engineer's first name (`{name}` on the end card; `%s` on knockdown cards and in narration) | 20 |
| The upper-case first name as a speaker tag (`'%s: That door is our way through.'`) | 6 |
| The full name in upper case (the name card, `'%s\nMAINTENANCE ENGINEER'`) | 1 |
| Numbers | 16 |
| Joined with `+` (`WOLF_DOOR_WARNING`, `checkpoint_callback()`) | 2 |

Choice texts are also put inside ASCII quotes (`'%s\n1  "%s"\n2  "%s"'`).

**Code that matches the English text.** Each of these breaks once the text is translated, or needs a
fixed token:
- 27 hints start with `E:` or `HOLD E:`, or contain `Press E` or `press 2`. `_refresh_ui` and
  `_shown_line` find these English tokens and put the bound key in their place. The prototype found
  that `PAUSE:` also contains `E:`.
- 34 lines carry the speaker inline (`WOLF: ...`, `DIRECTOR / PURGE: ...`):
  - `DialogueBoxes.tag_of` splits at `TAG: `.
  - `box_seconds` treats any upper-case text before `: ` as a tag. CJK has no case.
  - French puts a space before the colon.
- The speaker's colour is chosen by comparing text: `name == "WOLF"` and `begins_with("DIRECTOR")`.
- End-card rows split at the first double space into a topic and its text.
- `DialogueBoxes` counts words by spaces, caps rows at 42 characters and breaks sentences only at
  `.`, `!` or `?` followed by a space. It knows only ASCII quotes.
- 45 lines have hand-placed `\n` breaks sized for English.

**The engineer's gender: 26 lines, plus 44 changelog lines.** The engineer is non-binary and uses
they/them (`docs/decisions.md` S1-03). WOLF is he/his, so his own lines carry no risk.

How many of the 26 lines each language is affected by:

| Language | Lines |
|---|---|
| pl, ru, uk | all 26 |
| es, fr, it, pt | 2 |
| de | 1 |

The causes:
1. **Past tense with the engineer as subject.** The verb shows gender in pl, ru and uk:
   `BYPASS_RELEASED_LINE` and six end-card recap rows. One recap row ("timed the drop alone") also
   shows gender in es, fr, it and pt, through "solo/sola", "seul/seule" and the like.
2. **WOLF speaking to the engineer in the past tense** ("you told me", in pl, ru and uk):
   `BAIT_YES_LINE`, `BAIT_NO_LINE`, "Thank you for telling me", two remembered lines and the three
   checkpoint callbacks.
3. **The name as an object.** In pl, ru and uk it takes a case ending, and how it declines depends on
   the name's gender. This hits all five knockdown cards, the sentry lock and lost lines, and
   `RUBBLE_LINE`.
4. **"Crank it yourself".** "yourself" becomes сам/сама or sam/sama.
5. **The name card's "MAINTENANCE ENGINEER".** A gendered noun in all 8 of these languages.
6. **The changelog.** 44 lines say "the engineer" and use they/their.

The style rules that answer each cause are in PIPELINE.md, and the open choice is decision D9.
Polish formal address (Pan/Pani) is gendered too, so WOLF uses informal address.

**Plurals: only 2 strings.**
- "HOLD E: crank the valve, %d of %d turns."
- "The valve gives. %d of %d turns."

The total is fixed at `PressureLine.TURNS_NEEDED = 3`. The other counters have no counted noun.

**Formats:**
- Percentages need locale spacing (fr and de write "100 %").
- Changelog dates are US format ("October 16, 2026").
- "03:17" is a clock time.

**Text painted into textures: 3 phrases, all in `assets/props/corridor-seal-atlas.png`.**

| Phrase | Where it is painted | Atlas position (px, approximate) |
|---|---|---|
| DOOR 4B-07 | hood stencil | x 60-260, y 55-130 |
| SECTOR 4B | wall stencil | x 760-855, y 80-110 |
| RESTRICTED AREA | plate | x 765-880, y 160-195 |

- The manifest says the door tools typeset all three in Roboto, so they can be typeset again per
  language.
- Every other room image, prop and atlas was checked by eye: no readable text.
- Every station plate is a live Label, not pixels. So is "MrDemonWolf, Inc." on the studio logo.
- The fate of the painted phrases is decision D3.

**The save stores English.** The save keeps the wording of the choice the player saw
(`m0_state.gd` memory `selected_text`), and WOLF quotes it back from the save. The prototype's design
answers this by keeping English as the internal text and translating at display time. A saved choice
is then the English msgid, which WOLF's line translates when it is drawn. No save change is needed,
and old saves keep working (DESIGN.md). The prototype has not run this case yet: the callback lines
are among the 261 still to be marked.

**Settings show internal ids:**
- The volume rows are "`%s` volume" with the AudioServer bus names Master, Music, Effects and Voice.
- The rebind prompt inserts the id `keyboard` or `controller`.
- An action with no display name shows its id with `_` turned into a space.

**Key names are English.** `GameSettings.prompt()` uses `OS.get_keycode_string(physical_keycode)`.
- It always returns English names ("Escape", "Left"; Godot `core/os/keyboard.cpp`).
- It uses US QWERTY labels, so on an AZERTY keyboard the Move-left key shows "A" although the key is
  printed Q.
- `DisplayServer.keyboard_get_label_from_physical` returns the label printed on the key in the active
  layout, on macOS, Windows and Linux.
- The controller labels ("D-pad left", "BUTTON %d") are hard-coded English.

**Layout:**
- Most menu controls have fixed pixel sizes: the end-card button is 250×52, CANCEL REBIND 180×38,
  the settings columns 220 and 206 px, and the end-card topic column 82 px.
- The name and the speaker tag are upper-cased in code with `to_upper()`, which ignores the locale.
  That matters for the Turkish dotted i.
- The station plates are fitted by `_fit_label` and capped at 150% (`TextSize.world_factor`).

**British spellings in player text:**
- In the game: "off centre" (`TANK_HIT_OFF_CENTRE_LINE`, approved wording) and "Rebind cancelled."
- In the changelog: centre, centred, neighbouring, colour, grey and licence.

Everything else is US spelling. Decision D5.

## Tests that assert English

`test_asserts.py` counted:
- 376 English player-text literals on 302 test lines;
- 132 references to the game's text constants (for example `MainScript.TRUST_LINE_1`).

270 of the 2,148 `_expect` lines use one or both. Most are in `approved_wording_test` (36 lines),
`m0_scene_test` (62), `sentry_test` (50), `junction_test` (38), `chapter_scene_test` (22) and
`text_boxes_test` (20).

The prototype keeps English as the internal text, so all of these keep passing unchanged. The full run
with es, de and ja passed all 25 suites. The full run with Russian added passed the 24 existing suites;
the new `i18n_test` failed on the Russian CONTINUE overflow, and passed when run alone after that
overflow was pinned (prototype/README.md, "Headless checks"). What the existing suites need is the
language pinned to English (DESIGN.md, "Tests").

## How much the prototype already reaches

The prototype's POT has 149 msgids, against 75 that Godot's generator finds on `main`:
- 165 of the 650 shown strings are in it;
- 485 are not;
- of the 485:
  - 213 are the changelog;
  - 3 are painted;
  - 8 are engine key names;
  - **261 are in code**: 185 in `main.gd`, 42 in `game_settings.gd`, 17 in `junction_room.gd`, 8 in
    `m0_state.gd`, 7 in `records_room.gd` and 2 in `bypass_handle.gd`.

The list, file by file, is in `prototype/evidence/hardcoded.json`. Those 261 are what the wiring PRs
in PLAN.md mark.

## Credits

- The inventory and its tools were made by Claude (Claude Code) for Nathanial on October 16, 2026, in
  the research-strings step.
- The visual check of the textures used the Read tool on every room plate, prop, title and boot image.
- The Godot facts cite the 4.7.2-stable source:
  - `core/os/keyboard.cpp`;
  - `doc/classes/DisplayServer.xml` (`keyboard_get_label_from_physical`);
  - `doc/classes/OS.xml` (`get_keycode_string`);
  - `doc/classes/ProjectSettings.xml` (`application/config/name_localized`).
