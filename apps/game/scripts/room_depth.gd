class_name RoomDepth
extends Node2D
## A room built from three painted plates that share one 16:9 frame, plus the light every room
## shares, all with built-in nodes:
## - far: the back wall and floor, a Parallax2D that lags the camera, with additive glows and
##   drifting light shafts over its painted lamps, procedurally drawn lockdown beacons, wall haze
##   and dust;
## - mid: the play plane, drawn 1:1 with the room so its painted walkway is the floor (y 440) the
##   actors and stations stand on;
## - near: the plate's edge pieces only (a left strip and the same strip mirrored on the right),
##   drawn over the actors and scrolling faster than the floor.
## Source pixels are never edited. Main switches the depth pass with [member effects_enabled]: off,
## every plate moves with the floor and the near pieces, glows, haze and dust are hidden.

const ROOM_WIDTH: float = 960.0
const FLOOR_Y: float = 440.0
const BACKDROP_SCROLL: Vector2 = Vector2(0.9, 1.0)
const NEAR_SCROLL: Vector2 = Vector2(1.15, 1.0)
const Z_BACKDROP: int = -4
const Z_MID: int = -3
## Far dust shares the backdrop's depth and is added after it, so it drifts over the far wall but
## behind the mid plate's pillars and pipes.
const Z_ATMOSPHERE: int = -4
const Z_NEAR: int = 3
## The near edge strips are anchored at least this far past the room edges so their outer edges
## stay off screen through every framing: Parallax2D shifts a layer by (camera x - 480) *
## (1 - scroll), which at 1.15 is up to 19 px at play (zoom 1.35), 32 px in the opening (zoom 1.8)
## and 26 px at the chapter-close shot (zoom 1.55), plus up to 10 px of camera shake.
const NEAR_OVERHANG: float = 56.0
## Mirrored slivers of the mid plate past each room edge and below its bottom, so camera shake at
## the end of the camera's travel (or under the touch framing, whose view ends at the plate's
## bottom) shows a continuation of the plate instead of its cut edge. The bottom one matters where
## the floor is painted on the mid plate (the junction); elsewhere that strip is transparent.
const MID_BLEED: float = 16.0
const FAR_DUST_COUNT: int = 30
const NEAR_DUST_COUNT: int = 12
const GLOW_SIZE: Vector2 = Vector2(250.0, 96.0)
const SHAFT_SIZE: Vector2 = Vector2(54.0, 240.0)

## The far plate: back wall, painted lamps and wet floor (opaque).
@export var painting: Texture2D
## The play plane: pillars, pipes and machines on transparency.
@export var mid_painting: Texture2D
## Foreground pieces on transparency; only [member near_strip_width] source pixels from its left
## edge are used, on both sides of the room.
@export var near_painting: Texture2D
## The source row where the mid plate's painted walkway meets the floor; it is drawn at FLOOR_Y.
@export var walkway_y: float = 777.0
## How far the far plate sits below the mid plate, so its painted ceiling lamps stay in the play view.
@export var far_drop: float = 0.0
@export var near_strip_width: float = 512.0
## How far past each room edge the near strips are anchored (at least NEAR_OVERHANG). A room whose
## painted pipe column is wider than the corridor's (57 px) anchors it further out by the
## difference, so the column at each end of the play view only grazes an engineer standing at the
## 40 / 920 clamp.
@export var near_overhang: float = NEAR_OVERHANG
@export var base_color: Color = Color("#091533")
## Ceiling lamp centres as fractions of the far plate, so the glows ride on its parallax.
@export var lamps: PackedVector2Array = PackedVector2Array()
@export var lamp_color: Color = Color("#9fe4ff")
## Lamps (by index into [member lamps]) that also cast a drifting light shaft.
@export var shaft_lamps: PackedInt32Array = PackedInt32Array()
## Lockdown beacons as fractions of the far plate: a small drawn lamp housing with a pulsing glow.
@export var warning_lamps: PackedVector2Array = PackedVector2Array()
@export var warning_color: Color = Color("#ff4a46")

var effects_enabled: bool = true:
	set(value):
		effects_enabled = value
		if is_node_ready():
			_apply()

