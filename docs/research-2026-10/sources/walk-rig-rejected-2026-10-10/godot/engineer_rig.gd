class_name EngineerRig
extends RigBase
## The engineer as a jointed cut-out (head, torso, backpack, two-piece arms and legs per side).
## Procedural gait: phase advances by distance walked / stride length, so planted boots never
## slide; the shin-and-boot is rigid and rolls heel -> flat -> toe while planted. Walk and jog
## curves blend by speed; idle breathes and shifts weight slowly.

const WALK_SPEED: float = 100.0   # world px/s
const JOG_SPEED: float = 190.0
const WALK = {"L": 270.0, "duty": 0.6, "lift": 22.0, "lift_peak": 0.35, "hip": 146.0, "bob": 3.5,
		"lean": 0.04, "arm": 0.32, "elbow": 0.22, "elbow_osc": 0.28, "reach": 6.0, "head": -0.02, "kick": 0.0}
const JOG = {"L": 480.0, "duty": 0.36, "lift": 46.0, "lift_peak": 0.42, "hip": 140.0, "bob": -6.0,
		"lean": 0.13, "arm": 0.55, "elbow": 1.25, "elbow_osc": 0.35, "reach": 12.0, "head": -0.07, "kick": 26.0}

var legs: Array = []        # [near, far]
var leg_names: Array = [["near_thigh", "near_shin"], ["far_thigh", "far_shin"]]
var phase: float = 0.0
var speed: float = 0.0
var t: float = 0.0
var idle_w: float = 1.0
var blend: float = 0.0
var pelvis: Node2D
var torso: Node2D
var hip_rest: Dictionary = {}
var last_hip_y: float = 0.0
var pack_vel: float = 0.0
var pack_rot: float = 0.0
var swing_phase_lag: float = 0.06


func build(dir: String) -> void:
	load_rig(dir)
	pelvis = Node2D.new()
	pelvis.name = "pelvis"
	add_child(pelvis)
	torso = make_bone("torso", pelvis, 0)
	var hd: Node2D = make_bone("head", torso, 1)
	hd.position = rest_vec("torso", "neck")
	var pk: Node2D = make_bone("backpack", torso, -5)
	pk.position = rest_vec("torso", "pack")
	var nu: Node2D = make_bone("near_upper", torso, 4)
	nu.position = rest_vec("torso", "shoulder")
	var nf: Node2D = make_bone("near_fore", nu, -1)
	nf.position = rest_vec("near_upper", "end")
	var fu: Node2D = make_bone("far_upper", torso, -8, Color(0.70, 0.72, 0.80))
	fu.position = rest_vec("torso", "shoulder") + Vector2(6, 0)
	var ff: Node2D = make_bone("far_fore", fu, -1, Color(0.70, 0.72, 0.80))
	ff.position = rest_vec("far_upper", "end")
	var tz: Array = [[-2, -3], [-6, -7]]
	var hip_dx: Array = [2.0, -2.0]
	for i: int in 2:
		var th: Node2D = make_bone(leg_names[i][0], pelvis, tz[i][0], Color.WHITE if i == 0 else Color(0.72, 0.74, 0.82))
		th.position = Vector2(hip_dx[i], 0)
		var sh: Node2D = make_bone(leg_names[i][1], th, tz[i][1] - tz[i][0], Color.WHITE if i == 0 else Color(0.72, 0.74, 0.82))
		sh.position = rest_vec(leg_names[i][0], "end")
		legs.append(GaitLeg.new(0.0 if i == 0 else 0.5))
	reset_stance()


func reset_stance() -> void:
	var wx: float = world_x * D4
	var spread: Array = [6.0, 2.0]
	for i: int in 2:
		var leg: GaitLeg = legs[i]
		var shin: String = leg_names[i][1]
		leg.plant = Vector2(wx + (pt(shin, "heel") - pt(shin, "pivot")).x + spread[i], 0.0)
		leg.cur_heel = leg.plant
		leg.stance = true
		leg.q = fposmod(phase - leg.offset, 1.0)


