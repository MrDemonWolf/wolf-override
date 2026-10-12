# Map: room and world scripts (read-only analysis, main @ 76d3a50)

Scope: `apps/game/scripts/` junction_room.gd (1243 LOC), records_room.gd (149), room_depth.gd (642), seal_leaf.gd (58), bypass_handle.gd (199), containment_cage.gd (40), sentry.gd (330), sentry_brain.gd (224), drop_arm.gd (109), pressure_line.gd (128), hazard.gd (59), hold_use.gd (44), floor_reflection.gd (115), fx_presets.gd (98), impact.gd (179), m0_actor.gd (174), m0_state.gd (393), plus the corridor parts of main.gd (3310) and main.tscn (911).

Nothing was run. This is a read of the source only: no headless run, no render, no play. Line savings below are estimates from reading the code.

## 1. What each file does today

| file | role | notes |
|---|---|---|
| room_depth.gd | Shared 3-plate parallax set (far/mid/near), lamp glows, shafts, beacons, dust, near-edge and pillar fade, plus static helpers `make_prop`, `make_bulkhead`, `bulkhead_center_x`, `make_glow`. | Already the one real shared room component. Used by the corridor (in main.tscn), Records and the Junction (both built in code). |
| junction_room.gd | Builds the whole junction in code: RoomDepth, 7 props, valve wheel (mask shader), door (body, 3 state sprites, lip, seam glow), 9 particle systems, 2 Hazards, sentry, tank, arm, 7 plates and a caption. Draws gauge needle, lights, blast stripes, alcove, floor brackets, arm rods and cable, bolt feed (through an inner `Recesses` node). Inner classes `TankSprite`, `Recesses`, `HatchDoorway`. Also hosts the shared static helpers `fade_at_view_edge`, `edge_alpha`, `prop_point`, `prop_rect`, `soft_texture`, the `LABEL_PLATE` style colours and `WHEEL_MASK`. | It is a god-object for the junction and also a utility library for the other rooms. |
| records_room.gd | RoomDepth, 3 props, 2 status lights (drawn rect plus glow), 3 station names (no plate), the open-exit doorway drawn in `_draw_exit`. | It repeats the junction's label, fit and fade code with a different font size and no plate. |
| bypass_handle.gd | The corridor MANUAL BYPASS: a wheel (a copy of the junction valve wheel and its shader), a plate with a crank readout, the COOLANT FAULT tag, coolant hiss, and the drawn pipe and post. | It has its own `_plate()` copy of the junction plate and its own edge fade. |
| seal_leaf.gd | The corridor seal leaf rising into the header, clipped to a polygon doorway. | Same mechanism as `JunctionRoom.HatchDoorway`. |
| containment_cage.gd | The procedural intro cage and folding gate (`shutter` export). | Attached to a `Sprite2D` node in the tscn. Main drives it with `set("opening", ...)`. |
| sentry.gd | The sentry body (CharacterBody2D) plus `SentryVisual` (art, wreck, lens glow, beam drawing). | `_art()` repeats the `make_prop` cut. Its velocity mover repeats `M0Actor._approach`. |
| sentry_brain.gd, drop_arm.gd, pressure_line.gd | Pure logic, frame-independent. | Clean. Small overlaps only (x-range tests, EPSILON, `reset`). |
| hazard.gd | An Area2D hurtbox that is armed from real state. | Used twice (vent, cloud). The blast and the sentry contact use x-range tests instead. |
| hold_use.gd | Held-USE tick accumulator (0.4 s). | `PressureLine.crank` repeats the same accumulator (TURN_SECONDS 0.4) and Main runs both for the valve. |
| floor_reflection.gd | A mirrored sprite plus a contact shadow per source, refreshed every frame. | Makes one new GradientTexture2D shadow and one ShaderMaterial per instance. |
| fx_presets.gd | The sparks, dust and steam CPUParticles2D presets. | Every call makes a new dot texture and a new fade ramp. |
| impact.gd | Shake, hit-stop, flash and rumble. | Fine. Out of the duplication path. |
| m0_actor.gd / m0_state.gd | Actor mover and follow / save state. | The literal bounds 40/920 in M0State repeat `M0Actor.MIN_X`/`MAX_X`. `HUMAN_HALF_WIDTH` and `JUNCTION_DOOR_LEFT_X` live in the save class but are world geometry. |
| main.gd (corridor parts) | Corridor stations live as loose scene nodes: `PurgeTerminalArt`, `BreakerArt`, `RelayArt`, `CheckpointArt`, `BreakerStatusLight`, `RelayStatusLight` (ColorRects), 3 Labels, `Door`, `Visual`, `DoorArt`, `IntroGate`, `IntroCage`, `RelaySpark`. Code adds `door_open_art`, `door_lip`, `seal_leaf`, `bypass_handle`, `EdgeFader`, the status glows and the particles. It also holds all three rooms' station tables (`*_STATIONS`), `_machine_spans`, and the reach checks in `_interact*`, `_context_hint`, `_junction_hint` and `_hold_station`. | There is no CorridorRoom. Four hand-kept lists show or hide the corridor nodes (lines ~993-998, ~1080-1085, ~1518-1521, 2811-2814). |

