class_name DebugTools
extends Node
## Debug tools and cheat codes, so a tester or a capture driver can see what the game is doing: the
## F3 overlay (performance, then state, then state with the world's zones, hitboxes and render boxes
## drawn over the game: DebugZones), F12 bug captures (a screenshot and a JSON state dump with all of
## that geometry as numbers), the debug menu (DebugMenu over DebugActions: jumps, choices, cheats,
## forced knockdowns, saves and effect switches) and a small DEBUG button for touch. Main builds one
## in _ready (_setup_debug_tools) and gives it its debug_snapshot().
##
## Gating: always available in a debug build. In any other build the tools stay hidden until a cheat
## code on the title screen unlocks them (WOLFDEN typed on a keyboard; Up Up Down Down Left Right Left
## Right B A on a controller's D-pad and face buttons; seven quick taps on the logo mark), and the
## unlock is stored with the settings. lock() hides them again and forgets the unlock, for the rest of
## the session even in a debug build.
##
## Cost: while the tools are unavailable, or available with the overlay off, the menu closed and no
## per-frame cheat on (instant crank, slow motion), this node, its zone drawing and its actions neither
## process nor draw; it only looks at input events as they arrive. The overlay
## refreshes its text REFRESH_SECONDS apart while it is shown, never every frame, and reads the save
## on disk at most SAVE_INFO_SECONDS apart; the zones page redraws every frame while it is up.
##
## The game's own cards come first: while Pause, Settings, the END OF SLICE card or the title's
## Credits or Changelog is up, the overlay and the DEBUG button step aside (and stop refreshing), and
## the overlay steps aside for an answer button that would sit under it (the touch layout's choice
## row). A pause without a card, such as the debug menu's, keeps the overlay up and refreshing.

## The tools became available or were hidden (unlock, lock, or a debug_build change).
signal availability_changed(available: bool)
## Backquote, both sticks pressed (L3 + R3) or the DEBUG button asked for the debug menu (it opens,
## or closes when open).
signal menu_requested
signal overlay_mode_changed(mode: int)
## A bug capture was written; [param paths] holds "json" and "png" (empty when no screenshot exists)
## and "with_boxes" (whether every zone, hitbox and render box was drawn into the screenshot).
signal captured(paths: Dictionary)

## On the zones page the categories also toggle on a controller: LB zones, RB hitboxes, View (Select)
## render boxes (DebugZones.CATEGORY_PAD_BUTTONS), unless the player bound that button to a game action.
##
## The overlay pages F3 cycles through, in order.
enum Overlay { OFF, PERFORMANCE, STATE, ZONES }
const OVERLAY_NAMES: Array[String] = ["off", "performance", "state", "state and zones"]
## Where the unlock is stored in the settings file (GameSettings keeps other sections as they are).
const SETTINGS_SECTION: String = "debug"
const SETTINGS_KEY: String = "unlocked"
## The unlock codes.
const KEY_CODE: String = "WOLFDEN"
const PAD_CODE: Array[JoyButton] = [
	JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_DOWN,
	JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT,
	JOY_BUTTON_B, JOY_BUTTON_A,
]
const LOGO_TAPS: int = 7
## Logo taps further apart than this start the count again.
const LOGO_TAP_GAP_MSEC: int = 1000
const UNLOCKED_NOTE: String = "Debug tools unlocked"
const LOCKED_NOTE: String = "Debug tools locked"
const CAPTURE_FAILED_NOTE: String = "Bug capture could not be saved."
const NOTE_SECONDS: float = 3.0
const CAPTURE_DIR: String = "user://debug-captures"
const REFRESH_SECONDS: float = 0.25
## The overlay's view of the save on disk is read again after this long, or when the file's
## existence or modified time changes; captures and dump() always read it fresh.
const SAVE_INFO_SECONDS: float = 1.0
## Main's full-screen cards (by property name) that the overlay and the DEBUG button step aside for.
const CARDS: Array[StringName] = [&"pause_overlay", &"end_card", &"credits_screen", &"changelog_screen"]
## Main's answer buttons (by property name); the overlay hides while one would sit under it.
const CHOICES: Array[StringName] = [&"touch_choice_1", &"touch_choice_2"]
## Above the game's HUD, menus and pause overlay.
const LAYER: int = 100
## capture_with_boxes() waits at most this many frames for the boxes to be drawn: a window that
## presents nothing (hidden, occluded or minimised) never holds a capture driver up.
const FRAME_WAIT_LIMIT: int = 10
## The touch DEBUG button, in the 960x540 canvas: top right, ending BUTTON_GAP left of PAUSE (main.tscn's
## PauseButton spans x 854..942) and above the title's logo mark (from y 48), so it never covers PAUSE,
## USE, the arrows or the actors lower down. Its width is at least the TouchButton theme's minimum,
## which can be wider than asked for, so the button grows to the left, never into the gap.
const BUTTON_RECT: Rect2 = Rect2(760.0, 10.0, 72.0, 34.0)
const PAUSE_LEFT: float = 854.0
const BUTTON_GAP: float = 14.0
## The short note ("Debug tools unlocked", a capture's path): near the top in play, below the top
## card; on the title over the key art's floor, above CHANGELOG, clear of the title text and menu.
const NOTE_RECT: Rect2 = Rect2(200.0, 92.0, 560.0, 32.0)
const TITLE_NOTE_RECT: Rect2 = Rect2(48.0, 412.0, 408.0, 32.0)

