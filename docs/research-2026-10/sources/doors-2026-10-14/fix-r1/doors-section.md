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

