extends SceneTree
## Scratch capture driver for the PIN design mock (not part of the repo).

var out_dir: String = ""
var game: Node2D
var tools: DebugTools


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	out_dir = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Node2D
	game.set("settings_path", "user://pin-settings.cfg")
	game.set("save_path", "user://pin-save.json")
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	await _frames(2)
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	tools = game.get("debug_tools")
	tools.debug_build = true
	await _wait(0.8)
	tools.actions.jump(&"records_mirror")
	await _wait(1.6)
	tools.hide_note()
	game.debug_place(272.0, 230.0)
	await _wait(1.0)
	await _shot("records-base")
	tools.actions.jump(&"tank_down")
	await _wait(1.6)
	tools.hide_note()
	var station: Vector4 = Main.JUNCTION_STATIONS[3]
	var spot: float = game.debug_station_side_x(station, station.x - 1.0)
	game.debug_place(spot, spot - 70.0)
	await _wait(1.5)
	await _shot("junction-base")
	game.queue_free()
	await _frames(2)
	quit(0)


func _shot(label: String) -> void:
	await _wait(0.3)
	await _frames(3)
	var image: Image = root.get_texture().get_image()
	image.save_png(out_dir.path_join(label + ".png"))
	print("shot ", label, " ", image.get_size())


func _wait(seconds: float) -> void:
	await create_timer(seconds, true).timeout


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame
