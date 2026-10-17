@tool
extends EditorPlugin
## Generates the game's translation template (POT) with Godot 4.7.2's own generator, headlessly, then
## quits. Installed into a project only for the run by ../extract_pot.sh, never kept in it.
##
## Why this hack: 4.7.2 has no command-line POT switch and TranslationTemplateGenerator is not bound to
## scripts (editor/translations/template_generator.cpp; the only callers are LocalizationEditor's
## file dialog and the "Generate Translation Template" command-palette entry, localization_editor.cpp
## lines 411-430 and 920). The LocalizationEditor's save dialog is connected to _template_generate, so
## emitting its "file_selected" signal with a path runs the real generator on the files listed in
## internationalization/locale/translations_pot_files.
## Contract: run `godot --headless --editor --path <project>` with this plugin enabled and the
## environment variable I18N_POT_OUT set to an absolute .pot path (outside res://: a template inside the
## project would be scanned, and a .csv template imported as an empty translation). It waits until the
## first filesystem scan has finished, writes that file, prints "POT_PROBE wrote <path> exists=<bool>"
## and quits with 0, or prints "POT_PROBE failed: ..." and quits with 1. Without I18N_POT_OUT it does
## nothing, so an editor or export run that still has it enabled is left alone.
## Gotchas: relies on editor internals (node class names, dialog wiring) that can change in any release;
## it waits 30 frames before the scan check because the scan has not started on the first frames.
## History: first written as the research-godot step's probe (it wrote a .pot and a .csv into
## res://i18n_probe/out); changed to one POT at I18N_POT_OUT by the prototype step (2026-10-16); moved
## from the research branch codex/localization-research at 520cad1 (prototype/tools/pot_addon/) to
## scripts/i18n/pot_addon/ in PR L2, unchanged.

## The absolute .pot path from I18N_POT_OUT; empty when the plugin should stay idle.
var out_path: String = ""
## Frames processed so far, for the 30-frame wait before the first scan check.
var frames: int = 0


## Reads I18N_POT_OUT and processes only when it is set.
func _enter_tree() -> void:
	out_path = OS.get_environment("I18N_POT_OUT")
	set_process(not out_path.is_empty())


## Once the editor's first filesystem scan is over, finds the LocalizationEditor's save dialog and
## emits its file_selected with [member out_path], which runs the real generator, then quits.
func _process(_delta: float) -> void:
	frames += 1
	if frames < 30 or EditorInterface.get_resource_filesystem().is_scanning():
		return
	set_process(false)
	var editors: Array[Node] = EditorInterface.get_base_control().get_tree().root.find_children("*", "LocalizationEditor", true, false)
	if editors.is_empty():
		_finish("failed: no LocalizationEditor node", 1)
		return
	var dialog: Node = null
	for child: Node in editors[0].find_children("*", "EditorFileDialog", true, false):
		if child.get("file_mode") == EditorFileDialog.FILE_MODE_SAVE_FILE:
			dialog = child
	if dialog == null:
		_finish("failed: no save dialog under LocalizationEditor", 1)
		return
	dialog.emit_signal("file_selected", out_path)
	print("POT_PROBE wrote %s exists=%s" % [out_path, FileAccess.file_exists(out_path)])
	_finish("done", 0 if FileAccess.file_exists(out_path) else 1)


## Prints "POT_PROBE <message>" (extract_pot.sh greps for it) and quits the editor with [param code].
func _finish(message: String, code: int) -> void:
	print("POT_PROBE " + message)
	EditorInterface.get_base_control().get_tree().quit(code)
