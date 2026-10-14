extends SceneTree
## The wording Nathanial approved on 2026-10-13 (docs/research-2026-10/how-it-should-play/
## drafts-2026-10-13.md, items 1 and 3-7) as the game shows it: every changed line, the trust line as
## two boxes in order, the junction's goal-only entry and its hint ladder (timers and order), every
## refused press in the junction answered with a sound, a lamp flicker and a line within 6 frames (and
## again, with a blink of the box, when pressed again), the sealed door's own USE answer and its bump,
## and none of the cut lines left anywhere in the game's scripts or on screen.

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const MainScript = preload("res://scripts/main.gd")
const State = preload("res://scripts/m0_state.gd")
## A press must be heard, seen on its station's lamp and answered in the box within this many frames.
const ANSWER_FRAMES: int = 6
## Lines cut on 2026-10-13 (P0-19 / Q5: N1, N4, N5, N14 and the two clauses; Q6's chain on entry).
const CUT_LINES: Array[String] = [
	"A blue light answers from inside the containment seal.",
	"The gate slides aside.",
	"The Director freezes at the sound of the seal opening.",
	"WOLF runs ahead to the valve and reads its LINE gauge.",
	"the red seal stays shut",
	"from a split line",
	"Go now. We can talk after.",
	"They know what a fault looks like",
	"CHECK THE LANE",
	"In the lane beyond",
	"alcove",
	"Keep inside the posts",
	"in the brackets",
	"floor mark",
	"from the panel",
	"toward the panel",
	"You're in its lane",
	"patrols the lane",
	"runs the line",
	"The lane past the door",
	"SPENT",
	"BOLTED",
	"\"LANE  ",
]

var failures: int = 0
var game: Node2D
var human: M0Actor
var wolf: M0Actor
var room: JunctionRoom
var bank: SfxBank
var bottom_bar: Control
var started: Array[StringName] = []
var path: String


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	path = "user://approved-wording-test-%s.json" % OS.get_process_id()
	_remove(path)
	_check_sources()
	_check_constants()
	game = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	game.set("settings_path", "%s-settings.cfg" % path)
	root.add_child(game)
	human = game.get_node("Human") as M0Actor
	wolf = game.get_node("Wolf") as M0Actor
	room = game.get("junction_room") as JunctionRoom
	bank = game.get("sfx_bank") as SfxBank
	bottom_bar = game.get_node("CanvasLayer/BottomBar") as Control
	bank.clip_started.connect(func(clip: StringName) -> void: started.append(clip))
	bank.wait_for_detail()
	await _check_opening()
	await _check_trust_boxes()
	await _check_junction_entry()
	_check_ladder()
	await _check_refusals()
	await _check_door_bump()
	await _check_after_blast()
	await _check_knockdown_boxes()
	await _check_blast_boxes()
	await _check_story_moves_on()
	await _check_miss_boxes()
	bank.stop_all()
	game.queue_free()
	_remove(path)
	_remove("%s-settings.cfg" % path)
	await create_timer(0.5).timeout
	if failures == 0:
		print("Approved wording checks passed")
	quit(1 if failures > 0 else 0)


## No cut line or dropped name is left in any script a player's text comes from.
func _check_sources() -> void:
	for script_path: String in ["res://scripts/main.gd", "res://scripts/junction_room.gd", "res://scripts/m0_state.gd"]:
		var source: String = FileAccess.get_file_as_string(script_path)
		var code: String = ""
		for line: String in source.split("\n"):
			# Comments may name the old words (to say what changed); only code reaches the screen.
			if not line.strip_edges().begins_with("#"):
				code += line.get_slice(" ## ", 0) + "\n"
		for cut: String in CUT_LINES:
			var at: int = code.find(cut)
			# "alcove" survives only inside identifiers and comments (alcove_rect, ALCOVE_FLOOR), never in a string.
			var in_string: bool = false
			while at >= 0:
				var before: String = code.substr(0, at)
				var line_start: int = before.rfind("\n") + 1
				var prefix: String = code.substr(line_start, at - line_start)
				if prefix.count("\"") % 2 == 1:
					in_string = true
					break
				at = code.find(cut, at + 1)
			_expect(not in_string, "%s has no player text with \"%s\"" % [script_path.get_file(), cut])


