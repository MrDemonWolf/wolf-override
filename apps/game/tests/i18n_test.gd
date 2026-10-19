extends "res://tests/support/game_suite.gd"
## Languages: the foundation PR L1 lays (localization plan, research branch codex/localization-research
## at 520cad1, PLAN.md), grown from the scratch prototype's suite (that branch's
## prototype/evidence/game.patch). Only English is offered yet and nothing in the game calls I18n, so
## this suite checks the module itself:
## - the pinned language: scripts/check-game.sh starts every suite with `--language en`, so a Mac set to
##   Spanish or Japanese still runs the English suites in English;
## - the language table (apps/game/i18n/languages.json): D1's twelve files, every field the game reads,
##   and nothing offered whose fonts are not in the build;
## - the shipped catalogs (PR L2): the offered translated languages, the .po files in res://i18n/ and
##   project.godot's internationalization/locale/translations are the same set of codes, so no language
##   is offered without its file and no file ships without being offered;
## - the OS-locale resolver's explicit table (DESIGN.md, "How Godot picks a file for the system
##   language") and the saved setting;
## - each language's glyphs checked with only its own font chain, and a CJK character planted in a
##   German catalog failing that check (the prototype's check had every fallback on at once);
## - the bundled fonts (PR L4): no font asks the OS for a missing glyph, each CJK subset draws its whole
##   fixed character list (decision D7) and nothing outside it, the subsets and the line-breaking data
##   stay inside D7's size budget, every character the game's English text uses is drawn by every theme
##   font, and Roboto's symbols fallback leaves its line height alone;
## - the language list (PR L6): its own font chain (I18n.picker_font) draws every language's name and
##   "machine translation" tag in every language, holds none of the game fonts' language fallbacks, keeps
##   the list's row height, and the game font alone cannot draw the CJK names (the check can fail); each
##   picker font holds only its own name and tag; I18n.machine_tag follows the review state;
## - the sibling case: with made-up zh_Hans and zh_Hant catalogs (and es and es_ES), a line only one file
##   of the pair has shows English in the other, and the same lookup with every catalog kept (what an
##   apply() that keeps them all would leave) shows the sibling's text, so the check can fail;
## - a translated template whose inserts differ showing the English line (I18n.shown);
## - the overflow check: one planted overflow for each blind spot the build closes (containers, trimmed
##   text, height), each beside a twin that fits;
## - the HUD's key prompts (PR L7b): HudText keeps the English line, fills the translated template's key
##   tokens after tr(), uses a line's touch form on touch and guards a broken translation; and in a game,
##   the hint, tutorial, top card, touch USE button and the opening's CONTINUE prompt in another language,
##   with CONTINUE's touch-button context kept apart from the title's, and the top card drawn again in
##   English when the language changes back;
## - every offered language laid out in the game (PR L9): the title, credits, changelog, Settings, Pause,
##   the touch buttons and the station names at every TEXT SIZE step fit, and the names stand apart.
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
## The folder holding the shipped catalogs, beside languages.json: one <code>.po per offered language.
const CATALOG_DIR: String = "res://i18n"
## The fonts folder: every .ttf and .otf in it is checked to have the OS fallback off.
const FONT_DIR: String = "res://assets/fonts"
## Each CJK subset's fixed character list, written with the subsets by `scripts/i18n/i18n_tool.py fonts`.
const CHARSETS_PATH: String = "res://tests/support/cjk_charsets.json"
## A character no subset may draw: U+3400, the first of CJK Extension A, which none of the four common
## sets holds. Its absence shows Font.has_char reads the subset alone and that the list check can fail.
const OUTSIDE_EVERY_SET: String = "\u3400"
## Decision D7 (DECISIONS.md, decided October 16, 2026): fixed common-character subsets, "about 4-5 MB"
## for the four fonts and "about 9-10 MB" once Godot's line-breaking data joins them. The budgets are
## the top of each range, in bytes (decimal MB, as the plan measures the .pck).
const CJK_FONT_BUDGET_BYTES: int = 5_000_000
const CJK_TOTAL_BUDGET_BYTES: int = 10_000_000
## icudt_godot.dat, the line-breaking data an export adds once any CJK catalog is registered (measured,
## DESIGN.md "Line breaking"; scripts/get-export-templates.sh unpacks and checks it, PR L3). Not under
## res://, so the size is recorded here rather than read.
const ICU_DATA_BYTES: int = 4_797_472
## Where the game's English text lives: every string literal of these folders' scripts and scenes is
## scanned for characters the theme fonts must draw (the tests and add-ons are not game text).
const TEXT_DIRS: Array[String] = ["res://scripts", "res://scenes"]
## Roboto's own file: the line-height check compares it, with its symbols fallback, to a bare copy.
const ROBOTO_FILE: String = "res://assets/fonts/Roboto-Variable.ttf"

