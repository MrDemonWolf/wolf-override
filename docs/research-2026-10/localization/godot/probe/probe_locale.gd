extends SceneTree
## Prints the locale Godot starts in (step research-godot), to check `--language` and the test setting.
## Contract: `godot --headless --path <probe> [--language X] --script res://probe_locale.gd`.
func _initialize() -> void:
	print("RESULT start locale = %s (OS %s)" % [TranslationServer.get_locale(), OS.get_locale()])
	quit(0)
