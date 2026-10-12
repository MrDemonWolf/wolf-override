extends SceneTree
## MOCK capture for PIN option B (never part of the repository). Loads the real junction at the
## tank-down beat, stands the engineer at the exit bolt, and lays the mock keypad card over it.
## Revised: rendered on main at cfe304f, with WOLF left at his spot in the hatch doorway
## (JunctionRoom.WOLF_DOWN_X); WOLF reads the code on both relay routes (tone only differs); the
## lockout uses no beacons or klaxon; 06 now shows one consistent state; 03 uses the touch layout.

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SAVE: String = "user://pin-mock-save.json"
const SETTINGS: String = "user://pin-mock-settings.cfg"
const CARD: GDScript = preload("res://pin_mock_b/keypad_card_mock.gd")

var out_dir: String = ""
var game: Node2D
var card: Control
var reader: Node2D


class Reader extends Node2D:
	## The world-side reader on the bolt panel: a small housing, a 4-cell strip and a mode lamp.
	var tint: Color = Color("#f3ae4b")
	var word: String = "LOCAL"
	var seal_intact: bool = false
	func _draw() -> void:
		var font: Font = preload("res://assets/fonts/Montserrat-Bold.tres")
		draw_rect(Rect2(-9, -15, 18, 26), Color("#0b141b"))
		draw_rect(Rect2(-9, -15, 18, 26), Color(0.35, 0.5, 0.58, 0.9), false, 1.0)
		draw_rect(Rect2(-7, -13, 14, 5), Color("#03080c"))
		for i: int in range(3):
			for j: int in range(4):
				draw_rect(Rect2(-6 + i * 4.3, -6 + j * 4.0, 3.2, 3.0), Color(0.55, 0.68, 0.74, 0.9))
		# State on the lamp's shape and colour only (LABELS): square LOCKDOWN / LOCKOUT, rounded LOCAL,
		# round OPEN. No world text; the mode word is on the card and in reach.
		draw_circle(Vector2(0, -20), 6.0, Color(tint, 0.22))
		match word:
			"LOCAL":
				draw_rect(Rect2(-3, -23, 6, 6), tint)
				draw_circle(Vector2(0, -20), 2.6, tint)
			"OPEN":
				draw_circle(Vector2(0, -20), 3.2, tint)
			_:
				draw_rect(Rect2(-3.2, -23.2, 6.4, 6.4), tint)
		if seal_intact:
			draw_rect(Rect2(10, -8, 7, 14), Color("#c8322a"))
			draw_rect(Rect2(10, -2, 7, 2), Color("#ffe9a8"))


func _initialize() -> void:
	call_deferred("_run")