## Debug builds always have the tools; tests set this false to check a release build's gating.
var debug_build: bool = OS.is_debug_build():
	set(value):
		debug_build = value
		if game != null:
			_apply()
## The stored unlock from a cheat code.
var unlocked: bool = false
## lock() was used this session: hidden even in a debug build until a code unlocks them again.
var session_locked: bool = false
var available: bool = false
var overlay_mode: int = Overlay.OFF
## Set by cheats (invincibility, jumps and the like); shown on the state page and in every dump.
var cheats_used: bool = false
## The debug menu sets this while it is open, so the DEBUG button hides.
var menu_open: bool = false:
	set(value):
		menu_open = value
		if game != null:
			_refresh_view()
var capture_dir: String = CAPTURE_DIR
## The last bug capture's paths ("json", "png"), or empty.
var last_capture: Dictionary = {}
var game: Node2D
var settings_path: String = ""
var layer: CanvasLayer
var overlay: DebugOverlay
## The zones page's drawing and its legend (F5 zones, F6 hitboxes, F7 render boxes).
var zones: DebugZones
## What the debug menu does to the game, and the menu itself (with the frame-step bar).
var actions: DebugActions
var menu: DebugMenu
var debug_button: Button
var note: Panel
var note_label: Label

var _typed: String = ""
var _pad: Array[int] = []
var _logo_taps: int = 0
var _last_logo_tap_msec: int = -LOGO_TAP_GAP_MSEC * 10
## Stick buttons held per device, for L3 + R3.
var _sticks: Dictionary = {}
## The pad code's last button, whose release must not reach a focused button either, or -1.
var _swallow_release: int = -1
var _refresh_left: float = 0.0
var _note_tween: Tween
var _view_queued: bool = false
## The overlay's cached view of the save on disk, and the file's existence and modified time it was
## read at.
var _save_info: Dictionary = {}
var _save_info_stamp: String = ""
var _save_info_msec: int = 0
## How many times the save file was opened and parsed (tests check the overlay's refresh caches it).
var save_reads: int = 0
## True while capture_with_boxes() has every box drawn for its screenshot.
var _capturing_boxes: bool = false
## The signal capture_with_boxes() waits on for a drawn frame; unset, the renderer's frame_post_draw
## (none in a headless run). Tests set one that never fires to check the bounded wait.
var frame_drawn_signal: Signal = Signal()


