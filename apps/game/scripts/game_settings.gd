class_name GameSettings
extends Control
## The Settings menu, shared by the title and Pause: its DISPLAY, AUDIO, CONTROLS and GENERAL tabs, built
## in code by [method configure] from the saved settings file, which every change writes back at once
## ([method _save_extra]). GENERAL holds LANGUAGE (localization PR L6, decision D10) and stays hidden
## while the game offers one language.
##
## Translation (localization PR L7a; the three ways are in I18n's class notes): captions whose whole text
## is one message keep the English and auto-translate, marked for the translation template with
## [code]I18n.KEY.tr()[/code] where the generator would not find them; text worked out here (the note
## under the tabs, key and button names, the binding buttons) is translated with tr() as it is worked out,
## on Controls whose auto-translate is off, and is worked out again on NOTIFICATION_TRANSLATION_CHANGED.

const BODY_FONT: FontVariation = preload("res://assets/fonts/Roboto-Regular.tres")
const CONTROL_FONT: FontVariation = preload("res://assets/fonts/Montserrat-Semibold.tres")
const HEADING_FONT: FontVariation = preload("res://assets/fonts/Montserrat-Bold.tres")
const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"interact", &"choice_1", &"choice_2", &"pause_game"]
## The display name of each of [constant ACTIONS], in its order: English, translated where it is drawn
## (the CONTROLS rows auto-translate; the notes call tr()). A static var rather than a const only so the
## names can carry the I18n.KEY.tr() marks the translation template is extracted from (a const
## initialiser cannot call a method).
static var ACTION_NAMES: Array[String] = [I18n.KEY.tr("Move left"), I18n.KEY.tr("Move right"), I18n.KEY.tr("Interact / continue"), I18n.KEY.tr("Response 1"), I18n.KEY.tr("Response 2"), I18n.KEY.tr("Pause")]
## Display names of the other actions a rebind can clash with (Main's _install_inputs), so the "Already
## used by" note never shows an id. The English is the id with "_" as a space, as the note showed before.
static var OTHER_ACTION_NAMES: Dictionary = {&"cycle_name": I18n.KEY.tr("cycle name")}
## The AudioServer buses Settings controls, by id: the ids are the settings file's [audio] keys and the
## bus names, never shown.
const BUSES: Array[String] = ["Master", "Music", "Effects", "Voice"]
## The AUDIO row caption of each of [constant BUSES], in its order (a display name, not the bus id; a
## static var for the marks, like ACTION_NAMES).
static var BUS_CAPTIONS: Array[String] = [I18n.KEY.tr("Master volume"), I18n.KEY.tr("Music volume"), I18n.KEY.tr("Effects volume"), I18n.KEY.tr("Voice volume")]
## Display servers whose DisplayServer.keyboard_get_label_from_physical reads the active keyboard layout
## (Godot 4.7.2: DisplayServerX11, DisplayServerWayland, DisplayServerWindows, DisplayServerMacOSBase).
## Every other one (headless, Android, iOS, the web) has only the base version, which logs "Not supported
## by this display server." and returns the code (servers/display/display_server.cpp), so there a key
## keeps the name of its US QWERTY position, as every key did before PR L7a.
const KEY_LABEL_SERVERS: Array[String] = ["X11", "Wayland", "Windows", "macOS"]
## The context of the key names' messages, so "Pause" the key and "Pause" the action, or "Back" and
## "Home", can be translated apart.
const KEY_NAME_CONTEXT: StringName = &"key name"
## The named keys (Godot 4.7.2 core/os/keyboard.cpp, keycode_get_string) a player can bind and read, marked
## for the translation template. [method key_name] translates any name with words through tr(), so this
## list only decides which names a translator is offered; the media, launch and modifier keys (Settings
## refuses modifiers) and the keypad's digits are left out, and a name with one letter or none ("F5", "E") needs no translation.
static var KEY_NAMES: Array[String] = [I18n.KEY.tr("Escape", KEY_NAME_CONTEXT), I18n.KEY.tr("Tab", KEY_NAME_CONTEXT), I18n.KEY.tr("Backspace", KEY_NAME_CONTEXT), I18n.KEY.tr("Enter", KEY_NAME_CONTEXT), I18n.KEY.tr("Kp Enter", KEY_NAME_CONTEXT), I18n.KEY.tr("Insert", KEY_NAME_CONTEXT), I18n.KEY.tr("Delete", KEY_NAME_CONTEXT), I18n.KEY.tr("Pause", KEY_NAME_CONTEXT), I18n.KEY.tr("Print", KEY_NAME_CONTEXT), I18n.KEY.tr("Clear", KEY_NAME_CONTEXT), I18n.KEY.tr("Home", KEY_NAME_CONTEXT), I18n.KEY.tr("End", KEY_NAME_CONTEXT), I18n.KEY.tr("Left", KEY_NAME_CONTEXT), I18n.KEY.tr("Up", KEY_NAME_CONTEXT), I18n.KEY.tr("Right", KEY_NAME_CONTEXT), I18n.KEY.tr("Down", KEY_NAME_CONTEXT), I18n.KEY.tr("PageUp", KEY_NAME_CONTEXT), I18n.KEY.tr("PageDown", KEY_NAME_CONTEXT), I18n.KEY.tr("CapsLock", KEY_NAME_CONTEXT), I18n.KEY.tr("NumLock", KEY_NAME_CONTEXT), I18n.KEY.tr("ScrollLock", KEY_NAME_CONTEXT), I18n.KEY.tr("Kp Multiply", KEY_NAME_CONTEXT), I18n.KEY.tr("Kp Divide", KEY_NAME_CONTEXT), I18n.KEY.tr("Kp Subtract", KEY_NAME_CONTEXT), I18n.KEY.tr("Kp Period", KEY_NAME_CONTEXT), I18n.KEY.tr("Kp Add", KEY_NAME_CONTEXT), I18n.KEY.tr("Menu", KEY_NAME_CONTEXT), I18n.KEY.tr("Help", KEY_NAME_CONTEXT), I18n.KEY.tr("Space", KEY_NAME_CONTEXT)]
const MAX_SETTINGS_BYTES: int = 65536
## Window sizes offered in Settings, by index. A first launch (no saved size) opens at
## DEFAULT_WINDOW_SIZE, the same size project.godot gives the first window, so the characters are
## not drawn at the smallest size. Mobile windows are OS-managed and ignore both.
const WINDOW_SIZES: Array[Vector2i] = [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]
const DEFAULT_WINDOW_SIZE: int = 1
## The Display tab's note (Q10, October 14, 2026): the window-size sentence shows only on phones and
## tablets, where the OS sizes the window; the V-sync sentence applies everywhere.
const MOBILE_WINDOW_NOTE: String = "Window size is OS-managed on mobile."
const VSYNC_NOTE: String = "V-sync may limit the FPS cap."
## The GENERAL tab's index, after the three older tabs so their indices (which the parity capture, the UI
## dump and the tests use) stay as they were while the tab is hidden (PR L6).
const GENERAL_TAB: int = 3
## The "machine translation" tag's size (px), under a name in the open list and under the LANGUAGE row:
## smaller than the 16 px names, so the name row keeps its width (DESIGN.md, "Settings").
const TAG_FONT_PX: int = 12
## The muted blue-grey of secondary text in this menu: the THE DEN / LOCAL CONFIGURATION subtitle, and
## since PR L6 the "machine translation" tags, which read as notes beside the names.
const MUTED_TEXT: Color = Color("#89acbf")

