class_name Opening
extends Node
## The opening's staging in the dock bay (layout L1, Nathanial 2026-10-14; DockBay holds the room and
## WOLF's marks in it): what each of the opening's boxes shows while its caption is up. Main owns the
## boxes themselves (INTRO_LINES, the presses, the fades and the hand-over to play) and calls
## [method start], [method advance], [method tick], [method finish] and [method stop]; this node moves
## the actors and the bay. It was split out of main.gd (decision 7, recommended) so the opening's ~300
## lines of choreography live in one place.
##
## The beats, by Main.intro_step (the approved 2026-10-13 draft's boxes; box 5's two speakers are two
## boxes of one step, which Main's dialogue boxes split by speaker):
## 0 (box 1): WOLF charging on the pad in his shut, locked cage; the Director in front of the bay, his
##   back to the doorway; the doorway empty (Q-A).
## 1 (box 2): the engineer walks in from the corridor and stops in the doorway, watching (Q2).
## 2 (box 3): the caption first, then WOLF wakes himself: the pad, the battery screen and his eye and
##   seams turn from amber to blue.
## 3 (box 4): the caption first, then the break-out: he gets up (the charge cuts as he lifts), stands at
##   the latch and forces the guard lock (the boom, the lock torn off and swinging, the bay's beacon, the
##   Director stepping back without turning (Q-B), the engineer's flinch), shoulders the leaves aside with
##   his feet planted (Q-F) and steps down out of the bay.
## 4 (box 5 and 6): the Director and WOLF face each other.
## 5 (box 7): "Lock down maintenance": the klaxon and the corridor's lockdown light through the doorway,
##   with the line, not before (decision 7).
## 6 (box 8): the Director steps back to the wall first (decision 4); only then does WOLF walk to the
##   doorway, in a lane nearer the camera, passing in front of him, and the engineer takes a half step
##   toward him.
## Then, under the fade into play, the Director leaves by his door (badge, open, through, the closer).
## A press moves the caption on at once and never snaps an action to its end: each step's action waits
## for the one playing to finish (queue_beat, backup round 4).
## Units: world px (40 per metre), seconds, px/s. Marks are the codex/opening-dock backup's round-4 ones
## (9b6a2e3) unless DockBay derives them from the new pieces.

