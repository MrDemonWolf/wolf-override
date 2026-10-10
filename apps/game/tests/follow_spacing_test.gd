extends SceneTree
## WOLF keeps his drawn body clear of the engineer's: at rest in each room, after he scouts the
## junction seam, across a turn, against a wall and against a sealed door. The overlap test uses the
## sprites' visible pixels, so it holds for the art as drawn, not just the collision boxes.

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const State = preload("res://scripts/m0_state.gd")
const Main = preload("res://scripts/main.gd")
## Physics frames given to WOLF to reach his spot and stop.
const SETTLE_FRAMES: int = 150

var failures: int = 0
## Visible-pixel rect of each body texture, by resource path.
var used_rects: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var path: String = "user://follow-spacing-test-%s.json" % OS.get_process_id()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	game.set("settings_path", "%s-settings.cfg" % path)
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	await process_frame
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	_check_reaches(human, wolf)
	_expect(wolf.get_index() < human.get_index() and wolf.z_index == human.z_index and wolf.keep_clear_of == human, "the engineer draws in front of WOLF at the same depth")

	# The corridor: the opening hands over with WOLF a follow gap behind, clear of the engineer.
	game.call("_new_game")
	game.call("_finish_intro")
	await _settle()
	_expect_clear(human, wolf, "corridor start")
	_expect(wolf.position.x < human.position.x, "WOLF starts on the engineer's left, away from where he faces")
	_expect(await _walk_to(human, 450.0), "the engineer walks right along the corridor")
	await _settle()
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
	await _settle()
	_expect_clear(human, wolf, "corridor at rest after quick taps")

	# A real turn moves him to the other side once, behind the engineer and dimmed while passing.
	var dimmed: bool = false
	var drawn_behind: bool = true
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
			drawn_behind = drawn_behind and wolf.get_index() < human.get_index() and wolf.z_index <= human.z_index
	_expect(side_changes == 1 and wolf.follow_side == 1, "turning left moves WOLF to the engineer's right exactly once")
	_expect(dimmed and drawn_behind, "crossing over, WOLF passes behind the engineer and dims")
	_expect_clear(human, wolf, "corridor at rest after the turn")
	# He stops within the 2 px of his spot that M0Actor treats as arrived.
	_expect(absf(wolf.position.x - human.position.x - M0Actor.FOLLOW_GAP) <= 2.5 and wolf.body_sprite.flip_h, "on the right WOLF rests a follow gap away, facing the engineer")
	_expect(await _wait_until(func() -> bool: return wolf.body_sprite.self_modulate.is_equal_approx(Color.WHITE), 120), "WOLF's dim clears once he is past")

	# At the left wall there is no room behind a right-facing engineer, so WOLF stays in front.
	_expect(await _walk_to(human, 48.0), "the engineer walks to the corridor's left wall")
	await _tap_frames(&"move_right", 3)
	await _settle()
	_expect(M0Actor.facing_of(human) == 1 and wolf.follow_side == 1, "at the wall WOLF keeps to the open side")
	_expect_clear(human, wolf, "corridor at the left wall")

	# Against the shut seal there is no room ahead of a left-facing engineer, so WOLF stays behind.
	await _tap_frames(&"move_right", 300)
	await _tap_frames(&"move_left", 3)
	await _settle()
	_expect(human.position.x > 700.0 and M0Actor.facing_of(human) == -1 and wolf.follow_side == -1, "at the shut seal WOLF keeps to the open side")
	_expect(wolf.position.x <= Main.CORRIDOR_DOOR_LEFT_X - M0Actor.WOLF_REACH + 0.5, "WOLF never noses into the shut seal")
	_expect_clear(human, wolf, "corridor at the shut seal")

	# Records, once WOLF has nothing of his own to do there.
	var state: M0State = _completed_records_state()
	state.chapter_complete = false
	game.set("state", state)
	game.call("_sync_scene")
	await _settle()
	_expect_clear(human, wolf, "records at rest after a load")
	_expect(await _walk_to(human, 420.0), "the engineer walks into Records")
	await _settle()
	_expect_clear(human, wolf, "records at rest after walking")

	# The junction: WOLF comes in ahead, reads the seam on his own, then comes back clear.
	state = _completed_records_state()
	game.set("state", state)
	game.call("_sync_scene")
	await physics_frame
	await _tap(&"interact")
	if not _require(state.chapter_id == "junction" and game.get("wolf_scouting"), "the Records exit enters the junction with WOLF scouting"):
		return
	_expect_clear(human, wolf, "junction entry")
	var read_x: Array[float] = [-1.0]
	var seam_read: Callable = func() -> bool:
		if game.get("wolf_scouting"):
			return false
		read_x[0] = wolf.position.x
		return true
	_expect(await _wait_until(seam_read, 240), "WOLF reaches the seam and reads it")
	_expect(absf(read_x[0] - JunctionRoom.WOLF_SEAM_X) <= 4.0, "WOLF reads the seam from its authored spot")
	await _settle()
	_expect_clear(human, wolf, "junction at rest after scouting")
	# A left-facing engineer by the sealed door leaves no room on his right, so WOLF holds on his left.
	_expect(await _walk_to(human, JunctionRoom.VALVE_X), "the engineer walks to the valve")
	await _tap_frames(&"move_left", 3)
	await _settle()
	_expect(wolf.follow_side == -1 and wolf.position.x < human.position.x, "beside the sealed door WOLF keeps to the open side")
	_expect_clear(human, wolf, "junction at the valve")
	_expect(wolf.position.x + M0State.WOLF_HALF_WIDTH <= M0State.JUNCTION_DOOR_LEFT_X, "WOLF stays short of the sealed door")
	# With the sentry down he follows anywhere in the lane.
	state.door_blown = true
	state.sentry_down = true
	state.human_position = Vector2(640.0, 410.0)
	state.wolf_position = Vector2(JunctionRoom.WOLF_RUBBLE_X, 423.0)
	game.call("_sync_scene")
	await _settle()
	_expect_clear(human, wolf, "junction lane at rest")
	_expect(await _walk_to(human, 760.0), "the engineer walks toward the exit bolt")
	await _settle()
	_expect_clear(human, wolf, "junction lane at rest after walking")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game.queue_free()
	await create_timer(0.1).timeout
	if failures == 0:
		print("Follow spacing checks passed")
	quit(1 if failures > 0 else 0)


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


func _settle() -> void:
	for _frame: int in SETTLE_FRAMES:
		await physics_frame


func _completed_records_state() -> M0State:
	var state: M0State = State.new()
	state.record_choice(State.DISCLOSE)
	state.arm_breaker()
	state.activate_power("wolf")
	state.reach_checkpoint()
	state.enter_records()
	state.preserve_purge_trace()
	state.preserve_mirror_trace("wolf")
	state.complete_chapter()
	state.human_position = Vector2(830.0, 410.0)
	state.wolf_position = Vector2(742.0, 423.0)
	return state


func _tap(action: StringName) -> void:
	await process_frame
	Input.action_press(action)
	await process_frame
	Input.action_release(action)


func _tap_frames(action: StringName, frames: int) -> void:
	Input.action_press(action)
	for _frame: int in frames:
		await physics_frame
	Input.action_release(action)


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
		push_error("Follow spacing check failed: " + label)


func _require(condition: bool, label: String) -> bool:
	_expect(condition, label)
	if not condition:
		quit(1)
	return condition
