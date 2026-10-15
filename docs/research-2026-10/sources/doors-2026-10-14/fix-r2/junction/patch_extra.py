"""Second half of the junction blast-door integration (scratch only): retires the bulkhead pillar
fade that only the old junction door used, brings the tests over to the door's pieces, and updates
the asset register. Called by patch_game.py; exact replacements, each must match once."""
from __future__ import annotations

import json
import os


def sub(text: str, old: str, new: str, path: str) -> str:
    n = text.count(old)
    if n != 1:
        raise SystemExit(f"{path}: expected one match, found {n}:\n{old[:300]}")
    return text.replace(old, new)


def patch_depth(path: str) -> None:
    s = open(path).read()
    s = sub(s, '''## The pressure bulkheads (design A) shared by the corridor seal and the junction door: their import
## copies share one canvas per door whose bottom row is the floor, drawn at this scale, and the front
## pillar's outer edge sits this many canvas pixels in from the left, its column BULKHEAD_PILLAR_WIDTH
## canvas pixels wide at body height.
const BULKHEAD_SCALE: float = 0.3
const BULKHEAD_PILLAR_X: float = 83.0
const BULKHEAD_PILLAR_WIDTH: float = 76.0
## A bulkhead's front pillar (see [member pillars]) fades to this opacity while it covers an actor,
## keeping more of the doorway than a near edge piece does.
const PILLAR_FADE_ALPHA: float = 0.5
''', '', path)
    s = sub(s, '''## Bulkhead front lips (made with [method make_bulkhead]'s cut) drawn over the actors in this room;
## each fades back to PILLAR_FADE_ALPHA while its pillar covers one of the [member occluders].
var pillars: Array[Sprite2D] = []
''', '', path)
    s = sub(s, '''	# The pillars fade whether or not the depth pass is on: they draw over the actors either way.
	for pillar: Sprite2D in pillars:
		if is_instance_valid(pillar):
			var pillar_target: float = PILLAR_FADE_ALPHA if pillar_covers(pillar) else 1.0
			pillar.modulate.a = move_toward(pillar.modulate.a, pillar_target, NEAR_FADE_SPEED * delta)
''', '', path)
    # pillar_covers and its doc comment, up to the blank lines before the next function
    i = s.index('''## True when [param pillar]'s front pillar column''')
    j = s.index('''\n\n\n''', i)
    s = s[:i] + s[j + 3:]
    s = sub(s, '''## A bulkhead image (BULKHEAD_SCALE, its canvas bottom on the floor) placed so its front pillar's
## outer edge is at [param face_x], the face of the door's collision body.
static func make_bulkhead(prop_name: String, texture: Texture2D, region: Rect2, face_x: float) -> Sprite2D:
	return make_prop(prop_name, texture, region, BULKHEAD_SCALE, bulkhead_center_x(region, face_x))


## The centre x of a bulkhead drawn from [param region] with its front pillar's edge at [param face_x].
static func bulkhead_center_x(region: Rect2, face_x: float) -> float:
	return face_x + (region.get_center().x - BULKHEAD_PILLAR_X) * BULKHEAD_SCALE


''', '', path)
    open(path, "w").write(s)


