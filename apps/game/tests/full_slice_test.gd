extends "res://tests/support/game_suite.gd"
## Chapter 1's cooperative and engineer-only routes, played only through the inputs a player has (the title's
## NEW GAME button, the move and USE actions, the answer keys), with no debug jumps, fixture saves or
## direct calls into the game: NEW GAME, the opening read box by box, the corridor's breaker and
## cooperative relay or manual bypass, the seal and safe point; Records' purge queue, WOLF's readout
## or manual mirror port and exit; Junction's breaker, valve, blast, WOLF's distraction or a manually
## timed tank drop, the exit bolt and open door; then the
## closing lines, the investigation's three evidence reads and the chapter-end card. Each step must hand on to the next, so a
## change that breaks the route between rooms (the hand-over from the opening, a door that never
## opens, an exit whose USE moved) fails here even when every room's own suite passes.
##
## It drives the game with the shared kit (tests/support/game_suite.gd): walk_to_reading_on, tap and
## wait_until, and finish_opening and finish_closing_lines, which the parity capture's R2 and R4 routes
## use too. Every wait is bounded in physics frames (1/60 s of game time each), never the wall clock,
## so a busy machine slows it down without changing what it sees. Station positions come from the
## rooms' and Main's own constants.

## How long a beat between two inputs may take at most, in physics frames: 15 s of game time, the
## same bound door_route_test gives a beat; conversations read box by box get the kit's TALK_FRAMES.
const BEAT_FRAMES: int = 900

var game: Main
var human: M0Actor
var wolf: M0Actor
var state: M0State:
	get:
		return game.state


func _run() -> void:
	check_name = "Full Chapter 1"
	for engineer_only: bool in [false, true]:
		game = await start_game("full-chapter-one-%s" % ("manual" if engineer_only else "cooperative"), keep_running) as Main
		human = game.human
		wolf = game.wolf
		if not await _play_opening() or not await _play_corridor(engineer_only) or not await _play_records(engineer_only) or not await _play_junction(engineer_only) or not await _play_investigation():
			return
		await end_game(game)
	finish("Full Chapter 1 checks passed: NEW GAME to chapter end, cooperative and engineer-only")


## NEW GAME on the title, then the opening read through to first control, which must come in the
## corridor, past the dock bay's cross-wall (DockBay.ROOM_RIGHT), with the engineer free to walk.
func _play_opening() -> bool:
	var new_game: Button = game.get_node("CanvasLayer/TitleScreen/NewGameButton") as Button
	if not _require(game.title_open and new_game.is_visible_in_tree() and not new_game.disabled, "the title offers NEW GAME"):
		return false
	new_game.pressed.emit()
	await frames(2)
	if not _require(game.intro_active, "NEW GAME starts the opening"):
		return false
	var note: String = await finish_opening(game)
	if not _require(note.is_empty(), note):
		return false
	if not _require(await wait_until(func() -> bool: return human.controlled, BEAT_FRAMES), "the opening hands control to the engineer"):
		return false
	return _require(human.position.x > DockBay.ROOM_RIGHT, "play starts in the corridor, past the dock bay (engineer at x %.1f)" % human.position.x)


