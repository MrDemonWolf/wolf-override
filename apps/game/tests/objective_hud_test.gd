extends "res://tests/support/game_suite.gd"
## Goal notifications fit their translated text without changing the introductory identity card.


func _run() -> void:
	check_name = "Objective HUD"
	var game: Main = await start_game("objective-hud", keep_running) as Main
	game.call("_new_game")
	game.call("_refresh_ui")
	_expect(game.intro_active and not game.top_card.visible and not game.context_hint.visible and not game.tutorial_prompt.visible, "the opening keeps routine HUD panels hidden between its lines")
	game.call("_finish_intro")
	await settle(3)
	_expect(game.hud.text.contains("MAINTENANCE ENGINEER") and game.top_card.size.y >= 62.0, "the introductory name card keeps its two-row presentation")
	# This layout fixture begins after the opening words have been read.
	game.call("_drop_box_queue")
	game.status_line = ""
	game.name_card_remaining = 0.0
	game.tutorial_step = 2
	for locale: String in I18n.offered():
		I18n.apply_for_checks(locale)
		for factor: float in [1.0, 2.0]:
			TextSize.factor = factor
			game.call("_apply_text_size")
			game.call("_show_top_card", game.call("_objective_card_message"), Main.OBJECTIVE_CARD_SECONDS)
			game.call("_refresh_ui")
			await settle(3)
			_expect(game.top_card.visible and game.hud.text == HudText.card(str(game.call("_objective"))) and not game.hud.text.contains("\n"), "%s at %d%% shows only the translated current goal" % [locale, int(factor * 100)])
			_expect(game.screen_shape.safe_rect.encloses(game.top_card.get_global_rect()), "goal fits safe canvas at %s %d%%" % [locale, int(factor * 100)])
			_expect(game.hud.size.y >= game.hud.get_line_height() * game.hud.get_line_count(), "wrapped goal text fits its panel at %s %d%%" % [locale, int(factor * 100)])
			await _check_pause_goal(game, locale, factor)
	I18n.apply_for_checks(I18n.FALLBACK)
	TextSize.factor = 1.0
	game.call("_show_top_card", game.call("_objective_card_message"), Main.OBJECTIVE_CARD_SECONDS)
	game.call("_apply_text_size")
	game.call("_refresh_ui")
	await settle(3)
	_expect(game.top_card.size.x < 448.0 and game.top_card.size.y < 62.0, "short goals no longer reserve a large two-row location panel")
	game.call("_interact_breaker")
	game.call("_refresh_ui")
	await settle(3)
	_expect(game.speaker.visible and game.bottom_bar.visible and game.dialogue_continue.visible and not game.context_hint.visible and not game.top_card.visible and not game.tutorial_prompt.visible, "dialogue owns the HUD without routine hints, objectives or tutorial panels")
	_expect(not game.dialogue_continue.get_global_rect().intersects(game.story.get_global_rect()), "the continue cue stays outside translated story text")
	var breaker_label: Label = game.get_node("BreakerLabel") as Label
	_expect(breaker_label.self_modulate.a == 0.0, "ordinary station names do not compete with dialogue")
	_expect(game.bypass_handle.fault_tag.self_modulate.a == 1.0, "the live coolant-fault warning keeps its own visibility")
	var label_point: Vector2 = breaker_label.get_global_transform_with_canvas() * (breaker_label.size * 0.5)
	for target: Tappable in game.world_input.targets:
		if target.id == &"breaker" and "lockdown" in target.chapters:
			_expect(is_inf(target.hit_score(label_point, false)), "a hidden station name does not remain an invisible click target")
	for factor: float in [1.0, 2.0]:
		TextSize.factor = factor
		game.call("_apply_text_size")
		game.call("_refresh_ui")
		await settle(2)
		var name_width: float = ceilf(game.speaker.get_theme_font(&"font").get_string_size(game.speaker.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, TextSize.px(Main.SPEAKER_FONT_SIZE)).x)
		_expect(game.speaker.size.x <= maxf(name_width + Main.DIALOGUE_PADDING.x, game.speaker.get_combined_minimum_size().x) + 1.0, "a short speaker tab fits its own name at %d%%" % int(factor * 100))
	TextSize.factor = 1.0
	game.call("_apply_text_size")
	_expect(not game.bypass_handle.readout.visible, "an idle crank gauge does not float over story dialogue")
	game.hold_use.advance(0.01, true, &"bypass")
	game.world_input.show_station_names(false)
	_expect(game.bypass_handle.readout.visible, "active crank feedback remains visible during dialogue")
	game.hold_use.reset()
	game.world_input.show_station_names(false)
	game.save_error = "Test save failure"
	game.call("_set_dialogue", game.save_error)
	_expect(game.context_hint.visible and game.context_hint_text.text == game.save_error, "save failures remain visible during story dialogue")
	_expect(breaker_label.self_modulate.a == 0.0, "a save failure does not bring unrelated station names back")
	game.save_error = ""
	game.dialogue_cleared = true
	game.call("_refresh_ui")
	await settle(3)
	_expect(game.top_card.visible and not game.bottom_bar.visible, "the deferred goal returns after the story box clears")
	_expect(breaker_label.self_modulate.a == 1.0 and game.bypass_handle.readout.visible, "station names and their gauge return when exploration resumes")
	game.dialogue_cleared = false
	game.state.chapter_id = "junction"
	game.pressure_line.state = &"building"
	game.human.position.x = (PressureLine.VENT_GRATE_MIN_X + PressureLine.VENT_GRATE_MAX_X) * 0.5
	game.call("_set_dialogue", "Test vent warning")
	_expect(game.bottom_bar.visible and game.context_hint.visible, "a live vent warning remains visible over dialogue")
	game.state.chapter_id = "lockdown"
	game.pressure_line.state = &"idle"
	await end_game(game)
	finish("Objective HUD checks passed")


