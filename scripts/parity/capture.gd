extends SceneTree
## Parity capture driver for the behaviour-identical refactor steps (never shipped: it lives outside
## res://, and run.sh hands it to tools/render/render.sh, which copies it into the render container's
## project copy as res://review_capture/). It plays one route through input actions and button
## presses, on fixed frame counts and fixed waits, and takes the same stills at the same moments on
## every run, so a refactor can be compared pixel for pixel. No window opens on the host.
##
## Determinism: run with --fixed-fps 60; each room's lamp flicker gets a fixed seed and restarts,
## and every CPUParticles2D that enters the tree is given a fixed seed. The container's virtual screen
## has no other input. Each still checks that a new frame was drawn first and that the renderer drew
## something in it (draw calls above 0), so a stalled renderer fails the run instead of recording
## stale frames. (Equal draw-call counts on consecutive stills are normal on a still screen, so the
## count itself is not required to change.)
##
## Every route takes controller-prompt stills, and R2-R4 switch input devices mid-play at a station
## (keyboard or touch, then a controller, then a screen touch, then a key) and fail the run unless
## the context hint changes to the controller prompts and back, and in the touch run the USE button
## hides and returns.
##
## Writes into --out: NNN-slug.png stills, shots.json (per still: frame, draw calls, texture memory,
## masks), text.log (every change of the narration, hints, objective, cards and buttons, by frame)
## and audio.log (every SfxBank play, play_blend and stop, by frame).
##
## Usage (inside render.sh): godot --fixed-fps 60 --script res://review_capture/capture.gd --
##        --route=R1|R2|R3|R4 --out=/work/out --size=1280x720 --variant=kb-fx|kb-calm|touch-fx

const ParityBank = preload("parity_sfx_bank.gd")
const RNG_SEED: int = 0x5041524954
const PARTICLE_SEED: int = 1337
const TEXT_PATHS: Array[String] = [
	"CanvasLayer/TopBar/HUD",
	"CanvasLayer/BottomBar/Speaker",
	"CanvasLayer/BottomBar/Story",
	"CanvasLayer/ContextHint/Text",
	"CanvasLayer/TutorialPrompt/Text",
	"CanvasLayer/TouchControls/Use",
	"CanvasLayer/TouchControls/Choice1",
	"CanvasLayer/TouchControls/Choice2",
	"CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton",
	"CanvasLayer/PauseOverlay/Panel/PauseMenu/PauseHint",
	"CanvasLayer/TitleScreen/ContinueButton",
	"CanvasLayer/TitleScreen/ContinueNote",
]

var route: String = "R1"
var variant: String = "kb-fx"
var out_dir: String = ""
var size: Vector2i = Vector2i(1280, 720)
var save_path: String = ""
var settings_path: String = ""
var game: Node2D
var human: M0Actor
var wolf: M0Actor
var shots: Array = []
var notes: Array = []
var text_log: PackedStringArray = []
var last_text: Dictionary = {}
var frame: int = 0
var last_drawn: int = -1
var failed: bool = false


## Counts frames and samples the on-screen text after Main has run (process priority 1000).
class Probe:
	extends Node
	var driver: Object

	func _process(_delta: float) -> void:
		driver.call("_sample")


func _initialize() -> void:
	call_deferred("_run")


