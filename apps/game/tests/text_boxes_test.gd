extends "res://tests/support/game_suite.gd"
## Text you can read (P0-8, P0-9, P0-10, P0-13; STORY-2, STORY-3, STORY-4, STORY-8, STORY-10,
## TEACH-7, PHONE-3, PHONE-7). Every line constant and every dialogue literal in main.gd, as each
## engineer name, splits into boxes with one speaker, at most two rows of at most 42 characters at
## 100% text size, under 20 words, read at 0.33 s a word or slower, and without a word changed. Then
## the boxes the game shows on the way through the opening, the corridor, Records Access and the
## Service Junction are measured on screen, and the first controllable frame, the Records exit, the
## touch layout, the TEXT SIZE setting and the prompts at every size are checked. Spawn, teardown and
## failure reporting come from the shared suite kit (tests/support/game_suite.gd).

const MAIN_SCRIPT: String = "res://scripts/main.gd"
const NAMES: Array[String] = ["Rowan", "Alex", "Morgan"]

var game: Main
var story: Label
var speaker: Label
var bar: Control
## Boxes measured on screen, and the most rows any took at 200%.
var shown_checked: int = 0
var rows_at_200: int = 0


func _initialize() -> void:
	call_deferred("_run")


## One game through every check, then the kit's teardown (no sound, node or file left behind) and
## exit status. Its settings file, [code]path[/code], is the one _check_text_size saves to and reads
## back in a second game.
func _run() -> void:
	check_name = "Text boxes"
	var path: String = "user://text-boxes-test-%s.cfg" % OS.get_process_id()
	game = await spawn_game("%s-save.json" % path, path, _keep_running) as Main
	story =game.get_node("CanvasLayer/BottomBar/Story") as Label
	speaker = game.get_node("CanvasLayer/BottomBar/Speaker") as Label
	bar = game.get_node("CanvasLayer/BottomBar") as Control
	_check_reading_rule()
	_check_splitting()
	_check_corpus()
	await _check_opening()
	await _check_first_control()
	await _check_corridor()
	await _check_records_exit()
	await _check_junction()
	await _check_story_kept()
	await _check_touch()
	await _check_text_size(path)
	print("text boxes: %d boxes measured on screen; the longest box takes %d rows at 200%%" % [shown_checked, rows_at_200])
	# The rooms' jumps leave clips playing; end_game stops them before freeing the game and removes
	# its save and settings files.
	await end_game(game)
	finish("")


## Passed to spawn_game for the games this suite drives itself: they keep running when the window
## has no focus (a headless run never has it), instead of pausing.
static func _keep_running(spawned: Node) -> void:
	spawned.set("auto_pause_on_focus_loss", false)


## STORY-2: 1.2 s plus 0.33 s a word, or plus 0.05 s a character (at most 7 s), whichever is longer.
func _check_reading_rule() -> void:
	_expect(is_equal_approx(DialogueBoxes.READ_SECONDS_PER_WORD, 0.33) and DialogueBoxes.READ_SECONDS_BASE > 0.0, "boxes are timed at 0.33 s a word plus a base")
	_expect(absf(DialogueBoxes.read_seconds("Go.") - (1.2 + 0.33)) < 0.001 and DialogueBoxes.read_seconds("one two three four five six seven eight nine ten") >= 10 * 0.33 and absf(DialogueBoxes.read_seconds("abcdefghij abcdefghij abcdefghij") - (1.2 + 0.05 * 32)) < 0.001, "a box is up 1.2 s plus 0.33 s a word or 0.05 s a character, whichever is longer (%.2f s for \"Go.\")" % DialogueBoxes.read_seconds("Go."))
	_expect(not (load(MAIN_SCRIPT) as Script).get_script_constant_map().has("READ_SECONDS_PER_WORD"), "main.gd keeps no faster reading rate of its own")


## The splitter on lines with known shapes: speakers inline, untagged continuation, quotes, choices.
func _check_splitting() -> void:
	var tags: Array[String] = ["WOLF", "DIRECTOR", "DIRECTOR / PURGE", "ROWAN"]
	var wide: Callable = func(_words: String) -> bool: return true
	_expect(DialogueBoxes.split("FIRST COPY SECURED. WOLF: An order. I want the source.\nROWAN: Then Archive is next.", tags, wide) == ["FIRST COPY SECURED.", "WOLF: An order. I want the source.", "ROWAN: Then Archive is next."], "a speaker named inside a line starts their own box")
	_expect(DialogueBoxes.split("WOLF: You said \"Go now. We can talk after.\"\nI refused.", tags, wide) == ["WOLF: You said \"Go now. We can talk after.\"\nI refused."], "an untagged line after WOLF's goes on in his box, and a quotation stays whole")
	_expect(DialogueBoxes.split("WOLF: Which one?\n1  \"Yes.\"\n2  \"No.\"", tags, wide) == ["WOLF: Which one?"], "a choice's response rows stay out of the box")
	_expect(DialogueBoxes.split("DIRECTOR / PURGE: Logs marked.\nWOLF: Gone.", tags, wide) == ["DIRECTOR / PURGE: Logs marked.", "WOLF: Gone."], "the purge display's tag is matched whole")
	var twenty: String = "One two three four five. Six seven eight nine ten. Eleven twelve thirteen fourteen fifteen. Sixteen seventeen eighteen nineteen twenty."
	var long_boxes: Array[String] = DialogueBoxes.split(twenty, tags, wide)
	_expect(long_boxes.size() == 2 and " ".join(long_boxes) == twenty, "a line of 20 words splits at a sentence break even when it would fit (%s)" % [long_boxes])


