extends SceneTree
## Blowback beats 4-6: the sentry brain and the drop arm as pure logic, the junction's later guards
## and saves, and the scene routes past the door (WOLF draws the sentry; the engineer times the drop
## alone after WOLF refuses; a miss with its cloud and rewind; sentry and cloud knockdowns back to
## autosave B; the exit bolt, the closing beat and Continue from B, C and D).

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const State = preload("res://scripts/m0_state.gd")
const MainScript = preload("res://scripts/main.gd")
## How far WOLF's painted body stays from the hung tank's on his way down the lane, in px.
const TANK_CLEARANCE: float = 3.0
## The bound over the crushed tank (_check_tank_leap_shape): its steepest rise or fall in px up per px
## along, how far along it stays within 2 px of its top, and how far short of his spot it lands.
const TANK_LEAP_MAX_SLOPE: float = 1.4
const TANK_LEAP_TOP_SPAN: float = 60.0
const TANK_LEAP_LANDING: float = 20.0

var failures: int = 0
var _wolf_pixel_cache: Dictionary = {}
## The lane watch (_watch_lane): frames looked at in the junction, and what read false on them.
var lane_frames: int = 0
var lane_beam_frames: int = 0
var lane_faults: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_brain()
	_check_arm()
	_check_drop_window()
	_check_state_guards()
	await _check_scene()
	if failures == 0:
		print("Sentry checks passed")
	quit(1 if failures > 0 else 0)


func _check_brain() -> void:
	for x: float in [SentryBrain.LANE_ENTRY_X, SentryBrain.COVER_MIN_X, JunctionRoom.ARM_X, SentryBrain.COVER_MAX_X, 500.0]:
		_expect(not SentryBrain.is_exposed(x), "%.0f is out of the sentry's sight" % x)
	for x: float in [SentryBrain.COVER_MAX_X + 1.0, 640.0, 700.0]:
		_expect(SentryBrain.is_exposed(x), "%.0f is exposed in the lane" % x)
	# The alcove starts at the rubble line: no strip between the two where the sentry can see you.
	var strip_hidden: bool = true
	var strip_x: float = SentryBrain.LANE_ENTRY_X
	while strip_x <= SentryBrain.COVER_MAX_X:
		strip_hidden = strip_hidden and not SentryBrain.is_exposed(strip_x)
		strip_x += 0.5
	_expect(SentryBrain.COVER_MIN_X == SentryBrain.LANE_ENTRY_X and strip_hidden, "from the rubble line to the alcove's right end nobody is seen")
	_expect(JunctionRoom.alcove_rect().position.x == SentryBrain.COVER_MIN_X and JunctionRoom.alcove_rect().end.x == SentryBrain.COVER_MAX_X, "the drawn alcove is exactly the span that hides the engineer")
	_expect(JunctionRoom.RUBBLE_X == SentryBrain.RUBBLE_X and JunctionRoom.CHOICE_X < SentryBrain.LANE_ENTRY_X, "the rubble line is the lane boundary and the question comes up before it")
	var brain: SentryBrain = SentryBrain.new()
	_expect(brain.state == &"dormant" and brain.tick(1.0, 700.0, true, -1.0) == &"dormant" and brain.x == SentryBrain.PATROL_MAX_X, "a dormant sentry neither moves nor sees")
	_expect(brain.wake() and brain.state == &"patrol" and not brain.wake(), "the blast wakes it once")
	brain.tick(1.0, 100.0, false, -1.0)
	_expect(is_equal_approx(brain.x, 700.0) and brain.facing < 0.0, "patrol runs left from the far end at 140 px/s")
	brain.tick(1.0, 100.0, false, -1.0)
	_expect(is_equal_approx(brain.x, SentryBrain.PATROL_MIN_X * 2.0 - 560.0) and brain.facing > 0.0, "it bounces off its near end and comes back")
	_expect(is_equal_approx(SentryBrain.PATROL_MIN_X - SentryBrain.DRAWN_HALF_WIDTH, SentryBrain.COVER_MAX_X + M0Actor.HUMAN_REACH), "the patrol turns where its drawn front meets an engineer drawn at the alcove's right end")
	_expect(SentryBrain.DRAWN_HALF_WIDTH >= Sentry.drawn_half_width() and SentryBrain.DRAWN_HALF_WIDTH - Sentry.drawn_half_width() < 1.0, "the rule's drawn half width is the painted machine's, rounded up (%.2f)" % Sentry.drawn_half_width())
	_expect(SentryBrain.PATROL_MIN_X < DropArm.MARK_X and SentryBrain.PATROL_MAX_X > DropArm.MARK_X + DropArm.HIT_REACH, "the patrol crosses the mark and leaves the hit window at its far end on every pass")
	var sliced: SentryBrain = _patrolling_at(SentryBrain.PATROL_MAX_X, -1.0)
	var whole: SentryBrain = _patrolling_at(SentryBrain.PATROL_MAX_X, -1.0)
	var lowest: float = INF
	var highest: float = -INF
	for _frame: int in 600:
		sliced.tick(5.0 / 600.0, 100.0, false, -1.0)
		lowest = minf(lowest, sliced.x)
		highest = maxf(highest, sliced.x)
	whole.tick(5.0, 100.0, false, -1.0)
	_expect(absf(sliced.x - whole.x) < 0.01 and sliced.facing == whole.facing, "sliced and whole deltas land on the same patrol position")
	_expect(lowest >= SentryBrain.PATROL_MIN_X - 0.01 and highest <= SentryBrain.PATROL_MAX_X + 0.01, "patrol stays inside its range")
	for cover_x: float in [SentryBrain.COVER_MIN_X, JunctionRoom.ARM_X, SentryBrain.COVER_MAX_X]:
		_expect(lowest - cover_x > SentryBrain.CONTACT_RANGE - 0.01, "a patrolling sentry never runs into an engineer hidden at %.0f" % cover_x)
	# Detection: only in the lane, only ahead (or touching), never in the alcove. Seeing someone starts
	# the lock-on beat, never the chase itself.
	_expect(_patrolling_at(700.0, -1.0).tick(0.001, 600.0, true, -1.0) == &"lock", "an exposed engineer ahead inside its sight is seen")
	_expect(_patrolling_at(840.0, -1.0).tick(0.001, 665.0, true, -1.0) == &"lock", "175 px ahead is inside its sight")
	_expect(_patrolling_at(840.0, -1.0).tick(0.001, 650.0, true, -1.0) == &"patrol", "190 px ahead is past its sight")
	_expect(_patrolling_at(700.0, -1.0).tick(0.001, JunctionRoom.ARM_X, SentryBrain.is_exposed(JunctionRoom.ARM_X), -1.0) == &"patrol", "the alcove hides the engineer")
	_expect(_patrolling_at(700.0, -1.0).tick(0.001, 760.0, true, -1.0) == &"patrol", "behind it and out of reach is unseen")
	_expect(_patrolling_at(700.0, -1.0).tick(0.001, 720.0, true, -1.0) == &"lock", "walking into it from behind is noticed")
	_expect(_patrolling_at(620.0, -1.0).tick(0.001, 530.0, false, -1.0) == &"patrol", "an engineer back over the rubble is never seen")
	_check_lock_on()
	# Chase.
	var chaser: SentryBrain = _patrolling_at(700.0, -1.0)
	chaser.tick(0.001, 600.0, true, -1.0)
	chaser.tick(SentryBrain.LOCK_SECONDS, 600.0, true, -1.0)
	var start_x: float = chaser.x
	chaser.tick(0.1, 600.0, true, -1.0)
	_expect(is_equal_approx(start_x - chaser.x, SentryBrain.CHASE_SPEED * 0.1), "a chase closes at 230 px/s")
	_expect(not chaser.touches(600.0) or absf(chaser.x - 600.0) <= SentryBrain.CONTACT_RANGE, "contact needs the bodies to meet")
	chaser.tick(5.0, SentryBrain.LANE_ENTRY_X + 1.0, true, -1.0)
	_expect(chaser.state == &"chase" and chaser.x == SentryBrain.CHASE_MIN_X and chaser.x > SentryBrain.RUBBLE_X, "it never comes past its rubble stop")
	_expect(chaser.touches(JunctionRoom.ARM_X) and chaser.touches(SentryBrain.COVER_MIN_X + 1.0), "a chasing sentry reaches an engineer anywhere in the alcove")
	_expect(not chaser.touches(SentryBrain.RUBBLE_X), "an engineer back on the rubble line is out of its reach")
	chaser.tick(0.5, 500.0, false, -1.0)
	_expect(chaser.state == &"chase" and chaser.x == SentryBrain.WATCH_X and chaser.x - SentryBrain.HALF_WIDTH > SentryBrain.COVER_MAX_X, "with the engineer back over the rubble it waits at the alcove's mouth, its body clear of the alcove")
	chaser.tick(1.5, 500.0, false, -1.0)
	chaser.tick(0.1, 560.0, false, -1.0)
	chaser.tick(2.0, 500.0, false, -1.0)
	_expect(chaser.state == &"chase", "stepping back into the lane restarts the 2.5 s it needs to give up")
	chaser.tick(0.4, 500.0, false, -1.0)
	_expect(chaser.state == &"chase", "2.4 s back over the rubble it is still after the engineer")
	chaser.tick(0.1, 500.0, false, -1.0)
	_expect(chaser.state == &"patrol", "2.5 s back over the rubble and it gives up")
	var parked_x: float = chaser.x
	chaser.tick(0.02, 500.0, false, -1.0)
	_expect(chaser.facing > 0.0 and is_equal_approx(chaser.x - parked_x, SentryBrain.PATROL_SPEED * 0.02), "after a chase it turns and walks back into its patrol instead of jumping")
	var walk_back_sliced: SentryBrain = _patrolling_at(SentryBrain.CHASE_MIN_X, -1.0)
	var walk_back_whole: SentryBrain = _patrolling_at(SentryBrain.CHASE_MIN_X, -1.0)
	for _frame: int in 300:
		walk_back_sliced.tick(3.0 / 300.0, 500.0, false, -1.0)
	walk_back_whole.tick(3.0, 500.0, false, -1.0)
	_expect(absf(walk_back_sliced.x - walk_back_whole.x) < 0.01 and walk_back_sliced.facing == walk_back_whole.facing, "walking back in lands the same with sliced and whole deltas")
	_expect(not _patrolling_at(700.0, -1.0).touches(700.0), "a patrolling sentry is not contact")
	# Fixated on WOLF.
	var fixated: SentryBrain = _patrolling_at(SentryBrain.PATROL_MAX_X, -1.0)
	_expect(fixated.tick(0.1, 100.0, false, JunctionRoom.WOLF_BAIT_X) == &"fixated", "WOLF drawing it fixates it")
	fixated.tick(2.0, 100.0, false, JunctionRoom.WOLF_BAIT_X)
	_expect(is_equal_approx(fixated.x, JunctionRoom.WOLF_BAIT_X - SentryBrain.BAIT_OFFSET) and is_equal_approx(fixated.x, DropArm.MARK_X) and fixated.facing > 0.0, "it parks just short of WOLF, on the floor mark, facing him with its back to the release")
	fixated.tick(1.0, 600.0, true, JunctionRoom.WOLF_BAIT_X)
	_expect(fixated.state == &"fixated" and is_equal_approx(fixated.x, DropArm.MARK_X), "an engineer elsewhere in the lane does not break its hold")
	_expect(fixated.x + SentryBrain.HALF_WIDTH <= JunctionRoom.WOLF_BAIT_X - M0State.WOLF_HALF_WIDTH, "the parked sentry does not overlap WOLF")
	_expect(JunctionRoom.WOLF_BAIT_X - M0Actor.WOLF_REACH > DropArm.MARK_X + JunctionRoom.TANK_SIZE.x * 0.5, "all of WOLF's drawn body stands clear of the tank's footprint")
	_expect(JunctionRoom.WOLF_BAIT_X - M0Actor.WOLF_REACH - 2.0 > DropArm.MARK_X + DropArm.HIT_RANGE, "all of WOLF's drawn body stands outside the floor brackets")
	_expect(JunctionRoom.WOLF_BAIT_X - M0Actor.WOLF_REACH > fixated.x + SentryBrain.HALF_WIDTH, "WOLF's drawn body stops short of the parked sentry")
	# Round 3 item 2: the sentry is drawn to WOLF, so the order along the lane is release, sentry, WOLF:
	# the engineer working the release is behind the parked sentry, never between it and WOLF.
	_expect(JunctionRoom.ARM_X < SentryBrain.COVER_MAX_X and SentryBrain.COVER_MAX_X < fixated.x - SentryBrain.HALF_WIDTH and fixated.x < JunctionRoom.WOLF_BAIT_X, "the parked sentry stands between the release alcove and WOLF, so WOLF is the one it is drawn to")
	_expect(JunctionRoom.WOLF_BAIT_X - M0Actor.WOLF_REACH > SentryBrain.COVER_MAX_X + M0Actor.HUMAN_REACH and JunctionRoom.WOLF_BAIT_X > JunctionRoom.WOLF_RUBBLE_X, "WOLF's drawn body stays clear of the engineer at the TANK RELEASE, and drawing it is a move he is seen to make")
	var wolf_art: Vector2 = _wolf_art_reach()
	# Facing back down the lane his snout is the art's front and his tail its back, mirrored.
	_expect(JunctionRoom.WOLF_BAIT_X + wolf_art.x <= 960.0, "at the far end of the lane all of WOLF's painted body is inside the room (tail at %.1f)" % (JunctionRoom.WOLF_BAIT_X + wolf_art.x))
	var bolt_panel_right: float = JunctionRoom.BOLT_PANEL_X + JunctionRoom.BOLT_PANEL_HALF_WIDTH
	_expect(JunctionRoom.WOLF_BAIT_X - wolf_art.y >= bolt_panel_right - M0Actor.AVOID_TOLERANCE, "his painted snout stops at the exit bolt panel's right edge (snout %.1f, panel %.1f)" % [JunctionRoom.WOLF_BAIT_X - wolf_art.y, bolt_panel_right])
	_expect(JunctionRoom.WOLF_DOWN_X - M0Actor.WOLF_REACH > DropArm.MARK_X + JunctionRoom.TANK_SIZE.x * 0.5 + SentryBrain.HALF_WIDTH, "once it is down WOLF waits clear of the tank and the wreck under it")
	_check_bait_walk()
	var from_left: SentryBrain = _patrolling_at(SentryBrain.PATROL_MIN_X, 1.0)
	from_left.tick(2.0, 100.0, false, JunctionRoom.WOLF_BAIT_X)
	_expect(is_equal_approx(from_left.x, DropArm.MARK_X), "it parks on the mark from either side")
	_expect(fixated.tick(0.001, 690.0, true, JunctionRoom.WOLF_BAIT_X) == &"lock", "walking into a fixated sentry breaks its hold")
	_expect(fixated.tick(SentryBrain.LOCK_SECONDS, 690.0, true, JunctionRoom.WOLF_BAIT_X) == &"chase" and fixated.touches(690.0), "after the lock-on beat it runs down whoever walked into it")
	var released: SentryBrain = _patrolling_at(SentryBrain.PATROL_MAX_X, -1.0)
	released.tick(0.1, 100.0, false, JunctionRoom.WOLF_BAIT_X)
	_expect(released.tick(0.1, 100.0, false, -1.0) == &"patrol", "when WOLF stops drawing it, it patrols again")
	# Holding: only a fixated sentry stopped on its hold point (the mark) counts.
	var arriving: SentryBrain = _patrolling_at(SentryBrain.PATROL_MAX_X, -1.0)
	arriving.tick(0.1, 100.0, false, JunctionRoom.WOLF_BAIT_X)
	_expect(arriving.state == &"fixated" and not arriving.is_holding(JunctionRoom.WOLF_BAIT_X), "a fixated sentry still on its way in is not holding")
	arriving.tick(2.0, 100.0, false, JunctionRoom.WOLF_BAIT_X)
	_expect(arriving.is_holding(JunctionRoom.WOLF_BAIT_X) and arriving.x == DropArm.MARK_X, "stopped on the mark it is holding")
	_expect(not _patrolling_at(DropArm.MARK_X, -1.0).is_holding(JunctionRoom.WOLF_BAIT_X), "a patrolling sentry crossing the mark is not holding")
	_check_keeps_distance()
	_check_obstacle()
	# Down and paused.
	var down: SentryBrain = _patrolling_at(700.0, -1.0)
	_expect(down.knock_down() and not down.knock_down() and not down.wake() and not down.alert(), "the tank downs it once and nothing wakes it")
	_expect(down.tick(1.0, 700.0, true, JunctionRoom.WOLF_BAIT_X) == &"down" and down.x == 700.0 and not down.touches(700.0), "a downed sentry ignores everything")
	var paused: SentryBrain = _patrolling_at(700.0, -1.0)
	paused.paused = true
	_expect(paused.tick(1.0, 600.0, true, JunctionRoom.WOLF_BAIT_X) == &"patrol" and paused.x == 700.0, "a paused sentry neither moves nor sees")
	var alerted: SentryBrain = _patrolling_at(800.0, -1.0)
	_expect(alerted.alert() and alerted.state == &"lock" and alerted.x == 800.0, "a missed drop turns it on the engineer, locking on first")
	alerted.tick(0.2, SentryBrain.COVER_MIN_X, false, -1.0)
	_expect(alerted.alert() and alerted.state == &"lock" and is_equal_approx(alerted.lock_remaining, SentryBrain.LOCK_SECONDS - 0.2), "a second alert does not restart the beat")
	alerted.tick(SentryBrain.LOCK_SECONDS, SentryBrain.COVER_MIN_X, false, -1.0)
	_expect(alerted.state == &"chase" and alerted.alert() and alerted.state == &"chase", "once the beat is over it chases, and an alert keeps it chasing")
	_expect(alerted.turned_by_miss, "a chase a missed drop started stays marked as one, through the lock-on beat and a second alert")
	alerted.tick(SentryBrain.LOSE_SECONDS, SentryBrain.RUBBLE_X, false, -1.0)
	_expect(alerted.state == &"patrol" and not alerted.turned_by_miss, "losing the engineer behind the rubble clears the mark")
	# Seen first: the chase is the sentry's own, and a miss during it does not relabel it.
	var spotter: SentryBrain = _patrolling_at(700.0, -1.0)
	spotter.tick(0.001, 640.0, true, -1.0)
	_expect(spotter.state == &"lock" and not spotter.turned_by_miss, "a sentry that sees the engineer is not marked as turned by a miss")
	_expect(spotter.alert() and not spotter.turned_by_miss, "a miss during its own lock-on beat leaves it unmarked")
	spotter.tick(SentryBrain.LOCK_SECONDS, 640.0, true, -1.0)
	_expect(spotter.state == &"chase" and spotter.alert() and not spotter.turned_by_miss, "nor does a miss during its own chase")
	alerted.alert()
	alerted.reset(true, false, DropArm.MARK_X)
	_expect(not alerted.turned_by_miss, "reset clears the mark")
	_expect(alerted.state == &"patrol" and alerted.x == SentryBrain.PATROL_MAX_X and alerted.facing < 0.0, "reset after the blast patrols from the far end")
	alerted.reset(false, false, DropArm.MARK_X)
	_expect(alerted.state == &"dormant", "reset before the blast is dormant")
	alerted.reset(true, true, DropArm.MARK_X)
	_expect(alerted.state == &"down" and alerted.x == DropArm.MARK_X, "reset after the drop lies on the mark")


