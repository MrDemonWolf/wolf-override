extends "res://tests/support/game_suite.gd"
## The corridor's round-7 additions, checked without playing: the caged beacons hang where main's
## drawn beacons were, and the inner blast leaf seals the whole opening when shut and is wholly in its
## wall pocket, behind the walk line, once open. (The leaf moving with the roller and the crank pose's
## hand on the wheel are checked in play by m0_scene_test.) Spawn, teardown and failure reporting come
## from the shared suite kit (tests/support/game_suite.gd).

## The corridor's beacon anchors (CorridorDepth/Backdrop/Beacon0 and Beacon1 and their WarningGlow
## sprites at load): main's (76d3a50) anchors at the far plate's fractions (0.341 and 0.659 across, 0.27
## down), on the whole-piece far plate drawn at world (0, 0) since art swap PR 3 (it shares the play
## plate's frame; the earlier plate hung 78.5 px lower, its anchors at y 224.3).
const MAIN_BEACONS: PackedVector2Array = [Vector2(327.36, 145.8), Vector2(632.64, 145.8)]
## Main's drawn beacon housing, relative to its anchor (RoomDepth.Beacon's fallback drawing).
const MAIN_HOUSING: Rect2 = Rect2(-7.0, -4.0, 14.0, 9.0)
## The cross-wall's clear opening along its face (metres from the walk line, design spec round 7):
## the near jamb (behind the column) and the far jamb (the pocket's mouth).
const JAMB_NEAR_A: float = -2.09069
const LEAF_LENGTH_M: float = 3.95
## The walk line (where the actors' feet are) crosses the wall face at a = 0, at world y
## RoomDepth.FLOOR_Y.
const WALK_A: float = 0.0


## One game from the title screen: the beacon and blast-leaf checks, then the kit's teardown (no
## sound, node or file left behind) and exit status.
func _run() -> void:
	check_name = "Corridor additions"
	var game: Node2D = await start_game("corridor-additions-test")
	# start_game waits one process frame; this suite always checked after two, so it still does.
	await process_frame
	_check_beacons(game)
	_check_blast_leaf(game)
	await end_game(game)
	finish("Corridor additions test passed")


## The corridor's two caged beacons (RoomDepth's painted beacon atlas): each stands on main's old
## anchor (MAIN_BEACONS), its lens is red, its globe hangs where main's drawn housing was, and its light
## is an additive region of the same atlas. Records Access and the Service Junction keep their drawn
## beacons (no atlas). Reads the live [param game] once, right after it loads; reports through _expect.
func _check_beacons(game: Node2D) -> void:
	var depth: RoomDepth = game.get_node("CorridorDepth") as RoomDepth
	_expect(depth.beacon_atlas != null and depth.beacon_regions.size() == MAIN_BEACONS.size() * RoomDepth.BEACON_ART_PARTS, "the corridor's beacons use the painted caged-lamp atlas")
	for index: int in MAIN_BEACONS.size():
		var beacon: Node2D = depth.get_node("Backdrop/Beacon%d" % index) as Node2D
		var glow: Sprite2D = depth.get_node("Backdrop/WarningGlow%d" % index) as Sprite2D
		if not _expect(beacon != null and glow != null, "beacon %d and its glow exist" % index):
			continue
		_expect(beacon.position.is_equal_approx(MAIN_BEACONS[index]) and glow.position.is_equal_approx(MAIN_BEACONS[index]), "beacon %d stands at main's anchor %s (beacon %s, glow %s)" % [index, MAIN_BEACONS[index], beacon.position, glow.position])
		var lens: Color = beacon.get("lens") as Color
		# Round 11: the lens dims with each flash (to warning_color.darkened(0.6) at the bottom), so check
		# its hue at any moment and its full colour at the top of the flash.
		var peak: Color = depth.warning_color
		_expect(lens.r > 0.35 and lens.g < lens.r * 0.35 and lens.b < lens.r * 0.35 and peak.r > 0.9 and peak.g < 0.35 and peak.b < 0.35, "beacon %d's lens is still red (now %s, at the top of a flash %s)" % [index, lens, peak])
		var parts: Array = beacon.get("parts") as Array
		if not _expect(beacon.get("art") != null and parts.size() == 6, "beacon %d draws the painted fixture, globe and guard" % index):
			continue
		var globe: Rect2 = parts[2] as Rect2
		_expect(globe.intersects(MAIN_HOUSING) and globe.get_center().length() <= 6.0, "beacon %d's red globe hangs where main's lamp was (globe %s, centre %.1f px from the anchor)" % [index, globe, globe.get_center().length()])
		_expect((glow.material as CanvasItemMaterial).blend_mode == CanvasItemMaterial.BLEND_MODE_ADD and glow.region_enabled and glow.texture == depth.beacon_atlas, "beacon %d's light is one additive region of the same atlas (no extra texture)" % index)
	# The other rooms keep their drawn beacons.
	for room: Node in game.find_children("*", "", true, false):
		if room is RoomDepth and room != depth:
			_expect((room as RoomDepth).beacon_atlas == null, "%s keeps its drawn beacons" % room.get_path())


