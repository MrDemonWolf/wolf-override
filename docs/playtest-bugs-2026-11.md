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

## B6. Desktop: buttons feel too big

- **Status:** Cause found
- **Seen:** Mac debug build, Settings, November 6. Toggles, dropdowns, tabs and BACK are large for a mouse; the menu looks like a phone screen on a desktop.
- **Cause (confirmed in code):** every control uses one size for finger and pointer. `game_settings.gd` sets rows and controls at 40 to 48 canvas px tall (lines 306, 310, 323, 361, 373, 537) and 206 to 272 px wide; that is the 44 px touch minimum. The 960×540 canvas is scaled ×1.33 at the default 1280×720 window, so a toggle is 58 to 64 screen px tall on a Mac, and ×2 at 1920×1080.
- **Fix:**
  1. Two control sizes in the shared row layout from B3: **pointer** (about 32 canvas px tall, narrower widths) and **touch** (the current 44 to 48). Pick by the last input used (`DisplayServer.is_touchscreen_available()` and the last event class), the same way the HUD already picks keyboard, controller or touch prompts.
  2. Tabs, BACK and binding buttons use the same two sizes.
  3. Keep the touch size on iOS and Android, so B1's phone fix and this never fight.
- **How to check:** rendered stills of Settings at 1280×720 with pointer sizing and at the iPhone size with touch sizing; a headless test that each control's height matches the mode; then Nathanial opens Settings on both.

## B7. Title: CREDITS shows an outline when nothing is happening

- **Status:** Cause found
- **Seen:** Mac debug build, title screen, November 6. The CREDITS button has a bright outline with no mouse over it and no key pressed.
- **Cause (confirmed in code):** it is the keyboard focus ring (`Button_focus` style in `game_theme.tres`). `main.gd` line 1135 focuses the title's first button at start, and line 2083 focuses CREDITS when you close the credits. `_grab_menu_focus` (line 2330) only releases focus for touch; with a mouse on a desktop it always calls `grab_focus()`, so the ring stays drawn after a click, which is why CREDITS keeps it once you have been in and out of Credits.
- **Fix:**
  1. Show the focus ring only while the last input was a keyboard or controller. Track the last input class in one place (the HUD already does this for prompts) and on a mouse click or move, release focus or swap the focus style for an invisible one; on the first key or stick press, restore focus to `title_focus_return` and draw the ring.
  2. Keep focus logic for keyboard and controller users exactly as it is; they need the ring.
- **How to check:** rendered stills of the title after a mouse click on BACK (no ring) and after a key press (ring on the right button); the existing menu navigation test still passes; Nathanial opens and closes Credits with the mouse.

## B8. Title: the main menu has no motion

- **Status:** Cause found
- **Seen:** Mac debug build, November 6. After the first fade the title screen is still; it feels like a static image.
- **Cause (confirmed in code):** `main.gd` lines 1136-1142 fade the mark, line and title in once (0.4 s, 0.25 s, 0.35 s) and that is all. Buttons only move on hover, focus and press (`UIMotion`). Nothing idles.
- **Fix:** add quiet idle motion that reads as a living terminal, not a loop you notice: the logo mark breathing or its cyan eye blinking on a long irregular timer, the title line's scan sweep, slow drift or flicker in the background art, and a short staggered rise of the buttons after the title fade. One shared idle helper so the pause menu and end card can reuse it. Everything respects the REDUCED MOTION setting (off means the current still screen).
- **How to check:** a short rendered capture of the title (a few seconds of frames) showing the motion, with and without reduced motion; the headless opening timing test still passes; Nathanial watches the title for 30 seconds.

## B9. Audio: a background sound plays all the time

