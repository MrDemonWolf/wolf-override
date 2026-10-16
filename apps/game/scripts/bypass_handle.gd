class_name BypassHandle
extends Node2D
## The corridor's MANUAL BYPASS: a 0.525 m handwheel on a worm gearbox, on a steel backplate anchored
## to the corridor wall at the cross-wall's corner, with its hub at 1.0 m; an enclosed chain guard
## runs straight up the wall in two clamp brackets to the door operator's manual input. The backplate,
## gearbox and guard are painted into the corridor's mid plate; only the wheel is drawn here, so it
## can turn. Its hub sits WHEEL_OFFSET from the gameplay point (Main's BYPASS_WHEEL), under the hand
## of the engineer's crank pose. A row of crank lights along the bottom of its name plate, above the
## head of the engineer cranking it and clear of WOLF beside them, counts the held-USE ticks. It also carries the relay's
## COOLANT FAULT tag, until WOLF takes the surge or the bypass locks over, and the coolant that jets
## from the relay's relief valve while the bypass is cranked. A plate the edge of the view cuts fades
## out, as in the junction. Main owns the rules; this only shows them.

## Crank lights in the readout, one per held-USE tick.
const TICKS_NEEDED: int = 8
## Seconds of held USE per tick, so the eight take 2 s (Nathanial's decision Q1, October 13, 2026; it
## was 3.2 s). The alarm and the hiss, not the hold, are what the manual route costs.
const TICK_SECONDS: float = 0.25
## Degrees the wheel turns per tick: an eighth.
const TICK_DEGREES: float = 360.0 / TICKS_NEEDED
## Letting go mid-tick, the wheel springs back to its last notch this fast.
const SPRING_BACK_SECONDS: float = 0.12
## The handwheel art: a region of the door end's atlas (4 source px per world px, centred on the
## wheel's axis).
const WHEEL_ART: Texture2D = preload("res://assets/props/corridor-seal-atlas.png")
const WHEEL_REGION: Rect2 = Rect2(730.0, 619.0, 88.0, 88.0)
const WHEEL_SCALE: float = 0.25
## The wheel's hub from the gameplay point, on the wall gearbox at 1.0 m: the crank pose's glove
## (the engineer at BYPASS_CRANK_X) lands on its rim at 8 o'clock.
const WHEEL_OFFSET: Vector2 = Vector2(-6.0, 2.0)
## How far either side of the wheel's centre the bypass mount reaches (WOLF rests clear of it).
const COLLAR_RADIUS: float = 17.5
## The crank readout along the bottom of the name plate: one cell per tick, in a strip this tall.
const READOUT_HEIGHT: float = 12.0
const CELL_SIZE: Vector2 = Vector2(5.0, 6.0)
const CELL_GAP: float = 1.5
const LAMP_OFF: Color = Color("#24333c")
## A crank light still to come once the bypass is live.
const LAMP_WAITING: Color = Color("#4d6370")
const LABEL_TEXT: Color = Color(0.69, 0.82, 0.87, 1)
const FAULT_TEXT: Color = Color("#ffb36b")
const FAULT_EDGE: Color = Color(0.78, 0.33, 0.2, 0.8)
const LABEL_FONT_SIZE: int = 13
## The MANUAL BYPASS plate, wrapped to two rows: its width, its top edge above the gameplay point and
## its sideways shift. It stands over the wheel's hub: its right edge stops just left of the chain
## guard rising to the door operator, and its bottom just above the corridor's label line (y 313, the
## COOLANT RELAY name), which with the COOLANT FAULT tag under it and the head of the engineer cranking
## it is why it cannot sit lower.
const LABEL_WIDTH: float = 64.0
const LABEL_TOP: float = -136.0
const LABEL_SHIFT_X: float = -32.5
## Above 100%, the least gap between the MANUAL BYPASS plate and the COOLANT FAULT tag to its left.
const LABEL_GAP: float = 6.0
## A leader from the plate's bottom edge straight down to the top of the wheel's backplate, at the
## hub's x, so the plate and its crank lights read as the wheel's (relative to the gameplay point).
const LEADER_X: float = -6.0
const LEADER_END_Y: float = -14.0
const LEADER_WIDTH: float = 1.0
## The COOLANT FAULT tag sits under the COOLANT RELAY name, centred on the relay.
const FAULT_TAG_TOP: float = 331.0
## The open end of the relief valve's discharge pipe, painted on the relay art (art px (352.5, 337)
## at its 0.25 scale): the valve stands on the crown of the relay's side pipe, and its tailpipe is
## carried down the relay's side in two clamps to a safe point 0.44 m above the floor, away from the
## engineer's hands and face at the wheel. The coolant sprays from here, down onto the floor.
const RELIEF_OUTLET: Vector2 = Vector2(649.75, 422.25)
## The fault tag pulses with the alarm while the bypass vents.
const PULSE_SECONDS: float = 1.1
## How long the COOLANT FAULT tag takes to fade once the relay is dealt with.
const FAULT_CLEAR_SECONDS: float = 0.35

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
## Coolant jetting from the relief valve while the bypass is cranked; the fault tag pulses with the
## alarm.
var venting: bool = false:
	set(value):
		venting = value
		coolant_hiss.emitting = venting
		if not venting:
			fault_tag.modulate = Color.WHITE
			_pulse = 0.0
