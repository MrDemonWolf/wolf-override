extends Node2D
class_name JunctionRoom
## Blowback: the Service Junction, the third 960 px room after the Records exit. The maintenance
## corridor's layered set and its breaker and sealed-door props are reused, tinted, until the room
## has its own art; the pressure line, relief
## vent, valve wheel, gauge, sealed door, rubble, the overhead arm and its tank, the floor mark,
## the ARM PANEL alcove, the exit bolt and the hatch are drawn here from the state the parent
## mirrors in (PressureLine, DropArm, SentryBrain), so nothing animates on a timer of its own.

const CORRIDOR_FAR: Texture2D = preload("res://assets/rooms/corridor-far.png")
const CORRIDOR_MID: Texture2D = preload("res://assets/rooms/corridor-mid.png")
const CORRIDOR_NEAR: Texture2D = preload("res://assets/rooms/corridor-near.png")
const BREAKER_PROP: Texture2D = preload("res://assets/props/corridor-breaker.png")
const DOOR_PROP: Texture2D = preload("res://assets/props/corridor-sealed-door.png")
## The corridor's prop cuts and scales (see main.tscn), so both rooms show the same machines.
const BREAKER_REGION: Rect2 = Rect2(81.0, 46.0, 342.0, 433.0)
const BREAKER_SCALE: float = 0.225
const DOOR_REGION: Rect2 = Rect2(120.0, 18.0, 273.0, 467.0)
const DOOR_SCALE: float = 0.302
## The breaker's status light rides on the amber bar painted at the top of its cabinet.
const BREAKER_LIGHT: Rect2 = Rect2(BREAKER_X - 11.0, 358.0, 18.0, 5.0)
## Station centres, left to right.
const ENTRY_X: float = 80.0
const BREAKER_X: float = 200.0
const VENT_X: float = 300.0
const VALVE_X: float = 420.0
const DOOR_X: float = 480.0
## The rubble line is the sentry's lane boundary.
const RUBBLE_X: float = SentryBrain.RUBBLE_X
## The ARM PANEL sits in the middle of the alcove that hides the engineer from the sentry.
const ARM_X: float = (SentryBrain.COVER_MIN_X + SentryBrain.COVER_MAX_X) * 0.5
const BOLT_X: float = 850.0
const HATCH_X: float = 880.0
const FLOOR_Y: float = 440.0
## Where WOLF stands to read the door seam (his 62 px body stops just short of the door body at
## x 452), and where he holds once the door is down.
const WOLF_SEAM_X: float = 418.0
## (He holds at the near edge of the rubble, so his sprite stays clear of the engineer at CHOICE_X.)
const WOLF_RUBBLE_X: float = 448.0
## Where WOLF stands when he chooses to draw the sentry; it parks BAIT_OFFSET short of him, on the mark.
const WOLF_BAIT_X: float = DropArm.MARK_X + SentryBrain.BAIT_OFFSET
## The engineer's front foot on the rubble line: where the question of how to drop the tank comes up,
## still outside the sentry's lane.
const CHOICE_X: float = RUBBLE_X - M0State.HUMAN_HALF_WIDTH
## The tank hangs centred here and lands with its base on the floor. At the play framing (zoom 1.35,
## camera y 360) its top sits at screen y ~186, below the answer buttons (Main.CHOICE_ROW_TOP), and
## its base (y 354) clears the sentry's mast (Sentry.DRAWN_HEIGHT) as it patrols underneath.
const TANK_REST_Y: float = 326.0
const TANK_SIZE: Vector2 = Vector2(36.0, 56.0)
const RAIL_Y: float = 196.0
## The hatch slides open this long after the bolt arcs.
const HATCH_OPEN_SECONDS: float = 0.5
## The sealed door body is this wide; its left face is M0State.JUNCTION_DOOR_LEFT_X.
const DOOR_WIDTH: float = 56.0
## How long the grate stays dangerous after the relief vent lets go.
const HAZARD_SECONDS: float = 0.4
const VENT_REASON: String = "The relief vent let go under you. Stand clear of the grate when the gauge peaks."
const BLAST_REASON: String = "The door blew with you in front of it. Get left of the vent before the fuse ends."
const SENTRY_REASON: String = "The sentry ran you down in its lane. Cross when it faces away, or get back over the rubble."
const CLOUD_REASON: String = "The coolant cloud caught you. Let it clear before you cross the mark."
const AMBER: Color = Color("#f3ae4b")
const GREEN: Color = Color("#a4f0c4")
const DIM: Color = Color("#3e4f5a")
const STEEL: Color = Color("#4a6572")
const COOLANT: Color = Color("#7fe8ff")
const SEAM_RED: Color = Color("#ff6a55")
## The VALVE label sits this far left of the wheel so SEAL CHARGED ends before the door art.
const VALVE_LABEL_SHIFT: float = 22.0
## The relief vent's painted caption: its baseline start, text and size.
const VENT_LABEL_POSITION: Vector2 = Vector2(VENT_X - 42.0, 346.0)
const VENT_LABEL: String = "RELIEF VENT"
const VENT_LABEL_FONT_SIZE: int = 11
## The gauge dial sits above the pipe run (y 292), clear of the VALVE label below it.
const GAUGE_CENTRE: Vector2 = Vector2(VALVE_X - 48.0, 266.0)

