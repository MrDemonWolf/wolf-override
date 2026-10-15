extends SceneTree
## The rooms' light: the lamp flicker's random rhythm (never faster than 3 blinks a second, gentler
## with Reduced Motion), lockdown beacons that settle once a room's route is cleared and come back
## the same way on Continue, hidden rooms that stop their dust and light tweens, and a sentry beam
## drawn as far as the sentry actually sees, broken over the alcove where it cannot.

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const State = preload("res://scripts/m0_state.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_flicker_plan()
	_check_beam_rule()
	await _check_scene()
	if failures == 0:
		print("Room lights checks passed")
	quit(1 if failures > 0 else 0)


## Many sampled flickers: each waits 4-15 s, dips and recovers; a double blink starts its second dip
## at least a third of a second after the first; Reduced Motion is one shallower, slower dip.
func _check_flicker_plan() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 2026
	var doubles: int = 0
	var singles: int = 0
	var shortest_wait: float = INF
	var longest_wait: float = 0.0
	var fastest_spacing: float = INF
	for _sample: int in 2000:
		var steps: Array[Vector2] = RoomDepth.flicker_steps(rng, false)
		shortest_wait = minf(shortest_wait, steps[0].y)
		longest_wait = maxf(longest_wait, steps[0].y)
		_expect(steps[0].x == 1.0 and steps[steps.size() - 1].x == 1.0, "a flicker starts and ends at full brightness")
		var dips: Array[float] = []
		var clock: float = 0.0
		var previous: float = 1.0
		for step: Vector2 in steps:
			if step.x < previous:
				dips.append(clock)
			clock += step.y
			previous = step.x
		for index: int in range(1, dips.size()):
			fastest_spacing = minf(fastest_spacing, dips[index] - dips[index - 1])
		if dips.size() == 2:
			doubles += 1
		elif dips.size() == 1:
			singles += 1
		else:
			_expect(false, "a flicker has one or two dips (got %d)" % dips.size())
	_expect(shortest_wait >= RoomDepth.FLICKER_WAIT_MIN and longest_wait <= RoomDepth.FLICKER_WAIT_MAX and longest_wait - shortest_wait > 9.0, "flicker waits spread across 4-15 s (%.2f..%.2f)" % [shortest_wait, longest_wait])
	_expect(doubles > 300 and singles > doubles, "most flickers are single and some double blink (%d single, %d double)" % [singles, doubles])
	_expect(fastest_spacing >= 1.0 / 3.0, "a double blink stays under 3 Hz (blinks %.2f s apart)" % fastest_spacing)
	var gentle_doubles: int = 0
	var shallowest: float = 0.0
	for _sample: int in 500:
		var gentle: Array[Vector2] = RoomDepth.flicker_steps(rng, true)
		gentle_doubles += 1 if gentle.size() != 3 else 0
		shallowest = maxf(shallowest, 1.0 - gentle[1].x)
		_expect(gentle[0].y >= RoomDepth.FLICKER_WAIT_MIN and gentle[0].y <= RoomDepth.FLICKER_WAIT_MAX and gentle[1].y > RoomDepth.BLINK_DOWN_SECONDS, "a Reduced Motion flicker waits as long and dims more slowly")
	_expect(gentle_doubles == 0 and shallowest <= 0.16, "Reduced Motion never double blinks and dims the lamp by at most 16%% (%.2f)" % shallowest)


## The beam ends where the brain's sight does: SIGHT_RANGE ahead, cut at the rubble line and at the
## furthest right the engineer can stand, and broken over the alcove, where nobody can be seen.
func _check_beam_rule() -> void:
	var far_end: float = Sentry.beam_tip_x(SentryBrain.PATROL_MAX_X, -1.0)
	_expect(is_equal_approx(far_end, SentryBrain.PATROL_MAX_X - SentryBrain.SIGHT_RANGE), "from the far end the beam reaches the full 180 px of sight")
	_expect(_patrolling_at(SentryBrain.PATROL_MAX_X, -1.0).tick(0.0001, far_end, true, -1.0) == &"lock", "an engineer at the beam's tip is seen")
	_expect(_patrolling_at(SentryBrain.PATROL_MAX_X, -1.0).tick(0.0001, far_end - 2.0, true, -1.0) == &"patrol", "an engineer just past the beam's tip is not")
	_expect(is_equal_approx(Sentry.beam_tip_x(560.0, 1.0), 740.0), "facing right it reaches 180 px the other way")
	# P0-16: solid things stop it. The exit bolt's panel stands in the lane: from left of it, facing it,
	# the beam ends on its face and nobody behind it is seen; a sentry already in front of it (its lens
	# past the face) looks on past it.
	var face: float = JunctionRoom.BOLT_PANEL_X - JunctionRoom.BOLT_PANEL_HALF_WIDTH
	_expect(is_equal_approx(SentryBrain.PANEL_FACE_X, face) and is_equal_approx(SentryBrain.LENS_AHEAD, Sentry.lens_rect().end.x), "the sight rule's panel face and lens are the drawn ones (%.2f, %.2f)" % [face, Sentry.lens_rect().end.x])
	_expect(is_equal_approx(Sentry.beam_tip_x(700.0, 1.0), face), "facing the bolt panel from the mark the beam stops on its face")
	_expect(_patrolling_at(700.0, 1.0).tick(0.0001, face, true, -1.0) == &"lock" and _patrolling_at(700.0, 1.0).tick(0.0001, face + 2.0, true, -1.0) == &"patrol", "it sees up to the panel's face and nobody behind it")
	_expect(is_equal_approx(Sentry.beam_tip_x(face - SentryBrain.LENS_AHEAD + 1.0, 1.0), minf(M0Actor.MAX_X, face - SentryBrain.LENS_AHEAD + 1.0 + SentryBrain.SIGHT_RANGE)), "a sentry whose lens is past the panel's face looks on past it")
	# A missed tank on the floor stops it from either side, and hides whoever is behind it.
	var tank: Vector2 = Vector2(DropArm.MARK_X - JunctionRoom.TANK_SIZE.x * 0.5, DropArm.MARK_X + JunctionRoom.TANK_SIZE.x * 0.5)
	_expect(is_equal_approx(Sentry.beam_tip_x(800.0, -1.0, false, INF, tank), tank.y) and is_equal_approx(Sentry.beam_tip_x(620.0, 1.0, false, INF, tank), tank.x), "a tank on the floor stops the beam at its near face, from either side")
	var behind: SentryBrain = _patrolling_at(800.0, -1.0)
	behind.sight_block = tank
	_expect(behind.tick(0.0001, tank.x - 5.0, true, -1.0) == &"patrol", "nobody behind a tank on the floor is seen")
	# Every x it can stand at, both ways, with and without a tank down: the drawn beam ends where the
	# brain's sight does (within the room and short of the rubble), and never on the far side of a
	# solid thing ahead of its lens.
	var rule_ok: bool = true
	var x_at: float = SentryBrain.CHASE_MIN_X
	while x_at <= SentryBrain.PATROL_MAX_X:
		for facing: float in [-1.0, 1.0]:
			for floor_tank: Vector2 in [Vector2.ZERO, tank]:
				if floor_tank != Vector2.ZERO and x_at + SentryBrain.HALF_WIDTH > floor_tank.x and x_at - SentryBrain.HALF_WIDTH < floor_tank.y:
					continue
				var tip_x: float = Sentry.beam_tip_x(x_at, facing, false, INF, floor_tank)
				var sight: float = SentryBrain.sight_end_x(x_at, facing, floor_tank)
				var lens_x: float = x_at + facing * SentryBrain.LENS_AHEAD
				if facing > 0.0:
					rule_ok = rule_ok and is_equal_approx(tip_x, maxf(x_at, minf(sight, M0Actor.MAX_X)))
					if lens_x <= face:
						rule_ok = rule_ok and tip_x <= face + 0.001
					if floor_tank != Vector2.ZERO and lens_x <= floor_tank.x:
						rule_ok = rule_ok and tip_x <= floor_tank.x + 0.001
				else:
					rule_ok = rule_ok and is_equal_approx(tip_x, minf(x_at, maxf(sight, SentryBrain.LANE_ENTRY_X)))
					if floor_tank != Vector2.ZERO and lens_x >= floor_tank.y:
						rule_ok = rule_ok and tip_x >= floor_tank.y - 0.001
		x_at += 1.0
	_expect(rule_ok, "at every x the drawn beam ends where the sentry's sight does and stops at the panel and a tank on the floor")
	_expect(is_equal_approx(Sentry.beam_tip_x(SentryBrain.PATROL_MIN_X, -1.0), SentryBrain.LANE_ENTRY_X), "the beam stops at the rubble line, where nobody can be seen")
	_expect(not SentryBrain.is_exposed(SentryBrain.LANE_ENTRY_X) and not SentryBrain.is_exposed(SentryBrain.LANE_ENTRY_X + 1.0) and SentryBrain.is_exposed(SentryBrain.COVER_MAX_X + 1.0), "nobody is seen from the rubble line to the alcove's right end, the edge of what it can see")
	_expect(is_equal_approx(Sentry.beam_tip_x(SentryBrain.PATROL_MAX_X, 1.0), M0Actor.MAX_X), "facing right from the far end the beam stops where the engineer can stand furthest, inside the room")
	# Just short of the end, so the tick does not bounce it round first.
	_expect(_patrolling_at(SentryBrain.PATROL_MAX_X - 1.0, 1.0).tick(0.0001, M0Actor.MAX_X, true, -1.0) == &"lock", "an engineer at that right-hand tip is seen")
	# Every x the patrol and chase can put it at, both ways: the beam never covers the alcove, and
	# every lane x between the alcove and the rubble that it sees is still under the beam.
	var gaps_ok: bool = true
	var x: float = SentryBrain.CHASE_MIN_X
	while x <= SentryBrain.PATROL_MAX_X:
		for facing: float in [-1.0, 1.0]:
			var tip: float = Sentry.beam_tip_x(x, facing)
			var gap: Vector2 = Sentry.beam_gap(x, facing)
			# The beam spans from the sentry to its tip; the break is that span's overlap with the alcove
			# (a sentry chasing someone into the alcove can stand inside its right end).
			var near: float = maxf(minf(x, tip), SentryBrain.COVER_MIN_X)
			var far: float = minf(maxf(x, tip), SentryBrain.COVER_MAX_X)
			var crosses: bool = far > near
			if crosses != (gap.y > gap.x):
				gaps_ok = false
			elif crosses and (not is_equal_approx(gap.x, near) or not is_equal_approx(gap.y, far)):
				gaps_ok = false
		x += 4.0
	_expect(gaps_ok, "the beam breaks over exactly the part of the alcove it would cross, and nowhere else")
	var at_turn: Vector2 = Sentry.beam_gap(SentryBrain.PATROL_MIN_X, -1.0)
	_expect(at_turn.is_equal_approx(Vector2(SentryBrain.COVER_MIN_X, SentryBrain.COVER_MAX_X)), "at the patrol's turn the whole alcove is out of the beam")
	_expect(not SentryBrain.is_exposed(at_turn.x) and not SentryBrain.is_exposed(at_turn.y) and not SentryBrain.is_exposed((at_turn.x + at_turn.y) * 0.5), "the gap is where an engineer is hidden")
	# The alcove starts at the rubble line, so from its turn the beam has nothing left to draw past it.
	var near_turn: float = SentryBrain.PATROL_MIN_X + 1.0
	_expect(is_equal_approx(Sentry.beam_gap(near_turn, -1.0).x, Sentry.beam_tip_x(near_turn, -1.0)) and is_equal_approx(Sentry.beam_tip_x(near_turn, -1.0), SentryBrain.COVER_MIN_X), "there is no seen strip between the alcove and the rubble, and no beam drawn there")
	var just_out: float = SentryBrain.COVER_MAX_X + 1.0
	_expect(_patrolling_at(near_turn + 30.0, -1.0).tick(0.0001, just_out, SentryBrain.is_exposed(just_out), -1.0) == &"lock" and just_out > Sentry.beam_gap(near_turn + 30.0, -1.0).y, "a step out of the alcove into the lane it sees you, under the drawn beam")
	_expect(Sentry.beam_gap(SentryBrain.PATROL_MAX_X, -1.0) == Vector2.ZERO, "from the far end the beam stops short of the alcove, with no break")


func _check_scene() -> void:
	var path: String = "user://room-lights-test-%s.json" % OS.get_process_id()
	_remove(path)
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	game.set("settings_path", "%s-settings.cfg" % path)
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	await process_frame
	var corridor: RoomDepth = game.get_node("CorridorDepth") as RoomDepth
	var records: RoomDepth = (game.get("records_room") as RecordsRoom).depth
	var junction_room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var junction: RoomDepth = junction_room.depth
	var depths: Dictionary = {"corridor": corridor, "records": records, "junction": junction}
	_check_running(depths, "corridor", "at the title")
	# A new game: the corridor's lockdown beacons pulse.
	game.call("_new_game")
	game.call("_finish_intro")
	_check_running(depths, "corridor", "in the corridor")
	var corridor_pulsing: bool = await _beacons_pulse(corridor)
	_expect(not corridor.lockdown_cleared and corridor_pulsing, "the corridor's lockdown beacons pulse before the safe point")
	await _check_corridor_flash(game, corridor, records)
	# Open the seal by the bypass and reach the safe point: the corridor is cleared.
	var state: M0State = game.get("state") as M0State
	state.record_choice(State.PRESS)
	state.arm_breaker()
	state.activate_power("human")
	(game.get_node("Human") as M0Actor).position = Vector2(876.0, 410.0)
	game.call("_sync_door")
	game.call("_interact")
	_expect(state.checkpoint_reached and corridor.lockdown_cleared, "reaching the safe point clears the corridor's lockdown")
	await create_timer(RoomDepth.SETTLE_SECONDS + 0.2).timeout
	var settled_corridor_pulsing: bool = await _beacons_pulse(corridor)
	_expect(_beacons_settled(corridor) and not settled_corridor_pulsing, "the corridor's beacons settle to a steady dim glow")
	# A new game brings the pulse back; Continue from the safe point settles the lights again.
	game.call("_return_to_title")
	game.call("_new_game")
	game.call("_finish_intro")
	var new_game_pulsing: bool = await _beacons_pulse(corridor)
	# The corridor's lens now dims with each flash, so look for it back at full red over a cycle.
	var top_red: float = 0.0
	var watch_start: int = Time.get_ticks_usec()
	while Time.get_ticks_usec() - watch_start < 900000:
		await process_frame
		top_red = maxf(top_red, _lens(corridor).r)
	var full_red: bool = top_red >= corridor.warning_color.r - 0.02
	_expect(not corridor.lockdown_cleared and full_red and new_game_pulsing, "a new game brings the corridor's pulse back (cleared %s, lens red up to %.2f, pulsing %s)" % [corridor.lockdown_cleared, top_red, new_game_pulsing])
	game.call("_return_to_title")
	game.call("_load_game")
	var continued_pulsing: bool = await _beacons_pulse(corridor)
	_expect((game.get("state") as M0State).checkpoint_reached and _beacons_settled(corridor) and not continued_pulsing, "Continue from the safe point shows the corridor settled")
	# Records: pulsing until the first copy is secured, settled after.
	var records_state: M0State = _completed_records_state(State.DISCLOSE)
	records_state.chapter_complete = false
	game.set("state", records_state)
	game.call("_sync_scene")
	_check_running(depths, "records", "in Records Access")
	var records_pulsing: bool = await _beacons_pulse(records)
	_expect(corridor.lockdown_cleared and not records.lockdown_cleared and records_pulsing, "in Records the corridor stays cleared and Records' own beacons pulse")
	(game.get_node("Human") as M0Actor).position = Vector2(830.0, 410.0)
	game.call("_interact")
	_expect(records_state.chapter_complete and records.lockdown_cleared, "securing the first copy clears Records")
	game.call("_finish_chapter_close")
	# Into the junction: Records stops, the junction starts.
	game.call("_enter_junction")
	_check_running(depths, "junction", "in the Service Junction")
	var junction_pulsing: bool = await _beacons_pulse(junction)
	_expect(not junction.lockdown_cleared and junction_pulsing, "the junction's beacons pulse while its line is live")
	# Autosave D: "It's quiet now" settles the junction, and Continue keeps it settled.
	var cleared: M0State = _completed_records_state(State.DISCLOSE)
	cleared.enter_junction()
	cleared.blow_door()
	cleared.drop_sentry()
	cleared.human_position = Vector2(JunctionRoom.BOLT_X, 410.0)
	cleared.wolf_position = Vector2(780.0, 423.0)
	game.set("state", cleared)
	game.call("_sync_scene")
	game.call("_start_gameplay_camera")
	game.set("bolt_state", &"open")
	_expect(not junction.lockdown_cleared, "with the sentry down but the line not yet cleared the beacons still pulse")
	game.call("_leave_junction")
	_expect(cleared.junction_cleared and junction.lockdown_cleared and str(game.get("status_line")).contains("It's quiet now"), "WOLF's \"It's quiet now\" comes with the junction's lockdown clearing")
	await create_timer(RoomDepth.SETTLE_SECONDS + 0.2).timeout
	var settled_junction_pulsing: bool = await _beacons_pulse(junction)
	_expect(_beacons_settled(junction) and not settled_junction_pulsing, "the junction's beacons settle once the line is cleared")
	game.call("_finish_chapter_close")
	var card_up: bool = false
	for _frame: int in 120:
		await physics_frame
		if game.get("end_card_active"):
			card_up = true
			break
	_expect(card_up and not game.get("title_open"), "the closing beat leads, through the hatch, to the END OF SLICE card")
	game.call("_close_end_card")
	_expect(game.get("title_open") and not game.get("end_card_active"), "the END OF SLICE card goes on to the title")
	# A new game puts the junction back to pulsing; Continue from autosave D settles it again.
	game.call("_new_game")
	game.call("_finish_intro")
	_expect(not junction.lockdown_cleared and not records.lockdown_cleared and not corridor.lockdown_cleared, "a new game clears no room")
	game.call("_return_to_title")
	game.call("_load_game")
	var continued_junction_pulsing: bool = await _beacons_pulse(junction)
	_expect((game.get("state") as M0State).junction_cleared and _beacons_settled(junction) and not continued_junction_pulsing, "Continue from autosave D shows the junction settled")
	_check_running(depths, "junction", "after Continue into the junction")
	# The effects switch stops every room; turning it back on restarts only the room in play.
	game.set("effects_enabled", false)
	for room_name: String in depths:
		var depth: RoomDepth = depths[room_name]
		_expect(not depth.is_animating() and not depth.far_dust.emitting and not depth.near_dust.emitting, "%s: effects off stops the light and dust" % room_name)
	game.set("effects_enabled", true)
	_check_running(depths, "junction", "with effects back on")
	# Reduced Motion reaches every room's flicker.
	game.call("_on_reduced_motion_changed", true)
	for room_name: String in depths:
		_expect((depths[room_name] as RoomDepth).reduce_motion, "%s: Reduced Motion reaches the lamp flicker" % room_name)
	game.call("_on_reduced_motion_changed", false)
	await _check_sentry_beam(game)
	_remove(path)
	_remove("%s-settings.cfg" % path)
	# The lane's sound loops stop and their playback ends before quitting, so nothing is left behind.
	game.call("_stop_junction_loops")
	game.queue_free()
	await create_timer(0.2).timeout


## At autosave B the patrolling sentry's beam reaches as far as it sees, with a lit lens glow; the
## wreck has neither, and the glow follows the effects switch.
func _check_sentry_beam(game: Node2D) -> void:
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var brain: SentryBrain = game.get("sentry_brain") as SentryBrain
	var at_b: M0State = _completed_records_state(State.DISCLOSE)
	at_b.enter_junction()
	at_b.blow_door()
	at_b.human_position = Vector2(400.0, 410.0)
	at_b.wolf_position = Vector2(JunctionRoom.WOLF_RUBBLE_X, 423.0)
	game.set("state", at_b)
	game.call("_sync_scene")
	game.call("_start_gameplay_camera")
	for _frame: int in 6:
		await physics_frame
	var sentry: Sentry = room.sentry
	var tip: float = Sentry.beam_tip_x(brain.x, sentry.visual.scale.x)
	_expect(brain.state == &"patrol" and sentry.visual.is_lit() and sentry.visual.lens_glow.visible, "the patrolling sentry's lens is lit with a soft glow")
	_expect(is_equal_approx(sentry.visual.reach, absf(tip - sentry.position.x)) and sentry.visual.reach > 100.0, "the drawn beam reaches the sentry's sight (%.0f px)" % sentry.visual.reach)
	var span: Vector2 = Sentry.beam_gap(brain.x, sentry.visual.scale.x)
	var expected_gap: Vector2 = Vector2.ZERO
	if span.y > span.x:
		var ends: Vector2 = (Vector2(span.x, span.y) - Vector2.ONE * sentry.position.x) * sentry.visual.scale.x
		expected_gap = Vector2(minf(ends.x, ends.y), maxf(ends.x, ends.y))
	_expect(sentry.visual.gap.is_equal_approx(expected_gap), "the drawn beam breaks where beam_gap says (%s)" % sentry.visual.gap)
	sentry.target_x = SentryBrain.PATROL_MIN_X
	sentry.position.x = SentryBrain.PATROL_MIN_X
	sentry.visual.scale.x = -1.0
	sentry.call("_sync_reach")
	_expect(sentry.visual.gap.is_equal_approx(Vector2(SentryBrain.PATROL_MIN_X - SentryBrain.COVER_MAX_X, SentryBrain.PATROL_MIN_X - SentryBrain.COVER_MIN_X)), "turning at the alcove, the drawn beam skips it (%s)" % sentry.visual.gap)
	sentry.follow(brain)
	_expect(sentry.visual.lens_glow.modulate.is_equal_approx(Color(Sentry.SentryVisual.EYE_PATROL, Sentry.LENS_GLOW_ALPHA)), "the glow takes the patrol colour")
	game.set("effects_enabled", false)
	_expect(not sentry.visual.lens_glow.visible and sentry.visual.is_lit(), "effects off hides the glow but keeps the eye and beam")
	game.set("effects_enabled", true)
	sentry.keel_over(DropArm.MARK_X)
	_expect(not sentry.visual.is_lit() and not sentry.visual.lens_glow.visible, "the wreck has no beam and no glow")


## The room in play animates its light and dust; the hidden rooms stop both and their dust does not
## simulate. A room whose light is painted into its plates (ambient_dust off: the corridor) runs no
## dust at all.
func _check_running(depths: Dictionary, current: String, label: String) -> void:
	var emitters: int = 0
	var expected: int = 0
	for room_name: String in depths:
		var depth: RoomDepth = depths[room_name]
		var shown: bool = room_name == current
		var drifts: bool = shown and depth.ambient_dust
		expected += 2 if drifts else 0
		_expect(depth.is_visible_in_tree() == shown, "%s: only the %s is on screen (%s)" % [label, current, room_name])
		_expect(depth.is_animating() == shown, "%s: the %s light %s" % [label, room_name, "animates" if shown else "is still"])
		for dust: CPUParticles2D in [depth.far_dust, depth.near_dust]:
			_expect(dust.emitting == drifts and dust.can_process() == drifts, "%s: the %s %s %s" % [label, room_name, dust.name, "drifts" if drifts else "is stopped"])
			emitters += 1 if dust.emitting else 0
	_expect(emitters == expected, "%s: only the room in play runs its dust emitters (%d running, %d expected)" % [label, emitters, expected])


## True when a beacon glow's brightness changes over most of a second.
func _beacons_pulse(depth: RoomDepth) -> bool:
	# Sampled through 0.7 s rather than at its two ends, which a 0.68 s flash cycle (the corridor's)
	# could land on at the same phase.
	var glow: Sprite2D = depth.lamp_glows.filter(func(node: Sprite2D) -> bool: return node.name == "WarningGlow0")[0]
	var low: float = glow.modulate.a
	var high: float = low
	for _sample: int in 7:
		await create_timer(0.1).timeout
		low = minf(low, glow.modulate.a)
		high = maxf(high, glow.modulate.a)
	return high - low > 0.02


## The corridor's caged lamps flash like a real rotating red beacon (round 11, realism review r4):
## each lamp's lens dims and brightens with the light it casts (in phase, its red at the bottom no
## more than half its red at the top), about 80-96 flashes a minute and never 3 a second, while
## Records' drawn beacons keep their steady lens and slow breathe; Reduced Motion holds the corridor's
## lamps lit and steady at once, and turning it off brings the flash back.
func _check_corridor_flash(game: Node2D, corridor: RoomDepth, records: RoomDepth) -> void:
	_expect(corridor.beacon_flash and corridor.beacon_lens_trough >= 0.5 and not records.beacon_flash and is_zero_approx(records.beacon_lens_trough), "only the corridor's caged lamps flash with their lenses (Records and the junction keep the drawn beacons' breathe)")
	var glow: Sprite2D = corridor.lamp_glows.filter(func(node: Sprite2D) -> bool: return node.name == "WarningGlow0")[0]
	var alphas: Array[float] = []
	var reds: Array[float] = []
	var times: Array[float] = []
	var start: int = Time.get_ticks_usec()
	while Time.get_ticks_usec() - start < 2400000:
		await process_frame
		times.append(float(Time.get_ticks_usec() - start) / 1000000.0)
		alphas.append(glow.modulate.a)
		reds.append(_lens(corridor).r)
	var r: float = _pearson(alphas, reds)
	var red_low: float = reds.min()
	var red_high: float = reds.max()
	_expect(r >= 0.9 and red_low <= 0.5 * red_high, "the corridor lamp's lens moves with its light (r %.3f) and its red falls to %.2f of its top" % [r, red_low / maxf(red_high, 0.001)])
	# Flashes: rises through the middle of the light's swing.
	var mid: float = (alphas.min() + alphas.max()) * 0.5
	var rises: Array[float] = []
	for i: int in range(1, alphas.size()):
		if alphas[i - 1] < mid and alphas[i] >= mid:
			rises.append(times[i])
	var per_minute: float = 0.0
	if rises.size() >= 2:
		per_minute = 60.0 * float(rises.size() - 1) / (rises[rises.size() - 1] - rises[0])
	_expect(per_minute >= 80.0 and per_minute <= 96.0, "the corridor's beacons flash like a real rotating beacon, about 88 a minute (%.0f), under 3 a second" % per_minute)
	print("corridor beacon flash: lens-light r %.3f, lens red %.2f to %.2f (%.2f), %.1f flashes a minute over %d samples" % [r, red_low, red_high, red_low / maxf(red_high, 0.001), per_minute, alphas.size()])
	var records_lens: Color = _lens(records)
	_expect(records_lens.is_equal_approx(records.warning_color), "Records' drawn beacons keep a steady lens")
	# Reduced Motion: lit and steady at once.
	game.call("_on_reduced_motion_changed", true)
	await process_frame
	var steady: bool = true
	for _sample: int in 8:
		await create_timer(0.1).timeout
		steady = steady and is_equal_approx(glow.modulate.a, corridor.beacon_peak_alpha) and _lens(corridor).is_equal_approx(corridor.warning_color)
	_expect(steady, "with Reduced Motion the corridor's beacons hold lit and steady (light %.2f, lens %s)" % [glow.modulate.a, _lens(corridor)])
	game.call("_on_reduced_motion_changed", false)
	var back: bool = await _beacons_pulse(corridor)
	_expect(back, "turning Reduced Motion off brings the corridor's flash back")


func _pearson(xs: Array[float], ys: Array[float]) -> float:
	var n: float = float(xs.size())
	var mx: float = 0.0
	var my: float = 0.0
	for i: int in xs.size():
		mx += xs[i]
		my += ys[i]
	mx /= n
	my /= n
	var sxy: float = 0.0
	var sxx: float = 0.0
	var syy: float = 0.0
	for i: int in xs.size():
		sxy += (xs[i] - mx) * (ys[i] - my)
		sxx += (xs[i] - mx) * (xs[i] - mx)
		syy += (ys[i] - my) * (ys[i] - my)
	return sxy / maxf(sqrt(sxx * syy), 0.000001)


## True when every beacon holds the settled glow with a darkened lens.
func _beacons_settled(depth: RoomDepth) -> bool:
	for glow: Sprite2D in depth.lamp_glows:
		if glow.name.begins_with("WarningGlow") and not is_equal_approx(glow.modulate.a, RoomDepth.SETTLED_BEACON_ALPHA):
			return false
	return _lens(depth).is_equal_approx(depth.warning_color.darkened(RoomDepth.SETTLED_LENS_DARKEN))


func _lens(depth: RoomDepth) -> Color:
	return depth.beacons[0].get("lens")


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


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("Room lights check failed: " + label)
