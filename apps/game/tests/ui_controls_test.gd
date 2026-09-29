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
	root.add_child(game)
	_expect(_has_button(&"interact", JOY_BUTTON_A) and _has_button(&"pause_game", JOY_BUTTON_START), "gamepad action buttons are mapped")
	_expect(_has_button(&"move_left", JOY_BUTTON_DPAD_LEFT) and _has_button(&"move_right", JOY_BUTTON_DPAD_RIGHT), "gamepad D-pad movement is mapped")
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
	game.call("_pause_game")
	var overlay: PauseOverlay = game.get_node("CanvasLayer/PauseOverlay") as PauseOverlay
	_expect(paused and overlay.visible, "pause freezes the game and opens the menu")
	(game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/SettingsButton") as Button).pressed.emit()
	_expect((game.get_node("CanvasLayer/PauseOverlay/Panel/SettingsMenu") as Control).visible, "settings open while paused")
	var fps: OptionButton = game.get_node("CanvasLayer/PauseOverlay/Panel/SettingsMenu/FPSOptions") as OptionButton
	fps.select(0)
	game.call("_on_fps_selected", 0)
	var config: ConfigFile = ConfigFile.new()
	_expect(config.load(path) == OK and Engine.max_fps == 30 and config.get_value("video", "fps_limit") == 30, "FPS cap applies and persists")
	(game.get_node("CanvasLayer/PauseOverlay/Panel/SettingsMenu/BackButton") as Button).pressed.emit()
	overlay.resume_requested.emit()
	_expect(not paused and not overlay.visible and (game.get_node("Human") as M0Actor).controlled, "resume returns to the same playable state")
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


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("UI and controls check failed: " + label)
