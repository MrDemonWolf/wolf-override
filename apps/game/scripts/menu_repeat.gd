class_name MenuRepeat
extends Node
## Repeats only native pad directions through the existing GUI action path; never emits gameplay input.
## The caller supplies the current menu/page as context, or null while gameplay/capture owns input.

const DIRECTIONS: Array[StringName] = [&"ui_up", &"ui_down", &"ui_left", &"ui_right"]
## Existing mockup proposals, in seconds and repeats/second; real-device keyboard matching remains unverified.
static var DELAY: float = UiTokens.seconds("timing.input-repeat.delay")
static var RATE: float = UiTokens.number("timing.input-repeat.rate")
var context: Callable
var _scope: Control
var _action: StringName = &""
var _device: int = -1
var _remaining: float = 0.0
var _focused: bool = true


## Menus continue during pause; disconnected active pads cannot leave a direction repeating.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_connection)


## Watches the same native events as InputMode; the engine performs the initial move itself.
func observe(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not _action.is_empty() and event.device == _device and event.is_action_released(_action):
			cancel()
		for action: StringName in DIRECTIONS:
			if event.is_action_pressed(action):
				var scope: Control = context.call() if context.is_valid() else null
				if scope != null and _focused and (action != _action or event.device != _device or scope != _scope):
					_scope = scope
					_action = action
					_device = event.device
					_remaining = DELAY
				return
		if event.is_pressed():
			cancel()
	elif event is InputEventKey or event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventScreenDrag:
		cancel()


## Sends at most one GUI direction per frame after the initial delay; late frames never cause a burst.
func _process(delta: float) -> void:
	if _action.is_empty():
		return
	var scope: Control = context.call() if context.is_valid() else null
	if not _focused or not is_instance_valid(_scope) or scope != _scope or not Input.is_action_pressed(_action) or get_viewport().gui_get_focus_owner() == null:
		cancel()
		return
	_remaining -= delta
	if _remaining > 0.0:
		return
	_remaining = 1.0 / RATE
	var repeat: InputEventAction = InputEventAction.new()
	repeat.action = _action
	repeat.pressed = true
	get_viewport().push_input(repeat)


## Drops held intent without changing InputMap state, focus or the current menu.
func cancel() -> void:
	_action = &""
	_scope = null
	_device = -1


## A reconnect never resumes a previously held direction.
func _on_connection(device: int, connected: bool) -> void:
	if not connected and device == _device:
		cancel()


## Focus loss clears intent; returning to the app requires a fresh native press.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
		cancel()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
