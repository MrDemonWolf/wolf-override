class_name M0Actor
extends CharacterBody2D

@export var actor_id: StringName = &"human"
@onready var body_sprite: Sprite2D = get_node_or_null("BodySprite") as Sprite2D

var controlled: bool = false
var follow_target: Node2D
var autonomous_target_x: float = -1.0

const WALK_SPEED: float = 190.0
const FOLLOW_SPEED: float = 220.0
const FOLLOW_GAP: float = 64.0
const GRAVITY: float = 900.0


func _physics_process(delta: float) -> void:
	if controlled:
		velocity.x = Input.get_axis(&"move_left", &"move_right") * WALK_SPEED
	elif autonomous_target_x >= 0.0:
		var distance: float = autonomous_target_x - position.x
		velocity.x = clampf(distance / delta, -FOLLOW_SPEED, FOLLOW_SPEED) if absf(distance) > 2.0 else 0.0
	elif follow_target != null:
		var target_x: float = clampf(follow_target.position.x - FOLLOW_GAP, 40.0, 920.0)
		var distance: float = target_x - position.x
		velocity.x = clampf(distance / delta, -FOLLOW_SPEED, FOLLOW_SPEED) if absf(distance) > 2.0 else 0.0
	else:
		velocity.x = 0.0
	if body_sprite != null and absf(velocity.x) > 1.0:
		body_sprite.flip_h = velocity.x < 0.0
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += GRAVITY * delta
	move_and_slide()
	position.x = clampf(position.x, 40.0, 920.0)


func _draw() -> void:
	if controlled:
		var ground_y: float = 22.0 if actor_id == &"wolf" else 34.0
		draw_line(Vector2(-31, ground_y), Vector2(31, ground_y), Color("#eaf4ff"), 3.0)
		draw_line(Vector2(-31, ground_y), Vector2(-24, ground_y - 5), Color("#eaf4ff"), 2.0)
		draw_line(Vector2(31, ground_y), Vector2(24, ground_y - 5), Color("#eaf4ff"), 2.0)