## Hooks the tools onto Main: reads the stored unlock from Main's settings file, builds the hidden
## overlay, note and DEBUG button, and listens for the logo taps.
func setup(main: Node2D) -> void:
	game = main
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	set_physics_process(false)
	settings_path = str(main.get(&"settings_path"))
	unlocked = GameSettings.boolean(GameSettings.load_config(settings_path), SETTINGS_SECTION, SETTINGS_KEY, false)
	_build()
	var logo: Control = main.get(&"title_mark") as Control
	if logo != null:
		# The mark is otherwise decoration; it takes taps (and clicks) for the touch code.
		logo.mouse_filter = Control.MOUSE_FILTER_STOP
		logo.gui_input.connect(_on_logo_input)
	for property: StringName in CARDS + CHOICES:
		var item: CanvasItem = main.get(property) as CanvasItem
		if item != null:
			item.visibility_changed.connect(_queue_view)
	_apply()


func _build() -> void:
	layer = CanvasLayer.new()
	layer.name = "DebugLayer"
	layer.layer = LAYER
	layer.visible = false
	add_child(layer)
	# Under the overlay card and the note, over the game and its HUD.
	zones = DebugZones.new()
	layer.add_child(zones)
	zones.setup(game, self)
	actions = DebugActions.new()
	add_child(actions)
	actions.setup(game, self)
	# The menu sits beside the overlay's column; the overlay and the note draw over its backdrop.
	menu = DebugMenu.new()
	layer.add_child(menu)
	menu.setup(game, self, actions)
	menu_requested.connect(menu.toggle)
	overlay = DebugOverlay.new()
	overlay.hide()
	layer.add_child(overlay)
	note = Panel.new()
	note.name = "DebugNote"
	note.theme_type_variation = &"HudCard"
	note.position = NOTE_RECT.position
	note.size = NOTE_RECT.size
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.hide()
	layer.add_child(note)
	note_label = Label.new()
	note_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	note_label.add_theme_font_size_override("font_size", 14)
	note_label.add_theme_color_override("font_color", Color("#73DDF5"))
	note_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_child(note_label)
	debug_button = Button.new()
	debug_button.name = "DebugButton"
	debug_button.text = "DEBUG"
	debug_button.theme_type_variation = &"TouchButton"
	debug_button.add_theme_font_size_override("font_size", 13)
	# A touch control: keyboard and controller focus never lands on it.
	debug_button.focus_mode = Control.FOCUS_NONE
	debug_button.hide()
	debug_button.pressed.connect(open_menu)
	layer.add_child(debug_button)
	# In the tree the theme's minimum size is known; the button keeps its right edge clear of PAUSE.
	var button_size: Vector2 = BUTTON_RECT.size.max(debug_button.get_combined_minimum_size())
	debug_button.size = button_size
	debug_button.position = Vector2(PAUSE_LEFT - BUTTON_GAP - button_size.x, BUTTON_RECT.position.y)
	# If the theme's minimum grows later (a font or theme change), the button grows to the left.
	debug_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	UIMotion.attach(debug_button)
	# The zone drawing keeps its names off the tools' own cards.
	zones.own_controls = [overlay, debug_button, note, menu.panel, menu.step_bar]


## Recomputes availability from the build, the stored unlock and a session lock.
func _apply() -> void:
	var was: bool = available
	available = unlocked or (debug_build and not session_locked)
	if not available:
		overlay_mode = Overlay.OFF
		menu.close()
		menu_open = false
		actions.reset_all()
	_sync()
	if was != available:
		availability_changed.emit(available)


## The overlay page or availability changed: shows the new page at once.
func _sync() -> void:
	_refresh_view(true)


