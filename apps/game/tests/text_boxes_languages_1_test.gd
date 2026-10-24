extends "res://tests/support/text_boxes_suite.gd"
## Text you can read in every language (localization PRs L7d and L8), shard 1 of the text-box kit's
## LANGUAGE_SHARDS: for its share of the languages, the game's corpus at every TEXT SIZE step keeps each
## language's box rules, and the overlap checks of the English suite (touch layout, top card, station
## names, prompts) hold, pseudolocalization included. Split from tests/text_boxes_test.gd so each suite
## stays well under check-game.sh's time limit; the checks live in tests/support/text_boxes_suite.gd.


## The whole suite: shard 1's languages (run_language_shard), then the kit's teardown and exit status.
func _run() -> void:
	await run_language_shard(1)
