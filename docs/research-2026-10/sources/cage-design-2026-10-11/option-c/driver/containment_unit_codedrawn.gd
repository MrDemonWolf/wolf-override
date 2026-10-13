extends Node2D
## DESIGN DRAWING ONLY (option C, scratch, never part of the repository). WOLF's standby dock inside a
## guarded bay, drawn the way the real one would be code-drawn: three parts on three nodes.
##   back = true    -> the bay behind WOLF (z 1): back plate, charger cabinet, belly cradle, umbilical reel,
##                     umbilical and its connector on WOLF's back with the dock lamp.
##   shutter = true -> the front (z 3): four telescoping mesh leaves on a top track.
##   neither        -> the frame (z 4): posts, head beam, sill, anchors, guard lock, keypad station,
##                     status lamp, camera, conduit, contact shadow.
## One drive value, `opening` 0..1 (as on main): 0 = locked; 0..0.04 = the lock tearing off and the
## leading leaf jumping; 0.04..1 = the leaves telescoping left. `wake` 0..1 turns the dock lamp blue.
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
var show_stencils: bool = true
var _blink_on: bool = true
var _blink_t: float = 0.0
var _font: Font
var _mesh_tex: ImageTexture

const FLOOR: float = 75.0
const LEAF_W: float = 44.0
const LEAF_STEP: float = 40.0
const LEAF_TOP: float = -21.0
const LEAF_BOTTOM: float = 69.0
const STEEL: Color = Color("#30363e")
const STEEL_LIT: Color = Color("#5c6571")
const STEEL_DARK: Color = Color("#161a1f")
const LEAF: Color = Color("#383f48")
const LEAF_LIT: Color = Color("#606a76")
const MESH: Color = Color(0.05, 0.07, 0.09, 0.22)
const MESH_SHEEN: Color = Color(0.55, 0.65, 0.75, 0.05)
const BACK_PLATE: Color = Color("#252b32")
const BACK_SEAM: Color = Color("#0f1317")
const CABINET: Color = Color("#2b3138")
const HAZARD: Color = Color("#d39a1c")
const HAZARD_DARK: Color = Color("#16191c")
const STENCIL: Color = Color("#a19ea0")
const SOCKET: Color = Color("#141a1f")
const LAMP_GREEN: Color = Color("#4fd27f")
const LAMP_RED: Color = Color("#ff3b2f")
const LAMP_AMBER: Color = Color("#ffae2a")
const LAMP_BLUE: Color = Color("#4fb0ff")


