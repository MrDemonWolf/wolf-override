class_name DockBay
extends Node2D
## The opening's dock bay (layout L1, approved by Nathanial on 2026-10-14): a short room left of the
## corridor, joined to it by a cased opening in the cross-wall, stacked from the whole pieces of the
## approved art set (2026-10-16). It replaces the backup's grey-box GreyboxBay (codex/opening-dock
## 9b6a2e3) and keeps none of its flat shapes or hand-made light pools.
##
## Back to front, on the mid plate's depth (RoomDepth.Z_MID, under the stations and the actors):
## - the room plate (dock-mid: back wall, lockers, hoist, workbench, the bay lines on the deck), and the
##   light of its two stem-hung fittings;
## - D2, the Director's door in the back wall: a dark passage behind its leaf (dock-exit-leaf), the
##   leaf, which swings away from the room on its left hinges ([method set_exit]), its trim (door light
##   fitting and badge reader, dock-exit-trim), the door light, its pool and the reader's LED;
## - D1, the cased opening to the corridor: the lit corridor seen through it (dock-corridor-beyond), the
##   casing round it (dock-corridor-casing), the door light, the passage's light in and out of the hole
##   and the exit sign (DoorKit.exit_sign, toward the corridor).
## - WOLF's charging dock (dock-charger: the power cabinet with its battery window, the conduit, the
##   wireless pad with its coil ring and lip strip) inside the containment cage's frame (cage-frame: back
##   plate, corner post, lock pilaster, header with the leaves' track and a sealed roof fitting), with the
##   pad's charge light ([method set_charge]), the battery screen (a PropScreen battery readout,
##   [method set_battery]) and the roof fitting's light. WOLF lies, gets up and stands over these.
## Over WOLF while he is inside the cage (CAGE_FRONT_Z; he draws at WOLF_CAGED_Z until he steps out): the four telescoping mesh leaves (three
## cage-leaf, then the lead cage-leaf-lead with the keeper, [method set_lead_travel]), the guard lock
## (cage-lock, its lens lit red-orange while it holds) or, once WOLF forces it, the lock torn off and
## swinging on its cable (cage-lock-torn, [method tear_lock]), and the bay's "door forced" beacon on its
## painted fitting ([method set_beacon]). Once WOLF has stepped down out of the bay he draws over all of
## it, as every actor on the walk line does.
## Over the actors (KNOCKDOWN_Z, like the corridor seal's near end): the cross-wall's cut end, the near
## column (dock-corridor-front), so whoever walks through the opening passes behind it.
##
## Every placement is the art set's (compose.py dock(), doors.py DOCK_PIECES, dock_lights): world px at 40
## per metre, the dock room at negative x with the corridor starting at 0 and the shared walk line at
## y 440. Every light goes through DoorKit, RoomDepth.make_glow and two additive lines on the pad's
## painted ring and lip; this script has no _draw of its own.

## The room plate: its top-left (world px) and its size there (690.3 x 504.1 world px from its
## 1346 x 983 px at 1.95 px per world px; compose.py dock() places it at (-680, 96)).
const PLATE: Texture2D = preload("res://assets/rooms/dock-mid.png")
const PLATE_AT: Vector2 = Vector2(-680.0, 96.0)
const PLATE_DENSITY: float = 1.95
## The room's two stem-hung fittings (their stems, canopies and fittings are painted on the plate):
## the lamps' x, the lamps' y, and their cool light (compose.py dock(): glow radius 22 at 0.5 squashed
## 0.35 on the fitting, radius 60 at 0.12 squashed 0.2 on the deck under it; COOL is (150, 200, 235)).
const PENDANT_XS: PackedFloat32Array = [-250.0, -527.0]
const PENDANT_Y: float = 250.0
const COOL: Color = Color8(150, 200, 235)
## The room's ends for the actors (world px): the end wall's cut is at x -644..-626 (the plate's left
## wall), so the engineer (17 px reach) stops at -606 and WOLF, whose body reaches further, at -556
## (GreyboxBay round 2's marks, which the plate was painted to). The room's right edge is the
## cross-wall's cut end, the near column's right face.
const HUMAN_MIN_X: float = -606.0
const WOLF_MIN_X: float = -556.0
const ROOM_RIGHT: float = 8.0
## The plate's left edge (world px), and the furthest left a view of the room shows: 14 px past the end
## wall's cut (-626), so the dark margin the plate paints beyond the wall (x -680 .. -626) stays out of
## view.
const ROOM_LEFT: float = -680.0
const VIEW_LEFT: float = -640.0

