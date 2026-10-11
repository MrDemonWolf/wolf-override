class_name DebugZones
extends Control
## The debug overlay's zones page, drawn over the game so a tester or a capture driver can see what
## the rules see: zones (every station's use range, the sentry's lane, sight and chase limits, WOLF's
## spots and follow gap, the camera and walk limits, the seal's and door's limits), hitboxes (every
## collision shape from its real shape, and the rule ranges that hurt or hit: the vent, the blast,
## the cloud, the sentry's contact, the tank's footprint and hit range) and render boxes (the on-screen
## rectangle of every sprite, prop, plate layer, label and UI panel, named, with its z-index and
## canvas layer). Each category has its own colour, a legend button and a key.
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
const COLORS: Dictionary = {ZONES: Color("#73DDF5"), HITBOXES: Color("#ff9a4a"), RENDER: Color("#d7f36b")}
## Filled over an armed hazard or a hit range that is live right now.
const ARMED: Color = Color("#ff4a3d")
const SHADOW: Color = Color(0.015, 0.025, 0.04, 0.9)
const MUTED: Color = Color("#9fc3d2")
const FONT_SIZE: int = 9
## The x-range rows, stacked under the floor line in screen pixels so ranges never draw over each other.
enum Row { USE, HURT, LANE, WOLF, CAMERA }
const ROW_TOP: float = 4.0
const ROW_HEIGHT: float = 11.0
const BAR_HEIGHT: float = 2.0
## Behind the rows, so their names read over the floor art and the dialogue card.
const ROW_BACKING: Color = Color(0.015, 0.025, 0.04, 0.82)
## A range that is not in force right now is drawn this strong.
const IDLE_STRENGTH: float = 0.7
## Limit lines run from this world height down to the floor; their names stagger over LIMIT_STAGGER rows.
const LIMIT_TOP_Y: float = 250.0
const LIMIT_STAGGER: int = 3
## Render boxes fainter than this (a faded label, a hidden card fading out) are reported, not drawn.
const MIN_ALPHA: float = 0.02
## The candidate sprites and controls are gathered again this often while shown; their rects every frame.
const REFRESH_SECONDS: float = 0.25
## The legend: between the top card (ends x 466) and the DEBUG button (from about x 768), above the
## title's brand line (y 106) and the answer row (y 88), so it covers no game control.
const LEGEND_RECT: Rect2 = Rect2(474.0, 10.0, 262.0, 58.0)
## The legend buttons keep the theme's button look with tighter padding, so all three fit.
const LEGEND_BUTTON_PADDING: Vector2 = Vector2(6.0, 2.0)
## Main's touch controls; the rows' backing leaves them uncovered.
const TOUCH_CONTROLS: Array[StringName] = [&"touch_left", &"touch_right", &"touch_use"]
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

	func to_dict() -> Dictionary:
		var data: Dictionary = {
			"category": str(category), "name": name, "kind": kind, "source": source, "path": path,
			"world_rect": DebugZones.rect_array(world), "screen_rect": DebugZones.rect_array(screen), "active": active,
		}
		data.merge(extra)
		return data


## Which categories are drawn; all of them are always reported.
var layers: Dictionary = {ZONES: true, HITBOXES: true, RENDER: true}
var game: Node2D
## Nodes left out of the render boxes (the debug tools' own).
var skip_root: Node
var legend: PanelContainer
var legend_buttons: Dictionary = {}
var _constants: Dictionary = {}
var _candidates: Array[CanvasItem] = []
var _refresh_left: float = 0.0
## The screen y under the last rule row, where the limit lines end.
var _rows_bottom: float = 0.0


func _init() -> void:
	name = "DebugZones"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	set_process(false)


func setup(main: Node2D, skip: Node) -> void:
	game = main
	skip_root = skip
	if main.get_script() != null:
		_constants = (main.get_script() as Script).get_script_constant_map()
	_build_legend()


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
	caption.text = "DRAW  F5 · F6 · F7"
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
		# A touch and mouse control: keyboard and controller focus stays on the game.
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


func toggle_layer(category: StringName) -> void:
	set_layer(not bool(layers.get(category, false)), category)


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
	all.append_array(render_items(not fresh))
	if not _title_open():
		var rules: Array[Item] = zone_items()
		rules.append_array(hitbox_items())
		_layout(rules)
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
		"legend": legend_data,
		"zones": zones,
		"hitboxes": hitboxes,
		"render_boxes": render,
	}


## The play camera: where it is, its zoom, the world it shows and the limits it is held to.
func camera_info() -> Dictionary:
	var camera: Camera2D = game.get(&"intro_camera") as Camera2D if game != null else null
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
	return get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_visible_rect()


## Where Main holds the play camera's centre (Main._update_gameplay_camera): half its view in from
## each end of the 960 px room.
func _camera_centre_limits() -> Vector2:
	var half_view: float = float(_const(&"GAMEPLAY_VIEW_WIDTH", 960.0)) * 0.5
	return Vector2(half_view, 960.0 - half_view)


func _title_open() -> bool:
	return game == null or bool(game.get(&"title_open"))


## A constant of Main's script, or [param fallback] when it has none.
func _const(key: StringName, fallback: Variant = null) -> Variant:
	if _constants.has(key):
		return _constants[key]
	if _constants.has(String(key)):
		return _constants[String(key)]
	return fallback


func _state() -> M0State:
	return game.get(&"state") as M0State


# --- Zones ------------------------------------------------------------------------------------

## The current room's zones: its stations' use ranges and the engineer's own spots, its limits, the
## sentry's lane in the junction, WOLF's spots, follow gap and the machines he rests clear of, and the
## camera's limits.
func zone_items() -> Array[Item]:
	var list: Array[Item] = []
	var state: M0State = _state()
	if state == null:
		return list
	var human: M0Actor = game.get(&"human") as M0Actor
	var wolf: M0Actor = game.get(&"wolf") as M0Actor
	match state.chapter_id:
		"lockdown":
			var stations: Array = _const(&"CORRIDOR_STATIONS", [])
			var relay_x: float = _const(&"RELAY_X", 0.0)
			var relay_reach: float = _const(&"RELAY_REACH", 0.0)
			var wheel: Vector2 = _const(&"BYPASS_WHEEL", Vector2.ZERO)
			var bypass_reach: float = _const(&"BYPASS_REACH", 0.0)
			list.append(_range(ZONES, "use: purge display", M0Actor.MIN_X, _const(&"PURGE_DISPLAY_MAX_X", 0.0), Row.USE, "M0Actor.MIN_X..PURGE_DISPLAY_MAX_X"))
			if stations.size() >= 3:
				list.append(_station(stations[0], "use: breaker", "CORRIDOR_STATIONS[0] (_at_breaker)"))
			list.append(_range(ZONES, "use: relay", relay_x - relay_reach, wheel.x - bypass_reach, Row.USE, "RELAY_X - RELAY_REACH .. BYPASS_WHEEL.x - BYPASS_REACH (_at_relay)"))
			list.append(_range(ZONES, "use: bypass", wheel.x - bypass_reach, wheel.x + bypass_reach, Row.USE, "BYPASS_WHEEL.x ± BYPASS_REACH (_at_bypass)"))
			if stations.size() >= 3:
				list.append(_station(stations[2], "use: safe point", "CORRIDOR_STATIONS[2]"))
			list.append(_spot(ZONES, "stand: relay", _const(&"RELAY_SIDE_X", 0.0), Row.USE, "RELAY_SIDE_X"))
			list.append(_spot(ZONES, "crank: bypass", _const(&"BYPASS_CRANK_X", 0.0), Row.USE, "BYPASS_CRANK_X"))
			list.append(_spot(ZONES, "step back", _const(&"RELAY_STEP_BACK_X", 0.0), Row.USE, "RELAY_STEP_BACK_X"))
			list.append(_spot(ZONES, "WOLF: relay contact", _const(&"RELAY_CONTACT_X", 0.0), Row.WOLF, "RELAY_CONTACT_X"))
			list.append(_spot(ZONES, "WOLF: off relay", _const(&"WOLF_BYPASS_CLEAR_X", 0.0), Row.WOLF, "WOLF_BYPASS_CLEAR_X"))
			if not state.door_open:
				list.append(_limit(ZONES, "seal face", _const(&"CORRIDOR_DOOR_LEFT_X", 0.0), "CORRIDOR_DOOR_LEFT_X", 0))
		"records":
			var stations: Array = _const(&"RECORDS_STATIONS", [])
			var names: Array[String] = ["use: purge queue", "use: mirror port", "use: exit"]
			for index: int in mini(stations.size(), names.size()):
				list.append(_station(stations[index], names[index], "RECORDS_STATIONS[%d]" % index))
			list.append(_spot(ZONES, "WOLF: mirror", _const(&"WOLF_MIRROR_X", 0.0), Row.WOLF, "WOLF_MIRROR_X"))
		"junction":
			list.append_array(_junction_zones(state))
	# Walk limits, WOLF's follow limit, his follow gap and the machines he rests clear of.
	list.append(_limit(ZONES, "walk limit", M0Actor.MIN_X, "M0Actor.MIN_X", 1))
	list.append(_limit(ZONES, "walk limit", M0Actor.MAX_X, "M0Actor.MAX_X", 1))
	if wolf != null:
		if wolf.follow_max_x < M0Actor.MAX_X:
			list.append(_limit(ZONES, "WOLF follow limit", wolf.follow_max_x, "door face - M0Actor.WOLF_REACH (Main._wolf_follow_max_x)", 2))
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
		var target: float = float(game.call(&"_debug_wolf_target")) if game.has_method(&"_debug_wolf_target") else wolf.autonomous_target_x
		if target >= 0.0:
			var why: String = str(game.call(&"_debug_wolf_why")) if game.has_method(&"_debug_wolf_why") else ""
			var heading: Item = _spot(ZONES, "WOLF → %s" % why, target, Row.WOLF, "Main._debug_wolf_target")
			heading.extra["why"] = why
			heading.extra["target"] = true
			list.append(heading)
	# The camera's centre is held between these; the marker is where it is now.
	var limits: Vector2 = _camera_centre_limits()
	list.append(_range(ZONES, "camera centre limits", limits.x, limits.y, Row.CAMERA, "GAMEPLAY_VIEW_WIDTH / 2 .. 960 - GAMEPLAY_VIEW_WIDTH / 2", false))
	var camera: Camera2D = game.get(&"intro_camera") as Camera2D
	if camera != null:
		list.append(_spot(ZONES, "camera x%.2f" % camera.zoom.x, camera.get_screen_center_position().x, Row.CAMERA, "IntroCamera screen centre"))
	return list


## The junction's stations, the engineer's crank spot, the sentry's lane (the alcove, the patrol,
## its sight, its chase limit and where it watches from), the question line, WOLF's spots and the
## door's face.
func _junction_zones(state: M0State) -> Array[Item]:
	var list: Array[Item] = []
	var stations: Array = _const(&"JUNCTION_STATIONS", [])
	if stations.size() >= 2:
		list.append(_station(stations[0], "use: overload breaker", "JUNCTION_STATIONS[0]"))
		list.append(_station(stations[1], "use: valve", "JUNCTION_STATIONS[1]"))
	list.append(_range(ZONES, "use: tank release", SentryBrain.COVER_MIN_X, SentryBrain.COVER_MAX_X, Row.USE, "SentryBrain.COVER_MIN_X..COVER_MAX_X (_at_arm_panel)"))
	list.append(_range(ZONES, "use: exit bolt", JunctionRoom.BOLT_REACH_MIN_X, M0Actor.MAX_X, Row.USE, "JunctionRoom.BOLT_REACH_MIN_X.. (_use_exit)"))
	list.append(_spot(ZONES, "crank: valve", _const(&"VALVE_CRANK_X", 0.0), Row.USE, "VALVE_CRANK_X"))
	list.append(_range(ZONES, "alcove (out of sight)", SentryBrain.COVER_MIN_X, SentryBrain.COVER_MAX_X, Row.LANE, "SentryBrain.COVER_MIN_X..COVER_MAX_X"))
	list.append(_range(ZONES, "patrol", SentryBrain.PATROL_MIN_X, SentryBrain.PATROL_MAX_X, Row.LANE, "SentryBrain.PATROL_MIN_X..PATROL_MAX_X", false))
	var brain: SentryBrain = game.get(&"sentry_brain") as SentryBrain
	if brain != null and brain.state != &"down":
		var awake: bool = brain.state != &"dormant"
		var tip: float = brain.x + brain.facing * SentryBrain.SIGHT_RANGE
		var sight: Item = _range(ZONES, "sight %.0f" % SentryBrain.SIGHT_RANGE, minf(brain.x, tip), maxf(brain.x, tip), Row.LANE, "sentry x + facing × SentryBrain.SIGHT_RANGE", awake)
		sight.kind = "ray"
		sight.extra["facing"] = brain.facing
		list.append(sight)
	list.append(_limit(ZONES, "lane entry (rubble)", SentryBrain.LANE_ENTRY_X, "SentryBrain.LANE_ENTRY_X", 0))
	list.append(_limit(ZONES, "chase limit", SentryBrain.CHASE_MIN_X, "SentryBrain.CHASE_MIN_X", 1))
	list.append(_limit(ZONES, "lane question", JunctionRoom.CHOICE_X, "JunctionRoom.CHOICE_X", 2))
	list.append(_spot(ZONES, "sentry watch", SentryBrain.WATCH_X, Row.LANE, "SentryBrain.WATCH_X"))
	list.append(_spot(ZONES, "WOLF: seam", JunctionRoom.WOLF_SEAM_X, Row.WOLF, "JunctionRoom.WOLF_SEAM_X"))
	list.append(_spot(ZONES, "WOLF: clear", JunctionRoom.WOLF_CLEAR_X, Row.WOLF, "JunctionRoom.WOLF_CLEAR_X"))
	list.append(_spot(ZONES, "WOLF: rubble", JunctionRoom.WOLF_RUBBLE_X, Row.WOLF, "JunctionRoom.WOLF_RUBBLE_X"))
	list.append(_spot(ZONES, "WOLF: bait", JunctionRoom.WOLF_BAIT_X, Row.WOLF, "JunctionRoom.WOLF_BAIT_X"))
	if not state.door_blown:
		list.append(_limit(ZONES, "door face", M0State.JUNCTION_DOOR_LEFT_X, "M0State.JUNCTION_DOOR_LEFT_X", 0))
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
	var line: PressureLine = game.get(&"pressure_line") as PressureLine
	var arm: DropArm = game.get(&"drop_arm") as DropArm
	var brain: SentryBrain = game.get(&"sentry_brain") as SentryBrain
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
	var room: JunctionRoom = game.get(&"junction_room") as JunctionRoom
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


# --- Render boxes -----------------------------------------------------------------------------

## The sprites, polygons, lines and drawing controls under Main, in draw-tree order, the debug
## tools' own left out.
func _gather_candidates() -> Array[CanvasItem]:
	var found: Array[CanvasItem] = []
	if game != null:
		_collect(game, found)
	return found


func _collect(node: Node, found: Array[CanvasItem]) -> void:
	if node == skip_root:
		return
	if node is CanvasItem and _draws_box(node as CanvasItem):
		found.append(node as CanvasItem)
	for child: Node in node.get_children():
		_collect(child, found)


static func _draws_box(item: CanvasItem) -> bool:
	if item is Sprite2D or item is AnimatedSprite2D or item is Polygon2D or item is Line2D:
		return true
	if item is Control:
		return not (item.get_class() in LAYOUT_ONLY)
	return false


## Each candidate's draw rectangle: in the world (or its canvas layer) and on screen, with its node
## path, class, effective z-index, canvas layer, visibility, alpha, draw order and whether one of
## Main's full-screen cards (the title, the END OF SLICE card) covers it. Covered, faded-out,
## hidden or off-screen boxes are reported, not drawn. [param for_draw] (the frame's drawing) leaves
## out hidden nodes and everything only the dump needs.
func render_items(for_draw: bool = false) -> Array[Item]:
	var list: Array[Item] = []
	var screen_rect: Rect2 = get_viewport().get_visible_rect() if is_inside_tree() else Rect2(0.0, 0.0, 960.0, 540.0)
	var covers: Array[CanvasItem] = _covers()
	var order: int = 0
	for item: CanvasItem in _candidates:
		if not is_instance_valid(item) or not item.is_inside_tree():
			continue
		if for_draw and not item.is_visible_in_tree():
			continue
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
		if for_draw:
			box.extra = {"z_index": absolute_z(item), "layer": layer}
			list.append(box)
			continue
		box.path = _path(item)
		box.extra = {
			"z_index": absolute_z(item),
			"layer": layer,
			"visible": shown,
			"alpha": alpha,
			"on_screen": box.screen.intersects(screen_rect),
			"covered": covered,
			"draw_order": order,
		}
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
	for property: StringName in [&"title_screen", &"end_card"]:
		var card: CanvasItem = game.get(property) as CanvasItem
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
## points widened by its width, a control's size.
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
	return Rect2()


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


func _skipped(node: Node) -> bool:
	return skip_root != null and (node == skip_root or skip_root.is_ancestor_of(node))


func _path(node: Node) -> String:
	return str(game.get_path_to(node)) if game != null and (node == game or game.is_ancestor_of(node)) else str(node.get_path())


# --- Item makers ------------------------------------------------------------------------------

## A rule range along x, drawn as a bar in [param row] under the floor; with [param height] it also
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


## A spot along x someone is sent to, marked on the floor and named in [param row].
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


## A limit along x (a door's face, the walk limit), drawn as a line from LIMIT_TOP_Y to the floor;
## [param stagger] moves its name down a line so neighbouring limits stay readable.
func _limit(category: StringName, label: String, x: float, source: String, stagger: int) -> Item:
	var item: Item = Item.new()
	item.category = category
	item.name = label
	item.kind = "limit"
	item.source = source
	item.world = _to_world(Rect2(x, LIMIT_TOP_Y, 0.0, RoomDepth.FLOOR_Y - LIMIT_TOP_Y))
	var top: Vector2 = _world_to_screen(Vector2(x, LIMIT_TOP_Y))
	var bottom: Vector2 = _world_to_screen(Vector2(x, RoomDepth.FLOOR_Y))
	item.screen = Rect2(top.x, top.y, 0.0, bottom.y - top.y)
	item.extra = {"x": x, "stagger": stagger % LIMIT_STAGGER}
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


func _canvas() -> Transform2D:
	return get_viewport().get_canvas_transform() if is_inside_tree() else Transform2D.IDENTITY


func _world_to_screen(point: Vector2) -> Vector2:
	var world: Vector2 = game.get_global_transform() * point if game != null else point
	return _canvas() * world


## Stacks the rule ranges and spots under the floor line: each row (USE, HURT, LANE, WOLF, CAMERA)
## takes as many lanes as it needs for nothing in it, names included, to overlap, and a row with
## nothing in it takes none. Sets each item's screen bar (a spot's runs from the floor to its lane).
func _layout(list: Array[Item]) -> void:
	var font: Font = get_theme_default_font()
	var floor_y: float = _world_to_screen(Vector2(0.0, RoomDepth.FLOOR_Y)).y
	var lanes: Dictionary = {}
	var placed: Array[Array] = []
	for item: Item in list:
		if item.row < 0:
			continue
		var start: float = item.screen.position.x
		var width: float = 0.0
		if not bool(item.extra.get("quiet", false)):
			width = font.get_string_size(item.name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x + 8.0 if font != null else 60.0
		var span: Vector2 = Vector2(start - 3.0, maxf(item.screen.end.x, start + width) + 3.0)
		var row_lanes: Array = lanes.get(item.row, [])
		var lane: int = 0
		while lane < row_lanes.size() and _overlaps(row_lanes[lane], span):
			lane += 1
		if lane == row_lanes.size():
			row_lanes.append([])
		(row_lanes[lane] as Array).append(span)
		lanes[item.row] = row_lanes
		placed.append([item, lane])
	var first_lane: Dictionary = {}
	var total: int = 0
	for row: int in Row.values():
		first_lane[row] = total
		total += (lanes.get(row, []) as Array).size()
	_rows_bottom = floor_y + ROW_TOP + total * ROW_HEIGHT
	for entry: Array in placed:
		var item: Item = entry[0]
		var lane: int = entry[1]
		var bar_y: float = floor_y + ROW_TOP + (int(first_lane[item.row]) + lane) * ROW_HEIGHT + FONT_SIZE - 1.0
		item.extra["lane"] = lane
		if item.kind == "spot":
			item.screen = Rect2(item.screen.position.x, floor_y, 0.0, bar_y + BAR_HEIGHT - floor_y)
		else:
			item.screen = Rect2(item.screen.position.x, bar_y, item.screen.size.x, BAR_HEIGHT)


static func _overlaps(spans: Array, span: Vector2) -> bool:
	for other: Vector2 in spans:
		if span.x < other.y and other.x < span.y:
			return true
	return false


static func rect_array(rect: Rect2) -> Array[float]:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


static func _size_text(size: Vector2) -> String:
	return "%.0f×%.0f" % [size.x, size.y]


# --- Drawing ----------------------------------------------------------------------------------

func _draw() -> void:
	if game == null:
		return
	var font: Font = get_theme_default_font()
	var all: Array[Item] = items(false)
	if (layers[ZONES] or layers[HITBOXES]) and not _title_open():
		var floor_y: float = _world_to_screen(Vector2(0.0, RoomDepth.FLOOR_Y)).y
		_draw_backing(Rect2(0.0, floor_y + 1.0, size.x, _rows_bottom - floor_y + 2.0))
	# Render boxes first, then zones, then hitboxes on top.
	for category: StringName in [RENDER, ZONES, HITBOXES]:
		if not layers[category]:
			continue
		for item: Item in all:
			if item.category == category:
				_draw_item(item, font)


## The rows' dark backing, cut around the touch arrows and USE so they stay in plain view.
func _draw_backing(band: Rect2) -> void:
	var cuts: Array[Rect2] = []
	for property: StringName in TOUCH_CONTROLS:
		var button: Control = game.get(property) as Control
		if button != null and button.is_visible_in_tree():
			var rect: Rect2 = button.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, button.size)
			if rect.intersects(band):
				cuts.append(rect)
	cuts.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
	var x: float = band.position.x
	for cut: Rect2 in cuts:
		if cut.position.x > x:
			draw_rect(Rect2(x, band.position.y, cut.position.x - x, band.size.y), ROW_BACKING)
		# Above and below the control, inside the band.
		if cut.position.y > band.position.y:
			draw_rect(Rect2(cut.position.x, band.position.y, cut.size.x, cut.position.y - band.position.y), ROW_BACKING)
		if cut.end.y < band.end.y:
			draw_rect(Rect2(cut.position.x, cut.end.y, cut.size.x, band.end.y - cut.end.y), ROW_BACKING)
		x = maxf(x, cut.end.x)
	if x < band.end.x:
		draw_rect(Rect2(x, band.position.y, band.end.x - x, band.size.y), ROW_BACKING)


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
			_draw_box(item, tint, font, "%s %s" % [item.name, _size_text(item.world.size)] if item.kind == "shape" else item.name)
		_:
			_draw_render_box(item, tint, font)


