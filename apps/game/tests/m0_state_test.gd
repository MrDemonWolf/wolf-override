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

	var legacy_wording: Dictionary = state.to_dict()
	legacy_wording["memory"]["selected_text"] = "Earlier wording of the same choice."
	var legacy_wording_loaded: M0State = State.from_dict(legacy_wording)
	_expect(legacy_wording_loaded != null and legacy_wording_loaded.checkpoint_callback().contains("Earlier wording of the same choice."), "older choice wording still loads and is quoted as saved")
	for bad_text: Variant in ["", "x".repeat(State.MAX_SELECTED_TEXT_LENGTH + 1), 7]:
		var bad_wording: Dictionary = state.to_dict()
		bad_wording["memory"]["selected_text"] = bad_text
		_expect(State.from_dict(bad_wording) == null, "rejects empty, oversized or non-text choice wording")

	var v3_fixture: Variant = JSON.parse_string("""{"version": 3, "identity": {"actor_id": "human", "name_index": 0}, "active_actor": "human",
		"positions": {"human": [128.0, 410.0], "wolf": [520.0, 423.0]},
		"memory": {"event_id": "relay_disagreement", "choice_id": "disclose_risk", "selected_text": "The relay may vent coolant. Your call.", "context": "breaker_relay_risk", "sequence": 1, "observed_by": ["human", "wolf"]},
		"puzzle": {"breaker_armed": true, "door_open": true, "route": "cooperate"}, "checkpoint_reached": true,
		"chapter_id": "records", "purge_trace_preserved": true, "mirror_trace_preserved": true, "mirror_route": "wolf", "chapter_complete": false}""")
	var v3_loaded: M0State = State.from_dict(v3_fixture)
	_expect(v3_loaded != null and v3_loaded.chapter_id == "records" and v3_loaded.purge_trace_preserved and v3_loaded.mirror_trace_preserved and v3_loaded.mirror_route == "wolf" and not v3_loaded.chapter_complete, "literal v3 records save keeps its chapter and both traces")

	var recovery_path: String = "user://m0-state-recovery-%s.json" % OS.get_process_id()
	_expect(records.save_to_disk(recovery_path), "recovery fixture saves")
	DirAccess.rename_absolute(ProjectSettings.globalize_path(recovery_path), ProjectSettings.globalize_path(recovery_path + ".tmp"))
	var recovered: M0State = State.load_from_disk(recovery_path)
	_expect(recovered != null and recovered.to_dict() == records.to_dict(), "surviving temporary save loads when the main file is missing")
	_expect(FileAccess.file_exists(recovery_path) and not FileAccess.file_exists(recovery_path + ".tmp"), "recovered temporary save is promoted into place")
	DirAccess.rename_absolute(ProjectSettings.globalize_path(recovery_path), ProjectSettings.globalize_path(recovery_path + ".tmp"))
	_write_text(recovery_path, "not json")
	recovered = State.load_from_disk(recovery_path)
	_expect(recovered != null and recovered.to_dict() == records.to_dict(), "surviving temporary save replaces an unreadable main file")
	for leftover: String in [recovery_path, recovery_path + ".tmp"]:
		if FileAccess.file_exists(leftover):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(leftover))

	var malformed_bodies: Dictionary = {
		"non-JSON": "WOLF//OVERRIDE save",
		"truncated JSON": JSON.stringify(records.to_dict()).left(40),
		"empty file": "",
		"JSON array root": "[1, 2, 3]",
	}
	var malformed_index: int = 0
	for label: String in malformed_bodies:
		var malformed_path: String = "user://m0-state-malformed-%s-%d.json" % [OS.get_process_id(), malformed_index]
		malformed_index += 1
		_write_text(malformed_path, malformed_bodies[label])
		_expect(State.load_from_disk(malformed_path) == null, "rejects a malformed save (%s)" % label)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(malformed_path))

	if failures == 0:
		var below_floor: Dictionary = records.to_dict()
		below_floor["positions"]["human"][1] = 530.0
		_expect(State.from_dict(below_floor) == null, "rejects human position below the floor")
		below_floor = records.to_dict()
		below_floor["positions"]["wolf"][1] = 530.0
		_expect(State.from_dict(below_floor) == null, "rejects WOLF position below the floor")
	# A blocked promotion must not lose the only readable checkpoint.
	var blocked_path: String = "user://m0-blocked-%s.json" % OS.get_process_id()
	var blocked_state: M0State = M0State.new()
	blocked_state.record_choice(M0State.DISCLOSE)
	blocked_state.arm_breaker()
	blocked_state.activate_power("wolf")
	blocked_state.reach_checkpoint()
	blocked_state.save_to_disk(blocked_path)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(blocked_path), ProjectSettings.globalize_path(blocked_path + ".tmp"))
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(blocked_path))
	var blocked_loaded: M0State = M0State.load_from_disk(blocked_path)
	_expect(blocked_loaded != null and blocked_loaded.checkpoint_reached and FileAccess.file_exists(blocked_path + ".tmp"), "a recovered checkpoint that cannot be promoted still loads and keeps its temporary copy")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_path + ".tmp"))
	if failures == 0:
		print("M0 state checks passed")
	quit(1 if failures > 0 else 0)


func _write_text(path: String, body: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_expect(false, "test file opens for writing: " + path)
		return
	file.store_string(body)
	file.close()


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("M0 state check failed: " + label)
