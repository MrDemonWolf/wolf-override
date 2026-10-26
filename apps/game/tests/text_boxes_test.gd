extends "res://tests/support/text_boxes_suite.gd"
## Text you can read (P0-8, P0-9, P0-10, P0-13; STORY-2, STORY-3, STORY-4, STORY-8, STORY-10,
## TEACH-7, PHONE-3, PHONE-7), in English. Every line constant and every dialogue literal in main.gd,
## as each engineer name, splits into boxes with one speaker, at most two rows of at most 42
## characters at 100% text size, under 20 words, read at 0.33 s a word or slower, and without a word
## changed; each language's box rules hold on known cases, and Chinese, Japanese and Korean samples
## split without a character changed into balanced boxes (localization PR L7d). Then the boxes the
## game shows on the way through the opening, the corridor, Records Access and the Service Junction
## are measured on screen, and the first controllable frame, the Records exit, the touch layout, the
## TEXT SIZE setting and the prompts at every size are checked. The same corpus and overlap checks in
## every other language run in tests/text_boxes_languages_1_test.gd and _2_test.gd. The checks live
## in the text-box kit (tests/support/text_boxes_suite.gd); spawn, teardown and failure reporting come
## from the suite kit (tests/support/game_suite.gd).


## One game through every English check, then the kit's teardown (no sound, node or file left behind)
## and exit status. Its settings file, [code]path[/code], is the one _check_text_size saves to and
## reads back in a second game.
func _run() -> void:
	check_name = "Text boxes"
	var path: String = await open_text_game("text-boxes-test")
	_check_reading_rule()
	_check_splitting()
	_check_language_rules()
	_check_corpus()
	_check_cjk_samples()
	await _check_opening()
	await _check_first_control()
	await _check_corridor()
	await _check_records_exit()
	await _check_junction()
	await _check_story_kept()
	await _check_touch()
	await _check_text_size(path)
	print("text boxes: %d boxes measured on screen; the longest box takes %d rows at 200%%" % [shown_checked, rows_at_200])
	await close_text_game()
