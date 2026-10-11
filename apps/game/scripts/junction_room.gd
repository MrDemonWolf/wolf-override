extends Node2D
class_name JunctionRoom
## Blowback: the Service Junction, the third 960 px room after the Records exit, built from its own
## layered set (RoomDepth) and painted station props, with the corridor's breaker and a pressure
## bulkhead for its door. What the art cannot show is drawn over it here from the state the parent
## mirrors in (PressureLine, DropArm, SentryBrain): the LINE gauge's needle, the vent and seam glows,
## the hazard stripes over the door's blast zone while the fuse burns, the panel and hatch lights, the
## alcove's shadow and floor, the passage behind the exit hatch, the floor brackets (lit while the
## sentry's body is inside them) with the tank's shadow, the rubble line and the winch cable. Station
## names sit on small plates in one row of clear wall (the vent's on the floor by its grate), and a
## plate cut by the edge of the view fades out rather than show part of its name. What pulses follows
## the mirrored state (the fuse, the gauge), not a timer of its own.

## The exit hatch has finished sliding open after the bolt arcs (bolt_arc).
signal hatch_opened

const JUNCTION_FAR: Texture2D = preload("res://assets/rooms/junction-far.png")
const JUNCTION_MID: Texture2D = preload("res://assets/rooms/junction-mid.png")
const JUNCTION_NEAR: Texture2D = preload("res://assets/rooms/junction-near.png")
const BREAKER_PROP: Texture2D = preload("res://assets/props/corridor-breaker.png")
const VALVE_PROP: Texture2D = preload("res://assets/props/junction-valve.png")
## The pressure bulkhead (design A): sealed, breaking for a moment at the blast, then blown open on
## the passage beyond, with its front pillar drawn again over the actors.
const DOOR_SEALED_PROP: Texture2D = preload("res://assets/props/junction-bulkhead-sealed.png")
const DOOR_BREAKING_PROP: Texture2D = preload("res://assets/props/junction-bulkhead-breaking.png")
const DOOR_BLOWN_PROP: Texture2D = preload("res://assets/props/junction-bulkhead-blown.png")
const DOOR_LIP_PROP: Texture2D = preload("res://assets/props/junction-bulkhead-front-lip.png")
const VENT_PROP: Texture2D = preload("res://assets/props/junction-relief-vent.png")
const ARM_PROP: Texture2D = preload("res://assets/props/junction-tank-arm.png")
## The tank cut out of the tank-arm image (rows 361..743), so it can fall away from the arm.
const TANK_PROP: Texture2D = preload("res://assets/props/junction-tank.png")
const ARM_PANEL_PROP: Texture2D = preload("res://assets/props/junction-arm-panel.png")
const BOLT_PANEL_PROP: Texture2D = preload("res://assets/props/junction-bolt-panel.png")
const HATCH_PROP: Texture2D = preload("res://assets/props/junction-hatch.png")
## The open exit hatch shows a painted service passage: this cut of the open corridor bulkhead's
## doorway (its floor, wall lamps and the light far down the line), drawn a little darker.
const HATCH_PASSAGE_PROP: Texture2D = preload("res://assets/props/corridor-bulkhead-open.png")
const HATCH_PASSAGE: Rect2 = Rect2(172.0, 300.0, 110.0, 253.0)
const HATCH_PASSAGE_TINT: Color = Color(0.78, 0.84, 0.86)
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
## Every door image (and the front lip) shares one registered canvas whose bottom row is the floor,
## so all of them use this cut: 181 px tall at RoomDepth.BULKHEAD_SCALE, with the front pillar's
## outer edge on the door body's face (M0State.JUNCTION_DOOR_LEFT_X).
const DOOR_REGION: Rect2 = Rect2(0.0, 36.0, 384.0, 604.0)
const DOOR_SCALE: float = RoomDepth.BULKHEAD_SCALE
## The seam painted down the sealed leaf, in canvas pixels.
const DOOR_SEAM_X: float = 196.0
## How long the breaking bulkhead shows at the blast before the blown one replaces it.
const DOOR_BREAK_SECONDS: float = 0.15
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
## The exit hatch's leaf (its inner door, in source pixels): it slides up into the frame as the hatch
## opens, over the dark passage behind it, while the frame and its lamp stay.
const HATCH_LEAF: Rect2 = Rect2(150.0, 142.0, 216.0, 498.0)
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
## The TANK RELEASE sits in the middle of the alcove that hides the engineer from the sentry.
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
## Where WOLF stands when he chooses to draw the sentry: at the lip of the rubble with only his front
## over the lane line, so he never walks through the machine and his drawn body stays clear of the
## engineer at the TANK RELEASE, the floor brackets and the tank. It parks BAIT_OFFSET
## past him, on the mark, facing him.
const WOLF_BAIT_X: float = DropArm.MARK_X - SentryBrain.BAIT_OFFSET
## Where WOLF waits while the line builds and the fuse burns: back by the entrance, his drawn body
## (M0Actor.WOLF_REACH) clear of the engineer at the breaker, so it is nowhere near the relief vent's
## grate, its steam or the door's blast zone.
const WOLF_CLEAR_X: float = BREAKER_X - M0Actor.HUMAN_REACH - M0Actor.WOLF_REACH - 2.0
## The engineer's front foot on the rubble line: where the question of how to drop the tank comes up,
## still outside the sentry's lane.
const CHOICE_X: float = RUBBLE_X - M0State.HUMAN_HALF_WIDTH
## The tank hangs centred here and lands with its base on the floor. At the play framing (zoom 1.35,
## camera y 360) its top (y 298) sits at screen y ~186, below the answer buttons
## (Main.CHOICE_ROW_TOP), and its base (y 382) clears the sentry's scanner fin (Sentry.DRAWN_HEIGHT)
## as it patrols underneath.
const TANK_REST_Y: float = 340.0
const TANK_SIZE: Vector2 = TANK_REGION.size * TANK_ART_SCALE
## The middle of the tank's shadow: on the floor stripes under it.
const SHADOW_Y: float = FLOOR_Y + 1.0
## The arm's ceiling plate hangs on two rods from the mid plate's overhead gantry (its underside).
const GANTRY_Y: float = 120.0
## The hatch slides open this long after the bolt arcs.
const HATCH_OPEN_SECONDS: float = 0.5
## The sealed door body is this wide; its left face is M0State.JUNCTION_DOOR_LEFT_X.
const DOOR_WIDTH: float = 56.0
const DOOR_HEIGHT: float = 132.0
## The bulkhead draws one step under the actors (this node sits at z 1), its front pillar one step
## over them, so they pass through the doorway once it is open.
const DOOR_Z: int = 0
const DOOR_LIP_Z: int = 2
## How long the grate stays dangerous after the relief vent lets go.
const HAZARD_SECONDS: float = 0.4
const VENT_REASON: String = "The relief vent let go under you. Stand clear of the grate when the gauge peaks."
## Formatted with the engineer's first name.
const BLAST_REASON: String = "The door went with %s in front of it. When the fuse lights, back away past the valve."
const SENTRY_REASON: String = "The sentry ran you down in its lane. Cross when it faces away, or get back over the rubble."
const CLOUD_REASON: String = "The coolant cloud caught you. Let it clear before you cross the mark."
const AMBER: Color = Color("#f3ae4b")
const GREEN: Color = Color("#a4f0c4")
const DIM: Color = Color("#3e4f5a")
const STEEL: Color = Color("#4a6572")
const COOLANT: Color = Color("#7fe8ff")
const SEAM_RED: Color = Color("#ff6a55")
## The tank's cable, in the tones of the cable painted on the arm's winch drum.
const CABLE_SHADOW: Color = Color("#0d1419")
const CABLE_BODY: Color = Color("#35434c")
const CABLE_SHEEN: Color = Color(0.55, 0.64, 0.7, 0.55)
## Station name plates: their top edge, all in one row of clear wall between the far plate's pipe run
## and the machines' tops, and their text size.
const LABEL_Y: float = 320.0
const LABEL_FONT_SIZE: int = 12
## The VALVE plate sits this far left of the wheel so its longest text ends well before the bulkhead.
const VALVE_LABEL_SHIFT: float = 28.0
## The breaker's plate sits this far left of the breaker, and the RELIEF VENT plate this far left of
## the grate's centre, so the vent's name fits between the longest breaker and valve texts.
const BREAKER_LABEL_SHIFT: float = 12.0
const VENT_LABEL_SHIFT: float = 3.0
## The door's placard sits across the bulkhead's leaf, this far right of its centre, over its pillar.
const DOOR_LABEL_SHIFT: float = 7.0
## The TANK RELEASE plate sits right of the panel, clear of the bulkhead's frame and the door's placard.
const ARM_LABEL_SHIFT: float = 20.0
## The EXIT plate sits over the bolt panel, left of the hatch it also names.
const EXIT_LABEL_X: float = 792.0
## A plate fades out over this many px as it reaches the edge of the view.
const LABEL_EDGE_FADE: float = 14.0
const LABEL_PLATE: Color = Color(0.035, 0.06, 0.08, 0.8)
const LABEL_PLATE_EDGE: Color = Color(0.29, 0.4, 0.45, 0.55)
const VENT_LABEL: String = "RELIEF VENT"
## The glow over the vent grate, warming with the gauge, flashing red through its hard warning and red
## once it has tripped.
const VENT_GLOW_SIZE: Vector2 = Vector2(96.0, 22.0)
## The vent's hard warning flashes this many times a second (steady with Reduced Motion).
const VENT_FLASH_HZ: float = 5.0
## After the vent lets go the needle stays pinned at the top, red, for HAZARD_SECONDS (and through a
## knockdown, when nothing advances it), then falls back to empty over this long.
const GAUGE_FALL_SECONDS: float = 0.8
## The caption beside the valve's dial, the gauge the narration names.
const LINE_CAPTION: String = "LINE"
const LINE_CAPTION_FONT_SIZE: int = 8
## The hazard stripes over the door's blast zone pulse this many times a second while the fuse burns
## (steady with Reduced Motion).
const BLAST_STRIPE_HZ: float = 4.0
## The floor brackets glow this colour while the sentry's body is inside them.
const MARK_LIT: Color = Color("#ffe9a8")
## The alcove's floor is tinted over exactly the span that hides the engineer.
const ALCOVE_FLOOR: Color = Color(0.25, 0.55, 0.62, 0.16)
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
## Mirrored from PressureLine: seconds left on the fuse, which drives the blast stripes' pulse.
var fuse_remaining: float = 0.0
## The needle's reading: the gauge while it builds, pinned at the top for a while after the vent lets
## go (gauge_hold seconds left), then falling back; gauge_tripped draws it red meanwhile.
var display_gauge: float = 0.0
var gauge_hold: float = 0.0
var gauge_tripped: bool = false
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
## The sealed door; at the blast the breaking one shows for DOOR_BREAK_SECONDS, then the blown one.
var door_art: Sprite2D
var door_breaking_art: Sprite2D
var door_blown_art: Sprite2D
## The bulkhead's front pillar, drawn over the actors.
var door_lip: Sprite2D
## True from the blast until the breaking frame gives way to the blown one.
var door_breaking: bool = false
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
## TANK DOWN, over the tank once it lies on the sentry.
var tank_label: Label
## The LINE caption beside the valve's dial.
var line_caption: Label
var hatch_label: Label
var breaker_glow: Sprite2D
var seam_glow: Sprite2D
var vent_glow: Sprite2D
var hatch_doorway: HatchDoorway
var breaker_label: Label
var valve_label: Label
var door_label: Label
## The relief vent's floor caption, on the same plate, just above its grate.
var vent_label: Label
var station_labels: Array[Label] = []
var label_plate: StyleBoxFlat
## The alcove's soft shadow, made once and kept so the drawing that uses it always has it.
var alcove_shadow: GradientTexture2D = soft_texture(GradientTexture2D.FILL_SQUARE)
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


