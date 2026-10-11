extends SceneTree

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")

var failures: int = 0
var base: String = ""
var menu_requests: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	base = "user://debug-tools-test-%s" % OS.get_process_id()
	_clean()
	await _check_release_gating()
	await _check_keyboard_code_and_storage()
	await _check_controller_code()
	await _check_logo_code()
	await _check_overlay()
	await _check_snapshot()
	await _check_capture()
	await _check_touch_button_and_menu_inputs()
	_clean()
	if failures == 0:
		print("Debug tools checks passed")
	quit(1 if failures > 0 else 0)


## A release build hides everything: no overlay, capture, menu or button, and nothing processes or draws.
func _check_release_gating() -> void:
	var game: Node2D = await _spawn(false)
	var tools: DebugTools = _tools(game)
	_expect(tools != null and tools.get_parent() == game, "Main builds one DebugTools node")
	_expect(not tools.available and not tools.unlocked, "a release build starts with the debug tools hidden")
	_expect(_idle(tools), "hidden debug tools neither process nor draw")
	tools.capture_dir = base + "-captures"
	for key: Key in [KEY_F3, KEY_F12, KEY_QUOTELEFT]:
		await _send_key(key)
	await _send_pad(JOY_BUTTON_LEFT_STICK, true)
	await _send_pad(JOY_BUTTON_RIGHT_STICK, true)
	await _send_pad(JOY_BUTTON_RIGHT_STICK, false)
	await _send_pad(JOY_BUTTON_LEFT_STICK, false)
	_expect(tools.overlay_mode == DebugTools.Overlay.OFF and _idle(tools), "F3, F12, backquote and both sticks do nothing while the tools are hidden")
	_expect(tools.capture().is_empty() and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(tools.capture_dir)), "no bug capture is written while the tools are hidden")
	tools.set_overlay_mode(DebugTools.Overlay.STATE)
	tools.open_menu()
	_expect(tools.overlay_mode == DebugTools.Overlay.OFF and not tools.is_processing(), "the overlay cannot be forced on while the tools are hidden")
	game.set("touch_enabled", true)
	tools.call("_refresh_button")
	_expect(not tools.debug_button.visible and not tools.layer.visible, "touch play shows no DEBUG button while the tools are hidden")
	game.set("touch_enabled", false)
	game.call("_new_game")
	game.call("_finish_intro")
	await _settle(3)
	_expect(_idle(tools), "hidden tools stay idle during play too")
	tools.debug_build = true
	_expect(tools.available and tools.overlay_mode == DebugTools.Overlay.OFF and _idle(tools), "a debug build always has the tools, and with the overlay off they still cost nothing per frame")
	_expect(not GameSettings.load_config(_settings_path()).has_section_key(DebugTools.SETTINGS_SECTION, DebugTools.SETTINGS_KEY), "a debug build stores no unlock")
	await _free(game)


