class_name DialogueBark
extends RefCounted
## Places the existing timed dialogue panel above its speaker without moving controls or camera.


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
		var blocked: bool = false
		for obstacle: Rect2 in obstacles:
			if full.grow(gap).intersects(obstacle):
				panel.position.y = floorf(obstacle.position.y - gap - panel_size.y)
				blocked = true
				break
		if not blocked:
			return panel
	return Rect2()