## The Director: his mark in front of the bay, his step back from the tear (and 2 px toward the camera,
## so "behind" reads as depth when WOLF passes), and his last mark at the back wall by his door.
const DIRECTOR_X: float = -257.0
const DIRECTOR_Y: float = 410.0
const DIRECTOR_BACK_X: float = -235.0
const DIRECTOR_DOWNSTAGE: float = 2.0
const DIRECTOR_LAST: Vector2 = Vector2(-222.0, 406.5)
const DIRECTOR_STEP_S: float = 0.5
## In box 8 the Director draws behind WOLF passing in front of him (WOLF is at Main.ACTOR_Z).
const DIRECTOR_YIELD_Z: int = Main.ACTOR_Z - 1
## The engineer: where they come from (in the corridor, out of the opening's view), where they stop in
## the doorway to watch, and the half step toward WOLF in box 8 (they meet: backup round 3).
const ENGINEER_ENTER_X: float = 125.0
const ENGINEER_WATCH_X: float = -34.0
const ENGINEER_MEET_X: float = -44.0
const ENGINEER_MEET_S: float = 0.45
## WOLF stops at the opening's edge, his painted snout 0.6 m from the engineer's reach (backup round 3,
## review-human-2 9): x -140 before he was drawn at a real wolf's size (Main.WOLF_ART_SCALE).
const WOLF_DOORWAY_X: float = ENGINEER_MEET_X - M0Actor.HUMAN_REACH - 0.6 * DoorCamera.PX_PER_M - M0Actor.WOLF_SNOUT
## Calm walking speeds (review S6): 1.4 m/s, under Spot's 1.6 m/s maximum; the Director leaves briskly
## (1.6 m/s): he is going to see his order done.
const WALK_SPEED: float = 56.0
const DIRECTOR_EXIT_SPEED: float = 64.0
## Caption first (backup round 3, review-human-2 3): the wake and the break-out wait this long after
## their box appears; the wake eases over WAKE_S; WOLF is up at the latch LATCH_S after he lifts.
const ENGINEER_DELAY: float = 0.3
const WAKE_DELAY: float = 0.8
const WAKE_S: float = 0.8
const LATCH_DELAY: float = 0.8
const LATCH_S: float = 0.3
## The step down out of the bay (backup round 4): STEP_S long; his forepaw passes the sill's foot
## PAW_CLEAR px into it, and only then is he drawn over the cage (the sill hides his paws till then).
const STEP_S: float = 0.28
const PAW_CLEAR: float = 3.5
## Box 8: WOLF waits this long after the Director starts his step back; his lane is LANE px nearer the
## camera while he passes the Director, eased in over his first LANE_IN px and out between LANE_OUT's
## two x (world px), 20 and 5 px before the doorway mark (the backup's -160 and -145 for its -140).
const WOLF_WAIT_S: float = 0.35
const LANE: float = 2.0
const LANE_IN: float = 21.0
const LANE_OUT: Vector2 = Vector2(WOLF_DOORWAY_X - 20.0, WOLF_DOORWAY_X - 5.0)
## The engineer flinches at the tear (a placeholder for a drawn frame): 3 px away and 5 degrees back,
## held 0.3 s, then back over 0.25 s.
const FLINCH: Vector2 = Vector2(3.0, 0.5)
const FLINCH_DEG: float = 5.0
## The Director's exit (backup round 4, review-real-3 M2): the badge reader beside his door, the door's
## middle he goes through, the badge (its LED goes green over the first 0.12 s), the push open, and the
## closer bringing the leaf shut behind him.
const EXIT_READER_X: float = -232.0
const EXIT_THROUGH_X: float = -262.0
const EXIT_BADGE_S: float = 0.3
const EXIT_READER_S: float = 0.12
const EXIT_OPEN_S: float = 0.45
const EXIT_CLOSE_S: float = 1.2
## Sounds: the wake's servo, the tear's boom (Main._shutter_boom), each leaf catch's quiet clunk, the
## klaxon with the lockdown order, the door's quiet latch (dB, pitch).
const SERVO_DB: float = -14.0
const CATCH_DB: float = -16.0
const CATCH_PITCH: float = 0.85
const KLAXON_DB: float = -10.0
const LATCH_DB: float = -22.0
const LATCH_PITCH: float = 1.2

## The game this staging belongs to.
var main: Main
var _queue: Array[Callable] = []
var _beat: Tween
var _exit: Tween
var _flinch: Tween
## Box 8: WOLF is on his walk to the doorway; the engineer has taken their half step.
var _box8_walking: bool = false
var _engineer_met: bool = false
## Seconds since the leaves' push began at their last update (for the catch clunks), or -1.
var _leaf_clock: float = -1.0


## The opening's first frame (box 1), after Main has reset the scene for a new game.
func start() -> void:
	stop()
	var human: M0Actor = main.human
	var wolf: M0Actor = main.wolf
	human.hide()
	human.position.x = ENGINEER_ENTER_X
	human.body_sprite.flip_h = true
	var director: Sprite2D = main.intro_director
	director.position = Vector2(DIRECTOR_X, DIRECTOR_Y)
	director.z_index = Main.ACTOR_Z
	director.modulate = Color.WHITE
	director.show()
	wolf.position = Vector2(DockBay.LIE_X, wolf.position.y)
	wolf.z_index = DockBay.WOLF_CAGED_Z
	wolf.body_sprite.flip_h = false
	main.wolf_pose(&"lie", DockBay.PAD_LIFT)
	main.wolf_lights.tint = WolfLights.LIGHT
	main.wolf_lights.strength = Main.WOLF_RESTING_LIGHT
	# Inside the bay he lies on the pad, behind the leaves: no reflection on the deck in front.
	main.wolf_reflection.enabled = false
	main.dock_bay.set_standby()


## The staging of opening step [param step] (Main.intro_step, just advanced; see the class doc).
func advance(step: int) -> void:
	match step:
		1:
			queue_beat(_engineer_arrives)
		2:
			queue_beat(_wake)
		3:
			queue_beat(_break_out)
		5:
			# The order is heard and seen as it is given, so it is not queued.
			main.sfx_bank.play(&"klaxon", KLAXON_DB)
			main.dock_bay.set_lockdown(true)
		6:
			queue_beat(_wolf_leaves)