var backdrop_layer: Parallax2D
var backdrop: Sprite2D
var mid_layer: Node2D
var near_layer: Parallax2D
var lamp_glows: Array[Sprite2D] = []
var beacons: Array[Node2D] = []
var haze: Sprite2D
var far_dust: CPUParticles2D
var near_dust: CPUParticles2D
var _built: Array[Node] = []
var _tweens: Array[Tween] = []


## A lockdown beacon: a dark housing on a short bracket with a red lens.
class Beacon:
	extends Node2D
	var lens: Color = Color("#ff4a46")

	func _draw() -> void:
		draw_line(Vector2(0.0, -9.0), Vector2(0.0, -4.0), Color("#1b2630"), 2.0)
		draw_rect(Rect2(-7.0, -4.0, 14.0, 9.0), Color("#141c24"))
		draw_rect(Rect2(-7.0, -4.0, 14.0, 9.0), Color("#3e4f5a"), false, 1.0)
		draw_rect(Rect2(-5.0, -2.0, 10.0, 5.0), lens)


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
	beacons.clear()
	backdrop_layer = _add_parallax("Backdrop", BACKDROP_SCROLL, Z_BACKDROP)
	backdrop = _plate("Painting", painting)
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
		var beacon: Beacon = Beacon.new()
		beacon.name = "Beacon%d" % index
		beacon.lens = warning_color
		beacon.z_index = 1
		backdrop_layer.add_child(beacon)
		beacons.append(beacon)
		var glow: Sprite2D = make_glow(warning_color, Vector2(90.0, 90.0), 0.4, additive)
		glow.name = "WarningGlow%d" % index
		glow.z_index = 2
		backdrop_layer.add_child(glow)
		lamp_glows.append(glow)
		_pulse(glow, 0.4, 0.5 * index)
	mid_layer = Node2D.new()
	mid_layer.name = "MidPlate"
	mid_layer.z_as_relative = false
	mid_layer.z_index = Z_MID
	add_child(mid_layer)
	_built.append(mid_layer)
	mid_layer.add_child(_plate("Painting", mid_painting))
	if mid_painting != null:
		var bleed_source: float = MID_BLEED / _plate_scale()
		var width: float = float(mid_painting.get_width())
		mid_layer.add_child(_plate("LeftBleed", mid_painting, Rect2(0.0, 0.0, bleed_source, mid_painting.get_height()), true))
		mid_layer.add_child(_plate("RightBleed", mid_painting, Rect2(width - bleed_source, 0.0, bleed_source, mid_painting.get_height()), true))
		# The bottom rows flipped down, running past both sides (mirror repeat) to fill the corners.
		var bottom_bleed: Sprite2D = _plate("BottomBleed", mid_painting, Rect2(-bleed_source, mid_painting.get_height() - bleed_source, width + bleed_source * 2.0, bleed_source))
		bottom_bleed.flip_v = true
		bottom_bleed.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
		mid_layer.add_child(bottom_bleed)
	far_dust = _make_dust("FarDust", FAR_DUST_COUNT, 0.18, 0.4, Z_ATMOSPHERE)
	near_layer = _add_parallax("Near", NEAR_SCROLL, Z_NEAR)
	if near_painting != null:
		var strip: Rect2 = Rect2(0.0, 0.0, minf(near_strip_width, near_painting.get_width()), near_painting.get_height())
		near_layer.add_child(_plate("LeftEdge", near_painting, strip))
		near_layer.add_child(_plate("RightEdge", near_painting, strip, true))
	near_dust = _make_dust("NearDust", NEAR_DUST_COUNT, 0.35, 0.65, Z_NEAR)
	_apply()


