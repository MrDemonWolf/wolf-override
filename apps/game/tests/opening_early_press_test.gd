extends SceneTree
## P0-13 grey box (layout L1, round 4; review-human-3 should-fix 1): a fast reader presses CONTINUE early,
## and no beat snaps to its end. Box 3 is pressed 0.4 s in (before WOLF starts to wake) and box 4 1.0 s
## in (before the lock tears); boxes 5-7 are pressed 0.3 s in. Every frame, WOLF's tint, his position, the
## leaves and the engineer move no further than their own motion allows (no jump), the wake and the whole
## break-out still play out in order, box 8's step-back and walk wait until the break-out has finished,
## and the Director never turns. Game time is the sum of the frame deltas.
## Scratch only (opening-dock/game), not in the repository.

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SPEAKERS: Array[String] = ["DIRECTOR", "WOLF", "ROWAN"]
## When each box is pressed, in seconds after it shows (-1: at its reading time).
const PRESS_AT: Array[float] = [-1.0, -1.0, 0.4, 1.0, 0.3, 0.3, 0.3, -1.0]

var game: Node2D
var bay: Object
var failures: int = 0
var clock: float = -1.0
var phase: String = "title"
var title_wait: float = 0.0
var box_step: int = -1
var box_age: float = 0.0
var box_read: float = 0.0
var release_next: bool = false
var pressed_this_box: bool = false
var last: Dictionary = {}
var max_tint_jump: float = 0.0
var max_wolf_jump: float = 0.0
var max_leaf_jump: float = 0.0
var max_human_jump: float = 0.0
var wake_done_t: float = -1.0
var tear_t: float = -1.0
var leaves_stop_t: float = -1.0
var step_down_t: float = -1.0
var director_moves_t: float = -1.0
var box8_shown_t: float = -1.0
var director_flipped: bool = false
var close_wait: float = 0.0
var save_path: String = ""


func _initialize() -> void:
	save_path = "user://opening-early-press-test-%s.json" % OS.get_process_id()
	game = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", save_path)
	game.set("settings_path", "%s-settings.cfg" % save_path)
	game.set("auto_pause_on_focus_loss", false)
	root.add_child(game)


static func read_seconds(text: String) -> float:
	var plain: PackedStringArray = []
	for line: String in text.split("\n"):
		var colon: int = line.find(":")
		if colon > 0 and line.substr(0, colon) in SPEAKERS:
			line = line.substr(colon + 1).strip_edges()
		plain.append(line)
	var joined: String = " ".join(plain)
	return maxf(minf(1.2 + 0.05 * joined.length(), 7.0), 1.2 + 0.33 * joined.split(" ", false).size())


func _expect(ok: bool, what: String) -> void:
	if ok:
		print("PASS ", what)
	else:
		failures += 1
		push_error("FAIL " + what)
		print("FAIL ", what)


func _watch(delta: float) -> void:
	var wolf: Node2D = game.get_node("Wolf") as Node2D
	var human: Node2D = game.get_node("Human") as Node2D
	var director: Sprite2D = game.get_node("IntroDirector") as Sprite2D
	var wolf_sprite: Sprite2D = wolf.get_node("BodySprite") as Sprite2D
	if bay == null:
		bay = game.get("greybox")
	var now: Dictionary = {
		"tint": wolf_sprite.modulate.r, "wolf": wolf.position.x, "lead": float(bay.get("lead_x")),
		"human": human.position.x if human.visible else 999.0, "director": director.position.x,
	}
	# Rates over windows of at least 0.1 s of game time: headless frames are far shorter than a physics
	# step, so a walk advances in steps between them.
	now["t"] = clock
	if last.is_empty():
		last = now
	elif clock - float(last["t"]) >= 0.25:
		var span: float = clock - float(last["t"])
		# The wake eases 0.21 -> 1.0 over 0.8 s (sine); WOLF's quickest move is the latch edge (about 107
		# px/s); the leaves peak at 85 px/s; the engineer walks at 56 px/s.
		max_tint_jump = maxf(max_tint_jump, absf(now["tint"] - last["tint"]) / span)
		max_wolf_jump = maxf(max_wolf_jump, absf(now["wolf"] - last["wolf"]) / span)
		if now["human"] < 900.0 and last["human"] < 900.0:
			max_human_jump = maxf(max_human_jump, absf(now["human"] - last["human"]) / span)
		last = now
	if wake_done_t < 0.0 and wolf_sprite.modulate.is_equal_approx(Color.WHITE):
		wake_done_t = clock
	if tear_t < 0.0 and bool(bay.get("lock_torn")):
		tear_t = clock
	# The leaves follow their planned curve from the tear (main's leaf_travel), within a frame's travel:
	# a press that snapped them open would leave them far ahead of it.
	if tear_t >= 0.0 and leaves_stop_t < 0.0:
		var planned: float = 153.0 - float(game.get_script().call("leaf_travel", clock - tear_t))
		max_leaf_jump = maxf(max_leaf_jump, absf(float(bay.get("lead_x")) - planned) - 85.0 * delta)
	if leaves_stop_t < 0.0 and absf(float(bay.get("lead_x")) - 33.0) < 0.01:
		leaves_stop_t = clock
	if step_down_t < 0.0 and wolf.z_index >= 5:
		step_down_t = clock
	# He stands at y 410, steps 2 px toward the camera at the tear, and up to the wall (406.5) in box 8.
	if box8_shown_t >= 0.0 and director_moves_t < 0.0 and director.position.y < 409.5:
		director_moves_t = clock
	director_flipped = director_flipped or director.flip_h


