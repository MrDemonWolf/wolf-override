extends "res://tests/support/game_suite.gd"
## Viewport routing preserves GUI priority and finger ownership; OS delivery needs container/device checks.


func _run() -> void:
	check_name = "World events"
	var game: Main = await start_game("world-events", keep_running) as Main
	game.call("_new_game")
	game.call("_finish_intro")
	await frames(3)
	var pointer: WorldInput = game.world_input
	var point: Vector2 = game.get_viewport().get_canvas_transform() * Vector2(500, 470)
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.position = point
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	root.push_input(down.duplicate(), true)
	await frames(1)
	_expect(not pointer.active.is_empty(), "native mouse floor press reaches the unhandled world route")
	var up: InputEventMouseButton = down.duplicate() as InputEventMouseButton
	up.pressed = false
	root.push_input(up.duplicate(), true)
	await frames(2)
	_expect(not is_inf(game.human.pointer_target_x), "native floor release begins navigation")
	pointer.cancel()
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = 2
	touch.position = point
	touch.pressed = true
	root.push_input(touch.duplicate(), true)
	await frames(1)
	_expect(not pointer.active.is_empty() and pointer.active["id"] == 2, "native touch owns its gesture")
	var other: InputEventScreenTouch = touch.duplicate() as InputEventScreenTouch
	other.index = 3
	root.push_input(other.duplicate(), true)
	await frames(1)
	_expect(not pointer.active.is_empty() and pointer.active["id"] == 2, "second finger cannot steal the world gesture")
	other.pressed = false
	root.push_input(other.duplicate(), true)
	await frames(1)
	_expect(is_inf(game.human.pointer_target_x), "secondary release never starts a walk")
	touch.pressed = false
	root.push_input(touch.duplicate(), true)
	await frames(2)
	_expect(not is_inf(game.human.pointer_target_x), "owner release starts its own walk")
	pointer.cancel()
	# Godot forwards a phone tap to native Buttons as an emulated mouse event.
	down.device = InputEvent.DEVICE_ID_EMULATION
	up.device = InputEvent.DEVICE_ID_EMULATION
	down.position = game.pause_button.get_global_rect().get_center()
	up.position = down.position
	root.push_input(down.duplicate(), true)
	await frames(1)
	root.push_input(up.duplicate(), true)
	await frames(2)
	_expect(paused, "emulated phone tap reaches the actual Pause button")
	_expect(pointer.active.is_empty() and is_inf(game.human.pointer_target_x), "Pause click never reaches the world beneath it")
	game.call("_resume_game")
	await end_game(game)
	finish("World events checks passed")