func _apply() -> void:
	var on: bool = effects_enabled
	var scale_factor: float = _plate_scale()
	var mid_top: float = FLOOR_Y - walkway_y * scale_factor
	var far: Rect2 = far_rect()
	backdrop_layer.scroll_scale = BACKDROP_SCROLL if on else Vector2.ONE
	backdrop.position = far.position
	backdrop.scale = Vector2.ONE * scale_factor
	haze.visible = on
	haze.position = Vector2(far.position.x, far.position.y + far.size.y * 0.29)
	haze.scale = Vector2(far.size.x, far.size.y * 0.56) / haze.texture.get_size()
	for index: int in lamps.size():
		var glow: Sprite2D = backdrop_layer.get_node("LampGlow%d" % index) as Sprite2D
		glow.position = far.position + lamps[index] * far.size
		var shaft: Sprite2D = backdrop_layer.get_node_or_null("LightShaft%d" % index) as Sprite2D
		if shaft != null:
			shaft.position = glow.position + Vector2(0.0, 6.0)
	for index: int in warning_lamps.size():
		var at: Vector2 = far.position + warning_lamps[index] * far.size
		beacons[index].position = at
		(backdrop_layer.get_node("WarningGlow%d" % index) as Sprite2D).position = at
	for glow: Sprite2D in lamp_glows:
		glow.visible = on
	var mid: Sprite2D = mid_layer.get_node("Painting") as Sprite2D
	mid.position = Vector2(0.0, mid_top)
	mid.scale = Vector2.ONE * scale_factor
	var left_bleed: Sprite2D = mid_layer.get_node_or_null("LeftBleed") as Sprite2D
	if left_bleed != null:
		var right_bleed: Sprite2D = mid_layer.get_node("RightBleed") as Sprite2D
		left_bleed.scale = Vector2.ONE * scale_factor
		left_bleed.position = Vector2(-MID_BLEED, mid_top)
		right_bleed.scale = Vector2.ONE * scale_factor
		right_bleed.position = Vector2(ROOM_WIDTH, mid_top)
		var bottom_bleed: Sprite2D = mid_layer.get_node("BottomBleed") as Sprite2D
		bottom_bleed.scale = Vector2.ONE * scale_factor
		bottom_bleed.position = Vector2(-MID_BLEED, mid_top + mid.texture.get_height() * scale_factor)
	near_layer.visible = on
	var left_edge: Sprite2D = near_layer.get_node_or_null("LeftEdge") as Sprite2D
	if left_edge != null:
		var right_edge: Sprite2D = near_layer.get_node("RightEdge") as Sprite2D
		left_edge.scale = Vector2.ONE * scale_factor
		left_edge.position = Vector2(-near_overhang, mid_top)
		right_edge.scale = left_edge.scale
		right_edge.position = Vector2(ROOM_WIDTH + near_overhang - right_edge.region_rect.size.x * scale_factor, mid_top)
	for dust: CPUParticles2D in [far_dust, near_dust]:
		dust.visible = on
		dust.emitting = on
	queue_redraw()


func _draw() -> void:
	# The opaque far plate covers every framing (room_depth_test checks it), so the base fill only
	# shows for a room built without one.
	if painting == null:
		draw_rect(Rect2(-60.0, 0.0, ROOM_WIDTH + 120.0, 680.0), base_color)


## Where the far plate is drawn, in the backdrop layer's space (it lines up with the room when the
## camera is centred on the room).
func far_rect() -> Rect2:
	var scale_factor: float = _plate_scale()
	var size: Vector2 = painting.get_size() * scale_factor if painting != null else Vector2(ROOM_WIDTH, 540.0)
	return Rect2(Vector2(0.0, FLOOR_Y - walkway_y * scale_factor + far_drop), size)


## Every plate is painted at the same size and drawn exactly as wide as the room.
func _plate_scale() -> float:
	var reference: Texture2D = mid_painting if mid_painting != null else painting
	return ROOM_WIDTH / float(reference.get_width()) if reference != null else 1.0


func _plate(plate_name: String, texture: Texture2D, region: Rect2 = Rect2(), mirrored: bool = false) -> Sprite2D:
	var plate: Sprite2D = Sprite2D.new()
	plate.name = plate_name
	plate.centered = false
	plate.texture = texture
	plate.region_enabled = region.has_area()
	plate.region_rect = region
	plate.flip_h = mirrored
	return plate


func _add_parallax(layer_name: String, scroll: Vector2, z: int) -> Parallax2D:
	var layer: Parallax2D = Parallax2D.new()
	layer.name = layer_name
	layer.scroll_scale = scroll
	layer.z_as_relative = false
	layer.z_index = z
	add_child(layer)
	_built.append(layer)
	return layer


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


## A station prop cut to [param region] of its own image (its painted outline, so the floor
## reflection mirrors from its real base), [param prop_scale]d, centred on [param center_x] with its
## base on [param base_y].
static func make_prop(prop_name: String, texture: Texture2D, region: Rect2, prop_scale: float, center_x: float, base_y: float = FLOOR_Y) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = prop_name
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.scale = Vector2.ONE * prop_scale
	sprite.position = Vector2(center_x, base_y - region.size.y * prop_scale * 0.5)
	return sprite


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
