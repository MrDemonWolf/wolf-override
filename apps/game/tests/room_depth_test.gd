extends "res://tests/support/game_suite.gd"
## The layered rooms: the mid plate's walkway is the floor, stations stand on it, and no plate edge
## shows at either end of the camera's travel, in the opening or at the chapter-close shot.

## Camera shake moves Camera2D.offset by up to this much (world px at the play zoom).
const SHAKE: float = 10.0


func _run() -> void:
	check_name = "Room depth"
	var game: Node2D = await start_game("room-depth-test", keep_running)
	var path: String = str(game.get("save_path"))
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
		["close-up, right end", Vector2(960.0 - 480.0 / 1.55, 352.0), 1.55, 0.0],
	]
	camera.position_smoothing_enabled = false
	for framing: Array in framings:
		camera.zoom = Vector2.ONE * float(framing[2])
		for shake: float in ([-framing[3], framing[3]] if framing[3] > 0.0 else [0.0]):
			var view: Rect2 = await _view_at(camera, framing[1], shake)
			for room_name: String in rooms:
				_check_coverage("%s, %s, shake %d" % [room_name, framing[0], int(shake)], rooms[room_name], view)
	camera.offset = Vector2.ZERO
	# The junction's view stops at the room's edge, like the others' (the right-end framings above).
	_expect(JunctionRoom.EXIT_VIEW_RIGHT == RoomDepth.ROOM_WIDTH, "the junction's view stops at the room's edge, where the plates and their bleeds cover it")
	# Every station stands on the floor, as tall as the art it replaced.
	var floor_props: Dictionary = {
		"purge display": game.get_node("PurgeTerminalArt"),
		"breaker": game.get_node("BreakerArt"),
		"relay": game.get_node("RelayArt"),
		"safe point": game.get_node("CheckpointArt"),
		"purge queue": records.get_node("PurgeArt"),
		"mirror port": records.get_node("MirrorArt"),
		"junction breaker": junction.breaker_art,
		"junction relief vent": junction.vent_art,
		"junction valve": junction.valve_art,
		"junction arm panel": junction.arm_panel_art,
		"junction bolt panel": junction.bolt_panel_art,
	}
	for prop_name: String in floor_props:
		var prop: Sprite2D = floor_props[prop_name]
		_expect(is_equal_approx(snappedf(_bottom(prop), 0.5), 440.0), "the %s's base is on the floor (y 440, got %.2f)" % [prop_name, _bottom(prop)])
	# The corridor's purge display and the Records PURGE QUEUE are both 1.80 m consoles on the walk line,
	# so they are drawn the same height (72 world px at 40 px per metre).
	var display_height: float = RoomDepth.prop_bounds(floor_props["purge display"]).size.y
	var queue_height: float = RoomDepth.prop_bounds(floor_props["purge queue"]).size.y
	_expect(absf(display_height - queue_height) < 0.5, "the purge display is as tall as the purge queue (%.1f and %.1f px)" % [display_height, queue_height])
	# The Records stations' named sizes are their pieces' own (their half widths are read from them).
	for station: Array in [[records.get_node("PurgeArt"), RecordsRoom.PURGE_SIZE, "PURGE QUEUE"], [records.get_node("MirrorArt"), RecordsRoom.MIRROR_SIZE, "MIRROR PORT"]]:
		_expect(RoomDepth.prop_region(station[0]).size == station[1], "the %s's named size is its piece's (%s)" % [station[2], RoomDepth.prop_region(station[0]).size])
	# The corridor's curtain stands across the corridor in the cross-wall's turned face, drawn shut at rest
	# over the whole painted curtain (its art's u from the near guide to the far one), and it crosses the
	# walk line (y 440) at the collision face.
	var curtain: SealLeaf = game.get("seal_leaf") as SealLeaf
	_expect(curtain.visible and curtain.open == 0.0 and SealLeaf.column_u(0) > 0.99 and SealLeaf.column_u(SealLeaf.COLUMNS.size() - 1) < 0.01, "the corridor seal's curtain is drawn shut across its whole art")
	var foot_a: Vector3 = SealLeaf.COLUMNS[4]
	var foot_b: Vector3 = SealLeaf.COLUMNS[5]
	var crossing_x: float = foot_a.x + (foot_b.x - foot_a.x) * (440.0 - foot_a.y) / (foot_b.y - foot_a.y)
	# The curtain hangs 70 mm in front of the wall's face, so it meets the walk line 3 px before the
	# collision face: the engineer stopped there stands against it.
	_expect(absf(crossing_x - 752.0) < 3.5, "the corridor seal's curtain meets the walk line at the collision face (x %.1f)" % crossing_x)
	_check_exit_door(junction)
	_check_junction_entry(junction)
	# The junction's shut leaf ends on the doorway's near jamb foot, on the deck in front of the walk line.
	var leaf: Sprite2D = junction.door_leaf
	_expect(absf(leaf.position.y + leaf.region_rect.size.y * leaf.scale.y - JunctionRoom.NEAR_JAMB_FOOT.y) < 1.0, "the junction door's leaf stands on the deck at its near jamb")
	var vent: Rect2 = _global_rect(junction.vent_art)
	_expect(absf(vent.position.x - PressureLine.VENT_GRATE_MIN_X) < 0.01 and absf(vent.end.x - PressureLine.VENT_GRATE_MAX_X) < 0.01, "the relief vent art spans exactly the grate's hurtbox (%s)" % vent)
	var tank: Rect2 = _global_rect(junction.tank)
	var arm: Rect2 = _global_rect(junction.arm_art)
	var shackle: Vector2 = junction.global_position + RoomDepth.prop_point(junction.arm_art, JunctionRoom.ARM_SHACKLE)
	_expect(absf(shackle.x - DropArm.MARK_X) < 0.01 and absf(arm.end.y - shackle.y) < 0.01 and tank.position.y > shackle.y and absf(tank.get_center().x - DropArm.MARK_X) < 0.01, "the hung tank hangs centred over the mark below the arm's shackle, on its cable (shackle %s, tank top %.1f)" % [shackle, tank.position.y])
	_check_records_doors(records)
	_check_characters(game)
	game.queue_free()
	await process_frame
	for leftover: String in [path, "%s-settings.cfg" % path]:
		remove_file(leftover)
	finish("Room depth checks passed")