## Reduced Motion changed; Main hands it to the impact kit (no shake or hit-stop, shorter flashes).
signal reduced_motion_changed(enabled: bool)
## TOGGLE HOLDS changed: with it on, one press of interact works a crank until a second press.
signal hold_toggle_changed(enabled: bool)
## TEXT SIZE changed (TextSize.factor already holds the new factor); Main lays the HUD out again.
signal text_size_changed(factor: float)

var settings_path: String
var tabs: TabBar
var vsync: CheckButton
var antialiasing: OptionButton
var reduced_motion: CheckButton
var text_size: OptionButton
## LANGUAGE on the GENERAL tab: one item per offered language, named in its own language (never
## translated), each item's metadata its I18n code; an unreviewed language's tag follows as a labelled
## separator, so it is a second, smaller row nobody can select.
var language: OptionButton
## Under LANGUAGE: the chosen language's "machine translation" tag while it is unreviewed, else hidden.
var language_note: Label
var volumes: Dictionary = {}
var binding_buttons: Dictionary = {}
var defaults: Dictionary = {}
var deadzone: HSlider
var hold_toggle: CheckButton
var cancel_button: Button
var capture_action: StringName = &""
var capture_kind: String = ""
var display_nodes: Array[CanvasItem] = []
var pages: Array[Control] = []
## A phone or tablet build (iOS or Android): the window is the OS's, and the Display note says so.
var mobile: bool = OS.has_feature("ios") or OS.has_feature("android")
## prompt() labels by action, for keys and for a controller; the HUD asks for them every frame, so
## they are worked out once and forgotten whenever this menu changes a binding or the language changes.
var _key_prompts: Dictionary = {}
var _pad_prompts: Dictionary = {}
## The language the remembered prompt() labels are in (TranslationServer's locale, and whether
## pseudolocalization was on). prompt() checks it on every call rather than clearing the labels on
## NOTIFICATION_TRANSLATION_CHANGED: the notification reaches Main before this child, so Main's own
## handler (Pause's hint) would still read the old language's names.
var _prompts_language: String = ""
## The language the player picked (or the file held), written back as [general] language; "" while
## none was chosen, so the game keeps following the OS (DESIGN.md: no "follow the system" entry; the
## first run follows the OS, and a pick is kept).
var _picked_language: String = ""
## The note under the tabs as English: its message and the messages filled into it (see [method show_note]),
## kept so a language change can translate it again.
var _note_message: String = ""
var _note_inserts: Array[String] = []
@onready var note: Label = $SettingsNote


func configure(path: String) -> void:
	settings_path = path
	for action: StringName in ACTIONS:
		defaults[action] = InputMap.action_get_events(action)
	_build_menu()
	var config: ConfigFile = load_config(settings_path)
	vsync.set_pressed_no_signal(boolean(config, "video", "vsync", true))
	antialiasing.select(clampi(int(number(config, "video", "msaa_2d", 0)), 0, 3))
	reduced_motion.set_pressed_no_signal(boolean(config, "video", "reduced_motion", false))
	# The saved language, or the start-up locale's when none was chosen (I18n.saved), applied before the
	# menus are drawn; a saved code stays saved even while it is not offered.
	var saved_language: Variant = config.get_value(I18n.CONFIG_SECTION, I18n.CONFIG_KEY, "")
	_picked_language = saved_language if saved_language is String else ""
	I18n.apply(I18n.saved(config))
	refresh_languages()
	TextSize.factor = TextSize.nearest_step(number(config, "video", "text_size", 1.0))
	text_size.select(TextSize.STEPS.find(TextSize.factor))
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
	hold_toggle.set_pressed_no_signal(boolean(config, "controls", "hold_toggle", false))
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


## Reads a settings file without letting it construct objects or load resources.
## ConfigFile.load parses object and resource forms before any value can be checked.
static func load_config(path: String) -> ConfigFile:
	var config: ConfigFile = ConfigFile.new()
	if not FileAccess.file_exists(path):
		return config
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return config
	if file.get_length() > MAX_SETTINGS_BYTES:
		file.close()
		push_warning("Settings file is too large; using defaults.")
		return config
	var text: String = file.get_as_text()
	file.close()
	# Reject the bare names too, so a comment between a name and "(" cannot slip past.
	var unsafe: RegEx = RegEx.create_from_string("\\b(Object|Resource|SubResource|ExtResource)\\b")
	if unsafe.search(text) != null:
		push_warning("Settings file has unexpected content; using defaults.")
		return config
	# A damaged file is expected input here, so report it once as a warning, not an engine error.
	var printing: bool = Engine.print_error_messages
	Engine.print_error_messages = false
	var result: Error = config.parse(text)
	Engine.print_error_messages = printing
	if result != OK:
		push_warning("Settings file could not be read; using defaults.")
		return ConfigFile.new()
	return config


static func number(config: ConfigFile, section: String, key: String, fallback: float) -> float:
	var value: Variant = config.get_value(section, key, fallback)
	if (value is int or value is float) and is_finite(float(value)):
		return float(value)
	return fallback


static func boolean(config: ConfigFile, section: String, key: String, fallback: bool) -> bool:
	var value: Variant = config.get_value(section, key, fallback)
	return value if value is bool else fallback


## The saved window size's index into WINDOW_SIZES; an unreadable value opens at the default.
static func saved_window_index(config: ConfigFile) -> int:
	return clampi(int(number(config, "video", "resolution", DEFAULT_WINDOW_SIZE)), 0, WINDOW_SIZES.size() - 1)


