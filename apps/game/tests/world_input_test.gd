extends "res://tests/support/game_suite.gd"
## Pointer cancellation must stop its own crank without changing scripted actor navigation.


func _run() -> void:
	check_name = "World input"
	_check_canvas_geometry()
	var game: Main = await start_game("world-input", keep_running) as Main
	game.call("_new_game")
	game.call("_finish_intro")
	var pointer: WorldInput = game.world_input
	pointer.active = {"id": 0, "target": null, "point": Vector2.ZERO, "cancelled": false, "fired": true, "hold": &"bypass"}
	pointer.set("_queued_use", true)
	game.crank_latched = true
	var release: InputEventScreenTouch = InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.canceled = true
	pointer.observe(release)
	_expect(not game.crank_latched and not pointer.get("_queued_use"), "OS-canceled touch drops both toggle hold and queued press")
	_expect(pointer.active.is_empty() and pointer.released["cancelled"], "canceled release cannot activate on release")
	pointer.active = {"id": WorldInput.MOUSE_ID, "target": null, "point": Vector2.ZERO, "cancelled": false, "fired": true, "hold": &"bypass"}
	var mouse: InputEventMouseButton = InputEventMouseButton.new()
	mouse.device = InputEvent.DEVICE_ID_EMULATION
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = false
	pointer.observe(mouse)
	_expect(not pointer.active.is_empty(), "emulated mouse release cannot end a native gesture")
	game.crank_latched = true
	pointer.cancel()
	_expect(not game.crank_latched and pointer.active.is_empty(), "canceling pointer intent stops its own latched hold")
	game.crank_latched = true
	pointer.cancel()
	_expect(game.crank_latched, "canceling an idle pointer preserves another input's latch")
	game.crank_latched = false
	# Build a live manual route with the same state methods used by the choice and breaker.
	game.state.record_choice(M0State.PRESS)
	game.state.arm_breaker()
	game.human.position.x = Main.BYPASS_CRANK_X
	game.call("_update_controls")
	await frames(3)
	var station: Tappable = pointer.prompt_target()
	_expect(station != null and station.id == &"bypass" and station.prompt_rect().has_area(), "the prompt resolves the dispatcher's live bypass with a drawn anchor")
	var wheel: Sprite2D = game.bypass_handle.wheel
	var down: InputEventMouseButton = InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = wheel.get_global_transform_with_canvas() * wheel.get_rect().get_center()
	down.pressed = true
	_expect(pointer.handle_unhandled(down) and pointer.holding(&"bypass"), "pressing the live wheel owns a held crank")
	var ticked: bool = await wait_until(func() -> bool: return game.hold_use.ticks >= 1, 40)
	_expect(ticked, "holding the wheel advances the real held-USE timer")
	var kept: int = game.hold_use.ticks
	var up: InputEventMouseButton = down.duplicate() as InputEventMouseButton
	up.pressed = false
	pointer.observe(up)
	pointer.handle_unhandled(up)
	await frames(3)
	_expect(not game.hold_use.holding and game.hold_use.ticks == kept, "release stops the crank and preserves completed ticks")
	await _check_walk_prompt(game)
	await end_game(game)
	finish("World input checks passed")


