class_name Sentry
extends CharacterBody2D
## The purge sentry's body in the Service Junction lane. SentryBrain decides where it goes; this
## node stands where the brain is every frame (follow), and only rolls back off a knocked-down
## engineer on its own, through move_and_slide like the actors. It runs on its lane's rail: no
## gravity, and it sits on no physics layer and scans none, so it never pushes anyone; contact is
## the brain's test, and the room stops an engineer who walks into it (Main._keep_off_sentry). All of its drawing lives in the one Visual child: the painted machine (a wreck
## once the tank lands on it) with its scanner beam, eye light and a soft lens glow drawn over the
## art in code. The beam is drawn as far as the brain actually sees (see [method beam_tip_x]), ending
## on a hard edge there and at the face of anything solid in the way (the exit bolt's panel, a tank
## on the floor), with a break over the TANK RELEASE alcove, where it cannot see anyone (see
## [method beam_gap]). The painted lamp on its front shows the eye's colour too, so every light on it
## points the way it looks. Dormant behind the sealed door it stands powered down: dark eye and lamp,
## no beam, the machine dimmed.

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
## BEAM_TIP_ALPHA there, where a hard bright edge marks the end of its sight. A pale core runs along
## its middle and dashed pale lines along its two edges, so it still reads where its colour does not
## (red-weak eyes, A11Y-3); a faint edge marks where the alcove cuts it.
const BEAM_SPREAD: float = 12.0
const BEAM_ALPHA: float = 0.34
const BEAM_TIP_ALPHA: float = 0.18
const BEAM_EDGE_ALPHA: float = 0.24
## How much white is mixed into the eye colour for the core, the dashed edges and the tip.
const BEAM_CORE_WHITE: float = 0.7
const BEAM_CORE_ALPHA: float = 0.8
const BEAM_DASH_WHITE: float = 0.45
const BEAM_DASH_ALPHA: float = 0.75
const BEAM_DASH: float = 4.0
const BEAM_DASH_GAP: float = 3.0
const BEAM_TIP_WHITE: float = 0.6
const BEAM_TIP_ALPHA_EDGE: float = 0.95
const BEAM_TIP_WIDTH: float = 2.0
## The round lamp painted on the front of the hull (source pixels: its lens's centre and radius): it is
## drawn over in the eye's colour, dark while the machine is powered down.
const LAMP_CENTRE: Vector2 = Vector2(245.0, 398.0)
const LAMP_RADIUS: float = 32.0
## The lamp's soft halo, this many times its radius, at this opacity.
const LAMP_HALO: float = 1.9
const LAMP_HALO_ALPHA: float = 0.3
## The soft additive glow over the lens slit.
const LENS_GLOW_SIZE: Vector2 = Vector2(30.0, 16.0)
const LENS_GLOW_ALPHA: float = 0.7
## Powered down until the blast wakes it, the machine is drawn this dark; it brightens over
## WAKE_SECONDS as it powers up.
const DORMANT_TINT: Color = Color(0.42, 0.47, 0.54)
const WAKE_SECONDS: float = 0.35
## Having run the engineer down out in its lane, it rolls back off them this fast (recoil_to), so it is
## clear of the body by the time they are down.
const RECOIL_SPEED: float = 480.0

