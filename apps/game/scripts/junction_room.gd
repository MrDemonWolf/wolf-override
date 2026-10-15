extends Node2D
class_name JunctionRoom
## Blowback: the Service Junction, the third 960 px room after the Records exit, built from its own
## layered set (RoomDepth) and painted station props, with the corridor's breaker and a blast door
## in a cross-wall across the walkway (JunctionDoorLayout). What the art cannot show is drawn over it
## here from the state the parent mirrors in (PressureLine, DropArm, SentryBrain): the LINE gauge's
## needle, the vent glow and the door's status lamp, the hazard stripes over the door's blast zone
## while the fuse burns, the panel and entry hatch lights, the floor brackets (lit while the sentry's
## body is inside them) with the tank's shadow and the winch cable. Station
## names sit on small plates in one row of clear wall (the vent's on the floor by its grate), and a
## plate cut by the edge of the view fades out rather than show part of its name. What pulses follows
## the mirrored state (the fuse, the gauge), not a timer of its own.

## The exit door has finished sliding open into its pocket after the bolt arcs (bolt_arc).
signal hatch_opened

const JUNCTION_FAR: Texture2D = preload("res://assets/rooms/junction-far.png")
const JUNCTION_MID: Texture2D = preload("res://assets/rooms/junction-mid.png")
const JUNCTION_NEAR: Texture2D = preload("res://assets/rooms/junction-near.png")
const BREAKER_PROP: Texture2D = preload("res://assets/props/corridor-breaker.png")
const VALVE_PROP: Texture2D = preload("res://assets/props/junction-valve.png")
## The blast door: a hinged steel leaf (2.3 x 2.6 m, 0.30 m) in a 0.40 m cast-concrete cross-wall that
## stands ACROSS the walkway, its face turned 17 degrees to the camera like the corridor's door end.
## Every piece is one region of one lossless atlas (JunctionDoorLayout, generated from the design's
## placement.json). Under the actors: the empty doorway (blown), the shut or breaking leaf, the wall
## with the doorway at alpha 0, the blast damage, the TANK RELEASE bay. Over them: the near column
## with the status lamp, the wall's stub across the deck and, once blown, the leaf lying in the lane.
const VENT_PROP: Texture2D = preload("res://assets/props/junction-relief-vent.png")
const ARM_PROP: Texture2D = preload("res://assets/props/junction-tank-arm.png")
## The tank cut out of the tank-arm image (rows 361..743), so it can fall away from the arm.
const TANK_PROP: Texture2D = preload("res://assets/props/junction-tank.png")
const ARM_PANEL_PROP: Texture2D = preload("res://assets/props/junction-arm-panel.png")
const BOLT_PANEL_PROP: Texture2D = preload("res://assets/props/junction-bolt-panel.png")
## The entry (review r1, M5; design: docs/research-2026-10/sources/junction-entry-door-2026-10-13/): the
## engineer comes in from the service line passage the Records exit opens on, through a 3'0" x 7'0"
## hollow-metal steel door in a 300 mm cast cross-wall closing the room's left end, turned 17 degrees
## across the walkway like every door end of the base, in this room's camera (vanishing point (511,
## 162)). Its leaf swings into the junction on its hinges at the far jamb (SwingLeaf), its closer
## bringing it shut behind the arriving pair; the passage is painted behind the doorway into the far
## plate. Wall, leaf, near column, stub and the lamp's glass are one AtlasMesh (one draw call) drawn
## right after the mid plate: nobody passes behind the column (the leaf stops them at ENTRY_DOOR_X).
const ENTRY_ATLAS: Texture2D = preload("res://assets/props/junction-entry-atlas.png")
## The entry leaf's fill (fix round 4, review r4 M1; see RecordsRoom.EXIT_LEAF_FILL).
const ENTRY_LEAF_FILL: float = 0.0880
const ENTRY_WALL_REGION: Rect2 = Rect2(92.0, 2.0, 280.0, 607.0)
const ENTRY_WALL_AT: Vector2 = Vector2(7.0, 140.0)
const ENTRY_FRONT_REGION: Rect2 = Rect2(2.0, 2.0, 88.0, 634.0)
const ENTRY_FRONT_AT: Vector2 = Vector2(-2.0, 140.0)
const ENTRY_LEAF_ROOM_REGION: Rect2 = Rect2(374.0, 2.0, 73.0, 171.0)
const ENTRY_LEAF_OUT_REGION: Rect2 = Rect2(449.0, 2.0, 73.0, 171.0)
const ENTRY_LEAF_EDGE_REGION: Rect2 = Rect2(524.0, 2.0, 5.0, 171.0)
const ENTRY_LENS_REGION: Rect2 = Rect2(531.0, 2.0, 16.0, 20.0)
## One painted-steel pixel of the leaf's edge (low on it, under the lock front): the closer arm's colour.
const ENTRY_ARM_REGION: Rect2 = Rect2(526.0, 150.0, 1.0, 1.0)
## Where the shut leaf's junction face crosses the walk line: the door's collision face. Left of WOLF's
## tail at his spot by the entrance (WOLF_CLEAR_X - M0Actor.WOLF_REACH, x 33).
const ENTRY_DOOR_X: float = 30.0
const ENTRY_LAMP: Vector2 = Vector2(6.8, 345.2)
const ENTRY_HINGE: Vector3 = Vector3(0.89597, 0.0, 0.43639)
const ENTRY_AXIS_U: Vector3 = Vector3(0.292372, 0.0, 0.956305)
const ENTRY_AXIS_N: Vector3 = Vector3(-0.956305, 0.0, 0.292372)
## The lights the leaf sees, as they light the wall round it (jedesign.py), in the leaf's own exposure
## (fix round 4, review r4 M1; see RecordsRoom.EXIT_LEAF_LIGHTS): the door light, the room's left ceiling
## lamp, the wet deck's bounce (fill), the threshold and passage deck through the doorway and the cross-wall's
## lit face beyond the hinge jamb.
const ENTRY_LEAF_LIGHTS: Array = [
	[Vector3(0.8456, 2.8000, -0.0292), Vector3(1.7065, 1.8847, 1.9843), 1.40, 2.0, 0.00],  # the door light over the head (the design's: reach 1.4 m, down 2.0; true Lambert)
	[Vector3(1.9461, 5.2370, 4.2000), Vector3(0.6570, 0.9537, 1.0597), 3.40, 1.5, 0.06],  # the room's ceiling lamp
	[Vector3(2.7500, 0.1000, -3.0000), Vector3(0.0550, 0.0750, 0.0850), 4.00, 0.0, 0.06, true],  # the broad floor bounce (fill)
	[Vector3(0.4755, 0.0300, 0.0871), Vector3(0.3002, 0.3316, 0.3491), 0.90, 0.0, 0.05],  # the lit threshold and passage deck seen through the doorway
	[Vector3(1.0467, 1.4000, 0.8609), Vector3(0.3697, 0.4083, 0.4299), 1.00, 0.0, 0.05],  # the cross-wall's own lit face beyond the hinge jamb
]
## Its closer brings it shut behind them a moment after they come in, 90 to 10 degrees in 3 s or
## longer (ANSI/BHMA A156.19), as the Records entry's does; amber while it moves, red once it latches.
const ENTRY_CLOSE_DELAY: float = 0.35
const ENTRY_CLOSE_SECONDS: float = 3.4
const ENTRY_LAMP_SHUT: Color = Color(0.9, 0.2, 0.17)
const ENTRY_LAMP_MOVING: Color = Color("#f3ae4b")
## The exit: a power-operated sliding steel door in a cast-concrete cross-wall at the room's right end,
## turned 17 degrees across the walk line like the corridor's door end (its approach face crosses the
## walk line at EXIT_DOOR_X). Its leaf runs in the wall's middle on bottom rollers and slides back into
## a pocket in the far jamb; the service passage beyond is painted behind the doorway. One lossless
## atlas (docs: doors-2026-10-14/junction-exit), drawn at EXIT_ATLAS_SCALE (2 source px per world px):
## - beyond: the passage, the far reveal's rear half and the pocket (under the leaf);
## - leaf: the sliding leaf, moved by exit_leaf_anchor();
## - back: the cross-wall behind the walk line (its face back to the room's back wall, the far jamb and
##   its steel-lined reveal with the pocket mouth, the steel threshold, the status lamp's box and guard
##   and its conduit) and the bolt panel's riser down to its floor flange, drawn under the props;
## - lens: the status lamp's globe, lit live in the exit bolt's colour;
## - front: the cross-wall in front of the walk line (the near jamb, the wall beyond it, the lintel with
##   the exit bolt's housing, its conduit and the wall pack over the door), drawn over the actors, so
##   anyone walking through passes behind the near jamb;
## - deck: the junction's own deck and fascia past x 960 (a translated cut of the mid plate, not its
##   mirrored bleed), over the actors' floor reflections, since nothing behind the wall reflects in the
##   floor in front of it;
## - front also carries the wall's column (its 0.66 m end toward the camera, steel arris angles) and its
##   0.15 m stub across the deck (review r1, S4), as the corridor's and the blast door's do.
const EXIT_ATLAS: Texture2D = preload("res://assets/props/junction-exit-atlas.png")
const EXIT_ATLAS_SCALE: float = 0.5
## The source row where the mid plate's walkway meets the back wall; it is drawn at the floor (y 440).
const WALKWAY_Y: float = 776.0
## The far plate sits this much lower than the mid plate, as in the corridor, so it still covers
## the bottom of the view at the touch framing.
const FAR_DROP: float = 27.0
## The near plate's pipe column is 100 px wide in the room (source column 200) against the
## corridor's 57, so its strips hang that much further past the room edges.
const NEAR_OVERHANG: float = RoomDepth.NEAR_OVERHANG + 43.0
## Each prop is cut to its painted outline (source pixels) and scaled; its base sits on the floor.
## The breaker uses the corridor's cut and scale (see main.tscn), so both rooms show the same machine.
const BREAKER_REGION: Rect2 = Rect2(81.0, 46.0, 342.0, 433.0)
const BREAKER_SCALE: float = 0.225
const VALVE_REGION: Rect2 = Rect2(3.0, 11.0, 506.0, 490.0)
const VALVE_SCALE: float = 0.2
## The painted wheel (centre and rim radius) and gauge face on the valve image, in source pixels.
const VALVE_WHEEL_CENTRE: Vector2 = Vector2(255.0, 272.0)
const VALVE_WHEEL_RADIUS: float = 92.0
const VALVE_DIAL_CENTRE: Vector2 = Vector2(255.0, 64.0)
const VALVE_DIAL_RADIUS: float = 37.0
## The blast door's near column (JunctionDoorLayout COLUMN, COLBLOWN once blown) draws over the actors
## (DOOR_FRONT_Z) in every door state. In the rows a body lying on the floor fills (Main.COLLAPSE_TOPS),
## its painting starts at source column DOOR_COLUMN_FOOT of either cut and ends at the cut's right
## edge, so it covers DOOR_FOOT_X..DOOR_FOOT_RIGHT_X of the room there (junction_test measures both
## cuts). The stub's painting starts below the floor line, so it never covers a lying body. A slump
## that would reach under the column ends short of it on either side (Main._start_collapse).
const DOOR_COLUMN_FOOT: float = 0.0
const DOOR_FOOT_X: float = JunctionDoorLayout.COLUMN_AT.x + DOOR_COLUMN_FOOT * JunctionDoorLayout.COLUMN_SCALE
const DOOR_FOOT_RIGHT_X: float = JunctionDoorLayout.COLUMN_AT.x + JunctionDoorLayout.COLUMN_REGION.size.x * JunctionDoorLayout.COLUMN_SCALE
## How long the breaking leaf shows at the blast before the blown doorway replaces it.
const DOOR_BREAK_SECONDS: float = 0.15
## Fix round 4 (review r4 C2, human r4): the leaf is thrown, not swapped. After DOOR_BREAK_SECONDS the torn
## leaf leaves its doorway into the lane, tipping over as it flies (SDI 133 / ASTM F2927 Category IV: the
## door separates from its frame and becomes flying debris), and lands where it then lies, raising dust off
## the wet deck. World px: its centre from the doorway to the lying leaf's body (JunctionDoorLayout's
## breaking-leaf and lying-leaf pieces), how high it rises on the way, how far it turns (nearly flat) and how
## much nearer the camera it lands (the lying leaf is drawn in front of the walk line, at 1.25x the size).
const DOOR_FLIGHT_SECONDS: float = 0.24
const DOOR_FLIGHT_FROM: Vector2 = Vector2(479.3, 389.7)
const DOOR_FLIGHT_TO: Vector2 = Vector2(641.0, 462.5)
const DOOR_FLIGHT_RISE: float = 18.0
const DOOR_FLIGHT_TURN: float = 1.5
const DOOR_FLIGHT_GROW: float = 1.22
## The share of the flight after which the leaf is clear of the near column and draws in front of it.
const DOOR_FLIGHT_CLEAR: float = 0.3
const VENT_REGION: Rect2 = Rect2(8.0, 35.0, 743.0, 183.0)
const ARM_REGION: Rect2 = Rect2(88.0, 9.0, 388.0, 352.0)
## Where the tank was cut out of the tank-arm image.
const TANK_REGION: Rect2 = Rect2(144.0, 361.0, 211.0, 382.0)
const TANK_ART_SCALE: float = 0.22
const ARM_PANEL_REGION: Rect2 = Rect2(79.0, 26.0, 354.0, 463.0)
const ARM_PANEL_SCALE: float = 0.14
const ARM_PANEL_LIGHT: Rect2 = Rect2(206.0, 88.0, 92.0, 20.0)
const BOLT_PANEL_REGION: Rect2 = Rect2(0.0, 68.0, 512.0, 393.0)
const BOLT_PANEL_SCALE: float = 0.15
const BOLT_PANEL_LIGHT: Rect2 = Rect2(222.0, 118.0, 70.0, 20.0)
## The exit atlas's pieces: (atlas region, world top-left). placement.json in the design record.
const EXIT_BEYOND: Rect2 = Rect2(228.0, 0.0, 198.0, 616.0)
const EXIT_BEYOND_AT: Vector2 = Vector2(933.0, 140.0)
const EXIT_BACK: Rect2 = Rect2(428.0, 0.0, 286.0, 607.0)
const EXIT_BACK_AT: Vector2 = Vector2(829.5, 140.0)
const EXIT_FRONT: Rect2 = Rect2(0.0, 0.0, 226.0, 644.0)
const EXIT_FRONT_AT: Vector2 = Vector2(919.0, 140.0)
const EXIT_LENS: Rect2 = Rect2(992.0, 0.0, 14.0, 11.0)
const EXIT_LENS_AT: Vector2 = Vector2(909.5, 323.0)
const EXIT_LEAF: Rect2 = Rect2(870.0, 0.0, 120.0, 236.0)
## The leaf image's leading-edge bottom corner, in its own (atlas-region) pixels: the point
## exit_leaf_anchor() places.
const EXIT_LEAF_ANCHOR: Vector2 = Vector2(106.27, 229.9)
## The cross-wall and its door, in metres (the design's geometry, tools/geom.py): the approach face
## crosses the walk line at EXIT_DOOR_X; s runs along the wall toward the room's back, n through it
## toward the passage. The camera is the junction's own (review r1, C1: vanishing point (511, 162), as
## the blast door's, measured from the deck seams; the walk line 38 m from the eye, 40 px per metre).
const EXIT_DOOR_X: float = 962.0
const EXIT_VPX: float = 511.0
const EXIT_HORIZON: float = 162.0
const EXIT_WALL_ANGLE: float = 17.0
const EXIT_LEAF_N: float = 0.27
const EXIT_LEAD_SHUT_S: float = -0.5
const EXIT_LEAD_OPEN_S: float = 1.62
## Where the near jamb's edge stands on screen (s -0.4 on the approach face): anyone whose drawn body is
## all right of it has gone through, behind the wall.
const EXIT_NEAR_JAMB_X: float = 971.3
## The junction's own deck and fascia carried on past x 960 to the view's edge (review r1, M4): the mid
## plate translated 2.0 m along the room in its camera (seams to its vanishing point), not its mirrored
## bleed; drawn over the floor reflections of anyone who has gone through, behind the wall's stub.
const EXIT_DECK: Rect2 = Rect2(716.0, 0.0, 152.0, 288.0)
const EXIT_DECK_AT: Vector2 = Vector2(956.0, 440.0)
## The deck's bottom rows mirrored on down past its end (y 584), as the room's mid plate's bottom bleed
## does: the touch framing (Main.GAMEPLAY_CAMERA_Y_TOUCH) shows down to y ~592, and a camera shake
## 10 px more, so at the junction's right end the view would otherwise show the far plate there.
const EXIT_DECK_BLEED: float = 40.0
## The passage's and the deck's right-hand columns mirrored on past their end (x 1032), as the room's
## mid plate's right bleed does: a camera shake (Impact.MAX_SHAKE_PX, the bolt's arc at 0.8 trauma) at
## the view's right end (EXIT_VIEW_RIGHT) would otherwise show the far plate there.
const EXIT_EDGE_BLEED: float = 12.0
## Each bleed mirrors its piece's rows or columns from this many atlas px short of the piece's edge, and
## overlaps the piece by half as many world px: the edge texel blends with the transparent atlas gap
## beside it under linear filtering, so a seam on the edge itself would let a faint line of the far
## plate through.
const EXIT_SEAM_TRIM: float = 2.0
## The junction's camera may show this far right (Main), so the near jamb, the wall's column and the
## passage beyond frame the doorway (the exit's pieces and its deck cover the view to here), and the
## actors may walk on through it this far: on down the passage, out of view behind the wall, far enough
## that WOLF's body and the engineer's never share the same floor.
const EXIT_VIEW_RIGHT: float = 1030.0
const EXIT_WALK_MAX_X: float = 1100.0
## WOLF in the open doorway, looking back at the engineer: his head, shoulders and forelegs in view on
## the threshold, his hindquarters already past the near jamb and hidden by it. Fix round 2 (review r2,
## human pass): at x 985 his rear stood out past the near column (x 971.5..1000 at his height) in the
## stub's cutaway, against the passage, so the jamb cut him in half; here his tail tip (x 934 + 64 with
## the art mirrored) stays behind the column's edge at x 1000.
const WOLF_DOORWAY_X: float = 934.0
## The engineer is at the exit from here (USE leaves through it), and walks no further while WOLF
## stands in the doorway (his tail at WOLF_DOORWAY_X - M0Actor.WOLF_REACH).
## (fix round 2: 846, was 870, so the engineer can stand behind WOLF in his new spot, their back clear
## of the bolt panel's edge but for STATION_OVERLAP)
const HATCH_REACH_MIN_X: float = 846.0
const HATCH_REACH_MAX_X: float = WOLF_DOORWAY_X - M0Actor.WOLF_REACH - M0Actor.HUMAN_REACH
## Walking out, each is gone once their whole drawn body is past the near jamb.
const WOLF_GONE_X: float = EXIT_NEAR_JAMB_X + M0Actor.WOLF_REACH + 3.0
const HUMAN_GONE_X: float = EXIT_NEAR_JAMB_X + M0Actor.HUMAN_REACH + 3.0
## The breaker's status light rides on the amber bar painted at the top of its cabinet.
const BREAKER_LIGHT: Rect2 = Rect2(BREAKER_X - 11.0, 358.0, 18.0, 5.0)
## Station centres, left to right.
const BREAKER_X: float = 200.0
const VENT_X: float = 300.0
const VALVE_X: float = 420.0
const DOOR_X: float = 480.0
## The rubble line is the sentry's lane boundary.
const RUBBLE_X: float = SentryBrain.RUBBLE_X
## Half the drawn width of the machines the actors must not stand inside.
const BREAKER_HALF_WIDTH: float = BREAKER_REGION.size.x * BREAKER_SCALE * 0.5
const VALVE_HALF_WIDTH: float = VALVE_REGION.size.x * VALVE_SCALE * 0.5
const ARM_PANEL_HALF_WIDTH: float = ARM_PANEL_REGION.size.x * ARM_PANEL_SCALE * 0.5
const BOLT_PANEL_HALF_WIDTH: float = BOLT_PANEL_REGION.size.x * BOLT_PANEL_SCALE * 0.5
## The TANK RELEASE stands at the left end of the alcove that hides the engineer from the sentry, just
## inside its left post, so the engineer works it from beside it, inside the cover (Main's
## JUNCTION_STATIONS).
const ARM_X: float = SentryBrain.COVER_MIN_X + ARM_PANEL_HALF_WIDTH + 2.0
## The exit bolt's panel stands on the floor left of the exit door, the riser on its right running down
## into a floor flange (drawn in the exit's back layer). The engineer works it from its left, facing it
## (BOLT_X), clear of the downed sentry; its USE reaches from BOLT_REACH_MIN_X rightward, and once the
## door is open the way out answers from HATCH_REACH_MIN_X.
## (fix round 2: 796, was 806: 10 px further from the door, so the engineer has room at the open door
## behind WOLF in the doorway; its riser moves with it, in the exit's back layer)
const BOLT_PANEL_X: float = 796.0
## (6 px: the engineer's front hand over the panel's edge, Main.STATION_OVERLAP.)
const BOLT_X: float = BOLT_PANEL_X - BOLT_PANEL_HALF_WIDTH - M0Actor.HUMAN_REACH + 6.0
const BOLT_REACH_MIN_X: float = BOLT_X - 16.0
const FLOOR_Y: float = 440.0
## Where WOLF stands to read the line on entry: on the valve's left, facing it, his snout at the
## valve's edge below its LINE gauge, so he never stands inside the machine. There is no floor at the
## door itself: the valve stands right in front of it, and the only gap between the breaker and the
## valve (the idle relief vent's grate, 33 px of bare floor) is far shorter than his body, so the
## narration names the gauge he reads, not the door (Main.JUNCTION_ENTRY_LINE).
const WOLF_SEAM_X: float = VALVE_X - VALVE_HALF_WIDTH - M0Actor.WOLF_REACH - 2.0
## Where WOLF holds back from the rubble line while the engineer deals with the lane (or after he breaks
## off drawing the sentry): the nearest clear floor to it, his reading spot by the valve. Between the
## valve and the rubble line the valve, the blown door's near column and the engineer at CHOICE_X leave
## no floor as long as he is, so any nearer spot would stand him inside them.
const WOLF_RUBBLE_X: float = WOLF_SEAM_X
## Doors fix round 2 (review r2, human pass: "WOLF stands inside the valve"): wherever his body would
## pass over the valve after the blast (walking by it on the way down the lane or back), he steps out
## onto the deck in front of it, about 1.3 m nearer the camera: his drawn body this much lower on the screen (the deck
## in this camera falls 9.3 px per metre toward the camera at the walk line), so his feet stand clearly
## in front of the valve's base and he draws over it.
const WOLF_STEP_FORWARD: float = 12.0
const WOLF_STEP_FULL: float = 40.0
const WOLF_STEP_RAMP: float = 60.0
## Where WOLF stands when he chooses to draw the sentry: at the far end of its lane, in front of the
## exit hatch (a doorway in the back wall, not a machine), facing back down the lane, his painted snout
## (M0Actor.WOLF_SNOUT) just clear of the bolt panel's right edge and his painted tail
## (M0Actor.WOLF_TAIL) inside the room's right edge. It parks BAIT_OFFSET short of him, on the
## mark, facing him with its back to the TANK RELEASE, so the engineer working the release is behind
## it and never between the two; his drawn body stays far outside the floor brackets and the tank.
const WOLF_BAIT_X: float = DropArm.MARK_X + SentryBrain.BAIT_OFFSET
## Where WOLF waits once the sentry is down, through the bolt and the closing beat: the same spot, in
## full view by the hatch he says is next, clear of the crushed sentry and the tank on it.
const WOLF_DOWN_X: float = WOLF_BAIT_X
## Crossing the lane to his spot, WOLF bounds over the live sentry rather than through it
## (wolf_leap_height): his painted feet (y 438) clear its drawn top (Sentry.FLOOR_Y less
## Sentry.DRAWN_HEIGHT, y 396) by 6 px at the top of the bound, held while his legs are over its body
## (LEAP_CLEAR: the two bodies' contact range, SentryBrain.HALF_WIDTH plus M0State.WOLF_HALF_WIDTH, and a
## 5 px margin) and eased in and out over LEAP_RAMP either side, where only his snout or tail passes its
## low treads. He runs LEAP_SPEED_SCALE times faster meanwhile, so it reads as a bound, not a hover. The
## tank's base (y 382 at most) is lower than the top of his head at the bound, so he never bounds under
## it: the sentry he draws backs off ahead of him to the end of its patrol (SentryBrain.BAIT_OFFSET)
## and he catches it there, and the bound and both ramps stay clear of the hanging tank's painted body
## by a few px (sentry_test measures the two images).
const LEAP_HEIGHT: float = 48.0
const LEAP_CLEAR: float = SentryBrain.HALF_WIDTH + M0State.WOLF_HALF_WIDTH + 5.0
const LEAP_RAMP: float = 30.0
const LEAP_SPEED_SCALE: float = 2.0
## Running under the hung tank on his way down the lane, WOLF ducks: at rest the tips of his ears
## (y 379) are higher than the tank's rounded base (y 382 at its lowest), so while his head (WOLF_HEAD_X
## ahead of his centre) is within DUCK_CLEAR of the mark he runs crouched, his drawn body squashed
## DUCK_DEPTH px lower with his feet on the floor, easing in and out over DUCK_RAMP. His head then
## passes a few px under the tank's base (sentry_test measures the two images).
const DUCK_DEPTH: float = 9.0
const DUCK_CLEAR: float = 34.0
const DUCK_RAMP: float = 24.0
const WOLF_HEAD_X: float = 45.0
## Once the tank is down on the sentry, WOLF crossing from his spot by the valve to his spot by the hatch bounds
## clean over the crushed tank and the wreck under it in one arc (wolf_tank_leap_height): a parabola in
## x, so at his steady LEAP_SPEED_SCALE speed it is a fall under constant gravity, TANK_LEAP_HEIGHT at
## its top over TANK_LEAP_PEAK_X and back on the floor TANK_LEAP_HALF_SPAN either side. He is 134 px
## long, the tank stands 107 px over the floor about 60 px past the engineer working the release, and
## the parked arm's claw hangs only some 10 px above the height that clears the tank, so there is no
## room for a short hop: he takes off a few px before his snout reaches the engineer's back, passes
## over them on the way up and lands just short of his spot. His painted feet (y 438) pass over the
## tank's top (y 331, on the crushed hull) and his back under the claw. The empty arm hangs too low over
## the tank for him to pass under it, so it winches up into its ceiling plate as the tank lands for good
## (ARM_PARK_RISE over ARM_PARK_SECONDS), and he waits by the valve until it is up. sentry_test measures
## his painted body against the tank's, the wreck's and the arm's images on every frame of the crossing
## and at every x (3 px clear).
const TANK_LEAP_HEIGHT: float = 122.0
const TANK_LEAP_PEAK_X: float = DropArm.MARK_X - 5.0
const TANK_LEAP_HALF_SPAN: float = 180.0
const ARM_PARK_RISE: float = 44.0
const ARM_PARK_SECONDS: float = 0.3
## Where WOLF waits while the line builds and the fuse burns: back by the entrance hatch, his snout at
## the breaker's left edge (his painted front is a few px inside M0Actor.WOLF_REACH), so he is not
## inside the breaker, his drawn body is clear of the engineer working it from its right, his tail
## stays in view while they crank the valve, and he is nowhere near the relief vent's grate, its
## steam or the door's blast zone.
const WOLF_CLEAR_X: float = 100.0
## The engineer's front foot on the rubble line: where the question of how to drop the tank comes up,
## still outside the sentry's lane.
const CHOICE_X: float = RUBBLE_X - M0State.HUMAN_HALF_WIDTH
## The tank hangs centred here and lands with its base on the floor. At the play framing (zoom 1.35,
## camera y 360) its top (y 298) sits at screen y ~186, below the answer buttons
## (Main.CHOICE_ROW_TOP), and its base (y 382) clears the sentry's scanner fin (Sentry.DRAWN_HEIGHT)
## as it patrols underneath.
const TANK_REST_Y: float = 340.0
const TANK_SIZE: Vector2 = TANK_REGION.size * TANK_ART_SCALE
## The middle of the tank's shadow: on the floor stripes under it.
const SHADOW_Y: float = FLOOR_Y + 1.0
## The arm's ceiling plate hangs on two rods from the mid plate's overhead gantry (its underside).
const GANTRY_Y: float = 120.0
## The exit door slides open this long after the bolt arcs.
const HATCH_OPEN_SECONDS: float = 0.5
## The sealed door body is this wide; its left face is M0State.JUNCTION_DOOR_LEFT_X.
const DOOR_WIDTH: float = 56.0
const DOOR_HEIGHT: float = 132.0
## The door's pieces under the actors draw at DOOR_Z (over the mid plate, under the props), the
## release bay one step above them (over the bolt feed in Recesses); the column, stub and lying leaf
## at DOOR_FRONT_Z, over the actors (this node sits at z 1), so they pass through the doorway behind
## the near column.
const DOOR_Z: int = -3
const BAY_Z: int = -2
const DOOR_FRONT_Z: int = 2
## The status lamp on the column: red shut, amber while the line builds, flashing red and white
## through the fuse (steady red with Reduced Motion), dark once the door is down.
const LAMP_SHUT: Color = Color(0.9, 0.2, 0.17)
const LAMP_DEAD: Color = Color(0.16, 0.17, 0.18)
## The vent's steam and its burst draw one step under the props (the grate is a prop), so the grate is
## drawn over the steam rising out of it.
const VENT_STEAM_Z: int = -2
## How long the grate stays dangerous after the relief vent lets go.
const HAZARD_SECONDS: float = 0.4
## The knockdown cards, in the third person like the narration; each is formatted with the engineer's
## first name.
const VENT_REASON: String = "The relief vent let go under %s. When the gauge peaks, stay off the grate."
const BLAST_REASON: String = "The door went with %s in front of it. When the fuse lights, back away past the valve."
## SENTRY_REASON is for an engineer it spotted and ran down out in the open, which is always past the
## cover beside the TANK RELEASE (SentryBrain.is_exposed); it points at the drawn release, not at an
## alcove or posts the picture does not show (P0-7, approved 2026-10-13). Once it has turned on them
## after a miss, or reaches them at the release, that cover is no help and SENTRY_CHASED_REASON says
## so. Both are two rows.
const SENTRY_REASON: String = "The sentry saw %s out in the open.\nStay close to the TANK RELEASE."
const SENTRY_CHASED_REASON: String = "The sentry ran %s down. Once its\neyes go red, only the rubble is safe."
const CLOUD_REASON: String = "The coolant cloud caught %s. Let it clear before crossing the mark."
const AMBER: Color = Color("#f3ae4b")
const GREEN: Color = Color("#a4f0c4")
const DIM: Color = Color("#3e4f5a")
const STEEL: Color = Color("#4a6572")
const COOLANT: Color = Color("#7fe8ff")
const SEAM_RED: Color = Color("#ff6a55")
## The tank's cable, in the tones of the cable painted on the arm's winch drum.
const CABLE_SHADOW: Color = Color("#0d1419")
const CABLE_BODY: Color = Color("#35434c")
const CABLE_SHEEN: Color = Color(0.55, 0.64, 0.7, 0.55)
## Station name plates: their top edge, all in one row of clear wall between the far plate's pipe run
## and the machines' tops, and their text size.
const LABEL_Y: float = 320.0
const LABEL_FONT_SIZE: int = 12
## The VALVE plate sits this far left of the wheel so its longest text ends well before the door.
const VALVE_LABEL_SHIFT: float = 28.0
## The breaker's plate sits this far left of the breaker, and the RELIEF VENT plate this far left of
## the grate's centre, so the vent's name fits between the longest breaker and valve texts.
const BREAKER_LABEL_SHIFT: float = 12.0
const VENT_LABEL_SHIFT: float = 3.0
## The door's placard is centred over the doorway's head.
const DOOR_LABEL_X: float = 479.0
## The TANK RELEASE plate sits right of the panel, clear of the door's column and its placard.
const ARM_LABEL_SHIFT: float = 20.0
## The EXIT plate sits over the bolt panel, left of the hatch it also names.
const EXIT_LABEL_X: float = 792.0
## The feed from the TANK RELEASE to the exit bolt panel runs under the floor and comes up at the
## bolt panel (_draw_bolt_feed), so nothing runs across the lane where the tank comes down. Its cable
## box is centred at this height, behind the ends of the panel's painted cables. Dead while the winch
## holds the tank; once the tank is down its power runs to the bolt (amber), warming to white through
## the whine and green once the bolt drops.
const BOLT_FEED_Y: float = 404.0
## The cable box (behind the three painted cable ends) and the floor gland the conduit comes up from.
const FEED_BOX: Vector2 = Vector2(8.0, 34.0)
const FEED_GLAND: Vector2 = Vector2(12.0, 3.0)
## The box's and gland's painted-steel face, a step lighter than the conduit.
const FEED_STEEL: Color = Color("#2a3741")
## A plate fades out over this many px as it reaches the edge of the view.
const LABEL_EDGE_FADE: float = 14.0
const LABEL_PLATE: Color = Color(0.035, 0.06, 0.08, 0.8)
const LABEL_PLATE_EDGE: Color = Color(0.29, 0.4, 0.45, 0.55)
const VENT_LABEL: String = "RELIEF VENT"
## The glow over the vent grate, warming with the gauge, flashing red through its hard warning and red
## once it has tripped.
const VENT_GLOW_SIZE: Vector2 = Vector2(96.0, 22.0)
## The vent's hard warning flashes this many times a second (steady with Reduced Motion).
const VENT_FLASH_HZ: float = 5.0
## After the vent lets go the needle stays pinned at the top, red, for HAZARD_SECONDS (and through a
## knockdown, when nothing advances it), then falls back to empty over this long.
const GAUGE_FALL_SECONDS: float = 0.8
## The caption beside the valve's dial, the gauge the narration names.
const LINE_CAPTION: String = "LINE"
const LINE_CAPTION_FONT_SIZE: int = 8
## The hazard stripes over the door's blast zone pulse this many times a second while the fuse burns
## (steady with Reduced Motion): once per fuse tick, peaking with it, and at no more than 2 Hz, so even
## the longer fuse stays well under three flashes a second (A11Y-2).
const BLAST_STRIPE_HZ: float = 1.0 / PressureLine.FUSE_TICK_SECONDS
## The floor brackets glow this colour while the sentry's body is inside them.
const MARK_LIT: Color = Color("#ffe9a8")
## The alcove is painted: a recessed bay whose two steel posts stand on SentryBrain.COVER_MIN_X and
## COVER_MAX_X, so where cover stops (the right post) shows beside an engineer at the TANK RELEASE.
## A refused press (Main._refuse) or a bump into the sealed door: the station's lamp goes dark for
## FLICKER_STEP_SECONDS and comes back, twice for a press and once for a bump. The door's status lamp is
## barely lit at rest, so its flicker lights it up between the dark steps. With Reduced Motion the lamp
## goes dark once and comes back, with no repeat.
const FLICKER_STEP_SECONDS: float = 0.07
const FLICKER_DARK: Color = Color("#1a2228")
const SEAM_FLICKER_ALPHA: float = 0.75
## Hint ladder T1: the breaker's lamp pulses while WOLF looks at it, this many times a second (at most
## 2 Hz, well under three flashes a second; steady and bright with Reduced Motion).
const BREAKER_PULSE_HZ: float = 1.5
## Cuts the turning wheel out of the valve image as a disc, so only the wheel turns over the
## painted one.
const WHEEL_MASK: String = """shader_type canvas_item;
uniform vec2 centre;
uniform float radius;
void fragment() {
	COLOR.a *= 1.0 - smoothstep(radius - 0.006, radius, distance(UV, centre));
}
"""

## Ceiling lamp centres as fractions of the far plate, measured from the plate; the lockdown
## beacons sit on the tops of its two braced pillars.
var lamps: PackedVector2Array = PackedVector2Array([Vector2(0.139, 0.268), Vector2(0.493, 0.268), Vector2(0.857, 0.268)])
var warning_lamps: PackedVector2Array = PackedVector2Array([Vector2(0.294, 0.285), Vector2(0.703, 0.285)])

# Mirrored from the parent's state and PressureLine; the parent calls sync_line()/refresh_state().
var line_state: StringName = &"idle"
var gauge: float = 0.0
var turns: int = 0
## How far into the next turn a hold at the valve has its wheel (HoldUse.shown_fraction), 0 while it
## is not held. Set through show_crank.
var crank_fraction: float = 0.0
var door_blown: bool = false
var sentry_down: bool = false
var junction_cleared: bool = false
## Mirrored from DropArm: its state and how far down the tank is (0 hanging, 1 on the floor), and
## whether a missed tank still lies on the floor before the winch takes it (DropArm.on_floor).
var arm_state: StringName = &"hung"
var tank_drop: float = 0.0
var tank_on_floor: bool = false
## Mirrored from PressureLine: seconds left on the fuse, which drives the blast stripes' pulse.
var fuse_remaining: float = 0.0
## The needle's reading: the gauge while it builds, pinned at the top for a while after the vent lets
## go (gauge_hold seconds left), then falling back; gauge_tripped draws it red meanwhile.
var display_gauge: float = 0.0
var gauge_hold: float = 0.0
var gauge_tripped: bool = false
## 0 with the arm hanging where it holds the tank, 1 once it has winched up into its ceiling plate
## after the tank came down on the sentry (ARM_PARK_RISE).
var arm_parked: float = 0.0:
	set(value):
		arm_parked = value
		if arm_art != null:
			arm_art.position.y = arm_rest_y - ARM_PARK_RISE * arm_parked
			queue_redraw()
## Mirrored from Main's exit bolt: locked, charging (0..1 through the whine) or open.
var bolt_state: StringName = &"locked"
var bolt_charge: float = 0.0
## 0 shut, 1 open; slides once after the bolt arcs.
var hatch_open: float = 0.0:
	set(value):
		hatch_open = value
		_sync_hatch()
## Reduced Motion: the charged door lamp holds steady instead of flashing.
var reduce_motion: bool = false:
	set(value):
		reduce_motion = value
		if is_node_ready():
			_sync_lamp()

var depth: RoomDepth
var breaker_art: Sprite2D
var valve_art: Sprite2D
var vent_art: Sprite2D
var arm_art: Sprite2D
## Where the arm hangs while it holds the tank (its centre's y).
var arm_rest_y: float = 0.0
var arm_panel_art: Sprite2D
var bolt_panel_art: Sprite2D
## The entry door (see ENTRY_ATLAS): its swinging leaf, the mesh that draws it all, its lamp's glass
## quad, its collision body and the closer's tween.
var entry_leaf: SwingLeaf
var entry_mesh: AtlasMesh
var entry_lamp_quad: int = -1
var entry_door_shape: CollisionShape2D
var entry_tween: Tween
## The exit door's pieces (see EXIT_ATLAS).
var exit_beyond: Sprite2D
var exit_leaf: Sprite2D
var exit_back: Sprite2D
var exit_lens: Sprite2D
var exit_deck: Sprite2D
var exit_deck_bleed: Sprite2D
var exit_front: Sprite2D
var recesses: Recesses
## The exit bolt's panel drawn again over the sentry where it passes behind it.
var panel_front: PanelFront
var door_body: StaticBody2D
var door_shape: CollisionShape2D
## The door's pieces (JunctionDoorLayout): the shut leaf; at the blast the breaking leaf and cracks
## show for DOOR_BREAK_SECONDS, then the empty doorway, the damage and the leaf lying in the lane.
var door_hole: Sprite2D
var door_leaf: Sprite2D
var door_leaf_breaking: Sprite2D
var door_wall: Sprite2D
var door_cracks: Sprite2D
var door_damage: Sprite2D
var release_bay: Sprite2D
var door_column: Sprite2D
var door_stub: Sprite2D
var door_leaf_down: Sprite2D
## The status lamp's glass and its small glow, tinted live.
var door_lamp: Sprite2D
var door_lamp_glow: Sprite2D
## True from the blast until the breaking frame gives way to the blown one.
var door_breaking: bool = false
## True while the torn leaf is in the air (DOOR_FLIGHT_SECONDS), and how far along its flight it is (0..1).
var door_flying: bool = false
var door_flight: float = 0.0
## The dust the leaf raises where it lands.
var landing_dust: CPUParticles2D
var valve_wheel: Sprite2D
var vent_steam: CPUParticles2D
var vent_puff: CPUParticles2D
var blast_sparks: CPUParticles2D
var blast_debris: CPUParticles2D
var blast_dust: CPUParticles2D
var vent_hazard: Hazard
var cloud_hazard: Hazard
var sentry: Sentry
var tank: TankSprite
var coolant_cloud: CPUParticles2D
var coolant_burst: CPUParticles2D
var hit_sparks: CPUParticles2D
var bolt_sparks: CPUParticles2D
var arm_label: Label
## TANK DOWN, over the tank once it lies on the sentry.
var tank_label: Label
## The LINE caption beside the valve's dial.
var line_caption: Label
var hatch_label: Label
var breaker_glow: Sprite2D
var vent_glow: Sprite2D
var breaker_label: Label
var valve_label: Label
var door_label: Label
## The relief vent's floor caption, on the same plate, just above its grate.
var vent_label: Label
var station_labels: Array[Label] = []
var label_plate: StyleBoxFlat
var floor_reflections: Array[FloorReflection] = []
## What this node's _draw and Recesses last drew from (draw_inputs, recesses_inputs), so the
## per-frame syncs redraw them only when something they draw has changed.
var _drawn_inputs: Array = []
var _recesses_drawn_inputs: Array = []
var _redraw_check_queued: bool = false
## The station whose lamp is flickering (breaker, valve, door, release or bolt), how far into it, and how
## many times it goes dark.
var flicker_station: StringName = &""
var flicker_elapsed: float = 0.0
var flicker_times: int = 0
## Seconds the breaker's lamp still pulses for the hint ladder, and how long it has pulsed.
var breaker_pulse_remaining: float = 0.0
var breaker_pulse_elapsed: float = 0.0
var _valve_tween: Tween
var _lamp_tween: Tween
var _door_tween: Tween
var _hazard_tween: Tween
var _hatch_tween: Tween
var _arm_tween: Tween


## The hanging coolant tank, cut from the tank-arm art, with a dent drawn on after a missed drop.
class TankSprite:
	extends Sprite2D
	var dent: Polygon2D
	var dented: bool = false:
		set(value):
			dented = value
			dent.visible = dented

	func _init() -> void:
		dent = Polygon2D.new()
		dent.name = "Dent"
		# In the cut's own pixels around its centre: a crease in the right flank of the body.
		dent.polygon = PackedVector2Array([Vector2(78.0, 30.0), Vector2(50.0, 62.0), Vector2(78.0, 92.0)])
		dent.color = Color("#14242c")
		dent.visible = false
		add_child(dent)


## What sits behind the stations: the release's feed to the exit bolt, drawn under the props (the
## room's own drawing sits over them).
class Recesses:
	extends Node2D
	var room: JunctionRoom

	func _draw() -> void:
		room.draw_recesses(self)


## The exit bolt's panel stands nearer than the sentry's lane: at the far end of its patrol the machine
## and its beam pass behind it. Right after the sentry and at its depth, this draws the panel and its
## light again wherever the sentry's drawing crosses the panel (bolt_panel_cover), with the bolt's feed
## under the panel's painted cables there too, so none of them is ever drawn under the machine, and
## draws nothing while the sentry is clear of it. Only those spots are drawn, so the engineer working the
## bolt and WOLF by the hatch still draw over the panel as before.
class PanelFront:
	extends Node2D
	var room: JunctionRoom
	## The room rectangles drawn this frame (bolt_panel_cover) and the colours they were drawn with: the
	## panel's lamp as it shows (bolt_lamp_color) and the feed's core (bolt_feed_color), so a change to
	## either redraws them.
	var cover: Array[Rect2] = []
	var colors: Array[Color] = []

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		# After Main's frame, which moves the sentry, so the cover is where the sentry is drawn.
		process_priority = 100

	func _process(_delta: float) -> void:
		var now: Array[Rect2] = room.bolt_panel_cover()
		var look: Array[Color] = [room.bolt_lamp_color(), room.bolt_feed_color()]
		if now != cover or (not now.is_empty() and look != colors):
			cover = now
			colors = look
			queue_redraw()

	func _draw() -> void:
		if not cover.is_empty():
			room.draw_panel_front(self, cover, colors[0])

	## What _draw covers: the bounds of [member cover], for the debug tools' render box.
	func debug_draw_rect() -> Rect2:
		if cover.is_empty():
			return Rect2()
		var bounds: Rect2 = cover[0]
		for part: Rect2 in cover:
			bounds = bounds.merge(part)
		return bounds


func _ready() -> void:
	depth = RoomDepth.new()
	depth.name = "Depth"
	depth.painting = JUNCTION_FAR
	depth.mid_painting = JUNCTION_MID
	depth.near_painting = JUNCTION_NEAR
	depth.walkway_y = WALKWAY_Y
	depth.far_drop = FAR_DROP
	depth.near_overhang = NEAR_OVERHANG
	depth.near_column_width = 200.0
	depth.base_color = Color("#0a0e18")
	depth.lamps = lamps
	depth.shaft_lamps = PackedInt32Array([0, 2])
	# The middle ceiling lamp is behind the blast door's cross-wall now: its glow is hidden.
	depth.painted_lamps = PackedInt32Array([1])
	depth.warning_lamps = warning_lamps
	# The room's ends are the entry's and the exit's cross-walls now, not mirrored pipe columns.
	depth.near_left_edge = false
	depth.near_right_edge = false
	add_child(depth)
	recesses = Recesses.new()
	recesses.name = "Recesses"
	recesses.room = self
	recesses.z_index = -2
	add_child(recesses)
	_build_bay()
	breaker_art = RoomDepth.make_prop("BreakerArt", BREAKER_PROP, BREAKER_REGION, BREAKER_SCALE, BREAKER_X)
	vent_art = RoomDepth.make_prop("VentArt", VENT_PROP, VENT_REGION, vent_scale(), (PressureLine.VENT_GRATE_MIN_X + PressureLine.VENT_GRATE_MAX_X) * 0.5)
	valve_art = RoomDepth.make_prop("ValveArt", VALVE_PROP, VALVE_REGION, VALVE_SCALE, VALVE_X)
	arm_panel_art = RoomDepth.make_prop("ArmPanelArt", ARM_PANEL_PROP, ARM_PANEL_REGION, ARM_PANEL_SCALE, ARM_X)
	bolt_panel_art = RoomDepth.make_prop("BoltPanelArt", BOLT_PANEL_PROP, BOLT_PANEL_REGION, BOLT_PANEL_SCALE, BOLT_PANEL_X)
	_build_entry()
	_build_exit()
	for prop: Sprite2D in [breaker_art, vent_art, valve_art, arm_panel_art, bolt_panel_art]:
		# One step under this node's own drawing, so the lights and readouts drawn in _draw() sit on the art.
		prop.z_index = -1
		add_child(prop)
		floor_reflections.append(FloorReflection.attach(prop))
	# Only the wheel turns: a disc cut from the same image, over the painted wheel.
	valve_wheel = Sprite2D.new()
	valve_wheel.name = "ValveWheel"
	valve_wheel.texture = VALVE_PROP
	valve_wheel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	valve_wheel.region_enabled = true
	valve_wheel.region_rect = Rect2(VALVE_WHEEL_CENTRE - Vector2.ONE * VALVE_WHEEL_RADIUS, Vector2.ONE * VALVE_WHEEL_RADIUS * 2.0)
	valve_wheel.scale = Vector2.ONE * VALVE_SCALE
	valve_wheel.position = prop_point(valve_art, VALVE_WHEEL_CENTRE)
	valve_wheel.z_index = -1
	var mask: Shader = Shader.new()
	mask.code = WHEEL_MASK
	var wheel_material: ShaderMaterial = ShaderMaterial.new()
	wheel_material.shader = mask
	wheel_material.set_shader_parameter("centre", VALVE_WHEEL_CENTRE / VALVE_PROP.get_size())
	wheel_material.set_shader_parameter("radius", VALVE_WHEEL_RADIUS / VALVE_PROP.get_size().x)
	valve_wheel.material = wheel_material
	add_child(valve_wheel)
	breaker_glow = RoomDepth.make_glow(AMBER, Vector2(64.0, 30.0), 0.5)
	breaker_glow.name = "BreakerGlow"
	breaker_glow.position = BREAKER_LIGHT.get_center()
	# Station lights, glows, plates and captions sit at this node's own depth (z 1), under the actors
	# (Main.ACTOR_Z): someone standing at a machine is always drawn in front of all of it.
	breaker_glow.z_index = 0
	add_child(breaker_glow)
	vent_glow = RoomDepth.make_glow(AMBER, VENT_GLOW_SIZE, 0.0)
	vent_glow.name = "VentGlow"
	vent_glow.position = Vector2(VENT_X, FLOOR_Y - 6.0)
	vent_glow.z_index = 0
	add_child(vent_glow)
	_build_door()
	_build_particles()
	# The hurtbox is the grate: a body touching it is on the vent (PressureLine.is_on_vent).
	# The door blast has no hurtbox; main.gd decides it from PressureLine.is_in_blast alone.
	vent_hazard = Hazard.make("VentHazard", Rect2(PressureLine.VENT_GRATE_MIN_X, 380.0, PressureLine.VENT_GRATE_MAX_X - PressureLine.VENT_GRATE_MIN_X, 60.0), VENT_REASON)
	add_child(vent_hazard)
	label_plate = StyleBoxFlat.new()
	label_plate.bg_color = LABEL_PLATE
	label_plate.border_color = LABEL_PLATE_EDGE
	label_plate.set_border_width_all(1)
	label_plate.set_corner_radius_all(2)
	label_plate.content_margin_left = 5.0
	label_plate.content_margin_right = 5.0
	label_plate.content_margin_top = 0.0
	label_plate.content_margin_bottom = 0.0
	breaker_label = _add_station_label("OVERLOAD BREAKER", BREAKER_X - BREAKER_LABEL_SHIFT, Color("#b0d1de"))
	# In the row above the grate, where nobody standing on the floor covers it.
	vent_label = _add_station_label(VENT_LABEL, VENT_X - VENT_LABEL_SHIFT, Color("#8fa6b2"))
	# A little left of the wheel so its longest text ends before the door.
	valve_label = _add_station_label("VALVE", VALVE_X - VALVE_LABEL_SHIFT, Color("#b0d1de"))
	# A placard over the doorway's head, hung in front of the near column (above head height).
	door_label = _add_station_label("SEALED DOOR", DOOR_LABEL_X, Color("#ffc7c7"))
	door_label.z_index = DOOR_FRONT_Z + 1
	arm_label = _add_station_label("TANK RELEASE", ARM_X + ARM_LABEL_SHIFT, Color("#b0d1de"))
	# Over the landed tank, shown only once it lies on the sentry.
	tank_label = _add_station_label("TANK DOWN", DropArm.MARK_X, Color("#8fa6b2"))
	line_caption = Label.new()
	line_caption.name = "LineCaption"
	line_caption.text = LINE_CAPTION
	line_caption.add_theme_font_size_override("font_size", LINE_CAPTION_FONT_SIZE)
	line_caption.add_theme_color_override("font_color", Color("#b0d1de"))
	line_caption.add_theme_stylebox_override("normal", label_plate)
	line_caption.z_index = 0
	add_child(line_caption)
	line_caption.size = line_caption.get_combined_minimum_size()
	# Just left of the dial, level with it.
	var dial: Vector2 = prop_point(valve_art, VALVE_DIAL_CENTRE)
	line_caption.position = Vector2(dial.x - VALVE_DIAL_RADIUS * VALVE_SCALE - 2.0 - line_caption.size.x, dial.y - line_caption.size.y * 0.5)
	# Over the bolt panel, beside the exit door, so both read as one exit.
	hatch_label = _add_station_label("EXIT LOCKED", EXIT_LABEL_X, Color("#8fa6b2"))
	_build_lane()
	refresh_state()


## The relief vent is drawn exactly as wide as its grate's hurtbox (PressureLine.VENT_GRATE_*), so
## what is drawn is what hurts.
static func vent_scale() -> float:
	return (PressureLine.VENT_GRATE_MAX_X - PressureLine.VENT_GRATE_MIN_X) / VENT_REGION.size.x


## Where [param source] (a pixel of [param prop]'s image) is in this room.
static func prop_point(prop: Sprite2D, source: Vector2) -> Vector2:
	return prop.position + (source - prop.region_rect.get_center()) * prop.scale


## [param source] (a rectangle of [param prop]'s image) in this room.
static func prop_rect(prop: Sprite2D, source: Rect2) -> Rect2:
	return Rect2(prop_point(prop, source.position), source.size * prop.scale)


## The door: a 56x132 body on the floor layer whose face stops the engineer just short of the shut
## leaf, and the blast door's pieces from JunctionDoorLayout; at the blast the leaf breaks, then the
## doorway stands empty on the lane and the leaf lies thrown beyond it.
func _build_door() -> void:
	# Off until the junction is the room in play (see set_active).
	door_shape = RoomDepth.door_body(self, "Door", Vector2(DOOR_X, FLOOR_Y - DOOR_HEIGHT * 0.5), Vector2(DOOR_WIDTH, DOOR_HEIGHT))
	door_body = door_shape.get_parent() as StaticBody2D
	door_hole = _door_piece("DoorHole", JunctionDoorLayout.HOLE_REGION, JunctionDoorLayout.HOLE_AT, JunctionDoorLayout.HOLE_SCALE, DOOR_Z)
	door_leaf = _door_piece("DoorLeaf", JunctionDoorLayout.LEAF_REGION, JunctionDoorLayout.LEAF_AT, JunctionDoorLayout.LEAF_SCALE, DOOR_Z)
	door_leaf_breaking = _door_piece("DoorLeafBreaking", JunctionDoorLayout.LEAFBREAK_REGION, JunctionDoorLayout.LEAFBREAK_AT, JunctionDoorLayout.LEAFBREAK_SCALE, DOOR_Z)
	door_wall = _door_piece("DoorWall", JunctionDoorLayout.WALL_REGION, JunctionDoorLayout.WALL_AT, JunctionDoorLayout.WALL_SCALE, DOOR_Z)
	door_cracks = _door_piece("DoorCracks", JunctionDoorLayout.CRACKS_REGION, JunctionDoorLayout.CRACKS_AT, JunctionDoorLayout.CRACKS_SCALE, DOOR_Z)
	door_damage = _door_piece("DoorDamage", JunctionDoorLayout.DAMAGE_REGION, JunctionDoorLayout.DAMAGE_AT, JunctionDoorLayout.DAMAGE_SCALE, DOOR_Z)
	# The lamp's glass draws under the column, so the column's guard bars lie over it.
	door_lamp = _door_piece("DoorLampLens", JunctionDoorLayout.LENS_REGION, JunctionDoorLayout.LENS_AT, JunctionDoorLayout.LENS_SCALE, DOOR_FRONT_Z)
	door_column = _door_piece("DoorColumn", JunctionDoorLayout.COLUMN_REGION, JunctionDoorLayout.COLUMN_AT, JunctionDoorLayout.COLUMN_SCALE, DOOR_FRONT_Z)
	door_stub = _door_piece("DoorStub", JunctionDoorLayout.STUB_REGION, JunctionDoorLayout.STUB_AT, JunctionDoorLayout.STUB_SCALE, DOOR_FRONT_Z)
	door_leaf_down = _door_piece("DoorLeafDown", JunctionDoorLayout.LYING_REGION, JunctionDoorLayout.LYING_AT, JunctionDoorLayout.LYING_SCALE, DOOR_FRONT_Z)
	door_lamp_glow = RoomDepth.make_glow(LAMP_SHUT, Vector2(16.0, 16.0), 0.45)
	door_lamp_glow.name = "DoorLampGlow"
	door_lamp_glow.position = JunctionDoorLayout.LAMP_CENTRE
	door_lamp_glow.z_index = DOOR_FRONT_Z
	add_child(door_lamp_glow)
	_show_door()


## One piece of the blast door, cut from JunctionDoorLayout's atlas and placed by its world top-left.
func _door_piece(piece_name: String, region: Rect2, top_left: Vector2, piece_scale: float, z: int) -> Sprite2D:
	var sprite: Sprite2D = RoomDepth.cut(JunctionDoorLayout.ATLAS, region, piece_scale, piece_name, top_left)
	sprite.z_index = z
	add_child(sprite)
	return sprite


## The entry door's pieces in one AtlasMesh right after the mid plate (under the props and the actors):
## the wall with its doorway transparent (the passage in the far plate shows through), the leaf on its
## hinges with the closer's arm, the lamp's glass, then the near column and stub over them.
func _build_entry() -> void:
	entry_leaf = SwingLeaf.new(ENTRY_ATLAS, ENTRY_LEAF_ROOM_REGION, ENTRY_LEAF_OUT_REGION, ENTRY_LEAF_EDGE_REGION, ENTRY_HINGE, ENTRY_AXIS_U, ENTRY_AXIS_N, ENTRY_LEAF_LIGHTS)
	entry_leaf.fill = ENTRY_LEAF_FILL
	entry_leaf.name = "EntryLeaf"
	entry_leaf.vpx = EXIT_VPX
	entry_leaf.horizon = EXIT_HORIZON
	entry_leaf.arm_region = ENTRY_ARM_REGION
	add_child(entry_leaf)
	entry_mesh = AtlasMesh.new(ENTRY_ATLAS)
	entry_mesh.name = "EntryDoor"
	entry_mesh.z_as_relative = false
	entry_mesh.z_index = RoomDepth.Z_MID
	entry_mesh.add_quad(ENTRY_WALL_REGION, ENTRY_WALL_AT, 0.5)
	entry_mesh.add_leaf(entry_leaf)
	entry_lamp_quad = entry_mesh.add_quad(ENTRY_LENS_REGION, ENTRY_LAMP - ENTRY_LENS_REGION.size * 0.25 * 0.5, 0.25, ENTRY_LAMP_SHUT)
	entry_mesh.add_quad(ENTRY_FRONT_REGION, ENTRY_FRONT_AT, 0.5)
	depth.add_child(entry_mesh)
	# The shut leaf stops whoever walks into it: 16 px deep from its junction face, as tall as a door.
	entry_door_shape = SwingLeaf.make_body(self, "EntryDoorBody", ENTRY_DOOR_X, -1.0)


## The entry's status lamp: amber while its closer brings the leaf shut, red once it latches.
func set_entry_lamp(color: Color) -> void:
	entry_mesh.set_color(entry_lamp_quad, color)


func entry_lamp_color() -> Color:
	return entry_mesh.get_color(entry_lamp_quad)


