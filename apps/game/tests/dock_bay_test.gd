extends "res://tests/support/game_suite.gd"
## The opening's dock bay (DockBay, layout L1): its whole pieces load at the size the art set made them,
## each has an entry in the asset register, the near column draws over the actors, the corridor's
## chapter lets the engineer walk through the opening into the bay and stops them at its end wall, the
## camera eases continuously from the corridor's first framing to the whole room without showing past
## the room's plate, and the Director's door swings and badges.

## Each piece's world size in the art set's manifest (world_px, at 40 world px per metre), keyed by the
## node DockBay names it.
const SIZES: Dictionary = {
	"Room/Plate": Vector2(690.3, 504.1),
	"Room/ExitLeaf": Vector2(36.2, 83.5),
	"Room/ExitTrim": Vector2(33.0, 61.0),
	"Room/Casing": Vector2(52.0, 119.0),
	"Room/Beyond": Vector2(48.0, 93.0),
	"Front/NearColumn": Vector2(17.9, 340.4),
	"Room/Charger": Vector2(210.0, 77.1),
	"Room/CageFrame": Vector2(163.8, 104.2),
	"CageFront/Leaf0": Vector2(38.0, 82.0),
	"CageFront/Leaf3": Vector2(38.0, 82.0),
	"CageFront/Lock": Vector2(18.5, 29.3),
	"CageFront/TornLock/Torn": Vector2(25.3, 52.7),
}
## Each piece's file, which must be in the asset register.
const FILES: Array[String] = [
	"apps/game/assets/rooms/dock-mid.png",
	"apps/game/assets/doors/dock-exit-leaf.png",
	"apps/game/assets/doors/dock-exit-trim.png",
	"apps/game/assets/doors/dock-corridor-casing.png",
	"apps/game/assets/doors/dock-corridor-beyond.png",
	"apps/game/assets/doors/dock-corridor-front.png",
	"apps/game/assets/props/dock-charger.png",
	"apps/game/assets/props/cage-frame.png",
	"apps/game/assets/props/cage-leaf.png",
	"apps/game/assets/props/cage-leaf-lead.png",
	"apps/game/assets/props/cage-lock.png",
	"apps/game/assets/props/cage-lock-torn.png",
	"apps/game/assets/characters/wolf-lie-pad.png",
	"apps/game/assets/characters/wolf-rise.png",
]
## Drawn sizes may differ from the manifest's rounded world sizes by this much (world px).
const SIZE_SLACK: float = 0.6
## The walk back pans no faster than this (world px per second): a pan, not a cut.
const MAX_PAN_SPEED: float = 400.0