## What sits behind the stations: the shadow of the TANK RELEASE alcove, drawn under the props (the
## room's own drawing sits over them).
class Recesses:
	extends Node2D
	var room: JunctionRoom

	func _draw() -> void:
		room.draw_recesses(self)


## The exit hatch's doorway over its painted leaf: once the hatch starts to open it draws the painted
## passage beyond (HATCH_PASSAGE), with a faint green work light, and the leaf (cut from the same art
## as the hatch) slides up inside it into the frame's header, clipped to the doorway. Shut, it draws
## nothing, so the hatch art shows as painted.
class HatchDoorway:
	extends Node2D
	var size: Vector2
	var open: float = 0.0:
		set(value):
			open = value
			leaf.position.y = size.y * 0.5 - open * size.y
			queue_redraw()
	var leaf: Sprite2D
	var light: GradientTexture2D

	func _init(texture: Texture2D, region: Rect2, leaf_scale: float) -> void:
		size = region.size * leaf_scale
		clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		leaf = Sprite2D.new()
		leaf.name = "Leaf"
		leaf.texture = texture
		leaf.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		leaf.region_enabled = true
		leaf.region_rect = region
		leaf.scale = Vector2.ONE * leaf_scale
		leaf.position = Vector2(size.x * 0.5, size.y * 0.5)
		add_child(leaf)
		light = JunctionRoom.soft_texture(GradientTexture2D.FILL_RADIAL)

	func _draw() -> void:
		if open <= 0.0:
			return
		draw_texture_rect_region(JunctionRoom.HATCH_PASSAGE_PROP, Rect2(Vector2.ZERO, size), JunctionRoom.HATCH_PASSAGE, JunctionRoom.HATCH_PASSAGE_TINT)
		draw_texture_rect(light, Rect2(size.x * 0.05, size.y * 0.1, size.x * 0.9, size.y * 0.7), false, Color(JunctionRoom.GREEN, 0.12 * open))


