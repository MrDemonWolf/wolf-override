extends Node2D
class_name RecordsRoom

const RECORDS_BACKGROUND: Texture2D = preload("res://assets/records-access-background-provisional.png")
const RECORDS_PROPS: Texture2D = preload("res://assets/records-props-provisional.png")

# The parent owns chapter state and calls queue_redraw() after changing it.
var purge_trace_preserved: bool = false
var mirror_trace_preserved: bool = false
var chapter_complete: bool = false
var exit_art: Sprite2D


func _ready() -> void:
	_add_prop("PurgeArt", 190.0, 0.0)
	_add_prop("MirrorArt", 520.0, 724.0)
	exit_art = _add_prop("ExitArt", 830.0, 1448.0)
	_add_station_label("PURGE QUEUE", 190.0, Color("#ffc7c7"))
	_add_station_label("MIRROR PORT", 520.0, Color("#b6edff"))
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


func _add_station_label(caption: String, center_x: float, tint: Color, label_y: float = 309.0) -> void:
	var label: Label = Label.new()
	label.text = caption
	label.position = Vector2(center_x - 90.0, label_y)
	label.size = Vector2(180.0, 30.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", tint)
	add_child(label)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("#071221"))
	draw_texture_rect(RECORDS_BACKGROUND, Rect2(0, 88, 960, 540), false)
	draw_line(Vector2(40, 440), Vector2(920, 440), Color("#405b6d"), 2.0)

	_draw_exit()
	_draw_progress()


func _draw_exit() -> void:
	if chapter_complete:
		draw_rect(Rect2(798, 300, 64, 138), Color("#081b2b"))
		draw_rect(Rect2(790, 296, 80, 144), Color("#4a6572"), false, 3.0)
		draw_line(Vector2(810, 433), Vector2(851, 433), Color("#a4f0c4"), 4.0)


func _draw_progress() -> void:
	draw_rect(Rect2(349, 139, 262, 11), Color("#0b1c2c"))
	draw_rect(Rect2(354, 143, 123 if purge_trace_preserved else 24, 4), Color("#a4f0c4") if purge_trace_preserved else Color("#965363"))
	draw_rect(Rect2(483, 143, 123 if mirror_trace_preserved else 24, 4), Color("#a4f0c4") if mirror_trace_preserved else Color("#42677b"))
	draw_circle(Vector2(613, 145), 5.0, Color("#a4f0c4") if chapter_complete else Color("#d86b70"))
