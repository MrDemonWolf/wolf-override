class_name GreyboxBay
extends Node2D
## P0-13, layout L1, SHAPES (opening-dock/shapes, 2026-10-14): the dock room left of the corridor, design C's
## standby dock, the cross-wall's cased opening into the corridor and the Director's exit, drawn as exact
## functional shapes, flat-shaded (no paint): textures rendered by opening-dock/shapes/tools from one geometry
## source (geometry.py; positions in DockShapesData). Design C local (lx, ly) sits at world (lx - 397,
## ly + 365). The lamps are live sockets tinted here. Light comes only from drawn fittings: each pool is an
## additive falloff around its own fitting, clipped to the surfaces it can reach (unchanged from round 4).
## Measurements: opening-dock/shapes/SHAPES.md; opening-design/DESIGN.md sections 1.1, 3 and 5.
## PAINT (opening-dock/paint, 2026-10-15): the dock itself (stand, reel, roof fitting, cabinet, bay frame and lock
## pilaster, guard lock, mesh leaves, connector and umbilical) is painted (DockPaintData) on the same rects; the
## dock lamp's lit states are painted overlays on the connector. The rest of the room stays flat shapes.
## PAINT FIX 1 (opening-dock DOCK.md, 2026-10-15): the bay wash fades out above its diffuser instead of stopping
## at a clip line; room light reaches the floor in front of the bay; docked WOLF shades the stand and plate under
## him; the torn lock's cable is dark, slack and leaves the backplate's side.

## Design C's local origin (its main-world (115, 365)) in L1.
const DC: Vector2 = Vector2(-397.0, 365.0)
## Design C's main-world x 0 in L1 (the leaves keep r1's main-world x: 33 shut-left .. 153 lead shut).
const BAY_O: float = -512.0
const FLOOR_Y: float = 440.0
const CEIL_Y: float = 158.0
## The room's left end (round 2: shortened from -750 to here, so the whole room fits one view). The end
## wall is 0.45 m like the cross-wall: its cut, then its room-side face receding to the back wall. Round 4:
## no door in it any more (the Director's exit moved to the back wall, beside his last mark).
const END_CUT: Vector2 = Vector2(-644.0, -626.0)
## Round 4 (review-real-3 M2, S3; Nathanial 2026-10-14): the Director's exit is a 0.9 x 2.1 m personnel
## door in the room's back wall, about 1 m left of his last mark: leaf, hollow-metal frame (2 in jambs) clear of
## every cut and of the lock pilaster (16 px of wall between them), hinged on its left, swinging away
## from the room (he pushes it open, a closer pulls it shut), a badge reader on its latch side, a white
## door light over it. Behind it, a real passage.
const EXIT_LEAF: Vector2 = Vector2(-280.0, -244.0)
const EXIT_FRAME: Vector2 = Vector2(-283.0, -241.0)
## The leaf swings to this angle (degrees) when fully open.
const EXIT_OPEN_DEG: float = 80.0
## The cross-wall (0.45 m): its bay-side face (far jamb), the cased opening, its cut end (near column).
const FACE_BAND: Vector2 = Vector2(-80.0, -58.0)
const OPENING: Vector2 = Vector2(-58.0, -10.0)
const NEAR_COLUMN: Vector2 = Vector2(-10.0, 8.0)
const LINTEL: Vector2 = Vector2(334.0, 344.0)
## The corridor's bulkhead fitting (round 3, review-real-2 S6): wall-mounted on the clear patch of the
## corridor's back wall between the overhead pipe run (underside y 256) and the tank's lid (y 333),
## just right of the cut; its conduit runs up the wall face to the pipe run.
const BULKHEAD: Rect2 = Rect2(12.0, 300.0, 14.0, 7.0)
## Round 4 (Nathanial 2026-10-14, decision 7): the corridor's lockdown beacon that switches on with "Lock
## down maintenance", on the corridor's back wall where the doorway's view reaches it: the clear wall
## right of the painted elbow pipe and above the tank's lid, left of the purge display. Main's corridor
## beacons' shapes (a dark housing on a short bracket, a red lens), fed by a conduit up to the pipe rack.
const LOCKDOWN_BEACON: Vector2 = Vector2(74.0, 282.0)
const LOCKDOWN_LENS: Color = Color("#ff4a46")
const LOCKDOWN_LENS_OFF: Color = Color("#3a1d1c")
## Its glow on the corridor wall pulses like main's corridor beacons (RoomDepth.BEACON_ALPHA, 1.3 s).
const LOCKDOWN_GLOW: Color = Color(0.40, 0.05, 0.04)
const LOCKDOWN_PULSE_S: float = 1.3
## The bay's "door forced" beacon on the room's back wall above the lock pilaster.
const BEACON: Vector2 = Vector2(-305.0, 300.0)
## The room's two stem-hung general fittings (their stems, canopies and fittings are the pendant pieces).
const PENDANTS: Array[float] = [-250.0, -527.0]
const PENDANT_Y: float = 250.0
## The bay's footprint: room light stops at its steel. Fix 1 (review-real-1 S2): the frame's outer faces (post
## -485, pilaster -299, head beam 328) down to the floor line only; the floor in front of the bay is the room's,
## grounded by the frame's own contact shadow (it ran to y 446 and left a hard dark strip on the floor).
const BAY_RECT: Rect2 = Rect2(-485.0, 328.0, 186.0, 112.0)
## Fix 1 (review-real-1 M4): the bay's roof fitting's diffuser plane (shapes: its emitter's underside) and the
## bay's roof (the back plate's top). The wash fades out above the diffuser over a few px, never at a clip line.
const BAY_DIFFUSER_Y: float = 352.6
const BAY_ROOF_Y: float = 344.0
const BAY_WASH_FADE: float = 5.0
## The leading leaf's main-world x shut and against the stop in the top track.
const LEAD_CLOSED: float = 153.0
const LEAD_OPEN: float = 33.0
const LEAF_W: float = 44.0
## Each leaf's open stop (main-world x): the fixed left leaf, two picked up and stacked a stile apart
## behind the left post, and the leading leaf. The stack's right edge stays at the lead's 77 (world -435).
const LEAF_OPEN: Array[float] = [33.0, 27.0, 30.0, 33.0]
## Where the leading leaf catches each intermediate leaf (main-world x of the lead): leaf 2 at 116,
## leaf 1 at 79 (closed x + the stop's offset from the lead's).
const PICKUP_2: float = 113.0 + 33.0 - 30.0
const PICKUP_1: float = 73.0 + 33.0 - 27.0
## The torn guard lock hangs by its cable from its gland (its top right corner): it drops, swings and
## settles with the gland straight above its centre of mass (8 x 14 px body: about 30 degrees).
const LOCK_GLAND_MOUNT: Vector2 = Vector2(88.0, 27.0)
const LOCK_GLAND_HUNG: Vector2 = Vector2(86.5, 45.0)
const LOCK_DROP_S: float = 0.14
const LOCK_SWING_S: float = 1.6
## The connector rides WOLF's back here while docked; the reel winds it up until its ball stop seats against
## the roller guide (shapes: the reel's guide is at y 361, so the connector's centre stops at 370).
const CONNECTOR_DOCKED: Vector2 = Vector2(-380.0, 391.0)
const CONNECTOR_WOUND: Vector2 = Vector2(-380.0, 370.0)
const CONNECTOR_DROP_S: float = 0.12
const CONNECTOR_REEL_S: float = 0.5
## Shapes: the reel's roller guide, where the umbilical leaves it (the cable hangs from here).
const REEL_GUIDE: Vector2 = Vector2(-380.0, 361.0)
## Shapes: the dock beacon's lens (142 mm rotating mirror beacon): its rect, the dome over its top 1.3 px.
const BEACON_LENS: Rect2 = Rect2(-307.6, 295.3, 5.2, 6.3)
## Shapes: the lock's cable leaves the backplate's side through its gland here (fix 2: the gland nub at x -309.6
## .. -309); the status lamp's lens centre.
const LOCK_CABLE_ENTRY: Vector2 = Vector2(-309.6, 394.0)
const STATUS_LAMP: Vector2 = Vector2(-305.0, 383.3)
## Shapes: the closer's arm, the swung leaf's lit edge, the lock's cable.
const C_ARM: Color = Color("#5a5a5a")
const C_LEAF_EDGE: Color = Color("#636363")
## Fix 1 (review-real-1 M1): the lock's 8 mm black PUR cable (OKLab L 0.18), so the torn lock visibly hangs by it.
const C_LOCK_CABLE: Color = Color("#161718")
const LOCK_CABLE_W: float = 0.6
## Fix 2 (review-tells-2, noted): the cable's lit edge toward the bay's fitting (about +0.05 L).
const C_LOCK_CABLE_LIT: Color = Color("#24272a")
const LOCK_CABLE_LIT_W: float = 0.2
## Fix 1 (review-real-1 S3): docked WOLF's shade on the stand and the plate under his body (soft, about -0.1 L).
const OCCUPANT_SHADE: float = 0.26
const OCCUPANT_SHADE_AT: Vector2 = Vector2(8.0, 0.0)
const OCCUPANT_SHADE_R: Vector2 = Vector2(30.0, 9.0)
const OCCUPANT_SHADE_Y: float = 422.0

