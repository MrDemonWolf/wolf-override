class_name M0State
extends RefCounted
## The slice's progress and the checkpoint file that keeps it: who the engineer is, where both actors
## stand, the relay choice WOLF remembers and every chapter beat. to_dict and from_dict are the save
## format (from_dict rejects anything a real run could not produce); save_to_disk and load_from_disk
## write and read it without losing newer progress to a failed write.

const SAVE_VERSION: int = 5
const SAVE_PATH: String = "user://m0-save.json"
## The save file's write counter, one higher at every save_to_disk. It sits beside to_dict()'s fields
## rather than in them, so it is not progress: from_dict ignores it, and older builds load the file too.
const GENERATION_KEY: String = "generation"
## The counter's ceiling: 2^53, the largest whole number JSON's doubles hold exactly. One save a second
## would take 285 million years to reach it.
const MAX_GENERATION: int = 9007199254740992
## The largest checkpoint file read. A v4 save is under 1 KiB even with the longest choice wording
## (MAX_SELECTED_TEXT_LENGTH), so 64 KiB, the settings file's limit (GameSettings.MAX_SETTINGS_BYTES),
## leaves room for every future field while a huge or wrong file is turned away before it is read.
const MAX_CHECKPOINT_BYTES: int = 65536
const CHAPTER_IDS: Array[String] = ["lockdown", "records", "junction", "investigation"]
const EVENT_ID: String = "relay_disagreement"
const DISCLOSE: String = "disclose_risk"
const PRESS: String = "press_without_warning"
const HUMAN_NAMES = ["Rowan Vale", "Alex Bennett", "Morgan Reed"]
const MAX_SELECTED_TEXT_LENGTH: int = 200
## Half the width of each actor's body (28 px engineer, 44 px WOLF), as main.tscn shapes them. WOLF's
## was 62 px before he was drawn at a real wolf's size (Main.WOLF_ART_SCALE, 2026-10-19); it shrank with
## his art, 62 x 0.70 rounded up to an even 44, so it still spans his legs and chest.
const HUMAN_HALF_WIDTH: float = 14.0
const WOLF_HALF_WIDTH: float = 22.0
## The Service Junction's sealed door face; until the door is blown nobody can stand past it.
const JUNCTION_DOOR_LEFT_X: float = 452.0
## The engineer's two answers at the relay. A save keeps the words its player saw (memory
## "selected_text"), so a save made before option 2 was reworded on 2026-10-13 ("Go now. We can talk
## after.") still quotes those words in WOLF's callback.
const CHOICE_TEXT = {
	"disclose_risk": "The relay may vent coolant. Your call.",
	"press_without_warning": "Skip the risk talk. Go now.",
}
## The saved ways the junction's sentry can have come down (lane_recap), empty before it falls:
## WOLF drew it, he refused, the engineer timed it with WOLF held back by the valve, or he broke off by the
## exit hatch after a miss.
const LANE_RECAPS: Array[String] = ["", "wolf", "refused", "alone", "broke_off"]

var active_actor: String = "human"
var name_index: int = 0
var human_position: Vector2 = Vector2(160.0, 410.0)
## WOLF starts one follow gap (M0Actor.FOLLOW_GAP) behind the engineer, clear of his body.
var wolf_position: Vector2 = Vector2(160.0 - M0Actor.FOLLOW_GAP, 423.0)
var memory: Dictionary = {}
var breaker_armed: bool = false
var door_open: bool = false
var route: String = ""
var checkpoint_reached: bool = false
var chapter_id: String = "lockdown"
var purge_trace_preserved: bool = false
var mirror_trace_preserved: bool = false
var mirror_route: String = ""
var chapter_complete: bool = false
## Service Junction progress (save v4), in order: the sealed door blown, the sentry down, the exit bolt popped.
var door_blown: bool = false
var sentry_down: bool = false
var junction_cleared: bool = false
## Ordered annex progress: 0 none, 1 fragment, 2 controller, 3 escort/repair, 4 explicit chapter exit.
var investigation_step: int = 0
## How the sentry came down, for the END OF SLICE recap: "wolf" (he drew it onto the mark), "refused"
## (he would not, so the engineer timed it), "alone" (he held back by the valve while the engineer timed
## it), or empty before the fall. Optional in the file, so v4 saves without it still load.
var lane_recap: String = ""


