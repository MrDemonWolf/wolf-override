class_name InputMode
extends RefCounted
## Owns the last input class, active pad ID and pointer-focus policy shared by play, menus and debug UI.
## It never reads or changes bindings, saves preferences, or operates controls.

## A real input changed the class or active pad; views refresh from the new state.
signal changed

enum Kind { KEYBOARD, POINTER, TOUCH, CONTROLLER }
## Existing input-switch and rebinding thresholds, fractions of full stick travel; drift must not switch UI.
const SWITCH_THRESHOLD: float = 0.45
const CAPTURE_THRESHOLD: float = 0.65
const NAVIGATION_ACTIONS: Array[StringName] = [&"ui_accept", &"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev"]

var _kind: Kind = Kind.TOUCH if OS.has_feature("ios") or OS.has_feature("android") else Kind.KEYBOARD
var _controller_device: int = -1
## Script overrides notify the same views as native input; observe coalesces its two field changes.
var kind: Kind:
	get: return _kind
	set(value):
		if _kind != value:
			_kind = value
			changed.emit()
var controller_device: int:
	get: return _controller_device
	set(value):
		if _controller_device != value:
			_controller_device = value
			changed.emit()
## Mouse motion can hide a focus ring without replacing controller or keyboard prompts.
var pointer_focus: bool = false
## Existing Main/test properties remain views of this owner, not separate state.
var touch_enabled: bool:
	get: return kind == Kind.TOUCH
	set(value):
		if value or kind == Kind.TOUCH:
			kind = Kind.TOUCH if value else Kind.KEYBOARD
var controller_active: bool:
	get: return kind == Kind.CONTROLLER
	set(value):
		if value or kind == Kind.CONTROLLER:
			kind = Kind.CONTROLLER if value else Kind.KEYBOARD


## Updates input identity from event and returns whether it is a keyboard/controller navigation press.
## Emulated mouse events and small stick movements leave identity and focus policy unchanged.
func observe(event: InputEvent) -> bool:
	if event.device == InputEvent.DEVICE_ID_EMULATION and (event is InputEventMouseButton or event is InputEventMouseMotion):
		return false
	var previous_kind: Kind = kind
	var previous_pad: int = controller_device
	var navigation: bool = navigation_press(event)
	if event is InputEventJoypadButton and event.pressed or event is InputEventJoypadMotion and absf(event.axis_value) > SWITCH_THRESHOLD:
		_kind = Kind.CONTROLLER
		_controller_device = event.device
	elif event is InputEventKey and event.pressed:
		_kind = Kind.KEYBOARD
	elif event is InputEventScreenTouch and event.pressed or event is InputEventScreenDrag:
		_kind = Kind.TOUCH
	elif event is InputEventMouseButton and event.pressed:
		_kind = Kind.POINTER
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		pointer_focus = true
	elif navigation or event is InputEventScreenTouch or event is InputEventScreenDrag:
		pointer_focus = false
	if previous_kind != kind or previous_pad != controller_device:
		changed.emit()
	return navigation


## Whether touch controls and their larger targets should be shown for the current input class.
func touch_layout() -> bool:
	return touch_enabled


## The existing menu-navigation threshold, shared with debug UI; releases never restore focus.
static func navigation_press(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed or event is InputEventJoypadButton and event.pressed or event is InputEventJoypadMotion and absf(event.axis_value) > SWITCH_THRESHOLD


## Binding storage uses keyboard/controller kinds regardless of whether the input is pressed.
static func binding_kind(event: InputEvent) -> String:
	return "keyboard" if event is InputEventKey else ("controller" if event is InputEventJoypadButton or event is InputEventJoypadMotion else "")


## Returns -1 for an LB press, +1 for an RB press, or 0 for every other event, including releases.
static func tab_step(event: InputEvent) -> int:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			return -1
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			return 1
	return 0