## Round 3b: drawn while WOLF is still coming down the lane behind it (watch_x), the sentry never closes
## on him: it turns to him and holds, or backs off to stay BAIT_OFFSET ahead of him, as far as the end
## of its patrol, so he catches it there and bounds over it right of the hanging tank. It is not
## holding (the drop waits) until he is past it; then it parks on the mark facing him. With WOLF
## holding the far end without drawing it (far_x), its patrol turns short of him.
func _check_keeps_distance() -> void:
	var wary: SentryBrain = _patrolling_at(DropArm.MARK_X, 1.0)
	wary.watch_x = JunctionRoom.WOLF_RUBBLE_X + 40.0
	_expect(wary.tick(0.5, 100.0, false, JunctionRoom.WOLF_BAIT_X) == &"fixated" and wary.x >= DropArm.MARK_X - 0.01 and wary.facing < 0.0, "drawn with WOLF still behind it, it turns to face him and does not close on him (x %.1f)" % wary.x)
	_expect(not wary.is_holding(JunctionRoom.WOLF_BAIT_X) and wary.wolf_ahead(), "nor is it holding while he is still coming")
	var gap_kept: bool = true
	var crossed_mark_holding: bool = false
	var wolf_x: float = JunctionRoom.WOLF_RUBBLE_X + 40.0
	for _frame: int in 120:
		var before: float = wary.x
		wolf_x = minf(wolf_x + M0Actor.FOLLOW_SPEED / 60.0, SentryBrain.PATROL_MAX_X - 120.0)
		wary.watch_x = wolf_x
		wary.tick(1.0 / 60.0, 100.0, false, JunctionRoom.WOLF_BAIT_X)
		gap_kept = gap_kept and wary.x >= before - 0.001 and wary.x - wolf_x >= minf(SentryBrain.BAIT_OFFSET, SentryBrain.PATROL_MAX_X - wolf_x) - 4.0 and wary.facing < 0.0
		crossed_mark_holding = crossed_mark_holding or wary.is_holding(JunctionRoom.WOLF_BAIT_X)
	_expect(gap_kept and not crossed_mark_holding, "as he comes on it backs off ahead of him, still facing him, and is never holding on the way")
	_expect(is_equal_approx(wary.x, SentryBrain.PATROL_MAX_X), "it backs off as far as the end of its patrol and waits there for him (x %.1f)" % wary.x)
	wary.watch_x = SentryBrain.PATROL_MAX_X + 1.0
	wary.tick(0.05, 100.0, false, JunctionRoom.WOLF_BAIT_X)
	_expect(wary.x < SentryBrain.PATROL_MAX_X and wary.facing > 0.0, "once he is past it, it turns to him and gives way toward the mark")
	wary.watch_x = JunctionRoom.WOLF_BAIT_X
	wary.tick(2.0, 100.0, false, JunctionRoom.WOLF_BAIT_X)
	_expect(is_equal_approx(wary.x, DropArm.MARK_X) and wary.facing > 0.0 and wary.is_holding(JunctionRoom.WOLF_BAIT_X), "then it parks on the mark facing him, and holds")
	var near_start: SentryBrain = _patrolling_at(SentryBrain.PATROL_MIN_X, -1.0)
	near_start.watch_x = JunctionRoom.WOLF_RUBBLE_X + 40.0
	near_start.tick(0.1, 100.0, false, JunctionRoom.WOLF_BAIT_X)
	_expect(near_start.x >= SentryBrain.PATROL_MIN_X - 0.01, "drawn from the near end of its patrol it still never comes toward him")
	# WOLF holding the far end after breaking off: the patrol turns short of him.
	var held_off: SentryBrain = _patrolling_at(SentryBrain.PATROL_MIN_X, 1.0)
	held_off.far_x = 805.0
	var lowest: float = INF
	var highest: float = -INF
	for _frame: int in 600:
		held_off.tick(1.0 / 60.0, 100.0, false, -1.0)
		lowest = minf(lowest, held_off.x)
		highest = maxf(highest, held_off.x)
	_expect(highest <= 805.01 and highest >= 800.0 and highest > DropArm.MARK_X + DropArm.HIT_REACH and lowest < DropArm.MARK_X, "with WOLF holding the far end its patrol turns short of him and still crosses the mark and the whole far side of the hit window (%.1f..%.1f)" % [lowest, highest])
	var outside: SentryBrain = _patrolling_at(SentryBrain.PATROL_MAX_X, 1.0)
	outside.far_x = 805.0
	outside.tick(0.1, 100.0, false, -1.0)
	_expect(outside.x < SentryBrain.PATROL_MAX_X and is_equal_approx(SentryBrain.PATROL_MAX_X - outside.x, SentryBrain.PATROL_SPEED * 0.1) and outside.facing < 0.0, "past that turn already, it walks back in at patrol speed rather than jump")


## Round 3 item 1: a missed tank lying in the lane (DropArm.footprint while DropArm.blocks_lane) stops
## the sentry at its edge on the side it came from; it never drives into or through it, chasing or
## patrolling, and goes on once the tank is up.
func _check_obstacle() -> void:
	var footprint: Vector2 = DropArm.footprint()
	_expect(is_equal_approx(footprint.x, DropArm.MARK_X - DropArm.HIT_RANGE) and is_equal_approx(footprint.y, DropArm.MARK_X + DropArm.HIT_RANGE), "the tank's footprint is the floor brackets")
	var chaser: SentryBrain = _patrolling_at(800.0, -1.0)
	chaser.alert()
	chaser.obstacle = footprint
	chaser.tick(SentryBrain.LOCK_SECONDS + 2.0, JunctionRoom.ARM_X, false, -1.0)
	_expect(chaser.state == &"chase" and is_equal_approx(chaser.x - SentryBrain.HALF_WIDTH, footprint.y), "a chase from the far side stops with its body at the tank's edge (x %.1f)" % chaser.x)
	var sliced: SentryBrain = _patrolling_at(800.0, -1.0)
	sliced.alert()
	sliced.obstacle = footprint
	var nearest: float = INF
	for _frame: int in 150:
		sliced.tick(1.0 / 60.0, JunctionRoom.ARM_X, false, -1.0)
		nearest = minf(nearest, sliced.x - SentryBrain.HALF_WIDTH)
	_expect(nearest >= footprint.y - 0.01, "frame by frame its body never enters the tank (nearest edge %.1f)" % nearest)
	chaser.obstacle = Vector2.ZERO
	chaser.tick(0.5, JunctionRoom.ARM_X, false, -1.0)
	_expect(chaser.x < footprint.x, "once the tank is up it carries on past the mark")
	var grazed: SentryBrain = _patrolling_at(DropArm.MARK_X + DropArm.HIT_REACH + 1.0, -1.0)
	grazed.alert()
	grazed.obstacle = footprint
	var grazed_x: float = grazed.x
	grazed.tick(SentryBrain.LOCK_SECONDS + 1.0, JunctionRoom.ARM_X, false, -1.0)
	_expect(grazed.x == grazed_x, "a sentry the missed tank grazed holds where it stands rather than drive further under it")
	var from_left: SentryBrain = _patrolling_at(SentryBrain.PATROL_MIN_X, 1.0)
	from_left.obstacle = footprint
	from_left.tick(1.0, 100.0, false, -1.0)
	_expect(from_left.x <= SentryBrain.PATROL_MIN_X + 0.01 and from_left.facing < 0.0, "a patrol coming from the near side turns back at the tank instead of driving further into it")
	var left_chaser: SentryBrain = _patrolling_at(640.0, 1.0)
	left_chaser.alert()
	left_chaser.obstacle = footprint
	left_chaser.tick(SentryBrain.LOCK_SECONDS + 1.0, 820.0, true, -1.0)
	_expect(left_chaser.state == &"chase" and is_equal_approx(left_chaser.x + SentryBrain.HALF_WIDTH, footprint.x), "a chase from the near side stops with its body at the tank's other edge (x %.1f)" % left_chaser.x)
	var from_right: SentryBrain = _patrolling_at(SentryBrain.PATROL_MAX_X, -1.0)
	from_right.obstacle = footprint
	from_right.tick(1.0, 100.0, false, -1.0)
	_expect(from_right.x - SentryBrain.HALF_WIDTH >= footprint.y - 0.01 and from_right.facing > 0.0, "and so does one coming from the far side")
	from_right.reset(true, false, DropArm.MARK_X)
	_expect(from_right.obstacle == Vector2.ZERO, "a restore clears the lane")


## The lock-on beat: seeing the engineer stops the sentry for LOCK_SECONDS, turned to them, before
## the chase; it cannot run anyone down until then.
func _check_lock_on() -> void:
	_expect(SentryBrain.LOCK_SECONDS >= 0.4 and SentryBrain.LOCK_SECONDS <= 0.6, "the lock-on beat lasts about half a second")
	var locking: SentryBrain = _patrolling_at(700.0, -1.0)
	locking.tick(0.001, 600.0, true, -1.0)
	var seen_x: float = locking.x
	_expect(is_equal_approx(seen_x, 700.0 - SentryBrain.PATROL_SPEED * 0.001) and is_equal_approx(locking.lock_remaining, SentryBrain.LOCK_SECONDS), "it locks on where it saw the engineer")
	locking.tick(SentryBrain.LOCK_SECONDS - 0.01, 600.0, true, -1.0)
	_expect(locking.state == &"lock" and locking.x == seen_x and not locking.touches(600.0), "through the beat it stands still and is not contact")
	locking.tick(0.01, 600.0, true, -1.0)
	_expect(locking.state == &"chase" and locking.x == seen_x, "at the end of the beat the chase starts from where it stood")
	# From the far end, so the chase after the beat has room before it reaches the engineer.
	var sliced: SentryBrain = _patrolling_at(SentryBrain.PATROL_MAX_X, -1.0)
	var whole: SentryBrain = _patrolling_at(SentryBrain.PATROL_MAX_X, -1.0)
	sliced.tick(0.001, 680.0, true, -1.0)
	whole.tick(0.001, 680.0, true, -1.0)
	var far_seen_x: float = whole.x
	for _frame: int in 48:
		sliced.tick(1.0 / 60.0, 680.0, true, -1.0)
	whole.tick(0.8, 680.0, true, -1.0)
	_expect(sliced.state == &"chase" and whole.state == &"chase" and absf(sliced.x - whole.x) < 0.01, "sliced and whole deltas leave the beat and chase alike (%.2f vs %.2f)" % [sliced.x, whole.x])
	_expect(is_equal_approx(far_seen_x - whole.x, SentryBrain.CHASE_SPEED * (0.8 - SentryBrain.LOCK_SECONDS)), "0.8 s after seeing the engineer it has chased only for the time after the beat")
	# P0-16: it runs at the engineer and stops where the drawn bodies touch, never into them.
	whole.tick(2.0, 680.0, true, -1.0)
	_expect(is_equal_approx(whole.x, 680.0 + SentryBrain.CONTACT_RANGE) and whole.touches(680.0) and whole.facing < 0.0, "the chase stops at contact range, facing the engineer (%.1f)" % whole.x)
	whole.tick(0.1, 680.0 + SentryBrain.CONTACT_RANGE - 3.0, true, -1.0)
	_expect(is_equal_approx(whole.x, 680.0 + SentryBrain.CONTACT_RANGE) and whole.facing < 0.0, "an engineer who steps closer is not backed away from")
	var behind: SentryBrain = _patrolling_at(700.0, -1.0)
	behind.tick(0.001, 720.0, true, -1.0)
	behind.tick(0.1, 720.0, true, -1.0)
	_expect(behind.state == &"lock" and behind.facing > 0.0, "locking on to someone behind it, it turns to face them")
	var touching: SentryBrain = _patrolling_at(700.0, -1.0)
	touching.tick(0.001, 700.0, true, -1.0)
	_expect(touching.state == &"lock" and not touching.touches(700.0), "an engineer touching it is not run down during the beat")
	var held: SentryBrain = _patrolling_at(700.0, -1.0)
	held.tick(0.001, 600.0, true, -1.0)
	held.paused = true
	held.tick(1.0, 600.0, true, -1.0)
	_expect(held.state == &"lock" and is_equal_approx(held.lock_remaining, SentryBrain.LOCK_SECONDS), "a paused sentry holds its beat")
	held.paused = false
	_expect(held.knock_down() and held.state == &"down", "the tank can land on it mid-beat")
	var restored: SentryBrain = _patrolling_at(700.0, -1.0)
	restored.tick(0.001, 600.0, true, -1.0)
	restored.reset(true, false, DropArm.MARK_X)
	_expect(restored.state == &"patrol" and restored.lock_remaining == 0.0, "a restore drops the beat")
	var dropped: SentryBrain = _patrolling_at(700.0, -1.0)
	dropped.tick(0.001, 600.0, true, -1.0)
	_expect(dropped.tick(SentryBrain.LOCK_SECONDS, 500.0, false, -1.0) == &"chase", "an engineer who gets back over the rubble during the beat is still chased")
	dropped.tick(SentryBrain.LOSE_SECONDS, 500.0, false, -1.0)
	_expect(dropped.state == &"patrol", "and it gives up the usual 2.5 s later")


func _check_arm() -> void:
	# One rule the floor shows: the brackets are the tank's footprint, and a hit is the sentry's body
	# over them when the tank lands.
	_expect(absf(DropArm.HIT_RANGE - JunctionRoom.TANK_SIZE.x * 0.5) <= 1.0, "the floor brackets are as wide as the tank")
	var edge_overlap: float = (DropArm.MARK_X + DropArm.HIT_RANGE) - (DropArm.MARK_X + DropArm.HIT_REACH - SentryBrain.HALF_WIDTH)
	_expect(is_equal_approx(edge_overlap, DropArm.GRAZE_OVERLAP) and is_equal_approx(DropArm.GRAZE_OVERLAP, SentryBrain.HALF_WIDTH * 0.5), "at the edge of the hit window a quarter of the sentry's body is over the brackets: a graze counts (%.0f px)" % edge_overlap)
	_expect(DropArm.is_hit(DropArm.MARK_X - DropArm.HIT_REACH) and DropArm.is_hit(DropArm.MARK_X + DropArm.HIT_REACH) and not DropArm.is_hit(DropArm.MARK_X - DropArm.HIT_REACH - 1.0) and not DropArm.is_hit(DropArm.MARK_X + DropArm.HIT_REACH + 1.0), "the hit window is a quarter or more of the sentry's body over the brackets")
	_expect(DropArm.is_hit(DropArm.MARK_X + DropArm.HIT_RANGE) and DropArm.is_hit(DropArm.MARK_X - DropArm.HIT_RANGE), "a sentry centred on a bracket, half its body under the tank, is a hit")
	_expect(JunctionRoom.tank_rests_on_wreck(DropArm.MARK_X + DropArm.HIT_RANGE) and JunctionRoom.tank_rests_on_wreck(DropArm.MARK_X - DropArm.HIT_RANGE) and not JunctionRoom.tank_rests_on_wreck(DropArm.MARK_X + DropArm.HIT_RANGE + 1.0) and not JunctionRoom.tank_rests_on_wreck(DropArm.MARK_X - DropArm.HIT_REACH), "the tank rests on the wreck while the sentry's middle is in the brackets, and a graze's tank stands on the floor over the wreck's end")
	_expect(not DropArm.is_hit(DropArm.MARK_X + DropArm.HIT_RANGE + SentryBrain.HALF_WIDTH - 3.0) and not DropArm.is_hit(DropArm.MARK_X - DropArm.HIT_RANGE - SentryBrain.HALF_WIDTH + 3.0), "a brush, a few pixels of the body over a bracket, is still a miss")
	var arm: DropArm = DropArm.new()
	_expect(arm.state == &"hung" and arm.drop_amount() == 0.0 and arm.advance(1.0, 700.0) == &"", "a hung tank waits")
	_expect(arm.drop() and arm.state == &"falling" and not arm.drop(), "the clamp lets go once")
	_expect(arm.advance(0.44, 700.0) == &"" and arm.drop_amount() > 0.5 and arm.drop_amount() < 1.0, "0.44 s into the fall it is still falling")
	_expect(arm.advance(0.02, DropArm.MARK_X + DropArm.HIT_REACH) == &"hit" and arm.state == &"landed" and arm.drop_amount() == 1.0, "it lands at 0.45 s on a sentry with a quarter of its body in the brackets")
	_expect(not arm.drop() and arm.advance(10.0, 700.0) == &"", "a landed tank is final")
	var sliced: DropArm = DropArm.new()
	sliced.drop()
	var event: StringName = &""
	var frames: int = 0
	while event.is_empty() and frames < 100:
		event = sliced.advance(1.0 / 60.0, 800.0)
		frames += 1
	_expect(event == &"miss" and frames == 27, "sliced into frames the fall still takes 0.45 s")
	var miss: DropArm = DropArm.new()
	miss.drop()
	_expect(miss.advance(0.45, DropArm.MARK_X + DropArm.HIT_REACH + 1.0) == &"miss" and miss.state == &"rewinding" and miss.cloud_active() and miss.drop_amount() == 1.0, "a miss lands on the floor, starts the rewind and sprays the cloud")
	_expect(not miss.drop(), "a second drop during the rewind is refused")
	# Round 3 item 1: the missed tank lies on the mark while the cloud sprays, then the winch takes it.
	_expect(DropArm.FLOOR_SECONDS >= 0.5, "a missed tank lies on the floor for at least half a second")
	_expect(miss.on_floor() and miss.blocks_lane() and not miss.winching(), "the moment it lands it lies on the floor, in the lane, not yet winched")
	miss.advance(DropArm.FLOOR_SECONDS - 0.05, 0.0)
	_expect(miss.drop_amount() == 1.0 and miss.on_floor() and miss.cloud_active(), "it is still on the floor, spraying, %.2f s after the miss" % (DropArm.FLOOR_SECONDS - 0.05))
	miss.advance(0.05 + DropArm.LIFT_SECONDS * 0.5, 0.0)
	_expect(not miss.on_floor() and miss.winching() and miss.blocks_lane() and miss.drop_amount() > 0.0 and miss.drop_amount() < 0.5, "then the winch has it most of the way up within half the lift, still in the lane")
	miss.advance(DropArm.LIFT_SECONDS * 0.5, 0.0)
	_expect(miss.drop_amount() == 0.0 and miss.state == &"rewinding" and not miss.blocks_lane(), "after %.1f s on the floor and %.1f s of lift the tank hangs at its height again, out of the lane, while the clamp latches" % [DropArm.FLOOR_SECONDS, DropArm.LIFT_SECONDS])
	miss.advance(2.9 - DropArm.FLOOR_SECONDS - DropArm.LIFT_SECONDS, 0.0)
	_expect(miss.cloud_active() and miss.state == &"rewinding", "the cloud lasts 3 s")
	miss.advance(0.2, 0.0)
	_expect(not miss.cloud_active() and miss.state == &"rewinding" and miss.drop_amount() == 0.0, "the cloud clears while the clamp is still latching")
	_expect(miss.advance(2.8, 0.0) == &"" and miss.state == &"rewinding", "5.9 s in the tank is not back yet")
	_expect(miss.advance(0.2, 0.0) == &"rehung" and miss.state == &"hung" and miss.drop_amount() == 0.0, "the rewind finishes at 6 s and re-hangs the tank")
	_expect(miss.drop(), "a re-hung tank can drop again")
	var paused: DropArm = DropArm.new()
	paused.paused = true
	_expect(not paused.drop(), "a paused arm refuses to drop")
	paused.paused = false
	paused.drop()
	paused.paused = true
	_expect(paused.advance(1.0, 700.0) == &"" and paused.state == &"falling", "a paused fall holds")
	paused.reset(true)
	_expect(paused.state == &"landed" and paused.drop_amount() == 1.0 and not paused.paused, "reset after the drop is landed")
	_expect(DropArm.in_cloud(DropArm.MARK_X + DropArm.CLOUD_HALF_WIDTH + M0State.HUMAN_HALF_WIDTH) and not DropArm.in_cloud(DropArm.MARK_X + DropArm.CLOUD_HALF_WIDTH + M0State.HUMAN_HALF_WIDTH + 1.0), "the cloud reaches an engineer whose body touches it")


func _check_state_guards() -> void:
	var state: M0State = _completed_records_state(State.DISCLOSE)
	_expect(not state.drop_sentry() and not state.clear_junction(), "nothing in the lane happens outside the junction")
	state.enter_junction()
	_expect(not state.drop_sentry() and not state.clear_junction(), "the sentry cannot go down before the door")
	state.blow_door()
	_expect(not state.clear_junction(), "the junction cannot clear with the sentry live")
	_expect(state.drop_sentry() and not state.drop_sentry() and state.sentry_down, "the sentry goes down once")
	_expect(state.clear_junction() and not state.clear_junction() and state.junction_cleared, "the junction clears once")
	var round_trip: M0State = State.from_dict(JSON.parse_string(JSON.stringify(state.to_dict())))
	_expect(round_trip != null and round_trip.junction_cleared and round_trip.sentry_down and round_trip.door_blown, "a cleared junction round-trips through JSON")
	_expect(state.wolf_will_bait() and not _completed_records_state(State.PRESS).wolf_will_bait(), "WOLF offers to draw the sentry only with the relay risk disclosed")