func _process(delta: float) -> bool:
	if release_next:
		Input.action_release(&"interact")
		release_next = false
	if clock >= 0.0:
		clock += delta
	match phase:
		"closing":
			close_wait += delta
			if close_wait >= 0.1 and is_instance_valid(game) and not game.is_queued_for_deletion():
				game.queue_free()
			if close_wait >= 0.2:
				quit(1 if failures > 0 else 0)
				return true
		"title":
			title_wait += delta
			if title_wait >= 0.5:
				(game.get_node("CanvasLayer/TitleScreen/NewGameButton") as Button).pressed.emit()
				clock = 0.0
				phase = "intro"
		"intro":
			if not game.get("intro_active"):
				phase = "control"
				return false
			var step: int = int(game.get("intro_step"))
			# Up to the last press: the cut's fade and the reset into the corridor are not part of it.
			if step < PRESS_AT.size():
				_watch(delta)
			if step != box_step and step < PRESS_AT.size():
				box_step = step
				box_age = 0.0
				pressed_this_box = false
				box_read = read_seconds(str(game.get("status_line")))
				if step == 7:
					box8_shown_t = clock
			box_age += delta
			var at: float = PRESS_AT[box_step] if PRESS_AT[box_step] >= 0.0 else box_read
			if box_age >= at and not pressed_this_box and not release_next:
				pressed_this_box = true
				Input.action_press(&"interact")
				release_next = true
			if clock > 120.0:
				_expect(false, "the opening ends within 120 s")
				return _finish()
		"control":
			var human: Node2D = game.get_node("Human") as Node2D
			if (game.get_node("CanvasLayer/IntroFade") as ColorRect).color.a < 0.01:
				print("RESULT early_press max_tint_rate=%.2f/s max_wolf=%.1f px/s leaf_gap=%.2f px max_engineer=%.1f px/s wake_done=%.3f tear=%.3f leaves_stop=%.3f step_down=%.3f box8_shown=%.3f director_moves=%.3f control=%.3f" % [max_tint_jump, max_wolf_jump, max_leaf_jump, max_human_jump, wake_done_t, tear_t, leaves_stop_t, step_down_t, box8_shown_t, director_moves_t, clock])
				_expect(max_tint_jump <= 1.6, "WOLF's wake eases in, never pops (fastest %.2f per s)" % max_tint_jump)
				_expect(max_wolf_jump <= 130.0, "WOLF never jumps (fastest %.1f px/s)" % max_wolf_jump)
				_expect(max_leaf_jump <= 0.5, "the leaves never jump open: they follow their curve from the tear (largest gap %.2f px beyond a frame)" % max_leaf_jump)
				_expect(max_human_jump <= 62.0, "the engineer never jumps (fastest %.1f px/s over 0.25 s)" % max_human_jump)
				_expect(wake_done_t >= 0.0 and tear_t > wake_done_t, "the wake plays out before the break-out starts")
				_expect(leaves_stop_t > tear_t and step_down_t >= leaves_stop_t, "the break-out plays in order: tear, leaves to the stop, step-down")
				_expect(director_moves_t >= step_down_t and director_moves_t > box8_shown_t, "box 8's step-back waits until the break-out has finished")
				_expect(not director_flipped, "the Director never turns")
				_expect(absf(human.position.x - 160.0) < 0.5 and absf((game.get_node("Wolf") as Node2D).position.x - 72.0) < 0.5, "control still starts with the engineer at 160 and WOLF at 72")
				return _finish()
	return false


func _finish() -> bool:
	if failures == 0:
		print("opening_early_press_test: all passed")
	else:
		print("opening_early_press_test: %d failed" % failures)
	Input.action_release(&"interact")
	(game.get("sfx_bank") as Node).call("stop_all")
	for suffix: String in ["", "-settings.cfg"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	phase = "closing"
	close_wait = 0.0
	return false
