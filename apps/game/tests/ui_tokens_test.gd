extends "res://tests/support/game_suite.gd"
## The UI token file (res://ui/ui.tokens.json) as the game reads it through UiTokens (brief 2.7 step 6):
## every token is well formed and every alias resolves; every value keeps its hard limits and options;
## every theme binding names a slot the loaded project theme has, and the theme holds the token's value
## there; and the readers moved onto the tokens (UIMotion, Main's retry fades) read them.
## scripts/export_ui_tokens.py --check (run by check-game.sh before the suites) covers the file side:
## the theme regenerates byte for byte and every Color() line of the theme is bound.
## Later (B26): once scene colour overrides become theme type variations, a source scan here fails any UI
## script outside UiTokens and Palette that writes a colour literal, as approved_wording_test scans text.

## Statuses a token may have (the file's root $description says what each means).
const STATUSES: Array[String] = ["sourced", "computed", "today", "proposal"]


func _run() -> void:
	check_name = "UI tokens"
	_check_tokens()
	_check_lookup_errors()
	_check_theme()
	_check_readers()
	finish("UI token checks passed")


## Each token's own entry, its alias chain, its value's shape for its type, its limits and its options.
func _check_tokens() -> void:
	var paths: PackedStringArray = UiTokens.paths()
	_expect(paths.size() > 100, "the token file loads with its tokens (%d)" % paths.size())
	var aliases: int = 0
	for path: String in paths:
		var own: Dictionary = UiTokens.entry(path)
		var type: String = str(own.get("$type", ""))
		if not _expect(UiTokens.TYPES.has(type), "%s has a known $type (%s)" % [path, type]):
			continue
		var ext: Dictionary = UiTokens.extension(path)
		_expect(STATUSES.has(str(ext.get("status", ""))), "%s has a status (%s)" % [path, ext.get("status", "none")])
		var found: Variant = UiTokens._find(UiTokens._table, path)
		if not _expect(found is Dictionary, "%s resolves (%s)" % [path, found]):
			continue
		var target: Dictionary = found
		if own["$value"] is String and str(own["$value"]).begins_with("{"):
			aliases += 1
			_expect(str(target["$type"]) == type, "%s aliases a token of its own type (%s, not %s)" % [path, target["$type"], type])
		if path.begins_with("color.role."):
			_expect(str(own["$value"]).begins_with("{color.base."), "%s is a role, so it aliases a base colour (%s)" % [path, own["$value"]])
		var problem: String = _value_problem(type, target["$value"], ext)
		_expect(problem.is_empty(), "%s: %s" % [path, problem])
	_expect(aliases > 0, "aliases were checked (%d)" % aliases)


## Why [param value] cannot be a [param type] token with extension data [param ext], or "" when it can:
## the value's shape, an enum index or option, and hard_min and hard_max (inclusive, in the value's unit).
func _value_problem(type: String, value: Variant, ext: Dictionary) -> String:
	var measured: float = NAN
	match type:
		"color":
			var colour: Dictionary = value if value is Dictionary else {}
			var components: Array = colour.get("components", [])
			if str(colour.get("colorSpace", "")) != "srgb" or components.size() != 3:
				return "a colour is sRGB with three components (%s)" % [value]
			for part: Variant in components + [colour.get("alpha", 1.0)]:
				if not (part is float or part is int) or float(part) < 0.0 or float(part) > 1.0:
					return "colour parts run from 0 to 1 (%s)" % [value]
			return ""
		"dimension", "duration":
			var units: PackedStringArray = PackedStringArray(["px"] if type == "dimension" else ["ms", "s"])
			if not value is Dictionary or not units.has(str((value as Dictionary).get("unit", ""))) or not ((value as Dictionary).get("value") is float or (value as Dictionary).get("value") is int):
				return "a %s is {value, unit %s} (%s)" % [type, units, value]
			measured = float((value as Dictionary)["value"]) * (1000.0 if str((value as Dictionary)["unit"]) == "s" else 1.0)
		"number":
			if not (value is float or value is int):
				return "a number token holds a number (%s)" % [value]
			measured = float(value)
		"cubicBezier":
			if not value is Array or (value as Array).size() != 4 or float((value as Array)[0]) < 0.0 or float((value as Array)[0]) > 1.0 or float((value as Array)[2]) < 0.0 or float((value as Array)[2]) > 1.0:
				return "a cubicBezier is [x1, y1, x2, y2] with x1 and x2 from 0 to 1 (%s)" % [value]
			return ""
		"fontFamily", "fontWeight":
			if ext.has("options") and not (ext["options"] as Array).has(value):
				return "%s is one of its options %s" % [value, ext["options"]]
			return ""
	if ext.has("options"):
		var index: float = measured
		if index != floorf(index) or index < 0.0 or index >= (ext["options"] as Array).size():
			return "%s is an index into its options %s" % [value, ext["options"]]
		return ""
	if ext.has("hard_min") and measured < float(ext["hard_min"]):
		return "%s is below hard_min %s" % [measured, ext["hard_min"]]
	if ext.has("hard_max") and measured > float(ext["hard_max"]):
		return "%s is above hard_max %s" % [measured, ext["hard_max"]]
	return ""


## The lookup's error answers, tried on made-up tables so nothing is pushed: a missing token, a group,
## and an alias loop each come back as a reason instead of a token.
func _check_lookup_errors() -> void:
	var looped: Dictionary = {"a": {"b": {"$type": "number", "$value": "{a.c}"}, "c": {"$type": "number", "$value": "{a.b}"}}}
	_expect(str(UiTokens._find(looped, "a.b")).begins_with("alias loop: a.b -> a.c -> a.b"), "an alias loop is caught (%s)" % [UiTokens._find(looped, "a.b")])
	_expect(str(UiTokens._find(UiTokens._table, "no.such.token")).begins_with("no token"), "a missing token is reported")
	_expect(str(UiTokens._find(UiTokens._table, "motion")).ends_with("is a group, not a token"), "a group is not read as a token")
	_expect(str(UiTokens._find(UiTokens._table, "color.$description")).begins_with("no token"), "a $ key is data, not a token")


## Every theme binding names a slot of the loaded project theme, once, and the theme holds the token's
## value there: a StyleBox property ("Button_normal.bg_color", by the StyleBox's sub-resource id), a type's
## colour ("Button/colors/font_color") or default_font_size. Colours compare exactly: the theme's and the
## token's components are the same text, so they parse to the same float32.
func _check_theme() -> void:
	var theme: Theme = ThemeDB.get_project_theme()
	if not _expect(theme != null, "the project theme is loaded"):
		return
	var boxes: Dictionary = {}
	for type: String in theme.get_stylebox_type_list():
		for box_name: String in theme.get_stylebox_list(type):
			var box: StyleBox = theme.get_stylebox(box_name, type)
			if box.resource_path.contains("::"):
				boxes[box.resource_path.get_slice("::", 1)] = box
	_expect(boxes.size() > 20, "the theme's StyleBoxes are found by their sub-resource ids (%d)" % boxes.size())
	var bound: Dictionary = {}
	for path: String in UiTokens.paths():
		for slot: String in UiTokens.extension(path).get("theme", []):
			_expect(not bound.has(slot), "theme slot %s is bound once (by %s and %s)" % [slot, bound.get(slot, ""), path])
			bound[slot] = path
			if slot == "default_font_size":
				_expect(theme.default_font_size == UiTokens.px(path), "default_font_size is %s (%d, theme %d)" % [path, UiTokens.px(path), theme.default_font_size])
			elif slot.contains("/"):
				var parts: PackedStringArray = slot.split("/")
				var has_slot: bool = parts.size() == 3 and parts[1] == "colors" and theme.has_color(parts[2], parts[0])
				if _expect(has_slot, "%s's theme slot %s exists" % [path, slot]):
					_expect(theme.get_color(parts[2], parts[0]) == UiTokens.color(path), "%s is %s in the theme (%s, token %s)" % [slot, path, theme.get_color(parts[2], parts[0]), UiTokens.color(path)])
			else:
				var box: StyleBox = boxes.get(slot.get_slice(".", 0)) as StyleBox
				var property: String = slot.get_slice(".", 1)
				if _expect(box != null and box.get(property) is Color, "%s's theme slot %s exists" % [path, slot]):
					_expect(box.get(property) == UiTokens.color(path), "%s is %s in the theme (%s, token %s)" % [slot, path, box.get(property), UiTokens.color(path)])
	_expect(bound.size() > 80, "the theme bindings were checked (%d)" % bound.size())


## The code that moved its values into the token file reads them from there.
func _check_readers() -> void:
	_expect(UIMotion.LIFT_SCALE == Vector2.ONE * UiTokens.number("motion.focus.scale") and UIMotion.PRESS_SCALE == Vector2.ONE * UiTokens.number("motion.press.scale"), "UIMotion's lift and press scales are motion.focus.scale and motion.press.scale (%s, %s)" % [UIMotion.LIFT_SCALE, UIMotion.PRESS_SCALE])
	_expect(UIMotion.LIFT_SECONDS == UiTokens.seconds("motion.focus.in") and UIMotion.PRESS_SECONDS == UiTokens.seconds("motion.press.duration"), "UIMotion's times are motion.focus.in and motion.press.duration (%s s, %s s)" % [UIMotion.LIFT_SECONDS, UIMotion.PRESS_SECONDS])
	_expect(Main.RETRY_FADE_OUT_SECONDS == UiTokens.seconds("timing.fade.out") and Main.RETRY_FADE_IN_SECONDS == UiTokens.seconds("timing.fade.in"), "the knockdown's fades are timing.fade.out and timing.fade.in (%s s, %s s)" % [Main.RETRY_FADE_OUT_SECONDS, Main.RETRY_FADE_IN_SECONDS])
	_expect(UiTokens.bezier("motion.ease.in").size() == 4 and UiTokens.px("type.display.size") > 0, "the bezier and px getters read their tokens")
