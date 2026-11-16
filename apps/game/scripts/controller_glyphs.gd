class_name ControllerGlyphs
extends RefCounted
## Maps physical SDL/Godot inputs to the registered Kenney-derived font; never remaps an action.

## Pinned 1.5a font from univeous commit a487aade870c1a7e66e9924c77bd8e276cb68f48.
const FONT_PATH: String = "res://assets/fonts/Input-Prompt-Icons.ttf"
## Lookup order is physical button position. Nintendo south/east and west/north letters are swapped.
const BUTTON_KEYS: Array[int] = [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_BACK, JOY_BUTTON_START, JOY_BUTTON_LEFT_STICK, JOY_BUTTON_RIGHT_STICK, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]
## Codepoints read from that font with hb-info --list-unicodes; PlayStation menu/create art is PS5 style.
const BUTTONS: Dictionary = {
	&"xbox": [0xE511, 0xE513, 0xE52B, 0xE52D, 0xE529, 0xE521, 0xE560, 0xE568, 0xE550, 0xE556, 0xE542, 0xE531, 0xE535, 0xE538],
	&"playstation": [0xE376, 0xE36C, 0xE37C, 0xE37E, 0xE349, 0xE34F, 0xE378, 0xE37A, 0xE3A3, 0xE3AB, 0xE38B, 0xE382, 0xE386, 0xE389],
	&"nintendo": [0xE203, 0xE201, 0xE217, 0xE215, 0xE209, 0xE20B, 0xE25B, 0xE263, 0xE207, 0xE20D, 0xE239, 0xE230, 0xE234, 0xE237],
	&"steam_deck": [0xE418, 0xE41A, 0xE434, 0xE436, 0xE432, 0xE426, 0xE44B, 0xE453, 0xE41E, 0xE42A, 0xE443, 0xE43A, 0xE43E, 0xE441],
}

## Axis order follows native constants; trigger negative halves deliberately keep the textual fallback.
const AXIS_KEYS: Array[int] = [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y, JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]
const AXES: Dictionary = {
	&"xbox": [[0xE55F, 0xE561], [0xE562, 0xE55D], [0xE567, 0xE569], [0xE56A, 0xE565], [0, 0xE554], [0, 0xE55A]],
	&"playstation": [[0xE392, 0xE394], [0xE395, 0xE390], [0xE39A, 0xE39C], [0xE39D, 0xE398], [0, 0xE3A7], [0, 0xE3AF]],
	&"nintendo": [[0xE25A, 0xE25C], [0xE25D, 0xE258], [0xE262, 0xE264], [0xE265, 0xE260], [0, 0xE219], [0, 0xE21B]],
	&"steam_deck": [[0xE44A, 0xE44C], [0xE44D, 0xE448], [0xE452, 0xE454], [0xE455, 0xE450], [0, 0xE420], [0, 0xE42C]],
}


## Returns one icon character for a physical button, or empty for an unmapped/system button.
static func button(family: StringName, index: int) -> String:
	var at: int = BUTTON_KEYS.find(index)
	return String.chr(BUTTONS.get(family, BUTTONS[&"xbox"])[at]) if at >= 0 else ""


## Returns a direction-specific icon for an axis value (-1..1), or empty for an unsupported axis/half.
static func axis(family: StringName, index: int, value: float) -> String:
	var at: int = AXIS_KEYS.find(index)
	if at < 0:
		return ""
	var codepoint: int = AXES.get(family, AXES[&"xbox"])[at][0 if value < 0.0 else 1]
	return String.chr(codepoint) if codepoint > 0 else ""
