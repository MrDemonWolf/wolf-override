class_name I18n
extends RefCounted
## The game's languages: the one place that knows which languages exist, which one the game shows and
## how a line reaches the screen translated. Built in PR L1 of the localization plan (research branch
## codex/localization-research at 520cad1, docs/research-2026-10/localization/DESIGN.md and PLAN.md),
## from the scratch prototype's version (that branch's prototype/evidence/game.patch). Since PR L6
## Settings applies the saved language at start-up and offers the LANGUAGE list (GameSettings), which
## stays hidden while only English is offered; the game's text is marked in L7, so until then only
## English exists and nothing changes on screen.
##
## The rule: English stays the game's internal text. Constants, status_line, saves, comparisons and the
## tests keep the English words, and text is translated only where it is drawn, in one of three ways:
## - A Control whose whole text is one message keeps Godot's auto-translate (scene buttons, Settings
##   captions): it is given the English and translates itself, also when the language changes.
## - Text worked out every frame (hints, prompts) calls tr() where it is worked out; a template is
##   translated first and filled after (tr(TEMPLATE) % key).
## - Text kept between frames (status_line, the top card, a knockdown card) stays English and is
##   translated where it is drawn, by [method shown] and [method lines]; its Label has auto-translate
##   off, so nothing is translated twice.
## Why: code compares English text (key tokens, speaker tags, the speaker's colour, end-card topics,
## DialogueBoxes' sentence rules) and the save stores the English choice, so translating at the source
## would break all of them and every test that asserts English.
##
## Godot's POT generator extracts only tr()/tr_n()/atr()/atr_n() calls whose argument reduces to a
## constant, plus scene text and literal .text assignments. English that is stored first and translated
## later is marked with [code]I18n.KEY.tr(TEXT)[/code]: KEY is an object with message translation off,
## so the call returns TEXT unchanged, but the generator still sees a tr() of a constant and extracts
## it (Godot 4.7.2 modules/gdscript/editor/gdscript_translation_parser_plugin.cpp matches the called
## method's name only).
##
## Gotchas:
## - Static functions cannot call tr() (a parse error) and a const initialiser cannot either, so the
##   statics here use TranslationServer.translate(), which the generator does not extract: never pass
##   them a literal that is not also marked somewhere with tr() or KEY.tr().
## - A formatted line ("... %s ...") can only be translated from its template, so lines with inserts are
##   built with [method format], which remembers the template and the inserts for [method shown].

## The language table, read once from this file into [member LANGUAGES]. It lives inside the project
## so the export carries it (both presets export all resources, which in Godot 4.7.2 includes .json
## files: measured with --export-pack, "Storing File: res://i18n/languages.json"); the i18n tools read
## the same file.
const TABLE_PATH: String = "res://i18n/languages.json"
## The language when the OS asks for one the game does not offer. project.godot's
## internationalization/locale/fallback says the same to Godot.
const FALLBACK: String = "en"
## The game's two font files. Every FontVariation in the theme uses one of them as its base, and a
## FontVariation with no fallbacks of its own uses its base font's, so a fallback put behind these two
## reaches every themed Control.
const BASE_FONT_PATHS: Array[String] = ["res://assets/fonts/Roboto-Variable.ttf", "res://assets/fonts/Montserrat-Variable.ttf"]
## The settings file's section and key for the chosen language (absent: follow the start-up locale).
const CONFIG_SECTION: String = "general"
const CONFIG_KEY: String = "language"
## Metadata name set (true) on a Control whose text is written in its own language and never translated:
## the language list's names and tags (GameSettings). The pseudolocalization audit (scripts/parity/
## capture.gd) does not count such text as untranslated, while Controls whose auto-translate is off for
## other reasons (lines I18n.shown translates) are still checked.
const OWN_LANGUAGE_META: StringName = &"i18n_own_language"
## Pixels a measured size may exceed its room by before [method overflows] calls it an overflow: text
## widths are fractional and Controls round their sizes, so an exact fit can measure up to a pixel over.
const OVERFLOW_TOLERANCE_PX: float = 1.0

