class_name TextSize
extends RefCounted
## The TEXT SIZE setting (Settings, DISPLAY tab; STORY-3): one factor, 100% to 200%, that the dialogue
## box, the hint bar, the tutorial prompt, the top cards, the answer buttons and the station name
## labels multiply their font sizes by (the station names up to WORLD_MAX_FACTOR). Menus keep their
## own sizes.

## The sizes Settings offers, as factors.
const STEPS: Array[float] = [1.0, 1.25, 1.5, 1.75, 2.0]

## The current factor: one of STEPS (1.0 is 100%). GameSettings sets it when the settings load and
## when TEXT SIZE changes, then emits text_size_changed so Main lays the HUD out again; px,
## world_factor and every caller read it live, so nothing keeps a stale copy.
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

## The clear gap (px, world) part_world_labels leaves between two neighbouring station names it parts:
## one pixel either side, so their plates' borders never share a pixel.
const WORLD_LABEL_GAP: float = 2.0


## Resizes a station's name label to its text at the current text size (world_px), centred on
## [param center_x]. At 100% its top is at [param top]; a larger text grows the plate upward, away
## from the machine under it, so its bottom edge stays where it was. [param room] (px, the whole plate
## with its margins) is the most width the plate may take before it breaks onto rows; INF leaves only
## WORLD_ROW_GROWTH's limit, and [method part_world_labels] passes less where a neighbour stands close.
## [param font_px] above 0 draws the name at that size instead of world_px (part_world_labels steps a
## name that cannot break narrow enough back toward its 100% size). Remembers [param center_x] and
## [param top] on the label, so part_world_labels can fit it again.
static func fit_world_label(label: Label, center_x: float, top: float, room: float = INF, font_px: int = 0) -> void:
	var base: int = int(label.get_meta(&"text_base_size", label.get_theme_font_size(&"font_size")))
	label.set_meta(&"world_center_x", center_x)
	label.set_meta(&"world_top", top)
	wrap_world_label(label, base, room, font_px)
	label.position = Vector2(center_x - label.size.x * 0.5, top - world_growth(label, base))


## Neighbouring station names that would cover each other part (localization PR L8, decision D3: the
## plates are translated, and a longer name must not run into the next one). Each pair of [param labels]
## whose plates overlap, both with words (shown or not: a room hides its names while the engineer is
## elsewhere), has its wider plate fitted again with only the room that clears the other plate by
## WORLD_LABEL_GAP, which breaks it onto rows at its spaces, and where one word is still wider than that
## room (Spanish REFRIGERANTE above 100%), draws it smaller, back toward its 100% size, until it fits,
## and if even that is too wide, moves it off its station's centre, away from the neighbour, by what is
## left over; when the wider one cannot be fitted again, the other is tried. Only plates fitted with [method fit_world_label] are moved; the
## others (the MANUAL BYPASS plate, the COOLANT FAULT tag) stand still. Rects are compared in global
## px, so plates under different parents (the corridor's and the bypass handle's) count. Plates that do
## not overlap are left exactly as fitted, so the English rooms, whose names stand apart at every TEXT
## SIZE step (text_boxes_test), are unchanged. Call it after fitting every label of the room.
static func part_world_labels(labels: Array[Label]) -> void:
	for _pass: int in labels.size():
		var parted: bool = false
		for a: int in labels.size():
			for b: int in range(a + 1, labels.size()):
				var first: Label = labels[a]
				var second: Label = labels[b]
				# Visibility is not asked: a room hides its names while the engineer is elsewhere and shows
				# them again without fitting them, so they are parted whether shown now or not.
				if first.text.is_empty() or second.text.is_empty():
					continue
				# Touching plates are apart, as the test's overlap check counts them (grow -0.5).
				if not first.get_global_rect().grow(-0.5).intersects(second.get_global_rect().grow(-0.5)):
					continue
				var wider: Label = first if first.size.x >= second.size.x else second
				var narrower: Label = second if wider == first else first
				if _narrow_beside(wider, narrower) or _narrow_beside(narrower, wider):
					parted = true
		if not parted:
			return


## Fits [param label] again (fit_world_label) into the room that clears [param neighbour]'s plate by
## WORLD_LABEL_GAP, both centred where they stand: first broken onto rows at its current size, then, if a
## word is still too wide, a pixel smaller at a time down to its 100% size (its text_base_size), never
## below; and if it is still too wide at 100%, moved away from the neighbour by the overlap left over
## (the Spanish COOLANT RELAY beside the fixed MANUAL BYPASS plate at 125%: a few px). Returns true when
## the plate got narrower or moved; false when it was not fitted by fit_world_label or already clears the
## neighbour.
static func _narrow_beside(label: Label, neighbour: Label) -> bool:
	if not label.has_meta(&"world_top"):
		return false
	var distance: float = absf(label.get_global_rect().get_center().x - neighbour.get_global_rect().get_center().x)
	var room: float = 2.0 * (distance - neighbour.size.x * 0.5 - WORLD_LABEL_GAP)
	var before: float = label.size.x
	if room >= before:
		return false
	var center_x: float = float(label.get_meta(&"world_center_x"))
	var top: float = float(label.get_meta(&"world_top"))
	var base: int = int(label.get_meta(&"text_base_size", label.get_theme_font_size(&"font_size")))
	var font_px: int = label.get_theme_font_size(&"font_size")
	fit_world_label(label, center_x, top, room, font_px)
	while label.size.x > room and font_px > base:
		font_px -= 1
		fit_world_label(label, center_x, top, room, font_px)
	if label.size.x > room:
		# Off centre by what the two plates still lack: their half widths and the gap, less the distance.
		var away: float = signf(label.get_global_rect().get_center().x - neighbour.get_global_rect().get_center().x)
		var shift: float = label.size.x * 0.5 + neighbour.size.x * 0.5 + WORLD_LABEL_GAP - distance
		fit_world_label(label, center_x + (away if away != 0.0 else -1.0) * shift, top, room, font_px)
		return true
	return label.size.x < before - 0.5


