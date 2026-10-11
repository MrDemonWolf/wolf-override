class_name OpeningHatch
extends Node2D
## The maintenance crawl hatch low on the containment wall behind WOLF's cage, the way he leaves in the
## opening. Three aligned layers cut from one painted hatch: the dark duct behind the opening, the leaf
## that slides up out of it (clipped to the opening, so it disappears into the wall), and the frame in
## front, with the lamp on its top bar drawn over the painted lens. The node sits on the floor at its
## sill. WOLF draws in front of all of it, except while he slips into the duct (slip_z puts him between
## the duct and the frame).

const FRAME_ART: Texture2D = preload("res://assets/props/opening-hatch-frame.png")
const LEAF_ART: Texture2D = preload("res://assets/props/opening-hatch-leaf.png")
const DUCT_ART: Texture2D = preload("res://assets/props/opening-hatch-duct.png")
## World px per art px: the opening is 41.5 px tall, enough for WOLF crouched low and shrinking into
## the duct (Main._slip_into_hatch).
const ART_SCALE: float = 0.21
## In art px: the opening (x, y, w, h) and the unlit lens on the top bar, and the art's bottom row (the
## sill, on the floor), all measured on the 640x387 layers.
const OPENING: Rect2 = Rect2(113.4, 98.5, 415.2, 197.5)
const LAMP: Rect2 = Rect2(279.8, 35.4, 79.4, 14.8)
const SILL_ROW: float = 380.3
## Shut and locked, the lamp is red like the cage's; it turns green as the hatch opens.
const LAMP_LOCKED: Color = Color("#db4f39")
const LAMP_OPEN: Color = Color("#56dc69")
## The containment room is darker than the painted steel: the hatch is graded down to sit in it.
const ROOM_TINT: Color = Color(0.6, 0.66, 0.74)
## The layers' depth: the duct and its leaf under the frame, and the slot between them that WOLF takes
## while he slips in.
const DUCT_Z: int = -1
const FRAME_Z: int = 1
const SLIP_Z: int = 0

## 0 shut, 1 open: the leaf has slid this far up out of the opening.
var open: float = 0.0:
	set(value):
		open = clampf(value, 0.0, 1.0)
		if leaf != null:
			leaf.position.y = -open * OPENING.size.y
## The lamp's colour, drawn over the painted lens.
var lamp: Color = LAMP_LOCKED:
	set(value):
		lamp = value
		if lamp_rect != null:
			lamp_rect.color = lamp
			lamp_glow.modulate = Color(lamp, 0.55)

var duct: Sprite2D
var leaf: Sprite2D
var frame: Sprite2D
var lamp_rect: ColorRect
var lamp_glow: Sprite2D


func _init() -> void:
	duct = _layer("Duct", DUCT_ART)
	duct.z_index = DUCT_Z
	# The leaf is the duct's child, clipped to the duct's own shape: the opening.
	duct.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	add_child(duct)
	leaf = Sprite2D.new()
	leaf.name = "Leaf"
	leaf.texture = LEAF_ART
	leaf.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	leaf.self_modulate = ROOM_TINT
	duct.add_child(leaf)
	frame = _layer("Frame", FRAME_ART)
	frame.z_index = FRAME_Z
	add_child(frame)
	# The lamp rides on the frame, in its own pixels.
	lamp_rect = ColorRect.new()
	lamp_rect.name = "Lamp"
	lamp_rect.position = LAMP.position - FRAME_ART.get_size() * 0.5
	lamp_rect.size = LAMP.size
	lamp_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(lamp_rect)
	lamp_glow = RoomDepth.make_glow(LAMP_LOCKED, LAMP.size * 3.0, 0.55)
	lamp_glow.name = "LampGlow"
	lamp_glow.position = LAMP.get_center() - FRAME_ART.get_size() * 0.5
	frame.add_child(lamp_glow)
	lamp = LAMP_LOCKED
	open = 0.0


## Places the hatch with its sill on [param floor_y], centred on [param x].
func place(x: float, floor_y: float) -> void:
	position = Vector2(x, floor_y - (SILL_ROW - FRAME_ART.get_size().y * 0.5) * ART_SCALE)


## The opening in the world, for WOLF to slip into.
func opening_rect() -> Rect2:
	return Rect2(position + (OPENING.position - FRAME_ART.get_size() * 0.5) * ART_SCALE, OPENING.size * ART_SCALE)


## Shut and locked, as the scene starts.
func reset() -> void:
	open = 0.0
	lamp = LAMP_LOCKED


func _layer(layer_name: String, texture: Texture2D) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = layer_name
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.scale = Vector2.ONE * ART_SCALE
	sprite.self_modulate = ROOM_TINT
	return sprite
