extends Node2D
## Option B design prototype (scratch only, never part of the repository). Draws one layer of the
## containment cell from cell_spec.json, the same file the construction drawing is made from.
## layer: "back" (behind WOLF), "front" (fixed shell), "leaf" (sliding door). Positions in the spec are
## world px; this node sits at (115, 365).

const ORIGIN: Vector2 = Vector2(115.0, 365.0)
var layer: String = "front"
var phase: int = 0:
	set(value):
		phase = value
		queue_redraw()
var opening: float = 0.0:
	set(value):
		opening = clampf(value, 0.0, 1.0)
		queue_redraw()
var source: Node = null
var shutter: bool = false
var prims: Array = []
var travel: float = 81.0
var kf: Dictionary = {}
var stage: Dictionary = {}
var font: Font = preload("res://assets/fonts/Roboto-Variable.ttf")


func _ready() -> void:
	var f: FileAccess = FileAccess.open("res://cage_design/cell_spec.json", FileAccess.READ)
	var spec: Dictionary = JSON.parse_string(f.get_as_text())
	travel = float(spec["travel"])
	kf = spec["keeper_fall"]
	stage = spec["stage"]
	for p: Dictionary in spec["prims"]:
		if p["layer"] == layer:
			prims.append(p)
	queue_redraw()


func _process(_delta: float) -> void:
	if source != null and not is_equal_approx(float(source.get("opening")), opening):
		opening = float(source.get("opening"))


func _shown(cond: String) -> bool:
	var eff: int = 2 if opening > 0.001 else phase
	match cond:
		"always": return true
		"closed": return opening <= 0.001
		"open": return opening > 0.001
		"p0": return eff == 0
		"p1": return eff == 1
		"p2": return eff == 2
		"p_ge1": return eff >= 1
	return true


func _xf(pt: Vector2, group: String) -> Vector2:
	var q: Vector2 = pt
	if group == "leaf":
		q.x -= travel * leaf_s(opening)
	elif group == "keeper_fall":
		var t: float = clampf(opening / float(kf["span"]), 0.0, 1.0)
		var piv: Vector2 = Vector2(kf["pivot"][0], kf["pivot"][1])
		q = piv + (q - piv).rotated(deg_to_rad(float(kf["rot_deg"]) * t)) + Vector2(float(kf["end"][0]) * t, float(kf["end"][1]) * t * t)
	return q - ORIGIN


## Stage A (opening 0..a_end): the keeper tears out and the leaf only shifts a_frac of its travel.
## Stage B: the leaf runs the rest of the way along its track.
func leaf_s(o: float) -> float:
	var a_end: float = float(stage["a_end"])
	var a_frac: float = float(stage["a_frac"])
	if o < a_end:
		return a_frac * o / a_end
	return a_frac + (1.0 - a_frac) * (o - a_end) / (1.0 - a_end)


func _col(p: Dictionary) -> Color:
	var c: Color = Color(p["c"])
	c.a = float(p["a"])
	return c


func _draw() -> void:
	for p: Dictionary in prims:
		if not _shown(p["cond"]):
			continue
		var g: String = p["g"]
		var col: Color = _col(p)
		match p["k"]:
			"rect":
				var r: Array = p["r"]
				var a: Vector2 = _xf(Vector2(r[0], r[1]), g)
				draw_rect(Rect2(a, Vector2(r[2], r[3])), col)
			"poly":
				var pts: PackedVector2Array = PackedVector2Array()
				for q: Array in p["pts"]:
					pts.append(_xf(Vector2(q[0], q[1]), g))
				draw_colored_polygon(pts, col)
			"gpoly":
				var gp: PackedVector2Array = PackedVector2Array()
				var gc: PackedColorArray = PackedColorArray()
				for i: int in range(p["pts"].size()):
					gp.append(_xf(Vector2(p["pts"][i][0], p["pts"][i][1]), g))
					var cc: Color = Color(p["cols"][i])
					cc.a *= float(p["a"])
					gc.append(cc)
				if p.get("fan", false):
					for i: int in range(1, gp.size() - 1):
						draw_polygon(PackedVector2Array([gp[0], gp[i], gp[i + 1]]), PackedColorArray([gc[0], gc[i], gc[i + 1]]))
				else:
					draw_polygon(gp, gc)
			"line":
				draw_line(_xf(Vector2(p["p"][0][0], p["p"][0][1]), g), _xf(Vector2(p["p"][1][0], p["p"][1][1]), g), col, float(p["w"]))
			"circle":
				draw_circle(_xf(Vector2(p["ctr"][0], p["ctr"][1]), g), float(p["rad"]), col)
			"ellipse":
				var e: PackedVector2Array = PackedVector2Array()
				var c0: Vector2 = Vector2(p["ctr"][0], p["ctr"][1])
				for i: int in range(32):
					var ang: float = TAU * i / 32.0
					e.append(c0 + Vector2(cos(ang) * float(p["rad"][0]), sin(ang) * float(p["rad"][1])))
				var cr: Array = p["clipr"]
				var box: PackedVector2Array = PackedVector2Array([Vector2(cr[0], cr[1]), Vector2(cr[2], cr[1]), Vector2(cr[2], cr[3]), Vector2(cr[0], cr[3])])
				for piece: PackedVector2Array in Geometry2D.intersect_polygons(e, box):
					var moved: PackedVector2Array = PackedVector2Array()
					for q: Vector2 in piece:
						moved.append(_xf(q, g))
					draw_colored_polygon(moved, col)
			"text":
				# Rasterise large and scale down so the stencil stays crisp under the camera zoom.
				var cap: float = float(p["cap"])
				var size: int = 64
				var s: float = cap / (0.711 * size)
				var at: Vector2 = _xf(Vector2(p["pos"][0], p["pos"][1]), g)
				draw_set_transform(at, 0.0, Vector2(s, s))
				draw_string(font, Vector2.ZERO, p["s"], HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
