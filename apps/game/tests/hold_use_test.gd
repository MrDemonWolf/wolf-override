extends SceneTree

var failures: int = 0


func _initialize() -> void:
	var hold: HoldUse = HoldUse.new()
	_expect(hold.advance(0.5, true, &"") == 0 and hold.ticks == 0 and not hold.holding, "holding USE away from any station counts nothing")
	_expect(hold.advance(0.3, true, &"valve") == 0 and hold.holding and hold.ticks == 0, "0.3 s held is not yet a tick")
	_expect(hold.advance(0.15, true, &"valve") == 1 and hold.ticks == 1, "the first tick lands at 0.4 s")
	_expect(hold.advance(0.85, true, &"valve") == 2 and hold.ticks == 3, "a long frame can complete more than one tick")
	var partial: float = hold.progress
	_expect(partial > 0.0, "part of the next tick is in progress")
	_expect(hold.advance(0.016, false, &"valve") == 0 and hold.ticks == 3 and hold.progress == 0.0 and not hold.holding, "releasing keeps the ticks and drops the part tick")
	_expect(hold.advance(0.1, true, &"") == 0 and hold.ticks == 3, "stepping out of range keeps the ticks")
	_expect(hold.advance(0.4, true, &"valve") == 1 and hold.ticks == 4, "holding again continues from the kept ticks")
	_expect(hold.advance(0.4, true, &"bolt") == 1 and hold.ticks == 1 and hold.station == &"bolt", "a different station starts its own count")
	hold.reset()
	_expect(hold.ticks == 0 and hold.station.is_empty() and hold.progress == 0.0 and not hold.holding, "reset forgets everything")
	# Frame-independent: 1.3 s held in 60 Hz slices and in one slice give the same ticks.
	var sliced: HoldUse = HoldUse.new()
	for _frame: int in 78:
		sliced.advance(1.3 / 78.0, true, &"valve")
	var whole: HoldUse = HoldUse.new()
	whole.advance(1.3, true, &"valve")
	_expect(sliced.ticks == 3 and whole.ticks == 3, "1.3 s held is three ticks whether sliced or whole")
	if failures == 0:
		print("HoldUse checks passed")
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("HoldUse check failed: " + label)
