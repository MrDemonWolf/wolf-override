class_name AtomicFile
extends RefCounted
## Writes a small text file so a reader never meets a half-written copy: the text goes to a temporary
## file beside it first ([method temp_path]), and only a complete, flushed copy replaces the real one.
## The one home for this: the checkpoint (M0State.save_to_disk) and the settings file (GameSettings,
## Main's display options, the debug unlock) all write through here.

## Appended to a path to name its temporary copy. M0State.load_from_disk reads that copy back when it
## holds newer progress than the checkpoint, so the suffix is part of the save format.
const TEMP_SUFFIX: String = ".tmp"


## The temporary copy [method write_text] writes before it replaces [param path].
static func temp_path(path: String) -> String:
	return path + TEMP_SUFFIX


## Writes [param text] (UTF-8) to [param path], a user:// or absolute file path, by way of
## [method temp_path]. Returns true when [param path] holds the whole text. On false [param path] is
## as it was; the temporary copy may still hold the new text, which [method promote] can move into
## place later (M0State.load_from_disk does).
static func write_text(path: String, text: String) -> bool:
	var temp: String = temp_path(path)
	var file: FileAccess = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	var stored: bool = file.store_string(text)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if not stored or write_error != OK:
		return false
	return promote(temp, path)


## Moves the file at [param from] over [param to] (user:// or absolute paths) and returns true when
## [param to] then holds its content. A rename comes first, since it swaps the whole file in one step.
## A rename can fail where a copy works (on Windows, for one, while another program holds the target
## open), so the copy is the fallback, and [param from] is removed only after the copy succeeded. On
## false [param from] is kept, so the new content is not lost.
static func promote(from: String, to: String) -> bool:
	var global_from: String = ProjectSettings.globalize_path(from)
	var global_to: String = ProjectSettings.globalize_path(to)
	if DirAccess.rename_absolute(global_from, global_to) == OK:
		return true
	# Neither a rename nor a copy can replace a folder standing at [param to]; copying onto one only
	# logs an engine error.
	if DirAccess.dir_exists_absolute(global_to):
		return false
	if DirAccess.copy_absolute(global_from, global_to) != OK:
		return false
	# A copy left behind is harmless: it holds the same content as [param to].
	DirAccess.remove_absolute(global_from)
	return true
