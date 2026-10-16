class_name SwingLeaf
extends Node2D
## A side-hinged steel door leaf that swings on its hinges, drawn as a mesh in the room's camera so it
## turns in its own plane: shut it lies in the cross-wall's turned face, open it stands at 90 degrees
## against nothing but its floor stop. Its faces are flat art in the leaf's own plane (u from the
## hinge edge to the latch edge, v up), regions of the room's door atlas; the face the camera sees
## is drawn (the room face while it shows, else the outside face), plus the latch edge. The light is
## the design's own (records_room door light and the room's ceiling lamp, as rdesign.py lights the
## wall round it), applied per vertex, so the leaf never carries light that belongs to the place.
## Nothing here fades: the leaf is always somewhere on its hinges. A leaf can be drawn by an AtlasMesh
## on the same atlas ([member host]), so a room's door pieces cost one draw call between them.

## The leaf is placed with the door ends' design camera, DoorCamera (x metres along the room, h metres
## up, d metres behind the walkway); a room with its own measured vanishing point (the Service
## Junction's, (511, 162)) sets [member vpx] and [member horizon]. The leaf's size in metres:
const LEAF_W: float = 0.914
const LEAF_H: float = 2.134
const LEAF_T: float = 0.044
const LEAF_BOTTOM: float = 0.010
## The surface closer's regular arm on the room side (ICD/ICS 705: an automatic, non-hold closer
## inside): its pinion on the closer body at the leaf's top rail by the hinge, a main arm and a forearm,
## and the shoe on the frame head. Metres: the pinion's distance from the hinge edge, its height, how far
## it stands off the leaf; the shoe's place along the head from the hinge axis, its height and stand-off.
const ARM_PINION_U: float = 0.10
const ARM_PINION_H: float = 2.052
const ARM_PINION_OFF: float = 0.06
const ARM_SHOE_A: float = -0.45
const ARM_SHOE_H: float = 2.175
const ARM_SHOE_OFF: float = 0.035
const ARM_MAIN: float = 0.26
const ARM_FORE: float = 0.30
const ARM_WIDTH: float = 0.028
## The entry closer's timing (close_behind): the leaf rests open this long (seconds) as they come in,
## then the closer brings it from 90 degrees to shut in CLOSE_SECONDS, eased. ANSI/BHMA A156.19 asks a
## closer 3 s or longer from 90 to 10 degrees. The Records entry and the junction entry share it.
const CLOSE_DELAY: float = 0.35
const CLOSE_SECONDS: float = 3.4
## A shut swing leaf's collision box (px): 16 deep from its room face, as tall as the corridor seal's
## (132), so it stops whoever walks into it at the face.
const BODY_SIZE: Vector2 = Vector2(16.0, 132.0)
## Rows of the mesh (fractions of the leaf height), so the door light's fall-off down the leaf is smooth.
const ROWS: PackedFloat32Array = [0.0, 0.2, 0.45, 0.7, 0.88, 1.0]
## The design model's own shading constants (AMBIENT and WRAP in rmodel.py, under
## docs/research-2026-10/sources/doors-2026-10-14/records/tools; rdesign.py lit the painted walls and
## reveals with them), so a leaf lit here matches the art round it. AMBIENT is the linear-light fill every face gets (scaled by the fill exposure);
## WRAP lifts a lamp's n.l so a face turned slightly away still takes a little of it (a light entry's
## fifth value overrides it, as the door lights' 0 does).
const AMBIENT: Vector3 = Vector3(0.020, 0.032, 0.042)
const WRAP: float = 0.06
## The paint the face art was made at (GUNSHIP albedo at reference exposure 1): a vertex's colour is
## the lit paint over this, per channel in sRGB.
const PAINT: Vector3 = Vector3(0.18, 0.195, 0.235)

## 0 shut, 1 open (90 degrees, on its floor stop).
var open: float = 0.0:
	set(value):
		open = clampf(value, 0.0, 1.0)
		queue_redraw()
		if host != null:
			host.queue_redraw()
