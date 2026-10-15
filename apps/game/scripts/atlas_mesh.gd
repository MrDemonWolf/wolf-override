class_name AtlasMesh
extends Node2D
## Pieces of one atlas drawn as a single triangle array, so a room's door pieces at one depth cost one
## draw call between them: flat quads (a region at a world top-left and scale, with a vertex colour
## the game can tint, like a status lamp's glass) and swinging leaves (SwingLeaf, which then draw
## nothing themselves). Pieces draw in the order they were added, later over earlier.

var texture: Texture2D
## Each quad: [region (Rect2), world top-left (Vector2), scale (float), colour (Color)], or a leaf.
var _pieces: Array = []


func _init(atlas: Texture2D) -> void:
	texture = atlas
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## Adds a flat piece; returns its index for [method set_color].
func add_quad(region: Rect2, top_left: Vector2, scale_factor: float, color: Color = Color.WHITE) -> int:
	_pieces.append([region, top_left, scale_factor, color])
	queue_redraw()
	return _pieces.size() - 1


## Draws [param leaf] here, at its place in the order, from now on.
func add_leaf(leaf: SwingLeaf) -> void:
	leaf.host = self
	_pieces.append(leaf)
	queue_redraw()


func set_color(index: int, color: Color) -> void:
	(_pieces[index] as Array)[3] = color
	queue_redraw()


func get_color(index: int) -> Color:
	return (_pieces[index] as Array)[3]


## The world rectangle a flat piece covers.
func quad_rect(index: int) -> Rect2:
	var piece: Array = _pieces[index]
	return Rect2(piece[1], (piece[0] as Rect2).size * float(piece[2]))


func _draw() -> void:
	var mesh: Array = [PackedVector2Array(), PackedVector2Array(), PackedColorArray(), PackedInt32Array()]
	var size: Vector2 = texture.get_size()
	for piece: Variant in _pieces:
		if piece is SwingLeaf:
			(piece as SwingLeaf).append_mesh(mesh)
			continue
		var region: Rect2 = piece[0]
		var top_left: Vector2 = piece[1]
		var extent: Vector2 = region.size * float(piece[2])
		var color: Color = piece[3]
		var points: PackedVector2Array = mesh[0]
		var uvs: PackedVector2Array = mesh[1]
		var colors: PackedColorArray = mesh[2]
		var indices: PackedInt32Array = mesh[3]
		var first: int = points.size()
		for corner: Vector2 in [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)]:
			points.append(top_left + extent * corner)
			uvs.append((region.position + region.size * corner) / size)
			colors.append(color)
		indices.append_array([first, first + 1, first + 2, first, first + 2, first + 3])
		mesh[0] = points
		mesh[1] = uvs
		mesh[2] = colors
		mesh[3] = indices
	if not (mesh[3] as PackedInt32Array).is_empty():
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), mesh[3], mesh[0], mesh[2], mesh[1], PackedInt32Array(), PackedFloat32Array(), texture.get_rid())
