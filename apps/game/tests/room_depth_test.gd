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
	# The corridor's curtain stands across the corridor in the cross-wall's turned face: it crosses the
	# walk line (y 440) at the collision face, and its art ends at its near-jamb corner, in front of it.
	_expect(absf(door.get_global_transform().origin.y + door.region_rect.size.y * door.scale.y * 0.5 - float(game.get("CORRIDOR_SEAL_FOOT_Y"))) < 0.5, "the corridor seal's curtain ends at its near-jamb foot")
	var foot_a: Vector3 = SealLeaf.COLUMNS[4]
	var foot_b: Vector3 = SealLeaf.COLUMNS[5]
	var crossing_x: float = foot_a.x + (foot_b.x - foot_a.x) * (440.0 - foot_a.y) / (foot_b.y - foot_a.y)
	# The curtain hangs 70 mm in front of the wall's face, so it meets the walk line 3 px before the
	# collision face: the engineer stopped there stands against it.
	_expect(absf(crossing_x - 752.0) < 3.5, "the corridor seal's curtain meets the walk line at the collision face (x %.1f)" % crossing_x)
	_expect(absf(junction.door_art.get_global_transform().origin.y + junction.door_art.region_rect.size.y * junction.door_art.scale.y * 0.5 - 440.0) < 0.5, "the junction door stands on the floor")
	var vent: Rect2 = _global_rect(junction.vent_art)
	_expect(absf(vent.position.x - PressureLine.VENT_GRATE_MIN_X) < 0.01 and absf(vent.end.x - PressureLine.VENT_GRATE_MAX_X) < 0.01, "the relief vent art spans exactly the grate's hurtbox (%s)" % vent)
	var tank: Rect2 = _global_rect(junction.tank)
	var arm: Rect2 = _global_rect(junction.arm_art)
	_expect(absf(tank.position.y - arm.end.y) < 0.01 and absf(tank.get_center().x - DropArm.MARK_X) < 0.01, "the hung tank sits on the arm's cut line, centred over the mark")
	_expect(is_equal_approx(records.exit_art.position.y, RecordsRoom.EXIT_REST.y), "the exit hatch rests where the chapter close resets it")
	_expect(records.exit_art.z_index >= 0 and records.exit_art.z_as_relative, "the exit hatch draws over the open doorway the records room paints, so its lift-away shows")
	_check_characters(game)
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


## The far plate fills the view, the mid plate (with its bleeds) reaches both sides and the bottom
## of it, and the near strips' outer edges stay outside it. The bottom matters where the floor is
## painted on the mid plate (the junction): past its end the far plate's wall would show instead.
func _check_coverage(label: String, depth: RoomDepth, view: Rect2) -> void:
	var far: Rect2 = _global_rect(depth.backdrop)
	_expect(far.encloses(view), "%s: the far plate fills the view (%s vs %s)" % [label, far, view])
	var mid_span: Rect2 = _global_rect(depth.mid_layer.get_node("Painting") as Sprite2D)
	mid_span = mid_span.merge(_global_rect(depth.mid_layer.get_node("LeftBleed") as Sprite2D)).merge(_global_rect(depth.mid_layer.get_node("RightBleed") as Sprite2D))
	_expect(mid_span.position.x <= view.position.x and mid_span.end.x >= view.end.x, "%s: the mid plate reaches both view edges" % label)
	var bottom: Rect2 = _global_rect(depth.mid_layer.get_node("BottomBleed") as Sprite2D)
	_expect(bottom.position.x <= view.position.x and bottom.end.x >= view.end.x and bottom.end.y >= view.end.y and is_equal_approx(bottom.position.y, mid_span.end.y), "%s: the mid plate's bottom bleed spans the view's width and reaches its bottom (%s vs %s)" % [label, bottom, view])
	var left: Rect2 = _global_rect(depth.near_layer.get_node("LeftEdge") as Sprite2D)
	_expect(left.position.x < view.position.x, "%s: the left near strip's outer edge is off screen" % label)
	# A room may leave its mirrored right strip out (the corridor, whose right end opens into the
	# machinery room past the seal); where it has one, its outer edge is off screen too.
	var right_edge: Sprite2D = depth.near_layer.get_node_or_null("RightEdge") as Sprite2D
	_expect((right_edge == null) == (not depth.near_right_edge), "%s: the right near strip is there only if the room asks for it" % label)
	if right_edge != null:
		_expect(_global_rect(right_edge).end.x > view.end.x, "%s: the right near strip's outer edge is off screen" % label)


## The engineer, WOLF and the Director use art downscaled from the masters in art-source/characters,
## drawn at the masters' world size (1536 x 0.047 and 1015 x 0.0733 world px tall), sampled through
## the shared sharp_sprite material; each floor reflection samples with the same mip bias.
func _check_characters(game: Node2D) -> void:
	var characters: Dictionary = {
		"engineer": [game.get_node("Human/BodySprite"), Vector2i(256, 384), 1536.0 * 0.047],
		"WOLF": [game.get_node("Wolf/BodySprite"), Vector2i(761, 406), 1015.0 * 0.0733],
		"Director": [game.get_node("IntroDirector"), Vector2i(256, 384), 1536.0 * 0.047],
	}
	var shared: Material = null
	for label: String in characters:
		var sprite: Sprite2D = characters[label][0]
		var shader_material: ShaderMaterial = sprite.material as ShaderMaterial
		_expect(Vector2i(sprite.texture.get_size()) == characters[label][1], "the %s texture is the downscaled %s (got %s)" % [label, characters[label][1], sprite.texture.get_size()])
		_expect(absf(sprite.texture.get_height() * sprite.scale.y - float(characters[label][2])) < 0.01, "the %s keeps its world height (%.2f px)" % [label, sprite.texture.get_height() * sprite.scale.y])
		_expect(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS and sprite.texture.get_image().has_mipmaps(), "the %s samples a mipmapped texture" % label)
		_expect(shader_material != null and shader_material.shader.resource_path == "res://assets/shaders/sharp_sprite.gdshader" and is_equal_approx(FloorReflection.lod_bias_of(sprite), -0.5), "the %s draws through the sharp sprite material at a -0.5 mip bias" % label)
		_expect(shared == null or shared == shader_material, "the characters share one sharp sprite material")
		shared = shader_material
		var reflection: FloorReflection = sprite.get_parent().get_node(NodePath(sprite.name + "Reflection")) as FloorReflection
		_expect(reflection != null and is_equal_approx(float((reflection.material as ShaderMaterial).get_shader_parameter("lod_bias")), -0.5), "the %s's floor reflection samples with the same mip bias" % label)
	var breaker: Sprite2D = game.get_node("BreakerArt") as Sprite2D
	_expect(FloorReflection.lod_bias_of(breaker) == 0.0 and is_equal_approx(float((breaker.get_parent().get_node("BreakerArtReflection").material as ShaderMaterial).get_shader_parameter("lod_bias")), 0.0), "props keep the default mip selection, and so do their reflections")


func _global_rect(sprite: Sprite2D) -> Rect2:
	return sprite.get_global_transform() * sprite.get_rect()


func _bottom(prop: Sprite2D) -> float:
	return _global_rect(prop).end.y


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("Room depth check failed: " + label)