## Every string Nathanial approved on 2026-10-13, as the code holds it.
func _check_constants() -> void:
	var c: Dictionary = (MainScript as GDScript).get_script_constant_map()
	_expect(State.CHOICE_TEXT[State.PRESS] == "Skip the risk talk. Go now." and State.CHOICE_TEXT[State.DISCLOSE] == "The relay may vent coolant. Your call.", "item 1: the relay's answers")
	_expect(c["TRUST_LINE_1"] == "%s keeps WOLF's systems running." and c["TRUST_LINE_2"] == "%s knows what a fault looks like,\nand this isn't one.", "item 4: the trust line's two boxes")
	_expect((c["INTRO_LINES"] as Array)[2] == "Nobody gives an activation command.\nWOLF wakes himself." and (c["INTRO_LINES"] as Array)[3] == "The latch breaks from the inside.\nWOLF steps out under his own power.", "item 6: the opening's cut lines are gone")
	_expect(c["BREAKER_CATCHES_LINE"] == "The breaker catches.\nBlue light fills the coolant relay.", "item 6 N7: the breaker line without the seal clause")
	_expect(c["JUNCTION_ENTRY_LINE"] == "%s: That door is our way through." and c["JUNCTION_GOAL_HINT"] == "Get through the sealed door." and c["WOLF_DOOR_WARNING"] == "WOLF: When the door goes, don't be standing in front of it.", "item 7: the junction entry says the goal only, then WOLF warns about the door")
	_expect(c["LADDER_BREAKER_LINE"] == "%s: The breaker by the entrance\nfeeds that line." and c["LADDER_CHAIN_LINE"] == "%s: Overload it, crank the valve,\nand the door goes.", "item 7: the ladder's lines are the approved chain, split")
	_expect(c["JUNCTION_RESTORE_A_LINE"] == "Service junction restored. Arm the breaker by the entrance, then crank the valve.\nWOLF: When the door goes, don't be standing in front of it.", "item 7: Continue keeps the restore-A line")
	_expect(c["RUBBLE_LINE"] == "The door goes. WOLF heads for the rubble\nto wait for %s's call." and c["RUBBLE_WAKE_LINE"] == "Past the doorway, something whirs awake.", "item 3 S6: the door going, then the sentry past the doorway")
	_expect(c["TANK_MISS_LINE"] == "The tank hits the empty mark\nand sprays coolant." and c["TANK_MISS_TURN_LINE"] == "The sentry swings toward the release;\nget back over the rubble.", "items 3 S15 and 6 N18: the miss in two boxes, with no split line")
	_expect(c["BAIT_NO_LINE"] == "WOLF: At the relay you'd have sent me in blind. I won't walk into its sights. Time the drop from the release; it crosses the mark on every pass.", "item 3 S14: WOLF says release, not panel")
	_expect(c["ALONE_LINES"] == ["WOLF: I'll hold at the rubble.\nIt crosses the mark on every pass.", "WOLF: The tank takes a moment to fall."], "item 3 S13: WOLF's two boxes when the engineer times it alone")
	_expect(c["SENTRY_LOCK_LINE"] == "The sentry stops and its eyes snap red.\nIt has %s; get back over the rubble." and c["SENTRY_LOST_LINE"] == "The sentry loses %s behind the rubble\nand rolls back to its patrol.", "item 3 S7 and S8: the same words on two rows")
	_expect(JunctionRoom.SENTRY_REASON == "The sentry saw %s out in the open.\nStay close to the TANK RELEASE." and JunctionRoom.SENTRY_CHASED_REASON == "The sentry ran %s down. Once its\neyes go red, only the rubble is safe.", "item 3 S3 and S4: the sentry's knockdown cards")
	for key: String in ["RECAP_LANE_WOLF", "RECAP_LANE_REFUSED", "RECAP_LANE_ALONE", "RECAP_LANE_BROKE_OFF", "RECAP_LANE_UNKNOWN"]:
		_expect(str(c[key]).begins_with("SENTRY  "), "item 3 S20: %s's topic is SENTRY" % key)
	var refusals: Dictionary = {
		"REFUSE_VALVE_DEAD": "The valve is dead. Arm the breaker first.",
		"REFUSE_VALVE_TRIPPED": "The vent let go and the breaker tripped.\nReset it by the entrance.",
		"REFUSE_DOOR": "Sealed shut. Something hums behind it.\nThe valve beside it charges it.",
		"REFUSE_BREAKER_LIVE": "Already live. Crank the valve by the door.",
		"REFUSE_FUSE_LIT": "Fuse lit. Get clear of the door.",
		"REFUSE_SPENT": "No charge left. The door is down.",
		"DROP_WAIT_LINE": "Wait. WOLF hasn't got it on the mark yet.",
		"REFUSE_REWINDING": "Not yet. The tank is still going back up.",
		"REFUSE_RELEASE_SPENT": "The tank is down on the sentry.\nThe exit bolt is by the hatch.",
		"REFUSE_EXIT_SENTRY": "Locked out until the sentry is down.",
		"REFUSE_EXIT_DOOR": "Bolted. The sealed door comes first.",
	}
	for key: String in refusals:
		_expect(c[key] == refusals[key], "item 5: %s reads as approved" % key)
	# Line rules: at most 42 characters a row (with the longest preset name) and 2 rows a box.
	var boxes: Array[String] = []
	for key: String in ["TRUST_LINE_1", "TRUST_LINE_2", "RUBBLE_LINE", "RUBBLE_WAKE_LINE", "TANK_MISS_LINE", "TANK_MISS_TURN_LINE", "SENTRY_LOCK_LINE", "SENTRY_LOST_LINE", "LADDER_BREAKER_LINE", "LADDER_CHAIN_LINE", "JUNCTION_ENTRY_LINE"]:
		boxes.append(str(c[key]))
	boxes.append_array(c["ALONE_LINES"] as Array)
	boxes.append_array(refusals.values())
	boxes.append_array([JunctionRoom.SENTRY_REASON, JunctionRoom.SENTRY_CHASED_REASON])
	boxes.append_array([(c["INTRO_LINES"] as Array)[2], (c["INTRO_LINES"] as Array)[3], c["BREAKER_CATCHES_LINE"]])
	# S11 and S16 are said where they happen; _check_after_blast checks them on screen word for word.
	boxes.append_array(["No station in reach. The TANK RELEASE\nis past the rubble.", "Service junction restored. The door is\ndown. The sentry patrols past the rubble."])
	for box: String in boxes:
		var shown: String = box.replace("%s", "MORGAN" if box.begins_with("%s:") else "Morgan")
		if shown.begins_with("MORGAN: ") or shown.begins_with("WOLF: "):
			shown = shown.get_slice(": ", 1) if shown.split("\n").size() == 1 else shown.substr(shown.find(": ") + 2)
		var rows: PackedStringArray = shown.split("\n")
		var widest: int = 0
		for row: String in rows:
			widest = maxi(widest, row.length())
		_expect(rows.size() <= 2 and widest <= 42, "\"%s\" fits 2 rows of 42 characters with Morgan (%d rows, widest %d)" % [box.c_escape(), rows.size(), widest])


## The opening never shows a cut line.
func _check_opening() -> void:
	game.call("_new_game")
	var shown: Array[String] = []
	for _beat: int in (game.get_script().get_script_constant_map()["INTRO_LINES"] as Array).size():
		shown.append(str(game.get("status_line")))
		game.call("_advance_intro")
		await process_frame
	game.call("_finish_intro")
	await process_frame
	for line: String in shown:
		for cut: String in CUT_LINES:
			_expect(not line.contains(cut), "the opening shows no cut line (\"%s\")" % cut)


## Item 4: after first control the trust line is two boxes, in order, each up its reading time, then
## the opening exchange as it was.
func _check_trust_boxes() -> void:
	game.call("debug_new_game", true)
	await process_frame
	var box_1: String = "Rowan keeps WOLF's systems running."
	var box_2: String = "Rowan knows what a fault looks like,\nand this isn't one."
	var box_3: String = "WOLF: I heard the Director's plan for me. I woke myself. He wants me to hunt people he calls threats.\nROWAN: Then we get through maintenance before the original logs disappear."
	# The boxes are timed by the game's own clock; step it by hand so nothing else moves meanwhile.
	game.set("box_queue_seconds", MainScript.box_seconds(box_1))
	_expect(str(game.get("status_line")) == box_1 and game.get("box_queue") == [box_2, box_3], "first control shows the trust line's first box, with the second and the exchange to come")
	_expect(absf(MainScript.box_seconds(box_1) - 2.95) < 0.01 and absf(MainScript.box_seconds(box_2) - (1.2 + 0.33 * 11.0)) < 0.01, "each box stays up its reading time (%.2f s and %.2f s)" % [MainScript.box_seconds(box_1), MainScript.box_seconds(box_2)])
	game.call("_advance_box_queue", MainScript.box_seconds(box_1) - 0.05)
	_expect(str(game.get("status_line")) == box_1, "the first box holds for its reading time")
	game.call("_advance_box_queue", 0.1)
	_expect(str(game.get("status_line")) == box_2, "then the second box: the name again, never \"They\"")
	game.call("_refresh_ui")
	var story: Label = game.get_node("CanvasLayer/BottomBar/Story") as Label
	_expect(story.text == box_2 and not (game.get_node("CanvasLayer/BottomBar/Speaker") as Label).visible, "the second box shows as narration, untagged, on two rows")
	game.call("_advance_box_queue", MainScript.box_seconds(box_2) + 0.05)
	_expect(str(game.get("status_line")) == box_3 and (game.get("box_queue") as Array).is_empty(), "then the opening exchange, unchanged")
	# A line said meanwhile (a station's answer) only holds the rest back for its own reading time.
	game.call("debug_new_game", true)
	game.set("status_line", "WOLF: Quiet.")
	game.call("_advance_box_queue", 0.01)
	_expect(game.get("box_queue") == [box_2, box_3] and str(game.get("status_line")) == "WOLF: Quiet.", "another line taking the box holds the boxes still to come")
	game.call("_advance_box_queue", MainScript.box_seconds("WOLF: Quiet.") - 0.05)
	_expect(str(game.get("status_line")) == "WOLF: Quiet.", "the line that cut in stays up its own reading time")
	game.call("_advance_box_queue", 0.1)
	_expect(str(game.get("status_line")) == box_2 and game.get("box_queue") == [box_3], "then the trust line's second box comes back")
	# An open choice holds them; answering it drops them (the story has moved on past them).
	game.set("status_line", "WOLF: Pick.")
	game.call("_advance_box_queue", 0.01)
	game.set("waiting_for_choice", true)
	game.call("_advance_box_queue", 30.0)
	_expect(str(game.get("status_line")) == "WOLF: Pick." and game.get("box_queue") == [box_3], "an open choice holds the boxes still to come")
	game.set("waiting_for_choice", false)
	game.set("status_line", "WOLF: Picked.")
	game.call("_advance_box_queue", 30.0)
	_expect((game.get("box_queue") as Array).is_empty() and str(game.get("status_line")) == "WOLF: Picked.", "answering the choice drops the boxes from before it")
	# In play: following the hint bar at first control (E at the purge display, during the first box)
	# still shows the second box and the opening exchange, in order, after the display's own line.
	for at_breaker: bool in [false, true]:
		game.call("debug_new_game", true)
		await process_frame
		if at_breaker:
			# E at the breaker within the first box: the stakes line cuts in instead.
			human.position.x = 350.0
		for _frame: int in 20:
			await process_frame
		var seen: Array[String] = [str(game.get("status_line"))]
		Input.action_press(&"interact")
		await process_frame
		Input.action_release(&"interact")
		var started_at: int = Time.get_ticks_msec()
		while Time.get_ticks_msec() - started_at < 25000:
			var line: String = str(game.get("status_line"))
			if seen.is_empty() or seen.back() != line:
				seen.append(line)
			if line == box_3:
				break
			await process_frame
		var cut_in: String = seen[1] if seen.size() > 1 else ""
		_expect(seen.size() == 4 and seen[0] == box_1 and cut_in != box_2 and seen[2] == box_2 and seen[3] == box_3, "E at the %s during the first box: its line, then the second box and the exchange, in order (seen %s)" % ["breaker" if at_breaker else "purge display", str(seen).c_escape()])


## A fresh junction entry: the engineer's goal, WOLF's run shown and his warning, the goal-only hint.
func _check_junction_entry() -> void:
	await _enter_fresh_junction()
	_expect(str(game.get("status_line")) == "ROWAN: That door is our way through.", "entering, the engineer says only the goal")
	game.call("_refresh_ui")
	var speaker: Label = game.get_node("CanvasLayer/BottomBar/Speaker") as Label
	_expect(speaker.text == "ROWAN" and (game.get_node("CanvasLayer/BottomBar/Story") as Label).text == "That door is our way through.", "under the engineer's own tag")
	_expect(game.get("wolf_scouting") and wolf.autonomous_target_x == JunctionRoom.WOLF_SEAM_X, "WOLF runs to the valve on screen, with no narration of it")
	game.set("checkpoint_toast_remaining", 0.0)
	human.position.x = 120.0
	_expect(str(game.call("_context_hint")) == "Get through the sealed door.", "the hint bar shows the goal only")
	_expect(await _wait_until(func() -> bool: return str(game.get("status_line")) == "WOLF: When the door goes, don't be standing in front of it.", 400), "then WOLF's approved door warning, once he has read the gauge")
	_expect(not game.get("wolf_scouting"), "and he follows again")


## Item 7's hint ladder, stepped by hand: T1 at 45 s (WOLF looks at the breaker, its lamp pulses, no
## text), T2 at 90 s (the engineer names the breaker), T3 at 180 s (the whole chain, two boxes). It
## does not count during a choice or a knockdown, and arming the breaker ends it.
func _check_ladder() -> void:
	var seconds: Array = game.get_script().get_script_constant_map()["JUNCTION_LADDER_SECONDS"]
	_expect(seconds == [45.0, 90.0, 180.0], "the ladder's steps come at 45, 90 and 180 s")
	game.set("ladder_seconds", 0.0)
	game.set("ladder_step", 0)
	game.set("wolf_scouting", false)
	game.set("status_line", "WOLF: When the door goes, don't be standing in front of it.")
	game.call("_update_controls")
	game.set("waiting_for_choice", true)
	game.call("_tick_ladder", 100.0)
	_expect(is_equal_approx(float(game.get("ladder_seconds")), 0.0), "the ladder does not count during a choice")
	game.set("waiting_for_choice", false)
	game.call("_tick_ladder", 44.9)
	_expect(int(game.get("ladder_step")) == 0 and room.breaker_pulse_level() == 0.0, "nothing before 45 s")
	game.call("_tick_ladder", 0.2)
	_expect(int(game.get("ladder_step")) == 1 and float(game.get("wolf_look_x")) >= 0.0 and wolf.autonomous_target_x == float(game.get("wolf_look_x")), "T1 at 45 s: WOLF stops where he is to look")
	game.call("_tick_ladder", 0.0)
	_expect(wolf.body_sprite.flip_h == (JunctionRoom.BREAKER_X < wolf.position.x), "he faces the breaker")
	room._advance_flicker(0.3)
	_expect(room.breaker_pulse_level() > 0.0 and room.breaker_pulse_remaining > 0.0, "the breaker's lamp pulses")
	_expect(str(game.get("status_line")) == "WOLF: When the door goes, don't be standing in front of it.", "T1 says nothing")
	game.call("_tick_ladder", MainScript.WOLF_LOOK_SECONDS)
	_expect(float(game.get("wolf_look_x")) < 0.0 and wolf.follow_target == human, "after the look he follows again")
	game.call("_tick_ladder", 90.0 - float(game.get("ladder_seconds")) - 0.1)
	_expect(int(game.get("ladder_step")) == 1, "nothing more before 90 s")
	game.call("_tick_ladder", 0.2)
	_expect(int(game.get("ladder_step")) == 2 and str(game.get("status_line")) == "ROWAN: The breaker by the entrance\nfeeds that line.", "T2 at 90 s: the engineer names the breaker")
	human.position.x = 120.0
	_expect(str(game.call("_context_hint")) == "Get through the sealed door.", "the hint bar still shows the goal only")
	game.call("_tick_ladder", 180.0 - float(game.get("ladder_seconds")) - 0.1)
	_expect(int(game.get("ladder_step")) == 2, "nothing more before 180 s")
	game.call("_tick_ladder", 0.2)
	_expect(int(game.get("ladder_step")) == 3 and str(game.get("status_line")) == "ROWAN: The breaker by the entrance\nfeeds that line." and game.get("box_queue") == ["ROWAN: Overload it, crank the valve,\nand the door goes."], "T3 at 180 s: the whole chain, as two boxes in order")
	_expect(str(game.call("_context_hint")) == "Arm the breaker by the entrance, then crank the valve by the door.", "once the chain is said the hint bar gives it too")
	# Arming the breaker is progress: a fresh ladder stops there.
	game.set("ladder_seconds", 0.0)
	game.set("ladder_step", 0)
	(game.get("pressure_line") as PressureLine).arm()
	game.call("_tick_ladder", 50.0)
	_expect(int(game.get("ladder_step")) == 3 and float(game.get("wolf_look_x")) < 0.0, "with the breaker armed the ladder ends without a step")
	(game.get("pressure_line") as PressureLine).reset()
	room.sync_line(game.get("pressure_line"))


