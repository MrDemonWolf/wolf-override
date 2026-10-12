extends SceneTree
## Scratch mock driver for PIN design option A, "the found code" (not part of the repo).
## Revised after the judge's review: renders on main at cfe304f (logic round 3, WOLF waits in the hatch
## doorway once the sentry is down), shows the reader's state on a code-drawn LAMP on the bolt panel
## instead of a world text chip (2026-10-11 LABELS), uses 12 px key gaps on touch, and adds the
## MANUAL RELEASE route's crank and its arc (the same bolt arc as the code route).
##   godot --resolution 1280x720 --path <exported game> --script <this> -- <out dir>
## Renders the real game at two beats (Records Access with the engineer at a mocked ACCESS SCREEN,
## and the Service Junction with the sentry down and the engineer at the exit bolt panel), freezes it,
## then lays a mock keypad card over it built only from the game's own theme, fonts and Controls.
## Every string drawn here is PROPOSED, AWAITING NATHANIAL.

const DISPLAY_FONT: FontVariation = preload("res://assets/fonts/Montserrat-Bold.tres")
const CONTROL_FONT: FontVariation = preload("res://assets/fonts/Montserrat-Semibold.tres")
const AMBER: Color = Color("#f2c46d")
const RED: Color = Color("#ff8a8f")
const GREEN: Color = Color("#a4f0c4")
const ACCENT: Color = Color("#73DDF5")
const MUTED: Color = Color("#9fc3d2")
const CODE: String = "4071"
## Where the reader lamp sits on the bolt panel, from (BOLT_PANEL_X, FLOOR_Y), in world px.
const LAMP_OFFSET: Vector2 = Vector2(0.0, -86.0)

var out_dir: String = ""
var game: Node2D
var tools: DebugTools
var layer: CanvasLayer


## A lamp shape that never relies on colour alone: ring (waiting), cross (denied), padlock (locked),
## tick (granted).
class PinLamp extends Control:
	var kind: StringName = &"idle"
	var tint: Color = Color.WHITE

	func _draw() -> void:
		var c: Vector2 = size * 0.5
		var r: float = minf(size.x, size.y) * 0.5 - 1.0
		draw_circle(c, r, Color(tint, 0.18))
		match kind:
			&"idle":
				draw_arc(c, r - 2.0, 0.0, TAU, 32, tint, 2.0, true)
				draw_circle(c, r * 0.32, tint)
			&"denied":
				draw_arc(c, r - 2.0, 0.0, TAU, 32, tint, 2.0, true)
				var d: float = r * 0.42
				draw_line(c + Vector2(-d, -d), c + Vector2(d, d), tint, 2.6, true)
				draw_line(c + Vector2(-d, d), c + Vector2(d, -d), tint, 2.6, true)
			&"locked":
				draw_rect(Rect2(c.x - r * 0.5, c.y - r * 0.05, r, r * 0.7), tint)
				draw_arc(c + Vector2(0, -r * 0.05), r * 0.34, PI, TAU, 16, tint, 2.4, true)
			&"granted":
				draw_arc(c, r - 2.0, 0.0, TAU, 32, tint, 2.0, true)
				draw_polyline(PackedVector2Array([c + Vector2(-r * 0.42, 0), c + Vector2(-r * 0.1, r * 0.34), c + Vector2(r * 0.46, -r * 0.36)]), tint, 2.8, true)
			&"forced":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r * 0.8), c + Vector2(r * 0.85, r * 0.62), c + Vector2(-r * 0.85, r * 0.62)]), tint)
				draw_line(c + Vector2(0, -r * 0.3), c + Vector2(0, r * 0.2), Color("#06101a"), 2.4, true)
				draw_circle(c + Vector2(0, r * 0.4), 1.4, Color("#06101a"))


