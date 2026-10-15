# Junction exit door: notes (doors-r1, hatch track)

## Fix round 4 (2026-10-14)

- No change to the exit door this round.
- Still open (could, review r4): the orange reflection streaks on the cloned floor wedge with no orange source above it; the wall pack's hard diagonal shadow; roller scuffs on the leaf.

## Fix round 3 (2026-10-14, review r3): what changed

Tools: `doors-r1/fix-r3/hatch/tools/cleanup.py` and `fix-r3/tools/fringecheck.py`. No Codex session.
- **R3-1:** the violet key fringe on the sliding leaf's left and bottom edges (858 atlas px) is gone: in `leaf()`, nothing within 6 design px of the silhouette is kept, near it no magenta-cast pixel counts as paint, and all of them take the nearest kept pixel's colour (as `wall()` already did). `fringecheck.py` fails any door atlas holding a violet pixel; all four pass (round 2's exit atlas fails it).
- **S2:** the room's four pipes are drawn from the model: each a cylinder along the room from the wall's back corner into the face, valued from the room's own pipes beside it (a thin cyan highlight on a dark body), each through a 50 mm steel escutcheon ring 10 mm proud of the face, which projects to an upright ellipse about 0.48x as wide as tall. The old flat band and square collar (which the paint had merged into round knobs) and the paint's halo round them are refilled with the face's own concrete from the same row.
- **Human r3, the floor at the wall's foot:** the floor between the wall's foot and the walk line is the room's own wet deck (the mid plate's deck moved 1.5 m along the room and 4.8 m nearer the camera in the room's camera), in the wall's contact shadow, and kept out of the wall's row gains (which had lifted it to a flat light grey).

## Fix round 2 (2026-10-13, review r2): what changed

Tools and outputs: `doors-r1/fix-r2/hatch/` (design at `design/v8`). Session r2-junction-exit.
- **N3:** the cross-wall face that sees the junction's corner fitting is lit with it. In the reviewer's own j08 boxes it reads 0.41-0.71x the back wall beside it (it was 0.011-0.075x). Graded by `grade2.py` from inside `cleanup.py` (linear, at the corner, closed on render.sh frames). The leaf sits at 0.69x the wall.
- **S7:** the wall pack is a forward-throw fitting. Its front glass is lit, and its pool falls on the leaf, the threshold and the deck.
- **Look:** form-panel joints and tie cones; the room's four back-wall pipes pass through the wall at its corner in collars. The passage fitting is twice as bright.
- **Station:** the bolt panel moved from x 806 to 796, with its riser in the back layer. The design rect now starts at x 826.

## Fix round 1 (2026-10-13, review r1): what changed and where the record now lives

Tools and outputs: `doors-r1/fix-r1/hatch/` (design at `design/v7`, a changed copy of the tools).
- **One camera (C1):** `geom.py` uses the junction's own vanishing point (511, 162), as the blast door does;
  `JunctionRoom.exit_leaf_anchor` and the tests follow.
- **Column and stub (S4):** the wall ends 0.16 m past the near jamb's trim in a column (its 0.66 m end face
  with steel arris angles) and is cut to a 0.15 m stub across the deck, its cut going down the fascia; the
  passage shows beyond it in the cutaway.
- **Soft shadows (S3):** the ceiling batten is sampled 13 x 3 and the wall pack 9 x 2, so the small boxes'
  shadows are soft smudges.
- **Deck (M4):** the mirrored `exit_deck` is replaced by an atlas piece (`hinstall.py`): the mid plate
  translated 2.0 m along the room in its camera (x 956 to 1032), feathered over 8 px.
- **Values (M1):** designed wear (`design.py` `concrete_wear`), re-painted (session fix-junction-exit),
  graded in `cleanup.py` `grade_room` to 0.70x the junction's back wall at the same height.
- `install.py` is not used: it rewrote junction_room.gd from a template; `hinstall.py` packs the atlas and
  the game's EXIT_* constants are set from `placement.json`.


Scratch only. Nothing here touches the Git repository. The base is main exported at 9c7371d. The patch also applies cleanly to main at db9df1d, which only adds docs and `scripts/parity/` and leaves `apps/game` unchanged. Nothing was played by hand, so there are no feel claims. What was checked: the headless tests (all 15 pass) and rendered stills from `tools/render/render.sh` (container, software GL).

