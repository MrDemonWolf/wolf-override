class_name DebugZones
extends Control
## The debug overlay's zones page, drawn over the game so a tester or a capture driver can see what
## the rules see: zones (every station's use range, the sentry's lane, sight and chase limits, WOLF's
## spots and follow gap, the camera and walk limits, the seal's and door's limits), hitboxes (every
## collision shape from its real shape, and the rule ranges that hurt or hit: the vent, the blast,
## the cloud, the sentry's contact, the tank's footprint and hit range) and render boxes (the on-screen
## rectangle of every sprite, prop, plate layer, custom-drawn prop, label and UI panel, named, with its
## z-index and canvas layer). Each category has its own colour, a legend button, a key (F5 to F7) and
## a controller button (LB, RB, View).
##
## Nothing it draws covers the touch arrows, USE, the answers, PAUSE or the text of the hint, the
## dialogue, the tutorial or the top card: lines and fills are cut around them, and every name is
## placed where it overlaps none of them, no actor and no other name (a name with no room left is
## reported, not drawn).
##
##
## Everything is worked out from the live nodes and the constants the rules use (Main's, M0Actor's,
## M0State's, PressureLine's, DropArm's, SentryBrain's, JunctionRoom's), never from copied numbers,
## and the same items are drawn and reported: geometry() gives them as plain numbers for the JSON dump.
##
## It sits on DebugTools' canvas layer and draws in screen space, mapping the world through the
## viewport's canvas transform every frame, so it follows the camera. Hidden, it neither processes
## nor draws; DebugTools shows it only on the zones page (or for a capture with boxes).

## A category was turned on or off (the legend, F5 to F7 or set_layer).
signal layers_changed

## The draw categories, with their legend names, colours and toggle keys.
const ZONES: StringName = &"zones"
const HITBOXES: StringName = &"hitboxes"
const RENDER: StringName = &"render"
const CATEGORIES: Array[StringName] = [ZONES, HITBOXES, RENDER]
const CATEGORY_NAMES: Dictionary = {ZONES: "ZONES", HITBOXES: "HITBOXES", RENDER: "RENDER"}
const CATEGORY_KEYS: Dictionary = {ZONES: KEY_F5, HITBOXES: KEY_F6, RENDER: KEY_F7}
## On a controller, buttons the game leaves unbound (DebugTools skips one a player has bound).
const CATEGORY_PAD_BUTTONS: Dictionary = {ZONES: JOY_BUTTON_LEFT_SHOULDER, HITBOXES: JOY_BUTTON_RIGHT_SHOULDER, RENDER: JOY_BUTTON_BACK}
## The legend's caption for each input device.
const CAPTIONS: Dictionary = {"keyboard": "DRAW  F5 · F6 · F7", "controller": "DRAW  LB · RB · VIEW", "touch": "DRAW  TAP TO TOGGLE"}
const COLORS: Dictionary = {ZONES: Color("#73DDF5"), HITBOXES: Color("#ff9a4a"), RENDER: Color("#d7f36b")}
## Filled over an armed hazard or a hit range that is live right now.
const ARMED: Color = Color("#ff4a3d")
const SHADOW: Color = Color(0.015, 0.025, 0.04, 0.9)
const MUTED: Color = Color("#9fc3d2")
const FONT_SIZE: int = 9
## The x-range rows, placed in lanes under the floor line in screen pixels so ranges never draw over
## each other; the rows only set the order they are placed in (the camera's take the lowest lane).
enum Row { USE, HURT, LANE, WOLF, CAMERA }
const ROW_TOP: float = 4.0
const ROW_HEIGHT: float = 11.0
const BAR_HEIGHT: float = 2.0
## Behind each name, so it reads over the floor art.
const LABEL_BACKING: Color = Color(0.015, 0.025, 0.04, 0.72)
## A range that is not in force right now is drawn this strong.
const IDLE_STRENGTH: float = 0.7
## Limit lines run from this world height down to the floor; a name takes the first line down its
## length (on either side of it) where it overlaps nothing.
const LIMIT_TOP_Y: float = 250.0
## Render boxes fainter than this (a faded label, a hidden card fading out) are reported, not drawn.
const MIN_ALPHA: float = 0.02
## A box name with no room at its corners may sit up to this many lines further up or down its left
## edge, with a leader line to the corner.
const LEADER_STEPS: int = 6
## The candidate sprites and controls are gathered again this often while shown; their rects every frame.
const REFRESH_SECONDS: float = 0.25
## The legend: between the top card (ends x 466) and the DEBUG button (from about x 768), above the
## title's brand line (y 106) and the answer row (y 88), so it covers no game control.
const LEGEND_RECT: Rect2 = Rect2(474.0, 10.0, 262.0, 58.0)
## The legend buttons keep the theme's button look with tighter padding, so all three fit.
const LEGEND_BUTTON_PADDING: Vector2 = Vector2(6.0, 2.0)
## Sprites under an actor that are not its body (its floor shadow and reflection, its glows).
const NOT_BODY: Array[String] = ["Shadow", "Reflection", "Glow"]
## Controls that only lay out their children draw nothing of their own, so they get no render box.
const LAYOUT_ONLY: Array[String] = ["Control", "VBoxContainer", "HBoxContainer", "BoxContainer", "MarginContainer", "GridContainer", "CenterContainer", "FlowContainer", "HFlowContainer", "VFlowContainer", "AspectRatioContainer", "SubViewportContainer"]


## One drawn and reported thing: a zone, a hitbox or a render box.
class Item:
	extends RefCounted
	var category: StringName
	var name: String
	## x_range, spot, limit, ray, shape, rect, or the node class for a render box.
	var kind: String
	## The constants or node it comes from.
	var source: String = ""
	var path: String = ""
	## In world (or, on a canvas layer, layer) coordinates, and in the 960x540 canvas.
	var world: Rect2
	var screen: Rect2
	var row: int = -1
	## In force right now (an armed hazard, the target WOLF is heading for, a live range).
	var active: bool = true
	var extra: Dictionary = {}
	## The name drawn beside it and where (screen); an empty rect when it is not drawn.
	var label: String = ""
	var label_rect: Rect2 = Rect2()
	## It has a name, but no place was free of the protected controls, text, actors and other names.
	var label_hidden: bool = false

	## The item as plain values for the JSON dump: its category, name, kind, source, path, world and screen
	## rects ([x, y, w, h]) and whether it is active, plus its extra fields, and label_rect or label_hidden
	## when it has them.
	func to_dict() -> Dictionary:
		var data: Dictionary = {
			"category": str(category), "name": name, "kind": kind, "source": source, "path": path,
			"world_rect": DebugZones.rect_array(world), "screen_rect": DebugZones.rect_array(screen), "active": active,
		}
		data.merge(extra)
		if label_rect.has_area():
			data["label_rect"] = DebugZones.rect_array(label_rect)
		if label_hidden:
			data["label_hidden"] = true
		return data


## Where names may go: a coarse grid of the rectangles already taken, so each placement checks only
## its neighbours.
class LabelSpace:
	extends RefCounted
	const CELL: float = 64.0
	var cells: Dictionary = {}

	## Marks [param rect] (screen px) taken, in every grid cell it touches.
	func add(rect: Rect2) -> void:
		for key: Vector2i in _keys(rect):
			(cells.get_or_add(key, []) as Array).append(rect)

	## True when [param rect] (screen px) overlaps no rectangle taken so far.
	func is_free(rect: Rect2) -> bool:
		for x: int in range(floori(rect.position.x / CELL), floori(rect.end.x / CELL) + 1):
			for y: int in range(floori(rect.position.y / CELL), floori(rect.end.y / CELL) + 1):
				var taken: Variant = cells.get(Vector2i(x, y))
				if taken == null:
					continue
				for other: Rect2 in taken:
					if other.intersects(rect):
						return false
		return true

	## The taken rectangles [param rect] overlaps.
	func hits(rect: Rect2) -> Array[Rect2]:
		var found: Array[Rect2] = []
		for key: Vector2i in _keys(rect):
			for other: Rect2 in cells.get(key, []):
				if other.intersects(rect) and not found.has(other):
					found.append(other)
		return found

	## The grid cells (CELL px square) [param rect] touches, edges included.
	static func _keys(rect: Rect2) -> Array[Vector2i]:
		var keys: Array[Vector2i] = []
		var start: Vector2i = Vector2i(floori(rect.position.x / CELL), floori(rect.position.y / CELL))
		var end: Vector2i = Vector2i(floori(rect.end.x / CELL), floori(rect.end.y / CELL))
		for x: int in range(start.x, end.x + 1):
			for y: int in range(start.y, end.y + 1):
				keys.append(Vector2i(x, y))
		return keys


## Which categories are drawn; all of them are always reported.
var layers: Dictionary = {ZONES: true, HITBOXES: true, RENDER: true}
var game: Main
## Nodes left out of the render boxes (the debug tools' own).
var skip_root: Node
## The debug tools' own cards over this drawing (the state card, the DEBUG button, the note); names
## stay off them.
var own_controls: Array[Control] = []
var legend: PanelContainer
var legend_caption: Label
var legend_buttons: Dictionary = {}
var _candidates: Array[CanvasItem] = []
var _refresh_left: float = 0.0
## The screen y under the last rule lane, where the limit lines end.
var _lanes_bottom: float = 0.0
## This pass's protected rectangles (screen): drawing is cut around _clear, names stay off _blockers
## (_clear, the debug tools' cards and the actors). _clear_nodes: the nodes they belong to, whose own
## render boxes are drawn whole.
var _clear: Array[Rect2] = []
var _clear_names: Array[String] = []
var _clear_nodes: Dictionary = {}
var _blockers: Array[Rect2] = []
var _actor_rects: Array[Rect2] = []
## Scripts already checked for a _draw of their own.
var _draw_scripts: Dictionary = {}
## Names already measured (_text_width).
var _widths: Dictionary = {}


## Names the node and fills the screen without taking the mouse, hidden and idle until set_shown.
func _init() -> void:
	name = "DebugZones"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	set_process(false)


## Wires this to the game [param main], leaves [param skip] (the debug tools' own nodes) out of the
## render boxes, and builds the legend. DebugTools calls it once.
func setup(main: Main, skip: Node) -> void:
	game = main
	skip_root = skip
	_build_legend()


## Builds the legend card at LEGEND_RECT (canvas px): the device caption and one toggle button per
## category, with the theme's button look at LEGEND_BUTTON_PADDING. Its buttons never take keyboard or
## controller focus.
func _build_legend() -> void:
	legend = PanelContainer.new()
	legend.name = "DrawLegend"
	legend.theme_type_variation = &"HudCard"
	legend.position = LEGEND_RECT.position
	legend.size = LEGEND_RECT.size
	legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(legend)
	var margin: MarginContainer = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, 6 if side in ["left", "right"] else 3)
	legend.add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 2)
	margin.add_child(column)
	var caption: Label = Label.new()
	caption.name = "Caption"
	caption.text = CAPTIONS["keyboard"]
	legend_caption = caption
	caption.add_theme_font_size_override("font_size", 10)
	caption.add_theme_color_override("font_color", MUTED)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(caption)
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	column.add_child(row)
	for category: StringName in CATEGORIES:
		var button: Button = Button.new()
		button.name = "%sToggle" % CATEGORY_NAMES[category].capitalize()
		button.toggle_mode = true
		button.button_pressed = layers[category]
		# A touch and mouse control: keyboard and controller focus stays on the game (keys and
		# controller buttons toggle the categories instead).
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(80.0, 26.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 11)
		button.toggled.connect(set_layer.bind(category))
		row.add_child(button)
		for state: String in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
			var theme_box: StyleBox = button.get_theme_stylebox(state)
			if theme_box == null:
				continue
			var box: StyleBox = theme_box.duplicate() as StyleBox
			box.content_margin_left = LEGEND_BUTTON_PADDING.x
			box.content_margin_right = LEGEND_BUTTON_PADDING.x
			box.content_margin_top = LEGEND_BUTTON_PADDING.y
			box.content_margin_bottom = LEGEND_BUTTON_PADDING.y
			button.add_theme_stylebox_override(state, box)
		legend_buttons[category] = button
		_style_button(category)


## Draws [param category] or not; the legend button follows.
func set_layer(on: bool, category: StringName) -> void:
	if not layers.has(category):
		return
	layers[category] = on
	var button: Button = legend_buttons.get(category) as Button
	if button != null and button.button_pressed != on:
		button.set_pressed_no_signal(on)
	_style_button(category)
	queue_redraw()
	layers_changed.emit()


## Turns [param category]'s drawing over (F5 to F7, LB, RB or View); see set_layer.
func toggle_layer(category: StringName) -> void:
	set_layer(not bool(layers.get(category, false)), category)


## The legend's caption names the toggles for [param device]: "keyboard", "controller" or "touch".
func set_device(device: String) -> void:
	if legend_caption != null:
		legend_caption.text = CAPTIONS.get(device, CAPTIONS["keyboard"])


## Labels [param category]'s legend button with a filled or empty box and tints it with its colour while
## on, muted while off.
func _style_button(category: StringName) -> void:
	var button: Button = legend_buttons.get(category) as Button
	if button == null:
		return
	var on: bool = layers[category]
	button.text = "%s %s" % ["■" if on else "□", CATEGORY_NAMES[category]]
	var tint: Color = COLORS[category] if on else MUTED.darkened(0.3)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, tint)


## Shown, it redraws every frame (the camera moves) and gathers its candidates REFRESH_SECONDS apart;
## hidden, it costs nothing.
func set_shown(shown: bool) -> void:
	if shown == visible and shown == is_processing():
		return
	visible = shown
	set_process(shown)
	if shown:
		refresh_now()


## Gathers the candidates again and redraws at once.
func refresh_now() -> void:
	_candidates = _gather_candidates()
	_refresh_left = REFRESH_SECONDS
	queue_redraw()


## While shown: redraws every frame, and gathers the render candidates again every REFRESH_SECONDS
## ([param delta] in seconds).
func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left <= 0.0:
		_candidates = _gather_candidates()
		_refresh_left = REFRESH_SECONDS
	queue_redraw()


# --- What is drawn and reported ---------------------------------------------------------------

## Every item of every category, worked out now. [param fresh] gathers the render candidates again
## (dumps and tests); the frame's draw reuses the last gathering.
func items(fresh: bool = true) -> Array[Item]:
	var all: Array[Item] = []
	if game == null:
		return all
	if fresh:
		_candidates = _gather_candidates()
	_begin_pass()
	var render: Array[Item] = render_items(not fresh)
	var rules: Array[Item] = []
	if not _title_open():
		rules = zone_items()
		rules.append_array(hitbox_items())
		_layout(rules)
	_place_box_labels(rules, render)
	all.append_array(render)
	all.append_array(rules)
	return all


## Everything as plain values for the JSON dump: the camera, each category's items (rects as
## [x, y, width, height]) and what was drawn.
func geometry() -> Dictionary:
	var zones: Array[Dictionary] = []
	var hitboxes: Array[Dictionary] = []
	var render: Array[Dictionary] = []
	for item: Item in items(true):
		match item.category:
			ZONES:
				zones.append(item.to_dict())
			HITBOXES:
				hitboxes.append(item.to_dict())
			_:
				render.append(item.to_dict())
	var legend_data: Dictionary = {}
	for category: StringName in CATEGORIES:
		legend_data[str(category)] = {"name": CATEGORY_NAMES[category], "color": "#" + (COLORS[category] as Color).to_html(false), "key": OS.get_keycode_string(CATEGORY_KEYS[category]), "drawn": visible and bool(layers[category])}
	var final: Transform2D = get_viewport().get_final_transform() if is_inside_tree() else Transform2D.IDENTITY
	return {
		"rect_format": "[x, y, width, height]",
		"spaces": "world_rect: the room's coordinates (a UI node's: its canvas layer's); screen_rect: the 960x540 canvas; window pixels = screen * screen_to_window.scale + screen_to_window.offset",
		"screen_to_window": {"scale": [final.x.x, final.y.y], "offset": [final.origin.x, final.origin.y]},
		"camera": camera_info(),
		"drawn": visible,
		"keep_clear": keep_clear_info(),
		"legend": legend_data,
		"zones": zones,
		"hitboxes": hitboxes,
		"render_boxes": render,
	}


## The play camera: where it is, its zoom, the world it shows and the limits it is held to.
func camera_info() -> Dictionary:
	var camera: Camera2D = game.intro_camera if game != null else null
	var view: Rect2 = _world_view()
	var info: Dictionary = {"view_world_rect": rect_array(view)}
	if camera != null:
		info["position"] = [camera.global_position.x, camera.global_position.y]
		info["screen_center"] = [camera.get_screen_center_position().x, camera.get_screen_center_position().y]
		info["zoom"] = camera.zoom.x
	var limits: Vector2 = _camera_centre_limits()
	info["centre_x_limits"] = [limits.x, limits.y]
	return info


## The world rectangle the viewport shows right now.
func _world_view() -> Rect2:
	if not is_inside_tree():
		return Rect2()
	return get_viewport().get_canvas_transform().affine_inverse() * _view()


## Where Main holds the play camera's centre (Main._update_gameplay_camera): half its view in from
## each end of the 960 px room.
func _camera_centre_limits() -> Vector2:
	var half_view: float = Main.GAMEPLAY_VIEW_WIDTH * 0.5
	return Vector2(half_view, 960.0 - half_view)


## True while the title is up (or no game is wired): the rules' zones and hitboxes are left out then, and only
## render boxes are drawn.
func _title_open() -> bool:
	return game == null or game.title_open


## The game's live progress (Main.state).
func _state() -> M0State:
	return game.state


# --- Zones ------------------------------------------------------------------------------------

## The current room's zones: its stations' use ranges and the engineer's own spots, its limits, the
## sentry's lane in the junction, WOLF's spots, follow gap and the machines he rests clear of, and the
## camera's limits.
func zone_items() -> Array[Item]:
	var list: Array[Item] = []
	var state: M0State = _state()
	if state == null:
		return list
	var human: M0Actor = game.human
	var wolf: M0Actor = game.wolf
	match state.chapter_id:
		"lockdown":
			var stations: Array[Vector4] = Main.CORRIDOR_STATIONS
			var relay_x: float = Main.RELAY_X
			var relay_reach: float = Main.RELAY_REACH
			var wheel: Vector2 = Main.BYPASS_WHEEL
			var bypass_reach: float = Main.BYPASS_REACH
			list.append(_range(ZONES, "use: purge display", M0Actor.MIN_X, Main.PURGE_DISPLAY_MAX_X, Row.USE, "M0Actor.MIN_X..PURGE_DISPLAY_MAX_X"))
			if stations.size() >= 3:
				list.append(_station(stations[0], "use: breaker", "CORRIDOR_STATIONS[0] (_at_breaker)"))
			list.append(_range(ZONES, "use: relay", relay_x - relay_reach, wheel.x - bypass_reach, Row.USE, "RELAY_X - RELAY_REACH .. BYPASS_WHEEL.x - BYPASS_REACH (_at_relay)"))
			list.append(_range(ZONES, "use: bypass", wheel.x - bypass_reach, wheel.x + bypass_reach, Row.USE, "BYPASS_WHEEL.x ± BYPASS_REACH (_at_bypass)"))
			if stations.size() >= 3:
				list.append(_station(stations[2], "use: safe point", "CORRIDOR_STATIONS[2]"))
			list.append(_spot(ZONES, "stand: relay", Main.RELAY_SIDE_X, Row.USE, "RELAY_SIDE_X"))
			list.append(_spot(ZONES, "crank: bypass", Main.BYPASS_CRANK_X, Row.USE, "BYPASS_CRANK_X"))
			list.append(_spot(ZONES, "step back", Main.RELAY_STEP_BACK_X, Row.USE, "RELAY_STEP_BACK_X"))
			list.append(_spot(ZONES, "WOLF: relay contact", Main.RELAY_CONTACT_X, Row.WOLF, "RELAY_CONTACT_X"))
			list.append(_spot(ZONES, "WOLF: off relay", Main.WOLF_BYPASS_CLEAR_X, Row.WOLF, "WOLF_BYPASS_CLEAR_X"))
			if not state.door_open:
				list.append(_limit(ZONES, "seal face", Main.CORRIDOR_DOOR_LEFT_X, "CORRIDOR_DOOR_LEFT_X"))
		"records":
			var stations: Array[Vector4] = Main.RECORDS_STATIONS
			var names: Array[String] = ["use: purge queue", "use: mirror port", "use: exit"]
			for index: int in mini(stations.size(), names.size()):
				list.append(_station(stations[index], names[index], "RECORDS_STATIONS[%d]" % index))
			list.append(_spot(ZONES, "WOLF: mirror", Main.WOLF_MIRROR_X, Row.WOLF, "WOLF_MIRROR_X"))
		"junction":
			list.append_array(_junction_zones(state))
	# Walk limits, WOLF's follow limit, his follow gap and the machines he rests clear of.
	list.append(_limit(ZONES, "walk limit", M0Actor.MIN_X, "M0Actor.MIN_X"))
	list.append(_limit(ZONES, "walk limit", M0Actor.MAX_X, "M0Actor.MAX_X"))
	if wolf != null:
		if wolf.follow_max_x < M0Actor.MAX_X:
			list.append(_limit(ZONES, "WOLF follow limit", wolf.follow_max_x, "door face - M0Actor.WOLF_REACH (Main._wolf_follow_max_x)"))
		for index: int in wolf.avoid_spans.size():
			var span: Vector2 = wolf.avoid_spans[index]
			var machine: Item = _range(ZONES, "machine", span.x, span.y, Row.WOLF, "Main._machine_spans (M0Actor.avoid_spans)", false)
			# One name for the lot: the machines WOLF rests clear of share a lane.
			machine.extra["quiet"] = index > 0
			if index == 0:
				machine.name = "WOLF rests off: machine"
			list.append(machine)
		if human != null and wolf.follow_target != null:
			var gap: Item = _range(ZONES, "follow gap", human.position.x - M0Actor.FOLLOW_GAP, human.position.x + M0Actor.FOLLOW_GAP, Row.WOLF, "engineer x ± M0Actor.FOLLOW_GAP")
			gap.extra["side"] = wolf.follow_side
			list.append(gap)
		var target: float = game.debug_wolf_target()
		if target >= 0.0:
			var why: String = game.debug_wolf_why()
			var heading: Item = _spot(ZONES, "WOLF → %s" % why, target, Row.WOLF, "Main.debug_wolf_target")
			heading.extra["why"] = why
			heading.extra["target"] = true
			list.append(heading)
	# The camera's centre is held between these; the marker is where it is now.
	var limits: Vector2 = _camera_centre_limits()
	list.append(_range(ZONES, "camera centre limits", limits.x, limits.y, Row.CAMERA, "GAMEPLAY_VIEW_WIDTH / 2 .. 960 - GAMEPLAY_VIEW_WIDTH / 2", false))
	var camera: Camera2D = game.intro_camera
	if camera != null:
		var centre: Item = _spot(ZONES, "camera x%.2f" % camera.zoom.x, camera.get_screen_center_position().x, Row.CAMERA, "IntroCamera screen centre")
		# Not a floor position: a tick in its lane, no line up to the floor.
		centre.extra["tick_only"] = true
		list.append(centre)
	return list


## The junction's stations, the engineer's crank spot, the sentry's lane (the alcove, the patrol,
## its sight, its chase limit and where it watches from), the question line, WOLF's spots and the
## door's face.
func _junction_zones(state: M0State) -> Array[Item]:
	var list: Array[Item] = []
	var stations: Array[Vector4] = Main.JUNCTION_STATIONS
	if stations.size() >= 2:
		list.append(_station(stations[0], "use: overload breaker", "JUNCTION_STATIONS[0]"))
		list.append(_station(stations[1], "use: valve", "JUNCTION_STATIONS[1]"))
	# USE answers at the TANK RELEASE only once the door is down (Main._interact_junction).
	list.append(_range(ZONES, "use: tank release", SentryBrain.COVER_MIN_X, SentryBrain.COVER_MAX_X, Row.USE, "SentryBrain.COVER_MIN_X..COVER_MAX_X (_at_arm_panel, door blown)", state.door_blown))
	list.append(_range(ZONES, "use: exit bolt", JunctionRoom.BOLT_REACH_MIN_X, M0Actor.MAX_X, Row.USE, "JunctionRoom.BOLT_REACH_MIN_X.. (_use_exit)"))
	list.append(_spot(ZONES, "crank: valve", Main.VALVE_CRANK_X, Row.USE, "VALVE_CRANK_X"))
	list.append(_range(ZONES, "alcove (out of sight)", SentryBrain.COVER_MIN_X, SentryBrain.COVER_MAX_X, Row.LANE, "SentryBrain.COVER_MIN_X..COVER_MAX_X"))
	list.append(_range(ZONES, "patrol", SentryBrain.PATROL_MIN_X, SentryBrain.PATROL_MAX_X, Row.LANE, "SentryBrain.PATROL_MIN_X..PATROL_MAX_X", false))
	var brain: SentryBrain = game.sentry_brain
	if brain != null and brain.state != &"down":
		var awake: bool = brain.state != &"dormant"
		var tip: float = brain.x + brain.facing * SentryBrain.SIGHT_RANGE
		var sight: Item = _range(ZONES, "sight %.0f" % SentryBrain.SIGHT_RANGE, minf(brain.x, tip), maxf(brain.x, tip), Row.LANE, "sentry x + facing × SentryBrain.SIGHT_RANGE", awake)
		sight.kind = "ray"
		sight.extra["facing"] = brain.facing
		list.append(sight)
	list.append(_limit(ZONES, "lane entry (rubble)", SentryBrain.LANE_ENTRY_X, "SentryBrain.LANE_ENTRY_X"))
	list.append(_limit(ZONES, "chase limit", SentryBrain.CHASE_MIN_X, "SentryBrain.CHASE_MIN_X"))
	list.append(_limit(ZONES, "lane question", JunctionRoom.CHOICE_X, "JunctionRoom.CHOICE_X"))
	list.append(_spot(ZONES, "sentry watch", SentryBrain.WATCH_X, Row.LANE, "SentryBrain.WATCH_X"))
	list.append(_spot(ZONES, "WOLF: seam", JunctionRoom.WOLF_SEAM_X, Row.WOLF, "JunctionRoom.WOLF_SEAM_X"))
	list.append(_spot(ZONES, "WOLF: clear", JunctionRoom.WOLF_CLEAR_X, Row.WOLF, "JunctionRoom.WOLF_CLEAR_X"))
	list.append(_spot(ZONES, "WOLF: rubble", JunctionRoom.WOLF_RUBBLE_X, Row.WOLF, "JunctionRoom.WOLF_RUBBLE_X"))
	list.append(_spot(ZONES, "WOLF: bait", JunctionRoom.WOLF_BAIT_X, Row.WOLF, "JunctionRoom.WOLF_BAIT_X"))
	if not state.door_blown:
		list.append(_limit(ZONES, "door face", M0State.JUNCTION_DOOR_LEFT_X, "M0State.JUNCTION_DOOR_LEFT_X"))
	return list


# --- Hitboxes ---------------------------------------------------------------------------------

## Every collision shape under Main from its real shape (actor bodies, the floor, the corridor seal,
## the junction door, the sentry's body, the vent and cloud hurtboxes), and in the junction the rule
## ranges that hurt or hit: the vent and cloud by the engineer's x, the blast, the sentry's contact,
## the tank's hit range and its footprint.
func hitbox_items() -> Array[Item]:
	var list: Array[Item] = []
	for node: Node in game.find_children("*", "CollisionShape2D", true, false):
		var shape_node: CollisionShape2D = node as CollisionShape2D
		if _skipped(shape_node) or shape_node.shape == null:
			continue
		list.append(shape_item(shape_node))
	var state: M0State = _state()
	if state == null or state.chapter_id != "junction":
		return list
	var line: PressureLine = game.pressure_line
	var arm: DropArm = game.drop_arm
	var brain: SentryBrain = game.sentry_brain
	var building: bool = line != null and line.state == &"building" and not state.door_blown
	list.append(_range(HITBOXES, "vent (engineer x)", PressureLine.VENT_MIN_X, PressureLine.VENT_MAX_X, Row.HURT, "PressureLine.VENT_MIN_X..VENT_MAX_X (is_on_vent)", building))
	var fuse_lit: bool = line != null and not state.door_blown and line.state in [&"charged", &"fuse"]
	var blast: Item = _range(HITBOXES, "blast", PressureLine.BLAST_MIN_X, PressureLine.BLAST_MAX_X, Row.HURT, "PressureLine.BLAST_MIN_X..BLAST_MAX_X (is_in_blast)", fuse_lit, JunctionRoom.DOOR_HEIGHT)
	list.append(blast)
	var cloud_reach: float = DropArm.CLOUD_HALF_WIDTH + M0State.HUMAN_HALF_WIDTH
	list.append(_range(HITBOXES, "cloud (engineer x)", DropArm.MARK_X - cloud_reach, DropArm.MARK_X + cloud_reach, Row.HURT, "DropArm.MARK_X ± (CLOUD_HALF_WIDTH + M0State.HUMAN_HALF_WIDTH) (in_cloud)", arm != null and arm.cloud_active()))
	if brain != null and brain.state != &"dormant" and brain.state != &"down":
		list.append(_range(HITBOXES, "sentry contact", brain.x - SentryBrain.CONTACT_RANGE, brain.x + SentryBrain.CONTACT_RANGE, Row.HURT, "sentry x ± SentryBrain.CONTACT_RANGE (touches)", brain.state == &"chase"))
	if not state.sentry_down:
		list.append(_range(HITBOXES, "tank hit range", DropArm.MARK_X - DropArm.HIT_REACH, DropArm.MARK_X + DropArm.HIT_REACH, Row.HURT, "DropArm.MARK_X ± HIT_REACH (is_hit, the floor brackets)", arm != null and arm.state == &"falling"))
	var room: JunctionRoom = game.junction_room
	if room != null and room.tank != null:
		var centre: Vector2 = room.tank.global_position
		var footprint: Item = _rect(HITBOXES, "tank footprint", Rect2(centre - JunctionRoom.TANK_SIZE * 0.5, JunctionRoom.TANK_SIZE), "Tank position, JunctionRoom.TANK_SIZE", arm != null and arm.state == &"falling")
		footprint.path = _path(room.tank)
		list.append(footprint)
	return list


## A collision shape's box in the world and on screen, from its shape resource and transform.
func shape_item(shape_node: CollisionShape2D) -> Item:
	var item: Item = Item.new()
	item.category = HITBOXES
	var owner_object: CollisionObject2D = shape_node.get_parent() as CollisionObject2D
	item.name = String(owner_object.name if owner_object != null else shape_node.name)
	item.kind = "shape"
	item.path = _path(shape_node)
	var local: Rect2 = shape_node.shape.get_rect()
	item.world = shape_node.get_global_transform() * local
	item.screen = shape_node.get_global_transform_with_canvas() * local
	var area: Hazard = owner_object as Hazard
	# In force: enabled, monitoring (a hurtbox) and in the room on show (the hidden rooms' shapes are off
	# or out of play).
	item.active = not shape_node.disabled and (area.monitoring if area != null else true) and shape_node.is_visible_in_tree()
	item.source = "%s %s" % [shape_node.shape.get_class(), _size_text(local.size)]
	item.extra = {
		"owner_class": owner_object.get_class() if owner_object != null else "",
		"shape": {"type": shape_node.shape.get_class(), "size": [local.size.x, local.size.y]},
		"disabled": shape_node.disabled,
		"collision_layer": owner_object.collision_layer if owner_object != null else 0,
		"collision_mask": owner_object.collision_mask if owner_object != null else 0,
		"visible": shape_node.is_visible_in_tree(),
	}
	if area != null:
		item.extra["armed"] = area.armed
		item.extra["monitoring"] = area.monitoring
		item.extra["reason"] = area.reason
	return item


# --- Protected areas ----------------------------------------------------------------------------

## Main's controls that nothing drawn may cover, by name: the touch arrows, USE, the answers and PAUSE.
func keep_clear_controls() -> Dictionary:
	return {
		"touch_left": game.touch_left, "touch_right": game.touch_right, "touch_use": game.touch_use,
		"touch_choice_1": game.touch_choice_1, "touch_choice_2": game.touch_choice_2, "pause_button": game.pause_button,
	}


## Main's labels whose text nothing drawn may cover, by name: the hint, the dialogue's speaker and
## line, the tutorial prompt and the top card.
func keep_clear_text() -> Dictionary:
	return {"context_hint_text": game.context_hint_text, "speaker": game.speaker, "story": game.story, "tutorial_text": game.tutorial_text, "hud": game.hud}


## Works out this pass's protected rectangles: Main's controls and HUD text on screen (_clear, which
## drawing is cut around), plus the debug tools' own cards and the actors (_blockers, which names
## stay off).
func _begin_pass() -> void:
	_clear.clear()
	_clear_names.clear()
	_clear_nodes.clear()
	if game != null:
		var controls: Dictionary = keep_clear_controls()
		for property: String in controls:
			var control: Control = controls[property] as Control
			if control != null and control.is_visible_in_tree() and effective_alpha(control) >= MIN_ALPHA:
				_add_clear(control, control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, control.size), property)
		var labels: Dictionary = keep_clear_text()
		for property: String in labels:
			var label: Label = labels[property] as Label
			if label != null and label.is_visible_in_tree() and effective_alpha(label) >= MIN_ALPHA:
				var text: Rect2 = text_rect(label)
				if text.has_area():
					_add_clear(label, text, property + " text")
	_actor_rects = actor_rects()
	_blockers = _clear.duplicate()
	_blockers.append_array(_actor_rects)
	for control: Control in own_controls + [legend]:
		if control != null and control.is_visible_in_tree():
			_blockers.append(control.get_global_rect())


## Protects [param rect] (screen px), belonging to [param node] and reported as [param label]: nothing
## drawn this pass covers it, and the node's own render box is drawn whole.
func _add_clear(node: CanvasItem, rect: Rect2, label: String) -> void:
	_clear.append(rect)
	_clear_names.append(label)
	_clear_nodes[node] = true


## The protected rectangles, for the dump: what nothing drawn may cover, and the actors names stay off.
func keep_clear_info() -> Dictionary:
	_begin_pass()
	var controls: Array[Dictionary] = []
	for index: int in _clear.size():
		controls.append({"name": _clear_names[index], "screen_rect": rect_array(_clear[index])})
	var actors: Array[Array] = []
	for rect: Rect2 in _actor_rects:
		actors.append(rect_array(rect))
	return {"controls_and_text": controls, "actors": actors}


## The screen rectangle [param label]'s text covers (not its whole box), from its characters' bounds.
static func text_rect(label: Label) -> Rect2:
	var bounds: Rect2 = Rect2()
	var found: bool = false
	for index: int in label.text.length():
		var glyph: Rect2 = label.get_character_bounds(index)
		if glyph.size.x <= 0.0 or glyph.size.y <= 0.0:
			continue
		bounds = glyph if not found else bounds.merge(glyph)
		found = true
	if not found:
		return Rect2()
	return label.get_global_transform_with_canvas() * bounds.grow(2.0)


## Each actor's body on screen (its sprites and name tag, not its shadow or reflection): the engineer,
## WOLF and, in the junction, the sentry.
func actor_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if game == null:
		return rects
	var actors: Array[Node] = [game.human, game.wolf]
	var room: JunctionRoom = game.junction_room
	if room != null and room.sentry != null:
		actors.append(room.sentry)
	for actor: Node in actors:
		var canvas_actor: CanvasItem = actor as CanvasItem
		if canvas_actor == null or not canvas_actor.is_visible_in_tree():
			continue
		var body: Rect2 = Rect2()
		var found: bool = false
		for node: Node in actor.find_children("*", "CanvasItem", true, false):
			var part: CanvasItem = node as CanvasItem
			if not (part is Sprite2D or part is AnimatedSprite2D or part is Label) or not part.is_visible_in_tree():
				continue
			if NOT_BODY.any(func(word: String) -> bool: return String(part.name).contains(word)):
				continue
			var rect: Rect2 = part.get_global_transform_with_canvas() * local_rect(part)
			body = rect if not found else body.merge(rect)
			found = true
		if found:
			rects.append(body)
	return rects


# --- Render boxes -----------------------------------------------------------------------------

## The sprites, polygons, lines, drawing controls and custom-drawn nodes under Main, in draw-tree
## order, the debug tools' own left out.
func _gather_candidates() -> Array[CanvasItem]:
	var found: Array[CanvasItem] = []
	if game != null:
		_collect(game, found)
	return found


## Appends [param node] and its descendants that draw a box or draw by themselves to [param found], in
## tree order, skipping skip_root and everything under it.
func _collect(node: Node, found: Array[CanvasItem]) -> void:
	if node == skip_root:
		return
	if node is CanvasItem and (_draws_box(node as CanvasItem) or _custom_draw(node as CanvasItem)):
		found.append(node as CanvasItem)
	for child: Node in node.get_children():
		_collect(child, found)


## True for a sprite, polygon, line, or a Control that draws something itself (not one of LAYOUT_ONLY).
static func _draws_box(item: CanvasItem) -> bool:
	if item is Sprite2D or item is AnimatedSprite2D or item is Polygon2D or item is Line2D:
		return true
	if item is Control:
		return not (item.get_class() in LAYOUT_ONLY)
	return false


## True for a node that draws by itself: its script has a _draw (the sentry's beam, the hatch
## doorway, the room lights and beacons), something draws into it on its draw signal (the bypass's
## crank lights and leader), or it declares what it draws (debug_draw_rect).
func _custom_draw(item: CanvasItem) -> bool:
	if item is Control:
		return false
	if item.has_method(&"debug_draw_rect") or not item.draw.get_connections().is_empty():
		return true
	var script: Script = item.get_script() as Script
	if script == null:
		return false
	if not _draw_scripts.has(script):
		var draws: bool = false
		for method: Dictionary in script.get_script_method_list():
			if method["name"] == "_draw":
				draws = true
				break
		_draw_scripts[script] = draws
	return _draw_scripts[script]


## Each candidate's draw rectangle: in the world (or its canvas layer) and on screen, with its node
## path, class, effective z-index, canvas layer, visibility, alpha, draw order and whether one of
## Main's full-screen cards (the title, the END OF SLICE card) covers it. Covered, faded-out,
## hidden or off-screen boxes are reported, not drawn. [param for_draw] (the frame's drawing) leaves
## out hidden nodes and everything only the dump needs.
func render_items(for_draw: bool = false) -> Array[Item]:
	var list: Array[Item] = []
	var screen_rect: Rect2 = _view()
	var covers: Array[CanvasItem] = _covers()
	var order: int = 0
	for item: CanvasItem in _candidates:
		if not is_instance_valid(item) or not item.is_inside_tree():
			continue
		if for_draw and not item.is_visible_in_tree():
			continue
		var custom: bool = not _draws_box(item)
		var local: Rect2 = local_rect(item)
		var box: Item = Item.new()
		box.category = RENDER
		box.name = _render_name(item)
		box.kind = item.get_class()
		box.world = item.get_global_transform() * local
		box.screen = item.get_global_transform_with_canvas() * local
		var shown: bool = item.is_visible_in_tree()
		var alpha: float = effective_alpha(item)
		var layer: int = canvas_layer(item)
		var covered: bool = _covered(item, layer, covers)
		box.active = shown and not covered and alpha >= MIN_ALPHA and box.screen.intersects(screen_rect) and box.screen.has_area()
		var z: int = absolute_z(item)
		box.label = "%s z%d" % [box.name, z] + (" L%d" % layer if layer != 0 else "")
		if for_draw:
			box.extra = {"z_index": z, "layer": layer}
			if _clear_nodes.has(item):
				box.extra["keep_clear"] = true
			list.append(box)
			continue
		box.path = _path(item)
		box.extra = {
			"z_index": z,
			"layer": layer,
			"visible": shown,
			"alpha": alpha,
			"on_screen": box.screen.intersects(screen_rect),
			"covered": covered,
			"draw_order": order,
		}
		if _clear_nodes.has(item):
			box.extra["keep_clear"] = true
		if custom:
			box.extra["custom_draw"] = true
			box.extra["bounds"] = _custom_bounds_source(item)
		var text: String = _text_of(item)
		if not text.is_empty():
			box.extra["text"] = text
		order += 1
		list.append(box)
	return list


## A node's name, or for a generated name (@Label@115) its class and the start of its text.
static func _render_name(item: CanvasItem) -> String:
	var node_name: String = String(item.name)
	if not node_name.begins_with("@"):
		return node_name
	var text: String = _text_of(item)
	return "%s \"%s\"" % [item.get_class(), text.get_slice("\n", 0).left(18)] if not text.is_empty() else item.get_class()


## The text a label or button shows, for the dump (empty for anything else).
static func _text_of(item: CanvasItem) -> String:
	if item is Label:
		return (item as Label).text
	if item is Button:
		return (item as Button).text
	if item is RichTextLabel:
		return (item as RichTextLabel).get_parsed_text().left(200)
	return ""


## Main's opaque full-screen cards that are up: the title screen, the END OF SLICE card.
func _covers() -> Array[CanvasItem]:
	var found: Array[CanvasItem] = []
	for card: CanvasItem in [game.title_screen, game.end_card]:
		if card != null and card.is_visible_in_tree() and effective_alpha(card) >= 0.9:
			found.append(card)
	return found


## True when [param item] (on canvas layer [param layer]) draws under one of [param covers]: on a
## lower layer, or earlier on the same layer and not inside it.
static func _covered(item: CanvasItem, layer: int, covers: Array[CanvasItem]) -> bool:
	for card: CanvasItem in covers:
		if item == card or card.is_ancestor_of(item):
			continue
		var card_layer: int = canvas_layer(card)
		if layer < card_layer or (layer == card_layer and not item.is_greater_than(card)):
			return true
	return false


## The rectangle [param item] draws in its own space: a sprite's or polygon's bounds, a line's
## points widened by its width, a control's size, or for a custom-drawn node what the renderer
## recorded for it (editor builds) or what it declares it draws (debug_draw_rect).
static func local_rect(item: CanvasItem) -> Rect2:
	if item is Sprite2D:
		return (item as Sprite2D).get_rect()
	if item is AnimatedSprite2D:
		var animated: AnimatedSprite2D = item as AnimatedSprite2D
		var frame: Texture2D = animated.sprite_frames.get_frame_texture(animated.animation, animated.frame) if animated.sprite_frames != null else null
		var frame_size: Vector2 = frame.get_size() if frame != null else Vector2.ZERO
		return Rect2(animated.offset - (frame_size * 0.5 if animated.centered else Vector2.ZERO), frame_size)
	if item is Polygon2D:
		var polygon: Polygon2D = item as Polygon2D
		return _points_rect(polygon.polygon, polygon.offset, 0.0)
	if item is Line2D:
		var line: Line2D = item as Line2D
		return _points_rect(line.points, Vector2.ZERO, line.width * 0.5)
	if item is Control:
		return Rect2(Vector2.ZERO, (item as Control).size)
	var drawn: Rect2 = RenderingServer.debug_canvas_item_get_rect(item.get_canvas_item())
	if drawn.has_area():
		return drawn
	if item.has_method(&"debug_draw_rect"):
		return item.call(&"debug_draw_rect")
	return Rect2()


## Where a custom-drawn node's box comes from: "renderer" (what it drew, editor builds), "declared"
## (its debug_draw_rect), "nothing drawn", or "editor builds only" (an exported build cannot ask the
## renderer and the node declares nothing).
static func _custom_bounds_source(item: CanvasItem) -> String:
	if RenderingServer.debug_canvas_item_get_rect(item.get_canvas_item()).has_area():
		return "renderer"
	if item.has_method(&"debug_draw_rect"):
		return "declared"
	return "nothing drawn" if OS.has_feature("editor") else "editor builds only"


## The box round [param points], each moved by [param offset], grown by [param grow] on every side; an
## empty box at [param offset] when there are none.
static func _points_rect(points: PackedVector2Array, offset: Vector2, grow: float) -> Rect2:
	if points.is_empty():
		return Rect2(offset, Vector2.ZERO)
	var box: Rect2 = Rect2(points[0] + offset, Vector2.ZERO)
	for point: Vector2 in points:
		box = box.expand(point + offset)
	return box.grow(grow)


## The z-index [param item] is drawn at: its own, plus its parents' while it is relative to them.
static func absolute_z(item: CanvasItem) -> int:
	var z: int = item.z_index
	var node: CanvasItem = item
	while node.z_as_relative:
		var parent: CanvasItem = node.get_parent() as CanvasItem
		if parent == null:
			break
		z += parent.z_index
		node = parent
	return clampi(z, RenderingServer.CANVAS_ITEM_Z_MIN, RenderingServer.CANVAS_ITEM_Z_MAX)


## The canvas layer [param item] draws on: its CanvasLayer's layer, or 0 for the world.
static func canvas_layer(item: Node) -> int:
	var node: Node = item.get_parent()
	while node != null:
		if node is CanvasLayer:
			return (node as CanvasLayer).layer
		node = node.get_parent()
	return 0


## How opaque [param item] is drawn: its own and its parents' modulate, and its self-modulate.
static func effective_alpha(item: CanvasItem) -> float:
	var alpha: float = item.self_modulate.a
	var node: Node = item
	while node is CanvasItem:
		alpha *= (node as CanvasItem).modulate.a
		node = node.get_parent()
	return alpha


## True for skip_root (the debug tools) and every node under it.
func _skipped(node: Node) -> bool:
	return skip_root != null and (node == skip_root or skip_root.is_ancestor_of(node))


## [param node]'s path for the dump: relative to Main when under it, else absolute.
func _path(node: Node) -> String:
	return str(game.get_path_to(node)) if game != null and (node == game or game.is_ancestor_of(node)) else str(node.get_path())


# --- Item makers ------------------------------------------------------------------------------

## A rule range along x, drawn as a bar in a lane under the floor; with [param height] it also
## shades that much of the room above the floor (the blast).
func _range(category: StringName, label: String, x_min: float, x_max: float, row: int, source: String, active: bool = true, height: float = 0.0) -> Item:
	var item: Item = Item.new()
	item.category = category
	item.name = label
	item.kind = "x_range"
	item.source = source
	item.row = row
	item.active = active
	var floor_y: float = RoomDepth.FLOOR_Y
	item.world = _to_world(Rect2(x_min, floor_y - height, x_max - x_min, height))
	var left: Vector2 = _world_to_screen(Vector2(x_min, floor_y))
	var right: Vector2 = _world_to_screen(Vector2(x_max, floor_y))
	# Its bar's height under the floor is set by _layout.
	item.screen = Rect2(left.x, left.y, right.x - left.x, BAR_HEIGHT)
	item.extra = {"x_range": [x_min, x_max], "row": row}
	if height > 0.0:
		var top: Vector2 = _world_to_screen(Vector2(x_min, floor_y - height))
		item.extra["screen_area"] = rect_array(Rect2(left.x, top.y, right.x - left.x, left.y - top.y))
	return item


## A station's use range from its Vector4 (centre, half width, reach, side).
func _station(station: Vector4, label: String, source: String) -> Item:
	var item: Item = _range(ZONES, label, station.x - station.z, station.x + station.z, Row.USE, source)
	item.extra["centre_x"] = station.x
	return item


## A spot along x someone is sent to, marked on the floor and named in its lane.
func _spot(category: StringName, label: String, x: float, row: int, source: String) -> Item:
	var item: Item = Item.new()
	item.category = category
	item.name = label
	item.kind = "spot"
	item.source = source
	item.row = row
	item.world = _to_world(Rect2(x, RoomDepth.FLOOR_Y, 0.0, 0.0))
	var at: Vector2 = _world_to_screen(Vector2(x, RoomDepth.FLOOR_Y))
	# It runs down to its lane, which _layout sets.
	item.screen = Rect2(at.x, at.y, 0.0, 0.0)
	item.extra = {"x": x, "row": row}
	return item


## A limit along x (a door's face, the walk limit), drawn as a line from LIMIT_TOP_Y to the floor.
func _limit(category: StringName, label: String, x: float, source: String) -> Item:
	var item: Item = Item.new()
	item.category = category
	item.name = label
	item.kind = "limit"
	item.source = source
	item.world = _to_world(Rect2(x, LIMIT_TOP_Y, 0.0, RoomDepth.FLOOR_Y - LIMIT_TOP_Y))
	var top: Vector2 = _world_to_screen(Vector2(x, LIMIT_TOP_Y))
	var bottom: Vector2 = _world_to_screen(Vector2(x, RoomDepth.FLOOR_Y))
	item.screen = Rect2(top.x, top.y, 0.0, bottom.y - top.y)
	item.extra = {"x": x}
	return item


## A rule rectangle in the world (the tank's footprint).
func _rect(category: StringName, label: String, world: Rect2, source: String, active: bool) -> Item:
	var item: Item = Item.new()
	item.category = category
	item.name = label
	item.kind = "rect"
	item.source = source
	item.active = active
	item.world = _to_world(world)
	item.screen = _canvas() * item.world
	return item


## Main's own space to the world (Main normally sits at the origin).
func _to_world(rect: Rect2) -> Rect2:
	return game.get_global_transform() * rect if game != null else rect


## The viewport's canvas transform (world to screen, following the camera); identity outside the tree.
func _canvas() -> Transform2D:
	return get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY


## [param point] in Main's space as a screen point (canvas px).
func _world_to_screen(point: Vector2) -> Vector2:
	var world: Vector2 = game.get_global_transform() * point if game != null else point
	return _canvas() * world


## The canvas on show (960x540, wider on a wide window).
func _view() -> Rect2:
	return get_viewport().get_visible_rect() if is_inside_tree() else Rect2(0.0, 0.0, 960.0, 540.0)


## The floor line (RoomDepth.FLOOR_Y) as a screen y (canvas px), where the rule lanes start.
func _floor_screen_y() -> float:
	return _world_to_screen(Vector2(0.0, RoomDepth.FLOOR_Y)).y


# --- Layout -----------------------------------------------------------------------------------

## Places the rule ranges and spots in lanes under the floor line and the limits' names near their
## tops. A row's items go in the first lane where the bar overlaps no other bar in that lane and the
## name, at the bar's start or just past whatever is in the way, overlaps no protected control or
## text, no actor and no other name; a spot's line down to its lane must be clear too where it can
## be. The camera's row fills from the lowest lane up. A range wholly off screen is reported, not
## drawn (lane -1). A name with no room left is hidden (label_hidden) and its bar still drawn.
func _layout(list: Array[Item]) -> void:
	var font: Font = get_theme_default_font()
	var view: Rect2 = _view()
	var floor_y: float = _floor_screen_y()
	var space: LabelSpace = LabelSpace.new()
	for rect: Rect2 in _blockers:
		space.add(rect)
	# The lanes from the floor down, and one more on the bottom edge of the screen (the camera's).
	var lane_ys: Array[float] = []
	var bottom_y: float = view.end.y - BAR_HEIGHT - 1.0
	while lane_ys.size() < 1 or _lane_bar_y(floor_y, lane_ys.size()) <= bottom_y - ROW_HEIGHT:
		lane_ys.append(_lane_bar_y(floor_y, lane_ys.size()))
	lane_ys.append(maxf(bottom_y, lane_ys[-1] + ROW_HEIGHT))
	var lane_count: int = lane_ys.size()
	var bars: Array[Array] = []
	for _lane: int in lane_count:
		bars.append([])
	var ordered: Array[Item] = []
	for row: int in Row.values():
		for item: Item in list:
			if item.row == row:
				ordered.append(item)
	var deepest: int = 0
	for item: Item in ordered:
		var x0: float = item.screen.position.x
		var x1: float = item.screen.end.x
		item.extra["lane"] = -1
		if x1 < view.position.x or x0 > view.end.x:
			item.extra["on_screen"] = false
			item.screen = Rect2(x0, floor_y, item.screen.size.x, 0.0)
			continue
		var quiet: bool = bool(item.extra.get("quiet", false))
		var spot: bool = item.kind == "spot"
		var tick: bool = bool(item.extra.get("tick_only", false))
		item.label = "" if quiet else item.name
		var width: float = _text_width(font, item.label)
		var span: Vector2 = Vector2(x0 - 3.0, x1 + 3.0)
		var lanes: Array = range(lane_count)
		if item.row == Row.CAMERA:
			lanes.reverse()
		var lane: int = -1
		var line: Rect2 = Rect2()
		for strict: bool in [true, false]:
			for candidate: int in lanes:
				# A tick (the camera's centre) may sit on another bar; ranges and spots may not.
				if not tick and _overlaps(bars[candidate], span):
					continue
				var bar_y: float = lane_ys[candidate]
				if quiet:
					lane = candidate
					break
				var reach: Rect2 = Rect2(x0 - 1.5, floor_y, 3.0, bar_y + BAR_HEIGHT - floor_y) if spot and not tick else Rect2()
				if strict and reach.has_area() and not space.is_free(reach):
					continue
				var rect: Rect2 = _fit_row_label(space, view, item, bar_y, width, font)
				if not rect.has_area():
					continue
				lane = candidate
				item.label_rect = rect
				line = reach
				break
			if lane >= 0:
				break
		if lane < 0:
			item.label_hidden = not item.label.is_empty()
			for candidate: int in lanes:
				if not _overlaps(bars[candidate], span):
					lane = candidate
					break
			if lane < 0:
				lane = lanes[0]
		(bars[lane] as Array).append(span)
		if item.label_rect.has_area():
			space.add(item.label_rect)
		if line.has_area():
			space.add(line)
		var bar_top: float = lane_ys[lane]
		item.extra["lane"] = lane
		if spot:
			var top: float = bar_top - 3.0 if tick else floor_y
			item.screen = Rect2(x0, top, 0.0, bar_top + BAR_HEIGHT - top)
		else:
			item.screen = Rect2(x0, bar_top, item.screen.size.x, BAR_HEIGHT)
		if item.row != Row.CAMERA:
			deepest = maxi(deepest, lane)
	_lanes_bottom = lane_ys[deepest] + BAR_HEIGHT
	for item: Item in list:
		if item.kind == "limit":
			_fit_limit_label(space, view, item, font)


