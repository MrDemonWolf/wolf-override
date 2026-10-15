class_name FxPresets
extends RefCounted
## Four reusable CPUParticles2D configurations (they run on every renderer, including GL
## Compatibility): a spark shower, a dust burst, a steam column and a relief-valve jet. Bursts are
## one-shot and fire through Impact.burst(); steam and the jet toggle emitting with the state that
## drives them.

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


## Continuous: the coolant spray from a pressure-relief discharge pipe's open end, 0.44 m above the
## floor, pointing straight down. Hot coolant that relieves to air flashes, so it shows right at the
## mouth: a short, dense, slightly fanned spray of soft streaks (align Y) that starts pipe-narrow,
## widens as it falls and spreads where it meets the floor about 18 px below, and is gone there; low
## alpha in normal blending (no glow; 0.2 since round 9, so it stays faint, as brief (g) asks). The
## caller sets emitting.
static func relief_jet() -> CPUParticles2D:
	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.name = "ReliefJet"
	particles.emitting = false
	particles.amount = 22
	particles.lifetime = 0.22
	particles.direction = Vector2(0.0, 1.0)
	particles.spread = 9.0
	particles.initial_velocity_min = 70.0
	particles.initial_velocity_max = 84.0
	particles.damping_min = 35.0
	particles.damping_max = 50.0
	particles.gravity = Vector2(0.0, 120.0)
	particles.particle_flag_align_y = true
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 1.2
	var flare: Curve = Curve.new()
	flare.add_point(Vector2(0.0, 0.22))
	flare.add_point(Vector2(0.55, 0.6))
	flare.add_point(Vector2(1.0, 1.0))
	particles.scale_amount_curve = flare
	particles.color = Color(0.86, 0.92, 0.95, 0.2)
	var fade: Gradient = Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.1, 0.7, 1.0])
	fade.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 0.85), Color.WHITE, Color(1.0, 1.0, 1.0, 0.55), Color(1.0, 1.0, 1.0, 0.0)])
	particles.color_ramp = fade
	particles.texture = _streak_texture(12, 16)
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


## A soft ellipse [param width] by [param height] (the radial fill runs in UV space), for streaks
## stretched along their travel.
static func _streak_texture(width: int, height: int) -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1.0, 1.0, 1.0, 0.4), Color(1.0, 1.0, 1.0, 0.0)])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = width
	texture.height = height
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture
