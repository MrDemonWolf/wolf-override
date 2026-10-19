extends "res://tests/support/game_suite.gd"
## Settings: values saved and loaded, hostile settings files, rebinding keys and controller buttons, the
## display page, the LANGUAGE row (localization PR L6) and the menus' text in another language (PR L7a).
## Bookkeeping, spawning and the waits come from the shared suite kit (tests/support/game_suite.gd).


func _run() -> void:
	check_name = "Settings"
	await _check_hostile_settings()
	var path: String = "user://settings-test-%s.cfg" % OS.get_process_id()
	var corrupt: ConfigFile = ConfigFile.new()
	for key: String in ["fps_limit", "resolution", "msaa_2d"]:
		corrupt.set_value("video", key, {"bad": true})
	corrupt.set_value("audio", "Music", {"bad": true})
	corrupt.set_value("controls", "deadzone", "bad")
	corrupt.set_value("video", "fullscreen", {})
	corrupt.set_value("video", "vsync", {})
	corrupt.set_value("video", "reduced_motion", "bad")
	corrupt.set_value("bindings", "interact_keyboard", {"type": "key", "code": KEY_I})
	corrupt.set_value("bindings", "choice_1_keyboard", {"type": "key", "code": KEY_I})
	corrupt.save(path)
	var game: Node2D = MAIN_SCENE.instantiate() as Node2D
	game.set("settings_path", path)
	game.set("save_path", "user://settings-save-test-%s.json" % OS.get_process_id())
	root.add_child(game)
	var malformed: ConfigFile = ConfigFile.new()
	malformed.set_value("audio", "Music", {"bad": true})
	malformed.set_value("controls", "deadzone", "bad")
	_expect(GameSettings.number(malformed, "audio", "Music", 100.0) == 100.0 and GameSettings.number(malformed, "controls", "deadzone", 0.25) == 0.25, "malformed numeric preferences fall back safely")
	(game.get_node("CanvasLayer/TitleScreen/SettingsButton") as Button).pressed.emit()
	var menu: GameSettings = game.get("settings_menu") as GameSettings
	_expect(Engine.max_fps == 60 and (menu.volumes["Music"] as HSlider).value == 100.0 and menu.deadzone.value == 0.25, "malformed saved preferences do not interrupt scene setup")
	_expect(menu.prompt(&"interact", false) == "E" and menu.prompt(&"choice_1", false) == "1" and menu.vsync.button_pressed and not menu.reduced_motion.button_pressed, "invalid booleans and reserved loaded bindings restore safe defaults")
	var resolution_options: OptionButton = game.get("resolution_options") as OptionButton
	_expect(resolution_options.selected == 1 and resolution_options.get_item_text(1) == "1280 × 720" and game.call("_resolution_size", resolution_options.selected) == Vector2i(1280, 720), "an unreadable window size falls back to the 1280×720 default")
	_expect(game.call("_resolution_size", 0) == Vector2i(960, 540) and game.call("_resolution_size", 2) == Vector2i(1920, 1080) and game.call("_resolution_size", 7) == Vector2i(1280, 720), "every saved window size keeps its own size; an unknown index opens at the default")
	_expect(ProjectSettings.get_setting("display/window/size/window_width_override") == 1280 and ProjectSettings.get_setting("display/window/size/window_height_override") == 720 and ProjectSettings.get_setting("display/window/size/viewport_width") == 960, "the first window opens at 1280×720 over the unchanged 960×540 canvas")
	var impact: Impact = game.get("impact") as Impact
	_expect(impact != null and not impact.reduce_motion and menu.reduced_motion.is_visible_in_tree(), "Reduced Motion is off by default and sits on the Display tab")
	menu.reduced_motion.button_pressed = true
	_expect(impact.reduce_motion, "the Reduced Motion toggle reaches the impact kit")
	impact.add_trauma(1.0)
	impact.hit_stop(0.09)
	await process_frame
	_expect((game.get_node("IntroCamera") as Camera2D).offset == Vector2.ZERO and Engine.time_scale == 1.0, "with Reduced Motion on, a boom leaves the camera still and skips hit-stop")
	_expect(paused and menu.is_visible_in_tree() and game.get("title_open"), "settings open before starting a game")
	_check_display_page(menu)
	await _check_language_row(game, path)
	await _check_menu_translation(game)
	var navigation_actions: Array[StringName] = [&"ui_left", &"ui_right", &"ui_up", &"ui_down"]
	var navigation_buttons: Array[JoyButton] = [JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN]
	for index: int in navigation_actions.size():
		var stick: InputEventJoypadMotion = InputEventJoypadMotion.new()
		stick.axis = JOY_AXIS_LEFT_X if index < 2 else JOY_AXIS_LEFT_Y
		stick.axis_value = -1.0 if index % 2 == 0 else 1.0
		_expect(InputMap.action_has_event(navigation_actions[index], _controller_button(navigation_buttons[index], true)) and InputMap.action_has_event(navigation_actions[index], stick), "menu direction keeps D-pad and stick mappings: %s" % navigation_actions[index])
	await process_frame
	Input.parse_input_event(_controller_button(JOY_BUTTON_B, true))
	await process_frame
	var title_settings: Button = game.get_node("CanvasLayer/TitleScreen/SettingsButton") as Button
	_expect(not paused and not game.get("pause_overlay").visible and game.get("title_open"), "controller B closes title settings through native event dispatch")
	_expect(title_settings.has_focus(), "controller B from title settings leaves the title Settings button focused")
	Input.parse_input_event(_controller_button(JOY_BUTTON_B, false))
	await process_frame
	title_settings.pressed.emit()
	Input.parse_input_event(_key(KEY_ESCAPE))
	await process_frame
	Input.parse_input_event(_key(KEY_ESCAPE, false))
	await process_frame
	_expect(not paused and game.get("title_open") and title_settings.has_focus(), "Esc from title settings leaves the title Settings button focused")
	title_settings.pressed.emit()
	game.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	_expect(not paused and game.get("title_open") and title_settings.has_focus(), "Android Back from title settings leaves the title Settings button focused")
	title_settings.pressed.emit()
	(game.get_node("CanvasLayer/PauseOverlay/Panel/SettingsMenu/BackButton") as Button).grab_focus()
	Input.parse_input_event(_controller_button(JOY_BUTTON_A, true))
	await process_frame
	Input.parse_input_event(_controller_button(JOY_BUTTON_A, false))
	await process_frame
	_expect(not paused and not game.get("pause_overlay").visible, "controller A activates the focused settings Back button")
	_expect(title_settings.has_focus(), "the settings Back button leaves the title Settings button focused")
	# Pure touch play opens and closes Settings without a focus ring nobody asked for.
	game.set("touch_enabled", true)
	game.set("controller_active", false)
	title_settings.pressed.emit()
	_expect(root.gui_get_focus_owner() == null, "touch-opened title settings focus nothing")
	(game.get_node("CanvasLayer/PauseOverlay/Panel/SettingsMenu/BackButton") as Button).pressed.emit()
	_expect(not paused and root.gui_get_focus_owner() == null, "touch Back from title settings focuses nothing")
	Input.parse_input_event(_key(KEY_DOWN))
	await process_frame
	Input.parse_input_event(_key(KEY_DOWN, false))
	await process_frame
	_expect(title_settings.has_focus(), "a key press after touch Back from title settings selects the title Settings button")
	game.set("touch_enabled", false)
	title_settings.pressed.emit()
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
	resolution_options.select(0)
	game.call("_on_resolution_selected", 0)
	var config: ConfigFile = ConfigFile.new()
	config.load(path)
	_expect(config.get_value("audio", "Music") == 37.0 and config.get_value("video", "msaa_2d") == 2 and config.get_value("video", "fps_limit") == 30 and config.get_value("video", "resolution") == 0 and config.get_value("video", "reduced_motion") == true, "video saves preserve audio, Reduced Motion and extra graphics preferences")
	_expect(root.msaa_2d == Viewport.MSAA_4X, "edge smoothing applies to the game viewport")
	menu.tabs.current_tab = 2
	menu.begin_capture(&"interact", "keyboard")
	menu._input(_key(KEY_I))
	_expect(menu.prompt(&"interact", false) == "E" and not menu.capture_action.is_empty(), "name-cycling shortcut cannot be assigned to interaction")
	menu.cancel_capture()
	menu.begin_capture(&"interact", "keyboard")
	menu._input(_key(KEY_Q))
	_expect(menu.prompt(&"interact", false) == "Q" and menu.capture_action.is_empty(), "keyboard rebind changes the actual InputMap and ends capture")
	menu.begin_capture(&"choice_1", "keyboard")
	menu._input(_key(KEY_Q))
	_expect(menu.prompt(&"choice_1", false) == "1" and not menu.capture_action.is_empty(), "duplicate gameplay binding is rejected without losing the old key")
	menu._input(_key(KEY_ESCAPE))
	_expect(menu.capture_action.is_empty() and paused, "Escape cancels rebinding without unpausing")
	menu.begin_capture(&"choice_1", "controller")
	Input.parse_input_event(_controller_button(JOY_BUTTON_B, true))
	await process_frame
	_expect(menu.prompt(&"choice_1", true) == "B" and paused and menu.is_visible_in_tree() and menu.capture_action.is_empty(), "controller B rebind is consumed before menu cancellation")
	Input.parse_input_event(_controller_button(JOY_BUTTON_B, false))
	await process_frame
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
	_expect(not paused and game.get("title_open") and title_settings.has_focus(), "Back from title settings returns to the title with Settings focused")
	game.queue_free()
	await process_frame
	var reloaded: Node2D = MAIN_SCENE.instantiate() as Node2D
	reloaded.set("settings_path", path)
	root.add_child(reloaded)
	var restored: GameSettings = reloaded.get("settings_menu") as GameSettings
	_expect(restored.prompt(&"interact", false) == "Q" and restored.prompt(&"choice_1", true) == "B" and restored.prompt(&"move_left", true) == "AXIS 2 −", "reopening restores key, button and stick bindings")
	_expect((restored.volumes["Music"] as HSlider).value == 37.0 and restored.antialiasing.selected == 2 and Engine.max_fps == 30, "reopening restores volume and graphics preferences")
	_expect((reloaded.get("resolution_options") as OptionButton).selected == 0, "a saved 960×540 window size still wins over the 1280×720 default")
	_expect(restored.reduced_motion.button_pressed and (reloaded.get("impact") as Impact).reduce_motion, "reopening restores Reduced Motion and applies it to the impact kit")
	restored.reduced_motion.button_pressed = false
	_expect(InputMap.action_get_events(&"move_right").size() == 4, "unmodified movement retains both keyboard keys, D-pad and stick")
	reloaded.call("_new_game")
	reloaded.call("_finish_intro")
	# Past the tutorial prompt, which is the one prompt on the first frames, the hint bar shows.
	reloaded.set("tutorial_step", 2)
	reloaded.call("_refresh_ui")
	_expect((reloaded.get_node("CanvasLayer/ContextHint/Text") as Label).text.begins_with("Q:"), "interaction hint follows remapped key")
	restored.reset_controls()
	for bus: String in GameSettings.BUSES:
		restored._apply_volume(bus, 100.0)
	Engine.max_fps = 60
	root.msaa_2d = Viewport.MSAA_DISABLED
	reloaded.queue_free()
	await process_frame
	var swaps: ConfigFile = ConfigFile.new()
	swaps.set_value("bindings", "interact_keyboard", {"type": "key", "code": KEY_1})
	swaps.set_value("bindings", "choice_1_keyboard", {"type": "key", "code": KEY_E})
	swaps.set_value("bindings", "choice_2_controller", {"type": "button", "code": JOY_BUTTON_MAX})
	swaps.set_value("bindings", "move_left_keyboard", {"type": "key", "code": KEY_Q})
	swaps.set_value("bindings", "move_right_keyboard", {"type": "key", "code": KEY_Q})
	swaps.save(path)
	var swapped_game: Node2D = MAIN_SCENE.instantiate() as Node2D
	swapped_game.set("settings_path", path)
	root.add_child(swapped_game)
	var swapped: GameSettings = swapped_game.get("settings_menu") as GameSettings
	_expect(swapped.prompt(&"interact", false) == "1" and swapped.prompt(&"choice_1", false) == "E", "legitimate saved keyboard swaps survive whole-map validation")
	_expect(swapped.prompt(&"choice_2", true) == "Y", "invalid saved controller code retains its default")
	_expect(swapped.prompt(&"move_left", false) != swapped.prompt(&"move_right", false) and (swapped.prompt(&"move_left", false) == "A" or swapped.prompt(&"move_right", false) == "D"), "conflicting loaded overrides cannot bind opposing movement to one key")
	swapped.reset_controls()
	swapped_game.queue_free()
	await process_frame
	await _check_saved_language(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	finish("Settings persistence and rebinding checks passed")


func _check_hostile_settings() -> void:
	var pid: int = OS.get_process_id()
	var path: String = "user://settings-hostile-%s.cfg" % pid
	var script_path: String = "user://evil-%s.gd" % pid
	var save_path: String = "user://settings-hostile-save-%s.json" % pid
	_write_text(script_path, "extends RefCounted\n\n\nstatic func _static_init() -> void:\n\tEngine.set_meta(\"wolf_settings_poc\", true)\n\n\nfunc _init() -> void:\n\tEngine.set_meta(\"wolf_settings_poc\", true)\n")
	var cases: Dictionary = {
		"object payload": "[video]\nfps_limit=Object(RefCounted,\"script\":Resource(\"%s\"))\n" % script_path,
		"truncated file": "[video\nfps_limit=",
		"oversized file": "[video]\nfps_limit=30\n" + ";".repeat(GameSettings.MAX_SETTINGS_BYTES),
	}
	for label: String in cases:
		_write_text(path, cases[label])
		var game: Node2D = MAIN_SCENE.instantiate() as Node2D
		game.set("settings_path", path)
		game.set("save_path", save_path)
		root.add_child(game)
		var menu: GameSettings = game.get("settings_menu") as GameSettings
		_expect(not Engine.has_meta("wolf_settings_poc"), "%s does not run code from the settings file" % label)
		_expect(Engine.max_fps == 60 and menu.vsync.button_pressed and (menu.volumes["Music"] as HSlider).value == 100.0 and menu.prompt(&"interact", false) == "E", "%s loads default settings" % label)
		game.queue_free()
		await process_frame
		if Engine.has_meta("wolf_settings_poc"):
			Engine.remove_meta("wolf_settings_poc")
	for file: String in [path, script_path, save_path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


## Q10 (October 14, 2026): the Display tab, where TEXT SIZE is, keeps its THE DEN / LOCAL CONFIGURATION
## heading, shows no GPU or renderer line, and says the window size is OS-managed only on phones and
## tablets; the V-sync sentence shows everywhere.
func _check_display_page(menu: GameSettings) -> void:
	menu.select_tab(0)
	var texts: Array[String] = []
	for label: Node in menu.find_children("*", "Label", true, false):
		if (label as Label).is_visible_in_tree():
			texts.append((label as Label).text)
	_expect("THE DEN  /  LOCAL CONFIGURATION" in texts and menu.text_size.is_visible_in_tree(), "the Display tab keeps the THE DEN / LOCAL CONFIGURATION heading, beside TEXT SIZE")
	var adapter: String = RenderingServer.get_video_adapter_name()
	var developer_lines: Array[String] = []
	for text: String in texts:
		if text.contains("GPU") or text.contains("Renderer") or (not adapter.is_empty() and text.contains(adapter)):
			developer_lines.append(text)
	_expect(developer_lines.is_empty(), "the Display tab shows no GPU or renderer line (%s)" % [developer_lines])
	var was_mobile: bool = menu.mobile
	_expect(not was_mobile, "a desktop run is not a phone or tablet")
	_expect(menu.note.text == "V-sync may limit the FPS cap.", "on desktop the Display note leaves out the mobile window size (%s)" % menu.note.text)
	menu.mobile = true
	menu.select_tab(0)
	_expect(menu.note.text == "Window size is OS-managed on mobile. V-sync may limit the FPS cap.", "on phones and tablets the Display note says the OS manages the window size (%s)" % menu.note.text)
	menu.select_tab(1)
	_expect(not menu.note.text.contains("OS-managed"), "the other tabs keep their own notes")
	menu.mobile = was_mobile
	menu.select_tab(0)


## LANGUAGE on the GENERAL tab (PR L6, PLAN.md and DESIGN.md "Settings: the LANGUAGE option"):
## - as shipped (Spanish offered since PR L9) the tab shows and the list holds English and both Spanish
##   files, each Spanish one with its "traducción automática" tag;
## - with English alone offered (set here with [method _offer]) the GENERAL tab stays hidden, the list
##   holds English, and saving other settings writes no language, so the game keeps following the OS;
## - with Spanish (Latin America) and Japanese offered the tab shows, each language is named in its own
##   words with its "machine translation" tag as a separator row under it, never translated;
## - a pick applies the language, shows its tag under the row and saves [general] language;
## - a change made elsewhere (I18n.apply) moves the list's choice and the note (TRANSLATION_CHANGED).
## [param path] is the game's settings file; its language is erased again at the end, and the shipped
## offered set is put back.
func _check_language_row(game: Node2D, path: String) -> void:
	var menu: GameSettings = game.get("settings_menu") as GameSettings
	var config: ConfigFile = ConfigFile.new()
	config.load(path)
	_expect(not menu.tabs.is_tab_hidden(GameSettings.GENERAL_TAB) and _language_items(menu) == ["English", "Deutsch", "— maschinelle Übersetzung", "Español (España)", "— traducción automática", "Español (Latinoamérica)", "— traducción automática", "Français", "— traduction automatique", "Português (Brasil)", "— tradução automática"], "as shipped the GENERAL tab shows English, then German, both Spanish files, French and Brazilian Portuguese in the table's order, each translation with its tag (%s)" % [_language_items(menu)])
	var shipped: Dictionary = _offer(["en"])
	menu.refresh_languages()
	_expect(menu.tabs.is_tab_hidden(GameSettings.GENERAL_TAB) and menu.tabs.get_tab_title(GameSettings.GENERAL_TAB) == "GENERAL", "with English alone the GENERAL tab is there but hidden")
	_expect(menu.language.item_count == 1 and menu.language.get_item_text(0) == "English" and menu.language.selected == 0 and not menu.language_note.visible, "the list holds English, chosen, with no tag")
	_expect(not config.has_section_key(I18n.CONFIG_SECTION, I18n.CONFIG_KEY), "saving other settings writes no language, so the OS keeps deciding")
	_offer(["en", "es", "ja"])
	menu.refresh_languages()
	_expect(not menu.tabs.is_tab_hidden(GameSettings.GENERAL_TAB), "with a second language the GENERAL tab shows")
	var items: Array[String] = _language_items(menu)
	_expect(items == ["English", "Español (Latinoamérica)", "— traducción automática", "日本語", "— 機械翻訳"], "each language is named in its own words, its tag a separator row under it (%s)" % [items])
	_expect(menu.language.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED and menu.language.get_popup().auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED and menu.language_note.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED, "the names and tags are never translated")
	menu.tabs.current_tab = GameSettings.GENERAL_TAB
	await process_frame
	_expect(menu.language.is_visible_in_tree() and not menu.text_size.is_visible_in_tree() and menu.note.text == "Until you choose a language, the game uses your system's.", "the GENERAL tab shows LANGUAGE alone, with its note (%s)" % menu.note.text)
	menu.language.select(1)
	menu.language.item_selected.emit(1)
	config.load(path)
	_expect(TranslationServer.get_locale() == "es" and config.get_value(I18n.CONFIG_SECTION, I18n.CONFIG_KEY, "") == "es", "picking Español applies it and saves [general] language=es")
	_expect(menu.language_note.visible and menu.language_note.text == "traducción automática", "an unreviewed choice shows its tag under the row (%s)" % menu.language_note.text)
	I18n.apply("ja")
	await process_frame
	_expect(menu.language.get_item_metadata(menu.language.selected) == "ja" and menu.language_note.text == "機械翻訳", "a change made elsewhere moves the list's choice and the note")
	I18n.apply("en")
	await process_frame
	_expect(menu.language.selected == 0 and not menu.language_note.visible, "back in English the list shows English with no tag")
	_restore_offered(shipped)
	config.erase_section(I18n.CONFIG_SECTION)
	config.save(path)
	# Forget the pick too, or the menu's next save would write it back.
	menu.set("_picked_language", "")
	I18n.apply("en")
	menu.refresh_languages()
	menu.select_tab(0)


## The menus' worked-out text follows a language change (localization PR L7a), with a catalog made up
## here for [constant UNSHIPPED_TEST_LANGUAGE] (the suite kit's; dropped again with I18n.forget, so no
## real catalog is touched). The made-up words are Portuguese, from when the code was "pt_BR".
## - prompt() forgets the labels it remembered in English (the lighter plan's S01 prompt cache), so a
##   controller button and a named key read in Spanish at once, and the binding buttons follow;
## - the note under the tabs is translated again, its action name too, and a translation whose
##   conversions differ from the English shows the English template (I18n.fill) instead of a blank note;
## - a key name is translated with the "key name" context, so the action "Pause" and the key "Pause" stay
##   apart, and one-letter names and a layout's symbols are never sent through tr();
## - a key whose layout label matches its position keeps its word ("Minus"), a layout's character label
##   is shown as itself, and one the game fonts cannot draw (Greek, Hebrew, Arabic, Thai) falls back to
##   the QWERTY name (GameSettings.key_label_name, given the labels the headless server cannot read);
## - Pause's hint is written again in the new language while Pause is open, and the note reads English
##   again after the switch back.
## [param game] has title Settings open on the CONTROLS rows' defaults.
func _check_menu_translation(game: Node2D) -> void:
	var menu: GameSettings = game.get("settings_menu") as GameSettings
	var catalog: Translation = Translation.new()
	catalog.locale = UNSHIPPED_TEST_LANGUAGE
	catalog.add_message("START", "INÍCIO")
	catalog.add_message("Escape", "Escape-pt", GameSettings.KEY_NAME_CONTEXT)
	catalog.add_message("Pause", "Pausa (ação)")
	catalog.add_message("Press a keyboard input for %s. Esc cancels.", "Pressione uma tecla para %s. Esc cancela.")
	catalog.add_message("%s  RESUME", "%s  CONTINUAR")
	# A broken translation (other conversions than the English), as a gap in the PO gates would ship it.
	catalog.add_message("Press a controller input for %s. Esc cancels.", "Pressione um botão para %d. Esc cancela.")
	catalog.add_message("Minus", "Menos", GameSettings.KEY_NAME_CONTEXT)
	TranslationServer.add_translation(catalog)
	_expect(menu.prompt(&"pause_game", true) == "START" and menu.prompt(&"pause_game", false) == "Escape", "in English the Pause prompts read START and Escape (and are remembered)")
	menu.begin_capture(&"pause_game", "keyboard")
	I18n.apply(UNSHIPPED_TEST_LANGUAGE)
	await process_frame
	_expect(menu.prompt(&"pause_game", true) == "INÍCIO" and menu.prompt(&"pause_game", false) == "Escape-pt", "a language change forgets the remembered prompts (%s, %s)" % [menu.prompt(&"pause_game", true), menu.prompt(&"pause_game", false)])
	var keyboard: Button = menu.binding_buttons["pause_game_keyboard"]
	_expect(keyboard.text == "Escape-pt" and keyboard.tooltip_text == keyboard.text and keyboard.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED, "the binding buttons are worked out again in the new language (%s)" % keyboard.text)
	_expect(menu.note.text == "Pressione uma tecla para Pausa (ação). Esc cancela.", "the rebind prompt is translated whole, with the action's name (%s)" % menu.note.text)
	menu.begin_capture(&"pause_game", "controller")
	_expect(menu.note.text == "Press a controller input for Pausa (ação). Esc cancels.", "a translated note whose conversions differ from the English shows the English template (its insert still translated), not a blank note (%s)" % menu.note.text)
	menu.cancel_capture()
	var symbol: InputEventKey = InputEventKey.new()
	symbol.physical_keycode = KEY_MINUS
	var letter: InputEventKey = InputEventKey.new()
	letter.physical_keycode = KEY_E
	_expect(menu.key_name(symbol) == "Menos" and menu.key_label_name(KEY_MINUS, KEY_MINUS) == "Menos", "a symbol key whose layout agrees with its position keeps its name, translated (%s)" % menu.key_name(symbol))
	# Layouts the headless display server cannot switch to, named by their labels: French AZERTY's 1 key
	# prints &, its A position prints Q; Russian's A position prints Cyrillic ф, which the game fonts
	# draw; Greek α, Hebrew ש, Arabic ش and Thai ฟ are not in them, so those keys keep the QWERTY name.
	_expect(menu.key_label_name(KEY_1, KEY_AMPERSAND) == "&" and menu.key_label_name(KEY_A, KEY_Q) == "Q", "a layout's character label is shown as the character (%s, %s)" % [menu.key_label_name(KEY_1, KEY_AMPERSAND), menu.key_label_name(KEY_A, KEY_Q)])
	_expect(menu.key_label_name(KEY_A, "ф".unicode_at(0) as Key) == "ф", "a Cyrillic label the fonts draw is shown (%s)" % menu.key_label_name(KEY_A, "ф".unicode_at(0) as Key))
	for native: String in ["α", "ש", "ش", "ฟ"]:
		_expect(not I18n.game_fonts_draw(native) and menu.key_label_name(KEY_A, native.unicode_at(0) as Key) == "A", "a %s label the game fonts cannot draw falls back to the QWERTY name A (%s)" % [native, menu.key_label_name(KEY_A, native.unicode_at(0) as Key)])
	_expect(menu.key_label_name(KEY_SEMICOLON, "ش".unicode_at(0) as Key) == "Semicolon", "an undrawable label on a symbol key falls back to the position's word, translated as a key name")
	TranslationServer.pseudolocalization_enabled = true
	_expect(menu.key_name(letter) == "E" and menu.key_label_name(KEY_1, KEY_AMPERSAND) == "&", "a letter and a layout's symbol are never sent through tr() (%s, %s)" % [menu.key_name(letter), menu.key_label_name(KEY_1, KEY_AMPERSAND)])
	TranslationServer.pseudolocalization_enabled = false
	var pause_menu: Control = game.get("pause_menu") as Control
	var hint: Label = game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/PauseHint") as Label
	game.call("_show_pause_hint", false)
	_expect(hint.text == "Escape-pt  CONTINUAR" and hint.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED, "Pause's hint fills the translated template with the key's name (%s)" % hint.text)
	var was_visible: bool = pause_menu.visible
	pause_menu.show()
	I18n.apply("en")
	await process_frame
	_expect(hint.text == "Escape  RESUME" and menu.note.text == "Press a controller input for Pause. Esc cancels.", "back in English, Pause's hint and the note are English again (%s; %s)" % [hint.text, menu.note.text])
	pause_menu.visible = was_visible
	I18n.forget(catalog)
	I18n.apply("en")
	await process_frame


## A saved language at start-up (PR L6), one game at a time: with Spanish offered a game whose file says
## [general] language=es starts in Spanish and selects it; once no Spanish file is offered (both turned
## off here with [method _offer], since es_ES alone would still catch a saved "es") the same file starts in
## English with the GENERAL tab hidden, and saving keeps the player's pick in the file for when it comes
## back. The shipped offered set is put back at the end. [param path] is a scratch settings file.
func _check_saved_language(path: String) -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(I18n.CONFIG_SECTION, I18n.CONFIG_KEY, "es")
	config.save(path)
	var shipped: Dictionary = _offer(["en", "es"])
	var spanish: Node2D = MAIN_SCENE.instantiate() as Node2D
	spanish.set("settings_path", path)
	root.add_child(spanish)
	var restored: GameSettings = spanish.get("settings_menu") as GameSettings
	_expect(TranslationServer.get_locale() == "es" and restored.language.get_item_metadata(restored.language.selected) == "es" and not restored.tabs.is_tab_hidden(GameSettings.GENERAL_TAB), "a game started with language=es saved starts in Spanish and selects it (locale %s)" % TranslationServer.get_locale())
	spanish.queue_free()
	await process_frame
	_offer(["en"])
	var english: Node2D = MAIN_SCENE.instantiate() as Node2D
	english.set("settings_path", path)
	root.add_child(english)
	var english_only: GameSettings = english.get("settings_menu") as GameSettings
	english_only.reduced_motion.button_pressed = true
	config.load(path)
	_expect(TranslationServer.get_locale() == "en" and english_only.tabs.is_tab_hidden(GameSettings.GENERAL_TAB) and config.get_value(I18n.CONFIG_SECTION, I18n.CONFIG_KEY, "") == "es" and config.get_value("video", "reduced_motion") == true, "a saved language no longer offered shows English and stays in the file after a save")
	english_only.reduced_motion.button_pressed = false
	english.queue_free()
	await process_frame
	_restore_offered(shipped)
	I18n.apply("en")


## The language list's rows as the player reads them, a tag separator row as "— <tag>".
func _language_items(menu: GameSettings) -> Array[String]:
	var items: Array[String] = []
	for index: int in menu.language.item_count:
		items.append(("— %s" if menu.language.is_item_separator(index) else "%s") % menu.language.get_item_text(index))
	return items


## Offers exactly [param codes] for the rest of this check, by turning "enabled" on or off in
## I18n.LANGUAGES (the loaded table only; the file is untouched). Returns every row's "enabled" as it was,
## for [method _restore_offered]. Callers refresh the menu themselves.
func _offer(codes: Array[String]) -> Dictionary:
	var before: Dictionary = {}
	for code: String in I18n.LANGUAGES:
		var row: Dictionary = I18n.LANGUAGES[code]
		before[code] = row.get("enabled", false)
		row["enabled"] = codes.has(code)
	return before


## Puts back the "enabled" values [method _offer] returned.
func _restore_offered(before: Dictionary) -> void:
	for code: String in before:
		(I18n.LANGUAGES[code] as Dictionary)["enabled"] = before[code]


func _write_text(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _key(code: Key, pressed: bool = true) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	return event


func _controller_button(code: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = code
	event.pressed = pressed
	return event
