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
	await _check_overlay_steps_aside()
	await _check_snapshot()
	await _check_capture()
	await _check_zones_corridor()
	await _check_zones_records()
	await _check_zones_junction()
	await _check_zones_keep_clear()
	await _check_custom_draw_boxes()
	await _check_zones_controller_toggles()
	await _check_capture_with_boxes()
	await _check_capture_bounded_wait()
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
	tools.call("_refresh_view")
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
	var debug_numbers: Dictionary = DebugTools.performance(true)
	_expect(debug_numbers["memory_mb"] is float and float(debug_numbers["memory_mb"]) > 0.0 and debug_numbers.has("video_mb"), "a debug build reports static memory, and video memory too")
	var release_numbers: Dictionary = DebugTools.performance(false)
	_expect(release_numbers["memory_mb"] == null and release_numbers["video_mb"] is float, "where Godot has no static memory figure (release builds) memory is null, not 0, and video memory is still reported")
	var release_text: String = DebugOverlay.performance_text(release_numbers)
	_expect(release_text.contains("MEM[/color]  n/a · video") and not release_text.contains(" 0 MB ·"), "the performance page says static memory is unavailable instead of 0 MB")
	var release_state: String = DebugOverlay.state_text({"performance": release_numbers})
	_expect(release_state.contains("video") and not release_state.contains("· 0 MB ·"), "the state page shows video memory when static memory is unavailable")
	await _send_key(KEY_F3)
	text = tools.overlay.body.get_parsed_text()
	_expect(tools.overlay_mode == DebugTools.Overlay.STATE and text.contains("STATE") and not text.contains("ZONES"), "F3 again shows the state page")
	for row: String in ["ROOM  lockdown · play · CHECK THE BREAKER", "ENGINEER  x 160", "WOLF  x", "follow", "SENTRY  not in this room", "HAZARDS", "MEMORY  —", "CHOICES  relay —", "SAVE  v%d · none on disk" % M0State.SAVE_VERSION, "CHEATS  none"]:
		_expect(text.contains(row), "the state page shows '%s'" % row)
	var overlay_rect: Rect2 = tools.overlay.get_global_rect()
	_expect(overlay_rect.position.x >= 0.0 and overlay_rect.end.x <= 480.0 and overlay_rect.position.y >= 78.0 and overlay_rect.end.y <= 340.0, "the state page fits in the upper left, below the top card and above the touch arrows (%s)" % overlay_rect)
	_expect(not overlay_rect.intersects((game.get_node("CanvasLayer/PauseButton") as Control).get_global_rect()) and not overlay_rect.intersects((game.get_node("CanvasLayer/TouchControls/Use") as Control).get_global_rect()), "the overlay never covers PAUSE or USE")
	# A pause with no card over the game (the debug menu's, a frame step's) keeps the overlay up.
	paused = true
	await process_frame
	_expect(paused and tools.overlay.visible and tools.can_process() and tools.is_processing(), "the overlay keeps refreshing while the game is paused")
	(game.get_node("Human") as M0Actor).position.x = 512.0
	await create_timer(DebugTools.REFRESH_SECONDS * 2.0, true).timeout
	_expect(tools.overlay.body.get_parsed_text().contains("ENGINEER  x 512"), "the paused state page follows what changes")
	paused = false
	await process_frame
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