var _checks: int = 0
## English's layout of each control [method _check_fit] judges, by "<where>|<node path>": whether
## I18n.overflows found an overflow, the judged Control's size and the one-row width (px). Filled by the
## English pass of [method _check_layouts], which runs first (I18n.offered puts English first).
var _english_fit: Dictionary = {}


func _run() -> void:
	check_name = "Languages"
	_check_pinned()
	_check_table()
	_check_catalogs()
	_check_resolver()
	_check_saved()
	_check_glyphs()
	_check_fonts()
	_check_picker()
	_check_english_glyphs()
	_check_sibling(["zh_Hans", "zh_Hant"], ["两条都有", "兩條都有"], "只有简体")
	_check_sibling(["es", "es_ES"], ["ambas la tienen", "ambas la tienen (España)"], "solo Latinoamérica")
	_check_format_guard()
	await _check_planted_overflows()
	_check_key_prompts()
	await _check_hud()
	await _check_layouts()
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


## Every offered language but the source (English, which has no catalog) has its catalog
## (CATALOG_DIR/<code>.po), and project.godot registers exactly those catalogs: the three lists hold the
## same codes. Turning a language on in languages.json without its file, adding a file without turning
## it on (its text could still reach players through the OS locale, since Godot loads every registered
## catalog), or forgetting the project.godot entry all fail here. Every .po must also be a language of
## the table (i18n_tool.py check stops on one that is not).
func _check_catalogs() -> void:
	var offered: Array[String] = []
	for code: String in I18n.offered():
		if not bool((I18n.LANGUAGES[code] as Dictionary).get("source", false)):
			offered.append(code)
	var files: Array[String] = []
	for file: String in DirAccess.get_files_at(CATALOG_DIR):
		if file.get_extension() == "po":
			files.append(file.get_basename())
	var registered: Array[String] = []
	for path: String in ProjectSettings.get_setting("internationalization/locale/translations", PackedStringArray()):
		registered.append(path.get_file().get_basename())
	offered.sort()
	files.sort()
	registered.sort()
	_check(files == offered, "the .po files in %s are the offered translated languages (files %s, offered %s)" % [CATALOG_DIR, files, offered])
	_check(registered == offered, "project.godot registers the offered translated languages' catalogs (registered %s, offered %s)" % [registered, offered])
	for code: String in files:
		_check(I18n.LANGUAGES.has(code), "the catalog %s.po is a language of the table" % code)


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
## Font.has_char never asks the OS's fonts. A language whose fallback font is not in the build is
## checked to be unoffered instead. Latin and Cyrillic chain nothing, so
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


