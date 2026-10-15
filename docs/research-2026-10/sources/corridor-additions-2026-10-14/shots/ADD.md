# Round 11: fix round 4 of the corridor additions

Scratch only, 2026-10-14. No Git repository or worktree was edited. The fixes are installed in `real-slice/game-add`, and all new work is in `real-slice/add7/fix4/`. Every file in `add7/shots/` that is made from captures was rebuilt from round 11's captures; round 10's crops, measurements and sheet were moved to `add7/fix4/work/r10-package/`.

Nothing under `game-slice`, `game-main`, `shots/`, `design/`, `layers/`, `codex/` or the top-level `provenance.txt` was changed. `add7/provenance.txt` has a round-11 section. Round 10's installed game copy is kept in `add7/fix4/work/r10-game/`, and round 10's ADD.md in `fix4/work/ADD-round10-before-r11.md`.

This round fixes the one must-fix of the real review r4, the should-fix that both r4 reviews raised about the beacons, and the human review's should-fix on the steel blast frame. The inherited items are listed at the end and were not changed.

**How this was checked:**
- **Headless logic:** 14 of 14 suites pass after two imports, run after the last change to any game file (`logs11/tests-add/`). `room_lights_test` now checks the corridor's flash too. `m0_scene_test` passed 6 more times, 3 at a time (`logs11/m0-repeat/`): usual 0 frames, lead-in 0, worst grip 0.80 world px, blast leaf 31-33 frames in step.
- **Rendered stills:** all made with `tools/render/render.sh` and round 8's driver (`add7/fix1/driver`, filed as `fix1/driver/realslice_capture.gd` at ada83fa), unchanged. That covers routes O, A and B at 1280x720 and in phone shape, O at 1600x900, a second O run and the perf runs (`raw11/add`). There is also a new, finer beacon strip (route P, driver `fix4/driver-pulse`): 60 frames 2 game frames apart (1/30 s, 2.0 s), for round 10 (`raw11/r10/P-720`, from `fix4/work/r10-game`) and round 11 (`raw11/add/P-720`). No window opened on the Mac.
  - Every capture (05:01-05:38) was made after the last change to the game copy's art, scene or scripts (05:00). The later edits are two tests and the asset register's wording, which change nothing the game draws; the tests were re-run after them.
- **Not done:** nothing was played by hand, so there are **no feel claims**. The flash rhythm is measured, not judged in motion. No phone, device or export test. No review has run on round 11, and Nathanial has not seen it.

## What to open

- `sheet.png`: every state at 1280x720 as main | round 6 | round 10 (reviewed) | round 11, four phone rows, every crop, and the opening diffs.
- `pairs/<state>-720.png` and `pairs/<state>-phone.png`: the four-way pairs with the HUD hidden.
- `crops/`:
  - `p-beacon-pulse-left-2x.png`, `p-beacon-pulse-right-2x.png`: 20 frames at 1/30 s, round 10 above round 11.
  - `p-beacon-curves.png`: the globe's red and the light it throws, frame by frame, both rounds and both lamps.
  - `d-beacon-*`: one moment of each lamp in s1 and s5.
  - `j-jambs-s1-2x.png`, `j-jambs-s5-2x.png`, `j-jambs-s6-3x.png`, `j-far-plate-s1-4x.png`, `j-near-plate-s1-4x.png`: the jamb plates.
  - Unchanged items, re-cut from round 11's captures: `c-cutaway-s7`, `w-wolf-doorway-s7`, `k-marker-safe-point-s7`, `g-relief-spray-s3`, `l-luminaire-pause-o8-*`, `m1-luminaire-*`.
- `fix4-code.diff`: round 10 to round 11 (263 lines). `add-code.diff`: round 6 to round 11 (1,388 lines).

## What changed, item by item

### Real r4 MUST 1: the lamp now dims and brightens with its light

- **What was wrong:** round 10 tweened only the light's alpha, from 0.55 down to 0.066. The globe's lens tint stayed at full red, so the lamp stayed lit while its light faded almost to nothing.
- **The fix** (`scripts/room_depth.gd`, `scenes/main.tscn`; same nodes, same draw items):
  - `_pulse` now takes the beacon's index and tweens its `Beacon.lens` in the same sequence as its light: full `warning_color` at the top, `warning_color.darkened(0.6)` at the bottom, with the same durations, transitions and phase.
  - It is scoped by a new export, `beacon_lens_trough` (0 by default, so Records' and the junction's drawn housings keep a steady lens). The corridor sets it to 0.6.
  - Unchanged: the settled state (`SETTLED_LENS_DARKEN`, alpha 0.1) once the route is cleared, and the light's own peak (0.55) and trough (0.12 of the peak).
- **Measured** on the new 1/30 s strips (`pulse.json`; "12 reddest px" is the review's own measure, which gives round 10's 159-194 again):

| | Globe, 12 reddest px, trough to peak | Trough / peak | Pearson r against the light under the lamp |
|---|---|---|---|
| Left, round 10 | 159.4 to 194.1 | 0.82 | (lens steady in code) |
| Right, round 10 | 203.4 to 233.0 | 0.87 | (lens steady in code) |
| Left, round 11 | 70.3 to 192.8 | **0.36** | **0.994** |
| Right, round 11 | 91.0 to 233.0 | **0.39** | **0.986** |

  - Over the glass mask (lit glass only, 25 and 66 px), round 11 falls to 0.34 and 0.27 of its peak, with r 0.998 and 1.000.
  - The review's check asked for at most half and r of at least 0.9. Both lamps pass.
  - Headless (`room_lights_test`): lens red 0.40 to 1.00, r 1.000 against the light.
- **Budgets:** 47 draw calls at s1 and 48 while cranking, 7 additive items, 74.70 MB of texture memory, 436 nodes. All the same as round 10.

### Real r4 SHOULD 2 and human r4 SHOULD 2: a real beacon's rhythm

- **What was wrong:** one smooth sine every 2.6 s (about 23 a minute) read as a breathing UI pulse, while a real red rotating warning beacon makes 80-90 flashes a minute ([S21] in REVIEW-real-r4).
- **The fix:** a second new export, `beacon_flash`, set only on the corridor. It gives the lamps a rotating beacon's rhythm:
  - each flash rises in 0.17 s (`TRANS_SINE`, ease in) as the beam sweeps past, then falls in 0.51 s (`TRANS_EXPO`, ease out) as the reflector turns away;
  - one flash every 0.68 s, which is 88 a minute and about 1.5 a second, well under WCAG's three flashes a second;
  - the second lamp runs 0.29 s behind the first, as two beacons on one circuit drift apart;
  - the phase offset is applied once (`Tween.custom_step`), not as an interval inside the loop.
- **Reduced Motion:** the corridor's lamps stop flashing at once and hold lit and steady at the top (light 0.55, full red lens). Turning it off brings the flash back. `reduce_motion` now has a setter that resettles the beacons; the lamp flicker still reads it at each flicker, as before. Records' and the junction's beacons are unchanged.
- **Measured:** 90.0 and 87.8 flashes a minute on the strip (rises through the middle of the light's swing), 88.3 in the headless test over 2.4 s. The light under each lamp still swings 16.0 and 15.0 (round 10: 16.8 and 15.0), because only the rhythm changed, not the peak.
- **Tests:** `room_lights_test` now checks this:
  - only the corridor flashes;
  - the lens tracks the light (r at least 0.9) and falls to at most half;
  - 80-96 flashes a minute;
  - Records keeps a steady lens;
  - Reduced Motion holds the corridor's lamps steady, and turning it off restarts the flash.
  - Its pulse helper now samples through 0.7 s instead of only at the two ends, which a 0.68 s cycle could hit at the same phase.
  - `corridor_additions_test` checks the lens's hue at any moment and the full colour at the top of the flash, instead of a fixed full red.
- **Still needs play:** both reviews said the rhythm can only be judged in motion. Nathanial can keep the slow breathe by setting `beacon_flash = false` in `main.tscn`. The lens fix stays either way.

### Human r4 SHOULD 6: the steel blast frame's side jambs as heavy bolted armour plates

- **What was wrong:** the riveted head plate read as armour, but the sides read as thin steel channels. The far jamb plate was 0.55 m wide on a face foreshortened to about 48 %, so 17 px at 720p, with one row of M24 heads that hardly showed (2 of 10 stood out by 6 levels or more). The near side had only the round-6 65 mm arris angle.
- **The design** (`fix4/door/tools/jamb11.py`, `design/spec.json`, `design/masks/`):
  - **Far jamb:** the plate on the far column's face widens to 0.85 m, to 0.20 m short of the corner with the corridor's back wall, where the bypass chain guard runs. It is 25 mm steel in 36118, the same paint as the head plate, with the same joints at 1.30 and 2.60 m. It carries M30 anchor bolts on 90 mm square plate washers at 300 mm pitch in two rows. Only the outer row shows; the inner row is under the roller's guide, as it would be on a real frame where the guide bolts through it. Above the hood, the head plate's top bolt row is carried on over the new strip. The head plate's own corner keeps round 10's pixels.
  - **Near jamb:** the near column's end face gets the matching jamb plate: 25 mm bare galvanised steel, the column's own armour (its chamfer plate and arris angle are bare steel). It runs 0.20 m from the arris and wraps round the old angle, from the cut wall's top at 0.36 m (the clean cutaway) up to the head plate's top at 3.92 m. It has the same joints, one bolt row, a worn arris, a lit top edge and a 30 mm edge shadow. The status lamp, the push-button station and the conduit stay mounted on top of it, untouched.
  - **Real basis:** a blast door's frame is a steel subframe cast into the opening, and its jamb and head plates are anchored through into the wall so blast and rebound loads go into the structure ([D1] in add7/door/NOTES.md). Wall ends on cart routes are armoured with steel plate.
- **Paint:** one Codex session, built-in image tool in edit mode, C2PA kept: `01a139d9-1863-7681-8bc9-ab42ca7191c0`, archived (`fix4/codex/paint-jamb11/`).
  - The edit target and paint map are made by `codex_inputs11.py`: the door end composed as the game layers its atlas pieces, with white only where each plate shows.
  - The tool made two images. Only the second, which Codex copied, is used. Both are recorded in provenance.
- **Cleanup** (`cleanup11.py`):
  - Codex's paint is used only as luma high-pass detail clamped to ±12 % inside each plate's mask. Codex also recoloured the near plate much lighter and erased DOOR 4B-07 outside the map; none of that is used.
  - Each plate's value is its albedo times the light the round-10 art already carries there (`light-far.npy` and `light-near.npy`, read from the concrete and the old plate around it).
  - The bolts, joints and edge shadows are drawn by script. Each bolt has a washer, a head, a lit rim toward its fitting (the door light for the far plate, the corridor lamp for the near one) and a 1 px cast shadow away from it.
  - Only the atlas's wall and column regions change, only inside the new masks. That is 12,206 px, 0 outside the masks and 0 alpha px (`fix4/door/layers/report11.json`). No region, position, node or draw call changed.
- **Measured in game** (`measure11.json`; bolt contrast = head minus the plate ring round it):

| 720p, s1 | Round 10 | Round 11 |
|---|---|---|
| Far plate width at 2 m | 16.7 px | 25.6 px |
| Near plate width at 2 m | 4.4 px (the 65 mm angle) | 13.7 px |
| Far bolts standing out by 6 levels or more | 2 of 10 (mean 3.7) | 11 of 21: the outer row and the head row (mean 10.0) |
| Near bolts standing out | none drawn | 8 of 8 (mean 7.3) |
| Far plate luma; concrete beside it | 33.2; 25.0 | 31.2; 24.0 |
| Near plate luma; end-face concrete | 32.7 (angle); 26.0 | 29.6; 26.0 |

  - In phone shape: far plate 25.1 to 38.5 px, near 6.7 to 20.5 px, far bolts 12 of 21 standing out, near 8 of 8.
- **As a first-time player** (`crops/j-jambs-s1-2x.png`): both sides of the doorway now read as bolted steel plates, framing the opening with the riveted head plate. At 1x the bolts are small dots, a row on each side. The near column is no wider and no brighter where the actors pass (s6 and s7 crops). It is still solid concrete and steel in front of the actors.

### Real r4 NIT 4: ADD.md's note on round 10's atlas change

- Round 10's section says only the atlas's stub region changed. **That was wrong.** The column region's foot changed too: 1,292 px at atlas x 962-1014, y 582-607, where round 9's galvanised angle became the poché. I checked this against round 9's and round 10's installed atlases. The art is right; only the note was wrong. Round 10's text below is left as written.

## Checks

- **Opening, rule 5** (`opening-diff.json`, `opening-diff/`): o0-o8 pass against main's four runs, rounds 6-10.
  - Left of world x 540 and outside the beacon zones, only main's dust differs (1,335-2,372 px a frame, none of it larger than dust; round 10's counts differ by at most 24 px because the zones follow the found anchors).
  - Against round 10: 0 px outside the zones in every frame.
  - Right of x 540: o4-o6 are 0 px. In o7 and o8, 6,277 and 6,009 px differ. All but 349 are the right beacon's flash. The 349 are the frame's last 5 columns (x 1275-1280), where the wider far jamb plate's edge comes into view, at 4-7 levels.
  - The opening diff now also takes a beacon's anchor from main's lens when the dimmed globe is too dark to find. The zones match round 10's.
