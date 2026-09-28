extends Node2D
class_name RecordsRoom

# The parent owns chapter state and calls queue_redraw() after changing it.
var purge_trace_preserved: bool = false
var mirror_trace_preserved: bool = false
var chapter_complete: bool = false


func _ready() -> void:
	_add_station_label("PURGE QUEUE", 190.0, Color("#ffc7c7"))
	_add_station_label("MIRROR PORT", 520.0, Color("#b6edff"))
	_add_station_label("EXIT", 830.0, Color("#c1f4d8"))


func _add_station_label(caption: String, center_x: float, tint: Color) -> void:
	var label: Label = Label.new()
	label.text = caption
	label.position = Vector2(center_x - 90.0, 309.0)
	label.size = Vector2(180.0, 30.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", tint)
	add_child(label)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("#071221"))
	draw_rect(Rect2(34, 101, 892, 337), Color("#112438"))
	draw_rect(Rect2(42, 109, 876, 228), Color("#172d42"))
	draw_rect(Rect2(42, 109, 876, 16), Color("#354657"))
	draw_line(Vector2(42, 156), Vector2(918, 156), Color("#496175"), 3.0)
	draw_line(Vector2(42, 294), Vector2(918, 294), Color("#365063"), 2.0)

	# Archive racks make this bay read differently from the maintenance corridor.
	for rack_x in [55, 302, 632]:
		draw_rect(Rect2(rack_x, 165, 225, 124), Color("#0b1b2d"))
		draw_rect(Rect2(rack_x, 165, 225, 124), Color("#3d5667"), false, 2.0)
		for slot in range(4):
			var slot_y: float = 176.0 + float(slot) * 28.0
			draw_rect(Rect2(rack_x + 11, slot_y, 202, 19), Color("#193046"))
			draw_line(Vector2(rack_x + 18, slot_y + 9), Vector2(rack_x + 119, slot_y + 9), Color("#466277"), 2.0)
			draw_circle(Vector2(rack_x + 197, slot_y + 9), 3.0, Color("#79b8c9"))

	# Emergency lamps cast separate red and cold-blue pools over the stations.
	for lamp_x in [190.0, 520.0, 830.0]:
		var lamp_color: Color = Color(0.98, 0.33, 0.36, 0.13) if lamp_x != 520.0 else Color(0.35, 0.78, 0.98, 0.10)
		draw_colored_polygon(PackedVector2Array([Vector2(lamp_x - 19.0, 134.0), Vector2(lamp_x + 19.0, 134.0), Vector2(lamp_x + 91.0, 438.0), Vector2(lamp_x - 91.0, 438.0)]), lamp_color)
		draw_rect(Rect2(lamp_x - 23.0, 129.0, 46.0, 8.0), Color("#e5696a") if lamp_x != 520.0 else Color("#79d7f4"))

	draw_rect(Rect2(40, 438, 880, 11), Color("#405b6d"))
	draw_rect(Rect2(40, 397, 880, 41), Color("#172b3e"))
	for floor_x in range(50, 920, 46):
		draw_line(Vector2(floor_x, 399), Vector2(floor_x - 10, 437), Color("#314d61"), 1.0)
	draw_line(Vector2(42, 391), Vector2(918, 391), Color("#d16466"), 2.0)

	_draw_queue()
	_draw_mirror()
	_draw_exit()
	_draw_progress()


func _draw_queue() -> void:
	draw_rect(Rect2(132, 340, 116, 98), Color("#081827"))
	draw_rect(Rect2(139, 347, 102, 91), Color("#523747"))
	draw_rect(Rect2(147, 355, 86, 56), Color("#10273a"))
	for row in range(3):
		draw_rect(Rect2(155, 364 + row * 12, 58 - row * 8, 4), Color("#aa7a82"))
	draw_circle(Vector2(220, 398), 5.0, Color("#a4f0c4") if purge_trace_preserved else Color("#f08b8d"))
	draw_rect(Rect2(154, 418, 72, 5), Color("#a4f0c4") if purge_trace_preserved else Color("#725164"))
	if purge_trace_preserved:
		draw_line(Vector2(207, 399), Vector2(215, 407), Color("#a4f0c4"), 3.0)
		draw_line(Vector2(215, 407), Vector2(231, 387), Color("#a4f0c4"), 3.0)


func _draw_mirror() -> void:
	draw_rect(Rect2(459, 340, 122, 98), Color("#081827"))
	draw_rect(Rect2(466, 347, 108, 91), Color("#315b70"))
	draw_rect(Rect2(475, 357, 90, 55), Color("#10283b"))
	for column in range(2):
		draw_rect(Rect2(486 + column * 38, 365, 27, 37), Color("#376078"))
		draw_rect(Rect2(490 + column * 38, 369, 19, 29), Color("#85c9df") if mirror_trace_preserved else Color("#416c80"))
	draw_circle(Vector2(520, 422), 5.0, Color("#a4f0c4") if mirror_trace_preserved else Color("#77a2b5"))
	if mirror_trace_preserved:
		draw_line(Vector2(505, 418), Vector2(514, 427), Color("#a4f0c4"), 3.0)
		draw_line(Vector2(514, 427), Vector2(532, 407), Color("#a4f0c4"), 3.0)


func _draw_exit() -> void:
	draw_rect(Rect2(785, 255, 90, 183), Color("#071623"))
	draw_rect(Rect2(790, 260, 80, 178), Color("#4a6572"), false, 4.0)
	draw_rect(Rect2(798, 271, 64, 167), Color("#081b2b") if chapter_complete else Color("#263e50"))
	if not chapter_complete:
		draw_line(Vector2(830, 271), Vector2(830, 438), Color("#547186"), 3.0)
		draw_rect(Rect2(809, 356, 42, 8), Color("#d86b70"))
	else:
		draw_line(Vector2(810, 433), Vector2(851, 433), Color("#a4f0c4"), 4.0)
	draw_rect(Rect2(802, 264, 56, 5), Color("#a4f0c4") if chapter_complete else Color("#d86b70"))


func _draw_progress() -> void:
	draw_rect(Rect2(349, 139, 262, 11), Color("#0b1c2c"))
	draw_rect(Rect2(354, 143, 123 if purge_trace_preserved else 24, 4), Color("#a4f0c4") if purge_trace_preserved else Color("#965363"))
	draw_rect(Rect2(483, 143, 123 if mirror_trace_preserved else 24, 4), Color("#a4f0c4") if mirror_trace_preserved else Color("#42677b"))
	draw_circle(Vector2(613, 145), 5.0, Color("#a4f0c4") if chapter_complete else Color("#d86b70"))
