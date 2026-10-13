class_name WolfRig
extends RigBase
## WOLF as a jointed cut-out: body, head, three tail segments, and four legs (upper, lower, paw /
## thigh, shin, foot). The far legs reuse the near parts, darkened. A procedural walk/trot driven
## by distance travelled: phase += distance / stride, planted paws are fixed in world space.

const FAR_TINT: Color = Color(0.60, 0.64, 0.72)

# Gait tables (D4 px). walk: lateral sequence; trot: diagonal pairs.
const WALK_SPEED: float = 110.0   # world px/s at which the walk is "pure"
const TROT_SPEED: float = 200.0
const WALK = {"L": 272.0, "duty": 0.64, "lift_f": 15.0, "lift_h": 12.0, "bob": 2.7, "curl_f": 0.9, "curl_h": 0.45,
		"off": [0.0, 0.25, 0.5, 0.75], "reach_f": 4.0, "reach_h": 0.0, "tail": 0.07, "head": 0.025, "roll_f": 0.5, "roll_h": 0.35}
const TROT = {"L": 390.0, "duty": 0.42, "lift_f": 27.0, "lift_h": 22.0, "bob": 5.5, "curl_f": 1.5, "curl_h": 0.8,
		"off": [0.0, 0.5, 0.5, 0.0], "reach_f": 10.0, "reach_h": 2.0, "tail": 0.1, "head": 0.04, "roll_f": 0.7, "roll_h": 0.5}
# leg order: near hind, near fore, far hind, far fore

var hip_h: float = 129.0
var sh_h: float = 125.5
var legs: Array = []
var phase: float = 0.0
var speed: float = 0.0      # world px/s
var t: float = 0.0
var idle_w: float = 1.0
var blend: float = 0.0       # 0 walk .. 1 trot
var body: Node2D
var far_parts: Dictionary = {}
var last_hip: float = 0.0
var hip_vel: float = 0.0


func build(dir: String) -> void:
	load_rig(dir)
	body = make_bone("body", self, 0)
	# tail (behind body), head (behind body so the neck socket tucks in)
	var tb: Node2D = make_bone("tail_base", body, -3)
	tb.position = rest_vec("body", "tail")
	var tm: Node2D = make_bone("tail_mid", tb, 0)
	tm.position = rest_vec("tail_base", "end")
	var tt: Node2D = make_bone("tail_tip", tm, 0)
	tt.position = rest_vec("tail_mid", "end")
	var hd: Node2D = make_bone("head", body, -1)
	hd.position = rest_vec("body", "neck")
	# legs: near ones in front of the body, far ones behind
	for side: String in ["near", "far"]:
		var z0: int = 4 if side == "near" else -6
		var tint: Color = Color.WHITE if side == "near" else FAR_TINT
		_leg_chain(side, ["hind_thigh", "hind_shin", "hind_foot"], rest_vec("body", "hip"), z0, tint)
		_leg_chain(side, ["fore_upper", "fore_lower", "fore_paw"], rest_vec("body", "shoulder"), z0, tint)
	for i: int in 4:
		legs.append(GaitLeg.new(WALK["off"][i]))
	reset_stance()


## Duplicates a three-part chain for a side. Bone keys become "<side>_<part>".
func _leg_chain(side: String, names: Array, at: Vector2, z: int, tint: Color) -> void:
	var parent: Node2D = body
	var pos: Vector2 = at
	for i: int in names.size():
		var src: String = names[i]
		var key: String = side + "_" + src
		parts[key] = parts[src]
		var b: Node2D = make_bone(key, parent, z - i if side == "far" else z - i, tint)
		b.position = pos
		parent = b
		if i < names.size() - 1:
			pos = rest_vec(src, "end")


func reset_stance() -> void:
	# All four paws planted under their roots.
	var wx: float = world_x * D4
	for i: int in 4:
		var leg: GaitLeg = legs[i]
		var is_fore: bool = i % 2 == 1
		var root_x: float = _root_rest_x(is_fore)
		var foot: String = "fore_paw" if is_fore else "hind_foot"
		var heel_rel: float = (pt(foot, "heel") - pt(foot, "pivot")).x
		var spread: float = 6.0 if i < 2 else -6.0
		leg.plant = Vector2(wx + root_x + heel_rel + spread, 0.0)
		leg.cur_heel = leg.plant
		leg.stance = true
		leg.q = fposmod(phase - leg.offset, 1.0)


func _root_rest_x(is_fore: bool) -> float:
	# body pivot (hip hub) is placed so the rig origin is midway between hip and shoulder
	var hip: Vector2 = -rest_vec("body", "shoulder") * 0.5
	return hip.x + (rest_vec("body", "shoulder").x if is_fore else 0.0)


func _g(key: String) -> float:
	return lerpf(float(WALK[key]), float(TROT[key]), blend)


func step(dt: float, v: float) -> void:
	t += dt
	speed = v
	var moving: float = clampf(absf(v) / 40.0, 0.0, 1.0)
	idle_w = move_toward(idle_w, 1.0 - moving, dt * 3.0)
	blend = RigBase.smooth((absf(v) - WALK_SPEED) / (TROT_SPEED - WALK_SPEED))
	var L: float = _g("L")
	var duty: float = _g("duty")
	var dist: float = v * dt * D4
	world_x += v * dt
	phase = fposmod(phase + dist / L, 1.0)
	for i: int in 4:
		var leg: GaitLeg = legs[i]
		leg.offset = lerpf(float(WALK["off"][i]), float(TROT["off"][i]), blend)
		if v > 0.5:
			leg.advance(phase, duty)
	_pose(L, duty)


func _pose(L: float, duty: float) -> void:
	var wx: float = world_x * D4
	var bob_amp: float = _g("bob") * (1.0 - idle_w)
	# body heights: lowest at each diagonal/lateral support peak (twice per cycle)
	var breathe: float = sin(t * TAU / 3.2) * 1.2 * idle_w
	var hip_y: float = hip_h + breathe * 0.5 - bob_amp * (0.5 + 0.5 * cos(4.0 * PI * (phase - duty * 0.5)))
	var sh_y: float = sh_h + breathe - bob_amp * (0.5 + 0.5 * cos(4.0 * PI * (phase - 0.25 - duty * 0.5)))
	var hip_x: float = _root_rest_x(false)
	var sh_x: float = _root_rest_x(true)
	# solve feet first (they are world fixed in stance), then clamp heights so legs reach
	var feet: Array = []
	for i: int in 4:
		feet.append(_foot(i, L, duty, wx, hip_x if i % 2 == 0 else sh_x))
	for i: int in 4:
		var leg: GaitLeg = legs[i]
		if not leg.stance:
			continue
		var is_fore: bool = i % 2 == 1
		var reach: float = (bone_len("fore_upper") + bone_len("fore_lower") if is_fore else bone_len("hind_thigh") + bone_len("hind_shin")) * 0.985
		var j: Vector2 = feet[i]["pivot"]
		var rx: float = (sh_x if is_fore else hip_x)
		var allowed: float = -j.y + RigBase.max_height(j.x - rx, reach)
		if is_fore:
			sh_y = minf(sh_y, allowed)
		else:
			hip_y = minf(hip_y, allowed)
	# body transform
	var hip: Vector2 = Vector2(hip_x, -hip_y)
	var sh_target: Vector2 = Vector2(sh_x, -sh_y)
	var rho: float = (sh_target - hip).angle() - rest_vec("body", "shoulder").angle()
	body.position = hip
	body.rotation = rho
	abs_rot["body"] = rho
	var sh: Vector2 = hip + rest_vec("body", "shoulder").rotated(rho)
	# legs
	for i: int in 4:
		var side: String = "near" if i < 2 else "far"
		var is_fore: bool = i % 2 == 1
		var names: Array = ["fore_upper", "fore_lower", "fore_paw"] if is_fore else ["hind_thigh", "hind_shin", "hind_foot"]
		var root: Vector2 = sh if is_fore else hip
		var f: Dictionary = feet[i]
		var joint: Vector2 = RigBase.ik2(root, f["pivot"], bone_len(names[0]), bone_len(names[1]), -1.0 if is_fore else 1.0)
		var a0: float = aim_rot(names[0], "end", joint - root)
		var a1: float = aim_rot(names[1], "end", f["pivot"] - joint)
		set_abs(side + "_" + names[0], a0, rho)
		set_abs(side + "_" + names[1], a1, a0)
		set_abs(side + "_" + names[2], f["rot"], a1)
	# head: steady gaze with a small nod against the bob
	var nod: float = sin(TAU * phase * 2.0 + 0.6) * _g("head") * (1.0 - idle_w) + sin(t * TAU / 6.4) * 0.03 * idle_w
	set_abs("head", -0.10 * (1.0 - idle_w) + nod + 0.02, rho)
	# tail: droop plus a travelling wave
	var amp: float = _g("tail") * (1.0 - idle_w) + 0.06 * idle_w
	var freq: float = phase * TAU * 2.0 if idle_w < 0.5 else t * TAU / 3.2
	var base: float = -0.28 + 0.1 * blend * (1.0 - idle_w)
	var a_b: float = base + amp * sin(freq)
	var a_m: float = a_b + 0.10 + amp * 1.3 * sin(freq - 0.9)
	var a_t: float = a_m + 0.08 + amp * 1.6 * sin(freq - 1.8)
	set_abs("tail_base", rho + a_b, rho)
	set_abs("tail_mid", rho + a_m, rho + a_b)
	set_abs("tail_tip", rho + a_t, rho + a_m)


