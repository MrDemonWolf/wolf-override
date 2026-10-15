# Service Junction blast door (doors-r1, junction track)

## Fix round 4 (2026-10-14, review r4 C2, human r4): what changed

- **The blast leaf is thrown, not swapped.** After the 0.15 s break, the torn leaf flies 0.24 s (`DOOR_FLIGHT_SECONDS`) from its doorway to where it lies:
  - it is carried along the lane, rises 18 world px and falls;
  - it tips about 86 degrees toward flat and grows 1.22x as it comes nearer the camera;
  - it draws in front of the near column once it is 30 % along;
  - it lands with a low dust burst off the wet deck (`landing_dust`, 18 particles).
- **Code only, no asset change.** `door_route_test` now requires the leaf to be seen in the air past the near jamb.
- **Not done (could):** the exit wedge's orange streaks, the wall pack's hard shadow, the dash scuffs and granite-like kick plate, roller scuffs, the column blotches, the hairline cracks and darker puffs.

## Fix round 3 (2026-10-14, review r3): what changed

Tools: `doors-r1/fix-r3/junction/tools/` (`jgrade2.py`, `lying3.py`, `install.py`) and `fix-r3/tools/threshcheck.py`. No Codex session.
- **S1:** the threshold plate is set to the deck's value as it reads beside it on screen (0.0265 linear target, `threshcheck.py`), its 12 mm nose a dull edge 1.35x that.
- **S4:** the fresh damage reads lighter than the weathered face: spall faces at 2x and their arrises and torn steel (keepers, tabs, liner, the column's torn hinge leaves) at 2.6x the weathered face (the wall's 0.0082, the column end's 0.0197); soot and open cracks unchanged. Torn steel that was already lighter keeps its value.
- **S3 and human r3, the thrown leaf (`lying3.py`):** dished 0.16 m from jdesign's own leaf geometry (it rests on its middle and on the chunk under its right end; its left end stands 0.17 m off the deck, shading the deck under it); 16 world px further along the lane (0.4 m), so it no longer lies across the wall's stub; its landing corner on the chunk crushed in a ragged 0.10-0.14 m chamfer with a bright torn edge; scrapes along its slide on the near edge and the up face's leading end (kept off the hardware); soot by its latch edge. The painted pixels move by the exact height change, so nothing is repainted.
- **Atlas:** `install.py` now packs with a skyline packer; the atlas shrinks from 1024 x 928 to 1024 x 656.

## Fix round 2 (2026-10-13, review r2): what changed

Tools and outputs: `doors-r1/fix-r2/junction/` (`jdesign.py`, `codex_inputs.py`, `cleanup.py`, `jgrade2.py`, `install.py`). Sessions r2-junction-sealed and r2-junction-blown.
- **S3:** three full-surface hinges on the hinge jamb (UFGS 08 39 54 2.2.1), frame leaves on the jamb, door leaves on the leaf, five 60 mm knuckles each.
- **S4:** the threshold at the deck's value, with a dull steel edge (nobody crosses a sealed door).
- **N4:** the readable damage moved to 0.3-2.0 m, below the DOOR DOWN plate:
  - on the near column (`column_damage_parts`): torn hinges with sheared pins, the hinge-jamb corner spalled 60-80 mm down to its bars, cracks, and the arris angle torn loose and bowed 120 mm;
  - in the opening: the latch face plate torn off above 1.0 m and bent into the opening with two sheared keeper lugs;
  - the lane behind the doorway in the wall's shade.
  - The blown column is its own atlas region (`COLBLOWN`). The same DoorColumn sprite switches to it once blown, so there is no new draw call. Its lamp, junction box, feed and riser are the sealed column's own pixels.
  - In j04 the DOOR DOWN plate covers 8.6 % of the damage piece's rectangle and 4.7 % of the column's, and none of the 0.3-2.0 m band.
- **S5:** the near column's even flecks are calmed (median blend) and its detail is lifted less.
- **The batten over the door:** its body, caps and brackets read; its lens dims with the wall; a soft pool sits round it.
- **N3:** `jgrade2.py` (`grade2.py`). The wall reads 0.69-0.81x the back wall at the corner, the leaf 0.72x the wall.
- **The thrown leaf:** the hinges' door leaves stay on it, and it keeps the wall's gain (it lies face up under the ceiling lights).

## Fix round 1 (2026-10-13, review r1): what changed and where the record now lives

The fix round's tools and outputs are in `doors-r1/fix-r1/junction/` (a copy of this folder's tools,
changed); this section corrects the claims below that the round-1 art did not show.
- **Thrown leaf (M2).** Re-modelled (`jdesign.py` `lying_parts`, `ly_point`): approach face up, its hinge
  edge toward the camera with three torn knuckles, sheared pins and their hinge leaves; bowed 0.09 m and
  dished 0.04 m; its far edge and right end on jamb chunks (about 6.5 and 3.5 degrees); three bent bolts
  out of the latch edge; thrown straight out from the wall (yaw 17 degrees), at least 14 world px clear of
  the stub; its far edge stays below the actors' feet. Re-painted (session fix-junction-blown).
