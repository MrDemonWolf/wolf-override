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
	# The title CHANGELOG button opens the exported changelog in the game; the online button keeps the website link.
	var changelog: Button = game.get_node("CanvasLayer/TitleScreen/ChangelogButton") as Button
	var changelog_screen: ColorRect = game.get_node("CanvasLayer/TitleScreen/ChangelogScreen") as ColorRect
	var changelog_body: RichTextLabel = changelog_screen.get_node("ChangelogBody") as RichTextLabel
	var changelog_back: Button = changelog_screen.get_node("ChangelogBackButton") as Button
	var changelog_online: Button = changelog_screen.get_node("ChangelogOnlineButton") as Button
	var title_logo: Label = game.get_node("CanvasLayer/TitleScreen/GameTitle") as Label
	_expect(changelog.pressed.is_connected(Callable(game, "_show_changelog")) and changelog_online.pressed.is_connected(Callable(game, "_open_changelog")) and str(game.CHANGELOG_URL) == "https://wolfoverride.mrdemonwolf.dev/docs/changelog/" and str(game.SITE_URL).begins_with("https://wolfoverride.mrdemonwolf.dev"), "title changelog opens in the game and the online button points to the public development updates")
	var changelog_text: String = str(game.get("changelog_text"))
	var first_heading: String = changelog_text.get_slice("\n", 0)
	_expect(first_heading.begins_with("== ") and first_heading.ends_with(" ==") and first_heading.contains(", 20") and changelog_text.contains("\n- "), "the exported changelog loads and starts with the newest dated heading")
	changelog.pressed.emit()
	_expect(changelog_screen.visible and not title_logo.visible and game.get("title_open") and changelog_back.has_focus(), "CHANGELOG opens the in-game screen over the title without starting a game")
	_expect(changelog_body.get_parsed_text().begins_with(first_heading.substr(3, first_heading.length() - 6)) and changelog_body.get_v_scroll_bar().value == 0.0, "the changelog screen shows the text from its newest heading")
	# The one-line note above the text must stay inside its label; a longer wording once clipped at the panel edge.
	var changelog_note: Label = changelog_screen.get_node("ChangelogNote") as Label
	var note_width: float = changelog_note.get_theme_font("font").get_string_size(changelog_note.text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, changelog_note.get_theme_font_size("font_size")).x
	_expect(changelog_note.text.contains("drag the text") and note_width <= changelog_note.size.x, "the changelog note mentions dragging the text and fits on its one line")
	# Touch readers have no wheel or keys: dragging the text itself moves the page, as the on-screen note promises.
	await _settle(4)
	var body_centre: Vector2 = changelog_body.global_position + changelog_body.size * 0.5
	var changelog_bar: VScrollBar = changelog_body.get_v_scroll_bar()
	_expect(changelog_bar.max_value > changelog_bar.page + 200.0, "the exported changelog is taller than one page")
	await _send_touch_drag(body_centre, -120.0)
	var after_touch_drag: float = changelog_bar.value
	_expect(is_equal_approx(after_touch_drag, 120.0), "a 120 px upward touch drag over the changelog text scrolls it 120 px")
	await _send_mouse_drag(body_centre, -60.0, 0)
	_expect(is_equal_approx(changelog_bar.value, after_touch_drag + 60.0), "a left-button mouse drag over the changelog text scrolls it too")
	var before_emulated: float = changelog_bar.value
	await _send_mouse_drag(body_centre, -60.0, InputEvent.DEVICE_ID_EMULATION)
	_expect(is_equal_approx(changelog_bar.value, before_emulated), "the mouse motion Godot emulates from a touch is ignored so a finger does not scroll twice")
	changelog_bar.value = 0.0
	changelog_back.pressed.emit()
	_expect(not changelog_screen.visible and title_logo.visible and game.get("title_open") and changelog.has_focus() and not (game.get_node("CanvasLayer/TitleScreen/CreditsScreen") as Control).visible, "BACK TO TITLE restores the title menu and returns focus to CHANGELOG")
	changelog.pressed.emit()
	await _send_escape(true)
	await _send_escape(false)
	_expect(not changelog_screen.visible and title_logo.visible and game.get("title_open") and not paused, "Esc closes the changelog screen without pausing")
	changelog.pressed.emit()
	game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(not changelog_screen.visible and title_logo.visible and game.get("title_open"), "Android Back closes the changelog screen instead of quitting")
	changelog.pressed.emit()
	game.call("_handle_back")
	_expect(not changelog_screen.visible and title_logo.visible and game.get("title_open") and not changelog_online.is_visible_in_tree(), "the Back router closes the changelog screen")
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
	# The theme pass gave title, pause and HUD buttons one lifted style: the ring rides over the state fill
	# instead of replacing it, so it stays wider than the button border and keeps a colour hover never uses.
	var resume: Button = game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/ResumeButton") as Button
	var resume_normal: StyleBoxFlat = resume.get_theme_stylebox("normal") as StyleBoxFlat
	var resume_hover: StyleBoxFlat = resume.get_theme_stylebox("hover") as StyleBoxFlat
	_expect(resume.get_theme_stylebox("focus") == ring and resume_normal != null and resume_hover != null and ring.border_width_left > resume_normal.border_width_left and not ring.border_color.is_equal_approx(resume_hover.border_color) and resume_normal.shadow_size > 0 and resume_normal.corner_radius_top_left > 0, "pause-menu buttons share the inset ring, heavier than their border and distinct from hover")
	_expect(title_new_game.get_theme_stylebox("normal") == resume_normal, "title and pause buttons wear the same theme style")
	# Settings alone keeps the terminal identity: squared controls with the same ring colour and width, squared to match.
	for bordered_path: String in ["CanvasLayer/PauseOverlay/Panel/SettingsMenu/BackButton", "CanvasLayer/PauseOverlay/Panel/SettingsMenu/FPSOptions", "CanvasLayer/PauseOverlay/Panel/SettingsMenu/ResolutionOptions"]:
		var bordered: Button = game.get_node(bordered_path) as Button
		var bordered_focus: StyleBoxFlat = bordered.get_theme_stylebox("focus") as StyleBoxFlat
		var bordered_normal: StyleBoxFlat = bordered.get_theme_stylebox("normal") as StyleBoxFlat
		_expect(bordered_focus != null and bordered_normal != null and bordered_focus.border_color.is_equal_approx(ring.border_color) and bordered_focus.border_width_left == ring.border_width_left and bordered_focus.expand_margin_left == 0.0 and bordered_focus.bg_color.a == 0.0 and bordered_focus.corner_radius_top_left == 0 and bordered_normal.corner_radius_top_left == 0 and bordered_normal.border_width_left < bordered_focus.border_width_left, "%s keeps a squared terminal ring inside its border" % bordered.name)
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
	_expect(game.get("tutorial_step") == 2 and not (game.get_node("CanvasLayer/TutorialPrompt") as Control).visible, "touch use reads the display and clears the tutorial")
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
	game.set("auto_pause_on_focus_loss", false)
	game.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(not paused and not overlay.visible, "focus loss does not pause when auto_pause_on_focus_loss is off")
	game.set("auto_pause_on_focus_loss", true)
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
	# On a touch-opened pause menu, B is still the cancel press: it resumes rather than only revealing focus.
	game.set("touch_enabled", true)
	game.set("controller_active", false)
	new_game.pressed.emit()
	game.call("_finish_intro")
	await process_frame
	game.call("_pause_game")
	_expect(paused and root.gui_get_focus_owner() == null, "a touch-opened pause menu starts unfocused")
	Input.parse_input_event(_controller_button(JOY_BUTTON_B, true))
	await process_frame
	Input.parse_input_event(_controller_button(JOY_BUTTON_B, false))
	await process_frame
	_expect(not paused and not overlay.visible, "controller B on a touch-opened pause menu resumes play like any cancel press")
	game.set("touch_enabled", false)
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


