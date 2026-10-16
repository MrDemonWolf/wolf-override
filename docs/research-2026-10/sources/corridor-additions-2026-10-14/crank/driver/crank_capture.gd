extends SceneTree
## Crank-pose capture and check driver (scratch only, never part of a repository).
## Plays route B (press at the breaker, WOLF refuses the relay) to the MANUAL BYPASS, then holds USE
## and records the engineer's sprite every frame for 1.2 s, saving stills and a frame sequence.
## Usage (after --): --out=DIR [--size=1280x720] [--pixels=1]
## With --pixels=0 (godot --headless) it saves no images, only crank.json (the per-frame record).
## Works on a project without the crank pose too (game-slice, the "before"): crank_frame reads null.

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")

var out_dir: String = ""
var pixels: bool = true
var game: Node2D
var human: Node2D
var wolf: Node2D
var canvas_layer: CanvasLayer
var notes: Array = []
var record: Array = []


func _initialize() -> void:
	call_deferred("_run")


func _arg(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


func _run() -> void:
	seed(20261012)
	out_dir = _arg("out", "/tmp/crank")
	pixels = _arg("pixels", "1") == "1"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var sz: PackedStringArray = _arg("size", "1280x720").split("x")
	var want: Vector2i = Vector2i(int(sz[0]), int(sz[1]))
	var save_path: String = "user://crank-save.json"
	var settings_path: String = "user://crank-settings.cfg"
	_remove(save_path)
	_remove(settings_path)
	game = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", save_path)
	game.set("settings_path", settings_path)
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	human = game.get_node("Human") as Node2D
	wolf = game.get_node("Wolf") as Node2D
	canvas_layer = game.get_node("CanvasLayer") as CanvasLayer
	await _raw(30)
	if pixels and get_root().size != want:
		get_root().size = want
		await _raw(10)
	notes.append("window %s" % str(get_root().size))
	await _skip_opening()
	await _breaker(&"choice_2")
	await _walk_to(605.0)
	await _raw(40)
	await _tap(&"interact")
	await _raw(20)
	await _tap(&"interact")
	await _raw(30)
	await _walk_to(700.0)
	await _raw(20)
	await _tap(&"interact")
	if not await _wait_until(func() -> bool: return float(game.get("engineer_step_x")) < 0.0, 120):
		notes.append("never reached the crank spot")
	await _raw(30)
	_note_frame("at-wheel")
	await _shot("c0-at-wheel")
	# From here every capture is one frame (the HUD canvas stays hidden), so the stills land on the
	# frames recorded for them.
	canvas_layer.visible = false
	Input.action_press(&"interact")
	var start_ticks: int = int(game.get("bypass_ticks"))
	for i: int in range(72):
		await process_frame
		_note_frame("hold-%02d" % i)
		# frame 14 (A, before the first tick at frame 24) and 30 (B, 6 frames after it) also as stills
		var names: Array[String] = ["seq-%02d" % i]
		if i == 14:
			names.append("c1-crank-a")
		if i == 30:
			names.append("c2-crank-b")
		await _grab(names)
	Input.action_release(&"interact")
	await _raw(3)
	_note_frame("released+3")
	await _grab(["c3-released"])
	canvas_layer.visible = true
	var f: FileAccess = FileAccess.open(out_dir.path_join("crank.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"notes": notes, "start_ticks": start_ticks, "record": record}, " "))
	f.close()
	_remove(save_path)
	_remove(settings_path)
	print("crank done ", notes)
	quit(0)


func _note_frame(tag: String) -> void:
	var sp: Sprite2D = human.get("body_sprite") as Sprite2D
	var rect: Rect2 = sp.get_rect()
	var bottom_world: float = (sp.global_transform * Vector2(0.0, rect.end.y)).y
	var refl: Sprite2D = human.get_parent().get_node_or_null("Human/BodySpriteReflection") as Sprite2D
	record.append({"tag": tag, "crank_frame": game.get("crank_frame"), "texture": sp.texture.resource_path, "region": sp.region_enabled,
		"region_rect": str(sp.region_rect), "scale": sp.scale.x, "pos": str(sp.position), "flip_h": sp.flip_h, "sprite_bottom_world": bottom_world,
		"human_x": human.position.x, "human_y": human.position.y, "ticks": game.get("bypass_ticks"), "wheel_deg": (game.get("bypass_handle") as Node).get("wheel").rotation_degrees,
		"reflection_texture": refl.texture.resource_path if refl != null else "", "reflection_region": str(refl.region_rect) if refl != null else ""})


## One clean frame of the current state (the HUD canvas already hidden); no frame passes in between.
func _grab(names: Array[String]) -> void:
	if not pixels:
		return
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	for slug: String in names:
		img.save_png(out_dir.path_join(slug + ".png"))
	record[record.size() - 1]["grabbed"] = names


func _shot(slug: String, clean: bool = true) -> void:
	if not pixels:
		return
	await RenderingServer.frame_post_draw
	if clean:
		root.get_texture().get_image().save_png(out_dir.path_join(slug + ".png"))
	canvas_layer.visible = false
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(slug + "-clean.png"))
	canvas_layer.visible = true


func _skip_opening() -> void:
	_press("CanvasLayer/TitleScreen/NewGameButton")
	await _raw(50)
	await _pause_action()
	await _raw(20)
	_press("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton")
	await _raw(320)


func _breaker(choice: StringName) -> void:
	await _walk_to(350.0)
	await _raw(20)
	await _tap(&"interact")
	await _raw(30)
	if not game.get("waiting_for_choice"):
		await _tap(&"interact")
		await _raw(30)
	await _tap(choice)
	await _raw(40)
	await _tap(&"interact")
	await _raw(30)


func _press(path: String) -> void:
	var b: Button = game.get_node(path) as Button
	if b.disabled or not b.is_visible_in_tree():
		notes.append("button %s not usable" % path)
		return
	b.pressed.emit()


func _pause_action() -> void:
	var ev: InputEventAction = InputEventAction.new()
	ev.action = &"pause_game"
	ev.pressed = true
	Input.parse_input_event(ev)
	await process_frame
	var up: InputEventAction = InputEventAction.new()
	up.action = &"pause_game"
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame


func _tap(action: StringName) -> void:
	await process_frame
	Input.action_press(action)
	await process_frame
	Input.action_release(action)
	await process_frame


func _walk_to(target_x: float) -> bool:
	var dir: float = signf(target_x - human.position.x)
	if absf(target_x - human.position.x) <= 3.0:
		return true
	var action: StringName = &"move_right" if dir > 0.0 else &"move_left"
	Input.action_press(action)
	var reached: bool = false
	for _i: int in range(1200):
		await process_frame
		if (target_x - human.position.x) * dir <= 2.0:
			reached = true
			break
		if not bool(human.get("controlled")) and not bool(game.get("engineer_waits_for_wolf")):
			Input.action_release(action)
			await _raw(30)
			if game.get("waiting_for_choice"):
				break
			await _tap(&"interact")
			await _raw(10)
			Input.action_press(action)
	Input.action_release(action)
	await process_frame
	if not reached:
		notes.append("walk to %.0f stopped at %.0f" % [target_x, human.position.x])
	return reached


func _wait_until(cond: Callable, max_frames: int) -> bool:
	for _i: int in range(max_frames):
		if cond.call():
			return true
		await process_frame
	return bool(cond.call())


func _raw(frames: int) -> void:
	for _i: int in range(frames):
		await process_frame


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
