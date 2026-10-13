extends Node2D
## DESIGN DRAWING ONLY (option C, revision 2, scratch, never part of the repository). WOLF's standby dock
## inside a guarded bay, built as a real one would be: flat-shaded layer textures (design_art.py, 4 px per
## world px) plus a handful of live parts. Three parts on three nodes:
##   back = true    -> the bay behind WOLF (z 1): back.png (lit by the painted roof fitting) + live
##                     umbilical, connector and dock lamp.
##   shutter = true -> four telescoping mesh leaves (z 3): leaf.png x3, leaf_lead.png + live hook bolt.
##   neither        -> the frame (z 4): frame.png (with the lock pilaster) + live guard lock (intact, or
##                     torn off and hanging by its cable) and status lamp.
## One drive value, `opening` 0..1 (as on main): 0 = locked; 0..0.04 = the lock tearing off its mount;
## 0.04..1 = the leaves telescoping left. `wake` 0..1 turns the dock lamp blue.
## Variants for Nathanial: `stencils` (8 px stencils or blank plates), `keypad` (keypad or a blank 1.2 m
## backplate), `mesh` (welded mesh or a flat tone, for the shimmer check).
## Local origin = world (115, 365). 1 m = 40 px. Floor = local y 75 (world 440).

@export var shutter: bool = false
@export var back: bool = false
var opening: float = 0.0:
	set(value):
		opening = clampf(value, 0.0, 1.0)
		set_process(not back and not shutter and opening > 0.0)
		queue_redraw()
var wake: float = 0.0:
	set(value):
		wake = clampf(value, 0.0, 1.0)
		queue_redraw()
var stencils: bool = true:
	set(value):
		stencils = value
		queue_redraw()
var keypad: bool = true:
	set(value):
		keypad = value
		queue_redraw()
var mesh: bool = true:
	set(value):
		mesh = value
		queue_redraw()
var _blink_on: bool = true
var _blink_t: float = 0.0
var _tex: Dictionary = {}
var _glow: Texture2D

const ART: String = "res://cage_design/art/"
const LEAF_STEP: float = 40.0
const LAMP_GREEN: Color = Color("#4fd27f")
const LAMP_RED: Color = Color("#ff3b2f")
const LAMP_AMBER: Color = Color("#ffae2a")
const LAMP_BLUE: Color = Color("#4fb0ff")
const LAMP_AT: Vector2 = Vector2(92, 18.3)
const LOCK_AT: Vector2 = Vector2(80, 27)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for n: String in ["back", "leaf", "leaf_lead", "leaf_plain", "leaf_lead_plain", "frame", "frame_notext", "frame_plain", "lock"]:
		var img: Image = Image.load_from_file(ProjectSettings.globalize_path(ART + n + ".png"))
		img.generate_mipmaps()
		_tex[n] = ImageTexture.create_from_image(img)
	var grad: Gradient = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var g: GradientTexture2D = GradientTexture2D.new()
	g.gradient = grad
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	g.width = 64
	g.height = 64
	_glow = g
	set_process(not back and not shutter and opening > 0.0)
	queue_redraw()


func _process(delta: float) -> void:
	# Door-forced alarm: the status lamp flashes red at 2 Hz (one redraw per toggle).
	_blink_t += delta
	if _blink_t >= 0.25:
		_blink_t = 0.0
		_blink_on = not _blink_on
		queue_redraw()


func _draw() -> void:
	if _tex.is_empty():
		return
	if back:
		_draw_bay()
	elif shutter:
		_draw_leaves()
	else:
		_draw_frame()