static func window_size(index: int) -> Vector2i:
	return WINDOW_SIZES[index] if index >= 0 and index < WINDOW_SIZES.size() else WINDOW_SIZES[DEFAULT_WINDOW_SIZE]


## Applies the saved window size and fullscreen (desktop only). Run at launch by the logo screen and
## again by the title, so it changes nothing the second time: a fullscreen window keeps its size.
static func apply_saved_window(window: Window, config: ConfigFile) -> void:
	if window.mode == Window.MODE_WINDOWED:
		# The OS centres the first window at the project's 1280x720 override; a different saved size
		# is applied here, so centre again rather than leave it anchored to the 1280x720 corner.
		var wanted: Vector2i = window_size(saved_window_index(config))
		if window.size != wanted:
			window.size = wanted
			window.move_to_center()
	if boolean(config, "video", "fullscreen", false) and window.mode != Window.MODE_FULLSCREEN:
		window.mode = Window.MODE_FULLSCREEN


func _build_menu() -> void:
	var surface: Panel = Panel.new()
	surface.position = Vector2(24, 126)
	surface.size = Vector2(712, 240)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	surface.theme_type_variation = &"TerminalPanel"
	add_child(surface)
	move_child(surface, 0)
	var subtitle: Label = _label(I18n.KEY.tr("THE DEN  /  LOCAL CONFIGURATION"), 13)
	subtitle.position = Vector2(34, 15)
	subtitle.modulate = MUTED_TEXT
	subtitle.add_theme_font_override("font", CONTROL_FONT)
	add_child(subtitle)
	$Title.position.y = 35
	$Title.add_theme_font_override("font", HEADING_FONT)
	$Title.add_theme_font_size_override("font_size", 27)
	tabs = TabBar.new()
	tabs.theme_type_variation = &"TerminalTabBar"
	tabs.position = Vector2(32, 81)
	tabs.size = Vector2(696, 38)
	for caption: String in [I18n.KEY.tr("DISPLAY"), I18n.KEY.tr("AUDIO"), I18n.KEY.tr("CONTROLS"), I18n.KEY.tr("GENERAL")]:
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
	antialiasing = _option_row(display, I18n.KEY.tr("EDGE SMOOTHING"), Rect2(410, 77, 0, 0), Rect2(410, 111, 270, 42), [I18n.KEY.tr("OFF"), I18n.KEY.tr("2× MSAA"), I18n.KEY.tr("4× MSAA"), I18n.KEY.tr("8× MSAA")])
	antialiasing.item_selected.connect(func(_index: int) -> void: _apply_graphics(); _save_extra())
	reduced_motion = CheckButton.new()
	reduced_motion.text = "REDUCED MOTION"
	reduced_motion.tooltip_text = "No camera shake or hit-stop; screen flashes are shorter."
	reduced_motion.position = Vector2(404, 154)
	reduced_motion.size = Vector2(272, 40)
	display.add_child(reduced_motion)
	reduced_motion.toggled.connect(func(value: bool) -> void: reduced_motion_changed.emit(value); _save_extra())
	# TEXT SIZE scales the play HUD's words and the station names, 100% to 200% (TextSize).
	var size_captions: Array[String] = []
	for step: float in TextSize.STEPS:
		size_captions.append("%d%%" % roundi(step * 100.0))
	text_size = _option_row(display, I18n.KEY.tr("TEXT SIZE"), Rect2(410, 198, 100, 40), Rect2(520, 196, 160, 40), size_captions)
	text_size.tooltip_text = "Scales the dialogue, hints, cards and station names."
	text_size.item_selected.connect(func(index: int) -> void: TextSize.factor = TextSize.STEPS[index]; text_size_changed.emit(TextSize.factor); _save_extra())
	var audio: VBoxContainer = _page_box()
	pages.append(audio)
	for index: int in BUSES.size():
		var bus: String = BUSES[index]
		var slider: HSlider = _slider_row(audio, BUS_CAPTIONS[index], 0, 100, 1)
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
		var column: Label = _label([I18n.KEY.tr("ACTION"), I18n.KEY.tr("KEYBOARD"), I18n.KEY.tr("CONTROLLER")][index], 14)
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
			# Key and button names are translated as they are worked out (_refresh_bindings), so the
			# button must not translate them again.
			button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			button.custom_minimum_size = Vector2(206, 48)
			button.add_theme_font_size_override("font_size", 15)
			row.add_child(button)
			var action: StringName = ACTIONS[index]
			binding_buttons["%s_%s" % [action, kind]] = button
			button.pressed.connect(begin_capture.bind(action, kind))
	deadzone = _slider_row(controls, I18n.KEY.tr("Stick deadzone"), 0.1, 0.8, 0.05)
	deadzone.value_changed.connect(func(value: float) -> void: _apply_deadzone(value); _save_extra())
	# For every device at once, since every crank goes through the one interact action.
	hold_toggle = CheckButton.new()
	hold_toggle.text = "TOGGLE HOLDS"
	hold_toggle.tooltip_text = "Press interact once to start a crank and again to stop it, instead of holding it down. Keyboard, controller and touch."
	hold_toggle.custom_minimum_size.y = 44
	controls.add_child(hold_toggle)
	hold_toggle.toggled.connect(func(value: bool) -> void: hold_toggle_changed.emit(value); _save_extra())
	var reset: Button = Button.new()
	reset.text = "RESTORE DEFAULT CONTROLS"
	reset.custom_minimum_size.y = 40
	controls.add_child(reset)
	reset.pressed.connect(reset_controls)
	_build_general_page()
	$Title.size.x = 690
	$BackButton.position = Vector2(32, 414)
	$BackButton.size = Vector2(180, 38)
	note.position = Vector2(40, 372)
	note.size = Vector2(680, 34)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# The note is often filled in (an action's name, the Display note's two sentences), so show_note
	# translates it and the Label must not translate it again.
	note.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	cancel_button = Button.new()
	cancel_button.position = Vector2(548, 414)
	cancel_button.size = Vector2(180, 38)
	cancel_button.text = "CANCEL REBIND"
	cancel_button.hide()
	add_child(cancel_button)
	cancel_button.pressed.connect(cancel_capture)


