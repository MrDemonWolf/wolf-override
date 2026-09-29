extends Node2D
class_name RecordsRoom

const RECORDS_BACKGROUND: Texture2D = preload("res://assets/records-access-background-provisional.png")
const RECORDS_PROPS: Texture2D = preload("res://assets/records-props-provisional.png")

# The parent owns chapter state and calls queue_redraw() after changing it.
var purge_trace_preserved: bool = false
var mirror_trace_preserved: bool = false
var chapter_complete: bool = false
var exit_art: Sprite2D
var purge_label: Label
var mirror_label: Label


func _ready() -> void:
	_add_prop("PurgeArt", 190.0, 0.0)
	_add_prop("MirrorArt", 520.0, 724.0)
	exit_art = _add_prop("ExitArt", 830.0, 1448.0)
	purge_label = _add_station_label("PURGE QUEUE", 190.0, Color("#ffc7c7"))
	mirror_label = _add_station_label("MIRROR PORT", 520.0, Color("#b6edff"))
	_add_station_label("EXIT", 830.0, Color("#c1f4d8"), 276.0)


func _add_prop(prop_name: String, center_x: float, source_x: float) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = prop_name
	sprite.texture = RECORDS_PROPS
	sprite.region_enabled = true
	sprite.region_rect = Rect2(source_x, 0.0, 724.0, 724.0)
	sprite.position = Vector2(center_x, 375.0)
	sprite.scale = Vector2(0.22, 0.22)
	add_child(sprite)
	return sprite


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
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("#071221"))
	draw_texture_rect(RECORDS_BACKGROUND, Rect2(0, 0, 960, 680), false)

	_draw_exit()
	_draw_machine_lights()


func _draw_exit() -> void:
	if chapter_complete:
		draw_rect(Rect2(798, 300, 64, 138), Color("#081b2b"))
		draw_rect(Rect2(790, 296, 80, 144), Color("#4a6572"), false, 3.0)
		draw_line(Vector2(810, 433), Vector2(851, 433), Color("#a4f0c4"), 4.0)


func _draw_machine_lights() -> void:
	draw_rect(Rect2(177, 360, 26, 5), Color("#a4f0c4") if purge_trace_preserved else Color("#d86b70"))
	draw_rect(Rect2(507, 360, 26, 5), Color("#a4f0c4") if mirror_trace_preserved else Color("#73b9d2"))