## The game's own cards come first: Pause, Settings, the END OF SLICE card and the title's Credits and
## Changelog hide the overlay (which stops refreshing) until they close, and so does an answer button
## that would sit under it (the touch layout's choice row); the keyboard layout's answers stay clear.
func _check_overlay_steps_aside() -> void:
	var game: Node2D = await _spawn(true)
	var tools: DebugTools = _tools(game)
	tools.set_overlay_mode(DebugTools.Overlay.STATE)
	_expect(tools.overlay.visible and tools.is_processing(), "the overlay shows on the title")
	for card: Array in [["_show_credits", "credits_screen", "Credits"], ["_show_changelog", "changelog_screen", "Changelog"]]:
		game.call(card[0])
		await process_frame
		_expect(not tools.overlay.visible and not tools.is_processing() and tools.overlay_mode == DebugTools.Overlay.STATE, "the title's %s card hides the overlay, which stops refreshing" % card[2])
		game.call("_hide_title_overlay", game.get(card[1]))
		await process_frame
		_expect(tools.overlay.visible and tools.is_processing(), "the overlay comes back when %s closes" % card[2])
	game.call("_show_title_settings")
	await process_frame
	_expect(not tools.overlay.visible and not tools.is_processing(), "the title's Settings hides the overlay")
	game.call("_on_settings_back")
	await process_frame
	_expect(tools.overlay.visible, "the overlay comes back after the title's Settings")
	game.call("_new_game")
	game.call("_finish_intro")
	await _settle(3)
	_expect(tools.overlay.visible and tools.is_processing(), "the overlay shows in play")
	game.call("_pause_game")
	await process_frame
	_expect(not tools.overlay.visible and not tools.is_processing() and not tools.layer.visible, "the Pause menu hides the overlay, which stops refreshing")
	game.call("_show_settings")
	await process_frame
	_expect(not tools.overlay.visible and not tools.is_processing(), "Settings hides the overlay")
	game.call("_on_settings_back")
	await process_frame
	game.call("_resume_game")
	await process_frame
	_expect(tools.overlay.visible and tools.is_processing() and tools.overlay_mode == DebugTools.Overlay.STATE, "resuming brings the same page back")
	game.call("_ask_relay")
	await _settle(2)
	var choices: Array[Control] = [game.get("touch_choice_1") as Control, game.get("touch_choice_2") as Control]
	_expect(choices[0].visible and choices[1].visible, "the relay question shows its answers")
	_expect(tools.overlay.visible, "in the keyboard layout the overlay stays up during a question")
	for choice: Control in choices:
		_expect(not tools.overlay.get_global_rect().intersects(choice.get_global_rect()), "in the keyboard layout the overlay leaves %s clear (%s vs %s)" % [choice.name, tools.overlay.get_global_rect(), choice.get_global_rect()])
	# A phone build: the answers move into the touch row, and the next tap reaches the tools as it would.
	game.set("touch_enabled", true)
	game.call("_refresh_ui")
	await _touch(Vector2(480.0, 230.0))
	await _settle(2)
	_expect(game.get("waiting_for_choice"), "the tap answered nothing")
	_expect(choices[0].get_global_rect().position.x < DebugOverlay.footprint(false).end.x, "the touch layout's first answer sits in the overlay's column")
	_expect(not tools.overlay.visible and not tools.is_processing(), "in the touch layout the overlay steps aside for the answers instead of covering answer 1")
	_expect(tools.debug_button.visible, "the DEBUG button stays during a touch question")
	for choice: Control in choices:
		_expect(not tools.debug_button.get_global_rect().grow(8.0).intersects(choice.get_global_rect()), "the DEBUG button leaves %s clear" % choice.name)
	game.set("waiting_for_choice", false)
	game.call("_update_controls")
	await _settle(2)
	_expect(tools.overlay.visible and tools.is_processing(), "once answered the overlay comes back")
	tools.set_overlay_mode(DebugTools.Overlay.PERFORMANCE)
	game.set("waiting_for_choice", true)
	game.call("_update_controls")
	await _settle(2)
	_expect(not tools.overlay.visible, "the performance page steps aside for the touch answers too")
	game.set("waiting_for_choice", false)
	game.call("_update_controls")
	game.set("touch_enabled", false)
	tools.set_overlay_mode(DebugTools.Overlay.STATE)
	await _settle(2)
	game.call("_show_end_card")
	await process_frame
	_expect(not tools.overlay.visible and not tools.is_processing(), "the END OF SLICE card hides the overlay")
	game.call("_hide_end_card")
	await process_frame
	_expect(tools.overlay.visible and tools.is_processing(), "the overlay comes back after the card")
	tools.set_overlay_mode(DebugTools.Overlay.OFF)
	_expect(_idle(tools), "turned off, the overlay costs nothing again")
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
	_expect(not (tools.dump(false) as Dictionary).has("state") and (dump["state"] as Dictionary).has("door_blown"), "the overlay's refresh leaves out the full save state; dump() keeps it")
	tools.set_overlay_mode(DebugTools.Overlay.STATE)
	var reads: int = tools.save_reads
	await create_timer(DebugTools.REFRESH_SECONDS * 3.5, true).timeout
	_expect(tools.save_reads - reads <= 1, "the shown overlay reads the save on disk at most once a second, not on every refresh (%d reads)" % (tools.save_reads - reads))
	reads = tools.save_reads
	tools.dump()
	_expect(tools.save_reads == reads + 1, "dump() and captures always read the save fresh")
	tools.set_overlay_mode(DebugTools.Overlay.OFF)
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
	tools.call("_refresh_view")
	_expect(button.visible and tools.layer.visible and button.focus_mode == Control.FOCUS_NONE, "touch play shows the DEBUG button, which keyboard and controller focus skip")
	var rect: Rect2 = button.get_global_rect()
	_expect(Rect2(0.0, 0.0, 960.0, 540.0).encloses(rect), "the DEBUG button is on screen")
	for path: String in ["CanvasLayer/PauseButton", "CanvasLayer/TouchControls/Use", "CanvasLayer/TouchControls/Left", "CanvasLayer/TouchControls/Right", "CanvasLayer/TitleScreen/LogoMark", "CanvasLayer/TitleScreen/NewGameButton", "CanvasLayer/TopBar"]:
		_expect(not rect.intersects((game.get_node(path) as Control).get_global_rect()), "the DEBUG button never covers %s" % path.get_file())
	var pause_rect: Rect2 = (game.get_node("CanvasLayer/PauseButton") as Control).get_global_rect()
	_expect(not rect.grow(8.0).intersects(pause_rect), "the DEBUG button leaves a real gap before PAUSE, at its theme's full size (%s, PAUSE %s)" % [rect, pause_rect])
	_expect(rect.size.x >= button.get_combined_minimum_size().x and rect.size.y >= button.get_combined_minimum_size().y, "the DEBUG button's laid-out size already includes the theme's minimum")
	button.add_theme_font_size_override("font_size", 20)
	await process_frame
	_expect(not button.get_global_rect().grow(8.0).intersects(pause_rect) and is_equal_approx(button.get_global_rect().end.x, rect.end.x), "a larger theme minimum grows the DEBUG button to the left, keeping the gap before PAUSE (%s)" % button.get_global_rect())
	button.add_theme_font_size_override("font_size", 13)
	button.size = rect.size
	button.position = rect.position
	await process_frame
	game.call("_show_credits")
	await process_frame
	_expect(not button.visible, "the DEBUG button steps aside while the title's Credits card is up")
	game.call("_hide_title_overlay", game.get("credits_screen"))
	await process_frame
	_expect(button.visible, "it comes back when Credits closes")
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

