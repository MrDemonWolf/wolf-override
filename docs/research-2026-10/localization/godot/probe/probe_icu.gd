extends SceneTree
## ICU data probe (step research-godot): the size of the line-breaking data an export adds
## (icudt_godot.dat, TextServer.get_support_data on the editor binary) and which locales make the
## exporter add it on its own (TextServer.is_locale_using_support_data; editor_export_platform.cpp 1180-1240).
## Contract: `godot --headless --path <probe> --script res://probe_icu.gd`; prints RESULT lines.
func _initialize() -> void:
	var server: TextServer = TextServerManager.get_primary_interface()
	print("RESULT support data file = %s, %d bytes" % [server.get_support_data_filename(), server.get_support_data().size()])
	for locale: String in ["en", "es", "pt_BR", "de", "fr", "ru", "ja", "ko", "zh_Hans", "zh_Hant", "th", "vi", "pl", "tr"]:
		print("RESULT is_locale_using_support_data(%s) = %s" % [locale, server.is_locale_using_support_data(locale)])
	quit(0)
