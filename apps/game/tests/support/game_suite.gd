extends SceneTree
## The shared kit for the headless suites (scripts/check-game.sh runs every tests/*_test.gd as
## `godot --headless --script`). AGENTS.md's "Don't duplicate code" rule: the bookkeeping, game
## spawn and teardown, waits, holds and image helpers that suites used to copy into themselves live
## here once.
##
## How to use it: every suite extends it, `extends "res://tests/support/game_suite.gd"`, defines
## `_run()` (the kit's _initialize calls it deferred), sets [member check_name] (the start of every
## failure message) first thing, reports with [method _expect] or [method _require] and ends with
## [method finish]. It must not declare its own `failures`, `check_name` or `MAIN_SCENE`:
## redeclaring a parent member is a parse error. It calls the statics below by their bare names, and
## keeps only helpers that no other suite needs; a helper a second suite wants moves here.
##
## The file has no class_name, so nothing test-only enters the game's global class list, and it
## never ships: export_presets.cfg excludes tests/*, which covers tests/support/. check-game.sh only
## globs tests/*_test.gd, so it is never run as a suite itself.
##
## Users (2026-10-18): every tests/*_test.gd. What must stay true for every user:
## - What the statics touch besides their arguments: the running SceneTree (tree(), and its paused
##   flag in free_tools_game); the global Input actions and events (hold, press_for, tap, walk_to,
##   walk_to_reading_on, retry, send_key and continue_until (with its two users) press or send them,
##   and each releases what it pressed
##   before it returns); user:// files (remove_file and remove_tools_files delete them, write_text
##   writes one, fresh_save_path, start_game and open_game delete stale save and settings files
##   before the game starts, end_game deletes the game's own after it is freed); the root's children
##   (start_clock adds a GameClock the caller frees, wait_game_seconds adds and frees its own); and
##   the process id (in the file names, so suites run side by side do not share files). Nothing else
##   is kept between calls: the kit has no static state.
## - The parity capture driver (scripts/parity/capture.gd) preloads this file for continue_until,
##   finish_opening and finish_closing_lines, so a played route and the suites press through the
##   opening and the closing lines the same way; those three must keep working outside a suite (they
##   use only tree(), tap and the game's own nodes).
## - frames, wait_until, hold, press_for, walk_to, walk_to_reading_on, retry, continue_until,
##   finish_opening and finish_closing_lines count physics frames
##   (1/60 s of game time each at the project's physics rate, not the wall clock), so a busy machine
##   slows those waits down but does not change what they see; tap, settle, send_key and retry hold
##   presses for process frames. GameClock, start_clock and wait_game_seconds measure and wait in
##   game time (the summed process deltas the game itself runs on), never the wall clock, so a check
##   with an upper bound on how long something took does not fail on a busy machine; only their hang
##   guard is in wall time. spawn_game and start_game wait one process frame, add_game and
##   open_game none. end_game waits process frames and SceneTree timers in seconds, which do follow
##   real time: the audio mixer and the loader threads it waits for run on the wall clock, not on
##   game frames.
## - end_game leaves no game, sound or file behind, because check-game fails a suite that leaks
##   objects at exit.

## The game scene every suite plays.
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

## The language a suite's made-up catalog stands in for (i18n_test's HUD and story checks, settings_test's menu
## translation): one in languages.json that ships no catalog (Italian, outside decision D1's twelve
## files), so no real catalog of the same locale answers first. Which of two catalogs of one locale
## answers is Godot's order, not the test's. It was "es" until PR L9 shipped es.po, and settings_test's
## was "pt_BR" until PR L10 shipped pt_BR.po; one shared code keeps the next shipped language from
## breaking a suite again. The made-up words stay whatever language they were written in.
const UNSHIPPED_TEST_LANGUAGE: String = "it"

## Failed checks so far; [method finish] quits with status 1 when there are any.
var failures: int = 0
## The suite's name as its failure messages start, for example "Corridor additions": a failed check
## pushes "<check_name> check failed: <label>", word for word what the suites printed before.
var check_name: String = ""


