extends "res://tests/support/game_suite.gd"
## The studio logo at launch: when it is skipped, its timeline (and with Reduced Motion), the handover
## to the title, and skipping while the title still loads.
## Bookkeeping, spawning and the waits come from the shared suite kit (tests/support/game_suite.gd).

const LOGO_SCENE: PackedScene = preload("res://scenes/studio_logo.tscn")

var settings_path: String = ""


func _run() -> void:
	check_name = "Studio logo"
	settings_path = "user://studio-logo-test-%s.cfg" % OS.get_process_id()
	var children_before: int = root.get_child_count()
	_check_skip_rules()
	# The background-load cases run first, so the title's scripts compile on worker threads as at launch.
	await _check_timeline()
	await _check_reduced_motion()
	await _check_handover()
	await _check_skip_waits_for_load()
	await _check_skip_inputs()
	await _check_launch_skip()
	await settle(2)
	_expect(root.get_child_count() == children_before and current_scene == null, "every logo, title and handover cover is freed")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
	finish()


func _check_skip_rules() -> void:
	_expect(StudioLogo.wants_skip(PackedStringArray(["--skip-logo"]), "macOS"), "--skip-logo skips the logo on a normal display")
	_expect(StudioLogo.wants_skip(PackedStringArray(), "headless"), "a headless run skips the logo")
	_expect(not StudioLogo.wants_skip(PackedStringArray(["--fullscreen"]), "Windows"), "a normal launch plays the logo")
	var warm: PackedStringArray = []
	StudioLogo.list_warm_assets(StudioLogo.ASSET_DIR, warm)
	var loadable: bool = warm.size() > 20
	for path: String in warm:
		loadable = loadable and ResourceLoader.exists(path) and not path.begins_with(StudioLogo.BRAND_DIR) and not path.ends_with(".json")
	_expect(loadable and warm.has("res://assets/title-corridor-key-art-provisional.png"), "the warm-up lists the game's loadable assets and leaves out the logo's own folder")
	var chosen: ConfigFile = ConfigFile.new()
	_expect(not StudioLogo.wants_saved_window(chosen, false), "a first launch keeps the window the engine opened")
	chosen.set_value("video", "fullscreen", true)
	_expect(StudioLogo.wants_saved_window(chosen, false), "a saved fullscreen applies on the logo's first frame")
	_expect(not StudioLogo.wants_saved_window(chosen, true), "a phone's window is left to the OS")
	chosen = ConfigFile.new()
	chosen.set_value("video", "resolution", 2)
	_expect(StudioLogo.wants_saved_window(chosen, false), "a saved window size applies on the logo's first frame")


## Headless, the logo goes straight to the title without starting its own load.
func _check_launch_skip() -> void:
	var logo: StudioLogo = _add_logo(true)
	_expect(logo.handed_over and not logo.is_processing(), "the launch skip stops the logo at once")
	await settle(3)
	_expect(not is_instance_valid(logo) and _on_title(), "the launch skip changes to main.tscn")
	_expect(root.get_node_or_null("StudioLogoHandover") == null, "the launch skip shows no handover cover")
	await _leave_title()


func _check_timeline() -> void:
	var logo: StudioLogo = _add_logo(false)
	logo.manual_clock = true
	var top: float = logo.mascot.position.y
	_expect(not logo.grin_mouth.visible and logo.company_name.modulate.a == 0.0 and logo.fade.color.a == 0.0 and not logo.load_bar.visible, "the first frame is the smirk alone, as on the boot splash")
	_expect(logo.mascot.position == Vector2(408, 86) and logo.mascot.size == Vector2(144, 300), "the mascot sits where the boot splash draws it")
	_check_shader_warmup(logo)
	logo.seek(StudioLogo.SWAP_AT - 0.01)
	_expect(not logo.grin_mouth.visible, "the smirk holds until the swap")
	logo.seek(StudioLogo.SWAP_AT + StudioLogo.BOUNCE_SECONDS * 0.5)
	_expect(logo.grin_mouth.visible and is_equal_approx(logo.mascot.position.y, top - StudioLogo.BOUNCE_PX), "the grin lands with a small hop")
	logo.seek(StudioLogo.SWAP_AT + StudioLogo.BOUNCE_SECONDS)
	_expect(is_equal_approx(logo.mascot.position.y, top), "the hop comes back down")
	logo.seek(StudioLogo.NAME_IN_AT)
	_expect(logo.company_name.modulate.a == 0.0, "the name waits a beat after the grin")
	logo.seek(StudioLogo.NAME_IN_AT + StudioLogo.NAME_IN_SECONDS)
	_expect(logo.company_name.modulate.a == 1.0 and logo.fade.color.a == 0.0, "the name is fully in before the fade")
	var label: Label = logo.company_name
	var font_size: int = label.get_theme_font_size("font_size")
	var width: float = label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, -1.0, font_size).x
	_expect(label.text == "MrDemonWolf, Inc." and font_size >= 24 and width < label.size.x, "the name reads MrDemonWolf, Inc. at a phone-readable size on one line")
	logo.seek(StudioLogo.FADE_AT + StudioLogo.FADE_SECONDS * 0.5)
	_expect(is_equal_approx(logo.fade.color.a, 0.5), "everything fades to the title's dark")
	logo.seek(StudioLogo.FADE_AT, 1.0)
	_expect(logo.load_bar.visible and logo.load_bar.position.y > logo.company_name.position.y + logo.company_name.size.y, "the loading bar sits under the name")
	var track: float = logo.load_bar.size.x
	var starts: Array[float] = []
	var inside: bool = true
	for step: int in range(8):
		logo.bar_time = StudioLogo.BAR_SWEEP_SECONDS * step / 8.0
		logo.seek(StudioLogo.FADE_AT, 1.0)
		var fill: ColorRect = logo.load_fill
		inside = inside and fill.position.x >= 0.0 and fill.position.x + fill.size.x <= track + 0.01 and fill.size.x <= track * StudioLogo.BAR_SEGMENT + 0.01
		starts.append(fill.position.x)
	_expect(inside and starts.max() - starts.min() > track * 0.5, "the loading bar sweeps a short segment across its track instead of sitting near full")
	_expect(not auto_accept_quit and not quit_on_go_back, "closing during the background load waits for it")
	await _free_logo(logo)


## The shader warm-up (SMOOTH-6) on a playing logo: one transparent draw for each of the game's canvas
## shaders and each blend mode, behind the opaque Background so nothing of it can show. Headless never
## draws a frame, so the node's freeing after the first drawn frame is left to the rendered checks.
func _check_shader_warmup(logo: StudioLogo) -> void:
	var holder: Control = logo.get_node_or_null(StudioLogo.WARM_NODE) as Control
	_expect(holder != null and holder.get_index() < logo.get_node("Background").get_index(), "the shader warm-up draws behind the logo's opaque background")
	if holder == null:
		return
	var shaders: Array[Shader] = []
	var blends: Array[int] = []
	var transparent: bool = true
	for draw: ColorRect in holder.get_children():
		transparent = transparent and draw.color.a == 0.0 and draw.modulate.a == 1.0
		if draw.material is ShaderMaterial:
			shaders.append((draw.material as ShaderMaterial).shader)
		elif draw.material is CanvasItemMaterial:
			blends.append((draw.material as CanvasItemMaterial).blend_mode)
	_expect(transparent, "each warm-up draw is a transparent colour, not a culled zero modulate")
	var wanted: Array[Shader] = StudioLogo.WARM_SHADERS.duplicate()
	wanted.append(FloorReflection.MATERIAL.shader)
	var covered: bool = shaders.size() == wanted.size()
	for shader: Shader in wanted:
		covered = covered and shaders.has(shader)
	var shared: bool = holder.get_children().any(func(draw: ColorRect) -> bool: return draw.material == FloorReflection.MATERIAL)
	_expect(covered and shared, "the warm-up draws sharp_sprite, post_grade and the shared floor reflection material itself")
	blends.sort()
	var every_mode: Array[int] = [CanvasItemMaterial.BLEND_MODE_MIX, CanvasItemMaterial.BLEND_MODE_ADD, CanvasItemMaterial.BLEND_MODE_SUB, CanvasItemMaterial.BLEND_MODE_MUL, CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA]
	every_mode.sort()
	_expect(blends == every_mode, "the warm-up draws every CanvasItemMaterial blend mode once")


func _check_reduced_motion() -> void:
	var text: String = "[video]\nreduced_motion=true\nvsync=false\n"
	_expect(write_text(settings_path, text), "test file opens for writing: " + settings_path)
	var logo: StudioLogo = _add_logo(false)
	logo.manual_clock = true
	var top: float = logo.mascot.position.y
	logo.seek(StudioLogo.SWAP_AT + StudioLogo.BOUNCE_SECONDS * 0.5)
	_expect(logo.reduce_motion and logo.grin_mouth.visible and logo.mascot.position.y == top, "Reduced Motion swaps to the grin without the hop")
	await _free_logo(logo)
	_expect(FileAccess.get_file_as_string(settings_path) == text, "the logo only reads the settings file")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))