## Every line constant and dialogue literal, as each engineer name, at 100%.
func _check_corpus() -> void:
	var font: Font = story.get_theme_font(&"font")
	var size: int = story.get_theme_font_size(&"font_size")
	var width: float = game.call("_dialogue_column_width")
	_expect(size >= 23, "dialogue is %d px at 540p (at least 23)" % size)
	# A row that would pass 42 characters breaks one word earlier, never sooner; rows of the approved
	# two-row boxes keep their written breaks.
	var stiff: String = "The wheel is stiff. Three full turns charge the door."
	var stiff_rows: Array[String] = DialogueBoxes.row_texts(stiff, font, size, DialogueBoxes.wrap_width(stiff, font, size, width, DialogueBoxes.MAX_ROW_CHARACTERS))
	_expect(stiff_rows == ["The wheel is stiff. Three full turns", "charge the door."], "a long row breaks one word earlier, not more (%s)" % [stiff_rows])
	var lost: String = Main.SENTRY_LOST_LINE % "Morgan"
	var lost_rows: Array[String] = DialogueBoxes.row_texts(lost, font, size, DialogueBoxes.wrap_width(lost, font, size, width, DialogueBoxes.MAX_ROW_CHARACTERS))
	var written: Array[String] = []
	written.assign(lost.split("\n"))
	_expect(lost_rows == written, "an approved two-row box keeps its rows (%s)" % [lost_rows])
	var messages: Array[String] = _corpus()
	_expect(messages.size() >= 90, "the corpus holds the game's lines (%d)" % messages.size())
	var boxes: int = 0
	for first: String in NAMES:
		var tags: Array[String] = ["WOLF", "DIRECTOR", "DIRECTOR / PURGE", first.to_upper()]
		var fits: Callable = func(words: String) -> bool: return DialogueBoxes.rows(words, font, size, DialogueBoxes.wrap_width(words, font, size, width, DialogueBoxes.MAX_ROW_CHARACTERS)).size() <= DialogueBoxes.MAX_ROWS
		for template: String in messages:
			var message: String = template.replace("{NAME}", first.to_upper()).replace("{name}", first)
			var split: Array[String] = DialogueBoxes.split(message, tags, fits)
			_expect(_words(message.get_slice(DialogueBoxes.CHOICE_MARKER, 0), tags) == _words("\n".join(split), tags), "splitting changes no word: %s" % message.c_escape())
			for box: String in split:
				boxes += 1
				_check_box(box, tags, font, size, width, message)
	_expect(boxes > messages.size() * 3, "every line was measured as boxes (%d)" % boxes)


func _check_box(box: String, tags: Array[String], font: Font, size: int, width: float, source: String) -> void:
	var words: String = DialogueBoxes.words_of(box, tags)
	var rows: Array[String] = DialogueBoxes.row_texts(words, font, size, DialogueBoxes.wrap_width(words, font, size, width, DialogueBoxes.MAX_ROW_CHARACTERS))
	var longest: int = _longest_row(rows)
	_expect(not _names_inline(words, tags), "one speaker per box: %s" % box.c_escape())
	_expect(rows.size() <= DialogueBoxes.MAX_ROWS and longest <= DialogueBoxes.MAX_ROW_CHARACTERS, "a box takes at most 2 rows of at most 42 characters (%d rows, %d characters): %s (from %s)" % [rows.size(), longest, box.c_escape(), source.c_escape()])
	_expect(DialogueBoxes.word_count(words) < DialogueBoxes.LONG_LINE_WORDS, "a box holds fewer than 20 words: %s" % box.c_escape())
	_expect(DialogueBoxes.read_seconds(words) >= DialogueBoxes.word_count(words) * 0.33, "a box is up 0.33 s a word or longer: %s" % box.c_escape())


## The length in characters of the longest of [param rows] (0 for none). Used by _check_box and
## _measure_shown against DialogueBoxes.MAX_ROW_CHARACTERS.
static func _longest_row(rows: Array[String]) -> int:
	var longest: int = 0
	for row: String in rows:
		longest = maxi(longest, row.length())
	return longest


## Whether [param text] names a speaker inside it ("TAG: " for any of [param tags]), which would put
## two speakers in one box. Used by _check_box and _measure_shown.
static func _names_inline(text: String, tags: Array[String]) -> bool:
	for tag: String in tags:
		if text.contains(tag + ": "):
			return true
	return false


## The words of [param text] with the speaker tags taken out, in order.
static func _words(text: String, tags: Array[String]) -> PackedStringArray:
	var plain: String = text.replace("\n", " ")
	for tag: String in DialogueBoxes._longest_first(tags):
		plain = plain.replace(tag + ": ", " ")
	return plain.split(" ", false)


## Every line constant in Main (the trust line's boxes, the refusals and the opening exchange too) and
## JunctionRoom's knockdown cards, and every string literal main.gd says through status_line, _tell,
## _say, _say_next or _aside, with "%s" as the engineer's name ({NAME} where it is a tag) and
## "%d" as a number. WOLF's remembered line at the safe point is filled in with each of its three.
func _corpus() -> Array[String]:
	var out: Array[String] = []
	var constants: Dictionary = (load(MAIN_SCRIPT) as Script).get_script_constant_map()
	for name: String in constants:
		if name.ends_with("_LINE") or name.ends_with("_LINES") or name.ends_with("_QUESTION") or name.ends_with("_WARNING") or name.contains("_LINE_") or name.begins_with("REFUSE_") or name == "OPENING_EXCHANGE":
			var value: Variant = constants[name]
			if value is String:
				out.append(_fill(value))
			elif value is Array:
				for line: Variant in value:
					out.append(_fill(str(line)))
	var junction: Dictionary = (load("res://scripts/junction_room.gd") as Script).get_script_constant_map()
	for name: String in junction:
		if name.ends_with("_REASON"):
			out.append(_fill(str(junction[name])))
	var literal: RegEx = RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")
	var remembered: Array[String] = []
	var source: String = FileAccess.get_file_as_string(MAIN_SCRIPT)
	for line: String in source.split("\n"):
		if line.contains("var remembered_line: String ="):
			for found: RegExMatch in literal.search_all(line):
				if found.get_string(1).contains(" "):
					remembered.append(found.get_string(1).c_unescape())
	for line: String in source.split("\n"):
		var said_at: int = -1
		for call: String in ["status_line = ", "_tell(", "_say_next(", "_say([", "_aside("]:
			if line.contains(call):
				said_at = line.find(call)
		if said_at < 0:
			continue
		for found: RegExMatch in literal.search_all(line.substr(said_at)):
			var text: String = found.get_string(1).c_unescape()
			if not text.contains(" "):
				continue
			if text.begins_with("WOLF: %s\n"):
				for said: String in remembered:
					out.append(text.replace("%s", said))
			else:
				out.append(_fill(text))
	# The safe point's callbacks, on each relay route.
	for route: Array in [[M0State.PRESS, "human"], [M0State.DISCLOSE, "wolf"], [M0State.DISCLOSE, "human"]]:
		var state: M0State = M0State.new()
		state.record_choice(route[0])
		state.arm_breaker()
		state.activate_power(route[1])
		state.reach_checkpoint()
		out.append("Safe point saved. " + state.checkpoint_callback())
	return out


