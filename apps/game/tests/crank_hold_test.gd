extends "res://tests/support/game_suite.gd"
## P0-11 (FEEL-4, FEEL-1, PHONE-10, CTRL-5): the cranks answer on the press frame, the MANUAL BYPASS
## takes about 2 s (Nathanial's decision Q1), and Settings' TOGGLE HOLDS lets one press work a crank to
## the end on the keyboard, a controller and touch alike (all three press the one interact action).
## Played through the game's own input from beats the debug jumps build (DebugActions).

## Where this run's files go: user://crank-hold-test-<pid>, with .cfg and -save.json (the kit's
## spawn_tools_game).
var base: String = ""


func _run() -> void:
	check_name = "Crank hold"
	base = "user://crank-hold-test-%s" % OS.get_process_id()
	remove_tools_files(base)
	await _check_bypass_first_frame()
	await _check_bypass_held_time()
	await _check_bypass_toggle()
	await _check_valve()
	await _check_setting_saved()
	remove_tools_files(base)
	if failures == 0:
		print("Crank hold checks passed")
	quit(1 if failures > 0 else 0)


## Holding interact at the bypass: on the frame Main first sees the press the wheel has turned and the
## ratchet has clicked, long before the first notch at 0.25 s; letting go springs the part turn back.
func _check_bypass_first_frame() -> void:
	# Each check starts from default settings (TOGGLE HOLDS off).
	remove_tools_files(base)
	var game: Node2D = await spawn_tools_game(base, true)
	await _at_bypass(game)
	var handle: BypassHandle = game.get("bypass_handle") as BypassHandle
	var hold: HoldUse = game.get("hold_use") as HoldUse
	var resting: float = handle.wheel.rotation_degrees
	var clicks: Array[int] = await _press_listening(game)
	var answered_at: int = Engine.get_process_frames()
	_expect(hold.holding and hold.started, "Main takes the hold on the first frame interact is down")
	_expect(hold.ticks == 0 and handle.ticks == 0 and hold.progress < BypassHandle.TICK_SECONDS, "no notch has landed yet on the press frame")
	_expect(handle.hold_fraction >= HoldUse.FIRST_FRAME_GIVE and handle.wheel.rotation_degrees - resting >= BypassHandle.TICK_DEGREES * HoldUse.FIRST_FRAME_GIVE - 0.01, "on the press frame the wheel has already turned (%.1f degrees)" % (handle.wheel.rotation_degrees - resting))
	_expect(not clicks.is_empty() and clicks[0] <= answered_at, "and the ratchet clicks on that frame")
	var notched: bool = await wait_until(func() -> bool: return handle.ticks >= 1, 30)
	_expect(notched and handle.wheel.rotation_degrees >= BypassHandle.TICK_DEGREES, "the first notch lands with the wheel past an eighth")
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return not hold.holding, 5)
	await frames(20)
	_expect(handle.hold_fraction == 0.0 and is_equal_approx(handle.wheel.rotation_degrees, BypassHandle.TICK_DEGREES * handle.ticks), "letting go springs the part turn back to the last notch (%.1f degrees, %d notches)" % [handle.wheel.rotation_degrees, handle.ticks])
	await free_tools_game(game)


## Holding interact at the bypass from no notches opens the seal after 2 s of held game time
## (Nathanial's decision Q1), summed from the frames Main runs with the press down, so a slip back to
## the old 3.2 s, or any other length, fails here.
func _check_bypass_held_time() -> void:
	remove_tools_files(base)
	var game: Node2D = await spawn_tools_game(base, true)
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
	var opened: bool = await wait_until(func() -> bool: return state.door_open, 240)
	Input.action_release(&"interact")
	process_frame.disconnect(sum_frame)
	var expected: float = BypassHandle.TICKS_NEEDED * BypassHandle.TICK_SECONDS
	_expect(absf(expected - 2.0) < 0.001, "the bypass is eight notches of a quarter second, 2 s in all")
	_expect(opened and int(game.get("bypass_ticks")) == BypassHandle.TICKS_NEEDED and held[0] >= 2.0 - 0.001 and held[0] <= 2.0 + held[1] + 0.001, "holding interact from no notches opens the seal after 2 s held (%.3f s, longest frame %.3f s, opened %s, notches %d)" % [held[0], held[1], opened, int(game.get("bypass_ticks"))])
	await free_tools_game(game)