## D2, the Director's door: the leaf (36.2 x 83.5 world px at 5.5 px per world px, a 0.9 x 2.1 m
## personnel door) at its manifest place (compose.py: (-280, 356) plus the piece's 0.18 px offset), hinged
## on its left edge and swinging away from the room through EXIT_OPEN_DEG. Behind it, a dark passage the
## size of the leaf: the passage behind the back wall is unlit (the Director "darkens and goes through").
const EXIT_LEAF: Texture2D = preload("res://assets/doors/dock-exit-leaf.png")
const EXIT_LEAF_AT: Vector2 = Vector2(-280.0, 356.18)
const EXIT_LEAF_DENSITY: float = 5.5
const EXIT_OPEN_DEG: float = 80.0
const EXIT_PASSAGE: Color = Color(0.02, 0.03, 0.04)
## Its trim: the door light's wall pack and the badge reader (doors.py DOCK_PIECES box (-269, 337) plus
## the manifest's 1 px offset; 4 px per world px).
const EXIT_TRIM: Texture2D = preload("res://assets/doors/dock-exit-trim.png")
const EXIT_TRIM_AT: Vector2 = Vector2(-268.0, 338.0)
## doors.py dock_lights: the door light's lens, its pool on the floor in front of the door (radius 22
## at 0.12, squashed 0.8), and the reader's LED (red: the door stays locked to the engineer; green once
## the Director badges).
const EXIT_LIGHT: Vector2 = Vector2(-262.0, 345.0)
const EXIT_POOL: Vector2 = Vector2(-262.0, 400.0)
const EXIT_READER: Vector2 = Vector2(-236.5, 394.5)
## D1, the cased opening to the corridor: the casing (doors.py DOCK_PIECES (-63, 320) plus the manifest's
## 1 px offset, 4 px per world px), and the corridor seen through its hole (DOCK_HOLE (-58, 344) to
## (-10, 437), the piece drawn to fill it).
const CASING: Texture2D = preload("res://assets/doors/dock-corridor-casing.png")
const CASING_AT: Vector2 = Vector2(-62.0, 321.0)
const BEYOND: Texture2D = preload("res://assets/doors/dock-corridor-beyond.png")
const HOLE: Rect2 = Rect2(-58.0, 344.0, 48.0, 93.0)
## doors.py dock_lights: D1's door light (DOCK_PACK_TO), the passage's light low in the hole, its glow
## higher up, its spill out over the threshold onto the dock's deck, each [at, radius, alpha, squash],
## and the exit sign's housing (DOCK_SIGN_TO, centred over the opening).
const CASING_LIGHT: Vector2 = Vector2(-18.0, 333.0)
const HOLE_LIGHTS: Array = [[Vector2(-34.0, 436.0), 14.0, 0.4, 0.3], [Vector2(-34.0, 425.0), 18.0, 0.25, 0.5], [Vector2(-34.0, 446.0), 30.0, 0.22, 0.18]]
const EXIT_SIGN: Rect2 = Rect2(-42.0, 321.0, 16.0, 10.0)
## The near column: the cross-wall's 0.45 m cut concrete end, from over the ceiling to the deck
## (doors.py DOCK_PIECES (-10, 98), 2.4 px per world px).
const FRONT: Texture2D = preload("res://assets/doors/dock-corridor-front.png")
const FRONT_AT: Vector2 = Vector2(-10.0, 98.0)
const FRONT_DENSITY: float = 2.4
## Each painted door piece's density (px per world px), from the art set's manifest.
const TRIM_DENSITY: float = 4.0

