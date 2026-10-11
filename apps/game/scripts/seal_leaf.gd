class_name SealLeaf
extends Node2D
## The corridor seal's leaf sliding up into the bulkhead's header as the seal opens. It is cut from
## the sealed bulkhead image (LEAF) and clipped to the doorway (DOORWAY, which follows the slanted
## header), over the open bulkhead, so the frame stays put while the leaf rises and the lit passage
## shows from the floor up. Shut or open it is hidden; Main shows it only while the seal opens.

## The leaf, in the bulkhead canvas's pixels (both bulkhead images share it).
const LEAF: Rect2 = Rect2(150.0, 160.0, 188.0, 440.0)
## The doorway the leaf slides inside, in the same pixels; its top is the header's underside.
const DOORWAY: Array[Vector2] = [Vector2(150.0, 166.0), Vector2(236.0, 166.0), Vector2(338.0, 230.0), Vector2(338.0, 600.0), Vector2(150.0, 600.0)]

## 0 shut, 1 risen fully into the header.
var open: float = 0.0:
	set(value):
		open = clampf(value, 0.0, 1.0)
		leaf.position.y = _rest_y - open * LEAF.size.y * _scale
var leaf: Sprite2D
var _region: Rect2
var _scale: float
var _rest_y: float


## [param texture] is the sealed bulkhead drawn from [param region] at [param art_scale]; place the
## node with [method align_to] on the sprite that shows it.
func _init(texture: Texture2D, region: Rect2, art_scale: float) -> void:
	name = "SealLeaf"
	_region = region
	_scale = art_scale
	clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	leaf = Sprite2D.new()
	leaf.name = "Leaf"
	leaf.texture = texture
	leaf.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	leaf.region_enabled = true
	leaf.region_rect = LEAF
	leaf.scale = Vector2.ONE * art_scale
	var centre: Vector2 = _local(LEAF.get_center())
	_rest_y = centre.y
	leaf.position = centre
	add_child(leaf)


## Lines the leaf up with [param art], a sprite drawing the same region at the same scale.
func align_to(art: Sprite2D) -> void:
	position = art.position - _region.size * _scale * 0.5


func _local(canvas_point: Vector2) -> Vector2:
	return (canvas_point - _region.position) * _scale


func _draw() -> void:
	# Only the mask: with CLIP_CHILDREN_ONLY the doorway itself is never drawn.
	var points: PackedVector2Array = PackedVector2Array()
	for point: Vector2 in DOORWAY:
		points.append(_local(point))
	draw_colored_polygon(points, Color.WHITE)
