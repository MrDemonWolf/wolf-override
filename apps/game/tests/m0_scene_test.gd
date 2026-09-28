extends SceneTree

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const State = preload("res://scripts/m0_state.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var path: String = "user://m0-scene-test-%s.json" % OS.get_process_id()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	root.add_child(game)
	var title_screen: Control = game.get_node("CanvasLayer/TitleScreen") as Control
	var title_art: TextureRect = game.get_node("CanvasLayer/TitleScreen/CorridorArt") as TextureRect
	var title_mark: TextureRect = game.get_node("CanvasLayer/TitleScreen/LogoMark") as TextureRect
	var title_logo: Label = game.get_node("CanvasLayer/TitleScreen/GameTitle") as Label
	var new_game_button: Button = game.get_node("CanvasLayer/TitleScreen/NewGameButton") as Button
	var continue_button: Button = game.get_node("CanvasLayer/TitleScreen/ContinueButton") as Button
	var hud: Label = game.get_node("CanvasLayer/TopBar/HUD") as Label
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor

	if not _require(game.get("title_open") and title_screen.visible and continue_button.disabled, "fresh title disables Continue without a test checkpoint"):
		return
	if not _require(title_art.texture != null and title_art.texture.resource_path == "res://assets/title-corridor-key-art-provisional.png", "title shows the corridor artwork"):
		return
	if not _require(title_logo.text == "WOLF//OVERRIDE" and title_mark.texture != null and title_mark.texture.resource_path == "res://assets/logo-mark.svg", "title loads the branded WOLF//OVERRIDE logo"):
		return
	new_game_button.pressed.emit()
	if not _require(not game.get("title_open") and not title_screen.visible, "New Game button starts play through its signal"):
		return
	_expect(str(game.get("status_line")).contains("I woke myself"), "opening establishes WOLF's own awakening")
	var state: M0State = game.get("state") as M0State
	_expect(state.memory.is_empty() and not state.door_open and state.active_actor == "human", "New Game button starts clean")
	_expect(wolf.position.x < human.position.x and is_equal_approx(human.position.x - wolf.position.x, 64.0), "WOLF starts beside, not inside, the engineer")
	_expect(human.controlled and not wolf.controlled and not InputMap.has_action(&"switch_actor"), "only the engineer has movement controls")
	_expect(game.call("_objective") == "CHECK THE BREAKER", "opening points to the first corridor objective")
	await process_frame
	await _tap(&"interact")
	_expect(str(game.get("status_line")).contains("Original program logs marked for deletion"), "purge display establishes evidence stakes without inventory")
	var start_x: float = human.position.x
	if not _require(await _walk_to(human, 350.0), "active engineer reaches breaker by moving right"):
		return
	_expect(human.position.x > start_x and wolf.position.x > 225.0 and wolf.position.x < human.position.x, "WOLF follows the engineer autonomously")
	if not _require(await _walk_to(human, 450.0), "engineer can move beyond the breaker"):
		return
	if not _require(await _walk_to(human, 350.0), "engineer can backtrack to the breaker"):
		return
	for _frame in range(40):
		await physics_frame
	_expect(absf(human.position.x - wolf.position.x - 64.0) <= 5.0, "WOLF settles behind the engineer after backtracking")
	await _tap(&"interact")
	if not _require(game.get("waiting_for_choice"), "breaker opens authored disagreement"):
		return
	await _tap(&"choice_1")
	if not _require(state.memory.get("choice_id") == State.DISCLOSE, "first dialogue key records disclosed risk"):
		return
	_expect(game.call("_objective") == "ARM THE BREAKER", "honest answer advances the objective")
	await _tap(&"interact")
	if not _require(state.breaker_armed, "breaker arms after choice"):
		return
	_expect(game.call("_objective") == "OPEN THE SEAL", "powered relay becomes the objective")
	if not _require(await _walk_to(human, 605.0), "engineer reaches relay with WOLF following"):
		return
	_expect(not wolf.controlled and wolf.position.x > 400.0 and wolf.position.x < human.position.x, "WOLF stays a companion at the relay")
	_expect(str(game.call("_context_hint")).contains("give WOLF room"), "relay hint waits for WOLF to reach the contact")
	await _tap(&"interact")
	if not _require(not state.door_open and str(game.get("status_line")).contains("give me room"), "early relay request keeps the seal closed until WOLF is near"):
		return
	if not _require(await _walk_to(human, 655.0), "engineer gives WOLF room at the contact"):
		return
	_expect(absf(wolf.position.x - 605.0) <= 32.0, "WOLF reaches the relay before cooperation")
	await _tap(&"interact")
	if not _require(state.door_open and state.route == "cooperate", "WOLF cooperation opens door"):
		return
	_expect(game.call("_objective") == "REACH SAFE POINT", "open seal points to safety")
	_expect(str(game.call("_context_hint")).contains("Move to the safe point"), "open-door hint no longer sends the player back to the breaker")
	await create_timer(0.45).timeout
	var door_visual: ColorRect = game.get_node("Door/Visual") as ColorRect
	_expect(not door_visual.visible, "door retracts after cooperation")
	await _tap(&"interact")
	_expect(not door_visual.visible, "reusing the open relay does not replay the door seal")
	if not _require(await _walk_to(human, 876.0), "engineer walks through opened door to checkpoint"):
		return
	await _tap(&"interact")
	if not _require(state.checkpoint_reached and FileAccess.file_exists(path), "cooperative checkpoint saves"):
		return
	_expect(game.call("_objective") == "CORRIDOR CLEARED", "checkpoint closes the first scene")
	_expect(str(game.get("status_line")).contains(State.CHOICE_TEXT[State.DISCLOSE]), "cooperative checkpoint displays the selected choice")
	var saved: Dictionary = state.to_dict()
	game.call("_new_game")
	state = game.get("state") as M0State
	_expect(state.memory.is_empty() and not state.door_open and human.position == state.human_position, "New Game clears current play")
	await _tap(&"load_game")
	state = game.get("state") as M0State
	if not _require(state.to_dict() == saved and state.active_actor == "human" and human.controlled and not wolf.controlled, "load restores cooperative scene with engineer control"):
		return
	_expect(human.position == state.human_position and wolf.position == state.wolf_position and state.checkpoint_callback().contains(State.CHOICE_TEXT[State.DISCLOSE]), "load restores positions and actual callback")

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
	_expect(str(game.get("status_line")).contains("I won't take that risk blind"), "WOLF refuses the live contact")
	await _tap(&"interact")
	if not _require(state.breaker_armed, "fallback breaker arms"):
		return
	if not _require(await _walk_to(human, 605.0), "engineer reaches manual bypass on fallback play"):
		return
	_expect(not state.door_open and str(game.call("_context_hint")).contains("ask WOLF"), "relay first offers WOLF a choice")
	await _tap(&"interact")
	if not _require(not state.door_open and state.route.is_empty() and game.get("relay_refused"), "WOLF refuses and keeps the seal closed"):
		return
	_expect(str(game.get("status_line")).contains("I said no") and str(game.call("_context_hint")).contains("manual bypass"), "refusal clearly offers the engineer's bypass")
	Input.action_press(&"move_right")
	for _frame in range(180):
		await physics_frame
	Input.action_release(&"move_right")
	_expect(human.position.x < 760.0, "locked door physically blocks the engineer")
	if not _require(await _walk_to(human, 605.0), "engineer can return to manual bypass after refusal"):
		return
	await _tap(&"interact")
	if not _require(state.door_open and state.route == "fallback", "engineer bypass opens door"):
		return
	_expect(str(game.call("_context_hint")).contains("Move to the safe point"), "fallback hint points through the open seal")
	if not _require(await _walk_to(human, 876.0), "engineer walks through opened door to checkpoint"):
		return
	await _tap(&"cycle_name")
	_expect(state.name_index == 1, "draft identity changes before fallback save")
	_expect(hud.text.contains("CONTROL: Alex Bennett (they/them)"), "protagonist keeps they/them when the provisional name changes")
	_expect(not str(game.get("status_line")).contains("breaker"), "identity line does not rewind the scene after the seal opens")
	await _tap(&"interact")
	if not _require(state.checkpoint_reached, "fallback reaches checkpoint"):
		return
	_expect(str(game.get("status_line")).contains(State.CHOICE_TEXT[State.PRESS]), "fallback checkpoint displays the selected choice")
	saved = state.to_dict()
	await _tap(&"load_game")
	state = game.get("state") as M0State
	_expect(state.to_dict() == saved and state.checkpoint_callback().contains(State.CHOICE_TEXT[State.PRESS]), "fallback save loads with one accurate memory")
	_expect(not game.get("relay_refused"), "load clears the transient refusal prompt")
	game.queue_free()
	await process_frame
	game = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	root.add_child(game)
	title_screen = game.get_node("CanvasLayer/TitleScreen") as Control
	continue_button = game.get_node("CanvasLayer/TitleScreen/ContinueButton") as Button
	human = game.get_node("Human") as M0Actor
	wolf = game.get_node("Wolf") as M0Actor
	if not _require(game.get("title_open") and title_screen.visible and not continue_button.disabled, "fresh title enables Continue for the test checkpoint"):
		return
	continue_button.pressed.emit()
	state = game.get("state") as M0State
	if not _require(not game.get("title_open") and not title_screen.visible, "Continue button starts saved play through its signal"):
		return
	_expect(state.to_dict() == saved and state.active_actor == "human" and human.controlled and not wolf.controlled and state.route == "fallback" and state.name_index == 1 and state.memory.get("choice_id") == State.PRESS, "Continue restores engineer control, puzzle, identity and one accurate memory")
	_expect(human.position == state.human_position and wolf.position == state.wolf_position and state.checkpoint_callback().contains(State.CHOICE_TEXT[State.PRESS]), "Continue restores both actor positions and actual callback")

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