- **Blown doorway (M3).** A spall bite deepest at the latch jamb and over the head (0.85 m along the face,
  so it reads after the 17-degree foreshortening), 25 mm bars drawn 1 world px, four bar ends bent out and
  two hanging from the head, cracks from both head corners, the 300 mm latch face plate torn out 0.45 m, the
  head sagging 0.11 m, the far reveal's liner sooted and buckled with torn keeper pockets. Re-painted.
- **Frame and threshold (C2):** a 300 mm latch face plate; the threshold plate 0.75 m with a bright nosing.
- **Charge line (S2):** the valve's outlet (its painted 0.36 m pipe end, h 0.545) carries on through a mating
  flange, a 350 x 150 reducer, a spool, an elbow, a 1 m run behind the valve's base and an elbow up into the
  riser (now drawn as a 150 mm cylinder), which turns into the wall through a collar on the penetration plate.
- **Cut section (S9):** the stub's end is the wall's cut, carried down the deck's fascia to y 580 with steel
  trim angles; the stub end plate is gone.
- **Values (M1):** wear designed into the concrete (`concrete_wear`); the paint keeps 90 % of its grain;
  `jgrade.py` (with `../tools/grade.py`) sets the concrete row by row at 0.70x the junction's back wall,
  keeps the light pools and lifts the paint's own fine grain; the bay at 0.75x. The round-1 upper-wall
  fall-off in `install.py` is replaced by it. The atlas is packed to its used height (1024 x 888).
- **Effects (S7):** the blast's sparks are hard streaks, its debris hard tumbling chips, its dust a jet
  through the doorway (`FxPresets.streaks`, `chips`, `dust_jet`), within the same particle counts.


This is scratch work, kept out of the repository. It was built from main 9c7371d (`origin/main`, exported
into `doors-r1/main-junction/`) and follows the corridor door end's method and design language
(`docs/research-2026-10/sources/corridor-door-end-2026-10-12/`, REAL-LOOK.md section 8). Nothing was
played by hand. The evidence is headless tests and render.sh stills. No claims are made about how it
feels to play.

## What it is

The junction's SEALED DOOR is now a real blast door set in a cross-wall that stands **across the
walkway**. The walkway is blocked before the blast. After it, the engineer and WOLF walk **through**
the blown opening into the lane.

- **Wall.** The cross-wall is cast reinforced concrete, 0.40 m thick. It runs from the back wall
  (screen x about 420, behind the valve) to a near column at x about 494, plus a 0.15 m stub across
  the deck. Its approach face is turned 17 degrees to the camera, the corridor's angle, so all doors
  read as one facility.
- **Leaf.** One hinged steel leaf, concrete-filled: 2.3 x 2.6 m clear and 0.30 m thick. It sits in a
  steel channel frame with a 0.18 m flange.
  - It is hung and locked from the lane side, so it reads as sealed from the other side.
  - The approach face shows only the plain leaf, two capped lever spindles (that side's levers are
    removed), the frame, the door light over the head, and the charge line's welded penetration plate.
