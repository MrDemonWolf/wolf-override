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
## Over the actors (KNOCKDOWN_Z, like the corridor seal's near end): the cross-wall's cut end, the near
## column (dock-corridor-front), so whoever walks through the opening passes behind it.
##
## Every placement is the art set's (compose.py dock(), doors.py DOCK_PIECES, dock_lights): world px at 40
## per metre, the dock room at negative x with the corridor starting at 0 and the shared walk line at
## y 440. Every light goes through DoorKit and RoomDepth.make_glow; this script draws nothing itself.

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

## The room's pieces under the actors.
var room: Node2D
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
	front = Node2D.new()
	front.name = "Front"
	front.z_as_relative = false
	front.z_index = Main.KNOCKDOWN_Z
	add_child(front)
	DoorKit.piece(front, FRONT, FRONT_AT, "NearColumn", 1.0, 1.0 / FRONT_DENSITY)
	set_exit(0.0, 0.0)


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
