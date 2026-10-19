extends RefCounted
## Shared helpers for the parity tools (capture.gd, perf.gd, ui_dump.gd), so they do not each keep a
## copy: the command-line reader and the fixture saves the routes and the probe start from. Never
## shipped: run.sh copies it beside the tools (res://parity/ for the headless runs, and into the
## capture driver folder that render.sh puts at res://review_capture/), and each tool loads it with
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