## The engineer's name from HUMAN_NAMES at name_index.
func human_name() -> String:
	return HUMAN_NAMES[name_index]


## Steps name_index to the next of HUMAN_NAMES, wrapping round.
func cycle_name() -> void:
	name_index = (name_index + 1) % HUMAN_NAMES.size()


## Saves the engineer's answer at the relay as WOLF's memory (the six fields from_dict checks, with the
## words from CHOICE_TEXT). [param choice_id] is DISCLOSE or PRESS. False, changing nothing, when an
## answer is already saved or the id is unknown.
func record_choice(choice_id: String) -> bool:
	if not memory.is_empty() or not CHOICE_TEXT.has(choice_id):
		return false
	memory = {
		"event_id": EVENT_ID,
		"choice_id": choice_id,
		"selected_text": CHOICE_TEXT[choice_id],
		"context": "breaker_relay_risk",
		"sequence": 1,
		"observed_by": ["human", "wolf"],
	}
	return true


## Arms the breaker. False, changing nothing, before the relay answer or once it is armed.
func arm_breaker() -> bool:
	if memory.is_empty() or breaker_armed:
		return false
	breaker_armed = true
	return true


## Powers the relay as [param actor_id] ("wolf" or "human") and opens the door. Returns the route taken,
## "cooperate" (WOLF) or "fallback" (the engineer), which it also stores; or, changing nothing,
## "not_ready" (breaker not armed), "already_open", "refused" (WOLF was not told the risk) or
## "invalid_actor".
func activate_power(actor_id: String) -> String:
	if not breaker_armed:
		return "not_ready"
	if door_open:
		return "already_open"
	if actor_id == "wolf":
		if memory.get("choice_id") != DISCLOSE:
			return "refused"
		route = "cooperate"
	elif actor_id == "human":
		route = "fallback"
	else:
		return "invalid_actor"
	door_open = true
	return route


## Marks the corridor's safe point reached. False, changing nothing, before the door opens or once reached.
func reach_checkpoint() -> bool:
	if not door_open or checkpoint_reached:
		return false
	checkpoint_reached = true
	return true


## Moves the chapter from "lockdown" to "records" and stands both actors at the records room's entry
## spots (world px). False, changing nothing, before the checkpoint or outside "lockdown".
func enter_records() -> bool:
	if not checkpoint_reached or chapter_id != "lockdown":
		return false
	chapter_id = "records"
	# WOLF comes in one follow gap ahead: he heads straight for the mirror, so he never starts by
	# walking through the engineer.
	human_position = Vector2(128.0, 410.0)
	wolf_position = Vector2(216.0, 423.0)
	return true


## Marks the purge trace kept. False, changing nothing, outside "records" or once kept.
func preserve_purge_trace() -> bool:
	if chapter_id != "records" or purge_trace_preserved:
		return false
	purge_trace_preserved = true
	return true


## Marks the mirror trace kept and stores [param selected_route] ("wolf" or "manual") as mirror_route.
## False, changing nothing, outside "records", before the purge trace, once kept or for any other route.
func preserve_mirror_trace(selected_route: String) -> bool:
	if chapter_id != "records" or not purge_trace_preserved or mirror_trace_preserved or (selected_route != "wolf" and selected_route != "manual"):
		return false
	mirror_trace_preserved = true
	mirror_route = selected_route
	return true


## Closes the records chapter once both traces are kept. False, changing nothing, otherwise or once closed.
func complete_chapter() -> bool:
	if chapter_id != "records" or not purge_trace_preserved or not mirror_trace_preserved or chapter_complete:
		return false
	chapter_complete = true
	return true


## The Records exit leads into the Service Junction once the first copy is secured.
func enter_junction() -> bool:
	if chapter_id != "records" or not chapter_complete:
		return false
	chapter_id = "junction"
	# WOLF comes in one follow gap ahead, already on his way to read the door seam.
	human_position = Vector2(120.0, 410.0)
	wolf_position = Vector2(208.0, 423.0)
	return true


## Marks the junction's sealed door blown. False, changing nothing, outside "junction" or once blown.
func blow_door() -> bool:
	if chapter_id != "junction" or door_blown:
		return false
	door_blown = true
	return true


## The hanging tank came down on the sentry; only after the door is down.
func drop_sentry() -> bool:
	if chapter_id != "junction" or not door_blown or sentry_down:
		return false
	sentry_down = true
	return true


## The exit bolt is popped and the engineer leaves by the hatch; only once the sentry is down.
func clear_junction() -> bool:
	if chapter_id != "junction" or not sentry_down or junction_cleared:
		return false
	junction_cleared = true
	return true


## Whether WOLF chooses to draw the sentry under the tank when asked: the same rule as the relay
## contact. He takes the risk only if he was told about the last one; the engineer can always time
## the drop alone.
func wolf_will_bait() -> bool:
	return memory.get("choice_id") == DISCLOSE


## Enters the annex only after the junction exit is open; positions are world px in reused Records art.
func enter_investigation() -> bool:
	if chapter_id != "junction" or not junction_cleared:
		return false
	chapter_id = "investigation"
	human_position = Vector2(128.0, 410.0)
	wolf_position = Vector2(216.0, 423.0)
	return true


## Keeps the next beat (1..4), rejecting skipped, repeated or out-of-room reads without changing state.
func investigate(next_step: int) -> bool:
	if chapter_id != "investigation" or next_step != investigation_step + 1 or next_step > 4:
		return false
	investigation_step = next_step
	return true


## WOLF's callback at the corridor's safe point: he quotes the answer the engineer gave at the relay and
## says what came of it, or "" before the safe point or with no answer saved. The quote is the English the
## save keeps ("selected_text", which may be an older wording); his words are built with I18n.format and
## the quote as a quoted insert, so I18n.shown draws both in the current language (localization PR L7c)
## and the line the game keeps stays English.
func checkpoint_callback() -> String:
	if not checkpoint_reached or memory.is_empty():
		return ""
	var said: String = str(memory.get("selected_text", ""))
	if memory.get("choice_id") == PRESS:
		# TRANSLATORS: WOLF's callback at the safe point. %s is the answer the engineer chose at the relay, as the game shows it; keep the quotation marks round it in your language's style. Avoid a past tense that shows the engineer's gender ("you said", "you found").
		# i18n: story speaker=WOLF engineer=you slot=choice keep-breaks
		return "WOLF: " + I18n.format(I18n.KEY.tr("You said \"%s\"\nI refused. You found another way. Next time, tell me what it costs."), [said], [0])
	if route == "cooperate":
		# TRANSLATORS: WOLF's callback at the safe point. %s is the answer the engineer chose at the relay, as the game shows it; keep the quotation marks round it in your language's style. Avoid a past tense that shows the engineer's gender ("you said").
		# i18n: story speaker=WOLF engineer=you slot=choice keep-breaks
		return "WOLF: " + I18n.format(I18n.KEY.tr("You said \"%s\"\nI chose the relay. We made it."), [said], [0])
	# Told the risk, he offered the contact; the engineer cranked the manual bypass instead.
	# TRANSLATORS: WOLF's callback at the safe point. %s is the answer the engineer chose at the relay, as the game shows it; keep the quotation marks round it in your language's style. Avoid a past tense that shows the engineer's gender ("you said", "you cranked").
	# i18n: story speaker=WOLF engineer=you slot=choice keep-breaks
	return "WOLF: " + I18n.format(I18n.KEY.tr("You said \"%s\"\nI made my call. You cranked the bypass anyway. I stayed."), [said], [0])