JUNCTION_PRESENTATION_OLD = '''## The bulkhead shares one cut across its states, stands with its front pillar on the door body's
## face and draws that pillar over the actors and the rest under them; the station plates share one
## row and size and never overlap.
func _check_presentation(room: JunctionRoom, human: M0Actor, wolf: M0Actor) -> void:
	var arts: Array[Sprite2D] = [room.door_art, room.door_breaking_art, room.door_blown_art, room.door_lip]
	var shared: bool = true
	for art: Sprite2D in arts:
		shared = shared and art.region_rect == JunctionRoom.DOOR_REGION and art.position == room.door_art.position and art.scale == room.door_art.scale
	_expect(shared, "every bulkhead image and its front lip share one registered cut")
	var pillar_x: float = room.door_visual.position.x + (RoomDepth.BULKHEAD_PILLAR_X - JunctionRoom.DOOR_REGION.get_center().x) * JunctionRoom.DOOR_SCALE
	_expect(is_equal_approx(pillar_x, M0State.JUNCTION_DOOR_LEFT_X), "the bulkhead's front pillar stands on the door body's face (%.1f)" % pillar_x)
	var body_z: int = room.z_index + room.door_visual.z_index
	var lip_z: int = body_z + room.door_lip.z_index
	_expect(body_z < human.z_index and body_z < wolf.z_index and lip_z > human.z_index and lip_z > wolf.z_index, "the bulkhead draws behind the actors and its front pillar in front of them")
'''
JUNCTION_PRESENTATION_NEW = '''## The blast door's pieces are regions of one atlas: the doorway, the leaf, the wall and the release bay
## draw under the actors, the near column, its lamp, the wall's stub and the thrown leaf over them, so
## whoever walks through the doorway passes behind the near column. The doorway stands across the walk
## line just beyond the door body's face. The station plates share one row and size and never overlap.
func _check_presentation(room: JunctionRoom, human: M0Actor, wolf: M0Actor) -> void:
	var under: Array[Sprite2D] = [room.door_hole, room.door_leaf, room.door_leaf_breaking, room.door_wall, room.door_cracks, room.door_damage, room.release_bay]
	var over: Array[Sprite2D] = [room.door_lamp, room.door_column, room.door_stub, room.door_leaf_down]
	var atlas: bool = true
	var order: bool = true
	for piece: Sprite2D in under + over:
		atlas = atlas and piece.texture == JunctionDoorLayout.ATLAS and piece.region_enabled
		var z: int = room.z_index + piece.z_index
		order = order and (z < mini(human.z_index, wolf.z_index) if under.has(piece) else z > maxi(human.z_index, wolf.z_index))
	_expect(atlas, "every blast-door piece is a region of the one door atlas")
	_expect(order, "the doorway, leaf, wall and bay draw behind the actors; the near column, stub and thrown leaf in front")
	var far: Vector2 = JunctionDoorLayout.FAR_JAMB_FOOT
	var near: Vector2 = JunctionDoorLayout.NEAR_JAMB_FOOT
	var crossing_x: float = far.x + (near.x - far.x) * (JunctionRoom.FLOOR_Y - far.y) / (near.y - far.y)
	_expect(far.y < JunctionRoom.FLOOR_Y and near.y > JunctionRoom.FLOOR_Y and crossing_x > M0State.JUNCTION_DOOR_LEFT_X and crossing_x < M0State.JUNCTION_DOOR_LEFT_X + JunctionRoom.DOOR_WIDTH, "the doorway crosses the walk line inside the door body (x %.1f)" % crossing_x)
	_expect(room.door_leaf.visible and not room.door_hole.visible and not room.door_leaf_down.visible, "the shut leaf stands in the doorway before the blast")
'''


