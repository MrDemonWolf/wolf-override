extends SceneTree
## Headless CPU-side performance probe for the lighter-game refactor steps (never shipped: run.sh
## copies it into a scratch copy of the game as res://parity/). Frame times from the render container
## mean nothing, so this measures what a refactor step can change on the CPU, with no window:
## - startup: load(main.tscn), instantiate, add_child (every _ready), the first frame, the sound
##   bank's startup render and the time until its background clips are done;
## - per state (title, corridor start, the relay question, Records, junction entry, the lane question,
##   the lane with WOLF drawing the sentry): the whole frame's wall time (run with --fixed-fps 60, so
##   every frame is one physics step and one process step of 1/60 s, unthrottled), the span of every
##   node's _process (a first and a last node), how often the junction room redraws, the cost of
##   one _refresh_ui call in microseconds, and, while the junction is on screen, the cost of one
##   junction room _draw and one Recesses _draw in microseconds (timed from the item's draw signal,
##   which fires just before _draw, to a deferred call queued right behind the redraw, which runs
##   just after it; about 7 us of that is the redraw call itself). (Performance's TIME_PROCESS is a
##   once-a-second maximum, so it is not used.)
## - the opening in the dock bay, from debug_new_game(false): every frame's wall time for
##   OPENING_FRAMES frames from the call, how many took longer than HITCH_MS, and each of those with
##   the beat it ended on (the opening waits on a press at its first box, so this is its staging and
##   the dock bay's first frames, not a read-through);
## - each room load through debug_load_checkpoint from a fixture save (parity_kit.gd): the call and
##   the call through the first frame after it, in ms;
## - one language pass: GameSettings.pick_language for every code of I18n.offered(), the call and the
##   call through the first frame after it, in ms (the first switch into a script loads its fonts);
## - node, object and resource counts, static memory now and at its peak, and the process's resident
##   set (Kit.counts) per state and at the end, plus the largest resident set seen ("peak_rss_mb").
## The run ends with Suite.end_game, the suites' own teardown (stop the audio, let the mixer let go,
## free the game), so a clip still playing does not leak its stream and playback at exit; run.sh
## fails a perf run whose log says anything leaked.
## Texture memory (RENDER_TEXTURE_MEM_USED) is 0 with the headless dummy renderer, so it is not taken
## here: the capture driver records it per still in the render container, and compare.py reports it.
## The states are reached through fixture saves and Main's debug surface, unthrottled (fps limit off).
## Usage: scripts/parity/run.sh perf <out dir> <label>  (godot --headless ... -- --out=<file.json>)

const Kit = preload("parity_kit.gd")
## The suites' kit, for its teardown (end_game) and remove_file; capture.gd preloads it the same way.
const Suite = preload("res://tests/support/game_suite.gd")
const SAVE: String = "user://perf-save.json"
const SETTINGS: String = "user://perf-settings.cfg"
const HOLD_FRAMES: int = 240
const WARM_FRAMES: int = 30
const REFRESH_CALLS: int = 400
const REFRESH_BATCHES: int = 5
const DRAW_SAMPLES: int = 120
## The opening's frames recorded from the debug_new_game(false) call: 20 s of game time at 60 fps.
## The SMOOTH audit (October 24, 2026) saw its hitches some 9.6 s in (frames 574-576 of 1,800), so 20 s
## covers them with room to spare, and the opening holds at its first box after that anyway.
const OPENING_FRAMES: int = 1200
## A frame longer than this counts as a hitch: half of a 60 Hz frame's 16.7 ms, the CPU share that
## leaves the other half for the renderer (the SMOOTH-8 audit's line).
const HITCH_MS: float = 8.0
## At most this many hitches are listed one by one; "over_hitch_ms" still counts all of them.
const HITCH_LIST: int = 20

var game: Node2D
var head: Head
var tail: Tail
var junction_draws: int = 0
var result: Dictionary = {}
var draw_started: int = 0
var draw_samples: PackedFloat64Array = []
## The largest resident set (MB) any _counts call has seen; on macOS, where ps gives no high-water
## mark, this sampled maximum is the only peak there is (see Kit.rss_mb).
var rss_peak_mb: float = -1.0


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


