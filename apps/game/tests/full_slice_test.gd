extends "res://tests/support/game_suite.gd"
## The whole built slice in one headless run, played only through the inputs a player has (the title's
## NEW GAME button, the move and USE actions, the answer keys), with no debug jumps, fixture saves or
## direct calls into the game: NEW GAME, the opening read box by box, the corridor's breaker (telling
## WOLF the truth), the relay WOLF powers, the seal and the safe point; Records' purge queue, the mirror
## port (WOLF's readout) and the exit; the Service Junction's breaker, the valve crank, the blast, the
## lane question (WOLF draws the sentry), the tank drop, the exit bolt and the open exit door; then the
## closing lines, the walk out and the END OF SLICE card. Each step must hand on to the next, so a
## change that breaks the route between rooms (the hand-over from the opening, a door that never
## opens, an exit whose USE moved) fails here even when every room's own suite passes.
##
## It drives the game with the shared kit (tests/support/game_suite.gd): walk_to_reading_on, tap and
## wait_until, and finish_opening and finish_closing_lines, which the parity capture's R2 and R4 routes
## use too. Every wait is bounded in physics frames (1/60 s of game time each), never the wall clock,
## so a busy machine slows it down without changing what it sees. Station positions come from the
## rooms' and Main's own constants.

## How long a beat between two inputs may take at most, in physics frames: 15 s of game time (the
## longest, WOLF walking to the sentry's mark and holding it there, takes about 6 s).
const BEAT_FRAMES: int = 900
## How long a conversation may take at most, in physics frames: 60 s of game time. continue_until reads
## every box for its full reading time (up to 7 s each), and the breaker's talk runs WOLF's stakes and
## the opening lines before his question, so it needs longer than one beat.
const TALK_FRAMES: int = 3600

var game: Main
var human: M0Actor
var wolf: M0Actor
var state: M0State:
	get:
		return game.state


func _run() -> void:
	check_name = "Full slice"
	game = await start_game("full-slice-test", keep_running) as Main
	human = game.human
	wolf = game.wolf
	if not await _play_opening():
		return
	if not await _play_corridor():
		return
	if not await _play_records():
		return
	if not await _play_junction():
		return
	await end_game(game)
	finish("Full slice checks passed: NEW GAME to the END OF SLICE card")


## NEW GAME on the title, then the opening read through to first control, which must come in the
## corridor side of the dock bay's doorway with the engineer free to walk.
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
	return _require(await wait_until(func() -> bool: return human.controlled, BEAT_FRAMES), "the opening hands control to the engineer (engineer at x %.1f)" % human.position.x)


## The corridor: the breaker and its question (disclose), the relay WOLF powers, the seal opening, the
## safe point and the cut to Records.
func _play_corridor() -> bool:
	if not _require(await walk_to_reading_on(human, Main.CORRIDOR_STATIONS[0].x), "the engineer walks from the dock bay to the corridor's breaker (stopped at x %.1f)" % human.position.x):
		return false
	await tap(&"interact", 1)
	if not _require(await continue_until(game, func() -> bool: return game.waiting_for_choice, TALK_FRAMES), "USE at the breaker asks whether to tell WOLF"):
		return false
	await tap(&"choice_1", 1)
	if not _require(await continue_until(game, func() -> bool: return state.breaker_armed and human.controlled and not game.waiting_for_choice, TALK_FRAMES), "telling WOLF arms the breaker and hands control back"):
		return false
	if not _require(await walk_to_reading_on(human, Main.RELAY_X), "the engineer walks to the relay"):
		return false
	await tap(&"interact", 1)
	if not _require(await wait_until(func() -> bool: return state.door_open and not game.seal_opening, BEAT_FRAMES), "WOLF powers the relay and the seal opens"):
		return false
	if not _require(await walk_to_reading_on(human, Main.CORRIDOR_STATIONS[2].x), "the engineer walks to the open seal"):
		return false
	await tap(&"interact", 1)
	return _require(await continue_until(game, func() -> bool: return state.chapter_id == "records" and human.controlled, TALK_FRAMES), "USE at the seal reaches the safe point and goes on into Records")


## Records Access: the purge queue, the mirror port with WOLF's readout, then the exit and its closing
## lines into the Service Junction.
func _play_records() -> bool:
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
	await tap(&"choice_1", 1)
	if not _require(await continue_until(game, func() -> bool: return state.mirror_trace_preserved and human.controlled, TALK_FRAMES), "WOLF's readout copies the mirror trace"):
		return false
	if not _require(await walk_to_reading_on(human, Main.RECORDS_EXIT_X), "the engineer walks to the Records exit"):
		return false
	await tap(&"interact", 1)
	return _require(await continue_until(game, func() -> bool: return state.chapter_id == "junction" and human.controlled and not game.wolf_scouting, TALK_FRAMES), "USE at the exit reads the closing lines and walks on into the Service Junction")


## The Service Junction: the breaker, the valve crank, the blast, the lane question (WOLF draws the
## sentry), the tank drop, the exit bolt, USE at the open door, the closing lines, the walk out and the
## END OF SLICE card.
func _play_junction() -> bool:
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
	await tap(&"choice_1", 1)
	var brain: SentryBrain = game.sentry_brain
	if not _require(await wait_until(func() -> bool: return brain.state == &"fixated" and absf(brain.x - DropArm.MARK_X) < 1.0 and absf(wolf.position.x - JunctionRoom.WOLF_BAIT_X) < 4.0, BEAT_FRAMES), "WOLF draws the sentry and holds it on the mark"):
		return false
	if not _require(await walk_to_reading_on(human, JunctionRoom.ARM_X), "the engineer walks to the tank release"):
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
	if not _require(await wait_until(func() -> bool: return game.end_card_active, BEAT_FRAMES), "WOLF and then the engineer walk out through the exit door to the END OF SLICE card"):
		return false
	var titles: Array[Node] = game.end_card.find_children("*", "Label", true, false).filter(func(label: Node) -> bool: return (label as Label).text == Main.END_CARD_TITLE)
	return _expect(game.end_card.visible and titles.size() == 1, "the END OF SLICE card is up with its title")