static func _fill(text: String) -> String:
	return text.replace("%s:", "{NAME}:").replace("%s", "{name}").replace("%d", "8")


## Measures the box on screen now, at the current text size.
func _measure_shown(context: String) -> void:
	if not bar.visible or story.text.is_empty():
		return
	shown_checked += 1
	var font: Font = story.get_theme_font(&"font")
	var size: int = story.get_theme_font_size(&"font_size")
	var rows: Array[String] = DialogueBoxes.row_texts(story.text, font, size, story.size.x)
	var longest: int = _longest_row(rows)
	var tags: Array[String] = game.call("_speaker_tags")
	var inline: bool = _names_inline(story.text, tags)
	_expect(story.get_line_count() == rows.size(), "the shown box wraps as measured (%s)" % context)
	if is_equal_approx(TextSize.factor, 1.0):
		_expect(rows.size() <= 2 and longest <= 42, "%s: the shown box takes %d rows, the longest %d characters: %s" % [context, rows.size(), longest, story.text.c_escape()])
	else:
		rows_at_200 = maxi(rows_at_200, rows.size())
	_expect(not inline and (speaker.text.is_empty() or speaker.text in tags), "%s: one speaker, named in the speaker column" % context)
	var box: Rect2 = bar.get_global_rect()
	_expect(box.position.x >= 0.0 and box.end.x <= 960.0 and box.position.y >= 0.0 and box.end.y <= 540.0, "%s: the dialogue box stays on the canvas (%s)" % [context, box])
	_expect(story.position.y + story.size.y <= bar.size.y + 0.5 and story.get_line_count() * story.get_line_height() <= story.size.y + 0.5, "%s: the words fit inside the box" % context)


## Runs the game for [param seconds] of game time in 1/60 s steps, measuring every box shown.
func _play(seconds: float, context: String) -> void:
	var last: String = ""
	for _step: int in roundi(seconds * 60.0):
		game.call("_process", 1.0 / 60.0)
		if story.text != last:
			last = story.text
			_measure_shown(context)
	await process_frame


## P0-13 and the opening, box by box: one box per press, the beat's next box first.
func _check_opening() -> void:
	game.new_game_button.pressed.emit()
	await process_frame
	var hint: Label = game.get_node("CanvasLayer/ContextHint/Text") as Label
	_expect(hint.text.contains(Main.SKIP_OPENING_HINT) and (game.get_node("CanvasLayer/ContextHint") as Control).visible, "the opening's first box says PAUSE skips the opening (%s)" % hint.text.c_escape())
	_measure_shown("opening")
	var pressed: int = 0
	while game.intro_active and game.intro_step < Main.INTRO_LINES.size() and pressed < 40:
		var step: int = game.intro_step
		var index: int = game.dialogue_index
		# Pressed inline, press first: the suites' _tap helpers wait a frame before pressing, and that
		# leading frame would let the box read here change before the press lands.
		Input.action_press(&"interact")
		await process_frame
		Input.action_release(&"interact")
		await process_frame
		pressed += 1
		if game.intro_active and game.intro_step < Main.INTRO_LINES.size():
			_expect(game.intro_step == step and game.dialogue_index == index + 1 or game.intro_step == step + 1 and game.dialogue_index == 0, "a press in the opening shows the next box (beat %d box %d -> beat %d box %d)" % [step, index, game.intro_step, game.dialogue_index])
			_expect(not hint.text.contains(Main.SKIP_OPENING_HINT), "only the first box carries the skip hint")
			_measure_shown("opening")
	_expect(pressed > Main.INTRO_LINES.size(), "the opening's multi-speaker beats take a box per speaker (%d presses for %d beats)" % [pressed, Main.INTRO_LINES.size()])
	await create_timer(1.0).timeout
	_expect(not game.intro_active, "the last press fades into play")


## P0-8 (TEACH-7): the first controllable frame shows one text element and one prompt, then the
## tutorial after the first step, then the lines.
func _check_first_control() -> void:
	game.debug_new_game(true)
	await process_frame
	game.call("_refresh_ui")
	var hint_panel: Control = game.get_node("CanvasLayer/ContextHint") as Control
	var tutorial: Control = game.get_node("CanvasLayer/TutorialPrompt") as Control
	var tutorial_text: Label = tutorial.get_node("Text") as Label
	_expect(game.human.controlled and game.top_card.visible and game.hud.text.contains("MAINTENANCE ENGINEER"), "control starts with the name card")
	_expect(tutorial.visible and tutorial_text.get_line_count() == 1 and tutorial_text.text.ends_with("MOVE"), "and one prompt: move (%s)" % tutorial_text.text.c_escape())
	_expect(not bar.visible and not hint_panel.visible, "and no dialogue box or hint bar on the first controllable frame")
	await _play(2.0, "first control, standing")
	_expect(not bar.visible, "the lines wait for the first step")
	Input.action_press(&"move_right")
	await _play(0.1, "first step")
	Input.action_release(&"move_right")
	_expect(tutorial_text.text.contains("READ DISPLAY (optional)") and not bar.visible, "the first step brings the rest of the tutorial, not the lines yet")
	# The name card fades (a tween, in real time) while its last moments run out. Waited out by its
	# state, not a fixed time, so a loaded machine cannot leave it still fading at the check.
	await _play(Main.TOP_CARD_FADE_SECONDS, "after the first step")
	var fade_started: int = Time.get_ticks_msec()
	while game.top_card.visible and Time.get_ticks_msec() - fade_started < 10000:
		await process_frame
	await _play(0.1, "after the name card")
	_expect(not game.top_card.visible and bar.visible and story.text.begins_with("%s keeps WOLF's systems running." % game.call("_first_name")), "once the name card has gone the lines start, one box at a time (%s)" % story.text.c_escape())
	_expect(not hint_panel.visible, "the hint bar stays off while the tutorial prompt is the prompt")
	# Only the test's own steps move the game's clock here, so a slow frame between them on a loaded
	# machine cannot run the box out early.
	game.set_process(false)
	var first_box_seconds: float = DialogueBoxes.read_seconds(story.text) - game.dialogue_age
	var first_box: String = story.text
	await _play(first_box_seconds - 0.1, "trust line")
	_expect(story.text == first_box, "a box stays up for its reading time")
	await _play(0.2, "trust line")
	_expect(story.text != first_box and speaker.text.is_empty(), "then the next box takes its place (%s)" % story.text.c_escape())
	game.set_process(true)
	var narration_width: float = bar.size.x
	_expect(absf(story.position.x - Main.DIALOGUE_PADDING.x) <= 0.5 and absf(narration_width - (Main.DIALOGUE_PADDING.x * 2.0 + story.size.x)) <= 0.5, "a narration box is only as wide as its words' column, with no empty name column (%s)" % bar.size)
	await _play(14.0, "opening lines")
	_expect(speaker.text in ["WOLF", (game.call("_first_name") as String).to_upper()] or game.status_line == Main.STAKES_LINE, "WOLF and the engineer each get their own boxes")
	if not speaker.text.is_empty():
		_expect(bar.size.x > narration_width, "a speaker's box adds the name column (%s vs %s)" % [bar.size.x, narration_width])