const LAMP_OFF: Color = Color("#202020")
const LAMP_GREEN: Color = Color("#3fd06a")
const LAMP_RED: Color = Color("#e83a2e")
const LAMP_RED_OFF: Color = Color("#3a1714")
# Light from each fitting (additive peak at the fitting; falls off as exp(-(d/r)^2)).
const BAY_WASH: Color = Color(0.17, 0.17, 0.17)
const ROOM_POOL: Color = Color(0.11, 0.11, 0.11)
## Round 3 (review-real-2 S10): the floor right under each room fitting is lit more than the wall.
const ROOM_FLOOR_POOL: Color = Color(0.07, 0.07, 0.07)
const CORRIDOR_POOL: Color = Color(0.62, 0.64, 0.67)
const BEACON_POOL: Color = Color(0.30, 0.03, 0.02)
## Round 3 (review-real-2 M1, S1): the beacon's turning light across the dock room, clipped to the room's
## own surfaces. It replaces the full-screen red wash, so nothing red reaches the corridor.
const BEACON_ROOM: Color = Color(0.05, 0.006, 0.004)
## Round 3 (review-real-2 S2): the corridor fitting's light through the opening onto the dock floor,
## and its bounce on the far jamb's face.
const SPILL: Color = Color(0.15, 0.16, 0.17)
const JAMB_BOUNCE: Color = Color(0.06, 0.065, 0.07)
## Round 3 (review-real-2 S9): the exit door's lamp is a white door light (the beacon is the one red).
const DOOR_LIGHT: Color = Color(0.10, 0.10, 0.10)
## Round 4 (review-real-3 S2): the dock beacon's turning beam. Its reflector turns once a second; the beam
## grazes the back wall to the left and to the right of the beacon in turn (one lobe each side, in phase
## with the reflector band on the lens) and sweeps the floor while it faces the room.
const BEACON_TURN_S: float = 1.0
const BEACON_LOBE: Color = Color(0.22, 0.02, 0.015)
const BEACON_FLOOR: Color = Color(0.10, 0.012, 0.008)

enum Dock { AMBER, BLUE, OFF }
## Round 3 (review-real-2 S9, one red per view): the lock's indicator is fed through the lock's own
## cable, so it goes dark when the lock is torn off; the beacon alone carries "door forced".
enum Status { GREEN, RED_FLASH, RED_STEADY, OFF }

var dock_lamp: int = Dock.AMBER
## 0 amber .. 1 blue while the wake eases (amber to blue over 0.45 s).
var wake: float = 0.0
var status_lamp: int = Status.GREEN
var lock_torn: bool = false
## Seconds since the lock tore off (it drops and swings on its cable), or -1 while it is on its mount.
var lock_age: float = -1.0
## Contact shadows under the actors on the dock room's floor: [Vector3(x, feet y, half width)].
var shadow_casters: Array[Vector3] = []
## Fix 1: WOLF's x while he stands docked in the bay (he shades the stand under him), or none.
var occupant: bool = false
var occupant_x: float = 0.0
var _shade: GradientTexture2D
## The breakaway connector: true while it rides WOLF's back.
var umbilical_attached: bool = true
## Seconds since the connector let go (it drops, swings and is wound up), or -1 while attached.
var connector_age: float = -1.0
## The leading leaf's main-world x (LEAD_CLOSED .. LEAD_OPEN); the others are picked up as it passes.
var lead_x: float = LEAD_CLOSED
## The bay's "door forced" beacon (on from the tear until the cut) and its turn.
var beacon_on: bool = false
var beacon_phase: float = 0.0
var reduce_motion: bool = false
## Round 4: the Director's exit door, 0 shut .. 1 open (EXIT_OPEN_DEG), and its badge reader's LED
## (0 dim .. 1 green, accepted).
var exit_open: float = 0.0
var reader_ok: float = 0.0
## Round 4: the corridor's lockdown beacon (off until "Lock down maintenance"; settled with the corridor's
## own beacons once the route is cleared) and its pulse clock.
var lockdown_on: bool = false
var lockdown_settled: bool = false
var lockdown_phase: float = 0.0
## 0 while the camera is in the dock room (the opening shows the corridor beyond), 1 once it is in the
## corridor (the opening shows the dock room): the space behind the hole is the room on its far side.
var view_side: float = 0.0
## The corridor's depth plates (RoomDepth): the opening shows its back wall.
var corridor_depth: Node2D
var _flash_time: float = 0.0
var _pool: GradientTexture2D
## Shaped pools for fittings that throw most of their light down: [texture, rx, up, down].
var _bulkhead_pool: Array = []
var _pendant_pool: Array = []
var _door_pool: Array = []
## Shapes: the pieces' textures by name (DockShapesData.PIECES).
var _tex: Dictionary = {}

