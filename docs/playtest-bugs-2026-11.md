# Playtest bugs, November 2026

**What this file is for:** the working list of bugs Nathanial found playing the November 6, 2026 builds (Mac app from main `1b9287a`, the same build on his iPhone 14 Pro Max), with the cause as far as it is known and the planned fix. It is temporary: delete it when every bug below is closed. Nathanial's own play notes live in Notion ([Nathanial's play notes](https://app.notion.com/p/410d61481c7b819b9ed4c3364ef3fc5b)); this file is the developer side.

Status words: **Open** (not started), **Cause found** (reproduced and understood), **Fixing** (branch open), **Fixed** (merged, waiting for Nathanial to confirm in play), **Closed** (confirmed by hand).

## Priority (Nathanial, November 6, 2026; updated November 9)

"The story is good, fine for now. It needs better UI/UX and gameplay." So story work pauses at the current canon; the order of work is:

0. **Groundwork, no visible change:** B26 (one UI token file), B31 (one row-length home), B30 (mockup tuning loop). Why: the mockups and the game then read the same numbers from the start.
1. **Look and feel of the rooms:** B13 (art direction, corridor first), with B12 (stray bar) and B23 (beacons out of view) fixed along the way.
2. **Playing with hands:** B11 (click and tap the world and its labels), B1 (iPhone fills the screen), B14 to B17 (Xbox pad on the ROG Ally, input mode and glyphs, hot-plug, pad rebinding), B33 (USE timing), B34 (camera), B29 (Android edges, with the Android port).
3. **Reading and talking:** B10 (dialogue and prompt redesign), B24 (speaker marks), B5 (type scale), B25 (reduced motion in the UI), B27 (bold text), B9 (loops become lights), B36 (mix by loudness).
4. **Menus:** B18 (settings split by device), B3, B6 (Settings layout and control size), B19 (frame rate), B2 (FPS, size, fullscreen), B7, B8 (title focus ring and idle motion), B20 (quit), B28 (UI sounds), B4 (tabs, once confirmed).
5. **Starting and moving between rooms:** B21 (boot seam), B22 (transitions and resume card), B32 (timing line), B35 (save on interruption). Why a new step: it touches boot, Continue and every door, not dialogue or menus, and needs the device timings first.

Each step ships as one small branch with a Mac and iPhone build for Nathanial to play before the next starts. Controller steps also get a ROG Ally build.

### Decisions (Nathanial, November 9, 2026)

1. **Handheld:** his handheld is the ROG Ally (2023). Call it that everywhere.
2. **Loading:** "better loading screen" means a better boot, door-led room transitions, a Continue resume card, and a loading view only for a slow load (mockup M04). No tips on short loads.
3. **Speakers (recommended, not yet decided):** a name tab, a colour and a small mark (WOLF's cyan eye, Rowan's badge) for now; painted portraits after B13's art rules are in place (B24). The mockups show both so Nathanial can choose by eye.
4. **Phone controls (recommended, not yet decided):** the left move pad plus tapping a station or WOLF to use it, with tap-to-walk as a Settings option. The mockups show both so Nathanial can choose by eye.

## B1. iPhone: the game does not fill the screen

- **Status:** Open
- **Seen:** iPhone 14 Pro Max, first launch, November 6. The picture sits in the middle with unused screen on both sides.
- **Cause (confirmed in code):** `apps/game/project.godot` renders a fixed 960×540 canvas with `window/stretch/mode="canvas_items"` and no `window/stretch/aspect` set, so Godot uses its default, `keep`. `keep` letterboxes any screen that is not 16:9. The iPhone 14 Pro Max is 19.5:9, so about 15% of the width is black bars.
- **Fix:**
  1. Set `display/window/stretch/aspect="expand"` so a wider screen shows more of the room instead of bars. The canvas stays 540 px tall; width grows to match the screen.
  2. Anchor the HUD, dialogue box and touch controls to the real viewport edges, and inset them by `DisplayServer.get_display_safe_area()` so nothing sits under the notch or the home bar.
  3. Clamp the camera's horizontal limits to each room's edges so the extra width never shows past the room art.
  4. Make sure a 16:9 Mac window is unchanged (same framing, same positions).
- **Correction (November 9):** plain `expand` is not enough. It shows past the art on 32:9, breaks the iPad and Steam Deck touch framing, and opens a gap at the far plate's edge on every phone. The plan: `expand` only between 4:3 and 2.4:1 (bars outside that), keep zoom 1.35, raise the camera on taller screens, and fix the far plate's offset (`room_depth.gd` 36-38 assumes a 960 px canvas).
- **How to check:** `tools/render/render.sh` stills at 2796×1290 (14 Pro Max), 2400×1080 (Pixel 8), 2732×2048 (iPad Air 13), 1280×800 (Steam Deck), 1920×1080 (ROG Ally), 2560×1080 (21:9), 5120×1440 (32:9, side bars) and 1280×720; a headless test that the HUD stays inside the safe area at both sizes; then Nathanial plays it on the phone.

## B2. Mac: FPS LIMIT, WINDOW SIZE and FULLSCREEN do nothing

- **Status:** Open
- **Seen:** Mac debug build, Settings → DISPLAY, November 6. Changing any of the three has no visible effect. Nathanial confirmed these three; V-SYNC, EDGE SMOOTHING, REDUCED MOTION and TEXT SIZE are not checked yet.
- **What the code does:** `apps/game/scripts/main.gd` `_setup_settings` connects the three controls; `_on_fps_selected` sets `Engine.max_fps`, `_on_resolution_selected` sets `get_window().size`, `_on_fullscreen_toggled` sets `get_window().mode`, and each saves the file. So the controls are wired. Something stops the effect from showing, or the signal never fires.
- **Likely causes, in the order to test:**
  1. **FPS:** V-sync defaults to on (`game_settings.gd` line 131, `vsync` default `true`), and the menu's own note says "V-sync may limit the FPS cap". With v-sync on, a 60 Hz Mac display shows 60 FPS whatever the cap, and the game has no FPS counter, so a change is invisible. If this is it, the fix is a visible FPS readout in the debug tools and a clearer note, not a code fix.
  2. **Window size:** on macOS, Godot ignores `window.size` while the window is in native fullscreen or maximised; and `item_selected` only fires when the choice changes, so re-picking the current size does nothing. Check whether the window was in the green-button fullscreen.
  3. **Fullscreen toggle:** `MODE_FULLSCREEN` on macOS should work; if it does not, check whether `fullscreen_toggle.disabled` is true because `OS.has_feature("ios")` is somehow set, and whether the macOS export's `display/window/size/mode` conflicts.
  4. ~~**Signals lost on re-parent.**~~ Ruled out (November 9): nothing is re-parented.
- **Main cause for the mouse (found November 9):** the DISPLAY page's `Control` has `mouse_filter` STOP and covers the three controls, so a click never reaches them. V-sync can also hide the FPS cap (cause 1); both can be true.
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
  1. Two control sizes in the shared row layout from B3: **pointer** (about 32 canvas px tall, narrower widths) and **touch** (48 canvas px on the ROG Ally, 58 on the iPhone; corrected November 9, not one 44 px size). Pick by the last input used (`DisplayServer.is_touchscreen_available()` and the last event class), the same way the HUD already picks keyboard, controller or touch prompts.
  2. Tabs, BACK and binding buttons use the same two sizes.
  3. Keep the touch size on iOS and Android, so B1's phone fix and this never fight.
- **How to check:** rendered stills of Settings at 1280×720 with pointer sizing and at the iPhone size with touch sizing; a headless test that each control's height matches the mode; then Nathanial opens Settings on both.

## B7. Title: CREDITS shows an outline when nothing is happening

- **Status:** Cause found
- **Seen:** Mac debug build, title screen, November 6. The CREDITS button has a bright outline with no mouse over it and no key pressed.
- **Cause (confirmed in code):** it is the keyboard focus ring (`Button_focus` style in `game_theme.tres`). `main.gd` line 1135 focuses the title's first button at start, and line 2083 focuses CREDITS when you close the credits. `_grab_menu_focus` (line 2330) only releases focus for touch; with a mouse on a desktop it always calls `grab_focus()`, so the ring stays drawn after a click, which is why CREDITS keeps it once you have been in and out of Credits.
- **Exact cause (November 9):** `_grab_menu_focus` grabs focus on every non-touch menu open, so the ring shows even after a mouse click. Fix it by calling `grab_focus(true)`, which focuses without drawing the ring, for mouse opens.
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

## B13. Art: the rooms read as AI slop, not a real place

- **Status:** Open (art direction, the biggest item on this list)
- **Seen:** Mac debug build, corridor at the COOLANT RELAY, MANUAL BYPASS and SAFE POINT with the Records doorway, November 6. Nathanial: "we definitely need better images and such for this game, not look like AI slop."
- **What a first-time player sees in that frame (the AI tells, named so they can be checked off):**
  1. **Props on a stage, not in a building.** The relay, the bypass wheel and the safe point are three separate kit pieces set on the floor. Nothing mounts them: no bolts, no bracket, no conduit running from the relay's pipe stubs to the wall, no cable from the bypass to anything. The relay's pipes end in the air.
  2. **Floating sans-serif labels.** COOLANT RELAY, MANUAL BYPASS and SAFE POINT hang over each prop in the menu font, like a mock-up's callouts. A real facility paints or rivets a plate on the thing.
  3. **One texture everywhere.** Wall and floor are the same blue-grey with rust streaks repeated at even spacing. There is no reason behind the grime: no drip from a fitting, no scuff where feet go, no clean patch where a sign was.
  4. **No lighting key.** The relay is lit from the front, the doorway from inside, the safe point from its own lamp, and the wall from nowhere. Shadows don't agree, so nothing sits.
  5. **Scale drift.** The relay is as tall as WOLF; the bypass wheel is a hand-sized dial on a post; the safe point is a fridge. Nothing shares a human scale.
  6. **Clean frame, dirty wall.** The doorway's frame and the lit passage are crisp and new while the wall beside them is weathered, which is the look of two generations pasted together.
  7. **The floor is a plane.** No curb where wall meets floor, no drain, no painted lane, no wear; actors stand on a flat gradient (B12's stray bar lives here too).
- **Cause (process, confirmed by the rules in memory and `docs/decisions.md`):** pieces were painted one at a time from prompts, each a "sci-fi prop", then placed. Nobody drew the room first. That is the slop pipeline: paint then arrange, instead of design then paint.
- **Fix (the project's own rule, applied room by room; the corridor first because it is the first thing anyone sees):**
  1. **Blueprint before paint.** For each room, one page: what the room is for, where the walls, floor, ceiling and doors are in world px, what is mounted where and why (conduit runs from relay to wall to bypass; the safe point is a wall-mounted cabinet on a plinth; the door's frame is set into the wall with its own grime), the lighting key (one main source, one fill, and what every lamp does), human scale (door 2.1 m, panels at chest height, WOLF's shoulder at knee height), and the dirt logic (drips below fittings, scuffs at feet, clean where sheltered). Exact shapes, measured, with real industrial reference photos (not game art) cited in Notion.
  2. **Codex only paints the blueprint.** Each piece is painted once as a whole piece (one room background, one prop each) from its exact shape and reference, in Look 2, then cleaned up, and reviewed against a written AI-tell list (floating, melted edges, symmetric grime, text that isn't text, lighting that disagrees). Any tell sends it back.
  3. **Labels become plates.** The floating callouts go; each station gets a painted or riveted plate in the art, and the B10/B11 prompt pill carries the name when you are close.
  4. **One piece in game first.** The relay, repainted and mounted, goes in alone; Nathanial judges it in play before the next piece. Then the bypass, the safe point, the door, the walls, the floor, then Records, then the Junction and the annex.
  5. **Replace, don't add.** Each new piece fully replaces the old one (file, import, manifest entry, references) in the same change, and the manifest records provenance and generation count.
- **How to check:** rendered stills of the corridor before and after at 1280×720, reviewed with the AI-tell list; the manifest and asset register still complete; Nathanial plays the corridor and says whether it looks like a place.

## B4. Mac: Settings tabs may not switch sections

- **Status:** Open, unconfirmed
- **Seen:** Nathanial said "the sections don't work" on November 6; later narrowed to the three DISPLAY controls in B2. Whether tapping AUDIO, CONTROLS or GENERAL switches the page is not confirmed either way.
- **Likely not a bug (November 9):** no page covers the tab bar, so the tabs should take clicks. The "sections don't work" was most likely B2's covered controls.
- **Fix:** none until confirmed. Next play session: tap each tab and note whether the page changes.

## B14. Controller: every screen must work with an Xbox pad (ROG Ally)

- **Status:** Open (spec ready)
- **Why:** Nathanial plays on a ROG Ally (2023), so the pad must reach everything, not only play.
- **Cause (code):** menus were built for mouse and touch first. Pad focus exists on some screens only; `game_settings.gd:864` names pad buttons "BUTTON n".
- **Fix:**
  1. Every screen: D-pad or stick to move, A to choose, B to go back.
  2. Menu pauses; View shows the objective.
  3. LB/RB switch tabs; LT/RT switch pages; the right stick scrolls.
  4. Answer cards, the credits scroll and the name entry all work by pad.
  5. Disabled buttons and touch-only buttons take no focus; the on-screen PAUSE shows for touch only.
  6. The changelog's ONLINE step asks to confirm on a handheld.
- **How to check:** a headless menu walk by pad events, then a device test on the ROG Ally.

## B15. One shared input mode and glyph service

- **Status:** Open
- **Why:** prompts and layouts guess the input in many places and show keyboard text to pad players.
- **Cause (code):** the "touch layout" test is copied about nine times, for example `main.gd:683`, `main.gd:2160`, `game_settings.gd:99` and `debug/debug_menu.gd:427`. Pad buttons show as "BUTTON n" (`game_settings.gd:864`).
- **Fix:**
  1. One `InputMode` service owns the last input class; touch is seen from `InputEventScreenTouch` on any OS.
  2. Pad family from the vendor ID; Xbox glyphs with Menu (not START) and View.
  3. Hide keyboard glyphs and the mouse cursor while a pad is used.
  4. Delete the copies, including the debug menu's, in the same change.
  5. Log the glyph art in the manifest.
- **How to check:** a headless test that feeds key, mouse, pad and touch events and reads the mode and glyphs.

## B16. Controller hot-plug, focus loss and vibration

- **Status:** Open
- **Cause (code):** nothing listens to `Input.joy_connection_changed`; the dead zone lives only in Settings (`game_settings.gd:152`) and does not reach the menus.
- **Fix:**
  1. Pause when the pad disconnects; read pad state at start.
  2. Set `ignore_joypad_on_unfocused_application`.
  3. Stop rumble on pause; one VIBRATION / HAPTICS slider.
  4. One dead-zone source for play and menus.
- **How to check:** a headless test with fake connect and disconnect events; then unplug and replug on the ROG Ally.

## B17. Rebinding on a pad

- **Status:** Open
- **Cause (code):** the rebind capture was built for keys; its note and labels name keys (`game_settings.gd:864`).
- **Fix:**
  1. Cancel a capture from the pad (Menu cancels).
  2. Note text and labels match the device, with glyphs.
  3. On a clash, offer swap or cancel.
  4. Reset needs a hold to confirm.
- **How to check:** a headless rebind test by pad; then rebind on the ROG Ally.

## B18. Settings split by device

- **Status:** Open (spec ready)
- **Why:** one Settings page for Mac, ROG Ally and iPhone fits none of them (B3, B6).
- **Cause (code):** phone detection is copied (`main.gd:683`, `main.gd:2160`, `game_settings.gd:99`, `studio_logo.gd:121`) and there is no handheld profile.
- **Fix:**
  1. Three profiles: desktop, handheld, touch; a DEVICE PROFILE override.
  2. One `classify(facts)` picks the profile; handheld from the model code, the ASUS pad ID 2821:6988 or a Z-series processor.
  3. One one-column row helper with three densities (also B3).
  4. A new ACCESSIBILITY tab; each profile has its own defaults and visible rows.
  5. Settings save per device.
  6. Delete the four copied phone checks.
- **How to check:** a headless test of `classify` with each device's facts; rendered stills of Settings per profile.

## B19. Frame rate that tells the truth, per device

- **Status:** Open
- **Cause (code):** V-sync defaults on (`game_settings.gd:131`) and hides the FPS cap; there is no FPS readout (B2).
- **Fix:**
  1. Desktop: match the display by default; grey the caps while V-sync is on; add SHOW FPS.
  2. Handheld: 30 / 40 / 60 / 120, default 60.
  3. Phone: 30 / 60, plus 120 when the screen refreshes at 119 Hz or more; default 60.
  4. BATTERY SAVER on handheld and phone.
- **How to check:** a headless test of the choices per profile; then SHOW FPS on the Mac and the ROG Ally.

## B20. Quit to desktop

- **Status:** Open
- **Cause (code):** only Android Back from the bare title quits (`main.gd:2412-2429`); Mac, Windows and the ROG Ally have no QUIT button.
- **Fix:**
  1. QUIT on the title and in pause on Mac, Windows and handhelds.
  2. Never on iOS.
  3. Android keeps Back from the bare title.
- **How to check:** a headless test that QUIT shows per platform; then quit on the ROG Ally with the pad.

## B21. Boot seam and launch screen

- **Status:** Open
- **Cause (code):** `project.godot:18` sets `boot_splash/bg_color` to black, but the studio logo's background is navy (`studio_logo.tscn:37`), so the boot shows a seam. The logo skip listens to keys and buttons (`studio_logo.gd:185`), not a stick push.
- **Fix:**
  1. Set `boot_splash/bg_color` to RGB (9, 21, 51); match the iOS launch storyboard.
  2. A stick push also skips the logo.
  3. Measure iPhone time to first frame against 400 ms (`xctrace` App Launch), plus the BOOT line (B32) through `devicectl --console`.
- **How to check:** rendered stills of the first frames; the iPhone timing log.

## B22. Room transitions, resume card and one shared indicator

- **Status:** Open (mockup M04 chosen November 9)
- **Why:** Nathanial asked for a better loading screen. Real loads are tiny (Continue about 1 ms, a room change about 2 ms, headless), so a card would only add waiting.
- **Cause (code):** room changes cut; Continue drops you in with no reminder; the logo's sweep lives only in `studio_logo.gd`.
- **Fix:**
  1. Door-led room fades.
  2. The room name on the first visit.
  3. A Continue resume card.
  4. A loading view only when a load is slow.
  5. Move the logo's sweep into one shared indicator.
  6. The resume and first-visit cards restyle today's top card (`main.gd:632`, `_show_top_card` at `main.gd:5484`); no second card component.
  7. Reduced motion uses a plain cut or short fade.
- **How to check:** rendered captures of a door, the first visit and Continue; B32's timing line shows no added wait beyond the fade.

## B23. Corridor alarm beacons sit above the play view

- **Status:** Open (check with a render first)
- **Cause (code):** the corridor beacons (`room_depth.gd:331`) sit at world y 146-152, just above the play view's top (y 160); in the touch framing none of their glow shows.
- **Fix:** move the beacons, or their glow, down into the view, so B9's lights-not-sound plan can be seen.
- **How to check:** rendered stills at keyboard and touch framing showing the beacon glow.

## B24. Dialogue speaker marks have no art

- **Status:** Open (default decided November 9)
- **Cause (assets):** there is no portrait or bust art; only full-body sprites.
- **Fix:**
  1. Ship the default now: a name tab, the speaker's colour and a small mark (WOLF's cyan eye, Rowan's badge).
  2. Keep a placeholder-portrait variant behind a toggle in the mockup only.
  3. Paint head portraits only after B13's art rules are in place: whole pieces, in the manifest.
- **How to check:** rendered stills of a WOLF line and a Rowan line; Nathanial says whether he knows who is talking.

## B25. Reduced motion misses the UI

- **Status:** Open
- **Cause (code):** `ui_motion.gd` (`_scale_to`, line 34) scales buttons on hover and press, and the pause card slides, whatever REDUCED MOTION says.
- **Fix:** route all UI motion through the shared motion tokens; `UIMotion` reads them and does nothing under reduced motion.
- **How to check:** a headless test that hover and pause make no scale or slide with reduced motion on.

## B26. One UI token file

- **Status:** Open (lands first, no visible change)
- **Cause (code):** three near-identical cyans and four light text colours are written by hand in about 60 places, for example `fx/palette.gd:12`; dead scene font sizes are overridden in code.
- **Fix:**
  1. `apps/game/ui/ui.tokens.json` holds colours, type roles, densities, motion and timing; a `UiTokens` loader reads it.
  2. `scripts/export_ui_tokens.py` generates the theme colours and `default_font_size`; `check-game.sh` fails on drift.
  3. The colour overrides in `main.tscn` and `studio_logo.tscn` become theme type variations; `Palette.CYAN` reads the WOLF token.
  4. Delete the dead values.
- **How to check:** rendered stills before and after are identical, and the regenerated theme is byte-identical.

## B27. Credits and changelog bold may draw at regular weight

- **Status:** Open (confirm with a render)
- **Cause (code):** `RichTextLabel`'s `bold_font` falls back to Roboto 400 with no embolden; `assets/fonts/game_theme.tres` sets no bold face.
- **Fix:** set a bold face in the theme.
- **How to check:** a rendered still of the credits before and after.

## B28. Shared UI sound set

- **Status:** Open
- **Cause (code):** there is no one UI sound set; menus have no confirm, back or focus sounds of their own and no UI volume.
- **Fix:**
  1. Six UI sounds in one set.
  2. Confirm plays on press; focus ticks are rate-limited.
  3. A UI volume slider.
- **How to check:** a headless test that fast focus moves play capped ticks; Nathanial clicks through the menus.

## B29. Android edges (with the Android port)

- **Status:** Open (waits for the Android port)
- **Cause (code):** Back pauses today, so the back-edge swipe fights the left move pad.
- **Fix:**
  1. Keep the back-edge swipe away from the move pad.
  2. Use cutout insets in immersive mode.
  3. Use `screen_get_dpi()` for dp, never `screen_get_scale()`.
  4. Orientation 0 or 4; keep `appCategory="game"`.
- **How to check:** the device log, then play on an Android phone.

## B30. Mockup tuning loop

- **Status:** Open
- **Why:** Nathanial tunes sizes and colours in the mockups; the numbers must flow back into the game, not be retyped.
- **Fix:**
  1. A Tune panel in the mockups, with its state in the URL.
  2. Copy JSON gives the change as a diff.
  3. `export_ui_tokens.py --apply` writes it to the token file (B26); `--check-css` checks the mockup stylesheet.
  4. The M00 mockup's criteria pass.
- **How to check:** change one value in the Tune panel, apply it, and see the same value in the game's theme.

## B31. One home for the English row length

- **Status:** Open
- **Cause (code):** `dialogue_boxes.gd:26` `MAX_ROW_CHARACTERS = 42` repeats the value in `languages.json`.
- **Fix:** read it from the table and delete the constant.
- **How to check:** the dialogue wrap tests still pass.

## B32. One timing line for boot, Continue and room changes

- **Status:** Open
- **Fix:**
  1. StudioLogo and Main print `BOOT …` and `RESTORE …` lines under `--boot-timing`.
  2. One `tools/` script runs it headless and prints the numbers (never a timed pass or fail).
  3. Delete the scratch probes.
- **How to check:** a headless run; then the iPhone (B21) and the ROG Ally.

## B33. USE timing and forgiveness

- **Status:** Open
- **Cause (code):** USE is read with `Input.is_action_just_pressed(&"interact")` in several branches of `main.gd` (lines 1432-1503), each with its own rules.
- **Fix:**
  1. Pad and key USE act on the press frame, with a test.
  2. World taps act on release.
  3. One "pending USE" owner for the 0.1 s buffer, the 0.1 s coyote time and B11's walk-then-use.
- **How to check:** headless tests for an early press, a late press and a tap from across the room.

## B34. Camera window, look-ahead and screen shake scaling

- **Status:** Open
- **Cause (code):** the camera follows with fixed smoothing (`main.gd:1411-1412`); shake is a fixed 10 px peak (`impact.gd:9`, applied at `impact.gd:104`) with no setting.
- **Fix:**
  1. A ±36 world px dead window, eased look-ahead and turn hysteresis.
  2. A SCREEN SHAKE % setting scales `impact.gd`'s amplitude.
  3. The camera clamp uses the half-view helper from B1.
- **How to check:** a short rendered capture of a walk and a turn; a headless test that 0% shake gives no offset.

## B35. Save on interruption

- **Status:** Open
- **Cause (code):** `main.gd:2406` pauses on `NOTIFICATION_APPLICATION_PAUSED` only when `auto_pause_on_focus_loss` is on, and writes no save or settings there.
- **Fix:**
  1. On `APPLICATION_PAUSED`: pause, then write the pending save and settings.
  2. Resume into the pause menu.
- **How to check:** a headless test that sends the notification; then background the game on the iPhone.

## B36. Mix by loudness

- **Status:** Open
- **Fix:**
  1. A loudness offset per profile: −24 LKFS desktop, −18 LKFS on portable speakers.
  2. A limiter on the Master bus.
  3. Measure a 30-minute capture with a BS.1770 meter.
- **How to check:** the meter reading for each profile; Nathanial plays with headphones and on the ROG Ally's speakers.