## The charging dock (the art set's guides.py DOCK, compose.py DOCK_X): its sprite's left edge and the
## deck's y it stands on, and its top-left (DOCK_Y = 440 - its 76 px guide height, plus the manifest's
## -0.73 px offset), at 5.5 px per world px.
const DOCK_X: float = -521.0
const DOCK_Y: float = 364.0
const CHARGER: Texture2D = preload("res://assets/props/dock-charger.png")
const CHARGER_AT: Vector2 = Vector2(DOCK_X, DOCK_Y - 0.73)
const CHARGER_DENSITY: float = 5.5
## The battery window's glass on the charger (piece px): DOCK window (7.5, 5.5) .. (40.5, 35.5) world px
## from the dock's top-left, less the piece's offset, times its density.
const BATTERY_GLASS: Rect2 = Rect2(41.25, 34.27, 181.5, 165.0)
## The charge light (compose.py charge_light, and DOCK ring, lip and pad): the coil ring's centre and
## radii, the lip strip's ends, the pad's ends and top face, all world px; and its colours (compose.py
## AMBER for charging and standby, WAKE_BLUE when WOLF wakes), with the strength (k) of each state.
const RING_CENTRE: Vector2 = Vector2(DOCK_X + 131.0, DOCK_Y + 68.8)
const RING_RADII: Vector2 = Vector2(40.0, 3.4)
const LIP_FROM: Vector2 = Vector2(DOCK_X + 66.0, DOCK_Y + 74.7)
const LIP_TO: Vector2 = Vector2(DOCK_X + 196.0, DOCK_Y + 74.7)
const PAD_FROM: float = DOCK_X + 62.0
const PAD_TO: float = DOCK_X + 200.0
const PAD_TOP: float = DOCK_Y + 64.5
const AMBER: Color = Color8(240, 160, 50)
const WAKE_BLUE: Color = Color8(70, 140, 255)
const CHARGING_K: float = 0.85
const WAKE_K: float = 1.0
const STANDBY_K: float = 0.45
## The battery's charge while WOLF charges (64 %) and once he is awake (100 %) (compose.py DOCK_BEATS).
const CHARGING_PERCENT: int = 64
const AWAKE_PERCENT: int = 100
## Amber standby breathes: its strength swings this share either way over this many seconds (a slow
## charger "breathing" light; held steady with Reduce Motion).
const BREATHE_SHARE: float = 0.15
const BREATHE_SECONDS: float = 4.0
## The cage's frame (guides.py CAGE frame x 48..211, y -28..76 from the dock's top-left, less the
## manifest's -0.25 px offset), at 4 px per world px.
const FRAME: Texture2D = preload("res://assets/props/cage-frame.png")
const FRAME_AT: Vector2 = Vector2(DOCK_X + 47.75, DOCK_Y - 28.0)
const CAGE_DENSITY: float = 4.0
## The sealed roof fitting under the header (CAGE fitting 110..144, its lens 4.6 px under the header's
## foot at -18) and its cool wash down the back plate (compose.py cage_light: radius 46 at 0.13).
const FITTING_FROM: Vector2 = Vector2(DOCK_X + 112.0, DOCK_Y - 13.4)
const FITTING_TO: Vector2 = Vector2(DOCK_X + 142.0, DOCK_Y - 13.4)
const FITTING_WASH: Vector2 = Vector2(DOCK_X + 127.0, DOCK_Y + 16.6)
## The leaves (CAGE leaf, leaf_top, interior, stack_step): their sprites' top, the clear span they close,
## each leaf's width, and the track pitch they stack at once open; each at 4 px per world px.
const LEAF: Texture2D = preload("res://assets/props/cage-leaf.png")
const LEAD_LEAF: Texture2D = preload("res://assets/props/cage-leaf-lead.png")
const LEAF_TOP: float = DOCK_Y - 18.0
const INTERIOR_FROM: float = 57.0
const INTERIOR_TO: float = 199.0
const LEAF_WIDTH: float = 38.0
const STACK_STEP: float = 3.0
const LEAVES: int = 4
## Layer depths: the leaves and the lock stand behind the walk line, so they draw under the actors
## (CAGE_FRONT_Z, with the stations); only WOLF inside the cage draws under them (WOLF_CAGED_Z, still
## over the room plate), until he steps down out of the bay and Main puts him back at ACTOR_Z (first
## stills, 2026-10-19: with the leaves over every actor, the hanging lock covered WOLF walking past).
const CAGE_FRONT_Z: int = Main.ACTOR_Z - 1
const WOLF_CAGED_Z: int = Main.ACTOR_Z - 2
## The guard lock and the lock torn off (CAGE lock_at and lock_torn_at, plus each piece's manifest
## offset), at 6 px per world px; the lock's lens (on the lock's face, compose.py dock(): pilaster x
## 199 + 4.5, lock_y 21 + 10.5), red-orange while the lock holds (compose.py REDORANGE).
const LOCK: Texture2D = preload("res://assets/props/cage-lock.png")
const LOCK_AT: Vector2 = Vector2(DOCK_X + 191.5, DOCK_Y + 12.17)
const TORN: Texture2D = preload("res://assets/props/cage-lock-torn.png")
const TORN_AT: Vector2 = Vector2(DOCK_X + 184.5, DOCK_Y + 12.17)
const LOCK_DENSITY: float = 6.0
const LOCK_LENS: Vector2 = Vector2(DOCK_X + 203.5, DOCK_Y + 31.5)
const LOCK_LENS_RADIUS: float = 1.2
const REDORANGE: Color = Color8(232, 80, 52)
## The torn lock hangs from its cable's gland at the top of its sprite (est. from the piece: the cable
## leaves its top edge a third in from the right). Torn off, it drops into its hang over LOCK_DROP_S
## (from LOCK_DROP_PX higher) and swings about the gland, LOCK_SWING_DEG at first, dying away over
## LOCK_SWING_S with the period of a pendulum about 0.6 m long (2 pi sqrt(0.6 / 9.81) = 1.55 s; backup
## round 3's drop 0.14 s and swing 1.6 s).
const TORN_GLAND: Vector2 = Vector2(TORN_AT.x + 17.0, TORN_AT.y)
const LOCK_DROP_S: float = 0.14
const LOCK_DROP_PX: float = 4.0
const LOCK_SWING_S: float = 1.6
const LOCK_SWING_DEG: float = 14.0
const LOCK_SWING_PERIOD: float = 1.55
## The bay's "door forced" beacon (decision 6, recommended: no new art): its lens on the beacon fitting
## painted on the back wall above the lock pilaster (the room plate was painted from the backup's
## shapes, whose beacon lens was this rect's centre, (-307.6, 295.3) 5.2 x 6.3), lit and flashing as the
## corridor's caged beacons do (main.tscn CorridorDepth: peak 0.55, trough 0.12, lens trough 0.6, the
## rotating-beacon rhythm), and its glow on the wall round it.
const BEACON_LENS: Vector2 = Vector2(-305.0, 298.5)
const BEACON_LENS_RADIUS: float = 2.4
const BEACON_GLOW: Vector2 = Vector2(110.0, 90.0)
const BEACON_PEAK: float = 0.55
const BEACON_TROUGH: float = 0.12
const BEACON_LENS_TROUGH: float = 0.6
## WOLF's pieces on the pad: lying belly-down while he charges (wolf-lie-pad, 8 px per world px) and
## getting up off it (wolf-rise, 6 px per world px). Main's _wolf_pose draws each at the standing piece's
## density (8) over its own, times WOLF_ART_SCALE, so he keeps one size whatever his pose.
const WOLF_LIE: Texture2D = preload("res://assets/characters/wolf-lie-pad.png")
const WOLF_RISE: Texture2D = preload("res://assets/characters/wolf-rise.png")
const WOLF_LIE_SCALE: float = 8.0 / 8.0
const WOLF_RISE_SCALE: float = 8.0 / 6.0
## WOLF's marks in the bay (world px, his origin's x), from the art set's compose.py dock(): lying,
## centred where its still lies him (DOCK wolf_x 64 plus half the piece's 127 px); getting up, his
## haunch where the lying piece's was; standing at the latch, his snout at the pad's head (DOCK_X + 196);
## and out in front of the cage, his snout OUT_GAP (0.3 m, compose.py OUT_GAP) clear of the hanging lock,
## where the art review of 2026-10-16 asked for it (touching, the lock read as carried in his mouth).
const LIE_X: float = DOCK_X + 127.5
const LIE_HALF: float = 1016.0 * Main.WOLF_ART_SCALE * WOLF_LIE_SCALE * 0.5
const RISE_HALF: float = 743.0 * Main.WOLF_ART_SCALE * WOLF_RISE_SCALE * 0.5
const RISE_X: float = LIE_X - LIE_HALF + RISE_HALF
const LATCH_X: float = DOCK_X + 196.0 - M0Actor.WOLF_SNOUT
const OUT_GAP: float = 12.0
const OUT_X: float = TORN_AT.x - OUT_GAP - M0Actor.WOLF_SNOUT
## On the pad his feet stand on its top face (DOCK wolf_floor, y 435), 3.4 px above where his feet are
## drawn on the deck (his origin at y 423 puts them at 438.4); stepped out of the bay he stands this far
## toward the camera on the bay floor (backup round 4: 12 px, so his lane clears the bay's face).
const PAD_LIFT: float = -3.4
const STEP_DOWN: float = 12.0
## The corridor's lockdown light seen through the opening (decision 7: it comes on with "Lock down
## maintenance", inside the opening's view): the corridor's red warning light spilling into the passage
## beyond the hole and out over its threshold, flashing in the corridor beacons' rhythm (est., tuned on
## rendered stills: the hole's middle, a glow a little wider than the hole, as strong as a beacon's).
const LOCKDOWN_AT: Vector2 = Vector2(-34.0, 395.0)
const LOCKDOWN_GLOW: Vector2 = Vector2(70.0, 130.0)
const LOCKDOWN_PEAK: float = 0.35
## The leaves' push (decision 3, recommended; Q-F, "shoulders the leaves aside, calm and deliberate";
## backup round 3, review-real-2 S8): WOLF takes the lead leaf SWEEP_PX, accelerating it over
## SWEEP_ACCEL_S to LEAF_V0 and holding it there; released, the moving leaves coast to the stop with
## one rolling deceleration. Each intermediate leaf is caught as the lead passes it; the second catch is
## after the release, an inelastic catch that drops the speed to 2/3 (two leaves' momentum shared by
## three). World px and seconds.
const SWEEP_PX: float = 42.0
const SWEEP_ACCEL_S: float = 0.3
const LEAF_V0: float = 85.0

