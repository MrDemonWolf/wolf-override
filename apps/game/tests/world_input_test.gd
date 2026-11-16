extends "res://tests/support/game_suite.gd"
## Pointer cancellation must stop its own crank without changing scripted actor navigation.


func _run() -> void:
	check_name = "World input"
	_check_canvas_geometry()
	var game: Main = await start_game("world-input", keep_running) as Main
	game.call("_new_game")
	game.call("_finish_intro")
	var pointer: WorldInput = game.world_input
	pointer.active = {"id": 0, "target": null, "point": Vector2.ZERO, "cancelled": false, "fired": true, "hold": &"bypass"}
	pointer.set("_queued_use", true)
	game.crank_latched = true
	var release: InputEventScreenTouch = InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.canceled = true
	pointer.observe(release)
	_expect(not game.crank_latched and not pointer.get("_queued_use"), "OS-canceled touch drops both toggle hold and queued press")
	_expect(pointer.active.is_empty() and pointer.released["cancelled"], "canceled release cannot activate on release")
	pointer.active = {"id": WorldInput.MOUSE_ID, "target": null, "point": Vector2.ZERO, "cancelled": false, "fired": true, "hold": &"bypass"}
	var mouse: InputEventMouseButton = InputEventMouseButton.new()
	mouse.device = InputEvent.DEVICE_ID_EMULATION
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = false
	pointer.observe(mouse)
	_expect(not pointer.active.is_empty(), "emulated mouse release cannot end a native gesture")
	game.crank_latched = true
	pointer.cancel()
	_expect(not game.crank_latched and pointer.active.is_empty(), "canceling pointer intent stops its own latched hold")
	game.crank_latched = true
	pointer.cancel()
	_expect(game.crank_latched, "canceling an idle pointer preserves another input's latch")
	game.crank_latched = false
	# Build a live manual route with the same state methods used by the choice and breaker.
	game.state.record_choice(M0State.PRESS)
	game.state.arm_breaker()
	game.human.position.x = Main.BYPASS_CRANK_X
	game.call("_update_controls")
	await frames(3)
	var station: Tappable = pointer.prompt_target()
	_expect(station != null and station.id == &"bypass" and station.prompt_rect().has_area(), "the prompt resolves the dispatcher's live bypass with a drawn anchor")
	var wheel: Sprite2D = game.bypass_handle.wheel
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = wheel.get_global_transform_with_canvas() * wheel.get_rect().get_center()
	down.pressed = true
	_expect(pointer.handle_unhandled(down) and pointer.holding(&"bypass"), "pressing the live wheel owns a held crank")
	var ticked: bool = await wait_until(func() -> bool: return game.hold_use.ticks >= 1, 40)
	_expect(ticked, "holding the wheel advances the real held-USE timer")
	var kept: int = game.hold_use.ticks
	var up: InputEventMouseButton = down.duplicate() as InputEventMouseButton
	up.pressed = false
	pointer.observe(up)
	pointer.handle_unhandled(up)
	await frames(3)
	_expect(not game.hold_use.holding and game.hold_use.ticks == kept, "release stops the crank and preserves completed ticks")
	await end_game(game)
	finish("World input checks passed")


## A translated/scaled plate keeps the same live canvas bounds for its hit target and HUD avoidance.
func _check_canvas_geometry() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)
	holder.position = Vector2(30, 20)
	var plate: Control = Control.new()
	holder.add_child(plate)
	plate.position = Vector2(10, 15)
	plate.size = Vector2(20, 10)
	plate.scale = Vector2(2, 3)
	var target: Tappable = Tappable.new()
	holder.add_child(target)
	target.setup(&"plate", [], [plate])
	_expect(Tappable.canvas_rect(plate).is_equal_approx(Rect2(40, 35, 40, 30)), "plate bounds include ancestor translation and local scale")
	_expect(not is_inf(target.hit_score(Vector2(60, 50), false)), "the displayed plate centre remains clickable")
	holder.position.x += 80.0
	_expect(Tappable.canvas_rect(plate).position.is_equal_approx(Vector2(120, 35)) and is_inf(target.hit_score(Vector2(60, 50), false)), "moving the plate updates geometry without a cached hit rectangle")
	_expect(target.prompt_rect().is_equal_approx(Tappable.canvas_rect(plate)), "prompt and hit geometry share the same transformed plate")
	plate.hide()
	_expect(is_inf(target.hit_score(Vector2(140, 50), true)), "hidden plates retain geometry but cannot take a touch")
	_expect(not target.prompt_rect().has_area(), "hidden targets supply no drawn prompt anchor")
	holder.free()
