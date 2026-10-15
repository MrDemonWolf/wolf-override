extends SceneTree
## P0-13 grey box (layout L1, round 4): NEW GAME to the first move input, pressing CONTINUE after each
## box's reading time, plus the staging checks of opening-design/DESIGN.md section 6.1 and the fixes of
## rounds 2 to 4 (GREYBOX.md, GREYBOX-R4.md): the caption shows before the wake and before the break-out,
## the connector parts as WOLF first moves, WOLF stays planted while he sweeps the leading stile, the
## leaves' speed is continuous except at the one inelastic catch (a 2/3 drop), his tail never meets the
## stacked leaves, no full-screen wash ever shows and the beacon stays on from the tear to the cut, the
## corridor's lockdown beacon switches on with "Lock down maintenance" inside the opening's view, in box 8
## the Director steps back to the wall before WOLF walks and WOLF passes in front of him (never into him),
## his tail clears the hanging lock, the engineer steps toward him, the Director leaves by his door before the walk back can see it, the first controllable frame's
## prompt stands clear of the display, and the walk back into the dock room is a continuous pan into an
## empty, quiet room with no corridor card.
## Reading time per box: the larger of 1.2 s + 0.05 s per character (at most 7 s) and
## 1.2 s + 0.33 s per word, speaker tags and row breaks not counted.
## Time is game time: the sum of the frame deltas the tree hands this script.
## Scratch only (opening-design/game), not in the repository.

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const TARGET_MIN: float = 30.0
const TARGET_MAX: float = 45.0
## Round 1's measured slack between finishing a box and pressing (0.35-0.95 s, mean 0.59 s).
const HUMAN_SLACK_PER_BOX: float = 0.59
const SPEAKERS: Array[String] = ["DIRECTOR", "WOLF", "ROWAN"]
const WOLF_HALF: float = 57.65
## WOLF's drawn tail tip behind his origin (sprite measure, round 1).
const WOLF_TAIL: float = 56.2
const DIRECTOR_HALF: float = 10.25
const ENGINEER_HALF: float = 13.65
const NEAR_COLUMN: Vector2 = Vector2(-10.0, 8.0)
const DOCKED_X: float = -397.0
const LATCH_X: float = -376.5
const WATCH_X: float = -34.0
const MEET_X: float = -44.0
const DOORWAY_X: float = -140.0
## Feet below each origin (main's L1_*_FEET) and WOLF's stepped-down sprite y (main's WOLF_SPRITE_REST + 8).
const DIRECTOR_FEET: float = 34.8
const WOLF_FEET: float = 22.3
const WOLF_SPRITE_DOWN_Y: float = -7.0
const ROOM_VIEW_CENTRE: float = -318.0
## The bay's front (its sill line) and the torn lock's span on the pilaster (GreyboxBay).
const BAY_FACE_Y: float = 440.0
const LOCK_SPAN: Vector2 = Vector2(-319.0, -303.0)
## The Director's exit door's frame (GreyboxBay.EXIT_FRAME) and his last mark.
const EXIT_FRAME: Vector2 = Vector2(-283.0, -241.0)
const DIRECTOR_LAST: Vector2 = Vector2(-222.0, 406.5)
## The corridor's lockdown beacon (GreyboxBay.LOCKDOWN_BEACON).
const LOCKDOWN_BEACON: Vector2 = Vector2(74.0, 282.0)

var game: Node2D
var bay: Object
var failures: int = 0
var clock: float = -1.0
var phase: String = "title"
var box_step: int = -1
var box_age: float = 0.0
var box_read: float = 0.0
var boxes: Array[Dictionary] = []
var reading_sum: float = 0.0
var release_next: bool = false
var title_wait: float = 0.0
var stop_at: float = -1.0
var director_max_x: float = -10000.0
var director_flipped: bool = false
var engineer_watch_t: float = -1.0
var engineer_seen_box1: bool = false
var wolf_director_overlap_s: float = 0.0
var wolf_in_front_of_director_s: float = 0.0
var wolf_engineer_overlap_s: float = 0.0
var x0: float = 0.0
# Box 4.
var box4_shown: float = -1.0
var wolf_first_move_t: float = -1.0
var connector_release_t: float = -1.0
var lamp_off_t: float = -1.0
var lamp_off_while_attached: bool = false
var tear_t: float = -1.0
## The length of the frame the tear was first seen in: the tear itself fell somewhere inside it.
var tear_frame: float = 0.0
var leaves_stop_t: float = -1.0
## Largest gap between the leaf's drawn x and the planned curve (153 - leaf_travel(t since the tear)).
var max_lead_error: float = 0.0
var wolf_drift_while_sweeping: float = 0.0
var tail_in_stack_s: float = 0.0
var engineer_turned_making_way: bool = false
# Round 3.
var box3_shown: float = -1.0
## The length of the frame box 3 was first seen in (the press fell somewhere inside it).
var box3_frame: float = 0.0
## Round 4: the longest frame inside the current camera window, and how many windows a hitch spoiled.
var window_longest: float = 0.0
var hitched_windows: int = 0
var wake_start_t: float = -1.0
var max_wash: float = 0.0
var beacon_off_after_tear_s: float = 0.0
var wolf_flipped_box8: bool = false
var shadows_while_passing: bool = true
var corridor_card_in_room: bool = false
# Round 4.
var lockdown_on_before_box7: bool = false
var lockdown_on_t: float = -1.0
var box7_shown: float = -1.0
var lockdown_in_view: bool = false
var director_right_of_235_before_box8: bool = false
var director_at_wall_before_overlap: bool = true
var overlap_seen: bool = false
var wolf_behind_director_s: float = 0.0
## Smallest depth gap (WOLF's feet below the Director's) while their bodies overlap on screen.
var min_front_gap: float = 1000.0
## Smallest distance of WOLF's feet in front of the bay's face while his tail is over the hanging lock.
var min_tail_clear: float = 1000.0
var lit_edge_box2: float = -1.0
var wolf_edge_in_bay: float = 0.0
var exit_gone_t: float = -1.0
var view_reaches_door_t: float = -1.0
var director_seen_in_walk_back: bool = false
var door_open_when_seen: float = -1.0
# Walk back.
## The camera's x every 0.1 s of the walk back, for its largest speed.
var cam_samples: Array[Vector2] = []
var max_cam_speed: float = 0.0
var settle_until: float = -1.0
var close_wait: float = 0.0
var save_path: String = ""


func _initialize() -> void:
	var path: String = "user://opening-timing-test-%s.json" % OS.get_process_id()
	save_path = path
	game = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	game.set("settings_path", "%s-settings.cfg" % path)
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


func _x(node_name: String) -> float:
	return (game.get_node(node_name) as Node2D).position.x


func _cam_x() -> float:
	return (game.get_node("IntroCamera") as Camera2D).get_screen_center_position().x