## The bundled fonts (PR L4). Every font file has the OS fallback off (its import's
## allow_system_fallback), so a missing glyph is tofu on every device alike and these glyph checks are
## the whole truth. Each CJK subset draws every character of its fixed list (cjk_charsets.json), the list
## holds the language's picker name and tag, and the subset lacks OUTSIDE_EVERY_SET (the planted miss).
## The four subsets, alone and with the line-breaking data, stay inside D7's budgets.
func _check_fonts() -> void:
	for file: String in DirAccess.get_files_at(FONT_DIR):
		if file.get_extension() in ["ttf", "otf"]:
			var font_file: FontFile = load(FONT_DIR.path_join(file)) as FontFile
			_check(font_file != null and not font_file.allow_system_fallback, "%s never asks the OS for a missing glyph" % file)
	var charsets: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(CHARSETS_PATH)) as Dictionary)["charsets"]
	var font_bytes: int = 0
	for code: String in I18n.LANGUAGES:
		var path: Variant = I18n.LANGUAGES[code]["fallback_font"]
		if path == null:
			continue
		var subset: Font = I18n.fallback_font(code)
		_check(subset != null, "%s's subset %s is in the build" % [code, path])
		_check(charsets.has(code), "%s has a fixed character list in %s" % [code, CHARSETS_PATH])
		if subset == null or not charsets.has(code):
			continue
		var wanted: String = charsets[code]
		var missing: String = I18n.missing_glyphs(wanted, subset)
		_check(missing.is_empty(), "%s's subset draws all %d characters of its list; missing: %s" % [code, wanted.length(), missing])
		var own: String = str(I18n.LANGUAGES[code]["name"]) + str(I18n.LANGUAGES[code]["machine_tag"])
		var not_listed: String = ""
		for character: String in own.replace(" ", "").split("", false):
			if not wanted.contains(character):
				not_listed += character
		_check(not_listed.is_empty(), "%s's list holds its picker name and tag (%s); not listed: %s" % [code, own, not_listed])
		_check(I18n.missing_glyphs(OUTSIDE_EVERY_SET, subset) == OUTSIDE_EVERY_SET, "%s's subset lacks U+3400, outside every common set (planted miss)" % code)
		font_bytes += FileAccess.get_file_as_bytes(path as String).size()
		var picker: Variant = I18n.LANGUAGES[code].get("picker_font")
		if picker is String:
			font_bytes += FileAccess.get_file_as_bytes(picker as String).size()
	_check(font_bytes > 0 and font_bytes <= CJK_FONT_BUDGET_BYTES, "the CJK subsets total %d B, within D7's %d B" % [font_bytes, CJK_FONT_BUDGET_BYTES])
	_check(font_bytes + ICU_DATA_BYTES <= CJK_TOTAL_BUDGET_BYTES, "the CJK subsets and line-breaking data total %d B, within D7's %d B" % [font_bytes + ICU_DATA_BYTES, CJK_TOTAL_BUDGET_BYTES])


