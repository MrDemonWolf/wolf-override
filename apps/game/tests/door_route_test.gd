extends "res://tests/support/game_suite.gd"
## The doors the route goes through after the corridor (whose door end m0_scene_test covers): the
## Records entry and exit, the Service Junction's blast door and its exit door. Each one stands across
## the walkway and stops the route while it is shut; once it opens, the route's x runs through its
## doorway; its leaf is drawn whole somewhere in every frame while its doorway is in use (it swings,
## slides or is thrown, and never hides or fades); the END OF SLICE card comes only once WOLF and then
## the engineer are through the exit; and no authored resting spot leaves an actor's drawn body across
## a door frame, other than standing in an open doorway behind its near jamb.
##
## It runs on the shared suite kit (tests/support/game_suite.gd) and counts frames, never the wall
## clock, so a busy machine slows the suite down but does not change what it sees:
## - each beat is bounded by BEAT_FRAMES physics frames (at normal speed, 1/60 s of game time each);
## - the loops that watch a beat sample every drawn frame (process_frame) inside that bound;
## - the blast is watched in slow motion (BLAST_TIME_SCALE) until the leaf lies in the lane;
## - the closing beat at the exit is sampled on a fixed count of drawn frames (see _check_exit_door).

## How many physics frames a beat may take before the test gives up on it: 15 s of game time at normal
## speed. In the blast's slow motion each physics frame is 1/600 s, so there the same cap is 1.5 s of
## game time, still about four times the break and the flight (DOOR_BREAK_SECONDS +
## DOOR_FLIGHT_SECONDS, 0.39 s).
const BEAT_FRAMES: int = 900
## How slow the game runs while the test watches the blast (Engine.time_scale), so that even a long
## frame on a busy machine samples the 0.24 s flight several times (the capture driver uses 0.05). The
## blast's own hit-stop (Impact.hit_stop, 70 ms of real time) would put time_scale back to 1.0 a moment
## later, so the test ends it first (Impact.end_hit_stop) and the slow motion then holds to the landing.
const BLAST_TIME_SCALE: float = 0.1
## Where each shut door's face crosses the walk line: a resting body must stay short of it. The
## doorways' spans themselves are the rooms' own (RecordsRoom.EXIT_SPAN and ENTRY_SPAN,
## JunctionRoom.EXIT_SPAN and EXIT_SHUT_SPAN), which wolf_space_test reads too.
const RECORDS_EXIT_FACE_X: float = RecordsRoom.EXIT_DOOR_X
const RECORDS_ENTRY_FACE_X: float = RecordsRoom.ENTRY_DOOR_X
const BLAST_FACE_X: float = M0State.JUNCTION_DOOR_LEFT_X
## The blast door's doorway on the deck, far jamb foot to the near column's far side (the column's foot,
## JunctionRoom.DOOR_FOOT_RIGHT_X).
const BLAST_SPAN: Vector2 = Vector2(JunctionDoorLayout.FAR_JAMB_FOOT.x, JunctionRoom.DOOR_FOOT_RIGHT_X)

var game: Node2D
var human: M0Actor
var wolf: M0Actor


func _initialize() -> void:
	check_name = "Door route"
	call_deferred("_run")


func _run() -> void:
	game = await start_game("door-route-test")
	human = game.get_node("Human") as M0Actor
	wolf = game.get_node("Wolf") as M0Actor
	game.call("debug_new_game", true)
	await frames(3)
	await _check_records()
	await _check_blast_door()
	await _check_exit_door()
	_check_rest_spots()
	await end_game(game)
	finish("Door route checks passed")