def patch_junction_test(path: str) -> None:
    s = open(path).read()
    s = sub(s, JUNCTION_PRESENTATION_OLD, JUNCTION_PRESENTATION_NEW, path)
    s = sub(s, '''	await _check_pillar_fade(room)
''', '', path)
    i = s.index('''## The bulkhead's front pillar fades back while someone stands in the doorway behind it''')
    j = s.index('''func _expect(''', i)
    s = s[:i] + s[j:]
    s = sub(s, '''(room.door_breaking_art.visible or room.door_blown_art.visible) and not room.door_art.visible''',
            '''(room.door_leaf_breaking.visible or room.door_hole.visible) and not room.door_leaf.visible''', path)
    s = sub(s, '''room.door_art.visible and not room.door_blown_art.visible and not room.door_blown''',
            '''room.door_leaf.visible and not room.door_hole.visible and not room.door_leaf_down.visible and not room.door_blown''', path)
    s = sub(s, '''_expect(room.door_breaking_art.visible and not room.door_art.visible and not room.door_blown_art.visible, "at the blast the bulkhead shows breaking first")''',
            '''_expect(room.door_leaf_breaking.visible and room.door_cracks.visible and not room.door_leaf.visible and not room.door_hole.visible, "at the blast the leaf shows breaking first")''', path)
    s = sub(s, '''return room.door_blown_art.visible and not room.door_breaking_art.visible, 30), "then it stands blown open on the passage beyond")''',
            '''return room.door_hole.visible and room.door_leaf_down.visible and not room.door_leaf_breaking.visible, 30), "then the doorway stands empty on the lane and the leaf lies beyond it")''', path)
    s = sub(s, '''_expect(room.z_index + room.door_visual.z_index < wolf.z_index and room.z_index + room.door_visual.z_index < human.z_index, "the torn door frame draws behind WOLF and the engineer")''',
            '''_expect(room.z_index + room.door_hole.z_index < wolf.z_index and room.z_index + room.door_hole.z_index < human.z_index, "the torn doorway draws behind WOLF and the engineer")''', path)
    s = sub(s, '''not room.door_art.visible and room.door_blown_art.visible and str(game.get("status_line")).contains("door is down")''',
            '''not room.door_leaf.visible and room.door_hole.visible and room.door_leaf_down.visible and str(game.get("status_line")).contains("door is down")''', path)
    s = sub(s, '''	# Reduced Motion holds the charged seam steady instead of strobing.''', '''	# Reduced Motion holds the charged door lamp steady instead of flashing.''', path)
    s = sub(s, '''	# A spare room, outside Main's per-frame sync, shows the seam on its own.''', '''	# A spare room, outside Main's per-frame sync, shows the lamp on its own.''', path)
    s = sub(s, '''	var steady: Color = spare.seam_glow.modulate''', '''	var steady: Color = spare.door_lamp_glow.modulate''', path)
    s = sub(s, '''_expect(spare.seam_glow.modulate == steady and steady.a > 0.5, "with Reduced Motion the charged seam glows without strobing")''',
            '''_expect(spare.door_lamp_glow.modulate == steady and steady.a > 0.5, "with Reduced Motion the charged door lamp glows without flashing")''', path)
    s = sub(s, '''		strobed = strobed or spare.seam_glow.modulate != steady
	_expect(strobed, "without Reduced Motion the charged seam strobes")''', '''		strobed = strobed or spare.door_lamp_glow.modulate != steady
	_expect(strobed, "without Reduced Motion the charged door lamp flashes")''', path)
    open(path, "w").write(s)


def patch_follow_test(path: str) -> None:
    s = open(path).read()
    s = sub(s, '''room.vent_glow, room.seam_glow, room.line_caption''', '''room.vent_glow, room.line_caption''', path)
    s = sub(s, '''## at a machine is in front of everything on it. (The door's placard rides over the bulkhead's front
## pillar, above head height.)''', '''## at a machine is in front of everything on it. (The door's placard hangs over the blast door's near
## column, above head height; the door's status lamp is on that column, in front of the actors.)''', path)
    open(path, "w").write(s)


def patch_room_depth_test(path: str) -> None:
    s = open(path).read()
    s = sub(s, '''	_expect(absf(junction.door_art.get_global_transform().origin.y + junction.door_art.region_rect.size.y * junction.door_art.scale.y * 0.5 - 440.0) < 0.5, "the junction door stands on the floor")''',
            '''	# The junction's shut leaf ends on the doorway's near jamb foot, on the deck in front of the walk line.
	var leaf: Sprite2D = junction.door_leaf
	_expect(absf(leaf.position.y + leaf.region_rect.size.y * leaf.scale.y - JunctionDoorLayout.NEAR_JAMB_FOOT.y) < 1.0, "the junction door's leaf stands on the deck at its near jamb")''', path)
    open(path, "w").write(s)


def patch_m0_scene_test(path: str) -> None:
    s = open(path).read()
    s = sub(s, '''_expect(not (game.get("corridor_depth") as RoomDepth).pillars.has(column) and column.modulate.a == 1.0, "the corridor's near column stays opaque")''',
            '''_expect(column.modulate.a == 1.0, "the corridor's near column stays opaque")''', path)
    open(path, "w").write(s)