## Lamp and lockdown-beacon centres as fractions of the reused corridor far plate (as in main.tscn).
var lamps: PackedVector2Array = PackedVector2Array([Vector2(0.144, 0.188), Vector2(0.5, 0.188), Vector2(0.854, 0.188)])
var warning_lamps: PackedVector2Array = PackedVector2Array([Vector2(0.341, 0.27), Vector2(0.659, 0.27)])

# Mirrored from the parent's state and PressureLine; the parent calls sync_line()/refresh_state().
var line_state: StringName = &"idle"
var gauge: float = 0.0
var turns: int = 0
var door_blown: bool = false
var sentry_down: bool = false
var junction_cleared: bool = false
## Mirrored from DropArm: its state and how far down the tank is (0 hanging, 1 on the floor).
var arm_state: StringName = &"hung"
var tank_drop: float = 0.0
## Mirrored from Main's exit bolt: locked, charging (0..1 through the whine) or open.
var bolt_state: StringName = &"locked"
var bolt_charge: float = 0.0
## 0 shut, 1 open; slides once after the bolt arcs.
var hatch_open: float = 0.0:
	set(value):
		hatch_open = value
		queue_redraw()
## Reduced Motion: the charged seam holds a steady glow instead of strobing.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		if is_node_ready():
			_sync_seam()

var depth: RoomDepth
var breaker_art: Sprite2D
var door_body: StaticBody2D
var door_shape: CollisionShape2D
var door_visual: Node2D
var door_art: Sprite2D
var valve_wheel: ValveWheel
var vent_steam: CPUParticles2D
var vent_puff: CPUParticles2D
var blast_sparks: CPUParticles2D
var blast_dust: CPUParticles2D
var vent_hazard: Hazard
var cloud_hazard: Hazard
var sentry: Sentry
var tank: TankArt
var coolant_cloud: CPUParticles2D
var coolant_burst: CPUParticles2D
var hit_sparks: CPUParticles2D
var bolt_sparks: CPUParticles2D
var arm_label: Label
var hatch_label: Label
var breaker_glow: Sprite2D
var seam_glow: Sprite2D
var breaker_label: Label
var valve_label: Label
var door_label: Label
var floor_reflections: Array[FloorReflection] = []
var _valve_tween: Tween
var _seam_tween: Tween
var _door_tween: Tween
var _hazard_tween: Tween
var _hatch_tween: Tween


## The valve wheel: a rim, hub and four spokes that turn a quarter per real valve turn.
class ValveWheel:
	extends Node2D
	const RADIUS: float = 20.0

	func _draw() -> void:
		draw_circle(Vector2.ZERO, RADIUS + 3.0, Color("#1b2630"))
		draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, Color("#9fb6c2"), 4.0, true)
		for spoke: int in 4:
			var direction: Vector2 = Vector2.RIGHT.rotated(spoke * TAU / 4.0)
			draw_line(Vector2.ZERO, direction * RADIUS, Color("#9fb6c2"), 3.0, true)
		draw_circle(Vector2.ZERO, 5.0, Color("#d8e6ec"))
		draw_circle(Vector2(0.0, -RADIUS), 3.0, Color("#f3ae4b"))


## The hanging coolant tank: a banded cylinder with a clamp lug, dented after a missed drop.
class TankArt:
	extends Node2D
	var dented: bool = false:
		set(value):
			dented = value
			queue_redraw()

	func _draw() -> void:
		var half: Vector2 = JunctionRoom.TANK_SIZE * 0.5
		var body: Rect2 = Rect2(-half, JunctionRoom.TANK_SIZE)
		draw_rect(body, Color("#2c4a57"))
		draw_rect(Rect2(body.position.x + 4.0, body.position.y, 6.0, body.size.y), Color("#3f6a7a"))
		for band: int in 2:
			draw_rect(Rect2(body.position.x, body.position.y + 12.0 + band * 26.0, body.size.x, 4.0), Color("#c98a2e"))
		draw_rect(body, Color("#7fa5b4"), false, 1.5)
		draw_rect(Rect2(-6.0, -half.y - 6.0, 12.0, 6.0), Color("#4a6572"))
		draw_string(ThemeDB.fallback_font, Vector2(-half.x + 3.0, 6.0), "COOLANT", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("#bfe8ff"))
		if dented:
			var dent: PackedVector2Array = PackedVector2Array([Vector2(half.x, half.y - 18.0), Vector2(half.x - 7.0, half.y - 10.0), Vector2(half.x, half.y - 3.0)])
			draw_colored_polygon(dent, Color("#14242c"))