## Records Access: in through the entry, which closes behind them; the shut exit stops the engineer;
## the first copy opens it; they walk out through its doorway before the junction starts.
func _check_records() -> void:
	# The run as it enters Records (the debug presets: disclosed, WOLF powers the relay), with both
	# copies made, so the first copy can go into the container; enter_records() sets the arrival spots.
	var state: M0State = (game as Main).debug_tools.actions.build_state(&"records_entry")
	state.preserve_purge_trace()
	state.preserve_mirror_trace("wolf")
	game.set("state", state)
	game.call("_sync_scene")
	game.call("_start_gameplay_camera")
	await frames(2)
	var records: RecordsRoom = game.get("records_room") as RecordsRoom
	_expect(state.human_position.x > RecordsRoom.ENTRY_SPAN.y and state.wolf_position.x > RecordsRoom.ENTRY_SPAN.y, "both arrive in Records past the entry's doorway, having come through it")
	records.close_entry_behind()
	var entry_whole: bool = await _leaf_whole_while(records.entry_leaf, func() -> bool: return records.entry_tween != null and records.entry_tween.is_running())
	_expect(entry_whole and is_zero_approx(records.entry_leaf.open), "the entry closes behind them on its hinges, drawn whole every frame")
	# Shut, the exit stops the engineer short of its face.
	game.call("debug_place", 800.0, 700.0)
	await hold(&"move_right", 72)  # 1.2 s of game time
	_expect(human.position.x < RecordsRoom.EXIT_SPAN.x and records.exit_leaf.visible and is_zero_approx(records.exit_leaf.open), "the shut exit stops the route (engineer at x %.1f)" % human.position.x)
	# The first copy goes into the container; the exit swings open on its hinges.
	game.call("debug_place", 830.0, 700.0)
	game.call("debug_interact")
	_expect(state.chapter_complete and records.exit_swinging(), "securing the first copy starts the exit's swing")
	game.call("_finish_chapter_close")
	var exit_whole: bool = await _leaf_whole_while(records.exit_leaf, func() -> bool: return records.exit_swinging())
	_expect(exit_whole and is_equal_approx(records.exit_leaf.open, 1.0), "the exit swings fully open, drawn whole every frame")
	# USE at the open exit: the engineer walks out through the doorway before the junction starts.
	await wait_until(func() -> bool: return float(game.get("engineer_step_x")) < 0.0 and human.controlled, BEAT_FRAMES)
	game.call("debug_place", 830.0, 740.0)
	game.call("debug_interact")
	var furthest: float = human.position.x
	var wolf_furthest: float = wolf.position.x
	var leaf_whole: bool = true
	# Fix round 2: past the doorway they walk on the passage's floor, never off the floor's end.
	var floor_y: Vector2 = Vector2(human.position.y, wolf.position.y)
	var off_floor: float = 0.0
	var started: int = Engine.get_physics_frames()
	while state.chapter_id == "records" and Engine.get_physics_frames() - started < BEAT_FRAMES:
		furthest = maxf(furthest, human.position.x)
		wolf_furthest = maxf(wolf_furthest, wolf.position.x)
		off_floor = maxf(off_floor, maxf(absf(human.position.y - floor_y.x), absf(wolf.position.y - floor_y.y)))
		leaf_whole = leaf_whole and _whole(records.exit_leaf)
		await process_frame
	_expect(state.chapter_id == "junction", "walking out of Records leads into the Service Junction")
	_expect(furthest > RecordsRoom.EXIT_SPAN.y, "the engineer is through the exit's doorway (x %.1f past %.1f) before the junction starts" % [furthest, RecordsRoom.EXIT_SPAN.y])
	# Review r1: nobody is left behind by the cabinet; WOLF follows them through, his whole body past the
	# near column, before the junction starts.
	_expect(wolf_furthest - M0Actor.WOLF_REACH >= RecordsRoom.EXIT_SPAN.y - 0.5, "WOLF follows them through the exit's doorway (his tail at x %.1f past %.1f) before the junction starts" % [wolf_furthest - M0Actor.WOLF_REACH, RecordsRoom.EXIT_SPAN.y])
	_expect(leaf_whole, "the open exit leaf stays drawn whole while they walk through")
	_expect(off_floor <= 1.0, "both walk out of Records on the floor, never dropping off its end (at most %.1f px off it)" % off_floor)
	# In the junction they came in through its entry, which stands open behind them and closes on its
	# hinges (review r1, M5), drawn whole every frame.
	var junction: JunctionRoom = game.get("junction_room") as JunctionRoom
	_expect(junction.entry_leaf.open > 0.5 or (junction.entry_tween != null and junction.entry_tween.is_running()), "the junction's entry stands open behind them as they arrive")
	var jentry_whole: bool = await _leaf_whole_while(junction.entry_leaf, func() -> bool: return junction.entry_tween != null and junction.entry_tween.is_running())
	_expect(jentry_whole and is_zero_approx(junction.entry_leaf.open), "the junction's entry closes behind them on its hinges, drawn whole every frame")
	_expect(human.position.x - M0State.HUMAN_HALF_WIDTH > JunctionRoom.ENTRY_DOOR_X and wolf.position.x - M0State.WOLF_HALF_WIDTH > JunctionRoom.ENTRY_DOOR_X, "both arrive in the junction past its entry, having come through it")


