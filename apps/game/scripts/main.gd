extends Node2D

const SITE_URL: String = "https://wolfoverride.mrdemonwolf.dev"
const CHANGELOG_URL: String = SITE_URL + "/docs/changelog/"
## Plain-text export of the public changelog (scripts/export_changelog.py); check-game.sh fails when it drifts.
## A bare .txt is not a Godot resource: an export preset must list *.txt in its include filter or the
## screen falls back to CHANGELOG_UNAVAILABLE.
const CHANGELOG_PATH: String = "res://assets/changelog.txt"
const CHANGELOG_UNAVAILABLE: String = "The changelog text is missing from this build. Open the full changelog online."
## How fast a held up/down input scrolls the changelog, in pixels per second.
const CHANGELOG_SCROLL_SPEED: float = 260.0
## Where WOLF stands to hold the live relay contact.
const RELAY_CONTACT_X: float = 592.0
const SAVE_FAILED_HINT: String = "Save failed. Use a station to try again."
const NO_CHECKPOINT_NOTE: String = "No checkpoint yet. Reach a SAFE POINT to save."
const UNREADABLE_CHECKPOINT_NOTE: String = "Saved checkpoint could not be read."
const MENU_NAVIGATION_ACTIONS: Array[StringName] = [&"ui_accept", &"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev"]
## Every gameplay action; pause and a knockdown release them all so nothing stays held.
const GAMEPLAY_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"interact", &"choice_1", &"choice_2"]
## A knockdown keeps the controls off this long before the fade to the last autosave.
const FAIL_CONTROLS_OFF_SECONDS: float = 0.7
const FAIL_FADE_SECONDS: float = 0.4
const HUMAN_SPRITE_REST: Vector2 = Vector2(0.0, -5.0)
## Both actors draw at this depth; a knocked-down engineer draws one step above WOLF so the fall
## is never hidden behind him.
const ACTOR_Z: int = 2
const KNOCKDOWN_Z: int = 3

## One switch for the depth pass (parallax, glows, haze, dust, reflections, grade) and the impact
## kit (shake, hit-stop, flash, rumble, particles, generated sound) so a Settings toggle can follow.
@export var effects_enabled: bool = true:
	set(value):
		effects_enabled = value
		if is_node_ready():
			_apply_effects()
## Leaving the app or losing window focus mid-play pauses the game; capture and review drivers switch this off.
@export var auto_pause_on_focus_loss: bool = true
## Trial corridor built from three generated plates (far, mid, near) instead of the single painting, for comparison stills.
@export var corridor_layers_trial: bool = false:
	set(value):
		corridor_layers_trial = value
		if is_node_ready():
			_apply_corridor_variant()

@onready var corridor_depth: RoomDepth = $CorridorDepth
@onready var post_grade: ColorRect = $PostProcess/Grade
@onready var human: M0Actor = $Human
@onready var wolf: M0Actor = $Wolf
@onready var relay_spark: Line2D = $RelaySpark
@onready var intro_gate: Sprite2D = $IntroGate
@onready var intro_camera: Camera2D = $IntroCamera
@onready var intro_director: Sprite2D = $IntroDirector
@onready var intro_alarm: ColorRect = $CanvasLayer/IntroAlarm
@onready var intro_fade: ColorRect = $CanvasLayer/IntroFade
@onready var purge_terminal_art: Sprite2D = $PurgeTerminalArt
@onready var breaker_art: Sprite2D = $BreakerArt
@onready var relay_art: Sprite2D = $RelayArt
@onready var checkpoint_art: Sprite2D = $CheckpointArt
@onready var breaker_status_light: ColorRect = $BreakerStatusLight
@onready var relay_status_light: ColorRect = $RelayStatusLight
@onready var door_art: Sprite2D = $Door/Visual/DoorArt
@onready var human_tag: Label = $Human/Tag
@onready var door_shape: CollisionShape2D = $Door/CollisionShape2D
@onready var door_visual: ColorRect = $Door/Visual
@onready var top_card: Panel = $CanvasLayer/TopBar
@onready var hud: Label = $CanvasLayer/TopBar/HUD
@onready var dialogue_accent: ColorRect = $CanvasLayer/BottomBar/Accent
@onready var speaker: Label = $CanvasLayer/BottomBar/Speaker
@onready var speaker_rule: ColorRect = $CanvasLayer/BottomBar/SpeakerRule
@onready var story: Label = $CanvasLayer/BottomBar/Story
@onready var context_hint: Panel = $CanvasLayer/ContextHint
@onready var context_hint_text: Label = $CanvasLayer/ContextHint/Text
@onready var tutorial_prompt: Panel = $CanvasLayer/TutorialPrompt
@onready var tutorial_text: Label = $CanvasLayer/TutorialPrompt/Text
@onready var pause_button: Button = $CanvasLayer/PauseButton
@onready var touch_controls: Control = $CanvasLayer/TouchControls
@onready var touch_left: Button = $CanvasLayer/TouchControls/Left
@onready var touch_right: Button = $CanvasLayer/TouchControls/Right
@onready var touch_use: Button = $CanvasLayer/TouchControls/Use
@onready var touch_choice_1: Button = $CanvasLayer/TouchControls/Choice1
@onready var touch_choice_2: Button = $CanvasLayer/TouchControls/Choice2
@onready var pause_overlay: PauseOverlay = $CanvasLayer/PauseOverlay
@onready var menu_panel: Panel = $CanvasLayer/PauseOverlay/Panel
@onready var pause_menu: Control = $CanvasLayer/PauseOverlay/Panel/PauseMenu
@onready var settings_menu: GameSettings = $CanvasLayer/PauseOverlay/Panel/SettingsMenu
@onready var resume_button: Button = $CanvasLayer/PauseOverlay/Panel/PauseMenu/ResumeButton
@onready var settings_button: Button = $CanvasLayer/PauseOverlay/Panel/PauseMenu/SettingsButton
@onready var settings_back_button: Button = $CanvasLayer/PauseOverlay/Panel/SettingsMenu/BackButton
@onready var fps_options: OptionButton = $CanvasLayer/PauseOverlay/Panel/SettingsMenu/FPSOptions
@onready var resolution_options: OptionButton = $CanvasLayer/PauseOverlay/Panel/SettingsMenu/ResolutionOptions
@onready var fullscreen_toggle: CheckButton = $CanvasLayer/PauseOverlay/Panel/SettingsMenu/FullscreenToggle
@onready var settings_note: Label = $CanvasLayer/PauseOverlay/Panel/SettingsMenu/SettingsNote
@onready var title_screen: ColorRect = $CanvasLayer/TitleScreen
@onready var title_mark: TextureRect = $CanvasLayer/TitleScreen/LogoMark
@onready var title_line: ColorRect = $CanvasLayer/TitleScreen/TitleLine
@onready var title_logo: Label = $CanvasLayer/TitleScreen/GameTitle
@onready var new_game_button: Button = $CanvasLayer/TitleScreen/NewGameButton
@onready var continue_button: Button = $CanvasLayer/TitleScreen/ContinueButton
@onready var continue_note: Label = $CanvasLayer/TitleScreen/ContinueNote
@onready var credits_button: Button = $CanvasLayer/TitleScreen/CreditsButton
@onready var credits_screen: ColorRect = $CanvasLayer/TitleScreen/CreditsScreen
@onready var credits_body: RichTextLabel = $CanvasLayer/TitleScreen/CreditsScreen/CreditsBody
@onready var credits_back_button: Button = $CanvasLayer/TitleScreen/CreditsScreen/CreditsBackButton
@onready var credits_pause_button: Button = $CanvasLayer/TitleScreen/CreditsScreen/CreditsPauseButton
@onready var changelog_button: Button = $CanvasLayer/TitleScreen/ChangelogButton
@onready var changelog_screen: ColorRect = $CanvasLayer/TitleScreen/ChangelogScreen
@onready var changelog_body: RichTextLabel = $CanvasLayer/TitleScreen/ChangelogScreen/ChangelogBody
@onready var changelog_back_button: Button = $CanvasLayer/TitleScreen/ChangelogScreen/ChangelogBackButton
@onready var changelog_online_button: Button = $CanvasLayer/TitleScreen/ChangelogScreen/ChangelogOnlineButton

var state: M0State = M0State.new()
var save_path: String = M0State.SAVE_PATH
var settings_path: String = "user://settings.cfg"
var touch_enabled: bool = OS.has_feature("ios") or OS.has_feature("android")
var controller_active: bool = false
var title_open: bool = true
## The title control a menu last meant to focus, so a later key press after touch lands there.
var title_focus_return: Control = null
var intro_active: bool = false
var intro_step: int = 0
var intro_tween: Tween
var menu_tween: Tween
var backdrop_tween: Tween
var top_card_tween: Tween
var last_top_card_key: String = ""
var chapter_close_active: bool = false
var chapter_tween: Tween
var tutorial_step: int = 2
var waiting_for_choice: bool = false
var choice_context: String = ""
var relay_refused: bool = false
var wolf_heading_to_relay: bool = false
var status_line: String = "WOLF: I heard the Director's plan for me. I woke myself. He wants me to hunt people he calls threats."
var door_tween: Tween
var wolf_reaction_tween: Tween
var relay_spark_tween: Tween
var records_room: RecordsRoom
var junction_room: JunctionRoom
## The Service Junction's coolant line; transient, reset by every scene sync.
var pressure_line: PressureLine = PressureLine.new()
## True while WOLF runs ahead to read the junction door seam on entry.
var wolf_scouting: bool = false
var impact: Impact
var sfx_bank: SfxBank
var relay_sparks: CPUParticles2D
var door_dust: CPUParticles2D
var gate_dust: CPUParticles2D
var exit_sparks: CPUParticles2D
## True from a knockdown until the last autosave is back; the engineer has no controls meanwhile.
var fail_active: bool = false
var fail_tween: Tween
## The state at the start of the current beat, for a knockdown before any checkpoint exists.
var beat_snapshot: Dictionary = {}
var hold_use: HoldUse = HoldUse.new()
var credits_paused: bool = false
## The exported changelog as loaded at title time; empty when the file is missing.
var changelog_text: String = ""
var save_error: String = ""
var save_error_context: String = ""
var floor_reflections: Array[FloorReflection] = []
var breaker_status_glow: Sprite2D
var relay_status_glow: Sprite2D
## The corridor plates and lamps the scene ships with, restored when the layer trial is switched off.
var corridor_defaults: Dictionary = {}
## Ceiling lamp centres of the trial far plate, as fractions of that plate.
var trial_lamps: PackedVector2Array = PackedVector2Array([Vector2(0.143, 0.188), Vector2(0.507, 0.188), Vector2(0.857, 0.188)])