## With TOGGLE HOLDS on, one tap of interact at the bypass cranks it to the end with nothing held, and
## the prompt drops HOLD; a move or a pause stops a toggled crank, and a second press stops it too.
func _check_bypass_toggle() -> void:
	# Each check starts from default settings (TOGGLE HOLDS off).
	remove_tools_files(base)
	var game: Node2D = await spawn_tools_game(base, true)
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
	await press_for(&"interact", 2)
	var turning: bool = await wait_until(func() -> bool: return hold.holding, 5)
	_expect(turning and game.get("crank_latched"), "one tap starts the crank turning")
	await frames(20)
	Input.action_press(&"move_left")
	await frames(2)
	Input.action_release(&"move_left")
	await frames(2)
	_expect(not game.get("crank_latched") and not hold.holding, "a move stops a toggled crank")
	(game.get_node("Human") as M0Actor).position.x = float((game.get_script() as Script).get_script_constant_map()["BYPASS_CRANK_X"])
	await frames(2)
	# A tap, then pause: the crank stops while the game is paused and stays stopped after.
	await press_for(&"interact", 2)
	await wait_until(func() -> bool: return hold.holding, 5)
	game.call("_pause_game")
	await frames(3)
	game.call("_resume_game")
	await frames(3)
	_expect(not game.get("crank_latched") and not hold.holding, "pausing stops a toggled crank")
	# A tap, then a second tap: it stops.
	await press_for(&"interact", 2)
	await wait_until(func() -> bool: return hold.holding, 5)
	await frames(4)
	await press_for(&"interact", 2)
	await frames(2)
	_expect(not game.get("crank_latched") and not hold.holding and not state.door_open, "a second press stops it")
	# One tap and hands off: it runs to the end on its own.
	var before: int = int(game.get("bypass_ticks"))
	await press_for(&"interact", 2)
	var started_at: int = Engine.get_physics_frames()
	var opened: bool = await wait_until(func() -> bool: return state.door_open, 240)
	var seconds: float = (Engine.get_physics_frames() - started_at) / 60.0
	_expect(opened and state.route == "fallback" and int(game.get("bypass_ticks")) == BypassHandle.TICKS_NEEDED, "with TOGGLE HOLDS on a single press completes the crank (from %d notches, %.2f s)" % [before, seconds])
	# The latch is let go in Main._process, which a physics frame does not always include on a busy
	# machine; process_frame fires before that frame's _process, so the second one follows a full pass.
	await process_frame
	await process_frame
	_expect(not game.get("crank_latched") and not hold.holding, "and the toggle lets go once the crank is done")
	_expect(not Input.is_action_pressed(&"interact"), "nothing was held down the whole time")
	await free_tools_game(game)


## The junction valve: the press frame turns the wheel and clicks; with TOGGLE HOLDS a single press
## makes all three turns and lights the fuse.
func _check_valve() -> void:
	# Each check starts from default settings (TOGGLE HOLDS off).
	remove_tools_files(base)
	var game: Node2D = await spawn_tools_game(base, true)
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var line: PressureLine = game.get("pressure_line") as PressureLine
	await _at_valve(game)
	var resting: float = room.valve_wheel.rotation_degrees
	var clicks: Array[int] = await _press_listening(game)
	var answered_at: int = Engine.get_process_frames()
	_expect(not clicks.is_empty() and clicks[0] <= answered_at, "the valve's ratchet clicks on the press frame")
	_expect((game.get("hold_use") as HoldUse).started and line.turns == 0 and room.crank_fraction >= HoldUse.FIRST_FRAME_GIVE and room.valve_wheel.rotation_degrees - resting >= 90.0 * HoldUse.FIRST_FRAME_GIVE - 0.01, "the valve wheel turns on the press frame, before its first quarter (%.1f degrees)" % (room.valve_wheel.rotation_degrees - resting))
	Input.action_release(&"interact")
	await frames(20)
	_expect(room.crank_fraction == 0.0 and is_equal_approx(room.valve_wheel.rotation_degrees, 90.0 * line.turns), "letting go springs the valve's part turn back (%.1f degrees, %d turns, fraction %.2f)" % [room.valve_wheel.rotation_degrees, line.turns, room.crank_fraction])
	await free_tools_game(game)
	remove_tools_files(base)
	game = await spawn_tools_game(base, true)
	(game.get("settings_menu") as GameSettings).hold_toggle.button_pressed = true
	line = game.get("pressure_line") as PressureLine
	await _at_valve(game)
	await press_for(&"interact", 2)
	var lit: bool = await wait_until(func() -> bool: return line.state == &"fuse" or line.state == &"charged", 120)
	_expect(lit and line.turns == PressureLine.TURNS_NEEDED, "with TOGGLE HOLDS on a single press makes all three valve turns and lights the fuse")
	await free_tools_game(game)