func _draw_range(item: Item, tint: Color, font: Font) -> void:
	var bar: Rect2 = item.screen
	var color: Color = ARMED if item.active and item.category == HITBOXES else tint
	var strength: float = 1.0 if item.active else IDLE_STRENGTH
	if item.extra.has("screen_area"):
		var area: Array = item.extra["screen_area"]
		var shade: Rect2 = Rect2(area[0], area[1], area[2], area[3])
		draw_rect(shade, Color(color, 0.22 if item.active else 0.07))
		draw_rect(shade, Color(color, 0.7 * strength), false, 1.0)
	draw_rect(bar.grow(1.0), SHADOW)
	draw_rect(bar, Color(color, 0.85 * strength))
	# End ticks show exactly where the range starts and stops.
	for x: float in [bar.position.x, bar.end.x]:
		draw_line(Vector2(x, bar.position.y - 3.0), Vector2(x, bar.end.y + 3.0), SHADOW, 3.0)
		draw_line(Vector2(x, bar.position.y - 3.0), Vector2(x, bar.end.y + 3.0), Color(color, strength), 1.0)
	if item.kind == "ray":
		var facing: float = float(item.extra.get("facing", 1.0))
		var tip: Vector2 = Vector2(bar.end.x if facing > 0.0 else bar.position.x, bar.get_center().y)
		draw_colored_polygon(PackedVector2Array([tip + Vector2(4.0 * facing, 0.0), tip + Vector2(-3.0 * facing, -4.0), tip + Vector2(-3.0 * facing, 4.0)]), Color(color, strength))
	if not bool(item.extra.get("quiet", false)):
		_label(font, Vector2(maxf(bar.position.x, 0.0) + 3.0, bar.position.y - 1.0), item.name, Color(color, strength).lightened(0.25))


func _draw_spot(item: Item, tint: Color, font: Font) -> void:
	var at: Vector2 = item.screen.position
	var bottom: float = item.screen.end.y
	var color: Color = tint if not bool(item.extra.get("target", false)) else Color.WHITE
	draw_line(at, Vector2(at.x, bottom), SHADOW, 3.0)
	draw_line(at, Vector2(at.x, bottom), color, 1.0)
	var marker: PackedVector2Array = PackedVector2Array([at, at + Vector2(-4.0, -6.0), at + Vector2(4.0, -6.0)])
	draw_colored_polygon(marker, color)
	draw_polyline(PackedVector2Array([marker[0], marker[1], marker[2], marker[0]]), SHADOW, 1.0)
	_label(font, Vector2(at.x + 3.0, bottom - 1.0), item.name, color)


func _draw_limit(item: Item, tint: Color, font: Font) -> void:
	var top: Vector2 = item.screen.position
	var bottom: Vector2 = Vector2(top.x, maxf(item.screen.end.y, _rows_bottom))
	draw_line(top, bottom, SHADOW, 3.0)
	draw_dashed_line(top, bottom, tint, 1.0, 5.0)
	var stagger: int = int(item.extra.get("stagger", 0))
	_label(font, Vector2(top.x + 3.0, top.y + 9.0 + stagger * 11.0), item.name, tint)


func _draw_box(item: Item, tint: Color, font: Font, label: String) -> void:
	var color: Color = ARMED if item.active and (bool(item.extra.get("armed", false)) or item.kind == "rect") else tint
	if item.kind == "shape" and not item.active:
		# A disabled shape blocks nothing; it is reported, not drawn.
		return
	if bool(item.extra.get("armed", false)) or (item.kind == "rect" and item.active):
		draw_rect(item.screen, Color(color, 0.25))
	draw_rect(item.screen, SHADOW, false, 3.0)
	draw_rect(item.screen, color, false, 1.5)
	_label(font, item.screen.position + Vector2(2.0, -2.0), label, color)


func _draw_render_box(item: Item, tint: Color, font: Font) -> void:
	if not item.active:
		return
	var box: Rect2 = item.screen
	draw_rect(box, Color(SHADOW, 0.5), false, 2.0)
	draw_rect(box, Color(tint, 0.75), false, 1.0)
	var layer: int = int(item.extra.get("layer", 0))
	var text: String = "%s z%d" % [item.name, int(item.extra.get("z_index", 0))] + (" L%d" % layer if layer != 0 else "")
	var view: Rect2 = get_viewport().get_visible_rect()
	var corner: Vector2 = box.intersection(view).position if box.intersects(view) else box.position
	_label(font, corner + Vector2(2.0, FONT_SIZE), text, Color(tint, 0.95))


func _label(font: Font, at: Vector2, text: String, color: Color) -> void:
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, 3, SHADOW)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, color)
