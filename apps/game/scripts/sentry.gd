class_name Sentry
extends CharacterBody2D
## The purge sentry's body in the Service Junction lane. SentryBrain decides where it goes; this
## node follows that x with the same velocity mover M0Actor uses for an autonomous target, so it
## moves through move_and_slide like the actors. It runs on its lane's rail: no gravity, and it
## sits on no physics layer and scans none, so it never pushes or blocks anyone; contact is the
## brain's test. All of its drawing lives in the one Visual child, so a painted texture can replace
## it later without touching the mover. Provisional art: a code-drawn tracked machine.

## Origin is the middle of its treads on the floor.
const FLOOR_Y: float = 440.0
## The drawing below is laid out for a 44 px body and scaled to the brain's real width.
const DRAW_SCALE: float = SentryBrain.HALF_WIDTH / 22.0
const BODY_SIZE: Vector2 = Vector2(SentryBrain.HALF_WIDTH * 2.0, 40.0 * DRAW_SCALE)
## How far it keels over when the tank lands on it.
const DOWN_DEGREES: float = 78.0

## The x the brain wants; the mover closes on it at up to CHASE_SPEED.
var target_x: float = SentryBrain.PATROL_MAX_X
var visual: SentryVisual
var _down_tween: Tween


## The drawn machine: treads, a squat armoured chassis, a sensor mast and an eye strip whose colour
## is the brain's state (off, amber patrol, red when locked on).
class SentryVisual:
	extends Node2D
	const TREAD: Color = Color("#141b21")
	const HULL: Color = Color("#33424c")
	const HULL_EDGE: Color = Color("#6a808c")
	const STRIPE: Color = Color("#c98a2e")
	const EYE_OFF: Color = Color("#2b1d1d")
	const EYE_PATROL: Color = Color("#f3ae4b")
	const EYE_LOCKED: Color = Color("#ff4a3d")

	var eye: Color = EYE_OFF:
		set(value):
			eye = value
			queue_redraw()

	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * Sentry.DRAW_SCALE)
		draw_rect(Rect2(-22.0, -12.0, 44.0, 12.0), TREAD)
		for wheel: int in 3:
			draw_circle(Vector2(-14.0 + wheel * 14.0, -6.0), 5.0, Color("#26323a"))
			draw_circle(Vector2(-14.0 + wheel * 14.0, -6.0), 2.0, HULL_EDGE)
		var hull: PackedVector2Array = PackedVector2Array([Vector2(-20.0, -12.0), Vector2(20.0, -12.0), Vector2(15.0, -34.0), Vector2(-17.0, -34.0)])
		draw_colored_polygon(hull, HULL)
		draw_polyline(hull + PackedVector2Array([hull[0]]), HULL_EDGE, 1.5, true)
		for stripe: int in 3:
			var x: float = -12.0 + stripe * 9.0
			draw_line(Vector2(x, -14.0), Vector2(x + 6.0, -22.0), STRIPE, 2.0)
		# The sensor head sits forward on the chassis; the eye strip faces the way it moves.
		draw_rect(Rect2(-4.0, -48.0, 20.0, 14.0), Color("#26323a"))
		draw_rect(Rect2(-4.0, -48.0, 20.0, 14.0), HULL_EDGE, false, 1.5)
		draw_line(Vector2(-2.0, -48.0), Vector2(-7.0, -60.0), HULL_EDGE, 1.5)
		draw_circle(Vector2(-7.0, -60.0), 2.0, eye.darkened(0.2))
		if eye != EYE_OFF:
			draw_rect(Rect2(1.0, -46.0, 16.0, 9.0), Color(eye, 0.25))
		draw_rect(Rect2(4.0, -44.0, 4.0, 4.0), eye)
		draw_rect(Rect2(10.0, -44.0, 4.0, 4.0), eye)


func _init() -> void:
	collision_layer = 0
	collision_mask = 0
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func _ready() -> void:
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = BODY_SIZE
	shape.shape = box
	shape.position = Vector2(0.0, -BODY_SIZE.y * 0.5)
	add_child(shape)
	visual = SentryVisual.new()
	visual.name = "Visual"
	add_child(visual)
	position = Vector2(target_x, FLOOR_Y)


func _physics_process(delta: float) -> void:
	var distance: float = target_x - position.x
	velocity = Vector2(clampf(distance / delta, -SentryBrain.CHASE_SPEED, SentryBrain.CHASE_SPEED) if absf(distance) > 0.5 and delta > 0.0 else 0.0, 0.0)
	move_and_slide()
	position.y = FLOOR_Y


## Mirrors the brain: where it wants to be, which way it faces and what its eyes say.
func follow(brain: SentryBrain) -> void:
	target_x = brain.x
	if brain.state != &"down":
		visual.scale.x = brain.facing
	match brain.state:
		&"patrol":
			visual.eye = SentryVisual.EYE_PATROL
		&"chase", &"fixated":
			visual.eye = SentryVisual.EYE_LOCKED
		_:
			visual.eye = SentryVisual.EYE_OFF


## Puts it straight where a restored brain says it is, upright unless it is down.
func place(brain: SentryBrain) -> void:
	_kill_tween()
	var down: bool = brain.state == &"down"
	var x: float = brain.x
	visual.scale.x = brain.facing
	target_x = x
	position = Vector2(x, FLOOR_Y)
	velocity = Vector2.ZERO
	visual.rotation_degrees = DOWN_DEGREES * visual.scale.x if down else 0.0
	visual.position = _down_offset() if down else Vector2.ZERO
	if down:
		visual.eye = SentryVisual.EYE_OFF


## The tank lands: it tips forward onto its sensor head and its eyes die.
func keel_over() -> void:
	_kill_tween()
	visual.eye = SentryVisual.EYE_OFF
	_down_tween = create_tween()
	_down_tween.tween_property(visual, "rotation_degrees", DOWN_DEGREES * visual.scale.x, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_down_tween.parallel().tween_property(visual, "position", _down_offset(), 0.35)


## Keeling over pivots on the front tread corner, so the body tips onto the floor instead of into it.
func _down_offset() -> Vector2:
	var corner: Vector2 = Vector2(BODY_SIZE.x * 0.5 * visual.scale.x, 0.0)
	return corner - corner.rotated(deg_to_rad(DOWN_DEGREES * visual.scale.x))


func _kill_tween() -> void:
	if _down_tween != null and _down_tween.is_valid():
		_down_tween.kill()
	_down_tween = null
