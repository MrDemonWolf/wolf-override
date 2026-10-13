# Review, round 4: the corridor's door end (independent, adversarial)

**Verdict: fix needed, but it is close.** Two small faults remain, and both show in the frames Nathanial will judge. Fix them, re-capture four frames, run one more review pass, and it is ready to show him.

Fix round 3 closed everything round 3 asked for:
- The near column is slim, and the pale silhouettes are gone.
- The stub follows the wall's own vanishing point.
- The tank head now matches the plate's camera.
- The wheel's rim is bright, and the glove touches it.
- The grain is luminance only.
- The plant-floor hot spot is gone.

I would not call anything in the slice generated-looking. It reads as a concrete cross-wall with a numbered roller door and a dim plant room beyond. That is a large step up from main's red gate.

The two faults:
- **A see-through slit in the near column.** WOLF's head and the engineer's arm show through it. The direction says "never faded or see-through".
- **The text says "the red seal stays shut", but nothing on the door is red.** That line is on screen in s1.

**What I reviewed:**
- Every after-shot in `raw4/slice/` (A-720, B-720, A-phone, B-phone, O-720, O-720-r2) against `raw4/main/`.
- Each at full size, in 3-6x crops, in greyscale and contrast-stretched, with REAL-LOOK section 3 run on each.

**What I ran myself:**
- an opening re-diff against all three main runs;
- C2PA, sha256 and archive checks on every Codex output;
- an independent render.sh probe of s1, s5 and s7 in both copies, with my own driver (job names `review-r4-main` and `review-r4-slice`);
- all 13 headless tests;
- value, contact-shadow, perspective and alpha measurements.

**Evidence:** `scratchpad/review-r4-work/`:
- crops and diffs: `crops/`;
- my tools: `tools/opening.py`, `tools/c2pa.py`, `tools/crop.py`, `driver/review_probe4.gd`;
- probe outputs: `probe-main/`, `probe-slice/`, `opening-mine.json`, `tests/`.

**Scope:**
- I edited nothing in `real-slice/` except this file.
- Running Godot touched only the slice's `.godot` cache, `home-realslice` and the render cache.
- No window opened on the Mac.
- No repository file changed, so there was nothing to commit or push. The slice is unapproved art in scratch.

**Validation:** nothing was played by hand, so this review makes no feel claims.

## Verified (not taken from the report)

- **The package is regenerated from the final build.**
  - The slice's code last changed at 17:21 (`main.gd`) and its art at 17:49.
  - The import cache's source md5s match the installed PNGs, and those match `layers/v4/game/`.
  - The slice captures run 17:54-18:16, and main's 16:52-17:19.
  - `SLICE.md`, `sheet.png`, `pairs/`, the perf files, `opening-diff.json`, `fix4-checks.json` and `slice-code.diff` are dated 18:13-18:22.
  - `slice-code.diff` matches a diff I regenerated, line for line.
  - The sheet is labelled fix round 3 and shows this build.
  - My own render.sh frame of slice s1 is **pixel-identical** (0 px) to `raw4/slice/A-720/s1-door-end-rest.png`. My s5 and s7 differ by at most 21 levels, only in the left lamp's light shaft (its flicker) and around the two lockdown beacons (their pulse).
- **Rule 5 holds.** I checked with my own `opening.py`, against main runs `O-720`, `O-720-repeat` and `O-720-r3`.
  - Left of world x 540 in o0-o8, every differing blob is 7-37 px across.
  - Every blob is darker in the slice (mean -9 to -34 levels), and none is brighter.
  - The largest, 37 x 22 px in o5, is two overlapping dust motes in main (`crops/o5-blob-6x.png`). The slice has no ambient dust.
  - The top-right box of o0 differs only by two main motes. In o5 its 300 x 200 px are identical (0 px).
  - The 16-px sliver right of world x 540 in o4-o6 is identical. In o0-o3, world x 540 lies past the frame edge (screen x 1295 and 1349), so "identical right of x 540" is empty there.
  - o7 and o8 differ only inside the slice span (screen x ≥ 972).
- **Provenance and C2PA are complete.**
  - All nine Codex outputs in `codex/*/out/` carry a `caBX` chunk with a c2pa JUMBF manifest.
  - The five used outputs are byte-identical (sha256) to their `~/.codex/generated_images/` originals.
  - All seven sessions are in `provenance.txt` and archived: 0 live, 1 archived each.
  - Every prompt or rules file says to keep the metadata.
  - No Codex session or generated image dates from this round. That matches "no new Codex sessions".
