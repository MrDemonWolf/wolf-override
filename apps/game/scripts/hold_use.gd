class_name HoldUse
extends RefCounted
## Held USE at a station. Time accumulates only while the action is down inside the station's
## range; every tick length is one tick (a valve turn, a notch of the bypass). Ticks already made
## survive a release, a pause (which releases the action) and stepping away; only part of a tick
## springs back. Pure logic, advanced with real delta, so timing tests are frame-independent.

## The default tick length: one junction valve turn (PressureLine.TURN_SECONDS).
const TICK_SECONDS: float = 0.4
## How far through its first tick a hold shows on the frame it starts, so a press is answered at
## once rather than when the first tick lands (FEEL-4): the wheel gives this much on the press frame.
const FIRST_FRAME_GIVE: float = 0.15

## The station being held, or empty.
var station: StringName = &""
var ticks: int = 0
## Seconds toward the next tick.
var progress: float = 0.0
var holding: bool = false
## True only on the frame a hold starts (the press frame, or the first frame back in reach while the
## action stays down): the station answers with its first click then.
var started: bool = false
## The tick length of the current hold, as the last advance() was given it.
var tick_seconds: float = TICK_SECONDS


## Advances by [param delta] seconds and returns how many ticks completed this call.
## [param in_station] is the station the engineer is in range of (empty when none); each tick takes
## [param seconds_per_tick].
func advance(delta: float, pressed: bool, in_station: StringName, seconds_per_tick: float = TICK_SECONDS) -> int:
	if in_station != station and not in_station.is_empty():
		# A different station starts its own count.
		station = in_station
		ticks = 0
		progress = 0.0
	tick_seconds = seconds_per_tick
	var was_holding: bool = holding
	holding = pressed and not in_station.is_empty()
	started = holding and not was_holding
	if not holding:
		progress = 0.0
		return 0
	progress += delta
	var gained: int = 0
	while progress >= tick_seconds:
		progress -= tick_seconds
		ticks += 1
		gained += 1
	return gained


## How far the station shows its next tick, 0..1: nothing while it is not held, and from the press
## frame on at least FIRST_FRAME_GIVE, growing to a whole tick as the time adds up.
func shown_fraction() -> float:
	return shown(progress / tick_seconds) if holding else 0.0


## The part of a tick a held station shows when [param done] (0..1) of it is held: never less than
## FIRST_FRAME_GIVE, so the press frame already moves the machine.
static func shown(done: float) -> float:
	return FIRST_FRAME_GIVE + (1.0 - FIRST_FRAME_GIVE) * clampf(done, 0.0, 1.0)


## Forgets every tick; a room calls this when the thing being cranked resets.
func reset() -> void:
	station = &""
	ticks = 0
	progress = 0.0
	holding = false
	started = false
