class_name GameSettings
extends Control

const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"interact", &"choice_1", &"choice_2", &"pause_game"]
const ACTION_NAMES: Array[String] = ["Move left", "Move right", "Interact / continue", "Response 1", "Response 2", "Pause"]
const BUSES: Array[String] = ["Master", "Music", "Effects", "Voice"]

var settings_path: String
var tabs: TabBar
var vsync: CheckButton
var antialiasing: OptionButton
var volumes: Dictionary = {}
var binding_buttons: Dictionary = {}
var defaults: Dictionary = {}
var deadzone: HSlider
var cancel_button: Button
var capture_action: StringName = &""
var capture_kind: String = ""
var display_nodes: Array[CanvasItem] = []
var pages: Array[Control] = []
@onready var note: Label = $SettingsNote


func configure(path: String) -> void:
	settings_path = path
	for action: StringName in ACTIONS:
		defaults[action] = InputMap.action_get_events(action)
	_build_menu()
	var config: ConfigFile = ConfigFile.new()
	config.load(settings_path)
	vsync.set_pressed_no_signal(boolean(config, "video", "vsync", true))
	antialiasing.select(clampi(int(number(config, "video", "msaa_2d", 0)), 0, 3))
	_apply_graphics()
	for bus: String in BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, "Master")
		var slider: HSlider = volumes[bus]
		slider.set_value_no_signal(clampf(number(config, "audio", bus, 100.0), 0.0, 100.0))
		_apply_volume(bus, slider.value)
	deadzone.set_value_no_signal(clampf(number(config, "controls", "deadzone", 0.25), 0.1, 0.8))
	_apply_deadzone(deadzone.value)
	var overrides: Dictionary = {}
	for action: StringName in ACTIONS:
		for kind: String in ["keyboard", "controller"]:
			var saved: Variant = config.get_value("bindings", "%s_%s" % [action, kind], {})
			if saved is Dictionary:
				var event: InputEvent = _decode_binding(saved)
				if event != null and _event_kind(event) == kind:
					_replace_binding(action, kind, event)
					overrides["%s_%s" % [action, kind]] = [action, kind, event]
	# Validate the whole loaded map so legitimate key swaps are preserved.
	while not overrides.is_empty():
		var rejected: bool = false
		for key: String in overrides.keys():
			var entry: Array = overrides[key]
			if not _binding_conflict(entry[0], entry[2]).is_empty():
				for old: InputEvent in InputMap.action_get_events(entry[0]):
					if _event_kind(old) == entry[1]:
						InputMap.action_erase_event(entry[0], old)
				for original: InputEvent in defaults[entry[0]]:
					if _event_kind(original) == entry[1]:
						InputMap.action_add_event(entry[0], original)
				overrides.erase(key)
				rejected = true
		if not rejected:
			break
	_refresh_bindings()
	select_tab(0)


static func number(config: ConfigFile, section: String, key: String, fallback: float) -> float:
	var value: Variant = config.get_value(section, key, fallback)
	if (value is int or value is float) and is_finite(float(value)):
		return float(value)
	return fallback


static func boolean(config: ConfigFile, section: String, key: String, fallback: bool) -> bool:
	var value: Variant = config.get_value(section, key, fallback)
	return value if value is bool else fallback


func _build_menu() -> void:
	var surface: Panel = Panel.new()
	surface.position = Vector2(24, 126)
	surface.size = Vector2(712, 240)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var surface_style: StyleBoxFlat = StyleBoxFlat.new()
	surface_style.bg_color = Color("#102333")
	surface_style.set_corner_radius_all(8)
	surface.add_theme_stylebox_override("panel", surface_style)
	add_child(surface)
	move_child(surface, 0)
	var subtitle: Label = _label("WOLF//OVERRIDE  /  PREFERENCES", 12)
	subtitle.position = Vector2(34, 15)
	subtitle.modulate = Color("#89acbf")
	add_child(subtitle)
	$Title.position.y = 35
	$Title.add_theme_font_size_override("font_size", 27)
	tabs = TabBar.new()
	tabs.position = Vector2(32, 81)
	tabs.size = Vector2(696, 38)
	for caption: String in ["DISPLAY", "AUDIO", "CONTROLS"]:
		tabs.add_tab(caption)
	add_child(tabs)
	tabs.tab_changed.connect(select_tab)
	var display: Control = Control.new()
	display.position = Vector2(32, 126)
	display.size = Vector2(696, 240)
	add_child(display)
	pages.append(display)
	for node_name: String in ["FPSLabel", "FPSOptions", "ResolutionLabel", "ResolutionOptions", "FullscreenToggle"]:
		display_nodes.append(get_node(node_name) as CanvasItem)
	$FPSLabel.position = Vector2(40, 144)
	$FPSOptions.position = Vector2(215, 138)
	$ResolutionLabel.position = Vector2(40, 206)
	$ResolutionOptions.position = Vector2(215, 200)
	$FullscreenToggle.position = Vector2(40, 260)
	vsync = CheckButton.new()
	vsync.text = "V-SYNC"
	vsync.position = Vector2(404, 14)
	vsync.size = Vector2(272, 44)
	display.add_child(vsync)
	vsync.disabled = DisplayServer.get_name() == "headless"
	vsync.toggled.connect(func(_value: bool) -> void: _apply_graphics(); _save_extra())
	var aa_label: Label = _label("EDGE SMOOTHING", 16)
	aa_label.position = Vector2(410, 77)
	display.add_child(aa_label)
	antialiasing = OptionButton.new()
	antialiasing.position = Vector2(410, 111)
	antialiasing.size = Vector2(270, 42)
	for caption: String in ["OFF", "2× MSAA", "4× MSAA", "8× MSAA"]:
		antialiasing.add_item(caption)
	display.add_child(antialiasing)
	antialiasing.item_selected.connect(func(_index: int) -> void: _apply_graphics(); _save_extra())
	var gpu: Label = _label("GPU: %s\nRenderer: Compatibility" % RenderingServer.get_video_adapter_name(), 14)
	gpu.position = Vector2(8, 194)
	gpu.size = Vector2(680, 44)
	gpu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	display.add_child(gpu)
	var audio: VBoxContainer = _page_box()
	pages.append(audio)
	for bus: String in BUSES:
		var slider: HSlider = _slider_row(audio, "%s volume" % bus, 0, 100, 1)
		volumes[bus] = slider
		slider.value_changed.connect(func(value: float) -> void: _apply_volume(bus, value); _save_extra())
	var controls_scroll: ScrollContainer = ScrollContainer.new()
	controls_scroll.position = Vector2(40, 128)
	controls_scroll.size = Vector2(680, 234)
	controls_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	controls_scroll.follow_focus = true
	add_child(controls_scroll)
	pages.append(controls_scroll)
	var controls: VBoxContainer = VBoxContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override("separation", 6)
	controls_scroll.add_child(controls)
	var header: HBoxContainer = HBoxContainer.new()
	controls.add_child(header)
	for index: int in 3:
		var column: Label = _label(["ACTION", "KEYBOARD", "CONTROLLER"][index], 14)
		column.custom_minimum_size.x = 220 if index == 0 else 206
		header.add_child(column)
	for index: int in ACTIONS.size():
		var row: HBoxContainer = HBoxContainer.new()
		controls.add_child(row)
		var caption: Label = _label(ACTION_NAMES[index], 16)
		caption.custom_minimum_size.x = 220
		row.add_child(caption)
		for kind: String in ["keyboard", "controller"]:
			var button: Button = Button.new()
			button.custom_minimum_size = Vector2(206, 48)
			button.add_theme_font_size_override("font_size", 15)
			row.add_child(button)
			var action: StringName = ACTIONS[index]
			binding_buttons["%s_%s" % [action, kind]] = button
			button.pressed.connect(begin_capture.bind(action, kind))
	deadzone = _slider_row(controls, "Stick deadzone", 0.1, 0.8, 0.05)
	deadzone.value_changed.connect(func(value: float) -> void: _apply_deadzone(value); _save_extra())
	var reset: Button = Button.new()
	reset.text = "RESTORE DEFAULT CONTROLS"
	reset.custom_minimum_size.y = 40
	controls.add_child(reset)
	reset.pressed.connect(reset_controls)
	$Title.size.x = 690
	$BackButton.position = Vector2(32, 414)
	$BackButton.size = Vector2(180, 38)
	note.position = Vector2(40, 372)
	note.size = Vector2(680, 34)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cancel_button = Button.new()
	cancel_button.position = Vector2(548, 414)
	cancel_button.size = Vector2(180, 38)
	cancel_button.text = "CANCEL REBIND"
	cancel_button.hide()
	add_child(cancel_button)
	cancel_button.pressed.connect(cancel_capture)


