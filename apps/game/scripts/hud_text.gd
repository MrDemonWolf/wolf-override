class_name HudText
extends RefCounted
## Formats system/story messages that name an input, with optional whole-message touch variants.
## Station pills draw bindings separately. These tokens preserve readable English in existing system/story text.
## StringName inserts are binding tokens; ordinary Strings and counts pass through unchanged after translation.

## Default readable interact token in system/story lines; localise supplies the current binding.
const USE: StringName = &"E"
## The second answer's input ("press 2 for the manual port").
const ANSWER_2: StringName = &"2"

## The touch layout's form of a keyed template, by its keyboard template: the whole line as it reads on
## touch, where the key's verb and button differ ("Tap USE here again." for "Press %s here again."), so it
## is its own message rather than a fill. Filled by [method key]; a few entries, never pruned.
static var _touch_forms: Dictionary = {}


## The English line [param template] % [param inserts] (an insert that is one of the tokens above writes
## that token's English: "E" or "2"), remembered by I18n.format so [method localise] can draw it
## in the current language. [param touch_template], when given, is the line's whole touch-layout form
## (no inserts; mark it with I18n.KEY.tr as the template). Mark [param template] with I18n.KEY.tr at the
## call: the template generator does not look inside this call.
static func key(template: String, inserts: Array, touch_template: String = "") -> String:
	if not touch_template.is_empty():
		_touch_forms[template] = touch_template
	return I18n.format(template, inserts)


## True when [param line] was built with [method key] and names an input: one of its inserts is a key
## token, or it has a touch form. A line I18n.format built with only a name or a quoted answer in it (the
## story, PR L7c) is not one; I18n.shown fills those.
static func has_keys(line: String) -> bool:
	var parts: Array = I18n.parts(line)
	if parts.is_empty():
		return false
	if _touch_forms.has(parts[0]):
		return true
	for insert: Variant in parts[1]:
		if insert is StringName:
			return true
	return false


## [param line] as the player reads it in the current language. A line built with [method key] is its
## translated template (or, when [param touch] is true and it has one, its translated touch form) filled
## with its inserts, each token replaced by its entry in [param keys] (token to the input's shown name; a
## token [param keys] lacks writes its English). Any other line is translated whole when
## [param translate_plain] is true, else returned as it is (status_line's story lines are drawn by
## I18n.shown, which asks this only for the lines [method has_keys] names).
## The fill goes through I18n.fill, so a translation whose inserts differ shows the English template.
static func localise(line: String, keys: Dictionary, touch: bool, translate_plain: bool = true) -> String:
	var parts: Array = I18n.parts(line)
	if parts.is_empty():
		return String(TranslationServer.translate(line)) if translate_plain and I18n.has_words(line) else line
	var template: String = parts[0]
	if touch and _touch_forms.has(template):
		return I18n.fill(_touch_forms[template], [])
	var inserts: Array = []
	for insert: Variant in parts[1]:
		inserts.append(keys.get(insert, String(insert)) if insert is StringName else insert)
	return I18n.fill(template, inserts)


## [param message] (a top card: rows of English such as "SERVICE JUNCTION\nARM THE BREAKER") as the
## player reads it: a card built with I18n.format (the name card) is its translated template filled with
## its inserts, any other card has each row translated on its own (I18n.lines), since its rows are
## separate messages (a location and an objective).
static func card(message: String) -> String:
	var parts: Array = I18n.parts(message)
	return I18n.lines(message) if parts.is_empty() else I18n.fill(parts[0], parts[1])