func _watch_staging(delta: float) -> void:
	var director: Sprite2D = game.get_node("IntroDirector") as Sprite2D
	var human: Node2D = game.get_node("Human") as Node2D
	var wolf: Node2D = game.get_node("Wolf") as Node2D
	if bay == null:
		bay = game.get("greybox")
	if director.visible:
		director_max_x = maxf(director_max_x, director.position.x)
		director_flipped = director_flipped or director.flip_h
		if int(game.get("intro_step")) < 7 and director.position.x > -235.0 + 0.01:
			director_right_of_235_before_box8 = true
	# Round 4: the corridor's lockdown beacon: off until box 7's line, then on, and inside the opening's view.
	# The game's own step (the press lands a frame before this script's box count moves on).
	var game_step: int = int(game.get("intro_step"))
	if game_step == 6 and box7_shown < 0.0:
		box7_shown = clock
	if bool(bay.get("lockdown_on")):
		if game_step < 6:
			lockdown_on_before_box7 = true
		elif lockdown_on_t < 0.0:
			lockdown_on_t = clock
			var cam: Camera2D = game.get_node("IntroCamera") as Camera2D
			var half: Vector2 = Vector2(960.0, 540.0) / cam.zoom * 0.5
			lockdown_in_view = Rect2(cam.get_screen_center_position() - half, half * 2.0).grow(-8.0).has_point(LOCKDOWN_BEACON)
	# Round 4: the corridor fitting's lit edge on the engineer in the doorway; none on WOLF in the bay.
	var human_edge: Sprite2D = human.get_node_or_null("BodySprite/LitEdge") as Sprite2D
	if box_step == 1 and box_age > 3.4 and lit_edge_box2 < 0.0 and human_edge != null:
		lit_edge_box2 = float(human_edge.get_meta("strength", 0.0)) if human_edge.visible else 0.0
	var wolf_edge: Sprite2D = wolf.get_node_or_null("BodySprite/LitEdge") as Sprite2D
	if box_step <= 3 and wolf_edge != null and wolf_edge.visible:
		wolf_edge_in_bay = maxf(wolf_edge_in_bay, float(wolf_edge.get_meta("strength", 0.0)))
	if box_step == 0 and human.visible:
		engineer_seen_box1 = true
	if box_step == 1 and engineer_watch_t < 0.0 and absf(human.position.x - WATCH_X) <= 0.5:
		engineer_watch_t = box_age
	var wx: float = wolf.position.x
	if director.visible and absf(wx - director.position.x) < WOLF_HALF + DIRECTOR_HALF:
		wolf_director_overlap_s += delta
		if wolf.z_index >= director.z_index:
			wolf_in_front_of_director_s += delta
		else:
			wolf_behind_director_s += delta
	if human.visible and absf(wx - human.position.x) < WOLF_HALF + ENGINEER_HALF:
		wolf_engineer_overlap_s += delta
	if box_step == 7 and not (human.get_node("BodySprite") as Sprite2D).flip_h:
		engineer_turned_making_way = true
	# Round 3: no full-screen wash at any point of the opening; the beacon on from the tear to the cut.
	max_wash = maxf(max_wash, (game.get_node("CanvasLayer/IntroAlarm") as ColorRect).color.a)
	if tear_t >= 0.0 and not bool(bay.get("beacon_on")):
		beacon_off_after_tear_s += delta
	if box_step == 2:
		if box3_shown < 0.0:
			box3_shown = clock
			box3_frame = delta
		if wake_start_t < 0.0 and float(bay.get("wake")) > 0.0:
			wake_start_t = clock
	var wolf_sprite: Sprite2D = wolf.get_node("BodySprite") as Sprite2D
	var wolf_feet: float = wolf.position.y + wolf_sprite.position.y - WOLF_SPRITE_DOWN_Y + WOLF_FEET
	if box_step == 7:
		wolf_flipped_box8 = wolf_flipped_box8 or wolf_sprite.flip_h
		if director.visible and absf(wx - director.position.x) < WOLF_HALF + DIRECTOR_HALF:
			if not overlap_seen:
				overlap_seen = true
				director_at_wall_before_overlap = director.position.distance_to(DIRECTOR_LAST) < 1.0
			min_front_gap = minf(min_front_gap, wolf_feet - (director.position.y + DIRECTOR_FEET))
			if (bay.get("shadow_casters") as Array).size() < 3:
				shadows_while_passing = false
	# Round 4 (review-real-3 S4): while WOLF is out of the bay and his tail is over the hanging lock, his
	# feet stand clear of the bay's face.
	if wolf.z_index >= 5 and wx - WOLF_TAIL < LOCK_SPAN.y and wx - 16.0 > LOCK_SPAN.x:
		min_tail_clear = minf(min_tail_clear, wolf_feet - BAY_FACE_Y)
	# Box 4: the connector, the tear, the sweep and the coast.
	if box_step == 3:
		if box4_shown < 0.0:
			box4_shown = clock
		if wolf_first_move_t < 0.0 and absf(wx - DOCKED_X) > 0.01:
			wolf_first_move_t = clock
		var attached: bool = bool(bay.get("umbilical_attached"))
		if connector_release_t < 0.0 and not attached:
			connector_release_t = clock
		if int(bay.get("dock_lamp")) == 2:
			if lamp_off_t < 0.0:
				lamp_off_t = clock
			if attached:
				lamp_off_while_attached = true
		if tear_t < 0.0 and bool(bay.get("lock_torn")):
			tear_t = clock
			tear_frame = delta
		var lead: float = float(bay.get("lead_x"))
		if tear_t >= 0.0 and leaves_stop_t < 0.0:
			var planned: float = 153.0 - float(game.get_script().call("leaf_travel", clock - tear_t))
			# One frame of slack either way: the tween and this script read different ends of a frame, and
			# the tear fell somewhere inside the frame it was first seen in (round 4: under load that frame
			# can be long).
			max_lead_error = maxf(max_lead_error, maxf(absf(lead - planned) - 85.0 * (delta + tear_frame), 0.0))
		if tear_t >= 0.0 and leaves_stop_t < 0.0:
			wolf_drift_while_sweeping = maxf(wolf_drift_while_sweeping, absf(wx - LATCH_X))
			if absf(lead - 33.0) < 0.01:
				leaves_stop_t = clock
	# Whenever WOLF is drawn in front of the leaves, his tail is clear of the open stack.
	if wolf.z_index >= 5 and wx - WOLF_TAIL < float(bay.get_script().get_script_constant_map()["BAY_O"]) + 33.0 + 44.0 - 0.01:
		tail_in_stack_s += delta


func _process(delta: float) -> bool:
	if release_next:
		Input.action_release(&"interact")
		release_next = false
	if clock >= 0.0:
		clock += delta
	match phase:
		"closing":
			# Let the mixer release the stopped sounds, free the game, then quit (no leaked objects).
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
			_watch_staging(delta)
			var step: int = int(game.get("intro_step"))
			var lines: Array = game.get_script().get_script_constant_map()["INTRO_LINES"] as Array
			if step != box_step and step < lines.size():
				if box_step >= 0:
					_end_of_box(box_step)
				box_step = step
				box_age = 0.0
				box_read = read_seconds(str(game.get("status_line")))
				boxes.append({"box": step + 1, "shown": clock, "read": box_read})
				reading_sum += box_read
			box_age += delta
			if box_age >= box_read and not release_next and box_age < 1000.0:
				boxes[-1]["pressed"] = clock
				if box_step == lines.size() - 1:
					_end_of_box(box_step)
				Input.action_press(&"interact")
				release_next = true
				box_age = 2000.0
			if clock > 120.0:
				_expect(false, "the opening ends within 120 s")
				return _finish()
		"control":
			var human: CharacterBody2D = game.get_node("Human") as CharacterBody2D
			var fade: ColorRect = game.get_node("CanvasLayer/IntroFade") as ColorRect
			if human.visible and bool(human.get("controlled")) and fade.color.a < 0.01:
				_first_control_checks(human)
				# The first move input: back toward the doorway, to check the walk back.
				Input.action_press(&"move_left")
				phase = "moving"
				stop_at = clock + 0.5
		"moving":
			if clock >= stop_at:
				var moved: float = x0 - _x("Human")
				_expect(moved > 1.0, "the first move input moves the engineer (%.1f px in 0.5 s)" % moved)
				phase = "walk_back"
				cam_samples = [Vector2(clock, _cam_x())]
		"walk_back":
			_sample_camera(delta)
			_card_check()
			_exit_check()
			if _x("Human") <= -250.0:
				Input.action_release(&"move_left")
				phase = "settle"
				settle_until = clock + 1.5
		"settle":
			_sample_camera(delta)
			_card_check()
			_exit_check()
			if clock >= settle_until:
				_room_checks()
				Input.action_press(&"move_right")
				phase = "return"
				stop_at = clock + 6.0
		"return":
			var hx: float = _x("Human")
			if hx >= 200.0 or clock >= stop_at:
				Input.action_release(&"move_right")
				_expect(hx >= 200.0, "walking right takes the engineer back past the display (%.1f)" % hx)
				phase = "return_settle"
				settle_until = clock + 1.0
		"return_settle":
			if clock >= settle_until:
				var want: float = clampf(_x("Human"), 315.6, 604.4)
				_expect(absf(_cam_x() - want) < 40.0, "the corridor framing returns (camera %.1f, target %.1f)" % [_cam_x(), want])
				return _finish()
	return false


## Round 4 (review-real-3 M2): the Director's exit, from the first control on. He must be through his door
## (hidden) before the walk back's view first reaches the door's frame.
func _exit_check() -> void:
	var director: CanvasItem = game.get_node("IntroDirector") as CanvasItem
	if exit_gone_t < 0.0 and not director.visible:
		exit_gone_t = clock
	var cam: Camera2D = game.get_node("IntroCamera") as Camera2D
	var left: float = cam.get_screen_center_position().x - 960.0 / cam.zoom.x * 0.5
	if view_reaches_door_t < 0.0 and left <= EXIT_FRAME.y:
		view_reaches_door_t = clock
		door_open_when_seen = float(bay.get("exit_open"))
		director_seen_in_walk_back = director.visible


