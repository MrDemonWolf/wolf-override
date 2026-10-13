extends SceneTree
## P0-11 (FEEL-4, FEEL-1, PHONE-10, CTRL-5): the cranks answer on the press frame, the MANUAL BYPASS
## takes about 2 s (Nathanial's decision Q1), and Settings' TOGGLE HOLDS lets one press work a crank to
## the end on the keyboard, a controller and touch alike (all three press the one interact action).
## Played through the game's own input from beats the debug jumps build (DebugActions).

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")

var failures: int = 0
var base: String = ""


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	base = "user://crank-hold-test-%s" % OS.get_process_id()
	_clean()
	await _check_bypass_first_frame()
	await _check_bypass_held_time()
	await _check_bypass_toggle()
	await _check_valve()
	await _check_setting_saved()
	_clean()
	if failures == 0:
		print("Crank hold checks passed")
	quit(1 if failures > 0 else 0)


## Holding interact at the bypass: on the frame Main first sees the press the wheel has turned and the
## ratchet has clicked, long before the first notch at 0.25 s; letting go springs the part turn back.
func _check_bypass_first_frame() -> void:
	# Each check starts from default settings (TOGGLE HOLDS off).
	_clean()
	var game: Node2D = await _spawn()
	await _at_bypass(game)
	var handle: BypassHandle = game.get("bypass_handle") as BypassHandle
	var hold: HoldUse = game.get("hold_use") as HoldUse
	var resting: float = handle.wheel.rotation_degrees
	var clicks: Array[int] = []
	(game.get("sfx_bank") as SfxBank).clip_started.connect(func(clip: StringName) -> void:
		if clip == &"clank":
			clicks.append(Engine.get_process_frames()))
	Input.action_press(&"interact")
	# process_frame fires before the nodes process: the second one resumes here after Main's first
	# frame with interact down.
	await process_frame
	await process_frame
	var answered_at: int = Engine.get_process_frames()
	_expect(hold.holding and hold.started, "Main takes the hold on the first frame interact is down")
	_expect(hold.ticks == 0 and handle.ticks == 0 and hold.progress < BypassHandle.TICK_SECONDS, "no notch has landed yet on the press frame")
	_expect(handle.hold_fraction >= HoldUse.FIRST_FRAME_GIVE and handle.wheel.rotation_degrees - resting >= BypassHandle.TICK_DEGREES * HoldUse.FIRST_FRAME_GIVE - 0.01, "on the press frame the wheel has already turned (%.1f degrees)" % (handle.wheel.rotation_degrees - resting))
	_expect(not clicks.is_empty() and clicks[0] <= answered_at, "and the ratchet clicks on that frame")
	var notched: bool = await _until(func() -> bool: return handle.ticks >= 1, 30)
	_expect(notched and handle.wheel.rotation_degrees >= BypassHandle.TICK_DEGREES, "the first notch lands with the wheel past an eighth")
	Input.action_release(&"interact")
	await _until(func() -> bool: return not hold.holding, 5)
	await _frames(20)
	_expect(handle.hold_fraction == 0.0 and is_equal_approx(handle.wheel.rotation_degrees, BypassHandle.TICK_DEGREES * handle.ticks), "letting go springs the part turn back to the last notch (%.1f degrees, %d notches)" % [handle.wheel.rotation_degrees, handle.ticks])
	await _free(game)


## Holding interact at the bypass from no notches opens the seal after 2 s of held game time
## (Nathanial's decision Q1), summed from the frames Main runs with the press down, so a slip back to
## the old 3.2 s, or any other length, fails here.
func _check_bypass_held_time() -> void:
	_clean()
	var game: Node2D = await _spawn()
	await _at_bypass(game)
	var state: M0State = game.get("state") as M0State
	var handle: BypassHandle = game.get("bypass_handle") as BypassHandle
	_expect(handle.ticks == 0 and int(game.get("bypass_ticks")) == 0 and not state.door_open, "the bypass starts from no notches")
	var held: Array[float] = [0.0, 0.0]
	var counting: Array[bool] = [true]
	# process_frame fires before the nodes process, with that frame's delta already set: add the delta
	# of every frame Main runs with interact down, up to the frame the last notch lands (the seal can
	# open on that frame, and the wait below can then end before another frame begins).
	var sum_frame: Callable = func() -> void:
		if not counting[0]:
			return
		if int(game.get("bypass_ticks")) >= BypassHandle.TICKS_NEEDED:
			counting[0] = false
			return
		var delta: float = root.get_process_delta_time()
		held[0] += delta
		held[1] = maxf(held[1], delta)
	Input.action_press(&"interact")
	process_frame.connect(sum_frame)
	var opened: bool = await _until(func() -> bool: return state.door_open, 240)
	Input.action_release(&"interact")
	process_frame.disconnect(sum_frame)
	var expected: float = BypassHandle.TICKS_NEEDED * BypassHandle.TICK_SECONDS
	_expect(absf(expected - 2.0) < 0.001, "the bypass is eight notches of a quarter second, 2 s in all")
	_expect(opened and int(game.get("bypass_ticks")) == BypassHandle.TICKS_NEEDED and held[0] >= 2.0 - 0.001 and held[0] <= 2.0 + held[1] + 0.001, "holding interact from no notches opens the seal after 2 s held (%.3f s, longest frame %.3f s, opened %s, notches %d)" % [held[0], held[1], opened, int(game.get("bypass_ticks"))])
	await _free(game)


