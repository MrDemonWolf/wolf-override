class_name StudioLogo
extends Control
## The MrDemonWolf, Inc. logo screen, the game's first scene (run/main_scene).
##
## Its first frame is the engine's boot splash (assets/brand/studio-logo-boot.png, rendered from this
## scene at t = 0), so launch flows straight into it. Over about two seconds the mascot's smirk holds,
## breaks into the grin with a small hop (no hop under Reduced Motion), the company name fades in under
## it, and everything fades to the title. The title scene loads on a background thread from the first
## frame; if it is still loading when the logo has played, a thin bar under the name shows it is still
## working. The bar sweeps rather than fills: almost all of the wait is the title's scripts compiling,
## which Godot reports as 0% until it is done, so a filling bar would sit still.
## The game's assets load on worker threads first and the title scene after them: in Godot 4.7.2 a scene
## whose scripts preload assets while compiling on a worker thread leaks the engine's load tokens at exit.
## While the logo is up it also draws each of the game's canvas shaders once, unseen (warm_shaders), so the
## title and the first room do not stall compiling them on their first frame (SMOOTH-6).
## Any key, mouse button, controller button or touch skips to the title as soon as it has loaded, and
## presses are swallowed for a moment after the cut so a player still mashing to skip never picks a
## title option unseen. A saved window size and fullscreen apply on the first frame, not at the title.
## Closing the window while a background load runs waits for it, so no load is cut off mid-way.
##
## Automation: pass `--skip-logo` as a user argument (`godot --path apps/game -- --skip-logo`) to go
## straight to the title; a headless run (tests, CI) always does.

const MAIN_SCENE: String = "res://scenes/main.tscn"
## Warmed on worker threads before MAIN_SCENE (see above), except the logo's own folder, whose boot
## splash is kept as a plain file rather than imported, and the asset register.
const ASSET_DIR: String = "res://assets"
const BRAND_DIR: String = "res://assets/brand"
const SKIP_ARG: String = "--skip-logo"
## The game's canvas shaders that warm_shaders draws once while the logo is up. The renderer compiles a
## shader the first time something draws with it, which stalls that frame (on a phone, a visible hitch);
## drawn here, the compile lands under the logo, which waits for the title's load anyway. The shared
## floor reflection material is drawn as itself; sharp_sprite and post_grade are main.tscn sub-resource
## materials, so fresh materials on the same Shader resources stand in for them (the compiled program
## belongs to the Shader, not to a material, and the shaders stay loaded until main.tscn holds them: the
## asset warm-up keeps every file under ASSET_DIR, these two included, until the title has loaded).
const WARM_SHADERS: Array[Shader] = [preload("res://assets/shaders/sharp_sprite.gdshader"), preload("res://assets/shaders/post_grade.gdshader")]
## Name of the node that holds the shader warm-up's draws, under Background so nothing of it shows.
const WARM_NODE: String = "ShaderWarmup"
## The smirk holds this long, then the grin's mouth replaces it.
const SWAP_AT: float = 0.45
## The hop as the grin lands: up BOUNCE_PX and back down over BOUNCE_SECONDS.
const BOUNCE_SECONDS: float = 0.28
const BOUNCE_PX: float = 6.0
## The company name fades in a beat after the grin.
const NAME_IN_AT: float = 0.7
const NAME_IN_SECONDS: float = 0.4
## Everything fades to the title's dark from FADE_AT; the logo has played at END_AT.
const FADE_AT: float = 1.6
const FADE_SECONDS: float = 0.4
const END_AT: float = FADE_AT + FADE_SECONDS
## A skip runs the closing fade at this speed.
const SKIP_FADE_RATE: float = 2.0
const BAR_IN_SECONDS: float = 0.25
## The loading bar's lit segment: this share of the track, crossing it once every BAR_SWEEP_SECONDS.
const BAR_SEGMENT: float = 0.3
const BAR_SWEEP_SECONDS: float = 1.1
## On the title, a cover in the fade colour clears over this long.
const HANDOVER_SECONDS: float = 0.3
## Key, button and touch presses are swallowed until the title has shown for this long (wall time from
## its first frame): the cover clears over HANDOVER_SECONDS, then the clear title holds a moment more.
const INPUT_GUARD_SECONDS: float = 0.6
## A long first frame or a stall while the title loads never jumps the animation ahead.
const MAX_STEP: float = 1.0 / 30.0
## The title screen's own base colour (main.tscn TitleScreen), so the fade meets it without a jump.
const FADE_COLOR: Color = Color(0.025, 0.045, 0.08, 1.0)

