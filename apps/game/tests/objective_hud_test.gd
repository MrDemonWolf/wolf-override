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
	game.save_error = "Test save failure"
	game.call("_set_dialogue", game.save_error)
	_expect(game.context_hint.visible and game.context_hint_text.text == game.save_error, "save failures remain visible during story dialogue")
	_expect(breaker_label.self_modulate.a == 0.0, "a save failure does not bring unrelated station names back")
	game.save_error = ""
	game.dialogue_cleared = true
	game.call("_refresh_ui")
	await settle(3)
	_expect(game.top_card.visible and not game.bottom_bar.visible, "the deferred goal returns after the story box clears")
	_expect(breaker_label.self_modulate.a == 1.0, "station names return when exploration resumes")
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
