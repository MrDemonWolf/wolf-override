extends "res://tests/support/game_suite.gd"
## The text-box checks' shared kit (it extends the suite kit, tests/support/game_suite.gd): one game
## with its dialogue box, and every check of text you can read, so the suites that split the work
## between them share one copy. Its users and what each runs:
## - tests/text_boxes_test.gd: the English checks, from the reading rule to the TEXT SIZE setting.
## - tests/text_boxes_languages_test.gd: the corpus and the overlap checks in every other language.
## The language checks were one suite with the English ones until CI ran it in 235 s of a 240 s limit
## (run 39370708132, 2026-10-20); split in two, each suite takes well under 120 s (the numbers are in
## scripts/check-game.sh's HEAVY_SUITES list). A check's text and contract did not change in the split.
##
## Like the suite kit it has no class_name and never ships (export_presets.cfg excludes tests/*), and
## check-game.sh only globs tests/*_test.gd, so it is never run as a suite itself.

const MAIN_SCRIPT: String = "res://scripts/main.gd"
const NAMES: Array[String] = ["Rowan", "Alex", "Morgan"]

## The suite's game (open_text_game), and its dialogue box's Story and Speaker labels and the box itself.
var game: Main
var story: Label
var speaker: Label
var bar: Control
## Boxes measured on screen, and the most rows any took at 200%.
var shown_checked: int = 0
var rows_at_200: int = 0


## Starts the suite's game: spawns it with its settings at a user:// file named after [param file_tag]
## and the process id (save file beside it), keeps it running on focus loss, and finds its dialogue box.
## Returns the settings path, which _check_text_size and _check_prompts_clear write to.
func open_text_game(file_tag: String) -> String:
	var path: String = "user://%s-%s.cfg" % [file_tag, OS.get_process_id()]
	game = await spawn_game("%s-save.json" % path, path, keep_running) as Main
	story = game.get_node("CanvasLayer/BottomBar/Story") as Label
	speaker = game.get_node("CanvasLayer/BottomBar/Speaker") as Label
	bar = game.get_node("CanvasLayer/BottomBar") as Control
	return path


## Ends the suite: the kit's teardown (the rooms' jumps leave clips playing; end_game stops them before
## freeing the game and removes its save and settings files), then the exit status.
func close_text_game() -> void:
	await end_game(game)
	finish("")


## Runs [param target]'s clock in game time, 1/60 s a step, until [param condition] holds or
## [param max_seconds] of game time have passed, and returns whether it held. Each step calls the
## game's _process with 1/60 s and advances the name card's fade tween (Main.top_card_tween) by the
## same with Tween.custom_step, then waits one process frame so the UI lays out. The engine keeps
## running its own frames meanwhile, which can only bring the end sooner. Why not wait out the fade
## in real time: that cost 0.45 s for every fresh game _check_prompts_clear opens, 10 per language
## (measured 2026-10-24 on the development Mac, of the 0.8 s each game took; the rest went to the
## sound bank's render, now shared, see SfxBank._detail_rendered), and how far it got depended on the
## machine's load.
func _step_game_time(target: Main, condition: Callable, max_seconds: float) -> bool:
	for _step: int in roundi(max_seconds * 60.0):
		if condition.call():
			return true
		target.call("_process", 1.0 / 60.0)
		var fade: Tween = target.top_card_tween
		if fade != null and fade.is_valid():
			fade.custom_step(1.0 / 60.0)
		await process_frame
	return condition.call()


## STORY-2: 1.2 s plus 0.33 s a word, or plus 0.05 s a character (at most 7 s), whichever is longer.
func _check_reading_rule() -> void:
	_expect(is_equal_approx(DialogueBoxes.READ_SECONDS_PER_WORD, 0.33) and DialogueBoxes.READ_SECONDS_BASE > 0.0, "boxes are timed at 0.33 s a word plus a base")
	_expect(absf(DialogueBoxes.read_seconds("Go.") - (1.2 + 0.33)) < 0.001 and DialogueBoxes.read_seconds("one two three four five six seven eight nine ten") >= 10 * 0.33 and absf(DialogueBoxes.read_seconds("abcdefghij abcdefghij abcdefghij") - (1.2 + 0.05 * 32)) < 0.001, "a box is up 1.2 s plus 0.33 s a word or 0.05 s a character, whichever is longer (%.2f s for \"Go.\")" % DialogueBoxes.read_seconds("Go."))
	_expect(not (load(MAIN_SCRIPT) as Script).get_script_constant_map().has("READ_SECONDS_PER_WORD"), "main.gd keeps no faster reading rate of its own")


## The splitter on lines with known shapes: speakers inline, untagged continuation, quotes, choices.
func _check_splitting() -> void:
	var tags: Array[String] = ["WOLF", "DIRECTOR", "DIRECTOR / PURGE", "ROWAN"]
	var wide: Callable = func(_words: String) -> bool: return true
	_expect(DialogueBoxes.split("FIRST COPY SECURED. WOLF: An order. I want the source.\nROWAN: Then Archive is next.", tags, wide) == ["FIRST COPY SECURED.", "WOLF: An order. I want the source.", "ROWAN: Then Archive is next."], "a speaker named inside a line starts their own box")
	_expect(DialogueBoxes.split("WOLF: You said \"Go now. We can talk after.\"\nI refused.", tags, wide) == ["WOLF: You said \"Go now. We can talk after.\"\nI refused."], "an untagged line after WOLF's goes on in his box, and a quotation stays whole")
	_expect(DialogueBoxes.split("WOLF: Which one?\n1  \"Yes.\"\n2  \"No.\"", tags, wide) == ["WOLF: Which one?"], "a choice's response rows stay out of the box")
	_expect(DialogueBoxes.split("DIRECTOR / PURGE: Logs marked.\nWOLF: Gone.", tags, wide) == ["DIRECTOR / PURGE: Logs marked.", "WOLF: Gone."], "the purge display's tag is matched whole")
	var twenty: String = "One two three four five. Six seven eight nine ten. Eleven twelve thirteen fourteen fifteen. Sixteen seventeen eighteen nineteen twenty."
	var long_boxes: Array[String] = DialogueBoxes.split(twenty, tags, wide)
	_expect(long_boxes.size() == 2 and " ".join(long_boxes) == twenty, "a line of 20 words splits at a sentence break even when it would fit (%s)" % [long_boxes])


## Every line constant and dialogue literal, as each engineer name, at 100%.
func _check_corpus() -> void:
	var font: Font = story.get_theme_font(&"font")
	var size: int = story.get_theme_font_size(&"font_size")
	var width: float = game.call("_dialogue_column_width")
	_expect(size >= 23, "dialogue is %d px at 540p (at least 23)" % size)
	# A row that would pass 42 characters breaks one word earlier, never sooner; rows of the approved
	# two-row boxes keep their written breaks.
	var stiff: String = "The wheel is stiff. Three full turns charge the door."
	var stiff_rows: Array[String] = DialogueBoxes.row_texts(stiff, font, size, DialogueBoxes.wrap_width(stiff, font, size, width, DialogueBoxes.MAX_ROW_CHARACTERS))
	_expect(stiff_rows == ["The wheel is stiff. Three full turns", "charge the door."], "a long row breaks one word earlier, not more (%s)" % [stiff_rows])
	var lost: String = Main.SENTRY_LOST_LINE % "Morgan"
	var lost_rows: Array[String] = DialogueBoxes.row_texts(lost, font, size, DialogueBoxes.wrap_width(lost, font, size, width, DialogueBoxes.MAX_ROW_CHARACTERS))
	var written: Array[String] = []
	written.assign(lost.split("\n"))
	_expect(lost_rows == written, "an approved two-row box keeps its rows (%s)" % [lost_rows])
	var messages: Array[String] = _corpus()
	_expect(messages.size() >= 90, "the corpus holds the game's lines (%d)" % messages.size())
	var boxes: int = 0
	for first: String in NAMES:
		var tags: Array[String] = ["WOLF", "DIRECTOR", "DIRECTOR / PURGE", first.to_upper()]
		var fits: Callable = DialogueBoxes.fits.bind(font, size, width, I18n.FALLBACK)
		for template: String in messages:
			var message: String = template.replace("{NAME}", first.to_upper()).replace("{name}", first)
			var split: Array[String] = DialogueBoxes.split(message, tags, fits)
			_expect(_words(message.get_slice(DialogueBoxes.CHOICE_MARKER, 0), tags) == _words("\n".join(split), tags), "splitting changes no word: %s" % message.c_escape())
			for box: String in split:
				boxes += 1
				_check_box(box, tags, font, size, width, message)
	_expect(boxes > messages.size() * 3, "every line was measured as boxes (%d)" % boxes)


