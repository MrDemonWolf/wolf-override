extends Node2D
class_name JunctionRoom
## Blowback: the Service Junction, the third 960 px room after the Records exit, built from its own
## layered set (RoomDepth) and painted station props, with the corridor's breaker and a blast door
## in a cross-wall across the walkway (BLAST_WALL). What the art cannot show is drawn over it
## here from the state the parent mirrors in (PressureLine, DropArm, SentryBrain): the LINE gauge's
## needle, the vent glow and the door's status lamp, the hazard stripes over the door's blast zone
## while the fuse burns, the breaker's light and the TANK RELEASE and exit bolt panels' lights, the
## floor brackets (lit while the sentry's body is inside them) with the tank's shadow and the winch
## cable. Every door's lamps, door lights and exit sign are DoorKit's live nodes, so _draw draws
## nothing of them. Station
## names sit on small plates in one row of clear wall (the vent's on the floor by its grate), and a
## plate cut by the edge of the view fades out rather than show part of its name. What pulses follows
## the mirrored state (the fuse, the gauge), not a timer of its own.

## The exit door has finished sliding open into its pocket after the bolt arcs (bolt_arc).
signal hatch_opened

const JUNCTION_FAR: Texture2D = preload("res://assets/rooms/junction-far.png")
const JUNCTION_MID: Texture2D = preload("res://assets/rooms/junction-mid.png")
const JUNCTION_NEAR: Texture2D = preload("res://assets/rooms/junction-near.png")
## The station props are whole pieces of the approved art set (2026-10-16), each painted with its lights
## and screens dark, so every lamp, gauge face and glow is drawn here over it.
const BREAKER_PROP: Texture2D = preload("res://assets/props/breaker.png")
## The VALVE's pump body with its wheel shaft bare: the handwheel (BypassHandle.HANDWHEEL, the same
## piece as the corridor's MANUAL BYPASS) is its own sprite on the shaft, so only the wheel turns.
const VALVE_PROP: Texture2D = preload("res://assets/props/valve-body.png")
## The blast door: a hinged steel leaf (2.3 x 2.6 m, 0.30 m) in a 0.40 m cast-concrete cross-wall that
## stands ACROSS the walkway, its face turned 17 degrees to the camera like the corridor's door end,
## drawn from the whole pieces of the approved art set (2026-10-16; its doors/DESIGN.md D8). Behind the
## mid plate: once blown, the light through the doorway onto the lane in the far plate (BLAST_HOLE),
## then BLAST_WALL (the wall's face with its 0.18 m channel frame, head, dog keepers, far hazard band,
## reveal and threshold). Under the actors: the shut leaf filling the hole frame to frame, the breaking
## leaf, the soot round the blown doorway (drawn in code). Over them: BLAST_FRONT (the near jamb with
## its three hinge knuckles and hazard band, the column and its stub across the deck; BLAST_FRONT_BLOWN
## once the knuckles are torn off) with the status lamp and, once blown, the leaf lying in the lane.
const BLAST_WALL: Texture2D = preload("res://assets/doors/blast-wall.png")
const BLAST_FRONT: Texture2D = preload("res://assets/doors/blast-front.png")
const BLAST_FRONT_BLOWN: Texture2D = preload("res://assets/doors/blast-front-blown.png")
const BLAST_SLAB: Texture2D = preload("res://assets/doors/blast-slab.png")
const BLAST_SLAB_BREAKING: Texture2D = preload("res://assets/doors/blast-slab-breaking.png")
const BLAST_SLAB_DOWN: Texture2D = preload("res://assets/doors/blast-slab-down.png")
## Each piece's world top-left (the art set's doors.py piece_box plus the manifest offset).
const BLAST_WALL_AT: Vector2 = Vector2(419.36, 0.0)
const BLAST_FRONT_AT: Vector2 = Vector2(487.94, 0.0)
## The opening on the wall's face, foot to head (doors.py W(a, h, 0) at a -1.725 and 0.575 m, h 0 and
## 2.6 m): its far jamb's foot behind the walk line and its near jamb's in front of it.
const BLAST_HOLE: PackedVector2Array = [Vector2(491.32, 452.62), Vector2(465.93, 436.03), Vector2(465.93, 333.52), Vector2(491.32, 343.90)]
const FAR_JAMB_FOOT: Vector2 = Vector2(465.93, 436.03)
const NEAR_JAMB_FOOT: Vector2 = Vector2(491.32, 452.62)
## The lane's light through the blown doorway (added, est.: tuned on rendered captures; sealed, no light
## shows round the leaf, so the shut door never reads as ajar), the door light's pool and graze and its
## wall pack's lens (doors.py surface_lights and emitters).
const BLAST_HOLE_LIGHT: Color = Color(0.30, 0.34, 0.36)
## Once blown, the lane's light also falls on the doorway's far reveal (the steel-lined throat of the 0.40
## m wall, doors.py "far jamb reveal", which is part of BLAST_WALL and draws over the hole's light), so
## the lit opening reads its whole width, not just the 10 px strip between the reveal and the near
## column (capture review, 2026-10-18: the doorway was only 1.26 times the wall's brightness). Added over
## the wall piece (est., tuned on rendered captures).
const BLAST_REVEAL: PackedVector2Array = [Vector2(465.93, 436.03), Vector2(481.1, 435.21), Vector2(481.1, 333.0), Vector2(465.93, 333.52)]
const BLAST_REVEAL_LIGHT: Color = Color(0.16, 0.18, 0.19)
## Both lights fall off from the lit lane floor toward the head (DoorKit.hole_light's head_share): flat
## from foot to head the reveal's light read as a pale grey slab still standing in the doorway, its
## square top under the dark head (capture review r2, 2026-10-19). The hole keeps some light at its
## head, as the corridor seal's (SEAL_HOLE_HEAD_SHARE); the reveal's head, in the shadow of the
## doorway's head, is left unlit (est., tuned on rendered captures).
const BLAST_HOLE_HEAD_SHARE: float = 0.35
const BLAST_REVEAL_HEAD_SHARE: float = 0.0
## The reveal's painted steel is lit evenly from foot to head, so unlit at its head it still read as a
## grey slab: it is also multiplied down toward the head to this share (DoorKit.shade's head_share),
## falling into the head's shadow so it reads as the throat of the wall, lit from the lane's floor
## (est., tuned on rendered captures).
const BLAST_REVEAL_SHADOW: float = 0.4
const BLAST_POOL: Vector2 = Vector2(486.05, 443.64)
const BLAST_GRAZE: Vector2 = Vector2(473.53, 374.20)
const BLAST_DOOR_LIGHT: Vector2 = Vector2(461.24, 321.08)
## The status lamp's live glass on the column's end face (its socket and guard are painted on the front).
const BLAST_LAMP: Vector2 = Vector2(503.174, 357.773)
## The shut leaf (blast-slab, 103 x 475 px at 4 px per world px, painted as seen from the room) drawn
## stretched over the hole's box from frame to frame, as the art set's review frames warp it: no light
## shows round it. Its top-left and its x and y scales (world px per piece px).
const LEAF_AT: Vector2 = Vector2(465.93, 333.52)
const LEAF_SCALE: Vector2 = Vector2(25.39 / 103.0, 119.10 / 475.0)
## The breaking leaf (blast-slab-breaking, 107 x 475 px at 4 px per world px), where the earlier
## breaking leaf stood (its manifest offset 0.25 world px down), and the leaf lying in the lane
## (blast-slab-down, 547 x 107 px at 2.002 px per world px, 273 x 53 world px), set down on the deck as
## the approved art set's frames show it (the art set's compose.py: at 0.75 of its size, its bottom on
## the deck's nosing at y 449 less its own 0.5 px offset, in the deck's blue cast). The deck now ends 9 px
## in front of the walk line, so the earlier spot (in front of it) hung the slab off the walkway's front
## edge; it lies under the actors, who walk the lane in front of it. Its tone (capture review,
## 2026-10-18): toned down to the deck's own value it read as a shadow on the deck, so it keeps most of
## its painted value, a step lighter than the deck, and reads as a steel slab lying there.
const LEAFBREAK_AT: Vector2 = Vector2(465.0, 333.25)
const LEAFBREAK_SCALE: float = 0.25
const LYING_AT: Vector2 = Vector2(482.74, 404.79)
const LYING_SCALE: float = 0.75 / 2.002
const LYING_TONE: Color = Color8(205, 215, 232)
## Soot and heat tint round the empty doorway once it is blown (the art set dropped the painted scorch
## and crack lines: code soot instead, compose.py's two patches, centre and radii in world px; the
## upper, lighter one drawn smaller, as DoorKit.soot's patches are all as dark at their centre).
const SOOT: Array = [[Vector2(492.0, 380.0), Vector2(30.0, 70.0)], [Vector2(492.0, 330.0), Vector2(11.0, 25.0)]]
const VENT_PROP: Texture2D = preload("res://assets/props/relief-vent.png")
## The overhead arm: its ceiling plate, the arm, the winch drum and the shackle the tank's cable hangs
## from (the cable itself is drawn, _draw_arm). The tank is its own piece, so it can fall away.
const ARM_PROP: Texture2D = preload("res://assets/props/tank-arm.png")
const TANK_PROP: Texture2D = preload("res://assets/props/coolant-tank.png")
const ARM_PANEL_PROP: Texture2D = preload("res://assets/props/arm-panel.png")
const BOLT_PANEL_PROP: Texture2D = preload("res://assets/props/bolt-panel.png")
## The entry (review r1, M5; design: 1cf8d73:docs/research-2026-10/sources/doors-2026-10-14/junction-entry/): the
## engineer comes in from the service line passage the Records exit opens on, through a 3'0" x 7'0"
## hollow-metal steel door in a 300 mm cast cross-wall closing the room's left end, turned 17 degrees
## across the walkway like every door end of the base, in this room's camera (vanishing point (511,
## 162)). Its leaf swings into the junction on its hinges at the far jamb (SwingLeaf), its closer
## bringing it shut behind the arriving pair. Its pieces are whole pieces of the approved art set
## (2026-10-16; doors/DESIGN.md D7): behind the mid plate the lit passage (ENTRY_BACK) and the wall's
## face (ENTRY_WALL); over the mid plate the leaf and the near column (ENTRY_FRONT) with the lamp:
## nobody passes behind the column (the leaf stops them at ENTRY_DOOR_X).
const ENTRY_BACK: Texture2D = preload("res://assets/doors/junction-entry-back.png")
const ENTRY_WALL: Texture2D = preload("res://assets/doors/junction-entry-wall.png")
const ENTRY_FRONT: Texture2D = preload("res://assets/doors/junction-entry-front.png")
const ENTRY_BACK_AT: Vector2 = Vector2(-10.0, 0.0)
const ENTRY_WALL_AT: Vector2 = Vector2(16.24, 0.0)
const ENTRY_FRONT_AT: Vector2 = Vector2(-10.0, 0.0)
## The opening on its face (doors.py W(a, h, 0) at a -0.46 and 0.46 m, h 0 and 2.14 m), the passage's
## light added through it (est., tuned on rendered captures), the door light's pool, graze and lens.
const ENTRY_HOLE: PackedVector2Array = [Vector2(18.92, 443.26), Vector2(40.82, 436.82), Vector2(40.82, 352.20), Vector2(18.92, 356.65)]
const ENTRY_HOLE_LIGHT: Color = Color(0.05, 0.06, 0.07)
const ENTRY_POOL: Vector2 = Vector2(24.82, 439.68)
const ENTRY_GRAZE: Vector2 = Vector2(35.69, 385.79)
const ENTRY_DOOR_LIGHT: Vector2 = Vector2(48.76, 339.61)
## The entry leaf's fill (fix round 4, review r4 M1; see RecordsRoom.EXIT_LEAF_FILL).
const ENTRY_LEAF_FILL: float = 0.0880
## Where the shut leaf's junction face crosses the walk line: the door's collision face. Left of WOLF's
## tail at his spot by the entrance (WOLF_CLEAR_X - M0Actor.WOLF_REACH, x 72.9).
const ENTRY_DOOR_X: float = 30.0
## The guarded status lamp on the near column's end face, world px: the centre of its live glass
## (jedesign.py's status_lamp_screen, in junction-entry/design/entry/spec.json).
const ENTRY_LAMP: Vector2 = Vector2(6.8, 345.2)
## The leaf's hinge axis (foot, metres: x along the room, h up, d behind the walk line) and its wall's
## plan axes (U along the face toward the back wall, N into the wall), from jedesign.py (spec.json's
## hinge_foot_m, axis_u and axis_n), as RecordsRoom's come from rdesign.py.
const ENTRY_HINGE: Vector3 = Vector3(0.89597, 0.0, 0.43639)
const ENTRY_AXIS_U: Vector3 = Vector3(0.292372, 0.0, 0.956305)
const ENTRY_AXIS_N: Vector3 = Vector3(-0.956305, 0.0, 0.292372)
## The lights the leaf sees, as they light the wall round it (jedesign.py), in the leaf's own exposure
## (fix round 4, review r4 M1; see RecordsRoom.EXIT_LEAF_LIGHTS): the door light, the room's left ceiling
## lamp, the wet deck's bounce (fill), the threshold and passage deck through the doorway and the cross-wall's
## lit face beyond the hinge jamb.
const ENTRY_LEAF_LIGHTS: Array = [
	[Vector3(0.8456, 2.8000, -0.0292), Vector3(1.7065, 1.8847, 1.9843), 1.40, 2.0, 0.00],  # the door light over the head (the design's: reach 1.4 m, down 2.0; true Lambert)
	[Vector3(1.9461, 5.2370, 4.2000), Vector3(0.6570, 0.9537, 1.0597), 3.40, 1.5, 0.06],  # the room's ceiling lamp
	[Vector3(2.7500, 0.1000, -3.0000), Vector3(0.0550, 0.0750, 0.0850), 4.00, 0.0, 0.06, true],  # the broad floor bounce (fill)
	[Vector3(0.4755, 0.0300, 0.0871), Vector3(0.3002, 0.3316, 0.3491), 0.90, 0.0, 0.05],  # the lit threshold and passage deck seen through the doorway
	[Vector3(1.0467, 1.4000, 0.8609), Vector3(0.3697, 0.4083, 0.4299), 1.00, 0.0, 0.05],  # the cross-wall's own lit face beyond the hinge jamb
]
## Its closer brings it shut behind them a moment after they come in, as the Records entry's does
## (SwingLeaf.close_behind); its lamp is amber while it moves, red once it latches (Palette.AMBER,
## Palette.LAMP_SHUT).
## The exit: a power-operated sliding steel door in a cast-concrete cross-wall at the room's right end,
## turned 17 degrees across the walk line like the corridor's door end (its approach face crosses the
## walk line at EXIT_DOOR_X). Its leaf runs in the wall's middle on bottom rollers and slides back into
## a pocket in the far jamb. Whole pieces of the approved art set (2026-10-16; doors/DESIGN.md D9),
## behind the mid plate: the lit service passage with the pocket mouth, floor guide and threshold
## (EXIT_BACK), the light through the hole, the leaf (SlideLeaf, junction-exit-leaf, sliding into the
## pocket), then the wall's face with the operator header over the opening and the pocket, the frame
## head and the door light fitting (EXIT_WALL). Over the mid plate: the status lamp on the header, lit
## in the exit bolt's colour, the door light and the exit sign. Over the actors (they walk out behind
## it): the wall's near end (EXIT_FRONT, x 971..1050), its narrow face strip to the near jamb, its cut
## end face and the curb across the deck. The passage and the near end run on past the room's right
## edge (the art set's fix sheet D05, 2026-10-18), so the view reaches EXIT_VIEW_RIGHT and the whole
## doorway, both jambs and the passage beyond it stand in the frame.
const EXIT_BACK: Texture2D = preload("res://assets/doors/junction-exit-back.png")
const EXIT_WALL: Texture2D = preload("res://assets/doors/junction-exit-wall.png")
const EXIT_FRONT: Texture2D = preload("res://assets/doors/junction-exit-front.png")
const EXIT_LEAF_ART: Texture2D = preload("res://assets/doors/junction-exit-leaf.png")
## Each piece's world top-left (the art set's doors.py piece_box plus the manifest offset): the passage
## 918.27 + 0.5 and the near end 970.14 + 1.0 (sheet D05), the wall's face 869.83 + 0.5 (sheet D02).
const EXIT_BACK_AT: Vector2 = Vector2(918.77, 0.0)
const EXIT_WALL_AT: Vector2 = Vector2(870.33, 0.0)
const EXIT_FRONT_AT: Vector2 = Vector2(971.14, 0.0)
## The room deck in front of the cross-wall runs on under the near end's curb past the room's edge: the
## mid plate's deck rows from here down (world y; the plate is opaque from y 444 at its right end) are
## mirrored on past x 960 as far as the view reaches (RoomDepth.deck_bleed).
const EXIT_DECK_TOP_Y: float = 444.0
## The passage seen past the exit wall's near end (EXIT_BACK right of the column's far arris, x 1000.1, down
## to its floor's near edge, doors.py "next space floor"), shaded (DoorKit.PAST_END_SHADE) so it never
## outshines the doorway; the column covers its left edge and the curb its foot. While the exit is shut
## it is multiplied down by EXIT_SHUT_SHADE as well, as the doorway's reveal is: at PAST_END_SHADE alone
## the passage floor beside the wall's end stayed the brightest opening at the shut exit (capture review
## r2, 2026-10-19: luma 0.228 against the shut doorway's 0.136 and the wall's 0.122).
const EXIT_PAST_END: PackedVector2Array = [Vector2(1000.1, 0.0), Vector2(EXIT_PAINTED_RIGHT, 0.0), Vector2(EXIT_PAINTED_RIGHT, 457.8), Vector2(1000.1, 443.1)]
## When the exit is shut no light comes through it: its reveal in front of the leaf (lit by the passage
## when open) is multiplied down to this (doors.py's shut frames: the far reveal one step under the wall),
## and the light through the hole is off, so only the lamp and the sign are left to tell shut from open
## at a glance. It eases to nothing as the leaf opens (est., tuned on rendered captures).
const EXIT_SHUT_SHADE: Color = Color(0.42, 0.45, 0.48)
## The sliding leaf's tone: DoorKit.LEAF_TONE at 0.7. It runs in the wall's middle, 0.27 m back in the
## dark reveal, and at the shared tone the shut leaf read 1.8 times the wall round it, almost as light as
## the open doorway (capture review, 2026-10-18; est., tuned on rendered captures).
const EXIT_LEAF_TONE: Color = Color(0.43, 0.47, 0.505)
## The opening on the face (doors.py W(a, h, 0) at s -0.4 and 1.6 m, h 0 and 2.4 m), the passage's light
## through it (est., tuned on rendered captures; the room's goal, so brighter than the entry's), the
## door light's pool, graze and lens, the status lamp on the header and the flag exit sign over the
## head (doors.py sign_at: its bracket 0.21 m along the face).
const EXIT_HOLE: PackedVector2Array = [Vector2(971.31, 442.83), Vector2(926.56, 429.24), Vector2(926.56, 336.96), Vector2(971.31, 345.85)]
const EXIT_HOLE_LIGHT: Color = Color(0.12, 0.14, 0.15)
const EXIT_POOL: Vector2 = Vector2(959.69, 435.18)
const EXIT_GRAZE: Vector2 = Vector2(937.65, 373.35)
const EXIT_DOOR_LIGHT: Vector2 = Vector2(919.17, 324.80)
const EXIT_LAMP: Vector2 = Vector2(913.0, 325.75)
const EXIT_SIGN: Rect2 = Rect2(941.98, 330.38, 13.91, 8.50)
## The sliding leaf's size (metres, geom.py at 1cf8d73: 2.15 x 2.47 x 0.12 m).
const EXIT_LEAF_SIZE: Vector2 = Vector2(2.15, 2.47)
## The near plate's pipe column is 100 world px wide in the room against the corridor's 57, so its
## strips hang that much further past the room edges.
const NEAR_OVERHANG: float = RoomDepth.NEAR_OVERHANG + 43.0
## Each prop is one whole piece cut to its painted outline; its base sits on the floor. Sizes are the
## pieces' own pixel sizes (assets/manifest.json) and scales are world px per piece px: 1 / the piece's
## density, or for the real-size pieces (the art set's PIECES.md section 5c) its real-size scale.
## The breaker is drawn the same in the corridor (main.tscn BreakerArt), so both rooms show one machine:
## 303 x 388 px at 4 px per world px (75.75 x 97 world px, 1.9 x 2.4 m).
const BREAKER_SIZE: Vector2 = Vector2(303.0, 388.0)
const BREAKER_SCALE: float = 0.25
## The breaker's lamp bar: the glass of the slot over its handle, piece px (measured on breaker.png).
const BREAKER_LAMP: Rect2 = Rect2(110.0, 57.0, 60.0, 12.0)
## The lamp bar of a breaker centred on x 0 with its base on the floor (world px): a room adds its
## breaker's x (the corridor's BreakerStatusLight too, Main).
const BREAKER_LIGHT_AT: Rect2 = Rect2((BREAKER_LAMP.position.x - BREAKER_SIZE.x * 0.5) * BREAKER_SCALE, FLOOR_Y - (BREAKER_SIZE.y - BREAKER_LAMP.position.y) * BREAKER_SCALE, BREAKER_LAMP.size.x * BREAKER_SCALE, BREAKER_LAMP.size.y * BREAKER_SCALE)
## The valve body: 409 x 395 px at 4 px per world px (102.25 x 98.75 world px).
const VALVE_SIZE: Vector2 = Vector2(409.0, 395.0)
const VALVE_SCALE: float = 0.25
## The bare wheel shaft (the handwheel's hub goes here) and the LINE gauge's glass (centre and radius),
## piece px, measured on valve-body.png.
const VALVE_SHAFT: Vector2 = Vector2(203.0, 211.0)
const VALVE_DIAL_CENTRE: Vector2 = Vector2(204.0, 42.0)
const VALVE_DIAL_RADIUS: float = 30.0
## The blast door's front (BLAST_FRONT, BLAST_FRONT_BLOWN once blown) draws over the actors
## (DOOR_FRONT_Z) in every door state. In the rows a body lying on the floor fills (Main.COLLAPSE_TOPS),
## the painting of either piece runs from its left edge (DOOR_COLUMN_FOOT piece px) to its piece column
## DOOR_COLUMN_RIGHT (the column's cut end; measured on both pieces), so it covers
## DOOR_FOOT_X..DOOR_FOOT_RIGHT_X of the room there (junction_test measures both). Its stub across the
## deck starts below the floor line, so it never covers a lying body. A slump that would reach under the
## column ends short of it on either side (Main._start_collapse).
const DOOR_COLUMN_FOOT: float = 0.0
const DOOR_COLUMN_RIGHT: float = 44.0
const DOOR_FOOT_X: float = BLAST_FRONT_AT.x + DOOR_COLUMN_FOOT * DoorKit.PIECE_SCALE
const DOOR_FOOT_RIGHT_X: float = BLAST_FRONT_AT.x + DOOR_COLUMN_RIGHT * DoorKit.PIECE_SCALE
## How long the breaking leaf shows at the blast before the blown doorway replaces it.
const DOOR_BREAK_SECONDS: float = 0.15
## Fix round 4 (review r4 C2, human r4): the leaf is thrown, not swapped. After DOOR_BREAK_SECONDS the torn
## leaf leaves its doorway into the lane, tipping over as it flies (SDI 133 / ASTM F2927 Category IV: the
## door separates from its frame and becomes flying debris), and lands where it then lies, raising dust off
## the wet deck. World px: its centre from the doorway to the lying leaf's body (LEAFBREAK_AT and
## LYING_AT), how high it rises on the way, how far it turns (nearly flat) and how much it grows on the
## way (it turns toward the camera as it tips; it lands on the deck at LYING_SCALE).
const DOOR_FLIGHT_SECONDS: float = 0.24
const DOOR_FLIGHT_FROM: Vector2 = Vector2(479.3, 389.7)
const DOOR_FLIGHT_TO: Vector2 = Vector2(585.2, 424.8)
const DOOR_FLIGHT_RISE: float = 18.0
const DOOR_FLIGHT_TURN: float = 1.5
const DOOR_FLIGHT_GROW: float = 1.22
## The share of the flight after which the leaf is clear of the near column and draws in front of it.
const DOOR_FLIGHT_CLEAR: float = 0.3
## The relief vent: 288 x 177 px, its floor grate the piece's whole width (vent_scale).
const VENT_SIZE: Vector2 = Vector2(288.0, 177.0)
## The tank arm at its real size (PIECES.md 5c, k 0.75: 340 x 310 px at 5.333 px per world px, 63.75
## x 58.1 world px; its winch drum was twice a real one's size). It hangs with its shackle over the
## mark (ARM_SHACKLE), its ceiling plate's top at ARM_TOP_Y, where the earlier arm's plate hung, so the
## rods from the gantry keep their length.
const ARM_SIZE: Vector2 = Vector2(340.0, 310.0)
const ARM_SCALE: float = 0.1875
const ARM_TOP_Y: float = 220.5
## The foot of the arm's shackle (piece px), where the tank's cable hangs from, and the two bolt blocks
## on its ceiling plate the rods come down to (piece x), measured on tank-arm.png.
const ARM_SHACKLE: Vector2 = Vector2(140.0, 310.0)
const ARM_ROD_XS: PackedFloat32Array = [35.0, 265.0]
## The coolant tank: 184 x 334 px at 4 px per world px (46 x 83.5 world px, its size before).
const TANK_PIXELS: Vector2 = Vector2(184.0, 334.0)
const TANK_ART_SCALE: float = 0.25
## The ARM PANEL: 199 x 260 px at 4 px per world px; its lamp's glass in piece px.
const ARM_PANEL_SIZE: Vector2 = Vector2(199.0, 260.0)
const ARM_PANEL_SCALE: float = 0.25
const ARM_PANEL_LIGHT: Rect2 = Rect2(73.0, 35.0, 52.0, 13.0)
## The EXIT BOLT's floor junction box at its real size (PIECES.md 5c, k 0.822: 241 x 185 px at 4.866 px
## per world px, 49.5 x 38 world px, 1.24 x 0.95 m), its lamp's glass and the row its painted cable
## ends meet the feed's cable box at (piece px, measured on bolt-panel.png).
const BOLT_PANEL_SIZE: Vector2 = Vector2(241.0, 185.0)
const BOLT_PANEL_SCALE: float = 1.0 / 4.8662
const BOLT_PANEL_LIGHT: Rect2 = Rect2(104.0, 21.0, 31.0, 13.0)
const BOLT_PANEL_CABLES_Y: float = 74.0
## The cross-wall and its door, in metres (the design's geometry, tools/geom.py): the approach face
## crosses the walk line at EXIT_DOOR_X; s runs along the wall toward the room's back, n through it
## toward the passage. The camera is the junction's own (review r1, C1: vanishing point (511, 162), as
## the blast door's, measured from the deck seams; the walk line 38 m from the eye, 40 px per metre).
const EXIT_DOOR_X: float = 962.0
const EXIT_VPX: float = 511.0
const EXIT_HORIZON: float = 162.0
const EXIT_WALL_ANGLE: float = 17.0
const EXIT_LEAF_N: float = 0.27
const EXIT_LEAD_SHUT_S: float = -0.5
const EXIT_LEAD_OPEN_S: float = 1.62
## Where the near jamb's edge stands on screen (s -0.4 on the approach face): anyone whose drawn body is
## all right of it has gone through, behind the wall.
const EXIT_NEAR_JAMB_X: float = 971.3
## Where the shut leaf's room face meets the walk line (world px; about 973.3, a little right of
## EXIT_NEAR_JAMB_X). The leaf runs in the wall's middle, its room face EXIT_LEAF_N m in from the
## approach face, and that face, turned EXIT_WALL_ANGLE off square to the walk line, crosses it
## EXIT_LEAF_N / cos(EXIT_WALL_ANGLE) m past EXIT_DOOR_X, at the walk line's DoorCamera.PX_PER_M. The
## reveal in front of it is open floor. door_route_test and wolf_space_test both measure the shut exit
## from here (EXIT_SHUT_SPAN), so a change to the wall's geometry moves both.
const EXIT_LEAF_SHUT_X: float = EXIT_DOOR_X + DoorCamera.PX_PER_M * EXIT_LEAF_N / cos(deg_to_rad(EXIT_WALL_ANGLE))
## The exit doorway's far jamb on the walk line (world px): junction-exit/NOTES.md, "Opening" (far jamb
## x 925.5, near jamb x 971.6 at the floor), in the doors records
## (1cf8d73:docs/research-2026-10/sources/doors-2026-10-14/). The near side is the game's own EXIT_NEAR_JAMB_X.
const EXIT_FAR_JAMB_X: float = 925.5
## The open exit's doorway on the walk line (world px, x from..to): far jamb to near jamb. No game code
## reads it; door_route_test measures resting spots and the walk-out against it, like RecordsRoom's
## EXIT_SPAN and ENTRY_SPAN.
const EXIT_SPAN: Vector2 = Vector2(EXIT_FAR_JAMB_X, EXIT_NEAR_JAMB_X)
## The shut exit on the walk line (world px, x from..to): only the line at the leaf's room face
## (EXIT_LEAF_SHUT_X). That face lies a little right of the near jamb's edge and the reveal in front of
## it is open floor, so a body crosses the shut door only where it covers that line; maxf keeps the
## span from running backwards if the geometry ever puts the face left of the jamb. door_route_test and
## wolf_space_test both read it, so neither derives its own.
const EXIT_SHUT_SPAN: Vector2 = Vector2(EXIT_LEAF_SHUT_X, maxf(EXIT_LEAF_SHUT_X, EXIT_NEAR_JAMB_X))
## The junction's camera may show this far right (Main), as on main before the art swap: past the near
## jamb (EXIT_NEAR_JAMB_X) and the wall's near end into the passage beyond, so the whole doorway reads in
## the frame (the art swap's capture review, 2026-10-18: stopping at the room's edge left 40 screen px of
## it). The exit's pieces (EXIT_BACK, EXIT_FRONT) are painted to x 1050 and the deck mirrored on as far,
## which covers a camera shake (Impact.MAX_SHAKE_PX, 10) at this edge. The actors may walk on through
## the doorway to EXIT_WALK_MAX_X: on down the passage, out of view behind the wall, far enough that
## WOLF's body and the engineer's never share the same floor.
const EXIT_VIEW_RIGHT: float = 1030.0
## How far right the exit's pieces are painted (the art set's doors.py ROOM_X_WIDE): the view's reach,
## a camera shake and 10 px spare.
const EXIT_PAINTED_RIGHT: float = 1050.0
const EXIT_WALK_MAX_X: float = 1100.0
## WOLF in the open doorway, looking back at the engineer: his head, shoulders and forelegs in view on
## the threshold, his hindquarters already past the near jamb and hidden by it. Fix round 2 (review r2,
## human pass): at x 985 his rear stood out past the near column (x 971.5..1000 at his height) in the
## stub's cutaway, against the passage, so the jamb cut him in half; here his painted tail tip
## (M0Actor.WOLF_TAIL, the art mirrored) stays at x 990, behind the column's edge at x 1000, where it
## was before he was drawn at a real wolf's size (x 934 then).
const WOLF_DOORWAY_X: float = 990.0 - M0Actor.WOLF_TAIL
## The engineer is at the exit from here (USE leaves through it), and walks no further while WOLF
## stands in the doorway (his tail at WOLF_DOORWAY_X - M0Actor.WOLF_REACH, less the
## M0Actor.ARRIVE_TOLERANCE short of it that he may rest, coming from his spot by the hatch).
## (fix round 2: 846, was 870, so the engineer can stand behind WOLF in his new spot, their back clear
## of the bolt panel's edge but for STATION_OVERLAP)
const HATCH_REACH_MIN_X: float = 846.0
const HATCH_REACH_MAX_X: float = WOLF_DOORWAY_X - M0Actor.ARRIVE_TOLERANCE - M0Actor.WOLF_REACH - M0Actor.HUMAN_REACH
## Walking out, each is gone once their whole drawn body is past the near jamb.
const WOLF_GONE_X: float = EXIT_NEAR_JAMB_X + M0Actor.WOLF_REACH + 3.0
const HUMAN_GONE_X: float = EXIT_NEAR_JAMB_X + M0Actor.HUMAN_REACH + 3.0
## The breaker's status light lies on the lamp bar's glass over its handle (BREAKER_LIGHT_AT).
const BREAKER_LIGHT: Rect2 = Rect2(BREAKER_LIGHT_AT.position + Vector2(BREAKER_X, 0.0), BREAKER_LIGHT_AT.size)
## Station centres, left to right.
const BREAKER_X: float = 200.0
const VENT_X: float = 300.0
const VALVE_X: float = 420.0
const DOOR_X: float = 480.0
## The rubble line is the sentry's lane boundary.
const RUBBLE_X: float = SentryBrain.RUBBLE_X
## Half the drawn width of the machines the actors must not stand inside.
const BREAKER_HALF_WIDTH: float = BREAKER_SIZE.x * BREAKER_SCALE * 0.5
const VALVE_HALF_WIDTH: float = VALVE_SIZE.x * VALVE_SCALE * 0.5
const ARM_PANEL_HALF_WIDTH: float = ARM_PANEL_SIZE.x * ARM_PANEL_SCALE * 0.5
const BOLT_PANEL_HALF_WIDTH: float = BOLT_PANEL_SIZE.x * BOLT_PANEL_SCALE * 0.5
## The TANK RELEASE stands at the left end of the alcove that hides the engineer from the sentry, just
## inside its left post, so the engineer works it from beside it, inside the cover (Main's
## JUNCTION_STATIONS).
const ARM_X: float = SentryBrain.COVER_MIN_X + ARM_PANEL_HALF_WIDTH + 2.0
## The exit bolt's panel stands on the floor left of the exit door, the riser on its right running down
## into a floor flange (drawn in the exit's back layer). The engineer works it from its left, facing it
## (BOLT_X), clear of the downed sentry; its USE reaches from BOLT_REACH_MIN_X rightward, and once the
## door is open the way out answers from HATCH_REACH_MIN_X.
## (fix round 2: 796, was 806: 10 px further from the door, so the engineer has room at the open door
## behind WOLF in the doorway; its riser moves with it, in the exit's back layer)
const BOLT_PANEL_X: float = 796.0
## (6 px: the engineer's front hand over the panel's edge, Main.STATION_OVERLAP.)
const BOLT_X: float = BOLT_PANEL_X - BOLT_PANEL_HALF_WIDTH - M0Actor.HUMAN_REACH + 6.0
const BOLT_REACH_MIN_X: float = BOLT_X - 16.0
## The walk line's floor, world y: RoomDepth's, the one definition every room and door stands on.
const FLOOR_Y: float = RoomDepth.FLOOR_Y
## Where WOLF stands to read the line on entry: on the valve's left, facing it, his snout at the
## valve's edge below its LINE gauge, so he never stands inside the machine. There is no floor at the
## door itself: the valve stands right in front of it, and the only gap between the breaker and the
## valve (the idle relief vent's grate, 33 px of bare floor) is far shorter than his body, so the
## narration names the gauge he reads, not the door (Main.JUNCTION_ENTRY_LINE).
const WOLF_SEAM_X: float = VALVE_X - VALVE_HALF_WIDTH - M0Actor.WOLF_REACH - 2.0
## Where WOLF holds back from the rubble line while the engineer deals with the lane (or after he breaks
## off drawing the sentry): the nearest clear floor to it, his reading spot by the valve. Between the
## valve and the rubble line the valve, the blown door's near column and the engineer at CHOICE_X leave
## no floor as long as he is, so any nearer spot would stand him inside them.
const WOLF_RUBBLE_X: float = WOLF_SEAM_X
## Doors fix round 2 (review r2, human pass: "WOLF stands inside the valve"): wherever his body would
## pass over the valve after the blast (walking by it on the way down the lane or back), he steps out
## onto the deck in front of it, about 1.3 m nearer the camera: his drawn body this much lower on the screen (the deck
## in this camera falls 9.3 px per metre toward the camera at the walk line), so his feet stand clearly
## in front of the valve's base and he draws over it. He is all the way forward within WOLF_STEP_FULL of
## the valve's middle and eases back over WOLF_STEP_RAMP, onto the walk line just as his painted snout
## (M0Actor.WOLF_SNOUT) clears the valve's edge (60 px when he was drawn 0.70x larger, ending 7 px
## inside it), so at his reading spot by the valve (WOLF_SEAM_X) he stands on the walk line.
const WOLF_STEP_FORWARD: float = 12.0
const WOLF_STEP_FULL: float = 40.0
const WOLF_STEP_RAMP: float = VALVE_HALF_WIDTH + M0Actor.WOLF_SNOUT - WOLF_STEP_FULL
## Where WOLF stands when he chooses to draw the sentry: at the far end of its lane, in front of the
## exit hatch (a doorway in the back wall, not a machine), facing back down the lane, his painted snout
## (M0Actor.WOLF_SNOUT) at x 848, 27 px clear of the bolt panel's right edge as it was before he was
## drawn at a real wolf's size, and his painted tail (M0Actor.WOLF_TAIL) inside the room's right edge;
## the spot is x 887.2 (SentryBrain.BAIT_OFFSET holds the number). It parks BAIT_OFFSET short of him,
## on the mark, facing him with its back to the TANK RELEASE, so the engineer working the release is
## behind it and never between the two; his drawn body stays far outside the floor brackets and the tank.
const WOLF_BAIT_X: float = DropArm.MARK_X + SentryBrain.BAIT_OFFSET
## Where WOLF waits once the sentry is down, through the bolt and the closing beat: the same spot, in
## full view by the hatch he says is next, clear of the crushed sentry and the tank on it.
const WOLF_DOWN_X: float = WOLF_BAIT_X
## Crossing the lane to his spot, WOLF bounds over the live sentry rather than through it
## (wolf_leap_height): his painted feet (y 438) clear its drawn top (Sentry.FLOOR_Y less
## Sentry.DRAWN_HEIGHT, y 396) by 6 px at the top of the bound, held while his legs are over its body
## (LEAP_CLEAR: the two bodies' contact range, SentryBrain.HALF_WIDTH plus M0State.WOLF_HALF_WIDTH, and a
## 5 px margin) and eased in and out over LEAP_RAMP either side, where only his snout or tail passes its
## low treads. LEAP_RAMP is short enough that the ramp ends before the sentry's patrol turn short of
## him at his spot by the hatch (M0Actor.WOLF_REACH + SentryBrain.HALF_WIDTH + Main.WOLF_SENTRY_GAP,
## 74 px from his centre; LEAP_CLEAR + LEAP_RAMP is 73), so he never lifts while it patrols up to him
## (30 px when he was drawn 0.70x larger). He runs LEAP_SPEED_SCALE times faster meanwhile, so it reads
## as a bound, not a hover. The
## tank's base (y 382 at most) is lower than the top of his head at the bound, so he never bounds under
## it: the sentry he draws backs off ahead of him to the end of its patrol (SentryBrain.BAIT_OFFSET)
## and he catches it there, and the bound and both ramps stay clear of the hanging tank's painted body
## by a few px (sentry_test measures the two images).
const LEAP_HEIGHT: float = 48.0
const LEAP_CLEAR: float = SentryBrain.HALF_WIDTH + M0State.WOLF_HALF_WIDTH + 5.0
const LEAP_RAMP: float = 20.0
const LEAP_SPEED_SCALE: float = 2.0
## Running under the hung tank on his way down the lane, WOLF needs no duck: at a real wolf's size
## (Main.WOLF_ART_SCALE, 2026-10-19) the tips of his ears (y 396.6) pass 14 px under the tank's rounded
## base (y 382 at its lowest). Drawn 0.70x larger before, they stood at y 379 and he ran crouched under
## it (sentry_test still measures the two images).
## Once the tank is down on the sentry, WOLF crossing from his spot by the valve to his spot by the hatch bounds
## clean over the crushed tank and the wreck under it in one arc (wolf_tank_leap_height): a parabola in
## x, so at his steady LEAP_SPEED_SCALE speed it is a fall under constant gravity, TANK_LEAP_HEIGHT at
## its top over TANK_LEAP_PEAK_X and back on the floor TANK_LEAP_HALF_SPAN either side. The arc was set
## when he was drawn 0.70x larger (134 px long with his reach) and is kept at his real size (88 px):
## the tank stands 107 px over the floor about 60 px past the engineer working the release, and the
## parked arm's shackle hangs only some 20 px above the height that clears the tank, so there is no
## room for a short hop: he takes off before he reaches the engineer's back, passes over them on the
## way up and lands just short of his spot. Its top is 13 px left of the tank's middle (the mark): it
## was 5 when his spot by the hatch was x 904, and moved 8 with that spot (to 887.2, SentryBrain.BAIT_OFFSET)
## so he still lands at least 20 px short of it (sentry_test). His painted feet (y 438) pass over the
## tank's top (y 331, on the crushed hull) and his back under the shackle. The empty arm hangs too low over
## the tank for him to pass under it, so it winches up into its ceiling plate as the tank lands for good
## (ARM_PARK_RISE over ARM_PARK_SECONDS), and he waits by the valve until it is up. sentry_test measures
## his painted body against the tank's, the wreck's and the arm's images on every frame of the crossing
## and at every x (3 px clear).
const TANK_LEAP_HEIGHT: float = 122.0
const TANK_LEAP_PEAK_X: float = DropArm.MARK_X - 13.0
const TANK_LEAP_HALF_SPAN: float = 180.0
const ARM_PARK_RISE: float = 44.0
const ARM_PARK_SECONDS: float = 0.3
## Where WOLF waits while the line builds and the fuse burns: back by the entrance hatch, his painted
## snout (M0Actor.WOLF_SNOUT) 6 px short of the breaker's left edge, as it was before he was drawn at a
## real wolf's size (x 100 then), so he is not inside the breaker, his drawn body is clear of the engineer working it from its right, his tail
## stays in view while they crank the valve, and he is nowhere near the relief vent's grate, its
## steam or the door's blast zone.
const WOLF_CLEAR_X: float = BREAKER_X - BREAKER_HALF_WIDTH - 6.0 - M0Actor.WOLF_SNOUT
## The engineer's front foot on the rubble line: where the question of how to drop the tank comes up,
## still outside the sentry's lane.
const CHOICE_X: float = RUBBLE_X - M0State.HUMAN_HALF_WIDTH
## The tank hangs centred here and lands with its base on the floor. At the play framing (zoom 1.35,
## camera y 360) its top (y 298) sits at screen y ~186, below the answer buttons
## (Main.CHOICE_ROW_TOP), and its base (y 382) clears the sentry's scanner fin (Sentry.DRAWN_HEIGHT)
## as it patrols underneath.
const TANK_REST_Y: float = 340.0
const TANK_SIZE: Vector2 = TANK_PIXELS * TANK_ART_SCALE
## The middle of the tank's shadow: on the floor stripes under it.
const SHADOW_Y: float = FLOOR_Y + 1.0
## The arm's ceiling plate hangs on two rods from the mid plate's overhead gantry (its underside).
const GANTRY_Y: float = 120.0
## The exit door slides open this long after the bolt arcs.
const HATCH_OPEN_SECONDS: float = 0.5
## The sealed door body is this wide; its left face is M0State.JUNCTION_DOOR_LEFT_X.
const DOOR_WIDTH: float = 56.0
const DOOR_HEIGHT: float = 132.0
## The door's pieces under the actors draw at DOOR_Z (over the mid plate, under the props); the front
## and the lying leaf at DOOR_FRONT_Z, over the actors (this node sits at z 1), so they pass through the
## doorway behind the near column.
const DOOR_Z: int = -3
const DOOR_FRONT_Z: int = 2
## The status lamp on the column: red shut, amber while the line builds, flashing red and white
## through the fuse (steady red with Reduced Motion), dark once the door is down: Palette.LAMP_SHUT,
## Palette.AMBER, SEAM_RED and white, and this.
const LAMP_DEAD: Color = Color(0.16, 0.17, 0.18)
## The vent's steam and its burst draw one step under the props (the grate is a prop), so the grate is
## drawn over the steam rising out of it.
const VENT_STEAM_Z: int = -2
## How long the grate stays dangerous after the relief vent lets go.
const HAZARD_SECONDS: float = 0.4
## The knockdown cards, in the third person like the narration; each is formatted with the engineer's
## first name.
const VENT_REASON: String = "The relief vent let go under %s. When the gauge peaks, stay off the grate."
const BLAST_REASON: String = "The door went with %s in front of it. When the fuse lights, back away past the valve."
## SENTRY_REASON is for an engineer it spotted and ran down out in the open, which is always past the
## cover beside the TANK RELEASE (SentryBrain.is_exposed); it points at the drawn release, not at an
## alcove or posts the picture does not show (P0-7, approved 2026-10-13). Once it has turned on them
## after a miss, or reaches them at the release, that cover is no help and SENTRY_CHASED_REASON says
## so. Both are two rows.
const SENTRY_REASON: String = "The sentry saw %s out in the open.\nStay close to the TANK RELEASE."
const SENTRY_CHASED_REASON: String = "The sentry ran %s down. Once its\neyes go red, only the rubble is safe."
const CLOUD_REASON: String = "The coolant cloud caught %s. Let it clear before crossing the mark."
const COOLANT: Color = Color("#7fe8ff")
const SEAM_RED: Color = Color("#ff6a55")
## The tank's cable, in the tones of the cable painted on the arm's winch drum.
const CABLE_SHADOW: Color = Color("#0d1419")
const CABLE_BODY: Color = Color("#35434c")
const CABLE_SHEEN: Color = Color(0.55, 0.64, 0.7, 0.55)
## Station name plates: their top edge, all in one row of clear wall between the far plate's pipe run
## and the machines' tops, and their text size. At 310 (it was 320) the DOOR plate's bottom (y ~324)
## clears the blast door's head frame (its top at y 326 over the far jamb, doors.py "frame head"), so the
## blown doorway shows its whole height (capture review, 2026-10-18).
const LABEL_Y: float = 310.0
const LABEL_FONT_SIZE: int = 12
## The VALVE plate sits this far left of the wheel so its longest text ends well before the door.
const VALVE_LABEL_SHIFT: float = 28.0
## The breaker's plate sits this far left of the breaker, and the RELIEF VENT plate this far left of
## the grate's centre, so the vent's name fits between the longest breaker and valve texts.
const BREAKER_LABEL_SHIFT: float = 12.0
const VENT_LABEL_SHIFT: float = 3.0
## The door's placard is centred over the doorway's head.
const DOOR_LABEL_X: float = 479.0
## The TANK RELEASE plate sits right of the panel, clear of the door's column and its placard.
const ARM_LABEL_SHIFT: float = 20.0
## The EXIT plate sits over the bolt panel, left of the hatch it also names.
const EXIT_LABEL_X: float = 792.0
## The feed from the TANK RELEASE to the exit bolt panel runs under the floor and comes up at the
## bolt panel (_draw_bolt_feed), so nothing runs across the lane where the tank comes down. Its cable
## box is centred on the row of the panel's painted cable ends (BOLT_PANEL_CABLES_Y), behind them. Dead
## while the winch holds the tank; once the tank is down its power runs to the bolt (amber), warming to
## white through the whine and green once the bolt drops.
## The cable box (behind the three painted cable ends, which span 88 piece px, 18 world px, of the
## panel's left edge, plus 2 px either side) and the floor gland the conduit comes up from.
const FEED_BOX: Vector2 = Vector2(8.0, 22.0)
const FEED_GLAND: Vector2 = Vector2(12.0, 3.0)
## The box's and gland's painted-steel face, a step lighter than the conduit.
const FEED_STEEL: Color = Color("#2a3741")
## A plate fades out over this many px as it reaches the edge of the view.
const LABEL_EDGE_FADE: float = 14.0
const VENT_LABEL: String = "RELIEF VENT"
## The glow over the vent grate, warming with the gauge, flashing red through its hard warning and red
## once it has tripped.
const VENT_GLOW_SIZE: Vector2 = Vector2(96.0, 22.0)
## The vent's hard warning flashes this many times a second (steady with Reduced Motion).
const VENT_FLASH_HZ: float = 5.0
## After the vent lets go the needle stays pinned at the top, red, for HAZARD_SECONDS (and through a
## knockdown, when nothing advances it), then falls back to empty over this long.
const GAUGE_FALL_SECONDS: float = 0.8
## The caption beside the valve's dial, the gauge the narration names.
const LINE_CAPTION: String = "LINE"
const LINE_CAPTION_FONT_SIZE: int = 8
## The hazard stripes over the door's blast zone pulse this many times a second while the fuse burns
## (steady with Reduced Motion): once per fuse tick, peaking with it, and at no more than 2 Hz, so even
## the longer fuse stays well under three flashes a second (A11Y-2).
const BLAST_STRIPE_HZ: float = 1.0 / PressureLine.FUSE_TICK_SECONDS
## The floor brackets glow this colour while the sentry's body is inside them.
const MARK_LIT: Color = Color("#ffe9a8")
## The alcove is painted: a recessed bay whose two steel posts stand on SentryBrain.COVER_MIN_X and
## COVER_MAX_X, so where cover stops (the right post) shows beside an engineer at the TANK RELEASE.
## A refused press (Main._refuse) or a bump into the sealed door: the station's lamp goes dark for
## FLICKER_STEP_SECONDS and comes back, twice for a press and once for a bump. The door's status lamp is
## barely lit at rest, so its flicker lights it up between the dark steps. With Reduced Motion the lamp
## goes dark once and comes back, with no repeat.
const FLICKER_STEP_SECONDS: float = 0.07
const FLICKER_DARK: Color = Color("#1a2228")
const SEAM_FLICKER_ALPHA: float = 0.75
## Hint ladder T1: the breaker's lamp pulses while WOLF looks at it, this many times a second (at most
## 2 Hz, well under three flashes a second; steady and bright with Reduced Motion).
const BREAKER_PULSE_HZ: float = 1.5

