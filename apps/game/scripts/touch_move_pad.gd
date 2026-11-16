class_name TouchMovePad
extends Control
## Owns one horizontal thumb gesture in canvas px. It reports an axis in -1..1 and never injects
## InputMap actions, changes a puzzle, or steals a touch already assigned to an object or UI button.

signal axis_changed(value: float)

## The reviewed mockup thumb occupies 40 percent of its ring diameter.
const THUMB_RATIO: float = 0.4

## Touch indices are nonnegative; -1 means the pad has no owner.
const NO_FINGER: int = -1
var finger: int = NO_FINGER
var axis: float = 0.0
var origin: Vector2 = Vector2.ZERO
var offset: Vector2 = Vector2.ZERO
var zone: Rect2
var radius: float = 0.0
var _deadzone: float = 1.0
var enabled: bool = false:
	set(value):
		enabled = value
		if not value:
			cancel()


## Leaves GUI routing to Main/WorldInput so objects get first refusal before an empty pad zone.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A hidden or removed overlay cannot retain a moving thumb.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		cancel()


## Sets the left-hand catch zone from the shared profile and a diameter in canvas px. A geometry or
## dead-zone change cancels the gesture; repeated identical layouts leave the current thumb alone.
func configure(safe: Rect2, diameter: float, deadzone: float) -> void:
	var next_zone: Rect2 = Rect2(safe.position, Vector2(safe.size.x * UiTokens.number("profile.phone.move-zone"), safe.size.y)) if safe.has_area() else Rect2()
	var next_radius: float = minf(maxf(diameter, 0.0) * 0.5, minf(next_zone.size.x, next_zone.size.y) * 0.5) if is_finite(diameter) else 0.0
	var next_deadzone: float = clampf(deadzone, 0.0, 1.0) if is_finite(deadzone) else 1.0
	if not zone.is_equal_approx(next_zone) or not is_equal_approx(radius, next_radius) or not is_equal_approx(_deadzone, next_deadzone):
		cancel()
	zone = next_zone
	radius = next_radius
	_deadzone = next_deadzone
	queue_redraw()


## Called only after UI and object hit tests declined the press. A second finger never takes over.
func begin(event: InputEventScreenTouch) -> bool:
	if not enabled or not is_visible_in_tree() or finger != NO_FINGER or event.index < 0 or not event.pressed or event.canceled or radius <= 0.0 or not zone.has_point(event.position):
		return false
	finger = event.index
	origin = event.position
	offset = Vector2.ZERO
	_set_axis(0.0)
	queue_redraw()
	return true


## Watches the owning touch before GUI consumes releases. Vertical motion is ignored in this side-view
## game; leaving the catch zone during a held drag is allowed, with horizontal travel clamped.
func observe(event: InputEvent) -> void:
	if InputMode.navigation_press(event):
		cancel()
	elif event is InputEventScreenTouch and event.index == finger and (not event.pressed or event.canceled):
		cancel()
	elif event is InputEventScreenDrag and event.index == finger and finger != NO_FINGER:
		offset = Vector2(clampf(event.position.x - origin.x, -radius, radius), 0.0)
		queue_redraw()
		var raw: float = offset.x / radius
		_set_axis(0.0 if absf(raw) <= _deadzone else signf(raw) * (absf(raw) - _deadzone) / (1.0 - _deadzone))


## Drops only this thumb's axis; physical keyboard/controller actions stay owned by InputMap.
func cancel() -> void:
	finger = NO_FINGER
	queue_redraw()
	offset = Vector2.ZERO
	_set_axis(0.0)


## Emits only changed values so neutral redraw/layout work cannot repeatedly command movement.
func _set_axis(value: float) -> void:
	if not is_equal_approx(axis, value):
		axis = value
		axis_changed.emit(value)


## The drawn centre in local canvas px, shared by rendering and overlay protection.
func _centre() -> Vector2:
	return origin if finger != NO_FINGER else Vector2(zone.get_center().x, zone.end.y - radius * 2.0)


## Bounds the ring and protruding thumb in local px, including half the 2 px ring stroke.
func visual_rect() -> Rect2:
	if radius <= 0.0:
		return Rect2()
	var centre: Vector2 = _centre()
	var thumb_radius: float = radius * THUMB_RATIO
	return Rect2(centre - Vector2.ONE * radius, Vector2.ONE * radius * 2.0).merge(Rect2(centre + offset - Vector2.ONE * thumb_radius, Vector2.ONE * thumb_radius * 2.0)).grow(1.0)


## Draws a quiet idle ring, then follows the owning thumb; positions and radii use canvas px.
func _draw() -> void:
	if radius <= 0.0:
		return
	var centre: Vector2 = _centre()
	draw_circle(centre, radius, UiTokens.color("color.role.touch.bg"))
	draw_arc(centre, radius, 0.0, TAU, 48, UiTokens.color("color.role.touch.border"), 2.0, true)
	draw_circle(centre + offset, radius * THUMB_RATIO, UiTokens.color("color.role.touch.border"))
