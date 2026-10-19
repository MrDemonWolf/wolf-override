extends Node2D
class_name RecordsRoom

const RECORDS_FAR: Texture2D = preload("res://assets/rooms/records-far.png")
const RECORDS_MID: Texture2D = preload("res://assets/rooms/records-mid.png")
const RECORDS_NEAR: Texture2D = preload("res://assets/rooms/records-near.png")
## The two stations and the security container are whole pieces of the approved art set (2026-10-16),
## painted with their screens and lights dark: the screens (PropScreen) and status lights are drawn here.
const PURGE_QUEUE: Texture2D = preload("res://assets/props/records-purge-queue.png")
const MIRROR_PORT: Texture2D = preload("res://assets/props/records-mirror-port.png")
const CONTAINER: Texture2D = preload("res://assets/props/records-container.png")
## The Records doors (design: 1cf8d73:docs/research-2026-10/sources/doors-2026-10-14/records/). Each end of the
## room is a 300 mm cast cross-wall turned 17 degrees across the walkway, like the corridor's, with a
## 3'0" x 7'0" steel secure-area door in it: the entry on the left (the way in from the corridor
## side) and the exit on the right (out to the service line passage toward Archive). Each leaf swings
## into the room on its hinges at the far jamb (SwingLeaf), opened and closed by a concealed operator in
## its header; nothing fades. The first copy is secured in the GSA security container left of the exit,
## not at the door (its own whole piece, CONTAINER). The doors are whole pieces of the approved art set
## (2026-10-16; its doors/DESIGN.md D5 and D6), stacked by DoorKit: behind the mid plate each door's lit
## next space ("-back"), the light through its hole and its cross-wall's face ("-wall"); over the mid
## plate the leaves, the entry's near end ("-front", which nobody passes behind: the entry stops the
## engineer and WOLF short of it), the door lights and, over the exit, the exit sign; over the actors
## the exit's near end with the badge reader. Each column's status lamp and the reader's LED are live
## DoorKit lamps. Positions are each piece's world top-left (the art set's doors.py piece_box plus the
## manifest offset).
const ENTRY_BACK: Texture2D = preload("res://assets/doors/records-entry-back.png")
const ENTRY_WALL: Texture2D = preload("res://assets/doors/records-entry-wall.png")
const ENTRY_FRONT: Texture2D = preload("res://assets/doors/records-entry-front.png")
const EXIT_BACK: Texture2D = preload("res://assets/doors/records-exit-back.png")
const EXIT_WALL: Texture2D = preload("res://assets/doors/records-exit-wall.png")
const EXIT_FRONT: Texture2D = preload("res://assets/doors/records-exit-front.png")
const ENTRY_BACK_AT: Vector2 = Vector2(-10.0, 0.0)
const ENTRY_WALL_AT: Vector2 = Vector2(56.71, 0.0)
const ENTRY_FRONT_AT: Vector2 = Vector2(-10.0, 0.0)
const EXIT_BACK_AT: Vector2 = Vector2(851.66, 0.0)
const EXIT_WALL_AT: Vector2 = Vector2(791.96, 0.0)
const EXIT_FRONT_AT: Vector2 = Vector2(889.40, 0.0)
## Each opening on its wall's face, foot to head (doors.py W(a, h, 0) at a -0.46 and 0.46 m, h 0 and
## 2.14 m), the light added through it (est., tuned on rendered captures until the passage reads at
## least 1.5 times the wall round it; the exit, the room's goal, the brighter, as the art set lit it), the
## door light's pool on the threshold and graze on the far reveal, and its wall pack's lens.
const ENTRY_HOLE: PackedVector2Array = [Vector2(59.71, 443.30), Vector2(80.05, 436.78), Vector2(80.05, 352.16), Vector2(59.71, 356.69)]
const EXIT_HOLE: PackedVector2Array = [Vector2(890.08, 443.30), Vector2(870.15, 436.78), Vector2(870.15, 352.16), Vector2(890.08, 356.69)]
const ENTRY_HOLE_LIGHT: Color = Color(0.05, 0.06, 0.07)
const EXIT_HOLE_LIGHT: Color = Color(0.12, 0.14, 0.15)
const ENTRY_POOL: Vector2 = Vector2(64.75, 439.68)
const ENTRY_GRAZE: Vector2 = Vector2(74.85, 385.75)
const ENTRY_DOOR_LIGHT: Vector2 = Vector2(87.58, 339.54)
const EXIT_POOL: Vector2 = Vector2(885.27, 439.68)
const EXIT_GRAZE: Vector2 = Vector2(875.37, 385.75)
const EXIT_DOOR_LIGHT: Vector2 = Vector2(862.74, 339.54)
## The exit's flag sign over its head (doors.py sign_at: bracket 0.40 m toward the latch side).
const EXIT_SIGN: Rect2 = Rect2(872.99, 343.50, 14.25, 8.69)
## Each leaf's fill (SwingLeaf.fill): the ambient and the broad floor bounce, which reach every face the
## door light misses (fix round 4, review r4 M1; see EXIT_LEAF_LIGHTS).
const EXIT_LEAF_FILL: float = 0.0370
const ENTRY_LEAF_FILL: float = 0.0509
## The EXIT caption's centre: over the exit sign that hangs square off the cross-wall over the door,
## clear of the near column (x 890 on).
const EXIT_LABEL_X: float = 862.0
## Its top edge: just over the sign's housing (y 343.5).
const EXIT_LABEL_Y: float = 322.0
## Where each shut leaf's room face crosses the walk line (y 440): the doors' collision faces.
const EXIT_DOOR_X: float = 880.0
const ENTRY_DOOR_X: float = 70.0
## Each doorway on the walk line (world px, x from .x to .y), read by door_route_test and
## wolf_space_test. The exit's runs from its shut leaf's room face to the near column's far side (the
## column's cut end face at the walk line, doors.py W(-0.57, 0, 0.30)), so an engineer walking out has
## passed it once their origin is beyond .y; the entry's runs from its near column's room side (W(-0.57,
## 0, 0.30) of the entry) to its shut leaf's room face. The room side of a shut face is open floor.
const EXIT_COLUMN_FAR_X: float = 903.19
## The passage seen past the exit wall's near end (EXIT_BACK right of the column's far arris, x 903.2, down
## to its floor's near edge, doors.py "next space floor"), shaded (DoorKit.PAST_END_SHADE) so it never
## outshines the doorway; the column covers its left edge and the curb its foot.
const EXIT_PAST_END: PackedVector2Array = [Vector2(903.2, 0.0), Vector2(975.0, 0.0), Vector2(975.0, 466.6), Vector2(903.2, 443.4)]
const ENTRY_COLUMN_FAR_X: float = 46.59
const EXIT_SPAN: Vector2 = Vector2(EXIT_DOOR_X, EXIT_COLUMN_FAR_X)
const ENTRY_SPAN: Vector2 = Vector2(ENTRY_COLUMN_FAR_X, ENTRY_DOOR_X)
## The guarded status lamps on the near columns' end faces (their glass is the live lens), and the exit's
## badge reader's LED at 1.1 m under its lamp (doors.py socket_parts: 48 world px lower).
const EXIT_LAMP: Vector2 = Vector2(901.665, 345.264)
const ENTRY_LAMP: Vector2 = Vector2(48.018, 345.264)
const EXIT_READER: Vector2 = Vector2(901.665, 393.264)
## The leaves' hinge axes (foot, metres: x along the room, h up, d behind the walk line) and their
## walls' plan axes (U along the face toward the back wall, N into the wall), from rdesign.py.
const EXIT_HINGE: Vector3 = Vector3(21.85451, 0.0, 0.43655)
const EXIT_AXIS_U: Vector3 = Vector3(-0.291329, 0.0, 0.956623)
const EXIT_AXIS_N: Vector3 = Vector3(0.956623, 0.0, 0.291329)
const ENTRY_HINGE: Vector3 = Vector3(1.89549, 0.0, 0.43655)
const ENTRY_AXIS_U: Vector3 = Vector3(0.291329, 0.0, 0.956623)
const ENTRY_AXIS_N: Vector3 = Vector3(-0.956623, 0.0, 0.291329)
## The GSA Class 5 security container (0.53 x 1.486 x 0.851 m) where the first copy is secured: the
## centre of its front, and its drawn body (side panel to front right edge) for WOLF to keep off.
## The piece (86 x 146 px at 2 px per world px: 43 x 73 world px) is a wheeled steel cabinet with a lid
## and a handle, painted without the Class 5's dial or lock (the art set's waste/records container), so it
## reads more as a bin than a safe; whether to repaint it is an open question for Nathanial. It is drawn
## centred on CONTAINER_X with its base CONTAINER_BASE_Y, where the earlier container's base stood (its
## wheels on the deck just in front of the walk line), so CONTAINER_SPAN still holds.
const CONTAINER_X: float = 797.0
const CONTAINER_SCALE: float = 0.5
const CONTAINER_BASE_Y: float = 442.0
const CONTAINER_SPAN: Vector2 = Vector2(776.0, 807.0)
## A low-energy operator swings the exit's leaf open: ANSI/BHMA A156.19 asks 3 s or longer to
## backcheck or 80 degrees, so 90 degrees takes this long. The entry's closer brings its leaf shut
## behind the engineer a moment after they come in (SwingLeaf.close_behind's timing).
const EXIT_SWING_SECONDS: float = 3.5
## Each station is one whole piece at its real size (the art set's PIECES.md section 5c), its base on
## the floor: the PURGE QUEUE 447 x 442 px at 6.135 px per world px (72.9 x 72 world px, 1.82 x 1.80 m;
## it was drawn 2.8 m tall) and the MIRROR PORT, a 42U equipment rack, 352 x 443 px at 5.54 px per world
## px (63.5 x 80 world px, 1.59 x 2.0 m; it was 2.77 m).
## Each piece's own pixel size (piece px, records-purge-queue.png and records-mirror-port.png, as the
## asset register lists them), centre x (world px) and scale (world px per piece px).
const PURGE_SIZE: Vector2 = Vector2(447.0, 442.0)
const PURGE_X: float = 190.0
const PURGE_SCALE: float = 1.0 / 6.135
const MIRROR_SIZE: Vector2 = Vector2(352.0, 443.0)
const MIRROR_X: float = 520.0
const MIRROR_SCALE: float = 1.0 / 5.5402
## Half each station's drawn width (world px), for Main's station table.
const PURGE_HALF_WIDTH: float = PURGE_SIZE.x * PURGE_SCALE * 0.5
const MIRROR_HALF_WIDTH: float = MIRROR_SIZE.x * MIRROR_SCALE * 0.5
## The screens' glass and the status lights, in piece px (measured on the pieces): the purge light is
## the slot in the bar under its screen, the mirror's the indicator window between its two drive bays.
const PURGE_SCREEN: Rect2 = Rect2(86.0, 28.0, 160.0, 96.0)
const PURGE_LIGHT: Rect2 = Rect2(119.0, 133.0, 61.0, 7.0)
const MIRROR_SCREEN: Rect2 = Rect2(125.0, 12.0, 109.0, 64.0)
const MIRROR_LIGHT: Rect2 = Rect2(172.0, 183.0, 7.0, 19.0)
## The purge order's red and the mirror's cyan: each station's screen and status light until its trace
## is copied, then both go green (the corridor's purge display shows the same order in PURGE_RED).
const PURGE_RED: Color = Color("#d86b70")
const MIRROR_CYAN: Color = Color("#73b9d2")
## The two station names' row (their top edge): just over the taller station, the MIRROR PORT (its top
## at y 360), so each name reads as its machine's now that both stand at their real size.
const STATION_LABEL_Y: float = 340.0
## The lights each leaf sees, as they light the wall and reveal round it (rdesign.py), in the leaf's own
## exposure: [position (m), colour * intensity, reach (m), down exponent, wrap, fill]. Fix round 4 (review r4,
## M1): the door light is the design's own again (reach 1.4 m, down 2.0) as a true Lambert source, so the
## open leaf by its hinge follows the painted reveal it hangs on all the way down, not only at the head; and
## the leaf sees the lit surfaces round it: the threshold and passage deck through the doorway (they light
## the open leaf's outside face and the reveal, never the room face) and the cross-wall's lit face beyond the
## hinge jamb (the room face turns toward it as the leaf opens, so the leaf never goes black mid-swing).
## Gains fitted with 1cf8d73:docs/research-2026-10/sources/doors-2026-10-14/fix-r4/tools/{leafsim,lp3,l1,refine,dipfix}.py and closed on render.sh frames
## (swingcheck.py): open, the leaf by the hinge at 0.7-0.9x the reveal in each row band; shut, below its
## wall; through the swing, never far below shut and well above half the wall.
const EXIT_LEAF_LIGHTS: Array = [
	[Vector3(21.9043, 2.8000, -0.0291), Vector3(1.1409, 1.2605, 1.3268), 1.40, 2.0, 0.00],  # the door light over the head (the design's: reach 1.4 m, down 2.0; true Lambert)
	[Vector3(15.0056, 5.5765, 4.3000), Vector3(0.0531, 0.0686, 0.0738), 3.20, 1.5, 0.06],  # the room's ceiling lamp
	[Vector3(20.0000, 0.1000, -3.0000), Vector3(0.1650, 0.2250, 0.2550), 5.00, 0.0, 0.06, true],  # the broad floor bounce (fill)
	[Vector3(22.2746, 0.0300, 0.0868), Vector3(0.1890, 0.2088, 0.2198), 0.90, 0.0, 0.05],  # the lit threshold and passage deck seen through the doorway
	[Vector3(21.7043, 1.4000, 0.8612), Vector3(0.7360, 0.8131, 0.8559), 1.00, 0.0, 0.05],  # the cross-wall's own lit face beyond the hinge jamb
]
const ENTRY_LEAF_LIGHTS: Array = [
	[Vector3(1.8457, 2.8000, -0.0291), Vector3(1.2242, 1.3524, 1.4231), 1.40, 2.0, 0.00],  # the door light over the head (the design's: reach 1.4 m, down 2.0; true Lambert)
	[Vector3(3.6013, 5.5765, 4.3000), Vector3(0.9362, 1.2093, 1.3003), 3.20, 1.5, 0.06],  # the room's ceiling lamp
	[Vector3(3.7500, 0.1000, -3.0000), Vector3(0.1650, 0.2250, 0.2550), 5.00, 0.0, 0.06, true],  # the broad floor bounce (fill)
	[Vector3(1.4754, 0.0300, 0.0868), Vector3(0.6889, 0.7610, 0.8008), 0.90, 0.0, 0.05],  # the lit threshold and passage deck seen through the doorway
	[Vector3(2.0457, 1.4000, 0.8612), Vector3(0.2724, 0.3010, 0.3167), 1.00, 0.0, 0.05],  # the cross-wall's own lit face beyond the hinge jamb
]
## The MIRROR PORT name until its trace is preserved.
const MIRROR_TEXT: Color = Color("#b6edff")
## Ceiling lamps and lockdown beacons as fractions of the far plate, measured from the plate.
var lamps: PackedVector2Array = PackedVector2Array([Vector2(0.199, 0.263), Vector2(0.6, 0.263), Vector2(0.869, 0.263)])
var warning_lamps: PackedVector2Array = PackedVector2Array([Vector2(0.304, 0.31), Vector2(0.698, 0.31)])

