# Shutter door art review (independent, 2026-10-11)

This is a scratch review. It made no paintings, made no Git writes, imported nothing into Godot and played nothing. Every judgement comes from the painter's paste-up composites, three extra probe paste-ups I made with the painter's own `tools/compose.py` (`review/probe-*.png`), and measurements on the layers. None of it is a game render or hands-on play, so this file makes no claims about feel.

**Verdict: fix needed.** The art direction matches the approved shutter, and the open and blown states read well. But three of the five portals can be walked through while shut, and the corridor's closed leaf does not read as blocking the engineer where the collision stops him. Fixes 1-4 are required before integration. Fixes 5-9 are smaller.

## What passes

- **The doors read as doors.** Every sealed state reads as a heavy slatted shutter in a floor-to-ceiling portal. It has a roll-drum or bolted header, guide rails, a hazard bottom bar and a caged lamp. None of them reads as a pillar or a freestanding frame.
  - The headers reach the top of the gameplay view (canvas tops 118-150, view top 160) and meet the ceiling pipe run.
- **Open and blown states:**
  - **Records open** (`records-exit-03`, `-04`): a long lit maintenance passage, clearly a new place.
  - **Exit hatch open** (`junction-exit-hatch-05`, `-06`): a rail tunnel, clearly a new place.
  - **Opening at 0.5** (`corridor-seal-02`, `records-exit-02`, `junction-exit-hatch-04`): reads as rolling up into the header.
  - **Junction breaking:** reads as about to burst.
  - **Junction blown:** a clear floor-level gap with torn slats hanging from the header.
- **No old door is visible.** No old bulkhead, hatch, borrowed passage or `_draw_exit()` rectangle shows in any composite. The plate fixes worked:
  - corridor column pair and machine: gone
  - records machine: gone
  - junction pipe stack: replaced by a clean elbow
  - entry boiler cluster: gone
  - exit truss: gone

  I checked the patched `junction-mid.png` against the original directly, outside the composites.
- **Geometry against MEASURE.md:**
  - Each collision face sits inside its opening: corridor 752-808 in 732.75-810.5, junction 452-508 in gap 443.25-513.
  - The walk-out at 886 is inside the exit opening (862-926.5).
  - The records USE point at 830 is inside its opening (812-891).
  - The blown gap's median clear height is 212, against a 72 px engineer.
  - Floors sit at y 440. The front layers start at the near jamb and fade over actors (`corridor-seal-05`).
  - Blast zone 360-540, rubble line 540 and save check 452 are untouched.
- **Density:** D = 4 on every door layer. `qa_asset.py` E_density gives 1.48 at 1080p gameplay and 2.96 at 960.
- **Values:** sealed doors have median L* 18.0-18.6, inside the 12-22 door band. Cool neutrals pass (b* -7 to -9). Noise and hf pass.
- **Alpha:** I inspected edges at 3x over black and over grey (`review/edges-review.png`).
  - Over grey there is no matte, black fringe or magenta. The halo flags are the requested cyan rim.
  - Bodies are at alpha 1.0. The blown torn edges carry ember tips, which are intended.
- **C2PA:** all 23 raw outputs in `codex/*/out/` contain a `caBX` chunk. I parsed the PNG chunks myself: IHDR, caBX, IDAT, IEND, with no stripping.
  - The SHA-256 prefixes match `provenance.txt`.
  - All 15 session ids are recorded, and `work/archive.log` shows each one archived.

## Required fixes

### 1. Three shut portals can be walked through

Only the corridor and the junction blast door have a body. Actors are clamped only to `M0Actor.MIN_X`/`MAX_X` = 40..920. Before, these doors were hatches on the back wall, so walking past them was fine. Now they are shutters across the walkway.