## The save format (SAVE_VERSION) as a fresh Dictionary: identity, both positions as [x, y] world px,
## a deep copy of memory, the puzzle, the chapter and the junction's beats. from_dict reads it back.
func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"identity": {"actor_id": "human", "name_index": name_index},
		"active_actor": "human",
		"positions": {
			"human": [human_position.x, human_position.y],
			"wolf": [wolf_position.x, wolf_position.y],
		},
		"memory": memory.duplicate(true),
		"puzzle": {"breaker_armed": breaker_armed, "door_open": door_open, "route": route},
		"checkpoint_reached": checkpoint_reached,
		"chapter_id": chapter_id,
		"purge_trace_preserved": purge_trace_preserved,
		"mirror_trace_preserved": mirror_trace_preserved,
		"mirror_route": mirror_route,
		"chapter_complete": chapter_complete,
		"door_blown": door_blown,
		"sentry_down": sentry_down,
		"junction_cleared": junction_cleared,
		"lane_recap": lane_recap,
		"investigation_step": investigation_step,
	}


## The state a save holds, or null when [param raw] is not one a real run could produce: a wrong type or
## version, a field out of range, a position off the floor, or beats out of their order. Reads save
## versions 1 to SAVE_VERSION; fields a version lacks keep their defaults. Has no side effects.
static func from_dict(raw: Variant) -> M0State:
	if not (raw is Dictionary):
		return null
	var data: Dictionary = raw
	if not _whole_in_range(data.get("version"), 1, SAVE_VERSION):
		return null
	var raw_identity: Variant = data.get("identity")
	var raw_positions: Variant = data.get("positions")
	var raw_puzzle: Variant = data.get("puzzle")
	var raw_memory: Variant = data.get("memory")
	if not (raw_identity is Dictionary) or not (raw_positions is Dictionary) or not (raw_puzzle is Dictionary) or not (raw_memory is Dictionary):
		return null
	var identity: Dictionary = raw_identity
	var positions: Dictionary = raw_positions
	var puzzle: Dictionary = raw_puzzle
	var loaded_memory: Dictionary = raw_memory
	if identity.get("actor_id") != "human" or not _whole_in_range(identity.get("name_index"), 0, HUMAN_NAMES.size() - 1):
		return null
	var legacy_wolf_save: bool = data.get("version") == 1 and data.get("active_actor") == "wolf"
	if data.get("active_actor") != "human" and not legacy_wolf_save:
		return null
	if not _valid_position(positions.get("human"), 414.0) or not _valid_position(positions.get("wolf"), 427.0):
		return null
	if typeof(puzzle.get("breaker_armed")) != TYPE_BOOL or typeof(puzzle.get("door_open")) != TYPE_BOOL:
		return null
	if puzzle.get("route") != "" and puzzle.get("route") != "cooperate" and puzzle.get("route") != "fallback":
		return null
	if typeof(data.get("checkpoint_reached")) != TYPE_BOOL:
		return null
	if not loaded_memory.is_empty():
		var choice_id: Variant = loaded_memory.get("choice_id")
		if typeof(choice_id) != TYPE_STRING or loaded_memory.size() != 6 or loaded_memory.get("event_id") != EVENT_ID or not CHOICE_TEXT.has(choice_id):
			return null
		# Keep the words the player actually saw, so later wording edits never invalidate older saves.
		var selected_text: Variant = loaded_memory.get("selected_text")
		if typeof(selected_text) != TYPE_STRING or (selected_text as String).is_empty() or (selected_text as String).length() > MAX_SELECTED_TEXT_LENGTH:
			return null
		if loaded_memory.get("context") != "breaker_relay_risk":
			return null
		if not _whole_in_range(loaded_memory.get("sequence"), 1, 1) or loaded_memory.get("observed_by") != ["human", "wolf"]:
			return null
	if puzzle["breaker_armed"] and loaded_memory.is_empty():
		return null
	if puzzle["door_open"] != (puzzle["route"] != ""):
		return null
	if puzzle["door_open"] and not puzzle["breaker_armed"]:
		return null
	if puzzle["route"] == "cooperate" and loaded_memory.get("choice_id") != DISCLOSE:
		return null
	if data["checkpoint_reached"] and not puzzle["door_open"]:
		return null
	if data["version"] >= 3:
		if not (data.get("chapter_id") in CHAPTER_IDS) or (data["chapter_id"] == "junction" and data["version"] < 4):
			return null
		if typeof(data.get("purge_trace_preserved")) != TYPE_BOOL or typeof(data.get("mirror_trace_preserved")) != TYPE_BOOL or typeof(data.get("chapter_complete")) != TYPE_BOOL:
			return null
		if typeof(data.get("mirror_route")) != TYPE_STRING:
			return null
		if data["chapter_id"] == "lockdown":
			if data["purge_trace_preserved"] or data["mirror_trace_preserved"] or data["mirror_route"] != "" or data["chapter_complete"]:
				return null
		elif not data["checkpoint_reached"]:
			return null
		if data["mirror_trace_preserved"]:
			if not data["purge_trace_preserved"] or (data["mirror_route"] != "wolf" and data["mirror_route"] != "manual"):
				return null
		elif data["mirror_route"] != "":
			return null
		if data["chapter_complete"] and not data["mirror_trace_preserved"]:
			return null
	if data["version"] >= 4:
		for field: String in ["door_blown", "sentry_down", "junction_cleared"]:
			if typeof(data.get(field)) != TYPE_BOOL:
				return null
		if data["chapter_id"] in ["junction", "investigation"]:
			# The junction opens only from a secured Records exit, and its beats land in order.
			if not data["chapter_complete"]:
				return null
			if data["sentry_down"] and not data["door_blown"]:
				return null
			if data["junction_cleared"] and not data["sentry_down"]:
				return null
			# Before the blast the sealed door walls off the right of the room; a save that puts
			# either actor past it would strand the engineer away from the breaker and valve.
			if not data["door_blown"]:
				if float(positions["human"][0]) + HUMAN_HALF_WIDTH > JUNCTION_DOOR_LEFT_X or float(positions["wolf"][0]) + WOLF_HALF_WIDTH > JUNCTION_DOOR_LEFT_X:
					return null
		elif data["door_blown"] or data["sentry_down"] or data["junction_cleared"]:
			return null
	if data.get("chapter_id") == "investigation" and (data["version"] < 5 or not data.get("junction_cleared", false)):
		return null
	var investigation: Variant = data.get("investigation_step", 0)
	if not _whole_in_range(investigation, 0, 4) or (data.get("chapter_id") != "investigation" and investigation != 0):
		return null
	if data["version"] >= 5 and not data.has("investigation_step"):
		return null
	# The lane recap is optional (older v4 saves lack it) and only describes a fallen sentry.
	var raw_lane_recap: Variant = data.get("lane_recap", "")
	if typeof(raw_lane_recap) != TYPE_STRING or not (raw_lane_recap in LANE_RECAPS):
		return null
	if raw_lane_recap != "" and not data.get("sentry_down", false):
		return null
	var state: M0State = M0State.new()
	state.name_index = int(identity["name_index"])
	state.active_actor = "human"
	var human_x: float = float(positions["wolf"][0]) if legacy_wolf_save else float(positions["human"][0])
	state.human_position = Vector2(human_x, float(positions["human"][1]))
	var wolf_x: float = clampf(human_x - M0Actor.FOLLOW_GAP, 40.0, 920.0) if legacy_wolf_save else float(positions["wolf"][0])
	state.wolf_position = Vector2(wolf_x, float(positions["wolf"][1]))
	state.memory = loaded_memory.duplicate(true)
	if not state.memory.is_empty():
		state.memory["sequence"] = int(state.memory["sequence"])
	state.breaker_armed = puzzle["breaker_armed"]
	state.door_open = puzzle["door_open"]
	state.route = str(puzzle["route"])
	state.checkpoint_reached = data["checkpoint_reached"]
	if data["version"] >= 3:
		state.chapter_id = data["chapter_id"]
		state.purge_trace_preserved = data["purge_trace_preserved"]
		state.mirror_trace_preserved = data["mirror_trace_preserved"]
		state.mirror_route = data["mirror_route"]
		state.chapter_complete = data["chapter_complete"]
	if data["version"] >= 4:
		state.door_blown = data["door_blown"]
		state.sentry_down = data["sentry_down"]
		state.junction_cleared = data["junction_cleared"]
	state.lane_recap = raw_lane_recap
	state.investigation_step = int(investigation)
	return state