## The GENERAL page (pages[GENERAL_TAB]), laid out like DISPLAY's left column: the LANGUAGE caption, its
## list and the tag note under it. The list and the note draw with I18n.picker_font, so every name and
## tag draws in any language, and never translate (I18n.OWN_LANGUAGE_META marks them for the pseudo
## audit). [method refresh_languages] fills the list.
func _build_general_page() -> void:
	var general: Control = Control.new()
	general.position = Vector2(32, 126)
	general.size = Vector2(696, 240)
	add_child(general)
	pages.append(general)
	# The list takes the longest name's width (fit_to_longest_item), at least 300 px: "Español
	# (Latinoamérica)" is about 250 px, the width DISPLAY could not give (D10).
	language = _option_row(general, I18n.KEY.tr("LANGUAGE"), Rect2(8, 12, 160, 40), Rect2(183, 12, 300, 40), [])
	var font: FontVariation = I18n.picker_font(CONTROL_FONT)
	language.add_theme_font_override(&"font", font)
	var popup: PopupMenu = language.get_popup()
	popup.add_theme_font_override(&"font", font)
	popup.add_theme_font_override(&"font_separator", font)
	popup.add_theme_font_size_override(&"font_separator_size", TAG_FONT_PX)
	popup.add_theme_color_override(&"font_separator_color", MUTED_TEXT)
	for side: StringName in [&"labeled_separator_left", &"labeled_separator_right"]:
		popup.add_theme_stylebox_override(side, StyleBoxEmpty.new())
	language_note = _label("", TAG_FONT_PX)
	language_note.position = Vector2(183, 56)
	language_note.size = Vector2(300, 20)
	language_note.modulate = MUTED_TEXT
	language_note.add_theme_font_override(&"font", font)
	general.add_child(language_note)
	for control: Node in [language, popup, language_note]:
		control.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		control.set_meta(I18n.OWN_LANGUAGE_META, true)
	language.item_selected.connect(func(index: int) -> void: pick_language(str(language.get_item_metadata(index))))


