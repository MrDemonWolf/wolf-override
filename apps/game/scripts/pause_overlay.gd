class_name PauseOverlay
extends ColorRect

signal resume_requested


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause_game"):
		resume_requested.emit()
		get_viewport().set_input_as_handled()
