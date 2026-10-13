# Round 2 captures: failures, front end, controller, display sizes (2026-10-13)

> **In the repository:** only the 60 frames the audit cites are kept, as WebP, in [frames/](README.md). Links below point to them when kept; other frame names are plain text. Logs, probes, drivers and contact sheets stayed in the session scratchpad.

WOLF//OVERRIDE is by **Nathanial Henniges**. These captures close the critic's capture gaps (G4-G7, G16, G19, G23). Same build as round 1: game code at `baffea4`, identical to `da5c14e` and to `main` at `36788ff` (`git diff baffea4 HEAD -- apps/game` is empty). Exported tree: `play-research/game/apps/game` in the session scratchpad.

**No window was opened on Nathanial's Mac.** Logic dry runs: `godot --headless --fixed-fps 60` with an isolated HOME (`round2/home`). Rendered runs: `tools/render/render.sh` (Linux container, Xvfb, Mesa llvmpipe), one unique `--name` per run:

| Route | `--name` | Screen | What it does | Frames | Game time |
|---|---|---|---|---|---|
| X | `play-research-failures` | 1280 × 720 | Disclose route to the junction; USE at the valve before the breaker and at the sealed door; stand on the relief vent (vent knockdown); a blast knockdown recorded every frame (Reduced Motion off), Reduced Motion turned on in Settings, the same knockdown every frame again; `NOTIFICATION_APPLICATION_FOCUS_OUT` mid-fuse with the default auto-pause; the lane alone with a deliberate miss and a chase knockdown; a second miss and a walk into the coolant cloud (cloud knockdown); the lane with WOLF, DROP pressed too early, then the hit; USE on spent stations; the exit | 370 + 2 × 180 burst | 286.7 s |
| F | `play-research-frontend` | 1280 × 720 | Starts from `studio_logo.tscn` like a real launch (a frame every 0.25 s); Credits (0, 5, 15 s), Changelog, title Settings, New Game, Pause in the opening (SKIP OPENING), the corridor and Records, Pause and RETURN TO TITLE mid-junction, Continue, the rest of the junction, the end card, Esc on the bare title, PLAY AGAIN, Pause, SKIP OPENING | 275 | 204.1 s |
| C | `play-research-controller` | 1280 × 720 | Every input is an injected `InputEventJoypadButton` or `InputEventJoypadMotion` (device 0); menus by D-pad and A; an analog-stick speed sweep; the press route (WOLF refuses; the MANUAL BYPASS cranked by holding A); Records alone; START, Settings (each tab), B; a blast knockdown; WOLF asked, then the timed drop with A; the end card with A; rumble polled every frame | 262 | 200.7 s |
| S-desk | `play-research-sizes-desktop` | 2560 × 1600 | At title, opening, first control, relay choice, junction entry, lane choice, DROP ready and the end card, the tree is paused and the window set to 960 × 540, 1280 × 800, 1440 × 900, 1920 × 1080 and 2560 × 1600; then the Fullscreen toggle | 231 | 150.8 s |
| S-touch | `play-research-sizes-touch` | 2732 × 2048 | The same moments with the touch layout, at 2732 × 2048 (12.9-inch iPad, 4:3) and 2556 × 1179 (iPhone 16 class, 19.5:9) | 204 | 149.1 s |

Command (X; the others change `--name`, `--screen`, `--route` and add `--sizes=` or `--touch=1`):
`tools/render/render.sh --screen 1280x720 --name play-research-failures --driver round2/driver-render --timeout 5400 game/apps/game round2/render/X -- --fixed-fps 60 --script res://review_capture/play2.gd -- --route=X --out=/work/out --size=1280x720`

Files here: per route `_log.jsonl` (one line per frame, as in round 1), `_probes.json` (press probes, choice probes, rumble, focus-out, analog sweep, burst rows, logo timings) and `_run.json` (notes and what was forced); `headless-D` and `headless-M` hold the press probes of the round-1 routes re-run headless; `driver/play2.gd`; `tools/` (contact sheets, flash measurement, colour-vision simulation, figure-ground contrast). The frames (about 1.1 GB) stay in the scratchpad at `play-research/round2/render/<route>/frames`.

