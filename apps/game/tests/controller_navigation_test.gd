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
			press = _axis(JOY_AXIS_LEFT_Y, 1.0)
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
	await _check_scrolling(game)
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


## The right stick scrolls the open Settings page steadily and each trigger pull moves it one page,
## through native pad events; focus and bindings stay as they were.
func _check_scrolling(game: Main) -> void:
	var menu: GameSettings = game.settings_menu
	menu.select_tab(2)
	await settle(4)
	(menu.binding_buttons["move_left_keyboard"] as Button).grab_focus()
	await settle(2)
	var page: ScrollContainer = menu.pages[2] as ScrollContainer
	var focused: Control = root.gui_get_focus_owner()
	var longest: int = int(page.get_v_scroll_bar().max_value - page.get_v_scroll_bar().page)
	_expect(game.call("_menu_scroll_target") == page and longest > 0, "the Controls page is the long list a pad scrolls (%d px to scroll)" % longest)
	page.scroll_vertical = 0
	Input.parse_input_event(_axis(JOY_AXIS_RIGHT_Y, 1.0))
	await wait_real_seconds(0.4)
	var scrolled: int = page.scroll_vertical
	_expect(scrolled > 0 and scrolled <= ceili(MenuRepeat.SCROLL_SPEED * 0.6) and root.gui_get_focus_owner() == focused, "holding the right stick down scrolls the page at the shared speed without moving focus (%d px)" % scrolled)
	Input.parse_input_event(_axis(JOY_AXIS_RIGHT_Y, 0.0))
	await settle(2)
	scrolled = page.scroll_vertical
	await wait_real_seconds(0.2)
	_expect(page.scroll_vertical == scrolled, "centring the stick stops the scroll")
	page.scroll_vertical = 0
	var step: int = mini(roundi(page.size.y * MenuRepeat.PAGE_FRACTION), longest)
	Input.parse_input_event(_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0))
	await settle(2)
	_expect(page.scroll_vertical == step, "one RT pull moves one page down (%d of %d px)" % [page.scroll_vertical, step])
	await wait_real_seconds(0.3)
	_expect(page.scroll_vertical == step, "a held trigger pages once")
	Input.parse_input_event(_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0))
	Input.parse_input_event(_axis(JOY_AXIS_TRIGGER_LEFT, 1.0))
	await settle(2)
	Input.parse_input_event(_axis(JOY_AXIS_TRIGGER_LEFT, 0.0))
	await settle(2)
	_expect(page.scroll_vertical == 0 and root.gui_get_focus_owner() == focused and menu.capture_action.is_empty(), "LT moves the page back up; focus and bindings are untouched")


## A native pad axis event for [param axis] at [param value] (-1 to 1; triggers 0 to 1) on device 0.
func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
	motion.axis = axis
	motion.axis_value = value
	return motion