## The room's pieces under the actors.
var room: Node2D
## The pad's charge light (its ring, lip and glows; the node's modulate carries colour and strength).
var charge: Node2D
var battery: PropScreen
## The leaves, the lock and the beacon over WOLF.
var cage_front: Node2D
var leaves: Array[Sprite2D] = []
var lock: Sprite2D
var lock_lens: DoorKit.Lamp
var torn_pivot: Node2D
var beacon_lens: DoorKit.Lamp
var beacon_glow: Sprite2D
## The charge light's colour and strength (0 off), and whether it breathes (amber standby).
var charge_color: Color = AMBER
var charge_k: float = 0.0
var breathing: bool = false
## How far the lead leaf has slid open (world px, 0 shut .. lead_open_travel() stacked).
var lead_travel: float = 0.0
## True once WOLF has torn the guard lock off; seconds since then (its drop and swing), or -1.
var lock_torn: bool = false
var lock_age: float = -1.0
var beacon_on: bool = false
## The corridor's lockdown light through the opening (set_lockdown).
var lockdown_glow: Sprite2D
var lockdown_on: bool = false
var _lockdown_tween: Tween
## Reduce Motion (Main copies impact.reduce_motion): the beacon holds lit, the lock does not swing and
## the standby light does not breathe.
var reduce_motion: bool = false
var _beacon_tween: Tween
var _clock: float = 0.0
## The cross-wall's cut end over the actors.
var front: Node2D
## The Director's door leaf (its scale.x carries the swing) and the dark passage behind it.
var exit_leaf: Sprite2D
var exit_passage: Polygon2D
var exit_reader: DoorKit.Lamp
## 0 shut .. 1 open (EXIT_OPEN_DEG); 0 dim red .. 1 green (accepted). See [method set_exit].
var exit_open: float = 0.0
var reader_ok: float = 0.0