## Every language the table knows, by Godot locale code ("en", "es", "zh_Hant"), in the picker's order,
## each a row of languages.json ("name", "enabled", "review", "machine_tag", "fallback_font",
## "picker_font", "reading_cps", "row_characters" and the tools' fields; the file's "_about" explains
## each). Read-only:
## the game never changes it. Only rows with "enabled" true are offered (see [method offered]).
static var LANGUAGES: Dictionary = _load_table()
## Extraction marker: KEY.tr(TEXT) returns TEXT untranslated (see the class notes).
static var KEY: Object = _make_key()
## Template and inserts of every line built with [method format], by the finished English line. It is
## never pruned: the game formats a few dozen distinct lines (names times knockdown reasons), not an
## unbounded stream.
static var _formats: Dictionary = {}
## One printf conversion as String % reads it (core/string/ustring.cpp sprintf, 4.7.2): flags, a width
## or *, a precision or .*, then the type letter; "%%" is matched too so it can be skipped as a literal.
static var _conversion: RegEx = RegEx.create_from_string("%%|%[-+ 0#]*(\\*|\\d+)?(\\.(\\*|\\d+))?[scdoxXfv]")
## Every catalog [method apply] has seen registered, so one it unregistered for another language can
## be registered again. Godot loads project.godot's internationalization/locale/translations at start-up;
## anything added later with TranslationServer.add_translation joins at the next apply().
static var _catalogs: Array[Translation] = []


## Reads [constant TABLE_PATH] into the code-to-row Dictionary [member LANGUAGES] holds. A missing or
## broken file pushes an error (which fails every headless suite, since check-game.sh treats ERROR
## lines as failures) and leaves a table with English alone, so a player's game still runs.
static func _load_table() -> Dictionary:
	var english: Dictionary = {FALLBACK: {"name": "English", "enabled": true, "fallback_font": null, "reading_cps": 20, "row_characters": 42, "source": true}}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TABLE_PATH))
	if not parsed is Dictionary or not (parsed as Dictionary).get("languages") is Dictionary:
		push_error("I18n: %s is missing or is not a language table; only English is offered" % TABLE_PATH)
		return english
	var table: Dictionary = (parsed as Dictionary)["languages"]
	if not table.has(FALLBACK):
		push_error("I18n: %s has no %s row; only English is offered" % [TABLE_PATH, FALLBACK])
		return english
	return table


## The object behind [member KEY]: translation turned off, so its tr() hands back its argument.
static func _make_key() -> Object:
	var key: RefCounted = RefCounted.new()
	key.set_message_translation(false)
	return key


## The codes of the languages the game offers ("enabled" in the table), in the picker's order. English
## always comes first: it is the source and the fallback.
static func offered() -> PackedStringArray:
	var codes: PackedStringArray = []
	for code: String in LANGUAGES:
		if bool((LANGUAGES[code] as Dictionary).get("enabled", false)):
			codes.append(code)
	return codes


## The language the table sends [param locale] to (any OS, saved or typed locale such as "es_MX",
## "es-419", "zh_HK" or "pt_PT"), before asking whether the game offers it. One explicit table, as
## ConPaws' resolveDeviceLocale does, so Godot's tie order never decides (DESIGN.md, "How Godot picks a
## file for the system language"):
## - Spanish is Latin America ("es") unless the region is Spain ("es_ES"); "es-419" standardises to "es".
## - Portuguese is Brazil's ("pt_BR"): the only Portuguese file.
## - Chinese goes by script, then region: Hant, TW, HK and MO to "zh_Hant", the rest to "zh_Hans".
## - Norwegian ("no", "nn", "nb") goes to "nb" (a later tier).
## - Every other language is its own code ("uk" stays "uk", so Ukrainian never becomes Russian).
static func table_language(locale: String) -> String:
	var parts: PackedStringArray = TranslationServer.standardize_locale(locale).split("_", false)
	if parts.is_empty():
		return ""
	var language: String = parts[0]
	var script: String = ""
	var region: String = ""
	for part: String in parts.slice(1):
		if part.length() == 4:
			script = part
		elif region.is_empty():
			region = part
	match language:
		"es":
			return "es_ES" if region == "ES" else "es"
		"pt":
			return "pt_BR"
		"zh":
			return "zh_Hant" if script == "Hant" or (script.is_empty() and region in ["TW", "HK", "MO"]) else "zh_Hans"
		"no", "nn", "nb":
			return "nb"
	return language