| Portal | Shut leaf (world x) | Where an actor can still go | Proof |
|---|---|---|---|
| Records exit (sealed) | 812-891 | to x 920: through the leaf and behind the near column | `review/probe-records-engineer-at-920.png` |
| Junction exit hatch (bolted, bolt live, charging) | 862-926.5 | to x 920, across the shut leaf | |
| Junction entry hatch (always shut) | 33.5-98 | to x 40, across the leaf | |

**Fix** (each value checked against the reach numbers in MEASURE.md):
- **Records:** a blocking face at x 812 while `_exit_open` is false, so the engineer's centre stops at 798. The USE window `|x-830| ≤ 58` still covers 798. Remove the face when the leaf has lifted.
- **Exit hatch:** a face at x 862 until `hatch_open` reaches 1, so the engineer stops at 848. The bolt reach starts at `BOLT_REACH_MIN_X` 790, so the bolt stays usable. Remove the face for the walk-out to 886 (WOLF to 856).
- **Entry hatch:** a fixed face at x 98, so the engineer's minimum is 112 and WOLF's is 129. The spawn at 120 and WOLF at 208 still work, and nothing interactive lies left of 160.
- **Both actors:** apply the same limits to WOLF's `follow_min_x`/`follow_max_x` in those states.
- **Tests:** add tests for these three bounds.

### 2. Corridor: the sealed leaf is face-on, so the stop looks like an invisible wall

- The leaf's bottom bar is level, and its opening top slopes only 3 px (215.25 to 218).
- The body face at 752 is 19 world px inside the leaf's left edge (732.75). At the stop, the engineer's sprite (714-762) covers the far column and the leaf's left quarter.
- In `review/probe-corridor-engineer-at-face.png` he looks like he is standing in front of a roller door set in the back wall, stopped by nothing. That is the reading Nathanial rejected before.
- The approved concept skews the face in a clear three-quarter view: the bottom chevron edge drops about 35 px across a 100 px face in `compare.png`.
- The junction blast door (`review/probe-junction-engineer-at-face.png`) overlaps by only 9 px against a strong column, so it passes. It would still gain from the same skew.

**Fix (preferred, keeps every code number):** a Codex edit-mode repaint of `corridor-seal` sealed/leaf/opening-mask/leaf-stowed with a real three-quarter skew.
- The hazard bottom edge runs from the far jamb at about y 434 (x 733) to the near jamb at about y 447 (x 810), crossing the walk line y 440 near x 752.
- The slats follow that perspective.
- The far column base sits at about y 434 and the near column base at about y 447.
- Rebuild `records-exit` and `junction-exit-hatch`, which share the design, the same way.

**Fallback (code only):**
- Move `CORRIDOR_DOOR_LEFT_X` and the body face to 733. The bypass crank at 674 still fits (engineer right edge 688).
- WOLF's `follow_max_x` becomes 666.
- Update `m0_scene_test` 222-237 and `follow_spacing_test`.

### 3. The space through the portal is not the space you walk into (corridor, junction)

**Corridor:**
- The open portal shows a tall machinery chamber.
- The plate right of the portal (x 842-960, with the safe point) is the same blue corridor wall.
- So the engineer walks through the door into the corridor he just left (`corridor-seal-05`).

**Junction:**
- The blown gap shows a warm switchgear hall with lockers.
- Past the door is the same cool pipe bay with TANK RELEASE and the sentry.

The approved concept puts the different space to the right of the portal as well. Its prompt says "rightmost 17% gives a glimpse ... of a genuinely different next space". Records and the exit hatch do not have this problem, because they cut to a new room.

**Decision for Nathanial:**
- **(a) Matches the approval.** Repaint the plate right of each portal as the beyond space:
  - corridor: mid and far plates for x 842-960, a machinery chamber with the safe point standing in it
  - junction: x 546-960, a switchgear hall. This is large: it re-themes the second half of the junction, its props and its light.
- **(b) Cheaper.** Repaint each beyond layer as a deeper view of the room that is actually to the right:
  - corridor: the blue wall and the safe-point niche
  - junction: the cool pipe bay and the hanging tank rig

  This gives up the "different space" from the concept.