func _check_scene() -> void:
	var path: String = "user://sentry-test-%s.json" % OS.get_process_id()
	_remove(path)
	var game: Node2D = GAME_SCENE.instantiate() as Node2D
	game.set("save_path", path)
	game.set("settings_path", "%s-settings.cfg" % path)
	root.add_child(game)
	await process_frame
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	var camera: Camera2D = game.get_node("IntroCamera") as Camera2D
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var brain: SentryBrain = game.get("sentry_brain") as SentryBrain
	var arm: DropArm = game.get("drop_arm") as DropArm
	var touch_use: Button = game.get_node("CanvasLayer/TouchControls/Use") as Button
	var touch_choice_1: Button = game.get_node("CanvasLayer/TouchControls/Choice1") as Button
	var continue_button: Button = game.get_node("CanvasLayer/TitleScreen/ContinueButton") as Button
	if not _require(room != null and brain != null and arm != null and room.sentry != null and room.sentry.get_node_or_null("Visual") != null, "Main builds the sentry with its drawing in one Visual child"):
		return
	_expect(room.sentry.collision_layer == 0 and room.sentry.collision_mask == 0, "the sentry body never pushes or blocks the actors")
	game.call("_new_game")
	game.call("_finish_intro")
	# P0-16: every frame of the routes below is checked as drawn (_watch_lane).
	var watch: Callable = _watch_lane.bind(game)
	process_frame.connect(watch)
	# Route 1: the relay risk was disclosed, so WOLF chooses to draw the sentry onto the mark.
	var b_dict: Dictionary = await _start_at_b(game, State.DISCLOSE)
	_expect(brain.state == &"patrol" and brain.x > SentryBrain.PATROL_MAX_X - 60.0 and brain.facing < 0.0 and arm.state == &"hung" and room.tank.position.y == JunctionRoom.TANK_REST_Y and not room.mark_lit(), "autosave B: the sentry patrols from the far end under a hung tank, outside the brackets")
	_expect(game.call("_objective") == "GO THROUGH THE DOOR", "before WOLF mentions the tank the card says to go through the door")
	game.call("_load_game")
	_expect((game.get("state") as M0State).door_blown and brain.state == &"patrol" and brain.x == SentryBrain.PATROL_MAX_X and str(game.get("status_line")).ends_with("The sentry patrols past the rubble."), "Continue from autosave B restores the live lane")
	_expect(await _walk_until_choice(game), "stepping onto the rubble line brings up the question")
	_expect(game.get("choice_context") == "lane" and human.position.x < SentryBrain.LANE_ENTRY_X and not human.controlled, "the question comes up before the engineer is in the lane")
	_expect(touch_choice_1.visible and touch_choice_1.text.contains("Draw it under the tank"), "the answers are on screen")
	_expect(game.call("_objective") == "DROP THE TANK", "once WOLF has asked about the tank the card names it")
	# The tank WOLF is asking about hangs in view below the answers in both layouts at the play framing.
	var touch_choice_2: Button = game.get_node("CanvasLayer/TouchControls/Choice2") as Button
	var tank_top_screen: float = (room.tank.position.y - JunctionRoom.TANK_SIZE.y * 0.5 - camera.position.y) * camera.zoom.y + 270.0
	for touch_layout: bool in [false, true]:
		game.set("touch_enabled", touch_layout)
		game.call("_refresh_ui")
		var answers_bottom: float = maxf(touch_choice_1.get_global_rect().end.y, touch_choice_2.get_global_rect().end.y)
		_expect(is_equal_approx(camera.zoom.y, 1.35) and tank_top_screen >= answers_bottom + 8.0, "the hanging tank sits below the %s answers (tank top %.0f, answers end %.0f)" % ["touch" if touch_layout else "keyboard", tank_top_screen, answers_bottom])
	game.set("touch_enabled", false)
	game.call("_refresh_ui")
	_expect(JunctionRoom.TANK_REST_Y + JunctionRoom.TANK_SIZE.y * 0.5 <= Sentry.FLOOR_Y - Sentry.DRAWN_HEIGHT - 8.0, "the hung tank clears the patrolling sentry's mast")
	var frozen_x: float = brain.x
	for _frame: int in 20:
		await physics_frame
	_expect(brain.x == frozen_x and arm.state == &"hung", "the sentry does not move while the question is open")
	await _tap(&"pause_game")
	_expect(paused, "pause works during the lane question")
	(game.get_node("CanvasLayer/PauseOverlay") as PauseOverlay).resume_requested.emit()
	_expect(not paused and game.get("waiting_for_choice"), "resume returns to the open question")
	await _tap(&"choice_1")
	_expect(game.get("wolf_baiting") and game.get("lane_choice") == "wolf" and wolf.autonomous_target_x == JunctionRoom.WOLF_BAIT_X and str(game.get("status_line")) == "WOLF: You told me the truth at the relay. I'll draw it onto the mark and keep clear of the tank. Drop it when it stops.", "with the risk disclosed WOLF chooses to draw it, and says it is because of the relay")
	# Round 3b: the engineer lets him go first at the rubble line, so he never runs through them later at
	# the release; they get their controls back once he is past them.
	_expect(game.get("engineer_waits_for_wolf") and not human.controlled, "after the answer the engineer waits at the rubble line while WOLF goes")
	var choice_x: float = human.position.x
	Input.action_press(&"move_right")
	var waited_in_place: Array[bool] = [true]
	var passed: bool = await _wait_until(func() -> bool:
		if game.get("engineer_waits_for_wolf"):
			waited_in_place[0] = waited_in_place[0] and absf(human.position.x - choice_x) < 0.5 and not human.controlled
		return not game.get("engineer_waits_for_wolf"), 120)
	Input.action_release(&"move_right")
	_expect(passed and waited_in_place[0] and choice_x < SentryBrain.LANE_ENTRY_X, "they hold at the rubble line, outside the lane, even with a direction held, until he is past")
	_expect(human.controlled and wolf.position.x - M0Actor.WOLF_REACH >= choice_x + M0Actor.HUMAN_REACH - 1.0, "then they have their controls back, with all of WOLF's drawn body ahead of them (WOLF %.0f)" % wolf.position.x)
	# "Drop it when it stops": until he has it stopped on the mark the release waits.
	human.position.x = JunctionRoom.ARM_X
	await physics_frame
	_expect(not brain.is_holding(JunctionRoom.WOLF_BAIT_X) and str(game.call("_context_hint")) == "Wait for WOLF to park it on the mark." and not game.call("_drop_ready"), "at the release before WOLF has it on the mark the hint says to wait")
	await _tap(&"interact")
	_expect(arm.state == &"hung" and str(game.get("status_line")) == "Wait. WOLF hasn't got it on the mark yet.", "USE at the release before it is parked leaves the tank hanging")
	# Once it is after the engineer WOLF has backed off, so the release no longer waits for him.
	var drawing_state: StringName = brain.state
	for hunting: StringName in [&"lock", &"chase"]:
		brain.state = hunting
		_expect(not game.call("_drop_waits_for_wolf") and game.call("_drop_ready") and wolf.autonomous_target_x == JunctionRoom.WOLF_BAIT_X, "with the sentry %s the release drops without waiting for WOLF" % ("locking on" if hunting == &"lock" else "chasing"))
	brain.state = drawing_state
	game.call("_update_controls")
	var walk_in_gap: Array[float] = [INF]
	var highest_bound: Array[float] = [0.0]
	var deepest_duck: Array[float] = [0.0]
	var never_closer: Array[bool] = [true]
	var last_sentry_x: Array[float] = [brain.x]
	# Box, hint and picture agree on every frame: the "Wait" and the wait hint stay up exactly until the
	# sentry is parked, and on that frame the line says it has stopped and the hint offers the drop.
	var agreed: Array[bool] = [true]
	_expect(await _wait_until(func() -> bool:
		# Where the two drawn bodies could meet he is up over the sentry; elsewhere they stay apart.
		var squash: float = wolf.body_sprite.scale.y / (game.get("wolf_sprite_scale") as Vector2).y
		var lift: float = -(wolf.body_sprite.offset.y - MainScript.WOLF_FEET_BELOW_CENTRE * (1.0 - squash) / squash) * wolf.body_sprite.scale.y
		highest_bound[0] = maxf(highest_bound[0], lift)
		deepest_duck[0] = maxf(deepest_duck[0], (1.0 - squash) * MainScript.WOLF_DRAWN_HEIGHT)
		if brain.wolf_ahead():
			# Still coming down the lane behind it: it never moves toward him.
			never_closer[0] = never_closer[0] and brain.x >= last_sentry_x[0] - 0.001
		last_sentry_x[0] = brain.x
		if lift < JunctionRoom.LEAP_HEIGHT - 0.5:
			walk_in_gap[0] = minf(walk_in_gap[0], absf(wolf.position.x - room.sentry.position.x))
		var parked: bool = game.call("_bait_holding")
		var line: String = str(game.get("status_line"))
		var hint: String = str(game.call("_context_hint"))
		if parked:
			agreed[0] = agreed[0] and line == "The sentry stops on the mark, its eyes on WOLF. Drop the tank now." and hint == "E: drop the tank. It's parked on the mark."
		else:
			agreed[0] = agreed[0] and line == "Wait. WOLF hasn't got it on the mark yet." and hint == "Wait for WOLF to park it on the mark."
		return brain.state == &"fixated" and absf(brain.x - DropArm.MARK_X) <= 0.5 and absf(wolf.position.x - JunctionRoom.WOLF_BAIT_X) <= 4.0, 300), "WOLF crosses to the far end of the lane and the sentry parks on the mark, facing him")
	_expect(agreed[0], "after an early press the \"Wait\" and its hint hold until the sentry parks, then the line and the hint both say it is on the mark")
	for _frame: int in 60:
		await physics_frame
	_expect(str(game.get("status_line")) == "The sentry stops on the mark, its eyes on WOLF. Drop the tank now." and str(game.call("_context_hint")).contains("drop the tank. It's parked"), "parked, the go line stays up beside the drop hint; nothing brings back the wait")
	# While WOLF holds it, it watches only him with its red eye and stops scanning: no beam is drawn, so
	# nothing runs over the engineer, over WOLF or across the EXIT BOLT box between them (round 3b).
	await physics_frame
	_expect(room.sentry.fixated and room.sentry.visual.scale.x > 0.0 and room.sentry.visual.eye == Sentry.SentryVisual.EYE_LOCKED and room.sentry.visual.reach < Sentry.lens_rect().end.x and room.sentry.visual.gap == Vector2.ZERO, "the fixated sentry faces WOLF with its eye red and draws no beam (reach %.1f)" % room.sentry.visual.reach)
	_expect(never_closer[0] and deepest_duck[0] >= JunctionRoom.DUCK_DEPTH - 0.5, "on his way down it never closed on him, and he ducked under the hung tank (deepest %.1f px)" % deepest_duck[0])
	_expect(wolf.body_sprite.flip_h and wolf.body_sprite.offset == Vector2.ZERO, "at his spot WOLF faces back down the lane at it, feet on the floor")
	_expect(walk_in_gap[0] >= SentryBrain.HALF_WIDTH + M0State.WOLF_HALF_WIDTH and highest_bound[0] >= JunctionRoom.LEAP_HEIGHT - 0.5, "WOLF bounds over the sentry on his way across and never walks through it (closest on the floor %.1f px, highest %.1f px)" % [walk_in_gap[0], highest_bound[0]])
	_expect(absf(room.sentry.position.x - brain.x) <= 4.0, "the sentry body follows its brain (%.1f vs %.1f)" % [room.sentry.position.x, brain.x])
	_expect(await _walk_to(human, JunctionRoom.ARM_X), "the engineer crosses to the panel")
	_expect(not game.get("fail_active") and brain.state == &"fixated", "crossing while it holds on WOLF is safe")
	_expect(absf(human.position.x - wolf.position.x) >= M0Actor.WOLF_REACH + M0Actor.HUMAN_REACH, "WOLF drawing it stands clear of the engineer at the release (%.1f px apart)" % absf(human.position.x - wolf.position.x))
	_expect(str(game.call("_context_hint")).contains("drop the tank. It's parked") and game.call("_drop_ready"), "with it parked the release offers the drop")
	await physics_frame
	_expect(room.mark_lit(), "the floor brackets light up with the sentry's body inside them")
	game.set("touch_enabled", true)
	game.call("_refresh_ui")
	_expect(touch_use.text == "DROP", "touch relabels USE to DROP at the panel")
	game.set("touch_enabled", false)
	game.call("_refresh_ui")
	await _tap(&"interact")
	_expect(arm.state == &"falling", "USE at the panel lets the tank go")
	_expect(await _wait_until(func() -> bool: return (game.get("state") as M0State).sentry_down, 60), "the tank lands on the parked sentry")
	_expect(str(game.get("status_line")).begins_with("The tank comes down square and crushes the sentry flat.") and absf(brain.x - DropArm.MARK_X) <= 8.0, "a hit on the mark is told as square")
	_expect(brain.state == &"down" and room.sentry_down and room.coolant_burst.emitting and room.hit_sparks.emitting, "the hit is a real state change with coolant and sparks")
	_expect(room.arm_label.text == "RELEASE USED" and room.tank_label.visible and room.tank_label.text == "TANK DOWN" and absf(room.tank_label.position.x + room.tank_label.size.x * 0.5 - DropArm.MARK_X) < 0.5, "the release reads spent and TANK DOWN sits over the tank")
	await physics_frame
	_check_crushed(room, brain, "the hit")
	_expect(game.call("_objective") == "POP THE EXIT BOLT" and not game.get("wolf_baiting") and wolf.autonomous_target_x == JunctionRoom.WOLF_DOWN_X, "the bolt is next and WOLF waits by the hatch, in full view, clear of the tank")
	var autosave_c: M0State = State.load_from_disk(path)
	_expect(autosave_c != null and autosave_c.sentry_down and autosave_c.door_blown and autosave_c.memory.get("choice_id") == State.DISCLOSE, "autosave C records the sentry down with the relay memory")
	_expect(autosave_c != null and autosave_c.lane_recap == "wolf", "autosave C keeps how the sentry came down for the END OF SLICE recap")
	_expect(await _wait_until(func() -> bool: return Engine.time_scale == 1.0 and camera.offset == Vector2.ZERO, 90), "time scale and camera settle after BOOM 2")
	game.call("_load_game")
	_expect(brain.state == &"down" and brain.x == DropArm.MARK_X and arm.state == &"landed" and room.sentry.visual.wrecked and room.tank.position.y > JunctionRoom.TANK_REST_Y and str(game.get("status_line")).contains("sentry is down"), "Continue from autosave C shows the sentry down under the tank")
	_check_crushed(room, brain, "Continue from autosave C")
	_expect(await _wait_until(func() -> bool: return absf(wolf.position.x - JunctionRoom.WOLF_DOWN_X) <= 2.0, 240) and wolf.body_sprite.flip_h, "after Continue from autosave C WOLF waits by the hatch, facing back at the engineer")
	_expect(await _walk_to(human, JunctionRoom.BOLT_X), "the engineer reaches the exit bolt")
	_expect(wolf.position.x - M0Actor.WOLF_REACH > human.position.x + M0Actor.HUMAN_REACH - 2.0 * M0Actor.AVOID_TOLERANCE and wolf.position.x - M0Actor.WOLF_REACH > DropArm.MARK_X + JunctionRoom.TANK_SIZE.x * 0.5, "at the bolt the engineer and WOLF both stand clear of each other and of the tank (WOLF %.0f, engineer %.0f)" % [wolf.position.x, human.position.x])
	_expect(str(game.call("_context_hint")).contains("pop the exit bolt"), "the bolt panel offers USE")
	await _tap(&"interact")
	_expect(game.get("bolt_state") == &"charging", "USE starts the bolt's whine")
	for _frame: int in 12:
		await physics_frame
	_expect(game.get("bolt_state") == &"charging" and room.bolt_charge > 0.0 and room.bolt_charge < 1.0, "the whine rises before the arc")
	_expect(_sounding(game, &"whine") and _sounding(game, &"bolt_arc"), "the arc's build starts under the whine, so its crack lands on the drop")
	_expect(await _wait_until(func() -> bool: return game.get("bolt_state") == &"open", 60), "the bolt arcs after the whine")
	_expect(room.bolt_sparks.emitting and (game.get("impact") as Impact).trauma > 0.0, "the arc throws sparks and shakes the view")
	_expect(room.hatch_open < 1.0 and str(game.get("status_line")) == "The bolt arcs and drops.", "while the hatch is still opening the line says only that the bolt dropped")
	_expect(room.hatch_label.text == "EXIT OPENING" and str(game.call("_context_hint")) == "The hatch is opening.", "while the hatch slides its plate and hint say it is opening, not open")
	await _tap(&"interact")
	_expect(not game.get("chapter_close_active") and not (game.get("state") as M0State).junction_cleared, "USE at a hatch still sliding does not leave through it")
	_expect(await _wait_until(func() -> bool: return room.hatch_open >= 1.0 and Engine.time_scale == 1.0, 60), "the hatch slides open")
	_expect(await _wait_until(func() -> bool: return str(game.get("status_line")) == "The bolt arcs and drops. The hatch slides open.", 6), "the line says the hatch slid open once it has")
	_expect(room.hatch_label.text == "EXIT OPEN" and str(game.call("_context_hint")) == "E: leave through the hatch.", "once the hatch is open its plate reads EXIT OPEN and the hint offers the way out")
	await _tap(&"interact")
	var state: M0State = game.get("state") as M0State
	_expect(state.junction_cleared and game.get("chapter_close_active") and not human.controlled and (game.get_node("CanvasLayer/TopBar/HUD") as Label).text.contains("SERVICE LINE CLEARED"), "USE at the open hatch clears the junction into a closing beat")
	var autosave_d: M0State = State.load_from_disk(path)
	_expect(autosave_d != null and autosave_d.junction_cleared, "autosave D records the cleared junction")
	await create_timer(0.6).timeout
	_expect(_close_cuts_no_label(camera, room), "the closing shot cuts no junction label at its edges")
	await _tap(&"pause_game")
	_expect(paused, "pause works during the closing beat")
	(game.get_node("CanvasLayer/PauseOverlay") as PauseOverlay).resume_requested.emit()
	var hatch_start_x: float = human.position.x
	await _tap(&"interact")
	# The two leave through the open hatch before the card, one at a time: WOLF steps into it and fades
	# out first, then the engineer walks in and fades (round 3b: never drawn over each other there).
	_expect(game.get("hatch_exit_walking") and not game.get("end_card_active") and not human.controlled, "Continue on the closing beat walks them out through the hatch first")
	# Nothing waits on a press during the walk, so no CONTINUE prompt shows, in any layout.
	_expect(not (game.get_node("CanvasLayer/ContextHint") as Control).visible, "walking out through the hatch shows no CONTINUE prompt")
	game.set("touch_enabled", true)
	game.call("_refresh_ui")
	_expect(not touch_use.visible and not (game.get_node("CanvasLayer/ContextHint") as Control).visible, "nor does the touch CONTINUE button show during the walk")
	game.set("touch_enabled", false)
	game.call("_refresh_ui")
	await _tap(&"interact")
	_expect(game.get("hatch_exit_walking") and not game.get("end_card_active"), "a second press does not cut the walk short")
	var one_at_a_time: Array[bool] = [true]
	var wolf_first: Array[bool] = [true]
	_expect(await _wait_until(func() -> bool:
		if human.modulate.a > 0.05 and wolf.modulate.a > 0.05:
			one_at_a_time[0] = one_at_a_time[0] and absf(human.position.x - wolf.position.x) >= M0Actor.WOLF_REACH + M0Actor.HUMAN_REACH - 2.0 * M0Actor.AVOID_TOLERANCE
		if absf(human.position.x - hatch_start_x) > 1.0:
			wolf_first[0] = wolf_first[0] and wolf.modulate.a < 0.05
		return bool(game.get("end_card_active")), 180), "the END OF SLICE card follows the walk")
	_expect(one_at_a_time[0] and wolf_first[0], "WOLF goes through first and the engineer only moves once he has gone, so the two are never drawn over each other in the doorway")
	_expect(human.position.x > hatch_start_x and absf(human.position.x - JunctionRoom.HATCH_X) <= 12.0 and absf(wolf.position.x - JunctionRoom.HATCH_X) <= 40.0 and human.modulate.a < 0.05 and wolf.modulate.a < 0.05, "both walked into the hatch and faded out (engineer x %.0f, WOLF x %.0f)" % [human.position.x, wolf.position.x])
	# Decision D: the closing beat leads to the END OF SLICE card with this run's choices, then the title.
	var end_card: Control = game.get_node("CanvasLayer/EndCard") as Control
	var end_button: Button = end_card.get_node("EndCardContinue") as Button
	_expect(game.get("end_card_active") and end_card.visible and not game.get("title_open") and not game.get("chapter_close_active") and not human.controlled, "the closing beat leads to the END OF SLICE card, not straight to the title")
	var recap_text: String = ""
	for label: Label in end_card.find_children("*", "Label", true, false):
		recap_text += label.text + "\n"
	var first_name: String = state.human_name().get_slice(" ", 0)
	_expect(recap_text.contains("END OF SLICE") and recap_text.contains("Thank you for playing this early slice.") and recap_text.contains("THIS RUN"), "the card thanks the player under END OF SLICE")
	_expect(recap_text.contains("%s told WOLF the risk. WOLF took the live contact." % first_name) and recap_text.contains("WOLF read the timestamp off his own readout.") and recap_text.contains("WOLF drew the sentry onto the mark."), "the recap names this run's relay, mirror and lane choices")
	_expect(not (game.get_node("CanvasLayer/BottomBar") as Control).visible and not (game.get_node("CanvasLayer/PauseButton") as Control).visible and not (game.get_node("CanvasLayer/TouchControls") as Control).visible, "nothing of the play HUD shows over the card")
	_expect(end_button.text == "E  CONTINUE", "the card's prompt names the interact key")
	game.set("touch_enabled", true)
	game.call("_refresh_ui")
	_expect(end_button.text == "TAP CONTINUE" and end_button.is_visible_in_tree(), "on touch the card's button says TAP CONTINUE")
	game.set("touch_enabled", false)
	game.call("_refresh_ui")
	await _tap(&"pause_game")
	_expect(not paused and game.get("title_open"), "Pause (or Back) on the card goes on to the title instead of pausing")
	_expect(not continue_button.disabled and continue_button.text == "PLAY AGAIN" and (game.get_node("CanvasLayer/TitleScreen/ContinueNote") as Label).text == "Slice complete. PLAY AGAIN starts a fresh run.", "on a finished save the title offers PLAY AGAIN and says why")
	var new_game_button: Button = game.get_node("CanvasLayer/TitleScreen/NewGameButton") as Button
	_expect(not new_game_button.visible and is_equal_approx(continue_button.offset_left, new_game_button.offset_left) and game.call("_title_first_button") == continue_button, "NEW GAME would do the same, so PLAY AGAIN stands alone across the row and takes the first focus")
	var finished_path: String = str(game.get("save_path"))
	game.set("save_path", finished_path + ".missing")
	game.call("_refresh_continue")
	_expect(new_game_button.visible and continue_button.text == "CONTINUE" and continue_button.offset_left > new_game_button.offset_right and game.call("_title_first_button") == new_game_button, "without a finished save NEW GAME and CONTINUE sit side by side again")
	game.set("save_path", finished_path)
	game.call("_refresh_continue")
	var finished_bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	continue_button.pressed.emit()
	await physics_frame
	state = game.get("state") as M0State
	_expect(not game.get("title_open") and game.get("intro_active") and state.chapter_id == "lockdown" and state.memory.is_empty(), "PLAY AGAIN starts a fresh run with the opening")
	_expect(human.modulate.a == 1.0 and wolf.modulate.a == 1.0 and not game.get("hatch_exit_walking"), "a fresh run shows both again after they faded out through the hatch")
	_expect(FileAccess.get_file_as_bytes(path) == finished_bytes, "like New Game, a fresh run keeps the finished save until it saves over it")
	# Only a hand-made save could reopen the cleared junction; it never calls the line unbuilt.
	game.call("_finish_intro")
	game.call("_load_game")
	state = game.get("state") as M0State
	_expect(state.junction_cleared and room.hatch_open == 1.0 and human.controlled and game.call("_objective") == "SERVICE LINE CLEARED" and str(game.get("status_line")) == "The service line runs on toward Archive.", "a restored cleared junction says where the line goes")
	# The corridor seal's body (switched off outside the corridor at the end of the restore's frame)
	# shares these coordinates, so the engineer is placed once that has happened.
	await physics_frame
	human.position.x = JunctionRoom.BOLT_X
	await _tap(&"interact")
	_expect(str(game.get("status_line")) == "The service line runs on toward Archive." and str(game.call("_context_hint")) == "The hatch is open.", "the open hatch has no developer note in the dialogue or the hint")
	# The card answers the interact key, its own button and Back too.
	for way: String in ["interact", "button", "back"]:
		game.set("chapter_close_active", true)
		game.call("_finish_chapter_close")
		_expect(await _wait_until(func() -> bool: return bool(game.get("end_card_active")), 120), "the card is up again (%s)" % way)
		match way:
			"interact":
				await _tap(&"interact")
			"button":
				end_button.pressed.emit()
			"back":
				game.call("_handle_back")
		_expect(game.get("title_open") and not game.get("end_card_active") and not end_card.visible, "%s on the END OF SLICE card goes on to the title" % way)
		game.call("_new_game")
		game.call("_finish_intro")
		game.call("_load_game")
	# WOLF breaks off after a miss while drawing the sentry.
	await _start_at_b(game, State.DISCLOSE)
	_expect(await _walk_until_choice(game), "the question comes up again on a new attempt")
	await _tap(&"choice_1")
	_expect(await _wait_until(func() -> bool: return brain.state == &"fixated", 120), "WOLF is drawing the sentry")
	game.call("_tank_miss")
	_expect(not game.get("wolf_baiting") and game.get("wolf_broke_off") and wolf.autonomous_target_x == JunctionRoom.WOLF_RUBBLE_X and brain.state == &"lock", "after a miss WOLF breaks off to the rubble and the sentry turns, locking on first")
	_expect(str(game.get("status_line")) == "The tank hits the empty mark\nand sprays coolant." and (game.get("box_queue") as Array) == ["The sentry swings toward the release;\nget back over the rubble.", "WOLF: I'm out. I'll hold at the rubble."] and not game.get("wolf_holding_far_end"), "not yet past the sentry, WOLF says in his own box after the miss that he is breaking off to the rubble")
	human.position.x = 500.0
	var miss_boxes: Array[String] = [str(game.get("status_line"))]
	var log_box: Callable = func() -> void:
		if miss_boxes.back() != str(game.get("status_line")):
			miss_boxes.append(str(game.get("status_line")))
	await physics_frame
	_expect(str(game.call("_context_hint")).contains("until it gives up"), "back over the rubble the hint says to wait out the chase")
	_expect(await _wait_until(func() -> bool:
		log_box.call()
		return brain.state == &"patrol", 240), "the chase ends with the engineer over the rubble")
	_expect(str(game.call("_context_hint")).contains("WOLF has broken off"), "then the hint says WOLF has stepped back")
	# Back over the rubble before the sentry swung, the order to get back over it is dropped (it would
	# be stale); the sentry giving up cuts in, and WOLF breaking off still follows once that line is read.
	await _wait_until(func() -> bool:
		log_box.call()
		return miss_boxes.back() == "WOLF: I'm out. I'll hold at the rubble.", 1200)
	var lost_at: int = miss_boxes.find("The sentry loses Rowan behind the rubble\nand rolls back to its patrol.")
	_expect(not miss_boxes.has("The sentry swings toward the release;\nget back over the rubble.") and lost_at > 0 and miss_boxes.find("WOLF: I'm out. I'll hold at the rubble.") > lost_at, "retreating over the rubble before the sentry swings drops the order to do so and still shows WOLF breaking off, after the sentry gives up (seen %s)" % str(miss_boxes).c_escape())
	# Round 3b: a miss with WOLF already past the sentry, by the hatch. He breaks off where he is, since
	# he never crosses back under the tank; the sentry's patrol then turns short of him and its beam
	# stops at him; and the END OF SLICE recap says he broke off.
	await _start_at_b(game, State.DISCLOSE)
	_expect(await _walk_until_choice(game), "the question comes up on another attempt")
	await _tap(&"choice_1")
	_expect(await _wait_until(func() -> bool: return game.call("_bait_holding"), 300), "WOLF has it held on the mark from his spot by the hatch")
	game.call("_tank_miss")
	_expect(game.get("wolf_holding_far_end") and game.get("wolf_broke_off") and not game.get("wolf_baiting") and wolf.autonomous_target_x == JunctionRoom.WOLF_BAIT_X and (game.get("box_queue") as Array).back() == "WOLF: I'm out.", "past it when it missed, WOLF breaks off where he is, by the hatch, and says only that he is out (Nathanial's rewrite)")
	human.position.x = 500.0
	var held_spot: Array[bool] = [true]
	var furthest: Array[float] = [-INF]
	_expect(await _wait_until(func() -> bool:
		held_spot[0] = held_spot[0] and absf(wolf.position.x - JunctionRoom.WOLF_BAIT_X) <= 4.0 and is_zero_approx(wolf.body_sprite.offset.y)
		if brain.state == &"patrol":
			furthest[0] = maxf(furthest[0], brain.x)
		return brain.state == &"patrol" and brain.facing < 0.0 and furthest[0] > 790.0, 900), "the sentry gives up on the engineer and patrols again")
	var turn_x: float = JunctionRoom.WOLF_BAIT_X - M0Actor.WOLF_REACH - SentryBrain.HALF_WIDTH - MainScript.WOLF_SENTRY_GAP
	_expect(held_spot[0] and is_equal_approx(brain.far_x, turn_x) and furthest[0] <= turn_x + 0.5, "WOLF holds by the hatch, on the floor, and the patrol turns short of him (furthest %.1f, turn %.1f)" % [furthest[0], turn_x])
	_expect(await _wait_until(func() -> bool: return brain.state == &"patrol" and brain.facing > 0.0 and brain.x > 760.0, 300), "the patrol heads his way again")
	await physics_frame
	var beam_end: float = room.sentry.position.x + room.sentry.visual.reach
	_expect(is_equal_approx(room.sentry.beam_stop_x, JunctionRoom.WOLF_BAIT_X - M0Actor.WOLF_REACH) and beam_end <= JunctionRoom.WOLF_BAIT_X - M0Actor.WOLF_REACH + 0.5, "facing him its beam stops at him instead of running on over him (ends %.1f)" % beam_end)
	brain.x = DropArm.MARK_X
	game.call("_tank_hit")
	_expect((game.get("state") as M0State).lane_recap == "broke_off" and (game.call("end_card_recap") as Array)[2] == "SENTRY  WOLF broke off while Rowan timed the drop.", "the recap says he broke off while the engineer timed the drop")
	_expect(await _wait_until(func() -> bool: return Engine.time_scale == 1.0, 90), "time scale settles after that hit")
	await _check_engineer_alone(game, path)
	await _check_cloud(game, path)
	await _check_chased_cards(game, path)
	process_frame.disconnect(watch)
	print("Lane watch: %d junction frames, %d with a beam" % [lane_frames, lane_beam_frames])
	_expect(lane_frames > 3000 and lane_beam_frames > 500 and lane_faults.is_empty(), "on all %d junction frames of these routes (%d with a beam), the sentry never overlaps the standing or lying engineer, its beam never runs past the bolt panel or the tank, and the bolt feed never crosses the tank (%d faults: %s)" % [lane_frames, lane_beam_frames, lane_faults.size(), ", ".join(lane_faults.slice(0, 6))])
	# A crafted v4 save with the sentry down but the door still sealed is rejected.
	var crafted: Dictionary = b_dict.duplicate(true)
	crafted["positions"]["human"] = [120.0, 410.0]
	crafted["positions"]["wolf"] = [64.0, 423.0]
	crafted["door_blown"] = false
	_write(path, crafted)
	_expect(State.load_from_disk(path) != null, "the crafted save's positions and flags are otherwise valid")
	crafted["sentry_down"] = true
	_write(path, crafted)
	_expect(State.load_from_disk(path) == null, "a v4 save with the sentry down but the door sealed is rejected")
	game.call("_pause_game")
	(game.get_node("CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton") as Button).pressed.emit()
	_expect(continue_button.disabled and (game.get_node("CanvasLayer/TitleScreen/ContinueNote") as Label).text == "Saved checkpoint could not be read.", "the title refuses to continue from it")
	_remove(path)
	_remove("%s-settings.cfg" % path)
	game.queue_free()
	await create_timer(0.1).timeout
	_expect(Engine.time_scale == 1.0, "freeing the game leaves time_scale at 1.0")