## Counts and reports a failed check. Returns [param condition], so a caller can skip checks that
## depend on this one: `if not _expect(node != null, "..."): return`.
func _expect(condition: bool, label: String) -> bool:
	if not condition:
		failures += 1
		push_error("%s check failed: %s" % [check_name, label])
	return condition


## Ends the suite: prints [param pass_note] when every check passed and the note is not empty, then
## quits with status 0, or 1 after any failed check.
func finish(pass_note: String = "") -> void:
	if failures == 0 and not pass_note.is_empty():
		print(pass_note)
	quit(1 if failures > 0 else 0)


## Starts the suite once the tree is up: calls the suite's own `_run()` (which every suite that
## extends the kit defines) deferred, so it runs after the first idle frame, as a SceneTree script's
## _initialize cannot await. A suite that does all its work in _initialize overrides this.
func _initialize() -> void:
	call_deferred("_run")


## [method _expect], and on failure quits with status 1 at once, for checks the rest of the suite
## cannot run without. Returns [param condition]. quit() only takes effect after the current frame,
## so a caller that goes on must also stop on false: `if not _require(...): return`.
func _require(condition: bool, label: String) -> bool:
	_expect(condition, label)
	if not condition:
		quit(1)
	return condition


## The running SceneTree (the suite itself), for the statics, which have no `self`.
static func tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Instantiates the game and adds it to the tree without waiting, for suites that drive it before its
## first frame (calling _new_game straight away, say). [param save_path] and [param settings_path]
## are user:// files the game reads and writes instead of the player's own; [param configure], when
## given, is called with the game before it enters the tree (for properties its _ready reads, such as
## auto_pause_on_focus_loss; [method keep_running] is the usual one). The caller frees it.
static func add_game(save_path: String, settings_path: String, configure: Callable = Callable()) -> Node2D:
	var game: Node2D = MAIN_SCENE.instantiate() as Node2D
	game.set("save_path", save_path)
	game.set("settings_path", settings_path)
	if configure.is_valid():
		configure.call(game)
	tree().root.add_child(game)
	return game


## [method add_game], then waits one process frame, so the game has run its first frame, and returns
## it. The caller frees it, normally with [method end_game].
static func spawn_game(save_path: String, settings_path: String, configure: Callable = Callable()) -> Node2D:
	var game: Node2D = add_game(save_path, settings_path, configure)
	await tree().process_frame
	return game


## This process's own save file for [param file_stem], user://<file_stem>-<pid>.json, with its
## settings file (<that>-settings.cfg) beside it; the process id keeps suites that run side by side
## apart. Removes both when an earlier run that was stopped left them, and returns the save path.
static func fresh_save_path(file_stem: String) -> String:
	var save_path: String = "user://%s-%s.json" % [file_stem, OS.get_process_id()]
	remove_file(save_path)
	remove_file("%s-settings.cfg" % save_path)
	return save_path


## [method spawn_game] with [method fresh_save_path]'s files for [param file_stem]. [method end_game]
## removes them again.
static func start_game(file_stem: String, configure: Callable = Callable()) -> Node2D:
	var save_path: String = fresh_save_path(file_stem)
	return await spawn_game(save_path, "%s-settings.cfg" % save_path, configure)


## [method start_game] without the frame wait: the game is in the tree but its first frame has not
## run, for suites that drive it before then. Not a coroutine, so callers do not await it.
static func open_game(file_stem: String, configure: Callable = Callable()) -> Node2D:
	var save_path: String = fresh_save_path(file_stem)
	return add_game(save_path, "%s-settings.cfg" % save_path, configure)


## A configure callable for the spawners: the game keeps running when the headless window reports a
## focus loss (Main pauses on one by default, which would stop a suite's frames counting).
static func keep_running(game: Node) -> void:
	game.set("auto_pause_on_focus_loss", false)


