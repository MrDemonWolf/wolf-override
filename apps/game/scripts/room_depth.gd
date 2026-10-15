class_name RoomDepth
extends Node2D
## A room built from three painted plates that share one 16:9 frame, plus the light every room
## shares, all with built-in nodes:
## - far: the back wall and floor, a Parallax2D that lags the camera, with additive glows and
##   drifting light shafts over its painted lamps, lockdown beacons (painted fixtures from
##   [member beacon_atlas], or a small drawn housing where a room has none), wall haze and dust;
## - mid: the play plane, drawn 1:1 with the room so its painted walkway is the floor (y 440) the
##   actors and stations stand on;
## - near: the plate's edge pieces only (a left strip and the same strip mirrored on the right),
##   drawn over the actors and scrolling faster than the floor; a piece fades back while it covers
##   one of the [member occluders] (the actors), so nobody is hidden at either end of the room.
## Source pixels are never edited. Main switches the depth pass with [member effects_enabled]: off,
## every plate moves with the floor and the near pieces, glows, haze and dust are hidden.
## The light moves only while the room is on screen: a hidden room (Main hides the rooms it is not
## in) stops its dust and its lamp, shaft and beacon tweens, and starts them again when it shows.
## Main settles the lockdown beacons from the save state once the room's route is cleared
## ([method set_lockdown_cleared]).

const ROOM_WIDTH: float = 960.0
const FLOOR_Y: float = 440.0
const BACKDROP_SCROLL: Vector2 = Vector2(0.9, 1.0)
const NEAR_SCROLL: Vector2 = Vector2(1.15, 1.0)
const Z_BACKDROP: int = -4
const Z_MID: int = -3
## Far dust shares the backdrop's depth and is added after it, so it drifts over the far wall but
## behind the mid plate's pillars and pipes.
const Z_ATMOSPHERE: int = -4
const Z_NEAR: int = 3
## The near edge strips are anchored at least this far past the room edges so their outer edges
## stay off screen through every framing: Parallax2D shifts a layer by (camera x - 480) *
## (1 - scroll), which at 1.15 is up to 19 px at play (zoom 1.35), 32 px in the opening (zoom 1.8)
## and 26 px at the chapter-close shot (zoom 1.55), plus up to 10 px of camera shake.
const NEAR_OVERHANG: float = 56.0
## Mirrored slivers of the mid plate past each room edge and below its bottom, so camera shake at
## the end of the camera's travel (or under the touch framing, whose view ends at the plate's
## bottom) shows a continuation of the plate instead of its cut edge. The bottom one matters where
## the floor is painted on the mid plate (the junction); elsewhere that strip is transparent.
const MID_BLEED: float = 16.0
const FAR_DUST_COUNT: int = 30
const NEAR_DUST_COUNT: int = 12
const GLOW_SIZE: Vector2 = Vector2(250.0, 96.0)
## Columns of the faded haze texture (see haze_fade): about one per far-plate pixel.
const HAZE_FADE_COLUMNS: int = 512
const SHAFT_SIZE: Vector2 = Vector2(54.0, 240.0)
const LAMP_ALPHA: float = 0.5
## Each lamp waits a random FLICKER_WAIT_MIN..FLICKER_WAIT_MAX seconds between flickers, so the
## lamps never fall into a shared rhythm.
const FLICKER_WAIT_MIN: float = 4.0
const FLICKER_WAIT_MAX: float = 15.0
## How often a flicker is a double blink (never with Reduced Motion).
const DOUBLE_BLINK_CHANCE: float = 0.3
## The two blinks of a double start this far apart, so no lamp ever flashes faster than about
## 2.8 times a second (under the 3 Hz flash guideline).
const BLINK_SPACING: float = 0.36
const BLINK_DOWN_SECONDS: float = 0.07
const BLINK_UP_SECONDS: float = 0.17
## Reduced Motion: one shallow, slower dip and no double blink.
const GENTLE_DOWN_SECONDS: float = 0.18
const GENTLE_UP_SECONDS: float = 0.35
const BEACON_ALPHA: float = 0.4
## One beacon pulse dims and recovers over twice this.
const BEACON_PULSE_SECONDS: float = 1.3
## A cleared room's beacons hold this steady, dim glow, their lenses darkened by SETTLED_LENS_DARKEN.
const SETTLED_BEACON_ALPHA: float = 0.1
const SETTLED_LENS_DARKEN: float = 0.6
## A rotating warning beacon seen from one place ([member beacon_flash]): the beam sweeps past in
## BEACON_FLASH_RISE_SECONDS, then the globe falls back to its dim glow over BEACON_FLASH_FALL_SECONDS
## while the reflector turns away: one flash every 0.68 s, 88 a minute, like a real 80-90 fpm red
## rotating beacon and well under three flashes a second. The second beacon runs
## BEACON_FLASH_PHASE_SECONDS behind the first, as two beacons on one circuit drift apart.
const BEACON_FLASH_RISE_SECONDS: float = 0.17
const BEACON_FLASH_FALL_SECONDS: float = 0.51
const BEACON_FLASH_PHASE_SECONDS: float = 0.29
## How long the beacons take to settle when the route is cleared in play.
const SETTLE_SECONDS: float = 1.2
## A near edge piece fades to this opacity while it covers an actor, at NEAR_FADE_SPEED per second.
const NEAR_FADE_ALPHA: float = 0.35
const NEAR_FADE_SPEED: float = 4.0
## The pressure bulkheads (design A) shared by the corridor seal and the junction door: their import
## copies share one canvas per door whose bottom row is the floor, drawn at this scale, and the front
## pillar's outer edge sits this many canvas pixels in from the left, its column BULKHEAD_PILLAR_WIDTH
## canvas pixels wide at body height.
const BULKHEAD_SCALE: float = 0.3
const BULKHEAD_PILLAR_X: float = 83.0
const BULKHEAD_PILLAR_WIDTH: float = 76.0
## A bulkhead's front pillar (see [member pillars]) fades to this opacity while it covers an actor,
## keeping more of the doorway than a near edge piece does.
const PILLAR_FADE_ALPHA: float = 0.5
## Regions per painted beacon in [member beacon_regions]: fixture, globe, guard, light.
const BEACON_ART_PARTS: int = 4