- **Status:** Cause found
- **Seen:** Mac debug build, November 6. Something keeps sounding in the background the whole time, with nothing happening. Nathanial asked whether it is an alert and suggested flashing lockdown lights instead, as real facilities do.
- **Cause (confirmed in code):** rooms carry "state" sounds that never rest. In the Service Junction, `main.gd` lines 3738-3741 play the pump `hum` loop every frame until the door is blown, and lines 3734-3735 play the three-way steam `hiss` blend whenever the pressure line is building, which is most of the time in that room; both only stop when the room's loops are stopped on exit (`_stop_junction_loops`). In the corridor, the bypass crank fires the generated `klaxon` every 1.1 s (`BYPASS_ALARM_SECONDS`, line 1754). None of them is a true alert: the hum and hiss say "the machine is on", and the klaxon says "the bypass is venting".
- **Fix:**
  1. Lockdown and alerts become light, not sound: the rooms already have lockdown beacons (`set_lockdown_cleared` per room, `main.gd` line 1316) and the intro's red alarm wash. Use them for the alert state, with at most one short stinger when the state changes (lockdown starts, bypass starts venting), not a repeating klaxon.
  2. Machine loops become room tone that rests: the pump hum drops to a low bed with a gap (the pump cycles, it does not run flat), and the steam hiss only plays while the gauge is actually climbing or in warning, silent while it holds. Everything ducks under dialogue.
  3. One rule in `SfxBank` for continuous sounds: a loop needs a reason to be playing (a gauge above a floor, a crank in hand) and stops within a second of the reason ending, so no future room can leave a loop running.
  4. Keep the sounds that are actions: valve turns, the vent burst, the spark, the bolt drop, WOLF's growls.
- **How to check:** a headless test that no loop is playing in the Junction while the line holds and the player stands still for 10 s, and that the corridor crank fires the klaxon at most once per crank; Nathanial plays the corridor and Junction and says whether the room feels alive but quiet.

## B10. Dialogue and prompt boxes need a redesign

- **Status:** Open (design first)
- **Seen:** Mac debug build, Records, November 6. Nathanial: "we definitely need to redo this more." The frame shows the station prompt ("E: read the Director's purge display.") as a thin box stacked over the speech box (ROWAN | "Then we get through maintenance…").
- **What a first-time player sees in that frame:**
  1. Two unrelated things, a control hint and a line of speech, drawn as two flat boxes on top of each other, so they read as one broken panel rather than a world prompt and a person talking.
  2. "E:" is a literal key name in the sentence; it reads like a debug line, and on a controller or phone it is wrong.
  3. "ROWAN" is a name with no face. The box has no portrait, no colour or mark that says who is speaking, and a new player may not know Rowan is the engineer they control.
  4. The speech appears whole and leaves on a timer. There is no reveal, no cue that it is finished, and no sign that a press would advance or skip it.
  5. The box is a wide dark slab with a vertical rule; it does not share the terminal look of the menus or the room's lighting.
- **Cause (confirmed in code):** `dialogue_boxes.gd` splits a message into one-speaker boxes shown for a reading time (`read_seconds`, `reading_cps` per language) with no reveal or advance input; `hud_text.gd` draws the station prompt as its own box; the key prefix is built into the prompt text. The two were built at different times and share no layout, type scale or speaker styling.
- **Fix (design before code; research first, by the project rule):**
  1. Research three or four shipped 2D games with strong one-speaker dialogue (timed and press-to-advance) and note, with numbers, box height, portrait size, reveal speed, advance cue and how the control prompt is kept apart from speech. Record it in Notion; decide with Nathanial.
  2. One dialogue box: speaker mark (small portrait or at least a colour and glyph per speaker: WOLF cyan eye, Rowan amber, Director red), name, text with a reveal at the language's reading speed, press to show all, press again to advance, a small "continue" tick when done, and auto-advance only as an option. Reduced motion shows text at once.
  3. The station prompt leaves the dialogue area: a small pill near the station or at a fixed HUD corner, with the input glyph (key cap, controller button or touch button) from the HUD's existing prompt picker, never a literal "E:".
  4. Both use the B5 type scale and B6 control sizes, and the terminal styling of the menus.
  5. Keep the row limits and CJK balancing that `dialogue_boxes.gd` already does; they are the hard-won part.
- **How to check:** rendered stills of the same Records moment at 1280×720 and the iPhone size, with keyboard, controller and touch prompts; the existing dialogue wrap and reading-time tests still pass; Nathanial plays Records and the corridor and says whether he knows who is talking and what to press.

## B11. Feedback: make things in the world clickable and tappable