## The zones page in the corridor: it draws only on that page and only while shown; every collision
## shape is drawn from its real shape and every render box from its sprite's or control's rect, in the
## world and on screen, following the camera; the use ranges match the rules that answer USE; the
## legend, F5, F6 and F7 turn each category on and off; and none of it costs anything once hidden.
func _check_zones_corridor() -> void:
	var game: Node2D = await _spawn(true)
	var tools: DebugTools = _tools(game)
	var zones: DebugZones = tools.zones
	_expect(zones.get_parent() == tools.layer and not zones.visible and not zones.is_processing(), "the zone drawing starts hidden and idle")
	game.call("_new_game")
	game.call("_finish_intro")
	await _settle(3)
	for page: int in [DebugTools.Overlay.PERFORMANCE, DebugTools.Overlay.STATE]:
		tools.set_overlay_mode(page)
		_expect(not zones.visible and not zones.is_processing(), "the %s page draws no zones" % DebugTools.OVERLAY_NAMES[page])
	tools.set_overlay_mode(DebugTools.Overlay.ZONES)
	await process_frame
	_expect(zones.visible and zones.is_processing() and tools.layer.visible and zones.legend.is_visible_in_tree(), "the zones page draws the zones, hitboxes and render boxes with their legend, redrawing every frame")
	_expect(tools.overlay.visible and tools.overlay.get_index() > zones.get_index(), "the state card stays up and draws over the boxes")
	var legend_rect: Rect2 = zones.legend.get_global_rect()
	_expect(Rect2(0.0, 0.0, 960.0, 540.0).encloses(legend_rect), "the legend is on screen (%s)" % legend_rect)
	for path: String in ["CanvasLayer/TopBar", "CanvasLayer/PauseButton", "CanvasLayer/TutorialPrompt", "CanvasLayer/TitleScreen/LogoMark", "CanvasLayer/TitleScreen/Brand"]:
		_expect(not legend_rect.intersects((game.get_node(path) as Control).get_global_rect()), "the legend leaves %s clear" % path.get_file())
	_expect(not legend_rect.intersects(tools.overlay.get_global_rect()), "the legend leaves the state card clear")
	for choice: String in ["touch_choice_1", "touch_choice_2"]:
		var button: Control = game.get(choice) as Control
		for layout: Array in [[Vector2(42.0, 88.0), Vector2(428.0, 76.0)], [Vector2(396.0, 88.0), Vector2(522.0, 40.0)]]:
			_expect(not legend_rect.intersects(Rect2(layout[0], layout[1])), "the legend leaves the answer row clear (%s)" % button.name)
	game.set("touch_enabled", true)
	tools.call("_refresh_view")
	_expect(not legend_rect.grow(6.0).intersects(tools.debug_button.get_global_rect()), "the legend leaves a gap before the DEBUG button (%s vs %s)" % [legend_rect, tools.debug_button.get_global_rect()])
	game.set("touch_enabled", false)
	tools.call("_refresh_view")
	var geometry: Dictionary = tools.dump()["geometry"]
	for key: String in ["camera", "zones", "hitboxes", "render_boxes", "legend", "rect_format", "screen_to_window"]:
		_expect(geometry.has(key), "the dump's geometry has '%s'" % key)
	_expect(not (tools.dump(false) as Dictionary).has("geometry"), "the overlay's frequent refresh leaves the geometry out")
	# Hitboxes: the real shapes, in the world and on screen.
	for path: String in ["Human/CollisionShape2D", "Wolf/CollisionShape2D", "Door/CollisionShape2D", "Floor/CollisionShape2D"]:
		var shape: CollisionShape2D = game.get_node(path) as CollisionShape2D
		var entry: Dictionary = _entry(geometry["hitboxes"], "path", path)
		var local: Rect2 = shape.shape.get_rect()
		_expect(not entry.is_empty() and _same_rect(entry["world_rect"], shape.get_global_transform() * local) and _same_rect(entry["screen_rect"], shape.get_global_transform_with_canvas() * local), "the %s hitbox is its real shape, in the world and on screen (%s)" % [path.get_slice("/", 0), entry.get("world_rect")])
	var human_box: Dictionary = _entry(geometry["hitboxes"], "path", "Human/CollisionShape2D")
	_expect(is_equal_approx(float(human_box["world_rect"][2]), M0State.HUMAN_HALF_WIDTH * 2.0) and is_equal_approx(float(_entry(geometry["hitboxes"], "path", "Wolf/CollisionShape2D")["world_rect"][2]), M0State.WOLF_HALF_WIDTH * 2.0), "the actors' hitboxes are as wide as the bodies the rules use")
	var seal: Dictionary = _entry(geometry["hitboxes"], "path", "Door/CollisionShape2D")
	_expect(seal["active"] == true and is_equal_approx(float(seal["world_rect"][0]), float(game.get_script().get_script_constant_map()["CORRIDOR_DOOR_LEFT_X"])), "the shut seal's hitbox starts at its face")
	var junction_door: String = str(game.get_path_to((game.get("junction_room") as JunctionRoom).door_shape))
	_expect(_entry(geometry["hitboxes"], "path", junction_door).get("active", true) == false, "the junction's door, out of play, is reported but not in force")
	# Render boxes: the sprite's and the control's own rects, with z-index and canvas layer.
	var sprite: Sprite2D = game.get_node("Human/BodySprite") as Sprite2D
	var sprite_box: Dictionary = _entry(geometry["render_boxes"], "path", "Human/BodySprite")
	_expect(not sprite_box.is_empty() and _same_rect(sprite_box["world_rect"], sprite.get_global_transform() * sprite.get_rect()) and _same_rect(sprite_box["screen_rect"], sprite.get_global_transform_with_canvas() * sprite.get_rect()), "the engineer's render box is the sprite's drawn rect, in the world and on screen")
	_expect(int(sprite_box.get("z_index", -99)) == 2 and int(sprite_box.get("layer", -1)) == 0 and sprite_box.get("visible") == true and sprite_box.get("active") == true, "the engineer's render box has the actors' z-index, the world layer and is drawn")
	var hint: Control = game.get_node("CanvasLayer/ContextHint") as Control
	var hint_box: Dictionary = _entry(geometry["render_boxes"], "path", "CanvasLayer/ContextHint")
	_expect(not hint_box.is_empty() and _same_rect(hint_box["world_rect"], hint.get_global_rect()) and _same_rect(hint_box["screen_rect"], hint.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, hint.size)) and int(hint_box["layer"]) == 2, "the hint panel's render box is its control rect on canvas layer 2")
	var hint_text: Dictionary = _entry(geometry["render_boxes"], "path", "CanvasLayer/ContextHint/Text")
	_expect(str(hint_text.get("text", "")) == (game.get_node("CanvasLayer/ContextHint/Text") as Label).text, "a label's render box carries its text")
	var plate: Sprite2D = null
	for node: Node in game.get_node("CorridorDepth").find_children("*", "Sprite2D", true, false):
		if (node as Sprite2D).is_visible_in_tree() and (node as Sprite2D).texture != null:
			plate = node as Sprite2D
			break
	var plate_box: Dictionary = _entry(geometry["render_boxes"], "path", str(game.get_path_to(plate))) if plate != null else {}
	_expect(not plate_box.is_empty() and _same_rect(plate_box["screen_rect"], plate.get_global_transform_with_canvas() * plate.get_rect()), "a plate layer's render box is where it draws through its parallax")
	var missing: int = 0
	for box: Dictionary in geometry["render_boxes"]:
		for key: String in ["path", "name", "kind", "world_rect", "screen_rect", "z_index", "layer", "visible", "alpha", "draw_order"]:
			if not box.has(key):
				missing += 1
	_expect(missing == 0 and (geometry["render_boxes"] as Array).size() > 50, "every render box gives its path, rects, z-index, layer and visibility (%d boxes, %d gaps)" % [(geometry["render_boxes"] as Array).size(), missing])
	_expect(_entry(geometry["render_boxes"], "path", "DebugTools/DebugLayer/DebugZones").is_empty() and _entry(geometry["render_boxes"], "name", "DrawLegend").is_empty(), "the debug tools leave themselves out of the render boxes")
	# Zones from the rules' own constants: each use range ends where the rule stops answering.
	var relay: Dictionary = _entry(geometry["zones"], "name", "use: relay")
	var bypass: Dictionary = _entry(geometry["zones"], "name", "use: bypass")
	var breaker: Dictionary = _entry(geometry["zones"], "name", "use: breaker")
	_expect(not relay.is_empty() and not bypass.is_empty() and not breaker.is_empty() and not _entry(geometry["zones"], "name", "use: safe point").is_empty() and not _entry(geometry["zones"], "name", "use: purge display").is_empty(), "the corridor shows every station's use range")
	_expect(_edges_match(game, "_at_relay", relay["x_range"], true), "the relay's drawn range is exactly where USE reaches the relay (%s)" % [relay["x_range"]])
	_expect(_edges_match(game, "_at_bypass", bypass["x_range"], false), "the bypass's drawn range is exactly where USE reaches the bypass (%s)" % [bypass["x_range"]])
	_expect(_edges_match(game, "_at_breaker", breaker["x_range"], false), "the breaker's drawn range is exactly where USE reaches the breaker (%s)" % [breaker["x_range"]])
	_expect(is_equal_approx(float(_entry(geometry["zones"], "name", "seal face")["x"]), float(seal["world_rect"][0])), "the seal's limit is drawn at its hitbox's face")
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	_expect(is_equal_approx(float(_entry(geometry["zones"], "name", "WOLF follow limit").get("x", -1.0)), wolf.follow_max_x), "WOLF's follow limit is drawn where it holds him")
	var gap: Dictionary = _entry(geometry["zones"], "name", "follow gap")
	var human: M0Actor = game.get_node("Human") as M0Actor
	_expect(not gap.is_empty() and is_equal_approx(float(gap["x_range"][1]) - float(gap["x_range"][0]), M0Actor.FOLLOW_GAP * 2.0) and is_equal_approx(float(gap["x_range"][0]), human.position.x - M0Actor.FOLLOW_GAP), "WOLF's follow gap is drawn around the engineer")
	var camera_limits: Dictionary = _entry(geometry["zones"], "name", "camera centre limits")
	var view_width: float = float(game.get_script().get_script_constant_map()["GAMEPLAY_VIEW_WIDTH"])
	_expect(not camera_limits.is_empty() and is_equal_approx(float(camera_limits["x_range"][0]), view_width * 0.5) and is_equal_approx(float(camera_limits["x_range"][1]), 960.0 - view_width * 0.5), "the camera's centre limits come from the play view's width")
	# They follow the camera: on screen each range starts where the canvas puts its world x.
	human.position.x = 700.0
	await create_timer(1.5).timeout
	geometry = tools.dump()["geometry"]
	var canvas: Transform2D = root.get_canvas_transform()
	bypass = _entry(geometry["zones"], "name", "use: bypass")
	_expect(is_equal_approx(float(bypass["screen_rect"][0]), (canvas * Vector2(float(bypass["x_range"][0]), RoomDepth.FLOOR_Y)).x) and float(bypass["screen_rect"][1]) > (canvas * Vector2(0.0, RoomDepth.FLOOR_Y)).y, "after the camera moves, the ranges are drawn where the world now is, under the floor line")
	sprite_box = _entry(geometry["render_boxes"], "path", "Human/BodySprite")
	_expect(_same_rect(sprite_box["screen_rect"], sprite.get_global_transform_with_canvas() * sprite.get_rect()), "the render boxes follow the camera too")
	# Within a row, no two ranges or names overlap.
	var overlaps: int = 0
	var rule_items: Array = (geometry["zones"] as Array) + (geometry["hitboxes"] as Array)
	for a: Dictionary in rule_items:
		for b: Dictionary in rule_items:
			if a == b or a.get("kind") != "x_range" or b.get("kind") != "x_range" or a.get("quiet", false) or b.get("quiet", false):
				continue
			var ra: Array = a["screen_rect"]
			var rb: Array = b["screen_rect"]
			if is_equal_approx(float(ra[1]), float(rb[1])) and float(ra[0]) < float(rb[0]) + float(rb[2]) and float(rb[0]) < float(ra[0]) + float(ra[2]):
				overlaps += 1
	_expect(overlaps == 0, "ranges sharing a lane never overlap (%d)" % overlaps)
	# Toggles: F5, F6, F7 and the legend.
	await _send_key(KEY_F6)
	_expect(zones.layers[DebugZones.HITBOXES] == false and not (zones.legend_buttons[DebugZones.HITBOXES] as Button).button_pressed and zones.layers[DebugZones.ZONES] and zones.layers[DebugZones.RENDER], "F6 turns the hitboxes off, and its legend button follows")
	_expect((tools.dump()["debug"] as Dictionary)["drawn"]["hitboxes"] == false and not (tools.dump()["geometry"]["hitboxes"] as Array).is_empty(), "the dump says the hitboxes are not drawn and still reports them")
	(zones.legend_buttons[DebugZones.HITBOXES] as Button).button_pressed = true
	_expect(zones.layers[DebugZones.HITBOXES] == true, "the legend's button turns them back on (a tap or click)")
	await _send_key(KEY_F5)
	await _send_key(KEY_F7)
	_expect(not zones.layers[DebugZones.ZONES] and not zones.layers[DebugZones.RENDER], "F5 and F7 turn the zones and the render boxes off")
	await _send_key(KEY_F5)
	await _send_key(KEY_F7)
	_expect(zones.layers[DebugZones.ZONES] and zones.layers[DebugZones.RENDER], "and on again")
	tools.set_overlay_mode(DebugTools.Overlay.STATE)
	await _send_key(KEY_F7)
	_expect(zones.layers[DebugZones.RENDER], "F7 does nothing off the zones page")
	# Pause steps aside; the title shows only what is on it.
	tools.set_overlay_mode(DebugTools.Overlay.ZONES)
	game.call("_pause_game")
	await process_frame
	_expect(not zones.visible and not zones.is_processing(), "the Pause menu hides the zone drawing, which stops redrawing")
	game.call("_resume_game")
	await process_frame
	_expect(zones.visible and zones.is_processing(), "it comes back on resume")
	game.call("_return_to_title")
	await _settle(2)
	geometry = tools.dump()["geometry"]
	var covered_world: bool = _entry(geometry["render_boxes"], "path", "Human/BodySprite").get("covered") == true and _entry(geometry["render_boxes"], "path", "Human/BodySprite").get("active") == false
	_expect((geometry["zones"] as Array).is_empty() and (geometry["hitboxes"] as Array).is_empty() and covered_world and _entry(geometry["render_boxes"], "path", "CanvasLayer/TitleScreen/NewGameButton").get("active") == true, "on the title only the title's own boxes are drawn; the world under it is reported as covered")
	tools.set_overlay_mode(DebugTools.Overlay.OFF)
	_expect(_idle(tools), "turned off, the zone drawing costs nothing")
	tools.set_overlay_mode(DebugTools.Overlay.ZONES)
	tools.debug_build = false
	_expect(_idle(tools), "hiding the tools hides the zone drawing too")
	await _free(game)