var texture: Texture2D
var room_region: Rect2
var out_region: Rect2
var edge_region: Rect2
## The hinge axis's foot (metres: x, h, d) and the wall's unit axes in plan (U along the face toward
## the back wall, N into the wall).
var hinge: Vector3
var axis_u: Vector3
var axis_n: Vector3
## Lights: [position (m), colour * intensity, reach (m), down exponent], and optionally a fifth entry, the
## light's wrap (default WRAP), and a sixth, true for a fill light (set by [member fill], not [member
## exposure]). Fix round 3 (review r3, R3-2): the door light over the head is a true Lambert source (wrap 0),
## so it lights an open leaf's face as it lights the far-jamb reveal the leaf hangs on (both face the same
## way under it) while it only grazes the shut leaf.
var lights: Array = []
## The exposure of the key lights (fix round 2, review r2 N3: the door end's lights set by one exposure).
var exposure: float = 1.0
## Fix round 4 (review r4, M1, cause 2): the ambient and the fill lights carry their own exposure, so a face
## the door light misses keeps the room's fill instead of losing it with the door light's fit. Below zero:
## the same as [member exposure].
var fill: float = -1.0
## The AtlasMesh whose draw call draws this leaf (it then draws nothing itself), or null.
var host: CanvasItem = null
## This room's vanishing point in world px (DoorCamera.project's vp_x, vp_y).
var vpx: float = DoorCamera.VPX
var horizon: float = DoorCamera.HORIZON
## A small solid region of the atlas (painted steel) the closer's arm is drawn with; empty: no arm.
var arm_region: Rect2 = Rect2()


## A leaf cut from [param atlas]: [param room], [param outside] and [param edge] are the atlas regions
## of its room face, outside face and latch edge (each painted flat, u across, v up); [param hinge_foot]
## is the hinge axis's foot and [param u], [param n] the wall's plan axes (see [member hinge]); [param
## lamps] its lights (see [member lights]). It starts shut, named "SwingLeaf", in DoorCamera's default
## vanishing point, with no closer arm: the room sets name, fill, vpx, horizon and arm_region as it needs.
func _init(atlas: Texture2D, room: Rect2, outside: Rect2, edge: Rect2, hinge_foot: Vector3, u: Vector3, n: Vector3, lamps: Array) -> void:
	name = "SwingLeaf"
	texture = atlas
	room_region = room
	out_region = outside
	edge_region = edge
	hinge = hinge_foot
	axis_u = u
	axis_n = n
	lights = lamps
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## A leaf as a room's door uses it: [method _init]'s leaf (atlas, faces, hinge, axes, lights) named
## [param leaf_name], with [param fill_exposure] as its [member fill] and its closer's arm drawn with
## [param arm] (an empty Rect2: no arm). The Records exit and entry and the junction entry are made
## here; a room with its own vanishing point then sets [member vpx] and [member horizon], and the room
## adds the leaf as a child and to the AtlasMesh that draws it.
static func make(leaf_name: String, atlas: Texture2D, room: Rect2, outside: Rect2, edge: Rect2, hinge_foot: Vector3, u: Vector3, n: Vector3, lamps: Array, fill_exposure: float, arm: Rect2) -> SwingLeaf:
	var leaf: SwingLeaf = SwingLeaf.new(atlas, room, outside, edge, hinge_foot, u, n, lamps)
	leaf.name = leaf_name
	leaf.fill = fill_exposure
	leaf.arm_region = arm
	return leaf


## A shut swing leaf's body in [param parent] (RoomDepth.door_body): BODY_SIZE, its face on the walk
## line at world x [param face_x], reaching into the doorway on the side [param side] (1 right, -1
## left), standing on the floor. Disabled until the room enables it; returns the shape.
static func make_body(parent: Node, body_name: String, face_x: float, side: float) -> CollisionShape2D:
	return RoomDepth.door_body(parent, body_name, Vector2(face_x + side * BODY_SIZE.x * 0.5, RoomDepth.FLOOR_Y - BODY_SIZE.y * 0.5), BODY_SIZE)


