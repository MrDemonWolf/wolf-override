# Door, seal, hatch and gate measurements (main at 76d3a50)

Scratch only. Nothing in a Git repository or worktree was edited. These are rendered stills from a scripted
capture plus code reading. Nothing was played by hand, so this file makes no claims about how anything feels.

## How this was measured

- Game copy: `game-copy/` (rsync of `apps/game` without `.godot`). It was imported twice headless with
  `HOME=<session scratch>/home-shutter`. Godot 4.7.2.stable.official.ed1daf0bf.
- Driver: `driver/capture_doors.gd` (copied into `game-copy/shutter_capture/`), run by `driver/run.sh` in a
  1280x720 window. Each shot sets an `M0State` and calls `_sync_scene()` plus `_start_gameplay_camera()`.
  It saves `reference/raw/<shot>.png` with the UI CanvasLayer hidden, and `<shot>-ui.png` for one state per
  door. It also writes `<shot>.json`, which holds `world_to_screen` and every visible Sprite2D render box and
  every CollisionShape2D hitbox (enabled or disabled), in world and screen px.
- `driver/annotate.py` draws those boxes over each frame and cuts one crop per door:
  - `reference/full/<shot>.png` (clean)
  - `reference/full/<shot>-boxes.png` (overlay)
  - `reference/crops/<shot>.png` and `<shot>-boxes.png`
- Overlay key:
  - red: enabled hitbox
  - grey dashed: disabled hitbox
  - orange: Area2D hazard
  - cyan: door render box, with z
  - yellow: actor render box
  - green: the floor at y 440, with world-x ticks every 50 and y ticks on the left.
- The main repo has no in-game hitbox or render-box debug overlay; grep found no `debug` code in `apps/game/scripts`. This overlay lives only in the scratch driver.
- Caveats:
  - The first run stalled after `j3` because the window stopped drawing. The junction shots were then re-run with `--from=j` and finished cleanly.
  - `r4` came out at 1664x936 after the chapter-close shot. The annotator rescaled it to 1280x720, but its camera framing differs a little from the others.
  - `k2` and `k3` set `junction_room.hatch_open` (0.5 and then 1.0) directly instead of running the bolt whine.

## World and camera facts every door shares

- Room width 960. Floor `FLOOR_Y` is 440. Actors are clamped to x 40..920 (`M0Actor.MIN_X`/`MAX_X`).
- Engineer: hitbox 28x60. Sprite about 72 world px tall (368.9..441.1).
- WOLF: hitbox 62x34. Sprite about 140x74.
- `WOLF_REACH` is 67 and `HUMAN_REACH` is 17.
- Gameplay camera: zoom 1.35, y 360 (touch y 392). It sees 711x400 world px: y 160..560 (touch y 192..592). Camera x is clamped to 355.6..604.4.
  - At 1280x720 a world px is 1.8 screen px. At 1080p it is 2.7.
  - With the camera at its right clamp, the view covers x 249..960.
- Chapter-close camera: zoom 1.55 at (650.3, 352). It sees x 340.6..960 and y 178..526.
- Intro camera: zoom 1.8 at (267, 355).
- Plates are 1920x1080, drawn at 0.5 so the room is 960 wide.
  - The mid plate's top is at `440 - walkway_y*0.5`: corridor 51.5 (walkway 777), junction 52 (776), records 69 (742).
  - The far plate is drawn 27 lower in the corridor and the junction, and parallaxes at 0.9. At the camera's clamps it shifts about ±12 world px.
  - The near strips parallax at 1.15.
- The ceiling pipe run on each mid plate ends at world y about 141 (corridor), 122 (junction) and 156 (records). A floor-to-ceiling portal header should meet that run, so its art should reach y ≤ 120..150. That way it stays solid above the view top (y 160) in every framing.
- Depth order:
  - mid plate z -3, far plate z -4
  - station props and doors 0..1
  - actors z 2 (`ACTOR_Z`)
  - corridor front lip z 3 (`KNOCKDOWN_Z`)
  - junction lip: room z 1 + 2 = 3
  - near plate z 3 (parallax)
