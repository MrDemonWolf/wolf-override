extends Node2D
class_name JunctionRoom
## Blowback: the Service Junction, the third 960 px room after the Records exit, built from its own
## layered set (RoomDepth) and painted station props, with the corridor's breaker. What the art
## cannot show is drawn over it here from the state the parent mirrors in (PressureLine, DropArm,
## SentryBrain): the pressure line, the gauge needle and turn lights, the seam glow, the panel and
## hatch lights, the alcove, the floor mark, the rubble line and the tank's cable. Nothing animates
## on a timer of its own.

const JUNCTION_FAR: Texture2D = preload("res://assets/rooms/junction-far.png")
const JUNCTION_MID: Texture2D = preload("res://assets/rooms/junction-mid.png")
const JUNCTION_NEAR: Texture2D = preload("res://assets/rooms/junction-near.png")
const BREAKER_PROP: Texture2D = preload("res://assets/props/corridor-breaker.png")
const VALVE_PROP: Texture2D = preload("res://assets/props/junction-valve.png")
const DOOR_SEALED_PROP: Texture2D = preload("res://assets/props/junction-blast-door-sealed.png")
const DOOR_BLOWN_PROP: Texture2D = preload("res://assets/props/junction-blast-door-blown.png")
const VENT_PROP: Texture2D = preload("res://assets/props/junction-relief-vent.png")
const ARM_PROP: Texture2D = preload("res://assets/props/junction-tank-arm.png")
## The tank cut out of the tank-arm image (rows 361..743), so it can fall away from the arm.
const TANK_PROP: Texture2D = preload("res://assets/props/junction-tank.png")
const ARM_PANEL_PROP: Texture2D = preload("res://assets/props/junction-arm-panel.png")
const BOLT_PANEL_PROP: Texture2D = preload("res://assets/props/junction-bolt-panel.png")
const HATCH_PROP: Texture2D = preload("res://assets/props/junction-hatch.png")
## The source row where the mid plate's walkway meets the back wall; it is drawn at the floor (y 440).
const WALKWAY_Y: float = 776.0
## The far plate sits this much lower than the mid plate, as in the corridor, so it still covers
## the bottom of the view at the touch framing.
const FAR_DROP: float = 27.0
## The near plate's pipe column is 100 px wide in the room (source column 200) against the
## corridor's 57, so its strips hang that much further past the room edges.
const NEAR_OVERHANG: float = RoomDepth.NEAR_OVERHANG + 43.0
## Each prop is cut to its painted outline (source pixels) and scaled; its base sits on the floor.
## The breaker uses the corridor's cut and scale (see main.tscn), so both rooms show the same machine.
const BREAKER_REGION: Rect2 = Rect2(81.0, 46.0, 342.0, 433.0)
const BREAKER_SCALE: float = 0.225
const VALVE_REGION: Rect2 = Rect2(3.0, 11.0, 506.0, 490.0)
const VALVE_SCALE: float = 0.2
## The painted wheel (centre and rim radius) and gauge face on the valve image, in source pixels.
const VALVE_WHEEL_CENTRE: Vector2 = Vector2(255.0, 272.0)
const VALVE_WHEEL_RADIUS: float = 92.0
const VALVE_DIAL_CENTRE: Vector2 = Vector2(255.0, 64.0)
const VALVE_DIAL_RADIUS: float = 37.0
## Both door images share one frame on the same canvas, so both are placed from the sealed cut:
## its frame foot (row 713) is on the floor and the blown door's rubble spills just past it.
const DOOR_REGION: Rect2 = Rect2(17.0, 53.0, 478.0, 660.0)
const DOOR_BLOWN_REGION: Rect2 = Rect2(12.0, 44.0, 487.0, 685.0)
## 132 px tall, the height of the door's body; the leaf between the pillars spans the body's 56 px.
const DOOR_SCALE: float = 0.2
## The seam painted down the middle of the leaf, in source pixels.
const DOOR_SEAM_X: float = 255.0
const VENT_REGION: Rect2 = Rect2(8.0, 35.0, 743.0, 183.0)
const ARM_REGION: Rect2 = Rect2(88.0, 9.0, 388.0, 352.0)
## Where the tank was cut out of the tank-arm image.
const TANK_REGION: Rect2 = Rect2(144.0, 361.0, 211.0, 382.0)
const TANK_ART_SCALE: float = 0.22
const ARM_PANEL_REGION: Rect2 = Rect2(79.0, 26.0, 354.0, 463.0)
const ARM_PANEL_SCALE: float = 0.14
const ARM_PANEL_LIGHT: Rect2 = Rect2(206.0, 88.0, 92.0, 20.0)
const BOLT_PANEL_REGION: Rect2 = Rect2(0.0, 68.0, 512.0, 393.0)
const BOLT_PANEL_SCALE: float = 0.15
const BOLT_PANEL_LIGHT: Rect2 = Rect2(222.0, 118.0, 70.0, 20.0)
const HATCH_REGION: Rect2 = Rect2(54.0, 34.0, 403.0, 700.0)
## 144 px tall, the size of the hatch it replaced.
const HATCH_SCALE: float = 0.206
const HATCH_LAMP: Rect2 = Rect2(206.0, 68.0, 92.0, 24.0)
## The hatch sprite lifts this far as it opens, fading out over the open doorway behind it.
const HATCH_LIFT: float = 138.0
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
## The bolt is used from BOLT_X - 40 rightward; its panel stands on the floor in that span, its right
## cables running into the hatch frame.
const BOLT_X: float = 850.0
const BOLT_PANEL_X: float = 806.0
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
## camera y 360) its top (y 298) sits at screen y ~186, below the answer buttons
## (Main.CHOICE_ROW_TOP), and its base (y 382) clears the sentry's scanner fin (Sentry.DRAWN_HEIGHT)
## as it patrols underneath.
const TANK_REST_Y: float = 340.0
const TANK_SIZE: Vector2 = TANK_REGION.size * TANK_ART_SCALE
## The arm's ceiling plate hangs on two rods from the mid plate's overhead gantry (its underside).
const GANTRY_Y: float = 120.0
## The hatch slides open this long after the bolt arcs.
const HATCH_OPEN_SECONDS: float = 0.5
## The sealed door body is this wide; its left face is M0State.JUNCTION_DOOR_LEFT_X.
const DOOR_WIDTH: float = 56.0
const DOOR_HEIGHT: float = 132.0
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
## The door's label sits between the mid plate's gauge box and the wheel painted over the door frame.
const DOOR_LABEL_Y: float = 271.0
## The relief vent's drop runs down the wall to a nozzle over its grate, ending above the caption.
const VENT_NOZZLE_Y: float = 397.0
## The breaker riser stops short of its station label and resumes under it, so it reads as passing
## behind the caption instead of through it.
const BREAKER_RISER_GAP: Vector2 = Vector2(306.0, 336.0)
## The relief vent's painted caption: its baseline start, text and size. It sits just above the
## grate it names and under the drop's nozzle, so no fixture crosses it, and it ends left of the
## junction's closing-shot edge.
const VENT_LABEL_POSITION: Vector2 = Vector2(PressureLine.VENT_GRATE_MIN_X + 3.0, 418.0)
const VENT_LABEL: String = "RELIEF VENT"
const VENT_LABEL_FONT_SIZE: int = 11
## Cuts the turning wheel out of the valve image as a disc, so only the wheel turns over the
## painted one.
const WHEEL_MASK: String = """shader_type canvas_item;
uniform vec2 centre;
uniform float radius;
void fragment() {
	COLOR.a *= 1.0 - smoothstep(radius - 0.006, radius, distance(UV, centre));
}
"""