## The blast door: shut, it stops the route; at the blast its leaf breaks and is then thrown into the
## lane, seen in the air on the way and drawn whole in every frame; afterwards the route runs through the
## empty doorway.
func _check_blast_door() -> void:
	var state: M0State = game.get("state") as M0State
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	await wait_until(func() -> bool: return human.controlled, BEAT_FRAMES)
	game.set("wolf_scouting", false)
	game.call("debug_place", 380.0, 200.0)
	await hold(&"move_right", 72)  # 1.2 s of game time
	_expect(human.position.x + M0State.HUMAN_HALF_WIDTH <= M0State.JUNCTION_DOOR_LEFT_X + 1.0 and _whole(room.door_leaf), "the shut blast door stops the route (engineer at x %.1f)" % human.position.x)
	game.call("debug_place", 200.0, 100.0)
	game.call("_door_blast")
	_expect(state.door_blown, "the blast brings the door down")
	var leaf_shown: bool = true
	var flew: bool = false
	# Watch every drawn frame of the break and the flight in slow motion, until the leaf lies in the
	# lane (the blast tween has ended), however long the frames take; then normal speed again. The
	# blast's hit-stop is ended first, or its real-time timer would reset time_scale to 1.0 mid-break.
	(game as Main).impact.end_hit_stop()
	Engine.time_scale = BLAST_TIME_SCALE
	var started: int = Engine.get_physics_frames()
	while Engine.get_physics_frames() - started < BEAT_FRAMES:
		leaf_shown = leaf_shown and (_whole(room.door_leaf) or _whole(room.door_leaf_breaking) or _whole(room.door_leaf_down))
		flew = flew or (room.door_flying and _whole(room.door_leaf_breaking) and room.door_leaf_breaking.position.x > JunctionDoorLayout.NEAR_JAMB_FOOT.x and not room.door_leaf_down.visible)
		if state.door_blown and not room.door_breaking and not room.door_flying and room.door_leaf_down.visible:
			break
		await process_frame
	Engine.time_scale = 1.0
	_expect(leaf_shown, "the leaf is drawn whole in every frame of the blast: shut, breaking, thrown, then lying in the lane")
	_expect(flew, "between the doorway and where it lies, the torn leaf is seen in the air, past the near jamb (it is thrown, not swapped)")
	_expect(_whole(room.door_leaf_down) and _whole(room.door_hole) and not room.door_leaf.visible, "after the blast the doorway is empty and the leaf lies in the lane")
	_expect(room.door_leaf_down.position.y + room.door_leaf_down.region_rect.size.y * room.door_leaf_down.scale.y >= JunctionRoom.FLOOR_Y, "the thrown leaf lies on the deck, not in the air")
	await frames(2)
	game.call("debug_place", 380.0, 200.0)
	await hold(&"move_right", 90, func() -> bool: return bool(game.get("waiting_for_choice")))  # 1.5 s of game time
	_expect(human.position.x > BLAST_SPAN.y, "the route runs through the blown doorway (engineer at x %.1f, doorway ends at %.1f)" % [human.position.x, BLAST_SPAN.y])


## The exit door: the bolt pops and the leaf slides into its pocket, drawn whole in every frame; USE at
## the doorway leaves; WOLF goes through first, then the engineer, nobody fades, and only then the card.
func _check_exit_door() -> void:
	var state: M0State = game.get("state") as M0State
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	game.set("waiting_for_choice", false)
	game.set("choice_context", "")
	state.drop_sentry()
	state.human_position = Vector2(JunctionRoom.BOLT_X, state.human_position.y)
	state.wolf_position = Vector2(JunctionRoom.WOLF_DOWN_X, state.wolf_position.y)
	game.call("_sync_scene")
	await frames(2)
	_expect(_whole(room.exit_leaf) and is_zero_approx(room.hatch_open), "the exit door stands shut before the bolt pops")
	game.call("debug_interact")
	var leaf_whole: bool = true
	var started: int = Engine.get_physics_frames()
	while room.hatch_open < 1.0 and Engine.get_physics_frames() - started < BEAT_FRAMES:
		leaf_whole = leaf_whole and _whole(room.exit_leaf)
		await process_frame
	_expect(room.hatch_open >= 1.0 and leaf_whole and _whole(room.exit_leaf), "the exit leaf slides open into its pocket, drawn whole every frame")
	var shut_edge: Vector3 = JunctionRoom.exit_leaf_anchor(0.0)
	_expect(room.exit_leaf.position.x - JunctionRoom.EXIT_SPAN.x < 0.25 * (JunctionRoom.EXIT_SPAN.y - JunctionRoom.EXIT_SPAN.x) and shut_edge.x - room.exit_leaf.position.x > 0.6 * (JunctionRoom.EXIT_SPAN.y - JunctionRoom.EXIT_SPAN.x), "the open leaf has slid back to the pocket's mouth by the far jamb (leading edge x %.1f, shut %.1f)" % [room.exit_leaf.position.x, shut_edge.x])
	await wait_until(func() -> bool: return human.controlled and absf(wolf.position.x - JunctionRoom.WOLF_DOORWAY_X) < 3.0, BEAT_FRAMES)
	# Fix round 3 (review r3, human pass): USE from the nearest spot that leaves (HATCH_REACH_MIN_X, still
	# inside the bolt panel's reach) leaves without stepping the engineer back to the panel's side.
	var leave_x: float = JunctionRoom.HATCH_REACH_MIN_X + 0.5
	game.call("debug_place", leave_x, wolf.position.x)
	game.call("debug_interact")
	_expect(state.junction_cleared and bool(game.get("chapter_close_active")), "USE at the open doorway leaves the junction")
	# The engineer's lowest x over the next 60 drawn frames (process frames, not physics frames: how
	# much game time they cover depends on the frame rate, at most 8 physics steps each).
	var closing_min_x: float = human.position.x
	for _frame: int in 60:
		await process_frame
		closing_min_x = minf(closing_min_x, human.position.x)
	_expect(float(game.get("engineer_step_x")) < 0.0 and closing_min_x >= leave_x - 1.0 and state.human_position.x >= leave_x - 1.0, "leaving, the engineer stays at the open door through the closing beat (lowest x %.1f, saved x %.1f, left from %.1f; the bolt panel's side is %.1f)" % [closing_min_x, state.human_position.x, leave_x, JunctionRoom.BOLT_X])
	game.call("_finish_chapter_close")
	# The physics frame each one is first past the near jamb (-1: not yet); only their order matters.
	var wolf_through: int = -1
	var human_through: int = -1
	var nobody_faded: bool = true
	leaf_whole = true
	var exit_floor_y: Vector2 = Vector2(human.position.y, wolf.position.y)
	var exit_off_floor: float = 0.0
	started = Engine.get_physics_frames()
	while not bool(game.get("end_card_active")) and Engine.get_physics_frames() - started < BEAT_FRAMES:
		exit_off_floor = maxf(exit_off_floor, maxf(absf(human.position.y - exit_floor_y.x), absf(wolf.position.y - exit_floor_y.y)))
		if wolf_through < 0 and wolf.position.x - M0Actor.WOLF_REACH >= JunctionRoom.EXIT_SPAN.y:
			wolf_through = Engine.get_physics_frames()
		if human_through < 0 and human.position.x - M0Actor.HUMAN_REACH >= JunctionRoom.EXIT_SPAN.y:
			human_through = Engine.get_physics_frames()
		nobody_faded = nobody_faded and human.visible and wolf.visible and human.modulate.a == 1.0 and wolf.modulate.a == 1.0 and human.self_modulate.a == 1.0 and wolf.self_modulate.a == 1.0
		leaf_whole = leaf_whole and _whole(room.exit_leaf)
		await process_frame
	_expect(bool(game.get("end_card_active")), "the END OF SLICE card comes at the end of the walk out")
	_expect(wolf_through >= 0 and human_through >= 0, "both WOLF and the engineer are past the exit's near jamb before the card (WOLF x %.1f, engineer x %.1f)" % [wolf.position.x, human.position.x])
	_expect(wolf_through >= 0 and human_through >= wolf_through, "WOLF goes through first, then the engineer")
	_expect(nobody_faded, "nobody fades or disappears on the way out")
	# Fix round 2: WOLF walks on down the passage to x 1100; the floor runs on under it, so he never drops
	# off its end behind the deck (he did, out of view, at round 1's full-speed walk).
	_expect(exit_off_floor <= 1.0, "both walk out through the exit on the floor, never dropping off its end (at most %.1f px off it)" % exit_off_floor)
	_expect(leaf_whole, "the open exit leaf stays drawn whole while they walk through")


