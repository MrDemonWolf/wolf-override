extends "res://tests/support/game_suite.gd"
## Exercises live geometry and actor movement through the unhandled pointer path.

func _run() -> void:
	check_name = "World pointer route"
	var game: Main = await start_game("world-pointer-route", keep_running) as Main
	game.call("_new_game")
	game.call("_finish_intro")
	await frames(3)
	var pointer: WorldInput = game.world_input
	var floor_point: Vector2 = game.get_viewport().get_canvas_transform() * Vector2(500, 470)
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = floor_point
	down.pressed = true
	_expect(pointer.handle_unhandled(down), "visible floor accepts a native mouse press")
	_expect(is_inf(game.human.pointer_target_x), "press alone never walks")
	var up: InputEventMouseButton = down.duplicate() as InputEventMouseButton
	up.pressed = false
	pointer.observe(up)
	pointer.handle_unhandled(up)
	_expect(is_equal_approx(game.human.pointer_target_x, 500), "release converts canvas point back to world destination")
	var before: float = game.human.position.x
	await frames(8)
	_expect(game.human.position.x > before, "pointer navigation uses the live actor movement path")
	Input.action_press(&"move_left")
	await frames(2)
	Input.action_release(&"move_left")
	_expect(is_inf(game.human.pointer_target_x), "manual movement takes over from pointer navigation")
	pointer.cancel()
	pointer.handle_unhandled(down)
	var drag: InputEventMouseMotion = InputEventMouseMotion.new()
	drag.position = floor_point + Vector2(50, 0)
	pointer.observe(drag)
	pointer.observe(up)
	pointer.handle_unhandled(up)
	_expect(is_inf(game.human.pointer_target_x), "dragging away cancels a floor tap even after returning")
	var breaker: Tappable
	for target: Tappable in pointer.targets:
		if target.id == &"breaker" and "lockdown" in target.chapters:
			breaker = target
	var art: Sprite2D = game.breaker_art
	var point: Vector2 = art.get_global_transform_with_canvas() * art.get_rect().get_center()
	down.position = point
	up.position = point
	_expect(pointer.call("_hit", point, false) == breaker, "actual breaker art wins its world hit")
	pointer.handle_unhandled(down)
	pointer.observe(up)
	pointer.handle_unhandled(up)
	_expect(pointer.pending == breaker, "far breaker click queues that station")
	var arrived: bool = await wait_until(func() -> bool: return pointer.pending == null, 240)
	_expect(arrived and game.interaction_target_at(game.human.position.x) == &"breaker", "walk reaches the physical USE dispatcher's breaker range")
	_expect(game.tutorial_step == 2 and (game.stakes_spoken or game.waiting_for_choice), "arrival invokes the existing breaker dialogue without choosing for the player")
	pointer.cancel()
	for chapter: String in ["lockdown", "records", "investigation", "junction"]:
		game.state.chapter_id = chapter
		var ids: Array = [&"purge_display", &"breaker", &"relay", &"bypass", &"exit"] if chapter == "lockdown" else ([&"purge", &"mirror", &"exit"] if chapter == "records" else ([&"purge", &"mirror", &"container"] if chapter == "investigation" else [&"breaker", &"valve", &"door"]))
		for start: float in [100.0, 900.0]:
			for id: StringName in ids:
				game.human.position.x = start
				var approach: float = game.pointer_use_x(id)
				_expect(game.interaction_target_at(approach) == id, "%s %s approach from %.0f resolves to itself at %.1f (got %s)" % [chapter, id, start, approach, game.interaction_target_at(approach)])
	await end_game(game)
	finish("World pointer route checks passed")
