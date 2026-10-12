class_name KeypadCardMockB
extends Control
## MOCK ONLY (option B, lockdown access). A keypad card drawn from the game's own theme
## (MenuPanel, CardSheen, TouchButton, Montserrat/Roboto). Not game code: no input handling,
## just the five looks: idle, entering, denied, lockout, granted. All text is PROPOSED,
## awaiting Nathanial. Revised: every caption is 12 px or more, and touch uses 12 px key gaps.

const CARD_RECT: Rect2 = Rect2(24.0, 86.0, 594.0, 356.0)
const KEY_SIZE: Vector2 = Vector2(90.0, 66.0)
var KEY_GAP: float = 8.0
const GRID_ORIGIN: Vector2 = Vector2(292.0, 58.0)
const DISPLAY_FONT: FontVariation = preload("res://assets/fonts/Montserrat-Bold.tres")
const CONTROL_FONT: FontVariation = preload("res://assets/fonts/Montserrat-Semibold.tres")
const ACCENT: Color = Color("#73DDF5")
const MUTED: Color = Color("#9fc3d2")
const RED: Color = Color("#ff6a55")
const AMBER: Color = Color("#f3ae4b")
const GREEN: Color = Color("#a4f0c4")
const DIM: Color = Color("#3e4f5a")
const KEYS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "DEL", "0", "OK"]

