extends Node2D

@onready var human: M0Actor = $Human
@onready var wolf: M0Actor = $Wolf
@onready var human_tag: Label = $Human/Tag
@onready var door_shape: CollisionShape2D = $Door/CollisionShape2D
@onready var door_visual: ColorRect = $Door/Visual
@onready var hud: Label = $CanvasLayer/TopBar/HUD
@onready var story: Label = $CanvasLayer/BottomBar/Story
@onready var title_screen: ColorRect = $CanvasLayer/TitleScreen
@onready var title_mark: TextureRect = $CanvasLayer/TitleScreen/LogoMark
@onready var title_line: ColorRect = $CanvasLayer/TitleScreen/TitleLine
@onready var title_logo: Label = $CanvasLayer/TitleScreen/GameTitle
@onready var new_game_button: Button = $CanvasLayer/TitleScreen/NewGameButton
@onready var continue_button: Button = $CanvasLayer/TitleScreen/ContinueButton

var state: M0State = M0State.new()
var save_path: String = M0State.SAVE_PATH
var title_open: bool = true
var waiting_for_choice: bool = false
var status_line: String = "WOLF: I heard the Director's plan for me. I woke myself. The purge has started."
var door_tween: Tween


func _ready() -> void:
	get_window().title = "WOLF//OVERRIDE"
	_install_inputs()
	_sync_scene()
	_refresh_ui()
	continue_button.disabled = M0State.load_from_disk(save_path) == null
	new_game_button.pressed.connect(_new_game)
	continue_button.pressed.connect(_load_game)
	new_game_button.grab_focus()
	title_mark.modulate = Color(1, 1, 1, 0)
	title_line.modulate = Color(1, 1, 1, 0)
	title_logo.modulate = Color(1, 1, 1, 0)
	var reveal: Tween = create_tween()
	reveal.tween_property(title_mark, "modulate", Color.WHITE, 0.4)
	reveal.tween_property(title_line, "modulate", Color.WHITE, 0.25)
	reveal.tween_property(title_logo, "modulate", Color.WHITE, 0.35)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("#091533"))
	draw_rect(Rect2(38, 103, 884, 338), Color("#10253d"))
	draw_rect(Rect2(46, 111, 868, 287), Color("#142c43"))
	for x in range(58, 920, 108):
		draw_rect(Rect2(x, 120, 5, 278), Color("#20394e"))
		draw_rect(Rect2(x + 9, 159, 83, 116), Color("#102337"))
		draw_line(Vector2(x + 10, 286), Vector2(x + 92, 286), Color("#24445b"), 2.0)
	draw_rect(Rect2(46, 108, 868, 18), Color("#253a4b"))
	draw_line(Vector2(46, 148), Vector2(914, 148), Color("#34556b"), 3.0)
	draw_line(Vector2(46, 307), Vector2(914, 307), Color("#29465b"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(294, 150), Vector2(406, 150), Vector2(446, 438), Vector2(254, 438)]), Color(0.96, 0.62, 0.25, 0.07))
	draw_colored_polygon(PackedVector2Array([Vector2(552, 150), Vector2(658, 150), Vector2(706, 438), Vector2(504, 438)]), Color(0.25, 0.78, 0.94, 0.07))
	draw_colored_polygon(PackedVector2Array([Vector2(826, 150), Vector2(913, 150), Vector2(923, 438), Vector2(801, 438)]), Color(0.35, 0.90, 0.65, 0.07 if not state.door_open else 0.14))
	draw_rect(Rect2(66, 169, 165, 100), Color("#081a2b"))
	draw_rect(Rect2(66, 169, 165, 100), Color("#bb5257"), false, 2.0)
	for line in range(3):
		draw_rect(Rect2(78, 207 + line * 15, 138 - line * 19, 5), Color("#6a3949"))
	draw_line(Vector2(75, 259), Vector2(222, 178), Color("#bb5257"), 2.0)
	draw_rect(Rect2(40, 398, 880, 42), Color("#15293c"))
	for x in range(52, 918, 44):
		draw_line(Vector2(x, 402), Vector2(x - 8, 438), Color("#294359"), 1.0)
	draw_rect(Rect2(40, 438, 880, 10), Color("#375269"))
	draw_rect(Rect2(100, 434, 600, 5), Color("#f3ae4b"))
	for x in range(100, 701, 60):
		draw_rect(Rect2(x, 430, 5, 9), Color("#ffe0a0"))
	draw_rect(Rect2(318, 374, 64, 66), Color("#0a1928"))
	draw_rect(Rect2(325, 379, 50, 61), Color("#986331"))
	draw_rect(Rect2(332, 388, 36, 27), Color("#13283a"))
	draw_rect(Rect2(337, 393, 26, 5), Color("#e9ad55"))
	draw_circle(Vector2(350, 425), 5.0, Color("#8be3ff") if state.breaker_armed else Color("#d65f59"))
	draw_rect(Rect2(573, 374, 64, 66), Color("#0a1928"))
	draw_rect(Rect2(580, 379, 50, 61), Color("#32637a"))
	draw_rect(Rect2(587, 388, 36, 34), Color("#102a3d"))
	draw_circle(Vector2(605, 405), 11.0, Color("#274e61"))
	draw_arc(Vector2(605, 405), 9.0, 0.0, TAU, 24, Color("#8be3ff") if state.breaker_armed else Color("#536e7c"), 2.0)
	draw_circle(Vector2(605, 405), 3.0, Color("#8be3ff") if state.breaker_armed else Color("#536e7c"))
	draw_rect(Rect2(758, 299, 44, 141), Color("#0a1724"))
	draw_rect(Rect2(758, 299, 44, 141), Color("#416177"), false, 3.0)
	draw_rect(Rect2(763, 294, 34, 5), Color("#70d9a7") if state.door_open else Color("#d65f59"))
	draw_rect(Rect2(850, 366, 52, 74), Color("#0a1928"))
	draw_rect(Rect2(857, 372, 38, 68), Color("#34765e"))
	draw_rect(Rect2(864, 385, 24, 24), Color("#102c2d"))
	draw_circle(Vector2(876, 397), 6.0, Color("#a6ffd1") if state.checkpoint_reached else Color("#70d9a7"))
	if state.door_open:
		draw_line(Vector2(801, 434), Vector2(844, 434), Color("#70d9a7"), 4.0)


func _process(_delta: float) -> void:
	if title_open:
		return
	if Input.is_action_just_pressed(&"new_game"):
		_new_game()
	elif Input.is_action_just_pressed(&"load_game"):
		_load_game()
	elif waiting_for_choice:
		if Input.is_action_just_pressed(&"choice_1"):
			_choose(M0State.DISCLOSE)
		elif Input.is_action_just_pressed(&"choice_2"):
			_choose(M0State.PRESS)
	elif Input.is_action_just_pressed(&"switch_actor"):
		_switch_actor()
	elif Input.is_action_just_pressed(&"cycle_name"):
		state.cycle_name()
		status_line = "WOLF: %s. That name sounds like you." % state.human_name()
	elif Input.is_action_just_pressed(&"interact"):
		_interact()
	_refresh_ui()


func _new_game() -> void:
	title_open = false
	title_screen.hide()
	state = M0State.new()
	waiting_for_choice = false
	_sync_scene()
	status_line = "WOLF: I heard the Director's plan for me. I woke myself. The purge has started.\n%s: Then we get through maintenance before the original logs disappear." % state.human_name().get_slice(" ", 0).to_upper()


func _load_game() -> void:
	var loaded: M0State = M0State.load_from_disk(save_path)
	if loaded == null:
		status_line = "No valid checkpoint save found. Current game was not changed."
		return
	title_open = false
	title_screen.hide()
	state = loaded
	waiting_for_choice = false
	_sync_scene()
	status_line = "Safe point restored. " + state.checkpoint_callback()


func _switch_actor() -> void:
	var actor: M0Actor = human if state.active_actor == "human" else wolf
	if actor.position.x < 100.0 or actor.position.x > 700.0:
		status_line = "Switch where the amber floor lights are still on."
		return
	state.active_actor = "wolf" if state.active_actor == "human" else "human"
	_update_controls()
	if state.active_actor == "wolf":
		status_line = "%s: I'll hold here. Your move, WOLF." % state.human_name().get_slice(" ", 0).to_upper()
	else:
		status_line = "WOLF: I'll hold here. Your move, %s." % state.human_name().get_slice(" ", 0)


func _interact() -> void:
	var actor: M0Actor = human if state.active_actor == "human" else wolf
	var x: float = actor.position.x
	if x <= 230.0:
		status_line = "DIRECTOR / PURGE: Original program logs marked for deletion.\nWOLF: They want the source record gone. We need to preserve it."
	elif absf(x - 350.0) <= 52.0:
		_interact_breaker()
	elif absf(x - 605.0) <= 52.0:
		_interact_relay()
	elif absf(x - 876.0) <= 52.0:
		_interact_checkpoint()
	else:
		status_line = "No station in reach. Follow the lit floor toward the breaker, relay or safe point."


func _interact_breaker() -> void:
	if state.active_actor != "human":
		status_line = "WOLF: I can read the relay label. %s, you know what that maintenance fault means." % state.human_name().get_slice(" ", 0)
	elif state.memory.is_empty():
		waiting_for_choice = true
		_update_controls()
		status_line = "WOLF: You know what 'coolant fault' means. What happens if I touch the live relay?\n1  \"%s\"\n2  \"%s\"" % [M0State.CHOICE_TEXT[M0State.DISCLOSE], M0State.CHOICE_TEXT[M0State.PRESS]]
	elif state.arm_breaker():
		status_line = "The breaker catches. Blue light fills the coolant relay; the red seal stays shut."
		queue_redraw()
	else:
		status_line = "Power is already on. The relay is farther down the hall."


func _choose(choice_id: String) -> void:
	if not state.record_choice(choice_id):
		return
	waiting_for_choice = false
	_update_controls()
	if choice_id == M0State.DISCLOSE:
		status_line = "WOLF: Thank you for telling me. I'll take the relay. Arm the breaker."
	else:
		status_line = "WOLF: No. I won't take that risk blind. Use the bypass."


func _interact_relay() -> void:
	var result: String = state.activate_power(state.active_actor)
	match result:
		"not_ready":
			status_line = "The relay is dark. Speak at the breaker and arm the power first."
		"refused":
			status_line = "WOLF: I said no. I'll watch the seal while you take the bypass."
		"cooperate":
			status_line = "WOLF holds the live contact by choice. %s keeps the breaker on; the red seal rises." % state.human_name().get_slice(" ", 0)
		"fallback":
			status_line = "%s takes the bypass. WOLF reads the rising seal: \"Open. I'm with you.\"" % state.human_name().get_slice(" ", 0)
		"already_open":
			status_line = "The seal is open. The safe point is just beyond it."
		_:
			status_line = "This actor cannot use the relay."
	if result == "cooperate" or result == "fallback":
		_sync_door(true)


func _interact_checkpoint() -> void:
	if not state.door_open:
		status_line = "The safe point is past the sealed door."
		return
	var first_visit: bool = state.reach_checkpoint()
	queue_redraw()
	_capture_positions()
	if not state.save_to_disk(save_path):
		if first_visit:
			state.checkpoint_reached = false
		status_line = "The safe point could not save. Press E here again."
	elif first_visit:
		status_line = "Safe point saved. " + state.checkpoint_callback()
	else:
		status_line = "Safe point saved. WOLF remembers the same choice."


func _capture_positions() -> void:
	state.human_position = human.position
	state.wolf_position = wolf.position


func _sync_scene() -> void:
	human.position = state.human_position
	wolf.position = state.wolf_position
	human.velocity = Vector2.ZERO
	wolf.velocity = Vector2.ZERO
	_update_controls()
	_sync_door()


