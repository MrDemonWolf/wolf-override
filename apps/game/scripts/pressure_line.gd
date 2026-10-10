class_name PressureLine
extends RefCounted
## The Service Junction's coolant line, as pure logic: the breaker arms it, the gauge climbs over
## BUILD_SECONDS, and three real valve turns charge the sealed door before the relief vent lets go.
## States, in order: idle, building (gauge rising), charged (turn 3 landed), fuse (counting down
## to the blast), blown (the door went); tripped is the vent letting go first. Advanced with real
## delta so timing tests are frame-independent; a room sets [member paused] during a choice.

const BUILD_SECONDS: float = 6.0
const FUSE_SECONDS: float = 1.0
const TURNS_NEEDED: int = 3
## Seconds of held USE per valve turn.
const TURN_SECONDS: float = 0.4
## The door blast, as a range of the engineer's x. It is the only test of the blast's outcome:
## inside it when the fuse ends is a knockdown, outside it the door goes.
const BLAST_MIN_X: float = 360.0
const BLAST_MAX_X: float = 540.0
## The relief vent's floor grate, in pixels. The drawn grate and the vent's hurtbox are this span.
const VENT_GRATE_MIN_X: float = 264.0
const VENT_GRATE_MAX_X: float = 336.0
## The engineer counts as on the vent while any part of their body is over the grate, so the
## engineer's x range is the grate widened by half their body on each side (250..350).
const VENT_MIN_X: float = VENT_GRATE_MIN_X - M0State.HUMAN_HALF_WIDTH
const VENT_MAX_X: float = VENT_GRATE_MAX_X + M0State.HUMAN_HALF_WIDTH
## Summing many small deltas lands a hair under a round number; boundaries forgive that much.
const EPSILON: float = 0.00001

var state: StringName = &"idle"
## 0..1 pressure while building; back to 0 when the line trips or blows.
var gauge: float = 0.0
var turns: int = 0
## Seconds of held USE toward the next turn; springs back on release.
var progress: float = 0.0
var fuse_remaining: float = 0.0
var paused: bool = false


## USE at the breaker. Arms from idle, or re-arms after a trip; returns false otherwise.
func arm() -> bool:
	if state != &"idle" and state != &"tripped":
		return false
	state = &"building"
	gauge = 0.0
	turns = 0
	progress = 0.0
	return true


## Advances by [param delta] seconds and returns the event that landed this call, or empty:
## "tripped" (the vent let go), "fuse" (the fuse started) or "blown" (the fuse ended).
func advance(delta: float) -> StringName:
	if paused or delta <= 0.0:
		return &""
	match state:
		&"building":
			gauge = minf(gauge + delta / BUILD_SECONDS, 1.0)
			if gauge >= 1.0 - EPSILON:
				state = &"tripped"
				gauge = 0.0
				turns = 0
				progress = 0.0
				return &"tripped"
		&"charged":
			state = &"fuse"
			fuse_remaining = FUSE_SECONDS
			return &"fuse"
		&"fuse":
			fuse_remaining = maxf(fuse_remaining - delta, 0.0)
			if fuse_remaining <= 0.0:
				state = &"blown"
				gauge = 0.0
				return &"blown"
	return &""


## Held USE at the valve for [param held_delta] seconds; returns how many turns completed.
## Only a building line takes turns, and turns already made survive a release.
func crank(held_delta: float) -> int:
	if paused or state != &"building" or held_delta <= 0.0:
		return 0
	progress += held_delta
	var gained: int = 0
	while progress >= TURN_SECONDS - EPSILON and turns < TURNS_NEEDED:
		progress -= TURN_SECONDS
		turns += 1
		gained += 1
	if turns >= TURNS_NEEDED:
		state = &"charged"
		progress = 0.0
	return gained


## Letting go of USE drops the part turn in progress.
func release() -> void:
	progress = 0.0


## True while the fuse is lit and the door is about to go.
func is_dangerous() -> bool:
	return state == &"fuse" or state == &"charged"


static func is_in_blast(x: float) -> bool:
	return x >= BLAST_MIN_X and x <= BLAST_MAX_X


static func is_on_vent(x: float) -> bool:
	return x >= VENT_MIN_X and x <= VENT_MAX_X


## Back to rest. A [param spent] line is the one a blown door left behind: it reads blown, refuses
## arm() and crank(), and so can never hiss, vent or light a second fuse after a reload.
func reset(spent: bool = false) -> void:
	state = &"blown" if spent else &"idle"
	gauge = 0.0
	turns = 0
	progress = 0.0
	fuse_remaining = 0.0
	paused = false
