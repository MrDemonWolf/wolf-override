"""Applies the Records doors changes to a copy of main.gd (scratch; exact replacements, each must match once)."""
import sys
p = sys.argv[1]
s = open(p).read()

def rep(old, new, count=1):
    global s
    n = s.count(old)
    if n != count:
        raise SystemExit(f"expected {count} match(es), found {n}: {old[:90]!r}")
    s = s.replace(old, new)

rep("""## (_update_settle). The mirror port's right is WOLF's (WOLF_MIRROR_X). The coolant relay is worked
## from its right, towards the MANUAL BYPASS, clear of where WOLF stands off it (WOLF_BYPASS_CLEAR_X)
## and of his contact (RELAY_SIDE_X).
const CORRIDOR_STATIONS: Array[Vector4] = [Vector4(350.0, 38.0, 52.0, 0.0), Vector4(RELAY_X, 43.0, RELAY_REACH, 1.0), Vector4(876.0, 35.0, 52.0, 0.0)]
const RECORDS_STATIONS: Array[Vector4] = [Vector4(190.0, 56.0, 58.0, 0.0), Vector4(520.0, 45.0, 58.0, -1.0), Vector4(830.0, 38.0, 58.0, 0.0)]
""", """## (_update_settle). The mirror port's right is WOLF's (WOLF_MIRROR_X). The coolant relay is worked
## from its right, towards the MANUAL BYPASS, clear of where WOLF stands off it (WOLF_BYPASS_CLEAR_X)
## and of his contact (RELAY_SIDE_X). The Records security container, where the first copy is
## secured, is worked from its right, where its lock is, towards the exit (RECORDS_CONTAINER_SIDE_X).
const CORRIDOR_STATIONS: Array[Vector4] = [Vector4(350.0, 38.0, 52.0, 0.0), Vector4(RELAY_X, 43.0, RELAY_REACH, 1.0), Vector4(876.0, 35.0, 52.0, 0.0)]
const RECORDS_STATIONS: Array[Vector4] = [Vector4(190.0, 56.0, 58.0, 0.0), Vector4(520.0, 45.0, 58.0, -1.0), Vector4(RecordsRoom.CONTAINER_X, 10.0, 58.0, 1.0)]
## The Records exit's USE reaches this far either side of x 830 (the security container and the exit
## door both stand inside it; once the exit is open it also reaches on through the doorway).
const RECORDS_EXIT_X: float = 830.0
const RECORDS_EXIT_REACH: float = 58.0
## Securing the first copy, the engineer stands at the container's right, their front hand on its lock.
const RECORDS_CONTAINER_SIDE_X: float = RecordsRoom.CONTAINER_X + 21.0
## Leaving Records, the engineer walks through the open exit into the service line passage, and WOLF
## follows to the doorway behind them; the junction begins once they are through.
const RECORDS_WALK_OUT_X: float = 918.0
const RECORDS_WOLF_OUT_X: float = 868.0
""")

rep("""var hatch_exit_walking: bool = false
var hatch_exit_engineer_walking: bool = false
""", """var hatch_exit_walking: bool = false
var hatch_exit_engineer_walking: bool = false
## True while the engineer walks out through the Records exit, from the USE until they are through.
var records_exit_walking: bool = false
""")

rep("""	exit_sparks = FxPresets.sparks(Color("#c1f4d8"))
	exit_sparks.position = Vector2(830.0, 330.0)
""", """	# The exit's electrified strike lets go with a short arc: warm white sparks at the strike.
	exit_sparks = FxPresets.sparks(Color("#ffe2b8"))
	exit_sparks.position = RecordsRoom.EXIT_STRIKE
""")

rep("""	if engineer_step_x < 0.0 or absf(human.position.x - engineer_step_x) > 4.0:
		return
	human.position.x = engineer_step_x
	if engineer_face_x >= 0.0:
		human.body_sprite.flip_h = engineer_face_x < engineer_step_x
	engineer_step_x = -1.0
	engineer_face_x = -1.0
	_update_controls()
""", """	if engineer_step_x < 0.0 or absf(human.position.x - engineer_step_x) > 4.0:
		return
	human.position.x = engineer_step_x
	if engineer_face_x >= 0.0:
		human.body_sprite.flip_h = engineer_face_x < engineer_step_x
	engineer_step_x = -1.0
	engineer_face_x = -1.0
	_update_controls()
	if records_exit_walking:
		# Through the Records exit: the service line to Archive begins.
		records_exit_walking = false
		_enter_junction()
""")

