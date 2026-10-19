class_name DoorKit
extends RefCounted
## What every doorway shares (the whole-piece doors approved by Nathanial on 2026-10-16; their design is
## the one door language of the art set's doors/DESIGN.md): one copy of how a door's painted pieces are
## placed and lit, and of the lights the game draws on them. Every player door is the same stack, back
## to front:
## - behind the mid plate (RoomDepth.behind): the lit next space ("-back"), the light through the hole
##   (hole_glow), the leaves that run inside the wall, then the cross-wall's face with its hole ("-wall");
## - in front of the mid plate, under the actors: the swing leaves, the rolling curtain and its hood,
##   the door light's halo (door_light) and, on the way forward only, the exit sign (Sign);
## - over the actors: the wall's near end ("-front") and its status lamp (Lamp).
## Users: Main's corridor seal, RecordsRoom's two doors and JunctionRoom's three. Units are world px
## (40 per metre at the walk line) unless a name says otherwise.

## World px per piece px of every projected door piece ("-back", "-wall", "-head", "-front"): they are
## painted at 2 px per world px (the art set's sheets D01 to D04, manifest density 2.0).
const PIECE_SCALE: float = 0.5
## The painted next spaces came out about a third darker than the design's target values, and the
## painted cross-wall faces about twice as bright, so the next space is lifted one step and the wall
## brought one step down (the art set's doors.py BEYOND_LIFT and WALL_LIFT, measured with its
## contrast-painted check): the space through a hole reads brighter than the wall round it.
const BEYOND_LIFT: float = 1.35
const WALL_LIFT: float = 0.72
## A door leaf's tone against the painted cross-walls round it: one step under its art, in the walls'
## blue-grey cast (the art set's doors.py SWING_TINT 196, 214, 230 at SWING_LIFT 0.8): at full value an
## open leaf read as a grey cabinet and a shut sliding leaf as a lit, open doorway. SwingLeaf and the
## Junction exit's SlideLeaf take it.
const LEAF_TONE: Color = Color(0.615, 0.671, 0.722)
## The status lamp's live glass on a front piece's painted guard and base (doors.py socket_parts: a
## 5.2 x 6.6 world px guard round a lens about this radius), and its halo.
const LENS_RADIUS: float = 1.7
const LENS_HALO: Vector2 = Vector2(18.0, 18.0)
const LENS_HALO_ALPHA: float = 0.45
## A badge reader's LED (an 80 x 130 mm reader at 1.1 m, its LED a few mm across): its radius.
const READER_LED_RADIUS: float = 0.7
## The next space seen past a cross-wall's near end (beside the column, not through the hole) is painted
## as lit as the space through the doorway, so beside the doorway it read as a brighter way round the
## door (capture review of 2026-10-18, the Records exit). It is multiplied down this far (shade), so the
## doorway is the brightest opening in the wall: away from the door light and the hole the passage
## falls darker (est., tuned on rendered captures).
const PAST_END_SHADE: Color = Color(0.5, 0.53, 0.56)
## A wall's cut curb across the deck painted lighter than the deck round it read as a loose plank
## lying there (the corridor seal's); multiplied down this far it reads as the wall's cut concrete
## (est., tuned on rendered captures).
const CURB_SHADE: Color = Color(0.62, 0.64, 0.67)
## The darkest a blown doorway's soot gets (compose.py soot at strength 0.7, a little warm).
const SOOT_DARK: Color = Color(0.335, 0.3, 0.265)
## The door light's lens over every head is a cool-white LED wall pack (doors.py WHITE), its halo this
## big (compose.py's 2 world px glow at full strength).
const DOOR_LIGHT_COLOR: Color = Color8(235, 238, 240)
const DOOR_LIGHT_SIZE: Vector2 = Vector2(9.0, 9.0)
const DOOR_LIGHT_ALPHA: float = 0.9
## A soft light of radius r in the art set's compose.py (a gaussian falling to nothing at about 2 r) is
## about as wide as one of RoomDepth.make_glow's radial glows this many times r across.
const GLOW_WIDTH_PER_RADIUS: float = 3.6
## The exit sign (ISO 7010 E001, lit safety green, no words): its dark steel housing, the rim's share of
## the housing's height round the lit face, the face's green, the running figure's white, and its glows
## (doors.py exit_sign_box: the face's own glow and a faint green spill on the wall round it).
const SIGN_HOUSING: Color = Color8(20, 24, 26)
const SIGN_RIM: float = 0.14
const EXIT_GREEN: Color = Color8(60, 200, 110)
const SIGN_FIGURE: Color = Color8(245, 250, 245)
const SIGN_FACE_GLOW: float = 0.35
const SIGN_SPILL_GLOW: float = 0.10