## The offered language for [param locale]: [method table_language]'s answer when it is in
## [param offered_codes] (default [method offered]); otherwise the offered language Godot's
## compare_locales scores highest against it (above 0, so the same language: es_ES finds "es" when
## Spain's file is not offered), the first in table order on a tie; otherwise [constant FALLBACK].
## Tests pass every code of [member LANGUAGES] to check the table itself.
static func resolve(locale: String, offered_codes: PackedStringArray = offered()) -> String:
	var wanted: String = table_language(locale)
	if offered_codes.has(wanted):
		return wanted
	var best: String = FALLBACK
	var best_score: int = 0
	for code: String in offered_codes:
		var score: int = TranslationServer.compare_locales(wanted if not wanted.is_empty() else locale, code)
		if score > best_score:
			best = code
			best_score = score
	return best


## The language in [param config] (Settings' file, [general] language), or when none was chosen the
## locale Godot started in: the OS's (OS.get_locale()), unless `--language xx` or
## internationalization/locale/test set another (TranslationServer.setup), so tests and captures can
## pin a language. Always an offered code (see [method resolve]).
static func saved(config: ConfigFile) -> String:
	var value: Variant = config.get_value(CONFIG_SECTION, CONFIG_KEY, "")
	return resolve(value if value is String and not (value as String).is_empty() else TranslationServer.get_locale())


## Switches the game to [param code]: puts that language's fallback font (and only that one) behind the
## game fonts, keeps only that language's catalogs registered, then sets TranslationServer's locale,
## which notifies every node (NOTIFICATION_TRANSLATION_CHANGED) so auto-translating Controls redraw.
## A code [member LANGUAGES] lacks goes through [method resolve] first; a known code is applied even
## when it is not offered, so tests can switch to a language before its PR turns it on.
##
## Why only one language's catalogs: Godot looks a line up in every registered catalog whose locale
## shares the language (core/string/translation_domain.cpp, get_message_from_translations, 4.7.2), so
## with zh_Hans and zh_Hant both registered a line zh_Hant lacks shows Simplified Chinese, and with es
## and es_ES the other Spanish. With one registered, a gap shows the English line.
static func apply(code: String) -> void:
	var language: String = code if LANGUAGES.has(code) else resolve(code)
	use_fallback(language)
	_register_only(language)
	TranslationServer.set_locale(language)


## Registers with TranslationServer every known catalog whose locale is [param language] and removes
## every other one, first adding the catalogs registered now to [member _catalogs].
static func _register_only(language: String) -> void:
	for catalog: Translation in TranslationServer.get_translations():
		if not _catalogs.has(catalog):
			_catalogs.append(catalog)
	var registered: Array[Translation] = TranslationServer.get_translations()
	for catalog: Translation in _catalogs:
		var wanted: bool = TranslationServer.standardize_locale(catalog.locale) == language
		if wanted and not registered.has(catalog):
			TranslationServer.add_translation(catalog)
		elif not wanted and registered.has(catalog):
			TranslationServer.remove_translation(catalog)


## Drops [param catalog] from the catalogs [method apply] manages and from TranslationServer, for a
## catalog that should never come back (the tests' made-up catalogs).
static func forget(catalog: Translation) -> void:
	_catalogs.erase(catalog)
	TranslationServer.remove_translation(catalog)


## Puts [param language]'s fallback font behind the game's font files and takes every other language's
## off. Only while that language is on, because Font.get_height() is the tallest font of the whole
## chain: with Noto Sans JP behind it, Roboto's line height grew from 21 to 25 px at 17 px (measured,
## Godot 4.7.2), which moved every Latin label. Changing a Font's fallbacks emits its changed signal, so
## every Control using it lays itself out again. Fallbacks that belong to no language stay where they
## are (Roboto's Montserrat-Symbols-Subset.ttf, set in its import, which draws the arrows and the empty
## square Roboto lacks). A fallback file that is not in the build is skipped with a warning.
static func use_fallback(language: String) -> void:
	var others: Array[Font] = []
	for code: String in LANGUAGES:
		var font: Font = fallback_font(code) if code != language else null
		if font != null:
			others.append(font)
	var own: Font = fallback_font(language)
	if own == null and not font_chain_complete(language):
		push_warning("I18n: the %s fallback font is not in the build: %s" % [language, _row(language)["fallback_font"]])
	for path: String in BASE_FONT_PATHS:
		var base: Font = load(path) as Font
		if base == null:
			continue
		var chain: Array[Font] = []
		for font: Font in base.fallbacks:
			if not others.has(font) and font != own:
				chain.append(font)
		if own != null:
			chain.append(own)
		if chain != base.fallbacks:
			base.fallbacks = chain


## The language list's own font (DESIGN.md, "Settings: the LANGUAGE option"): a copy of [param base]
## (the list's FontVariation, Settings' Montserrat Semibold) whose own fallbacks are every language's
## "picker_font", in table order. A FontVariation with fallbacks of its own uses them instead of its
## base font's, so this chain never holds the fallback [method use_fallback] puts behind the game fonts,
## and the game fonts never hold these: 日本語, 한국어, 简体中文 and 繁體中文 and their tags draw in every
## language, and no Latin line grows (each picker font has Montserrat's vertical metrics, so the list's
## rows keep their height too; tests/i18n_test.gd checks both).
## Gotcha: a fallback chain is searched character by character in order, so a character two names
## share (中, 文, 器, 翻, 機) is drawn by the first picker font that has it; Godot 4.7.2's text server
## did not prefer a fallback by the run's language (measured with language support overrides set), so
## the order is the table's and the shared characters' shapes differ only slightly between the regions.
## A picker font that is not in the build is skipped; the glyph test then fails.
static func picker_font(base: FontVariation) -> FontVariation:
	var font: FontVariation = base.duplicate() as FontVariation
	var chain: Array[Font] = []
	for code: String in LANGUAGES:
		var path: Variant = _row(code).get("picker_font")
		if path is String and ResourceLoader.exists(path as String):
			chain.append(load(path as String) as Font)
	font.fallbacks = chain
	return font


## The short "machine translation" tag of [param language], written in that language, while its row's
## review state is "machine" (PIPELINE.md, "Honest labelling"); "" once it is "reviewed", for the source
## language, for an unknown code and while the research has given the language no tag (null).
static func machine_tag(language: String) -> String:
	var row: Dictionary = _row(language)
	var tag: Variant = row.get("machine_tag")
	return tag as String if row.get("review") == "machine" and tag is String else ""


## The bundled fallback font of [param language] ("fallback_font" in its row), or null when it has none
## or the file is not in the build.
static func fallback_font(language: String) -> Font:
	var path: Variant = _row(language).get("fallback_font")
	if not path is String or not ResourceLoader.exists(path as String):
		return null
	return load(path as String) as Font


## True when every font [param language] needs is in the build: it has no fallback font, or its
## fallback file exists. A language whose chain is incomplete must not be offered (tests/i18n_test.gd).
static func font_chain_complete(language: String) -> bool:
	var path: Variant = _row(language).get("fallback_font")
	return not path is String or ResourceLoader.exists(path as String)


## [param language]'s row of [member LANGUAGES], or an empty Dictionary for an unknown code.
static func _row(language: String) -> Dictionary:
	return LANGUAGES.get(language, {}) as Dictionary


## [param template] % [param inserts], remembering both so [method shown] can translate the template
## and fill it again. The result is the English line, used as status_line as before.
static func format(template: String, inserts: Array) -> String:
	var line: String = template % inserts
	_formats[line] = [template, inserts]
	return line


## [param line] as the player reads it in the current language. A line built with [method format] is
## its translated template filled with the same inserts; any other line is translated piece by piece
## where a speaker's tag in [param speakers] starts ("DIRECTOR: ...\nWOLF: ..."), so the tags stay
## English and outside the translated text. A piece with no translation stays English. The speaker
## pieces are a stopgap until speaker and words are stored apart (DESIGN.md, PR L7c).
static func shown(line: String, speakers: Array[String]) -> String:
	if _formats.has(line):
		var entry: Array = _formats[line]
		return _filled(String(TranslationServer.translate(entry[0])), entry[0], entry[1])
	var out: PackedStringArray = []
	for row: String in line.split("\n"):
		var tag: String = DialogueBoxes.tag_of(row, speakers)
		if tag.is_empty() and not out.is_empty():
			# A row with no tag goes on the message above it (an authored line break inside it).
			out[out.size() - 1] += "\n" + row
		else:
			out.append(row)
	for index: int in out.size():
		var tag: String = DialogueBoxes.tag_of(out[index], speakers)
		var words: String = DialogueBoxes.words_of(out[index], speakers)
		var translated: String = String(TranslationServer.translate(words))
		out[index] = translated if tag.is_empty() else "%s: %s" % [tag, translated]
	return "\n".join(out)


