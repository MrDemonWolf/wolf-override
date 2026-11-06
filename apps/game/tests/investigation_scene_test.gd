extends "res://tests/support/game_suite.gd"
## Annex scene regressions from a completed-junction fixture: engineer-only access, ordered sources,
## player-paced reveal, pause, save/resume and explicit chapter completion. Full slice owns end-to-end.

var game: Main


## Uses real movement/USE after entering from the junction fixture; never opens a graphical window.
func _run() -> void:
	check_name = "Investigation scene"
	game = await start_game("investigation-scene", keep_running) as Main
	var legacy: M0State = completed_records_state(M0State.PRESS)
	legacy.enter_junction()
	legacy.blow_door()
	legacy.drop_sentry()
	legacy.clear_junction()
	legacy.human_position.x = JunctionRoom.HATCH_REACH_MIN_X + M0State.HUMAN_HALF_WIDTH
	legacy.wolf_position.x = JunctionRoom.WOLF_DOWN_X
	var old_save: Dictionary = legacy.to_dict()
	old_save["version"] = 4
	old_save.erase("investigation_step")
	_expect(write_text(game.save_path, JSON.stringify(old_save)), "literal v4 completed-junction fixture is saved")
	game._refresh_continue()
	_expect(game.continue_button.text == "CONTINUE", "old completed slice now offers Continue, not Play Again")
	game.continue_button.pressed.emit()
	await frames(3)
	_expect(game.state.chapter_id == "junction" and game.human.controlled, "real Continue loads legacy junction progress")
	await tap(&"interact", 1)
	await frames(3)
	_expect(game.state.chapter_id == "investigation" and game.records_room.visible and not game.junction_room.visible, "junction hands control to the reused annex room")
	_expect(game.human.controlled and not game.wolf.controlled and game.records_room.investigation, "engineer retains control and annex labels are distinct")
	await _read_all()
	game.wolf.hide()
	_expect(await walk_to_reading_on(game.human, RecordsRoom.MIRROR_X), "engineer can reach controller without WOLF")
	await tap(&"interact", 1)
	_expect(game.state.investigation_step == 0, "controller cannot skip surviving fragment")
	await _read_all()
	for step: int in [1, 2, 3]:
		var station: float = [RecordsRoom.PURGE_X, RecordsRoom.MIRROR_X, RecordsRoom.CONTAINER_X][step - 1]
		_expect(await walk_to_reading_on(game.human, station), "engineer reaches source %s alone" % step)
		await tap(&"interact", 1)
		_expect(game.state.investigation_step == step, "source %s advances exactly one ordered beat" % step)
		var before: String = game.status_line
		await frames(120)
		_expect(game.status_line == before, "source %s does not advance on a timer" % step)
		await _read_all()
		await tap(&"interact", 1)
		_expect(game.state.investigation_step == step, "re-reading source %s never duplicates progress" % step)
		await _read_all()
	_expect(game.state.investigation_step == 3 and not game.end_card_active, "identity reveal is saved separately from explicit chapter completion")
	game._load_game()
	await frames(3)
	_expect(game.state.investigation_step == 3 and not game.box_queue.is_empty() and game.status_line.contains("investigator"), "Continue restores and replays the final reveal")
	await tap(&"pause_game", 1)
	_expect(game.get_tree().paused, "pause remains available during the final reveal")
	await tap(&"pause_game", 1)
	_expect(not game.get_tree().paused, "pause returns to the final reveal")
	# A fast reader can advance each box explicitly, including the final one, without a forced timer.
	for _press: int in 32:
		if game.box_queue.is_empty() and game.dialogue_index == game.dialogue_boxes.size() - 1:
			break
		await tap(&"interact", 1)
	_expect(game.box_queue.is_empty() and game.dialogue_age < game._box_seconds(), "final box is reached before its reading timer finishes")
	await tap(&"interact", 1)
	_expect(game.dialogue_cleared and game.state.investigation_step == 3 and not game.end_card_active, "one USE acknowledges the final box immediately without also completing the chapter")
	_expect(await walk_to_reading_on(game.human, RecordsRoom.EXIT_DOOR_X), "engineer reaches annex exit")
	await tap(&"interact", 1)
	_expect(game.state.investigation_step == 4 and game.end_card_active, "explicit exit completes Chapter 1 after the reveal")
	var saved: M0State = M0State.load_from_disk(game.save_path)
	_expect(saved != null and saved.investigation_step == 4, "chapter completion is persisted")
	game._load_game()
	await frames(3)
	_expect(game.state.investigation_step == 4 and game.end_card_active and not game.human.controlled, "direct Load of a completed chapter restores its card instead of stranding the engineer")
	await end_game(game)
	finish("Investigation scene checks passed")


## Advances only with USE until queued boxes and their reading time finish, with the shared bound.
func _read_all() -> void:
	_expect(await continue_until(game, func() -> bool: return game.box_queue.is_empty() and game._dialogue_read(), TALK_FRAMES), "all annex lines can be read with USE")
