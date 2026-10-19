extends "res://tests/support/game_suite.gd"
## A fast reader's opening (the codex/opening-dock backup's round-4 test, carried to the whole-piece
## dock bay): pressing CONTINUE every PRESS_GAP seconds moves the captions on at once, but no beat is
## snapped to its end. The actions still play whole and in order (the engineer arrives, WOLF wakes,
## gets up, tears the lock, the leaves coast open for their full time, he steps out, then walks to the
## doorway), each after the one before it, and the last press still hands over to play.

## Seconds between presses: faster than any box can be read.
const PRESS_GAP: float = 0.3


func _run() -> void:
	check_name = "Opening early press"
	var game: Node2D = await start_game("opening-early-press-test", keep_running)
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	var bay: DockBay = game.get("dock_bay") as DockBay
	game.call("_new_game")
	var clock: float = 0.0
	var next_press: float = PRESS_GAP
	var arrived_t: float = -1.0
	var wake_t: float = -1.0
	var rise_t: float = -1.0
	var tear_t: float = -1.0
	var open_t: float = -1.0
	var walk_t: float = -1.0
	var presses: int = 0
	while clock < 20.0 and game.get("intro_active"):
		await physics_frame
		clock += 1.0 / 60.0
		# The last press (the fade into play) waits until every action has played, as a reader would see
		# the last box's action before going on; every earlier press comes at once.
		var last: bool = int(game.get("intro_step")) >= int(Main.INTRO_LINES.size()) - 1
		if clock >= next_press and (not last or walk_t > 0.0 and absf(wolf.position.x - Opening.WOLF_DOORWAY_X) < 1.0):
			await tap(&"interact")
			presses += 1
			next_press = clock + PRESS_GAP
		if arrived_t < 0.0 and human.visible and absf(human.position.x - Opening.ENGINEER_WATCH_X) < 0.5:
			arrived_t = clock
		if wake_t < 0.0 and bay.charge_color != DockBay.AMBER:
			wake_t = clock
		if rise_t < 0.0 and wolf.body_sprite.texture == DockBay.WOLF_RISE:
			rise_t = clock
		if tear_t < 0.0 and bay.lock_torn:
			tear_t = clock
		if open_t < 0.0 and absf(bay.lead_travel - DockBay.lead_open_travel()) < 0.01:
			open_t = clock
		if walk_t < 0.0 and wolf.autonomous_target_x == Opening.WOLF_DOORWAY_X:
			walk_t = clock
	_expect(wake_t > 0.0 and rise_t > wake_t and tear_t > rise_t and open_t > tear_t and walk_t > open_t, "the actions play in order: wake %.2f, rise %.2f, tear %.2f, open %.2f, walk %.2f" % [wake_t, rise_t, tear_t, open_t, walk_t])
	_expect(wake_t - Opening.WAKE_DELAY >= -0.02 and rise_t - wake_t >= Opening.WAKE_S - 0.02, "the wake plays whole before WOLF gets up")
	_expect(open_t - tear_t >= DockBay.leaf_seconds() - 0.05, "the leaves coast open for their full %.2f s, never snapped (%.2f s)" % [DockBay.leaf_seconds(), open_t - tear_t])
	_expect(arrived_t > 0.0, "the engineer still walks in and stops in the doorway")
	_expect(not game.get("intro_active") and await wait_until(func() -> bool: return human.controlled, 120), "the last press hands over to play (%d presses)" % presses)
	await end_game(game)
	finish("Opening early press checks passed")
