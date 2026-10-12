extends SceneTree
## Option A design-render driver (scratch only, never part of the repository). Plays main's real
## opening from New Game with real interact taps, hides today's IntroCage/IntroGate, and draws the
## Option A design layers (flat PNGs rendered by tools/layers.py) at their world position and z, so
## the real camera, WOLF, Director, UI, flash, shake and timing frame them. The leaf follows main's own
## IntroGate.opening tween. Usage:
## godot --fixed-fps 60 --path <game> --script res://cage_a/driver.gd -- --layers=<dir> --out=<dir>
## Revision 2: --hold=0.15 replaces main's 0.65 s gate tween with a 0.15 s break hold (leaf still) and a
## 0.5 s slide (same 0.65 s total, same z swap, step-down and walk); the lock lamp is green when locked;
## Godot's render monitors are logged per shot; the window is kept on top (never occluded).

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")

var out_dir: String = ""
var layer_dir: String = ""
var game: Node2D
var wolf: M0Actor
var cam: Camera2D
var gate: Node2D
var cage: Node2D
var director: Sprite2D
var entries: Array = []
var tex: Dictionary = {}

var back: Sprite2D
var glow_blue: Sprite2D
var frame_spr: Sprite2D
var leaf: Sprite2D
var top: Sprite2D
var keeper: Sprite2D
var lamp_glow: Sprite2D

var state: String = "standby"
var fail_frames: int = -1
var blue_target: float = 0.0
var _frames_since_tap: int = 0
var hold: float = 0.0


func _initialize() -> void:
	call_deferred("_run")


