extends SceneTree

const State = preload("res://scripts/m0_state.gd")

var failures: int = 0


func _initialize() -> void:
	var state: M0State = State.new()
	_expect(state.memory.is_empty() and not state.door_open and state.active_actor == "human", "New Game state is clean")
	_expect(state.record_choice(State.PRESS), "records first choice")
	_expect(not state.record_choice(State.DISCLOSE), "rejects duplicate choice")
	_expect(state.memory.get("event_id") == State.EVENT_ID, "stores stable event ID")
	_expect(state.arm_breaker(), "arms breaker after conversation")
	_expect(state.activate_power("wolf") == "refused" and not state.door_open, "refusal leaves door closed")
	_expect(state.activate_power("human") == "fallback" and state.door_open, "human fallback opens door")
	_expect(state.activate_power("human") == "already_open", "door outcome cannot repeat")
	_expect(state.reach_checkpoint() and not state.reach_checkpoint(), "checkpoint records once")
	state.active_actor = "wolf"
	state.cycle_name()
	state.human_position = Vector2(605.0, 410.0)
	state.wolf_position = Vector2(876.0, 423.0)

	var decoded: M0State = State.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	_expect(decoded != null, "JSON state restores")
	if decoded != null:
		_expect(decoded.active_actor == "wolf" and decoded.name_index == 1, "actor and draft identity restore")
		_expect(decoded.human_position == state.human_position and decoded.wolf_position == state.wolf_position, "positions restore")
		_expect(decoded.door_open and decoded.route == "fallback" and decoded.breaker_armed, "puzzle restores")
		_expect(decoded.memory == state.memory, "actual choice restores without duplicate memory")
		_expect(decoded.checkpoint_callback().find(State.CHOICE_TEXT[State.PRESS]) >= 0, "checkpoint callback quotes actual choice")

	var path: String = "user://m0-state-test-%s.json" % OS.get_process_id()
	var fresh: M0State = State.new()
	_expect(fresh.checkpoint_callback().is_empty(), "fresh state has no callback")
	_expect(fresh.save_to_disk(path), "fresh state test file saves")
	_expect(State.load_from_disk(path) == null, "load rejects a file without a checkpoint")
	_expect(state.save_to_disk(path), "checkpoint file saves")
	var loaded: M0State = State.load_from_disk(path)
	_expect(loaded != null and loaded.to_dict() == state.to_dict(), "checkpoint file loads full state")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	var forged: Dictionary = state.to_dict()
	forged["memory"]["event_id"] = "future_event"
	_expect(State.from_dict(forged) == null, "rejects unknown memory")
	var cooperative: M0State = State.new()
	cooperative.record_choice(State.DISCLOSE)
	cooperative.arm_breaker()
	_expect(cooperative.activate_power("wolf") == "cooperate", "informed cooperation opens door")
	cooperative.reach_checkpoint()
	_expect(cooperative.checkpoint_callback().find(State.CHOICE_TEXT[State.DISCLOSE]) >= 0, "cooperative callback quotes actual choice")
	_expect(State.new().memory.is_empty(), "new session does not inherit memory")

	if failures == 0:
		print("M0 state checks passed")
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("M0 state check failed: " + label)