## WOLF refuses with the PRESS memory; the sentry runs the engineer down once (back to autosave B
## with the memory intact); then the engineer misses, retreats, waits out the rewind and times a hit.
func _check_engineer_alone(game: Node2D, path: String) -> void:
	var human: M0Actor = game.get_node("Human") as M0Actor
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var brain: SentryBrain = game.get("sentry_brain") as SentryBrain
	var arm: DropArm = game.get("drop_arm") as DropArm
	var b_dict: Dictionary = await _start_at_b(game, State.PRESS)
	var b_bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	_expect(await _walk_until_choice(game), "the PRESS route gets the same question")
	await _tap(&"choice_1")
	var refusal: String = str(game.get("status_line"))
	_expect(_sounding(game, &"growl_refusal"), "WOLF's refusal comes with his recorded growl")
	_expect(game.get("lane_choice") == "refused" and not game.get("wolf_baiting") and wolf.autonomous_target_x == JunctionRoom.WOLF_RUBBLE_X, "with the risk withheld WOLF refuses to draw it")
	_expect(refusal.begins_with("WOLF: At the relay") and refusal.contains("Time the drop from the release;") and not refusal.contains("You said"), "his refusal names the relay choice openly and points at the engineer's way through")
	for _frame: int in 60:
		await physics_frame
	_expect(wolf.position.x <= JunctionRoom.WOLF_RUBBLE_X + 6.0 and brain.state == &"patrol", "WOLF stays at the rubble and the sentry keeps patrolling")
	# Step into its path: it sees, chases and runs the engineer down.
	_expect(await _wait_until(func() -> bool: return brain.facing < 0.0 and brain.x <= 780.0 and brain.x >= 720.0, 300), "the sentry comes back down the lane")
	human.position.x = 640.0
	human.body_sprite.flip_h = false
	_expect(await _wait_until(func() -> bool: return brain.state == &"lock", 5), "it sees the engineer and locks on")
	var locked_x: float = brain.x
	_expect(_sounding(game, &"klaxon") and room.sentry.visual.eye == Sentry.SentryVisual.EYE_LOCKED, "locking on turns its eye red with a short alarm")
	for _frame: int in 12:
		await physics_frame
	_expect(brain.state == &"lock" and brain.x == locked_x and absf(room.sentry.position.x - locked_x) <= 4.0 and not game.get("fail_active"), "through the lock-on beat it stands still")
	_expect(str(game.call("_context_hint")).contains("after you"), "the hint warns the engineer as soon as it locks on")
	_expect(await _wait_until(func() -> bool: return game.get("fail_active"), 90), "sentry contact in the lane is a knockdown")
	_expect(str(game.get("status_line")).begins_with(JunctionRoom.SENTRY_REASON % (game.get("state") as M0State).human_name().get_slice(" ", 0)) and str(game.get("status_line")).begins_with("The sentry saw Rowan out in the open.\nStay close to the TANK RELEASE."), "the status line names the sentry and the engineer, says they were caught out in the open, and points at the TANK RELEASE")
	_expect(SentryBrain.is_exposed(human.position.x) and human.position.x > SentryBrain.COVER_MAX_X, "and the engineer was indeed caught past the right post (x %.0f)" % human.position.x)
	# Round 3c item 3: the body lies where the card says they were caught: past the right post (facing
	# away from the alcove they slump forward, the way they faced), clear of the TANK RELEASE and of the
	# sentry, which rolls back off them.
	_expect(await _expect_lying(game, 1.0, "out in the lane"), "caught out in the lane facing right, the engineer slumps forward to the right, away from the alcove, onto the floor without turning round")
	var body_rect: Rect2 = _painted_body(human.body_sprite)
	var sentry_rect: Rect2 = _drawn_rect(room.sentry.visual.body)
	var release_right: float = JunctionRoom.ARM_X + JunctionRoom.ARM_PANEL_HALF_WIDTH
	_expect(body_rect.position.x >= SentryBrain.COVER_MAX_X + 3.0 and body_rect.position.x >= release_right + 3.0, "the body lies past the alcove's right post, clear of the TANK RELEASE (body %.1f..%.1f, post %.0f, release ends %.1f)" % [body_rect.position.x, body_rect.end.x, SentryBrain.COVER_MAX_X, release_right])
	_expect(room.sentry.position.x > human.position.x and sentry_rect.position.x - body_rect.end.x >= 3.0, "the sentry rolls back off the body and stands clear of it (gap %.1f px)" % (sentry_rect.position.x - body_rect.end.x))
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "the knockdown hands back")
	var state: M0State = game.get("state") as M0State
	_expect(FileAccess.get_file_as_bytes(path) == b_bytes and state.to_dict() == b_dict and state.memory.get("choice_id") == State.PRESS, "it restores autosave B with the relay memory intact and saves nothing")
	_expect(brain.state == &"patrol" and brain.x > SentryBrain.PATROL_MAX_X - 60.0 and arm.state == &"hung" and game.get("lane_choice") == "" and human.controlled, "the restore puts the sentry back at the far end under a hung tank")
	_expect(await _wait_until(func() -> bool: return Engine.time_scale == 1.0 and (game.get_node("IntroCamera") as Camera2D).offset == Vector2.ZERO, 90), "time scale and camera are at rest after the restore")
	_expect(await _walk_until_choice(game), "the question comes up again after the restore")
	await _tap(&"choice_2")
	_expect(game.get("lane_choice") == "alone" and str(game.get("status_line")).contains("hold at the rubble"), "answer 2 leaves the drop to the engineer")
	_expect(await _cross_to_panel(game), "the engineer slips into the alcove behind the sentry")
	for _frame: int in 240:
		await physics_frame
	_expect(not game.get("fail_active") and brain.state == &"patrol", "a full patrol passes the alcove without seeing the engineer")
	# A miss: drop while it is at the far end.
	_expect(await _wait_until(func() -> bool: return brain.x >= 830.0, 300), "the sentry reaches the far end")
	await _tap(&"interact")
	var lowest_base: Array[float] = [-INF]
	_expect(await _wait_until(func() -> bool:
		lowest_base[0] = maxf(lowest_base[0], room.tank.position.y + JunctionRoom.TANK_SIZE.y * 0.5)
		return arm.state == &"rewinding", 60), "the drop misses")
	await process_frame
	_expect(arm.cloud_active() and room.coolant_cloud.emitting and room.tank.dented and brain.state in [&"lock", &"chase"] and not room.tank_label.visible, "a miss dents the tank, sprays the cloud and turns the sentry on the release")
	# Round 3 item 1: the line and the picture agree: the tank is on the empty mark while it sprays.
	_expect(str(game.get("status_line")).begins_with("The tank hits the empty mark") and arm.on_floor() and is_equal_approx(room.tank.position.y, JunctionRoom.landed_tank_y(false)) and room.arm_label.text == "TANK RELEASE", "the miss is told as the empty mark while the tank lies on it, and the plate does not yet say it is winching")
	var on_floor_seconds: Array[float] = [0.0]
	var sentry_into_tank: Array[float] = [INF]
	var came_from_right: bool = brain.x > DropArm.MARK_X
	_expect(await _wait_until(func() -> bool:
		if is_equal_approx(room.tank.position.y, JunctionRoom.landed_tank_y(false)):
			on_floor_seconds[0] += 1.0 / 60.0
		if arm.blocks_lane():
			var edge_gap: float = (brain.x - SentryBrain.HALF_WIDTH - DropArm.footprint().y) if came_from_right else (DropArm.footprint().x - brain.x - SentryBrain.HALF_WIDTH)
			sentry_into_tank[0] = minf(sentry_into_tank[0], edge_gap)
		return room.arm_label.text == "WINCHING UP", 90), "once the winch takes it the plate says WINCHING UP")
	_expect(on_floor_seconds[0] >= DropArm.FLOOR_SECONDS - 4.0 / 60.0, "the tank lay on the floor for about %.1f s first (%.2f s)" % [DropArm.FLOOR_SECONDS, on_floor_seconds[0]])
	# Sampled once a physics frame, so the landing frame itself can fall between samples: within the
	# lift's first frame is still well below the height of a sentry the tank would rest on.
	_expect(lowest_base[0] > Sentry.FLOOR_Y - 8.0 and lowest_base[0] > Sentry.FLOOR_Y - Sentry.WRECK_CRUSH_HEIGHT + 8.0, "a missed tank comes down to the floor, not to the sentry's height (base %.1f)" % lowest_base[0])
	await physics_frame
	_expect(room.cloud_hazard.armed, "the cloud's hurtbox is live while it vents")
	_expect(_sounding(game, &"coolant_cloud"), "the cloud hisses while it vents")
	_expect(await _wait_until(func() -> bool:
		if arm.blocks_lane():
			var edge_gap: float = (brain.x - SentryBrain.HALF_WIDTH - DropArm.footprint().y) if came_from_right else (DropArm.footprint().x - brain.x - SentryBrain.HALF_WIDTH)
			sentry_into_tank[0] = minf(sentry_into_tank[0], edge_gap)
		return room.tank.position.y == JunctionRoom.TANK_REST_Y, 40) and arm.state == &"rewinding" and brain.state in [&"lock", &"chase"], "the winch has the tank back up while the sentry is still after the engineer")
	_expect(sentry_into_tank[0] >= -0.01, "the sentry never drives into the tank while it is down (closest edge %.1f px)" % sentry_into_tank[0])
	await _tap(&"interact")
	_expect(arm.state == &"rewinding" and str(game.get("status_line")) == "Not yet. The tank is still going back up.", "the panel refuses a second drop during the rewind")
	_expect(await _walk_to(human, 500.0), "the engineer retreats over the rubble")
	_expect(not game.get("fail_active"), "getting back over the rubble in time avoids the knockdown")
	_expect(await _wait_until(func() -> bool: return brain.state == &"patrol", 200), "the sentry gives up and patrols again")
	_expect(await _wait_until(func() -> bool: return not arm.cloud_active() and not room.cloud_hazard.armed, 200), "the cloud clears")
	await process_frame
	_expect(not _sounding(game, &"coolant_cloud"), "its hiss stops with it")
	_expect(await _wait_until(func() -> bool: return arm.state == &"hung", 400), "the rewind re-hangs the tank")
	# The timed hit: tap as it closes on the mark, leading it by the 0.45 s fall.
	_expect(await _cross_to_panel(game), "the engineer is back in the alcove")
	var lead: float = SentryBrain.PATROL_SPEED * DropArm.FALL_SECONDS
	_expect(await _wait_until(func() -> bool: return brain.facing < 0.0 and brain.x <= DropArm.MARK_X + lead + 8.0 and brain.x >= DropArm.MARK_X + lead - 8.0, 400), "the sentry comes toward the mark")
	await _tap(&"interact")
	var last_live_x: Array[float] = [brain.x]
	_expect(await _wait_until(func() -> bool:
		if brain.state != &"down":
			last_live_x[0] = brain.x
		return (game.get("state") as M0State).sentry_down, 60), "a drop timed on the patrol lands on it")
	await physics_frame
	# The tank lands before the sentry moves each frame, so the wreck is where it was last seen moving.
	_expect(absf(brain.x - last_live_x[0]) <= SentryBrain.PATROL_SPEED * 2.0 / 60.0, "the wreck stays where the tank caught it, no jump onto the mark (%.1f, last seen %.1f)" % [brain.x, last_live_x[0]])
	_check_crushed(room, brain, "the timed hit")
	var autosave_c: M0State = State.load_from_disk(path)
	_expect(autosave_c != null and autosave_c.sentry_down and autosave_c.memory.get("choice_id") == State.PRESS, "the engineer-only route writes autosave C too")
	await _check_tank_crossing(game)
	# Round 3c item 2: autosave C was written as the tank landed, with WOLF still at the rubble; Continue
	# starts him at his spot by the hatch, not back across the tank.
	_expect(autosave_c != null and autosave_c.wolf_position.x < JunctionRoom.TANK_LEAP_PEAK_X - JunctionRoom.TANK_LEAP_HALF_SPAN, "autosave C has WOLF on the rubble side of the tank (x %.0f)" % (autosave_c.wolf_position.x if autosave_c != null else -1.0))
	game.call("_load_game")
	_expect(wolf.position.x == JunctionRoom.WOLF_DOWN_X and wolf.body_sprite.flip_h and room.arm_parked == 1.0, "Continue from autosave C starts WOLF at his spot by the hatch, facing back down the lane, with the arm up (x %.1f)" % wolf.position.x)
	var placed_x: float = wolf.position.x
	await physics_frame
	_expect(absf(wolf.position.x - placed_x) <= 0.01 and wolf.autonomous_target_x == JunctionRoom.WOLF_DOWN_X and wolf.body_sprite.offset == Vector2.ZERO, "and he stays there on the floor, with no walk across the tank")


