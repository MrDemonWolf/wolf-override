class_name AtlasMesh
extends Node2D
## Pieces of one atlas drawn as a single triangle array, so a room's door pieces at one depth cost one
## draw call between them: flat quads (a region at a world top-left and scale, with a vertex colour
## the game can tint, like a status lamp's glass) and swinging leaves (SwingLeaf, which then draw
## nothing themselves). Pieces draw in the order they were added, later over earlier.

## The atlas every piece is cut from (each quad's region and each hosted leaf's regions are in its
## pixels); the one texture the single draw call binds. Set once by _init.
var texture: Texture2D
## Each quad: [region (Rect2), world top-left (Vector2), scale (float), colour (Color)], or a leaf.
var _pieces: Array = []


## A mesh on [param atlas] with nothing in it yet, sampled with mipmaps like the rooms' other door art.
## Rooms call [method make], which also names it and sets its z layer; _init alone leaves the node's
## name, z_index and z_as_relative at Godot's defaults.
func _init(atlas: Texture2D) -> void:
	texture = atlas
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## A new, empty mesh on [param atlas], named [param mesh_name], drawn at the absolute z [param z] (a
## RoomDepth layer such as Z_MID or Z_NEAR): z_as_relative is off, so it sorts against the actors by
## that layer whether the room adds it to itself or to its RoomDepth. The Records doors' plate and
## front meshes and the junction entry's mesh are made here; the caller adds pieces and the node.
static func make(atlas: Texture2D, mesh_name: String, z: int) -> AtlasMesh:
	var mesh: AtlasMesh = AtlasMesh.new(atlas)
	mesh.name = mesh_name
	mesh.z_as_relative = false
	mesh.z_index = z
	return mesh


## Adds a flat piece; returns its index for [method set_color].
func add_quad(region: Rect2, top_left: Vector2, scale_factor: float, color: Color = Color.WHITE) -> int:
	_pieces.append([region, top_left, scale_factor, color])
	queue_redraw()
	return _pieces.size() - 1


## Adds a flat piece centred on the world point [param centre] instead of placed by its top-left: a
## status lamp's glass, which the design places by the lamp's centre (the placement's "centre" or the
## room's *_LAMP point). The top-left is centre - region.size * scale_factor * 0.5, the expression the
## rooms used inline, in the same order, so the quad lands on the same 32-bit vertices. Returns its
## index for [method set_color]. Used by the Records doors' two lamps and the junction entry's.
func add_centred_quad(region: Rect2, centre: Vector2, scale_factor: float, color: Color = Color.WHITE) -> int:
	return add_quad(region, centre - region.size * scale_factor * 0.5, scale_factor, color)


## Draws [param leaf] here, at its place in the order, from now on.
func add_leaf(leaf: SwingLeaf) -> void:
	leaf.host = self
	_pieces.append(leaf)
	queue_redraw()


## Tints the flat piece [param index] (an index add_quad returned) with [param color],
## the vertex colour multiplied over its art, and redraws. The rooms' status lamps set their glass with it.
func set_color(index: int, color: Color) -> void:
	(_pieces[index] as Array)[3] = color
	queue_redraw()


## The vertex colour the flat piece [param index] is drawn with now: add_quad's, or the last set_color's.
func get_color(index: int) -> Color:
	return (_pieces[index] as Array)[3]


## The world rectangle a flat piece covers.
func quad_rect(index: int) -> Rect2:
	var piece: Array = _pieces[index]
	return Rect2(piece[1], (piece[0] as Rect2).size * float(piece[2]))


## Every piece in order into one TriMesh, drawn in one call (nothing is drawn while there is none).
func _draw() -> void:
	var mesh: TriMesh = TriMesh.new()
	var size: Vector2 = texture.get_size()
	for piece: Variant in _pieces:
		if piece is SwingLeaf:
			(piece as SwingLeaf).append_mesh(mesh)
			continue
		var region: Rect2 = piece[0]
		var top_left: Vector2 = piece[1]
		var extent: Vector2 = region.size * float(piece[2])
		var color: Color = piece[3]
		var first: int = mesh.vertex_count()
		for corner: Vector2 in [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)]:
			mesh.add_vertex(top_left + extent * corner, (region.position + region.size * corner) / size, color)
		mesh.add_quad(first)
	mesh.draw(get_canvas_item(), texture)