## Fills LANGUAGE with I18n.offered(), each language's tag under it while it is unreviewed, shows the
## current language as chosen, and hides the GENERAL tab while only one language is offered ("With one
## language it stays hidden", PLAN.md L6). Called by [method configure]; a test that turns a language on
## in I18n.LANGUAGES calls it again.
func refresh_languages() -> void:
	language.clear()
	var offered: PackedStringArray = I18n.offered()
	for code: String in offered:
		language.add_item(str((I18n.LANGUAGES[code] as Dictionary)["name"]))
		language.set_item_metadata(language.item_count - 1, code)
		var tag: String = I18n.machine_tag(code)
		if not tag.is_empty():
			language.add_separator(tag)
	tabs.set_tab_hidden(GENERAL_TAB, offered.size() < 2)
	_show_language()


## Switches the game to [param code] (an offered language) for good: applies it, which redraws every
## auto-translating Control and, through NOTIFICATION_TRANSLATION_CHANGED, this list, and saves it as
## [general] language.
func pick_language(code: String) -> void:
	_picked_language = code
	I18n.apply(code)
	_save_extra()


## Shows the game's current language as LANGUAGE's choice, and its tag under the row while it is
## unreviewed. The current language is read from TranslationServer, so a change made anywhere (this
## list, a capture or a test calling I18n.apply) shows here.
func _show_language() -> void:
	var code: String = I18n.resolve(TranslationServer.get_locale())
	for index: int in language.item_count:
		if language.get_item_metadata(index) == code:
			language.select(index)
	# The closed button shapes the name as its own language (TextServer's language for the run).
	language.language = code
	language_note.text = I18n.machine_tag(code)
	language_note.visible = not language_note.text.is_empty()


## On a language change, however it was made: the language list follows it (the prototype's bug: a
## list that kept showing the old choice after a change made elsewhere), and the text this menu works out
## and translates itself is worked out again: the binding buttons and the note. The remembered prompt()
## labels follow the language by themselves (see _prompts_language; the cache the lighter plan's S01
## extends to the HUD must forget a language's key names the same way).
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and language != null:
		_show_language()
		_refresh_bindings()
		_show_translated_note()


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


## A captioned drop-down on [param page]: a 16 px label reading [param caption] at
## [param label_rect]'s position (and at its size, unless that is zero, when the label keeps its own),
## then an OptionButton at [param option_rect] (page px) holding [param items] in order, label first in
## the tree. Returns the OptionButton; the caller connects it and sets anything else. The DISPLAY
## page's EDGE SMOOTHING and TEXT SIZE rows and the GENERAL page's LANGUAGE row are made with it.
func _option_row(page: Control, caption: String, label_rect: Rect2, option_rect: Rect2, items: Array[String]) -> OptionButton:
	var label: Label = _label(caption, 16)
	label.position = label_rect.position
	if label_rect.size != Vector2.ZERO:
		label.size = label_rect.size
	page.add_child(label)
	var option: OptionButton = OptionButton.new()
	option.position = option_rect.position
	option.size = option_rect.size
	for item: String in items:
		option.add_item(item)
	page.add_child(option)
	return option


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


## Settings is the one menu that keeps the terminal look (squared corners, label-style controls).
## Its styles are the Terminal* variations of the project theme (game_theme.tres); a local theme
## maps them onto the plain Button types so every control built here, now or later, picks them up.
## CheckButton focus and the TabBar ring still fall through to the shared project entries.
func apply_theme() -> void:
	var source: Theme = ThemeDB.get_project_theme()
	var menu_theme: Theme = Theme.new()
	menu_theme.default_font = BODY_FONT
	menu_theme.default_font_size = 16
	for type_name: String in ["Button", "OptionButton", "CheckButton"]:
		menu_theme.set_font("font", type_name, CONTROL_FONT)
		menu_theme.set_font_size("font_size", type_name, 16)
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			menu_theme.set_stylebox(state, type_name, source.get_stylebox(state, "TerminalButton"))
	# Buttons and option lists get the squared ring. A CheckButton would find the local Button ring first,
	# so it is pinned to the shared project ring that the title and sliders use.
	for type_name: String in ["Button", "OptionButton"]:
		menu_theme.set_stylebox("focus", type_name, source.get_stylebox("focus", "TerminalButton"))
	menu_theme.set_stylebox("focus", "CheckButton", source.get_stylebox("focus", "CheckButton"))
	menu_theme.set_font("font", "TabBar", CONTROL_FONT)
	menu_theme.set_font_size("font_size", "TabBar", 16)
	theme = menu_theme
	for label: Label in [$FPSLabel, $ResolutionLabel]:
		label.add_theme_font_size_override("font_size", 16)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	for button: Button in [$FPSOptions, $ResolutionOptions, $FullscreenToggle, $BackButton]:
		button.add_theme_font_size_override("font_size", 16)