# The parent owns chapter state and calls queue_redraw() after changing it.
var purge_trace_preserved: bool = false
var mirror_trace_preserved: bool = false
var chapter_complete: bool = false
var purge_label: Label
var mirror_label: Label
## Every station name; each fades out as it reaches the edge of the view, like the junction's.
var station_labels: Array[Label] = []
var depth: RoomDepth
var purge_glow: Sprite2D
var mirror_glow: Sprite2D
var purge_art: Sprite2D
var mirror_art: Sprite2D
var purge_screen: PropScreen
var mirror_screen: PropScreen
## The security container's sprite (drawn behind the walk line with the door walls, before the leaves).
var container_art: Sprite2D
var floor_reflections: Array[FloorReflection] = []
var exit_leaf: SwingLeaf
var entry_leaf: SwingLeaf
## The entry's near end (over the mid plate, under the actors) and the exit's (over the actors).
var entry_front: Sprite2D
var exit_front: Sprite2D
## The status lamps' live glass and the exit reader's LED.
var exit_lamp: DoorKit.Lamp
var entry_lamp: DoorKit.Lamp
var exit_reader: DoorKit.Lamp
## The shut leaves stop whoever walks into them: the exit until the first copy is secured, the entry
## always (the corridor side is behind the engineer).
var exit_door_shape: CollisionShape2D
var entry_door_shape: CollisionShape2D
var exit_tween: Tween
var entry_tween: Tween


