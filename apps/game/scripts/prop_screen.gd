class_name PropScreen
extends Node2D
## The lit screen of a console drawn in code over its whole piece. The approved pieces (art set,
## 2026-10-16) are painted with their screens dark and blank ("screen content in code"), so the glow
## and the rows of a running readout are drawn here: no painted lettering, nothing that has to be
## translated, and the tint can follow the game's state. Used by the corridor's purge display and by
## Records Access's PURGE QUEUE and MIRROR PORT; one copy for all three.
##
## It is a child of the prop's Sprite2D, so it moves, scales and dims (modulate) with the prop and
## draws over it. [member glass] is in the piece's own pixels (piece px), as measured on the PNG.

## The glass's glow: the tint darkened this much (so the rows stand out on it) at this alpha over the
## dark painted glass.
const FILL_DARKEN: float = 0.35
const FILL_ALPHA: float = 0.8
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

## The glass, in piece px.
var glass: Rect2 = Rect2()
## The screen's light; set it to follow the state (call queue_redraw after a change).
var tint: Color = Color.WHITE:
	set(value):
		tint = value
		queue_redraw()


## Adds a screen named [param screen_name] over [param glass] (piece px) of [param prop], lit
## [param color]. Returns it so the caller can change its tint later.
static func attach(prop: Sprite2D, screen_name: String, glass_rect: Rect2, color: Color) -> PropScreen:
	var screen: PropScreen = PropScreen.new()
	screen.name = screen_name
	screen.glass = glass_rect
	screen.tint = color
	prop.add_child(screen)
	return screen


## The glass in the prop sprite's local space (piece px about its centre).
func local_glass() -> Rect2:
	return RoomDepth.prop_local(get_parent() as Sprite2D, glass)


func _draw() -> void:
	var rect: Rect2 = local_glass()
	draw_rect(rect, Color(tint.darkened(FILL_DARKEN), FILL_ALPHA))
	var row_height: float = rect.size.y * ROW_HEIGHT
	for index: int in ROWS.size():
		var top: float = rect.position.y + rect.size.y * (INSET.y + ROW_STEP * index)
		var left: float = rect.position.x + rect.size.x * INSET.x
		draw_rect(Rect2(left, top, rect.size.x * (1.0 - 2.0 * INSET.x) * ROWS[index], row_height), Color(tint.lightened(ROW_LIGHTEN), ROW_ALPHA))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, maxf(row_height * 0.5, 1.0))), Color(tint.lightened(0.6), EDGE_ALPHA))