func _page_box() -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.position = Vector2(40, 138)
	box.size = Vector2(680, 220)
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	return box


func _label(caption: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = caption
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _slider_row(parent: Node, caption: String, minimum: float, maximum: float, step: float) -> HSlider:
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size.y = 48
	parent.add_child(row)
	var label: Label = _label(caption, 17)
	label.custom_minimum_size.x = 220
	row.add_child(label)
	var slider: HSlider = HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var value_label: Label = _label("", 16)
	value_label.custom_minimum_size.x = 64
	row.add_child(value_label)
	slider.value_changed.connect(func(value: float) -> void: value_label.text = "%d%%" % roundi(value if maximum == 100 else value * 100))
	# Programmatic loads do not emit value_changed.
	row.visibility_changed.connect(func() -> void: value_label.text = "%d%%" % roundi(slider.value if maximum == 100 else slider.value * 100))
	return slider


func apply_theme() -> void:
	var menu_theme: Theme = Theme.new()
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color("#182f40")
	normal.border_color = Color("#345366")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#234859")
	hover.border_color = Color("#64cce5")
	var focus: StyleBoxFlat = StyleBoxFlat.new()
	focus.border_color = Color("#8de5f5")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(5)
	focus.bg_color = Color.TRANSPARENT
	for type_name: String in ["Button", "OptionButton", "CheckButton"]:
		menu_theme.set_stylebox("normal", type_name, normal)
		menu_theme.set_stylebox("hover", type_name, hover)
		menu_theme.set_stylebox("pressed", type_name, hover)
		menu_theme.set_stylebox("focus", type_name, focus)
		menu_theme.set_font_size("font_size", type_name, 16)
	var tab_normal: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	tab_normal.content_margin_left = 20
	tab_normal.content_margin_right = 20
	tab_normal.expand_margin_left = -4
	tab_normal.expand_margin_right = -4
	var tab_selected: StyleBoxFlat = tab_normal.duplicate() as StyleBoxFlat
	tab_selected.bg_color = hover.bg_color
	tab_selected.border_color = hover.border_color
	menu_theme.set_stylebox("tab_selected", "TabBar", tab_selected)
	menu_theme.set_stylebox("tab_unselected", "TabBar", tab_normal)
	var tab_focus: StyleBoxFlat = focus.duplicate() as StyleBoxFlat
	tab_focus.expand_margin_left = -4
	tab_focus.expand_margin_right = -4
	menu_theme.set_stylebox("tab_focus", "TabBar", tab_focus)
	menu_theme.set_font_size("font_size", "TabBar", 16)
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Color("#345366")
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	track.set_corner_radius_all(3)
	menu_theme.set_stylebox("slider", "HSlider", track)
	var fill: StyleBoxFlat = track.duplicate() as StyleBoxFlat
	fill.bg_color = Color("#64cce5")
	menu_theme.set_stylebox("grabber_area", "HSlider", fill)
	menu_theme.set_stylebox("grabber_area_highlight", "HSlider", fill)
	theme = menu_theme
	for label: Label in [$FPSLabel, $ResolutionLabel]:
		label.add_theme_font_size_override("font_size", 16)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for button: Button in [$FPSOptions, $ResolutionOptions, $FullscreenToggle, $BackButton]:
		button.add_theme_font_size_override("font_size", 16)
	for node: Button in [$BackButton, $FPSOptions, $ResolutionOptions]:
		for state: String in ["normal", "hover", "pressed"]:
			node.remove_theme_stylebox_override(state)


func select_tab(index: int) -> void:
	cancel_capture()
	for page_index: int in pages.size():
		pages[page_index].visible = page_index == index
	for node: CanvasItem in display_nodes:
		node.visible = index == 0
	note.text = ["Window size is OS-managed on mobile. V-sync may limit the FPS cap.", "Volume changes apply immediately. Current chapter has no audio tracks yet.", "Select a binding, then press a key, controller button or move a stick."][index]


func _apply_graphics() -> void:
	if not vsync.disabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync.button_pressed else DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_2d = antialiasing.selected as Viewport.MSAA


func _apply_volume(bus: String, value: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	AudioServer.set_bus_mute(index, value <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(value / 100.0, 0.0001)))


func _apply_deadzone(value: float) -> void:
	for action: StringName in ACTIONS:
		InputMap.action_set_deadzone(action, value)


func begin_capture(action: StringName, kind: String) -> void:
	capture_action = action
	capture_kind = kind
	note.text = "Press a %s input for %s. Esc cancels." % [kind, ACTION_NAMES[ACTIONS.find(action)]]
	cancel_button.show()


func cancel_capture() -> void:
	capture_action = &""
	capture_kind = ""
	if cancel_button != null:
		cancel_button.hide()


func _input(event: InputEvent) -> void:
	if capture_action.is_empty() or not is_visible_in_tree():
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_capture()
		note.text = "Rebind cancelled."
		get_viewport().set_input_as_handled()
		return
	var pressed: bool = (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value) >= 0.65)
	if not pressed or _event_kind(event) != capture_kind:
		return
	get_viewport().set_input_as_handled()
	var binding: InputEvent = _decode_binding(_encode_binding(event))
	if binding == null:
		return
	var conflict: StringName = _binding_conflict(capture_action, binding)
	if not conflict.is_empty():
		var action_index: int = ACTIONS.find(conflict)
		var caption: String = ACTION_NAMES[action_index] if action_index >= 0 else str(conflict).replace("_", " ")
		note.text = "Already used by %s. Choose another input or cancel." % caption
		return
	_replace_binding(capture_action, capture_kind, binding)
	cancel_capture()
	_refresh_bindings()
	if _save_extra():
		note.text = "Binding saved."


