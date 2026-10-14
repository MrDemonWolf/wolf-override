class_name TextSize
extends RefCounted
## The TEXT SIZE setting (Settings, DISPLAY tab; STORY-3): one factor, 100% to 200%, that the dialogue
## box, the hint bar, the tutorial prompt, the top cards, the answer buttons and the station name
## labels multiply their font sizes by (the station names up to WORLD_MAX_FACTOR). Menus keep their
## own sizes.

## The sizes Settings offers, as factors.
const STEPS: Array[float] = [1.0, 1.25, 1.5, 1.75, 2.0]

static var factor: float = 1.0


## [param base] px at the current text size.
static func px(base: int) -> int:
	return roundi(base * factor)


## The nearest offered step to [param value] (a saved or hand-edited setting).
static func nearest_step(value: float) -> float:
	var best: float = STEPS[0]
	for step: float in STEPS:
		if absf(step - value) < absf(best - value):
			best = step
	return best


## Station names over the machines grow with the text size up to this factor; above it they keep
## this size: larger, neighbouring names would run into each other in the rooms' rows of machines
## (WORLD_ROW_GROWTH breaks them onto rows first), and on touch, where the play camera sits lower, the
## corridor's stacked COOLANT RELAY name and COOLANT FAULT tag would reach PAUSE.
const WORLD_MAX_FACTOR: float = 1.5


## The factor station names in the rooms take at the current text size.
static func world_factor() -> float:
	return minf(factor, WORLD_MAX_FACTOR)


## [param base] px for a station name at the current text size.
static func world_px(base: int) -> int:
	return roundi(base * world_factor())


## Gives [param label] (a station name in a room) its font at [param base] px times the text size
## (at most WORLD_MAX_FACTOR), and remembers the base.
static func size_label(label: Label, base: int) -> void:
	label.set_meta(&"text_base_size", base)
	label.add_theme_font_size_override(&"font_size", world_px(base))


## Station names stand between machines with little room either side. Above 100% a name breaks
## between its words onto more rows, so no row grows much wider than the whole name at 100%, and
## neighbouring names neither overlap nor reach the edge of the view, where they fade (a word stays
## whole, so a one-word name still grows).
const WORLD_ROW_GROWTH: float = 1.2


## Resizes a station's name label to its text at the current text size (world_px), centred on
## [param center_x]. At 100% its top is at [param top]; a larger text grows the plate upward, away
## from the machine under it, so its bottom edge stays where it was.
static func fit_world_label(label: Label, center_x: float, top: float) -> void:
	var base: int = int(label.get_meta(&"text_base_size", label.get_theme_font_size(&"font_size")))
	wrap_world_label(label, base)
	label.position = Vector2(center_x - label.size.x * 0.5, top - world_growth(label, base))


## Gives [param label] its font at [param base] px for a station name (world_px) and sizes it to its text,
## breaking it between words (WORLD_ROW_GROWTH) when one row would be too wide.
static func wrap_world_label(label: Label, base: int) -> void:
	label.add_theme_font_size_override(&"font_size", world_px(base))
	var font: Font = label.get_theme_font(&"font")
	var limit: float = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, base).x * WORLD_ROW_GROWTH
	# Words keep the spacing they were written with ("VALVE  0 / 3"); a row's ends lose their spaces.
	var widest: float = 0.0
	var row: String = ""
	var rows: int = 0
	for word: String in label.text.split(" "):
		var joined: String = word if row.is_empty() else row + " " + word
		if row.strip_edges().is_empty() or word.is_empty() or font.get_string_size(joined.strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, world_px(base)).x <= limit:
			row = joined
		else:
			widest = maxf(widest, font.get_string_size(row.strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, world_px(base)).x)
			rows += 1
			row = word
	widest = maxf(widest, font.get_string_size(row.strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, world_px(base)).x)
	var wrapped: bool = rows > 0
	label.autowrap_mode = TextServer.AUTOWRAP_WORD if wrapped else TextServer.AUTOWRAP_OFF
	# The plate is as wide as its widest row (and its margins); a pixel spare keeps the rows as measured.
	label.custom_minimum_size.x = ceilf(widest) + label.get_theme_stylebox(&"normal").get_minimum_size().x + 2.0 if wrapped else 0.0
	# The combined minimum size is cached until the next frame, so the rows are measured at the new
	# width here: the label's own minimum size lays its text out at its current width.
	label.size = Vector2(label.custom_minimum_size.x, 0.0)
	var measured: Vector2 = label.get_minimum_size()
	label.size = Vector2(maxf(measured.x, label.custom_minimum_size.x), measured.y)
	label.update_minimum_size()


## How much taller [param label] stands than its one row at 100% ([param base] px).
static func world_growth(label: Label, base: int) -> float:
	var one_row: float = label.get_theme_font(&"font").get_height(base) + label.get_theme_stylebox(&"normal").get_minimum_size().y
	return maxf(label.size.y - one_row, 0.0)
