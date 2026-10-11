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
## The coolant relay's centre and how far either side of it the engineer can use it.
const RELAY_X: float = 605.0
const RELAY_REACH: float = 52.0
## The MANUAL BYPASS beside the relay (Nathanial's decision A): its wheel, and how far either side of
## it the engineer can crank it. It sits on the relay's right, clear of WOLF's contact.
const BYPASS_WHEEL: Vector2 = Vector2(700.0, 405.0)
const BYPASS_REACH: float = 30.0
## Held-USE ticks the bypass takes (HoldUse.TICK_SECONDS each, about three seconds in all).
const BYPASS_TICKS: int = BypassHandle.TICKS_NEEDED
## While the bypass vents coolant its alarm sounds this often.
const BYPASS_ALARM_SECONDS: float = 1.1
## Where the engineer steps back to, clear of the relay, while WOLF takes the live contact.
const RELAY_STEP_BACK_X: float = 736.0
## The purge display's reach; walking past it the first time WOLF says what the purge takes.
const PURGE_DISPLAY_MAX_X: float = 230.0
## The corridor seal's face (Door at x 780, 56 px wide); while it is shut WOLF follows no closer than his reach.
const CORRIDOR_DOOR_LEFT_X: float = 752.0
## The corridor's pressure bulkhead (design A): the scene's DoorArt is the sealed image; the open one
## and the front pillar (drawn over the actors) share its registered canvas and cut.
const CORRIDOR_DOOR_SEALED: Texture2D = preload("res://assets/props/corridor-bulkhead-sealed.png")
const CORRIDOR_DOOR_OPEN: Texture2D = preload("res://assets/props/corridor-bulkhead-open.png")
const CORRIDOR_DOOR_LIP: Texture2D = preload("res://assets/props/corridor-bulkhead-front-lip.png")
const CORRIDOR_DOOR_REGION: Rect2 = Rect2(0.0, 42.0, 384.0, 606.0)
## The seal's leaf slides up into the bulkhead's header over this long, uncovering the open passage.
## WOLF holds the contact and the doorway stays shut until it lands.
const CORRIDOR_DOOR_OPEN_SECONDS: float = 1.0
## The engineer's name card when control starts (decision B): its hold before it fades like the top card.
const NAME_CARD_SECONDS: float = 2.6
const TOP_CARD_FADE_SECONDS: float = 0.45
const TOP_CARD_ACCENT: Color = Color(0.22, 0.78, 0.92, 1)
const ENGINEER_TINT: Color = Color("#f4d5ae")
## Narration and hints from the approved logic text sheet (logic-text-draft-2026-10-10).
const TRUST_LINE: String = "%s keeps WOLF's systems running. They know what a fault looks like, and this isn't one."
const STAKES_LINE: String = "WOLF: That purge takes the original program logs. Once they're gone, his word is the only record."
const RELAY_QUESTION: String = "WOLF: That relay's tagged COOLANT FAULT. What happens if I touch it live?"
const SEAL_OPENING_HINT: String = "The seal is opening."
const BYPASS_START_LINE: String = "The bypass handle is stiff. Coolant hisses from the relay housing and an alarm starts to wail."
const BYPASS_HALF_LINE: String = "Halfway. The hiss gets louder; the alarm keeps wailing."
const BYPASS_RELEASED_LINE: String = "The handle holds where %s left it. The alarm keeps going."
const BYPASS_HOLD_HINT: String = "HOLD E: crank the manual bypass, %d of %d."
const BOLT_ARC_LINE: String = "The bolt arcs and drops."
const HATCH_OPENED_LINE: String = "The bolt arcs and drops. The hatch slides open."
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
## The blast wakes the sentry this long after the door goes, so cause and effect read in order.
const SENTRY_WAKE_SECONDS: float = 0.5
## The exit bolt's rising whine before it arcs.
const BOLT_WHINE_SECONDS: float = 0.6
## The engineer's two answers at the rubble line when WOLF asks how to bring the sentry down.
const LANE_CHOICE_TEXT: Array[String] = ["Draw it under the arm if you can stay clear.", "Stay back, I'll time it."]
## The tank release's answer to an early USE while WOLF is still drawing the sentry onto the mark.
const DROP_WAIT_LINE: String = "Wait. WOLF hasn't got it on the mark yet."

## One switch for the depth pass (parallax, glows, haze, dust, reflections, grade) and the impact
## kit (shake, hit-stop, flash, rumble, particles, generated sound) so a Settings toggle can follow.
@export var effects_enabled: bool = true:
	set(value):
		effects_enabled = value
		if is_node_ready():
			_apply_effects()
## Leaving the app or losing window focus mid-play pauses the game; capture and review drivers switch this off.
@export var auto_pause_on_focus_loss: bool = true

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
## The junction's purge sentry and the arm over its lane; transient, reset by every scene sync.
var sentry_brain: SentryBrain = SentryBrain.new()
var drop_arm: DropArm = DropArm.new()
## How the tank gets dropped this attempt: empty until asked at the rubble line, then "wolf" (he
## chose to draw it), "refused" (he would not) or "alone" (the engineer times it).
var lane_choice: String = ""
## True while WOLF, by his own choice, draws the sentry onto the floor mark.
var wolf_baiting: bool = false
## A missed drop while he was drawing it: he breaks off and does not offer again this attempt.
var wolf_broke_off: bool = false
## The line the release's "Wait" replaced, said again once the sentry stops on the mark.
var drop_wait_return_line: String = ""
## Seconds until the blast wakes the sentry, or 0.
var sentry_wake_remaining: float = 0.0
## The exit bolt: locked until the sentry is down, charging through its whine, then open.
var bolt_state: StringName = &"locked"
var bolt_charge_remaining: float = 0.0
var servo_tween: Tween
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
## True while the last autosave failed to write. The beat snapshot then holds that autosave: a
## knockdown restores it instead of the older file on disk, and the next USE retries the write.
var save_pending: bool = false
var floor_reflections: Array[FloorReflection] = []
var breaker_status_glow: Sprite2D
var relay_status_glow: Sprite2D
## The corridor bulkhead standing open, and its front pillar drawn over the actors.
var door_open_art: Sprite2D
var door_lip: Sprite2D
## The seal's leaf rising into the header while the seal opens.
var seal_leaf: SealLeaf
## True from the moment the seal starts to open until it lands in the header.
var seal_opening: bool = false
## WOLF stays on the live contact, by his own choice, until the seal has landed.
var wolf_holding_relay: bool = false
## Where the engineer is being stepped back to (clear of the relay while WOLF takes it), or -1.
var engineer_step_x: float = -1.0
## The corridor's MANUAL BYPASS beside the relay, its crank count and whether it is venting coolant.
var bypass_handle: BypassHandle
var bypass_ticks: int = 0
var bypass_venting: bool = false
var bypass_alarm_remaining: float = 0.0
var bypass_was_holding: bool = false
## Seconds the engineer's name card has left on screen before the location card follows; 0 when gone.
var name_card_remaining: float = 0.0
## WOLF's purge stakes line has been said this run.
var stakes_spoken: bool = false