## With TOGGLE HOLDS on, one tap of interact at the bypass cranks it to the end with nothing held, and
## the prompt drops HOLD; a move or a pause stops a toggled crank, and a second press stops it too.
func _check_bypass_toggle() -> void:
	# Each check starts from default settings (TOGGLE HOLDS off).
	_clean()
	var game: Node2D = await _spawn()
	var settings: GameSettings = game.get("settings_menu") as GameSettings
	settings.hold_toggle.button_pressed = true
	_expect(game.get("hold_toggle"), "turning TOGGLE HOLDS on reaches the game")
	await _at_bypass(game)
	game.call("_refresh_ui")
	var shown: String = (game.get_node("CanvasLayer/ContextHint/Text") as Label).text
	_expect(str(game.call("_context_hint")).begins_with("HOLD E:") and shown.begins_with("E: crank"), "with TOGGLE HOLDS on the bypass prompt on screen drops HOLD (%s)" % shown)
	var state: M0State = game.get("state") as M0State
	var hold: HoldUse = game.get("hold_use") as HoldUse
	# A tap, then a move: the toggled crank stops and the turns made stay.
	await _tap(&"interact")
	var turning: bool = await _until(func() -> bool: return hold.holding, 5)
	_expect(turning and game.get("crank_latched"), "one tap starts the crank turning")
	await _frames(20)
	Input.action_press(&"move_left")
	await _frames(2)
	Input.action_release(&"move_left")
	await _frames(2)
	_expect(not game.get("crank_latched") and not hold.holding, "a move stops a toggled crank")
	(game.get_node("Human") as M0Actor).position.x = float((game.get_script() as Script).get_script_constant_map()["BYPASS_CRANK_X"])
	await _frames(2)
	# A tap, then pause: the crank stops while the game is paused and stays stopped after.
	await _tap(&"interact")
	await _until(func() -> bool: return hold.holding, 5)
	game.call("_pause_game")
	await _frames(3)
	game.call("_resume_game")
	await _frames(3)
	_expect(not game.get("crank_latched") and not hold.holding, "pausing stops a toggled crank")
	# A tap, then a second tap: it stops.
	await _tap(&"interact")
	await _until(func() -> bool: return hold.holding, 5)
	await _frames(4)
	await _tap(&"interact")
	await _frames(2)
	_expect(not game.get("crank_latched") and not hold.holding and not state.door_open, "a second press stops it")
	# One tap and hands off: it runs to the end on its own.
	var before: int = int(game.get("bypass_ticks"))
	await _tap(&"interact")
	var started_at: int = Engine.get_physics_frames()
	var opened: bool = await _until(func() -> bool: return state.door_open, 240)
	var seconds: float = (Engine.get_physics_frames() - started_at) / 60.0
	_expect(opened and state.route == "fallback" and int(game.get("bypass_ticks")) == BypassHandle.TICKS_NEEDED, "with TOGGLE HOLDS on a single press completes the crank (from %d notches, %.2f s)" % [before, seconds])
	await _frames(2)
	_expect(not game.get("crank_latched") and not hold.holding, "and the toggle lets go once the crank is done")
	_expect(not Input.is_action_pressed(&"interact"), "nothing was held down the whole time")
	await _free(game)


## The junction valve: the press frame turns the wheel and clicks; with TOGGLE HOLDS a single press
## makes all three turns and lights the fuse.
func _check_valve() -> void:
	# Each check starts from default settings (TOGGLE HOLDS off).
	_clean()
	var game: Node2D = await _spawn()
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var line: PressureLine = game.get("pressure_line") as PressureLine
	await _at_valve(game)
	var resting: float = room.valve_wheel.rotation_degrees
	var clicks: Array[int] = []
	(game.get("sfx_bank") as SfxBank).clip_started.connect(func(clip: StringName) -> void:
		if clip == &"clank":
			clicks.append(Engine.get_process_frames()))
	Input.action_press(&"interact")
	await process_frame
	await process_frame
	var answered_at: int = Engine.get_process_frames()
	_expect(not clicks.is_empty() and clicks[0] <= answered_at, "the valve's ratchet clicks on the press frame")
	_expect((game.get("hold_use") as HoldUse).started and line.turns == 0 and room.crank_fraction >= HoldUse.FIRST_FRAME_GIVE and room.valve_wheel.rotation_degrees - resting >= 90.0 * HoldUse.FIRST_FRAME_GIVE - 0.01, "the valve wheel turns on the press frame, before its first quarter (%.1f degrees)" % (room.valve_wheel.rotation_degrees - resting))
	Input.action_release(&"interact")
	await _frames(20)
	_expect(room.crank_fraction == 0.0 and is_equal_approx(room.valve_wheel.rotation_degrees, 90.0 * line.turns), "letting go springs the valve's part turn back (%.1f degrees, %d turns, fraction %.2f)" % [room.valve_wheel.rotation_degrees, line.turns, room.crank_fraction])
	await _free(game)
	_clean()
	game = await _spawn()
	(game.get("settings_menu") as GameSettings).hold_toggle.button_pressed = true
	line = game.get("pressure_line") as PressureLine
	await _at_valve(game)
	await _tap(&"interact")
	var lit: bool = await _until(func() -> bool: return line.state == &"fuse" or line.state == &"charged", 120)
	_expect(lit and line.turns == PressureLine.TURNS_NEEDED, "with TOGGLE HOLDS on a single press makes all three valve turns and lights the fuse")
	await _free(game)