## A whole painted door piece: [param texture] drawn at PIECE_SCALE with its top-left at [param
## top_left] (world px, in [param parent]'s space; the piece's world box from the art set's doors.py
## piece_box plus its manifest offset), its light multiplied by [param lift] (BEYOND_LIFT, WALL_LIFT, or
## 1 as painted), added to [param parent] now (node order is draw order).
static func piece(parent: Node, texture: Texture2D, top_left: Vector2, piece_name: String, lift: float = 1.0) -> Sprite2D:
	var sprite: Sprite2D = RoomDepth.cut(texture, Rect2(Vector2.ZERO, texture.get_size()), PIECE_SCALE, piece_name, top_left)
	sprite.modulate = Color(lift, lift, lift)
	parent.add_child(sprite)
	return sprite


## A doorway's stack behind the mid plate, added to [param parent] (RoomDepth.behind) in draw order: the
## next space and the wall's thickness ([param back] at [param back_at], lifted [param back_lift]; null
## where the room's far plate is what the hole shows), the light through the hole over them ([param
## hole], [param hole_color]: hole_light), [param inner] (a leaf running inside the wall, or null), the door light's
## pool on the threshold ([param pool]) and its graze on the far reveal ([param graze]) (doors.py
## surface_lights: radius 5 squashed 0.3 at 0.3, radius 2.5 stretched 3 at 0.15), then the cross-wall's
## face ([param wall] at [param wall_at], at WALL_LIFT), which it returns. Names start with [param
## door_name]. [param hole_head_share] is hole_light's head_share.
static func doorway(parent: Node, door_name: String, hole: PackedVector2Array, hole_color: Color, back: Texture2D, back_at: Vector2, back_lift: float, inner: Node2D, pool: Vector2, graze: Vector2, wall: Texture2D, wall_at: Vector2, hole_head_share: float = 1.0) -> Sprite2D:
	if back != null:
		piece(parent, back, back_at, door_name + "Back", back_lift)
	hole_light(parent, door_name + "HoleLight", hole, hole_color, hole_head_share)
	if inner != null:
		parent.add_child(inner)
	glow(parent, door_name + "Pool", pool, 5.0, DOOR_LIGHT_COLOR, 0.3, 0.3)
	glow(parent, door_name + "Graze", graze, 2.5, DOOR_LIGHT_COLOR, 0.15, 3.0)
	return piece(parent, wall, wall_at, door_name + "Wall", WALL_LIFT)


## An additive soft light of radius [param radius] (world px, compose.py's glow) at [param at], at
## [param alpha], squashed vertically by [param squash] (a pool on the floor), added to [param parent].
static func glow(parent: Node, glow_name: String, at: Vector2, radius: float, color: Color, alpha: float, squash: float = 1.0) -> Sprite2D:
	var sprite: Sprite2D = RoomDepth.make_glow(color, Vector2(radius, radius * squash) * GLOW_WIDTH_PER_RADIUS, alpha)
	sprite.name = glow_name
	sprite.position = at
	parent.add_child(sprite)
	return sprite


