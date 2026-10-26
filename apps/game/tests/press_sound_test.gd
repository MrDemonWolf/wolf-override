extends "res://tests/support/game_suite.gd"
## The round-2 press probe kept as a test (P0-14, SOUND-2): every press that changes the game's state
## starts a sound in the sound bank within one frame and changes what the screen says. It plays both
## relay routes through the corridor and Records Access with real presses, then the Service
## Junction's lane answers and its exit. On the way it checks that the MANUAL BYPASS hisses while it
## is cranked (P0-1, SOUND-1) and that the relay's COOLANT FAULT tag is gone once the relay is dealt
## with (P0-2, PUZ-7).

## Game variables that are part of a press's outcome beyond the save: the closing shots, the walk out,
## the lane answer, WOLF heading for the relay or refusing it, the bypass venting, the exit bolt and the
## walk out through the Records exit door.
const STATE_VARS: Array[String] = ["chapter_close_active", "hatch_exit_walking", "lane_choice", "wolf_heading_to_relay", "relay_refused", "bypass_venting", "bolt_state", "records_exit_walking"]
## How long, in seconds of game time, a scripted beat (WOLF walking to the relay, the crank, the
## seal) may take before the test gives up on it.
const BEAT_SECONDS: float = 15.0

var game: Node2D
var bank: SfxBank
var human: M0Actor
var wolf: M0Actor
var bypass: BypassHandle
## Clips the bank started since the last press.
var started: Array[StringName] = []
## State-changing presses checked, and how many of them were heard within one frame.
var presses: int = 0
var heard: int = 0


func _run() -> void:
	check_name = "Press sound"
	game = open_game("press-sound-test")
	bank = game.get("sfx_bank") as SfxBank
	human = game.get_node("Human") as M0Actor
	wolf = game.get_node("Wolf") as M0Actor
	bypass = game.get("bypass_handle") as BypassHandle
	bank.clip_started.connect(func(clip: StringName) -> void: started.append(clip))
	bank.wait_for_detail()

	await _route_wolf_takes_relay()
	await _route_bypass()
	await _junction_exit()

	_expect(presses >= 20, "the probe checked the slice's state-changing presses (%d)" % presses)
	print("Press probe: %d state-changing presses, %d heard within one frame" % [presses, heard])
	# The kit's teardown stops the bank and every player and lets the mixer release them (about 0.5 s
	# in all, as before) before it frees the game and removes its files.
	await end_game(game, 0.4)
	finish("Press sound checks passed")


## Disclose at the relay: WOLF takes the surge; the safe point; Records with WOLF's mirror readout;
## the first copy and its closing shot; into the junction; WOLF draws the sentry.
func _route_wolf_takes_relay() -> void:
	game.call("debug_new_game", true)
	await settle(5)
	await _ask_relay()
	await _press(&"choice_1", "telling WOLF the risk at the breaker")
	_expect(started.has(&"actuator"), "WOLF's answer at the relay is heard as his joints move (heard %s)" % [started])
	await _press(&"interact", "arming the corridor breaker")
	await _place(605.0, 520.0)
	_expect(_fault_shown(), "the live relay wears its COOLANT FAULT tag")
	await _press(&"interact", "signalling WOLF to take the relay")
	_expect(started.has(&"actuator"), "WOLF heading for the contact is heard at the press (heard %s)" % [started])
	_expect(await _until(func() -> bool: return bool(game.get("wolf_holding_relay"))), "WOLF takes the surge through the contact")
	_expect(await _until(func() -> bool: return not _fault_shown()), "the COOLANT FAULT tag fades once WOLF has taken the surge")
	_expect(await _until(func() -> bool: return human.controlled and not bool(game.get("seal_opening"))), "the seal opens and the engineer has control again")
	await _safe_point()
	await _records("wolf")
	await _leave_records()
	_expect((game.get("state") as M0State).chapter_id == "junction", "the Records exit leads into the Service Junction")
	await _press(&"interact", "arming the junction's overload breaker", JunctionRoom.BREAKER_X)
	await _lane_answer(1, "asking WOLF to draw the sentry")
	_expect(started.has(&"growl_warning") and started.has(&"actuator"), "WOLF agreeing to draw the sentry growls as he moves (heard %s)" % [started])