## The reader lamp on the bolt panel, in the world (LABELS decision: state on a lamp, never a
## permanent word). One housing; the lamp's shape and colour carry the state.
##   locked: red padlock (sentry on the line)        idle: amber ring and dot (OVERRIDE ONLY)
##   denied: red cross (blinks)                       timer: red padlock in a draining ring (READER LOCKED)
##   granted: green tick                              forced: flashing red warning triangle (DOOR FORCED)
class WorldLamp extends Node2D:
	var kind: StringName = &"idle"
	var tint: Color = Color.WHITE
	var drain: float = 0.7

	func _draw() -> void:
		var r: float = 7.0
		draw_rect(Rect2(-r - 4, -r - 4, r * 2 + 8, r * 2 + 8), Color("#0b141b"))
		draw_rect(Rect2(-r - 4, -r - 4, r * 2 + 8, r * 2 + 8), Color(0.35, 0.5, 0.58, 0.9), false, 1.0)
		draw_circle(Vector2.ZERO, r + 7.0, Color(tint, 0.16))
		match kind:
			&"idle":
				draw_arc(Vector2.ZERO, r - 1.0, 0.0, TAU, 24, tint, 1.6, true)
				draw_circle(Vector2.ZERO, r * 0.36, tint)
			&"locked":
				draw_rect(Rect2(-r * 0.6, -r * 0.05, r * 1.2, r * 0.8), tint)
				draw_arc(Vector2(0, -r * 0.05), r * 0.38, PI, TAU, 12, tint, 1.6, true)
			&"timer":
				draw_rect(Rect2(-r * 0.5, 0.0, r, r * 0.6), tint)
				draw_arc(Vector2(0, 0), r * 0.3, PI, TAU, 10, tint, 1.4, true)
				draw_arc(Vector2.ZERO, r, -PI * 0.5, -PI * 0.5 + TAU * drain, 24, tint, 1.8, true)
			&"denied":
				var d: float = r * 0.55
				draw_line(Vector2(-d, -d), Vector2(d, d), tint, 2.2, true)
				draw_line(Vector2(-d, d), Vector2(d, -d), tint, 2.2, true)
			&"granted":
				draw_polyline(PackedVector2Array([Vector2(-r * 0.6, 0), Vector2(-r * 0.15, r * 0.45), Vector2(r * 0.65, -r * 0.5)]), tint, 2.2, true)
			&"forced":
				draw_colored_polygon(PackedVector2Array([Vector2(0, -r), Vector2(r, r * 0.75), Vector2(-r, r * 0.75)]), tint)
				draw_line(Vector2(0, -r * 0.35), Vector2(0, r * 0.25), Color("#06101a"), 1.6, true)
				draw_circle(Vector2(0, r * 0.5), 1.0, Color("#06101a"))


## A thin stencilled hazard band along the card's title rule.
class HazardBand extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#0b1620"))
		var x: float = -size.y
		while x < size.x:
			draw_colored_polygon(PackedVector2Array([Vector2(x, size.y), Vector2(x + size.y, 0), Vector2(x + size.y + 7, 0), Vector2(x + 7, size.y)]), Color(0.95, 0.77, 0.43, 0.85))
			x += 16.0
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0))


## The mocked wall screen in Records Access that holds the found code (world coordinates).
class PinAccessScreen extends Node2D:
	func _draw() -> void:
		var r: Rect2 = Rect2(312, 326, 40, 30)
		draw_rect(r.grow(3), Color("#1a2630"))
		draw_rect(r.grow(3), Color("#4a6572"), false, 1.5)
		draw_rect(r, Color("#0b1a12"))
		for i: int in 5:
			var w: float = [30.0, 22.0, 26.0, 14.0, 24.0][i]
			draw_rect(Rect2(r.position.x + 4, r.position.y + 4 + i * 5, w, 2), Color(0.95, 0.77, 0.43, 0.9 if i != 2 else 1.0))
		draw_rect(Rect2(r.position.x + 30, r.position.y + 15, 6, 4), Color("#ff8a8f"))


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	out_dir = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Node2D
	game.set("settings_path", "user://pin-settings.cfg")
	game.set("save_path", "user://pin-save.json")
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	await _frames(2)
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	tools = game.get("debug_tools")
	tools.debug_build = true
	await _wait(0.8)
	await _records_find()
	await _junction()
	game.queue_free()
	await _frames(2)
	quit(0)


# --- Records Access: the find ----------------------------------------------------------------------