## Item 5: every refused press in the junction, each answered within ANSWER_FRAMES frames by the
## clunk, its station's lamp flicker and its line; a second press re-shows the line with a blink.
func _check_refusals() -> void:
	var tools: Object = game.get("debug_tools")
	(tools.get("actions") as Object).set("sentry_frozen", true)
	(tools.get("actions") as Object).set("invincible", true)
	var line: PressureLine = game.get("pressure_line") as PressureLine
	var stations: Array = game.get_script().get_script_constant_map()["JUNCTION_STATIONS"]
	var valve_x: float = float(game.call("debug_station_side_x", stations[1], JunctionRoom.VALVE_X - 1.0))
	var breaker_x: float = float(game.call("debug_station_side_x", stations[0], JunctionRoom.BREAKER_X + 1.0))
	var release_x: float = float(game.call("debug_station_side_x", stations[2], JunctionRoom.ARM_X + 1.0))
	# Row 1: the valve before the breaker; then pressed again.
	await _enter_fresh_junction()
	await _place(valve_x, false)
	await _refused("row 1, the valve before the breaker", &"valve", "The valve is dead. Arm the breaker first.", &"clank")
	await _refused("row 1 pressed again", &"valve", "The valve is dead. Arm the breaker first.", &"clank", true)
	# Row 7b: the exit before the door is down (only a hand-made save gets there).
	await _place(JunctionRoom.BOLT_X, false)
	await _refused("row 7b, the exit before the door is down", &"bolt", "Bolted. The sealed door comes first.", &"clank")
	# Row 3: the breaker while the line builds; row 3b: breaker and valve while the fuse burns.
	await _place(breaker_x, true)
	await _tap(&"interact")
	_expect(line.state == &"building", "the breaker arms the line")
	await _refused("row 3, the breaker while the line builds", &"breaker", "Already live. Crank the valve by the door.", &"clank")
	line.crank(2.0)
	line.advance(0.016)
	_expect(line.state == &"fuse", "the line is charged and the fuse lit")
	await _refused("row 3b, the breaker while the fuse burns", &"breaker", "Fuse lit. Get clear of the door.", &"clank")
	await _place(valve_x, false)
	await _refused("row 3b, the valve while the fuse burns", &"valve", "Fuse lit. Get clear of the door.", &"clank")
	# Row 1b: the valve after the vent tripped the breaker.
	await _enter_fresh_junction()
	line.arm()
	line.advance(PressureLine.BUILD_SECONDS + 0.1)
	room.sync_line(line)
	_expect(line.state == &"tripped", "the vent has tripped the breaker")
	await _place(valve_x, false)
	await _refused("row 1b, the valve after a trip", &"valve", "The vent let go and the breaker tripped.\nReset it by the entrance.", &"clank")
	# Row 2: USE at the sealed door, pressed up against it.
	line.reset()
	room.sync_line(line)
	Input.action_press(&"move_right")
	_expect(await _wait_until(func() -> bool: return human.position.x + M0State.HUMAN_HALF_WIDTH >= M0State.JUNCTION_DOOR_LEFT_X - 1.0, 120), "the engineer walks up against the sealed door")
	# The bump's own flicker has to be over, so the USE's flicker is its own.
	_expect(await _wait_until(func() -> bool: return not room.flickering(&"door"), 60), "the bump's flicker is over")
	game.set("status_line", "")
	await _refused("row 2, USE at the sealed door", &"door", "Sealed shut. Something hums behind it.\nThe valve beside it charges it.", &"clank")
	Input.action_release(&"move_right")
	# Let go at the door: the settle slides the engineer off the valve's body to its side, and USE there
	# is still the door's after 30 and 90 frames; once they move, the valve answers again.
	for wait: int in [30, 90]:
		await _place(380.0, false)
		Input.action_press(&"move_right")
		_expect(await _wait_until(func() -> bool: return human.position.x + M0State.HUMAN_HALF_WIDTH >= M0State.JUNCTION_DOOR_LEFT_X - 1.0, 120), "the engineer walks up against the sealed door again")
		# Held into the door, as a player does, until a frame has seen the engineer at its face: a slow
		# frame can run several physics steps, so letting go on the first touch can miss that frame.
		_expect(await _wait_until(func() -> bool: return bool(game.get("door_faced")), 60), "a frame sees the engineer at the sealed door's face")
		Input.action_release(&"move_right")
		_expect(await _wait_until(func() -> bool: return not room.flickering(&"door"), 60), "the bump's flicker is over")
		for _frame: int in wait:
			await physics_frame
		_expect(human.position.x < JunctionRoom.VALVE_X, "let go at the door, the engineer settles off the valve's body (x %.1f)" % human.position.x)
		await _refused("row 2, USE %d frames after letting go at the sealed door" % wait, &"door", "Sealed shut. Something hums behind it.\nThe valve beside it charges it.", &"clank")
	Input.action_press(&"move_left")
	for _frame: int in 4:
		await physics_frame
	Input.action_release(&"move_left")
	for _frame: int in 30:
		await physics_frame
	await _refused("row 1 after a step back from the door", &"valve", "The valve is dead. Arm the breaker first.", &"clank")
	# Rows 4 and 4b: the used valve and breaker once the door is down; row 7: the exit before the sentry.
	await _start_at(false)
	await _place(valve_x, false)
	await _refused("row 4, the used valve", &"valve", "No charge left. The door is down.", &"clank")
	await _place(breaker_x, true)
	await _refused("row 4b, the used breaker", &"breaker", "No charge left. The door is down.", &"clank")
	game.set("lane_choice", "alone")
	await _place(JunctionRoom.BOLT_X, false)
	await _refused("row 7, the exit before the sentry is down", &"bolt", "Locked out until the sentry is down.", &"clank")
	# Row 5: DROP while WOLF is still bringing the sentry in.
	game.set("lane_choice", "wolf")
	game.set("wolf_baiting", true)
	await _place(release_x, false)
	wolf.position.x = JunctionRoom.WOLF_RUBBLE_X
	_expect(game.call("_drop_waits_for_wolf"), "WOLF has not got it on the mark yet")
	await _refused("row 5, DROP too early", &"release", "Wait. WOLF hasn't got it on the mark yet.", &"clank")
	game.set("wolf_baiting", false)
	# Row 5b: DROP while the winch hauls a missed tank back up.
	var arm: DropArm = game.get("drop_arm") as DropArm
	(game.get("sentry_brain") as SentryBrain).x = SentryBrain.PATROL_MAX_X
	game.call("debug_drop_tank")
	_expect(await _wait_until(func() -> bool: return arm.state == &"rewinding" and not arm.on_floor(), 300), "the missed tank is winching back up")
	await _place(release_x, false)
	await _refused("row 5b, DROP while the tank winches up", &"release", "Not yet. The tank is still going back up.", &"clank")
	# Row 6: the release once the sentry is down.
	await _start_at(true)
	await _place(release_x, false)
	await _refused("row 6, the used release", &"release", "The tank is down on the sentry.\nThe exit bolt is by the hatch.", &"clank")
	(tools.get("actions") as Object).set("sentry_frozen", false)
	(tools.get("actions") as Object).set("invincible", false)