var panel: Panel
var accent_bar: ColorRect
var mode_lamp: Panel
var mode_label: Label
var status_label: Label
var sub_label: Label
var cells: Array[Label] = []
var cell_boxes: Array[Panel] = []
var pips: Array[Panel] = []
var lamp_rows: Dictionary = {}
var known_caption: Label
var known_button: Button
var footer: Label
var close_button: Button
var key_buttons: Dictionary = {}


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func build(touch: bool = false) -> void:
	KEY_GAP = 12.0 if touch else 8.0
	var veil: ColorRect = ColorRect.new()
	veil.color = Color(0.008, 0.018, 0.035, 0.42)
	veil.position = Vector2.ZERO
	veil.size = Vector2(960.0, 442.0)
	add_child(veil)
	panel = Panel.new()
	panel.theme_type_variation = &"MenuPanel"
	panel.position = CARD_RECT.position
	panel.size = CARD_RECT.size + (Vector2(8.0, 12.0) if touch else Vector2.ZERO)
	add_child(panel)
	var sheen: Panel = Panel.new()
	sheen.theme_type_variation = &"CardSheen"
	sheen.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(sheen)
	_label("EXIT BOLT", Rect2(18, 8, 200, 26), 20, Color.WHITE, DISPLAY_FONT)
	_label("READER  ·  SERVICE JUNCTION", Rect2(18, 30, 260, 17), 12, MUTED, CONTROL_FONT)
	mode_lamp = _lamp(Vector2(300, 18), 14.0, AMBER, 7)
	mode_label = _label("MODE: LOCAL", Rect2(320, 14, 175, 22), 14, AMBER, DISPLAY_FONT)
	close_button = Button.new()
	close_button.theme_type_variation = &"TouchButton"
	close_button.text = "CLOSE"
	close_button.add_theme_font_size_override("font_size", 12)
	close_button.position = Vector2(panel.size.x - 96, 10)
	close_button.size = Vector2(80, 32)
	close_button.focus_mode = Control.FOCUS_NONE
	panel.add_child(close_button)
	accent_bar = ColorRect.new()
	accent_bar.color = AMBER
	accent_bar.position = Vector2(18, 48)
	accent_bar.size = Vector2(panel.size.x - 36, 3)
	panel.add_child(accent_bar)
	# Readout window: the reader's own little screen.
	var readout: Panel = Panel.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("#03080c")
	sb.border_color = Color(0.25, 0.46, 0.56, 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	readout.add_theme_stylebox_override("panel", sb)
	readout.position = Vector2(18, 60)
	readout.size = Vector2(258, 118)
	panel.add_child(readout)
	status_label = _label("", Rect2(30, 66, 236, 18), 13, AMBER, DISPLAY_FONT)
	for i: int in range(4):
		var box: Panel = Panel.new()
		var cb: StyleBoxFlat = StyleBoxFlat.new()
		cb.bg_color = Color("#0a1620")
		cb.border_color = Color(0.25, 0.46, 0.56, 0.7)
		cb.border_width_bottom = 2
		cb.set_corner_radius_all(3)
		box.add_theme_stylebox_override("panel", cb)
		box.position = Vector2(32 + i * 60, 90)
		box.size = Vector2(50, 54)
		panel.add_child(box)
		cell_boxes.append(box)
		var cell: Label = _label("", Rect2(32 + i * 60, 88, 50, 56), 36, Color.WHITE, DISPLAY_FONT)
		cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cells.append(cell)
	sub_label = _label("", Rect2(30, 149, 236, 18), 12, MUTED, CONTROL_FONT)
	# Tries: three pips, filled per wrong code.
	_label("TRIES", Rect2(18, 186, 60, 18), 12, MUTED, CONTROL_FONT)
	for i: int in range(3):
		pips.append(_lamp(Vector2(68 + i * 18, 189), 11.0, DIM, 2))
	# Mode legend: shape + word + colour, never colour alone.
	var x: float = 18.0
	for row: Array in [["LOCKDOWN", RED, 0], ["LOCAL", AMBER, 3], ["OPEN", GREEN, 7]]:
		var lamp: Panel = _lamp(Vector2(x, 216), 12.0, row[1], row[2])
		var word: Label = _label(row[0], Rect2(x + 16, 211, 90, 18), 12, row[1], CONTROL_FONT)
		lamp_rows[row[0]] = [lamp, word, row[1]]
		x += 40.0 + row[0].length() * 9.2
	known_caption = _label("", Rect2(18, 240, 258, 18), 12, MUTED, CONTROL_FONT)
	known_button = Button.new()
	known_button.theme_type_variation = &"TouchButton"
	known_button.text = "ENTER KNOWN CODE"
	known_button.add_theme_font_size_override("font_size", 14)
	known_button.position = Vector2(18, 262)
	known_button.size = Vector2(258, 46)
	panel.add_child(known_button)
	footer = _label("", Rect2(18, 312, 258, 40), 12, MUTED, CONTROL_FONT)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# 3x4 phone-layout keypad.
	for i: int in range(KEYS.size()):
		var key: Button = Button.new()
		key.theme_type_variation = &"TouchButton"
		key.text = KEYS[i]
		key.add_theme_font_override("font", DISPLAY_FONT)
		key.add_theme_font_size_override("font_size", 26 if KEYS[i].length() == 1 else 15)
		key.position = GRID_ORIGIN + Vector2((i % 3) * (KEY_SIZE.x + KEY_GAP), (i / 3) * (KEY_SIZE.y + KEY_GAP))
		key.size = KEY_SIZE
		panel.add_child(key)
		key_buttons[KEYS[i]] = key


func _label(text: String, rect: Rect2, font_size: int, tint: Color, font: Font = null) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	if font != null:
		label.add_theme_font_override("font", font)
	panel.add_child(label)
	return label


func _lamp(pos: Vector2, size: float, tint: Color, radius: int) -> Panel:
	var lamp: Panel = Panel.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = tint
	sb.set_corner_radius_all(radius)
	sb.border_color = tint.lightened(0.3)
	sb.set_border_width_all(1)
	lamp.add_theme_stylebox_override("panel", sb)
	lamp.position = pos
	lamp.size = Vector2(size, size)
	panel.add_child(lamp)
	return lamp


func _tint_lamp(lamp: Panel, tint: Color, lit: bool) -> void:
	var sb: StyleBoxFlat = (lamp.get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
	sb.bg_color = tint if lit else Color(tint, 0.0)
	sb.border_color = tint if lit else Color(tint, 0.45)
	sb.shadow_color = Color(tint, 0.6) if lit else Color(0, 0, 0, 0)
	sb.shadow_size = 6 if lit else 0
	lamp.add_theme_stylebox_override("panel", sb)


## mode: LOCKDOWN / LOCAL / OPEN. digits: up to 4 chars. tries: wrong codes so far.
func show_state(mode: String, status: String, sub: String, digits: String, digit_tint: Color, tries: int, known: String, footer_text: String, keys_live: bool, focus_key: String) -> void:
	var mode_tint: Color = {"LOCKDOWN": RED, "LOCAL": AMBER, "OPEN": GREEN}[mode]
	mode_label.text = "MODE: " + mode
	mode_label.add_theme_color_override("font_color", mode_tint)
	_tint_lamp(mode_lamp, mode_tint, true)
	accent_bar.color = RED if digit_tint == RED or mode == "LOCKDOWN" else mode_tint
	status_label.text = status
	status_label.add_theme_color_override("font_color", RED if digit_tint == RED or mode == "LOCKDOWN" else mode_tint)
	sub_label.text = sub
	for i: int in range(4):
		cells[i].text = digits[i] if i < digits.length() else "–"
		cells[i].add_theme_color_override("font_color", digit_tint if i < digits.length() else Color(MUTED, 0.35))
		var cb: StyleBoxFlat = (cell_boxes[i].get_theme_stylebox("panel") as StyleBoxFlat).duplicate()
		cb.border_color = digit_tint if i < digits.length() else (ACCENT if i == digits.length() and keys_live else Color(0.25, 0.46, 0.56, 0.7))
		cell_boxes[i].add_theme_stylebox_override("panel", cb)
	for i: int in range(3):
		_tint_lamp(pips[i], RED, i < tries)
	for word: String in lamp_rows:
		var row: Array = lamp_rows[word]
		_tint_lamp(row[0], row[2], word == mode)
		(row[1] as Label).add_theme_color_override("font_color", row[2] if word == mode else Color(row[2], 0.4))
	known_caption.text = known
	known_button.visible = not known.is_empty()
	known_button.disabled = not keys_live
	footer.text = footer_text
	for k: String in key_buttons:
		var b: Button = key_buttons[k]
		b.disabled = not keys_live
		b.release_focus()
	known_button.release_focus()
	if focus_key == "KNOWN":
		known_button.grab_focus()
	elif not focus_key.is_empty():
		(key_buttons[focus_key] as Button).grab_focus()
