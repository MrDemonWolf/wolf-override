extends "res://tests/support/game_suite.gd"
## P0-17: regression checks for what already works about WOLF as a companion.
## - WOLF-1: no WOLF line hurries the engineer.
## - WOLF-6: the sentry never turns on WOLF outside the bait he chooses, and nothing can knock him
##   down, catch him or need him rescued.
## - WOLF-8: none of WOLF's own actions completes a step that is the engineer's (the safe point, the
##   copies, the breaker, the valve, the tank drop, the bolt).
## - STORY-9: no meter in the HUD, and the engineer-only route (WOLF refuses the relay and the lane,
##   the engineer copies the mirror through the port) reaches every essential step to END OF SLICE.

## Words that would have WOLF set the pace (NEEDS WOLF-1), matched in lower case.
const URGENCY: Array[String] = ["hurry", "quick", "come on", "keep moving", "faster", "now!", "move it", "let's go", "get moving", "speed up", "too slow", "what are you waiting", "run!"]
## Seconds the engineer stands idle while WOLF is free to act.
const IDLE_FRAMES: int = 240


func _run() -> void:
	check_name = "Companion rule"
	_check_no_urgency()
	_check_hazards_ignore_wolf()
	var game: Main = await start_game("companion-rules-test", keep_running) as Main
	var path: String = str(game.get("save_path"))
	var actions: DebugActions = game.debug_tools.actions
	_check_no_wolf_fail_state(game)
	await _check_sentry_ignores_wolf(game, actions, &"refused")
	await _check_sentry_ignores_wolf(game, actions, &"alone")
	await _check_blast_spares_wolf(game, actions)
	await _check_wolf_takes_no_engineer_step(game, actions)
	await _check_engineer_only_route(game, actions)
	game.queue_free()
	await process_frame
	remove_file(path)
	remove_file("%s-settings.cfg" % path)
	finish("Companion rule checks passed")


# --- WOLF-1 ---------------------------------------------------------------------------------------

## Every line the game gives WOLF is read for words that would hurry the engineer: in any string in
## the game's scripts, the row from "WOLF: " on and each row after it in the same box, up to the next
## speaker ("%s: ", "NAME: ") or the first choice row ("1  ..."); and, since the story keeps a speaker's
## words apart from the tag (localization PR L7c), every row of each message the translation template
## marks speaker=WOLF.
func _check_no_urgency() -> void:
	var lines: Array[String] = []
	var literal: RegEx = RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	var next_speaker: RegEx = RegEx.create_from_string("^(%s|[A-Z][A-Za-z]+): |^[0-9]  ")
	for file: String in _scripts("res://scripts"):
		var source: String = FileAccess.get_file_as_string(file)
		for found: RegExMatch in literal.search_all(source):
			var wolf_speaking: bool = false
			for row: String in found.get_string(1).c_unescape().split("\n"):
				var at: int = row.find("WOLF: ")
				if at >= 0:
					wolf_speaking = true
					lines.append(row.substr(at))
				elif next_speaker.search(row) != null:
					wolf_speaking = false
				elif wolf_speaking and not row.strip_edges().is_empty():
					lines.append(row)
	var template: Dictionary = template_notes()
	for msgid: String in template:
		if template_marks(template[msgid]).get("speaker") == "WOLF":
			lines.append_array(msgid.split("\n"))
	_expect(lines.size() >= 20, "the scan finds WOLF's lines (%d)" % lines.size())
	for row: String in ["It crosses the mark on every pass.", "Take the purge queue. I'll inspect the mirror.", "I chose the relay. We made it."]:
		_expect(lines.has(row), "the scan reads the second row of WOLF's two-row boxes (\"%s\")" % row)
	for row: String in ["%s: Then we get through maintenance before the original logs disappear.", "1  USE WOLF'S READOUT     2  USE MANUAL PORT"]:
		_expect(not lines.has(row), "and stops at the next speaker or the choices (\"%s\")" % row)
	for line: String in lines:
		for word: String in URGENCY:
			_expect(not line.to_lower().contains(word), "WOLF never hurries the engineer: \"%s\" says \"%s\"" % [line, word])


