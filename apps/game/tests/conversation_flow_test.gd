extends "res://tests/support/game_suite.gd"
## Live conversations hold movement/pages until input, survive Pause, and yield to timed action feedback.


## Exercises real pages, input and fallback state with an isolated save; teardown removes the game and files.
func _run() -> void:
	check_name = "Conversation flow"
	_check_bark_placement()
	var game: Main = await start_game("conversation-flow", keep_running) as Main
	# These probes isolate page ownership; dialogue_reveal_test covers Normal and its first-press reveal.
	game.settings_menu.text_speed.select(3)
	game.call("_new_game")
	game.call("_finish_intro")
	game.call("_drop_box_queue")
	game.stakes_spoken = true
	game.tutorial_step = 2
	game.opening_lines_held = false
	game.name_card_remaining = 0.0
	game.debug_place(Main.RELAY_STEP_BACK_X, Main.RELAY_CONTACT_X)
	game.call("_tell", "WOLF: Open. I'm with you.")
	game.call("_refresh_ui")
	var compact_width: float = Main.DIALOGUE_COLUMN_WIDTH * UiTokens.number("dialogue.bark.width-ratio")
	_expect(game.story.get_line_count() <= DialogueBoxes.MAX_ROWS and game.bottom_bar.size.x <= compact_width + Main.DIALOGUE_PADDING.x * 2.0, "a short bark uses the compact column without adding rows")
	game.call("_tell", "WOLF: I've got the contact. Give me a moment.")
	await settle(2)
	game.intro_camera.reset_smoothing()
	await settle(2)
	game.call("_refresh_ui")
	_expect(game.call("_bark_actor") == game.wolf and not game.dialogue_continue.visible and game.human.controlled, "timed WOLF speech anchors to him without a continue cue or movement lock")
	var body: Sprite2D = game.wolf.body_sprite
	var painted: Rect2 = body.get_global_transform_with_canvas() * body.get_rect()
	_expect(game.bottom_bar.get_global_rect().end.y < painted.position.y, "the timed panel stays above WOLF's body")
	var anchored: Vector2 = game.bottom_bar.position
	game.wolf.position.x += 20.0
	game.call("_layout_hud")
	_expect(game.bottom_bar.position.x > anchored.x, "the bark follows its speaker rather than staying in the HUD")
	game.wolf.body_sprite.hide()
	game.call("_refresh_ui")
	_expect(game.call("_bark_actor") == null, "a hidden speaker cannot acquire an on-screen anchor")
	game.wolf.body_sprite.show()
	game.call("_tell", "WOLF: Wait. DIRECTOR: Stop.")
	game.call("_refresh_ui")
	game.dialogue_index = game.dialogue_boxes.size() - 1
	game.call("_refresh_ui")
	_expect(game.speaker.text == "DIRECTOR" and game.call("_bark_actor") == null, "a mixed-speaker message does not attach a remote voice to WOLF")
	var clause: String = "Then we get through maintenance before he reaches that witness."
	game.call("_tell", "%s: %s" % [(game.call("_first_name") as String).to_upper(), clause])
	game.call("_refresh_ui")
	_expect(game.story_words == clause and game.story.get_line_count() <= DialogueBoxes.MAX_ROWS and game.story.size.x > compact_width, "a longer authored clause keeps its words and two readable rows instead of forcing the compact width")


	game.debug_place(game.pointer_use_x(&"purge_display"), game.wolf.position.x)
	await tap(&"interact")
	_expect(game.call("_conversation_active") and not game.human.controlled, "reading the optional purge display holds its important exchange")
	await continue_until(game, func() -> bool: return not game.call("_conversation_active"), TALK_FRAMES)
	var line: String = Main.OPENING_EXCHANGE % str(game.call("_first_name")).to_upper()
	game.call("_converse", line)
	game.call("_refresh_ui")
	_expect(game.dialogue_boxes.size() > 1 and not game.human.controlled and not game.wolf.controlled, "a real multi-speaker conversation stops the engineer and leaves WOLF independent")
	var at_x: float = game.human.position.x
	Input.action_press(&"move_right")
	await frames(3)
	Input.action_release(&"move_right")
	_expect(is_equal_approx(game.human.position.x, at_x), "held movement cannot walk away through a stopped conversation")
	game.call("_tick_dialogue", 60.0)
	_expect(game.dialogue_index == 0 and not game.call("_dialogue_read"), "elapsed reading time neither advances nor marks a conversation read")
	await tap(&"interact")
	_expect(game.dialogue_index == 1 and not game.human.controlled and game.state.memory.is_empty(), "keyboard USE advances a page without activating a station or choosing for the player")
	game.call("_pause_game")
	await tap(&"interact")
	_expect(paused and game.dialogue_index == 1, "Pause keeps the conversation on its current page")
	game.call("_resume_game")
	_expect(not paused and not game.human.controlled, "Resume returns to the same stopped conversation")
	await tap_touch(game.bottom_bar.get_global_rect().get_center())
	_expect(game.dialogue_cleared or game.dialogue_index == 2, "native dialogue touch advances or dismisses the next page")
	await continue_until(game, func() -> bool: return not game.call("_conversation_active"), TALK_FRAMES)
	_expect(game.dialogue_cleared and game.human.controlled and game.state.memory.is_empty(), "the final page releases movement without committing a choice")
	game.call("_converse", line)
	game.call("_tell", line)
	game.call("_sync_dialogue_boxes")
	game.call("_tick_dialogue", 60.0)
	_expect(not game.dialogue_is_conversation and game.human.controlled and game.dialogue_index == 1, "action feedback can replace identical conversation text and keep its timed movement path")
	game.debug_place(game.pointer_use_x(&"breaker"), game.wolf.position.x)
	game.call("_speak_stakes")
	await tap(&"interact", 2)
	_expect(game.dialogue_cleared and not game.waiting_for_choice, "reading the risk explanation does not answer or open the next question in the same press")
	game.call("_sync_dialogue_boxes")
	_expect(game.dialogue_cleared and not game.bottom_bar.visible and game.dialogue_boxes.size() > 1, "returning phone controls reflows the already-cleared warning into more pages")
	var cleared_page: int = game.dialogue_index
	_expect(not game.call("_next_box") and game.dialogue_index == cleared_page, "an already-cleared line cannot consume input by advancing hidden pages")
	await tap(&"interact", 2)
	_expect(game.waiting_for_choice, "a fresh USE opens the existing relay question (x %.1f, controlled %s, conversation %s, line %s)" % [game.human.position.x, game.human.controlled, game.dialogue_is_conversation, game.status_line])
	I18n.apply_for_checks("de")
	TextSize.factor = 2.0
	game.call("_apply_text_size")
	_expect(game.dialogue_boxes.size() > 1, "the German question spans real pages at 200 percent")
	var question_page: int = game.dialogue_index
	game.call("_tick_dialogue", 60.0)
	_expect(game.dialogue_index == question_page, "a question page waits for input after a minute of reading time")
	_expect(game.dialogue_continue.visible, "an unread question page shows its continue cue")
	game.touch_choice_1.grab_focus()
	Input.parse_input_event(controller_button(JOY_BUTTON_A, true))
	await settle(2)
	Input.parse_input_event(controller_button(JOY_BUTTON_A, false))
	await settle(2)
	_expect(game.waiting_for_choice and game.state.memory.is_empty() and game.dialogue_index == question_page + 1, "controller Interact reads exactly one page instead of confirming the focused answer")
	# Rewind this same question to check the polled action path as well as the native controller event.
	game.dialogue_index = question_page
	game.dialogue_age = 0.0
	game.call("_refresh_ui")
	await tap(&"interact")
	_expect(game.waiting_for_choice and game.dialogue_index == question_page + 1, "the Interact action advances a question without selecting an answer")
	for repeat: int in game.dialogue_boxes.size() + 1:
		await tap_touch(game.bottom_bar.get_global_rect().get_center())
	_expect(game.waiting_for_choice and not game.dialogue_cleared and game.dialogue_index == game.dialogue_boxes.size() - 1, "reading a choice question keeps its last page without selecting an answer")
	_expect(not game.dialogue_continue.visible, "the last question page hides the continue cue and leaves the answers available")
	I18n.apply_for_checks(I18n.FALLBACK)
	TextSize.factor = 1.0
	game.call("_apply_text_size")
	await tap(&"choice_2")
	_expect(game.state.memory.get("choice_id") == M0State.PRESS and game.call("_conversation_active") and not game.human.controlled, "the refusal response stays player-paced without changing the chosen engineer-only route")
	await continue_until(game, func() -> bool: return not game.call("_conversation_active"), TALK_FRAMES)
	_expect(await wait_until(func() -> bool: return game.human.controlled, 120), "reading WOLF's response gives the engineer movement back")
	await tap(&"interact")
	_expect(game.state.breaker_armed and game.call("_relay_refused"), "a fresh USE arms the breaker with the engineer-only bypass route intact")
	game.debug_tools.actions.jump(&"safe_point")
	game.debug_place(game.pointer_use_x(&"exit"), game.wolf.position.x)
	await tap(&"interact")
	_expect(game.state.chapter_id == "records" and game.call("_conversation_active") and not game.human.controlled and not game.wolf.controlled, "entering Records holds WOLF's remembered choice without controlling him")
	await continue_until(game, func() -> bool: return not game.call("_conversation_active"), TALK_FRAMES)
	_expect(game.human.controlled and not game.state.purge_trace_preserved, "reading the entry exchange releases movement without copying a source")
	await _check_records(game)
	game.call("_converse", line)
	game.state.chapter_id = "junction"
	game.pressure_line.state = &"charged"
	game.call("_converse", line)
	_expect(not game.call("_conversation_active") and game.human.controlled, "even identical dialogue yields movement when a live hazard is present")
	var hazard_lines: Array[String] = [line, line]
	game.call("_say", hazard_lines, true)
	_expect(not game.call("_conversation_active") and game.human.controlled, "a queued conversation also preserves movement during a live hazard")
	await end_game(game)
	finish("Conversation flow checks passed")


