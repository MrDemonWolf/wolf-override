class_name WolfLights
extends Node2D
## WOLF's cyan eye and seam lights, drawn in code over whichever of his pieces his body shows
## ([member pose]): standing (assets/characters/wolf-stand.png), lying on the dock's pad
## (wolf-lie-pad.png) or getting up off it (wolf-rise.png). The pieces were painted with these lights
## off (their shape guides showed them as dark glass), so the game lights them, as it does every other
## lamp and screen; one class lights every WOLF piece.
##
## It is a child of WOLF's BodySprite (see [method attach]), so it works in the piece's own pixels with
## its origin on the piece's centre, and the sprite's transform carries it: the duck's squash (scale)
## and WOLF's dimming while he passes behind the engineer (modulate). A child does not follow the
## sprite's flip_h or offset, so [method _process] copies both: it mirrors x when WOLF faces left and
## moves with the leap's lift (offset). It draws nothing else and has no gameplay effect.

## The earlier sprite's painted lights, averaged: rgb about (43..64, 200, 215).
const LIGHT: Color = Color("#2fd0dc")
## The bright core's centre is this much whiter than LIGHT, so it reads as a lit lens.
const CORE_WHITE: float = 0.45
## The soft additive halo round each light: this many times the light's size, at this opacity.
const HALO_SCALE: float = 2.6
const HALO_ALPHA: float = 0.22
## The standing piece's lights. Each light's centre on the piece (piece px from its centre; the piece
## is 1028x549, facing right).
## They are the earlier sprite's four lights (eye, neck seam, flank seam, tail seam) carried onto the
## repainted piece through its shape guide (old px times 1.65 from the earlier art's painted box),
## then checked on the piece: each lands on the dark glass the guide left there.
const CENTRES: Array[Vector2] = [Vector2(433.0, -144.5), Vector2(322.0, -87.5), Vector2(47.0, -16.5), Vector2(-313.0, 48.5)]
## Each light's half length and half width (piece px), and its long axis's angle from vertical
## (degrees, clockwise), measured on the earlier sprite's lit pixels and scaled by the same 1.65.
const HALF_SIZES: Array[Vector2] = [Vector2(4.2, 7.3), Vector2(3.5, 13.0), Vector2(4.3, 15.7), Vector2(2.5, 12.0)]
const ANGLES: Array[float] = [-57.0, 20.0, -41.0, 35.0]
## The lying and getting-up pieces' lights, in the same form (centre, half size and angle, piece px from
## the piece's centre, facing right): the eye and one flank seam, from the art set's compose.py
## WOLF_LIE_LIGHTS (on the 1016 x 280 lying piece: eye at 0.903, 0.418 of its box, measured; seam at
## 0.55, 0.50, est.) and WOLF_RISE_LIGHTS (on the 743 x 413 getting-up piece: eye at 0.919, 0.237 and
## shoulder seam at 0.70, 0.42, both est.), sized like the standing eye and seams at each piece's scale.
const LIE_CENTRES: Array[Vector2] = [Vector2(409.4, -23.0), Vector2(50.8, 0.0)]
const LIE_HALF_SIZES: Array[Vector2] = [Vector2(4.2, 5.5), Vector2(3.5, 13.0)]
const LIE_ANGLES: Array[float] = [-70.0, 90.0]
const RISE_CENTRES: Array[Vector2] = [Vector2(311.3, -108.6), Vector2(148.6, -33.0)]
const RISE_HALF_SIZES: Array[Vector2] = [Vector2(3.2, 5.5), Vector2(2.6, 9.7)]
const RISE_ANGLES: Array[float] = [-57.0, 20.0]

## Which piece the body shows: &"stand", &"lie" or &"rise" (Main._wolf_pose sets it with the texture).
var pose: StringName = &"stand":
	set(value):
		pose = value
		queue_redraw()
## The lights' colour (LIGHT; the dock's wake turns them blue) and how bright they are, 0 dark .. 1 lit
## (dim while he rests on the pad).
var tint: Color = LIGHT:
	set(value):
		tint = value
		queue_redraw()
var strength: float = 1.0:
	set(value):
		strength = value
		queue_redraw()

var _sprite: Sprite2D


## Adds the lights to [param sprite] (WOLF's BodySprite, drawing wolf-stand.png) and returns them.
static func attach(sprite: Sprite2D) -> WolfLights:
	var lights: WolfLights = WolfLights.new()
	lights.name = "Lights"
	lights._sprite = sprite
	lights.material = FxKit.additive()
	sprite.add_child(lights)
	return lights


func _process(_delta: float) -> void:
	if _sprite == null:
		return
	var mirrored: float = -1.0 if _sprite.flip_h else 1.0
	if scale.x != mirrored:
		scale.x = mirrored
	if position != _sprite.offset:
		position = _sprite.offset


func _draw() -> void:
	if strength <= 0.0:
		return
	var centres: Array[Vector2] = CENTRES
	var halves: Array[Vector2] = HALF_SIZES
	var angles: Array[float] = ANGLES
	if pose == &"lie":
		centres = LIE_CENTRES
		halves = LIE_HALF_SIZES
		angles = LIE_ANGLES
	elif pose == &"rise":
		centres = RISE_CENTRES
		halves = RISE_HALF_SIZES
		angles = RISE_ANGLES
	for index: int in centres.size():
		draw_set_transform(centres[index], deg_to_rad(angles[index]), halves[index])
		draw_circle(Vector2.ZERO, HALO_SCALE, Color(tint, HALO_ALPHA * strength))
		draw_circle(Vector2.ZERO, 1.0, Color(tint, strength))
		draw_circle(Vector2.ZERO, 0.5, Color(tint.lerp(Color.WHITE, CORE_WHITE), strength))
	draw_set_transform(Vector2.ZERO)