## WOLFDEN on the title unlocks a release build; the unlock is stored with the settings and kept by the
## next launch, and Lock debug tools forgets it again.
func _check_keyboard_code_and_storage() -> void:
	var game: Node2D = await _spawn(false)
	var tools: DebugTools = _tools(game)
	game.call("_save_settings")
	await _type("WOLFDEX")
	_expect(not tools.available, "a wrong word does not unlock the tools")
	await _type("WOL")
	await _send_key(KEY_1)
	await _type("FDEN")
	_expect(not tools.available, "the word has to be typed without other keys in between")
	await _type("WOLFDEN")
	_expect(tools.available and tools.unlocked, "typing WOLFDEN on the title unlocks the tools in a release build")
	_expect(tools.note.visible and tools.note_label.text == DebugTools.UNLOCKED_NOTE and tools.layer.visible, "the title shows 'Debug tools unlocked'")
	_expect(game.get("title_open") and not game.get("intro_active"), "typing the code does not start a game")
	var note_rect: Rect2 = tools.note.get_global_rect()
	for path: String in ["Brand", "LogoMark", "TitleLine", "GameTitle", "Subtitle", "NewGameButton", "ContinueButton", "ContinueNote", "CreditsButton", "SettingsButton", "ChangelogButton", "Credit"]:
		_expect(not note_rect.intersects((game.get_node("CanvasLayer/TitleScreen/" + path) as Control).get_global_rect()), "the title's note leaves %s clear" % path)
	var config: ConfigFile = GameSettings.load_config(_settings_path())
	_expect(GameSettings.boolean(config, DebugTools.SETTINGS_SECTION, DebugTools.SETTINGS_KEY, false), "the unlock is stored in the settings file")
	_expect(config.has_section_key("video", "fps_limit"), "storing the unlock keeps the other settings")
	tools.hide_note()
	_expect(_idle(tools), "once the note has gone the unlocked tools are idle until used")
	await _free(game)
	game = await _spawn(false)
	tools = _tools(game)
	_expect(tools.available and tools.unlocked, "the next launch of a release build reads the stored unlock")
	tools.lock()
	config = GameSettings.load_config(_settings_path())
	_expect(not tools.available and not tools.unlocked and not config.has_section_key(DebugTools.SETTINGS_SECTION, DebugTools.SETTINGS_KEY) and config.has_section_key("video", "fps_limit"), "Lock debug tools hides them and forgets the stored unlock, keeping the other settings")
	_expect(tools.note_label.text == DebugTools.LOCKED_NOTE and tools.note.visible, "locking says so")
	tools.debug_build = true
	_expect(not tools.available, "a lock holds for the rest of the session even in a debug build")
	tools.hide_note()
	_expect(_idle(tools), "locked tools are idle")
	await _type("WOLFDEN")
	_expect(tools.available, "the code unlocks them again after a lock")
	tools.lock()
	tools.hide_note()
	game.call("_new_game")
	await _type("WOLFDEN")
	_expect(not tools.available, "the code works only on the title screen")
	await _free(game)
	game = await _spawn(true)
	_expect(_tools(game).available, "a debug build has them again on its next launch")
	await _free(game)


## Up Up Down Down Left Right Left Right, B, A on a controller unlocks them; the last A presses nothing.
func _check_controller_code() -> void:
	var game: Node2D = await _spawn(false)
	var tools: DebugTools = _tools(game)
	var code: Array[JoyButton] = [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]
	for button: JoyButton in code:
		await _tap_pad(button)
	await _tap_pad(JOY_BUTTON_B)
	await _tap_pad(JOY_BUTTON_B)
	_expect(not tools.available, "a wrong last button does not unlock the tools")
	for button: JoyButton in code:
		await _tap_pad(button)
	await _tap_pad(JOY_BUTTON_B)
	_expect(not tools.available, "the code needs its last A")
	var new_game: Button = game.get_node("CanvasLayer/TitleScreen/NewGameButton") as Button
	new_game.grab_focus()
	await _tap_pad(JOY_BUTTON_A)
	_expect(tools.available and tools.unlocked and tools.note_label.text == DebugTools.UNLOCKED_NOTE, "Up Up Down Down Left Right Left Right B A unlocks the tools")
	_expect(new_game.has_focus() and game.get("title_open") and not game.get("intro_active"), "the code's last A does not press the focused NEW GAME")
	await _tap_pad(JOY_BUTTON_A)
	_expect(not game.get("title_open") and game.get("intro_active"), "the next A presses it as usual")
	_expect(GameSettings.boolean(GameSettings.load_config(_settings_path()), DebugTools.SETTINGS_SECTION, DebugTools.SETTINGS_KEY, false), "the controller unlock is stored too")
	tools.lock()
	await _free(game)