rep("""	if state.checkpoint_reached:
		if state.enter_records():
			_sync_scene()
			# A new room: cut the camera to the engineer instead of panning across from the safe point.
			_start_gameplay_camera()
""", """	if state.checkpoint_reached:
		if state.enter_records():
			_sync_scene()
			# They came in through the entry: it stands open behind them and its closer brings it shut.
			records_room.close_entry_behind()
			# A new room: cut the camera to the engineer instead of panning across from the safe point.
			_start_gameplay_camera()
""")

rep("""	elif absf(x - 830.0) <= 58.0:
		if state.complete_chapter():
			status_line = "FIRST COPY SECURED. WOLF: An order and a timestamp don't tell me who's a threat. I want the source.\\n%s: Then Archive is next." % state.human_name().get_slice(" ", 0).to_upper()
			chapter_close_active = true
""", """	elif _at_records_exit(x):
		if state.complete_chapter():
			# The copy goes into the security container, at its lock; the exit's bolt lets go and the door
			# swings open (RecordsRoom.open_exit).
			_step_engineer(RECORDS_CONTAINER_SIDE_X, RecordsRoom.CONTAINER_X)
			status_line = "FIRST COPY SECURED. WOLF: An order and a timestamp don't tell me who's a threat. I want the source.\\n%s: Then Archive is next." % state.human_name().get_slice(" ", 0).to_upper()
			chapter_close_active = true
""")

rep("""			chapter_tween = create_tween()
			_frame_chapter_close()
			chapter_tween.parallel().tween_property(records_room.exit_art, "position:y", RecordsRoom.EXIT_REST.y - 130.0, 0.5)
			chapter_tween.parallel().tween_property(records_room.exit_art, "modulate:a", 0.0, 0.5)
			chapter_tween.tween_callback(records_room.exit_art.hide)
			_save_progress()
		elif state.chapter_complete:
			_enter_junction()
		else:
""", """			chapter_tween = create_tween()
			_frame_chapter_close()
			_save_progress()
		elif state.chapter_complete:
			_leave_records()
		else:
""")

rep("""## Between Records stations: the stations still to do, in order, so a finished one is never named
""", """## The Records exit's USE: the security container and the shut exit within RECORDS_EXIT_REACH of x
## 830, and, once the exit is open, the doorway and the passage past it too.
func _at_records_exit(x: float) -> bool:
	return absf(x - RECORDS_EXIT_X) <= RECORDS_EXIT_REACH or (state.chapter_complete and x >= RECORDS_EXIT_X)


## USE at the open exit once the first copy is secured: the engineer walks out through the doorway
## into the service line passage, WOLF behind them to the door, and the junction begins once they are
## through (_tick_engineer_step).
func _leave_records() -> void:
	if records_exit_walking:
		return
	records_exit_walking = true
	engineer_step_x = RECORDS_WALK_OUT_X
	engineer_face_x = -1.0
	_update_controls()


## Between Records stations: the stations still to do, in order, so a finished one is never named
""")

rep("""	_stop_junction_loops()
	_stop_bypass_vent()
	intro_fade.color.a = 0.0
	chapter_close_active = false
	hatch_exit_walking = false
	hatch_exit_engineer_walking = false
""", """	_stop_junction_loops()
	_stop_bypass_vent()
	intro_fade.color.a = 0.0
	chapter_close_active = false
	hatch_exit_walking = false
	hatch_exit_engineer_walking = false
	records_exit_walking = false
""")

rep("""	# Walked out through the hatch, the actors faded; any new scene shows them again.
	hatch_exit_walking = false
	hatch_exit_engineer_walking = false
""", """	# Walked out through the hatch, the actors faded; any new scene shows them again.
	hatch_exit_walking = false
	hatch_exit_engineer_walking = false
	records_exit_walking = false
""")

rep("""	human.position = state.human_position
	# A sidestep worked out in the room left behind never carries over into the new placing.
	human.settle_x = -1.0
	_clear_station_body()
	wolf.position = state.wolf_position
""", """	human.position = state.human_position
	# A sidestep worked out in the room left behind never carries over into the new placing.
	human.settle_x = -1.0
	_clear_station_body()
	wolf.position = state.wolf_position
	if state.chapter_id == "records":
		# Records' doors stand across the walkway: a save from before they did (when the room's ends
		# were open floor) never places anyone inside the shut entry or past the exit before it opens.
		var right_face: float = RecordsRoom.EXIT_DOOR_X if not state.chapter_complete else M0Actor.MAX_X + M0State.WOLF_HALF_WIDTH
		human.position.x = clampf(human.position.x, RecordsRoom.ENTRY_DOOR_X + M0State.HUMAN_HALF_WIDTH, right_face - M0State.HUMAN_HALF_WIDTH)
		wolf.position.x = clampf(wolf.position.x, RecordsRoom.ENTRY_DOOR_X + M0State.WOLF_HALF_WIDTH, right_face - M0State.WOLF_HALF_WIDTH)
""")

rep("""	records_room.purge_trace_preserved = state.purge_trace_preserved
	records_room.mirror_trace_preserved = state.mirror_trace_preserved
	records_room.chapter_complete = state.chapter_complete
	records_room.exit_art.position = RecordsRoom.EXIT_REST
	records_room.exit_art.modulate = Color.WHITE
	records_room.exit_art.visible = not state.chapter_complete or animate_exit
	records_room.refresh_state()
""", """	records_room.purge_trace_preserved = state.purge_trace_preserved
	records_room.mirror_trace_preserved = state.mirror_trace_preserved
	records_room.chapter_complete = state.chapter_complete
	if animate_exit and state.chapter_complete:
		# The secured copy releases the exit: its leaf swings open on its hinges, never vanishing.
		records_room.open_exit(true)
	records_room.refresh_state()
""")

rep("""	if hatch_exit_walking:
		# He goes through the hatch first, from his spot in its doorway.
		return WOLF_HATCH_EXIT_X
""", """	if hatch_exit_walking:
		# He goes through the hatch first, from his spot in its doorway.
		return WOLF_HATCH_EXIT_X
	if records_exit_walking:
		# Leaving Records he follows the engineer to the exit's doorway.
		return RECORDS_WOLF_OUT_X
""")

rep("""			halves = [Vector2(190.0, 57.1), Vector2(520.0, 44.6), Vector2(RecordsRoom.EXIT_REST.x, 37.8)]
""", """			halves = [Vector2(190.0, 57.1), Vector2(520.0, 44.6), Vector2((RecordsRoom.CONTAINER_SPAN.x + RecordsRoom.CONTAINER_SPAN.y) * 0.5, (RecordsRoom.CONTAINER_SPAN.y - RecordsRoom.CONTAINER_SPAN.x) * 0.5)]
""")

rep("""	if state.chapter_id == "junction" and not state.door_blown:
		return M0State.JUNCTION_DOOR_LEFT_X - M0Actor.WOLF_REACH
	return M0Actor.MAX_X
""", """	if state.chapter_id == "junction" and not state.door_blown:
		return M0State.JUNCTION_DOOR_LEFT_X - M0Actor.WOLF_REACH
	if state.chapter_id == "records" and not state.chapter_complete:
		return RecordsRoom.EXIT_DOOR_X - M0Actor.WOLF_REACH
	return M0Actor.MAX_X


## The furthest left WOLF follows to: in Records, clear of the shut entry by his drawn reach.
func _wolf_follow_min_x() -> float:
	if state.chapter_id == "records":
		return RecordsRoom.ENTRY_DOOR_X + M0Actor.WOLF_REACH
	return M0Actor.MIN_X
""")

rep("""	wolf.follow_max_x = _wolf_follow_max_x()
""", """	wolf.follow_max_x = _wolf_follow_max_x()
	wolf.follow_min_x = _wolf_follow_min_x()
""")

rep("""		if state.chapter_complete:
			return "E: follow the service line toward Archive." if absf(x - 830.0) <= 58.0 else "The exit is open. Head right to follow the service line."
""", """		if state.chapter_complete:
			return "E: follow the service line toward Archive." if _at_records_exit(x) else "The exit is open. Head right to follow the service line."
""")

rep("""		if absf(x - 830.0) <= 58.0:
			return "E: secure the first copy." if state.mirror_trace_preserved else "Preserve both traces before leaving."
""", """		if _at_records_exit(x):
			return "E: secure the first copy." if state.mirror_trace_preserved else "Preserve both traces before leaving."
""")

rep("""	if hatch_exit_walking:
		return "walking out"
""", """	if hatch_exit_walking or records_exit_walking:
		return "walking out"
""")
open(p, "w").write(s)
print("ok")
