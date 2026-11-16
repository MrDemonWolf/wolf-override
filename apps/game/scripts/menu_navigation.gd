class_name MenuNavigation
extends RefCounted
## Shared controller tab input for Settings and the debug menu; it changes no input bindings.


## Returns -1 for an LB press, +1 for an RB press, or 0 for every other event, including releases.
static func tab_step(event: InputEvent) -> int:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
			return -1
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
			return 1
	return 0
