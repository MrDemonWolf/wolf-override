class_name DebugActions
extends Node
## What the debug menu does to the running game: jumps to any beat, the earlier choices those jumps
## use, cheats (invincibility, a frozen sentry, instant cranks, slow motion and frame stepping),
## forced knockdowns, the door blast and the tank drop, the save actions and the effect switches.
## DebugTools owns one; DebugMenu is only its buttons, so tests and capture drivers can call the same
## methods. Every method that changes the game returns a short note saying what happened, or why not.
##
## Jumps build the run through M0State's own steps (record_choice, arm_breaker, activate_power,
## reach_checkpoint, enter_records, ...) from the presets, so a jumped state is one real play can
## reach. A jump to a beat the game autosaves at writes that checkpoint, as play does on reaching it,
## and Main's own load puts it on screen; the beats before the first SAFE POINT go through a new game,
## the end of the opening and the breaker's own interact, and leave the save on disk alone. Main is
## reached only through its typed public debug_* calls and fields, never its private methods.
##
## Cost: it processes only while instant crank or slow motion is on (it runs before Main each frame,
## process_priority PROCESS_FIRST), and its frame stepper only for the one frame a step lets through.
## Main asks spares_knockdown() and sentry_frozen when a knockdown or the sentry's tick comes up.

## A cheat, preset or switch changed; the menu and the overlay show it.
signal changed
## One frame was let through by step_frame().
signal frame_stepped(frames: int)

## The beats a jump lands on, in play order.
const JUMPS: Array[StringName] = [
	&"opening", &"corridor_start", &"relay_question", &"safe_point", &"records_entry", &"records_mirror",
	&"junction_a", &"lane", &"tank_down", &"end_of_slice",
]
const JUMP_NAMES: Dictionary = {
	&"opening": "OPENING", &"corridor_start": "CORRIDOR START", &"relay_question": "RELAY QUESTION",
	&"safe_point": "CORRIDOR SAFE POINT", &"records_entry": "RECORDS ENTRY", &"records_mirror": "RECORDS, MIRROR COPIED",
	&"junction_a": "JUNCTION SAVE A", &"lane": "AFTER THE BLAST / LANE", &"tank_down": "TANK DOWN", &"end_of_slice": "END OF SLICE",
}
## Jumps that land on one of the game's checkpoints and so write it, as play does.
const CHECKPOINT_JUMPS: Array[StringName] = [&"safe_point", &"records_entry", &"records_mirror", &"junction_a", &"lane", &"tank_down", &"end_of_slice"]
## The relay answer and who opened the seal: rushed (WOLF refuses, the engineer cranks the bypass),
## told with WOLF taking the contact, or told and then cranked anyway.
const RELAY_OPTIONS: Array[StringName] = [&"press", &"disclose_wolf", &"disclose_bypass"]
const MIRROR_OPTIONS: Array[StringName] = [&"wolf", &"manual"]
## How the sentry comes down: WOLF draws it (only after the relay was disclosed), the engineer times
## it while WOLF holds back by the valve, or WOLF is asked and refuses (only after a rushed relay).
const LANE_OPTIONS: Array[StringName] = [&"wolf", &"alone", &"refused"]
const OPTION_NAMES: Dictionary = {
	&"press": "RUSHED, BYPASS", &"disclose_wolf": "TOLD, WOLF", &"disclose_bypass": "TOLD, BYPASS",
	&"wolf": "WOLF", &"manual": "MANUAL PORT", &"alone": "ALONE", &"refused": "WOLF REFUSES",
}
const SLOW_MOTION: Array[float] = [1.0, 0.5, 0.25]
const KNOCKDOWNS: Array[StringName] = [&"vent", &"blast", &"sentry", &"cloud"]
## Before Main in every frame, so a primed crank lands in the same frame Main reads it.
const PROCESS_FIRST: int = -100
## After every other node, so a frame step lets exactly one frame of play through.
const PROCESS_LAST: int = 1000