## Solves a foot: returns {pivot: rig-space wrist/hock, rot: foot rotation}.
func _foot(i: int, L: float, duty: float, wx: float, root_x: float) -> Dictionary:
	var leg: GaitLeg = legs[i]
	var is_fore: bool = i % 2 == 1
	var foot: String = "fore_paw" if is_fore else "hind_foot"
	var heel_v: Vector2 = pt(foot, "heel")
	var toe_v: Vector2 = pt(foot, "toe")
	var piv_v: Vector2 = pt(foot, "pivot")
	var roll_max: float = _g("roll_f") if is_fore else _g("roll_h")
	var heel: Vector2
	var rot: float = 0.0
	if leg.stance:
		var su: float = leg.stance_u(duty) if speed > 0.5 else 0.0
		rot = roll_max * RigBase.smooth((su - 0.62) / 0.38) * (1.0 - idle_w)
		var toe_w: Vector2 = leg.plant + (toe_v - heel_v)
		heel = toe_w + (heel_v - toe_v).rotated(rot)
	else:
		var u: float = leg.swing_u(duty)
		var reach: float = (_g("reach_f") if is_fore else _g("reach_h")) + duty * L * 0.5
		var heel_rel_mid: float = (heel_v - piv_v).x
		var bx: float = wx + root_x + (1.0 - leg.q) * L + heel_rel_mid + reach
		var e: float = RigBase.smooth(u)
		var lift_h: float = _g("lift_f") if is_fore else _g("lift_h")
		heel = Vector2(lerpf(leg.lift.x, bx, e), lerpf(leg.lift.y, 0.0, RigBase.smooth(u * 1.15)) - lift_h * pow(sin(PI * u), 1.3))
		var curl: float = _g("curl_f") if is_fore else _g("curl_h")
		rot = lerpf(leg.lift_rot, 0.0, RigBase.smooth(u * 1.6)) + curl * sin(PI * minf(u * 1.25, 1.0)) * (1.0 - u * 0.2)
		# keep the toe above the floor
		var toe_p: Vector2 = heel + (toe_v - heel_v).rotated(rot)
		var low: float = maxf(toe_p.y, heel.y)
		if low > 0.0:
			heel.y -= low
	leg.cur_heel = heel
	leg.cur_rot = rot
	var pivot: Vector2 = heel + (piv_v - heel_v).rotated(rot)
	return {"pivot": Vector2(pivot.x - wx, pivot.y), "rot": rot, "heel": heel}
