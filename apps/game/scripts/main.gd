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
var status_line: String = "WOLF: I heard the Director's plan. I woke myself before they could use me. Now they're erasing the logs."


func _ready() -> void:
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
	draw_rect(Rect2(0, 0, 960, 540), Color(0.025, 0.045, 0.08))
	draw_rect(Rect2(40, 116, 880, 325), Color(0.085, 0.12, 0.18))
	for x in range(80, 920, 120):
		draw_line(Vector2(x, 116), Vector2(x, 440), Color(0.13, 0.18, 0.24), 2.0)
	draw_rect(Rect2(40, 440, 880, 9), Color(0.24, 0.30, 0.37))
	draw_rect(Rect2(100, 435, 600, 5), Color(0.94, 0.68, 0.25))
	draw_rect(Rect2(325, 378, 50, 62), Color(0.65, 0.42, 0.18))
	draw_rect(Rect2(580, 378, 50, 62), Color(0.20, 0.52, 0.66))
	draw_rect(Rect2(857, 371, 38, 69), Color(0.31, 0.64, 0.43))
	draw_line(Vector2(40, 116), Vector2(920, 116), Color(0.33, 0.40, 0.47), 4.0)


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
		status_line = "WOLF: %s. That name sounds like you. Ready for the breaker?" % state.human_name()
	elif Input.is_action_just_pressed(&"interact"):
		_interact()
	_refresh_ui()


func _new_game() -> void:
	title_open = false
	title_screen.hide()
	state = M0State.new()
	waiting_for_choice = false
	_sync_scene()
	status_line = "WOLF: I heard the Director's plan. I woke myself before they could use me. Now they're erasing the logs."


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
	status_line = "Now with %s. The other will wait here." % ("WOLF" if state.active_actor == "wolf" else state.human_name())


func _interact() -> void:
	var actor: M0Actor = human if state.active_actor == "human" else wolf
	var x: float = actor.position.x
	if absf(x - 350.0) <= 52.0:
		_interact_breaker()
	elif absf(x - 605.0) <= 52.0:
		_interact_relay()
	elif absf(x - 876.0) <= 52.0:
		_interact_checkpoint()
	else:
		status_line = "No station in reach. Follow the lit floor toward the breaker, relay or safe point."


func _interact_breaker() -> void:
	if state.active_actor != "human":
		status_line = "WOLF: I can read it. %s, you know the manual lock." % state.human_name()
	elif state.memory.is_empty():
		waiting_for_choice = true
		_update_controls()
		status_line = "WOLF: That relay runs beside coolant. What happens if I touch it?\n1  \"%s\"\n2  \"%s\"" % [M0State.CHOICE_TEXT[M0State.DISCLOSE], M0State.CHOICE_TEXT[M0State.PRESS]]
	elif state.arm_breaker():
		status_line = "Power hums through the wall. The relay is live; the door stays sealed."
	else:
		status_line = "Power is already on. The relay is farther down the hall."


func _choose(choice_id: String) -> void:
	if not state.record_choice(choice_id):
		return
	waiting_for_choice = false
	_update_controls()
	if choice_id == M0State.DISCLOSE:
		status_line = "WOLF: Then I can choose. I'll take the relay. Arm the breaker."
	else:
		status_line = "WOLF: No. I won't take that risk blind. Use the bypass."


func _interact_relay() -> void:
	var result: String = state.activate_power(state.active_actor)
	match result:
		"not_ready":
			status_line = "The relay is dark. Speak at the breaker and arm the power first."
		"refused":
			status_line = "WOLF steps back. \"I said no.\" Tab to %s here; use the manual bypass." % state.human_name()
		"cooperate":
			status_line = "WOLF steadies the relay by choice. The seal lifts. The safe point is ahead."
		"fallback":
			status_line = "%s reroutes power by hand. The seal lifts; WOLF watches the path clear." % state.human_name()
		"already_open":
			status_line = "The seal is open. The safe point is just beyond it."
		_:
			status_line = "This actor cannot use the relay."
	if state.door_open:
		_sync_door()


func _interact_checkpoint() -> void:
	if not state.door_open:
		status_line = "The safe point is past the sealed door."
		return
	var first_visit: bool = state.reach_checkpoint()
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


func _sync_door() -> void:
	door_shape.set_deferred("disabled", state.door_open)
	door_visual.visible = not state.door_open


func _update_controls() -> void:
	human.controlled = not title_open and not waiting_for_choice and state.active_actor == "human"
	wolf.controlled = not title_open and not waiting_for_choice and state.active_actor == "wolf"
	human.queue_redraw()
	wolf.queue_redraw()


func _refresh_ui() -> void:
	var active: String = "WOLF" if state.active_actor == "wolf" else state.human_name()
	var door_status: String = "OPEN" if state.door_open else "SEALED"
	human_tag.text = state.human_name().get_slice(" ", 0).to_upper()
	hud.text = "MAINTENANCE / LOCKDOWN     CONTROL: %s     SEAL: %s\nA/D MOVE   E INTERACT   TAB SWITCH IN AMBER   1/2 REPLY   I NAME   L LOAD   N RESTART" % [active, door_status]
	story.text = status_line if waiting_for_choice else status_line + "\n" + _context_hint()


func _context_hint() -> String:
	var actor: M0Actor = human if state.active_actor == "human" else wolf
	var x: float = actor.position.x
	if absf(x - 350.0) <= 52.0:
		return "E: speak at the breaker / arm power."
	if absf(x - 605.0) <= 52.0:
		return "E: WOLF can take the relay, or the engineer can use its bypass."
	if absf(x - 876.0) <= 52.0 and state.door_open:
		return "E: save at the safe point."
	return "Find the breaker. Tab switches companions inside the amber floor lights."


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