## Records Access: its three stations' use ranges and WOLF's spot at the mirror, from Main's constants.
func _check_zones_records() -> void:
	var game: Node2D = await _spawn(true)
	var tools: DebugTools = _tools(game)
	var state: M0State = M0State.new()
	state.record_choice(M0State.DISCLOSE)
	state.arm_breaker()
	state.activate_power("wolf")
	state.reach_checkpoint()
	state.enter_records()
	_expect(state.save_to_disk(str(game.get("save_path"))), "a Records save is written")
	game.call("_load_game")
	await _settle(3)
	tools.set_overlay_mode(DebugTools.Overlay.ZONES)
	var geometry: Dictionary = tools.dump()["geometry"]
	var constants: Dictionary = game.get_script().get_script_constant_map()
	var stations: Array = constants["RECORDS_STATIONS"]
	var names: Array[String] = ["use: purge queue", "use: mirror port", "use: exit"]
	for index: int in names.size():
		var entry: Dictionary = _entry(geometry["zones"], "name", names[index])
		var station: Vector4 = stations[index]
		_expect(not entry.is_empty() and is_equal_approx(float(entry["x_range"][0]), station.x - station.z) and is_equal_approx(float(entry["x_range"][1]), station.x + station.z), "Records shows '%s' from its station's reach" % names[index])
	# The Records rules test a station by the same centre and reach the hint uses.
	var human: M0Actor = game.get_node("Human") as M0Actor
	var purge: Dictionary = _entry(geometry["zones"], "name", "use: purge queue")
	human.position.x = float(purge["x_range"][1])
	_expect(str(game.call("_context_hint")).contains("purge"), "at the purge queue range's edge the hint offers the purge queue")
	human.position.x = float(purge["x_range"][1]) + 1.0
	_expect(not str(game.call("_context_hint")).contains("E: copy the purge"), "just past it the purge queue is out of reach")
	_expect(is_equal_approx(float(_entry(geometry["zones"], "name", "WOLF: mirror").get("x", -1.0)), float(constants["WOLF_MIRROR_X"])), "WOLF's mirror spot is drawn")
	_expect(_entry(geometry["zones"], "name", "use: relay").is_empty() and _entry(geometry["hitboxes"], "name", "blast").is_empty(), "nothing from the other rooms is drawn")
	_expect(_entry(geometry["hitboxes"], "path", "Door/CollisionShape2D").get("active") == false, "the corridor seal, out of play, is not in force here")
	tools.set_overlay_mode(DebugTools.Overlay.OFF)
	await _free(game)


## The Service Junction: its hurtboxes and door from their real shapes, the blast, vent, cloud, sentry
## contact and tank ranges from the rules' constants and tests, the sentry's sight from its brain,
## the tank's footprint from the tank, and each range in force exactly while its rule is.
func _check_zones_junction() -> void:
	var game: Node2D = await _spawn(true)
	var tools: DebugTools = _tools(game)
	_expect(_junction_state(false).save_to_disk(str(game.get("save_path"))), "a junction entry save is written")
	game.call("_load_game")
	await _settle(3)
	tools.set_overlay_mode(DebugTools.Overlay.ZONES)
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var vent_path: String = str(game.get_path_to(room.vent_hazard.get_child(0)))
	var door_path: String = str(game.get_path_to(room.door_shape))
	var cloud_path: String = str(game.get_path_to(room.cloud_hazard.get_child(0)))
	var sentry_path: String = ""
	for child: Node in room.sentry.get_children():
		if child is CollisionShape2D:
			sentry_path = str(game.get_path_to(child))
	var geometry: Dictionary = tools.dump()["geometry"]
	var vent: Dictionary = _entry(geometry["hitboxes"], "path", vent_path)
	_expect(not vent.is_empty() and is_equal_approx(float(vent["world_rect"][0]), PressureLine.VENT_GRATE_MIN_X) and is_equal_approx(float(vent["world_rect"][0]) + float(vent["world_rect"][2]), PressureLine.VENT_GRATE_MAX_X) and vent["active"] == true and vent["armed"] == false, "the vent's hurtbox is drawn over its grate, monitoring and not armed")
	var door: Dictionary = _entry(geometry["hitboxes"], "path", door_path)
	_expect(not door.is_empty() and door["active"] == true and is_equal_approx(float(door["world_rect"][0]), M0State.JUNCTION_DOOR_LEFT_X), "the sealed door's hitbox starts at its face")
	_expect(is_equal_approx(float(_entry(geometry["zones"], "name", "door face").get("x", -1.0)), M0State.JUNCTION_DOOR_LEFT_X), "the door's limit is drawn at its face")
	var sentry_body: Dictionary = _entry(geometry["hitboxes"], "path", sentry_path)
	_expect(not sentry_body.is_empty() and is_equal_approx(float(sentry_body["world_rect"][2]), SentryBrain.HALF_WIDTH * 2.0), "the sentry's body is drawn as wide as the body its brain uses")
	var cloud_box: Dictionary = _entry(geometry["hitboxes"], "path", cloud_path)
	_expect(not cloud_box.is_empty() and is_equal_approx(float(cloud_box["world_rect"][0]), DropArm.MARK_X - DropArm.CLOUD_HALF_WIDTH) and is_equal_approx(float(cloud_box["world_rect"][2]), DropArm.CLOUD_HALF_WIDTH * 2.0), "the cloud's hurtbox is drawn as wide as the cloud")
	var on_vent: Dictionary = _entry(geometry["hitboxes"], "name", "vent (engineer x)")
	_expect(_edges_match_static(PressureLine.is_on_vent, on_vent["x_range"]) and on_vent["active"] == false, "the vent's engineer range is exactly where is_on_vent holds, idle before the line builds")
	var blast: Dictionary = _entry(geometry["hitboxes"], "name", "blast")
	_expect(_edges_match_static(PressureLine.is_in_blast, blast["x_range"]) and blast["active"] == false, "the blast range is exactly where is_in_blast holds, idle before the fuse")
	_expect(_edges_match(game, "_at_arm_panel", _entry(geometry["zones"], "name", "use: tank release")["x_range"], false), "the tank release's range is exactly where USE reaches it")
	_expect(_entry(geometry["zones"], "name", "use: tank release")["active"] == false, "before the door is blown the tank release's range is drawn as not answering USE")
	_expect(is_equal_approx(float(_entry(geometry["zones"], "name", "use: exit bolt")["x_range"][0]), JunctionRoom.BOLT_REACH_MIN_X), "the exit bolt's range starts at its reach")
	var line: PressureLine = game.get("pressure_line") as PressureLine
	line.arm()
	geometry = tools.dump()["geometry"]
	_expect(_entry(geometry["hitboxes"], "name", "vent (engineer x)")["active"] == true and _entry(geometry["hitboxes"], "name", "blast")["active"] == false, "once the line builds the vent range is live and the blast is not")
	line.crank(PressureLine.TURN_SECONDS * PressureLine.TURNS_NEEDED + 0.01)
	geometry = tools.dump()["geometry"]
	_expect(_entry(geometry["hitboxes"], "name", "blast")["active"] == true and _entry(geometry["hitboxes"], "name", "vent (engineer x)")["active"] == false, "with the fuse lit the blast range is live")
	var blast_area: Array = _entry(geometry["hitboxes"], "name", "blast").get("screen_area", [])
	_expect(blast_area.size() == 4 and float(blast_area[3]) > 0.0, "the blast also shades the room above its range")
	# The lane, door blown.
	_expect(_junction_state(true).save_to_disk(str(game.get("save_path"))), "a door-blown save is written")
	game.call("_load_game")
	await _settle(3)
	var brain: SentryBrain = game.get("sentry_brain") as SentryBrain
	geometry = tools.dump()["geometry"]
	_expect(_entry(geometry["zones"], "name", "use: tank release")["active"] == true, "with the door blown the tank release's range answers USE")
	var contact: Dictionary = _entry(geometry["hitboxes"], "name", "sentry contact")
	_expect(not contact.is_empty() and is_equal_approx(float(contact["x_range"][0]), brain.x - SentryBrain.CONTACT_RANGE) and is_equal_approx(float(contact["x_range"][1]), brain.x + SentryBrain.CONTACT_RANGE) and contact["active"] == false, "the sentry's contact range is drawn around it, idle while it patrols")
	var sight: Dictionary = _entry(geometry["zones"], "name", "sight %.0f" % SentryBrain.SIGHT_RANGE)
	var tip: float = brain.x + brain.facing * SentryBrain.SIGHT_RANGE
	_expect(not sight.is_empty() and sight["kind"] == "ray" and is_equal_approx(float(sight["x_range"][0]), minf(brain.x, tip)) and is_equal_approx(float(sight["x_range"][1]), maxf(brain.x, tip)) and is_equal_approx(float(sight["facing"]), brain.facing), "the sentry's sight is drawn from it, the way it faces, as far as it sees")
	var hit: Dictionary = _entry(geometry["hitboxes"], "name", "tank hit range")
	_expect(_edges_match_static(DropArm.is_hit, hit["x_range"]), "the tank's hit range is exactly where is_hit holds (the brackets)")
	var cloud: Dictionary = _entry(geometry["hitboxes"], "name", "cloud (engineer x)")
	_expect(_edges_match_static(DropArm.in_cloud, cloud["x_range"]) and cloud["active"] == false, "the cloud's engineer range is exactly where in_cloud holds, idle with no cloud")
	var footprint: Dictionary = _entry(geometry["hitboxes"], "name", "tank footprint")
	_expect(not footprint.is_empty() and _same_rect(footprint["world_rect"], Rect2(room.tank.global_position - JunctionRoom.TANK_SIZE * 0.5, JunctionRoom.TANK_SIZE)), "the tank's footprint is drawn where the tank hangs, at its size")
	var alcove: Dictionary = _entry(geometry["zones"], "name", "alcove (out of sight)")
	_expect(not SentryBrain.is_exposed(float(alcove["x_range"][0])) and not SentryBrain.is_exposed(float(alcove["x_range"][1])) and SentryBrain.is_exposed(float(alcove["x_range"][1]) + 0.5), "the alcove is drawn exactly where the sentry cannot see the engineer")
	_expect(is_equal_approx(float(_entry(geometry["zones"], "name", "chase limit").get("x", -1.0)), SentryBrain.CHASE_MIN_X) and not _entry(geometry["zones"], "name", "WOLF: bait").is_empty() and not _entry(geometry["zones"], "name", "WOLF: rubble").is_empty(), "the chase limit and WOLF's bait and rubble spots are drawn")
	var target: Dictionary = {}
	for zone: Dictionary in geometry["zones"]:
		if zone.get("target", false):
			target = zone
	_expect(not target.is_empty() and is_equal_approx(float(target["x"]), JunctionRoom.WOLF_RUBBLE_X) and str(target["why"]) == "hold: at the rubble", "WOLF's current target and why are drawn")
	_expect(_entry(geometry["zones"], "name", "door face").is_empty() and _entry(geometry["hitboxes"], "path", door_path).get("active") == false, "a blown door blocks nothing and draws no limit")
	# A miss arms the cloud: its hurtbox and range are in force while it hangs there.
	var arm: DropArm = game.get("drop_arm") as DropArm
	arm.drop()
	arm.advance(DropArm.FALL_SECONDS, DropArm.MARK_X + 200.0)
	room.sync_arm(arm)
	geometry = tools.dump()["geometry"]
	_expect(_entry(geometry["hitboxes"], "name", "cloud (engineer x)")["active"] == true and _entry(geometry["hitboxes"], "path", cloud_path).get("armed") == true, "after a miss the cloud's range and hurtbox are in force")
	tools.set_overlay_mode(DebugTools.Overlay.OFF)
	_expect(_idle(tools), "turned off in the junction, the tools are idle")
	await _free(game)


