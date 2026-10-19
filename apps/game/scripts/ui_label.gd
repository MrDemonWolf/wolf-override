class_name UILabel
extends RefCounted
## Builds the fixed-place captions that menu cards draw at an exact rect: the end card's title,
## thanks and recap header (Main) and the debug menu's title, status, note and hint (DebugMenu).
## Both cards lay out by hand in card px, so a container would not place them where their art expects.


## Adds a Label to [param parent] at [param rect] (parent px) reading [param text], at
## [param font_size] px in [param tint]. It ignores the mouse, so clicks and taps pass through to
## the card under it. Returns the label for callers that align it or change its text later.
static func place(parent: Control, text: String, rect: Rect2, font_size: int, tint: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
