extends SceneTree
## Option C capture driver (scratch only, never part of the repository). Plays main's opening from New
## Game with real interact taps and saves 1280x720 frames. With --design=1 it adds the design's third
## node (the bay behind WOLF, z 1), keeps the three parts on one `opening` value, sets `wake` at beat 2,
## and plays beat 3 with the proposed timing (0.15 s lock failure, then a 0.5 s slide; same 0.65 s total).
## With --design=0 it plays main untouched (baseline frames and render monitors).
## Revision 2 flags: --stencils=0 (blank plates), --keypad=0 (blank 1.2 m backplate), --mesh=0 (flat-tone
## leaves), --win=WxH (window size, e.g. 534x300 for the phone-size render), --mode=motion (UI hidden; every
## frame of beat 2's real camera zoom and of beat 3's first 0.15 s, for the mesh shimmer check).
## Usage: godot --fixed-fps 60 --path <game> --script res://cage_design/design_opening.gd -- --out=<dir> --design=1

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")

var out_dir: String = ""
var design: bool = true
var game: Node2D
var wolf: M0Actor
var cam: Camera2D
var gate: Node2D
var cage: Node2D
var bay: Node2D
var director: Sprite2D
var entries: Array = []
var _frames_since_tap: int = 0
var win: Vector2i = Vector2i(1280, 720)
var mode: String = "opening"


class Sync extends Node:
	var gate: Node2D
	var cage: Node2D
	var bay: Node2D
	func _process(_delta: float) -> void:
		bay.visible = cage.visible
		var o: float = gate.get("opening")
		if not is_equal_approx(float(cage.get("opening")), o):
			cage.set("opening", o)
		if not is_equal_approx(float(bay.get("opening")), o):
			bay.set("opening", o)


func _initialize() -> void:
	call_deferred("_run")