## Every authored resting spot, for the room and state it is used in: an actor's drawn body (its reach
## either side of the origin) never lies across a shut door, and where it lies across an open doorway
## the door's near pieces draw over the actors, so the body reads as standing in the opening behind
## the near jamb rather than over the frame.
func _check_rest_spots() -> void:
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var records: RecordsRoom = game.get("records_room") as RecordsRoom
	var main_constants: Dictionary = (game.get_script() as Script).get_script_constant_map()
	var wolf_reach: float = M0Actor.WOLF_REACH
	var human_reach: float = M0Actor.HUMAN_REACH
	# [label, x, reach, door span, door open there, near piece drawn over the actors]; a shut door's span
	# starts at its face on the walk line (the room side of it is open floor).
	var spots: Array = [
		["Records: engineer's leftmost spot (the shut entry)", RecordsRoom.ENTRY_DOOR_X + human_reach, human_reach, Vector2(RecordsRoom.ENTRY_SPAN.x, RECORDS_ENTRY_FACE_X), false, null],
		["Records: WOLF's leftmost follow spot", RecordsRoom.ENTRY_DOOR_X + wolf_reach, wolf_reach, Vector2(RecordsRoom.ENTRY_SPAN.x, RECORDS_ENTRY_FACE_X), false, null],
		["Records: engineer at the container", main_constants["RECORDS_CONTAINER_SIDE_X"], human_reach, Vector2(RECORDS_EXIT_FACE_X, RecordsRoom.EXIT_SPAN.y), false, null],
		["Records: WOLF's rightmost follow spot", RecordsRoom.EXIT_DOOR_X - wolf_reach, wolf_reach, Vector2(RECORDS_EXIT_FACE_X, RecordsRoom.EXIT_SPAN.y), false, null],
		["Records: WOLF following the engineer out", main_constants["RECORDS_WOLF_OUT_X"], wolf_reach, RecordsRoom.EXIT_SPAN, true, records.front_mesh],
		["Junction: WOLF clear of the blast", JunctionRoom.WOLF_CLEAR_X, wolf_reach, Vector2(BLAST_FACE_X, BLAST_SPAN.y), false, null],
		["Junction: WOLF reading the seam", JunctionRoom.WOLF_SEAM_X, wolf_reach, Vector2(BLAST_FACE_X, BLAST_SPAN.y), false, null],
		["Junction: WOLF at the rubble", JunctionRoom.WOLF_RUBBLE_X, wolf_reach, BLAST_SPAN, true, room.door_column],
		["Junction: the lane question", JunctionRoom.CHOICE_X, human_reach, BLAST_SPAN, true, room.door_column],
		["Junction: WOLF by the exit", JunctionRoom.WOLF_DOWN_X, wolf_reach, JunctionRoom.EXIT_SHUT_SPAN, false, null],
		["Junction: engineer at the exit bolt", JunctionRoom.BOLT_X, human_reach, JunctionRoom.EXIT_SHUT_SPAN, false, null],
		["Junction: engineer behind WOLF at the open exit", JunctionRoom.HATCH_REACH_MAX_X, human_reach, JunctionRoom.EXIT_SPAN, true, room.exit_front],
		["Junction: WOLF waiting in the open exit doorway", JunctionRoom.WOLF_DOORWAY_X, wolf_reach, JunctionRoom.EXIT_SPAN, true, room.exit_front],
	]
	var in_doorway: Array[String] = []
	for spot: Array in spots:
		var x: float = spot[1]
		var reach: float = spot[2]
		var span: Vector2 = spot[3]
		var across: bool = x + reach > span.x and x - reach < span.y
		if not across:
			continue
		if not bool(spot[4]):
			_expect(false, "%s (x %.1f, body %.1f..%.1f) lies across a shut door (%.1f..%.1f)" % [spot[0], x, x - reach, x + reach, span.x, span.y])
			continue
		var near: CanvasItem = spot[5]
		_expect(near != null and drawn_z(near) > drawn_z(wolf) and drawn_z(near) > drawn_z(human), "%s stands in an open doorway with its near piece drawn over the actors" % spot[0])
		in_doorway.append("%s (x %.1f)" % [spot[0], x])
	print("Resting spots in an open doorway, behind its near jamb: %s" % ", ".join(in_doorway))
	_expect(records.exit_leaf.visible and records.entry_leaf.visible, "both Records leaves are still drawn at the end")


## Waits while [param running] holds (up to BEAT_FRAMES physics frames), checking every drawn frame
## that [param leaf] is drawn whole; true when it was in all of them.
func _leaf_whole_while(leaf: CanvasItem, running: Callable) -> bool:
	var whole: bool = _whole(leaf)
	var started: int = Engine.get_physics_frames()
	while running.call() and Engine.get_physics_frames() - started < BEAT_FRAMES:
		whole = whole and _whole(leaf)
		await process_frame
	return whole and _whole(leaf)


## Drawn, fully opaque, all the way up its parents.
func _whole(item: CanvasItem) -> bool:
	if item == null or not item.is_visible_in_tree():
		return false
	var node: Node = item
	while node != null:
		var canvas: CanvasItem = node as CanvasItem
		if canvas != null and (canvas.modulate.a < 1.0 or canvas.self_modulate.a < 1.0 and canvas == item):
			return false
		node = node.get_parent()
	return true