## Ceiling lamp centres as fractions of the far plate, measured from the plate; the lockdown
## beacons sit on the tops of its two braced pillars.
var lamps: PackedVector2Array = PackedVector2Array([Vector2(0.139, 0.268), Vector2(0.493, 0.268), Vector2(0.857, 0.268)])
var warning_lamps: PackedVector2Array = PackedVector2Array([Vector2(0.294, 0.285), Vector2(0.703, 0.285)])

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
		_sync_hatch()
## Reduced Motion: the charged seam holds a steady glow instead of strobing.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		if is_node_ready():
			_sync_seam()

var depth: RoomDepth
var breaker_art: Sprite2D
var valve_art: Sprite2D
var vent_art: Sprite2D
var arm_art: Sprite2D
var arm_panel_art: Sprite2D
var bolt_panel_art: Sprite2D
var entry_hatch_art: Sprite2D
var hatch_art: Sprite2D
var recesses: Recesses
var door_body: StaticBody2D
var door_shape: CollisionShape2D
var door_visual: Node2D
## The sealed door; the blown one replaces it at the blast.
var door_art: Sprite2D
var door_blown_art: Sprite2D
var valve_wheel: Sprite2D
var vent_steam: CPUParticles2D
var vent_puff: CPUParticles2D
var blast_sparks: CPUParticles2D
var blast_dust: CPUParticles2D
var vent_hazard: Hazard
var cloud_hazard: Hazard
var sentry: Sentry
var tank: TankSprite
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