## Nothing drawn covers the touch arrows, USE, PAUSE or the hint and dialogue text, and no name sits
## on an actor or on another name, in the keyboard and the touch layout, in the corridor and the lane.
## A range wholly off screen is reported, not drawn.
func _check_zones_keep_clear() -> void:
	var game: Node2D = await _spawn(true)
	var tools: DebugTools = _tools(game)
	game.call("_new_game")
	game.call("_finish_intro")
	await _settle(3)
	tools.set_overlay_mode(DebugTools.Overlay.ZONES)
	for layout: String in ["keyboard", "touch"]:
		game.set("touch_enabled", layout == "touch")
		game.call("_refresh_ui")
		tools.call("_refresh_view")
		await _settle(2)
		var geometry: Dictionary = tools.dump()["geometry"]
		var clear: Dictionary = geometry["keep_clear"]
		var names: Array[String] = []
		for entry: Dictionary in clear["controls_and_text"]:
			names.append(str(entry["name"]))
		var expected: Array[String] = ["pause_button", "context_hint_text text", "story text"]
		if layout == "touch":
			expected.append_array(["touch_left", "touch_right", "touch_use"])
		_expect(expected.all(func(name: String) -> bool: return names.has(name)), "the %s layout protects PAUSE, the hint and dialogue text%s (%s)" % [layout, " and the touch controls" if layout == "touch" else "", names])
		var hint_text: Rect2 = DebugZones.text_rect(game.get_node("CanvasLayer/ContextHint/Text") as Label)
		var hint_box: Rect2 = (game.get_node("CanvasLayer/ContextHint/Text") as Control).get_global_rect()
		_expect(hint_text.has_area() and hint_text.size.x < hint_box.size.x, "the hint's protected area is its text, not its whole box (%s in %s)" % [hint_text, hint_box])
		_expect(_labels_clear(geometry).is_empty(), "corridor, %s layout: %s" % [layout, _labels_clear(geometry) if not _labels_clear(geometry).is_empty() else "every name is clear"])
		_expect(_drawn_names(geometry) >= (18 if layout == "keyboard" else 14), "corridor, %s layout: most names still find room (%d)" % [layout, _drawn_names(geometry)])
		var camera_tick: Dictionary = _entry(geometry["zones"], "name", "camera x%.2f" % (game.get("intro_camera") as Camera2D).zoom.x)
		_expect(camera_tick.has("label_rect"), "corridor, %s layout: the camera's centre is named on the bottom edge" % layout)
	# The engineer at the bypass: the purge display's range is wholly off screen.
	game.set("touch_enabled", false)
	game.call("_refresh_ui")
	(game.get_node("Human") as Node2D).position.x = 760.0
	await create_timer(1.5).timeout
	var far: Dictionary = tools.dump()["geometry"]
	var purge: Dictionary = _entry(far["zones"], "name", "use: purge display")
	_expect(not purge.is_empty() and purge.get("on_screen") == false and int(purge.get("lane", 0)) == -1 and not purge.has("label_rect"), "a range wholly off screen is reported but not drawn, and its name takes no room (%s)" % [purge.get("screen_rect")])
	_expect(_labels_clear(far).is_empty(), "with the camera moved: %s" % [_labels_clear(far) if not _labels_clear(far).is_empty() else "every name is clear"])
	# Cutting: whatever is left of a bar, line or box overlaps no protected rectangle.
	var cuts: Array[Rect2] = [Rect2(10.0, 10.0, 20.0, 20.0), Rect2(25.0, 0.0, 10.0, 50.0)]
	var pieces: Array[Rect2] = DebugZones.clip(Rect2(0.0, 15.0, 60.0, 4.0), cuts)
	var area: float = 0.0
	var crossing: int = 0
	for piece: Rect2 in pieces:
		area += piece.get_area()
		for cut: Rect2 in cuts:
			if piece.intersects(cut):
				crossing += 1
	_expect(crossing == 0 and is_equal_approx(area, 60.0 * 4.0 - 25.0 * 4.0), "a bar cut around two controls keeps exactly the parts outside them (%s)" % [pieces])
	# The lane, door blown, touch layout: the busiest still.
	_expect(_junction_state(true).save_to_disk(str(game.get("save_path"))), "a door-blown save is written")
	game.call("_load_game")
	await _settle(3)
	game.set("touch_enabled", true)
	game.call("_refresh_ui")
	tools.call("_refresh_view")
	await _settle(2)
	var lane: Dictionary = tools.dump()["geometry"]
	_expect(_labels_clear(lane).is_empty(), "the lane, touch layout: %s" % [_labels_clear(lane) if not _labels_clear(lane).is_empty() else "every name is clear"])
	var limit: DebugZones.Item = null
	for item: DebugZones.Item in tools.zones.items(true):
		if item.name == "chase limit":
			limit = item
	var use_rect: Rect2 = (game.get("touch_use") as Control).get_global_rect()
	_expect(limit != null and tools.zones.limit_bottom(limit) >= limit.screen.end.y, "a limit's line reaches the floor")
	game.set("touch_enabled", false)
	tools.set_overlay_mode(DebugTools.Overlay.OFF)
	_expect(use_rect.has_area() and _idle(tools), "turned off, the tools are idle")
	await _free(game)


