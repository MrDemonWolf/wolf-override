class_name SentryBrain
extends RefCounted
## The Service Junction's purge sentry, as pure logic. States: dormant (behind the sealed door,
## until the blast wakes it), patrol (bouncing PATROL_MIN_X..PATROL_MAX_X), lock (it has just
## seen the engineer, or a missed drop turned it: it stops and turns to them for LOCK_SECONDS before
## it moves), chase (running the engineer down in its lane), fixated (WOLF chose to draw it: it keeps
## its distance from him until he is past it, then parks BAIT_OFFSET short of him, on the mark) and
## down (the tank landed on it; nothing moves it again). A missed tank lying on the floor
## ([member obstacle]) stops it at its edge, and WOLF holding the far end of the lane ([member far_x])
## turns it short of him. Advanced with real
## delta so tests are frame-independent; the room sets [member paused] during a choice and never ticks
## it while the game is paused or during a knockdown.

## The rubble line the sentry never crosses; an engineer at or left of LANE_ENTRY_X is out of its lane.
const RUBBLE_X: float = 540.0
const LANE_ENTRY_X: float = RUBBLE_X + 5.0
## The TANK RELEASE alcove, exactly as JunctionRoom draws it: it starts at the rubble line, so there is
## no exposed strip between the two, and an engineer centred anywhere in it is out of the sentry's
## sight, though a sentry that is already chasing still runs them down at the release. It is wide
## enough for the release panel at its left end and the engineer standing beside it, facing it, with
## their whole drawn body inside the posts (JunctionRoom.ARM_X, Main's JUNCTION_STATIONS).
const COVER_MIN_X: float = LANE_ENTRY_X
const COVER_MAX_X: float = 626.0
## How far ahead it sees, in the direction it faces.
const SIGHT_RANGE: float = 180.0
## Half the sentry's body, as the tank's hit and WOLF's spacing use it.
const HALF_WIDTH: float = 26.0
## How far its drawn machine reaches from its origin on its longer side (Sentry.drawn_half_width,
## 31.6 px, rounded up), and so how far its drawn body reaches either way.
const DRAWN_HALF_WIDTH: float = 32.0
## Contact is the two drawn bodies touching: this machine's drawn half and the engineer's
## (M0Actor.HUMAN_REACH). A knockdown lands at this distance, before the drawings overlap.
const CONTACT_RANGE: float = DRAWN_HALF_WIDTH + M0Actor.HUMAN_REACH
## How far ahead of its origin the scanner's lens ends (Sentry.lens_rect): where its sight and beam start.
const LENS_AHEAD: float = 10.22
## The exit bolt's panel (JunctionRoom.BOLT_PANEL_X less BOLT_PANEL_HALF_WIDTH) is a solid box standing
## in the lane, as tall as the scanner: a sentry whose lens is left of this face sees no further right
## than it, and its beam stops there. Further right, at the far end of its patrol, the machine and its
## beam pass behind the box, which is drawn over them (JunctionRoom.PanelFront).
const PANEL_FACE_X: float = 767.6
## The patrol turns where its front edge meets an engineer standing at the alcove's right end, so a
## patrolling sentry never runs into someone hiding there (675; the patrol still crosses the mark).
const PATROL_MIN_X: float = COVER_MAX_X + CONTACT_RANGE
const PATROL_MAX_X: float = 840.0
const PATROL_SPEED: float = 140.0
const CHASE_SPEED: float = 230.0
## The closest it comes to the rubble while chasing an engineer in its lane (the alcove included): one
## pixel more than contact range past the lane edge, so it runs down anyone in the alcove while an
## engineer anywhere out of the lane is out of reach.
const CHASE_MIN_X: float = LANE_ENTRY_X + CONTACT_RANGE + 1.0
## Once the chased engineer is back over the rubble it waits here instead, at the alcove's mouth with
## its drawn body clear of the alcove, so a chase that loses them never leaves it parked inside.
const WATCH_X: float = COVER_MAX_X + DRAWN_HALF_WIDTH + 4.0
## The lock-on beat between seeing the engineer and chasing them: it holds still, facing them, for
## this long, so a chase never starts on the frame it first sees someone.
const LOCK_SECONDS: float = 0.5
## Seconds an engineer must stay back over the rubble before a chase gives up.
const LOSE_SECONDS: float = 2.5
## A fixated sentry parks this far short of the one drawing it, on the side toward the rubble. WOLF
## draws it from the far end of its lane, by the exit hatch (JunctionRoom.WOLF_BAIT_X, 904), so the
## parked sentry faces him with its back to the TANK RELEASE: the engineer at the release is behind it,
## never between the two. His drawn body (M0Actor.WOLF_REACH, 67) stays far outside the floor brackets
## and the tank's footprint, and inside the room's right edge (the view ends at x 960). Until he is
## past it, it keeps at least this far ahead of him as he comes down the lane and never closes on him,
## backing off as far as the end of its patrol (PATROL_MAX_X): he catches up with it there and bounds
## over it right of the hanging tank (JunctionRoom.wolf_leap_height), never under it.
const BAIT_OFFSET: float = 204.0
const EPSILON: float = 0.00001