## A one-finger drag over `pos` that moves `delta_y` pixels in three steps, pushed through the real input path.
func _send_touch_drag(pos: Vector2, delta_y: float) -> void:
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = 0
	touch.position = pos
	touch.pressed = true
	Input.parse_input_event(touch)
	await process_frame
	for i: int in range(1, 4):
		var drag: InputEventScreenDrag = InputEventScreenDrag.new()
		drag.index = 0
		drag.position = pos + Vector2(0.0, delta_y * i / 3.0)
		drag.relative = Vector2(0.0, delta_y / 3.0)
		Input.parse_input_event(drag)
		await process_frame
	touch.pressed = false
	touch.position = pos + Vector2(0.0, delta_y)
	Input.parse_input_event(touch)
	await process_frame


## A left-button mouse drag over `pos` that moves `delta_y` pixels in three steps on the given input device.
func _send_mouse_drag(pos: Vector2, delta_y: float, device: int) -> void:
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = pos
	press.global_position = pos
	press.device = device
	Input.parse_input_event(press)
	await process_frame
	for i: int in range(1, 4):
		var motion: InputEventMouseMotion = InputEventMouseMotion.new()
		motion.position = pos + Vector2(0.0, delta_y * i / 3.0)
		motion.global_position = motion.position
		motion.relative = Vector2(0.0, delta_y / 3.0)
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		motion.device = device
		Input.parse_input_event(motion)
		await process_frame
	press.pressed = false
	press.position = pos + Vector2(0.0, delta_y)
	press.global_position = press.position
	Input.parse_input_event(press)
	await process_frame


func _settle(frames: int) -> void:
	for _i: int in range(frames):
		await process_frame


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