## Press WOLF at the relay: he refuses, the engineer cranks the MANUAL BYPASS; the safe point and
## Records with the manual port; into the junction; WOLF refuses the sentry, then the engineer goes alone.
func _route_bypass() -> void:
	game.call("debug_new_game", true)
	await settle(5)
	await _ask_relay()
	await _press(&"choice_2", "pressing WOLF at the breaker")
	await _press(&"interact", "arming the corridor breaker after his refusal")
	await _press(&"interact", "asking WOLF again at the live relay", 605.0)
	_expect(started.has(&"actuator"), "WOLF's refusal at the relay is heard (heard %s)" % [started])
	await _place(700.0, 480.0)
	await _press(&"interact", "taking hold of the MANUAL BYPASS")
	_expect(started.has(&"klaxon"), "the bypass alarm starts with the first touch (heard %s)" % [started])
	_expect(_hissing(), "coolant hisses from the relay while the bypass vents (the pressure-line loops play)")
	_expect(_fault_shown(), "the COOLANT FAULT tag stays while the bypass is being cranked")
	# The engineer steps to the crank spot first; the held USE turns the wheel once they are there.
	_expect(await _until(func() -> bool: return float(game.get("engineer_step_x")) < 0.0 and human.controlled), "the engineer reaches the crank spot")
	Input.action_press(&"interact")
	var locked: bool = await _until(func() -> bool: return (game.get("state") as M0State).door_open)
	Input.action_release(&"interact")
	_expect(locked and (game.get("state") as M0State).route == "fallback", "holding interact cranks the bypass until it locks over")
	await settle(2)
	_expect(not _hissing(), "the hiss stops once the bypass locks over")
	_expect(await _until(func() -> bool: return not _fault_shown()), "the COOLANT FAULT tag fades once the bypass locks over")
	_expect(await _until(func() -> bool: return human.controlled and not bool(game.get("seal_opening"))), "the seal opens on the engineer's own work")
	await _safe_point()
	await _records("manual")
	await _leave_records()
	await _press(&"interact", "arming the junction's overload breaker", JunctionRoom.BREAKER_X)
	await _lane_answer(1, "asking WOLF to draw the sentry after the relay")
	_expect(started.has(&"growl_refusal"), "WOLF refusing to draw the sentry growls (heard %s)" % [started])
	await _lane_answer(2, "telling WOLF the engineer will time the drop alone")


## The end of the junction: the sentry is down; the exit bolt, the hatch and the closing shot's continue.
func _junction_exit() -> void:
	var state: M0State = game.get("state") as M0State
	state.blow_door()
	state.drop_sentry()
	state.human_position = Vector2(JunctionRoom.BOLT_X, state.human_position.y)
	game.call("_sync_scene")
	await settle(2)
	await _press(&"interact", "popping the exit bolt", JunctionRoom.BOLT_X)
	_expect(await _until(func() -> bool: return float((game.get("junction_room") as JunctionRoom).hatch_open) >= 1.0), "the bolt arcs and the hatch slides open")
	# USE at the bolt panel does nothing once the door is open: the engineer walks up to the doorway.
	await _press(&"interact", "using the bolt panel once the door is open", JunctionRoom.BOLT_X, false)
	_expect(not state.junction_cleared, "the bolt panel does not take the engineer out through the door")
	await _press(&"interact", "leaving through the open exit door", (JunctionRoom.HATCH_REACH_MIN_X + JunctionRoom.HATCH_REACH_MAX_X) * 0.5)
	_expect(state.junction_cleared and bool(game.get("chapter_close_active")), "the hatch clears the service line and starts the closing shot")
	await _read_on()
	await _press(&"interact", "continuing from the junction's closing shot")
	_expect(bool(game.get("hatch_exit_walking")), "continue starts the walk out through the hatch")


## USE at the open Records exit: the engineer walks out through the doorway (the press is heard on its
## frame) and the Service Junction begins once they are through.
func _leave_records() -> void:
	await _press(&"interact", "walking out through the Records exit", 830.0)
	_expect(await _until(func() -> bool: return (game.get("state") as M0State).chapter_id == "junction" and human.controlled), "the walk through the Records exit ends in the Service Junction")


## At the breaker: USE until WOLF asks about the relay (the stakes line may come first).
func _ask_relay() -> void:
	await _place(350.0, 290.0)
	for _attempt: int in 3:
		if bool(game.get("waiting_for_choice")):
			break
		await _press(&"interact", "reading on at the breaker", -1.0, false)
	_expect(bool(game.get("waiting_for_choice")), "WOLF asks about the relay at the breaker")


## The safe point: secure it (first visit), save again, then go on into Records Access.
func _safe_point() -> void:
	await _place(876.0, 800.0)
	_expect(not _fault_shown(), "no COOLANT FAULT tag is left on the relay at the safe point")
	await _press(&"interact", "securing the safe point")
	_expect(started.has(&"chirp"), "the safe point takes the save with a chirp (heard %s)" % [started])
	# A reload from the safe point keeps the tag away too.
	game.call("debug_load_checkpoint")
	await settle(2)
	_expect(not _fault_shown(), "after Continue from the safe point the relay shows no COOLANT FAULT tag")
	await _place(876.0, 800.0)
	await _press(&"interact", "going on into Records Access")
	_expect((game.get("state") as M0State).chapter_id == "records", "the safe point opens Records Access")


