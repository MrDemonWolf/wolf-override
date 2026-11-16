class_name DialogueReveal
extends RefCounted
## One page's reveal clock. It returns Unicode-codepoint limits for an already shaped Label;
## it never changes words, page boundaries, input ownership or game state. Times are seconds.

## Common titles and short forms in the shipped Latin-script languages; dotted initials are handled separately.
## shortcut: this is a bounded abbreviation list; extend it when a shipped line adds another short form.
const ABBREVIATIONS: Array[String] = ["mr.", "mrs.", "ms.", "dr.", "dra.", "prof.", "sr.", "sra.", "jr.", "st.", "vs.", "etc.", "inc.", "mme.", "mlle.", "m."]

var _page: String = ""
var _text: String = ""
var _ends: PackedInt32Array = []
var _shown: int = 0
var _budget: float = 0.0
## Seconds since the full page became visible; the caller owns any auto-advance decision.
var reading_age: float = 0.0


## Starts a new page when its identity or drawn text changes; repeated layout keeps its progress.
## [param instant] completes the current page for Instant speed, Reduced Motion or urgent feedback.
func sync(page: String, words: String, instant: bool) -> void:
	if page != _page or words != _text:
		_page = page
		_text = words
		_ends = TextServerManager.get_primary_interface().string_get_character_breaks(words)
		_shown = 0
		_budget = 0.0
		reading_age = 0.0
	if instant:
		complete()


## Advances by [param delta] seconds at [param cps] composite characters/second, with the supplied
## punctuation pause in seconds. Non-positive speed means Instant; no settings or clocks are read here.
func tick(delta: float, cps: float, punctuation_seconds: float) -> void:
	delta = maxf(delta, 0.0)
	if done():
		reading_age += delta
		return
	if cps <= 0.0:
		complete()
		reading_age += delta
		return
	_budget += delta
	while not done():
		var cost: float = 1.0 / cps
		if _shown > 0 and _pause_after(_ends[_shown - 1]):
			cost += maxf(punctuation_seconds, 0.0)
		if _budget < cost:
			return
		_budget -= cost
		_shown += 1
	reading_age += _budget
	_budget = 0.0


## Completes an unfinished page and returns true when this consumes a reading action.
## Calling it again returns false, allowing the caller to advance on that later input.
func complete() -> bool:
	if done():
		return false
	_shown = _ends.size()
	_budget = 0.0
	reading_age = 0.0
	return true


## Whether all composite characters are visible, including an empty page.
func done() -> bool:
	return _shown >= _ends.size()


## Unicode-codepoint limit for Label.visible_characters, never an offset inside a composite character.
func characters() -> int:
	return _ends[_shown - 1] if _shown > 0 else 0


## Whether the character ending at [param end] needs a pause before the next one. Punctuation runs
## pause once; internal decimal/initial dots and recognized abbreviations do not interrupt speech.
func _pause_after(end: int) -> bool:
	var mark: String = _text[end - 1]
	if not DialogueBoxes.SENTENCE_ENDS.contains(mark):
		return false
	if end < _text.length() and DialogueBoxes.SENTENCE_ENDS.contains(_text[end]):
		return false
	if mark != ".":
		return true
	if end < _text.length() and (_text[end].is_valid_identifier() or _text[end].is_valid_int()):
		return false
	var start: int = end - 1
	while start > 0 and (_text[start - 1] == "." or _text[start - 1].is_valid_identifier()):
		start -= 1
	var token: String = _text.substr(start, end - start).to_lower()
	var parts: PackedStringArray = token.trim_suffix(".").split(".")
	var initials: bool = parts.size() > 1
	for part: String in parts:
		initials = initials and part.length() == 1 and part.is_valid_identifier()
	return not (ABBREVIATIONS.has(token) or initials)