- Art density (art bible, doors D = 4 source px per world px):
  - current bulkheads: 0.3 scale, about 3.33 src/world (the originals in `art-source/doors` are about 6.7)
  - junction hatch: 0.206, about 4.85
  - records exit: 0.291, about 3.44

## 1. Corridor seal (lockdown chapter), the first shutter

- **Code:**
  - `scenes/main.tscn` node `Door`:
    - StaticBody2D at (780,374), layer 2, `DoorShape` 56x132
    - `Door/Visual`: a transparent ColorRect with offsets ±28/±66 and pivot (28,0)
    - `Door/Visual/DoorArt`: Sprite2D scale 0.3, region (0,42,384,606), pos (32.7,41.1), ext_resource `7_door` = `corridor-bulkhead-sealed.png`
  - `scripts/main.gd`:
    - constants `CORRIDOR_DOOR_LEFT_X`=752, `CORRIDOR_DOOR_SEALED/OPEN/LIP`, `CORRIDOR_DOOR_REGION`, `CORRIDOR_DOOR_OPEN_SECONDS`=1.0
    - `_setup_corridor_door()`: `door_open_art`, `door_lip` at z 3, `seal_leaf`
    - `_sync_door(animate)`
    - `_door_lands()`: shape disabled, thud, trauma 0.5, rumble, `door_dust` at (780,436) with extents 30x3
    - `_wolf_follow_max_x()`
    - `_interact_checkpoint()`
    - `corridor_depth.pillars=[door_lip]`
  - `scripts/seal_leaf.gd`: `SealLeaf` is a clip mask polygon `DOORWAY` plus the leaf cut `LEAF` (150,160,188,440) from the sealed image. It rises by its own height.
  - `scripts/room_depth.gd`:
    - `BULKHEAD_SCALE` 0.3, `BULKHEAD_PILLAR_X` 83, `BULKHEAD_PILLAR_WIDTH` 76
    - `make_bulkhead`, `bulkhead_center_x`, `pillar_covers`
    - the lip fades to 0.5 while it covers an actor
  - `FloorReflection` is attached to `door_art` and `door_open_art`.
- **World rect:**
  - Art: x 727.1..842.3, y 258.2..440 (115x182, centre x 784.7).
  - Collision: x 752..808, y 308..440.
  - The front pillar column is x 752..774.8.
- **Neighbours that bound a new portal:**
  - MANUAL BYPASS collar x 682.5..717.5; the engineer cranks it from x 674
  - Safe point art x 841..911 (`CheckpointArt` at 876, scale 0.25)
  - Room end 920
  - So a portal can use about x 718..840 without moving anything.
- **States and transitions:**
  - hidden in the intro (`door_visual` hidden)
  - sealed, with red lamps
  - opening (`seal_opening`): `SealLeaf.open` goes 0→1 over 1.0 s (quad in-out). Collision stays on and WOLF holds the relay contact.
  - open: `door_open_art` and the lip show, and the shape is disabled once `_door_lands` runs
  - It is hidden in the other rooms, where the shape is also disabled.
- **What blocks the player:**
  - `state.door_open` is set by `activate_power`: either WOLF takes the relay ("cooperate", only after the disclose choice) or the engineer finishes the bypass ("fallback").
  - The body stays solid until the leaf lands.
  - While the seal is shut, WOLF's `follow_max_x` = 752-67 = 685.
  - The checkpoint USE says "The safe point is past the sealed door."
- **Old art to delete:**
  - `assets/props/corridor-bulkhead-sealed.png`, `-open.png`, `-front-lip.png` (plus their `.import` files)
  - `art-source/doors/corridor-sealed.png`, `corridor-open.png`, `corridor-front-lip.png`
  - `scripts/prepare_bulkheads.py` (repo root)
  - manifest entries (`corridor-bulkhead-*` and the art-source rows)
  - **Dependency:** `junction_room.gd HATCH_PASSAGE_PROP` reuses a cut of `corridor-bulkhead-open.png`.