## Records Access: the purge copy, the mirror (by [param mirror_route]), the first copy and its
## closing shot.
func _records(mirror_route: String) -> void:
	await _press(&"interact", "copying the purge-order trace", 190.0)
	await _press(&"interact", "opening the mirror index", 520.0, false)
	# WOLF reads it from beside the port.
	await _place(520.0, float((game.get_script() as Script).get_script_constant_map()["WOLF_MIRROR_X"]))
	await _press(&"choice_1" if mirror_route == "wolf" else &"choice_2", "copying the mirror timestamp (%s)" % mirror_route)
	_expect((game.get("state") as M0State).mirror_route == mirror_route, "the mirror is copied by the chosen route")
	await _press(&"interact", "securing the first copy at the Records exit", 830.0)
	_expect(started.has(&"records_arc"), "the first copy lets the exit go with its arc (heard %s)" % [started])
	# No closing shot holds the engineer (STORY-8): control stays while the closing lines run, and USE at
	# the exit goes on through their boxes before it leaves.
	_expect(not bool(game.get("chapter_close_active")) and await _until(func() -> bool: return human.controlled), "the engineer keeps control after the first copy")
	await _read_on(830.0)


## Presses USE through the boxes of the line on screen (no state changes) up to its last one, with the
## engineer first placed at [param at_x] when it is 0 or more (see _press). At most 6 presses: more
## than any line here has boxes, so the cap only keeps a stuck line from hanging the suite.
func _read_on(at_x: float = -1.0) -> void:
	for _box: int in 6:
		if int(game.get("dialogue_index")) >= (game.get("dialogue_boxes") as Array).size() - 1:
			return
		await _press(&"interact", "reading on", at_x, false)


## WOLF asks at the rubble line how to bring the sentry down, and [param response] answers.
func _lane_answer(response: int, label: String) -> void:
	var state: M0State = game.get("state") as M0State
	if not state.door_blown:
		state.blow_door()
		state.human_position = Vector2(JunctionRoom.CHOICE_X, state.human_position.y)
		game.call("_sync_scene")
		await settle(2)
	game.call("_ask_lane")
	await _press(&"choice_1" if response == 1 else &"choice_2", label)


## One press of [param action] (with the engineer first placed at [param at_x] when it is 0 or more)
## through the game's own input, as a key, button or tap does it. When the press changes the game's
## state it must start a sound within one frame and change what the screen says; [param must_change]
## also requires that it changes the state.
func _press(action: StringName, label: String, at_x: float = -1.0, must_change: bool = true) -> void:
	if at_x >= 0.0:
		await _place(at_x, wolf.position.x)
	await process_frame
	var before: String = _fingerprint()
	var said: String = _screen_text()
	started.clear()
	Input.action_press(action)
	# The frame the game sees the press.
	await process_frame
	Input.action_release(action)
	var heard_at: int = 0 if not started.is_empty() else -1
	var shown_at: int = 0 if _screen_text() != said else -1
	await process_frame
	if heard_at < 0 and not started.is_empty():
		heard_at = 1
	if shown_at < 0 and _screen_text() != said:
		shown_at = 1
	var changed: bool = _fingerprint() != before
	if must_change:
		_expect(changed, "%s changes the game's state" % label)
	if not changed:
		return
	presses += 1
	if _expect(heard_at >= 0, "%s starts a sound within one frame (heard %s)" % [label, started]):
		heard += 1
	_expect(shown_at >= 0, "%s changes what the screen says within one frame" % label)


## The save's state without the actors' positions, plus the press outcomes kept outside the save.
func _fingerprint() -> String:
	var data: Dictionary = (game.get("state") as M0State).to_dict()
	data.erase("positions")
	for key: String in STATE_VARS:
		data[key] = str(game.get(key))
	data["pressure_line"] = str((game.get("pressure_line") as PressureLine).state)
	return JSON.stringify(data)


## What the screen says: the dialogue box, the hint bar (and whether it shows) and the top card.
func _screen_text() -> String:
	var hint: Panel = game.get_node("CanvasLayer/ContextHint") as Panel
	return "%s|%s|%s|%s|%s" % [(game.get_node("CanvasLayer/BottomBar/Speaker") as Label).text, (game.get_node("CanvasLayer/BottomBar/Story") as Label).text, hint.visible, (hint.get_node("Text") as Label).text, (game.get_node("CanvasLayer/TopBar/HUD") as Label).text]


func _fault_shown() -> bool:
	return bypass.fault_tag.is_visible_in_tree() and bypass.fault_tag.self_modulate.a > 0.0


## Any of the pressure-line hiss loops is playing.
func _hissing() -> bool:
	for player: AudioStreamPlayer in bank.players():
		for clip: StringName in SfxBank.HISS_GAUGE:
			if player.playing and player.stream == bank.streams[clip]:
				return true
	return false


## Waits process frames until [param condition] holds, up to BEAT_SECONDS of game time (the kit's
## wait_game_seconds: on a busy machine late frames could use up a real-time limit before the game
## had played the beat). Returns whether it holds.
func _until(condition: Callable) -> bool:
	await wait_game_seconds(BEAT_SECONDS, condition)
	return bool(condition.call())


## The engineer at [param human_x] and WOLF at [param wolf_x], once any step the engineer was taking
## (beside a station, back from the relay) has finished, so it never carries them off the new spot.
func _place(human_x: float, wolf_x: float) -> void:
	await _until(func() -> bool: return float(game.get("engineer_step_x")) < 0.0)
	game.call("debug_place", human_x, wolf_x)
	await settle(1)