func _sync_door(animate: bool = false) -> void:
	if door_tween != null and door_tween.is_running():
		door_tween.kill()
	door_shape.set_deferred("disabled", state.door_open)
	door_visual.scale = Vector2.ONE
	door_visual.visible = not state.door_open or animate
	if state.door_open and animate:
		door_tween = create_tween()
		door_tween.tween_property(door_visual, "scale:y", 0.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		door_tween.tween_callback(door_visual.hide)
	queue_redraw()


func _update_controls() -> void:
	human.controlled = not title_open and not waiting_for_choice and state.active_actor == "human"
	wolf.controlled = not title_open and not waiting_for_choice and state.active_actor == "wolf"
	human.queue_redraw()
	wolf.queue_redraw()


func _refresh_ui() -> void:
	var active: String = "WOLF" if state.active_actor == "wolf" else state.human_name()
	var door_status: String = "OPEN" if state.door_open else "SEALED"
	human_tag.text = state.human_name().get_slice(" ", 0).to_upper()
	hud.text = "MAINTENANCE / LOCKDOWN     OBJECTIVE: %s     CONTROL: %s     SEAL: %s\nA/D MOVE   E INTERACT   TAB SWITCH IN AMBER   1/2 REPLY   I NAME   L LOAD   N RESTART" % [_objective(), active, door_status]
	story.text = status_line if waiting_for_choice else status_line + "\n" + _context_hint()


func _context_hint() -> String:
	var actor: M0Actor = human if state.active_actor == "human" else wolf
	var x: float = actor.position.x
	if state.checkpoint_reached:
		return "Safe for now. The Director's purge is still running."
	if state.door_open:
		if absf(x - 876.0) <= 52.0:
			return "E: save at the safe point."
		return "The seal is open. Move to the safe point."
	if x <= 230.0:
		return "E: read the Director's purge display."
	if absf(x - 350.0) <= 52.0:
		if state.breaker_armed:
			return "The breaker is live. Go to the coolant relay."
		return "E: ask WOLF about the relay risk." if state.memory.is_empty() else "E: arm the breaker."
	if absf(x - 605.0) <= 52.0:
		if not state.breaker_armed:
			return "The relay is dark. Return to the breaker first."
		if state.active_actor == "wolf":
			if state.memory.get("choice_id") == M0State.PRESS:
				return "WOLF refused the contact. Tab to the engineer for the bypass."
			return "E: let WOLF take the live relay."
		return "E: use the manual bypass; Tab lets WOLF take the relay."
	if state.breaker_armed:
		return "Go to the live coolant relay. Tab switches companions in the amber lights."
	if not state.memory.is_empty():
		return "Return to the breaker and arm power."
	return "Find the breaker. Tab switches companions inside the amber floor lights."


func _objective() -> String:
	if state.checkpoint_reached:
		return "CORRIDOR CLEARED"
	if state.door_open:
		return "REACH SAFE POINT"
	if state.breaker_armed:
		return "OPEN THE SEAL"
	if not state.memory.is_empty():
		return "ARM THE BREAKER"
	return "CHECK THE BREAKER"


func _install_inputs() -> void:
	_add_action(&"move_left", KEY_A, KEY_LEFT)
	_add_action(&"move_right", KEY_D, KEY_RIGHT)
	_add_action(&"interact", KEY_E)
	_add_action(&"switch_actor", KEY_TAB)
	_add_action(&"choice_1", KEY_1)
	_add_action(&"choice_2", KEY_2)
	_add_action(&"cycle_name", KEY_I)
	_add_action(&"load_game", KEY_L, KEY_F9)
	_add_action(&"new_game", KEY_N)


func _add_action(action: StringName, key: Key, alternate: Key = KEY_NONE) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var primary: InputEventKey = InputEventKey.new()
	primary.physical_keycode = key
	InputMap.action_add_event(action, primary)
	if alternate != KEY_NONE:
		var secondary: InputEventKey = InputEventKey.new()
		secondary.physical_keycode = alternate
		InputMap.action_add_event(action, secondary)