## What it is now

The Service Junction's exit is now a power-operated sliding steel door. It sits in a cast-concrete cross-wall at the room's right end and follows the corridor door end's design language (REAL-LOOK section 8): the same wall, turned 17 degrees across the walk line, the same camera, the same gunship-grey steel, the same single yellow and the same live red/amber/green status lamp. The approach face crosses the walk line at x 962, so the route runs through the doorway. The engineer and WOLF walk in through the opening and pass behind the near jamb.

| Part | Real model | Size and placement |
|---|---|---|
| Cross-wall | Cast concrete, 0.66 m (the corridor's), one horizontal pour joint at 3.6 m | Turned 17 degrees; meets the junction's back wall (4.2 m deep) at screen x 868 |
| Opening | Steel channel frame cast into the wall | 2.0 m clear by 2.4 m (the 1.75 m engineer is 73 % of it). Far jamb x 925.5, near jamb x 971.6 at the floor |
| Leaf | Welded steel plate, 120 mm thick, two horizontal seams. Bottom rollers in a slot in the steel sill (UFGS 08 13 73 2.9.7). The leading edge has a black rubber edge on diagonal yellow/black caught-between striping (29 CFR 1910.144(a)(3)) | 2.15 x 2.47 m. It runs in the wall's middle (n 0.27..0.39 m) and seats 0.1 m into the near jamb's rebate. It slides 2.12 m back along the wall into a **pocket in the far jamb**, stopping 20 mm inside the mouth. The striped edge stays visible in the mouth when open. It never fades. |
| Exit bolt | Electric locking bolt in a steel housing over the head, dropping into a keeper on the leaf's top edge (latching at the head: UFGS 08 39 54 2.2.2; electric solenoid lock: UFGS 08 13 73 2.9.4) | Housing 0.34 x 0.17 x 0.28 m over the head, fed by 25 mm rigid conduit along the head line with strap clamps |
| Status lamp | Guarded globe on a back box left of the opening. Its glass is the live sprite: red, amber, green in the bolt's colour (as `_bolt_light_color()`) | Its conduit runs straight down into the floor, with three straps |
| Wall pack | Vapour-tight LED bulkhead over the door, on a short conduit up from the bolt run | 0.5 x 0.2 m at 3.05 m. It lights the leaf's lower face and the threshold (painted in) |
| Passage beyond | Plain concrete service passage, its own vapour-tight fitting on its back wall at 2.05 m | Painted behind the hole: the only thing seen through the doorway |
| Floor wedge | The junction's floor between the walk line and the wall's foot, with a contact shadow along the foot | The room's painting has no floor behind the walk line, so without this the wall would stand on nothing |
| Riser | Continuation of the bolt panel's right-hand riser: up to a cap, and down to a floor flange | It used to end in mid-air behind the old hatch |

Light: two visible sources are ray-cast: the junction's right ceiling fitting, which is painted on the far plate, and the passage fitting. The wall pack adds a third. All light is painted in; nothing new is live except the lamp's glass tint. Values are graded to the approved corridor door end's wall as it shows in the game (median about 34 to 36 sRGB) in the junction's cold light. Measured on the cleaned layers, the median luminance is 36 by construction.

Method (the corridor's):

1. Measured parts and camera in Python: `tools/geom.py`, `design.py`, `leaf.py` and `noleaf.py` (round 1's `junction-exit/tools/geom.py` at dee9996 and `junction-exit/tools/design.py` at dee9996; `tools/` now holds fix round 3's, see the Files list). There is one mask per part (`design/v6/masks/`) and `design/v6/spec.json`.
2. `compose.py` builds the edit targets (round 1's: `junction-exit/tools/compose.py` at dee9996).
3. Codex's built-in image tool in edit mode painted material and light only. There were two jobs, `hatch-wall` and `hatch-leaf`; their outputs are kept byte for byte with C2PA (caBX). See `../provenance.txt` and `../codex/hatch-*/`. Both sessions are archived.
4. `tools/cleanup.py` (round 1's: `junction-exit/tools/cleanup.py` at dee9996) registers each paint to its target. Wall edge NCC is 0.85, with 99.7 % of strong design edges recalled. It then re-imposes every design mask, removes the key's magenta feather, calms the concrete as one surface, clamps each part's value to the design (within 10 to 15 %), grades and tints the result, and adds the floor wedge.
5. `tools/install.py` packs one lossless atlas and writes `placement.json`. `tools/manifest.py` writes the manifest.

## The ending as specified and built

1. The bolt arcs; the leaf slides into its pocket over `HATCH_OPEN_SECONDS` (0.5 s, unchanged); the lamp goes green.
2. Once it is open, WOLF steps into the doorway (`WOLF_DOORWAY_X` 985) and waits looking back at the engineer. His head and shoulders are in view; the rest of him is already behind the near jamb.
3. At the bolt panel the hint is the existing line "The hatch is open. Leave through it." USE there does nothing.
4. The engineer walks up to the door: `HATCH_REACH_MIN_X` 870, stopping at `HATCH_REACH_MAX_X` 901, behind WOLF's head. Only there does the hint say "E: leave through the hatch." and USE leave.
5. The closing beat plays as before. Its camera now frames the whole doorway: zoom 1.45, view x 341..1000. The left edge is the same as before, so no label is cut.
6. On Continue, WOLF turns and walks on through the doorway until the near jamb hides all of him (x 1041.6, then on to 1100). Only then does the engineer walk through after him, until the jamb hides them (x 991.6). Nobody fades. Both walk at 0.55 of the follow speed, so the leaving is seen.
7. The doorway stands empty for 0.4 s, then the END OF SLICE card. Tests check that the card never comes before both are through, and that the visible parts of the two bodies never overlap.

Rendered stills of all of this are in `review/` and `captures/b4/`. Before frames are from main, captured with the same driver (`captures/main-perf/`).

## Files

- `junction-exit-door.patch`: the exact change as a `git diff --binary` against the export (`git apply --binary`). It touches:
  - **Scripts:** `scripts/junction_room.gd`, `scripts/main.gd`, `scripts/m0_actor.gd`.
  - **Tests:** `tests/sentry_test.gd`, `room_depth_test.gd`, `room_lights_test.gd`, `debug_tools_test.gd`.
  - **Assets:** `assets/manifest.json`, plus the new `assets/props/junction-exit-atlas.png` with its `.import` (lossless, mipmaps, as the corridor's atlas).
  - **Deleted:** `assets/props/corridor-bulkhead-open.png` and its `.import`, and `art-source/doors/corridor-open.png`. The old exit passage was their only use; both remain in the Git history.
  - **Repo root:** `scripts/prepare_bulkheads.py`, with the corridor family removed.
- `placement.json`: the atlas's regions, each piece's world top-left and the leaf's anchor.
- `layers/`: `beyond`, `back`, `lens`, `front` and `leaf` PNGs at 2 px per world px, `junction-exit-atlas.png` (sha256 07e4d56b...), `cleanup.json` (registration and fidelity numbers), and the review composites.
- `design/v6/`: the construction. It holds `spec.json`, the masks, the per-state renders and the Codex targets in `compose/`.
- `tools/`: `geom.py`, `design.py`, `leaf.py`, `noleaf.py`, `compose.py`, `imgkit.py`, `cleanup.py`, `install.py`, `manifest.py`, `run_codex.sh`. Filed in `junction-exit/tools/`, which now holds fix round 3's versions (`../README.md`, "Tool map"; `hinstall.py` from fix round 1 on); round 1's `geom.py`, `design.py`, `compose.py` and `cleanup.py` are `junction-exit/tools/geom.py` at dee9996, `junction-exit/tools/design.py` at dee9996, `junction-exit/tools/compose.py` at dee9996 and `junction-exit/tools/cleanup.py` at dee9996; `leaf.py`, `noleaf.py`, `install.py` and `manifest.py` are unchanged since. The Codex runner is `junction-exit/tools/run_codex.sh` at dee9996 (the doors' one Codex runner is now `../tools/run_codex.sh`).
- `templates/junction_room.gd.tmpl`: the script with placement placeholders that `install.py` fills.
- `driver/hatch_capture.gd`: the render.sh capture driver.
- `captures/` (b1..b4, main-perf, b2-perf) and `review/1..5-*.png`: the before/after and sequence sheets.
- `research/`: UFGS 08 13 73 and 08 39 54 (text and PDF).
- `testlogs/`: the headless test logs.

## Integration

1. Apply `junction-exit-door.patch` at the repo root with `git apply --binary`. Then run `godot --headless --import` and the 15 tests.
2. Copy this folder's record into `docs/research-2026-10/sources/junction-exit-door-2026-10-13/`. That is the path the manifest entry and the script comment name. Include:
   - `NOTES.md`, `placement.json`, `design/v6/spec.json` and the masks;
   - `tools/`;
   - the two Codex job folders from `../codex/hatch-wall` and `../codex/hatch-leaf` (prompt, refs, out with C2PA);
   - the hatch part of `../provenance.txt`;
   - `review/`.

   Leave out the large `.npy` caches, which can be rebuilt with `design.py` and `noleaf.py`.
3. **Expect conflicts with the junction blast-door track.** Both tracks change `junction_room.gd`, `manifest.json`, `prepare_bulkheads.py`, and possibly `debug_tools_test.gd` and `room_depth_test.gd`. The exit door touches only the `EXIT_*` and `HATCH_*` parts, `_build_exit`, `_sync_hatch`, `_sync_exit_lamp`, the `near_right_edge = false` line and the removed `HatchDoorway`. Merge by hand; nothing in the blast door's code is changed here.
4. The website changelog and walkthrough need a line. A draft is below, for approval.

## Route changes (x positions)

| Constant | Before | After | Why |
|---|---|---|---|
| `JunctionRoom.HATCH_X` | 880 | removed | The exit is now the door in the cross-wall. Its approach face crosses the walk line at `EXIT_DOOR_X` 962; near jamb `EXIT_NEAR_JAMB_X` 971.6 |
| Where USE leaves | anywhere from `BOLT_REACH_MIN_X` (~741) once open | from `HATCH_REACH_MIN_X` 870 | The leave prompt shows only at the door |
| Engineer walk limit | `M0Actor.MAX_X` 920 | 901 (`HATCH_REACH_MAX_X`) while the door is open | Behind WOLF in the doorway |
| WOLF after the door opens | stays at `WOLF_DOWN_X` 902 | `WOLF_DOORWAY_X` 985 | Waits in the doorway |
| Walk-out targets | engineer 886, WOLF 902, both fading | engineer 991.6 (`HUMAN_GONE_X`), WOLF 1041.6 then 1100 (`WOLF_GONE_X`, `EXIT_WALK_MAX_X`), no fade | They walk through |
| Play camera right edge | 960 | 1000 once the bolt is open | Shows the whole doorway |
| Junction close camera | x 650.3, zoom 1.55 | x 670.3, zoom 1.45 | Right edge 1000, same left edge |

Unchanged:
- `BOLT_PANEL_X`, `BOLT_X`, `BOLT_REACH_MIN_X`, `WOLF_DOWN_X` and `WOLF_BAIT_X`;
- the sentry lane, `HATCH_OPEN_SECONDS`, every beat, every choice and all text;
- the save format. Saves clamp x to 40..920 as before, so a body standing in the doorway saves at 920.

Changed in timing:
- The walk-out now takes about 2 s instead of about 1.6 s, because they walk through instead of fading.
- `room_lights_test` and `sentry_test` waited about 2 s for the card. They now wait up to 7 s.

## Performance (render.sh, same driver, same frames)

| | Draw calls p50 | Objects | Additive | Texture memory |
|---|---|---|---|---|
| main, shut | 98 | 283 | 9 | 73.37 MB |
| patched, shut | 97 | 282 | 9 | 74.41 MB (+1.04) |
| main, open and close | 103 / 92 | 267 / 282 | 9 | 78.05 MB |
| patched, open and close | 95 / 87 | 258 / 278 | 9 | 74.41 MB (−3.6) |

The atlas is 719 x 643 RGBA, about 1.85 MB, or about 2.5 MB with mipmaps. It replaces the 1.27 MB passage image, the `HatchDoorway` clip node and its gradient. There are no new full-screen layers and no new additive items. The right near-strip pipe column is no longer drawn, because the cross-wall is the room's right end now. Software GL timings say nothing about real frame times.

## Tests

All 15 headless suites pass on the patched copy. The new and changed checks cover:

- WOLF steps into the doorway and looks back.
- USE at the panel does not leave.
- The engineer stops behind WOLF.
- The hint at the door.
- WOLF goes through first, is seen mid-walk, and nobody fades.
- The card comes only after both are behind the jamb.
- The door's pieces come from one atlas, in draw order.
- The leaf stands on the sill shut, slides left into the pocket, and is still there open.

`sentry_test` failed once out of four runs under parallel load, on an existing 1 px check of WOLF's leap over the engineer. It passed twice in a row alone and on main. This looks like a timing flake, not this change.

## Text for Nathanial (drafts only, not shipped)

- **USE at the bolt panel once the door is open.** It now does nothing; the hint already reads "The hatch is open. Leave through it." If a line is wanted, a possible draft: "The door's open. Walk up to it."
- **The lines still say "hatch".** "The hatch slides open." and "E: leave through the hatch." still say hatch for what is now a sliding door. A possible draft: "The bolt arcs and drops. The door slides back into the wall."
- **Website changelog.** A possible draft: "The Service Junction's exit is now a sliding steel door in a concrete wall: when the bolt pops, its leaf runs back into a pocket in the wall, WOLF steps into the doorway and waits, and the two walk out through it, one after the other, before the END OF SLICE card. Checked by automated tests and still images only."

## Open issues

- **Screen size and position.** The exit sits at the room's right edge and is small on screen: the opening is about 46 px wide at play, because the wall is nearly edge-on. This is the corridor's approved language, but it is far less prominent than the old full-face hatch. Whether it reads in play has not been checked by hand. The wall cannot move left without moving WOLF's bait spot (x 902, body to 969), which is gameplay.
- **Speed.** The leaf travels 2.12 m in 0.5 s, about 4 m/s. Real power-operated sliding doors move at roughly 0.3 to 0.6 m/s. This is kept because timings stay, but 2 to 3 s would look real. It needs Nathanial's call.
- **The bolt does not visibly drop.** The housing is drawn but nothing moves. The play research (drafts N21) asks for this; it needs a small extra piece and a decision about what the bolt physically does.
- **No sign on the door.** There is no stencil or number (the corridor has SECTOR 4B and DOOR 4B-07). A typeset stencil, never painted, could follow once its text is approved.
- **Mid-slide stills are forced.** The frames at 0.35 and 0.7 are taken by setting the state directly. The real 0.5 s slide was not captured frame by frame, because software rendering runs behind physics.
- **WOLF's facing in the doorway.** He looks back at the engineer, which shows his head. The alternative (facing on, showing his tail) read worse in stills.
- **Floor reflections.** Behind the wall they are hidden by a mirrored cut of the mid plate's deck (`exit_deck`).
- **The END OF SLICE fallback.** `_wait_until_through` gives up after 3 s so a blocked walk can never hold the card back.

## Sources

- **UFGS 08 13 73, Sliding Metal Doors (USACE/NAVFAC/AFCEC, August 2025).** Bottom-supported doors on floor track with top guides (2.4.1), bottom rollers (2.9.7), the leading-edge safety device (2.8) and the electric solenoid lock option (2.9.4). https://www.wbdg.org/ffc/dod/unified-facilities-guide-specifications-ufgs/ufgs-08-13-73 (copy in `research/ufgs-081373/`).
- **UFGS 08 39 54, Blast Resistant Doors (August 2009).** Latching points and the latching system at the head and strike (2.2.2), the removable threshold (2.3.3) and the subframe. https://www.wbdg.org/ffc/dod/unified-facilities-guide-specifications-ufgs/ufgs-08-39-54 (copy in `research/ufgs-083954/`).
- **29 CFR 1910.144(a)(3), OSHA safety colour code.** Yellow for caution, marking striking-against and caught-in-between hazards: the leaf's leading edge.
- **FED-STD-595 colour chips, per REAL-LOOK section 8:**
  - 36231 for the concrete;
  - 36118 Gunship Gray for the frame and leaf;
  - 36081 for the housings;
  - 33538 for the yellow.
- **Design language and method.** `docs/research-2026-10/sources/corridor-door-end-2026-10-12/` (DESIGN.md v6, tools, spec), approved by Nathanial on 2026-10-12, and `docs/research-2026-10/art-direction/REAL-LOOK.md`.
