extends RefCounted
## Shared helpers for the parity tools (capture.gd, perf.gd, resources.gd, ui_dump.gd), so they do
## not each keep a copy: the command-line reader, the fixture saves the routes and the probes start
## from, and the object, memory and RSS figures the probes record. Never shipped: run.sh copies it
## beside the tools (res://parity/ for the headless runs, and into the capture driver folder that
## render.sh puts at res://review_capture/), and each tool loads it with
## `const Kit = preload("parity_kit.gd")`, a path relative to the tool itself. All statics, no state.


## The value of `--<key>=<value>` among the user arguments (the ones after `--` on the godot command
## line), or [param fallback] when it is not given.
static func arg(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


## Fixture save at the corridor's safe point after a disclosure, with WOLF powering the relay: the
## engineer at x 860 and WOLF at x 800 (world px, on the floor rows 410 and 423).
static func safe_point_state() -> M0State:
	var st: M0State = M0State.new()
	st.record_choice(M0State.DISCLOSE)
	st.arm_breaker()
	st.activate_power("wolf")
	st.reach_checkpoint()
	st.human_position = Vector2(860.0, 410.0)
	st.wolf_position = Vector2(800.0, 423.0)
	return st


## [method safe_point_state] carried into Records Access, just inside its entry (engineer x 90, WOLF
## x 50).
static func records_entry_state() -> M0State:
	var st: M0State = safe_point_state()
	st.enter_records()
	st.human_position = Vector2(90.0, 410.0)
	st.wolf_position = Vector2(50.0, 423.0)
	return st


## [method records_entry_state] with the purge order copied, the engineer beside the purge queue
## (x 140, WOLF x 100).
static func after_purge_state() -> M0State:
	var st: M0State = records_entry_state()
	st.preserve_purge_trace()
	st.human_position = Vector2(140.0, 410.0)
	st.wolf_position = Vector2(100.0, 423.0)
	return st


## Records completed (both copies, WOLF's mirror readout) and the Service Junction entered, the
## engineer at its entry (x 80) and WOLF ahead at the seam (x 400).
static func junction_entry_state() -> M0State:
	var st: M0State = records_entry_state()
	st.preserve_purge_trace()
	st.preserve_mirror_trace("wolf")
	st.complete_chapter()
	st.enter_junction()
	st.human_position = Vector2(80.0, 410.0)
	st.wolf_position = Vector2(400.0, 423.0)
	return st


## [method junction_entry_state] with the blast door blown, the pair past it (engineer x 420, WOLF
## x 380).
static func after_blast_state() -> M0State:
	var st: M0State = junction_entry_state()
	st.blow_door()
	st.human_position = Vector2(420.0, 410.0)
	st.wolf_position = Vector2(380.0, 423.0)
	return st


## The object and memory figures every probe records, as one Dictionary (perf.gd per state and at the
## end, resources.gd before and after main.tscn): Performance's node, object, resource and orphan-node
## counts, static memory now and at its peak in this process (MB, Godot's own allocator), and the
## process's resident set size in MB from [method rss_mb] ("rss_mb" now, "peak_rss_mb" the system's
## high-water mark or -1 where it gives none). Reading RSS can start a child process (macOS), so call
## this between measurements, never inside a timed span.
static func counts() -> Dictionary:
	var rss: PackedFloat64Array = rss_mb()
	return {
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"orphan_nodes": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"static_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.01),
		"static_max_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1048576.0, 0.01),
		"rss_mb": rss[0],
		"peak_rss_mb": rss[1],
	}


## This process's resident set size in MB, [now, peak so far], each -1 when unknown (float64, so the
## figures stay at their 0.1 MB rounding in the JSON, which a Vector2's float32 would not). Godot has
## no call for it, so: on Linux (CI, the render container) VmRSS and VmHWM from /proc/self/status, the
## kernel's own figures; elsewhere (macOS) `ps -o rss= -p <pid>` (KB) for now and no peak, since ps
## has no high-water mark (a caller wanting one keeps the largest of its samples, as perf.gd does).
## /proc files report a length of 0, so the status file is read line by line rather than whole.
static func rss_mb() -> PackedFloat64Array:
	var status: FileAccess = FileAccess.open("/proc/self/status", FileAccess.READ) if FileAccess.file_exists("/proc/self/status") else null
	if status != null:
		var now: float = -1.0
		var peak: float = -1.0
		while not status.eof_reached():
			var line: String = status.get_line()
			if line.begins_with("VmRSS:"):
				now = _status_mb(line)
			elif line.begins_with("VmHWM:"):
				peak = _status_mb(line)
		return PackedFloat64Array([now, peak])
	var out: Array = []
	if OS.execute("ps", ["-o", "rss=", "-p", str(OS.get_process_id())], out) == 0 and not out.is_empty():
		var kb: String = str(out[0]).strip_edges()
		if kb.is_valid_int():
			return PackedFloat64Array([snappedf(kb.to_float() / 1024.0, 0.1), -1.0])
	return PackedFloat64Array([-1.0, -1.0])


## The MB in a /proc/self/status line such as "VmRSS:	  331560 kB" (the figure is always in kB).
static func _status_mb(line: String) -> float:
	return snappedf(line.get_slice(":", 1).strip_edges().get_slice(" ", 0).to_float() / 1024.0, 0.1)