## The stakes and the relay question at the breaker; a box per speaker as WOLF answers.
func _check_corridor() -> void:
	game.debug_tools.actions.set_relay(&"press")
	game.debug_tools.actions.jump(&"relay_question")
	await process_frame
	_expect(game.waiting_for_choice and speaker.text == "WOLF" and story.text.contains("COOLANT FAULT"), "the relay question stands in WOLF's box")
	_measure_shown("relay question")
	await _play(8.0, "relay question")
	_expect(bar.visible and story.text.contains("COOLANT FAULT"), "a question stays up until it is answered")
	game.call("_answer_choice", 2)
	await _play(6.0, "WOLF refuses")
	# Standing still, the read line stays; walking on clears it (STORY-8).
	_expect(bar.visible, "a read line stays while the engineer stands")
	Input.action_press(&"move_right")
	await _play(0.2, "walking on")
	Input.action_release(&"move_right")
	_expect(not bar.visible, "a read line clears once the engineer moves on")
	var hint_panel: Control = game.get_node("CanvasLayer/ContextHint") as Control
	var hint_rect: Rect2 = hint_panel.get_global_rect()
	_expect(hint_panel.visible and absf(hint_rect.end.y - Main.DIALOGUE_BOTTOM) <= 0.5, "with no box up the hint bar takes the box's place at the bottom (%s)" % hint_rect)
	game.call("_interact")
	await _play(0.1, "said again")
	_expect(bar.visible or game.status_line.is_empty(), "the next line shows again")


## Records' exit: securing the first copy keeps control; its closing lines run while the engineer
## walks, USE there goes through them, and they clear once read and walked away from.
func _check_records_exit() -> void:
	await _to_records_mirror()
	_place_at_records_exit()
	game.call("_interact")
	await _play(0.6, "records exit")
	_expect(not game.chapter_close_active and game.human.controlled, "securing the first copy holds no closing shot: the engineer keeps control")
	_expect(game.state.chapter_complete and story.text == "FIRST COPY SECURED.", "the closing lines start with their first box (%s)" % story.text.c_escape())
	var hint: Label = game.get_node("CanvasLayer/ContextHint/Text") as Label
	await _play(2.0, "records exit")
	_expect(speaker.text == "WOLF" and hint.text.ends_with("continue."), "WOLF's box follows, and USE at the exit offers to continue (%s)" % hint.text)
	game.call("_interact")
	await _play(0.05, "records exit")
	_expect(game.state.chapter_id == "records" and speaker.text == (game.call("_first_name") as String).to_upper(), "USE at the exit shows the next box rather than leaving")
	var seconds: float = DialogueBoxes.read_seconds(story.text)
	Input.action_press(&"move_left")
	await _play(seconds + 0.1, "records exit, walking")
	Input.action_release(&"move_left")
	_expect(not bar.visible, "walking on after the last box has been read clears it (no hold at the exit)")
	_place_at_records_exit()
	game.call("_interact")
	await process_frame
	_expect(game.state.chapter_id == "junction", "with the lines read, USE at the exit goes on to the junction")


## Records Access with the purge trace and the mirror done (WOLF's relay disclosure, WOLF's readout),
## one process frame after the debug jump, so only the exit is left.
func _to_records_mirror() -> void:
	var acts: DebugActions = game.debug_tools.actions
	acts.set_relay(&"disclose_wolf")
	acts.set_mirror(&"wolf")
	acts.jump(&"records_mirror")
	await process_frame


## The engineer at Records' exit station (Main.RECORDS_STATIONS[2]), on the side they walk up to it
## from, with WOLF the follow gap behind; standing still, controls updated (Main.debug_place).
func _place_at_records_exit() -> void:
	var exit_side: float = game.debug_station_side_x(Main.RECORDS_STATIONS[2], 829.0)
	game.debug_place(exit_side, exit_side - M0Actor.FOLLOW_GAP)


## The junction's entry lines and the knockdown cards split into boxes as they show.
func _check_junction() -> void:
	await _play(12.0, "junction entry")
	for kind: StringName in [&"vent", &"blast", &"sentry", &"cloud"]:
		game.debug_tools.actions.set_relay(&"press")
		game.debug_tools.actions.jump(&"lane")
		await process_frame
		game.debug_knock_down(kind)
		await _play(6.0, "knockdown card %s" % kind)