## The settings file Reduced Motion is read from (only read, never written).
var settings_path: String = "user://settings.cfg"
## Tests and capture drivers turn this off so the logo plays even when headless.
var honor_launch_skip: bool = true
## Capture drivers set this and move the logo with seek() alone.
var manual_clock: bool = false
## Treats the title as still loading (tests and captures of the loading bar).
var hold_load: bool = false
var reduce_motion: bool = false
var elapsed: float = 0.0
var skipping: bool = false
## The loaded title scene, or null while it loads.
var main_scene: PackedScene = null
## The background loads in flight: the assets, then MAIN_SCENE alone.
var loading: PackedStringArray = []
var _warm: Array[Resource] = []
var bar_alpha: float = 0.0
## How long the loading bar has been sweeping.
var bar_time: float = 0.0
## The window was closed (or Back pressed) while a background load ran; the game quits once it ends.
var quit_requested: bool = false
var handed_over: bool = false
var _mascot_top: float = 0.0

@onready var mascot: TextureRect = $Mascot
@onready var grin_mouth: TextureRect = $Mascot/GrinMouth
@onready var company_name: Label = $CompanyName
@onready var load_bar: Control = $LoadBar
@onready var load_fill: ColorRect = $LoadBar/Fill
@onready var fade: ColorRect = $Fade


## True when the logo should be skipped: the user argument, or a run without a screen.
static func wants_skip(args: PackedStringArray, display_name: String) -> bool:
	return args.has(SKIP_ARG) or display_name == "headless"


## Starts the logo: reads Reduced Motion and the saved window from the settings file, or, when the
## launch asks to skip (wants_skip), changes straight to the title and does nothing else. Otherwise
## applies the saved window (desktop only), starts the background loads of the assets to warm, holds
## quitting until they finish, and shows the first frame.
func _ready() -> void:
	_mascot_top = mascot.position.y
	var config: ConfigFile = GameSettings.load_config(settings_path)
	reduce_motion = GameSettings.boolean(config, "video", "reduced_motion", false)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	args.append_array(OS.get_cmdline_args())
	if honor_launch_skip and wants_skip(args, DisplayServer.get_name()):
		handed_over = true
		set_process(false)
		set_process_input(false)
		get_tree().change_scene_to_file.call_deferred(MAIN_SCENE)
		return
	if wants_saved_window(config, OS.has_feature("ios") or OS.has_feature("android")):
		GameSettings.apply_saved_window(get_window(), config)
	list_warm_assets(ASSET_DIR, loading)
	for path: String in loading:
		ResourceLoader.load_threaded_request(path)
	warm_shaders()
	# A close or Back press now waits for the loads (see _notification) instead of quitting under them.
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	seek(0.0)


## True when the logo applies the player's saved window size and fullscreen itself: on desktop, once
## the player has chosen either. A first launch already opens at the default size.
static func wants_saved_window(config: ConfigFile, mobile: bool) -> bool:
	return not mobile and (config.has_section_key("video", "resolution") or config.has_section_key("video", "fullscreen"))


## A window close or Android Back while quitting is held marks quit_requested (_process quits once the
## loads are done); leaving the tree gives quitting back to the engine.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if not get_tree().auto_accept_quit:
			quit_requested = true
	elif what == NOTIFICATION_EXIT_TREE:
		_release_quit()


## Gives quitting back to the engine once no background load is in flight.
func _release_quit() -> void:
	get_tree().auto_accept_quit = true
	get_tree().quit_on_go_back = true


## Each frame until the hand-over: collects finished loads, quits when asked and nothing is loading,
## and (unless manual_clock) moves the logo on by [param delta] seconds, capped at MAX_STEP, faster when
## skipping. It holds at FADE_AT with the loading bar fading in until the title has loaded, and hands
## over at END_AT.
func _process(delta: float) -> void:
	if handed_over:
		return
	_poll_load()
	if quit_requested:
		if loading.is_empty():
			_release_quit()
			get_tree().quit()
		return
	if manual_clock:
		return
	var step: float = minf(delta, MAX_STEP)
	if bar_alpha > 0.0:
		bar_time += step
	var next: float = elapsed + step * (SKIP_FADE_RATE if skipping and elapsed >= FADE_AT else 1.0)
	if next >= FADE_AT and not is_loaded():
		next = FADE_AT
		bar_alpha = move_toward(bar_alpha, 1.0, step / BAR_IN_SECONDS)
	elapsed = next
	_apply()
	if elapsed >= END_AT and is_loaded():
		_hand_over()


