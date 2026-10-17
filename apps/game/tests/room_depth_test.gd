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
	await _check_exit_view_edge(junction, camera, half_play, touch_y)
	# Every station stands on the floor, as tall as the art it replaced.
	var floor_props: Dictionary = {
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
	_check_exit_door(junction)
	_check_junction_entry(junction)
	# The junction's shut leaf ends on the doorway's near jamb foot, on the deck in front of the walk line.
	var leaf: Sprite2D = junction.door_leaf
	_expect(absf(leaf.position.y + leaf.region_rect.size.y * leaf.scale.y - JunctionDoorLayout.NEAR_JAMB_FOOT.y) < 1.0, "the junction door's leaf stands on the deck at its near jamb")
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


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("Room depth check failed: " + label)


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


## The junction's play view runs on past the room's end to JunctionRoom.EXIT_VIEW_RIGHT. Past the mid
## plate's right bleed only the exit's own pieces stand between the camera and the far plate, so at the
## right end (keyboard and touch framing, shaken both ways) they cover that strip down to the view's
## bottom: the deck's bleed carries it below the deck's end, which the touch framing shows, and the
## mirrored edge strips carry the passage and the deck past their end, which a shake shows.
func _check_exit_view_edge(junction: JunctionRoom, camera: Camera2D, half_play: float, touch_y: float) -> void:
	var mid_span: Rect2 = _global_rect(junction.depth.mid_layer.get_node("RightBleed") as Sprite2D)
	var cover: Array[Rect2] = []
	for piece: Sprite2D in [junction.exit_beyond, junction.exit_front, junction.exit_deck, junction.exit_deck_bleed]:
		cover.append(_global_rect(piece))
	for strip_name: String in ["ExitBeyondEdgeBleed", "ExitDeckEdgeBleed", "ExitDeckBleedEdgeBleed"]:
		var strip: Sprite2D = junction.get_node(strip_name) as Sprite2D
		_expect(strip.flip_h and strip.texture == JunctionRoom.EXIT_ATLAS, "the exit's %s mirrors its piece's last columns" % strip_name)
		cover.append(_global_rect(strip))
	_expect(junction.exit_deck_bleed.flip_v and absf(_global_rect(junction.exit_deck).end.y - _global_rect(junction.exit_deck_bleed).position.y - JunctionRoom.EXIT_SEAM_TRIM * JunctionRoom.EXIT_ATLAS_SCALE) < 0.01, "the exit deck's bleed mirrors its bottom rows on from the deck's end, overlapping its edge row")
	camera.zoom = Vector2.ONE * 1.35
	for camera_y: float in [360.0, touch_y]:
		for shake: float in [-SHAKE, SHAKE]:
			var view: Rect2 = await _view_at(camera, Vector2(JunctionRoom.EXIT_VIEW_RIGHT - half_play, camera_y), shake)
			var gaps: int = 0
			var first_gap: Vector2 = Vector2.ZERO
			var x: float = mid_span.end.x
			while x <= view.end.x:
				var y: float = view.position.y
				while y <= view.end.y:
					if not cover.any(func(rect: Rect2) -> bool: return rect.has_point(Vector2(x, y))):
						if gaps == 0:
							first_gap = Vector2(x, y)
						gaps += 1
					y += 2.0
				x += 2.0
			_expect(gaps == 0, "junction, %s play right end, shake %d: the exit's pieces cover the view past the mid plate (first gap at %s)" % ["touch" if camera_y == touch_y else "keyboard", int(shake), first_gap])
	camera.offset = Vector2.ZERO


## The junction's exit door: its pieces come from one atlas and draw in depth order (the passage, the
## leaf and the wall behind the walk line under the actors, the wall in front of it and the deck over
## them); its leaf stands on the sill shut and slides back along the wall into the pocket in the far
## jamb, never fading, and the near jamb stands where the walk line meets the wall.
func _check_exit_door(junction: JunctionRoom) -> void:
	var pieces: Array[Sprite2D] = [junction.exit_beyond, junction.exit_leaf, junction.exit_back, junction.exit_lens, junction.exit_front]
	_expect(pieces.all(func(piece: Sprite2D) -> bool: return piece != null and piece.texture == JunctionRoom.EXIT_ATLAS), "the exit door's pieces all come from its one atlas")
	var order: Array[int] = []
	for piece: Sprite2D in pieces:
		order.append(piece.get_index())
	_expect(order[0] < order[1] and order[1] < order[2] and order[2] < order[3] and order[3] < order[4], "the passage, leaf, wall and lamp draw in that order, the front wall after them")
	_expect(junction.exit_back.z_index < 0 and junction.exit_leaf.z_index < 0 and junction.exit_front.z_index == JunctionRoom.DOOR_FRONT_Z and junction.exit_deck.z_index == JunctionRoom.DOOR_FRONT_Z, "only the wall in front of the walk line and the deck draw over the actors")
	var saved: float = junction.hatch_open
	junction.hatch_open = 0.0
	var shut: Vector2 = junction.exit_leaf.position
	junction.hatch_open = 0.5
	var half: Vector2 = junction.exit_leaf.position
	junction.hatch_open = 1.0
	var open: Vector2 = junction.exit_leaf.position
	# (In the junction's own camera since review r1: vanishing point (511, 162).)
	_expect(absf(shut.x - 983.2) < 0.5 and absf(shut.y - 442.9) < 0.5, "shut, the leaf's leading edge stands on the sill inside the near jamb (%s)" % shut)
	_expect(open.x < half.x and half.x < shut.x and open.y < shut.y and absf(open.x - 935.2) < 0.5, "opening, the leaf slides back along the wall into the far jamb's pocket (%s)" % open)
	_expect(junction.exit_leaf.visible and junction.exit_leaf.modulate.a == 1.0 and junction.exit_leaf.scale.x < JunctionRoom.EXIT_ATLAS_SCALE, "the open leaf is still there, in the pocket and a little smaller with distance")
	junction.hatch_open = saved
	_expect(JunctionRoom.EXIT_NEAR_JAMB_X > JunctionRoom.EXIT_DOOR_X and JunctionRoom.HUMAN_GONE_X - M0Actor.HUMAN_REACH > JunctionRoom.EXIT_NEAR_JAMB_X and JunctionRoom.WOLF_GONE_X - M0Actor.WOLF_REACH > JunctionRoom.EXIT_NEAR_JAMB_X, "walking out, each stops only once all of them is behind the near jamb")