## The hanging coolant tank, cut from the tank-arm art, with a dent drawn on after a missed drop.
class TankSprite:
	extends Sprite2D
	var dent: Polygon2D
	var dented: bool = false:
		set(value):
			dented = value
			dent.visible = dented

	func _init() -> void:
		dent = Polygon2D.new()
		dent.name = "Dent"
		# In the cut's own pixels around its centre: a crease in the right flank of the body.
		dent.polygon = PackedVector2Array([Vector2(78.0, 30.0), Vector2(50.0, 62.0), Vector2(78.0, 92.0)])
		dent.color = Color("#14242c")
		dent.visible = false
		add_child(dent)


## What sits behind the stations: the ARM PANEL alcove and the open exit doorway, drawn under the
## props (the room's own drawing sits over them).
class Recesses:
	extends Node2D
	var room: JunctionRoom

	func _draw() -> void:
		room.draw_recesses(self)


func _ready() -> void:
	depth = RoomDepth.new()
	depth.name = "Depth"
	depth.painting = JUNCTION_FAR
	depth.mid_painting = JUNCTION_MID
	depth.near_painting = JUNCTION_NEAR
	depth.walkway_y = WALKWAY_Y
	depth.far_drop = FAR_DROP
	depth.near_overhang = NEAR_OVERHANG
	depth.base_color = Color("#0a0e18")
	depth.lamps = lamps
	depth.shaft_lamps = PackedInt32Array([0, 2])
	depth.warning_lamps = warning_lamps
	add_child(depth)
	recesses = Recesses.new()
	recesses.name = "Recesses"
	recesses.room = self
	recesses.z_index = -2
	add_child(recesses)
	breaker_art = RoomDepth.make_prop("BreakerArt", BREAKER_PROP, BREAKER_REGION, BREAKER_SCALE, BREAKER_X)
	vent_art = RoomDepth.make_prop("VentArt", VENT_PROP, VENT_REGION, vent_scale(), (PressureLine.VENT_GRATE_MIN_X + PressureLine.VENT_GRATE_MAX_X) * 0.5)
	valve_art = RoomDepth.make_prop("ValveArt", VALVE_PROP, VALVE_REGION, VALVE_SCALE, VALVE_X)
	arm_panel_art = RoomDepth.make_prop("ArmPanelArt", ARM_PANEL_PROP, ARM_PANEL_REGION, ARM_PANEL_SCALE, ARM_X)
	bolt_panel_art = RoomDepth.make_prop("BoltPanelArt", BOLT_PANEL_PROP, BOLT_PANEL_REGION, BOLT_PANEL_SCALE, BOLT_PANEL_X)
	entry_hatch_art = RoomDepth.make_prop("EntryHatchArt", HATCH_PROP, HATCH_REGION, HATCH_SCALE, ENTRY_X)
	hatch_art = RoomDepth.make_prop("HatchArt", HATCH_PROP, HATCH_REGION, HATCH_SCALE, HATCH_X)
	for prop: Sprite2D in [breaker_art, vent_art, valve_art, arm_panel_art, bolt_panel_art, entry_hatch_art, hatch_art]:
		# One step under this node's own drawing, so the lights and readouts drawn in _draw() sit on the art.
		prop.z_index = -1
		add_child(prop)
		floor_reflections.append(FloorReflection.attach(prop))
	# Only the wheel turns: a disc cut from the same image, over the painted wheel.
	valve_wheel = Sprite2D.new()
	valve_wheel.name = "ValveWheel"
	valve_wheel.texture = VALVE_PROP
	valve_wheel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	valve_wheel.region_enabled = true
	valve_wheel.region_rect = Rect2(VALVE_WHEEL_CENTRE - Vector2.ONE * VALVE_WHEEL_RADIUS, Vector2.ONE * VALVE_WHEEL_RADIUS * 2.0)
	valve_wheel.scale = Vector2.ONE * VALVE_SCALE
	valve_wheel.position = prop_point(valve_art, VALVE_WHEEL_CENTRE)
	valve_wheel.z_index = -1
	var mask: Shader = Shader.new()
	mask.code = WHEEL_MASK
	var wheel_material: ShaderMaterial = ShaderMaterial.new()
	wheel_material.shader = mask
	wheel_material.set_shader_parameter("centre", VALVE_WHEEL_CENTRE / VALVE_PROP.get_size())
	wheel_material.set_shader_parameter("radius", VALVE_WHEEL_RADIUS / VALVE_PROP.get_size().x)
	valve_wheel.material = wheel_material
	add_child(valve_wheel)
	breaker_glow = RoomDepth.make_glow(AMBER, Vector2(64.0, 30.0), 0.5)
	breaker_glow.name = "BreakerGlow"
	breaker_glow.position = BREAKER_LIGHT.get_center()
	breaker_glow.z_index = 1
	add_child(breaker_glow)
	_build_door()
	_build_particles()
	# The hurtbox is the grate: a body touching it is on the vent (PressureLine.is_on_vent).
	# The door blast has no hurtbox; main.gd decides it from PressureLine.is_in_blast alone.
	vent_hazard = Hazard.make("VentHazard", Rect2(PressureLine.VENT_GRATE_MIN_X, 380.0, PressureLine.VENT_GRATE_MAX_X - PressureLine.VENT_GRATE_MIN_X, 60.0), VENT_REASON)
	add_child(vent_hazard)
	breaker_label = _add_station_label("OVERLOAD BREAKER", BREAKER_X, Color("#b0d1de"))
	# Centred a little left of the wheel so its longest text (SEAL CHARGED) ends before the door art.
	valve_label = _add_station_label("VALVE", VALVE_X - VALVE_LABEL_SHIFT, Color("#b0d1de"))
	door_label = _add_station_label("SEALED DOOR", DOOR_X, Color("#ffc7c7"), DOOR_LABEL_Y)
	arm_label = _add_station_label("ARM PANEL", ARM_X, Color("#b0d1de"))
	# Centred between the bolt panel and the hatch so both read as one exit.
	hatch_label = _add_station_label("EXIT BOLTED", (BOLT_PANEL_X + HATCH_X) * 0.5, Color("#8fa6b2"), 276.0)
	_build_lane()
	refresh_state()


