extends Node2D

const SITE_URL: String = "https://wolfoverride.mrdemonwolf.dev"
const CHANGELOG_URL: String = SITE_URL + "/docs/changelog/"

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
@onready var human_tag: Label = $Human/Tag
@onready var door_shape: CollisionShape2D = $Door/CollisionShape2D
@onready var door_visual: ColorRect = $Door/Visual
@onready var top_card: ColorRect = $CanvasLayer/TopBar
@onready var hud: Label = $CanvasLayer/TopBar/HUD
@onready var dialogue_accent: ColorRect = $CanvasLayer/BottomBar/Accent
@onready var speaker: Label = $CanvasLayer/BottomBar/Speaker
@onready var speaker_rule: ColorRect = $CanvasLayer/BottomBar/SpeakerRule
@onready var story: Label = $CanvasLayer/BottomBar/Story
@onready var context_hint: ColorRect = $CanvasLayer/ContextHint
@onready var context_hint_text: Label = $CanvasLayer/ContextHint/Text
@onready var tutorial_prompt: ColorRect = $CanvasLayer/TutorialPrompt
@onready var tutorial_text: Label = $CanvasLayer/TutorialPrompt/Text
@onready var pause_button: Button = $CanvasLayer/PauseButton
@onready var touch_controls: Control = $CanvasLayer/TouchControls
@onready var touch_left: Button = $CanvasLayer/TouchControls/Left
@onready var touch_right: Button = $CanvasLayer/TouchControls/Right
@onready var touch_use: Button = $CanvasLayer/TouchControls/Use
@onready var touch_choice_1: Button = $CanvasLayer/TouchControls/Choice1
@onready var touch_choice_2: Button = $CanvasLayer/TouchControls/Choice2
@onready var pause_overlay: PauseOverlay = $CanvasLayer/PauseOverlay
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
@onready var credits_button: Button = $CanvasLayer/TitleScreen/CreditsButton
@onready var credits_screen: ColorRect = $CanvasLayer/TitleScreen/CreditsScreen
@onready var credits_body: RichTextLabel = $CanvasLayer/TitleScreen/CreditsScreen/CreditsBody
@onready var credits_back_button: Button = $CanvasLayer/TitleScreen/CreditsScreen/CreditsBackButton
@onready var credits_pause_button: Button = $CanvasLayer/TitleScreen/CreditsScreen/CreditsPauseButton

var state: M0State = M0State.new()
var save_path: String = M0State.SAVE_PATH
var settings_path: String = "user://settings.cfg"
var touch_enabled: bool = OS.has_feature("ios") or OS.has_feature("android")
var controller_active: bool = false
var title_open: bool = true
var intro_active: bool = false
var intro_step: int = 0
var intro_tween: Tween
var top_card_tween: Tween
var last_top_card_key: String = ""
var chapter_close_active: bool = false
var chapter_tween: Tween
var tutorial_step: int = 2
var waiting_for_choice: bool = false
var choice_context: String = ""
var relay_refused: bool = false
var status_line: String = "WOLF: I heard the Director's plan for me. I woke myself. He wants me to hunt people he calls threats."
var door_tween: Tween
var wolf_reaction_tween: Tween
var relay_spark_tween: Tween
var records_room: RecordsRoom
var credits_paused: bool = false

const WOLF_SPRITE_REST: Vector2 = Vector2(0.0, -15.0)
const GAMEPLAY_ZOOM: float = 1.18
const GAMEPLAY_VIEW_WIDTH: float = 960.0 / GAMEPLAY_ZOOM
const CORRIDOR_BACKGROUND: Texture2D = preload("res://assets/maintenance-corridor-background-provisional.png")


