# The corridor's door end, in the real game (fix round 5)

Scratch only, 2026-10-12. No Git repository or worktree was edited (the repository is clean at baffea4), so there was nothing to commit or push. All changes are in `real-slice/game-slice`, the modified copy. `real-slice/game-main` is an untouched export of main 76d3a50 (plus the capture drivers the render runs copy in).

**How this was checked:**
- Headless logic tests: 13 of 13 pass in the slice after two imports (`logs6/tests-slice/`). `m0_scene_test` has one new check: the lamp conduit runs unbroken from the lamp box through its elbow into the camera's wall plate. On a private copy with round 4's atlas the check fails, with 21 breaks along the path (`fix6/work/negcopy/m0.log`).
- Rendered stills: every still was made with `tools/render/render.sh` (Godot 4.7.2 in the Colima container, software GL). No window opened on the Mac.
- Not done: nothing was played by hand, so this report makes **no feel claims**. No phone or export was tested.

**Review status:** this round answers the round-5 review (`REVIEW-round5.md`) item by item. It has not had its own review pass yet, and Nathanial has not seen it.

**Everything in this package is from the final build.**
- The slice's art last changed at 20:53 (`corridor-seal-atlas.png`, `corridor-far.png`), its code at 19:52 (`bypass_handle.gd`). The test file last changed at 21:06 (a comment re-wrapped after the captures; the tests were re-run after it).
- Slice captures ran 21:02-21:38 (`raw6/slice/`), all after the art change: the opening twice, routes A and B at 1280x720 and in phone shape, and both perf runs. CPU-side headless runs: 21:05.
- **Main was not re-captured:** it did not change. Its round-4 render.sh captures (`raw5/main/`, same driver, same container) are the "before" side of every pair and of the opening diff.
- The pairs, sheet, opening diff, checks, perf tables and `slice-code.diff` were made from these captures at 21:05-21:40.

## What to open

- `sheet.png`: the seven states before and after at 1280x720; s1, s5 and s7 in phone shape; the opening frames o5 and o7 with their diffs; and a last row of this round's close-ups (the conduit top and the camera's underside, round 4 against round 5).
- `pairs/<state>-720.png` and `pairs/<state>-phone.png` (phone: the 1920x1080 game image between 240 px pillar bars), single phone frames in `pairs/phone/`.
- `fix6-crops/` holds this round's crops, each beside its round-4 version (`*-round4.png`). `fix5-crops/` (round 4) is kept beside it.
- `raw6/slice/` holds this round's slice captures; `raw5/` (round 4, and main) and the earlier `raw4/`, `raw2/` and `raw/` are kept as their records.

## What changed in this round

### Must 1: the lamp conduit's top end (closed)

**Cause:** the 20 mm conduit up the near column's end face (`lamp_conduit_up`) ran straight up to 4.40 m and stopped with a plain cap. The spec said it comes "from the camera's box", but the camera's horizontal conduit ended at the column's corner, 0.25 m round the end face from it, and nothing joined them.

**What changed (the spec's own intent, option (a)):**
- `design/tools/portal6.py`: the vertical now stops at 4.3125 m, where a standard 90-degree conduit elbow (centre-line radius 100 mm) turns it toward the corner. A horizontal run at 4.41 m (the camera conduit's own height) crosses the end face to the arris, held by one saddle strap. It wraps the corner 20 mm proud of the jamb's 160 mm approach face and enters the side of the camera's wall plate. Four new part masks: elbow, run, corner, strap.
- `layers/tools/cleanup6.py` paints them with the vertical conduit's own painted steel: its measured cross-profile (wall shadow line, lit edge, highlight, body, far edge, cast shadow), laid across the run with the lit side up and blended round the elbow. The run casts a thin shadow on the concrete below it; the vertical's outer shadow line carries on round the elbow and fades. The strap is the conduit's highlight steel. The old capped top is painted out with the end face's own painted concrete, 12 px to the right on the same rows, light-matched.

**Measured (`fix6-checks.json` `must1_lamp_conduit_top`):**
- **Design:** the chain touches end to end (lamp cap -> vertical -> elbow -> run -> corner -> camera wall plate; `design/portal6/spec.json`).
- **Atlas grid (2 px per world px):** the conduit is one connected piece, it touches the lamp cap at its foot, and its top end reaches the camera's wall plate.
- **Atlas paint:** along the path (31 samples from the vertical up through the elbow and along the run to the plate's edge at world x 795.3), round 4 has 21 breaks; round 5 has **0**.
- **In game, world y 269.5, x 796.5-803.5 (the run):** round 4 shows bare concrete there (22.6 against 22.4 above). Round 5 shows the run, with a mean luma of 35.8 against 22.4 on the concrete above it at 720p, and 32.3 against 22.3 in phone shape, in s1, s5 and s7 alike.
- **Headless:** the new `m0_scene_test` check samples the same path in the column's atlas region and fails on any break, as described above.
- **Crops:** `must1-s1|s5|s7-A-720|A-phone-conduit.png`, each with `-round4`, plus `must1-s1-*-conduit-stretch.png`.

### Should 1: the documents describe what is drawn

`design/DESIGN.md`'s Parts table listed a mid-patch "relay feed: two 25 mm rigid conduits from the ceiling rack to the relay's roof". Round 1's `mid_patch.py` drew them, but since round 3 the mid plate has been rebuilt from main's (`install4.py`), and they are not in the installed build. The line now says so: the relay is fed from the floor through its plinth's brush-strip cable entry. Nothing was drawn to match the old line. The table also now says it is the round-0 list, and that the current front parts are in `portal6/spec.json` (for example, the camera at 4.35 m on the column, not 3.9 m on the return). This SLICE.md lists no relay feed.

### Should 2: a faint rim on the tank from the visible high-bay B (done)

It could be done deterministically, and it reads as light from B. High-bay B hangs over the tank's right half, about 2 m behind it and 0.35 m above its crown, so its light grazes the shell's right limb from behind. `cleanup6.py` adds that rim in linear light, in B's cool white:
- at most 4 source px wide (e-fold 0.9 px);
- strongest under the dished head, fading down the shell (e-fold 110 px).

Nothing else in the far plate changes, and the lit left third is byte-identical.

**Measured:**
- Far plate, right-edge luma: 35 -> 48 under the head, 38 -> 47 at y 380, 29 -> 35 at y 450, 27 -> 30 at y 520 and 19 -> 21 at y 600.
- In game (s5, the shell's edge column at 720p): 23-27 -> 27-31 luma.

The tank's left third is still lit by the hidden high-bay A; this round only answers the visible B. Crop: `should2-s5-tank-3x.png`, with `-round4`.

### Should 3: the pale strip under the camera housing (removed)

**Cause:** not the camera. The wall layer still carried a ghost of an earlier camera: a pale silhouette with a dark outline, at design x 368-470, y 466-514. It was offset from the camera drawn now, so its lower edge showed under the housing as if lit from below, and a pale patch showed above the arm.

**What changed:** `cleanup6.py` paints it out with the wall's own concrete from 52 px above, light-matched and feathered.

**Measured:**
- **Layer:** the zone's edge strength (p99 Sobel) goes from 83.7 to 34.3, against 31.5 on the wall round it. Its texture is 2.61 against 2.65 round it, and its mean luma 29.7 against 30.4.
- **In game:** the pale patch above the arm drops from 31.3 to 25.8 luma, against bare wall at 26.0 (720p; phone 31.9 -> 25.9).
- **Crops:** `should3-s1-A-720|A-phone-camera(-stretch).png`, each with `-round4`.

### Report: the perf table's s5 row, and the contact-shadow reference

**Draw calls:** `perf-table.md` now has a "max (all runs)" column. The draw-call maximum is a +4/+5 transient that shows in some 300-frame runs and not others. For **s5 it reads 75 -> 58**, from the round-5 review's probe. Round 4's own main s5 run peaked at 71, which is what the old row showed. s7 reads 75 -> 58 and s3 80 -> 63.

**Contact shadows** (`fix6-checks.json` `contact_shadows_s1`, s1 at 720p, across each plinth's width: relay world x 575-635, safe point x 848-905):

| Reference | Relay, slice | Safe point, slice | Relay, main | Safe point, main |
|---|---|---|---|---|
| **band**: world rows y 441-443, over rows y 448-452 | 0.72 | 0.53 | 0.95 | 0.86 |
| **contact row**: world row y 440.3, over rows y 448-452 | 0.53 | 0.45 | 0.71 | 0.74 |

- The **band** is the 2 px band starting 1 px under the plinths' foot line at y 440, measured over the band 8-12 px nearer the camera. It is the reference behind the 0.72 and 0.53 in round 4's SLICE.md and in both fix4 and fix5 checks.
- The **contact row** is the single foot-line row, the darkest. It is closer to the review's own reading (0.48 and 0.34), which used one column straight down from the plinth, not the plinth's width.
- Every reference agrees: the shadow is darkest at the contact line.

### Report only, not changed: the pale blue blob beside the relay while cranking (s3)

**Node:** `BypassHandle/CoolantHiss`, a `CPUParticles2D` made by `FxPresets.steam()`:
- 24 particles of a 16 px soft radial dot, scaled 4-7 times, #bfe8ff at alpha 0.35, normal blend, 0.75 s lifetime, drifting up and right at 25-45 px/s;
- set up in `scripts/bypass_handle.gd`, lines 109-120 in the slice; `HISS_OFFSET` (-56, 1) from the wheel puts it at the relay's right side;
- emits while `bypass_handle.venting` is true, from `main.gd` `_start_bypass_vent()`.

Main draws the same.

**Measured:** in a 20 x 30 world px box at its core, every pixel is above luma 150 (mean 204, colour (165, 212, 239)), against 44 at the same pixels at rest. The fine detail is almost nil (sd 1.1, main 0.8).

**How it reads:** the dots overlap into one smooth, evenly lit, pale cyan disc, with no wisps, no direction and no falloff into the air. So it **reads as a light blob, not as steam**. It is a runtime effect that only shows while venting, so rule 4 allows it to stay live. Making it read as a coolant jet is a separate change for Nathanial to pick: fewer, smaller and fainter dots in a narrow plume from a visible relief port.

Crops: `report-s3-hiss-slice-2x.png` and `report-s3-hiss-main-2x.png`.

### Still holding (re-measured on this round's captures)

- **Column solid (round 4's must 1):** over the column's filled span, s6 and s7 against s5 differ in 0 of 10,254 px.
- **Codex provenance:** no new Codex sessions in this round. All nine Codex outputs still carry their `caBX` (C2PA) chunk (`fix6-checks.json` `codex_c2pa`). All seven sessions are archived: 0 live, 1 each archived (`provenance.txt`, fix-round-5 section).
- **Lamp colours, plate position and leader:** these are code, unchanged since round 4, and so were not re-measured.

## Opening (rule 5): `opening-diff.json`, `opening-diff-<main run>.json`, `opening-diff/`

**Method:** as round 4 (`shots/tools/opening_diff6.py`). This round's slice (`raw6/slice/O-720`) is diffed against each of main's three runs (`raw5/main/O-720`, `O-720-repeat` and `O-720-r3`). Same-copy run-to-run noise is left out: the old bay lamp's flicker phase, from main's three runs and the slice's `O-720` and `O-720-r2`. Any blob brighter in the slice, or larger than dust, fails.

**Result, against all three main runs:**
- **Left of world x 540, o0-o8:** every difference is main's ambient dust, 7-20 blobs per frame. None fails, and none is brighter in the slice.
- **Right of world x 540:**
  - o0-o3: off-screen.
  - o4-o6: 0 px.
  - o7 and o8: about 173,000 px, the slice's own span.
- **Against round 4's slice:** o0-o7 are byte-identical to round 4's slice captures. o8 differs only in the old bay lamp's flicker glow, which is run-to-run noise. This round's art changes are all right of world x 540.
- Round 4's diff images and JSONs are kept in `opening-diff-round4/`.

## Numbers (`perf.json`, `perf-table.md`, `perf-headless.json`)

**Render monitors** (render.sh, 1280x720, 300 uncapped frames per held state). Main is round 4's run; the slice is this round's run.

| State | Draw calls p50 (max, all runs) | Texture MB | Video MB | Overdraw est. | Additive items | Dust emitters |
|---|---|---|---|---|---|---|
| s1 at rest | 72 (72) -> **54 (54)** | 72.0 -> 73.9 | 78.3 -> 80.2 | 3.60 -> 3.54 | 8 -> 7 | 2 -> 0 |
| s2 relay beat | 77 (77) -> **60 (60)** | 76.7 -> 73.9 | 83.0 -> 80.2 | 3.59 -> 3.47 | 8 -> 7 | 2 -> 0 |
| s3 cranking | 75 (80) -> **58 (63)** | 76.7 -> 73.9 | 83.0 -> 80.2 | 3.59 -> 3.48 | 9 -> 7 | 2 -> 0 |
| s4 opening | 73 (73) -> **56 (56)** | 76.7 -> 73.9 | 83.0 -> 80.2 | 3.61 -> 3.49 | 8 -> 7 | 2 -> 0 |
| s5 open | 71 (75) -> **54 (58)** | 76.7 -> 73.9 | 83.0 -> 80.2 | 3.58 -> 3.47 | 8 -> 7 | 2 -> 0 |
| s6 walking through | 71 (71) -> **54 (54)** | 76.7 -> 73.9 | 83.0 -> 80.2 | 3.59 -> 3.48 | 8 -> 7 | 2 -> 0 |
| s7 safe point | 71 (75) -> **54 (58)** | 76.7 -> 73.9 | 83.0 -> 80.2 | 3.53 -> 3.42 | 8 -> 7 | 2 -> 0 |

- **Draw calls:** this round added none. Every p50 equals round 4's: the atlas keeps the same pieces and regions, and `placement.json` is unchanged.
- **Memory:** texture and video memory are unchanged from round 4. The atlas, far and mid plates are the same sizes, and the mid plate is md5-identical.
- **Full-screen translucent world layers:** 2 in both copies (the haze, at 0.75 in main and 0.62 in the slice, and the mid plate). Canvas-layer quads: main draws Grade, IntroAlarm and IntroFade; the slice draws Grade only.
- **Frame times** in `perf-table.md` are software GL on a shared machine and are **not a measurement**.

**CPU, `godot --headless`** (frame wall time over 300 uncapped frames, p50 / p99 ms; main from round 4, slice re-run this round):

| State | Main | Slice |
|---|---|---|
| s1 | 0.21 / 0.30 | 0.22 / 0.34 |
| s2 | 0.20 / 0.27 | 0.18 / 0.38 |
| s3 | 0.22 / 0.40 | 0.21 / 0.45 |
| s4 | 0.20 / 0.28 | 0.21 / 0.30 |
| s5 | 0.21 / 0.30 | 0.21 / 0.32 |
| s6 | 0.21 / 0.27 | 0.19 / 0.37 |
| s7 | 0.21 / 0.28 | 0.20 / 0.33 |

The differences are noise. No phone or GPU measurement was made.

## Files made or changed in this round (all under `real-slice/`)

**Design:**
- `design/tools/portal6.py` writes `design/portal6/`: `design-front.png`, 39 part masks plus the contact shadow, glass hole and alpha masks, and `spec.json` (`lamp_conduit_top`).
- `design/tools/compose6.py` writes `design/door-end-design-v6-closed.png` and `-open.png`.
- `design/DESIGN.md` has a new v6 section on top, plus the corrected relay-feed line and a note on the Parts table. `design/DESIGN.round4.md` is the round-4 copy.

**Paint:** no new Codex sessions. Every new pixel is paint already in the slice (paint-portal2's conduit steel and end-face concrete; the wall layer's own concrete), or light added by Python (the tank rim). See the `provenance.txt` fix-round-5 section.

**Cleanup and layers:**
- `layers/tools/cleanup6.py` writes `layers/v6/portal-front.png`, `portal-wall.png` and `corridor-far.png`, copies of the unchanged v5 frame, curtain, open bar, lens and wheel, and `layers/report6.json`.
- `layers/tools/install6.py` writes `layers/v6/game/`: the atlas, the far plate, the mid plate (md5-identical to v5's) and `placement.json` (identical to v5's).
- The atlas changes only in the column region (154 px) and the wall region (1,375 px).

**Game (game-slice only; the whole diff against main is `shots/slice-code.diff`):**
- `assets/props/corridor-seal-atlas.png` and `assets/rooms/corridor-far.png` are replaced.
- `tests/m0_scene_test.gd` has the conduit check.
- No script changed.

**Tools and records:**
- Capture and test scripts: `fix6/tools/render_run.sh`, `capture_all.sh`, `headless_perf.sh` and `tests.sh`, plus `fix6/tools/layer_pairs.py`.
- Check scripts: `shots/tools/fix6_checks.py`, `opening_diff6.py`, `perf_table6.py`, `perf_headless6.py` and `sheet6.py`.
- Work files in `fix6/work/`:
  - the round-4 installed atlas, far and mid plates;
  - `SLICE.round4.md` and `slice-code.round4.diff`;
  - before/after layer crops;
  - the negative test log `negcopy/m0.log`.
- Outputs:
  - `shots/sheet.png`, `pairs/`, `perf.json`, `perf-table.md`, `perf-headless.json`;
  - `opening-diff.json`, `opening-diff-O-720*.json`, `opening-diff/` and `opening-diff-round4/`;
  - `fix6-checks.json`, `fix6-crops/` and `slice-code.diff`;
  - the captures in `raw6/slice/` and the logs in `logs6/`.
- `provenance.txt` has a fix-round-5 section.

## Still open

- **Review:** a review pass on this round, then Nathanial's first look at the one in-game piece.
- **For Nathanial**, unchanged from round 4:
  - the crank pose;
  - the three reds;
  - `SECTOR 4B` and `DOOR 4B-07`;
  - the 3.05 m height;
  - the 17-degree cross-wall;
  - the stub cutaway;
  - the blank 1.2 m keypad spot;
  - floor reflections;
  - the bypass plate's leader line;
  - the live beacon's flat drawing (review should 4);
  - section 8's yellows and reds (review should 6).
- **New for Nathanial:** the coolant hiss reads as a light blob (see above).
- **Budgets still over:**
  - s3's transient maximum of 63 draw calls;
  - overdraw at about 3.5;
  - 7 additive items;
  - texture memory at 73.9 MB.
- **Before a real PR:** the slice's `assets/manifest.json` must register the atlas and the replaced plates and stations. Notion and the Codex board are not updated.

---

# Fix round 4 record (kept as written)


Scratch only, 2026-10-12. No Git repository or worktree was edited, so there was nothing to commit or push. All changes are in `real-slice/game-slice`, the modified copy. `real-slice/game-main` is an untouched export of main 76d3a50 (plus the capture drivers the render runs copy in).

**How this was checked:**
- Headless logic tests: 13 of 13 pass in the slice (`logs5/tests-slice/`). `m0_scene_test` has three new checks: the column art has no see-through gap, the MANUAL BYPASS plate stands over its hub clear of the labels and the chain guard, and the leader reaches the backplate.
- Rendered stills: every still was made with `tools/render/render.sh` (Godot 4.7.2 in the Colima container, software GL). No window opened on the Mac.
- Not done: nothing was played by hand, so this report makes **no feel claims**. No phone or export was tested.

**Review status:** this round answers the round-4 review (`REVIEW-round4.md`) item by item. It has not had its own review pass yet, and Nathanial has not seen it.

**Everything in this package is from the final build.**
- The slice's code last changed at 19:52 (`bypass_handle.gd`; `m0_scene_test.gd` 19:51, `main.gd` 19:01). Its art last changed at 19:00.
- Slice captures ran 19:54-20:17, all after the last change. An earlier slice battery, started before the plate's last move, was stopped and fully re-run.
- Main was re-captured in this round too (19:18-20:17), with the same driver and container, into `raw5/main/`.
- Pairs, sheet, opening diff, checks and perf tables were made from these captures at 20:15-20:17.

## What to open

- `sheet.png` is the contact sheet:
  - the seven states, before and after, at 1280x720;
  - s1, s5 and s7 in phone shape;
  - the opening frames o5 and o7 with their diffs.
- `pairs/<state>-720.png` are the full-size before/after pairs at 1280x720 (HUD hidden; world labels stay).
- `pairs/<state>-phone.png` are the phone-shape pairs.
  - The game keeps 16:9, so a 2400x1080 phone shows its 1920x1080 image between 240 px pillar bars.
  - Each frame is the captured 1920x1080 image placed in a black 2400x1080 screen.
  - The single frames are in `pairs/phone/<copy>-<state>.png`.
- `fix5-crops/` holds the crops for each item below, with round 3's slice beside them (`*-round3.png`).
- `raw5/main/` and `raw5/slice/` hold the raw captures, with and without the HUD.
  - Routes: `O-720` (plus `O-720-repeat` and `O-720-r3` for main, `O-720-r2` for the slice), `A-720`, `B-720`, `A-phone`, `B-phone`, `*-720-perf` and `*-headless`.
  - `raw4/` (round 3) and `raw2/` (round 2) are kept as their records. Round 3's `fix4-checks.json` and `fix4-crops/` are kept as round 3's record too.

## What changed in this round

### Must 1: the see-through slit in the near column (closed)

**Cause:** the near guide (three 50 mm angles, standing 130 mm off the face) was drawn as its front face only. Its side return back to the jamb was missing, which left a 1.7 world px slit (design x 456.5..463.4) between the guide and the jamb's channel frame.

**What changed:**
- `design/tools/portal5.py` adds the return (`guide_near_side`, 110 mm deep, the guide's full 3.05 m). It is drawn before the jamb, so it fills exactly the slit and the jamb keeps its painted face.
- `layers/tools/cleanup5.py` paints it with the guide's own painted steel, carried along each row, under the return's design light.
- The same pass closes two 1 px anti-aliasing seams inside the column (atlas columns 21 and 59, alpha 249). Anything below full alpha with opaque pixels on both sides is set to 1.

**Measured (`fix5-checks.json` `must1_column_slit`):**
- **Atlas:** inside the column over world y 330-446, between each row's first and last fully opaque pixel, lamp glass excluded:
  - round 3: 1,392 non-opaque pixels, at columns 10-13 (the slit, alpha 0) and the two seams;
  - round 4: **0**.
- **In game:** over the column's *filled* span on screen (every pixel between its outline edges, so a slit counts; the lens is excluded), s6 and s7 compared with s5 (nobody behind the column):

  | Frame | Round 3: px differing by more than 2 | Round 3: max luma rise | Round 4: px differing by more than 2 | Round 4: max luma rise |
  |---|---|---|---|---|
  | s6 (engineer at x 780) | 167 | 94.9 | **0** | 0.0 |
  | s7 (WOLF at x 743) | 145 | 86.5 | **0** | 0.0 |

  Round 3's "0 pixels change on the column" counted opaque pixels only, so it missed the slit. That check is replaced.
- **Headless:** `m0_scene_test` now reads the column's atlas region and fails on any non-opaque pixel inside it over world y 330-446. The lamp glass and the foot row, where the chamfer meets the stub and its contact shadow, are excluded.
- **Crops:** `must1-s7-guide-6x.png` and `must1-s6-column-5x.png`, each beside its `-round3` version, where WOLF's head and the engineer's arm showed through.

The column can now be called solid: no faded or see-through pixel and no silhouette.

### Must 2: "the red seal" (the shut lamp is red)

**What changed:** `main.gd` `SEAL_LAMP_SHUT` is `Color(0.9, 0.2, 0.17)`. The guarded lens is red while the door is shut, amber while the curtain moves and green once it is open, as on the approved concept. The glow still shows only when open. The three lines that say "the red seal" now point at a red lamp. No in-game text changed.

**Measured (lens mean RGB):**

| Frame | Lens mean RGB | Reads as |
|---|---|---|
| s1 at rest | (210, 49, 43) | red |
| s3 cranking | (210, 49, 43) | red |
| s2 and s4 (the curtain is moving in both) | (237, 229-231, 101) | amber |
| s5 open | (159, 249, 229) | green |

Crop `must2-s1-lamp-6x.png`. The full s1 frame with the line "the red seal stays shut" is `must2-s1-hud.png`.

**Note for Nathanial:** the view now holds three reds when the door is shut: the two lockdown beacons and this lamp. REAL-LOOK section 8 asks for one. Dropping "red" from the three lines instead would be his call, because it is in-game text.

### Should 1: the crank pose (not done)

The glove sits on the rim at about 8 o'clock, but the arm still hangs. A 2-frame crank pose is new Look 2 character art, so it is **Nathanial's call** and is **not done** here.

### Should 2: the MANUAL BYPASS plate tied to its wheel

**What changed** (`bypass_handle.gd`):
- The plate moved 7.5 px right and now stands over the wheel's hub: world x 635.5-699.5, y 262-312. It used to sit at 628-692.
- A 1 px leader, in the plate's edge colour, drops from the plate's bottom edge at the hub's x (694) to the top of the wheel's backplate (y 384).
- The crank cells stay on the plate. Draw calls are unchanged.

**Why it cannot sit lower:**
- Its right edge must stay left of the chain guard (x 702.5).
- Its left edge overlaps the COOLANT RELAY name's box (x 555-655, y 313-330). Below the name are the COOLANT FAULT tag and the head of the engineer cranking.
- The plate is 50 px tall, so its top must be 136 above the gameplay point.

**Checks:**
- **Headless:** `m0_scene_test` checks that the plate spans the hub's x, ends left of x 702, and clears the name and the tag. It also checks that the leader ends below the plate at the hub's x.
- **Crops:** `should2-s3-plate-3x.png`, with the `-round3` version beside it.

### Should 3: two bays, one finish

**What changed** (`layers/tools/cleanup5.py`, far plate, right of the seam column only):
- The new bay's wall and dado take main's own painted wall at the same pixels, as relative detail over a 12 px low-pass:
  - its mottling;
  - the drip stains under the pipe run, where the leak would reach.
- Main's old pilaster band (source x 1230-1300) is filled from the detail on either side, averaged. Main's ceiling cables (y < 236) are left out.
- The bay's own fine block detail stays at 30 %.
- The broad light (the pendant's pool, the seam match) is unchanged.
- Chroma rises 12 % toward the old bay.
- The pendant's lens takes the corridor fittings' cool tint (188, 236, 255).
- Pipes, clamps, joints, the dado line and the luminaire are untouched. Nothing left of source x 1148 changes (checked).

**Measured:** s5, bare wall under the pipe run (screen y 196-268), clear of every label and fitting:

| | Old bay (x 470-545) | New bay, round 3 | New bay, round 4 |
|---|---|---|---|
| Saturation | 0.561 | 0.496 | **0.539** |
| Relative high-pass (texture sd / mean) | 0.134 | 0.180 (fine regular block) | **0.124** |
| Mean luma | 53.3 (under its own lamp) | 32.7 | 32.5 |

In the far plate's source (`layers/report5.json`), the new bay's saturation went from 0.448 to 0.496, against the old bay's 0.503. The value difference left between the bays comes from the old bay's brighter lamp, by design. Crops: `should3-s5-bays-2x.png`, `-stretch.png` and `-round3.png`.

### Should 4: the beacon's mount

**What changed** (far plate, deterministic, no image tool):
- A gunship-grey steel back box, 0.35 x 0.28 m, sits right above the live beacon's stalk (far x 0.659). It is lit from the pendant above it:
  - a bright top edge;
  - a lid seam;
  - four screws;
  - a short, soft shadow straight down the wall.
- A 25 mm conduit runs from the box's top to the ceiling tray, in two strap clamps. It passes behind the hanging luminaire.

**Measured (s1):** the box's mean luma is 62.5 and its lit top edge peaks at 80.3. The wall either side is 45.6 and 55.3. Crop `should4-s1-beacon-6x.png`, with `-round3.png` beside it.

### Should 5: budgets (stated; mostly inherited)

All still over:
- **Draw calls:** s3's transient maximum is 63 (p50 58), against a budget of 60. Main's s3 has the same +5 transient (75 -> 80).
- **Overdraw:** about 3.5, against a 2.0 target.
- **Additive items on screen:** 7, against a budget of 4. Most are left of x 540.
- **Texture memory:** 73.9 MB, against a 45 MB budget. Every room is still built at start; that is structural and outside this slice.

This round's changes added no draw call: every state's p50 and max equal round 3's.

### Still holding from earlier rounds (re-measured)

- **Contact shadows (s1, base against 8-12 px out):** relay 0.72, safe point 0.53. Main has 0.81 and 0.79.
- **Rule 5:** see the opening section below.

## Opening (rule 5): `opening-diff.json`, `opening-diff-<main run>.json`, `opening-diff/`

**Method:**
- The slice (`raw5/slice/O-720`) is diffed against each of main's three runs: `O-720`, `O-720-repeat` and `O-720-r3`.
- Pixels within the same-copy run-to-run noise (the lamp flicker's phase) are left out.
- Any blob that is brighter in the slice, or larger than dust, fails.

**Result:**
- **Left of world x 540, in o0-o8, in all three comparisons:** every difference is main's ambient dust.
  - There are 7-20 blobs per frame and none fails: none is larger than dust and none is brighter in the slice.
  - The slice has no ambient dust.
- **Right of world x 540:**
  - **o0-o3:** world x 540 is off-screen (screen x 1295 and more), so there is no slice span on screen (`slice_span_pixels_differing: null`).
  - **o4-o6:** the sliver right of x 540 is identical: 0 px differ.
  - **o7 and o8:** about 173,000 px differ. That is the slice's own span, the intended changes.

## Numbers (`perf.json`, `perf-table.md`, `perf-headless.json`)

**Render monitors.** These come from render.sh at 1280x720, 300 uncapped frames per held state, in the same container for both copies, and they are deterministic there. Each cell shows main -> slice.

| State | Draw calls p50 (max) | Texture MB | Video MB | Overdraw est. | Additive items | Dust emitters |
|---|---|---|---|---|---|---|
| s1 at rest | 72 -> **54** | 72.0 -> 73.9 | 78.3 -> 80.2 | 3.60 -> 3.54 | 8 -> 7 | 2 -> 0 |
| s2 relay beat | 77 -> **60** | 76.7 -> 73.9 | 83.0 -> 80.2 | 3.59 -> 3.47 | 8 -> 7 | 2 -> 0 |
| s3 cranking | 75 (80) -> **58 (63)** | 76.7 -> 73.9 | 83.0 -> 80.2 | 3.59 -> 3.48 | 9 -> 7 | 2 -> 0 |
| s4 opening | 73 -> **56** | 76.7 -> 73.9 | 83.0 -> 80.2 | 3.61 -> 3.49 | 8 -> 7 | 2 -> 0 |
| s5 open | 71 -> **54** | 76.7 -> 73.9 | 83.0 -> 80.2 | 3.58 -> 3.47 | 8 -> 7 | 2 -> 0 |
| s6 walking through | 71 -> **54** | 76.7 -> 73.9 | 83.0 -> 80.2 | 3.59 -> 3.48 | 8 -> 7 | 2 -> 0 |
| s7 safe point | 71 (75) -> **54 (58)** | 76.7 -> 73.9 | 83.0 -> 80.2 | 3.53 -> 3.42 | 8 -> 7 | 2 -> 0 |

- **Texture memory:**
  - In s1 the slice uses **1.9 MB more** than main: the lossless 1024x1024 atlas, about 5.3 MB with mipmaps.
  - In s2-s7 it uses 2.8 MB less.
- **Full-screen translucent world layers:** 2 in both copies, the haze and the mid plate. Main's haze covers 75 % of the view and the slice's 62 %.
- **Full-screen canvas-layer quads:** main draws 3 (Grade, IntroAlarm, IntroFade). The slice draws 1 (Grade); its intro quads are hidden at alpha 0.
- **Frame times** in `perf-table.md` come from software rendering on a machine shared with other sessions (load average up to about 55 during the runs). They are **not a measurement**.

**CPU, `godot --headless`** (no rendering; frame wall time over 300 uncapped frames per state, p50 / p99 ms):

| State | Main | Slice |
|---|---|---|
| s1 | 0.21 / 0.30 | 0.20 / 0.37 |
| s2 | 0.20 / 0.27 | 0.19 / 0.26 |
| s3 | 0.22 / 0.40 | 0.20 / 0.33 |
| s4 | 0.20 / 0.28 | 0.18 / 0.26 |
| s5 | 0.21 / 0.30 | 0.19 / 0.27 |
| s6 | 0.21 / 0.27 | 0.20 / 0.27 |
| s7 | 0.21 / 0.28 | 0.20 / 0.28 |

The differences are noise. No phone or GPU measurement was made, and none of these numbers says anything about phones.

## Files (all under `real-slice/`)

**Design (deterministic, no image tool):**
- `design/tools/portal5.py` writes `design/portal5/`:
  - `design-front.png`;
  - 35 part masks, including the new `front--guide_near_side.png`, plus the contact shadow, glass hole and alpha masks;
  - `spec.json`, whose `guide_return` holds the slit numbers.
- `design/tools/compose5.py` writes `design/door-end-design-v5-closed.png` and `-open.png`.
- `design/DESIGN.md` has a new v5 section on top. `design/DESIGN.round3.md` is the round-3 copy.

**Paint:** **no new Codex sessions** in this round.
- Every painted pixel comes from outputs already recorded (paint-portal2 for the guide's steel) or from main's own far plate (the new bay's mottling and drips).
- The beacon's box and conduit are drawn by Python.
- `provenance.txt` has a fix-round-4 section. All seven Codex sessions of the slice are recorded there, including 01a12e59-e7ba-7630-b1dc-9448924148ef, 01a12e5c-eb97-7f63-b9cf-ec4e75fd8a9a and 01a12e59-e7ba-7073-8a77-796f536bcc43, and all seven are archived: 0 live in `~/.codex/sessions`, 1 each in `~/.codex/archived_sessions`.
- All nine Codex outputs in `codex/*/out/` still carry their `caBX` chunk with a C2PA manifest (re-checked this round).

**Cleanup and layers:**
- `layers/tools/cleanup5.py` writes:
  - `layers/v5/portal-front.png` and `corridor-far.png`, plus copies of the unchanged v4 wall, frame, curtain, open bar, lens and wheel;
  - `layers/report5.json`.
- `layers/tools/install5.py` (install4's recipe on v5) writes `layers/v5/game/`: `corridor-mid.png` (byte-identical to v4's), `corridor-far.png`, `corridor-seal-atlas.png` and `placement.json` (byte-identical to v4's, so every atlas region is unchanged).

**Game (game-slice only; the whole code diff against main is in `shots/slice-code.diff`):**
- `assets/props/corridor-seal-atlas.png` (the column's guide return and closed seams) and `assets/rooms/corridor-far.png` (the new bay's finish, the beacon's mount) are replaced.
- `scripts/main.gd`: `SEAL_LAMP_SHUT` is red, with the comments updated.
- `scripts/bypass_handle.gd`: the plate's position and the leader.
- `tests/m0_scene_test.gd`: the column-art gap check and the plate and leader checks.
- The round-3 copies of the three code files are in `fix5/work/round4-code/`.

**Captures and checks:**
- Tools:
  - `fix5/tools/render_run.sh`, `capture_all.sh`, `headless_perf.sh` and `tests.sh`;
  - the drivers `fix3/driver/realslice_capture.gd` and `fix3/driver-headless/`, unchanged and used for both copies.
- Check scripts in `shots/tools/`: `fix5_checks.py`, `opening_diff5.py`, `perf_table5.py`, `perf_headless5.py` and `sheet5.py`.
- Outputs:
  - `shots/sheet.png`, `pairs/`, `perf.json`, `perf-table.md`, `perf-headless.json`;
  - `opening-diff.json` (against main `O-720`), `opening-diff-O-720*.json` (one per main run) and `opening-diff/`;
  - `fix5-checks.json`, `fix5-crops/` and `slice-code.diff`;
  - logs in `logs5/`, with the test logs in `logs5/tests-slice/`.

## Still open

- **Review:** a review pass on these captures, then Nathanial's first look at the one in-game piece.
- **For Nathanial:**
  - the 2-frame crank pose (new character art; not done);
  - three reds in the shut view (two lockdown beacons and the seal lamp) against section 8's one, or dropping "red" from the three lines;
  - the marks `SECTOR 4B` and `DOOR 4B-07` (8.75 px letters on the hood, under the 12 px spec);
  - the door height (3.05 m);
  - the reading of "slight angle" as a cross-wall face turned 17 degrees;
  - the stub, a cutaway convention new to the game;
  - the PIN keypad (the 1.2 m spot is blank);
  - floor reflections for the engineer and WOLF (kept);
  - the bypass plate's leader line, a small UI addition.
- **Military read:** partial. It reads as a secure, machine-run plant room. Options for Nathanial: a steel armour frame round the opening, a vestibule with an inner blast door, or `RESTRICTED AREA`. Nothing is taken from the Terminator films.
- **Inherited look:** the old bay's lamp keeps its painted cyan streaks and its runtime glow cone. The new bay now shares its finish but not that lamp style.
- **Budgets still over:** s3's transient maximum of 63 draw calls, overdraw at about 3.5, 7 additive items, and texture memory at 73.9 MB.
- **Before a real PR:**
  - the slice's `assets/manifest.json` must register the atlas and the replaced plates and stations, and retire the deleted round-0 images;
  - `corridor-bulkhead-open.png` stays, because the junction uses it.
- **Not done:** Notion and the Codex board.
