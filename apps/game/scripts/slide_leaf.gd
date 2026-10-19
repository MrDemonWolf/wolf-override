class_name SlideLeaf
extends DoorLeaf
## A flat painted door leaf drawn in its own plane in a room's camera: the Service Junction exit's power
## sliding leaf (the whole piece junction-exit-leaf of the approved art set, 2026-10-16: the leaf flat
## and face-on as seen from the room, its leading edge on the right). The room places it with
## [member place], a Callable (along: float, h: float) -> Vector2 that gives the world px of the point
## [code]along[/code] metres from the leaf's leading edge toward its tail and [code]h[/code] metres up,
## for the leaf's current position; the room calls queue_redraw() when that changes. The mesh is a grid
## of COLUMNS columns across the leaf (its [member DoorLeaf.open] is unused: the room's placer reads its
## own open value), so the art's u is right under perspective at every column; it is
## toned like every door leaf (DoorKit.LEAF_TONE) unless its room gives it its own [member tone].

## Columns across the leaf: enough that the art stays straight while the plane recedes (the junction
## exit's 2.15 m leaf spans about 1.3 m of depth along its turned wall).
const COLUMNS: int = 6

## The leaf's size in metres (its art's width and height).
var size_m: Vector2
## (along, h) -> world px; see the class doc.
var place: Callable
## The colour its art is multiplied by (DoorKit.LEAF_TONE unless the room sets one).
var tone: Color = DoorKit.LEAF_TONE:
	set(value):
		tone = value
		queue_redraw()


## A leaf showing [param art], [param width_m] by [param height_m] metres, placed by [param placer].
func _init(art: Texture2D, width_m: float, height_m: float, placer: Callable) -> void:
	super("SlideLeaf", art)
	size_m = Vector2(width_m, height_m)
	place = placer


func _draw() -> void:
	var mesh: TriMesh = TriMesh.new()
	for column: int in COLUMNS + 1:
		# u 1 is the leading edge (along 0), on the art's right.
		var u: float = float(column) / float(COLUMNS)
		var along: float = (1.0 - u) * size_m.x
		for row: int in 2:
			var h: float = size_m.y * float(1 - row)
			mesh.add_vertex(place.call(along, h), Vector2(u, float(row)), tone)
	mesh.add_grid(0, COLUMNS + 1, 2)
	mesh.draw(get_canvas_item(), texture)
