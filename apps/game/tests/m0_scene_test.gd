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
	var top_card: Panel = game.get_node("CanvasLayer/TopBar") as Panel
	var speaker: Label = game.get_node("CanvasLayer/BottomBar/Speaker") as Label
	var story: Label = game.get_node("CanvasLayer/BottomBar/Story") as Label
	var context_hint: Panel = game.get_node("CanvasLayer/ContextHint") as Panel
	var choice_1_button: Button = game.get_node("CanvasLayer/TouchControls/Choice1") as Button
	var choice_2_button: Button = game.get_node("CanvasLayer/TouchControls/Choice2") as Button
	var tutorial_prompt: Panel = game.get_node("CanvasLayer/TutorialPrompt") as Panel
	var tutorial_text: Label = game.get_node("CanvasLayer/TutorialPrompt/Text") as Label
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	var relay_spark: Line2D = game.get_node("RelaySpark") as Line2D
	var relay_status_light: ColorRect = game.get_node("RelayStatusLight") as ColorRect

	if not _require(game.get("title_open") and title_screen.visible and continue_button.disabled, "fresh title disables Continue without a test checkpoint"):
		return
	var continue_note: Label = game.get_node("CanvasLayer/TitleScreen/ContinueNote") as Label
	_expect(continue_note.text == "No checkpoint yet. Saving starts at the first SAFE POINT." and continue_button.tooltip_text == continue_note.text, "disabled Continue explains that no checkpoint exists yet")
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
	# Audit 12: the Director's lines carry his tag; the narration has its own untagged boxes.
	_expect(speaker.visible and speaker.text == "DIRECTOR" and story.text == "I decide who counts as a threat. WOLF handles the rest.", "the Director's first line sits alone under his tag")
	await _tap(&"interact")
	_expect(game.get("intro_step") == 1 and not speaker.visible and story.text == "The Director thinks WOLF is still in standby.", "the narration after it gets its own untagged box, naming the Director")
	await _tap(&"interact")
	_expect(game.get("intro_step") == 2 and str(game.get("status_line")).contains("wakes himself") and not speaker.visible, "WOLF wakes himself and opens containment")
	await _tap(&"interact")
	_expect(game.get("intro_step") == 3 and str(game.get("status_line")).contains("gate slides aside"), "WOLF opens containment from inside through a sliding gate")
	await create_timer(1.2).timeout
	_expect(intro_gate.visible and is_equal_approx(float(intro_gate.get("opening")), 1.0), "the opened gate stays drawn, folded aside, instead of vanishing")
	await _tap(&"interact")
	_expect(game.get("intro_step") == 4 and str(game.get("status_line")).contains("I won't do it") and not speaker.visible and story.text.begins_with("DIRECTOR: ") and story.text.contains("\nWOLF: "), "WOLF refuses the Director before the engineer arrives, both names inline")
	_expect(intro_gate.visible and is_equal_approx(float(intro_gate.get("opening")), 1.0), "the gate is still standing open in the next beat")
	await _tap(&"interact")
	_expect(game.get("intro_step") == 5 and speaker.text == "DIRECTOR" and story.text == "Lock down maintenance. WOLF does not leave this site.", "Director orders lockdown under his own tag")
	await _tap(&"interact")
	_expect(game.get("intro_step") == 6 and not speaker.visible and story.text == "WOLF turns from the Director and heads for maintenance." and wolf.autonomous_target_x == 110.0, "the narration says WOLF turns from the Director and heads for maintenance as he walks off")
	# Round 3c: the opening is main's (76d3a50): nothing is added on the wall behind WOLF's cage.
	_expect(game.get_node_or_null("OpeningHatch") == null and game.get("opening_hatch") == null, "nothing new stands behind the cage in the opening")
	await _tap(&"interact")
	await create_timer(0.8).timeout
	_expect(not game.get("intro_active") and not intro_gate.visible and not intro_director.visible and human.visible and purge_terminal_art.visible and human.controlled and intro_fade.color.a < 0.01, "opening fades into engineer control and gameplay stations")
	var gameplay_camera: Camera2D = game.get_node("IntroCamera") as Camera2D
	_expect(gameplay_camera.zoom.x > 1.0 and gameplay_camera.position_smoothing_enabled, "play view is closer and follows the engineer after the opening")
	var state: M0State = game.get("state") as M0State
	_expect(state.memory.is_empty() and not state.door_open and state.active_actor == "human", "New Game button starts clean")
	_expect(wolf.position.x < human.position.x and is_equal_approx(human.position.x - wolf.position.x, M0Actor.FOLLOW_GAP), "WOLF starts one follow gap behind, not inside, the engineer")
	_expect(human.controlled and not wolf.controlled and not InputMap.has_action(&"switch_actor"), "only the engineer has movement controls")
	_expect(game.call("_objective") == "CHECK THE BREAKER", "opening points to the first corridor objective")
	var name_card: String = "%s\nMAINTENANCE ENGINEER" % state.human_name().to_upper()
	var card_accent: ColorRect = game.get_node("CanvasLayer/TopBar/Accent") as ColorRect
	_expect(top_card.visible and hud.text == name_card and card_accent.color == Color("#f4d5ae") and human.controlled, "control starts with the engineer's name card, in their colour, without taking the controls")
	_expect(_widest_line(hud) <= hud.size.x, "the name card fits its card")
	state.cycle_name()
	game.call("_refresh_ui")
	_expect(hud.text == "ALEX BENNETT\nMAINTENANCE ENGINEER", "cycling the provisional name updates the name card while it is up")
	state.cycle_name()
	state.cycle_name()
	game.call("_refresh_ui")
	_expect(speaker.text.is_empty() and story.text.begins_with("Rowan keeps WOLF's systems running. They know what a fault looks like, and this isn't one.\nWOLF:") and story.text.contains("\n%s:" % state.human_name().get_slice(" ", 0).to_upper()), "the opening box says why the engineer trusts WOLF, then both speakers keep their own names")
	await create_timer(3.3).timeout
	game.call("_refresh_ui")
	_expect(top_card.visible and hud.text.contains("CHECK THE BREAKER") and card_accent.color == Color(0.22, 0.78, 0.92, 1), "the objective card follows the name card")
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
	_expect(str(game.get("status_line")).contains("Original program logs marked for deletion"), "walking straight on past the display leaves its text up to be read")
	_expect(await _wait_until(func() -> bool: return str(game.get("status_line")) == "WOLF: That purge takes the original program logs. Once they're gone, his word is the only record.", 240), "once the display's text has been up long enough to read, WOLF says what the purge takes")
	if not _require(await _walk_to(human, 450.0), "engineer can move beyond the breaker"):
		return
	if not _require(await _walk_to(human, 350.0), "engineer can backtrack to the breaker"):
		return
	# Stopped over the breaker's cabinet, the engineer sidesteps out beside it, still facing left and in
	# its reach, instead of standing inside the machine.
	_expect(await _wait_until(func() -> bool: return absf(human.position.x - 350.0) >= 38.0 + M0Actor.HUMAN_REACH - 6.0 - 2.0 and absf(human.velocity.x) < 1.0, 60), "stopped over the breaker the engineer steps out beside it (x %.0f)" % human.position.x)
	_expect(human.body_sprite.flip_h and absf(human.position.x - 350.0) <= 52.0, "the sidestep keeps the engineer's facing and the breaker in reach")
	# Backtracking turns the engineer left, so WOLF crosses to his right and settles a follow gap away,
	# or a little further back where that gap would stand him over the breaker.
	_expect(await _wait_until(func() -> bool: return wolf.position.x > human.position.x and absf(wolf.velocity.x) < 1.0 and wolf.position.x - human.position.x >= M0Actor.FOLLOW_GAP - 5.0 and wolf.position.x - human.position.x <= M0Actor.FOLLOW_GAP + M0Actor.AVOID_DETOUR, 150), "WOLF settles behind the engineer after backtracking")
	_expect(wolf.position.x - M0Actor.WOLF_REACH + M0Actor.AVOID_TOLERANCE >= 350.0 + 38.0 - 3.0, "resting behind the engineer at the breaker, WOLF stands clear of its cabinet (x %.0f)" % wolf.position.x)
	await _tap(&"interact")
	if not _require(game.get("waiting_for_choice"), "breaker opens authored disagreement"):
		return
	_expect(speaker.text == "WOLF" and story.text.contains("COOLANT FAULT") and not story.text.contains("\n1  "), "dialogue identifies WOLF, points at the relay's fault tag and keeps response text out of the question")
	var bypass_handle: BypassHandle = game.get("bypass_handle") as BypassHandle
	_expect(bypass_handle.visible and bypass_handle.fault_tag.text == "COOLANT FAULT" and bypass_handle.bypass_label.text == "MANUAL BYPASS", "the relay wears a COOLANT FAULT tag and the bypass its own name plate")
	var bypass_plate: Rect2 = Rect2(bypass_handle.global_position + bypass_handle.bypass_label.position, bypass_handle.bypass_label.size)
	var fault_plate: Rect2 = Rect2(bypass_handle.global_position + bypass_handle.fault_tag.position, bypass_handle.fault_tag.size)
	var hub: Vector2 = bypass_handle.global_position + BypassHandle.WHEEL_OFFSET
	var relay_name: Rect2 = (game.get_node("RelayLabel") as Label).get_global_rect()
	_expect(not bypass_plate.intersects(relay_name), "the MANUAL BYPASS plate stays clear of the COOLANT RELAY name (plate %s, name %s)" % [bypass_plate, relay_name])
	_expect(not bypass_plate.intersects(fault_plate) and bypass_plate.end.x <= 702.0 and bypass_plate.position.x <= hub.x and bypass_plate.end.x >= hub.x and bypass_plate.end.y < hub.y - 50.0, "the MANUAL BYPASS plate stands over its wheel's hub, clear of the COOLANT FAULT tag and left of the chain guard (x 702)")
	_expect(bypass_handle.global_position.y + BypassHandle.LEADER_END_Y > bypass_plate.end.y and absf(bypass_handle.global_position.x + BypassHandle.LEADER_X - hub.x) < 0.01, "a leader runs from the plate straight down to the wheel's backplate")
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
	var half_view: Vector2 = Vector2(960.0, 540.0) * 0.5 / gameplay_camera.zoom
	_expect(is_equal_approx(gameplay_camera.zoom.x, 1.35), "play view uses the 1.35 gameplay zoom")
	_expect(gameplay_camera.position.x > 560.0 and gameplay_camera.position.x - half_view.x >= 0.0 and gameplay_camera.position.x + half_view.x <= 960.0, "camera scrolls toward the engineer without exposing the corridor edge")
	_expect(is_equal_approx(gameplay_camera.position.x, clampf(human.position.x, half_view.x, 960.0 - half_view.x)), "the camera centres on the engineer inside its room clamp")
	# Feet on the floor (y 440) stay at least 24 px above the context hint, and the ceiling lamps (y ~188) stay in view.
	var feet_screen_y: float = (440.0 - gameplay_camera.position.y) * gameplay_camera.zoom.y + 270.0
	_expect(feet_screen_y <= context_hint.position.y - 24.0, "the actors' feet sit clear above the context hint")
	_expect(gameplay_camera.position.y - half_view.y <= 170.0 and gameplay_camera.position.y + half_view.y <= 600.0, "play view keeps the ceiling lamps in view and stays on the painting")
	# With the touch buttons up, the camera sits lower so feet and station bases clear their tops.
	game.set("touch_enabled", true)
	game.call("_refresh_ui")
	game.call("_update_gameplay_camera")
	var touch_feet_y: float = (440.0 - gameplay_camera.position.y) * gameplay_camera.zoom.y + 270.0
	var button_top: float = (game.get_node("CanvasLayer/TouchControls/Use") as Control).get_global_rect().position.y
	_expect(touch_feet_y <= button_top - 8.0 and gameplay_camera.position.y + half_view.y <= 600.0, "with touch buttons the feet sit above them (feet %.0f, buttons from %.0f) and the view stays on the painting" % [touch_feet_y, button_top])
	game.set("touch_enabled", false)
	game.call("_refresh_ui")
	game.call("_update_gameplay_camera")
	_expect(not wolf.controlled and wolf.position.x > 400.0 and wolf.position.x < human.position.x, "WOLF stays a companion at the relay")
	_expect(str(game.call("_context_hint")) == "E: signal WOLF to take the contact.", "after WOLF offered, the relay hint signals him instead of asking again")
	await _tap(&"interact")
	if not _require(not state.door_open and game.get("wolf_heading_to_relay") and str(game.get("status_line")).contains("I've got the contact"), "WOLF sets off for the contact himself and the seal stays closed until he arrives"):
		return
	_expect(not human.controlled and is_equal_approx(float(game.get("engineer_step_x")), 736.0) and str(game.call("_context_hint")) == "WOLF is moving to the contact.", "the engineer steps back from the relay while WOLF walks to it")
	if not _require(await _wait_until(func() -> bool: return not game.get("wolf_heading_to_relay"), 120), "WOLF reaches the contact by himself"):
		return
	if not _require(state.door_open and state.route == "cooperate", "WOLF cooperation opens door"):
		return
	_expect(human.controlled and human.position.x - M0Actor.HUMAN_REACH >= 592.0 + M0Actor.WOLF_REACH, "the engineer is clear of WOLF on the contact before he takes it")
	_expect(str(game.get("status_line")) == "WOLF takes the surge through the live contact. The red seal opens.", "the payoff line says what the screen shows")
	_expect(relay_status_light.color == Color("#a4f0c4"), "open relay changes from live cyan to completed green")
	_expect(relay_spark.visible and relay_spark.default_color == Color("#8be3ff"), "WOLF's contact produces a visible cyan relay spark")
	_expect(game.call("_objective") == "REACH SAFE POINT", "open seal points to safety")
	_expect(str(game.call("_context_hint")) == "The seal is opening." and wolf.autonomous_target_x == 592.0, "while the seal rises the hint says it is opening and WOLF stays on the contact")
	var door_shape: CollisionShape2D = game.get_node("Door/CollisionShape2D") as CollisionShape2D
	var seal_leaf: SealLeaf = game.get("seal_leaf") as SealLeaf
	await create_timer(0.45).timeout
	_expect(seal_leaf.visible and seal_leaf.open > 0.05 and seal_leaf.open < 0.95 and not door_shape.disabled and wolf.autonomous_target_x == 592.0 and absf(wolf.position.x - 592.0) <= 4.0, "half way the seal's leaf is rising into the header, the doorway is still shut and WOLF still holds the contact")
	if not _require(await _wait_until(func() -> bool: return not game.get("seal_opening"), 90), "the seal finishes opening"):
		return
	await physics_frame
	var door_visual: ColorRect = game.get_node("Door/Visual") as ColorRect
	_expect(not door_visual.visible and not seal_leaf.visible and door_shape.disabled, "door retracts after cooperation and the doorway opens once it lands")
	_expect(str(game.call("_context_hint")).contains("Move to the safe point") and wolf.follow_target == human, "once the seal has landed the hint says it is open and WOLF lets go of the contact")
	_expect((game.get("door_open_art") as Sprite2D).visible and (game.get("door_lip") as Sprite2D).visible and (game.get("door_lip") as Sprite2D).z_index > human.z_index, "the bulkhead stands open behind the engineer, its front pillar drawn over him")
	# The corridor's near column is solid (it never fades and nothing is drawn over it), and slim:
	# its art ends left of where the engineer can use the safe point.
	var column: Sprite2D = game.get("door_lip") as Sprite2D
	_expect(not (game.get("corridor_depth") as RoomDepth).pillars.has(column) and column.modulate.a == 1.0, "the corridor's near column stays opaque")
	# Its art has no see-through gap: on every row over the guide's height above its foot (where the
	# chamfer meets the stub and its contact shadow), from its first fully
	# opaque pixel to its last, every pixel is fully opaque, but for the live lamp's glass.
	var column_art: Image = column.texture.get_image()
	if column_art.is_compressed():
		column_art.decompress()
	var gaps: int = 0
	var lamp: Vector2 = (game.get_script() as Script).get_script_constant_map()["CORRIDOR_SEAL_LAMP"]
	for row: int in range(int((330.0 - 150.0) / column.scale.y), int((446.0 - 150.0) / column.scale.y)):
		var world_y: float = column.get_global_transform().origin.y + row * column.scale.y
		var opaque: Array[int] = []
		for x: int in int(column.region_rect.size.x):
			if column_art.get_pixel(int(column.region_rect.position.x) + x, int(column.region_rect.position.y) + row).a >= 0.999:
				opaque.append(x)
		if opaque.is_empty():
			continue
		for x: int in range(opaque[0], opaque[-1] + 1):
			var world_x: float = column.get_global_transform().origin.x + x * column.scale.x
			if absf(world_x - lamp.x) <= 3.5 and absf(world_y - lamp.y) <= 3.5:
				continue
			if column_art.get_pixel(int(column.region_rect.position.x) + x, int(column.region_rect.position.y) + row).a < 0.999:
				gaps += 1
	_expect(gaps == 0, "the near column's art has no see-through gap between the guide and the column (%d px)" % gaps)
	# The status lamp's conduit has a real top end: up the end face from the lamp box, through a
	# 90-degree elbow, across the face at 4.41 m and round the arris into the camera's wall plate,
	# whose edge is at world x 795.3. Every sample on that path is lit steel, brighter than the bare
	# concrete beside it (on the arris strips, x < 796, only the steel's own value: the strips are as
	# light), and the run carries on to the plate's edge without a break.
	var conduit_path: Array[Vector2] = []
	var beside: Array[Vector2] = []
	for i: int in 9:
		conduit_path.append(Vector2(806.0, 290.0 - i * 2.0))
		beside.append(Vector2(-2.5, 0.0))
	for p: Vector2 in [Vector2(806.0, 272.5), Vector2(805.5, 271.5), Vector2(805.0, 270.5), Vector2(804.5, 270.0)]:
		conduit_path.append(p)
		beside.append(Vector2(-2.0, 1.5))
	for i: int in 18:
		conduit_path.append(Vector2(803.5 - i * 0.5, 269.5))
		beside.append(Vector2(0.0, -2.0))
	var conduit_breaks: Array[String] = []
	var origin: Vector2 = column.get_global_transform().origin
	for i: int in conduit_path.size():
		var at: Vector2 = conduit_path[i]
		var here: Color = column_art.get_pixelv(Vector2i(column.region_rect.position + ((at - origin) / column.scale).floor()))
		var side: Color = column_art.get_pixelv(Vector2i(column.region_rect.position + ((at + beside[i] - origin) / column.scale).floor()))
		if here.a < 0.999 or here.get_luminance() < 0.12 or (at.x >= 796.0 and here.get_luminance() < side.get_luminance() + 0.02):
			conduit_breaks.append("%s (%.3f beside %.3f)" % [at, here.get_luminance(), side.get_luminance()])
	_expect(conduit_breaks.is_empty() and conduit_path[-1].x <= 795.3 + 0.5, "the lamp conduit runs unbroken from the lamp box through its elbow into the camera's wall plate (breaks: %s)" % [conduit_breaks])
	var column_right: float = column.get_global_transform().origin.x + column.region_rect.size.x * column.scale.x
	# The safe point answers from x 824 (its station at 876, reach 52): the column ends before that.
	_expect(column_right <= 876.0 - 52.0, "the near column ends clear of where the safe point is used (right edge %.1f)" % column_right)
	_expect(not relay_spark.visible and wolf.body_sprite.position == Vector2(0.0, -15.0), "contact reaction settles after the seal opens")
	if not _require(await _walk_to(human, 605.0), "the engineer can walk back to the open relay"):
		return
	await _tap(&"interact")
	_expect(not door_visual.visible and not seal_leaf.visible, "reusing the open relay does not replay the door seal")
	if not _require(await _walk_to(human, 876.0), "engineer walks through opened door to checkpoint"):
		return
	await _tap(&"interact")
	if not _require(state.checkpoint_reached and FileAccess.file_exists(path), "cooperative checkpoint saves"):
		return
	_expect(game.call("_objective") == "SAFE POINT REACHED", "checkpoint closes the first scene")
	_expect(str(game.get("status_line")).contains(State.CHOICE_TEXT[State.DISCLOSE]), "cooperative checkpoint displays the selected choice")
	var saved: Dictionary = state.to_dict()
	game.call("_new_game")
	await _tap(&"pause_game")
	_expect(paused and game.get("intro_active"), "Pause during the opening pauses instead of skipping")
	(game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton") as Button).pressed.emit()
	state = game.get("state") as M0State
	_expect(state.memory.is_empty() and not state.door_open and human.position == state.human_position, "New Game clears current play")
	game.call("_load_game")
	# Read where the load put them before a physics step can move WOLF on towards his follow spot.
	var loaded_human: Vector2 = human.position
	var loaded_wolf: Vector2 = wolf.position
	await process_frame
	state = game.get("state") as M0State
	if not _require(state.to_dict() == saved and state.active_actor == "human" and human.controlled and not wolf.controlled, "load restores cooperative scene with engineer control"):
		return
	_expect(loaded_human == state.human_position and loaded_wolf == state.wolf_position and state.checkpoint_callback().contains(State.CHOICE_TEXT[State.DISCLOSE]), "load restores positions and actual callback (engineer %s of %s, WOLF %s of %s)" % [loaded_human, state.human_position, loaded_wolf, state.wolf_position])

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
	_expect(str(game.get("status_line")).contains("keeps WOLF's systems running") and not game.get("stakes_spoken"), "walking right at once leaves the opening box up to be read")
	await _tap(&"interact")
	_expect(str(game.get("status_line")).begins_with("WOLF: That purge takes the original program logs.") and not game.get("waiting_for_choice"), "USE at the breaker before the opening box was read: WOLF says what the purge takes first, and the question waits")
	game.set("status_line", "WOLF: Quiet.")
	if not _require(await _walk_to(human, 200.0) and await _walk_to(human, 350.0), "engineer walks back past the display and returns"):
		return
	_expect(str(game.get("status_line")) == "WOLF: Quiet.", "the stakes line is said once per run, not every pass")
	await _tap(&"interact")
	if not _require(game.get("waiting_for_choice"), "fallback opens authored disagreement"):
		return
	await _tap(&"choice_2")
	if not _require(state.memory.get("choice_id") == State.PRESS, "second dialogue key records pressed risk"):
		return
	_expect(str(game.get("status_line")) == "WOLF: No. I won't take that risk blind. Use the manual bypass.", "WOLF refuses the live contact and names the manual bypass")
	await create_timer(0.1).timeout
	_expect(wolf.body_sprite.position.x < -2.0, "WOLF visibly steps back from the unwarned request")
	await _tap(&"interact")
	if not _require(state.breaker_armed, "fallback breaker arms"):
		return
	if not _require(await _walk_to(human, 605.0), "engineer reaches manual bypass on fallback play"):
		return
	_expect(not state.door_open and str(game.call("_context_hint")) == "WOLF refused the live contact. Use the MANUAL BYPASS beside it.", "after WOLF's refusal at the breaker the relay points at the bypass at once instead of asking him again")
	_expect(relay_status_light.color == Color("#f3ae4b"), "refused relay shows an amber state")
	await _tap(&"interact")
	if not _require(not state.door_open and state.route.is_empty() and game.get("relay_refused"), "WOLF refuses and keeps the seal closed"):
		return
	_expect(str(game.get("status_line")) == "WOLF: I said no. I won't touch it blind. The bypass is right beside it." and str(game.call("_context_hint")).contains("MANUAL BYPASS"), "refusal points at the bypass without a key name in WOLF's voice")
	await _tap(&"interact")
	_expect(not state.door_open and str(game.get("status_line")).begins_with("WOLF: I said no."), "a second USE at the relay repeats his refusal; the relay is never the bypass")
	Input.action_press(&"move_right")
	for _frame in range(180):
		await physics_frame
	Input.action_release(&"move_right")
	_expect(human.position.x < 760.0, "locked door physically blocks the engineer")
	if not _require(await _walk_to(human, 700.0), "engineer walks to the manual bypass after refusal"):
		return
	_expect(str(game.call("_context_hint")) == "HOLD E: crank the manual bypass, 0 of 8." and game.call("_hold_station") == &"bypass", "the bypass asks for a held USE and counts the turns")
	game.set("touch_enabled", true)
	game.call("_refresh_ui")
	_expect((game.get_node("CanvasLayer/TouchControls/Use") as Button).text == "CRANK", "on touch the USE button reads CRANK at the bypass")
	game.set("touch_enabled", false)
	game.call("_refresh_ui")
	await _tap(&"interact")
	_expect(not state.door_open and game.get("bypass_venting") and bypass_handle.venting and bypass_handle.coolant_hiss.emitting and str(game.get("status_line")) == "The bypass handle is stiff. Coolant hisses from the relay housing and an alarm starts to wail.", "touching the live bypass starts the coolant hiss and the alarm without opening anything")
	var main_constants: Dictionary = (game.get_script() as Script).get_script_constant_map()
	var crank_x: float = main_constants["BYPASS_CRANK_X"]
	# The drawn wheel's hub (the gameplay point plus the art's offset, under the crank pose's hand).
	var wheel_x: float = (main_constants["BYPASS_WHEEL"] as Vector2).x + BypassHandle.WHEEL_OFFSET.x
	var wolf_clear_x: float = main_constants["WOLF_BYPASS_CLEAR_X"]
	_expect(await _wait_until(func() -> bool: return float(game.get("engineer_step_x")) < 0.0, 30) and absf(human.position.x - crank_x) <= 2.0 and not human.body_sprite.flip_h and human.controlled, "the engineer steps to the crank spot beside the wheel, faces it and has control back")
	# The 0.525 m wheel (10.5 px radius) puts its rim under the crank pose's hand: the engineer's reach
	# may lie over the rim and spokes, never over the hub (2.7 px radius).
	_expect(human.position.x + M0Actor.HUMAN_REACH <= wheel_x - 3.0, "cranking, the engineer's hand is on the wheel's rim and leaves its hub clear (%.1f vs hub %.1f)" % [human.position.x + M0Actor.HUMAN_REACH, wheel_x])
	_expect(wolf.autonomous_target_x == wolf_clear_x, "after his refusal WOLF stands off the live relay while the engineer works the bypass")
	var crank_start: int = Time.get_ticks_msec()
	Input.action_press(&"interact")
	var halfway: bool = await _wait_until(func() -> bool: return int(game.get("bypass_ticks")) >= 4, 150)
	Input.action_release(&"interact")
	_expect(halfway and str(game.get("status_line")) == "Halfway. The hiss gets louder; the alarm keeps wailing." and bypass_handle.ticks == int(game.get("bypass_ticks")), "half way through the crank the hiss gets louder and the handle shows the count")
	_expect(absf(wolf.position.x - wolf_clear_x) <= 3.0 and wolf.position.x + M0Actor.WOLF_REACH < float(main_constants["RELAY_X"]) - 20.0 and not wolf.body_sprite.flip_h, "WOLF is off the relay's housing, facing the engineer at the bypass")
	# Wait for the game's own frame to see the release. process_frame fires before nodes process, and a
	# slow frame can run two physics steps before one, so a fixed physics + process wait can still read
	# the line from before the release.
	var let_go: bool = await _wait_until(func() -> bool: return not game.get("bypass_was_holding"), 30)
	var kept: int = int(game.get("bypass_ticks"))
	_expect(let_go and not state.door_open and kept >= 4 and str(game.get("status_line")) == "The handle holds where Rowan left it. The alarm keeps going." and str(game.call("_context_hint")) == "HOLD E: crank the manual bypass, %d of 8." % kept, "letting go keeps the turns made; the alarm keeps going")
	Input.action_press(&"interact")
	var opened: bool = await _wait_until(func() -> bool: return state.door_open, 150)
	Input.action_release(&"interact")
	if not _require(opened and state.route == "fallback", "cranking the bypass to the end opens the seal on the engineer's own work"):
		return
	_expect(Time.get_ticks_msec() - crank_start >= int(BypassHandle.TICKS_NEEDED * BypassHandle.TICK_SECONDS * 1000.0) - 50 and int(game.get("bypass_ticks")) == 8, "the bypass takes about two seconds of held USE")
	_expect(not game.get("bypass_venting") and not bypass_handle.coolant_hiss.emitting and bypass_handle.done and str(game.get("status_line")) == "The bypass locks over and the alarm cuts out. The red seal opens.\nWOLF: Open. I'm with you.", "the bypass locks over, the alarm cuts out and WOLF answers")
	_expect(relay_spark.visible and relay_spark.default_color == Color("#f3ae4b"), "manual bypass produces a distinct amber relay spark")
	_expect(relay_spark.points[0].x >= wheel_x - 14.0 and relay_spark.points[relay_spark.points.size() - 1].x <= wheel_x + 18.0, "the bypass arc jumps over the wheel, not across WOLF's contact on the relay")
	_expect(wolf.autonomous_target_x == wolf_clear_x and absf(wolf.position.x - wolf_clear_x) <= 3.0, "WOLF stays off the relay he refused while the seal slides up")
	_expect(str(game.call("_context_hint")) == "The seal is opening.", "the hint says the seal is opening while it rises")
	_expect(await _wait_until(func() -> bool: return not game.get("seal_opening"), 90) and str(game.call("_context_hint")).contains("Move to the safe point"), "fallback hint points through the open seal once it has landed")
	if not _require(await _walk_to(human, 876.0), "engineer walks through opened door to checkpoint"):
		return
	await _tap(&"cycle_name")
	_expect(state.name_index == 1, "draft identity changes before fallback save")
	_expect(str(game.get("status_line")).contains("Alex Bennett") and hud.text.contains("MAINTENANCE"), "provisional name changes without crowding the objective display")
	_expect(not str(game.get("status_line")).contains("breaker"), "identity line does not rewind the scene after the seal opens")
	await _tap(&"interact")
	if not _require(state.checkpoint_reached, "fallback reaches checkpoint"):
		return
	_expect(str(game.get("status_line")).contains(State.CHOICE_TEXT[State.PRESS]) and str(game.get("status_line")).ends_with("Next time, tell me what it costs."), "fallback checkpoint displays the selected choice and WOLF's follow-up")
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
	top_card = game.get_node("CanvasLayer/TopBar") as Panel
	hud = game.get_node("CanvasLayer/TopBar/HUD") as Label
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

	# Disclosed risk, but the engineer cranks the bypass instead of signalling WOLF.
	game.call("_new_game")
	game.call("_finish_intro")
	state = game.get("state") as M0State
	var bypass: BypassHandle = game.get("bypass_handle") as BypassHandle
	_expect(int(game.get("bypass_ticks")) == 0 and bypass.ticks == 0 and not bypass.done, "a new run starts with the bypass uncranked")
	await process_frame
	var start_view: Rect2 = game.get_viewport().get_canvas_transform().affine_inverse() * game.get_viewport().get_visible_rect()
	var plate_rect: Rect2 = bypass.bypass_label.get_global_rect()
	_expect(is_equal_approx(bypass.bypass_label.modulate.a, JunctionRoom.edge_alpha(plate_rect, start_view)) and (plate_rect.end.x <= start_view.end.x or bypass.bypass_label.modulate.a < 1.0), "where the opening view cuts the MANUAL BYPASS plate, the plate fades out instead of showing half its name")
	_expect(top_card.visible and hud.text.contains("MAINTENANCE ENGINEER"), "every new run opens on the name card")
	await _tap(&"interact")
	await process_frame
	_expect(float(game.get("name_card_remaining")) == 0.0 and hud.text.contains("MAINTENANCE / LOCKDOWN"), "the first USE skips the name card and the location card follows")
	if not _require(await _walk_to(human, 350.0), "engineer reaches breaker on the disclose-then-bypass route"):
		return
	await _tap(&"interact")
	_expect(str(game.get("status_line")).begins_with("WOLF: That purge takes") and not game.get("waiting_for_choice"), "the stakes line comes before the breaker question on every new run")
	# The relay prompt never shares the screen with the stakes: the hint only offers to go on.
	for _frame in range(200):
		await physics_frame
	_expect(str(game.call("_context_hint")) == "E: continue." and not game.get("waiting_for_choice") and str(game.get("status_line")).begins_with("WOLF: That purge takes"), "with WOLF's stakes up at the breaker the hint offers only to go on, never the relay prompt, and nothing opens the question on a timer")
	await _tap(&"interact")
	_expect(game.get("waiting_for_choice") and str(game.get("status_line")).begins_with("WOLF: That relay's tagged COOLANT FAULT"), "going on from the stakes, WOLF asks about the relay")
	await _tap(&"choice_1")
	await _tap(&"interact")
	if not _require(state.breaker_armed, "breaker arms on the disclose-then-bypass route"):
		return
	# No spot between the relay and the MANUAL BYPASS falls back to "go to the relay".
	var armed_x: float = human.position.x
	var gap_hints: Array[String] = []
	for probe_x: int in range(553, 670, 4):
		human.position.x = probe_x
		var probe_hint: String = str(game.call("_context_hint"))
		if probe_hint != "E: signal WOLF to take the contact.":
			gap_hints.append("%d: %s" % [probe_x, probe_hint])
	human.position.x = armed_x
	_expect(gap_hints.is_empty(), "from the relay's left edge up to the bypass's reach the hint is the relay's own (%s)" % ", ".join(gap_hints))
	if not _require(await _walk_to(human, 700.0), "engineer reaches the bypass after disclosing"):
		return
	await process_frame
	_expect(bypass.bypass_label.modulate.a == 1.0, "in full view the MANUAL BYPASS plate shows whole")
	var ready_x: float = float((game.get_script() as Script).get_script_constant_map()["WOLF_BYPASS_CLEAR_X"])
	_expect(wolf.autonomous_target_x == ready_x and ready_x + M0Actor.WOLF_REACH <= 605.0 - 43.0, "at the bypass on the honest route WOLF waits off the relay, ready to take it, instead of following onto the machine")
	_expect(str(game.call("_context_hint")) == "HOLD E: crank it yourself, or let WOLF take the relay.", "after WOLF offered, the bypass still offers the engineer-only way")
	# Part cranked, letting WOLF take the relay is still on offer, and the hint keeps saying so.
	Input.action_press(&"interact")
	var part_cranked: bool = await _wait_until(func() -> bool: return int(game.get("bypass_ticks")) >= 2, 120)
	Input.action_release(&"interact")
	await physics_frame
	var part_ticks: int = int(game.get("bypass_ticks"))
	_expect(part_cranked and not state.door_open and str(game.call("_context_hint")) == "HOLD E: crank on, %d of 8, or let WOLF take the relay." % part_ticks, "part cranked on the honest route, the hint counts the turns and still offers WOLF the relay")
	Input.action_press(&"interact")
	var cranked: bool = await _wait_until(func() -> bool: return state.door_open, 300)
	Input.action_release(&"interact")
	_expect(cranked and state.route == "fallback" and not game.get("wolf_heading_to_relay") and str(game.get("status_line")).begins_with("The bypass locks over"), "the engineer can crank the bypass even after WOLF offered")
	_expect(wolf.autonomous_target_x == float((game.get_script() as Script).get_script_constant_map()["WOLF_BYPASS_CLEAR_X"]) and game.get("seal_opening"), "WOLF stays off the relay he was not asked to take while the seal the engineer opened slides up")
	_expect(await _wait_until(func() -> bool: return not game.get("seal_opening") and wolf.follow_target == human, 120), "once the seal has landed WOLF follows the engineer again")
	state.reach_checkpoint()
	_expect(state.checkpoint_callback().ends_with("I made my call. You cranked the bypass anyway. I stayed."), "the safe point remembers that WOLF offered and the engineer cranked the bypass anyway")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	# The seal's landing thud has only just started; stop it and let the mixer release it before the
	# game is freed, then give the freed players the same time before quitting.
	(game.get("sfx_bank") as SfxBank).stop_all()
	await create_timer(0.1).timeout
	game.queue_free()
	await create_timer(0.1).timeout
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