func _check_plates(room_name: String, depth: RoomDepth) -> void:
	_expect(depth.painting != null and depth.mid_painting != null and depth.near_painting != null, "%s has far, mid and near plates" % room_name)
	_expect(depth.far_dust.z_index < depth.mid_layer.z_index and depth.far_dust.z_index >= depth.backdrop_layer.z_index and depth.far_dust.get_index() > depth.backdrop_layer.get_index(), "%s: the far dust drifts over the far wall and behind the mid plate" % room_name)
	var mid: Sprite2D = depth.mid_layer.get_node("Painting") as Sprite2D
	_expect(is_equal_approx(mid.position.y + depth.walkway_y * mid.scale.y, RoomDepth.FLOOR_Y), "%s: the mid plate's walkway is the floor" % room_name)
	_expect(mid.position.x == 0.0 and is_equal_approx(mid.texture.get_width() * mid.scale.x, RoomDepth.ROOM_WIDTH), "%s: the mid plate spans the room 1:1" % room_name)
	var far: Rect2 = depth.far_rect()
	for index: int in depth.lamps.size():
		var lamp_y: float = far.position.y + depth.lamps[index].y * far.size.y
		# The approved plates (art swap PR 3) hang the ceiling lamps over the play view's top (y 160 at the
		# keyboard framing), as the art set's phone frames show them: they stay on the far plate.
		_expect(lamp_y > far.position.y and lamp_y < far.end.y, "%s: ceiling lamp %d (y %.0f) is on the far plate" % [room_name, index, lamp_y])


