extends "res://tests/support/game_suite.gd"
## The opening in the dock bay, played from NEW GAME to first control by pressing CONTINUE after each
## box's reading time, with the staging checks of the codex/opening-dock backup's timing test (rounds 2
## to 4), carried to the whole-piece bay: first control comes 30 to 45 s in (and still under 45 s with a
## player's slack per box); the caption shows before the wake and before the break-out; the charge cuts
## on WOLF's first frame of getting up, not before; WOLF stays planted while he shoulders the leaves and
## the drawn lead leaf follows its planned travel; out of the bay his snout stays 0.3 m clear of the
## hanging lock; no full-screen wash ever shows and the bay's beacon stays on from the tear to the cut;
## the corridor's lockdown light comes on with "Lock down maintenance", not before, inside the view; in
## box 8 the Director is back at the wall before WOLF reaches him and WOLF passes in front of him, and
## the engineer faces WOLF; the Director is through his door, and it is shut, before a walk back could
## see it; and walking back finds the bay empty and quiet.
## Reading time per box: the game's own rule, DialogueBoxes.read_seconds in the language shown (English
## here: the larger of 1.2 s + 0.05 s per character, at most 7 s, and 1.2 s + 0.33 s per word), on the
## box as the Story label shows it. Time is game time (the frames' deltas).

const TARGET_MIN: float = 30.0
const TARGET_MAX: float = 45.0
## Round 1's measured slack between finishing a box and pressing (0.35 to 0.95 s, mean 0.59 s).
const HUMAN_SLACK_PER_BOX: float = 0.59
## The drawn lead leaf may differ from its planned travel by this much (world px).
const LEAF_SLACK: float = 0.5

var game: Node2D
var clock: float = 0.0


