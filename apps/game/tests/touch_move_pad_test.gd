extends "res://tests/support/game_suite.gd"
## A thumb owns one pad until release/cancel, and resizing or another input cannot leave it moving.
const PAD = preload("res://scripts/touch_move_pad.gd")


func _run() -> void:
	check_name = "Touch move pad"
	var pad = PAD.new()
	root.add_child(pad)
	pad.enabled = true
	pad.configure(Rect2(0, 0, 960, 540), 90.0, 0.25)
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = 4
	touch.position = Vector2(100, 400)
	touch.pressed = true
	_expect(pad.begin(touch) and pad.axis == 0.0, "a free left-zone press claims a neutral pad")
	var other: InputEventScreenTouch = touch.duplicate() as InputEventScreenTouch
	other.index = 6
	_expect(not pad.begin(other) and pad.finger == 4, "a second finger cannot replace the owner")
	var drag: InputEventScreenDrag = InputEventScreenDrag.new()
	drag.index = 4
	drag.position = touch.position + Vector2(5, 100)
	pad.observe(drag)
	_expect(pad.axis == 0.0, "vertical travel and small horizontal drift remain neutral")
	drag.position = touch.position + Vector2(90, 0)
	pad.observe(drag)
	_expect(pad.axis == 1.0 and pad.offset.x == pad.radius, "long drags clamp to full right movement")
	other.pressed = false
	pad.observe(other)
	_expect(pad.axis == 1.0, "another finger's release cannot stop the owner's movement")
	pad.configure(Rect2(0, 0, 960, 540), 90.0, 0.25)
	_expect(pad.finger == 4 and pad.axis == 1.0, "identical layout calls do not interrupt the thumb")
	pad.configure(Rect2(40, 0, 920, 540), 90.0, 0.25)
	_expect(pad.finger == PAD.NO_FINGER and pad.axis == 0.0, "safe-area changes release movement")
	_expect(pad.begin(touch), "a fresh gesture can start after resizing")
	drag.position = touch.position - Vector2(90, 0)
	pad.observe(drag)
	_expect(pad.axis == -1.0, "leftward drag gives a negative axis")
	touch.canceled = true
	pad.observe(touch)
	_expect(pad.axis == 0.0 and pad.finger == PAD.NO_FINGER, "OS cancellation releases the owner even if pressed remains set")
	touch.canceled = false
	var stick: InputEventJoypadMotion = InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_LEFT_X
	stick.axis_value = 0.1
	pad.begin(touch)
	pad.observe(drag)
	pad.observe(stick)
	_expect(pad.axis == -1.0, "idle controller drift does not interrupt the thumb")
	pad.cancel()
	stick.axis_value = 0.7
	for takeover: InputEvent in [key_event(KEY_D), controller_button(JOY_BUTTON_A, true), stick]:
		pad.begin(touch)
		pad.observe(drag)
		pad.observe(takeover)
		_expect(pad.axis == 0.0 and pad.finger == PAD.NO_FINGER, "keyboard or controller takeover clears touch movement")

	touch.position = Vector2(800, 400)
	_expect(not pad.begin(touch), "the right side is not a movement catch zone")
	touch.position = Vector2(100, 400)
	pad.begin(touch)
	pad.observe(drag)
	pad.hide()
	_expect(pad.axis == 0.0 and pad.finger == PAD.NO_FINGER, "hiding the overlay cannot retain a moving thumb")
	var game: Main = await start_game("touch-pad-movement", keep_running) as Main
	game.call("_new_game")
	game.call("_finish_intro")
	pad.show()
	pad.axis_changed.connect(func(value: float) -> void: game.human.touch_axis = value)
	touch.position = Vector2(100, 400)
	touch.pressed = true
	pad.begin(touch)
	drag.position = touch.position + Vector2(90, 0)
	pad.observe(drag)
	var start_x: float = game.human.position.x
	game.human.pointer_target_x = start_x + 100.0
	await frames(6)
	_expect(game.human.position.x > start_x and is_inf(game.human.pointer_target_x), "thumb movement uses the actor's live movement path and replaces pointer navigation")
	Input.action_press(&"move_left")
	_expect(game.human.player_axis() == -1.0, "physical movement takes priority over a held thumb")
	Input.action_press(&"move_right")
	_expect(game.human.player_axis() == 0.0 and game.human.has_move_input(), "opposing physical inputs stay neutral without losing held-input bookkeeping")
	Input.action_release(&"move_right")
	Input.action_release(&"move_left")
	game.human.touch_axis = INF
	_expect(game.human.touch_axis == 0.0, "non-finite thumb input cannot reach movement")
	game.human.touch_axis = -2.0
	_expect(game.human.touch_axis == -1.0, "thumb input is bounded to the movement axis")
	game.human.controlled = false
	_expect(game.human.touch_axis == 0.0, "an authored control lock clears the local thumb axis")
	game.human.controlled = true
	touch.position = Vector2(100, 200)
	game.call("_note_input_device", touch)
	await settle(3)
	_expect(game.touch_move_pad.is_visible_in_tree() and game.touch_move_pad.enabled, "touch input enables the live HUD pad")
	_expect(not game.touch_left.visible and not game.touch_right.visible, "the pad replaces the old arrow pair")
	_expect(game.world_input.handle_unhandled(touch), "an empty left-zone press reaches the pad through world routing")
	_expect(game.touch_move_pad.finger == touch.index and game.world_input.active.is_empty(), "the pad owns its finger without occupying the object gesture slot")
	drag.position = touch.position + Vector2(90, 0)
	game.call("_input", drag)
	_expect(game.human.touch_axis > 0.0, "native HUD drag reaches the engineer without global action injection")
	other.pressed = true
	other.position = game.touch_use.get_global_rect().get_center()
	root.push_input(other, true)
	await settle(1)
	_expect(Input.is_action_pressed(&"interact") and game.touch_move_pad.finger == touch.index, "the native USE button accepts a second finger while MOVE stays held")
	other.pressed = false
	root.push_input(other, true)
	await settle(1)
	_expect(not Input.is_action_pressed(&"interact") and game.human.touch_axis > 0.0, "releasing USE leaves the movement thumb held")
	game.call("_pause_game")
	_expect(game.human.touch_axis == 0.0 and game.touch_move_pad.finger == PAD.NO_FINGER, "pausing cancels the live thumb immediately")
	game.call("_resume_game")
	pad.cancel()
	pad.queue_free()
	await settle(2)
	await end_game(game)
	await settle(2)
	finish("Touch move pad checks passed")