## The landed tank rests on the crushed hull of a wreck pinned where the tank caught it, which is
## within the hit window, so the wreck's treads and hull show below it; a wreck on the mark (WOLF's
## hold, or Continue) shows past both of the tank's sides, and one caught off centre still has at
## least half the tank's footprint over it.
func _check_crushed(room: JunctionRoom, brain: SentryBrain, label: String) -> void:
	var tank_base: float = room.tank.position.y + JunctionRoom.TANK_SIZE.y * 0.5
	var wreck: Sprite2D = room.sentry.visual.wreck
	# Measured where the wreck settles: keel_over drops it the last few pixels onto its treads.
	var wreck_rect: Rect2 = wreck.get_global_transform() * wreck.get_rect()
	wreck_rect.position.y -= room.sentry.visual.position.y
	_expect(DropArm.is_hit(brain.x) and absf(room.sentry.position.x - brain.x) < 0.01, "%s: the wreck lies under the tank where it was caught (%.1f)" % [label, brain.x])
	_expect(is_equal_approx(room.tank.position.y, JunctionRoom.landed_tank_y(true)) and absf(tank_base - (Sentry.FLOOR_Y - Sentry.WRECK_CRUSH_HEIGHT)) < 0.01, "%s: the tank rests on the crushed hull (base y %.1f), not on the floor" % [label, tank_base])
	_expect(Sentry.WRECK_CRUSH_HEIGHT >= 20.0 and is_equal_approx(wreck_rect.end.y, Sentry.FLOOR_Y) and wreck_rect.end.y - tank_base >= 20.0, "%s: at least 20 px of the wreck shows under the tank, down to the floor" % label)
	var tank_left: float = DropArm.MARK_X - JunctionRoom.TANK_SIZE.x * 0.5
	var tank_right: float = DropArm.MARK_X + JunctionRoom.TANK_SIZE.x * 0.5
	var covered: float = minf(wreck_rect.end.x, tank_right) - maxf(wreck_rect.position.x, tank_left)
	_expect(covered >= JunctionRoom.TANK_SIZE.x * 0.5, "%s: at least half of the tank's footprint rests on the wreck (%.1f px)" % [label, covered])
	if absf(brain.x - DropArm.MARK_X) < 0.5:
		_expect(wreck_rect.position.x < tank_left and wreck_rect.end.x > tank_right, "%s: the wreck shows past both sides of the tank" % label)


## The coolant cloud is its own knockdown back to autosave B.
func _check_cloud(game: Node2D, path: String) -> void:
	var human: M0Actor = game.get_node("Human") as M0Actor
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var brain: SentryBrain = game.get("sentry_brain") as SentryBrain
	var arm: DropArm = game.get("drop_arm") as DropArm
	var b_dict: Dictionary = await _start_at_b(game, State.DISCLOSE)
	# Isolate the cloud: no sentry in play and the lane question already answered, a real miss from
	# the arm, then walk into the vapour.
	brain.state = &"dormant"
	game.set("lane_choice", "alone")
	arm.drop()
	arm.advance(DropArm.FALL_SECONDS, 0.0)
	_expect(arm.cloud_active(), "a forced miss vents the cloud")
	# The room syncs the arm from Main._process, which a single physics frame does not always include.
	_expect(await _wait_until(func() -> bool: return room.cloud_hazard.armed and room.coolant_cloud.emitting, 5), "the cloud arms its hurtbox")
	# Stopped over the exit bolt's box, the engineer's usual sidestep to its left would end in the cloud:
	# it never carries them into a hazard they are not already in.
	var beside_cloud_x: float = DropArm.MARK_X + DropArm.CLOUD_HALF_WIDTH + M0State.HUMAN_HALF_WIDTH + 20.0
	human.position.x = beside_cloud_x
	# One frame for the game to see where the engineer now stands (the sidestep is decided each frame).
	await process_frame
	await process_frame
	var stopped_x: float = human.position.x
	for _frame: int in 30:
		await physics_frame
	_expect(absf(human.position.x - stopped_x) < 0.5 and not DropArm.in_cloud(human.position.x) and not game.get("fail_active"), "the sidestep out of a machine never walks the engineer into the coolant cloud (x %.1f)" % human.position.x)
	# Walking in from the alcove side, facing the tank: they slump forward, the way they faced, and stagger
	# back from the tank as they go, so the lying body ends clear of it.
	human.position.x = DropArm.MARK_X - DropArm.CLOUD_HALF_WIDTH - M0State.HUMAN_HALF_WIDTH - 6.0
	human.body_sprite.flip_h = false
	Input.action_press(&"move_right")
	var walked_in: bool = await _wait_until(func() -> bool: return game.get("fail_active"), 60)
	Input.action_release(&"move_right")
	_expect(walked_in, "walking into the coolant cloud is a knockdown")
	_expect(await _expect_lying(game, 1.0, "in the coolant cloud"), "caught by the cloud facing the tank, the engineer slumps forward towards it onto the floor")
	var tank_left: float = room.global_position.x + room.tank.position.x - JunctionRoom.TANK_SIZE.x * 0.5
	var lying_rect: Rect2 = _painted_body(human.body_sprite)
	_expect(tank_left - lying_rect.end.x >= 3.0, "and the lying body ends clear of the tank on the floor (body ends %.1f, tank starts %.1f)" % [lying_rect.end.x, tank_left])
	_expect(str(game.get("status_line")).begins_with("The coolant cloud caught %s. Let it clear before crossing the mark." % (game.get("state") as M0State).human_name().get_slice(" ", 0)), "the status line names the cloud and the engineer")
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "the cloud knockdown hands back")
	_expect((game.get("state") as M0State).to_dict() == b_dict and not arm.cloud_active() and not room.cloud_hazard.armed and brain.state == &"patrol", "it restores autosave B with the cloud gone")
	# A hit well off the mark is told as one: the tank catches the sentry off centre, not square.
	brain.state = &"dormant"
	brain.x = DropArm.MARK_X + DropArm.HIT_REACH - 4.0
	game.set("lane_choice", "alone")
	arm.drop()
	_expect(await _wait_until(func() -> bool: return (game.get("state") as M0State).sentry_down, 60) and absf(brain.x - DropArm.MARK_X) > 8.0, "a drop on a sentry near the bracket's edge still hits")
	_expect(str(game.get("status_line")).begins_with("The tank catches the sentry off centre and pins it to the floor.") and str(game.get("status_line")).ends_with("WOLF: It's down. The bolt by the hatch is next."), "an off-centre hit is told as off centre, not square")


## The sentry card follows the cause. Seen and caught out in the lane, it points at the alcove or
## the rubble (_check_engineer_alone); turned on the engineer by a miss, or reaching them inside the
## alcove, it points only at the rubble, since a chase reaches anywhere between the posts.
func _check_chased_cards(game: Node2D, path: String) -> void:
	var human: M0Actor = game.get_node("Human") as M0Actor
	var brain: SentryBrain = game.get("sentry_brain") as SentryBrain
	var arm: DropArm = game.get("drop_arm") as DropArm
	var b_dict: Dictionary = await _start_at_b(game, State.PRESS)
	var chased: String = JunctionRoom.SENTRY_CHASED_REASON % (game.get("state") as M0State).human_name().get_slice(" ", 0)
	# A miss with the sentry at the far end, and the engineer stays at the release.
	game.set("lane_choice", "alone")
	human.position.x = JunctionRoom.ARM_X
	# Facing the sentry as it comes: they slump forward towards it, and it rolls back off them.
	human.body_sprite.flip_h = false
	_expect(brain.state == &"patrol" and brain.x >= 830.0 and arm.drop(), "the drop goes with the sentry at the far end")
	_expect(await _wait_until(func() -> bool: return arm.state == &"rewinding", 60) and brain.turned_by_miss, "the miss turns the sentry on the release")
	_expect(await _wait_until(func() -> bool: return game.get("fail_active"), 120), "a chase after a miss runs down an engineer who stays at the release")
	var status: String = str(game.get("status_line"))
	_expect(not SentryBrain.is_exposed(human.position.x) and status.begins_with(chased) and not status.contains("alcove's posts") and not status.contains("in its lane"), "caught between the posts after a miss, the card points only at the rubble (%s)" % status)
	await _expect_shove_fall(game, "after a miss", false)
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "the knockdown after a miss hands back")
	_expect((game.get("state") as M0State).to_dict() == b_dict and not brain.turned_by_miss, "it restores autosave B with the sentry patrolling again")
	# Seen out in the lane, then caught after ducking into the alcove: the alcove advice would be wrong.
	game.set("lane_choice", "alone")
	_expect(await _wait_until(func() -> bool: return brain.facing < 0.0 and brain.x <= 780.0 and brain.x >= 720.0, 300), "the sentry comes back down the lane")
	human.position.x = 640.0
	_expect(await _wait_until(func() -> bool: return brain.state == &"lock", 5) and not brain.turned_by_miss, "it sees the engineer in the lane")
	human.position.x = JunctionRoom.ARM_X
	# Facing away from it: they slump forward, away from it.
	human.body_sprite.flip_h = true
	_expect(await _wait_until(func() -> bool: return game.get("fail_active"), 120), "the chase reaches the engineer in the alcove")
	status = str(game.get("status_line"))
	_expect(not SentryBrain.is_exposed(human.position.x) and status.begins_with(chased) and not status.contains("alcove's posts"), "caught inside the alcove, the card points only at the rubble (%s)" % status)
	await _expect_shove_fall(game, "inside the alcove", true)
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "that knockdown hands back too")
	# Out in the lane facing back towards the alcove: they slump forward where they stand, towards it,
	# never turned round or dragged back against the fall.
	game.set("lane_choice", "alone")
	_expect(await _wait_until(func() -> bool: return brain.facing < 0.0 and brain.x <= 780.0 and brain.x >= 720.0, 300), "the sentry comes back down the lane again")
	human.position.x = 640.0
	human.body_sprite.flip_h = true
	_expect(await _wait_until(func() -> bool: return brain.state == &"lock", 5) and not brain.turned_by_miss, "it sees the engineer in the lane, facing the alcove")
	_expect(await _wait_until(func() -> bool: return game.get("fail_active"), 120), "the chase runs them down in the lane")
	_expect(str(game.get("status_line")).begins_with(JunctionRoom.SENTRY_REASON % (game.get("state") as M0State).human_name().get_slice(" ", 0)), "the card is the one for being seen out in the lane")
	var stood_x: float = human.position.x
	await _expect_shove_fall(game, "in the lane facing the alcove", true)
	_expect(is_equal_approx(float(game.get("collapse_to_x")), stood_x), "facing the alcove, the boots stay where they stood (x %.1f, lying at %.1f)" % [stood_x, float(game.get("collapse_to_x"))])
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "the knockdown in the lane hands back")


## Round 3c item 2: with the tank down on the sentry and WOLF at the rubble, he holds there until the
## empty arm has winched up, then bounds over the crushed tank to his spot by the hatch. On every frame
## of that crossing his painted body stays TANK_CLEARANCE px clear of the tank's, the wreck's and the
## arm's painted bodies (the images, measured where the scene draws them). The leap's shape is then
## checked at every x of the crossing against the wreck caught anywhere in the hit window, either way
## round.
func _check_tank_crossing(game: Node2D) -> void:
	var wolf: M0Actor = game.get_node("Wolf") as M0Actor
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var rest_scale: Vector2 = game.get("wolf_sprite_scale") as Vector2
	_expect(wolf.position.x < JunctionRoom.TANK_LEAP_PEAK_X - JunctionRoom.TANK_LEAP_HALF_SPAN and wolf.autonomous_target_x >= 0.0, "with the tank down WOLF starts the crossing from the rubble side (x %.0f)" % wolf.position.x)
	var human: M0Actor = game.get_node("Human") as M0Actor
	var waited: Array[bool] = [true]
	var start_x: float = wolf.position.x
	# His feet as he passes over the engineer's centre (the lowest of the frames there).
	var over_engineer: Array[float] = [-INF]
	var highest: Array[float] = [0.0]
	var frames: Dictionary = {}
	var steady: Array[bool] = [true]
	var arrived: bool = await _wait_until(func() -> bool:
		if room.arm_parked < 1.0:
			waited[0] = waited[0] and absf(wolf.position.x - start_x) < 0.5
		var lift: float = -wolf.body_sprite.offset.y * wolf.body_sprite.scale.y
		highest[0] = maxf(highest[0], lift)
		steady[0] = steady[0] and wolf.body_sprite.scale == rest_scale and is_zero_approx(wolf.body_sprite.rotation_degrees)
		var feet: float = wolf.position.y + wolf.body_sprite.position.y + MainScript.WOLF_FEET_BELOW_CENTRE * wolf.body_sprite.scale.y - lift
		frames[Vector4i(roundi(wolf.position.x), roundi(feet), 1 if wolf.body_sprite.flip_h else 0, roundi(room.arm_art.position.y))] = true
		if absf(wolf.position.x - human.position.x) <= M0Actor.HUMAN_REACH:
			over_engineer[0] = maxf(over_engineer[0], feet)
		return absf(wolf.position.x - JunctionRoom.WOLF_DOWN_X) <= 2.0 and wolf.body_sprite.offset == Vector2.ZERO, 300)
	_expect(arrived and waited[0], "WOLF holds where he is until the empty arm has winched up, then crosses to his spot by the hatch")
	_expect(steady[0] and highest[0] >= JunctionRoom.TANK_LEAP_HEIGHT - 0.5, "he bounds over the crushed tank at full height (highest %.1f px), unsquashed" % highest[0])
	var obstacles: Dictionary = {}
	var parked_y: int = roundi(room.arm_art.position.y)
	var fixed: Dictionary = _sprite_pixels(room.tank, TANK_CLEARANCE)
	fixed.merge(_sprite_pixels(room.sentry.visual.wreck, TANK_CLEARANCE))
	var arm: Dictionary = _sprite_pixels(room.arm_art, TANK_CLEARANCE)
	var touching: Array[String] = []
	for key: Vector4i in frames:
		var arm_shift: int = key.w - parked_y
		for offset: Vector2i in _wolf_pixels(0):
			var pixel: Vector2i = Vector2i(key.x + (-offset.x if key.z == 1 else offset.x), key.y + offset.y)
			if fixed.has(pixel) or arm.has(pixel - Vector2i(0, arm_shift)):
				touching.append("x %d feet %d" % [key.x, key.y])
				break
	_expect(touching.is_empty(), "WOLF's painted body stays %.0f px clear of the crushed tank, the wreck and the arm on every frame of the crossing (%d frames checked; touching at %s)" % [TANK_CLEARANCE, frames.size(), ", ".join(touching.slice(0, 4))])
	# Round 3c fix: one bound, not a launch beside the engineer and a hover. Working the release, the
	# engineer stands between the rubble and the tank, so he goes up over them, well clear of their head.
	var head_y: float = INF
	for pixel: Vector2i in _sprite_pixels(human.body_sprite, 0.0):
		head_y = minf(head_y, pixel.y)
	_expect(human.position.x >= SentryBrain.COVER_MIN_X and human.position.x <= SentryBrain.COVER_MAX_X and over_engineer[0] > -INF and over_engineer[0] <= head_y - TANK_CLEARANCE, "with the engineer at the release he passes over them on the way up, his feet (y %.0f) clear of their head (y %.0f)" % [over_engineer[0], head_y])
	# The leap at every x of the crossing, with the wreck pinned anywhere the tank can catch it.
	var feet_rest: float = 423.0 - 15.0 + MainScript.WOLF_FEET_BELOW_CENTRE * rest_scale.y
	_expect(JunctionRoom.wolf_tank_leap_height(JunctionRoom.WOLF_RUBBLE_X) == 0.0 and JunctionRoom.wolf_tank_leap_height(JunctionRoom.WOLF_DOWN_X) == 0.0, "at the rubble and at his spot by the hatch he is on the floor")
	_check_tank_leap_shape()
	for at_x: float in [DropArm.MARK_X - DropArm.HIT_REACH, DropArm.MARK_X, DropArm.MARK_X + DropArm.HIT_REACH]:
		for facing: float in [-1.0, 1.0]:
			room.sentry.keel_over(at_x)
			room.sentry.visual.position = Vector2.ZERO
			room.sentry.visual.scale.x = facing
			obstacles.merge(_sprite_pixels(room.sentry.visual.wreck, TANK_CLEARANCE))
	obstacles.merge(_sprite_pixels(room.tank, TANK_CLEARANCE))
	obstacles.merge(arm)
	var swept: Array[String] = []
	for x: int in range(roundi(JunctionRoom.WOLF_RUBBLE_X), roundi(JunctionRoom.WOLF_DOWN_X) + 1):
		var feet: int = roundi(feet_rest - JunctionRoom.wolf_tank_leap_height(x))
		for offset: Vector2i in _wolf_pixels(0):
			if obstacles.has(Vector2i(x + offset.x, feet + offset.y)):
				swept.append("x %d" % x)
				break
	_expect(swept.is_empty(), "at every x of the crossing the bound clears the tank, the wreck wherever it was caught and the arm by %.0f px (touching at %s)" % [TANK_CLEARANCE, ", ".join(swept.slice(0, 4))])
	# The pixel checks above hold the frame for a while; let the engine catch up before the next timed
	# check, so its physics frames are not spent catching up inside one process frame.
	for _frame: int in 6:
		await process_frame


