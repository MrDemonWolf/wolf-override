class_name WorldInput
extends Node
## Routes unhandled mouse/touch gestures to shared Tappables or the floor. It owns only pointer intent;
## Main still performs USE and every authored refusal, and M0Actor still owns movement/collisions.

## Mouse pointer id is outside the nonnegative touch-id range; empty dictionaries mean no gesture.
const MOUSE_ID: int = -1
## A floor tap can drift this far (canvas px); a blocked walk is abandoned after this many seconds.
const TAP_SLOP: float = 12.0
const BLOCKED_SECONDS: float = 0.6

var game: Main
var targets: Array[Tappable] = []
var hovered: Tappable
var active: Dictionary = {}
var released: Dictionary = {}
var pending: Tappable
var pending_room: String = ""
var use_pressed: bool = false
var read_pressed: bool = false
var objective_pressed: bool = false
var _queued_use: bool = false
var _queued_read: bool = false
var _queued_objective: bool = false
var _last_x: float = 0.0
var _stalled: float = 0.0


## Observes paused trees too, so opening a debug/modal menu never leaves an invisible walk queued.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Pausing stops pointer intent even when Main's process/input callbacks stop.
func _process(_delta: float) -> void:
	if game != null and get_tree().paused:
		cancel()


## Adds a component with one art/label hit test; no puzzle state or movement changes here.
func add_target(id: StringName, chapters: PackedStringArray, regions: Array[CanvasItem], hold: StringName = &"") -> Tappable:
	var target: Tappable = Tappable.new()
	target.setup(id, chapters, regions, hold)
	add_child(target)
	targets.append(target)
	return target


## Watches releases before GUI handling, so a release over a button still stops a world crank.
## Activation happens only in handle_unhandled; an event consumed by GUI can never click through.
func observe(event: InputEvent) -> void:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventKey and event.pressed or event is InputEventJoypadButton and event.pressed or event is InputEventJoypadMotion and absf(event.axis_value) > InputMode.SWITCH_THRESHOLD:
		cancel()
	var id: int = MOUSE_ID if event is InputEventMouseButton else (event.index if event is InputEventScreenTouch else -2)
	if not active.is_empty() and id == active["id"] and not event.pressed:
		released = active
		active = {}
		if event is InputEventScreenTouch and event.canceled:
			released["cancelled"] = true
			if released["fired"]:
				game.crank_latched = false
				_queued_use = false
	var point: Vector2
	var motion_id: int
	if event is InputEventMouseMotion:
		point = event.position
		motion_id = MOUSE_ID
	elif event is InputEventScreenDrag:
		point = event.position
		motion_id = event.index
	else:
		return
	if not active.is_empty() and motion_id == active["id"]:
		var target: Tappable = active["target"]
		if target != null and is_inf(target.hit_score(point, motion_id != MOUSE_ID)) or target == null and point.distance_to(active["point"]) > TAP_SLOP:
			active["cancelled"] = true
			if active["fired"]:
				game.crank_latched = false
				_queued_use = false


