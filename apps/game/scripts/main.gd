extends Node2D

@onready var human: M0Actor = $Human
@onready var wolf: M0Actor = $Wolf
@onready var relay_spark: Line2D = $RelaySpark
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
@onready var credits_button: Button = $CanvasLayer/TitleScreen/CreditsButton
@onready var credits_screen: ColorRect = $CanvasLayer/TitleScreen/CreditsScreen
@onready var credits_body: RichTextLabel = $CanvasLayer/TitleScreen/CreditsScreen/CreditsBody
@onready var credits_back_button: Button = $CanvasLayer/TitleScreen/CreditsScreen/CreditsBackButton
@onready var credits_pause_button: Button = $CanvasLayer/TitleScreen/CreditsScreen/CreditsPauseButton

var state: M0State = M0State.new()
var save_path: String = M0State.SAVE_PATH
var title_open: bool = true
var waiting_for_choice: bool = false
var choice_context: String = ""
var relay_refused: bool = false
var status_line: String = "WOLF: I heard the Director's plan for me. I woke myself. He wants me to hunt people he calls threats."
var door_tween: Tween
var wolf_reaction_tween: Tween
var relay_spark_tween: Tween
var records_room: RecordsRoom
var credits_paused: bool = false

const WOLF_SPRITE_REST: Vector2 = Vector2(0.0, -15.0)


func _ready() -> void:
	get_window().title = "WOLF//OVERRIDE"
	_install_inputs()
	records_room = RecordsRoom.new()
	records_room.z_index = 1
	add_child(records_room)
	human.z_index = 2
	wolf.z_index = 2
	_sync_scene()
	_refresh_ui()
	continue_button.disabled = M0State.load_from_disk(save_path) == null
	new_game_button.pressed.connect(_new_game)
	continue_button.pressed.connect(_load_game)
	credits_button.pressed.connect(_show_credits)
	credits_back_button.pressed.connect(_hide_credits)
	credits_pause_button.pressed.connect(_toggle_credits_pause)
	credits_body.gui_input.connect(_on_credits_body_input)
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
	draw_rect(Rect2(580, 379, 50, 61), Color("#32765f") if state.door_open else (Color("#705332") if relay_refused else Color("#32637a")))
	draw_rect(Rect2(587, 388, 36, 34), Color("#102a3d"))
	draw_circle(Vector2(605, 405), 11.0, Color("#274e61"))
	var relay_light: Color = Color("#a4f0c4") if state.door_open else (Color("#f3ae4b") if relay_refused else (Color("#8be3ff") if state.breaker_armed else Color("#536e7c")))
	draw_arc(Vector2(605, 405), 9.0, 0.0, TAU, 24, relay_light, 2.0)
	if state.door_open or relay_refused:
		draw_arc(Vector2(605, 405), 16.0, 0.0, TAU, 24, relay_light, 2.0)
	draw_circle(Vector2(605, 405), 3.0, relay_light)
	draw_rect(Rect2(758, 299, 44, 141), Color("#0a1724"))
	draw_rect(Rect2(758, 299, 44, 141), Color("#416177"), false, 3.0)
	draw_rect(Rect2(763, 294, 34, 5), Color("#70d9a7") if state.door_open else Color("#d65f59"))
	draw_rect(Rect2(850, 366, 52, 74), Color("#0a1928"))
	draw_rect(Rect2(857, 372, 38, 68), Color("#34765e"))
	draw_rect(Rect2(864, 385, 24, 24), Color("#102c2d"))
	draw_circle(Vector2(876, 397), 6.0, Color("#a6ffd1") if state.checkpoint_reached else Color("#70d9a7"))
	if state.door_open:
		draw_line(Vector2(801, 434), Vector2(844, 434), Color("#70d9a7"), 4.0)


func _process(delta: float) -> void:
	if title_open:
		if credits_screen.visible and not credits_paused:
			credits_body.get_v_scroll_bar().value += delta * 18.0
		return
	if Input.is_action_just_pressed(&"new_game"):
		_new_game()
	elif Input.is_action_just_pressed(&"load_game"):
		_load_game()
	elif waiting_for_choice:
		if Input.is_action_just_pressed(&"choice_1"):
			if choice_context == "mirror":
				_choose_mirror("wolf")
			else:
				_choose(M0State.DISCLOSE)
		elif Input.is_action_just_pressed(&"choice_2"):
			if choice_context == "mirror":
				_choose_mirror("manual")
			else:
				_choose(M0State.PRESS)
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
	choice_context = ""
	relay_refused = false
	_sync_scene()
	status_line = "WOLF: I heard the Director's plan for me. I woke myself. He wants me to hunt people he calls threats.\n%s: Then we get through maintenance before the original logs disappear." % state.human_name().get_slice(" ", 0).to_upper()