func _ready() -> void:
	depth = RoomDepth.new()
	depth.name = "Depth"
	depth.painting = JUNCTION_FAR
	depth.mid_painting = JUNCTION_MID
	depth.near_painting = JUNCTION_NEAR
	depth.walkway_y = WALKWAY_Y
	depth.far_drop = FAR_DROP
	depth.near_overhang = NEAR_OVERHANG
	depth.near_column_width = 200.0
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
	# The exit hatch's leaf and the passage behind it, over the hatch art.
	hatch_doorway = HatchDoorway.new(HATCH_PROP, HATCH_LEAF, HATCH_SCALE)
	hatch_doorway.name = "HatchDoorway"
	hatch_doorway.position = prop_point(hatch_art, HATCH_LEAF.position)
	hatch_doorway.z_index = -1
	add_child(hatch_doorway)
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
	vent_glow = RoomDepth.make_glow(AMBER, VENT_GLOW_SIZE, 0.0)
	vent_glow.name = "VentGlow"
	vent_glow.position = Vector2(VENT_X, FLOOR_Y - 6.0)
	vent_glow.z_index = 1
	add_child(vent_glow)
	_build_door()
	_build_particles()
	# The hurtbox is the grate: a body touching it is on the vent (PressureLine.is_on_vent).
	# The door blast has no hurtbox; main.gd decides it from PressureLine.is_in_blast alone.
	vent_hazard = Hazard.make("VentHazard", Rect2(PressureLine.VENT_GRATE_MIN_X, 380.0, PressureLine.VENT_GRATE_MAX_X - PressureLine.VENT_GRATE_MIN_X, 60.0), VENT_REASON)
	add_child(vent_hazard)
	label_plate = StyleBoxFlat.new()
	label_plate.bg_color = LABEL_PLATE
	label_plate.border_color = LABEL_PLATE_EDGE
	label_plate.set_border_width_all(1)
	label_plate.set_corner_radius_all(2)
	label_plate.content_margin_left = 5.0
	label_plate.content_margin_right = 5.0
	label_plate.content_margin_top = 0.0
	label_plate.content_margin_bottom = 0.0
	breaker_label = _add_station_label("OVERLOAD BREAKER", BREAKER_X - BREAKER_LABEL_SHIFT, Color("#b0d1de"))
	# In the row above the grate, where nobody standing on the floor covers it.
	vent_label = _add_station_label(VENT_LABEL, VENT_X - VENT_LABEL_SHIFT, Color("#8fa6b2"))
	# A little left of the wheel so its longest text ends before the bulkhead.
	valve_label = _add_station_label("VALVE", VALVE_X - VALVE_LABEL_SHIFT, Color("#b0d1de"))
	# A placard across the bulkhead's face, over its front pillar.
	door_label = _add_station_label("SEALED DOOR", door_visual.position.x + DOOR_LABEL_SHIFT, Color("#ffc7c7"))
	door_label.z_index = DOOR_LIP_Z + 1
	arm_label = _add_station_label("TANK RELEASE", ARM_X + ARM_LABEL_SHIFT, Color("#b0d1de"))
	# Over the landed tank, shown only once it lies on the sentry.
	tank_label = _add_station_label("TANK DOWN", DropArm.MARK_X, Color("#8fa6b2"))
	line_caption = Label.new()
	line_caption.name = "LineCaption"
	line_caption.text = LINE_CAPTION
	line_caption.add_theme_font_size_override("font_size", LINE_CAPTION_FONT_SIZE)
	line_caption.add_theme_color_override("font_color", Color("#b0d1de"))
	line_caption.add_theme_stylebox_override("normal", label_plate)
	line_caption.z_index = 1
	add_child(line_caption)
	line_caption.size = line_caption.get_combined_minimum_size()
	# Just left of the dial, level with it.
	var dial: Vector2 = prop_point(valve_art, VALVE_DIAL_CENTRE)
	line_caption.position = Vector2(dial.x - VALVE_DIAL_RADIUS * VALVE_SCALE - 2.0 - line_caption.size.x, dial.y - line_caption.size.y * 0.5)
	# Over the bolt panel, beside the hatch, so both read as one exit.
	hatch_label = _add_station_label("EXIT BOLTED", EXIT_LABEL_X, Color("#8fa6b2"))
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


## The door: the sealed bulkhead over a 56x132 body on the floor layer, its front pillar on the
## body's face; at the blast it breaks and then stands blown open on the passage beyond. The visual is
## pivoted at the floor so the blast can jolt it; the front lip rides with it, drawn over the actors.
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
	door_visual.position = Vector2(RoomDepth.bulkhead_center_x(DOOR_REGION, M0State.JUNCTION_DOOR_LEFT_X), FLOOR_Y)
	door_visual.z_index = DOOR_Z
	add_child(door_visual)
	door_art = RoomDepth.make_prop("DoorArt", DOOR_SEALED_PROP, DOOR_REGION, DOOR_SCALE, 0.0, 0.0)
	door_breaking_art = RoomDepth.make_prop("DoorBreakingArt", DOOR_BREAKING_PROP, DOOR_REGION, DOOR_SCALE, 0.0, 0.0)
	door_blown_art = RoomDepth.make_prop("DoorBlownArt", DOOR_BLOWN_PROP, DOOR_REGION, DOOR_SCALE, 0.0, 0.0)
	for art: Sprite2D in [door_art, door_breaking_art, door_blown_art]:
		art.visible = art == door_art
		door_visual.add_child(art)
		floor_reflections.append(FloorReflection.attach(art))
	door_lip = RoomDepth.make_prop("DoorLip", DOOR_LIP_PROP, DOOR_REGION, DOOR_SCALE, 0.0, 0.0)
	door_lip.z_index = DOOR_LIP_Z
	door_visual.add_child(door_lip)
	var leaf_height: float = DOOR_REGION.size.y * DOOR_SCALE * 0.8
	seam_glow = RoomDepth.make_glow(AMBER, Vector2(40.0, leaf_height), 0.0)
	seam_glow.name = "SeamGlow"
	seam_glow.position = Vector2(door_visual.position.x + (DOOR_SEAM_X - DOOR_REGION.get_center().x) * DOOR_SCALE, FLOOR_Y - DOOR_REGION.size.y * DOOR_SCALE * 0.5)
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


## A station name on its plate, centred on [param center_x] in the label row. It draws over the
## bulkhead and under the actors.
func _add_station_label(caption: String, center_x: float, tint: Color) -> Label:
	var label: Label = Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_stylebox_override("normal", label_plate)
	label.z_index = 1
	label.set_meta(&"center_x", center_x)
	add_child(label)
	station_labels.append(label)
	_fit_label(label)
	return label


## Shrinks [param label]'s plate to its text and centres it on its station again.
func _fit_label(label: Label) -> void:
	label.size = Vector2.ZERO
	label.size = label.get_combined_minimum_size()
	label.position = Vector2(float(label.get_meta(&"center_x")) - label.size.x * 0.5, LABEL_Y)


## A plate the edge of the view cuts would show part of a name: it fades out as it reaches the edge.
func _process(_delta: float) -> void:
	if not visible:
		return
	var viewport: Viewport = get_viewport()
	var view: Rect2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	for label: Label in station_labels:
		var rect: Rect2 = label.get_global_rect()
		var margin: float = minf(rect.position.x - view.position.x, view.end.x - rect.end.x)
		label.modulate.a = clampf(margin / LABEL_EDGE_FADE, 0.0, 1.0)


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
	fuse_remaining = line.fuse_remaining
	if line_state == &"building":
		display_gauge = gauge
		gauge_tripped = false
		gauge_hold = 0.0
	elif line_state == &"tripped" and previous_state == &"building":
		# The vent let go at the top of the gauge: the needle stays there, red, while the grate hurts.
		display_gauge = 1.0
		gauge_tripped = true
		gauge_hold = HAZARD_SECONDS
	elif not gauge_tripped:
		display_gauge = gauge
	if turns != previous_turns:
		_turn_wheel(turns)
	# The VALVE label counts the turns, so a crank refreshes it as well as a phase change.
	if line_state != previous_state or turns != previous_turns:
		refresh_state()
	var building: bool = line_state == &"building"
	# Steam only near the top of the gauge, thickening toward the peak.
	var steam: float = inverse_lerp(PressureLine.STEAM_GAUGE, 1.0, gauge)
	vent_steam.emitting = building and steam >= 0.0 and visible
	vent_steam.initial_velocity_max = lerpf(60.0, 220.0, clampf(steam, 0.0, 1.0))
	vent_steam.scale_amount_max = lerpf(6.0, 16.0, clampf(steam, 0.0, 1.0))
	vent_steam.modulate.a = lerpf(0.45, 1.0, clampf(steam, 0.0, 1.0))
	if building:
		seam_glow.modulate = Color(AMBER, 0.25 + 0.5 * gauge)
	_sync_vent_glow()
	queue_redraw()


## Advances the needle's fall after the vent lets go; the parent calls it every junction frame, so it
## holds still through a knockdown, when nothing does.
func advance_display(delta: float) -> void:
	if not gauge_tripped:
		return
	if gauge_hold > 0.0:
		gauge_hold = maxf(gauge_hold - delta, 0.0)
		return
	display_gauge = move_toward(display_gauge, gauge, delta / GAUGE_FALL_SECONDS)
	if display_gauge <= gauge:
		gauge_tripped = false
	queue_redraw()


## The grate glows as the line builds, hotter toward the gauge's peak, flashing red through the hard
## warning, and red once it has let go.
func _sync_vent_glow() -> void:
	match line_state:
		&"building":
			if gauge >= PressureLine.WARN_GAUGE:
				# The flash follows the gauge itself, so it runs at the same rate whatever the frame rate.
				var flash: float = 1.0 if reduce_motion else 0.5 + 0.5 * cos(gauge * PressureLine.BUILD_SECONDS * VENT_FLASH_HZ * TAU)
				vent_glow.modulate = Color(SEAM_RED, lerpf(0.35, 0.95, flash))
			else:
				vent_glow.modulate = Color(AMBER.lerp(SEAM_RED, gauge * gauge), 0.12 + 0.55 * gauge)
		&"tripped":
			vent_glow.modulate = Color(SEAM_RED, 0.35)
		_:
			vent_glow.modulate = Color(AMBER, 0.0)


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


