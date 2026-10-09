class_name FxPresets
extends RefCounted
## Three reusable CPUParticles2D configurations (they run on every renderer, including GL
## Compatibility): a spark shower, a dust burst and a steam column. Bursts are one-shot and fire
## through Impact.burst(); steam toggles emitting with the state that drives it.

const SPARK_CYAN: Color = Color("#8be3ff")
const SPARK_AMBER: Color = Color("#f3ae4b")
const DUST: Color = Color("#c9b9a0")
const STEAM: Color = Color("#bfe8ff")


static func sparks(color: Color = SPARK_CYAN) -> CPUParticles2D:
	var particles: CPUParticles2D = _one_shot("Sparks", 24, 0.45)
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 70.0
	particles.initial_velocity_min = 180.0
	particles.initial_velocity_max = 320.0
	particles.gravity = Vector2(0.0, 600.0)
	particles.damping_min = 40.0
	particles.damping_max = 40.0
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.0
	particles.color = color
	particles.color_ramp = _fade_ramp()
	particles.texture = _dot_texture(8)
	return particles


static func dust_burst() -> CPUParticles2D:
	var particles: CPUParticles2D = _one_shot("Dust", 16, 0.6)
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 85.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 90.0
	particles.gravity = Vector2(0.0, -20.0)
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 9.0
	particles.color = Color(DUST, 0.5)
	particles.color_ramp = _fade_ramp()
	particles.texture = _dot_texture(16)
	return particles


## Continuous; the caller sets emitting from real state and may scale amount with pressure.
static func steam() -> CPUParticles2D:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = "Steam"
	particles.emitting = false
	particles.amount = 40
	particles.lifetime = 1.2
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 12.0
	particles.initial_velocity_min = 120.0
	particles.initial_velocity_max = 180.0
	particles.gravity = Vector2(0.0, -60.0)
	particles.scale_amount_min = 6.0
	particles.scale_amount_max = 10.0
	var growth: Curve = Curve.new()
	growth.add_point(Vector2(0.0, 0.35))
	growth.add_point(Vector2(1.0, 1.0))
	particles.scale_amount_curve = growth
	particles.color = Color(STEAM, 0.35)
	particles.color_ramp = _fade_ramp()
	particles.texture = _dot_texture(16)
	return particles


static func _one_shot(particles_name: String, amount: int, lifetime: float) -> CPUParticles2D:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = particles_name
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = amount
	particles.lifetime = lifetime
	return particles


static func _fade_ramp() -> Gradient:
	var ramp: Gradient = Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	ramp.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
	return ramp


static func _dot_texture(size: int) -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1.0, 1.0, 1.0, 0.5), Color(1.0, 1.0, 1.0, 0.0)])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = size
	texture.height = size
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture
