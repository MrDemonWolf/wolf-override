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
	state.cycle_name()
	state.human_position = Vector2(605.0, 410.0)
	state.wolf_position = Vector2(876.0, 423.0)

	var decoded: M0State = State.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	_expect(decoded != null, "JSON state restores")
	if decoded != null:
		_expect(decoded.active_actor == "human" and decoded.name_index == 1, "engineer control and draft identity restore")
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
	var version_two_save: Dictionary = state.to_dict()
	version_two_save["version"] = 2
	for field in ["chapter_id", "purge_trace_preserved", "mirror_trace_preserved", "mirror_route", "chapter_complete"]:
		version_two_save.erase(field)
	var version_two_loaded: M0State = State.from_dict(version_two_save)
	_expect(version_two_loaded != null and version_two_loaded.chapter_id == "lockdown" and not version_two_loaded.purge_trace_preserved and not version_two_loaded.chapter_complete, "v2 checkpoint migrates to clean lockdown progress")
	var legacy_wolf_save: Dictionary = state.to_dict()
	legacy_wolf_save["version"] = 1
	legacy_wolf_save["active_actor"] = "wolf"
	var migrated: M0State = State.from_dict(legacy_wolf_save)
	_expect(migrated != null, "legacy WOLF-controlled checkpoint loads")
	if migrated != null:
		_expect(migrated.active_actor == "human" and migrated.human_position == Vector2(876.0, 410.0), "legacy checkpoint restores engineer at safe point without wolf-height floor overlap")
		_expect(migrated.wolf_position == Vector2(812.0, 423.0) and migrated.to_dict()["version"] == State.SAVE_VERSION, "legacy companion restores one follow gap left of engineer")
	var invalid_new_save: Dictionary = state.to_dict()
	invalid_new_save["active_actor"] = "wolf"
	_expect(State.from_dict(invalid_new_save) == null, "new saves cannot restore WOLF control")

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
	var records: M0State = State.new()
	_expect(not records.enter_records() and not records.preserve_purge_trace(), "records cannot begin before the first checkpoint")
	records.record_choice(State.DISCLOSE)
	records.arm_breaker()
	records.activate_power("wolf")
	records.reach_checkpoint()
	_expect(records.enter_records() and not records.enter_records() and records.chapter_id == "records", "checkpoint enters records once")
	_expect(records.human_position == Vector2(128.0, 410.0) and records.wolf_position == Vector2(64.0, 423.0), "records begins with both actors at its entrance")
	_expect(not records.preserve_mirror_trace("wolf") and not records.complete_chapter(), "mirror and completion wait for the purge trace")
	_expect(records.preserve_purge_trace() and not records.preserve_purge_trace(), "purge trace records once")
	_expect(not records.preserve_mirror_trace("unknown") and records.preserve_mirror_trace("manual") and not records.preserve_mirror_trace("wolf"), "mirror accepts one valid route")
	_expect(records.complete_chapter() and not records.complete_chapter(), "chapter completes only once after both traces")
	_expect(records.memory == cooperative.memory, "records progress leaves M0 memory unchanged")
	_expect(records.save_to_disk(path), "records checkpoint saves")
	var records_loaded: M0State = State.load_from_disk(path)
	_expect(records_loaded != null and records_loaded.to_dict() == records.to_dict(), "v3 records progress survives disk roundtrip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var impossible: Dictionary = records.to_dict()
	impossible["purge_trace_preserved"] = false
	_expect(State.from_dict(impossible) == null, "v3 rejects mirror without purge trace")
	impossible = records.to_dict()
	impossible["mirror_route"] = "unknown"
	_expect(State.from_dict(impossible) == null, "v3 rejects unknown mirror route")
	impossible = records.to_dict()
	impossible["checkpoint_reached"] = false
	_expect(State.from_dict(impossible) == null, "v3 rejects records before checkpoint")
	impossible = records.to_dict()
	impossible["chapter_id"] = "lockdown"
	_expect(State.from_dict(impossible) == null, "v3 rejects future progress in lockdown")
	impossible = records.to_dict()
	impossible["version"] = State.SAVE_VERSION + 1
	_expect(State.from_dict(impossible) == null, "rejects unknown future save version")

	if failures == 0:
		var below_floor: Dictionary = records.to_dict()
		below_floor["positions"]["human"][1] = 530.0
		_expect(State.from_dict(below_floor) == null, "rejects human position below the floor")
		below_floor = records.to_dict()
		below_floor["positions"]["wolf"][1] = 530.0
		_expect(State.from_dict(below_floor) == null, "rejects WOLF position below the floor")
	if failures == 0:
		print("M0 state checks passed")
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("M0 state check failed: " + label)