## A station's answer cutting into a story line said through the queue never drops it: Records'
## closing lines (the engineer keeps control while they play) come back after the route hint at the
## box they were on, and USE at the exit brings them back first; WOLF's stakes line comes back after
## the purge display.
func _check_story_kept() -> void:
	await _to_records_mirror()
	var close: String = Main.RECORDS_CLOSE_LINE % (game.call("_first_name") as String).to_upper()
	_place_at_records_exit()
	game.call("_interact")
	await _play(2.6, "records close kept")
	_expect(game.status_line == close and speaker.text == "WOLF", "WOLF's box of the closing lines is up (%s)" % story.text.c_escape())
	# Just outside the exit's reach (772 to 888) USE answers with the route hint.
	game.debug_place(740.0, 740.0 - M0Actor.FOLLOW_GAP)
	game.call("_interact")
	await process_frame
	_expect(game.status_line == game.call("_records_route_hint") and game.box_queue == [close], "the route hint cuts in and the closing lines wait behind it (%s, %s)" % [game.status_line.c_escape(), str(game.box_queue).c_escape()])
	await _play(Main.box_seconds(game.status_line) + 0.2, "records close kept")
	_expect(game.status_line == close and speaker.text == "WOLF", "the closing lines come back at WOLF's box, not their first (%s)" % story.text.c_escape())
	# Cut in again, then USE at the exit: the lines come back first, and the engineer's box follows.
	game.call("_interact")
	_place_at_records_exit()
	game.call("_refresh_ui")
	var hint: Label = game.get_node("CanvasLayer/ContextHint/Text") as Label
	_expect(hint.text.ends_with("continue."), "with the closing lines held back, USE at the exit offers to continue (%s)" % hint.text)
	game.call("_interact")
	await process_frame
	_expect(game.state.chapter_id == "records" and game.status_line == close and speaker.text == "WOLF", "USE at the exit brings the held-back lines back rather than leaving (%s)" % story.text.c_escape())
	game.call("_interact")
	await process_frame
	_expect(game.state.chapter_id == "records" and speaker.text == (game.call("_first_name") as String).to_upper() and story.text.ends_with("Then Archive is next."), "the engineer's closing box follows (%s)" % story.text.c_escape())
	# WOLF's stakes line, read over at the purge display.
	game.debug_new_game(true)
	await process_frame
	game.set("opening_lines_held", false)
	game.call("_drop_box_queue")
	game.debug_place(200.0, 120.0)
	game.call("_speak_stakes")
	await _play(0.5, "stakes kept")
	game.call("_interact")
	await process_frame
	_expect(str(game.status_line).begins_with("DIRECTOR / PURGE") and game.box_queue == [Main.STAKES_LINE], "the purge display cuts in and WOLF's stakes line waits behind it")
	# The display's text shows as two boxes; the stakes follow once both have been up their time.
	var display_seconds: float = 0.0
	for box: String in game.dialogue_boxes:
		display_seconds += DialogueBoxes.read_seconds(DialogueBoxes.words_of(box, game.call("_speaker_tags")))
	await _play(display_seconds + 0.2, "stakes kept")
	_expect(game.status_line == Main.STAKES_LINE, "the stakes line comes back after the display's text (%.1f s)" % display_seconds)
	# Held back again, USE at the breaker brings it back before WOLF asks about the relay.
	game.call("_interact")
	game.debug_place(350.0, 270.0)
	game.call("_interact")
	await process_frame
	_expect(game.status_line == Main.STAKES_LINE and not game.waiting_for_choice, "USE at the breaker brings the held-back stakes line back before the relay question")


## P0-10: on touch the answers sit at the bottom without numbers, the hint names the button on screen
## and stays clear of USE.
func _check_touch() -> void:
	game.touch_enabled = true
	game.controller_active = false
	game.debug_tools.actions.set_relay(&"disclose_wolf")
	game.debug_tools.actions.jump(&"relay_question")
	await process_frame
	game.call("_refresh_ui")
	var choice_1: Button = game.get_node("CanvasLayer/TouchControls/Choice1") as Button
	var choice_2: Button = game.get_node("CanvasLayer/TouchControls/Choice2") as Button
	_expect(choice_1.visible and not choice_1.text.begins_with("1") and not choice_2.text.begins_with("2") and choice_1.text == M0State.CHOICE_TEXT[M0State.DISCLOSE], "touch answers carry no number (%s / %s)" % [choice_1.text, choice_2.text])
	_expect(choice_1.position.y > 300.0 and choice_2.position.y > 300.0 and choice_1.get_global_rect().end.y <= bar.get_global_rect().position.y and choice_1.position.x < 100.0 and choice_2.get_global_rect().end.x > 860.0, "touch answers sit at the bottom corners, just above the question (%s, %s)" % [choice_1.get_global_rect(), choice_2.get_global_rect()])
	_expect(not choice_1.get_global_rect().intersects(choice_2.get_global_rect()), "the two answers do not overlap")
	game.call("_answer_choice", 1)
	# At the valve the hint names CRANK, the button on screen, and stays clear of USE.
	game.debug_tools.actions.jump(&"junction_a")
	await process_frame
	game.debug_place(JunctionRoom.BREAKER_X + 30.0, JunctionRoom.WOLF_CLEAR_X)
	game.call("_interact")
	game.debug_place(Main.VALVE_CRANK_X, JunctionRoom.WOLF_CLEAR_X)
	game.call("_refresh_ui")
	var hint_panel: Control = game.get_node("CanvasLayer/ContextHint") as Control
	var hint: Label = hint_panel.get_node("Text") as Label
	var use: Button = game.get_node("CanvasLayer/TouchControls/Use") as Button
	_expect(use.text == "CRANK" and hint.text.begins_with("HOLD CRANK:"), "on touch the crank hint names the CRANK button (%s)" % hint.text)
	for button: Button in [use, game.get_node("CanvasLayer/TouchControls/Left") as Button, game.get_node("CanvasLayer/TouchControls/Right") as Button]:
		_expect(not hint_panel.get_global_rect().intersects(button.get_global_rect()), "the hint bar stays clear of %s (%s vs %s)" % [button.text, hint_panel.get_global_rect(), button.get_global_rect()])
	_expect(not hint_panel.get_global_rect().intersects(bar.get_global_rect()), "the hint bar sits above the dialogue box")
	# The touch tutorial names its button in the same "button  action" form as the keys.
	game.debug_new_game(true)
	await process_frame
	Input.action_press(&"move_right")
	game.call("_process", 1.0 / 60.0)
	Input.action_release(&"move_right")
	var tutorial_text: Label = game.get_node("CanvasLayer/TutorialPrompt/Text") as Label
	_expect(tutorial_text.text.begins_with("USE  READ DISPLAY (optional)"), "the touch tutorial reads USE  READ DISPLAY (optional) (%s)" % tutorial_text.text.c_escape())
	game.touch_enabled = false


