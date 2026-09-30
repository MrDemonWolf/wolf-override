extends Node2D

@export var shutter: bool = false
var opening: float = 0.0:
	set(value):
		opening = clampf(value, 0.0, 1.0)
		queue_redraw()


func _draw() -> void:
	var steel: Color = Color("#24323a")
	var edge: Color = Color("#6b7e86")
	if shutter:
		var right: float = 80.0 - opening * 160.0
		if right <= -80.0:
			return
		for rest_x: int in range(-72, 73, 18):
			var x: float = rest_x - opening * 160.0
			if x < -77.0:
				continue
			draw_rect(Rect2(x - 3, -53, 6, 125), Color("#111a20"))
			draw_line(Vector2(x - 2, -53), Vector2(x - 2, 72), Color("#52616a"), 1.0)
			draw_line(Vector2(x + 2, -53), Vector2(x + 2, 72), Color("#080e13"), 2.0)
		for y: int in [-49, 16, 68]:
			draw_rect(Rect2(-80, y, right + 80, 5), steel)
			draw_line(Vector2(-80, y), Vector2(right, y), edge, 1.0)
		return
	draw_colored_polygon(PackedVector2Array([Vector2(-88, -64), Vector2(-78, -73), Vector2(98, -73), Vector2(88, -64)]), Color("#3b4b53"))
	draw_rect(Rect2(-88, -64, 176, 12), Color("#18242c"))
	draw_rect(Rect2(-88, 76, 176, 10), Color("#17232a"))
	for x: int in [-88, 80]:
		draw_rect(Rect2(x, -64, 8, 150), steel)
		draw_line(Vector2(x + 1, -63), Vector2(x + 1, 85), edge, 1.0)
		for y: int in [-58, 80]:
			draw_circle(Vector2(x + 4, y), 2, Color("#87949a"))
		draw_rect(Rect2(x - 1, -37, 10, 22), Color("#0b141a"))
		draw_rect(Rect2(x + 2, -33, 3, 14), Color("#db4f39"))
	draw_line(Vector2(-88, -64), Vector2(88, -64), edge, 2.0)
	draw_line(Vector2(-88, 76), Vector2(88, 76), edge, 2.0)