func _run() -> void:
	for path: String in [SAVE, SAVE + ".tmp", SETTINGS]:
		Suite.remove_file(path)
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
	result["opening"] = await _opening()
	game.call("debug_new_game", true)
	states["corridor_start"] = await _hold()
	game.call("debug_place", 350.0, 280.0)
	for _i: int in range(3):
		if game.get("waiting_for_choice"):
			break
		game.call("debug_interact")
		await _frames(5)
	states["corridor_relay_question"] = await _hold()
	var loads: Dictionary = {}
	loads["corridor_safe_point"] = await _load_room(Kit.safe_point_state())
	loads["records"] = await _load_room(Kit.records_entry_state())
	states["records"] = await _hold()
	loads["junction_entry"] = await _load_room(Kit.junction_entry_state())
	states["junction_entry"] = await _hold()
	loads["junction_after_blast"] = await _load_room(Kit.after_blast_state())
	result["room_loads"] = loads
	game.call("debug_place", 600.0, 560.0)
	await _frames(5)
	states["junction_lane_question"] = await _hold()
	game.call("debug_answer_lane", 1)
	states["junction_lane_wolf"] = await _hold()
	result["states"] = states
	# "final" stays where it always was (after the lane), so older runs compare; the language pass
	# loads every script's fonts, and its counts are taken on their own after it.
	result["final"] = _counts()
	result["languages"] = await _language_pass()
	result["after_languages"] = _counts()
	result["peak_rss_mb"] = maxf(rss_peak_mb, float(result["after_languages"]["peak_rss_mb"]))
	result["load_average"] = Kit.arg("load", "")
	result["engine"] = Engine.get_version_info()["string"]
	var f: FileAccess = FileAccess.open(Kit.arg("out", "user://perf.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(result, " ", true))
	f.close()
	# The detailed clips' worker must be done before the bank goes (its _exit_tree waits too; this
	# keeps the wait out of the teardown's frames). end_game removes SAVE and SETTINGS (the game's
	# save_path and settings_path); the save's .tmp is the probe's own to remove.
	(game.get("sfx_bank") as SfxBank).wait_for_detail()
	await Suite.end_game(game)
	Suite.remove_file(SAVE + ".tmp")
	print("perf done")
	quit()


## The opening from a new game with its intro (debug_new_game(false)), recorded from the call for
## OPENING_FRAMES frames: the call's own ms, the frame stats, how many frames took over HITCH_MS, the
## first HITCH_LIST of those (frame index from the call, ms, and the beat shown as it ended), the beat
## at the end, and the counts. No warm-up: the first frames are the ones a player sees.
func _opening() -> Dictionary:
	var start: int = Time.get_ticks_usec()
	game.call("debug_new_game", false)
	var call_ms: float = float(Time.get_ticks_usec() - start) / 1000.0
	var beats: Array[String] = []
	await _record(OPENING_FRAMES, beats)
	var hitches: Array[Dictionary] = []
	var over: int = 0
	for index: int in head.frame_ms.size():
		if head.frame_ms[index] > HITCH_MS:
			over += 1
			if hitches.size() < HITCH_LIST:
				hitches.append({"frame": index, "ms": snappedf(head.frame_ms[index], 0.01), "beat": beats[index]})
	var out: Dictionary = {
		"new_game_call_ms": snappedf(call_ms, 0.01),
		"frames": head.frame_ms.size(),
		"frame_ms": _stats(head.frame_ms),
		"over_hitch_ms": over,
		"hitch_ms": HITCH_MS,
		"hitches": hitches,
		"end_beat": str(game.call("debug_beat")),
	}
	out.merge(_counts())
	return out


## Saves [param state] as the checkpoint and loads it as the title's Continue does
## (debug_load_checkpoint): the call, and the call through the end of the first frame after it, in ms.
func _load_room(state: M0State) -> Dictionary:
	state.save_to_disk(SAVE)
	var start: int = Time.get_ticks_usec()
	game.call("debug_load_checkpoint")
	var called: int = Time.get_ticks_usec()
	await process_frame
	return {
		"call_ms": snappedf(float(called - start) / 1000.0, 0.01),
		"through_first_frame_ms": snappedf(float(Time.get_ticks_usec() - start) / 1000.0, 0.01),
	}


## One pass of GameSettings.pick_language over I18n.offered() in its order, each timed like
## _load_room (the call, and through the first frame after it, in ms), keyed by code; then back to the
## language the game was in, untimed. pick_language also saves the choice to SETTINGS.
func _language_pass() -> Dictionary:
	var menu: GameSettings = game.get("settings_menu") as GameSettings
	var was: String = I18n.resolve(TranslationServer.get_locale())
	var out: Dictionary = {}
	for code: String in I18n.offered():
		var start: int = Time.get_ticks_usec()
		menu.pick_language(code)
		var called: int = Time.get_ticks_usec()
		await process_frame
		out[code] = {
			"call_ms": snappedf(float(called - start) / 1000.0, 0.01),
			"through_first_frame_ms": snappedf(float(Time.get_ticks_usec() - start) / 1000.0, 0.01),
		}
	menu.pick_language(was)
	await process_frame
	return out


## Settles, then records HOLD_FRAMES frames and times _refresh_ui on its own.
func _hold() -> Dictionary:
	if game.get_tree().paused and not bool(game.get("title_open")):
		game.call("_resume_game")
	await _frames(WARM_FRAMES)
	await _record(HOLD_FRAMES)
	var draws: int = junction_draws
	var batches: Array[float] = []
	for _b: int in range(REFRESH_BATCHES):
		var start: int = Time.get_ticks_usec()
		for _c: int in range(REFRESH_CALLS):
			game.call("_refresh_ui")
		batches.append(float(Time.get_ticks_usec() - start) / REFRESH_CALLS)
	batches.sort()
	var junction: CanvasItem = game.get("junction_room") as CanvasItem
	var out: Dictionary = {
		"frames": tail.spans.size(),
		"frame_ms": _stats(head.frame_ms),
		"node_process_span_ms": _stats(tail.spans),
		"junction_redraws_per_frame": float(draws) / float(maxi(tail.spans.size(), 1)),
		"refresh_ui_us": batches[REFRESH_BATCHES / 2],
		"junction_draw_us": await _draw_us(junction),
		"recesses_draw_us": await _draw_us(junction.get("recesses") as CanvasItem),
		"beat": str(game.call("debug_beat")),
	}
	out.merge(_counts())
	return out


## Records [param count] frames from now: each whole frame into head.frame_ms, each _process span
## into tail.spans (both cleared first) and junction redraws into junction_draws. With [param beats]
## (an Array, filled in place), also appends debug_beat() after every frame's processing, so beats[i]
## is the beat of the frame frame_ms[i] timed.
func _record(count: int, beats: Variant = null) -> void:
	tail.spans.clear()
	head.frame_ms.clear()
	head.started = 0
	junction_draws = 0
	tail.recording = true
	head.recording = true
	for _i: int in range(count):
		await process_frame
		if beats is Array:
			(beats as Array).append(str(game.call("debug_beat")))
	tail.recording = false
	head.recording = false


## The median cost of one _draw of item over DRAW_SAMPLES frames, in microseconds; -1 when the item is
## not on screen (a hidden item does not draw). Each frame, right after process_frame, it queues the
## item's redraw and then a deferred stamp, so the message queue runs the redraw (draw signal, then
## _draw) and the stamp back to back.
func _draw_us(item: CanvasItem) -> float:
	if item == null or not item.is_visible_in_tree():
		return -1.0
	draw_samples.clear()
	item.draw.connect(_on_timed_draw)
	for _i: int in range(DRAW_SAMPLES):
		await process_frame
		draw_started = 0
		item.queue_redraw()
		_end_timed_draw.call_deferred()
	await process_frame
	item.draw.disconnect(_on_timed_draw)
	if draw_samples.size() < DRAW_SAMPLES / 2:
		push_error("perf: only %d of %d timed draws of %s" % [draw_samples.size(), DRAW_SAMPLES, item.name])
		return -1.0
	var sorted: Array = Array(draw_samples)
	sorted.sort()
	return snappedf(float(sorted[sorted.size() / 2]), 0.1)


func _on_timed_draw() -> void:
	draw_started = Time.get_ticks_usec()


func _end_timed_draw() -> void:
	if draw_started > 0:
		draw_samples.append(float(Time.get_ticks_usec() - draw_started))
	draw_started = 0


## Kit.counts() (objects, memory and resident set), also keeping the largest resident set seen in
## rss_peak_mb.
func _counts() -> Dictionary:
	var counts: Dictionary = Kit.counts()
	rss_peak_mb = maxf(rss_peak_mb, float(counts["rss_mb"]))
	return counts


func _stats(values: PackedFloat64Array) -> Dictionary:
	var sorted: Array = Array(values)
	sorted.sort()
	if sorted.is_empty():
		return {}
	var total: float = 0.0
	for v: float in sorted:
		total += v
	return {
		"max": snappedf(sorted[sorted.size() - 1], 0.0001),
		"mean": snappedf(total / sorted.size(), 0.0001),
		"p50": snappedf(sorted[sorted.size() / 2], 0.0001),
		"p90": snappedf(sorted[int(sorted.size() * 0.9)], 0.0001),
		"p99": snappedf(sorted[mini(int(sorted.size() * 0.99), sorted.size() - 1)], 0.0001),
	}


func _frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame

