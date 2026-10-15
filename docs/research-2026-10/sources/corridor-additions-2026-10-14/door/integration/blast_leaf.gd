class_name BlastLeaf
extends Node2D
## The corridor seal's inner blast leaf while the seal opens (round 7, add7 track DOOR; proposed, not
## yet in any game copy). A 0.24 m steel-faced concrete leaf runs in a slot 0.22..0.46 m behind the
## cross-wall's face on flanged wheels in a floor rail: shut, its leading edge sits in a receiver in
## the near jamb (behind the column); it slides back along the wall into a pocket in the far side,
## and open its leading edge stands flush in the pocket's mouth (that parked edge is painted into the
## wall piece, so this node only draws while the seal moves). It is drawn as a mesh in its own planes:
## the front face (t = T_LF, from the leading edge to the pocket's mouth) and the leading edge
## (a = a_lead, t from T_LF to T_LB), projected with the design's camera. The light belongs to the
## place, not to the moving leaf: each front-face vertex is shaded from LIGHT at its fixed spot.
## Driven only by the seal's existing open value: it starts to slide once the roller is 40 % up.

## Camera of the door end (design/tools/common.py): vanishing point, floor, walkway depth, scale.
const VPX: float = 483.9
const HORIZON: float = 158.5
const FLOOR_Y: float = 440.0
const D0: float = 38.0
const PX_PER_M: float = 40.0
## The cross-wall's frame: origin (metres) where its face meets the walk line (world 752, 440), U
## along the face toward the corridor's back wall, N into the wall.
const ORIGIN_X_M: float = 18.8
const U: Vector2 = Vector2(-0.2913294, 0.9566228)  # (x, depth) components
const N: Vector2 = Vector2(0.9566228, 0.2913294)
## Leaf geometry (metres).
const T_LF: float = 0.22
const T_LB: float = 0.46
const A_MOUTH: float = 1.46348
const A_LEAD_SHUT: float = -2.19069
const TRAVEL_M: float = 3.65417
const LEAF_TOP_M: float = 3.2
const H_OPEN: float = 3.05
const START: float = 0.4
## Atlas regions (corridor-seal-atlas.png, round 7) and their texel densities.
const FRONT_REGION: Rect2 = Rect2(449.0, 705.0, 158.0, 256.0)
const EDGE_REGION: Rect2 = Rect2(613.0, 705.0, 19.0, 256.0)
const U_TEXELS_PER_M: float = 40.0
const H_TEXELS_PER_M: float = 80.0
## Light on the front plane: columns at fixed a (mouth first), rows at fixed h; grey vertex colour.
const A_COLS: PackedFloat32Array = [1.4635, 1.0067, 0.5499, 0.0932, -0.3636, -0.8204, -1.2771, -1.7339, -2.1907]
const H_ROWS: PackedFloat32Array = [0.0, 0.4, 0.8, 1.2, 1.6, 2.0, 2.4, 2.75, 3.05]
## (row-major: index = column * H_ROWS.size() + row)
const LIGHT: PackedFloat32Array = [
	0.612, 0.612, 0.612, 0.612, 0.642, 0.642, 0.642, 0.552, 0.552, 0.761, 0.791, 0.821, 0.821, 0.851, 0.881, 0.94, 0.582, 0.552, 0.791, 0.821, 0.821, 0.851, 0.881, 0.91, 0.97, 0.612, 0.582, 0.821, 0.851, 0.851, 0.881, 0.91, 0.94, 0.97, 0.642, 0.612, 0.881, 0.881, 0.881, 0.91, 0.91, 0.94, 0.97, 0.672, 0.642, 0.91, 0.91, 0.94, 0.94, 0.94, 0.94, 0.94, 0.701, 0.672, 0.97, 0.97, 0.97, 0.94, 0.94, 0.94, 0.91, 0.731, 0.701, 1.0, 1.0, 1.0, 0.97, 0.94, 0.94, 0.91, 0.731, 0.701, 0.463, 0.463, 0.463, 0.493, 0.493, 0.493, 0.493, 0.343, 0.343,
]

## The seal's open value (0 shut, 1 open), the same value SealLeaf.open takes.
var open: float = 0.0:
	set(value):
		open = clampf(value, 0.0, 1.0)
		queue_redraw()
var texture: Texture2D


func _init(atlas: Texture2D) -> void:
	name = "BlastLeaf"
	texture = atlas
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## World (clamp-world) position of the point a metres along the wall, h up, t into it.
static func project(a: float, h: float, t: float) -> Vector2:
	var x_m: float = ORIGIN_X_M + a * U.x + t * N.x
	var depth: float = a * U.y + t * N.y
	var s: float = D0 / (D0 + depth)
	return Vector2(VPX + (x_m * PX_PER_M - VPX) * s, HORIZON + (FLOOR_Y - HORIZON) * s - h * PX_PER_M * s)


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


func _draw() -> void:
	var lead: float = lead_at(open)
	var size: Vector2 = texture.get_size()
	var points: PackedVector2Array = PackedVector2Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	# front face: columns from the leading edge back to the pocket's mouth
	var cols: PackedFloat32Array = PackedFloat32Array([lead])
	for i: int in range(A_COLS.size() - 1, -1, -1):
		if A_COLS[i] > lead + 0.0001:
			cols.append(A_COLS[i])
	var rows: int = H_ROWS.size()
	if cols.size() >= 2:
		for a: float in cols:
			for h: float in H_ROWS:
				points.append(project(a, h, T_LF))
				var texel: Vector2 = FRONT_REGION.position + Vector2((a - lead) * U_TEXELS_PER_M, (LEAF_TOP_M - h) * H_TEXELS_PER_M)
				uvs.append(texel / size)
				var g: float = light_at(a, h)
				colors.append(Color(g, g, g, 1.0))
		for c: int in cols.size() - 1:
			for r: int in rows - 1:
				var i0: int = c * rows + r
				var i1: int = (c + 1) * rows + r
				indices.append_array([i0, i1, i0 + 1, i0 + 1, i1, i1 + 1])
	# leading edge
	var base: int = points.size()
	var ge: float = edge_light(lead)
	for t: float in [T_LF, T_LB]:
		for h: float in H_ROWS:
			points.append(project(lead, h, t))
			var texel: Vector2 = EDGE_REGION.position + Vector2((t - T_LF) * H_TEXELS_PER_M, (LEAF_TOP_M - h) * H_TEXELS_PER_M)
			uvs.append(texel / size)
			colors.append(Color(ge, ge, ge, 1.0))
	for r: int in rows - 1:
		var j0: int = base + r
		var j1: int = base + rows + r
		indices.append_array([j0, j1, j0 + 1, j0 + 1, j1, j1 + 1])
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, points, colors, uvs, PackedInt32Array(), PackedFloat32Array(), texture.get_rid())