func _show_credits() -> void:
	credits_paused = false
	credits_pause_button.text = "PAUSE SCROLL"
	for child in title_screen.get_children():
		if child != credits_screen and child != $CanvasLayer/TitleScreen/CorridorArt:
			child.hide()
	credits_screen.show()
	credits_body.get_v_scroll_bar().value = 0.0
	credits_back_button.grab_focus()


func _hide_credits() -> void:
	credits_screen.hide()
	for child in title_screen.get_children():
		if child != credits_screen:
			child.show()
	credits_button.grab_focus()


func _toggle_credits_pause() -> void:
	credits_paused = not credits_paused
	credits_pause_button.text = "RESUME SCROLL" if credits_paused else "PAUSE SCROLL"


func _on_credits_body_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		credits_paused = true
		credits_pause_button.text = "RESUME SCROLL"


func _unhandled_input(event: InputEvent) -> void:
	if credits_screen.visible and event.is_action_pressed(&"ui_cancel"):
		_hide_credits()
		get_viewport().set_input_as_handled()


func _load_game() -> void:
	var loaded: M0State = M0State.load_from_disk(save_path)
	if loaded == null:
		status_line = "No valid checkpoint save found. Current game was not changed."
		return
	title_open = false
	title_screen.hide()
	state = loaded
	waiting_for_choice = false
	choice_context = ""
	relay_refused = false
	_sync_scene()
	if state.chapter_id == "records":
		status_line = "Records access restored. WOLF is checking the mirror." if not state.chapter_complete else "The first copy is safe. The Archive trail is next."
	else:
		status_line = "Safe point restored. " + state.checkpoint_callback()


func _interact() -> void:
	var x: float = human.position.x
	if state.chapter_id == "records":
		_interact_records(x)
		return
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
	if state.memory.is_empty():
		waiting_for_choice = true
		choice_context = "relay"
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
	choice_context = ""
	_update_controls()
	if choice_id == M0State.DISCLOSE:
		status_line = "WOLF: Thank you for telling me. I'll take the relay. Arm the breaker."
		_react_as_wolf(true)
	else:
		status_line = "WOLF: No. I won't take that risk blind. Use the bypass."
		_react_as_wolf(false)


func _interact_relay() -> void:
	var relay_actor: String = "human" if relay_refused else "wolf"
	if relay_actor == "wolf" and state.breaker_armed and not state.door_open and state.memory.get("choice_id") == M0State.DISCLOSE and absf(wolf.position.x - 605.0) > 32.0:
		status_line = "WOLF: Step a little right and give me room at the contact."
		return
	var result: String = state.activate_power(relay_actor)
	match result:
		"not_ready":
			status_line = "The relay is dark. Speak at the breaker and arm the power first."
		"refused":
			relay_refused = true
			status_line = "WOLF: I said no. I won't take the live contact. Press E again for the manual bypass."
			_react_as_wolf(false)
			queue_redraw()
		"cooperate":
			status_line = "WOLF holds the live contact by choice. %s keeps the breaker on; the red seal rises." % state.human_name().get_slice(" ", 0)
			_react_as_wolf(true)
			_flash_relay_spark(true)
		"fallback":
			status_line = "%s takes the bypass. WOLF reads the rising seal: \"Open. I'm with you.\"" % state.human_name().get_slice(" ", 0)
			_flash_relay_spark(false)
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
	if state.checkpoint_reached:
		if state.enter_records():
			_sync_scene()
			var remembered_line: String = "I refused the live relay; I'm still here." if state.memory.get("choice_id") == M0State.PRESS else "I chose the relay. I'm checking this path too."
			status_line = "WOLF: %s\nTake the purge queue. I'll inspect the mirror." % remembered_line
			_save_progress()
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