## 2. Repeated code found (with locations)

### 2.1 Station name plates and the edge fade (largest UI-visible repeat)
- Creating a label: `JunctionRoom._add_station_label` + `_fit_label` + the `label_plate` StyleBoxFlat (junction_room.gd 470-503, 673-694). `RecordsRoom._add_station_label` + `_fit_label` (records_room.gd 82-102). `BypassHandle._plate` (bypass_handle.gd 151-174), which builds a second StyleBoxFlat from `JunctionRoom.LABEL_PLATE`. `JunctionRoom` `line_caption` (490-501). `Main._setup_corridor_labels` re-fits three scene Labels (main.gd 603-613; main.tscn 224-252).
- The per-frame edge fade runs in four places: `JunctionRoom._process` (698-701), `RecordsRoom._process` (106-108), `BypassHandle._process` (147-148), and `Main.EdgeFader` (main.gd 415-421). Each one reads the canvas transform again.
- Variants the component has to keep so the UI stays the same: the junction has a plate, font 12, top at y 320. Records has no plate, font 13, y 309 (EXIT at 276). The corridor has no plate, font 13, y 313. The bypass has a plate, font 13, a 64 px wrap and a 12 px foot. The LINE caption has a plate and font 8.
- Each state change sets text and colour as a pair, then re-fits: junction `refresh_state` (871-908) has about 14 such pairs, Records has 4.
- About 180 lines in all. A NamePlate component would be about 50.

### 2.2 Status lamps (lights on a prop's painted bar, plus a glow)
- Records: the `PURGE_LIGHT` and `MIRROR_LIGHT` rects, `_add_glow`, `_draw_machine_lights`, `_purge_light_color` and `_mirror_light_color`, and the glow tint in `refresh_state` (records_room.gd 21-22, 70-78, 132-149).
- Junction: `BREAKER_LIGHT` + `breaker_glow` + `_draw_breaker_light` + `_breaker_light_color`; `ARM_PANEL_LIGHT` + `_draw_arm_panel_light`; `BOLT_PANEL_LIGHT` drawn in `_draw`; `HATCH_LAMP` drawn twice through `_draw_hatch_lamp` (entry and exit hatch); `_bolt_light_color` (junction_room.gd 75-87, 452-458, 1035-1046, 1118-1179, 1236-1243).
- Corridor: `BreakerStatusLight` and `RelayStatusLight` ColorRects (main.tscn 200-216), `_attach_status_glow` (main.gd 692-697), colours and glows set in `_refresh_ui` on every frame (main.gd 3000-3006).
- Effects on/off keeps a hand list of five glows (main.gd 625).
- That makes 3 implementations of one idea, about 110 lines plus 18 tscn lines. The approved Look 2 batch already ships 8 near-white `status-lamp-*.png` sprites meant to be tinted with `modulate`, so the lamp should be a sprite component, not draw_rect.