## The tank came down on the sentry at [param at_x] (the mark): the coolant and spark bursts (fired
## through the impact kit) are moved there and the sentry is crushed into its wreck under the tank.
func tank_hit(at_x: float) -> void:
	sentry_down = true
	coolant_burst.position.x = at_x
	hit_sparks.position.x = at_x
	sentry.keel_over(at_x)
	refresh_state()


## The tank hit the empty mark: the coolant burst moves there and the tank is dented.
func tank_miss() -> void:
	coolant_burst.position.x = DropArm.MARK_X
	tank.dented = true


## The bolt lets go and the hatch slides open (the parent fires the panel's sparks); hatch_opened
## follows once it is open.
func bolt_arc() -> void:
	if _hatch_tween != null and _hatch_tween.is_valid():
		_hatch_tween.kill()
	_hatch_tween = create_tween()
	_hatch_tween.tween_property(self, "hatch_open", 1.0, HATCH_OPEN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_hatch_tween.tween_callback(refresh_state)
	_hatch_tween.tween_callback(func() -> void: hatch_opened.emit())


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
		valve_label.text = "FUSE LIT" if line_state in [&"charged", &"fuse", &"blown"] else ("VALVE  %d / %d" % [turns, PressureLine.TURNS_NEEDED] if armed else "VALVE")
		valve_label.add_theme_color_override("font_color", GREEN if turns >= PressureLine.TURNS_NEEDED else Color("#b0d1de"))
	breaker_glow.modulate = Color(_breaker_light_color(), 0.75 if line_state in [&"building", &"charged", &"fuse"] and not door_blown else 0.4)
	door_label.text = "DOOR DOWN" if door_blown else "SEALED DOOR"
	door_label.add_theme_color_override("font_color", GREEN if door_blown else Color("#ffc7c7"))
	arm_label.text = "RELEASE SPENT" if sentry_down else ("WINCHING UP" if arm_state == &"rewinding" else "TANK RELEASE")
	tank_label.visible = sentry_down
	arm_label.add_theme_color_override("font_color", Color("#8fa6b2") if sentry_down else (AMBER if arm_state == &"rewinding" else Color("#b0d1de")))
	if junction_cleared or (bolt_state == &"open" and hatch_open >= 1.0):
		hatch_label.text = "EXIT OPEN"
		hatch_label.add_theme_color_override("font_color", GREEN)
	elif bolt_state == &"open":
		# The bolt has dropped but the hatch is still sliding: it says open only once it is.
		hatch_label.text = "EXIT OPENING"
		hatch_label.add_theme_color_override("font_color", AMBER)
	elif sentry_down:
		hatch_label.text = "EXIT BOLT"
		hatch_label.add_theme_color_override("font_color", AMBER)
	else:
		hatch_label.text = "EXIT BOLTED"
		hatch_label.add_theme_color_override("font_color", Color("#8fa6b2"))
	for label: Label in station_labels:
		_fit_label(label)
	_sync_seam()
	_sync_vent_glow()
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


## The door going: the bulkhead breaks under the blast flash and gives way to the blown frame on the
## passage beyond, which jolts and settles; sparks and dust fly, and the blast zone is dangerous for a
## moment.
func door_blast() -> void:
	door_blown = true
	door_breaking = true
	vent_hazard.armed = false
	door_shape.set_deferred("disabled", true)
	blast_sparks.restart()
	blast_dust.restart()
	if _door_tween != null and _door_tween.is_valid():
		_door_tween.kill()
	_show_door()
	door_visual.scale = Vector2(1.04, 0.94)
	_door_tween = create_tween()
	_door_tween.tween_interval(DOOR_BREAK_SECONDS)
	_door_tween.tween_callback(func() -> void:
		door_breaking = false
		_show_door())
	_door_tween.tween_property(door_visual, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	refresh_state()


## The sealed bulkhead until the blast, breaking for a moment, then blown open. All of it draws behind
## the actors (Main.ACTOR_Z) and its front pillar over them, so WOLF holding at the rubble and anyone
## walking through stay in the doorway.
func _show_door() -> void:
	door_art.visible = not door_blown
	door_breaking_art.visible = door_blown and door_breaking
	door_blown_art.visible = door_blown and not door_breaking


## The exit hatch's leaf slides up into its frame as it opens, over the passage behind it.
func _sync_hatch() -> void:
	if hatch_doorway == null:
		return
	hatch_doorway.open = hatch_open
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
	door_breaking = false
	arm_state = &"landed" if sentry_down else &"hung"
	tank_drop = 1.0 if sentry_down else 0.0
	tank.position.y = lerpf(TANK_REST_Y, landed_tank_y(sentry_down), tank_drop)
	fuse_remaining = 0.0
	display_gauge = 0.0
	gauge_hold = 0.0
	gauge_tripped = false
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
	_draw_gauge()
	_draw_breaker_light()
	_draw_blast_zone()
	if door_blown:
		draw_line(Vector2(RUBBLE_X - 6.0, 439.0), Vector2(RUBBLE_X + 6.0, 439.0), AMBER, 3.0)
	draw_rect(Rect2(SentryBrain.COVER_MIN_X, FLOOR_Y - 3.0, SentryBrain.COVER_MAX_X - SentryBrain.COVER_MIN_X, 6.0), ALCOVE_FLOOR)
	_draw_arm_panel_light()
	_draw_arm()
	_draw_floor_mark()
	_draw_hatch_lamp(hatch_art, _bolt_light_color(), 1.0)
	draw_rect(prop_rect(bolt_panel_art, BOLT_PANEL_LIGHT), _bolt_light_color())


## The shadow of the alcove behind the TANK RELEASE, drawn on [param canvas] (Recesses, under the
## props): a soft-edged dark recess in the wall, deepest in the middle, with no outline, so it reads
## as part of the painted wall. Its core is exactly SentryBrain's cover span, the x range where an
## engineer is out of the sentry's sight, and the floor under it is tinted over the same span.
func draw_recesses(canvas: CanvasItem) -> void:
	var alcove: Rect2 = alcove_rect()
	canvas.draw_texture_rect(alcove_shadow, alcove.grow_individual(14.0, 10.0, 14.0, 8.0), false, Color(0.0, 0.02, 0.04, 0.85))


## The alcove's core: exactly SentryBrain's cover span, up to the label row.
static func alcove_rect() -> Rect2:
	var top: float = LABEL_Y + 24.0
	return Rect2(SentryBrain.COVER_MIN_X, top, SentryBrain.COVER_MAX_X - SentryBrain.COVER_MIN_X, FLOOR_Y - top)


## A white texture that is opaque in the middle and fades softly to clear at its edges ([param fill]
## square for a recess, radial for a light); tinted by the colour it is drawn with.
static func soft_texture(fill: GradientTexture2D.Fill) -> GradientTexture2D:
	var texture: GradientTexture2D = GradientTexture2D.new()
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1.0, 1.0, 1.0, 0.75), Color(1.0, 1.0, 1.0, 0.0)])
	texture.gradient = gradient
	texture.width = 64
	texture.height = 64
	texture.fill = fill
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture


## A hatch's lamp, painted on the bar over its door, lit in [param color]; it rides and fades with
## the hatch as it lifts.
func _draw_hatch_lamp(hatch: Sprite2D, color: Color, alpha: float) -> void:
	if alpha > 0.0:
		draw_rect(prop_rect(hatch, HATCH_LAMP), Color(color, alpha))


## The needle over the valve's painted gauge is the LINE gauge (left at empty, right at the vent's
## peak): red through the hard warning, and pinned red at the top for a while after the vent lets go
## (display_gauge). The VALVE plate counts the real turns.
func _draw_gauge() -> void:
	var centre: Vector2 = prop_point(valve_art, VALVE_DIAL_CENTRE)
	var face: float = VALVE_DIAL_RADIUS * VALVE_SCALE
	# A fresh face over the painted one, so its painted needle never reads as a second reading.
	draw_circle(centre, face - 0.6, Color("#d9d3c4"))
	draw_arc(centre, face - 1.6, PI + PI * 0.78, TAU, 8, SEAM_RED, 1.6, true)
	var angle: float = PI + PI * display_gauge
	var red: bool = gauge_tripped or (line_state == &"building" and gauge >= PressureLine.WARN_GAUGE)
	var needle: Color = Color("#d0261c") if red else Color("#1a1c20")
	draw_line(centre, centre + Vector2.RIGHT.rotated(angle) * (face - 1.2), needle, 1.4, true)
	draw_circle(centre, 1.2, needle)


## Hazard stripes on the floor over exactly the door's blast zone (PressureLine.BLAST_MIN_X..
## BLAST_MAX_X) while the fuse burns, pulsing with the fuse (steady with Reduced Motion).
func _draw_blast_zone() -> void:
	if door_blown or not (line_state == &"charged" or line_state == &"fuse"):
		return
	var pulse: float = 1.0 if reduce_motion else 0.5 + 0.5 * cos(fuse_remaining * BLAST_STRIPE_HZ * TAU)
	var left: float = PressureLine.BLAST_MIN_X
	var width: float = PressureLine.BLAST_MAX_X - PressureLine.BLAST_MIN_X
	var stripes: int = 15
	# A red wash over the walkway in front, then the stripes along the floor line, over its whole span.
	draw_rect(Rect2(left, FLOOR_Y, width, 9.0), Color(SEAM_RED, lerpf(0.12, 0.3, pulse)))
	for stripe: int in stripes:
		var segment: Rect2 = Rect2(left + stripe * width / stripes, FLOOR_Y - 2.0, width / stripes, 7.0)
		draw_rect(segment, Color(SEAM_RED, lerpf(0.55, 1.0, pulse)) if stripe % 2 == 0 else Color(0.1, 0.03, 0.03, 0.85))
	for edge: float in [left, left + width]:
		draw_line(Vector2(edge, FLOOR_Y - 12.0), Vector2(edge, FLOOR_Y + 9.0), Color(SEAM_RED, lerpf(0.7, 1.0, pulse)), 2.0)


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


## The rods that hang the arm's ceiling plate from the gantry, and, only while the winch hauls a
## missed tank back up, the steel cable from its shackle down to the tank (a dark braided body with a
## faint sheen, in the painted winch cable's tones). A released tank falls free and lies free: no
## cable while it falls or once it is down.
func _draw_arm() -> void:
	var plate_top: float = arm_art.position.y - ARM_REGION.size.y * TANK_ART_SCALE * 0.5 + 2.0
	for rod_x: float in [DropArm.MARK_X - 26.0, DropArm.MARK_X + 34.0]:
		draw_line(Vector2(rod_x, GANTRY_Y), Vector2(rod_x, plate_top), Color("#1b2630"), 5.0)
		draw_line(Vector2(rod_x - 1.5, GANTRY_Y), Vector2(rod_x - 1.5, plate_top), STEEL, 1.0)
	if tank_drop <= 0.0 or arm_state != &"rewinding":
		return
	var cable_top: Vector2 = Vector2(DropArm.MARK_X, TANK_REST_Y - TANK_SIZE.y * 0.5)
	var tank_top: Vector2 = Vector2(DropArm.MARK_X, tank.position.y - TANK_SIZE.y * 0.5)
	draw_line(cable_top, tank_top, CABLE_SHADOW, 4.0)
	draw_line(cable_top, tank_top, CABLE_BODY, 2.5)
	draw_line(cable_top + Vector2(-0.6, 0.0), tank_top + Vector2(-0.6, 0.0), CABLE_SHEEN, 0.8)


## True while the floor brackets are lit: a live sentry's body is over them, so a tank landing now
## would hit it.
func mark_lit() -> bool:
	return door_blown and not sentry_down and sentry.visual.is_lit() and DropArm.is_hit(sentry.target_x)


## The floor brackets and the tank's shadow, both as wide as the tank (DropArm.HIT_RANGE either side
## of the mark). The shadow is laid over the stripes, dimming them and spilling onto the floor either
## side, and darkens and tightens as the tank comes down; the bracket posts stay on top of it. The
## brackets light up while the sentry is in them far enough to be hit (DropArm.is_hit).
func _draw_floor_mark() -> void:
	var left: float = DropArm.MARK_X - DropArm.HIT_RANGE
	var width: float = DropArm.HIT_RANGE * 2.0
	var lit: bool = mark_lit()
	var stripe_color: Color = MARK_LIT if lit else AMBER
	# The stripes run along the floor line and down onto the walkway in front of it, so a machine
	# standing on the mark covers only their top and the brackets still read below its treads.
	if lit:
		draw_rect(Rect2(left - 2.0, FLOOR_Y, width + 4.0, 10.0), Color(MARK_LIT, 0.28))
	var stripes: int = 7
	for stripe: int in stripes:
		var segment: Rect2 = Rect2(left + stripe * width / stripes, FLOOR_Y - 3.0, width / stripes, 7.0)
		draw_rect(segment, stripe_color if stripe % 2 == 0 else Color("#1a2229"))
	if arm_state != &"landed":
		var shadow: PackedVector2Array = PackedVector2Array()
		var half: Vector2 = Vector2(DropArm.HIT_RANGE * lerpf(1.35, 1.05, tank_drop), lerpf(5.0, 10.0, tank_drop))
		var centre: Vector2 = Vector2(DropArm.MARK_X, SHADOW_Y)
		for step: int in 24:
			shadow.append(centre + Vector2(cos(step * TAU / 24.0) * half.x, sin(step * TAU / 24.0) * half.y))
		draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, lerpf(0.25, 0.85, tank_drop)))
	for edge: float in [left, left + width]:
		draw_line(Vector2(edge, FLOOR_Y - 10.0), Vector2(edge, FLOOR_Y + 10.0), stripe_color, 2.0)


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