func _ready() -> void:
	depth = RoomDepth.new()
	depth.name = "Depth"
	depth.painting = CORRIDOR_FAR
	depth.mid_painting = CORRIDOR_MID
	depth.near_painting = CORRIDOR_NEAR
	depth.walkway_y = 777.0
	depth.far_drop = 27.0
	# The reused corridor set is pulled warmer and darker so the junction reads as its own place.
	depth.plate_tint = Color("#b7a79c")
	depth.base_color = Color("#0a0e18")
	depth.lamps = lamps
	depth.lamp_color = Color("#ffcf9a")
	depth.shaft_lamps = PackedInt32Array([0, 2])
	depth.warning_lamps = warning_lamps
	add_child(depth)
	breaker_art = RoomDepth.make_prop("BreakerArt", BREAKER_PROP, BREAKER_REGION, BREAKER_SCALE, BREAKER_X)
	# One step under this node's own drawing, so the status light drawn in _draw() sits on the art.
	breaker_art.z_index = -1
	add_child(breaker_art)
	floor_reflections.append(FloorReflection.attach(breaker_art))
	breaker_glow = RoomDepth.make_glow(AMBER, Vector2(64.0, 30.0), 0.5)
	breaker_glow.name = "BreakerGlow"
	breaker_glow.position = BREAKER_LIGHT.get_center()
	breaker_glow.z_index = 1
	add_child(breaker_glow)
	_build_door()
	valve_wheel = ValveWheel.new()
	valve_wheel.name = "ValveWheel"
	valve_wheel.position = Vector2(VALVE_X, 372.0)
	valve_wheel.z_index = 1
	add_child(valve_wheel)
	_build_particles()
	# The hurtbox is the drawn grate: a body touching it is on the vent (PressureLine.is_on_vent).
	# The door blast has no hurtbox; main.gd decides it from PressureLine.is_in_blast alone.
	vent_hazard = Hazard.make("VentHazard", Rect2(PressureLine.VENT_GRATE_MIN_X, 380.0, PressureLine.VENT_GRATE_MAX_X - PressureLine.VENT_GRATE_MIN_X, 60.0), VENT_REASON)
	add_child(vent_hazard)
	breaker_label = _add_station_label("OVERLOAD BREAKER", BREAKER_X, Color("#b0d1de"))
	# Centred a little left of the wheel so its longest text (SEAL CHARGED) ends before the door art.
	valve_label = _add_station_label("VALVE", VALVE_X - VALVE_LABEL_SHIFT, Color("#b0d1de"))
	door_label = _add_station_label("SEALED DOOR", DOOR_X, Color("#ffc7c7"), 276.0)
	arm_label = _add_station_label("ARM PANEL", ARM_X, Color("#b0d1de"))
	# Centred between the bolt panel and the hatch so both read as one exit.
	hatch_label = _add_station_label("EXIT BOLTED", (BOLT_X + HATCH_X) * 0.5, Color("#8fa6b2"), 276.0)
	_build_lane()
	refresh_state()


## The sealed door: the corridor's seal art over a 56x132 body on the floor layer, pivoted at the
## floor so the blast can crush it downward.
func _build_door() -> void:
	door_body = StaticBody2D.new()
	door_body.name = "Door"
	door_body.position = Vector2(DOOR_X, 374.0)
	door_body.collision_layer = 2
	door_body.collision_mask = 0
	door_shape = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = Vector2(DOOR_WIDTH, 132.0)
	door_shape.shape = box
	# Off until the junction is the room in play (see set_active).
	door_shape.disabled = true
	door_body.add_child(door_shape)
	add_child(door_body)
	door_visual = Node2D.new()
	door_visual.name = "DoorVisual"
	door_visual.position = Vector2(DOOR_X, FLOOR_Y)
	door_visual.z_index = 1
	add_child(door_visual)
	door_art = RoomDepth.make_prop("DoorArt", DOOR_PROP, DOOR_REGION, DOOR_SCALE, 0.0, 0.0)
	door_visual.add_child(door_art)
	floor_reflections.append(FloorReflection.attach(door_art))
	seam_glow = RoomDepth.make_glow(AMBER, Vector2(70.0, 150.0), 0.0)
	seam_glow.name = "SeamGlow"
	seam_glow.position = Vector2(DOOR_X - 26.0, 374.0)
	seam_glow.z_index = 2
	add_child(seam_glow)


func _build_particles() -> void:
	vent_steam = FxPresets.steam()
	vent_steam.name = "VentSteam"
	vent_steam.position = Vector2(VENT_X, FLOOR_Y - 4.0)
	vent_steam.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	vent_steam.emission_rect_extents = Vector2((PressureLine.VENT_GRATE_MAX_X - PressureLine.VENT_GRATE_MIN_X) * 0.5 - 6.0, 2.0)
	vent_steam.z_index = 3
	add_child(vent_steam)
	vent_puff = FxPresets.dust_burst()
	vent_puff.name = "VentPuff"
	vent_puff.position = vent_steam.position
	# Translucent and thin enough that the engineer, the grate and the breaker read through it.
	vent_puff.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	vent_puff.emission_rect_extents = vent_steam.emission_rect_extents
	vent_puff.color = Color(FxPresets.STEAM, 0.3)
	vent_puff.initial_velocity_min = 160.0
	vent_puff.initial_velocity_max = 260.0
	vent_puff.spread = 30.0
	vent_puff.amount = 16
	vent_puff.z_index = 3
	add_child(vent_puff)
	blast_sparks = FxPresets.sparks(AMBER)
	blast_sparks.name = "BlastSparks"
	blast_sparks.position = Vector2(DOOR_X, 370.0)
	blast_sparks.amount = 36
	blast_sparks.spread = 110.0
	blast_sparks.z_index = 3
	add_child(blast_sparks)
	blast_dust = FxPresets.dust_burst()
	blast_dust.name = "BlastDust"
	blast_dust.position = Vector2(DOOR_X + 20.0, FLOOR_Y - 4.0)
	blast_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	blast_dust.emission_rect_extents = Vector2(70.0, 3.0)
	blast_dust.amount = 30
	blast_dust.z_index = 3
	add_child(blast_dust)