var reduce_motion: bool = false
## How far into the next tick the hold has the wheel (HoldUse.shown_fraction), 0 while it is not held.
## Set through show_hold.
var hold_fraction: float = 0.0
## The relay is dealt with (WOLF took the surge, or the bypass locked over): the COOLANT FAULT tag is
## gone (PUZ-7). Set through clear_fault.
var fault_cleared: bool = false
var wheel: Sprite2D
var bypass_label: Label
var fault_tag: Label
var coolant_hiss: CPUParticles2D
var readout: Node2D
var _wheel_tween: Tween
var _fault_tween: Tween
var _pulse: float = 0.0
## The relay's centre the COOLANT FAULT tag is centred on (place).
var _relay_x: float = 0.0


func _init() -> void:
	name = "BypassHandle"
	wheel = Sprite2D.new()
	wheel.name = "Wheel"
	wheel.texture = WHEEL_ART
	wheel.region_enabled = true
	wheel.region_rect = WHEEL_REGION
	wheel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	wheel.scale = Vector2.ONE * WHEEL_SCALE
	wheel.position = WHEEL_OFFSET
	add_child(wheel)
	bypass_label = _plate("BypassLabel", "MANUAL BYPASS", LABEL_TEXT, Palette.PLATE_EDGE, LABEL_WIDTH, READOUT_HEIGHT)
	readout = Node2D.new()
	readout.name = "CrankReadout"
	readout.draw.connect(_draw_readout)
	bypass_label.add_child(readout)
	fault_tag = _plate("CoolantFaultTag", "COOLANT FAULT", FAULT_TEXT, FAULT_EDGE)
	coolant_hiss = FxPresets.relief_jet()
	# place() moves it onto the relief valve's outlet once the wheel's centre is known.
	FxPresets.place(coolant_hiss, self, "CoolantHiss", Vector2.ZERO)


## Places the handle with its wheel at [param wheel_centre] and the COOLANT FAULT tag centred on
## [param relay_x]; the coolant jet sits on the relief valve's outlet.
func place(wheel_centre: Vector2, relay_x: float) -> void:
	position = wheel_centre
	coolant_hiss.position = RELIEF_OUTLET - wheel_centre
	_relay_x = relay_x
	# The tag grows upward too, over the relay's name, which main lifts by as much (fault_tag_growth).
	fault_tag.position = Vector2(relay_x - wheel_centre.x - fault_tag.size.x * 0.5, FAULT_TAG_TOP - wheel_centre.y - fault_tag_growth())
	# A larger TEXT SIZE grows the plate upward, so its foot stays over the wheel, and to the right of
	# where it stood at 100%, clear of the COOLANT FAULT tag (the wider of the relay's two names), so
	# the relay's names and this plate never run into each other.
	var font: Font = bypass_label.get_theme_font(&"font")
	var grown: float = (font.get_height(TextSize.world_px(LABEL_FONT_SIZE)) - font.get_height(LABEL_FONT_SIZE)) * bypass_label.get_line_count()
	var left: float = -bypass_label.size.x * 0.5 + LABEL_SHIFT_X
	if TextSize.world_factor() > 1.0:
		var at_100: float = bypass_label.size.x - float(bypass_label.get_meta(&"wrap_width")) * (TextSize.world_factor() - 1.0)
		left = maxf(-at_100 * 0.5 + LABEL_SHIFT_X, fault_tag.position.x + fault_tag.size.x + LABEL_GAP)
	bypass_label.position = Vector2(left, LABEL_TOP - grown)
	readout.queue_redraw()


## How much taller the COOLANT FAULT tag stands than at 100% (it breaks onto two rows when larger).
func fault_tag_growth() -> float:
	return TextSize.world_growth(fault_tag, LABEL_FONT_SIZE)


## Shows the COOLANT FAULT tag while the relay is still faulted and takes it away once
## [param cleared]; with [param animate] it fades over FAULT_CLEAR_SECONDS (the moment the seal's power
## goes through), otherwise it goes at once (a reload). Its own self_modulate carries the fade, since
## the alarm pulse and the view-edge fade drive its modulate.
func clear_fault(cleared: bool, animate: bool) -> void:
	if cleared == fault_cleared:
		return
	fault_cleared = cleared
	Tweens.kill(_fault_tween)
	if not cleared:
		fault_tag.self_modulate.a = 1.0
		fault_tag.show()
	elif animate and is_inside_tree():
		_fault_tween = create_tween()
		_fault_tween.tween_property(fault_tag, "self_modulate:a", 0.0, FAULT_CLEAR_SECONDS)
		_fault_tween.tween_callback(fault_tag.hide)
	else:
		fault_tag.self_modulate.a = 0.0
		fault_tag.hide()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if venting:
		# The tag throbs in step with the alarm; Reduced Motion keeps it lit amber instead.
		_pulse = fmod(_pulse + delta, PULSE_SECONDS)
		var glow: float = 1.0 if reduce_motion else 0.6 + 0.4 * cos(_pulse / PULSE_SECONDS * TAU)
		fault_tag.modulate = Color(1.0, glow, glow * 0.9)
	# Like the junction's plates, a plate the edge of the view cuts fades out rather than show part of
	# its name.
	JunctionRoom.fade_at_view_edge([bypass_label, fault_tag], get_viewport())


## A name plate like the junction's; [param wrap_width] above 0 wraps the caption onto rows that wide,
## and [param foot] leaves that much room under the text.
func _plate(node_name: String, caption: String, text_color: Color, edge: Color, wrap_width: float = 0.0, foot: float = 0.0) -> Label:
	var plate: StyleBoxFlat = StyleBoxFlat.new()
	plate.bg_color = Palette.PLATE_BG
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
	TextSize.size_label(label, LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", text_color)
	label.add_theme_stylebox_override("normal", plate)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap_width > 0.0:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		label.custom_minimum_size.x = wrap_width * TextSize.world_factor()
		label.set_meta(&"wrap_width", wrap_width)
	add_child(label)
	label.size = label.get_combined_minimum_size()
	return label


## TEXT SIZE changed: both plates take the new size (the MANUAL BYPASS plate keeps its two rows; the
## COOLANT FAULT tag breaks onto two above 100%, TextSize.wrap_world_label) and are placed again.
func refit_labels() -> void:
	TextSize.size_label(bypass_label, LABEL_FONT_SIZE)
	bypass_label.custom_minimum_size.x = float(bypass_label.get_meta(&"wrap_width")) * TextSize.world_factor()
	bypass_label.size = Vector2.ZERO
	bypass_label.size = bypass_label.get_combined_minimum_size()
	TextSize.wrap_world_label(fault_tag, LABEL_FONT_SIZE)
	place(position, _relay_x)


## The hold under way: from its press frame the wheel turns part of the way to its next notch, by
## [param fraction] (HoldUse.shown_fraction), and the next crank light warms; at 0 (let go) the part
## turn springs back to the last notch.
func show_hold(fraction: float) -> void:
	if is_equal_approx(fraction, hold_fraction):
		return
	var released: bool = fraction <= 0.0
	hold_fraction = maxf(fraction, 0.0)
	readout.queue_redraw()
	Tweens.kill(_wheel_tween)
	var target: float = TICK_DEGREES * (ticks + hold_fraction)
	if released and is_inside_tree():
		_wheel_tween = create_tween()
		_wheel_tween.tween_property(wheel, "rotation_degrees", target, SPRING_BACK_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		wheel.rotation_degrees = target


func _turn_wheel() -> void:
	Tweens.kill(_wheel_tween)
	# Mid-hold the notch just reached is where the wheel is; show_hold adds the next part turn.
	var target: float = TICK_DEGREES * ticks
	if ticks == 0 or hold_fraction > 0.0 or not is_inside_tree():
		wheel.rotation_degrees = target
		return
	_wheel_tween = create_tween()
	_wheel_tween.tween_property(wheel, "rotation_degrees", target, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## The crank readout, drawn in the plate's foot: dark until the breaker is on, then one cell lights
## amber per tick, and all go green once the bypass has opened the seal.
func _draw_readout() -> void:
	# The leader, in the plate's edge colour, from its bottom edge down to the wheel's backplate.
	var leader_x: float = LEADER_X - bypass_label.position.x
	var leader_top: float = bypass_label.size.y
	var leader_bottom: float = LEADER_END_Y - bypass_label.position.y
	if leader_bottom > leader_top:
		readout.draw_rect(Rect2(leader_x - LEADER_WIDTH * 0.5, leader_top, LEADER_WIDTH, leader_bottom - leader_top), Palette.PLATE_EDGE)
	var row: float = CELL_SIZE.x * TICKS_NEEDED + CELL_GAP * (TICKS_NEEDED - 1)
	var first: Vector2 = Vector2((bypass_label.size.x - row) * 0.5, bypass_label.size.y - READOUT_HEIGHT * 0.5 - CELL_SIZE.y * 0.5 - 1.0)
	for index: int in TICKS_NEEDED:
		var cell: Color = LAMP_OFF
		if live or done:
			cell = Palette.GREEN if done else (Palette.AMBER if index < ticks else LAMP_WAITING)
			if not done and index == ticks and hold_fraction > 0.0:
				# The notch being cranked warms toward amber as the hold adds up.
				cell = LAMP_WAITING.lerp(Palette.AMBER, 0.35 + 0.5 * hold_fraction)
		readout.draw_rect(Rect2(first + Vector2((CELL_SIZE.x + CELL_GAP) * index, 0.0), CELL_SIZE), cell)