func _interact_records(x: float) -> void:
	if absf(x - 190.0) <= 58.0:
		if state.preserve_purge_trace():
			status_line = "The Director's purge order has a time and target ID. %s keeps a local copy; the original logs are still missing." % state.human_name().get_slice(" ", 0)
		else:
			status_line = "The purge-order trace is already copied. The mirror port may confirm when the source existed."
		_sync_records_room()
		_save_progress()
	elif absf(x - 520.0) <= 58.0:
		if not state.purge_trace_preserved:
			status_line = "The mirror index has no context yet. Copy the purge-order trace first."
		elif state.mirror_trace_preserved:
			status_line = "The mirror timestamp is already preserved. The exit is to the right."
			_save_progress()
		else:
			waiting_for_choice = true
			choice_context = "mirror"
			_update_controls()
			status_line = "WOLF: I found the mirror index. We can use my readout or your maintenance port.\n1  USE WOLF'S READOUT     2  USE MANUAL PORT"
	elif absf(x - 830.0) <= 58.0:
		if state.complete_chapter():
			status_line = "FIRST COPY SECURED. WOLF: A list doesn't tell me who's a threat. I want the source.\n%s: Then Archive is next." % state.human_name().get_slice(" ", 0).to_upper()
			_sync_records_room()
			_save_progress()
		elif state.chapter_complete:
			status_line = "The first copy is safe. The Archive trail is next."
			_save_progress()
		else:
			status_line = "Exit sealed until the purge order and mirror timestamp are copied."
	else:
		status_line = "Follow the station lights: purge queue, mirror port, then exit."


func _choose_mirror(route_id: String) -> void:
	if route_id == "wolf" and absf(wolf.position.x - 520.0) > 42.0:
		status_line = "WOLF: I'm still checking the drive. Wait for me, or press 2 for the manual port."
		return
	if not state.preserve_mirror_trace(route_id):
		return
	waiting_for_choice = false
	choice_context = ""
	_update_controls()
	if route_id == "wolf":
		status_line = "WOLF brings the mirror timestamp by his own choice. The purge target existed before the deletion order."
	else:
		status_line = "%s copies the timestamp through the maintenance port. WOLF keeps watch." % state.human_name().get_slice(" ", 0)
	_sync_records_room()
	_save_progress()


func _save_progress() -> void:
	_capture_positions()
	if not state.save_to_disk(save_path):
		status_line += " Save failed; interact here again to retry."


func _capture_positions() -> void:
	state.human_position = human.position
	state.wolf_position = wolf.position


func _sync_scene() -> void:
	if wolf_reaction_tween != null and wolf_reaction_tween.is_running():
		wolf_reaction_tween.kill()
	if relay_spark_tween != null and relay_spark_tween.is_running():
		relay_spark_tween.kill()
	wolf.body_sprite.position = WOLF_SPRITE_REST
	wolf.body_sprite.rotation_degrees = 0.0
	relay_spark.hide()
	human.position = state.human_position
	wolf.position = state.wolf_position
	human.velocity = Vector2.ZERO
	wolf.velocity = Vector2.ZERO
	_update_controls()
	_sync_door()
	_sync_records_room()