### 2.3 Glows, soft textures and particle textures, rebuilt per instance
- `RoomDepth.make_glow` builds a new 128x128 radial GradientTexture2D and a new additive CanvasItemMaterial on every call. Callers: 7 per room in RoomDepth (lamps, warning glows; shafts have their own 128 px texture), junction breaker, vent and seam glows, Records purge and mirror glows, the corridor's 2 status glows, and the sentry lens glow.
- `JunctionRoom.soft_texture`: the alcove shadow and the hatch light.
- `FloorReflection._make_shadow`: one identical 64 px radial per reflection, about 23 of them.
- `FxPresets._dot_texture` and `_fade_ramp`: new ones for every particle system (junction 9, main 5, bypass 1).
- `RoomDepth._make_dust` and `_make_shaft`: per room.
- That is about 80 GradientTexture2D instances but only about 6 distinct shapes. Separate additive materials also stop the GL Compatibility 2D batcher from merging the glows.

### 2.4 Prop sprite cuts done by hand next to `make_prop`
- `Sentry.SentryVisual._art` (sentry.gd 145-157), junction `arm_art` (621-630), `valve_wheel` (435-451), `TankSprite` setup (611-618), `BypassHandle` wheel (bypass_handle.gd 101-113), `SealLeaf` leaf (seal_leaf.gd 31-41), and the `HatchDoorway` leaf (junction_room.gd 378-386). Each one sets texture, filter, region, scale and position by hand.
- "z_index -1, add_child, append FloorReflection.attach" is written twice (records_room.gd 61-69, junction_room.gd 423-427). The corridor's version is the hand list in main.gd 466.

### 2.5 The turning wheel, written twice
- The junction valve wheel and the bypass wheel use the same texture, region and mask shader, built from the same `WHEEL_MASK` string. That string is compiled into two Shader instances.
- Both have the same `_turn_wheel` tween (0.18 s, cubic, ease out): junction_room.gd 859-867 and bypass_handle.gd 177-186.
- The Look 2 batch splits the valve into a body, a wheel, a gauge face and a needle. The wheel then becomes a plain sprite and both the mask shader and `_draw_gauge` go away.

### 2.6 Doors, shutters and hatches (biggest structural repeat)
- **Corridor seal:**
  - scene `Door` StaticBody2D, `Visual` ColorRect and `DoorArt` (main.tscn 70-91)
  - `_setup_corridor_door` (main.gd 579-590)
  - `_sync_door` with its tween (2828-2847) and `_door_lands` (2677-2686)
  - `door_dust`, `CORRIDOR_DOOR_*` constants, the `seal_leaf` node (seal_leaf.gd) and the pillar registration (main.gd 472)
- **Junction blast door:**
  - `_build_door` (527-562), `_show_door` (971-974), `door_blast` with its tween (948-965)
  - `set_active` toggling the body (722-727)
  - `blast_sparks` and `blast_dust`, `DOOR_*` constants and the seam glow
- **Junction exit hatch:** the `HatchDoorway` inner class (363-393), `bolt_arc` with its tween and `hatch_opened` (850-856), `_sync_hatch`, and the hatch lamp. The entry hatch reuses the same art with nothing attached.
- **Records exit:**
  - `exit_art` and `_draw_exit`, which draws an open doorway with rects (records_room.gd 124-128)
  - Main's lift-away tween (main.gd 1819-1824) and the reset in `_sync_records_room`
- All of these share: a collision body that shuts only while active and closed, art for each state, a front lip drawn over the actors and registered as a pillar, a leaf that slides up inside a clipped doorway over a passage, an open tween with a "landed" callback, a burst, and reflections.
- Main also works out the follow limit from the door's left face for each door separately (`_wolf_follow_max_x`, main.gd 2926-2931; `M0State.JUNCTION_DOOR_LEFT_X`).
- About 260 lines.