- **The render numbers reproduce exactly.** My probe ran 300 uncapped frames per state at 1280x720 in the container, with the same engineer positions as the report:

  | State | Draw calls p50 (main -> slice) | Texture MB | Video MB | Emitting particle nodes | Full-screen translucent world sprites |
  |---|---|---|---|---|---|
  | s1 | 72 -> **54** | 71.97 -> **73.87** | 78.35 -> 80.24 | 2 -> 0 | Haze 0.75 + MidPlate -> Haze 0.62 + MidPlate |
  | s5 | 71 (max 75) -> **54** (max 58) | 76.66 -> 73.87 | 83.03 -> 80.24 | 2 -> 0 | same |
  | s7 | 71 (max 75) -> **54** (max 58) | 76.66 -> 73.87 | 83.03 -> 80.24 | 2 -> 0 | same |

  - Full-screen canvas-layer quads: main has Grade, IntroAlarm and IntroFade (the last two clear, alpha 0). The slice has only Grade.
  - Frame times are software rendering on a shared machine (load average about 9.4), so they mean nothing.
- **Headless tests:** 13 of 13 pass in my run (`review-r4-work/tests/`).
- **Perspective checks out.**
  - The design camera puts the floor's vanishing point at screen (423, -3). VP2 sits at world x 21, which is screen x -410, not 21.
  - The stub's slope from the column foot to VP2 is 0.387, against 0.385 in the design and 0.376 measured.
  - The bottom bar (about 0.4 measured, 0.38 predicted) and the cross-wall's pour joint (0.088 measured, 0.099 predicted) fit the same point. The door's lines all run to it.
- **Contact shadows are darkest at the contact line.** I measured s1, from the row under the base out to 8-12 world px:
  - Relay: 15 against 34, a ratio of about **0.44**.
  - Safe point: 13 against about 30, about **0.43**.
  - Both stand on plinths with anchors.
- **The door rule holds.**
  - The curtain, frame and tucked bar are door-only regions of the atlas.
  - The wall region's doorway is alpha 0, and the plant room (far plate) shows through it.
- **The plant room is at actor values.**
  - The visible area, safe point excluded, averages **33.8**, and the view through the opening **33.9**. The engineer's box averages 45.
  - Saturation is 0.43 against the corridor wall's 0.49.
  - There is a defined pool on the wall and floor under high-bay B.
- **The seam values match.** The wall is 44.3 left of the seam column and 44.2 right of it, at the same hue (200°).
- **Phone shape is honest.** The game has no stretch-aspect override, so the default `keep` applies. A 2400x1080 window renders 1920x1080 with bars, so the pillar-boxed pairs are a fair picture of the phone.

## Must fix before Nathanial sees it

### 1. A see-through slit in the near column

The column sprite (atlas region `941,2,74,606`) has a transparent slit between the near guide and the column body.
- Atlas columns 11-12 are alpha 0, with 96 on either side.
- That is world x 790.0-791.5, from world y 328 down past the floor line (452).
- On screen it is about 2-3 px at 720p and 3-4 px at 1080p.
- It is in the design: `portal4/masks/front--guide_near.png` ends at design x 456 and `front--frame_near_jamb.png` starts at 463, with nothing between them.

Anyone behind the column shows through it:
- **s7** (`crops/s7-guide-gap-6x.png`): WOLF's head is cut by the guide, then a light sliver of his head armour shows again between the guide and the column face.
- **s6** (`crops/s6-column-edge-5x.png`): a red sliver of the engineer's right arm and glove shows between the guide and the column.
- With nobody behind it, the slit shows a line of the plant room through what should be the jamb's steel.

The jamb's 160 mm approach face lies in front of anyone in the doorway, so a real camera sees steel there, not the person behind it. The direction says the near column is "never faded or see-through".

`fix4-checks.json`'s "0 pixels differ on the column's 11,555 opaque pixels" is true, but it leaves this slit out because the slit has no opaque pixels.

**Fix:**
- In `portal4.py`, carry `frame_near_jamb`'s left edge over to the guide, or add a jamb-face part that fills design x 457-462.
- Re-run cleanup and install.
- Then check that every column of the column region is alpha 255 between the guide's left edge and the chamfer, over world y 328-452.

### 2. "The red seal" with nothing red on the door

The slice's door is gunship grey and its shut status lens is dark glass (`SEAL_LAMP_SHUT = Color(0.2, 0.17, 0.17)`). Three game lines still call it red:
- `main.gd:1707` "...the red seal stays shut." (on screen in s1);
- `main.gd:1771` "...The red seal opens.";
- `main.gd:1837` "...The red seal opens."

A first-time player reads "the red seal" and finds no red seal. The approved concept (`doors-shutter-approved/notes.md`) has a **red status lamp on the frame while closed** and green when open.

**Fix (recommended):** set `SEAL_LAMP_SHUT` to a red, so the guarded lens shows red while shut. It is a live lamp colour, which is on the live list. It also matches the approved concept.