## TOGGLE HOLDS is saved with the other settings, read back on the next launch, and left alone by
## RESTORE DEFAULT CONTROLS; a malformed value falls back to off.
func _check_setting_saved() -> void:
	_clean()
	var game: Node2D = await _spawn()
	var settings: GameSettings = game.get("settings_menu") as GameSettings
	_expect(not settings.hold_toggle.button_pressed and not game.get("hold_toggle"), "TOGGLE HOLDS starts off")
	settings.hold_toggle.button_pressed = true
	_expect(GameSettings.boolean(GameSettings.load_config(_settings_path()), "controls", "hold_toggle", false), "turning it on saves it to the settings file")
	settings.reset_controls()
	_expect(settings.hold_toggle.button_pressed and GameSettings.boolean(GameSettings.load_config(_settings_path()), "controls", "hold_toggle", false), "RESTORE DEFAULT CONTROLS leaves it as it is")
	await _free(game)
	game = await _spawn()
	_expect((game.get("settings_menu") as GameSettings).hold_toggle.button_pressed and game.get("hold_toggle"), "the next launch reads it back")
	await _free(game)
	var config: ConfigFile = GameSettings.load_config(_settings_path())
	config.set_value("controls", "hold_toggle", "yes")
	config.save(_settings_path())
	game = await _spawn()
	_expect(not (game.get("settings_menu") as GameSettings).hold_toggle.button_pressed and not game.get("hold_toggle"), "a malformed saved value falls back to off")
	await _free(game)


## The corridor after a rushed relay: WOLF refused, the breaker armed, the engineer at the bypass's
## crank spot with the handle already touched (venting), the way play leaves them.
func _at_bypass(game: Node2D) -> void:
	var actions: DebugActions = (game.get("debug_tools") as DebugTools).actions
	actions.jump(&"relay_question")
	await _frames(5)
	game.call("_answer_choice", 2)
	await _frames(5)
	game.call("debug_interact")
	await _frames(5)
	var crank_x: float = float((game.get_script() as Script).get_script_constant_map()["BYPASS_CRANK_X"])
	game.call("debug_place", crank_x, 490.0)
	await _frames(5)


## The Service Junction from autosave A: the breaker armed, the engineer at the valve's crank spot.
func _at_valve(game: Node2D) -> void:
	var actions: DebugActions = (game.get("debug_tools") as DebugTools).actions
	actions.jump(&"junction_a")
	await _frames(5)
	game.call("debug_place", JunctionRoom.BREAKER_X + 40.0, JunctionRoom.WOLF_CLEAR_X)
	await _frames(3)
	game.call("debug_interact")
	await _frames(3)
	var crank_x: float = float((game.get_script() as Script).get_script_constant_map()["VALVE_CRANK_X"])
	game.call("debug_place", crank_x, JunctionRoom.WOLF_CLEAR_X)
	await _frames(3)


func _spawn() -> Node2D:
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("settings_path", _settings_path())
	game.set("save_path", base + "-save.json")
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	await process_frame
	(game.get("debug_tools") as DebugTools).debug_build = true
	return game


func _free(game: Node2D) -> void:
	for action: StringName in [&"interact", &"move_left", &"move_right"]:
		Input.action_release(action)
	paused = false
	game.queue_free()
	await process_frame
	await process_frame


func _settings_path() -> String:
	return base + ".cfg"


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)


## Waits in physics frames, 1/60 s of game time apart, as the other scene suites do (headless process
## frames run as fast as they can).
func _frames(count: int) -> void:
	for _i: int in count:
		await physics_frame


func _until(condition: Callable, frames: int) -> bool:
	for _i: int in frames:
		await physics_frame
		if condition.call():
			return true
	return false


func _clean() -> void:
	for path: String in [_settings_path(), base + "-save.json", base + "-save.json.tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("Crank hold check failed: " + label)