## Runs once, after every other node has processed, then lets DebugActions pause the tree again.
class Stepper:
	extends Node
	var on_frame: Callable

	func _init() -> void:
		name = "FrameStepper"
		process_priority = DebugActions.PROCESS_LAST
		set_process(false)

	func _ready() -> void:
		set_process(false)

	func _process(_delta: float) -> void:
		set_process(false)
		on_frame.call()


var game: Main
var tools: DebugTools
## The earlier choices a jump builds the run from.
var relay: StringName = &"disclose_wolf"
var mirror: StringName = &"wolf"
var lane: StringName = &"wolf"
var invincible: bool = false
var sentry_frozen: bool = false
var instant_crank: bool = false
var slow_motion: float = 1.0
var frame_step: bool = false
var frames_stepped: int = 0
## The effect switches as the menu last set them (Main's effects_enabled, Impact's shake and flash).
var effects_on: bool = true
var shake_on: bool = true
var flash_on: bool = true
var stepper: Stepper
var _forcing: bool = false
var _step_pending: bool = false
## Main's effects switch before the menu first changed it, put back by reset_all().
var _effects_before: Variant = null


func _init() -> void:
	name = "DebugActions"
	process_priority = PROCESS_FIRST
	set_process(false)
	set_physics_process(false)


## A node with a _process starts processing when it enters the tree; these start idle.
func _ready() -> void:
	_update_processing()


func setup(main: Main, owner_tools: DebugTools) -> void:
	game = main
	tools = owner_tools
	stepper = Stepper.new()
	stepper.on_frame = _on_stepped
	add_child(stepper)


# --- Main's view of the cheats -------------------------------------------------------------------

## True while invincibility keeps knockdowns from landing; a knockdown forced from the menu still lands.
func spares_knockdown() -> bool:
	return invincible and not _forcing


# --- Presets ------------------------------------------------------------------------------------

## The relay answer later jumps use. WOLF's lane answer follows the same rule as the relay (he draws
## the sentry only if he was told the risk), so a lane preset that rule rules out changes with it.
func set_relay(option: StringName) -> String:
	if not RELAY_OPTIONS.has(option):
		return ""
	relay = option
	var note: String = "Relay: %s. The next jump uses it." % OPTION_NAMES[option]
	if relay == &"press" and lane == &"wolf":
		lane = &"refused"
		note += " Lane set to WOLF REFUSES: rushed at the relay, he won't draw the sentry."
	elif relay != &"press" and lane == &"refused":
		lane = &"wolf"
		note += " Lane set to WOLF: told the risk, he draws the sentry when asked."
	changed.emit()
	return note


func set_mirror(option: StringName) -> String:
	if not MIRROR_OPTIONS.has(option):
		return ""
	mirror = option
	changed.emit()
	return "Mirror: %s. The next jump uses it." % OPTION_NAMES[option]


func set_lane(option: StringName) -> String:
	if not LANE_OPTIONS.has(option):
		return ""
	lane = option
	var note: String = "Lane: %s. The next lane, tank or end jump uses it." % OPTION_NAMES[option]
	if lane == &"wolf" and relay == &"press":
		relay = &"disclose_wolf"
		note += " Relay set to TOLD: WOLF draws the sentry only if he was told the risk."
	elif lane == &"refused" and relay != &"press":
		relay = &"press"
		note += " Relay set to RUSHED: WOLF refuses only after a rushed relay."
	changed.emit()
	return note


# --- Jumps --------------------------------------------------------------------------------------

## Jumps to [param id] (one of JUMPS), building the run from the presets, and returns a note.
func jump(id: StringName) -> String:
	if not JUMPS.has(id):
		return ""
	tools.cheats_used = true
	match id:
		&"opening":
			game.debug_new_game(false)
		&"corridor_start":
			game.debug_new_game(true)
		&"relay_question":
			game.debug_new_game(true)
			# Beside the breaker, as play arrives there; its interact gives WOLF's purge stakes, the next
			# ones go on through their boxes to his question about the relay.
			var breaker: Vector4 = Main.CORRIDOR_STATIONS[0]
			var spot: float = game.debug_station_side_x(breaker, breaker.x - 1.0)
			game.debug_place(spot, spot - M0Actor.FOLLOW_GAP)
			for _press: int in 4:
				if game.waiting_for_choice:
					break
				game.debug_interact()
		_:
			if not build_state(id).save_to_disk(game.save_path):
				return "The checkpoint for %s could not be written." % JUMP_NAMES[id]
			game.debug_load_checkpoint()
			if id == &"lane":
				_answer_lane()
			elif id == &"end_of_slice":
				game.debug_show_end_card()
	_hold_if_stepping()
	changed.emit()
	return "Jumped to %s%s." % [JUMP_NAMES[id], " (checkpoint written)" if CHECKPOINT_JUMPS.has(id) else ""]