- **States s1-s7 against round 10** (`state-diff-720.json`, `state-diff-phone.json`): the only changes are:
  - the two beacons (world x 320-361 and 624-667, y 211-262);
  - the near plate (x 794-807, y 289-444);
  - the far plate (x 709-721, y 312-429, and x 709-718, y 274-294 above the hood);
  - in s4-s7, a few px at x 722-727 where the far plate shows between the guide's angles with the door up.
- **Luminaire** (`luminaire-check.json`): unchanged from round 10 (box step 0.62/0.71, conduit sides 1.0/0.9 apart).
- **Budgets** (`perf-table.md`): 47 draw calls at s1 (round 6: 54), 48 cranking, 7 additive items, 74.70 MB of texture (+0.83 MB on round 6), 2 full-screen translucent layers, 1 emitter only while cranking, 436 nodes. All identical to round 10.
- **CPU, headless** (load about 15): medians 0.21-0.23 ms, p99 0.65-1.73 ms.

## Not changed this round (for Nathanial)

- **Real r4 NIT 3:** the control marker at z 4 also crosses the near column's foot in s6 (24 screen px). Left as is, as the review suggests, unless Nathanial minds. A fix would move the poché strip out of the column sprite first.
- **Real r4 NIT 5 and the human nit on the cutaway's faint upper line:** the reviews point opposite ways (poché top only over a lighter face, or one flat tone). Left for Nathanial; the cutaway is unchanged.
- **Human r4 SHOULD 4, the RESTRICTED AREA plate's tilt** (inherited, minor): left unchanged after checking the geometry.
  - The plate, SECTOR 4B and the concrete's lift joint beside the plate are all set in the face's own plane, toward its second vanishing point (VP2 at world 21, 158.5). Their slopes grow with distance below that point's height: SECTOR 4B 3.4°, the plate's top 5.3° and bottom 7.0°, the steel band 9.7°, the floor line 21°.
  - So SECTOR 4B is not level, as both reviews read it. It is only short and near that height.
  - What reads level are the small round-6 junction boxes. If Nathanial wants the plate level anyway, that is a one-line change in the sign's design. It would put it out of the face's plane.
- **Inherited and unchanged:**
  - COOLANT FAULT stays up through "Safe point saved" (fixed on main by PR #63; check after the port).
  - WOLF's relay surge in s2 reads as a clip-art cloud (main draws it).
  - The shutter's slats sit nearly level while the hood and bottom bar slope.
  - The roller's striped bottom bar shows under the right end of the hood when open.
  - Three yellows when open and three reds when shut.
  - Overdraw (about 3.4) and texture memory (74.7 MB) are over REAL-LOOK's 2.0 and 45 MB; the round-6 haze is still a full-screen layer.
  - The Records and junction beacons are still drawn in code.
  - The inner leaf's bogie box reads like a vent box.
  - The thin conduit at x 852 runs behind the band's top-left corner.
  - The RESTRICTED AREA plate's open choices (printed letters, over the door, black only).
  - The crank pose is still to be re-cut from the approved walk frames.

# Round 10: fix round 3 of the corridor additions

Scratch only, 2026-10-14. No Git repository or worktree was edited. The fixes are installed in `real-slice/game-add`, and all new work is in `real-slice/add7/fix3/`. Every file in `add7/shots/` was rebuilt from round 10's captures.

Nothing under `game-slice`, `game-main`, `shots/`, `design/`, `layers/`, `codex/` or the top-level `provenance.txt` was changed. `add7/provenance.txt` has a round-10 section. Round 9's installed game copy is kept in `add7/fix3/work/r9-game/`, round 9's crops in `fix3/work/r9-crops/` and round 9's ADD.md in `fix3/work/ADD-round9-before-r10.md`.

This round follows Nathanial's two decisions of 2026-10-14 ("Show it as a clean cutaway" and "WOLF comes to the doorway"), fixes every must-fix and should-fix item in the two round-3 reviews that belongs to the additions, and leaves the inherited items alone.

**How this was checked:**
- **Headless logic:** 14 of 14 suites pass after two imports, re-run at the end after the last file changed (`logs10/tests-add/`). `m0_scene_test` also passed 12 more times, run in parallel (`logs10/m0-repeat/`), with 0 usual-sprite frames each time once the crank started, and 0-2 frames of lead-in. The worst crank grip is still 0.80 world px.
- **Rendered stills:** all were made with `tools/render/render.sh`, with round 8's driver (`add7/fix1/driver`, filed as `fix1/driver/realslice_capture.gd` at ada83fa), unchanged. That covers routes O, A and B at 1280x720 and in phone shape, O at 1600x900, a second O run, and the perf runs (`raw10/add`). There is also a new 16-frame beacon pulse strip (route P, driver `fix3/driver-pulse/pulse_capture.gd` at ada83fa; round 11's `fix4/driver-pulse/` is the same driver with a finer route P), made for main, round 9 and round 10 (`raw10/{main,r9,add}/P-720`). No window opened on the Mac.
  - Every capture (00:48-02:24) was made after the last change to the game copy's art, scenes or scripts (00:36). The one later edit is a note in the asset register about the beacon pulse. It changes nothing the game draws, and the tests were re-run after it.
- **Not done:** nothing was played by hand, so there are **no feel claims**, and the beacon pulse is judged from a 16-frame strip, not in motion. No phone, device or export test was run. No review has run on round 10, and Nathanial has not seen it.

## What to open

- `sheet.png`: every state at 1280x720 as main | round 6 | round 9 (reviewed) | round 10, four phone rows, every crop, and the opening diffs.
- `pairs/<state>-720.png` and `pairs/<state>-phone.png`: the same four-way pairs with the HUD hidden.
- `crops/`, one per fix:
  - `c-cutaway-*`: the cutaway.
  - `k-marker-*`: the control marker.
  - `w-wolf-doorway-*`: WOLF at the doorway.
  - `m1-luminaire-*`: the luminaire relight.
  - `p-beacon-pulse-*` and `d-beacon-*`: the beacons.
  - `g-relief-spray-s3-3x.png`: unchanged since round 9, kept for reference.
  - `l-luminaire-pause-o8-*`: the luminaire next to PAUSE.
- `fix3-code.diff`: round 9 to round 10 (289 lines). `add-code.diff`: round 6 to round 10 (1,189 lines). It includes the asset register and leaves out the render driver that only round 6's copy carries.

## What changed, item by item

### Nathanial's decision 1, "Show it as a clean cutaway" (closes real r3 FOR NATHANIAL and human r3 MUST-FIX)

- **What was wrong:** round 9 closed the plant room on the camera side with a 0.36 m cut wall. It was finished like a built knee wall, with galvanised edge angles, M12 anchors, form-tie holes, control joints and a damp foot, so both reviews read it as a wall a player could step over.
- **The fix:**
  - The cut is now drawn as an architectural section, the way This War of Mine and Fallout Shelter cut buildings open. One flat, dark poche (sRGB about 15, 17, 20) covers the corridor face and the cut plane together, with clean straight edges.
  - The angles, anchors, ties, joints and damp foot are gone. So is round 9's Codex paint detail.
  - The floor contact shadow at its foot is kept but made softer, so the poche's lower edge stays crisp against the wet floor.
  - The geometry is round 9's, unchanged: same line, 0.36 m cut, 0.66 m thickness and same ends. The engineer and the SAFE POINT machine stay whole. DOOR 4B-07 is still the only way in.
- **Measured in game (720p, `measure10.json`):**

| | Round 9 | Round 10 |
|---|---|---|
| Section face, mean (std) | 22.4 (9.1) | 13.2 (1.8) |
| Cut top, mean (std) | 27.2 (7.9) | 13.6 (1.7) |

  - The column's end face (21-23) and approach frame (33.7) are unchanged.
  - Engineer at the safe point: 0 px differ from round 9 in their box (x 1022-1074, y 387-502).
  - At s7, part of the cut-top box is covered by the marker, which is now drawn above it. That is why its std goes up there.
