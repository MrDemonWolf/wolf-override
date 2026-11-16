extends "res://tests/support/game_suite.gd"
## Connection loss pauses only when the disconnected device is the active pad in live play.
## Injected events prove routing and pause state; physical disconnects and motors need device checks.


func _run() -> void:
	check_name = "Controller disconnect"
	var game: Main = await start_game("controller-disconnect", keep_running) as Main
	game.call("_new_game")
	game.call("_finish_intro")
	TextSize.factor = 2.0
	game.call("_apply_text_size")
	var pad: InputEventJoypadButton = controller_button(JOY_BUTTON_DPAD_RIGHT, true)
	pad.device = 7
	Input.parse_input_event(pad)
	await frames(3)
	_expect(game.controller_active and game.impact.rumble_device == 7, "input selects the actual nonzero pad ID")
	Input.joy_connection_changed.emit(9, false)
	_expect(not paused, "another pad disconnecting leaves play running")
	game.crank_latched = true
	Input.action_press(&"interact")
	game.impact.hit_stop(0.09)
	Input.joy_connection_changed.emit(7, false)
	_expect(paused and game.pause_menu.visible and game.controller_disconnected, "losing the active pad pauses play and explains why")
	_expect(not Input.is_action_pressed(&"move_right") and not Input.is_action_pressed(&"interact") and not game.crank_latched and Engine.time_scale == 1.0, "disconnect releases movement, held actions and hit-stop")
	var position: Vector2 = game.human.position
	await frames(3)
	_expect(game.human.position == position, "the engineer stays still while the pad is disconnected")
	Input.joy_connection_changed.emit(7, true)
	await frames(3)
	_expect(paused and game.controller_disconnected, "reconnection never resumes automatically")
	var hint: Label = game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/MenuScroll/MenuMargin/MenuList/PauseHint") as Label
	_expect(hint.text.contains("Controller disconnected"), "Pause keeps the disconnect explanation until explicit resume")
	var scroll: ScrollContainer = hint.get_parent().get_parent().get_parent() as ScrollContainer
	_expect(scroll.get_global_rect().encloses(hint.get_global_rect()) and scroll.get_global_rect().encloses(game.resume_button.get_global_rect()), "at 200%, the disconnect notice and Resume are both fully visible")
	for pressed: bool in [true, false]:
		Input.parse_input_event(key_event(KEY_ESCAPE, pressed))
		await frames(2)
	_expect(not paused and not game.controller_disconnected and not game.controller_active, "keyboard resume clears the notice and switches input mode")
	Input.joy_connection_changed.emit(7, false)
	_expect(not paused, "a stale pad disconnect does not interrupt keyboard play")
	game.call("_return_to_title")
	game.call("_note_input_device", pad)
	Input.joy_connection_changed.emit(7, false)
	_expect(game.title_open and not paused, "disconnect does not open Pause over the title")
	game.call("_show_title_settings")
	Input.joy_connection_changed.emit(7, false)
	_expect(paused and game.settings_menu.visible, "disconnect leaves an existing Settings screen intact")
	pad.pressed = false
	Input.parse_input_event(pad)
	TextSize.factor = 1.0
	await end_game(game)
	finish("Controller disconnect checks passed")
