# Mobile play and performance as feel (WOLF//OVERRIDE research topic)

Researcher notes, started 2026-10-12. All URLs accessed 2026-10-12 unless noted. Source ids are [MOBILE-PERFORMANCE-n]; the full list is at the end.
Builds on docs/research-2026-10/design-reference-25-games.md (section 9 "Mobile and input notes" and its listed gap: "touch target sizes, zone layouts and session-length data were not supplied").

## 0. Baseline: what the game does today (read from the repo, 2026-10-12)

- Viewport 960x540, `window/stretch/mode="canvas_items"`, aspect left at Godot's default (`keep`), so a 19.5:9 phone gets pillarbox bars. GL Compatibility renderer on mobile. (`apps/game/project.godot`)
- Touch controls (`apps/game/scenes/main.tscn`): LEFT 96x90 px at x 32, RIGHT 96x90 px at x 142 (14 px gap), USE 155x90 px at x 773 (right edge at 928, 32 px from the edge), all with top at y 345 and bottom at y 435 (105 px above the bottom edge). Touch choices are 428x76 px, font 17 px.
- `touch_enabled` = iOS or Android feature only (`main.gd:307`); camera drops to `GAMEPLAY_CAMERA_Y_TOUCH = 392` when touch buttons show.
- Hold-to-crank: `HoldUse.TICK_SECONDS = 0.4`; bypass is about 3 s held; ticks survive a release (`hold_use.gd`).
- Pause on interruption: `NOTIFICATION_APPLICATION_PAUSED` and `NOTIFICATION_APPLICATION_FOCUS_OUT` call `_pause_game()` (`main.gd:1442-1449`). Android Back walks out of menus.
- Smallest text: world labels 13 px (Breaker/Relay/Checkpoint), context hint 14 px, HUD/speaker 15 px, default theme 16 px.
- Haptics: `impact.gd` vibrates the handheld when the touch layout is active.
- No safe-area code found (`get_display_safe_area` not used).
- Not yet tested on a physical phone (next-session.md, PROJECT_CONTEXT.md).

Scale math used below (derived, not sourced): with `keep`, the 960x540 viewport scales by min(screenW/960, screenH/540). Point sizes for current iPhones are from Apple's spec pages (see sources).

## 1. Platform guidelines: Apple (read from the HIG JSON data behind the pages, 2026-10-12)

### 1.1 Control size and spacing [MOBILE-PERFORMANCE-1] [MOBILE-PERFORMANCE-2] [MOBILE-PERFORMANCE-3]
- HIG Accessibility table: iOS/iPadOS default control size **44x44 pt**, minimum **28x28 pt** (macOS 28/20, tvOS 66/56, visionOS 60/28). Spacing: "about 12 points of padding around elements that include a bezel", "about 24 points of padding" around elements without a bezel. [1]
- HIG Game controls (touch section added June 10, 2024, updated June 9, 2025): "Make sure frequently used controls are a minimum size of 44x44 pt, and less important controls, such as menus, are a minimum size of 28x28 pt". [2]
- HIG Designing for games: "buttons in iOS must be at least 44x44 pt to accommodate touch interaction". [3]
- **For WOLF//OVERRIDE:** LEFT/RIGHT/USE are frequent controls (44 pt floor); pause and menus are secondary (28 pt floor). Today LEFT and RIGHT are 96x90 px with a **14 px** gap. On an iPhone 16 (Apple spec: 2556x1179 px at 460 ppi, so 852x393 pt landscape at 3x [MOBILE-PERFORMANCE-36]) the `keep` scale is min(852/960, 393/540) = 0.728, so they are about **70x66 pt** (pass; about 11.6 x 10.9 mm) but the gap is about **10 pt / 1.7 mm** between two bezelled buttons: under Apple's ~12 pt padding advice (it does pass Android's 8 dp = 1.27 mm). On an iPhone 11 (Apple spec: 1792x828 px at 326 ppi, so 896x414 pt at 2x [MOBILE-PERFORMANCE-37]) the scale is 0.767: 74x69 pt buttons and a 10.7 pt gap. Widen the gap to at least 18 px (about 13 pt at 0.728) or merge LEFT/RIGHT into one wide slide pad (see sec. 8). [Fact-check 2026-10-13] Against Microsoft's XAG 107, whose *suggested minimum default* touch target on phones is 15 x 15 mm [MOBILE-PERFORMANCE-48], today's LEFT/RIGHT (about 11.6 x 10.9 mm) and USE (155x90 px, about 113x66 pt, about 18.7 x 10.9 mm) all fall short in height on an iPhone 16. They pass Apple and Android minimums, not XAG 107.

### 1.2 Touch controls for games [MOBILE-PERFORMANCE-2]
Short quotes and paraphrase from HIG "Game controls > Touch controls":
- Prefer direct interaction to buttons where it fits: "consider letting players tap objects to select them instead of adding a virtual selection button."
- Placement: avoid the Home indicator and Dynamic Island; frequently used buttons near the thumb; "Place secondary controls, like menus, at the top of the screen."
- Press states: "Always include visible and tactile press states" that players "can see even when their finger is covering the control", combined with sound and haptics.
- Labels: use symbols for the action, avoid "controller-based naming like A, X, or R1".
- Hide controls when an action isn't available; consider hiding movement controls until the player touches the screen.
- Combine functions: "touch and hold" for a variant of the same action; combine walk and sprint into one control.
- Movement on the left; "opt to show a virtual thumbstick wherever the player lands their thumb instead of a static thumbstick position."
- **For WOLF//OVERRIDE:** (a) USE should show its press state as a halo/glow wider than the thumb plus a click and a light haptic (impact.gd already has handheld vibration; extend it to every press). (b) USE should show what it will do (a hand, a valve, a door icon, or the target's name), not "USE" alone. (c) Hide USE when nothing is in range rather than showing a dead button; or dim it, never let it vanish mid-hold (see Planet of Lana patch, design reference sec. 9). (d) Walk/jog in one control: thumb distance from the touch-down point = speed (floating pad), matching Apple's "combine walking or sprinting" advice. (e) Pause button top corner, 28 pt or more.