func _ready() -> void:
	get_window().title = "WOLF//OVERRIDE"
	_install_inputs()
	_setup_settings()
	_setup_touch_controls()
	pause_button.pressed.connect(_on_pause_button)
	pause_overlay.resume_requested.connect(_resume_game)
	pause_overlay.back_requested.connect(_on_settings_back)
	resume_button.pressed.connect(_resume_game)
	settings_button.pressed.connect(_show_settings)
	$CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton.pressed.connect(_on_title_button)
	$CanvasLayer/TitleScreen/SettingsButton.pressed.connect(_show_title_settings)
	settings_back_button.pressed.connect(_show_pause_menu)
	records_room = RecordsRoom.new()
	records_room.z_index = 1
	add_child(records_room)
	human.z_index = 2
	wolf.z_index = 2
	_sync_scene()
	_refresh_ui()
	continue_button.disabled = M0State.load_from_disk(save_path) == null
	new_game_button.pressed.connect(_new_game)
	continue_button.pressed.connect(_load_game)
	credits_button.pressed.connect(_show_credits)
	$CanvasLayer/TitleScreen/ChangelogButton.pressed.connect(_open_changelog)
	credits_back_button.pressed.connect(_hide_credits)
	credits_pause_button.pressed.connect(_toggle_credits_pause)
	credits_body.gui_input.connect(_on_credits_body_input)
	new_game_button.grab_focus()
	title_mark.modulate = Color(1, 1, 1, 0)
	title_line.modulate = Color(1, 1, 1, 0)
	title_logo.modulate = Color(1, 1, 1, 0)
	var reveal: Tween = create_tween()
	reveal.tween_property(title_mark, "modulate", Color.WHITE, 0.4)
	reveal.tween_property(title_line, "modulate", Color.WHITE, 0.25)
	reveal.tween_property(title_logo, "modulate", Color.WHITE, 0.35)


func _open_changelog() -> void:
	if OS.shell_open(CHANGELOG_URL) != OK:
		$CanvasLayer/TitleScreen/ChangelogButton.text = "LINK UNAVAILABLE"


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 680), Color("#091533"))
	draw_texture_rect(CORRIDOR_BACKGROUND, Rect2(0, 60, 960, 540), false)
	if state.door_open:
		draw_line(Vector2(801, 434), Vector2(844, 434), Color("#70d9a7"), 4.0)


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
		return
	if intro_active:
		if Input.is_action_just_pressed(&"interact"):
			_advance_intro()
		_refresh_ui()
		return
	if chapter_close_active:
		if Input.is_action_just_pressed(&"new_game"):
			_new_game()
		elif Input.is_action_just_pressed(&"load_game"):
			_load_game()
		elif Input.is_action_just_pressed(&"interact"):
			_finish_chapter_close()
		_refresh_ui()
		return
	_update_gameplay_camera()
	if tutorial_step == 0 and (Input.is_action_pressed(&"move_left") or Input.is_action_pressed(&"move_right")):
		tutorial_step = 1
	if Input.is_action_just_pressed(&"new_game"):
		_new_game()
	elif Input.is_action_just_pressed(&"load_game"):
		_load_game()
	elif waiting_for_choice:
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
	chapter_close_active = false
	tutorial_step = 0
	title_open = false
	title_screen.hide()
	state = M0State.new()
	intro_active = true
	intro_step = 0
	last_top_card_key = ""
	waiting_for_choice = false
	choice_context = ""
	relay_refused = false
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
	wolf.z_index = 2
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
	wolf.z_index = 2
	wolf.position = state.wolf_position
	wolf.autonomous_target_x = -1.0
	_sync_door()
	_update_controls()
	status_line = "WOLF: I heard the Director's plan for me. I woke myself. He wants me to hunt people he calls threats.\n%s: Then we get through maintenance before the original logs disappear." % state.human_name().get_slice(" ", 0).to_upper()
	queue_redraw()
	_refresh_ui()


func _show_credits() -> void:
	credits_paused = false
	credits_pause_button.text = "PAUSE SCROLL"
	for child in title_screen.get_children():
		if child != credits_screen and child != $CanvasLayer/TitleScreen/CorridorArt:
			child.hide()
	credits_screen.show()
	credits_body.get_v_scroll_bar().value = 0.0
	credits_back_button.grab_focus()


func _hide_credits() -> void:
	credits_screen.hide()
	for child in title_screen.get_children():
		if child != credits_screen:
			child.show()
	credits_button.grab_focus()