## The far plate: back wall, painted lamps and wet floor (opaque).
@export var painting: Texture2D
## The play plane: pillars, pipes and machines on transparency.
@export var mid_painting: Texture2D
## Foreground pieces on transparency; only [member near_strip_width] source pixels from its left
## edge are used, on both sides of the room.
@export var near_painting: Texture2D
## The source row where the mid plate's painted walkway meets the floor; it is drawn at FLOOR_Y.
@export var walkway_y: float = 777.0
## How far the far plate sits below the mid plate, so its painted ceiling lamps stay in the play view.
@export var far_drop: float = 0.0
@export var near_strip_width: float = 512.0
## How far past each room edge the near strips are anchored (at least NEAR_OVERHANG). A room whose
## painted pipe column is wider than the corridor's (57 px) anchors it further out by the
## difference, so the column at each end of the play view only grazes an engineer standing at the
## 40 / 920 clamp.
@export var near_overhang: float = NEAR_OVERHANG
## How many source pixels of each near strip, from the room's edge inward, are the painted column
## that can cover an actor (the corridor's 57 px column; the junction's is 100 px).
@export var near_column_width: float = 114.0
@export var base_color: Color = Color("#091533")
## Ceiling lamp centres as fractions of the far plate, so the glows ride on its parallax.
@export var lamps: PackedVector2Array = PackedVector2Array()
@export var lamp_color: Color = Color("#9fe4ff")
## Lamps (by index into [member lamps]) that also cast a drifting light shaft.
@export var shaft_lamps: PackedInt32Array = PackedInt32Array()
## Lockdown beacons as fractions of the far plate: a lamp with a pulsing glow.
@export var warning_lamps: PackedVector2Array = PackedVector2Array()
@export var warning_color: Color = Color("#ff4a46")
## Painted beacons (the corridor's caged wall lamps): one small atlas holding, per beacon,
## BEACON_ART_PARTS regions in [member beacon_regions] (atlas px), each drawn at its offset in
## [member beacon_offsets] from the beacon's anchor (far-plate px, so the art lands on the plate's own
## pixel grid): the fixture with its conduit and wall shadow, the globe (greyscale glass tinted by
## the live lens colour), the guard in front of the globe, and the lamp's light (additive, pulsed and
## settled exactly like the drawn beacons' glow). Without an atlas the room draws the small housing.
@export var beacon_atlas: Texture2D
@export var beacon_regions: Array[Rect2] = []
@export var beacon_offsets: PackedVector2Array = PackedVector2Array()
## The beacons' light at the top of each pulse, and how far it falls between pulses (a fraction of
## the top). The drawn housings keep BEACON_ALPHA and the shallow 0.55 dip; the corridor's caged lamps
## are real alarm lamps going off, so they swing from nearly dark to a brighter top (round 10, human
## review r3: at 1x the shallow pulse read as warning lights, not an alarm).
@export var beacon_peak_alpha: float = BEACON_ALPHA
@export var beacon_trough: float = 0.55
## How far each beacon's lens (its lit globe) darkens at the bottom of a pulse, moving with its light
## so the lamp itself dims and brightens with the light it casts (0 keeps a steady lens: the drawn
## housings). The corridor's caged lamps darken to 0.6, the unlit red of a jelly-jar globe.
@export var beacon_lens_trough: float = 0.0
## The rhythm of a real rotating warning beacon (see BEACON_FLASH_RISE_SECONDS) instead of the slow
## 2.6 s breathe. Reduced Motion holds these beacons lit and steady.
@export var beacon_flash: bool = false
## Ambient dust drifting in the room. Off where the room's light is painted into its plates and
## nothing in the air needs to move (the corridor since the door end was rebuilt).
@export var ambient_dust: bool = true
## How far across the far plate (a fraction of its width) the wall haze band reaches at full
## strength, and over how much more of it (haze_fade) it then fades out to nothing. The corridor
## keeps it untouched over everything the opening frames and fades it out over the door end's first
## bay, where the painted light takes over, so no straight edge shows on the floor. The fade is part
## of the haze's own texture (one sprite, one draw call).
@export var haze_end: float = 1.0
@export var haze_fade: float = 0.0
## Whether the near strip is mirrored on the room's right edge too. The corridor's right edge now
## opens into the machinery room past the seal, so its mirrored pipe column is not drawn there.
@export var near_right_edge: bool = true
## Lamps (by index into [member lamps]) whose light is painted into the plate: their glow and shaft
## stay hidden. They keep their place in the flicker sequence, so the other lamps flicker as before.
@export var painted_lamps: PackedInt32Array = PackedInt32Array()

var effects_enabled: bool = true:
	set(value):
		effects_enabled = value
		if is_node_ready():
			_apply()
## Reduced Motion: the lamps flicker with one shallow, slower dip and never double blink. Read at
## each flicker, so a change applies from the next one. Flashing beacons ([member beacon_flash]) stop
## at once and hold their lit, steady state.
var reduce_motion: bool = false:
	set(value):
		if value == reduce_motion:
			return
		reduce_motion = value
		if beacon_flash and is_node_ready() and _motion_running:
			_settle_beacons(false)
## True once Main says the room's route is cleared; see [method set_lockdown_cleared].
var lockdown_cleared: bool = false
## Sprites (the actors' bodies) the near edge pieces fade back from while they cover them.
var occluders: Array[Sprite2D] = []
## Bulkhead front lips (made with [method make_bulkhead]'s cut) drawn over the actors in this room;
## each fades back to PILLAR_FADE_ALPHA while its pillar covers one of the [member occluders].
var pillars: Array[Sprite2D] = []

var backdrop_layer: Parallax2D
var backdrop: Sprite2D
var mid_layer: Node2D
var near_layer: Parallax2D
var lamp_glows: Array[Sprite2D] = []
var beacons: Array[Node2D] = []
var haze: Sprite2D
var far_dust: CPUParticles2D
var near_dust: CPUParticles2D
var _built: Array[Node] = []
## The lamp flickers and shaft drifts, and separately the beacon pulses (or their settle).
var _tweens: Array[Tween] = []
var _beacon_tweens: Array[Tween] = []
var _lamp_lights: Array[Sprite2D] = []
var _shafts: Array[Sprite2D] = []
var _warning_glows: Array[Sprite2D] = []
## True while the lamps, shafts and beacons are animating (effects on and the room on screen).
var _motion_running: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## A lockdown beacon: a dark housing on a short bracket with a red lens, or, with [member art], the
## painted fixture, its globe tinted by [member lens] and the guard over it (one texture, so both
## beacons batch).
class Beacon:
	extends Node2D
	var lens: Color = Color("#ff4a46"):
		set(value):
			lens = value
			queue_redraw()
	var art: Texture2D
	## Destination rect (relative to the anchor, world px) and atlas region, for the fixture, the
	## globe and the guard in turn.
	var parts: Array[Rect2] = []

	func _draw() -> void:
		if art != null:
			draw_texture_rect_region(art, parts[0], parts[1])
			draw_texture_rect_region(art, parts[2], parts[3], lens)
			draw_texture_rect_region(art, parts[4], parts[5])
			return
		draw_line(Vector2(0.0, -9.0), Vector2(0.0, -4.0), Color("#1b2630"), 2.0)
		draw_rect(Rect2(-7.0, -4.0, 14.0, 9.0), Color("#141c24"))
		draw_rect(Rect2(-7.0, -4.0, 14.0, 9.0), Color("#3e4f5a"), false, 1.0)
		draw_rect(Rect2(-5.0, -2.0, 10.0, 5.0), lens)


func _ready() -> void:
	# The base fill drawn here must sit under the backdrop whatever the owning room's own z-index is.
	z_as_relative = false
	z_index = Z_BACKDROP
	_rng.randomize()
	rebuild()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	# The pillars fade whether or not the depth pass is on: they draw over the actors either way.
	for pillar: Sprite2D in pillars:
		if is_instance_valid(pillar):
			var pillar_target: float = PILLAR_FADE_ALPHA if pillar_covers(pillar) else 1.0
			pillar.modulate.a = move_toward(pillar.modulate.a, pillar_target, NEAR_FADE_SPEED * delta)
	if near_layer == null or not near_layer.visible:
		return
	for edge_name: String in ["LeftEdge", "RightEdge"]:
		var edge: Sprite2D = near_layer.get_node_or_null(edge_name) as Sprite2D
		if edge == null:
			continue
		var target: float = NEAR_FADE_ALPHA if near_covers(edge) else 1.0
		edge.modulate.a = move_toward(edge.modulate.a, target, NEAR_FADE_SPEED * delta)


## True when [param edge]'s painted column covers any visible occluder on screen.
func near_covers(edge: Sprite2D) -> bool:
	var width: float = edge.region_rect.size.x
	var column: float = minf(near_column_width, width)
	var local: Rect2 = Rect2(width - column if edge.flip_h else 0.0, 0.0, column, edge.region_rect.size.y)
	var screen: Rect2 = edge.get_global_transform_with_canvas() * local
	for sprite: Sprite2D in occluders:
		if is_instance_valid(sprite) and sprite.is_visible_in_tree():
			var body: Rect2 = sprite.get_global_transform_with_canvas() * sprite.get_rect()
			if body.position.x < screen.end.x and body.end.x > screen.position.x:
				return true
	return false


## True when [param pillar]'s front pillar column (BULKHEAD_PILLAR_X, BULKHEAD_PILLAR_WIDTH wide, floor
## to header) overlaps any visible occluder's body on screen.
func pillar_covers(pillar: Sprite2D) -> bool:
	if not pillar.is_visible_in_tree():
		return false
	var cut: Rect2 = pillar.get_rect()
	var local: Rect2 = Rect2(cut.position.x + BULKHEAD_PILLAR_X - pillar.region_rect.position.x, cut.position.y, BULKHEAD_PILLAR_WIDTH, cut.size.y)
	var screen: Rect2 = pillar.get_global_transform_with_canvas() * local
	for sprite: Sprite2D in occluders:
		if is_instance_valid(sprite) and sprite.is_visible_in_tree():
			if screen.intersects(sprite.get_global_transform_with_canvas() * sprite.get_rect()):
				return true
	return false


func _notification(what: int) -> void:
	# Main shows only the room in play; the others stop moving until they show again.
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_node_ready():
		_sync_motion()


## Rebuilds every layer from the current exports; call after swapping plates at runtime.
func rebuild() -> void:
	_stop_motion()
	for node: Node in _built:
		remove_child(node)
		node.queue_free()
	_built.clear()
	lamp_glows.clear()
	beacons.clear()
	_lamp_lights.clear()
	_shafts.clear()
	_warning_glows.clear()
	backdrop_layer = _add_parallax("Backdrop", BACKDROP_SCROLL, Z_BACKDROP)
	backdrop = _plate("Painting", painting)
	backdrop_layer.add_child(backdrop)
	haze = Sprite2D.new()
	haze.name = "Haze"
	haze.centered = false
	haze.z_index = 1
	haze.texture = _linear_texture([0.0, 0.62, 1.0], [Color(0.37, 0.54, 0.65, 0.0), Color(0.37, 0.54, 0.65, 0.14), Color(0.37, 0.54, 0.65, 0.0)])
	if haze_fade > 0.0:
		haze.texture = _faded_haze(haze.texture as GradientTexture2D, haze_end, haze_fade)
	backdrop_layer.add_child(haze)
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for index: int in lamps.size():
		var glow: Sprite2D = make_glow(lamp_color, GLOW_SIZE, LAMP_ALPHA, additive)
		glow.name = "LampGlow%d" % index
		glow.z_index = 1
		backdrop_layer.add_child(glow)
		lamp_glows.append(glow)
		_lamp_lights.append(glow)
		if index in shaft_lamps:
			var shaft: Sprite2D = _make_shaft(additive)
			shaft.name = "LightShaft%d" % index
			backdrop_layer.add_child(shaft)
			lamp_glows.append(shaft)
			_shafts.append(shaft)
	var painted_beacons: bool = beacon_atlas != null and beacon_regions.size() >= warning_lamps.size() * BEACON_ART_PARTS
	for index: int in warning_lamps.size():
		var beacon: Beacon = Beacon.new()
		beacon.name = "Beacon%d" % index
		beacon.lens = warning_color
		beacon.z_index = 1
		var glow: Sprite2D
		if painted_beacons:
			var first: int = index * BEACON_ART_PARTS
			var plate_scale: float = _plate_scale()
			beacon.art = beacon_atlas
			for part: int in 3:
				var region: Rect2 = beacon_regions[first + part]
				beacon.parts.append(Rect2(beacon_offsets[first + part] * plate_scale, region.size * plate_scale))
				beacon.parts.append(region)
			glow = Sprite2D.new()
			glow.texture = beacon_atlas
			glow.centered = false
			glow.region_enabled = true
			glow.region_rect = beacon_regions[first + 3]
			glow.offset = beacon_offsets[first + 3]
			glow.scale = Vector2.ONE * plate_scale
			glow.modulate = Color(warning_color, beacon_peak_alpha)
			glow.material = additive
		else:
			glow = make_glow(warning_color, Vector2(90.0, 90.0), beacon_peak_alpha, additive)
		backdrop_layer.add_child(beacon)
		beacons.append(beacon)
		glow.name = "WarningGlow%d" % index
		glow.z_index = 2
		backdrop_layer.add_child(glow)
		lamp_glows.append(glow)
		_warning_glows.append(glow)
	_settle_beacons(false)
	mid_layer = Node2D.new()
	mid_layer.name = "MidPlate"
	mid_layer.z_as_relative = false
	mid_layer.z_index = Z_MID
	add_child(mid_layer)
	_built.append(mid_layer)
	mid_layer.add_child(_plate("Painting", mid_painting))
	if mid_painting != null:
		var bleed_source: float = MID_BLEED / _plate_scale()
		var width: float = float(mid_painting.get_width())
		mid_layer.add_child(_plate("LeftBleed", mid_painting, Rect2(0.0, 0.0, bleed_source, mid_painting.get_height()), true))
		mid_layer.add_child(_plate("RightBleed", mid_painting, Rect2(width - bleed_source, 0.0, bleed_source, mid_painting.get_height()), true))
		# The bottom rows flipped down, running past both sides (mirror repeat) to fill the corners.
		var bottom_bleed: Sprite2D = _plate("BottomBleed", mid_painting, Rect2(-bleed_source, mid_painting.get_height() - bleed_source, width + bleed_source * 2.0, bleed_source))
		bottom_bleed.flip_v = true
		bottom_bleed.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
		mid_layer.add_child(bottom_bleed)
	far_dust = _make_dust("FarDust", FAR_DUST_COUNT, 0.18, 0.4, Z_ATMOSPHERE)
	near_layer = _add_parallax("Near", NEAR_SCROLL, Z_NEAR)
	if near_painting != null:
		var strip: Rect2 = Rect2(0.0, 0.0, minf(near_strip_width, near_painting.get_width()), near_painting.get_height())
		near_layer.add_child(_plate("LeftEdge", near_painting, strip))
		if near_right_edge:
			near_layer.add_child(_plate("RightEdge", near_painting, strip, true))
	near_dust = _make_dust("NearDust", NEAR_DUST_COUNT, 0.35, 0.65, Z_NEAR)
	_apply()


func _apply() -> void:
	var on: bool = effects_enabled
	var scale_factor: float = _plate_scale()
	var mid_top: float = FLOOR_Y - walkway_y * scale_factor
	var far: Rect2 = far_rect()
	backdrop_layer.scroll_scale = BACKDROP_SCROLL if on else Vector2.ONE
	backdrop.position = far.position
	backdrop.scale = Vector2.ONE * scale_factor
	haze.visible = on
	haze.position = Vector2(far.position.x, far.position.y + far.size.y * 0.29)
	haze.scale = Vector2(far.size.x * (haze_end + haze_fade), far.size.y * 0.56) / haze.texture.get_size()
	for index: int in lamps.size():
		var glow: Sprite2D = backdrop_layer.get_node("LampGlow%d" % index) as Sprite2D
		glow.position = far.position + lamps[index] * far.size
		var shaft: Sprite2D = backdrop_layer.get_node_or_null("LightShaft%d" % index) as Sprite2D
		if shaft != null:
			shaft.position = glow.position + Vector2(0.0, 6.0)
	for index: int in warning_lamps.size():
		var at: Vector2 = far.position + warning_lamps[index] * far.size
		beacons[index].position = at
		(backdrop_layer.get_node("WarningGlow%d" % index) as Sprite2D).position = at
	for glow: Sprite2D in lamp_glows:
		glow.visible = on
	for index: int in painted_lamps:
		(backdrop_layer.get_node("LampGlow%d" % index) as Sprite2D).visible = false
		var painted_shaft: Sprite2D = backdrop_layer.get_node_or_null("LightShaft%d" % index) as Sprite2D
		if painted_shaft != null:
			painted_shaft.visible = false
	var mid: Sprite2D = mid_layer.get_node("Painting") as Sprite2D
	mid.position = Vector2(0.0, mid_top)
	mid.scale = Vector2.ONE * scale_factor
	var left_bleed: Sprite2D = mid_layer.get_node_or_null("LeftBleed") as Sprite2D
	if left_bleed != null:
		var right_bleed: Sprite2D = mid_layer.get_node("RightBleed") as Sprite2D
		left_bleed.scale = Vector2.ONE * scale_factor
		left_bleed.position = Vector2(-MID_BLEED, mid_top)
		right_bleed.scale = Vector2.ONE * scale_factor
		right_bleed.position = Vector2(ROOM_WIDTH, mid_top)
		var bottom_bleed: Sprite2D = mid_layer.get_node("BottomBleed") as Sprite2D
		bottom_bleed.scale = Vector2.ONE * scale_factor
		bottom_bleed.position = Vector2(-MID_BLEED, mid_top + mid.texture.get_height() * scale_factor)
	near_layer.visible = on
	var left_edge: Sprite2D = near_layer.get_node_or_null("LeftEdge") as Sprite2D
	if left_edge != null:
		left_edge.scale = Vector2.ONE * scale_factor
		left_edge.position = Vector2(-near_overhang, mid_top)
	var right_edge: Sprite2D = near_layer.get_node_or_null("RightEdge") as Sprite2D
	if right_edge != null:
		right_edge.scale = Vector2.ONE * scale_factor
		right_edge.position = Vector2(ROOM_WIDTH + near_overhang - right_edge.region_rect.size.x * scale_factor, mid_top)
	for dust: CPUParticles2D in [far_dust, near_dust]:
		dust.visible = on and ambient_dust
	_sync_motion()
	queue_redraw()