### 2.7 Hazard floor bands
- `_draw_blast_zone` (1143-1156), `_draw_floor_mark` (1210-1231) and `_draw_alcove_floor` (1052-1057) each draw a stripe band along FLOOR_Y, a wash over the walkway and a vertical post at each end, ±10-12 px, 2 px wide.
- The hazard tests are split across mechanisms: an Area2D Hazard (vent, cloud), static range tests (`PressureLine.is_on_vent` / `is_in_blast`, `DropArm.in_cloud`, `SentryBrain.is_exposed`) and Main's `_settle_safe`. The vent is tested twice, once by the Area2D over the grate and once by `is_on_vent` over the grate ±14.

### 2.8 Station tables and reach checks (the same numbers in 4-5 places)
- Records 190/520/830 appear in `RecordsRoom._ready` and its labels, `RECORDS_STATIONS`, `_machine_spans`, `_interact_records` and `_context_hint`. Each is in main.gd 4-5 times, and reach 58 is typed again each time.
- Corridor 350 and 876 appear in the tscn positions, `CORRIDOR_STATIONS`, `_machine_spans`, `_at_breaker`, `_interact`, `_context_hint` and the tutorial check.
- The junction reach of 52 is retyped in `_interact_junction`, `_junction_hint` and `_hold_station`.
- There are 23 `absf(x - N) <= R` style checks in main.gd.
- Half widths drift between tables: `CORRIDOR_STATIONS` has the breaker at 38 and spans have 38.5. Records has 56 vs 57.1, 45 vs 44.6 and 38 vs 37.8.
- Junction station geometry is spread over about 40 constants (`*_X`, `*_REGION`, `*_SCALE`, `*_HALF_WIDTH`, `*_LABEL_SHIFT`).

### 2.9 Per-room setup and Main's per-room plumbing
- The RoomDepth build is written twice in code (records 45-56, junction 397-410) and once as tscn exports.
- Main lists the rooms by hand in several places:
  - `_room_depths`, `_apply_effects` (per-room and per-glow), `_sync_room_lights`, `_on_reduced_motion_changed`
  - the floor-reflection gathering (466-469)
  - per-room visibility in `_sync_records_room` / `_sync_junction_room`
  - the four corridor show/hide lists
- Main copies state into the rooms field by field (`_sync_records_room` 2808-2826, `_sync_junction_room` 2735-2755).

### 2.10 Particle setup
- In the junction, `_build_particles` and the particle half of `_build_lane` run about 90 lines (565-670). Main's `_setup_particles` adds about 20 (671-689).
- Each block repeats the same pattern: a preset, a rect emission shape with extents, a few overrides, z 3, then add_child.

### 2.11 Small repeats
- Colour literals: `#a4f0c4` x8, `#b0d1de` x7, `#8fa6b2` x7, `#8be3ff` x7, `#f3ae4b` x6, `#ffc7c7` x4, `#1b2630` x4, `#c1f4d8` x3, `#4a6572` x3. The same colour is named differently in each file (AMBER, SPARK_AMBER, EYE_PATROL; STEEL_DARK and a literal).
- The tween guard `if t != null and t.is_valid(): t.kill()` appears about 16 times (junction 6, room_depth 4, sentry 2, bypass 1, main and impact).
- Pipe and conduit drawing: `_draw_bolt_feed` (1072-1079), the bypass pipe and post (bypass_handle.gd 189-200) and the arm rods (1188-1190) all draw a dark body, a 1 px steel highlight, a core and clamps.
- The crank accumulator is in both `HoldUse.advance` and `PressureLine.crank`.
- The x-velocity mover is in both `M0Actor._approach` and `Sentry._physics_process`.

## 3. Proposed components (what each owns)

Each component should be a small `class_name` script built in code, as the rooms are today. They can become `.tscn` scenes later. Pixels, fonts, colours and z-order stay as they are now, so the UI looks the same.