func _event_kind(event: InputEvent) -> String:
	return "keyboard" if event is InputEventKey else ("controller" if event is InputEventJoypadButton or event is InputEventJoypadMotion else "")


func _binding_conflict(target: StringName, event: InputEvent) -> StringName:
	for action: StringName in InputMap.get_actions():
		if not action.begins_with("ui_") and action != target and InputMap.action_has_event(action, event):
			return action
	return &""


func _replace_binding(action: StringName, kind: String, event: InputEvent) -> void:
	for old: InputEvent in InputMap.action_get_events(action):
		if _event_kind(old) == kind:
			InputMap.action_erase_event(action, old)
	InputMap.action_add_event(action, event)


func _encode_binding(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "code": event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode}
	if event is InputEventJoypadButton:
		return {"type": "button", "code": event.button_index}
	if event is InputEventJoypadMotion:
		return {"type": "axis", "code": event.axis, "direction": -1 if event.axis_value < 0 else 1}
	return {}


func _decode_binding(data: Dictionary) -> InputEvent:
	if not data.get("code") is int:
		return null
	var code: int = data.code
	match data.get("type", ""):
		"key":
			if code <= 0 or code > 0x7FFFFF or OS.get_keycode_string(code as Key).is_empty() or code in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META]:
				return null
			var event: InputEventKey = InputEventKey.new()
			event.physical_keycode = code as Key
			return event
		"button":
			if code < 0 or code >= JOY_BUTTON_MAX:
				return null
			var event: InputEventJoypadButton = InputEventJoypadButton.new()
			event.button_index = code as JoyButton
			return event
		"axis":
			if code < 0 or code >= JOY_AXIS_MAX or data.get("direction") not in [-1, 1]:
				return null
			var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
			event.axis = code as JoyAxis
			event.axis_value = float(data.direction)
			return event
	return null


