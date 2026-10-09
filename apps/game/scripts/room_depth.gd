class_name RoomDepth
extends Node2D
## Depth and lighting that every room shares, built over its existing painting with built-in nodes:
## a parallax backdrop drawn a little larger than the room, additive glows and drifting light shafts
## over the painted lamps, wall haze, dust motes and a near foreground that scrolls faster than the
## floor. Source pixels are never edited. A room passes its painting and lamp positions; Main switches
## the whole pass with [member effects_enabled].

const ROOM_RECT: Rect2 = Rect2(0.0, 60.0, 960.0, 540.0)
## The backdrop is drawn this much larger so its edges stay hidden while it lags the camera.
const BACKDROP_OVERSCAN: float = 1.06
const BACKDROP_SCROLL: Vector2 = Vector2(0.9, 1.0)
const MID_SCROLL: Vector2 = Vector2(0.95, 1.0)
const NEAR_SCROLL: Vector2 = Vector2(1.1, 1.0)
const Z_BACKDROP: int = -4
const Z_ATMOSPHERE: int = -3
const Z_NEAR: int = 3
const FAR_DUST_COUNT: int = 30
const NEAR_DUST_COUNT: int = 12
const GLOW_SIZE: Vector2 = Vector2(250.0, 96.0)
const SHAFT_SIZE: Vector2 = Vector2(54.0, 240.0)
const NEAR_DARK: Color = Color("#03070c")

@export var painting: Texture2D
@export var base_color: Color = Color("#091533")
## Ceiling lamp centres as fractions of the painting, so the glows ride on the parallax backdrop.
@export var lamps: PackedVector2Array = PackedVector2Array()
@export var lamp_color: Color = Color("#9fe4ff")
## Lamps (by index into [member lamps]) that also cast a drifting light shaft.
@export var shaft_lamps: PackedInt32Array = PackedInt32Array()
@export var warning_lamps: PackedVector2Array = PackedVector2Array()
@export var warning_color: Color = Color("#ff4a46")
## Trial plates: a mid plate that moves almost with the floor and a near plate drawn in front of the
## actors. Leave empty to draw the built-in near silhouettes instead.
@export var mid_painting: Texture2D
@export var near_painting: Texture2D
@export var near_region: Rect2 = Rect2()

var effects_enabled: bool = true:
	set(value):
		effects_enabled = value
		if is_node_ready():
			_apply()

var backdrop_layer: Parallax2D
var backdrop: Sprite2D
var mid_layer: Parallax2D
var near_layer: Parallax2D
var lamp_glows: Array[Sprite2D] = []
var haze: Sprite2D
var far_dust: CPUParticles2D
var near_dust: CPUParticles2D
var _built: Array[Node] = []
var _tweens: Array[Tween] = []


func _ready() -> void:
	# The base fill drawn here must sit under the backdrop whatever the owning room's own z-index is.
	z_as_relative = false
	z_index = Z_BACKDROP
	rebuild()


## Rebuilds every layer from the current exports; call after swapping plates at runtime.
func rebuild() -> void:
	for tween: Tween in _tweens:
		tween.kill()
	_tweens.clear()
	for node: Node in _built:
		remove_child(node)
		node.queue_free()
	_built.clear()
	lamp_glows.clear()
	backdrop_layer = _add_parallax("Backdrop", BACKDROP_SCROLL, Z_BACKDROP)
	backdrop = Sprite2D.new()
	backdrop.name = "Painting"
	backdrop.centered = false
	backdrop.texture = painting
	backdrop_layer.add_child(backdrop)
	haze = Sprite2D.new()
	haze.name = "Haze"
	haze.centered = false
	haze.z_index = 1
	haze.texture = _linear_texture([0.0, 0.62, 1.0], [Color(0.37, 0.54, 0.65, 0.0), Color(0.37, 0.54, 0.65, 0.14), Color(0.37, 0.54, 0.65, 0.0)])
	backdrop_layer.add_child(haze)
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for index: int in lamps.size():
		var glow: Sprite2D = make_glow(lamp_color, GLOW_SIZE, 0.5, additive)
		glow.name = "LampGlow%d" % index
		glow.z_index = 1
		backdrop_layer.add_child(glow)
		lamp_glows.append(glow)
		_flicker(glow, 0.5, 0.9 + 0.7 * index)
		if index in shaft_lamps:
			var shaft: Sprite2D = _make_shaft(additive)
			shaft.name = "LightShaft%d" % index
			backdrop_layer.add_child(shaft)
			lamp_glows.append(shaft)
			_drift(shaft, 0.6 * index)
	for index: int in warning_lamps.size():
		var glow: Sprite2D = make_glow(warning_color, Vector2(90.0, 90.0), 0.4, additive)
		glow.name = "WarningGlow%d" % index
		glow.z_index = 1
		backdrop_layer.add_child(glow)
		lamp_glows.append(glow)
		_pulse(glow, 0.4, 0.5 * index)
	if mid_painting != null:
		mid_layer = _add_parallax("MidPlate", MID_SCROLL, Z_ATMOSPHERE)
		var mid: Sprite2D = Sprite2D.new()
		mid.name = "Painting"
		mid.centered = false
		mid.texture = mid_painting
		mid_layer.add_child(mid)
	else:
		mid_layer = null
	far_dust = _make_dust("FarDust", FAR_DUST_COUNT, 0.18, 0.4, Z_ATMOSPHERE)
	near_layer = _add_parallax("Near", NEAR_SCROLL, Z_NEAR)
	if near_painting != null:
		var near: Sprite2D = Sprite2D.new()
		near.name = "Plate"
		near.centered = false
		near.texture = near_painting
		near.region_enabled = near_region.has_area()
		near.region_rect = near_region
		near_layer.add_child(near)
	else:
		_add_silhouettes()
	near_dust = _make_dust("NearDust", NEAR_DUST_COUNT, 0.35, 0.65, Z_NEAR)
	_apply()