## [param template] (English, with % conversions) in the current language, filled with [param inserts]:
## the one way text built in code from a translated template is filled (Settings' note, key and button
## names, Pause's hint), so each has [method _filled]'s guard. A template with fewer than two letters
## ([method has_words], such as "%s %s") is not translated, so pseudolocalization does not pad it. Mark a
## literal passed here with KEY.tr(), since the template generator does not look inside this call. With no
## [param inserts] the translated template is returned as it is, unfilled.
static func fill(template: String, inserts: Array) -> String:
	var translated: String = String(TranslationServer.translate(template)) if has_words(template) else template
	if inserts.is_empty():
		# Nothing to fill: a message such as a save error may hold a lone "%", which % would reject.
		return translated
	return _filled(translated, template, inserts)


## [param translated] % [param inserts], or [param template] (its English) % [param inserts] when the
## translation's conversions differ from the English ones ([method _inserts]). Shared by [method shown]
## and [method fill].
static func _filled(translated: String, template: String, inserts: Array) -> String:
	if _inserts(translated) != _inserts(template):
		# A shipped translation whose inserts differ would make % raise a script error and the text would
		# not draw. The PO gates (msgfmt --check-format, i18n_tool.py check) stop that before a build; this
		# keeps a gap in them to one English line instead of a broken box or a blank note.
		push_warning("I18n: the %s translation of %s has other inserts; showing English" % [TranslationServer.get_locale(), template.c_escape()])
		return template % inserts
	return translated % inserts


## The printf conversions of [param template] in order, each reduced to what % takes from the
## inserts: one "*" per star width or precision, then the type letter ("%02d" and "%d" are both "d").
## A literal "%%" takes nothing and is left out. Used by [method shown] to compare a translation with its
## English template.
static func _inserts(template: String) -> PackedStringArray:
	var found: PackedStringArray = []
	for match: RegExMatch in _conversion.search_all(template):
		var token: String = match.get_string()
		if token != "%%":
			found.append("*".repeat(token.count("*")) + token.right(1))
	return found


## True when [param text] has at least two letters, so it holds a word a translation can change: not a
## lone symbol such as ◀, a number, or a one-letter key or button name ("E", "A"), which every language
## writes the same way and pseudolocalization has nothing to pad. One rule for the game and the tools:
## Settings translates a key or button name only when this holds (GameSettings), and the parity capture's
## pseudo audit counts only such text as untranslated (scripts/parity/capture.gd). A letter is a character
## with an upper and a lower case, so CJK text counts only through its Latin letters (none of the names
## this is asked about are CJK).
static func has_words(text: String) -> bool:
	var letters: int = 0
	for character: String in text:
		if character.to_upper() != character.to_lower():
			letters += 1
	return letters >= 2


## [param text] with each of its lines translated on its own (the top card's location and objective).
static func lines(text: String) -> String:
	var out: PackedStringArray = []
	for row: String in text.split("\n"):
		out.append(String(TranslationServer.translate(row)))
	return "\n".join(out)


## The characters of [param text] that [param font] and its fallbacks cannot draw, each once (line
## breaks and spaces skipped). Font.has_char never asks the OS's fonts, so "" means no tofu on any
## machine. Shared by tests/i18n_test.gd, [method game_fonts_draw] and, from PR L2, the parity
## capture's language audit.
static func missing_glyphs(text: String, font: Font) -> String:
	var missing: String = ""
	for character: String in text:
		if character != "\n" and character != " " and not font.has_char(character.unicode_at(0)) and not missing.contains(character):
			missing += character
	return missing


## True when both game font files ([constant BASE_FONT_PATHS], which every themed FontVariation uses as
## its base) and their current fallbacks can draw every character of [param text]
## ([method missing_glyphs]). Since PR L4 the fonts never ask the OS for a missing character, so a
## character this rejects would draw as an empty box. Used by GameSettings.key_label_name to keep a
## keyboard layout's Greek, Hebrew, Arabic or Thai letter off the screen. A font file missing from the
## build is skipped.
static func game_fonts_draw(text: String) -> bool:
	for path: String in BASE_FONT_PATHS:
		var font: Font = load(path) as Font
		if font != null and not missing_glyphs(text, font).is_empty():
			return false
	return true