var state: StringName = &"dormant"
var x: float = PATROL_MAX_X
## -1 faces left (toward the rubble), +1 right.
var facing: float = -1.0
## Seconds the chased engineer has been back over the rubble.
var lost_seconds: float = 0.0
## Seconds left in the lock-on beat.
var lock_remaining: float = 0.0
## True while the current lock-on or chase began with a missed drop rather than with it seeing the
## engineer; the knockdown card tells the two apart.
var turned_by_miss: bool = false
var paused: bool = false
## A missed tank lying on the floor or still on its way up, as the x span (from, to) of its footprint
## (DropArm.footprint), or Vector2.ZERO while the lane is clear. The room sets it every frame
## (DropArm.blocks_lane). The sentry stops at its edge on the side it came from and never drives into
## or through it; a patrol turns back there.
var obstacle: Vector2 = Vector2.ZERO
## The coolant tank's drawn span (from, to) while it stands at the height of its scanner (lying on the floor, or
## low in its fall or lift), or Vector2.ZERO: it sees no further than the tank's near face
## (sight_end_x). The room sets it every frame.
var sight_block: Vector2 = Vector2.ZERO
## Where WOLF actually is while he draws it (he is still crossing the lane to his spot), or a negative
## number: a fixated sentry keeps its eyes on him, not on the spot he is heading for, and keeps its
## distance from him until he is past it. The room sets it every frame.
var watch_x: float = -1.0
## The furthest right its body may go: PATROL_MAX_X, or short of WOLF while he holds the far end of the
## lane without drawing it (he broke off there after a miss), so its patrol turns before it reaches
## him. The room sets it every frame.
var far_x: float = PATROL_MAX_X


## True when the engineer is in the lane and out of the alcove, where the sentry can see them.
static func is_exposed(engineer_x: float) -> bool:
	return engineer_x > LANE_ENTRY_X and not (engineer_x >= COVER_MIN_X and engineer_x <= COVER_MAX_X)


## The blast woke it: from dormant it starts patrolling from where it stands.
func wake() -> bool:
	if state != &"dormant":
		return false
	state = &"patrol"
	return true


## A dropped tank missed: whatever it was doing, it turns on the engineer, locking on before it
## chases (a sentry already locking on or chasing carries on).
func alert() -> bool:
	if state == &"dormant" or state == &"down":
		return false
	if state == &"chase":
		lost_seconds = 0.0
	elif state != &"lock":
		_lock_on()
		turned_by_miss = true
	return true


## The tank landed on it.
func knock_down() -> bool:
	if state == &"down":
		return false
	state = &"down"
	return true


