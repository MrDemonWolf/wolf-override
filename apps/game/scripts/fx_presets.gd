class_name FxPresets
extends RefCounted
## Three reusable CPUParticles2D configurations (they run on every renderer, including GL
## Compatibility): a spark shower, a dust burst and a steam column. Bursts are one-shot and fire
## through Impact.burst(); steam toggles emitting with the state that drives it. Their dot textures and
## fade ramp are FxKit's shared ones; place() parks a configured one in its room.

const DUST: Color = Color("#c9b9a0")
const STEAM: Color = Color("#bfe8ff")


static func sparks(color: Color = Palette.CYAN) -> CPUParticles2D:
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


## Names [param particles] (an empty [param particles_name] keeps the preset's), parks it at [param at] on
## [param z] and adds it to [param parent]; a non-zero [param extents] spreads its emission over a
## rectangle that size. The caller sets anything else on it first. Returns [param particles].
static func place(particles: CPUParticles2D, parent: Node, particles_name: String, at: Vector2, z: int = 0, extents: Vector2 = Vector2.ZERO) -> CPUParticles2D:
	if not particles_name.is_empty():
		particles.name = particles_name
	particles.position = at
	if extents != Vector2.ZERO:
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = extents
	particles.z_index = z
	parent.add_child(particles)
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
	return FxKit.ramp([0.0, 0.6, 1.0], [Color.WHITE, Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])


static func _dot_texture(size: int) -> GradientTexture2D:
	return FxKit.radial(size, [0.0, 0.5, 1.0], [Color.WHITE, Color(1.0, 1.0, 1.0, 0.5), Color(1.0, 1.0, 1.0, 0.0)])
