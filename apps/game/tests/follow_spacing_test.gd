extends "res://tests/support/game_suite.gd"
## WOLF keeps his drawn body clear of the engineer's: at rest in each room, after he scouts the
## junction seam, across a turn, against a wall and against a sealed door. The overlap test uses the
## sprites' visible pixels, so it holds for the art as drawn, not just the collision boxes.

const State = preload("res://scripts/m0_state.gd")
const Main = preload("res://scripts/main.gd")
## Physics frames given to WOLF to reach his spot and stop.
const SETTLE_FRAMES: int = 150

## Visible-pixel rect of each body texture, by resource path.
var used_rects: Dictionary = {}


func _run() -> void:
	check_name = "Follow spacing"
	var game: Node2D = await start_game("follow-spacing-test", keep_running)
	var path: String = str(game.get("save_path"))
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	_check_reaches(human, wolf)
	_expect(wolf.get_index() < human.get_index() and wolf.z_index == human.z_index and wolf.keep_clear_of == human, "the engineer draws in front of WOLF at the same depth")

	# The opening: WOLF walking out never dims. (Layout L1: the engineer arrives in the doorway in box 2
	# and watches from there, so they are no longer hidden; WOLF's walk out waits for the beats before it,
	# which a press never snaps to their end, so watch until he has walked.)
	game.call("_new_game")
	var intro_dimmed: bool = false
	var intro_walked: bool = false
	for _step: int in 6:
		game.call("_advance_intro")
		for _frame: int in 60:
			await physics_frame
			intro_walked = intro_walked or absf(wolf.velocity.x) > 1.0
			intro_dimmed = intro_dimmed or wolf.passing() or wolf.body_sprite.self_modulate.v < 0.99
	for _frame: int in 900:
		if intro_walked:
			break
		await physics_frame
		intro_walked = intro_walked or absf(wolf.velocity.x) > 1.0
		intro_dimmed = intro_dimmed or wolf.passing() or wolf.body_sprite.self_modulate.v < 0.99
	_expect(intro_walked and not intro_dimmed, "in the opening WOLF walks out undimmed")

	# The corridor: the opening hands over with WOLF a follow gap behind, clear of the engineer.
	game.call("_finish_intro")
	await frames(SETTLE_FRAMES)
	_expect_clear(human, wolf, "corridor start")
	_expect(wolf.position.x < human.position.x, "WOLF starts on the engineer's left, away from where he faces")
	_expect(await walk_to(human, 450.0), "the engineer walks right along the corridor")
	await frames(SETTLE_FRAMES)
	_expect_clear(human, wolf, "corridor at rest after walking right")
	_expect(wolf.follow_side == -1 and absf(human.position.x - wolf.position.x - M0Actor.FOLLOW_GAP) <= 2.5, "walking right, WOLF rests one follow gap behind on the left")

	# Quick taps back and forth never set him weaving: no turn lasts long enough to change sides.
	var side_changes: int = 0
	var last_side: int = wolf.follow_side
	for tap: int in 8:
		var action: StringName = &"move_left" if tap % 2 == 0 else &"move_right"
		Input.action_press(action)
		for _frame: int in 6:
			await physics_frame
			if wolf.follow_side != last_side:
				side_changes += 1
				last_side = wolf.follow_side
		Input.action_release(action)
	_expect(side_changes == 0 and wolf.follow_side == -1, "taps shorter than the settle time leave WOLF on his side (%d changes)" % side_changes)
	await frames(SETTLE_FRAMES)
	_expect_clear(human, wolf, "corridor at rest after quick taps")

	# A short turn just before following pauses (a choice prompt) still has to settle once play resumes.
	await press_for(&"move_left", 8)
	game.set("waiting_for_choice", true)
	game.call("_update_controls")
	for _frame: int in 30:
		await physics_frame
	game.set("waiting_for_choice", false)
	game.call("_update_controls")
	var held_side: bool = true
	for _frame: int in 10:
		await physics_frame
		held_side = held_side and wolf.follow_side == -1
	_expect(held_side, "a pause in following does not skip the turn settle")
	await press_for(&"move_right", 3)
	await frames(SETTLE_FRAMES)
	_expect(wolf.follow_side == -1, "facing right again, WOLF keeps his side behind")

	# A real turn moves him to the other side once, behind the engineer and dimmed while passing.
	var dimmed: bool = false
	var reflection_dimmed: bool = false
	var drawn_behind: bool = true
	var reflection: FloorReflection = wolf.get_node_or_null("BodySpriteReflection") as FloorReflection
	Input.action_press(&"move_left")
	for _frame: int in 40:
		await physics_frame
		if wolf.follow_side != last_side:
			side_changes += 1
			last_side = wolf.follow_side
	Input.action_release(&"move_left")
	for _frame: int in SETTLE_FRAMES:
		await physics_frame
		if wolf.follow_side != last_side:
			side_changes += 1
			last_side = wolf.follow_side
		if wolf.passing():
			dimmed = dimmed or wolf.body_sprite.self_modulate.v < 0.95
			reflection_dimmed = reflection_dimmed or (reflection != null and reflection.modulate.v < 0.95)
			drawn_behind = drawn_behind and wolf.get_index() < human.get_index() and wolf.z_index <= human.z_index
	_expect(side_changes == 1 and wolf.follow_side == 1, "turning left moves WOLF to the engineer's right exactly once")
	_expect(dimmed and drawn_behind, "crossing over, WOLF passes behind the engineer and dims")
	_expect(reflection_dimmed, "WOLF's floor reflection dims with him")
	_expect_clear(human, wolf, "corridor at rest after the turn")
	# He stops within the 2 px of his spot that M0Actor treats as arrived: a follow gap away, or, where
	# that would stand him over a machine (here the breaker the engineer stopped by), the first clear
	# floor a little further back.
	var rest_x: float = wolf.off_machines(human.position.x + M0Actor.FOLLOW_GAP, 1)
	_expect(absf(wolf.position.x - rest_x) <= 2.5 and rest_x - human.position.x <= M0Actor.FOLLOW_GAP + M0Actor.AVOID_DETOUR and wolf.body_sprite.flip_h, "on the right WOLF rests a follow gap away or just clear of the nearest machine, facing the engineer (x %.0f, spot %.0f)" % [wolf.position.x, rest_x])
	for span: Vector2 in wolf.avoid_spans:
		# (Within the 2.5 px M0Actor treats as arrived.)
		_expect(wolf.position.x + M0Actor.WOLF_REACH - M0Actor.AVOID_TOLERANCE <= span.x + 2.5 or wolf.position.x - M0Actor.WOLF_REACH + M0Actor.AVOID_TOLERANCE >= span.y - 2.5 or absf(rest_x - human.position.x - M0Actor.FOLLOW_GAP) < 0.5, "resting there WOLF stands clear of the machine at %.0f..%.0f" % [span.x, span.y])
	_expect(await wait_until(func() -> bool: return wolf.body_sprite.self_modulate.is_equal_approx(Color.WHITE), 120), "WOLF's dim clears once he is past")

	# At the left wall there is no room behind a right-facing engineer, so WOLF stays in front. (Layout
	# L1, Nathanial 2026-10-14: the corridor's left end is the opening into the dock bay, so the nearest
	# left wall is the bay's end wall.)
	_expect(await walk_to(human, DockBay.HUMAN_MIN_X + 8.0), "the engineer walks to the dock bay's end wall")
	await press_for(&"move_right", 3)
	await frames(SETTLE_FRAMES)
	_expect(M0Actor.facing_of(human) == 1 and wolf.follow_side == 1, "at the wall WOLF keeps to the open side")
	_expect_clear(human, wolf, "dock bay at its end wall")
	_expect(await walk_to(human, 48.0), "the engineer walks back into the corridor")

	# Against the shut seal there is no room ahead of a left-facing engineer, so WOLF stays behind.
	await press_for(&"move_right", 300)
	await press_for(&"move_left", 3)
	await frames(SETTLE_FRAMES)
	_expect(human.position.x > 700.0 and M0Actor.facing_of(human) == -1 and wolf.follow_side == -1, "at the shut seal WOLF keeps to the open side")
	_expect(wolf.position.x <= Main.CORRIDOR_DOOR_LEFT_X - M0Actor.WOLF_REACH + 0.5, "WOLF never noses into the shut seal")
	_expect_clear(human, wolf, "corridor at the shut seal")

	# Records, once WOLF has nothing of his own to do there.
	var state: M0State = _completed_records_state()
	state.chapter_complete = false
	game.set("state", state)
	game.call("_sync_scene")
	await frames(SETTLE_FRAMES)
	_expect_clear(human, wolf, "records at rest after a load")
	_expect(await walk_to(human, 420.0), "the engineer walks into Records")
	await frames(SETTLE_FRAMES)
	_expect_clear(human, wolf, "records at rest after walking")

	# The junction: WOLF comes in ahead, reads the seam on his own, then comes back clear.
	state = _completed_records_state()
	game.set("state", state)
	game.call("_sync_scene")
	await physics_frame
	await tap(&"interact")
	# USE at the open exit walks the engineer out through the doorway first; the junction follows.
	await wait_until(func() -> bool: return state.chapter_id == "junction", 180)
	if not _require(state.chapter_id == "junction" and game.get("wolf_scouting"), "the Records exit enters the junction with WOLF scouting"):
		return
	_expect_clear(human, wolf, "junction entry")
	var read_x: Array[float] = [-1.0]
	var seam_read: Callable = func() -> bool:
		if game.get("wolf_scouting"):
			return false
		read_x[0] = wolf.position.x
		return true
	_expect(await wait_until(seam_read, 240), "WOLF reaches the seam and reads it")
	_expect(absf(read_x[0] - JunctionRoom.WOLF_SEAM_X) <= 4.0, "WOLF reads the seam from its authored spot")
	await frames(SETTLE_FRAMES)
	_expect_clear(human, wolf, "junction at rest after scouting")
	# A left-facing engineer by the sealed door leaves no room on his right, so WOLF holds on his left.
	_expect(await walk_to(human, JunctionRoom.VALVE_X), "the engineer walks to the valve")
	await press_for(&"move_left", 3)
	await frames(SETTLE_FRAMES)
	_expect(wolf.follow_side == -1 and wolf.position.x < human.position.x, "beside the sealed door WOLF keeps to the open side")
	_expect_clear(human, wolf, "junction at the valve")
	_expect(wolf.position.x + M0State.WOLF_HALF_WIDTH <= M0State.JUNCTION_DOOR_LEFT_X, "WOLF stays short of the sealed door")
	# With the sentry down he follows anywhere in the lane.
	state.door_blown = true
	state.sentry_down = true
	state.human_position = Vector2(640.0, 410.0)
	state.wolf_position = Vector2(JunctionRoom.WOLF_RUBBLE_X, 423.0)
	game.call("_sync_scene")
	await frames(SETTLE_FRAMES)
	_expect_clear(human, wolf, "junction lane at rest")
	_expect(await walk_to(human, 760.0), "the engineer walks toward the exit bolt")
	await frames(SETTLE_FRAMES)
	_expect_clear(human, wolf, "junction lane at rest after walking")

	# Nobody rests inside a machine, in any room: stopped over a station's body the engineer sidesteps
	# out beside it, and WOLF's own spots keep him off the machines where there is floor.
	var corridor: M0State = State.new()
	corridor.record_choice(State.DISCLOSE)
	corridor.arm_breaker()
	corridor.activate_power("wolf")
	await _check_stations(game, human, corridor, Main.CORRIDOR_STATIONS, "corridor")
	var corridor_labels: Array[Label] = [game.get_node("BreakerLabel"), game.get_node("RelayLabel"), game.get_node("CheckpointLabel")]
	await _check_label_edges(game, human, corridor_labels, "corridor")
	var records: M0State = _completed_records_state()
	records.chapter_complete = false
	await _check_stations(game, human, records, Main.RECORDS_STATIONS, "records")
	await _check_label_edges(game, human, (game.get("records_room") as RecordsRoom).station_labels, "records")
	var junction: M0State = _completed_records_state()
	junction.enter_junction()
	junction.door_blown = true
	junction.sentry_down = true
	await _check_stations(game, human, junction, Main.JUNCTION_STATIONS, "junction")
	var release: Vector4 = Main.JUNCTION_STATIONS[2]
	var release_spot: float = release.x + release.y + M0Actor.HUMAN_REACH - Main.STATION_OVERLAP
	_expect(release_spot - M0Actor.HUMAN_REACH >= SentryBrain.COVER_MIN_X and release_spot + M0Actor.HUMAN_REACH <= SentryBrain.COVER_MAX_X, "beside the TANK RELEASE the engineer's whole body is between the alcove's posts")
	_expect(JunctionRoom.WOLF_SEAM_X + M0Actor.WOLF_REACH <= JunctionRoom.VALVE_X - JunctionRoom.VALVE_HALF_WIDTH and JunctionRoom.WOLF_SEAM_X - M0Actor.WOLF_REACH >= JunctionRoom.BREAKER_X + JunctionRoom.BREAKER_HALF_WIDTH - 6.0, "WOLF reads the line from the floor between the breaker and the valve, not from inside the valve")
	_expect(JunctionRoom.BOLT_X + M0Actor.HUMAN_REACH - Main.STATION_OVERLAP <= JunctionRoom.BOLT_PANEL_X - JunctionRoom.BOLT_PANEL_HALF_WIDTH + 0.5 and JunctionRoom.BOLT_X >= JunctionRoom.BOLT_REACH_MIN_X, "the exit bolt is worked from beside its panel, inside its reach")
	_check_draw_order(game, human, wolf)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game.queue_free()
	await create_timer(0.1).timeout
	finish("Follow spacing checks passed")


