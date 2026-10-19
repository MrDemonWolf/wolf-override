class_name BlastLeaf
extends Node2D
## The corridor seal's inner blast leaf while the seal opens. A 0.36 m steel-faced concrete leaf runs
## in a slot 0.14..0.54 m behind the cross-wall's face on two bogies in a floor rail: shut, its
## leading edge sits in a receiver in the near jamb (behind the column); it slides back along the
## wall into a pocket in the far side, and open its leading edge stands flush in the pocket's mouth
## (only the seal-back piece's pocket mouth shows of it then, and shut the curtain hides it, so this node
## only draws while the seal moves).
## Its art is the whole piece seal-blast-leaf (the approved art set, 2026-10-16): the leaf flat and
## face-on as seen from the corridor, its leading end on the right, then its 0.36 m leading edge.
## It is drawn as a mesh in its own planes: the front face (t = T_LF, from the leading edge to the
## pocket's mouth), the leading edge (a = a_lead, t from T_LF to T_LB), and a feathered contact
## shadow on the threshold in front of its foot (SHADOW_COLOR, vertex alpha), all projected
## with the door end's design camera (DoorCamera). The light belongs to the place, not to the moving
## leaf: each front-face vertex is shaded from LIGHT at its fixed spot. Driven only by the seal's
## existing open value: it starts to slide once the roller is 40 % up.

## The cross-wall's frame: origin (metres) where its face meets the walk line (world 752, 440), U
## along the face toward the corridor's back wall, N into the wall.
const ORIGIN_X_M: float = 18.8
const U: Vector2 = Vector2(-0.2913294, 0.9566228)  # (x, depth) components
const N: Vector2 = Vector2(0.9566228, 0.2913294)
## Leaf geometry (metres).
const T_LF: float = 0.16
const T_LB: float = 0.52
const A_MOUTH: float = 1.46348
const A_LEAD_SHUT: float = -2.19069
const TRAVEL_M: float = 3.65417
const LEAF_TOP_M: float = 3.2
const H_OPEN: float = 3.05
const START: float = 0.4
## The piece's texel density both ways (345 x 256 px for 4.31 x 3.2 m) and where its front face ends
## and its leading edge's face begins (texel x: the front's 3.95 m).
const TEXELS_PER_M: float = 80.0
const FRONT_TEXELS: float = 3.95 * TEXELS_PER_M
## The contact shadow's colour; its feather is vertex alpha.
const SHADOW_COLOR: Color = Color.BLACK
## The contact shadow reaches this far in front of the foot (m) and is this dark at the foot.
const SHADOW_DEPTH_M: float = 0.14
const SHADOW_ALPHA: float = 0.62
## Light on the front plane: columns at fixed a (mouth first), rows at fixed h; grey vertex colour.
const A_COLS: PackedFloat32Array = [1.4635, 1.0067, 0.5499, 0.0932, -0.3636, -0.8204, -1.2771, -1.7339, -2.1907]
const H_ROWS: PackedFloat32Array = [0.0, 0.4, 0.8, 1.2, 1.6, 2.0, 2.4, 2.75, 3.05]
## (row-major: index = column * H_ROWS.size() + row)
const LIGHT: PackedFloat32Array = [
	0.612, 0.612, 0.612, 0.612, 0.612, 0.612, 0.612, 0.552, 0.552, 0.761, 0.791, 0.791, 0.821, 0.851, 0.881, 0.91, 0.582, 0.552, 0.791, 0.821, 0.821, 0.851, 0.881, 0.91, 0.94, 0.612, 0.582, 0.821, 0.851, 0.851, 0.881, 0.881, 0.91, 0.97, 0.642, 0.612, 0.881, 0.881, 0.881, 0.91, 0.91, 0.94, 0.97, 0.672, 0.642, 0.91, 0.91, 0.91, 0.91, 0.91, 0.94, 0.94, 0.701, 0.672, 0.97, 0.97, 0.97, 0.94, 0.94, 0.91, 0.91, 0.731, 0.701, 1.0, 1.0, 1.0, 0.97, 0.94, 0.91, 0.881, 0.731, 0.701, 0.463, 0.463, 0.463, 0.463, 0.493, 0.493, 0.493, 0.343, 0.343,
]

## The seal's open value (0 shut, 1 open), the same value SealLeaf.open takes.
var open: float = 0.0:
	set(value):
		open = clampf(value, 0.0, 1.0)
		queue_redraw()
var texture: Texture2D