## Any key, mouse button, controller button or touch press skips to the closing fade (skip) and is
## marked handled. Ignored after the hand-over or under manual_clock.
func _input(event: InputEvent) -> void:
	if handed_over or manual_clock:
		return
	var pressed: bool = false
	if event is InputEventKey:
		pressed = event.pressed and not event.is_echo()
	elif event is InputEventMouseButton or event is InputEventJoypadButton or event is InputEventScreenTouch:
		pressed = event.is_pressed()
	if pressed:
		skip()
		get_viewport().set_input_as_handled()


## Skips to the closing fade, which starts once the title has loaded; until then the full logo holds.
func skip() -> void:
	skipping = true
	elapsed = maxf(elapsed, FADE_AT)
	_apply()


## True once the title scene has loaded and no test holds it back (hold_load).
func is_loaded() -> bool:
	return main_scene != null and not hold_load


## Shows the logo as it is `time` seconds in, with the loading bar at `bar` opacity.
func seek(time: float, bar: float = 0.0) -> void:
	elapsed = time
	bar_alpha = bar
	_apply()


## Draws the logo as it is at elapsed seconds: the grin from SWAP_AT with its hop (none under Reduced
## Motion), the company name fading in, the loading bar at bar_alpha (sweeping, or glowing in place
## under Reduced Motion) and the fade to the title from FADE_AT.
func _apply() -> void:
	grin_mouth.visible = elapsed >= SWAP_AT
	var hop: float = clampf((elapsed - SWAP_AT) / BOUNCE_SECONDS, 0.0, 1.0)
	var lift: float = 0.0 if reduce_motion else BOUNCE_PX * sin(PI * hop)
	mascot.position.y = _mascot_top - lift
	company_name.modulate.a = smoothstep(NAME_IN_AT, NAME_IN_AT + NAME_IN_SECONDS, elapsed)
	load_bar.visible = bar_alpha > 0.0
	load_bar.modulate.a = bar_alpha
	var width: float = load_bar.size.x
	if reduce_motion:
		# Under Reduced Motion the whole track glows gently instead of sweeping.
		load_fill.position.x = 0.0
		load_fill.size.x = width
		load_fill.modulate.a = 0.55 + 0.45 * cos(TAU * bar_time / BAR_SWEEP_SECONDS)
	else:
		var head: float = lerpf(-BAR_SEGMENT, 1.0, fposmod(bar_time / BAR_SWEEP_SECONDS, 1.0)) * width
		var left: float = clampf(head, 0.0, width)
		load_fill.position.x = left
		load_fill.size.x = clampf(head + BAR_SEGMENT * width, 0.0, width) - left
		load_fill.modulate.a = 1.0
	fade.color.a = clampf((elapsed - FADE_AT) / FADE_SECONDS, 0.0, 1.0)


## Collects every background load that has finished (failed ones too, so none stays pending). Once the
## warmed assets are all in it requests the title scene, and when that arrives keeps it in main_scene
## (loading it directly if the background load failed), lets the warmed assets go and gives quitting
## back. Nothing once the title is loaded.
func _poll_load() -> void:
	if main_scene != null:
		return
	if loading.is_empty():
		if quit_requested:
			return
		loading.append(MAIN_SCENE)
		ResourceLoader.load_threaded_request(MAIN_SCENE)
	for path: String in loading.duplicate():
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		# Every finished request is collected, even a failed one, so none is left pending.
		var resource: Resource = ResourceLoader.load_threaded_get(path) if status == ResourceLoader.THREAD_LOAD_LOADED else null
		loading.remove_at(loading.find(path))
		if path != MAIN_SCENE:
			if resource != null:
				_warm.append(resource)
		elif resource is PackedScene:
			main_scene = resource
		else:
			push_warning("The title scene failed to load in the background; loading it directly.")
			main_scene = load(MAIN_SCENE) as PackedScene
	if main_scene != null:
		_warm.clear()
		if not quit_requested:
			_release_quit()