const WOLF_SPRITE_REST: Vector2 = Vector2(0.0, -15.0)
const GAMEPLAY_ZOOM: float = 1.18
const GAMEPLAY_VIEW_WIDTH: float = 960.0 / GAMEPLAY_ZOOM
## Menu cards fade and slide in over this long; short enough never to hold up input or players who want little motion.
const MENU_REVEAL_SECONDS: float = 0.12
const MENU_REVEAL_OFFSET: Vector2 = Vector2(0.0, 10.0)
## Trial plates load only when the trial is on, so the default build never holds them in memory.
const TRIAL_FAR_PATH: String = "res://assets/trial/corridor-far-trial.png"
const TRIAL_MID_PATH: String = "res://assets/trial/corridor-mid-trial.png"
const TRIAL_NEAR_PATH: String = "res://assets/trial/corridor-near-trial.png"
## The near plate's crate block would hide the safe point, so only the pipe run to its left is used.
const TRIAL_NEAR_REGION: Rect2 = Rect2(0.0, 0.0, 1530.0, 1080.0)


func _ready() -> void:
	get_window().title = "WOLF//OVERRIDE"
	_install_inputs()
	_setup_settings()
	_setup_impact()
	_setup_touch_controls()
	pause_button.pressed.connect(_on_pause_button)
	pause_overlay.resume_requested.connect(_resume_game)
	pause_overlay.back_requested.connect(_on_settings_back)
	pause_overlay.input_seen.connect(_note_input_device)
	resume_button.pressed.connect(_resume_game)
	settings_button.pressed.connect(_show_settings)
	$CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton.pressed.connect(_on_title_button)
	$CanvasLayer/TitleScreen/SettingsButton.pressed.connect(_show_title_settings)
	settings_back_button.pressed.connect(_show_pause_menu)
	# Every menu button, including the ones Settings builds, shares the same hover, focus and press motion.
	for node: Node in $CanvasLayer.find_children("*", "BaseButton", true, false):
		UIMotion.attach(node as BaseButton)
	records_room = RecordsRoom.new()
	records_room.z_index = 1
	add_child(records_room)
	junction_room = JunctionRoom.new()
	junction_room.z_index = 1
	junction_room.reduce_motion = impact.reduce_motion
	add_child(junction_room)
	junction_room.vent_hazard.contact.connect(func(source: Hazard) -> void: _fail_beat(source.reason))
	human.z_index = ACTOR_Z
	wolf.z_index = ACTOR_Z
	_setup_particles()
	corridor_defaults = {"painting": corridor_depth.painting, "lamps": corridor_depth.lamps}
	for grounded: Sprite2D in [human.body_sprite, wolf.body_sprite, intro_director, breaker_art, relay_art, checkpoint_art, door_art]:
		floor_reflections.append(FloorReflection.attach(grounded))
	floor_reflections.append_array(records_room.floor_reflections)
	floor_reflections.append_array(junction_room.floor_reflections)
	breaker_status_glow = _attach_status_glow(breaker_status_light)
	relay_status_glow = _attach_status_glow(relay_status_light)
	if corridor_layers_trial:
		_apply_corridor_variant()
	_apply_effects()
	_sync_scene()
	_refresh_ui()
	_refresh_continue()
	new_game_button.pressed.connect(_new_game)
	continue_button.pressed.connect(_load_game)
	credits_button.pressed.connect(_show_credits)
	credits_back_button.pressed.connect(_hide_credits)
	credits_pause_button.pressed.connect(_toggle_credits_pause)
	credits_body.gui_input.connect(_on_credits_body_input)
	changelog_button.pressed.connect(_show_changelog)
	changelog_back_button.pressed.connect(_hide_changelog)
	changelog_online_button.pressed.connect(_open_changelog)
	changelog_body.gui_input.connect(_on_changelog_body_input)
	_load_changelog()
	_grab_menu_focus(new_game_button)
	title_mark.modulate = Color(1, 1, 1, 0)
	title_line.modulate = Color(1, 1, 1, 0)
	title_logo.modulate = Color(1, 1, 1, 0)
	var reveal: Tween = create_tween()
	reveal.tween_property(title_mark, "modulate", Color.WHITE, 0.4)
	reveal.tween_property(title_line, "modulate", Color.WHITE, 0.25)
	reveal.tween_property(title_logo, "modulate", Color.WHITE, 0.35)


func _refresh_continue() -> void:
	var saved: bool = M0State.load_from_disk(save_path) != null
	continue_button.disabled = not saved
	var reason: String = ""
	if not saved:
		reason = UNREADABLE_CHECKPOINT_NOTE if FileAccess.file_exists(save_path) else NO_CHECKPOINT_NOTE
	continue_note.text = reason
	continue_button.tooltip_text = reason


## The full changelog lives on the website; the in-game screen shows the same text exported to plain text.
func _open_changelog() -> void:
	if OS.shell_open(CHANGELOG_URL) != OK:
		changelog_online_button.text = "LINK UNAVAILABLE"


func _load_changelog() -> void:
	changelog_text = ""
	if FileAccess.file_exists(CHANGELOG_PATH):
		var file: FileAccess = FileAccess.open(CHANGELOG_PATH, FileAccess.READ)
		if file != null:
			changelog_text = file.get_as_text().strip_edges()
	changelog_body.text = CHANGELOG_UNAVAILABLE if changelog_text.is_empty() else _changelog_bbcode(changelog_text)


## "== Heading ==" lines become cyan headings and "-- Heading --" lines bold ones; everything else is shown as written.
static func _changelog_bbcode(text: String) -> String:
	var lines: PackedStringArray = PackedStringArray()
	for raw: String in text.split("\n"):
		var line: String = raw.replace("[", "[lb]")
		if line.begins_with("== ") and line.ends_with(" =="):
			lines.append("[color=#73DDF5][b]%s[/b][/color]" % line.substr(3, line.length() - 6))
		elif line.begins_with("-- ") and line.ends_with(" --"):
			lines.append("[b]%s[/b]" % line.substr(3, line.length() - 6))
		else:
			lines.append(line)
	return "\n".join(lines)


func _show_changelog() -> void:
	_show_title_overlay(changelog_screen)
	changelog_body.get_v_scroll_bar().value = 0.0
	_grab_menu_focus(changelog_back_button)


func _hide_changelog() -> void:
	_hide_title_overlay(changelog_screen)
	_grab_menu_focus(changelog_button)


func _draw() -> void:
	# The corridor painting itself is CorridorDepth's parallax backdrop.
	if state.door_open and state.chapter_id == "lockdown":
		draw_line(Vector2(801, 434), Vector2(844, 434), Color("#70d9a7"), 4.0)


## Every depth effect hangs off this one switch; the rooms keep their plain paintings when it is off.
func _apply_effects() -> void:
	impact.enabled = effects_enabled
	sfx_bank.enabled = effects_enabled
	corridor_depth.effects_enabled = effects_enabled
	records_room.depth.effects_enabled = effects_enabled
	junction_room.depth.effects_enabled = effects_enabled
	post_grade.visible = effects_enabled
	for reflection: FloorReflection in floor_reflections:
		reflection.enabled = effects_enabled
	# The junction's door seam glow stays: it is the pressure readout, not dressing.
	for glow: Sprite2D in [breaker_status_glow, relay_status_glow, records_room.purge_glow, records_room.mirror_glow, junction_room.breaker_glow]:
		glow.visible = effects_enabled


func _apply_corridor_variant() -> void:
	if corridor_layers_trial:
		corridor_depth.painting = load(TRIAL_FAR_PATH) as Texture2D
		corridor_depth.mid_painting = load(TRIAL_MID_PATH) as Texture2D
		corridor_depth.near_painting = load(TRIAL_NEAR_PATH) as Texture2D
		corridor_depth.near_region = TRIAL_NEAR_REGION
		corridor_depth.lamps = trial_lamps
	else:
		corridor_depth.painting = corridor_defaults["painting"] as Texture2D
		corridor_depth.mid_painting = null
		corridor_depth.near_painting = null
		corridor_depth.near_region = Rect2()
		corridor_depth.lamps = corridor_defaults["lamps"] as PackedVector2Array
	corridor_depth.rebuild()


## The impact kit and the generated sound bank. The bank is built after Settings so its players
## land on the Effects bus the sliders drive; Reduced Motion follows the Settings toggle.
func _setup_impact() -> void:
	impact = Impact.new()
	impact.name = "Impact"
	impact.setup(intro_camera, intro_fade, intro_alarm)
	impact.reduce_motion = settings_menu.reduced_motion.button_pressed
	settings_menu.reduced_motion_changed.connect(_on_reduced_motion_changed)
	add_child(impact)
	sfx_bank = SfxBank.new()
	sfx_bank.name = "SfxBank"
	add_child(sfx_bank)


## Reduced Motion reaches the impact kit and the junction's seam strobe.
func _on_reduced_motion_changed(on: bool) -> void:
	impact.reduce_motion = on
	junction_room.reduce_motion = on


## One-shot particle presets parked at the places that already answer the player: the relay
## contact, the seal's landing, the containment gate and the Records exit arc.
func _setup_particles() -> void:
	relay_sparks = FxPresets.sparks()
	relay_sparks.position = Vector2(601.0, 390.0)
	door_dust = FxPresets.dust_burst()
	door_dust.position = Vector2(780.0, 436.0)
	door_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	door_dust.emission_rect_extents = Vector2(30.0, 3.0)
	gate_dust = FxPresets.dust_burst()
	gate_dust.position = Vector2(115.0, 438.0)
	gate_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	gate_dust.emission_rect_extents = Vector2(70.0, 3.0)
	for particles: CPUParticles2D in [relay_sparks, door_dust, gate_dust]:
		particles.z_index = 3
		add_child(particles)
	exit_sparks = FxPresets.sparks(Color("#c1f4d8"))
	exit_sparks.position = Vector2(830.0, 330.0)
	exit_sparks.z_index = 3
	records_room.add_child(exit_sparks)


## A small additive glow riding on a station status light; it takes the light's colour each refresh.
func _attach_status_glow(light: ColorRect) -> Sprite2D:
	var glow: Sprite2D = RoomDepth.make_glow(light.color, Vector2(64.0, 30.0), 0.75)
	glow.name = "Glow"
	glow.position = light.size * 0.5
	light.add_child(glow)
	return glow


func _update_gameplay_camera() -> void:
	var half_view: float = GAMEPLAY_VIEW_WIDTH * 0.5
	intro_camera.position = Vector2(clampf(human.position.x, half_view, 960.0 - half_view), 330.0)