NEW_ENTRY = {
    "asset_id": "junction-door-atlas",
    "path": "apps/game/assets/props/junction-door-atlas.png",
    "source_or_tool": "Design-first build, 2026-10-13, in the corridor door end's method: construction drawings, masks and specs drawn by Python from measured real hardware in the junction room's own camera (doors-r1/junction tools jmodel.py and jdesign.py, NumPy and Pillow; no lettering), painted inside those shapes with Codex's built-in image_gen tool in edit mode (sessions junction-paint-sealed, 01a1340f-a80c-7d53-a66e-2be8b8a96ff5, and junction-paint-blown, 01a1341f-aa82-7d42-b21e-0d38a4fbab1d, 2026-10-13), then cleaned up and packed deterministically by Python (cleanup.py and install.py, NumPy, SciPy and Pillow)",
    "source_reference": "Design, research, review and paint records: the junction blast-door track folder (NOTES.md, design/spec.json, every tool, review/), to be filed under docs/research-2026-10/sources/ like the corridor door end; Codex sessions (ids, outputs, SHA-256, use) in its provenance.txt; raw Codex outputs kept byte for byte with their C2PA content credentials (caBX chunk). Rules from docs/research-2026-10/art-direction/REAL-LOOK.md.",
    "terms_reference": "https://openai.com/policies/terms-of-use/",
    "rights_review_status": "Provisional AI-assisted gameplay prop: deterministic construction drawings painted with an AI image tool, then cleaned up deterministically. Awaiting Nathanial Henniges's review from rendered frames; not yet approved. Final commercial asset-rights review remains open; not covered by the code/docs GPL license.",
    "modifications": "One lossless 1024x768 RGBA atlas holding every piece of the Service Junction's blast door: the cast-concrete cross-wall across the walkway with its doorway transparent, the charge line's penetration plate and the door light; the shut leaf and the breaking leaf (4 atlas px per world px); the breaking cracks; the blown doorway (torn bolt keepers, buckled threshold, the rubble pile), the blast damage (spall, rebar, peeled flange, soot); the TANK RELEASE bay with its two posts; the near column with the status lamp socket; the wall's stub across the deck; the thrown leaf lying in the lane with the front rubble; the lamp's glass. Paint is kept only inside each part's designed mask; the design's exact alpha is re-imposed and values held to the room's light plan.",
    "implementation_status": "Integration candidate (not on main): JunctionRoom draws every piece from JunctionDoorLayout (generated): doorway, leaf, wall, damage and bay under the actors; column, lamp glass (tinted live), stub and thrown leaf over them. It replaces junction-bulkhead-sealed/-breaking/-blown/-front-lip.png and their art-source originals (deleted, in the Git history).",
}


def patch_manifest(path: str) -> None:
    d = json.load(open(path))
    gone = {"door-a-junction-sealed-master", "door-a-junction-breaking-master", "door-a-junction-blown-master", "door-a-junction-front-lip-master",
            "junction-bulkhead-sealed", "junction-bulkhead-breaking", "junction-bulkhead-blown", "junction-bulkhead-front-lip"}
    before = len(d["assets"])
    idx = next(i for i, a in enumerate(d["assets"]) if a["asset_id"] == "junction-bulkhead-sealed")
    d["assets"] = [a for a in d["assets"] if a["asset_id"] not in gone]
    idx -= sum(1 for a in json.load(open(path))["assets"][:idx] if a["asset_id"] in gone)
    d["assets"].insert(idx, NEW_ENTRY)
    if len(d["assets"]) != before - 7:
        raise SystemExit("manifest: unexpected entry count")
    json.dump(d, open(path, "w"), indent=2, ensure_ascii=False)
    open(path, "a").write("\n")


