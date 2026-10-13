class_name GaitLeg
extends RefCounted
## One leg's stance/swing state. All x values are world D4 px (4 per world px); y is height above
## the floor (positive up), so the floor is y = 0.

var offset: float = 0.0        # phase at which this leg touches down
var stance: bool = true
var q: float = 0.0             # this leg's phase, 0 = touchdown
var plant: Vector2 = Vector2.ZERO   # contact "heel" point while planted (world D4, height)
var lift: Vector2 = Vector2.ZERO    # heel point at lift-off
var lift_rot: float = 0.0           # foot rotation at lift-off
var cur_heel: Vector2 = Vector2.ZERO  # last solved heel point (world D4, height)
var cur_rot: float = 0.0


func _init(phase_offset: float) -> void:
	offset = phase_offset


## Advances the leg's state for global phase p. Returns true when the state changed.
func advance(p: float, duty: float) -> void:
	var q_new: float = fposmod(p - offset, 1.0)
	var wrapped: bool = q_new < q - 0.5
	if stance:
		if q_new >= duty and not wrapped:
			stance = false
			lift = cur_heel
			lift_rot = cur_rot
	else:
		if wrapped or q_new < duty and q_new < q:
			stance = true
			plant = Vector2(cur_heel.x, 0.0)
	q = q_new


## Swing progress 0..1 (only meaningful in swing).
func swing_u(duty: float) -> float:
	return clampf((q - duty) / maxf(1.0 - duty, 0.001), 0.0, 1.0)


## Stance progress 0..1.
func stance_u(duty: float) -> float:
	return clampf(q / maxf(duty, 0.001), 0.0, 1.0)
