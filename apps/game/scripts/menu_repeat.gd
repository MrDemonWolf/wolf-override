class_name MenuRepeat
extends Node
## Repeats only native pad directions through the existing GUI action path; never emits gameplay input.
## The caller supplies the current menu/page as context, or null while gameplay/capture owns input.
## It also scrolls the long list or page the caller names: the right stick scrolls it steadily and the
## triggers move it a page at a time (LT up, RT down). Scrolling never moves focus or presses anything.

const DIRECTIONS: Array[StringName] = [&"ui_up", &"ui_down", &"ui_left", &"ui_right"]
## Existing mockup proposals, in seconds and repeats/second; real-device keyboard matching remains unverified.
static var DELAY: float = UiTokens.seconds("timing.input-repeat.delay")
static var RATE: float = UiTokens.number("timing.input-repeat.rate")
## Steady scroll speed in canvas px per second at full tilt: the changelog's existing held-key speed,
## shared so every long page reads at one pace.
const SCROLL_SPEED: float = 260.0
## A trigger press moves this share of the visible height, so one line of the old page stays in view.
const PAGE_FRACTION: float = 0.8
## A trigger counts as pressed past this travel (0 to 1); it must come back under it to page again.
const TRIGGER_THRESHOLD: float = 0.5
var context: Callable
## Returns the ScrollContainer or RichTextLabel to scroll now, or null while nothing long is open.
var scroll_context: Callable
var _scope: Control
var _action: StringName = &""
var _device: int = -1
var _remaining: float = 0.0
var _focused: bool = true
## Right stick tilt (-1 up to 1 down) and the pad it came from; 0 while centred or after a cancel.
var _scroll_tilt: float = 0.0
var _scroll_device: int = -1
## Sub-pixel scroll left over between frames: ScrollContainer positions are whole px.
var _scroll_carry: float = 0.0
## Trigger axes (per device) that are past TRIGGER_THRESHOLD, so one pull pages once.
var _triggers_down: Dictionary = {}


## Menus continue during pause; disconnected active pads cannot leave a direction repeating.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_connection)


## Watches the same native events as InputMode; the engine performs the initial move itself.
func observe(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		_observe_scroll(event as InputEventJoypadMotion)
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


## Records right-stick tilt and pages once per trigger pull. Stick values under InputMode's switch
## threshold count as centred, so a resting stick never drifts a page.
func _observe_scroll(event: InputEventJoypadMotion) -> void:
	if event.axis == JOY_AXIS_RIGHT_Y:
		_scroll_tilt = event.axis_value if absf(event.axis_value) > InputMode.SWITCH_THRESHOLD else 0.0
		_scroll_device = event.device if _scroll_tilt != 0.0 else -1
	elif event.axis == JOY_AXIS_TRIGGER_LEFT or event.axis == JOY_AXIS_TRIGGER_RIGHT:
		var key: Vector2i = Vector2i(event.device, event.axis)
		var down: bool = event.axis_value > TRIGGER_THRESHOLD
		if down and not _triggers_down.has(key) and _focused:
			var target: Control = scroll_context.call() if scroll_context.is_valid() else null
			if target != null:
				scroll_by(target, target.size.y * PAGE_FRACTION * (-1.0 if event.axis == JOY_AXIS_TRIGGER_LEFT else 1.0))
		if down:
			_triggers_down[key] = true
		else:
			_triggers_down.erase(key)


## Moves [param target] (a ScrollContainer or a RichTextLabel with its own bar) down by [param pixels]
## canvas px, up when negative; the control clamps at its ends. Any other control is left alone.
static func scroll_by(target: Control, pixels: float) -> void:
	if target is ScrollContainer:
		(target as ScrollContainer).scroll_vertical += roundi(pixels)
	elif target is RichTextLabel:
		(target as RichTextLabel).get_v_scroll_bar().value += pixels


## The long list inside [param scope]: the ScrollContainer holding the focused control, else [param scope]
## itself or its first visible ScrollContainer. Null when [param scope] is null or holds none.
static func scroll_under(scope: Control) -> ScrollContainer:
	if scope == null:
		return null
	var focus: Control = scope.get_viewport().gui_get_focus_owner()
	var node: Node = focus if focus != null and (focus == scope or scope.is_ancestor_of(focus)) else null
	while node != null and node != scope.get_parent():
		if node is ScrollContainer:
			return node as ScrollContainer
		node = node.get_parent()
	if scope is ScrollContainer:
		return scope as ScrollContainer
	for child: Node in scope.find_children("*", "ScrollContainer", true, false):
		if (child as ScrollContainer).is_visible_in_tree():
			return child as ScrollContainer
	return null


## Sends at most one GUI direction per frame after the initial delay; late frames never cause a burst.
func _process(delta: float) -> void:
	_scroll(delta)
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


## Scrolls the caller's long page while the right stick is tilted, whole px at a time.
func _scroll(delta: float) -> void:
	if _scroll_tilt == 0.0:
		_scroll_carry = 0.0
		return
	var target: Control = scroll_context.call() if scroll_context.is_valid() else null
	if target == null or not _focused:
		_scroll_carry = 0.0
		return
	_scroll_carry += _scroll_tilt * SCROLL_SPEED * delta
	var whole: float = float(int(_scroll_carry))
	if whole != 0.0:
		_scroll_carry -= whole
		scroll_by(target, whole)


## Drops held intent without changing InputMap state, focus or the current menu.
func cancel() -> void:
	_action = &""
	_scope = null
	_device = -1


## A reconnect never resumes a previously held direction.
func _on_connection(device: int, connected: bool) -> void:
	if not connected and device == _device:
		cancel()
	if not connected:
		if device == _scroll_device:
			_scroll_tilt = 0.0
			_scroll_device = -1
		for key: Vector2i in _triggers_down.keys():
			if key.x == device:
				_triggers_down.erase(key)


## Focus loss clears intent; returning to the app requires a fresh native press.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_focused = false
		_scroll_tilt = 0.0
		_scroll_device = -1
		_triggers_down.clear()
		cancel()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_focused = true
