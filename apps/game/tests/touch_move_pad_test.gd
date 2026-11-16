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
	pad.queue_free()
	await settle(2)
	finish("Touch move pad checks passed")