## The relief vent is drawn exactly as wide as its grate's hurtbox (PressureLine.VENT_GRATE_*), so
## what is drawn is what hurts.
static func vent_scale() -> float:
	return (PressureLine.VENT_GRATE_MAX_X - PressureLine.VENT_GRATE_MIN_X) / VENT_REGION.size.x


## Where [param source] (a pixel of [param prop]'s image) is in this room.
static func prop_point(prop: Sprite2D, source: Vector2) -> Vector2:
	return prop.position + (source - prop.region_rect.get_center()) * prop.scale


## [param source] (a rectangle of [param prop]'s image) in this room.
static func prop_rect(prop: Sprite2D, source: Rect2) -> Rect2:
	return Rect2(prop_point(prop, source.position), source.size * prop.scale)


## The door: the painted seal over a 56x132 body on the floor layer, swapped for the blown frame at
## the blast. The visual is pivoted at the floor so the blast can jolt it.
func _build_door() -> void:
	door_body = StaticBody2D.new()
	door_body.name = "Door"
	door_body.position = Vector2(DOOR_X, FLOOR_Y - DOOR_HEIGHT * 0.5)
	door_body.collision_layer = 2
	door_body.collision_mask = 0
	door_shape = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = Vector2(DOOR_WIDTH, DOOR_HEIGHT)
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
	door_art = RoomDepth.make_prop("DoorArt", DOOR_SEALED_PROP, DOOR_REGION, DOOR_SCALE, 0.0, 0.0)
	door_visual.add_child(door_art)
	door_blown_art = RoomDepth.make_prop("DoorBlownArt", DOOR_BLOWN_PROP, DOOR_BLOWN_REGION, DOOR_SCALE, 0.0, 0.0)
	# Same canvas as the sealed door, so the frames line up.
	door_blown_art.position = door_art.position + (DOOR_BLOWN_REGION.get_center() - DOOR_REGION.get_center()) * DOOR_SCALE
	door_blown_art.visible = false
	door_visual.add_child(door_blown_art)
	for art: Sprite2D in [door_art, door_blown_art]:
		floor_reflections.append(FloorReflection.attach(art))
	seam_glow = RoomDepth.make_glow(AMBER, Vector2(44.0, 140.0), 0.0)
	seam_glow.name = "SeamGlow"
	seam_glow.position = Vector2(DOOR_X + (DOOR_SEAM_X - DOOR_REGION.get_center().x) * DOOR_SCALE, FLOOR_Y - DOOR_HEIGHT * 0.5)
	seam_glow.z_index = 2
	add_child(seam_glow)