## The game's scripts, without the debug tools (their labels name WOLF's spots, not lines he says).
func _scripts(folder: String) -> Array[String]:
	var found: Array[String] = []
	for file: String in DirAccess.get_files_at(folder):
		if file.ends_with(".gd"):
			found.append(folder.path_join(file))
	for sub: String in DirAccess.get_directories_at(folder):
		if sub != "debug":
			found.append_array(_scripts(folder.path_join(sub)))
	return found


# --- WOLF-6 ---------------------------------------------------------------------------------------

## The vent and the coolant cloud report contact for the engineer only.
func _check_hazards_ignore_wolf() -> void:
	var hazard: Hazard = Hazard.make("Probe", Rect2(0.0, 0.0, 10.0, 10.0), "%s")
	var contacts: Array[int] = [0]
	hazard.contact.connect(func(_source: Hazard) -> void: contacts[0] += 1)
	hazard.armed = true
	var wolf: M0Actor = M0Actor.new()
	wolf.actor_id = &"wolf"
	var human: M0Actor = M0Actor.new()
	human.actor_id = &"human"
	hazard.call("_on_body_entered", wolf)
	_expect(contacts[0] == 0, "an armed hazard ignores WOLF walking into it")
	hazard.call("_on_body_entered", human)
	_expect(contacts[0] == 1, "and catches the engineer")
	for node: Node in [hazard, wolf, human]:
		node.free()


## No knockdown card, save field or room state is WOLF's: every card names the engineer, and a save
## keeps only where he stands.
func _check_no_wolf_fail_state(game: Main) -> void:
	for reason: String in [JunctionRoom.VENT_REASON, JunctionRoom.BLAST_REASON, JunctionRoom.CLOUD_REASON, JunctionRoom.SENTRY_REASON, JunctionRoom.SENTRY_CHASED_REASON]:
		_expect(reason.contains("%s") and not reason.contains("WOLF"), "the knockdown card \"%s\" is about the engineer" % reason)
	var keys: Array = M0State.new().to_dict().keys()
	for key: Variant in keys:
		_expect(not str(key).contains("wolf"), "no save field holds a WOLF condition (%s)" % key)
	_expect((M0State.new().to_dict()["positions"] as Dictionary).has("wolf"), "a save keeps where WOLF stands, and nothing else about him")
	_expect(not game.has_method("_knock_down_wolf") and not game.has_method("_rescue_wolf"), "there is no knockdown or rescue for WOLF")


## In the lane on the routes where WOLF does not draw it, the sentry patrols on with WOLF standing in
## its path, never sees, chases or fixates on him, and nothing knocks anyone down.
func _check_sentry_ignores_wolf(game: Main, actions: DebugActions, lane: StringName) -> void:
	actions.set_relay(&"press" if lane == &"refused" else &"disclose_wolf")
	actions.set_lane(lane)
	actions.jump(&"lane")
	_require(game.lane_choice == String(lane) and not game.wolf_baiting, "%s: WOLF is not drawing the sentry" % lane)
	var brain: SentryBrain = game.sentry_brain
	var noticed: bool = false
	for _frame: int in 300:
		# WOLF stands right in its body, wherever it goes.
		game.wolf.position.x = clampf(brain.x, M0Actor.MIN_X, M0Actor.MAX_X)
		await physics_frame
		noticed = noticed or brain.state != &"patrol" or brain.watch_x >= 0.0 or game.fail_active
	_expect(not noticed and game.wolf.visible and game.wolf.modulate.a > 0.99, "%s: with WOLF in its path the sentry keeps its patrol, never watches him and nothing is knocked down" % lane)