## A game for the debug-tools suites (crank_hold, debug_tools), which name their files from one
## [param base] path (user://<suite>-<pid>): settings in <base>.cfg, the save in <base>-save.json.
## It keeps running on focus loss, has run its first process frame, and its DebugTools act as in a
## debug build when [param debug_build] is true and as in a release build when false. Free it with
## [method free_tools_game]; [method remove_tools_files] deletes the files.
static func spawn_tools_game(base: String, debug_build: bool) -> Node2D:
	var game: Node2D = await spawn_game(base + "-save.json", base + ".cfg", keep_running)
	(game.get("debug_tools") as DebugTools).debug_build = debug_build
	return game


## Frees a [method spawn_tools_game] game between checks: lets go of interact and the two move
## actions (a check that fails mid-press must not leave them held for the next), unpauses the tree
## and waits two process frames for the free to land. Leaves its files for the next check.
static func free_tools_game(game: Node) -> void:
	for action: StringName in [&"interact", &"move_left", &"move_right"]:
		Input.action_release(action)
	tree().paused = false
	game.queue_free()
	await tree().process_frame
	await tree().process_frame


## Deletes the settings, save and half-written save (<base>-save.json.tmp) files of a
## [method spawn_tools_game] game named from [param base], so a check starts from defaults.
static func remove_tools_files(base: String) -> void:
	for path: String in [base + ".cfg", base + "-save.json", base + "-save.json.tmp"]:
		remove_file(path)


## Silences [param game]: its SfxBank's voices (stop_all) when it has one, then every
## AudioStreamPlayer and AudioStreamPlayer2D under it, rooms' one-shots included. A clip still
## playing when the game is freed can leak its playback at exit.
static func stop_audio(game: Node) -> void:
	var bank: SfxBank = game.get("sfx_bank") as SfxBank
	if bank != null:
		bank.stop_all()
	for player: Node in game.find_children("*", "AudioStreamPlayer", true, false) + game.find_children("*", "AudioStreamPlayer2D", true, false):
		player.call("stop")


## Frees [param game] the way that leaves nothing behind at exit, then removes its save and
## settings files: stop its audio, give the mixer 0.1 s to release the playback, free the game, run
## 10 process frames so queued frees and deferred calls finish, then wait [param settle_seconds]
## (seconds of real time) for the audio and loader threads to let go of their resources.
static func end_game(game: Node, settle_seconds: float = 0.3) -> void:
	var files: Array[String] = [str(game.get("save_path")), str(game.get("settings_path"))]
	stop_audio(game)
	await tree().create_timer(0.1).timeout
	game.queue_free()
	for _frame: int in 10:
		await tree().process_frame
	await tree().create_timer(settle_seconds).timeout
	for file: String in files:
		remove_file(file)


## The station names that show in [param game]'s rooms right now, visible and with text: the
## corridor's (Main._corridor_station_labels), Records Access's and the Service Junction's. Shared by
## text_boxes_test (the names stay apart at every TEXT SIZE step) and i18n_test (the same in every
## offered language), so both judge the same set.
static func shown_station_labels(game: Node) -> Array[Label]:
	var candidates: Array = game.call("_corridor_station_labels")
	candidates.append_array(game.get("records_room").get("station_labels"))
	candidates.append_array(game.get("junction_room").get("station_labels"))
	var shown: Array[Label] = []
	for label: Label in candidates:
		if label.is_visible_in_tree() and not label.text.is_empty():
			shown.append(label)
	return shown


## Every pair of [param labels] whose global rects overlap, each rect shrunk by 0.5 px so names that only
## touch pass, as "<text> and <text> overlap (<rect>, <rect>)" lines (rects in canvas px). Empty when
## every name stands apart. Pure: reads the labels' current layout.
static func overlapping_labels(labels: Array[Label]) -> Array[String]:
	var found: Array[String] = []
	for a: int in labels.size():
		var rect: Rect2 = labels[a].get_global_rect()
		for b: int in range(a + 1, labels.size()):
			var other: Rect2 = labels[b].get_global_rect()
			if rect.grow(-0.5).intersects(other.grow(-0.5)):
				found.append("%s and %s overlap (%s, %s)" % [labels[a].text.c_escape(), labels[b].text.c_escape(), rect, other])
	return found