- **Tests that pin the current structure:**
  - `tests/m0_scene_test.gd` 222-237: `seal_leaf`, `door_open_art`, `door_lip` z above the engineer, `corridor_depth.pillars`
  - `follow_spacing_test.gd`
- **Space beyond:** walking through the corridor door keeps you in the same room, with the safe point at 876. Records is entered by a second USE at the safe point, which cuts to the new room. So the "different space" can only show inside the portal's own depth while it is open, unless the room is extended.

## 2. Junction blast door

- **Code:** `scripts/junction_room.gd`
  - constants:
    - `DOOR_SEALED/BREAKING/BLOWN/LIP_PROP`
    - `DOOR_REGION` (0,36,384,604), `DOOR_SCALE` 0.3, `DOOR_SEAM_X` 196
    - `DOOR_BREAK_SECONDS` 0.15
    - `DOOR_X` 480, `DOOR_WIDTH` 56, `DOOR_HEIGHT` 132
    - `DOOR_Z` 0, `DOOR_LIP_Z` 2
  - functions:
    - `_build_door()`
    - `door_blast()`: breaking, then blown after 0.15 s. The visual jolts to scale (1.04,0.94) and settles back to 1 over 0.3 s (TRANS_BACK). `blast_sparks` at (480,374); `blast_dust` at (500,436) with extents 70x3.
    - `_show_door()`, `_sync_seam()`, `set_active()`, `reset_transient()`
    - `_draw_blast_zone()`: red stripes over x 360..540 while the fuse burns
    - the rubble tick at x 540
    - `door_label` "SEALED DOOR"/"DOOR DOWN" at x≈491.7, y 320, z 3
  - also: `M0State.JUNCTION_DOOR_LEFT_X`=452; `PressureLine.BLAST_MIN_X/MAX_X` 360/540; `SentryBrain.RUBBLE_X` 540; `main.gd _door_blast()`, which also handles the knockdown when the engineer is inside 360..540
  - Save validation (`m0_state.gd` 294-297) rejects positions past 452 before the blast.
- **World rect:**
  - Art: x 427.1..542.3, y 258.8..440 (centre 484.7).
  - Collision: x 452..508, y 308..440. It is enabled only while the junction is active and the door is not blown.
  - Seam glow: centre x 485.9, 40x145.
  - The breaking frame jolts out to x 424.8..544.6, y 269.7..440.
- **Neighbours:**
  - VALVE at 420, half-width 50.6, so x 369.4..470.6. It stands in front of the door's left frame.
  - WOLF reads the seam from `WOLF_SEAM_X`.
  - The alcove and TANK RELEASE start at x 545 (`COVER_MIN_X`).
  - So a portal fits about x 425..545, with the valve kept in front of it.
- **States:**
  - sealed: seam amber at 0.2
  - building: seam amber at 0.25+0.5×gauge
  - charged/fuse: seam strobes white and red (steady with Reduced Motion), and the blast stripes pulse
  - breaking: 0.15 s
  - blown: shape off, "DOOR DOWN", rubble tick
  - A knockdown restores autosave A, so the door goes back to sealed.
  - A save that loads already blown shows the blown frame.
- **What blocks the player:** the body face at x 452, and WOLF `follow_max_x` = 385, until the breaker is armed, the valve gets three turns and the fuse finishes.
- **Old art to delete:**
  - `assets/props/junction-bulkhead-sealed/-breaking/-blown/-front-lip.png` (plus `.import`)
  - `art-source/doors/junction-*.png`
  - manifest rows
- **Tests that pin the current structure:** `tests/junction_test.gd` 298, 305, 324, 349, 556-569 (shared region, pillar on the face, z order) and 630-646 (lip fade).

## 3. Junction exit hatch, end of the slice