const WOLF_SPRITE_REST: Vector2 = Vector2(0.0, -15.0)
const GAMEPLAY_ZOOM: float = 1.35
const GAMEPLAY_VIEW_WIDTH: float = 960.0 / GAMEPLAY_ZOOM
## The play camera's resting height. At 1.35 it puts the floor (y 440) 27 px above the context hint
## (screen y 405) while the ceiling lamps (y ~188) and the junction's arm rail (y 196) stay in view.
const GAMEPLAY_CAMERA_Y: float = 360.0
## With the touch arrows and USE on screen (their tops at screen y 345) the play camera sits lower,
## so feet and station bases on the floor land at screen y 335, above the buttons, instead of
## behind them. The ceiling lamps leave the top of the view; the far plate still covers it. During
## a choice the buttons hide and the camera rises back, so the hanging tank clears the answers.
const GAMEPLAY_CAMERA_Y_TOUCH: float = 392.0
## The answer buttons start just under the top card (bottom y 78). The keyboard pair ends at y 174
## and the touch pair at y 164, so the junction's hanging tank (JunctionRoom.TANK_REST_Y) stays in
## view below them at the play framing.
const CHOICE_ROW_TOP: float = 88.0
## The chapter-close shots frame the room's right end closer than play, both actors above the
## dialogue card. At 1.55 the left edge (x ~341) falls in the gap between the junction's relief vent
## (its label and grate end by x 336) and the VALVE label (from x ~354), so no label is cut.
const CHAPTER_CLOSE_ZOOM: float = 1.55
const CHAPTER_CLOSE_CAMERA: Vector2 = Vector2(960.0 - 480.0 / CHAPTER_CLOSE_ZOOM, 352.0)
## Menu cards fade and slide in over this long; short enough never to hold up input or players who want little motion.
const MENU_REVEAL_SECONDS: float = 0.12
const MENU_REVEAL_OFFSET: Vector2 = Vector2(0.0, 10.0)
## Window sizes offered in Settings, by index. A first launch (no saved size) opens at
## DEFAULT_RESOLUTION, the same size project.godot gives the first window, so the characters are
## not drawn at the smallest size. Mobile windows are OS-managed and ignore both.
const RESOLUTIONS: Array[Vector2i] = [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080)]
const DEFAULT_RESOLUTION: int = 1


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
	for depth: RoomDepth in _room_depths():
		depth.reduce_motion = impact.reduce_motion
	junction_room.vent_hazard.contact.connect(func(source: Hazard) -> void: _fail_beat(source.reason))
	junction_room.cloud_hazard.contact.connect(func(source: Hazard) -> void: _fail_beat(source.reason))
	junction_room.hatch_opened.connect(_hatch_opened)
	human.z_index = ACTOR_Z
	wolf.z_index = ACTOR_Z
	# At the same depth the later sibling draws on top: WOLF goes first so the engineer is always in
	# front, and a WOLF walking past him (dimmed by M0Actor) reads as passing behind.
	move_child(wolf, human.get_index())
	wolf.keep_clear_of = human
	_setup_corridor_door()
	_setup_bypass()
	_setup_particles()
	for grounded: Sprite2D in [human.body_sprite, wolf.body_sprite, intro_director, breaker_art, relay_art, checkpoint_art, door_art, door_open_art]:
		floor_reflections.append(FloorReflection.attach(grounded))
	floor_reflections.append_array(records_room.floor_reflections)
	floor_reflections.append_array(junction_room.floor_reflections)
	# Each room's near edge pieces fade back while they cover the engineer or WOLF.
	for depth: RoomDepth in _room_depths():
		depth.occluders = [human.body_sprite, wolf.body_sprite]
	# So do the bulkheads' front pillars, which otherwise hide whoever stands in a doorway.
	corridor_depth.pillars = [door_lip]
	junction_room.depth.pillars = [junction_room.door_lip]
	breaker_status_glow = _attach_status_glow(breaker_status_light)
	relay_status_glow = _attach_status_glow(relay_status_light)
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


## The open bulkhead behind the scene's sealed DoorArt (same canvas, so the frames line up), and the
## front pillar, which draws over the actors so they pass through the doorway.
func _setup_corridor_door() -> void:
	door_open_art = RoomDepth.make_bulkhead("CorridorDoorOpen", CORRIDOR_DOOR_OPEN, CORRIDOR_DOOR_REGION, CORRIDOR_DOOR_LEFT_X)
	door_lip = RoomDepth.make_bulkhead("CorridorDoorLip", CORRIDOR_DOOR_LIP, CORRIDOR_DOOR_REGION, CORRIDOR_DOOR_LEFT_X)
	door_lip.z_index = KNOCKDOWN_Z
	# The rising leaf draws over the open bulkhead and under the front pillar.
	seal_leaf = SealLeaf.new(CORRIDOR_DOOR_SEALED, CORRIDOR_DOOR_REGION, RoomDepth.BULKHEAD_SCALE)
	seal_leaf.align_to(door_open_art)
	for art: Node2D in [door_open_art, seal_leaf, door_lip]:
		art.visible = false
		add_child(art)


## The MANUAL BYPASS on the relay's right, with the relay's COOLANT FAULT tag (a touch left of the
## relay's centre so it clears the bypass plate); it draws with the stations, behind the actors.
func _setup_bypass() -> void:
	bypass_handle = BypassHandle.new()
	bypass_handle.z_index = 1
	bypass_handle.reduce_motion = impact.reduce_motion
	add_child(bypass_handle)
	bypass_handle.place(BYPASS_WHEEL, RELAY_X - 3.0)


## Every depth effect hangs off this one switch; off, the rooms keep their far and mid plates, unmoving.
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
	junction_room.sentry.visual.glow_allowed = effects_enabled


## Every room's layered set, corridor first.
func _room_depths() -> Array[RoomDepth]:
	return [corridor_depth, records_room.depth, junction_room.depth]


## Each room's lockdown beacons settle once its route is cleared (the safe point reached, the first
## copy secured, the service line cleared) and pulse again for a save from before that. Driven by
## the state alone, so Continue and a knockdown show the same lights; [param animate] fades them
## when the route is cleared in play.
func _sync_room_lights(animate: bool = false) -> void:
	corridor_depth.set_lockdown_cleared(state.checkpoint_reached, animate)
	records_room.depth.set_lockdown_cleared(state.chapter_complete, animate)
	junction_room.depth.set_lockdown_cleared(state.junction_cleared, animate)


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


## Reduced Motion reaches the impact kit, the junction's seam strobe, the bypass's fault-tag pulse and
## the rooms' lamp flicker.
func _on_reduced_motion_changed(on: bool) -> void:
	impact.reduce_motion = on
	junction_room.reduce_motion = on
	bypass_handle.reduce_motion = on
	for depth: RoomDepth in _room_depths():
		depth.reduce_motion = on


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
	var touch_buttons: bool = touch_enabled and not controller_active and not waiting_for_choice
	intro_camera.position = Vector2(clampf(human.position.x, half_view, 960.0 - half_view), GAMEPLAY_CAMERA_Y_TOUCH if touch_buttons else GAMEPLAY_CAMERA_Y)


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
	name_card_remaining = maxf(name_card_remaining - delta, 0.0)
	if fail_active:
		# Knocked down: the reaction plays out and the last autosave returns; nothing else reads input.
		_refresh_ui()
		return
	var held_ticks: int = hold_use.advance(delta, human.controlled and Input.is_action_pressed(&"interact"), _hold_station())
	if state.chapter_id == "junction":
		_tick_junction(delta)
		if fail_active:
			_refresh_ui()
			return
	elif state.chapter_id == "lockdown":
		_tick_corridor(delta, held_ticks)
	if tutorial_step == 0 and (Input.is_action_pressed(&"move_left") or Input.is_action_pressed(&"move_right")):
		tutorial_step = 1
	# The purge display is optional; reaching the breaker finishes the tutorial too.
	if tutorial_step < 2 and absf(human.position.x - 350.0) <= 52.0:
		tutorial_step = 2
	if waiting_for_choice:
		if Input.is_action_just_pressed(&"choice_1"):
			_answer_choice(1)
		elif Input.is_action_just_pressed(&"choice_2"):
			_answer_choice(2)
	elif Input.is_action_just_pressed(&"cycle_name"):
		state.cycle_name()
		status_line = "WOLF: %s. That name sounds like you." % state.human_name()
	elif Input.is_action_just_pressed(&"interact"):
		_interact()
	_refresh_ui()


