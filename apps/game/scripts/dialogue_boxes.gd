class_name DialogueBoxes
extends RefCounted
## Splits a dialogue message into the boxes the bottom bar shows one after another, and says how long
## each needs on screen (STORY-2, STORY-3, STORY-4, STORY-10). Every box has one speaker (or is
## narration) and fits the dialogue column in MAX_ROWS rows. Splitting never changes a word: a message
## breaks only where the speaker changes, at its own line breaks and between sentences (inside a
## sentence only at a semicolon or comma, and only when the sentence alone is too long).

## Reading time per box (STORY-2): the larger of a base plus a time per character (capped) and the base
## plus this long per word, the reading time the October 13 wording drafts use (BBC subtitles allow
## about 0.33 s a word). Speaker tags are not counted. The time per character is one over the
## language's "reading_cps" in I18n.LANGUAGES (languages.json: Netflix's subtitle speeds, English 20
## characters a second, so 0.05 s; PR L7d), English's where a language has none yet.
const READ_SECONDS_BASE: float = 1.2
const READ_SECONDS_PER_WORD: float = 0.33
## English's cap on the per-character time. Other languages scale it by English's speed over theirs,
## so the cap covers the same number of characters (116) in every language: at Japanese's 4 characters
## a second a 7 s cap would cover only 28 (DESIGN.md, "Per-language reading speed").
const READ_SECONDS_MAX_BY_CHARACTERS: float = 7.0
## A box holds at most this many rows of the dialogue column (subtitle practice: two lines).
const MAX_ROWS: int = 2
## English's row limit in characters, the "row_characters" of the en row of languages.json
## (wrap_width narrows the wrap where a row would hold more). A language whose "row_characters" is null
## (Chinese, Japanese, Korean) runs its rows to the column width and splits a two-row box into two
## balanced rows instead (row_characters, DESIGN.md "Per-script row limits").
const MAX_ROW_CHARACTERS: int = 42
## A box of this many words or more is split at its sentence breaks even when it would fit. Its
## character equivalent is long_line_characters: the same reading time in characters.
const LONG_LINE_WORDS: int = 20
## A choice's response rows follow its question after this; the answer buttons show them instead.
const CHOICE_MARKER: String = "\n1  "
## The marks below hold Chinese and Japanese punctuation as \u escapes: they are marks the splitter
## reads, never text the game draws, and the English glyph check (tests/i18n_test.gd) reads every
## literal as text to draw. 3002 。, ff01 ！, ff1f ？, ff1b ；, ff0c ，, 3001 、, 300c 「, 300d 」,
## 300e 『, 300f 』, ff09 ）, 3011 】, 3015 〕.
## Marks that end a sentence. "…" counts as one; the Chinese and Japanese full stops need no space
## after them (NO_SPACE_MARKS). Spanish ¿ and ¡ open a sentence and end none, so they need no rule: a
## sentence breaks before them at the space after the last one's mark.
const SENTENCE_ENDS: String = ".!?…\u3002\uff01\uff1f"
## Marks a sentence too long for one box may break after, semicolons first, then commas (with the
## fullwidth forms and Japanese's 、).
const CLAUSE_MARKS: Array[String] = [";\uff1b", ",\uff0c\u3001"]
## Fullwidth marks a break follows directly: Chinese and Japanese write no space after them (the
## prototype measured a Japanese knockdown box one box too long without them).
const NO_SPACE_MARKS: String = "\u3002\uff01\uff1f\uff1b\uff0c\u3001"
## Characters a break never comes before, so "！？" and "。」" stay together on one side.
const NO_BREAK_BEFORE: String = ".!?…\u3002\uff01\uff1f\uff1b\uff0c\u3001\u300d\u300f\uff09\u3011\u3015”’»"
## Quotation openers and the closers each takes: a sentence inside a quotation never breaks the line.
## „ closes with “ in German and ” in Polish; " is its own closer.
const QUOTE_PAIRS: Dictionary = {"\"": "\"", "«": "»", "„": "“”", "“": "”", "\u300c": "\u300d", "\u300e": "\u300f"}


## The boxes [param message] is shown as, in order. Each is "TAG: words" for a speaker in
## [param speakers] or plain narration. [param fits] takes a box's words (without the tag) and says
## whether they fit the column in MAX_ROWS rows (the game and the tests pass [method fits] bound to
## their font, size and column). A line with no tag after a tagged one goes on in that speaker's voice,
## as the game's lines are written. [param language] (a code of I18n.LANGUAGES, "" for the one shown)
## sets the box's length limit ([method long_line_characters]).
static func split(message: String, speakers: Array[String], fits: Callable, language: String = "") -> Array[String]:
	var code: String = _language(language)
	var boxes: Array[String] = []
	for segment: Array in segments(message, speakers):
		for words: String in _fit(segment[1], fits, code):
			boxes.append(words if segment[0].is_empty() else "%s: %s" % [segment[0], words])
	return boxes


## Whether [param words] fit a column [param width] px wide in MAX_ROWS rows at [param font_size] px of
## [param font], wrapped by [param language]'s row rule ([method wrap_width] with
## [method row_characters]). The one fit rule: Main's dialogue box and tests/text_boxes_test.gd both
## split with it. Pure for a named [param language]; with "" it also reads the language shown.
static func fits(words: String, font: Font, font_size: int, width: float, language: String = "") -> bool:
	return rows(words, font, font_size, wrap_width(words, font, font_size, width, row_characters(language))).size() <= MAX_ROWS


## The most characters a dialogue row of [param language] holds ("row_characters" in I18n.LANGUAGES,
## MAX_ROW_CHARACTERS in English), or 0 where rows run to the column width and a two-row box is balanced
## (null in the table: Chinese, Japanese and Korean). "" is the language shown.
static func row_characters(language: String = "") -> int:
	return int(I18n.rule(_language(language), "row_characters", 0))


## [param language]'s reading speed in characters a second ("reading_cps"), English's where it has
## none yet. "" is the language shown.
static func reading_cps(language: String = "") -> float:
	return float(I18n.rule(_language(language), "reading_cps", _english_cps()))


## English's reading speed, the en row's "reading_cps" (20, the speed READ_SECONDS_MAX_BY_CHARACTERS
## and the old 0.05 s a character were written for), or 20 if the table lost it.
static func _english_cps() -> float:
	return float(I18n.rule(I18n.FALLBACK, "reading_cps", 20.0))


## The character equivalent of LONG_LINE_WORDS in [param language]: as many characters as its reader
## reads in the time LONG_LINE_WORDS words take (6.6 s): 132 in English and 112 in Spanish, more than
## two 42-character rows hold, so only the word limit binds there; 26 in Japanese (4 characters a
## second), close to Netflix's two Japanese rows of 13, 59 in Chinese and 79 in Korean. A box holds
## fewer characters than this. A starting point to tune from stills (DESIGN.md, "Per-script row limits").
static func long_line_characters(language: String = "") -> int:
	return floori(LONG_LINE_WORDS * READ_SECONDS_PER_WORD * reading_cps(language))


## [param language] when I18n.LANGUAGES has it; the language shown (I18n.current) for ""; else English.
static func _language(language: String) -> String:
	if language.is_empty():
		return I18n.current()
	return language if I18n.LANGUAGES.has(language) else I18n.FALLBACK


## [param message] cut where its speaker changes, before any box fitting: each segment is
## [tag, words, joiner], the tag ("" for narration) from [param speakers], the words without it, and the
## joiner that stood before the segment in [param message] ("" for the first, "\n" at a written line
## break, " " where a tagged sentence starts mid-line, "FIRST COPY SECURED. WOLF: ..."). A written line
## with no tag after a segment goes on in that segment's words, after a "\n". A choice's response rows
## (after [constant CHOICE_MARKER]) are left out. The one place a message is cut by speaker: [method split]
## fits each segment into boxes, and I18n.shown translates each segment's words as one message (PR L7c),
## so the boxes and the translation template cut the same way. Joining every segment's joiner, then
## "tag: " when it has a tag, then its words gives the message back up to its choice rows, for the
## messages the game writes (one space after a sentence's end and after a tag's colon).
static func segments(message: String, speakers: Array[String]) -> Array[Array]:
	var tags: Array[String] = longest_first(speakers)
	var found: Array[Array] = []
	for line: String in message.get_slice(CHOICE_MARKER, 0).split("\n"):
		var first_piece: bool = true
		for piece: String in _tag_pieces(line, tags):
			var tag: String = tag_of(piece, tags)
			var joiner: String = "" if found.is_empty() else ("\n" if first_piece else " ")
			if tag.is_empty() and first_piece and not found.is_empty():
				found.back()[1] += "\n" + piece
			elif tag.is_empty():
				found.append(["", piece, joiner])
			else:
				found.append([tag, piece.substr(tag.length() + 1).strip_edges(), joiner])
			first_piece = false
	return found


## The speaker tag [param box] starts with ("WOLF" for "WOLF: ..."), or "" for narration.
static func tag_of(box: String, speakers: Array[String]) -> String:
	for tag: String in longest_first(speakers):
		if box.begins_with(tag + ": "):
			return tag
	return ""


