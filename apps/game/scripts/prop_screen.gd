class_name PropScreen
extends Node2D
## The lit screen of a console drawn in code over its whole piece. The approved pieces (art set,
## 2026-10-16) are painted with their screens dark and blank ("screen content in code"), so the glow
## and the rows of a running readout are drawn here: no painted lettering, nothing that has to be
## translated, and the tint can follow the game's state. Used by the corridor's purge display, by
## Records Access's PURGE QUEUE and MIRROR PORT (the running log, [member Readout.LOG]) and by the
## dock bay's charger cabinet (its battery gauge and percent, [member Readout.BATTERY]); one copy for all.
##
## It is a child of the prop's Sprite2D, so it moves, scales and dims (modulate) with the prop and
## draws over it. [member glass] is in the piece's own pixels (piece px), as measured on the PNG.

## The glass's glow: the tint darkened this much (so the rows stand out on it) at this alpha over the
## dark painted glass. Review of art swap PR 2: at 0.35 a lit station read flat and dim at 1280x720
## next to the earlier painted glass, so the fill is only lightly darkened.
const FILL_DARKEN: float = 0.2
const FILL_ALPHA: float = 0.85
## The light the lit glass throws round itself (the shared additive RoomDepth.make_glow, as the
## stations' status lights use): this many times the glass's size, at this alpha. It is what lets a
## working screen pull the eye from across the room, and its colour change (the MIRROR PORT's cyan to
## green once copied) shows on the wall round it, not only on the small glass.
const HALO_SPREAD: float = 3.0
const HALO_ALPHA: float = 0.8
## The readout's rows: their share of the glass's width, top to bottom. Fixed, so a still is the same
## every run; short and long rows read as a log, not as words.
const ROWS: PackedFloat32Array = [0.72, 0.55, 0.83, 0.4, 0.66, 0.5]
## Each row's height and the gap under it, as shares of the glass's height (6 rows fill about 3/4 of it).
const ROW_HEIGHT: float = 0.055
const ROW_STEP: float = 0.12
## The rows' inset from the glass's left and top edges, as shares of its width and height.
const INSET: Vector2 = Vector2(0.08, 0.14)
## The rows: the tint lightened this much and nearly opaque, so they read as lit lines on the glow.
const ROW_LIGHTEN: float = 0.25
const ROW_ALPHA: float = 0.9
## A thin bright line along the glass's top edge, the light catching it (alpha).
const EDGE_ALPHA: float = 0.35
## What the glass shows: a running log's rows, or a battery's charge (the dock bay's charger,
## Nathanial 2026-10-16: "And it has the battery charge status").
enum Readout { LOG, BATTERY }
## [member percent] for a battery whose charge is cut (the glass dark, nothing lit) and for the empty
## pad on standby (the battery's outline only, dim: no battery is on the pad).
const BATTERY_OFF: int = -1
const BATTERY_IDLE: int = -2
## The battery readout's layout, in the units of BATTERY_WINDOW (the art set's compose.py
## battery_status, drawn in a 33 x 30 world px window): the outline's top-left and size, its terminal
## nub, the dark glass inset inside the outline (OUTLINE_INSET), the six segments (each SEGMENT_SIZE, SEGMENT_STEP apart from
## SEGMENT_FIRST), the digits' height and baseline (Roboto bold; the % sign at PERCENT_SHARE of their
## height, as device battery readouts set it), and the gap between the number and the sign.
const BATTERY_WINDOW: Vector2 = Vector2(33.0, 30.0)
const OUTLINE: Rect2 = Rect2(2.5, 2.5, 26.0, 9.0)
const NUB: Rect2 = Rect2(28.5, 5.0, 2.0, 4.0)
const OUTLINE_INSET: float = 0.9
const SEGMENTS: int = 6
const SEGMENT_FIRST: Vector2 = Vector2(4.1, 4.2)
const SEGMENT_SIZE: Vector2 = Vector2(3.3, 5.6)
const SEGMENT_STEP: float = 3.95
const DIGIT_HEIGHT: float = 11.5
const DIGIT_BASELINE: float = 27.8
const PERCENT_SHARE: float = 0.6
const DIGIT_GAP: float = 0.5
## Roboto's digits stand about this share of a font size (its em) tall, so the font is sized
## DIGIT_HEIGHT / DIGIT_EM to draw digits DIGIT_HEIGHT tall.
const DIGIT_EM: float = 0.72
## The outline's value against the tint (lit, and on idle standby), the inset's dark glass, an unlit
## segment, and the screen's own light (compose.py: radius 16 at 0.2; idle 8 at 0.06), as alphas of
## HALO_ALPHA's halo. The idle outline is a little brighter than compose.py's 0.35 (review of dock bay
## PR 2's stills: at 1280x720 the empty battery barely read).
const OUTLINE_LIT: float = 0.6
const OUTLINE_IDLE: float = 0.5
const INSET_COLOR: Color = Color8(8, 11, 13)
const SEGMENT_UNLIT: Color = Color8(28, 36, 40)
const BATTERY_HALO: float = 0.25
const IDLE_HALO: float = 0.08
## The digits' face: Roboto at bold weight (one FontVariation, made once).
static var _digits_font: FontVariation

## The glass, in piece px.
var glass: Rect2 = Rect2()
## The halo round the glass (HALO_SPREAD, HALO_ALPHA); made by attach, tinted with [member tint].
var halo: Sprite2D
## The screen's light; setting it redraws the glass and retints the halo, so it can follow the state.
var tint: Color = Color.WHITE:
	set(value):
		tint = value
		_sync_halo()
		queue_redraw()
