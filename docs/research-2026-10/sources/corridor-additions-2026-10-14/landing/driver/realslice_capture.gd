extends SceneTree
## Landing copy (2026-10-14, land-corridor): round 8's driver (add7/fix1/driver) run on main and on the
## port, all routes in one Godot run (--routes=OAB, each route on a fresh game instance, frames under
## OUT/<route>/), with perf passes (--perf=1 adds A-perf and B-perf); the crank strip waits for the
## pose it names where the copy has a crank pose (main's bypass ticks every 0.25 s); the safe point
## waits for WOLF to stop before its shot; a headless run (no image) only walks the routes.
## Round 7 integration copy of fix3/driver/realslice_capture.gd (add7/integrate/driver): adds s4b (the
## roller three quarters up, the inner blast leaf moving) to route A and, outside perf runs, a crank
## strip (s3-crank-B just after a tick, s3-crank-A in the regrip) to route B; records the blast leaf
## and crank frame where the copy has them. Runs unchanged on main and round 6, which lack them.
## Real-slice capture driver (fix round 2: run through tools/render/render.sh, writes to /work/out) (scratch only, never part of a repository). Runs the same scripted
## route in game-main and game-slice and saves the door-end frames, the opening frames and the
## Godot monitors. Usage (after --):
##   --route=A|B|O  --out=DIR  [--size=1280x720]  [--perf=1]
## A: disclose at the relay, WOLF takes the contact, the seal opens, walk through, safe point.
## B: press at the relay (WOLF refuses), the engineer cranks the MANUAL BYPASS.
## O: the opening only, on fixed frame counts (for the pixel comparison with main).
## Every random source the frames depend on is seeded (global seed, each RoomDepth's rng), so
## main and slice give the same moments.

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const PERF_FRAMES: int = 300

var route: String = "A"
var out_dir: String = ""
var out_root: String = ""
var perf: bool = false
var game: Node2D
var human: Node2D
var wolf: Node2D
var notes: Array = []
var shots: Array = []
var perf_rows: Array = []
var canvas_layer: CanvasLayer


func _initialize() -> void:
	call_deferred("_run")


