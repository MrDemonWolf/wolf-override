# UI map: main.tscn, settings, pause, motion, theme (read-only, main @ 76d3a50)

This was a read-only pass. Nothing under the repository was changed. All probes ran in a scratch copy at
`scratchpad/lighter/ui-parity/game`, a copy of `apps/game` without `.godot` or `art-source`.

## 1. Baseline facts

| Item | Value |
|---|---|
| `scenes/main.tscn` | 911 lines, 110 nodes. 646 of those lines are UI under `CanvasLayer` (lines 266-911) |
| Runtime UI tree | `CanvasLayer` holds 197 nodes (185 Controls) once `_ready` has run. The whole scene has 435 nodes |
| Inline overrides in main.tscn | 47 `theme_override_font_sizes`, 14 `theme_override_colors`, 5 `theme_override_fonts` |
| UI built in code | Settings (`game_settings.gd` `_build_menu`, lines 125-246), END OF SLICE card (`main.gd` 1878-1938 and 1967-1990), and a runtime Theme for Settings (`apply_theme`, lines 293-315) |
| Theme | `assets/fonts/game_theme.tres` is the project theme (`gui/theme/custom`). Its variations are HudCard, MenuPanel, CardSheen, TitleVeil, TouchButton, TerminalButton, TerminalPanel and TerminalTabBar. It has no Label variations and no font-size variations |
| Fonts | Montserrat-Variable.ttf is 745 KB and Roboto-Variable.ttf is 489 KB. There are three FontVariation wrappers: Roboto 400 (body), Montserrat 600 (controls) and Montserrat 700 (display) |
| Measured (headless, desktop M-series) | instantiate 3-5 ms, `_ready` 82-116 ms, `GameSettings.apply_theme()` 4-6 ms per call, `_refresh_ui()` 48-98 us per frame in play and 193-328 us per frame while a choice is up |

## 2. Duplicated subtrees and patterns

| # | Pattern | Locations | Lines | Proposed component |
|---|---|---|---|---|
| D1 | **Sheen overlay**: a full-rect `Panel` child with `theme_type_variation=CardSheen` and `mouse_filter=2`, the same 9 lines each time | tscn 283 (TopBar), 314 (BottomBar), 617 (CreditsPanel), 685 (ChangelogPanel), 770 (PauseOverlay/Panel). In code: main.gd 1894-1898 (end card) | ~50 | `card_panel.gd` (`class_name CardPanel extends Panel`, `@export var sheen := true`). `_draw()` calls `draw_style_box(get_theme_stylebox("panel","CardSheen"), Rect2(Vector2.ZERO,size))`. Godot runs the script `_draw` after Panel's own stylebox draw, so the layer order matches. This removes 6 nodes |
| D2 | **Accent stripe**: a cyan `ColorRect` on the card's left edge | tscn 292 TopBar (0,0 4x62), 323 BottomBar (1,1 3x80), 364 ContextHint (1,1 3x33, **colour 0.24,0.77,0.90**), 391 TutorialPrompt (1,1 4x64), 779 Pause panel rule (30,89 390x4) | ~43 | Fold into `CardPanel` as `@export accent_color` and `@export accent_rect`, drawn with `draw_rect`. **Geometry and colour differ per card** (inset 0 or 1, width 3 or 4, one off-tone colour). Each instance must keep its exact values to keep the pixels; do not normalise them. main.gd writes `dialogue_accent.color` (l.3063) and `$CanvasLayer/TopBar/Accent.color` (l.3077), and tests read `CanvasLayer/TopBar/Accent` once. Lower-risk option: keep the Accent ColorRects and only do D1 |
| D3 | **Title overlay** (Credits vs Changelog): backdrop ColorRect (0.025,0.045,0.08,0.76), MenuPanel 168,19-792,521 with Sheen, centred display-font title (185,35-775,80, size 28), cyan rule (340,92 280x3), RichTextLabel body (default_color 0.82,0.89,0.94), BACK TO TITLE (189,453-407,502, size 19), plus a second button | tscn 601-667 and 669-745. Code: main.gd `_show_credits`/`_hide_credits` 1104-1115, `_show_changelog`/`_hide_changelog` 566-574, scroll in `_process` 716-720, drag/click handlers 1138-1154, focus branches 1370-1373, back branches 1384-1389 and 1417-1420 | 144 tscn + ~45 gd | `scenes/ui/title_overlay.tscn` with a `TitleOverlay` script: exports `title`, `body_font_size`, `body_rect`, `auto_scroll_speed` (credits 18 px/s, changelog 0 plus held-axis and drag), `action_text`, an optional note, and signals `back_pressed` and `action_pressed`. Two instances keep the root names `CreditsScreen` and `ChangelogScreen`. The fields that differ go in as instance overrides: body offsets 125-425 vs 130-433, font 19 vs 17, action button left 553 vs 433 and size 19 vs 17, and the changelog's extra Note label |
| D4 | **END OF SLICE card** built in code: the same backdrop, MenuPanel, Sheen, display title, cyan rule (280x3), body and button as D3 | main.gd 1878-1938 (`_build_end_card`, `_end_card_label`) and 1967-1990 (recap rows built with 9 property lines each) | ~75 gd | `scenes/ui/end_card.tscn`, authored with the root `EndCard` and child `EndCardContinue`, both named because tests use those paths. Add `end_card_row.tscn` (HBox, topic Label in display font 15 #73DDF5 with min width 82, text Label 17 0.82,0.89,0.94 with min width 560 and autowrap) instanced per recap row. It can share CardPanel (D1). Its backdrop alpha (0.94) and positions differ from D3, so it is a sibling of TitleOverlay rather than an instance of it |
| D5 | **Per-button font sizes** on every Button | 21: NewGame, Continue, Resume, PauseSettings. 19: CreditsBack, CreditsPause, ChangelogBack, TitleButton, end card. 18: Credits, Settings, Changelog, plus Settings' Back (dead, see O2). 17: ChangelogOnline, PauseButton, Choice1, Choice2. 34: Left and Right. 23: Use | 19 nodes | Theme variations in game_theme.tres that set only `font_size` on base Button: `MenuButtonLarge` (21), `MenuButton` (19), `MenuButtonSmall` (18), `TouchArrow` (34, base TouchButton). Same resource, same pixels. This only matters if the theme becomes the single source; the gain is maintainability, not speed |
| D6 | **Muted label tints** repeated as inline colour overrides | 0.69,0.82,0.87 size 13 on three identical station labels (tscn 224-252). 0.59,0.70,0.77 on ContinueNote (15), Credit (16) and ChangelogNote (15). 0.67,0.79,0.85 on PauseHint (16), ReturnWarning (14) and SettingsNote (15). One-offs: Brand 0.61,0.77,0.85 / 18; Subtitle 0.68,0.78,0.85 / 20; ContextHint text 0.76,0.86,0.91 / 14. Body colour 0.82,0.89,0.94 on both RichTextLabels and twice in end-card code | 14 tscn + 3 gd | Label variations: `StationLabel` (colour plus 13), `CaptionLabel` (0.59 tint), `MenuNote` (0.67 tint), and a RichTextLabel variation `MenuBody`. **Do not merge the 0.59, 0.61, 0.67, 0.68 and 0.69 tints.** They look alike but differ in the dump, so merging them would change pixels. Keep the one-offs inline |
| D7 | **Display-font headings** (Montserrat-Bold override plus size) | tscn GameTitle 42, CreditsTitle 28, ChangelogTitle 28, Pause Title 31, Settings Title 31 (code rewrites it to 27). Code: end-card title 32, header 15, recap topics 15, and `game_settings.gd` 139 re-adds the same font | 5 tscn + 4 gd | One `DisplayLabel` variation (base Label, font = Montserrat-Bold.tres). Sizes stay per node or move into `DisplayTitle` (28) and `DisplayCaption` (15) |
| D8 | **Cyan rules**, colour 0.10,0.76,0.92 | TitleLine 388x4, CreditsLine and ChangelogLine 280x3, end-card line 280x3 (code) | ~24 | Part of D3 and D4. `TOP_CARD_ACCENT` (main.gd 55) duplicates the 0.22,0.78,0.92 accent value already in tscn |
| D9 | **CONTINUE prompt strings** | main.gd 2943, 2991, 2998. 12 `settings_menu.prompt(` calls and 6 `touch_enabled and not controller_active` expressions | ~10 | `_continue_prompt()` and `_touch_layout()` helpers (code-only, no UI change) |
| D10 | **Touch buttons**: Left and Right identical except position and glyph; Choice1 and Choice2 identical | tscn 425-469 | 45 | **Do not make this a component.** Five buttons is too few to pay for a scene. The choice buttons' position, size and font size are re-set every frame by `_refresh_ui` (2956-2961), so their tscn values are only initial. At most add a `TouchArrow` variation (D5) |

## 3. Overrides that duplicate the theme or are dead

- **O1 No-op overrides (equal to `default_font_size = 16`)**: `TitleScreen/Credit` (tscn 598) and `PauseMenu/PauseHint` (822). Removing them leaves the pixels unchanged.
- **O2 Settings values overwritten on the first frame** (`_build_menu` and `apply_theme`):
  - FPSLabel and ResolutionLabel size 19, rewritten to 16.
  - FPSOptions, ResolutionOptions and FullscreenToggle size 18, rewritten to 16.
  - BackButton size 18, rewritten to 16. Its position and size (336-378) are rewritten to (32,414 180x38).
  - Title: the font override duplicates `HEADING_FONT`, size 31 becomes 27 and y 29 becomes 35.
  - The FPS, Resolution and Fullscreen offsets are all rewritten (`game_settings.gd` 156-160).
  - SettingsNote position and size are rewritten (237-239).
  - About 25 tscn property lines are dead. `apply_theme` 311-315 exists only to undo them. If the tscn overrides go, the local theme's Button/OptionButton/CheckButton size 16 already covers these controls.
- **O3 Pause panel geometry**: `Panel` offsets 255,78-705,467 and `PauseMenu` 450x389 are always replaced before the panel is shown (`_show_pause_menu` 1312-1314, `_show_settings` 1270-1271). SettingsMenu's 760x464 is the panel size from `_show_settings`.
- **O4 Per-frame layout writes**: Choice1 and Choice2 position, size and font size (2956-2961) and ContextHint position and size (3067-3069) are re-set every frame. `TopBar/Accent` colour is set per card.
- **O5 Runtime-built Settings theme**: `apply_theme()` copies the Terminal styleboxes into a new Theme each launch. It costs 4-6 ms because assigning the theme re-propagates through about 60 controls. A `settings_theme.tres` assigned in the scene gives the same styles with no second propagation pass. The Terminal styleboxes must then move out of game_theme.tres into that file or into external `.tres` files. Only `game_settings.gd` uses them, at 130, 142, 302 and 306.
- **O6 Dead nodes**: `Human/Tag` (tscn 109-116) and `Wolf/Tag` (134-141) are always `visible=false`. Wolf/Tag is never referenced. Human/Tag only gets `.text` written every frame (main.gd 3008, `@onready` 222). No test references either one. Remove both nodes and the two gd lines.

## 4. Which pieces become instanced scenes

Ordered by value. Every proposal keeps the current look.

1. **Hot-path fixes first (no scene change).** In `_set_dialogue`, guard `speaker.add_theme_color_override` (main.gd 3064) and the two choice font-size overrides (2960-2961) with a check of the current value. **Measured:** every repeat call fires NOTIFICATION_THEME_CHANGED (100 of 100 calls in the probe), and 10,000 Button font-size overrides cost 295 ms against 12 ms for same-text sets. In the scratch copy, the guard cut `_refresh_ui` from 48-98 us to 25-39 us in play and from 193-328 us to 35-53 us with a choice up. That is the only UI change here with a measurable frame-time effect, and it matters most on phones.
2. **CardPanel script** (D1, optionally D2). It removes 6 Sheen nodes, or up to 11 with the accents. It touches no theme values.
3. **TitleOverlay scene** (D3), replacing about 144 duplicated tscn lines and four mirrored code branches.
4. **EndCard scene plus EndCardRow** (D4). It replaces about 75 lines of imperative builder code. It can also load lazily on first `_show_end_card`; if so, run `UIMotion.attach` on its button at that point, because the `_ready` scan (main.gd 441-442) only sees buttons that exist at startup.
5. **Theme variations** (D5-D7, O1, O2). They take about 40 of the 66 inline overrides out of main.tscn without new nodes.
6. **Settings as an authored scene** (`settings_menu.tscn` with GameSettings logic kept, plus `settings_theme.tres`, O5). The static parts of `_build_menu` (subtitle, surface, tabs, three page containers, vsync, AA and reduced-motion controls, GPU label, cancel button) move to the scene. Binding rows and slider rows stay generated, or become `binding_row.tscn` and `slider_row.tscn`. Expect lines to **move** rather than shrink. The wins are one source of layout truth (O2), no runtime Theme build, and an editor-visible layout.

Not recommended: a component for title buttons (theme variations cover them), touch controls (D10), the HUD bottom bar (unique Speaker/Rule/Story layout), or `pause_overlay.gd` (23 lines). Two small cleanups there: cache `Panel/SettingsMenu` with `@onready` instead of calling `get_node_or_null` on every input event, and in `ui_motion.gd` `_scale_to` skip creating a Tween when `scale == target` and no tween is running. The 23 to 45-line scripts are already shared components and should be kept.

**Path compatibility.** Tests use 41 unique `CanvasLayer/...` paths (impact, sentry, chapter_scene, ui_controls, m0_scene, junction and settings tests), and main.gd has about 50 `@onready` paths.
- An instance keeps old paths only if its root has the old name and its internal children have the old names. Children inside an instanced scene cannot be renamed per instance.
- TitleOverlay therefore needs generic child names (`BackButton`, `ActionButton`, `Body`). That breaks `CreditsScreen/CreditsBackButton` and `CreditsPauseButton` in tests (1 reference each) and about 8 `@onready` lines. Update them in the same change, or expose them as properties on the overlay script.
- EndCard must keep `EndCard/EndCardContinue` (sentry_test 436-437, ui_controls_test 264-265).
- Do not move `TopBar/HUD`, `ContextHint/Text`, `TutorialPrompt/Text`, `BottomBar/Speaker|Story`, `PauseOverlay/Panel/PauseMenu/*` or `PauseOverlay/Panel/SettingsMenu/{BackButton,FPSOptions,ResolutionOptions}`.

## 5. How parity is proven

**A. Resolved-property dump (built and baselined).**
- Script: `scratchpad/lighter/ui-parity/ui_dump.gd` (copy to `res://parity/` in a scratch project).
- It drives main.tscn through 14 states: title, credits, changelog, settings tabs 0-2, intro, keyboard and touch play, touch and keyboard choices, pause, and the end card. It waits out tweens on a real-time timer.
- For every visible Control it records: path, class, global rect (including UIMotion lift), alpha, ColorRect colour, theme-resolved font file, weight and size, font colour, alignment, text, and button, panel and tab stylebox parameters.
- Baseline: `scratchpad/lighter/ui-parity/baseline-76d3a50.txt` (389 lines). It is **deterministic**: two runs diffed clean.
- After a refactor, rerun and `diff`. Only expected path renames may change; normalise auto-named nodes with `sed 's/@[A-Za-z]*@[0-9]*/@auto/g'` and keep a rename map.
- Extend the dump before using it with CardPanel: record CardPanel's `sheen` and accent fields under the old Sheen and Accent lines so removed nodes still compare.

**B. Pixel diff (not run: it needs a window).**
- Use the existing `scratchpad/capture-scripts/capture.gd` pattern with the normal GL Compatibility renderer, not headless.
- Capture the same 14 states before and after at 960x540, at 1280x720 and at one phone aspect.
- Settings: reduced motion on, credits scroll paused at 0, same focus target.
- Run `magick compare -metric AE before.png after.png diff.png` and expect 0 differing pixels.
- Fonts and styleboxes are deterministic, so a non-zero count is a real change.

**C. Existing suites.** Run `scripts/check-game.sh`. ui_controls_test already asserts that theme focus-ring identity and title/pause button style identity hold, plus choice sizes 40 and 76. m0_scene_test asserts that HUD, tutorial and continue-note text fits its box.

**D. Hands-on (AGENTS.md).** Play title → credits → changelog → settings, pause, a choice and the end card on desktop and in a touch layout before claiming "looks the same". Headless dump, rendered stills and play are separate claims.

## 6. Font weight (lighter build, optional, asset change)

- The two variable TTFs total 1.23 MB. The docs site already ships Latin subsets of about 36 KB each (`apps/docs/app/fonts/*.woff2`).
- A game subset must keep the glyphs the UI uses. Montserrat has ◀ ▶ × − — ’. Roboto lacks ◀ and ▶; those appear only on TouchButton text, which uses Montserrat.
- Subset only to the weights in use: Roboto 400, Montserrat 600 and 700.
- Neither OFL file declares a Reserved Font Name, so a subset may keep its name.
- This needs manifest entries and a glyph-coverage check against every UI string. Coordinate it with the asset-replacement ask.

## 7. Risks

- **Theme lookup order.** Godot checks the nearest owner theme for all of a control's types before it reaches the project theme. Inside SettingsMenu, the local theme's plain `Button` entries win over any project-theme variation. Font-size variations from D5 would be ignored there unless they also go into the settings theme.
- **Merging near-identical colours** (D2, D6) changes pixels. Preserve each value exactly.
- **Credits text.** The BBCode credits body (tscn 651, including the Nathanial Henniges credit) must move verbatim if D3 is done.
- **UIMotion on lazy scenes.** Lazily instanced UI is missed by the `_ready` UIMotion scan.
- **Overlay hiding logic.** `_show_title_overlay` / `_hide_title_overlay` hide every TitleScreen child except the art and the two overlays, matched by identity. New title children must follow that rule.
- **Merge conflicts.** Branch `codex/logic-round-3` (wt-r3) is editing main.gd (junction staging and hatch). The `_refresh_ui` and `_set_dialogue` edits will conflict with it, so land them after that merge.
- **Scale of the win.** Removing about 13 nodes is about 6% of the 197 UI nodes and has no measurable frame cost. The speed gain is item 4.1 (guarded overrides). The rest is mainly about size and maintainability.