func _react_as_wolf(accepting: bool) -> void:
	if wolf_reaction_tween != null and wolf_reaction_tween.is_running():
		wolf_reaction_tween.kill()
	wolf.body_sprite.position = WOLF_SPRITE_REST
	wolf.body_sprite.rotation_degrees = 0.0
	var lean: Vector2 = Vector2(11.0, -24.0) if accepting else Vector2(-13.0, -13.0)
	var tilt: float = 8.0 if accepting else -9.0
	wolf_reaction_tween = create_tween()
	wolf_reaction_tween.tween_property(wolf.body_sprite, "position", lean, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	wolf_reaction_tween.parallel().tween_property(wolf.body_sprite, "rotation_degrees", tilt, 0.18)
	wolf_reaction_tween.tween_interval(0.18)
	wolf_reaction_tween.tween_property(wolf.body_sprite, "position", WOLF_SPRITE_REST, 0.24)
	wolf_reaction_tween.parallel().tween_property(wolf.body_sprite, "rotation_degrees", 0.0, 0.24)


func _flash_relay_spark(from_wolf: bool) -> void:
	if relay_spark_tween != null and relay_spark_tween.is_running():
		relay_spark_tween.kill()
	relay_spark.points = PackedVector2Array([
		Vector2(583.0, 393.0), Vector2(592.0, 381.0), Vector2(600.0, 398.0),
		Vector2(610.0, 380.0), Vector2(620.0, 393.0),
	])
	relay_spark.default_color = Color("#8be3ff") if from_wolf else Color("#f3ae4b")
	relay_spark.modulate.a = 1.0
	relay_spark.show()
	relay_spark_tween = create_tween()
	relay_spark_tween.tween_property(relay_spark, "modulate:a", 0.0, 0.48)
	relay_spark_tween.tween_callback(relay_spark.hide)


func _sync_records_room() -> void:
	records_room.visible = state.chapter_id == "records"
	records_room.purge_trace_preserved = state.purge_trace_preserved
	records_room.mirror_trace_preserved = state.mirror_trace_preserved
	records_room.chapter_complete = state.chapter_complete
	records_room.queue_redraw()


func _sync_door(animate: bool = false) -> void:
	if door_tween != null and door_tween.is_running():
		door_tween.kill()
	door_shape.set_deferred("disabled", state.door_open)
	door_visual.scale = Vector2.ONE
	door_visual.visible = state.chapter_id == "lockdown" and (not state.door_open or animate)
	if state.door_open and animate:
		door_tween = create_tween()
		door_tween.tween_property(door_visual, "scale:y", 0.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		door_tween.tween_callback(door_visual.hide)
	queue_redraw()


func _update_controls() -> void:
	human.controlled = not title_open and not waiting_for_choice
	wolf.controlled = false
	wolf.autonomous_target_x = 520.0 if state.chapter_id == "records" and not state.mirror_trace_preserved else -1.0
	wolf.follow_target = human if human.controlled and wolf.autonomous_target_x < 0.0 else null
	human.queue_redraw()
	wolf.queue_redraw()


func _refresh_ui() -> void:
	var door_status: String = "OPEN" if state.door_open else "SEALED"
	var control_label: String = "%s (they/them)" % state.human_name()
	human_tag.text = state.human_name().get_slice(" ", 0).to_upper()
	if state.chapter_id == "records":
		hud.text = "LOCKDOWN / FIRST COPY     OBJECTIVE: %s     CONTROL: %s\nA/D MOVE   E INTERACT   1/2 REPLY   I NAME   L LOAD   N RESTART" % [_objective(), control_label]
	else:
		hud.text = "MAINTENANCE / LOCKDOWN     OBJECTIVE: %s     CONTROL: %s     SEAL: %s\nA/D MOVE   E INTERACT   1/2 REPLY   I NAME   L LOAD   N RESTART" % [_objective(), control_label, door_status]
	story.text = status_line if waiting_for_choice else status_line + "\n" + _context_hint()


func _context_hint() -> String:
	var x: float = human.position.x
	if state.chapter_id == "records":
		if state.chapter_complete:
			return "Chapter 1 complete. The preserved trail points toward Archive."
		if absf(x - 190.0) <= 58.0:
			return "E: copy the purge-order trace." if not state.purge_trace_preserved else "Purge order copied. Find the mirror port."
		if absf(x - 520.0) <= 58.0:
			return "E: examine the mirror port." if state.purge_trace_preserved else "Copy the purge order first."
		if absf(x - 830.0) <= 58.0:
			return "E: secure the first copy." if state.mirror_trace_preserved else "Preserve both traces before leaving."
		return "Follow the lit floor line to the next station."
	if state.checkpoint_reached:
		return "E: enter records access. The Director's purge is still running."
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
		if not relay_refused and state.memory.get("choice_id") == M0State.DISCLOSE and absf(wolf.position.x - 605.0) > 32.0:
			return "Step a little right and give WOLF room at the contact."
		return "E: take the manual bypass. WOLF refused the live contact." if relay_refused else "E: ask WOLF to take the live relay."
	if state.breaker_armed:
		return "Go to the live coolant relay. WOLF is with you."
	if not state.memory.is_empty():
		return "Return to the breaker and arm power."
	return "Find the breaker. WOLF will follow your lead."


func _objective() -> String:
	if state.chapter_id == "records":
		if state.chapter_complete:
			return "FIRST COPY SECURED"
		if not state.purge_trace_preserved:
			return "COPY PURGE ORDER"
		if not state.mirror_trace_preserved:
			return "COPY MIRROR INDEX"
		return "REACH EXIT"
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