var back: Node2D
var light: Node2D
var shadows: Node2D
var cable: Node2D
var leaves: Node2D
var front: Node2D
var over: Node2D


func _ready() -> void:
	z_as_relative = false
	_pool = _make_pool_texture()
	_shade = _make_pool_texture(true)
	_bulkhead_pool = _make_shaped_pool(95.0, 30.0, 175.0)
	_pendant_pool = _make_shaped_pool(130.0, 45.0, 190.0)
	_door_pool = _make_shaped_pool(16.0, 6.0, 48.0)
	for piece_name: String in DockShapesData.PIECES:
		var dir: String = DockPaintData.DIR if piece_name in DockPaintData.PIECES else DockShapesData.DIR
		_tex[piece_name] = load(dir + piece_name + ".png") as Texture2D
	for lamp_name: String in [DockPaintData.LAMP_AMBER, DockPaintData.LAMP_BLUE, DockPaintData.LEAF_STACKED]:
		_tex[lamp_name] = load(DockPaintData.DIR + lamp_name + ".png") as Texture2D
	back = _layer("Back", -2, _draw_back)
	light = _layer("Light", -1, _draw_light)
	light.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var add: CanvasItemMaterial = CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	light.material = add
	# Contact shadows on the floor: over the floor and its light, under every actor (z 2 and up).
	shadows = _layer("Shadows", 1, _draw_shadows)
	# The umbilical hangs inside the bay: over WOLF (same z, drawn after him), under the mesh leaves.
	cable = _layer("Cable", 2, _draw_cable)
	leaves = _layer("Leaves", 3, _draw_leaves)
	front = _layer("Front", 4, _draw_front)
	over = _layer("Over", 6, _draw_over)
	# The pieces are drawn at 4 texels per world px (the shell at 2): minified with mipmaps, so the mesh's
	# 5 mm wire reads as a fine tone, not a shimmer.
	for layer: Node2D in [back, shadows, cable, leaves, front, over]:
		layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func _layer(layer_name: String, z: int, painter: Callable) -> Node2D:
	var layer: Node2D = Node2D.new()
	layer.name = layer_name
	layer.z_as_relative = false
	layer.z_index = z
	layer.draw.connect(painter.bind(layer))
	add_child(layer)
	return layer


static func _make_pool_texture(shade: bool = false) -> GradientTexture2D:
	var gradient: Gradient = Gradient.new()
	# exp(-(2r)^2) for r = 0 .. 1 of the texture's radius: the fitting's "r" is half the texture radius.
	var offsets: PackedFloat32Array = PackedFloat32Array()
	var colors: PackedColorArray = PackedColorArray()
	for i: int in 9:
		var r: float = i / 8.0
		var v: float = exp(-4.0 * r * r) if i < 8 else 0.0
		offsets.append(r)
		colors.append(Color(0.0, 0.0, 0.0, v) if shade else Color(v, v, v))
	gradient.offsets = offsets
	gradient.colors = colors
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	return texture


## A pool that falls off as exp(-(dx/rx)^2 - (dy/ry)^2) with ry = [param up] above the fitting and
## [param down] below it (a fitting under a hood throws little light upward).
static func _make_shaped_pool(rx: float, up: float, down: float) -> Array:
	var w: int = 64
	var h: int = 112
	var image: Image = Image.create(w, h, false, Image.FORMAT_RGB8)
	var total_h: float = 2.0 * up + 2.0 * down
	for py: int in h:
		var dy: float = (py + 0.5) / h * total_h - 2.0 * up
		var ry: float = up if dy < 0.0 else down
		for px: int in w:
			var dx: float = ((px + 0.5) / w - 0.5) * 4.0 * rx
			var v: float = exp(-(dx * dx) / (rx * rx) - (dy * dy) / (ry * ry))
			image.set_pixel(px, py, Color(v, v, v))
	return [ImageTexture.create_from_image(image), rx, up, down]


func _process(delta: float) -> void:
	if status_lamp == Status.RED_FLASH:
		var was_on: bool = fmod(_flash_time, 0.5) < 0.25
		_flash_time += delta
		if was_on != (fmod(_flash_time, 0.5) < 0.25):
			front.queue_redraw()
	if beacon_on and not reduce_motion:
		beacon_phase = fmod(beacon_phase + delta / BEACON_TURN_S, 1.0)
		back.queue_redraw()
		light.queue_redraw()
	if lockdown_on and not lockdown_settled and not reduce_motion:
		lockdown_phase = fmod(lockdown_phase + delta / (2.0 * LOCKDOWN_PULSE_S), 1.0)
		light.queue_redraw()
	if connector_age >= 0.0 and connector_age < CONNECTOR_DROP_S + CONNECTOR_REEL_S:
		connector_age += delta
		cable.queue_redraw()
	if lock_age >= 0.0 and lock_age < LOCK_SWING_S:
		lock_age += delta
		front.queue_redraw()
	var camera: Camera2D = get_viewport().get_camera_2d() if is_inside_tree() else null
	if camera != null:
		var side: float = smoothstep(-150.0, 150.0, camera.get_screen_center_position().x)
		if absf(side - view_side) > 0.002:
			view_side = side
			back.queue_redraw()
			light.queue_redraw()


func refresh() -> void:
	for layer: Node2D in [back, light, shadows, cable, leaves, front, over]:
		layer.queue_redraw()


## Main hands over the actors' feet each frame (only those on the dock room's floor cast one here).
func set_shadows(casters: Array[Vector3]) -> void:
	if casters == shadow_casters:
		return
	shadow_casters = casters
	shadows.queue_redraw()


## Fix 1: docked WOLF's x (he shades the stand under him), or [param inside] false once he has left the bay.
func set_occupant(inside: bool, x: float = 0.0) -> void:
	if inside == occupant and (not inside or absf(x - occupant_x) < 0.05):
		return
	occupant = inside
	occupant_x = x
	shadows.queue_redraw()


## The lock tears off its mount: it drops onto its cable and swings.
func tear_lock() -> void:
	lock_torn = true
	lock_age = 0.0
	status_lamp = Status.OFF
	refresh()


## The closed, dark dock of box 1.
func set_standby() -> void:
	# WOLF is inside the bay: its front (frame, lock), leaves and umbilical draw over him.
	front.z_index = 4
	leaves.z_index = 3
	cable.z_index = 2
	dock_lamp = Dock.AMBER
	wake = 0.0
	status_lamp = Status.GREEN
	lock_torn = false
	lock_age = -1.0
	umbilical_attached = true
	connector_age = -1.0
	lead_x = LEAD_CLOSED
	beacon_on = false
	beacon_phase = 0.0
	_flash_time = 0.0
	exit_open = 0.0
	reader_ok = 0.0
	# The corridor's lockdown is not ordered yet.
	lockdown_on = false
	lockdown_settled = false
	lockdown_phase = 0.0
	refresh()


## After the cut and on load (Q-D, Q-E): opened, empty and quiet; the alarm silenced, the lock's
## indicator dark with the lock torn off (round 3), the lock hanging still.
func set_empty_quiet() -> void:
	# The bay stands against the back wall: anyone walking the room passes in front of it.
	front.z_index = 1
	leaves.z_index = 1
	cable.z_index = 1
	dock_lamp = Dock.OFF
	wake = 1.0
	status_lamp = Status.OFF
	lock_torn = true
	lock_age = LOCK_SWING_S
	umbilical_attached = false
	connector_age = CONNECTOR_DROP_S + CONNECTOR_REEL_S
	lead_x = LEAD_OPEN
	beacon_on = false
	# The Director has gone through his door; its closer has shut it. The corridor stays locked down.
	exit_open = 0.0
	reader_ok = 0.0
	lockdown_on = true
	refresh()


## Round 4: the corridor's lockdown beacon switches on (box 7) or settles once the route is cleared.
func set_lockdown(on: bool, settled: bool = false) -> void:
	if on == lockdown_on and settled == lockdown_settled:
		return
	lockdown_on = on
	lockdown_settled = settled
	refresh()


## Round 4: the exit door's leaf (0 shut .. 1 open) and its reader's LED.
func set_exit(open: float, reader: float) -> void:
	if open == exit_open and reader == reader_ok:
		return
	exit_open = open
	reader_ok = reader
	back.queue_redraw()
	light.queue_redraw()


func set_wake(value: float) -> void:
	wake = value
	# The dock lamp is on the connector: once the contacts have parted it stays off.
	if umbilical_attached:
		dock_lamp = Dock.BLUE if value >= 1.0 else Dock.AMBER
	refresh()


func set_lead_x(value: float) -> void:
	lead_x = value
	leaves.queue_redraw()


## The breakaway connector parts as WOLF first moves: the contacts open (dock lamp off), it drops and
## swings on its cable, and the spring reel winds it up.
func release_connector() -> void:
	if not umbilical_attached:
		return
	umbilical_attached = false
	dock_lamp = Dock.OFF
	connector_age = 0.0
	refresh()


func set_beacon(on: bool) -> void:
	beacon_on = on
	refresh()


## Where the connector hangs [param age] seconds after it let go.
static func connector_at(age: float) -> Vector2:
	if age < 0.0:
		return CONNECTOR_DOCKED
	var swing: float = 2.5 * sin(TAU * age / 0.35) * exp(-4.0 * age)
	if age < CONNECTOR_DROP_S:
		var u: float = age / CONNECTOR_DROP_S
		return CONNECTOR_DOCKED + Vector2(swing, 6.0 * u * u)
	var v: float = clampf((age - CONNECTOR_DROP_S) / CONNECTOR_REEL_S, 0.0, 1.0)
	var y: float = lerpf(CONNECTOR_DOCKED.y + 6.0, CONNECTOR_WOUND.y, smoothstep(0.0, 1.0, v))
	return Vector2(CONNECTOR_DOCKED.x + swing, y)


## The torn lock [param age] seconds after the tear, in design C's local coordinates: its gland (top
## right corner, where the cable enters) and the body's rotation about it, in radians. It drops onto its
## cable, then swings about the gland and settles with its centre of mass straight below it.
static func lock_pose(age: float) -> Array:
	if age < 0.0:
		return [LOCK_GLAND_MOUNT, 0.0]
	var rest: float = atan2(-4.0, 7.0)
	var u: float = clampf(age / LOCK_DROP_S, 0.0, 1.0)
	var gland: Vector2 = LOCK_GLAND_MOUNT.lerp(LOCK_GLAND_HUNG, u * u)
	# Mounted it stood upright (0); it swings past its rest angle and back, dying away.
	var swing: float = -rest * exp(-3.2 * age) * cos(TAU * age / 0.62)
	return [gland, rest + swing]


## The leaves' main-world x per leaf for the leading leaf at [param lead].
static func leaf_xs(lead: float) -> Array[float]:
	var xs: Array[float] = []
	for i: int in 4:
		var closed: float = 33.0 + 40.0 * i
		if i == 0:
			xs.append(closed)
			continue
		# Picked up by the lead's pickup lug once it has come within (33 - stop) of the leaf's own stop.
		var k: float = LEAD_OPEN - LEAF_OPEN[i]
		xs.append(clampf(lead - k, LEAF_OPEN[i], closed))
	return xs


## World x of the open stack's right edge (the leading leaf's leading stile when open).
static func stack_right() -> float:
	return BAY_O + LEAD_OPEN + LEAF_W


static func _r(layer: Node2D, x0: float, y0: float, x1: float, y1: float, color: Color) -> void:
	layer.draw_rect(Rect2(x0, y0, x1 - x0, y1 - y0), color)