- **Code:** `junction_room.gd`
  - constants:
    - `HATCH_PROP` = `junction-hatch.png` (512x768)
    - `HATCH_REGION` (54,34,403,700), `HATCH_SCALE` 0.206, `HATCH_LAMP` (206,68,92,24)
    - `HATCH_LEAF` (150,142,216,498)
    - `HATCH_PASSAGE_PROP`/`HATCH_PASSAGE`/`HATCH_PASSAGE_TINT` (a corridor-bulkhead-open cut)
    - `HATCH_X` 880, `HATCH_OPEN_SECONDS` 0.5
  - classes and functions:
    - class `HatchDoorway`: clip-children-and-draw. It draws the passage plus a green light, and its leaf slides up by its own height.
    - `bolt_arc()`, `_sync_hatch()`, `hatch_opened` signal
    - `_draw_hatch_lamp()`, `_bolt_light_color()` (red→amber→white→green), `hatch_label`
  - `main.gd`: `_use_exit()`, `_hatch_sliding()`, `_hatch_opened()`, `_leave_junction()`, `_walk_out_through_hatch()` (`HATCH_EXIT_X` 886, `WOLF_HATCH_EXIT_X` 856, fade after 0.3 s over 0.5 s)
- **World rect:**
  - Art: x 838.5..921.5, y 295.8..440.
  - Leaf and doorway: x 858.3..902.8, y 318.1..420.6. Its threshold is about 19 px above the floor.
  - Lamp: x 869.8..888.8, y 302.8..307.7.
  - **No collision**; the actors' x clamp (920) is the only wall.
- **Neighbours:**
  - The bolt panel at 806, half-width 38.4, spans x 767.6..844.4. USE reaches from x 740.6.
  - The room's right edge is at 960.
  - So a portal fits about x 845..958.
- **States:**
  - bolted (red lamp, "EXIT BOLTED")
  - sentry down: "EXIT BOLT", amber
  - charging: the bolt whine warms the lamp to white
  - opening: `hatch_open` 0→1 over 0.5 s, "EXIT OPENING"
  - open: "EXIT OPEN", green
  - cleared (walk-out, END OF SLICE)
- **What blocks the player:** the USE gate only. The door has to be blown and the sentry down, and the bolt must arc and the hatch finish sliding before the next USE leaves.
- **Old art to delete:** `assets/props/junction-hatch.png` (shared with the entry hatch) and its manifest row.

## 4. Junction entry hatch (decoration)

- **Code:** `junction_room.gd` `entry_hatch_art` uses the same `HATCH_PROP` at `ENTRY_X` 80. `_draw_hatch_lamp(entry_hatch_art, GREEN, 1.0)` draws its lamp green at all times.
- **World rect:** x 38.5..121.5, y 295.8..440. No collision. The engineer spawns at x 120 and WOLF at 208.
- **States:** one only: shut, green lamp. It never animates.
- The BREAKER at 200 (x 161.5..238.5) sets the right limit, so a portal fits x 0..160.

## 5. Records exit

- **Code:**
  - `scripts/records_room.gd`:
    - `EXIT_HATCH` = `records-exit-hatch.png` (512x512), `EXIT_REGION` (126,21,260,481), `EXIT_SCALE` 0.291, `EXIT_REST` (830,370)
    - "EXIT" label at (830,276)
    - `_draw_exit()` draws the open doorway as plain rects:
      - fill (798,300,64,138) `#081b2b`
      - frame (790,296,80,144) `#4a6572` 3 px
      - green sill line (810..851, y 433)
  - `main.gd _interact_records(x)` with `|x-830|≤58`:
    - `complete_chapter()` brings the arc sound, trauma 0.3, flash and `exit_sparks` at (830,330)
    - `exit_art` tweens y-130 and alpha to 0 over 0.5 s, then hides
    - `_frame_chapter_close()`
    - The next USE runs `_enter_junction()`, a cut.
  - `_sync_records_room()`; `_machine_spans()` treats the exit as a machine span (830±37.8), so WOLF never stands in it.