## The language list's own font chain (PR L6; DESIGN.md, "Settings: the LANGUAGE option"). Every name and
## every tag of the table, not only the offered ones, is drawn by I18n.picker_font over the list's font
## (Montserrat Semibold, THEME_FONTS[1]) in English and in each language whose fonts are in the build,
## since the chain must not depend on the fallback I18n.use_fallback puts behind the game fonts; that
## fallback never joins the list's chain. The planted miss: the list's font without its own chain lacks
## the CJK names. The picker fonts have Montserrat's vertical metrics, so the list's rows keep their
## height at the list's sizes, and each holds its own name and tag and nothing of another CJK name.
func _check_picker() -> void:
	var base: FontVariation = load(THEME_FONTS[1]) as FontVariation
	var list_font: FontVariation = I18n.picker_font(base)
	var text: String = ""
	for code: String in I18n.LANGUAGES:
		text += str(I18n.LANGUAGES[code]["name"])
		if I18n.LANGUAGES[code].get("machine_tag") is String:
			text += I18n.LANGUAGES[code]["machine_tag"]
	I18n.apply("en")
	_check(I18n.missing_glyphs(text, base) != "", "planted miss: the list's font without its own chain cannot draw the CJK names (missing: %s)" % I18n.missing_glyphs(text, base))
	for code: String in I18n.LANGUAGES:
		if not I18n.font_chain_complete(code):
			continue
		I18n.apply(code)
		var missing: String = I18n.missing_glyphs(text, list_font)
		_check(missing.is_empty(), "at %s the language list draws every name and tag (%s); missing: %s" % [code, text, missing])
		var game_fallback: Font = I18n.fallback_font(code)
		_check(game_fallback == null or not list_font.fallbacks.has(game_fallback), "at %s the game fonts' fallback stays out of the list's chain" % code)
	I18n.apply("en")
	for px: int in [12, 14, 16, 20]:
		_check(list_font.get_height(px) == base.get_height(px), "the list's chain keeps Montserrat's row height at %d px (%.0f, bare %.0f)" % [px, list_font.get_height(px), base.get_height(px)])
	var names: Array[String] = []
	for code: String in I18n.LANGUAGES:
		if I18n.LANGUAGES[code].get("picker_font") is String:
			names.append(str(I18n.LANGUAGES[code]["name"]))
	for code: String in I18n.LANGUAGES:
		var path: Variant = I18n.LANGUAGES[code].get("picker_font")
		if not path is String:
			continue
		var own: Font = load(path as String) as Font
		var row: Dictionary = I18n.LANGUAGES[code]
		var own_text: String = (str(row["name"]) + str(row["machine_tag"])).replace(" ", "")
		_check(own != null and I18n.missing_glyphs(own_text, own).is_empty(), "%s's picker font draws its name and tag %s" % [code, own_text])
		for other: String in names:
			if other != row["name"]:
				var foreign: String = ""
				for character: String in other.split("", false):
					if not own_text.contains(character):
						foreign += character
				_check(own != null and I18n.missing_glyphs(foreign, own) == foreign, "%s's picker font holds nothing of %s but shared characters" % [code, other])
	_check(I18n.machine_tag("es") == "traducción automática" and I18n.machine_tag("ja") == "機械翻訳", "an unreviewed language's tag is its own words (es %s, ja %s)" % [I18n.machine_tag("es"), I18n.machine_tag("ja")])
	_check(I18n.machine_tag("en") == "" and I18n.machine_tag("it") == "" and I18n.machine_tag("xx") == "", "English, a language with no tag yet and an unknown code show no tag")
	var spanish: Dictionary = I18n.LANGUAGES["es"]
	spanish["review"] = "reviewed"
	_check(I18n.machine_tag("es") == "", "a reviewed language loses its tag (got %s)" % I18n.machine_tag("es"))
	spanish["review"] = "machine"


## Every character of the game's English (each string literal in TEXT_DIRS' .gd and .tscn files, code
## comments left out) drawn by every theme font in English, where no language fallback is chained. Before
## PR L4 the OS fallback hid the arrows and the empty square Roboto lacks; now Roboto chains
## Montserrat-Symbols-Subset.ttf for them, so this fails when new text needs a character no theme font
## has. That fallback's vertical metrics match Roboto's, so Roboto's line height must equal a bare copy's
## at a spread of sizes from 12 to 40 px, unlike the 21 to 25 px a CJK fallback causes.
func _check_english_glyphs() -> void:
	I18n.apply("en")
	var literal: RegEx = RegEx.create_from_string("\"((?:[^\"\\\\\n]|\\\\.)*)\"")
	var characters: String = ""
	for dir: String in TEXT_DIRS:
		for path: String in _files_under(dir, ["gd", "tscn"]):
			for line: String in FileAccess.get_file_as_string(path).split("\n"):
				var code: String = line.get_slice("#", 0) if path.ends_with(".gd") else line
				for found: RegExMatch in literal.search_all(code):
					for character: String in found.get_string(1).split("", false):
						if character.unicode_at(0) > 0x7E and not characters.contains(character):
							characters += character
	_check(characters.contains("\u25b6"), "the scan finds the touch arrow ▶ in the game's text (found %s)" % characters)
	for path: String in THEME_FONTS:
		var missing: String = I18n.missing_glyphs(characters, load(path) as Font)
		_check(missing.is_empty(), "%s draws every character of the game's English (%s); missing: %s" % [path.get_file(), characters, missing])
	var roboto: Font = load(ROBOTO_FILE) as Font
	var bare: FontFile = FontFile.new()
	bare.data = FileAccess.get_file_as_bytes(ROBOTO_FILE)
	for px: int in [12, 14, 16, 17, 20, 23, 28, 40]:
		_check(roboto.get_height(px) == bare.get_height(px), "Roboto with its symbols fallback keeps its own line height at %d px (%.0f, bare %.0f)" % [px, roboto.get_height(px), bare.get_height(px)])