## Shows what is on, and processes only while the overlay is up: the overlay while it has a page and
## no card or answer button needs its space, the DEBUG button for touch play while no menu or card is
## up. [param redraw] refreshes the overlay's text now even if it was already showing.
func _refresh_view(redraw: bool = false) -> void:
	_view_queued = false
	if game == null:
		return
	var card_up: bool = _card_up()
	var showing: bool = available and overlay_mode != Overlay.OFF and not card_up and not _choice_under_overlay()
	var was: bool = overlay.visible
	overlay.visible = showing
	set_process(showing)
	if showing and (redraw or not was):
		_refresh_left = REFRESH_SECONDS
		_refresh_overlay()
	# The zones page draws over the whole view, so it steps aside for the game's cards (not for the
	# answers: its legend is clear of them); a capture with boxes draws it whatever is up.
	zones.set_shown(available and (_capturing_boxes or (overlay_mode == Overlay.ZONES and not card_up)))
	var controller: bool = bool(game.get(&"controller_active"))
	var touch_layout: bool = bool(game.get(&"touch_enabled")) and not controller
	zones.set_device("controller" if controller else ("touch" if touch_layout else "keyboard"))
	debug_button.visible = available and touch_layout and not menu_open and not card_up
	# The game's own Pause opened over frame stepping (its pause wins): stepping ends, Pause stays.
	if actions.frame_step and (game.get(&"pause_overlay") as CanvasItem).visible:
		actions.set_frame_step(false)
	menu.refresh_step_bar()
	sync_layer()


## Once per frame at most, after Main has laid out whatever just changed.
func _queue_view() -> void:
	if _view_queued:
		return
	_view_queued = true
	_refresh_view.call_deferred()


## Shows the tools' canvas layer only while something on it is shown.
func sync_layer() -> void:
	if layer != null:
		layer.visible = overlay.visible or debug_button.visible or note.visible or zones.visible or menu.visible


## True while one of Main's full-screen cards is up.
func _card_up() -> bool:
	for property: StringName in CARDS:
		var card: CanvasItem = game.get(property) as CanvasItem
		if card != null and card.is_visible_in_tree():
			return true
	return false


## True while an answer button is shown where the current page would be drawn.
func _choice_under_overlay() -> bool:
	var area: Rect2 = DebugOverlay.footprint(overlay_mode == Overlay.PERFORMANCE)
	for property: StringName in CHOICES:
		var choice: Control = game.get(property) as Control
		if choice != null and choice.is_visible_in_tree() and area.intersects(choice.get_global_rect()):
			return true
	return false


func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_refresh_left = REFRESH_SECONDS
		_refresh_overlay()


func _refresh_overlay() -> void:
	if overlay_mode == Overlay.PERFORMANCE:
		overlay.show_performance(performance())
	elif overlay_mode != Overlay.OFF:
		overlay.show_state(dump(false), overlay_mode == Overlay.ZONES)


