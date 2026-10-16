class_name DoorCamera
extends RefCounted
## The design camera of the door ends, written once. Door pieces that are drawn as meshes in their
## own planes (the corridor's inner blast leaf, the Records and junction swing leaves, the junction
## exit's leaf anchor) place each vertex with it, so a moving leaf lines up with the painted room
## around it.
##
## The camera was measured from the corridor far plate's floor joints (the corridor door-end
## design, 1cf8d73:docs/research-2026-10/sources/corridor-door-end-2026-10-12/tools/design/common.py, whose
## project() and depth_scale() this matches): the walk line is at depth D0 metres from the eye, and a
## point d metres behind it is scaled by D0 / (D0 + d) about the vanishing point. A room with its own
## measured vanishing point passes it as (vp_x, vp_y); the Service Junction's is (511, 162).
##
## Users must get bit-identical vertices from it: it takes scalar floats (64-bit in GDScript) and
## keeps the operation order the leaves used before it existed, so nothing is rounded to a
## Vector3's 32-bit floats before the final Vector2. Pass metres as floats, not packed in a Vector3,
## unless the caller's values were already 32-bit.

## The vanishing point's world x and its world y (the horizon), in world px (common.py VPX, HORIZON).
const VPX: float = 483.9
const HORIZON: float = 158.5
## The walk line's distance from the eye, metres (common.py D0).
const D0: float = 38.0
## World px per metre at the walk line's depth (common.py PX_PER_M). The walk line's floor is at
## world y RoomDepth.FLOOR_Y (440), the single definition of the floor.
const PX_PER_M: float = 40.0


## World px of the point [param x_m] metres along the room (world x / PX_PER_M at the walk line),
## [param h_m] metres above the floor and [param d_m] metres behind the walk line (negative is
## nearer the camera), seen with the vanishing point ([param vp_x], [param vp_y]) in world px.
static func project(x_m: float, h_m: float, d_m: float, vp_x: float = VPX, vp_y: float = HORIZON) -> Vector2:
	var s: float = depth_scale(d_m)
	return Vector2(vp_x + (x_m * PX_PER_M - vp_x) * s, vp_y + (RoomDepth.FLOOR_Y - vp_y) * s - h_m * PX_PER_M * s)


## How much a point [param d_m] metres behind the walk line is scaled about the vanishing point
## (1 on the walk line, smaller further back).
static func depth_scale(d_m: float) -> float:
	return D0 / (D0 + d_m)
