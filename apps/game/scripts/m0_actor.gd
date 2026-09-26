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
	var color: Color = Color(0.22, 0.78, 0.96) if actor_id == &"wolf" else Color(0.96, 0.79, 0.40)
	if actor_id == &"wolf":
		draw_rect(Rect2(-25, -10, 47, 19), color)
		draw_colored_polygon(PackedVector2Array([Vector2(15, -12), Vector2(32, -12), Vector2(34, 1), Vector2(20, 5)]), color)
		draw_colored_polygon(PackedVector2Array([Vector2(18, -12), Vector2(20, -26), Vector2(25, -12)]), color)
		draw_colored_polygon(PackedVector2Array([Vector2(26, -12), Vector2(31, -24), Vector2(33, -10)]), color)
		draw_line(Vector2(-24, -7), Vector2(-39, -18), color, 5.0)
		draw_line(Vector2(-17, 6), Vector2(-17, 17), color, 5.0)
		draw_line(Vector2(14, 6), Vector2(14, 17), color, 5.0)
	else:
		draw_circle(Vector2(0, -21), 9.0, color)
		draw_rect(Rect2(-10, -12, 20, 27), color)
		draw_line(Vector2(-7, 13), Vector2(-8, 29), color, 5.0)
		draw_line(Vector2(7, 13), Vector2(8, 29), color, 5.0)
	if controlled:
		draw_rect(Rect2(-39, -34, 78, 69), Color(1.0, 1.0, 1.0, 0.8), false, 2.0)