## Advances by [param delta] seconds and returns the state afterwards. [param engineer_exposed] is
## whether the engineer can be seen (is_exposed, as the room decides it); [param bait_x] is where
## WOLF is drawing it, or a negative number when he is not.
func tick(delta: float, engineer_x: float, engineer_exposed: bool, bait_x: float) -> StringName:
	if paused or delta <= 0.0 or state == &"dormant" or state == &"down":
		return state
	var from_x: float = x
	match state:
		&"patrol":
			if bait_x >= 0.0:
				state = &"fixated"
				_hold_on(bait_x, delta)
			else:
				_patrol(delta)
				if _sees(engineer_x, engineer_exposed):
					_lock_on()
		&"fixated":
			if bait_x < 0.0:
				state = &"patrol"
				_patrol(delta)
			elif engineer_exposed and absf(engineer_x - x) <= CONTACT_RANGE:
				# Walking into it breaks the hold, bait or not.
				_lock_on()
			else:
				_hold_on(bait_x, delta)
		&"lock":
			# Stopped, it turns to the engineer; time left over after the beat goes into the chase.
			if absf(engineer_x - x) > EPSILON:
				facing = signf(engineer_x - x)
			lock_remaining -= delta
			if lock_remaining <= EPSILON:
				var spare: float = -lock_remaining
				lock_remaining = 0.0
				state = &"chase"
				lost_seconds = 0.0
				if spare > EPSILON:
					return tick(spare, engineer_x, engineer_exposed, bait_x)
		&"chase":
			# It runs at the engineer and stops where the bodies touch, never into them; an engineer who
			# stepped closer than that is not backed away from (the touch is a knockdown).
			var side: float = signf(x - engineer_x) if absf(x - engineer_x) > EPSILON else -facing
			var goal_x: float = engineer_x + side * CONTACT_RANGE
			if (goal_x - x) * side > 0.0:
				goal_x = x
			_move_toward(goal_x, CHASE_SPEED, delta, CHASE_MIN_X if engineer_x > LANE_ENTRY_X else WATCH_X)
			if engineer_x <= LANE_ENTRY_X:
				lost_seconds += delta
				if lost_seconds >= LOSE_SECONDS - EPSILON:
					state = &"patrol"
					lost_seconds = 0.0
					turned_by_miss = false
			else:
				lost_seconds = 0.0
	_stop_at_obstacle(from_x)
	return state


## True when it is fixated on WOLF drawing it from [param bait_x] and has stopped where it holds,
## BAIT_OFFSET short of him (on the mark), with him past it: the moment the tank can be dropped on it.
## (Backing away from him down the lane it can cross the mark; that is not holding.)
func is_holding(bait_x: float) -> bool:
	return state == &"fixated" and not wolf_ahead() and absf(x - hold_x(bait_x)) <= EPSILON


## True while WOLF, drawing it, is still on the rubble side of it, not yet past it (watch_x).
func wolf_ahead() -> bool:
	return watch_x >= 0.0 and watch_x < x


## Where a sentry fixated on WOLF drawing it from [param bait_x] parks: BAIT_OFFSET short of him, on
## the side toward the rubble, inside its range.
static func hold_x(bait_x: float) -> float:
	return clampf(bait_x - BAIT_OFFSET, CHASE_MIN_X, PATROL_MAX_X)


## True when a chasing sentry has reached the engineer: the drawn bodies meet (CONTACT_RANGE). Through
## the lock-on beat it runs nobody down; the room keeps an engineer who walks into it at that range
## (Main._keep_off_sentry), so the two never overlap.
func touches(engineer_x: float) -> bool:
	return state == &"chase" and absf(engineer_x - x) <= CONTACT_RANGE + EPSILON


## True while its body stands in the lane as a solid machine the engineer cannot walk through (awake
## and not crushed).
func is_solid() -> bool:
	return state != &"dormant" and state != &"down"


## Back to the state a save describes: dormant behind the door, patrolling from the far end once the
## door is down, or lying at the floor mark once the tank has landed.
func reset(door_blown: bool, down: bool, down_x: float) -> void:
	state = &"down" if down else (&"patrol" if door_blown else &"dormant")
	x = down_x if down else PATROL_MAX_X
	facing = -1.0
	lost_seconds = 0.0
	lock_remaining = 0.0
	turned_by_miss = false
	paused = false
	obstacle = Vector2.ZERO
	sight_block = Vector2.ZERO
	watch_x = -1.0
	far_x = PATROL_MAX_X


func _lock_on() -> void:
	state = &"lock"
	lock_remaining = LOCK_SECONDS
	lost_seconds = 0.0
	turned_by_miss = false