static func _ellipse(layer: Node2D, centre: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 16:
		var a: float = TAU * i / 16.0
		points.append(centre + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	layer.draw_colored_polygon(points, color)


## Shapes (P0-13, opening-dock/shapes): one flat-shaded piece of the dock room, drawn into its own rect.
func _piece(layer: Node2D, piece_name: String, modulate_color: Color = Color.WHITE) -> void:
	layer.draw_texture_rect(_tex[piece_name], DockShapesData.PIECES[piece_name], false, modulate_color)


## A piece drawn into [param rect] instead of its own (a moving part).
func _piece_in(layer: Node2D, piece_name: String, rect: Rect2, modulate_color: Color = Color.WHITE) -> void:
	layer.draw_texture_rect(_tex[piece_name], rect, false, modulate_color)


## One fitting's pool: centre [param at], falloff radius [param radius] (the light is exp(-(d/r)^2)),
## drawn only inside [param clips].
func _pool_in(layer: Node2D, at: Vector2, radius: Vector2, color: Color, clips: Array[Rect2]) -> void:
	var full: Rect2 = Rect2(at - radius * 2.0, radius * 4.0)
	var size: Vector2 = Vector2(_pool.width, _pool.height)
	for clip: Rect2 in clips:
		var part: Rect2 = full.intersection(clip)
		if not part.has_area():
			continue
		var src: Rect2 = Rect2((part.position - full.position) / full.size * size, part.size / full.size * size)
		layer.draw_texture_rect_region(_pool, part, src, color)


func _shaped_in(layer: Node2D, pool: Array, at: Vector2, color: Color, clips: Array[Rect2]) -> void:
	var texture: Texture2D = pool[0]
	var rx: float = pool[1]
	var up: float = pool[2]
	var down: float = pool[3]
	var full: Rect2 = Rect2(at.x - 2.0 * rx, at.y - 2.0 * up, 4.0 * rx, 2.0 * up + 2.0 * down)
	var size: Vector2 = texture.get_size()
	for clip: Rect2 in clips:
		var part: Rect2 = full.intersection(clip)
		if not part.has_area():
			continue
		var src: Rect2 = Rect2((part.position - full.position) / full.size * size, part.size / full.size * size)
		layer.draw_texture_rect_region(texture, part, src, color)


## The beacon's lens level, 0..1: brightest while its reflector faces the room; steady with Reduced Motion.
func _beacon_level() -> float:
	if not beacon_on:
		return 0.0
	if reduce_motion:
		return 0.75
	return 0.55 + 0.45 * maxf(cos(TAU * beacon_phase), 0.0)


## Round 4 (review-real-3 S2): where the turning beam points, as its angle about the beacon's vertical
## axis (0 = facing the room and the camera, PI/2 = along the wall to the right).
func _beam_angle() -> float:
	return TAU * beacon_phase


## The room's wall and floor that a room fitting can reach: everything but the bay's steel and the
## cross-wall, from [param left] (world x).
static func _room_surfaces(left: float) -> Array[Rect2]:
	# Down the whole floor toward the camera (round 3: a clip at y 470 showed as a hard line).
	var bottom: float = FLOOR_Y + 180.0
	return [
		Rect2(left, CEIL_Y, BAY_RECT.position.x - left, bottom - CEIL_Y),
		Rect2(BAY_RECT.end.x, CEIL_Y, FACE_BAND.x - BAY_RECT.end.x, FLOOR_Y - CEIL_Y),
		Rect2(BAY_RECT.position.x, CEIL_Y, BAY_RECT.size.x, BAY_RECT.position.y - CEIL_Y),
		Rect2(BAY_RECT.position.x, BAY_RECT.end.y, BAY_RECT.size.x, bottom - BAY_RECT.end.y),
		Rect2(BAY_RECT.end.x, FLOOR_Y, OPENING.y - BAY_RECT.end.x, bottom - FLOOR_Y),
	]


## Shapes: the back layer. What is behind the two holes first (the passage and the Director's leaf; the
## space the doorway shows), then the shell, which is alpha 0 in both holes, then the fixtures, then the
## live lamp sockets.
func _draw_back(layer: Node2D) -> void:
	_draw_exit(layer)
	# From the dock room the doorway shows the corridor's back wall; from the corridor, the dock room's wall.
	_piece(layer, "hole_corridor")
	if view_side > 0.0:
		_piece(layer, "hole_dock", Color(1.0, 1.0, 1.0, view_side))
	_piece(layer, "shell")
	for piece_name: String in ["doorway_trim", "tray", "pendant_0", "pendant_1", "exit_door", "beacon_mount", "corridor_fitting", "lockdown_beacon", "dock_back"]:
		_piece(layer, piece_name)
	# The closer's arm, from its shoe under the head to the closer body on the leaf's top rail.
	var k: float = cos(deg_to_rad(EXIT_OPEN_DEG) * exit_open)
	layer.draw_line(Vector2(EXIT_LEAF.x + 14.0 * k, 357.8), Vector2(-255.25, 356.9), C_ARM, 0.75)
	# The badge reader's LED: dim white, green on a badge, never red.
	_r(layer, -237.8, 395.2, -236.2, 395.8, Color("#8a8f8a").lerp(LAMP_GREEN, reader_ok))
	_draw_beacon_lens(layer)
	_r(layer, LOCKDOWN_BEACON.x - 5.0, LOCKDOWN_BEACON.y - 2.0, LOCKDOWN_BEACON.x + 5.0, LOCKDOWN_BEACON.y + 3.0, _lockdown_lens())


## The dock beacon's lens (a 142 mm rotating mirror beacon on its wall bracket): unlit red until the tear;
## lit, its reflector's band crosses the front while the beam faces the room (round 4, in phase with the beam).
func _draw_beacon_lens(layer: Node2D) -> void:
	var level: float = _beacon_level()
	if level <= 0.0:
		return
	var lens: Color = LAMP_RED_OFF.lerp(LAMP_RED, level)
	_r(layer, BEACON_LENS.position.x, BEACON_LENS.position.y + 1.3, BEACON_LENS.end.x, BEACON_LENS.end.y, lens)
	_ellipse(layer, Vector2(BEACON.x, BEACON_LENS.position.y + 1.3), Vector2(BEACON_LENS.size.x * 0.5, 1.3), lens)
	if beacon_on and not reduce_motion:
		var angle: float = _beam_angle()
		if cos(angle) > -0.2:
			var sweep: float = sin(angle) * 1.8
			_r(layer, BEACON.x + sweep - 0.7, BEACON_LENS.position.y + 0.6, BEACON.x + sweep + 0.7, BEACON_LENS.end.y - 0.6, LAMP_RED.lerp(Color.WHITE, 0.45 * maxf(cos(angle), 0.0)))


## Round 4 (review-real-3 M2, S3), shapes: the Director's exit. The leaf swings away from the room about its
## left (hinge) edge, so open it is seen foreshortened (cos) and darker as it turns from the door light, its
## 44.5 mm thickness lit at the free edge, and the passage behind shows. Shut, its undercut shows the passage
## floor. The frame, the door light and the reader are the static exit_door piece drawn over it.
func _draw_exit(layer: Node2D) -> void:
	var angle: float = deg_to_rad(EXIT_OPEN_DEG) * exit_open
	_piece(layer, "passage")
	var full: Rect2 = DockShapesData.PIECES["exit_leaf"]
	var w: float = full.size.x * cos(angle)
	var shade: float = 0.45 * sin(angle)
	_piece_in(layer, "exit_leaf", Rect2(full.position, Vector2(w, full.size.y)), Color(1.0 - shade, 1.0 - shade, 1.0 - shade))
	if exit_open > 0.0:
		_r(layer, full.position.x + w, full.position.y, full.position.x + w + maxf(1.8 * sin(angle), 0.5), full.end.y, C_LEAF_EDGE)


func _lockdown_level() -> float:
	if not lockdown_on:
		return 0.0
	if lockdown_settled:
		return 0.25
	if reduce_motion:
		return 0.8
	# Main's corridor beacons dim to 55% and recover, each half over LOCKDOWN_PULSE_S, eased.
	return 0.55 + 0.45 * (0.5 + 0.5 * cos(TAU * lockdown_phase))


func _lockdown_lens() -> Color:
	if not lockdown_on:
		return LOCKDOWN_LENS_OFF
	if lockdown_settled:
		return LOCKDOWN_LENS.darkened(0.55)
	return LOCKDOWN_LENS_OFF.lerp(LOCKDOWN_LENS, 0.6 + 0.4 * _lockdown_level())


func _draw_light(layer: Node2D) -> void:
	# The bay's roof fitting lights the bay's inside below it (design C's painted wash, as light).
	# Fix 1 (review-real-1 M4): full below the diffuser's plane; above it (the plate up to the bay's roof) the same
	# pool fading out over BAY_WASH_FADE px in thin strips, so no clip edge sits inside the lit area.
	var wash_at: Vector2 = DC + Vector2(-12.0, -8.0)
	var wash_r: Vector2 = Vector2(80.0, 65.0)
	_pool_in(layer, wash_at, wash_r, BAY_WASH, [Rect2(DC.x - 82.0, BAY_DIFFUSER_Y, 164.0, FLOOR_Y - BAY_DIFFUSER_Y)])
	var strip: float = 0.25
	var y: float = BAY_ROOF_Y
	while y < BAY_DIFFUSER_Y - 0.001:
		var h: float = minf(strip, BAY_DIFFUSER_Y - y)
		var k: float = exp(-pow((BAY_DIFFUSER_Y - (y + 0.5 * h)) / BAY_WASH_FADE, 2.0))
		_pool_in(layer, wash_at, wash_r, BAY_WASH * k, [Rect2(DC.x - 82.0, y, 164.0, h)])
		y += h
	# Fix 2 (review-tells-2 M1, review-human-2 S3): no pool on the plate from the dock lamp. It is a 75 mm
	# indicator facing the camera (the amber state threw none either); the lit window and its rim carry it.
	# The room's two stem-hung fittings light its wall and floor (not through the bay's steel), the floor
	# right under each one most (round 3, review-real-2 S10).
	var floor_band: Array[Rect2] = [Rect2(END_CUT.y, FLOOR_Y, OPENING.x - END_CUT.y, 60.0)]
	for x: float in PENDANTS:
		_shaped_in(layer, _pendant_pool, Vector2(x, PENDANT_Y + 4.0), ROOM_POOL, _room_surfaces(END_CUT.y))
		_pool_in(layer, Vector2(x, FLOOR_Y + 4.0), Vector2(46.0, 10.0), ROOM_FLOOR_POOL, floor_band)
	var level: float = _beacon_level()
	if level > 0.0:
		var walls: Array[Rect2] = _room_surfaces(END_CUT.y)
		_pool_in(layer, BEACON, Vector2(40.0, 40.0), BEACON_POOL * level * 0.7, walls)
		# Its light across the whole room, dim (never through the cross-wall; review-real-2 S1).
		_pool_in(layer, BEACON, Vector2(260.0, 190.0), BEACON_ROOM * level, walls)
		if not reduce_motion:
			# Round 4 (review-real-3 S2): the turning beam. Pointing along the wall it grazes it in a long
			# lobe on that side; pointing into the wall it lights a short patch behind the beacon; facing
			# the room it sweeps across the floor in front of the bay and the dock.
			var angle: float = _beam_angle()
			var along: float = sin(angle)
			var toward: float = cos(angle)
			var wall_weight: float = clampf(1.0 - toward, 0.0, 1.0)
			_pool_in(layer, BEACON + Vector2(85.0 * along, 8.0), Vector2(55.0 + 25.0 * absf(along), 42.0), BEACON_LOBE * wall_weight, walls)
			if toward > 0.0:
				var floor_rect: Array[Rect2] = [Rect2(END_CUT.y, FLOOR_Y, OPENING.y - END_CUT.y, 180.0)]
				_pool_in(layer, Vector2(BEACON.x + 160.0 * along, FLOOR_Y + 22.0), Vector2(70.0, 26.0), BEACON_FLOOR * toward, floor_rect)
		else:
			_pool_in(layer, BEACON, Vector2(70.0, 70.0), BEACON_POOL * 0.3, walls)
	# The white door light over the exit lights its leaf and the floor in front of it.
	var door_lamp: Vector2 = Vector2((EXIT_LEAF.x + EXIT_LEAF.y) * 0.5, 348.0)
	_shaped_in(layer, _door_pool, door_lamp, DOOR_LIGHT, [Rect2(EXIT_FRAME.x - 30.0, 340.0, EXIT_FRAME.y - EXIT_FRAME.x + 60.0, FLOOR_Y + 180.0 - 340.0)])
	# The corridor's bulkhead fitting: its pool on the corridor's back wall and floor, and on the same wall
	# seen through the opening (only while the opening shows the corridor).
	var source: Vector2 = Vector2(BULKHEAD.get_center().x, BULKHEAD.end.y)
	var corridor: Array[Rect2] = [Rect2(NEAR_COLUMN.y, 100.0, 170.0, FLOOR_Y + 180.0 - 100.0)]
	_shaped_in(layer, _bulkhead_pool, source, CORRIDOR_POOL, corridor)
	if view_side < 1.0:
		# Through the opening down to the corridor's floor line (the dock room's floor is not this light's).
		# Round 4: the wall seen through the opening is the corridor's back wall right beside the fitting
		# (corridor x 8-56), so it is lit as that wall is: evenly across, from the fitting's own height.
		# Round 3 lit it as if it stood at the hole's own x, 50-80 px from the fitting, which left its far
		# side dark behind the engineer.
		var hole: Array[Rect2] = [Rect2(OPENING.x, LINTEL.y, OPENING.y - OPENING.x, FLOOR_Y - LINTEL.y)]
		var seen_source: Vector2 = Vector2((OPENING.x + OPENING.y) * 0.5, source.y)
		_shaped_in(layer, _bulkhead_pool, seen_source, CORRIDOR_POOL * (1.0 - view_side), hole)
	# Round 4: the corridor's lockdown beacon's glow on its own wall (never into the dock room).
	var lockdown: float = _lockdown_level()
	if lockdown > 0.0:
		var corridor_wall: Array[Rect2] = [Rect2(NEAR_COLUMN.y, 100.0, 400.0, FLOOR_Y - 100.0)]
		_pool_in(layer, LOCKDOWN_BEACON, Vector2(30.0, 26.0), LOCKDOWN_GLOW * lockdown, corridor_wall)
	_draw_spill(layer)


## Round 3 (review-real-2 S2): the corridor fitting's light through the opening. On the dock floor a pale
## wedge from the opening's floor line, widening and fading into the room; on the far jamb's face a soft
## bounce, strongest at the opening and near the lit floor. It is light on the dock room's own surfaces,
## so it does not follow the camera.
func _draw_spill(layer: Node2D) -> void:
	var near: float = OPENING.y - 2.0
	var far: float = OPENING.x
	var lit: Color = SPILL
	var zero: Color = Color(0.0, 0.0, 0.0)
	# Full along the opening's floor line; fading to nothing toward the camera and into the room. The
	# edge at the near jamb (x -12) is the jamb's own shadow line.
	var a: Vector2 = Vector2(near, FLOOR_Y)
	var b: Vector2 = Vector2(far, FLOOR_Y)
	var c: Vector2 = Vector2(far - 118.0, FLOOR_Y)
	var d: Vector2 = Vector2(far - 80.0, FLOOR_Y + 36.0)
	var e: Vector2 = Vector2(near, FLOOR_Y + 30.0)
	for tri: Array in [[a, b, e, lit, lit, zero], [b, d, e, lit, zero, zero], [b, c, d, lit, zero, zero]]:
		layer.draw_polygon(PackedVector2Array([tri[0], tri[1], tri[2]]), PackedColorArray([tri[3], tri[4], tri[5]]))
	# The far jamb's face: a bounce fading away from the opening and up from the floor.
	var j0: float = FACE_BAND.x
	var j1: float = OPENING.x - 2.0
	var top: float = LINTEL.y + 20.0
	var lo: Color = JAMB_BOUNCE
	layer.draw_polygon(PackedVector2Array([Vector2(j1, top), Vector2(j1, FLOOR_Y), Vector2(j0, FLOOR_Y), Vector2(j0, top)]), PackedColorArray([zero, lo, zero, zero]))


## Shapes: the 75 mm umbilical from the reel's roller guide to the breakaway connector's ball stop (on
## WOLF's back, dropping and swinging, or wound up with the ball stop seated against the guide).
func _draw_cable(layer: Node2D) -> void:
	var at: Vector2 = connector_at(connector_age if not umbilical_attached else -1.0)
	var top: Vector2 = at + Vector2(0.0, -9.0)
	var run: Vector2 = top - REEL_GUIDE
	if run.y > 0.25:
		# The cable's one-px slice stretched along the run (a rotated rect: never a polygon to triangulate).
		layer.draw_set_transform(REEL_GUIDE, run.angle() - PI * 0.5, Vector2.ONE)
		layer.draw_texture_rect(_tex["umbilical"], Rect2(-1.5, 0.0, 3.0, run.length()), false)
		layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var c: Rect2 = DockShapesData.PIECES["connector"]
	var c_rect: Rect2 = Rect2(at + c.position, c.size)
	# Paint: the connector with its lamp off, then the painted lit lamp over it, amber easing to blue on the wake.
	_piece_in(layer, "connector", c_rect)
	if dock_lamp != Dock.OFF:
		if wake < 1.0:
			_piece_in(layer, DockPaintData.LAMP_AMBER, c_rect, Color(1.0, 1.0, 1.0, 1.0 - wake))
		if wake > 0.0:
			_piece_in(layer, DockPaintData.LAMP_BLUE, c_rect, Color(1.0, 1.0, 1.0, wake))


## Shapes: the four telescoping mesh leaves (the mesh is see-through, so the stack's stiles show through the
## lead's mesh on their own).
func _draw_leaves(layer: Node2D) -> void:
	var xs: Array[float] = leaf_xs(lead_x)
	var rect: Rect2 = DockShapesData.PIECES["leaf"]
	# Paint fix 2b (review-human-2 M1): once the lead is at its open stop, each leaf parked at its own stop sits
	# a whole number of mesh pitches behind the lead, so its mesh is hidden behind the lead's aligned mesh or a
	# stile. It is drawn without its mesh, so the four filtered meshes do not compound into heavy bars.
	var stacked: bool = is_equal_approx(xs[3], LEAF_OPEN[3])
	for i: int in 4:
		var piece_name: String = "leaf"
		if i == 3:
			piece_name = "leaf_lead"
		elif stacked and is_equal_approx(xs[i], LEAF_OPEN[i]):
			piece_name = DockPaintData.LEAF_STACKED
		_piece_in(layer, piece_name, Rect2(Vector2(BAY_O + xs[i], rect.position.y), rect.size))


## Shapes: the bay's front (frame, sill, buffer, lock pilaster and its fittings, the contact shadow), the
## guard lock on its mount or torn off and hanging by its cable from its gland, and the status lamp.
func _draw_front(layer: Node2D) -> void:
	_piece(layer, "bay_frame")
	if not lock_torn:
		_piece(layer, "lock")
	else:
		_piece(layer, "lock_scars")
		var pose: Array = lock_pose(lock_age)
		var gland: Vector2 = DC + pose[0]
		# The lock's cable: out of the backplate's gland (leaving it level), down into the lock's gland
		# (fix 1: dark, so the lock is seen to hang by it). Fix 2 (review-real-2 S2): slack only while the lock
		# drops and swings; once it has settled the cable carries it, so it makes a tight bend out of the
		# backplate and drops straight to the lock.
		var settled: float = smoothstep(0.2, 1.0, lock_age)
		var p1_taut: Vector2 = LOCK_CABLE_ENTRY + Vector2(-1.2, 0.0)
		var p1: Vector2 = (LOCK_CABLE_ENTRY + Vector2(-2.0, 0.0)).lerp(p1_taut, settled)
		var p2: Vector2 = (gland + Vector2(-2.2, -4.0)).lerp(gland + (p1_taut - gland) * 0.3, settled)
		var points: PackedVector2Array = PackedVector2Array()
		for i: int in 13:
			var t: float = i / 12.0
			var u: float = 1.0 - t
			points.append(u * u * u * LOCK_CABLE_ENTRY + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * gland)
		layer.draw_polyline(points, C_LOCK_CABLE, LOCK_CABLE_W, true)
		# Its lit edge, on the side that faces up and left toward the bay's fitting.
		var lit: PackedVector2Array = PackedVector2Array()
		for i: int in points.size():
			var tangent: Vector2 = (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
			var normal: Vector2 = Vector2(-tangent.y, tangent.x)
			if normal.dot(Vector2(-1.0, -1.0)) < 0.0:
				normal = -normal
			lit.append(points[i] + normal * (0.5 * LOCK_CABLE_W - 0.5 * LOCK_CABLE_LIT_W))
		layer.draw_polyline(lit, C_LOCK_CABLE_LIT, LOCK_CABLE_LIT_W, true)
		var lock_rect: Rect2 = DockShapesData.PIECES["lock"]
		layer.draw_set_transform(gland, float(pose[1]), Vector2.ONE)
		_piece_in(layer, "lock", Rect2(lock_rect.position - DC - LOCK_GLAND_MOUNT, lock_rect.size))
		layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var lamp: Color = LAMP_GREEN
	if status_lamp == Status.RED_STEADY:
		lamp = LAMP_RED
	elif status_lamp == Status.RED_FLASH:
		lamp = LAMP_RED if fmod(_flash_time, 0.5) < 0.25 else LAMP_OFF
	elif status_lamp == Status.OFF:
		lamp = LAMP_OFF
	layer.draw_circle(STATUS_LAMP, 1.3, lamp)


## Contact shadows (round 3, review-real-2 S3 and review-human-2 must-fix 1): a soft dark ellipse under
## each actor standing on the dock room's floor, at their feet, so depth on the floor reads.
func _draw_shadows(layer: Node2D) -> void:
	if occupant:
		# Fix 1 (review-real-1 S3): docked WOLF's body stands between the bay's roof fitting and the stand: a
		# soft shade on the stand and the plate under him (this layer is over the bay's light, under the actors).
		var centre: Vector2 = Vector2(occupant_x, OCCUPANT_SHADE_Y) + OCCUPANT_SHADE_AT
		var full: Rect2 = Rect2(centre - OCCUPANT_SHADE_R * 2.0, OCCUPANT_SHADE_R * 4.0)
		var inside: Rect2 = Rect2(DC.x - 82.0, BAY_ROOF_Y, 164.0, FLOOR_Y - BAY_ROOF_Y)
		var part: Rect2 = full.intersection(inside)
		if part.has_area():
			var size: Vector2 = Vector2(_shade.width, _shade.height)
			var src: Rect2 = Rect2((part.position - full.position) / full.size * size, part.size / full.size * size)
			layer.draw_texture_rect_region(_shade, part, src, Color(1.0, 1.0, 1.0, OCCUPANT_SHADE))
	for caster: Vector3 in shadow_casters:
		var at: Vector2 = Vector2(caster.x, caster.y)
		var half: float = caster.z
		_ellipse(layer, at, Vector2(half, 2.6), Color(0.0, 0.0, 0.0, 0.22))
		_ellipse(layer, at + Vector2(0.0, 0.3), Vector2(half * 0.75, 1.6), Color(0.0, 0.0, 0.0, 0.3))


## Shapes: the cross-wall's cut end (0.45 m), drawn over the actors, with its corner guard.
func _draw_over(layer: Node2D) -> void:
	_piece(layer, "near_column")


## Round 4 (Nathanial 2026-10-14, decision 11): the corridor fitting's light on an actor's edge. A child of
## the actor's sprite with the same texture, drawn additively: only the silhouette's rim on the side that
## faces the fitting lights, by an amount that falls off with the distance from the fitting the way its
## pool does, and to nothing where the cross-wall stands between them (left of the opening's far side).
const LIT_EDGE_SHADER: String = """
shader_type canvas_item;
render_mode blend_add;
uniform vec2 to_light = vec2(1.0, -1.0);
uniform float reach_px = 8.0;
uniform vec3 light_color = vec3(0.80, 0.86, 0.92);
uniform float strength_top = 0.0;
uniform float strength_bottom = 0.0;
void fragment() {
	float a = texture(TEXTURE, UV, -0.5).a;
	float outside = 0.0;
	for (int i = 1; i <= 4; i++) {
		vec2 uv2 = UV + to_light * TEXTURE_PIXEL_SIZE * reach_px * float(i) / 4.0;
		outside = max(outside, 1.0 - texture(TEXTURE, uv2, -0.5).a);
	}
	float e = smoothstep(0.35, 0.9, a) * outside * mix(strength_top, strength_bottom, UV.y);
	COLOR = vec4(light_color * e, 1.0);
}
"""
## The fitting's light reaches an actor's edge with this much at most, falling off as exp(-(d / r)^2).
## Round 4, measured on the stills (GREYBOX-R4.md): once the wall seen through the opening is lit as the
## corridor wall beside the fitting really is, the engineer's edge in the doorway reaches 2.00 (box 2) and
## 2.05 (box 8) with no lit edge, and every lit edge tried lowers it, because it brightens their edge
## toward that same lit wall (0.6: 1.41; 1.0: 1.72; 1.4: 1.91, which reads as a white outline). So it is
## built and switched off (0) for Nathanial's call; 1.0 is the physically matched strength.
const LIT_EDGE_PEAK: float = 0.0
const LIT_EDGE_RADIUS: float = 170.0
static var _lit_edge_shader: Shader


static func make_lit_edge(body: Sprite2D) -> Sprite2D:
	if _lit_edge_shader == null:
		_lit_edge_shader = Shader.new()
		_lit_edge_shader.code = LIT_EDGE_SHADER
	var edge: Sprite2D = Sprite2D.new()
	edge.name = "LitEdge"
	edge.texture = body.texture
	edge.texture_filter = body.texture_filter
	edge.centered = body.centered
	edge.offset = body.offset
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = _lit_edge_shader
	edge.material = material
	edge.visible = false
	body.add_child(edge)
	return edge


## How much of the fitting's light reaches a point (0..1), and its direction from that point.
static func lit_edge_light(at: Vector2) -> Array:
	var source: Vector2 = Vector2(BULKHEAD.get_center().x, BULKHEAD.end.y)
	var to_source: Vector2 = source - at
	var level: float = LIT_EDGE_PEAK * exp(-to_source.length_squared() / (LIT_EDGE_RADIUS * LIT_EDGE_RADIUS))
	# The cross-wall blocks it left of the opening's far side.
	level *= smoothstep(OPENING.x - 14.0, OPENING.x + 4.0, at.x)
	return [level, to_source.normalized()]


func update_lit_edge(edge: Sprite2D, body: Sprite2D, centre: Vector2, on: bool, half_height: float = 32.0) -> void:
	if edge == null:
		return
	if LIT_EDGE_PEAK <= 0.0:
		edge.visible = false
		edge.set_meta("strength", 0.0)
		return
	var light_at: Array = lit_edge_light(centre)
	var level: float = float(light_at[0]) if on else 0.0
	# Head and feet are at different distances from the fitting: the light falls off down the body.
	var top: float = float(lit_edge_light(centre - Vector2(0.0, half_height))[0]) if on else 0.0
	var bottom: float = float(lit_edge_light(centre + Vector2(0.0, half_height))[0]) if on else 0.0
	edge.visible = level > 0.02
	if not edge.visible:
		return
	edge.flip_h = body.flip_h
	edge.texture = body.texture
	# The knockdown frames are regions of the same sheet.
	edge.region_enabled = body.region_enabled
	edge.region_rect = body.region_rect
	edge.hframes = body.hframes
	edge.vframes = body.vframes
	edge.frame = body.frame
	var direction: Vector2 = light_at[1]
	if body.flip_h:
		direction.x = -direction.x
	var material: ShaderMaterial = edge.material as ShaderMaterial
	material.set_shader_parameter("to_light", direction)
	material.set_shader_parameter("strength_top", top)
	material.set_shader_parameter("strength_bottom", bottom)
	edge.set_meta("strength", level)