## Runs [param beat] now, or once the beat already playing has finished. A beat returns the tween that
## plays it, or null when it is instant.
func queue_beat(beat: Callable) -> void:
	_queue.append(beat)
	if _beat == null or not _beat.is_running():
		_next_beat()


func _next_beat() -> void:
	while not _queue.is_empty():
		var beat: Callable = _queue.pop_front()
		var tween: Variant = beat.call()
		if tween is Tween and (tween as Tween).is_running():
			_beat = tween as Tween
			_beat.finished.connect(_next_beat, CONNECT_ONE_SHOT)
			return
	_beat = null


## True while a beat is playing or waiting to.
func busy() -> bool:
	return not _queue.is_empty() or (_beat != null and _beat.is_running())


## Box 2: the engineer walks in from the corridor and stops in the doorway (Q-A).
func _engineer_arrives() -> Tween:
	var tween: Tween = create_tween()
	tween.tween_interval(ENGINEER_DELAY)
	tween.tween_callback(func() -> void:
		main.human.show()
		_walk(main.human, ENGINEER_WATCH_X))
	return tween


## Box 3: the caption first; then WOLF wakes himself.
func _wake() -> Tween:
	var tween: Tween = create_tween()
	tween.tween_interval(WAKE_DELAY)
	tween.tween_callback(func() -> void: main.sfx_bank.play(&"servo", SERVO_DB))
	tween.tween_method(_wake_at, 0.0, 1.0, WAKE_S)
	return tween


## The wake at [param t] (0 charging .. 1 awake): the dock's light and screen (DockBay.set_wake) and
## WOLF's lights from dim cyan to bright blue.
func _wake_at(t: float) -> void:
	main.dock_bay.set_wake(t)
	main.wolf_lights.tint = WolfLights.LIGHT.lerp(DockBay.WAKE_BLUE, t)
	main.wolf_lights.strength = lerpf(Main.WOLF_RESTING_LIGHT, 1.0, t)


## Box 4 (Q-F): the caption first; then WOLF gets up off the pad, stands at the latch and forces the
## guard lock, shoulders the leaves aside with his feet planted while they coast to the stop, and steps
## down out of the bay to stand clear of the hanging lock.
func _break_out() -> Tween:
	var tween: Tween = create_tween()
	tween.tween_interval(LATCH_DELAY)
	tween.tween_callback(_wolf_rises)
	tween.tween_interval(LATCH_S)
	tween.tween_callback(_wolf_at_latch)
	tween.tween_callback(_lock_tears)
	tween.tween_callback(func() -> void: _leaf_clock = 0.0)
	tween.tween_method(_leaves_at, 0.0, DockBay.leaf_seconds(), DockBay.leaf_seconds())
	tween.tween_callback(func() -> void: main.sfx_bank.play(&"clank", -8.0))
	# The step down: back off the latch to clear the hanging lock, and down toward the camera; he is
	# drawn over the cage once his forepaw has passed the sill's foot.
	var rest: float = Main.WOLF_SPRITE_REST.y
	var paw_s: float = STEP_S * PAW_CLEAR / DockBay.STEP_DOWN
	tween.tween_property(main.wolf.body_sprite, "position:y", rest + PAW_CLEAR, paw_s)
	tween.parallel().tween_property(main.wolf, "position:x", lerpf(DockBay.LATCH_X, DockBay.OUT_X, PAW_CLEAR / DockBay.STEP_DOWN), paw_s)
	tween.tween_callback(_wolf_steps_down)
	tween.tween_property(main.wolf.body_sprite, "position:y", rest + DockBay.STEP_DOWN, STEP_S - paw_s)
	tween.parallel().tween_property(main.wolf, "position:x", DockBay.OUT_X, STEP_S - paw_s)
	return tween


## WOLF lifts off the pad: the getting-up piece, his haunch where it lay; the coupling breaks as he lifts,
## so the pad's light and the battery screen go dark on this frame.
func _wolf_rises() -> void:
	main.wolf.position.x = DockBay.RISE_X
	main.wolf_pose(&"rise", DockBay.PAD_LIFT)
	main.dock_bay.set_charge(DockBay.WAKE_BLUE, 0.0)
	main.dock_bay.set_battery(PropScreen.BATTERY_OFF)


