class_name UiTokens
extends RefCounted
## The UI token file (res://ui/ui.tokens.json, brief 2.7): the one home of UI colour, type, density,
## motion and timing values, read once at class load like I18n's language table. The HTML mockups
## (mockups/shared/wo.js) read the same file, and scripts/export_ui_tokens.py writes the theme slots each
## token binds into assets/fonts/game_theme.tres, so the game, the theme and the mockups never hold two
## copies of a value. Tuned values come back through `export_ui_tokens.py --apply` (brief 7.2).
##
## Format: Design Tokens Format Module 2025.10. A token is an object with "$value" and "$type"; its
## name is its dot path ("motion.press.duration"); a "$value" of "{group.token}" is an alias to another
## token. Units: a dimension is {"value", "unit": "px"} in canvas px of the 960x540 canvas; a duration
## is {"value", "unit": "ms"} (or "s"). The root "$description" in the file says the rest.
##
## Readers call the typed getters with a dot path. A missing file, a missing token, a token of another
## type or an alias loop pushes an error (every headless suite fails on it: scripts/godot-helpers.sh,
## godot_error_lines) and returns a stand-in, so a player's game keeps running.
##
## Gotchas:
## - Godot's JSON numbers are all floats, so [method px] rounds to an int.
## - A const cannot call these getters; a value read from here is a static var (UIMotion's scales).
##   A static var of another class may use them at its own class load (measured: research gap-3).
## - Color("#38c7eb") and the 7-digit component form are about one float32 step apart, so tests
##   compare colours with is_equal_approx() or to_html(), not ==.

## The token file. It lives inside the project so the export carries it (both presets export all
## resources, .json files included), as i18n/languages.json does.
const TABLE_PATH: String = "res://ui/ui.tokens.json"
## The key of the game's own data under each token's "$extensions" (the bundle id; DTCG asks for a
## reverse-domain key): status, source, the Tune panel's min, max and step, hard_min and hard_max,
## band, options and the theme slots the token fills.
const EXTENSION: String = "com.mrdemonwolf.wolfoverride"
## Every "$type" the file may use (brief 2.7).
const TYPES: Array[String] = ["color", "dimension", "duration", "number", "cubicBezier", "fontFamily", "fontWeight"]
## What [method color] returns for a token it cannot read: loud on screen, so a broken file is seen.
const MISSING_COLOR: Color = Color.MAGENTA

## The parsed token file (the whole tree, groups and "$" keys included); {} when it could not be read.
static var _table: Dictionary = _load_table()


## Reads [constant TABLE_PATH]. A missing or broken file pushes an error and leaves an empty table,
## so every getter then reports its token as missing.
static func _load_table() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TABLE_PATH))
	if not parsed is Dictionary:
		push_error("UiTokens: %s is missing or is not JSON; every UI token reads as missing" % TABLE_PATH)
		return {}
	return parsed


## The object at dot path [param path] in [param table] itself, aliases not followed: a token (it has
## "$value"), a group, or null when nothing is there. Keys starting with "$" are data, never children.
static func _node_in(table: Dictionary, path: String) -> Variant:
	var node: Variant = table
	for part: String in path.split("."):
		if not node is Dictionary or part.begins_with("$") or not (node as Dictionary).has(part):
			return null
		node = (node as Dictionary)[part]
	return node


## The token at [param path] in [param table] after following its aliases: the object holding the
## literal "$value". Returns that Dictionary, or a String saying why there is none (no such token, a
## group rather than a token, or an alias loop). Pure: it pushes nothing, so tests can try broken tables.
static func _find(table: Dictionary, path: String) -> Variant:
	var seen: PackedStringArray = []
	var at: String = path
	while not seen.has(at):
		seen.append(at)
		var node: Variant = _node_in(table, at)
		if node == null:
			return "no token %s%s" % [at, "" if at == path else " (an alias of %s)" % path]
		if not node is Dictionary or not (node as Dictionary).has("$value"):
			return "%s is a group, not a token" % at
		var value: Variant = (node as Dictionary)["$value"]
		if not (value is String and (value as String).begins_with("{") and (value as String).ends_with("}")):
			return node
		at = (value as String).substr(1, (value as String).length() - 2)
	seen.append(at)
	return "alias loop: %s" % " -> ".join(seen)


