extends "res://tests/support/text_boxes_suite.gd"
## Text you can read in every language (localization PRs L7d and L8): the game's corpus, in every
## language of I18n.LANGUAGES at every TEXT SIZE step, keeps each language's box rules, and the
## overlap checks of the English suite (touch layout, top card, station names, prompts) hold in every
## other offered language and under pseudolocalization. Split from tests/text_boxes_test.gd so each
## suite stays well under check-game.sh's time limit; the checks live in the text-box kit
## (tests/support/text_boxes_suite.gd).


## One game, already in play (debug_new_game, as the English suite's checks leave it before these),
## through both checks, then the kit's teardown and exit status.
func _run() -> void:
	check_name = "Text boxes in every language"
	var path: String = await open_text_game("text-boxes-languages-test")
	game.debug_new_game(true)
	await process_frame
	_check_every_language()
	await _check_overlaps_every_language(path)
	await close_text_game()
