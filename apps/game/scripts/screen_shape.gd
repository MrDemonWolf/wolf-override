class_name ScreenShape
extends Node
## Owns the visible canvas and mobile safe rect in canvas px. It observes layout while paused too;
## consumers keep their own authored padding inside safe_rect. Desktop never uses monitor work areas.

signal shape_changed(visible: Rect2, safe: Rect2)

var visible_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height")))
var safe_rect: Rect2 = visible_rect


## Connects viewport resizing; mobile also polls because a cutout can change sides without resizing.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size_changed.connect(refresh)
	set_process(OS.has_feature("ios") or OS.has_feature("android"))
	refresh()


## Reads platform insets without changing the viewport, camera, or saved preferences.
func _process(_delta: float) -> void:
	refresh()


## Refreshes cached canvas rectangles; emits only when either changed, including while menus pause play.
func refresh() -> void:
	var visible: Rect2 = get_viewport().get_visible_rect()
	var safe: Rect2 = visible
	if OS.has_feature("ios") or OS.has_feature("android"):
		safe = canvas_safe_rect(visible, Rect2(DisplayServer.get_display_safe_area()), get_viewport().get_screen_transform())
	if visible == visible_rect and safe == safe_rect:
		return
	visible_rect = visible
	safe_rect = safe
	shape_changed.emit(visible_rect, safe_rect)


## Converts the OS safe area (screen px) through the viewport's screen transform, including bars/scale.
## An unavailable or empty OS result falls back to the visible canvas; it never produces a zero-size UI.
static func canvas_safe_rect(visible: Rect2, screen_safe: Rect2, canvas_to_screen: Transform2D) -> Rect2:
	if not screen_safe.has_area():
		return visible
	var safe: Rect2 = visible.intersection(canvas_to_screen.affine_inverse() * screen_safe)
	return safe if safe.has_area() else visible