**Alternative:** if Nathanial wants no extra red in view (REAL-LOOK section 8 allows one red element, and the lockdown beacons are already red), drop "red" from the three lines. That is in-game text, so it is his call.

Then re-capture s1 and s2 at 720 and in phone shape.

## Should fix (same pass, or put to Nathanial)

1. **The crank still does not read as cranking.**
   - In s3 the glove sits on the rim at about 8 o'clock (`crops/s3-crank-5x.png`), but the arm hangs straight. In a still they are standing next to a valve.
   - The direction asks for the hand on the rim "while cranking".
   - This needs a 2-frame crank pose, which is Look 2 character art, so it is Nathanial's call. Say so in the hand-off. Do not count it as done.
2. **The MANUAL BYPASS plate is far from the wheel.**
   - `LABEL_TOP -134` and `LABEL_SHIFT_X -40` put it about 160 screen px above and left of the wheel, on bare wall between the relay and the door.
   - Its crank meter fills there while the engineer stands at the wheel. It reads as a sign on the wall, not the wheel's name.
   - Main's plate sits right over its wheel.
   - Fix: tie the plate to the wheel. Bring it down beside the guard just above the wheel, add a short leader, or show the crank cells next to the wheel.
3. **Two bays, two finishes.**
   - Right of the seam column the new bay is a cool grey, fine-grained block wall with a white pendant and a modest pool.
   - Left of it, the untouched bay is teal, painterly, drip-stained concrete under a cyan lamp with a glow cone (`crops/s5-seam-2x-stretch.png`).
   - Values match, but at 1x it reads as two finishes joined at a column.
   - The same pipe run leaks down the old bay and leaves the new bay clean, which breaks wear logic.
   - Fix: bring the new bay's grain and tint toward the old bay's, and carry faint drip stains under the pipe run where the leak would reach.
4. **The lockdown beacon in the new bay hangs on bare wall.**
   - Main's pilaster is gone. The flat code-drawn red box now sits on plain block wall, with a back-box and conduit you can only find under a contrast stretch (`crops/s1-beacon-6x-stretch.png`).
   - Fix: paint a visible back-box with conduit up to the rack.
5. **Budgets** (state them as over; most are inherited):
   - s3's transient maximum of 63 draw calls (budget 60);
   - overdraw about 3.5 (target 2.0);
   - 7 additive items (budget 4 persistent glows; most are left of x 540);
   - texture memory 73.9 MB (budget 45 MB).

## Report accuracy (fix in SLICE.md)

- **"0 pixels change on the column":** it leaves out the transparent slit (must-fix 1). Say that the slit is closed and re-measure.
- **"o0 to o6 are identical right of x 540 too":** in o0-o3, world x 540 is off-screen. Say that only o4-o6 have a 16-px sliver right of x 540, and that it is identical.
- **"The near column is slim, and the see-through silhouettes are gone":** true for the silhouettes. Do not call the column solid until the slit is closed.

## Direction, point by point

| Direction | Result |
|---|---|
| A wall across the corridor that the walkway passes through, not a door facing the camera | **Pass.** A cast cross-wall turned 17°, with the walk line crossing the curtain at x 752. |
| The cross-wall spans the floor from the back wall to the camera-side edge | **Pass** with the cutaway convention: the column foot, then the 0.15 m stub along VP2 out of frame. The wet corridor floor lies only on its near side, the plant slab on its far side. |
| Far column and header behind the actors | **Pass** (s2, s4, s5). |
| Near column in front of the actors, solid, slim | **Fail (small):** the see-through slit (must-fix 1). Slim: pass. The engineer at the safe point stands clear, and WOLF is occluded only, not ghosted. |
| The rolling steel door fills the opening and rises into the header | **Pass** (s1, s2, s4 at 0.53 open, s5 with the tucked bar). |
| Machinery room only as background, at 35-45, with its own light pool and matched saturation | **Pass:** 33.8 visible and 33.9 through the opening, saturation 0.43 against 0.49, pool under high-bay B. Like the approved concept, the room also shows right of the column, where the safe point stands. |
| MANUAL BYPASS wall-mounted at 1.0-1.1 m, wheel readable, hand on the rim while cranking | **Partial.** Backplate, gearbox, guard and a 0.525 m wheel at 1.0 m; rim p90 115. The glove is on the rim, but the pose is idle (should 1), and the plate is detached (should 2). |
| Left of x 540 and the opening identical apart from dust | **Pass** (re-measured above). |
| Lossless where mottling showed; draw calls in budget; real footprint shadows | **Pass:** lossless atlas, p50 54-60, shadows 0.43-0.44. The s3 transient 63 is over budget and stated as such. |

