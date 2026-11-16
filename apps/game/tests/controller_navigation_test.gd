extends "res://tests/support/game_suite.gd"
## Native held navigation in the real Settings list; presses enter through Input, never direct GUI calls.


## A held direction must move more than once, then stop on release without activating any binding.
func _run() -> void:
	check_name = "Controller navigation"
	var game: Main = await start_game("controller-navigation", keep_running) as Main
	(game.get_node("CanvasLayer/TitleScreen/MenuScroll/MenuMargin/MenuList/SettingsButton") as Button).pressed.emit()
	await settle(12)
	var menu: GameSettings = game.settings_menu
	menu.select_tab(2)
	await settle(4)
	for stick: bool in [false, true]:
		var first: Button = menu.binding_buttons["move_left_keyboard"]
		first.grab_focus()
		await settle(2)
		var visited: Array[Control] = []
		var observe: Callable = func(control: Control) -> void: visited.append(control)
		root.gui_focus_changed.connect(observe)
		var press: InputEvent = controller_button(JOY_BUTTON_DPAD_DOWN, true)
		if stick:
			var motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
			motion.axis = JOY_AXIS_LEFT_Y
			motion.axis_value = 1.0
			press = motion
		Input.parse_input_event(press)
		await wait_real_seconds(1.0)
		var release: InputEvent = press.duplicate()
		if release is InputEventJoypadMotion:
			release.axis_value = 0.0
		else:
			(release as InputEventJoypadButton).pressed = false
		Input.parse_input_event(release)
		await settle(2)
		var moves: int = visited.size()
		_expect(moves >= 3, "holding %s navigates repeatedly without repeated injected events (observed %d moves)" % ["stick" if stick else "D-pad", moves])
		await wait_real_seconds(0.3)
		_expect(visited.size() == moves, "releasing the direction stops navigation")
		_expect(menu.capture_action.is_empty(), "navigation never starts a rebind")
		root.gui_focus_changed.disconnect(observe)
	await _check_interruptions(game)
	await end_game(game)
	finish("Controller navigation checks passed")


## A held direction cannot leak across capture, page, application focus or device-disconnect boundaries.
func _check_interruptions(game: Main) -> void:
	var menu: GameSettings = game.settings_menu
	for boundary: String in ["capture", "page", "focus", "disconnect"]:
		menu.select_tab(2)
		await settle(4)
		(menu.binding_buttons["move_left_keyboard"] as Button).grab_focus()
		Input.parse_input_event(controller_button(JOY_BUTTON_DPAD_DOWN, true))
		await wait_real_seconds(0.1)
		match boundary:
			"capture": menu.begin_capture(&"interact", "controller")
			"page": menu.select_tab(1)
			"focus": game.menu_repeat.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
			"disconnect": Input.joy_connection_changed.emit(0, false)
		await settle(4)
		var focused: Control = root.gui_get_focus_owner()
		await wait_real_seconds(0.55)
		_expect(root.gui_get_focus_owner() == focused, "%s stops a previously held direction" % boundary)
		if boundary == "capture":
			menu.cancel_capture()
		elif boundary == "focus":
			game.menu_repeat.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		elif boundary == "disconnect":
			Input.joy_connection_changed.emit(0, true)
		await settle(4)
		focused = root.gui_get_focus_owner()
		await wait_real_seconds(0.55)
		_expect(root.gui_get_focus_owner() == focused, "%s recovery requires a fresh press" % boundary)
		Input.parse_input_event(controller_button(JOY_BUTTON_DPAD_DOWN, false))
		await settle(2)
