class_name DebugMenu
extends Control
## The debug menu: six pages of buttons over DebugActions (JUMP, CHOICES, CHEATS, FORCE, SAVE and
## VIEW), plus the small frame-step bar. Backquote, both sticks (L3 + R3) or the DEBUG button open
## and close it (DebugTools.menu_requested); Esc, B, Android Back, CLOSE or a tap outside the card
## close it. It holds the game still like Pause does while it is open, and works with keyboard and
## controller focus (LB and RB change page) and with touch.
##
## The card sits right of the F3 overlay's column (DebugOverlay.footprint) and under the top card, so
## the overlay stays readable beside it. It uses the game's menu card, buttons and fonts; the
## terminal look stays in Settings. Closed, it has no process and draws nothing.

signal opened
signal closed

## In the 960x540 canvas: right of the overlay's column (which ends at x 396), below the top card and
## PAUSE (y 78), above the bottom edge.
const MENU_RECT: Rect2 = Rect2(404.0, 84.0, 544.0, 446.0)
## The frame-step bar: right of the corridor's tutorial card (ends x 638), under PAUSE, in the ceiling
## band where nobody stands; below the answer row while a question is up.
const STEP_BAR_RECT: Rect2 = Rect2(650.0, 84.0, 296.0, 40.0)
const STEP_BAR_BELOW_CHOICES_Y: float = 182.0
const PAGES: Array[StringName] = [&"jump", &"choices", &"cheats", &"force", &"save", &"view"]
const PAGE_NAMES: Dictionary = {&"jump": "JUMP", &"choices": "CHOICES", &"cheats": "CHEATS", &"force": "FORCE", &"save": "SAVE", &"view": "VIEW"}
## Tall enough to tap on a phone once the 960x540 canvas is scaled down.
const BUTTON_HEIGHT: float = 40.0
const FONT_SIZE: int = 14
const SMALL_FONT_SIZE: int = 12
const CAPTION_FONT_SIZE: int = 11
const ACCENT: Color = Color("#73DDF5")
const MUTED: Color = Color("#9fc3d2")
const WARN: Color = Color("#ff9a9f")
const BACKDROP: Color = Color(0.008, 0.018, 0.035, 0.55)
const DISPLAY_FONT: FontVariation = preload("res://assets/fonts/Montserrat-Bold.tres")
const CLEAR_CONFIRM_TEXT: String = "PRESS AGAIN TO DELETE"

var tools: DebugTools
var actions: DebugActions
var game: Node2D
var is_open: bool = false
var page: StringName = &"jump"
var backdrop: ColorRect
var panel: Panel
var status_label: Label
var note_label: Label
var hint_label: Label
var close_button: Button
var scroll: ScrollContainer
var tab_buttons: Dictionary = {}
var pages: Dictionary = {}
## Every action button by id ("jump:opening", "relay:press", "cheat:invincible", "speed:0.5",
## "force:vent", "trigger:blast", "save:now", "view:overlay", ...), for refreshing and for tests.
var buttons: Dictionary = {}
var force_reason: Label
var save_caption: Label
var step_bar: PanelContainer
var step_label: Label
var step_button: Button
var run_button: Button
var _clear_armed: bool = false


func _init() -> void:
	name = "DebugMenu"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func setup(main: Node2D, owner_tools: DebugTools, owner_actions: DebugActions) -> void:
	game = main
	tools = owner_tools
	actions = owner_actions
	_build()
	actions.changed.connect(_on_actions_changed)
	actions.frame_stepped.connect(func(_frames: int) -> void: refresh_step_bar())


# --- Building -----------------------------------------------------------------------------------

