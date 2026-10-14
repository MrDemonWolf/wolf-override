class_name TextSize
extends RefCounted
## The TEXT SIZE setting (Settings, DISPLAY tab; STORY-3): one factor, 100% to 200%, that the dialogue
## box, the hint bar, the tutorial prompt, the top cards, the answer buttons and the station name
## labels multiply their font sizes by. Menus keep their own sizes.

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


## Gives [param label] its font at [param base] px times the text size, and remembers the base.
static func size_label(label: Label, base: int) -> void:
	label.set_meta(&"text_base_size", base)
	label.add_theme_font_size_override(&"font_size", px(base))


## Resizes a station's name label to its text at the current text size, centred on
## [param center_x]. At 100% its top is at [param top]; a larger text grows the plate upward, away
## from the machine under it, so its bottom edge stays where it was.
static func fit_world_label(label: Label, center_x: float, top: float) -> void:
	var base: int = int(label.get_meta(&"text_base_size", label.get_theme_font_size(&"font_size")))
	label.add_theme_font_size_override(&"font_size", px(base))
	label.size = Vector2.ZERO
	label.size = label.get_combined_minimum_size()
	var font: Font = label.get_theme_font(&"font")
	var grown: float = (font.get_height(px(base)) - font.get_height(base)) * maxi(label.get_line_count(), 1)
	label.position = Vector2(center_x - label.size.x * 0.5, top - grown)