- **Status:** Open (feature, design first)
- **Seen:** November 6. Nathanial: "can we make things click and tappable, maybe to give a better gaming experience." On the Mac the mouse does nothing in the world; on the phone play is hold-an-arrow then press USE, which is a keyboard scheme drawn on glass.
- **What the code does (confirmed):** `main.gd` line 2108 uses a mouse click only to pick an answer in a question, and line 2478 only to note that the last input was a mouse. Touch is two hold arrows and a USE button (controls page, "Touch"). Stations, doors, WOLF, the dialogue box and the floor take no click or tap.
- **Fix (design first, research by the project rule; keyboard and controller stay exactly as they are):**
  1. **Tap or click a station, door or WOLF** to walk there and use it: one press does the walk and the interact, with the same engineer-only rules, the same reach and the same refusals as pressing E there. The prompt pill from B10 becomes the thing you tap.
  2. **Tap or click the floor** to walk to that point and stop; the arrows stay for players who prefer them.
  3. **Tap or click the dialogue box** to show the rest of a line and again to advance (B10's press-to-advance, on the box itself).
  4. **Hover and press feedback** on everything tappable: the station's plate brightens on hover (mouse) and dips on press (both), so a player can find what is live by looking. One shared `Tappable` component on stations, doors and WOLF so there is one hit-test and one highlight, not copies per room.
  4a. **Labels are targets too** (Nathanial, November 6: "the labels and such"). A station's name plate (MANUAL BYPASS, VALVE, the record stations), the prompt pill, the HUD's objective line and the dialogue box's speaker name all take a tap or click and do the obvious thing: a plate or pill walks and uses the station, the objective line re-shows the current goal, the speaker name is part of the box's advance area. A label that is drawn in the world (`PropScreen`, the name plates) gets the same `Tappable` hit area as its station, sized to the touch minimum even when the painted plate is small.
  5. **Cranks** keep hold: hold on the station (mouse down or finger down) cranks, the same as holding E.
  6. Research three or four shipped 2D side-view games with tap-to-move or click-to-use (what counts as a hit, how they show reach, how they avoid walk-away misclicks) and record it in Notion before the build.
- **How to check:** a headless test that a tap on each station from across the room walks and uses it with the same outcome as pressing E, including refusals and the engineer-only fallback; rendered stills of the hover and press states; Nathanial plays Records and the Junction on the Mac with the mouse only and on the phone with taps only.

## B12. Corridor: a thin pale-blue bar floats at the door threshold

- **Status:** Open (needs a layer-by-layer render to find)
- **Seen:** Mac debug build, corridor by the SAFE POINT, November 6. With WOLF on the ramp in the open doorway, a thin, hard-edged, pale-blue horizontal bar (about 70 world px long, 2 px tall) sits at floor level just right of his feet, in front of the threshold. It is not attached to anything; it reads as a stray UI line or an unpainted edge. Nathanial: "that bar needs to be fixed as well."
- **What it is not (checked in code):** the HUD's hint and prompt accents (`main.tscn` ContextHint and TutorialPrompt `Accent`) are vertical 3-4 px bars; the corridor `Door/Visual` placeholder is fully transparent; the doorway's `Pool` and `Graze` lights (`door_kit.gd` line 94-95) are soft radial glows, not a hard line.
- **Candidates, in the order to test:** the doorway curb strip `SEAL_FRONT` with its `CorridorSealCurbShade` (`main.gd` lines 1262-1266), whose painted edge could show as a line where the shade ends; the top edge of WOLF's `FloorReflection` strip (a squashed mirrored copy drawn below his feet; its clip edge would move with him); a one-pixel seam between two room plates (`RoomDepth` layers) lit by the door; or a `Line2D` or `ColorRect` left from an earlier door build.
- **Fix:** 1. Reproduce with `tools/render/render.sh` at that spot (WOLF on the ramp, engineer at the SAFE POINT), then hide layers one at a time (door front, curb shade, reflections, each depth plate) until the bar goes, which names the owner. 2. Fix the owner: paint the edge into the plate, clip the reflection to the floor, or delete the leftover node. 3. Add the frame to the corridor's rendered regression so the bar cannot come back unseen.
- **How to check:** the same rendered frame before and after, with no stray edge; Nathanial walks WOLF through the doorway and looks.

## B4. Mac: Settings tabs may not switch sections

- **Status:** Open, unconfirmed
- **Seen:** Nathanial said "the sections don't work" on November 6; later narrowed to the three DISPLAY controls in B2. Whether tapping AUDIO, CONTROLS or GENERAL switches the page is not confirmed either way.
- **Fix:** none until confirmed. Next play session: tap each tab and note whether the page changes.