func _check_box(box: String, tags: Array[String], font: Font, size: int, width: float, source: String) -> void:
	var words: String = DialogueBoxes.words_of(box, tags)
	var rows: Array[String] = DialogueBoxes.row_texts(words, font, size, DialogueBoxes.wrap_width(words, font, size, width, DialogueBoxes.MAX_ROW_CHARACTERS))
	var longest: int = _longest_row(rows)
	_expect(not _names_inline(words, tags), "one speaker per box: %s" % box.c_escape())
	_expect(rows.size() <= DialogueBoxes.MAX_ROWS and longest <= DialogueBoxes.MAX_ROW_CHARACTERS, "a box takes at most 2 rows of at most 42 characters (%d rows, %d characters): %s (from %s)" % [rows.size(), longest, box.c_escape(), source.c_escape()])
	_expect(DialogueBoxes.word_count(words) < DialogueBoxes.LONG_LINE_WORDS, "a box holds fewer than 20 words: %s" % box.c_escape())
	_expect(DialogueBoxes.read_seconds(words) >= DialogueBoxes.word_count(words) * 0.33, "a box is up 0.33 s a word or longer: %s" % box.c_escape())


## PR L7d's rules, language by language: the table's row limits, reading speeds and the box length
## they give, and the sentence, clause and quotation marks of the languages the table lists.
func _check_language_rules() -> void:
	_expect(DialogueBoxes.row_characters("en") == DialogueBoxes.MAX_ROW_CHARACTERS and DialogueBoxes.row_characters("es") == 42 and DialogueBoxes.row_characters("ja") == 0 and DialogueBoxes.row_characters("ko") == 0, "rows hold 42 characters in English and Spanish and run to the column in Japanese and Korean (languages.json)")
	_expect(DialogueBoxes.long_line_characters("en") > 2 * DialogueBoxes.MAX_ROW_CHARACTERS and DialogueBoxes.long_line_characters("es") > 2 * DialogueBoxes.MAX_ROW_CHARACTERS, "in English and Spanish the box length limit is longer than two rows, so English boxes split as before (%d, %d)" % [DialogueBoxes.long_line_characters("en"), DialogueBoxes.long_line_characters("es")])
	_expect(DialogueBoxes.long_line_characters("ja") == 26 and DialogueBoxes.long_line_characters("zh_Hans") == 59 and DialogueBoxes.long_line_characters("ko") == 79, "a box holds as many characters as 20 words take to read: 26 in Japanese, 59 in Chinese, 79 in Korean (%d, %d, %d)" % [DialogueBoxes.long_line_characters("ja"), DialogueBoxes.long_line_characters("zh_Hans"), DialogueBoxes.long_line_characters("ko")])
	var ten: String = "あいうえおかきくけこ"
	_expect(is_equal_approx(DialogueBoxes.read_seconds(ten, "ja"), 1.2 + 10.0 / 4.0) and is_equal_approx(DialogueBoxes.read_seconds(ten.repeat(4), "ja"), 1.2 + 40.0 / 4.0), "Japanese is read at 4 characters a second, its cap scaled to cover as many characters as English's (%.2f s for 40)" % DialogueBoxes.read_seconds(ten.repeat(4), "ja"))
	_expect(is_equal_approx(DialogueBoxes.read_seconds(ten.repeat(14), "ja"), 1.2 + 5.8 * 5.0) and is_equal_approx(DialogueBoxes.read_seconds(ten.repeat(14), "en"), 7.0), "the per-character time stops at English's 7 s cap scaled by speed (%.2f s in Japanese)" % DialogueBoxes.read_seconds(ten.repeat(14), "ja"))
	var line: String = "abcdefghij abcdefghij abcdefghij"
	_expect(DialogueBoxes.read_seconds(line, "de") == DialogueBoxes.read_seconds(line, "en") and DialogueBoxes.read_seconds(line) == DialogueBoxes.read_seconds(line, "en") and is_equal_approx(DialogueBoxes.read_seconds(line, "es"), 1.2 + 32.0 / 17.0), "a language with no speed yet reads at English's; Spanish at 17 characters a second")
	var short: Callable = func(limit: int) -> Callable: return func(words: String) -> bool: return words.length() <= limit
	var none: Array[String] = []
	var cases: Array = [
		["ja", "扉が開いた。明かりが消えた！どうする？", 8, ["扉が開いた。", "明かりが消えた！", "どうする？"], "Japanese full stops end sentences with no space after them"],
		["ja", "本当！？行こう。", 5, ["本当！？", "行こう。"], "a break never comes between two marks"],
		["ja", "「行こう。」と言った。次へ。", 11, ["「行こう。」と言った。", "次へ。"], "a Japanese quotation stays whole, and a full stop before its closer is not a break"],
		["ja", "彼は「『止まれ。』と書いてある。」と言った。", 6, ["彼は「『止まれ。』と書いてある。」と言った。"], "nested 「『 quotations are tracked"],
		["ja", "雨が降っているので、傘を持って、駅まで歩いた。", 13, ["雨が降っているので、", "傘を持って、駅まで歩いた。"], "a sentence too long breaks after 、 with no space"],
		["zh_Hans", "今天下雨了。我们带上伞，走到车站。", 8, ["今天下雨了。", "我们带上伞，", "走到车站。"], "Chinese full stops and commas break with no space"],
		["en", "Wait… the door is open. Go.", 21, ["Wait…", "the door is open. Go."], "an ellipsis ends a sentence"],
		["de", "Sie sagte „Geh jetzt. Wir reden später.“ Er ging.", 41, ["Sie sagte „Geh jetzt. Wir reden später.“", "Er ging."], "a German „“ quotation stays whole"],
		["pl", "Powiedziała „Idź. Pogadamy później.” Poszedł.", 40, ["Powiedziała „Idź. Pogadamy później.”", "Poszedł."], "a Polish „” quotation stays whole"],
		["fr", "Il dit « Allez. Vite. » Puis il part.", 22, ["Il dit « Allez. Vite. »", "Puis il part."], "a French « » quotation stays whole, its closer after a space"],
		["en", "He said “Go now. Talk later.” Then he left.", 30, ["He said “Go now. Talk later.”", "Then he left."], "a “” quotation stays whole"],
		["es", "¿Listo? ¡Vamos ya!", 12, ["¿Listo?", "¡Vamos ya!"], "Spanish ¿ and ¡ open a sentence and break nothing"],
	]
	for case: Array in cases:
		var boxes: Array[String] = DialogueBoxes.split(case[1], none, short.call(case[2]), case[0])
		_expect(boxes == (case[3] as Array), "%s: %s (got %s)" % [case[0], case[4], boxes])


## Every language of I18n.LANGUAGES at every TextSize step (PR L7d): the corpus as that language shows
## it (each message translated where its catalog has it, the Director's tags too, with Morgan, the
## longest preset name) splits without a letter changed into one-speaker boxes; a box that breaks its
## language's rules (MAX_ROWS rows, its row limit, LONG_LINE_WORDS words, long_line_characters) has no
## sentence or clause break left to split at; and where rows run to the column, two rows are balanced.
## Each message is shown in a language once, before the size loop: the shown text does not depend on
## the size, only its layout does.
func _check_every_language() -> void:
	var messages: Array[String] = _corpus()
	var codes: Array[String] = []
	codes.assign(I18n.LANGUAGES.keys())
	var tags: Array[String] = ["WOLF", "DIRECTOR", "DIRECTOR / PURGE", "MORGAN"]
	var name_back: Callable = func(words: String) -> String:
		var key: String = words.replace("Morgan", "%s")
		var translated: String = String(TranslationServer.translate(key))
		return "" if translated == key else translated.replace("%s", "Morgan")
	var boxes: int = 0
	var unsplittable: int = 0
	for code: String in codes:
		I18n.apply(code)
		var names: Dictionary = game.call("_speaker_names")
		names["MORGAN"] = "MORGAN"
		var shown_tags: Array[String] = []
		for tag: String in tags:
			shown_tags.append(String(names.get(tag, tag)))
		var shown: Array[String] = []
		for template: String in messages:
			shown.append(I18n.shown(template.replace("{NAME}", "MORGAN").replace("{name}", "Morgan"), tags, names, name_back))
		for step: float in TextSize.STEPS:
			_use_size(step)
			var font: Font = story.get_theme_font(&"font")
			var size: int = story.get_theme_font_size(&"font_size")
			var width: float = game.call("_dialogue_column_width")
			var fits: Callable = DialogueBoxes.fits.bind(font, size, width, code)
			for message: String in shown:
				var split: Array[String] = DialogueBoxes.split(message, shown_tags, fits, code)
				_expect(_letters(message.get_slice(DialogueBoxes.CHOICE_MARKER, 0), shown_tags) == _letters("".join(split), shown_tags), "%s at %d%%: splitting changes no letter: %s" % [code, roundi(step * 100.0), message.c_escape()])
				for box: String in split:
					boxes += 1
					if not _check_language_box(box, shown_tags, font, size, width, code):
						unsplittable += 1
	I18n.apply(I18n.FALLBACK)
	_use_size(1.0)
	print("text boxes: %d boxes in %d languages at %d sizes; %d are one sentence or clause too long to split" % [boxes, codes.size(), TextSize.STEPS.size(), unsplittable])
	_expect(boxes > messages.size() * codes.size() * TextSize.STEPS.size(), "every language's corpus was measured at every size (%d boxes)" % boxes)