func _run() -> void:
	check_name = "Dock bay"
	var game: Node2D = await start_game("dock-bay-test", keep_running)
	game.call("_new_game")
	game.call("_finish_intro")
	await frames(30)
	var bay: DockBay = game.get("dock_bay") as DockBay
	var human: M0Actor = game.get_node("Human") as M0Actor
	var camera: Camera2D = game.get_node("IntroCamera") as Camera2D
	if not _require(bay != null and bay.is_visible_in_tree(), "the dock bay is built and shows in the corridor's chapter"):
		return
	for path: String in SIZES:
		var sprite: Sprite2D = bay.get_node_or_null(path) as Sprite2D
		if not _expect(sprite != null and sprite.texture != null, "%s is drawn" % path):
			continue
		var drawn: Vector2 = sprite.get_rect().size * sprite.scale.abs()
		_expect(drawn.distance_to(SIZES[path]) <= SIZE_SLACK, "%s is drawn at the art set's size (%s, drawn %s)" % [path, SIZES[path], drawn])
	var plate: Sprite2D = bay.get_node("Room/Plate") as Sprite2D
	_expect(plate.position.is_equal_approx(DockBay.PLATE_AT), "the room plate stands at the art set's place, its walk line on the corridor's")
	var register: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/manifest.json"))
	var paths: Array = []
	for entry: Dictionary in register["assets"]:
		paths.append(entry["path"])
	for file: String in FILES:
		_expect(file in paths, "%s has an entry in the asset register" % file)
	_expect(drawn_z(bay.front) > drawn_z(human), "the cross-wall's near column draws over the actors")
	_expect(not bay.exit_passage.visible and is_equal_approx(bay.exit_leaf.scale.x, 1.0 / DockBay.EXIT_LEAF_DENSITY), "the Director's door stands shut")
	bay.set_exit(1.0, 1.0)
	_expect(bay.exit_passage.visible and bay.exit_leaf.scale.x < 0.2 / DockBay.EXIT_LEAF_DENSITY and bay.exit_reader.color.is_equal_approx(Palette.LAMP_OPEN), "badged and open, the leaf swings away on its hinges over a dark passage and the reader shows green")
	bay.set_exit(0.0, 0.0)
	_expect(bay.exit_reader.color.is_equal_approx(Palette.LAMP_SHUT), "shut again, the reader is red")
	_check_states(bay)
	_check_leaves(bay)
	_check_lock(bay)
	bay.set_empty_quiet()

	# Walking left from first control: the camera eases from the corridor's framing to the whole room.
	var half_view: float = 960.0 / camera.zoom.x * 0.5
	var start_left: float = camera.get_screen_center_position().x - half_view
	_expect(absf(start_left - Main.L1_CORRIDOR_MIN_VIEW_X) <= 1.0, "first control's view starts at x %.0f, the opening at its edge (got %.1f)" % [Main.L1_CORRIDOR_MIN_VIEW_X, start_left])
	# The pan's speed over each tenth of a second (six physics frames), as the eye sees a pan.
	var samples: Array[float] = []
	var fastest: float = 0.0
	var leftmost_view: float = INF
	Input.action_press(&"move_left")
	for _frame: int in 360:
		await physics_frame
		var x: float = camera.get_screen_center_position().x
		samples.append(x)
		if samples.size() > 6:
			fastest = maxf(fastest, absf(x - samples[samples.size() - 7]) * 10.0)
		leftmost_view = minf(leftmost_view, x - half_view)
	Input.action_release(&"move_left")
	_expect(is_equal_approx(human.position.x, DockBay.HUMAN_MIN_X), "the engineer walks through the opening and stops at the bay's end wall (x %.1f)" % human.position.x)
	_expect(fastest <= MAX_PAN_SPEED, "the camera pans into the room continuously (fastest %.0f px/s)" % fastest)
	_expect(leftmost_view >= DockBay.VIEW_LEFT - 0.5, "the view never shows past the end wall into the plate's dark margin (%.1f)" % leftmost_view)
	_expect(await wait_until(func() -> bool: return absf(camera.get_screen_center_position().x - Main.L1_ROOM_VIEW_CENTRE) <= 1.0, 120), "the camera settles on the whole room, the bay to the opening")
	_expect(str(game.call("_context_hint")) != "E: read the Director's purge display.", "the corridor's purge display is not offered from the bay")
	await end_game(game)
	finish("Dock bay checks passed")


## Each charge state sets the pad's light and the battery screen (compose.py DOCK_BEATS): standby
## amber at 64 %, awake blue at 100 %, the charge cut dark, and the empty pad's amber standby with the
## battery's outline only. The screen shows numbers only: the battery readout, never a log's rows.
func _check_states(bay: DockBay) -> void:
	bay.set_standby()
	_expect(bay.charge.visible and bay.charge_color == DockBay.AMBER and bay.battery.percent == 64 and bay.battery.tint == DockBay.AMBER, "charging: the pad's light amber and the screen at 64 %")
	_expect(bay.battery.readout == PropScreen.Readout.BATTERY, "the charger's screen is a battery gauge and a percent, numbers only")
	bay.set_wake(1.0)
	_expect(bay.charge_color.is_equal_approx(DockBay.WAKE_BLUE) and bay.battery.percent == 100 and bay.battery.tint.is_equal_approx(DockBay.WAKE_BLUE), "awake: blue, the screen at 100 %")
	bay.set_charge(DockBay.WAKE_BLUE, 0.0)
	bay.set_battery(PropScreen.BATTERY_OFF)
	_expect(not bay.charge.visible and bay.battery.halo.modulate.a == 0.0, "the charge cut: the pad and the screen dark")
	bay.set_empty_quiet()
	_expect(bay.charge.visible and bay.charge_color == DockBay.AMBER and bay.charge_k == DockBay.STANDBY_K and bay.battery.percent == PropScreen.BATTERY_IDLE, "the empty pad: slow amber standby, the screen showing the battery's outline only")
	_expect(not bay.beacon_on and not bay.lock_lens.visible and bay.lock_torn, "the empty bay is quiet: the beacon and the lock's lens dark, the torn lock still hanging")


