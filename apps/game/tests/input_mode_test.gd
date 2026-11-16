extends "res://tests/support/game_suite.gd"
## Pure input-policy checks: actual input classes, emulated mouse events, stick drift and active pad IDs.


func _run() -> void:
	check_name = "Input mode"
	var mode: InputMode = InputMode.new()
	var default_kind: InputMode.Kind = InputMode.Kind.TOUCH if OS.has_feature("ios") or OS.has_feature("android") else InputMode.Kind.KEYBOARD
	_expect(mode.kind == default_kind and mode.controller_device == -1, "startup follows the platform and never assumes a connected pad")
	mode.kind = InputMode.Kind.KEYBOARD
	var changes: Array[int] = []
	mode.changed.connect(func() -> void: changes.append(1))
	var mouse: InputEventMouseMotion = InputEventMouseMotion.new()
	mode.observe(mouse)
	_expect(mode.kind == InputMode.Kind.KEYBOARD and mode.pointer_focus, "mouse motion hides focus without replacing keyboard prompts")
	var stick: InputEventJoypadMotion = InputEventJoypadMotion.new()
	stick.device = 7
	stick.axis_value = 0.44
	_expect(not mode.observe(stick) and mode.kind == InputMode.Kind.KEYBOARD, "small stick drift never changes the input class")
	stick.axis_value = 0.46
	_expect(mode.observe(stick) and mode.controller_active and mode.controller_device == 7 and not mode.pointer_focus, "a deliberate stick input selects the actual pad and restores focus")
	mode.observe(mouse)
	_expect(mode.controller_active, "mouse motion does not replace controller prompts")
	var tap: InputEventScreenTouch = InputEventScreenTouch.new()
	tap.pressed = true
	mode.observe(tap)
	_expect(mode.touch_layout() and not mode.controller_active, "a touch selects its layout on desktop as well as mobile")
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.pressed = true
	click.device = InputEvent.DEVICE_ID_EMULATION
	mode.observe(click)
	_expect(mode.touch_layout() and not mode.pointer_focus, "the emulated mouse press after touch cannot undo touch mode")
	mode.observe(key_event(KEY_E))
	_expect(mode.kind == InputMode.Kind.KEYBOARD and not mode.touch_layout(), "keyboard input switches away from touch")
	click.device = 0
	mode.observe(click)
	_expect(mode.kind == InputMode.Kind.POINTER and mode.pointer_focus, "a real mouse press selects pointer mode")
	var pad: InputEventJoypadButton = controller_button(JOY_BUTTON_A, true)
	pad.device = 11
	mode.observe(pad)
	_expect(mode.controller_device == 11 and mode.controller_active, "switching pads updates identity even within controller mode")
	pad.pressed = false
	_expect(not mode.observe(pad) and mode.controller_device == 11, "release events leave identity unchanged")
	_expect(InputMode.binding_kind(key_event(KEY_Q)) == "keyboard" and InputMode.binding_kind(stick) == "controller" and InputMode.binding_kind(tap).is_empty(), "bindings share the input type classification without accepting touch")
	_expect(changes.size() == 5, "views are notified once per identity change, never for drift, motion or releases")
	finish("Input mode checks passed")