## True while the room's light is animating: the effects are on and the room is on screen.
func is_animating() -> bool:
	return _motion_running


## The haze band with its fade-out baked in: every column of the band's own gradient image (so its
## vertical profile is the same, byte for byte, as the plain band's), full strength up to [param end]
## and fading linearly to nothing over the next [param fade] (both fractions of the far plate's
## width), at HAZE_FADE_COLUMNS columns over the whole band.
static func _faded_haze(band: GradientTexture2D, end: float, fade: float) -> ImageTexture:
	var column: Image = band.get_image()
	var height: int = column.get_height()
	var image: Image = Image.create_empty(HAZE_FADE_COLUMNS, height, false, column.get_format())
	for x: int in HAZE_FADE_COLUMNS:
		# Three columns' grace, so no column the linear filter blends into the full-strength band is
		# dimmed (the fade starts about 4 far-plate pixels past [param end]).
		var at: float = (float(x) - 2.5) / float(HAZE_FADE_COLUMNS) * (end + fade)
		var strength: float = clampf(1.0 - (at - end) / fade, 0.0, 1.0)
		for y: int in height:
			var texel: Color = column.get_pixel(0, y)
			if strength < 1.0:
				texel.a *= strength
			image.set_pixel(x, y, texel)
	return ImageTexture.create_from_image(image)


## Starts the dust and the lamp, shaft and beacon tweens while the room is on screen with effects
## on, and stops them otherwise. A hidden room's dust stops simulating at once and refills the room
## (its preprocess) when it shows again.
func _sync_motion() -> void:
	var run: bool = effects_enabled and is_visible_in_tree()
	for dust: CPUParticles2D in [far_dust, near_dust]:
		if run and ambient_dust:
			dust.process_mode = Node.PROCESS_MODE_INHERIT
			if not dust.emitting:
				dust.restart()
		else:
			dust.emitting = false
			dust.process_mode = Node.PROCESS_MODE_DISABLED
	if run == _motion_running:
		return
	if run:
		_motion_running = true
		for glow: Sprite2D in _lamp_lights:
			_flicker(glow)
		for index: int in _shafts.size():
			_drift(_shafts[index], 0.6 * index)
		_settle_beacons(false)
	else:
		_stop_motion()


## Kills every light tween and puts the lamps, shafts and beacons back at rest.
func _stop_motion() -> void:
	_motion_running = false
	for tween: Tween in _tweens:
		if tween.is_valid():
			tween.kill()
	for tween: Tween in _beacon_tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	_beacon_tweens.clear()
	for glow: Sprite2D in _lamp_lights:
		glow.modulate.a = LAMP_ALPHA
	for shaft: Sprite2D in _shafts:
		shaft.skew = 0.04
		shaft.modulate.a = 1.0
	_settle_beacons(false)


## Main calls this from the save state: [param cleared] once the room's route is cleared (the
## corridor's safe point reached, the first copy secured, the service line cleared). The beacons
## stop pulsing and hold a steady dim glow; [param animate] fades them there instead of cutting.
## Clearing it (a new game or an earlier save) brings the pulse back.
func set_lockdown_cleared(cleared: bool, animate: bool = false) -> void:
	if cleared == lockdown_cleared:
		return
	lockdown_cleared = cleared
	_settle_beacons(animate)