func _ready() -> void:
	depth = RoomDepth.new()
	depth.name = "Depth"
	depth.painting = RECORDS_FAR
	depth.mid_painting = RECORDS_MID
	depth.near_painting = RECORDS_NEAR
	depth.base_color = Color("#071221")
	depth.lamps = lamps
	depth.shaft_lamps = PackedInt32Array([1, 2])
	depth.warning_lamps = warning_lamps
	# Both ends of the room are walls with doors now, as the corridor's right end opens into its
	# machinery room: no foreground pipe column is drawn over either.
	depth.near_left_edge = false
	depth.near_right_edge = false
	add_child(depth)
	purge_art = RoomDepth.make_prop("PurgeArt", PURGE_QUEUE, PURGE_SCALE, PURGE_X)
	mirror_art = RoomDepth.make_prop("MirrorArt", MIRROR_PORT, MIRROR_SCALE, MIRROR_X)
	for prop: Sprite2D in [purge_art, mirror_art]:
		# One step under this node's own drawing, so the status lights drawn in _draw() sit on the art.
		prop.z_index = -1
		add_child(prop)
		floor_reflections.append(FloorReflection.attach(prop))
	purge_screen = PropScreen.attach(purge_art, "PurgeScreen", PURGE_SCREEN, PURGE_RED)
	mirror_screen = PropScreen.attach(mirror_art, "MirrorScreen", MIRROR_SCREEN, MIRROR_CYAN)
	# Behind the mid plate: each doorway's next space, light and cross-wall face (DoorKit.doorway).
	DoorKit.doorway(depth.behind, "Entry", ENTRY_HOLE, ENTRY_HOLE_LIGHT, ENTRY_BACK, ENTRY_BACK_AT, DoorKit.BEYOND_LIFT, null, ENTRY_POOL, ENTRY_GRAZE, ENTRY_WALL, ENTRY_WALL_AT)
	DoorKit.doorway(depth.behind, "Exit", EXIT_HOLE, EXIT_HOLE_LIGHT, EXIT_BACK, EXIT_BACK_AT, DoorKit.BEYOND_LIFT, null, EXIT_POOL, EXIT_GRAZE, EXIT_WALL, EXIT_WALL_AT)
	DoorKit.shade(depth.behind, "ExitPastEnd", EXIT_PAST_END, DoorKit.PAST_END_SHADE)
	# Over the mid plate, under the actors: the leaves on their hinges (SwingLeaf, lit per vertex), each
	# with its surface closer's arm on the room side, the entry's near end with its lamp (nobody passes
	# behind it), the door lights and the exit's sign. The security container stands in front of the
	# exit's wall, its own sprite right after these at the same depth (the open exit leaf stops well
	# clear of it). Contact shadows and light are painted: nothing here casts a runtime reflection.
	var over: Node2D = Node2D.new()
	over.name = "DoorsOver"
	over.z_as_relative = false
	over.z_index = RoomDepth.Z_MID
	depth.add_child(over)
	exit_leaf = SwingLeaf.make("ExitLeaf", EXIT_HINGE, EXIT_AXIS_U, EXIT_AXIS_N, EXIT_LEAF_LIGHTS, EXIT_LEAF_FILL)
	entry_leaf = SwingLeaf.make("EntryLeaf", ENTRY_HINGE, ENTRY_AXIS_U, ENTRY_AXIS_N, ENTRY_LEAF_LIGHTS, ENTRY_LEAF_FILL)
	over.add_child(exit_leaf)
	over.add_child(entry_leaf)
	entry_front = DoorKit.piece(over, ENTRY_FRONT, ENTRY_FRONT_AT, "EntryFront")
	entry_lamp = DoorKit.lamp(over, "EntryLamp", ENTRY_LAMP, Palette.LAMP_SHUT)
	DoorKit.door_light(over, ENTRY_DOOR_LIGHT)
	DoorKit.door_light(over, EXIT_DOOR_LIGHT)
	DoorKit.exit_sign(over, EXIT_SIGN, 1.0)
	container_art = RoomDepth.make_prop("ContainerArt", CONTAINER, CONTAINER_SCALE, CONTAINER_X, CONTAINER_BASE_Y)
	# On the doors' own absolute layer, so it sorts against the actors the same way.
	container_art.z_index = RoomDepth.Z_MID
	container_art.z_as_relative = false
	depth.add_child(container_art)
	# The exit's near end, lamp and reader draw over the actors (they walk out behind them), always opaque.
	exit_front = DoorKit.piece(self, EXIT_FRONT, EXIT_FRONT_AT, "ExitFront")
	exit_front.z_index = RoomDepth.Z_NEAR
	exit_front.z_as_relative = false
	exit_lamp = DoorKit.lamp(self, "ExitLamp", EXIT_LAMP, Palette.LAMP_SHUT)
	exit_reader = DoorKit.lamp(self, "ExitReader", EXIT_READER, Palette.LAMP_SHUT, DoorKit.READER_LED_RADIUS)
	for front: Node2D in [exit_lamp, exit_reader]:
		front.z_index = RoomDepth.Z_NEAR
		front.z_as_relative = false
	# Each shut leaf stops whoever walks into it at its room face; refresh_state() enables the bodies.
	exit_door_shape = SwingLeaf.make_body(self, "ExitDoor", EXIT_DOOR_X, 1.0)
	entry_door_shape = SwingLeaf.make_body(self, "EntryDoor", ENTRY_DOOR_X, -1.0)
	purge_glow = _add_glow("PurgeGlow", RoomDepth.prop_rect(purge_art, PURGE_LIGHT).get_center())
	mirror_glow = _add_glow("MirrorGlow", RoomDepth.prop_rect(mirror_art, MIRROR_LIGHT).get_center())
	purge_label = _add_station_label("PURGE QUEUE", PURGE_X, Palette.LABEL_ALERT, STATION_LABEL_Y)
	mirror_label = _add_station_label("MIRROR PORT", MIRROR_X, MIRROR_TEXT, STATION_LABEL_Y)
	# The exit's name sits on the cross-wall over its door, left of the near column (which draws over
	# the actors and would cut it; captions stay under the actors).
	_add_station_label("EXIT", EXIT_LABEL_X, Palette.EXIT_GREEN, EXIT_LABEL_Y)
	refresh_state()


