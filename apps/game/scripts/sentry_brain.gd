class_name SentryBrain
extends RefCounted
## The Service Junction's purge sentry, as pure logic. States: dormant (behind the sealed door,
## until the blast wakes it), patrol (bouncing PATROL_MIN_X..PATROL_MAX_X), chase (it saw the
## engineer in its lane), fixated (WOLF chose to draw it; it parks just past him, on the mark) and
## down (the tank landed on it; nothing moves it again). Advanced with real delta so tests are frame-independent;
## the room sets [member paused] during a choice and never ticks it while the game is paused or
## during a knockdown.

## The rubble line the sentry never crosses; an engineer at or left of LANE_ENTRY_X is out of its lane.
const RUBBLE_X: float = 540.0
const LANE_ENTRY_X: float = RUBBLE_X + 5.0
## The ARM PANEL alcove: an engineer centred in it is out of the sentry's sight, though a sentry that
## is already chasing still runs them down there.
const COVER_MIN_X: float = 556.0
const COVER_MAX_X: float = 584.0
## How far ahead it sees, in the direction it faces.
const SIGHT_RANGE: float = 180.0
## Half the sentry's body. Bodies touching (this plus half the engineer) is contact.
const HALF_WIDTH: float = 26.0
const CONTACT_RANGE: float = HALF_WIDTH + M0State.HUMAN_HALF_WIDTH
## The patrol turns where its front edge meets an engineer standing at the alcove's right end, so a
## patrolling sentry never runs into someone hiding there (624; the patrol still crosses the mark).
const PATROL_MIN_X: float = COVER_MAX_X + CONTACT_RANGE
const PATROL_MAX_X: float = 840.0
const PATROL_SPEED: float = 140.0
const CHASE_SPEED: float = 230.0
## The closest it comes to the rubble while chasing: one pixel more than contact range past the lane
## edge, so an engineer anywhere out of the lane is out of reach.
const CHASE_MIN_X: float = LANE_ENTRY_X + CONTACT_RANGE + 1.0
## Seconds an engineer must stay back over the rubble before a chase gives up.
const LOSE_SECONDS: float = 2.5
## A fixated sentry parks this far past the one drawing it, on the far side from the rubble. WOLF comes
## from the rubble and stops short of the mark, so he never has to cross the machine. Their bodies
## clear each other (26 + 31 = 57) with room for a sentry that turns on the panel after a miss and
## gains 10 px/s on WOLF as he backs off to the rubble, and WOLF stays clear of the tank's footprint.
const BAIT_OFFSET: float = 64.0
const EPSILON: float = 0.00001

var state: StringName = &"dormant"
var x: float = PATROL_MAX_X
## -1 faces left (toward the rubble), +1 right.
var facing: float = -1.0
## Seconds the chased engineer has been back over the rubble.
var lost_seconds: float = 0.0
var paused: bool = false


## True when the engineer is in the lane and out of the alcove, where the sentry can see them.
static func is_exposed(engineer_x: float) -> bool:
	return engineer_x > LANE_ENTRY_X and not (engineer_x >= COVER_MIN_X and engineer_x <= COVER_MAX_X)


## The blast woke it: from dormant it starts patrolling from where it stands.
func wake() -> bool:
	if state != &"dormant":
		return false
	state = &"patrol"
	return true


## A dropped tank missed: whatever it was doing, it turns on the engineer.
func alert() -> bool:
	if state == &"dormant" or state == &"down":
		return false
	state = &"chase"
	lost_seconds = 0.0
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
	match state:
		&"patrol":
			if bait_x >= 0.0:
				state = &"fixated"
				_hold_on(bait_x, delta)
			else:
				_patrol(delta)
				if _sees(engineer_x, engineer_exposed):
					state = &"chase"
					lost_seconds = 0.0
		&"fixated":
			if bait_x < 0.0:
				state = &"patrol"
				_patrol(delta)
			elif engineer_exposed and absf(engineer_x - x) <= CONTACT_RANGE:
				# Walking into it breaks the hold, bait or not.
				state = &"chase"
				lost_seconds = 0.0
			else:
				_hold_on(bait_x, delta)
		&"chase":
			_move_toward(engineer_x, CHASE_SPEED, delta)
			if engineer_x <= LANE_ENTRY_X:
				lost_seconds += delta
				if lost_seconds >= LOSE_SECONDS - EPSILON:
					state = &"patrol"
					lost_seconds = 0.0
			else:
				lost_seconds = 0.0
	return state


## True when a chasing sentry has reached the engineer.
func touches(engineer_x: float) -> bool:
	return state == &"chase" and absf(engineer_x - x) <= CONTACT_RANGE


## Back to the state a save describes: dormant behind the door, patrolling from the far end once the
## door is down, or lying at the floor mark once the tank has landed.
func reset(door_blown: bool, down: bool, down_x: float) -> void:
	state = &"down" if down else (&"patrol" if door_blown else &"dormant")
	x = down_x if down else PATROL_MAX_X
	facing = -1.0
	lost_seconds = 0.0
	paused = false


func _patrol(delta: float) -> void:
	# Outside the patrol range (a chase parked it short of the rubble): face back into it and walk
	# there at patrol speed rather than jumping in.
	var below: bool = x < PATROL_MIN_X
	var above: bool = x > PATROL_MAX_X
	if below:
		facing = 1.0
	elif above:
		facing = -1.0
	x += facing * PATROL_SPEED * delta
	if (below and x <= PATROL_MIN_X) or (above and x >= PATROL_MAX_X):
		return
	# Bounce off either end, keeping any overshoot so sliced and whole deltas land the same.
	while x < PATROL_MIN_X or x > PATROL_MAX_X:
		if x < PATROL_MIN_X:
			x = PATROL_MIN_X + (PATROL_MIN_X - x)
			facing = 1.0
		else:
			x = PATROL_MAX_X - (x - PATROL_MAX_X)
			facing = -1.0


## Fixated: closes to BAIT_OFFSET past the one drawing it (on the side away from the rubble) and keeps
## facing them.
func _hold_on(bait_x: float, delta: float) -> void:
	_move_toward(bait_x + BAIT_OFFSET, CHASE_SPEED, delta)
	if absf(bait_x - x) > EPSILON:
		facing = signf(bait_x - x)


func _move_toward(target_x: float, speed: float, delta: float) -> void:
	var goal: float = clampf(target_x, CHASE_MIN_X, PATROL_MAX_X)
	var step: float = speed * delta
	if absf(goal - x) <= step:
		x = goal
	else:
		facing = signf(goal - x)
		x += facing * step


func _sees(engineer_x: float, engineer_exposed: bool) -> bool:
	if not engineer_exposed:
		return false
	var ahead: float = (engineer_x - x) * facing
	return absf(engineer_x - x) <= CONTACT_RANGE or (ahead >= 0.0 and ahead <= SIGHT_RANGE)
