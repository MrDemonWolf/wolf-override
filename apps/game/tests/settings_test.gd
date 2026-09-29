extends SceneTree

const GAME: PackedScene = preload("res://scenes/main.tscn")
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var path: String = "user://settings-test-%s.cfg" % OS.get_process_id()
	var game: Node2D = GAME.instantiate() as Node2D
	game.set("settings_path", path)
	game.set("save_path", "user://settings-save-test-%s.json" % OS.get_process_id())
	root.add_child(game)
	(game.get_node("CanvasLayer/TitleScreen/SettingsButton") as Button).pressed.emit()
	var menu: GameSettings = game.get("settings_menu") as GameSettings
	_expect(paused and menu.is_visible_in_tree() and game.get("title_open"), "settings open before starting a game")
	menu.tabs.current_tab = 1
	var music: HSlider = menu.volumes["Music"]
	music.value = 37.0
	var master: HSlider = menu.volumes["Master"]
	master.value = 0.0
	_expect(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")), "zero master volume mutes the mixer")
	_expect(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))), 0.37), "music slider changes its live mixer bus")
	menu.antialiasing.select(2)
	menu.antialiasing.item_selected.emit(2)
	(game.get("fps_options") as OptionButton).select(0)
	game.call("_on_fps_selected", 0)
	var config: ConfigFile = ConfigFile.new()
	config.load(path)
	_expect(config.get_value("audio", "Music") == 37.0 and config.get_value("video", "msaa_2d") == 2 and config.get_value("video", "fps_limit") == 30, "video saves preserve audio and extra graphics preferences")
	_expect(root.msaa_2d == Viewport.MSAA_4X, "edge smoothing applies to the game viewport")
	menu.tabs.current_tab = 2
	menu.begin_capture(&"interact", "keyboard")
	menu._input(_key(KEY_Q))
	_expect(menu.prompt(&"interact", false) == "Q" and menu.capture_action.is_empty(), "keyboard rebind changes the actual InputMap and ends capture")
	menu.begin_capture(&"choice_1", "keyboard")
	menu._input(_key(KEY_Q))
	_expect(menu.prompt(&"choice_1", false) == "1" and not menu.capture_action.is_empty(), "duplicate gameplay binding is rejected without losing the old key")
	menu._input(_key(KEY_ESCAPE))
	_expect(menu.capture_action.is_empty() and paused, "Escape cancels rebinding without unpausing")
	menu.begin_capture(&"choice_1", "controller")
	var button: InputEventJoypadButton = InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_B
	button.pressed = true
	menu._input(button)
	_expect(menu.prompt(&"choice_1", true) == "B", "controller rebind updates the action prompt")
	menu.begin_capture(&"move_left", "controller")
	var axis: InputEventJoypadMotion = InputEventJoypadMotion.new()
	axis.axis = JOY_AXIS_RIGHT_X
	axis.axis_value = -0.8
	menu._input(axis)
	_expect(menu.prompt(&"move_left", true) == "AXIS 2 −", "stick direction can be rebound")
	menu.deadzone.value = 0.4
	_expect(is_equal_approx(InputMap.action_get_deadzone(&"move_left"), 0.4), "stick deadzone applies to gameplay")
	config.load(path)
	_expect(config.get_value("bindings", "interact_keyboard").code == KEY_Q and config.get_value("audio", "Music") == 37.0, "remapping preserves audio and display settings")
	var saved: ConfigFile = config
	menu.reset_controls()
	_expect(menu.prompt(&"interact", false) == "E" and menu.prompt(&"choice_1", true) == "X", "reset restores keyboard and controller defaults")
	var reset_config: ConfigFile = ConfigFile.new()
	reset_config.load(path)
	_expect(not reset_config.has_section_key("bindings", "interact_keyboard"), "reset clears saved overrides")
	saved.save(path)
	game.call("_show_pause_menu")
	_expect(not paused and game.get("title_open"), "Back from title settings returns to the title")
	game.queue_free()
	await process_frame
	var reloaded: Node2D = GAME.instantiate() as Node2D
	reloaded.set("settings_path", path)
	root.add_child(reloaded)
	var restored: GameSettings = reloaded.get("settings_menu") as GameSettings
	_expect(restored.prompt(&"interact", false) == "Q" and restored.prompt(&"choice_1", true) == "B" and restored.prompt(&"move_left", true) == "AXIS 2 −", "reopening restores key, button and stick bindings")
	_expect((restored.volumes["Music"] as HSlider).value == 37.0 and restored.antialiasing.selected == 2 and Engine.max_fps == 30, "reopening restores volume and graphics preferences")
	_expect(InputMap.action_get_events(&"move_right").size() == 4, "unmodified movement retains both keyboard keys, D-pad and stick")
	reloaded.call("_new_game")
	reloaded.call("_finish_intro")
	reloaded.call("_refresh_ui")
	_expect((reloaded.get_node("CanvasLayer/ContextHint/Text") as Label).text.begins_with("Q:"), "interaction hint follows remapped key")
	restored.reset_controls()
	for bus: String in GameSettings.BUSES:
		restored._apply_volume(bus, 100.0)
	Engine.max_fps = 60
	root.msaa_2d = Viewport.MSAA_DISABLED
	reloaded.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if failures == 0:
		print("Settings persistence and rebinding checks passed")
	quit(1 if failures > 0 else 0)


func _key(code: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("Settings check failed: " + message)