- **Pipeline:**
  - Shapes: `fix3/door/tools/cut10.py`, which reuses cut9's geometry, read only.
  - Fill and pack: `cleanup10.py` and `install10.py`.
  - Only the atlas's stub region changes. It is now `Rect2(2, 619, 443, 195)`, in `main.gd`. Every other region and world position is round 9's.
  - **No Codex session:** a flat poche has no material to paint, and painting texture into a section cut would break the convention.

### Nathanial's decision 2, "WOLF comes to the doorway" (closes human r3 SHOULD-FIX)

- **The behaviour:** when the seal is open and the engineer has gone through to the safe point (x >= 800), WOLF walks to the open doorway (`WOLF_DOORWAY_X = 716`) and stands there facing them while "We made it." is up.
  - No line changed.
  - If the engineer comes back nearer, he returns to his round-9 waiting spot (490). This is `_wolf_comes_to_doorway()` and `WOLF_DOORWAY_HOLD_X` in `main.gd`.
- **Where he stands (P0-4's rule), measured in world px:**
  - His drawn body spans x 660-775 and his reach 649-783.
  - Head and forelegs are in the opening (the curtain line is 721.75).
  - His reach ends 2 px short of the near column (785), which is drawn over the actors.
  - His tail is clear of the relay's housing (ends at 648.1) by 0.9 px, and of its relief tailpipe by 10 px painted.
  - His nose is about 43 px from the engineer's body, with 115 px between their centres.
  - The only thing behind him is the MANUAL BYPASS gearbox, which is bolted to the back wall behind the walkway.
- **Check:** `m0_scene_test` now waits for WOLF at the doorway at the safe point. It checks his head is in the opening and his tail clear of the tailpipe, and that his body is clear of every floor machine, the near column and the engineer, inside the camera's view and facing the engineer.
- **Crops:** `w-wolf-doorway-s7-2x.png` and `w-wolf-doorway-wide-s7-1x.png`.

### Real r3 MUST 1: the dark rectangle round the shortened luminaire

- **Cause:** round 9's `far9.py` kept the far plate's old light over a rectangle round the fitting (SOURCE_BOX).
- **The fix:** `fix3/far/tools/far10.py`, deterministic relighting from round 8's plate, with no new paint.
  - The old values are kept only on the fitting's own pixels: body, diffuser, rods and canopies, from round 8's design spec.
  - That mask is feathered over about 2.5 plate px.
  - Above the diffuser, the moved pool's gain fades smoothly to nothing between plate y 229 and 199, the same at every x.
  - The floor streak and the stray-streak inpaint are round 9's.
- **The review's checks, at 720p (`luminaire-check.json`):**

| Check | Round 9 | Round 10 | Limit |
|---|---|---|---|
| Largest step across x 655-668, rows 28-50 (s1 / s5) | 3.84 / 3.34 | 0.62 / 0.71 | 1.5 |
| Conduit sides, x 707-711 against 716-720 | 28.0 / 24.2 (3.8 apart) | 27.3 / 26.3 (1.0 apart) | 2 |

- **Pool position:** the pool's peak is at 682, its centroid at 685 and the floor streak at 686, against the diffuser's centre at 687 on this measure.
  - Measured against 687.5, the review's figure, the peak is 5.5 px off.
  - The wall under the fitting is now a flat plateau, within about 3 levels from x 670 to 697. Its highest column is a concrete texture feature at 682.
  - I tried moving the pool further right, with WALL_EXTRA at 9 (installed), 4.5, 2, 0 and -3. The peak stays at 682 until it jumps to 694, while the centroid moves from 686 to 696.
  - So no setting puts both nearer the fitting, and the installed plate is round 10's first build (`fix3/far/scan/README.txt`).
- **Rule 5:** still holds in o7/o8 (below).
- **Crops:** `m1-luminaire-box-r8-r9-r10-s5-4x.png` and `m1-luminaire-profile-round{8,9,10}-2x.png`.

### Real r3 SHOULD 2: the control marker hidden by the cut

- **The fix:** the engineer's cyan control marker (`m0_actor.gd`) now draws on its own child canvas item at absolute z 4. That is above the near column, camera and cut section (z 3), so no wall ever cuts it.
  - The line is unchanged: same place, colour, width and length.
  - It redraws when control changes.
- **Marker pixels at s7, 720p, in the same box:**

| Round 8 | Round 9 | Round 10 |
|---|---|---|
| 240 | 136 | 288 |

  - Round 10 is higher than round 8 because the whole line now shows, where round 8's lower edge sat behind the old curb.
- **Crops:** `k-marker-safe-point-s7-4x.png` and `k-marker-count-s7-r8-r9-r10-6x.png`.

### Real r3 SHOULD 3: the crank test under load (test only)

- **The cause:** `_sample_crank_grip` samples on physics frames, but the pose changes in `_process`. Under load, a few physics steps can run between the press and its first `_process`.
- **The fix:**
  - Usual-sprite frames before the first crank frame are now counted as lead-in (input latency), bounded at 6.
  - Usual-sprite frames after the crank has started must be 0, which is stricter than round 9's "at most 1".
- **Result:** 13 runs, 12 of them in parallel. Every run had 0 usual frames once cranking started and 0-2 frames of lead-in, with A 57-69 and B 27-37 frames.

### Human r3 SHOULD-FIX: the beacons read as a few red pixels

- **The art is unchanged** (round 9's `corridor-beacons.png`, md5 72efa04f…). The globes stay at their real size.
- **The pulse changed:**
  - The two additive light regions now swing from nearly dark to a brighter top.
  - The peak alpha went from 0.40 to 0.55, and the trough from 0.55 to 0.12 of the peak.
  - This uses `beacon_peak_alpha` and `beacon_trough` on RoomDepth, set in `main.tscn`. Other rooms keep the old defaults.
- **Measured over the 16-frame strip (2.67 s):** the mean red excess under each globe.

| | Main | Round 9 | Round 10 |
|---|---|---|---|
| Left beacon swing | 6.2 | 6.5 | 17.6 |
| Right beacon swing | 5.6 | 5.5 | 14.9 |
| Left, top of the pulse | 7.1 | 8.1 | 13.6 |

  - The same additive items are used, so the count stays at 7.
- **Crops:** `p-beacon-pulse-{left,right}-2x.png`, and `pulse.json`. Whether it reads as an alarm going off can only be judged in motion.

### Not changed (the item is a nit or inherited)

- **NIT, not fixed:** the thin conduit at x 852 runs behind the steel band's top-left corner. It is 1 px at 1x.
- **Inherited, unchanged:**
  - COOLANT FAULT stays up through "Safe point saved"; main's PR #63 fixes it.
  - The shutter's slats sit nearly level while its hood and bottom bar follow the face's slope.
  - SECTOR 4B is set level against the wall's slope.
  - The roller's striped bottom bar shows under the right end of its hood when open.
  - Three yellows when open and three reds when shut.
  - Overdraw (about 3.4) and texture memory (74.7 MB) are over REAL-LOOK's 2.0 and 45 MB.
  - The Records and junction beacons are still drawn in code.
  - The inner leaf's bogie box reads like a vent box.
  - The RESTRICTED AREA plate is printed, over the door and black only.
  - The crank must be re-cut from the approved walk frames.

## Rule 5 and the other states

- **Opening (`opening-diff.json`, `opening-diff/`):** o0-o8 pass against main's four runs and rounds 6, 7, 8 and 9.
  - Left of world x 540 and outside the beacon zones, 0 px differ from rounds 6-9, and only main's dust differs from main.
  - Right of x 540, o4-o6 differ by 0 px.
  - In o7/o8, round 10 differs from round 9 by 8,878 and 6,384 px. These are the luminaire's relit wall and the right beacon's light, which sits right of x 540 in those frames and pulses deeper now.
  - WOLF's cage shows only main's dust.
- **States against round 9 (`state-diff-720.json`, `state-diff-phone.json`):** the only differing areas are:
  - the cut section, in every state;
  - the two beacons' light (pulse phase);
  - the luminaire's wall above the beacon;
  - in s7, WOLF's old spot (x 432-551) and his new one (x 658-777).

  Nothing else moved.

## Budgets (render.sh, `perf-table.md`, `perf.json`)

| Measure | Round 6 | Round 9 | Round 10 | Limit |
|---|---|---|---|---|
| Draw calls, s1 | 54 | 47 | 47 | 54 |
| Draw calls while cranking (s3) | 55 | 48 | 48 | – |
| Additive items | 7 | 7 | 7 | 7 |
| Texture memory | 73.87 MB | 74.70 MB | 74.70 MB | +2 MB on round 6 |
| Nodes | 433 | 434 | 436 | – |

- The two new nodes are the two actors' control-marker canvas items.
- There are 2 full-screen translucent world layers, and 1 emitter (the relief jet), only while cranking.
- **CPU side** (`godot --headless`, re-run with the machine's load average about 90): p50 0.23-0.47 ms per state, in line with earlier rounds. The p99 values reflect that load.

## Codex and provenance

- No Codex session was started this round. The cutaway is a flat section fill, and the far plate and the beacon pulse are deterministic.
- round 9's `paint-cut9b` detail is no longer used anywhere in the installed atlas. Its record stays in `add7/provenance.txt`.
- All earlier sessions are archived.
- No text was painted or added.
- **Installed (md5, identical to the delivered file):**
  - `corridor-seal-atlas.png`: 16e54f8a589f206463acd8003682916b (`fix3/door/game/`)
  - `corridor-far.png`: a2db51a0cd09aa97c6f7a09b014cc98d (`fix3/far/layer/`)
  - `corridor-beacons.png`: unchanged, 72efa04f54b780b044b12c0bbb0fd3ce
- The asset register (`manifest.json`) has round-10 notes on the atlas, the far plate and the beacons' pulse.

## Round 10's changes in the game copy (game-add/apps/game)

- `scripts/main.gd`:
  - `WOLF_DOORWAY_X`, `WOLF_DOORWAY_HOLD_X` and `_wolf_comes_to_doorway()`;
  - facing the engineer in the doorway;
  - the stub region `Rect2(2, 619, 443, 195)`;
  - comments.
- `scripts/m0_actor.gd`: the control marker on its own canvas item at z 4.
- `scripts/room_depth.gd`: `beacon_peak_alpha` and `beacon_trough` (the defaults keep the old pulse).
- `scenes/main.tscn`: the corridor's `beacon_peak_alpha = 0.55` and `beacon_trough = 0.12`.
- `tests/m0_scene_test.gd`:
  - WOLF at the doorway at the safe point;
  - the crank lead-in counted separately;
  - no usual-sprite frame once the crank starts.
- `assets/props/corridor-seal-atlas.png` and `assets/rooms/corridor-far.png`.
- `assets/manifest.json`: round-10 notes.

---

# Round 9: fix round 2 of the corridor additions

Scratch only, 2026-10-13. No Git repository or worktree was edited. The fixes are installed in `real-slice/game-add`, and all new work is in `real-slice/add7/fix2/`. The package in `add7/shots/` was regenerated, and every file in it now shows round 9.

Nothing under `game-slice`, `game-main`, `shots/`, `design/`, `layers/`, `codex/` or the top-level `provenance.txt` was changed. `add7/provenance.txt` has a new section at the end. Round 8's installed game copy is kept in `add7/fix2/work/r8-game/`.

**How this was checked:**
- **Headless logic:** 14 of 14 suites pass after two imports (`logs9/tests-add/`). `m0_scene_test` passed 3 more times, with no errors or leaks, and the worst crank grip was 0.80 world px in every run (`logs9/m0-repeat/`).
- **Rendered stills:** all were made with `tools/render/render.sh`, and no window opened on the Mac.
  - Round 9 was captured with round 8's driver (`add7/fix1/driver`, filed as `fix1/driver/realslice_capture.gd` at ada83fa), unchanged: routes O, A and B at 1280x720 and in phone shape, O at 1600x900, a second O run, and the perf runs (`raw9/add`).
  - Main, round 6 and round 8 are compared from round 8's render.sh captures with the same driver (`raw8/`). Main and round 6 did not change.
- **Not done:** nothing was played by hand, so there are **no feel claims**. No phone, device or export test was run. No review pass has run on round 9, and Nathanial has not seen it.

## What to open

- `sheet.png`: every state at 1280x720 as main | round 6 | round 8 (reviewed) | round 9, four phone rows, every crop, and the opening diffs.
- `pairs/<state>-720.png` and `pairs/<state>-phone.png`: the same four-way pairs, HUD hidden.
- `crops/`: one crop per fix. The `m1-*` crops are MUST 1, and the `m2-*` crops are MUST 2. `m2-luminaire-profile-round8-2x.png` and `-round9-2x.png` are the review's own measure, redrawn: cyan is the fitting's centre, yellow the wall pool's peak, orange the floor streak's peak.
- `fix2-code.diff`: round 8 to round 9 (99 lines). `add-code.diff`: round 6 to round 9 (1,058 lines, including the asset register; the render driver that only round 6's copy carries is left out). Both were rebuilt from the final install.

## What changed, item by item

### Must-fix items from the two round-2 reviews

**Real MUST 1 and human MUST: the plant room could be reached round the door.** This item was inherited from round 6. Both reviews made it a must, and it is inside the door end, so it is fixed this round.
- **What was wrong:** right of the near column, the corridor's wet floor ran on in front of a 0.15 m curb into the plant room, one step up. A player reads that as "step up and walk round the door".
- **The fix (the real review's preferred one):** the cross-wall is carried on its own line from the column's foot to the bottom-right edge of the view, as a cut concrete section.
  - It is a low cast wall: corridor face, a damp darker foot, plugged form-tie holes, two formed control joints and its full 0.66 m top.
  - Galvanised steel edge angles run on both arrises, with M12 anchor heads.
  - A footprint contact shadow on the corridor floor stops the wet floor at its face.
  - The plant room's floor and the safe point's plinth stay visible above it.
  - DOOR 4B-07 is the only way in.
- **Height, 0.36 m, not the review's 0.6-0.7 m. This is a geometry limit:**
  - The section's 0.66 m top has a plant-room arris, which starts at the column's chamfer. On screen it rises toward the engineer's boots at the safe point.
  - At 0.60 m it would hide up to 5 world px of both boots.
  - A first try at 0.42 m, rendered with render.sh, still took the rear heel's last 1-2 screen px.
  - At 0.36 m the silhouette stays at least 1.5 world px below the soles (`fix2/door/design/spec.json`).
  - **Check:** in s7, the engineer's box (x 1022-1074, y 387-502 at 720p) is identical to round 8's: 0 px differ (`measure9.json`).
  - The section's top runs below the station's plinth everywhere: y 447-472 under the station, against its base at about 440-447.
- **Value:** the section is at or below the column's, as the review asked. In game, at 720p:

| Surface | Mean luma |
|---|---|
| Section face | 22.3 |
| Section top | 26.8 |
| Column end face | 24.1 |
| Column approach frame | 33.6 |
| Round 8 curb face / top | 29.6 / 36.4 |

- **The junction:** where the section's top meets the column's chamfer, two edges met with a notch of up to 2.5 world px that showed the room through. It is grouted solid, as a real wall/pier junction would be. That is 5 px of the 4 px-per-world-px layer, and `m0_scene_test`'s "no see-through gap" check passes.
- **Pipeline:**
  - Shapes: `fix2/door/tools/cut9.py`.
  - Edit target and map: `codex_inputs9.py`.
  - Paint: one Codex edit-mode session, `paint-cut9b`, used only as clamped luma detail inside the masks.
  - Cleanup and pack: `cleanup9.py` and `install9.py` (`fix2/door/tools/` at ada83fa; round 10's `fix3/door/tools/cleanup10.py` and `install10.py` replaced them). Every value is the design light times one constant per part.
  - Only the atlas's stub region changes (now `Rect2(2, 619, 443, 202)` at world (762.5, 440.0)), plus the column region's lower rows. Every other region and position is round 8's.
  - The superseded 0.42 m try (`paint-cut9`) is kept and recorded.
- **The streak in the same frames:** the corridor-floor streak at x 1185 reflected a lamp behind that wall, and it was taken out of the far plate.
  - Method: an inpaint of plate x 1747-1824, with the low frequency interpolated across and the floor's own texture kept.
  - The door light's own reflection under the door (plate x ~1460) is kept.
  - **In game:** the zone's column profile, rows 630-700 at x 1140-1240, now reads max/median 1.25 with no peak (round 8: 1.80, peak at x 1181).

**Real MUST 2: the luminaire's wall pool and floor streak now sit under the fitting.**
- **Method:** deterministic relighting of the far plate in linear light, with no new paint (`fix2/far/tools/far9.py`).
  - **The wall pool:** a fitted smooth gain, G = 1 + A(y)·gaussian(x), multiplied by G(x + d)/G(x). The same concrete carries the light at its new place, and the fitting's own pixels keep ratio 1.
  - **The floor reflection:** treated as an additive cool-white reflection. Its luma excess is taken out where it was and added back 44 plate px to the left, so its patchy pattern moves with it.
- **In game,** with the review's own measure (`luminaire-check.json`; s1 and s5 at 720p, fitting centre x 687):

| Measure | Round 8 | Round 9 | Target |
|---|---|---|---|
| Wall-pool peak / centroid | 731 / 724.4 | **682 / 685.0** | ±5 of the fitting |
| Floor-streak peak | 725-726 | **686** | ±5 of the fitting |

  The wall-pool peak sits at the edge of the tolerance (-5) and its centroid at -2.
- **PAUSE clearance:** the fitting itself is round 8's, so it keeps its clearance.

### Should-fix items

**Human should-fix: the beacons did not read at 1x.**
- **The change:** the computed light is stronger.
  - Red wall pool ×2.0.
  - Glass bloom 0.45 → 0.70, over a 3.0 px radius (was 2.4).
  - The globe keeps its real 0.14 m size, as the real review asked. Fixture, globe and guard pixels are round 8's exactly.
- **Measured** (s1, one pulse phase): the mean red excess in a 52x60 px box under each globe rose from -0.3 to 4.5 (left) and from -11.5 to -5.6 (right).
- **Atlas:** the light regions are now 85x109 (were 83x107), and `main.tscn` has the new regions and offsets. Same paint, no new session.
- **Not judged:** the pulse cannot be judged from stills, so whether the alarm sells in play is open.

**Brief (g) and the real review's note: the coolant jet is faint again.**
- **The change:** alpha 0.3 → 0.2 in `FxPresets.relief_jet()`.
- **s3 zone** (world 644-656, 421-441):

| Measure | Round 8 | Round 9 |
|---|---|---|
| Mean | 79.6 | 65.3 |
| p90 | 136.3 | 108.9 |
| Max | 166.0 | 133.6 |

**Human should-fix (round-8 change, needs Nathanial): WOLF is far from the door at the safe point. Not changed; it is his call.**
- **Why nothing nearer fits:** WOLF's drawn body is about 134 world px long (reach 67).
  - The floor between the relay (561.9-648.1) and the bypass wheel (700) is about 50 px.
  - The doorway between its jambs is about 63 px.
  - Between the near column (to 817.5) and the station (from 841) is 24 px.
  - Right of the station is 49 px.
  - So x 490, just left of the relay, is the nearest spot where he stands clear of every machine, frame and the engineer.
- **The two ways out, for Nathanial:**
  - (a) Change the safe-point line ("…I chose the relay. We made it."), which is story text.
  - (b) Let WOLF stand in the doorway in front of the wall-mounted wheel. It is behind him in depth, but it reads as "over a machine" in a still.

**Doc nits (real review):**
- The beacon atlas is 256x156 and has been since round 7; round 8's ADD.md and register said 256x160. The register is corrected.
- The luminaire hung about 0.55 m from its pool, not 0.35 m. That is now moot.

### Optional, not done

- **Crank frame A's near arm** (6x only): it will be redrawn when the crank is re-cut from the approved walk frames.

## Measured

**Rule 5** (`opening-diff.json`, `opening-diff/`; `fix2/tools/opening_diff9.py` at ada83fa). o0-o8 against main, three older main runs, round 6, round 7 and round 8:
- Left of world x 540 and outside the two beacon zones: **0 px** against rounds 6, 7 and 8, and only main's dust against main (0 non-dust blobs).
- The beacon zones differ from round 8 by 2,700-10,700 px (the stronger light).
- o4-o6 right of x 540: 0 px.
- o7 and o8 right of x 540 differ from round 8 only at the door end (the pool, the streaks and the section), plus the old bay lamp's flicker noise.

**Every change against round 8** (`state-diff-720.json`, `state-diff-phone.json`), in world px, in every state:

| Region (world px) | What changed |
|---|---|
| x 603-682, y 420-560 | the floor streak |
| x 586-710, y 175-268 | the wall pool and the right beacon |
| x 783-960, y 438-560 | the section and the stray streak |
| x 321-360, y 213-258 | the left beacon |
| x 643-680, y 368-378, about 150 px | the lower wall's relight |
| x 668-676, y 424-437, s3 only | the fainter jet |

Nothing else changed. WOLF and the engineer are where they were.

**Budgets** (`perf-table.md`; render.sh, 1280x720), main -> round 6 -> round 7 -> round 8 -> round 9:

| Measure | Main | Round 6 | Round 8 | Round 9 | Limit |
|---|---|---|---|---|---|
| Draw calls, s1 | 72 | 54 | 47 | **47** | 54 |
| Draw calls, s3 cranking | 73 | 55 | 48 | **48** | – |
| Draw calls, s7 p50 (max) | 71 (75) | 54 (58) | 46 (50) | **46 (50)** | – |
| Additive items, s1 | 8 | 7 | 7 | **7** | 7 |
| Texture memory, s1 | 71.97 MB | 73.87 MB | 74.70 MB | **74.70 MB** (+0.83 against round 6) | +2 MB |
| Overdraw estimate, s1 | 3.60 | 3.54 | 3.46 | 3.47 | – |
| Particle emitters on, s3 | 3 | 1 | 1 | 1 | – |

The new section replaces the old stub inside the same atlas region, the far plate and beacon atlas keep their sizes, so no draw call or texture memory was added. Every state's row, and the headless CPU times, are in `perf-table.md`; frame times inside render.sh are software GL and are left out.

## Inherited, listed and not changed

1. **SECTOR 4B is set level** against the face's slope (round 6's typeset text; it needs the text layer redone).
2. **COOLANT FAULT** stays up after the relay is dealt with. Main has since fixed this (PR #63, 154d42a), and it will come in when the additions are rebased.
3. **When open, the roller's striped bottom bar** peeks out only under the right end of the hood.
4. **Colour counts:** three yellows when open and three reds when shut (Nathanial's choices).
5. **Budgets against REAL-LOOK:** overdraw (about 3.4) and resident textures (about 74.7 MB) are above REAL-LOOK's 2.0 and 45 MB.
6. **Other rooms' beacons:** the Records and junction beacons still use the code-drawn housing.
7. **The human review's nits:**
   - The inner leaf's bogie box reads more like a vent box.
   - The far jamb's liner is subtle.

## For Nathanial (choices, not defects)

- **The section's height:** 0.36 m reads as a low cast wall, not as a full cutaway. The options are:
  - accept it;
  - a taller section (0.6 m), which would hide the bottom of the engineer's boots at the safe point (physically correct, since they stand behind it);
  - a guard rail on top, which would cross in front of the safe point.
- **WOLF at the safe point:** options (a) and (b) above.
- **The beacons:** the stronger pool and bloom, with the globe still at real size. The pulse is not judged.
- **The RESTRICTED AREA plate:** unchanged and still open. It has printed letters rather than a bridged stencil, sits over the door rather than beside it, and is black only.
- **The crank pose:** it must be cut again from the approved walk frames when they land.

## Files (round 9)

- **Game copy `game-add/apps/game/`:**
  - `scripts/main.gd`: the stub region and position, and the comment.
  - `scripts/fx_presets.gd`: jet alpha 0.2.
  - `scenes/main.tscn`: the beacon light regions and offsets.
  - `assets/props/corridor-seal-atlas.png`, `assets/rooms/corridor-far.png`, `assets/props/corridor-beacons.png`.
  - `assets/manifest.json`: round-9 notes on corridor-seal-atlas, corridor-far and corridor-beacons, and the 256x156 correction.
- **Work `add7/fix2/`:**
  - `door/`: `tools/cut9.py`, `codex_inputs9.py`, `cleanup9.py`, `install9.py` (the last two `fix2/door/tools/` at ada83fa); `design/`, `layers/` (`portal-front.png`, `report9.json`), `game/` (atlas, regions); `work-042/` (the superseded 0.42 m design).
  - `far/`: `tools/far9.py`; `layer/` (plate, `report.json`, before/after crops).
  - `beacons/`: a copy of round 8's tools and design, with the R9 light, and `layers/`.
  - `codex/`: `paint-cut9b` (used), `paint-cut9` (0.42 m try, not used) and `empty-run-r9` (a wrong-path empty run, no image), each with prompt, refs, out (C2PA kept), `run.log` and `session.txt`; `run_job.sh`; `archive.log`.
  - `tools/`: `tests.sh`, `render_run.sh`, `capture_all.sh`, `headless_perf.sh`, `opening_diff9.py`, `state_diff9.py`, `perf_table9.py`, `package9.py`, `luminaire_check9.py`, `measure9.py` (all `fix2/tools/` at ada83fa; round 11's `fix4/tools/` holds the current copies), `preview.py`, `crop.py`, `side.py` (still filed in `fix2/tools/`).
  - `work/`: `r8-game/` (round 8's installed copy), previews.

---

# Round 8: fix round 1 of the corridor additions

Scratch only, 2026-10-13. No Git repository or worktree was edited. The fixes are installed in `real-slice/game-add`. All new work is in `real-slice/add7/fix1/`, and the package in `add7/shots/` was regenerated. Nothing under `game-slice`, `game-main`, `shots/`, `design/`, `layers/`, `codex/` or the top-level `provenance.txt` was changed; `add7/provenance.txt` has a new section at the end. The headless perf run also used round 7's private main and round-6 copies in `add7/integrate/probe/` (its driver is copied in and removed after, as in round 7). `raw8/add/*-try*` are this round's trial captures, kept for the record.

**How this was checked:**
- **Headless logic:** 14 of 14 suites pass after two imports (`logs8/tests-add/`). `m0_scene_test` was also run five more times on the final copy (`logs8/m0-repeat/`).
- **Rendered stills:** all made with `tools/render/render.sh`, and no window opened on the Mac. Main, round 6 and round 8 were all re-captured this round with one driver (`add7/fix1/driver`, filed as `fix1/driver/realslice_capture.gd` at ada83fa): routes O, A and B at 1280x720 and in phone shape, plus O at 1600x900, plus perf runs. Round 7 is compared from its own render.sh captures (`raw7/add`).
- **Not done:** nothing was played by hand, so there are **no feel claims**. No phone, device or export test was run. No review pass has run on round 8, and Nathanial has not seen it.

## What to open

- `sheet.png`: every state at 1280x720 as main | round 6 | round 7 | round 8, four phone rows, every crop, and the opening diffs.
- `pairs/<state>-720.png` and `pairs/<state>-phone.png`: the same four-way pairs, HUD hidden.
- `crops/`: one crop per fix, at 3x unless the name says otherwise.
  - `l-luminaire-pause-o8-*` are with the HUD, at 720, 1600x900 and phone.
  - `w-wolf-safe-point-s7-1x` shows round 7 | round 8.
- `fix1-code.diff`: round 7 to round 8 (417 lines). `add-code.diff`: round 6 to round 8 (1,890 lines, including the asset register).

## What changed, item by item

### Must-fix and should-fix items from the two reviews (additions)

**MUST 1 / human should-fix (a): the blast frame now reads as steel, and the door light is whole again.**
- **Design** (`fix1/door/tools/portal8.py`): a continuous 40 mm steel liner.
  - The head band runs from 3.05 m to 3.80 m, so it shows 0.30 m (11-12 world px) above the hood.
  - The jamb strip is 0.55 m wide on the face.
  - Joints are at most 1.25 m apart: head at a = -1.0, 0.2 and 1.4 m; jamb at h = 1.3, 2.6 and 3.05 m.
  - A 1-px lit top arris faces the door light, and a lit outer arris faces the corridor luminaire. Under the upper plate at each joint there is a 1-px shadow.
  - Dark M24 anchor heads, each with one highlight, sit at 0.30 m pitch.
  - The near column carries the band over its 0.16 m approach face.
- **The lamp:** the plates stop 3.75 world px under the door light (measured from the masks). Its bracket, body, lens and feed are round 6's pixels exactly: `lamp_px_equal_round6: true`, and 0 new pixels lie within 2 world px of it (`layers/report8.json`).
- **In game, s1 at 720p:**

| Measure | Round 6 | Round 7 | Round 8 |
|---|---|---|---|
| Head band, mean / p90 | 41.0 / 50.9 | 38.3 / 45.9 | **50.5 / 64.2** |
| Concrete beside it | 40.9 | 40.9 | 40.9 |
| Jamb strip, mean | 33.1 | 30.6 | **41.4** |
| Door-light lens, p90 / max | 221 / 240 | 92 / 149 | **221 / 240** |

  The band sits inside the 45-55 target, against concrete at about 41.
- **Honest note:** 36118 Gunship Gray cannot read lighter than this concrete under the same light. The liner's albedo (0.315, 0.345, 0.39) was set to meet the review's value target, so it reads as a lighter, cooler painted steel, not as 36118.

**MUST 2 / human should-fix (c): the inner blast leaf reads heavier.** No change to timing, collision or the open value.
- **Leading edge:** 0.36 m (was 0.24 m), in a 0.40 m slot inside the 0.66 m wall.
- **Seams:** horizontal weld seams (groove plus lit bead) at 1.0 and 2.0 m, and vertical sheet seams.
- **Nose:** a 0.10 m steel nose channel with a lit arris and a rubber seal.
- **Bogies:** two bogie housings, 0.30 x 0.60 m, standing on the rail, each with a lit top, a dark side and 8 bolt heads.
- **Receivers:** three locking-bolt receivers on the leading edge, also on the parked edge in the pocket's mouth.
- **Foot:** a rubber sweep.
- **Face value:** in s4 the face reads mean 34.9 (round 7: 28.3).
- **Feathered contact shadow:** `BlastLeaf` draws a strip on the threshold in front of the leaf's foot. It uses an 8x8 solid black patch of the same atlas, with vertex alpha going from 0.62 at the foot to 0 at 0.14 m, so it still batches. This softens the aliased foot line.

**MUST 3 / human should-fix (f): the crank pose is now the same drawing as the in-game engineer.**
- **How it was made** (`fix1/crank/tools/rig.py`): the frames are cut from `rowan-side-right-provisional.png` itself.
  - The legs are kept.
  - The torso leans 6 degrees in A and 9 in B, about the belt.
  - Each arm is a two-bone IK onto the wheel's rim. Both gloves grip it: A at 8 and 10 o'clock, B at half past 9 and half past 11 (one tick on).
- **Codex:** one edit-mode session repaired only the seams (arms, where the arms were, the hip seam).
- **Cleanup:**
  - Codex's pixels are used only in those zones.
  - Its colour is matched to the sprite, and magenta is despilled.
  - One cut sliver is removed.
  - The legs below the hip seam are the sprite's own pixels: 14,486 of 14,486 in A and 14,328 of 14,328 in B are identical.
- **In the game:** drawn at the sprite's own 0.188 scale, from cells centred on the sprite's centre, so the boots stand exactly where they always do.
- **Glove fit:** in Python the gloves sit 0.3-0.7 world px off the rim line (`frames/report.json`).
- **Headless, in play:** every crank frame has both gloves at most **0.80 world px** off the rim line and 0.81 px from their grip points (A 62 and B 34 frames, 0 usual-sprite frames). The test now checks both gloves.
- **Any hold length:** B shows for at most half a tick, so the regrip still shows when another job shortens the hold to about 2 s.

**Should 4: the `m0_scene_test` failure (1 in 12).**
- **Cause:** the race is in the test, not in `main.gd`. The game reads USE in `_process`, and `process_frame` is emitted before `_process`. When two physics steps fall in one frame, the test resumed after `await physics_frame; await process_frame` before the game had seen the release.
- **Fix:** the test now waits one more `process_frame`.
- **Why `main.gd` is unchanged:** the review's suggested change there would do nothing. `held_ticks > 0` implies `holding`, so the `elif` can never be skipped on a release frame.
- **Result:** passes in the full run and in five more runs on the final copy, 6 of 6 (`logs8/tests-add/`, `logs8/m0-repeat/summary.txt`). That is not proof the race is gone, only that it did not show.

**Should 5: the s3 perf row now measures cranking.**
- **How:** the round-8 driver keeps USE held through the 300-frame hold and holds the count under the last tick, so the seal never opens. It also records `door_open_after`.
- **s3:** draw calls main 73 -> round 6 55 -> round 8 **48**. The jet is emitting (1), the door stays shut, and there are 7 additive items.

**Human should-fix (d): the beacons.**
- **Stronger pool:**
  - Spill 0.8 -> 1.0.
  - A broader d/r^2 skirt, so the red reaches the pipes below.
  - The light box faded at its edges, so no box edge can show.
  - Glass bloom 0.30 -> 0.45.
- **Measured** (s1, one pulse phase, 52x60 px of wall below each lamp): the mean red excess rose by 2.9 and 2.8 levels against round 7. It is visible at 3x and modest at 1x (`crops/d-beacon-*`).
- **Lens size:** kept at its real 0.14 m. The real review said not to enlarge it; the human review asked for a slightly larger lens. Nathanial's call.
- **Left lamp's feed:** three wider one-hole straps (0.29, 0.59 and 0.89 m) with lit tops and a hairline wall shadow, so it reads as fixed to the wall rather than as a hanging wire. It is still a conduit drop from the tray: real, and allowed by the real review.
- **Paint:** same Codex paint, no new session. The atlas is 256x160 (was 256x156), and `main.tscn` has the new regions and offsets.

**Human should-fix (g) and the real review's optional note: the coolant discharge.**
- **Route:** the relief valve's tailpipe now carries on down the relay's side: union, 40 mm galvanised drop, two pipe clamps with brackets to the coolant pipe. It ends open at **0.44 m above the floor**. Real practice pipes discharge downward to a safe point, supported; round 7's plume sources apply.
- **Damp patch:** on the floor under the outlet.
- **Codex:** one edit-mode session. The drop's value is pinned to round 7's own tailpipe: luma 80.4 against 80.3.
- **Spray:** `FxPresets.relief_jet()` is now a short, denser, slightly fanned spray from `RELIEF_OUTLET` (649.75, 422.25) to the floor about 18 px below.
  - Settings: 22 streaks, 0.22 s, spread 9 degrees, gravity 120, alpha 0.3, normal blend.
  - Zone luma: mean 82.8 and p90 141 (round 7: 55.5 and 73.9).
  - It is no longer at the engineer's head height (`crops/g-relief-spray-s3-3x.png`).
- **Unchanged:** one emitter, no additive item.

### Also in this round's brief (from the PR #58 landing), not done in round 7

**The luminaire by the PAUSE button.**
- **New fitting:** the far plate's 1.2 m bar became a **0.6 m vapour-tight LED fitting**:
  - grey body with end caps;
  - opal diffuser lit from inside;
  - two suspension rods with ceiling canopies.
- **Position:** plate x 1213-1261, beside its feed conduit. The old bar's ends and hangers were inpainted from the wall, and the beacon's feed conduit runs on through.
- **Paint:** one Codex session. It painted the fitting 28 px to the right, and the cleanup samples it there (`PAINT_SHIFT`).
- **Clearance in o8**, fitting end to PAUSE border:

| Shape | Gap |
|---|---|
| 1280x720 | 30 px |
| 1600x900 | 37 px |
| Phone (1920x1080 game image) | 44 px |

  In round 6 and round 7 the bar ran under the translucent button (`crops/l-luminaire-pause-o8-*`).
- **Honest note:** the fitting hangs about 0.35 m left of where round 6 painted its light pool. The pool is broad, and nothing else in the door end changed.

**WOLF at the safe point (and every WOLF spot in s1-s7).**
- **The problem:** WOLF's drawn body is about 130 px long (`WOLF_REACH` 67). Near the door end there is no floor where he fits clear of the relay, the bypass, the doorway's near column (drawn in front of the actors), the safe point's station and the engineer.
- **The fix:** once the seal is open and the engineer is past his clear spot (x >= 578), WOLF waits at his existing clear spot, `WOLF_BYPASS_CLEAR_X` (490), facing the engineer. He follows again when the engineer comes back (`_wolf_waits_for_safe_point()` in `main.gd`).
- **Spots on route A, round 8:** s1 490, s2 and s4 592 (on the relay contact, by design), then s5-s7 **490**.
  - In round 7 they were 647 in s5, over the relay and the bypass; 692 in s6, over both; and 743 in s7, behind the near column.
  - On route B he is at 490 throughout.
  - The opening is unchanged (rule 5).
- **New check in `m0_scene_test`:** at the safe point both are wholly in view, with WOLF clear of every machine, the column and the engineer, and facing them.
- **Tests:** two existing expectations ("WOLF follows again") now accept his waiting.
- **Nathanial should judge this:** it is a presentation change; WOLF no longer walks through the door with the engineer.

## Measured

**Rule 5** (`opening-diff.json`, `opening-diff/`; `fix1/tools/opening_diff8.py` at ada83fa):
- o0-o8 against this round's main, three older main runs, round 6 and round 7: left of world x 540 and outside the two beacon zones, **0 px against round 6 and round 7**, and against main only main's dust (0 non-dust blobs).
- Each beacon zone contains main's red lens.
- o4-o6 right of x 540: 0 px.
- o7 and o8 against round 7 change only at the luminaire, the right beacon and the relay's drop (o8 also shows the old bay lamp's flicker noise).

**Every change against round 7** (`state-diff-720.json`, `state-diff-phone.json`), in world px:
- the liner, x 713-798, y 276-310, and x 713-721, y 313-429;
- both beacons;
- the luminaire, x 617-680, y 173-206;
- the relay's drop and spray, x 642-658, y 359-449;
- the leaf, in s4 and s4b;
- the crank pose, in s3;
- WOLF's position, in s5-s7.

Phone shape shows the same regions. The only exception is s2's roller foot, a 211-px timing difference: the seal had just started to rise.

**Budgets** (`perf-table.md`; render.sh, 1280x720), main -> round 6 -> round 7 -> round 8:

| Measure | Result |
|---|---|
| Draw calls, s1 | 72 -> 54 -> 47 -> **47** (limit 54) |
| Draw calls, s3 while cranking | 73 -> 55 -> (not measured) -> **48** |
| Draw calls, other states | 46-54 |
| Additive items | 8 -> 7 -> 7 -> **7** |
| Texture memory | 71.97 -> 73.87 -> 74.38 -> **74.70 MB**: +0.83 MB against round 6 (limit 2 MB); the new crank atlas 410x380 with mips and the beacon atlas 256x160 |
| Full-screen translucent world layers | 2 (Haze 0.62, MidPlate) |
| Overdraw estimate | 3.37-3.46 |
| Headless CPU p50 | 0.19-0.23 ms in round 8 (main 0.20-0.24 ms) |

## Inherited, listed and not changed

1. **The safe point looks reachable round the door.** The safe point's room floor carries on right of the near column on the camera side, with a step edge from the bulkhead corner, so a player may ask why not walk round the door. Both reviews raised it. The fix is art in the near strip (a low wall, a railing, or the column carried down): it is not trivial, so it is not done.
2. **SECTOR 4B is set level**, while the face's lines drop about 4 px across it at 720p (round 6's typeset text).
3. **Colour counts:** three yellows when open and three reds when shut (Nathanial's choices; REAL-LOOK asks for one of each).
4. **Budgets against REAL-LOOK:** the overdraw estimate (about 3.4) and the resident textures (74.7 MB) are above REAL-LOOK's 2.0 and 45 MB targets.
5. **COOLANT FAULT** stays up after the relay is dealt with (another job's branch clears it).
6. **Other rooms' beacons:** the Records and junction beacons still use the code-drawn housing.
7. **Flicker noise:** the corridor lamps' first flicker runs before the driver reseeds the RNG, which is why run-to-run noise is left out of the opening diff.

## For Nathanial (choices, not defects)

- **The crank pose:**
  - It now matches today's provisional sprite. When the approved walk-final frames land, it must be cut again from those.
  - The hood's back point shows as a small red tip behind the head in B at 3x.
- **WOLF waiting in the corridor** during the safe-point beat (above).
- **The beacons:** the lens stays at its real size, so the lockdown read relies on the pool and the pulse; the pulse was not judged in stills.
- **The RESTRICTED AREA plate** (unchanged): printed letters, not bridged stencil; over the door, not beside it; black only.
- **The luminaire** moved and got shorter (above).
- **The discharge** now vents at the floor by the relay, not at head height near the engineer.

## Files (round 8)

- **Game copy `game-add/apps/game/`:**
  - Scripts: `main.gd` (crank constants, push length, WOLF's wait), `blast_leaf.gd` (0.36 m leaf, contact shadow, new light table), `bypass_handle.gd` (outlet), `fx_presets.gd` (spray).
  - Scene: `main.tscn` (beacon regions).
  - Tests: `m0_scene_test.gd` (both gloves, race wait, WOLF safe-point check), `corridor_additions_test.gd` (leaf thickness, shadow).
  - Assets: `corridor-seal-atlas.png`, `corridor-beacons.png`, `eng-crank-atlas.png`, `corridor-coolant-relay.png`, `rooms/corridor-far.png`, and `manifest.json`. The register now holds a `corridor-seal-atlas` entry (from main's, with the scratch additions) and updated entries for the far plate, relay, beacons and crank atlas.
- **Work `add7/fix1/`:**
  - `door/`: `portal8.py`, `base8.py`, `codex_inputs8.py`, `cleanup8.py`, `install8.py` (`fix1/door/tools/install8.py` at ada83fa), `design/`, `layers/`, `game/`.
  - `crank/`: `rig.py`, `codex_inputs.py`, `cleanup.py`, `pack.py`, `rig/`, `frames/`, `deliver/`.
  - `beacons/`: copied design and cleanup with the R8 changes, plus `layers/`.
  - `plume/`: `design8.py`, `codex_inputs8.py`, `cleanup8.py`, `design/`, `layer/`.
  - `luminaire/`: `design.py`, `cleanup.py`, `design/`, `layer/`.
  - `codex/`: five job folders with prompt, refs, out (C2PA kept), `run.log` and `session.txt`; `run_job.sh`; `archive.log`.
  - `tools/`: capture, tests, headless perf, `opening_diff8`, `state_diff8`, `perf_table8`, `package8`, `crop`, `side` (all `fix1/tools/` at ada83fa; round 11's `fix4/tools/` holds the current copies, and round 9's `fix2/tools/crop.py` and `side.py` are byte for byte round 8's).
  - `driver/` (`fix1/driver/realslice_capture.gd` at ada83fa; round 9's identical copy `fix2/driver/realslice_capture.gd` is at ada83fa too).
  - `work/`, including `r7-installed/` with round 7's replaced files.
- **Outputs `add7/shots/`:**
  - New and regenerated: `ADD.md` (this section), `sheet.png`, `pairs/`, `crops/`, `opening-diff/` and `opening-diff.json`, `state-diff-*.json`, `perf.json`, `perf-table.md`, `add-code.diff`, `fix1-code.diff`.
  - Raw captures and logs: `raw8/` and `logs8/`.
  - Kept as round 7's record: `raw7/`, `logs/`, `REVIEW-*-r1.md`.
- **Provenance:** `add7/provenance.txt`, "FIX ROUND 1" section.
  - Five sessions, all archived. Outputs are byte-identical to their originals, each with its C2PA chunk.
  - One session (crank try 1) was not used.

---

*The section below is round 7's record. Its numbers refer to `raw7/`. The pairs, crops, sheet, opening diff, state diffs, perf table and `add-code.diff` it names were regenerated for round 8 above.*

# Round 7: Nathanial's additions, all four tracks in one game copy

Scratch only, 2026-10-13. No Git repository or worktree was edited. The additions are installed in `real-slice/game-add` (a copy of round 6's `game-slice`). Nothing that already existed under `real-slice/` was changed: `game-slice`, `game-main`, `shots/`, `design/`, `layers/`, `codex/` and the top-level `provenance.txt` have no file newer than the start of this job. The only file touched outside `add7/integrate` and `add7/shots` is `add7/provenance.txt`, which has a new section at the end.

**How this was checked:**
- **Headless logic:** 14 of 14 suites pass after two imports: round 6's 13 suites plus the new `corridor_additions_test` (`logs/tests-add/`).
- **Rendered stills:** all made with `tools/render/render.sh` (Godot 4.7.2 in the Colima container, software GL); no window opened on the Mac. Main, round 6 and the additions were all re-captured this round with the same driver, so every pair is like for like.
- **Not done:** nothing was played by hand, so this note makes **no feel claims**. No phone, device or export test was run. No review pass has run, and Nathanial has not seen it.

## What to open

- `sheet.png` holds:
  - every state at 1280x720 as main | round 6 | additions;
  - s1, s4b and s5 in phone shape;
  - the 3x crops of each addition;
  - the opening frames o5, o7 and o8, each with its diff.
- `pairs/<state>-720.png` and `pairs/<state>-phone.png` are three-way pairs with the HUD hidden. Phone is 2400x1080: the 1920x1080 game image between pillar bars. Single phone frames are in `pairs/phone/<copy>-<state>.png`.
- `crops/*-3x.png` are one crop per addition, main | round 6 | additions.
- `opening-diff/oN-*.png` draws the diff over **main's** frame. Pink marks pixels that differ outside the beacon zones; cyan outlines the beacon zones; yellow marks world x 540.

## What a first-time player sees now

- **Door end, shut (s1).** The roller door sits in a steel blast frame: armour plates over the hood with a row of anchor bolts, and a strip down the far jamb. A white steel plate over the door reads RESTRICTED AREA in black stencil, typeset from the game's own Roboto. SECTOR 4B and DOOR 4B-07 stay. The seal lamp is red.
- **Opening (s4, s4b).** The roller rises. Behind it is a second, darker and much thicker door with a yellow-and-black striped leading edge.
  - At about 40 % open the inner door slides back along the wall into a pocket on the far side.
  - The plant room appears behind its edge as it goes (`crops/c-inner-leaf-s4b-3x.png`).
- **Open (s5-s7).** The inner door is home in its pocket, with only its striped edge showing in the pocket's mouth, and a floor rail crosses the threshold. Nothing blocks the walkway.
- **Beacons.** The two flat red chips with pink rims are now caged red lamps on wall brackets:
  - the left lamp is fed by conduit from the ceiling tray;
  - the right lamp hangs under its back box;
  - each glow is a red pool on the wall (`crops/d-beacon-*-3x.png`).
- **Cranking (s3).** The pale glowing disc is gone.
  - A relief valve stands on the relay's side pipe, and a faint, narrow jet falls from its tailpipe (`crops/g-relief-jet-s3-3x.png`).
  - The engineer grips the wheel's rim with the near glove, the far glove braced on the gearbox housing above it.
  - The push frame (B) and the regrip frame (A) alternate with each tick (`crops/f-crank-*-3x.png`, `pairs/s3-crank-{B,A}-720.png`).
- **Strap.** A second saddle strap holds the vertical lamp conduit at 3.45 m. It is 1-2 px at 1x.

## Measured

### Every change is one of the additions

`state-diff-720.json` and `state-diff-phone.json` compare round 6 with the additions in each state; their blobs are listed in world px. Every blob over 3 levels is one of these:
- the two beacons (about 15,000 px each at 720p);
- the sign (x 730-790, y 223-255);
- the head plates (x 714-797, y 276-309);
- the far-jamb plates (x 714-721, y 314-429);
- the relief valve (x 633-652, y 349-363);
- the strap (x 803-809, y 308-313);
- the column piece's changed pixels (the near head plate, its bolt and the strap) at s2's subpixel-shifted camera (x 790-799, y 324-330, 21 px at 720p);
- the floor rail, uncovered as the roller lifts off it (s2, 88 px);
- the leaf in s4 and s4b;
- the parked edge and rail in s5-s7;
- the crank pose with its floor reflection, and the jet, in s3.

Phone shape shows the same regions.

### Rule 5: the opening (`opening-diff.json`, `tools: integrate/tools/opening_diff7.py` at ada83fa)

**Method.** The additions' `raw7/add/O-720` is compared with three references:
- each of main's three render.sh runs (`shots/raw5/main/O-720`, `-repeat`, `-r3`);
- round 6 (`shots/raw6/slice/O-720`).

**Noise.** Same-copy run-to-run noise is left out. It comes from the old bay lamp's flicker phase: each room's RNG is randomised in `_ready`, and its first flicker runs before the driver reseeds it. The noise is taken from main's three runs, round 6's two and the additions' two (`O-720`, `O-720-r2`).

**Beacon zones.** Each zone covers what main draws there and what the additions draw there: x -45..45 and y -55..45 world px from the anchor, plus 3 px. A beacon counts only where main has a red lens within 9 world px and the pixels changed, so main's other reds (the terminal screen, the cage lights) are not counted as beacons.

**Results:**

| Frame | Beacons found | Main's lens inside the zone | Beacon-zone px vs main | Outside the zones, left of x 540, vs main | vs round 6 | Right of x 540, vs round 6 |
|---|---|---|---|---|---|---|
| o0 | 1 | yes | 26,314 | 1,594 px in 14 dust blobs, 0 not dust | **0 px** | off screen |
| o1 | 1 | yes | 26,773 | 1,691 px, 16 blobs, 0 not dust | **0** | off screen |
| o2 | 1 | yes | 24,488 | 1,998 px, 12 blobs, 0 not dust | **0** | off screen |
| o3 | 1 | yes | 24,755 | 2,372 px, 12 blobs, 0 not dust | **0** | off screen |
| o4 | 1 | yes | 24,795 | 2,237 px, 9 blobs, 0 not dust | **0** | **0** |
| o5 | 1 | yes | 24,290 | 2,197 px, 7 blobs, 0 not dust | **0** | **0** |
| o6 | 1 | yes | 25,160 | 2,287 px, 10 blobs, 0 not dust | **0** | **0** |
| o7 | 2 | yes | 10,651 | 1,389 px, 16 blobs, 0 not dust | **0** | 19,270 (door end and right beacon) |
| o8 | 2 | yes | 16,583 | 1,406 px, 19 blobs, 0 not dust | **0** | 19,105 (door end and right beacon) |

All nine frames pass against all three main runs and against round 6. Outside the two beacons, everything left of world x 540 (WOLF's cage and the whole opening) is pixel-identical to round 6. Against main the only differences there are main's ambient dust, and none is brighter in the additions.

**A note on o5 and o8.** Before the additions' second opening run was in the noise reference, o5 and o8 showed 2-4-level changes in the corridor ceiling lamps' glow, away from both beacons. The additions' own two runs differ in exactly those pixels (o5: 5,900 px, max 2; o8: 11,632 px, max 4), so this is the lamp-flicker run-to-run noise and not a change.

### New headless checks (`game-add/apps/game/tests/`)

- **`corridor_additions_test.gd` (new suite):**
  - **Beacons:** both corridor beacons and their glows stand at main's anchors, (327.36, 224.3) and (632.64, 224.3), read headless from main 76d3a50.
    - Each lens is still red.
    - Each red globe overlaps main's 14x9 housing, its centre 5.3 px from the anchor.
    - Each light is one additive region of the same atlas.
    - The other rooms keep their drawn beacons.
  - **Shut:** the inner leaf spans the whole opening, its lead at -2.19 m, inside the near jamb at -2.09 m.
  - **Opening:** it holds until 40 % open, then moves only toward its pocket.
  - **Open:** its leading edge is flush at the pocket's mouth (1.4635 m), so the opening is clear. Its whole footprint lies behind the walk line (its lowest foot point is at world y 429.6, against the walk line at 440; the check requires under 432).
  - **Batching:** it draws right before the roller from the same atlas.
- **`m0_scene_test.gd` (in play):**
  - **While the seal opens:** the inner leaf keeps the roller's own open value in every frame (31-32 frames sampled), and the doorway stays blocked while any of the leaf is in the opening. Once it lands, the leaf is hidden and in its pocket.
  - **While cranking (USE held to 4 ticks):** every frame shows the crank pose. One run had 60 A and 37 B frames, and 0 frames of the usual sprite.
  - **Hand on the rim:** the glove is found in the crank art through the sprite's own transform. In every frame it is at most **0.87 world px** off the wheel's rim line and 0.87 px from its grip point. The check fails above 1.5 px off the rim or 2.5 px from the grip point.
- **Negative checks** (on a throwaway copy, `integrate/negtest/`):
  - Moving the crank sprite 4 px fails the check: 3.03 px off the rim (`neg-sprite-shift.log`).
  - Asking for the wrong grip points fails it too: 3.02 px from the grip point.

### Budgets (`perf-table.md`, `perf.json`; render.sh, 1280x720, 300 frames held per state)

| State | Draw calls p50 (max): main -> round 6 -> additions | Additive items | Texture MB | Full-screen translucent world layers |
|---|---|---|---|---|
| s1 at rest | 72 (72) -> 54 (54) -> **47 (47)** | 8 -> 7 -> **7** | 71.97 -> 73.87 -> **74.38** | 2 -> 2 -> 2 |
| s2 relay beat | 77 -> 60 -> **54** | 8 -> 7 -> 7 | 76.66 -> 73.87 -> 74.38 | 2 |
| s3 cranking | 75 (80) -> 58 (63) -> **51 (57)** | 9 -> 7 -> 7 | 76.66 -> 73.87 -> 74.38 | 2 |
| s4 roller half up (leaf visible) | 73 -> 56 -> **50** | 8 -> 7 -> 7 | 76.66 -> 73.87 -> 74.38 | 2 |
| s4b leaf sliding | 73 -> 56 -> **50** | 8 -> 7 -> 7 | 76.66 -> 73.87 -> 74.38 | 2 |
| s5 open | 71 -> 54 -> **47** | 8 -> 7 -> 7 | 76.66 -> 73.87 -> 74.38 | 2 |
| s6 walking through | 71 -> 54 -> **47** | 8 -> 7 -> 7 | 76.66 -> 73.87 -> 74.38 | 2 |
| s7 safe point | 71 (75) -> 54 (58) -> **46 (50)** | 8 -> 7 -> 7 | 76.66 -> 73.87 -> 74.38 | 2 |

- **Draw calls:** every state has fewer than round 6, 6-8 fewer.
  - The beacons now draw from one atlas, so both beacons batch.
  - The sliding leaf batches with the roller: s4 and s4b hold 50, with the leaf on screen.
  - Round 6's s4b (56) and main's (73) come from this round's runs, since only this driver captures s4b. This round's round-6 run reproduces round 6's own s1, s2 and s4-s7 numbers exactly.
- **Additive items:** 7, the same as round 6. The beacon glows replace main's radial glows one for one, and the plume is normal-blend.
- **Texture memory:** +0.51 MB against round 6 (+0.036 MB for the beacon atlas, about +0.47 MB for the crank atlas with mipmaps). The seal atlas stays 1024x1024. That is inside the 2 MB limit.
- **Full-screen translucent world layers:** 2 (the haze at 0.62 and the mid plate), unchanged. The only canvas-layer quad is Grade.
- **Overdraw estimate:** 3.36-3.46, down from 3.42-3.54.
- **Nodes:** 434 against 433 (the BlastLeaf).
- **Frame times** inside the container are not a measurement and are left out.
- **CPU, `godot --headless`:** p50 frame time 0.22-0.48 ms in all three copies. The p99 values (0.4-3.9 ms) are noise from other render jobs on the machine (`perf-table.md`).

## How it was installed (smallest code changes; full diff `add-code.diff`, 976 lines)

1. **Plume:**
   - `git apply add7/plume/patch/plume.patch` (clean): `bypass_handle.gd`, `fx_presets.gd`, `manifest.json` and the relay PNG;
   - the jet comes from `FxPresets.relief_jet()` at `RELIEF_OUTLET` (649.6, 361).
2. **Beacons:**
   - `beacons-code.diff` changes `room_depth.gd` and `main.tscn` (ext_resource `23_beacons`, no id collision);
   - `corridor-beacons.png` and its `.import` are added (lossless, no mipmaps);
   - a manifest entry is added (rights: pending Nathanial's review).
3. **Crank:**
   - `crank-code.diff` changes `main.gd` and `floor_reflection.gd`;
   - `assets/characters/eng-crank-atlas.png` and its `.import` are added (lossless, mipmaps);
   - a manifest entry is added.
4. **Door:**
   - the door track's `corridor-seal-atlas.png` replaces the old atlas (same size and import; every existing region is unchanged);
   - `scripts/blast_leaf.gd` is added;
   - `main.gd` gets `var blast_leaf`, `BlastLeaf.new(CORRIDOR_SEAL_ATLAS)` in the door body before `seal_leaf`, `blast_leaf.open/visible` in `_sync_door`, and the tween now runs `tween_method(_set_seal_open, 0, 1, CORRIDOR_DOOR_OPEN_SECONDS)` with the same quad in-out easing, plus `tween_callback(blast_leaf.hide)`;
   - there is no new timing and no collision change.
5. **Tests:**
   - `tests/corridor_additions_test.gd` is new;
   - `tests/m0_scene_test.gd` has the in-play leaf and crank checks.

The installed art is byte-identical to each track's delivered file: atlas 9b1719de..., beacons afd3bb20..., crank 8ca19231..., relay 9fbcf045... (md5; `add7/provenance.txt`).

## Provenance

- **No new Codex session** in this integration; every image comes from a track's delivered file.
- **Re-checked this round:**
  - all eight add7 Codex originals carry their `caBX` C2PA chunk (21,881 or 23,654 bytes);
  - all eight sessions are archived, with 0 live: crank 1a, 1b, 2a, 2b and 2c (2c delivered), beacons, plume and door7. The ids are listed in `add7/provenance.txt`.
- **Text:** RESTRICTED AREA, SECTOR 4B and DOOR 4B-07 are typeset by script in the bundled Roboto (OFL). The image tool painted no lettering.
- **Asset register:** `manifest.json` now has entries for `corridor-beacons` and `eng-crank-atlas`, and the coolant relay's entry describes the valve. The seal atlas itself is still unregistered, as in round 6, and must be registered before a real PR.

## Open, for review and for Nathanial

1. **The crank pose is a different drawing.** The crank frames come from the approved walk-final engineer: strict profile, lighter grey trousers, rim-lit hair. The rest of the game still draws the provisional 3/4 sprite, so the engineer changes style while cranking and back on release; at 3x the switch is obvious (`crops/f-crank-*`). The crank track recommends landing this with, or after, the approved idle, walk and jog frames.
2. **The far glove.** It rests flat on the gearbox housing above the wheel. At 6x it reads as a hand on the machine; at 1x a first-time player might read it as a raised hand. A reviewer should judge it at phone size.
3. **The inner leaf's front face is very dark** (about luma 18-30, under the actors by design). Its striped edge carries the read, and the face reads as a dark slab. The leaf slides 3.65 m in about 0.6 s, inside the existing 1 s opening, which is the same game-time compression as the roller.
4. **Two yellows when open:** the parked edge's stripes and the roller's bottom bar and floor line, all toned to about luma 39.
5. **Three reds when shut:** the two beacons and the seal lamp, as Nathanial chose. The beacons are now smaller and quieter (a globe about 10 px tall at 720p).
6. **The sign hangs over the door, not beside it,** because the wall beside the door is a 17 px foreshortened column. Real Army signs add red lettering; this sign is black only.
7. **The jet is faint.** The valve is about 29x19 px at 720p and reads as a pipe fitting; the jet was judged only in still frames.
8. **The opening's lamp flicker** is still randomised at `_ready`, before any reseed. That is how main and round 6 behave too, and it is why run-to-run noise has to be left out of the opening diff.
9. **The Records and junction beacons** still use the drawn housing (outside this round).
10. **Not done:** a review pass, Nathanial's look, play by hand, phone and export tests, Notion and the Codex board.

## Files (all under `real-slice/`)

- **Game copy `game-add/apps/game/`:**
  - changed: `scripts/main.gd`, `room_depth.gd`, `bypass_handle.gd`, `fx_presets.gd`, `floor_reflection.gd`, `scenes/main.tscn`, `assets/manifest.json`, `assets/props/corridor-seal-atlas.png`, `corridor-coolant-relay.png` and `tests/m0_scene_test.gd`;
  - new: `scripts/blast_leaf.gd`, `assets/props/corridor-beacons.png(.import)`, `assets/characters/eng-crank-atlas.png(.import)` and `tests/corridor_additions_test.gd`.
- **Integration tools `add7/integrate/`:**
  - `tools/tests.sh`, `render_run.sh`, `capture_all.sh` and `headless_perf.sh` (adapted copies of `fix6/tools`; `integrate/tools/` at ada83fa);
  - `tools/opening_diff7.py`, `state_diff7.py`, `perf_table7.py` and `package7.py` (`integrate/tools/` at ada83fa; round 11's `fix4/tools/` holds the current copies);
  - `driver/realslice_capture.gd` (`integrate/driver/realslice_capture.gd` at ada83fa), a copy of `fix3/driver` that adds s4b and the crank strip;
  - `patches/` (the beacon and crank diffs with relative paths);
  - `probe/` (the main beacon probe, and private main and round-6 copies for headless timing);
  - `negtest/` (the negative crank checks);
  - `work/`, `manifest.before.json` and the battery logs.
- **Outputs `add7/shots/`:**
  - `ADD.md`, `sheet.png`, `pairs/` (20 pairs plus `phone/`) and `crops/` (13);
  - `opening-diff/` and `opening-diff.json`;
  - `state-diff-720.json` and `state-diff-phone.json`;
  - `perf.json`, `perf-table.md` and `add-code.diff`;
  - `raw7/{main,r6,add}/` (O-720 and O-720-r2 for the additions only, then A and B at 720 and phone, perf runs and headless runs);
  - `logs/`.
- **Provenance:** `add7/provenance.txt`, integration section.
