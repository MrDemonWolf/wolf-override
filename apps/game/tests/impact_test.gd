extends SceneTree

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const State = preload("res://scripts/m0_state.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var path: String = "user://impact-test-%s.json" % OS.get_process_id()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	game.set("settings_path", "%s-settings.cfg" % path)
	root.add_child(game)
	var impact: Impact = game.get("impact") as Impact
	var camera: Camera2D = game.get_node("IntroCamera") as Camera2D
	var intro_fade: ColorRect = game.get_node("CanvasLayer/IntroFade") as ColorRect
	var intro_alarm: ColorRect = game.get_node("CanvasLayer/IntroAlarm") as ColorRect
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	if not _require(impact != null and impact.camera == camera and impact.white_flash == intro_fade and impact.red_wash == intro_alarm, "Main owns one impact kit wired to the camera and the existing overlays"):
		return
	game.call("_new_game")
	game.call("_finish_intro")
	await process_frame

	# Shake: trauma moves Camera2D.offset only, then decays to nothing.
	var rest_position: Vector2 = camera.position
	impact.add_trauma(1.0)
	var moved: bool = false
	for _frame: int in 6:
		await process_frame
		moved = moved or camera.offset.length() > 0.5
	_expect(moved, "trauma shakes the camera through its offset")
	_expect(camera.offset.length() <= Impact.MAX_SHAKE_PX, "shake never exceeds the 10 px cap")
	_expect(camera.position == rest_position, "shake leaves Camera2D.position (clamp and smoothing) alone")
	_expect(await _wait_until(func() -> bool: return impact.trauma == 0.0 and camera.offset == Vector2.ZERO, 90), "trauma decays to zero and the offset returns to zero within 90 frames")

	# Hit-stop: the dip always ends, including when the game pauses inside it.
	impact.hit_stop(0.08)
	_expect(is_equal_approx(Engine.time_scale, Impact.HIT_STOP_SCALE), "hit-stop dips Engine.time_scale")
	await create_timer(0.2, true, false, true).timeout
	_expect(Engine.time_scale == 1.0, "hit-stop restores time_scale after its real-time length")
	impact.hit_stop(0.09)
	await process_frame
	paused = true
	_expect(paused and is_equal_approx(Engine.time_scale, Impact.HIT_STOP_SCALE), "a raw tree pause mid-dip leaves the dip to its timer")
	await create_timer(0.2, true, false, true).timeout
	_expect(paused and Engine.time_scale == 1.0, "the timer restores time_scale while the tree is still paused")
	paused = false
	impact.hit_stop(0.09)
	await process_frame
	game.call("_pause_game")
	_expect(paused and Engine.time_scale == 1.0, "the Pause menu ends a dip at once so it never opens slowed")
	impact.hit_stop(0.09)
	game.call("_resume_game")
	_expect(not paused and Engine.time_scale == 1.0, "resume always restores time_scale, even inside a dip")
	impact.hit_stop(0.05)
	var shorter_serial: int = impact.get("_stop_serial")
	impact.hit_stop(0.09)
	# Fire the shorter dip's own timeout by hand: no wall-clock race with the longer one's timer.
	impact.call("_end_hit_stop", shorter_serial)
	_expect(is_equal_approx(Engine.time_scale, Impact.HIT_STOP_SCALE), "a longer hit-stop replaces a shorter one instead of ending early")
	await create_timer(0.1, true, false, true).timeout
	_expect(Engine.time_scale == 1.0, "the replacing hit-stop still ends")
	impact.hit_stop(5.0)
	await create_timer(Impact.MAX_HIT_STOP_SECONDS + 0.05, true, false, true).timeout
	_expect(Engine.time_scale == 1.0, "hit-stop is capped at 100 ms")

	# Flash: a white frame on IntroFade over a red wash on IntroAlarm, both back to rest.
	impact.flash(0.1, 0.3)
	_expect(intro_fade.color.r == 1.0 and intro_fade.color.a > 0.0 and intro_alarm.color.a >= Impact.RED_WASH_ALPHA, "flash whitens IntroFade and washes IntroAlarm red")
	await create_timer(0.5, true, false, true).timeout
	_expect(intro_fade.color == Color(0.0, 0.0, 0.0, 0.0) and intro_alarm.color.a == 0.0, "flash restores both overlays to their rest colours")
	impact.flash(0.5, 0.5)
	impact.reset()
	_expect(intro_fade.color == Color(0.0, 0.0, 0.0, 0.0) and intro_alarm.color.a == 0.0 and camera.offset == Vector2.ZERO and Engine.time_scale == 1.0, "reset restores overlays, camera and time scale at once")

	# Reduced Motion: no shake, no hit-stop, flashes halved; the kit stays usable.
	impact.reduce_motion = true
	impact.add_trauma(1.0)
	impact.hit_stop(0.09)
	await process_frame
	_expect(camera.offset == Vector2.ZERO and impact.trauma == 0.0 and Engine.time_scale == 1.0, "Reduced Motion zeroes shake and skips hit-stop")
	impact.reduce_motion = false
	impact.enabled = false
	impact.add_trauma(1.0)
	impact.hit_stop(0.09)
	impact.flash(0.2, 0.2)
	await process_frame
	_expect(camera.offset == Vector2.ZERO and Engine.time_scale == 1.0 and intro_fade.color.a == 0.0 and intro_alarm.color.a == 0.0, "a disabled kit does nothing")
	impact.enabled = true

	# Rumble follows the controller in use, not always the first one connected.
	var pad_press: InputEventJoypadButton = InputEventJoypadButton.new()
	pad_press.device = 1
	pad_press.button_index = JOY_BUTTON_A
	pad_press.pressed = true
	game.call("_note_input_device", pad_press)
	_expect(game.get("controller_active") and impact.rumble_device == 1, "a press on the second pad makes it the one that rumbles")
	var pad_motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
	pad_motion.device = 0
	pad_motion.axis = JOY_AXIS_LEFT_X
	pad_motion.axis_value = 1.0
	game.call("_note_input_device", pad_motion)
	_expect(impact.rumble_device == 0, "moving the first pad's stick hands rumble back to it")
	var key_press: InputEventKey = InputEventKey.new()
	key_press.pressed = true
	key_press.physical_keycode = KEY_D
	game.call("_note_input_device", key_press)
	_expect(not game.get("controller_active"), "a key press returns to keyboard play")

	# Existing moments route through the kit: the relay contact and the seal landing.
	var relay_sparks: CPUParticles2D = game.get("relay_sparks") as CPUParticles2D
	var door_dust: CPUParticles2D = game.get("door_dust") as CPUParticles2D
	var state: M0State = game.get("state") as M0State
	state.record_choice(State.DISCLOSE)
	state.arm_breaker()
	game.call("_sync_scene")
	human.position.x = 605.0
	game.call("_interact_relay")
	_expect(await _wait_until(func() -> bool: return state.door_open, 150), "WOLF takes the relay")
	_expect(impact.trauma > 0.0 and relay_sparks.emitting and relay_sparks.color == Color("#8be3ff"), "the relay contact adds shake and a cyan spark shower")
	_expect(await _wait_until(func() -> bool: return door_dust.emitting, 60), "the seal's landing bursts dust at its base")
	_expect(await _wait_until(func() -> bool: return impact.trauma == 0.0 and camera.offset == Vector2.ZERO, 120), "the corridor settles after the seal opens")

	# Knockdown: the current checkpoint comes back byte for byte, memory included.
	human.position.x = 876.0
	game.call("_interact_checkpoint")
	if not _require(state.checkpoint_reached and FileAccess.file_exists(path), "the safe point saves the checkpoint the knockdown restores"):
		return
	var saved: Dictionary = state.to_dict()
	var save_bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	_expect(await _walk_to(human, 700.0), "the engineer walks back toward the seal")
	var hazard: Hazard = Hazard.make("TestVent", Rect2(670.0, 380.0, 60.0, 60.0), "The vent blew while you stood on it. Wait for the hiss to stop.")
	hazard.contact.connect(func(source: Hazard) -> void: game.call("_fail_beat", source.reason))
	game.add_child(hazard)
	await physics_frame
	await physics_frame
	_expect(not game.get("fail_active"), "an unarmed hazard never knocks the engineer down")
	hazard.armed = true
	if not _require(game.get("fail_active"), "arming a hazard the engineer already stands in knocks them down at once"):
		return
	_expect(not human.controlled and is_equal_approx(Engine.time_scale, Impact.HIT_STOP_SCALE) and intro_alarm.color.a >= Impact.RED_WASH_ALPHA, "the knockdown takes the controls, dips time and washes the screen red")
	_expect(str(game.get("status_line")).begins_with("The vent blew"), "the status line names the cause")
	Input.action_press(&"move_left")
	for _frame: int in 10:
		await physics_frame
	Input.action_release(&"move_left")
	_expect(absf(human.position.x - 700.0) <= 12.0, "held movement does nothing during the knockdown")
	_expect(await _wait_until(func() -> bool: return absf(human.body_sprite.rotation_degrees) > 40.0, 30), "the engineer's sprite tilts over")
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "the knockdown hands back within a few seconds")
	state = game.get("state") as M0State
	_expect(state.to_dict() == saved and FileAccess.get_file_as_bytes(path) == save_bytes, "the knockdown restores the checkpoint exactly and never writes the save")
	_expect(state.memory.get("choice_id") == State.DISCLOSE and state.route == "cooperate", "the relay memory and route survive the knockdown")
	_expect(human.controlled and human.position == state.human_position and wolf.position == state.wolf_position, "the engineer stands at the checkpoint with controls back")
	_expect(human.body_sprite.rotation_degrees == 0.0 and human.body_sprite.position == Vector2(0.0, -5.0), "the sprite is upright again")
	_expect(str(game.get("status_line")).contains("Wait for the hiss") and str(game.get("status_line")).contains("last autosave"), "the status line keeps the cause and says where play resumed")
	_expect(await _wait_until(func() -> bool: return Engine.time_scale == 1.0 and camera.offset == Vector2.ZERO and intro_fade.color.a == 0.0, 90), "time scale, camera and fade are all at rest after the restore")
	# Walking into the armed hazard is the other contact path.
	_expect(await _walk_to(human, 760.0), "the engineer walks toward the vent again")
	Input.action_press(&"move_left")
	var tripped: bool = await _wait_until(func() -> bool: return game.get("fail_active"), 120)
	Input.action_release(&"move_left")
	_expect(tripped, "walking into an armed hazard knocks the engineer down")
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "the second knockdown restores too")
	_expect((game.get("state") as M0State).to_dict() == saved, "the second restore is the same checkpoint")
	hazard.queue_free()

	# Pause during the knockdown keeps working, and Return to Title drops it cleanly.
	game.call("_fail_beat", "Test knockdown.")
	await process_frame
	game.call("_pause_game")
	_expect(paused and (game.get_node("CanvasLayer/PauseOverlay") as Control).visible and Engine.time_scale == 1.0, "Pause works during a knockdown and clears the dip")
	(game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton") as Button).pressed.emit()
	_expect(game.get("title_open") and not game.get("fail_active") and intro_fade.color.a == 0.0 and human.body_sprite.rotation_degrees == 0.0, "Return to Title cancels the knockdown")

	# Before any checkpoint the beat snapshot stands in, so the relay memory still survives.
	game.call("_new_game")
	game.call("_finish_intro")
	state = game.get("state") as M0State
	human.position.x = 350.0
	game.call("_interact_breaker")
	game.call("_choose", State.PRESS)
	var pre_save: Dictionary = (game.get("beat_snapshot") as Dictionary).duplicate(true)
	_expect(await _walk_to(human, 450.0), "the engineer moves on before any save exists")
	game.call("_fail_beat", "Test knockdown.")
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "a knockdown before the first checkpoint still hands back")
	state = game.get("state") as M0State
	_expect(state.to_dict() == pre_save and state.memory.get("choice_id") == State.PRESS and not state.checkpoint_reached and state.chapter_id == "lockdown", "without a checkpoint the beat snapshot restores the choice, not an older save")
	_expect(human.controlled and human.position == state.human_position, "the engineer is back at the beat start")
	_expect(str(game.get("status_line")).ends_with("Back at the start of this beat."), "without a checkpoint the restore line does not claim an autosave")

	# Reduced Motion knockdown: no tilt, no dip, still a restore.
	impact.reduce_motion = true
	game.call("_fail_beat", "Test knockdown.")
	await process_frame
	_expect(game.get("fail_active") and Engine.time_scale == 1.0 and human.body_sprite.rotation_degrees == 0.0, "Reduced Motion knockdown skips the tilt and the dip")
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "the Reduced Motion knockdown restores")
	impact.reduce_motion = false

	# Intro and chapter close never knock down; the kit's intro boom still settles.
	game.call("_new_game")
	game.call("_fail_beat", "Test knockdown.")
	_expect(not game.get("fail_active"), "the opening ignores knockdowns")
	game.call("_advance_intro")
	game.call("_advance_intro")
	_expect(impact.trauma > 0.0 and intro_fade.color.r == 1.0, "the containment gate boom shakes and flashes")
	game.call("_finish_intro")
	_expect(await _wait_until(func() -> bool: return impact.trauma == 0.0 and camera.offset == Vector2.ZERO, 90), "the gate boom settles")

	game.queue_free()
	# The mixer releases a stopped clip a few steps later; give it that time before quitting.
	await create_timer(0.1).timeout
	_expect(Engine.time_scale == 1.0, "freeing the game leaves time_scale at 1.0")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if failures == 0:
		print("Impact checks passed")
	quit(1 if failures > 0 else 0)


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
		push_error("Impact check failed: " + label)


func _require(condition: bool, label: String) -> bool:
	_expect(condition, label)
	if not condition:
		quit(1)
	return condition