func _run() -> void:
	check_name = "Opening timing"
	game = await start_game("opening-timing-test", keep_running)
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	var director: Sprite2D = game.get_node("IntroDirector") as Sprite2D
	var story: Label = game.get_node("CanvasLayer/BottomBar/Story") as Label
	var alarm: ColorRect = game.get_node("CanvasLayer/IntroAlarm") as ColorRect
	var camera: Camera2D = game.get_node("IntroCamera") as Camera2D
	var bay: DockBay = game.get("dock_bay") as DockBay
	game.call("_new_game")
	var last_text: String = ""
	var box_age: float = 0.0
	var box_read: float = 0.0
	var boxes: int = 0
	var shown_at: Dictionary = {}
	var wake_t: float = -1.0
	var rise_t: float = -1.0
	var charge_cut_t: float = -1.0
	var tear_t: float = -1.0
	var lockdown_t: float = -1.0
	var box7_t: float = -1.0
	var lockdown_in_view: bool = false
	var max_wash: float = 0.0
	var beacon_dark_after_tear: bool = false
	var push_start_x: float = NAN
	var wolf_drift: float = 0.0
	var leaf_error: float = 0.0
	var push_age: float = -1.0
	var director_at_wall_first: bool = true
	var passed_in_front: bool = true
	var overlapped: bool = false
	var engineer_faced_wolf: bool = true
	var first_control: float = -1.0
	while clock < 90.0:
		var delta: float = 1.0 / 60.0
		await physics_frame
		clock += delta
		box_age += delta
		if not game.get("intro_active"):
			if human.controlled:
				first_control = clock
				break
			continue
		var text: String = story.text
		if text != last_text:
			last_text = text
			boxes += 1
			box_age = 0.0
			box_read = DialogueBoxes.read_seconds(text.strip_edges())
			shown_at[int(game.get("intro_step"))] = shown_at.get(int(game.get("intro_step")), clock)
			if text.begins_with("Lock down maintenance"):
				box7_t = clock
		elif box_age >= box_read:
			await tap(&"interact")
			box_age = -1000.0
		max_wash = maxf(max_wash, alarm.color.a)
		if wake_t < 0.0 and bay.charge_color != DockBay.AMBER:
			wake_t = clock
		if rise_t < 0.0 and wolf.body_sprite.texture == DockBay.WOLF_RISE:
			rise_t = clock
		if charge_cut_t < 0.0 and bay.charge_k == 0.0:
			charge_cut_t = clock
		if tear_t < 0.0 and bay.lock_torn:
			tear_t = clock
			push_start_x = wolf.position.x
			push_age = 0.0
		elif push_age >= 0.0 and push_age < DockBay.leaf_seconds() - 2.0 / 60.0:
			push_age += delta
			wolf_drift = maxf(wolf_drift, absf(wolf.position.x - push_start_x))
			leaf_error = maxf(leaf_error, absf((bay.leaves[3] as Sprite2D).position.x - DockBay.DOCK_X - DockBay.leaf_x(3, bay.lead_travel)))
		if tear_t >= 0.0 and not bay.beacon_on:
			beacon_dark_after_tear = true
		if lockdown_t < 0.0 and bay.lockdown_on:
			lockdown_t = clock
			var view: Rect2 = Rect2(camera.get_screen_center_position() - Vector2(480.0, 270.0) / camera.zoom, Vector2(960.0, 540.0) / camera.zoom)
			lockdown_in_view = view.has_point(DockBay.LOCKDOWN_AT)
		# (Until the last press: under the fade into play the Director leaves while WOLF may still be walking.)
		var before_fade: bool = int(game.get("intro_step")) < Main.INTRO_LINES.size()
		if before_fade and director.visible and absf(wolf.position.x - director.position.x) < M0Actor.WOLF_SNOUT + 10.0 and wolf.z_index >= Main.ACTOR_Z:
			overlapped = true
			director_at_wall_first = director_at_wall_first and director.position.is_equal_approx(Opening.DIRECTOR_LAST)
			passed_in_front = passed_in_front and wolf.z_index > director.z_index
		if human.visible and human.position.x == Opening.ENGINEER_WATCH_X:
			engineer_faced_wolf = engineer_faced_wolf and human.body_sprite.flip_h
	var reading: float = first_control
	_expect(first_control >= TARGET_MIN and first_control <= TARGET_MAX, "first control %.1f s in (30 to 45 s)" % first_control)
	_expect(first_control + HUMAN_SLACK_PER_BOX * boxes <= TARGET_MAX + 0.5, "with a player's slack per box it is still about 45 s or less (%.1f s, %d boxes)" % [reading + HUMAN_SLACK_PER_BOX * boxes, boxes])
	_expect(shown_at.has(2) and wake_t > float(shown_at[2]) + 0.5, "the wake's caption shows first, then the wake (%.2f s after it)" % (wake_t - float(shown_at.get(2, 0.0))))
	_expect(shown_at.has(3) and rise_t > float(shown_at[3]) + 0.5, "the break-out's caption shows first, then WOLF gets up")
	_expect(rise_t > 0.0 and absf(charge_cut_t - rise_t) < 0.02, "the charge cuts on WOLF's first frame of getting up, not before (%.2f vs %.2f)" % [charge_cut_t, rise_t])
	_expect(wolf_drift < 0.5 and leaf_error <= LEAF_SLACK, "WOLF stays planted while the leaves move, and the drawn lead follows its travel (drift %.2f, leaf %.2f px)" % [wolf_drift, leaf_error])
	_expect(DockBay.OUT_X + M0Actor.WOLF_SNOUT <= DockBay.TORN_AT.x - DockBay.OUT_GAP + 0.01, "out of the bay his snout stands 0.3 m clear of the hanging lock")
	_expect(max_wash == 0.0, "no full-screen wash ever shows")
	_expect(tear_t > 0.0 and not beacon_dark_after_tear, "the bay's beacon stays on from the tear to the cut")
	_expect(box7_t > 0.0 and absf(lockdown_t - box7_t) < 0.1 and lockdown_in_view, "the corridor's lockdown light comes on with the order, not before, in view (order %.2f, light %.2f, in view %s)" % [box7_t, lockdown_t, lockdown_in_view])
	_expect(overlapped and director_at_wall_first and passed_in_front, "in box 8 the Director is back at the wall before WOLF reaches him, and WOLF passes in front of him (%s %s %s)" % [overlapped, director_at_wall_first, passed_in_front])
	_expect(engineer_faced_wolf, "the engineer watches from the doorway facing the bay")
	# The Director leaves under the fade; he is through his door, and it is shut, within a few seconds.
	_expect(await wait_until(func() -> bool: return not director.visible and bay.exit_open == 0.0, 360), "the Director is through his door and it is shut")
	# The walk back finds the bay empty and quiet.
	_expect(await walk_to(human, -250.0), "the engineer walks back into the dock bay")
	_expect(bay.battery.percent == PropScreen.BATTERY_IDLE and bay.charge_k == DockBay.STANDBY_K and not bay.beacon_on and not bay.lock_lens.visible and not director.visible, "the bay is empty and quiet: the pad on amber standby, the screen's outline, the beacon and the lock's lens dark, nobody there")
	await end_game(game)
	finish("Opening timing checks passed (first control %.1f s, %d boxes)" % [first_control, boxes])
