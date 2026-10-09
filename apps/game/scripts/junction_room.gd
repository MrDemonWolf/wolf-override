extends Node2D
class_name JunctionRoom
## Blowback: the Service Junction, the third 960 px room after the Records exit. The painted
## maintenance corridor is reused (tinted) as its provisional backdrop; the pressure line, relief
## vent, valve wheel, gauge, sealed door, rubble and exit hatch are drawn here from the state the
## parent mirrors in, so nothing animates on a timer of its own.

const CORRIDOR_BACKGROUND: Texture2D = preload("res://assets/maintenance-corridor-background-provisional.png")
const MAINTENANCE_PROPS: Texture2D = preload("res://assets/maintenance-props-provisional.png")
## Station centres, left to right.
const ENTRY_X: float = 80.0
const BREAKER_X: float = 200.0
const VENT_X: float = 300.0
const VALVE_X: float = 420.0
const DOOR_X: float = 480.0
const RUBBLE_X: float = 540.0
const HATCH_X: float = 880.0
const FLOOR_Y: float = 440.0
## Where WOLF stands to read the door seam (his 62 px body stops just short of the door body at
## x 452), and where he holds once the door is down.
const WOLF_SEAM_X: float = 418.0
const WOLF_RUBBLE_X: float = 500.0
## How long the vent burst and the door blast stay dangerous after they go.
const HAZARD_SECONDS: float = 0.4
const VENT_REASON: String = "The relief vent let go under you. Stand clear of the grate when the gauge peaks."
const BLAST_REASON: String = "The door blew with you in front of it. Get left of the vent before the fuse ends."
const AMBER: Color = Color("#f3ae4b")
const GREEN: Color = Color("#a4f0c4")
const DIM: Color = Color("#3e4f5a")
const STEEL: Color = Color("#4a6572")
const SEAM_RED: Color = Color("#ff6a55")

## Lamp centres as fractions of the reused corridor painting.
var lamps: PackedVector2Array = PackedVector2Array([Vector2(0.345, 0.251), Vector2(0.604, 0.251), Vector2(0.87, 0.251)])
var warning_lamps: PackedVector2Array = PackedVector2Array([Vector2(0.036, 0.35), Vector2(0.79, 0.34)])

# Mirrored from the parent's state and PressureLine; the parent calls sync_line()/refresh_state().
var line_state: StringName = &"idle"
var gauge: float = 0.0
var turns: int = 0
var door_blown: bool = false

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
var blast_hazard: Hazard
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


func _ready() -> void:
	depth = RoomDepth.new()
	depth.name = "Depth"
	depth.painting = CORRIDOR_BACKGROUND
	depth.base_color = Color("#0a0e18")
	depth.lamps = lamps
	depth.lamp_color = Color("#ffcf9a")
	depth.shaft_lamps = PackedInt32Array([0, 2])
	depth.warning_lamps = warning_lamps
	add_child(depth)
	# The reused corridor painting is pulled warmer and darker so the junction reads as its own place.
	depth.backdrop.modulate = Color("#b7a79c")
	breaker_art = _add_prop("BreakerArt", BREAKER_X, 0.0)
	floor_reflections.append(FloorReflection.attach(breaker_art))
	breaker_glow = RoomDepth.make_glow(AMBER, Vector2(64.0, 30.0), 0.5)
	breaker_glow.name = "BreakerGlow"
	breaker_glow.position = Vector2(BREAKER_X, 356.5)
	breaker_glow.z_index = 1
	add_child(breaker_glow)
	_build_door()
	valve_wheel = ValveWheel.new()
	valve_wheel.name = "ValveWheel"
	valve_wheel.position = Vector2(VALVE_X, 372.0)
	valve_wheel.z_index = 1
	add_child(valve_wheel)
	_build_particles()
	vent_hazard = Hazard.make("VentHazard", Rect2(PressureLine.VENT_MIN_X, 380.0, PressureLine.VENT_MAX_X - PressureLine.VENT_MIN_X, 60.0), VENT_REASON)
	blast_hazard = Hazard.make("BlastHazard", Rect2(PressureLine.BLAST_MIN_X, 300.0, PressureLine.BLAST_MAX_X - PressureLine.BLAST_MIN_X, 140.0), BLAST_REASON)
	add_child(vent_hazard)
	add_child(blast_hazard)
	breaker_label = _add_station_label("OVERLOAD BREAKER", BREAKER_X, Color("#b0d1de"))
	valve_label = _add_station_label("VALVE", VALVE_X, Color("#b0d1de"))
	door_label = _add_station_label("SEALED DOOR", DOOR_X, Color("#ffc7c7"), 276.0)
	_add_station_label("EXIT", HATCH_X, DIM, 276.0)
	refresh_state()


func _add_prop(prop_name: String, center_x: float, source_x: float) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = prop_name
	sprite.texture = MAINTENANCE_PROPS
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.region_enabled = true
	sprite.region_rect = Rect2(source_x, 0.0, 543.0, 724.0)
	sprite.position = Vector2(center_x, 372.0)
	sprite.scale = Vector2(0.22, 0.22)
	sprite.z_index = 1
	add_child(sprite)
	return sprite


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
	box.size = Vector2(56.0, 132.0)
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
	door_art = Sprite2D.new()
	door_art.name = "DoorArt"
	door_art.texture = MAINTENANCE_PROPS
	door_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	door_art.region_enabled = true
	door_art.region_rect = Rect2(1086.0, 0.0, 543.0, 724.0)
	door_art.position = Vector2(0.0, -66.0)
	door_art.scale = Vector2(0.22, 0.22)
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
	vent_steam.emission_rect_extents = Vector2(22.0, 2.0)
	vent_steam.z_index = 3
	add_child(vent_steam)
	vent_puff = FxPresets.dust_burst()
	vent_puff.name = "VentPuff"
	vent_puff.position = vent_steam.position
	vent_puff.color = Color(FxPresets.STEAM, 0.7)
	vent_puff.initial_velocity_min = 160.0
	vent_puff.initial_velocity_max = 260.0
	vent_puff.spread = 30.0
	vent_puff.amount = 28
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
	for hazard: Hazard in [vent_hazard, blast_hazard]:
		hazard.armed = false
		hazard.set_deferred("monitoring", active)


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
	var armed: bool = line_state != &"idle" and line_state != &"tripped"
	breaker_label.text = "BREAKER TRIPPED" if line_state == &"tripped" else ("BREAKER LIVE" if armed else "OVERLOAD BREAKER")
	breaker_label.add_theme_color_override("font_color", SEAM_RED if line_state == &"tripped" else (Color("#8be3ff") if armed else Color("#b0d1de")))
	breaker_glow.modulate = Color(_breaker_light_color(), 0.75 if armed else 0.4)
	valve_label.text = "SEAL CHARGED" if line_state == &"charged" or line_state == &"fuse" else ("VALVE  %d / %d" % [turns, PressureLine.TURNS_NEEDED] if armed else "VALVE")
	valve_label.add_theme_color_override("font_color", GREEN if turns >= PressureLine.TURNS_NEEDED else Color("#b0d1de"))
	door_label.text = "DOOR DOWN" if door_blown else "SEALED DOOR"
	door_label.add_theme_color_override("font_color", GREEN if door_blown else Color("#ffc7c7"))
	_sync_seam()
	queue_redraw()


func _sync_seam() -> void:
	if _seam_tween != null and _seam_tween.is_valid():
		_seam_tween.kill()
	_seam_tween = null
	seam_glow.visible = not door_blown
	match line_state:
		&"charged", &"fuse":
			# The seam strobes white only once the third turn is real.
			seam_glow.modulate = Color(Color.WHITE, 0.9)
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
	_arm_hazard(blast_hazard)
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
	for tween: Tween in [_valve_tween, _seam_tween, _door_tween, _hazard_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	_valve_tween = null
	_seam_tween = null
	_door_tween = null
	_hazard_tween = null
	for hazard: Hazard in [vent_hazard, blast_hazard]:
		hazard.armed = false
	vent_steam.emitting = false
	vent_puff.emitting = false
	blast_sparks.emitting = false
	blast_dust.emitting = false
	valve_wheel.rotation_degrees = 0.0
	door_visual.scale = Vector2.ONE
	door_visual.rotation_degrees = 0.0
	door_visual.visible = not door_blown
	door_shape.set_deferred("disabled", not visible or door_blown)
	line_state = &"idle"
	gauge = 0.0
	turns = 0
	refresh_state()


func _draw() -> void:
	# The corridor painting itself is the Depth child's parallax backdrop.
	_draw_entry_hatch()
	_draw_pressure_line()
	_draw_vent()
	_draw_gauge_and_lights()
	_draw_breaker_light()
	if door_blown:
		_draw_rubble()
	_draw_exit_hatch()


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


func _draw_vent() -> void:
	var grate: Rect2 = Rect2(VENT_X - 30.0, FLOOR_Y - 8.0, 60.0, 8.0)
	draw_rect(grate, Color("#141c24"))
	for slat: int in 6:
		var x: float = grate.position.x + 6.0 + slat * 9.0
		draw_line(Vector2(x, grate.position.y + 1.0), Vector2(x, grate.end.y - 1.0), Color("#5c707c"), 2.0)
	draw_rect(grate, STEEL, false, 2.0)
	var vent_light: Color = SEAM_RED if line_state == &"tripped" else (DIM.lerp(AMBER, gauge) if line_state == &"building" else DIM)
	draw_rect(Rect2(VENT_X - 13.0, 352.0, 26.0, 5.0), vent_light)
	draw_string(ThemeDB.fallback_font, Vector2(VENT_X - 42.0, 346.0), "RELIEF VENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#8fa6b2"))


## A dial on the pipe run beside the valve whose needle is the gauge, and three lights stacked
## left of the wheel that go green per real turn (both clear of the station label and the actors).
func _draw_gauge_and_lights() -> void:
	var centre: Vector2 = Vector2(VALVE_X - 48.0, 326.0)
	draw_line(Vector2(centre.x, 292.0), Vector2(centre.x, centre.y - 18.0), Color("#263540"), 6.0)
	draw_circle(centre, 18.0, Color("#101820"))
	draw_arc(centre, 15.0, PI, TAU, 24, Color("#5c707c"), 2.0, true)
	draw_arc(centre, 15.0, PI + PI * 0.78, TAU, 8, SEAM_RED, 3.0, true)
	var angle: float = PI + PI * gauge
	draw_line(centre, centre + Vector2.RIGHT.rotated(angle) * 13.0, Color("#f4f7f9") if gauge > 0.0 else Color("#7b8f9a"), 2.0, true)
	draw_circle(centre, 2.5, Color("#d8e6ec"))
	for light: int in PressureLine.TURNS_NEEDED:
		var rect: Rect2 = Rect2(VALVE_X - 40.0, 356.0 + light * 12.0, 12.0, 6.0)
		draw_rect(rect, GREEN if light < turns else Color("#1f2a33"))
		draw_rect(rect, STEEL, false, 1.0)


func _draw_breaker_light() -> void:
	draw_rect(Rect2(BREAKER_X - 9.0, 354.0, 18.0, 5.0), _breaker_light_color())


func _breaker_light_color() -> Color:
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


func _draw_exit_hatch() -> void:
	draw_rect(Rect2(HATCH_X - 32.0, 300.0, 64.0, 138.0), Color("#06111a"))
	draw_rect(Rect2(HATCH_X - 40.0, 296.0, 80.0, 144.0), STEEL, false, 3.0)
	for bar: int in 3:
		var y: float = 330.0 + bar * 34.0
		draw_line(Vector2(HATCH_X - 32.0, y), Vector2(HATCH_X + 32.0, y), Color("#1e2b35"), 3.0)
	draw_rect(Rect2(HATCH_X - 9.0, 354.0, 18.0, 5.0), SEAM_RED)