- **World rect:** art x 792.2..867.8, y 300..440. Drawn doorway x 790..870, y 296..440. **No collision.**
- **Neighbours:** the mid-plate truss column (x 740..790); the engineer works the exit from its side; room end 920. A portal fits about x 795..930.
- **States:**
  - sealed: red strip, "Exit sealed until the purge order and mirror timestamp are copied."
  - lifting: 0.5 s
  - open: the code-drawn rect doorway
  - Reloaded saves show the open rects directly.
- **What blocks the player:** USE only. `purge_trace_preserved` and `mirror_trace_preserved` must both be set, then `complete_chapter`.
- **Old art to delete:** `assets/props/records-exit-hatch.png` and its manifest row, plus the `_draw_exit()` rectangles (an old code-drawn doorway).

## 6. Intro containment gate (seen first, not a corridor door)

- **Code:** `scripts/containment_cage.gd` with `shutter=true`.
  - `IntroGate` (z 3) and `IntroCage` (z 4) sit at (115,365) in `main.tscn`.
  - `main.gd _new_game()`/`_finish_intro()`, `_shutter_boom()`, `gate_dust` (115,438)
  - The opening tween takes 0.65 s, cubic out, and the bars stack against the left post.
- **World rect:** bars x≈40..190, y 312..437. Cage frame x 27..203, y 292..451. No collision; this is intro staging. Everything is drawn in code; there are no image files.
- **States:** closed, then opening as WOLF breaks out, then open and folded, then hidden after the intro.
- **Recommendation:** out of shutter scope unless Nathanial asks. Listed for completeness.

## Layers a shutter version needs (for each portal)

1. **Portal back:** the header, the far frame column, the guide rails' back halves, and the dark recess. It is opaque and runs floor to ceiling (y ≈120..440). It draws behind the actors at z 0..1, over the mid plate.
2. **Beyond plate:** the different space seen through the opening, sitting inside the portal back and clipped to the opening.
   - corridor: a machinery service chamber
   - junction: an electrical switchgear hall with warm lights
   - exit hatches: a service line
   It needs its own floor that continues the walkway at y 440.
3. **Shutter leaf:** the moving part, ribbed slats with a hazard-chevron bottom edge. It is drawn at the 3/4 angle and clipped to the opening.
   - Open: it rises into the header, driven by the same 0→1 value as `SealLeaf.open` or `HatchDoorway.open`.
   - It needs a separate stowed sliver of the bottom edge (or a rolled drum) in the header.
4. **Portal front edge:** the near frame column plus the header lip. It draws over the actors (z 3) and fades to 0.5 while it covers someone, as `door_lip` does now. Its left edge sits on the collision face (752 corridor, 452 junction).
5. **Status lamps:** one lens per state, as small sprites or a tintable white lens plus a glow.
   - corridor: red sealed, green open
   - junction: amber; dark or broken when blown
   - exit hatch: red, amber, white, green
   - records: red sealed, green open
   They should not be baked into the plate (art bible: state lights are never baked).
6. **Junction only:**
   - breaking frame: buckled slats with a hot seam, 0.15 s
   - blown leaf remains: torn slats hanging from the header, buckled toward the right, with a clear gap at least 2× the engineer's height from the floor
   - separate debris pieces on the floor right of x 452. They must stay out of the walk path or sit behind the actors; the rubble line stays at x 540.
   - scorch decal on the portal and floor
   - seam glow anchor: a new `DOOR_SEAM_X` equivalent