## Places the engineer, facing right, at the middle of every station in [param stations] of the room
## [param state] is in and checks that, with no input held, they sidestep out beside the machine (its
## own side, else the left from the middle) without turning, still inside its reach.
func _check_stations(game: Node2D, human: M0Actor, state: M0State, stations: Array[Vector4], room: String) -> void:
	game.set("state", state)
	game.call("_sync_scene")
	await physics_frame
	await physics_frame
	for station: Vector4 in stations:
		human.position.x = station.x
		human.velocity = Vector2.ZERO
		human.body_sprite.flip_h = false
		var offset: float = minf(station.y + M0Actor.HUMAN_REACH - Main.STATION_OVERLAP, station.z - 2.0)
		var spot: float = clampf(station.x + (station.w if station.w != 0.0 else -1.0) * offset, M0Actor.MIN_X, M0Actor.MAX_X)
		var settled: bool = await wait_until(func() -> bool: return absf(human.position.x - spot) <= 2.5 and absf(human.velocity.x) < 1.0, 90)
		_expect(settled and human.controlled, "%s: stopped over the machine at %.0f the engineer steps out to %.0f (at %.0f)" % [room, station.x, spot, human.position.x])
		_expect(not human.body_sprite.flip_h and absf(human.position.x - station.x) <= station.z, "%s: the step out at %.0f keeps the engineer's facing and the machine in reach" % [room, station.x])