## The far plate fills the view, the mid plate (with its bleeds) reaches both sides and the bottom
## of it, and the near strips' outer edges stay outside it. The bottom matters where the floor is
## painted on the mid plate (the junction): past its end the far plate's wall would show instead.
func _check_coverage(label: String, depth: RoomDepth, view: Rect2) -> void:
	var far: Rect2 = _global_rect(depth.backdrop).merge(_global_rect(depth.backdrop_layer.get_node("BottomBleed") as Sprite2D))
	_expect(far.encloses(view), "%s: the far plate fills the view (%s vs %s)" % [label, far, view])
	var mid_span: Rect2 = _global_rect(depth.mid_layer.get_node("Painting") as Sprite2D)
	mid_span = mid_span.merge(_global_rect(depth.mid_layer.get_node("LeftBleed") as Sprite2D)).merge(_global_rect(depth.mid_layer.get_node("RightBleed") as Sprite2D))
	_expect(mid_span.position.x <= view.position.x and mid_span.end.x >= view.end.x, "%s: the mid plate reaches both view edges" % label)
	var bottom: Rect2 = _global_rect(depth.mid_layer.get_node("BottomBleed") as Sprite2D)
	_expect(bottom.position.x <= view.position.x and bottom.end.x >= view.end.x and bottom.end.y >= view.end.y and is_equal_approx(bottom.position.y, mid_span.end.y), "%s: the mid plate's bottom bleed spans the view's width and reaches its bottom (%s vs %s)" % [label, bottom, view])
	# A room may leave either near strip out (Records, whose two ends are door walls); where it has
	# one, its outer edge is off screen.
	var left_edge: Sprite2D = depth.near_layer.get_node_or_null("LeftEdge") as Sprite2D
	_expect((left_edge == null) == (not depth.near_left_edge), "%s: the left near strip is there only if the room asks for it" % label)
	if left_edge != null:
		_expect(_global_rect(left_edge).position.x < view.position.x, "%s: the left near strip's outer edge is off screen" % label)
	# A room may leave its mirrored right strip out (the corridor, whose right end opens into the
	# machinery room past the seal); where it has one, its outer edge is off screen too.
	var right_edge: Sprite2D = depth.near_layer.get_node_or_null("RightEdge") as Sprite2D
	_expect((right_edge == null) == (not depth.near_right_edge), "%s: the right near strip is there only if the room asks for it" % label)
	if right_edge != null:
		_expect(_global_rect(right_edge).end.x > view.end.x, "%s: the right near strip's outer edge is off screen" % label)


