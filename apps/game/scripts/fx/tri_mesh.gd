class_name TriMesh
extends RefCounted
## One textured triangle mesh, built vertex by vertex and drawn in a single
## RenderingServer.canvas_item_add_triangle_array call (one draw call, so pieces on the same atlas
## batch). The door leaves drawn as meshes in their own planes build theirs here instead of each
## keeping four packed arrays and its own index loops: SealLeaf (the corridor's rolling curtain),
## BlastLeaf, SwingLeaf and SlideLeaf.
##
## What must stay true for every user: vertices and indices go into the arrays in exactly the order
## the caller adds them, and nothing is reordered, merged or dropped, so a mesh built here draws the
## same pixels as the hand-built arrays it replaced. Points are in the canvas item's local px, UVs
## are normalised (0..1 of the texture), and the colour is the vertex's modulate (light and alpha).
## Build one per _draw: it is a RefCounted and is freed when _draw returns.

var points: PackedVector2Array = PackedVector2Array()
var uvs: PackedVector2Array = PackedVector2Array()
var colors: PackedColorArray = PackedColorArray()
var indices: PackedInt32Array = PackedInt32Array()


## How many vertices have been added: the index the next one gets.
func vertex_count() -> int:
	return points.size()


## Adds one vertex at [param point] (local px) showing [param uv] of the texture, modulated by
## [param color].
func add_vertex(point: Vector2, uv: Vector2, color: Color) -> void:
	points.append(point)
	uvs.append(uv)
	colors.append(color)


## Adds the two triangles of every cell of a grid whose [param columns] x [param rows] vertices were
## added column by column (each column's rows in order) starting at index [param first]. For column
## c and row r the cell's corners are i0 = first + c * rows + r and i1 = i0 + rows (the next column),
## and its triangles are (i0, i1, i0 + 1) and (i0 + 1, i1, i1 + 1).
func add_grid(first: int, columns: int, rows: int) -> void:
	for c: int in columns - 1:
		for r: int in rows - 1:
			var i0: int = first + c * rows + r
			var i1: int = i0 + rows
			indices.append_array([i0, i1, i0 + 1, i0 + 1, i1, i1 + 1])


## Adds the two triangles of one quad whose four corners were added in order (round the quad)
## starting at index [param first]: (first, first + 1, first + 2) and (first, first + 2, first + 3).
func add_quad(first: int) -> void:
	indices.append_array([first, first + 1, first + 2, first, first + 2, first + 3])


## True while no vertex has been added, so there is nothing to draw.
func is_empty() -> bool:
	return points.is_empty()


## Draws the mesh on [param canvas_item] with [param texture] in one call (call it from the canvas
## item's _draw); does nothing when the mesh has no vertex. A null texture draws the vertex colours
## alone (a swing leaf's edge and closer arm, a leaf's contact shadow).
func draw(canvas_item: RID, texture: Texture2D) -> void:
	if is_empty():
		return
	RenderingServer.canvas_item_add_triangle_array(canvas_item, indices, points, colors, uvs, PackedInt32Array(), PackedFloat32Array(), texture.get_rid() if texture != null else RID())
