extends SceneTree

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var path: String = "user://ui-controls-test-%s.cfg" % OS.get_process_id()
	var old_fps: int = Engine.max_fps
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("settings_path", path)
	game.set("save_path", "%s-save.json" % path)
	root.add_child(game)
	var changelog: Button = game.get_node("CanvasLayer/TitleScreen/ChangelogButton") as Button
	_expect(changelog.pressed.is_connected(Callable(game, "_open_changelog")) and str(game.CHANGELOG_URL) == "https://wolfoverride.mrdemonwolf.dev/docs/changelog/" and str(game.SITE_URL).begins_with("https://wolfoverride.mrdemonwolf.dev"), "title changelog points to the public development updates")
	_expect(_has_button(&"interact", JOY_BUTTON_A) and _has_button(&"pause_game", JOY_BUTTON_START), "gamepad action buttons are mapped")
	_expect(_has_button(&"move_left", JOY_BUTTON_DPAD_LEFT) and _has_button(&"move_right", JOY_BUTTON_DPAD_RIGHT), "gamepad D-pad movement is mapped")
	var project_theme: Theme = ThemeDB.get_project_theme()
	var ring: StyleBoxFlat = project_theme.get_stylebox("focus", "Button") as StyleBoxFlat if project_theme != null and project_theme.has_stylebox("focus", "Button") else null
	_expect(ring != null and ring.border_color.is_equal_approx(Color("#8de5f5")) and ring.border_width_left == 2 and ring.expand_margin_left == 0.0 and ring.bg_color.a == 0.0, "the shared theme gives buttons an inset cyan focus ring")
	var title_new_game: Button = game.get_node("CanvasLayer/TitleScreen/NewGameButton") as Button
	var shared_settings: GameSettings = game.get_node("CanvasLayer/PauseOverlay/Panel/SettingsMenu") as GameSettings
	_expect(title_new_game.get_theme_stylebox("focus") == ring and shared_settings.vsync.get_theme_stylebox("focus") == ring and (shared_settings.volumes["Music"] as HSlider).get_theme_stylebox("focus") == ring and shared_settings.deadzone.get_theme_stylebox("focus") == ring, "title and Settings controls, sliders included, share the theme focus ring")
	var tab_ring: StyleBoxFlat = shared_settings.tabs.get_theme_stylebox("tab_focus") as StyleBoxFlat
	_expect(tab_ring != null and tab_ring.border_width_left == 2 and tab_ring.expand_margin_left == -4.0, "settings tabs keep their inset focus ring")
	var resume_focus: StyleBoxFlat = (game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/ResumeButton") as Button).get_theme_stylebox("focus") as StyleBoxFlat
	var resume_normal: StyleBoxFlat = (game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/ResumeButton") as Button).get_theme_stylebox("normal") as StyleBoxFlat
	_expect(resume_focus != null and resume_focus.border_width_left > resume_normal.border_width_left and resume_focus.bg_color.a == 1.0, "pause-menu focus is heavier than the pause-menu button border")
	for bordered_path: String in ["CanvasLayer/PauseOverlay/Panel/SettingsMenu/BackButton", "CanvasLayer/PauseOverlay/Panel/SettingsMenu/FPSOptions", "CanvasLayer/PauseOverlay/Panel/SettingsMenu/ResolutionOptions"]:
		var bordered: Button = game.get_node(bordered_path) as Button
		_expect(bordered.get_theme_stylebox("focus") == resume_focus and (bordered.get_theme_stylebox("normal") as StyleBoxFlat).border_width_left < resume_focus.border_width_left, "%s uses the heavier focus style over its cyan border" % bordered.name)
	game.call("_new_game")
	game.call("_finish_intro")
	game.set("touch_enabled", true)
	game.call("_refresh_ui")
	var touch: Control = game.get_node("CanvasLayer/TouchControls") as Control
	var right: Button = touch.get_node("Right") as Button
	var use: Button = touch.get_node("Use") as Button
	_expect(touch.visible and right.visible and use.visible, "touch movement and use appear during play")
	right.button_down.emit()
	_expect(Input.is_action_pressed(&"move_right"), "held touch direction drives the movement action")
	game.call("_process", 0.016)
	right.button_up.emit()
	_expect(not Input.is_action_pressed(&"move_right") and game.get("tutorial_step") == 1, "releasing touch stops movement and advances the tutorial")
	await process_frame
	use.button_down.emit()
	await process_frame
	use.button_up.emit()
	_expect(game.get("tutorial_step") == 2 and not (game.get_node("CanvasLayer/TutorialPrompt") as ColorRect).visible, "touch use reads the display and clears the tutorial")
	game.set("waiting_for_choice", true)
	game.call("_refresh_ui")
	var first_choice: Button = touch.get_node("Choice1") as Button
	var second_choice: Button = touch.get_node("Choice2") as Button
	_expect(first_choice.size.y == 76.0 and second_choice.position.x > first_choice.position.x, "touch choices retain large side-by-side targets")
	var controller_event: InputEventJoypadButton = InputEventJoypadButton.new()
	controller_event.button_index = JOY_BUTTON_RIGHT_SHOULDER
	controller_event.pressed = true
	game.call("_input", controller_event)
	_expect(first_choice.size.y == 40.0 and second_choice.position.y > first_choice.position.y and first_choice.text.begins_with("X  ") and second_choice.text.begins_with("Y  "), "controller choices use compact stacked cards with action prompts")
	_expect(not right.visible and not use.visible, "controller input hides mobile touch movement controls")
	var touch_event: InputEventScreenTouch = InputEventScreenTouch.new()
	touch_event.pressed = true
	game.call("_input", touch_event)
	_expect(first_choice.size.y == 76.0 and first_choice.text.begins_with("1  "), "touch input restores large choice targets")
	game.set("waiting_for_choice", false)
	game.call("_refresh_ui")
	game.call("_pause_game")
	var overlay: PauseOverlay = game.get_node("CanvasLayer/PauseOverlay") as PauseOverlay
	_expect(paused and overlay.visible, "pause freezes the game and opens the menu")
	_expect(root.gui_get_focus_owner() == null, "pause opened in touch mode leaves no focused button")
	await _send_key(KEY_DOWN, true)
	await _send_key(KEY_DOWN, false)
	_expect((game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/ResumeButton") as Button).has_focus(), "the first arrow press in a touch-opened pause menu focuses Resume without moving past it")
	(game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/SettingsButton") as Button).pressed.emit()
	_expect((game.get_node("CanvasLayer/PauseOverlay/Panel/SettingsMenu") as Control).visible, "settings open while paused")
	var fps: OptionButton = game.get_node("CanvasLayer/PauseOverlay/Panel/SettingsMenu/FPSOptions") as OptionButton
	fps.select(0)
	game.call("_on_fps_selected", 0)
	var config: ConfigFile = ConfigFile.new()
	_expect(config.load(path) == OK and Engine.max_fps == 30 and config.get_value("video", "fps_limit") == 30, "FPS cap applies and persists")
	var settings_menu: GameSettings = game.get_node("CanvasLayer/PauseOverlay/Panel/SettingsMenu") as GameSettings
	settings_menu.begin_capture(&"interact", "keyboard")
	await _send_escape(true)
	await _send_escape(false)
	_expect(paused and overlay.visible and settings_menu.capture_action.is_empty(), "Escape cancels a key rebind without resuming")
	await _send_escape(true)
	await _send_escape(false)
	_expect(paused and overlay.visible and (game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu") as Control).visible and not settings_menu.visible, "Escape in Settings returns to the pause menu")
	await _send_escape(true)
	await _send_escape(false)
	await process_frame
	_expect(not paused and not overlay.visible and (game.get_node("Human") as M0Actor).controlled, "physical Escape resumes and does not re-pause on the same press")
	await _send_escape(true)
	await _send_escape(false)
	_expect(paused and overlay.visible, "physical Escape pauses during play")
	Input.parse_input_event(_controller_button(JOY_BUTTON_START, true))
	await process_frame
	Input.parse_input_event(_controller_button(JOY_BUTTON_START, false))
	await process_frame
	await process_frame
	_expect(not paused and not overlay.visible, "controller Start resumes without re-pausing")
	var menu: GameSettings = game.get("settings_menu") as GameSettings
	menu.call("_replace_binding", &"interact", "controller", _controller_button(JOY_BUTTON_B, false))
	menu.call("_replace_binding", &"choice_2", "controller", _controller_button(JOY_BUTTON_A, false))
	game.call("_new_game")
	await process_frame
	Input.parse_input_event(_controller_button(JOY_BUTTON_B, true))
	await process_frame
	await process_frame
	_expect(game.get("intro_active") and game.get("intro_step") == 1, "remapped B continues the intro instead of triggering native menu cancel")
	Input.parse_input_event(_controller_button(JOY_BUTTON_B, false))
	await process_frame
	game.call("_finish_intro")
	(game.get_node("Human") as M0Actor).position.x = 350.0
	game.call("_interact")
	first_choice.grab_focus()
	await process_frame
	Input.parse_input_event(_controller_button(JOY_BUTTON_A, true))
	await process_frame
	_expect((game.get("state") as M0State).memory.get("choice_id") == M0State.PRESS and not game.get("waiting_for_choice"), "remapped A selects the second response even when native menu focus is on the first")
	Input.parse_input_event(_controller_button(JOY_BUTTON_A, false))
	await process_frame
	menu.reset_controls()
	game.call("_pause_game")
	(game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton") as Button).pressed.emit()
	var new_game: Button = game.get_node("CanvasLayer/TitleScreen/NewGameButton") as Button
	_expect(not paused and game.get("title_open") and not overlay.visible and not (game.get_node("Human") as M0Actor).controlled and new_game.has_focus(), "Return to Title hides the pause menu and focuses New Game with actor control stopped")
	_expect((game.get_node("CanvasLayer/TitleScreen/ContinueButton") as Button).disabled, "returning without a saved checkpoint keeps Continue disabled")
	new_game.pressed.emit()
	_expect(game.get("intro_active") and (game.get("state") as M0State).memory.is_empty(), "New Game from the returned title clears the previous remembered choice")
	# Android Back walks out of menus one step at a time and pauses play instead of quitting.
	game.call("_new_game")
	game.call("_finish_intro")
	await process_frame
	game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(paused and overlay.visible, "Back during play opens Pause")
	(game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/SettingsButton") as Button).pressed.emit()
	game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(paused and (game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu") as Control).visible and not settings_menu.visible, "Back in Settings returns to Pause")
	game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(not paused and not overlay.visible, "Back in Pause resumes play")
	game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(paused and overlay.visible, "losing app focus during play pauses the game")
	game.call("_resume_game")
	# Pause during the opening is a real pause; skipping is an explicit menu choice.
	game.call("_new_game")
	await process_frame
	await _send_escape(true)
	await _send_escape(false)
	var title_button: Button = game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton") as Button
	_expect(paused and game.get("intro_active") and title_button.text == "SKIP OPENING", "Pause during the opening keeps the opening and offers Skip Opening")
	title_button.pressed.emit()
	_expect(not paused and not game.get("intro_active"), "Skip Opening resumes into play")
	# A choice left open when returning to the title cannot be committed from the title.
	(game.get_node("Human") as M0Actor).position.x = 350.0
	game.call("_interact")
	game.call("_pause_game")
	title_button.pressed.emit()
	Input.parse_input_event(_controller_button(JOY_BUTTON_X, true))
	await process_frame
	Input.parse_input_event(_controller_button(JOY_BUTTON_X, false))
	await process_frame
	_expect(game.get("title_open") and not game.get("waiting_for_choice") and (game.get("state") as M0State).memory.is_empty(), "returning to the title drops a pending choice")
	# A controller picked up on a touch device starts from a sensible menu control, not a stray press.
	game.set("controller_active", false)
	root.gui_release_focus()
	Input.parse_input_event(_controller_button(JOY_BUTTON_A, true))
	await process_frame
	Input.parse_input_event(_controller_button(JOY_BUTTON_A, false))
	await process_frame
	_expect(game.get("title_open") and game.get("controller_active") and new_game.has_focus(), "the first controller press on an unfocused touch title focuses New Game without starting a game")
	Engine.max_fps = old_fps
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game.queue_free()
	await process_frame
	if failures == 0:
		print("UI and controls checks passed")
	quit(1 if failures > 0 else 0)


func _has_button(action: StringName, index: JoyButton) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == index:
			return true
	return false


func _controller_button(index: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = pressed
	return event


func _send_escape(pressed: bool) -> void:
	await _send_key(KEY_ESCAPE, pressed)


func _send_key(code: Key, pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("UI and controls check failed: " + label)