## The engineer, WOLF and the Director are whole pieces from assets/characters, each drawn at its
## world height (the engineer at the pieces' own 1/8, the Director at his own 1/5.5, WOLF at
## Main.WOLF_ART_SCALE, the size he was drawn before the repaint), sampled through the shared
## sharp_sprite material; each floor reflection samples with the same mip bias.
func _check_characters(game: Node2D) -> void:
	var characters: Dictionary = {
		"engineer": [game.get_node("Human/BodySprite"), Vector2i(217, 562), 562.0 / 8.0],
		"WOLF": [game.get_node("Wolf/BodySprite"), Vector2i(1028, 549), 549.0 * Main.WOLF_ART_SCALE],
		"Director": [game.get_node("IntroDirector"), Vector2i(114, 391), 391.0 / 5.5],
	}
	var shared: Material = null
	for label: String in characters:
		var sprite: Sprite2D = characters[label][0]
		var shader_material: ShaderMaterial = sprite.material as ShaderMaterial
		_expect(Vector2i(sprite.texture.get_size()) == characters[label][1], "the %s texture is its whole piece, %s (got %s)" % [label, characters[label][1], sprite.texture.get_size()])
		_expect(absf(sprite.texture.get_height() * sprite.scale.y - float(characters[label][2])) < 0.01, "the %s keeps its world height (%.2f px)" % [label, sprite.texture.get_height() * sprite.scale.y])
		_expect(sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS and sprite.texture.get_image().has_mipmaps(), "the %s samples a mipmapped texture" % label)
		_expect(shader_material != null and shader_material.shader.resource_path == "res://assets/shaders/sharp_sprite.gdshader" and is_equal_approx(FloorReflection.lod_bias_of(sprite), -0.5), "the %s draws through the sharp sprite material at a -0.5 mip bias" % label)
		_expect(shared == null or shared == shader_material, "the characters share one sharp sprite material")
		shared = shader_material
		var reflection: FloorReflection = sprite.get_parent().get_node(NodePath(sprite.name + "Reflection")) as FloorReflection
		_expect(reflection != null and is_equal_approx(float((reflection.material as ShaderMaterial).get_shader_parameter("lod_bias")), -0.5), "the %s's floor reflection samples with the same mip bias" % label)
	var breaker: Sprite2D = game.get_node("BreakerArt") as Sprite2D
	_expect(FloorReflection.lod_bias_of(breaker) == 0.0 and is_equal_approx(float((breaker.get_parent().get_node("BreakerArtReflection").material as ShaderMaterial).get_shader_parameter("lod_bias")), 0.0), "props keep the default mip selection, and so do their reflections")


## The Records doors stand across the walkway: each shut leaf's room face meets the walk line (y 440)
## at its collision face, the open exit leaf stands behind the walk line clear of the doorway, the
## security container stands on the floor behind the walk line, and every leaf is somewhere on its
## hinges in every state (nothing fades or hides).
func _check_records_doors(records: RecordsRoom) -> void:
	_check_swing_leaf(records.exit_leaf, RecordsRoom.EXIT_DOOR_X, "exit", "Records exit")
	_check_swing_leaf(records.entry_leaf, RecordsRoom.ENTRY_DOOR_X, "entry", "Records entry")
	var box: Rect2 = records.container_rect()
	_expect(box.position.x >= RecordsRoom.CONTAINER_SPAN.x - 2.0 and box.position.x <= RecordsRoom.CONTAINER_SPAN.x and box.end.y >= 440.0 and box.end.y <= 446.0, "the security container stands on the floor where the stations expect it (%s)" % box)
	_expect(SwingLeaf.project(records.exit_leaf.hinge + records.exit_leaf.leaf_dir(PI * 0.5) * SwingLeaf.LEAF_W).x > RecordsRoom.CONTAINER_SPAN.y + 20.0, "the open exit leaf stops clear of the container and of the engineer working it")


## The junction's entry (review r1, M5): the shut leaf's junction face meets the walk line at its
## collision face in the junction's own camera, the open leaf stands behind the walk line, the leaf is
## drawn whole at every swing, the camera-facing hatch is gone and no near pipe column hides the wall.
func _check_junction_entry(junction: JunctionRoom) -> void:
	_check_swing_leaf(junction.entry_leaf, JunctionRoom.ENTRY_DOOR_X, "junction entry", "junction entry")
	_expect(JunctionRoom.WOLF_CLEAR_X - M0Actor.WOLF_REACH > JunctionRoom.ENTRY_DOOR_X, "WOLF waiting by the entrance stands clear of the shut entry")
	_expect(junction.get("entry_hatch_art") == null and not junction.depth.near_left_edge, "the camera-facing hatch is gone and no pipe column stands in front of the entry")


