extends SceneTree
## Landing the doors (2026-10-14), review r5 M1: the sentry at the far end of its patrol passing behind
## the exit bolt panel and its feed with the new exit art (p01), and its beam facing back over the
## TANK RELEASE alcove (p02), with the engineer at the rubble line and the lane taken alone.
## Usage after --:  [--size=WxH] [--touch=1]

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
var out_dir: String = "/work/out"
var game: Node2D
var canvas_layer: CanvasLayer


func _initialize() -> void:
	call_deferred("_run")


func _arg(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


func _run() -> void:
	var parts: PackedStringArray = _arg("size", "1280x720").split("x")
	var size: Vector2i = Vector2i(int(parts[0]), int(parts[1]))
	DirAccess.make_dir_recursive_absolute(out_dir)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	root.size = size
	game = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", "user://panel-cap-save.json")
	game.set("settings_path", "user://panel-cap-settings.cfg")
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	canvas_layer = game.get_node("CanvasLayer") as CanvasLayer
	if _arg("touch", "0") == "1":
		game.set("touch_enabled", true)
	await _raw(30)
	if root.size != size:
		root.size = size
		await _raw(10)
	var actions: Object = game.get("debug_tools").get("actions")
	actions.call("set_relay", &"disclose_bypass")
	actions.call("set_lane", &"alone")
	print(actions.call("jump", &"lane"))
	await _raw(60)
	for _i: int in 8:
		if game.get("waiting_for_choice") or (game.get_node("Human") as Node2D).get("controlled"):
			break
		await _tap(&"interact")
		await _raw(20)
	var brain: Object = game.get("sentry_brain")
	var human: Node2D = game.get_node("Human") as Node2D
	var choice_x: float = float((game.get("junction_room").get_script() as Script).get_script_constant_map()["CHOICE_X"])
	game.call("debug_place", choice_x - 6.0, 300.0)
	await _raw(20)
	var shot_far: bool = false
	var shot_back: bool = false
	for _i: int in 6000:
		await process_frame
		if game.get("waiting_for_choice"):
			await _tap(&"choice_2")
		var x: float = float(brain.get("x"))
		var facing: float = float(brain.get("facing"))
		if not shot_far and x >= 836.0 and facing > 0.0:
			await _shot("p01-sentry-behind-panel")
			print("p01 sentry x %.1f facing %.0f state %s" % [x, facing, brain.get("state")])
			shot_far = true
		elif shot_far and not shot_back and facing < 0.0 and x <= 720.0:
			await _shot("p02-beam-back-over-alcove")
			print("p02 sentry x %.1f facing %.0f state %s engineer %.1f" % [x, facing, brain.get("state"), human.position.x])
			shot_back = true
		if shot_far and shot_back:
			break
	_remove("user://panel-cap-save.json")
	_remove("user://panel-cap-settings.cfg")
	quit(0)


func _shot(slug: String) -> void:
	var was: float = Engine.time_scale
	Engine.time_scale = 0.0
	await _raw(2)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(slug + ".png"))
	canvas_layer.visible = false
	await _raw(1)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(slug + "-clean.png"))
	canvas_layer.visible = true
	Engine.time_scale = was


func _tap(action: StringName) -> void:
	await process_frame
	Input.action_press(action)
	await process_frame
	Input.action_release(action)
	await process_frame


func _raw(frames: int) -> void:
	for _i: int in range(frames):
		await process_frame


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