func _g(key: String) -> float:
	return lerpf(float(WALK[key]), float(JOG[key]), blend)


func step(dt: float, v: float) -> void:
	t += dt
	speed = v
	var moving: float = clampf(absf(v) / 30.0, 0.0, 1.0)
	idle_w = move_toward(idle_w, 1.0 - moving, dt * 4.0)
	blend = RigBase.smooth((absf(v) - WALK_SPEED) / (JOG_SPEED - WALK_SPEED))
	var L: float = _g("L")
	var duty: float = _g("duty")
	world_x += v * dt
	phase = fposmod(phase + v * dt * D4 / L, 1.0)
	if v > 0.5:
		for leg: GaitLeg in legs:
			leg.advance(phase, duty)
	_pose(dt, L, duty)


func _pose(dt: float, L: float, duty: float) -> void:
	var wx: float = world_x * D4
	var mv: float = 1.0 - idle_w
	# idle: slow weight shift (hips sway over the planted boots) and breathing
	var shift: float = sin(t * TAU / 6.4)
	var breathe: float = sin(t * TAU / 3.2)
	var hip_x: float = shift * 3.0 * idle_w
	var bob: float = _g("bob") * cos(4.0 * PI * (phase - duty * 0.5)) * mv
	var hip_y: float = lerpf(151.0 - absf(shift) * 1.0, _g("hip"), mv) + bob
	# solve feet, then lower the hips just enough that every planted boot is reachable
	var feet: Array = []
	for i: int in 2:
		feet.append(_foot(i, L, duty, wx, hip_x))
	for i: int in 2:
		var leg: GaitLeg = legs[i]
		if not leg.stance:
			continue
		var th: String = leg_names[i][0]
		var sh: String = leg_names[i][1]
		var reach: float = (bone_len(th) + rest_vec(sh, "heel").length()) * lerpf(0.997, 0.992, mv)
		var hx: float = hip_x + (2.0 if i == 0 else -2.0)
		var allowed: float = RigBase.max_height(feet[i]["heel"].x - wx - hx, reach)
		var reach_t: float = (bone_len(th) + rest_vec(sh, "toe").length()) * lerpf(0.997, 0.992, mv)
		var toe_w: Vector2 = leg.plant + (pt(sh, "toe") - pt(sh, "heel"))
		allowed = maxf(allowed, RigBase.max_height(toe_w.x - wx - hx, reach_t))
		hip_y = minf(hip_y, allowed)
	pelvis.position = Vector2(hip_x, -hip_y)
	# torso lean, breathing
	var lean: float = _g("lean") * mv + 0.012 * sin(4.0 * PI * phase + 0.4) * mv + 0.008 * shift * idle_w
	torso.rotation = lean
	abs_rot["torso"] = lean
	var b: float = 0.010 * breathe * idle_w
	sprites["torso"].scale = Vector2(1.0, 1.0 + b)
	for k: String in ["head", "near_upper", "far_upper", "backpack"]:
		var base: Vector2 = rest_vec("torso", "neck" if k == "head" else ("pack" if k == "backpack" else "shoulder"))
		if k == "far_upper":
			base += Vector2(6, 0)
		bones[k].position = Vector2(base.x, base.y * (1.0 + b))
	# legs
	for i: int in 2:
		var th: String = leg_names[i][0]
		var sh: String = leg_names[i][1]
		var hip: Vector2 = pelvis.position + bones[th].position
		var f: Dictionary = feet[i]
		var target: Vector2 = Vector2(f["heel"].x - wx, f["heel"].y)
		var key: String = "heel"
		var knee: Vector2 = RigBase.ik2(hip, target, bone_len(th), rest_vec(sh, "heel").length(), 1.0)
		var a1: float = aim_rot(sh, "heel", target - knee)
		if leg_names.size() > 0 and legs[i].stance and a1 > 0.0:
			# rolled onto the toe: solve to the planted toe instead
			var toe_w: Vector2 = legs[i].plant + (pt(sh, "toe") - pt(sh, "heel"))
			target = Vector2(toe_w.x - wx, 0.0)
			knee = RigBase.ik2(hip, target, bone_len(th), rest_vec(sh, "toe").length(), 1.0)
			a1 = aim_rot(sh, "toe", target - knee)
			key = "toe"
		elif not legs[i].stance:
			# keep the toe cap above the floor while swinging
			for _k: int in 2:
				var toe_p: Vector2 = knee + rest_vec(sh, "toe").rotated(a1)
				if toe_p.y <= 0.0:
					break
				target.y -= toe_p.y
				knee = RigBase.ik2(hip, target, bone_len(th), rest_vec(sh, "heel").length(), 1.0)
				a1 = aim_rot(sh, "heel", target - knee)
		var a0: float = aim_rot(th, "end", knee - hip)
		set_abs(th, a0, 0.0)
		set_abs(sh, a1, a0)
		# record the solved heel for lift-off / touchdown bookkeeping
		var heel_rig: Vector2 = knee + rest_vec(sh, "heel").rotated(a1) if key == "toe" else target
		legs[i].cur_heel = Vector2(heel_rig.x + wx, heel_rig.y)
		legs[i].cur_rot = a1
	# arms swing opposite the legs, with a small follow-through lag
	var arm_amp: float = _g("arm") * mv
	var c: float = cos(TAU * (phase - swing_phase_lag))
	var sway: float = 0.03 * sin(t * TAU / 6.4 - 0.8) * idle_w + 0.02 * breathe * idle_w
	var flex0: float = lerpf(0.16, _g("elbow"), mv)
	var arms: Array = [["near_upper", "near_fore", 1.0], ["far_upper", "far_fore", -1.0]]
	for a: Array in arms:
		var swing: float = a[2] * arm_amp * c + sway + 0.04 * mv
		var up_abs: float = lean + swing
		set_abs(a[0], up_abs, lean)
		var fwd: float = clampf(-a[2] * c, 0.0, 1.0)
		var flex: float = flex0 + _g("elbow_osc") * fwd * mv
		set_abs(a[1], up_abs - flex, up_abs)
	# head keeps the gaze level against the lean
	var nod: float = 0.015 * sin(4.0 * PI * phase - 0.5) * mv + 0.012 * sin(t * TAU / 3.2) * idle_w
	set_abs("head", -lean * 0.75 + _g("head") * mv * 0.3 + nod, lean)
	# backpack: a little lag on the hip's vertical motion (secondary motion)
	var vy: float = (hip_y - last_hip_y) / maxf(dt, 0.001)
	last_hip_y = hip_y
	var target_rot: float = clampf(-vy * 0.0016, -0.06, 0.06)
	pack_vel += (target_rot - pack_rot) * 120.0 * dt - pack_vel * 14.0 * dt
	pack_rot += pack_vel * dt
	set_abs("backpack", lean + pack_rot, lean)


## Heel point of a boot (world D4 x, screen y) for this frame.
func _foot(i: int, L: float, duty: float, wx: float, hip_x: float) -> Dictionary:
	var leg: GaitLeg = legs[i]
	var sh: String = leg_names[i][1]
	if leg.stance:
		return {"heel": leg.plant}
	var u: float = leg.swing_u(duty)
	var heel_rel_mid: float = (pt(sh, "heel") - pt(sh, "pivot")).x
	var bx: float = wx + hip_x + (1.0 - leg.q) * L + heel_rel_mid + duty * L * 0.5 + _g("reach")
	var e: float = RigBase.smooth(u)
	var peak: float = _g("lift_peak")
	var shape: float = sin(PI * pow(u, log(0.5) / log(peak)))
	var hx: float = lerpf(leg.lift.x, bx, e) - _g("kick") * sin(PI * minf(u * 1.6, 1.0)) * (1.0 - u)
	var hy: float = lerpf(leg.lift.y, 0.0, RigBase.smooth(u * 1.2)) - _g("lift") * shape
	return {"heel": Vector2(hx, minf(hy, 0.0))}