func _arg(key: String, fallback: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return fallback


func _settle(frames: int) -> void:
	for _i: int in range(frames):
		await process_frame


func _run() -> void:
	out_dir = _arg("out", OS.get_user_data_dir())
	DirAccess.make_dir_recursive_absolute(out_dir)
	for p: String in [SAVE, SETTINGS]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	game = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", SAVE)
	game.set("settings_path", SETTINGS)
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)
	await _settle(20)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	await _settle(30)
	var state: M0State = M0State.new()
	state.record_choice(M0State.DISCLOSE)
	state.arm_breaker()
	state.activate_power("wolf")
	state.reach_checkpoint()
	state.enter_records()
	state.preserve_purge_trace()
	state.preserve_mirror_trace("wolf")
	state.complete_chapter()
	state.enter_junction()
	state.blow_door()
	state.drop_sentry()
	state.lane_recap = "wolf"
	state.human_position.x = JunctionRoom.BOLT_X
	state.wolf_position.x = JunctionRoom.WOLF_DOWN_X
	state.save_to_disk(SAVE)
	game.call("debug_load_checkpoint")
	await _settle(10)
	var bolt: Vector4 = Main.JUNCTION_STATIONS[3]
	var spot: float = game.call("debug_station_side_x", bolt, bolt.x - 40.0)
	game.call("debug_place", spot, JunctionRoom.WOLF_DOWN_X)
	await _settle(90)
	await _shot("00-baseline")
	game.set_process(false)
	# World reader on the bolt panel's left face.
	reader = Reader.new()
	reader.position = Vector2(JunctionRoom.BOLT_PANEL_X - 2.0, 392.0)
	reader.z_index = 5
	game.add_child(reader)
	var ui: CanvasLayer = game.get_node("CanvasLayer") as CanvasLayer
	card = CARD.new()
	ui.add_child(card)
	card.call("build")
	var kb: String = "0-9 type  ·  BACKSPACE delete  ·  ENTER submit  ·  ESC close"
	var pad: String = "D-PAD move  ·  A press  ·  X delete  ·  Y known code  ·  B close"
	var touch: String = "Tap the keys. CLOSE or Back leaves the reader."
	var wolf_line: String = "WOLF puts his readout to the panel.\nWOLF: Lockdown missed the local code. It's on my readout."
	var wolf_line_cool: String = "WOLF puts his readout to the panel without a word.\nWOLF: Local code. On my readout."
	await _state("01-idle", "LOCAL", "LOCAL OVERRIDE", "ENTER CODE", "", Color.WHITE, 0, "ON FILE: 7294  ·  WOLF'S READOUT", kb, true, "KNOWN", wolf_line)
	await _state("02-entering", "LOCAL", "ENTER CODE", "2 OF 4", "72", Color.WHITE, 0, "ON FILE: 7294  ·  WOLF'S READOUT", pad, true, "9", wolf_line_cool)
	# Touch layout: 12 px key gaps.
	card.queue_free()
	card = CARD.new()
	ui.add_child(card)
	card.call("build", true)
	await _state("03-denied", "LOCAL", "DENIED  ·  1 OF 3", "CODE CLEARS IN A MOMENT", "7249", Color("#ff6a55"), 1, "ON FILE: 7294  ·  OVERRIDE CARD", touch, true, "", "DENIED. The reader buzzes and clears. Two tries left before it locks out.")
	card.queue_free()
	card = CARD.new()
	ui.add_child(card)
	card.call("build")
	reader.tint = Color("#ff6a55")
	reader.word = "LOCKOUT"
	reader.queue_redraw()
	await _state("04-lockout", "LOCKDOWN", "LOCKOUT  ·  READER RESET", "LOCAL POWER BACK IN 0:08", "", Color("#ff6a55"), 3, "ON FILE: 7294  ·  OVERRIDE CARD", kb, false, "", "Three wrong codes. The reader drops back to LOCKDOWN.")
	reader.tint = Color("#a4f0c4")
	reader.word = "OPEN"
	reader.queue_redraw()
	await _state("05-granted", "OPEN", "ACCESS GRANTED", "BOLT RELEASING", "7294", Color("#a4f0c4"), 0, "ON FILE: 7294  ·  WOLF'S READOUT", kb, false, "", "The bolt is taking the charge.")
	# World-only stills: the reader before the first USE (sentry down, still LOCKDOWN until the
	# winch power reroutes; today's hint and restore line), and after the reroute with the seal intact.
	card.hide()
	reader.tint = Color("#ff6a55")
	reader.word = "LOCKDOWN"
	reader.seal_intact = true
	reader.queue_redraw()
	await _world("06-world-lockdown", "Service junction restored. The sentry is down; pop the exit bolt by the hatch.", "SERVICE JUNCTION\nPOP THE EXIT BOLT", "E: pop the exit bolt.")
	reader.tint = Color("#f3ae4b")
	reader.word = "LOCAL"
	reader.queue_redraw()
	await _world("07-world-local-sealed", "The bolt's reader drops off the lockdown and comes up amber: LOCAL OVERRIDE.", "SERVICE JUNCTION\nENTER THE LOCAL OVERRIDE", "HOLD E: break the override seal on the panel.")
	print("PIN MOCK DONE")
	quit()


func _state(name: String, mode: String, status: String, sub: String, digits: String, tint: Color, tries: int, known: String, footer: String, live: bool, focus: String, line: String) -> void:
	game.set("status_line", line)
	game.call("debug_refresh_ui")
	await _settle(4)
	card.call("show_state", mode, status, sub, digits, tint, tries, known, footer, live, focus)
	(game.get_node("CanvasLayer/TopBar/HUD") as Label).text = "SERVICE JUNCTION\nENTER THE LOCAL OVERRIDE"
	await _settle(2)
	await _shot(name)


func _world(name: String, line: String, card_text: String, hint: String) -> void:
	game.set("status_line", line)
	game.call("debug_refresh_ui")
	await _settle(4)
	(game.get_node("CanvasLayer/TopBar/HUD") as Label).text = card_text
	(game.get_node("CanvasLayer/ContextHint/Text") as Label).text = hint
	await _shot(name)


func _shot(name: String) -> void:
	# Main redraws its HUD each frame; hide the context hint after that, as the card would.
	(game.get_node("CanvasLayer/ContextHint") as CanvasItem).visible = card == null or not card.visible
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("shot ", name, " ", img.get_size())