## Every file under [param dir] (at any depth) whose extension is in [param extensions], as res:// paths.
func _files_under(dir: String, extensions: Array[String]) -> Array[String]:
	var found: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() in extensions:
			found.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		found.append_array(_files_under(dir.path_join(sub), extensions))
	return found


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
## than raising a script error (I18n.shown, and I18n.fill for text built in code), and a matching
## translation is still used. The two msgids are made up here and live only in a catalog that is dropped
## again.
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
	_check(I18n.fill(broken, ["A", 3]) == "I18N GUARD CHECK A of 3" and I18n.fill(fine, ["A"]) == "I18N GUARD GUT A", "I18n.fill shares the guard (got %s, %s)" % [I18n.fill(broken, ["A", 3]), I18n.fill(fine, ["A"])])
	_check(I18n.fill("I18N GUARD 100% DONE", []) == "I18N GUARD 100% DONE", "I18n.fill with nothing to fill leaves a lone % alone")
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


## The made-up "es" catalog of the HUD checks: key templates (one with turn counts), the held form, a
## touch form, an objective and location, the name card, the tutorial, CONTINUE with and without the
## touch button's context, and one broken translation whose conversion differs from the English.
func _hud_catalog() -> Translation:
	var catalog: Translation = Translation.new()
	catalog.locale = "es"
	catalog.add_message("%s: talk to WOLF about the relay.", "%s: habla con WOLF del relé.")
	catalog.add_message("%s: crank the manual bypass, %d of %d.", "%s: gira el bypass manual, %d de %d.")
	catalog.add_message("HOLD %s", "MANTÉN %s")
	catalog.add_message("The safe point could not save. Press %s here again.", "No se pudo guardar. Pulsa %s otra vez aquí.")
	catalog.add_message("The safe point could not save. Tap USE here again.", "No se pudo guardar. Toca USAR otra vez aquí.")
	catalog.add_message("%s: save at the safe point.", "%d: guarda en el punto seguro.")
	catalog.add_message("CHECK THE BREAKER", "REVISA EL DISYUNTOR")
	catalog.add_message("MAINTENANCE / LOCKDOWN", "MANTENIMIENTO / CIERRE")
	catalog.add_message("%s\nMAINTENANCE ENGINEER", "%s\nMANTENIMIENTO")
	catalog.add_message("%s  MOVE", "%s  MOVER")
	catalog.add_message("USE", "USAR")
	catalog.add_message("CONTINUE", "CONTINUAR")
	catalog.add_message("CONTINUE", "SEGUIR", Main.TOUCH_BUTTON_CONTEXT)
	catalog.add_message("%s  CONTINUE", "%s  SEGUIR")
	return catalog


