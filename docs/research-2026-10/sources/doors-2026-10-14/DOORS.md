# Doors fix round 4 (doors-r1/fix-r4): the review r4 fixes

Scratch only. The Git repository was not touched.

**Base:** `origin/main` at **0c5d1ae** (PR #67, the approved wording). The doors from rounds 1-3 were rebased onto it in the scratch repo (`game-doors`, commit 1642c5b). Five conflicts were resolved:
- `junction_test`: main's approved wording with the doors' node names.
- `main.gd` `_interact`: main's sealed-door refusal plus round 3's open-exit fix.
- `_hatch_opened`: main's `_tell` and `_update_controls`.
- `human.controlled`: `lane_question_held` plus `records_exit_walking`.
- `junction_room`: main's flicker constants with the painted alcove. Main's flicker is ported to the door's status lamp and the exit door's lens.

Round 4 is commits 1974aa3 and 9c219a1.

**The fixed game** is `doors-r1/game-doors/apps/game`.
- `doors-integration.patch` (52 files) applies cleanly to a fresh `git archive origin/main apps/game scripts` at 0c5d1ae. The result matches the copy file for file.
- `doors-fix-r4-over-r3.patch` (9 files) is this round alone, cut against round 3 rebased on 0c5d1ae.

**Evidence:**
- **Headless suites:** 19 of 19 pass on the final copy (`checks/round-4/suites-final.txt`). Main now has 19 suites, adding approved_wording_test.
- **Stills:** render.sh at 1280x720 and 2400x1080, made by the same driver on main 0c5d1ae and on the fixed copy.
- **Measurements:** every review r4 item is measured on those stills with a check that fails round 3.

**Nothing was played by hand, so there are no feel claims.** That includes the blast leaf's flight, which the human reviewer asked to have checked hands-on.

Everything below this section describes round 3 and earlier. Where they disagree with this section, this section is current.

## Real-look review (r4)

| Item | Fix | Measured |
|---|---|---|
| **M1, cause 1:** the swing leaves drew the wrong face for part of each swing | `SwingLeaf.room_face_shows(theta)` now tests the real view ray to the face's centre: `n_room.dot(centre - camera) < 0`, with camera = (vpx / 40, 0, -38) m. The test is no longer `n_room.z < 0`. The closer's arm uses the same choice. | **Room face shown:** to about 31-34 degrees (it was 17-18 before). Checked headless at every 2 degrees against the ray test in `room_depth_test`. |
| **M1, cause 2:** the door-light exposure starved the fill | **Separate fill exposure.** `SwingLeaf.fill` scales the ambient and every light marked as fill, independent of the key lights. Per door: `EXIT_LEAF_FILL` 0.0370, Records `ENTRY_LEAF_FILL` 0.0509, junction `ENTRY_LEAF_FILL` 0.0880.<br>**The door light** is back at the design's reach of 1.4 m and down 2.0, as a true Lambert source.<br>**Two more lights**, taken from the surfaces round each door:<br>- the lit threshold and passage deck seen through the doorway;<br>- the cross-wall's lit face beyond the hinge jamb, which the room face turns toward as the leaf opens.<br>**A dip at about 10 degrees remained.** The room face turns out of the door light before the jamb face reaches it. It was lifted to the shut leaf's level: the Records exit's jamb-face light ×1.25; the Records entry's and the junction entry's ceiling lamp ×1.3 (`dipfix.py`). The gains were fitted with `leafsim / lp3 / l1 / refine / dipfix.py` and checked on render.sh frames with `swingcheck.py`. | **r10, the junction entry leaf closing** (x 50-68, y 380-470, against the wall at x 95-135): round 3 **0.0020 linear (0.16x the wall)** → **0.0105 (0.86x)** (`r10-leaf.txt`).<br>**New swing frames, 10 / 20 / 30 / 50 % open, time frozen** (`swing.md`):<br>- leaf / wall: Records entry 0.84 / 1.04 / 1.44 / 2.29; Records exit 1.09 / 1.40 / 1.76 / 1.77; junction entry 0.96 / 1.27 / 1.76 / 2.55;<br>- leaf / shut leaf: 1.05 or more in every frame.<br>**Software model, every 2 degrees, minimum leaf / shut:** 1.01 / 1.03 / 1.05 (`swing-every-2deg.txt`).<br>**Open leaf by the hinge / reveal**, rows 350-380 / 400-440 / 460-490 (target 0.6-1.0):<br>- Records entry 0.54 / 0.29 / 0.11 → **0.83 / 0.86 / 0.79**<br>- Records exit 0.68 / 0.43 / 0.26 → **0.68 / 0.74 / 0.85**<br>- junction entry 0.81 / 0.44 / 0.26 → **0.71 / 0.68 / 0.86**<br>Round 3's figures are the reviewer's. |
| **S1:** the steam at the junction entry ended in a ruler-straight line | `steamlap.py` laps the mid plate's own steam onto the cross-wall's face within 7 world px of its back corner:<br>- its density comes from the dark-channel prior, mirrored about the corner;<br>- it is drawn in the cloud's own colour and fades to nothing.<br>One atlas changed: `junction-entry-atlas.png`, 549x638, SHA-256 93e12a6b…. | **Mean luminance step across the corner column** (`steam.md`): r09 / r10 / r11 at x 222, **37.4 / 37.0 / 36.8 → 14.6 / 14.3 / 14.1**; j01 at x 158, **25.9 → 10.6**.<br>Rows carrying a step over 12 at x 222: 152 of 210 → 115. The cloud now feathers onto the wall face (`steam-r3-vs-r4-3x.png`). |
| **S2:** a doors-added sentry_test check flaked under load | **The test fix:** `sentry_test` waits up to 30 frames for WOLF's turn (`flip_h`), because main sets his facing in its per-frame update, and the check had read it after one physics frame.<br>**Correction to round 3's DOORS.md:** it said the load flake was main's alone. That was wrong. The reviewer's failure was in this doors-added doorway check. | **`sentry-load.txt`:** 3 rounds of 2 doors-copy and 2 main runs at once, beside 6 busy CPU loops. **Doors 6/6, main 6/6.** |
| **S3:** the register's status listed deleted images and missed three atlases | `manifest.json` top-level `status` now lists **five door-end atlases** (corridor seal, Records, junction blast door, junction entry, junction exit). The pressure-bulkhead images and their art-source originals are gone from it. The swing doors' leaves are listed as procedural meshes. The junction entry atlas's entry has a round-4 note with its size and SHA-256. | All 5 atlases on disk are registered. Every apps/game path in the register exists. |
| **Could** | **Done:** the thrown leaf's in-flight pose (see the human review).<br>**Not done:** the exit wedge's orange streaks; the exit wall pack's hard shadow; the dash scuffs and granite-like kick plates; roller scuffs; the column blotches; smooth hairline cracks; darker blast puffs. | — |

**One side effect, for the next reviewer.** The fill now reaches shut leaves too. Shut, they read **0.78x (Records entry), 1.05x (Records exit) and 0.88x (junction entry)** their walls (`shutleaf.txt`). In round 3 they read 0.54 / 0.47 / 0.58. So the Records exit's shut leaf now sits 5 % above its concrete. That breaks round 2's "leaf at or below the wall" rule by that much. It is the price of M1's "never below the shut value".

**One limit.** Through the game's own `SwingLeaf` (`leaf-angles-game-code.txt`), the middle of the face stays at 0.96-1.00x its shut value at every degree. But the point by the hinge at the head dips to 0.48-0.70x its shut value at about 11 degrees. At that point the door light grazes the shut leaf and lights it brightly, and that lit spot is lost as the leaf turns. At the dip the point still reads 0.0117-0.0135 linear, at or above the wall beside it.

## Human review (r4)

| Item | Fix | Measured |
|---|---|---|
| **should-fix: the blast leaf seemed to teleport** | **The leaf is thrown, not swapped.** After the 0.15 s break, the torn leaf flies **0.24 s** (`DOOR_FLIGHT_SECONDS`) from the doorway to where it lies:<br>- it is carried along the lane and slowed, rising 18 px and falling;<br>- it tips toward flat (1.5 rad) and grows 1.22x as it comes nearer the camera;<br>- it draws in front of the near column once 30 % along;<br>- it lands in a low dust burst off the wet deck (`landing_dust`).<br>This follows SDI 133 / ASTM F2927 Category IV: the leaf separates from its frame and becomes debris.<br>**New check:** `door_route_test` requires the leaf to be seen in the air past the near jamb with the lying leaf hidden, and drawn whole in every frame. | `j03-flight-20 / 45 / 70 / 90` and `j03-landed` (`flight-sequence.png`). The driver poses the flight with time frozen, because software frames are slow; that pose is a driver-only debug path.<br>**Needs one hands-on check** to see whether it now reads as thrown in motion. |
| **should-fix: text** ("secure the first copy", "hatch") | **Drafts only**, below. | — |
| **fine / small:** the floor beyond the Records exit column is a plain grey plane | **Not done.** Listed here. | — |

## Inherited, listed and not changed

- **j10-j14:** the mint sentry beam line runs through the fallen tank and the crushed sentry.
- **j04 / j05:** the sentry's yellow beam band floats across the alcove; on phone j04, about x 1410-1600.
- **j13 / j14:** a half-faded DOOR DOWN label ghosts at the left edge.
- **r08, j04-j07:** the dialogue box covers both walk-outs and much of the thrown leaf, now including part of its flight.

## Route, station, camera, timing and text changes this round

- **No x position, station, camera position, text, choice or save changed.**
- **Engineer x in j12 / j13:** **848.2 / 848.2**, so the round 3 ending fix holds. Round 3's run read 849.2; this run's driver timing differs by 1 px, and both are past `HATCH_REACH_MIN_X` 846.
- **One visual timing change:** after the blast, the lying leaf appears **0.24 s later**, after its flight. No beat, box or input timing moved.
- **One test change follows from it:** junction_test now waits up to 45 frames (it was 30) for the empty doorway and the lying leaf.

## Measurements

**Budget** (`perf-table.md`, `perf.json`; render.sh 1280x720, main 0c5d1ae → round 4):
- **Draw calls:** Records 45-53 against 47-53; junction 83-96 against 94-105.
- **Additive items:** 8-9 against 9-10.
- **Largest change over main in any state:** draw calls +0, additive +0, texture memory **+1.88 MB**, the same as round 3. The atlas grew 2.3 KB on disk, the same size in memory.
- The landing dust is one CPUParticles2D that emits only on landing, and it is not additive.
- **No new full-screen layer, draw call or live light.**

**Atlases:** `fringe.txt`, 0 violet px in all five door atlases.

**Tests:**
- **Final:** 19/19 pass (`suites-final.txt`).
- **Under load:** in one earlier run, with two render.sh containers and another job's renders running beside 4 suites at once, `crank_hold_test` failed once ("a single press makes all three valve turns", a 120-physics-frame bound; `suites-under-render-load.txt`). Run alone it passed 3/3 on the doors copy and 3/3 on main (`crank-hold-rerun.txt`). The test file and the valve code are the same as main.

## Process

- **No Codex session this round.** Every change is code, or deterministic image work with NumPy, SciPy and Pillow. `provenance.txt` has the round-4 entry.
- **`fix-r4/rebuild.sh`** reproduces the one changed asset. A re-run left the game copy byte-identical.
- **Capture driver:** it now reads optional flags through `_flag()`, so it runs on main, which has no flight. Main's run notes "flight not caught", as expected.
- **Register:** `manifest.json`, see S3.
- **Track notes:** `records/`, `junction/`, `hatch/NOTES.md` and `fix-r3/jentry/NOTES.md` have round-4 sections.
- **Tools** are in `fix-r4-tools/`: the tools, driver, rebuild, render and suite scripts, gains and constants.

## Drafts for Nathanial (not shipped)

- **Container hint:** "E: secure the first copy in the container." (today: "E: secure the first copy.")
- **"hatch" → "door"** in about ten exit lines. Draft for the hint: "E: leave through the door."
- **Nathanial's calls:**
  - whether the DOOR DOWN plate moves up off the doorway;
  - the blast door's turn, 17 or 30-35 degrees.

## Not done

- **Hands-on play:** the flight, the ending and the leaves' light are checked only headless and in stills.
- The changelog export check, exports and device tests.
- The "could" items and the Records exit's plain floor beyond the column (above).
- **Outside apps/game:**
  - delete repo-root `scripts/prepare_bulkheads.py`;
  - update the lighter-game docs;
  - file the design records under `docs/research-2026-10/sources/`.

# Doors fix round 3 (doors-r1/fix-r3): the review r3 fixes

Scratch only. The Git repository was not touched.

**Base:** `origin/main` at **8cb4301**. Main moved past cec75f6 (PR #66, which redraws the junction only when its inputs change). The door work was rebased onto it in the scratch repo (`game-doors`, branch `r3-8cb`). Three conflicts were resolved:
- `junction_room.gd` `sync_bolt`: main's redraw check plus the exit lamp;
- `draw_recesses`: main's input snapshot, with no alcove shadow because the bay is painted;
- `records_room.gd`: main's `set_active` plus the doors' `refresh_state` note.

Main's new junction_test check, "Records' sparks stop emitting once it is hidden", reads `exit_sparks`, which went with the exit pod. It now checks that those sparks are gone and that any particles Records holds stop once it is hidden. Records holds none now, so the second half has nothing to check.

**The fixed game** is `doors-r1/game-doors/apps/game`. `doors-integration.patch` (52 files) applies cleanly to a fresh `git archive origin/main apps/game` at 8cb4301, and the result matches that copy file for file. `doors-fix-r3-over-r2.patch` (14 files) is this round alone. It is cut on cec75f6 so that it compares like with like against round 2.

**Evidence:**
- 18 of 18 headless suites pass on the final copy (`checks/round-3/suites-final.txt`).
- render.sh stills at 1280x720 and 2400x1080, made by the same driver on main 8cb4301 and on the fixed copy.
- Every review r3 item is measured on those stills with a check that fails round 2.

**Nothing was played by hand, so there are no feel claims.**

Everything below this section describes fix round 2 and earlier. Where they disagree with this section, this section is current.

## Real-look review (r3)

| Item | Fix | Measured (render.sh 1280x720) |
|---|---|---|
| **R3-1** a violet fringe round the shut exit leaf | `hatch/tools/cleanup.py leaf()`, done as `wall()` already did it:<br>- no pixel within 6 design px of the silhouette is kept;<br>- near the silhouette, no magenta-cast pixel counts as paint;<br>- every one of them takes the nearest kept pixel's colour.<br>**New check:** `fringecheck.py` fails any door atlas holding a pixel with alpha > 0, b−g > 20 and r−g > 8. It runs in `rebuild.sh` on all four atlases. | Atlas: round 2's exit atlas **858 → 0**. All four atlases pass.<br>On screen, in j08, j09 and j10 (x 1040-1200, y 280-520): **84 / 84 / 24 → 0 / 0 / 0**. |
| **R3-2** open swing leaves read as black cards beside the lit reveal | **The door light over each head is now a true Lambert source** (no wrap) of 0.5 m reach. It lights an open leaf the way it lights the far-jamb reveal the leaf hangs on, since both face the same way, and only grazes a shut leaf. `SwingLeaf` takes an optional fifth light entry for the wrap.<br>- **Fitted** with `leaffit.py` and closed on the render.<br>- **Exposures:** Records exit 0.082, Records entry 0.225, junction entry 0.147.<br>- **The faces get designed wear** where use and water put it (`leafwear.py`): hand grime round the lever, primer rubbed through on the latch stile, a grime band and heel marks low down, level cart scrapes at 0.35-0.95 m, and dirt in the edges.<br>- **The paint's own grain is lifted** at 1 and 2 face px. The junction entry's leaf draws smaller, so its grain is lifted more (`JENTRY_GRAIN`; it read 0.089 before this).<br>- **Mipmaps are kept.** The atlases draw at 0.5x, so without mipmaps they would shimmer.<br>**New check:** `leafcheck.py`. | **Leaf head by the hinge / reveal** (target 0.7-1.0):<br>- Records entry 0.30 → **0.74**<br>- Records exit 0.15 → **0.71**<br>- junction entry 0.14 → **0.72**<br>**Free edge low / wall:** **0.43 / 0.23 / 0.89**. Where the door light does not reach, the leaf stays below the concrete.<br>**Relative texture** (target ≥ 0.12): **0.129 / 0.252 / 0.139**.<br>**Shut leaves / wall** (`shutleaf.py`): **0.54 / 0.47 / 0.58**. |
| **R3-3** junction entry: a bare lamp lens, a white smear and a pasted pipe | Round 2's straight header and service-line run over the cross-wall's face is removed, with its escutcheons. The face under it takes its own concrete from the same rows.<br>The mid plate keeps the room's own elbow, riser and service-line end (`jemid.py RESTORE_ELBOW`, as on main). So the header turns up into its riser at the corner, and the far plate's ceiling lamp stays hidden behind the elbow. | **Near-white px at the header** (r09 x 150-300, y 90-230): round 2 **315 → 30**, the same as main (30).<br>The same holds in r10, r11 and j04. In j01: 297 → **65** (main 65). |
| **S1** pale plank threshold | Set to the deck's value as it reads beside it on screen. Its 12 mm nose is a dull edge (`jgrade2.py`).<br>**New check:** `threshcheck.py`. | **Plate / deck:** j01 2.99 → **0.99**, j02 2.58 → **0.93** (target 1 ± 0.15). |
| **S2** collars read as round black knobs | Drawn from the model. Each of the room's four pipes is a cylinder from the wall's back corner into the face, valued from the room's own pipes. Each passes through a 50 mm steel escutcheon ring 10 mm proud of the face.<br>The old band, the square collar and the paint's halo round them are refilled with the face's concrete. | The rings project to upright ellipses about **0.48x** as wide as tall at this wall's real 17-degree turn. That is wider than the reviewer's estimate of about 0.3x.<br>In stills they read as pipes entering the wall (j08, j13, phone j08). |
| **S3** the thrown leaf reads as a clean slab | `lying3.py`, built from jdesign's own leaf geometry, moves painted pixels by their exact height change, so nothing is repainted:<br>- **dished 0.16 m:** it rests on its middle and on the chunk under its right end, its left end stands 0.17 m off the deck, and the silhouette sags about 7 world px against its chord;<br>- **the landing corner is crushed** in a ragged 0.10-0.14 m chamfer;<br>- **scrapes** run along its slide;<br>- **soot** sits by the latch edge. | j04-blown and j05-j07: the leaf lies bowed in the alcove, clear of the wall. |
| **S4** blast damage invisible at 1x | Fresh fracture faces and torn bare steel are graded lighter than the weathered face, and the soot stays dark (`jgrade2.py`).<br>**New check:** `damagecheck.py`. | **j04, ratio to the weathered face:**<br>- spall faces 2.47<br>- arrises 2.36<br>- column spall 1.37<br>- torn hinge leaves 1.49<br>- keeper pockets 1.11<br>- soot 0.61<br>j06 is similar. |
| **S5** provenance missed one output | `provenance.txt` now lists `codex/r2-junction-exit/out/attempt-1/r2-junction-exit-leaf-painted.png` (sha256 d72dd17e…, verified; session 01a136e0; unused). **Fix round 2 made 11 outputs in 7 sessions, not 10.** | — |
| Could: roller scuffs on the exit leaf; the blast column's white blotches; jagged hairline cracks | **Not done.** | — |

## Human review (r3)

| Item | Fix | Measured |
|---|---|---|
| **MUST: at the open exit, USE sent the engineer back to the bolt panel** | **Cause (verified):** in the junction, USE first ran `_step_beside_station`. The EXIT BOLT panel's reach runs to x 849, past `HATCH_REACH_MIN_X` (846), so leaving from the nearest spot stepped the engineer to the panel's working side (`BOLT_X` 747).<br>**Fix:** `main.gd` skips that sidestep once the bolt is open and the engineer is at or past `HATCH_REACH_MIN_X` (`_at_open_exit`).<br>**New check:** `door_route_test` leaves from x 846.5 and requires the engineer to hold that x through the closing beat, both live and in the save. It **fails without the fix** (lowest x 831.8, saved x 746.6) and passes with it. | Engineer x in j12 / j13: round 2 **849.2 / 746.6**; round 3 **849.2 / 849.2**. |
| Junction entry header: white slivers, a flat pipe cut | As R3-3. | As R3-3. |
| Junction exit: a flat grey floor wedge under WOLF | The floor between the wall's foot and the walk line is now the room's own wet deck. It is the mid plate's deck moved 1.5 m along the room and 4.8 m nearer the camera, in the room's camera, so its seams and sheen run on. It sits in the wall's contact shadow and is kept out of the wall's row gains, which had flattened it. | j08-j13: wet deck with the room's reflections. |
| Light battens read as white dashes at the screen edges | The diffuser was clipped white because the detail lift drove it to 255. It is now a frosted cool strip (0.28 linear, about sRGB 145), and the detail lift leaves the fitting out. The housing, clips and end caps show in their own spill. | **Near-white px** (min channel > 200) at the screen-edge battens in r01, r03, r04 and r07: **5 / 5 / 40 / 40 → 0 / 0 / 0 / 0**. |
| The thrown leaf reads as a plate; its corner lies across the wall's foot | As S3. It also lies **0.4 m (16 world px) further along the lane**, clear of the wall's stub. The dialogue box still covers much of it (inherited). | j04-blown-clean: its left end clears the stub. |
| Fine: a violet edge; disc-like collars; the open Records exit leaf a near-black slab | As R3-1, S2 and R3-2. | — |
| Text: nothing ties "secure the first copy" to the container | **Draft only**, below. | — |

## Inherited, listed and not changed

- **j10-j14:** the mint sentry beam line runs through the fallen tank and the crushed sentry.
- **r08, j14:** the dialogue box covers both walk-outs and most of the thrown leaf.
- **j13/j14:** a half-faded DOOR DOWN label ghosts at the left edge (x 20-140, y 262).
- **Phone j04:** the sentry's beam band floats across the alcove.
- **Exit lines:** "hatch" is still in the shipped text; the replacement is a draft.

## Route, station, camera, timing and text changes this round

- **None of x positions, stations, the camera, timings or text changed.**
- **One behaviour fix:** USE at the open exit no longer steps the engineer to the bolt panel's side (above).
- **One test change on top of main:** the junction_test Records-particles check (see Base).

## Measurements

**Light at the corners** (`measure4.py`; `checks/round-3/light-final.md`). The walls are as in round 2: 0.54-0.81x the back wall at most rows, and 0.77 at the Records exit's top rows. The two outliers are the same as round 2: 1.19 in the junction entry's near-black top rows, and 1.03 in the exit lamp's spill. The reviewer's junction-exit boxes read 0.41 / 0.72 / 0.77 / 0.63.

The "leaf / wall ≤ 1" rule from review r2 (N3) still holds for the **shut** leaves:
- blast door 0.72;
- junction exit 0.67;
- shut swing leaves 0.47-0.58.

**The open swing leaves now read 1.5-4.2x the wall's median**, because R3-2 asks them to take the door light as the lit reveal beside them does. The reveal reads 11x the wall's median at the junction entry. This is the intended outcome of R3-2, and the next reviewer should judge it against the reveal, not the wall.

**Budget** (`perf.json`, `checks/round-3/perf-table.md`, Records and junction states):
- **Draw calls** are at or below main in every state: Records 45-53 against 47-53, junction 83-96 against 94-105.
- **Additive items** are at or below main.
- **Texture memory** is **+1.88 MB** over main (round 2: +3.30 MB). The junction door atlas is now skyline-packed, 1024x928 → 1024x656. The junction exit state is **−2.80 MB**.
- **No new full-screen layer, draw call or live light.**

**Tests** (`checks/round-3/suites-final.txt`): 18 of 18 pass, run 4 at a time with isolated HOMEs.

**sentry_test under load** (`checks/round-3/sentry-load.txt`, `fix-r3-tools/tools/sentry-load.sh`): 3 rounds of 2 doors-copy and 2 main runs at once, beside 6 busy CPU loops.
- Doors copy: 6/6 pass.
- **Main 8cb4301: 5/6.** One run failed "WOLF bounds over the sentry … never walks through it", the same check that failed twice on the doors copy in this round's earlier suite runs while render.sh ran beside them.
- So this is a timing flake in main's test under heavy load, not a door change.
- **Correction:** an earlier stress script in this round (`checks/sentry-stress`) called `timeout`, which macOS lacks. Its 12 "passes" never ran Godot, so it is not evidence.

## Process

- **No Codex session this round.** Every change is design-driven and deterministic (NumPy, SciPy, Pillow) on round 2's cleaned paint, or drawn from the model.
- **`fix-r3/rebuild.sh`** reproduces every asset. A full re-run changes only the file it should (byte-identical elsewhere).
- **The asset register** (`manifest.json`) has round-3 notes on the seven changed assets: records-doors-atlas, records-far, junction-door-atlas, junction-entry-atlas, junction-exit-atlas, junction-mid and junction-far, each with size and SHA-256 (`manifest_r3.py`).
- **Track notes:** `records/`, `junction/` and `hatch/NOTES.md` and `fix-r3/jentry/NOTES.md` have round-3 sections.
- **Tools** are in `fix-r3-tools/`.

## Drafts for Nathanial (not shipped)

- **The container hint**, tying the copy to the container. Draft: "E: secure the first copy in the container." (today: "E: secure the first copy.")
- **"hatch" → "door"** in the exit lines. The exit is a sliding door, but about ten shipped lines still call it "the hatch": the hint, "The hatch is open.", "The hatch slides open.", "The hatch is opening.", the two tank-hit lines and three status lines. Draft for the hint: "E: leave through the door."
- **Unchanged from earlier rounds:** stencils, slide speed, the records_arc sound, the CONTINUE chirp, the changelog line.
- **Nathanial's calls:**
  - whether the DOOR DOWN plate moves up off the doorway (a UI change);
  - the blast door's turn, 17 or 30-35 degrees.

## Not done

- **Hands-on play.** The ending (the engineer now holds at the door through the closing beat), the leaves' new light and every look change are checked only headless and in stills.
- The changelog export check, exports and device tests.
- The "could" items above, and round 2's darker blast puffs.
- **Outside apps/game:**
  - delete repo-root `scripts/prepare_bulkheads.py`;
  - update the lighter-game docs;
  - file the design records under `docs/research-2026-10/sources/`.


# Doors fix round 2 (doors-r1/fix-r2): the review r2 fixes

Scratch only. The Git repository was not touched.

**Base:** `origin/main` at **cec75f6**. Main moved past 4bb15b0 (PR #65). The door work was rebased onto it, and `junction_test.gd`'s one conflict was resolved: main's fuse frames with the door's node names.

**The fixed game** is `doors-r1/game-doors/apps/game` (a scratch git repo; branch `r2`). `doors-integration.patch` (52 files) applies cleanly to a fresh `git archive origin/main apps/game`, and the result is file-identical to that copy. `doors-fix-r2-over-r1.patch` (15 files) is this round alone.

**Evidence:** 18 headless suites (main's new `crank_hold_test` included), all passing, and render.sh stills at 1280x720 and 2400x1080. The same driver ran on main cec75f6 and on the fixed copy. **Nothing was played by hand, so there are no feel claims.**

Everything below this section describes fix round 1 and round 1. Where they disagree with this section, this section is current.

## Real-look review (r2)

| Item | Fix | Where |
|---|---|---|
| **N1** a painted copy of the shut door in the open doorways | **The Records ends and the junction entry were re-painted open, with no leaf in the doorway** (sessions r2-records-exit, r2-records-entry, r2-junction-entry). The space behind each doorway now takes paint detail **only where that painting showed it**: hidden pixels mirror-fill from the same part (`detail_map(vis=)`, `beyond_visible`). The leaf faces are painted flat on their own sheet.<br>**New check:** `ghostcheck.py` fails a layer whose high-pass edges line up with the shut leaf's edges inside the opening.<br>- Round 1: 0.37, 0.37 and 0.25, all **FAIL**.<br>- Round 2: −0.02, −0.03 and −0.09, all **pass**.<br>**New captures:** the driver takes each open doorway with its leaf hidden (`r01-noleaf`, `r07-noleaf`, `r09-noleaf`, `j08-noleaf`, `j11-noleaf`, `j01-noleaf`). Each shows only the designed passage. `SwingLeaf` now draws nothing while hidden. | `fix-r2/records/tools/{paint_inputs,cleanup}.py`, `fix-r2/jentry/tools/{jeinputs,jeclean}.py`, `fix-r2/tools/ghostcheck.py`, `checks/round-2/ghostcheck.json` |
| **N2** the junction's machinery through the entry doorway and under the wall's foot | `jemid.py` rebuilds `junction-mid.png`. It erases **208,725 px**, against round 1's 546: everything under the wall, its doorway and the floor triangle between the wall's foot and the walk line.<br>- **The floor triangle** is re-laid as deck (5,570 px), taken from the plate's own deck 5 m nearer the camera along the lines to (511, 162).<br>- **The header and the service line** run on into the wall through steel escutcheons in sleeves. Their lengths over the face are the room's own header pixels, from a plain run of it (no clamp, no steam).<br>- **The guard rail** ends on a post (its own right end, mirrored).<br>- **Re-captured:** r09-r11 and j01-j03. | `fix-r2/jentry/tools/{jemid,jedesign,jeinstall}.py` |
| **N3** one light logic | **`grade2.py`**: measured as the reviewer measures, in linear light, with the back wall just room-side of each corner against the wall's own columns at the corner. One gain per row, at **0.60x** the back wall (never below 0.5x of its lower rows). Pools keep part of their light; lenses keep their value. **Closed on the render:** `feedback.py` measures each render.sh pass and corrects per row, bounded 0.5-2.5; four passes (a1-a4).<br>**The leaves**, in the same pass, at or below the concrete:<br>- the swing leaves get a runtime exposure (`RecordsRoom.EXIT_LEAF_EXPOSURE` 0.17, `ENTRY_LEAF_EXPOSURE` 0.25, `JunctionRoom.ENTRY_LEAF_EXPOSURE` 0.33);<br>- the blast and exit leaves are graded in their atlases;<br>- the Records leaves' floor bounce matches the design (0.30).<br>**The junction exit's face, which sees the corner fitting, is lit with it.** Its detail is lifted at 1.2 world px, which survives the atlas (the paint's own grain; no noise). Measurements below. | `fix-r2/tools/{grade2,rgrade2,feedback,measure4}.py`, `junction/tools/jgrade2.py`, `hatch/tools/cleanup.py grade_room`, `swing_leaf.gd exposure` |
| **N4** the blast damage hidden under the DOOR DOWN plate | **The readable damage is now between 0.3 and 2.0 m**:<br>- **the near column** (its own atlas region, `COLBLOWN`; the same DoorColumn sprite switches to it once blown, so no new draw call): the three full-surface hinges torn, with sheared pins and the middle frame leaf bent out; the hinge-jamb corner spalled 60-80 mm down to its 25 mm bars and ties, one tie bent out; 2-4 mm cracks; the 50 mm arris angle torn off its anchors and bowed 120 mm; soot;<br>- **the latch face plate** torn off above 1.0 m and bent 0.25 m into the opening, its torn edge bare, with two sheared keeper lugs;<br>- **the lane behind the doorway** in the wall's shade, so the opening is no longer a pale lit slot.<br>**Measured in j04:** the plate (world y 320-335) covers **8.6 %** of the damage piece's rectangle and **4.7 %** of the column's, and none of the 0.3-2.0 m band (world y about 360-428). The plate's position and text are unchanged; moving it is Nathanial's call. | `junction/tools/jdesign.py column_damage_parts, damage_parts`, `install.py`, `junction_room.gd _sync_door`, `checks/round-2/blast-damage-vs-plate.json` |
| **S1** Records open leaves featureless | The faces keep the paint's scuffs and grime at their real size. Their even white flecks are calmed (3x3 median blend). The room face's lever, rose and thumbturn are lifted to worn steel, so the hardware reads at 2 px or more. The closer arm takes the leaf's own shade. | `rgrade2.py`, `swing_leaf.gd` |
| **S2** penetration plates with no pipe | Removed, with their leach streaks (`PIPE_RUNS = ()`). | `records/tools/rdesign.py` |
| **S3** the blast door reads as a personnel door | Three **full-surface hinges** (UFGS 08 39 54 2.2.1): frame leaves on the hinge jamb's flange, door leaves on the leaf, five 60 mm knuckles on one pin. The bolts throw into keepers at the head, sill and jambs (2.2.2.1). The 17 vs 30-35 degree turn is still Nathanial's call. | `jdesign.py hinge_frame_parts, leaf_parts` |
| **S4** pale plank threshold | At the deck's value, with a dull steel edge. | `jdesign.py` |
| **S5** even speckle on the blast column | Median blend (keeps 25 % of the fine difference); its detail is lifted half as much as the wall's. | `jgrade2.py` |
| **S6** container the brightest thing | Linear grade: it falls to 0.45 at its base, and its median is 0.95x the exit wall at the same rows. | `rgrade2.py` |
| **S7** the exit's unlit wall pack | A **forward-throw** wall pack: its front glass is lit, and its pool falls on the leaf, the threshold and the deck. | `hatch/tools/{geom,design}.py` |
| Could: the closer arm's colour | It takes the leaf's own shade at the head. | `swing_leaf.gd` |
| Could: darker blast puffs | Not done. | |

## Human review (r2)

| Item | Fix |
|---|---|
| **MUST j11-j13: WOLF sliced by the exit jamb, his rear in the wall** | `WOLF_DOORWAY_X` 985 → **934**. He waits on the threshold in front of the open door, his whole body on the room side of the near column; nothing cuts him in the held frame (j13). To leave room for the engineer behind him: `HATCH_REACH_MIN_X` 870 → **846**, and the **EXIT BOLT panel** `BOLT_PANEL_X` 806 → **796** (its riser moves with it in the exit's back layer). |
| **MUST j04/j05: WOLF inside the valve** | Past the blast, wherever his body would stand over the valve, he steps out onto the deck **12 px (about 1.3 m) in front of it**, his feet and reflection lower, and draws over it and the engineer there (`JunctionRoom.wolf_valve_step`). His x and `WOLF_RUBBLE_X` (448) are unchanged; he eases back over 60 px. The actors keep one scale (sentry_test's tank crossing checks it). |
| Blown doorway reads as a slot with gravel | As N4. |
| The thrown leaf reads as a pallet | The hinges' door leaves stay on it (16 mm plates with the door's knuckles). It keeps the wall's gain (face up under the ceiling fittings). The dialogue box still covers most of it (inherited). |
| Smooth empty slabs at every door end | **Every cast face now carries:**<br>- form-panel joints (1.2 x 2.4 m) and grouted 25 mm tie cones 0.6 m on centre (ACI 347);<br>- the damp band, seepage and scuffs;<br>- the light of its fittings (N3);<br>- the paint's own grain lifted.<br>**Pipes through the walls:** the exit wall carries the room's four back-wall pipes through collars at its corner, and the junction entry carries the header and service line. |
| Flat placeholder leaves, floating closer arm | As S1 and N3. The arm is dark steel in the leaf's light. |
| Clean flat container | As S6. Tying it to the copy needs a line or a label, which is new text (drafted below). |
| j08/j09 exit hard to spot | The exit wall is lit by the corner fitting (0.41-0.71x the back wall beside it, from 0.011-0.075x). The wall pack's glass is lit, and the leaf sits at 0.69x the wall. "hatch" in the text is still a draft. |
| Stray white light-tube dashes | Each is now a **real 1.2 m vapour-tight batten**: a grey body, clips and end caps, a lens that dims with the space it lights, and a soft pool on the wall round it. This covers the two Records passages, the junction entry passage and the blast door's light. |
| Ending: WOLF never seen stepping through | **A bug:** the junction's tick does not run during the chapter close, so WOLF walked out at full follow speed (through the doorway in about 0.15 s). He now walks at the walk-out speed, as round 1 intended, so the stills show him going through (j14-walk-out-00 to 03). That made **a second bug** visible: **the floor collider ended at x 960**, so past the doorway WOLF dropped off its end, behind the deck. In Records the drop was 88 px; after the junction exit it ran to over 1,700 px. Both happened out of view at round 1's speed. The floor now runs to x 1200 (`main.tscn`), and `door_route_test` checks both walk-outs stay on it. The new checks fail without the fix (87.8 and 1,755 px) and pass with it. |
| Ending: the engineer behind the jamb, not into the light | The engineer walks into the doorway against the lit passage (the passage fitting is now twice as bright) before the near column takes them (j14-walk-out-10 to 12). |

## Inherited, listed and not changed

- **j10-j14:** the sentry's beam line through the fallen tank and the crushed sentry.
- **r08, j14:** the dialogue box covers the bottom quarter during both walk-outs, and most of the thrown leaf.
- **j13/j14:** a half-faded DOOR DOWN label ghosts at the left edge.
- **Phone j04:** the sentry's beam band floats across the alcove.

## Route, station, camera and timing changes (each forced by a door; text, beats, choices and saves unchanged)

| Change | From → to | Why |
|---|---|---|
| `JunctionRoom.WOLF_DOORWAY_X` (WOLF's wait at the open exit) | 985 → **934** | The human pass: WOLF was sliced by the near jamb |
| `JunctionRoom.HATCH_REACH_MIN_X` | 870 → **846** | Room for the engineer behind WOLF |
| `JunctionRoom.BOLT_PANEL_X` (the EXIT BOLT station) and its riser | 806 → **796** | The same; `BOLT_X` follows (−10 px) |
| WOLF's drawn position over the valve after the blast | +12 px down, nearer the camera | The human pass: WOLF inside the valve |
| WOLF's walk-out speed through the exit | full follow speed → `HATCH_EXIT_SPEED_SCALE` (0.55), as the engineer's | Bug fix toward round 1's stated intent. The walk-out now lasts about 0.9 s longer before the engineer follows. |
| The floor collider | x 0-960 → **x 0-1200** | Bug fix: actors walking out dropped off its end |
| Exit atlas regions, entry atlas regions, the junction door layout (generated) | Updated | New art |

The camera and every line of text are unchanged.

## Measurements (render.sh 1280x720, the same driver on main cec75f6 and on round 2)

**Walls at the corner** (linear luminance; `measure4.py`, `checks/round-2/light-final.md`):

| Door end | Rows (world y) | Back wall | Cross-wall | Ratio |
|---|---|---|---|---|
| Records exit | 190-250 / 330-372 | 0.0061 / 0.0121 | 0.0039 / 0.0075 | **0.64 / 0.62** |
| Records entry | 190-250 / 330-372 | 0.0104 / 0.0139 | 0.0066 / 0.0081 | **0.63 / 0.58** |
| Junction entry | 250-320 | 0.0078 | 0.0045 | **0.58** |
| Blast door | 160-230 / 250-320 | 0.0060 / 0.0105 | 0.0041 / 0.0085 | **0.69 / 0.81** |
| Junction exit | 225-280 | 0.4389 | 0.2803 | **0.64** |

**The reviewer's own junction-exit boxes** (j08, screen: back wall x 940-985 against the cross-wall x 995-1040):

| Screen rows | 100-140 | 180-220 | 260-300 | 340-380 |
|---|---|---|---|---|
| Ratio, round 2 | **0.41** | **0.71** | **0.67** | **0.62** |
| Ratio, fix round 1 | 0.011 | 0.016 | 0.062 | 0.075 |

**Leaves against the wall beside them** (target at or below 1):

| Records entry | Records exit | Junction entry | Blast door | Junction exit |
|---|---|---|---|---|
| **0.95** | **0.77** | **0.81** | **0.72** | **0.69** |

Fix round 1 had the junction entry leaf at 4.2x and the Records leaves at 2.9x.

**Texture.** Against the approved corridor wall (relative texture, std/median, 0.22), the cast faces read 0.30-1.05. The exceptions:
- the junction exit wall near the lamp (0.09-0.14), where the light dominates;
- the junction entry's top rows (0.17), which are near-black ceiling shadow; there both the wall (0.0014) and the room's machinery (0.0012) are near black, so the ratio there (1.19) says little.

The raw texture ratio against the back walls stays under 0.5 at most ends, because those back boxes take in lit pipework. Above the lamp at the junction exit (rows 180-215) the face reads 1.01x: it is that lamp's spill on the face, beside the dark ceiling.

**Budget** (`perf.json`, `checks/round-2/perf-table.md`):
- **Draw calls** are equal to fix round 1 and at or below main in every state, for example junction 94-105 → 83-95 and Records 47-49 → 45-49.
- **Additive items** are at or below main (junction 10 → 9 and 9 → 8).
- **Texture memory:** +3.30 MB over main until the exit opens (fix round 1: +3.02 MB), and −1.38 MB after. That is inside the ~4 MB budget.
- **What grew:** the junction door atlas 1024x888 → 1024x928 (the blown column); the exit atlas 986 → 1006 wide; the entry atlas 549 → 551 wide.
- **No new full-screen layer, draw call or live light.**

## Process

- **Pipeline:** design first (masks and parts from the game's measurements), then Codex paints material and light only, then a deterministic cleanup re-imposes masks and palette, then `grade2` with render feedback, then install. The whole chain is reproducible with `fix-r2/rebuild.sh`.
- **Codex: 7 sessions, 10 outputs.**
  - r2-records-exit, r2-records-entry, r2-records-parts, r2-junction-entry, r2-junction-sealed, r2-junction-blown, r2-junction-exit.
  - Each output keeps its C2PA content credentials (caBX) and is byte-identical to its original in `~/.codex/generated_images/`.
  - All seven sessions are archived. Their rollouts call only the built-in `image_gen__imagegen`: no image API and no image_gen.py.
  - Recorded in `doors-r1/provenance.txt`.
- **The asset register** (`manifest.json`) records round 2 for the seven changed assets (sessions, method, size, SHA-256).
- **Corrected notes:**
  - `records/NOTES.md` now names the ghost door, and the pipe-less plates' streaks;
  - `fix-r1/jentry/NOTES.md` and `fix-r2/jentry/NOTES.md` correct the "junction-mid cleared" claim and the passage claim;
  - `junction/NOTES.md` and `hatch/NOTES.md` have round-2 sections on top.

## Drafts for Nathanial (not shipped)

Unchanged from fix round 1:
- the container hint (tying it to the copy);
- "hatch" → "door" in the three exit lines;
- stencils, slide speed, the records_arc sound, the CONTINUE chirp, the changelog line.

New this round:
- Should the DOOR DOWN plate move up off the doorway? The damage no longer needs it, so this is a UI call.
- The blast door's turn: 17 or 30-35 degrees.

## Not done

- Hands-on play. The longer WOLF walk-out (about 0.9 s), WOLF's step in front of the valve, and the junction entry's look are checked only headless and in stills.
- The changelog export check, exports and device tests.
- Outside apps/game:
  - delete repo-root `scripts/prepare_bulkheads.py`;
  - update the lighter-game docs;
  - file the design records under `docs/research-2026-10/sources/`: the four tracks, `fix-r1/jentry` and the fix-r2 tools.

---

# Doors fix round 1 (doors-r1/fix-r1): the review r1 fixes

Scratch only. The Git repository was not touched. Base: `origin/main` at **4bb15b0**. The fixed game is `doors-r1/game-doors/apps/game` (a scratch git repo; fix-round commits on top of round 1). Nothing was played by hand, so there are no feel claims. The evidence is 17 headless suites and render.sh stills (1280x720 and 2400x1080, the same driver on main and on the fixed copy).

Everything below this section describes round 1 (the integration). Where this section disagrees with it, this section is current.

## What changed, item by item

**Must fix**

| Item | Fix | Where |
|---|---|---|
| **M1** walls brighter than their rooms | Each door end was repainted with wear designed into the drawing:<br>- a damp band at the foot;<br>- seepage under the pour joints;<br>- leach streaks only under the pipe penetrations;<br>- a scuffed kick zone at the doors.<br>The prompt asked for the room's own grit. The cleanup keeps more of the paint's grain. A new grade (`fix-r1/tools/grade.py`) then sets the concrete, **row by row, to 0.70x the room's back wall at the same height**. Exceptions:<br>- the exit wall is set to 0.62x;<br>- the bay is set to 0.75x;<br>- passages are set to 0.95x;<br>- the target never falls below 0.55x of the room's lower-wall median, so the high walls do not turn black;<br>- light pools under fittings keep part of their light;<br>- the paint's own fine grain is lifted (an unsharp mask; no noise is added). | `junction/tools/jgrade.py`, `tools/rgrade.py`, `hatch/tools/cleanup.py grade_room` |
| **M2** pristine thrown leaf, partly inside the wall | The leaf was re-modelled:<br>- it lies approach face up, with its hinge edge toward the camera;<br>- three torn knuckles with sheared pins and their hinge leaves;<br>- bowed 0.09 m and dished 0.04 m;<br>- its far edge and right end rest on jamb chunks (about 6.5 and 3.5 degrees);<br>- three bent locking bolts stick out of the latch edge;<br>- it was thrown straight out from the wall, at least 14 world px clear of the stub;<br>- its far edge stays below the actors' feet line (y 440).<br>Repainted as a scraped, dented, bent steel slab with exposed fill. | `junction/tools/jdesign.py lying_parts` |
| **M3** blown doorway not reading | The damage was redrawn so it reads at play zoom:<br>- a spall bite deepest at the latch jamb and over the head, 0.85 m along the face so it survives the 17-degree foreshortening;<br>- 25 mm bars drawn 1 world px wide, four bar ends bent out and two hanging from the head;<br>- cracks from both head corners (Liu et al.);<br>- the 300 mm latch face plate torn out 0.45 m;<br>- the head sagging 0.11 m;<br>- a sooted, buckled liner with ripped keeper pockets.<br>Also a larger rubble heap (0.45 m) with chunks of 0.3-0.5 m, and a hard-chip and dust jet at the blast. | `jdesign.py hole_parts, damage_parts, rubble_*` |
| **M4** mirrored deck past x 960 | The mirrored `exit_deck` is gone. A **deck** atlas piece takes its place: the mid plate translated 2.0 m along the room in its own camera, so its seams run to (511, 162), over x 956 to 1032. The exit wall's stub now covers the rest. | `hatch/tools/hinstall.py`, `junction_room.gd EXIT_DECK` |
| **M5** camera-facing entry hatch at x 80 | **Replaced by a door end**: a 300 mm cross-wall turned 17 degrees, with a 3'0" x 7'0" steel door at x 30, in the junction's camera.<br>- It stands open behind the arriving pair and its closer shuts it (0.35 s + 3.4 s, amber then red).<br>- The service line passage is painted behind it.<br>- `junction-hatch.png`, its import and its lamp drawing are deleted.<br>- The left near pipe column is no longer drawn. | new `fix-r1/jentry/` (`jedesign.py`, `jeclean.py`, `jeinstall.py`, NOTES.md), `junction_room.gd ENTRY_*` |

**Should fix and consider**

| Item | Fix |
|---|---|
| **S1** WOLF's head in the column at the rubble | At WOLF_RUBBLE_X (448, unchanged) he now faces back toward where the engineer comes from. His head is out in the room (in front of the valve) and his tail is behind the near column. `j05` is now captured with the engineer *in* the doorway (x 478), between the far jamb and the column. |
| **S2** valve outlet hanging in mid-air | The painted 0.36 m outlet carries on through:<br>- a mating flange;<br>- a 350 x 150 reducer, a spool and a long-radius elbow;<br>- a 1 m run behind the valve's base;<br>- an elbow up into the riser, now drawn as a real 150 mm cylinder;<br>- a turn into the wall through a collar on the penetration plate. |
| **S3** hard shadow wedge at the exit head | The ceiling batten is sampled 13 x 3 and the wall pack 9 x 2, so the shadows are soft smudges. |
| **S4** no stub at the exit | The wall now ends in a column 0.16 m past the near jamb (its 0.66 m end with arris angles) and is cut to a 0.15 m stub across the deck, with the passage beyond it in the cutaway. |
| **S5** Records closer and hinges | Added:<br>- a 310 x 65 mm surface closer on the leaf's room face by the hinge;<br>- its regular arm, drawn live (`SwingLeaf.arm_joints`, two thin quads in the same draw call) to a shoe on the head;<br>- hinge knuckles at 26 mm (about 2 px);<br>- an 85 mm floor stop.<br>The junction entry has the same closer. |
| **S6** mirrored Records walls | The walls now differ:<br>- exit pour joint at 3.6 m, entry at 4.2 m;<br>- the camera only on the exit;<br>- the junction box on the latch side over the exit and the hinge side over the entry;<br>- painted separately, with their own stains. |
| **S7** blob effects | New presets (`FxPresets.streaks`, `chips`, `dust_jet`):<br>- the blast's sparks are 2 x 8 px hard streaks aligned to their flight, white-hot to orange, with gravity;<br>- its debris are hard tumbling 3 px chips;<br>- its dust is a jet through the doorway that slows and spreads;<br>- the exit bolt's sparks are streaks (22, was 30).<br>The particle counts are the same or lower. |
| **S8** clay-box container | Added a 130 x 100 mm lock housing, a 120 mm dial ring and an index mark. It was repainted as grey enamel and set in the room's light, darker toward its base. |
| **S9** walls on the raised deck | The blast wall's stub ends in its cut section, carried down the deck's fascia with steel trim angles. The exit's equivalent runs off-screen to the right. |
| **C1** two vanishing points | The exit door was rebuilt in (511, 162). `exit_leaf_anchor` and the tests follow. |
| **C2** narrow frame, threshold | A 300 mm latch face plate, and a 0.75 m threshold plate with a bright nosing. The 30-35 degree turn is still Nathanial's call. |
| **C3** half lamp at the Records entry | Not reproduced at the stated place. The entry wall is redrawn and darker, and no cut lamp shows in r01-r03 (see the crops). |
| **C4** notes claiming unseen detail | The art now shows the knuckles, bow, rebar and soot. Each track's NOTES.md has a "Fix round 1" section on top that corrects its round-1 claims. |

**The human pass**

| Item | Fix |
|---|---|
| Records right third: blank pale wall, floating EXIT | The wall is dark grimy concrete with pipe penetration plates. The EXIT caption is now the legend of a real exit-sign housing that stands square off the wall over the door (painted with a blank face; the text is the game's caption). |
| WOLF overlapping at the rubble (j04, j05) | As S1. |
| Clip-art container | As S8. A label would be new text (drafted below). |
| WOLF left behind when Records cuts (r08, r09) | The engineer now walks on out of view (to x 1000) and WOLF follows them through the doorway. The junction starts once his whole body is past the column (x 980, the cut at 976 or more), or after 3 s at most. |
| Records exit small, open leaf a dark slab | The leaf's faces take only the square root of the wall's darkening. The open leaf shows its kick plate, lever and closer arm. Its size is the real 3'0" door's. |
| Records entry: drywall look, bright white line | The wall is repainted and graded. The stub's edge angle is dull steel. |
| SEALED DOOR reads as a pillar | The dark wall, the 300 mm frame plate, the threshold plate and the stub's cut down the fascia now carry the wall across the walkway. The turn angle is left to Nathanial. |
| Blown doorway: a pale panel with square holes | As M3. |
| Thrown leaf reads as a floor plate, chips for rubble | As M2, with the larger rubble. |
| Engineer hidden in j05 | The frame is now caught in the doorway (x 478). |
| "hatch" not on screen in j08, j09 | The junction view always runs to x 1030, so the exit door is in view before the bolt. The word "hatch" is a text decision (drafts below). |
| Mint disc sparks (j10) | As S7. |
| Clean pale exit wall | As M1. |
| Closing camera presses the exit to the edge | The closing shot is now zoom 1.62 over x 438..1030, with the floor about 70 % down the view. The column and the passage beyond show right of the doorway. |

## Inherited, listed and not changed

- **j08-j14:** the sentry's beam line still runs through the fallen tank and the crushed sentry.
- **r08, j14:** the dialogue box still covers the bottom quarter during both walk-outs.
- **r09:** the junction no longer opens beside a camera-facing round vault hatch. This is fixed under M5 above.

## Route, station and camera changes (each one forced by a door; text, beats, choices and saves unchanged)

**Junction entry (new)**
- The collision face is at `JunctionRoom.ENTRY_DOOR_X` 30. The engineer stops at x 44.
- Restored saves are clamped to engineer x 44 or more and WOLF x 61 or more.
- WOLF's follow minimum in the junction is 97.
- WOLF_CLEAR_X (100) is unchanged; his tail (x 33) clears the door.

**Records walk-out**
- `RECORDS_WALK_OUT_X` goes from 918 to 1000. `RECORDS_WOLF_OUT_X` goes from 830 to 980.
- The actors' maximum x during the walk-out is 1040.
- The junction starts when WOLF reaches x 976, or after 3 s at most.
- The walk-out now takes about 1.5-2 s (round 1: about 0.45 s).

**Junction camera and exit geometry**
- The play view's right edge in the junction is now 1030 at all times. Round 1 used 960, and 1000 once the bolt was open.
- The closing camera goes from (670.3, 352) at zoom 1.45 to (733.7, 373) at zoom 1.62.
- `EXIT_NEAR_JAMB_X` goes from 971.6 to 971.3 (the junction's camera). `HUMAN_GONE_X` and `WOLF_GONE_X` move with it.

**Unchanged:** every other station and route x.

## Checks

- **Headless, final build:** 17 / 17 suites pass (`checks/fix-r1-suites.txt`).
  - Import is clean.
  - `press_sound`: 29 presses, 29 heard within one frame.
- **`door_route_test`, new checks:**
  - WOLF follows through the Records exit before the junction starts.
  - The junction entry stands open on arrival and closes on its hinges, drawn whole every frame.
  - Both actors arrive past the entry.
- **New checks in the other suites:** `room_depth_test` checks the junction entry's geometry and the exit leaf in the new camera. `junction_test` checks that no near column stands over either junction end.
- **Earlier flake:** in one parallel run `studio_logo_test` failed a timing check. It passed alone and in the final run. It does not touch the doors.
- **Patch:** `doors-integration.patch` (the whole change against main, `git diff --binary`, 51 files) applies cleanly to a fresh `git archive 4bb15b0 apps/game`. `doors-fix-r1-over-round1.patch` is this round alone.
- **Asset register:**
  - 62 entries, and every asset PNG is registered;
  - `junction-hatch` is replaced by `junction-entry-atlas`;
  - the three changed atlases and junction-far, junction-mid and records-far are updated;
  - nothing in the register points at a missing file.

## Numbers (render.sh 1280x720, the same driver on main and on the fixed copy, p50 of 60 frames)

| State | Draw calls main → after | Additive main → after | Texture MB main → after |
|---|---|---|---|
| Records arrival | 49 → 49 | 9 → 9 | 73.12 → 76.14 |
| Records copy point | 47 → 45 | 9 → 9 | 73.12 → 76.14 |
| Records exit open | 47 → 45 | 9 → 9 | 73.12 → 76.14 |
| Junction, entry shut | 96 → 88 | 10 → 9 | 73.37 → 76.39 |
| Junction sealed | 94 → 86 | 10 → 9 | 73.37 → 76.39 |
| Junction blown | 98 → 88 | 10 → 9 | 73.37 → 76.39 |
| Lane with the sentry | 105 → 95 | 10 → 9 | 73.37 → 76.39 |
| Exit bolt | 98 → 83 | 9 → 8 | 73.37 → 76.39 |
| Exit open | 103 → 83 | 9 → 8 | 78.05 → 76.39 |

- Draw calls are equal or lower everywhere. Additive items are equal or lower. No full-screen layer was added.
- Texture memory is **+3.02 MB** against main until the exit opens, and −1.66 MB after.
- Decoded prop art (RGBA with mips) is +3.19 MB. Both are inside the ~4 MB budget.
- PNG bytes are −0.95 MB.
- Every number is in `perf.json`. Software GL says nothing about frame time.

**Walls against their rooms, same rows** (`checks/walls-same-height-*.md`, `fix-r1/tools/measure_r2.py`; world boxes on plain wall away from fittings):

| Wall | Round 1 ratio | Now | Texture ratio now |
|---|---|---|---|
| Records exit | 2.79 / 2.10 | **0.58 / 0.57** | 0.45 / 0.31 |
| Records entry | 2.79 / 2.10 | **0.61 / 0.62** | 0.39 / 0.28 |
| Junction blast | 1.57 / 2.07 | **0.60 / 0.70** | 0.42 / 0.93 |
| Junction exit | 3.38 / 1.24 | **1.05 / 0.55** | 0.27 / 0.16 |
| Junction entry (new) | n/a | **0.74 / 0.61** | 0.18 / 0.12 |

The first figure in each pair is the upper rows, the second the mid rows.

- **Junction exit, upper:** it measures 1.05 against the room's dark recess at x 640-790. Against the back wall beside it, under the same ceiling lamp, it is 0.16. Its top-left is lit by that fitting.
- **The reviewer's own boxes** (`measure_walls.py`, `checks/walls-reviewer-boxes-after.md`) give 0.88, 0.97, 0.84 and 1.36. Those boxes put the wall box lower than the room box and take in the door lights' pools, so they read higher.

## Files

**Package (`shots/`)**
- this `DOORS.md`;
- `doors-integration.patch` and `.stat` (the whole change against main 4bb15b0) and `doors-fix-r1-over-round1.patch`;
- `sheet.png` and `sheet-phone.png` (every state after);
- `pairs/`: 62 before|after images at 1280 and phone size;
- `crops/`: 31 3x door crops, including the junction entry (r09-r11);
- `perf.json`, `checks/` (round 1's checks moved to `checks/round-1/`), `fix-r1-tools/`;
- `integration-tools/` (round 1).

**Fix round work: `doors-r1/fix-r1/`**
- `junction/`, `records/`, `hatch/` (design `v7`): changed copies of the tracks' tools, with their new design, layers and final atlases;
- `jentry/`: the new entry door's tools, design, layers, out and NOTES.md;
- `tools/`: `grade.py`, `rgrade.py`, `measure_r2.py`, `package.py`;
- `driver/doors_capture.gd`;
- `captures/{before,after}-{1280,phone}`;
- `checks/`.

**Game (`game-doors/apps/game`)**
- New: `assets/props/junction-entry-atlas.png` (+ import).
- Changed:
  - atlases: `junction-door-atlas.png` (1024x888), `junction-exit-atlas.png` (986x644), `records-doors-atlas.png`;
  - plates: `junction-far.png`, `junction-mid.png`, `records-far.png`;
  - `manifest.json`;
  - scripts: `junction_room.gd`, `main.gd`, `records_room.gd`, `swing_leaf.gd`, `fx_presets.gd`, `junction_door_layout.gd`;
  - tests: `door_route_test.gd`, `junction_test.gd`, `room_depth_test.gd`.
- Deleted: `assets/props/junction-hatch.png` (+ import).

## Text and decisions for Nathanial (nothing below was shipped)

- **Container hint.** "E: secure the first copy." does not say why a cabinet. Draft: "E: lock the first copy in the security container."
- **Junction exit wording.** "pop the exit bolt by the hatch", "The hatch slides open." and "E: leave through the hatch." name a hatch that is a sliding door. Drafts:
  - "pop the exit bolt by the door";
  - "The bolt arcs and drops. The door slides back into the wall.";
  - "E: leave through the door."
- **Junction entry.** It needs no new line. The existing "Arm the breaker by the entrance" still reads true.
- **Still open from round 1:**
  - the blast door's 17 vs 30-35 degree turn;
  - a typeset door number;
  - the 0.5 s exit slide vs a real 2-3 s;
  - the `records_arc` sound;
  - the CONTINUE chirp on the Records leave;
  - the changelog line.

## Open issues (honest list)

1. **Not played by hand.** The longer Records walk-out (WOLF following through) and the junction entry closing have only been checked headless and in stills.
2. **Junction exit wall.** Its upper face is 1.05x the dark recess beside the arm (0.16x the lamp-lit wall beside it). It is lit by the right ceiling fitting.
3. **Junction entry.** It sits at the room's left edge (screen x 0-220 at the start). It reads mostly on arrival, while it stands open and closes.
4. **Reviewer box heights.** The reviewer's boxes still read 0.84-1.36 because of their heights and the light pools (see Numbers).
5. **Texture ratio.** It is 0.12-0.45 on the darkest walls. The grain is the paint's own, lifted; no noise was added.
6. **Thrown leaf.** Its left end is painted as torn edge channel showing the concrete fill.
7. **Image size.** Codex returned three outputs at 1254 x 1254 for 1024 targets. Each was mapped by ratio, as in round 1.
8. **Repo-root files.** `scripts/prepare_bulkheads.py` and the lighter-game docs still list deleted files. Filing the design records under `docs/research-2026-10/sources/` is still to do, now including `junction-entry-door-2026-10-13/` from `fix-r1/jentry/`.
9. **Not done:** the changelog export check, exports and device tests.

## Provenance

- **Seven Codex sessions** (built-in image generation, edit mode, run from `doors-r1/codex/<job>/`):
  - fix-junction-sealed 01a135a4-1fd6;
  - fix-junction-blown 01a135aa-7dc9;
  - records-exit-fix 01a135b6-a273;
  - records-entry-fix 01a135b6-ab61;
  - records-parts-fix 01a135b6-b160;
  - fix-junction-entry 01a135ba-ac28;
  - fix-junction-exit 01a135c7-02c3.
- **Outputs.** All 10 outputs keep their signed C2PA `caBX` manifest and are byte-identical to their originals in `~/.codex/generated_images`. Their SHA-256 hashes and uses are in `provenance.txt`.
- **Archived.** All seven sessions are archived with `codex archive`.
- **No API use.** No rollout ran an image API or `image_gen.py`.
- **Sources** are as in round 1, plus:
  - ASTM F2927 category IV and Liu et al. 2018 for the damage;
  - ICD/ICS 705 for the closer, SDI 129 for the knuckles;
  - GSA Class 5 for the lock housing;
  - REAL-LOOK section 2 for wear "where it comes from".

---

# Doors integration (doors-r1): Records entry and exit, the junction blast door, the junction exit door

Scratch only. The Git repository was not touched. Base: `origin/main` at **4bb15b0** (fetched 2026-10-13), exported to `doors-r1/game-doors/` (integrated copy) and `doors-r1/main-export/` (untouched copy, the "before"). Nothing was played by hand, so nothing here makes a claim about feel. The evidence is 17 headless suites and render.sh stills only.

## What changed

All three tracks are installed together in `game-doors/apps/game`. As one patch against main: `doors-integration.patch` (45 files, +1566 / -642). It applies cleanly to a fresh `git archive origin/main apps/game`, checked with `git apply --check --binary`.

| Door | Before (main 4bb15b0) | After |
|---|---|---|
| Records entry (x 70) | No door. The engineer appeared beside pipes. | A 3'0" x 7'0" steel secure-area door in a 300 mm concrete cross-wall, turned 17 degrees. It stands open behind the engineer on arrival, then its closer brings it shut over 3.4 s on visible hinges (lamp amber, then red). It stops the engineer at x 84 and WOLF at x 137. |
| Records copy point and exit (x 797 / 880) | A red "EXIT pod". After the copy it became a navy rectangle with a mint bar, and the same USE secured the copy and left. | The copy goes into a gray four-drawer security container at x 797. The exit door's shut leaf crosses the walkway at x 880. Securing the copy swings the leaf into the room over 3.5 s, onto a floor stop. A second USE walks the engineer through the doorway to x 918, WOLF one gap behind, and only then does the junction start. |
| Junction blast door (x 452 to 510) | A camera-facing orange bulkhead. It "blew" without visibly opening the route. | A hinged steel leaf in a 0.40 m concrete cross-wall across the walkway. The blast plays shut, then breaking (0.15 s), then blown. The leaf is thrown into the lane and lies on the deck; the doorway is left empty, with spalling, rebar, soot and a rubble pile to x 540. The engineer walks through the doorway. The status lamp on the near column runs red, amber, flashing, then dark. The TANK RELEASE alcove is now a painted bay whose two posts stand on the cover span's edges. |
| Junction exit (x 962) | A camera-facing hatch whose panel vanished. WOLF faded, and the card cut in before anyone reached it. | A power-operated sliding steel door in a concrete cross-wall. The leaf slides 2.12 m into a pocket in the far jamb, and its striped edge stays visible. WOLF steps into the doorway and waits looking back. USE works only at the door (x 870 to 901). On CONTINUE, WOLF walks through, then the engineer, nobody fades, the doorway stays empty for 0.4 s, and then the END OF SLICE card. |

Every leaf moves physically and never fades or hides; `door_route_test` checks this frame by frame. Door art is door-only, with transparent openings and a painted space behind each hole: a service passage at the junction exit, a lit passage at the Records exit, and the lane at the blast door.

## How the merge was done (and what it needed)

1. **Hatch** `hatch/junction-exit-door.patch`: `git apply --binary --exclude=scripts/prepare_bulkheads.py` applied cleanly. The excluded file is repo-root and was not exported.
2. **Records** `records/out/records-doors.patch`: two hunks in `main.gd` were rejected because main moved on (PR #63 sound work) and the hatch patch had changed the same lines. I merged them by hand:
   - `records_room.close_entry_behind()` after `enter_records()`, below main's new safe-point chirp;
   - the `records_exit_walking` branch of `_wolf_target_x()`, after the hatch's `end_card_active` branch.
3. **Junction** `junction/tools/patch_game.py`: I ran a copy (`shots/integration-tools/patch_game.py`, `patch_extra.py`) with three fixes:
   - The header-comment replacement now matches the hatch's rewording.
   - The `_build_door` replacement stops at the hatch's `## The exit door's pieces` instead of `_build_particles`. Without this it deleted the hatch's `_build_exit()` and `exit_leaf_anchor()`.
   - The hatch's uses of the old `DOOR_LIP_Z` are renamed to the junction's `DOOR_FRONT_Z` (both z 2), in `junction_room.gd` and `room_depth_test.gd`. I also dropped one identity replacement that no longer matched.
4. **New on main since the tracks:** `press_sound_test` (P0-14: every state-changing press is heard and changes the screen within one frame). It failed on the new flows, and I fixed it with the smallest changes:
   - `main.gd _leave_records()`: the leave press plays `chirp -10 dB, 0.75`, the same sound as CONTINUE on a closing shot, and clears the hint bar (the save toast from securing the copy, or the USE prompt) as they set off. `_context_hint()` returns "" while `records_exit_walking`. No text was added or changed.
   - `press_sound_test.gd`:
     - `records_exit_walking` is added to its state variables;
     - leaving Records waits for the walk to end in the junction;
     - USE at the bolt panel once the door is open is checked to do nothing;
     - "leaving" is pressed at the door (x 885.5).
5. **Added `tests/door_route_test.gd`** (the requested checks, on the integrated game):
   - Every shut door stops the route: Records exit at x 880 (engineer stopped at 866), and the blast door at 452.
   - Each opened doorway is walked through:
     - Records exit: the engineer reaches more than 908.5, past the near column, before the junction starts;
     - Blast door: the engineer walks to more than 510;
     - Exit door: WOLF and the engineer both pass the near jamb at 971.6.
   - The leaf is drawn whole (visible, alpha 1 up its parents) in every frame while its doorway is used: the entry closing, the exit swing, the walk out, the blast (shut, then breaking, then lying, and the lying leaf is on the deck), and the exit slide and walk out.
   - The END card starts only after both are past the hatch, WOLF first, and nobody fades.
   - No authored resting spot lays an actor's drawn body (`M0Actor` reach) across a shut door's leaf. Where a resting body crosses an **open** doorway, the door's near piece must draw over the actors. The test prints those spots (see Open issues).

## Checks (headless, isolated HOME, `scripts/check-game.sh` equivalent; the changelog export step is skipped because apps/docs is not exported)

| Copy | Result |
|---|---|
| main 4bb15b0 (untouched export) | 16 / 16 suites pass. `press_sound`: 29 presses, 29 heard within one frame. |
| integrated copy | **17 / 17 pass**, including the new `door_route_test` (17 s). `press_sound`: 29 presses, 29 heard. |

Both imports ran twice with no unexpected errors. Logs: `shots/checks/` (`main-suites.txt`, `after-suites.txt`, `door_route_test.log`), with full logs in `integrate/logs-main/` and `integrate/logs-doors/`.

## Numbers (render.sh, 1280x720, same driver on both copies, p50 of 60 frames)

| State | Draw calls main | after | Objects main | after | Additive main | after | Texture MB main | after | Video MB main | after |
|---|---|---|---|---|---|---|---|---|---|---|
| Records arrival | 49 (max 53) | 49 (53) | 209 | 209 | 9 | 9 | 73.12 | 74.88 | 81.44 | 83.20 |
| Records entry shut | 49 | 49 | 209 | 209 | 9 | 9 | 73.12 | 74.88 | 81.44 | 83.20 |
| Records copy point | 47 | 45 | 146 | 144 | 9 | 9 | 73.12 | 74.88 | 81.44 | 83.20 |
| Records exit open | 47 | 45 | 211 | 208 | 9 | 9 | 73.12 | 74.88 | 81.44 | 83.20 |
| Junction sealed | 94 | 90 | 350 | 344 | 10 | 9 | 73.37 | 75.13 | 81.79 | 83.54 |
| Junction blown | 98 (102) | 92 (96) | 389 | 383 | 10 | 9 | 73.37 | 75.13 | 81.79 | 83.54 |
| Lane with the sentry | 105 (106) | 96 (97) | 348 | 338 | 10 | 9 | 73.37 | 75.13 | 81.79 | 83.54 |
| Exit bolt | 98 | 91 | 283 | 277 | 9 | 8 | 73.37 | 75.13 | 81.80 | 83.56 |
| Exit open | 103 | 89 | 267 | 253 | 9 | 8 | 78.05 | 75.13 | 86.48 | 83.56 |

- Draw calls are equal or lower in every state (−2 to −14). Additive items are equal or lower (−1 in the junction). No full-screen layer was added.
- Texture memory is **+1.76 MB** until the exit opens. After that it is **−2.92 MB**, because main loaded the 1.27 MB `corridor-bulkhead-open` passage there and it is gone now.
- Static decoded size of the new art (RGBA with mips): new 30.60 MB vs replaced 28.69 MB, **+1.91 MB**. That is under the ~4 MB budget.
- PNG bytes on disk: **−1.13 MB** (4,099,734 vs 5,228,794).
- Every number is also in `perf.json`. Software rendering says nothing about frame time.

## Route and station x changes (all forced by a door; gameplay beats, choices, saves and text unchanged)

**Records (records track)**
- The engineer's minimum x goes from 40 to 84 (the entry face is at 70). WOLF's follow minimum goes from 40 to 137.
- Until the copy is secured, the engineer's maximum x goes from 920 to 866 (the exit face is at 880). WOLF's follow maximum in Records goes to 813. When they leave, WOLF walks to 830.
- The exit station (x 830, half 38) becomes the container station (x 797, half 10, worked from the right). Securing walks the engineer to 818. WOLF's avoid span goes from 792..868 to 776..807.
- The USE zone stays at |x − 830| ≤ 58. Once the exit is open it also reaches x ≥ 830.
- Leaving walks the engineer to x 918 (about 0.45 s) before the junction starts. If USE is pressed during the swing, the leave waits for the swing to finish.
- Records saves are clamped inside the doors when loaded. The save format is unchanged.
- The EXIT label moves from x 830 to 862. The foreground pipe strips at both Records edges are removed (new `room_depth.near_left_edge` switch). The exit spark particles are removed.

**Junction blast door (junction track)**
- No x changes. The geometry was fitted inside the old door body: the doorway crosses the walk line between jamb feet 465.9 and 491.3.
- Only the SEALED DOOR / DOOR DOWN placard moves, from x about 491.7 to 479.

**Junction exit (hatch track)**
- `HATCH_X` 880 is removed. The exit is the cross-wall door: `EXIT_DOOR_X` 962, near jamb 971.6, far jamb about 925.5.
- Leaving works only from `HATCH_REACH_MIN_X` 870 once the door is open; on main it fired anywhere from about 741, at the bolt panel.
- While the door is open, the engineer can walk only as far as `HATCH_REACH_MAX_X` 901.
- Once the door is open, WOLF moves from 902 to `WOLF_DOORWAY_X` 985.
- On the walk out, the engineer goes to 991.6 and WOLF to 1041.6, then on to 1100. Nobody fades, and both walk at 0.55 of the follow speed.
- The play camera's right edge moves from 960 to 1000 once the bolt is open. The closing camera moves from (650.3, zoom 1.55) to (670.3, zoom 1.45).

**Integration**
- No x changes. The Records leave press now plays the CONTINUE chirp and clears the hint bar on its frame (see step 4 above).

## Files

**Package (`doors-r1/shots/`)**
- `DOORS.md` (this file).
- `doors-integration.patch` and `.stat`: the whole change against main 4bb15b0.
- `sheet.png`: every after state, 1280x720, labelled with each actor's x and the beat.
- `sheet-phone.png`: the same states at 2400x1080.
- `pairs/`: 58 before|after images, `<state>.png` at 1280x720 and `<state>-phone.png` at 2400x1080. Main has no `j12-at-the-door` (it leaves from the bolt) and no Records walk-out frames (it cut straight to the junction), so those halves are marked "no equivalent frame on main".
- `crops/`: 27 3x nearest-neighbour crops (before | after) of each door in each state: Records entry r01 to r03, Records exit r04 to r08, blast door j01 to j07, exit door j08 to j15.
- `perf.json`: per-state numbers for both copies.
- `checks/`: suite summaries for main and after, `door_route_test.gd` and its log.
- `integration-tools/`: the adjusted `patch_game.py` and `patch_extra.py`, the render driver `doors_capture.gd`, and `package.py`.

**Integrated game:** `doors-r1/game-doors/apps/game`, a scratch git repo with tags `records-merged` and `junction-merged`.
- New files:
  - `assets/props/junction-door-atlas.png`, `junction-exit-atlas.png`, `records-doors-atlas.png` (+ `.import`);
  - `scripts/junction_door_layout.gd`, `atlas_mesh.gd`, `swing_leaf.gd` (+ `.uid`);
  - `tests/door_route_test.gd` (+ `.uid`).
- Changed:
  - `assets/manifest.json`, `assets/rooms/records-far.png`, `records-mid.png`;
  - `scripts/junction_room.gd`, `main.gd`, `records_room.gd`, `room_depth.gd`, `m0_actor.gd`;
  - tests `chapter_scene`, `debug_tools`, `follow_spacing`, `junction`, `m0_scene`, `press_sound`, `room_depth`, `room_lights`, `sentry`.
- Deleted (the lighter-game rule: file, import, manifest entry and every reference):
  - `assets/props/junction-bulkhead-{sealed,breaking,blown,front-lip}.png`, `corridor-bulkhead-open.png`, `records-exit-hatch.png` and their imports;
  - `art-source/doors/junction-{sealed,breaking,blown,front-lip}.png` and `corridor-open.png`.
- The register has 62 entries. Every asset PNG is registered, and no entry points at a missing game file.

**Captures:** `doors-r1/integrate/captures/{before,after}-1280/` and `{before,after}-phone/`, with `-clean` copies without UI and `_run.json` per run.

**Track design records** (unchanged, to be filed under `docs/research-2026-10/sources/`):
- `doors-r1/junction/` → `junction-blast-door-2026-10-13/`
- `doors-r1/hatch/` → `junction-exit-door-2026-10-13/`
- `doors-r1/records/` → `records-doors-2026-10-13/`

## Text and decisions for Nathanial (nothing below was shipped)

- **Records**
  - Container hint: "E: secure the first copy." could become "E: lock the first copy in the security container."
  - Leaving hint: "E: follow the service line toward Archive." could become "E: go through the exit and follow the service line."
  - `records_arc` (a crackle) plays with nothing visibly arcing. Should it become a bolt-release clunk?
- **Junction exit**
  - The lines still say "hatch" for what is now a sliding door. Possible rewording: "The bolt arcs and drops. The door slides back into the wall."
  - An optional line for USE at the bolt panel once the door is open: "The door's open. Walk up to it."
  - Keep the 0.5 s slide, or a real 2 to 3 s?
  - Should the door get a typeset stencil or door number, like the corridor's SECTOR 4B / DOOR 4B-07?
- **Blast door**
  - A typeset stencil "J-02" over the door and "BLAST DOOR" on the column?
  - Keep the corridor's 17-degree turn (consistent, but narrow on screen: about 34 screen px), or turn it 30 to 35 degrees for about 1.7x more face? That means new masks and one more paint pass.
- **Integration:** the Records leave press now plays the CONTINUE chirp (no text). Is that the right sound, or should it be a door or footstep sound?
- **Draft changelog line (hatch track):** "The Service Junction's exit is now a sliding steel door in a concrete wall: when the bolt pops, its leaf runs back into a pocket in the wall, WOLF steps into the doorway and waits, and the two walk out through it, one after the other, before the END OF SLICE card. Checked by automated tests and still images only."

## Open issues (honest list)

1. **WOLF at the rubble stands in the blown doorway with his head behind the near column** (x 448, his body about 381..515 across the doorway at 466..510; see `crops/j04-blown-junction-blast-3x.png`). The depth is consistent, because the column draws over him. But it is the "WOLF overlaps door frames" look the playthrough reviewers named.
   - The junction track kept `WOLF_RUBBLE_X` 448 (gameplay). There is no free floor his 130 px body fits into: the valve is on the left, and the engineer at `CHOICE_X` 526 and the lane are on the right.
   - Options for Nathanial: (a) keep it; (b) have him face back at the engineer while he waits, so his tail rather than his head goes through the doorway (this matches the exit, where he waits looking back); (c) move the wall. Option (c) would change the approved door geometry and the rubble line.
   - `door_route_test` allows this case only because the doorway is open and the column draws over him. It prints every such spot:
     - Records, WOLF following out (x 830);
     - WOLF at the rubble (448);
     - the lane question (526, the engineer just past the column);
     - WOLF waiting in the exit doorway (985, by design).
2. **Before the exit opens, WOLF's tail at the bait spot (x 902) reaches about 4 to 7 px into the exit's reveal.** That is past the approach face at 962 but short of the shut leaf at 973.3, so it is in front of the leaf. It read as fine at 3x (`crops/j08-exit-bolt-junction-exit-3x.png`).
3. **Both junction doors are much less prominent than the old camera-facing art.** The 17-degree cross-walls read as narrow grey slabs (blast door about 34 screen px; exit at the right edge, about 46 px). Before the bolt opens, the exit sits just outside the play camera (right edge 960). The exit's cross-wall is a large plain concrete face, paler than the room's blue-painted art. Whether either reads in play needs a hand-played check.
4. **Effects still use soft blobs.** The bolt's sparks at the exit panel (`j10-hatch-opening`) are mint/cyan soft discs from the shared `FxPresets`. The relay, exit and corridor sparks and dust also still use the shared soft discs; only the junction blast was retuned.
5. **Repo-root `scripts/prepare_bulkheads.py` now has no source files left**, because both families' art-source images are deleted. It should be removed with this change. The lighter-game docs (`PLAN.md`, `map-assets.md`, `map-perf.md`) still list the deleted files, as research history.
6. **Track open issues carried over:**
   - The junction cover cue is now the painted posts only.
   - The thrown leaf reads as a slab rather than plainly as the door at game scale.
   - The exit bolt does not visibly drop.
   - A faint board-form seam shows on the exit wall.
   - The Records lamps are small and the container is plain.
   - At the Records entry, the pale wall reads brighter than the blue room.
   - An engineer who stops in the Records exit doorway (x 886..908) is mostly hidden by the near column.
   - "E: secure the first copy." shows from x 772 to 888, including at the shut door.
7. **Not checked:** the in-game changelog export check (needs `apps/docs`), exports, devices, and hands-on play of any route. The flaky `sentry_test` 1 px check that the hatch track saw did not recur in the two full runs of the merged copy here.

## Provenance

- No Codex session was started for the integration, and no image was generated or edited.
- Ten Codex sessions were made by the tracks: junction 01a1340f, 01a13418, 01a1341f; hatch 01a13425-e4a3-79f3 and -7aa0; records 01a1341d-ce40, -ce3d, -ce41, 01a13486-5993, -59a0.
  - All are listed in `doors-r1/provenance.txt` and all 10 are in `~/.codex/archived_sessions`.
  - All 10 raw outputs under `doors-r1/codex/*/out/` still carry their C2PA `caBX` chunk (checked chunk by chunk).
  - The integration's provenance line is appended to `provenance.txt`.
- **Sources** (from the tracks):
  - ASTM F2927 categories via SDI 133;
  - UFGS 08 39 54 (blast-resistant doors) and 08 13 73 (sliding metal doors);
  - Hartmann HET 02; BABS TPH 2019; Liu et al. NDIA 2018;
  - 29 CFR 1910.144(a)(3);
  - FED-STD-595 chips per REAL-LOOK section 8;
  - ICD/ICS 705 v1.4; SDI 129-24; UMich 08 11 13; GSA Class 5 cabinets; ANSI/BHMA A156.19.
- Method and design language: `docs/research-2026-10/sources/corridor-door-end-2026-10-12/` (DESIGN.md v6) and `REAL-LOOK.md`.
