extends SceneTree
## Option B capture driver (scratch only, never part of the repository). Swaps the two cage nodes'
## script for the design prototype, adds the back layer, then plays main's opening from New Game with
## real interact taps and saves 1280x720 frames. Room, actors, camera, timing and UI are main's.

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const PROTO_VEC: Script = preload("res://cage_design/cell_proto.gd")
const PROTO_BAKED: Script = preload("res://cage_design/cell_baked.gd")
var PROTO: Script = PROTO_VEC

var out_dir: String = ""
var game: Node2D
var wolf: M0Actor
var cam: Camera2D
var gate: Node2D
var cage: Node2D
var back: Node2D
var director: Sprite2D
var entries: Array = []
var _frames_since_tap: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _arg(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


func _run() -> void:
	out_dir = _arg("out", OS.get_user_data_dir().path_join("cell-b"))
	var move_dust: bool = _arg("dust", "lock") == "lock"
	DirAccess.make_dir_recursive_absolute(out_dir)
	game = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", "user://cell-b-save.json")
	game.set("settings_path", "user://cell-b-settings.cfg")
	game.set("auto_pause_on_focus_loss", false)
	gate = game.get_node("IntroGate") as Node2D
	cage = game.get_node("IntroCage") as Node2D
	var design: bool = _arg("design", "1") == "1"
	if _arg("baked", "0") == "1":
		PROTO = PROTO_BAKED
	if design:
		gate.set_script(PROTO)
		gate.set("layer", "leaf")
		cage.set_script(PROTO)
		cage.set("layer", "front")
		cage.set("source", gate)
		back = Node2D.new()
		back.set_script(PROTO)
		back.set("layer", "back")
		back.set("source", gate)
		back.name = "IntroCellBack"
		back.z_as_relative = false
		back.z_index = 1
		cage.add_child(back)
		cage.z_index = 3
		gate.z_index = 4
	else:
		move_dust = false
	root.add_child(game)
	wolf = game.get_node("Wolf") as M0Actor
	cam = game.get_node("IntroCamera") as Camera2D
	director = game.get_node("IntroDirector") as Sprite2D
	if move_dust:
		# Proposed: the existing spark preset at the keeper instead of floor dust along the gate.
		var old: CPUParticles2D = game.get("gate_dust") as CPUParticles2D
		old.queue_free()
		var sparks: CPUParticles2D = FxPresets.sparks(Color("#ffd27a"))
		sparks.position = Vector2(193.0, 405.0)
		sparks.z_index = 5
		sparks.scale_amount_min = 0.3
		sparks.scale_amount_max = 0.6
		sparks.amount = 16
		sparks.initial_velocity_min = 90.0
		sparks.initial_velocity_max = 170.0
		game.add_child(sparks)
		game.set("gate_dust", sparks)
	await _raw(10)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)  # rev 2: never occluded
	DisplayServer.window_set_size(Vector2i(1280, 720))
	await _raw(60)
	(game.get_node("CanvasLayer/TitleScreen/NewGameButton") as Button).pressed.emit()
	_set_phase(0)
	await _raw(70)
	await _shot("beat0-director-line", true)
	await _tap()
	await _raw(90)
	await _shot("beat1-standby", true)
	await _tap()
	_set_phase(1)
	await _raw(10)
	await _shot("beat2-wake-t0.17s", false)
	await _raw(80)
	await _shot("beat2-wake-settled", true)
	await _tap()
	for f: int in [1, 3, 6, 8, 10, 12, 16, 22, 30, 39, 48, 56, 60, 64, 72, 90, 150]:
		await _raw(f - _frames_since_tap)
		await _shot("beat3-latch-f%03d" % f, f in [6, 8, 10, 12, 60, 64])
	await _shot("beat3-settled", true)
	await _tap()
	await _raw(100)
	await _shot("beat4-standby-line", true)
	await _tap()
	await _raw(60)
	await _shot("beat5-lockdown-line", true)
	await _tap()
	await _raw(92)
	await _shot("beat6-only-open-route", true)
	await _tap()
	await _raw(92)
	await _shot("control-starts", false)
	# Close-ups at a fixed design camera (not a game camera), UI hidden.
	(game.get_node("CanvasLayer") as CanvasLayer).visible = false
	game.call("_new_game")
	_set_phase(0)
	await _raw(70)
	cam.position_smoothing_enabled = false
	cam.zoom = Vector2(2.6, 2.6)
	cam.position = Vector2(150, 375)
	await _raw(4)
	await _shot("design-closed-z2.6", false)
	_set_phase(1)
	await _raw(3)
	await _shot("design-awake-z2.6", false)
	gate.set("opening", 0.12)
	await _raw(3)
	await _shot("design-breach-0.12-z2.6", false)
	gate.set("opening", 1.0)
	await _raw(3)
	await _shot("design-open-z2.6", false)
	var f2: FileAccess = FileAccess.open(out_dir.path_join("_log.json"), FileAccess.WRITE)
	f2.store_string(JSON.stringify(entries, " "))
	f2.close()
	for p: String in ["user://cell-b-save.json", "user://cell-b-settings.cfg"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	print("cell-b capture done shots=", entries.size())
	quit(0)


func _set_phase(v: int) -> void:
	for n: Node2D in [cage, gate, back]:
		if n != null and "phase" in n:
			n.set("phase", v)


func _tap() -> void:
	await process_frame
	Input.action_press(&"interact")
	await process_frame
	Input.action_release(&"interact")
	_frames_since_tap = 0


func _raw(frames: int) -> void:
	for _i: int in range(maxi(frames, 0)):
		await process_frame
		_frames_since_tap += 1


func _shot(slug: String, also_clean: bool) -> void:
	var file: String = "%02d-%s.png" % [entries.size() + 1, slug]
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(file))
	var ct: Transform2D = root.get_canvas_transform()
	entries.append({
		"file": file,
		"frames_since_tap": _frames_since_tap,
		"intro_step": game.get("intro_step"),
		"line": game.get("status_line"),
		"cam_zoom": cam.zoom.x,
		"canvas_xform": [ct.x.x, ct.x.y, ct.y.x, ct.y.y, ct.origin.x, ct.origin.y],
		"opening": gate.get("opening"),
		"phase": cage.get("phase"),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"cage_visible": cage.visible,
		"gate_visible": gate.visible,
		"wolf_pos": [wolf.position.x, wolf.position.y],
		"wolf_sprite_y": wolf.body_sprite.position.y,
		"wolf_z": wolf.z_index,
		"wolf_modulate": wolf.body_sprite.modulate.to_html(),
		"director_pos": [director.position.x, director.position.y],
	})
	if also_clean:
		var layer: CanvasLayer = game.get_node("CanvasLayer") as CanvasLayer
		layer.visible = false
		await process_frame
		await RenderingServer.frame_post_draw
		_frames_since_tap += 1
		root.get_texture().get_image().save_png(out_dir.path_join(file.replace(".png", "-noui.png")))
		layer.visible = true