7. A floor reflection and shadow come free from `FloorReflection.attach` for each sprite. The art needs clean straight alpha at the base row (the canvas's bottom row is the floor).

Size targets at D = 4, using the available x ranges above and y 120..440 (320 world px tall, so 1280 source px):

| Portal | World width | Source width |
|---|---|---|
| corridor | ~122 | ~490 |
| junction | ~120 | ~480 |
| exit hatch | ~110 | ~440 |
| records | ~130 | ~520 |
| entry hatch | ~120 | ~480 |

- The approved concept makes the shutter face 1.4× the engineer's height. That is about 100 world px.
- Keep each collision face, `JUNCTION_DOOR_LEFT_X`, the blast zone and the rubble line unchanged. If they stay, the save validation, WOLF reach limits and tests keep working, and only art regions and lip geometry move.

## Plate pieces that would show behind or beside a new shutter (no painted doors exist)

None of the nine room plates (`*-far`, `*-mid`, `*-near`) has an old door or doorway painted into it. These are the code-drawn or plate pieces that would clash with a floor-to-ceiling portal:

- **corridor-mid.png:** a pipe-and-column pair at source x 1460..1562 (world x 730..781), running the full height (world y 52..440). It stands inside the corridor door's footprint. Above the header it reads as a second pillar (visible in c1, c3 and c4).
  - Paint it out (or rebuild it as the portal's left column).
  - Paint out the low machine and pipe stub at source x 1565..1870, rows 575..776 (world x 782..935, y 339..440), behind the door's right half and the safe point.
- **junction-mid.png:** a hanging pipe stack with valves and a gauge at source x 786..1010, rows 140..566 (world x 393..505, y 122..335). It hangs straight onto the blast door's header (j1 to j4). Paint it out or re-route it so the deep portal header meets the ceiling run.
- **junction-mid.png:** a right truss column at source x 1801..1900 (world 900..950, y 58..440). It overlaps the exit hatch's right side (hatch 838..921). Paint it out or turn it into the portal's far column.
- **junction-mid.png:** a left boiler, gauge and pipe cluster at source x 12..279 (world 6..140, y 58..440). The entry hatch is pasted over it. Paint out the part inside x 0..160 if the entry gets a portal.
- **records-mid.png:**
  - A truss column at source x 1480..1580 (world 740..790, y 69..440), directly left of the exit. Keep it as a neighbour or merge it into the portal's left column.
  - A machine at source x 1588..1905, rows 596..741 (world 794..952, y 367..440), sitting behind the exit's right half. Paint it out.
- **records_room.gd `_draw_exit()`:** a code-drawn rectangular doorway (old placeholder). Delete it.
- **junction_room.gd `HATCH_PASSAGE`:** borrows `corridor-bulkhead-open.png`. Replace it with the new beyond plate before deleting that file.
- Far plates: no doors.
  - corridor-far: plain wall and lamps at the door x.
  - junction-far: pipes and a junction box.
  - records-far: rack bays and a vent grille at world y 374..404 behind the exit, which the portal back would cover.
  - Near strips: no doors.

## Reference files

- `reference/full/` and `reference/crops/`, with a `-boxes` overlay for each:
  - corridor seal: c1-c5 (`c1-corridor-sealed`, `c2-corridor-opening`, `c3-corridor-open`, `c4-corridor-engineer-in-doorway`, `c5-corridor-engineer-past-door`)
  - records exit: r1-r4 (`r1-records-exit-sealed`, `r2-records-exit-lifting`, `r3-records-exit-open-close-framing`, `r4-records-exit-open-reloaded`)
  - junction entry hatch: j0 (`j0-junction-entry-hatch`)
  - junction blast door: j1-j4 (`j1-junction-door-sealed`, `j2-junction-door-breaking`, `j3-junction-door-blown`, `j4-junction-engineer-in-blown-gap`)
  - junction exit hatch: k1-k3 (`k1-junction-exit-hatch-bolted`, `k2-junction-exit-hatch-half-open`, `k3-junction-exit-hatch-open`)
  - intro cage gate: i1 (`i1-intro-cage-gate-closed`)
- `reference/raw/*-ui.png` frames for c1, r1, j0, j1, k1 and i1 include the HUD.
- `measure/props-sheet.png`: every current door prop on magenta.

Room expansion to 1.5-2 views is decided but not built. Every coordinate here is the current main build and will move if the rooms grow.