## The exit's status lamp: red shut, amber while its leaf moves, green open; the badge reader's LED
## goes green with it once the copy releases the door, and is red otherwise.
func set_exit_lamp(color: Color) -> void:
	exit_lamp.color = color
	exit_reader.color = Palette.LAMP_SHUT if color == Palette.LAMP_SHUT else Palette.LAMP_OPEN


## The exit lamp's current colour: what set_exit_lamp last set (chapter_scene_test reads it).
func exit_lamp_color() -> Color:
	return exit_lamp.color


## The entry's status lamp: amber while its closer brings the leaf shut, red once it latches.
func set_entry_lamp(color: Color) -> void:
	entry_lamp.color = color


## The entry lamp's current colour: what set_entry_lamp last set.
func entry_lamp_color() -> Color:
	return entry_lamp.color


## Where the security container's art is drawn (in this room, which sits at the world origin).
func container_rect() -> Rect2:
	return RoomDepth.prop_bounds(container_art)


## An additive glow over a drawn machine light; refresh_state() tints it with the light's colour. It
## sits at this node's own depth, under the actors, so someone at the machine is drawn in front of it.
func _add_glow(glow_name: String, at: Vector2) -> Sprite2D:
	var glow: Sprite2D = RoomDepth.make_glow(Color.WHITE, Vector2(72.0, 32.0), 0.6)
	glow.name = glow_name
	glow.position = at
	glow.z_index = 0
	add_child(glow)
	return glow


