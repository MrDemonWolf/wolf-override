class_name BypassHandle
extends Node2D
## The corridor's MANUAL BYPASS: a small wheel on its own bracket beside the coolant relay, piped into
## the relay's housing. The wheel is the junction valve's own disc (the same cut JunctionRoom turns),
## and a row of crank lights along the bottom of its name plate, above the head of the engineer
## cranking it and clear of WOLF beside them, counts the held-USE ticks. It also carries the relay's
## COOLANT FAULT tag and the coolant that hisses from the housing while the bypass is cranked. Main
## owns the rules; this only shows them.

## Crank lights in the readout, one per held-USE tick.
const TICKS_NEEDED: int = 8
const WHEEL_SCALE: float = 0.15
## The dark collar the wheel turns on, just outside its rim.
const COLLAR_RADIUS: float = 17.5
## The crank readout along the bottom of the name plate: one cell per tick, in a strip this tall.
const READOUT_HEIGHT: float = 12.0
const CELL_SIZE: Vector2 = Vector2(5.0, 6.0)
const CELL_GAP: float = 1.5
## The bracket: a pipe from the relay's side pipe into the wheel's hub, and a post down to the floor.
const PIPE_FROM_X: float = -58.0
const POST_BOTTOM: float = 35.0
const STEEL_DARK: Color = Color("#1b2630")
const STEEL: Color = Color("#4a6572")
const STEEL_LIGHT: Color = Color("#6b7e86")
const LAMP_OFF: Color = Color("#24333c")
const AMBER: Color = Color("#f3ae4b")
const GREEN: Color = Color("#a4f0c4")
const LABEL_TEXT: Color = Color(0.69, 0.82, 0.87, 1)
const FAULT_TEXT: Color = Color("#ffb36b")
const FAULT_EDGE: Color = Color(0.78, 0.33, 0.2, 0.8)
const LABEL_FONT_SIZE: int = 13
## The MANUAL BYPASS plate, wrapped to two rows so it fits between the relay and the seal: its width
## and its top edge above the wheel's centre, high enough to clear the head of an engineer cranking it.
const LABEL_WIDTH: float = 64.0
const LABEL_TOP: float = -87.0
## The COOLANT FAULT tag sits under the COOLANT RELAY name, centred on the relay.
const FAULT_TAG_TOP: float = 331.0
## Where the coolant leaks from the relay's housing, from the wheel's centre.
const HISS_OFFSET: Vector2 = Vector2(-56.0, -6.0)
## The fault tag pulses with the alarm while the bypass vents.
const PULSE_SECONDS: float = 1.1

## Ticks cranked so far (0..TICKS_NEEDED); each turns the wheel an eighth and lights a cell.
var ticks: int = 0:
	set(value):
		var turned: bool = value != ticks
		ticks = clampi(value, 0, TICKS_NEEDED)
		if turned:
			_turn_wheel()
		readout.queue_redraw()
## Powered by the breaker; dead its readout stays dark.
var live: bool = false:
	set(value):
		live = value
		readout.queue_redraw()
## The bypass opened the seal: every cell goes green.
var done: bool = false:
	set(value):
		done = value
		readout.queue_redraw()
## Coolant hissing from the housing while the bypass is cranked; the fault tag pulses with the alarm.
var venting: bool = false:
	set(value):
		venting = value
		coolant_hiss.emitting = venting
		if not venting:
			fault_tag.modulate = Color.WHITE
			_pulse = 0.0
var reduce_motion: bool = false
var wheel: Sprite2D
var bypass_label: Label
var fault_tag: Label
var coolant_hiss: CPUParticles2D
var readout: Node2D
var _wheel_tween: Tween
var _pulse: float = 0.0


func _init() -> void:
	name = "BypassHandle"
	wheel = Sprite2D.new()
	wheel.name = "Wheel"
	wheel.texture = JunctionRoom.VALVE_PROP
	wheel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	wheel.region_enabled = true
	wheel.region_rect = Rect2(JunctionRoom.VALVE_WHEEL_CENTRE - Vector2.ONE * JunctionRoom.VALVE_WHEEL_RADIUS, Vector2.ONE * JunctionRoom.VALVE_WHEEL_RADIUS * 2.0)
	wheel.scale = Vector2.ONE * WHEEL_SCALE
	var mask: Shader = Shader.new()
	mask.code = JunctionRoom.WHEEL_MASK
	var wheel_material: ShaderMaterial = ShaderMaterial.new()
	wheel_material.shader = mask
	wheel_material.set_shader_parameter("centre", JunctionRoom.VALVE_WHEEL_CENTRE / JunctionRoom.VALVE_PROP.get_size())
	wheel_material.set_shader_parameter("radius", JunctionRoom.VALVE_WHEEL_RADIUS / JunctionRoom.VALVE_PROP.get_size().x)
	wheel.material = wheel_material
	add_child(wheel)
	bypass_label = _plate("BypassLabel", "MANUAL BYPASS", LABEL_TEXT, Color(0.29, 0.4, 0.45, 0.55), LABEL_WIDTH, READOUT_HEIGHT)
	readout = Node2D.new()
	readout.name = "CrankReadout"
	readout.draw.connect(_draw_readout)
	bypass_label.add_child(readout)
	fault_tag = _plate("CoolantFaultTag", "COOLANT FAULT", FAULT_TEXT, FAULT_EDGE)
	coolant_hiss = FxPresets.steam()
	coolant_hiss.name = "CoolantHiss"
	coolant_hiss.position = HISS_OFFSET
	coolant_hiss.amount = 24
	coolant_hiss.lifetime = 0.75
	coolant_hiss.direction = Vector2(0.6, -1.0)
	coolant_hiss.spread = 25.0
	coolant_hiss.initial_velocity_min = 25.0
	coolant_hiss.initial_velocity_max = 45.0
	coolant_hiss.scale_amount_min = 4.0
	coolant_hiss.scale_amount_max = 7.0
	add_child(coolant_hiss)


## Places the handle with its wheel at [param wheel_centre] and the COOLANT FAULT tag centred on
## [param relay_x].
func place(wheel_centre: Vector2, relay_x: float) -> void:
	position = wheel_centre
	bypass_label.position = Vector2(-bypass_label.size.x * 0.5, LABEL_TOP)
	fault_tag.position = Vector2(relay_x - wheel_centre.x - fault_tag.size.x * 0.5, FAULT_TAG_TOP - wheel_centre.y)


func _process(delta: float) -> void:
	if not venting or not is_visible_in_tree():
		return
	# The tag throbs in step with the alarm; Reduced Motion keeps it lit amber instead.
	_pulse = fmod(_pulse + delta, PULSE_SECONDS)
	var glow: float = 1.0 if reduce_motion else 0.6 + 0.4 * cos(_pulse / PULSE_SECONDS * TAU)
	fault_tag.modulate = Color(1.0, glow, glow * 0.9)


## A name plate like the junction's; [param wrap_width] above 0 wraps the caption onto rows that wide,
## and [param foot] leaves that much room under the text.
func _plate(node_name: String, caption: String, text_color: Color, edge: Color, wrap_width: float = 0.0, foot: float = 0.0) -> Label:
	var plate: StyleBoxFlat = StyleBoxFlat.new()
	plate.bg_color = JunctionRoom.LABEL_PLATE
	plate.border_color = edge
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(2)
	plate.content_margin_left = 5.0
	plate.content_margin_right = 5.0
	plate.content_margin_bottom = foot
	var label: Label = Label.new()
	label.name = node_name
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_stylebox_override("normal", plate)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap_width > 0.0:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.custom_minimum_size.x = wrap_width
	add_child(label)
	label.size = label.get_combined_minimum_size()
	return label


func _turn_wheel() -> void:
	if _wheel_tween != null and _wheel_tween.is_valid():
		_wheel_tween.kill()
	var target: float = 360.0 / TICKS_NEEDED * ticks
	if ticks == 0 or not is_inside_tree():
		wheel.rotation_degrees = target
		return
	_wheel_tween = create_tween()
	_wheel_tween.tween_property(wheel, "rotation_degrees", target, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	# The pipe from the relay's housing into the hub, with a flange at each end.
	draw_rect(Rect2(PIPE_FROM_X, -4.0, -PIPE_FROM_X, 8.0), STEEL_DARK)
	draw_line(Vector2(PIPE_FROM_X, -3.0), Vector2(0.0, -3.0), STEEL_LIGHT, 1.0)
	for flange_x: float in [PIPE_FROM_X, -16.0]:
		draw_rect(Rect2(flange_x, -6.5, 4.0, 13.0), STEEL)
	# The post to the floor and its foot plate.
	draw_rect(Rect2(-4.0, 8.0, 8.0, POST_BOTTOM - 8.0), STEEL_DARK)
	draw_line(Vector2(-3.0, 8.0), Vector2(-3.0, POST_BOTTOM - 3.0), STEEL_LIGHT, 1.0)
	draw_rect(Rect2(-13.0, POST_BOTTOM - 4.0, 26.0, 4.0), STEEL)
	# The dark collar the wheel turns on.
	draw_circle(Vector2.ZERO, COLLAR_RADIUS, STEEL_DARK)
	draw_arc(Vector2.ZERO, COLLAR_RADIUS, 0.0, TAU, 40, STEEL, 1.5)


## The crank readout, drawn in the plate's foot: dark until the breaker is on, then one cell lights
## amber per tick, and all go green once the bypass has opened the seal.
func _draw_readout() -> void:
	var row: float = CELL_SIZE.x * TICKS_NEEDED + CELL_GAP * (TICKS_NEEDED - 1)
	var first: Vector2 = Vector2((bypass_label.size.x - row) * 0.5, bypass_label.size.y - READOUT_HEIGHT * 0.5 - CELL_SIZE.y * 0.5 - 1.0)
	for index: int in TICKS_NEEDED:
		var cell: Color = LAMP_OFF
		if live or done:
			cell = GREEN if done else (AMBER if index < ticks else Color("#4d6370"))
		readout.draw_rect(Rect2(first + Vector2((CELL_SIZE.x + CELL_GAP) * index, 0.0), CELL_SIZE), cell)