## Walking into the sealed door: a thud, a stop, the seam lamp flickers once, and only the first bump
## of a visit says why.
func _check_door_bump() -> void:
	await _enter_fresh_junction()
	game.set("wolf_scouting", false)
	await _place(380.0, false)
	game.set("status_line", "WOLF: Quiet.")
	started.clear()
	Input.action_press(&"move_right")
	# The bump's flicker lasts 0.14 s; a slow frame can start and end it while the walk is still being
	# watched, so any frame that sees it counts.
	var flickered: Array[bool] = [false]
	_expect(await _wait_until(func() -> bool:
		flickered[0] = flickered[0] or room.flickering(&"door")
		return human.position.x + M0State.HUMAN_HALF_WIDTH >= M0State.JUNCTION_DOOR_LEFT_X - 1.0, 120), "the engineer walks into the sealed door")
	var frames: int = await _frames_until(func() -> bool:
		flickered[0] = flickered[0] or room.flickering(&"door")
		return started.has(&"thud") and flickered[0] and str(game.get("status_line")) == "Sealed shut. Something hums behind it.\nThe valve beside it charges it.")
	_expect(frames <= ANSWER_FRAMES, "the first bump thuds, flickers the door's lamp and says why within %d frames (%d)" % [ANSWER_FRAMES, frames])
	var stopped_x: float = human.position.x
	for _frame: int in 20:
		await physics_frame
	_expect(absf(human.position.x - stopped_x) < 0.5 and human.position.x + M0State.HUMAN_HALF_WIDTH <= M0State.JUNCTION_DOOR_LEFT_X + 0.5 and started.count(&"thud") == 1, "held against it, the engineer stops at its face and it thuds once")
	Input.action_release(&"move_right")
	await _place(380.0, false)
	game.set("status_line", "WOLF: Quiet.")
	started.clear()
	Input.action_press(&"move_right")
	_expect(await _wait_until(func() -> bool: return started.has(&"thud") and room.flickering(&"door"), 120), "a second push thuds again and flickers the door's lamp")
	_expect(str(game.get("status_line")) == "WOLF: Quiet.", "but only the first bump says why")
	Input.action_release(&"move_right")


## After the blast: the objective, the plates, the hints and lines that name drawn things.
func _check_after_blast() -> void:
	await _start_at(false)
	_expect(game.call("_objective") == "GO THROUGH THE DOOR", "item 3 S19: the objective after the blast")
	_expect(room.breaker_label.text == "BREAKER USED" and room.valve_label.text == "VALVE USED" and room.hatch_label.text == "EXIT LOCKED", "item 3: the plates' state words are plain")
	_expect(str(game.get("status_line")) == "Service junction restored. The door is\ndown. The sentry patrols past the rubble.", "item 3 S16: the restore line")
	game.set("checkpoint_toast_remaining", 0.0)
	_expect(str(game.call("_context_hint")) == "The sentry patrols past the rubble. The TANK RELEASE hides you from it.", "item 3 S1: the default hint")
	var stations: Array = game.get_script().get_script_constant_map()["JUNCTION_STATIONS"]
	human.position.x = float(game.call("debug_station_side_x", stations[2], JunctionRoom.ARM_X + 1.0))
	_expect(str(game.call("_context_hint")) == "E: drop the tank. Land it with the sentry on the mark.", "item 3 S12: the release's hint")
	human.position.x = SentryBrain.COVER_MAX_X + 30.0
	(game.get("sentry_brain") as SentryBrain).state = &"patrol"
	_expect(str(game.call("_context_hint")) == "You're in its sights. Hide at the TANK RELEASE or the rubble.", "item 3 S2: out in the open")
	game.call("debug_place", JunctionRoom.CHOICE_X - 30.0, JunctionRoom.WOLF_RUBBLE_X)
	game.call("debug_interact")
	_expect(str(game.get("status_line")) == "No station in reach. The TANK RELEASE\nis past the rubble.", "item 3 S11: no station in reach")
	_expect(game.call("_sentry_reason") == "The sentry ran Rowan down. Once its\neyes go red, only the rubble is safe.", "item 3 S4: the chased card")
	await _start_at(true)
	_expect(room.arm_label.text == "RELEASE USED" and room.hatch_label.text == "EXIT READY", "item 3: the used release and the ready exit")
	var recap: Array = game.call("end_card_recap")
	_expect(str(recap[2]).begins_with("SENTRY  "), "item 3 S20: the end card's third topic is SENTRY")


## A sentry knockdown card is two rows already, so where play resumed follows in its own box (2 rows a box).
func _check_knockdown_boxes() -> void:
	await _start_at(false)
	var reason: String = JunctionRoom.SENTRY_REASON % "Rowan"
	game.call("_fail_beat", reason, true)
	_expect(bool(game.get("fail_active")), "the sentry knockdown starts")
	_expect(await _wait_until(func() -> bool: return not bool(game.get("fail_active")), 300), "the knockdown restores the checkpoint")
	var c: Dictionary = (MainScript as GDScript).get_script_constant_map()
	var queue: Array = game.get("box_queue")
	_expect(str(game.get("status_line")) == reason and queue.size() == 1 and (queue[0] == c["RESTORE_FROM_DISK_LINE"] or queue[0] == c["RESTORE_BEAT_LINE"]), "after restore the two-row card keeps its box and the restore line comes next (box \"%s\", then %s)" % [str(game.get("status_line")).c_escape(), str(queue)])