## The TEXT SIZE setting: 100% to 200%, saved, and every HUD text and station name scaled.
func _check_text_size(path: String) -> void:
	var settings: GameSettings = game.settings_menu
	_expect(settings.text_size != null and settings.text_size.item_count == 5 and settings.text_size.get_item_text(0) == "100%" and settings.text_size.get_item_text(4) == "200%", "Settings offers TEXT SIZE from 100% to 200%")
	var breaker_label: Label = game.get_node("BreakerLabel") as Label
	var base_label_bottom: float = breaker_label.position.y + breaker_label.size.y
	settings.text_size.select(4)
	settings.text_size.item_selected.emit(4)
	_expect(is_equal_approx(TextSize.factor, 2.0) and GameSettings.load_config(path).get_value("video", "text_size", 0.0) == 2.0, "choosing 200% applies and saves it")
	_expect(story.get_theme_font_size(&"font_size") == 46 and (game.get_node("CanvasLayer/ContextHint/Text") as Label).get_theme_font_size(&"font_size") == 28 and game.hud.get_theme_font_size(&"font_size") == 30 and (game.get_node("CanvasLayer/TutorialPrompt/Text") as Label).get_theme_font_size(&"font_size") == 34, "dialogue, hint, card and tutorial double")
	_expect(breaker_label.get_theme_font_size(&"font_size") == roundi(13 * TextSize.WORLD_MAX_FACTOR) and absf(breaker_label.position.y + breaker_label.size.y - base_label_bottom) <= 2.0, "station names grow to their cap (TextSize.WORLD_MAX_FACTOR) at 200%% and grow upward from where they stood (%d px)" % breaker_label.get_theme_font_size(&"font_size"))
	var junction_label: Label = game.junction_room.station_labels[0]
	_expect(junction_label.get_theme_font_size(&"font_size") == roundi(JunctionRoom.LABEL_FONT_SIZE * TextSize.WORLD_MAX_FACTOR) and game.records_room.station_labels[0].get_theme_font_size(&"font_size") == roundi(13 * TextSize.WORLD_MAX_FACTOR) and game.bypass_handle.fault_tag.get_theme_font_size(&"font_size") == roundi(BypassHandle.LABEL_FONT_SIZE * TextSize.WORLD_MAX_FACTOR), "the junction's, Records' and the bypass's plates grow too")
	# Boxes at 200% stay on the canvas, one speaker each; their rows are counted.
	game.debug_new_game(true)
	await process_frame
	Input.action_press(&"move_right")
	await _play(1.0, "200% opening lines")
	Input.action_release(&"move_right")
	await _play(20.0, "200% opening lines")
	game.debug_tools.actions.jump(&"records_mirror")
	await process_frame
	_place_at_records_exit()
	game.call("_interact")
	await _play(12.0, "200% records exit")
	_expect(rows_at_200 >= 1 and rows_at_200 <= 3, "at 200%% a box takes at most 3 rows (%d)" % rows_at_200)
	for path_name: String in ["CanvasLayer/TopBar", "CanvasLayer/ContextHint", "CanvasLayer/TutorialPrompt", "CanvasLayer/BottomBar"]:
		var rect: Rect2 = (game.get_node(path_name) as Control).get_global_rect()
		_expect(rect.position.x >= 0.0 and rect.end.x <= 960.0 and rect.position.y >= 0.0 and rect.end.y <= 540.0, "%s stays on the canvas at 200%% (%s)" % [path_name, rect])
	var card: Rect2 = game.top_card.get_global_rect()
	_expect(not card.intersects((game.get_node("CanvasLayer/PauseButton") as Control).get_global_rect()), "the top card stays clear of PAUSE at 200%")
	# The answers keep the HUD's side margin (keys, under the top card), and on touch the top card
	# stays clear of the DEBUG button where it shows, its words still fitting.
	game.debug_tools.actions.set_relay(&"disclose_wolf")
	game.debug_tools.actions.jump(&"relay_question")
	await process_frame
	game.call("_refresh_ui")
	for button_path: String in ["CanvasLayer/TouchControls/Choice1", "CanvasLayer/TouchControls/Choice2"]:
		var answer: Rect2 = (game.get_node(button_path) as Control).get_global_rect()
		_expect(answer.position.x >= Main.HUD_SIDE_MARGIN - 0.5 and answer.end.x <= 960.0 - Main.HUD_SIDE_MARGIN + 0.5, "at 200%% the answer keeps the side margin (%s)" % answer)
	game.call("_answer_choice", 1)
	game.touch_enabled = true
	game.controller_active = false
	game.debug_tools.call("_refresh_view")
	game.call("_refresh_ui")
	await process_frame
	var debug_button: Control = game.debug_tools.debug_button
	if debug_button.visible:
		_expect(not game.top_card.get_global_rect().intersects(debug_button.get_global_rect()), "at 200%% on touch the top card stays clear of DEBUG (%s vs %s)" % [game.top_card.get_global_rect(), debug_button.get_global_rect()])
		_expect(game.hud.get_line_count() * game.hud.get_line_height() <= game.hud.size.y + 1.0, "the narrower top card still fits its words (%d rows)" % game.hud.get_line_count())
	else:
		print("text boxes: the DEBUG button is not shown in this build; its check is skipped")
	game.touch_enabled = false
	game.debug_tools.call("_refresh_view")
	# A fresh game reads the saved size back; a broken value falls back to the nearest step.
	# Not end_game for this one: it would remove the settings file the first game still saves to.
	var again: Main = await spawn_game("%s-again.json" % path, path) as Main
	_expect(is_equal_approx(TextSize.factor, 2.0) and again.settings_menu.text_size.selected == 4, "a new session opens at the saved 200%")
	again.queue_free()
	await process_frame
	await _check_station_names()
	await _check_prompts_clear(path)
	settings.text_size.select(0)
	settings.text_size.item_selected.emit(0)
	_expect(is_equal_approx(TextSize.factor, 1.0) and story.get_theme_font_size(&"font_size") == 23 and breaker_label.get_theme_font_size(&"font_size") == 13, "back at 100% everything returns to its size")
	_expect(is_equal_approx(TextSize.nearest_step(1.3), 1.25) and is_equal_approx(TextSize.nearest_step(9.0), 2.0) and is_equal_approx(TextSize.nearest_step(-1.0), 1.0), "a hand-edited size snaps to the nearest step")