## Props drawn by their own _draw (the sentry's beam, the hatch doorway, the bypass pipe, the room
## lights and beacons) get render boxes from what was drawn, and the sentry's beam also declares its
## box for exported builds.
func _check_custom_draw_boxes() -> void:
	var game: Node2D = await _spawn(true)
	var tools: DebugTools = _tools(game)
	_expect(_junction_state(true).save_to_disk(str(game.get("save_path"))), "a door-blown save is written")
	game.call("_load_game")
	await _settle(4)
	tools.set_overlay_mode(DebugTools.Overlay.ZONES)
	await _settle(2)
	var geometry: Dictionary = tools.dump()["geometry"]
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var visual: Node2D = room.sentry.get_node("Visual") as Node2D
	var beam: Dictionary = _entry(geometry["render_boxes"], "path", str(game.get_path_to(visual)))
	var drawn: Rect2 = RenderingServer.debug_canvas_item_get_rect(visual.get_canvas_item())
	_expect(drawn.has_area() and not beam.is_empty() and beam.get("custom_draw") == true and beam.get("bounds") == "renderer" and _same_rect(beam["screen_rect"], visual.get_global_transform_with_canvas() * drawn), "the sentry's beam has a render box from what it drew (%s)" % [beam.get("screen_rect")])
	var declared: Rect2 = visual.call("debug_draw_rect")
	_expect(declared.grow(2.0).encloses(drawn) and drawn.grow(2.0).encloses(declared), "the beam's declared box matches what it drew (%s vs %s)" % [declared, drawn])
	var boxed: Dictionary = {}
	for box: Dictionary in geometry["render_boxes"]:
		boxed[str(box["path"])] = true
	var missing: Array[String] = []
	for node: Node in game.find_children("*", "Node2D", true, false):
		var item: Node2D = node as Node2D
		if not item.is_visible_in_tree() or str(game.get_path_to(item)).begins_with("DebugTools"):
			continue
		var script: Script = item.get_script() as Script
		if script == null or not script.get_script_method_list().any(func(method: Dictionary) -> bool: return method["name"] == "_draw"):
			continue
		if RenderingServer.debug_canvas_item_get_rect(item.get_canvas_item()).has_area() and not boxed.has(str(game.get_path_to(item))):
			missing.append(str(game.get_path_to(item)))
	_expect(missing.is_empty(), "every visible prop that draws by itself has a render box (missing %s)" % [missing])
	for path: String in [str(game.get_path_to(room)) + "/HatchDoorway", "BypassHandle"]:
		var node: CanvasItem = game.get_node_or_null(path) as CanvasItem
		_expect(node != null and not _entry(geometry["render_boxes"], "path", path).is_empty(), "%s has a render box" % path)
	tools.set_overlay_mode(DebugTools.Overlay.OFF)
	await _free(game)


## On a controller the zones page's categories toggle with LB, RB and View, like F5 to F7, unless the
## button is bound to a game action; the legend names the buttons for the device in use.
func _check_zones_controller_toggles() -> void:
	var game: Node2D = await _spawn(true)
	var tools: DebugTools = _tools(game)
	var zones: DebugZones = tools.zones
	game.call("_new_game")
	game.call("_finish_intro")
	await _settle(3)
	tools.set_overlay_mode(DebugTools.Overlay.ZONES)
	await _tap_pad(JOY_BUTTON_LEFT_SHOULDER)
	_expect(not zones.layers[DebugZones.ZONES] and zones.layers[DebugZones.HITBOXES] and zones.layers[DebugZones.RENDER], "LB turns the zones off")
	await _tap_pad(JOY_BUTTON_RIGHT_SHOULDER)
	await _tap_pad(JOY_BUTTON_BACK)
	_expect(not zones.layers[DebugZones.HITBOXES] and not zones.layers[DebugZones.RENDER] and not (zones.legend_buttons[DebugZones.RENDER] as Button).button_pressed, "RB and View turn the hitboxes and the render boxes off, and the legend follows")
	for button: JoyButton in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_BACK]:
		await _tap_pad(button)
	_expect(zones.layers.values().all(func(on: bool) -> bool: return on), "and on again")
	_expect(zones.legend_caption.text == DebugZones.CAPTIONS["controller"], "after a controller press the legend names LB, RB and View (%s)" % zones.legend_caption.text)
	var bound: InputEventJoypadButton = InputEventJoypadButton.new()
	bound.button_index = JOY_BUTTON_LEFT_SHOULDER
	InputMap.action_add_event(&"interact", bound)
	await _tap_pad(JOY_BUTTON_LEFT_SHOULDER)
	InputMap.action_erase_event(&"interact", bound)
	_expect(zones.layers[DebugZones.ZONES], "a button the player bound to a game action does not toggle anything")
	tools.set_overlay_mode(DebugTools.Overlay.STATE)
	await _tap_pad(JOY_BUTTON_RIGHT_SHOULDER)
	_expect(zones.layers[DebugZones.HITBOXES], "off the zones page RB does nothing")
	game.set("controller_active", false)
	game.set("touch_enabled", true)
	tools.call("_refresh_view")
	_expect(zones.legend_caption.text == DebugZones.CAPTIONS["touch"], "in the touch layout the legend says to tap")
	game.set("touch_enabled", false)
	tools.call("_refresh_view")
	_expect(zones.legend_caption.text == DebugZones.CAPTIONS["keyboard"], "on a keyboard it names F5 to F7")
	tools.set_overlay_mode(DebugTools.Overlay.OFF)
	await _free(game)


