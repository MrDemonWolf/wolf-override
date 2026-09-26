extends SceneTree

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const State = preload("res://scripts/m0_state.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	root.add_child(game)
	var path: String = "user://m0-scene-test-%s.json" % OS.get_process_id()
	game.set("save_path", path)
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor

	game.call("_new_game")
	var state: M0State = game.get("state") as M0State
	var start_x: float = human.position.x
	if not _require(await _walk_to(human, 350.0), "active engineer reaches breaker by moving right"):
		return
	_expect(human.position.x > start_x and is_equal_approx(wolf.position.x, 225.0), "inactive WOLF stays at start")
	await _tap(&"interact")
	if not _require(game.get("waiting_for_choice"), "breaker opens authored disagreement"):
		return
	await _tap(&"choice_1")
	if not _require(state.memory.get("choice_id") == State.DISCLOSE, "first dialogue key records disclosed risk"):
		return
	await _tap(&"interact")
	if not _require(state.breaker_armed, "breaker arms after choice"):
		return
	await _tap(&"switch_actor")
	if not _require(state.active_actor == "wolf" and wolf.controlled, "switches to WOLF in amber zone"):
		return
	if not _require(await _walk_to(wolf, 605.0), "WOLF reaches relay by moving right"):
		return
	await _tap(&"interact")
	if not _require(state.door_open and state.route == "cooperate", "WOLF cooperation opens door"):
		return
	if not _require(await _walk_to(wolf, 876.0), "WOLF walks through opened door to checkpoint"):
		return
	await _tap(&"interact")
	if not _require(state.checkpoint_reached and FileAccess.file_exists(path), "cooperative checkpoint saves"):
		return
	_expect(str(game.get("status_line")).contains(State.CHOICE_TEXT[State.DISCLOSE]), "cooperative checkpoint displays the selected choice")
	var saved: Dictionary = state.to_dict()
	game.call("_new_game")
	state = game.get("state") as M0State
	_expect(state.memory.is_empty() and not state.door_open and human.position == state.human_position, "New Game clears current play")
	await _tap(&"load_game")
	state = game.get("state") as M0State
	if not _require(state.to_dict() == saved and state.active_actor == "wolf", "load restores cooperative scene"):
		return
	_expect(wolf.position == state.wolf_position and state.checkpoint_callback().contains(State.CHOICE_TEXT[State.DISCLOSE]), "load restores positions and actual callback")

	game.call("_new_game")
	state = game.get("state") as M0State
	if not _require(await _walk_to(human, 350.0), "engineer reaches breaker on fresh fallback play"):
		return
	await _tap(&"interact")
	if not _require(game.get("waiting_for_choice"), "fallback opens authored disagreement"):
		return
	await _tap(&"choice_2")
	if not _require(state.memory.get("choice_id") == State.PRESS, "second dialogue key records pressed risk"):
		return
	await _tap(&"interact")
	if not _require(state.breaker_armed, "fallback breaker arms"):
		return
	await _tap(&"switch_actor")
	if not _require(state.active_actor == "wolf", "fallback switches to WOLF"):
		return
	if not _require(await _walk_to(wolf, 605.0), "WOLF reaches relay on fallback play"):
		return
	await _tap(&"interact")
	if not _require(not state.door_open and state.memory.get("choice_id") == State.PRESS, "WOLF refusal preserves choice and locked door"):
		return
	Input.action_press(&"move_right")
	for _frame in range(180):
		await physics_frame
	Input.action_release(&"move_right")
	_expect(wolf.position.x < 760.0, "locked door physically blocks WOLF")
	if not _require(await _walk_to(wolf, 605.0), "WOLF can return to switching zone after refusal"):
		return
	await _tap(&"switch_actor")
	if not _require(state.active_actor == "human", "fallback switches to engineer"):
		return
	if not _require(await _walk_to(human, 605.0), "engineer reaches manual bypass"):
		return
	await _tap(&"interact")
	if not _require(state.door_open and state.route == "fallback", "engineer bypass opens door"):
		return
	if not _require(await _walk_to(human, 876.0), "engineer walks through opened door to checkpoint"):
		return
	await _tap(&"interact")
	if not _require(state.checkpoint_reached, "fallback reaches checkpoint"):
		return
	_expect(str(game.get("status_line")).contains(State.CHOICE_TEXT[State.PRESS]), "fallback checkpoint displays the selected choice")
	saved = state.to_dict()
	await _tap(&"load_game")
	state = game.get("state") as M0State
	_expect(state.to_dict() == saved and state.checkpoint_callback().contains(State.CHOICE_TEXT[State.PRESS]), "fallback save loads with one accurate memory")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game.queue_free()
	if failures == 0:
		print("M0 scene checks passed")
	quit(1 if failures > 0 else 0)


func _tap(action: StringName) -> void:
	await process_frame
	Input.action_press(action)
	await process_frame
	Input.action_release(action)


func _walk_to(actor: M0Actor, target_x: float) -> bool:
	var action: StringName = &"move_right" if target_x > actor.position.x else &"move_left"
	Input.action_press(action)
	var reached: bool = false
	for _frame in range(300):
		await physics_frame
		if absf(actor.position.x - target_x) <= 12.0:
			reached = true
			break
	Input.action_release(action)
	return reached


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("M0 scene check failed: " + label)


func _require(condition: bool, label: String) -> bool:
	_expect(condition, label)
	if not condition:
		quit(1)
	return condition