def run(game: str) -> None:
    patch_room_comments(os.path.join(game, "scripts", "junction_room.gd"))
    patch_room_blast(os.path.join(game, "scripts", "junction_room.gd"))
    patch_depth(os.path.join(game, "scripts", "room_depth.gd"))
    patch_junction_test(os.path.join(game, "tests", "junction_test.gd"))
    patch_room_depth_test(os.path.join(game, "tests", "room_depth_test.gd"))
    patch_m0_scene_test(os.path.join(game, "tests", "m0_scene_test.gd"))
    patch_follow_test(os.path.join(game, "tests", "follow_spacing_test.gd"))
    patch_manifest(os.path.join(game, "assets", "manifest.json"))
    for n in ("sealed", "breaking", "blown", "front-lip"):
        p = os.path.join(game, "art-source", "doors", f"junction-{n}.png")
        if os.path.exists(p):
            os.remove(p)


ROOM_COMMENTS = [
    ('''## layered set (RoomDepth) and painted station props, with the corridor's breaker and a pressure
## bulkhead for its door. What the art cannot show is drawn over it here from the state the parent
## mirrors in (PressureLine, DropArm, SentryBrain): the LINE gauge's needle, the vent and seam glows,
## the hazard stripes over the door's blast zone while the fuse burns, the panel and hatch lights, the
## alcove's shadow and floor, the passage behind the exit hatch, the floor brackets (lit while the
## sentry's body is inside them) with the tank's shadow, the rubble line and the winch cable.''',
     '''## layered set (RoomDepth) and painted station props, with the corridor's breaker and a blast door
## in a cross-wall across the walkway (JunctionDoorLayout). What the art cannot show is drawn over it
## here from the state the parent mirrors in (PressureLine, DropArm, SentryBrain): the LINE gauge's
## needle, the vent glow and the door's status lamp, the hazard stripes over the door's blast zone
## while the fuse burns, the panel and hatch lights, the passage behind the exit hatch, the floor
## brackets (lit while the sentry's body is inside them) with the tank's shadow and the winch cable.'''),
    ('''## The VALVE plate sits this far left of the wheel so its longest text ends well before the bulkhead.''',
     '''## The VALVE plate sits this far left of the wheel so its longest text ends well before the door.'''),
    ('''## The TANK RELEASE plate sits right of the panel, clear of the bulkhead's frame and the door's placard.''',
     '''## The TANK RELEASE plate sits right of the panel, clear of the door's column and its placard.'''),
    ('''## Reduced Motion: the charged seam holds a steady glow instead of strobing.''',
     '''## Reduced Motion: the charged door lamp holds steady instead of flashing.'''),
    ('''## What sits behind the stations: the shadow of the TANK RELEASE alcove and the release's feed to the
## exit bolt, drawn under the props (the room's own drawing sits over them).''',
     '''## What sits behind the stations: the release's feed to the exit bolt, drawn under the props (the
## room's own drawing sits over them).'''),
    ('''	# A little left of the wheel so its longest text ends before the bulkhead.''',
     '''	# A little left of the wheel so its longest text ends before the door.'''),
    ('''## The door: the sealed bulkhead over a 56x132 body on the floor layer, its front pillar on the
## body's face; at the blast it breaks and then stands blown open on the passage beyond. The visual is
## pivoted at the floor so the blast can jolt it; the front lip rides with it, drawn over the actors.''',
     '''## The door: a 56x132 body on the floor layer whose face stops the engineer just short of the shut
## leaf, and the blast door's pieces from JunctionDoorLayout; at the blast the leaf breaks, then the
## doorway stands empty on the lane and the leaf lies thrown beyond it.'''),
    ('''## A station name on its plate, centred on [param center_x] in the label row. It draws over the
## bulkhead and under the actors.''',
     '''## A station name on its plate, centred on [param center_x] in the label row. It draws over the
## door's cross-wall and under the actors.'''),
    ('''## Copies the live pressure line in; the gauge needle, steam, seam and labels all follow it.''',
     '''## Copies the live pressure line in; the gauge needle, steam, door lamp and labels all follow it.'''),
    ('''## Labels, glows and the seam follow the line's phase; the parent calls this after state changes.''',
     '''## Labels, glows and the door lamp follow the line's phase; the parent calls this after state changes.'''),
]