## Light added inside a doorway's hole (the polygon [param hole], world px: the opening on the wall's
## face from foot to head), drawn behind the wall's face piece so only what shows through the hole is
## lit: the next space reads brighter than the wall round it, the way out by light. The art set lifts
## the far plate's paint in the hole (doors.py lift_hole, FAR_LIFT 2.2); the game cannot multiply a
## parallax layer's pixels, so it adds [param color] over them instead, tuned on rendered captures.
## [param head_share] (0..1) fades it toward the head: a hole whose light is flat from foot to head reads as
## a pale pane of glass (the corridor seal's), so its light falls off upward from the lit floor. It needs
## the hole's points in the order every hole constant gives them: the two feet, then the two heads.
static func hole_light(parent: Node, light_name: String, hole: PackedVector2Array, color: Color, head_share: float = 1.0) -> Polygon2D:
	var light: Polygon2D = Polygon2D.new()
	light.name = light_name
	light.polygon = hole
	light.color = color
	if head_share < 1.0:
		var head: Color = Color(color * head_share, color.a)
		light.color = Color.WHITE
		light.vertex_colors = PackedColorArray([color, color, head, head])
	light.material = FxKit.additive()
	parent.add_child(light)
	return light


## A shade multiplied into what is drawn under the polygon [param polygon] (world px), [param color]
## at full strength (white leaves it as it is, so a caller fades the shade by easing its colour to
## white: a multiply cannot be faded by alpha), added to [param parent]. [param head_share] (0..1) darkens
## it toward the head, as hole_light's fades a light: the head lets through that share of what the feet
## do (it needs the points in hole order, the two feet, then the two heads). Users: the Junction exit's
## reveal while it is shut, the blown blast doorway's far reveal falling into the head's shadow, the
## light-catching curbs and the passage seen past a wall's near end that must not outshine the doorway.
static func shade(parent: Node, shade_name: String, polygon: PackedVector2Array, color: Color, head_share: float = 1.0) -> Polygon2D:
	var patch: Polygon2D = Polygon2D.new()
	patch.name = shade_name
	patch.polygon = polygon
	patch.color = color
	if head_share < 1.0:
		var head: Color = Color(color * head_share, color.a)
		patch.color = Color.WHITE
		patch.vertex_colors = PackedColorArray([color, color, head, head])
	patch.material = FxKit.multiply()
	parent.add_child(patch)
	return patch


## Soot and heat tint on a wall round a blown doorway: a soft dark patch (radii [param radii], world
## px) multiplied into what is drawn under it (the art set's compose.py soot, a gaussian falloff
## leaning a little warm), at its centre SOOT_DARK. One shared texture and FxKit's multiply blend: a
## multiply cannot be faded by alpha, so every patch is as dark at its centre and a lighter one is
## made smaller.
static func soot(parent: Node, soot_name: String, at: Vector2, radii: Vector2) -> Sprite2D:
	var patch: Sprite2D = Sprite2D.new()
	patch.name = soot_name
	patch.texture = FxKit.radial(128, [0.0, 0.45, 1.0], [SOOT_DARK, SOOT_DARK.lerp(Color.WHITE, 0.6), Color.WHITE])
	patch.scale = radii * GLOW_WIDTH_PER_RADIUS / patch.texture.get_size()
	patch.position = at
	patch.material = FxKit.multiply()
	parent.add_child(patch)
	return patch


## The door light's halo on its painted wall pack's lens at [param at] (doors.py emitters: W(a1 + 0.27,
## H + 0.29, -0.05) of each door), added to [param parent].
static func door_light(parent: Node, at: Vector2) -> Sprite2D:
	var halo: Sprite2D = RoomDepth.make_glow(DOOR_LIGHT_COLOR, DOOR_LIGHT_SIZE, DOOR_LIGHT_ALPHA)
	halo.name = "DoorLight"
	halo.position = at
	parent.add_child(halo)
	return halo


## A status lamp's live glass at [param at], tinted [param color], added to [param parent]: red shut,
## amber while its door moves, green open (Palette.LAMP_SHUT, Palette.AMBER, Palette.LAMP_OPEN). A
## smaller [param radius] (world px) makes a badge reader's LED (READER_LED_RADIUS).
static func lamp(parent: Node, lamp_name: String, at: Vector2, color: Color, radius: float = LENS_RADIUS) -> Lamp:
	var node: Lamp = Lamp.new(radius)
	node.name = lamp_name
	node.position = at
	node.color = color
	parent.add_child(node)
	return node


