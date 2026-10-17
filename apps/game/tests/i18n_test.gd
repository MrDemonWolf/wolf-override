extends "res://tests/support/game_suite.gd"
## Languages: the foundation PR L1 lays (localization plan, research branch codex/localization-research
## at 520cad1, PLAN.md), grown from the scratch prototype's suite (that branch's
## prototype/evidence/game.patch). Only English is offered yet and nothing in the game calls I18n, so
## this suite checks the module itself:
## - the pinned language: scripts/check-game.sh starts every suite with `--language en`, so a Mac set to
##   Spanish or Japanese still runs the English suites in English;
## - the language table (apps/game/i18n/languages.json): D1's twelve files, every field the game reads,
##   and nothing offered whose fonts are not in the build;
## - the OS-locale resolver's explicit table (DESIGN.md, "How Godot picks a file for the system
##   language") and the saved setting;
## - each language's glyphs checked with only its own font chain, and a CJK character planted in a
##   German catalog failing that check (the prototype's check had every fallback on at once);
## - the sibling case: with made-up zh_Hans and zh_Hant catalogs (and es and es_ES), a line only one file
##   of the pair has shows English in the other, and the same lookup with every catalog kept (what an
##   apply() that keeps them all would leave) shows the sibling's text, so the check can fail;
## - a translated template whose inserts differ showing the English line (I18n.shown);
## - the overflow check: one planted overflow for each blind spot the build closes (containers, trimmed
##   text, height), each beside a twin that fits, and the English title judged by it.
## Spawn, waits and teardown come from tests/support/game_suite.gd. Every catalog this suite adds is
## made up here and dropped again with I18n.forget, so no real catalog is touched.

## D1's twelve files (decided October 16, 2026): the table must hold each of them.
const D1_CODES: Array[String] = ["en", "zh_Hans", "zh_Hant", "ru", "es", "es_ES", "pt_BR", "de", "ja", "fr", "ko", "pl"]
## The theme's fonts: the body (Roboto) and the two Montserrat weights the buttons and headings use.
const THEME_FONTS: Array[String] = ["res://assets/fonts/Roboto-Regular.tres", "res://assets/fonts/Montserrat-Semibold.tres", "res://assets/fonts/Montserrat-Bold.tres"]
## The font size the line-height check measures at (px): the dialogue's body size, where the prototype
## measured Roboto's line height growing from 21 to 25 px with a CJK fallback behind it.
const BODY_FONT_PX: int = 17
## Made-up msgids for the sibling case: one both files of a pair translate, one only the first has.
const SIBLING_BOTH: String = "I18N TEST LINE BOTH FILES HAVE"
const SIBLING_ONE: String = "I18N TEST LINE ONLY ONE FILE HAS"
## A long run of wide capitals for the planted overflows: several hundred px on one row at the theme's
## sizes and four rows when wrapped at 200 px, so it outgrows every planted box below by far.
const LONG_TEXT: String = "WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW WWWWWWWWWW"
const SHORT_TEXT: String = "OK"

var _checks: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	check_name = "Languages"
	_check_pinned()
	_check_table()
	_check_resolver()
	_check_saved()
	_check_glyphs()
	_check_sibling(["zh_Hans", "zh_Hant"], ["两条都有", "兩條都有"], "只有简体")
	_check_sibling(["es", "es_ES"], ["ambas la tienen", "ambas la tienen (España)"], "solo Latinoamérica")
	_check_format_guard()
	await _check_planted_overflows()
	await _check_title()
	I18n.apply("en")
	finish("Languages: %d checks passed." % _checks)


## _expect, counting the checks that ran so the pass note can say how many.
func _check(condition: bool, label: String) -> bool:
	_checks += 1
	return _expect(condition, label)


## check-game.sh starts every suite with `--language en`, which overrides the OS locale
## (TranslationServer.setup), so the suites see English on any machine.
func _check_pinned() -> void:
	_check(TranslationServer.get_locale() == "en", "the suite starts pinned to English, as check-game.sh's --language en sets (locale %s, OS %s)" % [TranslationServer.get_locale(), OS.get_locale()])
	_check(I18n.saved(ConfigFile.new()) == "en", "with nothing saved the pinned start-up locale decides: en (got %s)" % I18n.saved(ConfigFile.new()))


## The table holds D1's files, each row has the fields the game reads, English comes first and is
## offered, and nothing is offered whose font chain is incomplete.
func _check_table() -> void:
	var codes: Array = I18n.LANGUAGES.keys()
	_check(not codes.is_empty() and codes[0] == "en", "English is the table's first row (got %s)" % [codes.slice(0, 1)])
	for code: String in D1_CODES:
		_check(I18n.LANGUAGES.has(code), "the table has D1's %s" % code)
	for code: String in codes:
		var row: Dictionary = I18n.LANGUAGES[code]
		_check(row.get("name") is String and not (row["name"] as String).is_empty(), "%s has a picker name" % code)
		_check(row.get("enabled") is bool, "%s says whether it is offered" % code)
		var font: Variant = row.get("fallback_font")
		_check(font == null or (font is String and (font as String).begins_with("res://assets/fonts/")), "%s's fallback font is none or a bundled font (got %s)" % [code, font])
		var cps: Variant = row.get("reading_cps")
		_check(cps == null or (cps is float and cps > 0.0), "%s's reading speed is unset or positive (got %s)" % [code, cps])
		var row_characters: Variant = row.get("row_characters")
		_check(row_characters == null or (row_characters is float and row_characters > 0.0), "%s's row limit is unset or positive (got %s)" % [code, row_characters])
		if not bool(row.get("source", false)):
			_check(row.get("review") in ["machine", "reviewed"], "%s has a review state (got %s)" % [code, row.get("review")])
	var offered: PackedStringArray = I18n.offered()
	_check(not offered.is_empty() and offered[0] == "en", "English is offered first (offered: %s)" % [offered])
	for code: String in offered:
		_check(I18n.font_chain_complete(code), "%s is offered only once its fallback font is in the build" % code)


## The OS locale goes through the explicit table to an offered language, else English. Checked twice:
## against every language in the table (the table itself), and against what is offered now.
func _check_resolver() -> void:
	var every: PackedStringArray = PackedStringArray(I18n.LANGUAGES.keys())
	var cases: Dictionary = {
		"es_MX": "es", "es_AR": "es", "es_US": "es", "es-419": "es", "es_419": "es", "es": "es", "es_ES": "es_ES",
		"pt_PT": "pt_BR", "pt": "pt_BR", "pt_BR": "pt_BR", "pt_AO": "pt_BR",
		"zh_CN": "zh_Hans", "zh_SG": "zh_Hans", "zh": "zh_Hans", "zh_Hans": "zh_Hans",
		"zh_TW": "zh_Hant", "zh_HK": "zh_Hant", "zh_MO": "zh_Hant", "zh_Hant": "zh_Hant", "zh-Hant-HK": "zh_Hant",
		"fr_CA": "fr", "fr_BE": "fr", "fr_CH": "fr", "fr_FR": "fr", "de_AT": "de", "de": "de",
		"ja_JP": "ja", "ko_KR": "ko", "pl_PL": "pl", "ru_RU": "ru", "ru_KZ": "ru",
		"en_GB": "en", "en_AU": "en", "en_US": "en",
		"uk_UA": "uk", "nn_NO": "en", "no": "en", "sv_SE": "en", "": "en",
	}
	for locale: String in cases:
		var got: String = I18n.resolve(locale, every)
		_check(got == cases[locale], "with every language offered, %s resolves to %s (got %s)" % [locale, cases[locale], got])
	_check(I18n.resolve("uk_UA", every) != "ru", "a Ukrainian locale never resolves to Russian")
	_check(I18n.resolve("uk_UA", PackedStringArray(["en", "ru"])) == "en", "a Ukrainian locale shows English while Ukrainian is not offered")
	_check(I18n.resolve("nn", PackedStringArray(["en", "nb"])) == "nb", "Norwegian Nynorsk goes to the Bokmål file once it exists")
	_check(I18n.resolve("es_ES", PackedStringArray(["en", "es"])) == "es", "Spain gets the Latin-American file while Spain's is not offered")
	var offered: PackedStringArray = I18n.offered()
	for locale: String in cases:
		var got: String = I18n.resolve(locale)
		_check(offered.has(got), "with %s offered, %s resolves to an offered language (got %s)" % [offered, locale, got])
		if offered.has(cases[locale]):
			_check(got == cases[locale], "with %s offered, %s resolves to %s (got %s)" % [offered, locale, cases[locale], got])


