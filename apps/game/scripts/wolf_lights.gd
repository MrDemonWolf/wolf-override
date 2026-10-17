class_name WolfLights
extends Node2D
## WOLF's cyan eye and seam lights, drawn in code over his standing piece
## (assets/characters/wolf-stand.png). The piece was painted with these lights off (its shape guide
## showed them as dark glass), so the game lights them, as it does every other lamp and screen.
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
## Each light's centre on the piece (piece px from its centre; the piece is 1028x549, facing right).
## They are the earlier sprite's four lights (eye, neck seam, flank seam, tail seam) carried onto the
## repainted piece through its shape guide (old px times 1.65 from the earlier art's painted box),
## then checked on the piece: each lands on the dark glass the guide left there.
const CENTRES: Array[Vector2] = [Vector2(433.0, -144.5), Vector2(322.0, -87.5), Vector2(47.0, -16.5), Vector2(-313.0, 48.5)]
## Each light's half length and half width (piece px), and its long axis's angle from vertical
## (degrees, clockwise), measured on the earlier sprite's lit pixels and scaled by the same 1.65.
const HALF_SIZES: Array[Vector2] = [Vector2(4.2, 7.3), Vector2(3.5, 13.0), Vector2(4.3, 15.7), Vector2(2.5, 12.0)]
const ANGLES: Array[float] = [-57.0, 20.0, -41.0, 35.0]

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
	for index: int in CENTRES.size():
		var half: Vector2 = HALF_SIZES[index]
		draw_set_transform(CENTRES[index], deg_to_rad(ANGLES[index]), half)
		draw_circle(Vector2.ZERO, HALO_SCALE, Color(LIGHT, HALO_ALPHA))
		draw_circle(Vector2.ZERO, 1.0, LIGHT)
		draw_circle(Vector2.ZERO, 0.5, LIGHT.lerp(Color.WHITE, CORE_WHITE))
	draw_set_transform(Vector2.ZERO)