func _apply() -> void:
	var on: bool = effects_enabled
	var rect: Rect2 = _backdrop_rect()
	backdrop_layer.scroll_scale = BACKDROP_SCROLL if on else Vector2.ONE
	backdrop.position = rect.position
	backdrop.scale = rect.size / painting.get_size() if painting != null else Vector2.ONE
	haze.visible = on
	haze.position = Vector2(rect.position.x, rect.position.y + rect.size.y * 0.29)
	haze.scale = Vector2(rect.size.x, rect.size.y * 0.56) / haze.texture.get_size()
	for index: int in lamps.size():
		var glow: Sprite2D = backdrop_layer.get_node("LampGlow%d" % index) as Sprite2D
		glow.position = rect.position + lamps[index] * rect.size
		var shaft: Sprite2D = backdrop_layer.get_node_or_null("LightShaft%d" % index) as Sprite2D
		if shaft != null:
			shaft.position = glow.position + Vector2(0.0, 6.0)
	for index: int in warning_lamps.size():
		(backdrop_layer.get_node("WarningGlow%d" % index) as Sprite2D).position = rect.position + warning_lamps[index] * rect.size
	for glow: Sprite2D in lamp_glows:
		glow.visible = on
	if mid_layer != null:
		mid_layer.visible = on
		mid_layer.scroll_scale = MID_SCROLL if on else Vector2.ONE
		var mid: Sprite2D = mid_layer.get_node("Painting") as Sprite2D
		mid.position = rect.position
		mid.scale = rect.size / mid_painting.get_size()
	near_layer.visible = on
	var plate: Sprite2D = near_layer.get_node_or_null("Plate") as Sprite2D
	if plate != null:
		plate.position = rect.position
		plate.scale = rect.size / near_painting.get_size()
	for dust: CPUParticles2D in [far_dust, near_dust]:
		dust.visible = on
		dust.emitting = on
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0.0, 0.0, 960.0, 680.0), base_color)


func _backdrop_rect() -> Rect2:
	if not effects_enabled:
		return ROOM_RECT
	var size: Vector2 = ROOM_RECT.size * BACKDROP_OVERSCAN
	return Rect2(ROOM_RECT.get_center() - size * 0.5, size)


func _add_parallax(layer_name: String, scroll: Vector2, z: int) -> Parallax2D:
	var layer: Parallax2D = Parallax2D.new()
	layer.name = layer_name
	layer.scroll_scale = scroll
	layer.z_as_relative = false
	layer.z_index = z
	add_child(layer)
	_built.append(layer)
	return layer


## Soft near-edge pillars and a floor-front shade, drawn when a room has no near plate.
func _add_silhouettes() -> void:
	var edge: GradientTexture2D = _linear_texture([0.0, 0.55, 1.0], [Color(NEAR_DARK, 0.96), Color(NEAR_DARK, 0.45), Color(NEAR_DARK, 0.0)], true)
	var left: Sprite2D = Sprite2D.new()
	left.name = "LeftPillar"
	left.centered = false
	left.texture = edge
	left.position = Vector2(-80.0, 0.0)
	left.scale = Vector2(112.0, 680.0) / edge.get_size()
	near_layer.add_child(left)
	var right: Sprite2D = Sprite2D.new()
	right.name = "RightPillar"
	right.centered = false
	right.texture = edge
	right.flip_h = true
	right.position = Vector2(928.0, 0.0)
	right.scale = left.scale
	near_layer.add_child(right)
	var front: Sprite2D = Sprite2D.new()
	front.name = "FloorFront"
	front.centered = false
	front.texture = _linear_texture([0.0, 1.0], [Color(NEAR_DARK, 0.0), Color(NEAR_DARK, 0.8)])
	front.position = Vector2(-80.0, 452.0)
	front.scale = Vector2(1120.0, 160.0) / front.texture.get_size()
	near_layer.add_child(front)


