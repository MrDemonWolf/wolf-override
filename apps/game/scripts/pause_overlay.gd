class_name PauseOverlay
extends ColorRect
## The pause screen's dimmed backdrop (CanvasLayer/PauseOverlay in main.tscn), holding the pause menu and
## the settings menu. It runs while the tree is paused, so it turns Pause and Back presses into
## [signal resume_requested] (pause menu showing) or [signal back_requested] (settings showing) for Main to
## act on; it changes no state of its own.

signal resume_requested
signal back_requested
## Main's _input stops while the tree is paused, so the overlay forwards input for device and focus tracking.
signal input_seen(event: InputEvent)

## Looked up once: _input runs for every event while the overlay is up.
@onready var _settings_menu: GameSettings = get_node_or_null("Panel/SettingsMenu") as GameSettings


func _input(event: InputEvent) -> void:
	if not visible:
		return
	input_seen.emit(event)
	if not (event.is_action_pressed(&"pause_game") or event.is_action_pressed(&"ui_cancel")):
		return
	if _settings_menu != null and not _settings_menu.capture_action.is_empty():
		return
	if _settings_menu != null and _settings_menu.visible:
		back_requested.emit()
	else:
		resume_requested.emit()
	get_viewport().set_input_as_handled()
