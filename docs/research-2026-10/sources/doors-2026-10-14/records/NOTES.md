# Records Access doors (doors-r1, records track)

## Fix round 4 (2026-10-14, review r4 M1): what changed

- **Face choice.** `SwingLeaf.room_face_shows()` picks the face the room's pinhole camera sees (camera at x = vpx / 40 m, d = -38 m). The old test assumed a view straight along +d, so it drew the outside face for 17-31 degrees of each Records swing.
- **Light.** The ambient and the floor bounce have their own exposure (`EXIT_LEAF_FILL` 0.0370, `ENTRY_LEAF_FILL` 0.0509). The door light is back at the design's reach of 1.4 m. Two more lights come from the surfaces round each door: the lit threshold and passage deck seen through the doorway, and the cross-wall's lit face beyond the hinge jamb. The gains were fitted with `fix-r4/tools/{leafsim,lp3,l1,refine,dipfix}.py` and checked on render.sh frames with `swingcheck.py`.
- **Measured** (render.sh 1280x720):
  - leaf / wall at 10-50 % open: entry 0.84-2.29, exit 1.09-1.77;
  - leaf / shut leaf: 1.05 or more;
  - open leaf by the hinge / reveal: entry 0.83 / 0.86 / 0.79, exit 0.68 / 0.74 / 0.85.
- **Shut leaves** read 0.78x (entry) and **1.05x (exit)** their walls; round 3 had 0.54 and 0.47.
- No asset changed.

## Fix round 3 (2026-10-14, review r3): what changed

Tools: `doors-r1/fix-r3/` (`tools/leafwear.py`, `tools/rgrade2.py`, `tools/leafcheck.py`, `tools/leaffit.py`, `tools/leaflight.py`). No Codex session.
- **R3-2, the open leaves:** an open leaf and the far-jamb reveal it hangs on face the same way under the same door light, so the leaf now takes that light. The door light in `RecordsRoom.EXIT_LEAF_LIGHTS` / `ENTRY_LEAF_LIGHTS` is a true Lambert source (no wrap) of 0.5 m reach, fitted with `leaffit.py` and closed on render.sh frames; the exposures are 0.082 (exit) and 0.225 (entry). The head by the hinge reads about 0.75x the reveal, the free edge low stays under the wall, and the shut leaf only takes the light grazing it. The door lights' intensities follow their painted reveals.
- **R3-2, flat faces:** designed wear where use and water put it (hand grime round the lever, primer rubbed through on the latch stile, a grime band and heel marks low down, a few level cart scrapes at 0.35-0.95 m, dirt in the edges), then the paint's own grain lifted at 1 and 2 face px (the faces draw at about 0.85x with trilinear mipmaps).
- **Battens (human r3):** the passage batten's diffuser is a frosted, cool strip at 0.28 linear, about sRGB 145 (it was clipped white: the detail lift had driven it to 255, so the fitting is now left out of that lift), and its housing, clips and end caps show in their own spill.

## Fix round 2 (2026-10-13, review r2): what changed, and corrections to the claims below

Tools and outputs: `doors-r1/fix-r2/records/` and `doors-r1/fix-r2/tools/` (`grade2.py`, `rgrade2.py`, `feedback.py`, `ghostcheck.py`, `measure4.py`).

**Correction.** The passages below (and the fix-round-1 section) describe the space behind the exit as "concrete back wall, two painted pipes, a cable ladder and a vapour-tight LED", and the vestibule behind the entry as wall and fitting. In rounds 1 and fix-1 the cleaned layers behind both doorways **also held a painted copy of the shut door** (lever, kick plate), because the door ends were painted shut and the space behind each hole was built from that painting (review r2, N1). The leach streaks "under the two new pipe penetration plates" were under plates with no pipe (S2).

**Round 2:**
- Both door ends were **painted open, with no leaf in the doorway** (sessions r2-records-exit, r2-records-entry). The space behind each doorway takes detail only where it was visible in that painting (`cleanup.py beyond_visible`, `mirror_fill`).
- `ghostcheck.py` fails a layer whose fine edges line up with the shut leaf's edges inside the opening. It fails both round-1 layers (correlation 0.37) and passes round 2 (−0.02 to −0.03).
- The driver captures each doorway with its leaf hidden (`r01-noleaf`, `r07-noleaf`): those frames show only the passage and the vestibule.
- **Gone:** the two blank penetration plates and their streaks (`PIPE_RUNS = ()`).
- **Added:**
  - form-panel joints (1.2 x 2.4 m) and grouted 25 mm tie cones 0.6 m on centre on the cast faces (`cast_marks`);
  - a real 1.2 m batten in each passage, with body, clips and end caps (`passage_fitting`).
- **Light (N3):** one grade, `grade2.py`:
  - linear light, at 0.60x the back wall at the corner, closed on render.sh frames;
  - each leaf's level set at runtime (`RecordsRoom.EXIT_LEAF_EXPOSURE` 0.17, `ENTRY_LEAF_EXPOSURE` 0.25), so painted steel sits at 0.77x and 0.91x the concrete beside it;
  - the leaf faces despeckled, with the room face's lever, rose and thumbturn lifted (S1);
  - the floor bounce in the leaves' light matches the design (0.30).
- **Container (S6):** linear grade, falling off toward its base, at 0.95x the exit wall at the same rows.

## Fix round 1 (2026-10-13, review r1): what changed and where the record now lives