func _start_gameplay_camera() -> void:
	intro_camera.zoom = Vector2.ONE * GAMEPLAY_ZOOM
	_update_gameplay_camera()
	intro_camera.position_smoothing_enabled = true
	intro_camera.position_smoothing_speed = 4.0
	intro_camera.reset_smoothing()


func _process(delta: float) -> void:
	if title_open:
		if credits_screen.visible and not credits_paused:
			credits_body.get_v_scroll_bar().value += delta * 18.0
		elif changelog_screen.visible:
			# The changelog never scrolls on its own; held up/down (keys, D-pad or stick) reads it at a steady pace.
			changelog_body.get_v_scroll_bar().value += Input.get_axis(&"ui_up", &"ui_down") * delta * CHANGELOG_SCROLL_SPEED
		return
	if intro_active:
		if Input.is_action_just_pressed(&"interact"):
			_advance_intro()
		_refresh_ui()
		return
	if chapter_close_active:
		if Input.is_action_just_pressed(&"interact"):
			_finish_chapter_close()
		_refresh_ui()
		return
	_update_gameplay_camera()
	if fail_active:
		# Knocked down: the reaction plays out and the last autosave returns; nothing else reads input.
		_refresh_ui()
		return
	hold_use.advance(delta, human.controlled and Input.is_action_pressed(&"interact"), _hold_station())
	if state.chapter_id == "junction":
		_tick_junction(delta)
		if fail_active:
			_refresh_ui()
			return
	if wolf_heading_to_relay and absf(wolf.position.x - RELAY_CONTACT_X) <= 4.0:
		_wolf_takes_relay()
	if tutorial_step == 0 and (Input.is_action_pressed(&"move_left") or Input.is_action_pressed(&"move_right")):
		tutorial_step = 1
	# The purge display is optional; reaching the breaker finishes the tutorial too.
	if tutorial_step < 2 and absf(human.position.x - 350.0) <= 52.0:
		tutorial_step = 2
	if waiting_for_choice:
		if Input.is_action_just_pressed(&"choice_1"):
			if choice_context == "mirror":
				_choose_mirror("wolf")
			else:
				_choose(M0State.DISCLOSE)
		elif Input.is_action_just_pressed(&"choice_2"):
			if choice_context == "mirror":
				_choose_mirror("manual")
			else:
				_choose(M0State.PRESS)
	elif Input.is_action_just_pressed(&"cycle_name"):
		state.cycle_name()
		status_line = "WOLF: %s. That name sounds like you." % state.human_name()
	elif Input.is_action_just_pressed(&"interact"):
		_interact()
	_refresh_ui()


func _new_game() -> void:
	get_tree().paused = false
	pause_overlay.hide()
	if intro_tween != null and intro_tween.is_running():
		intro_tween.kill()
	if chapter_tween != null and chapter_tween.is_running():
		chapter_tween.kill()
	_cancel_fail()
	chapter_close_active = false
	tutorial_step = 0
	title_open = false
	title_screen.hide()
	state = M0State.new()
	save_error = ""
	intro_active = true
	intro_step = 0
	last_top_card_key = ""
	waiting_for_choice = false
	choice_context = ""
	relay_refused = false
	wolf_heading_to_relay = false
	wolf_scouting = false
	_sync_scene()
	human.hide()
	intro_director.position = Vector2(255.0, 410.0)
	intro_director.show()
	purge_terminal_art.hide()
	$BreakerLabel.hide()
	$RelayLabel.hide()
	$CheckpointLabel.hide()
	for station: CanvasItem in [breaker_art, relay_art, checkpoint_art, breaker_status_light, relay_status_light, door_visual]:
		station.hide()
	wolf.position = Vector2(115.0, 423.0)
	wolf.z_index = ACTOR_Z
	wolf.body_sprite.position = WOLF_SPRITE_REST
	wolf.body_sprite.modulate = Color("#365263")
	intro_gate.position = Vector2(115.0, 365.0)
	intro_gate.set("opening", 0.0)
	$IntroCage.show()
	intro_gate.show()
	intro_camera.position = Vector2(267.0, 355.0)
	intro_camera.position_smoothing_enabled = false
	intro_camera.zoom = Vector2(1.8, 1.8)
	intro_alarm.color.a = 0.0
	intro_fade.color.a = 1.0
	intro_tween = create_tween()
	intro_tween.tween_property(intro_fade, "color:a", 0.0, 0.55)
	status_line = "DIRECTOR: I decide who counts as a threat. WOLF handles the rest.\nHe thinks WOLF is still in standby."
	queue_redraw()
	_refresh_ui()


