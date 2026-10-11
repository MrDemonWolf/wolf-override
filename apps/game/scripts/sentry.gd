class_name Sentry
extends CharacterBody2D
## The purge sentry's body in the Service Junction lane. SentryBrain decides where it goes; this
## node follows that x with the same velocity mover M0Actor uses for an autonomous target, so it
## moves through move_and_slide like the actors. It runs on its lane's rail: no gravity, and it
## sits on no physics layer and scans none, so it never pushes or blocks anyone; contact is the
## brain's test. All of its drawing lives in the one Visual child: the painted machine (a wreck
## once the tank lands on it) with its scanner beam, eye light and a soft lens glow drawn over the
## art in code. The beam is drawn as far as the brain actually sees (see [method beam_tip_x]), with
## a break over the TANK RELEASE alcove, where it cannot see anyone (see [method beam_gap]). Dormant
## behind the sealed door it stands powered down: dark eye, no beam, the machine dimmed.

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
## Fixated on WOLF it watches only him and sees no one else. Facing the rubble its beam ends here,
## short of anyone at the TANK RELEASE (the patrol's near turn, where its front would meet an engineer
## at the alcove's edge); facing WOLF at the far end of the lane (JunctionRoom.WOLF_BAIT_X) it ends at
## his snout (FIXATED_BEAM_FAR_X) rather than run on over him.
const FIXATED_BEAM_END_X: float = SentryBrain.PATROL_MIN_X
const FIXATED_BEAM_FAR_X: float = DropArm.MARK_X + SentryBrain.BAIT_OFFSET - M0Actor.WOLF_REACH
## The soft additive glow over the lens slit.
const LENS_GLOW_SIZE: Vector2 = Vector2(30.0, 16.0)
const LENS_GLOW_ALPHA: float = 0.7
## Powered down until the blast wakes it, the machine is drawn this dark; it brightens over
## WAKE_SECONDS as it powers up.
const DORMANT_TINT: Color = Color(0.42, 0.47, 0.54)
const WAKE_SECONDS: float = 0.35

## The x the brain wants; the mover closes on it at up to CHASE_SPEED.
var target_x: float = SentryBrain.PATROL_MAX_X
## True while the brain is fixated on WOLF: the beam is drawn short (beam_tip_x).
var fixated: bool = false
var visual: SentryVisual
var floor_reflections: Array[FloorReflection] = []
var _down_tween: Tween


## The painted machine, drawn facing +x (the left-facing art is mirrored); the parent flips the
## whole node to face the way the brain does. Over the scanner slit it draws the eye light, a soft
## lens glow and the beam in the brain's colour (off, amber patrol, red from the moment it locks on), reaching
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
	## The stretch ahead of the origin (near, far, in px) where the beam is not drawn because the
	## alcove hides anyone there; an empty span (far <= near) when the beam does not cross it (set by
	## the parent from beam_gap).
	var gap: Vector2 = Vector2.ZERO:
		set(value):
			if not value.is_equal_approx(gap):
				gap = value
				queue_redraw()
	## Main's effects switch: off, the lens glow (dressing) hides; the beam and eye stay.
	var glow_allowed: bool = true:
		set(value):
			glow_allowed = value
			_sync_glow()
	var body: Sprite2D
	var wreck: Sprite2D
	var lens_glow: Sprite2D
	## True while it is powered down (dormant): the body is drawn at DORMANT_TINT.
	var dormant: bool = false
	var _wake_tween: Tween

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

	## Powers the machine down or up; [param animate] brightens it over WAKE_SECONDS as it wakes.
	func set_dormant(value: bool, animate: bool) -> void:
		if _wake_tween != null and _wake_tween.is_valid():
			_wake_tween.kill()
		_wake_tween = null
		dormant = value
		var tint: Color = Sentry.DORMANT_TINT if dormant else Color.WHITE
		if animate and not dormant and is_inside_tree() and body.modulate != tint:
			_wake_tween = create_tween()
			_wake_tween.tween_property(body, "modulate", tint, Sentry.WAKE_SECONDS)
		else:
			body.modulate = tint

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
		var front: float = lens.end.x
		if reach > front:
			var gapped: bool = gap.y > gap.x and gap.x < reach and gap.y > front
			if gapped:
				_draw_beam(front, clampf(gap.x, front, reach), lens)
				_draw_beam(clampf(gap.y, front, reach), reach, lens)
				# A faint edge where the alcove cuts its sight off.
				if gap.x > front:
					_draw_edge(gap.x, lens)
			else:
				_draw_beam(front, reach, lens)
			# The faint edge at the end of its sight, unless that end is inside the alcove's gap.
			if not gapped or reach > gap.y:
				_draw_edge(reach, lens)
		draw_rect(lens, Color(eye, 0.9))

	## The part of the beam from [param from] to [param to] px ahead of the origin, cut from the one
	## cone that opens from the lens slit to BEAM_SPREAD at [member reach] and fades as it goes.
	func _draw_beam(from: float, to: float, lens: Rect2) -> void:
		if to - from < 0.5:
			return
		var y: float = lens.get_center().y
		var near: Vector2 = _beam_section(from, lens)
		var far: Vector2 = _beam_section(to, lens)
		var beam: PackedVector2Array = PackedVector2Array([Vector2(from, y - near.x), Vector2(to, y - far.x), Vector2(to, y + far.x), Vector2(from, y + near.x)])
		draw_polygon(beam, PackedColorArray([Color(eye, near.y), Color(eye, far.y), Color(eye, far.y), Color(eye, near.y)]))
		# A brighter core along the middle.
		draw_line(Vector2(from, y), Vector2(to, y), Color(eye, Sentry.BEAM_TIP_ALPHA * 1.5), 1.0, true)

	## The cone's half-height (x) and opacity (y) at [param at] px ahead of the origin.
	func _beam_section(at: float, lens: Rect2) -> Vector2:
		var t: float = clampf(inverse_lerp(lens.end.x, reach, at), 0.0, 1.0) if reach > lens.end.x else 1.0
		return Vector2(lerpf(lens.size.y * 0.5, Sentry.BEAM_SPREAD, t), lerpf(Sentry.BEAM_ALPHA, Sentry.BEAM_TIP_ALPHA, t))

	func _draw_edge(at: float, lens: Rect2) -> void:
		var y: float = lens.get_center().y
		var half: float = _beam_section(at, lens).x
		draw_line(Vector2(at, y - half), Vector2(at, y + half), Color(eye, Sentry.BEAM_EDGE_ALPHA), 1.0, true)


