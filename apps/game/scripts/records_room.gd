extends Node2D
class_name RecordsRoom

const RECORDS_BACKGROUND: Texture2D = preload("res://assets/records-access-background-provisional.png")
const RECORDS_PROPS: Texture2D = preload("res://assets/records-props-provisional.png")
## Ceiling lamps and lockdown lamps as fractions of the painting, measured from the plate.
var lamps: PackedVector2Array = PackedVector2Array([Vector2(0.203, 0.251), Vector2(0.604, 0.251), Vector2(0.87, 0.251)])
var warning_lamps: PackedVector2Array = PackedVector2Array([Vector2(0.033, 0.32), Vector2(0.79, 0.34)])

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
	depth.painting = RECORDS_BACKGROUND
	depth.base_color = Color("#071221")
	depth.lamps = lamps
	depth.shaft_lamps = PackedInt32Array([1, 2])
	depth.warning_lamps = warning_lamps
	add_child(depth)
	var purge_art: Sprite2D = _add_prop("PurgeArt", 190.0, 0.0)
	var mirror_art: Sprite2D = _add_prop("MirrorArt", 520.0, 724.0)
	exit_art = _add_prop("ExitArt", 830.0, 1448.0)
	for prop: Sprite2D in [purge_art, mirror_art, exit_art]:
		floor_reflections.append(FloorReflection.attach(prop))
	purge_glow = _add_glow("PurgeGlow", 190.0)
	mirror_glow = _add_glow("MirrorGlow", 520.0)
	purge_label = _add_station_label("PURGE QUEUE", 190.0, Color("#ffc7c7"))
	mirror_label = _add_station_label("MIRROR PORT", 520.0, Color("#b6edff"))
	_add_station_label("EXIT", 830.0, Color("#c1f4d8"), 276.0)
	refresh_state()


func _add_prop(prop_name: String, center_x: float, source_x: float) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = prop_name
	sprite.texture = RECORDS_PROPS
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.region_enabled = true
	sprite.region_rect = Rect2(source_x, 0.0, 724.0, 724.0)
	sprite.position = Vector2(center_x, 375.0)
	sprite.scale = Vector2(0.22, 0.22)
	add_child(sprite)
	return sprite


## An additive glow over a drawn machine light; refresh_state() tints it with the light's colour.
func _add_glow(glow_name: String, center_x: float) -> Sprite2D:
	var glow: Sprite2D = RoomDepth.make_glow(Color.WHITE, Vector2(72.0, 32.0), 0.6)
	glow.name = glow_name
	glow.position = Vector2(center_x, 362.5)
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
	# The records painting itself is the Depth child's parallax backdrop.
	_draw_exit()
	_draw_machine_lights()


func _draw_exit() -> void:
	if chapter_complete:
		draw_rect(Rect2(798, 300, 64, 138), Color("#081b2b"))
		draw_rect(Rect2(790, 296, 80, 144), Color("#4a6572"), false, 3.0)
		draw_line(Vector2(810, 433), Vector2(851, 433), Color("#a4f0c4"), 4.0)


func _draw_machine_lights() -> void:
	draw_rect(Rect2(177, 360, 26, 5), _purge_light_color())
	draw_rect(Rect2(507, 360, 26, 5), _mirror_light_color())


func _purge_light_color() -> Color:
	return Color("#a4f0c4") if purge_trace_preserved else Color("#d86b70")


func _mirror_light_color() -> Color:
	return Color("#a4f0c4") if mirror_trace_preserved else Color("#73b9d2")
