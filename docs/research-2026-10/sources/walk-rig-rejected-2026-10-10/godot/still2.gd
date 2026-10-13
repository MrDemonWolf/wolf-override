extends SceneTree
## Renders rig stills (rest pose and a strip of gait poses) with joint markers, for tuning.
## args: --rig=wolf|engineer --out=DIR --parts=DIR

var vp: SubViewport


func _initialize() -> void:
	call_deferred("_run")


func _arg(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


func _run() -> void:
	var which: String = _arg("rig", "wolf")
	var out: String = _arg("out", "/tmp")
	var parts_dir: String = _arg("parts", "")
	var speeds: PackedStringArray = _arg("speeds", "0,110,200").split(",")
	DirAccess.make_dir_recursive_absolute(out)
	vp = SubViewport.new()
	vp.size = Vector2i(2400, 700)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg: ColorRect = ColorRect.new()
	bg.color = Color("#2a2f3a")
	bg.size = Vector2(vp.size)
	bg.z_index = -100
	vp.add_child(bg)
	for row: int in speeds.size():
		var v: float = float(speeds[row])
		for col: int in 4:
			var rig: RigBase = load("res://%s_rig.gd" % which).new()
			vp.add_child(rig)
			rig.call("build", parts_dir)
			# warm up then sample at distinct phases
			for k: int in 90 + col * 9:
				rig.call("step", 1.0 / 60.0, v)
			rig.position = Vector2(300 + col * 600, 660)
			rig.scale = Vector2.ONE * float(_arg("zoom", "1.0"))
			var line: Line2D = Line2D.new()
			line.points = PackedVector2Array([Vector2(-280, 0), Vector2(280, 0)])
			line.width = 1.0
			line.default_color = Color(1, 0.8, 0.2, 0.7)
			rig.add_child(line)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img: Image = vp.get_texture().get_image()
		img.save_png(out.path_join("still-%s-%s.png" % [which, speeds[row]]))
		for c: Node in vp.get_children():
			if c is RigBase:
				c.queue_free()
		await process_frame
	quit()
