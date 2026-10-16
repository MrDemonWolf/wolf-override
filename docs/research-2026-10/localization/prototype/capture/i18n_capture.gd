extends SceneTree
## Render-container capture driver for the i18n prototype (scratch only, 2026-10-16). Copied into the
## project copy as res://review_capture/ by tools/render/render.sh --driver; never part of the game.
## Not moved into the build: it re-implements part of scripts/parity/capture.gd (routes, waits, size,
## touch layout, saving), so PR L2 adds --language and this file's audit to that driver instead and this
## copy stays on the research branch as the record of how the prototype's stills were made (PLAN.md, L2).
## Its earlier-capture path below is git history: 1cf8d73:docs/research-2026-10/how-it-should-play/...
##
## One run plays the game once at one window size (user argument --size=WxH, default 1280x720; run
## render.sh with the same --screen) and, for each language in LANGUAGES, saves four frames to
## /work/out/<size>/<language>-<frame>.png: the title, the first corridor hint (with the location card
## up), the opening's first narration box, and the vent knockdown card in the Service Junction; plus,
## at 1280x720, the Settings DISPLAY tab with the LANGUAGE row. "pseudo" is
## English with Godot's pseudolocalization on (brackets and 30% padding; accents and doubled vowels
## off, since they would break the "E:" key token and the {name} inserts).
## For every saved frame it audits the visible Labels and Buttons (the text as drawn, auto-translate
## applied) and writes /work/out/audit.json: text that overflows its control, characters the control's
## font chain cannot draw (tofu), and in the pseudo frames, text that did not go through translation.
## Contract: run as `--script res://review_capture/i18n_capture.gd -- --size=WxH [--languages=a,b]`
## with render.sh --screen WxH. --languages limits the run to those entries of LANGUAGES (the design
## step's Russian runs used --languages=ru, so the earlier languages were not rendered again). Quits with
## 0, or 1 if a step could not be reached or a language is not in LANGUAGES.
## A size wider than 2:1 (2400x1080) is a phone: the run turns the game's touch layout on, as the
## earlier phone captures did (docs/research-2026-10/how-it-should-play/playthrough/CAPTURE-ROUND1.md).
## Gotchas: the game's own launch sizing runs first, so the size is set on the root window after it
## and given frames to settle; without the borderless flag a 2400x1080 window came out 1920x1080 on a
## 2400x1080 and on a 2560x1440 screen (measured, runs i18n-proto-1 and -3; the doors landing driver
## sets the same flag), so it is set first. The title fades its logo in over about
## a second. Text the title screen covers (the play HUD behind it) is not audited.

const LANGUAGES: Array[String] = ["en", "es", "de", "ja", "ru", "pseudo"]
const WAIT_FRAMES: int = 45
const OUT: String = "/work/out"

