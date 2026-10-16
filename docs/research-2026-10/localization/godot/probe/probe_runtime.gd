extends SceneTree
## Runtime localization probe for Godot 4.7.2 (WOLF//OVERRIDE i18n research, step research-godot).
##
## Purpose: measure, headlessly, how TranslationServer names and matches locales, how PO plurals,
## contexts and fuzzy entries load, what pseudolocalization does to placeholders and BBCode, which
## nodes hear NOTIFICATION_TRANSLATION_CHANGED, what auto_translate_mode does to a Label, and (fix-2
## step) which file fills a line that one file of a language lacks.
## Contract: run as `godot --headless --path <probe> --script res://probe_runtime.gd` with an
## isolated HOME. Prints one "RESULT key = value" line per measurement and quits with 0. It loads
## the PO fixtures in res://po/ directly (PO needs no import: core/io/translation_loader_po.cpp).
## Gotchas: translations are added in code, not through project settings, so the probe controls
## exactly which locales exist; every section clears the server first.

const LOCALES_TO_STANDARDIZE: Array[String] = [
	"es-419", "es_419", "es-MX", "es_ES", "es", "zh-Hans", "zh-Hant", "zh-Hans-CN", "zh_CN", "zh_TW",
	"zh_HK", "pt-BR", "pt_PT", "pt", "ja_JP", "ko_KR", "de_DE", "fr_CA", "ru_RU", "en_US", "pl_PL",
	"tr_TR", "it_IT", "uk_UA", "vi_VN", "id_ID", "th_TH",
]


func _initialize() -> void:
	_os_locale()
	_standardize()
	_matching()
	_po_features()
	_sibling_fallback()
	_formats()
	_pseudolocalization()
	await _notifications_and_auto_translate()
	quit(0)


func _out(key: String, value: Variant) -> void:
	print("RESULT %s = %s" % [key, str(value)])


## The PO fixture res://po/<file> as a Translation (null if it failed to load).
func _po(file: String) -> Translation:
	return load("res://po/" + file) as Translation


## How each OS-style locale code is named inside Godot, with and without added defaults.
func _standardize() -> void:
	for code: String in LOCALES_TO_STANDARDIZE:
		_out("standardize(%s)" % code, "%s | add_defaults: %s" % [
			TranslationServer.standardize_locale(code), TranslationServer.standardize_locale(code, true)])
	for pair: Array in [["es_419", "es"], ["es_419", "es_MX"], ["es_MX", "es_ES"], ["zh_TW", "zh_Hant"],
			["zh_HK", "zh_Hant"], ["zh_CN", "zh_Hant"], ["zh", "zh_Hans"], ["pt_BR", "pt_PT"], ["pt", "pt_BR"]]:
		_out("compare_locales(%s, %s)" % pair, TranslationServer.compare_locales(pair[0], pair[1]))


## Which translation wins for a player locale when several Spanish, Portuguese and Chinese files exist.
func _matching() -> void:
	TranslationServer.clear()
	for file: String in ["es.po", "es_419.po", "es_MX.po", "pt_BR.po", "pt_PT.po", "zh_Hans.po", "zh_Hant.po"]:
		var translation: Translation = _po(file)
		_out("po locale(%s)" % file, translation.locale if translation else "LOAD FAILED")
		if translation:
			TranslationServer.add_translation(translation)
	_out("loaded_locales", TranslationServer.get_loaded_locales())
	for player: String in ["es_419", "es-419", "es_AR", "es_MX", "es_ES", "es_US", "pt_BR", "pt_PT", "pt_AO", "pt",
			"zh_CN", "zh_Hans_CN", "zh_TW", "zh_HK", "zh_Hant_TW", "zh_SG", "zh", "fr_FR"]:
		TranslationServer.set_locale(player)
		_out("tr(HELLO) at %s (server locale %s)" % [player, TranslationServer.get_locale()], TranslationServer.translate("HELLO"))
	TranslationServer.clear()


## Contexts, plurals (CLDR-style rule from the header or Godot's built-in table), fuzzy entries.
func _po_features() -> void:
	TranslationServer.clear()
	TranslationServer.add_translation(_po("es.po"))
	TranslationServer.add_translation(_po("ru.po"))
	var pl: Translation = _po("pl_noheader.po")
	TranslationServer.add_translation(pl)
	TranslationServer.set_locale("es")
	_out("es ctx verb", TranslationServer.translate("Open", "verb"))
	_out("es ctx adjective", TranslationServer.translate("Open", "adjective"))
	_out("es no ctx (falls to msgid)", TranslationServer.translate("Open"))
	_out("es fuzzy entry", TranslationServer.translate("FUZZY ONE"))
	for n: int in [0, 1, 2, 5]:
		_out("es tr_n(%d)" % n, TranslationServer.translate_plural("%d valve", "%d valves", n) % n)
	TranslationServer.set_locale("ru")
	for n: int in [1, 2, 5, 11, 21, 22, 25]:
		_out("ru tr_n(%d)" % n, TranslationServer.translate_plural("%d valve", "%d valves", n) % n)
	_out("built-in plural rule ru", TranslationServer.get_plural_rules("ru"))
	_out("built-in plural rule pl", TranslationServer.get_plural_rules("pl"))
	_out("built-in plural rule ja", TranslationServer.get_plural_rules("ja"))
	_out("built-in plural rule pt_BR", TranslationServer.get_plural_rules("pt_BR"))
	_out("pl PO without Plural-Forms locale", pl.locale)
	TranslationServer.set_locale("de")
	_out("missing locale de -> fallback en, untranslated", TranslationServer.translate("HELLO"))
	TranslationServer.clear()


