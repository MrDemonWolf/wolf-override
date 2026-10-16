extends SceneTree
## P0-4 (WOLF-2, AUDIT 7): wherever WOLF goes and stands on his own, his painted body overlaps no
## station, no door frame in the walk line and not the engineer, on both relay routes, both mirror
## routes, every lane answer and a break-off after a miss. Each beat is reached the way play reaches it (the game's own
## interacts, holds and answers, and the debug jumps, which build the run with M0State's own steps),
## then WOLF is given time to stop.
##
## What is measured is what the player sees: each body's painted pixels (more than half opaque) along
## the floor, from the live sprites, so a moved prop or a new image is measured as drawn.
## - Stations: every room's machines (the corridor's purge display, breaker, coolant relay, MANUAL
##   BYPASS and safe point; Records' purge queue, mirror port and security container; the junction's breaker, valve,
##   TANK RELEASE and exit bolt panel, and the tank once it is down), plus the sentry, live or crushed.
## - Door frames: the doors the walk line passes through, the corridor's seal portal (frame and near
##   column), Records' entry and exit and the junction's entry and exit while they are shut (from the
##   leaf's face on the walk line to the near column), and the junction's blast door (its shut or
##   breaking leaf and its near column) and the leaf it throws, lying in the lane.
## - Not counted: the relief vent, a grate in the floor. Standing in an open doorway behind its near
##   jamb and the walk-outs through the exits are door_route_test's.
## Touching (at most TOUCH px of shared painted pixels) is not an overlap.

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const WOLF_ART: String = "res://assets/wolf-side-right-provisional.png"
const TOUCH: float = 0.5
## Frames WOLF is given to reach a spot and stop (his longest walk, the length of a room, takes ~260).
const SETTLE_FRAMES: int = 600

var failures: int = 0
var checked: Array[String] = []
## Painted columns (first, last + 1) of each texture region, by texture path and region.
var painted: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var path: String = "user://wolf-space-test-%s.json" % OS.get_process_id()
	_remove(path)
	var game: Main = GAME_SCENE.instantiate() as Main
	game.save_path = path
	game.settings_path = "%s-settings.cfg" % path
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	await process_frame
	_check_reach_constants(game)
	var actions: DebugActions = game.debug_tools.actions
	await _corridor(game, actions, &"press")
	await _corridor(game, actions, &"disclose_wolf")
	await _corridor(game, actions, &"disclose_bypass")
	await _records(game, actions, &"wolf")
	await _records(game, actions, &"manual")
	await _junction_entry(game, actions)
	await _lane(game, actions, &"wolf")
	await _lane(game, actions, &"alone")
	await _lane(game, actions, &"refused")
	await _break_off(game, actions)
	_expect(checked.size() >= 30, "every route reached its rest points (%d checked)" % checked.size())
	game.queue_free()
	await process_frame
	_remove(path)
	_remove("%s-settings.cfg" % path)
	if failures == 0:
		print("WOLF space checks passed at %d rest points:\n  %s" % [checked.size(), "\n  ".join(checked)])
	quit(1 if failures > 0 else 0)


## M0Actor.WOLF_SNOUT and WOLF_TAIL, which place his spots, are his painted art's reach.
func _check_reach_constants(game: Main) -> void:
	var wolf: M0Actor = game.wolf
	_expect(wolf.body_sprite.texture.resource_path == WOLF_ART, "WOLF is drawn from the art the reach constants were measured on")
	var columns: Vector2 = _painted_columns(wolf.body_sprite)
	var half: float = wolf.body_sprite.texture.get_width() * 0.5
	var scale: float = wolf.body_sprite.scale.x
	var tail: float = (half - columns.x) * scale
	var snout: float = (columns.y - half) * scale
	_expect(absf(snout - M0Actor.WOLF_SNOUT) <= 0.1 and absf(tail - M0Actor.WOLF_TAIL) <= 0.1, "M0Actor.WOLF_SNOUT and WOLF_TAIL match his painted snout (%.2f) and tail (%.2f)" % [snout, tail])
	_expect(M0Actor.WOLF_SNOUT <= M0Actor.WOLF_REACH and M0Actor.WOLF_TAIL <= M0Actor.WOLF_REACH, "his painted reach is inside the spacing reach")


