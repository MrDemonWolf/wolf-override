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
	game.call("_interact_checkpoint")
	_expect(state.chapter_id == "records" and FileAccess.file_exists(path), "checkpoint opens and saves a second room")
	_expect(str(game.get("status_line")).contains("I chose the relay"), "second room remembers the cooperative choice")
	_expect((game.get("records_room") as RecordsRoom).visible and game.call("_objective") == "COPY PURGE ORDER", "records room and first objective are visible")
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	_expect(human.controlled and not wolf.controlled and wolf.autonomous_target_x == 520.0, "only engineer is playable while WOLF starts his own mirror check")
	if not await _walk_to(human, 190.0):
		_fail("engineer can walk to the purge queue")
		return
	await _tap(&"interact")
	_expect(state.purge_trace_preserved and game.call("_objective") == "COPY MIRROR INDEX", "purge trace advances objective")
	if not await _walk_to(human, 520.0):
		_fail("engineer can walk to the mirror port")
		return
	await _tap(&"interact")
	_expect(game.get("waiting_for_choice"), "mirror presents both preservation routes")
	for _frame in range(45):
		await physics_frame
	_expect(absf(wolf.position.x - 520.0) <= 42.0, "WOLF autonomously reaches the mirror")
	await _tap(&"choice_1")
	_expect(state.mirror_trace_preserved and state.mirror_route == "wolf" and not game.get("waiting_for_choice"), "WOLF readout preserves timestamp once")
	_expect(state.memory.get("choice_id") == State.DISCLOSE and state.memory.get("event_id") == State.EVENT_ID, "chapter preserves the actual relay memory")
	if not await _walk_to(human, 830.0):
		_fail("engineer can reach the records exit")
		return
	await _tap(&"interact")
	_expect(state.chapter_complete and game.call("_objective") == "FIRST COPY SECURED", "first chapter resolves after two traces")
	_expect(str(game.get("status_line")).contains("A list doesn't tell me who's a threat"), "WOLF questions the Director's target labels after the first copy")
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
	await _tap(&"interact")
	_expect(not game.get("chapter_close_active") and human.controlled, "closing beat returns control to the engineer")
	var saved: Dictionary = state.to_dict()
	game.call("_new_game")
	for _step in range(5):
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
	_expect(state.memory.get("choice_id") == State.PRESS, "manual route retains accurate earlier choice")
	_expect(not (game.get_node("Wolf") as M0Actor).controlled, "fallback never transfers control to WOLF")
	if not await _walk_to(human, 830.0):
		_fail("fallback engineer can reach exit")
		return
	await _tap(&"interact")
	var loaded: M0State = State.load_from_disk(path)
	_expect(state.chapter_complete and loaded != null and loaded.mirror_route == "manual", "manual chapter completion saves for Continue")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game.queue_free()
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
	Input.action_press(action)
	await process_frame
	Input.action_release(action)


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
