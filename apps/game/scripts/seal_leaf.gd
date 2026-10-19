class_name SealLeaf
extends Node2D
## The corridor seal's rolling steel curtain, shut, rolling up and parked open. The door stands across
## the corridor in the cross-wall's turned face, so the curtain is drawn as a mesh in that plane: COLUMNS
## are vertical lines of the curtain (world x, the floor's y under them, and world px per metre of
## height there, from the design's camera model), and a point of the curtain [code]h[/code] metres up
## shows the curtain's art from [code]h - open * TRAVEL[/code] metres up, so the slats rise in their own
## plane and wind into the hood (the seal-head piece, drawn over it). The art is the whole piece
## seal-curtain (the approved art set, 2026-10-16): the curtain flat and face-on as seen from the
## corridor, ART_A_FAR..ART_A_NEAR metres along the wall's face wide and ART_HEIGHT_M tall, its striped
## bottom bar at the foot. The hood's shadow (HOOD_SHADOW_*) belongs to the place, not to the moving
## slats, so each vertex is shaded by the shadow where it is now. Open, only the bottom bar shows,
## tucked under the hood.

## Curtain columns in world px: (x, floor y under the column, px per metre of height), from the near
## jamb's guide (COLUMN_A_NEAR) to the far one (COLUMN_A_FAR), evenly along the face.
const COLUMNS: PackedVector3Array = [
	Vector3(791.391, 456.362, 42.3249), Vector3(782.03, 452.742, 41.8106), Vector3(772.894, 449.21, 41.3087),
	Vector3(763.974, 445.761, 40.8187), Vector3(755.264, 442.394, 40.3401), Vector3(746.755, 439.104, 39.8727),
	Vector3(738.442, 435.89, 39.4159), Vector3(730.317, 432.748, 38.9695), Vector3(722.373, 429.677, 38.5331),
]
## Where the first and last column stand along the wall's face (metres, a in the art set's doors.py:
## 0 where the face crosses the walk line, + toward the back wall; SealLeaf's curtain plane, t -0.07).
const COLUMN_A_NEAR: float = -2.16
const COLUMN_A_FAR: float = 1.51
## The painted curtain spans a = ART_A_NEAR..ART_A_FAR (the opening's -2.10..1.45 m plus 0.08 m into
## each guide) and is ART_HEIGHT_M tall (the 3.05 m opening plus 0.05 m into the hood): doors.py roll().
const ART_A_NEAR: float = -2.18
const ART_A_FAR: float = 1.53
const ART_HEIGHT_M: float = 3.10
## The curtain reaches this high (metres) shut; above it the curtain is inside the hood.
const TOP_M: float = 3.07
## How far the curtain rises (metres): its 115 mm bottom bar stays in sight under the hood.
const TRAVEL: float = 2.935
## The hood's shadow on the curtain from the corridor luminaire: full light below START, the darkest
## (FLOOR) above END.
const HOOD_SHADOW_START: float = 0.709
const HOOD_SHADOW_END: float = 2.024
const HOOD_SHADOW_FLOOR: float = 0.42
## Rows of the mesh (metres), so the shadow's falloff is smooth.
const ROWS: PackedFloat32Array = [0.0, 0.4, 0.709, 0.95, 1.2, 1.45, 1.7, 2.024, 2.5, 3.07]

## 0 shut, 1 wound up into the hood.
var open: float = 0.0:
	set(value):
		open = clampf(value, 0.0, 1.0)
		queue_redraw()
## The curtain's art (seal-curtain.png).
var texture: Texture2D


## A curtain drawn with [param art], the flat seal-curtain piece.
func _init(art: Texture2D) -> void:
	name = "SealLeaf"
	texture = art
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## How lit the curtain is at [param h] metres up, under the hood's shadow.
static func shadow_at(h: float) -> float:
	var t: float = clampf((h - HOOD_SHADOW_START) / (HOOD_SHADOW_END - HOOD_SHADOW_START), 0.0, 1.0)
	return 1.0 - (1.0 - HOOD_SHADOW_FLOOR) * pow(t, 1.3)


## The art's u (0 at its left edge, the far guide as the corridor sees it) of column [param index].
static func column_u(index: int) -> float:
	var a: float = lerpf(COLUMN_A_NEAR, COLUMN_A_FAR, float(index) / float(COLUMNS.size() - 1))
	return (ART_A_FAR - a) / (ART_A_FAR - ART_A_NEAR)


func _draw() -> void:
	var lift: float = open * TRAVEL
	var heights: PackedFloat32Array = PackedFloat32Array([lift])
	for row: float in ROWS:
		if row > lift + 0.001:
			heights.append(row)
	if heights.size() < 2:
		return
	# One vertex per column and height, column by column, then the grid's cells between them.
	var mesh: TriMesh = TriMesh.new()
	for index: int in COLUMNS.size():
		var column: Vector3 = COLUMNS[index]
		var u: float = column_u(index)
		for h: float in heights:
			var shade: float = shadow_at(h)
			mesh.add_vertex(Vector2(column.x, column.y - h * column.z), Vector2(u, 1.0 - (h - lift) / ART_HEIGHT_M), Color(shade, shade, shade, 1.0))
	mesh.add_grid(0, COLUMNS.size(), heights.size())
	mesh.draw(get_canvas_item(), texture)