## One swing leaf (the Records exit and entry, the junction entry): in its own room's camera (its
## [member SwingLeaf.vpx] and [member SwingLeaf.horizon], which for the Records leaves are
## DoorCamera's defaults), the shut leaf's room face meets the walk line (y 440) within 1 px of
## [param face_x], its collision face; the open leaf stands behind the walk line; it is drawn whole
## shut, half open and open; and its light holds through the swing. [param label] names it in the
## messages ("exit" reads "the exit's shut leaf ..."), [param light_label] in _check_leaf_light's. It
## leaves the leaf shut.
func _check_swing_leaf(leaf: SwingLeaf, face_x: float, label: String, light_label: String) -> void:
	var shut_foot_hinge: Vector2 = SwingLeaf.project(leaf.hinge, leaf.vpx, leaf.horizon)
	var shut_foot_free: Vector2 = SwingLeaf.project(leaf.hinge + leaf.leaf_dir(0.0) * SwingLeaf.LEAF_W, leaf.vpx, leaf.horizon)
	var crossing_x: float = shut_foot_hinge.x + (shut_foot_free.x - shut_foot_hinge.x) * (440.0 - shut_foot_hinge.y) / (shut_foot_free.y - shut_foot_hinge.y)
	_expect(absf(crossing_x - face_x) < 1.0, "the %s's shut leaf meets the walk line at its collision face (x %.1f)" % [label, crossing_x])
	var open_free: Vector3 = leaf.hinge + leaf.leaf_dir(PI * 0.5) * SwingLeaf.LEAF_W
	_expect(open_free.z > 0.1 and leaf.hinge.z > 0.1, "the open %s leaf stands behind the walk line, out of the walkway" % label)
	for opening: float in [0.0, 0.5, 1.0]:
		leaf.open = opening
		_expect(leaf.visible and leaf.modulate.a == 1.0, "the %s leaf is drawn whole at %.0f %% open" % [label, opening * 100.0])
	leaf.open = 0.0
	_check_leaf_light(leaf, light_label)


## Fix round 4 (review r4, M1): the leaf draws the face its room's pinhole camera sees (the room face up to
## about 30 degrees, where a view straight along +d had switched at 17-18), and through the swing the lit
## paint at the middle of that face stays within 5 % of the shut leaf's or above it (no black card mid-swing).
## Which face the camera sees is checked on screen, not with the leaf's own 3D test: the room face's
## outline, projected, keeps the winding it has shut exactly while the camera stays on the room side
## of its plane (a pinhole view mirrors a plane's outline once the eye crosses to its back).
func _check_leaf_light(leaf: SwingLeaf, label: String) -> void:
	var shut_turn: float = signf(_room_face_turn(leaf, 0.0))
	var agrees: bool = leaf.room_face_shows(0.0) and shut_turn != 0.0
	for degrees: int in range(0, 91, 2):
		var theta: float = deg_to_rad(float(degrees))
		agrees = agrees and leaf.room_face_shows(theta) == (signf(_room_face_turn(leaf, theta)) == shut_turn)
	_expect(agrees and leaf.room_face_shows(deg_to_rad(24.0)) and not leaf.room_face_shows(deg_to_rad(60.0)), "the %s leaf draws the face its room's camera sees (the room face still at 24 degrees)" % label)
	var shut: float = _face_level(leaf, 0.0)
	var lowest: float = shut
	for degrees: int in range(2, 91, 2):
		lowest = minf(lowest, _face_level(leaf, deg_to_rad(float(degrees))))
	_expect(lowest >= 0.95 * shut, "the %s leaf's face stays lit through its swing (lowest %.3f against %.3f shut)" % [label, lowest, shut])


## The signed screen area (world px squared) of the room face's hinge-foot, latch-foot, hinge-head
## corners at swing [param theta], projected in the leaf's own room camera. Its sign is the outline's
## winding; it flips only when the camera crosses the face's plane.
func _room_face_turn(leaf: SwingLeaf, theta: float) -> float:
	var foot: Vector2 = SwingLeaf.project(leaf.hinge, leaf.vpx, leaf.horizon)
	var latch: Vector2 = SwingLeaf.project(leaf.hinge + leaf.leaf_dir(theta) * SwingLeaf.LEAF_W, leaf.vpx, leaf.horizon)
	var head: Vector2 = SwingLeaf.project(leaf.hinge + Vector3(0.0, SwingLeaf.LEAF_H, 0.0), leaf.vpx, leaf.horizon)
	return (latch - foot).cross(head - foot)