## Writes this state as the checkpoint at [param path] (through AtomicFile, so a crash mid-write leaves
## the old checkpoint whole) and returns true when [param path] holds it. The file is to_dict() plus a
## GENERATION_KEY one higher than either copy already on disk, which is how load_from_disk tells the
## newer of the checkpoint and a leftover temporary copy apart. On false the new progress may sit in
## the temporary copy only; load_from_disk still finds it there.
func save_to_disk(path: String = SAVE_PATH) -> bool:
	var data: Dictionary = to_dict()
	data[GENERATION_KEY] = maxi(_generation_of(read_json(path)), _generation_of(read_json(AtomicFile.temp_path(path)))) + 1
	return AtomicFile.write_text(path, JSON.stringify(data))


## The checkpoint saved at [param path], or null when there is none worth loading. Of the checkpoint
## and its temporary copy (AtomicFile.temp_path) it returns the newer valid one by GENERATION_KEY, the
## checkpoint on a tie (so saves from before generations, both at 0, load as they always did). When
## the temporary copy wins it is moved over the checkpoint, so the next save cannot overwrite the only
## copy of that progress; a move that fails keeps the temporary copy for the next load.
static func load_from_disk(path: String = SAVE_PATH) -> M0State:
	var temp_path: String = AtomicFile.temp_path(path)
	var main_data: Variant = read_json(path)
	var temp_data: Variant = read_json(temp_path)
	var main_state: M0State = _checkpoint_from(main_data)
	var temp_state: M0State = _checkpoint_from(temp_data)
	if temp_state == null:
		return main_state
	if main_state != null and _generation_of(main_data) >= _generation_of(temp_data):
		return main_state
	AtomicFile.promote(temp_path, path)
	return temp_state