func _build_particles() -> void:
	vent_steam = FxPresets.steam()
	vent_steam.name = "VentSteam"
	vent_steam.position = Vector2(VENT_X, FLOOR_Y - 8.0)
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
	blast_sparks.position = Vector2(DOOR_X, FLOOR_Y - DOOR_HEIGHT * 0.5)
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
	floor_reflections.append_array(sentry.floor_reflections)
	tank = TankSprite.new()
	tank.name = "Tank"
	tank.texture = TANK_PROP
	tank.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tank.scale = Vector2.ONE * TANK_ART_SCALE
	tank.position = Vector2(DropArm.MARK_X, TANK_REST_Y)
	tank.z_index = 1
	add_child(tank)
	# The arm stays where the tank-arm image put it relative to the tank: centred over the mark,
	# its shackle on the tank's cut line.
	arm_art = Sprite2D.new()
	arm_art.name = "ArmArt"
	arm_art.texture = ARM_PROP
	arm_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	arm_art.region_enabled = true
	arm_art.region_rect = ARM_REGION
	arm_art.scale = Vector2.ONE * TANK_ART_SCALE
	arm_art.position = tank.position + (ARM_REGION.get_center() - TANK_REGION.get_center()) * TANK_ART_SCALE
	arm_art.z_index = 1
	add_child(arm_art)
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
	bolt_sparks.position = prop_rect(bolt_panel_art, BOLT_PANEL_LIGHT).get_center()
	bolt_sparks.amount = 30
	bolt_sparks.z_index = 3
	add_child(bolt_sparks)