## The run at checkpoint jump [param id], built with M0State's own steps from the presets, with the
## engineer and WOLF where play leaves them at that beat.
func build_state(id: StringName) -> M0State:
	var state: M0State = M0State.new()
	state.record_choice(M0State.PRESS if relay == &"press" else M0State.DISCLOSE)
	state.arm_breaker()
	state.activate_power("wolf" if relay == &"disclose_wolf" else "human")
	state.reach_checkpoint()
	# At the safe point, beside it on the left as its interact leaves the engineer.
	_set_positions(state, _side_spot(Main.CORRIDOR_STATIONS[2], -1.0))
	if id == &"safe_point":
		return state
	state.enter_records()
	if id == &"records_entry":
		return state
	state.preserve_purge_trace()
	state.preserve_mirror_trace(String(mirror))
	# Beside the mirror port; WOLF on its right where he read it, or following.
	var port: float = _side_spot(Main.RECORDS_STATIONS[1], -1.0)
	_set_positions(state, port, Main.WOLF_MIRROR_X if mirror == &"wolf" else port - M0Actor.FOLLOW_GAP)
	if id == &"records_mirror":
		return state
	state.complete_chapter()
	state.enter_junction()
	if id == &"junction_a":
		return state
	state.blow_door()
	# Backed off past the valve when the fuse ran out, just clear of the blast; WOLF by the entrance.
	_set_positions(state, PressureLine.BLAST_MIN_X - 8.0, JunctionRoom.WOLF_CLEAR_X)
	if id == &"lane":
		return state
	state.drop_sentry()
	state.lane_recap = String(lane)
	# At the TANK RELEASE; WOLF where he drew the sentry, or back by the valve.
	var release: Vector4 = Main.JUNCTION_STATIONS[2]
	_set_positions(state, _side_spot(release, release.w), JunctionRoom.WOLF_BAIT_X if lane == &"wolf" else JunctionRoom.WOLF_RUBBLE_X)
	if id == &"tank_down":
		return state
	state.clear_junction()
	# At the bolt; WOLF at his spot by the hatch, where he waits once the sentry is down.
	_set_positions(state, JunctionRoom.BOLT_X, JunctionRoom.WOLF_DOWN_X)
	return state


## After the blast: the engineer walks up to the rubble line, WOLF asks how to bring the sentry down,
## and the lane preset answers through the game's own answer (he decides by the relay memory).
func _answer_lane() -> void:
	game.debug_place(JunctionRoom.CHOICE_X, JunctionRoom.WOLF_RUBBLE_X)
	game.debug_answer_lane(2 if lane == &"alone" else 1)


func _set_positions(state: M0State, human_x: float, wolf_x: float = -1.0) -> void:
	state.human_position.x = human_x
	state.wolf_position.x = clampf(wolf_x if wolf_x >= 0.0 else human_x - M0Actor.FOLLOW_GAP, M0Actor.MIN_X, M0Actor.MAX_X)


## The spot beside a Main station (x: centre, w: its side) on [param side], as Main works it out.
func _side_spot(station: Vector4, side: float) -> float:
	return game.debug_station_side_x(station, station.x + side)


# --- Cheats -------------------------------------------------------------------------------------

func set_invincible(on: bool) -> String:
	invincible = on
	return _cheat_changed(on, "Invincible: knockdowns do not land; the door blows as if you were clear." if on else "Invincible off.")


## A frozen sentry stops moving and changing state; touching one that was chasing still knocks down
## (unless invincible).
func set_sentry_frozen(on: bool) -> String:
	sentry_frozen = on
	return _cheat_changed(on, "Sentry frozen where it is." if on else "Sentry moving again.")