## The screen y of lane [param lane]'s bar under the floor at [param floor_y].
static func _lane_bar_y(floor_y: float, lane: int) -> float:
	return floor_y + ROW_TOP + lane * ROW_HEIGHT + FONT_SIZE - 1.0


## A free rectangle for a range's or spot's name sitting on its bar at [param bar_y], or an empty one.
## A range's name starts at its bar's on-screen start, or just past whatever is in the way, but
## never past the bar's end; a spot's goes right of its line, or left.
func _fit_row_label(space: LabelSpace, view: Rect2, item: Item, bar_y: float, width: float, font: Font) -> Rect2:
	var height: float = _label_height(font)
	var top: float = bar_y - height
	var candidates: Array[float] = []
	var x0: float = item.screen.position.x
	if item.kind == "spot":
		candidates.append(x0 + 2.0)
		candidates.append(x0 - 4.0 - width)
	else:
		var low: float = maxf(x0, view.position.x) + 2.0
		var high: float = minf(item.screen.end.x, view.end.x) - 2.0
		candidates.append(low)
		for hit: Rect2 in space.hits(Rect2(low, top, maxf(high - low, 0.0) + width + 2.0, height)):
			if hit.end.x + 1.0 > low and hit.end.x + 1.0 <= high:
				candidates.append(hit.end.x + 1.0)
		var last: float = view.end.x - width - 3.0
		if last > low and last <= high:
			candidates.append(last)
		candidates.sort()
	for x: float in candidates:
		var rect: Rect2 = Rect2(x, top, width + 2.0, height)
		if view.encloses(rect) and space.is_free(rect):
			return rect
	return Rect2()


## Places a limit's name on the first line down from its top, right of its line or left, where it
## overlaps nothing; a limit off screen is reported, not drawn.
func _fit_limit_label(space: LabelSpace, view: Rect2, item: Item, font: Font) -> void:
	var x: float = item.screen.position.x
	if x < view.position.x or x > view.end.x:
		item.extra["on_screen"] = false
		return
	item.label = item.name
	var width: float = _text_width(font, item.label)
	var height: float = _label_height(font)
	for line: int in maxi(1, floori((item.screen.size.y - height) / ROW_HEIGHT)):
		var top: float = item.screen.position.y + 2.0 + line * ROW_HEIGHT
		for left: float in [x + 2.0, x - 4.0 - width]:
			var rect: Rect2 = Rect2(left, top, width + 2.0, height)
			if view.encloses(rect) and space.is_free(rect):
				item.label_rect = rect
				space.add(rect)
				return
	item.label_hidden = true


## Names the hitbox shapes and render boxes that are drawn, each where it overlaps no protected
## control or text, no actor and no name already placed (the rule rows' and limits' first): a
## hitbox's above its box's top-left corner, else inside it, else under it; a render box's inside
## its top-left corner, else above it, else inside or under its bottom; then the same at the right
## corners (render boxes smallest first). One with no room is hidden.
func _place_box_labels(rules: Array[Item], render: Array[Item]) -> void:
	var font: Font = get_theme_default_font()
	var view: Rect2 = _view()
	var space: LabelSpace = LabelSpace.new()
	for rect: Rect2 in _blockers:
		space.add(rect)
	for item: Item in rules:
		if item.label_rect.has_area() and layers[item.category]:
			space.add(item.label_rect)
	if layers[HITBOXES]:
		for item: Item in rules:
			if item.kind == "shape" and item.active:
				item.label = "%s %s" % [item.name, _size_text(item.world.size)]
			elif item.kind == "rect":
				item.label = item.name
			else:
				continue
			_fit_box_label(space, view, item, font, true)
	if layers[RENDER]:
		# Smallest boxes first: a prop, a light or the sentry's beam has few places for its name; a
		# plate layer as wide as the room has many.
		var named: Array[Item] = []
		for item: Item in render:
			if item.active:
				named.append(item)
		named.sort_custom(func(a: Item, b: Item) -> bool: return a.screen.get_area() < b.screen.get_area())
		for item: Item in named:
			_fit_box_label(space, view, item, font, false)


## Finds a free place in [param space] (inside [param view]) for [param item]'s name: the four left
## corner spots (above or inside first, by [param outside_first]), then the right ones, then above an
## actor on it, then up to LEADER_STEPS lines up or down its left edge with a leader line. Sets
## label_rect and takes the place, or sets label_hidden when none is free. Does nothing for an item off
## the view.
func _fit_box_label(space: LabelSpace, view: Rect2, item: Item, font: Font, outside_first: bool) -> void:
	if not item.screen.intersects(view):
		return
	var width: float = _text_width(font, item.label) + 2.0
	var height: float = _label_height(font)
	var shown: Rect2 = item.screen.intersection(view)
	var above: Vector2 = Vector2(shown.position.x, shown.position.y - height - 1.0)
	var inside: Vector2 = shown.position + Vector2(1.0, 1.0)
	var inside_bottom: Vector2 = Vector2(shown.position.x + 1.0, shown.end.y - height - 1.0)
	var below: Vector2 = Vector2(shown.position.x, shown.end.y + 1.0)
	var right: float = shown.end.x - width
	var spots: Array[Vector2] = [above, inside, inside_bottom, below]
	if not outside_first:
		spots = [inside, above, inside_bottom, below]
	# Then the same four on the right-hand corners, then above any actor the box is on.
	spots.append_array([Vector2(right, above.y), Vector2(right - 1.0, inside.y), Vector2(right - 1.0, inside_bottom.y), Vector2(right, below.y)])
	for actor: Rect2 in _actor_rects:
		if actor.intersects(item.screen):
			spots.append(Vector2(shown.position.x, actor.position.y - height - 1.0))
			spots.append(Vector2(actor.position.x, actor.position.y - height - 1.0))
	for at: Vector2 in spots:
		var rect: Rect2 = Rect2(at, Vector2(width, height))
		if view.encloses(rect) and space.is_free(rect):
			item.label_rect = rect
			space.add(rect)
			return
	# Further up or down its left edge, joined to its corner by a leader line.
	for step: int in range(1, LEADER_STEPS + 1):
		for upward: bool in [true, false]:
			var y: float = above.y - step * (height + 1.0) if upward else below.y + step * (height + 1.0)
			var rect: Rect2 = Rect2(shown.position.x, y, width, height)
			if not view.encloses(rect) or not space.is_free(rect):
				continue
			var corner: float = shown.position.y if upward else shown.end.y
			var leader: Rect2 = Rect2(shown.position.x - 0.5, minf(rect.end.y, corner), 1.0, absf(corner - (rect.end.y if upward else rect.position.y)))
			item.label_rect = rect
			item.extra["leader"] = rect_array(leader)
			space.add(rect)
			return
	item.label_hidden = true


## A name's width at FONT_SIZE, measured once per name (the names repeat every frame).
func _text_width(font: Font, text: String) -> float:
	if text.is_empty():
		return 0.0
	if not _widths.has(text):
		_widths[text] = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x if font != null else 6.0 * text.length()
	return _widths[text]


## The height of one drawn name at FONT_SIZE (ascent and descent, plus 1 px), or FONT_SIZE + 1 with no font.
static func _label_height(font: Font) -> float:
	return (font.get_ascent(FONT_SIZE) + font.get_descent(FONT_SIZE) if font != null else float(FONT_SIZE)) + 1.0


## True when [param span] (from x, to y) overlaps any of [param spans]; touching ends do not count.
static func _overlaps(spans: Array, span: Vector2) -> bool:
	for other: Vector2 in spans:
		if span.x < other.y and other.x < span.y:
			return true
	return false


## [param rect] as [x, y, width, height], as the dump writes rectangles.
static func rect_array(rect: Rect2) -> Array[float]:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


## [param size] as whole pixels, "W×H".
static func _size_text(size: Vector2) -> String:
	return "%.0f×%.0f" % [size.x, size.y]


## [param rect] with [param cut] taken out: up to four rectangles around it.
static func rect_minus(rect: Rect2, cut: Rect2) -> Array[Rect2]:
	if not rect.intersects(cut):
		return [rect]
	var pieces: Array[Rect2] = []
	if cut.position.y > rect.position.y:
		pieces.append(Rect2(rect.position.x, rect.position.y, rect.size.x, cut.position.y - rect.position.y))
	if cut.end.y < rect.end.y:
		pieces.append(Rect2(rect.position.x, cut.end.y, rect.size.x, rect.end.y - cut.end.y))
	var top: float = maxf(rect.position.y, cut.position.y)
	var bottom: float = minf(rect.end.y, cut.end.y)
	if cut.position.x > rect.position.x:
		pieces.append(Rect2(rect.position.x, top, cut.position.x - rect.position.x, bottom - top))
	if cut.end.x < rect.end.x:
		pieces.append(Rect2(cut.end.x, top, rect.end.x - cut.end.x, bottom - top))
	return pieces