## A saved language wins over the start-up locale, but only an offered one; anything else is resolved.
func _check_saved() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(I18n.CONFIG_SECTION, I18n.CONFIG_KEY, "en_GB")
	_check(I18n.saved(config) == "en", "a saved en_GB resolves to en (got %s)" % I18n.saved(config))
	for code: String in I18n.LANGUAGES:
		config.set_value(I18n.CONFIG_SECTION, I18n.CONFIG_KEY, code)
		var expected: String = code if I18n.offered().has(code) else I18n.resolve(code)
		_check(I18n.saved(config) == expected, "a saved %s gives %s (got %s)" % [code, expected, I18n.saved(config)])
	config.set_value(I18n.CONFIG_SECTION, I18n.CONFIG_KEY, 3)
	_check(I18n.saved(config) == "en", "a saved value that is not a code falls back to the start-up locale")


## Every language's own text (its picker name, its machine-translation tag and every line of its
## registered catalogs) drawn by the theme fonts with only that language's fallback behind them;
## Font.has_char never asks the OS's fonts. Languages whose fallback font is not in the build yet
## (the CJK subsets, PR L4) are checked to be unoffered instead. Latin and Cyrillic chain nothing, so
## their line height stays English's. Then the planted case: a German catalog holding a CJK character
## must fail the same check.
func _check_glyphs() -> void:
	var roboto: Font = load(THEME_FONTS[0]) as Font
	I18n.apply("en")
	var english_height: float = roboto.get_height(BODY_FONT_PX)
	for code: String in I18n.LANGUAGES:
		if not I18n.font_chain_complete(code):
			_check(not I18n.offered().has(code), "%s is not offered while its font %s is missing" % [code, I18n.LANGUAGES[code]["fallback_font"]])
			continue
		I18n.apply(code)
		var text: String = _language_text(code, [])
		for path: String in THEME_FONTS:
			var missing: String = I18n.missing_glyphs(text, load(path) as Font)
			_check(missing.is_empty(), "%s: %s draws all of %s with its own chain; missing: %s" % [code, path.get_file(), text.c_escape(), missing])
		if I18n.LANGUAGES[code]["fallback_font"] == null:
			_check(roboto.get_height(BODY_FONT_PX) == english_height, "%s chains no fallback, so lines keep English's height (%.0f px)" % [code, roboto.get_height(BODY_FONT_PX)])
	var planted: Translation = Translation.new()
	planted.locale = "de"
	planted.add_message(SIBLING_BOTH, "Grüße aus 日本")
	I18n.apply("de")
	var missing_planted: String = I18n.missing_glyphs(_language_text("de", [planted]), load(THEME_FONTS[0]) as Font)
	_check(missing_planted == "日本", "a CJK character in a German catalog fails German's own chain (missing: %s)" % missing_planted)
	I18n.apply("en")