## One box of [method _check_every_language] in [param code]: one speaker; within the language's rules
## or, if not, with no break left in it; and, where rows run to the column, two rows the wrap chose are
## balanced. Returns whether the box keeps the rules.
func _check_language_box(box: String, tags: Array[String], font: Font, size: int, width: float, code: String) -> bool:
	var words: String = DialogueBoxes.words_of(box, tags)
	_expect(not _names_inline(words, tags), "%s: one speaker per box: %s" % [code, box.c_escape()])
	var limit: int = DialogueBoxes.row_characters(code)
	# What the game shows (main.gd _story_wrap_width): Korean with its row break at a space.
	var shown: String = DialogueBoxes.keep_words(words, font, size, width) if limit == 0 else words
	var wrap: float = DialogueBoxes.wrap_width(shown, font, size, width, limit)
	var rows: Array[String] = DialogueBoxes.row_texts(shown, font, size, wrap)
	var keeps: bool = rows.size() <= DialogueBoxes.MAX_ROWS and (limit == 0 or _longest_row(rows) <= limit) and DialogueBoxes.word_count(words) < DialogueBoxes.LONG_LINE_WORDS and words.length() < DialogueBoxes.long_line_characters(code)
	if not keeps:
		var breaks: int = DialogueBoxes.break_count(words)
		_expect(breaks == 1 and not words.contains("\n"), "%s at %d%%: a box past the rules (%d rows, %d characters) is one sentence or clause: %s" % [code, roundi(TextSize.factor * 100.0), rows.size(), words.length(), box.c_escape()])
	# A written line break is the English layout (a translation drops it, DESIGN.md "Layout breaks never
	# bind a translation"), so only rows the wrap chose are judged.
	# Text whose rows break only at spaces (Korean, DialogueBoxes.breaks_at_spaces) breaks at a space,
	# never between two syllables of a word (PR L12's stills: "있" / "다."); its rows are as even as
	# whole words allow, so the balance is asked only of rows the wrap chose.
	if limit == 0 and rows.size() == 2 and DialogueBoxes.breaks_at_spaces(words):
		_expect(not keeps or " ".join(rows) == words, "%s at %d%%: two rows break at a space (%s)" % [code, roundi(TextSize.factor * 100.0), rows])
	elif limit == 0 and rows.size() == 2 and not words.contains("\n"):
		_expect(_balanced(rows, font, size), "%s at %d%%: two rows are balanced (%s)" % [code, roundi(TextSize.factor * 100.0), rows])
	return keeps


## Chinese, Japanese and Korean samples (neutral fixtures, not game text; the shipped catalogs are
## checked by _check_every_language) at every TextSize step: they split without a character changed
## into boxes that keep the language's rules, each two-row box balanced so no short word is left alone
## on the last row, and the language's bundled font draws every character. Two rows break at a comma
## or (Korean) a space past the middle rather than inside a word (PR L12).
func _check_cjk_samples() -> void:
	var samples: Dictionary = {
		"ja": "今日は雨が降っている。傘を持って出かけよう。駅まで歩いて十分かかる。電車は少し遅れているらしい。",
		"zh_Hans": "今天下雨了。我们带上伞出门吧。走到车站要十分钟。听说火车晚点了一会儿。我们只好在站台上等着。",
		"zh_Hant": "今天下雨了。我們帶上傘出門吧。走到車站要十分鐘。聽說火車晚點了一會兒。我們只好在月台上等著。",
		"ko": "오늘은 비가 온다. 우산을 가지고 나가자. 역까지 걸어서 십 분 걸린다. 기차가 조금 늦는다고 한다.",
	}
	var none: Array[String] = []
	for code: String in samples:
		I18n.apply(code)
		var sample: String = samples[code]
		_expect(I18n.missing_glyphs(sample, story.get_theme_font(&"font")).is_empty(), "%s: the bundled font draws the sample (missing: %s)" % [code, I18n.missing_glyphs(sample, story.get_theme_font(&"font"))])
		for step: float in TextSize.STEPS:
			_use_size(step)
			var font: Font = story.get_theme_font(&"font")
			var size: int = story.get_theme_font_size(&"font_size")
			var width: float = game.call("_dialogue_column_width")
			var boxes: Array[String] = DialogueBoxes.split(sample, none, DialogueBoxes.fits.bind(font, size, width, code), code)
			_expect(boxes.size() > 1 and _letters("".join(boxes), none) == _letters(sample, none), "%s at %d%%: the sample splits into %d boxes without a character changed" % [code, roundi(step * 100.0), boxes.size()])
			for box: String in boxes:
				_expect(_check_language_box(box, none, font, size, width, code), "%s at %d%%: the box keeps the rules: %s" % [code, roundi(step * 100.0), box])
	I18n.apply(I18n.FALLBACK)
	_use_size(1.0)
	# Two rows break after the comma past the middle; the evenest width alone would split the verb
	# (降り出したの / で、). A comma before the middle is passed over: its second row would not fit.
	# Korean breaks at a space: the text server would break between any two syllables (PR L12).
	for case: Array in [["ja", "雨が降り出したので、駅まで歩いた。", "、"], ["ja", "雨なので、私たちは駅までゆっくり歩いていった。", ""], ["ko", "오늘은 비가 와서 우리는 역까지 천천히 걸어갔다.", " "]]:
		I18n.apply(case[0])
		var mark_font: Font = story.get_theme_font(&"font")
		var mark_size: int = story.get_theme_font_size(&"font_size")
		var text: String = case[1]
		var column: float = ceilf(mark_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, mark_size).x * 0.75)
		var shown: String = DialogueBoxes.keep_words(text, mark_font, mark_size, column)
		var mark_rows: Array[String] = DialogueBoxes.row_texts(shown, mark_font, mark_size, DialogueBoxes.wrap_width(shown, mark_font, mark_size, column, 0))
		var at_break: bool = mark_rows.size() == 2 and (mark_rows[0].ends_with("、") if case[2] == "、" else " ".join(mark_rows) == text)
		_expect(mark_rows.size() == 2 and _balanced(mark_rows, mark_font, mark_size) and at_break == (case[2] != ""), "%s: two rows break at a comma or space past the middle, never inside a word (%s)" % [case[0], mark_rows])
	I18n.apply(I18n.FALLBACK)
	# A station name written without spaces breaks between its words above 100% (TextSize.wrap_world_label).
	I18n.apply("ja")
	_use_size(2.0)
	var plate: Label = (game.get_node("BreakerLabel") as Label).duplicate() as Label
	plate.text = "非常用電源制御盤"
	game.add_child(plate)
	TextSize.wrap_world_label(plate, 13)
	_expect(plate.get_line_count() > 1, "a Japanese station name breaks between its words at 200%% (%d rows)" % plate.get_line_count())
	plate.free()
	I18n.apply(I18n.FALLBACK)
	_use_size(1.0)


## Sets TEXT SIZE to [param step] (a TextSize.STEPS factor) without Settings, and lays the game's text
## out again at it, so the Story label's font size and the dialogue column are read at that size.
func _use_size(step: float) -> void:
	TextSize.factor = step
	game.call("_apply_text_size")


