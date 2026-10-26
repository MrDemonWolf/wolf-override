extends SceneTree
## Headless memory snapshot of the game before and after main.tscn (SMOOTH-3's measurement; never
## shipped: run.sh copies it into a scratch copy of the game as res://parity/). It writes one JSON file:
## - "before": just before load(main.tscn); "after": once the game has run AFTER_FRAMES frames in the
##   tree (title up, the sound bank's detailed clips rendered). Each holds Kit.counts() (Performance's
##   object, resource, node and orphan-node counts, static memory now and at its peak, resident set),
##   every resource in the cache with its size, and totals by type.
## - "generated": the sound bank's clips, made in code, so in no cache: their PCM bytes.
## Godot 4.7 has no call that lists the loaded resources (OS.print_all_resources is gone), so the
## probe walks every file under res:// (but .godot) and asks ResourceLoader.has_cached for each; a
## resource made at run time or embedded in a scene (a sub-resource) has no path of its own and only
## shows in the counts. Sizes, in bytes:
## - "bytes": what the resource holds in memory as far as the probe can tell: a texture's
##   width x height x 4 (RGBA8, no mipmaps; headless has no GPU, so this is what the texture would take
##   uncompressed, a ceiling for its VRAM), an AudioStreamWAV's PCM data, a FontFile's font data, and
##   for anything else the size of its file;
## - "stored": for an imported file, the size of its imported copy under .godot/imported (the
##   .ctex, .sample or .fontdata the game loads; a VRAM-compressed texture's is far below its "bytes"),
##   or -1.
## Nothing here names a game class (SfxBank, Main) as a type: a typed name or a preload loads that
## script, and every resource it preloads, while this script is parsed, before the "before" snapshot.
## The suites' kit comes the same way, through Kit.suite(), only for the teardown.
## Usage: scripts/parity/run.sh resources <out file>  (godot --headless ... -- --out=<file.json>)

const Kit = preload("parity_kit.gd")
## Frames the game runs before the "after" snapshot: 2 s of game time, by which the title is up and
## the detailed clips' worker (about 0.5 s, SfxBank) has finished; the probe also waits for it.
const AFTER_FRAMES: int = 120
## Resources listed one by one in each snapshot, largest "bytes" first; the totals count every one.
const LIST: int = 40

var result: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var files: Array[String] = []
	_walk("res://", files)
	result["files_checked"] = files.size()
	result["before"] = _snapshot(files)
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	game.set("save_path", "user://resources-save.json")
	game.set("settings_path", "user://resources-settings.cfg")
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	for _i: int in AFTER_FRAMES:
		await process_frame
	var bank: Node = game.get("sfx_bank")
	bank.call("wait_for_detail")
	result["after"] = _snapshot(files)
	result["generated"] = _generated(bank)
	result["engine"] = Engine.get_version_info()["string"]
	var f: FileAccess = FileAccess.open(Kit.arg("out", "user://resources.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(result, " ", false))
	f.close()
	# Stops the audio and lets the mixer let go before freeing, then removes the save and settings.
	await Kit.suite().end_game(game)
	print("resources done")
	quit()


## Kit.counts() plus every cached resource among [param files]: "cached" (how many), "totals" (bytes
## and stored bytes by type, and overall) and "largest" (the LIST largest by bytes, with path, type,
## bytes, stored and, for a texture, its size in px).
func _snapshot(files: Array[String]) -> Dictionary:
	var rows: Array[Dictionary] = []
	for path: String in files:
		if ResourceLoader.has_cached(path):
			rows.append(_row(path, ResourceLoader.get_cached_ref(path)))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["bytes"]) > int(b["bytes"]))
	var by_type: Dictionary = {}
	var total: int = 0
	var stored: int = 0
	for row: Dictionary in rows:
		var kind: String = row["type"]
		if not by_type.has(kind):
			by_type[kind] = {"count": 0, "bytes": 0, "stored": 0}
		by_type[kind]["count"] += 1
		by_type[kind]["bytes"] += int(row["bytes"])
		by_type[kind]["stored"] += maxi(int(row["stored"]), 0)
		total += int(row["bytes"])
		stored += maxi(int(row["stored"]), 0)
	var out: Dictionary = Kit.counts()
	out["cached"] = rows.size()
	out["totals"] = {"bytes": total, "stored": stored, "by_type": by_type}
	out["largest"] = rows.slice(0, LIST)
	return out


## One resource's row (see the header for what "bytes" and "stored" mean).
func _row(path: String, res: Resource) -> Dictionary:
	var row: Dictionary = {"path": path, "type": res.get_class(), "stored": _imported_size(path)}
	if res is Texture2D:
		var texture: Texture2D = res as Texture2D
		row["px"] = "%dx%d" % [texture.get_width(), texture.get_height()]
		row["bytes"] = texture.get_width() * texture.get_height() * 4
	elif res is AudioStreamWAV:
		row["bytes"] = (res as AudioStreamWAV).data.size()
	elif res is FontFile:
		row["bytes"] = (res as FontFile).data.size()
	else:
		row["bytes"] = _file_size(path)
	return row


## The sound bank's clips: each clip's PCM bytes (generated and recorded alike; the recorded ones are
## also in the cache under their paths), and the total.
func _generated(bank: Node) -> Dictionary:
	var clips: Dictionary = {}
	var total: int = 0
	var streams: Dictionary = bank.get("streams")
	for clip: StringName in streams:
		var stream: AudioStreamWAV = streams[clip] as AudioStreamWAV
		if stream != null and stream.resource_path.is_empty():
			clips[String(clip)] = stream.data.size()
			total += stream.data.size()
	return {"sfx_clips": clips, "sfx_bytes": total}


## The size in bytes of [param path]'s imported copy (the first of its .import file's dest_files),
## or -1 when it is not an imported file.
func _imported_size(path: String) -> int:
	if not FileAccess.file_exists(path + ".import"):
		return -1
	var config: ConfigFile = ConfigFile.new()
	if config.load(path + ".import") != OK:
		return -1
	var dest: Array = config.get_value("deps", "dest_files", [])
	return _file_size(str(dest[0])) if not dest.is_empty() else -1


## The size in bytes of the file at [param path], or -1 when it cannot be opened.
func _file_size(path: String) -> int:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	return file.get_length() if file != null else -1


## Every file under [param dir] (but .godot and dot folders) that is no .import or .uid sidecar,
## appended to [param out] as a res:// path.
func _walk(dir: String, out: Array[String]) -> void:
	for name: String in DirAccess.get_files_at(dir):
		if not (name.ends_with(".import") or name.ends_with(".uid")):
			out.append(dir.path_join(name))
	for sub: String in DirAccess.get_directories_at(dir):
		if not sub.begins_with("."):
			_walk(dir.path_join(sub), out)