## Round 3c fix: the bound over the crushed tank is one arc. It leaves the floor once and comes back
## once, rising and then falling with no flat top (every step up is smaller than the one before it, as
## under gravity), never steeper than TANK_LEAP_MAX_SLOPE px up per px along (the earlier plateau's
## ramps rose 2.1), within 2 px of its top for no more than TANK_LEAP_TOP_SPAN px along, and down on
## the floor at least TANK_LEAP_LANDING px short of his spot by the hatch, so he does not drop onto it.
func _check_tank_leap_shape() -> void:
	var take_off: float = -1.0
	var landing: float = -1.0
	var concave: bool = true
	var steepest: float = 0.0
	var near_top: float = 0.0
	var previous_step: float = INF
	for x: int in range(roundi(JunctionRoom.WOLF_RUBBLE_X), roundi(JunctionRoom.WOLF_DOWN_X)):
		var here: float = JunctionRoom.wolf_tank_leap_height(x)
		var next: float = JunctionRoom.wolf_tank_leap_height(x + 1)
		if here == 0.0 and next > 0.0:
			_expect(take_off < 0.0, "the bound leaves the floor only once (again at x %d)" % x)
			take_off = x
		if here > 0.0 and next == 0.0:
			landing = x + 1
		if here > 0.0 and next > 0.0:
			var step: float = next - here
			concave = concave and step < previous_step
			previous_step = step
			steepest = maxf(steepest, absf(step))
		if here >= JunctionRoom.TANK_LEAP_HEIGHT - 2.0:
			near_top += 1.0
	_expect(take_off > JunctionRoom.WOLF_RUBBLE_X and landing > take_off and concave, "the bound over the tank is one arc, from x %.0f to x %.0f, rising and falling with no flat top" % [take_off, landing])
	_expect(steepest <= TANK_LEAP_MAX_SLOPE, "it rises and falls no steeper than %.1f px per px (steepest %.2f)" % [TANK_LEAP_MAX_SLOPE, steepest])
	_expect(near_top <= TANK_LEAP_TOP_SPAN, "it is within 2 px of its top for %.0f px along, not a hover" % near_top)
	_expect(landing <= JunctionRoom.WOLF_DOWN_X - TANK_LEAP_LANDING, "he lands at x %.0f, at least %.0f px short of his spot by the hatch" % [landing, TANK_LEAP_LANDING])


## [param sprite]'s painted pixels (alpha over half) where the scene draws it, in world pixels, grown
## by [param grow] px.
func _sprite_pixels(sprite: Sprite2D, grow: float) -> Dictionary:
	var image: Image = sprite.texture.get_image()
	if image.is_compressed():
		image.decompress()
	var region: Rect2 = sprite.region_rect if sprite.region_enabled else Rect2(Vector2.ZERO, image.get_size())
	var local_rect: Rect2 = sprite.get_rect()
	var xform: Transform2D = sprite.get_global_transform()
	var inverse: Transform2D = xform.affine_inverse()
	var bounds: Rect2 = xform * local_rect
	var painted: Array[Vector2i] = []
	for wy: int in range(floori(bounds.position.y) - 1, ceili(bounds.end.y) + 1):
		for wx: int in range(floori(bounds.position.x) - 1, ceili(bounds.end.x) + 1):
			var local: Vector2 = inverse * Vector2(wx + 0.5, wy + 0.5)
			if not local_rect.has_point(local):
				continue
			var u: float = (local.x - local_rect.position.x) / local_rect.size.x
			var v: float = (local.y - local_rect.position.y) / local_rect.size.y
			if sprite.flip_h:
				u = 1.0 - u
			var tx: int = clampi(floori(region.position.x + u * region.size.x), 0, image.get_width() - 1)
			var ty: int = clampi(floori(region.position.y + v * region.size.y), 0, image.get_height() - 1)
			if image.get_pixel(tx, ty).a > 0.5:
				painted.append(Vector2i(wx, wy))
	var reach: int = ceili(grow)
	var pixels: Dictionary = {}
	for pixel: Vector2i in painted:
		for dy: int in range(-reach, reach + 1):
			for dx: int in range(-reach, reach + 1):
				if dx * dx + dy * dy <= grow * grow:
					pixels[pixel + Vector2i(dx, dy)] = true
	return pixels


## Round 3c item 3 and P0-3: a chase's knockdown: the sentry stops where the bodies touch, the engineer
## slumps forward the way they faced ([param facing_left]) onto the floor without turning round, and it
## stands clear of the lying body, whichever side of it they fell.
func _expect_shove_fall(game: Node2D, label: String, facing_left: bool) -> void:
	var human: M0Actor = game.get_node("Human") as M0Actor
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	var brain: SentryBrain = game.get("sentry_brain") as SentryBrain
	_expect(absf(human.position.x - brain.x) >= SentryBrain.CONTACT_RANGE - 0.01, "caught %s, it knocks the engineer down at contact range, not inside them (%.1f px)" % [label, absf(human.position.x - brain.x)])
	_expect(await _expect_lying(game, -1.0 if facing_left else 1.0, label), "caught %s, the engineer slumps forward the way they faced onto the floor, without turning round" % label)
	var body_rect: Rect2 = _painted_body(human.body_sprite)
	var sentry_rect: Rect2 = _drawn_rect(room.sentry.visual.body)
	var gap: float = sentry_rect.position.x - body_rect.end.x if room.sentry.position.x > human.position.x else body_rect.position.x - sentry_rect.end.x
	_expect(gap >= 3.0, "caught %s, the sentry stands clear of the lying body (gap %.1f px)" % [label, gap])


## P0-3: the knocked-down engineer lies on the floor line: the collapse's last frame, never tilted, the
## soles on y 440 (the region's bottom row is the soles' row, so nothing is drawn below it), falling
## [param fall] (1 right, -1 left), and the shadow under the whole body.
func _expect_lying(game: Node2D, fall: float, label: String) -> bool:
	var human: M0Actor = game.get_node("Human") as M0Actor
	var sprite: Sprite2D = human.body_sprite
	var last_x: float = MainScript.COLLAPSE_FRAME.x * (MainScript.COLLAPSE_SPANS.size() - 1)
	var down: bool = await _wait_until(func() -> bool: return sprite.texture == MainScript.COLLAPSE_SHEET and is_equal_approx(sprite.region_rect.position.x, last_x), 90)
	var rect: Rect2 = _drawn_rect(sprite)
	var reflection: FloorReflection = game.get("human_reflection") as FloorReflection
	var span: Vector2 = reflection.shadow_span + Vector2.ONE * human.position.x
	var ok: bool = down and game.get("fail_active") and is_zero_approx(sprite.rotation_degrees) and absf(rect.end.y - JunctionRoom.FLOOR_Y) < 0.01 and sprite.flip_h == (fall < 0.0)
	ok = ok and span.x <= rect.get_center().x and span.y >= rect.get_center().x and span.y - span.x >= rect.size.x * 0.9 and reflection.shadow.visible
	if not ok:
		print("caught %s: not lying on the floor line (down %s, bottom %.2f, tilt %.1f, flip %s, body %.1f..%.1f, shadow %.1f..%.1f)" % [label, down, rect.end.y, sprite.rotation_degrees, sprite.flip_h, rect.position.x, rect.end.x, span.x, span.y])
	return ok


## P0-16 and SPACE-8, on one frame as it was drawn (connected to process_frame, so it sees the frame
## the game finished last): in the junction, (1) the live sentry's drawn body and the engineer's (standing
## at M0Actor.HUMAN_REACH, or lying as painted) do not overlap; (2) a lit beam ends on or before the
## near face of the exit bolt's panel and of the tank at the beam's height when they stand ahead of its
## lens, and never further than SIGHT_RANGE; (3) the bolt feed's boxes, conduits and glands do not
## cross the tank wherever it hangs, falls or lies.
func _watch_lane(game: Node2D) -> void:
	var room: JunctionRoom = game.get("junction_room") as JunctionRoom
	if room == null or not room.is_visible_in_tree() or paused:
		return
	lane_frames += 1
	var human: M0Actor = game.get_node("Human") as M0Actor
	var sentry: Sentry = room.sentry
	var origin: float = room.global_position.x
	var tank_rect: Rect2 = Rect2(room.tank.position - JunctionRoom.TANK_SIZE * 0.5, JunctionRoom.TANK_SIZE)
	var facing: float = sentry.visual.scale.x
	if sentry.is_visible_in_tree() and not sentry.visual.wrecked and (game.get("sentry_brain") as SentryBrain).is_solid():
		var front: float = (Sentry.ACTIVE_TREAD_X - Sentry.ACTIVE_REGION.position.x) * Sentry.ART_SCALE
		var back: float = (Sentry.ACTIVE_REGION.end.x - Sentry.ACTIVE_TREAD_X) * Sentry.ART_SCALE
		var sx: float = origin + sentry.position.x
		var body: Vector2 = Vector2(sx - (back if facing > 0.0 else front), sx + (front if facing > 0.0 else back))
		var engineer: Vector2 = Vector2(human.global_position.x - M0Actor.HUMAN_REACH, human.global_position.x + M0Actor.HUMAN_REACH)
		if human.body_sprite.texture == MainScript.COLLAPSE_SHEET:
			engineer = _painted_collapse(human)
		var overlap: float = minf(body.y, engineer.y) - maxf(body.x, engineer.x)
		if overlap > 0.01:
			lane_faults.append("frame %d: sentry %.1f..%.1f overlaps the engineer %.1f..%.1f (fail %s, target %.1f, speed %.0f, brain %s %.1f f%.0f, human %.1f)" % [lane_frames, body.x, body.y, engineer.x, engineer.y, game.get("fail_active"), sentry.target_x, sentry.max_speed, (game.get("sentry_brain") as SentryBrain).state, (game.get("sentry_brain") as SentryBrain).x, (game.get("sentry_brain") as SentryBrain).facing, human.position.x] + " region %.0f ts %.2f pos %.2f vel %.1f" % [human.body_sprite.region_rect.position.x, Engine.time_scale, sentry.position.x, sentry.velocity.x])
	if sentry.is_visible_in_tree() and sentry.visual.is_lit() and sentry.visual.reach > Sentry.lens_rect().end.x:
		lane_beam_frames += 1
		var lens: float = sentry.position.x + facing * Sentry.lens_rect().end.x
		var tip: float = sentry.position.x + facing * sentry.visual.reach
		if absf(tip - sentry.position.x) > SentryBrain.SIGHT_RANGE + 0.01:
			lane_faults.append("frame %d: beam %.1f px long" % [lane_frames, absf(tip - sentry.position.x)])
		var solids: Array[Rect2] = [Rect2(SentryBrain.PANEL_FACE_X, Sentry.FLOOR_Y - 60.0, JunctionRoom.BOLT_PANEL_HALF_WIDTH * 2.0, 60.0)]
		# (A tank whose base is within a hundredth of a pixel of the beam's top edge only grazes it.)
		if room.tank.visible and tank_rect.end.y > Sentry.beam_top_y() + 0.01:
			solids.append(tank_rect)
		for solid: Rect2 in solids:
			if facing > 0.0 and lens <= solid.position.x and tip > solid.position.x + 0.01:
				lane_faults.append("frame %d: beam to %.1f runs into the solid at %.1f" % [lane_frames, tip, solid.position.x])
			elif facing < 0.0 and lens >= solid.end.x and tip < solid.end.x - 0.01:
				lane_faults.append("frame %d: beam to %.1f runs into the solid ending %.1f (block %s, arm %s %.2f, tank y %.1f, choice %s, fail %s)" % [lane_frames, tip, solid.end.x, sentry.sight_block, (game.get("drop_arm") as DropArm).state, (game.get("drop_arm") as DropArm).drop_amount(), room.tank.position.y, game.get("waiting_for_choice"), game.get("fail_active")])
	if human.body_sprite.texture == MainScript.COLLAPSE_SHEET and room.tank.visible:
		var drawn: Rect2 = _drawn_rect(human.body_sprite)
		var span: Vector2 = _painted_collapse(human)
		var frame: int = roundi(human.body_sprite.region_rect.position.x / MainScript.COLLAPSE_FRAME.x)
		var top: float = drawn.end.y - (MainScript.COLLAPSE_FRAME.y - MainScript.COLLAPSE_TOPS[frame]) * MainScript.COLLAPSE_SCALE
		var lying: Rect2 = Rect2(span.x, top, span.y - span.x, drawn.end.y - top)
		var tank_world: Rect2 = Rect2(tank_rect.position + room.global_position, tank_rect.size)
		if lying.grow(-0.01).intersects(tank_world):
			lane_faults.append("frame %d: the lying engineer %s overlaps the tank %s" % [lane_frames, lying, tank_world])
	for part: Rect2 in room.bolt_feed_parts():
		if room.tank.visible and part.intersects(tank_rect):
			lane_faults.append("frame %d: the bolt feed %s crosses the tank %s" % [lane_frames, part, tank_rect])
			break


## The x span of the engineer's collapse frame as painted (MainScript.COLLAPSE_SPANS), in the world.
func _painted_collapse(human: M0Actor) -> Vector2:
	var sprite: Sprite2D = human.body_sprite
	var frame: int = roundi(sprite.region_rect.position.x / MainScript.COLLAPSE_FRAME.x)
	var fall: float = -1.0 if sprite.flip_h else 1.0
	var boots: float = sprite.global_position.x - fall * (MainScript.COLLAPSE_FRAME.x * 0.5 - MainScript.COLLAPSE_PIVOT_X) * MainScript.COLLAPSE_SCALE
	return MainScript.collapse_span(frame, fall, boots)


## The engineer's lying body as painted: the collapse frame's cut is 4 px wider than the painting on
## each side (MainScript.COLLAPSE_SPANS), about 1 px in the room.
func _painted_body(sprite: Sprite2D) -> Rect2:
	return _drawn_rect(sprite).grow_individual(-4.0 * MainScript.COLLAPSE_SCALE, 0.0, -4.0 * MainScript.COLLAPSE_SCALE, 0.0)


## The axis-aligned box [param sprite]'s drawn rectangle covers in the world.
func _drawn_rect(sprite: Sprite2D) -> Rect2:
	return sprite.get_global_transform() * sprite.get_rect()


## Autosave B: the door is down, the engineer just left of the old door line, WOLF at the rubble.
func _start_at_b(game: Node2D, choice_id: String) -> Dictionary:
	var state: M0State = _completed_records_state(choice_id)
	state.enter_junction()
	state.blow_door()
	state.human_position = Vector2(400.0, 410.0)
	state.wolf_position = Vector2(JunctionRoom.WOLF_RUBBLE_X, 423.0)
	game.set("state", state)
	game.call("_sync_scene")
	game.call("_start_gameplay_camera")
	game.call("_save_progress")
	await physics_frame
	return State.load_from_disk(game.get("save_path")).to_dict()


## True when neither edge of the settled closing shot falls inside a station label (RELIEF VENT among
## them).
func _close_cuts_no_label(camera: Camera2D, room: JunctionRoom) -> bool:
	var half_width: float = 480.0 / camera.zoom.x
	var edges: Array[float] = [camera.position.x - half_width, camera.position.x + half_width]
	var spans: Array[Vector2] = []
	for child: Node in room.get_children():
		var label: Label = child as Label
		if label == null or not label.visible:
			continue
		var text_width: float = label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		var centre: float = label.position.x + label.size.x * 0.5
		spans.append(Vector2(centre - text_width * 0.5, centre + text_width * 0.5))
	for edge: float in edges:
		for span: Vector2 in spans:
			if edge > span.x - 4.0 and edge < span.y + 4.0:
				push_error("the closing edge at x %.1f cuts a label spanning %.1f..%.1f" % [edge, span.x, span.y])
				return false
	return true


func _walk_until_choice(game: Node2D) -> bool:
	Input.action_press(&"move_right")
	var asked: bool = await _wait_until(func() -> bool: return game.get("waiting_for_choice"), 300)
	Input.action_release(&"move_right")
	return asked


