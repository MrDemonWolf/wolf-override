extends SceneTree

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const State = preload("res://scripts/m0_state.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var path: String = "user://chapter-scene-test-%s.json" % OS.get_process_id()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	game.set("settings_path", "%s-settings.cfg" % path)
	root.add_child(game)
	game.call("_new_game")
	game.call("_finish_intro")
	var state: M0State = _checkpoint_state(State.DISCLOSE)
	game.set("state", state)
	game.call("_sync_scene")
	(game.get_node("Human") as M0Actor).position.x = 160.0
	_expect(not str(game.call("_context_hint")).contains("enter records"), "checkpoint entry hint stays hidden outside safe-point reach")
	(game.get_node("Human") as M0Actor).position.x = 876.0
	_expect(str(game.call("_context_hint")).contains("enter records"), "checkpoint entry hint appears at the safe point")
	game.call("_interact_checkpoint")
	_expect(state.chapter_id == "records" and FileAccess.file_exists(path), "checkpoint opens and saves a second room")
	game.call("_refresh_ui")
	_expect(str(game.get("status_line")).begins_with("WOLF: I took the relay because you told me the truth.") and (game.get_node("CanvasLayer/BottomBar/Speaker") as Label).text == "WOLF", "second room remembers the cooperative choice, under WOLF's tag")
	_expect((game.get("records_room") as RecordsRoom).visible and game.call("_objective") == "COPY PURGE ORDER", "records room and first objective are visible")
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	var main_constants: Dictionary = (game.get_script() as Script).get_script_constant_map()
	var wolf_mirror_x: float = main_constants["WOLF_MIRROR_X"]
	_expect(human.controlled and not wolf.controlled and wolf.autonomous_target_x == wolf_mirror_x, "only engineer is playable while WOLF starts his own mirror check")
	if not await _walk_to(human, 190.0):
		_fail("engineer can walk to the purge queue")
		return
	await _tap(&"interact")
	_expect(state.purge_trace_preserved and game.call("_objective") == "COPY MIRROR INDEX", "purge trace advances objective")
	# Audit 23: a USE over the middle of a machine steps the engineer out beside it, facing it.
	_expect(await _wait_until(func() -> bool: return float(game.get("engineer_step_x")) < 0.0, 40) and human.position.x + M0Actor.HUMAN_REACH <= 190.0 - 56.0 + 18.0 and not human.body_sprite.flip_h and human.controlled, "after copying the purge order the engineer stands beside the purge queue, facing it (x %.0f)" % human.position.x)
	var purge_save: M0State = State.load_from_disk(path)
	_expect(purge_save != null and absf(purge_save.human_position.x - human.position.x) <= 0.5, "the purge-copy autosave keeps the spot the engineer stepped out to, not the middle of the purge queue")
	if not await _walk_to(human, 350.0):
		_fail("engineer can walk between the Records stations")
		return
	_expect(str(game.call("_context_hint")) == "Follow the station lights: mirror port, then exit.", "between stations after the purge copy the hint names only what is left (%s)" % game.call("_context_hint"))
	if not await _walk_to(human, 520.0):
		_fail("engineer can walk to the mirror port")
		return
	await _tap(&"interact")
	_expect(game.get("waiting_for_choice"), "mirror presents both preservation routes")
	for _frame in range(45):
		await physics_frame
	_expect(absf(wolf.position.x - wolf_mirror_x) <= 42.0, "WOLF autonomously reaches the mirror")
	_expect(await _wait_until(func() -> bool: return absf(wolf.position.x - wolf_mirror_x) <= 2.0 and wolf.body_sprite.flip_h, 120), "WOLF stops on the mirror port's right, facing it")
	_expect(wolf.position.x - M0Actor.WOLF_REACH >= 520.0 + 45.0 - 18.0 and human.position.x + M0Actor.HUMAN_REACH < 520.0 - 45.0 + 18.0 and not human.body_sprite.flip_h, "neither WOLF nor the engineer is drawn inside the mirror port: he reads it from its right, they stand on its left (engineer x %.0f, WOLF x %.0f)" % [human.position.x, wolf.position.x])
	await _tap(&"choice_1")
	_expect(state.mirror_trace_preserved and state.mirror_route == "wolf" and not game.get("waiting_for_choice"), "WOLF readout preserves timestamp once")
	_expect(state.memory.get("choice_id") == State.DISCLOSE and state.memory.get("event_id") == State.EVENT_ID, "chapter preserves the actual relay memory")
	_expect(str(game.call("_context_hint")) == "Mirror copied. Head for the exit.", "once the mirror timestamp is copied the mirror port's hint says so instead of offering it again")
	if not await _walk_to(human, 700.0):
		_fail("engineer can walk on from the mirror port")
		return
	_expect(str(game.call("_context_hint")) == "Mirror copied. Head for the exit.", "walking on after both copies the hint names only the exit, never a finished station (%s)" % game.call("_context_hint"))
	var records: RecordsRoom = game.get("records_room") as RecordsRoom
	await _walk_to(human, 905.0)
	_expect(human.position.x <= RecordsRoom.EXIT_DOOR_X - State.HUMAN_HALF_WIDTH + 1.0 and is_equal_approx(records.exit_leaf.open, 0.0), "the shut exit stops the engineer at its leaf before the first copy is secured (x %.1f)" % human.position.x)
	if not await _walk_to(human, 830.0):
		_fail("engineer can reach the records exit")
		return
	await _tap(&"interact")
	_expect(state.chapter_complete and game.call("_objective") == "FIRST COPY SECURED", "first chapter resolves after two traces")
	_expect(records.exit_leaf.open < 0.25 and records.exit_lamp_color() == RecordsRoom.LAMP_MOVING, "securing the copy starts the exit's leaf swinging on its hinges, its status lamp amber")
	_expect(await _wait_until(func() -> bool: return absf(human.position.x - (RecordsRoom.CONTAINER_X + 21.0)) <= 0.5 and human.body_sprite.flip_h, 60), "the engineer secures the copy at the security container's lock, facing it (x %.1f)" % human.position.x)
	_expect(str(game.get("status_line")).contains("An order and a timestamp don't tell me who's a threat"), "WOLF names what was copied when he questions the Director's target labels")
	_expect(game.get("chapter_close_active") and not human.controlled, "first copy opens a player-paced closing beat")
	_expect((game.get_node("CanvasLayer/PauseButton") as Button).visible, "closing beat keeps the pause button available")
	await _tap(&"pause_game")
	_expect(paused and game.get("chapter_close_active") and (game.get_node("CanvasLayer/PauseOverlay") as Control).visible, "pause key opens the menu without dismissing the closing beat")
	var closing_camera: Camera2D = game.get_node("IntroCamera") as Camera2D
	var paused_camera_position: Vector2 = closing_camera.position
	await create_timer(0.1, true).timeout
	_expect(closing_camera.position == paused_camera_position, "pause freezes the closing camera transition")
	(game.get_node("CanvasLayer/PauseOverlay") as PauseOverlay).resume_requested.emit()
	_expect(not paused and game.get("chapter_close_active") and not human.controlled, "resume preserves the closing beat until Continue")
	await create_timer(0.6).timeout
	_expect(records.exit_leaf.open > 0.0 and records.exit_leaf.open < 1.0 and records.exit_leaf.visible, "the exit's leaf is part way round its swing, never faded or hidden")
	_expect(closing_camera.zoom.x >= 1.35, "the closing shot never zooms out past the play view")
	var close_half: Vector2 = Vector2(960.0, 540.0) * 0.5 / closing_camera.zoom
	var dialogue_top: float = (game.get_node("CanvasLayer/BottomBar") as Panel).position.y
	var framed: bool = closing_camera.position.x + close_half.x <= 960.0
	for actor: M0Actor in [human, wolf]:
		var screen_x: float = (actor.position.x - closing_camera.position.x) * closing_camera.zoom.x + 480.0
		framed = framed and screen_x > 40.0 and screen_x < 920.0
	framed = framed and (440.0 - closing_camera.position.y) * closing_camera.zoom.y + 270.0 <= dialogue_top - 24.0
	_expect(framed, "the closing shot keeps both actors in view with their feet clear above the dialogue")
	await _tap(&"interact")
	_expect(not game.get("chapter_close_active") and human.controlled, "closing beat returns control to the engineer")
	var saved: Dictionary = state.to_dict()
	game.call("_new_game")
	for _step in range((main_constants["INTRO_LINES"] as Array).size()):
		game.call("_advance_intro")
	var ending_intro_tween: Tween = game.get("intro_tween") as Tween
	ending_intro_tween.custom_step(0.4)
	var intro_fade: ColorRect = game.get_node("CanvasLayer/IntroFade") as ColorRect
	_expect(not game.get("intro_active") and intro_fade.color.a > 0.0, "intro returns control while its fade-in is still running")
	_expect((game.get("state") as M0State).chapter_id == "lockdown", "New Game clears chapter progress")
	(game.get_node("CanvasLayer/IntroAlarm") as ColorRect).color.a = 0.13
	game.call("_load_game")
	_expect(intro_fade.color.a == 0.0 and (game.get_node("CanvasLayer/IntroAlarm") as ColorRect).color.a == 0.0 and not ending_intro_tween.is_running(), "Continue cancels the remaining intro transition and clears fade and alarm overlays")
	state = game.get("state") as M0State
	_expect(state.to_dict() == saved and human.position == state.human_position and wolf.position == state.wolf_position, "Continue restores progress and both positions")
	# Audit 23: a save taken over a machine's body (an earlier build's) restores the engineer beside it,
	# facing it and still within reach, in the corridor and in Records.
	var over_safe_point: M0State = _checkpoint_state(State.PRESS)
	over_safe_point.human_position = Vector2(873.5, 410.0)
	over_safe_point.save_to_disk(path)
	game.call("_load_game")
	_expect(absf(human.position.x - (876.0 - 35.0 - M0Actor.HUMAN_REACH + 6.0)) <= 0.5 and not human.body_sprite.flip_h and str(game.call("_context_hint")).contains("enter records"), "Continue over the SAFE POINT console puts the engineer beside it, facing it and in reach (x %.1f)" % human.position.x)
	var over_queue: M0State = _checkpoint_state(State.PRESS)
	over_queue.enter_records()
	over_queue.preserve_purge_trace()
	over_queue.human_position = Vector2(188.2, 410.0)
	over_queue.save_to_disk(path)
	game.call("_load_game")
	_expect(absf(human.position.x - (190.0 - 56.0)) <= 0.5 and not human.body_sprite.flip_h, "Continue over the PURGE QUEUE puts the engineer beside it, facing it (x %.1f)" % human.position.x)
	var beside_port: M0State = _checkpoint_state(State.PRESS)
	beside_port.enter_records()
	beside_port.human_position = Vector2(464.0, 410.0)
	beside_port.save_to_disk(path)
	game.call("_load_game")
	_expect(human.position == beside_port.human_position, "a save already clear of every machine restores exactly")
	game.queue_free()
	await process_frame

	game = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	game.set("settings_path", "%s-settings.cfg" % path)
	root.add_child(game)
	game.call("_new_game")
	game.call("_finish_intro")
	state = _checkpoint_state(State.PRESS)
	game.set("state", state)
	game.call("_sync_scene")
	game.call("_interact_checkpoint")
	_expect(str(game.get("status_line")).contains("I refused the live relay"), "second room remembers refusal without blocking progress")
	human = game.get_node("Human") as M0Actor
	if not await _walk_to(human, 190.0):
		_fail("fallback engineer can reach purge queue")
		return
	await _tap(&"interact")
	if not await _walk_to(human, 520.0):
		_fail("fallback engineer can reach mirror port")
		return
	await _tap(&"interact")
	await _tap(&"choice_2")
	_expect(state.mirror_trace_preserved and state.mirror_route == "manual", "manual port preserves the required timestamp")
	_expect(str(game.call("_context_hint")) == "Mirror copied. Head for the exit.", "the manual copy also leaves the mirror port reading as copied")
	_expect(state.memory.get("choice_id") == State.PRESS, "manual route retains accurate earlier choice")
	_expect(not (game.get_node("Wolf") as M0Actor).controlled, "fallback never transfers control to WOLF")
	if not await _walk_to(human, 830.0):
		_fail("fallback engineer can reach exit")
		return
	await _tap(&"interact")
	var loaded: M0State = State.load_from_disk(path)
	_expect(state.chapter_complete and loaded != null and loaded.mirror_route == "manual", "manual chapter completion saves for Continue")
	game.call("_pause_game")
	(game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton") as Button).pressed.emit()
	var continue_button: Button = game.get_node("CanvasLayer/TitleScreen/ContinueButton") as Button
	_expect(game.get("title_open") and not paused and not human.controlled and not continue_button.disabled, "Return to Title refreshes Continue availability after completing the chapter")
	continue_button.pressed.emit()
	_expect(not game.get("title_open") and (game.get("state") as M0State).to_dict() == loaded.to_dict() and human.controlled, "Continue from the returned title restores the exact completed checkpoint")
	state = M0State.new()
	state.record_choice(State.DISCLOSE)
	state.arm_breaker()
	state.activate_power("human")
	state.reach_checkpoint()
	state.human_position = Vector2(876.0, 410.0)
	state.wolf_position = Vector2(812.0, 423.0)
	game.set("state", state)
	game.call("_sync_scene")
	game.call("_interact_checkpoint")
	_expect(str(game.get("status_line")).begins_with("WOLF: I offered the relay; you cranked the bypass. Still with you.") and not str(game.get("status_line")).contains("I took the relay"), "Records entry remembers the actual manual route even when the risk was disclosed")
	state.preserve_purge_trace()
	state.save_to_disk(path)
	game.call("_load_game")
	_expect(str(game.get("status_line")).contains("copy the mirror index"), "Continue after the purge copy points at the mirror index")
	state = game.get("state") as M0State
	state.preserve_mirror_trace("manual")
	state.save_to_disk(path)
	game.call("_load_game")
	_expect(str(game.get("status_line")).contains("head for the exit"), "Continue after both copies points at the exit")

	var unwritable_path: String = "user://missing-save-folder-%s/save.json" % OS.get_process_id()
	game.set("save_path", unwritable_path)
	game.set("status_line", "WOLF: Copied.")
	human.position.x = 190.0
	game.call("_save_progress")
	game.call("_refresh_ui")
	var hint_text: Label = game.get_node("CanvasLayer/ContextHint/Text") as Label
	_expect(game.get("status_line") == "WOLF: Copied." and hint_text.text == "Save failed. Use a station to try again.", "save failure shows in the system hint, not in WOLF's line")
	human.position.x = 830.0
	game.call("_refresh_ui")
	_expect(hint_text.text.ends_with("secure the first copy."), "moving to another station brings back its interaction hint after a save failure")
	human.position.x = 190.0
	game.call("_save_progress")
	game.set("save_path", path)
	game.call("_save_progress")
	game.call("_refresh_ui")
	_expect(hint_text.text != "Save failed. Use a station to try again.", "a later successful save clears the failure hint")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# The exit arc clip can still be playing. Stop every player first: the mixer releases a stopped clip's
	# playback a few mix steps later, and a fixed 0.1 s wait after freeing was sometimes too short on a busy
	# runner, which reported two leaked objects at exit. Then give it frames as well as time before quitting.
	for player: Node in game.find_children("*", "AudioStreamPlayer", true, false) + game.find_children("*", "AudioStreamPlayer2D", true, false):
		player.call("stop")
	await create_timer(0.1).timeout
	game.queue_free()
	for frame: int in 10:
		await process_frame
	await create_timer(0.2).timeout
	if failures == 0:
		print("Chapter scene checks passed")
	quit(1 if failures > 0 else 0)


func _checkpoint_state(choice_id: String) -> M0State:
	var state: M0State = State.new()
	state.record_choice(choice_id)
	state.arm_breaker()
	state.activate_power("wolf" if choice_id == State.DISCLOSE else "human")
	state.reach_checkpoint()
	state.human_position = Vector2(876.0, 410.0)
	state.wolf_position = Vector2(812.0, 423.0)
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


func _wait_until(condition: Callable, max_frames: int) -> bool:
	for _frame in range(max_frames):
		if condition.call():
			return true
		await physics_frame
	return bool(condition.call())


func _walk_to(actor: M0Actor, target_x: float) -> bool:
	var action: StringName = &"move_right" if target_x > actor.position.x else &"move_left"
	Input.action_press(action)
	var reached: bool = false
	for _frame in range(300):
		await physics_frame
		if absf(actor.position.x - target_x) <= 12.0:
			reached = true
			break
	Input.action_release(action)
	return reached


func _expect(condition: bool, label: String) -> void:
	if not condition:
		_fail(label)


func _fail(label: String) -> void:
	failures += 1
	push_error("Chapter scene check failed: " + label)
	quit(1)