## The text [param code] must draw: its picker name, its machine-translation tag, and every message of
## the catalogs registered for it plus [param extra] (made-up catalogs).
func _language_text(code: String, extra: Array[Translation]) -> String:
	var row: Dictionary = I18n.LANGUAGES[code]
	var text: String = str(row["name"])
	if row.get("machine_tag") is String:
		text += row["machine_tag"]
	var catalogs: Array[Translation] = TranslationServer.get_translations()
	catalogs.append_array(extra)
	for catalog: Translation in catalogs:
		if catalog.locale == code:
			for message: StringName in catalog.get_translated_message_list():
				text += String(message)
	return text


## [param pair] is two files of one language ([param words] their translations of SIBLING_BOTH); only
## the first has SIBLING_ONE, as [param only_first]. At the second language the gap must show English
## and only that language's catalog may be registered; with every catalog registered again (what an
## apply() that kept them all would leave) the gap shows the first file's text, so the check above
## fails on such an apply(). At the first language its own line shows.
func _check_sibling(pair: Array[String], words: Array[String], only_first: String) -> void:
	var first: Translation = Translation.new()
	first.locale = pair[0]
	first.add_message(SIBLING_BOTH, words[0])
	first.add_message(SIBLING_ONE, only_first)
	var second: Translation = Translation.new()
	second.locale = pair[1]
	second.add_message(SIBLING_BOTH, words[1])
	TranslationServer.add_translation(first)
	TranslationServer.add_translation(second)
	I18n.apply(pair[1])
	_check(TranslationServer.translate(SIBLING_BOTH) == words[1], "%s shows its own line (got %s)" % [pair[1], TranslationServer.translate(SIBLING_BOTH)])
	_check(TranslationServer.translate(SIBLING_ONE) == SIBLING_ONE, "a line only %s has shows English at %s (got %s)" % [pair[0], pair[1], TranslationServer.translate(SIBLING_ONE)])
	_check(not TranslationServer.get_translations().has(first), "%s's catalog is unregistered at %s" % [pair[0], pair[1]])
	TranslationServer.add_translation(first)
	_check(TranslationServer.translate(SIBLING_ONE) == only_first, "negative control: with every catalog kept, the %s gap shows %s's text (got %s)" % [pair[1], pair[0], TranslationServer.translate(SIBLING_ONE)])
	I18n.apply(pair[0])
	_check(TranslationServer.translate(SIBLING_ONE) == only_first and not TranslationServer.get_translations().has(second), "at %s its own line shows and %s's catalog is unregistered" % [pair[0], pair[1]])
	I18n.apply("en")
	_check(TranslationServer.translate(SIBLING_BOTH) == SIBLING_BOTH, "back in English the made-up line is English")
	I18n.forget(first)
	I18n.forget(second)


## A formatted line whose translation has other inserts than its English shows the English line rather
## than raising a script error (I18n.shown), and a matching translation is still used. The two msgids
## are made up here and live only in a catalog that is dropped again.
func _check_format_guard() -> void:
	var broken: String = "I18N GUARD CHECK %s of %d"
	var fine: String = "I18N GUARD FINE %s"
	var extra: Translation = Translation.new()
	extra.locale = "de"
	extra.add_message(broken, "I18N GUARD PRÜFUNG %d")
	extra.add_message(fine, "I18N GUARD GUT %s")
	TranslationServer.add_translation(extra)
	I18n.apply("de")
	var english: String = I18n.format(broken, ["A", 3])
	_check(I18n.shown(english, []) == "I18N GUARD CHECK A of 3", "a translation with other inserts shows the English line (got %s)" % I18n.shown(english, []))
	_check(I18n.shown(I18n.format(fine, ["A"]), []) == "I18N GUARD GUT A", "a translation with the same inserts is used (got %s)" % I18n.shown(I18n.format(fine, ["A"]), []))
	I18n.forget(extra)
	I18n.apply("en")


