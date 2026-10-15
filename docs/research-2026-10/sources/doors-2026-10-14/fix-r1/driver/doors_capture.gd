extends SceneTree
## Doors capture, fix round 1 (doors-r1/fix-r1; from doors-r1/integrate's, scratch only): adds the
## junction's arrival through its entry door, the walk-out from Records with WOLF following through,
## and catches the engineer in the blown doorway (j05). Run through tools/render/render.sh on
## an untouched export of main and on the integrated copy; the same script drives both, through the
## game's own debug jumps, presses and walks. Writes PNGs (with UI and -clean without), and _run.json
## with every shot's actors, camera transform and, at 1280x720, draw calls, objects, texture and
## video memory and visible additive items per state.
## Usage after --:  [--size=WxH] [--perf=1] [--only=records|junction]

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const PERF_FRAMES: int = 60

var out_dir: String = "/work/out"
var size: Vector2i = Vector2i(1280, 720)
var with_perf: bool = false
var game: Node2D
var human: Node2D
var wolf: Node2D
var junction: Node2D
var records: Node2D
var actions: Object
var canvas_layer: CanvasLayer
var notes: Array = []
var shots: Array = []
var perf_rows: Array = []


func _initialize() -> void:
	call_deferred("_run")


func _arg(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


func _run() -> void:
	seed(20261013)
	var parts: PackedStringArray = _arg("size", "1280x720").split("x")
	size = Vector2i(int(parts[0]), int(parts[1]))
	with_perf = _arg("perf", "0") == "1"
	var only: String = _arg("only", "")
	DirAccess.make_dir_recursive_absolute(out_dir)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	root.size = size
	DisplayServer.window_set_position(Vector2i(0, 0))
	var save_path: String = "user://doors-cap-save.json"
	var settings_path: String = "user://doors-cap-settings.cfg"
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
	if root.size != size:
		root.size = size
		await _raw(10)
	_reseed()
	actions = game.get("debug_tools").get("actions")
	actions.call("set_relay", &"disclose_wolf")
	actions.call("set_lane", &"wolf")
	junction = game.get("junction_room") as Node2D
	records = game.get("records_room") as Node2D
	if only != "junction":
		await _records_route()
	if only != "records":
		await _junction_route()
	var f: FileAccess = FileAccess.open(out_dir.path_join("_run.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"size": [size.x, size.y], "notes": notes, "shots": shots, "perf": perf_rows}, " "))
	f.close()
	_remove(save_path)
	_remove(settings_path)
	print("doors capture done ", notes)
	quit(0)


## Records Access: arrival through the entry, the copy point, the exit opening, walking through.
func _records_route() -> void:
	notes.append(str(actions.call("jump", &"safe_point")))
	await _raw(40)
	await _clear_cards()
	game.call("debug_place", 876.0, 790.0)
	await _raw(4)
	await _tap(&"interact")
	await _raw(3)
	await _shot("r01-arrival", "records", true)
	await _game_seconds(1.6)
	await _shot("r02-arrival-closing", "records", false)
	await _game_seconds(3.0)
	await _clear_cards()
	await _shot("r03-arrival-closed", "records", true)
	notes.append(str(actions.call("jump", &"records_mirror")))
	await _raw(40)
	await _clear_cards()
	await _walk_to(830.0)
	await _raw(30)
	await _shot("r04-copy-point", "records", true)
	await _tap(&"interact")
	await _game_seconds(1.2)
	await _shot("r05-exit-opening", "records", false)
	await _game_seconds(1.0)
	await _shot("r06-exit-opening-2", "records", false)
	await _game_seconds(2.0)
	await _clear_cards()
	await _raw(10)
	await _walk_to(830.0)
	await _raw(10)
	await _shot("r07-exit-open", "records", true)
	Engine.time_scale = 0.25
	await _tap(&"interact")
	for i: int in 12:
		await _game_seconds(0.25)
		# (the junction starts as soon as WOLF is through: stop before a frame could catch the cut)
		if _chapter() != "records" or bool(game.get("records_exit_engineer_out")) and wolf.position.x >= 960.0:
			break
		await _shot("r08-walk-out-%d" % i, "records", false)
	Engine.time_scale = 1.0
	for _i: int in 600:
		if _chapter() != "records":
			break
		await process_frame
	await _raw(2)
	await _shot("r09-after-leaving", "any", false)
	# The junction's entry stands open behind them and its closer brings it shut.
	await _game_seconds(1.6)
	await _shot("r10-entry-closing", "junction", false)
	await _game_seconds(3.0)
	await _clear_cards()
	await _raw(20)
	await _shot("r11-entry-shut", "junction", true)


## The Service Junction: sealed, the fuse, the blast frame, blown, walking through, the lane with the
## sentry, the tank drop, the exit bolt, the hatch opening, WOLF through, the engineer through, the card.
func _junction_route() -> void:
	notes.append(str(actions.call("jump", &"junction_a")))
	await _raw(60)
	await _clear_cards()
	game.set("wolf_scouting", false)
	await _walk_to(470.0)
	await _raw(40)
	await _shot("j01-sealed", "junction", true)
	# The breaker, then three turns at the valve (the game's own crank), then back past the valve.
	await _walk_to(float(_const(junction, "BREAKER_X", 200.0)))
	await _tap(&"interact")
	await _raw(10)
	var line: Object = game.get("pressure_line")
	line.call("crank", 0.4 * 3.0 + 0.01)
	game.call("debug_valve_turned")
	game.call("debug_place", 352.0, float(_const(junction, "WOLF_CLEAR_X", 100.0)))
	junction.call("sync_line", line)
	Engine.time_scale = 0.05
	for _i: int in 200:
		await process_frame
		if str(line.get("state")) == "fuse":
			break
	await _raw(3)
	await _shot("j02-fuse", "junction", false)
	for _i: int in 400:
		await process_frame
		if bool(junction.get("door_blown")):
			break
	await _shot("j03-blast-frame", "junction", false)
	Engine.time_scale = 1.0
	await _game_seconds(1.5)
	await _clear_cards()
	await _raw(30)
	await _shot("j04-blown", "junction", true)
	# In the blown doorway, between its far jamb (x 466) and the near column (x 493): the engineer in it.
	await _walk_to(478.0)
	await _raw(3)
	await _shot("j05-walking-through", "junction", false)
	notes.append(str(actions.call("jump", &"lane")))
	await _raw(60)
	await _clear_cards()
	await _game_seconds(1.5)
	await _shot("j06-lane-sentry", "junction", true)
	# The live drop: the release as soon as the sentry stands on the mark under WOLF's bait.
	var sentry: Object = junction.get("sentry")
	var hit: bool = false
	for _i: int in 900:
		await process_frame
		if sentry != null and DropArm.is_hit(float(sentry.get("target_x"))) and str((game.get("sentry_brain") as Object).get("state")) != "dormant":
			hit = true
			break
	notes.append("sentry on the mark: %s" % hit)
	Engine.time_scale = 0.1
	game.call("debug_drop_tank")
	await _game_seconds(0.12)
	await _shot("j07-tank-drop", "junction", false)
	Engine.time_scale = 1.0
	notes.append(str(actions.call("jump", &"tank_down")))
	await _raw(60)
	await _clear_cards()
	await _walk_to(float(_const(junction, "BOLT_X", 760.0)))
	await _raw(40)
	await _shot("j08-exit-bolt", "junction", true)
	Engine.time_scale = 0.1
	await _tap(&"interact")
	await _game_seconds(0.4)
	await _shot("j09-bolt-whine", "junction", false)
	for _i: int in 600:
		await process_frame
		if float(junction.get("hatch_open")) >= 0.45:
			break
	await _shot("j10-hatch-opening", "junction", false)
	Engine.time_scale = 1.0
	await _game_seconds(2.0)
	await _raw(20)
	await _shot("j11-hatch-open", "junction", true)
	var reach_min: float = float(_const(junction, "HATCH_REACH_MIN_X", -1.0))
	if reach_min > 0.0:
		await _walk_to((reach_min + float(_const(junction, "HATCH_REACH_MAX_X", reach_min + 20.0))) * 0.5)
		await _raw(10)
		await _shot("j12-at-the-door", "junction", false)
	await _tap(&"interact")
	await _game_seconds(1.0)
	await _shot("j13-closing-shot", "junction", false)
	await _tap(&"interact")
	Engine.time_scale = 0.5
	for i: int in 16:
		await _game_seconds(0.2)
		if bool(game.get("end_card_active")):
			break
		await _shot("j14-walk-out-%02d" % i, "junction", false)
	Engine.time_scale = 1.0
	for _i: int in 200:
		if bool(game.get("end_card_active")):
			break
		await process_frame
	await _game_seconds(0.5)
	await _shot("j15-end-card", "junction", false)


func _chapter() -> String:
	return str((game.get("state") as Object).get("chapter_id"))


func _const(node: Object, key: String, fallback: Variant) -> Variant:
	var map: Dictionary = (node.get_script() as Script).get_script_constant_map()
	return map.get(key, fallback)


func _clear_cards() -> void:
	for _i: int in 6:
		if bool(human.get("controlled")):
			return
		await _tap(&"interact")
		await _raw(20)


func _reseed() -> void:
	var n: int = 0
	for node: Node in game.find_children("*", "Node2D", true, false):
		if node is RoomDepth:
			var rng: RandomNumberGenerator = node.get("_rng") as RandomNumberGenerator
			if rng != null:
				rng.seed = 1000 + n
				rng.state = 0
				n += 1


func _shot(slug: String, room_key: String, perf: bool) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(slug + ".png"))
	canvas_layer.visible = false
	await _raw(1)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join(slug + "-clean.png"))
	canvas_layer.visible = true
	var xf: Transform2D = root.get_canvas_transform()
	var state: Object = game.get("state")
	shots.append({"slug": slug, "chapter": _chapter(), "engineer_x": human.position.x, "wolf_x": wolf.position.x,
		"human_alpha": human.modulate.a, "wolf_alpha": wolf.modulate.a, "human_visible": human.visible, "wolf_visible": wolf.visible,
		"canvas": [xf.x.x, xf.x.y, xf.y.x, xf.y.y, xf.origin.x, xf.origin.y], "beat": str(game.call("debug_beat")),
		"end_card": bool(game.get("end_card_active")), "door_blown": bool(state.get("door_blown")), "hatch_open": float(junction.get("hatch_open")),
		"status": str(game.get("status_line")), "time_scale": Engine.time_scale})
	if perf and with_perf:
		await _perf(slug, room_key)


func _perf(slug: String, room_key: String) -> void:
	await _raw(10)
	var draws: Array[int] = []
	var items: Array[int] = []
	for _i: int in range(PERF_FRAMES):
		await process_frame
		draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		items.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
	draws.sort()
	items.sort()
	perf_rows.append({"slug": slug, "room": room_key, "draw_calls_p50": draws[PERF_FRAMES / 2], "draw_calls_max": draws[-1], "objects_p50": items[PERF_FRAMES / 2],
		"texture_mem_mb": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		"video_mem_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"additive_visible": _additive(game), "additive_visible_room": _additive(junction if room_key == "junction" else records)})


func _additive(from: Node) -> int:
	var n: int = 0
	for node: Node in from.find_children("*", "CanvasItem", true, false):
		var item: CanvasItem = node as CanvasItem
		if item.is_visible_in_tree() and item.material is CanvasItemMaterial and (item.material as CanvasItemMaterial).blend_mode == CanvasItemMaterial.BLEND_MODE_ADD:
			n += 1
	return n


func _game_seconds(seconds: float) -> void:
	await create_timer(seconds, true, false, false).timeout


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
	var last: float = human.position.x
	var still: int = 0
	for _i: int in range(900):
		await process_frame
		if (target_x - human.position.x) * dir <= 2.0:
			reached = true
			break
		still = still + 1 if absf(human.position.x - last) < 0.01 else 0
		last = human.position.x
		if still > 40:
			break
	Input.action_release(action)
	await process_frame
	if not reached:
		notes.append("walk to %.0f stopped at %.0f" % [target_x, human.position.x])
	return reached


func _raw(frames: int) -> void:
	for _i: int in range(frames):
		await process_frame


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
