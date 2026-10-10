extends SceneTree
## The layered rooms: the mid plate's walkway is the floor, stations stand on it, and no plate edge
## shows at either end of the camera's travel, in the opening or at the chapter-close shot.

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
## Camera shake moves Camera2D.offset by up to this much (world px at the play zoom).
const SHAKE: float = 10.0

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var path: String = "user://room-depth-test-%s.json" % OS.get_process_id()
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	game.set("settings_path", "%s-settings.cfg" % path)
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	await process_frame
	var camera: Camera2D = game.get_node("IntroCamera") as Camera2D
	var records: RecordsRoom = game.get("records_room") as RecordsRoom
	var junction: JunctionRoom = game.get("junction_room") as JunctionRoom
	var rooms: Dictionary = {"corridor": game.get_node("CorridorDepth") as RoomDepth, "records": records.depth, "junction": junction.depth}
	for room_name: String in rooms:
		var depth: RoomDepth = rooms[room_name]
		_check_plates(room_name, depth)
	# The play camera's clamp at zoom 1.35 (Main.GAMEPLAY_ZOOM).
	var half_play: float = 960.0 / 1.35 * 0.5
	var touch_y: float = (game.get_script() as Script).get_script_constant_map()["GAMEPLAY_CAMERA_Y_TOUCH"]
	var framings: Array[Array] = [
		["play, left end", Vector2(half_play, 360.0), 1.35, SHAKE],
		["play, right end", Vector2(960.0 - half_play, 360.0), 1.35, SHAKE],
		["touch play, left end", Vector2(half_play, touch_y), 1.35, SHAKE],
		["touch play, right end", Vector2(960.0 - half_play, touch_y), 1.35, SHAKE],
		["opening", Vector2(267.0, 355.0), 1.8, 0.0],
		["opening, pan", Vector2(300.0, 355.0), 1.95, 0.0],
		["chapter close", Vector2(960.0 - 480.0 / 1.55, 352.0), 1.55, 0.0],
	]
	camera.position_smoothing_enabled = false
	for framing: Array in framings:
		camera.zoom = Vector2.ONE * float(framing[2])
		for shake: float in ([-framing[3], framing[3]] if framing[3] > 0.0 else [0.0]):
			camera.position = framing[1]
			camera.offset = Vector2(shake, absf(shake))
			await process_frame
			await process_frame
			var half: Vector2 = Vector2(960.0, 540.0) * 0.5 / camera.zoom
			var view: Rect2 = Rect2(camera.get_screen_center_position() - half, half * 2.0)
			for room_name: String in rooms:
				_check_coverage("%s, %s, shake %d" % [room_name, framing[0], int(shake)], rooms[room_name], view)
	camera.offset = Vector2.ZERO
	# Every station stands on the floor, as tall as the art it replaced.
	var floor_props: Dictionary = {
		"breaker": game.get_node("BreakerArt"),
		"relay": game.get_node("RelayArt"),
		"safe point": game.get_node("CheckpointArt"),
		"purge queue": records.get_node("PurgeArt"),
		"mirror port": records.get_node("MirrorArt"),
		"exit": records.exit_art,
		"junction breaker": junction.breaker_art,
		"junction relief vent": junction.vent_art,
		"junction valve": junction.valve_art,
		"junction arm panel": junction.arm_panel_art,
		"junction bolt panel": junction.bolt_panel_art,
		"junction entry hatch": junction.entry_hatch_art,
		"junction exit hatch": junction.hatch_art,
	}
	for prop_name: String in floor_props:
		var prop: Sprite2D = floor_props[prop_name]
		_expect(is_equal_approx(snappedf(_bottom(prop), 0.5), 440.0), "the %s's base is on the floor (y 440, got %.2f)" % [prop_name, _bottom(prop)])
	var door: Sprite2D = game.get_node("Door/Visual/DoorArt") as Sprite2D
	_expect(absf(door.get_global_transform().origin.y + door.region_rect.size.y * door.scale.y * 0.5 - 440.0) < 0.5, "the corridor seal stands on the floor")
	_expect(absf(junction.door_art.get_global_transform().origin.y + junction.door_art.region_rect.size.y * junction.door_art.scale.y * 0.5 - 440.0) < 0.5, "the junction door stands on the floor")
	var vent: Rect2 = _global_rect(junction.vent_art)
	_expect(absf(vent.position.x - PressureLine.VENT_GRATE_MIN_X) < 0.01 and absf(vent.end.x - PressureLine.VENT_GRATE_MAX_X) < 0.01, "the relief vent art spans exactly the grate's hurtbox (%s)" % vent)
	var tank: Rect2 = _global_rect(junction.tank)
	var arm: Rect2 = _global_rect(junction.arm_art)
	_expect(absf(tank.position.y - arm.end.y) < 0.01 and absf(tank.get_center().x - DropArm.MARK_X) < 0.01, "the hung tank sits on the arm's cut line, centred over the mark")
	_expect(is_equal_approx(records.exit_art.position.y, RecordsRoom.EXIT_REST.y), "the exit hatch rests where the chapter close resets it")
	_expect(records.exit_art.z_index >= 0 and records.exit_art.z_as_relative, "the exit hatch draws over the open doorway the records room paints, so its lift-away shows")
	game.queue_free()
	await process_frame
	for leftover: String in [path, "%s-settings.cfg" % path]:
		if FileAccess.file_exists(leftover):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(leftover))
	if failures == 0:
		print("Room depth checks passed")
	quit(1 if failures > 0 else 0)