## Coming in from the service line passage: the entry stands open behind the engineer and its closer
## brings it shut (as the Records entry's does).
func close_entry_behind() -> void:
	if entry_tween != null and entry_tween.is_running():
		entry_tween.kill()
	entry_leaf.open = 1.0
	set_entry_lamp(ENTRY_LAMP_MOVING)
	entry_tween = create_tween()
	entry_tween.tween_interval(ENTRY_CLOSE_DELAY)
	entry_tween.tween_property(entry_leaf, "open", 0.0, ENTRY_CLOSE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	entry_tween.tween_callback(func() -> void: set_entry_lamp(ENTRY_LAMP_SHUT))


## The release bay draws after Recesses (so its right post lies over the bolt feed); it is made once
## Recesses exists.
func _build_bay() -> void:
	release_bay = _door_piece("ReleaseBay", JunctionDoorLayout.ALCOVE_REGION, JunctionDoorLayout.ALCOVE_AT, JunctionDoorLayout.ALCOVE_SCALE, BAY_Z)


## The exit door's pieces, in drawing order. The passage, the leaf, the wall behind the walk line and
## the lamp's lens go in before the props, one step under this node's drawing like them (the leaf is
## always behind the walk line where it shows); the deck and the wall in front of the walk line go over
## the actors with the blast door's column (DOOR_FRONT_Z). Its lens and leaf follow the bolt.
func _build_exit() -> void:
	exit_beyond = _exit_piece("ExitBeyond", EXIT_BEYOND, EXIT_BEYOND_AT, -1)
	_exit_edge_bleed(exit_beyond)
	exit_leaf = _exit_piece("ExitLeaf", EXIT_LEAF, Vector2.ZERO, -1)
	exit_leaf.offset = -EXIT_LEAF_ANCHOR
	exit_back = _exit_piece("ExitBack", EXIT_BACK, EXIT_BACK_AT, -1)
	exit_lens = _exit_piece("ExitLens", EXIT_LENS, EXIT_LENS_AT, -1)
	exit_deck = _exit_piece("ExitDeck", EXIT_DECK, EXIT_DECK_AT, DOOR_FRONT_Z)
	var bleed_rows: float = EXIT_DECK_BLEED / EXIT_ATLAS_SCALE
	exit_deck_bleed = _exit_piece("ExitDeckBleed", Rect2(EXIT_DECK.position.x, EXIT_DECK.end.y - EXIT_SEAM_TRIM - bleed_rows, EXIT_DECK.size.x, bleed_rows), EXIT_DECK_AT + Vector2(0.0, (EXIT_DECK.size.y - EXIT_SEAM_TRIM) * EXIT_ATLAS_SCALE), DOOR_FRONT_Z)
	exit_deck_bleed.flip_v = true
	_exit_edge_bleed(exit_deck)
	_exit_edge_bleed(exit_deck_bleed).flip_v = true
	exit_front = _exit_piece("ExitFront", EXIT_FRONT, EXIT_FRONT_AT, DOOR_FRONT_Z)
	_sync_hatch()


## [param piece]'s last EXIT_EDGE_BLEED world px (short of its edge texels), mirrored on to the right of
## it at its depth, overlapping its edge.
func _exit_edge_bleed(piece: Sprite2D) -> Sprite2D:
	var columns: float = EXIT_EDGE_BLEED / EXIT_ATLAS_SCALE
	var region: Rect2 = piece.region_rect
	var strip: Sprite2D = _exit_piece(piece.name + "EdgeBleed", Rect2(region.end.x - EXIT_SEAM_TRIM - columns, region.position.y, columns, region.size.y), piece.position + Vector2((region.size.x - EXIT_SEAM_TRIM) * EXIT_ATLAS_SCALE, 0.0), piece.z_index)
	strip.flip_h = true
	return strip


## One piece of the exit door, cut from EXIT_ATLAS at EXIT_ATLAS_SCALE and placed by its world top-left
## [param at], drawn at [param z]; added now, so the build order sets the drawing order.
func _exit_piece(piece_name: String, region: Rect2, at: Vector2, z: int) -> Sprite2D:
	var piece: Sprite2D = RoomDepth.cut(EXIT_ATLAS, region, EXIT_ATLAS_SCALE, piece_name, at)
	piece.z_index = z
	add_child(piece)
	return piece


## Where the leaf's leading-edge bottom corner stands with the door [param open] (0 shut, 1 open), and
## the leaf's scale there (x, y: the point; z: the scale against the shut leaf's). The leaf slides along
## the wall, back into the pocket, so it moves left and away from the camera (smaller). The point is
## DoorCamera's projection with the junction's vanishing point; x_m and z_m stay 64-bit floats up to it,
## so the anchor is bit for bit the one the retyped formula gave before DoorCamera existed.
static func exit_leaf_anchor(open: float) -> Vector3:
	var a: float = deg_to_rad(EXIT_WALL_ANGLE)
	var s: float = lerpf(EXIT_LEAD_SHUT_S, EXIT_LEAD_OPEN_S, clampf(open, 0.0, 1.0))
	var x_m: float = EXIT_DOOR_X / DoorCamera.PX_PER_M - s * sin(a) + EXIT_LEAF_N * cos(a)
	var z_m: float = s * cos(a) + EXIT_LEAF_N * sin(a)
	var z_shut: float = EXIT_LEAD_SHUT_S * cos(a) + EXIT_LEAF_N * sin(a)
	var p: Vector2 = DoorCamera.project(x_m, 0.0, z_m, EXIT_VPX, EXIT_HORIZON)
	return Vector3(p.x, p.y, DoorCamera.depth_scale(z_m) * (DoorCamera.D0 + z_shut) / DoorCamera.D0)


func _build_particles() -> void:
	vent_steam = FxPresets.steam()
	vent_steam.name = "VentSteam"
	vent_steam.position = Vector2(VENT_X, FLOOR_Y - 8.0)
	vent_steam.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	vent_steam.emission_rect_extents = Vector2((PressureLine.VENT_GRATE_MAX_X - PressureLine.VENT_GRATE_MIN_X) * 0.5 - 6.0, 2.0)
	# Behind the vent's grate (one step under the props) and the actors: the column rises from inside
	# the grate, which stays drawn over it, so the grate the card names reads through the steam.
	vent_steam.z_index = VENT_STEAM_Z
	add_child(vent_steam)
	vent_puff = FxPresets.dust_burst()
	vent_puff.name = "VentPuff"
	vent_puff.position = vent_steam.position
	# Translucent and thin enough that the engineer, the grate and the breaker read through it.
	vent_puff.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	vent_puff.emission_rect_extents = vent_steam.emission_rect_extents
	vent_puff.color = Color(FxPresets.STEAM, 0.3)
	vent_puff.initial_velocity_min = 160.0
	vent_puff.initial_velocity_max = 260.0
	vent_puff.spread = 30.0
	vent_puff.amount = 16
	# Like the column: out of the grate, behind it and the engineer it knocks down.
	vent_puff.z_index = VENT_STEAM_Z
	add_child(vent_puff)
	# Steel tearing at the latch jamb, where the bolts shear: a few short, hard white-hot streaks thrown
	# into the lane, falling (FxPresets.streaks), not soft discs.
	blast_sparks = FxPresets.streaks(14)
	blast_sparks.name = "BlastSparks"
	blast_sparks.position = Vector2(JunctionDoorLayout.FAR_JAMB_FOOT.x + 2.0, FLOOR_Y - 52.0)
	blast_sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	blast_sparks.emission_rect_extents = Vector2(2.0, 46.0)
	blast_sparks.direction = Vector2(1.0, -0.25)
	blast_sparks.spread = 40.0
	blast_sparks.z_index = 3
	add_child(blast_sparks)
	# Concrete spalled off round the frame: hard chips thrown through the doorway into the lane, tumbling
	# and falling to the deck (FxPresets.chips).
	blast_debris = FxPresets.chips(Color(0.42, 0.43, 0.45), 20)
	blast_debris.name = "BlastDebris"
	blast_debris.position = Vector2(DOOR_X, FLOOR_Y - 60.0)
	blast_debris.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	blast_debris.emission_rect_extents = Vector2(8.0, 55.0)
	blast_debris.z_index = 3
	add_child(blast_debris)
	# The blast's dust driven through the doorway into the lane: a fast grey jet out of the opening that
	# slows and spreads (FxPresets.dust_jet), not a flat sheet on the deck.
	blast_dust = FxPresets.dust_jet(Color(0.56, 0.58, 0.6, 0.42), 26)
	blast_dust.name = "BlastDust"
	blast_dust.position = Vector2(DOOR_X - 2.0, FLOOR_Y - 46.0)
	blast_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	blast_dust.emission_rect_extents = Vector2(6.0, 42.0)
	blast_dust.z_index = 3
	add_child(blast_dust)
	# Fix round 4 (review r4 C2): the dust the thrown leaf raises off the wet deck where it lands, low and
	# spreading along it, in front of the lying leaf.
	landing_dust = FxPresets.dust_jet(Color(0.5, 0.53, 0.56, 0.38), 18)
	landing_dust.name = "LandingDust"
	landing_dust.position = DOOR_FLIGHT_TO + Vector2(0.0, 20.0)
	landing_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	landing_dust.emission_rect_extents = Vector2(66.0, 4.0)
	landing_dust.direction = Vector2(0.0, -1.0)
	landing_dust.spread = 75.0
	landing_dust.initial_velocity_min = 50.0
	landing_dust.initial_velocity_max = 130.0
	landing_dust.damping_min = 120.0
	landing_dust.damping_max = 180.0
	landing_dust.z_index = DOOR_FRONT_Z + 1
	add_child(landing_dust)


## The sentry, the tank over the mark and the lane's hazards and bursts. The sentry is added before
## the tank so a landed tank draws over the machine it came down on.
func _build_lane() -> void:
	sentry = Sentry.new()
	sentry.name = "Sentry"
	sentry.z_index = 1
	add_child(sentry)
	floor_reflections.append_array(sentry.floor_reflections)
	panel_front = PanelFront.new()
	panel_front.name = "BoltPanelFront"
	panel_front.room = self
	panel_front.z_index = sentry.z_index
	add_child(panel_front)
	tank = TankSprite.new()
	tank.name = "Tank"
	tank.texture = TANK_PROP
	tank.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tank.scale = Vector2.ONE * TANK_ART_SCALE
	tank.position = Vector2(DropArm.MARK_X, TANK_REST_Y)
	tank.z_index = 1
	add_child(tank)
	# The arm stays where the tank-arm image put it relative to the tank: centred over the mark,
	# its shackle on the tank's cut line.
	arm_art = Sprite2D.new()
	arm_art.name = "ArmArt"
	arm_art.texture = ARM_PROP
	arm_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	arm_art.region_enabled = true
	arm_art.region_rect = ARM_REGION
	arm_art.scale = Vector2.ONE * TANK_ART_SCALE
	arm_art.position = tank.position + (ARM_REGION.get_center() - TANK_REGION.get_center()) * TANK_ART_SCALE
	arm_rest_y = arm_art.position.y
	arm_art.z_index = 1
	add_child(arm_art)
	# The cloud's hurtbox is the cloud: DropArm.CLOUD_HALF_WIDTH either side of the mark, floor to head height.
	cloud_hazard = Hazard.make("CloudHazard", Rect2(DropArm.MARK_X - DropArm.CLOUD_HALF_WIDTH, 360.0, DropArm.CLOUD_HALF_WIDTH * 2.0, 80.0), CLOUD_REASON)
	add_child(cloud_hazard)
	coolant_cloud = FxPresets.steam()
	coolant_cloud.name = "CoolantCloud"
	coolant_cloud.position = Vector2(DropArm.MARK_X, FLOOR_Y - 6.0)
	coolant_cloud.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	coolant_cloud.emission_rect_extents = Vector2(DropArm.CLOUD_HALF_WIDTH - 8.0, 4.0)
	coolant_cloud.initial_velocity_min = 20.0
	coolant_cloud.initial_velocity_max = 60.0
	coolant_cloud.spread = 60.0
	coolant_cloud.scale_amount_min = 10.0
	coolant_cloud.scale_amount_max = 18.0
	coolant_cloud.amount = 24
	coolant_cloud.color = Color(COOLANT, 0.16)
	# Behind the actors and the sentry, so the vapour never hides who is in it.
	coolant_cloud.z_index = 0
	add_child(coolant_cloud)
	coolant_burst = FxPresets.dust_burst()
	coolant_burst.name = "CoolantBurst"
	coolant_burst.position = Vector2(DropArm.MARK_X, FLOOR_Y - 10.0)
	coolant_burst.color = Color(COOLANT, 0.35)
	coolant_burst.initial_velocity_min = 110.0
	coolant_burst.initial_velocity_max = 220.0
	coolant_burst.amount = 22
	coolant_burst.z_index = 3
	add_child(coolant_burst)
	hit_sparks = FxPresets.sparks(FxPresets.SPARK_CYAN)
	hit_sparks.name = "HitSparks"
	hit_sparks.position = Vector2(DropArm.MARK_X, FLOOR_Y - 30.0)
	hit_sparks.amount = 36
	hit_sparks.spread = 100.0
	hit_sparks.z_index = 3
	add_child(hit_sparks)
	# The bolt's short in the panel: hot streaks spat out of the panel's face, falling (FxPresets.streaks).
	bolt_sparks = FxPresets.streaks(22)
	bolt_sparks.name = "BoltSparks"
	bolt_sparks.position = prop_rect(bolt_panel_art, BOLT_PANEL_LIGHT).get_center()
	bolt_sparks.spread = 75.0
	bolt_sparks.z_index = 3
	add_child(bolt_sparks)


## A station name on its plate, centred on [param center_x] in the label row. It draws over the
## door's cross-wall and under the actors.
func _add_station_label(caption: String, center_x: float, tint: Color) -> Label:
	var label: Label = Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_stylebox_override("normal", label_plate)
	label.z_index = 0
	label.set_meta(&"center_x", center_x)
	add_child(label)
	station_labels.append(label)
	_fit_label(label)
	return label


## Shrinks [param label]'s plate to its text and centres it on its station again.
func _fit_label(label: Label) -> void:
	label.size = Vector2.ZERO
	label.size = label.get_combined_minimum_size()
	label.position = Vector2(float(label.get_meta(&"center_x")) - label.size.x * 0.5, LABEL_Y)


## A plate the edge of the view cuts would show part of a name: it fades out as it reaches the edge.
## Once the junction is cleared the closing shot's camera stands still, so a plate caught in that fade
## would hang there half see-through for the whole walk-out (review r5: DOOR DOWN at the left edge on
## a phone); it is hidden instead.
func _process(delta: float) -> void:
	if not visible:
		return
	fade_at_view_edge(station_labels, get_viewport())
	if junction_cleared:
		for label: Label in station_labels:
			if label.modulate.a < 1.0:
				label.modulate.a = 0.0
	_advance_flicker(delta)


## The lamp of [param station] (&"breaker", &"valve", &"door", &"release" or &"bolt") goes dark and
## comes back [param times] times, from this frame.
func flicker(station: StringName, times: int) -> void:
	var was_door: bool = flicker_station == &"door"
	flicker_station = station
	flicker_elapsed = 0.0
	flicker_times = times
	if was_door and station != &"door":
		_sync_lamp()
	_sync_flicker()


## How lit [param station]'s lamp is this frame: 0 dark in a flicker, 1 otherwise.
func lamp_level(station: StringName) -> float:
	if station != flicker_station or flicker_times <= 0:
		return 1.0
	if reduce_motion:
		return 0.0 if flicker_elapsed < FLICKER_STEP_SECONDS * 2.0 else 1.0
	if flicker_elapsed >= FLICKER_STEP_SECONDS * 2.0 * flicker_times:
		return 1.0
	return 0.0 if fmod(flicker_elapsed, FLICKER_STEP_SECONDS * 2.0) < FLICKER_STEP_SECONDS else 1.0


## True while [param station]'s lamp is in a flicker (dark or between dark steps).
func flickering(station: StringName) -> bool:
	if station != flicker_station or flicker_times <= 0:
		return false
	return flicker_elapsed < FLICKER_STEP_SECONDS * 2.0 * (1 if reduce_motion else flicker_times)


## The breaker's lamp pulses for [param seconds] (hint ladder T1, while WOLF looks at it).
func pulse_breaker(seconds: float) -> void:
	breaker_pulse_remaining = seconds
	breaker_pulse_elapsed = 0.0
	queue_redraw()


## How far the breaker's lamp is pulsed up this frame, 0..1 (0 when it is not pulsing).
func breaker_pulse_level() -> float:
	if breaker_pulse_remaining <= 0.0:
		return 0.0
	if reduce_motion:
		return 1.0
	return 0.5 - 0.5 * cos(breaker_pulse_elapsed * BREAKER_PULSE_HZ * TAU)


func _advance_flicker(delta: float) -> void:
	if breaker_pulse_remaining > 0.0:
		breaker_pulse_remaining = maxf(breaker_pulse_remaining - delta, 0.0)
		breaker_pulse_elapsed += delta
		_sync_breaker_glow()
		queue_redraw()
	if flicker_times <= 0:
		return
	flicker_elapsed += delta
	if not flickering(flicker_station):
		var station: StringName = flicker_station
		flicker_times = 0
		flicker_station = &""
		if station == &"door":
			_sync_lamp()
		_sync_breaker_glow()
		_sync_exit_lamp()
		queue_redraw()
		return
	_sync_flicker()


## Shows the flicker's current step: the drawn lamps follow lamp_level when they draw; the glows, the
## door's status lamp and the exit door's lens are nodes, set here.
func _sync_flicker() -> void:
	if flicker_station == &"door" and not door_blown and not (line_state in [&"charged", &"fuse"]):
		if _lamp_tween != null and _lamp_tween.is_valid():
			_lamp_tween.kill()
		var lit: float = lamp_level(&"door")
		_set_lamp(AMBER if lit > 0.0 else LAMP_DEAD, SEAM_FLICKER_ALPHA * lit)
	_sync_exit_lamp()
	_sync_breaker_glow()
	queue_redraw()


## The breaker's glow: as its phase sets it (refresh_state), dark in a flicker, brighter in a pulse.
func _sync_breaker_glow() -> void:
	var lit: bool = line_state in [&"building", &"charged", &"fuse"] and not door_blown
	var glow: Color = Color(_breaker_light_color(), 0.75 if lit else 0.4)
	glow.a = lerpf(glow.a, 1.0, breaker_pulse_level()) * lamp_level(&"breaker")
	breaker_glow.modulate = glow


## Fades each of [param labels] out over LABEL_EDGE_FADE px as it reaches the edge of [param viewport]'s
## view, so a name the edge would cut never shows in part. Every room's station names and the corridor's
## bypass plates use it; a label sized to its text fades by its text.
static func fade_at_view_edge(labels: Array, viewport: Viewport) -> void:
	var view: Rect2 = viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	for label: Control in labels:
		label.modulate.a = edge_alpha(label.get_global_rect(), view)


## How opaque a plate covering [param rect] is in [param view]: 1 well inside, falling to 0 as either
## end reaches the view's edge.
static func edge_alpha(rect: Rect2, view: Rect2) -> float:
	var margin: float = minf(rect.position.x - view.position.x, view.end.x - rect.end.x)
	return clampf(margin / LABEL_EDGE_FADE, 0.0, 1.0)


## Enables the door body and hazards only while this is the room in play, so the junction's
## collision never leaks into the corridor or Records, which share the same coordinates. Its floor
## reflections mirror only while it is in play; its bursts, steam and cloud are stopped by
## reset_transient, which the parent runs with every sync.
func set_active(active: bool) -> void:
	FloorReflection.set_all_active(floor_reflections, active)
	door_shape.set_deferred("disabled", not active or door_blown)
	entry_door_shape.set_deferred("disabled", not active)
	vent_hazard.armed = false
	vent_hazard.set_deferred("monitoring", active)
	cloud_hazard.armed = false
	cloud_hazard.set_deferred("monitoring", active)


## Copies the live pressure line in; the gauge needle, steam, door lamp and labels all follow it.
func sync_line(line: PressureLine) -> void:
	var previous_turns: int = turns
	var previous_state: StringName = line_state
	line_state = line.state
	gauge = line.gauge
	turns = line.turns
	fuse_remaining = line.fuse_remaining
	if line_state == &"building":
		display_gauge = gauge
		gauge_tripped = false
		gauge_hold = 0.0
	elif line_state == &"tripped" and previous_state == &"building":
		# The vent let go at the top of the gauge: the needle stays there, red, while the grate hurts.
		display_gauge = 1.0
		gauge_tripped = true
		gauge_hold = HAZARD_SECONDS
	elif not gauge_tripped:
		display_gauge = gauge
	if turns != previous_turns:
		_turn_wheel(turns)
	# The VALVE label counts the turns, so a crank refreshes it as well as a phase change.
	if line_state != previous_state or turns != previous_turns:
		refresh_state()
	var building: bool = line_state == &"building"
	# Steam only near the top of the gauge, thickening toward the peak.
	var steam: float = inverse_lerp(PressureLine.STEAM_GAUGE, 1.0, gauge)
	vent_steam.emitting = building and steam >= 0.0 and visible
	vent_steam.initial_velocity_max = lerpf(60.0, 220.0, clampf(steam, 0.0, 1.0))
	vent_steam.scale_amount_max = lerpf(6.0, 16.0, clampf(steam, 0.0, 1.0))
	vent_steam.modulate.a = lerpf(0.45, 1.0, clampf(steam, 0.0, 1.0))
	_sync_vent_glow()
	_check_redraw()


## Advances the needle's fall after the vent lets go; the parent calls it every junction frame, so it
## holds still through a knockdown, when nothing does.
func advance_display(delta: float) -> void:
	if not gauge_tripped:
		return
	if gauge_hold > 0.0:
		gauge_hold = maxf(gauge_hold - delta, 0.0)
		return
	display_gauge = move_toward(display_gauge, gauge, delta / GAUGE_FALL_SECONDS)
	if display_gauge <= gauge:
		gauge_tripped = false
	_check_redraw()


## The grate glows as the line builds, hotter toward the gauge's peak, flashing red through the hard
## warning, and red once it has let go.
func _sync_vent_glow() -> void:
	match line_state:
		&"building":
			if gauge >= PressureLine.WARN_GAUGE:
				# The flash follows the gauge itself, so it runs at the same rate whatever the frame rate.
				var flash: float = 1.0 if reduce_motion else 0.5 + 0.5 * cos(gauge * PressureLine.BUILD_SECONDS * VENT_FLASH_HZ * TAU)
				vent_glow.modulate = Color(SEAM_RED, lerpf(0.35, 0.95, flash))
			else:
				vent_glow.modulate = Color(AMBER.lerp(SEAM_RED, gauge * gauge), 0.12 + 0.55 * gauge)
		&"tripped":
			vent_glow.modulate = Color(SEAM_RED, 0.35)
		_:
			vent_glow.modulate = Color(AMBER, 0.0)


## Copies the arm in: the tank's height, the cloud and its hurtbox follow DropArm's state.
func sync_arm(arm: DropArm) -> void:
	var previous_state: StringName = arm_state
	var previous_on_floor: bool = tank_on_floor
	arm_state = arm.state
	tank_drop = arm.drop_amount()
	tank_on_floor = arm.on_floor()
	# A tank coming down on the sentry stops on its crushed hull, so the wreck shows under it; one that
	# only catches its end (a graze) comes down past it onto the floor.
	var on_sentry: bool = (arm.state == &"landed" or (arm.state == &"falling" and DropArm.is_hit(sentry.target_x))) and tank_rests_on_wreck(sentry.target_x)
	tank.position.y = lerpf(TANK_REST_Y, landed_tank_y(on_sentry), tank_drop)
	var cloud: bool = arm.cloud_active() and visible
	coolant_cloud.emitting = cloud
	if cloud_hazard.armed != cloud:
		cloud_hazard.armed = cloud
	if arm_state != previous_state or tank_on_floor != previous_on_floor:
		refresh_state()
	_check_redraw()


## Copies the exit bolt in; its panel light warms with the charge.
func sync_bolt(state: StringName, charge: float) -> void:
	var changed: bool = state != bolt_state
	bolt_state = state
	bolt_charge = charge
	if changed:
		refresh_state()
	# The exit's status lamp follows the bolt (amber while it charges); the bolt's lights and its feed
	# (Recesses) warm with the charge.
	_sync_exit_lamp()
	_check_redraw()


## The parent syncs the line, the arm and the bolt every junction frame, and most frames nothing drawn
## changes: once per frame, after the frame's syncs, this redraws the room and its Recesses only when
## what they draw differs from what they last drew.
func _check_redraw() -> void:
	if _redraw_check_queued:
		return
	_redraw_check_queued = true
	_redraw_if_changed.call_deferred()


func _redraw_if_changed() -> void:
	_redraw_check_queued = false
	if draw_inputs() != _drawn_inputs:
		queue_redraw()
	if recesses_inputs() != _recesses_drawn_inputs:
		recesses.queue_redraw()


## Every value _draw reads that can change after the room is built.
func draw_inputs() -> Array:
	return [line_state, gauge, display_gauge, gauge_tripped, fuse_remaining, reduce_motion, door_blown, sentry_down, junction_cleared, arm_state, tank_drop, tank_on_floor, tank.position.y, arm_art.position.y, bolt_state, bolt_charge, breaker_pulse_level(), lamp_level(&"breaker"), lamp_level(&"valve"), lamp_level(&"release"), lamp_level(&"bolt"), mark_lit()]


## Every value draw_recesses reads that can change after the room is built.
func recesses_inputs() -> Array:
	return [sentry_down, junction_cleared, bolt_state, bolt_charge]


## How high WOLF's drawn body is lifted with his centre at [param wolf_x] and the live sentry's at
## [param sentry_x]: LEAP_HEIGHT while their bodies could overlap, easing to nothing LEAP_RAMP further
## out.
static func wolf_leap_height(wolf_x: float, sentry_x: float) -> float:
	return LEAP_HEIGHT * (1.0 - smoothstep(LEAP_CLEAR, LEAP_CLEAR + LEAP_RAMP, absf(wolf_x - sentry_x)))


## How high WOLF's drawn body is lifted crossing the crushed tank on the mark with his centre at
## [param wolf_x]: one parabolic arc, TANK_LEAP_HEIGHT over TANK_LEAP_PEAK_X and nothing from
## TANK_LEAP_HALF_SPAN either side of it.
static func wolf_tank_leap_height(wolf_x: float) -> float:
	var along: float = (wolf_x - TANK_LEAP_PEAK_X) / TANK_LEAP_HALF_SPAN
	return TANK_LEAP_HEIGHT * maxf(1.0 - along * along, 0.0)


## How far forward of the walk line WOLF stands (0..1, a fraction of WOLF_STEP_FORWARD) with his centre at
## [param wolf_x]: all the way while his body would overlap the valve's middle, easing back over
## WOLF_STEP_RAMP to nothing, so he walks round the front of the valve.
static func wolf_valve_step(wolf_x: float) -> float:
	return 1.0 - smoothstep(WOLF_STEP_FULL, WOLF_STEP_FULL + WOLF_STEP_RAMP, absf(wolf_x - VALVE_X))


## How far WOLF ducks (px off the top of his drawn body, feet on the floor) with his centre at
## [param wolf_x], facing [param facing] (+1 right), under the hung tank: DUCK_DEPTH while his head is
## under its base, easing to nothing DUCK_RAMP further out.
static func wolf_duck_depth(wolf_x: float, facing: float) -> float:
	var head_x: float = wolf_x + signf(facing) * WOLF_HEAD_X
	return DUCK_DEPTH * (1.0 - smoothstep(DUCK_CLEAR, DUCK_CLEAR + DUCK_RAMP, absf(head_x - DropArm.MARK_X)))


## True when a tank landing on a sentry centred at [param sentry_x] rests on its crushed hull: the
## sentry's middle is inside the brackets, so at least half of the tank's footprint is over the wreck.
## A graze further out (DropArm.HIT_REACH) catches only the wreck's end and the tank stands on the
## floor beside it, over that end.
static func tank_rests_on_wreck(sentry_x: float) -> bool:
	return absf(sentry_x - DropArm.MARK_X) <= DropArm.HIT_RANGE + DropArm.EPSILON


## Where the tank's centre comes to rest: on the floor, or on top of the crushed sentry.
static func landed_tank_y(on_sentry: bool) -> float:
	return FLOOR_Y - TANK_SIZE.y * 0.5 - (Sentry.WRECK_CRUSH_HEIGHT if on_sentry else 0.0)


## The tank came down on the sentry at [param at_x] (the mark): the coolant and spark bursts (fired
## through the impact kit) are moved there and the sentry is crushed into its wreck under the tank.
func tank_hit(at_x: float) -> void:
	sentry_down = true
	coolant_burst.position.x = at_x
	hit_sparks.position.x = at_x
	sentry.keel_over(at_x)
	# The empty arm winches up into its ceiling plate, clear of WOLF bounding over the tank.
	if _arm_tween != null and _arm_tween.is_valid():
		_arm_tween.kill()
	_arm_tween = create_tween()
	_arm_tween.tween_property(self, "arm_parked", 1.0, ARM_PARK_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	refresh_state()


## The tank hit the empty mark: the coolant burst moves there and the tank is dented.
func tank_miss() -> void:
	coolant_burst.position.x = DropArm.MARK_X
	tank.dented = true


## The bolt lets go and the exit door slides open into its pocket (the parent fires the panel's sparks);
## hatch_opened follows once it is open.
func bolt_arc() -> void:
	if _hatch_tween != null and _hatch_tween.is_valid():
		_hatch_tween.kill()
	_hatch_tween = create_tween()
	_hatch_tween.tween_property(self, "hatch_open", 1.0, HATCH_OPEN_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_hatch_tween.tween_callback(refresh_state)
	_hatch_tween.tween_callback(func() -> void: hatch_opened.emit())


## A hold at the valve under way: from its press frame the wheel turns part of the way into its next
## quarter, by [param fraction] (HoldUse.shown_fraction); at 0 (let go) the part turn springs back.
func show_crank(fraction: float) -> void:
	if is_equal_approx(fraction, crank_fraction):
		return
	var released: bool = fraction <= 0.0
	crank_fraction = maxf(fraction, 0.0)
	if _valve_tween != null and _valve_tween.is_valid():
		_valve_tween.kill()
	var target: float = 90.0 * (turns + crank_fraction)
	if released and is_inside_tree():
		_valve_tween = create_tween()
		_valve_tween.tween_property(valve_wheel, "rotation_degrees", target, BypassHandle.SPRING_BACK_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		valve_wheel.rotation_degrees = target


func _turn_wheel(to_turns: int) -> void:
	if _valve_tween != null and _valve_tween.is_valid():
		_valve_tween.kill()
	var target: float = 90.0 * to_turns
	# Mid-hold the quarter just reached is where the wheel is; show_crank adds the next part turn.
	if to_turns == 0 or crank_fraction > 0.0:
		valve_wheel.rotation_degrees = target
		return
	_valve_tween = create_tween()
	_valve_tween.tween_property(valve_wheel, "rotation_degrees", target, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Labels, glows and the door lamp follow the line's phase; the parent calls this after state changes.
func refresh_state() -> void:
	if is_spent():
		# The blast used the line up: the same labels whether it just went or a save brought it back. State
		# words on the plates are plain (USED, LOCKED, READY; P0-7, approved 2026-10-13).
		breaker_label.text = "BREAKER USED"
		breaker_label.add_theme_color_override("font_color", Color("#8fa6b2"))
		valve_label.text = "VALVE USED"
		valve_label.add_theme_color_override("font_color", Color("#8fa6b2"))
	else:
		var armed: bool = line_state != &"idle" and line_state != &"tripped"
		breaker_label.text = "BREAKER TRIPPED" if line_state == &"tripped" else ("BREAKER LIVE" if armed else "OVERLOAD BREAKER")
		breaker_label.add_theme_color_override("font_color", SEAM_RED if line_state == &"tripped" else (Color("#8be3ff") if armed else Color("#b0d1de")))
		valve_label.text = "FUSE LIT" if line_state in [&"charged", &"fuse", &"blown"] else ("VALVE  %d / %d" % [turns, PressureLine.TURNS_NEEDED] if armed else "VALVE")
		valve_label.add_theme_color_override("font_color", GREEN if turns >= PressureLine.TURNS_NEEDED else Color("#b0d1de"))
	_sync_breaker_glow()
	door_label.text = "DOOR DOWN" if door_blown else "SEALED DOOR"
	door_label.add_theme_color_override("font_color", GREEN if door_blown else Color("#ffc7c7"))
	# A missed tank lying on the floor is not being winched yet: the plate says so only once the winch
	# takes it (it stays amber, busy, meanwhile).
	arm_label.text = "RELEASE USED" if sentry_down else ("WINCHING UP" if arm_state == &"rewinding" and not tank_on_floor else "TANK RELEASE")
	tank_label.visible = sentry_down
	arm_label.add_theme_color_override("font_color", Color("#8fa6b2") if sentry_down else (AMBER if arm_state == &"rewinding" else Color("#b0d1de")))
	if junction_cleared or (bolt_state == &"open" and hatch_open >= 1.0):
		hatch_label.text = "EXIT OPEN"
		hatch_label.add_theme_color_override("font_color", GREEN)
	elif bolt_state == &"open":
		# The bolt has dropped but the hatch is still sliding: it says open only once it is.
		hatch_label.text = "EXIT OPENING"
		hatch_label.add_theme_color_override("font_color", AMBER)
	elif sentry_down:
		hatch_label.text = "EXIT READY"
		hatch_label.add_theme_color_override("font_color", AMBER)
	else:
		hatch_label.text = "EXIT LOCKED"
		hatch_label.add_theme_color_override("font_color", Color("#8fa6b2"))
	for label: Label in station_labels:
		_fit_label(label)
	_sync_lamp()
	_sync_vent_glow()
	_sync_exit_lamp()
	queue_redraw()
	recesses.queue_redraw()


## The exit door's status lamp (its live lens) shows the bolt's colour: red shut, amber charging,
## warming through the whine, green open; it goes dark in a refusal's flicker at the bolt panel.
func _sync_exit_lamp() -> void:
	if exit_lens != null:
		exit_lens.modulate = bolt_lamp_color()


## True once the door is down, whether it just went or a save brought it back.
func is_spent() -> bool:
	return door_blown


## The door's status lamp follows the line: red shut, amber while it builds, flashing red and white
## through the fuse (steady red with Reduced Motion), dark once the door is down.
func _sync_lamp() -> void:
	if _lamp_tween != null and _lamp_tween.is_valid():
		_lamp_tween.kill()
	_lamp_tween = null
	if door_blown or line_state == &"blown":
		_set_lamp(LAMP_DEAD, 0.0)
		return
	match line_state:
		&"charged", &"fuse":
			_set_lamp(SEAM_RED, 0.6)
			if reduce_motion:
				return
			_lamp_tween = create_tween().set_loops()
			_lamp_tween.tween_callback(_set_lamp.bind(Color.WHITE, 0.7))
			_lamp_tween.tween_interval(0.12)
			_lamp_tween.tween_callback(_set_lamp.bind(SEAM_RED, 0.6))
			_lamp_tween.tween_interval(0.12)
		&"building":
			_set_lamp(AMBER, 0.5)
		_:
			_set_lamp(LAMP_SHUT, 0.45)


func _set_lamp(color: Color, glow: float) -> void:
	door_lamp.modulate = color
	door_lamp_glow.modulate = Color(color, glow)
	door_lamp_glow.visible = glow > 0.0


## The vent letting go: a steam burst and a short armed window over the grate.
func vent_blows() -> void:
	vent_steam.emitting = false
	vent_puff.restart()
	_arm_hazard(vent_hazard)


## The door going: the leaf breaks under the blast flash, then the doorway stands empty and the leaf
## lies thrown in the lane; sparks, concrete fragments and dust fly, and the blast zone is dangerous
## for a moment.
func door_blast() -> void:
	door_blown = true
	door_breaking = true
	vent_hazard.armed = false
	door_shape.set_deferred("disabled", true)
	blast_sparks.restart()
	blast_debris.restart()
	blast_dust.restart()
	if _door_tween != null and _door_tween.is_valid():
		_door_tween.kill()
	_show_door()
	_door_tween = create_tween()
	_door_tween.tween_interval(DOOR_BREAK_SECONDS)
	_door_tween.tween_callback(func() -> void:
		door_breaking = false
		door_flying = true
		_show_door())
	_door_tween.tween_method(_set_door_flight, 0.0, 1.0, DOOR_FLIGHT_SECONDS)
	_door_tween.tween_callback(func() -> void:
		door_flying = false
		_show_door()
		landing_dust.restart())
	refresh_state()


## The shut leaf until the blast; the breaking leaf and its cracks for a moment; then the empty doorway and
## the damage with the torn leaf in the air, and then lying in the lane. The wall, the bay, the column and the
## stub always show.
func _show_door() -> void:
	var gone: bool = door_blown and not door_breaking
	door_leaf.visible = not door_blown
	door_leaf_breaking.visible = door_blown and (door_breaking or door_flying)
	door_cracks.visible = door_blown and door_breaking
	door_hole.visible = gone
	door_damage.visible = gone
	door_leaf_down.visible = gone and not door_flying
	if not door_flying:
		_set_door_flight(0.0)
	# Fix round 2 (N4): once the leaf has gone, the near column shows what it tore off the hinge jamb (the
	# hinges' frame leaves and sheared pins, the spalled corner and its bars, the arris angle torn loose):
	# the same sprite, another region of the atlas (no new draw call).
	door_column.region_rect = JunctionDoorLayout.COLBLOWN_REGION if door_blown else JunctionDoorLayout.COLUMN_REGION
	door_column.position = JunctionDoorLayout.COLBLOWN_AT if door_blown else JunctionDoorLayout.COLUMN_AT


## The torn leaf [param t] (0..1) along its flight from the doorway to where it lies: carried on by the blast
## and slowed by the air along the lane, up a little and down under gravity, tipping over toward flat and
## growing as it comes nearer the camera; at 0 it stands in its doorway piece's place again.
func _set_door_flight(t: float) -> void:
	door_flight = t
	var leaf: Sprite2D = door_leaf_breaking
	if t <= 0.0:
		leaf.centered = false
		leaf.position = JunctionDoorLayout.LEAFBREAK_AT
		leaf.rotation = 0.0
		leaf.scale = Vector2.ONE * JunctionDoorLayout.LEAFBREAK_SCALE
		leaf.z_index = DOOR_Z
		return
	leaf.centered = true
	var along: float = 1.0 - (1.0 - t) * (1.0 - t)
	leaf.position = Vector2(lerpf(DOOR_FLIGHT_FROM.x, DOOR_FLIGHT_TO.x, along), lerpf(DOOR_FLIGHT_FROM.y, DOOR_FLIGHT_TO.y, t * t) - DOOR_FLIGHT_RISE * 4.0 * t * (1.0 - t))
	leaf.rotation = DOOR_FLIGHT_TURN * pow(t, 1.2)
	leaf.scale = Vector2.ONE * JunctionDoorLayout.LEAFBREAK_SCALE * lerpf(1.0, DOOR_FLIGHT_GROW, t)
	leaf.z_index = DOOR_FRONT_Z + 1 if t >= DOOR_FLIGHT_CLEAR else DOOR_Z


## The exit door's leaf slides back along the wall into its pocket as it opens, over the passage behind.
func _sync_hatch() -> void:
	if exit_leaf == null:
		return
	var anchor: Vector3 = exit_leaf_anchor(hatch_open)
	exit_leaf.position = Vector2(anchor.x, anchor.y)
	exit_leaf.scale = Vector2.ONE * EXIT_ATLAS_SCALE * anchor.z


func _arm_hazard(hazard: Hazard) -> void:
	if _hazard_tween != null and _hazard_tween.is_valid():
		_hazard_tween.kill()
	hazard.armed = true
	_hazard_tween = create_tween()
	_hazard_tween.tween_interval(HAZARD_SECONDS)
	_hazard_tween.tween_callback(func() -> void: hazard.armed = false)


## Back to the state the save describes: no burst, no fuse, the wheel at rest and the door as saved.
func reset_transient() -> void:
	for tween: Tween in [_valve_tween, _lamp_tween, _door_tween, _hazard_tween, _hatch_tween, _arm_tween, entry_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	entry_tween = null
	# The entry stands shut behind them, as a restored save finds it.
	entry_leaf.open = 0.0
	set_entry_lamp(ENTRY_LAMP_SHUT)
	_arm_tween = null
	_valve_tween = null
	_lamp_tween = null
	_door_tween = null
	_hazard_tween = null
	_hatch_tween = null
	flicker_times = 0
	flicker_station = &""
	breaker_pulse_remaining = 0.0
	vent_hazard.armed = false
	cloud_hazard.armed = false
	for burst: CPUParticles2D in [vent_steam, vent_puff, blast_sparks, blast_debris, blast_dust, landing_dust, coolant_cloud, coolant_burst, hit_sparks, bolt_sparks]:
		burst.emitting = false
	# The tank hangs again (or lies on the downed sentry), undented; the hatch is as the save left it.
	tank.dented = false
	door_breaking = false
	door_flying = false
	arm_state = &"landed" if sentry_down else &"hung"
	tank_drop = 1.0 if sentry_down else 0.0
	tank_on_floor = false
	tank.position.y = lerpf(TANK_REST_Y, landed_tank_y(sentry_down), tank_drop)
	# The arm is up in its plate once the tank is down for good, and holds the tank otherwise.
	arm_parked = 1.0 if sentry_down else 0.0
	fuse_remaining = 0.0
	crank_fraction = 0.0
	display_gauge = 0.0
	gauge_hold = 0.0
	gauge_tripped = false
	bolt_state = &"open" if junction_cleared else &"locked"
	bolt_charge = 0.0
	hatch_open = 1.0 if junction_cleared else 0.0
	# A blown door left the wheel at its third quarter; a restored save shows it the same way.
	valve_wheel.rotation_degrees = 90.0 * PressureLine.TURNS_NEEDED if door_blown else 0.0
	_show_door()
	door_shape.set_deferred("disabled", not visible or door_blown)
	line_state = &"idle"
	gauge = 0.0
	turns = 0
	refresh_state()


func _draw() -> void:
	_drawn_inputs = draw_inputs()
	# The plates are the Depth child's layers and the machines are sprites; this draws what they
	# cannot show.
	_draw_gauge()
	_draw_breaker_light()
	_draw_blast_zone()
	_draw_arm_panel_light()
	_draw_arm()
	_draw_floor_mark()
	draw_rect(prop_rect(bolt_panel_art, BOLT_PANEL_LIGHT), bolt_lamp_color())


## What Recesses draws under the props: the release's feed to the exit bolt (the bay itself is painted,
## ReleaseBay, drawn over it, so the feed leaves the bay behind its right post).
func draw_recesses(canvas: CanvasItem) -> void:
	_recesses_drawn_inputs = recesses_inputs()
	_draw_bolt_feed(canvas)


## The feed comes up out of the floor at the exit bolt's panel: a floor gland, a conduit up the wall and
## a cable box the panel's painted cables plug into. Its core is lit only while it carries power to the
## bolt (bolt_feed_color). The TANK RELEASE end needs nothing drawn: the release's own painted pipe runs
## down into its base, and the run between the two is under the floor, clear of the tank and the lane.
## Drawn on [param canvas] (Recesses) under the props, so the panel's painted cables run into the box
## in front of it and the flat code-drawn plates show only round the panel's edge.
func _draw_bolt_feed(canvas: CanvasItem) -> void:
	for mark: Array in bolt_feed_marks():
		canvas.draw_rect(mark[0] as Rect2, mark[1] as Color)


## What _draw_bolt_feed fills, in order, as [rect, colour] pairs, so PanelFront can draw any part of it
## again: the conduit with its sheen and its core, then the cable box and the floor gland, each a steel
## plate with a one-pixel dark rim and a sheen along its top.
func bolt_feed_marks() -> Array:
	var parts: Array[Rect2] = bolt_feed_parts()
	var box: Rect2 = parts[0]
	var conduit: Rect2 = parts[1]
	var gland: Rect2 = parts[2]
	var marks: Array = [
		[conduit, CABLE_SHADOW],
		[Rect2(conduit.position.x + 0.5, conduit.position.y, 1.0, conduit.size.y), CABLE_SHEEN],
		[Rect2(conduit.get_center().x - 0.5, conduit.position.y, 2.0, conduit.size.y), bolt_feed_color()],
	]
	for plate: Rect2 in [box, gland]:
		marks.append([plate, FEED_STEEL])
		marks.append([Rect2(plate.position.x, plate.position.y, plate.size.x, 1.0), CABLE_SHADOW])
		marks.append([Rect2(plate.position.x, plate.end.y - 1.0, plate.size.x, 1.0), CABLE_SHADOW])
		marks.append([Rect2(plate.position.x, plate.position.y + 1.0, 1.0, plate.size.y - 2.0), CABLE_SHADOW])
		marks.append([Rect2(plate.end.x - 1.0, plate.position.y + 1.0, 1.0, plate.size.y - 2.0), CABLE_SHADOW])
		marks.append([Rect2(plate.position.x + 1.0, plate.position.y + 1.0, plate.size.x - 2.0, 1.0), CABLE_SHEEN])
	return marks


## The feed's parts in the room, top to bottom: the cable box over the ends of the bolt panel's left
## cables, the conduit from it down to the floor, and the floor gland it goes into.
func bolt_feed_parts() -> Array[Rect2]:
	var x: float = bolt_feed_x()
	var box: Rect2 = Rect2(x - FEED_BOX.x * 0.5, BOLT_FEED_Y - FEED_BOX.y * 0.5, FEED_BOX.x, FEED_BOX.y)
	var gland: Rect2 = Rect2(x - FEED_GLAND.x * 0.5, FLOOR_Y - FEED_GLAND.y, FEED_GLAND.x, FEED_GLAND.y)
	var conduit: Rect2 = Rect2(x - 2.5, box.end.y, 5.0, gland.position.y - box.end.y)
	return [box, conduit, gland]


## Where the feed comes up: over the bolt panel's left edge, the box taking in the ends of its painted
## cables.
func bolt_feed_x() -> float:
	return prop_point(bolt_panel_art, BOLT_PANEL_REGION.position).x + FEED_BOX.x * 0.5 + 1.0


## The feed's core: dead until the tank is down, then the bolt's own light (amber, warming to white
## through the whine, green once it has dropped).
func bolt_feed_color() -> Color:
	return DIM if not sentry_down and not junction_cleared else bolt_light_color()


## Where the sentry's drawing (Sentry.drawn_rects, widened by a pixel for its soft edges) crosses the
## exit bolt's panel or its feed (bolt_front_rect), as rectangles in this room that do not overlap one
## another: PanelFront draws them there again over the machine and its beam. Empty while the sentry is
## hidden or clear of them.
func bolt_panel_cover() -> Array[Rect2]:
	var cover: Array[Rect2] = []
	if sentry == null or not sentry.is_visible_in_tree():
		return cover
	var panel: Rect2 = bolt_front_rect()
	for part: Rect2 in sentry.drawn_rects():
		var over: Rect2 = part.grow(1.0).intersection(panel)
		if over.has_area():
			cover.append(over)
	return disjoint_rects(cover)


## What stands in front of the sentry's lane at the exit bolt: the panel's box and the bolt's feed (whose
## floor gland reaches a pixel past the panel's left edge).
func bolt_front_rect() -> Rect2:
	var front: Rect2 = prop_rect(bolt_panel_art, BOLT_PANEL_REGION)
	for part: Rect2 in bolt_feed_parts():
		front = front.merge(part)
	return front


## The panel's image and its light, drawn on [param canvas] (PanelFront) inside [param cover] only, the
## light in [param light]; under the image, the bolt's feed (bolt_feed_marks), so the cable box and
## conduit stay in front of the machine with the painted cables over them.
func draw_panel_front(canvas: CanvasItem, cover: Array[Rect2], light: Color) -> void:
	var panel: Rect2 = prop_rect(bolt_panel_art, BOLT_PANEL_REGION)
	var lamp: Rect2 = prop_rect(bolt_panel_art, BOLT_PANEL_LIGHT)
	var marks: Array = bolt_feed_marks()
	for front: Rect2 in cover:
		for mark: Array in marks:
			var clipped: Rect2 = (mark[0] as Rect2).intersection(front)
			if clipped.has_area():
				canvas.draw_rect(clipped, mark[1] as Color)
		var part: Rect2 = front.intersection(panel)
		if not part.has_area():
			continue
		var source: Rect2 = Rect2(BOLT_PANEL_REGION.position + (part.position - panel.position) / BOLT_PANEL_SCALE, part.size / BOLT_PANEL_SCALE)
		# Sampled like the whole sprite (no clamp at the cut), so the redrawn strip matches the art under it.
		canvas.draw_texture_rect_region(BOLT_PANEL_PROP, part, source, Color.WHITE, false, false)
		var lit: Rect2 = lamp.intersection(part)
		if lit.has_area():
			canvas.draw_rect(lit, light)


## [param rects] as rectangles covering the same area without overlapping (so a translucent drawing in
## each is laid down once): cut into vertical strips at every rectangle's left and right edge, with the
## covered height ranges of each strip merged, and side-by-side strips of the same height joined.
static func disjoint_rects(rects: Array[Rect2]) -> Array[Rect2]:
	var out: Array[Rect2] = []
	if rects.size() <= 1:
		out.assign(rects)
		return out
	var edges: Array[float] = []
	for rect: Rect2 in rects:
		edges.append(rect.position.x)
		edges.append(rect.end.x)
	edges.sort()
	for index: int in edges.size() - 1:
		var from: float = edges[index]
		var to: float = edges[index + 1]
		if to - from <= 0.0:
			continue
		var spans: Array[Vector2] = []
		for rect: Rect2 in rects:
			if rect.position.x <= from and rect.end.x >= to:
				spans.append(Vector2(rect.position.y, rect.end.y))
		spans.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var merged: Array[Vector2] = []
		for span: Vector2 in spans:
			if not merged.is_empty() and span.x <= merged[-1].y:
				merged[-1].y = maxf(merged[-1].y, span.y)
			else:
				merged.append(span)
		for span: Vector2 in merged:
			var joined: bool = false
			for at: int in out.size():
				if is_equal_approx(out[at].end.x, from) and is_equal_approx(out[at].position.y, span.x) and is_equal_approx(out[at].end.y, span.y):
					out[at].size.x = to - out[at].position.x
					joined = true
					break
			if not joined:
				out.append(Rect2(from, span.x, to - from, span.y - span.x))
	return out


## The alcove's core: exactly SentryBrain's cover span, up to the label row.
static func alcove_rect() -> Rect2:
	var top: float = LABEL_Y + 24.0
	return Rect2(SentryBrain.COVER_MIN_X, top, SentryBrain.COVER_MAX_X - SentryBrain.COVER_MIN_X, FLOOR_Y - top)


## A white texture that is opaque in the middle and fades softly to clear at its edges ([param fill]
## square for a recess, radial for a light); tinted by the colour it is drawn with.
static func soft_texture(fill: GradientTexture2D.Fill) -> GradientTexture2D:
	var texture: GradientTexture2D = GradientTexture2D.new()
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1.0, 1.0, 1.0, 0.75), Color(1.0, 1.0, 1.0, 0.0)])
	texture.gradient = gradient
	texture.width = 64
	texture.height = 64
	texture.fill = fill
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture


## A hatch's lamp, painted on the bar over its door, lit in [param color]; it rides and fades with
## the hatch as it lifts.
## The needle over the valve's painted gauge is the LINE gauge (left at empty, right at the vent's
## peak): red through the hard warning, and pinned red at the top for a while after the vent lets go
## (display_gauge). The VALVE plate counts the real turns.
func _draw_gauge() -> void:
	var centre: Vector2 = prop_point(valve_art, VALVE_DIAL_CENTRE)
	var face: float = VALVE_DIAL_RADIUS * VALVE_SCALE
	# A fresh face over the painted one, so its painted needle never reads as a second reading.
	# The lit face is the valve's lamp: it goes dark in a refusal's flicker.
	draw_circle(centre, face - 0.6, Color("#d9d3c4").lerp(FLICKER_DARK, 1.0 - lamp_level(&"valve")))
	draw_arc(centre, face - 1.6, PI + PI * 0.78, TAU, 8, SEAM_RED, 1.6, true)
	var angle: float = PI + PI * display_gauge
	var red: bool = gauge_tripped or (line_state == &"building" and gauge >= PressureLine.WARN_GAUGE)
	var needle: Color = Color("#d0261c") if red else Color("#1a1c20")
	draw_line(centre, centre + Vector2.RIGHT.rotated(angle) * (face - 1.2), needle, 1.4, true)
	draw_circle(centre, 1.2, needle)


## Hazard stripes on the floor over exactly the door's blast zone (PressureLine.BLAST_MIN_X..
## BLAST_MAX_X) while the fuse burns, pulsing with the fuse (steady with Reduced Motion).
func _draw_blast_zone() -> void:
	if door_blown or not (line_state == &"charged" or line_state == &"fuse"):
		return
	var pulse: float = 1.0 if reduce_motion else 0.5 + 0.5 * cos(fuse_remaining * BLAST_STRIPE_HZ * TAU)
	var left: float = PressureLine.BLAST_MIN_X
	var width: float = PressureLine.BLAST_MAX_X - PressureLine.BLAST_MIN_X
	var stripes: int = 15
	# A red wash over the walkway in front, then the stripes along the floor line, over its whole span.
	draw_rect(Rect2(left, FLOOR_Y, width, 9.0), Color(SEAM_RED, lerpf(0.12, 0.3, pulse)))
	for stripe: int in stripes:
		var segment: Rect2 = Rect2(left + stripe * width / stripes, FLOOR_Y - 2.0, width / stripes, 7.0)
		draw_rect(segment, Color(SEAM_RED, lerpf(0.55, 1.0, pulse)) if stripe % 2 == 0 else Color(0.1, 0.03, 0.03, 0.85))
	for edge: float in [left, left + width]:
		draw_line(Vector2(edge, FLOOR_Y - 12.0), Vector2(edge, FLOOR_Y + 9.0), Color(SEAM_RED, lerpf(0.7, 1.0, pulse)), 2.0)


func _draw_breaker_light() -> void:
	var light: Color = _breaker_light_color().lerp(Color.WHITE, 0.6 * breaker_pulse_level())
	draw_rect(BREAKER_LIGHT, light.lerp(FLICKER_DARK, 1.0 - lamp_level(&"breaker")))


func _breaker_light_color() -> Color:
	if door_blown:
		return DIM
	match line_state:
		&"tripped":
			return SEAM_RED
		&"idle":
			return Color("#d48954")
		_:
			return Color("#8be3ff")


## The ARM PANEL's light: green while the tank hangs ready, amber while the arm is busy, dark once
## the sentry is down.
func _draw_arm_panel_light() -> void:
	var light: Color = DIM if sentry_down else (GREEN if arm_state == &"hung" else AMBER)
	draw_rect(prop_rect(arm_panel_art, ARM_PANEL_LIGHT), light.lerp(FLICKER_DARK, 1.0 - lamp_level(&"release")))


## The rods that hang the arm's ceiling plate from the gantry, and, only while the winch hauls a
## missed tank back up, the steel cable from its shackle down to the tank (a dark braided body with a
## faint sheen, in the painted winch cable's tones). A released tank falls free and lies free: no
## cable while it falls, once it is down, or while a missed one still lies on the floor.
func _draw_arm() -> void:
	var plate_top: float = arm_art.position.y - ARM_REGION.size.y * TANK_ART_SCALE * 0.5 + 2.0
	for rod_x: float in [DropArm.MARK_X - 26.0, DropArm.MARK_X + 34.0]:
		draw_line(Vector2(rod_x, GANTRY_Y), Vector2(rod_x, plate_top), Color("#1b2630"), 5.0)
		draw_line(Vector2(rod_x - 1.5, GANTRY_Y), Vector2(rod_x - 1.5, plate_top), STEEL, 1.0)
	if tank_drop <= 0.0 or arm_state != &"rewinding" or tank_on_floor:
		return
	var cable_top: Vector2 = Vector2(DropArm.MARK_X, TANK_REST_Y - TANK_SIZE.y * 0.5)
	var tank_top: Vector2 = Vector2(DropArm.MARK_X, tank.position.y - TANK_SIZE.y * 0.5)
	draw_line(cable_top, tank_top, CABLE_SHADOW, 4.0)
	draw_line(cable_top, tank_top, CABLE_BODY, 2.5)
	draw_line(cable_top + Vector2(-0.6, 0.0), tank_top + Vector2(-0.6, 0.0), CABLE_SHEEN, 0.8)


## True while the floor brackets are lit: a live sentry's body is over them, so a tank landing now
## would hit it.
func mark_lit() -> bool:
	return door_blown and not sentry_down and sentry.visual.is_lit() and DropArm.is_hit(sentry.target_x)


## The floor brackets and the tank's shadow, both as wide as the tank (DropArm.HIT_RANGE either side
## of the mark). The shadow is laid over the stripes, dimming them and spilling onto the floor either
## side, and darkens and tightens as the tank comes down; the bracket posts stay on top of it. The
## brackets light up while the sentry is in them far enough to be hit (DropArm.is_hit).
func _draw_floor_mark() -> void:
	var left: float = DropArm.MARK_X - DropArm.HIT_RANGE
	var width: float = DropArm.HIT_RANGE * 2.0
	var lit: bool = mark_lit()
	var stripe_color: Color = MARK_LIT if lit else AMBER
	# The stripes run along the floor line and down onto the walkway in front of it, so a machine
	# standing on the mark covers only their top and the brackets still read below its treads.
	if lit:
		draw_rect(Rect2(left - 2.0, FLOOR_Y, width + 4.0, 10.0), Color(MARK_LIT, 0.28))
	var stripes: int = 7
	for stripe: int in stripes:
		var segment: Rect2 = Rect2(left + stripe * width / stripes, FLOOR_Y - 3.0, width / stripes, 7.0)
		draw_rect(segment, stripe_color if stripe % 2 == 0 else Color("#1a2229"))
	if arm_state != &"landed":
		var shadow: PackedVector2Array = PackedVector2Array()
		var half: Vector2 = Vector2(DropArm.HIT_RANGE * lerpf(1.35, 1.05, tank_drop), lerpf(5.0, 10.0, tank_drop))
		var centre: Vector2 = Vector2(DropArm.MARK_X, SHADOW_Y)
		for step: int in 24:
			shadow.append(centre + Vector2(cos(step * TAU / 24.0) * half.x, sin(step * TAU / 24.0) * half.y))
		draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, lerpf(0.25, 0.85, tank_drop)))
	for edge: float in [left, left + width]:
		draw_line(Vector2(edge, FLOOR_Y - 10.0), Vector2(edge, FLOOR_Y + 10.0), stripe_color, 2.0)


## The exit bolt's lamp as drawn on its panel and on the exit door's status lamp: its light
## (bolt_light_color), dimmed while a refused press flickers it (lamp_level).
func bolt_lamp_color() -> Color:
	return bolt_light_color().lerp(FLICKER_DARK, 1.0 - lamp_level(&"bolt"))


## The exit bolt's light, on its panel and on the exit door's status lamp: red and dead while the
## sentry runs the line, amber once it can take the overload, warming to white through the whine, green once popped.
func bolt_light_color() -> Color:
	if junction_cleared or bolt_state == &"open":
		return GREEN
	if bolt_state == &"charging":
		return AMBER.lerp(Color.WHITE, bolt_charge)
	if sentry_down:
		return AMBER
	return SEAM_RED
