class_name M0Actor
extends CharacterBody2D

@export var actor_id: StringName = &"human"
@onready var body_sprite: Sprite2D = get_node_or_null("BodySprite") as Sprite2D

var controlled: bool = false
var follow_target: Node2D
var autonomous_target_x: float = NO_TARGET
## GREY BOX (L1): the left clamp is per room now; the lockdown room reaches into the dock room (-730).
var min_x: float = MIN_X
## Where a follower may stand; main pulls follow_max_x back from a sealed door so WOLF never noses into it.
var follow_min_x: float = MIN_X
var follow_max_x: float = MAX_X
## The body this one draws behind and dims against while walking past it (WOLF and the engineer).
var keep_clear_of: M0Actor
## The side of follow_target a follower stands on: -1 left, 1 right, 0 not chosen yet.
var follow_side: int = 0
## How long the engineer has faced the way that would put WOLF on his other side.
var turn_seconds: float = 0.0
## Where a controlled body eases to while no move input is held (main sets it beside a machine the
## engineer stopped over), or -1. It is a sidestep: the body keeps the way it faces, so WOLF, who
## follows on the side it faces away from, stays where he is. Any move input wins.
var settle_x: float = -1.0
## The room's machines as x spans (from, to); a follower rests clear of them when clear floor is at
## most AVOID_DETOUR further back from the engineer (main sets them per room).
var avoid_spans: Array[Vector2] = []
## Scales the speed of a body walking on its own or following (main speeds WOLF up for the moment he
## bounds over the junction's sentry, JunctionRoom.wolf_leap_height, and while he dashes past the
## engineer waiting for him at the rubble line).
var speed_scale: float = 1.0

const WALK_SPEED: float = 190.0
const FOLLOW_SPEED: float = 220.0
## The unhurried step out from over a machine (settle_x).
const SETTLE_SPEED: float = 140.0
## Horizontal reach of each drawn body from its origin, rounded up from the sprites' visible pixels
## (WOLF's run about -64..66 px, the engineer's about -16..15; flipping mirrors them).
## follow_spacing_test measures the art against these.
const WOLF_REACH: float = 67.0
const HUMAN_REACH: float = 17.0
## How far WOLF's painted body (pixels more than half opaque) reaches ahead of his origin to his snout
## and behind it to his tail tip. His authored spots stand him on clear floor by these, and
## wolf_space_test measures the art against them.
const WOLF_SNOUT: float = 59.1
const WOLF_TAIL: float = 56.0
## A follower stands this far from the engineer: both reaches plus a little air.
const FOLLOW_GAP: float = 88.0
## The least spacing at which the two drawn bodies still do not touch. A side with less room than
## this (a wall or a sealed door) sends WOLF to the engineer's other side.
const CLEAR_GAP: float = WOLF_REACH + HUMAN_REACH
## The engineer has to face a new way this long before WOLF crosses to his other side, so a tap
## back and forth never sets him weaving.
const TURN_SETTLE_SECONDS: float = 0.3
## A step at most this long to a follower's spot beside an engineer who is standing still is an edge:
## he keeps the way he faces rather than mirroring round for the two or three frames it takes (the
## seal landing, where follow_max_x draws him a few px back off the relay contact).
const FOLLOW_EDGE: float = 12.0
## How much further back than FOLLOW_GAP a follower goes to stand clear of a machine; with no clear
## floor that close he keeps the usual gap.
const AVOID_DETOUR: float = 100.0
## WOLF_REACH is rounded up past his painted nose and tail tip, so this much of it may touch a machine.
const AVOID_TOLERANCE: float = 4.0
const MIN_X: float = 40.0
## GREY BOX (L1): "no target". In L1 real targets can be negative world x, so the old ">= 0" test
## for "has a target" no longer works; -1.0 stays the sentinel and is compared exactly.
const NO_TARGET: float = -1.0
const MAX_X: float = 920.0
## While walking past the engineer WOLF draws behind him (main orders him first) and dims a little,
## so the pass reads as behind rather than through.
const PASS_TINT: Color = Color(0.7, 0.76, 0.84)
const PASS_TINT_RATE: float = 6.0
const GRAVITY: float = 900.0


func _physics_process(delta: float) -> void:
	var following: bool = false
	var settling: bool = false
	var edging: bool = false
	if controlled:
		var axis: float = Input.get_axis(&"move_left", &"move_right")
		velocity.x = axis * WALK_SPEED
		if axis == 0.0 and settle_x >= 0.0:
			velocity.x = clampf(_approach(settle_x, delta), -SETTLE_SPEED, SETTLE_SPEED)
			settling = true
	elif autonomous_target_x != NO_TARGET:
		velocity.x = _approach(autonomous_target_x, delta)
		# Once he has walked off on his own, he picks his side afresh from the engineer's facing.
		follow_side = 0
	elif follow_target != null:
		following = true
		var spot: float = follow_x(delta)
		velocity.x = _approach(spot, delta)
		var target_body: CharacterBody2D = follow_target as CharacterBody2D
		edging = absf(spot - position.x) <= FOLLOW_EDGE and (target_body == null or absf(target_body.velocity.x) <= 1.0)
	else:
		velocity.x = 0.0
	if not following:
		# A pause in following (a choice, a chapter close) keeps his side, so a turn still has to
		# hold for TURN_SETTLE_SECONDS of play before he crosses.
		turn_seconds = 0.0
	if body_sprite != null:
		var moving: bool = absf(velocity.x) > 1.0
		if moving and not settling and not edging:
			body_sprite.flip_h = velocity.x < 0.0
		elif following and not moving:
			# At rest beside the engineer he faces him, even where follow_max_x holds him back on the
			# other side of them from follow_side.
			body_sprite.flip_h = follow_target.position.x < position.x
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y += GRAVITY * delta
	move_and_slide()
	position.x = clampf(position.x, min_x, MAX_X)
	_tint_pass(delta)


## Where a follower heads this step: FOLLOW_GAP from the target on the side away from the way the
## target faces, so the engineer walks into open floor rather than into WOLF. A turn has to hold for
## TURN_SETTLE_SECONDS before he changes sides; a side without room for both bodies (a wall, a
## sealed door) sends him to the other side, and he returns only once the preferred side has the full gap.
## Where his spot would stand him over a machine and clear floor is a little further back, he rests
## there instead (off_machines).
func follow_x(delta: float) -> float:
	var target_x: float = follow_target.position.x
	var away: int = -facing_of(follow_target)
	if follow_side == 0:
		follow_side = away if has_room(target_x, away, CLEAR_GAP) or not has_room(target_x, -away, CLEAR_GAP) else -away
		turn_seconds = 0.0
	else:
		var wanted: int = follow_side
		if away != follow_side and has_room(target_x, away, FOLLOW_GAP):
			turn_seconds += delta
			if turn_seconds >= TURN_SETTLE_SECONDS:
				wanted = away
		else:
			turn_seconds = 0.0
		if not has_room(target_x, wanted, CLEAR_GAP) and has_room(target_x, -wanted, CLEAR_GAP):
			wanted = -wanted
		if wanted != follow_side:
			follow_side = wanted
			turn_seconds = 0.0
	return off_machines(clampf(target_x + follow_side * FOLLOW_GAP, follow_min_x, follow_max_x), follow_side)


## [param x], or, when a follower's body there would stand over one of avoid_spans, the nearest spot
## further from the engineer (on [param side]) that is clear of every span, if that is no more than
## AVOID_DETOUR away and inside the follow range.
func off_machines(x: float, side: int) -> float:
	var spot: float = x
	for _pass: int in avoid_spans.size() + 1:
		var moved: bool = false
		for span: Vector2 in avoid_spans:
			if spot + WOLF_REACH - AVOID_TOLERANCE > span.x and spot - WOLF_REACH + AVOID_TOLERANCE < span.y:
				spot = span.x - WOLF_REACH + AVOID_TOLERANCE if side < 0 else span.y + WOLF_REACH - AVOID_TOLERANCE
				moved = true
		if not moved:
			break
	if absf(spot - x) > AVOID_DETOUR or spot < follow_min_x or spot > follow_max_x:
		return x
	return spot


## True when standing FOLLOW_GAP to [param side] of [param target_x], held inside the follow range,
## still leaves at least [param need] between the two.
func has_room(target_x: float, side: int, need: float) -> bool:
	return absf(clampf(target_x + side * FOLLOW_GAP, follow_min_x, follow_max_x) - target_x) >= need


## 1 when [param node]'s body sprite faces right (the art's own direction), -1 when flipped left.
static func facing_of(node: Node2D) -> int:
	var actor: M0Actor = node as M0Actor
	return -1 if actor != null and actor.body_sprite != null and actor.body_sprite.flip_h else 1


func _approach(target_x: float, delta: float) -> float:
	var distance: float = target_x - position.x
	var speed: float = FOLLOW_SPEED * speed_scale
	return clampf(distance / delta, -speed, speed) if absf(distance) > 2.0 else 0.0


## True while this body walks across a shown keep_clear_of, close enough that the two drawn bodies overlap.
func passing() -> bool:
	return keep_clear_of != null and keep_clear_of.is_visible_in_tree() and absf(velocity.x) > 1.0 \
		and absf(position.x - keep_clear_of.position.x) < CLEAR_GAP


func _tint_pass(delta: float) -> void:
	if body_sprite == null or keep_clear_of == null:
		return
	var tint: Color = PASS_TINT if passing() else Color.WHITE
	body_sprite.self_modulate = body_sprite.self_modulate.lerp(tint, minf(PASS_TINT_RATE * delta, 1.0))


func _draw() -> void:
	if controlled:
		var ground_y: float = 22.0 if actor_id == &"wolf" else 34.0
		draw_line(Vector2(-20, ground_y), Vector2(20, ground_y), Color("#8be3ff80"), 2.0)