## Ceiling lamp centres as fractions of the far plate, measured from the plate; the lockdown
## beacons sit on the tops of its two braced pillars.
var lamps: PackedVector2Array = PackedVector2Array([Vector2(0.139, 0.268), Vector2(0.493, 0.268), Vector2(0.857, 0.268)])
var warning_lamps: PackedVector2Array = PackedVector2Array([Vector2(0.294, 0.285), Vector2(0.703, 0.285)])

# Mirrored from the parent's state and PressureLine; the parent calls sync_line()/refresh_state().
var line_state: StringName = &"idle"
var gauge: float = 0.0
var turns: int = 0
## How far into the next turn a hold at the valve has its wheel (HoldUse.shown_fraction), 0 while it
## is not held. Set through show_crank.
var crank_fraction: float = 0.0
var door_blown: bool = false
var sentry_down: bool = false
var junction_cleared: bool = false
## Mirrored from DropArm: its state and how far down the tank is (0 hanging, 1 on the floor), and
## whether a missed tank still lies on the floor before the winch takes it (DropArm.on_floor).
var arm_state: StringName = &"hung"
var tank_drop: float = 0.0
var tank_on_floor: bool = false
## Mirrored from PressureLine: seconds left on the fuse, which drives the blast stripes' pulse.
var fuse_remaining: float = 0.0
## The needle's reading: the gauge while it builds, pinned at the top for a while after the vent lets
## go (gauge_hold seconds left), then falling back; gauge_tripped draws it red meanwhile.
var display_gauge: float = 0.0
var gauge_hold: float = 0.0
var gauge_tripped: bool = false
## 0 with the arm hanging where it holds the tank, 1 once it has winched up into its ceiling plate
## after the tank came down on the sentry (ARM_PARK_RISE).
var arm_parked: float = 0.0:
	set(value):
		arm_parked = value
		if arm_art != null:
			arm_art.position.y = arm_rest_y - ARM_PARK_RISE * arm_parked
			queue_redraw()
## Mirrored from Main's exit bolt: locked, charging (0..1 through the whine) or open.
var bolt_state: StringName = &"locked"
var bolt_charge: float = 0.0
## 0 shut, 1 open; slides once after the bolt arcs.
var hatch_open: float = 0.0:
	set(value):
		hatch_open = value
		_sync_hatch()
## Reduced Motion: the charged door lamp holds steady instead of flashing.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		if is_node_ready():
			_sync_lamp()

var depth: RoomDepth
var breaker_art: Sprite2D
var valve_art: Sprite2D
var vent_art: Sprite2D
var arm_art: Sprite2D
## Where the arm hangs while it holds the tank (its centre's y).
var arm_rest_y: float = 0.0
var arm_panel_art: Sprite2D
var bolt_panel_art: Sprite2D
## The entry door (see ENTRY_BACK): its swinging leaf, its lamp, its collision body and the closer's
## tween.
var entry_leaf: SwingLeaf
var entry_lamp: DoorKit.Lamp
var entry_door_shape: CollisionShape2D
var entry_tween: Tween
## The exit door's pieces (see EXIT_BACK): its sliding leaf, its wall's face and its status lamp.
var exit_leaf: SlideLeaf
var exit_wall: Sprite2D
## The wall's near end (EXIT_FRONT), over the actors; the shade on the reveal while the exit is shut
## (EXIT_SHUT_SHADE) and the light through its hole.
var exit_front: Sprite2D
var exit_shade: Polygon2D
var exit_hole: Polygon2D
## The shade on the passage seen past the wall's near end (EXIT_PAST_END), darker while the exit is shut.
var exit_past_end: Polygon2D
var exit_lamp: DoorKit.Lamp
var recesses: Recesses
## The exit bolt's panel drawn again over the sentry where it passes behind it.
var panel_front: PanelFront
var door_body: StaticBody2D
var door_shape: CollisionShape2D
## The blast door's pieces (see BLAST_WALL): the shut leaf; at the blast the breaking leaf shows for
## DOOR_BREAK_SECONDS, then the lit empty doorway (door_hole, its light) with the soot round it and the
## leaf lying in the lane; the front (door_column) swaps to its blown piece.
var door_hole: Polygon2D
## The lane's light on the blown doorway's far reveal (BLAST_REVEAL) with its shadow toward the head (a
## child), shown with door_hole.
var door_reveal: Polygon2D
var door_leaf: Sprite2D
var door_leaf_breaking: Sprite2D
var door_wall: Sprite2D
var door_soot: Array[Sprite2D] = []
var door_column: Sprite2D
var door_leaf_down: Sprite2D
## The status lamp's live glass and its halo.
var door_lamp: DoorKit.Lamp
## True from the blast until the breaking frame gives way to the blown one.
var door_breaking: bool = false
## True while the torn leaf is in the air (DOOR_FLIGHT_SECONDS), and how far along its flight it is (0..1).
var door_flying: bool = false
var door_flight: float = 0.0
## The dust the leaf raises where it lands.
var landing_dust: CPUParticles2D
var valve_wheel: Sprite2D
var vent_steam: CPUParticles2D
var vent_puff: CPUParticles2D
var blast_sparks: CPUParticles2D
var blast_debris: CPUParticles2D
var blast_dust: CPUParticles2D
var vent_hazard: Hazard
var cloud_hazard: Hazard
var sentry: Sentry
var tank: TankSprite
var coolant_cloud: CPUParticles2D
var coolant_burst: CPUParticles2D
var hit_sparks: CPUParticles2D
var bolt_sparks: CPUParticles2D
var arm_label: Label
## TANK DOWN, over the tank once it lies on the sentry.
var tank_label: Label
## The LINE caption beside the valve's dial.
var line_caption: Label
var hatch_label: Label
var breaker_glow: Sprite2D
var vent_glow: Sprite2D
var breaker_label: Label
var valve_label: Label
var door_label: Label
## The relief vent's floor caption, on the same plate, just above its grate.
var vent_label: Label
var station_labels: Array[Label] = []
var label_plate: StyleBoxFlat
var floor_reflections: Array[FloorReflection] = []
## What this node's _draw and Recesses last drew from (draw_inputs, recesses_inputs), so the
## per-frame syncs redraw them only when something they draw has changed.
var _drawn_inputs: Array = []
var _recesses_drawn_inputs: Array = []
var _redraw_check_queued: bool = false
## The station whose lamp is flickering (breaker, valve, door, release or bolt), how far into it, and how
## many times it goes dark.
var flicker_station: StringName = &""
var flicker_elapsed: float = 0.0
var flicker_times: int = 0
## Seconds the breaker's lamp still pulses for the hint ladder, and how long it has pulsed.
var breaker_pulse_remaining: float = 0.0
var breaker_pulse_elapsed: float = 0.0
var _valve_tween: Tween
var _lamp_tween: Tween
var _door_tween: Tween
var _hazard_tween: Tween
var _hatch_tween: Tween
var _arm_tween: Tween