## What a player sees for a line one file of a language lacks (added by the fix-2 step, 2026-10-16).
## Godot looks every message up in each loaded translation whose locale scores above 0 against the
## current one (core/string/translation_domain.cpp, get_message_from_translations), skipping a file
## that lacks the message, has it fuzzy (the PO loader drops it) or has it empty; only then does it try
## the fallback locale and the msgid. So a gap in zh_Hant is filled from zh_Hans, and one in es_MX from
## es. The second half removes the sibling file, as I18n.apply() would if it kept only the chosen
## language's catalog registered, and the same gaps then show English.
func _sibling_fallback() -> void:
	TranslationServer.clear()
	var hans: Translation = _po("zh_Hans.po")
	for translation: Translation in [hans, _po("zh_Hant.po"), _po("es.po"), _po("es_MX.po")]:
		TranslationServer.add_translation(translation)
	TranslationServer.set_locale("zh_Hant")
	for message: String in ["HELLO", "ONLY IN HANS", "FUZZY IN HANT", "EMPTY IN HANT"]:
		_out("sibling: tr(%s) at zh_Hant, zh_Hans and zh_Hant loaded" % message, TranslationServer.translate(message))
	TranslationServer.set_locale("es_MX")
	_out("sibling: tr(ONLY IN ES) at es_MX, es and es_MX loaded", TranslationServer.translate("ONLY IN ES"))
	TranslationServer.remove_translation(hans)
	TranslationServer.set_locale("zh_Hant")
	for message: String in ["HELLO", "ONLY IN HANS", "FUZZY IN HANT", "EMPTY IN HANT"]:
		_out("sibling: tr(%s) at zh_Hant, only zh_Hant loaded" % message, TranslationServer.translate(message))
	TranslationServer.clear()


## Translating format strings: translate the template, then fill it.
func _formats() -> void:
	TranslationServer.clear()
	TranslationServer.add_translation(_po("es.po"))
	TranslationServer.set_locale("es")
	_out("percent after tr", TranslationServer.translate("Hello %s") % "Rowan")
	_out("format after tr", TranslationServer.translate("{name} keeps WOLF running.").format({"name": "Rowan"}))
	_out("tr after percent (key no longer matches)", TranslationServer.translate("Hello %s" % "Rowan"))
	TranslationServer.clear()


## What the pseudolocalizer does to the game's kinds of text (placeholders, named fields, BBCode).
func _pseudolocalization() -> void:
	TranslationServer.clear()
	var settings: Dictionary = {
		"internationalization/pseudolocalization/replace_with_accents": true,
		"internationalization/pseudolocalization/double_vowels": true,
		"internationalization/pseudolocalization/expansion_ratio": 0.3,
		"internationalization/pseudolocalization/prefix": "[",
		"internationalization/pseudolocalization/suffix": "]",
		"internationalization/pseudolocalization/skip_placeholders": true,
	}
	for key: String in settings:
		ProjectSettings.set_setting(key, settings[key])
	TranslationServer.reload_pseudolocalization()
	TranslationServer.pseudolocalization_enabled = true
	for sample: String in ["HOLD E: crank the manual bypass, %d of %d.", "{name} keeps WOLF's systems running.",
			"[b]RELAY[/b]  {name} told WOLF the risk.", "Back at the last checkpoint."]:
		var out: String = TranslationServer.translate(sample)
		_out("pseudo(%s)" % sample, "%s  (length %d -> %d, x%.2f)" % [out, sample.length(), out.length(), float(out.length()) / sample.length()])
	TranslationServer.pseudolocalization_enabled = false


## A node built in code hears NOTIFICATION_TRANSLATION_CHANGED on set_locale; a Label's shown text
## follows auto_translate_mode (measured through get_total_character_count, which counts the shown text).
func _notifications_and_auto_translate() -> void:
	TranslationServer.clear()
	TranslationServer.add_translation(_po("es.po"))
	TranslationServer.set_locale("en")
	var listener: Listener = Listener.new()
	root.add_child(listener)
	var always: Label = Label.new()
	always.text = "HELLO"
	root.add_child(always)
	var disabled: Label = Label.new()
	disabled.text = "HELLO"
	disabled.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	root.add_child(disabled)
	var rich: RichTextLabel = RichTextLabel.new()
	rich.text = "HELLO"
	root.add_child(rich)
	var appended: RichTextLabel = RichTextLabel.new()
	appended.append_text("HELLO")
	root.add_child(appended)
	await process_frame
	var before: int = listener.count
	TranslationServer.set_locale("es")
	await process_frame
	_out("listener notifications on set_locale", listener.count - before)
	_out("root auto_translate_mode (0 inherit,1 always,2 disabled)", root.auto_translate_mode)
	_out("Label inherit shown chars (HELLO=5, 'Hola (es)'=9)", always.get_total_character_count())
	_out("Label disabled shown chars", disabled.get_total_character_count())
	_out("Label.text property after locale change", always.text)
	_out("RichTextLabel .text shown", rich.get_parsed_text())
	_out("RichTextLabel append_text shown", appended.get_parsed_text())
	_out("Node.tr in disabled node", disabled.tr("HELLO"))
	_out("Node.atr in disabled node", disabled.atr("HELLO"))
	TranslationServer.set_locale("en")
	TranslationServer.clear()


func _os_locale() -> void:
	_out("OS.get_locale()", OS.get_locale())
	_out("OS.get_locale_language()", OS.get_locale_language())
	_out("TranslationServer.get_locale() at start (no test locale)", TranslationServer.get_locale())


## Counts NOTIFICATION_TRANSLATION_CHANGED, as text built in code would to rebuild itself.
class Listener extends Node:
	var count: int = 0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_TRANSLATION_CHANGED:
			count += 1