## The token [param path] names, aliases followed, as its file object ("$value", "$type", ...). Pushes
## an error and returns {} when there is none.
static func token(path: String) -> Dictionary:
	var found: Variant = _find(_table, path)
	if found is String:
		push_error("UiTokens: %s (%s)" % [found, TABLE_PATH])
		return {}
	return found


## The literal "$value" of [param path] when its type is [param type]; null (after pushing an error)
## when the token is missing or of another type. The alias target's "$type" is the one compared: an
## alias has its target's type (ui_tokens_test checks), so that is the alias's own type too.
static func _value(path: String, type: String) -> Variant:
	var found: Dictionary = token(path)
	if found.is_empty():
		return null
	if str(found.get("$type", "")) != type:
		push_error("UiTokens: %s is a %s token, not a %s" % [path, found.get("$type", "untyped"), type])
		return null
	return found["$value"]


## A colour token as a Godot Color, from its "components" and "alpha" (DTCG sRGB), never from "hex":
## the components are the text the theme writes, so a theme slot and this getter agree exactly.
## [constant MISSING_COLOR] when the token cannot be read.
static func color(path: String) -> Color:
	var value: Variant = _value(path, "color")
	if not value is Dictionary:
		return MISSING_COLOR
	var components: Array = (value as Dictionary)["components"]
	return Color(float(components[0]), float(components[1]), float(components[2]), float((value as Dictionary).get("alpha", 1.0)))


## A duration token in seconds (the file writes ms; an "s" unit is read as seconds). 0.0 when it cannot
## be read.
static func seconds(path: String) -> float:
	var value: Variant = _value(path, "duration")
	if not value is Dictionary:
		return 0.0
	var amount: float = float((value as Dictionary)["value"])
	return amount if str((value as Dictionary).get("unit", "ms")) == "s" else amount / 1000.0


## A dimension token in whole canvas px. JSON numbers are floats in Godot, so the value is rounded
## (roundi, as TextSize.px rounds font sizes). 0 when it cannot be read.
static func px(path: String) -> int:
	var value: Variant = _value(path, "dimension")
	if not value is Dictionary:
		return 0
	return roundi(float((value as Dictionary)["value"]))


## A number token (a ratio, a scale, a rate, or an enum's index into its options). 0.0 when it cannot
## be read.
static func number(path: String) -> float:
	var value: Variant = _value(path, "number")
	if value == null:
		return 0.0
	return float(value)


## A cubicBezier token as [x1, y1, x2, y2] (CSS cubic-bezier order). Empty when it cannot be read.
static func bezier(path: String) -> PackedFloat32Array:
	var value: Variant = _value(path, "cubicBezier")
	if not value is Array:
		return PackedFloat32Array()
	return PackedFloat32Array(value as Array)


## Every token's dot path, in file order: the list ui_tokens_test walks.
static func paths() -> PackedStringArray:
	var found: PackedStringArray = []
	_collect(_table, "", found)
	return found


## Adds the dot path of every token under [param node] (whose own path is [param prefix]) to
## [param found]. Keys starting with "$" are data, not children.
static func _collect(node: Dictionary, prefix: String, found: PackedStringArray) -> void:
	for key: String in node:
		var child: Variant = node[key]
		if key.begins_with("$") or not child is Dictionary:
			continue
		var path: String = prefix + key
		if (child as Dictionary).has("$value"):
			found.append(path)
		else:
			_collect(child as Dictionary, path + ".", found)


## The token object at [param path] as the file writes it, aliases not followed ("$value" may be an
## alias): what ui_tokens_test checks each token's own "$type" and "$value" on. {} when there is no token.
static func entry(path: String) -> Dictionary:
	var node: Variant = _node_in(_table, path)
	return node if node is Dictionary and (node as Dictionary).has("$value") else {}


## The game's own data for [param path] (its "$extensions" entry under [constant EXTENSION]), read from
## the token itself, not its alias target: status, limits, options and theme slots. {} when it has none
## or the token is missing.
static func extension(path: String) -> Dictionary:
	return (entry(path).get("$extensions", {}) as Dictionary).get(EXTENSION, {})
