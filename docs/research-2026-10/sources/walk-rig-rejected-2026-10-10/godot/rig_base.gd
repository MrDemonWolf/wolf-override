class_name RigBase
extends Node2D
## Shared cut-out rig helpers: part loading, bone hierarchy and two-bone IK.
## Units inside a rig are D=4 cell px (4 per world px); the root's scale sets the screen size.

const D4: float = 4.0

var parts: Dictionary = {}      # name -> {pts: {k: Vector2}, size}
var bones: Dictionary = {}      # name -> Node2D (origin at the part's pivot)
var sprites: Dictionary = {}    # name -> Sprite2D
var abs_rot: Dictionary = {}    # name -> absolute rotation in rig space
var world_x: float = 0.0        # world position of the rig's ground anchor, in world px
var debug_points: Array = []


func load_rig(dir: String) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("rig.json")))
	for name: String in data["parts"].keys():
		var p: Dictionary = data["parts"][name]
		var pts: Dictionary = {}
		for k: String in p["pts"].keys():
			pts[k] = Vector2(p["pts"][k][0], p["pts"][k][1])
		parts[name] = {"pts": pts, "file": dir.path_join(p["file"])}


static func load_texture(path: String) -> Texture2D:
	var img: Image = Image.load_from_file(path)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Creates a bone node (pivot origin) under parent with its sprite drawn at z.
func make_bone(name: String, parent: Node2D, z: int, tint: Color = Color.WHITE) -> Node2D:
	var bone: Node2D = Node2D.new()
	bone.name = name
	parent.add_child(bone)
	var spr: Sprite2D = Sprite2D.new()
	spr.name = name + "_sprite"
	spr.texture = load_texture(parts[name]["file"])
	spr.centered = false
	spr.offset = -pt(name, "pivot")
	spr.z_index = z
	spr.modulate = tint
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	bone.add_child(spr)
	bones[name] = bone
	sprites[name] = spr
	abs_rot[name] = 0.0
	return bone


func pt(name: String, key: String) -> Vector2:
	return parts[name]["pts"][key]


## Vector from a part's pivot to one of its points, in its unrotated image space.
func rest_vec(name: String, key: String) -> Vector2:
	return pt(name, key) - pt(name, "pivot")


func bone_len(name: String, key: String = "end") -> float:
	return rest_vec(name, key).length()


## Sets the absolute rotation (rig space) of a bone whose parent has absolute rotation parent_abs.
func set_abs(name: String, rot: float, parent_abs: float) -> void:
	bones[name].rotation = rot - parent_abs
	abs_rot[name] = rot


## Absolute rotation that points the part's pivot->key vector along dir.
func aim_rot(name: String, key: String, dir: Vector2) -> float:
	return dir.angle() - rest_vec(name, key).angle()


## Two-bone IK. Returns the middle joint. bend > 0 puts the joint on the left of root->target
## (screen space, y down) when looking from root to target.
static func ik2(root: Vector2, target: Vector2, l1: float, l2: float, bend: float) -> Vector2:
	var d: Vector2 = target - root
	var dist: float = clampf(d.length(), absf(l1 - l2) + 0.001, l1 + l2 - 0.001)
	var dir: Vector2 = d.normalized() if d.length() > 0.0001 else Vector2.DOWN
	var a: float = (l1 * l1 - l2 * l2 + dist * dist) / (2.0 * dist)
	var h: float = sqrt(maxf(l1 * l1 - a * a, 0.0))
	var perp: Vector2 = Vector2(dir.y, -dir.x) * signf(bend)
	return root + dir * a + perp * h


## Highest root height (most negative y) at horizontal offset dx so a chain of reach r still touches.
static func max_height(dx: float, reach: float) -> float:
	return sqrt(maxf(reach * reach - dx * dx, 0.0))


static func smooth(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)
