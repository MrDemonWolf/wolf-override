extends SceneTree

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const State = preload("res://scripts/m0_state.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_pressure_line()
	_check_save_format()
	await _check_scene()
	if failures == 0:
		print("Junction checks passed")
	quit(1 if failures > 0 else 0)


## PressureLine is pure logic: the same seconds give the same phases whether sliced or whole.
func _check_pressure_line() -> void:
	var line: PressureLine = PressureLine.new()
	_expect(line.state == &"idle" and line.crank(1.0) == 0 and line.turns == 0, "an idle line takes no turns")
	_expect(line.advance(2.0) == &"" and line.state == &"idle" and line.gauge == 0.0, "an idle line never builds pressure")
	_expect(line.arm() and line.state == &"building" and not line.arm(), "the breaker arms an idle line once")
	var tripped: StringName = &""
	for _frame: int in 360:
		var event: StringName = line.advance(PressureLine.BUILD_SECONDS / 360.0)
		if not event.is_empty():
			tripped = event
	_expect(tripped == &"tripped" and line.state == &"tripped" and line.gauge == 0.0 and line.turns == 0, "six seconds without cranks trips the vent and empties the gauge")
	_expect(line.crank(1.0) == 0 and line.advance(1.0) == &"" and line.state == &"tripped", "a tripped line waits for the breaker")
	_expect(line.arm() and line.state == &"building", "the breaker re-arms a tripped line")
	_expect(line.crank(0.3) == 0 and line.turns == 0 and line.progress > 0.0, "0.3 s held is not yet a turn")
	line.release()
	_expect(line.progress == 0.0 and line.turns == 0, "letting go drops the part turn")
	_expect(line.crank(0.45) == 1 and line.turns == 1 and line.state == &"building", "0.4 s held is the first turn")
	line.release()
	_expect(line.advance(0.5) == &"" and line.turns == 1 and line.gauge > 0.0, "a release between turns keeps the turn while the gauge keeps rising")
	_expect(line.crank(0.85) == 2 and line.turns == 3 and line.state == &"charged", "two more turns charge the seal")
	_expect(line.crank(1.0) == 0 and line.turns == 3, "a charged seal takes no more turns")
	_expect(line.advance(0.016) == &"fuse" and line.state == &"fuse" and is_equal_approx(line.fuse_remaining, PressureLine.FUSE_SECONDS), "the fuse lights on the next step")
	var blown: StringName = &""
	for _frame: int in 50:
		var event: StringName = line.advance(0.016)
		if not event.is_empty():
			blown = event
	_expect(blown == &"" and line.state == &"fuse" and line.fuse_remaining > 0.0, "0.8 s into the fuse the door still stands")
	for _frame: int in 20:
		var event: StringName = line.advance(0.016)
		if not event.is_empty():
			blown = event
	_expect(blown == &"blown" and line.state == &"blown" and line.gauge == 0.0, "the fuse ends at 1.0 s and the door goes")
	_expect(line.advance(1.0) == &"" and not line.arm(), "a blown line is finished")
	var whole: PressureLine = PressureLine.new()
	whole.arm()
	whole.crank(1.2)
	_expect(whole.turns == 3 and whole.state == &"charged", "1.2 s held in one slice is three turns")
	var paused: PressureLine = PressureLine.new()
	paused.arm()
	paused.paused = true
	_expect(paused.advance(10.0) == &"" and paused.gauge == 0.0 and paused.crank(1.0) == 0 and paused.turns == 0, "a paused line neither builds nor turns")
	paused.paused = false
	_expect(paused.crank(0.4) == 1, "unpausing resumes the same line")
	paused.reset()
	_expect(paused.state == &"idle" and paused.turns == 0 and paused.gauge == 0.0, "reset returns the line to idle")
	for x: float in [360.0, 450.0, 540.0]:
		_expect(PressureLine.is_in_blast(x), "%.0f is inside the door blast zone" % x)
	for x: float in [359.0, 541.0, 300.0, 700.0]:
		_expect(not PressureLine.is_in_blast(x), "%.0f is outside the door blast zone" % x)
	_expect(PressureLine.is_on_vent(250.0) and PressureLine.is_on_vent(350.0) and not PressureLine.is_on_vent(249.0) and not PressureLine.is_on_vent(351.0), "the relief vent covers 250..350")
	_expect(PressureLine.VENT_MIN_X == PressureLine.VENT_GRATE_MIN_X - M0State.HUMAN_HALF_WIDTH and PressureLine.VENT_MAX_X == PressureLine.VENT_GRATE_MAX_X + M0State.HUMAN_HALF_WIDTH, "the vent's x range is the grate widened by half the engineer's body")


## Save v4: junction progress in order, defaulting to nothing for v3 and older saves.
func _check_save_format() -> void:
	var records: M0State = _completed_records_state(State.DISCLOSE)
	_expect(not State.new().enter_junction() and not State.new().blow_door(), "the junction cannot begin from a new game")
	var incomplete: M0State = _completed_records_state(State.DISCLOSE)
	incomplete.chapter_complete = false
	_expect(not incomplete.enter_junction(), "the junction waits for the secured first copy")
	_expect(not records.blow_door(), "the door cannot blow before entering the junction")
	_expect(records.enter_junction() and not records.enter_junction() and records.chapter_id == "junction", "the Records exit enters the junction once")
	_expect(records.human_position == Vector2(120.0, 410.0) and records.wolf_position == Vector2(64.0, 423.0), "the junction begins with both actors at its entry hatch")
	_expect(not records.door_blown and not records.sentry_down and not records.junction_cleared, "entry sets no junction flags")
	var entry: Dictionary = records.to_dict()
	_expect(entry["version"] == 4 and entry["chapter_id"] == "junction", "junction saves are version 4")
	var entry_loaded: M0State = State.from_dict(JSON.parse_string(JSON.stringify(entry)))
	_expect(entry_loaded != null and entry_loaded.to_dict() == entry, "a junction entry save round-trips through JSON")
	_expect(records.blow_door() and not records.blow_door() and records.door_blown, "the door blows once")
	var blown_loaded: M0State = State.from_dict(records.to_dict())
	_expect(blown_loaded != null and blown_loaded.door_blown and blown_loaded.chapter_complete and blown_loaded.memory == records.memory, "a blown-door save keeps the flag, the Records result and the relay memory")
	var bad: Dictionary = records.to_dict()
	bad["chapter_complete"] = false
	_expect(State.from_dict(bad) == null, "v4 rejects the junction without the secured first copy")
	bad = records.to_dict()
	bad["sentry_down"] = true
	bad["door_blown"] = false
	_expect(State.from_dict(bad) == null, "v4 rejects the sentry down before the door is blown")
	bad = records.to_dict()
	bad["junction_cleared"] = true
	_expect(State.from_dict(bad) == null, "v4 rejects a cleared junction before the sentry is down")
	bad = records.to_dict()
	bad["sentry_down"] = true
	bad["junction_cleared"] = true
	_expect(State.from_dict(bad) != null, "v4 accepts the full junction order")
	bad = records.to_dict()
	bad["chapter_id"] = "records"
	_expect(State.from_dict(bad) == null, "v4 rejects junction flags outside the junction")
	bad = records.to_dict()
	bad["door_blown"] = "yes"
	_expect(State.from_dict(bad) == null, "v4 rejects a non-boolean junction flag")
	bad = records.to_dict()
	bad["version"] = 3
	_expect(State.from_dict(bad) == null, "a v3 save cannot claim the junction")
	# Before the blast nobody can stand past the sealed door's face.
	var sealed: Dictionary = entry.duplicate(true)
	sealed["positions"]["human"] = [438.0, 410.0]
	sealed["positions"]["wolf"] = [421.0, 423.0]
	_expect(State.from_dict(sealed) != null, "v4 accepts both actors pressed against the sealed door")
	sealed["positions"]["human"] = [439.0, 410.0]
	_expect(State.from_dict(sealed) == null, "v4 rejects an engineer whose body would be inside the sealed door")
	sealed["positions"]["human"] = [600.0, 410.0]
	_expect(State.from_dict(sealed) == null, "v4 rejects an engineer past the sealed door")
	sealed["positions"]["human"] = [120.0, 410.0]
	sealed["positions"]["wolf"] = [700.0, 423.0]
	_expect(State.from_dict(sealed) == null, "v4 rejects WOLF past the sealed door")
	var open_lane: Dictionary = records.to_dict()
	open_lane["positions"]["human"] = [600.0, 410.0]
	open_lane["positions"]["wolf"] = [500.0, 423.0]
	_expect(State.from_dict(open_lane) != null, "once the door is blown both actors may stand past it")
	var v3_fixture: Variant = JSON.parse_string("""{"version": 3, "identity": {"actor_id": "human", "name_index": 0}, "active_actor": "human",
		"positions": {"human": [830.0, 410.0], "wolf": [766.0, 423.0]},
		"memory": {"event_id": "relay_disagreement", "choice_id": "press_without_warning", "selected_text": "Go now. We can talk after.", "context": "breaker_relay_risk", "sequence": 1, "observed_by": ["human", "wolf"]},
		"puzzle": {"breaker_armed": true, "door_open": true, "route": "fallback"}, "checkpoint_reached": true,
		"chapter_id": "records", "purge_trace_preserved": true, "mirror_trace_preserved": true, "mirror_route": "manual", "chapter_complete": true}""")
	var v3_loaded: M0State = State.from_dict(v3_fixture)
	_expect(v3_loaded != null and v3_loaded.chapter_id == "records" and v3_loaded.chapter_complete and not v3_loaded.door_blown and not v3_loaded.sentry_down and not v3_loaded.junction_cleared, "a literal v3 save still loads with the junction untouched")
	_expect(v3_loaded != null and v3_loaded.enter_junction() and v3_loaded.to_dict()["version"] == 4, "a loaded v3 save can enter the junction and saves as v4")


## The scene: the Records exit leads in, WOLF scouts, the line charges by held USE, the blast
## zone knocks down to autosave A, and a clean blast opens the door and writes autosave B.
func _check_scene() -> void:
	var path: String = "user://junction-test-%s.json" % OS.get_process_id()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	game.set("settings_path", "%s-settings.cfg" % path)
	root.add_child(game)
	await process_frame
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	var camera: Camera2D = game.get_node("IntroCamera") as Camera2D
	var impact: Impact = game.get("impact") as Impact
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var line: PressureLine = game.get("pressure_line") as PressureLine
	var corridor_door: CollisionShape2D = game.get_node("Door/CollisionShape2D") as CollisionShape2D
	var touch_use: Button = game.get_node("CanvasLayer/TouchControls/Use") as Button
	if not _require(room != null and line != null and not room.visible and room.door_shape.disabled, "Main builds a hidden junction with its door body off"):
		return
	# The save check, the vent range and the door face share these widths with the scene.
	_expect(is_equal_approx(((game.get_node("Human/CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size.x * 0.5, M0State.HUMAN_HALF_WIDTH), "M0State.HUMAN_HALF_WIDTH matches the engineer's body")
	_expect(is_equal_approx(((game.get_node("Wolf/CollisionShape2D") as CollisionShape2D).shape as RectangleShape2D).size.x * 0.5, M0State.WOLF_HALF_WIDTH), "M0State.WOLF_HALF_WIDTH matches WOLF's body")
	_expect(is_equal_approx(room.door_body.position.x - (room.door_shape.shape as RectangleShape2D).size.x * 0.5, M0State.JUNCTION_DOOR_LEFT_X), "the junction door's face is M0State.JUNCTION_DOOR_LEFT_X")
	var vent_box: Rect2 = Rect2(room.vent_hazard.position - (room.vent_hazard.get_child(0) as CollisionShape2D).shape.size * 0.5, (room.vent_hazard.get_child(0) as CollisionShape2D).shape.size)
	_expect(is_equal_approx(vent_box.position.x, PressureLine.VENT_GRATE_MIN_X) and is_equal_approx(vent_box.end.x, PressureLine.VENT_GRATE_MAX_X), "the vent hurtbox is exactly the drawn grate")
	game.call("_new_game")
	game.call("_finish_intro")
	var state: M0State = _completed_records_state(State.DISCLOSE)
	game.set("state", state)
	game.call("_sync_scene")
	game.call("_start_gameplay_camera")
	await physics_frame
	_expect(not room.visible and room.door_shape.disabled and (game.get("records_room") as RecordsRoom).visible, "a completed Records save shows Records, not the junction")
	human.position.x = 700.0
	_expect(str(game.call("_context_hint")).contains("Head right"), "the secured exit points right from across the room")
	human.position.x = 830.0
	_expect(str(game.call("_context_hint")).contains("follow the service line"), "the secured exit offers the service line")
	await _tap(&"interact")
	if not _require(state.chapter_id == "junction" and not state.door_blown, "USE at the secured exit enters the junction"):
		return
	_expect(room.visible and not (game.get("records_room") as RecordsRoom).visible and not (game.get_node("CorridorDepth") as Node2D).visible, "only the junction is visible after entry")
	_expect(human.position == Vector2(120.0, 410.0) and human.controlled and not wolf.controlled, "the engineer stands at the entry hatch with controls")
	_expect(is_equal_approx(camera.get_screen_center_position().x, camera.position.x), "entering the junction cuts the camera to the engineer instead of panning across")
	var autosave_a: M0State = State.load_from_disk(path)
	_expect(autosave_a != null and autosave_a.chapter_id == "junction" and not autosave_a.door_blown and autosave_a.memory == state.memory, "autosave A is written on entry with the relay memory")
	var a_bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	_expect(game.call("_objective") == "CLEAR THE LINE" and (game.get_node("CanvasLayer/TopBar/HUD") as Label).text.contains("SERVICE JUNCTION"), "entry shows the junction card and first objective")
	_expect(game.get("wolf_scouting") and wolf.autonomous_target_x == JunctionRoom.WOLF_SEAM_X, "WOLF runs ahead to the door seam on his own")
	_expect(await _wait_until(func() -> bool: return not game.get("wolf_scouting"), 200), "WOLF reaches the seam and reads it")
	_expect(absf(wolf.position.x - JunctionRoom.WOLF_SEAM_X) <= 6.0 and wolf.follow_target == human and str(game.get("status_line")).contains("It's live"), "after the read WOLF returns to following and says what he found")
	await physics_frame
	_expect(await _wait_until(func() -> bool: return not room.door_shape.disabled, 5), "the junction door body is live in its room")
	# The sealed door physically blocks the engineer.
	_expect(await _walk_to(human, 420.0), "the engineer walks to the valve")
	Input.action_press(&"move_right")
	for _frame: int in 120:
		await physics_frame
	Input.action_release(&"move_right")
	_expect(human.position.x < 460.0, "the sealed door blocks the way right")
	_expect(str(game.call("_context_hint")).contains("valve is dead"), "the valve points back at the breaker before the line is armed")
	await _tap(&"interact")
	_expect(line.state == &"idle" and str(game.get("status_line")).contains("Arm the overload breaker"), "USE at a dead valve explains the breaker")
	_expect(await _walk_to(human, 200.0), "the engineer walks back to the breaker")
	await _check_vent_edges(game, human, wolf, room, line, a_bytes)
	_expect(await _walk_to(human, 200.0), "the engineer is back at the breaker after the vent checks")
	_expect(str(game.call("_context_hint")).contains("arm the overload breaker"), "the breaker offers USE")
	await _tap(&"interact")
	if not _require(line.state == &"building" and game.call("_objective") == "CHARGE THE SEAL", "USE at the breaker arms the line"):
		return
	_expect(room.vent_steam.emitting and room.breaker_label.text == "BREAKER LIVE", "an armed line steams at the vent and lights the breaker")
	await _tap(&"pause_game")
	_expect(paused, "pause works in the junction")
	var gauge_before: float = line.gauge
	await create_timer(0.15, true).timeout
	_expect(line.gauge == gauge_before, "the line does not build while paused")
	(game.get_node("CanvasLayer/PauseOverlay") as PauseOverlay).resume_requested.emit()
	_expect(not paused and line.state == &"building", "resume keeps the armed line")
	# Hold USE at the valve: turns persist across a release.
	_expect(await _walk_to(human, 420.0), "the engineer reaches the valve while the line builds")
	_expect(str(game.call("_context_hint")).begins_with("HOLD E:"), "the live valve asks for a held USE")
	game.set("touch_enabled", true)
	game.call("_refresh_ui")
	_expect(touch_use.text == "CRANK", "touch relabels USE to CRANK at the live valve")
	game.set("touch_enabled", false)
	game.call("_refresh_ui")
	Input.action_press(&"interact")
	var first_turn: bool = await _wait_until(func() -> bool: return line.turns >= 1, 60)
	Input.action_release(&"interact")
	if not _require(first_turn and line.turns == 1 and line.state == &"building", "0.4 s of held USE is one real turn"):
		return
	for _frame: int in 12:
		await physics_frame
	_expect(line.turns == 1 and room.turns == 1 and line.progress == 0.0 and room.valve_label.text == "VALVE  1 / %d" % PressureLine.TURNS_NEEDED, "releasing keeps the turn and the room and its VALVE label show it")
	Input.action_press(&"interact")
	var charged: bool = await _wait_until(func() -> bool: return line.turns >= 3, 90)
	Input.action_release(&"interact")
	if not _require(charged and line.turns == 3 and (line.state == &"charged" or line.state == &"fuse"), "holding again completes the three turns"):
		return
	_expect(game.call("_objective") == "CLEAR THE DOOR" and str(game.get("status_line")).begins_with("SEAL CHARGED"), "turn three lights the fuse and says to clear the door")
	# Stand just inside the blast zone's left edge: the fuse ends on a knockdown that reloads autosave A.
	human.position.x = PressureLine.BLAST_MIN_X + 2.0
	_expect(await _wait_until(func() -> bool: return game.get("fail_active"), 90), "the blast knocks down an engineer still in front of the door")
	_expect(not state.door_blown and room.door_shape.disabled == false and room.breaker_label.text != "BREAKER SPENT", "a knockdown blast never blows the door")
	_expect(not state.door_blown and FileAccess.get_file_as_bytes(path) == a_bytes, "a knockdown blast saves nothing and leaves the door sealed")
	_expect(str(game.get("status_line")).begins_with("The door blew"), "the status line names the blast as the cause")
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "the knockdown hands back")
	state = game.get("state") as M0State
	_expect(state.to_dict() == autosave_a.to_dict() and human.position == state.human_position and human.controlled, "the engineer is back at autosave A with controls")
	_expect(line.state == &"idle" and room.turns == 0 and not room.vent_hazard.armed, "the restore resets the line, the wheel and the vent")
	_expect(await _wait_until(func() -> bool: return not room.door_shape.disabled and room.door_art.visible and not room.door_blown_art.visible, 5), "the door stands sealed again after the restore")
	_expect(state.memory.get("choice_id") == State.DISCLOSE and state.chapter_complete, "memory and the Records result survive the knockdown")
	_expect(await _wait_until(func() -> bool: return Engine.time_scale == 1.0 and camera.offset == Vector2.ZERO and (game.get_node("CanvasLayer/IntroFade") as ColorRect).color.a == 0.0, 90), "time scale, camera and fade are at rest after the restore")
	# A clean run: arm, crank, clear the zone, and the door goes.
	_expect(await _walk_to(human, 200.0), "the engineer returns to the breaker")
	await _tap(&"interact")
	if not _require(line.state == &"building", "the breaker arms again after the knockdown"):
		return
	_expect(await _walk_to(human, 420.0), "the engineer reaches the valve again")
	Input.action_press(&"interact")
	charged = await _wait_until(func() -> bool: return line.turns >= 3, 120)
	Input.action_release(&"interact")
	if not _require(charged, "the seal charges again"):
		return
	# Just left of the zone, where the engineer's body still reaches past x 360: the one blast test
	# says outside, so the door blows, nobody is knocked down and autosave B is written.
	human.position.x = PressureLine.BLAST_MIN_X - 8.0
	_expect(await _wait_until(func() -> bool: return state.door_blown, 90), "the fuse ends and the door blows")
	_expect(game.call("_objective") == "DROP THE TANK" and room.door_label.text == "DOOR DOWN" and room.blast_sparks.emitting, "the blast is a real state change with sparks and the next objective")
	_expect(room.breaker_label.text == "BREAKER SPENT" and room.valve_label.text == "VALVE SPENT", "the blast spends the breaker and the valve")
	var knocked: bool = false
	for _frame: int in 30:
		await physics_frame
		knocked = knocked or game.get("fail_active")
	_expect(not knocked and human.controlled and str(game.get("status_line")).begins_with("The seal goes"), "clear of the zone the blast is not a knockdown, even at its edge")
	var autosave_b: M0State = State.load_from_disk(path)
	_expect(autosave_b != null and autosave_b.door_blown and autosave_b.chapter_id == "junction", "autosave B records the blown door")
	_expect(wolf.autonomous_target_x == JunctionRoom.WOLF_RUBBLE_X, "WOLF holds at the rubble and will not cross")
	_expect(await _wait_until(func() -> bool: return room.door_shape.disabled, 5), "the door body is gone")
	_expect(await _wait_until(func() -> bool: return Engine.time_scale == 1.0 and camera.offset == Vector2.ZERO, 90), "time scale and camera settle after the boom")
	# Through where the door stood, up to just short of the rubble line (the lane beyond is sentry_test's).
	_expect(await _walk_to(human, JunctionRoom.CHOICE_X - 16.0), "the engineer can walk through where the door stood")
	_expect(wolf.position.x <= JunctionRoom.WOLF_RUBBLE_X + 12.0, "WOLF stays on the near side of the rubble")
	_expect(room.z_index + room.door_visual.z_index < wolf.z_index and room.z_index + room.door_visual.z_index < human.z_index, "the torn door frame draws behind WOLF and the engineer")
	await _tap(&"interact")
	_expect(str(game.get("status_line")).contains("ARM PANEL") and not game.get("waiting_for_choice"), "short of the rubble USE points at the arm panel and nothing is asked yet")
	# A blast with the engineer already past the fuse needs no second save; Continue restores B.
	game.call("_load_game")
	state = game.get("state") as M0State
	_expect(state.door_blown and room.visible and room.door_shape.disabled and not room.door_art.visible and room.door_blown_art.visible and str(game.get("status_line")).contains("door is down"), "Continue restores the blown door and says so")
	_expect(room.breaker_label.text == "BREAKER SPENT" and room.valve_label.text == "VALVE SPENT", "Continue shows the same spent breaker and valve as the blast did")
	# The spent line stays spent after Continue: the breaker will not arm, the valve takes no turns
	# and a stray blast call does nothing.
	var b_bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	_expect(line.state == &"blown", "Continue from autosave B leaves the line spent, not idle")
	_expect(await _walk_to(human, JunctionRoom.BREAKER_X), "the engineer walks back to the spent breaker")
	await _tap(&"interact")
	_expect(line.state == &"blown" and str(game.get("status_line")).contains("breaker is spent") and not room.vent_steam.emitting, "USE at the spent breaker after Continue arms nothing")
	for _frame: int in 30:
		await physics_frame
	_expect(line.state == &"blown" and line.gauge == 0.0 and not game.get("fail_active"), "no gauge builds and no vent trips after the door is down")
	_expect(await _walk_to(human, JunctionRoom.VALVE_X), "the engineer walks to the spent valve")
	_expect(game.call("_hold_station") == &"" and not str(game.call("_context_hint")).contains("valve is dead"), "the spent valve offers no crank and never reads as dead")
	await _tap(&"interact")
	_expect(str(game.get("status_line")).contains("valve is spent") and line.turns == 0, "USE at the spent valve says so and takes no turns")
	game.call("_door_blast")
	_expect(not game.get("fail_active") and FileAccess.get_file_as_bytes(path) == b_bytes and Engine.time_scale == 1.0, "a blast with the door already down is no knockdown, no save and no hit-stop")
	# A failed autosave never costs more than the current beat: with an older autosave A on disk and
	# autosave B unwritten, a knockdown restores B from memory, and the next USE writes it.
	var disk: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	disk.store_buffer(a_bytes)
	disk.close()
	game.set("save_path", "user://missing-save-folder-%s/save.json" % OS.get_process_id())
	game.call("_save_progress")
	game.set("save_path", path)
	_expect(game.get("save_pending") and str(game.get("save_error")).begins_with("Save failed"), "a failed autosave is flagged and shown")
	game.call("_fail_beat", "Test knockdown.")
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "the knockdown after a failed save hands back")
	state = game.get("state") as M0State
	_expect(state.door_blown and str(game.get("status_line")).ends_with("Back at the start of this beat."), "the knockdown restores the unwritten beat, not the older autosave on disk")
	await _tap(&"interact")
	var retried: M0State = State.load_from_disk(path)
	_expect(not game.get("save_pending") and retried != null and retried.door_blown, "the next USE retries the save and writes the beat")
	# An unreadable file mid-room falls back to this beat too, never to an older corridor snapshot.
	disk = FileAccess.open(path, FileAccess.WRITE)
	disk.store_string("not a save")
	disk.close()
	game.call("_fail_beat", "Test knockdown.")
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "the knockdown with an unreadable save hands back")
	state = game.get("state") as M0State
	_expect(state.chapter_id == "junction" and state.door_blown, "with the save unreadable the knockdown keeps the current beat")
	game.call("_save_progress")
	# Reduced Motion holds the charged seam steady instead of strobing.
	var settings: GameSettings = game.get("settings_menu") as GameSettings
	settings.reduced_motion_changed.emit(true)
	_expect(room.reduce_motion, "the Reduced Motion toggle reaches the junction")
	settings.reduced_motion_changed.emit(false)
	_expect(not room.reduce_motion, "switching Reduced Motion off reaches the junction too")
	# A spare room, outside Main's per-frame sync, shows the seam on its own.
	var spare: JunctionRoom = JunctionRoom.new()
	spare.reduce_motion = true
	root.add_child(spare)
	spare.line_state = &"charged"
	spare.refresh_state()
	var steady: Color = spare.seam_glow.modulate
	for _frame: int in 12:
		await process_frame
	_expect(spare.seam_glow.modulate == steady and steady.a > 0.5, "with Reduced Motion the charged seam glows without strobing")
	spare.reduce_motion = false
	var strobed: bool = false
	for _frame: int in 12:
		await process_frame
		strobed = strobed or spare.seam_glow.modulate != steady
	_expect(strobed, "without Reduced Motion the charged seam strobes")
	spare.queue_free()
	_expect(corridor_door.disabled, "the corridor door stays open in the junction")
	# Return to Title and New Game leave the junction's collision and loops off.
	game.call("_pause_game")
	(game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton") as Button).pressed.emit()
	game.call("_new_game")
	game.call("_finish_intro")
	await physics_frame
	await physics_frame
	_expect(not room.visible and room.door_shape.disabled and (game.get("state") as M0State).chapter_id == "lockdown", "New Game hides the junction and disables its door body")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game.queue_free()
	# The mixer releases a stopped clip a few steps later; give it that time before quitting.
	await create_timer(0.1).timeout
	_expect(Engine.time_scale == 1.0, "freeing the game leaves time_scale at 1.0")


## The vent's knockdown span is the grate plus half the engineer's body, and the hint agrees: just
## off it the trip costs only the attempt, on its edge it is a knockdown back to autosave A.
func _check_vent_edges(game: Node2D, human: M0Actor, wolf: M0Actor, room: JunctionRoom, line: PressureLine, a_bytes: PackedByteArray) -> void:
	await _tap(&"interact")
	if not _require(line.state == &"building", "the breaker arms the line for the vent checks"):
		return
	human.position.x = PressureLine.VENT_MIN_X - 8.0
	await physics_frame
	await physics_frame
	_expect(not str(game.call("_context_hint")).begins_with("Relief vent"), "just left of the vent span there is no vent warning")
	line.gauge = 0.999
	_expect(await _wait_until(func() -> bool: return line.state == &"tripped", 10), "the gauge peaks and the vent lets go")
	for _frame: int in 4:
		await physics_frame
	_expect(not game.get("fail_active") and str(game.get("status_line")).begins_with("The relief vent lets go"), "just off the grate a vent trip is not a knockdown")
	human.position.x = JunctionRoom.BREAKER_X
	await _tap(&"interact")
	_expect(line.state == &"building", "the breaker re-arms after the trip")
	human.position.x = PressureLine.VENT_MIN_X + 6.0
	await physics_frame
	await physics_frame
	_expect(str(game.call("_context_hint")).begins_with("Relief vent. Move off it"), "with a foot on the grate the hint warns about the vent")
	line.gauge = 0.999
	_expect(await _wait_until(func() -> bool: return game.get("fail_active"), 10), "with a foot on the grate the vent trip is a knockdown")
	_expect(str(game.get("status_line")).begins_with("The relief vent let go under you"), "the status line names the vent")
	_expect(human.z_index > wolf.z_index and room.vent_puff.color.a <= 0.35, "the knocked-down engineer draws above WOLF and the steam burst is translucent")
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "the vent knockdown hands back")
	_expect(FileAccess.get_file_as_bytes(game.get("save_path")) == a_bytes and human.position == Vector2(120.0, 410.0) and human.z_index == wolf.z_index, "the vent knockdown restores autosave A and the usual draw order")
	_expect(str(game.get("status_line")).ends_with("Back at the last autosave."), "the restore line names the autosave it came from")


func _completed_records_state(choice_id: String) -> M0State:
	var state: M0State = State.new()
	state.record_choice(choice_id)
	state.arm_breaker()
	state.activate_power("wolf" if choice_id == State.DISCLOSE else "human")
	state.reach_checkpoint()
	state.enter_records()
	state.preserve_purge_trace()
	state.preserve_mirror_trace("wolf" if choice_id == State.DISCLOSE else "manual")
	state.complete_chapter()
	state.human_position = Vector2(830.0, 410.0)
	state.wolf_position = Vector2(766.0, 423.0)
	return state


func _tap(action: StringName) -> void:
	await process_frame
	if action == &"pause_game":
		# Pause is event-driven, so send a real input event.
		Input.parse_input_event(_action_event(action, true))
		await process_frame
		Input.parse_input_event(_action_event(action, false))
		return
	Input.action_press(action)
	await process_frame
	Input.action_release(action)


func _action_event(action: StringName, pressed: bool) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


func _wait_until(condition: Callable, frames: int) -> bool:
	for _frame: int in range(frames):
		await physics_frame
		if condition.call():
			return true
	return false


func _walk_to(actor: M0Actor, target_x: float) -> bool:
	var action: StringName = &"move_right" if target_x > actor.position.x else &"move_left"
	Input.action_press(action)
	var reached: bool = false
	for _frame: int in range(300):
		await physics_frame
		if absf(actor.position.x - target_x) <= 12.0:
			reached = true
			break
	Input.action_release(action)
	return reached


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("Junction check failed: " + label)


func _require(condition: bool, label: String) -> bool:
	_expect(condition, label)
	if not condition:
		quit(1)
	return condition