## What the glass shows (see Readout).
var readout: Readout = Readout.LOG:
	set(value):
		readout = value
		_sync_halo()
		queue_redraw()
## The battery's charge in percent (0 .. 100), or BATTERY_OFF or BATTERY_IDLE. Only the BATTERY
## readout reads it.
var percent: int = 100:
	set(value):
		percent = value
		_sync_halo()
		queue_redraw()


## Adds a screen named [param screen_name] over [param glass] (piece px) of [param prop], lit
## [param color], with its halo. Returns it so the caller can change its tint later.
static func attach(prop: Sprite2D, screen_name: String, glass_rect: Rect2, color: Color) -> PropScreen:
	var screen: PropScreen = PropScreen.new()
	screen.name = screen_name
	screen.glass = glass_rect
	prop.add_child(screen)
	var rect: Rect2 = screen.local_glass()
	screen.halo = RoomDepth.make_glow(color, rect.size * HALO_SPREAD, HALO_ALPHA)
	screen.halo.name = "Halo"
	screen.halo.position = rect.get_center()
	# A child draws after its parent's _draw, so the halo also lifts the glass and its rows.
	screen.add_child(screen.halo)
	screen.tint = color
	return screen


## The glass in the prop sprite's local space (piece px about its centre).
func local_glass() -> Rect2:
	return RoomDepth.prop_local(get_parent() as Sprite2D, glass)


## The halo follows the tint, and for a battery its charge: dimmer than a log's screen, faint on idle
## standby, out when the charge is cut.
func _sync_halo() -> void:
	if halo == null:
		return
	var alpha: float = HALO_ALPHA
	if readout == Readout.BATTERY:
		alpha = 0.0 if percent == BATTERY_OFF else (IDLE_HALO if percent == BATTERY_IDLE else BATTERY_HALO)
	halo.modulate = Color(tint, alpha)


func _draw() -> void:
	if readout == Readout.BATTERY:
		_draw_battery()
		return
	var rect: Rect2 = local_glass()
	draw_rect(rect, Color(tint.darkened(FILL_DARKEN), FILL_ALPHA))
	var row_height: float = rect.size.y * ROW_HEIGHT
	for index: int in ROWS.size():
		var top: float = rect.position.y + rect.size.y * (INSET.y + ROW_STEP * index)
		var left: float = rect.position.x + rect.size.x * INSET.x
		draw_rect(Rect2(left, top, rect.size.x * (1.0 - 2.0 * INSET.x) * ROWS[index], row_height), Color(tint.lightened(ROW_LIGHTEN), ROW_ALPHA))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, maxf(row_height * 0.5, 1.0))), Color(tint.lightened(0.6), EDGE_ALPHA))


## The battery readout (compose.py battery_status): an outline with SEGMENTS segments, lit from the left
## as many as the charge fills, over the percent in digits; numbers only, nothing to translate. Charge
## cut, the glass stays dark; on idle standby only the outline shows, dim.
func _draw_battery() -> void:
	if percent == BATTERY_OFF:
		return
	var rect: Rect2 = local_glass()
	var unit: Vector2 = rect.size / BATTERY_WINDOW
	var at: Callable = func(box: Rect2) -> Rect2: return Rect2(rect.position + box.position * unit, box.size * unit)
	var idle: bool = percent == BATTERY_IDLE
	var edge: Color = Color(tint.darkened(1.0 - (OUTLINE_IDLE if idle else OUTLINE_LIT)), 1.0)
	draw_rect(at.call(OUTLINE), edge)
	draw_rect(at.call(NUB), edge)
	draw_rect(at.call(OUTLINE.grow(-OUTLINE_INSET)), INSET_COLOR)
	if idle:
		return
	var lit: int = maxi(1, roundi(percent / 100.0 * SEGMENTS))
	for index: int in SEGMENTS:
		var segment: Rect2 = Rect2(SEGMENT_FIRST + Vector2(SEGMENT_STEP * index, 0.0), SEGMENT_SIZE)
		draw_rect(at.call(segment), tint if index < lit else SEGMENT_UNLIT)
	var font: Font = digits_font()
	var size: int = roundi(DIGIT_HEIGHT * unit.y / DIGIT_EM)
	var sign_size: int = roundi(size * PERCENT_SHARE)
	var digits: String = str(percent)
	var width: float = font.get_string_size(digits, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + DIGIT_GAP * unit.x + font.get_string_size("%", HORIZONTAL_ALIGNMENT_LEFT, -1, sign_size).x
	var base: Vector2 = Vector2(rect.get_center().x - width * 0.5, rect.position.y + DIGIT_BASELINE * unit.y)
	draw_string(font, base, digits, HORIZONTAL_ALIGNMENT_LEFT, -1, size, tint)
	base.x += font.get_string_size(digits, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + DIGIT_GAP * unit.x
	draw_string(font, base, "%", HORIZONTAL_ALIGNMENT_LEFT, -1, sign_size, tint)


## Roboto at bold weight for the battery's digits (made on first use and kept for every screen).
static func digits_font() -> FontVariation:
	if _digits_font == null:
		_digits_font = FontVariation.new()
		_digits_font.base_font = load("res://assets/fonts/Roboto-Variable.ttf") as Font
		_digits_font.variation_opentype = {"wght": 700}
	return _digits_font
