extends "res://tests/support/game_suite.gd"
## Live conversations hold movement/pages until input, survive Pause, and yield to timed action feedback.


## Exercises real pages, input and fallback state with an isolated save; teardown removes the game and files.
func _run() -> void:
	check_name = "Conversation flow"
	var game: Main = await start_game("conversation-flow", keep_running) as Main
	game.call("_new_game")
	game.call("_finish_intro")
	game.call("_drop_box_queue")
	game.stakes_spoken = true
	game.tutorial_step = 2
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
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.position = game.bottom_bar.get_global_rect().get_center()
	touch.pressed = true
	root.push_input(touch, true)
	touch.pressed = false
	root.push_input(touch, true)
	await settle(3)
	_expect(game.dialogue_cleared or game.dialogue_index == 2, "native dialogue touch advances or dismisses the next page")
	await continue_until(game, func() -> bool: return not game.call("_conversation_active"), TALK_FRAMES)
	_expect(game.dialogue_cleared and game.human.controlled and game.state.memory.is_empty(), "the final page releases movement without committing a choice")
	game.call("_converse", line)
	game.call("_tell", line)
	game.call("_sync_dialogue_boxes")
	game.call("_tick_dialogue", 60.0)
	_expect(not game.dialogue_is_conversation and game.human.controlled and game.dialogue_index == 1, "action feedback can replace identical conversation text and keep its timed movement path")
	game.human.position.x = 350.0
	game.call("_speak_stakes")
	await tap(&"interact")
	_expect(game.dialogue_cleared and not game.waiting_for_choice, "reading the risk explanation does not answer or open the next question in the same press")
	await tap(&"interact")
	_expect(game.waiting_for_choice, "a fresh USE opens the existing relay question")
	await tap(&"choice_2")
	_expect(game.state.memory.get("choice_id") == M0State.PRESS and game.call("_conversation_active") and not game.human.controlled, "the refusal response stays player-paced without changing the chosen engineer-only route")
	await continue_until(game, func() -> bool: return not game.call("_conversation_active"), TALK_FRAMES)
	_expect(await wait_until(func() -> bool: return game.human.controlled, 120), "reading WOLF's response gives the engineer movement back")
	await tap(&"interact")
	_expect(game.state.breaker_armed and game.call("_relay_refused"), "a fresh USE arms the breaker with the engineer-only bypass route intact")
	game.call("_converse", line)
	game.state.chapter_id = "junction"
	game.pressure_line.state = &"charged"
	game.call("_converse", line)
	_expect(not game.call("_conversation_active") and game.human.controlled, "even identical dialogue yields movement when a live hazard is present")
	await end_game(game)
	finish("Conversation flow checks passed")
