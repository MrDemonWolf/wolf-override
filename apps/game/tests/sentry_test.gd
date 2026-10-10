extends SceneTree
## Blowback beats 4-6: the sentry brain and the drop arm as pure logic, the junction's later guards
## and saves, and the scene routes past the door (WOLF draws the sentry; the engineer times the drop
## alone after WOLF refuses; a miss with its cloud and rewind; sentry and cloud knockdowns back to
## autosave B; the exit bolt, the closing beat and Continue from B, C and D).

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const State = preload("res://scripts/m0_state.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_brain()
	_check_arm()
	_check_state_guards()
	await _check_scene()
	if failures == 0:
		print("Sentry checks passed")
	quit(1 if failures > 0 else 0)


func _check_brain() -> void:
	for x: float in [SentryBrain.LANE_ENTRY_X, SentryBrain.COVER_MIN_X, JunctionRoom.ARM_X, SentryBrain.COVER_MAX_X, 500.0]:
		_expect(not SentryBrain.is_exposed(x), "%.0f is out of the sentry's sight" % x)
	for x: float in [SentryBrain.LANE_ENTRY_X + 1.0, SentryBrain.COVER_MAX_X + 1.0, 700.0]:
		_expect(SentryBrain.is_exposed(x), "%.0f is exposed in the lane" % x)
	_expect(JunctionRoom.RUBBLE_X == SentryBrain.RUBBLE_X and JunctionRoom.CHOICE_X < SentryBrain.LANE_ENTRY_X, "the rubble line is the lane boundary and the question comes up before it")
	var brain: SentryBrain = SentryBrain.new()
	_expect(brain.state == &"dormant" and brain.tick(1.0, 700.0, true, -1.0) == &"dormant" and brain.x == SentryBrain.PATROL_MAX_X, "a dormant sentry neither moves nor sees")
	_expect(brain.wake() and brain.state == &"patrol" and not brain.wake(), "the blast wakes it once")
	brain.tick(1.0, 100.0, false, -1.0)
	_expect(is_equal_approx(brain.x, 700.0) and brain.facing < 0.0, "patrol runs left from the far end at 140 px/s")
	brain.tick(1.0, 100.0, false, -1.0)
	_expect(is_equal_approx(brain.x, SentryBrain.PATROL_MIN_X * 2.0 - 560.0) and brain.facing > 0.0, "it bounces off its near end and comes back")
	_expect(is_equal_approx(SentryBrain.PATROL_MIN_X - SentryBrain.HALF_WIDTH, SentryBrain.COVER_MAX_X + M0State.HUMAN_HALF_WIDTH), "the patrol turns where its front edge meets an engineer at the alcove's right end")
	_expect(SentryBrain.PATROL_MIN_X < DropArm.MARK_X - DropArm.HIT_RANGE and SentryBrain.PATROL_MAX_X > DropArm.MARK_X + DropArm.HIT_RANGE, "the patrol still crosses the whole hit window")
	var sliced: SentryBrain = _patrolling_at(SentryBrain.PATROL_MAX_X, -1.0)
	var whole: SentryBrain = _patrolling_at(SentryBrain.PATROL_MAX_X, -1.0)
	var lowest: float = INF
	var highest: float = -INF
	for _frame: int in 600:
		sliced.tick(5.0 / 600.0, 100.0, false, -1.0)
		lowest = minf(lowest, sliced.x)
		highest = maxf(highest, sliced.x)
	whole.tick(5.0, 100.0, false, -1.0)
	_expect(absf(sliced.x - whole.x) < 0.01 and sliced.facing == whole.facing, "sliced and whole deltas land on the same patrol position")
	_expect(lowest >= SentryBrain.PATROL_MIN_X - 0.01 and highest <= SentryBrain.PATROL_MAX_X + 0.01, "patrol stays inside its range")
	for cover_x: float in [SentryBrain.COVER_MIN_X, JunctionRoom.ARM_X, SentryBrain.COVER_MAX_X]:
		_expect(lowest - cover_x > SentryBrain.CONTACT_RANGE - 0.01, "a patrolling sentry never runs into an engineer hidden at %.0f" % cover_x)
	# Detection: only in the lane, only ahead (or touching), never in the alcove.
	_expect(_patrolling_at(700.0, -1.0).tick(0.001, 600.0, true, -1.0) == &"chase", "an exposed engineer ahead inside its sight is seen")
	_expect(_patrolling_at(840.0, -1.0).tick(0.001, 665.0, true, -1.0) == &"chase", "175 px ahead is inside its sight")
	_expect(_patrolling_at(840.0, -1.0).tick(0.001, 650.0, true, -1.0) == &"patrol", "190 px ahead is past its sight")
	_expect(_patrolling_at(700.0, -1.0).tick(0.001, JunctionRoom.ARM_X, SentryBrain.is_exposed(JunctionRoom.ARM_X), -1.0) == &"patrol", "the alcove hides the engineer")
	_expect(_patrolling_at(700.0, -1.0).tick(0.001, 760.0, true, -1.0) == &"patrol", "behind it and out of reach is unseen")
	_expect(_patrolling_at(700.0, -1.0).tick(0.001, 720.0, true, -1.0) == &"chase", "walking into it from behind is noticed")
	_expect(_patrolling_at(620.0, -1.0).tick(0.001, 530.0, false, -1.0) == &"patrol", "an engineer back over the rubble is never seen")
	# Chase.
	var chaser: SentryBrain = _patrolling_at(700.0, -1.0)
	chaser.tick(0.001, 600.0, true, -1.0)
	var start_x: float = chaser.x
	chaser.tick(0.1, 600.0, true, -1.0)
	_expect(is_equal_approx(start_x - chaser.x, SentryBrain.CHASE_SPEED * 0.1), "a chase closes at 230 px/s")
	_expect(not chaser.touches(600.0) or absf(chaser.x - 600.0) <= SentryBrain.CONTACT_RANGE, "contact needs the bodies to meet")
	chaser.tick(5.0, SentryBrain.LANE_ENTRY_X + 1.0, true, -1.0)
	_expect(chaser.state == &"chase" and chaser.x == SentryBrain.CHASE_MIN_X and chaser.x > SentryBrain.RUBBLE_X, "it never comes past its rubble stop")
	_expect(chaser.touches(JunctionRoom.ARM_X), "a chasing sentry reaches the panel alcove")
	_expect(not chaser.touches(SentryBrain.RUBBLE_X), "an engineer back on the rubble line is out of its reach")
	chaser.tick(2.0, 500.0, false, -1.0)
	chaser.tick(0.1, 560.0, false, -1.0)
	chaser.tick(2.0, 500.0, false, -1.0)
	_expect(chaser.state == &"chase", "stepping back into the lane restarts the 2.5 s it needs to give up")
	chaser.tick(0.4, 500.0, false, -1.0)
	_expect(chaser.state == &"chase", "2.4 s back over the rubble it is still after the engineer")
	chaser.tick(0.1, 500.0, false, -1.0)
	_expect(chaser.state == &"patrol", "2.5 s back over the rubble and it gives up")
	var parked_x: float = chaser.x
	chaser.tick(0.02, 500.0, false, -1.0)
	_expect(chaser.facing > 0.0 and is_equal_approx(chaser.x - parked_x, SentryBrain.PATROL_SPEED * 0.02), "after a chase it turns and walks back into its patrol instead of jumping")
	var walk_back_sliced: SentryBrain = _patrolling_at(SentryBrain.CHASE_MIN_X, -1.0)
	var walk_back_whole: SentryBrain = _patrolling_at(SentryBrain.CHASE_MIN_X, -1.0)
	for _frame: int in 300:
		walk_back_sliced.tick(3.0 / 300.0, 500.0, false, -1.0)
	walk_back_whole.tick(3.0, 500.0, false, -1.0)
	_expect(absf(walk_back_sliced.x - walk_back_whole.x) < 0.01 and walk_back_sliced.facing == walk_back_whole.facing, "walking back in lands the same with sliced and whole deltas")
	_expect(not _patrolling_at(700.0, -1.0).touches(700.0), "a patrolling sentry is not contact")
	# Fixated on WOLF.
	var fixated: SentryBrain = _patrolling_at(SentryBrain.PATROL_MAX_X, -1.0)
	_expect(fixated.tick(0.1, 100.0, false, JunctionRoom.WOLF_BAIT_X) == &"fixated", "WOLF drawing it fixates it")
	fixated.tick(2.0, 100.0, false, JunctionRoom.WOLF_BAIT_X)
	_expect(is_equal_approx(fixated.x, JunctionRoom.WOLF_BAIT_X - SentryBrain.BAIT_OFFSET) and is_equal_approx(fixated.x, DropArm.MARK_X) and fixated.facing > 0.0, "it parks short of WOLF, on the floor mark, facing him")
	fixated.tick(1.0, 600.0, true, JunctionRoom.WOLF_BAIT_X)
	_expect(fixated.state == &"fixated" and is_equal_approx(fixated.x, DropArm.MARK_X), "an engineer elsewhere in the lane does not break its hold")
	_expect(JunctionRoom.WOLF_BAIT_X - M0State.WOLF_HALF_WIDTH >= fixated.x + SentryBrain.HALF_WIDTH, "the parked sentry does not overlap WOLF")
	_expect(JunctionRoom.WOLF_BAIT_X - M0State.WOLF_HALF_WIDTH > DropArm.MARK_X + JunctionRoom.TANK_SIZE.x * 0.5, "WOLF stands clear of the tank's footprint")
	var from_left: SentryBrain = _patrolling_at(SentryBrain.PATROL_MIN_X, 1.0)
	from_left.tick(2.0, 100.0, false, JunctionRoom.WOLF_BAIT_X)
	_expect(is_equal_approx(from_left.x, DropArm.MARK_X), "it parks on the mark from either side")
	_expect(fixated.tick(0.001, 690.0, true, JunctionRoom.WOLF_BAIT_X) == &"chase", "walking into a fixated sentry breaks its hold")
	var released: SentryBrain = _patrolling_at(SentryBrain.PATROL_MAX_X, -1.0)
	released.tick(0.1, 100.0, false, JunctionRoom.WOLF_BAIT_X)
	_expect(released.tick(0.1, 100.0, false, -1.0) == &"patrol", "when WOLF stops drawing it, it patrols again")
	# Down and paused.
	var down: SentryBrain = _patrolling_at(700.0, -1.0)
	_expect(down.knock_down() and not down.knock_down() and not down.wake() and not down.alert(), "the tank downs it once and nothing wakes it")
	_expect(down.tick(1.0, 700.0, true, JunctionRoom.WOLF_BAIT_X) == &"down" and down.x == 700.0 and not down.touches(700.0), "a downed sentry ignores everything")
	var paused: SentryBrain = _patrolling_at(700.0, -1.0)
	paused.paused = true
	_expect(paused.tick(1.0, 600.0, true, JunctionRoom.WOLF_BAIT_X) == &"patrol" and paused.x == 700.0, "a paused sentry neither moves nor sees")
	var alerted: SentryBrain = _patrolling_at(800.0, -1.0)
	_expect(alerted.alert() and alerted.state == &"chase", "a missed drop turns it on the engineer")
	alerted.reset(true, false, DropArm.MARK_X)
	_expect(alerted.state == &"patrol" and alerted.x == SentryBrain.PATROL_MAX_X and alerted.facing < 0.0, "reset after the blast patrols from the far end")
	alerted.reset(false, false, DropArm.MARK_X)
	_expect(alerted.state == &"dormant", "reset before the blast is dormant")
	alerted.reset(true, true, DropArm.MARK_X)
	_expect(alerted.state == &"down" and alerted.x == DropArm.MARK_X, "reset after the drop lies on the mark")


func _check_arm() -> void:
	_expect(DropArm.is_hit(DropArm.MARK_X - 44.0) and DropArm.is_hit(DropArm.MARK_X + 44.0) and not DropArm.is_hit(DropArm.MARK_X - 45.0) and not DropArm.is_hit(DropArm.MARK_X + 45.0), "the hit window is the mark +/- 44 px")
	var arm: DropArm = DropArm.new()
	_expect(arm.state == &"hung" and arm.drop_amount() == 0.0 and arm.advance(1.0, 700.0) == &"", "a hung tank waits")
	_expect(arm.drop() and arm.state == &"falling" and not arm.drop(), "the clamp lets go once")
	_expect(arm.advance(0.44, 700.0) == &"" and arm.drop_amount() > 0.5 and arm.drop_amount() < 1.0, "0.44 s into the fall it is still falling")
	_expect(arm.advance(0.02, DropArm.MARK_X + 44.0) == &"hit" and arm.state == &"landed" and arm.drop_amount() == 1.0, "it lands at 0.45 s on a sentry at the edge of the mark")
	_expect(not arm.drop() and arm.advance(10.0, 700.0) == &"", "a landed tank is final")
	var sliced: DropArm = DropArm.new()
	sliced.drop()
	var event: StringName = &""
	var frames: int = 0
	while event.is_empty() and frames < 100:
		event = sliced.advance(1.0 / 60.0, 800.0)
		frames += 1
	_expect(event == &"miss" and frames == 27, "sliced into frames the fall still takes 0.45 s")
	var miss: DropArm = DropArm.new()
	miss.drop()
	_expect(miss.advance(0.45, DropArm.MARK_X + 45.0) == &"miss" and miss.state == &"rewinding" and miss.cloud_active() and miss.drop_amount() == 1.0, "a miss starts the rewind and vents the cloud")
	_expect(not miss.drop(), "a second drop during the rewind is refused")
	miss.advance(2.9, 0.0)
	_expect(miss.cloud_active() and miss.state == &"rewinding", "the cloud lasts 3 s")
	miss.advance(0.2, 0.0)
	_expect(not miss.cloud_active() and miss.state == &"rewinding" and miss.drop_amount() < 1.0 and miss.drop_amount() > 0.0, "the cloud clears while the winch keeps hauling")
	_expect(miss.advance(2.8, 0.0) == &"" and miss.state == &"rewinding", "5.9 s in the tank is not back yet")
	_expect(miss.advance(0.2, 0.0) == &"rehung" and miss.state == &"hung" and miss.drop_amount() == 0.0, "the rewind finishes at 6 s and re-hangs the tank")
	_expect(miss.drop(), "a re-hung tank can drop again")
	var paused: DropArm = DropArm.new()
	paused.paused = true
	_expect(not paused.drop(), "a paused arm refuses to drop")
	paused.paused = false
	paused.drop()
	paused.paused = true
	_expect(paused.advance(1.0, 700.0) == &"" and paused.state == &"falling", "a paused fall holds")
	paused.reset(true)
	_expect(paused.state == &"landed" and paused.drop_amount() == 1.0 and not paused.paused, "reset after the drop is landed")
	_expect(DropArm.in_cloud(DropArm.MARK_X + DropArm.CLOUD_HALF_WIDTH + M0State.HUMAN_HALF_WIDTH) and not DropArm.in_cloud(DropArm.MARK_X + DropArm.CLOUD_HALF_WIDTH + M0State.HUMAN_HALF_WIDTH + 1.0), "the cloud reaches an engineer whose body touches it")


func _check_state_guards() -> void:
	var state: M0State = _completed_records_state(State.DISCLOSE)
	_expect(not state.drop_sentry() and not state.clear_junction(), "nothing in the lane happens outside the junction")
	state.enter_junction()
	_expect(not state.drop_sentry() and not state.clear_junction(), "the sentry cannot go down before the door")
	state.blow_door()
	_expect(not state.clear_junction(), "the junction cannot clear with the sentry live")
	_expect(state.drop_sentry() and not state.drop_sentry() and state.sentry_down, "the sentry goes down once")
	_expect(state.clear_junction() and not state.clear_junction() and state.junction_cleared, "the junction clears once")
	var round_trip: M0State = State.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	_expect(round_trip != null and round_trip.junction_cleared and round_trip.sentry_down and round_trip.door_blown, "a cleared junction round-trips through JSON")
	_expect(state.wolf_will_bait() and not _completed_records_state(State.PRESS).wolf_will_bait(), "WOLF offers to draw the sentry only with the relay risk disclosed")


func _check_scene() -> void:
	var path: String = "user://sentry-test-%s.json" % OS.get_process_id()
	_remove(path)
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	game.set("settings_path", "%s-settings.cfg" % path)
	root.add_child(game)
	await process_frame
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	var camera: Camera2D = game.get_node("IntroCamera") as Camera2D
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var brain: SentryBrain = game.get("sentry_brain") as SentryBrain
	var arm: DropArm = game.get("drop_arm") as DropArm
	var touch_use: Button = game.get_node("CanvasLayer/TouchControls/Use") as Button
	var touch_choice_1: Button = game.get_node("CanvasLayer/TouchControls/Choice1") as Button
	var continue_button: Button = game.get_node("CanvasLayer/TitleScreen/ContinueButton") as Button
	if not _require(room != null and brain != null and arm != null and room.sentry != null and room.sentry.get_node_or_null("Visual") != null, "Main builds the sentry with its drawing in one Visual child"):
		return
	_expect(room.sentry.collision_layer == 0 and room.sentry.collision_mask == 0, "the sentry body never pushes or blocks the actors")
	game.call("_new_game")
	game.call("_finish_intro")
	# Route 1: the relay risk was disclosed, so WOLF chooses to draw the sentry onto the mark.
	var b_dict: Dictionary = await _start_at_b(game, State.DISCLOSE)
	_expect(brain.state == &"patrol" and brain.x > SentryBrain.PATROL_MAX_X - 60.0 and brain.facing < 0.0 and arm.state == &"hung" and room.tank.position.y == JunctionRoom.TANK_REST_Y, "autosave B: the sentry patrols from the far end under a hung tank")
	_expect(game.call("_objective") == "DROP THE TANK", "the objective is the tank")
	game.call("_load_game")
	_expect((game.get("state") as M0State).door_blown and brain.state == &"patrol" and brain.x == SentryBrain.PATROL_MAX_X and str(game.get("status_line")).contains("door is down"), "Continue from autosave B restores the live lane")
	_expect(await _walk_until_choice(game), "stepping onto the rubble line brings up the question")
	_expect(game.get("choice_context") == "lane" and human.position.x < SentryBrain.LANE_ENTRY_X and not human.controlled, "the question comes up before the engineer is in the lane")
	_expect(touch_choice_1.visible and touch_choice_1.text.contains("Draw it under the arm"), "the answers are on screen")
	# The tank WOLF is asking about hangs in view below the answers in both layouts at the play framing.
	var touch_choice_2: Button = game.get_node("CanvasLayer/TouchControls/Choice2") as Button
	var tank_top_screen: float = (room.tank.position.y - JunctionRoom.TANK_SIZE.y * 0.5 - camera.position.y) * camera.zoom.y + 270.0
	for touch_layout: bool in [false, true]:
		game.set("touch_enabled", touch_layout)
		game.call("_refresh_ui")
		var answers_bottom: float = maxf(touch_choice_1.get_global_rect().end.y, touch_choice_2.get_global_rect().end.y)
		_expect(is_equal_approx(camera.zoom.y, 1.35) and tank_top_screen >= answers_bottom + 8.0, "the hanging tank sits below the %s answers (tank top %.0f, answers end %.0f)" % ["touch" if touch_layout else "keyboard", tank_top_screen, answers_bottom])
	game.set("touch_enabled", false)
	game.call("_refresh_ui")
	_expect(JunctionRoom.TANK_REST_Y + JunctionRoom.TANK_SIZE.y * 0.5 <= Sentry.FLOOR_Y - Sentry.DRAWN_HEIGHT - 8.0, "the hung tank clears the patrolling sentry's mast")
	var frozen_x: float = brain.x
	for _frame: int in 20:
		await physics_frame
	_expect(brain.x == frozen_x and arm.state == &"hung", "the sentry does not move while the question is open")
	await _tap(&"pause_game")
	_expect(paused, "pause works during the lane question")
	(game.get_node("CanvasLayer/PauseOverlay") as PauseOverlay).resume_requested.emit()
	_expect(not paused and game.get("waiting_for_choice"), "resume returns to the open question")
	await _tap(&"choice_1")
	_expect(game.get("wolf_baiting") and game.get("lane_choice") == "wolf" and wolf.autonomous_target_x == JunctionRoom.WOLF_BAIT_X and str(game.get("status_line")).begins_with("WOLF: I'll draw it"), "with the risk disclosed WOLF chooses to draw it")
	_expect(await _wait_until(func() -> bool: return brain.state == &"fixated" and absf(brain.x - DropArm.MARK_X) <= 0.5 and absf(wolf.position.x - JunctionRoom.WOLF_BAIT_X) <= 4.0, 300), "WOLF holds past the mark and the sentry parks on it")
	_expect(absf(room.sentry.position.x - brain.x) <= 4.0, "the sentry body follows its brain (%.1f vs %.1f)" % [room.sentry.position.x, brain.x])
	_expect(await _walk_to(human, JunctionRoom.ARM_X), "the engineer crosses to the panel")
	_expect(not game.get("fail_active") and brain.state == &"fixated", "crossing while it holds on WOLF is safe")
	_expect(str(game.call("_context_hint")).contains("drop the tank"), "the panel offers the drop")
	game.set("touch_enabled", true)
	game.call("_refresh_ui")
	_expect(touch_use.text == "DROP", "touch relabels USE to DROP at the panel")
	game.set("touch_enabled", false)
	game.call("_refresh_ui")
	await _tap(&"interact")
	_expect(arm.state == &"falling", "USE at the panel lets the tank go")
	_expect(await _wait_until(func() -> bool: return (game.get("state") as M0State).sentry_down, 60), "the tank lands on the parked sentry")
	_expect(brain.state == &"down" and room.sentry_down and room.arm_label.text == "TANK DOWN" and room.coolant_burst.emitting and room.hit_sparks.emitting, "the hit is a real state change with coolant and sparks")
	await physics_frame
	_check_crushed(room, brain, "the hit")
	_expect(game.call("_objective") == "POP THE EXIT BOLT" and not game.get("wolf_baiting") and wolf.follow_target == human, "the bolt is next and WOLF follows again")
	var autosave_c: M0State = State.load_from_disk(path)
	_expect(autosave_c != null and autosave_c.sentry_down and autosave_c.door_blown and autosave_c.memory.get("choice_id") == State.DISCLOSE, "autosave C records the sentry down with the relay memory")
	_expect(await _wait_until(func() -> bool: return Engine.time_scale == 1.0 and camera.offset == Vector2.ZERO, 90), "time scale and camera settle after BOOM 2")
	game.call("_load_game")
	_expect(brain.state == &"down" and brain.x == DropArm.MARK_X and arm.state == &"landed" and room.sentry.visual.wrecked and room.tank.position.y > JunctionRoom.TANK_REST_Y and str(game.get("status_line")).contains("sentry is down"), "Continue from autosave C shows the sentry down under the tank")
	_check_crushed(room, brain, "Continue from autosave C")
	_expect(await _walk_to(human, JunctionRoom.BOLT_X), "the engineer reaches the exit bolt")
	_expect(str(game.call("_context_hint")).contains("pop the exit bolt"), "the bolt panel offers USE")
	await _tap(&"interact")
	_expect(game.get("bolt_state") == &"charging", "USE starts the bolt's whine")
	for _frame: int in 12:
		await physics_frame
	_expect(game.get("bolt_state") == &"charging" and room.bolt_charge > 0.0 and room.bolt_charge < 1.0, "the whine rises before the arc")
	_expect(await _wait_until(func() -> bool: return game.get("bolt_state") == &"open", 60), "the bolt arcs after the whine")
	_expect(room.hatch_label.text == "EXIT OPEN" and room.bolt_sparks.emitting and (game.get("impact") as Impact).trauma > 0.0, "the arc throws sparks, shakes the view and opens the exit")
	_expect(await _wait_until(func() -> bool: return room.hatch_open >= 1.0 and Engine.time_scale == 1.0, 60), "the hatch slides open")
	await _tap(&"interact")
	var state: M0State = game.get("state") as M0State
	_expect(state.junction_cleared and game.get("chapter_close_active") and not human.controlled and (game.get_node("CanvasLayer/TopBar/HUD") as Label).text.contains("SERVICE LINE CLEARED"), "USE at the open hatch clears the junction into a closing beat")
	var autosave_d: M0State = State.load_from_disk(path)
	_expect(autosave_d != null and autosave_d.junction_cleared, "autosave D records the cleared junction")
	await create_timer(0.6).timeout
	_expect(_close_cuts_no_label(camera, room), "the closing shot cuts no junction label at its edges")
	await _tap(&"pause_game")
	_expect(paused, "pause works during the closing beat")
	(game.get_node("CanvasLayer/PauseOverlay") as PauseOverlay).resume_requested.emit()
	await _tap(&"interact")
	_expect(game.get("title_open") and (game.get_node("CanvasLayer/TitleScreen") as Control).visible and not game.get("chapter_close_active"), "the closing beat returns to the title")
	_expect(not continue_button.disabled, "Continue is offered after the junction")
	continue_button.pressed.emit()
	await physics_frame
	state = game.get("state") as M0State
	_expect(not game.get("title_open") and state.chapter_id == "junction" and state.junction_cleared and room.visible and room.hatch_open == 1.0 and game.get("bolt_state") == &"open" and human.controlled and not game.get("chapter_close_active"), "Continue from autosave D restores the cleared junction")
	_expect(game.call("_objective") == "SERVICE LINE CLEARED" and str(game.get("status_line")).contains("line is clear"), "the restored junction says the line is clear")
	await _tap(&"interact")
	_expect(not game.get("chapter_close_active") and str(game.get("status_line")).contains("not built yet"), "the open hatch says the line beyond is not built yet")
	# WOLF breaks off after a miss while drawing the sentry.
	await _start_at_b(game, State.DISCLOSE)
	_expect(await _walk_until_choice(game), "the question comes up again on a new attempt")
	await _tap(&"choice_1")
	_expect(await _wait_until(func() -> bool: return brain.state == &"fixated", 120), "WOLF is drawing the sentry")
	game.call("_tank_miss")
	_expect(not game.get("wolf_baiting") and game.get("wolf_broke_off") and wolf.autonomous_target_x == JunctionRoom.WOLF_RUBBLE_X and brain.state == &"chase", "after a miss WOLF breaks off to the rubble and the sentry turns")
	_expect(str(game.get("status_line")).contains("WOLF: I'm out"), "WOLF says he is breaking off")
	human.position.x = 500.0
	await physics_frame
	_expect(str(game.call("_context_hint")).contains("until it gives up"), "back over the rubble the hint says to wait out the chase")
	_expect(await _wait_until(func() -> bool: return brain.state == &"patrol", 200), "the chase ends with the engineer over the rubble")
	_expect(str(game.call("_context_hint")).contains("WOLF has broken off"), "then the hint says WOLF has stepped back")
	await _check_engineer_alone(game, path)
	await _check_cloud(game, path)
	# A crafted v4 save with the sentry down but the door still sealed is rejected.
	var crafted: Dictionary = b_dict.duplicate(true)
	crafted["positions"]["human"] = [120.0, 410.0]
	crafted["positions"]["wolf"] = [64.0, 423.0]
	crafted["door_blown"] = false
	_write(path, crafted)
	_expect(State.load_from_disk(path) != null, "the crafted save's positions and flags are otherwise valid")
	crafted["sentry_down"] = true
	_write(path, crafted)
	_expect(State.load_from_disk(path) == null, "a v4 save with the sentry down but the door sealed is rejected")
	game.call("_pause_game")
	(game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton") as Button).pressed.emit()
	_expect(continue_button.disabled and (game.get_node("CanvasLayer/TitleScreen/ContinueNote") as Label).text == "Saved checkpoint could not be read.", "the title refuses to continue from it")
	_remove(path)
	_remove("%s-settings.cfg" % path)
	game.queue_free()
	await create_timer(0.1).timeout
	_expect(Engine.time_scale == 1.0, "freeing the game leaves time_scale at 1.0")


## WOLF refuses with the PRESS memory; the sentry runs the engineer down once (back to autosave B
## with the memory intact); then the engineer misses, retreats, waits out the rewind and times a hit.
func _check_engineer_alone(game: Node2D, path: String) -> void:
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var brain: SentryBrain = game.get("sentry_brain") as SentryBrain
	var arm: DropArm = game.get("drop_arm") as DropArm
	var b_dict: Dictionary = await _start_at_b(game, State.PRESS)
	var b_bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	_expect(await _walk_until_choice(game), "the PRESS route gets the same question")
	await _tap(&"choice_1")
	var refusal: String = str(game.get("status_line"))
	_expect(game.get("lane_choice") == "refused" and not game.get("wolf_baiting") and wolf.autonomous_target_x == JunctionRoom.WOLF_RUBBLE_X, "with the risk withheld WOLF refuses to draw it")
	_expect(refusal.begins_with("WOLF: No.") and refusal.contains("time the drop") and not refusal.contains("blind") and not refusal.contains("You said"), "his refusal points at the engineer's way through without blame")
	for _frame: int in 60:
		await physics_frame
	_expect(wolf.position.x <= JunctionRoom.WOLF_RUBBLE_X + 6.0 and brain.state == &"patrol", "WOLF stays at the rubble and the sentry keeps patrolling")
	# Step into its path: it sees, chases and runs the engineer down.
	_expect(await _wait_until(func() -> bool: return brain.facing < 0.0 and brain.x <= 780.0 and brain.x >= 720.0, 300), "the sentry comes back down the lane")
	human.position.x = 640.0
	_expect(await _wait_until(func() -> bool: return game.get("fail_active"), 60), "sentry contact in the lane is a knockdown")
	_expect(str(game.get("status_line")).begins_with(JunctionRoom.SENTRY_REASON.left(20)), "the status line names the sentry")
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "the knockdown hands back")
	var state: M0State = game.get("state") as M0State
	_expect(FileAccess.get_file_as_bytes(path) == b_bytes and state.to_dict() == b_dict and state.memory.get("choice_id") == State.PRESS, "it restores autosave B with the relay memory intact and saves nothing")
	_expect(brain.state == &"patrol" and brain.x > SentryBrain.PATROL_MAX_X - 60.0 and arm.state == &"hung" and game.get("lane_choice") == "" and human.controlled, "the restore puts the sentry back at the far end under a hung tank")
	_expect(await _wait_until(func() -> bool: return Engine.time_scale == 1.0 and (game.get_node("IntroCamera") as Camera2D).offset == Vector2.ZERO, 90), "time scale and camera are at rest after the restore")
	_expect(await _walk_until_choice(game), "the question comes up again after the restore")
	await _tap(&"choice_2")
	_expect(game.get("lane_choice") == "alone" and str(game.get("status_line")).contains("hold at the rubble"), "answer 2 leaves the drop to the engineer")
	_expect(await _cross_to_panel(game), "the engineer slips into the alcove behind the sentry")
	for _frame: int in 240:
		await physics_frame
	_expect(not game.get("fail_active") and brain.state == &"patrol", "a full patrol passes the alcove without seeing the engineer")
	# A miss: drop while it is at the far end.
	_expect(await _wait_until(func() -> bool: return brain.x >= 830.0, 300), "the sentry reaches the far end")
	await _tap(&"interact")
	_expect(await _wait_until(func() -> bool: return arm.state == &"rewinding", 60), "the drop misses")
	_expect(arm.cloud_active() and room.coolant_cloud.emitting and room.tank.dented and brain.state == &"chase" and room.arm_label.text == "ARM REWINDING", "a miss dents the tank, vents the cloud and turns the sentry on the panel")
	_expect(arm.drop_amount() > 0.99 and room.tank.position.y + JunctionRoom.TANK_SIZE.y * 0.5 > Sentry.FLOOR_Y - 1.0, "a missed tank comes down to the floor, not to the sentry's height")
	await physics_frame
	_expect(room.cloud_hazard.armed, "the cloud's hurtbox is live while it vents")
	await _tap(&"interact")
	_expect(arm.state == &"rewinding" and str(game.get("status_line")).contains("still hauling"), "the panel refuses a second drop during the rewind")
	_expect(await _walk_to(human, 500.0), "the engineer retreats over the rubble")
	_expect(not game.get("fail_active"), "getting back over the rubble in time avoids the knockdown")
	_expect(await _wait_until(func() -> bool: return brain.state == &"patrol", 200), "the sentry gives up and patrols again")
	_expect(await _wait_until(func() -> bool: return not arm.cloud_active() and not room.cloud_hazard.armed, 200), "the cloud clears")
	_expect(await _wait_until(func() -> bool: return arm.state == &"hung", 400), "the rewind re-hangs the tank")
	# The timed hit: tap as it closes on the mark, leading it by the 0.45 s fall.
	_expect(await _cross_to_panel(game), "the engineer is back in the alcove")
	var lead: float = SentryBrain.PATROL_SPEED * DropArm.FALL_SECONDS
	_expect(await _wait_until(func() -> bool: return brain.facing < 0.0 and brain.x <= DropArm.MARK_X + lead + 8.0 and brain.x >= DropArm.MARK_X + lead - 8.0, 400), "the sentry comes toward the mark")
	await _tap(&"interact")
	_expect(await _wait_until(func() -> bool: return (game.get("state") as M0State).sentry_down, 60), "a drop timed on the patrol lands on it")
	await physics_frame
	_check_crushed(room, brain, "the timed hit")
	var autosave_c: M0State = State.load_from_disk(path)
	_expect(autosave_c != null and autosave_c.sentry_down and autosave_c.memory.get("choice_id") == State.PRESS, "the engineer-only route writes autosave C too")


## The landed tank rests on the crushed hull of a wreck pinned under the mark, so the wreck's treads
## and hull show below it and past both of its sides.
func _check_crushed(room: JunctionRoom, brain: SentryBrain, label: String) -> void:
	var tank_base: float = room.tank.position.y + JunctionRoom.TANK_SIZE.y * 0.5
	var wreck: Sprite2D = room.sentry.visual.wreck
	# Measured where the wreck settles: keel_over drops it the last few pixels onto its treads.
	var wreck_rect: Rect2 = wreck.get_global_transform() * wreck.get_rect()
	wreck_rect.position.y -= room.sentry.visual.position.y
	_expect(is_equal_approx(brain.x, DropArm.MARK_X) and absf(room.sentry.position.x - DropArm.MARK_X) < 0.01, "%s: the wreck is pinned on the mark under the tank" % label)
	_expect(is_equal_approx(room.tank.position.y, JunctionRoom.landed_tank_y(true)) and absf(tank_base - (Sentry.FLOOR_Y - Sentry.WRECK_CRUSH_HEIGHT)) < 0.01, "%s: the tank rests on the crushed hull (base y %.1f), not on the floor" % [label, tank_base])
	_expect(Sentry.WRECK_CRUSH_HEIGHT >= 20.0 and is_equal_approx(wreck_rect.end.y, Sentry.FLOOR_Y) and wreck_rect.end.y - tank_base >= 20.0, "%s: at least 20 px of the wreck shows under the tank, down to the floor" % label)
	_expect(wreck_rect.position.x < DropArm.MARK_X - JunctionRoom.TANK_SIZE.x * 0.5 and wreck_rect.end.x > DropArm.MARK_X + JunctionRoom.TANK_SIZE.x * 0.5, "%s: the wreck shows past both sides of the tank" % label)


## The coolant cloud is its own knockdown back to autosave B.
func _check_cloud(game: Node2D, path: String) -> void:
	var human: M0Actor = game.get_node("Human") as M0Actor
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var brain: SentryBrain = game.get("sentry_brain") as SentryBrain
	var arm: DropArm = game.get("drop_arm") as DropArm
	var b_dict: Dictionary = await _start_at_b(game, State.DISCLOSE)
	# Isolate the cloud: no sentry in play and the lane question already answered, a real miss from
	# the arm, then walk into the vapour.
	brain.state = &"dormant"
	game.set("lane_choice", "alone")
	arm.drop()
	arm.advance(DropArm.FALL_SECONDS, 0.0)
	_expect(arm.cloud_active(), "a forced miss vents the cloud")
	await physics_frame
	_expect(room.cloud_hazard.armed and room.coolant_cloud.emitting, "the cloud arms its hurtbox")
	human.position.x = DropArm.MARK_X
	_expect(await _wait_until(func() -> bool: return game.get("fail_active"), 30), "walking into the coolant cloud is a knockdown")
	_expect(str(game.get("status_line")).begins_with("The coolant cloud caught you"), "the status line names the cloud")
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "the cloud knockdown hands back")
	_expect((game.get("state") as M0State).to_dict() == b_dict and not arm.cloud_active() and not room.cloud_hazard.armed and brain.state == &"patrol", "it restores autosave B with the cloud gone")