## The inner blast leaf behind the roller, from BlastLeaf's own geometry (lead_at, project, in metres
## on the wall face and world px) and the live [param game]'s leaf: hidden at rest and drawn inside the
## wall, behind the cross-wall's face (both in the room's layer behind the mid plate, the leaf first);
## shut, it spans the opening from the near jamb; it waits for the roller to be 40 % up and only moves
## toward its pocket; open, it is wholly in the pocket with its foot behind the walk line; its edge
## thickness and contact shadow fit inside the 0.66 m wall, and the shadow is black. Reports through
## _expect.
func _check_blast_leaf(game: Node2D) -> void:
	var leaf: BlastLeaf = game.get("blast_leaf") as BlastLeaf
	var seal_leaf: SealLeaf = game.get("seal_leaf") as SealLeaf
	if not _expect(leaf != null and seal_leaf != null, "the corridor door has its inner blast leaf"):
		return
	_expect(not leaf.visible, "the inner blast leaf draws only while the seal moves")
	var wall: Sprite2D = game.get("seal_wall") as Sprite2D
	_expect(leaf.get_parent() == wall.get_parent() and leaf.get_index() < wall.get_index() and leaf.get_parent() == (game.get_node("CorridorDepth") as RoomDepth).behind, "the inner blast leaf draws inside the wall, behind the cross-wall's face")
	# Shut: the leaf's leading edge is in the near jamb's receiver, so the leaf spans the whole opening.
	_expect(BlastLeaf.lead_at(0.0) < JAMB_NEAR_A and BlastLeaf.lead_at(0.0) + LEAF_LENGTH_M > BlastLeaf.A_MOUTH, "shut, the inner leaf spans the whole opening (lead %.3f m, near jamb %.3f m)" % [BlastLeaf.lead_at(0.0), JAMB_NEAR_A])
	# It waits for the roller, then only ever moves toward its pocket.
	var last: float = BlastLeaf.lead_at(0.0)
	var monotonic: bool = true
	for step: int in 101:
		var lead: float = BlastLeaf.lead_at(step / 100.0)
		if lead < last - 0.000001:
			monotonic = false
		last = lead
	_expect(monotonic and is_equal_approx(BlastLeaf.lead_at(0.4), BlastLeaf.A_LEAD_SHUT), "the inner leaf holds until the roller is 40 % up, then slides one way, into its pocket")
	# Open: the whole leaf is in the pocket beyond the far jamb, clear of the opening and the walk line.
	var open_lead: float = BlastLeaf.lead_at(1.0)
	_expect(open_lead >= BlastLeaf.A_MOUTH - 0.0001 and open_lead > WALK_A, "open, the inner leaf's leading edge is flush in the pocket's mouth (%.4f m, mouth %.4f m), so the opening from the near jamb to the far jamb is clear" % [open_lead, BlastLeaf.A_MOUTH])
	var deepest_foot_y: float = -INF
	for a: float in [open_lead, open_lead + LEAF_LENGTH_M * 0.5, open_lead + LEAF_LENGTH_M]:
		for t: float in [BlastLeaf.T_LF, BlastLeaf.T_LB]:
			deepest_foot_y = maxf(deepest_foot_y, BlastLeaf.project(a, 0.0, t).y)
	_expect(deepest_foot_y < RoomDepth.FLOOR_Y - 8.0, "open, the inner leaf's footprint is wholly behind the walk line (lowest foot at world y %.1f, the walk line at %.0f)" % [deepest_foot_y, RoomDepth.FLOOR_Y])
	# Round 8: it reads heavier than the roller: a 0.30-0.45 m leading edge, and a feathered contact
	# shadow on the threshold, in the wall's thickness (in front of the leaf's foot, behind the face),
	# in SHADOW_COLOR.
	_expect(BlastLeaf.T_LB - BlastLeaf.T_LF >= 0.30 and BlastLeaf.T_LB - BlastLeaf.T_LF <= 0.45 and BlastLeaf.T_LB < 0.66, "the inner leaf's leading edge is %.2f m thick, inside the 0.66 m wall" % (BlastLeaf.T_LB - BlastLeaf.T_LF))
	var shadow_t: float = BlastLeaf.T_LF - BlastLeaf.SHADOW_DEPTH_M
	_expect(shadow_t > 0.0 and BlastLeaf.SHADOW_ALPHA > 0.0 and BlastLeaf.SHADOW_ALPHA < 1.0, "the leaf's contact shadow lies on the threshold inside the wall (t %.2f..%.2f m), feathered from alpha %.2f to 0" % [shadow_t, BlastLeaf.T_LF, BlastLeaf.SHADOW_ALPHA])
	_expect(BlastLeaf.SHADOW_COLOR == Color.BLACK, "the contact shadow is black")
