extends "res://tests/support/game_suite.gd"
## Safe-area conversion includes screen scaling/bars; the live HUD and scrollable menus stay inside
## synthetic cutouts at both text-size extremes. Physical mobile insets need separate device checks.


func _run() -> void:
	check_name = "Screen shape"
	for case: Array in [[Vector2i(1280, 720), Vector2i(960, 540), Window.CONTENT_SCALE_ASPECT_EXPAND], [Vector2i(1280, 800), Vector2i(960, 540), Window.CONTENT_SCALE_ASPECT_EXPAND], [Vector2i(2796, 1290), Vector2i(960, 540), Window.CONTENT_SCALE_ASPECT_EXPAND], [Vector2i(2400, 1080), Vector2i(960, 540), Window.CONTENT_SCALE_ASPECT_EXPAND], [Vector2i(2732, 2048), Vector2i(960, 540), Window.CONTENT_SCALE_ASPECT_EXPAND], [Vector2i(5120, 1440), Vector2i(1296, 540), Window.CONTENT_SCALE_ASPECT_KEEP], [Vector2i(1000, 1000), Vector2i(960, 720), Window.CONTENT_SCALE_ASPECT_KEEP]]:
		var config: Dictionary = ScreenShape.window_config(case[0])
		_expect(config["size"] == case[1] and config["aspect"] == case[2], "%s chooses the bounded expansion mode" % case[0])
	_expect(ScreenShape.centre_limits(0, 960, 1200) == Vector2(480, 480), "a view wider than its room stays centred")
	var visible: Rect2 = Rect2(0, 0, 960, 540)
	var safe: Rect2 = Rect2(74, 0, 812, 514)
	var screen: Transform2D = Transform2D(Vector2(2, 0), Vector2(0, 2), Vector2(120, 80))
	_expect(ScreenShape.canvas_safe_rect(visible, screen * safe, screen).is_equal_approx(safe), "safe screen pixels become canvas coordinates after scale and bars")
	_expect(ScreenShape.canvas_safe_rect(visible, Rect2(), screen) == visible, "unavailable safe areas keep the visible canvas")
	_expect(ScreenShape.canvas_safe_rect(visible, Rect2(-100, -100, 2000, 2000), Transform2D.IDENTITY) == visible, "safe areas are clipped to the viewport")
	# A saved/previous window can differ from the default reapplied during Main setup.
	root.size = Vector2i(2732, 2048)
	await frames(2)
	var game: Main = await start_game("screen-shape", keep_running) as Main
	game.call("_new_game")
	game.call("_finish_intro")
	game.touch_enabled = true
	game.settings_menu.mobile = true
	game.screen_shape.safe_rect = safe
	for locale: String in I18n.offered():
		I18n.apply_for_checks(locale)
		for factor: float in [1.0, 2.0]:
			TextSize.factor = factor
			game.call("_apply_text_size")
			await frames(3)
			for control: Control in [game.pause_button, game.touch_left, game.touch_right, game.touch_use, game.debug_tools.debug_button, game.top_card, game.bottom_bar, game.context_hint]:
				_expect(safe.grow(1.0).encloses(control.get_global_rect()), "%s fits the safe rect at %d%%" % [control.name, int(factor * 100)])
			game.call("_ask_relay")
			game.call("_refresh_ui")
			await frames(3)
			for button: Button in [game.touch_choice_1, game.touch_choice_2]:
				_expect(safe.grow(1.0).encloses(button.get_global_rect()), "touch answers fit the safe rect at %d%%" % int(factor * 100))
			game.call("_pause_game")
			await frames(3)
			_expect(safe.encloses(game.menu_panel.get_global_rect()), "Pause fits inside the safe area")
			game.call("_show_settings")
			await frames(3)
			_expect(safe.encloses(game.menu_panel.get_global_rect()), "Settings fits inside the safe area")
			var changed: Rect2 = Rect2(74, 0, 812, 500)
			game.screen_shape.safe_rect = changed
			game.screen_shape.shape_changed.emit(visible, changed)
			await frames(8)
			_expect(paused and changed.encloses(game.menu_panel.get_global_rect()), "safe-area changes relayout Settings while paused")
			game.screen_shape.safe_rect = safe
			game.call("_resume_game")
	TextSize.factor = 1.0
	I18n.apply_for_checks(I18n.FALLBACK)
	await end_game(game)
	finish("Screen shape checks passed")