# --- Routes ---------------------------------------------------------------------------------------

## The corridor on one relay answer: WOLF off the relay while the engineer is at it, on the contact
## when he takes it, and off it while the engineer cranks the MANUAL BYPASS and the seal opens.
func _corridor(game: Main, actions: DebugActions, relay: StringName) -> void:
	actions.set_relay(relay)
	actions.jump(&"relay_question")
	await _frames(5)
	_require(game.waiting_for_choice and game.choice_context == "relay", "%s: the relay question is up" % relay)
	await _tap(&"choice_2" if relay == &"press" else &"choice_1")
	await _frames(20)
	for _step: int in 3:
		if game.state.breaker_armed:
			break
		await _tap(&"interact")
		await _frames(20)
	_require(game.state.breaker_armed, "%s: the breaker is armed" % relay)
	_require(await _walk_to(game.human, Main.RELAY_SIDE_X), "%s: the engineer walks to the relay" % relay)
	if relay == &"press":
		# Rushed, USE at the relay asks WOLF to take it, and he refuses.
		await _tap(&"interact")
		_require(game.relay_refused, "press: WOLF refuses the relay")
	await _settle(game)
	await _check_rest(game, "%s: corridor, engineer at the relay (WOLF %s)" % [relay, game.debug_wolf_why()])
	if relay == &"disclose_wolf":
		# Told, he has offered; USE at the relay signals him to take it.
		await _tap(&"interact")
		_require(await _wait_until(func() -> bool: return game.wolf_holding_relay, 240), "told: WOLF takes the contact")
		_expect(game.wolf.autonomous_target_x == Main.RELAY_CONTACT_X and not game.wolf.body_sprite.flip_h, "WOLF holds the contact from the relay's left, facing it")
		await _settle(game)
		_expect(game.wolf_holding_relay, "told: WOLF still holds the contact once his lean in has settled")
		await _check_rest(game, "%s: corridor, WOLF on the relay contact as the seal opens" % relay)
		await _safe_point(game, relay)
		return
	_require(await _walk_to(game.human, Main.BYPASS_WHEEL.x - 18.0), "%s: the engineer walks to the MANUAL BYPASS" % relay)
	await _tap(&"interact")
	await _frames(10)
	Input.action_press(&"interact")
	var opened: bool = await _wait_until(func() -> bool: return game.state.door_open, 400)
	Input.action_release(&"interact")
	_require(opened and game.state.route == "fallback", "%s: the cranked bypass opens the seal" % relay)
	_expect(game.seal_opening and game.wolf.autonomous_target_x == Main.WOLF_BYPASS_CLEAR_X, "%s: WOLF keeps off the relay while the seal opens" % relay)
	await _check_rest(game, "%s: corridor, WOLF off the relay as the bypass locks over" % relay)
	await _safe_point(game, relay)


## After the seal lands: WOLF lets go of his spot and follows, but no further than the relay's left
## side, so he never stands in the MANUAL BYPASS or the seal's frame, while the engineer waits by the
## seal, walks to the safe point and saves there. At rest he faces the engineer.
func _safe_point(game: Main, relay: StringName) -> void:
	var facing: bool = game.wolf.body_sprite.flip_h
	_require(await _wait_until(func() -> bool: return not game.seal_opening, 240), "%s: the seal finishes opening" % relay)
	if relay == &"disclose_wolf":
		# Letting go of the contact, he edges the few px back to the open-seal limit without mirroring round.
		var turns: int = 0
		for _frame: int in 30:
			await physics_frame
			if game.wolf.body_sprite.flip_h != facing:
				turns += 1
				facing = game.wolf.body_sprite.flip_h
		_expect(turns == 0, "told: WOLF keeps facing the relay as the seal lands and he edges back (%d turns)" % turns)
	await _settle(game)
	await _check_rest(game, "%s: corridor, the seal open and the engineer by it (WOLF %s)" % [relay, game.debug_wolf_why()], false)
	_require(await _walk_to(game.human, 830.0), "%s: the engineer walks to the safe point" % relay)
	await _settle(game)
	_expect(game.wolf.follow_target == game.human and absf(game.wolf.position.x - Main.WOLF_FOLLOW_OPEN_MAX_X) <= 2.5, "%s: WOLF waits on the relay's left while the engineer is at the safe point (x %.1f)" % [relay, game.wolf.position.x])
	_expect(not game.wolf.body_sprite.flip_h, "%s: waiting there he faces the engineer" % relay)
	await _check_rest(game, "%s: corridor, the engineer at the safe point" % relay, false)
	await _tap(&"interact")
	_require(game.state.checkpoint_reached and game.state.chapter_id == "lockdown", "%s: the safe point saves" % relay)
	await _tap_frames(&"move_left", 4)
	# He takes the engineer's other side only after the turn has held for TURN_SETTLE_SECONDS; check
	# once it has, so the facing rule is tested against the side he would now choose.
	_expect(await _wait_until(func() -> bool: return game.wolf.follow_side > 0, 60), "%s: once the engineer's turn holds, WOLF's follow side is their right (side %d)" % [relay, game.wolf.follow_side])
	await _settle(game)
	_expect(absf(game.wolf.position.x - Main.WOLF_FOLLOW_OPEN_MAX_X) <= 2.5 and not game.wolf.body_sprite.flip_h, "%s: the engineer turning round at the safe point leaves WOLF where he is, facing them (x %.1f)" % [relay, game.wolf.position.x])
	await _check_rest(game, "%s: corridor, saved at the safe point" % relay, false)


## Records on one mirror answer: WOLF at the mirror port on entry, there while the engineer chooses,
## and after the answer (his readout, or following once the engineer copies it through the port).
func _records(game: Main, actions: DebugActions, mirror: StringName) -> void:
	actions.set_relay(&"disclose_wolf")
	actions.set_mirror(mirror)
	actions.jump(&"records_entry")
	await _settle(game)
	_expect(absf(game.wolf.position.x - Main.WOLF_MIRROR_X) <= 2.0, "%s: WOLF goes to the mirror port on entry" % mirror)
	await _check_rest(game, "%s: Records, WOLF at the mirror port on entry" % mirror)
	_require(await _walk_to(game.human, 190.0), "%s: the engineer walks to the purge queue" % mirror)
	await _tap(&"interact")
	_require(game.state.purge_trace_preserved, "%s: the purge order is copied" % mirror)
	_require(await _walk_to(game.human, 520.0), "%s: the engineer walks to the mirror port" % mirror)
	await _tap(&"interact")
	_require(game.waiting_for_choice, "%s: the mirror offers both routes" % mirror)
	await _settle(game)
	await _check_rest(game, "%s: Records, both at the mirror port for the choice" % mirror)
	await _tap(&"choice_1" if mirror == &"wolf" else &"choice_2")
	_require(game.state.mirror_trace_preserved and game.state.mirror_route == String(mirror), "%s: the mirror timestamp is copied" % mirror)
	await _settle(game)
	await _check_rest(game, "%s: Records, after the mirror copy (WOLF %s)" % [mirror, game.debug_wolf_why()], false)


## The junction from Records' exit: WOLF reading the valve's LINE gauge on entry, then clear of the
## vent and the blast while the line builds and the fuse burns, then holding back from the rubble.
func _junction_entry(game: Main, actions: DebugActions) -> void:
	actions.set_relay(&"disclose_wolf")
	actions.set_mirror(&"wolf")
	var state: M0State = actions.build_state(&"records_mirror")
	_require(state.complete_chapter(), "the Records chapter completes")
	_require(state.save_to_disk(game.save_path), "the completed Records save is written")
	game.debug_load_checkpoint()
	await _frames(5)
	game.human.position.x = 830.0
	await _tap(&"interact")
	# USE at the open exit walks them out through it; the junction begins once WOLF is through too.
	_require(await _wait_until(func() -> bool: return game.state.chapter_id == "junction", 400) and game.wolf_scouting, "USE at the secured exit walks them out into the junction with WOLF heading for the valve")
	_require(await _wait_until(func() -> bool: return absf(game.wolf.position.x - JunctionRoom.WOLF_SEAM_X) <= 2.0, 240), "WOLF reaches the valve")
	await _frames(10)
	await _check_rest(game, "junction, WOLF reading the LINE gauge on entry")
	_require(await _wait_until(func() -> bool: return not game.wolf_scouting, 240), "WOLF finishes reading the gauge")
	_require(await _walk_to(game.human, JunctionRoom.BREAKER_X), "the engineer walks to the breaker")
	await _tap(&"interact")
	_require(game.pressure_line.state == &"building", "the breaker arms the line")
	await _settle(game)
	await _check_rest(game, "junction, WOLF clear of the vent while the line builds")
	_require(await _walk_to(game.human, Main.VALVE_CRANK_X), "the engineer walks to the valve")
	Input.action_press(&"interact")
	var lit: bool = await _wait_until(func() -> bool: return game.pressure_line.state == &"fuse" or game.pressure_line.state == &"charged", 240)
	Input.action_release(&"interact")
	_require(lit, "three turns light the fuse")
	game.human.position.x = PressureLine.BLAST_MIN_X - 8.0
	await _frames(2)
	await _check_rest(game, "junction, WOLF clear of the blast while the fuse burns")
	_require(await _wait_until(func() -> bool: return game.state.door_blown, 400), "the door blows")
	await _settle(game)
	_expect(game.wolf.autonomous_target_x == JunctionRoom.WOLF_CLEAR_X, "after the blast WOLF keeps by the entrance while the engineer stands in his spot by the valve")
	_expect(not game.wolf.body_sprite.flip_h, "holding by the entrance he faces the engineer and the rubble, not the way out")
	await _check_rest(game, "junction, after the blast, the engineer still just past the valve")
	# An engineer edging to and fro near the valve's crank never sets him running back and forth.
	game.human.position.x = Main.VALVE_CRANK_X - 7.0
	var turns: int = 0
	var last_sign: float = 0.0
	for step: int in 12:
		await _tap_frames(&"move_right" if step % 2 == 0 else &"move_left", 4)
		for _frame: int in 12:
			await physics_frame
			if absf(game.wolf.velocity.x) > 1.0:
				var moving: float = signf(game.wolf.velocity.x)
				if last_sign != 0.0 and moving != last_sign:
					turns += 1
				last_sign = moving
	_expect(turns == 0, "edging about by the valve leaves WOLF holding (%d turns, engineer at %.1f)" % [turns, game.human.position.x])
	_require(await _walk_to(game.human, 480.0), "the engineer walks up to the blown door")
	await _settle(game)
	_expect(game.wolf.autonomous_target_x == JunctionRoom.WOLF_RUBBLE_X, "then WOLF holds back from the rubble by the valve for the engineer's call")
	await _check_rest(game, "junction, WOLF waiting for the engineer's call after the blast")


## The lane on one answer, from autosave B: the question at the rubble line, WOLF's spot while the
## engineer deals with the sentry, and his spot by the hatch once it is down.
func _lane(game: Main, actions: DebugActions, lane: StringName) -> void:
	actions.set_relay(&"press" if lane == &"refused" else &"disclose_wolf")
	actions.set_lane(lane)
	actions.jump(&"lane")
	_require(game.lane_choice == String(lane), "%s: the lane is answered" % lane)
	if lane == &"wolf":
		_require(await _wait_until(func() -> bool: return game.call("_bait_holding"), 600), "wolf: the sentry stops on the mark, drawn by WOLF")
		await _settle(game)
		await _check_rest(game, "wolf: lane, WOLF drawing the sentry from the far end (engineer at the rubble)")
		_require(await _walk_to(game.human, JunctionRoom.ARM_X + 20.0), "wolf: the engineer walks into the alcove")
		await _check_rest(game, "wolf: lane, WOLF holding the sentry on the mark (engineer at the TANK RELEASE)")
		await _tap(&"interact")
		_require(await _wait_until(func() -> bool: return game.state.sentry_down, 120), "wolf: the tank comes down on the sentry")
	else:
		await _settle(game)
		_expect(game.wolf.autonomous_target_x == JunctionRoom.WOLF_RUBBLE_X, "%s: WOLF holds back from the rubble" % lane)
		_expect(game.human.position.x > game.wolf.position.x and not game.wolf.body_sprite.flip_h, "%s: holding back by the valve he faces the engineer and the rubble" % lane)
		await _check_rest(game, "%s: lane, WOLF holding back while the engineer takes the lane" % lane)
		actions.jump(&"tank_down")
		await _frames(5)
	await _settle(game)
	_expect(absf(game.wolf.position.x - JunctionRoom.WOLF_DOWN_X) <= 2.0, "%s: WOLF waits by the hatch once the sentry is down" % lane)
	await _check_rest(game, "%s: tank down, WOLF by the hatch" % lane)
	_require(await _walk_to(game.human, JunctionRoom.BOLT_X), "%s: the engineer walks to the exit bolt" % lane)
	await _settle(game)
	await _check_rest(game, "%s: tank down, WOLF by the hatch with the engineer at the bolt" % lane)


## A missed drop while WOLF is drawing the sentry and has not got past it yet: he breaks off, walks
## back to his spot by the valve ("I'm out. I'll hold back.") and, once there, faces the engineer at
## the rubble line and the rubble beyond them, not the entrance he walked back towards.
func _break_off(game: Main, actions: DebugActions) -> void:
	actions.set_relay(&"disclose_wolf")
	actions.set_lane(&"wolf")
	actions.jump(&"lane")
	_require(game.lane_choice == "wolf" and game.wolf_baiting, "break-off: WOLF sets off to draw the sentry")
	var brain: SentryBrain = game.sentry_brain
	_require(await _wait_until(func() -> bool: return brain.state == &"fixated", 240), "break-off: the sentry turns to WOLF")
	# The tank falls about half a second; the sentry is still backing off far right of the mark and
	# WOLF still on its rubble side when it lands, so it misses.
	_require(actions.trigger_drop() == "The clamp lets go.", "break-off: the TANK RELEASE lets the tank go")
	_require(await _wait_until(func() -> bool: return game.wolf_broke_off, 120), "break-off: the tank misses and WOLF breaks off")
	_require(not game.state.sentry_down and not game.wolf_holding_far_end, "break-off: he had not got past the sentry, so he goes back, not to the hatch")
	_expect(await _wait_until(func() -> bool: return game.status_line == Main.BROKE_OFF_RUBBLE_LINE, 1200), "break-off: WOLF says he is out and holds back (%s)" % game.status_line.c_escape())
	await _settle(game)
	_expect(game.wolf.autonomous_target_x == JunctionRoom.WOLF_RUBBLE_X and absf(game.wolf.position.x - JunctionRoom.WOLF_RUBBLE_X) <= 2.0, "break-off: WOLF holds back at his spot by the valve (x %.1f)" % game.wolf.position.x)
	_expect(game.human.position.x > game.wolf.position.x and not game.wolf.body_sprite.flip_h, "break-off: settled there he faces the engineer and the rubble, not the entrance")
	await _check_rest(game, "wolf: lane, WOLF holding back by the valve after breaking off")
	# Let the chase, the coolant cloud and the winch finish, then bring the sentry down so its servo
	# winds down too: no sound is still playing as the run ends.
	_expect(await _wait_until(func() -> bool: return brain.state == &"patrol" and game.drop_arm.state == &"hung" and not game.drop_arm.cloud_active(), 900), "break-off: the sentry gives up and the tank is wound back up")
	actions.jump(&"tank_down")
	await _settle(game)
	await _frames(60)


# --- Measuring ------------------------------------------------------------------------------------

## WOLF at rest: his painted body against every station, door frame and the engineer. With
## [param own_spot] he must be on one of his authored spots, not following.
func _check_rest(game: Main, label: String, own_spot: bool = true) -> void:
	await physics_frame
	checked.append(label)
	if own_spot:
		_expect(game.wolf.autonomous_target_x >= 0.0, "%s: WOLF is on a spot of his own (%s)" % [label, game.debug_wolf_why()])
	var wolf_span: Vector2 = _painted_span(game.wolf.body_sprite)
	for item: Array in _obstacles(game):
		var span: Vector2 = item[1]
		var overlap: float = minf(wolf_span.y, span.y) - maxf(wolf_span.x, span.x)
		_expect(overlap <= TOUCH, "%s: WOLF (x %.1f, painted %.1f..%.1f) stands clear of %s (%.1f..%.1f), overlap %.1f px" % [label, game.wolf.position.x, wolf_span.x, wolf_span.y, item[0], span.x, span.y, overlap])


