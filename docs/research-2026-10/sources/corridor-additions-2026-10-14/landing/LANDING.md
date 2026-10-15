# Landing the corridor additions on main (2026-10-14, fixed 2026-10-15)

Branch `codex/corridor-additions` from origin/main c5d1d84. What was ported and why is in `../README.md` ("The landing"). This file says how it was checked. Nothing was played by hand, so it makes no claim about how the door end, the flash, the crank or WOLF's walk feel.

## Player-facing text

- **In-game, new (no old text):** the sign `RESTRICTED AREA` above the door. It is typeset by script in the game's bundled Roboto (`../integrate/tools/package7.py`, carried through `../fix*/tools/package*.py`), not painted by the image tool. `SECTOR 4B` and `DOOR 4B-07` were already on main (round 6) and are unchanged.
- **In-game, unchanged:** no story, WOLF or narration line was added, removed or reworded ("We made it." and "Open. I'm with you." are untouched).
- **Website and in-game changelog:** a new section "October 15, 2026" with the door-end entry and its Website entry (moved there from October 14 on 2026-10-15, as the merge cannot happen before then). In the October 14 WOLF entry, old: "Once the corridor's door is open he follows you no further than the relay's left side and waits there, facing you, while you go on to the safe point, instead of standing over the MANUAL BYPASS and in the doorway; this is a stopgap until the corridor's door end is redrawn with room for him." New: "Once the corridor's door is open he follows you no further than the relay's left side while you walk through, instead of standing over the MANUAL BYPASS and in the doorway; at the safe point itself he now comes to the open doorway (see the door end entry above)." The corridor walkthrough, Settings, Credits and Testing pages change as listed in `../README.md`.

## Deviations from the must-fix checks, to be accepted

- **High-pass detail in the review's box** (atlas x 728-840, y 296-338) was asked to be 3 or less. Over the whole box it is 5.51 after the repaint (5.82 before; the landing verifier's sigma-2 measure: round 6 2.76, round 11 5.03, landing 4.85), because the box holds the head plate's designed joints, the parked inner leaf's stripes and the doorway's alpha edge, none of which were in round 6. Over the repainted plate paint it falls from 2.62 to 1.45 (round 6: 1.42; the verifier: 2.73 to 1.55), and the 5x stretched and high-pass crops show no letter shapes (`atlasfix/`).
- **Byte identity with round 11** was asked for every corridor state and opening frame at 1280x720. 19 of 29 frames are byte-identical; the other 10 differ only in the ceiling lamps' run-to-run flicker at the top of the screen, with 0 door-end pixels changed. The verifier also showed the door end cannot change: all 1,633 changed atlas pixels sit under hood pixels that are fully opaque (minimum alpha 255) within 2 world px all round, and the hood is drawn whenever the corridor is.

## Fixes after the landing verification (2026-10-15)

- **Changelog date:** the door-end entry and its Website entry now sit under October 15, 2026; the in-game changelog was regenerated (`scripts/export_changelog.py`) and the drift check is green.
- **WOLF walking to and fro by the doorway:** the verifier saw him set off for the doorway with the engineer at x 806 and walk back when they stepped to 794, each time about 200 px. He now sets off only once the engineer is at the safe point's near edge (x 824, `WOLF_DOORWAY_HOLD_X` 800 plus `WOLF_DOORWAY_HYSTERESIS` 24) and, once set off, keeps the doorway until they are back within a clear gap of him (x 800), so the bodies still never overlap. `wolf_space_test` gained two edge cases on all three relay answers: walking to and fro between x 788 and 812 from the relay's left, and between 812 and 840 from the doorway, with 0 changes of mind allowed. With the hysteresis set to 0 the first case fails on every route (5 changes of mind each).
- **`room_lights_test` under load:** the "a new game brings the corridor's pulse back" check had to catch the lens at the brief top of a flash inside 0.9 s of wall-clock time and failed once at a load average of about 127. It now reads the lens as the new game sets the beacons back, before the flash has run a frame, then checks the flash runs.
- **Repaint pixel count:** the README, provenance and the asset register said 1,702 px; the repaint changed 1,633 px (repaint mask 1,793 px), as `atlasfix/report12.json` and the verifier's diff of the round 11 atlas against the landing atlas both give.
- **decisions.md:** the stopgap sentence in the now-built decision is in the past tense.

Evidence for the fixes (2026-10-15; nothing played by hand):

