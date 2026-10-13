# Gap pass: controller, front end, desktop display, speakers, accessibility depth, localization, licences, choice memory, tablets (round 2)

WOLF//OVERRIDE is an original game and story by **Nathanial Henniges**. This note closes the gaps a critic found in the first synthesis (2026-10-13): areas the eleven topics did not cover, MUST needs that rested on Wikipedia or fan transcripts, and gaps listed by the 25-game study that were never ledgered. It was written on 2026-10-13 by an AI agent (Claude Code by Anthropic). Every source below was opened on 2026-10-13 unless it is marked UNVERIFIED; quotes are short and the works are linked, not copied. The engineer uses they/them; WOLF is he/his.

Game facts come from the game code at `da5c14e` (identical game code to `baffea4` and to `main` at `36788ff`) and from the round-2 capture ([CAPTURE-ROUND2.md](../playthrough/CAPTURE-ROUND2.md)), which ran headless (`godot --headless`, isolated HOME) and in `tools/render/render.sh` (container). No window was opened on Nathanial's Mac.

---

## 1. Controller (gamepad)

**What the game does today (code and capture).** A = interact and confirm, X and Y = the two answers, START = pause, B = back, D-pad or left stick = move (main.gd:3446-3462). Stick deadzone 0.25 by default, adjustable 0.1-0.8 (game_settings.gd:56, :255). Rumble goes to the pad in use (impact.gd:166-170; main.gd:1511-1522). Prompts swap to the pad's labels as letters ("A READ DISPLAY", "X The relay may vent coolant", "HOLD A: crank", C-0052, C-0069, C-0098); the Settings CONTROLS tab rebinds both columns (C-0185).

Measured in route C (headless and render.sh, injected `InputEventJoypadButton` / `InputEventJoypadMotion`):
- **Analog walking is proportional.** Speed = 190 × (|stick| − 0.25) / 0.75 px/s: stick 0.2 → 0, 0.3 → 12.7, 0.5 → 63.3, 0.8 → 139.3, 1.0 → 190 px/s. So a half-tilt already walks at a third of full speed, a natural basis for the decided walk-then-jog (FEEL-3).
- **Rumble fires** on the cage release (0.5 weak / 0.9 strong, 0.25 s), the breaker (0.15 / 0, 0.06 s), the bypass, the seal, the Records exit, the blast knockdown (0.5 / 0.9, 0.25 s), the door blast (0.7 / 1.0, 0.3 s), the tank and the bolt. There is no rumble strength slider (only on/off through Settings).
- **Menus by D-pad:** the title focuses NEW GAME at once and A starts it; Pause focuses RESUME; one D-pad down reaches SETTINGS. **Inside Settings › CONTROLS, D-pad down cycles the eight rebinding rows, the deadzone slider and RESET, and never reaches BACK; up goes to the tab bar.** B closes Settings (it works). A pad player who does not think of B cannot leave the screen by D-pad.
- **Glyphs are letters,** not the connected pad's symbols: "A", "X", "Y", "START". On a PlayStation or Switch pad those letters are wrong.

**Sources.**
- Microsoft's XInput guide defines `XINPUT_GAMEPAD_LEFT_THUMB_DEADZONE` as 7849 of 32767 (≈ 0.24), right 8689 (≈ 0.27), trigger threshold 30 of 255, and says to rescale the range past the dead zone to 0-1, optionally with a non-linear curve ("cube the result") for "more precision in the lower ranges" [GAP-PASS-1]. The game's 0.25 matches the left-stick default, and Godot already rescales (the measured speeds above follow (v − 0.25)/0.75).
- Apple's HIG "Game controls" (updated June 9, 2025): "Be sure to use the connected controller's labeling scheme"; "Prefer using symbols, not text, to refer to game controller elements"; UI conventions A activates, B "Cancels an action or returns to previous screen", Menu "Opens game settings or pauses gameplay"; "Let players customize key bindings" [GAP-PASS-2].
- Steam Deck Verified criteria: the default controller configuration must reach all content with no settings change; "On-screen glyphs must match the inputs being used"; "Mouse and keyboard glyphs should not be shown if they are not the active input"; default config reaches ~30 fps at 800p; the smallest font character "should never fall below 9 pixels in height at 1280x800"; 1280x800 preferred [GAP-PASS-3].
- XAG 110 (haptics): players must be able to turn haptics off and "Adjust the strength", and haptics must never be the only channel [GAP-PASS-6]. XAG 112 (UI navigation): "consistent ... 'A' to select, 'B' for back" and the UI "fully navigable by keyboard and controller digital input alone" [GAP-PASS-7]. XAG 113: a visible focus indicator that never moves to off-screen or invisible elements [GAP-PASS-8].