def patch_room_comments(path: str) -> None:
    import re
    s = open(path).read()
    for old, new in ROOM_COMMENTS:
        s = sub(s, old, new, path)
    s = re.sub(r"\b_sync_seam\b", "_sync_lamp", s)
    s = re.sub(r"\b_seam_tween\b", "_lamp_tween", s)
    open(path, "w").write(s)


def patch_room_blast(path: str) -> None:
    """The blast's effects at the door: a few small sparks where the steel tears at the latch jamb
    (not a shower of soft amber discs), concrete fragments thrown into the lane that fall to the
    deck, and the grey concrete dust from the doorway's foot."""
    s = open(path).read()
    s = sub(s, '''var blast_sparks: CPUParticles2D
var blast_dust: CPUParticles2D''', '''var blast_sparks: CPUParticles2D
var blast_debris: CPUParticles2D
var blast_dust: CPUParticles2D''', path)
    s = sub(s, '''	blast_sparks = FxPresets.sparks(AMBER)
	blast_sparks.name = "BlastSparks"
	blast_sparks.position = Vector2(DOOR_X, FLOOR_Y - DOOR_HEIGHT * 0.5)
	blast_sparks.amount = 36
	blast_sparks.spread = 110.0
	blast_sparks.z_index = 3
	add_child(blast_sparks)''', '''	# Steel tearing at the latch jamb, where the bolts shear: a few small, fast sparks thrown into the
	# lane, not a shower.
	blast_sparks = FxPresets.sparks(AMBER)
	blast_sparks.name = "BlastSparks"
	blast_sparks.position = Vector2(JunctionDoorLayout.FAR_JAMB_FOOT.x + 2.0, FLOOR_Y - 52.0)
	blast_sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	blast_sparks.emission_rect_extents = Vector2(2.0, 46.0)
	blast_sparks.direction = Vector2(1.0, -0.25)
	blast_sparks.spread = 45.0
	blast_sparks.amount = 14
	blast_sparks.scale_amount_min = 0.3
	blast_sparks.scale_amount_max = 0.6
	blast_sparks.z_index = 3
	add_child(blast_sparks)
	# Concrete spalled off round the frame, thrown into the lane and falling to the deck.
	blast_debris = FxPresets.sparks(Color(0.36, 0.37, 0.39))
	blast_debris.name = "BlastDebris"
	blast_debris.position = Vector2(DOOR_X, FLOOR_Y - 60.0)
	blast_debris.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	blast_debris.emission_rect_extents = Vector2(8.0, 55.0)
	blast_debris.direction = Vector2(1.0, -0.35)
	blast_debris.spread = 40.0
	blast_debris.initial_velocity_min = 140.0
	blast_debris.initial_velocity_max = 360.0
	blast_debris.gravity = Vector2(0.0, 900.0)
	blast_debris.damping_min = 10.0
	blast_debris.damping_max = 10.0
	blast_debris.lifetime = 0.7
	blast_debris.amount = 20
	blast_debris.scale_amount_min = 0.35
	blast_debris.scale_amount_max = 0.75
	blast_debris.z_index = 3
	add_child(blast_debris)''', path)
    s = sub(s, '''	blast_sparks.restart()
	blast_dust.restart()''', '''	blast_sparks.restart()
	blast_debris.restart()
	blast_dust.restart()''', path)
    s = sub(s, '''vent_steam, vent_puff, blast_sparks, blast_dust, coolant_cloud''', '''vent_steam, vent_puff, blast_sparks, blast_debris, blast_dust, coolant_cloud''', path)
    s = sub(s, '''## The door going: the bulkhead breaks under the blast flash and gives way to the blown frame on the
## passage beyond, which jolts and settles; sparks and dust fly, and the blast zone is dangerous for a
## moment.''', '''## The door going: the leaf breaks under the blast flash, then the doorway stands empty and the leaf
## lies thrown in the lane; sparks, concrete fragments and dust fly, and the blast zone is dangerous
## for a moment.''', path)
    open(path, "w").write(s)
