extends SceneTree

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const State = preload("res://scripts/m0_state.gd")
const MainScript = preload("res://scripts/main.gd")
const Suite = preload("res://tests/support/game_suite.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_collapse_sheet()
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
	# Beside the SAFE POINT console, where a USE steps the engineer out to (a restore never leaves them
	# inside the machine).
	human.position.x = 830.0
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
	# Turned round to face the way they came (the second knockdown below walks in facing left).
	human.body_sprite.flip_h = false
	var faced_left: bool = human.body_sprite.flip_h
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
	# P0-3: the painted collapse plays, frame by frame, and the body ends up lying on the floor line.
	# The painted slump is forward, so the body falls the way they faced and never turns round.
	var seen_frames: Dictionary = {}
	var turned: Array[bool] = [human.body_sprite.flip_h != faced_left]
	var lying: bool = await _wait_until(func() -> bool:
		turned[0] = turned[0] or human.body_sprite.flip_h != faced_left
		if human.body_sprite.texture == MainScript.COLLAPSE_SHEET:
			seen_frames[int(human.body_sprite.region_rect.position.x / MainScript.COLLAPSE_FRAME.x)] = true
		return seen_frames.has(MainScript.COLLAPSE_SPANS.size() - 1), 60)
	_expect(lying and seen_frames.size() >= 3, "the engineer collapses through the painted frames (%s) and lies down" % str(seen_frames.keys()))
	_expect(not turned[0] and is_equal_approx(float(game.get("collapse_fall")), -1.0 if faced_left else 1.0), "facing %s, they slump forward that way and never turn round" % ("left" if faced_left else "right"))
	# The reflection copies its source in _process, which a physics frame does not always include;
	# process_frame fires before that frame's _process, so the second one follows a full pass.
	await process_frame
	await process_frame
	_check_lying(human, "in the corridor")
	await _check_retry_timing(game, "the first knockdown")
	state = game.get("state") as M0State
	_expect(state.to_dict() == saved and FileAccess.get_file_as_bytes(path) == save_bytes, "the knockdown restores the checkpoint exactly and never writes the save")
	_expect(state.memory.get("choice_id") == State.DISCLOSE and state.route == "cooperate", "the relay memory and route survive the knockdown")
	_expect(human.controlled and human.position == state.human_position and wolf.position == state.wolf_position, "the engineer stands at the checkpoint with controls back")
	_expect(human.body_sprite.rotation_degrees == 0.0 and human.body_sprite.position == Vector2(0.0, -5.0) and human.body_sprite.texture != MainScript.COLLAPSE_SHEET and not human.body_sprite.region_enabled and is_equal_approx(human.body_sprite.scale.x, 0.188), "the engineer stands again, as drawn before the knockdown")
	var reflection: FloorReflection = game.get("human_reflection") as FloorReflection
	await process_frame
	await process_frame
	_expect(reflection.texture == human.body_sprite.texture and reflection.shadow_span == Vector2.ZERO and is_equal_approx(reflection.floor_y, -5.0 + 192.0 * 0.188), "their reflection and shadow are the standing ones again")
	_expect(str(game.get("status_line")).contains("Wait for the hiss") and str(game.get("status_line")).contains("Back at the last checkpoint."), "the status line keeps the cause and says where play resumed")
	_expect(await _wait_until(func() -> bool: return Engine.time_scale == 1.0 and camera.offset == Vector2.ZERO and intro_fade.color.a == 0.0, 90), "time scale, camera and fade are all at rest after the restore")
	# Walking into the armed hazard is the other contact path.
	_expect(await _walk_to(human, 760.0), "the engineer walks toward the vent again")
	Input.action_press(&"move_left")
	var tripped: bool = await _wait_until(func() -> bool: return game.get("fail_active"), 120)
	Input.action_release(&"move_left")
	_expect(tripped, "walking into an armed hazard knocks the engineer down")
	var walked_turn: Array[bool] = [not human.body_sprite.flip_h]
	var walked_down: bool = await _wait_until(func() -> bool:
		walked_turn[0] = walked_turn[0] or not human.body_sprite.flip_h
		return human.body_sprite.texture == MainScript.COLLAPSE_SHEET and is_equal_approx(human.body_sprite.region_rect.position.x, MainScript.COLLAPSE_FRAME.x * (MainScript.COLLAPSE_SPANS.size() - 1)), 60)
	_expect(walked_down and not walked_turn[0], "walking left into it, they slump forward to the left without turning round")
	await _check_retry_timing(game, "a repeat knockdown")
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
	# Beside the breaker, where a USE steps the engineer out to.
	human.position.x = 306.0
	game.call("_interact_breaker")
	game.call("_choose", State.PRESS)
	var pre_save: Dictionary = (game.get("beat_snapshot") as Dictionary).duplicate(true)
	_expect(await _walk_to(human, 450.0), "the engineer moves on before any save exists")
	game.call("_fail_beat", "Test knockdown.")
	_expect(await Suite.retry(game, 240), "a knockdown before the first checkpoint still hands back")
	state = game.get("state") as M0State
	_expect(state.to_dict() == pre_save and state.memory.get("choice_id") == State.PRESS and not state.checkpoint_reached and state.chapter_id == "lockdown", "without a checkpoint the beat snapshot restores the choice, not an older save")
	_expect(human.controlled and human.position == state.human_position, "the engineer is back at the beat start")
	_expect(str(game.get("status_line")).ends_with("Back at the start of this stretch."), "without a checkpoint the restore line does not claim a checkpoint")

	# Reduced Motion knockdown: straight to lying on the floor, no dip, still a restore.
	impact.reduce_motion = true
	game.call("_fail_beat", "Test knockdown.")
	await process_frame
	await process_frame
	_expect(game.get("fail_active") and Engine.time_scale == 1.0 and human.body_sprite.rotation_degrees == 0.0 and is_equal_approx(human.body_sprite.region_rect.position.x, MainScript.COLLAPSE_FRAME.x * (MainScript.COLLAPSE_SPANS.size() - 1)), "Reduced Motion knockdown cuts straight to lying down and skips the dip")
	_check_lying(human, "with Reduced Motion")
	_expect(await Suite.retry(game, 240), "the Reduced Motion knockdown restores")
	impact.reduce_motion = false

	# Intro and chapter close never knock down; the kit's intro boom still settles.
	game.call("_new_game")
	game.call("_fail_beat", "Test knockdown.")
	_expect(not game.get("fail_active"), "the opening ignores knockdowns")
	for _step: int in 3:
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


## P0-3: the collapse sheet is cut so each frame's soles are on its bottom row (no gap above the floor
## line and nothing below it), and Main's spans are the painted body's columns from the boots.
func _check_collapse_sheet() -> void:
	var image: Image = MainScript.COLLAPSE_SHEET.get_image()
	if image.is_compressed():
		image.decompress()
	var frame_size: Vector2i = Vector2i(MainScript.COLLAPSE_FRAME)
	_expect(image.get_width() == frame_size.x * MainScript.COLLAPSE_SPANS.size() and image.get_height() == frame_size.y, "the collapse sheet holds %d frames of %s" % [MainScript.COLLAPSE_SPANS.size(), frame_size])
	for frame: int in MainScript.COLLAPSE_SPANS.size():
		var bottom_row: int = 0
		var top_row: int = frame_size.y
		var left: int = frame_size.x
		var right: int = -1
		for y: int in frame_size.y:
			for x: int in frame_size.x:
				if image.get_pixel(frame * frame_size.x + x, y).a >= 0.5:
					bottom_row = maxi(bottom_row, y)
					top_row = mini(top_row, y)
					left = mini(left, x)
					right = maxi(right, x)
		_expect(bottom_row == frame_size.y - 1, "collapse frame %d stands its soles on its bottom row (%d)" % [frame, bottom_row])
		_expect(top_row == int(MainScript.COLLAPSE_TOPS[frame]), "collapse frame %d's painted body starts on row %d, as Main says (%.0f)" % [frame, top_row, MainScript.COLLAPSE_TOPS[frame]])
		var span: Vector2 = MainScript.COLLAPSE_SPANS[frame]
		_expect(absf(left - MainScript.COLLAPSE_PIVOT_X - span.x) <= 1.0 and absf(right - MainScript.COLLAPSE_PIVOT_X - span.y) <= 1.0, "collapse frame %d's painted body spans %d..%d from the boots, as Main says (%s)" % [frame, left - int(MainScript.COLLAPSE_PIVOT_X), right - int(MainScript.COLLAPSE_PIVOT_X), span])


## P0-3: a knocked-down body lies on the floor line (y 440, the bottom of the engineer's body): never
## tilted, its soles on the line and nothing drawn below it, its reflection the same picture and its
## shadow under the whole body.
func _check_lying(human: M0Actor, label: String) -> void:
	var sprite: Sprite2D = human.body_sprite
	var rect: Rect2 = sprite.get_global_transform() * sprite.get_rect()
	var floor_y: float = human.global_position.y + MainScript.HUMAN_FLOOR_Y
	_expect(is_zero_approx(sprite.rotation_degrees) and absf(rect.end.y - floor_y) < 0.01, "%s the lying body's soles are on the floor line (bottom %.2f, floor %.2f)" % [label, rect.end.y, floor_y])
	var reflection: FloorReflection = null
	for sibling: Node in human.get_children():
		if sibling is FloorReflection:
			reflection = sibling
	if reflection == null:
		_expect(false, "%s the engineer has a floor reflection" % label)
		return
	var span: Vector2 = reflection.shadow_span
	var local: Rect2 = Rect2(rect.position - human.global_position, rect.size)
	_expect(reflection.texture == sprite.texture and reflection.region_rect == sprite.region_rect and is_equal_approx(reflection.floor_y, MainScript.HUMAN_FLOOR_Y), "%s the reflection mirrors the lying body about the floor line" % label)
	_expect(span.x <= local.position.x + 2.0 and span.y >= local.end.x - 2.0 and is_equal_approx(reflection.shadow.position.y, MainScript.HUMAN_FLOOR_Y), "%s the shadow lies under the whole body (%.1f..%.1f under %.1f..%.1f)" % [label, span.x, span.y, local.position.x, local.end.x])


func _wait_until(condition: Callable, frames: int) -> bool:
	for _frame: int in range(frames):
		await physics_frame
		if condition.call():
			return true
	return false


## Q17 (Cold Still timing, October 14, 2026), the same on the first knockdown and every repeat: the card
## takes RETRY at 0.9 s and not before, holds until it is pressed, and a press at once has control back
## at about 1.5 s. Time is the game's own (the frames' deltas, as the knockdown and its tweens count it),
## and each moment is checked to the frame it falls in, so a slow machine does not change the result.
func _check_retry_timing(game: Node, context: String) -> void:
	# Its two presses stay inline, not Suite.retry: each is frame-exact and counts the press frame itself.
	var hint: Label = game.get_node("CanvasLayer/ContextHint/Text") as Label
	var age: float = float(game.get("fail_age"))
	var before: float = age
	var early_press: bool = false
	var ready_matches: bool = true
	while not bool(game.call("_retry_ready")) and age < 3.0:
		await process_frame
		before = age
		age = float(game.get("fail_age"))
		ready_matches = ready_matches and bool(game.call("_retry_ready")) == (age >= 0.9)
		if not early_press and age >= 0.5 and age < 0.8:
			# A press before 0.9 s does nothing, and no prompt asks for one.
			early_press = true
			Input.action_press(&"interact")
			await process_frame
			Input.action_release(&"interact")
			before = age
			age = float(game.get("fail_age"))
			_expect(bool(game.get("fail_active")) and not bool(game.get("retrying")) and not hint.text.contains("RETRY"), "%s: a press at %.2f s does nothing and no RETRY shows yet" % [context, age])
	_expect(early_press and ready_matches and bool(game.call("_retry_ready")) and age >= 0.9 and before < 0.9, "%s: the card takes RETRY from the frame that reaches 0.9 s (%.3f s, the frame before at %.3f s)" % [context, age, before])
	await process_frame
	_expect(hint.text == "E  RETRY" and (game.get_node("CanvasLayer/ContextHint") as Control).visible, "%s: the hint reads E  RETRY once it does (%s)" % [context, hint.text.c_escape()])
	# Left alone, the card holds: it never moves on by itself.
	while float(game.get("fail_age")) < 2.5:
		await process_frame
	_expect(bool(game.get("fail_active")) and not bool(game.get("retrying")) and hint.text == "E  RETRY", "%s: the card holds until RETRY (still up %.1f s after the hit)" % [context, float(game.get("fail_age"))])
	# On touch the hint reads TAP RETRY, USE reads RETRY, and the arrows are gone while the card is up.
	game.set("touch_enabled", true)
	game.call("_refresh_ui")
	var use: Button = game.get_node("CanvasLayer/TouchControls/Use") as Button
	_expect(hint.text == "TAP RETRY" and use.visible and use.text == "RETRY" and not (game.get_node("CanvasLayer/TouchControls/Left") as Control).visible and not (game.get_node("CanvasLayer/TouchControls/Right") as Control).visible, "%s: on touch the hint reads TAP RETRY on the RETRY button, with no arrows (%s, %s)" % [context, hint.text, use.text])
	game.set("touch_enabled", false)
	game.call("_refresh_ui")
	# RETRY: the fade out, the restore and the fade in take 0.6 s, so a press at 0.9 s has control at 1.5 s.
	# Counted in the game's own frames: the press is read in this frame, whose fade takes its first step
	# at the frame's end, and each frame's delta (known as it starts) is added before it runs, so a long
	# frame anywhere (a loaded machine) is counted where the fade counts it.
	var after_press: float = game.get_process_delta_time()
	var longest_frame: float = after_press
	Input.action_press(&"interact")
	await process_frame
	Input.action_release(&"interact")
	var human: M0Actor = game.get_node("Human") as M0Actor
	while not human.controlled and after_press < 3.0:
		var step: float = game.get_process_delta_time()
		after_press += step
		longest_frame = maxf(longest_frame, step)
		await process_frame
	_expect(human.controlled and not bool(game.get("fail_active")) and after_press >= 0.6 - 0.001 and after_press - 0.6 <= longest_frame + 0.001, "%s: control comes back 0.6 s after RETRY, so about 1.5 s after the hit for a press at 0.9 s (%.3f s after the press, frames up to %.3f s)" % [context, after_press, longest_frame])
	_expect(is_equal_approx(MainScript.RETRY_READY_SECONDS + MainScript.RETRY_FADE_OUT_SECONDS + MainScript.RETRY_FADE_IN_SECONDS, 1.5), "%s: 0.9 s + 0.25 s fade out + 0.35 s fade in = 1.5 s" % context)


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