## The sentry, the tank over the mark and the lane's hazards and bursts. The sentry is added before
## the tank so a landed tank draws over the machine it came down on.
func _build_lane() -> void:
	sentry = Sentry.new()
	sentry.name = "Sentry"
	sentry.z_index = 1
	add_child(sentry)
	tank = TankArt.new()
	tank.name = "Tank"
	tank.position = Vector2(DropArm.MARK_X, TANK_REST_Y)
	tank.z_index = 1
	add_child(tank)
	# The cloud's hurtbox is the cloud: DropArm.CLOUD_HALF_WIDTH either side of the mark, floor to head height.
	cloud_hazard = Hazard.make("CloudHazard", Rect2(DropArm.MARK_X - DropArm.CLOUD_HALF_WIDTH, 360.0, DropArm.CLOUD_HALF_WIDTH * 2.0, 80.0), CLOUD_REASON)
	add_child(cloud_hazard)
	coolant_cloud = FxPresets.steam()
	coolant_cloud.name = "CoolantCloud"
	coolant_cloud.position = Vector2(DropArm.MARK_X, FLOOR_Y - 6.0)
	coolant_cloud.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	coolant_cloud.emission_rect_extents = Vector2(DropArm.CLOUD_HALF_WIDTH - 8.0, 4.0)
	coolant_cloud.initial_velocity_min = 20.0
	coolant_cloud.initial_velocity_max = 60.0
	coolant_cloud.spread = 60.0
	coolant_cloud.scale_amount_min = 10.0
	coolant_cloud.scale_amount_max = 18.0
	coolant_cloud.amount = 24
	coolant_cloud.color = Color(COOLANT, 0.16)
	# Behind the actors and the sentry, so the vapour never hides who is in it.
	coolant_cloud.z_index = 0
	add_child(coolant_cloud)
	coolant_burst = FxPresets.dust_burst()
	coolant_burst.name = "CoolantBurst"
	coolant_burst.position = Vector2(DropArm.MARK_X, FLOOR_Y - 10.0)
	coolant_burst.color = Color(COOLANT, 0.35)
	coolant_burst.initial_velocity_min = 110.0
	coolant_burst.initial_velocity_max = 220.0
	coolant_burst.amount = 22
	coolant_burst.z_index = 3
	add_child(coolant_burst)
	hit_sparks = FxPresets.sparks(FxPresets.SPARK_CYAN)
	hit_sparks.name = "HitSparks"
	hit_sparks.position = Vector2(DropArm.MARK_X, FLOOR_Y - 30.0)
	hit_sparks.amount = 36
	hit_sparks.spread = 100.0
	hit_sparks.z_index = 3
	add_child(hit_sparks)
	bolt_sparks = FxPresets.sparks(Color("#c1f4d8"))
	bolt_sparks.name = "BoltSparks"
	bolt_sparks.position = Vector2(BOLT_X, 336.0)
	bolt_sparks.amount = 30
	bolt_sparks.z_index = 3
	add_child(bolt_sparks)