func _ready() -> void:
	name = "DockBay"
	room = Node2D.new()
	room.name = "Room"
	room.z_as_relative = false
	room.z_index = RoomDepth.Z_MID
	add_child(room)
	room.add_child(RoomDepth.cut(PLATE, Rect2(Vector2.ZERO, PLATE.get_size()), 1.0 / PLATE_DENSITY, "Plate", PLATE_AT))
	for index: int in PENDANT_XS.size():
		var x: float = PENDANT_XS[index]
		DoorKit.glow(room, "Pendant%d" % index, Vector2(x, PENDANT_Y), 22.0, COOL, 0.5, 0.35)
		DoorKit.glow(room, "PendantPool%d" % index, Vector2(x, RoomDepth.FLOOR_Y + 6.0), 60.0, COOL, 0.12, 0.2)
	_build_exit()
	_build_opening()
	_build_dock()
	_build_cage_front()
	front = Node2D.new()
	front.name = "Front"
	front.z_as_relative = false
	front.z_index = Main.KNOCKDOWN_Z
	add_child(front)
	DoorKit.piece(front, FRONT, FRONT_AT, "NearColumn", 1.0, 1.0 / FRONT_DENSITY)
	set_exit(0.0, 0.0)
	set_standby()


## D2: the passage, the leaf on its hinges, the trim, and the door light, its pool and the reader's LED.
func _build_exit() -> void:
	var size: Vector2 = EXIT_LEAF.get_size() / EXIT_LEAF_DENSITY
	exit_passage = Polygon2D.new()
	exit_passage.name = "ExitPassage"
	exit_passage.polygon = PackedVector2Array([EXIT_LEAF_AT, EXIT_LEAF_AT + Vector2(size.x, 0.0), EXIT_LEAF_AT + size, EXIT_LEAF_AT + Vector2(0.0, size.y)])
	exit_passage.color = EXIT_PASSAGE
	room.add_child(exit_passage)
	exit_leaf = RoomDepth.cut(EXIT_LEAF, Rect2(Vector2.ZERO, EXIT_LEAF.get_size()), 1.0 / EXIT_LEAF_DENSITY, "ExitLeaf", EXIT_LEAF_AT)
	room.add_child(exit_leaf)
	DoorKit.piece(room, EXIT_TRIM, EXIT_TRIM_AT, "ExitTrim", 1.0, 1.0 / TRIM_DENSITY)
	DoorKit.door_light(room, EXIT_LIGHT).name = "ExitDoorLight"
	DoorKit.glow(room, "ExitPool", EXIT_POOL, 22.0, DoorKit.DOOR_LIGHT_COLOR, 0.12, 0.8)
	exit_reader = DoorKit.lamp(room, "ExitReader", EXIT_READER, Palette.LAMP_SHUT, DoorKit.READER_LED_RADIUS)


## D1: the corridor through the hole, the casing round it, then their light and the exit sign.
func _build_opening() -> void:
	var beyond: Sprite2D = RoomDepth.cut(BEYOND, Rect2(Vector2.ZERO, BEYOND.get_size()), 1.0, "Beyond", HOLE.position)
	beyond.scale = HOLE.size / BEYOND.get_size()
	room.add_child(beyond)
	DoorKit.piece(room, CASING, CASING_AT, "Casing", 1.0, 1.0 / TRIM_DENSITY)
	DoorKit.door_light(room, CASING_LIGHT).name = "CasingDoorLight"
	for index: int in HOLE_LIGHTS.size():
		var light: Array = HOLE_LIGHTS[index]
		DoorKit.glow(room, "HoleLight%d" % index, light[0], light[1], DoorKit.DOOR_LIGHT_COLOR, light[2], light[3])
	DoorKit.exit_sign(room, EXIT_SIGN, 1.0)


## The Director's door: [param open] 0 shut .. 1 swung EXIT_OPEN_DEG away from the room on its left
## hinges (drawn as the leaf's width foreshortened by the cosine of the angle, the hinge edge fixed;
## the passage behind shows only while it is open), and [param reader] 0 (the LED red, locked) .. 1
## (green, accepted).
func set_exit(open: float, reader: float) -> void:
	exit_open = clampf(open, 0.0, 1.0)
	reader_ok = clampf(reader, 0.0, 1.0)
	exit_leaf.scale.x = cos(deg_to_rad(EXIT_OPEN_DEG * exit_open)) / EXIT_LEAF_DENSITY
	exit_passage.visible = exit_open > 0.0
	exit_reader.color = Palette.LAMP_SHUT.lerp(Palette.LAMP_OPEN, reader_ok)


## True when world x [param x] is inside the dock room (left of the cross-wall's cut end).
static func contains_x(x: float) -> bool:
	return x < ROOM_RIGHT