## The parsed JSON in the save file at [param path], or null when it is missing, larger than
## MAX_CHECKPOINT_BYTES, unopenable or not JSON. Reads only; the debug tools' SAVE page uses it too.
static func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	if file.get_length() > MAX_CHECKPOINT_BYTES:
		file.close()
		push_warning("Checkpoint file is too large; ignoring it: " + path)
		return null
	var body: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(body) != OK:
		return null
	return json.data


## The state in parsed save [param data] when it is valid and past the first checkpoint, else null.
static func _checkpoint_from(data: Variant) -> M0State:
	var loaded: M0State = from_dict(data)
	return loaded if loaded != null and loaded.checkpoint_reached else null


## The GENERATION_KEY of parsed save [param data]: 0 when it is missing or not a whole number of at
## least 0 (every save written before generations, or a hand-edited one).
static func _generation_of(data: Variant) -> int:
	if not (data is Dictionary):
		return 0
	var generation: Variant = (data as Dictionary).get(GENERATION_KEY)
	return int(generation) if _whole_in_range(generation, 0, MAX_GENERATION) else 0


## True when [param value] is a whole number (an int, or a float with no fraction, as JSON gives) from
## [param low] to [param high] inclusive.
static func _whole_in_range(value: Variant, low: int, high: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return value >= low and value <= high and int(value) == value


## True when [param value] is a saved [x, y] pair of numbers inside the slice's walkable box: x from 40
## to 920 (M0Actor.MIN_X..MAX_X) and y from 0 to [param floor_height] (world px).
static func _valid_position(value: Variant, floor_height: float) -> bool:
	if not (value is Array) or value.size() != 2:
		return false
	for component in value:
		if typeof(component) != TYPE_INT and typeof(component) != TYPE_FLOAT:
			return false
	return float(value[0]) >= 40.0 and float(value[0]) <= 920.0 and float(value[1]) >= 0.0 and float(value[1]) <= floor_height