## Round 3: in the dock room the corridor's area card never shows.
func _card_check() -> void:
	var card: CanvasItem = game.get("top_card") as CanvasItem
	var hud: Label = game.get("hud") as Label
	if _x("Human") < NEAR_COLUMN.x and card.visible and hud.text.contains("LOCKDOWN"):
		corridor_card_in_room = true


## Round 4: a window with a frame longer than 1/20 s is a hitch of the machine running the check (the
## camera's smoothing then catches up in one step); it is counted and left out, not judged.
func _sample_camera(delta: float) -> void:
	window_longest = maxf(window_longest, delta)
	if clock - cam_samples[-1].x >= 0.1:
		var now: Vector2 = Vector2(clock, _cam_x())
		if window_longest <= 0.05:
			max_cam_speed = maxf(max_cam_speed, absf(now.y - cam_samples[-1].y) / (now.x - cam_samples[-1].x))
		else:
			hitched_windows += 1
		window_longest = 0.0
		cam_samples.append(now)


## The planned leaf curve itself (round 3): its speed between two samples 1/600 s apart never changes by
## more than its largest acceleration allows, except at the coast's one inelastic catch, where it drops
## to 2/3; the first catch falls inside WOLF's push.
func _leaf_curve_check() -> void:
	var main_script: Script = game.get_script()
	var plan: Dictionary = main_script.call("leaf_plan")
	var catch_t: float = float(main_script.call("leaf_time_at", float(plan["catch_2_px"])))
	var first_catch_t: float = float(main_script.call("leaf_time_at", float(plan["catch_1_px"])))
	var dt: float = 1.0 / 600.0
	var last_v: float = 0.0
	var max_dv: float = 0.0
	var max_v: float = 0.0
	var v_before: float = 0.0
	var v_after: float = -1.0
	var t: float = 0.0
	var s_prev: float = 0.0
	while t < 3.5:
		t += dt
		var s_now: float = float(main_script.call("leaf_travel", t))
		var v: float = (s_now - s_prev) / dt
		if t < catch_t - dt:
			v_before = v
		elif t > catch_t + dt and v_after < 0.0:
			v_after = v
		if t < catch_t - dt or t > catch_t + 2.0 * dt:
			max_dv = maxf(max_dv, absf(v - last_v))
		max_v = maxf(max_v, v)
		last_v = v
		s_prev = s_now
	var ratio: float = v_after / maxf(v_before, 0.001)
	print("RESULT leaf_curve max_v=%.2f max_dv_per_1/600s=%.3f end=%.2f catch1_t=%.3f sweep_s=%.3f catch2_t=%.3f v %.1f -> %.1f (x%.3f) a=%.2f stop_t=%.3f" % [max_v, max_dv, s_prev, first_catch_t, float(plan["sweep_s"]), catch_t, v_before, v_after, ratio, float(plan["a"]), float(plan["sweep_s"]) + float(plan["coast_b_s"]) + float(plan["coast_c_s"])])
	_expect(max_v <= 85.01 and max_dv <= 0.5 and absf(s_prev - 120.0) < 0.01, "the leaves' planned speed never jumps outside the catch (peak %.1f px/s, largest change %.3f px/s per 1/600 s)" % [max_v, max_dv])
	_expect(absf(ratio - 2.0 / 3.0) < 0.02, "at the coast's catch the speed drops to 2/3 (x%.3f)" % ratio)
	_expect(first_catch_t < float(plan["sweep_s"]), "the first catch falls inside WOLF's push (%.3f s < %.3f s)" % [first_catch_t, float(plan["sweep_s"])])