## Takes a free-world pointer event after GUI. Objects beat the floor; release must stay on its target.
func handle_unhandled(event: InputEvent) -> bool:
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return false
	if event is InputEventMouseMotion:
		hovered = _hit(event.position, false) if _can_read() else null
		return false
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT or event is InputEventScreenTouch):
		return false
	var id: int = MOUSE_ID if event is InputEventMouseButton else event.index
	var point: Vector2 = event.position
	if not _can_read() or _blocked(point):
		return false
	if event.pressed:
		if not active.is_empty():
			return false
		var target: Tappable = _hit(point, id != MOUSE_ID)
		if target == null and event is InputEventScreenTouch and _can_walk() and game.touch_move_pad.begin(event):
			game.human.pointer_target_x = INF
			return true
		if target == null and (not _can_walk() or not _floor(point)):
			return false
		active = {"id": id, "target": target, "point": point, "cancelled": false, "fired": false, "hold": &""}
		# Keep the pressed canvas target stable through the crank's first-frame alignment lock.
		if target != null and target.kind == Tappable.Kind.USE:
			active["rect"] = Tappable.canvas_rect(game.context_hint)
		if target != null and _can_walk() and not String(game.call("_hold_station")).is_empty() and (target.kind == Tappable.Kind.USE or target.kind == Tappable.Kind.WORLD and _reached(target) and game.call("_hold_station") == target.hold_station):
			active["fired"] = true
			active["hold"] = game.call("_hold_station")
			_queued_use = true
		return true
	if released.is_empty() or released["id"] != id:
		return false
	var gesture: Dictionary = released
	released = {}
	if gesture["cancelled"] or gesture["fired"]:
		return true
	var target: Tappable = gesture["target"]
	if target != _hit(point, id != MOUSE_ID):
		return true
	if target != null and target.kind == Tappable.Kind.DIALOGUE:
		_queued_read = true
	elif target != null and target.kind == Tappable.Kind.OBJECTIVE:
		_queued_objective = true
	elif target != null and target.kind == Tappable.Kind.USE:
		_queued_use = true
	elif _can_walk():
		cancel_walk()
		if target != null and _reached(target):
			_queued_use = true
		elif target != null:
			pending = target
			pending_room = game.state.chapter_id
			_walk_to(target.approach.call() if target.approach.is_valid() else game.pointer_use_x(target.id))
		elif point.distance_to(gesture["point"]) <= TAP_SLOP and _floor(point):
			_walk_to((game.get_viewport().get_canvas_transform().affine_inverse() * point).x)
	return true


## Publishes one-frame actions before Main's process; watches actual movement so walls never keep a queue alive.
func advance(delta: float) -> void:
	use_pressed = _queued_use
	read_pressed = _queued_read
	objective_pressed = _queued_objective
	_queued_use = false
	_queued_read = false
	_queued_objective = false
	released = {}
	if not _can_read():
		cancel()
		return
	if not _can_walk():
		cancel_walk()
		if game.engineer_step_x < 0.0:
			active = {}
	elif Input.get_axis(&"move_left", &"move_right") != 0.0:
		cancel()
	elif pending != null:
		if pending_room != game.state.chapter_id or not _available(pending):
			cancel_walk()
		elif _reached(pending):
			use_pressed = pending.hold_station.is_empty() or game.call("_hold_station") != pending.hold_station
			cancel_walk()
		elif is_inf(game.human.pointer_target_x):
			cancel_walk()
	if not is_inf(game.human.pointer_target_x):
		_stalled = _stalled + delta if absf(game.human.position.x - _last_x) < 0.05 else 0.0
		_last_x = game.human.position.x
		if _stalled >= BLOCKED_SECONDS:
			cancel_walk()
	for target: Tappable in targets:
		target.feedback(target == hovered and game.input_mode.pointer_focus and _available(target), not active.is_empty() and active["target"] == target and not active["cancelled"], game.impact.reduce_motion)


## Resolves the same currently reachable station as physical USE, using the existing registry and gates.
## It never extends reach or performs an interaction; an owned crank survives its presentation lock.
func prompt_target() -> Tappable:
	for target: Tappable in targets:
		if target.kind == Tappable.Kind.WORLD and _available(target, true) and _reached(target):
			return target
	return null


## Drawn station labels are shared placement obstacles, including the separately owned COOLANT FAULT cue.
func prompt_obstacles() -> Array[Rect2]:
	var obstacles: Array[Rect2] = []
	for target: Tappable in targets:
		if target.kind != Tappable.Kind.WORLD:
			continue
		for item: CanvasItem in target.regions:
			if item is Label and item.is_visible_in_tree() and item.modulate.a >= 0.05 and item.self_modulate.a >= 0.05:
				obstacles.append(Tappable.canvas_rect(item))
	return obstacles


