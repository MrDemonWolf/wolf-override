class_name DebugOverlay
extends PanelContainer
## The F3 overlay's card: a performance page, and a state page that says what the game is doing
## (room, beat and objective, the engineer, WOLF and why he is where he is, the junction's machines,
## the hazards that are armed, WOLF's memory and the run's choices, the save). It shows the data
## DebugTools.dump() gives, so the overlay and a bug capture never disagree. It draws only while shown
## and its text changes only when DebugTools refreshes it, a few times a second.

## The game's HUD card and cyan accent, in the game's fonts; the terminal look stays in Settings.
const ACCENT: String = "#73DDF5"
const MUTED: String = "#9fc3d2"
const WARN: String = "#ff9a9f"
## Small enough that the tallest page (the junction's) ends above the actors' heads at the touch
## play framing, where they stand highest on screen.
const FONT_SIZE: int = 11
## Below the top card (main.tscn's TopBar ends at y 78) on the left, so the right half of the view,
## PAUSE and USE stay clear.
const ORIGIN: Vector2 = Vector2(12.0, 80.0)
## The performance page stays narrow enough to clear the corridor's tutorial card (from x 322).
const PERFORMANCE_WIDTH: float = 260.0
const STATE_WIDTH: float = 360.0
## The text's side and top/bottom margins inside the card.
const MARGIN_X: int = 10
const MARGIN_Y: int = 5
## Room for the HudCard frame around the margins when working out where a page lands.
const FRAME_SLACK: float = 4.0
const NONE: String = "—"
const HEADER_FONT: FontVariation = preload("res://assets/fonts/Montserrat-Semibold.tres")

var body: RichTextLabel


func _init() -> void:
	name = "DebugOverlay"
	theme_type_variation = &"HudCard"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	position = ORIGIN
	var margin: MarginContainer = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right"]:
		margin.add_theme_constant_override("margin_%s" % side, MARGIN_X)
	for side: String in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, MARGIN_Y)
	add_child(margin)
	body = RichTextLabel.new()
	body.name = "Body"
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_font_size_override("normal_font_size", FONT_SIZE)
	body.add_theme_font_size_override("bold_font_size", FONT_SIZE)
	body.add_theme_font_override("bold_font", HEADER_FONT)
	body.add_theme_color_override("default_color", Color(0.82, 0.89, 0.94, 1))
	body.add_theme_constant_override("line_separation", -1)
	body.custom_minimum_size = Vector2(PERFORMANCE_WIDTH, 0.0)
	margin.add_child(body)


## Where a page can be drawn in the 960x540 canvas: its width, from ORIGIN down to the bottom edge
## (every page is shorter), so a control in that column would be under it.
static func footprint(performance_page: bool) -> Rect2:
	var width: float = (PERFORMANCE_WIDTH if performance_page else STATE_WIDTH) + MARGIN_X * 2.0 + FRAME_SLACK
	return Rect2(ORIGIN, Vector2(width, 540.0 - ORIGIN.y))


## The performance page: frame rate and time, memory, node and draw-call counts.
func show_performance(performance: Dictionary) -> void:
	_show(PERFORMANCE_WIDTH, "%s\n%s" % [_header("PERFORMANCE"), performance_text(performance)])


## The state page (with [param zones] the header says the world zones are drawn too).
func show_state(data: Dictionary, zones: bool) -> void:
	_show(STATE_WIDTH, "%s\n%s" % [_header("STATE + ZONES" if zones else "STATE"), state_text(data)])


## One line of performance numbers.
static func performance_text(performance: Dictionary) -> String:
	return "%s  %d fps · %.1f ms frame · %.1f ms process\n%s  %s · video %.0f MB\n%s  %d nodes · %d objects · %d draw calls" % [
		_key("PERF"), int(performance.get("fps", 0)), float(performance.get("frame_ms", 0.0)), float(performance.get("process_ms", 0.0)),
		_key("MEM"), memory_text(performance), float(performance.get("video_mb", 0.0)),
		_key("COUNT"), int(performance.get("nodes", 0)), int(performance.get("objects", 0)), int(performance.get("draw_calls", 0)),
	]


## Static memory in MB, or "n/a" where Godot does not report it (release builds).
static func memory_text(performance: Dictionary) -> String:
	var memory: Variant = performance.get("memory_mb")
	return "n/a" if memory == null else "%.0f MB" % float(memory)


