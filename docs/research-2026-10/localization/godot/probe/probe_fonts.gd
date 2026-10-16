extends SceneTree
## Font coverage and text-measure probe for Godot 4.7.2 (WOLF//OVERRIDE i18n research, step research-godot).
##
## Purpose: say which scripts the game's fonts cover (Font.has_char over whole Unicode blocks and over
## the letters each candidate language needs), whether a missing glyph is filled by an OS font
## (FontFile.allow_system_fallback, default true), and how wide the same line is in each language.
## Contract: `godot --headless --path <probe> --script res://probe_fonts.gd -- <font> [<font> ...]`
## where each <font> is an absolute path to a .ttf/.otf. With `-- --chain <primary> <fallback>...` it
## instead builds one font whose Font.fallbacks are the later files, with OS fallback turned off, and
## reports for each sample line how many glyphs the chain leaves unresolved. Fonts load with FontFile.load_dynamic_font,
## so no import step runs. Prints "RESULT ..." lines and quits with 0.
## Units: widths in px at FONT_SIZE px, measured by Font.get_string_size (one unwrapped line).
## Gotchas: has_char reads the font's own cmap only; it never consults fallbacks or system fonts,
## which is what a ship check needs (an OS font is not there on every device, and never on web).

const FONT_SIZE: int = 18

## Unicode blocks, as [name, first, last] code points (inclusive).
const BLOCKS: Array = [
	["Basic Latin (printable)", 0x20, 0x7E],
	["Latin-1 Supplement (letters+punct)", 0xA0, 0xFF],
	["Latin Extended-A", 0x100, 0x17F],
	["Latin Extended-B", 0x180, 0x24F],
	["Latin Extended Additional (Vietnamese etc.)", 0x1E00, 0x1EFF],
	["Greek and Coptic", 0x370, 0x3FF],
	["Cyrillic", 0x400, 0x4FF],
	["Cyrillic Supplement", 0x500, 0x52F],
	["General Punctuation", 0x2000, 0x206F],
	["CJK Symbols and Punctuation", 0x3000, 0x303F],
	["Hiragana", 0x3041, 0x3096],
	["Katakana", 0x30A0, 0x30FF],
	["CJK Unified Ideographs", 0x4E00, 0x9FFF],
	["Hangul Syllables", 0xAC00, 0xD7A3],
	["Halfwidth and Fullwidth Forms", 0xFF00, 0xFFEF],
	["Arabic", 0x600, 0x6FF],
	["Thai", 0xE00, 0xE7F],
	["Devanagari", 0x900, 0x97F],
]

## Letters each language needs beyond ASCII (lower and upper case), checked one by one.
const LANGUAGE_LETTERS: Dictionary = {
	"es": "áéíóúüñÁÉÍÓÚÜÑ¿¡«»",
	"pt_BR": "áâãàçéêíóôõúÁÂÃÀÇÉÊÍÓÔÕÚ",
	"fr": "àâæçéèêëîïôœùûüÿÀÂÆÇÉÈÊËÎÏÔŒÙÛÜŸ«»",
	"de": "äöüßÄÖÜẞ„“",
	"it": "àèéìòùÀÈÉÌÒÙ",
	"pl": "ąćęłńóśźżĄĆĘŁŃÓŚŹŻ",
	"tr": "çğıöşüÇĞİÖŞÜ",
	"ru": "абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ",
	"uk": "ґєіїҐЄІЇʼ",
	"vi": "ăâđêôơưĂÂĐÊÔƠƯạảấầẩẫậắằẳẵặẹẻẽếềểễệỉịọỏốồổỗộớờởỡợụủứừửữựỳỵỷỹ",
	"ja": "あいうえおアイウエオ漢字、。！？「」ー",
	"zh_Hans": "你好开门电门这对，。！？“”",
	"zh_Hant": "你好開門電門這對，。！？「」",
	"ko": "안녕하세요문열기，。！？",
}

## One game line, sample translations by machine for width only (not wording for the game).
const SAMPLE_LINES: Dictionary = {
	"en": "Save failed. Use a station to try again.",
	"es": "No se pudo guardar. Usa una estación para intentarlo de nuevo.",
	"pt_BR": "Falha ao salvar. Use uma estação para tentar de novo.",
	"de": "Speichern fehlgeschlagen. Nutze eine Station, um es erneut zu versuchen.",
	"fr": "Échec de la sauvegarde. Utilisez une station pour réessayer.",
	"ru": "Не удалось сохранить. Используйте станцию, чтобы попробовать снова.",
	"ja": "セーブに失敗しました。ステーションでもう一度試してください。",
	"zh_Hans": "保存失败。请使用站点重试。",
	"ko": "저장에 실패했습니다. 스테이션을 사용해 다시 시도하세요.",
}


func _initialize() -> void:
	print("RESULT OS.has_feature(system_fonts) = %s" % OS.has_feature("system_fonts"))
	print("RESULT text server = %s" % TextServerManager.get_primary_interface().get_name())
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty() and args[0] == "--chain":
		_report_chain(args.slice(1))
	else:
		for path: String in args:
			_report(path)
	quit(0)


## A primary font with bundled fallbacks only (allow_system_fallback off on each, as a web export or a
## device without the OS font would behave): unresolved glyphs per sample line.
func _report_chain(paths: PackedStringArray) -> void:
	var fonts: Array[Font] = []
	for path: String in paths:
		var font: FontFile = FontFile.new()
		font.load_dynamic_font(path)
		font.allow_system_fallback = false
		fonts.append(font)
	var primary: FontFile = fonts[0]
	primary.fallbacks = fonts.slice(1)
	for language: String in SAMPLE_LINES:
		print("RESULT chain %s %s:%s" % [" + ".join(Array(paths).map(func(p: String) -> String: return p.get_file())), language, _unresolved(primary, SAMPLE_LINES[language])])


func _report(path: String) -> void:
	var font: FontFile = FontFile.new()
	var err: Error = font.load_dynamic_font(path)
	var name: String = path.get_file()
	if err != OK:
		print("RESULT %s load error %d" % [name, err])
		return
	print("RESULT %s file_size_bytes = %d" % [name, FileAccess.get_file_as_bytes(path).size()])
	for block: Array in BLOCKS:
		var have: int = 0
		var total: int = 0
		for code: int in range(block[1], block[2] + 1):
			total += 1
			if font.has_char(code):
				have += 1
		print("RESULT %s block %s = %d/%d" % [name, block[0], have, total])
	for language: String in LANGUAGE_LETTERS:
		var letters: String = LANGUAGE_LETTERS[language]
		var missing: String = ""
		for index: int in letters.length():
			if not font.has_char(letters.unicode_at(index)):
				missing += letters[index]
		print("RESULT %s language %s missing = '%s'" % [name, language, missing])
	var english: float = font.get_string_size(SAMPLE_LINES["en"], HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x
	for language: String in SAMPLE_LINES:
		var line: String = SAMPLE_LINES[language]
		var width: float = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x
		print("RESULT %s width %s = %.0f px (%d chars, x%.2f of en)%s" % [name, language, width, line.length(), width / english, _unresolved(font, line)])


## How many glyphs of [param line] no font in the chain (own cmap, fallbacks, OS fonts) could draw.
func _unresolved(font: FontFile, line: String) -> String:
	var server: TextServer = TextServerManager.get_primary_interface()
	var shaped: RID = server.create_shaped_text()
	server.shaped_text_add_string(shaped, line, font.get_rids(), FONT_SIZE)
	var missing: int = 0
	var from_other_font: int = 0
	var own: Array[RID] = font.get_rids()
	for glyph: Dictionary in server.shaped_text_get_glyphs(shaped):
		var rid: RID = glyph.get("font_rid", RID())
		if not rid.is_valid():
			missing += 1
		elif not own.has(rid):
			from_other_font += 1
	server.free_rid(shaped)
	return "  [glyphs drawn by an OS fallback font: %d, unresolved (tofu): %d]" % [from_other_font, missing]
