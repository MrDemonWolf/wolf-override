# Review, round 3: the corridor's door end (independent, adversarial)

**Verdict: fix needed. Do not show this to Nathanial yet.**

Fix round 2 closed most of the round-2 list:
- the opening is identical to main apart from dust;
- the package is current, and provenance and C2PA are complete;
- the bypass is on the wall at 1.05 m;
- the yellow line and the grey stop button are in;
- the draw calls dropped by 15-17 in every state.

Two things still read as unreal to a first-time player:
- the new "cover silhouettes" are pale ghosts, lighter than the concrete they are drawn on;
- the new art breaks the plate's own perspective in two places.

The report also overstates three measurements.

- **What I reviewed:** every after-shot in `raw2/slice/` (A-720, B-720, O-720, A-phone, B-phone, captured 15:02-15:10) against `raw2/main/`. I looked at each one at full size, in 2-6x crops, in greyscale and contrast-stretched, and ran REAL-LOOK section 3 on them.
- **What I ran myself:**
  - an opening re-diff against all three main runs and both slice runs;
  - C2PA, sha256 and archive checks on every Codex output;
  - an independent render.sh probe of s1, s5 and s7 in both copies, with my own driver and job names `review-r3-main` and `review-r3-slice`;
  - all 13 headless tests;
  - value, contact-shadow and perspective measurements.
- **Evidence:** `scratchpad/review-r3-work/`: `crops/`, `opening.py`, `c2pa.py`, `driver/review_probe.gd`, `probe-main/`, `probe-slice/` and `tests/`.
- **Scope:** I edited nothing in `real-slice/` except this file. Running Godot touched only the copies' `.godot` caches, `home-realslice` and the render cache. No window opened on the Mac. Nothing was committed or pushed: unapproved art and private scratch files stay out of Git until Nathanial approves the piece.
- **Validation:** nothing was played by hand, so I make no feel claims.

## Verified (not taken from the report)

- **The package is current.**
  - The slice captures (15:02-15:10) postdate the last code change (`room_depth.gd` at 15:01) and the art install (14:26).
  - `SLICE.md`, `sheet.png`, `pairs/`, `perf*.{json,md}` and `opening-diff.json` were all written at 15:10-15:15. The sheet shows the current build.
  - My own render.sh frame of slice s1 is **pixel-identical** (0 px) to `raw2/slice/A-720/s1-door-end-rest.png`.
- **Rule 5 holds** (`review-r3-work/opening.py`).
  - Left of world x 540 in o0-o8, every difference between slice and main is a round soft mote 12-37 px across, and the slice is darker in each. That is main's dust; the slice has no dust emitters.
  - No pixel is brighter in the slice by more than 3 levels, with one exception: o8 against main run `O-720`, whose lamp flicker drifted. Against main's other two runs, o8 matches apart from dust.
  - The round-2 top-right red halo in o0, o1 and o4-o6 is gone. The top-right box has 0 differing px in those frames, except o6 against one drifted main run (305 px, at most 2 levels).
  - o2's 38 px at the top right are a dust mote clipped by the frame edge; the slice is darker there.
- **Provenance and C2PA are complete.**
  - All nine Codex outputs in `codex/*/out/` carry a `caBX` chunk with a c2pa JUMBF manifest.
  - The used round-2 and round-3 outputs are byte-identical (sha256) to their `~/.codex/generated_images/` files.
  - All seven sessions are listed in `provenance.txt` with their outputs and derived files. All seven are archived: each has 0 rollouts in `~/.codex/sessions` and 1 in `archived_sessions`.
  - The prompts and `rules3.txt` say to keep all metadata.
- **The render numbers reproduce.** My re-measure, from the same container with my own driver, held state, at 1280x720:

  | State | Draw calls p50 (main -> slice) | Texture MB | Video MB | Full-screen translucent world layers | Emitting particle nodes |
  |---|---|---|---|---|---|
  | s1 | 72 -> **55** | 71.97 -> **73.70** | 78.35 -> 80.08 | 2 (Haze, MidPlate) -> 1 (MidPlate) | 2 -> 0 |
  | s5 | 75 (min 71) -> **58** (min 54) | 76.66 -> 73.70 | 83.03 -> 80.08 | 2 -> 1 | 2 -> 0 |
  | s7 | 75 -> **60** | 76.66 -> 73.70 | 83.03 -> 80.08 | 2 -> 1 | 2 -> 0 |

  - s1 matches the report exactly.
  - In s5 and s7 my probe did not pause tweens, so a transient adds about 4 calls in **both** copies. The drop (17 and 15) matches the report.
  - The headline "texture memory 76.7 -> 73.7 MB" hides that in s1 the slice uses **1.7 MB more** than main (72.0 -> 73.7).
