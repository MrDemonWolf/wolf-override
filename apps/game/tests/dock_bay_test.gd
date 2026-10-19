extends "res://tests/support/game_suite.gd"
## The opening's dock bay (DockBay, layout L1): its whole pieces load at the size the art set made them,
## each has an entry in the asset register, the near column draws over the actors, the corridor's
## chapter lets the engineer walk through the opening into the bay and stops them at its end wall, the
## camera eases continuously from the corridor's first framing to the whole room without showing past
## the room's plate, and the Director's door swings and badges.

## Each piece's world size in the art set's manifest (world_px, at 40 world px per metre), keyed by the
## node DockBay names it.
const SIZES: Dictionary = {
	"Room/Plate": Vector2(690.3, 504.1),
	"Room/ExitLeaf": Vector2(36.2, 83.5),
	"Room/ExitTrim": Vector2(33.0, 61.0),
	"Room/Casing": Vector2(52.0, 119.0),
	"Room/Beyond": Vector2(48.0, 93.0),
	"Front/NearColumn": Vector2(17.9, 340.4),
}
## Each piece's file, which must be in the asset register.
const FILES: Array[String] = [
	"apps/game/assets/rooms/dock-mid.png",
	"apps/game/assets/doors/dock-exit-leaf.png",
	"apps/game/assets/doors/dock-exit-trim.png",
	"apps/game/assets/doors/dock-corridor-casing.png",
	"apps/game/assets/doors/dock-corridor-beyond.png",
	"apps/game/assets/doors/dock-corridor-front.png",
]
## Drawn sizes may differ from the manifest's rounded world sizes by this much (world px).
const SIZE_SLACK: float = 0.6
## The walk back pans no faster than this (world px per second): a pan, not a cut.
const MAX_PAN_SPEED: float = 400.0


func _run() -> void:
	check_name = "Dock bay"
	var game: Node2D = await start_game("dock-bay-test", keep_running)
	game.call("_new_game")
	game.call("_finish_intro")
	await frames(30)
	var bay: DockBay = game.get("dock_bay") as DockBay
	var human: M0Actor = game.get_node("Human") as M0Actor
	var camera: Camera2D = game.get_node("IntroCamera") as Camera2D
	if not _require(bay != null and bay.is_visible_in_tree(), "the dock bay is built and shows in the corridor's chapter"):
		return
	for path: String in SIZES:
		var sprite: Sprite2D = bay.get_node_or_null(path) as Sprite2D
		if not _expect(sprite != null and sprite.texture != null, "%s is drawn" % path):
			continue
		var drawn: Vector2 = sprite.get_rect().size * sprite.scale.abs()
		_expect(drawn.distance_to(SIZES[path]) <= SIZE_SLACK, "%s is drawn at the art set's size (%s, drawn %s)" % [path, SIZES[path], drawn])
	var plate: Sprite2D = bay.get_node("Room/Plate") as Sprite2D
	_expect(plate.position.is_equal_approx(DockBay.PLATE_AT), "the room plate stands at the art set's place, its walk line on the corridor's")
	var register: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/manifest.json"))
	var paths: Array = []
	for entry: Dictionary in register["assets"]:
		paths.append(entry["path"])
	for file: String in FILES:
		_expect(file in paths, "%s has an entry in the asset register" % file)
	_expect(drawn_z(bay.front) > drawn_z(human), "the cross-wall's near column draws over the actors")
	_expect(not bay.exit_passage.visible and is_equal_approx(bay.exit_leaf.scale.x, 1.0 / DockBay.EXIT_LEAF_DENSITY), "the Director's door stands shut")
	bay.set_exit(1.0, 1.0)
	_expect(bay.exit_passage.visible and bay.exit_leaf.scale.x < 0.2 / DockBay.EXIT_LEAF_DENSITY and bay.exit_reader.color.is_equal_approx(Palette.LAMP_OPEN), "badged and open, the leaf swings away on its hinges over a dark passage and the reader shows green")
	bay.set_exit(0.0, 0.0)
	_expect(bay.exit_reader.color.is_equal_approx(Palette.LAMP_SHUT), "shut again, the reader is red")

	# Walking left from first control: the camera eases from the corridor's framing to the whole room.
	var half_view: float = 960.0 / camera.zoom.x * 0.5
	var start_left: float = camera.get_screen_center_position().x - half_view
	_expect(absf(start_left - Main.L1_CORRIDOR_MIN_VIEW_X) <= 1.0, "first control's view starts at x %.0f, the opening at its edge (got %.1f)" % [Main.L1_CORRIDOR_MIN_VIEW_X, start_left])
	# The pan's speed over each tenth of a second (six physics frames), as the eye sees a pan.
	var samples: Array[float] = []
	var fastest: float = 0.0
	var leftmost_view: float = INF
	Input.action_press(&"move_left")
	for _frame: int in 360:
		await physics_frame
		var x: float = camera.get_screen_center_position().x
		samples.append(x)
		if samples.size() > 6:
			fastest = maxf(fastest, absf(x - samples[samples.size() - 7]) * 10.0)
		leftmost_view = minf(leftmost_view, x - half_view)
	Input.action_release(&"move_left")
	_expect(is_equal_approx(human.position.x, DockBay.HUMAN_MIN_X), "the engineer walks through the opening and stops at the bay's end wall (x %.1f)" % human.position.x)
	_expect(fastest <= MAX_PAN_SPEED, "the camera pans into the room continuously (fastest %.0f px/s)" % fastest)
	_expect(leftmost_view >= DockBay.VIEW_LEFT - 0.5, "the view never shows past the end wall into the plate's dark margin (%.1f)" % leftmost_view)
	_expect(await wait_until(func() -> bool: return absf(camera.get_screen_center_position().x - Main.L1_ROOM_VIEW_CENTRE) <= 1.0, 120), "the camera settles on the whole room, the bay to the opening")
	_expect(str(game.call("_context_hint")) != "E: read the Director's purge display.", "the corridor's purge display is not offered from the bay")
	await end_game(game)
	finish("Dock bay checks passed")