func _first_control_checks(human: CharacterBody2D) -> void:
	var t: float = clock
	x0 = human.position.x
	var cam: Camera2D = game.get_node("IntroCamera") as Camera2D
	var half: Vector2 = Vector2(960.0, 540.0) / cam.zoom * 0.5
	var view_left: float = cam.get_screen_center_position().x - half.x
	var lines: String = ""
	for b: Dictionary in boxes:
		lines += "  box %d shown %.2f read %.2f pressed %.2f\n" % [b["box"], b["shown"], b["read"], b.get("pressed", -1.0)]
	print(lines)
	print("RESULT first_move_input=%.3f boxes=%d reading=%.2f with_slack=%.2f" % [t, boxes.size(), reading_sum, t + boxes.size() * HUMAN_SLACK_PER_BOX])
	_expect(boxes.size() == 8, "8 boxes (%d)" % boxes.size())
	_expect(t >= TARGET_MIN and t <= TARGET_MAX, "first move input in %.0f-%.0f s on the reading formula (%.2f s)" % [TARGET_MIN, TARGET_MAX, t])
	_expect(t + boxes.size() * HUMAN_SLACK_PER_BOX <= TARGET_MAX, "still within %.0f s with the per-box slack (%.2f s)" % [TARGET_MAX, t + boxes.size() * HUMAN_SLACK_PER_BOX])
	_expect(absf(human.position.x - 160.0) < 0.5 and absf(_x("Wolf") - 72.0) < 0.5, "control starts with the engineer at 160 and WOLF at 72 (%.1f, %.1f)" % [human.position.x, _x("Wolf")])
	var director_node: Node2D = game.get_node("IntroDirector") as Node2D
	_expect(not director_node.visible or director_node.position.x < view_left - 20.0, "the Director is out of the first controllable view (leaving by his door, x %.1f)" % director_node.position.x)
	_expect(absf(view_left - -40.0) < 1.0, "first-control view starts at x -40 (%.1f)" % view_left)
	# Round 4: the P0-8 stand-in (name card only, the walk-and-talk held back) is withdrawn: first control
	# shows main's trust line, as on main, until the P0 text step decides the first frame.
	_expect(str(game.get("status_line")).ends_with("keeps WOLF's systems running."), "first control shows main's trust line, as on main (%s)" % str(game.get("status_line")))
	_expect(not engineer_seen_box1, "box 1: the engineer is not there")
	_expect(engineer_watch_t >= 0.0 and engineer_watch_t <= float(boxes[1]["read"]), "box 2: the engineer lands on -34 within its reading time (%.2f s of %.2f)" % [engineer_watch_t, boxes[1]["read"]])
	_expect(not director_right_of_235_before_box8 and director_max_x <= DIRECTOR_LAST.x + 0.01 and not director_flipped, "the Director stays left of -235 until box 8, steps back no further than %.0f, and never turns (max %.2f)" % [DIRECTOR_LAST.x, director_max_x])
	print("RESULT wolf_director_overlap_s=%.2f wolf_in_front_of_director_s=%.2f wolf_engineer_overlap_s=%.2f" % [wolf_director_overlap_s, wolf_in_front_of_director_s, wolf_engineer_overlap_s])
	_expect(wolf_engineer_overlap_s == 0.0, "WOLF's body never overlaps the engineer's in the opening")
	print("RESULT round4 wolf_behind_director_s=%.2f min_front_gap=%.2f director_at_wall_first=%s min_tail_clear=%.2f lockdown_on=%.3f (box 7 at %.3f) in_view=%s lit_edge_box2=%.2f wolf_edge_in_bay=%.2f" % [wolf_behind_director_s, min_front_gap, director_at_wall_before_overlap, min_tail_clear, lockdown_on_t, box7_shown, lockdown_in_view, lit_edge_box2, wolf_edge_in_bay])
	_expect(wolf_behind_director_s == 0.0, "box 8: WOLF is never drawn behind the Director while they overlap (he passes in front)")
	_expect(overlap_seen and director_at_wall_before_overlap, "box 8: the Director has stepped back to the wall before WOLF reaches him")
	_expect(min_front_gap >= 8.0, "box 8: while WOLF passes in front of the Director his feet are at least 8 px nearer the camera (%.2f)" % min_front_gap)
	_expect(min_tail_clear >= 9.0, "box 8: while WOLF's tail passes the hanging lock his feet are at least 9 px clear of the bay's face (%.2f)" % min_tail_clear)
	_expect(not lockdown_on_before_box7 and lockdown_on_t >= 0.0 and absf(lockdown_on_t - box7_shown) < 0.05, "the corridor's lockdown beacon switches on with box 7's line, not before")
	_expect(lockdown_in_view, "the corridor's lockdown beacon is inside the opening's view")
	_expect(bool(bay.get("lockdown_on")), "the corridor's lockdown beacon is still on at first control")
	_expect(wolf_edge_in_bay == 0.0, "the fitting puts no lit edge on WOLF in the bay (the cross-wall stands between them)")
	print("RESULT box4 shown=%.3f wolf_moves=%.3f connector=%.3f lamp_off=%.3f tear=%.3f leaves_stop=%.3f max_leaf_error=%.2f wolf_drift=%.3f tail_in_stack_s=%.3f" % [box4_shown, wolf_first_move_t, connector_release_t, lamp_off_t, tear_t, leaves_stop_t, max_lead_error, wolf_drift_while_sweeping, tail_in_stack_s])
	_expect(connector_release_t >= 0.0 and absf(connector_release_t - wolf_first_move_t) < 0.02, "the connector parts on WOLF's first frame of movement")
	_expect(not lamp_off_while_attached and absf(lamp_off_t - connector_release_t) < 0.02, "the dock lamp goes off when the contacts part, not before")
	_expect(tear_t - box4_shown >= 0.8, "box 4's caption shows before the break-out starts (tear %.2f s in)" % (tear_t - box4_shown))
	_expect(wolf_drift_while_sweeping < 0.01, "WOLF stays planted at the latch edge while the leaves move (drift %.3f px)" % wolf_drift_while_sweeping)
	_leaf_curve_check()
	_expect(max_lead_error <= 0.5, "the drawn leaves follow that curve (largest gap %.2f px beyond a frame)" % max_lead_error)
	_expect(leaves_stop_t - tear_t >= 2.0, "the leaves coast to the stop over %.2f s" % (leaves_stop_t - tear_t))
	_expect(tail_in_stack_s == 0.0, "WOLF's tail never reaches into the stacked leaves while he is drawn in front of them")
	_expect(not engineer_turned_making_way, "box 8: the engineer keeps facing WOLF")
	print("RESULT round3 wake_after_caption=%.3f max_wash=%.3f beacon_off_after_tear_s=%.3f" % [wake_start_t - box3_shown, max_wash, beacon_off_after_tear_s])
	_expect(wake_start_t - box3_shown >= 0.8 - 0.02 - box3_frame, "box 3's caption shows before WOLF starts to wake (%.2f s in, the first frame %.3f s long)" % [wake_start_t - box3_shown, box3_frame])
	_expect(max_wash == 0.0, "no full-screen wash at any point of the opening (largest %.3f)" % max_wash)
	_expect(beacon_off_after_tear_s == 0.0, "the beacon stays on from the tear to the cut")
	_expect(not wolf_flipped_box8, "box 8: WOLF never flips round")
	_expect(shadows_while_passing, "box 8: the Director, WOLF and the engineer cast contact shadows while WOLF passes")
	var display: Sprite2D = game.get_node("PurgeTerminalArt") as Sprite2D
	var display_rect: Rect2 = display.get_global_transform_with_canvas() * display.get_rect()
	var prompt_rect: Rect2 = (game.get_node("CanvasLayer/TutorialPrompt") as Control).get_global_rect()
	var gap: float = prompt_rect.position.x - display_rect.end.x
	_expect(gap >= 8.0 or not prompt_rect.intersects(display_rect.grow(8.0)), "first control's prompt stands clear of the purge display (gap %.1f px)" % gap)
	var relay: CanvasItem = game.get_node("RelayLabel") as CanvasItem
	var tag: CanvasItem = (game.get("bypass_handle") as Object).get("fault_tag") as CanvasItem
	_expect(relay.self_modulate.a < 0.6 and tag.self_modulate.a < 0.6, "the relay's name and fault tag are dimmed until the breaker is armed")


