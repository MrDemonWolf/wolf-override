extends SceneTree
## Blowback beats 4-6: the sentry brain and the drop arm as pure logic, the junction's later guards
## and saves, and the scene routes past the door (WOLF draws the sentry; the engineer times the drop
## alone after WOLF refuses; a miss with its cloud and rewind; sentry and cloud knockdowns back to
## autosave B; the exit bolt, the closing beat and Continue from B, C and D).

const GAME_SCENE: PackedScene = preload("res://scenes/main.tscn")
const State = preload("res://scripts/m0_state.gd")

var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_brain()
	_check_arm()
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
	_expect(is_equal_approx(SentryBrain.PATROL_MIN_X - SentryBrain.HALF_WIDTH, SentryBrain.COVER_MAX_X + M0State.HUMAN_HALF_WIDTH), "the patrol turns where its front edge meets an engineer at the alcove's right end")
	_expect(SentryBrain.PATROL_MIN_X < DropArm.MARK_X - DropArm.HIT_REACH and SentryBrain.PATROL_MAX_X > DropArm.MARK_X + DropArm.HIT_REACH, "the patrol still crosses the whole hit window")
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
	var sliced: SentryBrain = _patrolling_at(700.0, -1.0)
	var whole: SentryBrain = _patrolling_at(700.0, -1.0)
	sliced.tick(0.001, 600.0, true, -1.0)
	whole.tick(0.001, 600.0, true, -1.0)
	for _frame: int in 48:
		sliced.tick(1.0 / 60.0, 600.0, true, -1.0)
	whole.tick(0.8, 600.0, true, -1.0)
	_expect(sliced.state == &"chase" and whole.state == &"chase" and absf(sliced.x - whole.x) < 0.01, "sliced and whole deltas leave the beat and chase alike (%.2f vs %.2f)" % [sliced.x, whole.x])
	_expect(is_equal_approx(seen_x - whole.x, SentryBrain.CHASE_SPEED * (0.8 - SentryBrain.LOCK_SECONDS)), "0.8 s after seeing the engineer it has chased only for the time after the beat")
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
	_expect(edge_overlap >= SentryBrain.HALF_WIDTH, "at the edge of the hit window at least half of the sentry's body is over the brackets (%.0f px)" % edge_overlap)
	_expect(DropArm.is_hit(DropArm.MARK_X - DropArm.HIT_REACH) and DropArm.is_hit(DropArm.MARK_X + DropArm.HIT_REACH) and not DropArm.is_hit(DropArm.MARK_X - DropArm.HIT_REACH - 1.0) and not DropArm.is_hit(DropArm.MARK_X + DropArm.HIT_REACH + 1.0), "the hit window is the sentry's middle inside the brackets")
	_expect(not DropArm.is_hit(DropArm.MARK_X + DropArm.HIT_RANGE + SentryBrain.HALF_WIDTH - 3.0) and not DropArm.is_hit(DropArm.MARK_X - DropArm.HIT_RANGE - SentryBrain.HALF_WIDTH + 3.0), "a graze, a few pixels of the body over a bracket, is a miss")
	var arm: DropArm = DropArm.new()
	_expect(arm.state == &"hung" and arm.drop_amount() == 0.0 and arm.advance(1.0, 700.0) == &"", "a hung tank waits")
	_expect(arm.drop() and arm.state == &"falling" and not arm.drop(), "the clamp lets go once")
	_expect(arm.advance(0.44, 700.0) == &"" and arm.drop_amount() > 0.5 and arm.drop_amount() < 1.0, "0.44 s into the fall it is still falling")
	_expect(arm.advance(0.02, DropArm.MARK_X + DropArm.HIT_REACH) == &"hit" and arm.state == &"landed" and arm.drop_amount() == 1.0, "it lands at 0.45 s on a sentry with half its body in the brackets")
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
	# Route 1: the relay risk was disclosed, so WOLF chooses to draw the sentry onto the mark.
	var b_dict: Dictionary = await _start_at_b(game, State.DISCLOSE)
	_expect(brain.state == &"patrol" and brain.x > SentryBrain.PATROL_MAX_X - 60.0 and brain.facing < 0.0 and arm.state == &"hung" and room.tank.position.y == JunctionRoom.TANK_REST_Y and not room.mark_lit(), "autosave B: the sentry patrols from the far end under a hung tank, outside the brackets")
	_expect(game.call("_objective") == "CHECK THE LANE", "before WOLF mentions the tank the card says to check the lane")
	game.call("_load_game")
	_expect((game.get("state") as M0State).door_blown and brain.state == &"patrol" and brain.x == SentryBrain.PATROL_MAX_X and str(game.get("status_line")).contains("door is down"), "Continue from autosave B restores the live lane")
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
	# Box, hint and picture agree on every frame: the "Wait" and the wait hint stay up exactly until the
	# sentry is parked, and on that frame the line says it has stopped and the hint offers the drop.
	var agreed: Array[bool] = [true]
	_expect(await _wait_until(func() -> bool:
		# Where the two drawn bodies could meet he is up over the sentry; elsewhere they stay apart.
		var lift: float = -wolf.body_sprite.offset.y * wolf.body_sprite.scale.y
		highest_bound[0] = maxf(highest_bound[0], lift)
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
	# While WOLF holds it, its beam watches only him: it ends short of the alcove, never on the engineer.
	await physics_frame
	var fixated_tip: float = Sentry.beam_tip_x(brain.x, room.sentry.visual.scale.x, true)
	_expect(room.sentry.fixated and room.sentry.visual.scale.x > 0.0 and fixated_tip >= SentryBrain.COVER_MAX_X + SentryBrain.CONTACT_RANGE and is_equal_approx(fixated_tip, Sentry.FIXATED_BEAM_FAR_X) and is_equal_approx(room.sentry.visual.reach, absf(fixated_tip - room.sentry.position.x)) and room.sentry.visual.gap == Vector2.ZERO, "the fixated sentry looks away from the TANK RELEASE alcove, its beam ending at WOLF's snout (tip %.0f)" % fixated_tip)
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
	_expect(room.arm_label.text == "RELEASE SPENT" and room.tank_label.visible and room.tank_label.text == "TANK DOWN" and absf(room.tank_label.position.x + room.tank_label.size.x * 0.5 - DropArm.MARK_X) < 0.5, "the release reads spent and TANK DOWN sits over the tank")
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
	# The two leave through the open hatch before the card: they walk into it and fade out.
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
	_expect(await _wait_until(func() -> bool: return bool(game.get("end_card_active")), 120), "the END OF SLICE card follows the walk")
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
	_expect(str(game.get("status_line")).contains("WOLF: I'm out"), "WOLF says he is breaking off")
	human.position.x = 500.0
	await physics_frame
	_expect(str(game.call("_context_hint")).contains("until it gives up"), "back over the rubble the hint says to wait out the chase")
	_expect(await _wait_until(func() -> bool: return brain.state == &"patrol", 240), "the chase ends with the engineer over the rubble")
	_expect(str(game.call("_context_hint")).contains("WOLF has broken off"), "then the hint says WOLF has stepped back")
	await _check_engineer_alone(game, path)
	await _check_cloud(game, path)
	await _check_chased_cards(game, path)
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
	_expect(refusal.begins_with("WOLF: At the relay") and refusal.contains("Time the drop from the panel") and not refusal.contains("You said"), "his refusal names the relay choice openly and points at the engineer's way through")
	for _frame: int in 60:
		await physics_frame
	_expect(wolf.position.x <= JunctionRoom.WOLF_RUBBLE_X + 6.0 and brain.state == &"patrol", "WOLF stays at the rubble and the sentry keeps patrolling")
	# Step into its path: it sees, chases and runs the engineer down.
	_expect(await _wait_until(func() -> bool: return brain.facing < 0.0 and brain.x <= 780.0 and brain.x >= 720.0, 300), "the sentry comes back down the lane")
	human.position.x = 640.0
	_expect(await _wait_until(func() -> bool: return brain.state == &"lock", 5), "it sees the engineer and locks on")
	var locked_x: float = brain.x
	_expect(_sounding(game, &"klaxon") and room.sentry.visual.eye == Sentry.SentryVisual.EYE_LOCKED, "locking on turns its eye red with a short alarm")
	for _frame: int in 12:
		await physics_frame
	_expect(brain.state == &"lock" and brain.x == locked_x and absf(room.sentry.position.x - locked_x) <= 4.0 and not game.get("fail_active"), "through the lock-on beat it stands still")
	_expect(str(game.call("_context_hint")).contains("after you"), "the hint warns the engineer as soon as it locks on")
	_expect(await _wait_until(func() -> bool: return game.get("fail_active"), 90), "sentry contact in the lane is a knockdown")
	_expect(str(game.get("status_line")).begins_with(JunctionRoom.SENTRY_REASON % (game.get("state") as M0State).human_name().get_slice(" ", 0)) and str(game.get("status_line")).contains("past the alcove's right post") and str(game.get("status_line")).contains("Keep inside the posts"), "the status line names the sentry and the engineer, says they were caught past the alcove's right post, and points at the alcove or the rubble")
	_expect(SentryBrain.is_exposed(human.position.x) and human.position.x > SentryBrain.COVER_MAX_X, "and the engineer was indeed caught past the right post (x %.0f)" % human.position.x)
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
	_expect(arm.state == &"rewinding" and str(game.get("status_line")).contains("still hauling"), "the panel refuses a second drop during the rewind")
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
	human.position.x = DropArm.MARK_X
	_expect(await _wait_until(func() -> bool: return game.get("fail_active"), 30), "walking into the coolant cloud is a knockdown")
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
	_expect(brain.state == &"patrol" and brain.x >= 830.0 and arm.drop(), "the drop goes with the sentry at the far end")
	_expect(await _wait_until(func() -> bool: return arm.state == &"rewinding", 60) and brain.turned_by_miss, "the miss turns the sentry on the release")
	_expect(await _wait_until(func() -> bool: return game.get("fail_active"), 120), "a chase after a miss runs down an engineer who stays at the release")
	var status: String = str(game.get("status_line"))
	_expect(not SentryBrain.is_exposed(human.position.x) and status.begins_with(chased) and not status.contains("alcove's posts") and not status.contains("in its lane"), "caught between the posts after a miss, the card points only at the rubble (%s)" % status)
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "the knockdown after a miss hands back")
	_expect((game.get("state") as M0State).to_dict() == b_dict and not brain.turned_by_miss, "it restores autosave B with the sentry patrolling again")
	# Seen out in the lane, then caught after ducking into the alcove: the alcove advice would be wrong.
	game.set("lane_choice", "alone")
	_expect(await _wait_until(func() -> bool: return brain.facing < 0.0 and brain.x <= 780.0 and brain.x >= 720.0, 300), "the sentry comes back down the lane")
	human.position.x = 640.0
	_expect(await _wait_until(func() -> bool: return brain.state == &"lock", 5) and not brain.turned_by_miss, "it sees the engineer in the lane")
	human.position.x = JunctionRoom.ARM_X
	_expect(await _wait_until(func() -> bool: return game.get("fail_active"), 120), "the chase reaches the engineer in the alcove")
	status = str(game.get("status_line"))
	_expect(not SentryBrain.is_exposed(human.position.x) and status.begins_with(chased) and not status.contains("alcove's posts"), "caught inside the alcove, the card points only at the rubble (%s)" % status)
	_expect(await _wait_until(func() -> bool: return not game.get("fail_active"), 240), "that knockdown hands back too")


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


## WOLF crosses the lane from the rubble to the far end, answering at many points of the patrol, and
## goes back to the rubble after a miss while the sentry turns on an engineer over the rubble (held at
## the edge of the tank lying on the floor). Wherever the two drawn bodies could meet on either walk he
## is up over the sentry at the full bound (JunctionRoom.wolf_leap_height), so they never overlap; the
## bound clears the sentry's drawn top; and he is back on the floor at both ends.
func _check_bait_walk() -> void:
	var clear: float = SentryBrain.HALF_WIDTH + M0State.WOLF_HALF_WIDTH
	var feet_y: float = 423.0 + (-15.0) + _wolf_art_feet()
	_expect(feet_y - JunctionRoom.LEAP_HEIGHT < Sentry.FLOOR_Y - Sentry.DRAWN_HEIGHT, "at the top of his bound WOLF's painted feet (y %.1f) clear the sentry's drawn top (y %.1f)" % [feet_y - JunctionRoom.LEAP_HEIGHT, Sentry.FLOOR_Y - Sentry.DRAWN_HEIGHT])
	_expect(JunctionRoom.wolf_leap_height(JunctionRoom.WOLF_RUBBLE_X, SentryBrain.CHASE_MIN_X) < 0.5 and JunctionRoom.wolf_leap_height(JunctionRoom.WOLF_BAIT_X, DropArm.MARK_X) == 0.0, "standing at the rubble or at his spot by the hatch he is on the floor")
	var step: float = 1.0 / 60.0
	var through_in: float = INF
	var through_out: float = INF
	var bounded: int = 0
	for phase: int in 40:
		var brain: SentryBrain = SentryBrain.new()
		brain.reset(true, false, DropArm.MARK_X)
		# Patrol for a while first so the answer lands at a different point of the patrol each time.
		brain.tick(phase * 0.12, 500.0, false, -1.0)
		var wolf_x: float = JunctionRoom.WOLF_RUBBLE_X
		var leapt: bool = false
		for _frame: int in 240:
			var lift: float = JunctionRoom.wolf_leap_height(wolf_x, brain.x)
			wolf_x = move_toward(wolf_x, JunctionRoom.WOLF_BAIT_X, M0Actor.FOLLOW_SPEED * (JunctionRoom.LEAP_SPEED_SCALE if lift > 0.0 else 1.0) * step)
			brain.tick(step, 500.0, false, JunctionRoom.WOLF_BAIT_X if wolf_x + M0Actor.WOLF_REACH > SentryBrain.LANE_ENTRY_X else -1.0)
			lift = JunctionRoom.wolf_leap_height(wolf_x, brain.x)
			leapt = leapt or lift >= JunctionRoom.LEAP_HEIGHT - 0.01
			if lift < JunctionRoom.LEAP_HEIGHT - 0.01:
				through_in = minf(through_in, absf(wolf_x - brain.x))
		bounded += 1 if leapt and is_equal_approx(wolf_x, JunctionRoom.WOLF_BAIT_X) else 0
		# A miss: the tank lies in the lane and the sentry turns on an engineer over the rubble while WOLF
		# goes back there.
		var arm: DropArm = DropArm.new()
		arm.drop()
		arm.advance(DropArm.FALL_SECONDS, brain.x + 100.0)
		brain.alert()
		for _frame: int in 180:
			arm.advance(step, brain.x)
			brain.obstacle = DropArm.footprint() if arm.blocks_lane() else Vector2.ZERO
			var lift: float = JunctionRoom.wolf_leap_height(wolf_x, brain.x)
			wolf_x = move_toward(wolf_x, JunctionRoom.WOLF_RUBBLE_X, M0Actor.FOLLOW_SPEED * (JunctionRoom.LEAP_SPEED_SCALE if lift > 0.0 else 1.0) * step)
			brain.tick(step, 500.0, false, -1.0)
			if JunctionRoom.wolf_leap_height(wolf_x, brain.x) < JunctionRoom.LEAP_HEIGHT - 0.01:
				through_out = minf(through_out, absf(wolf_x - brain.x))
		_expect(is_equal_approx(wolf_x, JunctionRoom.WOLF_RUBBLE_X), "after breaking off WOLF is back at the rubble (phase %d, x %.1f)" % [phase, wolf_x])
	_expect(bounded == 40, "on every walk in WOLF bounds over the sentry and reaches his spot by the hatch (%d of 40)" % bounded)
	_expect(through_in >= clear, "WOLF never crosses the sentry on the floor walking in to draw it (closest %.1f px)" % through_in)
	_expect(through_out >= clear, "nor on his way back after a miss (closest %.1f px)" % through_out)


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