## Native phone Pause reads the current goal after an older notification fades, without advancing play.
## Both sizes and every offered language must keep the goal and Resume together inside the scroll view.
func _check_pause_goal(game: Main, locale: String, factor: float) -> void:
	game.touch_enabled = true
	game.call("_refresh_ui")
	await settle(2)
	game.top_card_tween.custom_step(Main.OBJECTIVE_CARD_SECONDS + Main.TOP_CARD_FADE_SECONDS + 0.1)
	_expect(not game.top_card.visible, "the notification has faded before Pause recall")
	var expected_goal: String = HudText.card(str(game.call("_objective_card_message")))
	var hint: Label = game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/MenuScroll/MenuMargin/MenuList/PauseHint") as Label
	var scroll: ScrollContainer = game.pause_menu.get_node("MenuScroll") as ScrollContainer
	scroll.scroll_vertical = 200
	var position_before: Vector2 = game.human.position
	await tap_touch(game.pause_button.get_global_rect().get_center())
	await settle(3)
	_expect(paused and hint.is_visible_in_tree() and hint.text == expected_goal, "%s %d%%: phone Pause recovers the translated goal after its notification has faded" % [locale, int(factor * 100)])
	_expect(hint.get_index() < game.resume_button.get_index(), "the goal uses the existing hint slot above Resume")
	_expect(game.menu_panel.get_global_rect().encloses(scroll.get_global_rect()), "%s %d%%: the scrolling column stays inside the Pause card" % [locale, int(factor * 100)])
	_expect(scroll.get_global_rect().encloses(hint.get_global_rect()) and scroll.get_global_rect().encloses(game.resume_button.get_global_rect()), "%s %d%%: goal and Resume are immediately visible after stale scroll" % [locale, int(factor * 100)])
	_expect(not hint.get_global_rect().intersects(game.resume_button.get_global_rect()) and hint.size.y >= hint.get_line_height() * hint.get_line_count(), "goal text fits without covering Resume")
	_expect(game.human.position == position_before, "reading the Pause goal does not move the engineer")
	# Refresh while the world is paused, so a newly shown HUD card cannot mask a stale-message bug.
	var armed_before: bool = game.state.breaker_armed
	game.state.breaker_armed = not armed_before
	game.call("_show_pause_hint", true)
	_expect(hint.text == HudText.card(str(game.call("_objective_card_message"))) and hint.text != expected_goal, "Pause context reads the current goal instead of its cached notification")
	game.state.breaker_armed = armed_before
	game.call("_show_pause_hint", true)
	await settle(2)
	await tap_touch(game.resume_button.get_global_rect().get_center())
	_expect(not paused, "the existing Resume button returns to play")
	game.touch_enabled = false
