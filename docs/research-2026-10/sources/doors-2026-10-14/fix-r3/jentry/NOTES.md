# Service Junction entry door (doors-r1, fix round 1, review r1 M5)

## Fix round 3 (2026-10-14, review r3 R3-3, human r3): what changed

Tools: `doors-r1/fix-r3/jentry/tools/` (`jemid.py RESTORE_ELBOW`, `jeinstall.py pipes_removed`). No Codex session.
- **The header:** round 2's straight run of header and service line across the cross-wall's face into escutcheons is gone. It exposed the far plate's ceiling lamp 0 between the two pipes as a bare white lens (it has a live glow and shaft, so the far plate cannot change), left a white smear under the run and a hard seam against the plate's flange. The mid plate keeps the room's own elbow, riser and service-line end between the wall's back corner and x 147 (as on main), so the header turns up into its riser at the corner and the lamp stays hidden behind the elbow as on main. The face under the old run and escutcheons takes its own concrete from the same row 40 world px toward the door; right of the corner the wall layer is clear.
- **Measured:** near-white pixels at the header (r09 x 150-300, y 90-230) are 30, as on main (round 2: 315).
- **The leaf:** as Records (door light `JunctionRoom.ENTRY_LEAF_LIGHTS[0]`, exposure 0.147, designed wear). Its grain is lifted more than Records' (`leafwear.JENTRY_GRAIN` 2.2 and 1.9 against 1.5 and 1.0): it draws smaller in the junction's camera and read 0.089 relative texture on render.sh a3 against the 0.12 target. The atlas regions moved 2 px (`ENTRY_*_REGION`).

## Fix round 2 (2026-10-13, review r2): corrections and what changed

**Correction.** The text below says `junction-mid.png` was "cleared left of the column and the stub (the cutaway)", and DOORS.md said the service line passage is painted behind the doorway. In round 1 only 546 pixels of the mid plate changed (plate x 0-25). The doorway and the floor triangle under the wall's foot showed the room's own pipe and tank, and the wall cut the tops off machinery standing in front of it (review r2, N2). The passage behind the doorway also held a painted copy of the shut leaf (N1).

**Round 2** (`doors-r1/fix-r2/jentry/`, session r2-junction-entry):
- **`jemid.py`** erases 208,725 plate pixels: everything under the wall, its doorway and the floor triangle between its foot and the walk line. Deck is re-laid in the triangle (5,570 px) from the plate's own deck 5 m nearer the camera, along the vanishing lines to (511, 162). The guard rail ends on a post (its own right end, mirrored).
- **The pipes:** the header and the service line run on into the wall through steel escutcheons in sleeves. The lengths over the face are the room's own header pixels, from a plain run of it (`jeinstall.py pipes_from_mid`).
- **Painted open with no leaf.** The passage takes detail only where the painting showed it. `ghostcheck.py` passes (it failed round 1 at 0.25).
- **A real batten in the passage.** The leaf's level is `JunctionRoom.ENTRY_LEAF_EXPOSURE` 0.33: 0.81x the wall.

Scratch only. The junction's camera-facing round pressure hatch at x 80 (junction-hatch.png) was the
"door faces the camera, the route runs past it" problem the playthrough named. The engineer comes into the
junction from the service line passage the Records exit opens on, so the junction's left end is now the
same kind of door end as every other door of the base, in the junction's own camera.

- **Model** (`tools/jemodel.py`: `records/tools/rmodel.py` with the junction's vanishing point (511, 162)
  and its back wall at 4.2 m, the far plate's parallax). A 300 mm cast cross-wall turned 17 degrees across
  the walkway, its approach face crossing the walk line at x 30, with a 3'0" x 7'0" hollow-metal steel door
  on three 4-1/2 in hinges at the far jamb (SDI 129) and a surface closer on its junction side; the near
  column with a guarded status lamp; a 0.15 m stub. The design reuses `records/tools/rdesign.py`'s parts
  (`tools/jedesign.py`), with its own pour joint (3.3 m), no pipe plates, its own lamps (the door light, the
  junction's left ceiling lamp, the passage fitting) and its own passage behind (concrete, the service
  line's two pipes and cable ladder running on toward Records, one fitting).
- **Why x 30.** WOLF's authored spot by the entrance (WOLF_CLEAR_X 100) puts his tail at x 33: the shut
  leaf's junction face at x 30 and the near column (x 4.5..15 at 1 m) stay left of him. The engineer's
  collision face is the leaf (x 30), so they stop at x 44; WOLF follows no further left than x 97.
- **Paint and clean-up.** Session fix-junction-entry (two images: the door end, the leaf's faces), the
  records cleanup's method (`tools/jeclean.py`: design colour and light times the paint's detail), graded
  by `../tools/rgrade.py`, packed by `tools/jeinstall.py`: `junction-entry-atlas.png` (549 x 638), the
  passage painted into `junction-far.png` at the left clamp's parallax, `junction-mid.png` cleared left of
  the column and the stub (the cutaway).
- **In the game** (`junction_room.gd` ENTRY_*): one AtlasMesh after the mid plate (wall, leaf with the
  closer's arm, lamp glass, column and stub), a collision body at x 30, the leaf standing open behind the
  arriving pair and closed by its closer over 0.35 s + 3.4 s (amber, then red), as the Records entry's.
  The room's near pipe column at the left edge is no longer drawn (`near_left_edge = false`).
- **Not done:** hands-on play; whether the door reads at the start of the junction needs Nathanial's eye.
