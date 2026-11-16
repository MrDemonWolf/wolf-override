extends "res://tests/support/game_suite.gd"
## Short station actions keep binding art separate and remain reachable on touch at both text sizes.


## Checks real translated display prompts and native tap activation through the existing dispatcher.
func _run() -> void:
	check_name = "Station prompt"
	var game: Main = await start_game("station-prompt", keep_running) as Main
	game.debug_tools.actions.jump(&"corridor_start")
	game.debug_tools.debug_build = false
	game.set_process(false)
	game.stakes_spoken = true
	game.tutorial_step = 2
	game.name_card_remaining = 0.0
	game.call("_drop_box_queue")
	game.status_line = ""
	for language: String in I18n.offered():
		I18n.apply_for_checks(language)
		for phone: bool in [false, true]:
			root.size = Vector2i(2796, 1290) if phone else Vector2i(1280, 720)
			game.input_mode.kind = InputMode.Kind.TOUCH if phone else InputMode.Kind.CONTROLLER
			await settle(4)
			game.debug_place(100.0, 58.0)
			game.intro_camera.reset_smoothing()
			await settle(3)
			for factor: float in [1.0, 2.0]:
				TextSize.factor = factor
				game.call("_apply_text_size")
				await settle(2)
				# Main is frozen; reproduce its next-frame layout after the camera/viewport updates.
				game.call("_refresh_ui")
				var panel: Rect2 = game.context_hint.get_global_rect()
				_expect(game.station_prompt_target != null and game.station_prompt_target.id == &"purge_display" and game.context_hint.is_visible_in_tree(), "the live display supplies its own prompt: %s" % language)
				_expect(game.context_hint_text.text == String(TranslationServer.translate("Read display")) and not game.context_hint_text.text.contains(ControllerGlyphs.button(&"xbox", JOY_BUTTON_A)), "the translated action contains no embedded key: %s" % language)
				_expect(game.screen_shape.safe_rect.encloses(panel) and not panel.intersects(game.station_prompt_target.prompt_rect()), "the prompt fits safely and clears its plate: %s/%.0f%% phone=%s panel=%s safe=%s anchor=%s" % [language, factor * 100.0, phone, panel, game.screen_shape.safe_rect, game.station_prompt_target.prompt_rect()])
				if phone:
					_expect(not game.context_hint_glyph.visible and not game.touch_use.visible and panel.size.y >= Tappable.TOUCH_MIN, "touch has one action target at least58canvaspx tall")
				else:
					_expect(game.context_hint_glyph.visible and game.context_hint_glyph.accessibility_name == "A" and game.context_hint_text.get_global_rect().position.x >= game.context_hint_glyph.get_global_rect().end.x, "binding art has a readable name and never covers the words")
	I18n.apply_for_checks("en")
	TextSize.factor = 1.0
	game.call("_apply_text_size")
	var point: Vector2 = Tappable.canvas_rect(game.context_hint).get_center()
	await tap_touch(point)
	game.set_process(true)
	await settle(6)
	_expect(game.call("_conversation_active") and not game.human.controlled, "tapping the pill opens the authored display conversation through USE")
	await _check_touch_crank(game)
	await end_game(game)
	finish("Station prompt checks passed")


## Holding the pill uses the real crank and its release path even though the duplicate USE button is hidden.
func _check_touch_crank(game: Main) -> void:
	game.call("_drop_box_queue")
	game.status_line = ""
	game.state.record_choice(M0State.PRESS)
	game.state.arm_breaker()
	game.debug_place(Main.BYPASS_CRANK_X - 2.0, 580.0)
	game.call("_update_gameplay_camera")
	game.intro_camera.reset_smoothing()
	await settle(3)
	game.settings_menu.hold_toggle.button_pressed = false
	game.call("_refresh_ui")
	await settle(4)
	_expect(game.station_prompt_target != null and game.station_prompt_target.id == &"bypass" and game.context_hint_hold.visible and not game.touch_use.visible, "the live touch crank supplies one pill with a HOLD cue")
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.index = 1
	touch.position = Tappable.canvas_rect(game.context_hint).get_center()
	touch.pressed = true
	root.push_input(touch, true)
	_expect(await wait_until(func() -> bool: return game.hold_use.ticks >= 1, 90), "holding the pill advances the actual bypass")
	_expect(game.context_hint.visible and game.context_hint_hold.visible and not game.touch_use.visible, "the active HOLD target survives its timed narration without duplicate USE")
	_expect(Tappable.canvas_rect(game.context_hint).has_point(touch.position), "the held pill remains under the original finger through alignment and narration")
	var drag: InputEventScreenDrag = InputEventScreenDrag.new()
	drag.index = touch.index
	drag.position = touch.position + Vector2(1, 0)
	root.push_input(drag, true)
	_expect(not game.world_input.active.is_empty() and not game.world_input.active["cancelled"], "a small finger adjustment inside the held pill cannot cancel it")
	touch.pressed = false
	root.push_input(touch, true)
	await settle(2)
	var kept: int = game.hold_use.ticks
	await settle(8)
	_expect(not game.hold_use.holding and game.hold_use.ticks == kept, "releasing the pill stops the crank and preserves completed turns")