## An exit sign in the world box [param box] (its housing: doors.py sign_at's flag sign, standing square
## to the camera over the head of a forward exit), its figure running toward [param facing] (1 right,
## -1 left), added to [param parent]. Always lit (Nathanial's default: signs on the way forward only,
## always on).
static func exit_sign(parent: Node, box: Rect2, facing: float) -> Sign:
	var node: Sign = Sign.new()
	node.name = "ExitSign"
	node.position = box.position
	node.size = box.size
	node.facing = facing
	parent.add_child(node)
	node.build_glows()
	return node


## A status lamp's glass: a lit disc of LENS_RADIUS over the front piece's painted guard and base, with
## a small additive halo, both in [member color].
class Lamp:
	extends Node2D
	var halo: Sprite2D
	## The glass's radius (world px); the halo grows with it.
	var radius: float = LENS_RADIUS
	var color: Color = Palette.LAMP_SHUT:
		set(value):
			color = value
			if halo != null:
				halo.modulate = Color(color, LENS_HALO_ALPHA)
			queue_redraw()

	func _init(glass_radius: float = LENS_RADIUS) -> void:
		radius = glass_radius
		halo = RoomDepth.make_glow(color, LENS_HALO * radius / LENS_RADIUS, LENS_HALO_ALPHA)
		halo.name = "Halo"
		add_child(halo)

	func _draw() -> void:
		draw_circle(Vector2.ZERO, radius, color.darkened(0.25))
		draw_circle(Vector2(-0.25, -0.25) * radius, radius * 0.55, color.lightened(0.35))


## The ISO 7010 E001 exit sign drawn in code (no words, so nothing painted can read wrong): the dark
## housing, its lit green face inset by the rim, the white running figure heading through a doorway
## toward [member facing], and the face's glow with a faint green spill on the wall (doors.py
## exit_sign_box, which the art set's review frames were drawn with). Local px: the housing's top-left
## is the origin.
class Sign:
	extends Node2D
	var size: Vector2 = Vector2.ZERO
	var facing: float = 1.0

	## The two additive glows over and round the face, children so they draw over the sign.
	func build_glows() -> void:
		var centre: Vector2 = size * 0.5
		var spill: float = maxf(size.x, size.y) * 2.2
		var face: float = maxf(size.x, size.y) * 0.9
		for pair: Array in [[spill, SIGN_SPILL_GLOW, "Spill"], [face, SIGN_FACE_GLOW, "Glow"]]:
			var light: Sprite2D = RoomDepth.make_glow(EXIT_GREEN, Vector2.ONE * float(pair[0]) * GLOW_WIDTH_PER_RADIUS, float(pair[1]))
			light.name = pair[2]
			light.position = centre
			add_child(light)

	## A point of the lit face at (u, v) in 0..1, mirrored for a sign facing left.
	func _face(u: float, v: float) -> Vector2:
		var rim: float = size.y * SIGN_RIM
		var u2: float = 0.5 + facing * (u - 0.5)
		return Vector2(rim + u2 * (size.x - rim * 2.0), rim + v * (size.y - rim * 2.0))

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), SIGN_HOUSING)
		var top_left: Vector2 = _face(0.0, 0.0)
		var bottom_right: Vector2 = _face(1.0, 1.0)
		draw_rect(Rect2(top_left.min(bottom_right), (bottom_right - top_left).abs()), EXIT_GREEN)
		var line: float = size.y * 0.06
		# the doorway the figure runs to, then its head, body, legs and arms (E001's pose)
		var door_a: Vector2 = _face(0.70, 0.15)
		var door_b: Vector2 = _face(0.88, 0.88)
		draw_rect(Rect2(door_a.min(door_b), (door_b - door_a).abs()), SIGN_FIGURE, false, line)
		draw_circle(_face(0.47, 0.22), size.y * 0.09, SIGN_FIGURE)
		for limb: Array in [[0.45, 0.35, 0.40, 0.62], [0.40, 0.62, 0.28, 0.86], [0.40, 0.62, 0.55, 0.86], [0.45, 0.38, 0.60, 0.52], [0.45, 0.38, 0.30, 0.48]]:
			draw_line(_face(limb[0], limb[1]), _face(limb[2], limb[3]), SIGN_FIGURE, line * 1.2)