## Waits [param count] physics frames, 1/60 s of game time each.
static func frames(count: int) -> void:
	for _frame: int in count:
		await tree().physics_frame


## Waits physics frames until [param condition] holds, checking after each frame. Returns true as
## soon as it holds, or false once [param max_frames] frames have passed without it.
static func wait_until(condition: Callable, max_frames: int) -> bool:
	for _step: int in max_frames:
		await tree().physics_frame
		if condition.call():
			return true
	return false


## A stopwatch in game time: the sum of the process deltas the game's own _process, tweens and
## SceneTree timers advance by, in seconds. Suites measure with it instead of Time.get_ticks_msec,
## because on a busy machine (check-game.sh runs four suites at once, CI runners share cores) frames
## come late and the wall clock runs ahead of everything the game counts, so an upper bound in wall
## time fails for no fault of the game. It is not a count of physics frames at 1/60 s either: the
## opening's beats, the box reading times and the logo run on process deltas, and when frames come
## late those drift apart from the physics count (Godot runs at most max_physics_steps_per_frame
## physics steps per process frame and drops the rest).
## Read [member seconds] right after `await process_frame`: SceneTree emits process_frame before any
## node's _process, so at that point [member seconds] is the game time of the state the suite sees
## (every frame the game has finished), not one frame ahead. The clock is a node: it only runs in
## the tree, stops while the tree is paused (it inherits the root's pausable mode, as the game's
## pausable nodes do), and the caller frees it (check-game fails a suite that leaks it).
## [method start_clock] makes one; [method wait_game_seconds] uses one.
class GameClock extends Node:
	## Game time since the clock entered the tree, in seconds.
	var seconds: float = 0.0
	## Each frame adds at most this many seconds (INF: the whole delta). StudioLogo clamps its own
	## steps to StudioLogo.MAX_STEP, so a suite timing the logo clamps the same and counts what the
	## logo counts; a long frame (a load hitch) then adds what it adds to the logo, not its length.
	var max_step: float = INF

	func _process(delta: float) -> void:
		seconds += minf(delta, max_step)


## A new [GameClock] added under the root, starting at 0 s of game time from the next process frame;
## each step is clamped to [param max_step] seconds. The caller frees it (`clock.free()`).
static func start_clock(max_step: float = INF) -> GameClock:
	var clock: GameClock = GameClock.new()
	clock.max_step = max_step
	tree().root.add_child(clock)
	return clock


## How much wall-clock time a game-time wait may take per second it waits, plus HANG_GUARD_BASE_MS:
## only a guard against a game that stops making frames at all. It lets the game run ten times slower
## than real time before it ends a wait, far slower than a busy machine makes it run, so it never
## decides a check; the game-time limit does. check-game.sh's SUITE_TIMEOUT (240 s) would stop a
## hung suite too, but without saying which wait hung.
const HANG_GUARD_PER_SECOND_MS: int = 10000
## The fixed part of the hang guard, in milliseconds (see HANG_GUARD_PER_SECOND_MS).
const HANG_GUARD_BASE_MS: int = 30000


## Waits process frames until [param done] (when given) holds, checked before each frame, or until
## [param seconds] of game time ([GameClock], each step clamped to [param max_step]) have passed.
## Returns the game time it waited, in seconds; the caller checks [param done] again for which one
## ended it. A generous wall-clock limit (HANG_GUARD_PER_SECOND_MS) only ends the wait if frames stop.
static func wait_game_seconds(seconds: float, done: Callable = Callable(), max_step: float = INF) -> float:
	var clock: GameClock = start_clock(max_step)
	var guard_ms: int = Time.get_ticks_msec() + HANG_GUARD_BASE_MS + int(seconds * HANG_GUARD_PER_SECOND_MS)
	while clock.seconds < seconds and Time.get_ticks_msec() < guard_ms:
		if done.is_valid() and done.call():
			break
		await tree().process_frame
	var waited: float = clock.seconds
	clock.free()
	return waited