- **Headless tests:** 13 of 13 pass in my run. The two rewritten `m0_scene_test` checks are not weakened: the pier must be opaque with two silhouettes, and the hub clearance went from 6 to 3 px, as before.
- **Contact shadows are real and darkest at the contact line** (s1, floor at the base against 8-12 world px out):
  - Relay: 16.5 against 33, a ratio of about **0.50**.
  - Safe point: 13.5 against 36, about **0.38**.
  - Both stand on plinths with a floor cable entry.
- **The door works as a door across the way.**
  - The 17-degree cross-wall carries the rolling door. The walk line crosses it at the collision face.
  - The far column, reveal and hood sit behind the actors (s2, s4, s5).
  - The curtain fills the opening shut (s1, s2), winds up into the hood with the striped bar (s4), and leaves a tucked bar and a true hole onto the plant room (s5). `report3.json`: hole alpha max 0.
  - The near pier itself is opaque in every frame.
- **The bypass is wall-mounted.**
  - A backplate with four anchors sits on the corridor wall, with the hub at (695, 398) = 1.05 m.
  - An enclosed guard runs straight up the wall in two clamps to the operator. The floor stand and the diagonal shaft are gone.
  - The rim out-values its wall (s1: ring p90 89 against the surrounding wall p90 30).
- **The plant room is dark enough on average.** Its visible area in s1, without the safe point, averages luma **31.7**. Its saturation (0.42-0.44) is near the corridor's (0.54).
- **No text from the image tool; nothing from the films.** The only marks are the typeset `SECTOR 4B` and `DOOR 4B-07`, both on the approved list and both still proposals. There is no keypad, no franchise name, logo, typeface, machine shape, skull, red eye or model-number style.

## Must fix before Nathanial sees it

### 1. The cover silhouettes are pale ghosts, and the near column hides the safe-point user

The near column is solid now, but whoever stands behind it is drawn over it with `COVER_SILHOUETTE_TINT = Color(0.56, 0.68, 0.74, 0.4)`. That is a **light** blue-grey at 40%, blended over dark concrete, so it **lightens** the pier.

**Measured in s7:**

| Area | Luma |
|---|---|
| WOLF's head silhouette | 59.6 |
| Engineer's silhouette | 61.9 |
| Pier beside them | 21-35 |

The silhouettes are 2-3x **brighter** than the concrete they sit on, so `SLICE.md`'s "dim flat silhouette" is wrong.

**What a first-time player sees:**
- In s7, WOLF's head turns into a flat pale dog-head cut-out pasted on the wall (`crops/s7-pier-3x.png`).
- The engineer using the safe point is half red jacket, half grey ghost.
- In s6, a pale strip runs down his right side.
- It reads even at thumbnail size on the phone pair (`crops/phone-s7-pier-2x.png`).

This is now the strongest compositing tell in the slice. It also goes against the brief, which says the near column is "never faded or see-through" and should be "slim enough that actors stay readable".

**Root cause:** the column is too wide where people stop. It spans world x about 787-831 on screen (about 44 world px, 1.1 m). That is twice the engineer's width (about 22 px), and the safe point's gameplay stand point, x 831, sits on its right edge.

**Fix:**
1. **Make the column slim.** Reduce the exposed approach face and the 0.66 m end face (for example a 0.3 m steel-faced end) so the column's right edge lands left of about x 818. At the kept stand point x 831 the engineer then stands clear, and WOLF's s7 head is clear too.
2. **Drop the silhouette.** Plain occlusion of a slim column while someone walks past is real and readable. If Nathanial wants a silhouette as a game convention, make it **darker** than the pier: multiply the pier by about 0.6-0.7 inside the actor's shape, or draw a 1 px dark outline. Never add light.
3. Re-capture s6 and s7 at 1280x720 and in phone shape. Check that pier luma inside any silhouette is at or below the pier's own luma.

### 2. The new art breaks the plate's perspective in two places (checklist item 1)