func _check_plates(room_name: String, depth: RoomDepth) -> void:
	_expect(depth.painting != null and depth.mid_painting != null and depth.near_painting != null, "%s has far, mid and near plates" % room_name)
	_expect(depth.far_dust.z_index < depth.mid_layer.z_index and depth.far_dust.z_index >= depth.backdrop_layer.z_index and depth.far_dust.get_index() > depth.backdrop_layer.get_index(), "%s: the far dust drifts over the far wall and behind the mid plate" % room_name)
	var mid: Sprite2D = depth.mid_layer.get_node("Painting") as Sprite2D
	_expect(is_equal_approx(mid.position.y + depth.walkway_y * mid.scale.y, RoomDepth.FLOOR_Y), "%s: the mid plate's walkway is the floor" % room_name)
	_expect(mid.position.x == 0.0 and is_equal_approx(mid.texture.get_width() * mid.scale.x, RoomDepth.ROOM_WIDTH), "%s: the mid plate spans the room 1:1" % room_name)
	var far: Rect2 = depth.far_rect()
	for index: int in depth.lamps.size():
		var lamp_y: float = far.position.y + depth.lamps[index].y * far.size.y
		_expect(lamp_y >= 168.0, "%s: ceiling lamp %d (y %.0f) is inside the play view" % [room_name, index, lamp_y])


## The far plate fills the view and the near strips' outer edges stay outside it.
func _check_coverage(label: String, depth: RoomDepth, view: Rect2) -> void:
	var far: Rect2 = _global_rect(depth.backdrop)
	_expect(far.encloses(view), "%s: the far plate fills the view (%s vs %s)" % [label, far, view])
	var mid_span: Rect2 = _global_rect(depth.mid_layer.get_node("Painting") as Sprite2D)
	mid_span = mid_span.merge(_global_rect(depth.mid_layer.get_node("LeftBleed") as Sprite2D)).merge(_global_rect(depth.mid_layer.get_node("RightBleed") as Sprite2D))
	_expect(mid_span.position.x <= view.position.x and mid_span.end.x >= view.end.x, "%s: the mid plate reaches both view edges" % label)
	var left: Rect2 = _global_rect(depth.near_layer.get_node("LeftEdge") as Sprite2D)
	var right: Rect2 = _global_rect(depth.near_layer.get_node("RightEdge") as Sprite2D)
	_expect(left.position.x < view.position.x and right.end.x > view.end.x, "%s: the near strips' outer edges are off screen" % label)


func _global_rect(sprite: Sprite2D) -> Rect2:
	return sprite.get_global_transform() * sprite.get_rect()


func _bottom(prop: Sprite2D) -> float:
	return _global_rect(prop).end.y


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("Room depth check failed: " + label)
