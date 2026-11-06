# Playtest bugs, November 2026

**What this file is for:** the working list of bugs Nathanial found playing the November 6, 2026 builds (Mac app from main `1b9287a`, the same build on his iPhone 14 Pro Max), with the cause as far as it is known and the planned fix. It is temporary: delete it when every bug below is closed. Nathanial's own play notes live in Notion ([Nathanial's play notes](https://app.notion.com/p/410d61481c7b819b9ed4c3364ef3fc5b)); this file is the developer side.

Status words: **Open** (not started), **Cause found** (reproduced and understood), **Fixing** (branch open), **Fixed** (merged, waiting for Nathanial to confirm in play), **Closed** (confirmed by hand).

## B1. iPhone: the game does not fill the screen

- **Status:** Open
- **Seen:** iPhone 14 Pro Max, first launch, November 6. The picture sits in the middle with unused screen on both sides.
- **Cause (confirmed in code):** `apps/game/project.godot` renders a fixed 960×540 canvas with `window/stretch/mode="canvas_items"` and no `window/stretch/aspect` set, so Godot uses its default, `keep`. `keep` letterboxes any screen that is not 16:9. The iPhone 14 Pro Max is 19.5:9, so about 15% of the width is black bars.
- **Fix:**
  1. Set `display/window/stretch/aspect="expand"` so a wider screen shows more of the room instead of bars. The canvas stays 540 px tall; width grows to match the screen.
  2. Anchor the HUD, dialogue box and touch controls to the real viewport edges, and inset them by `DisplayServer.get_display_safe_area()` so nothing sits under the notch or the home bar.
  3. Clamp the camera's horizontal limits to each room's edges so the extra width never shows past the room art.
  4. Make sure a 16:9 Mac window is unchanged (same framing, same positions).
- **How to check:** `tools/render/render.sh` stills at 2778×1284 (14 Pro Max) and 1280×720; a headless test that the HUD stays inside the safe area at both sizes; then Nathanial plays it on the phone.

## B2. Mac: FPS LIMIT, WINDOW SIZE and FULLSCREEN do nothing

- **Status:** Open
- **Seen:** Mac debug build, Settings → DISPLAY, November 6. Changing any of the three has no visible effect. Nathanial confirmed these three; V-SYNC, EDGE SMOOTHING, REDUCED MOTION and TEXT SIZE are not checked yet.
- **What the code does:** `apps/game/scripts/main.gd` `_setup_settings` connects the three controls; `_on_fps_selected` sets `Engine.max_fps`, `_on_resolution_selected` sets `get_window().size`, `_on_fullscreen_toggled` sets `get_window().mode`, and each saves the file. So the controls are wired. Something stops the effect from showing, or the signal never fires.
- **Likely causes, in the order to test:**
  1. **FPS:** V-sync defaults to on (`game_settings.gd` line 131, `vsync` default `true`), and the menu's own note says "V-sync may limit the FPS cap". With v-sync on, a 60 Hz Mac display shows 60 FPS whatever the cap, and the game has no FPS counter, so a change is invisible. If this is it, the fix is a visible FPS readout in the debug tools and a clearer note, not a code fix.
  2. **Window size:** on macOS, Godot ignores `window.size` while the window is in native fullscreen or maximised; and `item_selected` only fires when the choice changes, so re-picking the current size does nothing. Check whether the window was in the green-button fullscreen.
  3. **Fullscreen toggle:** `MODE_FULLSCREEN` on macOS should work; if it does not, check whether `fullscreen_toggle.disabled` is true because `OS.has_feature("ios")` is somehow set, and whether the macOS export's `display/window/size/mode` conflicts.
  4. **Signals lost on re-parent:** `game_settings.gd` line 296 moves `FPSOptions`, `ResolutionOptions` and `FullscreenToggle` into the DISPLAY page. Moving a node keeps its signal connections, but if `configure` runs before `_setup_settings` connects them, or runs twice and rebuilds the controls, the connections are gone. Check the call order.
- **Fix:** reproduce first with a headless test that selects each option and asserts `Engine.max_fps`, the saved config and the window calls; then fix the real cause. Add a small FPS counter to the debug tools so a cap change can be seen.
- **How to check:** the new headless test, then Nathanial changes all three on the Mac and sees each one take effect.

## B3. Mac: the DISPLAY tab's layout is uneven

- **Status:** Cause found
- **Seen:** Mac debug build at 1280×720, November 6. EDGE SMOOTHING's label sits above its dropdown while every other row is label-left and control-right, and TEXT SIZE is pushed to the right edge.
- **Cause (confirmed in code):** `game_settings.gd` line 310 places the EDGE SMOOTHING label at (410, 77) and its dropdown at (410, 111), stacked, because the right column is only 270 px wide. The left column's rows (`FPSLabel`, `FPSOptions`, …) use label-left positions set by hand at lines 298-302. The two columns were laid out separately and do not share a row helper.
- **Fix:** one shared row layout for both columns (label left, control right, same row height), used by every DISPLAY row, so EDGE SMOOTHING and TEXT SIZE line up with the rest; or move TEXT SIZE to the left column under FULLSCREEN and give the right column the same label-left rule. Delete the hand-set positions once the helper places them.
- **How to check:** a rendered still of the DISPLAY tab at 1280×720 and 960×540; the existing settings UI test still passes.

## B5. Menus: font sizes and heading levels don't flow

- **Status:** Cause found
- **Seen:** Mac debug build, Settings, November 6. The text has no clear order: the title is big, then the tabs, row labels, control text, the note and the BACK button all look the same size, and the breadcrumb is tiny. The eye has nowhere to go.
- **Cause (confirmed in code):** there is no type scale. `game_settings.gd` sets sizes by hand per label: 27 (title), 13 (breadcrumb), 15, 16 and 17 for everything else; `main.gd` and the end card use 15, 16, 17 and 19; the theme's `default_font_size` is 16. Six nearby sizes with no rule, so there is effectively one heading level (H1) and then flat body text.
- **Fix:**
  1. One shared type scale in one file, named by role, not by number: H1 (screen title), H2 (section or tab), H3 (row label), body (control text, dialogue), caption (breadcrumb, notes, hints). Pick sizes with a clear step between levels (for example 32 / 22 / 18 / 16 / 13 at the 960×540 canvas) and weight or colour per level, so every level is visibly different from its neighbours.
  2. Every menu label, tab, row label, note and button reads its size from that scale; delete the hand-set numbers in `game_settings.gd`, `main.gd` and `ui_label.gd` callers.
  3. The TEXT SIZE setting multiplies the whole scale, so the order survives at 125% and 150%.
  4. Apply to Settings first (the page Nathanial saw), then the title, pause, end card and debug menu.
- **How to check:** rendered stills of each menu at 100% and 150% text size; a headless test that every menu label's size is one of the scale's values; then Nathanial reads them.

## B4. Mac: Settings tabs may not switch sections

- **Status:** Open, unconfirmed
- **Seen:** Nathanial said "the sections don't work" on November 6; later narrowed to the three DISPLAY controls in B2. Whether tapping AUDIO, CONTROLS or GENERAL switches the page is not confirmed either way.
- **Fix:** none until confirmed. Next play session: tap each tab and note whether the page changes.
