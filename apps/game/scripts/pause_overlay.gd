class_name PauseOverlay
extends ColorRect

signal resume_requested
signal back_requested
## Main's _input stops while the tree is paused, so the overlay forwards input for device and focus tracking.
signal input_seen(event: InputEvent)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	input_seen.emit(event)
	if not (event.is_action_pressed(&"pause_game") or event.is_action_pressed(&"ui_cancel")):
		return
	var settings_menu: GameSettings = get_node_or_null("Panel/SettingsMenu") as GameSettings
	if settings_menu != null and not settings_menu.capture_action.is_empty():
		return
	if settings_menu != null and settings_menu.visible:
		back_requested.emit()
	else:
		resume_requested.emit()
	get_viewport().set_input_as_handled()
