extends Node2D
## Option B, baked (scratch only): the same cell as cell_proto.gd, drawn from pre-rendered layer
## textures (bake.py), to measure what a texture build costs. One texture per visible part-state.

const ORIGIN: Vector2 = Vector2(115.0, 365.0)
const DIR: String = "res://cage_design/bake/"
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
var man: Dictionary = {}
var tex: Dictionary = {}
var spec: Dictionary = {}


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	man = JSON.parse_string(FileAccess.open(DIR + "bake.json", FileAccess.READ).get_as_text())
	spec = JSON.parse_string(FileAccess.open("res://cage_design/cell_spec.json", FileAccess.READ).get_as_text())
	for k: String in man.keys():
		if k.begins_with("_"):
			continue
		var img: Image = Image.load_from_file(ProjectSettings.globalize_path(DIR + k + ".png"))
		tex[k] = ImageTexture.create_from_image(img)


func _process(_delta: float) -> void:
	if source != null and not is_equal_approx(float(source.get("opening")), opening):
		opening = float(source.get("opening"))


func _leaf_s(o: float) -> float:
	var a_end: float = float(spec["stage"]["a_end"])
	var a_frac: float = float(spec["stage"]["a_frac"])
	if o < a_end:
		return a_frac * o / a_end
	return a_frac + (1.0 - a_frac) * (o - a_end) / (1.0 - a_end)


func _put(k: String, dx: float = 0.0) -> void:
	var m: Dictionary = man[k]
	draw_texture_rect(tex[k], Rect2(Vector2(m["pos"][0] + dx, m["pos"][1]) - ORIGIN, Vector2(m["size"][0], m["size"][1])), false)


func _draw() -> void:
	var open: bool = opening > 0.001
	var eff: int = 2 if open else phase
	match layer:
		"back":
			_put("back_p0" if eff == 0 else "back_p1")
		"front":
			_put("front_static")
			_put("front_open" if open else ("front_p0" if eff == 0 else "front_p1"))
		"leaf":
			var dx: float = -float(spec["travel"]) * _leaf_s(opening)
			_put("leaf_body", dx)
			if open:
				_put("leaf_open", dx)
				var kf: Dictionary = spec["keeper_fall"]
				var t: float = clampf(opening / float(kf["span"]), 0.0, 1.0)
				var piv: Vector2 = Vector2(kf["pivot"][0], kf["pivot"][1]) - ORIGIN
				var off: Vector2 = Vector2(float(kf["end"][0]) * t, float(kf["end"][1]) * t * t)
				draw_set_transform(piv + off, deg_to_rad(float(kf["rot_deg"]) * t), Vector2.ONE)
				var m: Dictionary = man["keeper_fall"]
				draw_texture_rect(tex["keeper_fall"], Rect2(Vector2(m["pos"][0], m["pos"][1]) - ORIGIN - piv, Vector2(m["size"][0], m["size"][1])), false)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			else:
				_put("keeper_on")
			_put("bolt")