## Holding interact at the junction valve or the corridor's MANUAL BYPASS finishes it at once, through
## the game's own crank (the last turn lands in Main as usual).
func set_instant_crank(on: bool) -> String:
	instant_crank = on
	return _cheat_changed(on, "Instant crank: hold interact at the valve or the bypass." if on else "Instant crank off.")


## Play at [param scale] speed (1, 0.5 or 0.25). Hit-stops still dip it further for their moment.
func set_slow_motion(scale: float) -> String:
	if not SLOW_MOTION.has(scale):
		return ""
	slow_motion = scale
	# A hit-stop under way keeps its dip; it comes back to this speed when it ends (_process).
	if Engine.time_scale > Impact.HIT_STOP_SCALE:
		Engine.time_scale = scale
	return _cheat_changed(scale != 1.0, "Speed %sx." % _speed_text(scale))


static func _speed_text(scale: float) -> String:
	return "1" if scale == 1.0 else str(scale)


## Frame stepping: the game holds still and step_frame() (period, RB, or STEP) lets one frame through.
func set_frame_step(on: bool) -> String:
	if frame_step != on:
		frame_step = on
		frames_stepped = 0
		if on:
			hold_pause()
		else:
			release_pause()
	return _cheat_changed(on, "Frame step: . (period), RB or STEP lets one frame through; Esc, B or RUN plays on." if on else "Frame step off.")


## Lets exactly one frame of play through (the physics steps due in it, then every node's process),
## then holds still again.
func step_frame() -> void:
	if not frame_step or tools.menu_open or _step_pending:
		return
	_step_pending = true
	frames_stepped += 1
	get_tree().paused = false
	stepper.set_process(true)


func _on_stepped() -> void:
	_step_pending = false
	if frame_step:
		get_tree().paused = true
	frame_stepped.emit(frames_stepped)
	changed.emit()


func _cheat_changed(on: bool, note: String) -> String:
	if on:
		tools.cheats_used = true
	_update_processing()
	changed.emit()
	return note


func _update_processing() -> void:
	set_process(tools != null and tools.available and (instant_crank or slow_motion != 1.0))


func _process(_delta: float) -> void:
	if get_tree().paused:
		return
	# Something put the speed back (a hit-stop ending, a resume, a scene sync): slow it again.
	if slow_motion != 1.0 and is_equal_approx(Engine.time_scale, 1.0):
		Engine.time_scale = slow_motion
	if instant_crank:
		_prime_crank()


## With interact held at a crank station, leaves the valve or the bypass one held moment from done,
## so Main's own crank this frame lands the last turn (its line, sound and seal or fuse).
func _prime_crank() -> void:
	var human: M0Actor = game.human
	if human == null or not human.controlled or not Input.is_action_pressed(&"interact"):
		return
	match game.debug_hold_station():
		&"valve":
			var line: PressureLine = game.pressure_line
			if line.state == &"building":
				line.turns = maxi(line.turns, PressureLine.TURNS_NEEDED - 1)
				line.progress = maxf(line.progress, PressureLine.TURN_SECONDS)
		&"bypass":
			var hold: HoldUse = game.hold_use
			if hold.station != &"bypass":
				hold.station = &"bypass"
				hold.ticks = 0
			hold.ticks = maxi(hold.ticks, BypassHandle.TICKS_NEEDED - 1)
			hold.progress = maxf(hold.progress, BypassHandle.TICK_SECONDS)


# --- Pausing for the menu and frame stepping ------------------------------------------------------

## Holds the game still like Pause does: held actions released, any hit-stop ended.
func hold_pause() -> void:
	for action: StringName in Main.GAMEPLAY_ACTIONS:
		Input.action_release(action)
	game.impact.end_hit_stop()
	get_tree().paused = true


## Holds the game still again after a jump or a reload while the menu is open or frame stepping is
## on: Main's own new game and load let the tree run, and with frame stepping nothing would pause it
## again until the next step (closing the menu leaves the pause as it finds it).
func _hold_if_stepping() -> void:
	if tools.menu_open or (frame_step and not _step_pending):
		get_tree().paused = true


## Lets the game run again unless the menu is open, frame stepping is on or the game's own Pause is up.
## With [param settle] false, a hit-stop, shake or flash an action from the menu just started (a forced
## knockdown's) plays on; the caller settles the ones from before the menu first (settle_impact).
func release_pause(settle: bool = true) -> void:
	if frame_step or tools.menu_open or game.pause_overlay.visible:
		return
	get_tree().paused = false
	# Like resuming from Pause: a dip or flash never outlasts the menu.
	if settle:
		settle_impact()
	game.debug_refresh_ui()


## Ends any hit-stop, shake and flash under way, as resuming from Pause does.
func settle_impact() -> void:
	game.impact.reset()


# --- Forcing ------------------------------------------------------------------------------------

## Why a knockdown cannot be forced now, or empty.
func knockdown_blocked() -> String:
	var why: String = _play_blocked()
	if not why.is_empty():
		return why
	if game.state.chapter_id != "junction":
		return "Knockdowns are the Service Junction's hazards."
	return ""


## Knocks the engineer down through the game's one knockdown path, with [param kind]'s own card
## (vent, blast, sentry or cloud), even while invincible; the beat's checkpoint comes back as usual.
func force_knockdown(kind: StringName) -> String:
	var why: String = knockdown_blocked()
	if not why.is_empty() or not KNOCKDOWNS.has(kind):
		return why
	tools.cheats_used = true
	_forcing = true
	game.debug_knock_down(kind)
	_forcing = false
	changed.emit()
	return "Forced the %s knockdown." % kind


## Why the door blast cannot be triggered now, or empty.
func blast_blocked() -> String:
	var why: String = knockdown_blocked()
	if not why.is_empty():
		return "The door blast is in the Service Junction." if why.begins_with("Knockdowns") else why
	if game.state.door_blown:
		return "The door is already down."
	if game.pressure_line.state in [&"charged", &"fuse", &"blown"]:
		return "The fuse is already lit."
	return ""


## Lights the junction door's fuse through the pressure line's own steps (armed if need be, then all
## three turns): the door goes PressureLine.FUSE_SECONDS later, and where the engineer stands then
## decides the outcome, as in play.
func trigger_blast() -> String:
	var why: String = blast_blocked()
	if not why.is_empty():
		return why
	var line: PressureLine = game.pressure_line
	if line.state != &"building":
		line.arm()
	line.crank(PressureLine.TURN_SECONDS * PressureLine.TURNS_NEEDED + PressureLine.EPSILON)
	game.debug_valve_turned()
	tools.cheats_used = true
	changed.emit()
	return "Fuse lit: the door goes %.1f s after play resumes." % PressureLine.FUSE_SECONDS


## Why the tank cannot be dropped now, or empty.
func drop_blocked() -> String:
	var why: String = knockdown_blocked()
	if not why.is_empty():
		return "The tank is in the Service Junction." if why.begins_with("Knockdowns") else why
	var state: M0State = game.state
	if not state.door_blown:
		return "The tank hangs past the door; blow the door first."
	if state.sentry_down:
		return "The tank is already down."
	if game.waiting_for_choice:
		return "Answer WOLF first."
	var arm: DropArm = game.drop_arm
	if arm.state != &"hung":
		return "The tank is %s; wait for the clamp." % arm.state
	return ""


## Lets the tank go through the TANK RELEASE's own drop, wherever the engineer is: it lands on the
## sentry only if the sentry is over the brackets when it lands, as in play.
func trigger_drop() -> String:
	var why: String = drop_blocked()
	if not why.is_empty():
		return why
	game.debug_drop_tank()
	tools.cheats_used = true
	changed.emit()
	return "The clamp lets go."


func _play_blocked() -> String:
	if game.title_open or game.intro_active:
		return "Start play first (jump to a beat)."
	if game.chapter_close_active or game.end_card_active:
		return "Not during a closing scene."
	if game.fail_active:
		return "A knockdown is already playing."
	return ""


# --- Saves --------------------------------------------------------------------------------------