## Seven quick taps on the logo mark unlock them on touch; six, or a slow seventh, do not.
func _check_logo_code() -> void:
	var game: Node2D = await _spawn(false)
	var tools: DebugTools = _tools(game)
	var logo: Control = game.get_node("CanvasLayer/TitleScreen/LogoMark") as Control
	var centre: Vector2 = logo.get_global_rect().get_center()
	for _tap: int in 6:
		await _touch(centre)
	_expect(not tools.available, "six taps on the logo do not unlock the tools")
	tools.set("_last_logo_tap_msec", Time.get_ticks_msec() - DebugTools.LOGO_TAP_GAP_MSEC - 500)
	await _touch(centre)
	_expect(not tools.available, "a slow tap starts the count again")
	for _tap: int in 5:
		await _touch(centre)
	_expect(not tools.available, "the restarted count needs seven taps")
	await _touch(centre)
	_expect(tools.available and tools.note_label.text == DebugTools.UNLOCKED_NOTE, "seven quick taps on the logo mark unlock the tools")
	_expect(game.get("title_open") and not game.get("intro_active"), "tapping the logo starts nothing")
	await _touch(Vector2(120.0, 120.0))
	_expect(game.get("title_open"), "taps away from the logo do nothing")
	tools.lock()
	await _free(game)


## F3 cycles off, performance, state, state and zones, then off; only a shown overlay processes, and it
## keeps updating while the game is paused.
func _check_overlay() -> void:
	var game: Node2D = await _spawn(true)
	var tools: DebugTools = _tools(game)
	game.call("_new_game")
	game.call("_finish_intro")
	await _settle(3)
	await _send_key(KEY_F3)
	_expect(tools.overlay_mode == DebugTools.Overlay.PERFORMANCE and tools.overlay.visible and tools.layer.visible and tools.is_processing(), "F3 shows the performance page and starts refreshing it")
	var text: String = tools.overlay.body.get_parsed_text()
	await process_frame
	var tutorial: Control = game.get_node("CanvasLayer/TutorialPrompt") as Control
	_expect(tutorial.visible and not tools.overlay.get_global_rect().intersects(tutorial.get_global_rect()), "the performance page clears the corridor's tutorial card (%s)" % tools.overlay.get_global_rect())
	_expect(text.contains("PERFORMANCE") and text.contains("fps") and text.contains("ms frame") and text.contains("MB") and text.contains("nodes") and text.contains("draw calls"), "the performance page shows fps, frame time, memory, nodes and draw calls")
	await _send_key(KEY_F3)
	text = tools.overlay.body.get_parsed_text()
	_expect(tools.overlay_mode == DebugTools.Overlay.STATE and text.contains("STATE") and not text.contains("ZONES"), "F3 again shows the state page")
	for row: String in ["ROOM  lockdown · play · CHECK THE BREAKER", "ENGINEER  x 160", "WOLF  x", "follow", "SENTRY  not in this room", "HAZARDS", "MEMORY  —", "CHOICES  relay —", "SAVE  v%d · none on disk" % M0State.SAVE_VERSION, "CHEATS  none"]:
		_expect(text.contains(row), "the state page shows '%s'" % row)
	var overlay_rect: Rect2 = tools.overlay.get_global_rect()
	_expect(overlay_rect.position.x >= 0.0 and overlay_rect.end.x <= 480.0 and overlay_rect.position.y >= 78.0 and overlay_rect.end.y <= 340.0, "the state page fits in the upper left, below the top card and above the touch arrows (%s)" % overlay_rect)
	_expect(not overlay_rect.intersects((game.get_node("CanvasLayer/PauseButton") as Control).get_global_rect()) and not overlay_rect.intersects((game.get_node("CanvasLayer/TouchControls/Use") as Control).get_global_rect()), "the overlay never covers PAUSE or USE")
	game.call("_pause_game")
	_expect(paused and tools.can_process() and tools.is_processing(), "the overlay keeps refreshing while the game is paused")
	(game.get_node("Human") as M0Actor).position.x = 512.0
	await create_timer(DebugTools.REFRESH_SECONDS * 2.0, true).timeout
	_expect(tools.overlay.body.get_parsed_text().contains("ENGINEER  x 512"), "the paused state page follows what changes")
	game.call("_resume_game")
	await _send_key(KEY_F3)
	_expect(tools.overlay_mode == DebugTools.Overlay.ZONES and tools.overlay.body.get_parsed_text().contains("STATE + ZONES"), "F3 a third time shows the state page with zones")
	await _send_key(KEY_F3)
	_expect(tools.overlay_mode == DebugTools.Overlay.OFF and _idle(tools), "F3 a fourth time turns the overlay off and stops all processing")
	var changes: Array[int] = []
	tools.overlay_mode_changed.connect(func(mode: int) -> void: changes.append(mode))
	tools.cycle_overlay()
	tools.set_overlay_mode(DebugTools.Overlay.OFF)
	_expect(changes == [DebugTools.Overlay.PERFORMANCE, DebugTools.Overlay.OFF], "overlay changes are announced")
	tools.set_overlay_mode(DebugTools.Overlay.STATE)
	tools.debug_build = false
	_expect(not tools.available and _idle(tools), "hiding the tools turns a shown overlay off")
	await _free(game)