func _ready() -> void:
	_font = load("res://assets/fonts/Roboto-Variable.ttf") as Font
	set_process(false)
	if shutter:
		# Welded mesh as a 3 x 3 px tile: one strand each way (about 75 mm pitch, drawn coarser than a
		# real RF screen so it reads as mesh, not glass). One textured rect per leaf.
		var img: Image = Image.create(3, 3, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for i: int in range(3):
			img.set_pixel(i, 0, Color(0.55, 0.62, 0.70, 0.15))
			img.set_pixel(0, i, Color(0.55, 0.62, 0.70, 0.15))
		_mesh_tex = ImageTexture.create_from_image(img)
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _process(delta: float) -> void:
	# Door-forced alarm: the status lamp flashes red at 2 Hz (one redraw per toggle, 4 per second).
	_blink_t += delta
	if _blink_t >= 0.25:
		_blink_t = 0.0
		_blink_on = not _blink_on
		queue_redraw()


func _phase_break() -> float:
	return clampf(opening / 0.04, 0.0, 1.0)


func _phase_slide() -> float:
	return clampf((opening - 0.04) / 0.96, 0.0, 1.0)


func _draw() -> void:
	if back:
		_draw_bay()
	elif shutter:
		_draw_leaves()
	else:
		_draw_frame()


# ---------------------------------------------------------------- back: the bay behind WOLF (z 1)
func _draw_bay() -> void:
	# Back plate: 6 mm steel on the bay's back wall, three bolted panels.
	draw_rect(Rect2(-82, -21, 164, 96), BACK_PLATE)
	draw_rect(Rect2(-82, -21, 164, 14), Color(0, 0, 0, 0.18))
	draw_rect(Rect2(-82, -7, 164, 10), Color(0, 0, 0, 0.08))
	for sx: float in [-27.0, 27.0]:
		draw_line(Vector2(sx, -21), Vector2(sx, 75), BACK_SEAM, 1.0)
	# Conduit: charger cabinet up the back wall and along under the roof to the umbilical reel.
	draw_line(Vector2(-70, 23), Vector2(-70, -16), Color("#3f4750"), 2.0)
	draw_line(Vector2(-71, -16), Vector2(10, -16), Color("#3f4750"), 2.0)
	for strap: Vector2 in [Vector2(-70, 4), Vector2(-50, -16), Vector2(-15, -16)]:
		draw_rect(Rect2(strap.x - 1.5, strap.y - 1.5, 3, 3), Color("#555e69"))
	# Charger and cell controller cabinet, 0.5 x 1.3 m, on the floor at the left end.
	draw_rect(Rect2(-79, 23, 20, 52), CABINET)
	draw_line(Vector2(-79, 23), Vector2(-59, 23), STEEL_LIT, 1.0)
	draw_line(Vector2(-69, 25), Vector2(-69, 73), STEEL_DARK, 1.0)
	for ly: float in [30.0, 33.0, 36.0]:
		draw_line(Vector2(-77, ly), Vector2(-71, ly), STEEL_DARK, 1.0)
	draw_rect(Rect2(-66, 28, 5, 3), Color("#59616c"))
	# Belly cradle: a pedestal between his fore and hind legs that carries his weight with the motors
	# locked out, charging contacts on the saddle (hidden under him).
	draw_rect(Rect2(6, 48, 10, 27), STEEL)
	draw_line(Vector2(6, 48), Vector2(6, 75), STEEL_LIT, 1.0)
	draw_rect(Rect2(4, 70, 14, 5), STEEL_DARK)
	draw_colored_polygon(PackedVector2Array([Vector2(1, 43), Vector2(21, 43), Vector2(17, 49), Vector2(5, 49)]), STEEL)
	draw_rect(Rect2(1, 42, 20, 2), Color("#101417"))
	# Umbilical reel (spring cable reel) hung from the roof.
	draw_rect(Rect2(12, -20, 3, 3), STEEL_DARK)
	draw_rect(Rect2(19, -20, 3, 3), STEEL_DARK)
	draw_rect(Rect2(9, -17, 16, 8), STEEL)
	draw_line(Vector2(9, -17), Vector2(25, -17), STEEL_LIT, 1.0)
	draw_circle(Vector2(17, -13), 3.0, STEEL_DARK)
	# The umbilical: plugged into WOLF's back in standby; after the lock goes, the breakaway connector has
	# let go and the reel has wound it up under the roof.
	var released: bool = opening > 0.0
	var head_y: float = -6.0 if released else 21.0
	draw_line(Vector2(17, -9), Vector2(17, head_y), Color("#0e1215"), 2.0)
	draw_rect(Rect2(14, head_y, 6, 11), Color("#2b3138"))
	draw_rect(Rect2(14, head_y + 3, 6, 2), Color("#545d68"))
	var lens: Vector2 = Vector2(17, head_y + 1.5)
	if released:
		draw_circle(lens, 1.2, SOCKET)
	else:
		var c: Color = LAMP_AMBER.lerp(LAMP_BLUE, wake)
		if wake > 0.0:
			# The blue answers from inside: a small pool on WOLF's back and the back plate behind him.
			_glow(Vector2(17, 25), 30.0, Color(LAMP_BLUE, 0.30 * wake))
		_glow(lens, 6.0, Color(c, 0.4))
		draw_circle(lens, 1.6, c)


# ---------------------------------------------------------------- shutter: the telescoping leaves (z 3)
func _draw_leaves() -> void:
	var brk: float = _phase_break()
	var slide: float = _phase_slide()
	for k: int in range(4):
		var closed_x: float = -82.0 + LEAF_STEP * k - k * brk
		var x: float = lerpf(closed_x, -82.0, slide)
		_draw_leaf(x, k == 3)


func _draw_leaf(x: float, leading: bool) -> void:
	var w: float = LEAF_W
	# Mesh infill (welded fine mesh: reads as a tone at this scale), then the frame.
	var infill: Rect2 = Rect2(x + 3, LEAF_TOP + 3, w - 6, 57 - LEAF_TOP - 3)
	draw_rect(infill, MESH)
	if _mesh_tex != null:
		draw_texture_rect(_mesh_tex, infill, true)
	draw_rect(Rect2(x, LEAF_TOP, 3, LEAF_BOTTOM - LEAF_TOP), LEAF)
	draw_rect(Rect2(x + w - 3, LEAF_TOP, 3, LEAF_BOTTOM - LEAF_TOP), LEAF)
	draw_rect(Rect2(x, LEAF_TOP, w, 3), LEAF)
	draw_rect(Rect2(x + 3, 26, w - 6, 2), LEAF)
	draw_line(Vector2(x, LEAF_TOP + 0.5), Vector2(x + w, LEAF_TOP + 0.5), LEAF_LIT, 1.0)
	draw_line(Vector2(x + 3, 26.5), Vector2(x + w - 3, 26.5), LEAF_LIT, 1.0)
	draw_line(Vector2(x + 0.5, LEAF_TOP), Vector2(x + 0.5, LEAF_BOTTOM), LEAF_LIT, 1.0)
	# Kick plate: 0.3 m of 6 mm plate at the foot of every leaf.
	draw_rect(Rect2(x, 57, w, 12), Color("#323940"))
	draw_line(Vector2(x, 57.5), Vector2(x + w, 57.5), LEAF_LIT, 1.0)
	if leading:
		# Leading stile: crush point, yellow/black diagonal stripes; guard-lock handle module and bolt.
		var sx: float = x + w - 4
		draw_rect(Rect2(sx, LEAF_TOP, 4, LEAF_BOTTOM - LEAF_TOP), HAZARD_DARK)
		var y: float = LEAF_TOP
		while y < LEAF_BOTTOM:
			var y2: float = minf(y + 3.0, LEAF_BOTTOM)
			draw_colored_polygon(PackedVector2Array([Vector2(sx, y), Vector2(sx + 4, y - 2), Vector2(sx + 4, minf(y2 - 2, LEAF_BOTTOM)), Vector2(sx, y2)]), HAZARD)
			y += 6.0
		draw_rect(Rect2(x + w - 11, 28, 7, 11), Color("#2c3239"))
		draw_line(Vector2(x + w - 11, 28.5), Vector2(x + w - 4, 28.5), LEAF_LIT, 1.0)
		if opening > 0.0:
			# Sheared bolt stub.
			draw_colored_polygon(PackedVector2Array([Vector2(x + w, 32), Vector2(x + w + 2, 31), Vector2(x + w + 1.5, 33), Vector2(x + w + 2.5, 34), Vector2(x + w, 35)]), Color("#9aa3ad"))
		else:
			draw_rect(Rect2(x + w, 32, 4, 3), Color("#8d96a0"))


# ---------------------------------------------------------------- frame (z 4)
func _draw_frame() -> void:
	# Contact shadow on the floor, darkest at the contact line.
	for i: int in range(5):
		draw_rect(Rect2(-92, FLOOR + i, 184, 1), Color(0, 0, 0, 0.5 - i * 0.1))
	# Sill / bottom guide channel, 0.15 m, with the leaves' guide slot.
	draw_rect(Rect2(-88, 69, 176, 6), STEEL)
	draw_line(Vector2(-88, 69.5), Vector2(88, 69.5), STEEL_LIT, 1.0)
	draw_line(Vector2(-82, 71.5), Vector2(82, 71.5), STEEL_DARK, 1.0)
	# Anchor base plates with two anchor bolts each, at both posts and mid-span.
	for ax: float in [-85.0, 0.0, 85.0]:
		draw_rect(Rect2(ax - 7, 73, 14, 2), STEEL_DARK)
		draw_rect(Rect2(ax - 7, 72.5, 14, 0.8), STEEL_LIT)
		for bx: float in [ax - 5, ax + 4]:
			draw_rect(Rect2(bx, 71.5, 1.5, 1.5), Color("#8b949e"))
	# Posts: 150 mm square tube.
	for px: float in [-88.0, 82.0]:
		draw_rect(Rect2(px, -33, 6, 108), STEEL)
		draw_line(Vector2(px + 0.5, -33), Vector2(px + 0.5, 75), STEEL_LIT, 1.0)
		draw_line(Vector2(px + 5.5, -33), Vector2(px + 5.5, 75), STEEL_DARK, 1.0)
	# The seal: conductive gasket strip on the latch post's inner face.
	draw_line(Vector2(81.5, LEAF_TOP + 2), Vector2(81.5, LEAF_BOTTOM - 1), Color("#7a6646"), 1.0)
	# Head beam (houses the four top tracks), with an even cap plate.
	draw_rect(Rect2(-90, -35, 180, 2), STEEL_DARK)
	draw_line(Vector2(-90, -34.5), Vector2(90, -34.5), STEEL_LIT, 1.0)
	draw_rect(Rect2(-88, -33, 176, 12), STEEL)
	draw_line(Vector2(-88, -32.5), Vector2(88, -32.5), STEEL_LIT, 1.0)
	draw_line(Vector2(-82, -21.5), Vector2(82, -21.5), STEEL_DARK, 1.0)
	# Corner gussets (welded) and the head beam's end bolts.
	draw_colored_polygon(PackedVector2Array([Vector2(-82, -21), Vector2(-77, -21), Vector2(-82, -16)]), STEEL)
	draw_colored_polygon(PackedVector2Array([Vector2(82, -21), Vector2(77, -21), Vector2(82, -16)]), STEEL)
	for bx: float in [-86.0, 84.5]:
		for by: float in [-30.0, -25.0]:
			draw_rect(Rect2(bx, by, 1.5, 1.5), Color("#7d8691"))
	if show_stencils and _font != null:
		_stencil("CU-01", Vector2(-80, -23.6))
		_stencil("KEEP CLEAR", Vector2(18, -23.6))
	# Camera: fixed housing on an arm off the latch post, aimed down at the door.
	draw_rect(Rect2(88, -31, 3, 2), STEEL_DARK)
	draw_colored_polygon(PackedVector2Array([Vector2(90, -33), Vector2(98, -31), Vector2(97, -26), Vector2(89, -28)]), Color("#525b66"))
	draw_colored_polygon(PackedVector2Array([Vector2(89, -28), Vector2(91, -27.4), Vector2(90.5, -25.5), Vector2(88.5, -26)]), Color("#0b0e11"))
	# Conduit: camera, keypad station and lock wiring down the outside of the latch post into the floor.
	draw_line(Vector2(94, -26), Vector2(94, 75), Color("#46505a"), 2.0)
	draw_line(Vector2(93.5, -26), Vector2(93.5, 75), STEEL_LIT, 0.6)
	for sy: float in [0.0, 50.0]:
		draw_rect(Rect2(92.5, sy, 3, 1.5), Color("#59626d"))
	draw_rect(Rect2(91, 73, 6, 2), STEEL_DARK)
	# Keypad station on a backplate: status lamp, card slot, 12-key PIN pad (1.5x real size so it reads).
	draw_rect(Rect2(90, 15, 8, 22), Color("#2e353d"))
	draw_line(Vector2(90, 15.5), Vector2(98, 15.5), STEEL_LIT, 1.0)
	draw_rect(Rect2(91, 21.5, 6, 1), Color("#090c0e"))
	draw_rect(Rect2(91, 24, 6, 9), Color("#1b2026"))
	for r: int in range(4):
		for c: int in range(3):
			draw_rect(Rect2(91.6 + c * 1.8, 24.7 + r * 2.0, 1.0, 1.2), Color("#7f8a95"))
	var lamp: Vector2 = Vector2(94, 18.3)
	draw_circle(lamp, 1.9, SOCKET)
	if opening > 0.0:
		if _blink_on:
			_glow(lamp, 7.0, Color(LAMP_RED, 0.45))
			draw_circle(lamp, 1.4, LAMP_RED)
	else:
		_glow(lamp, 5.0, Color(LAMP_GREEN, 0.3))
		draw_circle(lamp, 1.4, LAMP_GREEN)
	# Guard lock (spring-locked, power-to-unlock) on the latch post, 1.0-1.35 m up. When the lock fails
	# it tears off its mount and hangs by its cable; bright scars stay where it was bolted.
	if opening <= 0.0:
		draw_rect(Rect2(81, 27, 8, 14), Color("#2f363e"))
		draw_line(Vector2(81, 27.5), Vector2(89, 27.5), STEEL_LIT, 1.0)
		draw_rect(Rect2(83, 30, 4, 1), STEEL_DARK)
		draw_rect(Rect2(83, 36, 4, 1), STEEL_DARK)
	else:
		var brk: float = _phase_break()
		draw_rect(Rect2(82.5, 28, 3, 1.2), Color("#a7b0ba"))
		draw_rect(Rect2(82.5, 39, 3, 1.2), Color("#a7b0ba"))
		draw_line(Vector2(87, 44), Vector2(88, 41 + 6 * brk), Color("#0e1215"), 1.0)
		draw_set_transform(Vector2(85, 34 + 9 * brk), deg_to_rad(32.0 * brk), Vector2.ONE)
		draw_rect(Rect2(-4, -7, 8, 14), Color("#2f363e"))
		draw_line(Vector2(-4, -6.5), Vector2(4, -6.5), STEEL_LIT, 1.0)
		draw_rect(Rect2(-2, -4, 4, 1), STEEL_DARK)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _stencil(text: String, at: Vector2) -> void:
	# Typeset at 4x and scaled down so it stays crisp under the camera zoom (6.4 px cap height).
	draw_set_transform(at, 0.0, Vector2(0.25, 0.25))
	draw_string(_font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, STENCIL)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _glow(at: Vector2, radius: float, color: Color) -> void:
	for i: int in range(4):
		var f: float = 1.0 - i * 0.25
		draw_circle(at, radius * f, Color(color, color.a * 0.35))