func _patrol(delta: float) -> void:
	# Outside the patrol range (a chase parked it short of the rubble): face back into it and walk
	# there at patrol speed rather than jumping in.
	var far_end: float = _far_end()
	var below: bool = x < PATROL_MIN_X
	var above: bool = x > far_end
	if below:
		facing = 1.0
	elif above:
		facing = -1.0
	x += facing * PATROL_SPEED * delta
	if (below and x <= PATROL_MIN_X) or (above and x >= far_end):
		return
	# Bounce off either end, keeping any overshoot so sliced and whole deltas land the same.
	while x < PATROL_MIN_X or x > far_end:
		if x < PATROL_MIN_X:
			x = PATROL_MIN_X + (PATROL_MIN_X - x)
			facing = 1.0
		else:
			x = far_end - (x - far_end)
			facing = -1.0


## Fixated: keeps facing the one drawing it where they are (watch_x), or the spot they draw it from.
## While WOLF is still coming down the lane toward it, it never closes on him: it holds, or backs off to
## stay BAIT_OFFSET ahead of him, as far as the end of its patrol. Once he is past it, it parks
## BAIT_OFFSET short of his spot (on the side toward the rubble).
func _hold_on(bait_x: float, delta: float) -> void:
	var goal: float = hold_x(bait_x)
	if wolf_ahead():
		goal = clampf(maxf(x, watch_x + BAIT_OFFSET), CHASE_MIN_X, PATROL_MAX_X)
	_move_toward(goal, CHASE_SPEED, delta)
	var look: float = watch_x if watch_x >= 0.0 else bait_x
	if absf(look - x) > EPSILON:
		facing = signf(look - x)


func _move_toward(target_x: float, speed: float, delta: float, min_x: float = CHASE_MIN_X) -> void:
	var goal: float = clampf(target_x, min_x, maxf(min_x, _far_end()))
	var step: float = speed * delta
	if absf(goal - x) <= step:
		x = goal
	else:
		facing = signf(goal - x)
		x += facing * step


## The far turn of its patrol and the furthest right any move takes it: PATROL_MAX_X, or short of WOLF
## holding the far end (far_x).
func _far_end() -> float:
	return clampf(far_x, PATROL_MIN_X, PATROL_MAX_X)


## A move from [param from_x] that would take its body into the tank lying on the floor stops at the
## tank's edge on the side it came from (or where it stood, if a graze already left it touching); a
## patrol turns back there.
func _stop_at_obstacle(from_x: float) -> void:
	if obstacle == Vector2.ZERO:
		return
	var from_right: bool = from_x >= (obstacle.x + obstacle.y) * 0.5
	var limit: float = minf(from_x, obstacle.y + HALF_WIDTH) if from_right else maxf(from_x, obstacle.x - HALF_WIDTH)
	if (from_right and x >= limit - EPSILON) or (not from_right and x <= limit + EPSILON):
		return
	x = limit
	if state == &"patrol":
		facing = 1.0 if from_right else -1.0


func _sees(engineer_x: float, engineer_exposed: bool) -> bool:
	if not engineer_exposed:
		return false
	var ahead: float = (engineer_x - x) * facing
	return absf(engineer_x - x) <= CONTACT_RANGE or (ahead >= 0.0 and ahead <= absf(sight_end_x(x, facing, sight_block) - x))


## Where the sight of a sentry at [param x] facing [param facing] ends: SIGHT_RANGE ahead, cut short
## at the face of a solid thing standing between its lens and that range: the exit bolt's panel
## (PANEL_FACE_X) or the coolant tank down at its height ([param tank], its footprint, sight_block;
## Vector2.ZERO for none).
## Sentry.beam_tip_x draws the beam to the same point.
static func sight_end_x(x: float, facing: float, tank: Vector2 = Vector2.ZERO) -> float:
	var lens: float = x + signf(facing) * LENS_AHEAD
	var tip: float = x + signf(facing) * SIGHT_RANGE
	if facing > 0.0:
		if lens <= PANEL_FACE_X:
			tip = minf(tip, PANEL_FACE_X)
		if tank != Vector2.ZERO and lens <= tank.x:
			tip = minf(tip, tank.x)
	elif tank != Vector2.ZERO and lens >= tank.y:
		tip = maxf(tip, tank.y)
	return tip