func _build() -> void:
	backdrop = ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = BACKDROP
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.gui_input.connect(_on_backdrop_input)
	backdrop.hide()
	add_child(backdrop)
	panel = Panel.new()
	panel.name = "MenuCard"
	panel.theme_type_variation = &"MenuPanel"
	panel.position = MENU_RECT.position
	panel.size = MENU_RECT.size
	panel.hide()
	add_child(panel)
	var sheen: Panel = Panel.new()
	sheen.theme_type_variation = &"CardSheen"
	sheen.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sheen)
	var title: Label = _label("DEBUG MENU", Rect2(20.0, 10.0, 200.0, 32.0), 22, Color.WHITE)
	title.add_theme_font_override("font", DISPLAY_FONT)
	status_label = _label("", Rect2(190.0, 16.0, 334.0, 22.0), SMALL_FONT_SIZE, MUTED)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var accent: ColorRect = ColorRect.new()
	accent.color = Color(0.22, 0.78, 0.92, 1)
	accent.position = Vector2(20.0, 46.0)
	accent.size = Vector2(504.0, 3.0)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(accent)
	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.position = Vector2(20.0, 56.0)
	tabs.size = Vector2(504.0, 34.0)
	tabs.add_theme_constant_override("separation", 4)
	panel.add_child(tabs)
	var group: ButtonGroup = ButtonGroup.new()
	for id: StringName in PAGES:
		var tab: Button = Button.new()
		tab.name = "%sTab" % String(id).capitalize()
		tab.text = PAGE_NAMES[id]
		tab.toggle_mode = true
		tab.button_group = group
		tab.custom_minimum_size = Vector2(0.0, 34.0)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", SMALL_FONT_SIZE)
		_mark_chosen(tab)
		tab.pressed.connect(show_page.bind(id))
		# Moving focus along the row turns the page, so a controller never has to press a tab.
		tab.focus_entered.connect(show_page.bind(id))
		tabs.add_child(tab)
		UIMotion.attach(tab)
		tab_buttons[id] = tab
	scroll = ScrollContainer.new()
	scroll.name = "Pages"
	scroll.position = Vector2(20.0, 98.0)
	scroll.size = Vector2(504.0, 272.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.add_child(scroll)
	var holder: VBoxContainer = VBoxContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(holder)
	for id: StringName in PAGES:
		var box: VBoxContainer = VBoxContainer.new()
		box.name = "%sPage" % String(id).capitalize()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override("separation", 5)
		box.hide()
		holder.add_child(box)
		pages[id] = box
	_build_jump_page(pages[&"jump"])
	_build_choices_page(pages[&"choices"])
	_build_cheats_page(pages[&"cheats"])
	_build_force_page(pages[&"force"])
	_build_save_page(pages[&"save"])
	_build_view_page(pages[&"view"])
	note_label = _label("", Rect2(20.0, 374.0, 504.0, 30.0), CAPTION_FONT_SIZE, ACCENT)
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	note_label.max_lines_visible = 2
	hint_label = _label("", Rect2(20.0, 412.0, 344.0, 22.0), CAPTION_FONT_SIZE, MUTED)
	hint_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "CLOSE"
	close_button.position = Vector2(374.0, 406.0)
	close_button.size = Vector2(150.0, 34.0)
	close_button.add_theme_font_size_override("font_size", FONT_SIZE)
	close_button.pressed.connect(close)
	panel.add_child(close_button)
	UIMotion.attach(close_button)
	_build_step_bar()
	show_page(page)


func _build_jump_page(box: VBoxContainer) -> void:
	_caption(box, "JUMP TO A BEAT. Built from the CHOICES page; a checkpoint beat writes its save, as play does.")
	var grid: GridContainer = _grid(box, 2)
	for id: StringName in DebugActions.JUMPS:
		_button(grid, "jump:%s" % id, DebugActions.JUMP_NAMES[id], _run_and_close.bind(actions.jump.bind(id)))


func _build_choices_page(box: VBoxContainer) -> void:
	_caption(box, "THE RUN'S EARLIER CHOICES, used by the next jump.")
	_caption(box, "RELAY (what WOLF was told, then who opened the seal)", ACCENT)
	_radio(_grid(box, 3), "relay", DebugActions.RELAY_OPTIONS, actions.set_relay)
	_caption(box, "MIRROR", ACCENT)
	_radio(_grid(box, 3), "mirror", DebugActions.MIRROR_OPTIONS, actions.set_mirror)
	_caption(box, "LANE (WOLF draws the sentry only if he was told the risk at the relay)", ACCENT)
	_radio(_grid(box, 3), "lane", DebugActions.LANE_OPTIONS, actions.set_lane)


func _build_cheats_page(box: VBoxContainer) -> void:
	_caption(box, "CHEATS. Any cheat marks the overlay and every dump CHEATS USED.")
	var grid: GridContainer = _grid(box, 2)
	_toggle(grid, "cheat:invincible", actions.set_invincible)
	_toggle(grid, "cheat:freeze", actions.set_sentry_frozen)
	_toggle(grid, "cheat:crank", actions.set_instant_crank)
	_toggle(grid, "cheat:step", actions.set_frame_step)
	_caption(box, "SPEED", ACCENT)
	var speeds: GridContainer = _grid(box, 3)
	var group: ButtonGroup = ButtonGroup.new()
	for scale: float in DebugActions.SLOW_MOTION:
		var button: Button = _button(speeds, "speed:%s" % DebugActions._speed_text(scale), "%sx" % DebugActions._speed_text(scale), _run.bind(actions.set_slow_motion.bind(scale)))
		button.toggle_mode = true
		button.button_group = group


func _build_force_page(box: VBoxContainer) -> void:
	_caption(box, "FORCE A KNOCKDOWN (lands even while invincible; the beat's checkpoint comes back).")
	var grid: GridContainer = _grid(box, 2)
	for kind: StringName in DebugActions.KNOCKDOWNS:
		_button(grid, "force:%s" % kind, "%s KNOCKDOWN" % String(kind).to_upper(), _run_and_close.bind(actions.force_knockdown.bind(kind)))
	_caption(box, "TRIGGER (through the room's own rules: where everyone stands still decides it)", ACCENT)
	var triggers: GridContainer = _grid(box, 2)
	_button(triggers, "trigger:blast", "LIGHT THE DOOR FUSE", _run_and_close.bind(actions.trigger_blast))
	_button(triggers, "trigger:drop", "DROP THE TANK", _run_and_close.bind(actions.trigger_drop))
	force_reason = _caption(box, "")


func _build_save_page(box: VBoxContainer) -> void:
	save_caption = _caption(box, "")
	var grid: GridContainer = _grid(box, 1)
	_button(grid, "save:now", "SAVE NOW", _run.bind(actions.save_now))
	_button(grid, "save:reload", "RELOAD CHECKPOINT", _run_and_close.bind(actions.reload_checkpoint))
	_button(grid, "save:clear", "CLEAR SAVE", _on_clear_save)


func _build_view_page(box: VBoxContainer) -> void:
	_caption(box, "WHAT YOU SEE. The switches are not cheats and are not saved.")
	var grid: GridContainer = _grid(box, 2)
	_button(grid, "view:overlay", "OVERLAY", _on_cycle_overlay)
	_button(grid, "view:capture", "BUG CAPTURE", _on_capture)
	_toggle(grid, "view:effects", actions.set_effects)
	_toggle(grid, "view:shake", actions.set_shake)
	_toggle(grid, "view:flash", actions.set_flash)
	var lock: Button = _button(grid, "view:lock", "LOCK DEBUG TOOLS", _on_lock)
	lock.add_theme_color_override("font_color", WARN)


func _build_step_bar() -> void:
	step_bar = PanelContainer.new()
	step_bar.name = "FrameStepBar"
	step_bar.theme_type_variation = &"HudCard"
	step_bar.position = STEP_BAR_RECT.position
	step_bar.size = STEP_BAR_RECT.size
	step_bar.hide()
	add_child(step_bar)
	var margin: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 8 if side in ["left", "right"] else 3)
	step_bar.add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	margin.add_child(row)
	step_label = Label.new()
	step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	step_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	step_label.add_theme_font_size_override("font_size", SMALL_FONT_SIZE)
	step_label.add_theme_color_override("font_color", ACCENT)
	row.add_child(step_label)
	step_button = _bar_button(row, "STEP", actions.step_frame)
	run_button = _bar_button(row, "RUN", func() -> void: _run(actions.set_frame_step.bind(false)))


