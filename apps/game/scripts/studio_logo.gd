class_name StudioLogo
extends Control
## The MrDemonWolf, Inc. logo screen, the game's first scene (run/main_scene).
##
## Its first frame is the engine's boot splash (assets/brand/studio-logo-boot.png, rendered from this
## scene at t = 0), so launch flows straight into it. Over about two seconds the mascot's smirk holds,
## breaks into the grin with a small hop (no hop under Reduced Motion), the company name fades in under
## it, and everything fades to the title. The title scene loads on a background thread from the first
## frame; if it is still loading when the logo has played, a thin bar under the name shows its progress.
## The game's assets load on worker threads first and the title scene after them: in Godot 4.7.2 a scene
## whose scripts preload assets while compiling on a worker thread leaks the engine's load tokens at exit.
## Any key, mouse button, controller button or touch skips to the title as soon as it has loaded.
##
## Automation: pass `--skip-logo` as a user argument (`godot --path apps/game -- --skip-logo`) to go
## straight to the title; a headless run (tests, CI) always does.

const MAIN_SCENE: String = "res://scenes/main.tscn"
## Warmed on worker threads before MAIN_SCENE (see above), except the logo's own folder, whose boot
## splash is kept as a plain file rather than imported, and the asset register.
const ASSET_DIR: String = "res://assets"
const BRAND_DIR: String = "res://assets/brand"
const SKIP_ARG: String = "--skip-logo"
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
## On the title, a cover in the fade colour clears over this long.
const HANDOVER_SECONDS: float = 0.3
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
var load_progress: float = 0.0
## The background loads in flight: the assets, then MAIN_SCENE alone.
var loading: PackedStringArray = []
var _loads_total: int = 0
var _loads_done: int = 0
var _warm: Array[Resource] = []
var bar_alpha: float = 0.0
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


func _ready() -> void:
	_mascot_top = mascot.position.y
	reduce_motion = GameSettings.boolean(GameSettings.load_config(settings_path), "video", "reduced_motion", false)
	var args: PackedStringArray = OS.get_cmdline_user_args()
	args.append_array(OS.get_cmdline_args())
	if honor_launch_skip and wants_skip(args, DisplayServer.get_name()):
		handed_over = true
		set_process(false)
		set_process_input(false)
		get_tree().change_scene_to_file.call_deferred(MAIN_SCENE)
		return
	list_warm_assets(ASSET_DIR, loading)
	_loads_total = loading.size() + 1
	for path: String in loading:
		ResourceLoader.load_threaded_request(path)
	seek(0.0)


func _process(delta: float) -> void:
	if handed_over:
		return
	_poll_load()
	if manual_clock:
		return
	var step: float = minf(delta, MAX_STEP)
	var next: float = elapsed + step * (SKIP_FADE_RATE if skipping and elapsed >= FADE_AT else 1.0)
	if next >= FADE_AT and not is_loaded():
		next = FADE_AT
		bar_alpha = move_toward(bar_alpha, 1.0, step / BAR_IN_SECONDS)
	elapsed = next
	_apply()
	if elapsed >= END_AT and is_loaded():
		_hand_over()


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


func is_loaded() -> bool:
	return main_scene != null and not hold_load


## Shows the logo as it is `time` seconds in, with the loading bar at `bar` opacity.
func seek(time: float, bar: float = 0.0) -> void:
	elapsed = time
	bar_alpha = bar
	_apply()


func _apply() -> void:
	grin_mouth.visible = elapsed >= SWAP_AT
	var hop: float = clampf((elapsed - SWAP_AT) / BOUNCE_SECONDS, 0.0, 1.0)
	var lift: float = 0.0 if reduce_motion else BOUNCE_PX * sin(PI * hop)
	mascot.position.y = _mascot_top - lift
	company_name.modulate.a = smoothstep(NAME_IN_AT, NAME_IN_AT + NAME_IN_SECONDS, elapsed)
	load_bar.visible = bar_alpha > 0.0
	load_bar.modulate.a = bar_alpha
	load_fill.size.x = load_bar.size.x * clampf(load_progress, 0.0, 1.0)
	fade.color.a = clampf((elapsed - FADE_AT) / FADE_SECONDS, 0.0, 1.0)


func _poll_load() -> void:
	if main_scene != null:
		return
	if loading.is_empty():
		loading.append(MAIN_SCENE)
		ResourceLoader.load_threaded_request(MAIN_SCENE)
	var partial: float = 0.0
	for path: String in loading.duplicate():
		var progress: Array = []
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path, progress)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			partial += float(progress[0]) if not progress.is_empty() else 0.0
			continue
		# Every finished request is collected, even a failed one, so none is left pending.
		var resource: Resource = ResourceLoader.load_threaded_get(path) if status == ResourceLoader.THREAD_LOAD_LOADED else null
		loading.remove_at(loading.find(path))
		_loads_done += 1
		if path != MAIN_SCENE:
			if resource != null:
				_warm.append(resource)
		elif resource is PackedScene:
			main_scene = resource
		else:
			push_warning("The title scene failed to load in the background; loading it directly.")
			main_scene = load(MAIN_SCENE) as PackedScene
	load_progress = maxf(load_progress, (_loads_done + partial) / _loads_total)
	if main_scene != null:
		load_progress = 1.0
		_warm.clear()


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
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(cover)
	get_tree().root.add_child(layer)
	get_tree().change_scene_to_packed(main_scene)


## The cover over the cut to the title. It starts clearing once the title is the current scene, and a
## long frame (the title's first) clears at most one MAX_STEP of it, so it never pops.
class HandoverCover extends ColorRect:
	func _process(delta: float) -> void:
		var scene: Node = get_tree().current_scene
		if scene == null or scene.scene_file_path != MAIN_SCENE:
			return
		color.a -= minf(delta, MAX_STEP) / HANDOVER_SECONDS
		if color.a <= 0.0:
			get_parent().queue_free()