## Main.debug_snapshot and DebugTools.dump say what the game is doing, from its own state, without
## changing it, as plain values a JSON file can hold.
func _check_snapshot() -> void:
	var game: Node2D = await _spawn(true)
	var tools: DebugTools = _tools(game)
	var title: Dictionary = tools.dump()
	_expect(title.get("beat") == "title" and title.get("room") == "lockdown" and (title.get("save") as Dictionary).get("exists") == false and (title.get("save") as Dictionary).get("checkpoint") == "none", "on the title the dump says title and that no save exists")
	for key: String in ["room", "beat", "objective", "line", "engineer", "wolf", "sentry", "pressure_line", "drop_arm", "bolt", "hazards", "memory", "choices", "flags", "state", "performance", "save", "build", "debug", "time"]:
		_expect(title.has(key), "the dump has '%s'" % key)
	var state: M0State = _junction_state(false)
	_expect(state.save_to_disk(str(game.get("save_path"))), "a junction entry save is written")
	game.call("_load_game")
	await _settle(2)
	var line: PressureLine = game.get("pressure_line") as PressureLine
	line.arm()
	line.crank(1.2)
	game.call("_update_controls")
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	var side: int = wolf.follow_side
	var snapshot: Dictionary = game.call("debug_snapshot")
	_expect(wolf.follow_side == side, "taking a snapshot does not move WOLF's follow side")
	_expect(snapshot["room"] == "junction" and (snapshot["pressure_line"] as Dictionary)["state"] == "charged" and (snapshot["pressure_line"] as Dictionary)["turns"] == PressureLine.TURNS_NEEDED, "the snapshot shows the charged pressure line")
	_expect((snapshot["hazards"] as Dictionary)["blast"] == true and (snapshot["hazards"] as Dictionary)["vent"] == false, "with the fuse lit the blast is armed, the vent is not")
	_expect((snapshot["wolf"] as Dictionary)["why"] == "hold: clear of the vent and blast" and is_equal_approx(float((snapshot["wolf"] as Dictionary)["target_x"]), JunctionRoom.WOLF_CLEAR_X), "WOLF's target and reason come from the room's own spot")
	_expect((snapshot["sentry"] as Dictionary)["active"] == true and (snapshot["sentry"] as Dictionary)["state"] == "dormant" and is_equal_approx(float((snapshot["sentry"] as Dictionary)["sight_range"]), SentryBrain.SIGHT_RANGE), "the dormant sentry and its real sight range")
	_expect((snapshot["choices"] as Dictionary)["relay"] == "disclose → WOLF" and (snapshot["choices"] as Dictionary)["mirror"] == "wolf", "the run's relay and mirror choices")
	_expect((snapshot["memory"] as Dictionary).get("choice_id") == M0State.DISCLOSE, "WOLF's memory of the relay")
	state = _junction_state(true)
	_expect(state.save_to_disk(str(game.get("save_path"))), "a door-blown save is written")
	game.call("_load_game")
	await _settle(2)
	var dump: Dictionary = tools.dump()
	var sentry: Dictionary = dump["sentry"]
	_expect(sentry["state"] == "patrol" and sentry["fixated_on"] == "—" and float(sentry["x"]) <= SentryBrain.PATROL_MAX_X and float(sentry["x"]) >= SentryBrain.PATROL_MIN_X, "after the blast the sentry patrols its lane, fixed on nobody")
	_expect((dump["wolf"] as Dictionary)["why"] == "hold: at the rubble", "WOLF holds at the rubble until asked")
	var save: Dictionary = dump["save"]
	_expect(save["exists"] == true and save["checkpoint"] == "junction, door blown" and save["version"] == M0State.SAVE_VERSION and save["file_version"] == M0State.SAVE_VERSION, "the dump reads the checkpoint on disk")
	_expect(not FileAccess.file_exists(str(game.get("save_path")) + ".tmp"), "reading the save writes nothing")
	var round_trip: Variant = JSON.parse_string(JSON.stringify(dump))
	_expect(round_trip is Dictionary and (round_trip as Dictionary).get("room") == "junction" and ((round_trip as Dictionary).get("state") as Dictionary).get("door_blown") == true, "the dump survives a JSON round trip")
	tools.set_overlay_mode(DebugTools.Overlay.STATE)
	var text: String = tools.overlay.body.get_parsed_text()
	_expect(text.contains("SENTRY  patrol") and text.contains("sight %.0f" % SentryBrain.SIGHT_RANGE) and text.contains("LINE  blown") and text.contains("junction, door blown") and text.contains("CHOICES  relay disclose → WOLF · mirror wolf"), "the state page shows the junction's machines, the choices and the save")
	# At the touch framing the actors stand highest on screen; the tallest page still ends above them.
	game.set("touch_enabled", true)
	game.call("_start_gameplay_camera")
	await _settle(2)
	tools.set_overlay_mode(DebugTools.Overlay.STATE)
	await process_frame
	var bottom: float = tools.overlay.get_global_rect().end.y
	for actor_path: String in ["Human", "Wolf"]:
		var sprite: Sprite2D = (game.get_node(actor_path) as M0Actor).body_sprite
		var head: float = (sprite.get_global_transform_with_canvas() * sprite.get_rect().position).y
		_expect(bottom < head, "the junction's state page (bottom %.0f) ends above %s's sprite (top %.0f) at the touch framing" % [bottom, actor_path, head])
	game.set("touch_enabled", false)
	tools.cheats_used = true
	tools.set_overlay_mode(DebugTools.Overlay.STATE)
	_expect(tools.overlay.body.get_parsed_text().contains("CHEATS  USED") and (tools.dump()["debug"] as Dictionary)["cheats_used"] == true, "a cheat flags the state page and the dump")
	await _free(game)


