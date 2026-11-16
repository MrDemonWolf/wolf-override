class_name ScreenShape
extends Node
## Bounds the visible canvas from 4:3 to 2.4:1 and owns the mobile safe rect in canvas px;
## consumers keep their own authored padding inside safe_rect. Desktop never uses monitor work areas.

signal shape_changed(visible: Rect2, safe: Rect2)

## 4:3 leaves vertical art margin; 2.4 is the 960-world-px room at zoom 1.35 on a 540-px canvas.
const MIN_ASPECT: float = 4.0 / 3.0
const MAX_ASPECT: float = 2.4
static var design_size: Vector2i = Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))

var visible_rect: Rect2 = Rect2(Vector2.ZERO, design_size)
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
	var window: Window = get_window()
	var config: Dictionary = window_config(window.size)
	if window.content_scale_size != config["size"]:
		window.content_scale_size = config["size"]
	if window.content_scale_aspect != config["aspect"]:
		window.content_scale_aspect = config["aspect"]
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


## Base size and aspect mode for a window in screen px. Extreme screens get bars; gameplay zoom stays fixed.
static func window_config(size: Vector2i) -> Dictionary:
	var aspect: float = float(size.x) / maxf(size.y, 1.0)
	if aspect > MAX_ASPECT:
		return {"size": Vector2i(roundi(design_size.y * MAX_ASPECT), design_size.y), "aspect": Window.CONTENT_SCALE_ASPECT_KEEP}
	if aspect < MIN_ASPECT:
		return {"size": Vector2i(design_size.x, roundi(design_size.x / MIN_ASPECT)), "aspect": Window.CONTENT_SCALE_ASPECT_KEEP}
	return {"size": design_size, "aspect": Window.CONTENT_SCALE_ASPECT_EXPAND}


## Centre limits in world px for a view [param width] wide inside [param left]..[param right].
## A view wider than its room is centred, rather than passing inverted bounds to clampf.
static func centre_limits(left: float, right: float, width: float) -> Vector2:
	var half: float = width * 0.5
	return Vector2(left + half, right - half) if width <= right - left else Vector2.ONE * ((left + right) * 0.5)


## Keeps existing menu/logo compositions centred in the safe rect (canvas px), shrinking only when
## necessary. Cached authored rects prevent compounding; nested full-rect children follow their parent.
static func fit_authored(controls: Array[Control], safe: Rect2) -> void:
	var size: Vector2 = Vector2(design_size).min(safe.size)
	var factor: float = minf(size.x / design_size.x, size.y / design_size.y)
	var scale: Vector2 = Vector2.ONE * factor
	var origin: Vector2 = safe.get_center() - Vector2(design_size) * factor * 0.5
	for control: Control in controls:
		var home: Rect2 = authored_rect(control)
		var at: Vector2 = origin + home.position * scale
		var extent: Vector2 = home.size * scale
		set_rect(control, at, extent)


## The authored canvas rect before responsive placement; shared by grouped and edge-pinned layouts.
static func authored_rect(control: Control) -> Rect2:
	if not control.has_meta(&"screen_home"):
		control.set_meta(&"screen_home", Rect2(control.position, control.size))
	return control.get_meta(&"screen_home")


## Positions and sizes [param control] in canvas px, writing only changed values to avoid relayout each frame.
static func set_rect(control: Control, at: Vector2, size: Vector2) -> void:
	if control.position != at:
		control.position = at
	if control.size != size:
		control.size = size
