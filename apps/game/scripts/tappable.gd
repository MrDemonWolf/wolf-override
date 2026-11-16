class_name Tappable
extends Node
## One click/tap target shared by its art and labels. Rectangles are measured in live canvas px,
## so camera movement, text size and screen shape never need a second hit-box layout.

enum Kind { WORLD, DIALOGUE, OBJECTIVE, USE }
## Brief B11 target floors: 24 canvas px for a mouse, 58 for phone touch. Larger art keeps its bounds.
const MOUSE_MIN: float = 24.0
const TOUCH_MIN: float = 58.0
## Provisional feedback strengths; timing reuses the existing button-motion tokens.
const HOVER_GAIN: float = 1.12
const PRESS_GAIN: float = 0.88

var id: StringName
var chapters: PackedStringArray
var regions: Array[CanvasItem] = []
var kind: Kind = Kind.WORLD
var hold_station: StringName = &""
var enabled: Callable
## Optional restrictions distinguish a doorway from its bolt without expanding the existing USE reach.
var reached: Callable
var approach: Callable
var _base: Color = Color.WHITE
var _feedback: int = 0
var _tween: Tween


## Captures authored tint once. The first region is the art; further regions are its clickable labels.
func setup(target_id: StringName, rooms: PackedStringArray, items: Array[CanvasItem], hold: StringName = &"") -> void:
	id = target_id
	chapters = rooms
	regions = items
	hold_station = hold
	_base = regions[0].self_modulate


## Live art/label bounds in canvas px, shared by hit testing and HUD avoidance; unsupported items return empty.
## Visibility and minimum hit areas belong to the caller, so this never changes authored geometry.
static func canvas_rect(item: CanvasItem) -> Rect2:
	if item is Control:
		return item.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, item.size)
	if item is Sprite2D:
		return item.get_global_transform_with_canvas() * item.get_rect()
	return Rect2()


## Distance score for a visible region under [param point] (canvas px), or INF when none is hit.
## Actual art/label bounds win over a neighbouring target's enlarged touch margin.
func hit_score(point: Vector2, touch: bool) -> float:
	var best: float = INF
	for item: CanvasItem in regions:
		if not is_instance_valid(item) or not item.is_visible_in_tree() or item.modulate.a < 0.05 or item.self_modulate.a < 0.05:
			continue
		if not (item is Control or item is Sprite2D):
			continue
		var rect: Rect2 = canvas_rect(item)
		var size: Vector2 = rect.size.max(Vector2.ONE * (TOUCH_MIN if touch else MOUSE_MIN))
		var expanded: Rect2 = Rect2(rect.get_center() - size * 0.5, size)
		if expanded.has_point(point):
			var score: float = point.distance_squared_to(rect.get_center())
			if not rect.has_point(point):
				score += 1000000.0
			best = minf(best, score)
	return best


## Brightens on hover and dips on press without moving painted art off the floor or recolouring it.
func feedback(hovered: bool, pressed: bool, reduced_motion: bool) -> void:
	var state: int = 2 if pressed else (1 if hovered else 0)
	if state == _feedback:
		return
	_feedback = state
	var tint: Color = _base * (PRESS_GAIN if pressed else (HOVER_GAIN if hovered else 1.0))
	tint.a = _base.a
	if reduced_motion:
		Tweens.kill(_tween)
		regions[0].self_modulate = tint
	else:
		_tween = Tweens.restart(self, _tween)
		_tween.tween_property(regions[0], "self_modulate", tint, UIMotion.PRESS_SECONDS if pressed else UIMotion.LIFT_SECONDS)