## The font the station labels resolve from the project theme; the painted vent caption uses it too.
func caption_font() -> Font:
	return breaker_label.get_theme_font(&"font") if breaker_label != null else ThemeDB.fallback_font


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
	# The VALVE label counts the turns, so a crank refreshes it as well as a phase change.
	if line_state != previous_state or turns != previous_turns:
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
	# A tank coming down on the sentry stops on its crushed hull, so the wreck shows under it.
	var on_sentry: bool = arm.state == &"landed" or (arm.state == &"falling" and DropArm.is_hit(sentry.target_x))
	tank.position.y = lerpf(TANK_REST_Y, landed_tank_y(on_sentry), tank_drop)
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


## Where the tank's centre comes to rest: on the floor, or on top of the crushed sentry.
static func landed_tank_y(on_sentry: bool) -> float:
	return FLOOR_Y - TANK_SIZE.y * 0.5 - (Sentry.WRECK_CRUSH_HEIGHT if on_sentry else 0.0)


## The tank came down on the sentry at [param at_x]: the coolant and spark bursts (fired through the
## impact kit) are moved there and the sentry is crushed into its wreck under the tank.
func tank_hit(at_x: float) -> void:
	sentry_down = true
	coolant_burst.position.x = at_x
	hit_sparks.position.x = at_x
	sentry.keel_over(at_x)
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


