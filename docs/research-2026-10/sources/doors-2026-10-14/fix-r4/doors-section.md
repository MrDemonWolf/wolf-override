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