func _arg(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


func _t(name: String) -> Texture2D:
	if not tex.has(name):
		var img: Image = Image.load_from_file(layer_dir.path_join(name + ".png"))
		img.generate_mipmaps()
		tex[name] = ImageTexture.create_from_image(img)
	return tex[name]


func _spr(name: String, pos: Vector2, z: int, additive: bool = false) -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	s.texture = _t(name)
	s.centered = false
	s.position = pos
	s.scale = Vector2(0.25, 0.25)
	s.z_index = z
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if additive:
		var m: CanvasItemMaterial = CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		s.material = m
	game.add_child(s)
	return s


func _run() -> void:
	out_dir = _arg("out", OS.get_user_data_dir().path_join("cage-a"))
	layer_dir = _arg("layers", "")
	hold = float(_arg("hold", "0"))
	DirAccess.make_dir_recursive_absolute(out_dir)
	game = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", "user://cage-a-save.json")
	game.set("settings_path", "user://cage-a-settings.cfg")
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	wolf = game.get_node("Wolf") as M0Actor
	cam = game.get_node("IntroCamera") as Camera2D
	gate = game.get_node("IntroGate") as Node2D
	cage = game.get_node("IntroCage") as Node2D
	director = game.get_node("IntroDirector") as Sprite2D
	# Option A layers, in the z order the proposal gives them.
	back = _spr("back_standby", Vector2(15, 315), 1)
	glow_blue = _spr("glow_blue", Vector2(136.5 - 34.0, 371.0 - 26.0), 1, true)
	frame_spr = _spr("frame", Vector2(15, 315), 3)
	leaf = _spr("leaf_intact", Vector2(112, 350), 4)
	top = _spr("top_locked", Vector2(15, 315), 4)
	keeper = _spr("keeper", Vector2.ZERO, 4)
	keeper.centered = true
	keeper.offset = Vector2.ZERO
	lamp_glow = _spr("glow_green", Vector2(208.0 - 7.0, 360.0 - 7.0), 4, true)
	for s: Sprite2D in [back, glow_blue, frame_spr, leaf, top, keeper, lamp_glow]:
		s.hide()
	await _raw(10)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	await _raw(60)
	(game.get_node("CanvasLayer/TitleScreen/NewGameButton") as Button).pressed.emit()
	for s: Sprite2D in [back, frame_spr, leaf, top, lamp_glow]:
		s.show()
	glow_blue.modulate.a = 0.0
	glow_blue.show()
	# The breakout's debris comes from the lock, not the whole floor (existing emitter, moved).
	var dust: CPUParticles2D = game.get("gate_dust") as CPUParticles2D
	# Proposal: the existing gate emitter, retuned to the existing sparks preset's numbers, fires at
	# the keeper as its welds tear instead of a dust cloud along 140 px of floor.
	var sp: CPUParticles2D = FxPresets.sparks(Color(1.0, 0.82, 0.55))
	dust.position = Vector2(199.0, 374.0)
	dust.emission_rect_extents = Vector2(1.5, 5.0)
	# Revision 2: aimed up and back over the leaf, away from the Director's coat (x 245.8).
	dust.direction = Vector2(-0.4, -1.0)
	dust.spread = 25.0
	for prop: String in ["initial_velocity_min", "initial_velocity_max", "gravity", "damping_min", "damping_max", "scale_amount_min", "scale_amount_max", "color", "color_ramp", "texture", "lifetime"]:
		dust.set(prop, sp.get(prop))
	dust.initial_velocity_min = 70.0
	dust.initial_velocity_max = 140.0
	dust.scale_amount_min = 0.8
	dust.scale_amount_max = 1.6
	sp.free()
	await _raw(70)
	await _shot("beat0-director-line", true)
	await _tap()
	await _raw(90)
	await _shot("beat1-standby", true)
	await _tap()
	state = "wake"
	back.texture = _t("back_wake")
	blue_target = 1.0
	await _raw(10)
	await _shot("beat2-wake-t0.17s", false)
	await _raw(80)
	await _shot("beat2-wake-settled", true)
	await _tap()
	_break_latch()
	if hold > 0.0:
		_hold_tween()
	for f: int in [2, 3, 4, 5, 6, 8, 12, 20, 30, 40, 46, 52, 56, 60, 64, 68, 72, 80, 90, 150]:
		await _raw(f - _frames_since_tap)
		await _shot("beat3-f%03d" % f, f in [2, 3, 4, 5, 60, 64, 68, 150])
	await _tap()
	await _raw(100)
	await _shot("beat4-standby-line", true)
	await _tap()
	await _raw(60)
	await _shot("beat5-lockdown-line", true)
	await _tap()
	await _raw(90)
	await _shot("beat6-only-open-route", true)
	# Close-ups at a fixed audit camera (not a game camera), UI hidden: closed and forced lock.
	(game.get_node("CanvasLayer") as CanvasLayer).visible = false
	game.call("_new_game")
	_reset_design()
	await _raw(70)
	cam.position_smoothing_enabled = false
	cam.zoom = Vector2(2.6, 2.6)
	cam.position = Vector2(140, 380)
	await _raw(4)
	await _shot("audit-closed", false)
	cam.zoom = Vector2(6, 6)
	cam.position = Vector2(196, 384)
	await _raw(3)
	await _shot("closeup-lock-locked", false)
	_break_latch()
	gate.set("opening", 1.0)
	await _raw(40)
	await _shot("closeup-lock-forced", false)
	cam.zoom = Vector2(2.6, 2.6)
	cam.position = Vector2(140, 380)
	await _raw(3)
	await _shot("audit-open", false)
	var f2: FileAccess = FileAccess.open(out_dir.path_join("_log.json"), FileAccess.WRITE)
	f2.store_string(JSON.stringify(entries, " "))
	f2.close()
	for p: String in ["user://cage-a-save.json", "user://cage-a-settings.cfg"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	print("option A renders done shots=", entries.size())
	quit(0)


func _reset_design() -> void:
	state = "standby"
	fail_frames = -1
	blue_target = 0.0
	glow_blue.modulate.a = 0.0
	back.texture = _t("back_standby")
	leaf.texture = _t("leaf_intact")
	top.texture = _t("top_locked")
	lamp_glow.texture = _t("glow_green")
	lamp_glow.position = Vector2(208.0 - 7.0, 360.0 - 7.0)
	keeper.hide()


## The latch fails: WOLF drives into the leaf's latch end, the keeper's welds tear (the fail-secure
## hook bolt stays thrown), the lamp goes to forced/amber and the umbilical's breakaway lets go.
func _break_latch() -> void:
	state = "forced"
	fail_frames = 0
	glow_blue.modulate.a = 1.0
	blue_target = 1.0
	back.texture = _t("back_swing")
	leaf.texture = _t("leaf_torn")
	top.texture = _t("top_forced")
	lamp_glow.texture = _t("glow_amber")
	lamp_glow.position = Vector2(208.0 - 8.0, 360.0 - 8.0)
	keeper.show()
	var lunge: Tween = game.create_tween()
	lunge.tween_property(wolf.body_sprite, "position", Vector2(6.0, -12.0), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	lunge.tween_property(wolf.body_sprite, "position", Vector2(0.0, -15.0), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


## Revision 2: the break hold. Main's beat-3 tween is replaced by the same 0.65 s split into a 0.15 s hold
## (the keeper tears off, the leaf does not move) and a 0.5 s cubic ease-out slide; then main's own z swap,
## 8 px step-down and walk to x 185, at the same times.
func _hold_tween() -> void:
	var old: Tween = game.get("intro_tween") as Tween
	if old != null:
		old.kill()
	gate.set("opening", 0.0)
	var t: Tween = game.create_tween()
	t.tween_interval(hold)
	t.parallel().tween_property(game.get_node("CanvasLayer/IntroAlarm"), "color:a", 0.13, 0.18)
	t.tween_property(gate, "opening", 1.0, 0.65 - hold).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_callback(func() -> void: wolf.z_index = 5)
	t.tween_property(wolf.body_sprite, "position:y", -15.0 + 8.0, 0.28)
	t.tween_callback(func() -> void: wolf.autonomous_target_x = 185.0)
	game.set("intro_tween", t)


func _sync() -> void:
	cage.hide()
	gate.hide()
	leaf.position.x = 112.0 - 82.0 * float(gate.get("opening"))
	if glow_blue.modulate.a < blue_target:
		glow_blue.modulate.a = minf(blue_target, glow_blue.modulate.a + 1.0 / 27.0)
	if fail_frames >= 0:
		fail_frames += 1
		var t: float = fail_frames / 60.0
		if fail_frames == 12:
			back.texture = _t("back_released")
		var on: bool = (fail_frames % 30) < 20
		top.texture = _t("top_forced") if on else _t("top_forced_off")
		lamp_glow.visible = on
		# The keeper's flight: out and down from the leading stile, landing by the post's foot.
		var land: float = 0.5
		if t < land:
			keeper.position = Vector2(197.0 + 30.0 * t, 374.5 - 50.0 * t + 350.0 * t * t)
			keeper.rotation = 9.0 * t
		else:
			keeper.position = Vector2(212.0, 437.0)
			keeper.rotation = PI / 2.0


func _tap() -> void:
	await process_frame
	Input.action_press(&"interact")
	await process_frame
	Input.action_release(&"interact")
	_frames_since_tap = 0


func _raw(frames: int) -> void:
	for _i: int in range(maxi(frames, 0)):
		_sync()
		await process_frame
		_frames_since_tap += 1
	_sync()


func _shot(slug: String, also_clean: bool) -> void:
	var file: String = "%02d-%s.png" % [entries.size() + 1, slug]
	_sync()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(file))
	var ct: Transform2D = root.get_canvas_transform()
	var ft: Transform2D = root.get_final_transform()
	entries.append({
		"file": file,
		"frames_since_tap": _frames_since_tap,
		"intro_step": game.get("intro_step"),
		"line": game.get("status_line"),
		"cam_pos": [cam.position.x, cam.position.y],
		"cam_zoom": cam.zoom.x,
		"canvas_xform": [ct.x.x, ct.x.y, ct.y.x, ct.y.y, ct.origin.x, ct.origin.y],
		"final_xform": [ft.x.x, ft.y.y, ft.origin.x, ft.origin.y],
		"gate_opening": gate.get("opening"),
		"leaf_x": leaf.position.x,
		"design_state": state,
		"wolf_pos": [wolf.position.x, wolf.position.y],
		"wolf_sprite_pos": [wolf.body_sprite.position.x, wolf.body_sprite.position.y],
		"wolf_flip": wolf.body_sprite.flip_h,
		"wolf_z": wolf.z_index,
		"wolf_modulate": wolf.body_sprite.modulate.to_html(),
		"director_pos": [director.position.x, director.position.y],
		"old_cage_visible": cage.visible or gate.visible,
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
