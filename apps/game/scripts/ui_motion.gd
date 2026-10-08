class_name UIMotion
extends RefCounted
## Hover, focus and press motion shared by every menu button.
## Tweens only touch scale around the control's centre and stay at or under 0.1 s, so they never
## hold up input and read as a nudge rather than an animation for players who want little motion.

const LIFT_SCALE: Vector2 = Vector2(1.025, 1.025)
const PRESS_SCALE: Vector2 = Vector2(0.965, 0.965)
const LIFT_SECONDS: float = 0.1
const PRESS_SECONDS: float = 0.06


static func attach(button: BaseButton) -> void:
	_centre_pivot(button)
	button.resized.connect(_centre_pivot.bind(button))
	button.mouse_entered.connect(_settle.bind(button))
	button.mouse_exited.connect(_settle.bind(button))
	button.focus_entered.connect(_settle.bind(button))
	button.focus_exited.connect(_settle.bind(button))
	button.button_down.connect(_scale_to.bind(button, PRESS_SCALE, PRESS_SECONDS))
	button.button_up.connect(_settle.bind(button))


static func _centre_pivot(button: BaseButton) -> void:
	button.pivot_offset = button.size * 0.5


## Rest slightly lifted while hovered or focused, otherwise return to the normal size.
static func _settle(button: BaseButton) -> void:
	var raised: bool = button.is_hovered() or button.has_focus()
	_scale_to(button, LIFT_SCALE if raised else Vector2.ONE, LIFT_SECONDS)


static func _scale_to(button: BaseButton, target: Vector2, seconds: float) -> void:
	if button.has_meta(&"ui_motion_tween"):
		var previous: Tween = button.get_meta(&"ui_motion_tween") as Tween
		if previous != null and previous.is_running():
			previous.kill()
	if not button.is_inside_tree():
		button.scale = target
		return
	# Menus animate while the tree is paused, so the tween keeps processing regardless of pause mode.
	var tween: Tween = button.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(button, "scale", target, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	button.set_meta(&"ui_motion_tween", tween)
