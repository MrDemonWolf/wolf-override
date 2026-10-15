"""Applies the junction blast-door integration to a scratch copy of main's apps/game (never to a
Git repository or worktree). Exact text replacements: each must match once, or the patch stops.

usage: patch_game.py GAME_DIR
  copies layers/final/junction-door-atlas.png (+ its .import) and junction_door_layout.gd in,
  deletes the four junction bulkhead PNGs and their .import files, and edits
  scripts/junction_room.gd and scripts/main.gd.
"""
from __future__ import annotations

import os
import shutil
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
WORK = "doors-r1/junction"


def sub(text: str, old: str, new: str, path: str) -> str:
    n = text.count(old)
    if n != 1:
        raise SystemExit(f"{path}: expected one match, found {n}:\n{old[:200]}")
    return text.replace(old, new)


def patch_room(path: str) -> None:
    s = open(path).read()
    s = sub(s, '''## The pressure bulkhead (design A): sealed, breaking for a moment at the blast, then blown open on
## the passage beyond, with its front pillar drawn again over the actors.
const DOOR_SEALED_PROP: Texture2D = preload("res://assets/props/junction-bulkhead-sealed.png")
const DOOR_BREAKING_PROP: Texture2D = preload("res://assets/props/junction-bulkhead-breaking.png")
const DOOR_BLOWN_PROP: Texture2D = preload("res://assets/props/junction-bulkhead-blown.png")
const DOOR_LIP_PROP: Texture2D = preload("res://assets/props/junction-bulkhead-front-lip.png")
''', '''## The blast door: a hinged steel leaf (2.3 x 2.6 m, 0.30 m) in a 0.40 m cast-concrete cross-wall that
## stands ACROSS the walkway, its face turned 17 degrees to the camera like the corridor's door end.
## Every piece is one region of one lossless atlas (JunctionDoorLayout, generated from the design's
## placement.json). Under the actors: the empty doorway (blown), the shut or breaking leaf, the wall
## with the doorway at alpha 0, the blast damage, the TANK RELEASE bay. Over them: the near column
## with the status lamp, the wall's stub across the deck and, once blown, the leaf lying in the lane.
''', path)
    s = sub(s, '''## Every door image (and the front lip) shares one registered canvas whose bottom row is the floor,
## so all of them use this cut: 181 px tall at RoomDepth.BULKHEAD_SCALE, with the front pillar's
## outer edge on the door body's face (M0State.JUNCTION_DOOR_LEFT_X).
const DOOR_REGION: Rect2 = Rect2(0.0, 36.0, 384.0, 604.0)
const DOOR_SCALE: float = RoomDepth.BULKHEAD_SCALE
## The seam painted down the sealed leaf, in canvas pixels.
const DOOR_SEAM_X: float = 196.0
## How long the breaking bulkhead shows at the blast before the blown one replaces it.''', '''## How long the breaking leaf shows at the blast before the blown doorway replaces it.''', path)
    s = sub(s, '''## The bulkhead draws one step under the actors (this node sits at z 1), its front pillar one step
## over them, so they pass through the doorway once it is open.
const DOOR_Z: int = 0
const DOOR_LIP_Z: int = 2''', '''## The door's pieces under the actors draw at DOOR_Z (over the mid plate, under the props), the
## release bay one step above them (over the bolt feed in Recesses); the column, stub and lying leaf
## at DOOR_FRONT_Z, over the actors (this node sits at z 1), so they pass through the doorway behind
## the near column.
const DOOR_Z: int = -3
const BAY_Z: int = -2
const DOOR_FRONT_Z: int = 2
## The status lamp on the column: red shut, amber while the line builds, flashing red and white
## through the fuse (steady red with Reduced Motion), dark once the door is down.
const LAMP_SHUT: Color = Color(0.9, 0.2, 0.17)
const LAMP_DEAD: Color = Color(0.16, 0.17, 0.18)''', path)
    s = sub(s, '''## The door's placard sits across the bulkhead's leaf, this far right of its centre, over its pillar.
const DOOR_LABEL_SHIFT: float = 7.0''', '''## The door's placard is centred over the doorway's head.
const DOOR_LABEL_X: float = 479.0''', path)
    s = sub(s, '''## The alcove's floor is tinted over exactly the span that hides the engineer, down onto the walkway
## like the floor mark's stripes, and a post stands at each end of it, so where cover stops (the
## right post) shows beside an engineer at the TANK RELEASE.
const ALCOVE_FLOOR: Color = Color(0.25, 0.62, 0.72, 0.3)
const ALCOVE_EDGE: Color = Color(0.5, 0.86, 0.94, 0.85)
''', '''## The alcove is painted: a recessed bay whose two steel posts stand on SentryBrain.COVER_MIN_X and
## COVER_MAX_X, so where cover stops (the right post) shows beside an engineer at the TANK RELEASE.
''', path)
    s = sub(s, '''var door_visual: Node2D
## The sealed door; at the blast the breaking one shows for DOOR_BREAK_SECONDS, then the blown one.
var door_art: Sprite2D
var door_breaking_art: Sprite2D
var door_blown_art: Sprite2D
## The bulkhead's front pillar, drawn over the actors.
var door_lip: Sprite2D''', '''## The door's pieces (JunctionDoorLayout): the shut leaf; at the blast the breaking leaf and cracks
## show for DOOR_BREAK_SECONDS, then the empty doorway, the damage and the leaf lying in the lane.
var door_hole: Sprite2D
var door_leaf: Sprite2D
var door_leaf_breaking: Sprite2D
var door_wall: Sprite2D
var door_cracks: Sprite2D
var door_damage: Sprite2D
var release_bay: Sprite2D
var door_column: Sprite2D
var door_stub: Sprite2D
var door_leaf_down: Sprite2D
## The status lamp's glass and its small glow, tinted live.
var door_lamp: Sprite2D
var door_lamp_glow: Sprite2D''', path)
    s = sub(s, '''var seam_glow: Sprite2D
''', '', path)
    s = sub(s, '''## The alcove's soft shadow, made once and kept so the drawing that uses it always has it.
var alcove_shadow: GradientTexture2D = soft_texture(GradientTexture2D.FILL_SQUARE)
''', '', path)
    s = sub(s, '''	depth.shaft_lamps = PackedInt32Array([0, 2])''', '''	depth.shaft_lamps = PackedInt32Array([0, 2])
	# The middle ceiling lamp is behind the blast door's cross-wall now: its glow is hidden.
	depth.painted_lamps = PackedInt32Array([1])''', path)
    s = sub(s, '''	# A placard across the bulkhead's face, over its front pillar.
	door_label = _add_station_label("SEALED DOOR", door_visual.position.x + DOOR_LABEL_SHIFT, Color("#ffc7c7"))
	door_label.z_index = DOOR_LIP_Z + 1''', '''	# A placard over the doorway's head, hung in front of the near column (above head height).
	door_label = _add_station_label("SEALED DOOR", DOOR_LABEL_X, Color("#ffc7c7"))
	door_label.z_index = DOOR_FRONT_Z + 1''', path)
    old_build = s[s.index('''	add_child(door_body)
	door_visual = Node2D.new()'''):s.index('''## The exit door's pieces, in drawing order.''')]
    s = sub(s, old_build, '''	add_child(door_body)
	door_hole = _door_piece("DoorHole", JunctionDoorLayout.HOLE_REGION, JunctionDoorLayout.HOLE_AT, JunctionDoorLayout.HOLE_SCALE, DOOR_Z)
	door_leaf = _door_piece("DoorLeaf", JunctionDoorLayout.LEAF_REGION, JunctionDoorLayout.LEAF_AT, JunctionDoorLayout.LEAF_SCALE, DOOR_Z)
	door_leaf_breaking = _door_piece("DoorLeafBreaking", JunctionDoorLayout.LEAFBREAK_REGION, JunctionDoorLayout.LEAFBREAK_AT, JunctionDoorLayout.LEAFBREAK_SCALE, DOOR_Z)
	door_wall = _door_piece("DoorWall", JunctionDoorLayout.WALL_REGION, JunctionDoorLayout.WALL_AT, JunctionDoorLayout.WALL_SCALE, DOOR_Z)
	door_cracks = _door_piece("DoorCracks", JunctionDoorLayout.CRACKS_REGION, JunctionDoorLayout.CRACKS_AT, JunctionDoorLayout.CRACKS_SCALE, DOOR_Z)
	door_damage = _door_piece("DoorDamage", JunctionDoorLayout.DAMAGE_REGION, JunctionDoorLayout.DAMAGE_AT, JunctionDoorLayout.DAMAGE_SCALE, DOOR_Z)
	# The lamp's glass draws under the column, so the column's guard bars lie over it.
	door_lamp = _door_piece("DoorLampLens", JunctionDoorLayout.LENS_REGION, JunctionDoorLayout.LENS_AT, JunctionDoorLayout.LENS_SCALE, DOOR_FRONT_Z)
	door_column = _door_piece("DoorColumn", JunctionDoorLayout.COLUMN_REGION, JunctionDoorLayout.COLUMN_AT, JunctionDoorLayout.COLUMN_SCALE, DOOR_FRONT_Z)
	door_stub = _door_piece("DoorStub", JunctionDoorLayout.STUB_REGION, JunctionDoorLayout.STUB_AT, JunctionDoorLayout.STUB_SCALE, DOOR_FRONT_Z)
	door_leaf_down = _door_piece("DoorLeafDown", JunctionDoorLayout.LYING_REGION, JunctionDoorLayout.LYING_AT, JunctionDoorLayout.LYING_SCALE, DOOR_FRONT_Z)
	door_lamp_glow = RoomDepth.make_glow(LAMP_SHUT, Vector2(16.0, 16.0), 0.45)
	door_lamp_glow.name = "DoorLampGlow"
	door_lamp_glow.position = JunctionDoorLayout.LAMP_CENTRE
	door_lamp_glow.z_index = DOOR_FRONT_Z
	add_child(door_lamp_glow)
	_show_door()


## One piece of the blast door, cut from JunctionDoorLayout's atlas and placed by its world top-left.
func _door_piece(piece_name: String, region: Rect2, top_left: Vector2, piece_scale: float, z: int) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = piece_name
	sprite.texture = JunctionDoorLayout.ATLAS
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.scale = Vector2.ONE * piece_scale
	sprite.position = top_left
	sprite.z_index = z
	add_child(sprite)
	return sprite


## The release bay draws after Recesses (so its right post lies over the bolt feed); it is made once
## Recesses exists.
func _build_bay() -> void:
	release_bay = _door_piece("ReleaseBay", JunctionDoorLayout.ALCOVE_REGION, JunctionDoorLayout.ALCOVE_AT, JunctionDoorLayout.ALCOVE_SCALE, BAY_Z)


''', path)
    s = sub(s, '''	recesses.z_index = -2
	add_child(recesses)''', '''	recesses.z_index = -2
	add_child(recesses)
	_build_bay()''', path)
    s = sub(s, '''	blast_dust.amount = 30
	blast_dust.z_index = 3''', '''	blast_dust.amount = 30
	# Concrete dust, not the shared tan: neutral grey, finer, from the doorway's foot.
	blast_dust.color = Color(0.6, 0.62, 0.64, 0.4)
	blast_dust.scale_amount_min = 2.0
	blast_dust.scale_amount_max = 5.0
	blast_dust.z_index = 3''', path)
    s = sub(s, '''	if building:
		seam_glow.modulate = Color(AMBER, 0.25 + 0.5 * gauge)
	_sync_vent_glow()''', '''	_sync_vent_glow()''', path)
    s = sub(s, '''func _sync_seam() -> void:
	if _seam_tween != null and _seam_tween.is_valid():
		_seam_tween.kill()
	_seam_tween = null
	seam_glow.visible = not door_blown
	match line_state:
		&"charged", &"fuse":
			# The seam strobes white only once the third turn is real; Reduced Motion holds it steady.
			seam_glow.modulate = Color(Color.WHITE, 0.9)
			if reduce_motion:
				return
			_seam_tween = create_tween().set_loops()
			_seam_tween.tween_property(seam_glow, "modulate", Color(SEAM_RED, 0.5), 0.08)
			_seam_tween.tween_property(seam_glow, "modulate", Color(Color.WHITE, 0.9), 0.08)
		&"building":
			seam_glow.modulate = Color(AMBER, 0.25 + 0.5 * gauge)
		&"blown":
			seam_glow.visible = false
		_:
			seam_glow.modulate = Color(AMBER, 0.2)''', '''## The door's status lamp follows the line: red shut, amber while it builds, flashing red and white
## through the fuse (steady red with Reduced Motion), dark once the door is down.
func _sync_seam() -> void:
	if _seam_tween != null and _seam_tween.is_valid():
		_seam_tween.kill()
	_seam_tween = null
	if door_blown or line_state == &"blown":
		_set_lamp(LAMP_DEAD, 0.0)
		return
	match line_state:
		&"charged", &"fuse":
			_set_lamp(SEAM_RED, 0.6)
			if reduce_motion:
				return
			_seam_tween = create_tween().set_loops()
			_seam_tween.tween_callback(_set_lamp.bind(Color.WHITE, 0.7))
			_seam_tween.tween_interval(0.12)
			_seam_tween.tween_callback(_set_lamp.bind(SEAM_RED, 0.6))
			_seam_tween.tween_interval(0.12)
		&"building":
			_set_lamp(AMBER, 0.5)
		_:
			_set_lamp(LAMP_SHUT, 0.45)


func _set_lamp(color: Color, glow: float) -> void:
	door_lamp.modulate = color
	door_lamp_glow.modulate = Color(color, glow)
	door_lamp_glow.visible = glow > 0.0''', path)
    s = sub(s, '''	_show_door()
	door_visual.scale = Vector2(1.04, 0.94)
	_door_tween = create_tween()
	_door_tween.tween_interval(DOOR_BREAK_SECONDS)
	_door_tween.tween_callback(func() -> void:
		door_breaking = false
		_show_door())
	_door_tween.tween_property(door_visual, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	refresh_state()''', '''	_show_door()
	_door_tween = create_tween()
	_door_tween.tween_interval(DOOR_BREAK_SECONDS)
	_door_tween.tween_callback(func() -> void:
		door_breaking = false
		_show_door())
	refresh_state()''', path)
    s = sub(s, '''## The sealed bulkhead until the blast, breaking for a moment, then blown open. All of it draws behind
## the actors (Main.ACTOR_Z) and its front pillar over them, so WOLF holding at the rubble and anyone
## walking through stay in the doorway.
func _show_door() -> void:
	door_art.visible = not door_blown
	door_breaking_art.visible = door_blown and door_breaking
	door_blown_art.visible = door_blown and not door_breaking''', '''## The shut leaf until the blast; the breaking leaf and its cracks for a moment; then the empty doorway,
## the damage and the leaf lying in the lane. The wall, the bay, the column and the stub always show.
func _show_door() -> void:
	var down: bool = door_blown and not door_breaking
	door_leaf.visible = not door_blown
	door_leaf_breaking.visible = door_blown and door_breaking
	door_cracks.visible = door_blown and door_breaking
	door_hole.visible = down
	door_damage.visible = down
	door_leaf_down.visible = down''', path)
    s = sub(s, '''	door_visual.scale = Vector2.ONE
	_show_door()''', '''	_show_door()''', path)
    s = sub(s, '''	if door_blown:
		draw_line(Vector2(RUBBLE_X - 6.0, 439.0), Vector2(RUBBLE_X + 6.0, 439.0), AMBER, 3.0)
	_draw_alcove_floor()
''', '', path)
    s = sub(s, s[s.index('''## The alcove's floor: a tint over exactly the cover span'''):s.index('''## The shadow of the alcove behind the TANK RELEASE''')], '', path)
    s = sub(s, '''## The shadow of the alcove behind the TANK RELEASE, drawn on [param canvas] (Recesses, under the
## props): a soft-edged dark recess in the wall, deepest in the middle, with no outline, so it reads
## as part of the painted wall. Its core is exactly SentryBrain's cover span, the x range where an
## engineer is out of the sentry's sight, and the floor under it is tinted over the same span.
func draw_recesses(canvas: CanvasItem) -> void:
	var alcove: Rect2 = alcove_rect()
	canvas.draw_texture_rect(alcove_shadow, alcove.grow_individual(14.0, 10.0, 14.0, 8.0), false, Color(0.0, 0.02, 0.04, 0.85))
	_draw_bolt_feed(canvas)''', '''## What Recesses draws under the props: the release's feed to the exit bolt (the bay itself is painted,
## ReleaseBay, drawn over it, so the feed leaves the bay behind its right post).
func draw_recesses(canvas: CanvasItem) -> void:
	_draw_bolt_feed(canvas)''', path)
    s = s.replace("DOOR_LIP_Z", "DOOR_FRONT_Z").replace("the junction door's front pillar (DOOR_FRONT_Z)", "the blast door's column (DOOR_FRONT_Z)")
    open(path, "w").write(s)


def patch_main(path: str) -> None:
    s = open(path).read()
    s = sub(s, '''	# So does the junction bulkhead's front pillar, which otherwise hides whoever stands in its doorway.
	# The corridor's near column stays solid: it is slim, and nobody stops behind it.
	junction_room.depth.pillars = [junction_room.door_lip]
''', '', path)
    open(path, "w").write(s)


def main():
    game = os.path.abspath(sys.argv[1])
    fin = os.path.join(WORK, "layers", "final")
    props = os.path.join(game, "assets", "props")
    shutil.copy(os.path.join(fin, "junction-door-atlas.png"), os.path.join(props, "junction-door-atlas.png"))
    imp = open(os.path.join(props, "corridor-seal-atlas.png.import")).read()
    imp = "\n".join(l for l in imp.splitlines() if not l.startswith(("uid=", "path=", "dest_files=", "source_file=")))
    imp = imp.replace("[deps]", '[deps]\n\nsource_file="res://assets/props/junction-door-atlas.png"')
    open(os.path.join(props, "junction-door-atlas.png.import"), "w").write(imp + "\n")
    shutil.copy(os.path.join(fin, "junction_door_layout.gd"), os.path.join(game, "scripts", "junction_door_layout.gd"))
    for n in ("sealed", "breaking", "blown", "front-lip"):
        for ext in ("", ".import"):
            p = os.path.join(props, f"junction-bulkhead-{n}.png{ext}")
            if os.path.exists(p):
                os.remove(p)
    patch_room(os.path.join(game, "scripts", "junction_room.gd"))
    patch_main(os.path.join(game, "scripts", "main.gd"))
    import patch_extra
    patch_extra.run(game)
    print("patched", game)


if __name__ == "__main__":
    main()