## The state page's rows, from a DebugTools.dump().
static func state_text(data: Dictionary) -> String:
	var rows: PackedStringArray = PackedStringArray()
	var performance: Dictionary = data.get("performance", {})
	var memory_used: String = memory_text(performance) if performance.get("memory_mb") != null else "video %.0f MB" % float(performance.get("video_mb", 0.0))
	rows.append("%s  %d fps · %.1f ms · %s · %d nodes · %d draws" % [_key("PERF"), int(performance.get("fps", 0)), float(performance.get("frame_ms", 0.0)), memory_used, int(performance.get("nodes", 0)), int(performance.get("draw_calls", 0))])
	rows.append("%s  %s · %s · %s" % [_key("ROOM"), data.get("room", NONE), data.get("beat", NONE), data.get("objective", NONE)])
	var engineer: Dictionary = data.get("engineer", {})
	rows.append("%s  x %.0f %s · %s" % [_key("ENGINEER"), float(engineer.get("x", 0.0)), engineer.get("facing", NONE), engineer.get("state", NONE)])
	var wolf: Dictionary = data.get("wolf", {})
	var target: float = float(wolf.get("target_x", -1.0))
	rows.append("%s  x %.0f %s · to %s · %s" % [_key("WOLF"), float(wolf.get("x", 0.0)), wolf.get("facing", NONE), "%.0f" % target if target >= 0.0 else NONE, wolf.get("why", NONE)])
	var sentry: Dictionary = data.get("sentry", {})
	if sentry.get("active", false):
		rows.append("%s  %s · x %.0f %s · sight %.0f · on %s" % [_key("SENTRY"), sentry.get("state", NONE), float(sentry.get("x", 0.0)), sentry.get("facing", NONE), float(sentry.get("sight_range", 0.0)), sentry.get("fixated_on", NONE)])
		var line: Dictionary = data.get("pressure_line", {})
		var fuse: float = float(line.get("fuse", 0.0))
		rows.append("%s  %s · gauge %.2f · turns %d/%d · fuse %s" % [_key("LINE"), line.get("state", NONE), float(line.get("gauge", 0.0)), int(line.get("turns", 0)), int(line.get("turns_needed", 0)), "%.2f s" % fuse if fuse > 0.0 else NONE])
		var arm: Dictionary = data.get("drop_arm", {})
		var cloud: float = float(arm.get("cloud", 0.0))
		var bolt: Dictionary = data.get("bolt", {})
		rows.append("%s  %s · cloud %s · %s %s · %s" % [_key("ARM"), arm.get("state", NONE), "%.1f s" % cloud if cloud > 0.0 else NONE, _key("BOLT"), bolt.get("state", NONE), _hazards(data)])
	else:
		rows.append("%s  not in this room · %s" % [_key("SENTRY"), _hazards(data)])
	var choices: Dictionary = data.get("choices", {})
	rows.append("%s  relay %s · mirror %s · lane %s" % [_key("CHOICES"), choices.get("relay", NONE), _or_none(choices.get("mirror", "")), _or_none(choices.get("lane", ""))])
	var memory: Dictionary = data.get("memory", {})
	var debug: Dictionary = data.get("debug", {})
	rows.append("%s  %s · %s  %s" % [_key("MEMORY"), _or_none(memory.get("choice_id", "")), _key("CHEATS"), "[color=%s]USED[/color]" % WARN if debug.get("cheats_used", false) else "none"])
	var save: Dictionary = data.get("save", {})
	rows.append("%s  v%d · %s · %s" % [_key("SAVE"), int(save.get("version", 0)), "on disk" if save.get("exists", false) else "none on disk", save.get("checkpoint", NONE)])
	return "\n".join(rows)


## The armed hazards, named in red, or a dash.
static func _hazards(data: Dictionary) -> String:
	var hazards: Dictionary = data.get("hazards", {})
	var armed: PackedStringArray = PackedStringArray()
	for hazard: String in hazards.keys():
		if hazards[hazard]:
			armed.append("[color=%s]%s[/color]" % [WARN, hazard.to_upper()])
	return "%s  %s" % [_key("HAZARDS"), " · ".join(armed) if not armed.is_empty() else NONE]


func _show(width: float, text: String) -> void:
	body.custom_minimum_size.x = width
	body.text = text
	# Shrink back to the text after a longer page.
	reset_size()


static func _header(page: String) -> String:
	return "[b][color=%s]DEBUG  %s[/color][/b]  [color=%s]F3 · F12[/color]" % [ACCENT, page, MUTED]


static func _key(caption: String) -> String:
	return "[color=%s]%s[/color]" % [ACCENT, caption]


static func _or_none(value: Variant) -> String:
	var text: String = str(value)
	return NONE if text.is_empty() else text