## Where the drawn beam ends for a sentry at [param x] facing [param facing]: SIGHT_RANGE ahead,
## as far as SentryBrain sees, but never past the rubble line, where nobody can be seen, nor past
## the furthest right the engineer can stand (M0Actor.MAX_X), so it stays inside the room. A
## [param fixated] sentry (WOLF is drawing it) sees no one else, so facing the rubble its beam stops
## at FIXATED_BEAM_END_X, clear of the engineer at the TANK RELEASE, and facing WOLF it stops at his
## snout (FIXATED_BEAM_FAR_X).
static func beam_tip_x(x: float, facing: float, fixated: bool = false) -> float:
	var tip: float = x + signf(facing) * SentryBrain.SIGHT_RANGE
	if facing < 0.0:
		# (A fixated sentry already nearer than that end draws no beam at all.)
		return maxf(tip, minf(FIXATED_BEAM_END_X, x) if fixated else SentryBrain.LANE_ENTRY_X)
	return minf(tip, maxf(FIXATED_BEAM_FAR_X, x) if fixated else M0Actor.MAX_X)


## The world-x span (from, to) of the TANK RELEASE alcove that the beam of a sentry at [param x] facing
## [param facing] would cross. SentryBrain.is_exposed hides an engineer centred anywhere in it, so the
## beam is not drawn there. Vector2.ZERO when the beam does not reach the alcove.
static func beam_gap(x: float, facing: float, fixated: bool = false) -> Vector2:
	var tip: float = beam_tip_x(x, facing, fixated)
	var from: float = maxf(SentryBrain.COVER_MIN_X, minf(x, tip))
	var to: float = minf(SentryBrain.COVER_MAX_X, maxf(x, tip))
	return Vector2(from, to) if to > from else Vector2.ZERO


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
	fixated = brain.state == &"fixated"
	if brain.state != &"down":
		visual.scale.x = brain.facing
		_sync_reach()
	match brain.state:
		&"patrol":
			visual.eye = SentryVisual.EYE_PATROL
		&"lock", &"chase", &"fixated":
			visual.eye = SentryVisual.EYE_LOCKED
		_:
			visual.eye = SentryVisual.EYE_OFF
	var dormant: bool = brain.state == &"dormant"
	if dormant != visual.dormant:
		visual.set_dormant(dormant, true)


## Puts it straight where a restored brain says it is, a wreck if it is down.
func place(brain: SentryBrain) -> void:
	_kill_tween()
	var down: bool = brain.state == &"down"
	var x: float = brain.x
	fixated = brain.state == &"fixated"
	visual.scale.x = brain.facing
	target_x = x
	position = Vector2(x, FLOOR_Y)
	velocity = Vector2.ZERO
	visual.position = Vector2.ZERO
	visual.wrecked = down
	if down:
		visual.eye = SentryVisual.EYE_OFF
	visual.set_dormant(brain.state == &"dormant", false)
	_sync_reach()


## The beam ends where beam_tip_x puts the brain's sight and breaks where beam_gap says (target_x is
## the brain's x; the body can trail it by a few pixels), drawn from where the body is and the way it
## faces.
func _sync_reach() -> void:
	var facing: float = visual.scale.x
	visual.reach = absf(beam_tip_x(target_x, facing, fixated) - position.x)
	var span: Vector2 = beam_gap(target_x, facing, fixated)
	if span.y > span.x:
		var ends: Vector2 = Vector2((span.x - position.x) * facing, (span.y - position.x) * facing)
		visual.gap = Vector2(minf(ends.x, ends.y), maxf(ends.x, ends.y))
	else:
		visual.gap = Vector2.ZERO


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