## Copies each source through both existing mirror routes, reading every stopped line before moving on.
## Debug placement isolates the station/read contracts; full_slice_test separately plays the walking routes.
func _check_records(game: Main) -> void:
	for route: String in ["wolf", "manual"]:
		game.debug_tools.actions.jump(&"records_entry")
		game.debug_place(game.pointer_use_x(&"purge"), Main.WOLF_MIRROR_X)
		await tap(&"interact")
		_expect(game.state.purge_trace_preserved and game.call("_conversation_active") and not game.human.controlled, "the purge source is copied before its stopped readout (%s)" % route)
		var page: int = game.dialogue_index
		game.call("_tick_dialogue", 60.0)
		_expect(game.dialogue_index == page, "the source readout cannot time out (%s)" % route)
		await continue_until(game, func() -> bool: return not game.call("_conversation_active"), TALK_FRAMES)
		_expect(game.human.controlled, "reading the source returns movement (%s)" % route)
		game.debug_place(game.pointer_use_x(&"mirror"), Main.WOLF_MIRROR_X)
		await tap(&"interact")
		_expect(game.waiting_for_choice, "the mirror still offers both existing routes (%s)" % route)
		await tap(&"choice_1" if route == "wolf" else &"choice_2")
		_expect(game.state.mirror_trace_preserved and game.state.mirror_route == route and game.call("_conversation_active") and not game.human.controlled, "the chosen mirror result waits to be read (%s)" % route)
		await continue_until(game, func() -> bool: return not game.call("_conversation_active"), TALK_FRAMES)
		_expect(game.human.controlled and not game.wolf.controlled, "reading the mirror result returns engineer control without controlling WOLF (%s)" % route)