## Whether two [param rows] are balanced: the shorter is at least half as wide as the longer, so no
## short word is left alone on a row.
static func _balanced(rows: Array[String], font: Font, size: int) -> bool:
	var first: float = font.get_string_size(rows[0], HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
	var second: float = font.get_string_size(rows[1], HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
	return minf(first, second) >= 0.5 * maxf(first, second)


## [param text] with the speaker tags of [param tags] and every space and line break taken out: the
## letters a split must keep, in order, in languages written with or without spaces.
static func _letters(text: String, tags: Array[String]) -> String:
	var plain: String = text
	for tag: String in DialogueBoxes.longest_first(tags):
		plain = plain.replace(tag + ": ", "")
	return plain.replace(" ", "").replace("\n", "")


## The length in characters of the longest of [param rows] (0 for none). Used by _check_box and
## _measure_shown against DialogueBoxes.MAX_ROW_CHARACTERS.
static func _longest_row(rows: Array[String]) -> int:
	var longest: int = 0
	for row: String in rows:
		longest = maxi(longest, row.length())
	return longest


## Whether [param text] names a speaker inside it ("TAG: " for any of [param tags]), which would put
## two speakers in one box. Used by _check_box and _measure_shown.
static func _names_inline(text: String, tags: Array[String]) -> bool:
	for tag: String in tags:
		if text.contains(tag + ": "):
			return true
	return false


## The words of [param text] with the speaker tags taken out, in order.
static func _words(text: String, tags: Array[String]) -> PackedStringArray:
	var plain: String = text.replace("\n", " ")
	for tag: String in DialogueBoxes.longest_first(tags):
		plain = plain.replace(tag + ": ", " ")
	return plain.split(" ", false)


## Every line constant in Main (the trust line's boxes, the refusals and the opening exchange too) and
## JunctionRoom's knockdown cards, and every string literal main.gd says through status_line, _tell,
## _say, _say_next or _aside or marks as a story line written in place (with "%s" as the engineer's name,
## {NAME} where it is a tag, and "%d" as a number), and WOLF's callbacks on each relay route. A line
## composed from pieces is read piece by piece, as each is its own message.
func _corpus() -> Array[String]:
	var out: Array[String] = []
	var constants: Dictionary = (load(MAIN_SCRIPT) as Script).get_script_constant_map()
	for name: String in constants:
		if name.ends_with("_LINE") or name.ends_with("_LINES") or name.ends_with("_QUESTION") or name.ends_with("_WARNING") or name.contains("_LINE_") or name.begins_with("REFUSE_") or name == "OPENING_EXCHANGE":
			var value: Variant = constants[name]
			if value is String:
				out.append(_fill(value))
			elif value is Array:
				for line: Variant in value:
					out.append(_fill(str(line)))
	var junction: Dictionary = (load("res://scripts/junction_room.gd") as Script).get_script_constant_map()
	for name: String in junction:
		if name.ends_with("_REASON"):
			out.append(_fill(str(junction[name])))
	var literal: RegEx = RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	# Only tags, placeholders and choice numbers ("%s WOLF: %s\n%s: %s"): the frame a line is composed in,
	# whose pieces are their own literals (localization PR L7c keeps a speaker's words apart).
	var frame: RegEx = RegEx.create_from_string("^(?:%[sd]|WOLF|DIRECTOR|PURGE|[\\s:/\"0-9])*$")
	var source: String = FileAccess.get_file_as_string(MAIN_SCRIPT)
	var story_marked: bool = false
	for line: String in source.split("\n"):
		var code: String = line.strip_edges()
		if code.begins_with("#"):
			# A story line written in place: its marks stand in the comment right above it (StoryText's notes).
			if code.contains("i18n:") and code.get_slice("i18n:", 1).split(" ", false).has("story"):
				story_marked = true
			continue
		var said_at: int = -1
		for call: String in ["status_line = ", "_tell(", "_say_next(", "_say([", "_aside("]:
			if line.contains(call):
				said_at = line.find(call)
		if story_marked:
			said_at = 0
		story_marked = false
		if said_at < 0:
			continue
		for found: RegExMatch in literal.search_all(line.substr(said_at)):
			var text: String = found.get_string(1).c_unescape()
			if text.contains(" ") and frame.search(text) == null:
				out.append(_fill(text))
	# The safe point's callbacks, on each relay route.
	for route: Array in [[M0State.PRESS, "human"], [M0State.DISCLOSE, "wolf"], [M0State.DISCLOSE, "human"]]:
		var state: M0State = M0State.new()
		state.record_choice(route[0])
		state.arm_breaker()
		state.activate_power(route[1])
		state.reach_checkpoint()
		out.append("Safe point saved. " + state.checkpoint_callback())
	return out


static func _fill(text: String) -> String:
	return text.replace("%s:", "{NAME}:").replace("%s", "{name}").replace("%d", "8")


## Measures the box on screen now, at the current text size.
func _measure_shown(context: String) -> void:
	if not bar.visible or story.text.is_empty():
		return
	shown_checked += 1
	var font: Font = story.get_theme_font(&"font")
	var size: int = story.get_theme_font_size(&"font_size")
	var rows: Array[String] = DialogueBoxes.row_texts(story.text, font, size, story.size.x)
	var longest: int = _longest_row(rows)
	var tags: Array[String] = game.call("_speaker_tags")
	var inline: bool = _names_inline(story.text, tags)
	_expect(story.get_line_count() == rows.size(), "the shown box wraps as measured (%s)" % context)
	if is_equal_approx(TextSize.factor, 1.0):
		_expect(rows.size() <= 2 and longest <= 42, "%s: the shown box takes %d rows, the longest %d characters: %s" % [context, rows.size(), longest, story.text.c_escape()])
	else:
		rows_at_200 = maxi(rows_at_200, rows.size())
	_expect(not inline and (speaker.text.is_empty() or speaker.text in tags), "%s: one speaker, named in the speaker column" % context)
	var box: Rect2 = bar.get_global_rect()
	_expect(box.position.x >= 0.0 and box.end.x <= 960.0 and box.position.y >= 0.0 and box.end.y <= 540.0, "%s: the dialogue box stays on the canvas (%s)" % [context, box])
	_expect(story.position.y + story.size.y <= bar.size.y + 0.5 and story.get_line_count() * story.get_line_height() <= story.size.y + 0.5, "%s: the words fit inside the box" % context)


## Runs the game for [param seconds] of game time in 1/60 s steps, measuring every box shown (unless
## [param measure] is false: the English box rules do not hold another language's boxes, which
## _check_every_language checks on their own).
func _play(seconds: float, context: String, measure: bool = true) -> void:
	var last: String = ""
	for _step: int in roundi(seconds * 60.0):
		game.call("_process", 1.0 / 60.0)
		if measure and story.text != last:
			last = story.text
			_measure_shown(context)
	await process_frame


## P0-13 and the opening, box by box: one box per press, the beat's next box first.
func _check_opening() -> void:
	game.new_game_button.pressed.emit()
	await process_frame
	var hint: Label = game.get_node("CanvasLayer/ContextHint/Text") as Label
	_expect(hint.text.contains(Main.SKIP_OPENING_HINT) and (game.get_node("CanvasLayer/ContextHint") as Control).visible, "the opening's first box says PAUSE skips the opening (%s)" % hint.text.c_escape())
	_measure_shown("opening")
	var pressed: int = 0
	while game.intro_active and game.intro_step < Main.INTRO_LINES.size() and pressed < 40:
		var step: int = game.intro_step
		var index: int = game.dialogue_index
		# Pressed inline, press first: the suites' _tap helpers wait a frame before pressing, and that
		# leading frame would let the box read here change before the press lands.
		Input.action_press(&"interact")
		await process_frame
		Input.action_release(&"interact")
		await process_frame
		pressed += 1
		if game.intro_active and game.intro_step < Main.INTRO_LINES.size():
			_expect(game.intro_step == step and game.dialogue_index == index + 1 or game.intro_step == step + 1 and game.dialogue_index == 0, "a press in the opening shows the next box (beat %d box %d -> beat %d box %d)" % [step, index, game.intro_step, game.dialogue_index])
			_expect(not hint.text.contains(Main.SKIP_OPENING_HINT), "only the first box carries the skip hint")
			_measure_shown("opening")
	_expect(pressed > Main.INTRO_LINES.size(), "the opening's multi-speaker beats take a box per speaker (%d presses for %d beats)" % [pressed, Main.INTRO_LINES.size()])
	await create_timer(1.0).timeout
	_expect(not game.intro_active, "the last press fades into play")


## P0-8 (TEACH-7): the first controllable frame shows one text element and one prompt, then the
## tutorial after the first step, then the lines.
func _check_first_control() -> void:
	game.debug_new_game(true)
	await process_frame
	game.call("_refresh_ui")
	var hint_panel: Control = game.get_node("CanvasLayer/ContextHint") as Control
	var tutorial: Control = game.get_node("CanvasLayer/TutorialPrompt") as Control
	var tutorial_text: Label = tutorial.get_node("Text") as Label
	_expect(game.human.controlled and game.top_card.visible and game.hud.text.contains("MAINTENANCE ENGINEER"), "control starts with the name card")
	_expect(tutorial.visible and tutorial_text.get_line_count() == 1 and tutorial_text.text.ends_with("MOVE"), "and one prompt: move (%s)" % tutorial_text.text.c_escape())
	_expect(not bar.visible and not hint_panel.visible, "and no dialogue box or hint bar on the first controllable frame")
	await _play(2.0, "first control, standing")
	_expect(not bar.visible, "the lines wait for the first step")
	Input.action_press(&"move_right")
	await _play(0.1, "first step")
	Input.action_release(&"move_right")
	_expect(tutorial_text.text.contains("READ DISPLAY (optional)") and not bar.visible, "the first step brings the rest of the tutorial, not the lines yet")
	# The name card fades (a tween, in real time) while its last moments run out. Run out in game time
	# by its state (_step_game_time), not a fixed time, so a loaded machine cannot leave it still
	# fading at the check.
	await _play(Main.TOP_CARD_FADE_SECONDS, "after the first step")
	await _step_game_time(game, func() -> bool: return not game.top_card.visible, 10.0)
	await _play(0.1, "after the name card")
	_expect(not game.top_card.visible and bar.visible and story.text.begins_with("%s keeps WOLF's systems running." % game.call("_first_name")), "once the name card has gone the lines start, one box at a time (%s)" % story.text.c_escape())
	_expect(not hint_panel.visible, "the hint bar stays off while the tutorial prompt is the prompt")
	# Only the test's own steps move the game's clock here, so a slow frame between them on a loaded
	# machine cannot run the box out early.
	game.set_process(false)
	var first_box_seconds: float = DialogueBoxes.read_seconds(story.text) - game.dialogue_age
	var first_box: String = story.text
	await _play(first_box_seconds - 0.1, "trust line")
	_expect(story.text == first_box, "a box stays up for its reading time")
	await _play(0.2, "trust line")
	_expect(story.text != first_box and speaker.text.is_empty(), "then the next box takes its place (%s)" % story.text.c_escape())
	game.set_process(true)
	var narration_width: float = bar.size.x
	_expect(absf(story.position.x - Main.DIALOGUE_PADDING.x) <= 0.5 and absf(narration_width - (Main.DIALOGUE_PADDING.x * 2.0 + story.size.x)) <= 0.5, "a narration box is only as wide as its words' column, with no empty name column (%s)" % bar.size)
	await _play(14.0, "opening lines")
	_expect(speaker.text in ["WOLF", (game.call("_first_name") as String).to_upper()] or game.status_line == Main.STAKES_LINE, "WOLF and the engineer each get their own boxes")
	if not speaker.text.is_empty():
		_expect(bar.size.x > narration_width, "a speaker's box adds the name column (%s vs %s)" % [bar.size.x, narration_width])


## The stakes and the relay question at the breaker; a box per speaker as WOLF answers.
func _check_corridor() -> void:
	game.debug_tools.actions.set_relay(&"press")
	game.debug_tools.actions.jump(&"relay_question")
	await process_frame
	_expect(game.waiting_for_choice and speaker.text == "WOLF" and story.text.contains("COOLANT FAULT"), "the relay question stands in WOLF's box")
	_measure_shown("relay question")
	await _play(8.0, "relay question")
	_expect(bar.visible and story.text.contains("COOLANT FAULT"), "a question stays up until it is answered")
	game.call("_answer_choice", 2)
	await _play(6.0, "WOLF refuses")
	# Standing still, the read line stays; walking on clears it (STORY-8).
	_expect(bar.visible, "a read line stays while the engineer stands")
	Input.action_press(&"move_right")
	await _play(0.2, "walking on")
	Input.action_release(&"move_right")
	_expect(not bar.visible, "a read line clears once the engineer moves on")
	var hint_panel: Control = game.get_node("CanvasLayer/ContextHint") as Control
	var hint_rect: Rect2 = hint_panel.get_global_rect()
	_expect(hint_panel.visible and absf(hint_rect.end.y - Main.DIALOGUE_BOTTOM) <= 0.5, "with no box up the hint bar takes the box's place at the bottom (%s)" % hint_rect)
	game.call("_interact")
	await _play(0.1, "said again")
	_expect(bar.visible or game.status_line.is_empty(), "the next line shows again")


## Records' exit: securing the first copy keeps control; its closing lines run while the engineer
## walks, USE there goes through them, and they clear once read and walked away from.
func _check_records_exit() -> void:
	await _to_records_mirror()
	_place_at_records_exit()
	game.call("_interact")
	await _play(0.6, "records exit")
	_expect(not game.chapter_close_active and game.human.controlled, "securing the first copy holds no closing shot: the engineer keeps control")
	_expect(game.state.chapter_complete and story.text == "FIRST COPY SECURED.", "the closing lines start with their first box (%s)" % story.text.c_escape())
	var hint: Label = game.get_node("CanvasLayer/ContextHint/Text") as Label
	await _play(2.0, "records exit")
	_expect(speaker.text == "WOLF" and hint.text.ends_with("continue."), "WOLF's box follows, and USE at the exit offers to continue (%s)" % hint.text)
	game.call("_interact")
	await _play(0.05, "records exit")
	_expect(game.state.chapter_id == "records" and speaker.text == (game.call("_first_name") as String).to_upper(), "USE at the exit shows the next box rather than leaving")
	var seconds: float = DialogueBoxes.read_seconds(story.text)
	Input.action_press(&"move_left")
	await _play(seconds + 0.1, "records exit, walking")
	Input.action_release(&"move_left")
	_expect(not bar.visible, "walking on after the last box has been read clears it (no hold at the exit)")
	_place_at_records_exit()
	game.call("_interact")
	await process_frame
	# The press walks them out through the open door (Main._leave_records); the junction starts once
	# they are through, on the game's own frames, so this waits on the wall clock with a bound.
	_expect(game.records_exit_walking, "with the lines read, USE at the exit walks out through the door")
	await _wait_real(func() -> bool: return game.state.chapter_id == "junction", 15000)
	_expect(game.state.chapter_id == "junction", "and the walk out goes on to the junction")


## The relay question with WOLF disclosed (DebugActions), on screen: one frame for the jump to land,
## then the HUD refreshed, so the answer buttons are laid out for the current device and text size.
func _to_relay_question() -> void:
	game.debug_tools.actions.set_relay(&"disclose_wolf")
	game.debug_tools.actions.jump(&"relay_question")
	await process_frame
	game.call("_refresh_ui")


## Waits process frames until [param condition] holds or [param limit_ms] of wall-clock time have
## passed (it returns either way; the caller checks). For steps the game runs on each frame's real
## delta, such as the walk out of Records: headless frames on an idle machine run
## far faster than 1/60 s, so no frame count bounds them. The suite kit's waits count physics frames
## on purpose (game_suite.gd's header), so this wall-clock wait stays in this kit.
func _wait_real(condition: Callable, limit_ms: int) -> void:
	var waited_from: int = Time.get_ticks_msec()
	while not condition.call() and Time.get_ticks_msec() - waited_from < limit_ms:
		await process_frame


## Records Access with the purge trace and the mirror done (WOLF's relay disclosure, WOLF's readout),
## one process frame after the debug jump, so only the exit is left.
func _to_records_mirror() -> void:
	var acts: DebugActions = game.debug_tools.actions
	acts.set_relay(&"disclose_wolf")
	acts.set_mirror(&"wolf")
	acts.jump(&"records_mirror")
	await process_frame


## The engineer at Records' exit station (Main.RECORDS_STATIONS[2]), on the side they walk up to it
## from, with WOLF the follow gap behind; standing still, controls updated (Main.debug_place).
func _place_at_records_exit() -> void:
	var exit_side: float = game.debug_station_side_x(Main.RECORDS_STATIONS[2], 829.0)
	game.debug_place(exit_side, exit_side - M0Actor.FOLLOW_GAP)


## The junction's entry lines and the knockdown cards split into boxes as they show.
func _check_junction() -> void:
	await _play(12.0, "junction entry")
	for kind: StringName in [&"vent", &"blast", &"sentry", &"cloud"]:
		game.debug_tools.actions.set_relay(&"press")
		game.debug_tools.actions.jump(&"lane")
		await process_frame
		game.debug_knock_down(kind)
		await _play(6.0, "knockdown card %s" % kind)


## A station's answer cutting into a story line said through the queue never drops it: Records'
## closing lines (the engineer keeps control while they play) come back after the route hint at the
## box they were on, and USE at the exit brings them back first; WOLF's stakes line comes back after
## the purge display.
func _check_story_kept() -> void:
	await _to_records_mirror()
	var close: String = game._records_close_line()
	_place_at_records_exit()
	game.call("_interact")
	await _play(2.6, "records close kept")
	_expect(game.status_line == close and speaker.text == "WOLF", "WOLF's box of the closing lines is up (%s)" % story.text.c_escape())
	# Just outside the exit's reach (772 to 888) USE answers with the route hint.
	game.debug_place(740.0, 740.0 - M0Actor.FOLLOW_GAP)
	game.call("_interact")
	await process_frame
	_expect(game.status_line == game.call("_records_route_hint") and game.box_queue == [close], "the route hint cuts in and the closing lines wait behind it (%s, %s)" % [game.status_line.c_escape(), str(game.box_queue).c_escape()])
	await _play(Main.box_seconds(game.status_line) + 0.2, "records close kept")
	_expect(game.status_line == close and speaker.text == "WOLF", "the closing lines come back at WOLF's box, not their first (%s)" % story.text.c_escape())
	# Cut in again, then USE at the exit: the lines come back first, and the engineer's box follows.
	game.call("_interact")
	_place_at_records_exit()
	game.call("_refresh_ui")
	var hint: Label = game.get_node("CanvasLayer/ContextHint/Text") as Label
	_expect(hint.text.ends_with("continue."), "with the closing lines held back, USE at the exit offers to continue (%s)" % hint.text)
	game.call("_interact")
	await process_frame
	_expect(game.state.chapter_id == "records" and game.status_line == close and speaker.text == "WOLF", "USE at the exit brings the held-back lines back rather than leaving (%s)" % story.text.c_escape())
	game.call("_interact")
	await process_frame
	_expect(game.state.chapter_id == "records" and speaker.text == (game.call("_first_name") as String).to_upper() and story.text.ends_with("Then Archive is next."), "the engineer's closing box follows (%s)" % story.text.c_escape())
	# WOLF's stakes line, read over at the purge display.
	game.debug_new_game(true)
	await process_frame
	game.set("opening_lines_held", false)
	game.call("_drop_box_queue")
	game.debug_place(Main.PURGE_DISPLAY_MAX_X - 10.0, 80.0)
	game.call("_speak_stakes")
	await _play(0.5, "stakes kept")
	game.call("_interact")
	await process_frame
	_expect(str(game.status_line).begins_with("DIRECTOR / PURGE") and game.box_queue == [Main.STAKES_LINE], "the purge display cuts in and WOLF's stakes line waits behind it")
	# The display's text shows as two boxes; the stakes follow once both have been up their time.
	var display_seconds: float = 0.0
	for box: String in game.dialogue_boxes:
		display_seconds += DialogueBoxes.read_seconds(DialogueBoxes.words_of(box, game.call("_speaker_tags")))
	await _play(display_seconds + 0.2, "stakes kept")
	_expect(game.status_line == Main.STAKES_LINE, "the stakes line comes back after the display's text (%.1f s)" % display_seconds)
	# Held back again, USE at the breaker brings it back before WOLF asks about the relay.
	game.call("_interact")
	game.debug_place(350.0, 270.0)
	game.call("_interact")
	await process_frame
	_expect(game.status_line == Main.STAKES_LINE and not game.waiting_for_choice, "USE at the breaker brings the held-back stakes line back before the relay question")


## P0-10: on touch the answers sit at the bottom without numbers, the hint names the button on screen
## and stays clear of USE. In [param code] other than English (localization PR L8) only the places are
## checked: the answers apart at the bottom corners, the hint bar clear of the buttons and the box; the
## English words (the answers, CRANK, the tutorial's line) are English's alone.
func _check_touch(code: String = I18n.FALLBACK) -> void:
	var english: bool = code == I18n.FALLBACK
	game.touch_enabled = true
	game.controller_active = false
	await _to_relay_question()
	var choice_1: Button = game.get_node("CanvasLayer/TouchControls/Choice1") as Button
	var choice_2: Button = game.get_node("CanvasLayer/TouchControls/Choice2") as Button
	if english:
		_expect(choice_1.visible and not choice_1.text.begins_with("1") and not choice_2.text.begins_with("2") and choice_1.text == M0State.CHOICE_TEXT[M0State.DISCLOSE], "touch answers carry no number (%s / %s)" % [choice_1.text, choice_2.text])
	_expect(choice_1.position.y > 300.0 and choice_2.position.y > 300.0 and choice_1.get_global_rect().end.y <= bar.get_global_rect().position.y and choice_1.position.x < 100.0 and choice_2.get_global_rect().end.x > 860.0, "%s: touch answers sit at the bottom corners, just above the question (%s, %s)" % [code, choice_1.get_global_rect(), choice_2.get_global_rect()])
	_expect(not choice_1.get_global_rect().intersects(choice_2.get_global_rect()), "%s: the two answers do not overlap" % code)
	game.call("_answer_choice", 1)
	# At the valve the hint names CRANK, the button on screen, and stays clear of USE.
	game.debug_tools.actions.jump(&"junction_a")
	await process_frame
	game.debug_place(JunctionRoom.BREAKER_X + 30.0, JunctionRoom.WOLF_CLEAR_X)
	game.call("_interact")
	game.debug_place(Main.VALVE_CRANK_X, JunctionRoom.WOLF_CLEAR_X)
	game.call("_refresh_ui")
	var hint_panel: Control = game.get_node("CanvasLayer/ContextHint") as Control
	var hint: Label = hint_panel.get_node("Text") as Label
	var use: Button = game.get_node("CanvasLayer/TouchControls/Use") as Button
	if english:
		_expect(use.text == "CRANK" and hint.text.begins_with("HOLD CRANK:"), "on touch the crank hint names the CRANK button (%s)" % hint.text)
	for button: Button in [use, game.get_node("CanvasLayer/TouchControls/Left") as Button, game.get_node("CanvasLayer/TouchControls/Right") as Button]:
		_expect(not hint_panel.get_global_rect().intersects(button.get_global_rect()), "%s: the hint bar stays clear of %s (%s vs %s)" % [code, button.text, hint_panel.get_global_rect(), button.get_global_rect()])
	_expect(not hint_panel.get_global_rect().intersects(bar.get_global_rect()), "%s: the hint bar sits above the dialogue box" % code)
	if not english:
		game.touch_enabled = false
		return
	# The touch tutorial names its button in the same "button  action" form as the keys.
	game.debug_new_game(true)
	await process_frame
	Input.action_press(&"move_right")
	game.call("_process", 1.0 / 60.0)
	Input.action_release(&"move_right")
	var tutorial_text: Label = game.get_node("CanvasLayer/TutorialPrompt/Text") as Label
	_expect(tutorial_text.text.begins_with("USE  READ DISPLAY (optional)"), "the touch tutorial reads USE  READ DISPLAY (optional) (%s)" % tutorial_text.text.c_escape())
	game.touch_enabled = false


## The overlap checks of the English suite (tests/text_boxes_test.gd), in every other offered language and
## then under pseudolocalization (I18n.PSEUDO, English 30% longer, the stand-in for languages still to
## come): the touch answers and hint bar (_check_touch), the top card against PAUSE and DEBUG at 200%
## (_check_top_card_clear), the station names at every TEXT SIZE step with the touch layout
## (_check_station_names) and the prompts at every size (_check_prompts_clear). Localization PR L8
## runs these instead of writing an overlap check of its own (DESIGN.md, "The build's version"). The
## language is switched with the game running, as Settings does, then set back to English.
func _check_overlaps_every_language(path: String) -> void:
	var settings: GameSettings = game.settings_menu
	var codes: Array[String] = []
	for code: String in I18n.offered():
		if code != I18n.FALLBACK:
			codes.append(code)
	codes.append(I18n.PSEUDO)
	for code: String in codes:
		I18n.apply_for_checks(code)
		await process_frame
		await _check_touch(code)
		settings.text_size.select(TextSize.STEPS.size() - 1)
		settings.text_size.item_selected.emit(TextSize.STEPS.size() - 1)
		await _check_top_card_clear(code)
		await _check_station_names(code)
		await _check_prompts_clear(path, code)
		settings.text_size.select(0)
		settings.text_size.item_selected.emit(0)
	I18n.apply_for_checks(I18n.FALLBACK)


## The TEXT SIZE setting: 100% to 200%, saved, and every HUD text and station name scaled.
func _check_text_size(path: String) -> void:
	var settings: GameSettings = game.settings_menu
	_expect(settings.text_size != null and settings.text_size.item_count == 5 and settings.text_size.get_item_text(0) == "100%" and settings.text_size.get_item_text(4) == "200%", "Settings offers TEXT SIZE from 100% to 200%")
	var breaker_label: Label = game.get_node("BreakerLabel") as Label
	var base_label_bottom: float = breaker_label.position.y + breaker_label.size.y
	settings.text_size.select(4)
	settings.text_size.item_selected.emit(4)
	_expect(is_equal_approx(TextSize.factor, 2.0) and GameSettings.load_config(path).get_value("video", "text_size", 0.0) == 2.0, "choosing 200% applies and saves it")
	_expect(story.get_theme_font_size(&"font_size") == 46 and (game.get_node("CanvasLayer/ContextHint/Text") as Label).get_theme_font_size(&"font_size") == 28 and game.hud.get_theme_font_size(&"font_size") == 30 and (game.get_node("CanvasLayer/TutorialPrompt/Text") as Label).get_theme_font_size(&"font_size") == 34, "dialogue, hint, card and tutorial double")
	_expect(breaker_label.get_theme_font_size(&"font_size") == roundi(13 * TextSize.WORLD_MAX_FACTOR) and absf(breaker_label.position.y + breaker_label.size.y - base_label_bottom) <= 2.0, "station names grow to their cap (TextSize.WORLD_MAX_FACTOR) at 200%% and grow upward from where they stood (%d px)" % breaker_label.get_theme_font_size(&"font_size"))
	var junction_label: Label = game.junction_room.station_labels[0]
	_expect(junction_label.get_theme_font_size(&"font_size") == roundi(JunctionRoom.LABEL_FONT_SIZE * TextSize.WORLD_MAX_FACTOR) and game.records_room.station_labels[0].get_theme_font_size(&"font_size") == roundi(13 * TextSize.WORLD_MAX_FACTOR) and game.bypass_handle.fault_tag.get_theme_font_size(&"font_size") == roundi(BypassHandle.LABEL_FONT_SIZE * TextSize.WORLD_MAX_FACTOR), "the junction's, Records' and the bypass's plates grow too")
	# Boxes at 200% stay on the canvas, one speaker each; their rows are counted.
	game.debug_new_game(true)
	await process_frame
	Input.action_press(&"move_right")
	await _play(1.0, "200% opening lines")
	Input.action_release(&"move_right")
	await _play(20.0, "200% opening lines")
	await _check_top_card_clear(I18n.FALLBACK)
	_expect(rows_at_200 >= 1 and rows_at_200 <= 3, "at 200%% a box takes at most 3 rows (%d)" % rows_at_200)
	# A fresh game reads the saved size back; a broken value falls back to the nearest step.
	# Not end_game for this one: it would remove the settings file the first game still saves to.
	var again: Main = await spawn_game("%s-again.json" % path, path) as Main
	_expect(is_equal_approx(TextSize.factor, 2.0) and again.settings_menu.text_size.selected == 4, "a new session opens at the saved 200%")
	again.queue_free()
	await process_frame
	await _check_station_names()
	await _check_prompts_clear(path)
	settings.text_size.select(0)
	settings.text_size.item_selected.emit(0)
	_expect(is_equal_approx(TextSize.factor, 1.0) and story.get_theme_font_size(&"font_size") == 23 and breaker_label.get_theme_font_size(&"font_size") == 13, "back at 100% everything returns to its size")
	_expect(is_equal_approx(TextSize.nearest_step(1.3), 1.25) and is_equal_approx(TextSize.nearest_step(9.0), 2.0) and is_equal_approx(TextSize.nearest_step(-1.0), 1.0), "a hand-edited size snaps to the nearest step")


## At 200% TEXT SIZE in [param code] (the language already applied, the size already chosen): Records'
## exit run for 12 s (its boxes measured in English only), the top card, hint bar, tutorial prompt and box
## on the canvas, the top card clear of PAUSE, the answers inside the side margin, and on touch the top
## card clear of DEBUG with its words still fitting. Called by _check_text_size in English and by
## _check_overlaps_every_language in every other language (localization PR L8).
func _check_top_card_clear(code: String) -> void:
	game.debug_tools.actions.jump(&"records_mirror")
	await process_frame
	_place_at_records_exit()
	game.call("_interact")
	await _play(12.0, "200% records exit", code == I18n.FALLBACK)
	for path_name: String in ["CanvasLayer/TopBar", "CanvasLayer/ContextHint", "CanvasLayer/TutorialPrompt", "CanvasLayer/BottomBar"]:
		var rect: Rect2 = (game.get_node(path_name) as Control).get_global_rect()
		_expect(rect.position.x >= 0.0 and rect.end.x <= 960.0 and rect.position.y >= 0.0 and rect.end.y <= 540.0, "%s: %s stays on the canvas at 200%% (%s)" % [code, path_name, rect])
	var card: Rect2 = game.top_card.get_global_rect()
	_expect(not card.intersects((game.get_node("CanvasLayer/PauseButton") as Control).get_global_rect()), "%s: the top card stays clear of PAUSE at 200%%" % code)
	# The answers keep the HUD's side margin (keys, under the top card), and on touch the top card
	# stays clear of the DEBUG button where it shows, its words still fitting.
	await _to_relay_question()
	for button_path: String in ["CanvasLayer/TouchControls/Choice1", "CanvasLayer/TouchControls/Choice2"]:
		var answer: Rect2 = (game.get_node(button_path) as Control).get_global_rect()
		_expect(answer.position.x >= Main.HUD_SIDE_MARGIN - 0.5 and answer.end.x <= 960.0 - Main.HUD_SIDE_MARGIN + 0.5, "%s: at 200%% the answer keeps the side margin (%s)" % [code, answer])
	game.call("_answer_choice", 1)
	game.touch_enabled = true
	game.controller_active = false
	game.debug_tools.call("_refresh_view")
	game.call("_refresh_ui")
	await process_frame
	var debug_button: Control = game.debug_tools.debug_button
	if debug_button.visible:
		_expect(not game.top_card.get_global_rect().intersects(debug_button.get_global_rect()), "%s: at 200%% on touch the top card stays clear of DEBUG (%s vs %s)" % [code, game.top_card.get_global_rect(), debug_button.get_global_rect()])
		_expect(game.hud.get_line_count() * game.hud.get_line_height() <= game.hud.size.y + 1.0, "%s: the narrower top card still fits its words (%d rows)" % [code, game.hud.get_line_count()])
	else:
		print("text boxes: the DEBUG button is not shown in this build; its check is skipped")
	game.touch_enabled = false
	game.debug_tools.call("_refresh_view")


## At every text size the station names in each room, in each state, stay apart: a name breaks
## between its words above 100% (TextSize.WORLD_ROW_GROWTH) instead of running into its neighbours,
## stands where it stood at 100% (its bottom edge), and the corridor's are not faded out at the start
## (the MANUAL BYPASS plate, at the view's edge there, once the engineer walks towards it). Run in
## English and, by _check_overlaps_every_language, in [param code], every other language (PR L8).
func _check_station_names(code: String = I18n.FALLBACK) -> void:
	var settings: GameSettings = game.settings_menu
	var bottoms: Dictionary = {}
	for index: int in TextSize.STEPS.size():
		settings.text_size.select(index)
		settings.text_size.item_selected.emit(index)
		var percent: int = roundi(TextSize.STEPS[index] * 100.0)
		for jump: StringName in [&"corridor_start", &"records_mirror", &"junction_a", &"lane", &"tank_down"]:
			game.debug_tools.actions.jump(jump)
			for frame: int in 3:
				await process_frame
			var labels: Array[Label] = shown_station_labels(game)
			for label: Label in labels:
				var rect: Rect2 = label.get_global_rect()
				var key: String = "%s|%s|%s" % [jump, label.get_path(), label.text]
				if index == 0:
					bottoms[key] = rect.end.y
				elif bottoms.has(key) and label != game.get_node("RelayLabel"):
					_expect(absf(rect.end.y - float(bottoms[key])) <= 1.5, "%s, %d%%, %s: %s keeps its bottom edge where it was at 100%% (%.1f vs %.1f)" % [code, percent, jump, label.text, rect.end.y, bottoms[key]])
			for overlap: String in overlapping_labels(labels):
				_expect(false, "%s, %d%%, %s: no two station names overlap, but %s" % [code, percent, jump, overlap])
			if jump == &"corridor_start":
				for label: Label in [game.get_node("BreakerLabel"), game.get_node("RelayLabel"), game.bypass_handle.fault_tag] as Array[Label]:
					_expect(label.modulate.a > 0.99, "%s, %d%%: %s is not faded at the corridor's start (alpha %.2f)" % [code, percent, label.text, label.modulate.a])
				# The MANUAL BYPASS plate (the engineer-only fallback) stands at the view's right edge at the
				# start: a little faded at 100%, faded out at larger sizes (it grows to the right, clear of the
				# relay's names). Standing beside the relay, where WOLF points to the bypass when he refuses,
				# the engineer sees it in full.
				# Layout L1 (decided 2026-10-14): first control's view starts at x -40 so the opening into the
				# dock bay shows, which can carry the plate to the view's right edge, where it is faded out.
				if index == 0:
					var plate: Label = game.bypass_handle.bypass_label
					var view: Rect2 = game.get_viewport().get_canvas_transform().affine_inverse() * game.get_viewport().get_visible_rect()
					var at_edge: bool = plate.get_global_rect().end.x > view.end.x - JunctionRoom.LABEL_EDGE_FADE
					_expect(plate.modulate.a > 0.5 or at_edge, "%s, 100%%: MANUAL BYPASS shows at the corridor's start, or waits faded at the view's right edge (alpha %.2f)" % [code, plate.modulate.a])
				# The camera eases after the engineer in time, not frames: once it has its new target it is
				# snapped there, so the check does not depend on how fast the frames run.
				game.debug_place(Main.RELAY_SIDE_X, Main.RELAY_SIDE_X - 120.0)
				await process_frame
				game.intro_camera.reset_smoothing()
				for frame: int in 3:
					await process_frame
				_expect(game.bypass_handle.bypass_label.modulate.a > 0.99, "%s, %d%%: MANUAL BYPASS shows in full with the engineer beside the relay (alpha %.2f)" % [code, percent, game.bypass_handle.bypass_label.modulate.a])
				var relay_name: Rect2 = (game.get_node("RelayLabel") as Label).get_global_rect()
				_expect(relay_name.end.y <= game.bypass_handle.fault_tag.get_global_rect().position.y + 0.5, "%s, %d%%: COOLANT RELAY stands above its COOLANT FAULT tag" % [code, percent])
		await _check_touch_layout(percent, code)
		# The valve's plate changes its words as it is worked ("VALVE  0 / 3" keeps a double space):
		# each stands on the same line and clears the LINE caption by the dial.
		game.debug_tools.actions.jump(&"junction_a")
		await process_frame
		var room: JunctionRoom = game.junction_room
		var plate_bottom: float = JunctionRoom.LABEL_Y + room.valve_label.get_theme_font(&"font").get_height(JunctionRoom.LABEL_FONT_SIZE) + room.valve_label.get_theme_stylebox(&"normal").get_minimum_size().y
		for text: String in ["VALVE", "VALVE  0 / 3", "FUSE LIT", "VALVE SPENT"]:
			room.valve_label.text = text
			room.refit_labels()
			await process_frame
			await process_frame
			var plate: Rect2 = Rect2(room.valve_label.position, room.valve_label.size)
			_expect(absf(plate.end.y - plate_bottom) <= 1.5, "%s, %d%%: the %s plate stands on its line (bottom %.1f, expected %.1f)" % [code, percent, text.c_escape(), plate.end.y, plate_bottom])
			_expect(not plate.intersects(Rect2(room.line_caption.position, room.line_caption.size)), "%s, %d%%: the %s plate clears the LINE caption" % [code, percent, text.c_escape()])
			# English breaks a plate at its spaces, greedily, as it always has (TextSize._space_rows), so
			# "VALVE  0" keeps its first row whole; the text server's word rules would break it as
			# "VALVE" / "0 / 3", a narrower plate (PR L7d review).
			if code == I18n.FALLBACK and text == "VALVE  0 / 3" and room.valve_label.get_line_count() > 1:
				var first_row: float = room.valve_label.get_theme_font(&"font").get_string_size("VALVE  0", HORIZONTAL_ALIGNMENT_LEFT, -1.0, room.valve_label.get_theme_font_size(&"font_size")).x
				_expect(room.valve_label.size.x >= first_row, "%d%%: the armed valve plate keeps \"VALVE  0\" on its first row (%.1f px wide, the row %.1f px)" % [percent, room.valve_label.size.x, first_row])


## At every text size, keys and touch, in a fresh game: the opening's hint bar stands below the top
## card, not on it, and after the first step the tutorial prompt (moved off the station names where
## it would cover the breaker's, see Main._tutorial_prompt_place) is checked on the step's own frame,
## before any box, and again once the opening lines' first box is up, so a slow machine cannot change
## what is checked. Run in English and, by _check_overlaps_every_language, in [param code], every other
## language (PR L8).
func _check_prompts_clear(path: String, code: String = I18n.FALLBACK) -> void:
	for touch: bool in [false, true]:
		for index: int in TextSize.STEPS.size():
			var fresh: Main = await spawn_game("%s-prompts.json" % path, "%s-prompts.cfg" % path, keep_running) as Main
			fresh.touch_enabled = touch
			fresh.settings_menu.text_size.select(index)
			fresh.settings_menu.text_size.item_selected.emit(index)
			var context: String = "%s, %d%%, %s" % [code, roundi(TextSize.STEPS[index] * 100.0), "touch" if touch else "keys"]
			fresh.new_game_button.pressed.emit()
			for frame: int in 40:
				await process_frame
			var hint_panel: Control = fresh.get_node("CanvasLayer/ContextHint") as Control
			_expect(fresh.intro_active and fresh.top_card.visible and hint_panel.visible and not hint_panel.get_global_rect().intersects(fresh.top_card.get_global_rect()), "%s: the opening's hint bar stands below the top card (%s vs %s)" % [context, hint_panel.get_global_rect(), fresh.top_card.get_global_rect()])
			fresh.debug_new_game(true)
			fresh.touch_enabled = touch
			for frame: int in 5:
				await process_frame
			# The frame of the first step: the name card starts its fade, so no box is up yet.
			Input.action_press(&"move_right")
			await process_frame
			_expect(not fresh.bottom_bar.visible, "%s: no box is up on the frame of the first step" % context)
			_check_prompt_clear(fresh, touch, false, context, code == I18n.FALLBACK)
			for frame: int in 5:
				await process_frame
			Input.action_release(&"move_right")
			# The first box waits for the name card's fade (Main.TOP_CARD_FADE_SECONDS), which the game
			# runs on each frame's real delta; it is run out in game time instead (_step_game_time), so
			# no wall-clock fade is waited for on each of the 10 games.
			await _step_game_time(fresh, func() -> bool: return fresh.bottom_bar.visible, 10.0)
			_check_prompt_clear(fresh, touch, true, context, code == I18n.FALLBACK)
			_expect(fresh.bottom_bar.visible, "%s: the opening lines' first box comes up while the tutorial prompt shows" % context)
			# A quick free, not end_game: its settle time on each of the 10 games adds up, and the files
			# are shared by every fresh game here, so they are removed once after the loop.
			stop_audio(fresh)
			fresh.queue_free()
			await process_frame
	for file: String in ["%s-prompts.cfg" % path, "%s-prompts.json" % path]:
		remove_file(file)


## The tutorial prompt in [param fresh] after the first step, with or without a box up ([param box_up]):
## on the canvas, over no station name, neither actor, the box, a top card that shows (one leaving
## goes at once when the prompt takes its place), PAUSE, DEBUG or the touch buttons, and
## over at most Main.TUTORIAL_ART_OVERLAP of its area of the machines. Where it waits hidden behind a
## box, the hint bar is empty too. Only in English ([param english]) is the prompt's line itself read.
func _check_prompt_clear(fresh: Main, touch: bool, box_up: bool, context: String, english: bool) -> void:
	context += ", box up" if box_up else ", no box yet"
	if not fresh.tutorial_prompt.visible:
		_expect(box_up and fresh.tutorial_prompt_slot == &"waiting" and not (fresh.get_node("CanvasLayer/ContextHint") as Control).visible, "%s: the tutorial prompt is hidden only while it waits behind a box, with the hint bar empty (%s)" % [context, fresh.tutorial_prompt_slot])
		return
	var prompt: Rect2 = fresh.tutorial_prompt.get_global_rect()
	# A long frame under load can carry the engineer past the display, where the prompt only points on.
	_expect((not english or fresh.tutorial_text.text.contains("right to the breaker.")) and prompt.position.y >= 0.0 and prompt.end.y <= Main.DIALOGUE_BOTTOM and prompt.position.x >= 0.0 and prompt.end.x <= 960.0, "%s: after the first step the tutorial prompt shows on the canvas (%s)" % [context, prompt])
	for label: Label in fresh._corridor_station_labels():
		if label.is_visible_in_tree() and label.modulate.a > 0.05:
			var name_rect: Rect2 = label.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, label.size)
			_expect(not prompt.intersects(name_rect), "%s: the tutorial prompt leaves %s readable (%s vs %s)" % [context, label.text.replace("\n", " "), prompt, name_rect])
	for sprite: Sprite2D in [fresh.human.body_sprite, fresh.wolf.body_sprite] as Array[Sprite2D]:
		_expect(not prompt.intersects(sprite.get_global_transform_with_canvas() * sprite.get_rect()), "%s: the tutorial prompt leaves %s uncovered" % [context, sprite.get_parent().name])
	# Summed here from the sprites, not through Main._station_art_overlap: the test's own measure is
	# the independent check of the game's placement rule.
	var art_overlap: float = 0.0
	for sprite: Sprite2D in [fresh.breaker_art, fresh.purge_terminal_art, fresh.relay_art] as Array[Sprite2D]:
		art_overlap += prompt.intersection(sprite.get_global_transform_with_canvas() * sprite.get_rect()).get_area()
	_expect(art_overlap <= prompt.get_area() * Main.TUTORIAL_ART_OVERLAP, "%s: the tutorial prompt lies over at most a tenth of its area of the machines (%.0f of %.0f)" % [context, art_overlap, prompt.get_area()])
	var others: Array[Control] = [fresh.pause_button]
	if fresh.top_card.visible:
		others.append(fresh.top_card)
	if box_up:
		others.append(fresh.bottom_bar)
	if fresh.debug_tools.debug_button.visible:
		others.append(fresh.debug_tools.debug_button)
	if touch:
		others.append_array([fresh.touch_left, fresh.touch_right, fresh.touch_use])
	for other: Control in others:
		_expect(not prompt.intersects(other.get_global_rect()), "%s: the tutorial prompt stays clear of %s (%s vs %s)" % [context, other.name, prompt, other.get_global_rect()])


## On touch at [param percent] in [param code]: a box, with a name or without, stays clear of ◀ ▶ and
## USE, and the corridor's names and the COOLANT FAULT tag stay clear of PAUSE.
func _check_touch_layout(percent: int, code: String) -> void:
	game.debug_tools.actions.jump(&"corridor_start")
	game.touch_enabled = true
	game.controller_active = false
	for line: String in [Main.STAKES_LINE, Main.JUNCTION_CLEARED_LINE]:
		game.status_line = line
		await process_frame
		await process_frame
		var box: Rect2 = bar.get_global_rect()
		_expect(bar.visible, "%s, %d%%, touch: the box shows (%s)" % [code, percent, line])
		for button: Control in [game.touch_left, game.touch_right, game.touch_use]:
			_expect(not box.intersects(button.get_global_rect()), "%s, %d%%, touch: the box stays clear of %s (%s vs %s)" % [code, percent, (button as Button).text, box, button.get_global_rect()])
		var hint_panel: Control = game.get_node("CanvasLayer/ContextHint") as Control
		if hint_panel.visible:
			_expect(not hint_panel.get_global_rect().intersects(box), "%s, %d%%, touch: the hint bar stays clear of the box" % [code, percent])
	var pause: Rect2 = game.pause_button.get_global_rect()
	for label: Label in [game.get_node("RelayLabel"), game.bypass_handle.fault_tag] as Array[Label]:
		var on_screen: Rect2 = label.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, label.size)
		_expect(not on_screen.intersects(pause), "%s, %d%%, touch: %s stays clear of PAUSE (%s vs %s)" % [code, percent, label.text, on_screen, pause])
	game.touch_enabled = false
	await process_frame