**a. The cut band is vertical, but the floor converges.**
- `portal3.py` draws `pier_cut` and both arris angles with constant screen x, down to `BAND_BOTTOM`.
- Under the plate's camera (vanishing point at about screen (423, -3) at the 1280x720 clamp), a wall running toward the camera from the pier's foot at about (1005, 540) must slope at about 0.93 and reach the frame bottom near x 1190.
- The slab joint drawn right beside it does obey the vanishing point (measured slope 0.69, predicted 0.675), and so does the corridor's floor seam at x 800-900 (measured 1.55, predicted 1.52). The cut is the one vertical line among converging ones.
- So the band does not read as the wall reaching the camera. It reads as a free-standing foreground post.
- It is also nearly invisible: cut luma 11.7 against slab 13.4. The lower-right fifth of the frame is a near-black, almost featureless block beside a glossy wet floor (`crops/s1-cut-2x.png`, `crops/phone-cut-slab-stretch.png`).

**Fix:** the brief only asks the wall to span to the walkway's camera-side edge, and the angled face's foot already does. Pick one:
1. End the wall there with a clear cut face. Mark the floor junction between the corridor's wet floor and the plant slab as a steel joint or threshold **along the vanishing-point line** from (1005, 540).
2. Carry the wall on as a low, cut-down wall drawn **along that line**, with its lit steel angle, and value-separate it from the slab (at least 8-10 luma).

Then lift the near slab a little (it is 13-14) so the corner does not read as a hole.

**b. The tank's top is drawn from a different eye.**
- `far_patch.py` draws `tank_head` as a full ellipse with half-height `0.35 * tm` (about 12.7 world px).
- The plate's camera (eye 7.04 m, walkway 38 m away, tank 4 m back) puts a 5.2 m tank top almost on edge: about 1.1 world px half-height, so about 11x too open.
- The same plate draws the catwalk deck at 3 m (further below the eye, so it should look more open) as an edge-on strip. The two contradict each other.
- Lighting the head from high-bay B (round-2 item) made the error easier to see (`crops/s5-tank-top-4x.png`).

**Fix:** redraw the head as a shallow dished profile (rise about 0.25-0.3 m) above an almost flat rim, with only a 2-4 px sliver of top surface. Keep the light from B on its upper curve.

## Should fix in the same pass

1. **The crank does not read as cranking.**
   - In s3 the engineer's arm hangs straight and the glove only touches the rim's lower-left edge by about 2 px (`crops/s3-hand-6x.png`). He reads as standing next to a valve while the meter fills.
   - Main has the same idle pose, so this is the sprite's limit, but the brief asks for "the engineer's hand on its rim while cranking".
   - Fix: at minimum, move the crank stand point or the wheel 2-3 world px so the glove sits on the rim at about 8 o'clock. Better: a 2-frame crank pose, with the arm raised to the rim.
   - The wheel is right for a real handwheel (0.525 m, grey steel) but small and quiet at 1x. It nearly vanishes in the contact sheet, where main's gold wheel pops. The MANUAL BYPASS plate floats about 150 px above and left of it. A brighter worn-steel rim face (p90 about 110-120) would help it read as the thing you crank.
2. **The drive geometry.** The guard starts at the wheel's upper right, beside the hub, not behind it. On a worm gearbox the input sits on the wheel's axis and the output leaves the box. Either show the box behind the hub with the guard rising from it, or offset the wheel onto the box's input.
3. **The grain is colour noise.** The ±2.5-level grain added to calm faces is independent per channel: violet and green speckle under a stretch (`crops/phone-crosswall-stretch.png`). Real concrete grain is luminance. Make it luma-only. It is invisible at 1x on a desktop, but check it once through ETC2 on a phone.
4. **A hot spot in the plant room.** Between the pier and the safe point the floor reads luma 62 (45 right of the safe point), brighter than the engineer. Pull that patch down to about 40-45.
5. **Draw calls.** s3's transient maximum is still 63 against a 60 budget (p50 58). State it as over, or trim one call.

## Report accuracy (fix in SLICE.md before Nathanial reads it)

- **"Dim flat silhouette":** the measurement shows it is lighter than the pier (must-fix 1).
- **"Plant wall luma 21 and floor 26, against the engineer at 27":**
  - `fix2_checks.py` measured the floor on the near slab (world y 446-456), not the lit plant floor behind the safe point (45-62).
  - It measured the wall on the upper wall only. The wall below the catwalk reads 31-32.
  - Quote the area mean (31.7) and the hot spot instead.
