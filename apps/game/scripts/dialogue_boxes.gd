class_name DialogueBoxes
extends RefCounted
## Splits a dialogue message into the boxes the bottom bar shows one after another, and says how long
## each needs on screen (STORY-2, STORY-3, STORY-4, STORY-10). Every box has one speaker (or is
## narration) and fits the dialogue column in MAX_ROWS rows. Splitting never changes a word: a message
## breaks only where the speaker changes, at its own line breaks and between sentences (inside a
## sentence only at a semicolon or comma, and only when the sentence alone is too long).

## Reading time per box (STORY-2): the larger of a base plus this long per character (at most
## READ_SECONDS_MAX_BY_CHARACTERS) and the base plus this long per word, the reading time the
## October 13 wording drafts use (BBC subtitles allow about 0.33 s a word). Speaker tags are not counted.
const READ_SECONDS_BASE: float = 1.2
const READ_SECONDS_PER_CHARACTER: float = 0.05
const READ_SECONDS_PER_WORD: float = 0.33
const READ_SECONDS_MAX_BY_CHARACTERS: float = 7.0
## A box holds at most this many rows of the dialogue column (subtitle practice: two lines).
const MAX_ROWS: int = 2
## A row holds at most this many characters (wrap_width narrows the wrap where a row would hold more).
const MAX_ROW_CHARACTERS: int = 42
## A box of this many words or more is split at its sentence breaks even when it would fit.
const LONG_LINE_WORDS: int = 20
## A choice's response rows follow its question after this; the answer buttons show them instead.
const CHOICE_MARKER: String = "\n1  "


## The boxes [param message] is shown as, in order. Each is "TAG: words" for a speaker in
## [param speakers] or plain narration. [param fits] takes a box's words (without the tag) and says
## whether they fit the column in MAX_ROWS rows. A line with no tag after a tagged one goes on in
## that speaker's voice, as the game's lines are written.
static func split(message: String, speakers: Array[String], fits: Callable) -> Array[String]:
	var tags: Array[String] = _longest_first(speakers)
	var segments: Array[Array] = []
	for line: String in message.get_slice(CHOICE_MARKER, 0).split("\n"):
		var first_piece: bool = true
		for piece: String in _tag_pieces(line, tags):
			var tag: String = tag_of(piece, tags)
			if tag.is_empty() and first_piece and not segments.is_empty():
				segments.back()[1] += "\n" + piece
			elif tag.is_empty():
				segments.append(["", piece])
			else:
				segments.append([tag, piece.substr(tag.length() + 1).strip_edges()])
			first_piece = false
	var boxes: Array[String] = []
	for segment: Array in segments:
		for words: String in _fit(segment[1], fits):
			boxes.append(words if segment[0].is_empty() else "%s: %s" % [segment[0], words])
	return boxes


## The speaker tag [param box] starts with ("WOLF" for "WOLF: ..."), or "" for narration.
static func tag_of(box: String, speakers: Array[String]) -> String:
	for tag: String in _longest_first(speakers):
		if box.begins_with(tag + ": "):
			return tag
	return ""


## [param box] without its speaker tag.
static func words_of(box: String, speakers: Array[String]) -> String:
	var tag: String = tag_of(box, speakers)
	return box if tag.is_empty() else box.substr(tag.length() + 1).strip_edges()


static func word_count(text: String) -> int:
	return text.replace("\n", " ").split(" ", false).size()


## How long [param words] needs on screen to be read.
static func read_seconds(words: String) -> float:
	var text: String = words.replace("\n", " ")
	var by_characters: float = minf(READ_SECONDS_BASE + READ_SECONDS_PER_CHARACTER * text.length(), READ_SECONDS_MAX_BY_CHARACTERS)
	return maxf(by_characters, READ_SECONDS_BASE + READ_SECONDS_PER_WORD * word_count(text))


## The rows [param text] wraps to in a column [param width] px wide, as a Label with smart word wrap
## lays it out: each row's [start, end) character range.
static func rows(text: String, font: Font, font_size: int, width: float) -> Array[Vector2i]:
	var paragraph: TextParagraph = TextParagraph.new()
	paragraph.add_string(text, font, font_size)
	paragraph.width = width
	paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var ranges: Array[Vector2i] = []
	for index: int in paragraph.get_line_count():
		ranges.append(paragraph.get_line_range(index))
	return ranges