## Plays the corridor with disclosure/WOLF help or refusal/manual bypass according to [param engineer_only].
func _play_corridor(engineer_only: bool) -> bool:
	if not _require(await walk_to_reading_on(human, Main.CORRIDOR_STATIONS[0].x), "the engineer walks from the dock bay to the corridor's breaker (stopped at x %.1f)" % human.position.x):
		return false
	await tap(&"interact", 1)
	if not _require(await continue_until(game, func() -> bool: return game.waiting_for_choice, TALK_FRAMES), "USE at the breaker asks whether to tell WOLF"):
		return false
	await tap(&"choice_2" if engineer_only else &"choice_1", 1)
	if not _require(await continue_until(game, func() -> bool: return state.breaker_armed and human.controlled and not game.waiting_for_choice, TALK_FRAMES), "telling WOLF arms the breaker and hands control back"):
		return false
	if not _require(await walk_to_reading_on(human, Main.RELAY_X), "the engineer walks to the relay"):
		return false
	await tap(&"interact", 1)
	if engineer_only:
		if not _require(await continue_until(game, func() -> bool: return game.relay_refused and not game.waiting_for_choice, TALK_FRAMES), "WOLF's refusal leaves the engineer's bypass available"):
			return false
		if not _require(await walk_to_reading_on(human, Main.BYPASS_WHEEL.x), "the engineer reaches the manual bypass"):
			return false
		await hold(&"interact", BEAT_FRAMES, func() -> bool: return state.door_open)
	if not _require(await wait_until(func() -> bool: return state.door_open and not game.seal_opening, BEAT_FRAMES), "WOLF powers the relay and the seal opens"):
		return false
	if not _require(await walk_to_reading_on(human, Main.CORRIDOR_STATIONS[2].x), "the engineer walks to the open seal"):
		return false
	await tap(&"interact", 1)
	return _require(await continue_until(game, func() -> bool: return state.chapter_id == "records" and human.controlled, TALK_FRAMES), "USE at the seal reaches the safe point and goes on into Records")


## Copies Records using WOLF's readout or engineer access, then follows the existing exit into Junction.
func _play_records(engineer_only: bool) -> bool:
	if not _require(await walk_to_reading_on(human, RecordsRoom.PURGE_X), "the engineer walks to the purge queue"):
		return false
	await tap(&"interact", 1)
	if not _require(await continue_until(game, func() -> bool: return state.purge_trace_preserved and human.controlled, TALK_FRAMES), "USE at the purge queue copies the purge order"):
		return false
	if not _require(await walk_to_reading_on(human, RecordsRoom.MIRROR_X), "the engineer walks to the mirror port"):
		return false
	await tap(&"interact", 1)
	if not _require(await continue_until(game, func() -> bool: return game.waiting_for_choice, TALK_FRAMES), "USE at the mirror port asks who reads it"):
		return false
	await tap(&"choice_2" if engineer_only else &"choice_1", 1)
	if not _require(await continue_until(game, func() -> bool: return state.mirror_trace_preserved and human.controlled, TALK_FRAMES), "WOLF's readout copies the mirror trace"):
		return false
	if not _require(await walk_to_reading_on(human, Main.RECORDS_EXIT_X), "the engineer walks to the Records exit"):
		return false
	await tap(&"interact", 1)
	return _require(await continue_until(game, func() -> bool: return state.chapter_id == "junction" and human.controlled and not game.wolf_scouting, TALK_FRAMES), "USE at the exit reads the closing lines and walks on into the Service Junction")