func _arg(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


func _run() -> void:
	out_root = _arg("out", "/work/out")
	var want_perf: bool = _arg("perf", "0") == "1"
	var sz: PackedStringArray = _arg("size", "1280x720").split("x")
	var want: Vector2i = Vector2i(int(sz[0]), int(sz[1]))
	# render.sh: Xvfb virtual screen in the container; no window on the Mac.
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	root.size = want
	DisplayServer.window_set_position(Vector2i(0, 0))
	var passes: Array = []
	for r: String in _arg("routes", "OAB").split(""):
		passes.append([r, false])
	if want_perf:
		passes.append(["A", true])
		passes.append(["B", true])
	for p: Array in passes:
		await _one_route(str(p[0]), bool(p[1]), want)
	print("all routes done")
	quit(0)


func _one_route(which: String, with_perf: bool, want: Vector2i) -> void:
	seed(20261011)
	route = which
	perf = with_perf
	notes = []
	shots = []
	perf_rows = []
	out_dir = out_root.path_join(route + ("-perf" if perf else ""))
	DirAccess.make_dir_recursive_absolute(out_dir)
	var save_path: String = "user://realslice-%s-save.json" % route
	var settings_path: String = "user://realslice-%s-settings.cfg" % route
	_remove(save_path)
	_remove(settings_path)
	game = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", save_path)
	game.set("settings_path", settings_path)
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	if _arg("touch", "0") == "1":
		# The phone shape's touch layout, as on iOS and Android.
		game.set("touch_enabled", true)
	human = game.get_node("Human") as Node2D
	wolf = game.get_node("Wolf") as Node2D
	canvas_layer = game.get_node("CanvasLayer") as CanvasLayer
	_reseed()
	await _raw(30)
	if root.size != want:
		root.size = want
		await _raw(10)
	notes.append("window %s requested %s" % [str(DisplayServer.window_get_size()), str(want)])
	match route:
		"O":
			await _route_opening()
		"A":
			await _route_a()
		"B":
			await _route_b()
	var f: FileAccess = FileAccess.open(out_dir.path_join("_run.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"route": route, "window": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y], "notes": notes, "shots": shots, "perf": perf_rows}, " "))
	f.close()
	_remove(save_path)
	_remove(settings_path)
	print("route done ", route, " perf=", perf, " notes=", notes)
	for action: StringName in [&"interact", &"move_left", &"move_right"]:
		Input.action_release(action)
	game.queue_free()
	await _raw(5)


## Every RoomDepth keeps its own randomised rng for the lamp flicker; give each the same seed.
func _reseed() -> void:
	var n: int = 0
	for node: Node in game.find_children("*", "Node2D", true, false):
		if node is RoomDepth:
			var rng: RandomNumberGenerator = node.get("_rng") as RandomNumberGenerator
			if rng != null:
				rng.seed = 1000 + n
				rng.state = 0
				n += 1


# ------------------------------------------------------------------ routes

func _route_opening() -> void:
	_press("CanvasLayer/TitleScreen/NewGameButton")
	await _raw(50)
	await _shot("o0-room-opening", false)
	var beats: Array = [[80, "o1-standby"], [80, "o2-wolf-wakes"], [40, "o3-latch-breaks"], [40, "o4-gate-folding"], [40, "o5-wolf-steps-out"], [80, "o6-director-line"], [80, "o7-director-order"], [80, "o8-heads-out"]]
	for beat: Array in beats:
		await _tap(&"interact")
		await _raw(int(beat[0]))
		await _shot(str(beat[1]), false)


func _skip_opening() -> void:
	_press("CanvasLayer/TitleScreen/NewGameButton")
	await _raw(50)
	await _pause_action()
	await _raw(20)
	_press("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton")
	await _raw(60)
	# Let the name card and location card clear.
	await _raw(260)


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


## A: disclose; WOLF takes the relay; the seal opens; walk through; the safe point.
func _route_a() -> void:
	await _skip_opening()
	await _breaker(&"choice_1")
	await _walk_to(640.0)
	await _raw(90)
	await _shot("s1-door-end-rest", true)
	await _walk_to(605.0)
	await _raw(40)
	await _tap(&"interact")
	if not await _wait_until(func() -> bool: return bool(game.get("wolf_holding_relay")) or bool(game.get("seal_opening")), 400):
		notes.append("A: WOLF never took the contact")
	await _raw(4)
	await _shot("s2-relay-wolf", true)
	var leaf: Node = game.get("seal_leaf")
	if not await _wait_until(func() -> bool: return float(leaf.get("open")) >= 0.5, 200):
		notes.append("A: leaf never reached half")
	await _shot("s4-door-opening", true)
	if not await _wait_until(func() -> bool: return float(leaf.get("open")) >= 0.75, 200):
		notes.append("A: leaf never reached three quarters")
	await _shot("s4b-leaf-moving", true)
	if not await _wait_until(func() -> bool: return not bool(game.get("seal_opening")), 300):
		notes.append("A: seal never landed")
	await _raw(60)
	await _wait_until(func() -> bool: return bool(game.get("human").get("controlled")), 300)
	await _raw(20)
	await _shot("s5-door-open", true)
	await _walk_to(780.0)
	await _raw(2)
	await _shot("s6-walk-through", true)
	await _walk_to(876.0)
	await _raw(20)
	await _tap(&"interact")
	await _raw(60)
	# WOLF walks to where he waits at the safe point (main: the relay's left; the port: the doorway).
	var still: int = 0
	for _i: int in range(300):
		await process_frame
		still = still + 1 if absf((wolf as CharacterBody2D).velocity.x) <= 1.0 else 0
		if still >= 20:
			break
	notes.append("s7: WOLF at %.1f, still %d frames" % [wolf.position.x, still])
	await _shot("s7-safe-point", true)


## B: press; WOLF refuses; the engineer cranks the bypass (shot part way through the crank).
func _route_b() -> void:
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
	await _raw(20)
	Input.action_press(&"interact")
	if not await _wait_until(func() -> bool: return int(game.get("bypass_ticks")) >= 4, 400):
		notes.append("B: bypass never reached 4 ticks (ticks %s)" % str(game.get("bypass_ticks")))
	await _raw(3)
	await _shot("s3-bypass-crank", true)
	if not perf:
		# The crank strip: B (the push) a few frames after the next tick, A (the regrip) later in it.
		var t0: int = int(game.get("bypass_ticks"))
		if not await _wait_until(func() -> bool: return int(game.get("bypass_ticks")) > t0, 60):
			notes.append("B: no tick for the crank strip")
		if game.get("crank_frame") != null:
			# The pose shown: B (the push) just after the tick, A (the regrip) before the next one.
			if not await _wait_until(func() -> bool: return int(game.get("crank_frame")) == 1, 30):
				notes.append("B: no push frame")
			await _shot("s3-crank-B", true)
			var t1: int = int(game.get("bypass_ticks"))
			if not await _wait_until(func() -> bool: return int(game.get("crank_frame")) == 0 and int(game.get("bypass_ticks")) == t1, 30):
				notes.append("B: no regrip frame")
			await _shot("s3-crank-A", true)
		else:
			await _raw(4)
			await _shot("s3-crank-B", true)
			await _raw(6)
			await _shot("s3-crank-A", true)
	Input.action_release(&"interact")
	await _raw(10)


# ------------------------------------------------------------------ capture and perf

## (Round 8 copy: the s3 perf hold keeps cranking, see _perf.)
## Saves the frame with the UI, and a clean copy with the HUD canvas hidden; then (with --perf=1)
## holds the state and samples the monitors over PERF_FRAMES uncapped frames.
func _shot(slug: String, clean: bool) -> void:
	print("shot ", route, " ", slug)
	if DisplayServer.get_name() == "headless":
		shots.append({"slug": slug, "engineer_x": human.position.x, "wolf_x": wolf.position.x, "status_line": str(game.get("status_line")), "crank_frame": game.get("crank_frame")})
		if perf:
			await _perf(slug)
		return
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	if img != null:
		img.save_png(out_dir.path_join(slug + ".png"))
	var entry: Dictionary = {"slug": slug, "engineer_x": human.position.x, "wolf_x": wolf.position.x, "camera": str((game.get_node("IntroCamera") as Camera2D).get_screen_center_position()), "zoom": (game.get_node("IntroCamera") as Camera2D).zoom.x}
	var s: Object = game.get("state")
	entry["door_open"] = s.get("door_open")
	entry["checkpoint"] = s.get("checkpoint_reached")
	entry["bypass_ticks"] = game.get("bypass_ticks")
	entry["leaf_open"] = (game.get("seal_leaf") as Node).get("open")
	var blast: Variant = game.get("blast_leaf")
	if blast != null:
		entry["blast_leaf_open"] = (blast as Node).get("open")
		entry["blast_leaf_visible"] = (blast as CanvasItem).is_visible_in_tree()
	if game.get("crank_frame") != null:
		entry["crank_frame"] = game.get("crank_frame")
	entry["status_line"] = str(game.get("status_line"))
	entry["wolf_flip_h"] = (wolf.get_node("BodySprite") as Sprite2D).flip_h
	if clean:
		canvas_layer.visible = false
		await _raw(1)
		await RenderingServer.frame_post_draw
		var clean_img: Image = root.get_texture().get_image()
		if clean_img != null:
			clean_img.save_png(out_dir.path_join(slug + "-clean.png"))
		canvas_layer.visible = true
	shots.append(entry)
	if perf:
		await _perf(slug)


func _perf(slug: String) -> void:
	# Hold transient states: pause the door's tween and every tree tween so the frame stays put.
	var paused_tween: Tween = game.get("door_tween") as Tween
	if paused_tween != null and paused_tween.is_valid():
		paused_tween.pause()
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	await _raw(30)
	var times: Array[float] = []
	var draws: Array[int] = []
	var vp: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var cpu: Array[float] = []
	var last: int = Time.get_ticks_usec()
	# Cranking (s3): keep it cranking for the whole hold. USE stays held, so the ticks go on, the pose
	# alternates and the jet emits; the count is held under the last tick so the seal never opens
	# during the measurement (round 8 fix: round 7's row mostly measured the seal opening).
	var hold_crank: bool = slug.begins_with("s3") and game.get("hold_use") != null
	for _i: int in range(PERF_FRAMES):
		if hold_crank:
			var hu: Object = game.get("hold_use")
			if int(hu.get("ticks")) >= 6:
				hu.set("ticks", 4)
				game.set("bypass_ticks", 4)
		await process_frame
		var now: int = Time.get_ticks_usec()
		times.append(float(now - last) / 1000.0)
		last = now
		draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(vp))
	var sorted: Array[float] = times.duplicate()
	sorted.sort()
	var dsorted: Array[int] = draws.duplicate()
	dsorted.sort()
	var csorted: Array[float] = cpu.duplicate()
	csorted.sort()
	var layers: Dictionary = _layers()
	perf_rows.append({
		"slug": slug,
		"frames": PERF_FRAMES,
		"frame_ms_p50": sorted[int(PERF_FRAMES * 0.5)],
		"frame_ms_p99": sorted[int(PERF_FRAMES * 0.99)],
		"frame_ms_mean": _mean(times),
		"render_cpu_ms_p50": csorted[int(PERF_FRAMES * 0.5)],
		"draw_calls_p50": dsorted[int(PERF_FRAMES * 0.5)],
		"draw_calls_max": dsorted[-1],
		"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"texture_mem_mb": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		"video_mem_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"fullscreen_translucent_layers": layers["fullscreen"],
		"fullscreen_list": layers["fullscreen_list"],
		"fullscreen_canvaslayer_quads": layers["ui_fullscreen"],
		"fullscreen_canvaslayer_list": layers["ui_fullscreen_list"],
		"overdraw_estimate": layers["overdraw"],
		"translucent_items_on_screen": layers["items"],
		"additive_items_on_screen": layers["additive"],
		"particles_emitting": layers["particles"],
		"door_open_after": bool((game.get("state") as Object).get("door_open")),
	})
	Engine.max_fps = 60
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	if paused_tween != null and paused_tween.is_valid():
		paused_tween.play()


func _mean(values: Array[float]) -> float:
	var total: float = 0.0
	for v: float in values:
		total += v
	return total / maxf(values.size(), 1.0)


## Walks the visible world canvas items and measures each one's on-screen rect against the view:
## "fullscreen" counts translucent items covering more than half the screen (the far plate is
## opaque and not counted); "overdraw" is the summed screen fraction of every visible drawn item.
func _layers() -> Dictionary:
	var view: Rect2 = Rect2(Vector2.ZERO, root.get_visible_rect().size)
	var view_area: float = view.get_area()
	var fullscreen: int = 0
	var fullscreen_list: Array = []
	var overdraw: float = 0.0
	var items: int = 0
	var additive: int = 0
	var particles: int = 0
	var ui_fullscreen: int = 0
	var ui_fullscreen_list: Array = []
	for node: Node in game.find_children("*", "CanvasItem", true, false):
		var item: CanvasItem = node as CanvasItem
		if not item.is_visible_in_tree() or item is Control and (item as Control).get_parent() is CanvasLayer and false:
			continue
		if item is CPUParticles2D:
			if (item as CPUParticles2D).emitting:
				particles += 1
			continue
		var rect: Rect2 = Rect2()
		var opaque: bool = false
		if item is Sprite2D:
			var s: Sprite2D = item as Sprite2D
			if s.texture == null:
				continue
			rect = s.get_rect()
			# The far plates are the only opaque RGB textures (Backdrop/Painting in each RoomDepth).
			opaque = s.name == "Painting" and s.get_parent() != null and s.get_parent().name == "Backdrop"
		elif item is Polygon2D or item is Line2D:
			continue
		elif item is ColorRect or item is TextureRect:
			var c: Control = item as Control
			var cl: Node = c.get_parent()
			while cl != null and not (cl is CanvasLayer):
				cl = cl.get_parent()
			if cl != null:
				var r: Rect2 = c.get_global_rect()
				if r.intersection(Rect2(Vector2.ZERO, Vector2(960, 540))).get_area() > 0.5 * 960.0 * 540.0:
					ui_fullscreen += 1
					ui_fullscreen_list.append(str(c.get_path()))
			continue
		else:
			continue
		var xf: Transform2D = item.get_global_transform_with_canvas()
		var in_layer: bool = false
		var p: Node = item.get_parent()
		while p != null:
			if p is CanvasLayer:
				in_layer = true
				break
			p = p.get_parent()
		if in_layer:
			continue
		if item is Node2D and not (item is Sprite2D):
			continue
		var screen: Rect2 = (root.get_final_transform() * xf) * rect
		var hit: Rect2 = screen.intersection(view)
		if not hit.has_area():
			continue
		var frac: float = hit.get_area() / view_area
		overdraw += frac
		items += 1
		var mat: CanvasItemMaterial = item.material as CanvasItemMaterial
		if mat != null and mat.blend_mode == CanvasItemMaterial.BLEND_MODE_ADD:
			additive += 1
		if frac > 0.5 and not opaque:
			fullscreen += 1
			fullscreen_list.append("%s %.2f" % [item.get_path(), frac])
	return {"fullscreen": fullscreen, "fullscreen_list": fullscreen_list, "overdraw": overdraw, "items": items, "additive": additive, "particles": particles,
		"ui_fullscreen": ui_fullscreen, "ui_fullscreen_list": ui_fullscreen_list}


# ------------------------------------------------------------------ input helpers

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
			# A story box stopped the walk: read it, then walk on.
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
		notes.append("%s: walk to %.0f stopped at %.0f" % [route, target_x, human.position.x])
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