## Waits until the sentry is heading away on the far side, then walks into the alcove.
func _cross_to_panel(game: Node2D) -> bool:
	var brain: SentryBrain = game.get("sentry_brain") as SentryBrain
	var human: M0Actor = game.get_node("Human") as M0Actor
	if not await _wait_until(func() -> bool: return brain.state == &"patrol" and brain.facing > 0.0 and brain.x >= 700.0, 400):
		return false
	return await _walk_to(human, JunctionRoom.ARM_X) and not game.get("fail_active")


## P0-21 (PUZ-6, FAIL-6, Nathanial's Q7): the tank window is at least about half a second on patrol.
## The patrol turns at PATROL_MIN_X, inside the window, so each patrol pass (in past the mark and
## back out) measures about 1.0 s; a straight crossing at patrol speed would be about 0.53 s.
## Measured two ways at 60 fps, as Main runs them (the tank lands against where the sentry stands at
## the start of the frame): the frames the sentry's body is far enough over the brackets on each
## pass, and the press times of a drop that lands as a hit.
func _check_drop_window() -> void:
	var straight: float = 2.0 * DropArm.HIT_REACH / SentryBrain.PATROL_SPEED
	_expect(straight >= 0.5, "a straight crossing of the whole hit window takes %.2f s (at least 0.5 s; 0.34 s before)" % straight)
	for far_x: float in [SentryBrain.PATROL_MAX_X, 805.0]:
		var brain: SentryBrain = _patrolling_at(far_x, -1.0)
		brain.far_x = far_x
		var passes: Array[float] = []
		var run: int = 0
		for _frame: int in 1200:
			brain.tick(1.0 / 60.0, 100.0, false, -1.0)
			if DropArm.is_hit(brain.x):
				run += 1
			elif run > 0:
				passes.append(run / 60.0)
				run = 0
		passes.sort()
		_expect(passes.size() >= 3 and passes[0] >= 0.5, "on patrol (far end %.0f) every pass, in past the mark and back out, keeps the sentry over the brackets at least 0.5 s (shortest %.2f s of %d passes)" % [far_x, passes[0] if not passes.is_empty() else 0.0, passes.size()])
	# Press windows: for every frame of a patrol cycle, drop then and see whether it lands as a hit.
	var hits: Array[bool] = []
	for start: int in 240:
		var sentry: SentryBrain = _patrolling_at(SentryBrain.PATROL_MAX_X, -1.0)
		for _frame: int in start:
			sentry.tick(1.0 / 60.0, 100.0, false, -1.0)
		var arm: DropArm = DropArm.new()
		arm.drop()
		var landed: StringName = &""
		while landed.is_empty():
			landed = arm.advance(1.0 / 60.0, sentry.x)
			sentry.tick(1.0 / 60.0, 100.0, false, -1.0)
		hits.append(landed == &"hit")
	var windows: Array[float] = []
	var length: int = 0
	for index: int in hits.size():
		if hits[index]:
			length += 1
		if (not hits[index] or index == hits.size() - 1) and length > 0:
			windows.append(length / 60.0)
			length = 0
	windows.sort()
	_expect(not windows.is_empty() and windows[0] >= 0.5, "pressed at any moment of a patrol pass, the drop hits through a window of at least 0.5 s (%s)" % str(windows))
	print("Tank window: %.2f s per straight crossing at patrol speed, %.2f s at chase speed, press windows on patrol %s" % [straight, 2.0 * DropArm.HIT_REACH / SentryBrain.CHASE_SPEED, str(windows)])


func _patrolling_at(x: float, facing: float) -> SentryBrain:
	var brain: SentryBrain = SentryBrain.new()
	brain.wake()
	brain.x = x
	brain.facing = facing
	return brain


func _completed_records_state(choice_id: String) -> M0State:
	var state: M0State = State.new()
	state.record_choice(choice_id)
	state.arm_breaker()
	state.activate_power("wolf" if choice_id == State.DISCLOSE else "human")
	state.reach_checkpoint()
	state.enter_records()
	state.preserve_purge_trace()
	state.preserve_mirror_trace("wolf" if choice_id == State.DISCLOSE else "manual")
	state.complete_chapter()
	state.human_position = Vector2(830.0, 410.0)
	state.wolf_position = Vector2(766.0, 423.0)
	return state


func _write(path: String, data: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _tap(action: StringName) -> void:
	await process_frame
	if action == &"pause_game":
		# Pause is event-driven, so send a real input event.
		Input.parse_input_event(_action_event(action, true))
		await process_frame
		Input.parse_input_event(_action_event(action, false))
		return
	Input.action_press(action)
	await process_frame
	Input.action_release(action)


func _action_event(action: StringName, pressed: bool) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


## WOLF crosses the lane from the rubble to the far end, answering at many points of the patrol (the
## engineer waits at the rubble line while he dashes past them). Drawn, the sentry never closes on him
## before he is past it: it backs off to the end of its patrol and he bounds over it there
## (JunctionRoom.wolf_leap_height), ducking under the hung tank on the way (JunctionRoom.wolf_duck_depth).
## Wherever the two drawn bodies could meet he is up over the sentry at the full bound, so they never
## overlap; the bound clears the sentry's drawn top; his painted body never comes within
## TANK_CLEARANCE px of the hung tank's painted body (round 3b: the two images, measured); and he is on
## the floor at both ends. After a miss with him past it he holds by the hatch, and the sentry, turned
## on an engineer over the rubble and then patrolling again, stays short of him (SentryBrain.far_x).
func _check_bait_walk() -> void:
	var clear: float = SentryBrain.HALF_WIDTH + M0State.WOLF_HALF_WIDTH
	var feet_y: float = 423.0 + (-15.0) + _wolf_art_feet()
	_expect(feet_y - JunctionRoom.LEAP_HEIGHT < Sentry.FLOOR_Y - Sentry.DRAWN_HEIGHT, "at the top of his bound WOLF's painted feet (y %.1f) clear the sentry's drawn top (y %.1f)" % [feet_y - JunctionRoom.LEAP_HEIGHT, Sentry.FLOOR_Y - Sentry.DRAWN_HEIGHT])
	_expect(JunctionRoom.wolf_leap_height(JunctionRoom.WOLF_RUBBLE_X, SentryBrain.CHASE_MIN_X) < 0.5 and JunctionRoom.wolf_leap_height(JunctionRoom.WOLF_BAIT_X, DropArm.MARK_X) == 0.0, "standing at the rubble or at his spot by the hatch he is on the floor")
	_expect(JunctionRoom.wolf_duck_depth(JunctionRoom.WOLF_RUBBLE_X, 1.0) == 0.0 and JunctionRoom.wolf_duck_depth(JunctionRoom.WOLF_BAIT_X, -1.0) == 0.0, "nor does he duck there")
	var step: float = 1.0 / 60.0
	var through_in: float = INF
	var bounded: int = 0
	var crossing_low: float = INF
	var deepest_duck: float = 0.0
	# (x, lift, duck) of every frame his body is near the tank, deduplicated, for the image check.
	var near_tank: Dictionary = {}
	var held_clear: bool = true
	var patrol_far: float = -INF
	var far_x: float = JunctionRoom.WOLF_BAIT_X - M0Actor.WOLF_REACH - SentryBrain.HALF_WIDTH - MainScript.WOLF_SENTRY_GAP
	for phase: int in 40:
		var brain: SentryBrain = SentryBrain.new()
		brain.reset(true, false, DropArm.MARK_X)
		# Patrol for a while first so the answer lands at a different point of the patrol each time.
		brain.tick(phase * 0.12, 500.0, false, -1.0)
		var wolf_x: float = JunctionRoom.WOLF_RUBBLE_X
		var leapt: bool = false
		for _frame: int in 240:
			var lift: float = JunctionRoom.wolf_leap_height(wolf_x, brain.x)
			# He dashes past the engineer waiting at the rubble line, and bounds at the same speed.
			var dashing: bool = wolf_x - M0Actor.WOLF_REACH < JunctionRoom.CHOICE_X + M0Actor.HUMAN_REACH
			wolf_x = move_toward(wolf_x, JunctionRoom.WOLF_BAIT_X, M0Actor.FOLLOW_SPEED * (JunctionRoom.LEAP_SPEED_SCALE if lift > 0.0 or dashing else 1.0) * step)
			var bait_x: float = JunctionRoom.WOLF_BAIT_X if wolf_x + M0Actor.WOLF_REACH > SentryBrain.LANE_ENTRY_X else -1.0
			brain.watch_x = wolf_x if bait_x >= 0.0 else -1.0
			brain.tick(step, 500.0, false, bait_x)
			lift = JunctionRoom.wolf_leap_height(wolf_x, brain.x)
			var duck: float = JunctionRoom.wolf_duck_depth(wolf_x, 1.0)
			deepest_duck = maxf(deepest_duck, duck)
			if lift >= JunctionRoom.LEAP_HEIGHT - 0.01 and not leapt:
				crossing_low = minf(crossing_low, brain.x)
			leapt = leapt or lift >= JunctionRoom.LEAP_HEIGHT - 0.01
			if lift < JunctionRoom.LEAP_HEIGHT - 0.01:
				through_in = minf(through_in, absf(wolf_x - brain.x))
			if absf(wolf_x - DropArm.MARK_X) < 140.0:
				near_tank[Vector3i(roundi(wolf_x), roundi(lift * 2.0), roundi(duck * 2.0))] = true
		bounded += 1 if leapt and is_equal_approx(wolf_x, JunctionRoom.WOLF_BAIT_X) and JunctionRoom.wolf_leap_height(wolf_x, brain.x) < 0.5 else 0
		# A miss with WOLF by the hatch: he breaks off there and holds; the sentry turns on an engineer
		# over the rubble, gives up and patrols again, turning short of him.
		var arm: DropArm = DropArm.new()
		arm.drop()
		arm.advance(DropArm.FALL_SECONDS, brain.x + 100.0)
		brain.alert()
		brain.watch_x = -1.0
		brain.far_x = far_x
		for _frame: int in 480:
			arm.advance(step, brain.x)
			brain.obstacle = DropArm.footprint() if arm.blocks_lane() else Vector2.ZERO
			brain.tick(step, 500.0, false, -1.0)
			held_clear = held_clear and brain.x + SentryBrain.HALF_WIDTH + MainScript.WOLF_SENTRY_GAP <= JunctionRoom.WOLF_BAIT_X - M0Actor.WOLF_REACH + 0.01
			if brain.state == &"patrol":
				patrol_far = maxf(patrol_far, brain.x)
	_expect(bounded == 40, "on every walk in WOLF bounds over the sentry and lands on the floor at his spot by the hatch (%d of 40)" % bounded)
	_expect(through_in >= clear, "WOLF never crosses the sentry on the floor walking in to draw it (closest %.1f px)" % through_in)
	_expect(crossing_low >= SentryBrain.PATROL_MAX_X - 0.5, "he always catches it at the end of its patrol, right of the tank (lowest %.1f)" % crossing_low)
	_expect(deepest_duck >= JunctionRoom.DUCK_DEPTH - 0.01, "running under the hung tank he ducks")
	var tank: Dictionary = _tank_pixels(TANK_CLEARANCE)
	var touching: Array[String] = []
	for key: Vector3i in near_tank:
		var wolf_pixels: Dictionary = _wolf_pixels(key.z)
		var lift_px: int = roundi(key.y * 0.5)
		for offset: Vector2i in wolf_pixels:
			if tank.has(Vector2i(key.x + offset.x, roundi(feet_y) + offset.y - lift_px)):
				touching.append("x %d lift %.1f duck %.1f" % [key.x, key.y * 0.5, key.z * 0.5])
				break
	_expect(touching.is_empty(), "WOLF's painted body stays %.0f px clear of the hung tank's on every frame of the walk in (%d near-tank frames checked; touching at %s)" % [TANK_CLEARANCE, near_tank.size(), ", ".join(touching.slice(0, 4))])
	_expect(held_clear and patrol_far <= far_x + 0.01 and patrol_far >= DropArm.MARK_X + DropArm.HIT_REACH, "after the miss the sentry never reaches WOLF holding by the hatch, and its patrol turns short of him (furthest %.1f, turn %.1f)" % [patrol_far, far_x])


## The hung tank's painted pixels (alpha over half) in world pixels, grown by [param grow] px.
func _tank_pixels(grow: float) -> Dictionary:
	var image: Image = JunctionRoom.TANK_PROP.get_image()
	var scale: float = JunctionRoom.TANK_ART_SCALE
	var origin: Vector2 = Vector2(DropArm.MARK_X, JunctionRoom.TANK_REST_Y) - Vector2(image.get_size()) * scale * 0.5
	var painted: Array[Vector2i] = []
	for wy: int in range(floori(origin.y) - 1, ceili(origin.y + image.get_height() * scale) + 1):
		for wx: int in range(floori(origin.x) - 1, ceili(origin.x + image.get_width() * scale) + 1):
			var tx: int = floori((wx + 0.5 - origin.x) / scale)
			var ty: int = floori((wy + 0.5 - origin.y) / scale)
			if tx >= 0 and ty >= 0 and tx < image.get_width() and ty < image.get_height() and image.get_pixel(tx, ty).a > 0.5:
				painted.append(Vector2i(wx, wy))
	var reach: int = ceili(grow)
	var pixels: Dictionary = {}
	for pixel: Vector2i in painted:
		for dy: int in range(-reach, reach + 1):
			for dx: int in range(-reach, reach + 1):
				if dx * dx + dy * dy <= grow * grow:
					pixels[pixel + Vector2i(dx, dy)] = true
	return pixels


## WOLF's painted pixels (alpha over half), facing right, at his rest scale squashed from the top by
## [param duck_halves] half px with his feet on the floor (Main's duck), as world-pixel offsets from his
## x and his feet row. Cached per duck.
func _wolf_pixels(duck_halves: int) -> Dictionary:
	if _wolf_pixel_cache.has(duck_halves):
		return _wolf_pixel_cache[duck_halves]
	var image: Image = (load("res://assets/wolf-side-right-provisional.png") as Texture2D).get_image()
	var scale_x: float = 0.18325
	var squash: float = (MainScript.WOLF_DRAWN_HEIGHT - duck_halves * 0.5) / MainScript.WOLF_DRAWN_HEIGHT
	var scale_y: float = scale_x * squash
	# The texture's centre sits WOLF_FEET_BELOW_CENTRE texture px above his feet.
	var centre_y: float = -MainScript.WOLF_FEET_BELOW_CENTRE * scale_y
	var pixels: Dictionary = {}
	for dy: int in range(-70, 4):
		for dx: int in range(-75, 76):
			var tx: int = floori((dx + 0.5) / scale_x + image.get_width() * 0.5)
			var ty: int = floori((dy + 0.5 - centre_y) / scale_y + image.get_height() * 0.5)
			if tx >= 0 and ty >= 0 and tx < image.get_width() and ty < image.get_height() and image.get_pixel(tx, ty).a > 0.5:
				pixels[Vector2i(dx, dy)] = true
	_wolf_pixel_cache[duck_halves] = pixels
	return pixels


## WOLF's painted body at rest, from his art: how far it reaches behind his origin (x, his tail) and
## ahead of it (y, his snout), in world px.
func _wolf_art_reach() -> Vector2:
	var image: Image = (load("res://assets/wolf-side-right-provisional.png") as Texture2D).get_image()
	var left: int = image.get_width()
	var right: int = -1
	for x: int in image.get_width():
		for y: int in image.get_height():
			if image.get_pixel(x, y).a > 0.5:
				left = mini(left, x)
				right = maxi(right, x)
				break
	var scale: float = 0.18325
	var centre: float = image.get_width() * 0.5
	return Vector2((centre - left) * scale, (right + 1 - centre) * scale)


## How far below WOLF's sprite centre his painted feet reach, in world px.
func _wolf_art_feet() -> float:
	var image: Image = (load("res://assets/wolf-side-right-provisional.png") as Texture2D).get_image()
	var bottom: int = 0
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x, y).a > 0.5:
				bottom = y
				break
	return (bottom + 1 - image.get_height() * 0.5) * 0.18325


## True while some player in the sound bank is playing [param clip].
func _sounding(game: Node2D, clip: StringName) -> bool:
	var sfx: SfxBank = game.get("sfx_bank") as SfxBank
	for player: AudioStreamPlayer in sfx.players():
		if player.playing and player.stream == sfx.streams.get(clip):
			return true
	return false


func _wait_until(condition: Callable, frames: int) -> bool:
	for _frame: int in range(frames):
		await physics_frame
		if condition.call():
			return true
	return false


func _walk_to(actor: M0Actor, target_x: float) -> bool:
	var action: StringName = &"move_right" if target_x > actor.position.x else &"move_left"
	Input.action_press(action)
	var reached: bool = false
	for _frame: int in range(300):
		await physics_frame
		if absf(actor.position.x - target_x) <= 12.0:
			reached = true
			break
	Input.action_release(action)
	return reached


func _expect(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		push_error("Sentry check failed: " + label)


func _require(condition: bool, label: String) -> bool:
	_expect(condition, label)
	if not condition:
		quit(1)
	return condition