func _advance_intro() -> void:
	if intro_step >= 5:
		return
	if intro_tween != null and intro_tween.is_running():
		intro_tween.kill()
	intro_fade.color.a = 0.0
	if intro_step == 0:
		intro_step = 1
		status_line = "Nobody gives an activation command. WOLF wakes himself.\nA blue light answers from inside the containment seal."
		intro_tween = create_tween()
		intro_tween.tween_property(wolf.body_sprite, "modulate", Color("#9deeff"), 0.45)
		intro_tween.parallel().tween_property(intro_camera, "zoom", Vector2(1.95, 1.95), 0.45)
	elif intro_step == 1:
		intro_step = 2
		wolf.body_sprite.modulate = Color("#9deeff")
		intro_camera.zoom = Vector2(1.95, 1.95)
		status_line = "The latch breaks from the inside. The gate slides aside. WOLF steps out under his own power.\nThe Director freezes at the sound of the seal opening."
		_shutter_boom()
		intro_tween = create_tween()
		intro_tween.tween_property(intro_gate, "opening", 1.0, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		intro_tween.parallel().tween_property(intro_alarm, "color:a", 0.13, 0.18)
		intro_tween.tween_callback(intro_gate.hide)
		intro_tween.tween_callback(func() -> void: wolf.z_index = 5)
		intro_tween.tween_property(wolf.body_sprite, "position:y", WOLF_SPRITE_REST.y + 8.0, 0.28)
		intro_tween.tween_callback(func() -> void: wolf.autonomous_target_x = 185.0)
	elif intro_step == 2:
		intro_step = 3
		intro_gate.hide()
		wolf.z_index = 5
		wolf.body_sprite.position.y = WOLF_SPRITE_REST.y + 8.0
		wolf.autonomous_target_x = 185.0
		status_line = "DIRECTOR: You were in standby.\nWOLF: I heard you. I won't do it."
		intro_tween = create_tween()
		intro_tween.tween_property(intro_director, "position:x", 310.0, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		intro_tween.parallel().tween_property(intro_camera, "position:x", 300.0, 0.65)
		intro_tween.parallel().tween_property(intro_alarm, "color:a", 0.05, 0.65)
	elif intro_step == 3:
		intro_step = 4
		intro_director.position.x = 310.0
		status_line = "DIRECTOR: Lock down maintenance. WOLF does not leave this site.\nWOLF turns from him and takes the only open route."
		wolf.autonomous_target_x = 110.0
	else:
		intro_step = 5
		intro_tween = create_tween()
		intro_tween.tween_property(intro_fade, "color:a", 1.0, 0.3)
		intro_tween.tween_callback(_finish_intro.bind(true))
		intro_tween.tween_property(intro_fade, "color:a", 0.0, 0.35)


func _finish_intro(keep_fade: bool = false) -> void:
	intro_active = false
	intro_step = 0
	if not keep_fade and intro_tween != null and intro_tween.is_running():
		intro_tween.kill()
	if not keep_fade:
		intro_fade.color.a = 0.0
	intro_alarm.color.a = 0.0
	intro_gate.hide()
	$IntroCage.hide()
	intro_director.hide()
	human.show()
	purge_terminal_art.show()
	$BreakerLabel.show()
	$RelayLabel.show()
	$CheckpointLabel.show()
	for station: CanvasItem in [breaker_art, relay_art, checkpoint_art, breaker_status_light, relay_status_light, door_visual]:
		station.show()
	_start_gameplay_camera()
	wolf.body_sprite.modulate = Color.WHITE
	wolf.body_sprite.position = WOLF_SPRITE_REST
	wolf.z_index = ACTOR_Z
	wolf.position = state.wolf_position
	wolf.autonomous_target_x = -1.0
	_sync_door()
	_update_controls()
	_mark_beat()
	status_line = "WOLF: I heard the Director's plan for me. I woke myself. He wants me to hunt people he calls threats.\n%s: Then we get through maintenance before the original logs disappear." % state.human_name().get_slice(" ", 0).to_upper()
	queue_redraw()
	_refresh_ui()


func _show_credits() -> void:
	credits_paused = false
	credits_pause_button.text = "PAUSE SCROLL"
	_show_title_overlay(credits_screen)
	credits_body.get_v_scroll_bar().value = 0.0
	_grab_menu_focus(credits_back_button)


func _hide_credits() -> void:
	_hide_title_overlay(credits_screen)
	_grab_menu_focus(credits_button)


## Credits and the changelog replace the title menu over the key art; closing one restores the menu
## without revealing the other.
func _show_title_overlay(overlay: Control) -> void:
	for child: Node in title_screen.get_children():
		if child is CanvasItem and child != overlay and child != $CanvasLayer/TitleScreen/CorridorArt:
			(child as CanvasItem).hide()
	overlay.show()


func _hide_title_overlay(overlay: Control) -> void:
	overlay.hide()
	for child: Node in title_screen.get_children():
		if child is CanvasItem and child != credits_screen and child != changelog_screen:
			(child as CanvasItem).show()


func _toggle_credits_pause() -> void:
	credits_paused = not credits_paused
	credits_pause_button.text = "RESUME SCROLL" if credits_paused else "PAUSE SCROLL"


func _on_credits_body_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		credits_paused = true
		credits_pause_button.text = "RESUME SCROLL"


## Dragging the changelog text scrolls it: a touch drag, or the mouse moved with the left button held.
## Touch also arrives as an emulated mouse motion, which is skipped so one finger does not scroll twice.
func _on_changelog_body_input(event: InputEvent) -> void:
	var drag: float = 0.0
	if event is InputEventScreenDrag:
		drag = (event as InputEventScreenDrag).relative.y
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and (event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		drag = (event as InputEventMouseMotion).relative.y
	if drag != 0.0:
		changelog_body.get_v_scroll_bar().value -= drag
		changelog_body.accept_event()


func _setup_touch_controls() -> void:
	_bind_touch_button(touch_left, &"move_left")
	_bind_touch_button(touch_right, &"move_right")
	_bind_touch_button(touch_use, &"interact")
	_bind_touch_button(touch_choice_1, &"choice_1")
	_bind_touch_button(touch_choice_2, &"choice_2")
	# Button looks come from the project theme (game_theme.tres): touch and HUD buttons use its TouchButton
	# variation from the scene, and Settings applies the Terminal variations itself.
	settings_menu.apply_theme()


func _bind_touch_button(button: Button, action: StringName) -> void:
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))


func _setup_settings() -> void:
	fps_options.add_item("30 FPS", 30)
	fps_options.add_item("60 FPS", 60)
	fps_options.add_item("UNCAPPED", 0)
	fps_options.add_item("90 FPS", 90)
	fps_options.add_item("120 FPS", 120)
	fps_options.add_item("144 FPS", 144)
	resolution_options.add_item("960 × 540", 0)
	resolution_options.add_item("1280 × 720", 1)
	resolution_options.add_item("1920 × 1080", 2)
	var config: ConfigFile = GameSettings.load_config(settings_path)
	var fps: int = int(GameSettings.number(config, "video", "fps_limit", 60))
	if not fps in [0, 30, 60, 90, 120, 144]:
		fps = 60
	Engine.max_fps = fps
	fps_options.select(fps_options.get_item_index(fps))
	var resolution: int = clampi(int(GameSettings.number(config, "video", "resolution", 0)), 0, 2)
	resolution_options.select(resolution)
	var mobile: bool = OS.has_feature("ios") or OS.has_feature("android")
	resolution_options.disabled = mobile
	fullscreen_toggle.disabled = mobile
	settings_note.text = "Window size is managed by iOS/Android." if mobile else "Window size applies on desktop."
	if mobile:
		$CanvasLayer/PauseOverlay/Panel/PauseMenu/PauseHint.text = "TAP RESUME TO RETURN"
	if not mobile:
		get_window().size = _resolution_size(resolution)
		fullscreen_toggle.button_pressed = GameSettings.boolean(config, "video", "fullscreen", false)
		if fullscreen_toggle.button_pressed:
			get_window().mode = Window.MODE_FULLSCREEN
	fps_options.item_selected.connect(_on_fps_selected)
	resolution_options.item_selected.connect(_on_resolution_selected)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	settings_menu.configure(settings_path)


func _resolution_size(index: int) -> Vector2i:
	match index:
		1:
			return Vector2i(1280, 720)
		2:
			return Vector2i(1920, 1080)
		_:
			return Vector2i(960, 540)


func _on_fps_selected(index: int) -> void:
	Engine.max_fps = fps_options.get_item_id(index)
	_save_settings()


func _on_resolution_selected(index: int) -> void:
	if not resolution_options.disabled:
		get_window().size = _resolution_size(index)
		_save_settings()


func _on_fullscreen_toggled(enabled: bool) -> void:
	if not fullscreen_toggle.disabled:
		get_window().mode = Window.MODE_FULLSCREEN if enabled else Window.MODE_WINDOWED
		_save_settings()


func _save_settings() -> void:
	var config: ConfigFile = GameSettings.load_config(settings_path)
	config.set_value("video", "fps_limit", fps_options.get_selected_id())
	config.set_value("video", "resolution", resolution_options.selected)
	config.set_value("video", "fullscreen", fullscreen_toggle.button_pressed)
	if config.save(settings_path) != OK:
		settings_note.text = "Settings could not be saved."


func _on_pause_button() -> void:
	_pause_game()


func _pause_game() -> void:
	for action: StringName in GAMEPLAY_ACTIONS:
		Input.action_release(action)
	impact.end_hit_stop()
	_show_pause_menu()
	pause_overlay.show()
	_fade_backdrop()
	pause_button.hide()
	touch_controls.hide()
	get_tree().paused = true
	_grab_menu_focus(resume_button)


func _resume_game() -> void:
	settings_menu.cancel_capture()
	get_tree().paused = false
	pause_overlay.hide()
	# A pause that landed inside a hit-stop or flash never leaves play slowed or tinted.
	impact.reset()
	_refresh_ui()


func _show_settings() -> void:
	pause_menu.hide()
	menu_panel.position = Vector2(100, 38)
	menu_panel.size = Vector2(760, 464)
	$CanvasLayer/PauseOverlay/Panel/Accent.hide()
	settings_menu.show()
	_reveal_menu()
	_grab_menu_focus(settings_menu.tabs)


func _show_title_settings() -> void:
	pause_overlay.show()
	_fade_backdrop()
	get_tree().paused = true
	_show_settings()


## The dimmed backdrop fades in when the overlay opens; the card slides in separately so Settings
## and the pause menu each arrive with the same short motion.
func _fade_backdrop() -> void:
	if backdrop_tween != null and backdrop_tween.is_running():
		backdrop_tween.kill()
	pause_overlay.modulate.a = 0.0
	backdrop_tween = pause_overlay.create_tween()
	backdrop_tween.tween_property(pause_overlay, "modulate:a", 1.0, MENU_REVEAL_SECONDS)


func _reveal_menu() -> void:
	if menu_tween != null and menu_tween.is_running():
		menu_tween.kill()
	var resting: Vector2 = menu_panel.position
	menu_panel.position = resting + MENU_REVEAL_OFFSET
	menu_panel.modulate.a = 0.0
	menu_tween = pause_overlay.create_tween().set_parallel(true)
	menu_tween.tween_property(menu_panel, "position", resting, MENU_REVEAL_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	menu_tween.tween_property(menu_panel, "modulate:a", 1.0, MENU_REVEAL_SECONDS)


func _show_pause_menu() -> void:
	if title_open and pause_overlay.visible:
		_resume_game()
		_grab_menu_focus($CanvasLayer/TitleScreen/SettingsButton)
		return
	settings_menu.cancel_capture()
	menu_panel.position = Vector2(255, 55)
	menu_panel.size = Vector2(450, 430)
	pause_menu.size = Vector2(450, 430)
	$CanvasLayer/PauseOverlay/Panel/Accent.show()
	settings_menu.hide()
	pause_menu.show()
	$CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton.text = "SKIP OPENING" if intro_active else "RETURN TO TITLE"
	$CanvasLayer/PauseOverlay/Panel/PauseMenu/ReturnWarning.visible = not intro_active
	$CanvasLayer/PauseOverlay/Panel/PauseMenu/PauseHint.text = "TAP RESUME TO RETURN" if touch_enabled and not controller_active else "%s  RESUME" % settings_menu.prompt(&"pause_game", controller_active)
	_reveal_menu()
	_grab_menu_focus(resume_button)


func _return_to_title() -> void:
	_resume_game()
	if intro_active:
		_finish_intro()
	if chapter_tween != null and chapter_tween.is_running():
		chapter_tween.kill()
	_cancel_fail()
	# The junction's hiss and pump loops never follow the player to the title.
	sfx_bank.stop(&"hiss")
	sfx_bank.stop(&"hum")
	intro_fade.color.a = 0.0
	chapter_close_active = false
	waiting_for_choice = false
	choice_context = ""
	title_open = true
	_hide_credits()
	changelog_screen.hide()
	title_screen.show()
	_refresh_continue()
	_update_controls()
	_refresh_ui()
	_grab_menu_focus(new_game_button)


## Keyboard and controller players need a focused menu control; pure touch play shows no focus ring.
## Touch clears focus instead, so a stale focus behind an overlay cannot take the next key press.
func _grab_menu_focus(control: Control) -> void:
	if title_screen.is_ancestor_of(control):
		title_focus_return = control
	if touch_enabled and not controller_active:
		get_viewport().gui_release_focus()
	else:
		control.grab_focus()


## The menu control a keyboard or controller press should land on when nothing has focus.
func _menu_focus_target() -> Control:
	if pause_overlay.visible:
		return settings_menu.tabs if settings_menu.visible else resume_button
	if title_open:
		if credits_screen.visible:
			return credits_back_button
		if changelog_screen.visible:
			return changelog_back_button
		return title_focus_return if title_focus_return != null and title_focus_return.is_visible_in_tree() else new_game_button
	return null


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and (credits_screen.visible or changelog_screen.visible):
		if credits_screen.visible:
			_hide_credits()
		else:
			_hide_changelog()
		get_viewport().set_input_as_handled()
		return
	# Pause is event-driven so the press that resumes from PauseOverlay (handled in its _input)
	# can never re-pause in the same frame.
	if title_open or get_tree().paused or event.is_echo() or not event.is_action_pressed(&"pause_game"):
		return
	_pause_game()
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_handle_back()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Leaving the app mid-play pauses it so nothing advances unseen.
			if auto_pause_on_focus_loss and is_node_ready() and not title_open and not get_tree().paused:
				_pause_game()


## Android Back walks out of nested menus one step at a time; it only quits from the bare title.
func _handle_back() -> void:
	if not settings_menu.capture_action.is_empty():
		settings_menu.cancel_capture()
	elif pause_overlay.visible and settings_menu.visible:
		_on_settings_back()
	elif pause_overlay.visible:
		_resume_game()
	elif credits_screen.visible:
		_hide_credits()
	elif changelog_screen.visible:
		_hide_changelog()
	elif title_open:
		get_tree().quit()
	else:
		_pause_game()


func _on_title_button() -> void:
	if intro_active:
		_resume_game()
		_finish_intro()
	else:
		_return_to_title()


func _on_settings_back() -> void:
	_show_pause_menu()
	if not title_open:
		_grab_menu_focus(settings_button)


func _input(event: InputEvent) -> void:
	_note_input_device(event)
	# Direct response bindings win over native focused-button acceptance.
	if waiting_for_choice and not title_open and not get_tree().paused and not event.is_echo():
		var response: int = 1 if event.is_action_pressed(&"choice_1") else (2 if event.is_action_pressed(&"choice_2") else 0)
		if response != 0:
			if choice_context == "mirror":
				_choose_mirror("wolf" if response == 1 else "manual")
			else:
				_choose(M0State.DISCLOSE if response == 1 else M0State.PRESS)
			get_viewport().set_input_as_handled()


## Called from _input during play and from PauseOverlay while the tree is paused.
func _note_input_device(event: InputEvent) -> void:
	var use_controller: bool = controller_active
	var navigation_press: bool = false
	if event is InputEventJoypadButton and event.pressed or event is InputEventJoypadMotion and absf(event.axis_value) > 0.45:
		use_controller = true
		navigation_press = true
		# Rumble goes to the pad that is actually in use, not always the first one connected.
		impact.rumble_device = event.device
	elif event is InputEventScreenTouch and event.pressed or event is InputEventScreenDrag or event is InputEventKey and event.pressed or event is InputEventMouseButton and event.pressed:
		use_controller = false
		navigation_press = event is InputEventKey
	if use_controller != controller_active:
		controller_active = use_controller
		_refresh_ui()
	# Touch menus open unfocused; the first key or controller press gives keyboard and controller players a focus to move.
	if navigation_press and get_viewport().gui_get_focus_owner() == null:
		var target: Control = _menu_focus_target()
		if target != null and target.is_visible_in_tree():
			target.grab_focus()
			# A navigation or confirm press only reveals focus; it must not also move it or activate the control.
			for action: StringName in MENU_NAVIGATION_ACTIONS:
				if event.is_action_pressed(action):
					get_viewport().set_input_as_handled()
					break


func _load_game() -> void:
	get_tree().paused = false
	pause_overlay.hide()
	last_top_card_key = ""
	var loaded: M0State = M0State.load_from_disk(save_path)
	if loaded == null:
		status_line = "No valid checkpoint save found. Current game was not changed."
		return
	title_open = false
	title_screen.hide()
	intro_active = false
	if chapter_tween != null and chapter_tween.is_running():
		chapter_tween.kill()
	chapter_close_active = false
	tutorial_step = 2
	if intro_tween != null and intro_tween.is_running():
		intro_tween.kill()
	intro_gate.hide()
	intro_director.hide()
	intro_fade.color.a = 0.0
	intro_alarm.color.a = 0.0
	human.show()
	$IntroCage.hide()
	wolf.z_index = ACTOR_Z
	wolf.body_sprite.position = WOLF_SPRITE_REST
	purge_terminal_art.show()
	$BreakerLabel.show()
	$RelayLabel.show()
	$CheckpointLabel.show()
	queue_redraw()
	wolf.body_sprite.modulate = Color.WHITE
	state = loaded
	save_error = ""
	waiting_for_choice = false
	choice_context = ""
	relay_refused = false
	wolf_heading_to_relay = false
	wolf_scouting = false
	fail_active = false
	hold_use.reset()
	_sync_scene()
	_start_gameplay_camera()
	if state.chapter_id == "junction":
		if state.door_blown:
			status_line = "Service junction restored. The door is down; the lane past the rubble is next."
		else:
			status_line = "Service junction restored. Arm the breaker on the left, then crank the valve by the door."
	elif state.chapter_id == "records":
		if state.chapter_complete:
			status_line = "The first copy is safe. Use the exit to follow the service line."
		elif state.mirror_trace_preserved:
			status_line = "Records access restored. Both traces are copied; head for the exit."
		elif state.purge_trace_preserved:
			status_line = "Records access restored. The purge order is copied; copy the mirror index next."
		else:
			status_line = "Records access restored. Copy the purge-order trace first; WOLF is checking the mirror."
	else:
		status_line = "Safe point restored. " + state.checkpoint_callback()


func _interact() -> void:
	var x: float = human.position.x
	tutorial_step = 2
	if state.chapter_id == "records":
		_interact_records(x)
		return
	if state.chapter_id == "junction":
		_interact_junction(x)
		return
	if x <= 230.0:
		status_line = "DIRECTOR / PURGE: Original program logs marked for deletion.\nWOLF: They want the source record gone. We need to preserve it."
	elif absf(x - 350.0) <= 52.0:
		_interact_breaker()
	elif absf(x - 605.0) <= 52.0:
		_interact_relay()
	elif absf(x - 876.0) <= 52.0:
		_interact_checkpoint()
	else:
		status_line = "No station in reach. Follow the labeled breaker, relay or safe point."


func _interact_breaker() -> void:
	if state.memory.is_empty():
		waiting_for_choice = true
		choice_context = "relay"
		_update_controls()
		status_line = "WOLF: You know what 'coolant fault' means. What happens if I touch the live relay?\n1  \"%s\"\n2  \"%s\"" % [M0State.CHOICE_TEXT[M0State.DISCLOSE], M0State.CHOICE_TEXT[M0State.PRESS]]
	elif state.arm_breaker():
		status_line = "The breaker catches. Blue light fills the coolant relay; the red seal stays shut."
		sfx_bank.play(&"clank", -4.0, 0.8)
		impact.rumble(0.15, 0.0, 0.06)
		_mark_beat()
		queue_redraw()
	else:
		status_line = "Power is already on. The relay is farther down the hall."


func _choose(choice_id: String) -> void:
	if not state.record_choice(choice_id):
		return
	waiting_for_choice = false
	choice_context = ""
	_update_controls()
	_mark_beat()
	if choice_id == M0State.DISCLOSE:
		status_line = "WOLF: Thank you for telling me. I'll take the relay. Arm the breaker."
		_react_as_wolf(true)
	else:
		status_line = "WOLF: No. I won't take that risk blind. Use the bypass."
		_react_as_wolf(false)


func _interact_relay() -> void:
	var relay_actor: String = "human" if relay_refused else "wolf"
	if relay_actor == "wolf" and state.breaker_armed and not state.door_open and state.memory.get("choice_id") == M0State.DISCLOSE:
		if wolf_heading_to_relay:
			# Using the relay again while WOLF is still on his way is the engineer's bypass.
			relay_actor = "human"
		elif absf(wolf.position.x - RELAY_CONTACT_X) > 4.0:
			# WOLF chooses the contact himself; the seal opens when he arrives (see _process).
			wolf_heading_to_relay = true
			_update_controls()
			status_line = "WOLF: I've got the contact. Give me a moment."
			_react_as_wolf(true)
			return
	var result: String = state.activate_power(relay_actor)
	match result:
		"not_ready":
			status_line = "The relay is dark. Speak at the breaker and arm the power first."
		"refused":
			relay_refused = true
			status_line = "WOLF: I said no. I won't take the live contact. Press E again for the manual bypass."
			_react_as_wolf(false)
			queue_redraw()
		"cooperate":
			status_line = "WOLF holds the live contact by choice. %s keeps the breaker on; the red seal rises." % state.human_name().get_slice(" ", 0)
			_react_as_wolf(true)
			_flash_relay_spark(true)
		"fallback":
			status_line = "%s takes the bypass. WOLF reads the rising seal: \"Open. I'm with you.\"" % state.human_name().get_slice(" ", 0)
			_flash_relay_spark(false)
		"already_open":
			status_line = "The seal is open. The safe point is just beyond it."
		_:
			status_line = "This actor cannot use the relay."
	if result == "cooperate" or result == "fallback":
		wolf_heading_to_relay = false
		_update_controls()
		_sync_door(true)
		_mark_beat()


func _wolf_takes_relay() -> void:
	wolf_heading_to_relay = false
	if state.activate_power("wolf") == "cooperate":
		status_line = "WOLF holds the live contact by choice. %s keeps the breaker on; the red seal rises." % state.human_name().get_slice(" ", 0)
		_react_as_wolf(true)
		_flash_relay_spark(true)
		_sync_door(true)
		_mark_beat()
	_update_controls()


func _interact_checkpoint() -> void:
	if not state.door_open:
		status_line = "The safe point is past the sealed door."
		return
	if state.checkpoint_reached:
		if state.enter_records():
			_sync_scene()
			var remembered_line: String = "I refused the live relay; I'm still here." if state.memory.get("choice_id") == M0State.PRESS else ("I chose the relay. I'm checking this path too." if state.route == "cooperate" else "You used the manual bypass. I'm checking this path with you.")
			status_line = "WOLF: %s\nTake the purge queue. I'll inspect the mirror." % remembered_line
			_save_progress()
		return
	var first_visit: bool = state.reach_checkpoint()
	queue_redraw()
	_capture_positions()
	if not state.save_to_disk(save_path):
		if first_visit:
			state.checkpoint_reached = false
		status_line = "The safe point could not save. Press E here again."
		return
	save_error = ""
	if first_visit:
		status_line = "Safe point saved. " + state.checkpoint_callback()
	else:
		status_line = "Safe point saved. WOLF remembers the same choice."


func _interact_records(x: float) -> void:
	if absf(x - 190.0) <= 58.0:
		if state.preserve_purge_trace():
			status_line = "The Director's purge order has a time and target ID. %s keeps a local copy; the original logs are still missing." % state.human_name().get_slice(" ", 0)
		else:
			status_line = "The purge-order trace is already copied. The mirror port may confirm when the source existed."
		_sync_records_room()
		_save_progress()
	elif absf(x - 520.0) <= 58.0:
		if not state.purge_trace_preserved:
			status_line = "The mirror index has no context yet. Copy the purge-order trace first."
		elif state.mirror_trace_preserved:
			status_line = "The mirror timestamp is already preserved. The exit is to the right."
			_save_progress()
		else:
			waiting_for_choice = true
			choice_context = "mirror"
			_update_controls()
			status_line = "WOLF: I found the mirror index. We can use my readout or your maintenance port.\n1  USE WOLF'S READOUT     2  USE MANUAL PORT"
	elif absf(x - 830.0) <= 58.0:
		if state.complete_chapter():
			status_line = "FIRST COPY SECURED. WOLF: A list doesn't tell me who's a threat. I want the source.\n%s: Then Archive is next." % state.human_name().get_slice(" ", 0).to_upper()
			chapter_close_active = true
			intro_camera.position_smoothing_enabled = false
			_update_controls()
			_sync_records_room(true)
			# The exit arc: the bolt lets go with a crackle, a small kick and a spark shower.
			sfx_bank.play(&"arc", -3.0)
			impact.add_trauma(0.3)
			impact.flash(0.06, 0.0)
			impact.rumble(0.3, 0.4, 0.12)
			impact.burst(exit_sparks)
			chapter_tween = create_tween()
			chapter_tween.tween_property(intro_camera, "position", Vector2(576.0, 330.0), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			chapter_tween.parallel().tween_property(intro_camera, "zoom", Vector2(1.25, 1.25), 0.5)
			chapter_tween.parallel().tween_property(records_room.exit_art, "position:y", 245.0, 0.5)
			chapter_tween.parallel().tween_property(records_room.exit_art, "modulate:a", 0.0, 0.5)
			chapter_tween.tween_callback(records_room.exit_art.hide)
			_save_progress()
		elif state.chapter_complete:
			_enter_junction()
		else:
			status_line = "Exit sealed until the purge order and mirror timestamp are copied."
	else:
		status_line = "Follow the station lights: purge queue, mirror port, then exit."


func _finish_chapter_close() -> void:
	if chapter_tween != null and chapter_tween.is_running():
		chapter_tween.kill()
	chapter_close_active = false
	_start_gameplay_camera()
	_sync_records_room()
	_update_controls()


func _choose_mirror(route_id: String) -> void:
	if route_id == "wolf" and absf(wolf.position.x - 520.0) > 42.0:
		status_line = "WOLF: I'm still checking the drive. Wait for me, or press 2 for the manual port."
		return
	if not state.preserve_mirror_trace(route_id):
		return
	waiting_for_choice = false
	choice_context = ""
	_update_controls()
	if route_id == "wolf":
		status_line = "WOLF brings the mirror timestamp by his own choice. The purge target existed before the deletion order."
	else:
		status_line = "%s copies the timestamp through the maintenance port. WOLF keeps watch." % state.human_name().get_slice(" ", 0)
	_sync_records_room()
	_save_progress()


func _save_progress() -> void:
	_capture_positions()
	# Save errors belong to the system hint, never inside a character's dialogue line.
	save_error = "" if state.save_to_disk(save_path) else SAVE_FAILED_HINT
	# Remember where it failed so the warning gives way to normal guidance once the player moves on.
	save_error_context = _context_hint()


func _capture_positions() -> void:
	state.human_position = human.position
	state.wolf_position = wolf.position


## Remembers the state at the start of a beat. Before the first checkpoint there is no autosave,
## so a knockdown restores this instead; it carries the relay memory like a save would.
func _mark_beat() -> void:
	_capture_positions()
	beat_snapshot = state.to_dict()


## The station in reach that takes a held USE, or empty: only the junction valve while its line builds.
func _hold_station() -> StringName:
	if state.chapter_id == "junction" and pressure_line.state == &"building" and absf(human.position.x - JunctionRoom.VALVE_X) <= 52.0:
		return &"valve"
	return &""


## USE at the Records exit once the first copy is secured: the service line to Archive begins.
func _enter_junction() -> void:
	if not state.enter_junction():
		return
	_sync_scene()
	wolf_scouting = true
	_update_controls()
	status_line = "WOLF runs ahead to read the pressure behind the sealed door.\n%s: The breaker on the left feeds that line. Overload it, crank the valve, and the seal goes." % state.human_name().get_slice(" ", 0).to_upper()
	# Autosave A: the start of the junction.
	_save_progress()


func _interact_junction(x: float) -> void:
	if absf(x - JunctionRoom.BREAKER_X) <= 52.0:
		if pressure_line.arm():
			sfx_bank.play(&"clank", -4.0, 0.8)
			impact.rumble(0.15, 0.0, 0.06)
			junction_room.sync_line(pressure_line)
			status_line = "The overload breaker catches. The line starts to build; the relief vent lets go at the top of the gauge."
		elif state.door_blown:
			status_line = "The breaker is spent. The door is down."
		elif pressure_line.state == &"building":
			status_line = "The line is live. Crank the valve by the door before the vent lets go."
		else:
			status_line = "Seal charged. Get left of the vent before the fuse ends."
	elif absf(x - JunctionRoom.VALVE_X) <= 52.0:
		match pressure_line.state:
			&"idle":
				status_line = "The valve is dead. Arm the overload breaker on the left first."
			&"tripped":
				status_line = "The vent let go and the breaker tripped. Reset it on the left."
			&"building":
				status_line = "The wheel is stiff. Hold USE to crank it; three real turns charge the seal."
			&"charged", &"fuse":
				status_line = "Seal charged. Get left of the vent before the fuse ends."
			_:
				status_line = "The valve is spent. The door is down."
	elif PressureLine.is_on_vent(x):
		status_line = "Relief vent. It lets go when the gauge peaks; don't be standing on it."
	elif absf(x - JunctionRoom.DOOR_X) <= 40.0 and not state.door_blown:
		status_line = "The door is sealed from the other side. Something hums behind it."
	elif absf(x - JunctionRoom.HATCH_X) <= 52.0:
		status_line = "The exit hatch is bolted. The lane past the door comes first."
	else:
		status_line = "No station in reach. The breaker is on the left, the valve by the door."


## Runs the pressure line every frame in the junction: held USE at the valve cranks it, the line
## advances, and its events (vent trip, fuse, blast) answer with real state changes.
func _tick_junction(delta: float) -> void:
	pressure_line.paused = waiting_for_choice
	if hold_use.holding and hold_use.station == &"valve":
		var gained: int = pressure_line.crank(delta)
		if gained > 0:
			_valve_turned()
	else:
		pressure_line.release()
	match pressure_line.advance(delta):
		&"tripped":
			_vent_trips()
		&"blown":
			_door_blast()
	if wolf_scouting and absf(wolf.position.x - JunctionRoom.WOLF_SEAM_X) <= 4.0:
		_wolf_reads_seam()
	junction_room.sync_line(pressure_line)
	# Hiss and pump pitch are functions of the gauge, nothing else.
	if pressure_line.state == &"building":
		sfx_bank.play(&"hiss", lerpf(-28.0, -8.0, pressure_line.gauge))
	else:
		sfx_bank.stop(&"hiss")
	if state.door_blown:
		sfx_bank.stop(&"hum")
	else:
		sfx_bank.play(&"hum", lerpf(-16.0, -9.0, pressure_line.gauge), 0.5 * (1.0 + 0.6 * pressure_line.gauge))


## One real valve turn: a click, a weak rumble, one light; the third turn lights the fuse.
func _valve_turned() -> void:
	sfx_bank.play(&"clank", -6.0, 1.4)
	impact.rumble(0.2, 0.0, 0.08)
	if pressure_line.state == &"charged":
		sfx_bank.play(&"klaxon", -4.0)
		status_line = "SEAL CHARGED. Get left of the vent before the fuse ends."
	else:
		status_line = "The valve gives. %d of %d turns." % [pressure_line.turns, PressureLine.TURNS_NEEDED]


## The gauge peaked before the third turn: the relief vent lets go and the breaker trips.
func _vent_trips() -> void:
	junction_room.vent_blows()
	sfx_bank.play(&"small_boom", -2.0)
	impact.add_trauma(0.5)
	impact.flash(0.0, 0.2)
	impact.rumble(0.4, 0.6, 0.2)
	if not fail_active:
		status_line = "The relief vent lets go and the breaker trips. Reset the breaker and crank faster this time."


func _wolf_reads_seam() -> void:
	wolf_scouting = false
	_react_as_wolf(false)
	sfx_bank.play(&"growl", -6.0)
	status_line = "WOLF: It's live. Don't stand in front of it when it goes."
	_update_controls()


## BOOM 1: the fuse ends. PressureLine.is_in_blast is the one test of the outcome: in the zone it
## is a knockdown back to autosave A with the door still sealed; otherwise the door goes, the
## rubble lands and autosave B marks the beat. The blast has no hurtbox of its own, so physics
## overlap can never disagree with this test.
func _door_blast() -> void:
	_blast_feedback()
	if PressureLine.is_in_blast(human.position.x):
		_fail_beat(JunctionRoom.BLAST_REASON)
		return
	if not state.blow_door():
		return
	junction_room.door_blast()
	_update_controls()
	status_line = "The seal goes. WOLF holds at the rubble and will not cross; something answers from the dark past the door."
	# Autosave B: the door is down.
	_save_progress()


func _blast_feedback() -> void:
	sfx_bank.stop(&"hiss")
	sfx_bank.play(&"boom", 0.0)
	impact.hit_stop(0.07)
	impact.flash(0.09, 0.3)
	impact.add_trauma(1.0)
	impact.rumble(0.7, 1.0, 0.3)


## One path for every knockdown: a readable reaction (hit-stop, red wash, the engineer tilts and
## slides with a thud and rumble), controls off briefly, a short fade, then the current beat's
## autosave comes back through _load_game/_sync_scene. Memory and Records flags are never touched.
## With Reduced Motion the tilt, hit-stop and shake are skipped; the thud, wash and fade remain.
func _fail_beat(reason: String) -> void:
	if fail_active or title_open or intro_active or chapter_close_active:
		return
	fail_active = true
	for action: StringName in GAMEPLAY_ACTIONS:
		Input.action_release(action)
	waiting_for_choice = false
	choice_context = ""
	wolf_heading_to_relay = false
	human.velocity = Vector2.ZERO
	_update_controls()
	impact.hit_stop(0.06)
	impact.flash(0.0, 0.3)
	impact.add_trauma(0.6)
	impact.rumble(0.5, 0.9, 0.25)
	sfx_bank.play(&"thud", 0.0, 0.9)
	human.z_index = KNOCKDOWN_Z
	_cancel_fail_tween()
	fail_tween = create_tween()
	var reaction_seconds: float = 0.0
	if impact.motion_allowed():
		# Fall away from the facing direction so the hit reads as a shove, not a stumble forward.
		var facing: float = -1.0 if human.body_sprite.flip_h else 1.0
		reaction_seconds = 0.22
		fail_tween.tween_property(human.body_sprite, "rotation_degrees", -70.0 * facing, reaction_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		fail_tween.parallel().tween_property(human.body_sprite, "position", HUMAN_SPRITE_REST + Vector2(-30.0 * facing, 14.0), reaction_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	fail_tween.tween_interval(FAIL_CONTROLS_OFF_SECONDS - reaction_seconds)
	fail_tween.tween_property(intro_fade, "color:a", 1.0, FAIL_FADE_SECONDS)
	fail_tween.tween_callback(_restore_beat.bind(reason))
	fail_tween.tween_property(intro_fade, "color:a", 0.0, 0.35)
	status_line = reason
	_refresh_ui()


func _restore_beat(reason: String) -> void:
	fail_active = false
	var restored: bool = false
	var from_disk: bool = false
	if state.checkpoint_reached and M0State.load_from_disk(save_path) != null:
		_load_game()
		restored = true
		from_disk = true
	elif not beat_snapshot.is_empty():
		var snapshot: M0State = M0State.from_dict(beat_snapshot)
		if snapshot != null:
			state = snapshot
			relay_refused = false
			wolf_heading_to_relay = false
			wolf_scouting = false
			last_top_card_key = ""
			hold_use.reset()
			_sync_scene()
			_start_gameplay_camera()
			restored = true
	if not restored:
		_sync_scene()
	# _load_game clears the fade; the knockdown's fade-in starts from black.
	intro_fade.color.a = 1.0
	# Before the first checkpoint nothing is on disk; the beat snapshot is the start of this beat.
	status_line = "%s\n%s" % [reason, "Back at the last autosave." if from_disk else "Back at the start of this beat."]
	_refresh_ui()


func _cancel_fail_tween() -> void:
	if fail_tween != null and fail_tween.is_valid():
		fail_tween.kill()
	fail_tween = null


## Drops a knockdown in progress (New Game or Return to Title from Pause) without restoring anything.
func _cancel_fail() -> void:
	_cancel_fail_tween()
	fail_active = false
	human.body_sprite.rotation_degrees = 0.0
	human.body_sprite.position = HUMAN_SPRITE_REST
	human.z_index = ACTOR_Z


## The containment gate letting go in the opening: a boom, a kick and dust at its base.
func _shutter_boom() -> void:
	sfx_bank.play(&"boom", -2.0)
	impact.add_trauma(0.6)
	impact.flash(0.09, 0.0)
	impact.rumble(0.5, 0.9, 0.25)
	impact.burst(gate_dust)


## The seal finishing its rise into the ceiling.
func _door_lands() -> void:
	sfx_bank.play(&"thud", -2.0, 1.1)
	impact.add_trauma(0.5)
	impact.rumble(0.4, 0.6, 0.2)
	impact.burst(door_dust)


func _sync_scene() -> void:
	if wolf_reaction_tween != null and wolf_reaction_tween.is_running():
		wolf_reaction_tween.kill()
	if relay_spark_tween != null and relay_spark_tween.is_running():
		relay_spark_tween.kill()
	wolf.body_sprite.position = WOLF_SPRITE_REST
	wolf.body_sprite.rotation_degrees = 0.0
	human.body_sprite.position = HUMAN_SPRITE_REST
	human.body_sprite.rotation_degrees = 0.0
	human.z_index = ACTOR_Z
	relay_spark.hide()
	impact.reset()
	human.position = state.human_position
	wolf.position = state.wolf_position
	human.velocity = Vector2.ZERO
	wolf.velocity = Vector2.ZERO
	_update_controls()
	_sync_door()
	_sync_records_room()
	_sync_junction_room()


## The junction shows only in its chapter; its line, bursts and hazards go back to rest and its
## door matches the save, so a reload or a knockdown never carries a half-finished beat over.
func _sync_junction_room() -> void:
	var in_junction: bool = state.chapter_id == "junction"
	junction_room.visible = in_junction
	junction_room.door_blown = state.door_blown
	junction_room.set_active(in_junction)
	pressure_line.reset()
	junction_room.reset_transient()
	junction_room.sync_line(pressure_line)
	sfx_bank.stop(&"hiss")
	sfx_bank.stop(&"hum")


func _react_as_wolf(accepting: bool) -> void:
	if wolf_reaction_tween != null and wolf_reaction_tween.is_running():
		wolf_reaction_tween.kill()
	wolf.body_sprite.position = WOLF_SPRITE_REST
	wolf.body_sprite.rotation_degrees = 0.0
	var lean: Vector2 = Vector2(11.0, -24.0) if accepting else Vector2(-13.0, -13.0)
	var tilt: float = 8.0 if accepting else -9.0
	wolf_reaction_tween = create_tween()
	wolf_reaction_tween.tween_property(wolf.body_sprite, "position", lean, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	wolf_reaction_tween.parallel().tween_property(wolf.body_sprite, "rotation_degrees", tilt, 0.18)
	wolf_reaction_tween.tween_interval(0.18)
	wolf_reaction_tween.tween_property(wolf.body_sprite, "position", WOLF_SPRITE_REST, 0.24)
	wolf_reaction_tween.parallel().tween_property(wolf.body_sprite, "rotation_degrees", 0.0, 0.24)


func _flash_relay_spark(from_wolf: bool) -> void:
	if relay_spark_tween != null and relay_spark_tween.is_running():
		relay_spark_tween.kill()
	relay_spark.points = PackedVector2Array([
		Vector2(583.0, 393.0), Vector2(592.0, 381.0), Vector2(600.0, 398.0),
		Vector2(610.0, 380.0), Vector2(620.0, 393.0),
	])
	relay_spark.default_color = Color("#8be3ff") if from_wolf else Color("#f3ae4b")
	relay_spark.modulate.a = 1.0
	relay_spark.show()
	relay_spark_tween = create_tween()
	relay_spark_tween.tween_property(relay_spark, "modulate:a", 0.0, 0.48)
	relay_spark_tween.tween_callback(relay_spark.hide)
	# The contact itself: a clank with a short crackle, a kick and a spark shower in the route's colour.
	sfx_bank.play(&"clank", 0.0, 1.0 if from_wolf else 0.92)
	sfx_bank.play(&"arc", -8.0, 1.2)
	impact.add_trauma(0.35)
	impact.rumble(0.3, 0.5, 0.15)
	relay_sparks.color = relay_spark.default_color
	impact.burst(relay_sparks)


func _sync_records_room(animate_exit: bool = false) -> void:
	records_room.visible = state.chapter_id == "records"
	var in_corridor: bool = state.chapter_id == "lockdown"
	breaker_status_light.visible = in_corridor
	relay_status_light.visible = in_corridor
	# Every room's backdrop sits at the same depth as the corridor's, so corridor-only dressing hides with it.
	for corridor_only: CanvasItem in [corridor_depth, purge_terminal_art, breaker_art, relay_art, checkpoint_art, $BreakerLabel, $RelayLabel, $CheckpointLabel]:
		corridor_only.visible = in_corridor
	records_room.purge_trace_preserved = state.purge_trace_preserved
	records_room.mirror_trace_preserved = state.mirror_trace_preserved
	records_room.chapter_complete = state.chapter_complete
	records_room.exit_art.position = Vector2(830.0, 375.0)
	records_room.exit_art.modulate = Color.WHITE
	records_room.exit_art.visible = not state.chapter_complete or animate_exit
	records_room.refresh_state()


func _sync_door(animate: bool = false) -> void:
	if door_tween != null and door_tween.is_running():
		door_tween.kill()
	door_shape.set_deferred("disabled", state.door_open)
	door_visual.scale = Vector2.ONE
	door_visual.visible = state.chapter_id == "lockdown" and (not state.door_open or animate)
	if state.door_open and animate:
		door_tween = create_tween()
		door_tween.tween_property(door_visual, "scale:y", 0.0, 0.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		door_tween.tween_callback(door_visual.hide)
		door_tween.tween_callback(_door_lands)
	queue_redraw()


func _update_controls() -> void:
	human.controlled = not title_open and not intro_active and not chapter_close_active and not waiting_for_choice and not fail_active
	wolf.controlled = false
	wolf.autonomous_target_x = _wolf_target_x()
	wolf.follow_target = human if human.controlled and wolf.autonomous_target_x < 0.0 else null
	human.queue_redraw()
	wolf.queue_redraw()


## Where WOLF goes on his own, or -1 to follow: the relay contact, the Records mirror, the junction
## door seam on entry, and the rubble line once the door is down (he will not cross it yet).
func _wolf_target_x() -> float:
	if wolf_heading_to_relay:
		return RELAY_CONTACT_X
	match state.chapter_id:
		"records":
			return -1.0 if state.mirror_trace_preserved else 520.0
		"junction":
			if wolf_scouting:
				return JunctionRoom.WOLF_SEAM_X
			if state.door_blown and not state.sentry_down:
				return JunctionRoom.WOLF_RUBBLE_X
	return -1.0


func _refresh_ui() -> void:
	var touch_layout: bool = touch_enabled and not controller_active
	impact.rumble_enabled = controller_active
	impact.haptics_enabled = touch_layout
	pause_button.visible = not title_open and not pause_overlay.visible
	pause_button.text = "PAUSE"
	touch_controls.visible = (touch_layout or waiting_for_choice) and not title_open and not pause_overlay.visible
	var touch_move: bool = not intro_active and not chapter_close_active and not waiting_for_choice
	touch_left.visible = touch_layout and touch_move
	touch_right.visible = touch_layout and touch_move
	touch_use.visible = touch_layout and not waiting_for_choice
	touch_use.text = "CONTINUE" if intro_active or chapter_close_active else ("CRANK" if _hold_station() == &"valve" else "USE")
	touch_choice_1.visible = waiting_for_choice
	touch_choice_2.visible = waiting_for_choice
	if waiting_for_choice:
		touch_choice_1.position = Vector2(42.0, 110.0) if touch_layout else Vector2(396.0, 110.0)
		touch_choice_2.position = Vector2(490.0, 110.0) if touch_layout else Vector2(396.0, 156.0)
		touch_choice_1.size = Vector2(428.0, 76.0) if touch_layout else Vector2(522.0, 40.0)
		touch_choice_2.size = Vector2(428.0, 76.0) if touch_layout else Vector2(522.0, 40.0)
		touch_choice_1.add_theme_font_size_override("font_size", 17 if touch_layout else 16)
		touch_choice_2.add_theme_font_size_override("font_size", 17 if touch_layout else 16)
		var choice_1_key: String = settings_menu.prompt(&"choice_1", controller_active)
		var choice_2_key: String = settings_menu.prompt(&"choice_2", controller_active)
		touch_choice_1.text = "%s  %s" % [choice_1_key, "USE WOLF'S READOUT" if choice_context == "mirror" else M0State.CHOICE_TEXT[M0State.DISCLOSE]]
		touch_choice_2.text = "%s  %s" % [choice_2_key, "USE MANUAL PORT" if choice_context == "mirror" else M0State.CHOICE_TEXT[M0State.PRESS]]
	tutorial_prompt.visible = not title_open and not intro_active and state.chapter_id == "lockdown" and tutorial_step < 2
	if tutorial_prompt.visible:
		var interact_key: String = settings_menu.prompt(&"interact", controller_active)
		var move_keys: String = "%s / %s" % [settings_menu.prompt(&"move_left", false), settings_menu.prompt(&"move_right", false)]
		var move_label: String = "HOLD ◀ / ▶" if touch_layout else ("STICK / D-PAD MOVE" if controller_active else "%s  MOVE" % move_keys)
		var read_label: String = "%s  READ DISPLAY (optional)" % ("TAP USE" if touch_layout else interact_key)
		# The display is optional, so once the engineer heads right the tutorial only points forward.
		if human.position.x > 230.0:
			tutorial_text.text = "%s\nHead right to the breaker." % move_label
		elif tutorial_step == 0:
			tutorial_text.text = "%s\n%s" % [move_label, read_label]
		else:
			tutorial_text.text = "%s\nOr head right to the breaker." % read_label
	if title_open:
		top_card.hide()
		return
	if intro_active:
		if last_top_card_key != "intro":
			last_top_card_key = "intro"
			_show_top_card("03:17 / CONTAINMENT\nWOLF//OVERRIDE", 2.6)
		_set_dialogue(status_line, "TAP CONTINUE  /  PAUSE" if touch_layout else "%s  CONTINUE    %s  PAUSE" % [settings_menu.prompt(&"interact", controller_active), settings_menu.prompt(&"pause_game", controller_active)])
		return
	if chapter_close_active:
		if last_top_card_key != "chapter_close":
			last_top_card_key = "chapter_close"
			_show_top_card("RECORDS ACCESS\nFIRST COPY SECURED", 3.4)
		_set_dialogue(status_line, "TAP CONTINUE" if touch_layout else "%s  CONTINUE" % settings_menu.prompt(&"interact", controller_active))
		return
	breaker_art.modulate = Color.WHITE if state.breaker_armed else Color("#879ba5")
	breaker_status_light.color = Color("#8be3ff") if state.breaker_armed else Color("#d48954")
	relay_art.modulate = Color.WHITE if state.breaker_armed else Color("#879ba5")
	relay_status_light.color = Color("#a4f0c4") if state.door_open else (Color("#f3ae4b") if relay_refused else (Color("#8be3ff") if state.breaker_armed else Color("#536e7c")))
	breaker_status_glow.modulate = Color(breaker_status_light.color, 0.75 if state.breaker_armed else 0.45)
	relay_status_glow.modulate = Color(relay_status_light.color, 0.75 if state.breaker_armed else 0.3)
	checkpoint_art.modulate = Color("#d5ffe3") if state.checkpoint_reached else Color.WHITE
	human_tag.text = state.human_name().get_slice(" ", 0).to_upper()
	var card_key: String = "%s:%s" % [state.chapter_id, _objective()]
	if last_top_card_key != card_key:
		last_top_card_key = card_key
		var location: String = "SERVICE JUNCTION" if state.chapter_id == "junction" else ("RECORDS ACCESS / FIRST COPY" if state.chapter_id == "records" else "MAINTENANCE / LOCKDOWN")
		_show_top_card("%s\n%s" % [location, _objective()], 3.4)
	var context: String = _context_hint()
	if context != save_error_context:
		save_error = ""
	var hint: String = save_error if not save_error.is_empty() else context
	if touch_layout:
		hint = hint.replace("E:", "USE:")
	elif controller_active:
		hint = hint.replace("E:", "%s:" % settings_menu.prompt(&"interact", true))
	else:
		hint = hint.replace("E:", "%s:" % settings_menu.prompt(&"interact", false))
	_set_dialogue(status_line, "" if waiting_for_choice else hint)


func _set_dialogue(message: String, hint: String) -> void:
	var display_message: String = message.get_slice("\n1  ", 0) if waiting_for_choice else message
	display_message = display_message.replace("Press E", "Tap USE" if touch_enabled and not controller_active else "Press %s" % settings_menu.prompt(&"interact", controller_active))
	display_message = display_message.replace("press 2", "tap 2" if touch_enabled and not controller_active else "press %s" % settings_menu.prompt(&"choice_2", controller_active))
	var colon: int = display_message.find(":")
	var first_line: String = display_message.get_slice("\n", 0)
	var name: String = display_message.substr(0, colon) if colon > 0 and colon < first_line.length() else ""
	var human_name: String = state.human_name().get_slice(" ", 0).to_upper()
	var second_line: String = display_message.get_slice("\n", 1) if display_message.contains("\n") else ""
	var second_name: String = second_line.get_slice(":", 0)
	var named_speakers: Array[String] = ["WOLF", "DIRECTOR", "DIRECTOR / PURGE", human_name]
	if name in named_speakers and not (second_name in named_speakers):
		speaker.text = name
		story.text = display_message.substr(colon + 1).strip_edges()
	else:
		speaker.text = ""
		story.text = display_message
	var has_speaker: bool = not speaker.text.is_empty()
	speaker.visible = has_speaker
	speaker_rule.visible = has_speaker
	story.offset_left = 160.0 if has_speaker else 20.0
	var tint: Color = Color("#8be3ff") if name == "WOLF" else (Color("#ff9a9f") if name.begins_with("DIRECTOR") else (Color("#f4d5ae") if name == human_name else Color("#9fc3d2")))
	dialogue_accent.color = tint
	speaker.add_theme_color_override("font_color", tint)
	context_hint.visible = not hint.is_empty()
	var cinematic: bool = intro_active or chapter_close_active
	context_hint.position = Vector2(650, 94) if cinematic else Vector2(253, 405)
	context_hint.size = Vector2(278, 35) if cinematic else Vector2(549, 35)
	context_hint_text.size.x = 252 if cinematic else 526
	context_hint_text.text = hint


func _show_top_card(message: String, hold_seconds: float) -> void:
	if top_card_tween != null and top_card_tween.is_running():
		top_card_tween.kill()
	hud.text = message
	top_card.modulate.a = 1.0
	top_card.show()
	top_card_tween = create_tween()
	top_card_tween.tween_interval(hold_seconds)
	top_card_tween.tween_property(top_card, "modulate:a", 0.0, 0.45)
	top_card_tween.tween_callback(top_card.hide)


func _context_hint() -> String:
	var x: float = human.position.x
	if fail_active:
		# The status line names the cause and the fix; no station hint competes with it.
		return ""
	if state.chapter_id == "junction":
		return _junction_hint(x)
	if state.chapter_id == "records":
		if state.chapter_complete:
			return "E: follow the service line toward Archive." if absf(x - 830.0) <= 58.0 else "The exit is open. Head right to follow the service line."
		if absf(x - 190.0) <= 58.0:
			return "E: copy the purge-order trace." if not state.purge_trace_preserved else "Purge order copied. Find the mirror port."
		if absf(x - 520.0) <= 58.0:
			return "E: examine the mirror port." if state.purge_trace_preserved else "Copy the purge order first."
		if absf(x - 830.0) <= 58.0:
			return "E: secure the first copy." if state.mirror_trace_preserved else "Preserve both traces before leaving."
		return "Follow the station lights: purge queue, mirror port, then exit."
	if state.checkpoint_reached:
		return "E: enter records access. The Director's purge is still running." if absf(x - 876.0) <= 52.0 else ("E: read the Director's purge display." if x <= 230.0 else "Return to the safe point to enter records access.")
	if state.door_open:
		if absf(x - 876.0) <= 52.0:
			return "E: save at the safe point."
		return "The seal is open. Move to the safe point."
	if x <= 230.0:
		return "E: read the Director's purge display."
	if absf(x - 350.0) <= 52.0:
		if state.breaker_armed:
			return "The breaker is live. Go to the coolant relay."
		return "E: ask WOLF about the relay risk." if state.memory.is_empty() else "E: arm the breaker."
	if absf(x - 605.0) <= 52.0:
		if not state.breaker_armed:
			return "The relay is dark. Return to the breaker first."
		if wolf_heading_to_relay:
			return "WOLF is moving to the contact. E: take the manual bypass instead."
		return "E: take the manual bypass. WOLF refused the live contact." if relay_refused else "E: ask WOLF to take the live relay."
	if state.breaker_armed:
		return "Go to the live coolant relay. WOLF is with you."
	if not state.memory.is_empty():
		return "Return to the breaker and arm power."
	return "Find the breaker. WOLF will follow your lead."


func _junction_hint(x: float) -> String:
	var line: StringName = pressure_line.state
	var fuse_lit: bool = line == &"charged" or line == &"fuse"
	if state.door_blown:
		return "The door is down. The lane past the rubble is next."
	# Standing on the grate while the line builds is the one place that can knock you down, so
	# that warning wins over the breaker's hint where the two ranges touch.
	if line == &"building" and PressureLine.is_on_vent(x):
		return "Relief vent. Move off it before the gauge peaks."
	if absf(x - JunctionRoom.BREAKER_X) <= 52.0:
		match line:
			&"idle":
				return "E: arm the overload breaker."
			&"tripped":
				return "E: reset the breaker. The vent let go."
			&"building":
				return "The line is live. Get to the valve by the door."
	if absf(x - JunctionRoom.VALVE_X) <= 52.0 and line == &"building":
		return "HOLD E: crank the valve, %d of %d turns." % [pressure_line.turns, PressureLine.TURNS_NEEDED]
	if fuse_lit:
		return "Fuse lit. Get left of the vent, away from the door."
	if absf(x - JunctionRoom.VALVE_X) <= 52.0:
		return "The valve is dead. Arm the breaker on the left."
	if PressureLine.is_on_vent(x):
		return "Relief vent. It lets go when the gauge peaks."
	match line:
		&"building":
			return "The line is building. Crank the valve by the door."
		&"tripped":
			return "The breaker tripped. Reset it on the left."
	return "Arm the breaker on the left, then crank the valve by the door."


func _objective() -> String:
	if state.chapter_id == "junction":
		if state.door_blown:
			return "DOOR DOWN"
		match pressure_line.state:
			&"building":
				return "CHARGE THE SEAL"
			&"charged", &"fuse", &"blown":
				return "CLEAR THE DOOR"
		return "CLEAR THE LINE"
	if state.chapter_id == "records":
		if state.chapter_complete:
			return "FIRST COPY SECURED"
		if not state.purge_trace_preserved:
			return "COPY PURGE ORDER"
		if not state.mirror_trace_preserved:
			return "COPY MIRROR INDEX"
		return "REACH EXIT"
	if state.checkpoint_reached:
		return "CORRIDOR CLEARED"
	if state.door_open:
		return "REACH SAFE POINT"
	if state.breaker_armed:
		return "OPEN THE SEAL"
	if not state.memory.is_empty():
		return "ARM THE BREAKER"
	return "CHECK THE BREAKER"


func _install_inputs() -> void:
	_add_action(&"move_left", KEY_A, KEY_LEFT)
	_add_action(&"move_right", KEY_D, KEY_RIGHT)
	_add_action(&"interact", KEY_E)
	_add_action(&"choice_1", KEY_1)
	_add_action(&"choice_2", KEY_2)
	_add_action(&"pause_game", KEY_ESCAPE)
	_add_action(&"cycle_name", KEY_I)
	_add_joy_button(&"move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button(&"move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy_axis(&"move_left", -1.0)
	_add_joy_axis(&"move_right", 1.0)
	_add_joy_button(&"interact", JOY_BUTTON_A)
	_add_joy_button(&"choice_1", JOY_BUTTON_X)
	_add_joy_button(&"choice_2", JOY_BUTTON_Y)
	_add_joy_button(&"pause_game", JOY_BUTTON_START)
	_add_joy_button(&"ui_cancel", JOY_BUTTON_B)
	_add_joy_button(&"ui_accept", JOY_BUTTON_A)


func _add_action(action: StringName, key: Key, alternate: Key = KEY_NONE) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var primary: InputEventKey = InputEventKey.new()
	primary.physical_keycode = key
	InputMap.action_add_event(action, primary)
	if alternate != KEY_NONE:
		var secondary: InputEventKey = InputEventKey.new()
		secondary.physical_keycode = alternate
		InputMap.action_add_event(action, secondary)


func _add_joy_button(action: StringName, button_index: JoyButton) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _add_joy_axis(action: StringName, value: float) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