## Pure canvas geometry cases cover edges, hidden speakers and blocked/oversized placements without a second layout implementation.
func _check_bark_placement() -> void:
	var safe: Rect2 = Rect2(20.0, 10.0, 900.0, 500.0)
	var body: Rect2 = Rect2(400.0, 300.0, 80.0, 60.0)
	var size: Vector2 = Vector2(260.0, 70.0)
	var placed: Rect2 = DialogueBark.place(size, 24.0, body, safe, [], 12.0)
	_expect(placed.has_area() and safe.encloses(placed) and placed.end.y == 288.0, "a bark fits above its speaker with the authored gap")
	var edge: Rect2 = DialogueBark.place(size, 24.0, Rect2(10.0, 300.0, 40.0, 60.0), safe, [], 12.0)
	_expect(edge.position.x == safe.position.x, "a speaker at the left edge keeps all text inside the safe area")
	var fractional_safe: Rect2 = Rect2(20.4, 10.0, 900.0, 500.0)
	var fractional: Rect2 = DialogueBark.place(size, 24.0, Rect2(10.0, 300.0, 40.0, 60.0), fractional_safe, [], 12.0)
	_expect(fractional.has_area() and fractional_safe.encloses(fractional), "fractional OS insets survive pixel rounding")
	_expect(not DialogueBark.place(size, 24.0, Rect2(-300.0, 300.0, 40.0, 60.0), safe, [], 12.0).has_area(), "an off-screen speaker uses the lower reading position")
	_expect(not DialogueBark.place(size, 24.0, Rect2(400.0, 50.0, 80.0, 60.0), safe, [], 12.0).has_area(), "the name tab cannot be clipped above the safe area")
	_expect(not DialogueBark.place(size, 24.0, body, safe, [safe], 12.0).has_area(), "a warning that leaves no room blocks an anchored placement")
	var neighbour: Rect2 = Rect2(470.0, 230.0, 40.0, 130.0)
	var raised: Rect2 = DialogueBark.place(size, 24.0, body, safe, [neighbour], 12.0)
	_expect(raised.has_area() and raised.end.y <= neighbour.position.y - 12.0, "a taller companion's head stays clear of the bark")
	_expect(not DialogueBark.place(Vector2(1000.0, 70.0), 24.0, body, safe, [], 12.0).has_area(), "oversized text uses the existing bounded reading position")