## [param box] without its speaker tag.
static func words_of(box: String, speakers: Array[String]) -> String:
	var tag: String = tag_of(box, speakers)
	return box if tag.is_empty() else box.substr(tag.length() + 1).strip_edges()


## The words in [param text]: runs of characters between spaces, a line break counting as a space.
## The box limit (LONG_LINE_WORDS, through _fits_box), read_seconds and text_boxes_test all count
## with it, so they agree on what a word is.
static func word_count(text: String) -> int:
	return text.replace("\n", " ").split(" ", false).size()


## How long [param words] needs on screen to be read in [param language] ("" is the language shown):
## the base plus one character's time at its reading speed for each character, at most
## READ_SECONDS_MAX_BY_CHARACTERS scaled to that speed, or the base plus READ_SECONDS_PER_WORD a word,
## whichever is longer. A Chinese or Japanese box has no spaces, so it counts as one word and its
## characters decide.
static func read_seconds(words: String, language: String = "") -> float:
	var text: String = words.replace("\n", " ")
	# English's speed over this language's: 1.0 in English, so its times stay exactly as they were.
	var scale: float = _english_cps() / reading_cps(language)
	var cap: float = READ_SECONDS_BASE + (READ_SECONDS_MAX_BY_CHARACTERS - READ_SECONDS_BASE) * scale
	# One character's time first, then times the count: 1.0 / 20.0 is the double 0.05, so English's
	# times are bit for bit the 0.05 s a character they were (n / 20.0 differs in the last bit for some n).
	var per_character: float = 1.0 / reading_cps(language)
	var by_characters: float = minf(READ_SECONDS_BASE + per_character * text.length(), cap)
	return maxf(by_characters, READ_SECONDS_BASE + READ_SECONDS_PER_WORD * word_count(text))


## The rows [param text] wraps to in a column [param width] px wide, as a Label with smart word wrap
## lays it out: each row's [start, end) character range. With [param whole_words] a word longer than the
## column keeps its own row instead of breaking inside (the station names, TextSize.wrap_world_label).
## TextParagraph breaks by the text server's word rules, which split Chinese and Japanese, written
## without spaces, between their words too.
static func rows(text: String, font: Font, font_size: int, width: float, whole_words: bool = false) -> Array[Vector2i]:
	var paragraph: TextParagraph = TextParagraph.new()
	paragraph.add_string(text, font, font_size)
	paragraph.width = width
	paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | (0 if whole_words else TextServer.BREAK_ADAPTIVE)
	var ranges: Array[Vector2i] = []
	for index: int in paragraph.get_line_count():
		ranges.append(paragraph.get_line_range(index))
	return ranges


## The characters on each row (without the space or line break it wrapped at); [param whole_words] as
## [method rows] takes it.
static func row_texts(text: String, font: Font, font_size: int, width: float, whole_words: bool = false) -> Array[String]:
	var texts: Array[String] = []
	for row: Vector2i in rows(text, font, font_size, width, whole_words):
		texts.append(text.substr(row.x, row.y - row.x).strip_edges())
	return texts