**Recommendation:** (a) for the corridor, which is small and fits the room-expansion plan. Choose (a) or (b) for the junction. This also settles the junction beyond's accent fail (item 8).

### 4. The exit hatch's state lamp is hidden at the camera's right clamp

- The near pipe (parallax 1.15) covers the lamp at (939.25, 293.25).
- As a result `junction-exit-hatch-01`, `-02` and `-03` (red, amber, white) look the same. The finale's state signal is lost.

**Fix:** add a second lamp sprite (or a strip on the header lip) centred on the hatch header, at about (894, 188).
- It sits in view (view top 160, opening top 197) and clear of the near pipe.
- Drive it with the same `_bolt_light_color()`.

## Smaller fixes

5. **MANUAL BYPASS label.** Its panel runs under the corridor portal's far column (x 716-733) in every corridor shot. Move its anchor left so the panel ends at x ≤ 712, or give it a narrower panel.
6. **Debug overlay coverage.** Nathanial asked for hitboxes and render boxes. The `-boxes` twins draw only some of them.
   - **Drawn:** hitboxes (red), disabled hitboxes (grey dashed), Area2D (orange), door render boxes (cyan with z), front layer (magenta), lamps, openings and the floor.
   - **Not drawn:** actor and prop render boxes. The capture JSON has them (MEASURE's annotator drew them in yellow; `compose.py` does not).
   - **Unreadable names:** hazards show as `@Node2D@111`.
   - **For the real in-game overlay** (still not built), draw:
     - every CollisionShape2D (enabled or not) and every Area2D
     - every Sprite2D render rect with its z
     - the door openings and the new blocking faces from fix 1
     - the floor line

     Use node names.
7. **The junction composites have paste-up artifacts, not asset defects.** `plate_fix()` in `compose.py` swapped plate pixels onto the props in front of them. The result is speckle on the breaker and the "OVERLOAD BREAKER" label, plus a faint dashed remnant of the erased hazard rail at screen y ≈ 423, x 160-275, in every junction shot. The patched plate itself is clean. Judge that corner again only in a Godot render after integration.
8. **QA flags for the bible owner:**
   - Hazard yellow is not in the accent swatches but the approved design needs it. Add a hazard-yellow swatch.
   - `junction-blast-beyond` fails F_accent_dE_p90 (20.6, against 18) because of its warm lights. This is intended under option 3a and should be regraded cool under 3b.
   - The beyond layers fail C_top_light. They are interiors seen through an opening, so the check does not apply.
9. **Optional polish:** the blown door's scorch decals barely show at 1280x720. Raise the scorch alpha (now 0.6 for the wall decal) so the blast reads after the smoke clears.

## No action needed

- **Exit-truss erase.** 741 erased plate px are not covered by the hatch layers. They lie at y 122-130 and at x ≈ 954.5, which is above the gameplay view top (160) or under the near pipe.
- **Intro containment gate.** It is code-drawn, it is an intro cage rather than a corridor door, and MEASURE left it out of scope. If "delete all old assets" is meant to include it, that needs Nathanial's call.
- **Blast door upper half.** Its flat transom plate above the six segments still reads as a heavy shutter.

## Files

- Probes: `review/probe-corridor-engineer-at-face.png`, `review/probe-junction-engineer-at-face.png`, `review/probe-records-engineer-at-920.png`, each with a `-boxes` twin. They show the engineer moved to the stop point or the clamp, with WOLF hidden. Their hitbox overlay shows the captured positions, not the moved sprite.
- Edge sheet: `review/edges-review.png`.
- Sealed layer row: `review/sealed-row.png`.
- Plate before and after: `review/jmid-entry.png`, `review/jmid-stack.png`, `review/jmid-exit.png`.
- Scripts: `review/py/cover.py`, `review/py/unc.py` (plate-erase coverage), `review/py/probe.py`, `review/py/chunks.py` (C2PA chunk parse).