func _add_station_label(caption: String, center_x: float, tint: Color, label_y: float = 309.0) -> Label:
	var label: Label = Label.new()
	label.text = caption
	label.position = Vector2(center_x - 90.0, label_y)
	label.size = Vector2(180.0, 30.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", tint)
	add_child(label)
	return label


## Enables the door body and hazards only while this is the room in play, so the junction's
## collision never leaks into the corridor or Records, which share the same coordinates.
func set_active(active: bool) -> void:
	door_shape.set_deferred("disabled", not active or door_blown)
	vent_hazard.armed = false
	vent_hazard.set_deferred("monitoring", active)
	cloud_hazard.armed = false
	cloud_hazard.set_deferred("monitoring", active)


## Copies the live pressure line in; the gauge needle, steam, seam and labels all follow it.
func sync_line(line: PressureLine) -> void:
	var previous_turns: int = turns
	var previous_state: StringName = line_state
	line_state = line.state
	gauge = line.gauge
	turns = line.turns
	if turns != previous_turns:
		_turn_wheel(turns)
	if line_state != previous_state:
		refresh_state()
	var building: bool = line_state == &"building"
	vent_steam.emitting = building and visible
	vent_steam.initial_velocity_max = lerpf(60.0, 220.0, gauge)
	vent_steam.scale_amount_max = lerpf(6.0, 16.0, gauge)
	vent_steam.modulate.a = lerpf(0.3, 1.0, gauge)
	if building:
		seam_glow.modulate = Color(AMBER, 0.25 + 0.5 * gauge)
	queue_redraw()


## Copies the arm in: the tank's height, the cloud and its hurtbox follow DropArm's state.
func sync_arm(arm: DropArm) -> void:
	var previous_state: StringName = arm_state
	arm_state = arm.state
	tank_drop = arm.drop_amount()
	tank.position.y = lerpf(TANK_REST_Y, FLOOR_Y - TANK_SIZE.y * 0.5, tank_drop)
	var cloud: bool = arm.cloud_active() and visible
	coolant_cloud.emitting = cloud
	if cloud_hazard.armed != cloud:
		cloud_hazard.armed = cloud
	if arm_state != previous_state:
		refresh_state()
	queue_redraw()


## Copies the exit bolt in; its panel light warms with the charge.
func sync_bolt(state: StringName, charge: float) -> void:
	var changed: bool = state != bolt_state
	bolt_state = state
	bolt_charge = charge
	if changed:
		refresh_state()
	queue_redraw()


## The tank came down on the sentry at [param at_x]: the coolant and spark bursts (fired through the
## impact kit) are moved there and the sentry keels over.
func tank_hit(at_x: float) -> void:
	sentry_down = true
	coolant_burst.position.x = at_x
	hit_sparks.position.x = at_x
	sentry.keel_over()
	refresh_state()


## The tank hit the floor: the coolant burst moves to the mark and the tank is dented.
func tank_miss() -> void:
	coolant_burst.position.x = DropArm.MARK_X
	tank.dented = true


## The bolt lets go and the hatch slides open (the parent fires the panel's sparks).
func bolt_arc() -> void:
	if _hatch_tween != null and _hatch_tween.is_valid():
		_hatch_tween.kill()
	_hatch_tween = create_tween()
	_hatch_tween.tween_property(self, "hatch_open", 1.0, HATCH_OPEN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _turn_wheel(to_turns: int) -> void:
	if _valve_tween != null and _valve_tween.is_valid():
		_valve_tween.kill()
	var target: float = 90.0 * to_turns
	if to_turns == 0:
		valve_wheel.rotation_degrees = target
		return
	_valve_tween = create_tween()
	_valve_tween.tween_property(valve_wheel, "rotation_degrees", target, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Labels, glows and the seam follow the line's phase; the parent calls this after state changes.
func refresh_state() -> void:
	if is_spent():
		# The blast used the line up: the same labels whether it just went or a save brought it back.
		breaker_label.text = "BREAKER SPENT"
		breaker_label.add_theme_color_override("font_color", Color("#8fa6b2"))
		valve_label.text = "VALVE SPENT"
		valve_label.add_theme_color_override("font_color", Color("#8fa6b2"))
	else:
		var armed: bool = line_state != &"idle" and line_state != &"tripped"
		breaker_label.text = "BREAKER TRIPPED" if line_state == &"tripped" else ("BREAKER LIVE" if armed else "OVERLOAD BREAKER")
		breaker_label.add_theme_color_override("font_color", SEAM_RED if line_state == &"tripped" else (Color("#8be3ff") if armed else Color("#b0d1de")))
		valve_label.text = "SEAL CHARGED" if line_state in [&"charged", &"fuse", &"blown"] else ("VALVE  %d / %d" % [turns, PressureLine.TURNS_NEEDED] if armed else "VALVE")
		valve_label.add_theme_color_override("font_color", GREEN if turns >= PressureLine.TURNS_NEEDED else Color("#b0d1de"))
	breaker_glow.modulate = Color(_breaker_light_color(), 0.75 if line_state in [&"building", &"charged", &"fuse"] and not door_blown else 0.4)
	door_label.text = "DOOR DOWN" if door_blown else "SEALED DOOR"
	door_label.add_theme_color_override("font_color", GREEN if door_blown else Color("#ffc7c7"))
	arm_label.text = "TANK DOWN" if sentry_down else ("ARM REWINDING" if arm_state == &"rewinding" else "ARM PANEL")
	arm_label.add_theme_color_override("font_color", Color("#8fa6b2") if sentry_down else (AMBER if arm_state == &"rewinding" else Color("#b0d1de")))
	if junction_cleared or bolt_state == &"open":
		hatch_label.text = "EXIT OPEN"
		hatch_label.add_theme_color_override("font_color", GREEN)
	elif sentry_down:
		hatch_label.text = "EXIT BOLT"
		hatch_label.add_theme_color_override("font_color", AMBER)
	else:
		hatch_label.text = "EXIT BOLTED"
		hatch_label.add_theme_color_override("font_color", Color("#8fa6b2"))
	_sync_seam()
	queue_redraw()


## True once the door is down, whether it just went or a save brought it back.
func is_spent() -> bool:
	return door_blown


func _sync_seam() -> void:
	if _seam_tween != null and _seam_tween.is_valid():
		_seam_tween.kill()
	_seam_tween = null
	seam_glow.visible = not door_blown
	match line_state:
		&"charged", &"fuse":
			# The seam strobes white only once the third turn is real; Reduced Motion holds it steady.
			seam_glow.modulate = Color(Color.WHITE, 0.9)
			if reduce_motion:
				return
			_seam_tween = create_tween().set_loops()
			_seam_tween.tween_property(seam_glow, "modulate", Color(SEAM_RED, 0.5), 0.08)
			_seam_tween.tween_property(seam_glow, "modulate", Color(Color.WHITE, 0.9), 0.08)
		&"building":
			seam_glow.modulate = Color(AMBER, 0.25 + 0.5 * gauge)
		&"blown":
			seam_glow.visible = false
		_:
			seam_glow.modulate = Color(AMBER, 0.2)


## The vent letting go: a steam burst and a short armed window over the grate.
func vent_blows() -> void:
	vent_steam.emitting = false
	vent_puff.restart()
	_arm_hazard(vent_hazard)


## The door going: the seal crushes to the floor, rubble appears, sparks and dust fly, and the
## blast zone is dangerous for a moment.
func door_blast() -> void:
	door_blown = true
	vent_hazard.armed = false
	door_shape.set_deferred("disabled", true)
	blast_sparks.restart()
	blast_dust.restart()
	if _door_tween != null and _door_tween.is_valid():
		_door_tween.kill()
	door_visual.visible = true
	door_visual.scale = Vector2.ONE
	door_visual.rotation_degrees = 0.0
	_door_tween = create_tween()
	_door_tween.tween_property(door_visual, "scale:y", 0.06, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_door_tween.parallel().tween_property(door_visual, "rotation_degrees", 6.0, 0.22)
	_door_tween.tween_callback(door_visual.hide)
	refresh_state()


func _arm_hazard(hazard: Hazard) -> void:
	if _hazard_tween != null and _hazard_tween.is_valid():
		_hazard_tween.kill()
	hazard.armed = true
	_hazard_tween = create_tween()
	_hazard_tween.tween_interval(HAZARD_SECONDS)
	_hazard_tween.tween_callback(func() -> void: hazard.armed = false)


## Back to the state the save describes: no burst, no fuse, the wheel at rest and the door as saved.
func reset_transient() -> void:
	for tween: Tween in [_valve_tween, _seam_tween, _door_tween, _hazard_tween, _hatch_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	_valve_tween = null
	_seam_tween = null
	_door_tween = null
	_hazard_tween = null
	_hatch_tween = null
	vent_hazard.armed = false
	cloud_hazard.armed = false
	for burst: CPUParticles2D in [vent_steam, vent_puff, blast_sparks, blast_dust, coolant_cloud, coolant_burst, hit_sparks, bolt_sparks]:
		burst.emitting = false
	# The tank hangs again (or lies on the downed sentry), undented; the hatch is as the save left it.
	tank.dented = false
	arm_state = &"landed" if sentry_down else &"hung"
	tank_drop = 1.0 if sentry_down else 0.0
	tank.position.y = lerpf(TANK_REST_Y, FLOOR_Y - TANK_SIZE.y * 0.5, tank_drop)
	bolt_state = &"open" if junction_cleared else &"locked"
	bolt_charge = 0.0
	hatch_open = 1.0 if junction_cleared else 0.0
	# A blown door left the wheel at its third quarter; a restored save shows it the same way.
	valve_wheel.rotation_degrees = 90.0 * PressureLine.TURNS_NEEDED if door_blown else 0.0
	door_visual.scale = Vector2.ONE
	door_visual.rotation_degrees = 0.0
	door_visual.visible = not door_blown
	door_shape.set_deferred("disabled", not visible or door_blown)
	line_state = &"idle"
	gauge = 0.0
	turns = 0
	refresh_state()


func _draw() -> void:
	# The reused corridor plates are the Depth child's layers.
	_draw_entry_hatch()
	_draw_pressure_line()
	_draw_vent()
	_draw_gauge_and_lights()
	_draw_breaker_light()
	if door_blown:
		_draw_rubble()
	_draw_arm_panel()
	_draw_arm()
	_draw_floor_mark()
	_draw_exit_hatch()
	_draw_bolt_panel()


func _draw_entry_hatch() -> void:
	draw_rect(Rect2(ENTRY_X - 32.0, 300.0, 64.0, 138.0), Color("#081b2b"))
	draw_rect(Rect2(ENTRY_X - 40.0, 296.0, 80.0, 144.0), STEEL, false, 3.0)
	draw_line(Vector2(ENTRY_X - 20.0, 433.0), Vector2(ENTRY_X + 21.0, 433.0), GREEN, 4.0)


## The coolant line runs along the wall from the breaker past the vent and valve into the door;
## it warms with the gauge so the pressure is visible along its whole length.
func _draw_pressure_line() -> void:
	var pressure: Color = DIM.lerp(AMBER, gauge) if line_state == &"building" else (SEAM_RED if line_state == &"tripped" else DIM)
	var y: float = 292.0
	draw_line(Vector2(BREAKER_X, 330.0), Vector2(BREAKER_X, y), Color("#263540"), 10.0)
	draw_line(Vector2(BREAKER_X, y), Vector2(DOOR_X - 24.0, y), Color("#263540"), 10.0)
	draw_line(Vector2(VENT_X, y), Vector2(VENT_X, 352.0), Color("#263540"), 8.0)
	draw_line(Vector2(VALVE_X, y), Vector2(VALVE_X, 350.0), Color("#263540"), 8.0)
	draw_line(Vector2(BREAKER_X, y), Vector2(DOOR_X - 24.0, y), pressure, 3.0)
	draw_line(Vector2(VENT_X, y), Vector2(VENT_X, 352.0), pressure, 2.0)
	draw_line(Vector2(VALVE_X, y), Vector2(VALVE_X, 350.0), pressure, 2.0)


## The grate spans exactly the vent's hurtbox (PressureLine.VENT_GRATE_*), so what is drawn is
## what hurts.
func _draw_vent() -> void:
	var grate: Rect2 = Rect2(PressureLine.VENT_GRATE_MIN_X, FLOOR_Y - 8.0, PressureLine.VENT_GRATE_MAX_X - PressureLine.VENT_GRATE_MIN_X, 8.0)
	draw_rect(grate, Color("#141c24"))
	for slat: int in 7:
		var x: float = grate.position.x + 6.0 + slat * 10.0
		draw_line(Vector2(x, grate.position.y + 1.0), Vector2(x, grate.end.y - 1.0), Color("#5c707c"), 2.0)
	draw_rect(grate, STEEL, false, 2.0)
	var vent_light: Color = SEAM_RED if line_state == &"tripped" else (DIM.lerp(AMBER, gauge) if line_state == &"building" else DIM)
	draw_rect(Rect2(VENT_X - 13.0, 352.0, 26.0, 5.0), vent_light)
	draw_string(ThemeDB.fallback_font, VENT_LABEL_POSITION, VENT_LABEL, HORIZONTAL_ALIGNMENT_LEFT, -1, VENT_LABEL_FONT_SIZE, Color("#8fa6b2"))


## A dial mounted above the pipe run beside the valve whose needle is the gauge (above the station
## label at y 309, so it never covers it), and three lights stacked left of the wheel that go
## green per real turn.
func _draw_gauge_and_lights() -> void:
	var centre: Vector2 = GAUGE_CENTRE
	draw_line(Vector2(centre.x, 292.0), Vector2(centre.x, centre.y + 18.0), Color("#263540"), 6.0)
	draw_circle(centre, 18.0, Color("#101820"))
	draw_arc(centre, 15.0, PI, TAU, 24, Color("#5c707c"), 2.0, true)
	draw_arc(centre, 15.0, PI + PI * 0.78, TAU, 8, SEAM_RED, 3.0, true)
	var angle: float = PI + PI * gauge
	draw_line(centre, centre + Vector2.RIGHT.rotated(angle) * 13.0, Color("#f4f7f9") if gauge > 0.0 else Color("#7b8f9a"), 2.0, true)
	draw_circle(centre, 2.5, Color("#d8e6ec"))
	for light: int in PressureLine.TURNS_NEEDED:
		var rect: Rect2 = Rect2(VALVE_X - 40.0, 356.0 + light * 12.0, 12.0, 6.0)
		draw_rect(rect, GREEN if light < turns or door_blown else Color("#1f2a33"))
		draw_rect(rect, STEEL, false, 1.0)


func _draw_breaker_light() -> void:
	draw_rect(BREAKER_LIGHT, _breaker_light_color())


func _breaker_light_color() -> Color:
	if door_blown:
		return DIM
	match line_state:
		&"tripped":
			return SEAM_RED
		&"idle":
			return Color("#d48954")
		_:
			return Color("#8be3ff")


## What is left of the door: a dark spill of slabs at the rubble line.
func _draw_rubble() -> void:
	var base: Color = Color("#1a2229")
	var edge: Color = Color("#3a4a54")
	var slabs: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(448.0, 440.0), Vector2(470.0, 418.0), Vector2(506.0, 424.0), Vector2(512.0, 440.0)]),
		PackedVector2Array([Vector2(500.0, 440.0), Vector2(520.0, 412.0), Vector2(548.0, 420.0), Vector2(560.0, 440.0)]),
		PackedVector2Array([Vector2(540.0, 440.0), Vector2(552.0, 428.0), Vector2(576.0, 432.0), Vector2(582.0, 440.0)]),
		PackedVector2Array([Vector2(462.0, 440.0), Vector2(468.0, 432.0), Vector2(490.0, 430.0), Vector2(494.0, 440.0)]),
	]
	for slab: PackedVector2Array in slabs:
		draw_colored_polygon(slab, base)
		draw_polyline(slab, edge, 1.5, true)
	draw_line(Vector2(RUBBLE_X - 6.0, 439.0), Vector2(RUBBLE_X + 6.0, 439.0), AMBER, 3.0)


## The alcove recessed into the wall behind the panel: the engineer standing in it is out of the
## sentry's sight. Its width is exactly SentryBrain's cover span widened by half the engineer's body.
func _draw_arm_panel() -> void:
	var alcove: Rect2 = Rect2(SentryBrain.COVER_MIN_X - M0State.HUMAN_HALF_WIDTH, 318.0, SentryBrain.COVER_MAX_X - SentryBrain.COVER_MIN_X + M0State.HUMAN_HALF_WIDTH * 2.0, FLOOR_Y - 318.0)
	draw_rect(alcove, Color(0.02, 0.05, 0.08, 0.72))
	# A lit lip along the top so it reads as a recess, not a door.
	draw_rect(Rect2(alcove.position, Vector2(alcove.size.x, 4.0)), Color("#263540"))
	draw_rect(alcove, STEEL, false, 2.0)
	var panel: Rect2 = Rect2(ARM_X - 11.0, 346.0, 22.0, 28.0)
	draw_rect(panel, Color("#1b2630"))
	draw_rect(panel, Color("#9fb6c2"), false, 1.5)
	var light: Color = DIM if sentry_down else (GREEN if arm_state == &"hung" else AMBER)
	draw_rect(Rect2(ARM_X - 6.0, 352.0, 12.0, 5.0), light)
	draw_line(Vector2(ARM_X, 362.0), Vector2(ARM_X + (0.0 if arm_state == &"hung" else 6.0), 370.0), Color("#d8e6ec"), 2.0)
	# The control run from the panel up to the arm.
	draw_line(Vector2(ARM_X + 9.0, 346.0), Vector2(ARM_X + 9.0, RAIL_Y + 6.0), Color("#263540"), 3.0)


## The overhead rail, the trolley over the mark and the cable down to the tank. The cable is taut
## while the tank hangs, falls or winches back up, and lies slack once it has landed.
func _draw_arm() -> void:
	draw_line(Vector2(ARM_X + 9.0, RAIL_Y), Vector2(DropArm.MARK_X + 90.0, RAIL_Y), Color("#263540"), 9.0)
	draw_line(Vector2(ARM_X + 9.0, RAIL_Y - 3.0), Vector2(DropArm.MARK_X + 90.0, RAIL_Y - 3.0), STEEL, 2.0)
	for hanger_x: float in [ARM_X + 30.0, DropArm.MARK_X + 80.0]:
		draw_line(Vector2(hanger_x, 120.0), Vector2(hanger_x, RAIL_Y), Color("#263540"), 4.0)
	draw_rect(Rect2(DropArm.MARK_X - 14.0, RAIL_Y - 4.0, 28.0, 14.0), Color("#33424c"))
	draw_rect(Rect2(DropArm.MARK_X - 14.0, RAIL_Y - 4.0, 28.0, 14.0), Color("#9fb6c2"), false, 1.5)
	var cable_top: Vector2 = Vector2(DropArm.MARK_X, RAIL_Y + 10.0)
	var tank_top: Vector2 = Vector2(DropArm.MARK_X, tank.position.y - TANK_SIZE.y * 0.5 - 6.0)
	if arm_state == &"landed":
		var slack: PackedVector2Array = PackedVector2Array()
		for step: int in 9:
			var t: float = step / 8.0
			var point: Vector2 = cable_top.lerp(tank_top, t)
			point.x += sin(t * PI) * 26.0
			slack.append(point)
		draw_polyline(slack, Color("#9fb6c2"), 1.5, true)
	else:
		draw_line(cable_top, tank_top, Color("#9fb6c2"), 1.5)


## Hazard stripes on the floor exactly as wide as the drop's hit window.
func _draw_floor_mark() -> void:
	var left: float = DropArm.MARK_X - DropArm.HIT_RANGE
	var width: float = DropArm.HIT_RANGE * 2.0
	var stripes: int = 11
	for stripe: int in stripes:
		var segment: Rect2 = Rect2(left + stripe * width / stripes, FLOOR_Y - 4.0, width / stripes, 4.0)
		draw_rect(segment, AMBER if stripe % 2 == 0 else Color("#1a2229"))
	draw_line(Vector2(left, FLOOR_Y - 10.0), Vector2(left, FLOOR_Y), AMBER, 2.0)
	draw_line(Vector2(left + width, FLOOR_Y - 10.0), Vector2(left + width, FLOOR_Y), AMBER, 2.0)


func _draw_exit_hatch() -> void:
	draw_rect(Rect2(HATCH_X - 32.0, 300.0, 64.0, 138.0), Color("#06111a"))
	if hatch_open > 0.0:
		# The service line beyond: a faint green work light.
		draw_rect(Rect2(HATCH_X - 32.0, 300.0, 64.0, 138.0), Color(GREEN, 0.12 * hatch_open))
	# The hatch door slides up into the frame as it opens.
	var door_height: float = 138.0 * (1.0 - hatch_open)
	if door_height > 0.5:
		draw_rect(Rect2(HATCH_X - 32.0, 300.0, 64.0, door_height), Color("#0b1822"))
		for bar: int in 3:
			var y: float = 330.0 + bar * 34.0 - 138.0 * hatch_open
			if y > 300.0:
				draw_line(Vector2(HATCH_X - 32.0, y), Vector2(HATCH_X + 32.0, y), Color("#1e2b35"), 3.0)
	draw_rect(Rect2(HATCH_X - 40.0, 296.0, 80.0, 144.0), STEEL, false, 3.0)
	# The bolt across the hatch: red while it holds, dropped to the sill once it lets go.
	if bolt_state == &"open" or junction_cleared:
		draw_rect(Rect2(HATCH_X - 9.0, 432.0, 18.0, 5.0), DIM)
	else:
		draw_rect(Rect2(HATCH_X - 9.0, 354.0, 18.0, 5.0), SEAM_RED)


## The exit bolt's junction box on the hatch frame: red and dead while the sentry runs the line,
## amber once it can take the overload, warming to white through the whine, green once popped.
func _draw_bolt_panel() -> void:
	var box: Rect2 = Rect2(BOLT_X - 12.0, 318.0, 24.0, 30.0)
	draw_rect(box, Color("#1b2630"))
	draw_rect(box, Color("#9fb6c2"), false, 1.5)
	var light: Color = SEAM_RED
	if junction_cleared or bolt_state == &"open":
		light = GREEN
	elif bolt_state == &"charging":
		light = AMBER.lerp(Color.WHITE, bolt_charge)
	elif sentry_down:
		light = AMBER
	draw_rect(Rect2(BOLT_X - 7.0, 324.0, 14.0, 5.0), light)
	draw_line(Vector2(BOLT_X, 334.0), Vector2(BOLT_X, 344.0), Color("#d8e6ec"), 2.0)