## The charger, the cage's frame, the pad's charge light, the battery screen and the roof fitting's
## light, under WOLF.
func _build_dock() -> void:
	var charger: Sprite2D = DoorKit.piece(room, CHARGER, CHARGER_AT, "Charger", 1.0, 1.0 / CHARGER_DENSITY)
	DoorKit.piece(room, FRAME, FRAME_AT, "CageFrame", 1.0, 1.0 / CAGE_DENSITY)
	charge = Node2D.new()
	charge.name = "Charge"
	room.add_child(charge)
	# compose.py charge_light: the ring traced as small glows (radius 1.8 at 0.6), the lip as a row of
	# them (1.3 at 0.9), the pad's top face (0.9 of the ring at 0.25, squashed 0.12), the spill on the
	# deck in front of the lip, the bounce up the back plate behind WOLF across the whole pad and the pool
	# on the deck in front of the cage. A traced row of glows reads as a lit line with a soft edge: here a
	# thin bright line over a wider faint one.
	var ring: PackedVector2Array = PackedVector2Array()
	for step: int in 49:
		ring.append(RING_CENTRE + Vector2(cos(TAU * step / 48.0), sin(TAU * step / 48.0)) * RING_RADII)
	_charge_line("RingSoft", ring, 3.6, 0.25)
	_charge_line("Ring", ring, 1.1, 0.7)
	_charge_line("LipSoft", PackedVector2Array([LIP_FROM, LIP_TO]), 3.0, 0.3)
	_charge_line("Lip", PackedVector2Array([LIP_FROM, LIP_TO]), 1.0, 0.9)
	var pad_middle: float = (PAD_FROM + PAD_TO) * 0.5
	DoorKit.glow(charge, "PadTop", RING_CENTRE, RING_RADII.x * 0.9, Color.WHITE, 0.25, 0.12)
	DoorKit.glow(charge, "Spill", Vector2((LIP_FROM.x + LIP_TO.x) * 0.5, RoomDepth.FLOOR_Y + 4.0), (LIP_TO.x - LIP_FROM.x) * 0.5, Color.WHITE, 0.3, 0.1)
	DoorKit.glow(charge, "Bounce", Vector2(pad_middle, PAD_TOP - 8.0), (PAD_TO - PAD_FROM) * 0.55, Color.WHITE, 0.5, 0.35)
	DoorKit.glow(charge, "Pool", Vector2(pad_middle, RoomDepth.FLOOR_Y + 10.0), (PAD_TO - PAD_FROM) * 0.62, Color.WHITE, 0.5, 0.09)
	battery = PropScreen.attach(charger, "Battery", BATTERY_GLASS, AMBER)
	battery.readout = PropScreen.Readout.BATTERY
	var fitting: Line2D = _line(room, "RoofFitting", PackedVector2Array([FITTING_FROM, FITTING_TO]), 1.2, Color(COOL, 0.55))
	fitting.material = FxKit.additive()
	DoorKit.glow(room, "RoofWash", FITTING_WASH, 46.0, COOL, 0.13, 0.9)


## An additive line of the charge light: white, at [param alpha] of the light's strength (Charge's
## modulate carries its colour and strength).
func _charge_line(line_name: String, points: PackedVector2Array, width: float, alpha: float) -> void:
	_line(charge, line_name, points, width, Color(1.0, 1.0, 1.0, alpha)).material = FxKit.additive()


## A Line2D named [param line_name] through [param points] (world px), [param width] px wide, in
## [param color], added to [param parent].
static func _line(parent: Node, line_name: String, points: PackedVector2Array, width: float, color: Color) -> Line2D:
	var line: Line2D = Line2D.new()
	line.name = line_name
	line.points = points
	line.width = width
	line.default_color = color
	line.antialiased = true
	parent.add_child(line)
	return line


## The leaves, the guard lock and its lens, the torn lock on its pivot (hidden until the tear) and the
## bay's beacon, over WOLF inside the cage.
func _build_cage_front() -> void:
	cage_front = Node2D.new()
	cage_front.name = "CageFront"
	cage_front.z_as_relative = false
	cage_front.z_index = CAGE_FRONT_Z
	add_child(cage_front)
	for index: int in LEAVES:
		var art: Texture2D = LEAD_LEAF if index == LEAVES - 1 else LEAF
		leaves.append(DoorKit.piece(cage_front, art, Vector2(DOCK_X + leaf_x(index, 0.0), LEAF_TOP), "Leaf%d" % index, 1.0, 1.0 / CAGE_DENSITY))
	lock = DoorKit.piece(cage_front, LOCK, LOCK_AT, "Lock", 1.0, 1.0 / LOCK_DENSITY)
	lock_lens = DoorKit.lamp(cage_front, "LockLens", LOCK_LENS, REDORANGE, LOCK_LENS_RADIUS)
	torn_pivot = Node2D.new()
	torn_pivot.name = "TornLock"
	torn_pivot.position = TORN_GLAND
	cage_front.add_child(torn_pivot)
	DoorKit.piece(torn_pivot, TORN, TORN_AT - TORN_GLAND, "Torn", 1.0, 1.0 / LOCK_DENSITY)
	beacon_glow = RoomDepth.make_glow(RoomDepth.WARNING_RED, BEACON_GLOW, BEACON_PEAK)
	beacon_glow.name = "BeaconGlow"
	beacon_glow.position = BEACON_LENS
	room.add_child(beacon_glow)
	beacon_lens = DoorKit.lamp(room, "BeaconLens", BEACON_LENS, RoomDepth.WARNING_RED, BEACON_LENS_RADIUS)
	lockdown_glow = RoomDepth.make_glow(RoomDepth.WARNING_RED, LOCKDOWN_GLOW, LOCKDOWN_PEAK)
	lockdown_glow.name = "LockdownGlow"
	lockdown_glow.position = LOCKDOWN_AT
	room.add_child(lockdown_glow)