### 1.3 Text size [MOBILE-PERFORMANCE-1] [MOBILE-PERFORMANCE-3]
- iOS/iPadOS default **17 pt**, minimum **11 pt**; macOS 13/10; tvOS 29/23. "Ideally, give people the option to enlarge text by at least 200 percent". Contrast (Apple's table, from WCAG AA): 4.5:1 up to 17 pt, 3:1 at 18 pt and above, 3:1 for bold text at any size. [1]
- Designing for games repeats the same table under "Make sure text is always legible." [3]
- **For WOLF//OVERRIDE (derived):** at scale 0.728 (iPhone 16 landscape) 1 viewport px = 0.728 pt, so 11 pt needs **15.1 px** and 17 pt needs **23.4 px**. At iPhone 11's 0.767: 11 pt needs **14.3 px**, 17 pt needs **22.2 px**. On the iPhone 16 (worst verified case), today's 13 px world labels (9.5 pt), 14 px context hint (10.2 pt) and 15 px HUD/speaker (10.9 pt) are **below Apple's 11 pt minimum on phones**. Dialogue at 16-17 px is about 12 pt: legal but well under the 17 pt default. Recommendation: a phone text scale (e.g. 1.4x for the touch layout, so 17 px dialogue becomes about 24 px = 17 pt) and a player text-size option reaching 200 percent of the default, as Apple asks.

### 1.4 Safe areas, aspect ratios, orientation [MOBILE-PERFORMANCE-3] [MOBILE-PERFORMANCE-4] [MOBILE-PERFORMANCE-5]
- "Games need to look good and behave well at various aspect ratios, such as 16:10, 19.5:9, and 4:3"; rely on platform safe areas for rounded corners and the camera housing. [3]
- Launching: "Ensure a landscape-only interface responds correctly, regardless of whether people enter landscape orientation by rotating the device left or right." [4]
- Layout: respect safe areas so "the Dynamic Island don't obstruct content and controls"; even a landscape-only game must resize well. [5]
- **For WOLF//OVERRIDE:** the current `keep` aspect pillarboxes a 19.5:9 phone (960x540 scaled 0.728 = 699x393 pt inside 852 pt, about 76 pt black bars each side), which happens to keep everything clear of the Dynamic Island and rounded corners (exact landscape safe-area insets per model were not verified here: UNVERIFIED; read them at runtime with `get_display_safe_area()`; the 4.7 class reference says it is "Currently only implemented on Android and iOS" and returns screen pixels, so convert to viewport coordinates). But it wastes about 18 percent of the screen width and leaves controls in the middle instead of under the thumbs at the edge. If the project moves to `expand` (to fill 19.5:9), controls must be placed from `DisplayServer.get_display_safe_area()` and both landscape orientations must work (Godot `sensor_landscape`).

### 1.5 Interruptions and audio [MOBILE-PERFORMANCE-6] [MOBILE-PERFORMANCE-7]
- Full screen: "a game or a slideshow needs to pause automatically when people leave the experience so they don't miss anything." [6]
- Audio: silent mode should silence "sound effects, game soundtracks"; the "Solo ambient" category ("a game with a soundtrack") "Responds to the silence switch"; on headphone disconnect people "expect playback to pause immediately"; a game may auto-resume audio after an interruption. [7]
- **For WOLF//OVERRIDE:** `main.gd` already pauses on `NOTIFICATION_APPLICATION_PAUSED`/`FOCUS_OUT` (good, matches [6]). Gaps to check on device: (a) the Blowback overload timer and sentry must not advance during the OS pause (Godot tree pause covers it if the hazard uses `_process` under the paused tree); (b) on resume, show the pause menu, never resume straight into a live hazard; (c) audio category [resolved 2026-10-13]: in Godot 4.7.2, `audio/general/ios/session_category` defaults to 0, and 0 is **Ambient**. The enum in `core/config/project_settings.cpp` is "Ambient,Multi Route,Play and Record,Playback,Record,Solo Ambient", and `drivers/apple_embedded/app_delegate_service.mm` starts from `AVAudioSessionCategoryAmbient` [23]. Per Apple's table [7], Ambient obeys the silence switch and *mixes* with other apps' audio (Apple's example: "a game that lets people play music from another app"). Solo ambient also obeys the switch but stops other audio (Apple's example: "a game with a soundtrack"). Either way the silent switch is respected. Keeping Ambient lets players' own music keep playing; switching to Solo Ambient (index 5) matches Apple's example for a scored game. This is a design choice for Nathanial; (d) also autosave on `NOTIFICATION_APPLICATION_PAUSED`, because iOS can kill a backgrounded app without another callback.

### 1.6 Apple WWDC24 "Design advanced games for Apple platforms" [MOBILE-PERFORMANCE-8]
- Apple design team (Linda, Design Evangelism; Dylan, Apple Design), WWDC24 session 10085, transcript on the session page. Repeats 44x44 pt default / 28 pt minimum on iPhone and iPad; text "aim for a type size of 17 points or higher", 11 pt minimum for less essential information.
- Placement: "the regions around the thumbs, which are ideal for placing frequent or important actions, and the region at the top of the screen ... for less frequently used controls, like menu buttons"; avoid safe-area insets, the movement area and "the center of the display where the character is located."
- "players will likely be playing your game with only their two thumbs, you need to consider which controls might need to be used at the same time so that you can place them on the appropriate side of the screen."
- "It's extremely important that any touch control you create has a press state ... without them, controls feel unresponsive."
- **For WOLF//OVERRIDE:** MOVE (left thumb) and USE (right thumb) are the pair used at the same time (walking up to the valve while reaching for USE; holding USE to crank while the sentry approaches). They are already on opposite sides: keep it that way. Choice buttons (two wide panels across the bottom) replace movement during choices, which is fine because movement is not needed then.

## 2. Platform guidelines: Android and web standards

### 2.1 Touch target size and spacing [MOBILE-PERFORMANCE-9] [MOBILE-PERFORMANCE-10] [MOBILE-PERFORMANCE-11]
- Android Accessibility Help "Touch target size": "at least 48dp"; "A touch target of 48x48dp results in a physical size of about 9mm, regardless of screen size"; "The recommended target size for touchscreen objects is 7-10mm"; "separated by 8dp of space or more". [9]
- Android Developers "Make apps more accessible": 48dp x 48dp minimum, "Larger is even better"; contrast 4.5:1 below 18sp (or bold below 14sp), 3:1 otherwise. [10]
- Google Play Core app quality, criterion Touch_Target_Size: "Touch targets are least 48 dp." [11]
- **For WOLF//OVERRIDE (derived):** 48 dp is about 9 mm; 44 pt on an iPhone 16 is about 7.3 mm (460 ppi at 3x is about 153 pt per inch; at the classic 163 pt per inch it would be 6.9 mm; derived). Treat **9 mm / 48 dp** as the cross-platform floor for MOVE and USE, and 8 dp (1.27 mm, derived) as Android's minimum gap; Apple's ~12 pt with a bezel is about 2 mm, so use 2 mm. XAG 107's 15 x 15 mm (already in the sibling note controls-feel F11 and failure-difficulty F8) is, in Microsoft's words, a "suggested minimum default" size on phones (59 px at 100 DPI, 118 at 200, 236 at 400; tablets 24 mm) [MOBILE-PERFORMANCE-48]: a game-specific floor that is stricter than the platform floors, so aim for it on MOVE and USE.

### 2.2 WCAG 2.2 [MOBILE-PERFORMANCE-12] [MOBILE-PERFORMANCE-13]
- 2.5.8 Target Size (Minimum), Level AA: "at least 24 by 24 CSS pixels", with a spacing exception (a 24 px circle around each undersized target must not intersect another target). [12]
- 2.5.5 Target Size (Enhanced), Level AAA: "at least 44 by 44 CSS pixels"; rationale: "A finger is larger than a mouse pointer, and generally obstructs the user's view of the precise location on the screen that is being touched". [13]
- **For WOLF//OVERRIDE:** WCAG is written for web content, but the same 44 number shows up independently in Apple's guidance and the AAA criterion. The game's public site (apps/docs) is web content and WCAG applies there directly.

### 2.3 Thumb research [MOBILE-PERFORMANCE-14] [MOBILE-PERFORMANCE-15]
- Parhi, Karlson and Bederson, "Target Size Study for One-Handed Thumb Use on Small Touchscreen Devices", MobileHCI 2006 (Microsoft Research / University of Maryland): "target size of 9.2 mm for discrete tasks and targets of 9.6 mm for serial tasks should be sufficiently large for one-handed thumb use"; no significant error-rate differences for targets of at least 9.6 mm (discrete) and 7.7 mm (serial). (Read from the Microsoft Research abstract page; the full PDF could not be text-extracted here.) [14]
- Hoober, "How Do Users Really Hold Mobile Devices?", UXmatters, Feb 18 2013: 1,333 observations (780 touching the screen): 49% one-handed, 36% cradled, 15% two-handed; of two-handed users 90% held portrait, 10% landscape; people change grip "every few seconds". [15]
- **For WOLF//OVERRIDE:** Parhi's ~9.2-9.6 mm agrees with Android's 9 mm, so three independent sources converge on about 9 mm as the floor. Hoober's data is mostly portrait and apps, so it does not describe a landscape game; what transfers is (a) players change grip, and (b) thumbs, not fingertips, do the work. A landscape game is played two-thumbed by default, so both bottom corners are the reachable zone and the top centre is the hardest (Apple WWDC24 [8] agrees: top for menus).

### 2.4 Long-press and tap timing defaults [MOBILE-PERFORMANCE-16] [MOBILE-PERFORMANCE-17]
- Apple UIKit `UILongPressGestureRecognizer.minimumPressDuration`: "The default duration is 0.5 seconds." [16]
- Android AOSP `ViewConfiguration.java`: `DEFAULT_LONG_PRESS_TIMEOUT = 400` ms; `TAP_TIMEOUT = 100` ms; `DOUBLE_TAP_TIMEOUT = 300` ms; `TOUCH_SLOP = 8` (dp). [17]
- **For WOLF//OVERRIDE:** players' hands already know that 0.4-0.5 s turns a press into a "hold". The crank (`HoldUse.TICK_SECONDS = 0.4`) gives its first tick at exactly Android's long-press threshold, which reads as "the hold registered". Keep visible motion from the very first frame of the press (the sibling note controls-feel F11 sets <=0.1 s), and do not add a separate 0.5 s "is this a hold?" delay before cranking starts. A tap on USE that is not a hold (talk, read, flip a breaker) must fire on release or on press consistently: XAG 107 asks for activation on touch-end (failure-difficulty F8), which also lets a thumb slide off to cancel.

### 2.5 Android cutouts and app quality [MOBILE-PERFORMANCE-11] [MOBILE-PERFORMANCE-18]
- Display cutouts: for apps targeting SDK 35 on Android 15, `ALWAYS` is effectively the only mode for non-floating windows (edge-to-edge). Short-edge cutouts appear in landscape on the left or right; "Don't place interactive elements requiring fine-touch recognition in the cutout area", touch sensitivity "may be lower there"; read insets rather than hard-coding dp; test with Developer Options "Simulate a display with a cutout". [18]
- Core app quality: State_Preservation (resume "to the exact state in which the app was last used" from Recents or after sleep); Sleep_Resume and Lock_Resume (pause on sleep/lock); Fullscreen_Display ("fills the app window in both orientations and is not letterboxed because of configuration changes, including device folding and unfolding"; "Minor letterboxing to compensate for small variations in screen geometry is acceptable"); App_Startup_Time (feedback if load takes more than **2 s**); Rendering_Performance ("every 16 (or fewer) milliseconds to display at least 60 frames per second"); Line_Length 45-75 characters. [11]
- **For WOLF//OVERRIDE:** [Corrected 2026-10-13] Google's criterion is about letterboxing caused by configuration changes (rotation, folding), and it allows minor letterboxing for small geometry differences. Godot's `keep` still fills the app window and draws its own bars, so it is not a clear failure of this criterion. But 18% bars on a 19.5:9 phone are not "minor", and Apple asks for 19.5:9 support [3]. Moving to `expand` with a safe-area-aware HUD and controls is still the right call; treat it as quality, not a hard Play rule. Line length 45-75 chars agrees with XAG 101's 80-char cap and the sibling narrative note's ~40-42 chars per dialogue line.

## 3. Text size: game-specific minimums

### 3.1 Xbox Accessibility Guideline 101 (Microsoft, updated 2026) [MOBILE-PERFORMANCE-19]
- Minimum default text "body height" (descender to ascender): console 26 px at 1080p; PC 18 px at 1080p; **mobile 18 px at 100 DPI, 36 px at 200 DPI, 72 px at 400 DPI, scale linearly**; "a 5.5" screen with a 1080p resolution is roughly 400 DPI." Text should scale to 200%. Line width at most 80 characters; line spacing at least 1.5; sentence case for lines of text. "Platform-provided screen magnification tools aren't an appropriate mitigation for small text size."
- Derived: 18 px at 100 DPI = 0.18 in = **4.6 mm body height**. On an iPhone 16 (460 ppi, 3x) that is about 83 device px, about 27 pt of body height. On WOLF's `keep` viewport at 0.728 pt per px, that is about **38 viewport px of body height**. Today's dialogue at 16-17 px font size has a body height of roughly 16-20 px: about half of XAG's mobile minimum.

### 3.2 Game Accessibility Guidelines "Use an easily readable default font size" [MOBILE-PERFORMANCE-20]
- "28px minimum when viewed on a 1080p screen" (from Amazon TV guidelines), "as a minimum rather than a target"; small text is a common complaint including situational causes "such as small mobile screen"; "Allowing a choice of font size" is "the ideal solution".

### 3.3 Where the sources disagree, and what to do
- Apple: 11 pt minimum, 17 pt default (font size). XAG: about 27 pt of body height on a phone. These measure different things (font size vs. ascender-to-descender height) and XAG assumes the same physical size as a PC at desk distance, while phones are held closer. Apple is the platform holder for iOS and its 17 pt default is the practical target; XAG's figure is the accessible ceiling the text-size option should reach.
- **For WOLF//OVERRIDE:** default phone dialogue at about 17 pt (about 24 viewport px at the iPhone 16 scale, 22 px at the iPhone 11 scale), nothing below 11 pt (15-16 px), and a TEXT SIZE option up to 200% that reaches XAG's mobile body height. World labels on props (BREAKER, RELAY) at 13 px should be either enlarged on touch or treated as decoration with the readable name shown on the USE button / prompt.

## 4. Frame pacing: a steady rate beats a higher unstable one

### 4.1 Android frame pacing (Google) [MOBILE-PERFORMANCE-21]
- "If a game running at 30 FPS attempts to render on a device that natively supports 60 FPS, the game render loop doesn't realize that a repeated frame remains on the screen for an extra 16 milliseconds. This disconnect usually creates substantial inconsistency in frame times, such as: 49 milliseconds, 16 milliseconds, 33 milliseconds." "Short frames followed by long frames are perceived by the player as stuttering"; long frames may add "an extra frame of latency due to buffer-stuffing". Rendering 60 fps on a 120 Hz panel updates the screen twice per frame, which the library avoids to save battery.

### 4.2 Apple ProMotion (Apple, Core Animation docs) [MOBILE-PERFORMANCE-22]
- ProMotion ranges "from 10Hz to 120Hz on supported iPhone devices" (24-120 Hz on iPad Pro). Allowed intervals include 120 Hz (8 ms), 80 (12), 60 (16), 48 (20), 40 (25), 30 (33 ms).
- "In iOS 15 and later, the system provides games with special priority to 30Hz and 60Hz refresh rates to ensure optimal performance." To get it, the game must set a CADisplayLink preferred frame-rate range of 30 and/or 60 (same page); whether Godot 4.7.2 does this on iOS was not checked (UNVERIFIED).
- "If your animation requests 120Hz but can't keep up, it may render poorly. But the same animation may be able to maintain a steady cadence at a lower rate." "To save energy, choose the lowest frame rate that achieve's your desired visual flow."
- Without the `CADisableMinimumFrameDurationOnPhone` Info.plist key, iPhone apps don't get above 60 Hz.

### 4.3 What Godot 4.7.2 does by default (read from the 4.7.2-stable source and docs) [MOBILE-PERFORMANCE-23] [MOBILE-PERFORMANCE-24] [MOBILE-PERFORMANCE-25]
- The iOS Info.plist template in 4.7.2-stable sets `CADisableMinimumFrameDurationOnPhone` to true, and `display/window/ios/allow_high_refresh_rate` defaults to true: "iOS devices that support high refresh rate/"ProMotion" will be allowed to render at up to 120 frames per second." [23]
- Android: `display/window/frame_pacing/android/enable_frame_pacing` (Swappy) defaults to true, "Highly recommended". Default Swappy mode `auto_fps_auto_pipeline`: Swappy may "downgrade the max FPS until it finds a value that can be maintained", e.g. a game swinging between 40 and 60 fps on a 60 Hz screen ends up at "a perfect 30fps"; it disables pipelining when rendering takes under 8 ms on a 60 Hz screen "to minimize input latency". [23]
- `max_fps`: "Limiting the FPS can be useful to reduce system power consumption, which reduces heat and noise emissions (and improves battery life on mobile devices)." With V-Sync enabled the refresh rate takes precedence. [23][24]
- Godot's jitter guide: "Generally, Android is stutter and jitter-free because the running activity gets all the priority"; iOS usually stutter-free, but "older devices running newer versions of the operating system may exhibit problems"; jitter typically comes from physics at 60 Hz against a different display rate, fixed by physics interpolation. [25]
- `application/run/low_processor_mode` is for editors and mobile apps that redraw only when needed: "For most games ... it is recommended to keep this setting disabled." [23]
- **For WOLF//OVERRIDE:** the game's FPS limit defaults to 60 with options 30/60/90/120/144/uncapped (`main.gd:1222-1234`). On a ProMotion iPhone the engine now allows 120. Recommendations: (a) keep **60 as the phone default** and expose **30 (battery)** and **"match display" (up to 120)**; drop 90/144/uncapped on phones because they are not divisors of every panel and uncapped means 120 Hz plus heat; (b) never let it float between 40 and 60 (Google's 49/16/33 ms stutter); if a phone can't hold 60 in the Junction, lock that device to 30 rather than letting it wobble (Swappy may already do this on Android; iOS needs our own rule, e.g. drop to 30 after N seconds of missed 60); (c) physics interpolation on if physics stays at 60 Hz and the display runs at 120; (d) test the Junction "Blowback" (particles, shake, flashes) as the worst frame, not the corridor.

### 4.4 Android vitals: slow sessions (Google Play) [MOBILE-PERFORMANCE-26]
- "A slow session is a session in which more than 25% of the frames are slow"; a frame is slow if not presented within **50 ms** of the previous one (20 fps); a second metric uses **34 ms** (30 fps); monitoring begins after **one minute** of play; "In due course, Play will start steering users away from games that cannot achieve 20 FPS on their phones." (future tense on the page, so this is a stated plan, not a confirmed current policy.)
- **For WOLF//OVERRIDE:** 30 fps is the true floor for a Play listing; 60 is the target. A 2D game with this much painted art and particle work should hit 60 on mid-range phones; measure it.

### 4.5 Input latency on phones (cross-reference)
- The sibling note controls-feel F11 already cites Ng et al. (CHI 2014): commercial touch devices sit at about **65-120 ms** end to end before game code; Jota et al. found a tap ("land-on") JND near **64 ms**. Not repeated here. Two additions from this topic:
  - Every buffered frame costs 16.7 ms at 60 fps and 33.3 ms at 30 fps, so the 30 fps battery option roughly doubles the game's share of latency. Google's frame-pacing doc names buffer-stuffing as an "extra frame of latency". [21]
  - Swappy turns pipelining off when a frame renders in under 8 ms, so keeping the 2D render cheap buys latency on Android for free. [23]

### 4.6 Godot multitouch and the current touch buttons [MOBILE-PERFORMANCE-27] [MOBILE-PERFORMANCE-49]

> **Fact-check correction (2026-10-13):** the claim below that Control Buttons are not multitouch is out of date for Godot 4.7. PR #110893 "`BaseButton`: multitouch support" (Kazox61, merged 2026-04-09, milestone 4.7) and its fix #118608 "Fix BaseButton multitouch signals firing for only 1 button" (shiena, merged 2026-04-16) made BaseButton read `InputEventScreenTouch` by finger index. In `scene/gui/base_button.cpp` at tag 4.7.2-stable, each button stores its own `touch_index`, and the viewport routes each finger to the control under it (`gui.touch_focus[touch_index]`). The TouchScreenButton class reference sentence "Unlike [Button], TouchScreenButton supports multitouch out of the box" was not updated and is stale. So holding RIGHT and pressing USE should work in 4.7.2. It still needs a device test, and it can be checked headless with synthetic touches of index 0 and 1. One edge found in the same source (an inference, UNVERIFIED on a device): when a held button is hidden (`NOTIFICATION_VISIBILITY_CHANGED`), BaseButton clears its touch state but does not emit `button_up`, and it keeps `pressed_down_with_focus` set. `main.gd` already releases every gameplay action in `_pause_game()`, so nothing stays stuck. But the first touch on that button after resume may not emit `button_down`, because the stale flag is still set, so the first press after a pause would be lost. Test: hold RIGHT, trigger a pause (or a choice that hides the controls), resume, then tap RIGHT once.

Original researcher text (kept for the record; superseded by the correction above):
- Godot 4.7.2 class reference, TouchScreenButton: "Unlike [Button], TouchScreenButton supports multitouch out of the box. Several TouchScreenButtons can be pressed at the same time with touch input." Control Buttons get touch through `emulate_mouse_from_touch` (default true), which is mouse emulation. `keep_pressed_outside` "only affects the button's visual appearance".
- **For WOLF//OVERRIDE:** LEFT, RIGHT and USE are Control `Button`s driving `Input.action_press` on `button_down`/`button_up` (`main.gd:1215-1217`). [Superseded: see the correction above.] Per the engine docs, holding RIGHT with one thumb and pressing USE with the other may not register both, and a thumb sliding off a held button may not release it as expected. This must be checked on a real phone before anything else on touch (it is a logic question, so it can partly be tested headless with synthetic `InputEventScreenTouch` events of different indices). Fix options: `TouchScreenButton` nodes (multitouch, but no anchors, so place them from the safe area in code), or one full-screen Control that reads `InputEventScreenTouch`/`InputEventScreenDrag` by finger index and splits the screen into a left movement zone and right action zone (the INSIDE "Split" model in controls-feel F7).

## 5. Heat and battery

### 5.1 Apple thermal states [MOBILE-PERFORMANCE-28]
- `ProcessInfo.ThermalState.serious`: "The system takes moderate steps to reduce thermal state, which reduces performance"; advice includes "Reduce the target framerate from 60 FPS to 30 FPS" and "Reduce the level of detail in rendered content by using fewer particles or lower-resolution textures". `.critical`: reduce CPU/GPU/I-O "to the minimum level required for user interaction". `.fair`: defer background work.

### 5.2 Android thermal API and ADPF best practice [MOBILE-PERFORMANCE-29] [MOBILE-PERFORMANCE-30]
- Thermal headroom 0.0-1.0; forecast up to e.g. 30 s ahead; act when headroom passes ~0.85 (light) / 0.95 (moderate) / 1.0 (severe); "Don't call getThermalHeadroom() more than once every 10 seconds"; responses: reduce frame rate, lower fidelity. [29]
- ADPF best practices: scale individual settings (shadows, resolution, particles, effects) gradually, "over a few frames"; offer an "Enable Dynamic Performance Adjustment" toggle, on by default; "extended playtime testing (15+ minutes)" to see sustained thermal behaviour. [30]
- Cross-reference: the design reference sec. 9 already records INSIDE's iOS build at ~30 fps and the iPhone X reaching 60 only by overheating (Playdead). Agreed; the platform docs above give the mechanism and the API.
- **For WOLF//OVERRIDE:** (a) test every phone build with **15+ minutes** of continuous play (the whole slice loops: title, corridor, Records, Junction, retry) on a phone that starts cool and one that starts warm; (b) when iOS reports `serious` or Android headroom passes ~0.85-0.95, step down in this order: particles and flash density, then the floor-reflection pass (`floor_reflection.gd`), then 60 to 30 fps; announce nothing, but never change frame rate mid-hazard (wait for the next safe beat); (c) Godot has no built-in thermal-state API that I found in the 4.7.2 docs (UNVERIFIED; check `OS`/`DisplayServer` or use a small plugin).

### 5.3 Battery
- Apple [22] and Godot [23] both state the mechanism: a lower frame rate saves energy. No measured percentage for a 2D Godot game was found; any figure would be **UNVERIFIED**. Measure it: run the Junction for 15 minutes at 60 and at 30 fps and compare battery percentage drop and device temperature.
- `display/window/energy_saving/keep_screen_on` defaults to true in Godot 4.7.2 [23]: correct for play, but the title/pause screens should still pause the simulation (they already do) so an idle phone left on the pause menu is not rendering a live room at full rate (UNVERIFIED whether the pause overlay keeps rendering the room underneath at 60 fps; profile it).

## 6. Interruptions, session length and saving

### 6.1 Interruptions on iOS and Android [MOBILE-PERFORMANCE-6] [MOBILE-PERFORMANCE-31] [MOBILE-PERFORMANCE-32] [MOBILE-PERFORMANCE-33]
- Apple `applicationWillResignActive`: the app goes inactive for "temporary interruptions like an incoming phone call or SMS message"; "Games should use this method to pause the game." It also warns: "Don't rely on specific app state transitions to save all of your app's critical data." [31]
- Apple `applicationDidEnterBackground`: "approximately five seconds to perform any tasks and return. If the method doesn't return before time runs out, your app is terminated". [32]
- Godot 4.7.2 `NOTIFICATION_APPLICATION_PAUSED`: "On iOS, you only have approximately 5 seconds to finish a task started by this signal. If you go over this allotment, iOS will kill the app instead of pausing it." [33]
- Android Core app quality: resume "to the exact state in which the app was last used"; pause on sleep and lock. [11]
- **For WOLF//OVERRIDE:** current code pauses on PAUSED/FOCUS_OUT (good). Add: (a) a cheap autosave of the resume point on `NOTIFICATION_APPLICATION_PAUSED` (small ConfigFile write, well under 5 s), following Apple's advice to also save at normal checkpoints rather than only on the transition; (b) on resume, open the pause menu instead of live play (already the pause behaviour; verify on device); (c) a mid-hold crank must survive an interruption: `HoldUse` already keeps ticks across a release, so a phone call during the bypass loses at most one 0.4 s partial tick; (d) unsecured evidence on a cold relaunch (iOS killed the app in the background) should follow the design reference's rule (return to the last autosave with unsecured evidence left as a cache), not count as a death.

### 6.2 How long people play on phones [MOBILE-PERFORMANCE-34]
- GameAnalytics "2025 Mobile Gaming Benchmarks" by Tomas Hubka (page last updated August 24 2026; calendar 2024 data, 11,600 games, 1.48 billion average MAU, iOS and Android, medians): "the median 50% of games reported session lengths between 5 and 6 minutes" (top 25%: 8-9 minutes); about 4 sessions and about 22 minutes a day at the median. Adventure genre (monthly 2024 chart values embedded in the page): session **4.3-4.9 min**, **3.6-3.76 sessions/day**, **15.8-16.8 min/day**, D1 retention about 15.5-16.6%. [Corrected 2026-10-13: the overall median was 5-6 min, not 5-5.5.] Puzzle: 5.6-5.7 min sessions, 4.59-4.9 per day, 29.5-31.1 min/day.
- Caveat: the sample is mostly free-to-play; a premium story game is not the median adventure game, but the session shape (several short sittings a day) is the phone norm.
- **For WOLF//OVERRIDE:** design for a **5-minute sitting**. Each room beat (breaker, relay choice, Records, Junction stages) should take about 2-5 minutes, end at a safe point, and autosave, so a bus stop never costs more than one beat. The Junction "Blowback" sequence should have autosaves inside it (the design reference's "autosave at entry plus after each beat"), which already matches.

### 6.3 Monument Valley as the short-session premium case [MOBILE-PERFORMANCE-35]
- Wikipedia: "conceived as a touch game for tablets"; ten levels; "designed to be completed by most players". The Polygon source (Philip Kollar, March 18 2014) was opened through its Wayback Machine snapshot of June 23 2014 during the fact-check: "From the 1,000 beta testers ustwo used on the game, the average completion time was around 90 minutes", with executive producer Dan Gray as the speaker. Polygon says 1,000; Wikipedia's "over 1,000" overstates it slightly. Derived: about **9 minutes per level**, close to the GameAnalytics session length.
- **For WOLF//OVERRIDE:** the same shape (chapters about the length of a sitting, designed to be finished) fits a 3-5 hour premium narrative game on phones.

## 7. How cinematic and story platformers were brought to phones

### 7.1 Limbo (Playdead, iOS July 2013) [MOBILE-PERFORMANCE-38]
- Game Informer, Kyle Hilliard, "Limbo iOS Impressions – The Same Beautiful Experience, With Inferior Controls", July 3 2013: "An invisible d-pad on the left side of the screen is used to move left and right and climb ladders and ropes"; "Holding down your thumb on the right side of the screen makes him interact with objects and switches"; "To jump, you swipe up. If you are already moving ... the boy retains his momentum"; problem: "Sometimes the boy would just stop moving mid-jog and I would have to reset my thumb"; a "timing-centric" puzzle "was more difficult using the touchscreen controls"; verdict "the inferior choice ... but it's far from unplayable." Also: "Limbo hasn't received any balancing or layout changes to compensate for the less-than-perfect controls" (so the touch problems came from a straight port with no touch-specific level tuning).
- The design reference sec. 9 already quotes the "stop moving mid-jog" line; new here: the right-side **hold-to-interact** is the same verb shape as WOLF's hold-to-crank, and Playdead kept movement momentum through a jump gesture so the player never had to steer mid-air.

### 7.2 INSIDE (Playdead, iOS 2017) (cross-reference)
- Covered in detail by the sibling note controls-feel F7 [CONTROLS-FEEL-15] and design reference sec. 9: Split and Fluid modes, all fingers combine, swipe toward an object to grab, auto-complete rejected, animations shortened, 30 fps on iOS. Agreed; not repeated.

### 7.3 Another World 20th Anniversary (iOS Sept 22 2011; the DotEmu/BulkyPix credit is not in the cited article: UNVERIFIED) [MOBILE-PERFORMANCE-39]
- Game Informer, Tim Turi, Sept 7 2011: players "control the game with either a virtual d-pad or a new touch-based interface", plus a switch between original and HD graphics. Lesson: the first big cinematic-platformer port shipped **two schemes** rather than betting on gestures alone.

### 7.4 Oddworld: New 'n' Tasty (Just Add Water/Oddworld Inhabitants; Android and iOS Dec 14 2017) [MOBILE-PERFORMANCE-46]
- Release date from Wikipedia's infobox; the TouchArcade review it cites (Musgrave, Dec 14 2017) returned HTTP 403 to this fetcher, so its control details are **UNVERIFIED** here. The checkpoint changes (QuikSave, three-screen replay cap) are in the design reference sec. 4 and remain UNVERIFIED there.

### 7.5 Dead Cells (Motion Twin, mobile port by Playdigious, iOS Aug 28 2019) [MOBILE-PERFORMANCE-40]
- Engadget, Kris Holt, May 7 2019: "You'll be able to customize the size and position of the controls and swipe to dodge attacks"; MFi controller support; an "auto-hit mode".
- Lesson: resizable, movable controls plus an assist for the hardest verb; a fast action game still shipped on touch with these two levers.

### 7.6 Planet of Lana (Wishfully; mobile by Playdigious) [MOBILE-PERFORMANCE-41]
- App Store listing (seller Playdigious; 3.1 GB; iOS 15.6+, A12 Bionic or later): "Revamped interface – exclusive mobile UI with complete touch control".
- Version history: 1.0.3 (Dec 24 2025) "Settings changes are now automatically saved between play sessions"; 1.0.4 (Feb 24) hints and windows "out of screen on foldable devices"; 1.0.5 (Jul 27) "Adding visual feedback on buttons in menus", "Adjusting the text in menus for some devices", "Fixing the disappearance of some buttons when interacting with the environment".
- The design reference cites only the 1.0.5 disappearing-button fix. The other notes show the same family of first-release faults after launch: **no press feedback, text that doesn't fit some devices, UI off-screen on unusual aspect ratios, settings that did not persist**. Every one of these is cheap to prevent before release.

### 7.7 Monument Valley (ustwo, iOS April 3 2014) [MOBILE-PERFORMANCE-35]
- See 6.3: touch-first for tablets, ~90-minute average finish across 10 levels in beta, made so most players finish. Its interaction is direct (tap the world, drag a handle), with no virtual buttons at all: Apple's HIG advice to prefer direct interaction [2] in its purest form.

### 7.8 Player choice of layout: Into the Dead (Pik-Pok) [MOBILE-PERFORMANCE-43] [MOBILE-PERFORMANCE-48]
- Added in fact-check: XAG 107 gives two more precedents. *Fortnite* mobile ships three preset HUD layouts (including "Builder Pro" and "Combat Pro"), and *Call of Duty: Mobile* lets players customise the size and position of every touch target. XAG 107 asks games to "Allow players to adjust the size, spacing, and positioning of all touch targets" [48].
- Game Accessibility Guidelines, "Allow interfaces to be rearranged" (Intermediate, Motor): Pik-Pok's data from *Into the Dead* showed each of four touch layouts ("no UI, virtual stick on left side, virtual stick on right side, virtual buttons on left and right side") "was used by approximately 25% of their players". The same page lists "a virtual stick appearing wherever a touch is detected" as an example of a fully dynamic layout. No single default would have suited even a third of players.

### 7.9 Game Accessibility Guidelines: touch size [MOBILE-PERFORMANCE-42]
- "Ensure interactive elements / virtual controls are large and well spaced, particularly on small or touch screens" (Basic): about **2.4 cm** ideal on touch screens, **0.96 cm** minimum on phones, "use them as a minimum rather than a fixed size to aim for"; closely spaced buttons need to be larger.

## 8. What this means for WOLF//OVERRIDE: a phone layout proposal (design inference from the sources above)

Viewport math assumes the current 960x540 canvas; if the project switches to `expand` [44], the same physical sizes apply and positions come from the safe area [45].

| Item | Value | Why (sources) |
|---|---|---|
| MOVE control | One floating slide pad over the whole left 40% of the screen (below the dialogue band); touch-down sets the origin; horizontal offset sets walk vs jog; a faint ring appears under the thumb | Apple: floating stick where the thumb lands, combine walk/sprint [2]; Limbo's invisible pad lost the thumb [38], so show the ring and re-centre the origin if the thumb drifts past the edge |
| MOVE fallback layout | LEFT and RIGHT buttons as today, at least 96x90 px, gap at least 18 px (~2 mm) | Apple 12 pt padding [1], Android 8 dp [9] |
| USE | At least 15 x 15 mm (XAG 107's suggested phone minimum [48]; today's 90 px height is about 10.9 mm) and at least 15 mm wide where the screen allows (about 125 viewport px at the iPhone 16 scale), never below 9.6 mm (80 px); shows an icon/name of the target; glow ring larger than the thumb; click + light haptic on press | XAG 107 15 mm (sibling notes), GAG 0.96 cm min [42], Parhi 9.2-9.6 mm [14], Android 9 mm [9], Apple press states [2][8] |
| Pause | Top corner, at least 28 pt (about 40 px), away from the Dynamic Island side | Apple 28 pt secondary, menus at the top [2][8] |
| Hold to crank | First visible response within 0.1 s; first tick at 0.4 s (matches Android's 400 ms long press [17]); toggle option; ticks persist through a release | sibling notes; Apple 0.5 s [16] |
| Text on phones | Dialogue about 17 pt (about 24 px at 0.728); nothing below 11 pt (16 px); text size option to 200% | Apple [1][3][8], XAG 101 [19], GAG [20] |
| Layout presets | At least: floating pad (default), fixed buttons, left-handed mirror; resize slider for MOVE/USE | Into the Dead 4 x ~25% [43]; Dead Cells resizable controls [40] |
| Orientation | Landscape only, both directions (sensor landscape) | Apple Launching [4]; Godot orientation setting [23] |
| Aspect | Fill 16:9 to 19.5:9 (and 4:3 iPad); HUD and controls inside `get_display_safe_area()` | Apple [3][5]; Google "not letterboxed" [11]; Android cutouts [18] |
| Frame rate | 60 default, 30 battery option, steady; never floating 40-60 | Google [21][26], Apple [22], Godot [23] |
| Thermals | 15+ minute soak test; step down particles, then reflection, then 60->30 at a safe beat | Apple [28], Android [29][30] |
| Interruptions | Pause on resign-active; save resume point within the ~5 s window; resume into the pause menu | Apple [6][31][32], Godot [33], Google [11] |
| Session | Beats of 2-5 minutes ending at a safe point | GameAnalytics median ~5 min [34]; Monument Valley ~9 min per level [35] |
| Multitouch | Godot 4.7.2 Buttons track each finger [49]; still verify MOVE+USE together on a device and headless (touch index 0 and 1); release actions and reset buttons when touch controls hide mid-hold | Godot source [49]; TouchScreenButton doc [27] is stale |
| Silent switch | Godot 4.7.2's default iOS session (index 0) is Ambient: it obeys the silent switch and mixes with the player's music. Solo Ambient (index 5) is Apple's example for a game with a soundtrack. Pick one on purpose | Apple [7]; Godot source [23] (verified 2026-10-13) |

Testing honesty (AGENTS.md): sizes and safe areas can be checked in rendered stills (`tools/render/render.sh` at phone resolutions such as 2556x1179 and 1792x828); multitouch logic can be partly checked headless with synthetic touch events; feel, thumb comfort, heat and battery can only be validated on a physical phone.

## 9. Agreement and disagreement with design-reference-25-games.md

- **AGREE, gap filled: touch target sizes.** The reference listed "touch target sizes" as not covered. Now covered with platform numbers: Apple 44x44 pt default / 28 pt minimum, ~12 pt padding [1][2][3][8]; Android 48 dp (~9 mm), 8 dp spacing [9][10][11]; WCAG 24 / 44 CSS px [12][13]; Parhi 9.2-9.6 mm [14]; GAG 0.96 cm minimum / 2.4 cm ideal [42]; XAG 107 15 mm (sibling notes). The current LEFT/RIGHT/USE pass Apple and Android minimums on phones; the LEFT-RIGHT gap and all HUD text below 16 px do not.
- **AGREE, gap partly filled: zone layouts.** Apple's WWDC24 thumb regions [8] and Into the Dead's 25% split [43] supply the zone and layout data; no measured landscape thumb-reach map was found (Hoober's data is portrait [15]): **gap remains** for landscape reach numbers.
- **AGREE, gap filled: session-length data.** GameAnalytics medians [34] (about 5 min sessions, 3.6 adventure sessions per day), Monument Valley's ~90-minute finish [35].
- **AGREE with "Invisible d-pad ... Visible, anchored controls are safer" (sec. 9) but REFINE it.** Apple now recommends a *floating* stick that appears where the thumb lands [2], which is neither invisible nor anchored. Limbo's failure [38] was that the pad was invisible and lost the thumb, not that it floated. Recommendation: a floating pad that draws its ring and re-centres, plus a fixed-button layout preset.
- **AGREE with thermals (INSIDE ~30 fps; iPhone X 60 only by overheating).** Apple's thermal-state docs say the same thing in platform terms ("Reduce the target framerate from 60 FPS to 30 FPS") [28]. **EXTEND:** the reference says "profile on a cool device over long sessions" without a number; Google's ADPF guide gives **15+ minutes** [30].
- **AGREE with "Shorten timing actions on touch; never auto-complete them" and the tank-drop window rule** (sec. 6). Limbo's timing puzzle was harder on touch [38]. Add: frame pacing matters most in that window; a 40-60 fps wobble produces 16/33/49 ms frames [21], which is worst exactly during a ~0.38-0.63 s timing window.
- **AGREE with "Holds: hold-to-toggle for long holds".** Platform long-press defaults (0.4-0.5 s) [16][17] show the crank's 0.4 s tick sits at the system threshold; nothing contradicts the reference.
- **DISAGREE (mild) with treating INSIDE's iOS 30 fps as the model.** Apple gives games special priority at both 30 and 60 Hz since iOS 15 [22] and Google's quality bar is 60 fps [11]; a 2D Godot game on a 2020s phone should target a steady 60 and keep 30 as the fallback, not the default. INSIDE was a 3D Unity game on 2017 hardware.
- **NEW (not in the reference):** (a) [Corrected in fact-check] Godot 4.7 added multitouch to Control Buttons [49], so the two-thumb case should work; the remaining risk is hide-while-held, which may swallow the first press after resume (inferred from source, untested); (b) the current `keep` aspect pillarboxes phones by about 18%, more than the "minor" bars Google's quality criterion allows [11]; (c) the ~5 s background save window [32][33]; (d) Planet of Lana's other launch faults (no menu press feedback, text not fitting, foldable layouts, settings not persisting) [41]; (e) phone text below Apple's 11 pt minimum today [1].

## 10. Pitfalls (short list)

1. [Corrected] Assuming touch buttons work together without testing. Godot 4.7 Buttons do track fingers separately [49] (the TouchScreenButton doc saying otherwise is stale [27]), but hiding a held Button does not emit `button_up` and may swallow the next press. Test two-thumb holds and pause/resume on a device.
2. Letterboxing a 19.5:9 phone with `keep`: wastes about 18% of the width. Google's "not letterboxed" criterion [11] targets letterboxing from configuration changes and allows minor bars, so this is a quality problem rather than a clear Play-rule failure.
3. HUD and prop text at 13-15 px: below Apple's 11 pt minimum on phones [1].
4. LEFT/RIGHT 14 px apart: under Apple's ~12 pt padding [1].
5. An invisible or drifting movement pad that loses the thumb (Limbo [38]).
6. A frame rate that floats between 40 and 60 (16/33/49 ms frames [21]); "uncapped" on a 120 Hz phone means heat [22][23].
7. Testing a few minutes on a cool phone; ADPF asks for 15+ minutes [30].
8. Saving only on the background transition; Apple says save at normal points too, and there are ~5 s [31][32][33].
9. Shipping without press feedback, with text that overflows on some devices, UI off-screen on foldables, or settings that don't persist (Planet of Lana patches [41]).
10. One fixed layout for everyone (Into the Dead: four layouts, ~25% each [43]).
11. Gesture-only actions with no on-screen alternative (Apple: "Offer alternatives to gestures" [1]; custom gestures must not be "the only way to perform an important action" and should not conflict with system edge gestures [47]). WOLF//OVERRIDE should keep a visible USE button even if a swipe-toward-object gesture is added.

## 11. Sources (all accessed 2026-10-12)

[MOBILE-PERFORMANCE-1] Apple. "Accessibility", Human Interface Guidelines. Apple Developer, living document (current 2026). https://developer.apple.com/design/human-interface-guidelines/accessibility (read via its JSON data: https://developer.apple.com/tutorials/data/design/human-interface-guidelines/accessibility.json)
[MOBILE-PERFORMANCE-2] Apple. "Game controls" (Touch controls section added June 10 2024, updated June 9 2025), Human Interface Guidelines. Apple Developer. https://developer.apple.com/design/human-interface-guidelines/game-controls
[MOBILE-PERFORMANCE-3] Apple. "Designing for games", Human Interface Guidelines. Apple Developer, living document. https://developer.apple.com/design/human-interface-guidelines/designing-for-games
[MOBILE-PERFORMANCE-4] Apple. "Launching", Human Interface Guidelines. Apple Developer. https://developer.apple.com/design/human-interface-guidelines/launching
[MOBILE-PERFORMANCE-5] Apple. "Layout", Human Interface Guidelines (change log to September 9 2026). Apple Developer. https://developer.apple.com/design/human-interface-guidelines/layout
[MOBILE-PERFORMANCE-6] Apple. "Going full screen", Human Interface Guidelines. Apple Developer. https://developer.apple.com/design/human-interface-guidelines/going-full-screen
[MOBILE-PERFORMANCE-7] Apple. "Playing audio", Human Interface Guidelines. Apple Developer. https://developer.apple.com/design/human-interface-guidelines/playing-audio
[MOBILE-PERFORMANCE-8] Apple Design Evangelism and Apple Design team (speakers Linda and Dylan). "Design advanced games for Apple platforms", WWDC24 session 10085. Apple Developer video and transcript, 2024. https://developer.apple.com/videos/play/wwdc2024/10085/
[MOBILE-PERFORMANCE-9] Google. "Touch target size", Android Accessibility Help (Accessibility Scanner). Google Support, undated living page. https://support.google.com/accessibility/android/answer/7101858
[MOBILE-PERFORMANCE-10] Google. "Make apps more accessible", Android Developers documentation. https://developer.android.com/guide/topics/ui/accessibility/apps
[MOBILE-PERFORMANCE-11] Google. "Core app quality guidelines", Android Developers / Google Play. https://developer.android.com/docs/quality-guidelines/core-app-quality
[MOBILE-PERFORMANCE-12] W3C WAI. "Understanding Success Criterion 2.5.8: Target Size (Minimum)", WCAG 2.2, 2023. https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
[MOBILE-PERFORMANCE-13] W3C WAI. "Understanding Success Criterion 2.5.5: Target Size (Enhanced)", WCAG 2.2. https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html
[MOBILE-PERFORMANCE-14] Pekka Parhi, Amy K. Karlson, Benjamin B. Bederson. "Target Size Study for One-Handed Thumb Use on Small Touchscreen Devices", Proceedings of MobileHCI 2006 (ACM). Abstract page at Microsoft Research: https://www.microsoft.com/en-us/research/?p=155150 ; DOI https://dx.doi.org/10.1145/1152215.1152260 (full PDF downloaded but not text-extractable here; numbers taken from the abstract).
[MOBILE-PERFORMANCE-15] Steven Hoober. "How Do Users Really Hold Mobile Devices?", UXmatters, February 18 2013. https://www.uxmatters.com/mt/archives/2013/02/how-do-users-really-hold-mobile-devices.php
[MOBILE-PERFORMANCE-16] Apple. "minimumPressDuration", UIKit UILongPressGestureRecognizer documentation. Apple Developer. https://developer.apple.com/documentation/uikit/uilongpressgesturerecognizer/minimumpressduration
[MOBILE-PERFORMANCE-17] Android Open Source Project (Google). `core/java/android/view/ViewConfiguration.java`, frameworks/base, main branch. https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/core/java/android/view/ViewConfiguration.java
[MOBILE-PERFORMANCE-18] Google. "Support display cutouts", Android Developers documentation. https://developer.android.com/develop/ui/views/layout/display-cutout
[MOBILE-PERFORMANCE-19] Microsoft. "Xbox Accessibility Guideline 101: Text display", Microsoft Learn (Microsoft Game Dev), first published 2022-05-09; page metadata updated_at 2026-06-17, visible footer "Last updated on 2026-03-04". https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101
[MOBILE-PERFORMANCE-20] Game Accessibility Guidelines (collaborative group of studios, specialists and academics). "Use an easily readable default font size". https://gameaccessibilityguidelines.com/use-an-easily-readable-default-font-size/
[MOBILE-PERFORMANCE-21] Google. "Frame Pacing library" (Android Game Development Kit / Swappy), Android Developers documentation. https://developer.android.com/games/sdk/frame-pacing
[MOBILE-PERFORMANCE-22] Apple. "Optimizing iPhone and iPad apps to support ProMotion displays", Core Animation (QuartzCore) documentation. https://developer.apple.com/documentation/quartzcore/optimizing-iphone-and-ipad-apps-to-support-promotion-displays
[MOBILE-PERFORMANCE-23] Godot Engine contributors. `doc/classes/ProjectSettings.xml` and `misc/dist/apple_embedded_xcode/godot_apple_embedded/godot_apple_embedded-Info.plist`, tag 4.7.2-stable, GitHub. https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/ProjectSettings.xml ; https://github.com/godotengine/godot/blob/4.7.2-stable/misc/dist/apple_embedded_xcode/godot_apple_embedded/godot_apple_embedded-Info.plist
[MOBILE-PERFORMANCE-24] Godot Engine contributors. "Engine" class reference (max_fps, physics_ticks_per_second, physics_jitter_fix), Godot Docs (stable). https://docs.godotengine.org/en/stable/classes/class_engine.html
[MOBILE-PERFORMANCE-25] Godot Engine contributors. "Fixing jitter, stutter and input lag", Godot Docs (stable). https://docs.godotengine.org/en/stable/tutorials/rendering/jitter_stutter.html
[MOBILE-PERFORMANCE-26] Google. "Slow sessions" (Android vitals for games), Android Developers documentation. https://developer.android.com/games/optimize/vitals/slow-session
[MOBILE-PERFORMANCE-27] Godot Engine contributors. `doc/classes/TouchScreenButton.xml` and `doc/classes/BaseButton.xml`, tag 4.7.2-stable, GitHub. https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/TouchScreenButton.xml ; https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/BaseButton.xml
[MOBILE-PERFORMANCE-28] Apple. "ProcessInfo.ThermalState" (cases fair, serious, critical), Foundation documentation. https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.enum
[MOBILE-PERFORMANCE-29] Google. "Thermal API" (Android Dynamic Performance Framework), Android Developers documentation. https://developer.android.com/games/optimize/adpf/thermal
[MOBILE-PERFORMANCE-30] Google. "Best practices for ADPF", Android Developers documentation. https://developer.android.com/games/optimize/adpf/best-practices-adpf
[MOBILE-PERFORMANCE-31] Apple. "applicationWillResignActive(_:)", UIKit UIApplicationDelegate documentation. https://developer.apple.com/documentation/uikit/uiapplicationdelegate/applicationwillresignactive(_:)
[MOBILE-PERFORMANCE-32] Apple. "applicationDidEnterBackground(_:)", UIKit UIApplicationDelegate documentation. https://developer.apple.com/documentation/uikit/uiapplicationdelegate/applicationdidenterbackground(_:)
[MOBILE-PERFORMANCE-33] Godot Engine contributors. `doc/classes/Node.xml` (NOTIFICATION_APPLICATION_PAUSED), tag 4.7.2-stable, GitHub. https://github.com/godotengine/godot/blob/4.7.2-stable/doc/classes/Node.xml
[MOBILE-PERFORMANCE-34] Tomas Hubka / GameAnalytics. "2025 Mobile Gaming Benchmarks" (page last updated August 24 2026) (data: calendar 2024; 11,600 games; medians). GameAnalytics report, 2025. https://www.gameanalytics.com/reports/2025-mobile-gaming-benchmarks
[MOBILE-PERFORMANCE-35] Wikipedia contributors. "Monument Valley (video game)", relaying Philip Kollar, "Monument Valley: the quest for a game everyone can finish", Polygon, March 18 2014. Polygon blocks direct fetches; it was opened during the fact-check through the Wayback snapshot https://web.archive.org/web/20140623151414/http://www.polygon.com/2014/3/18/5522874/monument-valley-everyone-finish https://en.wikipedia.org/wiki/Monument_Valley_(video_game) ; http://www.polygon.com/2014/3/18/5522874/monument-valley-everyone-finish
[MOBILE-PERFORMANCE-36] Apple. "iPhone 16 - Technical Specifications". apple.com, 2024. https://www.apple.com/iphone-16/specs/
[MOBILE-PERFORMANCE-37] Apple. "iPhone 11 - Technical Specifications". Apple Support. https://support.apple.com/en-us/111865
[MOBILE-PERFORMANCE-38] Kyle Hilliard. "Limbo iOS Impressions – The Same Beautiful Experience, With Inferior Controls". Game Informer, July 3 2013. https://www.gameinformer.com/b/features/archive/2013/07/03/limbo-ios-impressions.aspx
[MOBILE-PERFORMANCE-39] Tim Turi. "Explore Another World On Your iPhone This Month". Game Informer, September 7 2011. https://www.gameinformer.com/b/news/archive/2011/09/07/explore-another-world-on-your-iphone-this-month.aspx
[MOBILE-PERFORMANCE-40] Kris Holt. "Indie hit 'Dead Cells' is coming to mobile this summer". Engadget, May 7 2019. https://www.engadget.com/2019/05/07/dead-cells-ios-android/
[MOBILE-PERFORMANCE-41] Playdigious (seller) / Wishfully (developer). "Planet of Lana" App Store listing and version history (1.0.3 Dec 24 2025; 1.0.4; 1.0.5). Apple App Store. https://apps.apple.com/us/app/planet-of-lana/id6739130049
[MOBILE-PERFORMANCE-42] Game Accessibility Guidelines. "Ensure interactive elements / virtual controls are large and well spaced, particularly on small or touch screens". https://gameaccessibilityguidelines.com/ensure-interactive-elements-virtual-controls-are-large-and-well-spaced-particularly-on-small-or-touch-screens/
[MOBILE-PERFORMANCE-43] Game Accessibility Guidelines. "Allow interfaces to be rearranged" (citing Pik-Pok's Into the Dead layout data). https://gameaccessibilityguidelines.com/allow-interfaces-to-be-rearranged/
[MOBILE-PERFORMANCE-44] Godot Engine contributors. "Multiple resolutions", Godot Docs (stable). https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html
[MOBILE-PERFORMANCE-45] Godot Engine contributors. "DisplayServer" class reference (get_display_safe_area, screen orientations), Godot Docs (stable). https://docs.godotengine.org/en/stable/classes/class_displayserver.html
[MOBILE-PERFORMANCE-47] Apple. "Gestures", Human Interface Guidelines (custom gestures; system-gesture conflicts). Apple Developer. https://developer.apple.com/design/human-interface-guidelines/gestures
[MOBILE-PERFORMANCE-46] Wikipedia contributors. "Oddworld: New 'n' Tasty!" (mobile release date). https://en.wikipedia.org/wiki/Oddworld:_New_%27n%27_Tasty!
[MOBILE-PERFORMANCE-48] Microsoft. "Xbox Accessibility Guideline 107: Input", Microsoft Learn (Microsoft Game Dev), first published 2022-05-09, metadata updated 2026-06-17. https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/107 (added in fact-check: 15 x 15 mm suggested minimum default touch target on phones, 24 mm on tablets; spacing; Fortnite presets; Call of Duty: Mobile customisation)
[MOBILE-PERFORMANCE-49] Kazox61 (author), Godot Engine contributors. "`BaseButton`: multitouch support", godotengine/godot PR #110893, merged 2026-04-09, milestone 4.7; follow-up shiena, "Fix BaseButton multitouch signals firing for only 1 button", PR #118608, merged 2026-04-16. GitHub. https://github.com/godotengine/godot/pull/110893 ; https://github.com/godotengine/godot/pull/118608 ; code at https://github.com/godotengine/godot/blob/4.7.2-stable/scene/gui/base_button.cpp (added in fact-check)

Cross-references (sibling notes in this folder, not re-sourced here): controls-feel.md F7 [CONTROLS-FEEL-15] (Playdead INSIDE iOS), F11 [CONTROLS-FEEL-24..26] (Ng et al. CHI 2014 latency; XAG 107 15 mm); failure-difficulty.md F8, F17 (XAG 107 holds; HIG resume).

Could not open (403/404/JS-only): TouchArcade reviews of Limbo, Another World, Oddworld NnT, Dead Cells; Polygon; ACM DL (Baldauf et al. on-screen gamepads); Playdigious news; Material 3 site (JS-rendered; Android pages used instead). The WebSearch budget for the session ran out midway, so later sources were reached by direct URLs only.

## Fact-check (independent checker, 2026-10-13)

Every source URL was opened again (Apple HIG and Apple developer docs through their JSON data; Godot through the 4.7.2-stable source files; Google, W3C, Microsoft, GAG, UXmatters, GameAnalytics, Wikipedia, Game Informer, Engadget and the App Store as HTML; Polygon through the Wayback Machine). A backup of the pre-check notes is at `mobile-performance.md.pre-factcheck.bak`.

Changed:
1. **Multitouch (must-level need, sec. 4.6, pitfall 1, NEW (a)): corrected.** Godot 4.7 added finger-index multitouch to BaseButton (PR #110893, merged 2026-04-09, milestone 4.7; fix PR #118608, merged 2026-04-16). `base_button.cpp` at 4.7.2-stable confirms it; the code was absent in 4.4, 4.5 and 4.6-stable. The TouchScreenButton doc line "Unlike [Button] ..." is stale. New source [49]. Added a source-read edge (UNVERIFIED on device): a held button that gets hidden does not emit `button_up` and keeps `pressed_down_with_focus`, which may swallow the next press after resume.
2. **Google "not letterboxed": softened.** The full criterion is "not letterboxed because of configuration changes, including device folding and unfolding" and "Minor letterboxing ... is acceptable". `keep` is not a clear failure of the rule; the 18% waste and Apple's 19.5:9 ask still justify `expand`.
3. **GameAnalytics:** the overall median session is "between 5 and 6 minutes", not 5-5.5. Adventure D1 retention is 15.5-16.6%. Added the author (Tomas Hubka) and the page update date (Aug 24 2026). The adventure session, count and playtime figures were confirmed from the chart data embedded in the page.
4. **Monument Valley:** Polygon was opened through Wayback and the source is now verified. The article says "the 1,000 beta testers ... around 90 minutes" (speaker: executive producer Dan Gray); Wikipedia's "over 1,000" is slightly off.
5. **Android vitals:** "Play will start steering" is the page's future plan ("In due course"), not current policy.
6. **iOS audio session index 0: resolved.** It is Ambient (enum in `project_settings.cpp`; mapping in `app_delegate_service.mm`). It obeys the silent switch but mixes with other audio. Apple's own example for "a game with a soundtrack" is Solo ambient.
7. **XAG 107 added [48]:** 15 x 15 mm is Microsoft's *suggested minimum default* on phones, not just a comfort target. Today's 90 px button height (about 10.9 mm on an iPhone 16) is under it. Also added XAG 107's Fortnite and Call of Duty: Mobile layout precedents.
8. **Small fixes:** 44 pt is about 7.3 mm at 153 pt per inch (the "1/163 in" parenthetical gave 6.9 mm). The Into the Dead layouts are now quoted exactly. Added Limbo's "no balancing or layout changes" line. XAG 101's visible "Last updated" date is 2026-03-04, while its metadata says 2026-06-17. Noted that `get_display_safe_area` works only on Android and iOS and returns screen pixels. Noted that Apple's 30/60 Hz game priority needs a CADisplayLink preferred frame-rate range (whether Godot sets it is UNVERIFIED).
9. **Another World:** the DotEmu/BulkyPix credit is not in the cited Game Informer piece, so it is marked UNVERIFIED.

Confirmed as written (exact quotes checked):
- Apple: 44/28 pt, 12/24 pt padding, the 17/11 pt text table, 200%, the contrast table, the Game controls quotes and their June 10 2024 / June 9 2025 dates, Launching, Layout (Sept 9 2026), Going full screen, Playing audio, Gestures, the WWDC24 10085 quotes, 0.5 s long press, the ProMotion table and quotes, ThermalState serious/critical, applicationWillResignActive, and the approximately five seconds of applicationDidEnterBackground.
- Google: 48dp, about 9 mm, 7-10 mm, 8dp, 18sp/14sp contrast; the core quality items (16 ms, two seconds, 45-75 chars, exact-state resume, sleep/lock); the cutout guidance; Swappy 49/16/33 ms; slow sessions (25%, 50 ms, 34 ms, one minute); thermal headroom 0.85/0.95/1.0, 10 s and 30 s; ADPF 15+ minutes.
- AOSP: 400/100/300 ms and 8 dp.
- W3C 2.5.8 and 2.5.5; Parhi 9.2/9.6/7.7 mm; Hoober 1,333/780/49/36/15/90/10%.
- XAG 101: 18/36/72 px, 80 chars, 1.5 spacing.
- GAG: 28 px, 0.96 cm, 2.4 cm, 25%.
- Godot 4.7.2: allow_high_refresh_rate, the CADisableMinimumFrameDurationOnPhone plist key, Swappy modes, max_fps, low_processor_mode, keep_screen_on, NOTIFICATION_APPLICATION_PAUSED 5 s, keep_pressed_outside, emulate_mouse_from_touch, and SCREEN_SENSOR_LANDSCAPE; the Godot jitter guide quotes; and the 'expand' advice for tall phones.
- Ports and specs: the Limbo, Another World, Dead Cells and Planet of Lana version history (1.0.3 Dec 24 2025, 1.0.4 Feb 24 2026, 1.0.5 Jul 27 2026; mobile 1.0 Oct 21 2025); the iPhone 16 and iPhone 11 specs; Oddworld NnT mobile on Dec 14 2017.
- Repo baseline: button offsets, the 13/14/15 px fonts, `main.gd` lines 1215-1217 and 1446, and `TICK_SECONDS = 0.4`.

Still UNVERIFIED: per-model landscape safe-area insets; any battery-saving percentage; whether Godot sets CADisplayLink 30/60 ranges on iOS; whether a Godot thermal-state API exists; the touch behaviour of Oddworld NnT mobile (TouchArcade 403); the hide-while-held Button edge on a real device.