func _records_find() -> void:
	tools.actions.jump(&"records_mirror")
	await _wait(1.4)
	tools.hide_note()
	var records: RecordsRoom = game.get("records_room")
	records.add_child(PinAccessScreen.new())
	records.call("_add_station_label", "ACCESS SCREEN", 332.0, AMBER)
	game.debug_place(298.0, 222.0)
	game.set("status_line", "SERVICE LINE / ACCESS\nLOCKDOWN: PERSONAL CODES REVOKED.\nHATCH OVERRIDE: 4071. CHANGE: OVERDUE.")
	await _wait(1.0)
	paused = true
	await _frames(2)
	(game.get("context_hint_text") as Label).text = "Logged: SERVICE OVERRIDE"
	(game.get("hud") as Label).text = "RECORDS ACCESS / FIRST COPY\nREACH EXIT"
	await _shot("0-records-find")
	paused = false


# --- Service Junction: the hatch reader ------------------------------------------------------------

var lamp: WorldLamp


func _set_lamp(kind: StringName, tint: Color, drain: float = 0.7) -> void:
	lamp.visible = true
	lamp.kind = kind
	lamp.tint = tint
	lamp.drain = drain
	lamp.queue_redraw()


func _junction() -> void:
	tools.actions.jump(&"tank_down")
	await _wait(1.6)
	tools.hide_note()
	var station: Vector4 = Main.JUNCTION_STATIONS[3]
	var spot: float = game.debug_station_side_x(station, station.x - 1.0)
	# cfe304f: with the sentry down WOLF waits at his spot in the hatch doorway (WOLF_DOWN_X); leave him there.
	game.debug_place(spot, JunctionRoom.WOLF_DOWN_X)
	var room: JunctionRoom = game.get("junction_room")
	lamp = WorldLamp.new()
	lamp.position = Vector2(JunctionRoom.BOLT_PANEL_X + LAMP_OFFSET.x, RoomDepth.FLOOR_Y + LAMP_OFFSET.y)
	lamp.z_index = 6
	room.add_child(lamp)
	_set_lamp(&"idle", AMBER)
	await _wait(1.6)
	paused = true
	await _frames(2)
	for part: String in ["bottom_bar", "context_hint", "tutorial_prompt", "touch_controls"]:
		(game.get(part) as CanvasItem).hide()
	(game.get("hud") as Label).text = "SERVICE JUNCTION\nOPEN THE HATCH"
	var frames: Array[Dictionary] = [
		{"name": "1-idle", "digits": "", "state": &"idle", "known": true, "focus": "known"},
		{"name": "2-entering", "digits": "407", "state": &"entering", "known": true, "focus": "7"},
		{"name": "3-wrong", "digits": "4017", "state": &"denied", "known": true, "focus": "DEL"},
		{"name": "4-lockout", "digits": "", "state": &"locked", "known": true, "focus": "manual"},
		{"name": "5-accepted", "digits": "4071", "state": &"granted", "known": true, "focus": ""},
		{"name": "6-touch-unknown", "digits": "", "state": &"idle", "known": false, "focus": "", "touch": true},
	]
	for f: Dictionary in frames:
		var st: StringName = f["state"]
		match st:
			&"denied": _set_lamp(&"denied", RED)
			&"locked": _set_lamp(&"timer", RED, 0.8)
			&"granted": _set_lamp(&"granted", GREEN)
			_: _set_lamp(&"idle", AMBER)
		await _frames(1)
		_build(f)
		await _shot(f["name"])
	# MANUAL RELEASE, mid-crank: no card, the DOOR FORCED lamp, the hold hint and WOLF's authored action.
	if layer != null:
		layer.queue_free()
		layer = null
	_set_lamp(&"forced", RED)
	for part: String in ["bottom_bar", "context_hint"]:
		(game.get(part) as CanvasItem).show()
	game.set("status_line", "The manual release fights back. An alarm sounds: DOOR FORCED.\nWOLF keeps his eyes on the lane while the alarm sounds.")
	game.call("debug_refresh_ui")
	await _frames(2)
	(game.get("context_hint_text") as Label).text = "Hold E: crank the manual release. 4 / 6"
	(game.get("hud") as Label).text = "SERVICE JUNCTION\nOPEN THE HATCH"
	await _shot("7-manual-crank")
	# MANUAL RELEASE at 6/6: the route hands over to the same chain as the code route. Here today's
	# real bolt USE (_pop_bolt, then _bolt_arc) plays it, so the arc, flash, sparks and shake are the game's own.
	lamp.visible = false
	paused = false
	game.debug_place(spot, JunctionRoom.WOLF_DOWN_X)
	game.call("debug_interact")
	await _wait(0.62)
	await _shot_now("8-manual-arc")
	await _wait(0.9)
	paused = true
	await _frames(1)