## With the view on the middle of the room, a station name the view's edge cuts fades out like the
## junction's plates instead of showing in part, and every name is sized to its text.
func _check_label_edges(game: Node2D, human: M0Actor, labels: Array[Label], room: String) -> void:
	human.position.x = 480.0
	await frames(SETTLE_FRAMES)
	var viewport: Viewport = game.get_viewport()
	var view: Rect2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	var faded: int = 0
	for label: Label in labels:
		var rect: Rect2 = label.get_global_rect()
		_expect(is_equal_approx(label.size.x, label.get_combined_minimum_size().x), "%s: %s is sized to its text" % [room, label.text])
		_expect(is_equal_approx(label.modulate.a, JunctionRoom.edge_alpha(rect, view)), "%s: %s fades by how close it is to the view's edge (alpha %.2f)" % [room, label.text, label.modulate.a])
		if rect.position.x < view.position.x or rect.end.x > view.end.x:
			_expect(label.modulate.a == 0.0, "%s: %s, cut by the view's edge, is hidden" % [room, label.text])
		if label.modulate.a < 1.0:
			faded += 1
	_expect(faded > 0, "%s: from the middle of the room at least one name reaches the view's edge, so the fade is exercised" % room)


## The machines' lights, glows, plates and captions all draw under the two actors, so someone standing
## at a machine is in front of everything on it. (The door's placard hangs over the blast door's near
## column, above head height; the door's status lamp is on that column, in front of the actors.)
func _check_draw_order(game: Node2D, human: M0Actor, wolf: M0Actor) -> void:
	var actor_z: int = drawn_z(human)
	_expect(actor_z == drawn_z(wolf), "both actors draw at one depth")
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var records: RecordsRoom = game.get("records_room") as RecordsRoom
	var bypass: BypassHandle = game.get("bypass_handle") as BypassHandle
	var parts: Array[CanvasItem] = [game.get_node("BreakerStatusLight"), game.get_node("RelayStatusLight"), game.get("breaker_status_glow"), game.get("relay_status_glow"), game.get_node("BreakerArt"), game.get_node("RelayArt"), game.get_node("CheckpointArt"), game.get_node("BreakerLabel"), game.get_node("RelayLabel"), game.get_node("CheckpointLabel"), bypass, bypass.bypass_label, bypass.fault_tag, records.purge_glow, records.mirror_glow, room.breaker_glow, room.vent_glow, room.line_caption, room.breaker_art, room.valve_art, room.arm_panel_art, room.bolt_panel_art]
	for label: Label in records.station_labels:
		parts.append(label)
	for label: Label in room.station_labels:
		if label != room.door_label:
			parts.append(label)
	var over: Array[String] = []
	for part: CanvasItem in parts:
		if drawn_z(part) >= actor_z:
			over.append("%s (z %d)" % [part.name, drawn_z(part)])
	_expect(over.is_empty(), "every machine's light, glow and plate draws under the actors (over: %s)" % ", ".join(over))


