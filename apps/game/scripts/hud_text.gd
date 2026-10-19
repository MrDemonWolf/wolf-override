class_name HudText
extends RefCounted
## The HUD's key prompts as text a translation can carry: the one place where a hint, the save-error line
## or WOLF's manual-port line names the input to press. Built in localization PR L7b (research branch
## codex/localization-research, docs/research-2026-10/localization/PLAN.md, "L7b mark-hud") as the part
## of the lighter-game plan's S05 Hud helpers ([method key] and [method localise]) that L7b needs, since
## S05 had not landed (DESIGN.md, "How the lighter-game plan's text steps fit": "localise() is the
## key-token fill: build it once, as placeholders filled after tr()").
##
## How a key prompt is written: the English template holds a %s where the key goes ("%s: arm the
## breaker.") and is built with [method key] and a token ([constant USE], [constant HOLD_USE] or
## [constant ANSWER_2]) as that insert. The result is the English line the game kept before ("E: arm the
## breaker."), so _context_hint, status_line and every test still read and compare English (I18n's rule),
## and I18n.format remembers the template and the token. Where it is drawn, [method localise] translates
## the template and fills each token with the input in use (the bound key, the controller button or the
## touch button's word), after tr(), so a translation moves the key wherever its grammar needs it and
## never has to keep an English "E:" for a search and replace to find.
##
## Why tokens are StringNames: an insert that is a StringName is a key token and anything else (the
## crank's turn counts, a name) passes through unchanged, so a name that happens to read "E" can never be
## taken for the key.

## The interact input, as the English hint writes it ("E: arm the breaker.").
const USE: StringName = &"E"
## The interact input held down, for a crank ("HOLD E: crank the valve, 2 of 8 turns."). With TOGGLE HOLDS
## on it is filled with the key alone, since one press works the crank.
const HOLD_USE: StringName = &"HOLD E"
## The second answer's input ("press 2 for the manual port").
const ANSWER_2: StringName = &"2"

## The touch layout's form of a keyed template, by its keyboard template: the whole line as it reads on
## touch, where the key's verb and button differ ("Tap USE here again." for "Press %s here again."), so it
## is its own message rather than a fill. Filled by [method key]; a few entries, never pruned.
static var _touch_forms: Dictionary = {}


## The English line [param template] % [param inserts] (an insert that is one of the tokens above writes
## that token's English: "E", "HOLD E" or "2"), remembered by I18n.format so [method localise] can draw it
## in the current language. [param touch_template], when given, is the line's whole touch-layout form
## (no inserts; mark it with I18n.KEY.tr as the template). Mark [param template] with I18n.KEY.tr at the
## call: the template generator does not look inside this call.
static func key(template: String, inserts: Array, touch_template: String = "") -> String:
	if not touch_template.is_empty():
		_touch_forms[template] = touch_template
	return I18n.format(template, inserts)


## True when [param line] was built with [method key] (or I18n.format) and so has inserts to fill.
static func has_keys(line: String) -> bool:
	return not I18n.parts(line).is_empty()


## [param line] as the player reads it in the current language. A line built with [method key] is its
## translated template (or, when [param touch] is true and it has one, its translated touch form) filled
## with its inserts, each token replaced by its entry in [param keys] (token to the input's shown name; a
## token [param keys] lacks writes its English). Any other line is translated whole when
## [param translate_plain] is true, else returned as it is (status_line's story lines are L7c's).
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