**Where this lands:** CTRL-1 to CTRL-5 in NEEDS.md.

## 2. Front end and session flow

**What the game does today (route F, render.sh, real launch from `studio_logo.tscn`).** Frames F-logo-00.25s to F-logo-03.50s and F-0003 to F-0261.
- **Launch to title:** the logo shows 0-2.0 s (mascot, then the company name), fades, and the main scene is in the tree at 2.03 s; the title buttons are drawn at 2.25 s and the wordmark has finished fading in by ~3.0 s. The repo's own audit measured launch to the first title frame at 0.93 s (main) to 1.17 s (presentation branch) on an M1 Pro [repo: docs/research-2026-10/data/audit.json, `perf`]. The logo can be skipped by any key after the title is ready (changelog, October 12).
- **Title:** NEW GAME, CONTINUE (disabled with "No checkpoint yet. Saving starts at the first SAFE POINT."), CREDITS, SETTINGS, CHANGELOG. **No QUIT** on the desktop title (main.tscn:542-583; F-0003). Esc on the bare title does nothing (main.gd:1421-1438); only Android Back quits from the bare title (main.gd:1468-1469), or closing the window.
- **Credits** (F-0004): the original concept, story and vision credit to Nathanial first; auto-scroll with a PAUSE SCROLL button (meets XAG 117's "pause, stop" rule for scrolling text). The credits did not scroll in the capture's 15 s; the capture draws only on saved frames, so this is probably a capture artefact (not judged).
- **Changelog** (F-0023): "DEVELOPMENT UPDATES", small body text (not measured) in a dense paragraph about source-build changes; developer language, no story spoilers seen on the first screen.
- **Pause during the opening offers SKIP OPENING** (F-0030, main.gd:1360); it lands on the first controllable frame (F-0261). So the opening is skippable in two presses, but nothing tells a first-time player.
- **Quit mid-junction and Continue:** with the breaker armed and the line building at x 248, RETURN TO TITLE warns "Returning keeps your last checkpoint. Unsaved progress will be lost." (F-0182). CONTINUE puts the engineer at the junction entry (x 120) with the line idle and "Service junction restored. Arm the breaker by the entrance, then crank the valve." (F-0188): ~5-10 s of replay, said plainly.
- **New Game / PLAY AGAIN with a save:** no overwrite prompt; the old save is kept "until the new run reaches its first SAFE POINT" (main.gd:574-575). After the slice the title shows only PLAY AGAIN with "Slice complete. PLAY AGAIN starts a fresh run." (F-0250).
- **First launch:** no accessibility or text-size prompt; Settings has no text size, subtitle, hold-toggle or haptic-strength rows (F-0025, C-0185).
- **Focus loss** (route X): with the default `auto_pause_on_focus_loss`, a `NOTIFICATION_APPLICATION_FOCUS_OUT` mid-fuse pauses at once (X-0266); the fuse held at 0.633 s for 2 s.

**Sources.**
- Apple HIG "Launching": "Launch instantly ... sometimes they don't want to wait more than a couple of seconds"; "Restore the previous state ... Avoid making people retrace steps"; on iOS a launch screen should be "nearly identical to the first screen" and "Don't advertise" [GAP-PASS-4]. The logo is a splash, which Apple says belongs at the start of onboarding, not the launch screen.
- Apple HIG "Designing for games": "Provide great default settings ... and the player's accessibility settings"; "Design for the full-screen experience" [GAP-PASS-5].
- XAG 112: make the path to accessibility settings accessible "From the game's initial launch", for example by "Prompting players to configure accessibility settings as the first screen" (Minecraft Dungeons) [GAP-PASS-7].
- XAG 115: before any action that deletes or changes stored data, "provide the player an opportunity to review and correct the data or completely reverse the action" [GAP-PASS-9]. The game's keep-the-old-save-until-the-first-safe-point rule meets the intent without a dialog; say so on the title.
- XAG 117: scrolling content needs a way to pause, stop or hide it [GAP-PASS-11]. The credits' PAUSE SCROLL meets it.
- No primary source found that requires a Quit button on a desktop title. On macOS, ⌘Q and the window close work; on Windows and Steam Deck players expect an exit in the menu (derived; UNVERIFIED as a platform rule).

**Where this lands:** MENU-1 to MENU-6.

## 3. Desktop display

**Measured (route S, render.sh, the paused game resized to each window).** The project uses a 960 × 540 viewport, stretch mode `canvas_items`, aspect `keep` (project.godot:23-27). Bars, measured on the frames:

| Window | Picture | Bars | Share of screen lost |
|---|---|---|---|
| 960 × 540 | 960 × 540 | none | 0% |
| 1280 × 800 (Steam Deck, 16:10) | 1280 × 720 | 40 px top and bottom | 10% |
| 1440 × 900 (MacBook Air "looks like" class, 16:10) | 1440 × 810 | 45 px top and bottom | 10% |
| 1920 × 1080 | 1920 × 1080 | none | 0% |
| 2560 × 1600 (16:10) | 2560 × 1440 | 80 px top and bottom | 10% |

Frames S-0062 to S-0066 (first control), S-0164 to S-0168 (junction entry). Text scales with the picture: the 17 px dialogue is 17 px at 960 × 540, 22.7 px at 1280 × 720/800, 25.5 px at 1440 × 900 and 45.3 px at 2560 × 1600 (in window points; on a 2× Retina screen each point is two device pixels). World labels (13 px) are 17.3 px at 1280 × 800, above Steam Deck's 9 px floor. Apple's minimum game text is 10 pt on macOS and 13 pt default [GAP-PASS-5]: the 13 px labels at a 960 × 540 window would be 13 pt, at the default.

The game's fullscreen toggle set the window mode to fullscreen in the container, but the virtual screen did not resize the window (no window manager), so fullscreen layout was not judged.

**Already measured in the repo (not re-measured here).** docs/research-2026-10/data/audit.json (`perf`) and notes/perf-audit/ on an Apple M1 Pro: every state ran at 490-1,055 fps uncapped, worst p95 2.95 ms at 1920 × 937 (more than five times the 16.7 ms budget); the shipped 60 fps cap plus V-Sync measured 44-51 fps with the screen locked, which the audit itself marks UNVERIFIED until re-run on an awake display; launch to first title frame 0.93-1.17 s. So desktop performance is not the risk; frame pacing at 120 Hz and the 60-cap reading are unknowns that need a hands-on check on an awake Mac.

**Where this lands:** DISPLAY-1 to DISPLAY-3; PERF-1 note.

## 4. Small speakers (SOUND-6's basis)

PUI Audio's product sheet for its phone, tablet and laptop micro speakers: the 15 × 11 mm parts have "a class-leading resonant frequency below 600 Hz", and the 18 × 13 mm parts "an amazingly low resonant frequency of 320 Hz"; they are "purpose-built for ... smartphones, tablets, laptops" [GAP-PASS-19]. Below its resonance a sealed driver's output falls steeply, so a phone-class speaker reproduces little below ~300-600 Hz (the exact −3 dB or −10 dB point depends on the phone's enclosure and DSP; no phone maker publishes it: UNVERIFIED per device). The game's `thud` has 99.3% of its energy below 150 Hz and `boom` 90.6% (audio-feel measurement): on a phone both are mostly inaudible. That supports SOUND-6 as a MUST. The "~1-4 kHz" layer band in the first synthesis has no source; the sourced floor is "above ~600 Hz", and the band is now marked derived. Laptop speaker response was not found from a primary source (UNVERIFIED).

## 5. Primary sources for weakly sourced MUST needs

- **FAIL-5 (help after repeated failure).** Iwata Asks NSMB Wii, re-opened: Miyamoto found the help block offered "from the beginning" insulting, and offered after losing "three times" still annoying ("Leave me alone!"); the team debated five against ten and settled on eight [GAP-PASS-23]. The MarioWiki citation is dropped. This also tempers the proposed 3-knockdown threshold: Nintendo chose 8 in a game with ~5 lives and short levels; for a ~20 s replay, 3 is a starting value to test, not a rule.
- **WOLF-5 and WOLF-11 (acknowledge at once; a refusal reads as a decision).** Game Informer's review (Joe Juba, 2016): "You might tell Trico to jump to a ledge three times, only to have it stare at you or walk off in the opposite direction – then oblige on your fourth try"; after ~15 minutes stuck he concluded it "feels like the controls aren't working" [GAP-PASS-20]. Ueda's own intent, from Edge via Kill Screen (2016): "it doesn't always do what you ask it to do", and Trico "is bound to both frustrate and delight players, but that's intentional" [GAP-PASS-21]. The PlayStation Blog interview (2016) was re-opened and has nothing on commands [GAP-PASS-22]. The Guardian original of the "pet / nuisance" quote could not be fetched by our tools (UNVERIFIED at source, unchanged).
- **STORY-1 (keep control).** Cory Barlog, via GamingBolt's report of his Eurogamer interview (2017): "The vocabulary of film is camera cuts ... But games are different. We don't really need to do that"; "There's never going to be a situation where we cut away" [GAP-PASS-24]. Eurogamer's page itself was not opened (secondary report).
- **STORY-5 (choices and memory).** Kevin Bruner's postmortem (Game Developer magazine, March 2013): when Telltale went "all in" on choice they iterated fast, "adding features like 'choice notifications,' onscreen inventory, panic meters"; "smaller, more intimate details often worked much better ... than giant, sweeping, branching opportunities" [GAP-PASS-25]. GDC 2013 "Saving Doug" (Jake Rodkin, Sean Vanaman), reported by Game Informer: 75% of players saved Carley and 25% Doug, because "We never gave the player the chance to learn who Doug is as a character" [GAP-PASS-26].
- **STORY-9 (story and play agree).** Clint Hocking's own post [NARRATIVE-IN-PLAY-29] carries the need; the Wikipedia summary [NARRATIVE-IN-PLAY-30] is dropped from it.
- **Valve commentary (about 15 MUSTs).** The five most-cited quotes (Episode One "Hurry up" / "make the player hate Alyx"; Episode Two's "numerous times in the first five minutes" falls; Portal's "tell us the story back"; Ravenholm's "without any room for tension building"; the Citadel birds) could **not** be re-checked against a recording: our tools cannot play the commentary audio, and the Episode One/Two caption files were not found in any public repository. Valve ships commentary text as caption strings (Team Fortress 2's `closecaption_english.txt` holds every node verbatim [GAP-PASS-29]), so a check against the game's own caption file is possible on a machine with Half-Life 2 installed. Until then these stay "verified against the fan transcript (Combine OverWiki, Portal Wiki), not against the recording"; none is marked UNVERIFIED because none failed a check.

## 6. Accessibility depth (XAG beyond 101-118)

- **XAG 106 Screen narration** [GAP-PASS-12] and Godot 4.5's AccessKit: "we added screen reader support to Control nodes, and ... screen reader bindings in order to customize the behavior of any type of Node"; the feature is "still in its experimental phase" [GAP-PASS-13]. The game is on Godot 4.7.2, so menu narration is available to try (COULD).
- **XAG 112 / 113 UI navigation and focus** [GAP-PASS-7] [GAP-PASS-8]: see §1 (BACK unreachable by D-pad in CONTROLS).
- **XAG 115 Error messages and destructive actions** [GAP-PASS-9]: see §2 (keep the save until the first safe point; say so).
- **XAG 116 Time limits** [GAP-PASS-10]: for UI time limits, an option "up to at least ten times the length of the default limit" or off; for text that times out on screen, the player can lengthen it "up to at least ten times". The fuse (1.0 s) and the tank window (~0.34 s / 0.21 s) are core-mechanic limits outside 116's UI scope, but its 10× rule is a sensible reach for a game-speed assist (A11Y-1). The objective card's 3.4 s display (main.gd:3203) is a UI time limit in 116's sense.
- **XAG 117 Visual distractions** [GAP-PASS-11]: options to turn off camera shake and to pause scrolling text; Reduced Motion covers shake and hit-stop (game_settings.gd:208).
- **Colour vision.** Simulated with Machado, Oliveira and Fernandes (2009) at severity 1.0 in linear sRGB [GAP-PASS-15] on the junction's state colours (junction_room.gd:216-221, :266). Closest pairs (CIE76 ΔE): normal vision AMBER/MARK_LIT 34.6; protanopia GREEN/MARK_LIT 16.4; deuteranopia AMBER/SEAM_RED 17.2; tritanopia GREEN/COOLANT 18.0. All pairs stay apart, but less than half as far as for normal vision. On frames (X-0297, X-0219 under each simulation): **the sentry's red sight beam almost disappears for protanopia and deuteranopia** (it turns dark olive on a dark background), and the red "BREAKER TRIPPED" label turns the same olive as the other labels. Words and shapes still carry the label states; the beam does not (FAIL-1, A11Y-3).
- **Flashes.** WCAG's thresholds: a general flash is "a pair of opposing changes in relative luminance of 10% or more" with the darker image "below 0.80"; flashes may cover no more than "25% of any 10 degree visual field" (a 341 × 256 rectangle at 1024 × 768) [GAP-PASS-14]. Measured on two 180-frame (3 s at 60 fps) render.sh sequences of the fuse and blast knockdown ([CAPTURE-ROUND2.md](../playthrough/CAPTURE-ROUND2.md)): with Reduced Motion off, the stripes reach up to 20 transitions per pixel in a second, but the area flashing more than 3 times a second peaks at 2.4% of the screen and 10.2% of the worst 10° window; no saturated-red flash; the biggest single-frame change covers 6.6% of the screen. With Reduced Motion on, at most 7 transitions per pixel and 0.02% of a window. **Below WCAG's general and red flash thresholds on this estimate** (software render, JPEG frames at 640 × 360 for analysis); a phone or monitor check is still needed.

## 7. Localization readiness

No decision records target languages (docs/decisions.md; none found). W3C's "Text size in translation" (Richard Ishida), from IBM's guidelines: English text up to 10 characters grows 200-300% in translation, 11-20 → 180-200%, 21-30 → 160-180%, 31-50 → 140-160%, 51-70 → 151-170%, over 70 → 130%; "Allow text to reflow and avoid small fixed-width containers" [GAP-PASS-16]. Applied to the game: the approved item names are 11-17 characters (item-text-2026-10-09.json), so a translation would run ~20-34 characters against the brief's 24-character limit; a 42-character subtitle line would need ~59-67 characters of room or a third line. The bundled fonts (fc-query on `assets/fonts/`): Roboto covers Latin, Greek, Cyrillic and Vietnamese; Montserrat covers Latin, Cyrillic and Vietnamese; neither covers CJK, Arabic, Hebrew, Devanagari or Thai. Roboto lacks ◀ ▶ (U+25C0, U+25B6); Montserrat has them.

## 8. Licences and credits

Godot's "Complying with licenses": "the only requirement is to include the license text somewhere in your game", in a credits screen, a licences screen, an accompanying file or similar, with the line "Copyright (c) 2014-present Godot Engine contributors. Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.", and the third-party notices (`COPYRIGHT.txt`, or `Engine.get_license_info()` / `Engine.get_copyright_info()`) [GAP-PASS-17]. The in-game credits (main.tscn:651) list "Godot 4.7.2 / GDScript" under BUILT WITH but no licence text; apps/docs credits.mdx has no Godot licence notice either. Roboto and Montserrat (SIL OFL 1.1) are credited.

## 9. Showing that WOLF remembered (choice signalling)

- Telltale added on-screen "choice notifications" while iterating, and found "smaller, more intimate details" beat big branches [GAP-PASS-25]; players followed the characters they had spent time with (75/25) [GAP-PASS-26].
- Oxenfree's lines are sized to walks and players can interrupt or stay silent [NARRATIVE-IN-PLAY-19] [NARRATIVE-IN-PLAY-20] (already in SOURCES).
- Night in the Woods and Kentucky Route Zero: no primary source on their choice signalling was found in this pass (still open).
- Measured in the game (headless probes over routes D, M, X, C): WOLF's spoken answer appears **1 frame (17 ms)** after every choice; his body changes at frame 1 only when the choice sends him somewhere (the mirror readout, the bait run). After the relay refusal (D) his sprite flips at frame 1 but nothing else; after the lane refusal and "Stay back, I'll time it" there is **no body change within 2 s**. A growl plays on both lane answers; the relay answers are silent. His memory is told later by callback lines (D-0106, D-0213) and the end card. Telltale's notices are the opposite approach (an explicit UI note); STORY-9 rules out a meter, so the need is a visible body reaction at once plus a later callback, with no "WOLF will remember that" text (STORY-19).

## 10. Phones and tablets

- Apple's HIG lists iPadOS default input as touch with "Game controller, keyboard, mouse, trackpad, Apple Pencil" as additional methods, and macOS keyboard, mouse and trackpad with game controller as additional [GAP-PASS-5]; touch buttons at least 44 × 44 pt for frequent controls and 28 × 28 pt for menus, a thumbstick "wherever the player lands their thumb", controls "where they don't overlap ... the Home indicator or Dynamic Island" [GAP-PASS-2].
- Android "Custom back navigation" (updated 2026-08-14): Android keeps a back stack, and Android 13+ adds predictive back, which "We strongly recommend" supporting [GAP-PASS-18]. The game walks Back out of nested menus one step at a time and quits only from the bare title (main.gd:1452-1469); predictive-back behaviour under Godot was not tested (UNKNOWN until a device test).
- iPad 4:3 and 19.5:9 stills: [CAPTURE-ROUND2.md](../playthrough/CAPTURE-ROUND2.md), route S-touch.

## 10b. Flip-screen to scrolling camera, and a 2.5D peer

- Oddworld: New 'n' Tasty (Just Add Water): Stewart Gilray, quoted from Eurogamer by God is a Geek (2012): with flip screens "You had to make your decision before you went through the screen flip ... But with this, because you can see farther in front of you, you can make that change in your gameplay there and then without having to go, I've died" [GAP-PASS-27]. This supports look-ahead (FEEL-6) and seeing a hazard before it acts (PUZ-5).
- Somerville (Jumpship, 2022), Video Games Chronicle review (Chris Scullion): the game "has no qualms about zooming all the way out to not only show how alone the player is, but also show the scale" [GAP-PASS-28]. A pulled-back camera sells scale; on a phone it shrinks the characters (PHONE-13). No developer interview on its camera was found (open).

---

## Sources (round 2 gap pass)

| Id | Creator | Title | Venue, year | URL |
|---|---|---|---|---|
| GAP-PASS-1 | Microsoft | Getting Started With XInput in Windows applications | Microsoft Learn, 2025 | https://learn.microsoft.com/en-us/windows/win32/xinput/getting-started-with-xinput |
| GAP-PASS-2 | Apple | Human Interface Guidelines: Game controls | Apple Developer, 2025 | https://developer.apple.com/design/human-interface-guidelines/game-controls |
| GAP-PASS-3 | Valve | Steam Deck Compatibility Review Process (Verified criteria) | Steamworks documentation, current 2026 | https://partner.steamgames.com/doc/steamdeck/compat |
| GAP-PASS-4 | Apple | Human Interface Guidelines: Launching | Apple Developer, current 2026 | https://developer.apple.com/design/human-interface-guidelines/launching |
| GAP-PASS-5 | Apple | Human Interface Guidelines: Designing for games | Apple Developer, 2025 | https://developer.apple.com/design/human-interface-guidelines/designing-for-games |
| GAP-PASS-6 | Microsoft | Xbox Accessibility Guideline 110: Haptic feedback | Microsoft Learn, 2026 | https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/110 |
| GAP-PASS-7 | Microsoft | Xbox Accessibility Guideline 112: UI navigation | Microsoft Learn, 2026 | https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/112 |
| GAP-PASS-8 | Microsoft | Xbox Accessibility Guideline 113: UI focus handling | Microsoft Learn, 2026 | https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/113 |
| GAP-PASS-9 | Microsoft | Xbox Accessibility Guideline 115: Error messages and destructive actions | Microsoft Learn, 2026 | https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/115 |
| GAP-PASS-10 | Microsoft | Xbox Accessibility Guideline 116: Time limits | Microsoft Learn, 2026 | https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/116 |
| GAP-PASS-11 | Microsoft | Xbox Accessibility Guideline 117: Visual distractions and motion settings | Microsoft Learn, 2026 | https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117 |
| GAP-PASS-12 | Microsoft | Xbox Accessibility Guideline 106: Screen narration | Microsoft Learn, 2026 | https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/106 |
| GAP-PASS-13 | Godot Engine (feature by Pāvels Nadtočajevs, bruvzg) | Godot 4.5 release: screen reader support (AccessKit) | godotengine.org, 2025 | https://godotengine.org/releases/4.5/ |
| GAP-PASS-14 | W3C (WAI) | Understanding Success Criterion 2.3.1: Three Flashes or Below Threshold | WCAG 2.2 Understanding, current 2026 | https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html |
| GAP-PASS-15 | Gustavo M. Machado, Manuel M. Oliveira, Leandro A. F. Fernandes | A Physiologically-based Model for Simulation of Color Vision Deficiency | IEEE TVCG 15(6), 2009 (authors' page with matrices) | https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html |
| GAP-PASS-16 | Richard Ishida (W3C), citing IBM's globalization guidelines | Text size in translation | W3C Internationalization, current 2026 | https://www.w3.org/International/articles/article-text-size |
| GAP-PASS-17 | Godot Engine documentation | Complying with licenses | docs.godotengine.org (stable), current 2026 | https://docs.godotengine.org/en/stable/about/complying_with_licenses.html |
| GAP-PASS-18 | Android Developers (Google) | Provide custom back navigation | developer.android.com, 2026 | https://developer.android.com/guide/navigation/custom-back |
| GAP-PASS-19 | PUI Audio, Inc. | Slim-Line Micro Speakers (new product feature; AS01508AO, AS01808AO) | manufacturer product sheet, 2016 (PDF mirror) | https://static.chipdip.ru/lib/573/DOC011573867.pdf |
| GAP-PASS-20 | Joe Juba | The Last Guardian Review | Game Informer, 2016 | https://gameinformer.com/games/the_last_guardian/b/playstation4/archive/2016/12/05/the-last-guardian-review-game-informer |
| GAP-PASS-21 | Caty McCarthy, relaying Fumito Ueda's interview in Edge | Don't worry: The Last Guardian is still coming out in 2016 | Kill Screen, 2016 | https://www.killscreen.com/dont-worry-last-guardian-still-coming-2016/ |
| GAP-PASS-22 | Corey Brotherson (interviewing Fumito Ueda) | The Last Guardian: 5 storytelling secrets | PlayStation Blog, 2016 | https://blog.playstation.com/2016/06/21/the-last-guardian-5-storytelling-secrets/ |
| GAP-PASS-23 | Satoru Iwata with Shigeru Miyamoto (Nintendo) | Iwata Asks: New Super Mario Bros. Wii, Volume 1 (hint block after 8 lost turns) | Nintendo, 2009 | https://iwataasks.nintendo.com/interviews/wii/nsmb/0/5 |
| GAP-PASS-24 | Cory Barlog, reported by GamingBolt from Eurogamer | God of War Director Reveals Why The Game Will Have No Camera Cuts | GamingBolt, 2017 | https://gamingbolt.com/god-of-war-director-reveals-why-the-game-will-have-no-camera-cuts |
| GAP-PASS-25 | Kevin Bruner (Telltale Games) | Classic Postmortem: Telltale Games' The Walking Dead | Game Developer (first printed in Game Developer magazine, March 2013) | https://www.gamedeveloper.com/design/classic-postmortem-telltale-games-the-walking-dead-2012 |
| GAP-PASS-26 | Kimberley Wallace, reporting Jake Rodkin and Sean Vanaman (GDC 2013, "Saving Doug") | Telltale: Why Fewer People Saved Doug In The Walking Dead | Game Informer, 2013 | https://www.gameinformer.com/b/news/archive/2013/03/28/telltale-why-fewer-people-saved-doug-in-the-walking-dead.aspx |
| GAP-PASS-27 | Colm Ahern, quoting Stewart Gilray (Just Add Water) from Eurogamer | Abe's Oddysee HD Becomes New N' Tasty at Eurogamer Expo | God is a Geek, 2012 (read via the Wayback Machine) | https://www.godisageek.com/2012/10/abes-oddysee-hd-n-tasty-eurogamer-expo/ |
| GAP-PASS-28 | Chris Scullion | Somerville review | Video Games Chronicle, 2022 | https://videogameschronicle.com/review/somerville |
| GAP-PASS-29 | Valve, via the SteamTracking project | Team Fortress 2 `tf/resource/closecaption_english.txt` (commentary nodes as caption strings) | GitHub (GameTracking-TF2), current 2026 | https://github.com/SteamTracking/GameTracking-TF2/blob/master/tf/resource/closecaption_english.txt |

All opened 2026-10-13. Limits: GAP-PASS-13's page summary was read through a fetch tool, and its stated date was inconsistent; Godot 4.5 shipped in 2025 (the engine's own release list). GAP-PASS-24 is a secondary report of a Eurogamer interview. GAP-PASS-21 relays an Edge print interview. GAP-PASS-27 was read from an archived copy.

*Compiled 2026-10-13 with AI assistance (Claude Code by Anthropic) for Nathanial Henniges.*
