class_name FxPresets
extends RefCounted
## Reusable CPUParticles2D configurations (they run on every renderer, including GL Compatibility):
## a spark shower, hot streaks, thrown chips, a dust burst, a dust jet, a steam column and a
## relief-valve jet. Bursts are
## one-shot and fire through Impact.burst(); steam and the jet toggle emitting with the state that
## drives them. Their textures and ramps are FxKit's shared ones; place() parks a configured one in its
## room.

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
	particles.color_ramp = FxKit.ramp([0.0, 0.25, 0.7, 1.0], [Color("#fff6d8"), Color("#ffc65a"), Color("#e8692a"), Color(0.6, 0.18, 0.05, 0.0)])
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
	# Held whole longer than the soft presets (to 0.85 of the life), so a chip is still solid as it lands.
	particles.color_ramp = _fade_ramp(0.85)
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


## Continuous: the coolant spray from a pressure-relief discharge pipe's open end, 0.44 m above the
## floor, pointing straight down. Hot coolant that relieves to air flashes, so it shows right at the
## mouth: a short, dense, slightly fanned spray of soft streaks (align Y) that starts pipe-narrow,
## widens as it falls and spreads where it meets the floor about 18 px below, and is gone there; low
## alpha in normal blending (no glow; 0.2 since round 9, so it stays faint, as brief (g) asks). The
## caller sets emitting. Its ramp and streak texture are FxKit's, shared, so nothing writes to them.
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
	particles.color_ramp = FxKit.ramp([0.0, 0.1, 0.7, 1.0], [Color(1.0, 1.0, 1.0, 0.85), Color.WHITE, Color(1.0, 1.0, 1.0, 0.55), Color(1.0, 1.0, 1.0, 0.0)])
	# A soft 12x16 ellipse (the radial fill runs in UV space), a streak stretched along its travel.
	particles.texture = FxKit.radial(12, [0.0, 0.45, 1.0], [Color.WHITE, Color(1.0, 1.0, 1.0, 0.4), Color(1.0, 1.0, 1.0, 0.0)], GradientTexture2D.FILL_RADIAL, 16)
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


## The particles' colour over their life: whole until [param hold] (a share of the life, 0 to 1),
## then fading out to nothing by its end. FxKit's shared ramp, so nothing writes to it.
static func _fade_ramp(hold: float = 0.6) -> Gradient:
	return FxKit.ramp([0.0, hold, 1.0], [Color.WHITE, Color.WHITE, Color(1.0, 1.0, 1.0, 0.0)])


## 2 x 8: a hard-edged streak, brightest at its head (the end it flies toward, its +y after align_y),
## FxKit's top-to-bottom band at that size (the same pixels as the streak's own texture had).
static func _streak_texture() -> GradientTexture2D:
	return FxKit.linear([0.0, 0.45, 1.0], [Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 0.75), Color.WHITE], false, 8, 2)


## 3 x 3, solid: a chip with hard edges (the particle's colour and turn make each one different),
## FxKit's left-to-right band at that size (white to a light grey).
static func _chip_texture() -> GradientTexture2D:
	return FxKit.linear([0.0, 1.0], [Color.WHITE, Color(0.8, 0.8, 0.8)], true, 3, 3)


static func _dot_texture(size: int) -> GradientTexture2D:
	return FxKit.radial(size, [0.0, 0.5, 1.0], [Color.WHITE, Color(1.0, 1.0, 1.0, 0.5), Color(1.0, 1.0, 1.0, 0.0)])