## The x the brain wants; the mover closes on it at up to CHASE_SPEED.
var target_x: float = SentryBrain.PATROL_MAX_X
## True while the brain is fixated on WOLF: it stops scanning and draws no beam (beam_tip_x).
var fixated: bool = false
## Where a beam facing right has to stop, or INF: WOLF's near edge while he holds the far end of the
## lane without drawing it, so the beam never runs on over him. Main sets it every frame.
var beam_stop_x: float = INF
## The tank down at the beam's height (its footprint, SentryBrain.sight_block), or Vector2.ZERO: the
## beam stops at its face as the brain's sight does.
var sight_block: Vector2 = Vector2.ZERO
## How fast the mover closes on target_x: CHASE_SPEED, or RECOIL_SPEED while it rolls back off a
## knocked-down engineer.
var max_speed: float = SentryBrain.CHASE_SPEED
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
	const EYE_PATROL: Color = Palette.AMBER
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

	## What _draw covers, in this node's space: the lamp, the lens and the beam out to where it is
	## drawn (to [member reach], or only to the alcove's near side when its sight ends inside the
	## alcove's [member gap]), at its widest; just the lamp while it is unlit. The debug tools' render
	## box uses it in an exported build, where the renderer cannot report what was drawn.
	func debug_draw_rect() -> Rect2:
		if wrecked:
			return Rect2()
		var lamp: Rect2 = Sentry.lamp_rect()
		if not is_lit():
			return lamp
		var lens: Rect2 = Sentry.lens_rect().merge(lamp)
		if reach <= Sentry.lens_rect().end.x:
			return lens
		var slit: Rect2 = Sentry.lens_rect()
		var end: float = reach
		if gap.y > gap.x and gap.x < reach and gap.y > slit.end.x and reach <= gap.y:
			end = clampf(gap.x, slit.end.x, reach)
		var half: float = maxf(_beam_section(end, slit).x, slit.size.y * 0.5)
		return lens.merge(Rect2(slit.end.x, slit.get_center().y - half, end - slit.end.x, half * 2.0))

	## Powers the machine down or up; [param animate] brightens it over WAKE_SECONDS as it wakes.
	func set_dormant(value: bool, animate: bool) -> void:
		Tweens.kill(_wake_tween)
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
		if wrecked:
			return
		# The hull's lamp in the eye's colour (dark while powered down), with a soft halo while lit.
		var lamp: Rect2 = Sentry.lamp_rect()
		var lamp_centre: Vector2 = lamp.get_center()
		var lamp_radius: float = Sentry.LAMP_RADIUS * Sentry.ART_SCALE
		if is_lit():
			draw_circle(lamp_centre, lamp_radius * Sentry.LAMP_HALO, Color(eye, Sentry.LAMP_HALO_ALPHA))
		draw_circle(lamp_centre, lamp_radius, eye)
		if is_lit():
			draw_circle(lamp_centre, lamp_radius * 0.45, eye.lerp(Color.WHITE, 0.6))
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
			# The hard edge at the end of its sight, unless that end is inside the alcove's gap.
			if not gapped or reach > gap.y:
				_draw_tip(reach, lens)
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
		# A pale core along the middle and dashed pale edges, readable without the colour.
		draw_line(Vector2(from, y), Vector2(to, y), Color(eye.lerp(Color.WHITE, Sentry.BEAM_CORE_WHITE), Sentry.BEAM_CORE_ALPHA), 1.5, true)
		var dash_color: Color = Color(eye.lerp(Color.WHITE, Sentry.BEAM_DASH_WHITE), Sentry.BEAM_DASH_ALPHA)
		var at: float = from
		while at < to - 0.5:
			var end: float = minf(at + Sentry.BEAM_DASH, to)
			var a: float = _beam_section(at, lens).x
			var b: float = _beam_section(end, lens).x
			draw_line(Vector2(at, y - a), Vector2(end, y - b), dash_color, 1.0, true)
			draw_line(Vector2(at, y + a), Vector2(end, y + b), dash_color, 1.0, true)
			at = end + Sentry.BEAM_DASH_GAP

	## The cone's half-height (x) and opacity (y) at [param at] px ahead of the origin.
	func _beam_section(at: float, lens: Rect2) -> Vector2:
		var t: float = clampf(inverse_lerp(lens.end.x, reach, at), 0.0, 1.0) if reach > lens.end.x else 1.0
		return Vector2(lerpf(lens.size.y * 0.5, Sentry.BEAM_SPREAD, t), lerpf(Sentry.BEAM_ALPHA, Sentry.BEAM_TIP_ALPHA, t))

	func _draw_edge(at: float, lens: Rect2) -> void:
		var y: float = lens.get_center().y
		var half: float = _beam_section(at, lens).x
		draw_line(Vector2(at, y - half), Vector2(at, y + half), Color(eye, Sentry.BEAM_EDGE_ALPHA), 1.0, true)

	## The hard end of its sight at [param at] px ahead: a bright bar across the beam, its outer side on
	## the tip, so nothing is drawn past where it sees.
	func _draw_tip(at: float, lens: Rect2) -> void:
		var y: float = lens.get_center().y
		var half: float = _beam_section(at, lens).x
		var x: float = at - Sentry.BEAM_TIP_WIDTH * 0.5
		draw_line(Vector2(x, y - half), Vector2(x, y + half), Color(eye.lerp(Color.WHITE, Sentry.BEAM_TIP_WHITE), Sentry.BEAM_TIP_ALPHA_EDGE), Sentry.BEAM_TIP_WIDTH)


## Where the drawn beam ends for a sentry at [param x] facing [param facing]: where SentryBrain's
## sight ends (SentryBrain.sight_end_x: SIGHT_RANGE ahead, or the face of the exit bolt's panel or of a
## [param tank] down at its height standing in the way), but never past the rubble line, where nobody
## can be seen, nor past the furthest right the engineer can stand (M0Actor.MAX_X), so it stays inside
## the room, nor, facing right, past [param stop_x] (WOLF's near edge while he holds the far end). A
## [param fixated] sentry (WOLF is drawing it) stops scanning: it watches only him, with its red eye,
## and draws no beam, so nothing is drawn over the engineer at the TANK RELEASE, over WOLF, or across
## the EXIT BOLT box between it on the mark and WOLF by the hatch.
static func beam_tip_x(x: float, facing: float, fixated: bool = false, stop_x: float = INF, tank: Vector2 = Vector2.ZERO) -> float:
	if fixated:
		return x
	var tip: float = SentryBrain.sight_end_x(x, facing, tank)
	if facing < 0.0:
		return minf(x, maxf(tip, SentryBrain.LANE_ENTRY_X))
	return maxf(x, minf(tip, minf(M0Actor.MAX_X, stop_x)))


## The world-x span (from, to) of the TANK RELEASE alcove that the beam of a sentry at [param x] facing
## [param facing] would cross. SentryBrain.is_exposed hides an engineer centred anywhere in it, so the
## beam is not drawn there. Vector2.ZERO when the beam does not reach the alcove.
static func beam_gap(x: float, facing: float, fixated: bool = false, stop_x: float = INF, tank: Vector2 = Vector2.ZERO) -> Vector2:
	var tip: float = beam_tip_x(x, facing, fixated, stop_x, tank)
	var from: float = maxf(SentryBrain.COVER_MIN_X, minf(x, tip))
	var to: float = minf(SentryBrain.COVER_MAX_X, maxf(x, tip))
	return Vector2(from, to) if to > from else Vector2.ZERO


## The highest the beam reaches (its top edge at its widest), in the room: anything solid lower than
## this in its way stops it.
static func beam_top_y() -> float:
	return FLOOR_Y + lens_rect().get_center().y - BEAM_SPREAD


## The hull's lamp in the visual's space (facing +x), from the active art's LAMP_CENTRE and its halo.
static func lamp_rect() -> Rect2:
	var centre: Vector2 = Vector2(ACTIVE_TREAD_X - LAMP_CENTRE.x, -(ACTIVE_REGION.end.y - LAMP_CENTRE.y)) * ART_SCALE
	var radius: float = LAMP_RADIUS * ART_SCALE * LAMP_HALO
	return Rect2(centre - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)


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
	velocity = Vector2(clampf(distance / delta, -max_speed, max_speed) if absf(distance) > 0.5 and delta > 0.0 else 0.0, 0.0)
	move_and_slide()
	position.y = FLOOR_Y
	_sync_reach()


## Mirrors the brain: where it wants to be, which way it faces and what its eyes say.
func follow(brain: SentryBrain) -> void:
	target_x = brain.x
	max_speed = SentryBrain.CHASE_SPEED
	# Drawn where the brain is this frame (it moves at most a chase step a frame), so its body, its
	# contact range and the beam it sees by are the one place; only the recoil off a knocked-down
	# engineer is left to the mover.
	position.x = target_x
	velocity = Vector2.ZERO
	fixated = brain.state == &"fixated"
	sight_block = brain.sight_block
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
	sight_block = brain.sight_block
	visual.scale.x = brain.facing
	target_x = x
	max_speed = SentryBrain.CHASE_SPEED
	position = Vector2(x, FLOOR_Y)
	velocity = Vector2.ZERO
	visual.position = Vector2.ZERO
	visual.wrecked = down
	if down:
		visual.eye = SentryVisual.EYE_OFF
	visual.set_dormant(brain.state == &"dormant", false)
	_sync_reach()


## The beam ends where beam_tip_x puts the brain's sight and breaks where beam_gap says (target_x is
## the brain's x, where follow puts the body), drawn from where the body is and the way it faces.
func _sync_reach() -> void:
	var facing: float = visual.scale.x
	# Rolling back off a knocked-down engineer it is not looking anywhere new: the beam keeps to the body.
	var sight_x: float = position.x if max_speed == RECOIL_SPEED else target_x
	visual.reach = absf(beam_tip_x(sight_x, facing, fixated, beam_stop_x, sight_block) - position.x)
	var span: Vector2 = beam_gap(sight_x, facing, fixated, beam_stop_x, sight_block)
	if span.y > span.x:
		var ends: Vector2 = Vector2((span.x - position.x) * facing, (span.y - position.x) * facing)
		visual.gap = Vector2(minf(ends.x, ends.y), maxf(ends.x, ends.y))
	else:
		visual.gap = Vector2.ZERO


## With the engineer knocked down near it, it rolls back to [param x], still facing them, so it
## stands clear of the lying body (Main._start_collapse), or is put there [param at_once] when the body
## lies down at once; the next restore places it afresh.
func recoil_to(x: float, at_once: bool = false) -> void:
	target_x = x
	max_speed = RECOIL_SPEED
	if at_once:
		# The body lies down at once (Reduced Motion), so the machine is put there on the same frame.
		position.x = x
		velocity = Vector2.ZERO
		_sync_reach()


## What the machine draws, as boxes in its parent's space: its painted body (or wreck) and, from
## SentryVisual.debug_draw_rect, the lamp and, while lit, the lens and the beam, plus the lens glow
## while it shows (JunctionRoom.bolt_panel_cover draws the panel over these).
func drawn_rects() -> Array[Rect2]:
	var to_parent: Transform2D = transform * visual.transform
	var art: Sprite2D = visual.wreck if visual.wrecked else visual.body
	var rects: Array[Rect2] = [to_parent * art.transform * art.get_rect()]
	var marks: Rect2 = visual.debug_draw_rect()
	if marks.has_area():
		rects.append(to_parent * marks)
	if visual.lens_glow.visible:
		rects.append(to_parent * visual.lens_glow.transform * visual.lens_glow.get_rect())
	return rects


## How far its drawn active body reaches from its origin on its longer side, in px.
static func drawn_half_width() -> float:
	return maxf(ACTIVE_TREAD_X - ACTIVE_REGION.position.x, ACTIVE_REGION.end.x - ACTIVE_TREAD_X) * ART_SCALE


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
	Tweens.kill(_down_tween)
	_down_tween = null