## Clears Junction with WOLF's distraction or an engineer-timed drop, then enters the investigation.
func _play_junction(engineer_only: bool) -> bool:
	if not _require(await walk_to_reading_on(human, JunctionRoom.BREAKER_X), "the engineer walks to the junction's breaker"):
		return false
	await tap(&"interact", 1)
	if not _require(await walk_to_reading_on(human, JunctionRoom.VALVE_X) and not game.fail_active, "the engineer crosses the vent to the valve"):
		return false
	var line: PressureLine = game.pressure_line
	await hold(&"interact", BEAT_FRAMES, func() -> bool: return line.state != &"building")
	if not _require(line.state != &"building" and not game.fail_active, "holding USE at the valve charges the line"):
		return false
	if not _require(await walk_to_reading_on(human, PressureLine.BLAST_MIN_X - 16.0), "the engineer stands clear of the blast"):
		return false
	if not _require(await wait_until(func() -> bool: return state.door_blown or game.fail_active, BEAT_FRAMES) and state.door_blown, "the charged line blows the blast door"):
		return false
	# Walking on into the lane brings WOLF's question; the engineer holds still at the rubble line while
	# the box before it is up (Main.lane_question_held), so the key stays down until it is asked.
	Input.action_press(&"move_right")
	var asked: bool = await wait_until(func() -> bool: return game.waiting_for_choice, BEAT_FRAMES)
	Input.action_release(&"move_right")
	if not _require(asked, "past the blown door WOLF asks how to bring the sentry down"):
		return false
	await tap(&"choice_2" if engineer_only else &"choice_1", 1)
	var brain: SentryBrain = game.sentry_brain
	if not engineer_only and not _require(await wait_until(func() -> bool: return brain.state == &"fixated" and absf(brain.x - DropArm.MARK_X) < 1.0 and absf(wolf.position.x - JunctionRoom.WOLF_BAIT_X) < 4.0, BEAT_FRAMES), "WOLF draws the sentry and holds it on the mark"):
		return false
	if not _require(await walk_to_reading_on(human, JunctionRoom.ARM_X), "the engineer walks to the tank release"):
		return false
	if engineer_only:
		# Lead the left-moving patrol by the tank's fall time; its existing graze window absorbs input latency.
		var release_x: float = DropArm.MARK_X + SentryBrain.PATROL_SPEED * DropArm.FALL_SECONDS
		if not _require(await wait_until(func() -> bool: return brain.state == &"patrol" and brain.facing < 0.0 and absf(brain.x - release_x) <= 8.0, BEAT_FRAMES), "the engineer waits in cover for a drop opportunity without WOLF"):
			return false
	await tap(&"interact", 1)
	if not _require(await wait_until(func() -> bool: return state.sentry_down, BEAT_FRAMES), "the tank drop brings the sentry down"):
		return false
	if not _require(await walk_to_reading_on(human, JunctionRoom.BOLT_PANEL_X), "the engineer walks to the exit bolt"):
		return false
	await tap(&"interact", 1)
	if not _require(await wait_until(func() -> bool: return game.bolt_state == &"open" and game.junction_room.hatch_open >= 1.0 and human.controlled, BEAT_FRAMES), "the bolt drops and the exit door slides open"):
		return false
	# USE leaves from the door itself, behind WOLF in its doorway, not from the bolt panel.
	if not _require(await walk_to_reading_on(human, OPEN_EXIT_X) and human.position.x >= JunctionRoom.HATCH_REACH_MIN_X, "the engineer walks up to the open exit door (x %.1f)" % human.position.x):
		return false
	await tap(&"interact", 1)
	if not _require(state.junction_cleared and game.chapter_close_active, "USE at the open exit door clears the junction into its closing lines"):
		return false
	var note: String = await finish_closing_lines(game)
	if not _require(note.is_empty(), note):
		return false
	return _require(await wait_until(func() -> bool: return state.chapter_id == "investigation" and human.controlled, BEAT_FRAMES), "the Junction exit leads into the investigation rather than ending Chapter 1 early")


## Reads each annex station through player movement and USE, then leaves only after the final reveal.
func _play_investigation() -> bool:
	for station: int in 3:
		var station_x: float = [RecordsRoom.PURGE_X, RecordsRoom.MIRROR_X, RecordsRoom.CONTAINER_X][station]
		if not _require(await walk_to_reading_on(human, station_x), "the engineer reaches investigation station %d" % (station + 1)):
			return false
		await tap(&"interact", 1)
		if not _require(await continue_until(game, func() -> bool: return state.investigation_step == station + 1 and game.box_queue.is_empty() and bool(game.call("_dialogue_read")), TALK_FRAMES), "the evidence at station %d is preserved and read" % (station + 1)):
			return false
	if not _require(await walk_to_reading_on(human, Main.RECORDS_EXIT_X + 10.0), "the engineer reaches the investigation exit after the repair discovery"):
		return false
	await tap(&"interact", 1)
	if not _require(await continue_until(game, func() -> bool: return game.end_card_active, TALK_FRAMES), "the approved repair revelation leads to the Chapter 1 end card"):
		return false
	var titles: Array[Node] = game.end_card.find_children("*", "Label", true, false).filter(func(label: Node) -> bool: return (label as Label).text == Main.END_CARD_TITLE)
	return _expect(game.end_card.visible and titles.size() == 1 and state.investigation_step == 4, "the Chapter 1 card follows the saved repair revelation")