func select_tab(index: int) -> void:
	cancel_capture()
	for page_index: int in pages.size():
		pages[page_index].visible = page_index == index
	for node: CanvasItem in display_nodes:
		node.visible = index == 0
	if index == 0:
		# The Display tab's note: the window-size sentence only where the OS manages the window (Q10).
		if mobile:
			show_note("%s %s", [I18n.KEY.tr(MOBILE_WINDOW_NOTE), I18n.KEY.tr(VSYNC_NOTE)])
		else:
			show_note(I18n.KEY.tr(VSYNC_NOTE))
	else:
		show_note([I18n.KEY.tr("Volume changes apply immediately. Effects carries every sound effect; there is no music or voice yet."), I18n.KEY.tr("Select a binding, then press a key, controller button or move a stick."), I18n.KEY.tr("Until you choose a language, the game uses your system's.")][index - 1])


## Shows [param message] (English) in the note under the tabs, in the current language: tr(message), with
## [param inserts] (English messages too: action names, sentences) each translated and filled in with %.
## Both are remembered, so a language change shows the note again in the new language. The one way the
## note is written, also by Main (its window-size and save-failure notes). A message with no words
## ("%s %s") is left as it is. Mark a literal passed here with I18n.KEY.tr(), since the template
## generator does not look inside this call.
func show_note(message: String, inserts: Array[String] = []) -> void:
	_note_message = message
	_note_inserts = inserts
	_show_translated_note()


## Writes the remembered note ([method show_note]) translated into the current language.
func _show_translated_note() -> void:
	var text: String = tr(_note_message) if I18n.has_words(_note_message) else _note_message
	if not _note_inserts.is_empty():
		var filled: Array[String] = []
		for insert: String in _note_inserts:
			filled.append(tr(insert))
		text = text % filled
	note.text = text


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
	# One message per device, so the note names the device in words, not by its id ("keyboard"), and a
	# translation can phrase each one whole.
	var message: String = I18n.KEY.tr("Press a keyboard input for %s. Esc cancels.") if kind == "keyboard" else I18n.KEY.tr("Press a controller input for %s. Esc cancels.")
	show_note(message, [ACTION_NAMES[ACTIONS.find(action)]])
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
		show_note(I18n.KEY.tr("Rebind cancelled."))
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
		# An action with no display name (a debug tool's) still shows its id with "_" as a space.
		var caption: String = ACTION_NAMES[action_index] if action_index >= 0 else str(OTHER_ACTION_NAMES.get(conflict, str(conflict).replace("_", " ")))
		show_note(I18n.KEY.tr("Already used by %s. Choose another input or cancel."), [caption])
		return
	_replace_binding(capture_action, capture_kind, binding)
	cancel_capture()
	_refresh_bindings()
	if _save_extra():
		show_note(I18n.KEY.tr("Binding saved."))


func _event_kind(event: InputEvent) -> String:
	return "keyboard" if event is InputEventKey else ("controller" if event is InputEventJoypadButton or event is InputEventJoypadMotion else "")


func _binding_conflict(target: StringName, event: InputEvent) -> StringName:
	for action: StringName in InputMap.get_actions():
		if not action.begins_with("ui_") and action != target and InputMap.action_has_event(action, event):
			return action
	return &""


func _replace_binding(action: StringName, kind: String, event: InputEvent) -> void:
	_forget_prompts()
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
				labels.append(key_name(event))
			elif event is InputEventJoypadButton:
				labels.append(_button_label(event.button_index))
			elif event is InputEventJoypadMotion:
				labels.append("%s %s" % [tr("Left stick") if event.axis == JOY_AXIS_LEFT_X else tr("Axis %d") % event.axis, "−" if event.axis_value < 0 else "+"])
	return " / ".join(labels)


