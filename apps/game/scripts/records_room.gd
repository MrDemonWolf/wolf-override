extends Node2D
class_name RecordsRoom

const RECORDS_FAR: Texture2D = preload("res://assets/rooms/records-far.png")
const RECORDS_MID: Texture2D = preload("res://assets/rooms/records-mid.png")
const RECORDS_NEAR: Texture2D = preload("res://assets/rooms/records-near.png")
const PURGE_QUEUE: Texture2D = preload("res://assets/props/records-purge-queue.png")
const MIRROR_PORT: Texture2D = preload("res://assets/props/records-mirror-port.png")
const EXIT_HATCH: Texture2D = preload("res://assets/props/records-exit-hatch.png")
## The source row where the mid plate's walkway (its pillar and machine bases) meets the floor.
const WALKWAY_Y: float = 742.0
## Each prop is cut to its painted outline and scaled to the height of the art it replaced
## (purge 111, mirror 111, exit 139 px); its base sits on the floor.
const PURGE_REGION: Rect2 = Rect2(51.0, 54.0, 417.0, 409.0)
const PURGE_SCALE: float = 0.274
const MIRROR_REGION: Rect2 = Rect2(69.0, 31.0, 373.0, 468.0)
const MIRROR_SCALE: float = 0.239
const EXIT_REGION: Rect2 = Rect2(126.0, 21.0, 260.0, 481.0)
const EXIT_SCALE: float = 0.291
## Where the exit hatch stands until the chapter close lifts it away.
const EXIT_REST: Vector2 = Vector2(830.0, RoomDepth.FLOOR_Y - 481.0 * 0.291 * 0.5)
## The status lights sit on the bar under the purge screen and under the mirror's screen.
const PURGE_LIGHT: Rect2 = Rect2(163.0, 360.5, 16.0, 4.0)
const MIRROR_LIGHT: Rect2 = Rect2(511.0, 348.0, 20.0, 4.0)
## Ceiling lamps and lockdown beacons as fractions of the far plate, measured from the plate.
var lamps: PackedVector2Array = PackedVector2Array([Vector2(0.199, 0.263), Vector2(0.6, 0.263), Vector2(0.869, 0.263)])
var warning_lamps: PackedVector2Array = PackedVector2Array([Vector2(0.304, 0.31), Vector2(0.698, 0.31)])

# The parent owns chapter state and calls queue_redraw() after changing it.
var purge_trace_preserved: bool = false
var mirror_trace_preserved: bool = false
var chapter_complete: bool = false
var exit_art: Sprite2D
var purge_label: Label
var mirror_label: Label
var depth: RoomDepth
var purge_glow: Sprite2D
var mirror_glow: Sprite2D
var floor_reflections: Array[FloorReflection] = []


func _ready() -> void:
	depth = RoomDepth.new()
	depth.name = "Depth"
	depth.painting = RECORDS_FAR
	depth.mid_painting = RECORDS_MID
	depth.near_painting = RECORDS_NEAR
	depth.walkway_y = WALKWAY_Y
	depth.base_color = Color("#071221")
	depth.lamps = lamps
	depth.shaft_lamps = PackedInt32Array([1, 2])
	depth.warning_lamps = warning_lamps
	add_child(depth)
	var purge_art: Sprite2D = RoomDepth.make_prop("PurgeArt", PURGE_QUEUE, PURGE_REGION, PURGE_SCALE, 190.0)
	var mirror_art: Sprite2D = RoomDepth.make_prop("MirrorArt", MIRROR_PORT, MIRROR_REGION, MIRROR_SCALE, 520.0)
	exit_art = RoomDepth.make_prop("ExitArt", EXIT_HATCH, EXIT_REGION, EXIT_SCALE, EXIT_REST.x)
	for prop: Sprite2D in [purge_art, mirror_art]:
		# One step under this node's own drawing, so the status lights drawn in _draw() sit on the art.
		prop.z_index = -1
	# The exit hatch stays at this node's depth, over the open doorway _draw_exit() paints once the
	# chapter is complete, so the hatch can be seen lifting away during the close.
	for prop: Sprite2D in [purge_art, mirror_art, exit_art]:
		add_child(prop)
		floor_reflections.append(FloorReflection.attach(prop))
	purge_glow = _add_glow("PurgeGlow", PURGE_LIGHT.get_center())
	mirror_glow = _add_glow("MirrorGlow", MIRROR_LIGHT.get_center())
	purge_label = _add_station_label("PURGE QUEUE", 190.0, Color("#ffc7c7"))
	mirror_label = _add_station_label("MIRROR PORT", 520.0, Color("#b6edff"))
	_add_station_label("EXIT", 830.0, Color("#c1f4d8"), 276.0)
	refresh_state()


## An additive glow over a drawn machine light; refresh_state() tints it with the light's colour.
func _add_glow(glow_name: String, at: Vector2) -> Sprite2D:
	var glow: Sprite2D = RoomDepth.make_glow(Color.WHITE, Vector2(72.0, 32.0), 0.6)
	glow.name = glow_name
	glow.position = at
	glow.z_index = 1
	add_child(glow)
	return glow


func _add_station_label(caption: String, center_x: float, tint: Color, label_y: float = 309.0) -> Label:
	var label: Label = Label.new()
	label.text = caption
	label.position = Vector2(center_x - 90.0, label_y)
	label.size = Vector2(180.0, 30.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", tint)
	add_child(label)
	return label


func refresh_state() -> void:
	purge_label.text = "PURGE COPIED" if purge_trace_preserved else "PURGE QUEUE"
	purge_label.add_theme_color_override("font_color", Color("#a4f0c4") if purge_trace_preserved else Color("#ffc7c7"))
	mirror_label.text = "MIRROR COPIED" if mirror_trace_preserved else "MIRROR PORT"
	mirror_label.add_theme_color_override("font_color", Color("#a4f0c4") if mirror_trace_preserved else Color("#b6edff"))
	purge_glow.modulate = Color(_purge_light_color(), 0.6)
	mirror_glow.modulate = Color(_mirror_light_color(), 0.6)
	queue_redraw()


func _draw() -> void:
	# The records plates are the Depth child's layers.
	_draw_exit()
	_draw_machine_lights()


func _draw_exit() -> void:
	if chapter_complete:
		draw_rect(Rect2(798, 300, 64, 138), Color("#081b2b"))
		draw_rect(Rect2(790, 296, 80, 144), Color("#4a6572"), false, 3.0)
		draw_line(Vector2(810, 433), Vector2(851, 433), Color("#a4f0c4"), 4.0)


func _draw_machine_lights() -> void:
	draw_rect(PURGE_LIGHT, _purge_light_color())
	draw_rect(MIRROR_LIGHT, _mirror_light_color())


func _purge_light_color() -> Color:
	return Color("#a4f0c4") if purge_trace_preserved else Color("#d86b70")


func _mirror_light_color() -> Color:
	return Color("#a4f0c4") if mirror_trace_preserved else Color("#73b9d2")
