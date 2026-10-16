class_name FxKit
extends RefCounted
## The generated textures and the material the rooms' lights, shadows and particles share: one
## GradientTexture2D per distinct gradient, size and fill, one Gradient per particle ramp, and one
## additive CanvasItemMaterial, made the first time they are asked for and handed to every caller
## after that, instead of a new copy per sprite (the same gradients give the same pixels).
## Main owns the kit: it opens it as it enters the tree, before any room builds, and closes it as it
## leaves, which lets go of everything cached. The kit is reachable from the rooms' static helpers only
## while it is open, so no Resource cache outlives the scene. With no kit open (a room or prop built on
## its own in a test) every call makes a fresh resource, as before. What a caller gets back is shared,
## so nothing writes to it after it is made: callers tint through modulate and the particles' own
## colour (fx_kit_test checks it).

## The open kit; a second Main entering while one is up builds from the first one's cache.
static var _current: FxKit

var _cache: Dictionary = {}


## Makes [param kit] the one every call shares from, unless another is already open.
static func open(kit: FxKit) -> void:
	if _current == null:
		_current = kit


## Lets go of everything [param kit] holds and, if it is the open one, closes it.
static func close(kit: FxKit) -> void:
	kit._cache.clear()
	if _current == kit:
		_current = null


## How many shared resources the open kit holds (0 with none); fx_kit_test reads it.
static func cached_count() -> int:
	return _current._cache.size() if _current != null else 0


## A [param size] px square texture of [param colors] at [param offsets], from the centre out to the
## middle of an edge ([param fill] radial for a disc, square for a soft-edged rectangle). A
## [param height] above 0 makes it [param size] px wide by that many px tall instead: the fill runs in
## UV space, so that gives a soft ellipse (the relief jet's streak, FxPresets.relief_jet).
static func radial(size: int, offsets: Array[float], colors: Array[Color], fill: GradientTexture2D.Fill = GradientTexture2D.FILL_RADIAL, height: int = 0) -> GradientTexture2D:
	# 0 means square; the key holds the resolved height so a square asked for both ways is one texture.
	var tall: int = height if height > 0 else size
	var key: Array = [&"radial", size, tall, offsets, colors, fill]
	var texture: GradientTexture2D = _find(key) as GradientTexture2D
	if texture == null:
		texture = GradientTexture2D.new()
		texture.gradient = _new_ramp(offsets, colors)
		texture.width = size
		texture.height = tall
		texture.fill = fill
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(0.5, 0.0)
		_keep(key, texture)
	return texture


## A thin band of [param colors] at [param offsets], top to bottom (left to right when
## [param horizontal]): [param length] px along the gradient by [param thickness] px across, 64x4 by
## default, which is stretched to size where it is drawn. A particle draws its texture at its own size,
## so the particle presets ask for the exact small sizes they need (FxPresets' 2x8 streak, 3x3 chip).
static func linear(offsets: Array[float], colors: Array[Color], horizontal: bool = false, length: int = 64, thickness: int = 4) -> GradientTexture2D:
	var key: Array = [&"linear", offsets, colors, horizontal, length, thickness]
	var texture: GradientTexture2D = _find(key) as GradientTexture2D
	if texture == null:
		texture = GradientTexture2D.new()
		texture.gradient = _new_ramp(offsets, colors)
		texture.width = length if horizontal else thickness
		texture.height = thickness if horizontal else length
		texture.fill_from = Vector2(0.0, 0.0)
		texture.fill_to = Vector2(1.0, 0.0) if horizontal else Vector2(0.0, 1.0)
		_keep(key, texture)
	return texture


## A colour ramp (a particle's colour over its life).
static func ramp(offsets: Array[float], colors: Array[Color]) -> Gradient:
	var key: Array = [&"ramp", offsets, colors]
	var gradient: Gradient = _find(key) as Gradient
	if gradient == null:
		gradient = _new_ramp(offsets, colors)
		_keep(key, gradient)
	return gradient


## The additive blend every glow and light shaft draws with.
static func additive() -> CanvasItemMaterial:
	var key: Array = [&"additive"]
	var material: CanvasItemMaterial = _find(key) as CanvasItemMaterial
	if material == null:
		material = CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_keep(key, material)
	return material


static func _new_ramp(offsets: Array[float], colors: Array[Color]) -> Gradient:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array(offsets)
	gradient.colors = PackedColorArray(colors)
	return gradient


static func _find(key: Array) -> Resource:
	return _current._cache.get(key) as Resource if _current != null else null


static func _keep(key: Array, resource: Resource) -> void:
	if _current != null:
		_current._cache[key] = resource
