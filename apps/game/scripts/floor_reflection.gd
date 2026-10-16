class_name FloorReflection
extends Sprite2D
## A mirrored, squashed copy of a sprite below its feet, fading with distance, plus a soft contact
## shadow, so actors and props sit on the wet painted floor instead of hovering over it.
## It lives beside its source under the same parent and mirrors the source every frame while its
## room is on screen (active), its image too, so a source that changes its texture or cut (the
## engineer's collapse) is mirrored as drawn.

const SQUASH: float = 0.55
## Drawn above the backdrop and haze, below every prop and actor.
const Z_FLOOR: int = -2
const SHADER: Shader = preload("res://assets/shaders/floor_reflection.gdshader")

var source: Sprite2D
## The contact line in the parent's space, taken from the source's resting bottom edge.
var floor_y: float = 0.0
var shadow: Sprite2D
## The shadow's resting width (its x scale), under the source's origin.
var shadow_rest_scale: float = 1.0
## When set (to > from), the shadow lies under this span of x in the parent's space instead, as long
## as it plus a little: a body lying on the floor (Main's knockdown) sets it; Vector2.ZERO is unset.
var shadow_span: Vector2 = Vector2.ZERO
var enabled: bool = true:
	set(value):
		enabled = value
		set_process(enabled and active)
		visible = enabled and source != null and source.visible
		if shadow != null:
			shadow.visible = visible
## False while its room is hidden: nothing of it shows, so it stops mirroring until the room is back.
var active: bool = true:
	set(value):
		if value == active:
			return
		active = value
		set_process(enabled and active)
		if enabled and active:
			_catch_up.call_deferred()
var _mirrored_frame: int = -1


## Adds a reflection and shadow for [param target], which must already be in the tree.
static func attach(target: Sprite2D, strength: float = 0.32) -> FloorReflection:
	var reflection: FloorReflection = FloorReflection.new()
	reflection.name = target.name + "Reflection"
	reflection.source = target
	reflection.z_as_relative = false
	reflection.z_index = Z_FLOOR
	reflection.texture_filter = target.texture_filter
	reflection.flip_v = true
	var half_height: float = _half_height(target)
	reflection.floor_y = target.position.y + half_height * target.scale.y
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("strength", strength)
	material.set_shader_parameter("lod_bias", lod_bias_of(target))
	reflection.material = material
	reflection._take_image()
	reflection.shadow = _make_shadow(target.name, _half_width(target) * target.scale.x * 1.7)
	reflection.shadow_rest_scale = reflection.shadow.scale.x
	reflection.shadow.position = Vector2(target.position.x, reflection.floor_y)
	target.add_sibling(reflection.shadow)
	target.add_sibling(reflection)
	reflection._mirror()
	return reflection


func _process(_delta: float) -> void:
	_mirrored_frame = Engine.get_process_frames()
	_mirror()


## Back on screen: mirrors the source as it stands once the frame's processing is done, unless this
## frame's _process already has.
func _catch_up() -> void:
	if _mirrored_frame != Engine.get_process_frames():
		_mirror()


func _mirror() -> void:
	if source == null:
		return
	visible = enabled and source.visible
	shadow.visible = visible
	if not visible:
		return
	if texture != source.texture or region_enabled != source.region_enabled or region_rect != source.region_rect:
		_take_image()
	position = Vector2(source.position.x, floor_y + (floor_y - source.position.y) * SQUASH)
	scale = Vector2(source.scale.x, source.scale.y * SQUASH)
	rotation = -source.rotation
	flip_h = source.flip_h
	# self_modulate too, so the reflection dims with WOLF as he passes behind the engineer.
	modulate = source.modulate * source.self_modulate
	if shadow_span.y > shadow_span.x:
		shadow.position = Vector2((shadow_span.x + shadow_span.y) * 0.5, floor_y)
		shadow.scale.x = (shadow_span.y - shadow_span.x + 6.0) / 64.0
	else:
		shadow.position = Vector2(source.position.x, floor_y)
		shadow.scale.x = shadow_rest_scale
	shadow.modulate.a = source.modulate.a


## Starts or stops [param reflections] mirroring, as their room shows or hides.
static func set_all_active(reflections: Array[FloorReflection], value: bool) -> void:
	for reflection: FloorReflection in reflections:
		reflection.active = value


## Copies the source's image and cut, and the shader's view of them (the cut's rows and the wobble,
## which is in source pixels).
func _take_image() -> void:
	texture = source.texture
	region_enabled = source.region_enabled
	region_rect = source.region_rect
	var shader_material: ShaderMaterial = material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("wobble_px", 1.2 / maxf(absf(source.scale.y), 0.001))
	if source.region_enabled and source.texture != null:
		var texture_height: float = float(source.texture.get_height())
		shader_material.set_shader_parameter("uv_span", Vector2(source.region_rect.position.y, source.region_rect.end.y) / texture_height)
	else:
		shader_material.set_shader_parameter("uv_span", Vector2(0.0, 1.0))


## The mipmap LOD bias a sprite samples with: its sharp_sprite material's lod_bias, or 0.0.
static func lod_bias_of(sprite: Sprite2D) -> float:
	var shader_material: ShaderMaterial = sprite.material as ShaderMaterial
	if shader_material == null:
		return 0.0
	var bias: Variant = shader_material.get_shader_parameter("lod_bias")
	return float(bias) if bias is float or bias is int else 0.0


static func _half_height(sprite: Sprite2D) -> float:
	if sprite.region_enabled:
		return sprite.region_rect.size.y * 0.5
	return float(sprite.texture.get_height()) * 0.5 if sprite.texture != null else 0.0


static func _half_width(sprite: Sprite2D) -> float:
	if sprite.region_enabled:
		return sprite.region_rect.size.x * 0.5
	return float(sprite.texture.get_width()) * 0.5 if sprite.texture != null else 0.0


static func _make_shadow(owner_name: String, width: float) -> Sprite2D:
	var shadow: Sprite2D = Sprite2D.new()
	shadow.name = owner_name + "Shadow"
	shadow.texture = FxKit.radial(64, [0.0, 0.45, 1.0], [Color(0.0, 0.0, 0.0, 0.5), Color(0.0, 0.0, 0.0, 0.22), Color(0.0, 0.0, 0.0, 0.0)])
	shadow.z_as_relative = false
	shadow.z_index = Z_FLOOR
	shadow.scale = Vector2(maxf(width, 24.0) / 64.0, 12.0 / 64.0)
	return shadow