## A station name centred on [param center_x], sized to its text so it fades by the text itself.
func _add_station_label(caption: String, center_x: float, tint: Color, label_y: float = 309.0) -> Label:
	var label: Label = Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	TextSize.size_label(label, 13)
	label.add_theme_color_override("font_color", tint)
	label.set_meta(&"center", Vector2(center_x, label_y))
	add_child(label)
	station_labels.append(label)
	_fit_label(label)
	return label


## Shrinks [param label] to its text and centres it on its station again (TEXT SIZE grows it upward).
func _fit_label(label: Label) -> void:
	var center: Vector2 = label.get_meta(&"center")
	TextSize.fit_world_label(label, center.x, center.y)


## TEXT SIZE or the language changed, or a name's words did: every name takes its size and words,
## and neighbours that would cover each other part (TextSize.part_world_labels, PR L8).
func refit_labels() -> void:
	for label: Label in station_labels:
		_fit_label(label)
	TextSize.part_world_labels(station_labels)


## A name the edge of the view would cut fades out instead (JunctionRoom.fade_at_view_edge).
func _process(_delta: float) -> void:
	if visible:
		JunctionRoom.fade_at_view_edge(station_labels, get_viewport())


## Only the room on screen keeps its floor reflections mirroring; hidden, its sparks stop emitting.
func set_active(active: bool) -> void:
	FloorReflection.set_all_active(floor_reflections, active)
	if active:
		return
	for child: Node in get_children():
		if child is CPUParticles2D:
			(child as CPUParticles2D).emitting = false