## WOLF_REACH and HUMAN_REACH must cover the visible art, or FOLLOW_GAP would not keep them apart.
func _check_reaches(human: M0Actor, wolf: M0Actor) -> void:
	var wolf_span: Vector2 = _local_span(wolf)
	var human_span: Vector2 = _local_span(human)
	_expect(maxf(-wolf_span.x, wolf_span.y) <= M0Actor.WOLF_REACH, "WOLF_REACH covers WOLF's drawn body (%.1f..%.1f)" % [wolf_span.x, wolf_span.y])
	_expect(maxf(-human_span.x, human_span.y) <= M0Actor.HUMAN_REACH, "HUMAN_REACH covers the engineer's drawn body (%.1f..%.1f)" % [human_span.x, human_span.y])
	_expect(M0Actor.FOLLOW_GAP > M0Actor.CLEAR_GAP and M0Actor.FOLLOW_GAP <= 90.0, "the follow gap clears both bodies with a little air")


## The visible horizontal extent of [param actor]'s body sprite, relative to the actor, unflipped.
func _local_span(actor: M0Actor) -> Vector2:
	var sprite: Sprite2D = actor.body_sprite
	var texture_path: String = sprite.texture.resource_path
	if not used_rects.has(texture_path):
		var image: Image = Image.load_from_file(ProjectSettings.globalize_path(texture_path))
		used_rects[texture_path] = image.get_used_rect()
	var used: Rect2i = used_rects[texture_path]
	var half_width: float = sprite.texture.get_width() * 0.5
	return Vector2((used.position.x - half_width) * sprite.scale.x, (used.end.x - half_width) * sprite.scale.x)


## The visible horizontal extent of [param actor]'s body in world space, as currently flipped.
func _world_span(actor: M0Actor) -> Vector2:
	var span: Vector2 = _local_span(actor)
	if actor.body_sprite.flip_h:
		span = Vector2(-span.y, -span.x)
	var origin: float = actor.body_sprite.global_position.x
	return Vector2(origin + span.x, origin + span.y)


func _expect_clear(human: M0Actor, wolf: M0Actor, where: String) -> void:
	var human_span: Vector2 = _world_span(human)
	var wolf_span: Vector2 = _world_span(wolf)
	var clear: bool = wolf_span.y <= human_span.x or wolf_span.x >= human_span.y
	_expect(clear, "%s: WOLF (%.0f..%.0f) and the engineer (%.0f..%.0f) do not overlap" % [where, wolf_span.x, wolf_span.y, human_span.x, human_span.y])


## The kit's completed Records run (a disclosure, the pair by the Records exit) with WOLF 24 px
## nearer the engineer, at x 742, where this suite has always started him.
func _completed_records_state() -> M0State:
	var state: M0State = completed_records_state(State.DISCLOSE)
	state.wolf_position = Vector2(742.0, 423.0)
	return state