## Draws every material the game's canvas uses once, unseen, so the renderer compiles each shader now,
## under the logo, rather than on the frame the title or a room first shows it: WARM_SHADERS, the shared
## FloorReflection.MATERIAL, and a CanvasItemMaterial in each blend mode (FxKit's additive and multiply
## glows and soot use two of them; each mode is its own generated shader, and all five cost a few tiny
## draws once). Each is an 8x8 px ColorRect in a fully transparent colour: not modulate alpha, which the
## renderer culls without drawing, but the draw's own colour, so the shader runs and writes nothing. They
## sit behind the opaque Background as well, so even a blend mode that ignores alpha (post_grade's
## multiply writes alpha 1) never reaches the screen. The node frees itself after the first frame drawn
## (RenderingServer.frame_post_draw). Adds one child (WARM_NODE) at index 0; returns it.
func warm_shaders() -> Control:
	var holder: Control = Control.new()
	holder.name = WARM_NODE
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var materials: Array[Material] = [FloorReflection.MATERIAL]
	for shader: Shader in WARM_SHADERS:
		var shader_material: ShaderMaterial = ShaderMaterial.new()
		shader_material.shader = shader
		materials.append(shader_material)
	for mode: int in [CanvasItemMaterial.BLEND_MODE_MIX, CanvasItemMaterial.BLEND_MODE_ADD, CanvasItemMaterial.BLEND_MODE_SUB, CanvasItemMaterial.BLEND_MODE_MUL, CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA]:
		var blend: CanvasItemMaterial = CanvasItemMaterial.new()
		blend.blend_mode = mode as CanvasItemMaterial.BlendMode
		materials.append(blend)
	for material_to_warm: Material in materials:
		var draw: ColorRect = ColorRect.new()
		draw.color = Color(1.0, 1.0, 1.0, 0.0)
		draw.size = Vector2(8.0, 8.0)
		draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		draw.material = material_to_warm
		holder.add_child(draw)
	add_child(holder)
	move_child(holder, 0)
	RenderingServer.frame_post_draw.connect(holder.queue_free, CONNECT_ONE_SHOT)
	return holder


## The resources under `dir` that are warmed before the title scene.
static func list_warm_assets(dir: String, into: PackedStringArray) -> void:
	for entry: String in ResourceLoader.list_directory(dir):
		if entry.ends_with("/"):
			var sub: String = dir.path_join(entry.trim_suffix("/"))
			if sub != BRAND_DIR:
				list_warm_assets(sub, into)
		elif not entry.ends_with(".json"):
			into.append(dir.path_join(entry))


## Changes to the title under a cover in the fade colour that then clears, so the cut never shows.
func _hand_over() -> void:
	handed_over = true
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "StudioLogoHandover"
	layer.layer = 128
	var cover: HandoverCover = HandoverCover.new()
	cover.color = FADE_COLOR
	cover.mouse_filter = Control.MOUSE_FILTER_STOP
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(cover)
	get_tree().root.add_child(layer)
	get_tree().change_scene_to_packed(main_scene)


## The cover over the cut to the title. It starts clearing once the title is the current scene, and a
## long frame (the title's first) clears at most one MAX_STEP of it, so it never pops. Until the title
## has shown for INPUT_GUARD_SECONDS it swallows every key, button and touch press, so a player still
## pressing to skip the logo cannot pick a title option (or start a New Game) before seeing the title.
class HandoverCover extends ColorRect:
	## When the title's first frame ran, in Time.get_ticks_msec(); -1 until then.
	var title_since: int = -1

	## Once the title is the current scene, clears the cover over HANDOVER_SECONDS (at most one MAX_STEP per
	## frame) and frees it, with its layer, when it is clear and INPUT_GUARD_SECONDS have passed.
	func _process(delta: float) -> void:
		var scene: Node = get_tree().current_scene
		if scene == null or scene.scene_file_path != MAIN_SCENE:
			return
		if title_since < 0:
			title_since = Time.get_ticks_msec()
		color.a = maxf(color.a - minf(delta, MAX_STEP) / HANDOVER_SECONDS, 0.0)
		if color.a <= 0.0 and Time.get_ticks_msec() - title_since >= INPUT_GUARD_SECONDS * 1000.0:
			get_parent().queue_free()

	## Swallows every key, mouse button, controller button and touch event while the cover is up.
	func _input(event: InputEvent) -> void:
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton or event is InputEventScreenTouch:
			get_viewport().set_input_as_handled()
