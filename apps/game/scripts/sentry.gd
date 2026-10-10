class_name Sentry
extends CharacterBody2D
## The purge sentry's body in the Service Junction lane. SentryBrain decides where it goes; this
## node follows that x with the same velocity mover M0Actor uses for an autonomous target, so it
## moves through move_and_slide like the actors. It runs on its lane's rail: no gravity, and it
## sits on no physics layer and scans none, so it never pushes or blocks anyone; contact is the
## brain's test. All of its drawing lives in the one Visual child: the painted machine (a wreck
## once the tank lands on it) with its scanner beam, eye light and a soft lens glow drawn over the
## art in code. The beam is drawn as far as the brain actually sees (see [method beam_tip_x]).

## Origin is the middle of its treads on the floor.
const FLOOR_Y: float = 440.0
const ACTIVE_ART: Texture2D = preload("res://assets/props/junction-sentry-side-left.png")
const WRECK_ART: Texture2D = preload("res://assets/props/junction-sentry-down.png")
## Each image is cut to its painted outline; both face left and share one scale, chosen so the
## treads are a little longer than the brain's body (SentryBrain.HALF_WIDTH).
const ACTIVE_REGION: Rect2 = Rect2(113.0, 57.0, 855.0, 626.0)
const WRECK_REGION: Rect2 = Rect2(143.0, 80.0, 844.0, 623.0)
const ART_SCALE: float = 0.07
## The source column under the middle of each machine's treads (the node's origin).
const ACTIVE_TREAD_X: float = 516.0
const WRECK_TREAD_X: float = 545.0
## The source row of the crushed hull's top either side of the bent mast on the wreck art. A tank
## that lands on the sentry rests this high, so the wreck's treads and hull show under it.
const WRECK_HULL_TOP: float = 340.0
const WRECK_CRUSH_HEIGHT: float = (WRECK_REGION.end.y - WRECK_HULL_TOP) * ART_SCALE
## The scanner slit on the active art (source pixels): the beam and eye light are drawn over it.
const LENS: Rect2 = Rect2(370.0, 166.0, 145.0, 28.0)
const BODY_SIZE: Vector2 = Vector2(SentryBrain.HALF_WIDTH * 2.0, 30.0)
## How far the drawing reaches above the floor: the top of the scanner's fin.
const DRAWN_HEIGHT: float = ACTIVE_REGION.size.y * ART_SCALE
## The beam opens to this half-height at its tip and fades from BEAM_ALPHA at the lens to
## BEAM_TIP_ALPHA there, where a faint edge marks the end of its sight.
const BEAM_SPREAD: float = 12.0
const BEAM_ALPHA: float = 0.34
const BEAM_TIP_ALPHA: float = 0.08
const BEAM_EDGE_ALPHA: float = 0.24
## The soft additive glow over the lens slit.
const LENS_GLOW_SIZE: Vector2 = Vector2(30.0, 16.0)
const LENS_GLOW_ALPHA: float = 0.7

## The x the brain wants; the mover closes on it at up to CHASE_SPEED.
var target_x: float = SentryBrain.PATROL_MAX_X
var visual: SentryVisual
var floor_reflections: Array[FloorReflection] = []
var _down_tween: Tween


## The painted machine, drawn facing +x (the left-facing art is mirrored); the parent flips the
## whole node to face the way the brain does. Over the scanner slit it draws the eye light, a soft
## lens glow and the beam in the brain's colour (off, amber patrol, red when locked on), reaching
## [member reach] px ahead of the machine's origin; the wreck has none of them.
class SentryVisual:
	extends Node2D
	const EYE_OFF: Color = Color("#2b1d1d")
	const EYE_PATROL: Color = Color("#f3ae4b")
	const EYE_LOCKED: Color = Color("#ff4a3d")

	var eye: Color = EYE_OFF:
		set(value):
			eye = value
			_sync_glow()
			queue_redraw()
	var wrecked: bool = false:
		set(value):
			wrecked = value
			if body != null:
				body.visible = not wrecked
				wreck.visible = wrecked
			_sync_glow()
			queue_redraw()
	## How far ahead of the origin the beam ends, in px (set by the parent from beam_tip_x).
	var reach: float = SentryBrain.SIGHT_RANGE:
		set(value):
			if not is_equal_approx(value, reach):
				reach = value
				queue_redraw()
	## Main's effects switch: off, the lens glow (dressing) hides; the beam and eye stay.
	var glow_allowed: bool = true:
		set(value):
			glow_allowed = value
			_sync_glow()
	var body: Sprite2D
	var wreck: Sprite2D
	var lens_glow: Sprite2D

	func _init() -> void:
		body = _art("Body", Sentry.ACTIVE_ART, Sentry.ACTIVE_REGION, Sentry.ACTIVE_TREAD_X)
		wreck = _art("Wreck", Sentry.WRECK_ART, Sentry.WRECK_REGION, Sentry.WRECK_TREAD_X)
		wreck.visible = false
		var lens: Rect2 = Sentry.lens_rect()
		lens_glow = RoomDepth.make_glow(EYE_PATROL, Sentry.LENS_GLOW_SIZE, Sentry.LENS_GLOW_ALPHA)
		lens_glow.name = "LensGlow"
		lens_glow.position = Vector2(lens.end.x - 2.0, lens.get_center().y)
		add_child(lens_glow)
		_sync_glow()

	func is_lit() -> bool:
		return not wrecked and eye != EYE_OFF

	func _sync_glow() -> void:
		if lens_glow == null:
			return
		lens_glow.visible = glow_allowed and is_lit()
		lens_glow.modulate = Color(eye, Sentry.LENS_GLOW_ALPHA)

	## A mirrored cut of [param texture] with its base on the floor and [param tread_x] at x 0. It
	## draws behind this node's own lens drawing.
	func _art(art_name: String, texture: Texture2D, region: Rect2, tread_x: float) -> Sprite2D:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = art_name
		sprite.texture = texture
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.region_enabled = true
		sprite.region_rect = region
		sprite.flip_h = true
		sprite.scale = Vector2.ONE * Sentry.ART_SCALE
		sprite.position = Vector2(-(region.get_center().x - tread_x), -region.size.y * 0.5) * Sentry.ART_SCALE
		sprite.show_behind_parent = true
		add_child(sprite)
		return sprite

	func _draw() -> void:
		if not is_lit():
			return
		var lens: Rect2 = Sentry.lens_rect()
		var front: Vector2 = Vector2(lens.end.x, lens.get_center().y)
		if reach > front.x:
			var tip: float = reach
			var half: float = lens.size.y * 0.5
			var beam: PackedVector2Array = PackedVector2Array([front + Vector2(0.0, -half), Vector2(tip, front.y - Sentry.BEAM_SPREAD), Vector2(tip, front.y + Sentry.BEAM_SPREAD), front + Vector2(0.0, half)])
			draw_polygon(beam, PackedColorArray([Color(eye, Sentry.BEAM_ALPHA), Color(eye, Sentry.BEAM_TIP_ALPHA), Color(eye, Sentry.BEAM_TIP_ALPHA), Color(eye, Sentry.BEAM_ALPHA)]))
			# A brighter core along the middle, and a faint edge where its sight ends.
			draw_line(front, Vector2(tip, front.y), Color(eye, Sentry.BEAM_TIP_ALPHA * 1.5), 1.0, true)
			draw_line(Vector2(tip, front.y - Sentry.BEAM_SPREAD), Vector2(tip, front.y + Sentry.BEAM_SPREAD), Color(eye, Sentry.BEAM_EDGE_ALPHA), 1.0, true)
		draw_rect(lens, Color(eye, 0.9))


## Where the drawn beam ends for a sentry at [param x] facing [param facing]: SIGHT_RANGE ahead,
## as far as SentryBrain sees, but never past the rubble line, where nobody can be seen.
static func beam_tip_x(x: float, facing: float) -> float:
	var tip: float = x + signf(facing) * SentryBrain.SIGHT_RANGE
	return maxf(tip, SentryBrain.LANE_ENTRY_X) if facing < 0.0 else tip


## The scanner slit in the visual's space (facing +x), from the active art's LENS.
static func lens_rect() -> Rect2:
	var left: float = -(LENS.end.x - ACTIVE_TREAD_X) * ART_SCALE
	var top: float = -(ACTIVE_REGION.end.y - LENS.position.y) * ART_SCALE
	return Rect2(left, top, LENS.size.x * ART_SCALE, LENS.size.y * ART_SCALE)


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
	for art: Sprite2D in [visual.body, visual.wreck]:
		floor_reflections.append(FloorReflection.attach(art))
	position = Vector2(target_x, FLOOR_Y)


func _physics_process(delta: float) -> void:
	var distance: float = target_x - position.x
	velocity = Vector2(clampf(distance / delta, -SentryBrain.CHASE_SPEED, SentryBrain.CHASE_SPEED) if absf(distance) > 0.5 and delta > 0.0 else 0.0, 0.0)
	move_and_slide()
	position.y = FLOOR_Y
	_sync_reach()


## Mirrors the brain: where it wants to be, which way it faces and what its eyes say.
func follow(brain: SentryBrain) -> void:
	target_x = brain.x
	if brain.state != &"down":
		visual.scale.x = brain.facing
		_sync_reach()
	match brain.state:
		&"patrol":
			visual.eye = SentryVisual.EYE_PATROL
		&"chase", &"fixated":
			visual.eye = SentryVisual.EYE_LOCKED
		_:
			visual.eye = SentryVisual.EYE_OFF


## Puts it straight where a restored brain says it is, a wreck if it is down.
func place(brain: SentryBrain) -> void:
	_kill_tween()
	var down: bool = brain.state == &"down"
	var x: float = brain.x
	visual.scale.x = brain.facing
	target_x = x
	position = Vector2(x, FLOOR_Y)
	velocity = Vector2.ZERO
	visual.position = Vector2.ZERO
	visual.wrecked = down
	if down:
		visual.eye = SentryVisual.EYE_OFF
	_sync_reach()


## The beam ends where beam_tip_x puts the brain's sight (target_x is the brain's x; the body can
## trail it by a few pixels), drawn from where the body is and the way it faces.
func _sync_reach() -> void:
	visual.reach = absf(beam_tip_x(target_x, visual.scale.x) - position.x)


## The tank lands on it at [param at_x]: the machine is pinned there and crushed into its wreck,
## which drops the last few pixels onto its treads, and its eye dies.
func keel_over(at_x: float) -> void:
	_kill_tween()
	target_x = at_x
	position.x = at_x
	velocity = Vector2.ZERO
	visual.eye = SentryVisual.EYE_OFF
	visual.wrecked = true
	visual.position = Vector2(0.0, -6.0)
	_down_tween = create_tween()
	_down_tween.tween_property(visual, "position", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _kill_tween() -> void:
	if _down_tween != null and _down_tween.is_valid():
		_down_tween.kill()
	_down_tween = null