## What the driver forced
- Same rules as round 1 (no teleports, no state writes; save and settings at fresh `user://play-research-*` paths, except route F, which used the defaults inside the throwaway container). Route X kept the game's default `auto_pause_on_focus_loss` (true), because it is tested; the other routes turned it off.
- Route F instantiated `studio_logo.tscn` and let it hand over to `main.tscn` itself.
- Route C: when the D-pad could not reach Settings' BACK, the driver pressed B instead (B works); when testing that, nothing was forced. No pad button was replaced by a key.
- Route S paused the tree while resizing, so all sizes show the same game moment.
- The fullscreen toggle set the window mode to fullscreen, but the container's virtual screen has no window manager and did not resize the window; fullscreen layout was not judged.
- The credits did not scroll in the capture; drawing only on saved frames probably stopped the RichTextLabel's layout from updating, so the auto-scroll was not judged.

## Results (frame names are in each route's `_log.jsonl`)

**Press probes** (headless and rendered; 156 presses over routes D, M, X, C, F). For each USE or choice press: the frame offset of the first SfxBank sound (one-shot voice or loop start) and of the first text change.
- Sound within 1-3 frames on: the breaker (clank), the bypass start (klaxon), the junction entry (hum), the tank release (clank), the bolt (whine), the lane answers (growls), the cage release (boom). No sound on: the safe-point secure, the purge-queue copy, the mirror answer, the relay answers, WOLF taking the relay (at the press), the hatch exit, every opening advance and every invalid press.
- Invalid presses: valve before the breaker, breaker while building, spent valve, DROP too early, spent release: text within 1 frame, no sound, no light. USE beside the sealed door repeats the valve's line (no change on screen); 40 s of walking into the sealed door produced nothing.

**WOLF's response to choices** (choice probes, 15 choices): his line at frame 1 every time; his body moves at frame 1 only when sent (mirror, bait), turning at frame 66-83; after refusals, nothing within 120 frames except one sprite flip.

**Knockdown cards** (all five): BLAST D-0186 / C-0196; VENT X-0219; SENTRY seen D-0226; SENTRY chased X-0298; CLOUD X-0318. See FAIL-1.

**Flashes** (`burst-blast-rm-off`, `burst-blast-rm-on`, 180 frames each at 60 fps; tools/flash.py at 640 × 360): Reduced Motion off: up to 20 luminance transitions per pixel per second, area flashing > 3/s at most 2.4% of the screen and 10.2% of the worst 10° window, no red flash, largest one-frame change 6.6% of the screen. Reduced Motion on: ≤ 7 transitions per pixel, ≤ 0.02% of a window.

**Focus loss** (X-0266, X-0267): pauses at once; fuse held at 0.633 s for 2 s.

**Front end**: logo 0-2.0 s, main scene at 2.03 s, title buttons drawn at 2.25 s, wordmark complete ~3.0 s (F-logo-00.25s to F-logo-03.50s); no QUIT (F-0003); SKIP OPENING in the opening's pause (F-0030 → F-0261); RETURN TO TITLE mid-junction (F-0182) and CONTINUE restores the junction entry with the breaker to arm again (F-0188); PLAY AGAIN after the slice (F-0250).

**Controller**: analog speed 190 × (|v| − 0.25) / 0.75 px/s; rumble on 10 beats; prompts as letters; D-pad cannot reach BACK in Settings › CONTROLS, B closes it (C-0185, C-0187).

**Display sizes** (bars measured on the frames): 1280 × 800 → 40 px top and bottom; 1440 × 900 → 45; 2560 × 1600 → 80; 960 × 540 and 1920 × 1080 → none; 2732 × 2048 (iPad) → 256 px top and bottom (25% of the height), with the touch buttons in the middle third of the screen rather than at the lower corners (S-0056, S-0172); 2556 × 1179 → 230 px each side (S-0057, S-0180).

**Colour vision** (tools/cvd.py, Machado et al. 2009 matrices, severity 1.0, on X-0297 and X-0219): the sentry's red beam nearly disappears for protanopia and deuteranopia; the red "BREAKER TRIPPED" label matches the other labels; state-colour pairs keep ΔE ≥ 16.4.

**Figure-ground contrast** (tools/contrast.py on round-1 desktop frames D-0048, D-0095, D-0116, D-0131, D-0165, D-0205, D-0240): engineer 1.17-1.59:1, WOLF 1.16-1.69:1.

## Limits
Scripted inputs and software rendering, as in round 1. No audio was heard (Dummy driver; the probes watch SfxBank's players, not the speakers). Rumble was read from Godot's vibration state with no pad attached. Flash and contrast numbers are estimates from container frames, not a display or phone measurement. Nothing here validates feel.

*Captured 2026-10-13 by an AI agent (Claude Code by Anthropic) for Nathanial Henniges.*