## The hanging coolant tank, cut from the tank-arm art, with a dent drawn on after a missed drop.
class TankSprite:
	extends Sprite2D
	var dent: Polygon2D
	var dented: bool = false:
		set(value):
			dented = value
			dent.visible = dented

	## Adds the dent, hidden until [member dented] is set; its points are the cut's own px about its centre.
	func _init() -> void:
		dent = Polygon2D.new()
		dent.name = "Dent"
		# In the cut's own pixels around its centre: a crease in the right flank of the body.
		dent.polygon = PackedVector2Array([Vector2(78.0, 30.0), Vector2(50.0, 62.0), Vector2(78.0, 92.0)])
		dent.color = Color("#14242c")
		dent.visible = false
		add_child(dent)


## What sits behind the stations: the release's feed to the exit bolt, drawn under the props (the
## room's own drawing sits over them).
class Recesses:
	extends Node2D
	var room: JunctionRoom

	## Draws the room's recesses (JunctionRoom.draw_recesses) on this node, under the props.
	func _draw() -> void:
		room.draw_recesses(self)


## The exit bolt's panel stands nearer than the sentry's lane: at the far end of its patrol the machine
## and its beam pass behind it. Right after the sentry and at its depth, this draws the panel and its
## light again wherever the sentry's drawing crosses the panel (bolt_panel_cover), with the bolt's feed
## under the panel's painted cables there too, so none of them is ever drawn under the machine, and
## draws nothing while the sentry is clear of it. Only those spots are drawn, so the engineer working the
## bolt and WOLF by the hatch still draw over the panel as before.
class PanelFront:
	extends Node2D
	var room: JunctionRoom
	## The room rectangles drawn this frame (bolt_panel_cover) and the colours they were drawn with: the
	## panel's lamp as it shows (bolt_lamp_color) and the feed's core (bolt_feed_color), so a change to
	## either redraws them.
	var cover: Array[Rect2] = []
	var colors: Array[Color] = []

	## Samples with mipmaps like the room's art, and processes after Main (priority 100), which moves the
	## sentry first.
	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		# After Main's frame, which moves the sentry, so the cover is where the sentry is drawn.
		process_priority = 100

	## Redraws only when the spots the sentry crosses the panel, or the colours they are drawn in, have
	## changed.
	func _process(_delta: float) -> void:
		var now: Array[Rect2] = room.bolt_panel_cover()
		var look: Array[Color] = [room.bolt_lamp_color(), room.bolt_feed_color()]
		if now != cover or (not now.is_empty() and look != colors):
			cover = now
			colors = look
			queue_redraw()

	## Draws the bolt panel again over the spots in [member cover], in its lamp's colour; nothing while the
	## sentry is clear.
	func _draw() -> void:
		if not cover.is_empty():
			room.draw_panel_front(self, cover, colors[0])

	## What _draw covers: the bounds of [member cover], for the debug tools' render box.
	func debug_draw_rect() -> Rect2:
		if cover.is_empty():
			return Rect2()
		var bounds: Rect2 = cover[0]
		for part: Rect2 in cover:
			bounds = bounds.merge(part)
		return bounds


## Builds the whole room once: its RoomDepth plates and lamps, the recesses, the station props (breaker,
## vent, valve with its turning wheel, tank release, bolt panel) with their glows and name plates, the
## vent hurtbox, the blast door's pieces, the entry and exit doors, the particles and the sentry's lane.
## Positions are world px.
func _ready() -> void:
	depth = RoomDepth.new()
	depth.name = "Depth"
	depth.painting = JUNCTION_FAR
	depth.mid_painting = JUNCTION_MID
	depth.near_painting = JUNCTION_NEAR
	depth.near_overhang = NEAR_OVERHANG
	depth.near_column_width = 100.0
	depth.base_color = Color("#0a0e18")
	depth.lamps = lamps
	depth.shaft_lamps = PackedInt32Array([0, 2])
	# The middle ceiling lamp is behind the blast door's cross-wall now: its glow is hidden.
	depth.painted_lamps = PackedInt32Array([1])
	depth.warning_lamps = warning_lamps
	# The room's ends are the entry's and the exit's cross-walls now, not mirrored pipe columns.
	depth.near_left_edge = false
	depth.near_right_edge = false
	add_child(depth)
	recesses = Recesses.new()
	recesses.name = "Recesses"
	recesses.room = self
	recesses.z_index = -2
	add_child(recesses)
	breaker_art = RoomDepth.make_prop("BreakerArt", BREAKER_PROP, BREAKER_SCALE, BREAKER_X)
	vent_art = RoomDepth.make_prop("VentArt", VENT_PROP, vent_scale(), (PressureLine.VENT_GRATE_MIN_X + PressureLine.VENT_GRATE_MAX_X) * 0.5)
	valve_art = RoomDepth.make_prop("ValveArt", VALVE_PROP, VALVE_SCALE, VALVE_X)
	arm_panel_art = RoomDepth.make_prop("ArmPanelArt", ARM_PANEL_PROP, ARM_PANEL_SCALE, ARM_X)
	bolt_panel_art = RoomDepth.make_prop("BoltPanelArt", BOLT_PANEL_PROP, BOLT_PANEL_SCALE, BOLT_PANEL_X)
	_build_entry()
	_build_exit()
	for prop: Sprite2D in [breaker_art, vent_art, valve_art, arm_panel_art, bolt_panel_art]:
		# One step under this node's own drawing, so the lights and readouts drawn in _draw() sit on the art.
		prop.z_index = -1
		add_child(prop)
		floor_reflections.append(FloorReflection.attach(prop))
	# Only the wheel turns: the handwheel piece on the valve's bare shaft, at its own size (1.0x).
	valve_wheel = BypassHandle.make_wheel("ValveWheel", BypassHandle.HANDWHEEL_SCALE)
	valve_wheel.position = RoomDepth.prop_point(valve_art, VALVE_SHAFT)
	valve_wheel.z_index = -1
	add_child(valve_wheel)
	breaker_glow = RoomDepth.make_glow(Palette.AMBER, Vector2(64.0, 30.0), 0.5)
	breaker_glow.name = "BreakerGlow"
	breaker_glow.position = BREAKER_LIGHT.get_center()
	# Station lights, glows, plates and captions sit at this node's own depth (z 1), under the actors
	# (Main.ACTOR_Z): someone standing at a machine is always drawn in front of all of it.
	breaker_glow.z_index = 0
	add_child(breaker_glow)
	vent_glow = RoomDepth.make_glow(Palette.AMBER, VENT_GLOW_SIZE, 0.0)
	vent_glow.name = "VentGlow"
	vent_glow.position = Vector2(VENT_X, FLOOR_Y - 6.0)
	vent_glow.z_index = 0
	add_child(vent_glow)
	_build_door()
	_build_particles()
	# The hurtbox is the grate: a body touching it is on the vent (PressureLine.is_on_vent).
	# The door blast has no hurtbox; main.gd decides it from PressureLine.is_in_blast alone.
	vent_hazard = Hazard.make("VentHazard", Rect2(PressureLine.VENT_GRATE_MIN_X, 380.0, PressureLine.VENT_GRATE_MAX_X - PressureLine.VENT_GRATE_MIN_X, 60.0), VENT_REASON)
	add_child(vent_hazard)
	label_plate = StyleBoxFlat.new()
	label_plate.bg_color = Palette.PLATE_BG
	label_plate.border_color = Palette.PLATE_EDGE
	label_plate.set_border_width_all(1)
	label_plate.set_corner_radius_all(2)
	label_plate.content_margin_left = 5.0
	label_plate.content_margin_right = 5.0
	label_plate.content_margin_top = 0.0
	label_plate.content_margin_bottom = 0.0
	# The plates keep their English text and translate as drawn (Label auto-translation); I18n.KEY.tr()
	# only marks each name for the template (localization PR L13: decision D3 translates the plates).
	breaker_label = _add_station_label(I18n.KEY.tr("OVERLOAD BREAKER"), BREAKER_X - BREAKER_LABEL_SHIFT, Palette.LABEL_TEXT)
	# In the row above the grate, where nobody standing on the floor covers it.
	vent_label = _add_station_label(I18n.KEY.tr(VENT_LABEL), VENT_X - VENT_LABEL_SHIFT, Palette.LABEL_MUTED)
	# A little left of the wheel so its longest text ends before the door.
	valve_label = _add_station_label(I18n.KEY.tr("VALVE"), VALVE_X - VALVE_LABEL_SHIFT, Palette.LABEL_TEXT)
	# A placard over the doorway's head, hung in front of the near column (above head height).
	door_label = _add_station_label(I18n.KEY.tr("SEALED DOOR"), DOOR_LABEL_X, Palette.LABEL_ALERT)
	door_label.z_index = DOOR_FRONT_Z + 1
	arm_label = _add_station_label(I18n.KEY.tr("TANK RELEASE"), ARM_X + ARM_LABEL_SHIFT, Palette.LABEL_TEXT)
	# Over the landed tank, shown only once it lies on the sentry.
	tank_label = _add_station_label(I18n.KEY.tr("TANK DOWN"), DropArm.MARK_X, Palette.LABEL_MUTED)
	line_caption = Label.new()
	line_caption.name = "LineCaption"
	line_caption.text = LINE_CAPTION
	line_caption.add_theme_color_override("font_color", Palette.LABEL_TEXT)
	line_caption.add_theme_stylebox_override("normal", label_plate)
	line_caption.z_index = 0
	add_child(line_caption)
	_place_line_caption()
	# Over the bolt panel, beside the exit door, so both read as one exit.
	hatch_label = _add_station_label("EXIT LOCKED", EXIT_LABEL_X, Palette.LABEL_MUTED)
	_build_lane()
	refresh_state()


## The relief vent is drawn exactly as wide as its grate's hurtbox (PressureLine.VENT_GRATE_*): the
## grate is the piece's whole width (0.25, its own 4 px per world px), so what is drawn is what hurts.
static func vent_scale() -> float:
	return (PressureLine.VENT_GRATE_MAX_X - PressureLine.VENT_GRATE_MIN_X) / VENT_SIZE.x


## The door: a 56x132 body on the floor layer whose face stops the engineer just short of the shut
## leaf, and the blast door's pieces (see BLAST_WALL); at the blast the leaf breaks, then the doorway
## stands empty on the lane and the leaf lies thrown beyond it.
func _build_door() -> void:
	# Off until the junction is the room in play (see set_active).
	door_shape = RoomDepth.door_body(self, "Door", Vector2(DOOR_X, FLOOR_Y - DOOR_HEIGHT * 0.5), Vector2(DOOR_WIDTH, DOOR_HEIGHT))
	door_body = door_shape.get_parent() as StaticBody2D
	# Behind the mid plate: the lane's light (once blown), the door light's pool and graze, the wall.
	door_wall = DoorKit.doorway(depth.behind, "Blast", BLAST_HOLE, BLAST_HOLE_LIGHT, null, Vector2.ZERO, 1.0, null, BLAST_POOL, BLAST_GRAZE, BLAST_WALL, BLAST_WALL_AT, BLAST_HOLE_HEAD_SHARE)
	door_hole = depth.behind.get_node("BlastHoleLight") as Polygon2D
	door_reveal = DoorKit.hole_light(depth.behind, "BlastRevealLight", BLAST_REVEAL, BLAST_REVEAL_LIGHT, BLAST_REVEAL_HEAD_SHARE)
	# Its shadow, a child so it shows and hides with the light (the shut leaf covers the reveal).
	DoorKit.shade(door_reveal, "Shadow", BLAST_REVEAL, Color.WHITE, BLAST_REVEAL_SHADOW)
	door_leaf = _door_piece("DoorLeaf", BLAST_SLAB, LEAF_AT, Vector2.ONE, DOOR_Z)
	door_leaf.scale = LEAF_SCALE
	door_leaf_breaking = _door_piece("DoorLeafBreaking", BLAST_SLAB_BREAKING, LEAFBREAK_AT, Vector2.ONE * LEAFBREAK_SCALE, DOOR_Z)
	for patch: Array in SOOT:
		var soot: Sprite2D = DoorKit.soot(self, "DoorSoot%d" % door_soot.size(), patch[0], patch[1])
		soot.z_index = DOOR_Z
		door_soot.append(soot)
	DoorKit.door_light(self, BLAST_DOOR_LIGHT).z_index = DOOR_Z
	door_column = _door_piece("DoorColumn", BLAST_FRONT, BLAST_FRONT_AT, Vector2.ONE * DoorKit.PIECE_SCALE, DOOR_FRONT_Z)
	door_lamp = DoorKit.lamp(self, "DoorLamp", BLAST_LAMP, Palette.LAMP_SHUT)
	door_lamp.z_index = DOOR_FRONT_Z
	door_leaf_down = _door_piece("DoorLeafDown", BLAST_SLAB_DOWN, LYING_AT, Vector2.ONE * LYING_SCALE, DOOR_Z)
	door_leaf_down.modulate = LYING_TONE
	_show_door()


## One whole piece of the blast door, [param texture] at [param top_left] (world px) and [param
## piece_scale] (world px per piece px, per axis), drawn at [param z]; added now, in drawing order.
func _door_piece(piece_name: String, texture: Texture2D, top_left: Vector2, piece_scale: Vector2, z: int) -> Sprite2D:
	var sprite: Sprite2D = RoomDepth.cut(texture, Rect2(Vector2.ZERO, texture.get_size()), 1.0, piece_name, top_left)
	sprite.scale = piece_scale
	sprite.z_index = z
	add_child(sprite)
	return sprite


## The entry door's pieces (see ENTRY_BACK): the lit passage and the wall's face behind the mid plate,
## then over it the leaf on its hinges with the closer's arm, the near column and its lamp, and the
## door light.
func _build_entry() -> void:
	DoorKit.doorway(depth.behind, "Entry", ENTRY_HOLE, ENTRY_HOLE_LIGHT, ENTRY_BACK, ENTRY_BACK_AT, DoorKit.BEYOND_LIFT, null, ENTRY_POOL, ENTRY_GRAZE, ENTRY_WALL, ENTRY_WALL_AT)
	var over: Node2D = _doors_over()
	entry_leaf = SwingLeaf.make("EntryLeaf", ENTRY_HINGE, ENTRY_AXIS_U, ENTRY_AXIS_N, ENTRY_LEAF_LIGHTS, ENTRY_LEAF_FILL)
	# The junction's own camera (its measured vanishing point), as the exit's.
	entry_leaf.vpx = EXIT_VPX
	entry_leaf.horizon = EXIT_HORIZON
	over.add_child(entry_leaf)
	DoorKit.piece(over, ENTRY_FRONT, ENTRY_FRONT_AT, "EntryFront")
	entry_lamp = DoorKit.lamp(over, "EntryLamp", ENTRY_LAMP, Palette.LAMP_SHUT)
	DoorKit.door_light(over, ENTRY_DOOR_LIGHT)
	# The shut leaf stops whoever walks into it: 16 px deep from its junction face, as tall as a door.
	entry_door_shape = SwingLeaf.make_body(self, "EntryDoorBody", ENTRY_DOOR_X, -1.0)


## The doors' layer over the mid plate and under the props and actors (on the mid plate's own absolute
## z, after it in the room's RoomDepth): made on first use, shared by the entry and the exit.
func _doors_over() -> Node2D:
	var over: Node2D = depth.get_node_or_null("DoorsOver") as Node2D
	if over == null:
		over = Node2D.new()
		over.name = "DoorsOver"
		over.z_as_relative = false
		over.z_index = RoomDepth.Z_MID
		depth.add_child(over)
	return over


## The entry's status lamp: amber while its closer brings the leaf shut, red once it latches.
func set_entry_lamp(color: Color) -> void:
	entry_lamp.color = color


## The entry lamp's current colour: what set_entry_lamp last set.
func entry_lamp_color() -> Color:
	return entry_lamp.color


## Coming in from the service line passage: the entry stands open behind the engineer and its closer
## brings it shut (as the Records entry's does).
func close_entry_behind() -> void:
	set_entry_lamp(Palette.AMBER)
	entry_tween = entry_leaf.close_behind(self, entry_tween, func() -> void: set_entry_lamp(Palette.LAMP_SHUT))


## The exit door's pieces (see EXIT_BACK): behind the mid plate the passage, its light, the sliding leaf
## and the wall's face; over it the status lamp, the door light and the exit sign. Its lamp and leaf
## follow the bolt.
func _build_exit() -> void:
	# First in the behind layer, so the passage and the curb draw over it where they stand.
	depth.deck_bleed("ExitDeckBleed", EXIT_DECK_TOP_Y, EXIT_PAINTED_RIGHT)
	exit_leaf = SlideLeaf.new(EXIT_LEAF_ART, EXIT_LEAF_SIZE.x, EXIT_LEAF_SIZE.y, _exit_leaf_point)
	exit_leaf.name = "ExitLeaf"
	exit_leaf.tone = EXIT_LEAF_TONE
	exit_wall = DoorKit.doorway(depth.behind, "Exit", EXIT_HOLE, EXIT_HOLE_LIGHT, EXIT_BACK, EXIT_BACK_AT, DoorKit.BEYOND_LIFT, exit_leaf, EXIT_POOL, EXIT_GRAZE, EXIT_WALL, EXIT_WALL_AT)
	exit_hole = depth.behind.get_node("ExitHoleLight") as Polygon2D
	# Over the passage and the reveal, under the leaf: the shut exit's shade.
	exit_shade = DoorKit.shade(depth.behind, "ExitShutShade", EXIT_HOLE, EXIT_SHUT_SHADE)
	depth.behind.move_child(exit_shade, exit_leaf.get_index())
	exit_past_end = DoorKit.shade(depth.behind, "ExitPastEnd", EXIT_PAST_END, DoorKit.PAST_END_SHADE)
	# The wall's near end draws over the actors (they walk out behind it), always opaque, as Records'.
	exit_front = DoorKit.piece(self, EXIT_FRONT, EXIT_FRONT_AT, "ExitFront")
	exit_front.z_index = RoomDepth.Z_NEAR
	exit_front.z_as_relative = false
	var over: Node2D = _doors_over()
	exit_lamp = DoorKit.lamp(over, "ExitLamp", EXIT_LAMP, Palette.LAMP_SHUT)
	DoorKit.door_light(over, EXIT_DOOR_LIGHT)
	DoorKit.exit_sign(over, EXIT_SIGN, 1.0)
	_sync_hatch()


## The world px of the sliding leaf's point [param along] metres from its leading edge toward its tail
## and [param h] metres up, at the door's current [member hatch_open] (SlideLeaf.place).
func _exit_leaf_point(along: float, h: float) -> Vector2:
	var lead: float = lerpf(EXIT_LEAD_SHUT_S, EXIT_LEAD_OPEN_S, clampf(hatch_open, 0.0, 1.0))
	return exit_point(lead + along, h, EXIT_LEAF_N)


## World px of the point [param s] metres along the exit's wall face toward the room's back, [param h]
## up and [param n] into the wall toward the passage, in the junction's camera (DoorCamera with the
## junction's vanishing point). x_m and z_m stay 64-bit floats up to DoorCamera.project.
static func exit_point(s: float, h: float, n: float) -> Vector2:
	var a: float = deg_to_rad(EXIT_WALL_ANGLE)
	var x_m: float = EXIT_DOOR_X / DoorCamera.PX_PER_M - s * sin(a) + n * cos(a)
	var z_m: float = s * cos(a) + n * sin(a)
	return DoorCamera.project(x_m, h, z_m, EXIT_VPX, EXIT_HORIZON)


## Where the leaf's leading-edge bottom corner stands with the door [param open] (0 shut, 1 open), and
## its depth scale there against the shut leaf's (x, y: the point; z: the scale). The leaf slides along
## the wall, back into the pocket, so it moves left and away from the camera (smaller). door_route_test
## measures the shut leaf's edge from it.
static func exit_leaf_anchor(open: float) -> Vector3:
	var a: float = deg_to_rad(EXIT_WALL_ANGLE)
	var s: float = lerpf(EXIT_LEAD_SHUT_S, EXIT_LEAD_OPEN_S, clampf(open, 0.0, 1.0))
	var z_m: float = s * cos(a) + EXIT_LEAF_N * sin(a)
	var z_shut: float = EXIT_LEAD_SHUT_S * cos(a) + EXIT_LEAF_N * sin(a)
	var p: Vector2 = exit_point(s, 0.0, EXIT_LEAF_N)
	return Vector3(p.x, p.y, DoorCamera.depth_scale(z_m) * (DoorCamera.D0 + z_shut) / DoorCamera.D0)


## Builds the vent's steam column and puff behind the grate, and the blast's sparks, chips and dust and
## the thrown leaf's landing dust at the doorway, each placed at its own z. None of them emits yet.
func _build_particles() -> void:
	# Behind the vent's grate (one step under the props) and the actors: the column rises from inside
	# the grate, which stays drawn over it, so the grate the card names reads through the steam.
	vent_steam = FxPresets.place(FxPresets.steam(), self, "VentSteam", Vector2(VENT_X, FLOOR_Y - 8.0), VENT_STEAM_Z, Vector2((PressureLine.VENT_GRATE_MAX_X - PressureLine.VENT_GRATE_MIN_X) * 0.5 - 6.0, 2.0))
	vent_puff = FxPresets.dust_burst()
	# Translucent and thin enough that the engineer, the grate and the breaker read through it.
	vent_puff.color = Color(FxPresets.STEAM, 0.3)
	vent_puff.initial_velocity_min = 160.0
	vent_puff.initial_velocity_max = 260.0
	vent_puff.spread = 30.0
	vent_puff.amount = 16
	# Like the column: out of the grate, behind it and the engineer it knocks down.
	FxPresets.place(vent_puff, self, "VentPuff", vent_steam.position, VENT_STEAM_Z, vent_steam.emission_rect_extents)
	# Steel tearing at the latch jamb, where the bolts shear: a few short, hard white-hot streaks thrown
	# into the lane, falling (FxPresets.streaks), not soft discs.
	blast_sparks = FxPresets.streaks(14)
	blast_sparks.direction = Vector2(1.0, -0.25)
	blast_sparks.spread = 40.0
	FxPresets.place(blast_sparks, self, "BlastSparks", Vector2(FAR_JAMB_FOOT.x + 2.0, FLOOR_Y - 52.0), 3, Vector2(2.0, 46.0))
	# Concrete spalled off round the frame: hard chips thrown through the doorway into the lane, tumbling
	# and falling to the deck (FxPresets.chips).
	blast_debris = FxPresets.place(FxPresets.chips(Color(0.42, 0.43, 0.45), 20), self, "BlastDebris", Vector2(DOOR_X, FLOOR_Y - 60.0), 3, Vector2(8.0, 55.0))
	# The blast's dust driven through the doorway into the lane: a fast grey jet out of the opening that
	# slows and spreads (FxPresets.dust_jet), not a flat sheet on the deck.
	blast_dust = FxPresets.place(FxPresets.dust_jet(Color(0.56, 0.58, 0.6, 0.42), 26), self, "BlastDust", Vector2(DOOR_X - 2.0, FLOOR_Y - 46.0), 3, Vector2(6.0, 42.0))
	# Fix round 4 (review r4 C2): the dust the thrown leaf raises off the wet deck where it lands, low and
	# spreading along it, in front of the lying leaf.
	landing_dust = FxPresets.dust_jet(Color(0.5, 0.53, 0.56, 0.38), 18)
	landing_dust.direction = Vector2(0.0, -1.0)
	landing_dust.spread = 75.0
	landing_dust.initial_velocity_min = 50.0
	landing_dust.initial_velocity_max = 130.0
	landing_dust.damping_min = 120.0
	landing_dust.damping_max = 180.0
	FxPresets.place(landing_dust, self, "LandingDust", DOOR_FLIGHT_TO + Vector2(0.0, 20.0), DOOR_FRONT_Z + 1, Vector2(66.0, 4.0))


## The sentry, the tank over the mark and the lane's hazards and bursts. The sentry is added before
## the tank so a landed tank draws over the machine it came down on.
func _build_lane() -> void:
	sentry = Sentry.new()
	sentry.name = "Sentry"
	sentry.z_index = 1
	add_child(sentry)
	floor_reflections.append_array(sentry.floor_reflections)
	panel_front = PanelFront.new()
	panel_front.name = "BoltPanelFront"
	panel_front.room = self
	panel_front.z_index = sentry.z_index
	add_child(panel_front)
	tank = TankSprite.new()
	tank.name = "Tank"
	tank.texture = TANK_PROP
	tank.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tank.scale = Vector2.ONE * TANK_ART_SCALE
	tank.position = Vector2(DropArm.MARK_X, TANK_REST_Y)
	tank.z_index = 1
	add_child(tank)
	# The arm hangs from its ceiling plate (top at ARM_TOP_Y) with its shackle over the mark; the tank
	# hangs under it on the cable _draw_arm draws.
	arm_art = RoomDepth.make_prop("ArmArt", ARM_PROP, ARM_SCALE, DropArm.MARK_X + (ARM_SIZE.x * 0.5 - ARM_SHACKLE.x) * ARM_SCALE, ARM_TOP_Y + ARM_SIZE.y * ARM_SCALE)
	arm_rest_y = arm_art.position.y
	arm_art.z_index = 1
	add_child(arm_art)
	# The cloud's hurtbox is the cloud: DropArm.CLOUD_HALF_WIDTH either side of the mark, floor to head height.
	cloud_hazard = Hazard.make("CloudHazard", Rect2(DropArm.MARK_X - DropArm.CLOUD_HALF_WIDTH, 360.0, DropArm.CLOUD_HALF_WIDTH * 2.0, 80.0), CLOUD_REASON)
	add_child(cloud_hazard)
	coolant_cloud = FxPresets.steam()
	coolant_cloud.initial_velocity_min = 20.0
	coolant_cloud.initial_velocity_max = 60.0
	coolant_cloud.spread = 60.0
	coolant_cloud.scale_amount_min = 10.0
	coolant_cloud.scale_amount_max = 18.0
	coolant_cloud.amount = 24
	coolant_cloud.color = Color(COOLANT, 0.16)
	# Behind the actors and the sentry, so the vapour never hides who is in it.
	FxPresets.place(coolant_cloud, self, "CoolantCloud", Vector2(DropArm.MARK_X, FLOOR_Y - 6.0), 0, Vector2(DropArm.CLOUD_HALF_WIDTH - 8.0, 4.0))
	coolant_burst = FxPresets.dust_burst()
	coolant_burst.color = Color(COOLANT, 0.35)
	coolant_burst.initial_velocity_min = 110.0
	coolant_burst.initial_velocity_max = 220.0
	coolant_burst.amount = 22
	FxPresets.place(coolant_burst, self, "CoolantBurst", Vector2(DropArm.MARK_X, FLOOR_Y - 10.0), 3)
	hit_sparks = FxPresets.sparks(Palette.CYAN)
	hit_sparks.amount = 36
	hit_sparks.spread = 100.0
	FxPresets.place(hit_sparks, self, "HitSparks", Vector2(DropArm.MARK_X, FLOOR_Y - 30.0), 3)
	# The bolt's short in the panel: hot streaks spat out of the panel's face, falling (FxPresets.streaks).
	bolt_sparks = FxPresets.streaks(22)
	bolt_sparks.spread = 75.0
	FxPresets.place(bolt_sparks, self, "BoltSparks", RoomDepth.prop_rect(bolt_panel_art, BOLT_PANEL_LIGHT).get_center(), 3)