## The door blast with WOLF standing in front of the door and the engineer clear: no knockdown.
func _check_blast_spares_wolf(game: Main, actions: DebugActions) -> void:
	actions.set_relay(&"disclose_wolf")
	actions.jump(&"junction_a")
	await frames(5)
	_require(await wait_until(func() -> bool: return not game.wolf_scouting, 300), "WOLF reads the gauge")
	_require(await walk_to_reading_on(game.human, JunctionRoom.BREAKER_X), "the engineer walks to the breaker")
	await tap(&"interact", 1)
	_require(game.pressure_line.state == &"building", "the breaker arms the line")
	_require(await walk_to_reading_on(game.human, Main.VALVE_CRANK_X), "the engineer walks to the valve")
	Input.action_press(&"interact")
	var lit: bool = await wait_until(func() -> bool: return game.pressure_line.state == &"fuse" or game.pressure_line.state == &"charged", 240)
	Input.action_release(&"interact")
	_require(lit, "three turns light the fuse")
	_require(await walk_to_reading_on(game.human, 200.0), "the engineer backs away to the breaker")
	var knocked: bool = false
	for _frame: int in 600:
		game.wolf.position.x = JunctionRoom.DOOR_X
		await physics_frame
		knocked = knocked or game.fail_active
		if game.state.door_blown:
			break
	_expect(game.state.door_blown and not knocked, "the blast with WOLF in front of the door knocks nobody down and the door goes")


# --- WOLF-8 ---------------------------------------------------------------------------------------

## Where WOLF acts on his own, the engineer stands idle: no step of theirs gets done.
func _check_wolf_takes_no_engineer_step(game: Main, actions: DebugActions) -> void:
	actions.set_relay(&"disclose_wolf")
	actions.set_mirror(&"wolf")
	actions.set_lane(&"wolf")
	# The corridor: WOLF takes the contact; the safe point is still the engineer's.
	actions.jump(&"relay_question")
	await tap(&"choice_1", 1)
	for _step: int in 3:
		if game.state.breaker_armed:
			break
		await tap(&"interact", 1)
		await frames(20)
	_require(await walk_to_reading_on(game.human, Main.RELAY_SIDE_X), "the engineer walks to the relay")
	await tap(&"interact", 1)
	_require(await wait_until(func() -> bool: return game.state.door_open, 300), "WOLF takes the contact and the seal opens")
	await frames(IDLE_FRAMES)
	_expect(game.state.route == "cooperate" and game.bypass_ticks == 0 and not game.state.checkpoint_reached, "with WOLF on the contact the MANUAL BYPASS is untouched and the safe point waits for the engineer")
	# Records: WOLF goes to the mirror port on his own; neither copy happens without the engineer.
	actions.jump(&"records_entry")
	await frames(IDLE_FRAMES)
	_expect(absf(game.wolf.position.x - Main.WOLF_MIRROR_X) <= 2.0 and not game.state.purge_trace_preserved and not game.state.mirror_trace_preserved, "at the mirror port WOLF copies nothing until the engineer asks")
	# The junction: WOLF reads the valve; the breaker and the valve stay the engineer's.
	actions.jump(&"junction_a")
	await frames(IDLE_FRAMES)
	_expect(not game.wolf_scouting and game.pressure_line.state == &"idle" and game.pressure_line.turns == 0 and not game.state.door_blown, "after WOLF reads the gauge the breaker, the valve and the door wait for the engineer")
	# The lane: WOLF draws the sentry onto the mark; the drop is the engineer's.
	actions.jump(&"lane")
	_require(await wait_until(func() -> bool: return game.call("_bait_holding"), 600), "WOLF parks the sentry on the mark")
	await frames(IDLE_FRAMES)
	_expect(game.call("_bait_holding") and game.drop_arm.state == &"hung" and not game.state.sentry_down, "with the sentry held on the mark the tank stays up until the engineer drops it")
	# Tank down: WOLF waits by the hatch; the bolt is the engineer's.
	actions.jump(&"tank_down")
	await frames(IDLE_FRAMES)
	_expect(game.bolt_state == &"locked" and not game.state.junction_cleared and game.junction_room.hatch_open == 0.0, "with WOLF by the hatch the bolt stays locked until the engineer pops it")