func _process(delta: float) -> void:
	_clock += delta
	var k: float = charge_k
	if breathing and not reduce_motion:
		k *= 1.0 + BREATHE_SHARE * sin(TAU * _clock / BREATHE_SECONDS)
	charge.modulate = Color(charge_color, clampf(k, 0.0, 1.0))
	if lock_torn and lock_age >= 0.0:
		lock_age += delta
		var pose: Vector2 = torn_pose(lock_age, reduce_motion)
		torn_pivot.position = TORN_GLAND + Vector2(0.0, pose.x)
		torn_pivot.rotation_degrees = pose.y


## The pad's charge light in [param color] at strength [param k] (0 dark: the charge cut), breathing
## when [param breathe] (amber standby).
func set_charge(color: Color, k: float, breathe: bool = false) -> void:
	charge_color = color
	charge_k = k
	breathing = breathe
	charge.visible = k > 0.0
	charge.modulate = Color(color, k)


## The battery screen: [param percent] 0 .. 100 in [param color], or PropScreen.BATTERY_OFF (dark) or
## PropScreen.BATTERY_IDLE (the outline only, dim).
func set_battery(percent: int, color: Color = AMBER) -> void:
	battery.tint = color
	battery.percent = percent


## WOLF wakes: [param t] 0 (charging: amber, 64 %) .. 1 (awake: blue, 100 %), the light and the screen
## easing between them (the screen's number steps at the end).
func set_wake(t: float) -> void:
	var color: Color = AMBER.lerp(WAKE_BLUE, t)
	set_charge(color, lerpf(CHARGING_K, WAKE_K, t))
	set_battery(AWAKE_PERCENT if t >= 1.0 else CHARGING_PERCENT, color)


## The lead leaf slid [param travel] world px open (0 shut .. lead_open_travel()); the other leaves are
## picked up as it reaches them and stack behind it.
func set_lead_travel(travel: float) -> void:
	lead_travel = clampf(travel, 0.0, lead_open_travel())
	for index: int in LEAVES:
		leaves[index].position.x = DOCK_X + leaf_x(index, lead_travel)


## WOLF forces the guard lock: it is torn off its mount and drops onto its cable, swinging, and its lens
## goes dark with the cable it was fed through (decision 5, recommended: the bay's beacon is the one red).
func tear_lock() -> void:
	lock_torn = true
	lock_age = 0.0
	lock.visible = false
	lock_lens.visible = false
	torn_pivot.visible = true


## The bay's "door forced" beacon on (flashing, held lit with Reduce Motion) or off (dark).
func set_beacon(on: bool) -> void:
	beacon_on = on
	Tweens.kill(_beacon_tween)
	_beacon_tween = null
	beacon_glow.visible = on
	beacon_lens.visible = on
	beacon_glow.modulate.a = BEACON_PEAK
	beacon_lens.color = RoomDepth.WARNING_RED
	if on and not reduce_motion:
		_beacon_tween = RoomDepth.pulse(self, beacon_glow, beacon_lens, &"color", RoomDepth.WARNING_RED, BEACON_PEAK, BEACON_TROUGH, BEACON_LENS_TROUGH, true, 0.0)


## The corridor's lockdown light through the opening on (flashing; held lit with Reduce Motion) or off.
func set_lockdown(on: bool) -> void:
	lockdown_on = on
	Tweens.kill(_lockdown_tween)
	_lockdown_tween = null
	lockdown_glow.visible = on
	lockdown_glow.modulate.a = LOCKDOWN_PEAK
	if on and not reduce_motion:
		_lockdown_tween = RoomDepth.pulse(self, lockdown_glow, null, &"", RoomDepth.WARNING_RED, LOCKDOWN_PEAK, BEACON_TROUGH, 0.0, true, 0.0)


## The opening's first frame: WOLF charging on the pad (amber, 64 %), the cage shut and locked, the
## beacon and the corridor's lockdown light dark.
func set_standby() -> void:
	set_charge(AMBER, CHARGING_K, true)
	set_battery(CHARGING_PERCENT, AMBER)
	set_lead_travel(0.0)
	lock_torn = false
	lock_age = -1.0
	lock.visible = true
	lock_lens.visible = true
	torn_pivot.visible = false
	set_beacon(false)
	set_lockdown(false)


## The bay after the opening, empty and quiet: the pad back on slow amber standby with the screen
## showing only the empty battery's outline, the leaves stacked open, the torn lock hanging still, its
## lens and the beacon dark (decisions 4 and 5, recommended).
func set_empty_quiet() -> void:
	set_charge(AMBER, STANDBY_K, true)
	set_battery(PropScreen.BATTERY_IDLE, AMBER)
	set_lead_travel(lead_open_travel())
	tear_lock()
	lock_age = -1.0
	torn_pivot.position = TORN_GLAND
	torn_pivot.rotation_degrees = 0.0
	set_beacon(false)
	set_exit(0.0, 0.0)


