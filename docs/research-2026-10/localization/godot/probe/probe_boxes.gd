extends SceneTree
## Dialogue-box probe across languages (WOLF//OVERRIDE i18n research, step research-godot).
##
## Purpose: run the game's own DialogueBoxes (loaded in place from the scratch export of main, not
## copied) on one game line and on sample translations of it, with the same fit rule main.gd's
## _dialogue_fits uses (wrap_width at MAX_ROW_CHARACTERS, then at most MAX_ROWS rows), and report
## the boxes, their rows and their reading time per character.
## Contract: `godot --headless --path <probe> --script res://probe_boxes.gd -- <dialogue_boxes.gd>
## <body font> [<cjk fallback font>]`, all absolute paths. Prints "RESULT ..." lines, quits with 0.
## Units: COLUMN_WIDTH and FONT_SIZE are canvas px at TEXT SIZE 100% (main.gd DIALOGUE_COLUMN_WIDTH
## 440, the Story label's font_size 17 in scenes/main.tscn). Reading time in seconds.
## Gotchas: the translations are machine samples for measurement only, never game wording.

const COLUMN_WIDTH: float = 440.0
const FONT_SIZE: int = 17
const SPEAKERS: Array[String] = ["WOLF", "ROWAN"]

const LINES: Dictionary = {
	"en (game, main.gd OPENING_EXCHANGE)": "WOLF: I heard the Director's plan for me. I woke myself. He wants me to hunt people he calls threats.",
	"es": "WOLF: Escuché el plan del Director para mí. Me desperté solo. Quiere que cace a las personas que él llama amenazas.",
	"es (¿? ¡! marks)": "WOLF: ¿Qué pasa si toco el relé con corriente? ¡Dímelo ya! No quiero adivinar.",
	"de": "WOLF: Ich habe den Plan des Direktors für mich gehört. Ich habe mich selbst geweckt. Er will, dass ich Menschen jage, die er Bedrohungen nennt.",
	"zh_Hans": "WOLF: 我听到了主管对我的计划。我自己醒了过来。他想让我去追捕那些他称为威胁的人。",
	"zh_Hans (fullwidth colon tag)": "WOLF：我听到了主管对我的计划。我自己醒了过来。他想让我去追捕那些他称为威胁的人。",
}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var boxes_script: GDScript = load(args[0])
	var font: FontFile = FontFile.new()
	font.load_dynamic_font(args[1])
	font.allow_system_fallback = false
	if args.size() > 2:
		var cjk: FontFile = FontFile.new()
		cjk.load_dynamic_font(args[2])
		cjk.allow_system_fallback = false
		font.fallbacks = [cjk]
	var max_chars: int = boxes_script.get("MAX_ROW_CHARACTERS")
	var max_rows: int = boxes_script.get("MAX_ROWS")
	# The same rule as main.gd _dialogue_fits, at TEXT SIZE 100% and the full column.
	var fits: Callable = func(words: String) -> bool:
		var width: float = boxes_script.wrap_width(words, font, FONT_SIZE, COLUMN_WIDTH, max_chars)
		return boxes_script.rows(words, font, FONT_SIZE, width).size() <= max_rows
	for language: String in LINES:
		var line: String = LINES[language]
		var boxes: Array[String] = boxes_script.split(line, SPEAKERS, fits)
		print("RESULT [%s] %d boxes" % [language, boxes.size()])
		for box: String in boxes:
			var words: String = boxes_script.words_of(box, SPEAKERS)
			var width: float = boxes_script.wrap_width(words, font, FONT_SIZE, COLUMN_WIDTH, max_chars)
			var rows: Array = boxes_script.row_texts(words, font, FONT_SIZE, width)
			var seconds: float = boxes_script.read_seconds(words)
			print("RESULT    tag=%s words=%d chars=%d rows=%d fits=%s read=%.2fs (%.1f chars/s) rows=%s" % [
				boxes_script.tag_of(box, SPEAKERS), boxes_script.word_count(words), words.length(), rows.size(),
				fits.call(words), seconds, words.length() / seconds, rows])
	quit(0)