## A window that presents no frame never holds a capture with boxes up: after FRAME_WAIT_LIMIT frames
## it writes the dump without a screenshot, says the boxes are not in one, and puts the view back.
func _check_capture_bounded_wait() -> void:
	var game: Node2D = await _spawn(true)
	var tools: DebugTools = _tools(game)
	tools.capture_dir = base + "-captures"
	game.call("_new_game")
	game.call("_finish_intro")
	await _settle(3)
	tools.zones.set_layer(false, DebugZones.RENDER)
	var silent: Node = Node.new()
	silent.add_user_signal("never")
	tools.frame_drawn_signal = Signal(silent, "never")
	var start: int = get_frame()
	var paths: Dictionary = await tools.capture_with_boxes()
	var waited: int = get_frame() - start
	_expect(waited <= DebugTools.FRAME_WAIT_LIMIT + 2, "the capture gives up waiting for a drawn frame after %d frames (%d)" % [DebugTools.FRAME_WAIT_LIMIT, waited])
	_expect(paths.get("with_boxes") == false and str(paths.get("png", "x")).is_empty() and FileAccess.file_exists(str(paths.get("json", ""))), "it still writes the dump, with no stale screenshot and with_boxes false (%s)" % [paths])
	_expect(not tools.zones.visible and not tools.zones.layers[DebugZones.RENDER] and tools.zones.layers[DebugZones.ZONES] and not tools.get("_capturing_boxes"), "and puts the page and the categories back")
	tools.frame_drawn_signal = Signal()
	tools.hide_note()
	silent.free()
	await _free(game)


## The first problem with the drawn names in [param geometry], or empty: a name over a protected
## control or text, over an actor, off screen, or over another name.
func _labels_clear(geometry: Dictionary) -> String:
	var clear: Array[Rect2] = []
	for entry: Dictionary in geometry["keep_clear"]["controls_and_text"]:
		clear.append(_rect(entry["screen_rect"]))
	for actor: Array in geometry["keep_clear"]["actors"]:
		clear.append(_rect(actor))
	var view: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var labels: Array[Rect2] = []
	var names: Array[String] = []
	for list: String in ["zones", "hitboxes", "render_boxes"]:
		for item: Dictionary in geometry[list]:
			if not item.has("label_rect"):
				continue
			var rect: Rect2 = _rect(item["label_rect"])
			if not view.encloses(rect):
				return "'%s' is drawn off screen at %s" % [item["name"], rect]
			for index: int in clear.size():
				if rect.intersects(clear[index]):
					return "'%s' at %s covers a protected area %s" % [item["name"], rect, clear[index]]
			for index: int in labels.size():
				if rect.intersects(labels[index]):
					return "'%s' at %s overlaps '%s' at %s" % [item["name"], rect, names[index], labels[index]]
			labels.append(rect)
			names.append(str(item["name"]))
	return ""


func _drawn_names(geometry: Dictionary) -> int:
	var count: int = 0
	for list: String in ["zones", "hitboxes"]:
		for item: Dictionary in geometry[list]:
			if item.has("label_rect"):
				count += 1
	return count


func _rect(values: Array) -> Rect2:
	return Rect2(float(values[0]), float(values[1]), float(values[2]), float(values[3]))


## For capture drivers: a capture with boxes draws every category into its screenshot whatever page
## is up, writes the dump with the geometry, then puts the view back as it was.
func _check_capture_with_boxes() -> void:
	var game: Node2D = await _spawn(true)
	var tools: DebugTools = _tools(game)
	tools.capture_dir = base + "-captures"
	game.call("_new_game")
	game.call("_finish_intro")
	await _settle(3)
	tools.zones.set_layer(false, DebugZones.RENDER)
	var shown_during: Array[bool] = []
	tools.captured.connect(func(_paths: Dictionary) -> void: shown_during.append(tools.zones.visible and tools.zones.layers[DebugZones.RENDER] and tools.zones.layers[DebugZones.HITBOXES]))
	var paths: Dictionary = await tools.capture_with_boxes()
	_expect(paths.get("with_boxes") == true and FileAccess.file_exists(str(paths.get("json", ""))), "a capture with boxes is written")
	_expect(shown_during == [true], "every category was drawn while it was taken")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(paths["json"])))
	var geometry: Dictionary = data.get("geometry", {})
	_expect((data.get("capture") as Dictionary).get("with_boxes") == true and geometry.get("drawn") == true and not (geometry.get("hitboxes", []) as Array).is_empty() and not (geometry.get("render_boxes", []) as Array).is_empty() and not (geometry.get("zones", []) as Array).is_empty(), "its dump has the zones, hitboxes and render boxes, drawn")
	_expect(tools.overlay_mode == DebugTools.Overlay.OFF and not tools.zones.visible and not tools.zones.layers[DebugZones.RENDER] and tools.zones.layers[DebugZones.ZONES], "afterwards the page and the categories are as they were")
	await _send_key(KEY_F12)
	var plain: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(tools.last_capture["json"])))
	_expect(tools.last_capture.get("with_boxes") == false and (plain.get("geometry", {}) as Dictionary).get("drawn") == false and not ((plain.get("geometry", {}) as Dictionary).get("render_boxes", []) as Array).is_empty(), "F12 with the overlay off reports the boxes as numbers without drawing them")
	tools.hide_note()
	_expect(_idle(tools), "after both captures the tools are idle again")
	tools.debug_build = false
	_expect((await tools.capture_with_boxes()).is_empty(), "hidden tools write no capture with boxes")
	await _free(game)


## The entry in [param list] whose [param key] is [param value], or empty.
func _entry(list: Variant, key: String, value: Variant) -> Dictionary:
	for item: Variant in list:
		if item is Dictionary and (item as Dictionary).get(key) == value:
			return item
	return {}


## True when a dumped [x, y, w, h] array is [param rect].
func _same_rect(values: Variant, rect: Rect2) -> bool:
	if not values is Array or (values as Array).size() != 4:
		return false
	var array: Array = values
	return absf(float(array[0]) - rect.position.x) < 0.01 and absf(float(array[1]) - rect.position.y) < 0.01 and absf(float(array[2]) - rect.size.x) < 0.01 and absf(float(array[3]) - rect.size.y) < 0.01


## True when Main's [param rule] holds at both ends of [param range] (just inside the right end when
## [param half_open]) and not just outside them.
func _edges_match(game: Node2D, rule: StringName, range: Variant, half_open: bool) -> bool:
	var low: float = float(range[0])
	var high: float = float(range[1])
	var inside_high: float = high - 0.01 if half_open else high
	var outside_high: float = high if half_open else high + 0.5
	return bool(game.call(rule, low)) and bool(game.call(rule, inside_high)) and not bool(game.call(rule, low - 0.5)) and not bool(game.call(rule, outside_high))


func _edges_match_static(rule: Callable, range: Variant) -> bool:
	var low: float = float(range[0])
	var high: float = float(range[1])
	return rule.call(low) and rule.call(high) and not rule.call(low - 0.5) and not rule.call(high + 0.5)


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


## True when the tools neither process nor draw anything, the zone drawing and its legend included.
func _idle(tools: DebugTools) -> bool:
	return not tools.is_processing() and not tools.is_physics_processing() and not tools.layer.visible and not tools.overlay.visible and not tools.debug_button.visible and not tools.note.visible \
		and not tools.zones.visible and not tools.zones.is_processing() and not tools.zones.legend.is_visible_in_tree()


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
