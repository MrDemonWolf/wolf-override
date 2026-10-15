extends SceneTree
## The shared kit for the headless suites (scripts/check-game.sh runs every tests/*_test.gd as
## `godot --headless --script`). AGENTS.md's "Don't duplicate code" rule: the bookkeeping, game
## spawn and teardown, waits, holds and image helpers that suites used to copy into themselves live
## here once.
##
## Two ways to use it:
## - A suite that is a plain SceneTree script extends it: `extends "res://tests/support/game_suite.gd"`,
##   sets [member check_name] (the start of every failure message), reports with [method _expect] and
##   ends with [method finish]. It must not declare its own `failures`: redeclaring a parent member is
##   a parse error. It uses [constant MAIN_SCENE] instead of its own scene preload.
## - A suite that keeps `extends SceneTree` calls the statics through
##   `const Suite = preload("res://tests/support/game_suite.gd")`, on its own line right after the
##   file's last top-level preload.
##
## The file has no class_name, so nothing test-only enters the game's global class list, and it
## never ships: export_presets.cfg excludes tests/*, which covers tests/support/. check-game.sh only
## globs tests/*_test.gd, so it is never run as a suite itself.
##
## Users (2026-10-15): follow_spacing_test (drawn_z); on the corridor, doors and text branches their
## suites as each branch's dedupe lists them. What must stay true for every user: the statics touch
## nothing but their arguments and the running SceneTree, waits count physics frames (1/60 s of game
## time each at the project's physics rate, never the wall clock, so a busy machine slows a suite
## down but does not change what it sees), and end_game leaves no game, sound or file behind, because
## check-game fails a suite that leaks objects at exit.

## The game scene every suite plays.
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

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


## The running SceneTree (the suite itself), for the statics, which have no `self`.
static func tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## Adds a new game to the tree and returns it once it has run one process frame (its _ready done).
## [param save_path] and [param settings_path] are user:// files the game reads and writes instead
## of the player's own; [param configure], when given, is called with the game before it enters the
## tree (for properties its _ready reads, such as auto_pause_on_focus_loss). The caller frees it,
## normally with [method end_game].
static func spawn_game(save_path: String, settings_path: String, configure: Callable = Callable()) -> Node2D:
	var game: Node2D = MAIN_SCENE.instantiate() as Node2D
	game.set("save_path", save_path)
	game.set("settings_path", settings_path)
	if configure.is_valid():
		configure.call(game)
	tree().root.add_child(game)
	await tree().process_frame
	return game


## [method spawn_game] with this process's own files, user://<file_stem>-<pid>.json and
## <that>-settings.cfg (the process id keeps suites that run side by side apart), after removing any
## left from an earlier run that was stopped. [method end_game] removes them again.
static func start_game(file_stem: String, configure: Callable = Callable()) -> Node2D:
	var save_path: String = "user://%s-%s.json" % [file_stem, OS.get_process_id()]
	var settings_path: String = "%s-settings.cfg" % save_path
	remove_file(save_path)
	remove_file(settings_path)
	return await spawn_game(save_path, settings_path, configure)


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