## F12 writes a screenshot (when a frame was rendered) and a JSON dump, and shows where.
func _check_capture() -> void:
	var game: Node2D = await _spawn(true)
	var tools: DebugTools = _tools(game)
	tools.capture_dir = base + "-captures"
	var written: Array[Dictionary] = []
	tools.captured.connect(func(paths: Dictionary) -> void: written.append(paths))
	game.call("_new_game")
	game.call("_finish_intro")
	await _settle(3)
	await _send_key(KEY_F12)
	var paths: Dictionary = tools.last_capture
	_expect(written.size() == 1 and written[0] == paths, "F12 writes one bug capture")
	var json_path: String = str(paths.get("json", ""))
	_expect(json_path.begins_with(tools.capture_dir + "/") and json_path.ends_with(".json") and FileAccess.file_exists(json_path), "the capture's JSON dump is in the capture folder (%s)" % json_path)
	var headless: bool = DisplayServer.get_name() == "headless"
	var png_path: String = str(paths.get("png", ""))
	_expect(png_path.is_empty() if headless else (png_path == json_path.trim_suffix(".json") + ".png" and FileAccess.file_exists(png_path)), "the screenshot sits beside the dump (none without a rendered frame)")
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	_expect(data is Dictionary and (data as Dictionary).get("room") == "lockdown" and (data as Dictionary).has("engineer") and (data as Dictionary).has("performance") and ((data as Dictionary).get("capture") as Dictionary).get("json") == json_path, "the dump holds the overlay's data, positions and flags")
	_expect(tools.note.visible and tools.note_label.text.contains(json_path if headless else png_path), "the capture shows its path")
	game.call("_pause_game")
	var paused_paths: Dictionary = tools.capture()
	_expect(not paused_paths.is_empty() and paused_paths["json"] != json_path and FileAccess.file_exists(str(paused_paths["json"])), "a second capture, even paused, gets its own file")
	game.call("_resume_game")
	tools.hide_note()
	_expect(_idle(tools), "after a capture the tools are idle again")
	await _free(game)