## AI-tell checklist (REAL-LOOK section 3, on the in-game captures)

| # | Item | Result |
|---|---|---|
| 1 | Vanishing lines | **Pass.** The floor seams go to (423, -3). The cross-wall, door, hood, bar, pour joint and stub go to VP2 (-410, -3). The tank head is nearly edge-on, consistent with the catwalk. |
| 2 | One light logic | **Pass.** The pendant pools on the new bay (57-72 under it, about 25 at the sides). The wall pack lights the hood. The cross-wall face brightens toward the pendant and the wall pack. High-bay B lights the tank crest (52 against a wall of 28). No ghost light. |
| 3 | Every part has a job | **Pass.** Conduit to the junction box, wall pack and camera. The guard runs to the operator. The tank has a run pipe on a hanger rod and a plinth. The pump sits on its skid. The catwalk post stands on a base plate. |
| 4 | Nothing floats | **Pass** for the stations (0.44 and 0.43), the backplate, the camera arm and the box. **Note:** the lockdown beacon's mount barely shows (should 4). |
| 5 | Scale | **Pass.** The door is 3.05 m and the wheel 0.525 m at 1.0 m. The buttons sit at about 1.3 m and the slats at real pitch. `DOOR 4B-07` is 8.75 px, under section 8's 12 px; it is flagged for Nathanial. |
| 6 | Doors | **Pass.** The opening is alpha 0, the wall continues round it, and the room's own background is behind it. |
| 7 | No text | **Pass.** Only typeset, listed marks, and both are still proposals. |
| 8 | Detail and values | **Pass.** In greyscale the plant room is quiet and the stations and actors carry the contrast. The stub separates from both floors. The slats are clean and straight, with no warping or smudge. **Minor:** the two-bay finish (should 3). |
| 9 | Wear logic | **Pass**, with the leak note in should 3. |
| 10 | No repeats | **Pass.** |
| 11 | Rule 5 | **Pass.** |
| - | Compositing | **Fail (small):** the slit that shows actors through the near column (must-fix 1). |

## Does it read as a near-future military base?

**Partly, as in round 3.** These read as hardened and machine-run:
- the cast cross-wall;
- the stencilled `SECTOR 4B`;
- the numbered gunship-grey door with caught-between stripes and a scuffed travel line;
- the fixed camera on its arm;
- the junction box and grouped conduit;
- the lockable push-button station;
- zoned, dim lighting.

These still say "secure industrial plant":
- the roller door has no blast mass;
- the room beyond is a tank and pump hall.

The options already listed for Nathanial (a steel armour frame round the opening, the inner blast-door vestibule, `RESTRICTED AREA`) are the right next steps. They add no keypads and no new text beyond the approved list.

**Nothing is taken from the Terminator films:** no names, logos, typefaces, chrome, skulls, red eyes in a skull, or model-number styles.

## Before and after, as a first-time player

| State | Before (main) | After (slice) |
|---|---|---|
| s1 at rest | A garish red gate standing on the floor, and a gold wheel on a pole | A concrete wall across the way with a grey numbered roller door, a camera, and a dim plant room past it. Believable. The text box says "the red seal", but no red seal is in sight (must-fix 2). |
| s2 relay beat | The engineer by the red gate | The engineer at the door face, and the relay on its plinth with a real shadow. Good. |
| s3 crank | The engineer beside a bright gold wheel | A real wall valve with their glove on the rim, but they stand idle. The meter fills on a plate up on the wall. |
| s4 opening | The gate folding | The roller door winding up into its hood with the amber lamp lit, and the room appearing under the bar. Good. |
| s5 open | A gate frame onto a blue tunnel | A true doorway onto a real, dim room, with the green lamp. The best frame. |
| s6 walk through | Walking through the gate | Walking through the doorway; at 1x it reads right. Zoomed in, a sliver of the engineer's arm shows through the column (must-fix 1). |
| s7 safe point | The engineer at the safe point | The engineer stands clear at the safe point. WOLF is cut by the column, but a sliver of his head shows through it (must-fix 1). |
| Seam | - | Hidden by the column, but the two bays read as two finishes (should 3). |

## What I need to pass it

1. Must-fix 1: the near column opaque across the guide-to-jamb slit.
2. Must-fix 2: a red shut lamp, or Nathanial's OK to reword the three lines.
3. Fresh s1, s2, s6 and s7 captures at 1280x720 and in phone shape. Also re-check the column alpha and run the opening re-diff, since the plates are untouched and it should still match.
4. SLICE.md corrected as listed above.

The should-fix items can wait for Nathanial's first look, as long as the hand-off states them, the crank pose above all. After this, one more review pass, then Nathanial.