func _arg(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


func _run() -> void:
	out_dir = _arg("out", OS.get_user_data_dir().path_join("cage-design"))
	design = _arg("design", "1") == "1"
	mode = _arg("mode", "opening")
	var ws: PackedStringArray = _arg("win", "1280x720").split("x")
	win = Vector2i(int(ws[0]), int(ws[1]))
	DirAccess.make_dir_recursive_absolute(out_dir)
	game = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", "user://cage-design-save.json")
	game.set("settings_path", "user://cage-design-settings.cfg")
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	wolf = game.get_node("Wolf") as M0Actor
	cam = game.get_node("IntroCamera") as Camera2D
	gate = game.get_node("IntroGate") as Node2D
	cage = game.get_node("IntroCage") as Node2D
	director = game.get_node("IntroDirector") as Sprite2D
	if design:
		bay = Node2D.new()
		bay.name = "IntroBay"
		bay.set_script(load("res://scripts/containment_cage.gd"))
		bay.set("back", true)
		bay.z_index = 1
		bay.position = Vector2(115, 365)
		bay.visible = false
		game.add_child(bay)
		var st: bool = _arg("stencils", "1") == "1"
		var kp: bool = _arg("keypad", "1") == "1"
		var me: bool = _arg("mesh", "1") == "1"
		cage.set("stencils", st)
		cage.set("keypad", kp)
		gate.set("mesh", me)
		var sync: Sync = Sync.new()
		sync.gate = gate
		sync.cage = cage
		sync.bay = bay
		game.add_child(sync)
	await _raw(10)
	# Kept on top so macOS never marks the window occluded (Godot stops drawing an occluded window).
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_size(win)
	await _raw(60)
	(game.get_node("CanvasLayer/TitleScreen/NewGameButton") as Button).pressed.emit()
	if mode == "motion":
		await _motion()
		return
	await _raw(70)
	await _shot("beat0-director-line", true)
	await _advance()
	await _raw(90)
	await _shot("beat1-standby", true)
	await _advance()
	await _raw(10)
	await _shot("beat2-wake-t0.17s", false)
	await _raw(80)
	await _shot("beat2-wake-settled", true)
	await _advance()
	for f: int in [2, 5, 9, 12, 16, 22, 30, 39, 48, 60, 72, 90, 150]:
		await _raw(f - _frames_since_tap)
		await _shot("beat3-latch-f%03d" % f, f == 9 or f == 12 or f == 16 or f == 48)
	await _shot("beat3-settled", true)
	await _advance()
	await _raw(20)
	await _shot("beat4-director-backs-f20", false)
	await _raw(80)
	await _shot("beat4-standby-line", true)
	await _advance()
	await _raw(60)
	await _shot("beat5-lockdown-line", true)
	await _advance()
	await _raw(12)
	await _shot("beat6-turns-f12", false)
	await _raw(80)
	await _shot("beat6-only-open-route", true)
	await _advance()
	await _raw(12)
	await _shot("beat7-fade-f12", false)
	await _raw(80)
	await _shot("control-starts", false)

	# Close-ups at a fixed design-review camera (not a game camera), UI hidden.
	(game.get_node("CanvasLayer") as CanvasLayer).visible = false
	game.call("_new_game")
	if design:
		bay.set("wake", 0.0)
	await _raw(70)
	cam.position_smoothing_enabled = false
	cam.zoom = Vector2(2.6, 2.6)
	cam.position = Vector2(150, 375)
	await _raw(4)
	await _shot("review-closed", false)
	cam.zoom = Vector2(6, 6)
	for spot: Array in [["lock", Vector2(190, 395)], ["cradle", Vector2(125, 405)], ["base-left", Vector2(45, 432)], ["camera", Vector2(195, 335)]]:
		cam.position = spot[1]
		await _raw(3)
		await _shot("closeup-closed-%s" % spot[0], false)
	(game.get_node("CanvasLayer") as CanvasLayer).visible = true
	cam.zoom = Vector2(1.8, 1.8)
	cam.position = Vector2(267, 355)
	await _advance()
	await _advance()
	await _raw(30)
	await _advance()
	await _raw(150)
	(game.get_node("CanvasLayer") as CanvasLayer).visible = false
	cam.zoom = Vector2(2.6, 2.6)
	cam.position = Vector2(150, 375)
	await _raw(3)
	await _shot("review-open", false)
	cam.zoom = Vector2(6, 6)
	for spot: Array in [["lock", Vector2(190, 395)], ["stack", Vector2(70, 390)]]:
		cam.position = spot[1]
		await _raw(3)
		await _shot("closeup-open-%s" % spot[0], false)
	var f2: FileAccess = FileAccess.open(out_dir.path_join("_log.json"), FileAccess.WRITE)
	f2.store_string(JSON.stringify(entries, " "))
	f2.close()
	for p: String in ["user://cage-design-save.json", "user://cage-design-settings.cfg"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	print("option-c capture done design=", design, " shots=", entries.size())
	quit(0)


## Mesh shimmer check: UI hidden, every frame of the real beat-2 zoom (1.8 to 1.95 over 0.45 s) and of
## beat 3's shake during the 0.15 s break hold, when the closed mesh moves on screen.
func _motion() -> void:
	(game.get_node("CanvasLayer") as CanvasLayer).visible = false
	await _raw(70)
	await _advance()
	await _raw(90)
	await _shot("m-beat1-static", false)
	await _advance()
	for f: int in range(1, 34):
		await _raw(1)
		await _shot("m-beat2-zoom-f%02d" % f, false)
	await _raw(40)
	await _advance()
	for f: int in range(1, 10):
		await _raw(1)
		await _shot("m-beat3-shake-f%02d" % f, false)
	var f2: FileAccess = FileAccess.open(out_dir.path_join("_log.json"), FileAccess.WRITE)
	f2.store_string(JSON.stringify(entries, " "))
	f2.close()
	for p: String in ["user://cage-design-save.json", "user://cage-design-settings.cfg"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	print("option-c motion capture done design=", design, " shots=", entries.size())
	quit(0)


## One real interact tap, then the design's hooks for the beat it started.
func _advance() -> void:
	if design and int(game.get("intro_step")) == 2:
		# Proposed: the floor dust burst becomes the existing amber spark preset at the lock (one emitter
		# swapped for another; nothing added).
		var sparks: CPUParticles2D = FxPresets.sparks(FxPresets.SPARK_AMBER)
		# Revision 2: a narrow, slow spray from the lock that falls down and back along the post and the
		# leading leaf, away from the Director (his coat starts at x 245.8).
		sparks.position = Vector2(199, 399)
		sparks.z_index = 4
		sparks.direction = Vector2(-0.45, -1.0)
		sparks.spread = 22.0
		sparks.initial_velocity_min = 70.0
		sparks.initial_velocity_max = 140.0
		sparks.scale_amount_min = 0.4
		sparks.scale_amount_max = 0.9
		game.add_child(sparks)
		game.set("gate_dust", sparks)
	await _tap()
	if not design:
		return
	var step: int = int(game.get("intro_step"))
	if step == 2:
		var t: Tween = game.create_tween()
		t.tween_property(bay, "wake", 1.0, 0.45)
	elif step == 3:
		var old: Tween = game.get("intro_tween") as Tween
		if old != null:
			old.kill()
		gate.set("opening", 0.0)
		var t: Tween = game.create_tween()
		t.tween_property(gate, "opening", 0.04, 0.15)
		t.parallel().tween_property(game.get_node("CanvasLayer/IntroAlarm"), "color:a", 0.13, 0.18)
		t.tween_property(gate, "opening", 1.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_callback(func() -> void: wolf.z_index = 5)
		t.tween_property(wolf.body_sprite, "position:y", -15.0 + 8.0, 0.28)
		t.tween_callback(func() -> void: wolf.autonomous_target_x = 185.0)
		game.set("intro_tween", t)


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
		"window": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"canvas_xform": [ct.x.x, ct.x.y, ct.y.x, ct.y.y, ct.origin.x, ct.origin.y],
		"gate_opening": gate.get("opening"),
		"wake": bay.get("wake") if design else -1.0,
		"wolf_pos": [wolf.position.x, wolf.position.y],
		"wolf_sprite_y": wolf.body_sprite.position.y,
		"wolf_z": wolf.z_index,
		"wolf_modulate": wolf.body_sprite.modulate.to_html(),
		"director_pos": [director.position.x, director.position.y],
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
	})
	if also_clean:
		var layer: CanvasLayer = game.get_node("CanvasLayer") as CanvasLayer
		layer.visible = false
		await process_frame
		await RenderingServer.frame_post_draw
		_frames_since_tap += 1
		root.get_texture().get_image().save_png(out_dir.path_join(file.replace(".png", "-noui.png")))
		layer.visible = true