## A station name on its plate, centred on [param center_x] in the label row. It draws over the
## door's cross-wall and under the actors.
func _add_station_label(caption: String, center_x: float, tint: Color) -> Label:
	var label: Label = Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	TextSize.size_label(label, LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_stylebox_override("normal", label_plate)
	label.z_index = 0
	label.set_meta(&"center_x", center_x)
	add_child(label)
	station_labels.append(label)
	_fit_label(label)
	return label


## Shrinks [param label]'s plate to its text and centres it on its station again.
func _fit_label(label: Label) -> void:
	TextSize.fit_world_label(label, float(label.get_meta(&"center_x")), LABEL_Y)


## Every plate fitted to its text again, then neighbours that would cover each other parted
## (TextSize.part_world_labels, PR L8). Called whenever a plate's words or size change.
func _fit_labels() -> void:
	for label: Label in station_labels:
		_fit_label(label)
	TextSize.part_world_labels(station_labels)


## TEXT SIZE or the language changed: every plate, and the LINE caption by the valve's dial, takes the
## new size and words.
func refit_labels() -> void:
	# The valve's turn count is translated where it is built (_valve_caption), so it is built again.
	if valve_label != null:
		valve_label.text = _valve_caption()
	_fit_labels()
	_place_line_caption()


## The LINE caption just left of the valve's dial, level with it.
func _place_line_caption() -> void:
	TextSize.size_label(line_caption, LINE_CAPTION_FONT_SIZE)
	line_caption.size = Vector2.ZERO
	line_caption.size = line_caption.get_combined_minimum_size()
	var dial: Vector2 = RoomDepth.prop_point(valve_art, VALVE_DIAL_CENTRE)
	line_caption.position = Vector2(dial.x - VALVE_DIAL_RADIUS * VALVE_SCALE - 2.0 - line_caption.size.x, dial.y - line_caption.size.y * 0.5)


## A plate the edge of the view cuts would show part of a name: it fades out as it reaches the edge.
## Once the junction is cleared the closing shot's camera stands still, so a plate caught in that fade
## would hang there half see-through for the whole walk-out (review r5: DOOR DOWN at the left edge on
## a phone); it is hidden instead.
func _process(delta: float) -> void:
	if not visible:
		return
	fade_at_view_edge(station_labels, get_viewport())
	if junction_cleared:
		for label: Label in station_labels:
			if label.modulate.a < 1.0:
				label.modulate.a = 0.0
	_advance_flicker(delta)


## The lamp of [param station] (&"breaker", &"valve", &"door", &"release" or &"bolt") goes dark and
## comes back [param times] times, from this frame.
func flicker(station: StringName, times: int) -> void:
	var was_door: bool = flicker_station == &"door"
	flicker_station = station
	flicker_elapsed = 0.0
	flicker_times = times
	if was_door and station != &"door":
		_sync_lamp()
	_sync_flicker()


## How lit [param station]'s lamp is this frame: 0 dark in a flicker, 1 otherwise.
func lamp_level(station: StringName) -> float:
	if station != flicker_station or flicker_times <= 0:
		return 1.0
	if reduce_motion:
		return 0.0 if flicker_elapsed < FLICKER_STEP_SECONDS * 2.0 else 1.0
	if flicker_elapsed >= FLICKER_STEP_SECONDS * 2.0 * flicker_times:
		return 1.0
	return 0.0 if fmod(flicker_elapsed, FLICKER_STEP_SECONDS * 2.0) < FLICKER_STEP_SECONDS else 1.0


## True while [param station]'s lamp is in a flicker (dark or between dark steps).
func flickering(station: StringName) -> bool:
	if station != flicker_station or flicker_times <= 0:
		return false
	return flicker_elapsed < FLICKER_STEP_SECONDS * 2.0 * (1 if reduce_motion else flicker_times)


## The breaker's lamp pulses for [param seconds] (hint ladder T1, while WOLF looks at it).
func pulse_breaker(seconds: float) -> void:
	breaker_pulse_remaining = seconds
	breaker_pulse_elapsed = 0.0
	queue_redraw()


## How far the breaker's lamp is pulsed up this frame, 0..1 (0 when it is not pulsing).
func breaker_pulse_level() -> float:
	if breaker_pulse_remaining <= 0.0:
		return 0.0
	if reduce_motion:
		return 1.0
	return 0.5 - 0.5 * cos(breaker_pulse_elapsed * BREAKER_PULSE_HZ * TAU)


## Moves the breaker's pulse and any station lamp flicker on by [param delta] seconds; when a flicker
## ends, puts the lamps it touched back as the state shows them. Redraws as they change.
func _advance_flicker(delta: float) -> void:
	if breaker_pulse_remaining > 0.0:
		breaker_pulse_remaining = maxf(breaker_pulse_remaining - delta, 0.0)
		breaker_pulse_elapsed += delta
		_sync_breaker_glow()
		queue_redraw()
	if flicker_times <= 0:
		return
	flicker_elapsed += delta
	if not flickering(flicker_station):
		var station: StringName = flicker_station
		flicker_times = 0
		flicker_station = &""
		if station == &"door":
			_sync_lamp()
		_sync_breaker_glow()
		_sync_exit_lamp()
		queue_redraw()
		return
	_sync_flicker()


## Shows the flicker's current step: the drawn lamps follow lamp_level when they draw; the glows, the
## door's status lamp and the exit door's lens are nodes, set here.
func _sync_flicker() -> void:
	if flicker_station == &"door" and not door_blown and not (line_state in [&"charged", &"fuse"]):
		Tweens.kill(_lamp_tween)
		var lit: float = lamp_level(&"door")
		_set_lamp(Palette.AMBER if lit > 0.0 else LAMP_DEAD, SEAM_FLICKER_ALPHA * lit)
	_sync_exit_lamp()
	_sync_breaker_glow()
	queue_redraw()


## The breaker's glow: as its phase sets it (refresh_state), dark in a flicker, brighter in a pulse.
func _sync_breaker_glow() -> void:
	var lit: bool = line_state in [&"building", &"charged", &"fuse"] and not door_blown
	var glow: Color = Color(_breaker_light_color(), 0.75 if lit else 0.4)
	glow.a = lerpf(glow.a, 1.0, breaker_pulse_level()) * lamp_level(&"breaker")
	breaker_glow.modulate = glow


## Fades each of [param labels] out over LABEL_EDGE_FADE px as it reaches the edge of [param viewport]'s
## view, so a name the edge would cut never shows in part. Every room's station names and the corridor's
## bypass plates use it; a label sized to its text fades by its text.
static func fade_at_view_edge(labels: Array, viewport: Viewport) -> void:
	var view: Rect2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	for label: Control in labels:
		label.modulate.a = edge_alpha(label.get_global_rect(), view)


## How opaque a plate covering [param rect] is in [param view]: 1 well inside, falling to 0 as either
## end reaches the view's edge.
static func edge_alpha(rect: Rect2, view: Rect2) -> float:
	var margin: float = minf(rect.position.x - view.position.x, view.end.x - rect.end.x)
	return clampf(margin / LABEL_EDGE_FADE, 0.0, 1.0)


## Enables the door body and hazards only while this is the room in play, so the junction's
## collision never leaks into the corridor or Records, which share the same coordinates. Its floor
## reflections mirror only while it is in play; its bursts, steam and cloud are stopped by
## reset_transient, which the parent runs with every sync.
func set_active(active: bool) -> void:
	FloorReflection.set_all_active(floor_reflections, active)
	door_shape.set_deferred("disabled", not active or door_blown)
	entry_door_shape.set_deferred("disabled", not active)
	vent_hazard.armed = false
	vent_hazard.set_deferred("monitoring", active)
	cloud_hazard.armed = false
	cloud_hazard.set_deferred("monitoring", active)


## Copies the live pressure line in; the gauge needle, steam, door lamp and labels all follow it.
func sync_line(line: PressureLine) -> void:
	var previous_turns: int = turns
	var previous_state: StringName = line_state
	line_state = line.state
	gauge = line.gauge
	turns = line.turns
	fuse_remaining = line.fuse_remaining
	if line_state == &"building":
		display_gauge = gauge
		gauge_tripped = false
		gauge_hold = 0.0
	elif line_state == &"tripped" and previous_state == &"building":
		# The vent let go at the top of the gauge: the needle stays there, red, while the grate hurts.
		display_gauge = 1.0
		gauge_tripped = true
		gauge_hold = HAZARD_SECONDS
	elif not gauge_tripped:
		display_gauge = gauge
	if turns != previous_turns:
		_turn_wheel(turns)
	# The VALVE label counts the turns, so a crank refreshes it as well as a phase change.
	if line_state != previous_state or turns != previous_turns:
		refresh_state()
	var building: bool = line_state == &"building"
	# Steam only near the top of the gauge, thickening toward the peak.
	var steam: float = inverse_lerp(PressureLine.STEAM_GAUGE, 1.0, gauge)
	vent_steam.emitting = building and steam >= 0.0 and visible
	vent_steam.initial_velocity_max = lerpf(60.0, 220.0, clampf(steam, 0.0, 1.0))
	vent_steam.scale_amount_max = lerpf(6.0, 16.0, clampf(steam, 0.0, 1.0))
	vent_steam.modulate.a = lerpf(0.45, 1.0, clampf(steam, 0.0, 1.0))
	_sync_vent_glow()
	_check_redraw()


## Advances the needle's fall after the vent lets go; the parent calls it every junction frame, so it
## holds still through a knockdown, when nothing does.
func advance_display(delta: float) -> void:
	if not gauge_tripped:
		return
	if gauge_hold > 0.0:
		gauge_hold = maxf(gauge_hold - delta, 0.0)
		return
	display_gauge = move_toward(display_gauge, gauge, delta / GAUGE_FALL_SECONDS)
	if display_gauge <= gauge:
		gauge_tripped = false
	_check_redraw()


## The grate glows as the line builds, hotter toward the gauge's peak, flashing red through the hard
## warning, and red once it has let go.
func _sync_vent_glow() -> void:
	match line_state:
		&"building":
			if gauge >= PressureLine.WARN_GAUGE:
				# The flash follows the gauge itself, so it runs at the same rate whatever the frame rate.
				var flash: float = 1.0 if reduce_motion else 0.5 + 0.5 * cos(gauge * PressureLine.BUILD_SECONDS * VENT_FLASH_HZ * TAU)
				vent_glow.modulate = Color(SEAM_RED, lerpf(0.35, 0.95, flash))
			else:
				vent_glow.modulate = Color(Palette.AMBER.lerp(SEAM_RED, gauge * gauge), 0.12 + 0.55 * gauge)
		&"tripped":
			vent_glow.modulate = Color(SEAM_RED, 0.35)
		_:
			vent_glow.modulate = Color(Palette.AMBER, 0.0)


## Copies the arm in: the tank's height, the cloud and its hurtbox follow DropArm's state.
func sync_arm(arm: DropArm) -> void:
	var previous_state: StringName = arm_state
	var previous_on_floor: bool = tank_on_floor
	arm_state = arm.state
	tank_drop = arm.drop_amount()
	tank_on_floor = arm.on_floor()
	# A tank coming down on the sentry stops on its crushed hull, so the wreck shows under it; one that
	# only catches its end (a graze) comes down past it onto the floor.
	var on_sentry: bool = (arm.state == &"landed" or (arm.state == &"falling" and DropArm.is_hit(sentry.target_x))) and tank_rests_on_wreck(sentry.target_x)
	tank.position.y = lerpf(TANK_REST_Y, landed_tank_y(on_sentry), tank_drop)
	var cloud: bool = arm.cloud_active() and visible
	coolant_cloud.emitting = cloud
	if cloud_hazard.armed != cloud:
		cloud_hazard.armed = cloud
	if arm_state != previous_state or tank_on_floor != previous_on_floor:
		refresh_state()
	_check_redraw()


## Copies the exit bolt in; its panel light warms with the charge.
func sync_bolt(state: StringName, charge: float) -> void:
	var changed: bool = state != bolt_state
	bolt_state = state
	bolt_charge = charge
	if changed:
		refresh_state()
	# The exit's status lamp follows the bolt (amber while it charges); the bolt's lights and its feed
	# (Recesses) warm with the charge.
	_sync_exit_lamp()
	_check_redraw()


## The parent syncs the line, the arm and the bolt every junction frame, and most frames nothing drawn
## changes: once per frame, after the frame's syncs, this redraws the room and its Recesses only when
## what they draw differs from what they last drew.
func _check_redraw() -> void:
	if _redraw_check_queued:
		return
	_redraw_check_queued = true
	_redraw_if_changed.call_deferred()


## Redraws the room, or the recesses, only when a value its drawing reads has changed since it was last
## drawn (draw_inputs, recesses_inputs). Queued at most once per frame.
func _redraw_if_changed() -> void:
	_redraw_check_queued = false
	if draw_inputs() != _drawn_inputs:
		queue_redraw()
	if recesses_inputs() != _recesses_drawn_inputs:
		recesses.queue_redraw()


## Every value _draw reads that can change after the room is built.
func draw_inputs() -> Array:
	return [line_state, gauge, display_gauge, gauge_tripped, fuse_remaining, reduce_motion, door_blown, sentry_down, junction_cleared, arm_state, tank_drop, tank_on_floor, tank.position.y, arm_art.position.y, bolt_state, bolt_charge, breaker_pulse_level(), lamp_level(&"breaker"), lamp_level(&"valve"), lamp_level(&"release"), lamp_level(&"bolt"), mark_lit()]


## Every value draw_recesses reads that can change after the room is built.
func recesses_inputs() -> Array:
	return [sentry_down, junction_cleared, bolt_state, bolt_charge]


## How high WOLF's drawn body is lifted with his centre at [param wolf_x] and the live sentry's at
## [param sentry_x]: LEAP_HEIGHT while their bodies could overlap, easing to nothing LEAP_RAMP further
## out.
static func wolf_leap_height(wolf_x: float, sentry_x: float) -> float:
	return LEAP_HEIGHT * (1.0 - smoothstep(LEAP_CLEAR, LEAP_CLEAR + LEAP_RAMP, absf(wolf_x - sentry_x)))


## How high WOLF's drawn body is lifted crossing the crushed tank on the mark with his centre at
## [param wolf_x]: one parabolic arc, TANK_LEAP_HEIGHT over TANK_LEAP_PEAK_X and nothing from
## TANK_LEAP_HALF_SPAN either side of it.
static func wolf_tank_leap_height(wolf_x: float) -> float:
	var along: float = (wolf_x - TANK_LEAP_PEAK_X) / TANK_LEAP_HALF_SPAN
	return TANK_LEAP_HEIGHT * maxf(1.0 - along * along, 0.0)


## How far forward of the walk line WOLF stands (0..1, a fraction of WOLF_STEP_FORWARD) with his centre at
## [param wolf_x]: all the way while his body would overlap the valve's middle, easing back over
## WOLF_STEP_RAMP to nothing, so he walks round the front of the valve.
static func wolf_valve_step(wolf_x: float) -> float:
	return 1.0 - smoothstep(WOLF_STEP_FULL, WOLF_STEP_FULL + WOLF_STEP_RAMP, absf(wolf_x - VALVE_X))


## True when a tank landing on a sentry centred at [param sentry_x] rests on its crushed hull: the
## sentry's middle is inside the brackets, so at least half of the tank's footprint is over the wreck.
## A graze further out (DropArm.HIT_REACH) catches only the wreck's end and the tank stands on the
## floor beside it, over that end.
static func tank_rests_on_wreck(sentry_x: float) -> bool:
	return absf(sentry_x - DropArm.MARK_X) <= DropArm.HIT_RANGE + DropArm.EPSILON


## Where the tank's centre comes to rest: on the floor, or on top of the crushed sentry.
static func landed_tank_y(on_sentry: bool) -> float:
	return FLOOR_Y - TANK_SIZE.y * 0.5 - (Sentry.WRECK_CRUSH_HEIGHT if on_sentry else 0.0)


## The tank came down on the sentry at [param at_x] (the mark): the coolant and spark bursts (fired
## through the impact kit) are moved there and the sentry is crushed into its wreck under the tank.
func tank_hit(at_x: float) -> void:
	sentry_down = true
	coolant_burst.position.x = at_x
	hit_sparks.position.x = at_x
	sentry.keel_over(at_x)
	# The empty arm winches up into its ceiling plate, clear of WOLF bounding over the tank.
	_arm_tween = Tweens.restart(self, _arm_tween)
	_arm_tween.tween_property(self, "arm_parked", 1.0, ARM_PARK_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	refresh_state()


## The tank hit the empty mark: the coolant burst moves there and the tank is dented.
func tank_miss() -> void:
	coolant_burst.position.x = DropArm.MARK_X
	tank.dented = true


## The bolt lets go and the exit door slides open into its pocket (the parent fires the panel's sparks);
## hatch_opened follows once it is open.
func bolt_arc() -> void:
	_hatch_tween = Tweens.restart(self, _hatch_tween)
	_hatch_tween.tween_property(self, "hatch_open", 1.0, HATCH_OPEN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_hatch_tween.tween_callback(refresh_state)
	_hatch_tween.tween_callback(func() -> void: hatch_opened.emit())


## A hold at the valve under way: from its press frame the wheel turns part of the way into its next
## quarter, by [param fraction] (HoldUse.shown_fraction); at 0 (let go) the part turn springs back.
func show_crank(fraction: float) -> void:
	if is_equal_approx(fraction, crank_fraction):
		return
	var released: bool = fraction <= 0.0
	crank_fraction = maxf(fraction, 0.0)
	Tweens.kill(_valve_tween)
	var target: float = 90.0 * (turns + crank_fraction)
	if released and is_inside_tree():
		_valve_tween = create_tween()
		_valve_tween.tween_property(valve_wheel, "rotation_degrees", target, BypassHandle.SPRING_BACK_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		valve_wheel.rotation_degrees = target


## Turns the VALVE's wheel to [param to_turns] quarter turns (90 degrees each): eased over 0.18 s for a
## new turn, or set at once at 0 or mid-hold (show_crank turns it on from there).
func _turn_wheel(to_turns: int) -> void:
	Tweens.kill(_valve_tween)
	var target: float = 90.0 * to_turns
	# Mid-hold the quarter just reached is where the wheel is; show_crank adds the next part turn.
	if to_turns == 0 or crank_fraction > 0.0:
		valve_wheel.rotation_degrees = target
		return
	_valve_tween = create_tween()
	_valve_tween.tween_property(valve_wheel, "rotation_degrees", target, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## The VALVE plate's words for the line's phase: VALVE USED once the blast used the line up, FUSE LIT
## from the charge on, the turn count ("VALVE  3 / 8") while the breaker is live, else VALVE.
## Every caption but the count stays English and translates as drawn, like the other plates; the count
## has inserts, so it is translated here from its template with tr() and filled after (a Label can only
## look up a whole message). Its words therefore follow a language change only when this is called
## again, which refit_labels() does.
func _valve_caption() -> String:
	if is_spent():
		return I18n.KEY.tr("VALVE USED")
	if line_state in [&"charged", &"fuse", &"blown"]:
		return I18n.KEY.tr("FUSE LIT")
	if line_state != &"idle" and line_state != &"tripped":
		return tr("VALVE  %d / %d") % [turns, PressureLine.TURNS_NEEDED]
	return I18n.KEY.tr("VALVE")


## Labels, glows and the door lamp follow the line's phase; the parent calls this after state changes.
func refresh_state() -> void:
	if is_spent():
		# The blast used the line up: the same labels whether it just went or a save brought it back. State
		# words on the plates are plain (USED, LOCKED, READY; P0-7, approved 2026-10-13).
		breaker_label.text = "BREAKER USED"
		breaker_label.add_theme_color_override("font_color", Palette.LABEL_MUTED)
		valve_label.text = _valve_caption()
		valve_label.add_theme_color_override("font_color", Palette.LABEL_MUTED)
	else:
		var armed: bool = line_state != &"idle" and line_state != &"tripped"
		breaker_label.text = I18n.KEY.tr("BREAKER TRIPPED") if line_state == &"tripped" else (I18n.KEY.tr("BREAKER LIVE") if armed else I18n.KEY.tr("OVERLOAD BREAKER"))
		breaker_label.add_theme_color_override("font_color", SEAM_RED if line_state == &"tripped" else (Palette.CYAN if armed else Palette.LABEL_TEXT))
		valve_label.text = _valve_caption()
		valve_label.add_theme_color_override("font_color", Palette.GREEN if turns >= PressureLine.TURNS_NEEDED else Palette.LABEL_TEXT)
	_sync_breaker_glow()
	door_label.text = I18n.KEY.tr("DOOR DOWN") if door_blown else I18n.KEY.tr("SEALED DOOR")
	door_label.add_theme_color_override("font_color", Palette.GREEN if door_blown else Palette.LABEL_ALERT)
	# A missed tank lying on the floor is not being winched yet: the plate says so only once the winch
	# takes it (it stays amber, busy, meanwhile).
	arm_label.text = I18n.KEY.tr("RELEASE USED") if sentry_down else (I18n.KEY.tr("WINCHING UP") if arm_state == &"rewinding" and not tank_on_floor else I18n.KEY.tr("TANK RELEASE"))
	tank_label.visible = sentry_down
	arm_label.add_theme_color_override("font_color", Palette.LABEL_MUTED if sentry_down else (Palette.AMBER if arm_state == &"rewinding" else Palette.LABEL_TEXT))
	if junction_cleared or (bolt_state == &"open" and hatch_open >= 1.0):
		hatch_label.text = "EXIT OPEN"
		hatch_label.add_theme_color_override("font_color", Palette.GREEN)
	elif bolt_state == &"open":
		# The bolt has dropped but the hatch is still sliding: it says open only once it is.
		hatch_label.text = "EXIT OPENING"
		hatch_label.add_theme_color_override("font_color", Palette.AMBER)
	elif sentry_down:
		hatch_label.text = "EXIT READY"
		hatch_label.add_theme_color_override("font_color", Palette.AMBER)
	else:
		hatch_label.text = "EXIT LOCKED"
		hatch_label.add_theme_color_override("font_color", Palette.LABEL_MUTED)
	_fit_labels()
	_sync_lamp()
	_sync_vent_glow()
	_sync_exit_lamp()
	queue_redraw()
	recesses.queue_redraw()


## The exit door's status lamp (its live lens) shows the bolt's colour: red shut, amber charging,
## warming through the whine, green open; it goes dark in a refusal's flicker at the bolt panel.
func _sync_exit_lamp() -> void:
	if exit_lamp != null:
		exit_lamp.color = bolt_lamp_color()


## True once the door is down, whether it just went or a save brought it back.
func is_spent() -> bool:
	return door_blown


## The door's status lamp follows the line: red shut, amber while it builds, flashing red and white
## through the fuse (steady red with Reduced Motion), dark once the door is down.
func _sync_lamp() -> void:
	Tweens.kill(_lamp_tween)
	_lamp_tween = null
	if door_blown or line_state == &"blown":
		_set_lamp(LAMP_DEAD, 0.0)
		return
	match line_state:
		&"charged", &"fuse":
			_set_lamp(SEAM_RED, 0.6)
			if reduce_motion:
				return
			_lamp_tween = create_tween().set_loops()
			_lamp_tween.tween_callback(_set_lamp.bind(Color.WHITE, 0.7))
			_lamp_tween.tween_interval(0.12)
			_lamp_tween.tween_callback(_set_lamp.bind(SEAM_RED, 0.6))
			_lamp_tween.tween_interval(0.12)
		&"building":
			_set_lamp(Palette.AMBER, 0.5)
		_:
			_set_lamp(Palette.LAMP_SHUT, 0.45)


## Shows the blast door's status lamp in [param color]: the glass is tinted with it and its glow takes
## the same colour at [param glow] alpha (0 to 1), hidden at 0 so a dark lamp adds no additive sprite.
func _set_lamp(color: Color, glow: float) -> void:
	door_lamp.color = color
	door_lamp.halo.modulate = Color(color, glow)
	door_lamp.halo.visible = glow > 0.0


## The vent letting go: a steam burst and a short armed window over the grate.
func vent_blows() -> void:
	vent_steam.emitting = false
	vent_puff.restart()
	_arm_hazard(vent_hazard)


## The door going: the leaf breaks under the blast flash, then the doorway stands empty and the leaf
## lies thrown in the lane; sparks, concrete fragments and dust fly, and the blast zone is dangerous
## for a moment.
func door_blast() -> void:
	door_blown = true
	door_breaking = true
	vent_hazard.armed = false
	door_shape.set_deferred("disabled", true)
	blast_sparks.restart()
	blast_debris.restart()
	blast_dust.restart()
	Tweens.kill(_door_tween)
	_show_door()
	_door_tween = create_tween()
	_door_tween.tween_interval(DOOR_BREAK_SECONDS)
	_door_tween.tween_callback(func() -> void:
		door_breaking = false
		door_flying = true
		_show_door())
	_door_tween.tween_method(_set_door_flight, 0.0, 1.0, DOOR_FLIGHT_SECONDS)
	_door_tween.tween_callback(func() -> void:
		door_flying = false
		_show_door()
		landing_dust.restart())
	refresh_state()


## The shut leaf until the blast; the breaking leaf for a moment; then the lit empty doorway and the
## soot with the torn leaf in the air, and then lying in the lane. The wall and the front always show.
func _show_door() -> void:
	var gone: bool = door_blown and not door_breaking
	door_leaf.visible = not door_blown
	door_leaf_breaking.visible = door_blown and (door_breaking or door_flying)
	door_hole.visible = gone
	door_reveal.visible = gone
	for soot: Sprite2D in door_soot:
		soot.visible = door_blown
	door_leaf_down.visible = gone and not door_flying
	if not door_flying:
		_set_door_flight(0.0)
	# Once the leaf has gone, the front shows the hinge knuckles torn off the near jamb (its blown piece).
	door_column.texture = BLAST_FRONT_BLOWN if door_blown else BLAST_FRONT


## The torn leaf [param t] (0..1) along its flight from the doorway to where it lies: carried on by the blast
## and slowed by the air along the lane, up a little and down under gravity, tipping over toward flat and
## growing as it comes nearer the camera; at 0 it stands in its doorway piece's place again.
func _set_door_flight(t: float) -> void:
	door_flight = t
	var leaf: Sprite2D = door_leaf_breaking
	if t <= 0.0:
		leaf.centered = false
		leaf.position = LEAFBREAK_AT
		leaf.rotation = 0.0
		leaf.scale = Vector2.ONE * LEAFBREAK_SCALE
		leaf.z_index = DOOR_Z
		return
	leaf.centered = true
	var along: float = 1.0 - (1.0 - t) * (1.0 - t)
	leaf.position = Vector2(lerpf(DOOR_FLIGHT_FROM.x, DOOR_FLIGHT_TO.x, along), lerpf(DOOR_FLIGHT_FROM.y, DOOR_FLIGHT_TO.y, t * t) - DOOR_FLIGHT_RISE * 4.0 * t * (1.0 - t))
	leaf.rotation = DOOR_FLIGHT_TURN * pow(t, 1.2)
	leaf.scale = Vector2.ONE * LEAFBREAK_SCALE * lerpf(1.0, DOOR_FLIGHT_GROW, t)
	leaf.z_index = DOOR_FRONT_Z + 1 if t >= DOOR_FLIGHT_CLEAR else DOOR_Z


## The exit door's leaf slides back along the wall into its pocket as it opens, over the passage behind;
## the light through the hole comes up and the shut shades on the reveal and past the wall's end go as it
## does.
func _sync_hatch() -> void:
	if exit_leaf != null:
		exit_leaf.queue_redraw()
		var open: float = clampf(hatch_open, 0.0, 1.0)
		exit_hole.color = EXIT_HOLE_LIGHT * open
		exit_shade.color = EXIT_SHUT_SHADE.lerp(Color.WHITE, open)
		exit_past_end.color = (DoorKit.PAST_END_SHADE * EXIT_SHUT_SHADE).lerp(DoorKit.PAST_END_SHADE, open)


## Arms [param hazard] for HAZARD_SECONDS, then disarms it; a later call replaces the window under way.
## The engineer already inside when it arms is reported at once (Hazard.armed emits contact).
func _arm_hazard(hazard: Hazard) -> void:
	Tweens.kill(_hazard_tween)
	hazard.armed = true
	_hazard_tween = create_tween()
	_hazard_tween.tween_interval(HAZARD_SECONDS)
	_hazard_tween.tween_callback(func() -> void: hazard.armed = false)


## Back to the state the save describes: no burst, no fuse, the wheel at rest and the door as saved.
func reset_transient() -> void:
	for tween: Tween in [_valve_tween, _lamp_tween, _door_tween, _hazard_tween, _hatch_tween, _arm_tween, entry_tween]:
		Tweens.kill(tween)
	entry_tween = null
	# The entry stands shut behind them, as a restored save finds it.
	entry_leaf.open = 0.0
	set_entry_lamp(Palette.LAMP_SHUT)
	_arm_tween = null
	_valve_tween = null
	_lamp_tween = null
	_door_tween = null
	_hazard_tween = null
	_hatch_tween = null
	flicker_times = 0
	flicker_station = &""
	breaker_pulse_remaining = 0.0
	vent_hazard.armed = false
	cloud_hazard.armed = false
	for burst: CPUParticles2D in [vent_steam, vent_puff, blast_sparks, blast_debris, blast_dust, landing_dust, coolant_cloud, coolant_burst, hit_sparks, bolt_sparks]:
		burst.emitting = false
	# The tank hangs again (or lies on the downed sentry), undented; the hatch is as the save left it.
	tank.dented = false
	door_breaking = false
	door_flying = false
	arm_state = &"landed" if sentry_down else &"hung"
	tank_drop = 1.0 if sentry_down else 0.0
	tank_on_floor = false
	tank.position.y = lerpf(TANK_REST_Y, landed_tank_y(sentry_down), tank_drop)
	# The arm is up in its plate once the tank is down for good, and holds the tank otherwise.
	arm_parked = 1.0 if sentry_down else 0.0
	fuse_remaining = 0.0
	crank_fraction = 0.0
	display_gauge = 0.0
	gauge_hold = 0.0
	gauge_tripped = false
	bolt_state = &"open" if junction_cleared else &"locked"
	bolt_charge = 0.0
	hatch_open = 1.0 if junction_cleared else 0.0
	# A blown door left the wheel at its third quarter; a restored save shows it the same way.
	valve_wheel.rotation_degrees = 90.0 * PressureLine.TURNS_NEEDED if door_blown else 0.0
	_show_door()
	door_shape.set_deferred("disabled", not visible or door_blown)
	line_state = &"idle"
	gauge = 0.0
	turns = 0
	refresh_state()


## Draws what the room's plates and sprites cannot show: the gauge, the breaker's light, the blast zone,
## the release's light, its rods and cable, the floor mark and the bolt panel's light. Notes what it drew
## from (draw_inputs) so a redraw is asked for only when one of those changes.
func _draw() -> void:
	_drawn_inputs = draw_inputs()
	# The plates are the Depth child's layers and the machines are sprites; this draws what they
	# cannot show.
	_draw_gauge()
	_draw_breaker_light()
	_draw_blast_zone()
	_draw_arm_panel_light()
	_draw_arm()
	_draw_floor_mark()
	draw_rect(RoomDepth.prop_rect(bolt_panel_art, BOLT_PANEL_LIGHT), bolt_lamp_color())


## What Recesses draws under the props: the release's feed to the exit bolt (the bay itself is painted,
## ReleaseBay, drawn over it, so the feed leaves the bay behind its right post).
func draw_recesses(canvas: CanvasItem) -> void:
	_recesses_drawn_inputs = recesses_inputs()
	_draw_bolt_feed(canvas)


## The feed comes up out of the floor at the exit bolt's panel: a floor gland, a conduit up the wall and
## a cable box the panel's painted cables plug into. Its core is lit only while it carries power to the
## bolt (bolt_feed_color). The TANK RELEASE end needs nothing drawn: the release's own painted pipe runs
## down into its base, and the run between the two is under the floor, clear of the tank and the lane.
## Drawn on [param canvas] (Recesses) under the props, so the panel's painted cables run into the box
## in front of it and the flat code-drawn plates show only round the panel's edge.
func _draw_bolt_feed(canvas: CanvasItem) -> void:
	for mark: Array in bolt_feed_marks():
		canvas.draw_rect(mark[0] as Rect2, mark[1] as Color)


## What _draw_bolt_feed fills, in order, as [rect, colour] pairs, so PanelFront can draw any part of it
## again: the conduit with its sheen and its core, then the cable box and the floor gland, each a steel
## plate with a one-pixel dark rim and a sheen along its top.
func bolt_feed_marks() -> Array:
	var parts: Array[Rect2] = bolt_feed_parts()
	var box: Rect2 = parts[0]
	var conduit: Rect2 = parts[1]
	var gland: Rect2 = parts[2]
	var marks: Array = [
		[conduit, CABLE_SHADOW],
		[Rect2(conduit.position.x + 0.5, conduit.position.y, 1.0, conduit.size.y), CABLE_SHEEN],
		[Rect2(conduit.get_center().x - 0.5, conduit.position.y, 2.0, conduit.size.y), bolt_feed_color()],
	]
	for plate: Rect2 in [box, gland]:
		marks.append([plate, FEED_STEEL])
		marks.append([Rect2(plate.position.x, plate.position.y, plate.size.x, 1.0), CABLE_SHADOW])
		marks.append([Rect2(plate.position.x, plate.end.y - 1.0, plate.size.x, 1.0), CABLE_SHADOW])
		marks.append([Rect2(plate.position.x, plate.position.y + 1.0, 1.0, plate.size.y - 2.0), CABLE_SHADOW])
		marks.append([Rect2(plate.end.x - 1.0, plate.position.y + 1.0, 1.0, plate.size.y - 2.0), CABLE_SHADOW])
		marks.append([Rect2(plate.position.x + 1.0, plate.position.y + 1.0, plate.size.x - 2.0, 1.0), CABLE_SHEEN])
	return marks


## The feed's parts in the room, top to bottom: the cable box over the ends of the bolt panel's left
## cables, the conduit from it down to the floor, and the floor gland it goes into.
func bolt_feed_parts() -> Array[Rect2]:
	var x: float = bolt_feed_x()
	var cables_y: float = RoomDepth.prop_point(bolt_panel_art, Vector2(0.0, BOLT_PANEL_CABLES_Y)).y
	var box: Rect2 = Rect2(x - FEED_BOX.x * 0.5, cables_y - FEED_BOX.y * 0.5, FEED_BOX.x, FEED_BOX.y)
	var gland: Rect2 = Rect2(x - FEED_GLAND.x * 0.5, FLOOR_Y - FEED_GLAND.y, FEED_GLAND.x, FEED_GLAND.y)
	var conduit: Rect2 = Rect2(x - 2.5, box.end.y, 5.0, gland.position.y - box.end.y)
	return [box, conduit, gland]


## Where the feed comes up: over the bolt panel's left edge, the box taking in the ends of its painted
## cables.
func bolt_feed_x() -> float:
	return RoomDepth.prop_bounds(bolt_panel_art).position.x + FEED_BOX.x * 0.5 + 1.0


## The feed's core: dead until the tank is down, then the bolt's own light (amber, warming to white
## through the whine, green once it has dropped).
func bolt_feed_color() -> Color:
	return Palette.DIM if not sentry_down and not junction_cleared else bolt_light_color()


## Where the sentry's drawing (Sentry.drawn_rects, widened by a pixel for its soft edges) crosses the
## exit bolt's panel or its feed (bolt_front_rect), as rectangles in this room that do not overlap one
## another: PanelFront draws them there again over the machine and its beam. Empty while the sentry is
## hidden or clear of them.
func bolt_panel_cover() -> Array[Rect2]:
	var cover: Array[Rect2] = []
	if sentry == null or not sentry.is_visible_in_tree():
		return cover
	var panel: Rect2 = bolt_front_rect()
	for part: Rect2 in sentry.drawn_rects():
		var over: Rect2 = part.grow(1.0).intersection(panel)
		if over.has_area():
			cover.append(over)
	return disjoint_rects(cover)


## What stands in front of the sentry's lane at the exit bolt: the panel's box and the bolt's feed (whose
## floor gland reaches a pixel past the panel's left edge).
func bolt_front_rect() -> Rect2:
	var front: Rect2 = RoomDepth.prop_bounds(bolt_panel_art)
	for part: Rect2 in bolt_feed_parts():
		front = front.merge(part)
	return front


## The panel's image and its light, drawn on [param canvas] (PanelFront) inside [param cover] only, the
## light in [param light]; under the image, the bolt's feed (bolt_feed_marks), so the cable box and
## conduit stay in front of the machine with the painted cables over them.
func draw_panel_front(canvas: CanvasItem, cover: Array[Rect2], light: Color) -> void:
	var panel: Rect2 = RoomDepth.prop_bounds(bolt_panel_art)
	var lamp: Rect2 = RoomDepth.prop_rect(bolt_panel_art, BOLT_PANEL_LIGHT)
	var marks: Array = bolt_feed_marks()
	for front: Rect2 in cover:
		for mark: Array in marks:
			var clipped: Rect2 = (mark[0] as Rect2).intersection(front)
			if clipped.has_area():
				canvas.draw_rect(clipped, mark[1] as Color)
		var part: Rect2 = front.intersection(panel)
		if not part.has_area():
			continue
		var source: Rect2 = Rect2((part.position - panel.position) / BOLT_PANEL_SCALE, part.size / BOLT_PANEL_SCALE)
		# Sampled like the whole sprite (no clamp at the cut), so the redrawn strip matches the art under it.
		canvas.draw_texture_rect_region(BOLT_PANEL_PROP, part, source, Color.WHITE, false, false)
		var lit: Rect2 = lamp.intersection(part)
		if lit.has_area():
			canvas.draw_rect(lit, light)


## [param rects] as rectangles covering the same area without overlapping (so a translucent drawing in
## each is laid down once): cut into vertical strips at every rectangle's left and right edge, with the
## covered height ranges of each strip merged, and side-by-side strips of the same height joined.
static func disjoint_rects(rects: Array[Rect2]) -> Array[Rect2]:
	var out: Array[Rect2] = []
	if rects.size() <= 1:
		out.assign(rects)
		return out
	var edges: Array[float] = []
	for rect: Rect2 in rects:
		edges.append(rect.position.x)
		edges.append(rect.end.x)
	edges.sort()
	for index: int in edges.size() - 1:
		var from: float = edges[index]
		var to: float = edges[index + 1]
		if to - from <= 0.0:
			continue
		var spans: Array[Vector2] = []
		for rect: Rect2 in rects:
			if rect.position.x <= from and rect.end.x >= to:
				spans.append(Vector2(rect.position.y, rect.end.y))
		spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var merged: Array[Vector2] = []
		for span: Vector2 in spans:
			if not merged.is_empty() and span.x <= merged[-1].y:
				merged[-1].y = maxf(merged[-1].y, span.y)
			else:
				merged.append(span)
		for span: Vector2 in merged:
			var joined: bool = false
			for at: int in out.size():
				if is_equal_approx(out[at].end.x, from) and is_equal_approx(out[at].position.y, span.x) and is_equal_approx(out[at].end.y, span.y):
					out[at].size.x = to - out[at].position.x
					joined = true
					break
			if not joined:
				out.append(Rect2(from, span.x, to - from, span.y - span.x))
	return out


## The alcove's core: exactly SentryBrain's cover span, up to the label row.
static func alcove_rect() -> Rect2:
	var top: float = LABEL_Y + 24.0
	return Rect2(SentryBrain.COVER_MIN_X, top, SentryBrain.COVER_MAX_X - SentryBrain.COVER_MIN_X, FLOOR_Y - top)


## The needle over the valve's painted gauge is the LINE gauge (left at empty, right at the vent's
## peak): red through the hard warning, and pinned red at the top for a while after the vent lets go
## (display_gauge). The VALVE plate counts the real turns.
func _draw_gauge() -> void:
	var centre: Vector2 = RoomDepth.prop_point(valve_art, VALVE_DIAL_CENTRE)
	var face: float = VALVE_DIAL_RADIUS * VALVE_SCALE
	# A fresh face over the painted one, so its painted needle never reads as a second reading.
	# The lit face is the valve's lamp: it goes dark in a refusal's flicker.
	draw_circle(centre, face - 0.6, Color("#d9d3c4").lerp(FLICKER_DARK, 1.0 - lamp_level(&"valve")))
	draw_arc(centre, face - 1.6, PI + PI * 0.78, TAU, 8, SEAM_RED, 1.6, true)
	var angle: float = PI + PI * display_gauge
	var red: bool = gauge_tripped or (line_state == &"building" and gauge >= PressureLine.WARN_GAUGE)
	var needle: Color = Color("#d0261c") if red else Color("#1a1c20")
	draw_line(centre, centre + Vector2.RIGHT.rotated(angle) * (face - 1.2), needle, 1.4, true)
	draw_circle(centre, 1.2, needle)


## Hazard stripes on the floor over exactly the door's blast zone (PressureLine.BLAST_MIN_X..
## BLAST_MAX_X) while the fuse burns, pulsing with the fuse (steady with Reduced Motion).
func _draw_blast_zone() -> void:
	if door_blown or not (line_state == &"charged" or line_state == &"fuse"):
		return
	var pulse: float = 1.0 if reduce_motion else 0.5 + 0.5 * cos(fuse_remaining * BLAST_STRIPE_HZ * TAU)
	var left: float = PressureLine.BLAST_MIN_X
	var width: float = PressureLine.BLAST_MAX_X - PressureLine.BLAST_MIN_X
	var stripes: int = 15
	# A red wash over the walkway in front, then the stripes along the floor line, over its whole span.
	draw_rect(Rect2(left, FLOOR_Y, width, 9.0), Color(SEAM_RED, lerpf(0.12, 0.3, pulse)))
	for stripe: int in stripes:
		var segment: Rect2 = Rect2(left + stripe * width / stripes, FLOOR_Y - 2.0, width / stripes, 7.0)
		draw_rect(segment, Color(SEAM_RED, lerpf(0.55, 1.0, pulse)) if stripe % 2 == 0 else Color(0.1, 0.03, 0.03, 0.85))
	for edge: float in [left, left + width]:
		draw_line(Vector2(edge, FLOOR_Y - 12.0), Vector2(edge, FLOOR_Y + 9.0), Color(SEAM_RED, lerpf(0.7, 1.0, pulse)), 2.0)


## Draws the breaker's status light in its phase colour, whitened by its pulse and darkened by a flicker.
func _draw_breaker_light() -> void:
	var light: Color = _breaker_light_color().lerp(Color.WHITE, 0.6 * breaker_pulse_level())
	draw_rect(BREAKER_LIGHT, light.lerp(FLICKER_DARK, 1.0 - lamp_level(&"breaker")))


## The breaker light's colour for the line's phase: dim once the door is blown, red when tripped,
## Palette.BREAKER_IDLE while idle, else cyan (live).
func _breaker_light_color() -> Color:
	if door_blown:
		return Palette.DIM
	match line_state:
		&"tripped":
			return SEAM_RED
		&"idle":
			return Palette.BREAKER_IDLE
		_:
			return Palette.CYAN


## The ARM PANEL's light: green while the tank hangs ready, amber while the arm is busy, dark once
## the sentry is down.
func _draw_arm_panel_light() -> void:
	var light: Color = Palette.DIM if sentry_down else (Palette.GREEN if arm_state == &"hung" else Palette.AMBER)
	draw_rect(RoomDepth.prop_rect(arm_panel_art, ARM_PANEL_LIGHT), light.lerp(FLICKER_DARK, 1.0 - lamp_level(&"release")))


## The rods that hang the arm's ceiling plate from the gantry (down to its two bolt blocks,
## ARM_ROD_XS), and, while the tank hangs from the winch (ready, or hauled back up after a miss), the
## steel cable from the arm's shackle down to the tank's lug (a dark braided body with a faint sheen,
## in the painted winch cable's tones). A released tank falls free and lies free: no cable while it
## falls, once it is down, or while a missed one still lies on the floor.
func _draw_arm() -> void:
	var plate_top: float = RoomDepth.prop_bounds(arm_art).position.y + 2.0
	for rod: float in ARM_ROD_XS:
		var rod_x: float = RoomDepth.prop_point(arm_art, Vector2(rod, 0.0)).x
		draw_line(Vector2(rod_x, GANTRY_Y), Vector2(rod_x, plate_top), Palette.STEEL_DARK, 5.0)
		draw_line(Vector2(rod_x - 1.5, GANTRY_Y), Vector2(rod_x - 1.5, plate_top), Palette.STEEL, 1.0)
	if not (arm_state == &"hung" or arm_state == &"rewinding") or tank_on_floor:
		return
	var cable_top: Vector2 = RoomDepth.prop_point(arm_art, ARM_SHACKLE)
	var tank_top: Vector2 = Vector2(DropArm.MARK_X, tank.position.y - TANK_SIZE.y * 0.5)
	draw_line(cable_top, tank_top, CABLE_SHADOW, 4.0)
	draw_line(cable_top, tank_top, CABLE_BODY, 2.5)
	draw_line(cable_top + Vector2(-0.6, 0.0), tank_top + Vector2(-0.6, 0.0), CABLE_SHEEN, 0.8)


## True while the floor brackets are lit: a live sentry's body is over them, so a tank landing now
## would hit it.
func mark_lit() -> bool:
	return door_blown and not sentry_down and sentry.visual.is_lit() and DropArm.is_hit(sentry.target_x)


## The floor brackets and the tank's shadow, both as wide as the tank (DropArm.HIT_RANGE either side
## of the mark). The shadow is laid over the stripes, dimming them and spilling onto the floor either
## side, and darkens and tightens as the tank comes down; the bracket posts stay on top of it. The
## brackets light up while the sentry is in them far enough to be hit (DropArm.is_hit).
func _draw_floor_mark() -> void:
	var left: float = DropArm.MARK_X - DropArm.HIT_RANGE
	var width: float = DropArm.HIT_RANGE * 2.0
	var lit: bool = mark_lit()
	var stripe_color: Color = MARK_LIT if lit else Palette.AMBER
	# The stripes run along the floor line and down onto the walkway in front of it, so a machine
	# standing on the mark covers only their top and the brackets still read below its treads.
	if lit:
		draw_rect(Rect2(left - 2.0, FLOOR_Y, width + 4.0, 10.0), Color(MARK_LIT, 0.28))
	var stripes: int = 7
	for stripe: int in stripes:
		var segment: Rect2 = Rect2(left + stripe * width / stripes, FLOOR_Y - 3.0, width / stripes, 7.0)
		draw_rect(segment, stripe_color if stripe % 2 == 0 else Color("#1a2229"))
	if arm_state != &"landed":
		var shadow: PackedVector2Array = PackedVector2Array()
		var half: Vector2 = Vector2(DropArm.HIT_RANGE * lerpf(1.35, 1.05, tank_drop), lerpf(5.0, 10.0, tank_drop))
		var centre: Vector2 = Vector2(DropArm.MARK_X, SHADOW_Y)
		for step: int in 24:
			shadow.append(centre + Vector2(cos(step * TAU / 24.0) * half.x, sin(step * TAU / 24.0) * half.y))
		draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, lerpf(0.25, 0.85, tank_drop)))
	for edge: float in [left, left + width]:
		draw_line(Vector2(edge, FLOOR_Y - 10.0), Vector2(edge, FLOOR_Y + 10.0), stripe_color, 2.0)


## The exit bolt's lamp as drawn on its panel and on the exit door's status lamp: its light
## (bolt_light_color), dimmed while a refused press flickers it (lamp_level).
func bolt_lamp_color() -> Color:
	return bolt_light_color().lerp(FLICKER_DARK, 1.0 - lamp_level(&"bolt"))


## The exit bolt's light, on its panel and on the exit door's status lamp: red and dead while the
## sentry runs the line, amber once it can take the overload, warming to white through the whine, green once popped.
func bolt_light_color() -> Color:
	if junction_cleared or bolt_state == &"open":
		return Palette.GREEN
	if bolt_state == &"charging":
		return Palette.AMBER.lerp(Color.WHITE, bolt_charge)
	if sentry_down:
		return Palette.AMBER
	return SEAM_RED