## The DEBUG button shows for touch play only, clear of PAUSE, USE, the arrows and the logo; it, the
## backquote and both sticks ask for the debug menu.
func _check_touch_button_and_menu_inputs() -> void:
	var game: Node2D = await _spawn(true)
	var tools: DebugTools = _tools(game)
	var button: Button = tools.debug_button
	_expect(not button.visible, "no DEBUG button without touch")
	await _touch(Vector2(120.0, 300.0))
	game.set("touch_enabled", true)
	tools.call("_refresh_button")
	_expect(button.visible and tools.layer.visible and button.focus_mode == Control.FOCUS_NONE, "touch play shows the DEBUG button, which keyboard and controller focus skip")
	var rect: Rect2 = button.get_global_rect()
	_expect(Rect2(0.0, 0.0, 960.0, 540.0).encloses(rect), "the DEBUG button is on screen")
	for path: String in ["CanvasLayer/PauseButton", "CanvasLayer/TouchControls/Use", "CanvasLayer/TouchControls/Left", "CanvasLayer/TouchControls/Right", "CanvasLayer/TitleScreen/LogoMark", "CanvasLayer/TitleScreen/NewGameButton", "CanvasLayer/TopBar"]:
		_expect(not rect.intersects((game.get_node(path) as Control).get_global_rect()), "the DEBUG button never covers %s" % path.get_file())
	_expect(rect.end.y < 260.0, "the DEBUG button sits above where the actors stand")
	game.call("_new_game")
	game.call("_finish_intro")
	await _settle(2)
	_expect(button.visible, "the DEBUG button stays for touch play")
	game.call("_pause_game")
	await process_frame
	_expect(not button.visible, "Pause hides the DEBUG button")
	game.call("_resume_game")
	await process_frame
	_expect(button.visible, "it comes back on resume")
	await _tap_pad(JOY_BUTTON_X)
	_expect(not button.visible, "controller play hides the DEBUG button")
	await _touch(Vector2(480.0, 200.0))
	_expect(button.visible, "touch brings it back")
	button.pressed.emit()
	_expect(tools.overlay_mode == DebugTools.Overlay.PERFORMANCE, "with no debug menu to open, DEBUG steps the overlay on")
	tools.set_overlay_mode(DebugTools.Overlay.OFF)
	tools.menu_requested.connect(_on_menu_requested)
	button.pressed.emit()
	_expect(menu_requests == 1 and tools.overlay_mode == DebugTools.Overlay.OFF, "DEBUG asks for the debug menu")
	await _send_key(KEY_QUOTELEFT)
	_expect(menu_requests == 2, "backquote asks for the debug menu")
	await _send_pad(JOY_BUTTON_LEFT_STICK, true)
	_expect(menu_requests == 2, "one stick press alone does not")
	await _send_pad(JOY_BUTTON_RIGHT_STICK, true)
	_expect(menu_requests == 3, "pressing both sticks (L3 + R3) asks for the debug menu")
	await _send_pad(JOY_BUTTON_RIGHT_STICK, false)
	await _send_pad(JOY_BUTTON_LEFT_STICK, false)
	await _send_pad(JOY_BUTTON_RIGHT_STICK, true)
	await _send_pad(JOY_BUTTON_RIGHT_STICK, false)
	_expect(menu_requests == 3, "a released stick is not still held")
	tools.menu_open = true
	await _touch(Vector2(480.0, 200.0))
	_expect(not button.visible, "an open debug menu hides the DEBUG button")
	tools.menu_open = false
	tools.debug_build = false
	_expect(not button.visible and not tools.layer.visible, "hiding the tools hides the DEBUG button")
	await _send_key(KEY_QUOTELEFT)
	_expect(menu_requests == 3, "backquote does nothing while the tools are hidden")
	game.set("touch_enabled", false)
	await _free(game)