- **Headless, alone:** `wolf_space_test` passes at 43 rest points (40 before, plus the edging cases); `room_lights_test` passes. Mutation: `WOLF_DOORWAY_HYSTERESIS` set to 0 fails `wolf_space_test` on all three relay answers.
- **`bun run game:check`:** 21 of 21 at a load average of about 12. Further runs were made on a machine shared with other jobs at a load average of 19 to 165, five on the branch and four on an untouched copy of c5d1d84 (two run side by side with branch runs), and each failed some timing-bound suites on both alike: `studio_logo_test` (its "closing fade is quick" timing), `crank_hold_test` (the valve's press-frame click), `debug_tools_test` (capture wait and note placement), `approved_wording_test` (reading-time margins), and on main also `junction_test` and `sfx_bank_test`. `studio_logo_test` run alone 8 times on each, 8 at once: the fade timing failed 7 of 8 on both. One branch run also showed an engine error during the logo's threaded load (`Initializing already initialized RID`, then `Parameter "t" is null` in the dummy texture storage) and once `ui_controls_test` leaked 2 objects at exit; neither came back in the other runs, and neither was seen in the main runs. They stay open below.
- **Docs:** `docs:check`, `docs:test` and `docs:build` pass; the changelog drift check is green.
- **Stills:** `land-corridor-fix-desk` (render.sh, 1280x720, routes A and B): every shot's state (positions, facing, door, leaf, crank frame) matches the earlier `-after-desk` run exactly, WOLF at 716.0 facing the engineer at s7. The pixels differ only in the ceiling lamps' flicker (screen y 0-63), the left beacon's flash phase and their reflections on the floor (screen y 512-575), as that run also played the opening first; nothing differs near WOLF or the engineer.

## Evidence

- **Headless logic:** `bun run game:check` twice on the final game (import twice, 21 suites, 4 at a time, on a machine at a load average of about 28). First run: 20 of 21; `studio_logo_test` failed (a texture error at close and its "closing fade is quick" timing). Second run: 21 of 21. Run alone, `studio_logo_test` passed 3 of 3 on the branch and 3 of 3 on main; run six at a time it failed its fade timing on both (6 of 6 on the branch, 4 of 6 on main), so its timing is load-sensitive on main too. The texture error was not seen again in those 12 runs; it is listed as open.
- **WOLF space:** `wolf_space_test` passes at 40 rest points. A negative run with `WOLF_DOORWAY_X` moved to 740 failed (the near column hid 412 to 536 of his samples), so the doorway measure catches a spot behind the column (`logs/`).
- **Docs:** `bun run docs:check`, `docs:test` and `docs:build` pass.
- **Rendered stills:** `tools/render/render.sh` only (Godot 4.7.2, Xvfb and Mesa in a container), no window on the Mac, with `driver/realslice_capture.gd` (round 8's driver run on all three routes in one Godot run per size). Runs: `land-corridor-before-desk` and `-before-phone` (an untouched `git archive` of c5d1d84), `-after-desk` and `-after-phone` (the branch), at 1280x720 and 2400x1080 with the touch layout; `-before-perf` and `-after-perf` for the measurements; `-r11-desk` and `-r12-desk` for the atlas repaint. Frames: the corridor states s1 (door end at rest), s2 (WOLF taking the relay), s3 (the bypass crank, with crank frames B and A), s4 (the door opening), s4b (the inner leaf moving), s5 (open), s6 (walking through), s7 (the safe point, "We made it." on route A) and the opening o0-o8. The stills stay in scratch; they are not filed.

## What the stills show

- **Against the approved round 11** (same states; round 11's 1280x720 and phone captures): the door end looks the same: blast frame and jamb plates, `RESTRICTED AREA`, inner leaf in s4 and s4b and parked in s5-s7, beacons, crank frames on the rim in s3, relief spray, luminaire clear of PAUSE, the cutaway and WOLF in the doorway at s7 (x 716.0, facing the engineer). What differs is main's newer text and UI: box wording and line breaks, the fault tag gone at the safe point (main's #63), and in the phone shape main's touch buttons and DEBUG button.
- **Against main (before):** at s7 WOLF stands in the doorway instead of on the relay's left (x 500.8 on main). COOLANT FAULT is gone at the safe point in both.
- **The opening, o0-o8, against main:** no pixel differs by more than 3 levels except within 63 world px of the left beacon (the new caged lamp and its light in place of main's drawn beacon and glow), in both sizes; o7 and o8 also differ right of world x 540, which is the door end. Left of x 540 outside the beacon, 0 px. (`tools/compare_land.py`; desk: o1 160 px and o3 24 px past a 60 px zone, all within 62.2 px of the beacon; phone the same.)
- **The atlas repaint, round 11 against the landing, same copy and driver:** 0 pixels of the door end changed in any of the 29 frames at 1280x720; 19 are byte-identical and 10 differ only at the top of the screen in the ceiling lamps' run-to-run flicker (at most 12 levels, screen x 0-660, y 0-121) (`atlasfix/identity12.json`).

## A first-time player's look (stills only)

- The corridor ends at a heavy concrete wall with a bolted steel frame round a shutter, `DOOR 4B-07` on its hood, `RESTRICTED AREA` above, red caged lamps on the wall and a camera: a locked-down, guarded place. The wheel beside the shutter with its `MANUAL BYPASS` plate and the red pillar lamp say what to try.
- Cranking, the engineer leans into the wheel with both hands on its rim and coolant spits down from a pipe on the relay. Opening, the shutter rolls up and a striped inner door slides away; open, only its striped edge stays in the wall. Nothing hovers and every door has somewhere to go.
- At the safe point WOLF stands in the open doorway, head through, facing the engineer, wholly in view. The handwheel behind him is hidden by his body at that moment; it is done with by then.
- Still odd, and inherited (listed below): the station names float over the machines, WOLF's surge at the relay is a pale cloud with a zigzag, and the narration at s2 says "The red seal opens" although nothing on the door is red but its lamp.

## Performance (render.sh at 1280x720, 300 uncapped frames per held state; headless CPU on the host)

| State | Draw calls p50 (max) | Additive items | Overdraw estimate | Full-screen translucent layers | Texture MB | Video MB | Nodes | Headless CPU frame p50 / p99 ms |
|---|---|---|---|---|---|---|---|---|
| s1-door-end-rest | 54 (54) -> 47 (47) | 7 -> 7 | 3.54 -> 3.47 | 2 -> 2 | 75.95 -> 76.78 | 84.36 -> 85.18 | 554 -> 557 | 0.24 / 0.85 -> 0.23 / 0.65 |
| s2-relay-wolf | 58 (58) -> 52 (52) | 7 -> 7 | 3.47 -> 3.39 | 2 -> 2 | 75.95 -> 76.78 | 84.36 -> 85.19 | 554 -> 557 | 0.21 / 0.39 -> 0.24 / 0.54 |
| s3-bypass-crank | 55 (55) -> 48 (48) | 7 -> 7 | 3.53 -> 3.45 | 2 -> 2 | 75.95 -> 76.78 | 84.36 -> 85.18 | 554 -> 557 | 0.51 / 1.56 -> 0.22 / 0.58 |
| s4-door-opening | 54 (54) -> 48 (48) | 7 -> 7 | 3.49 -> 3.42 | 2 -> 2 | 75.95 -> 76.78 | 84.36 -> 85.19 | 554 -> 557 | 0.20 / 0.48 -> 0.25 / 0.45 |
| s4b-leaf-moving | 54 (54) -> 48 (48) | 7 -> 7 | 3.46 -> 3.39 | 2 -> 2 | 75.95 -> 76.78 | 84.36 -> 85.19 | 554 -> 557 | 0.22 / 0.50 -> 0.31 / 0.88 |
| s5-door-open | 52 (52) -> 45 (45) | 7 -> 7 | 3.49 -> 3.42 | 2 -> 2 | 75.95 -> 76.78 | 84.36 -> 85.18 | 554 -> 557 | 0.25 / 0.48 -> 0.35 / 1.68 |
| s6-walk-through | 52 (52) -> 45 (45) | 7 -> 7 | 3.45 -> 3.37 | 2 -> 2 | 75.95 -> 76.78 | 84.36 -> 85.18 | 554 -> 557 | 0.24 / 0.49 -> 0.33 / 1.10 |
| s7-safe-point | 52 (56) -> 44 (48) | 7 -> 7 | 3.46 -> 3.39 | 2 -> 2 | 75.95 -> 76.78 | 84.36 -> 85.18 | 554 -> 557 | 0.24 / 0.78 -> 0.31 / 2.05 |

- **Better:** 6-8 fewer draw calls in every state (the beacons draw from one atlas and the inner leaf batches with the roller), and a slightly lower overdraw estimate.
- **Same:** 7 additive items, 2 full-screen translucent layers (the haze and the mid plate).
- **Cost:** +0.83 MB of texture memory (the crank and beacon atlases) and 3 nodes (BlastLeaf and the two control-marker canvas items).
- **Where it stands against the lighter-game targets** (`../../../art-direction/REAL-LOOK.md`, section 5): overdraw about 3.4 against 2.0 and texture memory about 76.8 MB against 45 MB. Both were over before this landing (3.5 and 76.0 on main) and still are; this change does not fix them. They belong to the lighter work (the full-screen haze layer, the far plates' size).
- Frame times inside the container are software rendering and mean nothing; the headless CPU medians (0.2-0.35 ms) were taken at a load average of 25-60 and only show nothing heavy was added.

## Open, for later jobs

- Inherited and unchanged: WOLF's surge cloud at the relay (s2); the floating station name plates; the narration's "The red seal opens"; the shutter's slats against the sloping hood; the roller's striped bottom bar under the hood's end when open; three yellows open and three reds shut; the Records and junction beacons still drawn in code; the inner leaf's bogie box reading like a vent box; the thin conduit behind the band's corner; the `RESTRICTED AREA` plate's open choices; the crank pose to be cut again from the approved walk frames.
- Overdraw and texture memory over the lighter-game targets (above).
- The review box's whole-box high-pass figure stays at 5.5 because it holds designed joints, the leaf's stripes and the doorway's edge; the lettering itself is gone (`../README.md`).
- `studio_logo_test`'s engine error in the threaded load (seen three times in about nine full runs on the branch under heavy load, never alone and not in the two full runs on main), and one leak at exit in `ui_controls_test` under load.
- Nothing played by hand; no phone, device or export test.
