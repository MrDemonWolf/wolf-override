class_name DialogueBark
extends RefCounted
## Places speech and action panels around canvas anchors without moving controls or camera.


## Returns a panel rect in canvas px, including room above it for the name tab; an empty rect asks
## the caller to keep its lower reading position. Off-screen speakers never acquire a false anchor.
static func place(panel_size: Vector2, tab_height: float, body: Rect2, safe: Rect2, obstacles: Array[Rect2], gap: float) -> Rect2:
	if not safe.has_point(body.get_center()) or panel_size.x > safe.size.x:
		return Rect2()
	var x: float = clampf(roundf(body.get_center().x - panel_size.x * 0.5), safe.position.x, safe.end.x - panel_size.x)
	var panel: Rect2 = Rect2(Vector2(x, floorf(body.position.y - gap - panel_size.y)), panel_size)
	# Raise above a neighbour's head or a warning before giving up on the speaker anchor.
	for _attempt: int in obstacles.size() + 1:
		var full: Rect2 = Rect2(panel.position - Vector2(0.0, tab_height), panel.size + Vector2(0.0, tab_height))
		if not safe.encloses(full):
			return Rect2()
		var blocker: Rect2 = _first_blocker(full, obstacles, gap)
		if not blocker.has_area():
			return panel
		panel.position.y = floorf(blocker.position.y - gap - panel_size.y)
	return Rect2()


## True when a canvas rect stays in safe and clears every obstacle by gap canvas px.
static func is_clear(rect: Rect2, safe: Rect2, obstacles: Array[Rect2], gap: float) -> bool:
	return safe.encloses(rect) and not _first_blocker(rect, obstacles, gap).has_area()


## An anchored action first tries the existing above-body placement, then at most 25 bounded alternatives.
## Returns empty when no safe space exists; ordinary speech keeps place()'s original lower-reading fallback.
static func place_near(panel_size: Vector2, body: Rect2, safe: Rect2, obstacles: Array[Rect2], gap: float) -> Rect2:
	if not body.has_area() or not safe.has_point(body.get_center()) or panel_size.x > safe.size.x or panel_size.y > safe.size.y:
		return Rect2()
	var blocked: Array[Rect2] = obstacles.duplicate()
	blocked.append(body)
	var above: Rect2 = place(panel_size, 0.0, body, safe, blocked, gap)
	if above.has_area():
		return above
	var xs: Array[float] = [body.get_center().x - panel_size.x * 0.5, body.position.x - gap - panel_size.x, body.end.x + gap, safe.position.x, safe.end.x - panel_size.x]
	var ys: Array[float] = [body.position.y - gap - panel_size.y, body.end.y + gap, body.get_center().y - panel_size.y * 0.5, safe.position.y, safe.end.y - panel_size.y]
	var best: Rect2
	var distance: float = INF
	for x: float in xs:
		for y: float in ys:
			var candidate: Rect2 = Rect2(Vector2(clampf(x, safe.position.x, safe.end.x - panel_size.x), clampf(y, safe.position.y, safe.end.y - panel_size.y)), panel_size)
			var cost: float = candidate.get_center().distance_squared_to(body.get_center())
			if cost < distance and is_clear(candidate, safe, blocked, gap):
				best = candidate
				distance = cost
	return best


## First canvas obstacle inside the requested gap; empty means none, with no state changes.
static func _first_blocker(rect: Rect2, obstacles: Array[Rect2], gap: float) -> Rect2:
	for obstacle: Rect2 in obstacles:
		if rect.grow(gap).intersects(obstacle):
			return obstacle
	return Rect2()