## The vertex light (luminance of SwingLeaf.shade) at the middle of the face the camera sees (1.07 m
## up, half the leaf's width from the hinge), on the face SwingLeaf.visible_face says the leaf draws.
func _face_level(leaf: SwingLeaf, theta: float) -> float:
	var face: Array = leaf.visible_face(theta)
	var p: Vector3 = (face[1] as Vector3) + leaf.leaf_dir(theta) * (SwingLeaf.LEAF_W * 0.5) + Vector3(0.0, 1.07, 0.0)
	var c: Color = leaf.shade(p, face[2] as Vector3)
	return c.get_luminance()


func _global_rect(sprite: Sprite2D) -> Rect2:
	return sprite.get_global_transform() * sprite.get_rect()


func _bottom(prop: Sprite2D) -> float:
	return _global_rect(prop).end.y


## The world rect [param camera] shows at its current zoom, placed at [param at] with the shake
## offset [param shake] (world px: right by shake and down by |shake|), once two process frames have
## drawn it there (the camera takes its new position on the next frame).
func _view_at(camera: Camera2D, at: Vector2, shake: float) -> Rect2:
	camera.position = at
	camera.offset = Vector2(shake, absf(shake))
	await process_frame
	await process_frame
	var half: Vector2 = Vector2(960.0, 540.0) * 0.5 / camera.zoom
	return Rect2(camera.get_screen_center_position() - half, half * 2.0)


## The junction's exit door: behind the mid plate its passage, the sliding leaf and the wall's face draw in
## that order; its leaf stands on the sill shut and slides back along the wall into the pocket in the far
## jamb, never fading, and the near jamb stands where the walk line meets the wall.
func _check_exit_door(junction: JunctionRoom) -> void:
	var behind: Node2D = junction.depth.behind
	_expect(junction.exit_leaf.get_parent() == behind and junction.exit_wall.get_parent() == behind and behind.get_node("ExitBack").get_index() < junction.exit_leaf.get_index() and junction.exit_leaf.get_index() < junction.exit_wall.get_index(), "the passage, the leaf and the wall's face draw in that order, behind the mid plate")
	var shut: Vector3 = JunctionRoom.exit_leaf_anchor(0.0)
	var half: Vector3 = JunctionRoom.exit_leaf_anchor(0.5)
	var open: Vector3 = JunctionRoom.exit_leaf_anchor(1.0)
	# (In the junction's own camera since review r1: vanishing point (511, 162).)
	_expect(absf(shut.x - 983.2) < 0.5 and absf(shut.y - 442.9) < 0.5, "shut, the leaf's leading edge stands on the sill inside the near jamb (%s)" % shut)
	_expect(open.x < half.x and half.x < shut.x and open.y < shut.y and absf(open.x - 935.2) < 0.5 and open.z < 1.0, "opening, the leaf slides back along the wall into the far jamb's pocket, smaller with distance (%s)" % open)
	var saved: float = junction.hatch_open
	junction.hatch_open = 1.0
	_expect(junction.exit_leaf.visible and junction.exit_leaf.modulate.a == 1.0, "the open leaf is still there, in the pocket")
	junction.hatch_open = saved
	_expect(JunctionRoom.EXIT_NEAR_JAMB_X > JunctionRoom.EXIT_DOOR_X and JunctionRoom.HUMAN_GONE_X - M0Actor.HUMAN_REACH > JunctionRoom.EXIT_NEAR_JAMB_X and JunctionRoom.WOLF_GONE_X - M0Actor.WOLF_REACH > JunctionRoom.EXIT_NEAR_JAMB_X, "walking out, each stops only once all of them is behind the near jamb")
