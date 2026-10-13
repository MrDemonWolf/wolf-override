extends SceneTree
## Renders the Track B1 deliverables from the live rigs.
##   --mode=loops   transparent loop frames (+ per-frame rig data) for each rig/state at 1x and 2x
##   --mode=context the corridor preview at 1920x1080 (zoom 1.35 at 1080p = 2.7 screen px/world px)
## args: --out=DIR --eng=PARTS_DIR --wolf=PARTS_DIR [--plates=DIR]

const FPS: float = 30.0
const ENG_H: float = 190.0   # target engineer height at game size (1080p)
const WOLF_L: float = 310.0  # target WOLF length at game size

var out: String
var eng_dir: String
var wolf_dir: String


func _initialize() -> void:
	call_deferred("_run")


func _arg(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


func _run() -> void:
	out = _arg("out", "/tmp/b1")
	eng_dir = _arg("eng", "")
	wolf_dir = _arg("wolf", "")
	DirAccess.make_dir_recursive_absolute(out)
	var mode: String = _arg("mode", "loops")
	if mode == "loops":
		await _loops()
	else:
		await _context()
	quit()


func _new_rig(which: String) -> RigBase:
	var rig: RigBase = load("res://%s_rig.gd" % which).new()
	rig.call("build", eng_dir if which == "engineer" else wolf_dir)
	return rig


## Measures the idle rig's opaque bounds (rig units) to fix the game-size scale.
func _measure(which: String) -> Rect2:
	var vp: SubViewport = _vp(Vector2i(900, 700))
	var rig: RigBase = _new_rig(which)
	vp.add_child(rig)
	rig.position = Vector2(450, 650)
	rig.call("step", 1.0 / FPS, 0.0)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	var r: Rect2i = img.get_used_rect()
	vp.queue_free()
	return Rect2(Vector2(r.position) - Vector2(450, 650), Vector2(r.size))


func _vp(size: Vector2i) -> SubViewport:
	var vp: SubViewport = SubViewport.new()
	vp.size = size
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	return vp


func _loops() -> void:
	var eng_box: Rect2 = await _measure("engineer")
	var wolf_box: Rect2 = await _measure("wolf")
	var scales: Dictionary = {"engineer": ENG_H / eng_box.size.y, "wolf": WOLF_L / wolf_box.size.x}
	var info: Dictionary = {"engineer_idle_box_rig": [eng_box.position.x, eng_box.position.y, eng_box.size.x, eng_box.size.y],
		"wolf_idle_box_rig": [wolf_box.position.x, wolf_box.position.y, wolf_box.size.x, wolf_box.size.y], "scale_1x": scales}
	var jobs: Array = [
		["engineer", "idle", 0.0], ["engineer", "walk", 100.0], ["engineer", "jog", 190.0],
		["wolf", "idle", 0.0], ["wolf", "walk", 110.0], ["wolf", "trot", 200.0]]
	for job: Array in jobs:
		for zoom: int in [1, 2]:
			info["%s_%s_%dx" % [job[0], job[1], zoom]] = await _loop(job[0], job[1], job[2], scales[job[0]] * zoom, zoom)
	var f: FileAccess = FileAccess.open(out.path_join("loops.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(info, "  "))


func _loop(which: String, state: String, v: float, s: float, zoom: int) -> Dictionary:
	var size: Vector2i = Vector2i(260, 230) * zoom if which == "engineer" else Vector2i(400, 230) * zoom
	if which == "engineer" and state == "jog":
		size = Vector2i(300, 230) * zoom
	var vp: SubViewport = _vp(size)
	var rig: RigBase = _new_rig(which)
	vp.add_child(rig)
	var anchor: Vector2 = Vector2(size.x * (0.5 if which == "engineer" else 0.56), size.y - 12 * zoom)
	rig.position = anchor
	rig.scale = Vector2.ONE * s
	# one exact cycle: idle loops every 6.4 s; gaits every stride / speed
	var period: float = 6.4
	if v > 0.0:
		rig.call("step", 0.0, v)
		var L: float = rig.call("_g", "L")
		period = L / (v * RigBase.D4)
	var n: int = maxi(8, roundi(period * FPS))
	var dt: float = period / n
	# warm up 4 s at speed, then align to phase 0 for a clean start frame
	var warm: int = roundi(4.0 / dt)
	for k: int in warm:
		rig.call("step", dt, v)
	var dir: String = out.path_join("loops/%s-%s-%dx" % [which, state, zoom])
	DirAccess.make_dir_recursive_absolute(dir)
	var frames: Array = []
	for k: int in n + 1:   # the extra frame is the loop-seam check (should equal frame 0)
		if k > 0:
			rig.call("step", dt, v)
		await RenderingServer.frame_post_draw
		var img: Image = vp.get_texture().get_image()
		img.save_png(dir.path_join("f%03d.png" % k))
		frames.append(_rig_data(rig, which, anchor, s))
	vp.queue_free()
	return {"frames": n, "period_s": period, "dt": dt, "speed_world": v, "scale": s, "anchor": [anchor.x, anchor.y],
		"screen_px_per_frame": v * dt * s * RigBase.D4, "data": frames}


## Per-frame rig facts in screen px of this render: hip/body anchor and boot/paw contact points
## (from the sprites' actual transforms), with world offsets so sliding can be measured.
func _rig_data(rig: RigBase, which: String, anchor: Vector2, s: float) -> Dictionary:
	var d: Dictionary = {"world_x_screen": rig.world_x * RigBase.D4 * s}
	if which == "engineer":
		var pel: Node2D = rig.get("pelvis")
		d["hip"] = [pel.position.x * s, pel.position.y * s]
		var feet: Array = []
		for side: String in ["near_shin", "far_shin"]:
			var spr: Sprite2D = rig.sprites[side]
			var xf: Transform2D = rig.get_global_transform().affine_inverse() * spr.get_global_transform()
			var heel: Vector2 = xf * (rig.pt(side, "heel") - rig.pt(side, "pivot"))
			var toe: Vector2 = xf * (rig.pt(side, "toe") - rig.pt(side, "pivot"))
			feet.append({"heel": [heel.x * s, heel.y * s], "toe": [toe.x * s, toe.y * s]})
		d["feet"] = feet
	else:
		var body: Node2D = rig.get("body")
		d["hip"] = [body.position.x * s, body.position.y * s]
		var feet: Array = []
		for side: String in ["near_hind_foot", "near_fore_paw", "far_hind_foot", "far_fore_paw"]:
			var spr: Sprite2D = rig.sprites[side]
			var src: String = side.substr(side.find("_") + 1)
			var xf: Transform2D = rig.get_global_transform().affine_inverse() * spr.get_global_transform()
			var heel: Vector2 = xf * (rig.pt(src, "heel") - rig.pt(src, "pivot"))
			var toe: Vector2 = xf * (rig.pt(src, "toe") - rig.pt(src, "pivot"))
			feet.append({"heel": [heel.x * s, heel.y * s], "toe": [toe.x * s, toe.y * s]})
		d["feet"] = feet
	return d


# ---------------------------------------------------------------- in-context corridor preview

func _context() -> void:
	var plates: String = _arg("plates", "")
	var size: Vector2i = Vector2i(1920, 1080)
	var vp: SubViewport = _vp(size)
	vp.transparent_bg = false
	var world: Node2D = Node2D.new()
	vp.add_child(world)
	var cam: Camera2D = Camera2D.new()
	cam.zoom = Vector2.ONE * 2.7
	world.add_child(cam)
	cam.make_current()
	var far_tex: Texture2D = RigBase.load_texture(plates.path_join("corridor-far.png"))
	var mid_tex: Texture2D = RigBase.load_texture(plates.path_join("corridor-mid.png"))
	var plate_scale: float = 0.5           # 1920 px plate drawn 960 world px wide, as RoomDepth does
	var mid_top: float = 440.0 - 777.0 * plate_scale
	var far_layer: Node2D = Node2D.new()
	far_layer.z_index = -10
	world.add_child(far_layer)
	var mid_layer: Node2D = Node2D.new()
	mid_layer.z_index = -5
	world.add_child(mid_layer)
	# preview only: the room repeated mirrored on both sides so the 6 s route has floor
	for i: int in range(-1, 3):
		for pair: Array in [[far_layer, far_tex], [mid_layer, mid_tex]]:
			var sp: Sprite2D = Sprite2D.new()
			sp.texture = pair[1]
			sp.centered = false
			sp.flip_h = i % 2 != 0
			sp.scale = Vector2.ONE * plate_scale
			sp.position = Vector2(i * 960.0, mid_top)
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			(pair[0] as Node2D).add_child(sp)
	var eng: RigBase = _new_rig("engineer")
	var wolf: RigBase = _new_rig("wolf")
	world.add_child(wolf)
	world.add_child(eng)
	eng.z_index = 2
	wolf.z_index = 1
	eng.scale = Vector2.ONE / RigBase.D4
	wolf.scale = Vector2.ONE / RigBase.D4
	var ex: float = -40.0
	var wx: float = ex - 120.0
	var ev: float = 100.0
	var wv: float = 100.0
	eng.world_x = ex
	wolf.world_x = wx
	eng.call("reset_stance")
	wolf.call("reset_stance")
	var n: int = roundi(6.0 * FPS)
	var pre: int = roundi(1.0 * FPS)
	var dt: float = 1.0 / FPS
	DirAccess.make_dir_recursive_absolute(out.path_join("context"))
	var log: Array = []
	# a short settle so the idle pose is valid, then go
	for kk: int in n + pre:
		var k: int = kk - pre
		var tt: float = k * dt
		var target_v: float = 100.0 if tt < 2.3 else 190.0
		ev = move_toward(ev, target_v, 260.0 * dt)
		ex += ev * dt
		# WOLF: the game's follow rule (gap 64, cap 220) with eased speed changes for the gait
		var gap_target: float = ex - 64.0
		var want: float = clampf((gap_target - wx) * 4.0, -220.0, 220.0)
		wv = move_toward(wv, want, 900.0 * dt)
		wx += wv * dt
		eng.call("step", dt, ev)
		wolf.call("step", dt, wv)
		eng.position = Vector2(ex, 440.0)
		wolf.position = Vector2(wx, 440.0)
		var cx: float = ex + 60.0
		if kk == 0:
			cam.position = Vector2(cx, 300.0)
		else:
			cam.position.x = lerpf(cam.position.x, cx, 1.0 - exp(-dt * 4.0))
		cam.position.y = 300.0
		far_layer.position.x = cam.position.x * 0.1   # far plate lags (scroll 0.9)
		if k < 0:
			continue
		await RenderingServer.frame_post_draw
		var img: Image = vp.get_texture().get_image()
		img.save_png(out.path_join("context/f%03d.png" % k))
		log.append({"t": tt, "eng_x": ex, "eng_v": ev, "wolf_x": wx, "wolf_v": wv, "cam_x": cam.position.x})
	var f: FileAccess = FileAccess.open(out.path_join("context.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(log, "  "))