## At every text size the station names in each room, in each state, stay apart: a name breaks
## between its words above 100% (TextSize.WORLD_ROW_GROWTH) instead of running into its neighbours,
## stands where it stood at 100% (its bottom edge), and the corridor's are not faded out at the start
## (the MANUAL BYPASS plate, at the view's edge there, once the engineer walks towards it).
func _check_station_names() -> void:
	var settings: GameSettings = game.settings_menu
	var bottoms: Dictionary = {}
	for index: int in TextSize.STEPS.size():
		settings.text_size.select(index)
		settings.text_size.item_selected.emit(index)
		var percent: int = roundi(TextSize.STEPS[index] * 100.0)
		for jump: StringName in [&"corridor_start", &"records_mirror", &"junction_a", &"lane", &"tank_down"]:
			game.debug_tools.actions.jump(jump)
			for frame: int in 3:
				await process_frame
			var labels: Array[Label] = []
			var candidates: Array = [game.get_node("BreakerLabel"), game.get_node("RelayLabel"), game.get_node("CheckpointLabel"), game.bypass_handle.fault_tag, game.bypass_handle.bypass_label]
			candidates.append_array(game.records_room.station_labels)
			candidates.append_array(game.junction_room.station_labels)
			for label: Label in candidates:
				if label.is_visible_in_tree() and not label.text.is_empty():
					labels.append(label)
			for a: int in labels.size():
				var rect: Rect2 = labels[a].get_global_rect()
				var key: String = "%s|%s|%s" % [jump, labels[a].get_path(), labels[a].text]
				if index == 0:
					bottoms[key] = rect.end.y
				elif bottoms.has(key) and labels[a] != game.get_node("RelayLabel"):
					_expect(absf(rect.end.y - float(bottoms[key])) <= 1.5, "%d%%, %s: %s keeps its bottom edge where it was at 100%% (%.1f vs %.1f)" % [percent, jump, labels[a].text, rect.end.y, bottoms[key]])
				for b: int in range(a + 1, labels.size()):
					var other: Rect2 = labels[b].get_global_rect()
					_expect(not rect.grow(-0.5).intersects(other.grow(-0.5)), "%d%%, %s: %s and %s do not overlap (%s, %s)" % [percent, jump, labels[a].text, labels[b].text, rect, other])
			if jump == &"corridor_start":
				for label: Label in [game.get_node("BreakerLabel"), game.get_node("RelayLabel"), game.bypass_handle.fault_tag] as Array[Label]:
					_expect(label.modulate.a > 0.99, "%d%%: %s is not faded at the corridor's start (alpha %.2f)" % [percent, label.text, label.modulate.a])
				# The MANUAL BYPASS plate (the engineer-only fallback) stands at the view's right edge at the
				# start: a little faded at 100%, faded out at larger sizes (it grows to the right, clear of the
				# relay's names). Standing beside the relay, where WOLF points to the bypass when he refuses,
				# the engineer sees it in full.
				if index == 0:
					_expect(game.bypass_handle.bypass_label.modulate.a > 0.5, "100%%: MANUAL BYPASS shows at the corridor's start (alpha %.2f)" % game.bypass_handle.bypass_label.modulate.a)
				# The camera eases after the engineer in time, not frames: once it has its new target it is
				# snapped there, so the check does not depend on how fast the frames run.
				game.debug_place(Main.RELAY_SIDE_X, Main.RELAY_SIDE_X - 120.0)
				await process_frame
				game.intro_camera.reset_smoothing()
				for frame: int in 3:
					await process_frame
				_expect(game.bypass_handle.bypass_label.modulate.a > 0.99, "%d%%: MANUAL BYPASS shows in full with the engineer beside the relay (alpha %.2f)" % [percent, game.bypass_handle.bypass_label.modulate.a])
				var relay_name: Rect2 = (game.get_node("RelayLabel") as Label).get_global_rect()
				_expect(relay_name.end.y <= game.bypass_handle.fault_tag.get_global_rect().position.y + 0.5, "%d%%: COOLANT RELAY stands above its COOLANT FAULT tag" % percent)
		await _check_touch_layout(percent)
		# The valve's plate changes its words as it is worked ("VALVE  0 / 3" keeps a double space):
		# each stands on the same line and clears the LINE caption by the dial.
		game.debug_tools.actions.jump(&"junction_a")
		await process_frame
		var room: JunctionRoom = game.junction_room
		var plate_bottom: float = JunctionRoom.LABEL_Y + room.valve_label.get_theme_font(&"font").get_height(JunctionRoom.LABEL_FONT_SIZE) + room.valve_label.get_theme_stylebox(&"normal").get_minimum_size().y
		for text: String in ["VALVE", "VALVE  0 / 3", "FUSE LIT", "VALVE SPENT"]:
			room.valve_label.text = text
			room.refit_labels()
			await process_frame
			await process_frame
			var plate: Rect2 = Rect2(room.valve_label.position, room.valve_label.size)
			_expect(absf(plate.end.y - plate_bottom) <= 1.5, "%d%%: the %s plate stands on its line (bottom %.1f, expected %.1f)" % [percent, text.c_escape(), plate.end.y, plate_bottom])
			_expect(not plate.intersects(Rect2(room.line_caption.position, room.line_caption.size)), "%d%%: the %s plate clears the LINE caption" % [percent, text.c_escape()])


## At every text size, keys and touch, in a fresh game: the opening's hint bar stands below the top
## card, not on it, and after the first step the tutorial prompt (moved off the station names where
## it would cover the breaker's, see Main._tutorial_prompt_place) is checked on the step's own frame,
## before any box, and again once the opening lines' first box is up, so a slow machine cannot change
## what is checked.
func _check_prompts_clear(path: String) -> void:
	for touch: bool in [false, true]:
		for index: int in TextSize.STEPS.size():
			var fresh: Main = await spawn_game("%s-prompts.json" % path, "%s-prompts.cfg" % path, _keep_running) as Main
			fresh.touch_enabled = touch
			fresh.settings_menu.text_size.select(index)
			fresh.settings_menu.text_size.item_selected.emit(index)
			var context: String = "%d%%, %s" % [roundi(TextSize.STEPS[index] * 100.0), "touch" if touch else "keys"]
			fresh.new_game_button.pressed.emit()
			for frame: int in 40:
				await process_frame
			var hint_panel: Control = fresh.get_node("CanvasLayer/ContextHint") as Control
			_expect(fresh.intro_active and fresh.top_card.visible and hint_panel.visible and not hint_panel.get_global_rect().intersects(fresh.top_card.get_global_rect()), "%s: the opening's hint bar stands below the top card (%s vs %s)" % [context, hint_panel.get_global_rect(), fresh.top_card.get_global_rect()])
			fresh.debug_new_game(true)
			fresh.touch_enabled = touch
			for frame: int in 5:
				await process_frame
			# The frame of the first step: the name card starts its fade, so no box is up yet.
			Input.action_press(&"move_right")
			await process_frame
			_expect(not fresh.bottom_bar.visible, "%s: no box is up on the frame of the first step" % context)
			_check_prompt_clear(fresh, touch, false, context)
			for frame: int in 5:
				await process_frame
			Input.action_release(&"move_right")
			for frame: int in 600:
				if fresh.bottom_bar.visible:
					break
				await process_frame
			_check_prompt_clear(fresh, touch, true, context)
			_expect(fresh.bottom_bar.visible, "%s: the opening lines' first box comes up while the tutorial prompt shows" % context)
			# A quick free, not end_game: its settle time on each of the 10 games adds up, and the files
			# are shared by every fresh game here, so they are removed once after the loop.
			stop_audio(fresh)
			fresh.queue_free()
			await process_frame
	for file: String in ["%s-prompts.cfg" % path, "%s-prompts.json" % path]:
		remove_file(file)


