extends SceneTree
## Headless CPU-side performance probe for the lighter-game refactor steps (never shipped: run.sh
## copies it into a scratch copy of the game as res://parity/). Frame times from the render container
## mean nothing, so this measures what a refactor step can change on the CPU, with no window:
## - startup: load(main.tscn), instantiate, add_child (every _ready), the first frame, the sound
##   bank's startup render and the time until its background clips are done;
## - per state (title, corridor start, the relay question, Records, junction entry, the lane question,
##   the lane with WOLF drawing the sentry): the whole frame's wall time (run with --fixed-fps 60, so
##   every frame is one physics step and one process step of 1/60 s, unthrottled), the span of every
##   node's _process (a first and a last node), how often the junction room redraws, and the cost of
##   one _refresh_ui call in microseconds. (Performance's TIME_PROCESS is a once-a-second maximum, so
##   it is not used.)
## - node, object and resource counts and static memory.
## The states are reached through fixture saves and Main's debug surface, unthrottled (fps limit off).
## Usage: scripts/parity/run.sh perf <out dir> <label>  (godot --headless ... -- --out=<file.json>)

const SAVE: String = "user://perf-save.json"
const SETTINGS: String = "user://perf-settings.cfg"
const HOLD_FRAMES: int = 240
const WARM_FRAMES: int = 30
const REFRESH_CALLS: int = 400
const REFRESH_BATCHES: int = 5

var game: Node2D
var head: Head
var tail: Tail
var junction_draws: int = 0
var result: Dictionary = {}


## Runs first in every frame: records the whole previous frame and starts the _process span.
class Head:
	extends Node
	var started: int = 0
	var frame_ms: PackedFloat64Array = []
	var recording: bool = false

	func _process(_delta: float) -> void:
		var now: int = Time.get_ticks_usec()
		if recording and started > 0:
			frame_ms.append(float(now - started) / 1000.0)
		started = now


## Runs last in every frame: records the span of every node's _process.
class Tail:
	extends Node
	var head: Head
	var spans: PackedFloat64Array = []
	var recording: bool = false

	func _process(_delta: float) -> void:
		if recording:
			spans.append(float(Time.get_ticks_usec() - head.started) / 1000.0)


func _initialize() -> void:
	call_deferred("_run")


func _arg(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


func _run() -> void:
	for path: String in [SAVE, SAVE + ".tmp", SETTINGS]:
		_remove(path)
	var config: ConfigFile = ConfigFile.new()
	config.set_value("video", "fps_limit", 0)
	config.set_value("video", "vsync", false)
	config.save(SETTINGS)
	head = Head.new()
	head.process_priority = -100000
	head.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(head)
	var t0: int = Time.get_ticks_usec()
	var scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var t1: int = Time.get_ticks_usec()
	game = scene.instantiate() as Node2D
	var t2: int = Time.get_ticks_usec()
	game.set("save_path", SAVE)
	game.set("settings_path", SETTINGS)
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	var t3: int = Time.get_ticks_usec()
	await process_frame
	var t4: int = Time.get_ticks_usec()
	var bank: SfxBank = game.get("sfx_bank") as SfxBank
	var detail_ms: float = -1.0
	while Time.get_ticks_usec() - t0 < 20000000:
		var task: int = int(bank.get("_detail_task"))
		if task == -1 or WorkerThreadPool.is_task_completed(task):
			detail_ms = float(Time.get_ticks_usec() - t0) / 1000.0
			break
		await process_frame
	result["startup"] = {
		"scene_load_ms": float(t1 - t0) / 1000.0,
		"instantiate_ms": float(t2 - t1) / 1000.0,
		"add_child_ready_ms": float(t3 - t2) / 1000.0,
		"first_frame_ms": float(t4 - t3) / 1000.0,
		"load_to_first_frame_ms": float(t4 - t0) / 1000.0,
		"sfx_startup_render_ms": bank.generation_ms,
		"load_to_sfx_detail_done_ms": detail_ms,
	}
	tail = Tail.new()
	tail.head = head
	tail.process_priority = 100000
	tail.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(tail)
	(game.get("junction_room") as CanvasItem).draw.connect(func() -> void: junction_draws += 1)
	var states: Dictionary = {}
	states["title"] = await _hold()
	game.call("debug_new_game", true)
	states["corridor_start"] = await _hold()
	game.call("debug_place", 350.0, 280.0)
	for _i: int in range(3):
		if game.get("waiting_for_choice"):
			break
		game.call("debug_interact")
		await _frames(5)
	states["corridor_relay_question"] = await _hold()
	(_records_entry_state()).save_to_disk(SAVE)
	game.call("debug_load_checkpoint")
	states["records"] = await _hold()
	(_junction_entry_state()).save_to_disk(SAVE)
	game.call("debug_load_checkpoint")
	states["junction_entry"] = await _hold()
	(_after_blast_state()).save_to_disk(SAVE)
	game.call("debug_load_checkpoint")
	game.call("debug_place", 600.0, 560.0)
	await _frames(5)
	states["junction_lane_question"] = await _hold()
	game.call("debug_answer_lane", 1)
	states["junction_lane_wolf"] = await _hold()
	result["states"] = states
	result["final"] = _counts()
	result["load_average"] = _arg("load", "")
	result["engine"] = Engine.get_version_info()["string"]
	var f: FileAccess = FileAccess.open(_arg("out", "user://perf.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(result, " ", true))
	f.close()
	for path: String in [SAVE, SAVE + ".tmp", SETTINGS]:
		_remove(path)
	game.queue_free()
	await process_frame
	print("perf done")
	quit()


## Settles, then records HOLD_FRAMES frames and times _refresh_ui on its own.
func _hold() -> Dictionary:
	if game.get_tree().paused and not bool(game.get("title_open")):
		game.call("_resume_game")
	await _frames(WARM_FRAMES)
	tail.spans.clear()
	head.frame_ms.clear()
	head.started = 0
	junction_draws = 0
	tail.recording = true
	head.recording = true
	await _frames(HOLD_FRAMES)
	tail.recording = false
	head.recording = false
	var draws: int = junction_draws
	var batches: Array[float] = []
	for _b: int in range(REFRESH_BATCHES):
		var start: int = Time.get_ticks_usec()
		for _c: int in range(REFRESH_CALLS):
			game.call("_refresh_ui")
		batches.append(float(Time.get_ticks_usec() - start) / REFRESH_CALLS)
	batches.sort()
	var out: Dictionary = {
		"frames": tail.spans.size(),
		"frame_ms": _stats(head.frame_ms),
		"node_process_span_ms": _stats(tail.spans),
		"junction_redraws_per_frame": float(draws) / float(maxi(tail.spans.size(), 1)),
		"refresh_ui_us": batches[REFRESH_BATCHES / 2],
		"beat": str(game.call("debug_beat")),
	}
	out.merge(_counts())
	return out


func _counts() -> Dictionary:
	return {
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"static_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.01),
	}


func _stats(values: PackedFloat64Array) -> Dictionary:
	var sorted: Array = Array(values)
	sorted.sort()
	if sorted.is_empty():
		return {}
	var total: float = 0.0
	for v: float in sorted:
		total += v
	return {
		"mean": snappedf(total / sorted.size(), 0.0001),
		"p50": snappedf(sorted[sorted.size() / 2], 0.0001),
		"p90": snappedf(sorted[int(sorted.size() * 0.9)], 0.0001),
		"p99": snappedf(sorted[mini(int(sorted.size() * 0.99), sorted.size() - 1)], 0.0001),
	}


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame


# The same fixture saves as the capture driver.
func _safe_point_state() -> M0State:
	var st: M0State = M0State.new()
	st.record_choice(M0State.DISCLOSE)
	st.arm_breaker()
	st.activate_power("wolf")
	st.reach_checkpoint()
	st.human_position = Vector2(860.0, 410.0)
	st.wolf_position = Vector2(800.0, 423.0)
	return st


func _records_entry_state() -> M0State:
	var st: M0State = _safe_point_state()
	st.enter_records()
	st.human_position = Vector2(90.0, 410.0)
	st.wolf_position = Vector2(50.0, 423.0)
	return st


func _junction_entry_state() -> M0State:
	var st: M0State = _records_entry_state()
	st.preserve_purge_trace()
	st.preserve_mirror_trace("wolf")
	st.complete_chapter()
	st.enter_junction()
	st.human_position = Vector2(80.0, 410.0)
	st.wolf_position = Vector2(400.0, 423.0)
	return st


func _after_blast_state() -> M0State:
	var st: M0State = _junction_entry_state()
	st.blow_door()
	st.human_position = Vector2(420.0, 410.0)
	st.wolf_position = Vector2(380.0, 423.0)
	return st


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