### Palette (const-only class, no runtime cost)
- **Owns:** AMBER, GREEN, STEEL, STEEL_DARK, DIM, SEAM_RED, LABEL_TEXT (#b0d1de), LABEL_MUTED (#8fa6b2), LABEL_ALERT (#ffc7c7), CYAN (#8be3ff), EXIT_GREEN (#c1f4d8), PLATE_BG, PLATE_EDGE.
- **Replaces:** about 60 literals in 8 files.

### FxKit (static shared resources)
- **Owns:** a cached radial glow texture, one shared additive CanvasItemMaterial, the soft square and soft radial textures, the dot textures (8 and 16), the fade ramp, and the contact-shadow texture.
- **Callers that switch to it:** `RoomDepth.make_glow`, `FxPresets`, `FloorReflection._make_shadow`, `JunctionRoom.soft_texture`.
- **Optional extra:** `FxPresets.place(particles, parent, pos, extents, z)`, to make the junction and main particle blocks table-driven.

### NamePlate (Label subclass) and one PlateFader
- **Owns:**
  - caption, tint, `anchor` (centre x, top y), font size, an optional plate StyleBox (one shared static instance), wrap width and foot
  - `set_state(text, color)`, which re-fits and re-centres
  - `register` with the room's fader
- **PlateFader:** one node that holds the station plates of the room in play and runs `edge_alpha` once a frame. It replaces the four `_process` copies and `Main.EdgeFader`.
- **Keeps:** `JunctionRoom.edge_alpha` as a static used in follow_spacing_test.gd:253, or a re-export of it.
- **Covers:** the junction plates, the Records names, the corridor's three scene labels, the bypass plate and COOLANT FAULT tag, and the LINE caption.

### StatusLamp (Sprite2D, or Node2D while the old art remains)
- **Owns:**
  - the socket rect in the prop's source pixels and its world placement (through `prop_rect`)
  - `color` and the lit or dim alpha
  - an optional glow child (shared texture and material)
  - joining an `&"status_glow"` group so the effects switch hides all glows with one group call instead of the hand list
- **With Look 2 art:** it becomes the `status-lamp-<station>.png` sprite tinted by `modulate`.
- **Replaces:**
  - Records: PURGE and MIRROR lights and glows
  - Junction: breaker, arm-panel, bolt-panel and the two hatch lamps
  - Corridor: the breaker and relay ColorRects and glows
- **Hook:** colour rules stay in each room as a `Callable` or as a `refresh` that sets `lamp.color`.

### Station (Resource or RefCounted data, plus an optional node)
- **Owns:** `id`, `center_x`, `half_width` (worked out from the prop's region times scale, or from the D=4 art's opaque width), `reach`, `side` (-1/0/1), the prop texture/region/scale or a Look 2 file, the label spec, and the lamp spec.
- **The Room exposes:**
  - `stations` and `station_at(x) -> Station`
  - `machine_spans()`
- **What it removes in Main:** `*_STATIONS` Vector4 tables, `_room_stations`, `_machine_spans`, `_station_offset` / `_station_side_x` inputs, and the 23 literal reach checks. Main asks `room.station_at(x).id`.
- **Asset swap:** half widths come from the art, so a swap moves the hitboxes and follow spans with it. That is what ask (2) needs.

### HazardZone (Node2D)
- **Owns:**
  - an x-span (min, max) and an optional widened "body" span (±HUMAN_HALF_WIDTH)
  - `armed` and `reason` (the knockdown card), `contains(x)`
  - an optional drawn band (stripes, wash, end posts, colour and pulse source, honouring Reduced Motion)
  - an optional timed arm (`arm_for(seconds)`), replacing `_hazard_tween`
- **Covers:** the vent grate, the blast zone, the coolant cloud, plus the alcove and floor brackets as non-hurting bands that use the same draw path.
- **Hurtbox note:** the world is a single floor, so the Area2D could be replaced by `contains(engineer_x)`, checked in the room tick. That removes physics monitoring, the deferred `set_active` toggles and the double vent test. If tests must keep `vent_hazard.armed` and `cloud_hazard.armed` (junction_test), keep those property names.

### Door / Shutter (Node2D)
- **Owns:**
  - the collision body (layer 2), enabled only while `active and not open`
  - `face_x` (the left face, also used for the follow limit)
  - the art layers: a frame per state (sealed, open, and for the junction armed, breaking, blown); the leaf (the SealLeaf mechanism: a clipped doorway polygon or rect); the passage behind; the front lip drawn over the actors and registered in `RoomDepth.pillars`
  - the lamp (a StatusLamp)
  - `open_to(amount, seconds)`, `blast()` and the `opened` / `landed` signals
  - the dust and spark bursts and their positions
  - its floor reflections
- **Replaces:** the corridor Door node block and its code, seal_leaf.gd, `JunctionRoom._build_door`, `door_blast`, `_show_door`, `HatchDoorway`, `bolt_arc` and `_sync_hatch`, the junction entry hatch, and the Records exit lift and `_draw_exit`.
- **Asset fit:** the approved shutter concepts (doors-shutter-approved) are full scenes. The game-ready layers are still to be drawn, so make the component layer-driven (frame, leaf or shutter, lip, passage, lamp). Drop-in layers then need no code change. The superseded look2-hq/doors set used the same layering (frame, leaf, front lip, passage), which supports the shape.

### TurnWheel (Sprite2D)
- **Owns:** the wheel texture or cut, `steps_per_rev`, `step` (turns with a 0.18 s tween; snaps at 0), and Reduced Motion.
- **Used by:** the junction valve and BypassHandle.
- **Note:** the WHEEL_MASK shader is only needed while the old valve art is used. Look 2 ships `junction-valve-wheel.png`, plus `junction-valve-gauge.png` and `junction-valve-needle.png`. The needle can be a sprite rotated by `display_gauge`, which replaces `_draw_gauge`.

### Room (base class for CorridorRoom, RecordsRoom and JunctionRoom)
- **Owns:**
  - the exported depth spec (far, mid and near textures, walkway_y, far_drop, lamps, shaft_lamps, warning_lamps, base_color), building its RoomDepth
  - `stations`, `props` (`add_prop()` does z, add_child and reflection in one step), `floor_reflections`, its PlateFader registration, and `doors`
  - `set_active(bool)`: visible, door bodies, hazards, fader, and stopping reflection processing
  - `effects_enabled` and `reduce_motion` passed down to depth, glows, sentry and bypass
  - `set_lockdown_cleared`
  - `apply_state(M0State)` in place of Main's field-by-field copies
  - the virtual `refresh_state()`
- **Main then keeps:** `rooms := {"lockdown": corridor, "records": records, "junction": junction}` and loops over it in `_apply_effects`, `_sync_room_lights`, `_on_reduced_motion_changed`, visibility and reflections.
- **Corridor:** move the loose corridor nodes out of main.tscn into a CorridorRoom: purge display, breaker, relay, safe point, lamps, labels, door, bypass, relay spark, and the intro gate and cage if wanted. The four show/hide lists become `corridor.set_stations_visible(bool)`. The relay, bypass and corridor rules can stay in Main at first; only the visuals move.

## 4. How this meets ask (2): replacing the assets

- Look 2 props are uniform D=4 (0.25 scale), on padded canvases with the baseline at row H-9.
- Most `*_REGION` and `*_SCALE` constants then collapse to one PROP_SCALE plus a baseline. Today there are 10 different prop scales: 0.225, 0.2, 0.14, 0.15, 0.206, 0.274, 0.239, 0.291, 0.07 and 0.22.
- The constants that collapse:

  | file | constants |
  |---|---|
  | junction | BREAKER_, VALVE_, VENT_, ARM_, TANK_, ARM_PANEL_, BOLT_PANEL_, HATCH_ REGION and SCALE |
  | records | PURGE_, MIRROR_, EXIT_ |
  | main.tscn | the 4 corridor props |
  | sentry | ACTIVE_ and WRECK_ REGION, ART_SCALE, TREAD_X (Look 2: tread centre x 130 for all 3 states) |

- Attach points (lamp sockets, wheel and gauge centres, shackle and lug) are in the batch's `parts.json`. A single PropSpec table (one script or `.tres`), read by Station and StatusLamp, means swapping the art is a data change.
- Must be re-measured on swap:
  - `VALVE_WHEEL_CENTRE` / `RADIUS` and `VALVE_DIAL_*`
  - the `*_LIGHT` rects
  - `Sentry.LENS` and `WRECK_HULL_TOP`
  - `DOOR_SEAM_X`, `HATCH_LEAF`, and `BULKHEAD_PILLAR_X` / `WIDTH`
  - SealLeaf `LEAF` / `DOORWAY`
- Scripts that `preload` old prop files, which will need new paths:
  - junction_room.gd: 15 textures
  - records_room.gd: 3
  - sentry.gd: 2
  - main.gd: 3 corridor bulkhead files
  - main.tscn: purge display, breaker, relay, safe point, bulkhead sealed, and the provisional characters and title art
- `bypass_handle.gd` uses `JunctionRoom.VALVE_PROP`, so it changes with the valve.
- The containment cage is procedural and has no asset.

## 5. Performance notes (towards a faster, lighter game on phones)

1. **The junction redraws every frame.** `sync_line`, `sync_arm` and `sync_bolt` each call `queue_redraw()` without a condition, and `sync_bolt` also redraws `Recesses`. Main calls all three on every junction frame (main.gd 2281, 2337-2339). The fix is dirty flags: redraw only when the mirrored values change. Most frames nothing changes.
2. **All ~23 FloorReflections run `_process` every frame,** in hidden rooms too. Their parents' visibility does not stop processing, and `source.visible` stays true. Most sources are static props, so they could mirror once and only refresh on visibility or tween changes. Alternatively, Room `set_active(false)` could call `set_process(false)` on its reflections.
3. **About 80 GradientTexture2D are baked at startup,** with only about 6 distinct shapes, and there are about 15 separate additive materials. Sharing them through FxKit cuts startup CPU, VRAM and draw-batch breaks in GL Compatibility.
4. **The edge fade runs in 4 nodes.** Each inverts the canvas transform every frame. One PlateFader per frame is enough.
5. **`_refresh_ui` runs every frame** (main.gd `_process`) and sets the corridor art modulates, ColorRect colours and glow modulates each time (3000-3006). That work belongs in a state-change refresh (StatusLamp `color` setter with an early-out).
6. **`refresh_state` re-fits every label** on any change (`get_combined_minimum_size`). With NamePlate `set_state`, only plates whose text changed are re-fitted.
7. **Particles:** the junction holds 9 CPUParticles2D, mostly idle, which is fine. The shared dot texture and ramp save allocations. RoomDepth already stops dust in hidden rooms.
8. **Hazard Area2Ds:** two areas with physics monitoring, plus deferred toggles. A 1-D `contains(x)` check is cheaper and simpler.
9. **Shaders:** the WHEEL_MASK Shader is compiled twice (two `Shader.new()`). A shared preloaded `.gdshader`, or dropping it with the Look 2 wheel sprite, removes one compile.
10. **Code size:** the repeats above add up to roughly 900-1,100 lines across main.gd, junction_room.gd, records_room.gd, bypass_handle.gd and seal_leaf.gd. The components that replace them come to roughly 450-550 lines. Net about -500 lines; this is an estimate, not measured.

## 6. Risks and constraints

- **Tests reach deep into room internals.** junction_test, sentry_test, follow_spacing_test, room_depth_test, room_lights_test, m0_scene_test and chapter_scene_test reference:
  - `room.valve_label.text`, `breaker_label`, `door_art.visible`, `door_breaking_art`, `door_blown_art`, `door_lip.modulate` / `z_index`, `door_shape.disabled`, `door_visual`
  - `vent_hazard.armed` / `get_child`, `cloud_hazard.armed`, `station_labels`, `seam_glow`, `vent_glow.modulate`, `line_caption`, `tank_label`, `hatch_open`, `display_gauge`, `gauge_tripped`
  - `seal_leaf.open` / `visible`, `bypass_handle.bypass_label` / `coolant_hiss` / `ticks` / `done`
  - `JunctionRoom.edge_alpha`
  
  Renaming them means rewriting the tests. Keep those names as properties or aliases on the new components, or update the tests in the same change.
- **UI parity:**
  - The plates differ per room (plate or none, font 12, 13 or 8, label rows at y 320, 309 and 313). Unifying them must keep each style, or Nathanial must approve the change.
  - The follow and label spacing tests measure label edges against the view at zoom 1.35 and 1.55 (CHAPTER_CLOSE comment in main.gd). A plate that moves by 1 px can fail them.
- **Z-order is load-bearing:**
  - stations at z 1, with glows and plates at z 0 under the actors (ACTOR_Z 2)
  - the door lip at 2 or 3 over the actors
  - floor reflections at absolute -2
  - RoomDepth layers at absolute -4, -3 and 3
  
  The components must carry z explicitly.
- **Branch in flight:** codex/logic-round-3 (scratchpad/wt-r3) is changing junction staging and the opening hatch, which overlaps `HatchDoorway`, `bolt_arc`, `_draw_hatch_lamp` and the junction parts of main.gd. Do the Door and Room refactor after it merges, or expect conflicts in junction_room.gd and main.gd.
- **Behaviour equivalence:**
  - Merging `PressureLine.crank` into HoldUse ticks changes an EPSILON boundary: PressureLine uses `>= TURN_SECONDS - EPSILON` and HoldUse uses `>= TICK_SECONDS`. Frame-sliced timing tests may notice.
  - Replacing the Hazard Area2D with x-range checks changes when contact fires (the physics frame vs the process frame) and `armed`'s re-emit-on-arm behaviour.
- **Reduced Motion and the effects switch:** the seam strobe, fault-tag pulse, vent flash, blast stripes, lamp flicker and glow visibility must all still follow both switches through the new components. The seam glow is a readout, not decoration, and must stay visible with effects off.
- **Save compatibility:** M0State is not touched by any of this. Keep `JUNCTION_DOOR_LEFT_X` and `HUMAN_HALF_WIDTH` values (save validation uses them) even if world geometry moves to Room or Door.
- **Validation:** none of this is play-validated. Any refactor needs a headless test run, rendered stills of each room at play and chapter-close framings, and a hands-on play of corridor, Records and Junction. Phone framing (touch camera y 392) must be included, because the plates sit near view edges there.
- **Old asset deletion** (ask 2) must also update `assets/manifest.json`. The PropSpec table must not point at files that have been deleted.

## 7. Suggested order (small, playable steps)

1. Palette and FxKit (shared textures and material). No visual change, and the quickest perf win.
2. NamePlate and PlateFader: move all four fade copies and five label builders onto them, keeping each room's style.
3. StatusLamp: move the corridor ColorRects, the Records lights and the junction lights onto it, and take the lamp updates out of the per-frame `_refresh_ui`.
4. Dirty-flag redraws in the junction. Reflections stop processing in inactive rooms.
5. Station data and `room.station_at(x)`: remove the tables and literal reach checks from Main.
6. Room base: the corridor becomes a CorridorRoom, and Main loops over its room dictionary.
7. Door/Shutter (after round 3 merges): the corridor seal, junction blast door, junction hatches and Records exit.
8. The Look 2 asset swap through the PropSpec table (D=4, `parts.json` sockets), with TurnWheel and the needle sprite. Then delete the old props and mask shader and update the manifest.