## The label of the first key (or controller input) bound to [param action], in the current language and,
## for a key, as printed on the player's keyboard ([method key_name]); remembered until a binding or the
## language changes.
func prompt(action: StringName, controller: bool) -> String:
	var shown_in: String = "%s %s" % [TranslationServer.get_locale(), TranslationServer.pseudolocalization_enabled]
	if shown_in != _prompts_language:
		_forget_prompts()
		_prompts_language = shown_in
	var known: Dictionary = _pad_prompts if controller else _key_prompts
	if known.has(action):
		return known[action]
	var label: String = _prompt_label(action, controller)
	known[action] = label
	return label


func _prompt_label(action: StringName, controller: bool) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		if not controller and event is InputEventKey:
			return key_name(event)
		if controller and event is InputEventJoypadButton:
			return _button_label(event.button_index)
		if controller and event is InputEventJoypadMotion:
			return tr("AXIS %d %s") % [event.axis, "−" if event.axis_value < 0 else "+"]
	return "?"


## The name of [param event]'s key as the player reads it. Where the display server can tell
## ([constant KEY_LABEL_SERVERS]) it is the label printed on the key in the active keyboard layout
## (DisplayServer.keyboard_get_label_from_physical), so on AZERTY the key bound to "Move left" by its
## QWERTY position A reads Q; elsewhere it is the US QWERTY position's name, as before. A key that types
## a character shows that character, because Godot names symbol keys in English words (AZERTY's 1 key
## would read "Ampersand"); letters and digits read as they always did. A named key ("Escape", "Left")
## is translated with the "key name" context ([constant KEY_NAMES]); one with fewer than two letters
## ("F5") is left as it is (I18n.has_words).
func key_name(event: InputEventKey) -> String:
	var code: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	if event.physical_keycode != KEY_NONE and DisplayServer.get_name() in KEY_LABEL_SERVERS:
		code = DisplayServer.keyboard_get_label_from_physical(event.physical_keycode)
	# Below KEY_SPECIAL a Key is the Unicode character it types; KEY_SPACE types nothing visible.
	if code > KEY_SPACE and code < KEY_SPECIAL:
		return String.chr(code)
	var name: String = OS.get_keycode_string(code)
	return tr(name, KEY_NAME_CONTEXT) if I18n.has_words(name) else name


## The name of controller button [param index], in the current language: the face buttons keep their
## printed letters (A, B, X, Y), the rest are translated.
func _button_label(index: int) -> String:
	match index:
		JOY_BUTTON_A: return "A"
		JOY_BUTTON_B: return "B"
		JOY_BUTTON_X: return "X"
		JOY_BUTTON_Y: return "Y"
		JOY_BUTTON_START: return tr("START")
		JOY_BUTTON_DPAD_LEFT: return tr("D-pad left")
		JOY_BUTTON_DPAD_RIGHT: return tr("D-pad right")
	return tr("BUTTON %d") % index


func _forget_prompts() -> void:
	_key_prompts.clear()
	_pad_prompts.clear()


func _refresh_bindings() -> void:
	_forget_prompts()
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
		show_note(I18n.KEY.tr("Default controls restored."))


func _save_extra() -> bool:
	var config: ConfigFile = load_config(settings_path)
	config.set_value("video", "vsync", vsync.button_pressed)
	config.set_value("video", "msaa_2d", antialiasing.selected)
	config.set_value("video", "reduced_motion", reduced_motion.button_pressed)
	config.set_value("video", "text_size", TextSize.factor)
	if not _picked_language.is_empty():
		config.set_value(I18n.CONFIG_SECTION, I18n.CONFIG_KEY, _picked_language)
	for bus: String in BUSES:
		config.set_value("audio", bus, (volumes[bus] as HSlider).value)
	config.set_value("controls", "deadzone", deadzone.value)
	config.set_value("controls", "hold_toggle", hold_toggle.button_pressed)
	for action: StringName in ACTIONS:
		for kind: String in ["keyboard", "controller"]:
			var key: String = "%s_%s" % [action, kind]
			if config.has_section_key("bindings", key):
				config.erase_section_key("bindings", key)
			var current: Array[Dictionary] = _family_bindings(InputMap.action_get_events(action), kind)
			if current != _family_bindings(defaults[action], kind) and not current.is_empty():
				config.set_value("bindings", key, current[0])
	if config.save(settings_path) != OK:
		show_note(I18n.KEY.tr("Settings could not be saved."))
		return false
	return true


func _family_bindings(events: Array[InputEvent], kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event: InputEvent in events:
		if _event_kind(event) == kind:
			result.append(_encode_binding(event))
	return result