# --- STORY-9 --------------------------------------------------------------------------------------

## No meter anywhere in the HUD: no progress bar, nothing named or labelled as a trust, bond or
## relationship meter, in any room or on the END OF SLICE card.
func _check_no_meter(game: Main, where: String) -> void:
	for layer: Node in game.find_children("*", "CanvasLayer", true, false):
		for node: Node in layer.find_children("*", "", true, false):
			if not (node is CanvasItem) or not (node as CanvasItem).is_visible_in_tree():
				continue
			_expect(not (node is ProgressBar) and not (node is TextureProgressBar), "%s: no progress bar in the HUD (%s)" % [where, layer.get_path_to(node)])
			var text: String = node.name.to_lower()
			if node is Label:
				text += " " + (node as Label).text.to_lower()
			elif node is RichTextLabel:
				text += " " + (node as RichTextLabel).get_parsed_text().to_lower()
			elif node is Button:
				text += " " + (node as Button).text.to_lower()
			for word: String in ["trust", "bond", "affinity", "loyalty", "meter", "relationship"]:
				_expect(not text.contains(word), "%s: nothing in the HUD reads as a %s meter (%s)" % [where, word, layer.get_path_to(node)])


## The engineer-only route: rushed at the relay (WOLF refuses, the engineer cranks the bypass), the
## mirror copied through the port, WOLF asked to draw the sentry and refusing, the engineer timing the
## drop alone, the bolt and the hatch, to the END OF SLICE card.
func _check_engineer_only_route(game: Main, actions: DebugActions) -> void:
	actions.set_relay(&"press")
	actions.jump(&"relay_question")
	_check_no_meter(game, "corridor")
	await tap(&"choice_2", 1)
	for _step: int in 3:
		if game.state.breaker_armed:
			break
		await tap(&"interact", 1)
		await frames(20)
	_require(game.state.breaker_armed and game.state.memory.get("choice_id") == M0State.PRESS, "rushed answer, breaker armed")
	_require(await walk_to_reading_on(game.human, Main.RELAY_SIDE_X), "the engineer walks to the relay")
	await tap(&"interact", 1)
	_require(game.relay_refused and not game.state.door_open, "WOLF refuses the relay")
	_require(await walk_to_reading_on(game.human, Main.BYPASS_WHEEL.x - 18.0), "the engineer walks to the MANUAL BYPASS")
	await tap(&"interact", 1)
	await frames(10)
	Input.action_press(&"interact")
	var opened: bool = await wait_until(func() -> bool: return game.state.door_open, 400)
	Input.action_release(&"interact")
	_require(opened and game.state.route == "fallback", "the engineer's crank opens the seal")
	_require(await wait_until(func() -> bool: return not game.seal_opening, 120), "the seal finishes opening")
	_require(await walk_to_reading_on(game.human, 876.0), "the engineer walks to the safe point")
	for _step: int in 4:
		if game.state.chapter_id == "records":
			break
		await tap(&"interact", 1)
		await frames(30)
	_require(game.state.checkpoint_reached and game.state.chapter_id == "records", "the safe point saves and opens Records")
	_check_no_meter(game, "Records")
	_require(await walk_to_reading_on(game.human, 190.0), "the engineer walks to the purge queue")
	await tap(&"interact", 1)
	_require(game.state.purge_trace_preserved, "the engineer copies the purge order")
	_require(await walk_to_reading_on(game.human, 520.0), "the engineer walks to the mirror port")
	await tap(&"interact", 1)
	_require(game.waiting_for_choice, "the mirror offers both routes")
	await tap(&"choice_2", 1)
	_require(game.state.mirror_trace_preserved and game.state.mirror_route == "manual", "the engineer copies the mirror through the port")
	_require(await walk_to_reading_on(game.human, 830.0), "the engineer walks to the Records exit")
	await tap(&"interact", 1)
	_require(game.state.chapter_complete, "the first copy is secured")
	# USE goes on from the closing shot, then walks them out through the open exit door; the junction
	# begins once WOLF is through behind the engineer.
	for _step: int in 4:
		if game.state.chapter_id == "junction":
			break
		await tap(&"interact", 1)
		await wait_until(func() -> bool: return game.state.chapter_id == "junction", 120)
	_require(game.state.chapter_id == "junction", "the Records exit leads into the junction")
	_check_no_meter(game, "junction")
	_require(await wait_until(func() -> bool: return not game.wolf_scouting, 300), "WOLF reads the gauge")
	_require(await walk_to_reading_on(game.human, JunctionRoom.BREAKER_X), "the engineer walks to the breaker")
	await tap(&"interact", 1)
	_require(game.pressure_line.state == &"building", "the engineer arms the line")
	_require(await walk_to_reading_on(game.human, Main.VALVE_CRANK_X), "the engineer walks to the valve")
	Input.action_press(&"interact")
	var lit: bool = await wait_until(func() -> bool: return game.pressure_line.state == &"fuse" or game.pressure_line.state == &"charged", 240)
	Input.action_release(&"interact")
	_require(lit, "the engineer's three turns light the fuse")
	_require(await walk_to_reading_on(game.human, PressureLine.BLAST_MIN_X - 20.0), "the engineer backs away past the valve")
	_require(await wait_until(func() -> bool: return game.state.door_blown, 400) and not game.fail_active, "the door blows with the engineer clear")
	Input.action_press(&"move_right")
	var asked: bool = await wait_until(func() -> bool: return game.waiting_for_choice, 400)
	Input.action_release(&"move_right")
	_require(asked, "WOLF asks how to bring the sentry down")
	await tap(&"choice_1", 1)
	_require(game.lane_choice == "refused" and not game.wolf_baiting, "asked to draw it after a rushed relay, WOLF refuses")
	var brain: SentryBrain = game.sentry_brain
	_require(await wait_until(func() -> bool: return game.human.controlled and brain.state == &"patrol" and brain.facing > 0.0 and brain.x >= 700.0, 600), "the sentry heads away down the lane")
	_require(await walk_to_reading_on(game.human, JunctionRoom.ARM_X) and not game.fail_active, "the engineer slips into the alcove")
	var lead: float = SentryBrain.PATROL_SPEED * DropArm.FALL_SECONDS
	_require(await wait_until(func() -> bool: return brain.facing < 0.0 and absf(brain.x - DropArm.MARK_X - lead) <= 8.0, 600), "the sentry comes back toward the mark")
	await tap(&"interact", 1)
	_require(await wait_until(func() -> bool: return game.state.sentry_down, 90), "the engineer's timed drop brings the sentry down")
	_require(await walk_to_reading_on(game.human, JunctionRoom.BOLT_X), "the engineer walks to the exit bolt")
	await tap(&"interact", 1)
	_require(game.bolt_state == &"charging", "the engineer pops the bolt")
	_require(await wait_until(func() -> bool: return game.bolt_state == &"open" and game.junction_room.hatch_open >= 1.0, 240), "the bolt drops and the hatch opens")
	# The way out is offered at the open door itself, behind WOLF waiting in its doorway.
	_require(await walk_to_reading_on(game.human, JunctionRoom.HATCH_REACH_MAX_X + 4.0), "the engineer walks up to the open exit door")
	for _step: int in 8:
		if game.end_card_active:
			break
		await tap(&"interact", 1)
		await wait_until(func() -> bool: return game.end_card_active, 240)
	_require(game.state.junction_cleared and game.end_card_active, "the engineer leaves through the exit door to the END OF SLICE card")
	_check_no_meter(game, "END OF SLICE card")


# --- Helpers --------------------------------------------------------------------------------------