func _room_checks() -> void:
	var cx: float = _cam_x()
	print("RESULT walk_back max_camera_speed=%.1f px/s camera=%.1f hitched_windows=%d" % [max_cam_speed, cx, hitched_windows])
	_expect(absf(cx - ROOM_VIEW_CENTRE) < 2.0, "the dock room shows whole (camera %.1f, view %.1f..%.1f)" % [cx, cx - 355.6, cx + 355.6])
	_expect(max_cam_speed <= 400.0, "the walk back pans, never whips (fastest %.0f px/s over 0.1 s)" % max_cam_speed)
	_expect(not (game.get_node("IntroDirector") as CanvasItem).visible, "the room is empty: the Director is gone")
	_expect((game.get_node("CanvasLayer/IntroAlarm") as ColorRect).color.a == 0.0 and not bool(bay.get("beacon_on")) and int(bay.get("status_lamp")) == 3, "the room is quiet: no wash, beacon off, the torn lock's indicator dark")
	_expect(not corridor_card_in_room, "the corridor's MAINTENANCE / LOCKDOWN card never shows in the dock room")
	print("RESULT exit director_gone=%.3f view_reaches_door=%.3f door_open_then=%.2f director_seen=%s door_now=%.2f" % [exit_gone_t, view_reaches_door_t, door_open_when_seen, director_seen_in_walk_back, float(bay.get("exit_open"))])
	_expect(exit_gone_t >= 0.0 and view_reaches_door_t >= 0.0 and exit_gone_t < view_reaches_door_t and not director_seen_in_walk_back, "the Director is through his door before the walk back's view reaches it (gone %.2f s, view at the door %.2f s)" % [exit_gone_t, view_reaches_door_t])
	_expect(float(bay.get("exit_open")) == 0.0, "his door is shut again by the time the room is in view")