## The torn lock's hang [param age] seconds after the tear: Vector2(how far above its rest it still is,
## world px; its swing about the gland, degrees). Still at once with [param still] (Reduce Motion).
static func torn_pose(age: float, still: bool = false) -> Vector2:
	if still or age >= LOCK_DROP_S + LOCK_SWING_S:
		return Vector2.ZERO
	if age < LOCK_DROP_S:
		var u: float = age / LOCK_DROP_S
		return Vector2(-LOCK_DROP_PX * (1.0 - u * u), LOCK_SWING_DEG * u)
	var swing: float = age - LOCK_DROP_S
	return Vector2(0.0, LOCK_SWING_DEG * exp(-3.0 * swing / LOCK_SWING_S) * cos(TAU * swing / LOCK_SWING_PERIOD))


## Leaf [param index]'s left edge (dock-local world px: add DOCK_X) with the lead leaf slid [param
## travel] open. Shut, the four overlap evenly across the interior and the lead meets the pilaster
## (guides.py cage_leaf_x at 0); the lead slides left and catches each leaf as it reaches it, and they
## stack STACK_STEP apart at the left post (cage_leaf_x at 1).
static func leaf_x(index: int, travel: float) -> float:
	var lead: float = _leaf_shut(LEAVES - 1) - travel
	return minf(_leaf_shut(index), lead - (LEAVES - 1 - index) * STACK_STEP)


## Leaf [param index]'s shut left edge (dock-local world px).
static func _leaf_shut(index: int) -> float:
	return INTERIOR_FROM + index * (INTERIOR_TO - INTERIOR_FROM - LEAF_WIDTH) / float(LEAVES - 1)


## How far the lead leaf slides from shut to stacked (world px).
static func lead_open_travel() -> float:
	return _leaf_shut(LEAVES - 1) - INTERIOR_FROM - (LEAVES - 1) * STACK_STEP


## The lead's travel (world px) at which it catches leaf [param index] (index < LEAVES - 1).
static func catch_travel(index: int) -> float:
	return _leaf_shut(LEAVES - 1) - _leaf_shut(index) - (LEAVES - 1 - index) * STACK_STEP


## The leaves' motion (backup round 3, leaf_plan, carried to the cage's geometry): the sweep holds
## LEAF_V0 through the first catch; released at SWEEP_PX with two leaves moving, they decelerate at a
## (rolling friction, the same for any number of leaves); at the second catch the speed drops to 2/3,
## and the three stop at the open stop. a is chosen so they stop exactly there:
## v0^2 = 2 a lb + (3/2)^2 2 a lc. Keys: sweep_s, coast_b_s, coast_c_s (seconds), a (px/s^2),
## catch_1_px, catch_2_px, total (px), v_b_end, v_c0 (px/s).
static func leaf_plan() -> Dictionary:
	var total: float = lead_open_travel()
	var catch_1: float = catch_travel(LEAVES - 2)
	var catch_2: float = catch_travel(LEAVES - 3)
	var lb: float = catch_2 - SWEEP_PX
	var lc: float = total - catch_2
	var a: float = LEAF_V0 * LEAF_V0 / (2.0 * lb + 4.5 * lc)
	var v_b_end: float = sqrt(4.5 * a * lc)
	var v_c0: float = v_b_end * 2.0 / 3.0
	return {
		"sweep_s": SWEEP_ACCEL_S + (SWEEP_PX - 0.5 * LEAF_V0 * SWEEP_ACCEL_S) / LEAF_V0,
		"a": a, "coast_b_s": (LEAF_V0 - v_b_end) / a, "coast_c_s": v_c0 / a,
		"catch_1_px": catch_1, "catch_2_px": catch_2,
		"v_b_end": v_b_end, "v_c0": v_c0, "total": total,
	}


## The sweep plus the coast, in seconds.
static func leaf_seconds() -> float:
	var plan: Dictionary = leaf_plan()
	return float(plan["sweep_s"]) + float(plan["coast_b_s"]) + float(plan["coast_c_s"])


## How far the lead leaf has travelled (world px) [param t] seconds after WOLF first pushes it.
static func leaf_travel(t: float) -> float:
	var plan: Dictionary = leaf_plan()
	var accel: float = LEAF_V0 / SWEEP_ACCEL_S
	var sweep_s: float = plan["sweep_s"]
	var a: float = plan["a"]
	var tb: float = plan["coast_b_s"]
	if t <= SWEEP_ACCEL_S:
		return 0.5 * accel * t * t
	if t <= sweep_s:
		return 0.5 * LEAF_V0 * SWEEP_ACCEL_S + LEAF_V0 * (t - SWEEP_ACCEL_S)
	var c: float = t - sweep_s
	if c <= tb:
		return SWEEP_PX + LEAF_V0 * c - 0.5 * a * c * c
	var c2: float = minf(c - tb, float(plan["coast_c_s"]))
	return float(plan["catch_2_px"]) + float(plan["v_c0"]) * c2 - 0.5 * a * c2 * c2


## The time after the push starts when the lead leaf has travelled [param px] (the catch clunks), by
## bisection over the monotonic leaf_travel.
static func leaf_time_at(px: float) -> float:
	var lo: float = 0.0
	var hi: float = leaf_seconds()
	for _i: int in 40:
		var mid: float = (lo + hi) * 0.5
		if leaf_travel(mid) < px:
			lo = mid
		else:
			hi = mid
	return hi