## Holds the input [param action] down for up to [param max_frames] physics frames, stopping early
## once [param stop] (when given) holds, checked before each frame. Then releases it and waits two
## physics frames, so the release has been seen before the caller looks.
static func hold(action: StringName, max_frames: int, stop: Callable = Callable()) -> void:
	Input.action_press(action)
	for _step: int in max_frames:
		if stop.is_valid() and stop.call():
			break
		await tree().physics_frame
	Input.action_release(action)
	await frames(2)


## Taps the input [param action] as a key press reaches the game: waits a process frame, presses,
## holds for one process frame and releases, then waits [param settle_frames] more process frames.
## pause_game is event-driven in Main (_unhandled_input), not polled, so it is sent as a real
## InputEventAction pair instead; settle_frames does not apply to it.
static func tap(action: StringName, settle_frames: int = 0) -> void:
	await tree().process_frame
	if action == &"pause_game":
		Input.parse_input_event(action_event(action, true))
		await tree().process_frame
		Input.parse_input_event(action_event(action, false))
		return
	Input.action_press(action)
	await tree().process_frame
	Input.action_release(action)
	for _frame: int in settle_frames:
		await tree().process_frame


## A pressed or released ([param pressed]) InputEventAction for [param action], for
## Input.parse_input_event.
static func action_event(action: StringName, pressed: bool) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


## A key event for [param code], down or up ([param pressed]), by both its keycode and its physical
## keycode, as a keyboard sends it, for Input.parse_input_event, Viewport.push_input or a node's
## _input. Users: send_key, settings_test and studio_logo_test.
static func key_event(code: Key, pressed: bool = true) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	return event


## A controller button event for [param button], down or up ([param pressed]), on the first
## controller (device 0). Users: settings_test and ui_controls_test.
static func controller_button(button: JoyButton, pressed: bool) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	return event