## HudText on its own (PR L7b): a key line keeps its English ("E: ...", "HOLD E: ...") for the code and
## tests that compare it, and in another language draws the translated template with each token filled
## by the input's shown name after tr(); a String insert that reads like a token is left alone; a line
## with a touch form reads it on touch; a translation with other conversions shows the English template
## filled with the shown key; a plain line is translated only when asked.
func _check_key_prompts() -> void:
	var catalog: Translation = _hud_catalog()
	TranslationServer.add_translation(catalog)
	var talk: String = HudText.key("%s: talk to WOLF about the relay.", [HudText.USE])
	var crank: String = HudText.key("%s: crank the manual bypass, %d of %d.", [HudText.HOLD_USE, 3, 8])
	var save: String = HudText.key("The safe point could not save. Press %s here again.", [HudText.USE], "The safe point could not save. Tap USE here again.")
	var broken: String = HudText.key("%s: save at the safe point.", [HudText.USE])
	var named: String = HudText.key("%s waits.", ["E"])
	_check(talk == "E: talk to WOLF about the relay." and crank == "HOLD E: crank the manual bypass, 3 of 8." and save == "The safe point could not save. Press E here again." and named == "E waits.", "key lines keep the English the game compared before (%s; %s; %s)" % [talk, crank, save])
	I18n.apply("es")
	var keys: Dictionary = {HudText.USE: "F", HudText.HOLD_USE: I18n.fill("HOLD %s", ["F"])}
	_check(HudText.localise(talk, keys, false) == "F: habla con WOLF del relé.", "the translated template gets the key after tr() (%s)" % HudText.localise(talk, keys, false))
	_check(HudText.localise(crank, keys, false) == "MANTÉN F: gira el bypass manual, 3 de 8.", "the held key and the turn counts fill the translated template (%s)" % HudText.localise(crank, keys, false))
	_check(HudText.localise(save, keys, false) == "No se pudo guardar. Pulsa F otra vez aquí." and HudText.localise(save, keys, true) == "No se pudo guardar. Toca USAR otra vez aquí.", "a line with a touch form reads it on touch and the key form elsewhere (%s; %s)" % [HudText.localise(save, keys, false), HudText.localise(save, keys, true)])
	_check(HudText.localise(broken, keys, false) == "F: save at the safe point.", "a translation with other conversions shows the English template with the shown key (%s)" % HudText.localise(broken, keys, false))
	_check(HudText.localise(named, keys, false) == "E waits.", "a String insert that reads like the key token is not taken for it (%s)" % HudText.localise(named, keys, false))
	_check(HudText.localise("CHECK THE BREAKER", keys, false) == "REVISA EL DISYUNTOR" and HudText.localise("CHECK THE BREAKER", keys, false, false) == "CHECK THE BREAKER", "a plain line is translated, or left as it is when asked")
	I18n.forget(catalog)
	I18n.apply("en")