## The door going: the seal is swapped for the torn frame and its rubble, which jolts and settles,
## sparks and dust fly, and the blast zone is dangerous for a moment.
func door_blast() -> void:
	door_blown = true
	vent_hazard.armed = false
	door_shape.set_deferred("disabled", true)
	blast_sparks.restart()
	blast_dust.restart()
	if _door_tween != null and _door_tween.is_valid():
		_door_tween.kill()
	_show_door()
	door_visual.scale = Vector2(1.06, 0.9)
	_door_tween = create_tween()
	_door_tween.tween_property(door_visual, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	refresh_state()


## The sealed door until the blast, the blown frame after it.
func _show_door() -> void:
	door_art.visible = not door_blown
	door_blown_art.visible = door_blown


## The exit hatch lifts and fades as it opens, over the doorway Recesses draws behind it.
func _sync_hatch() -> void:
	if hatch_art == null:
		return
	hatch_art.position.y = RoomDepth.FLOOR_Y - HATCH_REGION.size.y * HATCH_SCALE * 0.5 - HATCH_LIFT * hatch_open
	hatch_art.modulate.a = 1.0 - hatch_open
	hatch_art.visible = hatch_open < 1.0
	recesses.queue_redraw()
	queue_redraw()


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
	tank.position.y = lerpf(TANK_REST_Y, landed_tank_y(sentry_down), tank_drop)
	bolt_state = &"open" if junction_cleared else &"locked"
	bolt_charge = 0.0
	hatch_open = 1.0 if junction_cleared else 0.0
	# A blown door left the wheel at its third quarter; a restored save shows it the same way.
	valve_wheel.rotation_degrees = 90.0 * PressureLine.TURNS_NEEDED if door_blown else 0.0
	door_visual.scale = Vector2.ONE
	_show_door()
	door_shape.set_deferred("disabled", not visible or door_blown)
	line_state = &"idle"
	gauge = 0.0
	turns = 0
	refresh_state()


func _draw() -> void:
	# The plates are the Depth child's layers and the machines are sprites; this draws what they
	# cannot show.
	_draw_hatch_lamp(entry_hatch_art, GREEN, 1.0)
	_draw_pressure_line()
	_draw_vent()
	_draw_gauge_and_lights()
	_draw_breaker_light()
	if door_blown:
		draw_line(Vector2(RUBBLE_X - 6.0, 439.0), Vector2(RUBBLE_X + 6.0, 439.0), AMBER, 3.0)
	_draw_arm_panel_light()
	_draw_arm()
	_draw_floor_mark()
	_draw_hatch_lamp(hatch_art, _bolt_light_color(), 1.0 - hatch_open)
	draw_rect(prop_rect(bolt_panel_art, BOLT_PANEL_LIGHT), _bolt_light_color())


## The alcove behind the ARM PANEL and the doorway behind the exit hatch, drawn on [param canvas]
## (Recesses, under the props).
func draw_recesses(canvas: CanvasItem) -> void:
	# The engineer standing in the alcove is out of the sentry's sight. Its width is exactly
	# SentryBrain's cover span widened by half the engineer's body.
	var alcove: Rect2 = Rect2(SentryBrain.COVER_MIN_X - M0State.HUMAN_HALF_WIDTH, 318.0, SentryBrain.COVER_MAX_X - SentryBrain.COVER_MIN_X + M0State.HUMAN_HALF_WIDTH * 2.0, FLOOR_Y - 318.0)
	canvas.draw_rect(alcove, Color(0.02, 0.05, 0.08, 0.72))
	# A lit lip along the top so it reads as a recess, not a door.
	canvas.draw_rect(Rect2(alcove.position, Vector2(alcove.size.x, 4.0)), Color("#263540"))
	canvas.draw_rect(alcove, STEEL, false, 2.0)
	if hatch_open > 0.0:
		# The service line beyond the exit: dark, with a faint green work light.
		var doorway: Rect2 = Rect2(HATCH_X - 32.0, 300.0, 64.0, 138.0)
		canvas.draw_rect(doorway, Color("#06111a"))
		canvas.draw_rect(doorway, Color(GREEN, 0.12 * hatch_open))
		canvas.draw_rect(doorway.grow(4.0), STEEL, false, 3.0)


## A hatch's lamp, painted on the bar over its door, lit in [param color]; it rides and fades with
## the hatch as it lifts.
func _draw_hatch_lamp(hatch: Sprite2D, color: Color, alpha: float) -> void:
	if alpha > 0.0:
		draw_rect(prop_rect(hatch, HATCH_LAMP), Color(color, alpha))


## The coolant line runs along the wall from the breaker past the vent and valve into the door;
## it warms with the gauge so the pressure is visible along its whole length.
func _draw_pressure_line() -> void:
	var pressure: Color = DIM.lerp(AMBER, gauge) if line_state == &"building" else (SEAM_RED if line_state == &"tripped" else DIM)
	var y: float = 292.0
	var dial_top: float = prop_point(valve_art, VALVE_DIAL_CENTRE).y - VALVE_DIAL_RADIUS * VALVE_SCALE - 2.0
	draw_line(Vector2(BREAKER_X, y), Vector2(BREAKER_X, BREAKER_RISER_GAP.x), Color("#263540"), 10.0)
	draw_line(Vector2(BREAKER_X, BREAKER_RISER_GAP.y), Vector2(BREAKER_X, 346.0), Color("#263540"), 10.0)
	draw_line(Vector2(BREAKER_X, y), Vector2(DOOR_X - 24.0, y), Color("#263540"), 10.0)
	draw_line(Vector2(VENT_X, y), Vector2(VENT_X, VENT_NOZZLE_Y), Color("#263540"), 8.0)
	draw_line(Vector2(VALVE_X, y), Vector2(VALVE_X, dial_top), Color("#263540"), 8.0)
	draw_line(Vector2(BREAKER_X, y), Vector2(DOOR_X - 24.0, y), pressure, 3.0)
	draw_line(Vector2(VENT_X, y), Vector2(VENT_X, VENT_NOZZLE_Y), pressure, 2.0)
	draw_line(Vector2(VALVE_X, y), Vector2(VALVE_X, dial_top), pressure, 2.0)


## The relief vent's nozzle light (it warms with the gauge) and its painted caption.
func _draw_vent() -> void:
	var vent_light: Color = SEAM_RED if line_state == &"tripped" else (DIM.lerp(AMBER, gauge) if line_state == &"building" else DIM)
	draw_rect(Rect2(VENT_X - 13.0, VENT_NOZZLE_Y, 26.0, 5.0), vent_light)
	draw_string(caption_font(), VENT_LABEL_POSITION, VENT_LABEL, HORIZONTAL_ALIGNMENT_LEFT, -1, VENT_LABEL_FONT_SIZE, Color("#8fa6b2"))


## The needle over the valve's painted gauge is the gauge (left at empty, right at the vent's
## peak), and three lights in a box left of the gauge go green per real turn.
func _draw_gauge_and_lights() -> void:
	var centre: Vector2 = prop_point(valve_art, VALVE_DIAL_CENTRE)
	var face: float = VALVE_DIAL_RADIUS * VALVE_SCALE
	# A fresh face over the painted one, so its painted needle never reads as a second reading.
	draw_circle(centre, face - 0.6, Color("#d9d3c4"))
	draw_arc(centre, face - 1.6, PI + PI * 0.78, TAU, 8, SEAM_RED, 1.6, true)
	var angle: float = PI + PI * gauge
	draw_line(centre, centre + Vector2.RIGHT.rotated(angle) * (face - 1.2), Color("#1a1c20"), 1.4, true)
	draw_circle(centre, 1.2, Color("#1a1c20"))
	var box: Rect2 = Rect2(VALVE_X - 47.0, 344.0, 16.0, 38.0)
	draw_rect(box, Color("#141c24"))
	draw_rect(box, STEEL, false, 1.0)
	for light: int in PressureLine.TURNS_NEEDED:
		var rect: Rect2 = Rect2(box.position.x + 3.0, box.position.y + 4.0 + light * 11.0, 10.0, 7.0)
		draw_rect(rect, GREEN if light < turns or door_blown else Color("#1f2a33"))


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


## The ARM PANEL's light: green while the tank hangs ready, amber while the arm is busy, dark once
## the sentry is down.
func _draw_arm_panel_light() -> void:
	var light: Color = DIM if sentry_down else (GREEN if arm_state == &"hung" else AMBER)
	draw_rect(prop_rect(arm_panel_art, ARM_PANEL_LIGHT), light)


## The rods that hang the arm's ceiling plate from the gantry, and the cable from its shackle down
## to the tank once the clamp has let go: taut while the tank falls or winches back up, slack once
## it has landed.
func _draw_arm() -> void:
	var plate_top: float = arm_art.position.y - ARM_REGION.size.y * TANK_ART_SCALE * 0.5 + 2.0
	for rod_x: float in [DropArm.MARK_X - 26.0, DropArm.MARK_X + 34.0]:
		draw_line(Vector2(rod_x, GANTRY_Y), Vector2(rod_x, plate_top), Color("#1b2630"), 5.0)
		draw_line(Vector2(rod_x - 1.5, GANTRY_Y), Vector2(rod_x - 1.5, plate_top), STEEL, 1.0)
	if tank_drop <= 0.0:
		return
	var cable_top: Vector2 = Vector2(DropArm.MARK_X, TANK_REST_Y - TANK_SIZE.y * 0.5)
	var tank_top: Vector2 = Vector2(DropArm.MARK_X, tank.position.y - TANK_SIZE.y * 0.5)
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


## The exit bolt's light, on its panel and over the hatch: red and dead while the sentry runs the
## line, amber once it can take the overload, warming to white through the whine, green once popped.
func _bolt_light_color() -> Color:
	if junction_cleared or bolt_state == &"open":
		return GREEN
	if bolt_state == &"charging":
		return AMBER.lerp(Color.WHITE, bolt_charge)
	if sentry_down:
		return AMBER
	return SEAM_RED
