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


## Hot metal thrown off a short or a tearing bolt: short hard-edged streaks aligned with their flight
## (2 world px wide, about 7 long), white-hot to orange as they cool, falling under gravity. Not soft
## discs: a spark is a molten fleck seen in motion.
static func streaks(amount: int = 20) -> CPUParticles2D:
	var particles: CPUParticles2D = _one_shot("Streaks", amount, 0.5)
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 60.0
	particles.initial_velocity_min = 160.0
	particles.initial_velocity_max = 340.0
	particles.gravity = Vector2(0.0, 900.0)
	particles.damping_min = 20.0
	particles.damping_max = 40.0
	particles.particle_flag_align_y = true
	particles.scale_amount_min = 0.55
	particles.scale_amount_max = 1.0
	var ramp: Gradient = Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.7, 1.0])
	ramp.colors = PackedColorArray([Color("#fff6d8"), Color("#ffc65a"), Color("#e8692a"), Color(0.6, 0.18, 0.05, 0.0)])
	particles.color_ramp = ramp
	particles.texture = _streak_texture()
	return particles


## Broken concrete and steel thrown by a blast: small hard-edged chips (2-4 world px) that tumble and
## fall to the deck.
static func chips(color: Color, amount: int = 20) -> CPUParticles2D:
	var particles: CPUParticles2D = _one_shot("Chips", amount, 0.8)
	particles.direction = Vector2(1.0, -0.4)
	particles.spread = 45.0
	particles.initial_velocity_min = 140.0
	particles.initial_velocity_max = 380.0
	particles.gravity = Vector2(0.0, 900.0)
	particles.damping_min = 8.0
	particles.damping_max = 12.0
	particles.angle_min = 0.0
	particles.angle_max = 360.0
	particles.angular_velocity_min = -540.0
	particles.angular_velocity_max = 540.0
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.1
	particles.color = color
	var ramp: Gradient = Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.85, 1.0])
	ramp.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])
	particles.color_ramp = ramp
	particles.texture = _chip_texture()
	return particles


## A blast's dust driven through an opening: a fast jet that slows hard and spreads as it goes.
static func dust_jet(color: Color, amount: int = 26) -> CPUParticles2D:
	var particles: CPUParticles2D = _one_shot("DustJet", amount, 1.0)
	particles.explosiveness = 0.85
	particles.direction = Vector2(1.0, -0.12)
	particles.spread = 16.0
	particles.initial_velocity_min = 260.0
	particles.initial_velocity_max = 480.0
	particles.damping_min = 380.0
	particles.damping_max = 520.0
	particles.gravity = Vector2(0.0, -14.0)
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	var growth: Curve = Curve.new()
	growth.add_point(Vector2(0.0, 0.4))
	growth.add_point(Vector2(1.0, 1.7))
	particles.scale_amount_curve = growth
	particles.color = color
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


## 2 x 8: a hard-edged streak, brightest at its head (the end it flies toward, its +y after align_y).
static func _streak_texture() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 0.75), Color.WHITE])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 2
	texture.height = 8
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture


## 3 x 3, solid: a chip with hard edges (the particle's colour and turn make each one different).
static func _chip_texture() -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(0.8, 0.8, 0.8)])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 3
	texture.height = 3
	return texture


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