- **Status lamp.** A guarded lamp on the column's end face, tinted live:
  - red when shut
  - amber while the line builds
  - flashing red and white through the fuse (steady red with Reduced Motion)
  - dark once the door is down
- **Breaking** (0.15 s, under the existing flash). The latch edge is pulled 0.12 m into the lane, the
  face bows, three 50 mm locking bolts bend across the gap, and cracks run from the frame corners.
  Small sparks come from the latch jamb where the steel tears. Concrete fragments are thrown into the
  lane and fall, and grey concrete dust rises from the doorway's foot.
- **Blown.** The leaf follows ASTM F2927 response category IV: it is separated from the frame and
  thrown no further than 3 m.
  - It tore off its lane-side hinges and lies flat on the lane deck in front of the release bay. It
    is propped on one chunk, bowed, and shows torn hinge knuckles and contact shadow.
  - The doorway is empty and shows the lane behind it. The steel-lined far reveal has three torn bolt
    keepers, and the threshold is buckled.
  - The concrete is spalled round the frame, with exposed rebar. The latch-side flange is peeled, the
    head sags, and there is soot over the head.
  - A pile of spalled concrete and frame fragments runs from the doorway to the rubble line (x 540).
    The text can honestly call it rubble.
- **TANK RELEASE alcove.** The "alcove" and "posts" the text names are now real geometry: a recessed
  bay under a header beam, with two steel posts on base plates standing exactly on
  `SentryBrain.COVER_MIN_X` and `COVER_MAX_X`, and its own light fitting. It replaces the drawn
  cyan floor tint, the two tick posts and the soft recess shadow.
- **Nothing hovers.** Everything stands on the deck or is fixed by visible hardware. The door art is
  door-only, and the doorway is truly transparent (alpha 0), so the room behind shows through it.

## Files (all under `doors-r1/junction/`)

| What | Path |
|---|---|
| Atlas for the game (1024x768, lossless, 330 KB) | `layers/final/junction-door-atlas.png` (sha256 d565a30f...) |
| Placement: world positions, nodes, states, z, draw order, camera, model, screen points | `layers/final/placement.json` |
| Generated GDScript layout (regions, top-left positions, scales, lamp centre, jamb feet) | `layers/final/junction_door_layout.gd` |
| Each piece alone, for review | `layers/final/{wall,leaf,leafbreak,hole,damage,cracks,alcove,column,stub,lying,lens}.png` |
| Cleaned layers before packing | `layers/sealed/`, `layers/blown/` (with `cleanup-report.json`) |
| Construction design: flat renders, one mask per part, spec | `design/design-*.png`, `design/masks/`, `design/spec.json` |
| Tools | `tools/jmodel.py` (camera, model, light), `jdesign.py` (every part, with dims and job), `codex_inputs.py`, `cleanup.py`, `install.py`, `preview.py`, `imgkit.py`, `patch_game.py` + `patch_extra.py` (integration), `run_checks.sh`. Filed in `junction/tools/`, which now holds fix round 3's versions (`../README.md`, "Tool map"); round 1's are `junction/tools/jmodel.py` at dee9996, `junction/tools/jdesign.py` at dee9996, `junction/tools/codex_inputs.py` at dee9996, `junction/tools/cleanup.py` at dee9996 and `junction/tools/install.py` at dee9996. |
| Integrated slice: main + this door | `game-slice/` |
| Diff of the slice against main | `review/integration.diff` |
| Render driver | `driver/junction_door_capture.gd` |
| Captures, main | `captures/main/` |
| Captures, slice rounds 1-3 | `captures/slice1..3/` |
| Before/after sheet | `review/before-after-slice3.png` |
| Breaking frame | `review/breaking-slice3.png` |
| Headless logs | `review/checks-slice/` |
| Codex jobs | `doors-r1/codex/junction-paint-sealed/`, `doors-r1/codex/junction-paint-blown/` (prompt, refs, run log, out/ with C2PA kept) |
| Provenance | `doors-r1/provenance.txt` |
| Research PDFs | `research/dl/` |

## How to integrate

Rebuild the slice from a fresh export with
`python tools/patch_game.py <apps/game copy>`. Every replacement must match exactly once. The
patch does the following.

- **Assets in and out**
  - Copies in `assets/props/junction-door-atlas.png`, with an `.import` cloned from
    `corridor-seal-atlas.png.import` (lossless, mipmaps), and `scripts/junction_door_layout.gd`.
  - Deletes `assets/props/junction-bulkhead-{sealed,breaking,blown,front-lip}.png` with their
    `.import` files, and `art-source/doors/junction-{sealed,breaking,blown,front-lip}.png`.
  - In `assets/manifest.json`, replaces those 8 entries with one `junction-door-atlas` entry. Its
    rights status says it is awaiting Nathanial's review.
- **`scripts/junction_room.gd`**
  - Draws the door as pieces of the one atlas, via `_door_piece`.
    - Under the actors at z -3: `DoorHole`, `DoorLeaf`, `DoorLeafBreaking`, `DoorWall`,
      `DoorCracks`, `DoorDamage`.
    - At z -2: `ReleaseBay`, made after `Recesses` so its right post laps the bolt feed.
    - Over the actors at z 2: `DoorLampLens`, `DoorColumn`, `DoorStub`, `DoorLeafDown`, plus the
      lamp's small glow.
  - `_show_door` swaps the states. The old scale jolt, seam glow, alcove floor tint and posts,
    recess shadow and amber rubble tick are removed.
  - `_sync_seam` is renamed `_sync_lamp` and drives the lamp.
  - `blast_debris` is added, and the blast sparks and dust are retuned (see below).
  - The middle far-plate lamp's glow is hidden (`depth.painted_lamps = [1]`) because the cross-wall
    now stands in front of it.
  - The door placard `door_label` is centred at x 479 and drawn over the near column
    (`DOOR_FRONT_Z + 1`), as the old one was over the pillar.
- **`scripts/room_depth.gd`.** Removes the bulkhead pillar-fade machinery, which only the junction
  door used: `BULKHEAD_SCALE`, `BULKHEAD_PILLAR_X/WIDTH`, `PILLAR_FADE_ALPHA`, `pillars`,
  `pillar_covers`, `make_bulkhead`, `bulkhead_center_x`. The door column stays solid, as the
  corridor's does.
- **`scripts/main.gd`.** Drops `junction_room.depth.pillars = [...]`.
- **Tests**
  - `junction_test`: the presentation check is rewritten for the atlas pieces, draw order, and the
    doorway crossing the walk line inside the door body. The state checks use leaf, hole and leaf-down
    instead of the old images. The pillar-fade check is removed. The Reduced Motion check now uses the
    door lamp.
  - `room_depth_test`: the leaf stands on its near jamb foot.
  - `m0_scene_test`: the corridor column opacity check no longer reads `pillars`.
  - `follow_spacing_test`: the seam glow is gone; the placard is still excluded because it hangs over
    the column.
- **Outside `apps/game`, not patched here**
  - The repo-root `scripts/prepare_bulkheads.py` should drop its junction entries, or be deleted
    once the hatch track retires `corridor-bulkhead-open.png`.
  - The docs that list the old files (`docs/research-2026-10/lighter-game/map-assets.md`,
    `PLAN.md`) should be updated.
  - File this folder (tools, design, review, NOTES, provenance and the Codex `out/` files with
    C2PA) under `docs/research-2026-10/sources/junction-blast-door-2026-10-13/`, as was done for the
    corridor.
- **Merge order with the other tracks.** The hatch track also edits `junction_room.gd`, around
  `hatch_*` and `HATCH_PASSAGE_PROP`. These replacements do not touch those lines. If the hatch or
  records tracks also edit `room_depth.gd` or the tests, apply this patch after them and re-run it.
  It stops loudly on any text it cannot find.

## Route and station x changes

**None.** These all stay as they are:

- door collision body (`M0State.JUNCTION_DOOR_LEFT_X` 452, 56x132)
- `BLAST_MIN_X` and the blast zone
- `WOLF_CLEAR_X`, `WOLF_RUBBLE_X` 448, `RUBBLE_X` 540, `CHOICE_X`
- `COVER_MIN_X` / `COVER_MAX_X`, `ARM_X`
- valve, breaker and vent positions
- beats, timings (`DOOR_BREAK_SECONDS` 0.15), choices, saves and text

The geometry was fitted to the route instead. The approach face crosses the walk line at x 472. The
doorway spans the walk line between the far jamb foot (465.9, 436.0) and the near jamb foot
(491.3, 452.6), inside the old door body, so the engineer stopped by the body stands in front of the
shut leaf and then walks through the empty doorway.

The only position that moved is the **SEALED DOOR / DOOR DOWN placard**. Its centre went from
x about 491.7 to x 479, so it sits over the doorway's head instead of over the old pillar.

## Checks run

- **Headless** (`godot --headless`, isolated HOME `doors-r1/home`). On the slice: import twice, then
  all 15 suites pass with no script errors and no leaks.
  - `studio_logo_test` printed a dummy-renderer "Parameter t is null" texture error once in four
    runs, and also once on main. That is pre-existing and intermittent.
- **Rendered stills** (`tools/render/render.sh`, names `doors-r1-junction-slice1..3`, same driver as
  main's capture). Sealed, building, breaking (game time slowed so the 0.15 s frame is caught),
  blown, walking through the doorway, and at the rubble line. Main's own `j3-breaking` missed the
  breaking frame for the same speed reason.
  - The `j2-building` difference between main ("BREAKER TRIPPED") and the slice ("VALVE 2 / 3") is
    the capture's hold timing under software rendering, not a gameplay change. The headless
    `junction_test` covers that line identically on both.
- **Performance** (render.sh, medians over 90 frames; compare only with render.sh numbers):

| State | Draw calls | Visible additive items |
|---|---|---|
| Sealed | 94 → 90 | 10 → 9 |
| Building | 95 → 92 | 10 → 9 |
| Blown | 105 → 99 | 10 → 9 |

  - Texture memory went from 73.37 MB to 72.28 MB (−1.08 MB).
  - On disk, four PNGs totalling 1.19 MB became one 330 KB atlas.
  - The only new node is one one-shot `CPUParticles2D` (`BlastDebris`), live only during the blast.
- **Not done:** hands-on play, exports and device tests.

## Review rounds (from render.sh frames)

1. **Round 1** (`captures/slice1`). Three problems:
   - The near column cut the SEALED DOOR / DOOR DOWN placard in half.
   - The cross-wall's upper face read about 1.6x brighter than the approved corridor wall, sRGB
     about (40, 51, 57) against (24, 30, 34), so it looked like a flat pale slab.
   - The blast sparks were 12-24 px soft amber discs, the "blob" players described.
2. **Round 2** (`captures/slice2`).
   - The placard is now over the column.
   - The wall and column fall off above the door light. This is deterministic, in `install.py`:
     nothing but the far lamps lights them up there.
   - The breaking frame is now captured.
3. **Round 3** (`captures/slice3`). The blast effects were retuned:
   - 14 small sparks (2-5 px) from the latch jamb, thrown into the lane
   - grey concrete fragments with gravity
   - grey concrete dust in place of the shared tan
   - all of it lives only during the blast

No new Codex output after the two paint jobs.

## Text for Nathanial (drafts only, nothing shipped)

- **Optional stencil.** Typeset, never painted: a door number on the cross-wall over the head (for
  example `J-02`) and `BLAST DOOR` on the column, in the game's Roboto, like the corridor's
  `SECTOR 4B` / `DOOR 4B-07`. It would make "why it is sealed" read at a glance. It is not added,
  because it is new player-facing text.
- **Optional status line.** Once the blast is shown this clearly, the existing status line "The door
  goes. WOLF heads for the rubble ..." still fits. No change is proposed.

## Open issues and decisions for Nathanial

1. **The door is narrow on screen.** With the 17-degree turn and the door 40 px left of the room's
   vanishing point, the 2.3 m opening is only about 25 world px (about 34 screen px) wide, so the
   sealed leaf reads as a narrow grey door. A larger turn (about 30-35 degrees) would show about 1.7x
   more of the face. That means rebuilding every mask and one more Codex paint pass, and it departs
   from the corridor's angle. Say if you want it.
2. **The cover-span floor cue is gone.** Main tinted the floor cyan over the alcove's cover span and
   drew two tick posts. That is replaced by the painted bay, whose two real steel posts stand on the
   same x values. Whether the cover edge still reads in play needs a hand-played check. The sentry
   lines that name "the alcove's right post" now point at a real post.
3. **The amber rubble tick at x 540 is gone.** The rubble pile now ends there physically.
4. **The thrown leaf** lies on the near deck in front of the release bay, drawn over the actors who
   pass behind it. It looks grounded in stills, but at game scale it reads more as "a heavy slab"
   than unmistakably "the door". Showing its lane face up (levers, torn hinges) would need a new
   paint pass, and that detail is under 5 px at game scale.
5. **Shared effects.** The shared `FxPresets` sparks and dust (relay, exit, corridor door) still use
   the soft discs. Only the junction blast was retuned here.
6. **Outside this patch.** `scripts/prepare_bulkheads.py` and the lighter-game docs need updating
   when this lands (see "How to integrate").

## Sources

- ASTM F2927, *Standard Test Method for Door Systems Subject to Airblast Loadings*, door response
  damage categories (category IV: the door separates from the frame, flying debris within 3 m).
  - Quoted in SDI 133-2026: https://steeldoor.org/wp-content/uploads/2020/02/SDI_133.pdf (copy in
    `research/dl/sdi-133.pdf`)
  - Overview: https://www.intertek.com/building/standards/astm-f2927/
- UFGS 08 39 54, *Blast Resistant Doors* (USACE/NAVFAC/AFCEC). Side-hinged swinging blast doors,
  seating and unseating overpressure, rebound, hinges and latches:
  https://legacy.wbdg.org/FFC/DOD/UFGS/UFGS%2008%2039%2054.pdf (copy in `research/dl/`)
- Hartmann Tresore, HET 02 blast door data sheet: steel and reinforced concrete leaf 400 mm, 28 bar
  reflected, three lateral 80 mm round locking pins with a wheel, 80 mm hinge pins, heavy steel frame
  fixed with 80 mm anchors:
  https://hartmann-tresore.ch/fileadmin/user_upload/tresore/Explosionsschutzt%C3%BCr/HET02.pdf (copy
  in `research/dl/`)
- Swiss shelter closures, *Panzertor* PTO 1: two-leaf armoured gate, 2.40 x 2.10 m clear, 20 cm leaf,
  1 bar. Used for the proportions of a 0.2-0.3 m concrete-filled leaf in a military installation.
  - https://www.sz.ch/sicherheitsdepartement/amt-fuer-militaer-feuer-und-zivilschutz/schutzbauten/schutzraum-bauen/abschluesse.html/8756-8758-8802-9496-10084-10257-10306-10274
  - BABS TPH: https://www.babs.admin.ch/dam/de/sd-web/b3mfmfajan7s/tph19-de.pdf
- Liu, Oesterle, Conway and Covino, *Modeling and Simulation of HD 1.3 Thermal Initiation Tests on a
  Small Reinforced Concrete Storage Structure* (NDIA 2018). Observed failure: cracking from the wall
  corners and failure of the steel door under internal overpressure. Used for where cracks start and
  that the door goes first:
  https://ndia.dtic.mil/wp-content/uploads/2018/intexpsafety/Liu2Paper.pdf (copy in `research/dl/`)
- Method and design language: `docs/research-2026-10/sources/corridor-door-end-2026-10-12/`
  (DESIGN.md v6, spec.json, tools) and `docs/research-2026-10/art-direction/REAL-LOOK.md`.
