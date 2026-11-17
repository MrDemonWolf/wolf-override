extends "res://tests/support/game_suite.gd"
## Controller art coverage, physical mapping, cached prompts, spoken labels and stable font metrics.


## Uses isolated settings and the actual shared font chain; no physical controller is claimed by this test.
func _run() -> void:
	check_name = "Controller glyphs"
	var game: Main = await start_game("controller-glyphs", keep_running) as Main
	var font: Font = load(ControllerGlyphs.FONT_PATH) as Font
	var menu: GameSettings = game.settings_menu
	var bindings: Array[InputEvent] = InputMap.action_get_events(&"interact")
	var keyboard: String = menu.prompt(&"interact", false)
	for family: StringName in ControllerGlyphs.BUTTONS:
		menu.show_controller_family(family)
		var glyph: String = ControllerGlyphs.button(family, JOY_BUTTON_A)
		_expect(menu.prompt(&"interact", true) == glyph, "changing family refreshes an already cached HUD prompt: %s" % family)
		_expect(menu.binding_label(&"interact", "controller").contains(glyph), "binding rows use the same family as the HUD: %s" % family)
		var button: Button = menu.binding_buttons["interact_controller"]
		_expect(not button.tooltip_text.is_empty() and not _has_icons(button.tooltip_text) and not _has_icons(button.accessibility_name), "binding tooltips/accessibility retain readable words: %s" % family)
		_expect(menu.prompt(&"interact", false) == keyboard and InputMap.action_get_events(&"interact") == bindings, "changing presentation preserves keyboard prompts and physical mappings: %s" % family)
		for index: int in ControllerGlyphs.BUTTON_KEYS:
			var icon: String = ControllerGlyphs.button(family, index)
			_expect(icon.length() == 1 and font.has_char(icon.unicode_at(0)), "the registered font contains button %s/%d" % [family, index])
			_expect(not _has_icons(menu.describe_prompts("Use " + icon)), "spoken button feedback expands %s/%d" % [family, index])
		for axis: int in ControllerGlyphs.AXIS_KEYS:
			for direction: float in [-1.0, 1.0]:
				var icon: String = ControllerGlyphs.axis(family, axis, direction)
				if not icon.is_empty():
					_expect(font.has_char(icon.unicode_at(0)) and not _has_icons(menu.describe_prompts(icon)), "axis glyph has a font and spoken fallback: %s/%d/%s" % [family, axis, direction])
	_expect(ControllerGlyphs.button(&"unknown", JOY_BUTTON_A) == ControllerGlyphs.button(&"xbox", JOY_BUTTON_A), "unknown families use the approved Xbox fallback")
	_expect(ControllerGlyphs.button(&"xbox", JOY_BUTTON_GUIDE).is_empty() and ControllerGlyphs.axis(&"xbox", 99, 1.0).is_empty(), "reserved/unmapped inputs retain the caller's textual fallback")
	# These codepoints identify the source font's named B/A glyphs, not SDL's symbolic button names.
	_expect(ControllerGlyphs.button(&"nintendo", JOY_BUTTON_A).unicode_at(0) == 0xE203 and ControllerGlyphs.button(&"nintendo", JOY_BUTTON_B).unicode_at(0) == 0xE201, "Nintendo face letters follow south/east physical positions")
	for code: String in I18n.offered():
		I18n.apply_for_checks(code)
		for path: String in I18n.BASE_FONT_PATHS:
			var base: Font = load(path) as Font
			_expect(base.fallbacks.has(font), "%s retains input glyphs behind %s" % [code, path])
			var with_icons: float = base.get_height(22)
			var saved: Array[Font] = base.fallbacks.duplicate()
			var without: Array[Font] = []
			for fallback: Font in saved:
				if fallback != font:
					without.append(fallback)
			base.fallbacks = without
			var without_icons: float = base.get_height(22)
			base.fallbacks = saved
			_expect(is_equal_approx(with_icons, without_icons), "%s glyph fallback leaves existing line height unchanged" % code)
	I18n.apply_for_checks("en")
	(game.get_node("CanvasLayer/TitleScreen/MenuScroll/MenuMargin/MenuList/SettingsButton") as Button).pressed.emit()
	await settle(12)
	TextSize.factor = 2.0
	game.call("_apply_text_size")
	menu.select_tab(2)
	await settle(4)
	var focused_binding: Button = menu.binding_buttons["interact_controller"]
	focused_binding.grab_focus()
	await settle(8)
	_expect(menu.is_visible_in_tree() and focused_binding.has_focus() and menu.pages[2].get_global_rect().encloses(focused_binding.get_global_rect()), "visible Controls at200percent scrolls the focused binding fully into view")
	game.call("_resume_game")
	TextSize.factor = 1.0
	await end_game(game)
	finish("Controller glyph checks passed")


## Private-use font characters are visual art, never the semantic name passed to assistive applications.
func _has_icons(words: String) -> bool:
	for at: int in words.length():
		if words.unicode_at(at) >= 0xE000 and words.unicode_at(at) <= 0xF8FF:
			return true
	return false
