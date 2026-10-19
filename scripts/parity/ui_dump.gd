extends SceneTree
## UI parity dump (never shipped: run.sh copies it into a scratch copy of the game).
## Drives main.tscn through 13 menu and HUD states and writes, per visible Control under CanvasLayer,
## its class, global rect, theme-resolved font, size and colour, and stylebox description. Run it
## before and after a UI refactor and diff the two files: any line that changes is a visual change.
## Usage: scripts/parity/run.sh ui <out file>   (headless, --fixed-fps 60, so the waits are frames)

const Kit = preload("parity_kit.gd")
const SAVE: String = "user://parity-save.json"
const SETTINGS: String = "user://parity-settings.cfg"

var lines: PackedStringArray = []
var game: Node2D
## Nodes built at run time get names like @Label@124, whose number counts every node made so far:
## the dump keeps the class and drops the number, so only what is on screen is compared.
var auto_name: RegEx = RegEx.create_from_string("@(\\w+)@\\d+")


func _initialize() -> void:
	call_deferred("_run")


func _settle(frames: int) -> void:
	for i: int in frames:
		await process_frame


func _run() -> void:
	for path: String in [SAVE, SETTINGS]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var scene: PackedScene = load("res://scenes/main.tscn")
	game = scene.instantiate() as Node2D
	game.set("save_path", SAVE)
	game.set("settings_path", SETTINGS)
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	await _settle(40)
	_census()
	await _snap("title")
	game.call("_show_credits")
	await _settle(4)
	(game.get_node("CanvasLayer/TitleScreen/CreditsScreen/CreditsBody") as RichTextLabel).get_v_scroll_bar().value = 0.0
	await _snap("credits")
	game.call("_hide_credits")
	game.call("_show_changelog")
	await _settle(4)
	await _snap("changelog")
	game.call("_hide_changelog")
	game.call("_show_title_settings")
	await _settle(20)
	var menu: GameSettings = game.get("settings_menu") as GameSettings
	for i: int in 3:
		menu.select_tab(i)
		await _settle(4)
		await _snap("settings-tab%d" % i)
	(game.get_node("CanvasLayer/PauseOverlay/Panel/SettingsMenu/BackButton") as Button).pressed.emit()
	await _settle(10)
	game.call("_new_game")
	await _settle(30)
	await _snap("intro")
	game.call("_finish_intro")
	await _settle(30)
	await _snap("play-keyboard")
	game.set("touch_enabled", true)
	game.call("_refresh_ui")
	await _settle(4)
	await _snap("play-touch")
	game.set("waiting_for_choice", true)
	game.call("_refresh_ui")
	await _settle(4)
	await _snap("choice-touch")
	game.set("touch_enabled", false)
	game.call("_refresh_ui")
	await _settle(4)
	await _snap("choice-keyboard")
	game.set("waiting_for_choice", false)
	game.call("_pause_game")
	await _settle(20)
	await _snap("pause")
	game.call("_resume_game")
	await _settle(4)
	game.call("_show_end_card")
	await _settle(30)
	await _snap("end-card")
	var out: String = Kit.arg("out", "user://ui-dump.txt")
	var file: FileAccess = FileAccess.open(out, FileAccess.WRITE)
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("wrote ", lines.size(), " lines to ", out)
	quit()


func _census() -> void:
	var layer: Node = game.get_node("CanvasLayer")
	var controls: int = 0
	var all_nodes: int = 0
	for node: Node in layer.find_children("*", "", true, false):
		all_nodes += 1
		if node is Control:
			controls += 1
	lines.append("## census CanvasLayer nodes=%d controls=%d scene_nodes=%d" % [all_nodes, controls, game.find_children("*", "", true, false).size()])


func _box(box: StyleBox) -> String:
	if box == null:
		return "-"
	if box is StyleBoxFlat:
		var f: StyleBoxFlat = box
		return "Flat(bg=%s border=%s w=%d,%d,%d,%d r=%d shadow=%s/%d)" % [f.bg_color.to_html(), f.border_color.to_html(), f.border_width_left, f.border_width_top, f.border_width_right, f.border_width_bottom, f.corner_radius_top_left, f.shadow_color.to_html(), f.shadow_size]
	if box is StyleBoxTexture:
		return "Texture(%s)" % (box as StyleBoxTexture).texture.get_class()
	return box.get_class()


func _font(control: Control, size_name: String) -> String:
	var font: Font = control.get_theme_font("font" if size_name == "font_size" else "normal_font")
	var name: String = font.resource_path.get_file() if font != null else "-"
	if font is FontVariation:
		name += "@%s" % str((font as FontVariation).variation_opentype.get("weight", ""))
	return "%s/%d" % [name, control.get_theme_font_size(size_name)]


func _dump(state: String) -> void:
	lines.append("## state %s" % state)
	var layer: Node = game.get_node("CanvasLayer")
	for node: Node in layer.find_children("*", "Control", true, false):
		var control: Control = node as Control
		if not control.is_visible_in_tree():
			continue
		var rect: Rect2 = control.get_global_rect()
		var entry: String = "%s %s rect=(%.1f,%.1f %.1fx%.1f) mod=%s" % [auto_name.sub(str(layer.get_path_to(control)), "@$1@", true), control.get_class(), rect.position.x, rect.position.y, rect.size.x, rect.size.y, control.get_global_transform_with_canvas().get_scale(), ]
		entry += " a=%.2f" % control.modulate.a
		if control is ColorRect:
			entry += " color=%s" % (control as ColorRect).color.to_html()
		elif control is RichTextLabel:
			var rich: RichTextLabel = control
			entry += " font=%s color=%s text#%d" % [_font(rich, "normal_font_size"), rich.get_theme_color("default_color").to_html(), rich.text.hash()]
		elif control is Label:
			var label: Label = control
			entry += " font=%s color=%s halign=%d valign=%d text=%s" % [_font(label, "font_size"), label.get_theme_color("font_color").to_html(), label.horizontal_alignment, label.vertical_alignment, label.text.c_escape()]
		elif control is BaseButton:
			entry += " font=%s normal=%s focus=%s" % [_font(control, "font_size"), _box(control.get_theme_stylebox("normal")), _box(control.get_theme_stylebox("focus"))]
			if control is Button:
				entry += " text=%s" % (control as Button).text.c_escape()
		elif control is TabBar:
			entry += " font=%s sel=%s" % [_font(control, "font_size"), _box(control.get_theme_stylebox("tab_selected"))]
		elif control is Panel:
			entry += " panel=%s" % _box(control.get_theme_stylebox("panel"))
		lines.append(entry)


## Tweens run on real time and headless frames are near-instant, so wait out every reveal/lift tween first.
func _snap(state: String) -> void:
	await create_timer(1.2).timeout
	await _settle(2)
	_dump(state)