## Played through, the logo hands over to main.tscn after the animation, under a cover that clears.
## How long it played is measured in the logo's own game time (each frame's delta clamped to
## StudioLogo.MAX_STEP, as the logo clamps it), not on the wall clock: on a busy machine frames come
## late and the wall clock can run past END_AT + 1.5 s while the logo itself is on time. The game-time
## limits (8 s here, 3 s for the cover) are what fail a stuck logo; wait_game_seconds' wall-clock
## guard only stops the wait if frames stop altogether.
func _check_handover() -> void:
	var logo: StudioLogo = _add_logo(false)
	_expect(not logo.reduce_motion, "Reduced Motion is off without a settings file")
	var played: float = await wait_game_seconds(8.0, _freed(logo), StudioLogo.MAX_STEP)
	_expect(not is_instance_valid(logo) and _on_title(), "the logo hands over to main.tscn")
	_expect(auto_accept_quit and quit_on_go_back, "once loaded, closing quits at once again")
	_expect(played >= StudioLogo.END_AT - 0.05 and played < StudioLogo.END_AT + 1.5, "the logo plays for about two seconds (%.2f s)" % played)
	var cover: CanvasLayer = root.get_node_or_null("StudioLogoHandover") as CanvasLayer
	_expect(cover != null, "a cover in the fade colour hides the cut to the title")
	# A player still pressing to skip: Enter, a click and a controller A on the title's first frames.
	var title: Node = current_scene
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = Vector2(480, 300)
	var pad: InputEventJoypadButton = InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	for frame: int in range(6):
		for pressed: bool in [true, false]:
			root.push_input(key_event(KEY_ENTER, pressed))
			click.pressed = pressed
			root.push_input(click.duplicate())
			pad.pressed = pressed
			root.push_input(pad.duplicate())
		await process_frame
	_expect(is_instance_valid(title) and title.get("title_open") == true, "presses just after the cut never pick a title option")
	await wait_game_seconds(3.0, _freed(cover), StudioLogo.MAX_STEP)
	_expect(not is_instance_valid(cover), "the cover clears and frees itself")
	await _leave_title()


## A skip while the title is still loading holds the full logo with a loading bar until the load is done.
## The hold and the closing fade are timed in the logo's game time, as in [method _check_handover].
func _check_skip_waits_for_load() -> void:
	var logo: StudioLogo = _add_logo(false)
	logo.hold_load = true
	await settle(2)
	root.push_input(key_event(KEY_SPACE, true))
	_expect(logo.skipping and logo.elapsed == StudioLogo.FADE_AT and logo.grin_mouth.visible and logo.company_name.modulate.a == 1.0, "a skip jumps to the full logo")
	await wait_game_seconds(0.5, Callable(), StudioLogo.MAX_STEP)
	_expect(is_instance_valid(logo) and current_scene == logo and logo.fade.color.a == 0.0, "the skipped logo waits for the title to load")
	_expect(logo.load_bar.visible and logo.load_bar.modulate.a == 1.0, "a thin loading bar shows while it waits")
	logo.hold_load = false
	var took: float = await wait_game_seconds(3.0, _freed(logo), StudioLogo.MAX_STEP)
	_expect(not is_instance_valid(logo) and _on_title(), "once loaded, the skip goes on to main.tscn")
	_expect(took < StudioLogo.FADE_SECONDS / StudioLogo.SKIP_FADE_RATE + 0.3, "after a skip the closing fade is quick (%.2f s)" % took)
	await settle(1)
	var cover: Node = root.get_node_or_null("StudioLogoHandover")
	while is_instance_valid(cover):
		await process_frame
	await _leave_title()


func _check_skip_inputs() -> void:
	var logo: StudioLogo = _add_logo(false)
	logo.hold_load = true
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.pressed = true
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	var pad: InputEventJoypadButton = InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	var echo: InputEventKey = key_event(KEY_ENTER, true)
	echo.echo = true
	var cases: Dictionary = {"a key press": [key_event(KEY_ENTER, true), true], "a touch": [touch, true], "a mouse button": [click, true], "a controller button": [pad, true], "a key release": [key_event(KEY_ENTER, false), false], "a held key's repeat": [echo, false]}
	for label: String in cases.keys():
		logo.skipping = false
		logo.seek(0.0)
		root.push_input(cases[label][0])
		_expect(logo.skipping == cases[label][1], "%s %s the logo" % [label, "skips" if cases[label][1] else "does not skip"])
	while logo.main_scene == null:
		await process_frame
	await _free_logo(logo)


func _add_logo(launch_skip: bool) -> StudioLogo:
	var logo: StudioLogo = LOGO_SCENE.instantiate() as StudioLogo
	logo.settings_path = settings_path
	logo.honor_launch_skip = launch_skip
	root.add_child(logo)
	current_scene = logo
	return logo


## Waits for the background load so no request outlives the logo, then frees it.
func _free_logo(logo: StudioLogo) -> void:
	while logo.main_scene == null:
		await process_frame
	logo.queue_free()
	await process_frame


## A condition for wait_game_seconds: true once [param node] has been freed. It holds a weak
## reference, because a lambda that captures the node itself reports an error once the node is gone.
func _freed(node: Node) -> Callable:
	var ref: WeakRef = weakref(node)
	return func() -> bool: return ref.get_ref() == null


func _on_title() -> bool:
	return current_scene != null and current_scene.scene_file_path == StudioLogo.MAIN_SCENE


func _leave_title() -> void:
	if current_scene != null:
		current_scene.queue_free()
	await settle(2)