## Hovering a station out of reach shows "Walk here" on it with no key glyph; the click queues the
## existing pointer walk, and the pill returns to the station's own action once the engineer is in reach.
func _check_walk_prompt(game: Main) -> void:
	var pointer: WorldInput = game.world_input
	game.tutorial_step = 2
	game.name_card_remaining = 0.0
	game.call("_drop_box_queue")
	game.status_line = ""
	# The purge display always offers Read display, whatever the route so far; start out of its reach.
	game.debug_place(Main.PURGE_DISPLAY_X + 160.0, 580.0)
	game.call("_update_gameplay_camera")
	game.intro_camera.reset_smoothing()
	await frames(3)
	var display: Tappable
	for target: Tappable in pointer.targets:
		if target.id == &"purge_display":
			display = target
	var art: Sprite2D = display.regions[0] as Sprite2D
	var hover: InputEventMouseMotion = InputEventMouseMotion.new()
	hover.position = art.get_global_transform_with_canvas() * art.get_rect().get_center()
	game.input_mode.pointer_focus = true
	pointer.handle_unhandled(hover)
	game.call("_refresh_ui")
	_expect(game.screen_shape.safe_rect.has_point(hover.position) and game.interaction_target_at(game.human.position.x) != &"purge_display", "the hovered display is on screen and out of reach")
	_expect(pointer.walk_target() == display and game.station_prompt_walk and game.station_prompt_target == display and game.context_hint.visible and game.context_hint_text.text == "Walk here" and not game.context_hint_glyph.visible and not game.context_hint_hold.visible, "hovering a station out of reach shows Walk here without a key glyph (%s)" % game.context_hint_text.text)
	_expect(game.screen_shape.safe_rect.encloses(game.context_hint.get_global_rect()), "the Walk here pill stays inside the safe area")
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = game.context_hint.get_global_rect().get_center()
	_expect(pointer.call("_hit", click.position, false) != null and (pointer.call("_hit", click.position, false) as Tappable).kind != Tappable.Kind.USE or pointer.call("_hit", click.position, false) == null, "the Walk here pill is a caption, never a USE button")
	click.position = hover.position
	click.pressed = true
	pointer.handle_unhandled(click)
	click = click.duplicate() as InputEventMouseButton
	click.pressed = false
	pointer.observe(click)
	pointer.handle_unhandled(click)
	_expect(pointer.pending == display and not is_inf(game.human.pointer_target_x), "clicking the hovered station queues the existing walk")
	pointer.cancel_walk()
	game.debug_place(game.pointer_use_x(&"purge_display"), 58.0)
	game.call("_update_gameplay_camera")
	game.intro_camera.reset_smoothing()
	await frames(3)
	hover.position = art.get_global_transform_with_canvas() * art.get_rect().get_center()
	pointer.handle_unhandled(hover)
	game.call("_refresh_ui")
	_expect(pointer.walk_target() == null and not game.station_prompt_walk and game.station_prompt_target == display and game.context_hint_glyph.visible, "in reach, the pill is the station's own action with its key again (%s)" % game.context_hint_text.text)
	game.input_mode.pointer_focus = false
	pointer.cancel()
	game.call("_refresh_ui")


## A translated/scaled plate keeps the same live canvas bounds for its hit target and HUD avoidance.
func _check_canvas_geometry() -> void:
	var holder: Node2D = Node2D.new()
	root.add_child(holder)
	holder.position = Vector2(30, 20)
	var plate: Control = Control.new()
	holder.add_child(plate)
	plate.position = Vector2(10, 15)
	plate.size = Vector2(20, 10)
	plate.scale = Vector2(2, 3)
	var target: Tappable = Tappable.new()
	holder.add_child(target)
	target.setup(&"plate", [], [plate])
	_expect(Tappable.canvas_rect(plate).is_equal_approx(Rect2(40, 35, 40, 30)), "plate bounds include ancestor translation and local scale")
	_expect(not is_inf(target.hit_score(Vector2(60, 50), false)), "the displayed plate centre remains clickable")
	holder.position.x += 80.0
	_expect(Tappable.canvas_rect(plate).position.is_equal_approx(Vector2(120, 35)) and is_inf(target.hit_score(Vector2(60, 50), false)), "moving the plate updates geometry without a cached hit rectangle")
	_expect(target.prompt_rect().is_equal_approx(Tappable.canvas_rect(plate)), "prompt and hit geometry share the same transformed plate")
	plate.hide()
	_expect(is_inf(target.hit_score(Vector2(140, 50), true)), "hidden plates retain geometry but cannot take a touch")
	_expect(not target.prompt_rect().has_area(), "hidden targets supply no drawn prompt anchor")
	holder.free()