## Gives [param label] its font at [param base] px for a station name (world_px) and sizes it to its text,
## breaking it between words (WORLD_ROW_GROWTH) when one row would be too wide. A language written with
## spaces (DialogueBoxes.row_characters above 0) breaks at its spaces ([method _space_rows]), as station
## names always have; one whose rows run to the column (Chinese, Japanese, Korean) breaks by the text
## server's word rules (DialogueBoxes.row_texts, whole words only), so a name written without spaces
## breaks between its words too (PR L7d). The rows are measured on the name as drawn in the language
## shown, and a plate also breaks when it is wider than [param room] (px, margins included; PR L8, see
## [method part_world_labels]); [param font_px] above 0 replaces world_px(base) as its size.
static func wrap_world_label(label: Label, base: int, room: float = INF, font_px: int = 0) -> void:
	var px: int = font_px if font_px > 0 else world_px(base)
	label.add_theme_font_size_override(&"font_size", px)
	var font: Font = label.get_theme_font(&"font")
	# The rows are worked out from the name as it is drawn (the label translates its English text itself),
	# and no row may be wider than the shorter of the drawn and the English name at 100%: a longer
	# translation breaks onto rows to keep the English plate's footprint, which the rooms were laid out
	# for (Spanish RELÉ DE REFRIGERANTE in one row reached the view's edge at the corridor's start and
	# faded out). For English both are the same name, so its plates are unchanged.
	var shown: String = String(label.atr(label.text))
	var one_row: float = minf(font.get_string_size(shown, HORIZONTAL_ALIGNMENT_LEFT, -1.0, base).x, font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, base).x)
	var limit: float = one_row * WORLD_ROW_GROWTH
	# A neighbour close by (part_world_labels) leaves less: the plate's margins and the spare pixel below
	# come out of the room it gives.
	limit = minf(limit, room - label.get_theme_stylebox(&"normal").get_minimum_size().x - 2.0)
	# Words keep the spacing they were written with ("VALVE  0 / 3"); a row's ends lose their spaces.
	# Not TextParagraph for every language: its break rules move English rows ("VALVE  0 / 3" at 150%
	# broke as "VALVE" / "0 / 3" rather than "VALVE  0" / "/ 3", a narrower plate), and English stays as it was.
	var rows: Array[String] = _space_rows(shown, font, px, limit) if DialogueBoxes.row_characters() > 0 else DialogueBoxes.row_texts(shown, font, px, limit, true)
	var widest: float = 0.0
	for row: String in rows:
		widest = maxf(widest, font.get_string_size(row, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x)
	var wrapped: bool = rows.size() > 1
	label.autowrap_mode = TextServer.AUTOWRAP_WORD if wrapped else TextServer.AUTOWRAP_OFF
	# The plate is as wide as its widest row (and its margins); a pixel spare keeps the rows as measured.
	label.custom_minimum_size.x = ceilf(widest) + label.get_theme_stylebox(&"normal").get_minimum_size().x + 2.0 if wrapped else 0.0
	# The combined minimum size is cached until the next frame, so the rows are measured at the new
	# width here: the label's own minimum size lays its text out at its current width.
	label.size = Vector2(label.custom_minimum_size.x, 0.0)
	var measured: Vector2 = label.get_minimum_size()
	label.size = Vector2(maxf(measured.x, label.custom_minimum_size.x), measured.y)
	label.update_minimum_size()


## [param text] broken greedily at its spaces into rows no wider than [param limit] px at [param size] px
## of [param font]: each row takes words while the row still fits, and a row always takes at least one
## word, so a word wider than [param limit] keeps a row of its own. Repeated spaces stay inside a row
## ("VALVE  0 / 3"); each row is returned without the spaces at its ends. Used by wrap_world_label for
## languages written with spaces.
static func _space_rows(text: String, font: Font, size: int, limit: float) -> Array[String]:
	var rows: Array[String] = []
	var row: String = ""
	for word: String in text.split(" "):
		var joined: String = word if row.is_empty() else row + " " + word
		if row.strip_edges().is_empty() or word.is_empty() or font.get_string_size(joined.strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x <= limit:
			row = joined
		else:
			rows.append(row.strip_edges())
			row = word
	rows.append(row.strip_edges())
	return rows


## How much taller [param label] stands than its one row at 100% ([param base] px).
static func world_growth(label: Label, base: int) -> float:
	var one_row: float = label.get_theme_font(&"font").get_height(base) + label.get_theme_stylebox(&"normal").get_minimum_size().y
	return maxf(label.size.y - one_row, 0.0)