## Autosave B: the door is down, the engineer just left of the old door line, WOLF at the rubble.
func _start_at_b(game: Node2D, choice_id: String) -> Dictionary:
	var state: M0State = _completed_records_state(choice_id)
	state.enter_junction()
	state.blow_door()
	state.human_position = Vector2(400.0, 410.0)
	state.wolf_position = Vector2(JunctionRoom.WOLF_RUBBLE_X, 423.0)
	game.set("state", state)
	game.call("_sync_scene")
	game.call("_start_gameplay_camera")
	game.call("_save_progress")
	await physics_frame
	return State.load_from_disk(game.get("save_path")).to_dict()


## True when neither edge of the settled closing shot falls inside a station label or the painted
## RELIEF VENT caption.
func _close_cuts_no_label(camera: Camera2D, room: JunctionRoom) -> bool:
	var half_width: float = 480.0 / camera.zoom.x
	var edges: Array[float] = [camera.position.x - half_width, camera.position.x + half_width]
	var font: Font = room.caption_font()
	var vent_start: float = JunctionRoom.VENT_LABEL_POSITION.x
	var spans: Array[Vector2] = [Vector2(vent_start, vent_start + font.get_string_size(JunctionRoom.VENT_LABEL, HORIZONTAL_ALIGNMENT_LEFT, -1, JunctionRoom.VENT_LABEL_FONT_SIZE).x)]
	for child: Node in room.get_children():
		var label: Label = child as Label
		if label == null or not label.visible:
			continue
		var text_width: float = label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		var centre: float = label.position.x + label.size.x * 0.5
		spans.append(Vector2(centre - text_width * 0.5, centre + text_width * 0.5))
	for edge: float in edges:
		for span: Vector2 in spans:
			if edge > span.x - 4.0 and edge < span.y + 4.0:
				push_error("the closing edge at x %.1f cuts a label spanning %.1f..%.1f" % [edge, span.x, span.y])
				return false
	return true


