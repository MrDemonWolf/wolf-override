class_name SealLeaf
extends Node2D
## The corridor seal's rolling steel curtain while it opens. The door stands across the corridor in
## the cross-wall's turned face, so the curtain is drawn as a mesh in that plane: COLUMNS are vertical
## lines of the curtain (world x, the floor's y under them, and world px per metre of height there,
## from the design's camera model), and a point of the curtain [code]h[/code] metres up shows the
## closed curtain's art from [code]h - open * TRAVEL[/code] metres up, so the slats rise in their own
## plane and wind into the hood. The art is lit as a function of its column only; the hood's shadow
## (HOOD_SHADOW_*) belongs to the place, not to the moving slats, so each vertex is shaded by the
## shadow where it is now over the shadow its art was painted with (never brighter than the art).
## Shut it matches the scene's DoorArt (the same image, uncut), open it matches Main's tucked-bar
## image CorridorDoorOpen; Main shows this only while the seal opens.

## Curtain columns in world px: (x, floor y under the column, px per metre of height).
const COLUMNS: PackedVector3Array = [
	Vector3(791.391, 456.362, 42.3249), Vector3(782.03, 452.742, 41.8106), Vector3(772.894, 449.21, 41.3087),
	Vector3(763.974, 445.761, 40.8187), Vector3(755.264, 442.394, 40.3401), Vector3(746.755, 439.104, 39.8727),
	Vector3(738.442, 435.89, 39.4159), Vector3(730.317, 432.748, 38.9695), Vector3(722.373, 429.677, 38.5331),
]
## The curtain art reaches this high (metres); above it the curtain is inside the hood.
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
var texture: Texture2D
## The closed curtain's region in [member texture] (the door end's atlas).
var region: Rect2
## World position of the art's top-left pixel, and world px per art pixel.
var art_origin: Vector2
var art_scale: float


## [param art] holds the closed curtain (the scene's DoorArt) in [param art_region], its top-left
## pixel at world [param origin], drawn at [param scale_factor] world px per pixel.
func _init(art: Texture2D, art_region: Rect2, origin: Vector2, scale_factor: float) -> void:
	name = "SealLeaf"
	texture = art
	region = art_region
	art_origin = origin
	art_scale = scale_factor
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## How lit the curtain is at [param h] metres up, under the hood's shadow.
static func shadow_at(h: float) -> float:
	var t: float = clampf((h - HOOD_SHADOW_START) / (HOOD_SHADOW_END - HOOD_SHADOW_START), 0.0, 1.0)
	return 1.0 - (1.0 - HOOD_SHADOW_FLOOR) * pow(t, 1.3)


func _draw() -> void:
	var lift: float = open * TRAVEL
	var heights: PackedFloat32Array = PackedFloat32Array([lift])
	for row: float in ROWS:
		if row > lift + 0.001:
			heights.append(row)
	if heights.size() < 2:
		return
	var size: Vector2 = texture.get_size()
	var points: PackedVector2Array = PackedVector2Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	for column: Vector3 in COLUMNS:
		for h: float in heights:
			points.append(Vector2(column.x, column.y - h * column.z))
			var art: Vector2 = Vector2(column.x, column.y - (h - lift) * column.z)
			uvs.append((region.position + (art - art_origin) / art_scale) / size)
			var shade: float = shadow_at(h) / shadow_at(h - lift)
			colors.append(Color(shade, shade, shade, 1.0))
	var rows: int = heights.size()
	var indices: PackedInt32Array = PackedInt32Array()
	for c: int in COLUMNS.size() - 1:
		for r: int in rows - 1:
			var a: int = c * rows + r
			var b: int = (c + 1) * rows + r
			indices.append_array([a, b, a + 1, a + 1, b, b + 1])
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, points, colors, uvs, PackedInt32Array(), PackedFloat32Array(), texture.get_rid())