## Hides ordinary station-name glyphs during story reading. Self alpha preserves the room's edge fade;
## the fault tag has its own warning/fade owner. The plate's gauge stays visible only for active cranking.
func show_station_names(show: bool) -> void:
	if game == null:
		return
	game.bypass_handle.readout.visible = show or game.hold_use.holding
	var alpha: float = 1.0 if show else 0.0
	for target: Tappable in targets:
		if target.kind != Tappable.Kind.WORLD:
			continue
		for region: CanvasItem in target.regions:
			if region is Label and region != game.bypass_handle.fault_tag and not is_equal_approx(region.self_modulate.a, alpha):
				region.self_modulate.a = alpha


## True only while the same world crank's press is still held; slide-off and GUI releases stop it.
func holding(station: StringName) -> bool:
	return not active.is_empty() and not active["cancelled"] and active["fired"] and active["hold"] == station


## Drops only pointer navigation. Scripted engineer steps and WOLF's authored targets are untouched.
func cancel_walk() -> void:
	game.human.pointer_target_x = INF
	pending = null
	_stalled = 0.0


## Clears gestures and queued actions on pause, scene change or another device taking over.
func cancel() -> void:
	if game == null:
		return
	cancel_walk()
	if not active.is_empty() and active["fired"]:
		game.crank_latched = false
	active = {}
	released = {}
	hovered = null
	_queued_use = false
	_queued_read = false
	_queued_objective = false
	use_pressed = false
	read_pressed = false
	objective_pressed = false
	for target: Tappable in targets:
		target.feedback(false, false, true)


## Starts a finite, clamped pointer walk using the actor's existing player speed and collision path.
func _walk_to(x: float) -> void:
	game.human.pointer_target_x = clampf(x, game.human.min_x, minf(game.human.max_x, game.human.walk_max_x))
	_last_x = game.human.position.x
	_stalled = 0.0


## A target may narrow the existing dispatcher reach (the open doorway vs its bolt), never widen it.
func _reached(target: Tappable) -> bool:
	return game.interaction_target_at(game.human.position.x) == target.id and (not target.reached.is_valid() or target.reached.call())


## Dialogue/objective targets can be read without walking; world targets require live engineer control.
func _available(target: Tappable, for_prompt: bool = false) -> bool:
	# Presentation keeps an owned crank through its short alignment step; hit tests keep the normal lock.
	var controls: bool = _can_walk()
	if for_prompt and _can_read() and not game.call("_conversation_active") and not target.hold_station.is_empty():
		controls = controls or holding(target.hold_station)
	return (target.chapters.is_empty() or game.state.chapter_id in target.chapters) and (not target.enabled.is_valid() or target.enabled.call()) and (target.kind != Tappable.Kind.WORLD or controls)


## The nearest actual art/label hit wins before any expanded margin; HUD reading wins over world art.
func _hit(point: Vector2, touch: bool) -> Tappable:
	var best: Tappable
	var score: float = INF
	for target: Tappable in targets:
		if not _available(target):
			continue
		var value: float = target.hit_score(point, touch)
		if not is_inf(value) and (best == null or target.kind > best.kind or target.kind == best.kind and value < score):
			best = target
			score = value
	return best


## UI touch buttons also block native touch events, which can precede their emulated mouse events.
func _blocked(point: Vector2) -> bool:
	for control: Control in [game.pause_button, game.touch_left, game.touch_right, game.touch_use, game.touch_choice_1, game.touch_choice_2, game.debug_tools.debug_button, game.tutorial_prompt]:
		if control.is_visible_in_tree() and control.get_global_rect().has_point(point):
			return true
	return not game.screen_shape.safe_rect.has_point(point)


## Empty wall taps do nothing; only the painted floor is a walking target.
func _floor(point: Vector2) -> bool:
	return (game.get_viewport().get_canvas_transform().affine_inverse() * point).y >= RoomDepth.FLOOR_Y


## Menus, end cards and knockdowns own their input. No world gesture is carried through them.
func _can_read() -> bool:
	return not game.title_open and not game.get_tree().paused and not game.end_card_active and not game.fail_active


## Essential movement remains with the engineer and stops for every existing authored control lock.
func _can_walk() -> bool:
	return _can_read() and game.human.controlled