- **"Rim p90 88 against the wall beside it at p90 47":** `fix2-checks.json` records `wall_left_of_backplate_p90` 99.6 (s3, which includes the coolant cloud), and the 47 appears in no data file. My own s1 figure is rim p90 89 against wall p90 30. Quote a reproducible number.
- **"Texture memory 76.7 -> 73.7 MB":** give it per state. At s1 the slice is 1.7 MB higher (72.0 -> 73.7).

## Does it read as a near-future military base?

**Partly, and no worse than round 2.**

**What reads as hardened and machine-run:**
- a cast cross-wall;
- a numbered gunship-grey door with caught-between stripes and a scuffed travel line;
- a fixed camera on a wall arm;
- a lockable junction box with grouped conduit;
- `SECTOR 4B`;
- dark, zoned lighting.

**What still says "secure plant room":**
- The rolling door is a light commercial shutter with no blast mass.
- The room beyond is a generic tank, catwalk and pump hall.

**Without new text or keypads** (all for Nathanial to pick):
- a visible steel armour frame and edge angles round the opening, thick enough to read at 1x;
- the section 8 vestibule with a closed inner blast door behind the opening;
- `RESTRICTED AREA` from the approved list.

**Nothing is taken from the Terminator films.**

## AI-tell checklist (REAL-LOOK section 3, on the in-game captures)

| # | Item | Result |
|---|---|---|
| 1 | Vanishing lines | **Fail.** The vertical cut band against the converging floor (2a); the tank head drawn from a higher eye (2b). The door, hood, bar, marks, slab joints and corridor seams are consistent. |
| 2 | One light logic | **Fail** through the silhouettes: they add light where there is no source. The rest passes: the wall pack lights the hood, the LED fitting lights the new bay, the high-bays light the plant room, and the tank head is lit from B. |
| 3 | Every part has a job | Pass, with a note on the guard starting off the hub (should-fix 2). |
| 4 | Nothing floats | Pass. Relay 0.50, safe point 0.38; the backplate is anchored; the camera is on an arm; the box is on a backplate with conduit. |
| 5 | Scale | Pass. The door is 3.05 m, the wheel 0.525 m with its hub at 1.05 m. The near column (1.1 m) is the one oversized element at the play position (must-fix 1). |
| 6 | Doors | Pass. Hole alpha 0, the wall continues round it, and its own room is behind it. |
| 7 | No text | Pass. Typeset, listed marks only. |
| 8 | Detail and values | **Fail (small).** The near-black dead block at the lower right, chroma grain, and the plant-floor hot spot. The pier edge step and compression blocks are fixed. |
| 9 | Wear logic | Pass. Wear at the bar's centre, scuffs on the travel line, damp at the wall foot. |
| 10 | No repeats | Pass. |
| 11 | Rule 5 | **Pass.** Identical to main apart from dust in o0-o8 (re-measured). |
| - | Compositing | **Fail.** The pale ghost silhouettes (must-fix 1). |

## Before and after, as a first-time player

| State | Before (main) | After (slice) |
|---|---|---|
| s1 at rest | A garish red gate standing on the floor, and a gold wheel on a pole | A believable concrete cross-wall with a grey numbered roller door and a camera, and a dim machinery hall beyond. The wheel on the wall is quiet. The lower-right corner is a dark block with a vertical post. |
| s2 relay beat | The engineer beside the red gate | He stands at the door face in front of the curtain. The Look 2 relay sits on its plinth with a real shadow. Good. |
| s3 crank | The engineer beside a bright gold wheel | The engineer beside a grey wall wheel, arm hanging. It reads as "standing at a valve", not cranking. |
| s4 opening | The gate folding | A roller door winding into its hood, with the room appearing under the bar. Good. |
| s5 open | An open gate frame onto a blue tunnel | A true hole onto a real, dim room. The best frame. |
| s6 walk through | Walking through the gate | Walking through the doorway, with a pale ghost stripe down his right side where the column covers him. |
| s7 safe point | The engineer at the safe point | The engineer half hidden by the column and drawn half as a pale ghost. WOLF's head is a pale cut-out on the wall. This frame alone would make Nathanial call it fake. |
| Seam | - | Hidden by the column. The grimy old bay against the clean new bay reads as two bays. |

## What I need to pass it

1. Must-fix 1: a slim column, and no light silhouette. Must-fix 2: a perspective-consistent wall end or floor joint, and a corrected tank head.
2. Fresh s1-s7 captures at 1280x720 and in phone shape, plus the opening re-diff, from the final build.
3. SLICE.md corrected as listed above.

The should-fix items can go into the same pass. Then a second reviewer, and only then Nathanial.