## Shows the room's state: the station labels and lights, and the doors at rest (the exit shut until
## the first copy is secured, then open on its floor stop; the entry shut). A door already swinging
## finishes its swing.
func refresh_state() -> void:
	purge_label.text = "PURGE COPIED" if purge_trace_preserved else "PURGE QUEUE"
	purge_label.add_theme_color_override("font_color", Palette.GREEN if purge_trace_preserved else Palette.LABEL_ALERT)
	mirror_label.text = "MIRROR COPIED" if mirror_trace_preserved else "MIRROR PORT"
	mirror_label.add_theme_color_override("font_color", Palette.GREEN if mirror_trace_preserved else MIRROR_TEXT)
	purge_glow.modulate = Color(_purge_light_color(), 0.6)
	mirror_glow.modulate = Color(_mirror_light_color(), 0.6)
	purge_screen.tint = _purge_light_color()
	mirror_screen.tint = _mirror_light_color()
	refit_labels()
	if exit_tween == null or not exit_tween.is_running():
		exit_leaf.open = 1.0 if chapter_complete else 0.0
		set_exit_lamp(Palette.LAMP_OPEN if chapter_complete else Palette.LAMP_SHUT)
	if entry_tween == null or not entry_tween.is_running():
		entry_leaf.open = 0.0
		set_entry_lamp(Palette.LAMP_SHUT)
	# The exit stops the actors only while it is shut, and only while Records is the room in play.
	exit_door_shape.set_deferred("disabled", not visible or chapter_complete)
	entry_door_shape.set_deferred("disabled", not visible)
	queue_redraw()