## Shuts the leaf behind someone who just came through: it stands fully open (open = 1) now, rests
## CLOSE_DELAY, swings shut over CLOSE_SECONDS (sine, in and out), then calls [param shut] (the room
## turns its status lamp red there; it sets the moving colour itself before calling this). The tween
## belongs to [param room], so it pauses and frees with the room; [param running], the
## room's previous closer tween, is killed first so two closers never fight. Returns the new tween for
## the room to keep as its entry_tween: the room's own refresh or reset reads it (RecordsRoom.refresh_state
## leaves a closing leaf alone while it runs; JunctionRoom.reset_transient kills it), and so does
## door_route_test, which waits on it. Main does not read it.
func close_behind(room: Node, running: Tween, shut: Callable) -> Tween:
	if running != null and running.is_running():
		running.kill()
	open = 1.0
	var tween: Tween = room.create_tween()
	tween.tween_interval(CLOSE_DELAY)
	tween.tween_property(self, "open", 0.0, CLOSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(shut)
	return tween


## World px of the point [param p] (metres: x along the room, y up, z behind the walk line) seen from
## the vanishing point ([param vp_x], [param vp_y]): DoorCamera.project for the leaf's Vector3 points,
## whose components are already 32-bit, so passing them on changes no vertex. The room tests call it
## with a leaf's own [member vpx] and [member horizon].
static func project(p: Vector3, vp_x: float = DoorCamera.VPX, vp_y: float = DoorCamera.HORIZON) -> Vector2:
	return DoorCamera.project(p.x, p.y, p.z, vp_x, vp_y)


## [param p] on screen in this leaf's room ([member vpx], [member horizon]).
func _project(p: Vector3) -> Vector2:
	return project(p, vpx, horizon)


## The closer arm's three joints (pinion on the leaf, elbow, shoe on the head) at the current swing.
## The elbow is where the two links meet, on the room side.
func arm_joints() -> PackedVector3Array:
	var theta: float = angle()
	var dir: Vector3 = leaf_dir(theta)
	var n_room: Vector3 = room_normal(theta)
	var pinion: Vector3 = hinge + dir * ARM_PINION_U + n_room * ARM_PINION_OFF
	pinion.y = ARM_PINION_H
	var shoe: Vector3 = hinge + axis_u * ARM_SHOE_A - axis_n * ARM_SHOE_OFF
	shoe.y = ARM_SHOE_H
	# The links lie (nearly) level: the elbow from the two circles in plan.
	var a2: Vector2 = Vector2(pinion.x, pinion.z)
	var b2: Vector2 = Vector2(shoe.x, shoe.z)
	var d: float = clampf(a2.distance_to(b2), absf(ARM_MAIN - ARM_FORE) + 0.001, ARM_MAIN + ARM_FORE - 0.001)
	var along: float = (ARM_MAIN * ARM_MAIN - ARM_FORE * ARM_FORE + d * d) / (2.0 * d)
	var off: float = sqrt(maxf(ARM_MAIN * ARM_MAIN - along * along, 0.0))
	var u2: Vector2 = (b2 - a2).normalized()
	var room2: Vector2 = Vector2(-axis_n.x, -axis_n.z)
	var perp: Vector2 = Vector2(-u2.y, u2.x)
	if perp.dot(room2) < 0.0:
		perp = -perp
	var e2: Vector2 = a2 + u2 * along + perp * off
	var elbow: Vector3 = Vector3(e2.x, lerpf(pinion.y, shoe.y, along / maxf(d, 0.001)), e2.y)
	return PackedVector3Array([pinion, elbow, shoe])


## The swing angle (radians): the operator eases the leaf out of its stop and onto the floor stop.
func angle() -> float:
	return open * PI * 0.5


## The unit plan vector from the hinge edge to the latch edge at swing [param theta] (radians, 0 shut):
## shut it runs along the face away from the back wall (-axis_u); at 90 degrees it stands straight out
## of the wall into the room (-axis_n). The leaf turns about the vertical hinge axis, so y is always 0.
## The arm, the faces and the room tests (room_depth_test) all place the leaf with it.
func leaf_dir(theta: float) -> Vector3:
	return -axis_u * cos(theta) - axis_n * sin(theta)


## The room face's outward unit normal at swing [param theta]: shut it faces out of the wall into the
## room (-axis_n); at 90 degrees it faces along the wall toward the back (+axis_u). It stays leaf_dir
## turned a quarter turn, so the outside face's normal is its negative and the faces sit LEAF_T apart
## along it.
func room_normal(theta: float) -> Vector3:
	return -axis_n * cos(theta) + axis_u * sin(theta)


## The lit paint at [param p] on a face with normal [param nrm], as a vertex colour over the art.
func shade(p: Vector3, nrm: Vector3) -> Color:
	var fill_exposure: float = exposure if fill < 0.0 else fill
	var light: Vector3 = AMBIENT * fill_exposure
	for lamp: Array in lights:
		var to_lamp: Vector3 = (lamp[0] as Vector3) - p
		var dist: float = to_lamp.length()
		var dir: Vector3 = to_lamp / maxf(dist, 0.000001)
		var ndl: float = clampf(dir.dot(nrm), 0.0, 1.0)
		if ndl <= 0.0:
			continue
		var wrap: float = float(lamp[4]) if lamp.size() > 4 else WRAP
		ndl = wrap + (1.0 - wrap) * ndl
		var fall: float = 1.0 / (1.0 + pow(dist / float(lamp[2]), 2.0))
		var down: float = float(lamp[3])
		if down > 0.0:
			var below: float = clampf((dir.y + 0.35) / 1.35, 0.0, 1.0)
			fall *= 0.04 + 0.96 * pow(below, down)
		var is_fill: bool = lamp.size() > 5 and bool(lamp[5])
		light += (lamp[1] as Vector3) * ndl * fall * (fill_exposure if is_fill else exposure)
	var lit: Vector3 = PAINT * light
	return Color(_srgb(lit.x) / _srgb(PAINT.x), _srgb(lit.y) / _srgb(PAINT.y), _srgb(lit.z) / _srgb(PAINT.z), 1.0)


## The sRGB transfer function (IEC 61966-2-1) of the linear value [param c], clamped to 0..1 first. shade()
## takes the lit paint's ratio to the bare paint in sRGB, because the vertex colour multiplies the face
## art's stored sRGB values.
static func _srgb(c: float) -> float:
	c = clampf(c, 0.0, 1.0)
	return c * 12.92 if c <= 0.0031308 else 1.055 * pow(c, 1.0 / 2.4) - 0.055


## Draws the leaf on its own unless an AtlasMesh [member host] draws it in its own call.
func _draw() -> void:
	if host != null:
		return
	var mesh: TriMesh = TriMesh.new()
	append_mesh(mesh)
	mesh.draw(get_canvas_item(), texture)


## The room's pinhole camera (DoorCamera, with this leaf's vanishing point): x = vpx / PX_PER_M,
## d = -D0. Its height does not matter to which face it sees, since the leaf turns about a vertical
## axis.
func camera() -> Vector3:
	return Vector3(vpx / DoorCamera.PX_PER_M, 0.0, -DoorCamera.D0)


## True while the camera sees the room face at swing [param theta], else the outside face. Fix round 4
## (review r4, M1, cause 1): the test is the real view ray to the face's centre, not a view straight along
## +d; these doors stand 10-12 m off the camera's axis, so the parallel test drew the outside face (which
## the camera cannot see) for 17-31 degrees (Records) and 18-34 degrees (the junction entry) of the swing.
func room_face_shows(theta: float) -> bool:
	var centre: Vector3 = hinge + leaf_dir(theta) * (LEAF_W * 0.5)
	return room_normal(theta).dot(centre - camera()) < 0.0


## The face the camera sees at swing [param theta] (radians, 0 shut), as [room, base, normal]: room is
## room_face_shows(theta) (true: the room face, false: the outside face); base (metres) is that face's
## bottom corner on the hinge side, the hinge foot for the room face and LEAF_T behind it, along the
## room face's normal, for the outside face; normal is that face's outward unit normal. append_mesh
## draws and lights the face from it and room_depth_test measures the face's light from it, so the
## two can never pick different faces.
func visible_face(theta: float) -> Array:
	var n_room: Vector3 = room_normal(theta)
	var room_shows: bool = room_face_shows(theta)
	var base: Vector3 = hinge if room_shows else hinge - n_room * LEAF_T
	var nrm: Vector3 = n_room if room_shows else -n_room
	return [room_shows, base, nrm]


## Adds this leaf, at its current swing, to [param mesh] (in the order the leaf draws: the face the
## camera sees, the latch edge, then the closer arm's two links). AtlasMesh calls it to draw a hosted
## leaf in its own draw call; nothing is added while the leaf is hidden.
func append_mesh(mesh: TriMesh) -> void:
	if not visible:
		return
	var theta: float = angle()
	var dir: Vector3 = leaf_dir(theta)
	var n_room: Vector3 = room_normal(theta)
	var face: Array = visible_face(theta)
	var nrm: Vector3 = face[2]
	var region: Rect2 = room_region if bool(face[0]) else out_region
	_append_quad(mesh, face[1] as Vector3, dir * LEAF_W, region, nrm)
	# The latch edge, a 44 mm strip at the free end, faces the camera through the whole swing.
	var edge_base: Vector3 = hinge + dir * LEAF_W
	_append_quad(mesh, edge_base, -n_room * LEAF_T, edge_region, dir)
	if arm_region.has_area():
		var joints: PackedVector3Array = arm_joints()
		# The arm is dark painted steel on the room side of the head, in the leaf's own light (review r2:
		# lit as a top face it read as a pale sliver floating over the leaf).
		var lit: Color = shade(joints[0], nrm)
		var steel: Color = Color(lit.r * 0.85, lit.g * 0.85, lit.b * 0.85, 1.0)
		for k: int in 2:
			_append_link(mesh, joints[k], joints[k + 1], steel)


## One link of the closer's arm: a thin bar between two joints, ARM_WIDTH wide on screen.
func _append_link(mesh: TriMesh, from: Vector3, to: Vector3, color: Color) -> void:
	var size: Vector2 = texture.get_size()
	var a: Vector2 = _project(from)
	var b: Vector2 = _project(to)
	var across: Vector2 = (b - a).orthogonal().normalized() * (ARM_WIDTH * DoorCamera.PX_PER_M * 0.5)
	var first: int = mesh.vertex_count()
	var uv: Vector2 = arm_region.get_center() / size
	for p: Vector2 in [a + across, b + across, b - across, a - across]:
		mesh.add_vertex(p, uv, color)
	mesh.add_quad(first)


## One face as a two-column mesh: [param base] is its bottom corner on the hinge side (or the inner
## side, for the edge), [param across] runs to its other side, rows go up the leaf.
func _append_quad(mesh: TriMesh, base: Vector3, across: Vector3, region: Rect2, nrm: Vector3) -> void:
	var size: Vector2 = texture.get_size()
	var first: int = mesh.vertex_count()
	for column: int in 2:
		for row: float in ROWS:
			var p: Vector3 = base + across * float(column) + Vector3(0.0, LEAF_BOTTOM + row * LEAF_H, 0.0)
			mesh.add_vertex(_project(p), (region.position + Vector2(float(column) * region.size.x, (1.0 - row) * region.size.y)) / size, shade(p, nrm))
	mesh.add_grid(first, 2, ROWS.size())