## Puts the beacons in the state [member lockdown_cleared] describes: pulsing (while the room is
## animating) or settled.
func _settle_beacons(animate: bool) -> void:
	for tween: Tween in _beacon_tweens:
		if tween.is_valid():
			tween.kill()
	_beacon_tweens.clear()
	var lens: Color = warning_color.darkened(SETTLED_LENS_DARKEN) if lockdown_cleared else warning_color
	var alpha: float = SETTLED_BEACON_ALPHA if lockdown_cleared else beacon_peak_alpha
	if animate and lockdown_cleared and _motion_running:
		var settle: Tween = create_tween().set_parallel(true)
		_beacon_tweens.append(settle)
		for index: int in beacons.size():
			settle.tween_property(beacons[index], "lens", lens, SETTLE_SECONDS)
			settle.tween_property(_warning_glows[index], "modulate:a", alpha, SETTLE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		return
	var steady: bool = beacon_flash and reduce_motion
	for index: int in beacons.size():
		(beacons[index] as Beacon).lens = lens
		_warning_glows[index].modulate.a = alpha
		if not lockdown_cleared and _motion_running and not steady:
			_pulse(index, (BEACON_FLASH_PHASE_SECONDS if beacon_flash else 0.5) * index)


func _draw() -> void:
	# The opaque far plate covers every framing (room_depth_test checks it), so the base fill only
	# shows for a room built without one.
	if painting == null:
		draw_rect(Rect2(-60.0, 0.0, ROOM_WIDTH + 120.0, 680.0), base_color)


## Where the far plate is drawn, in the backdrop layer's space (it lines up with the room when the
## camera is centred on the room).
func far_rect() -> Rect2:
	var scale_factor: float = _plate_scale()
	var size: Vector2 = painting.get_size() * scale_factor if painting != null else Vector2(ROOM_WIDTH, 540.0)
	return Rect2(Vector2(0.0, FLOOR_Y - walkway_y * scale_factor + far_drop), size)


## Every plate is painted at the same size and drawn exactly as wide as the room.
func _plate_scale() -> float:
	var reference: Texture2D = mid_painting if mid_painting != null else painting
	return ROOM_WIDTH / float(reference.get_width()) if reference != null else 1.0


func _plate(plate_name: String, texture: Texture2D, region: Rect2 = Rect2(), mirrored: bool = false) -> Sprite2D:
	var plate: Sprite2D = Sprite2D.new()
	plate.name = plate_name
	plate.centered = false
	plate.texture = texture
	plate.region_enabled = region.has_area()
	plate.region_rect = region
	plate.flip_h = mirrored
	return plate


func _add_parallax(layer_name: String, scroll: Vector2, z: int) -> Parallax2D:
	var layer: Parallax2D = Parallax2D.new()
	layer.name = layer_name
	layer.scroll_scale = scroll
	layer.z_as_relative = false
	layer.z_index = z
	add_child(layer)
	_built.append(layer)
	return layer


func _make_dust(dust_name: String, count: int, scale_min: float, scale_max: float, z: int) -> CPUParticles2D:
	var dust: CPUParticles2D = CPUParticles2D.new()
	dust.name = dust_name
	dust.z_as_relative = false
	dust.z_index = z
	dust.amount = count
	dust.lifetime = 14.0
	dust.preprocess = 14.0
	dust.position = Vector2(480.0, 300.0)
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(500.0, 150.0)
	dust.direction = Vector2(1.0, 0.0)
	dust.spread = 180.0
	dust.gravity = Vector2(0.0, -1.5)
	dust.initial_velocity_min = 2.0
	dust.initial_velocity_max = 8.0
	dust.scale_amount_min = scale_min
	dust.scale_amount_max = scale_max
	dust.color = Color(0.8, 0.93, 1.0, 0.55)
	var ramp: Gradient = Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	dust.color_ramp = ramp
	dust.texture = _radial_texture(16, [0.0, 0.5, 1.0], [Color.WHITE, Color(1, 1, 1, 0.4), Color(1, 1, 1, 0)])
	add_child(dust)
	_built.append(dust)
	return dust


## The lower half of a squashed radial gradient: a soft cone hanging from the lamp.
func _make_shaft(additive: CanvasItemMaterial) -> Sprite2D:
	var shaft: Sprite2D = Sprite2D.new()
	shaft.centered = false
	shaft.texture = _radial_texture(128, [0.0, 0.35, 1.0], [Color(lamp_color, 0.3), Color(lamp_color, 0.14), Color(lamp_color, 0.0)])
	shaft.region_enabled = true
	shaft.region_rect = Rect2(0.0, 64.0, 128.0, 64.0)
	shaft.offset = Vector2(-64.0, 0.0)
	shaft.scale = SHAFT_SIZE / shaft.region_rect.size
	shaft.material = additive
	shaft.z_index = 1
	shaft.skew = 0.04
	return shaft


## A station prop cut to [param region] of its own image (its painted outline, so the floor
## reflection mirrors from its real base), [param prop_scale]d, centred on [param center_x] with its
## base on [param base_y].
static func make_prop(prop_name: String, texture: Texture2D, region: Rect2, prop_scale: float, center_x: float, base_y: float = FLOOR_Y) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = prop_name
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.scale = Vector2.ONE * prop_scale
	sprite.position = Vector2(center_x, base_y - region.size.y * prop_scale * 0.5)
	return sprite


## A bulkhead image (BULKHEAD_SCALE, its canvas bottom on the floor) placed so its front pillar's
## outer edge is at [param face_x], the face of the door's collision body.
static func make_bulkhead(prop_name: String, texture: Texture2D, region: Rect2, face_x: float) -> Sprite2D:
	return make_prop(prop_name, texture, region, BULKHEAD_SCALE, bulkhead_center_x(region, face_x))


## The centre x of a bulkhead drawn from [param region] with its front pillar's edge at [param face_x].
static func bulkhead_center_x(region: Rect2, face_x: float) -> float:
	return face_x + (region.get_center().x - BULKHEAD_PILLAR_X) * BULKHEAD_SCALE


## An additive radial glow; also used by rooms for their station status lights.
static func make_glow(color: Color, size: Vector2, alpha: float, material: CanvasItemMaterial = null) -> Sprite2D:
	var glow: Sprite2D = Sprite2D.new()
	glow.texture = _radial_texture(128, [0.0, 0.4, 1.0], [Color.WHITE, Color(1, 1, 1, 0.3), Color(1, 1, 1, 0)])
	glow.scale = size / glow.texture.get_size()
	glow.modulate = Color(color, alpha)
	if material == null:
		material = CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = material
	return glow


## One lamp's next flicker as (brightness factor, seconds) steps from rest: a random wait, a dip
## and the recovery, sometimes a second dip BLINK_SPACING after the first. [param gentle] (Reduced
## Motion) makes it one shallow, slower dip.
static func flicker_steps(rng: RandomNumberGenerator, gentle: bool) -> Array[Vector2]:
	var steps: Array[Vector2] = [Vector2(1.0, rng.randf_range(FLICKER_WAIT_MIN, FLICKER_WAIT_MAX))]
	if gentle:
		steps.append(Vector2(rng.randf_range(0.84, 0.9), GENTLE_DOWN_SECONDS))
		steps.append(Vector2(1.0, GENTLE_UP_SECONDS))
		return steps
	steps.append(Vector2(rng.randf_range(0.6, 0.75), BLINK_DOWN_SECONDS))
	steps.append(Vector2(1.0, BLINK_UP_SECONDS))
	if rng.randf() < DOUBLE_BLINK_CHANCE:
		steps.append(Vector2(1.0, BLINK_SPACING - BLINK_DOWN_SECONDS - BLINK_UP_SECONDS))
		steps.append(Vector2(rng.randf_range(0.72, 0.85), BLINK_DOWN_SECONDS))
		steps.append(Vector2(1.0, BLINK_UP_SECONDS + 0.2))
	return steps


## Plays one flicker on [param glow], then schedules the next with a fresh random wait.
func _flicker(glow: Sprite2D) -> void:
	# Drop the finished flickers so the list stays as long as the room has lights.
	var live: Array[Tween] = []
	for previous: Tween in _tweens:
		if previous.is_valid():
			live.append(previous)
	_tweens = live
	var tween: Tween = create_tween()
	_tweens.append(tween)
	for step: Vector2 in flicker_steps(_rng, reduce_motion):
		tween.tween_property(glow, "modulate:a", LAMP_ALPHA * step.x, step.y)
	tween.tween_callback(_flicker.bind(glow))


## Pulses beacon [param index] from its peak: its light (the glow's alpha) and, with
## [member beacon_lens_trough], its lens fall and rise together in one sequence, so the lamp and the
## light it casts never disagree.
func _pulse(index: int, phase: float) -> void:
	var glow: Sprite2D = _warning_glows[index]
	var beacon: Beacon = beacons[index] as Beacon
	var low_alpha: float = beacon_peak_alpha * beacon_trough
	var low_lens: Color = warning_color.darkened(beacon_lens_trough)
	var tween: Tween = create_tween().set_loops()
	_beacon_tweens.append(tween)
	if not beacon_flash:
		tween.tween_interval(phase)
	var fall: float = BEACON_FLASH_FALL_SECONDS if beacon_flash else BEACON_PULSE_SECONDS
	var rise: float = BEACON_FLASH_RISE_SECONDS if beacon_flash else BEACON_PULSE_SECONDS
	var fall_trans: Tween.TransitionType = Tween.TRANS_EXPO if beacon_flash else Tween.TRANS_SINE
	var fall_ease: Tween.EaseType = Tween.EASE_OUT if beacon_flash else Tween.EASE_IN_OUT
	var rise_ease: Tween.EaseType = Tween.EASE_IN if beacon_flash else Tween.EASE_IN_OUT
	tween.tween_property(glow, "modulate:a", low_alpha, fall).set_trans(fall_trans).set_ease(fall_ease)
	if beacon_lens_trough > 0.0:
		tween.parallel().tween_property(beacon, "lens", low_lens, fall).set_trans(fall_trans).set_ease(fall_ease)
	tween.tween_property(glow, "modulate:a", beacon_peak_alpha, rise).set_trans(Tween.TRANS_SINE).set_ease(rise_ease)
	if beacon_lens_trough > 0.0:
		tween.parallel().tween_property(beacon, "lens", warning_color, rise).set_trans(Tween.TRANS_SINE).set_ease(rise_ease)
	if beacon_flash and phase > 0.0:
		# Start part way through the cycle (an interval inside the loop would repeat every cycle).
		tween.custom_step(phase)


func _drift(shaft: Sprite2D, phase: float) -> void:
	var tween: Tween = _loop()
	tween.tween_interval(phase)
	tween.tween_property(shaft, "skew", 0.11, 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(shaft, "modulate:a", 0.75, 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(shaft, "skew", -0.04, 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(shaft, "modulate:a", 1.0, 6.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _loop() -> Tween:
	var tween: Tween = create_tween().set_loops()
	_tweens.append(tween)
	return tween


static func _gradient(offsets: Array[float], colors: Array[Color]) -> Gradient:
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array(offsets)
	gradient.colors = PackedColorArray(colors)
	return gradient


static func _radial_texture(size: int, offsets: Array[float], colors: Array[Color]) -> GradientTexture2D:
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = _gradient(offsets, colors)
	texture.width = size
	texture.height = size
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture


static func _linear_texture(offsets: Array[float], colors: Array[Color], horizontal: bool = false) -> GradientTexture2D:
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = _gradient(offsets, colors)
	texture.width = 64 if horizontal else 4
	texture.height = 4 if horizontal else 64
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(1.0, 0.0) if horizontal else Vector2(0.0, 1.0)
	return texture
