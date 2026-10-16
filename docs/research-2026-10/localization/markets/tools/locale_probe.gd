## Headless probe: how Godot 4.7.2's TranslationServer reads the locale codes
## the language list proposes. Prints standardize_locale() (with defaults) and
## compare_locales() scores for OS locales against candidate translation tags.
## Purpose: pick each language's Godot code so an OS locale (es_AR, zh_TW, pt_PT)
## lands on the intended translation. Scores: 10 exact, 5 same language,
## +1/-1 per matching/mismatching script, country, variant; 0 different language.
## Second part: for each font path passed after `--`, report whether the font
## has a glyph for sample characters of each candidate language's script, so we
## know which languages need a fallback font (FontFile.has_char, no rendering).
## Run: HOME=<temp> godot --headless --script locale_probe.gd [-- font.ttf ...]
## (no project, no window).
extends SceneTree

func _init() -> void:
	var ts := TranslationServer
	for c in ["es_419", "es-419", "es_MX", "es", "es_ES", "pt_BR", "pt_PT", "pt", "zh_CN", "zh_TW", "zh_Hans", "zh_Hant", "zh_HK", "fr_CA", "en_GB", "nb", "no"]:
		print("std ", c, " -> ", ts.standardize_locale(c, true), "  name=", ts.get_locale_name(c))
	var candidates := ["en", "es", "es_ES", "pt_BR", "pt", "pt_PT", "zh_Hans", "zh_Hant", "fr", "de", "ja", "ko", "ru"]
	for os_loc in ["es_AR", "es_MX", "es_ES", "es_US", "pt_PT", "pt_BR", "zh_TW", "zh_HK", "zh_CN", "zh_SG", "fr_CA", "en_GB"]:
		var best := ""
		var best_s := -1
		var row := []
		for c in candidates:
			var s := ts.compare_locales(os_loc, c)
			if s > 0:
				row.append("%s=%d" % [c, s])
			if s > best_s:
				best_s = s
				best = c
		print("os ", os_loc, " best=", best, "  ", " ".join(row))
	_fonts(OS.get_cmdline_user_args())
	quit()

## Sample letters that a translation in each language needs; a miss means the
## font would fall back (or show tofu) for that language.
const SAMPLES := {
	"es/pt/fr/it/de (Latin-1)": "ñçãõéèàâêîôûüöäßœ¿¡«»",
	"pl/cs/hu/ro/tr (Latin Ext-A)": "ąęłńśźżčěřšžůőűşğıİțș",
	"vi (Latin Ext Additional)": "ạảấầẩẫậắằẳẵặẹẻẽếềểễệđ",
	"ru/uk (Cyrillic)": "АБВГДЕЖЗИЙЯяёЁіїєґІЇЄҐ",
	"el (Greek)": "ΑΒΓΔαβγδωΩ",
	"ja (Kana)": "あいうえおアイウエオー",
	"zh/ja (Han)": "狼工程师门记录狼語",
	"ko (Hangul)": "늑대엔지니어",
	"ar (Arabic)": "ابتثجحخ",
	"hi (Devanagari)": "अआइईउक",
	"th (Thai)": "กขคงจฉ",
}

func _fonts(paths: PackedStringArray) -> void:
	for path in paths:
		var f := FontFile.new()
		if f.load_dynamic_font(path) != OK:
			print("font ", path, " FAILED to load")
			continue
		for key in SAMPLES:
			var s: String = SAMPLES[key]
			var miss := ""
			for i in s.length():
				if not f.has_char(s.unicode_at(i)):
					miss += s[i]
			print("font ", path.get_file(), " | ", key, " | ", "OK" if miss.is_empty() else "MISSING " + miss)