## A touch and mouse control on the step bar; keys (period, Esc) and the controller (RB, B) do the same.
func _bar_button(row: HBoxContainer, text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.name = "%sButton" % text.capitalize()
	button.text = text
	button.theme_type_variation = &"TouchButton"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(66.0, 32.0)
	button.add_theme_font_size_override("font_size", SMALL_FONT_SIZE)
	button.pressed.connect(action)
	row.add_child(button)
	return button


func _label(text: String, rect: Rect2, font_size: int, tint: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	return label


func _caption(box: VBoxContainer, text: String, tint: Color = MUTED) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", CAPTION_FONT_SIZE)
	label.add_theme_color_override("font_color", tint)
	box.add_child(label)
	return label


func _grid(box: VBoxContainer, columns: int) -> GridContainer:
	var grid: GridContainer = GridContainer.new()
	grid.columns = columns
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	return grid


## A button in [param grid], known as [param id]; [param action] runs on press (none for a switch).
func _button(grid: GridContainer, id: String, text: String, action: Callable = Callable()) -> Button:
	var button: Button = Button.new()
	button.name = id.replace(":", "_")
	button.text = text
	button.custom_minimum_size = Vector2(0.0, BUTTON_HEIGHT)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_theme_font_size_override("font_size", FONT_SIZE if grid.columns < 3 else SMALL_FONT_SIZE)
	_mark_chosen(button)
	if action.is_valid():
		button.pressed.connect(action)
	grid.add_child(button)
	UIMotion.attach(button)
	buttons[id] = button
	return button


## A chosen tab, option or switch that is on reads in the accent colour, as well as by its pressed look.
static func _mark_chosen(button: Button) -> void:
	for state: String in ["font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, ACCENT)


## An ON/OFF switch: [param setter] takes the new value and returns the note.
func _toggle(grid: GridContainer, id: String, setter: Callable) -> Button:
	var button: Button = _button(grid, id, "")
	button.toggle_mode = true
	button.toggled.connect(func(on: bool) -> void: _run(setter.bind(on)))
	return button


## One button per option, of which one is chosen; [param setter] takes the option and returns the note.
func _radio(grid: GridContainer, key: String, options: Array[StringName], setter: Callable) -> void:
	var group: ButtonGroup = ButtonGroup.new()
	for option: StringName in options:
		var button: Button = _button(grid, "%s:%s" % [key, option], DebugActions.OPTION_NAMES[option], _run.bind(setter.bind(option)))
		button.toggle_mode = true
		button.button_group = group


# --- Opening and closing --------------------------------------------------------------------------

## Backquote, L3 + R3 or DEBUG: opens the menu, or closes it when open.
func toggle() -> void:
	if is_open:
		close()
	else:
		open()


## Opens over the game and holds it still, unless the game's own Pause or Settings is up (closing
## this menu would otherwise let the game run under them).
func open() -> void:
	if is_open or tools == null or not tools.available:
		return
	if (game.get(&"pause_overlay") as CanvasItem).visible:
		tools.show_note("Close the pause menu first.")
		return
	is_open = true
	tools.menu_open = true
	actions.hold_pause()
	_clear_armed = false
	note_label.text = ""
	refresh()
	backdrop.show()
	panel.show()
	_sync_visible()
	show_page(page)
	_focus_first()
	opened.emit()


## Closes the menu and lets the game run again (unless frame stepping holds it).
func close() -> void:
	if not is_open:
		return
	is_open = false
	backdrop.hide()
	panel.hide()
	tools.menu_open = false
	actions.release_pause()
	_sync_visible()
	refresh_step_bar()
	# Back to the title's own focus there; in play nothing keeps focus.
	var target: Control = game.call(&"_menu_focus_target") as Control
	if target != null and target.is_visible_in_tree():
		game.call(&"_grab_menu_focus", target)
	else:
		get_viewport().gui_release_focus()
	closed.emit()


func _focus_first() -> void:
	if _touch_layout():
		get_viewport().gui_release_focus()
	else:
		(tab_buttons[page] as Button).grab_focus()


func _touch_layout() -> bool:
	return bool(game.get(&"touch_enabled")) and not bool(game.get(&"controller_active"))


func show_page(id: StringName) -> void:
	if not pages.has(id):
		return
	page = id
	# Without signals the button group does not let go of the last tab, so each is set.
	for key: StringName in PAGES:
		(pages[key] as Control).visible = key == id
		(tab_buttons[key] as Button).set_pressed_no_signal(key == id)
	scroll.scroll_vertical = 0
	_clear_armed = false
	_link_focus()
	refresh()


## Up and down between the tab row, the page's first and last rows and CLOSE are set by hand: the
## buttons' hover and focus lift (UIMotion) briefly changes their size, which can otherwise send a
## quick down press sideways along the tabs.
func _link_focus() -> void:
	var grids: Array[GridContainer] = []
	for child: Node in (pages[page] as Control).get_children():
		if child is GridContainer and (child as GridContainer).get_child_count() > 0:
			grids.append(child as GridContainer)
	if grids.is_empty():
		return
	var first: GridContainer = grids[0]
	var last: GridContainer = grids[-1]
	for id: StringName in PAGES:
		var tab: Button = tab_buttons[id] as Button
		tab.focus_neighbor_bottom = tab.get_path_to(first.get_child(0))
		tab.focus_neighbor_top = tab.get_path_to(close_button)
	var tab_here: Button = tab_buttons[page] as Button
	for index: int in mini(first.columns, first.get_child_count()):
		var button: Control = first.get_child(index) as Control
		button.focus_neighbor_top = button.get_path_to(tab_here)
	var last_count: int = last.get_child_count()
	var last_row: int = (last_count - 1) - (last_count - 1) % last.columns
	for index: int in range(last_row, last_count):
		var button: Control = last.get_child(index) as Control
		button.focus_neighbor_bottom = button.get_path_to(close_button)
	close_button.focus_neighbor_top = close_button.get_path_to(last.get_child(last_row))
	close_button.focus_neighbor_bottom = close_button.get_path_to(tab_here)


## The next or previous page (RB and LB while the menu is open), keeping focus on the tab row.
func step_page(by: int) -> void:
	var index: int = (PAGES.find(page) + by + PAGES.size()) % PAGES.size()
	show_page(PAGES[index])
	if not _touch_layout():
		(tab_buttons[page] as Button).grab_focus()


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if not event.is_echo() and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause_game")):
		close()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventJoypadButton and event.pressed:
		var index: int = (event as InputEventJoypadButton).button_index
		if index == JOY_BUTTON_LEFT_SHOULDER or index == JOY_BUTTON_RIGHT_SHOULDER:
			step_page(1 if index == JOY_BUTTON_RIGHT_SHOULDER else -1)
			get_viewport().set_input_as_handled()
			return
	# After touch nothing has focus: the first key or controller press gives it to the page's tab, and
	# does nothing else.
	var navigation: bool = event is InputEventKey and event.pressed or event is InputEventJoypadButton and event.pressed or event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.45
	if navigation and get_viewport().gui_get_focus_owner() == null:
		(tab_buttons[page] as Button).grab_focus()
		for action: StringName in [&"ui_accept", &"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev"]:
			if event.is_action_pressed(action):
				get_viewport().set_input_as_handled()
				return


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		close()
		backdrop.accept_event()


# --- Running actions ----------------------------------------------------------------------------

## Runs [param action] (it returns its note) and shows the note; the menu stays open.
func _run(action: Callable) -> void:
	var note: String = str(action.call())
	if not note.is_empty():
		note_label.text = note
	refresh()


## Runs [param action] and closes the menu so the result plays; its note shows over the game.
func _run_and_close(action: Callable) -> void:
	var note: String = str(action.call())
	close()
	if not note.is_empty():
		tools.show_note(note)


func _on_clear_save() -> void:
	if not _clear_armed:
		_clear_armed = true
		(buttons["save:clear"] as Button).text = CLEAR_CONFIRM_TEXT
		note_label.text = "Deleting the checkpoint cannot be undone."
		return
	_clear_armed = false
	_run(actions.clear_save)


func _on_cycle_overlay() -> void:
	tools.cycle_overlay()
	note_label.text = "Overlay: %s." % DebugTools.OVERLAY_NAMES[tools.overlay_mode]
	refresh()


## Closes the menu, lets one frame draw without it, then saves the capture (as F12 would).
func _on_capture() -> void:
	close()
	await get_tree().process_frame
	await get_tree().process_frame
	tools.capture()


func _on_lock() -> void:
	close()
	tools.lock()


func _on_actions_changed() -> void:
	if is_open:
		refresh()
	refresh_step_bar()


## Brings every button, caption and the status line in line with the game and the cheats.
func refresh() -> void:
	if actions == null:
		return
	var state: M0State = game.get(&"state") as M0State
	var beat: String = str(game.call(&"_debug_beat"))
	status_label.text = "%s · %s%s" % [state.chapter_id, beat, " · CHEATS USED" if tools.cheats_used else ""]
	status_label.add_theme_color_override("font_color", WARN if tools.cheats_used else MUTED)
	for option: StringName in DebugActions.RELAY_OPTIONS:
		_set_pressed("relay:%s" % option, actions.relay == option)
	for option: StringName in DebugActions.MIRROR_OPTIONS:
		_set_pressed("mirror:%s" % option, actions.mirror == option)
	for option: StringName in DebugActions.LANE_OPTIONS:
		_set_pressed("lane:%s" % option, actions.lane == option)
	_switch("cheat:invincible", "INVINCIBLE", actions.invincible)
	_switch("cheat:freeze", "FREEZE SENTRY", actions.sentry_frozen)
	_switch("cheat:crank", "INSTANT CRANK", actions.instant_crank)
	_switch("cheat:step", "FRAME STEP", actions.frame_step)
	for scale: float in DebugActions.SLOW_MOTION:
		_set_pressed("speed:%s" % DebugActions._speed_text(scale), is_equal_approx(actions.slow_motion, scale))
	var knockdown: String = actions.knockdown_blocked()
	for kind: StringName in DebugActions.KNOCKDOWNS:
		(buttons["force:%s" % kind] as Button).disabled = not knockdown.is_empty()
	var blast: String = actions.blast_blocked()
	var drop: String = actions.drop_blocked()
	(buttons["trigger:blast"] as Button).disabled = not blast.is_empty()
	(buttons["trigger:drop"] as Button).disabled = not drop.is_empty()
	var reasons: PackedStringArray = PackedStringArray()
	for pair: Array in [["KNOCKDOWNS", knockdown], ["FUSE", blast], ["TANK", drop]]:
		if not str(pair[1]).is_empty():
			reasons.append("%s: %s" % pair)
	force_reason.text = "\n".join(reasons) if not reasons.is_empty() else "All ready."
	var save: Dictionary = tools.save_info(true)
	save_caption.text = "CHECKPOINT ON DISK: %s (save format v%d). Save now writes this beat through the game's own autosave." % [save.get("checkpoint", "none") if save.get("exists", false) else "none", int(save.get("version", 0))]
	var save_now: String = actions.save_blocked()
	(buttons["save:now"] as Button).disabled = not save_now.is_empty()
	(buttons["save:reload"] as Button).disabled = not actions.has_checkpoint()
	(buttons["save:clear"] as Button).disabled = not save.get("exists", false)
	if not _clear_armed:
		(buttons["save:clear"] as Button).text = "CLEAR SAVE"
	(buttons["view:overlay"] as Button).text = "OVERLAY: %s" % DebugTools.OVERLAY_NAMES[tools.overlay_mode].to_upper()
	_switch("view:effects", "VISUAL EFFECTS", actions.effects_on)
	_switch("view:shake", "CAMERA SHAKE", actions.shake_on)
	_switch("view:flash", "SCREEN FLASH", actions.flash_on)
	var controller: bool = bool(game.get(&"controller_active"))
	hint_label.text = "TAP OUTSIDE TO CLOSE" if _touch_layout() else ("B  CLOSE   LB / RB  PAGE" if controller else "ESC  CLOSE   `  TOGGLE")


func _set_pressed(id: String, on: bool) -> void:
	var button: Button = buttons.get(id) as Button
	if button != null and button.button_pressed != on:
		button.set_pressed_no_signal(on)


func _switch(id: String, caption: String, on: bool) -> void:
	_set_pressed(id, on)
	(buttons[id] as Button).text = "%s  %s" % [caption, "ON" if on else "OFF"]


# --- Frame-step bar -----------------------------------------------------------------------------

## Shown while frame stepping with the menu closed, below the answer row while a question is up.
func refresh_step_bar() -> void:
	if actions == null:
		return
	step_bar.visible = actions.frame_step and not is_open and tools.available
	if step_bar.visible:
		step_label.text = "FRAME STEP  %d" % actions.frames_stepped
		var choice_up: bool = false
		for property: StringName in DebugTools.CHOICES:
			var choice: Control = game.get(property) as Control
			choice_up = choice_up or (choice != null and choice.is_visible_in_tree())
		step_bar.position.y = STEP_BAR_BELOW_CHOICES_Y if choice_up else STEP_BAR_RECT.position.y
	_sync_visible()


func _sync_visible() -> void:
	visible = is_open or step_bar.visible
	if tools != null:
		tools.sync_layer()