## One planted overflow for each blind spot of the prototype's check, each beside a twin that fits:
## - a Label in an HBoxContainer whose designed width it outgrows (the container grows instead);
## - a trimming Label, a clipping Button and a trimming Label inside a container (Settings' rows) whose
##   text is cut;
## - an autowrap Label that grows below its designed height, one that grows off the viewport's bottom
##   from a zero-height layout, and one that hides rows (max_lines_visible).
## The neighbour blind spot is text_boxes_test's (see I18n.overflows).
func _check_planted_overflows() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	root.add_child(layer)
	var bottom: float = root.get_visible_rect().size.y
	var cases: Array[Array] = []
	for text: String in [LONG_TEXT, SHORT_TEXT]:
		var long: bool = text == LONG_TEXT
		var box: HBoxContainer = HBoxContainer.new()
		_place(box, layer, Rect2(20, 20, 200, 40))
		var in_box: Label = Label.new()
		in_box.text = text
		box.add_child(in_box)
		cases.append([in_box, long, "a Label in a container 200 px wide"])
		var trimmed: Label = Label.new()
		trimmed.text = text
		trimmed.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_place(trimmed, layer, Rect2(20, 80, 160, 30))
		cases.append([trimmed, long, "a trimming Label 160 px wide"])
		var clipped: Button = Button.new()
		clipped.text = text
		clipped.clip_text = true
		_place(clipped, layer, Rect2(20, 300, 160, 80))
		cases.append([clipped, long, "a clipping Button 160 px wide"])
		var row: HBoxContainer = HBoxContainer.new()
		_place(row, layer, Rect2(20, 170, 300, 30))
		var caption: Label = Label.new()
		caption.text = "CAPTION"
		row.add_child(caption)
		var value: Label = Label.new()
		value.text = text
		value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(value)
		cases.append([value, long, "a trimming Label in a Settings-like row"])
		var tall: Label = Label.new()
		tall.text = text
		tall.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_place(tall, layer, Rect2(400, 20, 200, 40))
		cases.append([tall, long, "an autowrap Label 40 px tall"])
		var low: Label = Label.new()
		low.text = text
		low.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_place(low, layer, Rect2(640 if long else 400, bottom - 40.0, 200, 0))
		cases.append([low, long, "an autowrap Label laid out at zero height 40 px above the viewport's bottom"])
		var capped: Label = Label.new()
		capped.text = text
		capped.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		capped.max_lines_visible = 1
		_place(capped, layer, Rect2(400, 120 if long else 200, 200, 0))
		cases.append([capped, long, "an autowrap Label showing one row"])
	await frames(3)
	for entry: Array in cases:
		var control: Control = entry[0]
		var long: bool = entry[1]
		var found: bool = I18n.overflows(control)
		_check(found == long, "%s with %s %s (size %s)" % [entry[2], "long text overflows" if long else "short text fits", "and the check finds it" if found == long else "but the check says %s" % found, control.size])
	layer.queue_free()
	await frames(1)


## Adds [param control] to [param parent] at [param rect] (px) through its anchors and offsets, as a
## scene lays out a Control, so I18n.designed_rect reads that rect back.
func _place(control: Control, parent: Node, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y
	parent.add_child(control)


## The real title in English, judged by the build's check: its buttons, the Brand line and the CONTINUE
## note (shown only while there is no save, which start_game guarantees) all fit, so the check finds no
## overflow where the game shows none.
func _check_title() -> void:
	var game: Main = await start_game("i18n-test") as Main
	game.auto_pause_on_focus_loss = false
	await frames(3)
	var controls: Array[Control] = [game.new_game_button, game.continue_button, game.credits_button, game.changelog_button, game.get_node("CanvasLayer/TitleScreen/SettingsButton") as Button, game.get_node("CanvasLayer/TitleScreen/Brand") as Label, game.continue_note]
	_check(game.continue_note.is_visible_in_tree(), "the CONTINUE note is up on a fresh title, so it is judged")
	for control: Control in controls:
		_check(not I18n.overflows(control), "the English title's %s fits (size %s)" % [str(control.get("text")).c_escape(), control.size])
	await end_game(game)