func _glow_at(at: Vector2, radius: float, color: Color) -> void:
	draw_texture_rect(_glow, Rect2(at - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, color)


func _draw_bay() -> void:
	draw_texture_rect(_tex["back"], Rect2(-82, -21, 164, 96), false)
	# The umbilical (3 px, lighter than the plate) into the breakaway connector on WOLF's back. Once the
	# lock goes, the connector has let go and the spring reel has wound it up under the roof.
	var released: bool = opening > 0.0
	var head_y: float = -7.0 if released else 20.0
	draw_rect(Rect2(15.5, -9, 3, head_y + 10), Color("#8a939d"))
	draw_rect(Rect2(15.5, -9, 0.8, head_y + 10), Color("#b1b9c1"))
	draw_rect(Rect2(17.7, -9, 0.8, head_y + 10), Color("#5f6872"))
	draw_rect(Rect2(15.0, head_y - 2.0, 4, 2.2), Color("#3a424b"))
	draw_rect(Rect2(13.5, head_y, 7, 12), Color("#7a8590"))
	draw_rect(Rect2(13.5, head_y, 7, 0.8), Color("#a9b2bb"))
	draw_rect(Rect2(13.5, head_y + 5.0, 7, 1.6), Color("#2b3138"))
	draw_rect(Rect2(13.5, head_y + 10.2, 7, 1.8), Color("#1b2026"))
	var lens: Vector2 = Vector2(17, head_y + 2.6)
	if released:
		draw_rect(Rect2(lens - Vector2(1.2, 1.2), Vector2(2.4, 2.4)), Color("#141a1f"))
	else:
		var c: Color = LAMP_AMBER.lerp(LAMP_BLUE, wake)
		if wake > 0.0:
			# The blue answers from inside: a small pool on the back plate behind WOLF's shoulders.
			_glow_at(Vector2(17, 25), 34.0, Color(LAMP_BLUE, 0.5 * wake))
		_glow_at(lens, 6.0, Color(c, 0.7))
		draw_rect(Rect2(lens - Vector2(1.5, 1.5), Vector2(3, 3)), c)


func _draw_leaves() -> void:
	var slide: float = clampf((opening - 0.04) / 0.96, 0.0, 1.0)
	var sfx: String = "" if mesh else "_plain"
	for k: int in range(4):
		var x: float = lerpf(-82.0 + LEAF_STEP * k, -82.0, slide)
		draw_texture_rect(_tex[("leaf_lead" if k == 3 else "leaf") + sfx], Rect2(x, -21, 44, 90), false)
		if k == 3 and opening > 0.0:
			# The hook bolt is still thrown: the lock body tore off around it, it did not retract.
			draw_rect(Rect2(x + 44, 32, 4.5, 2.0), Color("#9aa3ad"))
			draw_rect(Rect2(x + 47, 33.2, 1.5, 2.6), Color("#9aa3ad"))


func _draw_frame() -> void:
	var key: String = "frame"
	if not keypad:
		key = "frame_plain"
	elif not stencils:
		key = "frame_notext"
	draw_texture_rect(_tex[key], Rect2(-93, -45, 193, 126), false)
	# Guard lock (spring-locked, power-to-unlock, hook bolt monitored) on the latch post and pilaster,
	# 1.0-1.35 m up. When WOLF drives the leaf outward the hook bolt loads the keeper in prying, the
	# module's mounting bolts shear and it hangs by its cable; bright scars stay where it was bolted.
	if opening <= 0.0:
		draw_texture_rect(_tex["lock"], Rect2(LOCK_AT, Vector2(8, 14)), false)
	else:
		var brk: float = clampf(opening / 0.04, 0.0, 1.0)
		draw_rect(Rect2(85.5, 27.6, 2.2, 1.4), Color("#a7b0ba"))
		draw_rect(Rect2(85.5, 39.0, 2.2, 1.4), Color("#a7b0ba"))
		draw_rect(Rect2(87, 41, 1, 3 + 6 * brk), Color("#0e1215"))
		draw_set_transform(Vector2(84, 34 + 9 * brk), deg_to_rad(32.0 * brk), Vector2.ONE)
		draw_texture_rect(_tex["lock"], Rect2(-4, -7, 8, 14), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Status lamp on the pilaster's backplate: steady green = locked and bolt monitored; 2 Hz red = forced.
	if opening > 0.0:
		if _blink_on:
			_glow_at(LAMP_AT, 7.0, Color(LAMP_RED, 0.8))
			draw_rect(Rect2(LAMP_AT - Vector2(1.3, 1.3), Vector2(2.6, 2.6)), LAMP_RED)
	else:
		_glow_at(LAMP_AT, 5.0, Color(LAMP_GREEN, 0.6))
		draw_rect(Rect2(LAMP_AT - Vector2(1.3, 1.3), Vector2(2.6, 2.6)), LAMP_GREEN)
