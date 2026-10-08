extends SceneTree

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const State = preload("res://scripts/m0_state.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var path: String = "user://m0-scene-test-%s.json" % OS.get_process_id()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	game.set("settings_path", "%s-settings.cfg" % path)
	root.add_child(game)
	var title_screen: Control = game.get_node("CanvasLayer/TitleScreen") as Control
	var title_art: TextureRect = game.get_node("CanvasLayer/TitleScreen/CorridorArt") as TextureRect
	var title_mark: TextureRect = game.get_node("CanvasLayer/TitleScreen/LogoMark") as TextureRect
	var title_logo: Label = game.get_node("CanvasLayer/TitleScreen/GameTitle") as Label
	var new_game_button: Button = game.get_node("CanvasLayer/TitleScreen/NewGameButton") as Button
	var continue_button: Button = game.get_node("CanvasLayer/TitleScreen/ContinueButton") as Button
	var credits_button: Button = game.get_node("CanvasLayer/TitleScreen/CreditsButton") as Button
	var credits_screen: ColorRect = game.get_node("CanvasLayer/TitleScreen/CreditsScreen") as ColorRect
	var credits_back_button: Button = game.get_node("CanvasLayer/TitleScreen/CreditsScreen/CreditsBackButton") as Button
	var credits_pause_button: Button = game.get_node("CanvasLayer/TitleScreen/CreditsScreen/CreditsPauseButton") as Button
	var hud: Label = game.get_node("CanvasLayer/TopBar/HUD") as Label
	var top_card: ColorRect = game.get_node("CanvasLayer/TopBar") as ColorRect
	var speaker: Label = game.get_node("CanvasLayer/BottomBar/Speaker") as Label
	var story: Label = game.get_node("CanvasLayer/BottomBar/Story") as Label
	var context_hint: ColorRect = game.get_node("CanvasLayer/ContextHint") as ColorRect
	var choice_1_button: Button = game.get_node("CanvasLayer/TouchControls/Choice1") as Button
	var choice_2_button: Button = game.get_node("CanvasLayer/TouchControls/Choice2") as Button
	var tutorial_prompt: ColorRect = game.get_node("CanvasLayer/TutorialPrompt") as ColorRect
	var tutorial_text: Label = game.get_node("CanvasLayer/TutorialPrompt/Text") as Label
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	var relay_spark: Line2D = game.get_node("RelaySpark") as Line2D
	var relay_status_light: ColorRect = game.get_node("RelayStatusLight") as ColorRect

	if not _require(game.get("title_open") and title_screen.visible and continue_button.disabled, "fresh title disables Continue without a test checkpoint"):
		return
	var continue_note: Label = game.get_node("CanvasLayer/TitleScreen/ContinueNote") as Label
	_expect(continue_note.text == "No checkpoint yet. Reach a SAFE POINT to save." and continue_button.tooltip_text == continue_note.text, "disabled Continue explains that no checkpoint exists yet")
	var note_width: float = continue_note.get_theme_font("font").get_string_size(continue_note.text, HORIZONTAL_ALIGNMENT_LEFT, -1, continue_note.get_theme_font_size("font_size")).x
	_expect(note_width <= continue_note.size.x and continue_note.position.y >= continue_button.position.y + continue_button.size.y and continue_note.position.y + continue_note.size.y <= credits_button.position.y, "Continue caption fits between the title button rows")
	if not _require(title_art.texture != null and title_art.texture.resource_path == "res://assets/title-corridor-key-art-provisional.png", "title shows the corridor artwork"):
		return
	if not _require(title_logo.text == "WOLF//OVERRIDE" and title_mark.texture != null and title_mark.texture.resource_path == "res://assets/logo-mark.svg", "title loads the branded WOLF//OVERRIDE logo"):
		return
	credits_button.pressed.emit()
	if not _require(credits_screen.visible and not title_logo.visible and game.get("title_open"), "Credits opens cleanly without starting the game"):
		return
	var credits_body: RichTextLabel = credits_screen.get_node("CreditsBody") as RichTextLabel
	_expect(credits_body.text.contains("Nathanial Henniges") and credits_body.text.contains("Godot 4.7.2"), "in-game credits name the creator and production tools")
	game.call("_process", 1.0)
	_expect(credits_body.get_v_scroll_bar().value > 0.0, "credits scroll during title playback")
	credits_pause_button.pressed.emit()
	_expect(game.get("credits_paused") and credits_pause_button.text == "RESUME SCROLL", "credits scroll can be paused for reading")
	var paused_position: float = credits_body.get_v_scroll_bar().value
	game.call("_process", 1.0)
	_expect(is_equal_approx(credits_body.get_v_scroll_bar().value, paused_position), "paused credits stay in place")
	credits_back_button.pressed.emit()
	if not _require(not credits_screen.visible and title_logo.visible and game.get("title_open"), "Back restores the title"):
		return
	credits_button.pressed.emit()
	_expect(not game.get("credits_paused") and credits_pause_button.text == "PAUSE SCROLL", "credits scroll resets when reopened")
	credits_back_button.pressed.emit()
	new_game_button.pressed.emit()
	if not _require(not game.get("title_open") and not title_screen.visible, "New Game button starts play through its signal"):
		return
	var intro_gate: Sprite2D = game.get_node("IntroGate") as Sprite2D
	var intro_director: Sprite2D = game.get_node("IntroDirector") as Sprite2D
	var intro_fade: ColorRect = game.get_node("CanvasLayer/IntroFade") as ColorRect
	var purge_terminal_art: Sprite2D = game.get_node("PurgeTerminalArt") as Sprite2D
	_expect(game.get("intro_active") and intro_gate.visible and intro_director.visible and not human.visible and not purge_terminal_art.visible and not human.controlled, "opening shows only WOLF and Director, without the later terminal or engineer")
	_expect(top_card.visible and hud.text.contains("CONTAINMENT"), "opening starts with a location slate")
	await create_timer(3.2).timeout
	game.call("_refresh_ui")
	_expect(not top_card.visible, "opening slate fades away and does not reappear each frame")
	await _tap(&"interact")
	_expect(game.get("intro_step") == 1 and str(game.get("status_line")).contains("wakes himself"), "WOLF wakes himself and opens containment")
	await _tap(&"interact")
	_expect(game.get("intro_step") == 2 and str(game.get("status_line")).contains("gate slides aside"), "WOLF opens containment from inside through a sliding gate")
	await _tap(&"interact")
	_expect(game.get("intro_step") == 3 and str(game.get("status_line")).contains("I won't do it"), "WOLF refuses the Director before the engineer arrives")
	await _tap(&"interact")
	_expect(game.get("intro_step") == 4 and str(game.get("status_line")).contains("Lock down maintenance"), "Director orders lockdown as WOLF leaves")
	await _tap(&"interact")
	await create_timer(0.8).timeout
	_expect(not game.get("intro_active") and not intro_gate.visible and not intro_director.visible and human.visible and purge_terminal_art.visible and human.controlled and intro_fade.color.a < 0.01, "opening fades into engineer control and gameplay stations")
	var gameplay_camera: Camera2D = game.get_node("IntroCamera") as Camera2D
	_expect(gameplay_camera.zoom.x > 1.0 and gameplay_camera.position_smoothing_enabled, "play view is closer and follows the engineer after the opening")
	var state: M0State = game.get("state") as M0State
	_expect(state.memory.is_empty() and not state.door_open and state.active_actor == "human", "New Game button starts clean")
	_expect(wolf.position.x < human.position.x and is_equal_approx(human.position.x - wolf.position.x, 64.0), "WOLF starts beside, not inside, the engineer")
	_expect(human.controlled and not wolf.controlled and not InputMap.has_action(&"switch_actor"), "only the engineer has movement controls")
	_expect(game.call("_objective") == "CHECK THE BREAKER", "opening points to the first corridor objective")
	_expect(top_card.visible and hud.text.contains("CHECK THE BREAKER"), "new gameplay objective appears as a short card")
	_expect(speaker.text.is_empty() and story.text.begins_with("WOLF:") and story.text.contains("\n%s:" % state.human_name().get_slice(" ", 0).to_upper()), "two speakers keep their own names in the opening exchange")
	await create_timer(3.9).timeout
	game.call("_refresh_ui")
	_expect(not top_card.visible, "gameplay objective card fades without returning each frame")
	_expect(tutorial_prompt.visible and tutorial_text.text == "A / D  MOVE\nE  READ DISPLAY (optional)", "New Game teaches movement and offers the nearby display as optional")
	var breaker_art: Sprite2D = game.get_node("BreakerArt") as Sprite2D
	var tutorial_rect: Rect2 = tutorial_prompt.get_global_rect()
	_expect(not tutorial_rect.intersects(purge_terminal_art.get_global_transform_with_canvas() * purge_terminal_art.get_rect()) and not tutorial_rect.intersects(breaker_art.get_global_transform_with_canvas() * breaker_art.get_rect()) and not tutorial_rect.intersects(top_card.get_global_rect()), "tutorial box leaves the purge display, breaker and objective card uncovered")
	_expect(_widest_line(tutorial_text) <= tutorial_text.size.x, "tutorial lines fit inside the tutorial box")
	Input.action_press(&"move_right")
	game.call("_process", 0.016)
	Input.action_release(&"move_right")
	_expect(tutorial_prompt.visible and tutorial_text.text == "E  READ DISPLAY (optional)\nOr head right to the breaker.", "movement leaves the display optional and points on to the breaker")
	game.set("touch_enabled", true)
	game.call("_refresh_ui")
	_expect(tutorial_text.text.begins_with("TAP USE  READ DISPLAY (optional)") and _widest_line(tutorial_text) <= tutorial_text.size.x, "touch tutorial line fits inside the tutorial box")
	game.set("touch_enabled", false)
	game.call("_refresh_ui")
	await process_frame
	await _tap(&"interact")
	_expect(str(game.get("status_line")).contains("Original program logs marked for deletion"), "purge display establishes evidence stakes without inventory")
	_expect(not tutorial_prompt.visible, "reading the display clears the opening tutorial")
	var start_x: float = human.position.x
	if not _require(await _walk_to(human, 350.0), "active engineer reaches breaker by moving right"):
		return
	_expect(human.position.x > start_x and wolf.position.x > 225.0 and wolf.position.x < human.position.x, "WOLF follows the engineer autonomously")
	if not _require(await _walk_to(human, 450.0), "engineer can move beyond the breaker"):
		return
	if not _require(await _walk_to(human, 350.0), "engineer can backtrack to the breaker"):
		return
	for _frame in range(40):
		await physics_frame
	_expect(absf(human.position.x - wolf.position.x - 64.0) <= 5.0, "WOLF settles behind the engineer after backtracking")
	await _tap(&"interact")
	if not _require(game.get("waiting_for_choice"), "breaker opens authored disagreement"):
		return
	_expect(speaker.text == "WOLF" and story.text.contains("coolant fault") and not story.text.contains("\n1  "), "dialogue identifies WOLF and keeps response text out of the question")
	_expect(not context_hint.visible and choice_1_button.visible and choice_2_button.visible, "disagreement offers visible choices without a competing interaction hint")
	_expect(choice_1_button.text.contains(State.CHOICE_TEXT[State.DISCLOSE]) and choice_2_button.text.contains(State.CHOICE_TEXT[State.PRESS]), "choice buttons show the complete response text")
	_expect(choice_1_button.size.y == 40.0 and choice_2_button.size.y == 40.0 and choice_1_button.text.begins_with("1  "), "keyboard choices use compact cards with number prompts")
	await _tap(&"choice_1")
	if not _require(state.memory.get("choice_id") == State.DISCLOSE, "first dialogue key records disclosed risk"):
		return
	await create_timer(0.1).timeout
	_expect(wolf.body_sprite.position.distance_to(Vector2(0.0, -15.0)) > 2.0, "WOLF visibly reacts to the disclosed risk")
	_expect(game.call("_objective") == "ARM THE BREAKER", "honest answer advances the objective")
	await _tap(&"interact")
	if not _require(state.breaker_armed, "breaker arms after choice"):
		return
	_expect(game.call("_objective") == "OPEN THE SEAL", "powered relay becomes the objective")
	if not _require(await _walk_to(human, 605.0), "engineer reaches relay with WOLF following"):
		return
	game.call("_update_gameplay_camera")
	_expect(gameplay_camera.position.x > 480.0 and gameplay_camera.position.x < 560.0, "camera scrolls toward the engineer without exposing the corridor edge")
	_expect(not wolf.controlled and wolf.position.x > 400.0 and wolf.position.x < human.position.x, "WOLF stays a companion at the relay")
	_expect(str(game.call("_context_hint")).contains("ask WOLF"), "relay hint offers WOLF the live contact")
	await _tap(&"interact")
	if not _require(not state.door_open and game.get("wolf_heading_to_relay") and str(game.get("status_line")).contains("I've got the contact"), "WOLF sets off for the contact himself and the seal stays closed until he arrives"):
		return
	_expect(str(game.call("_context_hint")).contains("manual bypass"), "the engineer keeps a bypass while WOLF walks")
	if not _require(await _wait_until(func() -> bool: return not game.get("wolf_heading_to_relay"), 120), "WOLF reaches the contact by himself"):
		return
	if not _require(state.door_open and state.route == "cooperate", "WOLF cooperation opens door"):
		return
	_expect(relay_status_light.color == Color("#a4f0c4"), "open relay changes from live cyan to completed green")
	_expect(relay_spark.visible and relay_spark.default_color == Color("#8be3ff"), "WOLF's contact produces a visible cyan relay spark")
	_expect(game.call("_objective") == "REACH SAFE POINT", "open seal points to safety")
	_expect(str(game.call("_context_hint")).contains("Move to the safe point"), "open-door hint no longer sends the player back to the breaker")
	await create_timer(0.68).timeout
	var door_visual: ColorRect = game.get_node("Door/Visual") as ColorRect
	_expect(not door_visual.visible, "door retracts after cooperation")
	_expect(not relay_spark.visible and wolf.body_sprite.position == Vector2(0.0, -15.0), "contact reaction settles after the seal opens")
	await _tap(&"interact")
	_expect(not door_visual.visible, "reusing the open relay does not replay the door seal")
	if not _require(await _walk_to(human, 876.0), "engineer walks through opened door to checkpoint"):
		return
	await _tap(&"interact")
	if not _require(state.checkpoint_reached and FileAccess.file_exists(path), "cooperative checkpoint saves"):
		return
	_expect(game.call("_objective") == "CORRIDOR CLEARED", "checkpoint closes the first scene")
	_expect(str(game.get("status_line")).contains(State.CHOICE_TEXT[State.DISCLOSE]), "cooperative checkpoint displays the selected choice")
	var saved: Dictionary = state.to_dict()
	game.call("_new_game")
	await _tap(&"pause_game")
	_expect(paused and game.get("intro_active"), "Pause during the opening pauses instead of skipping")
	(game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton") as Button).pressed.emit()
	state = game.get("state") as M0State
	_expect(state.memory.is_empty() and not state.door_open and human.position == state.human_position, "New Game clears current play")
	game.call("_load_game")
	await process_frame
	state = game.get("state") as M0State
	if not _require(state.to_dict() == saved and state.active_actor == "human" and human.controlled and not wolf.controlled, "load restores cooperative scene with engineer control"):
		return
	_expect(human.position == state.human_position and wolf.position == state.wolf_position and state.checkpoint_callback().contains(State.CHOICE_TEXT[State.DISCLOSE]), "load restores positions and actual callback")

	game.call("_new_game")
	game.call("_finish_intro")
	state = game.get("state") as M0State
	_expect(game.get("tutorial_step") == 0 and tutorial_prompt.visible, "fresh fallback play starts with the tutorial")
	if not _require(await _walk_to(human, 270.0), "engineer heads for the breaker without reading the display"):
		return
	await process_frame
	_expect(tutorial_prompt.visible and tutorial_text.text == "A / D  MOVE\nHead right to the breaker." and game.call("_objective") == "CHECK THE BREAKER", "skipping the display keeps the tutorial and objective pointed at the breaker")
	if not _require(await _walk_to(human, 350.0), "engineer reaches breaker on fresh fallback play"):
		return
	await process_frame
	_expect(game.get("tutorial_step") == 2 and not tutorial_prompt.visible and not str(game.get("status_line")).contains("Original program logs"), "reaching the breaker clears the tutorial without reading the display")
	await _tap(&"interact")
	if not _require(game.get("waiting_for_choice"), "fallback opens authored disagreement"):
		return
	await _tap(&"choice_2")
	if not _require(state.memory.get("choice_id") == State.PRESS, "second dialogue key records pressed risk"):
		return
	_expect(str(game.get("status_line")).contains("I won't take that risk blind"), "WOLF refuses the live contact")
	await create_timer(0.1).timeout
	_expect(wolf.body_sprite.position.x < -2.0, "WOLF visibly steps back from the unwarned request")
	await _tap(&"interact")
	if not _require(state.breaker_armed, "fallback breaker arms"):
		return
	if not _require(await _walk_to(human, 605.0), "engineer reaches manual bypass on fallback play"):
		return
	_expect(not state.door_open and str(game.call("_context_hint")).contains("ask WOLF"), "relay first offers WOLF a choice")
	await _tap(&"interact")
	if not _require(not state.door_open and state.route.is_empty() and game.get("relay_refused"), "WOLF refuses and keeps the seal closed"):
		return
	_expect(relay_status_light.color == Color("#f3ae4b"), "refused relay shows an amber state")
	_expect(str(game.get("status_line")).contains("I said no") and str(game.call("_context_hint")).contains("manual bypass"), "refusal clearly offers the engineer's bypass")
	Input.action_press(&"move_right")
	for _frame in range(180):
		await physics_frame
	Input.action_release(&"move_right")
	_expect(human.position.x < 760.0, "locked door physically blocks the engineer")
	if not _require(await _walk_to(human, 605.0), "engineer can return to manual bypass after refusal"):
		return
	await _tap(&"interact")
	if not _require(state.door_open and state.route == "fallback", "engineer bypass opens door"):
		return
	_expect(relay_spark.visible and relay_spark.default_color == Color("#f3ae4b"), "manual bypass produces a distinct amber relay spark")
	_expect(str(game.call("_context_hint")).contains("Move to the safe point"), "fallback hint points through the open seal")
	if not _require(await _walk_to(human, 876.0), "engineer walks through opened door to checkpoint"):
		return
	await _tap(&"cycle_name")
	_expect(state.name_index == 1, "draft identity changes before fallback save")
	_expect(str(game.get("status_line")).contains("Alex Bennett") and hud.text.contains("MAINTENANCE"), "provisional name changes without crowding the objective display")
	_expect(not str(game.get("status_line")).contains("breaker"), "identity line does not rewind the scene after the seal opens")
	await _tap(&"interact")
	if not _require(state.checkpoint_reached, "fallback reaches checkpoint"):
		return
	_expect(str(game.get("status_line")).contains(State.CHOICE_TEXT[State.PRESS]), "fallback checkpoint displays the selected choice")
	saved = state.to_dict()
	game.call("_load_game")
	await process_frame
	state = game.get("state") as M0State
	_expect(state.to_dict() == saved and state.checkpoint_callback().contains(State.CHOICE_TEXT[State.PRESS]), "fallback save loads with one accurate memory")
	_expect(not game.get("relay_refused"), "load clears the transient refusal prompt")
	game.queue_free()
	await process_frame
	game = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	game.set("settings_path", "%s-settings.cfg" % path)
	root.add_child(game)
	title_screen = game.get_node("CanvasLayer/TitleScreen") as Control
	continue_button = game.get_node("CanvasLayer/TitleScreen/ContinueButton") as Button
	human = game.get_node("Human") as M0Actor
	wolf = game.get_node("Wolf") as M0Actor
	if not _require(game.get("title_open") and title_screen.visible and not continue_button.disabled, "fresh title enables Continue for the test checkpoint"):
		return
	continue_note = game.get_node("CanvasLayer/TitleScreen/ContinueNote") as Label
	_expect(continue_note.text.is_empty() and continue_button.tooltip_text.is_empty(), "enabled Continue shows no warning caption")
	continue_button.pressed.emit()
	state = game.get("state") as M0State
	if not _require(not game.get("title_open") and not title_screen.visible, "Continue button starts saved play through its signal"):
		return
	_expect(state.to_dict() == saved and state.active_actor == "human" and human.controlled and not wolf.controlled and state.route == "fallback" and state.name_index == 1 and state.memory.get("choice_id") == State.PRESS, "Continue restores engineer control, puzzle, identity and one accurate memory")
	_expect(human.position == state.human_position and wolf.position == state.wolf_position and state.checkpoint_callback().contains(State.CHOICE_TEXT[State.PRESS]), "Continue restores both actor positions and actual callback")

	var unreadable: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	unreadable.store_string("not a checkpoint")
	unreadable.close()
	game.call("_refresh_continue")
	_expect(continue_button.disabled and continue_note.text == "Saved checkpoint could not be read." and continue_button.tooltip_text == continue_note.text, "disabled Continue explains an unreadable checkpoint")

	# Disclosed risk, but the engineer takes the bypass while WOLF is still walking.
	game.call("_new_game")
	game.call("_finish_intro")
	state = game.get("state") as M0State
	if not _require(await _walk_to(human, 350.0), "engineer reaches breaker on the disclose-then-bypass route"):
		return
	await _tap(&"interact")
	await _tap(&"choice_1")
	await _tap(&"interact")
	if not _require(state.breaker_armed, "breaker arms on the disclose-then-bypass route"):
		return
	if not _require(await _walk_to(human, 605.0), "engineer reaches the relay after disclosing"):
		return
	await _tap(&"interact")
	if not _require(game.get("wolf_heading_to_relay"), "WOLF heads for the contact after the risk is disclosed"):
		return
	await _tap(&"interact")
	_expect(state.door_open and state.route == "fallback" and not game.get("wolf_heading_to_relay") and str(game.get("status_line")).contains("takes the bypass"), "a second use while WOLF walks is the engineer's bypass")
	_expect(wolf.follow_target == human, "WOLF returns to following after the bypass")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	game.queue_free()
	if failures == 0:
		print("M0 scene checks passed")
	quit(1 if failures > 0 else 0)


func _tap(action: StringName) -> void:
	await process_frame
	if action == &"pause_game":
		# Pause is event-driven, so send a real input event.
		Input.parse_input_event(_action_event(action, true))
		await process_frame
		Input.parse_input_event(_action_event(action, false))
		return
	Input.action_press(action)
	await process_frame
	Input.action_release(action)


func _action_event(action: StringName, pressed: bool) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


func _widest_line(label: Label) -> float:
	var widest: float = 0.0
	for line: String in label.text.split("\n"):
		widest = maxf(widest, label.get_theme_font("font").get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x)
	return widest


func _wait_until(condition: Callable, frames: int) -> bool:
	for _frame in range(frames):
		await physics_frame
		if condition.call():
			return true
	return false


func _walk_to(actor: M0Actor, target_x: float) -> bool:
	var action: StringName = &"move_right" if target_x > actor.position.x else &"move_left"
	Input.action_press(action)
	var reached: bool = false
	for _frame in range(300):
		await physics_frame
		if absf(actor.position.x - target_x) <= 12.0:
			reached = true
			break
	Input.action_release(action)
	return reached


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("M0 scene check failed: " + label)


func _require(condition: bool, label: String) -> bool:
	_expect(condition, label)
	if not condition:
		quit(1)
	return condition