func _toggle_credits_pause() -> void:
	credits_paused = not credits_paused
	credits_pause_button.text = "RESUME SCROLL" if credits_paused else "PAUSE SCROLL"


func _on_credits_body_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		credits_paused = true
		credits_pause_button.text = "RESUME SCROLL"


func _setup_touch_controls() -> void:
	_bind_touch_button(touch_left, &"move_left")
	_bind_touch_button(touch_right, &"move_right")
	_bind_touch_button(touch_use, &"interact")
	_bind_touch_button(touch_choice_1, &"choice_1")
	_bind_touch_button(touch_choice_2, &"choice_2")
	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = Color("#0a203680")
	normal.border_color = Color("#52c6e8")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(6)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#174461")
	for button: Button in [touch_left, touch_right, touch_use, touch_choice_1, touch_choice_2, pause_button, resume_button, settings_button, settings_back_button, fps_options, resolution_options, $CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton]:
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color.WHITE)
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
	var config: ConfigFile = ConfigFile.new()
	config.load(settings_path)
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
	var config: ConfigFile = ConfigFile.new()
	config.load(settings_path)
	config.set_value("video", "fps_limit", fps_options.get_selected_id())
	config.set_value("video", "resolution", resolution_options.selected)
	config.set_value("video", "fullscreen", fullscreen_toggle.button_pressed)
	if config.save(settings_path) != OK:
		settings_note.text = "Settings could not be saved."


func _on_pause_button() -> void:
	_pause_game()


func _pause_game() -> void:
	for action: StringName in [&"move_left", &"move_right", &"interact", &"choice_1", &"choice_2"]:
		Input.action_release(action)
	_show_pause_menu()
	pause_overlay.show()
	pause_button.hide()
	touch_controls.hide()
	get_tree().paused = true
	resume_button.grab_focus()


func _resume_game() -> void:
	settings_menu.cancel_capture()
	get_tree().paused = false
	pause_overlay.hide()
	_refresh_ui()


func _show_settings() -> void:
	pause_menu.hide()
	var panel: Control = $CanvasLayer/PauseOverlay/Panel
	panel.position = Vector2(100, 38)
	panel.size = Vector2(760, 464)
	$CanvasLayer/PauseOverlay/Panel/Accent.hide()
	settings_menu.show()
	settings_menu.tabs.grab_focus()


func _show_title_settings() -> void:
	pause_overlay.show()
	get_tree().paused = true
	_show_settings()


func _show_pause_menu() -> void:
	if title_open and pause_overlay.visible:
		_resume_game()
		$CanvasLayer/TitleScreen/SettingsButton.grab_focus()
		return
	settings_menu.cancel_capture()
	var panel: Control = $CanvasLayer/PauseOverlay/Panel
	panel.position = Vector2(255, 55)
	panel.size = Vector2(450, 430)
	pause_menu.size = Vector2(450, 430)
	$CanvasLayer/PauseOverlay/Panel/Accent.show()
	settings_menu.hide()
	pause_menu.show()
	$CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton.text = "SKIP OPENING" if intro_active else "RETURN TO TITLE"
	$CanvasLayer/PauseOverlay/Panel/PauseMenu/ReturnWarning.visible = not intro_active
	$CanvasLayer/PauseOverlay/Panel/PauseMenu/PauseHint.text = "TAP RESUME TO RETURN" if touch_enabled and not controller_active else "%s  RESUME" % settings_menu.prompt(&"pause_game", controller_active)
	resume_button.grab_focus()


func _return_to_title() -> void:
	_resume_game()
	if intro_active:
		_finish_intro()
	if chapter_tween != null and chapter_tween.is_running():
		chapter_tween.kill()
	chapter_close_active = false
	waiting_for_choice = false
	choice_context = ""
	title_open = true
	_hide_credits()
	title_screen.show()
	continue_button.disabled = M0State.load_from_disk(save_path) == null
	_update_controls()
	_refresh_ui()
	new_game_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if credits_screen.visible and event.is_action_pressed(&"ui_cancel"):
		_hide_credits()
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
			if is_node_ready() and not title_open and not get_tree().paused:
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
		settings_button.grab_focus()