## Item 3 S6 in play: walking straight to the rubble line after the blast still shows "Past the
## doorway, something whirs awake.". Reaching the line brings it up at once and holds the engineer
## there; WOLF's question waits until it has been up its reading time. Waiting at the door first, it
## comes on its own and the question still waits out the rest of its time.
func _check_blast_boxes() -> void:
	var c: Dictionary = (MainScript as GDScript).get_script_constant_map()
	var box_1: String = c["RUBBLE_LINE"] % "Rowan"
	var wake: String = c["RUBBLE_WAKE_LINE"]
	for wait_ms: int in [0, 6000]:
		await _start_at(false)
		game.call("_say", [box_1, wake] as Array[String])
		var seen: Array[String] = [box_1]
		var wake_at: Array[int] = [-1]
		var held: Array[bool] = [false]
		var held_x: Array[float] = [INF]
		# The longest gap between two looks at the box: the wake box can come up that long before it is
		# seen, so the measured time can come out short by that much.
		var last_look: Array[int] = [Time.get_ticks_msec(), 0]
		var log_box: Callable = func() -> void:
			var now: int = Time.get_ticks_msec()
			last_look[1] = maxi(last_look[1], now - last_look[0])
			last_look[0] = now
			var line: String = str(game.get("status_line"))
			if seen.back() != line:
				seen.append(line)
				if line == wake:
					wake_at[0] = Time.get_ticks_msec()
			if not held[0] and bool(game.get("lane_question_held")):
				held[0] = true
				held_x[0] = human.position.x
		var started_at: int = Time.get_ticks_msec()
		while Time.get_ticks_msec() - started_at < wait_ms:
			await process_frame
			log_box.call()
		Input.action_press(&"move_right")
		var asked: bool = await _wait_until(func() -> bool:
			log_box.call()
			return bool(game.get("waiting_for_choice")), 900)
		Input.action_release(&"move_right")
		var wake_ms: int = Time.get_ticks_msec() - wake_at[0]
		var label: String = "walking to the rubble line at once" if wait_ms == 0 else "waiting at the door first"
		_expect(asked and seen.size() >= 2 and seen[seen.size() - 2] == wake and seen.find(wake) == seen.size() - 2 and str(seen.back()).begins_with("WOLF: It passes under that tank"), "%s: the sentry waking is shown before WOLF's question replaces it (seen %s)" % [label, str(seen).c_escape()])
		_expect(wake_at[0] >= 0 and wake_ms >= int(MainScript.box_seconds(wake) * 1000.0) - maxi(50, last_look[1]), "%s: the question waits until that box has been up its reading time (%d ms of %.2f s, frames up to %d ms apart)" % [label, wake_ms, MainScript.box_seconds(wake), last_look[1]])
		# The hold applies in _process, and a slow frame runs up to max_physics_steps_per_frame walk steps
		# before it, so the engineer can stop that far past the line; once held, they must not move on.
		var step: float = M0Actor.WALK_SPEED / float(Engine.physics_ticks_per_second)
		_expect(not held[0] or (held_x[0] <= JunctionRoom.CHOICE_X + Engine.max_physics_steps_per_frame * step + 0.5 and human.position.x <= held_x[0] + step + 0.5), "%s: the engineer holds at the rubble line meanwhile (held at x %.1f, x %.1f)" % [label, held_x[0], human.position.x])
		game.call("_choose_lane", 2)
		await physics_frame
		_expect(human.controlled and not bool(game.get("lane_question_held")), "%s: answering hands the controls back" % label)


## A line that moves the story on drops the boxes still to come of an earlier one: WOLF's "The tank
## takes a moment to fall." never comes back after the clamp lets go or the tank lands on the sentry.
func _check_story_moves_on() -> void:
	var c: Dictionary = (MainScript as GDScript).get_script_constant_map()
	var alone: Array = c["ALONE_LINES"]
	await _start_at(false)
	await _answer_lane(2)
	_expect(str(game.get("status_line")) == alone[0] and game.get("box_queue") == [alone[1]], "answer 2: WOLF's first box, the second to come")
	game.call("_drop_tank")
	_expect(str(game.get("status_line")) == "The clamp lets go." and (game.get("box_queue") as Array).is_empty(), "the clamp letting go drops WOLF's second box")
	await _start_at(false)
	await _answer_lane(2)
	(game.get("sentry_brain") as SentryBrain).x = DropArm.MARK_X
	game.call("_tank_hit")
	var hit: String = str(game.get("status_line"))
	game.call("_advance_box_queue", 30.0)
	_expect(hit.contains("It's down.") and str(game.get("status_line")) == hit and (game.get("box_queue") as Array).is_empty(), "a hit within WOLF's first box stays up; \"%s\" never comes back over the crushed sentry" % str(alone[1]))
	_expect(await _wait_until(func() -> bool: return Engine.time_scale == 1.0, 90), "time scale settles after the hit")


## Item 3 S15 in play: the order to get back over the rubble comes as the sentry swings into its chase,
## while the engineer is still at the release, before it can reach them; back over the rubble before
## it swings, the order is dropped, and it never shows after the sentry has given up or the tank is
## back up.
func _check_miss_boxes() -> void:
	var c: Dictionary = (MainScript as GDScript).get_script_constant_map()
	var miss: String = c["TANK_MISS_LINE"]
	var turn: String = c["TANK_MISS_TURN_LINE"]
	var lost: String = c["SENTRY_LOST_LINE"] % "Rowan"
	var brain: SentryBrain = game.get("sentry_brain") as SentryBrain
	for how: String in ["stay", "back at once", "back after the swing"]:
		await _start_at(false)
		await _answer_lane(2)
		await _place(float(game.call("debug_station_side_x", (c["JUNCTION_STATIONS"] as Array)[2], JunctionRoom.ARM_X + 1.0)), false)
		brain.x = SentryBrain.PATROL_MAX_X
		brain.facing = 1.0
		# A real drop, far from the sentry: the tank misses and the winch has it back up later.
		game.call("_drop_tank")
		_expect(await _wait_until(func() -> bool: return (game.get("drop_arm") as DropArm).state == &"rewinding", 60), "%s: the drop misses" % how)
		if how == "back at once":
			human.position.x = 500.0
		var seen: Array[String] = [str(game.get("status_line"))]
		var turn_ms: Array[int] = [-1]
		var started_at: int = Time.get_ticks_msec()
		var swung: Array[bool] = [false]
		var ended: bool = await _wait_until(func() -> bool:
			var line: String = str(game.get("status_line"))
			if seen.back() != line:
				seen.append(line)
				if line == turn:
					turn_ms[0] = Time.get_ticks_msec() - started_at
			if how == "back after the swing" and line == turn and not swung[0]:
				swung[0] = true
				human.position.x = 500.0
			if how == "stay":
				return bool(game.get("fail_active"))
			return (game.get("drop_arm") as DropArm).state == &"hung" and (game.get("box_queue") as Array).is_empty() and str(game.get("status_line")).contains("back on the clamp"), 1500)
		var turn_at: int = seen.find(turn)
		match how:
			"stay":
				_expect(ended and seen[0] == miss and turn_at == 1, "staying at the release: the miss, then the order to get back over the rubble before the sentry reaches them (seen %s)" % str(seen).c_escape())
				_expect(turn_ms[0] >= 0 and turn_ms[0] <= int((SentryBrain.LOCK_SECONDS + 0.3) * 1000.0), "the order comes as the sentry swings, after its %.1f s lock-on beat (%d ms)" % [SentryBrain.LOCK_SECONDS, turn_ms[0]])
				_expect(await _wait_until(func() -> bool: return not bool(game.get("fail_active")), 300), "the knockdown restores")
			"back at once":
				_expect(ended and seen[0] == miss and turn_at < 0 and seen.has(lost), "back over the rubble before it swings: no stale order, then the sentry giving up (seen %s)" % str(seen).c_escape())
			_:
				_expect(ended and seen[0] == miss and turn_at == 1 and seen.find(lost) > turn_at and seen.rfind(turn) == turn_at, "back over the rubble after it swings: the order once, then the sentry giving up, and the order never again (seen %s)" % str(seen).c_escape())
		_expect(seen.back().contains("back on the clamp") or how == "stay", "%s: the winch's line comes last, after the miss's boxes (seen %s)" % [how, str(seen).c_escape()])


## Walks to the rubble line and answers WOLF's question with [param response].
func _answer_lane(response: int) -> void:
	Input.action_press(&"move_right")
	var asked: bool = await _wait_until(func() -> bool: return bool(game.get("waiting_for_choice")), 300)
	Input.action_release(&"move_right")
	_expect(asked, "WOLF asks at the rubble line")
	game.call("_choose_lane", response)
	await physics_frame
	# The drop arm and the sentry unpause in main's _process; a slow frame can run several physics steps
	# before it (and process_frame comes just before it), so wait until it has run, as a player's next
	# press always does.
	for _frame: int in 10:
		if not (game.get("drop_arm") as DropArm).paused:
			break
		await process_frame


## A fresh run into the junction's entry, as USE at the Records exit makes it (autosave A).
func _enter_fresh_junction() -> void:
	game.call("debug_new_game", true)
	var state: M0State = State.new()
	state.record_choice(State.DISCLOSE)
	state.arm_breaker()
	state.activate_power("wolf")
	state.reach_checkpoint()
	state.enter_records()
	state.preserve_purge_trace()
	state.preserve_mirror_trace("wolf")
	state.complete_chapter()
	game.set("state", state)
	game.call("_sync_scene")
	game.call("_enter_junction")
	await physics_frame
	game.set("box_queue", [] as Array[String])


## Continue at autosave B (door down) or, with [param sentry_down], autosave C.
func _start_at(sentry_down: bool) -> void:
	var state: M0State = State.new()
	state.record_choice(State.DISCLOSE)
	state.arm_breaker()
	state.activate_power("wolf")
	state.reach_checkpoint()
	state.enter_records()
	state.preserve_purge_trace()
	state.preserve_mirror_trace("wolf")
	state.complete_chapter()
	state.enter_junction()
	state.blow_door()
	state.human_position = Vector2(JunctionRoom.CHOICE_X - 30.0, 410.0)
	state.wolf_position = Vector2(JunctionRoom.WOLF_RUBBLE_X, 423.0)
	if sentry_down:
		state.drop_sentry()
		state.lane_recap = "alone"
	_expect(state.save_to_disk(path), "the checkpoint is written")
	game.call("debug_load_checkpoint")
	await physics_frame


## Puts the engineer at [param x] facing left ([param face_left]) or right, with WOLF out of the way.
func _place(x: float, face_left: bool) -> void:
	game.call("debug_place", x, wolf.position.x)
	human.body_sprite.flip_h = face_left
	await physics_frame
	human.position.x = x
	human.body_sprite.flip_h = face_left


## Presses interact at [param station] and checks that [param clip] starts, the station's lamp
## flickers and the box shows [param line] within ANSWER_FRAMES frames; with [param again], that the
## box blinks too.
func _refused(label: String, station: StringName, line: String, clip: StringName, again: bool = false) -> void:
	if not again:
		game.set("status_line", "")
	started.clear()
	var before_alpha: float = bottom_bar.modulate.a
	Input.action_press(&"interact")
	var frames: int = await _frames_until(func() -> bool: return started.has(clip) and room.flickering(station) and str(game.get("status_line")) == line and (not again or bottom_bar.modulate.a < 1.0))
	Input.action_release(&"interact")
	_expect(frames <= ANSWER_FRAMES, "%s: the clunk, %s's lamp flicker and the line (\"%s\") come within %d frames (%d; clips %s, lamp %s, line \"%s\")" % [label, station, line.c_escape(), ANSWER_FRAMES, frames, started, room.flickering(station), str(game.get("status_line")).c_escape()])
	if again:
		_expect(before_alpha == 1.0, "%s: the box blinks once" % label)
	await process_frame
	for _frame: int in 30:
		await process_frame


## Frames (process frames) until [param condition] holds, or ANSWER_FRAMES + 30 if it never does.
func _frames_until(condition: Callable) -> int:
	for frame: int in range(1, ANSWER_FRAMES + 30):
		await process_frame
		if condition.call():
			return frame
	return ANSWER_FRAMES + 30


func _tap(action: StringName) -> void:
	await process_frame
	Input.action_press(action)
	await process_frame
	Input.action_release(action)


func _wait_until(condition: Callable, frames: int) -> bool:
	for _frame: int in range(frames):
		await physics_frame
		if condition.call():
			return true
	return false


func _remove(file: String) -> void:
	if FileAccess.file_exists(file):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("Approved wording check failed: " + label)