## The secured copy releases the exit: the lamp turns amber, the operator swings the leaf into the room
## onto its floor stop, and the lamp turns green. Without [param animate] it is simply open.
func open_exit(animate: bool) -> void:
	Tweens.kill(exit_tween)
	exit_door_shape.set_deferred("disabled", true)
	if not animate:
		exit_leaf.open = 1.0
		set_exit_lamp(Palette.LAMP_OPEN)
		return
	set_exit_lamp(Palette.AMBER)
	exit_tween = create_tween()
	exit_tween.tween_property(exit_leaf, "open", 1.0, EXIT_SWING_SECONDS).from(0.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	exit_tween.tween_callback(func() -> void: set_exit_lamp(Palette.LAMP_OPEN))


## True while the exit's operator is swinging its leaf open.
func exit_swinging() -> bool:
	return exit_tween != null and exit_tween.is_running()


## Entering from the corridor side: the entry stands open behind the engineer and its closer brings
## it shut, amber while it moves, red once it latches.
func close_entry_behind() -> void:
	set_entry_lamp(Palette.AMBER)
	entry_tween = entry_leaf.close_behind(self, entry_tween, func() -> void: set_entry_lamp(Palette.LAMP_SHUT))


func _draw() -> void:
	# The records plates are the Depth child's layers; the doors are their own nodes.
	_draw_machine_lights()


func _draw_machine_lights() -> void:
	draw_rect(RoomDepth.prop_rect(purge_art, PURGE_LIGHT), _purge_light_color())
	draw_rect(RoomDepth.prop_rect(mirror_art, MIRROR_LIGHT), _mirror_light_color())


func _purge_light_color() -> Color:
	return Palette.GREEN if purge_trace_preserved else PURGE_RED


func _mirror_light_color() -> Color:
	return Palette.GREEN if mirror_trace_preserved else MIRROR_CYAN