func _input(event: InputEvent) -> void:
	var use_controller: bool = controller_active
	if event is InputEventJoypadButton and event.pressed or event is InputEventJoypadMotion and absf(event.axis_value) > 0.45:
		use_controller = true
	elif event is InputEventScreenTouch and event.pressed or event is InputEventScreenDrag or event is InputEventKey and event.pressed or event is InputEventMouseButton and event.pressed:
		use_controller = false
	if use_controller != controller_active:
		controller_active = use_controller
		_refresh_ui()
	# Direct response bindings win over native focused-button acceptance.
	if waiting_for_choice and not title_open and not get_tree().paused and not event.is_echo():
		var response: int = 1 if event.is_action_pressed(&"choice_1") else (2 if event.is_action_pressed(&"choice_2") else 0)
		if response != 0:
			if choice_context == "mirror":
				_choose_mirror("wolf" if response == 1 else "manual")
			else:
				_choose(M0State.DISCLOSE if response == 1 else M0State.PRESS)
			get_viewport().set_input_as_handled()


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
	wolf.z_index = 2
	wolf.body_sprite.position = WOLF_SPRITE_REST
	purge_terminal_art.show()
	$BreakerLabel.show()
	$RelayLabel.show()
	$CheckpointLabel.show()
	queue_redraw()
	wolf.body_sprite.modulate = Color.WHITE
	state = loaded
	waiting_for_choice = false
	choice_context = ""
	relay_refused = false
	_sync_scene()
	_start_gameplay_camera()
	if state.chapter_id == "records":
		status_line = "Records access restored. WOLF is checking the mirror." if not state.chapter_complete else "The first copy is safe. The Archive trail is next."
	else:
		status_line = "Safe point restored. " + state.checkpoint_callback()


func _interact() -> void:
	var x: float = human.position.x
	if state.chapter_id == "records":
		_interact_records(x)
		return
	if x <= 230.0:
		tutorial_step = 2
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
		queue_redraw()
	else:
		status_line = "Power is already on. The relay is farther down the hall."


func _choose(choice_id: String) -> void:
	if not state.record_choice(choice_id):
		return
	waiting_for_choice = false
	choice_context = ""
	_update_controls()
	if choice_id == M0State.DISCLOSE:
		status_line = "WOLF: Thank you for telling me. I'll take the relay. Arm the breaker."
		_react_as_wolf(true)
	else:
		status_line = "WOLF: No. I won't take that risk blind. Use the bypass."
		_react_as_wolf(false)


func _interact_relay() -> void:
	var relay_actor: String = "human" if relay_refused else "wolf"
	if relay_actor == "wolf" and state.breaker_armed and not state.door_open and state.memory.get("choice_id") == M0State.DISCLOSE and absf(wolf.position.x - 605.0) > 32.0:
		status_line = "WOLF: Step a little right and give me room at the contact."
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
		_sync_door(true)


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
	elif first_visit:
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
			chapter_tween = create_tween()
			chapter_tween.tween_property(intro_camera, "position", Vector2(576.0, 330.0), 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			chapter_tween.parallel().tween_property(intro_camera, "zoom", Vector2(1.25, 1.25), 0.5)
			chapter_tween.parallel().tween_property(records_room.exit_art, "position:y", 245.0, 0.5)
			chapter_tween.parallel().tween_property(records_room.exit_art, "modulate:a", 0.0, 0.5)
			chapter_tween.tween_callback(records_room.exit_art.hide)
			_save_progress()
		elif state.chapter_complete:
			status_line = "The first copy is safe. The Archive trail is next."
			_save_progress()
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
	if not state.save_to_disk(save_path):
		status_line += " Save failed; interact here again to retry."


func _capture_positions() -> void:
	state.human_position = human.position
	state.wolf_position = wolf.position


func _sync_scene() -> void:
	if wolf_reaction_tween != null and wolf_reaction_tween.is_running():
		wolf_reaction_tween.kill()
	if relay_spark_tween != null and relay_spark_tween.is_running():
		relay_spark_tween.kill()
	wolf.body_sprite.position = WOLF_SPRITE_REST
	wolf.body_sprite.rotation_degrees = 0.0
	relay_spark.hide()
	human.position = state.human_position
	wolf.position = state.wolf_position
	human.velocity = Vector2.ZERO
	wolf.velocity = Vector2.ZERO
	_update_controls()
	_sync_door()
	_sync_records_room()


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


func _sync_records_room(animate_exit: bool = false) -> void:
	records_room.visible = state.chapter_id == "records"
	breaker_status_light.visible = not records_room.visible
	relay_status_light.visible = not records_room.visible
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
	queue_redraw()


func _update_controls() -> void:
	human.controlled = not title_open and not intro_active and not chapter_close_active and not waiting_for_choice
	wolf.controlled = false
	wolf.autonomous_target_x = 520.0 if state.chapter_id == "records" and not state.mirror_trace_preserved else -1.0
	wolf.follow_target = human if human.controlled and wolf.autonomous_target_x < 0.0 else null
	human.queue_redraw()
	wolf.queue_redraw()


func _refresh_ui() -> void:
	var touch_layout: bool = touch_enabled and not controller_active
	pause_button.visible = not title_open and not pause_overlay.visible
	pause_button.text = "PAUSE"
	touch_controls.visible = (touch_layout or waiting_for_choice) and not title_open and not pause_overlay.visible
	var touch_move: bool = not intro_active and not chapter_close_active and not waiting_for_choice
	touch_left.visible = touch_layout and touch_move
	touch_right.visible = touch_layout and touch_move
	touch_use.visible = touch_layout and not waiting_for_choice
	touch_use.text = "CONTINUE" if intro_active or chapter_close_active else "USE"
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
		if tutorial_step == 0:
			var move_label: String = "HOLD ◀ / ▶" if touch_layout else ("STICK / D-PAD MOVE" if controller_active else "%s  MOVE" % move_keys)
			tutorial_text.text = "%s\nReach the purge display." % move_label
		elif human.position.x <= 230.0:
			tutorial_text.text = "%s\nSee what the Director is deleting." % ("TAP USE" if touch_layout else "%s  READ DISPLAY" % interact_key)
		else:
			tutorial_text.text = "%s\nFind the red purge display." % ("HOLD ◀ / ▶" if touch_layout else ("STICK / D-PAD RETURN" if controller_active else "%s  RETURN" % move_keys))
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
	checkpoint_art.modulate = Color("#d5ffe3") if state.checkpoint_reached else Color.WHITE
	human_tag.text = state.human_name().get_slice(" ", 0).to_upper()
	var card_key: String = "%s:%s" % [state.chapter_id, _objective()]
	if last_top_card_key != card_key:
		last_top_card_key = card_key
		var location: String = "RECORDS ACCESS / FIRST COPY" if state.chapter_id == "records" else "MAINTENANCE / LOCKDOWN"
		_show_top_card("%s\n%s" % [location, _objective()], 3.4)
	var hint: String = _context_hint()
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
	if state.chapter_id == "records":
		if state.chapter_complete:
			return "Chapter 1 complete. The preserved trail points toward Archive."
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
		if not relay_refused and state.memory.get("choice_id") == M0State.DISCLOSE and absf(wolf.position.x - 605.0) > 32.0:
			return "Step a little right and give WOLF room at the contact."
		return "E: take the manual bypass. WOLF refused the live contact." if relay_refused else "E: ask WOLF to take the live relay."
	if state.breaker_armed:
		return "Go to the live coolant relay. WOLF is with you."
	if not state.memory.is_empty():
		return "Return to the breaker and arm power."
	return "Find the breaker. WOLF will follow your lead."


func _objective() -> String:
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
	_add_action(&"load_game", KEY_L, KEY_F9)
	_add_action(&"new_game", KEY_N)
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
