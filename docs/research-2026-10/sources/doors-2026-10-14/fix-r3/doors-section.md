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