func _walk_until_choice(game: Node2D) -> bool:
	Input.action_press(&"move_right")
	var asked: bool = await _wait_until(func() -> bool: return game.get("waiting_for_choice"), 300)
	Input.action_release(&"move_right")
	return asked


## Waits until the sentry is heading away on the far side, then walks into the alcove.
func _cross_to_panel(game: Node2D) -> bool:
	var brain: SentryBrain = game.get("sentry_brain") as SentryBrain
	var human: M0Actor = game.get_node("Human") as M0Actor
	if not await _wait_until(func() -> bool: return brain.state == &"patrol" and brain.facing > 0.0 and brain.x >= 700.0, 400):
		return false
	return await _walk_to(human, JunctionRoom.ARM_X) and not game.get("fail_active")


func _patrolling_at(x: float, facing: float) -> SentryBrain:
	var brain: SentryBrain = SentryBrain.new()
	brain.wake()
	brain.x = x
	brain.facing = facing
	return brain


func _completed_records_state(choice_id: String) -> M0State:
	var state: M0State = State.new()
	state.record_choice(choice_id)
	state.arm_breaker()
	state.activate_power("wolf" if choice_id == State.DISCLOSE else "human")
	state.reach_checkpoint()
	state.enter_records()
	state.preserve_purge_trace()
	state.preserve_mirror_trace("wolf" if choice_id == State.DISCLOSE else "manual")
	state.complete_chapter()
	state.human_position = Vector2(830.0, 410.0)
	state.wolf_position = Vector2(766.0, 423.0)
	return state


func _write(path: String, data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _tap(action: StringName) -> void:
	await process_frame
	if action == &"pause_game":
		# Pause is event-driven, so send a real input event.
		Input.parse_input_event(_action_event(action, true))
		await process_frame
		Input.parse_input_event(_action_event(action, false))
		return
	Input.action_press(action)
	await process_frame
	Input.action_release(action)


func _action_event(action: StringName, pressed: bool) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


func _wait_until(condition: Callable, frames: int) -> bool:
	for _frame: int in range(frames):
		await physics_frame
		if condition.call():
			return true
	return false


func _walk_to(actor: M0Actor, target_x: float) -> bool:
	var action: StringName = &"move_right" if target_x > actor.position.x else &"move_left"
	Input.action_press(action)
	var reached: bool = false
	for _frame: int in range(300):
		await physics_frame
		if absf(actor.position.x - target_x) <= 12.0:
			reached = true
			break
	Input.action_release(action)
	return reached


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("Sentry check failed: " + label)


func _require(condition: bool, label: String) -> bool:
	_expect(condition, label)
	if not condition:
		quit(1)
	return condition