## Everything WOLF must not stand in at rest in the current room, by name and painted span.
func _obstacles(game: Main) -> Array[Array]:
	var found: Array[Array] = []
	if game.human.is_visible_in_tree():
		found.append(["the engineer", _painted_span(game.human.body_sprite)])
	var sprites: Dictionary = {}
	match game.state.chapter_id:
		"lockdown":
			sprites = {
				"the purge display": game.get_node("PurgeTerminalArt"), "the corridor breaker": game.get_node("BreakerArt"),
				"the coolant relay": game.get_node("RelayArt"), "the safe point": game.get_node("CheckpointArt"),
				"the seal frame": game.get_node("Door/CorridorSealFrame"), "the seal's near column": game.get_node("CorridorDoorFront"),
			}
			# The MANUAL BYPASS is drawn in code round its wheel: its collar is its widest part.
			found.append(["the MANUAL BYPASS", Vector2(Main.BYPASS_WHEEL.x - BypassHandle.COLLAR_RADIUS, Main.BYPASS_WHEEL.x + BypassHandle.COLLAR_RADIUS)])
		"records":
			var records: RecordsRoom = game.records_room
			sprites = {"the purge queue": records.get_node("PurgeArt"), "the mirror port": records.get_node("MirrorArt")}
			# The container and the doors are regions of one atlas mesh: their spans on the walk line.
			found.append(["the security container", RecordsRoom.CONTAINER_SPAN])
			found.append(["the shut Records entry", RecordsRoom.ENTRY_SPAN])
			if not game.state.chapter_complete:
				found.append(["the shut Records exit", RecordsRoom.EXIT_SPAN])
		"junction":
			var room: JunctionRoom = game.junction_room
			sprites = {
				"the junction breaker": room.get_node("BreakerArt"), "the valve": room.get_node("ValveArt"),
				"the TANK RELEASE": room.get_node("ArmPanelArt"), "the exit bolt panel": room.get_node("BoltPanelArt"),
				"the sentry": room.get_node("Sentry/Visual/Body"), "the crushed sentry": room.get_node("Sentry/Visual/Wreck"),
				"the blast door's shut leaf": room.door_leaf, "the blast door's breaking leaf": room.door_leaf_breaking,
				"the blast door's near column": room.door_column, "the thrown leaf lying in the lane": room.door_leaf_down,
			}
			# The entry stands shut behind them, and the exit until it has slid open: from the leaf's face
			# on the walk line to the near jamb. The exit leaf's face (JunctionRoom.EXIT_LEAF_SHUT_X) lies a
			# little right of the near jamb's edge, so the shut exit's span is the line at its face.
			found.append(["the shut junction entry", Vector2(JunctionRoom.ENTRY_FRONT_AT.x, JunctionRoom.ENTRY_DOOR_X)])
			if room.hatch_open <= 0.0:
				found.append(["the shut junction exit", Vector2(JunctionRoom.EXIT_LEAF_SHUT_X, maxf(JunctionRoom.EXIT_LEAF_SHUT_X, JunctionRoom.EXIT_NEAR_JAMB_X))])
			# The tank stands on the floor only once it is down; hanging, he runs under it.
			if game.state.sentry_down:
				sprites["the landed tank"] = room.get_node("Tank")
	for name: String in sprites:
		var sprite: Sprite2D = sprites[name] as Sprite2D
		_require(sprite != null, "the room draws %s" % name)
		if sprite.is_visible_in_tree() and sprite.modulate.a * sprite.self_modulate.a > 0.05:
			found.append([name, _painted_span(sprite)])
	return found