## The HUD in a game (PR L7b), with [method _hud_catalog] for "es": in the opening the touch button's
## CONTINUE reads its own context's word while the title's CONTINUE keeps another, and the first box's
## prompt fills its key into the translated template; in play the top card, the tutorial and the hint
## (keyboard, then touch, where the key is the USE button's word) are translated, and switching back to
## English draws the top card in English again at once (NOTIFICATION_TRANSLATION_CHANGED).
func _check_hud() -> void:
	var catalog: Translation = _hud_catalog()
	TranslationServer.add_translation(catalog)
	var game: Main = await start_game("i18n-hud") as Main
	game.auto_pause_on_focus_loss = false
	game.call("_new_game")
	await process_frame
	I18n.apply("es")
	await process_frame
	var hint: Label = game.get_node("CanvasLayer/ContextHint/Text") as Label
	_check(game.touch_use.text == "SEGUIR" and String(TranslationServer.translate("CONTINUE")) == "CONTINUAR", "the touch button's CONTINUE has its own context, apart from the title's (%s)" % game.touch_use.text)
	_check(hint.text.begins_with("E  SEGUIR\n"), "the opening's first prompt fills its key into the translated template (%s)" % hint.text.c_escape())
	game.call("_finish_intro")
	await process_frame
	game.call("_refresh_ui")
	var first_name: String = game.state.human_name().to_upper()
	_check(game.hud.text == "%s\nMANTENIMIENTO" % first_name and game.hud.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED, "the name card translates its template and keeps the name (%s)" % game.hud.text.c_escape())
	var tutorial: Label = game.get_node("CanvasLayer/TutorialPrompt/Text") as Label
	_check(tutorial.text.begins_with("A / D  MOVER"), "the tutorial fills its keys into the translated template (%s)" % tutorial.text.c_escape())
	I18n.apply("en")
	_check(game.hud.text == "%s\nMAINTENANCE ENGINEER" % first_name, "a language change draws the top card again in English at once (%s)" % game.hud.text.c_escape())
	I18n.apply("es")
	# Past the tutorial, which takes the hint bar's place while it shows.
	game.tutorial_step = 2
	game.human.position.x = 350.0
	game.call("_refresh_ui")
	if _check(str(game.call("_context_hint")) == "E: talk to WOLF about the relay.", "at the breaker the hint is still the English line (%s)" % game.call("_context_hint")):
		_check(hint.text == "E: habla con WOLF del relé.", "the hint draws translated with the key (%s)" % hint.text)
		game.touch_enabled = true
		game.call("_refresh_ui")
		_check(hint.text == "USAR: habla con WOLF del relé." and game.touch_use.text == "USAR", "on touch the hint's key is the USE button's translated word (%s)" % hint.text)
		game.touch_enabled = false
	await end_game(game)
	I18n.forget(catalog)
	I18n.apply("en")


## Every offered language, English first, laid out in the real game and judged by the build's
## overflow check (I18n.overflows): the title (its buttons, the Brand line, the CONTINUE note, shown only
## while there is no save, which start_game guarantees, and the version number), the credits and
## changelog screens, every Settings tab, Pause in a run, the touch layout's buttons, and the station
## names in the corridor, Records Access and the Service Junction at every TEXT SIZE step, where they
## must also stand apart (the kit's overlapping_labels, the check text_boxes_test makes in English).
## English is judged too, so a check that flags the shipped English layout shows up as such. The
## dialogue boxes, hints and cards are not in the catalogs yet (PRs L7b and L7c); L7d's text_boxes_test
## loop covers them per language.
func _check_layouts() -> void:
	for code: String in I18n.offered():
		I18n.apply(code)
		var game: Main = await start_game("i18n-layout-%s" % code, keep_running) as Main
		await frames(3)
		_check(game.continue_note.is_visible_in_tree(), "%s: the CONTINUE note is up on a fresh title, so it is judged" % code)
		_check_fits(code, "title", game.get_node("CanvasLayer/TitleScreen"))
		game.call("_show_credits")
		await frames(2)
		_check_fits(code, "credits", game.credits_screen)
		game.call("_hide_credits")
		game.call("_show_changelog")
		await frames(2)
		_check_fits(code, "changelog", game.changelog_screen)
		game.call("_hide_changelog")
		var settings: GameSettings = game.settings_menu
		game.call("_show_title_settings")
		for tab: int in settings.pages.size():
			if settings.tabs.is_tab_hidden(tab):
				continue
			settings.select_tab(tab)
			await frames(2)
			_check_fits(code, "Settings tab %d" % tab, settings)
		game.call("_resume_game")
		game.debug_tools.actions.jump(&"corridor_start")
		game.touch_enabled = true
		game.call("_refresh_ui")
		await frames(3)
		_check_fits(code, "touch layout", game.get_node("CanvasLayer/TouchControls"))
		_check_fit(code, "touch layout|PauseButton", game.pause_button)
		game.touch_enabled = false
		game.call("_pause_game")
		await frames(2)
		_check_fits(code, "Pause", game.pause_menu)
		game.call("_resume_game")
		for index: int in TextSize.STEPS.size():
			settings.text_size.select(index)
			settings.text_size.item_selected.emit(index)
			var percent: int = roundi(TextSize.STEPS[index] * 100.0)
			for jump: StringName in [&"corridor_start", &"records_mirror", &"junction_a", &"tank_down"]:
				game.debug_tools.actions.jump(jump)
				await frames(3)
				var labels: Array[Label] = shown_station_labels(game)
				for label: Label in labels:
					_check_fit(code, "%d%% %s|%s" % [percent, jump, _game_path(label)], label)
				var overlaps: Array[String] = overlapping_labels(labels)
				_check(overlaps.is_empty(), "%s, %d%%, %s: no two station names overlap %s" % [code, percent, jump, overlaps])
		settings.text_size.select(0)
		settings.text_size.item_selected.emit(0)
		await end_game(game)
	I18n.apply("en")