## The leaves: shut, the lead meets the pilaster; open, the four stack a track pitch apart at the left
## post; the push is continuous but for the one inelastic catch (a 2/3 drop), and the coast lasts at
## least 2 s (backup round 3).
func _check_leaves(bay: DockBay) -> void:
	bay.set_lead_travel(0.0)
	_expect(is_equal_approx(DockBay.leaf_x(3, 0.0) + DockBay.LEAF_WIDTH, DockBay.INTERIOR_TO) and is_equal_approx(DockBay.leaf_x(0, 0.0), DockBay.INTERIOR_FROM), "shut, the leaves span the cage from post to pilaster")
	var open: float = DockBay.lead_open_travel()
	for index: int in DockBay.LEAVES:
		_expect(is_equal_approx(DockBay.leaf_x(index, open), DockBay.INTERIOR_FROM + index * DockBay.STACK_STEP), "open, leaf %d is stacked at the left post" % index)
	var plan: Dictionary = DockBay.leaf_plan()
	_expect(DockBay.leaf_seconds() >= 2.0 and is_equal_approx(DockBay.leaf_travel(DockBay.leaf_seconds()), open), "the leaves coast for at least 2 s and stop at the open stop")
	_expect(is_equal_approx(float(plan["v_c0"]) / float(plan["v_b_end"]), 2.0 / 3.0), "the last catch drops the speed to 2/3")
	var step: float = 1.0 / 240.0
	var jumps: int = 0
	var last_v: float = 0.0
	var t: float = step
	while t < DockBay.leaf_seconds():
		var v: float = (DockBay.leaf_travel(t) - DockBay.leaf_travel(t - step)) / step
		if t > 2.0 * step and absf(v - last_v) > 8.0:
			jumps += 1
		last_v = v
		t += step
	_expect(jumps == 1, "the push's speed is continuous except at the one catch (%d jumps)" % jumps)
	bay.set_lead_travel(open)
	_expect(is_equal_approx((bay.leaves[3] as Sprite2D).position.x, DockBay.DOCK_X + DockBay.leaf_x(3, open)), "the drawn lead leaf follows its travel")


## The torn lock drops onto its cable and swings, settling within LOCK_DROP_S + LOCK_SWING_S; with
## Reduce Motion it hangs still at once.
func _check_lock(bay: DockBay) -> void:
	bay.set_standby()
	_expect(bay.lock.visible and bay.lock_lens.visible and not bay.torn_pivot.visible, "the guard lock holds, its lens lit")
	bay.tear_lock()
	_expect(not bay.lock.visible and not bay.lock_lens.visible and bay.torn_pivot.visible, "torn off, it hangs on its cable and its lens is out")
	_expect(absf(DockBay.torn_pose(DockBay.LOCK_DROP_S + 0.2).y) > 1.0 and DockBay.torn_pose(DockBay.LOCK_DROP_S + DockBay.LOCK_SWING_S) == Vector2.ZERO, "it swings and then hangs still")
	_expect(DockBay.torn_pose(0.05, true) == Vector2.ZERO, "with Reduce Motion it hangs still at once")
	bay.set_beacon(true)
	_expect(bay.beacon_on and bay.beacon_glow.visible, "the bay's beacon comes on")
	bay.set_beacon(false)