var game: Main
var audit: Dictionary = {}
var failed: bool = false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate() as Main
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	var size: Vector2i = Vector2i(1280, 720)
	var languages: Array[String] = LANGUAGES.duplicate()
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--size="):
			var parts: PackedStringArray = argument.trim_prefix("--size=").split("x")
			size = Vector2i(int(parts[0]), int(parts[1]))
		elif argument.begins_with("--languages="):
			languages.assign(argument.trim_prefix("--languages=").split(",", false))
	for language: String in languages:
		if not LANGUAGES.has(language):
			push_error("unknown language %s (LANGUAGES: %s)" % [language, LANGUAGES])
			quit(1)
			return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	game.touch_enabled = size.x > size.y * 2
	await _wait(60)
	root.size = size
	await _wait(30)
	DirAccess.make_dir_recursive_absolute("%s/%dx%d" % [OUT, size.x, size.y])
	for language: String in languages:
		_set_language(language)
		await _title(size, language)
		if size == Vector2i(1280, 720):
			await _settings(size, language)
		await _narration(size, language)
		await _hint(size, language)
		await _knockdown(size, language)
		game._return_to_title()
		await _wait(10)
	_set_language("en")
	var file: FileAccess = FileAccess.open(OUT + "/audit.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(audit, " ", false))
	file.close()
	print("i18n capture: %d frames" % audit.size())
	quit(1 if failed else 0)


## English with pseudolocalization for "pseudo", else the language with it off.
func _set_language(language: String) -> void:
	var pseudo: bool = language == "pseudo"
	if pseudo:
		for setting: String in ["replace_with_accents", "double_vowels"]:
			ProjectSettings.set_setting("internationalization/pseudolocalization/" + setting, false)
		ProjectSettings.set_setting("internationalization/pseudolocalization/expansion_ratio", 0.3)
		TranslationServer.reload_pseudolocalization()
	TranslationServer.pseudolocalization_enabled = pseudo
	I18n.apply("en" if pseudo else language)


func _title(size: Vector2i, language: String) -> void:
	await _wait(WAIT_FRAMES * 2)
	_save(size, language, "title")


func _settings(size: Vector2i, language: String) -> void:
	game._show_title_settings()
	await _wait(WAIT_FRAMES)
	_save(size, language, "settings")
	game._return_to_title()
	await _wait(10)


## The opening's second box: the narration "The Director thinks WOLF is still in standby."
func _narration(size: Vector2i, language: String) -> void:
	game.debug_new_game(false)
	await _wait(20)
	game._advance_intro()
	await _wait(WAIT_FRAMES)
	_save(size, language, "narration")


## The first corridor hint by the purge display, with the location card up (the name card skipped).
func _hint(size: Vector2i, language: String) -> void:
	game.debug_new_game(true)
	game.tutorial_step = 2
	game.name_card_remaining = 0.0
	# The location card waits while the opening lines play; with them dropped it comes up at once.
	game.opening_lines.clear()
	game.debug_place(100.0, 60.0)
	await _wait(WAIT_FRAMES)
	_save(size, language, "hint")


## The vent knockdown card at Service Junction save A, once it takes RETRY.
func _knockdown(size: Vector2i, language: String) -> void:
	var note: String = game.debug_tools.actions.jump(&"junction_a")
	await _wait(30)
	var why: String = game.debug_tools.actions.force_knockdown(&"vent")
	if not why.begins_with("Forced"):
		push_error("knockdown not forced (%s / %s)" % [note, why])
		failed = true
	await _wait(WAIT_FRAMES * 2)
	_save(size, language, "knockdown")


func _wait(count: int) -> void:
	for _frame: int in count:
		await process_frame


func _save(size: Vector2i, language: String, frame: String) -> void:
	var image: Image = root.get_texture().get_image()
	var name: String = "%dx%d/%s-%s" % [size.x, size.y, language, frame]
	image.save_png("%s/%s.png" % [OUT, name])
	audit[name] = _audit(language == "pseudo")
	audit[name]["image"] = "%dx%d" % [image.get_width(), image.get_height()]


## The visible Labels and Buttons of the frame: overflow, tofu and (pseudo) untranslated text.
func _audit(pseudo: bool) -> Dictionary:
	var overflow: Array[String] = []
	var tofu: Array[String] = []
	var untranslated: Array[String] = []
	var texts: int = 0
	for node: Node in root.find_children("*", "Control", true, false):
		var control: Control = node as Control
		if not control.is_visible_in_tree() or not (control is Label or control is Button):
			continue
		if game.title_open and not game.title_screen.is_ancestor_of(control) and not game.pause_overlay.is_ancestor_of(control):
			continue
		var raw: String = str(control.get("text"))
		if raw.strip_edges().is_empty():
			continue
		texts += 1
		var shown: String = control.atr(raw)
		var where: String = "%s \"%s\"" % [control.get_path().get_concatenated_names().get_slice("Main/", 1), shown.c_escape()]
		var missing: String = I18n.missing_glyphs(shown, control.get_theme_font(&"font"))
		if not missing.is_empty():
			tofu.append("%s missing %s" % [where, missing])
		if I18n.overflows(control):
			overflow.append("%s needs %.0f px, has %.0f" % [where, control.get_minimum_size().x, control.size.x])
		# A pseudolocalized line split into boxes shows "[" on its first box and "]" on its last.
		if pseudo and not shown.contains("[") and not shown.contains("]") and _is_words(shown):
			untranslated.append(where)
	return {"texts": texts, "overflow": overflow, "tofu": tofu, "untranslated_in_pseudo": untranslated}


## Text with at least two letters (not a lone symbol such as ◀, a number or a key name).
static func _is_words(text: String) -> bool:
	var letters: int = 0
	for character: String in text:
		if character.to_upper() != character.to_lower():
			letters += 1
	return letters >= 2