## Writes [param text] to the user:// (or absolute) file at [param path], replacing what it held, for
## suites that hand the game a settings or script file of their own. Users: settings_test and
## studio_logo_test.
static func write_text(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## Waits [param count] process frames: one pass of every node's _process and of the UI, the step
## input events and menus answer on (not the physics frames [method frames] counts).
static func settle(count: int) -> void:
	for _frame: int in count:
		await tree().process_frame


## Sends one key event, [param code] down or up ([param pressed]) by both its keycode and its
## physical keycode, as Input.parse_input_event, then waits a process frame so the game has seen it.
static func send_key(code: Key, pressed: bool) -> void:
	Input.parse_input_event(key_event(code, pressed))
	await tree().process_frame


## Presses and releases the key [param code] ([method send_key] down, then up): two process frames.
static func tap_key(code: Key) -> void:
	await send_key(code, true)
	await send_key(code, false)


## Holds [param action] down for exactly [param count] physics frames, then releases it (no wait
## after, unlike [method hold]).
static func press_for(action: StringName, count: int) -> void:
	Input.action_press(action)
	await frames(count)
	Input.action_release(action)


## Walks [param actor] toward [param target_x] (world px) by holding move_left or move_right for up
## to 300 physics frames (5 s of game time), stopping once it is within 12 px. Returns whether it got
## there. One straight walk: a story box or scripted step that takes control away stops it short.
static func walk_to(actor: M0Actor, target_x: float) -> bool:
	var action: StringName = &"move_right" if target_x > actor.position.x else &"move_left"
	Input.action_press(action)
	var reached: bool = false
	for _frame: int in 300:
		await tree().physics_frame
		if absf(actor.position.x - target_x) <= 12.0:
			reached = true
			break
	Input.action_release(action)
	return reached


## Walks [param actor] to within 6 px of [param target_x] (world px) through whatever the game puts in
## the way: up to four attempts of 360 physics frames each. When an attempt loses control, it waits up
## to 60 frames for the game to hand control back on its own (a scripted step), and only when it does
## not taps interact to read a story box on and waits 10 frames. After arriving it waits 2 physics
## frames so the stop has settled. Returns whether the actor ends within 6 px.
static func walk_to_reading_on(actor: M0Actor, target_x: float) -> bool:
	for _attempt: int in 4:
		var action: StringName = &"move_right" if target_x > actor.position.x else &"move_left"
		Input.action_press(action)
		var reached: bool = false
		for _frame: int in 360:
			await tree().physics_frame
			if absf(actor.position.x - target_x) <= 6.0:
				reached = true
				break
			if not actor.controlled:
				break
		Input.action_release(action)
		if reached:
			await frames(2)
			return true
		if not await wait_until(func() -> bool: return actor.controlled, 60):
			await tap(&"interact", 1)
			await frames(10)
	return absf(actor.position.x - target_x) <= 6.0


## Where a played route stands to leave through the junction's open exit door: the middle of the reach
## its USE leaves from (JunctionRoom.HATCH_REACH_MIN_X 846 to HATCH_REACH_MAX_X, about 888; world px).
## Not door_route_test's leave_x (HATCH_REACH_MIN_X + 0.5), which it reaches by placing the engineer:
## a walk stops within a few px of its target (up to 6 for walk_to_reading_on, 3 for the capture's
## _walk_to, at 3.2 px a frame), so aimed at the window's edge it can stop short of it and the USE
## then works the bolt panel instead (the parity R4 failure of 2026-10-24, engineer at x 760.7).
const OPEN_EXIT_X: float = (JunctionRoom.HATCH_REACH_MIN_X + JunctionRoom.HATCH_REACH_MAX_X) * 0.5


## How long [method finish_opening] lets the opening run at most, in physics frames: 90 s of game
## time, the bound opening_timing_test plays it in (first control comes 30 to 45 s in when every box is
## read through, so this is about twice that).
const OPENING_MAX_FRAMES: int = 90 * 60
## How long one conversation read through with [method continue_until] may take at most, in physics
## frames: 60 s of game time. continue_until reads every box for its full reading time (up to 7 s
## each), and the corridor breaker's talk runs WOLF's stakes and the opening lines before his question
## (Main._interact_breaker), about 30 s. Users: full_slice_test and the parity capture's R2.
const TALK_FRAMES: int = 60 * 60
## How long [method finish_closing_lines] lets the junction's closing lines run at most, in physics
## frames: 30 s of game time, several times the three boxes' reading time (about 2 s each).
const CLOSING_MAX_FRAMES: int = 30 * 60


## Presses CONTINUE (a [method tap] of interact) the way a player reading every box does, until
## [param done] holds: the box the Story label shows is pressed on once it has been up for its reading
## time (DialogueBoxes.read_seconds, the game's own rule, in the language shown), and pressed again
## after each further reading time when it has not moved on (a press during a beat that is still
## playing may only queue it). Checks [param done] before each physics frame and gives up after
## [param max_frames] of them (1/60 s of game time each, so a busy machine slows it down without
## changing what it presses). Returns whether [param done] holds at the end. Shared by the suites and
## the parity capture driver (scripts/parity/capture.gd), which preloads this file for it.
static func continue_until(game: Node, done: Callable, max_frames: int) -> bool:
	var story: Label = game.get_node("CanvasLayer/BottomBar/Story") as Label
	var shown: String = story.text
	var age: int = 0
	for _frame: int in max_frames:
		if done.call():
			return true
		if story.text != shown:
			shown = story.text
			age = 0
		elif age >= ceili(DialogueBoxes.read_seconds(shown.strip_edges()) * Engine.physics_ticks_per_second):
			await tap(&"interact")
			age = 0
		await tree().physics_frame
		age += 1
	return bool(done.call())


## Plays the rest of the opening that is running in [param game] ([method continue_until], reading
## every box) until it hands over to play (Main.intro_active false), at most [constant
## OPENING_MAX_FRAMES] physics frames. Returns "" once it has, or a failure note naming the beat and box
## it stuck on. Control itself comes a moment later, under the fade into play: callers wait for
## M0Actor.controlled.
static func finish_opening(game: Node) -> String:
	if await continue_until(game, func() -> bool: return not bool(game.get("intro_active")), OPENING_MAX_FRAMES):
		return ""
	return "the opening never handed over to play: still at beat %d after %d s of game time, on the box \"%s\"" % [int(game.get("intro_step")), OPENING_MAX_FRAMES / 60, (game.get_node("CanvasLayer/BottomBar/Story") as Label).text.c_escape()]


## Reads the junction's closing lines in [param game] through ([method continue_until]) after USE at
## its open exit door, until the walk out starts (Main.hatch_exit_walking) or the END OF SLICE card is
## up (Main.end_card_active), at most [constant CLOSING_MAX_FRAMES] physics frames. Returns "" once it
## has, or a failure note naming the box it stuck on.
static func finish_closing_lines(game: Node) -> String:
	if await continue_until(game, func() -> bool: return bool(game.get("hatch_exit_walking")) or bool(game.get("end_card_active")), CLOSING_MAX_FRAMES):
		return ""
	return "the closing lines never led to the walk out: after %d s of game time the box shows \"%s\"" % [CLOSING_MAX_FRAMES / 60, (game.get_node("CanvasLayer/BottomBar/Story") as Label).text.c_escape()]


## True while some player in [param game]'s SfxBank is playing [param clip] (an SfxBank clip name).
static func sounding(game: Node, clip: StringName) -> bool:
	var sfx: SfxBank = game.get("sfx_bank") as SfxBank
	for player: AudioStreamPlayer in sfx.players():
		if player.playing and player.stream == sfx.streams.get(clip):
			return true
	return false


## How far [method story_state] takes a run: the corridor's safe point reached, the Records room
## entered, the chapter completed in it, the junction entered, and the junction's blast door blown.
enum Story { CHECKPOINT_REACHED, RECORDS_ENTERED, RECORDS_DONE, JUNCTION_ENTERED, DOOR_DOWN }


## A save state built with M0State's own steps, as play makes it: the corridor choice
## [param choice_id] (M0State.DISCLOSE or PRESS), the breaker, the relay powered (by WOLF after a
## disclosure, by the engineer otherwise) and the checkpoint, then on to [param through] (a
## [enum Story] stage). Past entering Records it keeps the purge trace and the mirror trace (WOLF's readout
## after a disclosure, the manual copy otherwise) and completes the chapter. Positions are left at
## M0State's defaults.
static func story_state(choice_id: String, through: Story) -> M0State:
	var disclosed: bool = choice_id == M0State.DISCLOSE
	var state: M0State = M0State.new()
	state.record_choice(choice_id)
	state.arm_breaker()
	state.activate_power("wolf" if disclosed else "human")
	state.reach_checkpoint()
	if through == Story.CHECKPOINT_REACHED:
		return state
	state.enter_records()
	if through == Story.RECORDS_ENTERED:
		return state
	state.preserve_purge_trace()
	state.preserve_mirror_trace("wolf" if disclosed else "manual")
	state.complete_chapter()
	if through >= Story.JUNCTION_ENTERED:
		state.enter_junction()
	if through >= Story.DOOR_DOWN:
		state.blow_door()
	return state


## [method story_state] through Records with the pair standing by the Records exit: the engineer at
## (830, 410) and WOLF at (766, 423), world px.
static func completed_records_state(choice_id: String) -> M0State:
	var state: M0State = story_state(choice_id, Story.RECORDS_DONE)
	state.human_position = Vector2(830.0, 410.0)
	state.wolf_position = Vector2(766.0, 423.0)
	return state


## A sentry brain already awake and on patrol at [param x] (world px), facing [param facing] (1 right,
## -1 left).
static func patrolling_sentry(x: float, facing: float) -> SentryBrain:
	var brain: SentryBrain = SentryBrain.new()
	brain.wake()
	brain.x = x
	brain.facing = facing
	return brain


## Deletes the user:// (or absolute) file at [param path] if there is one.
static func remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## The z index [param item] is drawn at: its own z_index plus each parent's, up the chain of
## CanvasItems while each one is relative to its parent. A plain Node between them ends the chain.
static func drawn_z(item: CanvasItem) -> int:
	var z: int = 0
	var node: Node = item
	while node is CanvasItem:
		z += (node as CanvasItem).z_index
		if not (node as CanvasItem).z_as_relative:
			break
		node = node.get_parent()
	return z


## [param texture]'s pixels as an Image that get_pixel can read: imported textures may be stored
## compressed (VRAM formats), which get_pixel cannot read, so a compressed copy is decompressed.
## Each call reads the texture again; a suite that samples one texture often keeps the result.
static func texture_image(texture: Texture2D) -> Image:
	var image: Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	return image


## RETRY on the knockdown card (Q17): waits until the card takes it (Main.RETRY_READY_SECONDS after the
## hit), presses interact once, and waits until the room has faded back in with the controls back.
## [param game] is the running game; [param max_frames] bounds each of the two waits, in physics
## frames. Returns false when the card never takes RETRY or the room never comes back in time.
## The press is held for exactly one process frame, the way a tap reaches the game. Users: the suites
## that knock the engineer down (approved_wording, debug_tools, impact, junction, sentry).
static func retry(game: Node, max_frames: int) -> bool:
	if not await wait_until(func() -> bool: return bool(game.call("_retry_ready")), max_frames):
		return false
	await tree().process_frame
	Input.action_press(&"interact")
	await tree().process_frame
	Input.action_release(&"interact")
	return await wait_until(func() -> bool: return not bool(game.get("fail_active")) and not bool(game.get("retry_fading_in")), max_frames)


## The "#." notes of every message in the committed translation template (i18n/messages.pot, at the
## repository root beside apps/game; CI regenerates it and fails when it differs from the source), by
## msgid (msgctxt ignored), joined into one string per message; empty when the file cannot be read, as in
## an exported build. Reads only the parts of a PO file Godot's generator writes (comments, msgctxt, msgid
## and its continued strings). Users: i18n_test (the story's marks) and companion_rules_test (WOLF's
## lines, by their speaker=WOLF mark).
static func template_notes() -> Dictionary:
	var path: String = ProjectSettings.globalize_path("res://").path_join("../../i18n/messages.pot").simplify_path()
	var notes: Dictionary = {}
	for block: String in FileAccess.get_file_as_string(path).split("\n\n"):
		var comments: PackedStringArray = []
		var msgid: String = ""
		var in_msgid: bool = false
		for line: String in block.split("\n"):
			if line.begins_with("#."):
				comments.append(line)
			elif line.begins_with("msgid "):
				msgid = str(JSON.parse_string(line.substr(6)))
				in_msgid = true
			elif line.begins_with("\"") and in_msgid:
				msgid += str(JSON.parse_string(line))
			else:
				in_msgid = false
		if not msgid.is_empty():
			notes[msgid] = String(notes.get(msgid, "")) + "\n".join(comments) + "\n"
	return notes


## The "i18n:" marks in [param notes] (one message's "#." lines from [method template_notes]) as key to
## value, as scripts/i18n/i18n_tool.py reads them (MARKS): "engineer=you slot=choice keep-breaks" gives
## {engineer: you, slot: choice, keep-breaks: ""}.
static func template_marks(notes: String) -> Dictionary:
	var found: Dictionary = {}
	for line: String in notes.split("\n"):
		var at: int = line.find("i18n:")
		if at < 0:
			continue
		for word: String in line.substr(at + 5).split(" ", false):
			found[word.get_slice("=", 0)] = word.get_slice("=", 1) if word.contains("=") else ""
	return found