func binding_label(action: StringName, kind: String) -> String:
	var labels: PackedStringArray = []
	for event: InputEvent in InputMap.action_get_events(action):
		if _event_kind(event) == kind:
			if event is InputEventKey:
				labels.append(OS.get_keycode_string(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode))
			elif event is InputEventJoypadButton:
				labels.append(_button_label(event.button_index))
			elif event is InputEventJoypadMotion:
				labels.append("%s %s" % ["Left stick" if event.axis == JOY_AXIS_LEFT_X else "Axis %d" % event.axis, "−" if event.axis_value < 0 else "+"])
	return " / ".join(labels)


func prompt(action: StringName, controller: bool) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		if not controller and event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode)
		if controller and event is InputEventJoypadButton:
			return _button_label(event.button_index)
		if controller and event is InputEventJoypadMotion:
			return "AXIS %d %s" % [event.axis, "−" if event.axis_value < 0 else "+"]
	return "?"


func _button_label(index: int) -> String:
	match index:
		JOY_BUTTON_A: return "A"
		JOY_BUTTON_B: return "B"
		JOY_BUTTON_X: return "X"
		JOY_BUTTON_Y: return "Y"
		JOY_BUTTON_START: return "START"
		JOY_BUTTON_DPAD_LEFT: return "D-pad left"
		JOY_BUTTON_DPAD_RIGHT: return "D-pad right"
	return "BUTTON %d" % index


func _refresh_bindings() -> void:
	for action: StringName in ACTIONS:
		for kind: String in ["keyboard", "controller"]:
			var button: Button = binding_buttons["%s_%s" % [action, kind]]
			button.text = binding_label(action, kind)
			button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			button.tooltip_text = button.text


func reset_controls() -> void:
	cancel_capture()
	for action: StringName in ACTIONS:
		InputMap.action_erase_events(action)
		for event: InputEvent in defaults[action]:
			InputMap.action_add_event(action, event)
	deadzone.value = 0.25
	_refresh_bindings()
	if _save_extra():
		note.text = "Default controls restored."


func _save_extra() -> bool:
	var config: ConfigFile = ConfigFile.new()
	config.load(settings_path)
	config.set_value("video", "vsync", vsync.button_pressed)
	config.set_value("video", "msaa_2d", antialiasing.selected)
	for bus: String in BUSES:
		config.set_value("audio", bus, (volumes[bus] as HSlider).value)
	config.set_value("controls", "deadzone", deadzone.value)
	for action: StringName in ACTIONS:
		for kind: String in ["keyboard", "controller"]:
			var key: String = "%s_%s" % [action, kind]
			if config.has_section_key("bindings", key):
				config.erase_section_key("bindings", key)
			var current: Array[Dictionary] = _family_bindings(InputMap.action_get_events(action), kind)
			if current != _family_bindings(defaults[action], kind) and not current.is_empty():
				config.set_value("bindings", key, current[0])
	if config.save(settings_path) != OK:
		note.text = "Settings could not be saved."
		return false
	return true


func _family_bindings(events: Array[InputEvent], kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event: InputEvent in events:
		if _event_kind(event) == kind:
			result.append(_encode_binding(event))
	return result