## [param rect] with every one of [param cuts] taken out.
## A rectangle with no area (a box thinner than an outline's side) gives no pieces.
static func clip(rect: Rect2, cuts: Array[Rect2]) -> Array[Rect2]:
	var pieces: Array[Rect2] = []
	if not rect.has_area():
		return pieces
	pieces.append(rect)
	for cut: Rect2 in cuts:
		if not cut.intersects(rect):
			continue
		var next: Array[Rect2] = []
		for piece: Rect2 in pieces:
			next.append_array(rect_minus(piece, cut))
		pieces = next
	return pieces


# --- Drawing ----------------------------------------------------------------------------------

## Draws every shown category's items, render boxes first, then zones, then hitboxes on top, from the last
## gathering.
func _draw() -> void:
	if game == null:
		return
	var font: Font = get_theme_default_font()
	var all: Array[Item] = items(false)
	# Render boxes first, then zones, then hitboxes on top.
	for category: StringName in [RENDER, ZONES, HITBOXES]:
		if not layers[category]:
			continue
		for item: Item in all:
			if item.category == category:
				_draw_item(item, font)


## Draws [param item] in its category's colour by its kind: range or ray, spot, limit, shape or rect, else
## a render box.
func _draw_item(item: Item, font: Font) -> void:
	var tint: Color = COLORS[item.category]
	match item.kind:
		"x_range", "ray":
			_draw_range(item, tint, font)
		"spot":
			_draw_spot(item, tint, font)
		"limit":
			_draw_limit(item, tint, font)
		"shape", "rect":
			_draw_box(item, tint, font)
		_:
			_draw_render_box(item, tint, font)


## A filled rectangle, cut around the protected controls and text unless [param whole].
func _fill(rect: Rect2, color: Color, whole: bool = false) -> void:
	if not rect.has_area():
		return
	if whole:
		draw_rect(rect, color)
		return
	for piece: Rect2 in clip(rect, _clear):
		if piece.has_area():
			draw_rect(piece, color)


## A rectangle's outline [param width] px wide, as four cut fills. A box no taller than the width is
## all top and bottom bar, so its sides are left out rather than given a negative height.
func _outline(rect: Rect2, color: Color, width: float, whole: bool = false) -> void:
	rect = rect.abs()
	var half: float = width * 0.5
	_fill(Rect2(rect.position.x - half, rect.position.y - half, rect.size.x + width, width), color, whole)
	_fill(Rect2(rect.position.x - half, rect.end.y - half, rect.size.x + width, width), color, whole)
	var side: float = rect.size.y - width
	if side <= 0.0:
		return
	_fill(Rect2(rect.position.x - half, rect.position.y + half, width, side), color, whole)
	_fill(Rect2(rect.end.x - half, rect.position.y + half, width, side), color, whole)


## A small marker, drawn only where it covers no protected control or text.
func _marker(points: PackedVector2Array, color: Color, outline: bool) -> void:
	var bounds: Rect2 = _points_rect(points, Vector2.ZERO, 1.0)
	for cut: Rect2 in _clear:
		if cut.intersects(bounds):
			return
	draw_colored_polygon(points, color)
	if outline:
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), SHADOW, 1.0)


## Draws a rule range (or a ray, with an arrow tip on its facing end) as a bar with end ticks in its
## lane, shading its screen_area above the floor when it has one; a live hitbox range in ARMED. Nothing
## for an item given no lane.
func _draw_range(item: Item, tint: Color, font: Font) -> void:
	if int(item.extra.get("lane", 0)) < 0:
		return
	var bar: Rect2 = item.screen
	var color: Color = ARMED if item.active and item.category == HITBOXES else tint
	var strength: float = 1.0 if item.active else IDLE_STRENGTH
	if item.extra.has("screen_area"):
		var area: Array = item.extra["screen_area"]
		var shade: Rect2 = Rect2(area[0], area[1], area[2], area[3])
		_fill(shade, Color(color, 0.22 if item.active else 0.07))
		_outline(shade, Color(color, 0.7 * strength), 1.0)
	_fill(bar.grow(1.0), SHADOW)
	_fill(bar, Color(color, 0.85 * strength))
	# End ticks show exactly where the range starts and stops.
	for x: float in [bar.position.x, bar.end.x]:
		_fill(Rect2(x - 1.5, bar.position.y - 3.0, 3.0, bar.size.y + 6.0), SHADOW)
		_fill(Rect2(x - 0.5, bar.position.y - 3.0, 1.0, bar.size.y + 6.0), Color(color, strength))
	if item.kind == "ray":
		var facing: float = float(item.extra.get("facing", 1.0))
		var tip: Vector2 = Vector2(bar.end.x if facing > 0.0 else bar.position.x, bar.get_center().y)
		_marker(PackedVector2Array([tip + Vector2(4.0 * facing, 0.0), tip + Vector2(-3.0 * facing, -4.0), tip + Vector2(-3.0 * facing, 4.0)]), Color(color, strength), false)
	_draw_label(item, Color(color, strength).lightened(0.25), font)


## Draws a spot as a tick down to its lane and, unless tick_only, a marker on top; white for the spot WOLF
## is heading for. Nothing for an item given no lane.
func _draw_spot(item: Item, tint: Color, font: Font) -> void:
	if int(item.extra.get("lane", 0)) < 0:
		return
	var at: Vector2 = item.screen.position
	var bottom: float = item.screen.end.y
	var color: Color = tint if not bool(item.extra.get("target", false)) else Color.WHITE
	_fill(Rect2(at.x - 1.5, at.y, 3.0, bottom - at.y), SHADOW)
	_fill(Rect2(at.x - 0.5, at.y, 1.0, bottom - at.y), color)
	if not bool(item.extra.get("tick_only", false)):
		_marker(PackedVector2Array([at, at + Vector2(-4.0, -6.0), at + Vector2(4.0, -6.0)]), color, true)
	_draw_label(item, color, font)


## Draws a limit as a dashed line from its top down to limit_bottom, with its name. Nothing while off screen.
func _draw_limit(item: Item, tint: Color, font: Font) -> void:
	if not bool(item.extra.get("on_screen", true)):
		return
	var top: Vector2 = item.screen.position
	var bottom: float = limit_bottom(item)
	_fill(Rect2(top.x - 1.5, top.y, 3.0, bottom - top.y), SHADOW)
	var y: float = top.y
	while y < bottom:
		_fill(Rect2(top.x - 0.5, y, 1.0, minf(5.0, bottom - y)), tint)
		y += 10.0
	_draw_label(item, tint, font)


## Where a limit's line ends on screen: down through the rule lanes, but no further than the first
## protected control or text under the floor at its x (the line would only be cut there anyway).
func limit_bottom(item: Item) -> float:
	var x: float = item.screen.position.x
	var floor_y: float = item.screen.end.y
	var bottom: float = maxf(floor_y, _lanes_bottom)
	for cut: Rect2 in _clear:
		if cut.position.y >= floor_y and x > cut.position.x - 2.0 and x < cut.end.x + 2.0:
			bottom = minf(bottom, cut.position.y)
	return maxf(bottom, floor_y)


## Draws a hitbox outline, filled in ARMED while armed or a live rule rect; a disabled shape is reported only.
func _draw_box(item: Item, tint: Color, font: Font) -> void:
	var color: Color = ARMED if item.active and (bool(item.extra.get("armed", false)) or item.kind == "rect") else tint
	if item.kind == "shape" and not item.active:
		# A disabled shape blocks nothing; it is reported, not drawn.
		return
	if bool(item.extra.get("armed", false)) or (item.kind == "rect" and item.active):
		_fill(item.screen, Color(color, 0.25))
	_outline(item.screen, SHADOW, 3.0)
	_outline(item.screen, color, 1.5)
	_draw_label(item, color, font)


## Draws a render box's outline and name; a protected control's box is drawn whole. Nothing for a box that is
## not active (hidden, covered, too faint per MIN_ALPHA, or off screen).
func _draw_render_box(item: Item, tint: Color, font: Font) -> void:
	if not item.active:
		return
	# A protected control's own box is its border: drawn whole.
	var whole: bool = bool(item.extra.get("keep_clear", false))
	_outline(item.screen, Color(SHADOW, 0.5), 2.0, whole)
	_outline(item.screen, Color(tint, 0.75), 1.0, whole)
	_draw_label(item, Color(tint, 0.95), font)


## The item's name where _layout or _place_box_labels put it, on a dark backing; nothing if it has
## no place.
func _draw_label(item: Item, color: Color, font: Font) -> void:
	if not item.label_rect.has_area() or font == null:
		return
	if item.extra.has("leader"):
		var leader: Array = item.extra["leader"]
		_fill(Rect2(leader[0], leader[1], leader[2], leader[3]), color)
	draw_rect(item.label_rect, LABEL_BACKING)
	var at: Vector2 = item.label_rect.position + Vector2(1.0, font.get_ascent(FONT_SIZE) + 0.5)
	draw_string_outline(font, at, item.label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, 2, SHADOW)
	draw_string(font, at, item.label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, color)
