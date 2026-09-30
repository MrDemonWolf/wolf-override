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
		var bottom: float = maxf(-53.0, 72.0 - opening * 128.0)
		if bottom <= -53.0:
			return
		for x: int in range(-72, 73, 18):
			draw_rect(Rect2(x - 3, -53, 6, bottom + 53), Color("#111a20"))
			draw_line(Vector2(x - 2, -53), Vector2(x - 2, bottom), Color("#52616a"), 1.0)
			draw_line(Vector2(x + 2, -53), Vector2(x + 2, bottom), Color("#080e13"), 2.0)
		for rest_y: int in [-49, 16, 68]:
			var y: float = rest_y - opening * 128.0
			if y < -53.0:
				continue
			draw_rect(Rect2(-80, y, 160, 5), steel)
			draw_line(Vector2(-80, y), Vector2(80, y), edge, 1.0)
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