## WOLF up on his feet inside the cage, his nose at the latch.
func _wolf_at_latch() -> void:
	main.wolf_pose(&"stand", DockBay.PAD_LIFT)
	main.wolf.position.x = DockBay.LATCH_X


## WOLF has stepped out of the bay: from here on he draws over the cage, the torn lock included, as
## every actor on the walk line does, and his reflection shows on the deck.
func _wolf_steps_down() -> void:
	main.wolf.z_index = Main.ACTOR_Z
	main.wolf_reflection.enabled = main.effects_enabled


## WOLF forces the guard lock: the boom and the shake, the lock torn off and swinging on its cable, the
## bay's beacon on, the Director stepping back from the cage still facing it (Q-B), the engineer flinching.
func _lock_tears() -> void:
	main.shutter_boom()
	main.dock_bay.tear_lock()
	main.dock_bay.set_beacon(true)
	var step_back: Tween = create_tween()
	step_back.tween_property(main.intro_director, "position", Vector2(DIRECTOR_BACK_X, DIRECTOR_Y + DIRECTOR_DOWNSTAGE), 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	Tweens.kill(_flinch)
	var body: Sprite2D = main.human.body_sprite
	_flinch = create_tween()
	_flinch.tween_property(body, "position", Main.HUMAN_SPRITE_REST + FLINCH, 0.06)
	_flinch.parallel().tween_property(body, "rotation_degrees", FLINCH_DEG, 0.06)
	_flinch.tween_interval(0.3)
	_flinch.tween_property(body, "position", Main.HUMAN_SPRITE_REST, 0.25)
	_flinch.parallel().tween_property(body, "rotation_degrees", 0.0, 0.25)


## The leaves [param t] seconds into WOLF's push (DockBay.leaf_travel), with a quiet clunk as each
## intermediate leaf is caught.
func _leaves_at(t: float) -> void:
	main.dock_bay.set_lead_travel(DockBay.leaf_travel(t))
	var plan: Dictionary = DockBay.leaf_plan()
	for px: float in [float(plan["catch_1_px"]), float(plan["catch_2_px"])]:
		var at: float = DockBay.leaf_time_at(px)
		if _leaf_clock < at and t >= at:
			main.sfx_bank.play(&"clank", CATCH_DB, CATCH_PITCH)
	_leaf_clock = t


## Box 8 (decision 4): the Director steps back first, to the wall, eyes on WOLF; then WOLF walks to the
## doorway in his lane nearer the camera, passing in front of him (tick), and stops facing the engineer.
func _wolf_leaves() -> Tween:
	var director: Sprite2D = main.intro_director
	var tween: Tween = create_tween()
	tween.tween_callback(func() -> void: director.z_index = DIRECTOR_YIELD_Z)
	tween.tween_property(director, "position", DIRECTOR_LAST, DIRECTOR_STEP_S).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_callback(func() -> void:
		_box8_walking = true
		_walk(main.wolf, WOLF_DOORWAY_X)).set_delay(WOLF_WAIT_S)
	return tween


## [param actor] walks on their own to [param x] at WALK_SPEED.
func _walk(actor: M0Actor, x: float) -> void:
	actor.speed_scale = WALK_SPEED / M0Actor.FOLLOW_SPEED
	actor.autonomous_target_x = x


## Every frame of the opening: each actor lands exactly on their mark, and box 8's lane and half step.
func tick() -> void:
	# The walk stops inside a 2 px band; in the opening each actor lands on their mark.
	for actor: M0Actor in [main.human, main.wolf]:
		var target: float = actor.autonomous_target_x
		if target != M0Actor.NO_TARGET and absf(actor.position.x - target) <= 2.0 and absf(actor.velocity.x) < 1.0:
			actor.position.x = target
			actor.autonomous_target_x = M0Actor.NO_TARGET
	if not _box8_walking:
		return
	var x: float = main.wolf.position.x
	var lane: float = smoothstep(DockBay.OUT_X, DockBay.OUT_X + LANE_IN, x) * (1.0 - smoothstep(LANE_OUT.x, LANE_OUT.y, x))
	main.wolf.body_sprite.position.y = Main.WOLF_SPRITE_REST.y + DockBay.STEP_DOWN + LANE * lane
	if not _engineer_met and absf(x - WOLF_DOORWAY_X) <= 30.0:
		_engineer_met = true
		var step_in: Tween = create_tween()
		step_in.tween_property(main.human, "position:x", ENGINEER_MEET_X, ENGINEER_MEET_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## After the last press, under the fade: the beats stop where they are, and the Director walks to the
## badge reader beside his door, badges (its LED goes green), pushes the leaf open and goes through into
## the dark passage; the closer pulls the leaf shut behind him. A player who walks straight back finds
## him gone and, at most, the leaf closing.
func director_exit() -> void:
	_stop_beats()
	var director: Sprite2D = main.intro_director
	var bay: DockBay = main.dock_bay
	var from: Vector2 = director.position
	var at_reader: Vector2 = Vector2(EXIT_READER_X, DIRECTOR_LAST.y)
	var through: Vector2 = Vector2(EXIT_THROUGH_X, DIRECTOR_LAST.y - 1.5)
	Tweens.kill(_exit)
	_exit = create_tween()
	_exit.tween_property(director, "position", at_reader, maxf(from.distance_to(at_reader) / DIRECTOR_EXIT_SPEED, 0.05))
	_exit.tween_method(func(v: float) -> void: bay.set_exit(0.0, v), 0.0, 1.0, EXIT_READER_S)
	_exit.tween_interval(EXIT_BADGE_S - EXIT_READER_S)
	_exit.tween_method(func(v: float) -> void: bay.set_exit(v, 1.0), 0.0, 1.0, EXIT_OPEN_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var walk_s: float = at_reader.distance_to(through) / DIRECTOR_EXIT_SPEED
	_exit.tween_property(director, "position", through, walk_s)
	# Into the dark passage: he darkens and is gone over the last part of the step.
	_exit.parallel().tween_property(director, "modulate", Color(0.2, 0.2, 0.2, 0.0), walk_s * 0.6).set_delay(walk_s * 0.4)
	_exit.tween_callback(_director_gone)
	_exit.tween_method(func(v: float) -> void: bay.set_exit(v, clampf(v * 2.0 - 1.0, 0.0, 1.0)), 1.0, 0.0, EXIT_CLOSE_S).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_exit.tween_callback(func() -> void: main.sfx_bank.play(&"clank", LATCH_DB, LATCH_PITCH))


## True while the Director is on his way out under the fade.
func exiting() -> bool:
	return _exit != null and _exit.is_running()


func _director_gone() -> void:
	var director: Sprite2D = main.intro_director
	director.hide()
	director.modulate = Color.WHITE
	director.z_index = Main.ACTOR_Z
	director.position = Vector2(DIRECTOR_X, DIRECTOR_Y)


## The hand-over to play: the beats stop, the engineer and WOLF are back on their own, the bay is empty
## and quiet. The Director keeps walking out under the fade when [param keep_exit] (the last press);
## otherwise (a skip) he is simply gone and his door is shut.
func finish(keep_exit: bool) -> void:
	_stop_beats()
	if not (keep_exit and exiting()):
		Tweens.kill(_exit)
		_director_gone()
	Tweens.kill(_flinch)
	var human: M0Actor = main.human
	human.body_sprite.rotation_degrees = 0.0
	human.body_sprite.position = Main.HUMAN_SPRITE_REST
	human.body_sprite.flip_h = false
	human.autonomous_target_x = M0Actor.NO_TARGET
	human.speed_scale = 1.0
	main.wolf.speed_scale = 1.0
	main.wolf.body_sprite.flip_h = false
	main.dock_bay.set_empty_quiet()
	# Play starts in lockdown, even after a skip that never reached the order.
	main.dock_bay.set_lockdown(not main.state.checkpoint_reached)
	if not (keep_exit and exiting()):
		main.dock_bay.set_exit(0.0, 0.0)


## Stops everything the opening has moving (a new game, a load): no beat, no exit, no flinch.
func stop() -> void:
	_stop_beats()
	Tweens.kill(_exit)
	_exit = null
	Tweens.kill(_flinch)
	_box8_walking = false
	_engineer_met = false
	_leaf_clock = -1.0


func _stop_beats() -> void:
	_queue.clear()
	Tweens.kill(_beat)
	_beat = null
	_box8_walking = false
