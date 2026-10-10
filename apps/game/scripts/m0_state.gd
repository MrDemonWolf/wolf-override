class_name M0State
extends RefCounted

const SAVE_VERSION: int = 4
const SAVE_PATH: String = "user://m0-save.json"
const CHAPTER_IDS: Array[String] = ["lockdown", "records", "junction"]
const EVENT_ID: String = "relay_disagreement"
const DISCLOSE: String = "disclose_risk"
const PRESS: String = "press_without_warning"
const HUMAN_NAMES = ["Rowan Vale", "Alex Bennett", "Morgan Reed"]
const MAX_SELECTED_TEXT_LENGTH: int = 200
## Half the width of each actor's body (28 px engineer, 62 px WOLF), as main.tscn shapes them.
const HUMAN_HALF_WIDTH: float = 14.0
const WOLF_HALF_WIDTH: float = 31.0
## The Service Junction's sealed door face; until the door is blown nobody can stand past it.
const JUNCTION_DOOR_LEFT_X: float = 452.0
const CHOICE_TEXT = {
	"disclose_risk": "The relay may vent coolant. Your call.",
	"press_without_warning": "Go now. We can talk after.",
}

var active_actor: String = "human"
var name_index: int = 0
var human_position: Vector2 = Vector2(160.0, 410.0)
var wolf_position: Vector2 = Vector2(96.0, 423.0)
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


func human_name() -> String:
	return HUMAN_NAMES[name_index]


func cycle_name() -> void:
	name_index = (name_index + 1) % HUMAN_NAMES.size()


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


func arm_breaker() -> bool:
	if memory.is_empty() or breaker_armed:
		return false
	breaker_armed = true
	return true


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


func reach_checkpoint() -> bool:
	if not door_open or checkpoint_reached:
		return false
	checkpoint_reached = true
	return true


func enter_records() -> bool:
	if not checkpoint_reached or chapter_id != "lockdown":
		return false
	chapter_id = "records"
	human_position = Vector2(128.0, 410.0)
	wolf_position = Vector2(64.0, 423.0)
	return true


func preserve_purge_trace() -> bool:
	if chapter_id != "records" or purge_trace_preserved:
		return false
	purge_trace_preserved = true
	return true


func preserve_mirror_trace(selected_route: String) -> bool:
	if chapter_id != "records" or not purge_trace_preserved or mirror_trace_preserved or (selected_route != "wolf" and selected_route != "manual"):
		return false
	mirror_trace_preserved = true
	mirror_route = selected_route
	return true


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
	human_position = Vector2(120.0, 410.0)
	wolf_position = Vector2(64.0, 423.0)
	return true


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


func checkpoint_callback() -> String:
	if not checkpoint_reached or memory.is_empty():
		return ""
	var said: String = str(memory.get("selected_text", ""))
	if memory.get("choice_id") == PRESS:
		return "WOLF: You said \"%s\"\nI refused. You found another way." % said
	if route == "cooperate":
		return "WOLF: You said \"%s\"\nI chose the relay. We made it." % said
	return "WOLF: You said \"%s\"\nYou took the bypass. I stayed with you." % said


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
	}


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
		if data["chapter_id"] == "junction":
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
	var state: M0State = M0State.new()
	state.name_index = int(identity["name_index"])
	state.active_actor = "human"
	var human_x: float = float(positions["wolf"][0]) if legacy_wolf_save else float(positions["human"][0])
	state.human_position = Vector2(human_x, float(positions["human"][1]))
	var wolf_x: float = clampf(human_x - 64.0, 40.0, 920.0) if legacy_wolf_save else float(positions["wolf"][0])
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
	return state


func save_to_disk(path: String = SAVE_PATH) -> bool:
	var temp_path: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	var stored: bool = file.store_string(JSON.stringify(to_dict()))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if not stored or write_error != OK:
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temp_path), ProjectSettings.globalize_path(path)) == OK


static func load_from_disk(path: String = SAVE_PATH) -> M0State:
	var loaded: M0State = _read_checkpoint(path)
	if loaded != null:
		return loaded
	# Only used when the main checkpoint is missing or unreadable, e.g. the first save or a rename that removed the old file first.
	var temp_path: String = path + ".tmp"
	var recovered: M0State = _read_checkpoint(temp_path)
	if recovered != null:
		var global_temp: String = ProjectSettings.globalize_path(temp_path)
		var global_path: String = ProjectSettings.globalize_path(path)
		# Promote the recovered copy; fall back to copying so the only readable checkpoint never
		# stays at .tmp, where the next save would overwrite it.
		if DirAccess.rename_absolute(global_temp, global_path) != OK and not DirAccess.dir_exists_absolute(global_path):
			DirAccess.copy_absolute(global_temp, global_path)
	return recovered


static func _read_checkpoint(path: String) -> M0State:
	if not FileAccess.file_exists(path):
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var body: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	if json.parse(body) != OK:
		return null
	var loaded: M0State = from_dict(json.data)
	return loaded if loaded != null and loaded.checkpoint_reached else null


static func _whole_in_range(value: Variant, low: int, high: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return value >= low and value <= high and int(value) == value


static func _valid_position(value: Variant, floor_height: float) -> bool:
	if not (value is Array) or value.size() != 2:
		return false
	for component in value:
		if typeof(component) != TYPE_INT and typeof(component) != TYPE_FLOAT:
			return false
	return float(value[0]) >= 40.0 and float(value[0]) <= 920.0 and float(value[1]) >= 0.0 and float(value[1]) <= floor_height