func _input(event: InputEvent) -> void:
	if game == null:
		return
	if event is InputEventJoypadButton and not event.pressed and (event as InputEventJoypadButton).button_index == _swallow_release:
		_swallow_release = -1
		get_viewport().set_input_as_handled()
		return
	if _title_listening():
		_watch_codes(event)
	if not available:
		return
	# The touch layout follows the last device Main saw; Main notes it after this node has the event.
	if event is InputEventJoypadButton or event is InputEventScreenTouch or event is InputEventKey:
		_queue_view()
	if _rebinding():
		return
	if actions.frame_step and not menu_open and _frame_step_input(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		var key: Key = (event as InputEventKey).physical_keycode
		if key == KEY_NONE:
			key = (event as InputEventKey).keycode
		match key:
			KEY_F3:
				cycle_overlay()
			KEY_F12:
				capture()
			KEY_QUOTELEFT:
				open_menu()
			KEY_F5, KEY_F6, KEY_F7:
				# On the zones page: zones, hitboxes, render boxes on or off.
				if overlay_mode != Overlay.ZONES:
					return
				for category: StringName in DebugZones.CATEGORIES:
					if DebugZones.CATEGORY_KEYS[category] == key:
						zones.toggle_layer(category)
			_:
				return
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton:
		var button: InputEventJoypadButton = event as InputEventJoypadButton
		# Unbound buttons: left unhandled, so Main still notes the controller is in use. The menu uses LB
		# and RB for its pages while it is open.
		if button.pressed and not menu_open and overlay_mode == Overlay.ZONES and zones.visible and _pad_toggle(button):
			return
		if button.button_index != JOY_BUTTON_LEFT_STICK and button.button_index != JOY_BUTTON_RIGHT_STICK:
			return
		var held: int = int(_sticks.get(button.device, 0))
		var bit: int = 1 if button.button_index == JOY_BUTTON_LEFT_STICK else 2
		held = held | bit if button.pressed else held & ~bit
		_sticks[button.device] = held
		if button.pressed and held == 3:
			open_menu()
			get_viewport().set_input_as_handled()


## While frame stepping (menu closed): period or RB lets one frame through; Esc, B or Pause plays on.
## True when [param event] was one of those.
func _frame_step_input(event: InputEvent) -> bool:
	if event.is_echo() or not event.is_pressed():
		return false
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause_game"):
		actions.set_frame_step(false)
		return true
	var key: InputEventKey = event as InputEventKey
	if key != null and (key.physical_keycode == KEY_PERIOD or key.keycode == KEY_PERIOD):
		actions.step_frame()
		return true
	var pad: InputEventJoypadButton = event as InputEventJoypadButton
	if pad != null and pad.button_index == JOY_BUTTON_RIGHT_SHOULDER:
		actions.step_frame()
		return true
	return false


## Android Back: closes the debug menu, or ends frame stepping; false when neither is up.
func handle_back() -> bool:
	if menu != null and menu.is_open:
		menu.close()
		return true
	if actions != null and actions.frame_step:
		actions.set_frame_step(false)
		return true
	return false


## On the zones page, LB, RB or View turns a category on or off; false (and nothing changes) for any
## other button, or one the player bound to a game action.
func _pad_toggle(button: InputEventJoypadButton) -> bool:
	for category: StringName in DebugZones.CATEGORIES:
		if DebugZones.CATEGORY_PAD_BUTTONS[category] != button.button_index:
			continue
		for action: StringName in InputMap.get_actions():
			if not String(action).begins_with("ui_") and InputMap.event_is_action(button, action, true):
				return false
		zones.toggle_layer(category)
		return true
	return false


## Codes are entered on the title screen, with no menu over it.
func _title_listening() -> bool:
	return bool(game.get(&"title_open")) and not get_tree().paused


## True while Settings waits for a new binding, so F3 or F12 can be bound without side effects.
func _rebinding() -> bool:
	var settings: GameSettings = game.get(&"settings_menu") as GameSettings
	return settings != null and not settings.capture_action.is_empty()


func _watch_codes(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		var letter: String = _letter(event as InputEventKey)
		if letter.is_empty():
			_typed = ""
			return
		_typed = (_typed + letter).right(KEY_CODE.length())
		if _typed == KEY_CODE:
			_typed = ""
			unlock()
	elif event is InputEventJoypadButton and event.pressed:
		_pad.append((event as InputEventJoypadButton).button_index)
		if _pad.size() > PAD_CODE.size():
			_pad.remove_at(0)
		if _pad_code_entered():
			_pad.clear()
			unlock()
			# The code's last button is A: neither its press nor its release may press the focused title
			# button.
			_swallow_release = PAD_CODE[-1]
			get_viewport().set_input_as_handled()


func _pad_code_entered() -> bool:
	if _pad.size() != PAD_CODE.size():
		return false
	for index: int in PAD_CODE.size():
		if _pad[index] != PAD_CODE[index]:
			return false
	return true


## The letter a key typed, from its text or (for synthetic events) its key code, or empty.
static func _letter(event: InputEventKey) -> String:
	if event.unicode != 0:
		var typed: String = String.chr(event.unicode).to_upper()
		return typed if typed >= "A" and typed <= "Z" else ""
	var key: Key = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
	if key >= KEY_A and key <= KEY_Z:
		return String.chr(key)
	return ""


func _on_logo_input(event: InputEvent) -> void:
	# A tap on a phone arrives here as the mouse click Godot emulates from the touch.
	if not (event is InputEventMouseButton and event.pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT):
		return
	if not _title_listening():
		return
	var now: int = Time.get_ticks_msec()
	_logo_taps = _logo_taps + 1 if now - _last_logo_tap_msec <= LOGO_TAP_GAP_MSEC else 1
	_last_logo_tap_msec = now
	if _logo_taps >= LOGO_TAPS:
		_logo_taps = 0
		unlock()


## A cheat code was entered: the tools show from now on and the unlock is stored with the settings.
func unlock() -> void:
	unlocked = true
	session_locked = false
	_store_unlock()
	_apply()
	show_note(UNLOCKED_NOTE)


## The menu's 'Lock debug tools': hides the tools, forgets the stored unlock and keeps them hidden
## for the rest of this session (a debug build has them again on its next launch).
func lock() -> void:
	unlocked = false
	session_locked = true
	_store_unlock()
	_apply()
	show_note(LOCKED_NOTE)


func _store_unlock() -> void:
	if settings_path.is_empty():
		return
	var config: ConfigFile = GameSettings.load_config(settings_path)
	if unlocked:
		config.set_value(SETTINGS_SECTION, SETTINGS_KEY, true)
	elif config.has_section_key(SETTINGS_SECTION, SETTINGS_KEY):
		config.erase_section_key(SETTINGS_SECTION, SETTINGS_KEY)
	if config.save(settings_path) != OK:
		push_warning("The debug unlock could not be saved with the settings.")


## F3: off, performance, state, state and zones, then off again.
func cycle_overlay() -> void:
	set_overlay_mode((overlay_mode + 1) % OVERLAY_NAMES.size())


func set_overlay_mode(mode: int) -> void:
	if not available:
		return
	overlay_mode = clampi(mode, Overlay.OFF, Overlay.ZONES)
	_sync()
	overlay_mode_changed.emit(overlay_mode)


## Backquote, L3 + R3 or the DEBUG button: opens the debug menu, or closes it when open.
func open_menu() -> void:
	if not available:
		return
	menu_requested.emit()


## F12: writes a screenshot and a JSON state dump to capture_dir/<timestamp>.png and .json, shows
## the path, and returns the paths ("json", and "png" or empty when there is no rendered frame, as
## in a headless run). The dump holds every zone, hitbox and render box as numbers; the screenshot
## shows what was on screen (the boxes only if the zones page was up). Empty when the tools are
## hidden or the dump could not be written.
func capture() -> Dictionary:
	return _write_capture(false)


## For capture drivers: draws every zone, hitbox and render box (whatever page or card is up), waits
## for that frame to render (at most FRAME_WAIT_LIMIT frames), writes the capture with them in the
## screenshot, then puts the view back. If no frame was drawn in time (a window that presents
## nothing) it still writes the dump, with no screenshot and "with_boxes" false.
## Await it: `var paths: Dictionary = await debug_tools.capture_with_boxes()`.
func capture_with_boxes() -> Dictionary:
	if not available:
		return {}
	var drawn: Dictionary = zones.layers.duplicate()
	_capturing_boxes = true
	for category: StringName in DebugZones.CATEGORIES:
		zones.set_layer(true, category)
	_refresh_view()
	zones.refresh_now()
	var frame_signal: Signal = frame_drawn_signal
	if frame_signal.is_null() and DisplayServer.get_name() != "headless":
		frame_signal = RenderingServer.frame_post_draw
	var rendered: bool = await await_drawn_frame(frame_signal, FRAME_WAIT_LIMIT)
	var paths: Dictionary = _write_capture(rendered, rendered)
	_capturing_boxes = false
	for category: StringName in DebugZones.CATEGORIES:
		zones.set_layer(bool(drawn[category]), category)
	_refresh_view()
	return paths


## Waits for [param drawn] (a frame was rendered), but at most [param frames] process frames; with
## no signal (a headless run, nothing to wait for) one frame. True unless the wait ran out.
func await_drawn_frame(drawn: Signal, frames: int) -> bool:
	if drawn.is_null():
		await get_tree().process_frame
		return true
	var came: Array[bool] = [false]
	var mark: Callable = func() -> void: came[0] = true
	drawn.connect(mark, CONNECT_ONE_SHOT)
	for _frame: int in frames:
		await get_tree().process_frame
		if came[0]:
			break
	if drawn.is_connected(mark):
		drawn.disconnect(mark)
	return came[0]


func _write_capture(with_boxes: bool, screenshot: bool = true) -> Dictionary:
	if not available:
		return {}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var base: String = "%s/%s" % [capture_dir, _timestamp()]
	var suffix: int = 1
	while FileAccess.file_exists(base + ".json"):
		suffix += 1
		base = "%s/%s-%d" % [capture_dir, _timestamp(), suffix]
	var png: String = ""
	var image: Image = _screenshot() if screenshot else null
	if image != null and image.save_png(base + ".png") == OK:
		png = base + ".png"
	var paths: Dictionary = {"json": base + ".json", "png": png, "with_boxes": with_boxes}
	var data: Dictionary = dump()
	data["capture"] = paths
	var file: FileAccess = FileAccess.open(base + ".json", FileAccess.WRITE)
	if file == null:
		show_note(CAPTURE_FAILED_NOTE)
		return {}
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	last_capture = paths
	show_note("Saved %s" % (png if not png.is_empty() else paths["json"]))
	captured.emit(paths)
	return paths


## The frame on screen, or null with no rendered frame (a headless run).
func _screenshot() -> Image:
	if DisplayServer.get_name() == "headless":
		return null
	var image: Image = get_viewport().get_texture().get_image()
	return image if image != null and not image.is_empty() else null


static func _timestamp() -> String:
	return "%s-%03d" % [Time.get_datetime_string_from_system(false, false).replace(":", "-"), Time.get_ticks_msec() % 1000]


## Everything the overlay shows and a bug capture saves, in one dictionary of plain values: Main's
## debug_snapshot() (room, beat, actors, machines, hazards, memory and choices, flags and the full
## save state) plus performance, the save on disk, the build, the tools' own flags and "geometry"
## (DebugZones.geometry: the camera and every zone, hitbox and render box with its node path, world
## and screen rects, z-index, canvas layer and visibility). Capture drivers call this to log state
## beside each screenshot. The overlay's refresh passes [param full] false: no full save state and no
## geometry, and the save on disk as last read (see SAVE_INFO_SECONDS).
func dump(full: bool = true) -> Dictionary:
	var data: Dictionary = {}
	if game != null and game.has_method(&"debug_snapshot"):
		data = game.call(&"debug_snapshot", full)
	data["time"] = Time.get_datetime_string_from_system(false, true)
	var window: Vector2i = get_window().size
	data["build"] = {
		"debug_build": OS.is_debug_build(),
		"godot": str(Engine.get_version_info().get("string", "")),
		"os": OS.get_name(),
		"display": DisplayServer.get_name(),
		"window": [window.x, window.y],
	}
	data["performance"] = performance()
	data["save"] = save_info(full)
	data["debug"] = {
		"available": available,
		"unlocked": unlocked,
		"debug_build": debug_build,
		"overlay": OVERLAY_NAMES[overlay_mode],
		"cheats_used": cheats_used,
		"cheats": actions.info(),
		"menu_open": menu_open,
		"drawn": {"shown": zones.visible, "zones": zones.layers[DebugZones.ZONES], "hitboxes": zones.layers[DebugZones.HITBOXES], "render": zones.layers[DebugZones.RENDER]},
	}
	if full:
		data["geometry"] = zones.geometry()
	return data


## Frame rate and times, memory and counts. Godot reports static memory only in debug builds
## (Performance.MEMORY_STATIC), so elsewhere, as in an unlocked release build, memory_mb is null
## ("n/a"), never 0; video memory is reported in every build.
static func performance(static_memory: bool = OS.is_debug_build()) -> Dictionary:
	var fps: float = Engine.get_frames_per_second()
	return {
		"fps": fps,
		"frame_ms": 1000.0 / fps if fps > 0.0 else 0.0,
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0 if static_memory else null,
		"video_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
	}


## The save on disk, read without side effects (M0State.load_from_disk can promote a leftover
## .tmp file; this never writes): the format version, whether a file exists and the checkpoint it holds.
## With [param fresh] false (the overlay's refresh) the last reading is reused for SAVE_INFO_SECONDS
## unless the file appeared, went or was modified since.
func save_info(fresh: bool = true) -> Dictionary:
	var path: String = str(game.get(&"save_path")) if game != null else M0State.SAVE_PATH
	var exists: bool = FileAccess.file_exists(path)
	var stamp: String = "%s:%d" % [path, FileAccess.get_modified_time(path)] if exists else path
	var now: int = Time.get_ticks_msec()
	if not fresh and not _save_info.is_empty() and stamp == _save_info_stamp and now - _save_info_msec < int(SAVE_INFO_SECONDS * 1000.0):
		return _save_info.duplicate()
	var info: Dictionary = _read_save_info(path, exists)
	_save_info = info
	_save_info_stamp = stamp
	_save_info_msec = now
	return info.duplicate()


func _read_save_info(path: String, exists: bool) -> Dictionary:
	var info: Dictionary = {"version": M0State.SAVE_VERSION, "path": path, "exists": exists, "checkpoint": "none"}
	if not exists:
		return info
	save_reads += 1
	var json: JSON = JSON.new()
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or json.parse(file.get_as_text()) != OK:
		info["checkpoint"] = "unreadable"
		return info
	var saved: M0State = M0State.from_dict(json.data)
	if saved == null or not saved.checkpoint_reached:
		info["checkpoint"] = "unreadable"
		return info
	if json.data is Dictionary:
		info["file_version"] = int((json.data as Dictionary).get("version", 0))
	info["checkpoint"] = checkpoint_label(saved)
	return info


## Where a saved state stands, in a few words.
static func checkpoint_label(saved: M0State) -> String:
	match saved.chapter_id:
		"records":
			if saved.chapter_complete:
				return "Records, first copy secured"
			if saved.mirror_trace_preserved:
				return "Records, both traces copied"
			if saved.purge_trace_preserved:
				return "Records, purge order copied"
			return "Records entry"
		"junction":
			if saved.junction_cleared:
				return "junction cleared"
			if saved.sentry_down:
				return "junction, tank down"
			if saved.door_blown:
				return "junction, door blown"
			return "junction entry"
	return "corridor safe point"


## A short note near the top of the screen for NOTE_SECONDS.
func show_note(text: String) -> void:
	var rect: Rect2 = TITLE_NOTE_RECT if game != null and bool(game.get(&"title_open")) else NOTE_RECT
	note.position = rect.position
	note.size = rect.size
	note_label.text = text
	note.show()
	sync_layer()
	if _note_tween != null and _note_tween.is_valid():
		_note_tween.kill()
	# Notes come up over Pause and the debug menu too, so the timer runs while the tree is paused.
	_note_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_note_tween.tween_interval(NOTE_SECONDS)
	_note_tween.tween_callback(_note_done)


func hide_note() -> void:
	if _note_tween != null and _note_tween.is_valid():
		_note_tween.kill()
	_note_done()


func _note_done() -> void:
	_note_tween = null
	note.hide()
	sync_layer()