## Every visible Label, Button and RichTextLabel with text under [param root] fits, one check each,
## named by [param code] and [param where]. English sets the baseline in [member _english_fit] (keyed by
## [param where] and the node's path): a control fits when I18n.overflows finds nothing, or, where the
## shipped English layout already overflows by that check (a Container page grown past its designed
## rect, a binding button that trims its two bindings), when the language needs no more room than English:
## its judged Control (I18n.outermost_container) is no larger and, where the control cuts its text, its
## one-row width (I18n.needed_width) fits the control or is no wider than English's. English itself is recorded, not failed: L8 (layout-for-languages) owns its known overflows.
func _check_fits(code: String, where: String, root: Node) -> void:
	var controls: Array[Node] = [root]
	controls.append_array(root.find_children("*", "Control", true, false))
	for node: Node in controls:
		if not (node is Label or node is Button or node is RichTextLabel):
			continue
		var control: Control = node as Control
		var text: String = str(control.get("text"))
		if text.is_empty() or not control.is_visible_in_tree():
			continue
		_check_fit(code, "%s|%s" % [where, _game_path(control)], control)


## [param node]'s place below the game's root node as child indices ("3/0/12"), the same for every game
## this suite starts. Not its NodePath: the root's name, and the names Godot gives nodes built in code
## without one ("@Label@1234"), differ between instances, so the English pass's keys would never match.
func _game_path(node: Node) -> String:
	var steps: PackedStringArray = []
	while node.get_parent() != null and node.get_parent() != tree().root:
		steps.insert(0, str(node.get_index()))
		node = node.get_parent()
	return "/".join(steps)


## One control of [method _check_fits] (also the station names), under [param key] in the baseline.
func _check_fit(code: String, key: String, control: Control) -> void:
	var over: bool = I18n.overflows(control)
	var judged: Vector2 = I18n.outermost_container(control).size
	# The one-row width matters only where the control cuts its text (clip or trim); a control that
	# grows instead shows that in its judged size.
	var cuts: bool = (control is Label or control is Button) and (bool(control.get("clip_text")) or int(control.get("text_overrun_behavior")) != TextServer.OVERRUN_NO_TRIMMING)
	var needed: float = I18n.needed_width(control) if cuts else 0.0
	var shown: String = TranslationServer.translate(str(control.get("text"))) if control.auto_translate_mode != Node.AUTO_TRANSLATE_MODE_DISABLED else str(control.get("text"))
	if code == I18n.FALLBACK:
		_english_fit[key] = {"over": over, "judged": judged, "needed": needed}
		return
	var english: Dictionary = _english_fit.get(key, {"over": false})
	var fits: bool = not over
	if over and bool(english["over"]):
		var tolerance: float = I18n.OVERFLOW_TOLERANCE_PX
		fits = (judged.x <= english["judged"].x + tolerance and judged.y <= english["judged"].y + tolerance
				and needed <= maxf(control.size.x, float(english["needed"])) + tolerance)
	_check(fits, "%s, %s: %s fits (size %s, judged %s, one row %.0f px; English: %s)" % [code, key.get_slice("|", 0), shown.left(60).c_escape(), control.size, judged, needed, english])