func _on_menu_requested() -> void:
	menu_requests += 1


func _spawn(debug_build: bool) -> Node2D:
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("settings_path", _settings_path())
	game.set("save_path", base + "-save.json")
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	await process_frame
	_tools(game).debug_build = debug_build
	return game


func _free(game: Node2D) -> void:
	paused = false
	game.queue_free()
	await process_frame
	await process_frame


func _tools(game: Node2D) -> DebugTools:
	return game.get("debug_tools") as DebugTools


func _settings_path() -> String:
	return base + ".cfg"


## True when the tools neither process nor draw anything.
func _idle(tools: DebugTools) -> bool:
	return not tools.is_processing() and not tools.is_physics_processing() and not tools.layer.visible and not tools.overlay.visible and not tools.debug_button.visible and not tools.note.visible


## A completed Records run (disclose, WOLF's readout) carried into the junction, with the door blown or not.
func _junction_state(door_blown: bool) -> M0State:
	var state: M0State = M0State.new()
	state.record_choice(M0State.DISCLOSE)
	state.arm_breaker()
	state.activate_power("wolf")
	state.reach_checkpoint()
	state.enter_records()
	state.preserve_purge_trace()
	state.preserve_mirror_trace("wolf")
	state.complete_chapter()
	state.enter_junction()
	if door_blown:
		state.blow_door()
		state.human_position = Vector2(500.0, 410.0)
		state.wolf_position = Vector2(448.0, 423.0)
	return state


func _type(word: String) -> void:
	for letter: String in word:
		await _send_key(OS.find_keycode_from_string(letter))


func _send_key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame


func _send_pad(index: JoyButton, pressed: bool) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = pressed
	Input.parse_input_event(event)
	await process_frame


func _tap_pad(index: JoyButton) -> void:
	await _send_pad(index, true)
	await _send_pad(index, false)


## A one-finger tap at [param canvas_pos] in the 960x540 canvas, sent in window pixels as the OS sends it.
func _touch(canvas_pos: Vector2) -> void:
	var pos: Vector2 = root.get_final_transform() * canvas_pos
	for pressed: bool in [true, false]:
		var touch: InputEventScreenTouch = InputEventScreenTouch.new()
		touch.index = 0
		touch.position = pos
		touch.pressed = pressed
		Input.parse_input_event(touch)
		await process_frame


func _settle(frames: int) -> void:
	for _i: int in range(frames):
		await process_frame


func _clean() -> void:
	for path: String in [_settings_path(), base + "-save.json", base + "-save.json.tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var captures: String = ProjectSettings.globalize_path(base + "-captures")
	if DirAccess.dir_exists_absolute(captures):
		for file: String in DirAccess.get_files_at(captures):
			DirAccess.remove_absolute(captures.path_join(file))
		DirAccess.remove_absolute(captures)


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("Debug tools check failed: " + label)