func _make_dust(dust_name: String, count: int, scale_min: float, scale_max: float, z: int) -> CPUParticles2D:
	var dust: CPUParticles2D = CPUParticles2D.new()
	dust.name = dust_name
	dust.z_as_relative = false
	dust.z_index = z
	dust.amount = count
	dust.lifetime = 14.0
	dust.preprocess = 14.0
	dust.position = Vector2(480.0, 300.0)
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(500.0, 150.0)
	dust.direction = Vector2(1.0, 0.0)
	dust.spread = 180.0
	dust.gravity = Vector2(0.0, -1.5)
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 8.0
	dust.scale_amount_min = scale_min
	dust.scale_amount_max = scale_max
	dust.color = Color(0.8, 0.93, 1.0, 0.55)
	var ramp: Gradient = Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	dust.color_ramp = ramp
	dust.texture = _radial_texture(16, [0.0, 0.5, 1.0], [Color.WHITE, Color(1, 1, 1, 0.4), Color(1, 1, 1, 0)])
	add_child(dust)
	_built.append(dust)
	return dust


## The lower half of a squashed radial gradient: a soft cone hanging from the lamp.
func _make_shaft(additive: CanvasItemMaterial) -> Sprite2D:
	var shaft: Sprite2D = Sprite2D.new()
	shaft.centered = false
	shaft.texture = _radial_texture(128, [0.0, 0.35, 1.0], [Color(lamp_color, 0.3), Color(lamp_color, 0.14), Color(lamp_color, 0.0)])
	shaft.region_enabled = true
	shaft.region_rect = Rect2(0.0, 64.0, 128.0, 64.0)
	shaft.offset = Vector2(-64.0, 0.0)
	shaft.scale = SHAFT_SIZE / shaft.region_rect.size
	shaft.material = additive
	shaft.z_index = 1
	shaft.skew = 0.04
	return shaft


## An additive radial glow; also used by rooms for their station status lights.
static func make_glow(color: Color, size: Vector2, alpha: float, material: CanvasItemMaterial = null) -> Sprite2D:
	var glow: Sprite2D = Sprite2D.new()
	glow.texture = _radial_texture(128, [0.0, 0.4, 1.0], [Color.WHITE, Color(1, 1, 1, 0.3), Color(1, 1, 1, 0)])
	glow.scale = size / glow.texture.get_size()
	glow.modulate = Color(color, alpha)
	if material == null:
		material = CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = material
	return glow


func _flicker(glow: Sprite2D, base: float, phase: float) -> void:
	var tween: Tween = _loop()
	tween.tween_interval(phase)
	tween.tween_property(glow, "modulate:a", base * 0.7, 0.06)
	tween.tween_property(glow, "modulate:a", base, 0.14)
	tween.tween_interval(2.3 + phase * 0.6)
	tween.tween_property(glow, "modulate:a", base * 0.86, 0.05)
	tween.tween_property(glow, "modulate:a", base, 0.4)


func _pulse(glow: Sprite2D, base: float, phase: float) -> void:
	var tween: Tween = _loop()
	tween.tween_interval(phase)
	tween.tween_property(glow, "modulate:a", base * 0.55, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(glow, "modulate:a", base, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _drift(shaft: Sprite2D, phase: float) -> void:
	var tween: Tween = _loop()
	tween.tween_interval(phase)
	tween.tween_property(shaft, "skew", 0.11, 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(shaft, "modulate:a", 0.75, 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(shaft, "skew", -0.04, 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(shaft, "modulate:a", 1.0, 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _loop() -> Tween:
	var tween: Tween = create_tween().set_loops()
	_tweens.append(tween)
	return tween


static func _gradient(offsets: Array[float], colors: Array[Color]) -> Gradient:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array(offsets)
	gradient.colors = PackedColorArray(colors)
	return gradient


static func _radial_texture(size: int, offsets: Array[float], colors: Array[Color]) -> GradientTexture2D:
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = _gradient(offsets, colors)
	texture.width = size
	texture.height = size
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture


static func _linear_texture(offsets: Array[float], colors: Array[Color], horizontal: bool = false) -> GradientTexture2D:
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = _gradient(offsets, colors)
	texture.width = 64 if horizontal else 4
	texture.height = 4 if horizontal else 64
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(1.0, 0.0) if horizontal else Vector2(0.0, 1.0)
	return texture