Tools and outputs: `doors-r1/fix-r1/records/` (a changed copy of this folder's tools). Corrections to the
claims below: in round 1 the hinge knuckles were 0.7 px wide and no closer was drawn; both now are.
- **Values and look (M1, the human pass):** designed wear (`wall_wear`: mottle, damp band, seepage under the
  pour joint, leach streaks under the two new pipe penetration plates, a kick zone either side of the door),
  re-painted to the room's grit (sessions records-exit-fix, records-entry-fix), the paint's detail kept to
  +-60 % (log), graded by `fix-r1/tools/rgrade.py` to 0.70x the Records back wall at the same height.
- **Two walls, two layouts (S6):** the exit's pour joint at 3.6 m, the entry's at 4.2 m; the camera only on
  the exit; the junction box on the latch side over the exit, the hinge side over the entry.
- **Closer and hinges (S5):** a 310 x 65 mm surface closer on the leaf's room face by the hinge
  (session records-parts-fix), its regular arm drawn live by `SwingLeaf.arm_joints()` to a shoe on the head,
  the knuckles 26 mm (about 2 world px), the floor stop 85 mm.
- **EXIT sign (the human pass):** a steel exit-sign housing standing square off the wall over the door at
  3.9 m, its face blank and dark; the game's EXIT caption is its legend.
- **Container (S8):** a 130 x 100 mm lock housing, a 120 mm dial ring, an index mark; re-painted as grey
  enamel; set in the room's light (darker toward its base).
- **Entry's stub angle:** dull steel, not worn bright (the bright line at the bottom left in r01-r03).


This track replaces the Records EXIT "pod" (`assets/props/records-exit-hatch.png`, the navy rectangle drawn by `_draw_exit()`) with two real objects and adds a way in at the room's left end. Everything here is scratch work. The repository was not touched. The patch is against `origin/main` at 9c7371d, exported to `doors-r1/main-records/`.

Nothing was played by hand, so there are no feel claims. The evidence is:
- headless suites;
- rendered stills from `tools/render/render.sh` (llvmpipe, in a container);
- draw-call and texture-memory monitors read inside that container.

## What the room has now

1. **The place the first copy is secured.** A GSA Class 5 four-drawer legal security container stands at x 797, just behind the walk line, left of the exit.
   - Size: 0.53 x 1.486 x 0.851 m. It is gray, single-lock design, with one FF-L-2740 spin dial on the top drawer that controls all four drawers.
   - It stands on the floor with a painted contact shadow.
   - It is lit by the room's ceiling lamp 1 and by the exit's door light.
   - Securing the copy walks the engineer to the container's right side (x 818), facing its lock.
2. **The exit.** A 300 mm cast cross-wall turned 17 degrees across the walkway, in the approved corridor door-end language.
   - The door in it is a 3'0" x 7'0", 1-3/4 in steel secure-area door. Its shut leaf crosses the walk line at x 880.
   - It hangs on three 4-1/2 in hinges at the far jamb (SDI 129 spacing), with a hollow-metal frame and a steel threshold.
   - The header has a high security switch and holds the concealed low-energy operator.
   - Above the door: a vapour-tight LED door light with its conduit, and a junction box.
   - A dome camera on an arm watches the room.
   - The near column has steel arris angles and a guarded status lamp. The lamp is red while the door is shut, amber while it moves and green when open.
   - A 0.15 m stub curb runs to the camera.
   - The leaf **swings into the room on its hinges** onto a floor stop. A mesh is drawn in its own plane, so it never fades or vanishes. The swing takes 3.5 s, meeting ANSI/BHMA A156.19's rule of 3 s or longer to 80 degrees.
   - The service line passage is painted behind the doorway in the far plate: concrete back wall, two painted pipes, a cable ladder on strut brackets and a vapour-tight LED, with its dry slab.
   - The shut leaf stops the engineer (collision face x 880) until the copy is secured.
   - Leaving, the engineer **walks through the doorway** into the passage (to x 918, past the near column) before the junction starts. WOLF follows one gap behind.
3. **The way in (entry).** The same wall and door type, mirrored, at x 70. This is the primary entrance, so its outside face carries the FF-L-2740 combination lock.
   - Behind it is a vestibule, as ICD 705 recommends.
   - On entering Records from the corridor, the entry stands open behind the engineer and its closer brings it shut: 0.35 s, then 3.4 s. Its lamp is amber while it moves and red once it latches.
   - It stops the engineer at x 84 and WOLF at x 137.

The doors and the container are drawn in **two draw calls** in total. Both are `AtlasMesh` nodes over one lossless atlas:
- everything behind the walk line, drawn right after the mid plate;
- the exit's near column and stub, drawn over the actors.

The lamp glass quads take their live tint as vertex colours. The design, masks, specs and every measured dimension are in `records/design/` and `records/tools/rdesign.py` / `rmodel.py`, as in the corridor door end's method.

Removed from the room:
- the hatch prop with its reflection and shadow;
- the navy rectangle;
- the mint spark puff at the exit;
- the foreground pipe strips at both room edges (the corridor dropped its right one for the same reason).

## Files

All paths are under `doors-r1/records/`.

| File | What |
|---|---|
| `out/records-doors.patch` | Full patch against exported main, with binaries (`git apply --binary`). It was checked with `git apply --check` on a fresh `git archive origin/main apps/game` export. |
| `out/records-doors-code.patch` | The text-only part (scripts, tests, manifest), for reading. |
| `out/placement.json` | Every atlas region, each piece's world top-left and scale, the leaves' hinge axes and lights, the mid-plate erasures, the far-plate parallax shifts and the memory figures. |
| `out/assets/props/records-doors-atlas.png` | 874x710 RGBA lossless atlas (SHA-256 35e913ee...). |
| `out/assets/rooms/records-far.png`, `records-mid.png` | Main's plates with the passage and vestibule painted in (far), and the end machinery erased where the walls stand (mid). Same sizes and import settings as main's. |
| `layers/{exit,entry}/clean-{wall,front,beyond}.png`, `layers/leaf/clean-*.png`, `layers/container/clean-container.png`, `layers/report.json` | Cleaned layers at 4 px per world px, with cleanup checks (silhouette match 1.0 and 0 alpha outside the design on every layer). |
| `design/{exit,entry,leaf,container}/` | Flat-shaded construction renders, one mask per part, and `spec.json` (every part's dimensions and job). |
| `tools/rmodel.py`, `rdesign.py`, `paint_inputs.py`, `run_job.sh`, `rules.txt`, `cleanup.py`, `install.py`, `compose.py`, `preview_clean.py`, `patch_main.py`, `run_suites.sh` | The deterministic pipeline: model, design, Codex inputs, cleanup, install, previews, the main.gd edit script and the suite runner. |
| `previews/` | Design and clean previews in the room's plates (exit and entry at 0, 45 and 90 degrees). |
| `captures/main-r2/`, `captures/final/` | render.sh walkthroughs of main and of the patch: entry, secure, close, leave. `_log.txt` records state, draws and texture memory per frame. |
| `captures/draws-main/`, `captures/draws-final/` | Draw calls per state (minimum over 20 frames). |
| `captures/fx/` | Depth pass on and off at both doors (no parallax gap at either doorway). |
| `captures/sheet-final.png`, `sheet-fx.png`, `crops-r4.png` | Review sheets. |
| `checks/base/`, `checks/patched/r10/` | Headless suite logs for main and for the final patch (15 of 15 pass). |
| `../codex/records-entry/`, `records-exit-v2/`, `records-parts-v2/` | Codex jobs in use (prompt, refs, run.log, notes, raw output with C2PA). `records-exit/` and `records-parts/` (v1) are superseded and unused. |
| `../provenance.txt` | The records entries: sessions, hashes, originals, use, archiving. |

## Code changes (in the patch)

- `scripts/records_room.gd` (rewritten):
  - removed: the EXIT_HATCH prop, `exit_art`, `EXIT_REST` and `_draw_exit()`;
  - added: the atlas constants (from placement.json) and the `exit_leaf` and `entry_leaf` (SwingLeaf);
  - added: `plate_mesh` and `front_mesh` (AtlasMesh), and two StaticBody2D door bodies;
  - added: `open_exit(animate)`, `close_entry_behind()`, `exit_swinging()`, the lamp setters and `container_rect()`;
  - changed: `near_left_edge` and `near_right_edge` are set to false;
  - changed: the EXIT caption moves to x 862, clear of the near column. Captions stay under the actors, as a follow_spacing check requires.
- `scripts/swing_leaf.gd` (new): a side-hinged leaf in the game camera, lit per vertex by the design's own lights. It can be drawn by a host mesh.
- `scripts/atlas_mesh.gd` (new): draws atlas quads and leaves as one triangle array.
- `scripts/room_depth.gd`: new export `near_left_edge` (default true; only Records sets it false).
- `scripts/main.gd`:
  - the Records station list and new `RECORDS_*` constants;
  - `_at_records_exit()` and `_leave_records()` (which waits for the leaf to reach its stop if it is still swinging);
  - `records_exit_walking`, with its resets and its hold on the controls;
  - the secure step to the container;
  - `_sync_records_room` opens the exit;
  - WOLF's follow min and max in Records, and his walk-out target;
  - the machine span for the container;
  - a clamp on restored Records positions;
  - the hint zone;
  - the debug beat;
  - the exit spark particles removed.
- `assets/manifest.json`:
  - the `records-exit-hatch` entry is replaced by `records-doors-atlas`, marked as awaiting Nathanial's review;
  - the `records-far` and `records-mid` modifications are updated.
- `assets/props/records-exit-hatch.png` and its `.import` are deleted. Adds `records-doors-atlas.png` and its `.import`.
- Tests:
  - `room_depth_test`: door geometry, leaf never hidden, container on the floor, the near strips made optional;
  - `chapter_scene_test`: the shut exit stops the engineer, the copy is secured at the container, the leaf swings rather than fading;
  - `junction_test`: a USE mid-swing waits, the engineer walks out past the doorway before the junction;
  - `follow_spacing_test`: waits for the walk-out.

## How to integrate

1. `git apply --binary out/records-doors.patch` from the repo root, on main at 9c7371d or later. If other door tracks touched `main.gd`, apply this one last and resolve by hand. It is self-contained in Records except for `room_depth.gd`'s new export.
2. Copy this track's design record to `docs/research-2026-10/sources/records-doors-2026-10-13/`. The code comments and the manifest point there. Copy:
   - `NOTES.md` (as the design record);
   - `tools/`;
   - `design/*/spec.json` and masks;
   - `layers/report.json`;
   - `out/placement.json`;
   - the three Codex jobs in use (`codex/records-entry`, `codex/records-exit-v2`, `codex/records-parts-v2`, with raw outputs byte for byte and C2PA kept);
   - the records lines of `provenance.txt`.
3. Run `godot --headless --import`, then `scripts/check-game.sh`. Here, the 15 suites passed on the patched copy with isolated HOMEs. The repo script's changelog check was not run.
4. Before merging:
   - Nathanial reviews `captures/final/` and `captures/sheet-final.png`;
   - someone plays Records by hand (entry, both copies, secure, leave), since no hand play was done;
   - update the credits and the in-game changelog if Nathanial wants;
   - update Notion and Jira (not touched here).

## Route and position changes (all forced by the doors)

- Records engineer minimum x changes from 40 to 84 (entry collision face x 70). WOLF's follow minimum changes from 40 to 137.
- The engineer's maximum x before the copy is secured changes from 920 to 866 (exit collision face x 880). WOLF's follow maximum in Records changes from 920 to 813, shut or open, so he never idles in the doorway. When leaving he walks to x 830.
- The exit station (830, half 38, reach 58, any side) is replaced by the container station (797, half 10, reach 58, worked from the right). Securing walks the engineer to x 818. WOLF's machine span changes from 792..868 to 776..807.
- The USE zone stays |x - 830| <= 58. Once the exit is open it also reaches on to the room's end (x >= 830), so USE works in the doorway and passage too.
- Leaving: the USE starts a short walk to x 918 (about 0.45 s from x 818 at the follow speed) before `_enter_junction()`. Within 3.5 s of securing, it first waits for the leaf to reach its floor stop. Controls are off during the walk-out.
- Restored Records saves are clamped inside the doors (x 84..866 while the exit is shut). The save format is unchanged.
- EXIT caption x changes from 830 to 862.

Unchanged: beats, choices, saves, all text, the chapter-close beat and camera, and the records_arc sound, shake, flash and rumble timing.

## Text for Nathanial (drafts only, nothing shipped)

No player-facing line changed, and every current line still reads true.

These suggestions point the words at the new objects:
- Hint at the container: current `E: secure the first copy.` Proposed: `E: lock the first copy in the security container.`
- USE at the exit before both copies: current `Exit sealed until the purge order and mirror timestamp are copied.` Fine as is.
- Leaving hint: current `E: follow the service line toward Archive.` Fine. Optional: `E: go through the exit and follow the service line.`
- The sound `records_arc` (a crackle) now plays with nothing visibly arcing. A bolt-release clunk would match the door better. This is a sound choice for Nathanial and was not changed.

## Measured (render.sh container, llvmpipe; compare only with render.sh)

**Draw calls in Records**, minimum over 20 frames, same states:

| State | main | patched |
|---|---|---|
| Left clamp, shut | 46 | 46 |
| Left clamp, complete | 49 | 46 |
| Right clamp, shut | 46 | 44 |
| Right clamp, complete | 46-49 | 44 |

- **Additive items:** none added. The exit's CPUParticles2D spark emitter is removed.
- **Texture memory** (RENDER_TEXTURE_MEM_USED): 73.24 MB on main, 75.04 MB patched, so **+1.80 MB**. The atlas is 874x710 lossless with mipmaps, about 3.3 MB. The 512² hatch with mips (1.4 MB) is removed. The far and mid plates keep main's sizes and formats.
- **Headless:** 15 of 15 suites pass on the patch (`checks/patched/r10.summary`). Main's baseline also passed 15 of 15 (`checks/base`).
- **Rendered stills** (`captures/final`):
  - the entry opens and shuts behind the engineer;
  - the engineer is stopped at the shut entry;
  - securing at the container, the lamp goes amber and the leaf swings, then green and open;
  - the engineer walks through the doorway into the passage.
- **No parallax gap** at either doorway with the depth pass on or off (`captures/fx`).

## Sources (fetched and read; local copies in `research/`)

- ICD/ICS 705 Technical Specifications for Construction and Management of SCIFs, v1.4 (NCSC, 2017-09-28), ch. 3 section E "SCIF Door Criteria": https://archive.dni.gov/files/NCSC/documents/Regulations/Technical-Specifications-SCIF-Construction.pdf
  - primary entrance: FF-L-2890 deadbolt, FF-L-2740 combination lock and access control;
  - secondary door: FF-L-2890 egress device with no combination lock;
  - a vestibule when practical;
  - an automatic non-hold door closer inside;
  - hinge pins protected;
  - steel doors 1-3/4 in with 18 ga faces, hinges reinforced to 7 ga;
  - ch. 7: the HSS alarms before the door opens 1-3/4 in.
- Steel Door Institute, SDI 129-24 Hinge and Strike Spacing (4-1/2 in hinges, 1-3/4 in doors): https://steeldoor.org/wp-content/uploads/2020/02/SDI_129.pdf
- University of Michigan master spec 08 11 13, Hollow Metal Doors and Frames (frames, anchors, threshold practice): https://umaec.umich.edu/for.archs/masterspec/08/MS081113.pdf
- GSA Class 5 Legal Size Filing Cabinets (AA-F-358):
  - four-drawer is 58-1/2 x 20-7/8 x 33-1/2 in, about 1195 lb;
  - single-lock design, one FF-L-2740 lock on all drawers;
  - gray.
  - Sources: https://exwc.navfac.navy.mil/Portals/88/Documents/EXWC/DoD_Locks/PDFs/GSA_Class_5_Legal_Size_Filing_Cabinets.pdf (also https://origin-www.gsa.gov/system/files/Class_5_Filing_Cabinets.pdf)
- ANSI/BHMA A156.19 low-energy operators: opening to backcheck or 80 degrees in 3 s or longer, closing from 90 to 10 degrees in 3 s or longer. As quoted at https://www.autodoorandhardware.com/Understanding-ANSI-A156-19-Low-Energy-Door-Operator-Require-s/123397.htm
- The method and design language: `docs/research-2026-10/sources/corridor-door-end-2026-10-12/DESIGN.md` (v6) and `docs/research-2026-10/art-direction/REAL-LOOK.md` section 8.

## Open issues

- **No hand play.** Whether the walk-out (about 0.45 s), the entry closing and the 3.5 s swing feel right is unverified.
- **USE zone.** "E: secure the first copy." shows anywhere in 772..888, including at the shut door, and the engineer is walked to the container. Separate zones would need the new hint above.
- **The wall's look.** After cleanup the walls are calm, neutral board-formed concrete, like the corridor's. At the entry, the pale wall is brighter than the blue-painted room around it. Nathanial should judge the match from `captures/final/20-entry-0.png` and `21b-at-entry.png`.
- **Occlusion in the doorway.** An engineer who stops in the doorway (x 886-908) is mostly hidden by the exit's near column. This is real occlusion, as at the corridor door, and it lasts only a moment on the way out.
- **Status lamp size.** The lenses are 4x5 world px. They are readable as dots, but small.
- **Container paint.** It came out quite plain after cleanup (calm powder coat). A second paint pass could add more believable wear at the pulls.
- **Asset approval.** The manifest entry is marked as awaiting Nathanial's approval. The docs site and credits were not changed.