## TOGGLE HOLDS is saved with the other settings, read back on the next launch, and left alone by
## RESTORE DEFAULT CONTROLS; a malformed value falls back to off.
func _check_setting_saved() -> void:
	remove_tools_files(base)
	var game: Node2D = await spawn_tools_game(base, true)
	var settings: GameSettings = game.get("settings_menu") as GameSettings
	_expect(not settings.hold_toggle.button_pressed and not game.get("hold_toggle"), "TOGGLE HOLDS starts off")
	settings.hold_toggle.button_pressed = true
	_expect(GameSettings.boolean(GameSettings.load_config(_settings_path()), "controls", "hold_toggle", false), "turning it on saves it to the settings file")
	settings.reset_controls()
	_expect(settings.hold_toggle.button_pressed and GameSettings.boolean(GameSettings.load_config(_settings_path()), "controls", "hold_toggle", false), "RESTORE DEFAULT CONTROLS leaves it as it is")
	await free_tools_game(game)
	game = await spawn_tools_game(base, true)
	_expect((game.get("settings_menu") as GameSettings).hold_toggle.button_pressed and game.get("hold_toggle"), "the next launch reads it back")
	await free_tools_game(game)
	var config: ConfigFile = GameSettings.load_config(_settings_path())
	config.set_value("controls", "hold_toggle", "yes")
	config.save(_settings_path())
	game = await spawn_tools_game(base, true)
	_expect(not (game.get("settings_menu") as GameSettings).hold_toggle.button_pressed and not game.get("hold_toggle"), "a malformed saved value falls back to off")
	await free_tools_game(game)


## The corridor after a rushed relay: WOLF refused, the breaker armed, the engineer at the bypass's
## crank spot with the handle already touched (venting), the way play leaves them.
func _at_bypass(game: Node2D) -> void:
	var actions: DebugActions = (game.get("debug_tools") as DebugTools).actions
	actions.jump(&"relay_question")
	await frames(5)
	game.call("_answer_choice", 2)
	await frames(5)
	game.call("debug_interact")
	await frames(5)
	var crank_x: float = float((game.get_script() as Script).get_script_constant_map()["BYPASS_CRANK_X"])
	game.call("debug_place", crank_x, 490.0)
	await frames(5)


## The Service Junction from autosave A: the breaker armed, the engineer at the valve's crank spot.
func _at_valve(game: Node2D) -> void:
	var actions: DebugActions = (game.get("debug_tools") as DebugTools).actions
	actions.jump(&"junction_a")
	await frames(5)
	game.call("debug_place", JunctionRoom.BREAKER_X + 40.0, JunctionRoom.WOLF_CLEAR_X)
	await frames(3)
	game.call("debug_interact")
	await frames(3)
	var crank_x: float = float((game.get_script() as Script).get_script_constant_map()["VALVE_CRANK_X"])
	game.call("debug_place", crank_x, JunctionRoom.WOLF_CLEAR_X)
	await frames(3)


func _settings_path() -> String:
	return base + ".cfg"


## Presses interact (and leaves it held) while listening for the ratchet's clank, and returns once
## Main's first frame with interact down has run: process_frame fires before the nodes process, so
## the second one resumes after that frame. Returns the process frame of every clank the bank starts
## from the press on; the array keeps filling while the game runs.
func _press_listening(game: Node2D) -> Array[int]:
	var clicks: Array[int] = []
	(game.get("sfx_bank") as SfxBank).clip_started.connect(func(clip: StringName) -> void:
		if clip == &"clank":
			clicks.append(Engine.get_process_frames()))
	Input.action_press(&"interact")
	await process_frame
	await process_frame
	return clicks