func _build(f: Dictionary) -> void:
	if layer != null:
		layer.queue_free()
	layer = CanvasLayer.new()
	layer.layer = 8
	root.add_child(layer)
	var touch: bool = f.get("touch", false)
	var state: StringName = f["state"]
	var tint: Color = {&"idle": AMBER, &"entering": AMBER, &"denied": RED, &"locked": RED, &"granted": GREEN}[state]
	var shell: Control = Control.new()
	shell.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(shell)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.008, 0.018, 0.035, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	shell.add_child(dim)
	# No world chip: the reader's state is on the lamp on the bolt panel (drawn in the world, under the dim).
	# The card.
	var key_w: float = 92.0 if touch else 88.0
	var key_h: float = 78.0 if touch else 72.0
	# Touch: 12 canvas px gaps (about 8.6 pt at a 390 pt phone's 0.72 scale, over Android's 8 dp).
	var gap: float = 12.0 if touch else 8.0
	var pad_w: float = key_w * 3 + gap * 2
	var pad_h: float = key_h * 4 + gap * 3
	var left_w: float = 238.0
	var card_size: Vector2 = Vector2(20 + left_w + 18 + pad_w + 20, 62 + pad_h + (26 if not touch else 18))
	var card: Panel = Panel.new()
	card.theme_type_variation = &"MenuPanel"
	card.position = Vector2(72.0 if not touch else 40.0, 84.0 if not touch else 78.0)
	card.size = card_size
	shell.add_child(card)
	var sheen: Panel = Panel.new()
	sheen.theme_type_variation = &"CardSheen"
	sheen.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sheen)
	_label(card, "SERVICE HATCH / LOCKDOWN", Rect2(20, 10, 360, 28), 19, Color.WHITE, DISPLAY_FONT)
	_label(card, "RESTRICTED AREA", Rect2(card_size.x - 160, 16, 140, 18), 11, MUTED, CONTROL_FONT).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var hazard: HazardBand = HazardBand.new()
	hazard.position = Vector2(20, 42)
	hazard.size = Vector2(card_size.x - 40, 5)
	card.add_child(hazard)
	# Left column: readout, state, known code, manual release, back.
	var readout: Panel = Panel.new()
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color("#06111c")
	box.border_color = tint if state in [&"denied", &"granted", &"locked"] else Color("#2b4a5c")
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	readout.add_theme_stylebox_override("panel", box)
	readout.position = Vector2(20, 58)
	readout.size = Vector2(left_w, 78)
	card.add_child(readout)
	var digits: String = f["digits"]
	for i: int in 4:
		var cell_x: float = 15 + i * 54
		var has: bool = i < digits.length()
		var ch: String = digits[i] if has else ""
		if state == &"locked":
			ch = "–"
		var col: Color = Color.WHITE
		if state == &"denied":
			col = RED
		elif state == &"granted":
			col = GREEN
		elif state == &"locked":
			col = Color(RED, 0.6)
		_label(readout, ch, Rect2(cell_x, 8, 46, 52), 38, col, DISPLAY_FONT).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var line: ColorRect = ColorRect.new()
		line.color = Color(ACCENT, 0.9) if (i == digits.length() and state in [&"idle", &"entering"]) else Color("#3d5a6a")
		line.position = Vector2(cell_x + 4, 62)
		line.size = Vector2(38, 3)
		readout.add_child(line)
	var lamp: PinLamp = PinLamp.new()
	lamp.kind = &"idle" if state == &"entering" else state
	lamp.tint = tint
	lamp.position = Vector2(20, 146)
	lamp.size = Vector2(26, 26)
	card.add_child(lamp)
	var state_text: String = {&"idle": "ENTER OVERRIDE", &"entering": "ENTER OVERRIDE", &"denied": "DENIED 1/3", &"locked": "READER LOCKED 0:05", &"granted": "ACCESS GRANTED"}[state]
	_label(card, state_text, Rect2(54, 145, left_w - 34, 28), 17, tint, DISPLAY_FONT)
	var sub: String = {&"idle": "MODE: OVERRIDE ONLY", &"entering": "MODE: OVERRIDE ONLY", &"denied": "CODE NOT ACCEPTED", &"locked": "3 WRONG CODES. WAIT, OR RELEASE BY HAND.", &"granted": "BOLT RELEASING"}[state]
	var sub_label: Label = _label(card, sub, Rect2(20, 176, left_w, 34), 11, MUTED, CONTROL_FONT)
	sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	var y: float = 212.0
	var known_button: Button = null
	if f["known"]:
		_label(card, "FROM YOUR CASE: SERVICE OVERRIDE", Rect2(20, y, left_w, 16), 10, MUTED, CONTROL_FONT)
		known_button = _button(card, "ENTER  4 0 7 1", Rect2(20, y + 18, left_w, key_h), 18)
		known_button.disabled = state in [&"locked", &"granted"]
		y += 18 + key_h + gap
	else:
		y += 4
	var manual_h: float = key_h if touch else 44.0
	var manual: Button = _button(card, "MANUAL RELEASE", Rect2(20, y, left_w, manual_h), 15)
	manual.disabled = state == &"granted"
	var manual_note: Label = null
	if not f["known"]:
		manual_note = _label(card, "Crank the bolt back by hand. It sets off the door alarm.", Rect2(20, y + manual_h + 6, left_w, 36), 12, MUTED)
		manual_note.autowrap_mode = TextServer.AUTOWRAP_WORD
	var back_y: float = y + manual_h + gap
	if not f["known"]:
		back_y += 40
	var back: Button = _button(card, "BACK", Rect2(20, back_y, left_w, 44.0 if not touch else key_h), 15)
	var left_bottom: float = back_y + back.size.y
	back.disabled = state == &"granted"
	# Right column: the phone-layout pad.
	var pad_x: float = 20 + left_w + 18
	var keys: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "DEL", "0", "ENTER"]
	var by_text: Dictionary = {}
	for i: int in keys.size():
		var col_i: int = i % 3
		var row_i: int = int(i / 3.0)
		var b: Button = _button(card, keys[i], Rect2(pad_x + col_i * (key_w + gap), 58 + row_i * (key_h + gap), key_w, key_h), 26 if keys[i].length() == 1 else 14)
		if keys[i].length() == 1:
			b.add_theme_font_override("font", DISPLAY_FONT)
		b.disabled = state in [&"locked", &"granted"]
		by_text[keys[i]] = b
	if state == &"entering":
		(by_text["7"] as Button).toggle_mode = true
		(by_text["7"] as Button).button_pressed = true
	var right_bottom: float = 58 + pad_h
	if not touch:
		_label(card, "0-9 TYPE  ·  BKSP DELETE  ·  ENTER SUBMIT  ·  ESC CLOSE", Rect2(pad_x, 58 + pad_h + 8, pad_w, 16), 9, MUTED, CONTROL_FONT).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right_bottom += 26
	card.size.y = maxf(left_bottom, right_bottom) + 20.0
	card.position.y = clampf(270.0 - card.size.y * 0.5 + 18.0, 82.0, 540.0 - card.size.y - 12.0)
	var focus: String = f["focus"]
	var target: Control = null
	if focus == "known":
		target = known_button
	elif focus == "manual":
		target = manual
	elif by_text.has(focus):
		target = by_text[focus]
	if target != null:
		target.grab_focus()
	else:
		var holder: Control = Control.new()
		holder.focus_mode = Control.FOCUS_ALL
		shell.add_child(holder)
		holder.grab_focus()


func _label(parent: Control, text: String, rect: Rect2, font_size: int, color: Color, font: Font = null) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(rect.size.x, 0)
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if font != null:
		label.add_theme_font_override("font", font)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, rect: Rect2, font_size: int) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", font_size)
	parent.add_child(b)
	return b


func _shot(label: String) -> void:
	await _wait(0.25)
	await _frames(3)
	var image: Image = root.get_texture().get_image()
	image.save_png(out_dir.path_join(label + ".png"))
	print("shot ", label, " ", image.get_size())


func _shot_now(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png(out_dir.path_join(label + ".png"))
	print("shot ", label, " ", image.get_size())


func _wait(seconds: float) -> void:
	await create_timer(seconds, true).timeout


func _frames(count: int) -> void:
	for _i: int in count:
		await process_frame
