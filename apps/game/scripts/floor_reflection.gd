class_name FloorReflection
extends Sprite2D
## A mirrored, squashed copy of a sprite below its feet, fading with distance, plus a soft contact
## shadow, so actors and props sit on the wet painted floor instead of hovering over it.
## It lives beside its source under the same parent and mirrors the source every frame.

const SQUASH: float = 0.55
## Drawn above the backdrop and haze, below every prop and actor.
const Z_FLOOR: int = -2
const SHADER: Shader = preload("res://assets/shaders/floor_reflection.gdshader")

var source: Sprite2D
## The contact line in the parent's space, taken from the source's resting bottom edge.
var floor_y: float = 0.0
var shadow: Sprite2D
var enabled: bool = true:
	set(value):
		enabled = value
		set_process(enabled)
		visible = enabled and source != null and source.visible
		if shadow != null:
			shadow.visible = visible


## Adds a reflection and shadow for [param target], which must already be in the tree.
static func attach(target: Sprite2D, strength: float = 0.32) -> FloorReflection:
	var reflection: FloorReflection = FloorReflection.new()
	reflection.name = target.name + "Reflection"
	reflection.source = target
	reflection.z_as_relative = false
	reflection.z_index = Z_FLOOR
	reflection.texture = target.texture
	reflection.texture_filter = target.texture_filter
	reflection.region_enabled = target.region_enabled
	reflection.region_rect = target.region_rect
	reflection.flip_v = true
	var half_height: float = _half_height(target)
	reflection.floor_y = target.position.y + half_height * target.scale.y
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("strength", strength)
	material.set_shader_parameter("wobble_px", 1.2 / maxf(absf(target.scale.y), 0.001))
	if target.region_enabled and target.texture != null:
		var texture_height: float = float(target.texture.get_height())
		material.set_shader_parameter("uv_span", Vector2(target.region_rect.position.y, target.region_rect.end.y) / texture_height)
	reflection.material = material
	reflection.shadow = _make_shadow(target.name, _half_width(target) * target.scale.x * 1.7)
	reflection.shadow.position = Vector2(target.position.x, reflection.floor_y)
	target.add_sibling(reflection.shadow)
	target.add_sibling(reflection)
	reflection._mirror()
	return reflection


func _process(_delta: float) -> void:
	_mirror()


func _mirror() -> void:
	if source == null:
		return
	visible = enabled and source.visible
	shadow.visible = visible
	if not visible:
		return
	position = Vector2(source.position.x, floor_y + (floor_y - source.position.y) * SQUASH)
	scale = Vector2(source.scale.x, source.scale.y * SQUASH)
	rotation = -source.rotation
	flip_h = source.flip_h
	modulate = source.modulate
	shadow.position = Vector2(source.position.x, floor_y)
	shadow.modulate.a = source.modulate.a


static func _half_height(sprite: Sprite2D) -> float:
	if sprite.region_enabled:
		return sprite.region_rect.size.y * 0.5
	return float(sprite.texture.get_height()) * 0.5 if sprite.texture != null else 0.0


static func _half_width(sprite: Sprite2D) -> float:
	if sprite.region_enabled:
		return sprite.region_rect.size.x * 0.5
	return float(sprite.texture.get_width()) * 0.5 if sprite.texture != null else 0.0


static func _make_shadow(owner_name: String, width: float) -> Sprite2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([Color(0.0, 0.0, 0.0, 0.5), Color(0.0, 0.0, 0.0, 0.22), Color(0.0, 0.0, 0.0, 0.0)])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 64
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	var shadow: Sprite2D = Sprite2D.new()
	shadow.name = owner_name + "Shadow"
	shadow.texture = texture
	shadow.z_as_relative = false
	shadow.z_index = Z_FLOOR
	shadow.scale = Vector2(maxf(width, 24.0) / 64.0, 12.0 / 64.0)
	return shadow