## The width [param text] wraps at in a column [param width] px wide so that no row holds more than
## [param max_characters] characters: the column itself, or a little narrower where a row of narrow
## letters would run longer. With [param max_characters] 0 (a language whose rows run to the column,
## [method row_characters]) the rows are balanced instead ([method _balanced_width]). The words stay as
## written; only where the rows break moves.
static func wrap_width(text: String, font: Font, font_size: int, width: float, max_characters: int) -> float:
	if max_characters <= 0:
		return _balanced_width(text, font, font_size, width)
	var at: float = width
	for attempt: int in 8:
		var narrower: float = at
		for row: String in row_texts(text, font, font_size, at):
			if row.length() <= max_characters:
				continue
			# The row's longest start of whole words within the limit.
			var space: int = row.left(max_characters + 1).rfind(" ")
			var keep: String = row.left(space) if space > 0 else row.left(max_characters)
			# The space the row breaks at counts towards its width as the text is laid out.
			narrower = minf(narrower, ceilf(font.get_string_size(keep + " ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x) + 1.0)
		if narrower >= at:
			return at
		at = narrower
	return at


## The narrowest whole-pixel width at which [param text] still takes as few rows as in the column
## [param width] px wide, plus a pixel so a Label's rounding keeps them: its rows come out as even as
## its words allow, so no short word is left alone on the last row (the prototype's Japanese stills
## showed "た。" and "いる。" so; DESIGN.md "Per-script row limits"). Rows are counted with whole words
## ([method rows]' whole_words): narrowing the width must never move a break inside a word, which the
## Label's smart wrap would otherwise do once a word no longer fits (PR L12's Korean stills broke
## "있" / "다." and "게" / "이지가"; Japanese "向" / "け"). Two rows break after a Chinese or Japanese
## comma or full stop instead where one gives rows nearly as even ([method _mark_width]). Text on one
## row, or on more rows than a box holds, keeps the column. Found by halving: fewer than 10 layouts of
## the text.
static func _balanced_width(text: String, font: Font, font_size: int, width: float) -> float:
	var count: int = rows(text, font, font_size, width, true).size()
	if count < 2 or count > MAX_ROWS:
		return width
	if count == 2:
		var at_mark: float = _mark_width(text, font, font_size, width)
		if at_mark > 0.0:
			return at_mark
	var too_narrow: float = 0.0
	var wide_enough: float = floorf(width)
	while wide_enough - too_narrow > 1.0:
		var middle: float = floorf((too_narrow + wide_enough) * 0.5)
		if rows(text, font, font_size, middle, true).size() <= count:
			wide_enough = middle
		else:
			too_narrow = middle
	return minf(wide_enough + 1.0, width)


## The width at which two rows of [param text] break right after one of NO_SPACE_MARKS (the Chinese and
## Japanese full stops and commas), choosing the mark that leaves the most even rows, or 0 when none
## does. Why: these scripts are written without spaces and the text server may break between any two
## characters, so the evenest width alone split a verb from its ending (PR L12's stills: "背を向" /
## "け、"), where a reader expects the break at the comma. A mark only counts when the shorter row is
## at least half as wide as the longer (the balance tests/text_boxes_test.gd asks of every two-row
## box) and both rows fit [param width]; the first row is then laid exactly that wide, so a mark before
## the middle never qualifies (its second row would not fit). Pure: lays the text out once per mark.
static func _mark_width(text: String, font: Font, font_size: int, width: float) -> float:
	var best: float = 0.0
	var best_gap: float = INF
	for index: int in text.length() - 1:
		if not NO_SPACE_MARKS.contains(text[index]) or NO_BREAK_BEFORE.contains(text[index + 1]):
			continue
		var first: float = font.get_string_size(text.left(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		var second: float = font.get_string_size(text.substr(index + 1).strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		if minf(first, second) < 0.5 * maxf(first, second) or absf(first - second) >= best_gap:
			continue
		var at: float = ceilf(first) + 1.0
		if at > width:
			continue
		var laid: Array[Vector2i] = rows(text, font, font_size, at, true)
		if laid.size() == 2 and laid[0].y == index + 1:
			best = at
			best_gap = absf(first - second)
	return best


## Splits [param line] where a sentence ends and the next one starts with a speaker's tag
## ("FIRST COPY SECURED. WOLF: ..."); each piece after the first starts with its tag. The space a piece
## was cut at is left out (segments puts it back as the joiner).
static func _tag_pieces(line: String, tags: Array[String]) -> Array[String]:
	var pieces: Array[String] = []
	for sentence: Array in _sentences(line):
		if pieces.is_empty() or not tag_of(sentence[0], tags).is_empty():
			pieces.append(sentence[0])
		else:
			pieces[pieces.size() - 1] += String(sentence[1]) + sentence[0]
	return pieces


## [param text]'s sentences (SENTENCE_ENDS), never broken inside a quotation, as [method _break_after]
## gives them.
static func _sentences(text: String) -> Array[Array]:
	return _break_after(text, SENTENCE_ENDS, true)


## How many pieces [param text] could break into for a box: at its sentence ends and its clause marks
## (SENTENCE_ENDS and every CLAUSE_MARKS), never inside a quotation. 1 means no break is left, so a box
## too long for the rules can be split no further (tests/text_boxes_test.gd checks that such a box is
## one sentence or clause).
static func break_count(text: String) -> int:
	return _break_after(text, SENTENCE_ENDS + "".join(CLAUSE_MARKS), true).size()


## Splits [param text] after any of [param marks] that a space follows, or with no space after a
## NO_SPACE_MARKS mark; never before a NO_BREAK_BEFORE character. A quotation's closer just after a mark
## ends the piece as the mark would ("... later.\" I ..."), also with spaces between them (French
## "« Allez. » Puis"). With [param skip_quotes], never inside a quotation (QUOTE_PAIRS, nested quotes
## tracked innermost first). Each piece is [words, joiner]: the joiner is what stood before it (" " at
## a space, "" first and after a NO_SPACE_MARKS mark), so joining every joiner and its words gives
## [param text] back.
static func _break_after(text: String, marks: String, skip_quotes: bool) -> Array[Array]:
	var pieces: Array[Array] = []
	var awaited: Array[String] = []
	var start: int = 0
	var joiner: String = ""
	for index: int in text.length():
		var character: String = text[index]
		var closed: bool = false
		if not awaited.is_empty() and String(awaited.back()).contains(character):
			awaited.pop_back()
			closed = true
		elif QUOTE_PAIRS.has(character):
			awaited.append(QUOTE_PAIRS[character])
		var ends: bool = marks.contains(character) or (closed and marks.contains(_before(text, index)))
		if not ends or (skip_quotes and not awaited.is_empty()) or index + 1 >= text.length():
			continue
		var next: String = text[index + 1]
		if next == " " or (NO_SPACE_MARKS.contains(character) and not NO_BREAK_BEFORE.contains(next)):
			pieces.append([text.substr(start, index + 1 - start), joiner])
			joiner = " " if next == " " else ""
			start = index + 1 + joiner.length()
	if start < text.length():
		pieces.append([text.substr(start), joiner])
	return pieces


## The last character of [param text] before [param index] that is not a space (a no-break space
## counts as one), or "".
static func _before(text: String, index: int) -> String:
	var at: int = index - 1
	while at >= 0 and text[at] in [" ", "\u00a0", "\u202f"]:
		at -= 1
	return text[at] if at >= 0 else ""


## The boxes one speaker's [param words] need in [param language]: whole when they fit and are short,
## otherwise their lines and sentences grouped greedily, in order, into boxes that fit.
static func _fit(words: String, fits: Callable, language: String) -> Array[String]:
	if _fits_box(words, fits, language):
		return [words]
	# Each unit carries the separator that joined it to the one before ("\n" between written lines, " "
	# or "" inside one, as _break_after found it).
	var units: Array[String] = []
	var joins: Array[String] = []
	var lines: PackedStringArray = words.split("\n")
	for line_index: int in lines.size():
		var first: bool = true
		for sentence: Array in _sentences(lines[line_index]):
			var sentence_first: bool = true
			for unit: Array in _clauses(sentence[0], fits, language):
				units.append(unit[0])
				if first and line_index > 0:
					joins.append("\n")
				else:
					joins.append(String(sentence[1]) if sentence_first else String(unit[1]))
				first = false
				sentence_first = false
	var boxes: Array[String] = []
	var current: String = units[0]
	for index: int in range(1, units.size()):
		var joined: String = current + joins[index] + units[index]
		if _fits_box(joined, fits, language):
			current = joined
		else:
			boxes.append(current)
			current = units[index]
	boxes.append(current)
	return boxes


## A sentence that does not fit on its own, broken after its semicolons, or failing that its commas
## (CLAUSE_MARKS), as [words, joiner] pieces like [method _break_after]'s (the first one's joiner is "").
static func _clauses(sentence: String, fits: Callable, language: String) -> Array[Array]:
	if _fits_box(sentence, fits, language):
		return [[sentence, ""]]
	for marks: String in CLAUSE_MARKS:
		var parts: Array[Array] = _break_after(sentence, marks, true)
		if parts.size() > 1:
			var grouped: Array[Array] = []
			for part: Array in parts:
				if not grouped.is_empty() and _fits_box(String(grouped.back()[0]) + part[1] + part[0], fits, language):
					grouped.back()[0] += String(part[1]) + part[0]
				else:
					grouped.append(part.duplicate())
			return grouped
	return [[sentence, ""]]


## Whether [param text] can be one box in [param language]: fewer than LONG_LINE_WORDS words, fewer
## than [method long_line_characters] characters, and [param fits] (the caller's row rule, a pure test
## of the words at the current text size) holds for it. The tests are pure, so the order they run in
## does not matter. Used by _fit and _clauses.
static func _fits_box(text: String, fits: Callable, language: String) -> bool:
	return word_count(text) < LONG_LINE_WORDS and text.length() < long_line_characters(language) and fits.call(text)


## A copy of [param speakers], longest tag first ([param speakers] itself is left as it is). tag_of
## and split try tags in this order, so where one tag could also match the start of a longer one's
## box the longer tag wins. text_boxes_test walks the tags in the same order.
static func longest_first(speakers: Array[String]) -> Array[String]:
	var sorted: Array[String] = speakers.duplicate()
	sorted.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	return sorted