## True when [param control] cannot show all of its text as laid out. Call it on a settled frame with
## the control visible; a hidden control never overflows. It closes the prototype check's three blind
## spots (DESIGN.md, "The prototype's overflow check has four blind spots"):
## - Containers: a Control inside a Container is judged by its outermost Container, since a Container
##   grows to hold its children instead of letting them overrun.
## - Trimmed or clipped text whose whole string needs more width than the Control has is an overflow,
##   not a fit: a translation cut to "…" hides words.
## - Both axes: the judged Control may outgrow neither the width nor the height its anchors and offsets
##   give it (each checked only where it gives one: a Control laid out at zero size sizes itself), nor
##   leave the viewport; an autowrap Label that grows downward is caught, and one that hides rows too.
## The fourth blind spot, two Controls that each fit but cover each other, is not checked here on
## purpose: tests/text_boxes_test.gd already intersects the rects that matter, and PR L8 runs those
## checks in every language instead of a second overlap check.
## Units: px in the control's canvas, with [constant OVERFLOW_TOLERANCE_PX] of slack.
static func overflows(control: Control) -> bool:
	if not control.is_visible_in_tree():
		return false
	var judged: Control = outermost_container(control)
	var designed: Rect2 = designed_rect(judged)
	if designed.size.x > 0.0 and judged.size.x > designed.size.x + OVERFLOW_TOLERANCE_PX:
		return true
	if designed.size.y > 0.0 and judged.size.y > designed.size.y + OVERFLOW_TOLERANCE_PX:
		return true
	if not judged.get_viewport_rect().grow(OVERFLOW_TOLERANCE_PX).encloses(judged.get_global_rect()):
		return true
	return text_cut(control)


## The Control [method overflows] judges [param control] by: its outermost Container ancestor in an
## unbroken chain of Containers, or the control itself when its parent is not a Container.
static func outermost_container(control: Control) -> Control:
	var judged: Control = control
	while judged.get_parent() is Container:
		judged = judged.get_parent() as Control
	return judged


## The rect [param control]'s anchors and offsets give it in its parent's area (px, relative to the
## parent), before it grows to its minimum size. Only meaningful outside a Container, which ignores
## anchors and offsets.
static func designed_rect(control: Control) -> Rect2:
	var area: Vector2 = control.get_parent_area_size()
	var left: float = control.anchor_left * area.x + control.offset_left
	var top: float = control.anchor_top * area.y + control.offset_top
	var right: float = control.anchor_right * area.x + control.offset_right
	var bottom: float = control.anchor_bottom * area.y + control.offset_bottom
	return Rect2(left, top, right - left, bottom - top)


## True when [param control] hides part of its own text: a Label with more rows than it shows; a Label
## or Button that clips or trims its text while the whole text needs more width than it has; or a
## RichTextLabel with no scroll bar whose content is taller than it is. The whole text's width is the
## control's own minimum width with clipping and trimming switched off for the measurement, so its own
## font, size, LabelSettings, upper-casing, style margins, icon and OptionButton arrow all count (a bare
## Font.get_string_size would miss the last five). Gotcha: the two properties are set back at once, but
## each change emits minimum_size_changed, so a Container parent sorts again on the next frame, to the
## same layout.
static func text_cut(control: Control) -> bool:
	if control is RichTextLabel:
		var rich: RichTextLabel = control as RichTextLabel
		return not rich.scroll_active and not rich.fit_content and rich.get_content_height() > rich.size.y + OVERFLOW_TOLERANCE_PX
	if control is Label:
		var label: Label = control as Label
		if label.get_visible_line_count() < label.get_line_count():
			return true
		if label.autowrap_mode != TextServer.AUTOWRAP_OFF:
			return false
	elif not control is Button:
		return false
	var clip: bool = bool(control.get("clip_text"))
	var overrun: int = int(control.get("text_overrun_behavior"))
	if not clip and overrun == TextServer.OVERRUN_NO_TRIMMING:
		return false
	control.set("clip_text", false)
	control.set("text_overrun_behavior", TextServer.OVERRUN_NO_TRIMMING)
	var needed: float = control.get_minimum_size().x
	control.set("clip_text", clip)
	control.set("text_overrun_behavior", overrun)
	return needed > control.size.x + OVERFLOW_TOLERANCE_PX
