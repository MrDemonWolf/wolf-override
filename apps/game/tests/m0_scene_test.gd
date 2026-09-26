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
	human.position.x = 350.0
	game.call("_interact")
	_expect(game.get("waiting_for_choice"), "breaker opens authored disagreement")
	game.call("_choose", State.DISCLOSE)
	game.call("_interact")
	_expect(state.breaker_armed, "breaker arms after choice")
	game.call("_switch_actor")
	_expect(state.active_actor == "wolf" and wolf.controlled, "switches to WOLF in amber zone")
	wolf.position.x = 605.0
	game.call("_interact")
	_expect(state.door_open and state.route == "cooperate", "WOLF cooperation opens door")
	wolf.position.x = 876.0
	game.call("_interact")
	_expect(state.checkpoint_reached and FileAccess.file_exists(path), "cooperative checkpoint saves")
	var saved: Dictionary = state.to_dict()
	game.call("_new_game")
	state = game.get("state") as M0State
	_expect(state.memory.is_empty() and not state.door_open, "New Game clears current play")
	game.call("_load_game")
	state = game.get("state") as M0State
	_expect(state.to_dict() == saved and state.active_actor == "wolf", "load restores cooperative scene")
	_expect(wolf.position == state.wolf_position and state.checkpoint_callback().contains(State.CHOICE_TEXT[State.DISCLOSE]), "load restores positions and actual callback")

	game.call("_new_game")
	state = game.get("state") as M0State
	human.position.x = 350.0
	game.call("_interact")
	game.call("_choose", State.PRESS)
	game.call("_interact")
	game.call("_switch_actor")
	wolf.position.x = 605.0
	game.call("_interact")
	_expect(not state.door_open and state.memory.get("choice_id") == State.PRESS, "WOLF refusal preserves choice and locked door")
	game.call("_switch_actor")
	human.position.x = 605.0
	game.call("_interact")
	_expect(state.door_open and state.route == "fallback", "engineer bypass opens door")
	human.position.x = 876.0
	game.call("_interact")
	_expect(state.checkpoint_reached, "fallback reaches checkpoint")
	saved = state.to_dict()
	game.call("_load_game")
	state = game.get("state") as M0State
	_expect(state.to_dict() == saved and state.checkpoint_callback().contains(State.CHOICE_TEXT[State.PRESS]), "fallback save loads with one accurate memory")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game.queue_free()
	if failures == 0:
		print("M0 scene checks passed")
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("M0 scene check failed: " + label)