## The resting marks at the end of each box's reading time.
func _end_of_box(step: int) -> void:
	var human: Node2D = game.get_node("Human") as Node2D
	var wolf: Node2D = game.get_node("Wolf") as Node2D
	var director: Node2D = game.get_node("IntroDirector") as Node2D
	var wolf_left: bool = (wolf.get_node("BodySprite") as Sprite2D).flip_h
	var eng_left: bool = (human.get_node("BodySprite") as Sprite2D).flip_h
	print("MARK box %d t=%.2f engineer %s %.1f %s | WOLF %.1f %s z%d | Director %s %.1f" % [step + 1, clock, "shown" if human.visible else "hidden", human.position.x, "L" if eng_left else "R", wolf.position.x, "L" if wolf_left else "R", wolf.z_index, "shown" if director.visible else "hidden", director.position.x])
	for x: float in [human.position.x, wolf.position.x]:
		if x > NEAR_COLUMN.x and x < NEAR_COLUMN.y:
			_expect(false, "box %d: nobody rests inside the near column" % (step + 1))
	if step == 7:
		_expect(absf(wolf.position.x - DOORWAY_X) <= 0.5 and not wolf_left, "box 8: WOLF stops at %.0f facing the engineer (%.1f)" % [DOORWAY_X, wolf.position.x])
		_expect(absf(human.position.x - MEET_X) <= 0.5 and eng_left, "box 8: the engineer has stepped toward him, still facing him (%.1f)" % human.position.x)
		var gap: float = (human.position.x - ENGINEER_HALF) - (wolf.position.x + WOLF_HALF + 1.5)
		print("RESULT box8 wolf_engineer_gap=%.1f px (%.2f m)" % [gap, gap / 40.0])
		_expect(gap > 0.0 and gap <= 30.0, "box 8: they meet within 0.75 m (%.1f px)" % gap)
	if step == 3:
		_expect(bool(bay.get("lock_torn")) and int(bay.get("dock_lamp")) == 2 and absf(float(bay.get("lead_x")) - 33.0) < 0.5, "box 4: lock hanging, dock lamp off, leaves at the open stop")
		_expect(absf(wolf.position.x - -327.0) <= 0.5, "box 4: WOLF is on his exit mark by the box's end (%.1f)" % wolf.position.x)


func _finish() -> bool:
	if failures == 0:
		print("opening_timing_test: all passed")
	else:
		print("opening_timing_test: %d failed" % failures)
	for action: StringName in [&"move_left", &"move_right", &"interact"]:
		Input.action_release(action)
	(game.get("sfx_bank") as Node).call("stop_all")
	for suffix: String in ["", "-settings.cfg"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	phase = "closing"
	close_wait = 0.0
	return false