## Why the game cannot be saved now, or empty.
func save_blocked() -> String:
	var why: String = _play_blocked()
	if not why.is_empty():
		return why
	if not game.state.checkpoint_reached:
		return Main.NO_CHECKPOINT_NOTE
	return ""


## Writes the current beat as the checkpoint, through the game's own autosave.
func save_now() -> String:
	var why: String = save_blocked()
	if not why.is_empty():
		return why
	game.debug_save_progress()
	return Main.SAVE_FAILED_HINT if game.save_pending else Main.CHECKPOINT_TOAST


## True when the save on disk holds a checkpoint Continue can load (read without side effects).
func has_checkpoint() -> bool:
	return not (str(tools.save_info(true).get("checkpoint", "none")) in ["none", "unreadable"])


## Back to the checkpoint on disk, as the title's Continue does.
func reload_checkpoint() -> String:
	if not has_checkpoint():
		return Main.UNREADABLE_CHECKPOINT_NOTE if FileAccess.file_exists(game.save_path) else "No checkpoint to reload."
	game.debug_load_checkpoint()
	_hold_if_stepping()
	changed.emit()
	return Main.RESTORE_FROM_DISK_LINE


## Deletes the checkpoint and its temporary copy (AtomicFile.temp_path); the title's buttons follow.
## Returns the note the SAVE page shows, naming what was actually removed: the checkpoint, only a
## leftover temporary copy, nothing, or a file that would not go (so a failed delete never reads as done).
func clear_save() -> String:
	var path: String = game.save_path
	var removed: Array[String] = []
	var stuck: bool = false
	for file: String in [path, AtomicFile.temp_path(path)]:
		if FileAccess.file_exists(file):
			if DirAccess.remove_absolute(ProjectSettings.globalize_path(file)) == OK:
				removed.append(file)
			else:
				stuck = true
	game.debug_save_changed()
	changed.emit()
	if stuck:
		return "A save file could not be deleted."
	if removed.has(path):
		return "Checkpoint deleted."
	return "Leftover temporary save deleted." if not removed.is_empty() else "No checkpoint on disk."


# --- Effect switches ----------------------------------------------------------------------------

## Main's one switch for the visual effects (depth pass, glows, reflections, grade and the impact kit).
func set_effects(on: bool) -> String:
	if _effects_before == null:
		_effects_before = game.effects_enabled
	effects_on = on
	game.effects_enabled = on
	changed.emit()
	return "Visual effects %s." % ("on" if on else "off")


func set_shake(on: bool) -> String:
	shake_on = on
	game.impact.shake_enabled = on
	changed.emit()
	return "Camera shake %s." % ("on" if on else "off")


func set_flash(on: bool) -> String:
	flash_on = on
	game.impact.flash_enabled = on
	changed.emit()
	return "Screen flashes %s." % ("on" if on else "off")


## Everything back as play has it (the tools were locked or hidden): no cheats, full speed, no frame
## stepping, the effects as they were before the menu changed them. The presets are kept.
func reset_all() -> void:
	invincible = false
	sentry_frozen = false
	instant_crank = false
	if slow_motion != 1.0:
		slow_motion = 1.0
		Engine.time_scale = 1.0
	if frame_step:
		frame_step = false
		frames_stepped = 0
		release_pause()
	if stepper != null:
		stepper.set_process(false)
	_step_pending = false
	if _effects_before != null:
		game.effects_enabled = bool(_effects_before)
		_effects_before = null
	effects_on = game.effects_enabled
	shake_on = true
	flash_on = true
	var impact: Impact = game.impact
	if impact != null:
		impact.shake_enabled = true
		impact.flash_enabled = true
	_update_processing()
	changed.emit()


## The cheats, presets and switches as plain values, for the overlay and every dump.
func info() -> Dictionary:
	return {
		"invincible": invincible,
		"sentry_frozen": sentry_frozen,
		"instant_crank": instant_crank,
		"slow_motion": slow_motion,
		"frame_step": frame_step,
		"frames_stepped": frames_stepped,
		"presets": {"relay": String(relay), "mirror": String(mirror), "lane": String(lane)},
		"effects": {"visual": effects_on, "shake": shake_on, "flash": flash_on},
	}

