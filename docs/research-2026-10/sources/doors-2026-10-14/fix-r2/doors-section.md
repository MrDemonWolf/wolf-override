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