## The tutorial prompt in [param fresh] after the first step, with or without a box up ([param box_up]):
## on the canvas, over no station name, neither actor, the box, a top card that shows (one leaving
## goes at once when the prompt takes its place), PAUSE, DEBUG or the touch buttons, and
## over at most Main.TUTORIAL_ART_OVERLAP of its area of the machines. Where it waits hidden behind a
## box, the hint bar is empty too.
func _check_prompt_clear(fresh: Main, touch: bool, box_up: bool, context: String) -> void:
	context += ", box up" if box_up else ", no box yet"
	if not fresh.tutorial_prompt.visible:
		_expect(box_up and fresh.tutorial_prompt_slot == &"waiting" and not (fresh.get_node("CanvasLayer/ContextHint") as Control).visible, "%s: the tutorial prompt is hidden only while it waits behind a box, with the hint bar empty (%s)" % [context, fresh.tutorial_prompt_slot])
		return
	var prompt: Rect2 = fresh.tutorial_prompt.get_global_rect()
	# A long frame under load can carry the engineer past the display, where the prompt only points on.
	_expect(fresh.tutorial_text.text.contains("right to the breaker.") and prompt.position.y >= 0.0 and prompt.end.y <= Main.DIALOGUE_BOTTOM and prompt.position.x >= 0.0 and prompt.end.x <= 960.0, "%s: after the first step the tutorial prompt shows on the canvas (%s)" % [context, prompt])
	for label: Label in [fresh.get_node("BreakerLabel"), fresh.get_node("RelayLabel"), fresh.get_node("CheckpointLabel"), fresh.bypass_handle.fault_tag, fresh.bypass_handle.bypass_label] as Array[Label]:
		if label.is_visible_in_tree() and label.modulate.a > 0.05:
			var name_rect: Rect2 = label.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, label.size)
			_expect(not prompt.intersects(name_rect), "%s: the tutorial prompt leaves %s readable (%s vs %s)" % [context, label.text.replace("\n", " "), prompt, name_rect])
	for sprite: Sprite2D in [fresh.human.body_sprite, fresh.wolf.body_sprite] as Array[Sprite2D]:
		_expect(not prompt.intersects(sprite.get_global_transform_with_canvas() * sprite.get_rect()), "%s: the tutorial prompt leaves %s uncovered" % [context, sprite.get_parent().name])
	# Summed here from the sprites, not through Main._station_art_overlap: the test's own measure is
	# the independent check of the game's placement rule.
	var art_overlap: float = 0.0
	for sprite: Sprite2D in [fresh.breaker_art, fresh.purge_terminal_art, fresh.relay_art] as Array[Sprite2D]:
		art_overlap += prompt.intersection(sprite.get_global_transform_with_canvas() * sprite.get_rect()).get_area()
	_expect(art_overlap <= prompt.get_area() * Main.TUTORIAL_ART_OVERLAP, "%s: the tutorial prompt lies over at most a tenth of its area of the machines (%.0f of %.0f)" % [context, art_overlap, prompt.get_area()])
	var others: Array[Control] = [fresh.pause_button]
	if fresh.top_card.visible:
		others.append(fresh.top_card)
	if box_up:
		others.append(fresh.bottom_bar)
	if fresh.debug_tools.debug_button.visible:
		others.append(fresh.debug_tools.debug_button)
	if touch:
		others.append_array([fresh.touch_left, fresh.touch_right, fresh.touch_use])
	for other: Control in others:
		_expect(not prompt.intersects(other.get_global_rect()), "%s: the tutorial prompt stays clear of %s (%s vs %s)" % [context, other.name, prompt, other.get_global_rect()])


## On touch at [param percent]: a box, with a name or without, stays clear of ◀ ▶ and USE, and the
## corridor's names and the COOLANT FAULT tag stay clear of PAUSE.
func _check_touch_layout(percent: int) -> void:
	game.debug_tools.actions.jump(&"corridor_start")
	game.touch_enabled = true
	game.controller_active = false
	for line: String in [Main.STAKES_LINE, Main.JUNCTION_CLEARED_LINE]:
		game.status_line = line
		await process_frame
		await process_frame
		var box: Rect2 = bar.get_global_rect()
		_expect(bar.visible, "%d%%, touch: the box shows (%s)" % [percent, line])
		for button: Control in [game.touch_left, game.touch_right, game.touch_use]:
			_expect(not box.intersects(button.get_global_rect()), "%d%%, touch: the box stays clear of %s (%s vs %s)" % [percent, (button as Button).text, box, button.get_global_rect()])
		var hint_panel: Control = game.get_node("CanvasLayer/ContextHint") as Control
		if hint_panel.visible:
			_expect(not hint_panel.get_global_rect().intersects(box), "%d%%, touch: the hint bar stays clear of the box" % percent)
	var pause: Rect2 = game.pause_button.get_global_rect()
	for label: Label in [game.get_node("RelayLabel"), game.bypass_handle.fault_tag] as Array[Label]:
		var on_screen: Rect2 = label.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, label.size)
		_expect(not on_screen.intersects(pause), "%d%%, touch: %s stays clear of PAUSE (%s vs %s)" % [percent, label.text, on_screen, pause])
	game.touch_enabled = false
	await process_frame