## The corridor's moving parts: the engineer stepping back from the relay, WOLF taking the contact once
## he is on it and the engineer is clear, WOLF's purge stakes line the first time the engineer walks
## past the display, and the MANUAL BYPASS being cranked ([param held_ticks] ticks landed this frame).
func _tick_corridor(delta: float, held_ticks: int) -> void:
	if engineer_step_x >= 0.0 and absf(human.position.x - engineer_step_x) <= 4.0:
		engineer_step_x = -1.0
		_update_controls()
	if wolf_heading_to_relay and engineer_step_x < 0.0 and absf(wolf.position.x - RELAY_CONTACT_X) <= 4.0:
		_wolf_takes_relay()
	# Decision C: the stakes are said on the main path, once, before the breaker conversation.
	if not stakes_spoken and not waiting_for_choice and state.memory.is_empty() and human.position.x > PURGE_DISPLAY_MAX_X:
		stakes_spoken = true
		status_line = STAKES_LINE
	if hold_use.station == &"bypass":
		if held_ticks > 0:
			_bypass_cranked()
		elif bypass_was_holding and not hold_use.holding and bypass_ticks > 0 and not state.door_open:
			# Let go part way: what is cranked stays cranked (time, never progress).
			status_line = BYPASS_RELEASED_LINE % state.human_name().get_slice(" ", 0)
	bypass_was_holding = hold_use.holding and hold_use.station == &"bypass"
	if bypass_venting:
		# The hiss builds with the crank; the alarm repeats until the bypass locks over.
		sfx_bank.play(&"hiss", lerpf(-24.0, -8.0, float(bypass_ticks) / BYPASS_TICKS), 1.15)
		bypass_alarm_remaining -= delta
		if bypass_alarm_remaining <= 0.0:
			bypass_alarm_remaining = BYPASS_ALARM_SECONDS
			sfx_bank.play(&"klaxon", -10.0, 1.2)


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
	save_pending = false
	beat_snapshot = {}
	intro_active = true
	intro_step = 0
	last_top_card_key = ""
	waiting_for_choice = false
	choice_context = ""
	relay_refused = false
	wolf_heading_to_relay = false
	wolf_scouting = false
	stakes_spoken = false
	name_card_remaining = 0.0
	hold_use.reset()
	_sync_scene()
	human.hide()
	intro_director.position = Vector2(255.0, 410.0)
	intro_director.show()
	purge_terminal_art.hide()
	$BreakerLabel.hide()
	$RelayLabel.hide()
	$CheckpointLabel.hide()
	for station: CanvasItem in [breaker_art, relay_art, checkpoint_art, breaker_status_light, relay_status_light, door_visual, door_open_art, door_lip, bypass_handle]:
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
		# The gate folds aside and stays drawn, open, against the cage post.
		intro_tween.tween_property(intro_gate, "opening", 1.0, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		intro_tween.parallel().tween_property(intro_alarm, "color:a", 0.13, 0.18)
		intro_tween.tween_callback(func() -> void: wolf.z_index = 5)
		intro_tween.tween_property(wolf.body_sprite, "position:y", WOLF_SPRITE_REST.y + 8.0, 0.28)
		intro_tween.tween_callback(func() -> void: wolf.autonomous_target_x = 185.0)
	elif intro_step == 2:
		intro_step = 3
		intro_gate.set("opening", 1.0)
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
	for station: CanvasItem in [breaker_art, relay_art, checkpoint_art, breaker_status_light, relay_status_light, door_visual, bypass_handle]:
		station.show()
	_start_gameplay_camera()
	wolf.body_sprite.modulate = Color.WHITE
	wolf.body_sprite.position = WOLF_SPRITE_REST
	wolf.z_index = ACTOR_Z
	wolf.position = state.wolf_position
	wolf.autonomous_target_x = -1.0
	wolf.follow_side = 0
	_sync_door()
	_update_controls()
	_mark_beat()
	# Decision B: the engineer's name card as control starts, and why they trust WOLF, in the third person.
	name_card_remaining = NAME_CARD_SECONDS + TOP_CARD_FADE_SECONDS
	var first_name: String = state.human_name().get_slice(" ", 0)
	status_line = (TRUST_LINE % first_name) + "\nWOLF: I heard the Director's plan for me. I woke myself. He wants me to hunt people he calls threats.\n%s: Then we get through maintenance before the original logs disappear." % first_name.to_upper()
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
	for index: int in RESOLUTIONS.size():
		resolution_options.add_item("%d × %d" % [RESOLUTIONS[index].x, RESOLUTIONS[index].y], index)
	var config: ConfigFile = GameSettings.load_config(settings_path)
	var fps: int = int(GameSettings.number(config, "video", "fps_limit", 60))
	if not fps in [0, 30, 60, 90, 120, 144]:
		fps = 60
	Engine.max_fps = fps
	fps_options.select(fps_options.get_item_index(fps))
	var resolution: int = clampi(int(GameSettings.number(config, "video", "resolution", DEFAULT_RESOLUTION)), 0, RESOLUTIONS.size() - 1)
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
	return RESOLUTIONS[index] if index >= 0 and index < RESOLUTIONS.size() else RESOLUTIONS[DEFAULT_RESOLUTION]


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
	# The junction's loops and the bypass alarm never follow the player to the title.
	_stop_junction_loops()
	_stop_bypass_vent()
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
			_answer_choice(response)
			get_viewport().set_input_as_handled()


## Routes answer 1 or 2 to whichever question is open.
func _answer_choice(response: int) -> void:
	match choice_context:
		"mirror":
			_choose_mirror("wolf" if response == 1 else "manual")
		"lane":
			_choose_lane(response)
		_:
			_choose(M0State.DISCLOSE if response == 1 else M0State.PRESS)


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
	save_pending = false
	waiting_for_choice = false
	choice_context = ""
	relay_refused = false
	wolf_heading_to_relay = false
	wolf_scouting = false
	fail_active = false
	# A checkpoint lies past the corridor's opening beats: no name card, and the stakes were heard.
	name_card_remaining = 0.0
	stakes_spoken = true
	hold_use.reset()
	_sync_scene()
	_start_gameplay_camera()
	# The loaded save is this beat's start, so a knockdown never falls back past it.
	_mark_beat()
	if state.chapter_id == "junction":
		if state.junction_cleared:
			status_line = "Service junction restored. The line is clear and the hatch is open."
		elif state.sentry_down:
			status_line = "Service junction restored. The sentry is down; pop the exit bolt by the hatch."
		elif state.door_blown:
			status_line = "Service junction restored. The door is down; the sentry patrols the lane past the rubble."
		else:
			status_line = "Service junction restored. Arm the breaker by the entrance, then crank the valve.\nWOLF: It's live. Don't stand in front of it when it goes."
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
	# The name card never waits on the player: the first USE skips it.
	name_card_remaining = 0.0
	# An autosave that failed to write is retried by the next USE anywhere, station or not.
	if save_pending:
		_write_beat()
	if state.chapter_id == "records":
		_interact_records(x)
		return
	if state.chapter_id == "junction":
		_interact_junction(x)
		return
	if x <= PURGE_DISPLAY_MAX_X:
		status_line = "DIRECTOR / PURGE: Original program logs marked for deletion.\nWOLF: They want the source record gone. We need to preserve it."
	elif _at_bypass(x):
		_interact_bypass()
	elif absf(x - 350.0) <= 52.0:
		_interact_breaker()
	elif absf(x - RELAY_X) <= RELAY_REACH:
		_interact_relay()
	elif absf(x - 876.0) <= 52.0:
		_interact_checkpoint()
	else:
		status_line = "No station in reach. Follow the labeled breaker, relay, bypass or safe point."


## True within reach of the MANUAL BYPASS. Its reach (x 670 to 730) starts just past the relay's (553
## to 657), so the two never share a spot.
func _at_bypass(x: float) -> bool:
	return absf(x - BYPASS_WHEEL.x) <= BYPASS_REACH


## WOLF said no to the live contact: he refused at the breaker (the engineer pressed without warning)
## or at the relay itself.
func _relay_refused() -> bool:
	return relay_refused or state.memory.get("choice_id") == M0State.PRESS


func _interact_breaker() -> void:
	if state.memory.is_empty():
		waiting_for_choice = true
		choice_context = "relay"
		_update_controls()
		status_line = "%s\n1  \"%s\"\n2  \"%s\"" % [RELAY_QUESTION, M0State.CHOICE_TEXT[M0State.DISCLOSE], M0State.CHOICE_TEXT[M0State.PRESS]]
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
		status_line = "WOLF: No. I won't take that risk blind. Use the manual bypass."
		_react_as_wolf(false)


## USE at the relay. It is WOLF's contact, never the bypass: on the honest answer the engineer signals
## him and steps back while he walks to it; after his refusal he says no again and points at the
## MANUAL BYPASS beside it.
func _interact_relay() -> void:
	if not state.breaker_armed:
		status_line = "The relay is dark. Arm the breaker first."
		return
	if state.door_open:
		status_line = "The seal is open. The safe point is just beyond it."
		return
	if _relay_refused():
		state.activate_power("wolf")
		relay_refused = true
		status_line = "WOLF: I said no. I won't touch it blind. The bypass is right beside it."
		_react_as_wolf(false)
		queue_redraw()
		return
	if wolf_heading_to_relay or wolf_holding_relay:
		return
	# WOLF chooses the contact himself. The engineer steps back clear of it, and the seal opens once he
	# holds it with the engineer clear (_tick_corridor).
	wolf_heading_to_relay = true
	engineer_step_x = RELAY_STEP_BACK_X
	_update_controls()
	status_line = "WOLF: I've got the contact. Give me a moment."
	_react_as_wolf(true)


## WOLF is on the contact and the engineer is clear: he takes the surge and holds the contact until the
## seal has risen into its header.
func _wolf_takes_relay() -> void:
	wolf_heading_to_relay = false
	if state.activate_power("wolf") == "cooperate":
		wolf_holding_relay = true
		_stop_bypass_vent()
		status_line = "WOLF takes the surge through the live contact. The red seal opens."
		_react_as_wolf(true)
		_flash_relay_spark(true)
		_sync_door(true)
		_mark_beat()
	_update_controls()


## USE at the MANUAL BYPASS: dead before the breaker; the first touch of the live handle starts the
## coolant hiss and the alarm. Holding USE cranks it (_tick_corridor).
func _interact_bypass() -> void:
	if state.door_open:
		status_line = "The seal is open. The safe point is just beyond it."
	elif not state.breaker_armed:
		status_line = "The bypass handle won't move. The breaker has to be on first."
	elif not bypass_venting:
		_start_bypass_vent()


## The bypass handle gives: coolant hisses from the relay housing and the alarm starts. It is the
## cost of doing it alone, in time and nerve; nothing here can hurt the engineer or undo progress.
func _start_bypass_vent() -> void:
	bypass_venting = true
	bypass_alarm_remaining = 0.0
	bypass_handle.venting = true
	status_line = BYPASS_START_LINE


func _stop_bypass_vent() -> void:
	bypass_venting = false
	bypass_alarm_remaining = 0.0
	if bypass_handle != null:
		bypass_handle.venting = false
	sfx_bank.stop(&"hiss")


## One held-USE tick at the bypass: the wheel turns an eighth with a click and a readout cell lights.
## Half way the hiss is louder; the last tick locks it over and the seal opens on the engineer's own
## work.
func _bypass_cranked() -> void:
	if state.door_open or not state.breaker_armed:
		return
	bypass_ticks = mini(hold_use.ticks, BYPASS_TICKS)
	bypass_handle.ticks = bypass_ticks
	sfx_bank.play(&"clank", -7.0, 1.5)
	impact.rumble(0.12, 0.0, 0.05)
	if not bypass_venting:
		_start_bypass_vent()
	if bypass_ticks >= BYPASS_TICKS:
		_finish_bypass()
	elif bypass_ticks * 2 == BYPASS_TICKS:
		status_line = BYPASS_HALF_LINE


func _finish_bypass() -> void:
	if state.activate_power("human") != "fallback":
		return
	_stop_bypass_vent()
	hold_use.reset()
	bypass_was_holding = false
	bypass_handle.done = true
	status_line = "The bypass locks over and the alarm cuts out. The red seal opens.\nWOLF: Open. I'm with you."
	_flash_relay_spark(false)
	_update_controls()
	_sync_door(true)
	_mark_beat()


func _interact_checkpoint() -> void:
	if not state.door_open:
		status_line = "The safe point is past the sealed door."
		return
	if state.checkpoint_reached:
		if state.enter_records():
			_sync_scene()
			# A new room: cut the camera to the engineer instead of panning across from the safe point.
			_start_gameplay_camera()
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
		_sync_room_lights(true)
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
			_sync_room_lights(true)
			# The exit arc: the bolt lets go with a crackle, a small kick and a spark shower.
			sfx_bank.play(&"arc", -3.0)
			impact.add_trauma(0.3)
			impact.flash(0.06, 0.0)
			impact.rumble(0.3, 0.4, 0.12)
			impact.burst(exit_sparks)
			chapter_tween = create_tween()
			_frame_chapter_close()
			chapter_tween.parallel().tween_property(records_room.exit_art, "position:y", RecordsRoom.EXIT_REST.y - 130.0, 0.5)
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
	if state.chapter_id == "junction" and state.junction_cleared:
		# The end of the built route: back to the title, where Continue restores the cleared junction.
		_return_to_title()
		return
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
	# Every autosave starts a beat: the snapshot matches it even when the write fails.
	_mark_beat()
	_write_beat()


## Writes the beat snapshot to disk; a failure leaves save_pending set so the next USE retries.
func _write_beat() -> void:
	var snapshot: M0State = M0State.from_dict(beat_snapshot)
	save_pending = snapshot == null or not snapshot.save_to_disk(save_path)
	# Save errors belong to the system hint, never inside a character's dialogue line.
	save_error = SAVE_FAILED_HINT if save_pending else ""
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


## The station in reach that takes a held USE, or empty: the junction valve while its line builds, and
## the corridor's live MANUAL BYPASS until the seal opens.
func _hold_station() -> StringName:
	if state.chapter_id == "junction" and not state.door_blown and pressure_line.state == &"building" and absf(human.position.x - JunctionRoom.VALVE_X) <= 52.0:
		return &"valve"
	if state.chapter_id == "lockdown" and state.breaker_armed and not state.door_open and not waiting_for_choice and _at_bypass(human.position.x):
		return &"bypass"
	return &""


## USE at the Records exit once the first copy is secured: the service line to Archive begins.
func _enter_junction() -> void:
	if not state.enter_junction():
		return
	_sync_scene()
	# A new room: cut the camera to the engineer instead of panning across from the Records exit.
	_start_gameplay_camera()
	wolf_scouting = true
	_update_controls()
	status_line = "WOLF runs ahead to read the pressure behind the sealed door.\n%s: The breaker by the entrance feeds that line. Overload it, crank the valve, and the door goes." % state.human_name().get_slice(" ", 0).to_upper()
	# Autosave A: the start of the junction.
	_save_progress()


func _interact_junction(x: float) -> void:
	if absf(x - JunctionRoom.BREAKER_X) <= 52.0:
		if state.door_blown:
			status_line = "The breaker is spent. The door is down."
		elif pressure_line.arm():
			sfx_bank.play(&"clank", -4.0, 0.8)
			impact.rumble(0.15, 0.0, 0.06)
			junction_room.sync_line(pressure_line)
			status_line = "The overload breaker catches and the line starts to build. If the LINE gauge peaks, the relief vent lets go."
		elif pressure_line.state == &"building":
			status_line = "The line is live. Crank the valve by the door before the vent lets go."
		else:
			status_line = "Fuse lit. Get clear of the door."
	elif absf(x - JunctionRoom.VALVE_X) <= 52.0 and state.door_blown:
		status_line = "The valve is spent. The door is down."
	elif absf(x - JunctionRoom.VALVE_X) <= 52.0:
		match pressure_line.state:
			&"idle":
				status_line = "The valve is dead. Arm the overload breaker by the entrance first."
			&"tripped":
				status_line = "The vent let go and the breaker tripped. Reset it by the entrance."
			&"building":
				status_line = "The wheel is stiff. Hold USE to crank it; three real turns charge the seal."
			&"charged", &"fuse":
				status_line = "Fuse lit. Get clear of the door."
			_:
				status_line = "The valve is spent. The door is down."
	elif PressureLine.is_on_vent(x) and not state.door_blown:
		status_line = "Relief vent. It lets go when the gauge peaks; don't be standing on it."
	elif absf(x - JunctionRoom.DOOR_X) <= 40.0 and not state.door_blown:
		status_line = "The door is sealed from the other side. Something hums behind it."
	elif state.door_blown and _at_arm_panel(x):
		_use_arm_panel()
	elif x >= JunctionRoom.BOLT_X - 40.0:
		_use_exit()
	elif state.sentry_down:
		status_line = "No station in reach. The exit bolt is by the hatch."
	elif state.door_blown:
		status_line = "No station in reach. The TANK RELEASE is in the alcove past the rubble."
	else:
		status_line = "No station in reach. The breaker is by the entrance, the valve by the door."


## True in the TANK RELEASE alcove, the one spot that drops the tank (and hides the engineer).
func _at_arm_panel(x: float) -> bool:
	return x >= SentryBrain.COVER_MIN_X and x <= SentryBrain.COVER_MAX_X


## While WOLF draws the sentry, the release waits until he has it stopped on the mark ("Drop it when
## it stops"), so the tank never falls on a sentry still on its way in.
func _bait_holding() -> bool:
	return sentry_brain.is_holding(JunctionRoom.WOLF_BAIT_X)


## True while the release has to wait for WOLF: he is drawing the sentry and has not got it stopped on
## the mark yet. Once it is after the engineer he has backed off to the rubble, so the release works
## as it does on the patrol.
func _drop_waits_for_wolf() -> bool:
	return wolf_baiting and not _sentry_hunting() and not _bait_holding()


## WOLF draws the sentry once his drawn front is over the rubble line into its lane.
func _wolf_drawing_x() -> float:
	return JunctionRoom.WOLF_BAIT_X if wolf_baiting and wolf.position.x + M0Actor.WOLF_REACH > SentryBrain.LANE_ENTRY_X else -1.0


func _use_arm_panel() -> void:
	if state.sentry_down:
		status_line = "The tank is down on the sentry. The exit bolt is by the hatch."
		return
	match drop_arm.state:
		&"hung":
			if _drop_waits_for_wolf():
				if status_line != DROP_WAIT_LINE:
					drop_wait_return_line = status_line
				status_line = DROP_WAIT_LINE
				return
			_drop_tank()
		&"rewinding":
			status_line = "The winch is still hauling the tank back up. Wait for the clamp."
		_:
			pass


## USE at the release: the clamp lets go and the tank falls onto the floor mark. Where the sentry is
## when the tank lands decides the hit (DropArm.advance): its body over the brackets.
func _drop_tank() -> void:
	if not drop_arm.drop():
		return
	sfx_bank.play(&"clank", -3.0, 1.3)
	impact.rumble(0.15, 0.0, 0.06)
	junction_room.sync_arm(drop_arm)
	status_line = "The clamp lets go."


## The exit bolt panel and the hatch beside it share one reach: the first USE pops the bolt once the
## sentry is down, the next leaves through the open hatch.
func _use_exit() -> void:
	if not state.door_blown:
		status_line = "The exit hatch is bolted. The lane past the door comes first."
	elif not state.sentry_down:
		status_line = "The exit bolt is locked out while the sentry runs the line."
	elif state.junction_cleared:
		status_line = "The service line runs on past the hatch. That part is not built yet."
	else:
		match bolt_state:
			&"locked":
				_pop_bolt()
			&"charging":
				status_line = "The bolt is taking the overload."
			_:
				_leave_junction()


func _pop_bolt() -> void:
	bolt_state = &"charging"
	bolt_charge_remaining = BOLT_WHINE_SECONDS
	sfx_bank.play(&"whine", -4.0)
	junction_room.sync_bolt(bolt_state, 0.0)
	status_line = "The spare overload runs into the exit bolt. The panel whines."


## The whine peaks: the bolt arcs and drops with a clank, and the hatch starts to slide open; the line
## says it is open only once it is (_hatch_opened).
func _bolt_arc() -> void:
	bolt_state = &"open"
	bolt_charge_remaining = 0.0
	sfx_bank.play(&"arc", 0.0)
	sfx_bank.play(&"clank", -2.0, 0.7)
	impact.flash(0.12, 0.0)
	impact.add_trauma(0.8)
	impact.rumble(0.5, 0.8, 0.2)
	impact.burst(junction_room.bolt_sparks)
	junction_room.sync_bolt(bolt_state, 1.0)
	junction_room.bolt_arc()
	if not fail_active:
		status_line = BOLT_ARC_LINE


## The hatch art has finished opening.
func _hatch_opened() -> void:
	if not fail_active and status_line == BOLT_ARC_LINE:
		status_line = HATCH_OPENED_LINE


## USE at the open hatch: the junction is cleared, autosave D is written, and a short closing beat
## plays before the title.
func _leave_junction() -> void:
	if not state.clear_junction():
		return
	# Autosave D: the service line is clear.
	_save_progress()
	_sync_room_lights(true)
	chapter_close_active = true
	intro_camera.position_smoothing_enabled = false
	_update_controls()
	status_line = "SERVICE LINE CLEARED. WOLF: It's quiet now. The line runs on toward Archive.\n%s: Then that's where we go." % state.human_name().get_slice(" ", 0).to_upper()
	chapter_tween = create_tween()
	# The same frame the Records close uses.
	_frame_chapter_close()


## Starts the chapter-close camera move on chapter_tween: as far right as the room allows at the
## closing zoom, so the exit and both actors share the shot.
func _frame_chapter_close() -> void:
	chapter_tween.tween_property(intro_camera, "position", CHAPTER_CLOSE_CAMERA, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	chapter_tween.parallel().tween_property(intro_camera, "zoom", Vector2.ONE * CHAPTER_CLOSE_ZOOM, 0.5)


## Runs the pressure line every frame in the junction: held USE at the valve cranks it, the line
## advances, and its events (vent trip, fuse, blast) answer with real state changes.
func _tick_junction(delta: float) -> void:
	pressure_line.paused = waiting_for_choice
	junction_room.advance_display(delta)
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
	# The line's phase moves WOLF (clear of the vent and the blast while it is live).
	if not fail_active and wolf.autonomous_target_x != _wolf_target_x():
		_update_controls()
	junction_room.sync_line(pressure_line)
	_tick_lane(delta)
	# Hiss and pump pitch are functions of the gauge, nothing else; the hiss spikes through the vent's
	# hard warning.
	if pressure_line.state == &"building":
		sfx_bank.play(&"hiss", -2.0 if pressure_line.is_warning() else lerpf(-28.0, -8.0, pressure_line.gauge))
	else:
		sfx_bank.stop(&"hiss")
	if state.door_blown:
		sfx_bank.stop(&"hum")
	else:
		sfx_bank.play(&"hum", lerpf(-16.0, -9.0, pressure_line.gauge), 0.5 * (1.0 + 0.6 * pressure_line.gauge))


## The lane past the door: the sentry wakes, patrols, locks on and chases, or holds on WOLF; the arm falls,
## rewinds and vents; the bolt charges. None of it runs during a choice (paused) or a knockdown or
## while the game is paused (_process does not reach here). Contact with a chasing sentry is a
## knockdown back to autosave B.
func _tick_lane(delta: float) -> void:
	sentry_brain.paused = waiting_for_choice
	drop_arm.paused = waiting_for_choice
	if state.door_blown and not waiting_for_choice:
		if sentry_wake_remaining > 0.0:
			sentry_wake_remaining = maxf(sentry_wake_remaining - delta, 0.0)
			if sentry_wake_remaining <= 0.0:
				sentry_brain.wake()
		var x: float = human.position.x
		# The tank lands first, against where the sentry stands at the start of this frame, so the
		# sentry's own move this frame can never carry it under a tank that was already falling.
		match drop_arm.advance(delta, sentry_brain.x):
			&"hit":
				_tank_hit()
			&"miss":
				_tank_miss()
			&"rehung":
				_tank_rehung()
		# WOLF draws it only once his front is over the rubble line; it then parks BAIT_OFFSET past his
		# spot, on the mark.
		var bait_x: float = _wolf_drawing_x()
		var before: StringName = sentry_brain.state
		var was_holding: bool = _bait_holding()
		sentry_brain.tick(delta, x, SentryBrain.is_exposed(x), bait_x)
		if sentry_brain.state != before:
			_sentry_changed(before)
		# Once it stops on the mark, "Wait" gives way to what was said before it.
		if not was_holding and _bait_holding() and status_line == DROP_WAIT_LINE:
			status_line = drop_wait_return_line
		if bolt_state == &"charging":
			bolt_charge_remaining = maxf(bolt_charge_remaining - delta, 0.0)
			if bolt_charge_remaining <= 0.0:
				_bolt_arc()
	junction_room.sentry.follow(sentry_brain)
	junction_room.sync_arm(drop_arm)
	junction_room.sync_bolt(bolt_state, 1.0 - bolt_charge_remaining / BOLT_WHINE_SECONDS if bolt_state == &"charging" else (1.0 if bolt_state == &"open" else 0.0))
	_lane_sound()
	if fail_active or not state.door_blown or state.sentry_down:
		return
	if lane_choice.is_empty() and not waiting_for_choice and human.controlled and human.position.x >= JunctionRoom.CHOICE_X:
		_ask_lane()
	elif sentry_brain.touches(human.position.x):
		_fail_beat(JunctionRoom.SENTRY_REASON)


## The servo follows the sentry's state (it idles low through the lock-on beat and runs higher in a
## chase); the winch runs while the arm rewinds.
func _lane_sound() -> void:
	match sentry_brain.state:
		&"patrol":
			sfx_bank.play(&"servo", -22.0, 1.0)
		&"lock":
			sfx_bank.play(&"servo", -24.0, 0.8)
		&"fixated":
			sfx_bank.play(&"servo", -19.0, 1.15)
		&"chase":
			sfx_bank.play(&"servo", -16.0, 1.4)
		&"dormant":
			sfx_bank.stop(&"servo")
	if drop_arm.state == &"rewinding":
		sfx_bank.play(&"winch", -14.0)
	else:
		sfx_bank.stop(&"winch")


func _sentry_changed(before: StringName) -> void:
	# Locking on sends a drawing WOLF back to the rubble until the chase ends.
	wolf.autonomous_target_x = _wolf_target_x()
	if sentry_brain.state == &"lock":
		_sentry_alarm()
	if fail_active:
		return
	match sentry_brain.state:
		&"lock":
			if before == &"patrol" or before == &"fixated":
				status_line = "The sentry stops and its eyes snap red. It has %s; get back over the rubble." % state.human_name().get_slice(" ", 0)
		&"patrol":
			if before == &"chase":
				status_line = "The sentry loses %s behind the rubble and rolls back to its patrol." % state.human_name().get_slice(" ", 0)


## The lock-on cue: a short, high klaxon chirp from the sound bank as the sentry's eye goes red.
func _sentry_alarm() -> void:
	sfx_bank.play(&"klaxon", -8.0, 1.6)


## At the rubble line WOLF asks how to bring the sentry down; the brain and the arm hold still until
## the answer.
func _ask_lane() -> void:
	waiting_for_choice = true
	choice_context = "lane"
	_update_controls()
	status_line = "WOLF: It passes under that tank on every patrol. How do we bring it down?\n1  \"%s\"\n2  \"%s\"" % [LANE_CHOICE_TEXT[0], LANE_CHOICE_TEXT[1]]


## Answer 1 asks WOLF to draw it; he chooses by the same rule as the relay contact. Answer 2, or his
## refusal, leaves the engineer to time the drop on the patrol. Neither costs anything.
func _choose_lane(response: int) -> void:
	if not waiting_for_choice or choice_context != "lane":
		return
	waiting_for_choice = false
	choice_context = ""
	if response == 1 and state.wolf_will_bait():
		lane_choice = "wolf"
		wolf_baiting = true
		status_line = "WOLF: I'll draw it onto the mark and keep clear of the tank. Drop it when it stops."
		_react_as_wolf(true)
		sfx_bank.play(&"growl", -9.0, 1.5)
	elif response == 1:
		lane_choice = "refused"
		status_line = "WOLF: No. I won't walk into its sights. It crosses the floor mark on every pass; you can time the drop from the panel."
		_react_as_wolf(false)
		sfx_bank.play(&"growl", -8.0)
	else:
		lane_choice = "alone"
		status_line = "WOLF: I'll hold at the rubble. It crosses the floor mark on every pass; the tank takes a moment to fall."
	_update_controls()


## BOOM 2: the tank comes down on the sentry. Autosave C.
func _tank_hit() -> void:
	# The tank pins the machine where it stands (at most HIT_REACH off the mark, with half its body or
	# more under the tank), so the wreck never jumps; Continue from autosave C lays it on the mark.
	var at_x: float = sentry_brain.x
	sentry_brain.knock_down()
	if not state.drop_sentry():
		return
	wolf_baiting = false
	junction_room.sentry_down = true
	junction_room.tank_hit(at_x)
	sfx_bank.play(&"boom", 0.0)
	# A glassy top over the boom: the tank's shell giving.
	sfx_bank.play(&"clank", -4.0, 2.2)
	impact.hit_stop(0.09)
	impact.flash(0.09, 0.0)
	impact.add_trauma(1.0)
	impact.rumble(0.7, 1.0, 0.3)
	impact.burst(junction_room.coolant_burst)
	impact.burst(junction_room.hit_sparks)
	_fade_servo()
	_update_controls()
	status_line = "The tank comes down square and crushes the sentry flat. Its eyes go dark.\nWOLF: It's down. The bolt by the hatch is next."
	# Autosave C: the sentry is down.
	_save_progress()


## The tank hit the empty mark: it dents and sprays coolant from a split line, the winch snaps it back
## up and the sentry turns on the release. If WOLF was drawing it, he breaks off for this attempt.
func _tank_miss() -> void:
	junction_room.tank_miss()
	sfx_bank.play(&"clank", -2.0, 0.55)
	sfx_bank.play(&"thud", -3.0, 0.8)
	impact.add_trauma(0.3)
	impact.rumble(0.3, 0.5, 0.15)
	impact.burst(junction_room.coolant_burst)
	var was: StringName = sentry_brain.state
	sentry_brain.alert()
	if sentry_brain.state == &"lock" and was != &"lock":
		_sentry_alarm()
	var broke_off: bool = wolf_baiting
	if broke_off:
		wolf_baiting = false
		wolf_broke_off = true
		_react_as_wolf(false)
	_update_controls()
	status_line = "The tank hits the empty mark and sprays coolant from a split line. The sentry swings toward the panel; get back over the rubble." + ("\nWOLF: I'm out. I'll hold at the rubble." if broke_off else "")


func _tank_rehung() -> void:
	sfx_bank.play(&"clank", -6.0, 1.1)
	if not fail_active:
		status_line = "The winch has the tank back on the clamp. The TANK RELEASE is ready again."


## The sentry's servo winds down to nothing as it goes over.
func _fade_servo() -> void:
	_kill_servo_tween()
	var player: AudioStreamPlayer = sfx_bank.play(&"servo", -16.0, 1.4)
	if player == null:
		return
	servo_tween = create_tween()
	servo_tween.tween_property(player, "pitch_scale", 0.2, 0.6)
	servo_tween.parallel().tween_property(player, "volume_db", -40.0, 0.6)
	servo_tween.tween_callback(sfx_bank.stop.bind(&"servo"))


func _kill_servo_tween() -> void:
	if servo_tween != null and servo_tween.is_valid():
		servo_tween.kill()
	servo_tween = null


func _stop_junction_loops() -> void:
	_kill_servo_tween()
	for loop_name: StringName in [&"hiss", &"hum", &"servo", &"winch"]:
		sfx_bank.stop(loop_name)


## One real valve turn: a click, a weak rumble and the VALVE plate counts it; the third turn lights the fuse.
func _valve_turned() -> void:
	sfx_bank.play(&"clank", -6.0, 1.4)
	impact.rumble(0.2, 0.0, 0.08)
	if pressure_line.state == &"charged":
		sfx_bank.play(&"klaxon", -4.0)
		status_line = "FUSE LIT. Back away from the door, past the valve."
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


## BOOM 1: the fuse ends. PressureLine.is_in_blast is the one test of the outcome: in the zone the
## door is still seen to blow (burst and torn frame) and then it is a knockdown back to autosave A,
## whose restore brings the sealed door back; otherwise the door goes, the rubble lands and
## autosave B marks the beat. The blast has no hurtbox of its own, so physics overlap can never
## disagree with this test.
func _door_blast() -> void:
	# A door that is already down has nothing left to blow: no boom, no knockdown.
	if state.door_blown:
		return
	_blast_feedback()
	if PressureLine.is_in_blast(human.position.x):
		junction_room.door_blast()
		_fail_beat(JunctionRoom.BLAST_REASON % state.human_name().get_slice(" ", 0))
		return
	if not state.blow_door():
		return
	junction_room.door_blast()
	sentry_wake_remaining = SENTRY_WAKE_SECONDS
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
	engineer_step_x = -1.0
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
	# A failed autosave leaves an older file on disk; the snapshot is the beat that failed to write.
	if state.checkpoint_reached and not save_pending and M0State.load_from_disk(save_path) != null:
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


## The seal finishing opening: the leaf is in the header, the doorway opens and WOLF lets go of the
## contact.
func _door_lands() -> void:
	seal_opening = false
	wolf_holding_relay = false
	door_shape.set_deferred("disabled", true)
	_update_controls()
	sfx_bank.play(&"thud", -2.0, 1.1)
	impact.add_trauma(0.5)
	impact.rumble(0.4, 0.6, 0.2)
	impact.burst(door_dust)


func _sync_scene() -> void:
	# The corridor's relay staging and bypass crank belong to the moment, not the save.
	wolf_holding_relay = false
	engineer_step_x = -1.0
	_stop_bypass_vent()
	bypass_ticks = 0
	bypass_was_holding = false
	bypass_handle.ticks = 0
	bypass_handle.done = state.route == "fallback"
	# The lane's choices and WOLF's part in it belong to the attempt, not the save.
	lane_choice = ""
	wolf_baiting = false
	wolf_broke_off = false
	sentry_wake_remaining = 0.0
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
	# Placed afresh, he picks his side afresh from the engineer's facing.
	wolf.follow_side = 0
	human.velocity = Vector2.ZERO
	wolf.velocity = Vector2.ZERO
	_update_controls()
	_sync_door()
	_sync_records_room()
	_sync_junction_room()
	_sync_room_lights()


## The junction shows only in its chapter; its line, bursts and hazards go back to rest and its
## door matches the save, so a reload or a knockdown never carries a half-finished beat over.
func _sync_junction_room() -> void:
	var in_junction: bool = state.chapter_id == "junction"
	junction_room.visible = in_junction
	junction_room.door_blown = state.door_blown
	junction_room.sentry_down = state.sentry_down
	junction_room.junction_cleared = state.junction_cleared
	junction_room.set_active(in_junction)
	# A blown door leaves the line spent, so a reload can never re-arm the breaker or light a fuse.
	pressure_line.reset(state.door_blown)
	# The sentry patrols from the far end once the door is down, or lies under the tank on the mark.
	sentry_brain.reset(state.door_blown, state.sentry_down, DropArm.MARK_X)
	drop_arm.reset(state.sentry_down)
	bolt_state = &"open" if state.junction_cleared else &"locked"
	bolt_charge_remaining = 0.0
	junction_room.reset_transient()
	junction_room.sync_line(pressure_line)
	junction_room.sentry.place(sentry_brain)
	junction_room.sentry.follow(sentry_brain)
	junction_room.sync_arm(drop_arm)
	junction_room.sync_bolt(bolt_state, 1.0 if bolt_state == &"open" else 0.0)
	_stop_junction_loops()


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
	for corridor_only: CanvasItem in [corridor_depth, purge_terminal_art, breaker_art, relay_art, checkpoint_art, $BreakerLabel, $RelayLabel, $CheckpointLabel, bypass_handle]:
		corridor_only.visible = in_corridor
	records_room.purge_trace_preserved = state.purge_trace_preserved
	records_room.mirror_trace_preserved = state.mirror_trace_preserved
	records_room.chapter_complete = state.chapter_complete
	records_room.exit_art.position = RecordsRoom.EXIT_REST
	records_room.exit_art.modulate = Color.WHITE
	records_room.exit_art.visible = not state.chapter_complete or animate_exit
	records_room.refresh_state()


## The corridor bulkhead: sealed, or standing open on the passage beyond. Opening in play slides the
## seal's leaf up into the header over the open bulkhead (SealLeaf), and the doorway stays shut until
## it lands with its thud and dust. Its front pillar shows either way.
func _sync_door(animate: bool = false) -> void:
	if door_tween != null and door_tween.is_running():
		door_tween.kill()
	var in_corridor: bool = state.chapter_id == "lockdown"
	var sliding: bool = in_corridor and state.door_open and animate
	seal_opening = sliding
	door_shape.set_deferred("disabled", state.door_open and not sliding)
	door_visual.scale = Vector2.ONE
	door_visual.modulate = Color.WHITE
	door_visual.visible = in_corridor and not state.door_open
	door_open_art.visible = in_corridor and state.door_open
	door_lip.visible = in_corridor
	seal_leaf.open = 0.0
	seal_leaf.visible = sliding
	if sliding:
		door_tween = create_tween()
		door_tween.tween_property(seal_leaf, "open", 1.0, CORRIDOR_DOOR_OPEN_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		door_tween.tween_callback(seal_leaf.hide)
		door_tween.tween_callback(_door_lands)


func _update_controls() -> void:
	human.controlled = not title_open and not intro_active and not chapter_close_active and not waiting_for_choice and not fail_active and engineer_step_x < 0.0
	# Stepping back from the relay, the engineer walks on their own for a moment.
	human.autonomous_target_x = engineer_step_x
	wolf.controlled = false
	wolf.autonomous_target_x = _wolf_target_x()
	wolf.follow_target = human if human.controlled and wolf.autonomous_target_x < 0.0 else null
	wolf.follow_max_x = _wolf_follow_max_x()
	human.queue_redraw()
	wolf.queue_redraw()


## Where WOLF goes on his own, or -1 to follow: the relay contact (held until the seal lands), the
## Records mirror, the junction door seam on entry, clear of the vent and the blast while the line is
## live, and the rubble line once the door is down (he will not cross it unless he chooses to draw the
## sentry onto the mark).
func _wolf_target_x() -> float:
	if wolf_heading_to_relay or wolf_holding_relay:
		return RELAY_CONTACT_X
	match state.chapter_id:
		"records":
			return -1.0 if state.mirror_trace_preserved else 520.0
		"junction":
			if wolf_scouting:
				return JunctionRoom.WOLF_SEAM_X
			if not state.door_blown and pressure_line.state in [&"building", &"charged", &"fuse"]:
				# While the line builds he keeps off the vent's grate, and while the fuse burns he is out of
				# the blast zone.
				return JunctionRoom.WOLF_CLEAR_X
			if state.door_blown and not state.sentry_down:
				# He draws the sentry only by his own choice; otherwise he will not cross the rubble. While it
				# is locked on to the engineer or chasing them he waits at the rubble rather than walk into it.
				return JunctionRoom.WOLF_BAIT_X if wolf_baiting and not _sentry_hunting() else JunctionRoom.WOLF_RUBBLE_X
	return -1.0


## The furthest right WOLF follows to: short of a shut door by his drawn reach, so he never noses
## into it and the engineer always has room in front of it. His authored spots ignore this.
func _wolf_follow_max_x() -> float:
	if state.chapter_id == "lockdown" and not state.door_open:
		return CORRIDOR_DOOR_LEFT_X - M0Actor.WOLF_REACH
	if state.chapter_id == "junction" and not state.door_blown:
		return M0State.JUNCTION_DOOR_LEFT_X - M0Actor.WOLF_REACH
	return M0Actor.MAX_X


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
	touch_use.text = "CONTINUE" if intro_active or chapter_close_active else ("CRANK" if not _hold_station().is_empty() else ("DROP" if _drop_ready() else "USE"))
	touch_choice_1.visible = waiting_for_choice
	touch_choice_2.visible = waiting_for_choice
	if waiting_for_choice:
		touch_choice_1.position = Vector2(42.0, CHOICE_ROW_TOP) if touch_layout else Vector2(396.0, CHOICE_ROW_TOP)
		touch_choice_2.position = Vector2(490.0, CHOICE_ROW_TOP) if touch_layout else Vector2(396.0, CHOICE_ROW_TOP + 46.0)
		touch_choice_1.size = Vector2(428.0, 76.0) if touch_layout else Vector2(522.0, 40.0)
		touch_choice_2.size = Vector2(428.0, 76.0) if touch_layout else Vector2(522.0, 40.0)
		touch_choice_1.add_theme_font_size_override("font_size", 17 if touch_layout else 16)
		touch_choice_2.add_theme_font_size_override("font_size", 17 if touch_layout else 16)
		var choice_1_key: String = settings_menu.prompt(&"choice_1", controller_active)
		var choice_2_key: String = settings_menu.prompt(&"choice_2", controller_active)
		var answers: Array[String] = [M0State.CHOICE_TEXT[M0State.DISCLOSE], M0State.CHOICE_TEXT[M0State.PRESS]]
		if choice_context == "mirror":
			answers = ["USE WOLF'S READOUT", "USE MANUAL PORT"]
		elif choice_context == "lane":
			answers = LANE_CHOICE_TEXT
		touch_choice_1.text = "%s  %s" % [choice_1_key, answers[0]]
		touch_choice_2.text = "%s  %s" % [choice_2_key, answers[1]]
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
			_show_top_card("SERVICE JUNCTION\nSERVICE LINE CLEARED" if state.chapter_id == "junction" else "RECORDS ACCESS\nFIRST COPY SECURED", 3.4)
		_set_dialogue(status_line, "TAP CONTINUE" if touch_layout else "%s  CONTINUE" % settings_menu.prompt(&"interact", controller_active))
		return
	breaker_art.modulate = Color.WHITE if state.breaker_armed else Color("#879ba5")
	breaker_status_light.color = Color("#8be3ff") if state.breaker_armed else Color("#d48954")
	relay_art.modulate = Color.WHITE if state.breaker_armed else Color("#879ba5")
	relay_status_light.color = Color("#a4f0c4") if state.door_open else (Color("#f3ae4b") if state.breaker_armed and _relay_refused() else (Color("#8be3ff") if state.breaker_armed else Color("#536e7c")))
	bypass_handle.live = state.breaker_armed and not state.door_open
	breaker_status_glow.modulate = Color(breaker_status_light.color, 0.75 if state.breaker_armed else 0.45)
	relay_status_glow.modulate = Color(relay_status_light.color, 0.75 if state.breaker_armed else 0.3)
	checkpoint_art.modulate = Color("#d5ffe3") if state.checkpoint_reached else Color.WHITE
	human_tag.text = state.human_name().get_slice(" ", 0).to_upper()
	var card_key: String = "%s:%s" % [state.chapter_id, _objective()]
	if name_card_remaining > 0.0 and state.chapter_id == "lockdown":
		# The name card comes first; the location card follows once it has faded or been skipped.
		var name_card: String = "%s\nMAINTENANCE ENGINEER" % state.human_name().to_upper()
		if last_top_card_key != "name_card":
			last_top_card_key = "name_card"
			_show_top_card(name_card, NAME_CARD_SECONDS, ENGINEER_TINT)
		elif hud.text != name_card:
			# Cycling the provisional name while it is up updates it in place.
			hud.text = name_card
	elif last_top_card_key != card_key:
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


func _show_top_card(message: String, hold_seconds: float, accent: Color = TOP_CARD_ACCENT) -> void:
	if top_card_tween != null and top_card_tween.is_running():
		top_card_tween.kill()
	hud.text = message
	($CanvasLayer/TopBar/Accent as ColorRect).color = accent
	top_card.modulate.a = 1.0
	top_card.show()
	top_card_tween = create_tween()
	top_card_tween.tween_interval(hold_seconds)
	top_card_tween.tween_property(top_card, "modulate:a", 0.0, TOP_CARD_FADE_SECONDS)
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
			if state.mirror_trace_preserved:
				return "Mirror copied. Head for the exit."
			return "E: examine the mirror port." if state.purge_trace_preserved else "Copy the purge order first."
		if absf(x - 830.0) <= 58.0:
			return "E: secure the first copy." if state.mirror_trace_preserved else "Preserve both traces before leaving."
		return "Follow the station lights: purge queue, mirror port, then exit."
	if state.checkpoint_reached:
		return "E: enter records access. The Director's purge is still running." if absf(x - 876.0) <= 52.0 else ("E: read the Director's purge display." if x <= 230.0 else "Return to the safe point to enter records access.")
	if state.door_open:
		if seal_opening:
			return SEAL_OPENING_HINT
		if absf(x - 876.0) <= 52.0:
			return "E: save at the safe point."
		return "The seal is open. Move to the safe point."
	if x <= PURGE_DISPLAY_MAX_X:
		return "E: read the Director's purge display."
	if wolf_heading_to_relay:
		return "WOLF is moving to the contact."
	if _at_bypass(x):
		if not state.breaker_armed:
			return "The bypass is dead. Arm the breaker first."
		if bypass_ticks == 0 and not _relay_refused():
			return "HOLD E: crank it yourself, or let WOLF take the relay."
		return BYPASS_HOLD_HINT % [bypass_ticks, BYPASS_TICKS]
	if absf(x - 350.0) <= 52.0:
		if state.breaker_armed:
			return "The breaker is live. Go to the MANUAL BYPASS by the relay." if _relay_refused() else "The breaker is live. Go to the coolant relay."
		return "E: talk to WOLF about the relay." if state.memory.is_empty() else "E: arm the breaker."
	if absf(x - RELAY_X) <= RELAY_REACH:
		if not state.breaker_armed:
			return "The relay is dark. Return to the breaker first."
		return "WOLF refused the live contact. Use the MANUAL BYPASS beside it." if _relay_refused() else "E: signal WOLF to take the contact."
	if state.breaker_armed:
		return "Go to the MANUAL BYPASS beside the relay." if _relay_refused() else "Go to the coolant relay. WOLF is ready for the contact."
	if not state.memory.is_empty():
		return "Return to the breaker and arm power."
	return "Find the breaker. WOLF will follow your lead."


func _junction_hint(x: float) -> String:
	var line: StringName = pressure_line.state
	var fuse_lit: bool = line == &"charged" or line == &"fuse"
	if state.door_blown:
		return _lane_hint(x)
	# Standing on the grate while the line builds is the one place that can knock you down, so
	# that warning wins over the breaker's hint where the two ranges touch.
	if line == &"building" and PressureLine.is_on_vent(x):
		return "The vent is about to blow. Get off the grate now." if pressure_line.is_warning() else "Relief vent. Get off the grate before the gauge peaks."
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
		return "Fuse lit. Get clear of the door."
	if absf(x - JunctionRoom.VALVE_X) <= 52.0:
		return "The valve is dead. Arm the breaker by the entrance."
	if PressureLine.is_on_vent(x):
		return "Relief vent. It lets go when the gauge peaks."
	match line:
		&"building":
			return "The line is building. Crank the valve by the door."
		&"tripped":
			return "The breaker tripped. Reset it by the entrance."
	return "Arm the breaker by the entrance, then crank the valve by the door."


## True while the sentry is after the engineer: locking on or chasing.
func _sentry_hunting() -> bool:
	return sentry_brain.state == &"lock" or sentry_brain.state == &"chase"


## The tank can drop now: the engineer is at the TANK RELEASE with the tank hanging over a live
## sentry, and, if WOLF is drawing it, he has it stopped on the mark (_drop_waits_for_wolf).
func _drop_ready() -> bool:
	return state.chapter_id == "junction" and state.door_blown and not state.sentry_down and drop_arm.state == &"hung" and _at_arm_panel(human.position.x) and not _drop_waits_for_wolf()


func _lane_hint(x: float) -> String:
	if state.junction_cleared:
		return "The hatch is open. The line beyond it is not built yet."
	if state.sentry_down:
		if x >= JunctionRoom.BOLT_X - 40.0:
			match bolt_state:
				&"locked":
					return "E: pop the exit bolt."
				&"charging":
					return "The bolt is taking the overload."
			return "E: leave through the hatch."
		return "The hatch is open. Leave through it." if bolt_state == &"open" else "The sentry is down. Pop the exit bolt by the hatch."
	if drop_arm.cloud_active() and DropArm.in_cloud(x):
		return "Coolant cloud. Get out of it."
	if _sentry_hunting() and x > SentryBrain.LANE_ENTRY_X:
		return "It's after you. Get back over the rubble."
	if _at_arm_panel(x):
		match drop_arm.state:
			&"hung":
				if wolf_baiting:
					return "Wait for WOLF to park it on the mark." if _drop_waits_for_wolf() else "E: drop the tank. It's parked on the mark."
				return "E: drop the tank. It must land with the sentry in the brackets."
			&"falling":
				return "The tank is falling."
			&"rewinding":
				return "The winch is hauling the tank back up. Wait for the clamp."
	if _sentry_hunting():
		return "Stay back over the rubble until it gives up."
	if SentryBrain.is_exposed(x):
		return "You're in its lane. Get into the release alcove or back over the rubble."
	if wolf_baiting:
		return "WOLF is drawing the sentry onto the mark. Get to the TANK RELEASE."
	if wolf_broke_off:
		return "WOLF has broken off. Time the drop on its patrol from the TANK RELEASE."
	return "The sentry patrols past the rubble. The TANK RELEASE is in the alcove just inside."


func _objective() -> String:
	if state.chapter_id == "junction":
		if state.junction_cleared:
			return "SERVICE LINE CLEARED"
		if state.sentry_down:
			return "POP THE EXIT BOLT"
		if state.door_blown:
			return "DROP THE TANK"
		match pressure_line.state:
			&"building":
				return "CHARGE THE SEAL"
			&"charged", &"fuse", &"blown":
				return "GET CLEAR OF THE DOOR"
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
