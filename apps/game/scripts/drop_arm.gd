class_name DropArm
extends RefCounted
## The overhead arm over the sentry lane and its hanging coolant tank, as pure logic. States: hung
## (ready at the TANK RELEASE), falling (FALL_SECONDS from the clamp letting go to the floor), landed
## (it came down on the sentry; final) and rewinding (it missed: the winch snaps the tank back up to
## its hanging height in LIFT_SECONDS, then the clamp takes the rest of REWIND_SECONDS to latch, while
## the split line sprays a coolant cloud for CLOUD_SECONDS). The hit is decided where the tank lands,
## against the sentry's real position: the drawn floor brackets are the tank's footprint, and a hit is
## at least half of the sentry's body over them, so the tank always comes down on the machine where it
## stands and a graze at the edge of the brackets is a miss.

const MARK_X: float = 700.0
## Half the floor brackets, which are drawn this wide either side of the mark: the tank's own
## footprint (JunctionRoom.TANK_SIZE.x is 46.4 px), so what lands inside them is under the tank.
const HIT_RANGE: float = 24.0
## A sentry centred this close to the mark (its middle inside the brackets) has at least half of its
## body (SentryBrain.HALF_WIDTH either side) over them, under the tank.
const HIT_REACH: float = HIT_RANGE
const FALL_SECONDS: float = 0.45
const REWIND_SECONDS: float = 6.0
## After a miss the winch has the tank off the floor and back at its hanging height this fast, before
## the sentry it turned can reach the mark, so nothing ever drives through a tank on the floor.
const LIFT_SECONDS: float = 0.3
const CLOUD_SECONDS: float = 3.0
## The coolant cloud's reach either side of the mark.
const CLOUD_HALF_WIDTH: float = 52.0
const EPSILON: float = 0.00001

var state: StringName = &"hung"
var fall_elapsed: float = 0.0
var rewind_remaining: float = 0.0
var cloud_remaining: float = 0.0
var paused: bool = false


## True when a sentry centred at [param target_x] has at least half of its body over the floor brackets.
static func is_hit(target_x: float) -> bool:
	return absf(target_x - MARK_X) <= HIT_REACH + EPSILON


## USE at the TANK RELEASE: lets the tank go. Refused unless it is hanging.
func drop() -> bool:
	if paused or state != &"hung":
		return false
	state = &"falling"
	fall_elapsed = 0.0
	return true


## Advances by [param delta] seconds and returns the event that landed this call, or empty:
## "hit" (it came down with the sentry at [param target_x] over the brackets), "miss" (it hit the floor),
## or "rehung" (the rewind finished and it can drop again).
func advance(delta: float, target_x: float) -> StringName:
	if paused or delta <= 0.0:
		return &""
	match state:
		&"falling":
			fall_elapsed = minf(fall_elapsed + delta, FALL_SECONDS)
			if fall_elapsed >= FALL_SECONDS - EPSILON:
				if is_hit(target_x):
					state = &"landed"
					return &"hit"
				state = &"rewinding"
				rewind_remaining = REWIND_SECONDS
				cloud_remaining = CLOUD_SECONDS
				return &"miss"
		&"rewinding":
			cloud_remaining = maxf(cloud_remaining - delta, 0.0)
			rewind_remaining = maxf(rewind_remaining - delta, 0.0)
			if rewind_remaining <= EPSILON:
				state = &"hung"
				rewind_remaining = 0.0
				cloud_remaining = 0.0
				return &"rehung"
	return &""


## 0 hanging, 1 on the floor: how far down the tank is right now.
func drop_amount() -> float:
	match state:
		&"falling":
			var t: float = fall_elapsed / FALL_SECONDS
			# Gravity: slow off the clamp, fastest at the floor.
			return t * t
		&"landed":
			return 1.0
		&"rewinding":
			# Off the floor fast (easing out), then it hangs while the clamp latches.
			var lifted: float = clampf((REWIND_SECONDS - rewind_remaining) / LIFT_SECONDS, 0.0, 1.0)
			return (1.0 - lifted) * (1.0 - lifted)
	return 0.0


func cloud_active() -> bool:
	return cloud_remaining > 0.0


## True when any part of an engineer centred at [param x] is inside the cloud's hurtbox.
static func in_cloud(x: float) -> bool:
	return absf(x - MARK_X) <= CLOUD_HALF_WIDTH + M0State.HUMAN_HALF_WIDTH


## Back to the state a save describes: hanging, or already on the downed sentry.
func reset(landed: bool) -> void:
	state = &"landed" if landed else &"hung"
	fall_elapsed = 0.0
	rewind_remaining = 0.0
	cloud_remaining = 0.0
	paused = false
