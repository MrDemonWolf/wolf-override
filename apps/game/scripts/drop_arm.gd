class_name DropArm
extends RefCounted
## The overhead arm over the sentry lane and its hanging coolant tank, as pure logic. States: hung
## (ready at the ARM PANEL), falling (FALL_SECONDS from the clamp letting go to the floor), landed
## (it came down on the sentry; final) and rewinding (it missed: the winch hauls it back up for
## REWIND_SECONDS while the dented tank vents a coolant cloud for CLOUD_SECONDS). The hit is decided
## where the tank lands, against the sentry's real position, so the drawn floor mark is the window.

const MARK_X: float = 700.0
## The tank lands on anything within this of the mark; the floor mark is drawn this wide.
const HIT_RANGE: float = 44.0
const FALL_SECONDS: float = 0.45
const REWIND_SECONDS: float = 6.0
const CLOUD_SECONDS: float = 3.0
## The coolant cloud's reach either side of the mark.
const CLOUD_HALF_WIDTH: float = 52.0
const EPSILON: float = 0.00001

var state: StringName = &"hung"
var fall_elapsed: float = 0.0
var rewind_remaining: float = 0.0
var cloud_remaining: float = 0.0
var paused: bool = false


static func is_hit(target_x: float) -> bool:
	return absf(target_x - MARK_X) <= HIT_RANGE + EPSILON


## USE at the ARM PANEL: lets the tank go. Refused unless it is hanging.
func drop() -> bool:
	if paused or state != &"hung":
		return false
	state = &"falling"
	fall_elapsed = 0.0
	return true


## Advances by [param delta] seconds and returns the event that landed this call, or empty:
## "hit" (it came down within HIT_RANGE of the mark on [param target_x]), "miss" (it hit the floor),
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
			return rewind_remaining / REWIND_SECONDS
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
