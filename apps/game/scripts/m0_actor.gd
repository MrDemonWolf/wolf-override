class_name M0Actor
extends CharacterBody2D

@export var actor_id: StringName = &"human"

var controlled: bool = false

const WALK_SPEED: float = 190.0
const GRAVITY: float = 900.0


func _physics_process(delta: float) -> void:
	velocity.x = Input.get_axis(&"move_left", &"move_right") * WALK_SPEED if controlled else 0.0
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += GRAVITY * delta
	move_and_slide()
	position.x = clampf(position.x, 40.0, 920.0)


func _draw() -> void:
	if actor_id == &"wolf":
		draw_line(Vector2(-21, -6), Vector2(-38, -18), Color("#24495e"), 7.0)
		draw_line(Vector2(-38, -18), Vector2(-44, -22), Color("#8be3ff"), 3.0)
		draw_rect(Rect2(-27, -12, 49, 22), Color("#163449"))
		draw_rect(Rect2(-22, -10, 40, 14), Color("#3b8da5"))
		draw_line(Vector2(-16, -7), Vector2(13, -7), Color("#8be3ff"), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(14, -13), Vector2(31, -11), Vector2(34, 3), Vector2(19, 5)]), Color("#3b8da5"))
		draw_colored_polygon(PackedVector2Array([Vector2(18, -12), Vector2(20, -27), Vector2(25, -12)]), Color("#8be3ff"))
		draw_colored_polygon(PackedVector2Array([Vector2(26, -12), Vector2(31, -25), Vector2(33, -10)]), Color("#8be3ff"))
		draw_line(Vector2(23, -6), Vector2(28, -6), Color("#eaf4ff"), 2.0)
		draw_line(Vector2(-18, 8), Vector2(-18, 17), Color("#24495e"), 6.0)
		draw_line(Vector2(14, 7), Vector2(14, 17), Color("#24495e"), 6.0)
		draw_line(Vector2(-22, 17), Vector2(-12, 17), Color("#8be3ff"), 2.0)
		draw_line(Vector2(10, 17), Vector2(20, 17), Color("#8be3ff"), 2.0)
	else:
		draw_circle(Vector2(0, -23), 10.0, Color("#142c43"))
		draw_arc(Vector2(0, -23), 10.0, PI, TAU, 16, Color("#f3c475"), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-10, -12), Vector2(10, -12), Vector2(13, 15), Vector2(-13, 15)]), Color("#b07d3e"))
		draw_rect(Rect2(-7, -7, 14, 17), Color("#f3c475"))
		draw_line(Vector2(-13, -7), Vector2(-17, 11), Color("#8d6035"), 5.0)
		draw_line(Vector2(13, -7), Vector2(17, 11), Color("#8d6035"), 5.0)
		draw_line(Vector2(-7, 14), Vector2(-8, 29), Color("#203d51"), 6.0)
		draw_line(Vector2(7, 14), Vector2(8, 29), Color("#203d51"), 6.0)
		draw_line(Vector2(-12, 29), Vector2(-3, 29), Color("#f3c475"), 2.0)
		draw_line(Vector2(4, 29), Vector2(12, 29), Color("#f3c475"), 2.0)
	if controlled:
		var ground_y: float = 22.0 if actor_id == &"wolf" else 34.0
		draw_line(Vector2(-31, ground_y), Vector2(31, ground_y), Color("#eaf4ff"), 3.0)
		draw_line(Vector2(-31, ground_y), Vector2(-24, ground_y - 5), Color("#eaf4ff"), 2.0)
		draw_line(Vector2(31, ground_y), Vector2(24, ground_y - 5), Color("#eaf4ff"), 2.0)
