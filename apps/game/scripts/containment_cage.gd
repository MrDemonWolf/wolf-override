extends Node2D

@export var shutter: bool = false


func _draw() -> void:
	var steel: Color = Color("#263b48")
	var edge: Color = Color("#66808b")
	if shutter:
		for x: int in range(-72, 73, 18):
			draw_rect(Rect2(x - 3, -53, 6, 115), Color("#12222c"))
			draw_line(Vector2(x + 2, -52), Vector2(x + 2, 61), edge, 1.0)
		for y: int in [-49, 16, 59]:
			draw_rect(Rect2(-80, y, 160, 5), steel)
			draw_line(Vector2(-80, y), Vector2(80, y), edge, 1.0)
		for x: int in [-66, 66]:
			draw_rect(Rect2(x, -39, 4, 16), Color("#f65b45"))
		return
	draw_rect(Rect2(-88, -64, 176, 12), steel)
	draw_rect(Rect2(-88, 64, 176, 10), steel)
	for x: int in [-88, 80]:
		draw_rect(Rect2(x, -64, 8, 138), steel)
		draw_line(Vector2(x + 1, -63), Vector2(x + 1, 73), edge, 1.0)
		for y: int in [-58, 68]:
			draw_circle(Vector2(x + 4, y), 2, Color("#a4b3b6"))
	draw_line(Vector2(-88, -64), Vector2(88, -64), edge, 2.0)
	draw_line(Vector2(-88, 64), Vector2(88, 64), edge, 2.0)