## [param sprite]'s painted pixels (more than half opaque) along x, in world space.
func _painted_span(sprite: Sprite2D) -> Vector2:
	var columns: Vector2 = _painted_columns(sprite)
	var size: Vector2 = sprite.region_rect.size if sprite.region_enabled else sprite.texture.get_size()
	var origin: float = sprite.offset.x - (size.x * 0.5 if sprite.centered else 0.0)
	var from: float = origin + columns.x
	var to: float = origin + columns.y
	if sprite.flip_h:
		var mirror: float = 2.0 * (origin + size.x * 0.5)
		var flipped_from: float = mirror - to
		to = mirror - from
		from = flipped_from
	var a: float = (sprite.global_transform * Vector2(from, 0.0)).x
	var b: float = (sprite.global_transform * Vector2(to, 0.0)).x
	return Vector2(minf(a, b), maxf(a, b))


## The first painted column and one past the last of [param sprite]'s texture (or region).
func _painted_columns(sprite: Sprite2D) -> Vector2:
	var region: Rect2i = Rect2i(sprite.region_rect) if sprite.region_enabled else Rect2i(Vector2i.ZERO, Vector2i(sprite.texture.get_size()))
	var key: String = "%s %s" % [sprite.texture.resource_path, region]
	if painted.has(key):
		return painted[key]
	var image: Image = sprite.texture.get_image()
	if image.is_compressed():
		image.decompress()
	var first: int = region.end.x
	var last: int = region.position.x - 1
	for x: int in range(region.position.x, region.end.x):
		for y: int in range(region.position.y, region.end.y):
			if image.get_pixel(x, y).a > 0.5:
				first = mini(first, x)
				last = maxi(last, x)
				break
	var columns: Vector2 = Vector2(first - region.position.x, last + 1 - region.position.x)
	painted[key] = columns
	return columns


# --- Helpers --------------------------------------------------------------------------------------

## Waits until WOLF has reached the spot he is heading for and stopped.
func _settle(game: Main) -> void:
	var still: int = 0
	for _frame: int in SETTLE_FRAMES:
		await physics_frame
		var target: float = game.debug_wolf_target()
		var arrived: bool = target < 0.0 or absf(game.wolf.position.x - target) <= 2.5 or not game.wolf.is_on_floor()
		var posed: bool = game.wolf.body_sprite.offset == Vector2.ZERO and game.wolf.body_sprite.position == Main.WOLF_SPRITE_REST and is_zero_approx(game.wolf.body_sprite.rotation)
		still = still + 1 if absf(game.wolf.velocity.x) <= 1.0 and arrived and posed else 0
		if still >= 12:
			return
	_expect(false, "WOLF stops within %d frames (x %.1f, heading for %.1f)" % [SETTLE_FRAMES, game.wolf.position.x, game.debug_wolf_target()])


## Holds [param action] down for [param count] frames.
func _tap_frames(action: StringName, count: int) -> void:
	Input.action_press(action)
	await _frames(count)
	Input.action_release(action)


func _frames(count: int) -> void:
	for _frame: int in count:
		await physics_frame


func _tap(action: StringName) -> void:
	await process_frame
	Input.action_press(action)
	await process_frame
	Input.action_release(action)
	await process_frame


## Walks the engineer to [param target_x] with the move keys; a story box that stops the walk is read on.
func _walk_to(actor: M0Actor, target_x: float) -> bool:
	for _attempt: int in 4:
		var action: StringName = &"move_right" if target_x > actor.position.x else &"move_left"
		Input.action_press(action)
		var reached: bool = false
		for _frame: int in range(360):
			await physics_frame
			if absf(actor.position.x - target_x) <= 6.0:
				reached = true
				break
			if not actor.controlled:
				break
		Input.action_release(action)
		if reached:
			await _frames(2)
			return true
		# A step the game takes on its own hands control back by itself; only a story box needs reading on.
		if not await _wait_until(func() -> bool: return actor.controlled, 60):
			await _tap(&"interact")
			await _frames(10)
	return absf(actor.position.x - target_x) <= 6.0


func _wait_until(condition: Callable, frames: int) -> bool:
	for _frame: int in range(frames):
		await physics_frame
		if condition.call():
			return true
	return false


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("WOLF space check failed: " + label)


## Fails and stops the run: the steps after it need this one.
func _require(condition: bool, label: String) -> void:
	_expect(condition, label)
	if not condition:
		quit(1)
