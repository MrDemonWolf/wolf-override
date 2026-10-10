class_name HoldUse
extends RefCounted
## Held USE at a station. Time accumulates only while the action is down inside the station's
## range; every TICK_SECONDS is one tick (a valve turn). Ticks already made survive a release, a
## pause (which releases the action) and stepping away; only part of a tick springs back.
## Pure logic, advanced with real delta, so timing tests are frame-independent.

const TICK_SECONDS: float = 0.4

## The station being held, or empty.
var station: StringName = &""
var ticks: int = 0
## Seconds toward the next tick.
var progress: float = 0.0
var holding: bool = false


## Advances by [param delta] seconds and returns how many ticks completed this call.
## [param in_station] is the station the engineer is in range of (empty when none).
func advance(delta: float, pressed: bool, in_station: StringName) -> int:
	if in_station != station and not in_station.is_empty():
		# A different station starts its own count.
		station = in_station
		ticks = 0
		progress = 0.0
	holding = pressed and not in_station.is_empty()
	if not holding:
		progress = 0.0
		return 0
	progress += delta
	var gained: int = 0
	while progress >= TICK_SECONDS:
		progress -= TICK_SECONDS
		ticks += 1
		gained += 1
	return gained


## Forgets every tick; a room calls this when the thing being cranked resets.
func reset() -> void:
	station = &""
	ticks = 0
	progress = 0.0
	holding = false