## A leaf drawn with [param art], the flat seal-blast-leaf piece.
func _init(art: Texture2D) -> void:
	name = "BlastLeaf"
	texture = art
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## World (clamp-world) position of the point a metres along the wall, h up, t into it: the wall
## frame's point in room metres (x along the room, depth behind the walk line), through DoorCamera.
static func project(a: float, h: float, t: float) -> Vector2:
	var x_m: float = ORIGIN_X_M + a * U.x + t * N.x
	var depth: float = a * U.y + t * N.y
	return DoorCamera.project(x_m, h, depth)


static func lead_at(open_value: float) -> float:
	return A_LEAD_SHUT + clampf((open_value - START) / (1.0 - START), 0.0, 1.0) * TRAVEL_M


## The place's light on the front plane at (a, h), bilinear in LIGHT.
static func light_at(a: float, h: float) -> float:
	var ai: float = 0.0
	for i: int in A_COLS.size() - 1:
		if a <= A_COLS[i] and a >= A_COLS[i + 1]:
			ai = i + (A_COLS[i] - a) / (A_COLS[i] - A_COLS[i + 1])
	if a < A_COLS[A_COLS.size() - 1]:
		ai = A_COLS.size() - 1
	var hi: float = 0.0
	for j: int in H_ROWS.size() - 1:
		if h >= H_ROWS[j] and h <= H_ROWS[j + 1]:
			hi = j + (h - H_ROWS[j]) / (H_ROWS[j + 1] - H_ROWS[j])
	var a0: int = int(floor(ai))
	var h0: int = int(floor(hi))
	var a1: int = mini(a0 + 1, A_COLS.size() - 1)
	var h1: int = mini(h0 + 1, H_ROWS.size() - 1)
	var fa: float = ai - a0
	var fh: float = hi - h0
	var nh: int = H_ROWS.size()
	var low: float = lerpf(LIGHT[a0 * nh + h0], LIGHT[a1 * nh + h0], fa)
	var high: float = lerpf(LIGHT[a0 * nh + h1], LIGHT[a1 * nh + h1], fa)
	return lerpf(low, high, fh)


## The leading edge faces the near jamb: lit by the plant room through the gap behind it.
static func edge_light(lead: float) -> float:
	return 0.35 + 0.65 * sqrt(clampf((lead - (A_LEAD_SHUT + 0.1)) / 1.2, 0.0, 1.0))


## Two TriMeshes: the front face, then the leading edge, in one textured call, then the contact shadow
## in vertex colour alone over them.
func _draw() -> void:
	var lead: float = lead_at(open)
	var size: Vector2 = texture.get_size()
	var mesh: TriMesh = TriMesh.new()
	# front face: columns from the leading edge back to the pocket's mouth
	var cols: PackedFloat32Array = PackedFloat32Array([lead])
	for i: int in range(A_COLS.size() - 1, -1, -1):
		if A_COLS[i] > lead + 0.0001:
			cols.append(A_COLS[i])
	var rows: int = H_ROWS.size()
	if cols.size() >= 2:
		for a: float in cols:
			for h: float in H_ROWS:
				var texel: Vector2 = Vector2(FRONT_TEXELS - (a - lead) * TEXELS_PER_M, (LEAF_TOP_M - h) * TEXELS_PER_M)
				var g: float = light_at(a, h)
				mesh.add_vertex(project(a, h, T_LF), texel / size, Color(g, g, g, 1.0))
		mesh.add_grid(0, cols.size(), rows)
	# leading edge: two columns (its front and back corner lines), each with every row
	var base: int = mesh.vertex_count()
	var ge: float = edge_light(lead)
	for t: float in [T_LF, T_LB]:
		for h: float in H_ROWS:
			var texel: Vector2 = Vector2(FRONT_TEXELS + (t - T_LF) * TEXELS_PER_M, (LEAF_TOP_M - h) * TEXELS_PER_M)
			mesh.add_vertex(project(lead, h, t), texel / size, Color(ge, ge, ge, 1.0))
	mesh.add_grid(base, 2, rows)
	# contact shadow on the threshold, in front of the foot: dark at the foot, clear at its far edge
	# (a 2 x 2 grid: at the leading edge and at the mouth, each at the foot and SHADOW_DEPTH_M out)
	mesh.draw(get_canvas_item(), texture)
	var shadow: TriMesh = TriMesh.new()
	for a: float in [lead, A_MOUTH]:
		for k: int in 2:
			shadow.add_vertex(project(a, 0.0, T_LF - SHADOW_DEPTH_M * k), Vector2.ZERO, Color(SHADOW_COLOR, SHADOW_ALPHA * (1 - k)))
	shadow.add_grid(0, 2, 2)
	shadow.draw(get_canvas_item(), null)