## The characters on each row (without the space or line break it wrapped at).
static func row_texts(text: String, font: Font, font_size: int, width: float) -> Array[String]:
	var texts: Array[String] = []
	for row: Vector2i in rows(text, font, font_size, width):
		texts.append(text.substr(row.x, row.y - row.x).strip_edges())
	return texts


## The width [param text] wraps at in a column [param width] px wide so that no row holds more than
## [param max_characters] characters: the column itself, or a little narrower where a row of narrow
## letters would run longer. The words stay as written; only where the rows break moves.
static func wrap_width(text: String, font: Font, font_size: int, width: float, max_characters: int) -> float:
	var at: float = width
	for attempt: int in 8:
		var narrower: float = at
		for row: String in row_texts(text, font, font_size, at):
			if row.length() <= max_characters:
				continue
			# The row's longest start of whole words within the limit.
			var space: int = row.left(max_characters + 1).rfind(" ")
			var keep: String = row.left(space) if space > 0 else row.left(max_characters)
			narrower = minf(narrower, ceilf(font.get_string_size(keep, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x) + 1.0)
		if narrower >= at:
			return at
		at = narrower
	return at


## Splits [param line] where a sentence ends and the next one starts with a speaker's tag
## ("FIRST COPY SECURED. WOLF: ..."); each piece after the first starts with its tag.
static func _tag_pieces(line: String, tags: Array[String]) -> Array[String]:
	var pieces: Array[String] = []
	for sentence: String in _sentences(line):
		if pieces.is_empty() or not tag_of(sentence, tags).is_empty():
			pieces.append(sentence)
		else:
			pieces[pieces.size() - 1] += " " + sentence
	return pieces


## [param text]'s sentences: it breaks after ".", "!" or "?" and a space, never inside quotes.
static func _sentences(text: String) -> Array[String]:
	return _break_after(text, ".!?", true)


## Splits [param text] after any of [param marks] that a space follows; with
## [param skip_quotes], not inside a quotation. The pieces rejoin with single spaces.
static func _break_after(text: String, marks: String, skip_quotes: bool) -> Array[String]:
	var pieces: Array[String] = []
	var quoted: bool = false
	var start: int = 0
	for index: int in text.length():
		var character: String = text[index]
		if character == "\"":
			quoted = not quoted
		var ends: bool = marks.contains(character) or (character == "\"" and not quoted and index > 0 and marks.contains(text[index - 1]))
		if ends and (not quoted or not skip_quotes) and index + 1 < text.length() and text[index + 1] == " ":
			pieces.append(text.substr(start, index + 1 - start))
			start = index + 2
	if start < text.length():
		pieces.append(text.substr(start))
	return pieces


## The boxes one speaker's [param words] need: whole when they fit and are short, otherwise their
## lines and sentences grouped greedily, in order, into boxes that fit.
static func _fit(words: String, fits: Callable) -> Array[String]:
	if word_count(words) < LONG_LINE_WORDS and fits.call(words):
		return [words]
	# Each unit carries the separator that joined it to the one before ("\n" between written lines).
	var units: Array[String] = []
	var joins: Array[String] = []
	for line_index: int in words.split("\n").size():
		var line: String = words.split("\n")[line_index]
		var first: bool = true
		for sentence: String in _sentences(line):
			for unit: String in _clauses(sentence, fits):
				units.append(unit)
				joins.append("\n" if first and line_index > 0 else " ")
				first = false
	var boxes: Array[String] = []
	var current: String = units[0]
	for index: int in range(1, units.size()):
		var joined: String = current + joins[index] + units[index]
		if word_count(joined) < LONG_LINE_WORDS and fits.call(joined):
			current = joined
		else:
			boxes.append(current)
			current = units[index]
	boxes.append(current)
	return boxes


## A sentence that does not fit on its own, broken after its semicolons, or failing that its commas.
static func _clauses(sentence: String, fits: Callable) -> Array[String]:
	if word_count(sentence) < LONG_LINE_WORDS and fits.call(sentence):
		return [sentence]
	for marks: String in [";", ","]:
		var parts: Array[String] = _break_after(sentence, marks, true)
		if parts.size() > 1:
			var grouped: Array[String] = []
			for part: String in parts:
				if not grouped.is_empty() and fits.call(grouped.back() + " " + part) and word_count(grouped.back() + " " + part) < LONG_LINE_WORDS:
					grouped[grouped.size() - 1] += " " + part
				else:
					grouped.append(part)
			return grouped
	return [sentence]


static func _longest_first(speakers: Array[String]) -> Array[String]:
	var sorted: Array[String] = speakers.duplicate()
	sorted.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	return sorted