func _arg(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


func _run() -> void:
	route = _arg("route", "R1")
	variant = _arg("variant", "kb-fx")
	out_dir = _arg("out", OS.get_user_data_dir().path_join("parity"))
	var dims: PackedStringArray = _arg("size", "1280x720").split("x")
	size = Vector2i(int(dims[0]), int(dims[1]))
	DirAccess.make_dir_recursive_absolute(out_dir)
	save_path = "user://parity-%s-save.json" % route
	settings_path = "user://parity-%s-settings.cfg" % route
	for path: String in [save_path, save_path + ".tmp", settings_path]:
		_remove(path)
	# Fast, unthrottled frames (the game reads its limiter from Settings); Reduced Motion for kb-calm.
	var config: ConfigFile = ConfigFile.new()
	config.set_value("video", "fps_limit", 0)
	config.set_value("video", "vsync", false)
	config.set_value("video", "reduced_motion", variant == "kb-calm")
	config.save(settings_path)
	if route == "R3":
		_write_save(_records_entry_state())
	elif route == "R4":
		_write_save(_junction_entry_state())
	node_added.connect(_on_node_added)
	var scene: PackedScene = load("res://scenes/main.tscn") as PackedScene
	game = scene.instantiate() as Node2D
	game.set("save_path", save_path)
	game.set("settings_path", settings_path)
	game.set("auto_pause_on_focus_loss", false)
	game.set("effects_enabled", variant != "kb-calm")
	game.set("touch_enabled", variant == "touch-fx")
	root.add_child(game)
	human = game.get_node("Human") as M0Actor
	wolf = game.get_node("Wolf") as M0Actor
	_seed_room_lights()
	var probe: Probe = Probe.new()
	probe.driver = self
	probe.process_priority = 1000
	probe.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(probe)
	await _raw(2)
	_set_size(size)
	await _raw(60)
	match route:
		"R1":
			await _route_1()
		"R2":
			await _route_2()
		"R3":
			await _route_3()
		"R4":
			await _route_4()
		_:
			notes.append("unknown route %s" % route)
	_finish()


func _finish() -> void:
	var f: FileAccess = FileAccess.open(out_dir.path_join("shots.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"route": route, "variant": variant, "size": [size.x, size.y], "frames": frame, "joypads": Input.get_connected_joypads().size(), "notes": notes, "failed": failed, "shots": shots}, " "))
	f.close()
	f = FileAccess.open(out_dir.path_join("text.log"), FileAccess.WRITE)
	f.store_string("\n".join(text_log) + "\n")
	f.close()
	f = FileAccess.open(out_dir.path_join("audio.log"), FileAccess.WRITE)
	f.store_string("\n".join(ParityBank.calls) + "\n")
	f.close()
	ParityBank.calls.clear()
	for path: String in [save_path, save_path + ".tmp", settings_path]:
		_remove(path)
	print("parity done route=%s variant=%s size=%dx%d shots=%d frames=%d failed=%s notes=%s" % [route, variant, size.x, size.y, shots.size(), frame, failed, notes])
	quit(1 if failed else 0)


# ---------------------------------------------------------------- determinism

func _on_node_added(node: Node) -> void:
	if node is CPUParticles2D:
		(node as CPUParticles2D).use_fixed_seed = true
		(node as CPUParticles2D).seed = PARTICLE_SEED
	elif node is SfxBank and node.get_script() != ParityBank:
		# Swap in the logging subclass before the bank's own _ready runs.
		node.set_script(ParityBank)


## The rooms' lamp flicker draws from a randomized generator: seed it and restart the light motion.
func _seed_room_lights() -> void:
	var index: int = 0
	for depth: Node in game.find_children("*", "RoomDepth", true, false):
		var rng: RandomNumberGenerator = depth.get("_rng") as RandomNumberGenerator
		if rng == null:
			notes.append("RoomDepth %s has no _rng to seed" % depth.name)
			failed = true
			continue
		rng.seed = RNG_SEED + index
		index += 1
		depth.call("_stop_motion")
		depth.call("_sync_motion")
	ParityBank.frame = 0


## Runs every frame after Main: counts the frame and logs every change of what the player can read.
func _sample() -> void:
	frame += 1
	ParityBank.frame = frame
	if game == null:
		return
	var now: Dictionary = {
		"status_line": str(game.get("status_line")),
		"context_hint()": str(game.call("_context_hint")) if not bool(game.get("title_open")) else "",
		"objective()": str(game.call("_objective")),
	}
	for path: String in TEXT_PATHS:
		var node: Control = game.get_node(path) as Control
		var text: String = (node as Label).text if node is Label else (node as Button).text
		now[path.trim_prefix("CanvasLayer/")] = ("" if node.is_visible_in_tree() else "(hidden) ") + text
	for key: String in now:
		if now[key] != last_text.get(key):
			text_log.append("%d\t%s\t%s" % [frame, key, str(now[key]).c_escape()])
	last_text = now


# ---------------------------------------------------------------- routes

## R1: title and menus. Title reveal, Credits (top and part-scrolled), Changelog (top and scrolled),
## Settings (three tabs, a rebind prompt and the saved binding), controller prompts on the title,
## Pause during the opening (SKIP OPENING), Pause and its Settings in play, the rebound key in a hint,
## the title's Continue note with a save present, Continue, and the END OF SLICE card.
func _route_1() -> void:
	await _shot("title")
	_press("CanvasLayer/TitleScreen/CreditsButton")
	await _raw(2)
	_press("CanvasLayer/TitleScreen/CreditsScreen/CreditsPauseButton")
	await _raw(40)
	await _shot("credits-top")
	_press("CanvasLayer/TitleScreen/CreditsScreen/CreditsPauseButton")
	await _raw(400)
	await _shot("credits-scrolled")
	_press("CanvasLayer/TitleScreen/CreditsScreen/CreditsBackButton")
	await _raw(30)
	_press("CanvasLayer/TitleScreen/ChangelogButton")
	await _raw(40)
	await _shot("changelog-top")
	Input.action_press(&"ui_down")
	await _raw(90)
	Input.action_release(&"ui_down")
	await _raw(10)
	await _shot("changelog-scrolled")
	_press("CanvasLayer/TitleScreen/ChangelogScreen/ChangelogBackButton")
	await _raw(30)
	await _controller_shot("title-controller")
	_press("CanvasLayer/TitleScreen/SettingsButton")
	await _raw(40)
	await _shot("settings-display")
	var menu: GameSettings = game.get("settings_menu") as GameSettings
	menu.tabs.current_tab = 1
	await _raw(20)
	await _shot("settings-audio")
	menu.tabs.current_tab = 2
	await _raw(20)
	await _shot("settings-controls")
	(menu.binding_buttons["interact_keyboard"] as Button).pressed.emit()
	await _raw(10)
	await _shot("settings-rebind-prompt")
	await _key(KEY_F)
	await _raw(10)
	await _shot("settings-rebind-saved")
	_press("CanvasLayer/PauseOverlay/Panel/SettingsMenu/BackButton")
	await _raw(30)
	_press("CanvasLayer/TitleScreen/NewGameButton")
	await _raw(50)
	await _action_event(&"pause_game")
	await _raw(40)
	await _shot("pause-opening")
	_press("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton")
	await _raw(60)
	await _shot("opening-skipped")
	await _walk_to(350.0)
	await _raw(30)
	await _shot("hint-rebound-key")
	if variant != "touch-fx" and not _hint().begins_with("F"):
		_fail("the rebound USE key (F) is not in the hint: %s" % _hint())
	await _action_event(&"pause_game")
	await _raw(40)
	await _shot("pause-play")
	_press("CanvasLayer/PauseOverlay/Panel/PauseMenu/SettingsButton")
	await _raw(40)
	await _shot("pause-settings")
	_press("CanvasLayer/PauseOverlay/Panel/SettingsMenu/BackButton")
	await _raw(30)
	await _shot("pause-after-settings")
	_write_save(_safe_point_state())
	_press("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton")
	await _raw(60)
	await _shot("title-with-save")
	_press("CanvasLayer/TitleScreen/ContinueButton")
	await _raw(60)
	await _shot("continued-safe-point")
	game.call("debug_show_end_card")
	await _raw(60)
	await _shot("end-card")
	await _tap(&"interact")
	await _raw(60)
	await _shot("title-after-end-card")


## R2: the corridor. The opening beat by beat, first control (and Pause while the objective card
## slides in), a camera pan, the breaker (with a device switch), the relay question (resized, and with
## controller prompts),
## then the three outcomes: disclose and signal WOLF (the seal at 0, mid and open, the safe point and
## the cut to Records), press and the manual bypass (released part way), and disclose with the bypass.
func _route_2() -> void:
	_press("CanvasLayer/TitleScreen/NewGameButton")
	await _raw(50)
	await _shot("opening-0")
	for beat: int in range(1, 7):
		await _tap(&"interact")
		await _raw(45)
		await _shot("opening-%d" % beat)
	await _tap(&"interact")
	await _raw(30)
	await _shot("opening-fade")
	await _raw(12)
	await _action_event(&"pause_game")
	await _raw(60)
	await _shot("paused-during-card")
	_press("CanvasLayer/PauseOverlay/Panel/PauseMenu/ResumeButton")
	await _raw(40)
	await _shot("first-control")
	Input.action_press(&"move_right")
	await _burst("pan", 6, 3)
	Input.action_release(&"move_right")
	await _walk_to(350.0)
	await _raw(30)
	await _shot("at-breaker")
	await _device_switch("breaker")
	await _tap(&"interact")
	await _raw(30)
	if not game.get("waiting_for_choice"):
		await _shot("breaker-stakes")
		await _tap(&"interact")
		await _raw(30)
	await _shot("relay-question")
	_set_size(Vector2i(size.x * 3 / 4, size.y * 3 / 4))
	await _raw(20)
	await _shot("relay-question-resized")
	_set_size(size)
	await _raw(20)
	await _shot("relay-question-restored")
	await _controller_shot("relay-question-controller")
	await _answer(1)
	await _raw(40)
	await _shot("disclosed")
	await _tap(&"interact")
	await _raw(30)
	await _shot("breaker-armed")
	await _walk_to(605.0)
	await _raw(40)
	await _shot("at-relay")
	await _tap(&"interact")
	await _raw(8)
	await _shot("wolf-signalled")
	if not await _wait_until(func() -> bool: return (game.get("state") as M0State).door_open, 400):
		_fail("the seal never opened (cooperate)")
	await _shot("seal-0")
	await _raw(26)
	await _shot("seal-mid")
	await _wait_until(func() -> bool: return not game.get("seal_opening"), 200)
	await _raw(30)
	await _shot("seal-open")
	_set_size(Vector2i(size.x * 3 / 4, size.y * 3 / 4))
	await _raw(20)
	await _shot("play-resized")
	_set_size(size)
	await _raw(20)
	await _walk_to(876.0)
	await _raw(10)
	await _tap(&"interact")
	await _raw(50)
	await _shot("safe-point")
	await _tap(&"interact")
	await _burst("records-cut", 5, 1)
	await _raw(60)
	await _shot("records-entry")
	# Outcome 2: press, WOLF refuses, the manual bypass let go part way, then finished.
	await _new_run_skipping_opening()
	await _walk_to(350.0)
	await _breaker_choice(2)
	await _walk_to(605.0)
	await _raw(40)
	await _shot("relay-refused")
	await _tap(&"interact")
	await _raw(20)
	await _tap(&"interact")
	await _raw(20)
	await _shot("relay-refusal-repeated")
	await _crank_bypass("press")
	# Outcome 3: disclose, then crank the bypass without signalling WOLF.
	await _new_run_skipping_opening()
	await _walk_to(350.0)
	await _breaker_choice(1)
	await _crank_bypass("disclose")


## R3: Records from its entry save. The purge copy (with a device switch at the purge queue), the
## mirror question (also with controller prompts) and WOLF's readout, the copy,
## Continue from a save just after the purge copy, the question again and the manual answer, the
## exit lift, the chapter close (paused while it frames) and the cut to the junction.
func _route_3() -> void:
	await _shot("title-records-save")
	_press("CanvasLayer/TitleScreen/ContinueButton")
	await _raw(60)
	await _shot("records-continued")
	await _walk_to(190.0)
	await _raw(40)
	await _shot("at-purge-queue")
	await _device_switch("purge-queue")
	await _tap(&"interact")
	await _raw(40)
	await _shot("purge-copied")
	await _walk_to(520.0)
	await _wait_until(func() -> bool: return absf(wolf.position.x - float(game.get_script().get_script_constant_map()["WOLF_MIRROR_X"])) <= 6.0, 300)
	await _raw(10)
	await _tap(&"interact")
	await _raw(30)
	await _shot("mirror-question")
	await _controller_shot("mirror-question-controller")
	await _answer(1)
	await _raw(40)
	await _shot("mirror-wolf-readout")
	await _raw(90)
	await _shot("mirror-wolf-settled")
	# Back to a save from just after the purge copy (the WOLF answer saved over the game's own), and
	# the other answer.
	await _action_event(&"pause_game")
	await _raw(30)
	_write_save(_after_purge_state())
	_press("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton")
	await _raw(40)
	_press("CanvasLayer/TitleScreen/ContinueButton")
	await _raw(60)
	await _shot("continued-after-purge")
	await _walk_to(520.0)
	await _wait_until(func() -> bool: return absf(wolf.position.x - float(game.get_script().get_script_constant_map()["WOLF_MIRROR_X"])) <= 6.0, 300)
	await _raw(10)
	await _tap(&"interact")
	await _raw(30)
	await _shot("mirror-question-again")
	await _answer(2)
	await _raw(40)
	await _shot("mirror-manual")
	await _raw(60)
	await _shot("mirror-copied")
	await _walk_to(830.0)
	await _raw(20)
	await _shot("at-exit-lift")
	await _tap(&"interact")
	await _raw(30)
	await _shot("exit-lift-used")
	await _raw(60)
	await _tap(&"interact")
	await _raw(20)
	await _shot("chapter-close-framing")
	await _action_event(&"pause_game")
	await _raw(60)
	await _shot("chapter-close-paused")
	_press("CanvasLayer/PauseOverlay/Panel/PauseMenu/ResumeButton")
	await _raw(40)
	await _shot("chapter-close-settled")
	await _tap(&"interact")
	await _burst("junction-cut", 5, 1)
	await _wait_until(func() -> bool: return (game.get("state") as M0State).chapter_id == "junction" and not game.get("wolf_scouting"), 400)
	await _raw(40)
	await _shot("junction-entry")


## R4: the junction from its entry save to the end. The vent knockdown (paused mid-fall) and the
## restore, the breaker and the line, a device switch at the valve, the crank, the fuse (32 consecutive
## frames) and the blast as frame sequences, the lane question (also with controller prompts), WOLF
## drawing the sentry, the tank drop (30 consecutive frames), the bolt, the hatch, the walk
## out and the END OF SLICE card; then Continue from the post-blast save, the engineer alone, the
## sentry's chase and its knockdown.
func _route_4() -> void:
	_press("CanvasLayer/TitleScreen/ContinueButton")
	await _raw(80)
	await _shot("junction-continued")
	await _walk_to(JunctionRoom.BREAKER_X)
	await _raw(30)
	await _shot("at-breaker")
	await _tap(&"interact")
	await _raw(20)
	await _shot("line-building")
	await _walk_to(300.0)
	await _shot("on-vent")
	if not await _wait_until(func() -> bool: return bool(game.get("fail_active")), 600):
		_fail("the vent never knocked the engineer down")
	await _burst("vent-knockdown", 6, 2)
	await _action_event(&"pause_game")
	await _raw(60)
	await _shot("vent-knockdown-paused")
	_press("CanvasLayer/PauseOverlay/Panel/PauseMenu/ResumeButton")
	await _raw(20)
	await _shot("vent-knockdown-card")
	await _wait_until(func() -> bool: return not game.get("fail_active"), 300)
	await _raw(40)
	await _shot("vent-restored")
	await _walk_to(JunctionRoom.BREAKER_X)
	await _tap(&"interact")
	await _raw(10)
	await _walk_to(JunctionRoom.VALVE_X)
	await _raw(10)
	await _shot("at-valve")
	await _device_switch("valve")
	Input.action_press(&"interact")
	await _raw(40)
	await _shot("valve-cranking")
	await _wait_until(func() -> bool: return (game.get("pressure_line") as PressureLine).state != &"building", 300)
	Input.action_release(&"interact")
	await _raw(2)
	await _shot("valve-charged")
	await _walk_to(PressureLine.BLAST_MIN_X - 16.0)
	await _burst("fuse", 32, 1)
	if not await _wait_until(func() -> bool: return (game.get("state") as M0State).door_blown or bool(game.get("fail_active")), 200):
		_fail("the door never blew")
	await _burst("blast", 8, 2)
	await _raw(90)
	await _shot("after-blast")
	await _walk_to(600.0)
	await _raw(10)
	await _shot("lane-question")
	await _controller_shot("lane-question-controller")
	await _answer(1)
	await _raw(30)
	await _shot("wolf-draws-sentry")
	if not await _wait_until(func() -> bool: return (game.get("sentry_brain") as SentryBrain).state == &"fixated" and absf((game.get("sentry_brain") as SentryBrain).x - DropArm.MARK_X) < 1.0 and absf(wolf.position.x - JunctionRoom.WOLF_BAIT_X) < 4.0, 900):
		_fail("WOLF never held the sentry on the mark")
	await _raw(10)
	await _shot("sentry-fixated")
	await _walk_to(JunctionRoom.ARM_X)
	await _raw(30)
	await _shot("at-tank-release")
	await _tap(&"interact")
	await _burst("tank-drop", 30, 1)
	await _raw(60)
	await _shot("sentry-down")
	await _walk_to(JunctionRoom.BOLT_PANEL_X)
	await _raw(40)
	await _shot("at-exit-bolt")
	await _tap(&"interact")
	await _raw(6)
	await _shot("hatch-sliding")
	await _wait_until(func() -> bool: return (game.get("junction_room") as JunctionRoom).hatch_open >= 1.0, 200)
	await _raw(10)
	await _shot("hatch-open")
	await _tap(&"interact")
	await _raw(100)
	await _shot("closing-beat")
	await _tap(&"interact")
	await _burst("walk-out", 8, 8)
	if not await _wait_until(func() -> bool: return bool(game.get("end_card_active")), 300):
		_fail("the END OF SLICE card never showed")
	await _raw(40)
	await _shot("end-card")
	await _tap(&"interact")
	await _raw(40)
	await _shot("title-after-end")
	# The engineer alone, from the post-blast save: the sentry sees them and gives chase.
	_write_save(_after_blast_state())
	_press("CanvasLayer/TitleScreen/ContinueButton")
	await _raw(80)
	await _shot("continued-after-blast")
	await _walk_to(600.0)
	await _raw(10)
	await _answer(2)
	await _raw(40)
	await _shot("engineer-alone")
	await _wait_until(_sentry_walking_back, 900)
	await _shot("sentry-patrol")
	await _walk_to(640.0, false)
	await _wait_until(func() -> bool: return (game.get("sentry_brain") as SentryBrain).state == &"chase" or bool(game.get("fail_active")), 300)
	await _shot("sentry-chase")
	if not await _wait_until(func() -> bool: return bool(game.get("fail_active")), 400):
		_fail("the sentry never knocked the engineer down")
	await _raw(20)
	await _shot("sentry-knockdown")
	await _wait_until(func() -> bool: return not game.get("fail_active"), 300)
	await _raw(40)
	await _shot("sentry-restored")


# ---------------------------------------------------------------- route pieces

func _sentry_walking_back() -> bool:
	var b: SentryBrain = game.get("sentry_brain") as SentryBrain
	return b.state == &"patrol" and b.facing < 0.0 and b.x <= 780.0 and b.x >= 700.0


func _new_run_skipping_opening() -> void:
	await _action_event(&"pause_game")
	await _raw(30)
	_press("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton")
	await _raw(40)
	_press("CanvasLayer/TitleScreen/NewGameButton")
	await _raw(30)
	await _action_event(&"pause_game")
	await _raw(30)
	_press("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton")
	await _raw(50)


func _breaker_choice(response: int) -> void:
	await _tap(&"interact")
	await _raw(30)
	if not game.get("waiting_for_choice"):
		await _tap(&"interact")
		await _raw(30)
	await _answer(response)
	await _raw(40)
	await _tap(&"interact")
	await _raw(30)


func _crank_bypass(tag: String) -> void:
	await _walk_to(700.0)
	await _raw(10)
	await _shot("%s-at-bypass" % tag)
	await _tap(&"interact")
	await _raw(20)
	await _shot("%s-bypass-touched" % tag)
	Input.action_press(&"interact")
	await _wait_until(func() -> bool: return int(game.get("bypass_ticks")) >= 5, 200)
	Input.action_release(&"interact")
	await _raw(20)
	await _shot("%s-bypass-released" % tag)
	Input.action_press(&"interact")
	var opened: bool = await _wait_until(func() -> bool: return (game.get("state") as M0State).door_open, 400)
	Input.action_release(&"interact")
	if not opened:
		_fail("the seal never opened from the bypass (%s)" % tag)
	await _raw(2)
	await _shot("%s-bypass-payoff" % tag)
	await _wait_until(func() -> bool: return not game.get("seal_opening"), 200)
	await _raw(30)
	await _shot("%s-seal-open" % tag)


## Answers the open question: the key in the keyboard runs, the on-screen button in the touch run.
## A question that is not open fails the run, so a route cannot drift past its choice unnoticed.
func _answer(response: int) -> void:
	if not game.get("waiting_for_choice"):
		_fail("answer %d with no question open" % response)
		return
	if variant == "touch-fx":
		var button: Button = game.get_node("CanvasLayer/TouchControls/Choice%d" % response) as Button
		if not button.is_visible_in_tree():
			_fail("touch answer %d not on screen" % response)
		button.button_down.emit()
		await _raw(2)
		button.button_up.emit()
		await _raw(1)
	else:
		await _tap(&"choice_%d" % response)


## A still with controller prompts (a trigger pull), then back to keyboard (an unbound key).
func _controller_shot(slug: String) -> void:
	await _trigger_pull()
	await _raw(10)
	await _shot(slug)
	await _key(KEY_SHIFT)
	await _raw(10)


## Switches input device mid-play (critique C6): from the variant's own layout to a controller, then
## a screen touch, then a key, with a still after the first two. The context hint must change to the
## controller prompts and come back unchanged; in the touch run the USE button must hide for the
## controller and return for the touch. (The game has touch buttons only where touch_enabled is set,
## on phones; in the keyboard runs a screen touch brings back the keyboard prompts.)
func _device_switch(slug: String) -> void:
	var start: String = _hint()
	var use_button: Control = game.get_node("CanvasLayer/TouchControls/Use") as Control
	var use_shown: bool = use_button.is_visible_in_tree()
	if bool(game.get("controller_active")):
		_fail("%s: a controller was already active before the device switch" % slug)
	await _trigger_pull()
	await _raw(10)
	await _shot("%s-device-controller" % slug)
	if not bool(game.get("controller_active")) or _hint() == start:
		_fail("%s: the hint kept its %s prompts after a controller input (%s)" % [slug, variant, _hint()])
	if use_shown and use_button.is_visible_in_tree():
		_fail("%s: the touch USE button stayed on screen with a controller" % slug)
	await _screen_touch()
	await _raw(10)
	await _shot("%s-device-touch" % slug)
	if bool(game.get("controller_active")) or _hint() != start:
		_fail("%s: after a screen touch the hint reads %s, not %s" % [slug, _hint(), start])
	if use_button.is_visible_in_tree() != use_shown:
		_fail("%s: the touch USE button did not return after a screen touch" % slug)
	await _key(KEY_SHIFT)
	await _raw(10)
	if _hint() != start:
		_fail("%s: after a key the hint reads %s, not %s" % [slug, _hint(), start])


func _hint() -> String:
	return (game.get_node("CanvasLayer/ContextHint/Text") as Label).text


## A left-trigger pull and release (the trigger is bound to no action, so it only switches prompts).
func _trigger_pull() -> void:
	for value: float in [1.0, 0.0]:
		var ev: InputEventJoypadMotion = InputEventJoypadMotion.new()
		ev.axis = JOY_AXIS_TRIGGER_LEFT
		ev.axis_value = value
		Input.parse_input_event(ev)
		await _raw(2)


## A tap in the empty upper middle of the view, clear of the HUD and the touch buttons.
func _screen_touch() -> void:
	for pressed: bool in [true, false]:
		var ev: InputEventScreenTouch = InputEventScreenTouch.new()
		ev.index = 0
		ev.position = Vector2(root.size) * Vector2(0.5, 0.35)
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _raw(1)


# ---------------------------------------------------------------- saves for R1, R3 and R4

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


func _after_purge_state() -> M0State:
	var st: M0State = _records_entry_state()
	st.preserve_purge_trace()
	st.human_position = Vector2(140.0, 410.0)
	st.wolf_position = Vector2(100.0, 423.0)
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


func _write_save(st: M0State) -> void:
	if not st.save_to_disk(save_path):
		_fail("could not write the fixture save")


# ---------------------------------------------------------------- input and capture helpers

func _press(path: String) -> void:
	var b: Button = game.get_node(path) as Button
	if b.disabled or not b.is_visible_in_tree():
		_fail("button %s not usable (disabled=%s visible=%s)" % [path, b.disabled, b.is_visible_in_tree()])
		return
	b.pressed.emit()


func _action_event(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var ev: InputEventAction = InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _raw(1)


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var ev: InputEventKey = InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _raw(1)


func _tap(action: StringName) -> void:
	await _raw(1)
	Input.action_press(action)
	await _raw(1)
	Input.action_release(action)
	await _raw(1)


func _walk_to(target_x: float, must_arrive: bool = true) -> bool:
	var dir: float = signf(target_x - human.position.x)
	if absf(target_x - human.position.x) <= 6.0:
		return true
	var action: StringName = &"move_right" if dir > 0.0 else &"move_left"
	Input.action_press(action)
	var reached: bool = false
	for _i: int in range(900):
		await _raw(1)
		if (target_x - human.position.x) * dir <= 3.0:
			reached = true
			break
		if not human.controlled and not game.get("engineer_waits_for_wolf"):
			break
	Input.action_release(action)
	await _raw(1)
	if not reached and must_arrive and not game.get("waiting_for_choice"):
		notes.append("walk to %.0f stopped at %.1f" % [target_x, human.position.x])
	return reached


func _wait_until(cond: Callable, max_frames: int) -> bool:
	for _i: int in range(max_frames):
		if cond.call():
			return true
		await _raw(1)
	return bool(cond.call())


func _raw(frames: int) -> void:
	for _i: int in range(frames):
		await process_frame


## The game sizes its own window at start-up (from Settings), so the driver sets it after that.
func _set_size(want: Vector2i) -> void:
	root.size = want


func _burst(slug: String, count: int, every: int) -> void:
	for i: int in range(count):
		await _shot("%s-%02d" % [slug, i])
		await _raw(maxi(every - 1, 0))


func _fail(why: String) -> void:
	failed = true
	notes.append("FAIL: " + why)
	push_error("parity: " + why)


func _shot(slug: String) -> void:
	await RenderingServer.frame_post_draw
	var drawn: int = Engine.get_frames_drawn()
	if drawn <= last_drawn:
		_fail("no new frame was drawn before %s (frames drawn %d)" % [slug, drawn])
	last_drawn = drawn
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if draw_calls <= 0:
		_fail("the renderer drew nothing before %s (0 draw calls)" % slug)
	var img: Image = root.get_texture().get_image()
	var file: String = "%03d-%s.png" % [shots.size() + 1, slug]
	img.save_png(out_dir.path_join(file))
	shots.append({
		"file": file,
		"frame": frame,
		"image": [img.get_width(), img.get_height()],
		"draw_calls": draw_calls,
		"objects": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"texture_mem_mb": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.01),
		"chapter": str((game.get("state") as M0State).chapter_id),
		"engineer_x": snappedf(human.position.x, 0.01),
		"wolf_x": snappedf(wolf.position.x, 0.01),
		"masks": [],
	})
	# frame_post_draw resumes after this frame's _process: start the next step at a frame boundary.
	await process_frame


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
