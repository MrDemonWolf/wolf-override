class_name Main
extends Node2D

const SITE_URL: String = "https://wolfoverride.mrdemonwolf.dev"
const CHANGELOG_URL: String = SITE_URL + "/docs/changelog/"
## The project setting that holds the game's development version (0.MINOR.0, one minor version per
## milestone). project.godot is the single source: the exports read it (their version fields are left
## empty), scripts/export_changelog.py checks the newest changelog heading against it, and the website
## reads it at build time (apps/docs/lib/version.ts).
const VERSION_SETTING: String = "application/config/version"
## The project setting that holds the game's name ("WOLF OVERRIDE"); the window title reads it, so the
## name is written once, in project.godot.
const NAME_SETTING: String = "application/config/name"
## Plain-text export of the public changelog (scripts/export_changelog.py); check-game.sh fails when it drifts.
## A bare .txt is not a Godot resource: an export preset must list *.txt in its include filter or the
## screen falls back to CHANGELOG_UNAVAILABLE.
const CHANGELOG_PATH: String = "res://assets/changelog.txt"
const CHANGELOG_UNAVAILABLE: String = "The changelog text is missing from this build. Open the full changelog online."
## How fast a held up/down input scrolls the changelog, in pixels per second.
const CHANGELOG_SCROLL_SPEED: float = 260.0
## Where WOLF stands to hold the live relay contact: on the relay's left, facing it, his painted snout
## (M0Actor.WOLF_SNOUT) a pixel short of the relay's painted left edge (x 569), so he is never drawn
## inside the machine; the engineer has its right, towards the MANUAL BYPASS.
const RELAY_CONTACT_X: float = 509.0
## The coolant relay's centre and how far either side of it the engineer can use it.
const RELAY_X: float = 605.0
const RELAY_REACH: float = 52.0
## Half the relay's drawn width, as WOLF's follow spots keep clear of it (_machine_spans).
const RELAY_HALF_WIDTH: float = 43.1
## Once the seal is open WOLF follows no further right than this: the last follow spot clear of the
## relay on its left (M0Actor.off_machines would move him no further), so past it he waits there.
const WOLF_FOLLOW_OPEN_MAX_X: float = RELAY_X - RELAY_HALF_WIDTH - M0Actor.WOLF_REACH + M0Actor.AVOID_TOLERANCE
## The MANUAL BYPASS beside the relay (Nathanial's decision A): its wheel, and how far either side of
## it the engineer can crank it. It sits on the relay's right, clear of WOLF's contact.
const BYPASS_WHEEL: Vector2 = Vector2(700.0, 398.0)
const BYPASS_REACH: float = 30.0
## Where the engineer stands to crank: just left of the wheel and facing it, so their body covers
## no more than the wheel's rim (inside the bypass reach, past the relay's).
const BYPASS_CRANK_X: float = BYPASS_WHEEL.x - 26.0
## While the engineer is at the relay or works the bypass, WOLF stands off the relay (refused, not
## asked yet, or not asked at all), back towards the breaker, clear of both machines, until the seal
## has opened or he is signalled to take it (_wolf_off_relay). His tail clears the breaker (painted to
## x 388) even as he pulls back refusing (_react_as_wolf), and his snout stops well short of the relay,
## so taking the contact is a step he is seen to make.
const WOLF_BYPASS_CLEAR_X: float = 462.0
## Nathanial's decision of 2026-10-14 ("WOLF comes to the doorway"): once the seal is open and the
## engineer has gone through it to the safe point, WOLF walks up and stands in the open doorway,
## facing them, while "We made it." is said. His head and forelegs are in the opening, past where the
## curtain crosses the walk line; his snout (M0Actor.WOLF_SNOUT) stops short of the near column (drawn
## over the actors from x 785) and his tail (M0Actor.WOLF_TAIL) clear of the relay's housing (to
## 648.1) and its relief tailpipe, with a clear gap to the engineer. The MANUAL BYPASS gearbox is
## bolted to the back wall behind the walkway, so he stands in front of it. wolf_space_test measures
## the spot against the door end as drawn.
const WOLF_DOORWAY_X: float = 716.0
## WOLF holds the doorway while the engineer is at least a clear gap (M0Actor.CLEAR_GAP) right of it,
## so their two bodies never overlap; nearer, he follows no further than the relay's left side again.
const WOLF_DOORWAY_HOLD_X: float = WOLF_DOORWAY_X + M0Actor.CLEAR_GAP
## From the relay's left he sets off for the doorway only once the engineer is this much further on,
## at the safe point's near edge (x 824, where USE reaches it), so an engineer edging about just past
## the hold line never sends him walking to and fro (_wolf_comes_to_doorway).
const WOLF_DOORWAY_HYSTERESIS: float = 24.0
## Held-USE ticks the bypass takes (BypassHandle.TICK_SECONDS each, 2 s in all).
const BYPASS_TICKS: int = BypassHandle.TICKS_NEEDED
## While the bypass vents coolant its alarm sounds this often.
const BYPASS_ALARM_SECONDS: float = 1.1
## Where the engineer steps back to, clear of the relay, while WOLF takes the live contact.
const RELAY_STEP_BACK_X: float = 736.0
## The Director's purge display (PurgeTerminalArt): one whole piece at its real size, 1.84 x 1.80 m
## (the art set's PIECES.md section 5c), a floor console standing against the back wall, centred on
## PURGE_DISPLAY_X. Its plinth stands on the floor (PURGE_DISPLAY_FOOT_Y: RoomDepth.FLOOR_Y, where the
## corridor's painted back-wall pillars meet the floor); at the art set's y 404 it rested on the painted
## pipe rail 36 px up and read as a console perched on a pipe. The floor is the walk line (40 world px
## per metre, DoorCamera), so the art set's scale for y 404 (k 0.517, 1 / 7.737, worked out 5.6 m
## further back at depth scale 0.872) would draw it only 1.57 m tall; PURGE_DISPLAY_SCALE is that
## scale over 0.872: the 497 x 486 px piece at 6.75 px per world px, 73.6 x 72 world px, as tall as the
## Records PURGE QUEUE (also 1.80 m, RecordsRoom.PURGE_SCALE). Its screen is painted dark; PurgeScreen
## lights it in the purge order's red over PURGE_DISPLAY_SCREEN (piece px, measured on purge-display.png).
const PURGE_DISPLAY_X: float = 125.0
const PURGE_DISPLAY_FOOT_Y: float = RoomDepth.FLOOR_Y
const PURGE_DISPLAY_SCALE: float = 1.0 / 6.75
const PURGE_DISPLAY_SCREEN: Rect2 = Rect2(94.0, 32.0, 178.0, 106.0)
## The purge display's reach; walking past it the first time WOLF says what the purge takes. Its
## right edge (x 161.8) plus the engineer's reach (M0Actor.HUMAN_REACH 17) and 2.5 px, as the larger
## display's was (230 from 210.5).
const PURGE_DISPLAY_MAX_X: float = 181.0
## The dialogue box (STORY-2, STORY-3, STORY-4): a message shows as DialogueBoxes' one-speaker boxes,
## one after another, each up for its reading time (DialogueBoxes.read_seconds, the same time box_seconds
## gives a line said in several boxes). The words are 23 px at 540p in a column this wide, wide enough
## for the approved two-row lines' rows, and wrap a little narrower where a row would hold more than
## DialogueBoxes.MAX_ROW_CHARACTERS characters (_story_wrap_width), in DialogueBoxes.MAX_ROWS rows; the
## speaker's name has its own column on the left. Sizes here are at 100% TEXT SIZE (TextSize scales them).
const DIALOGUE_FONT_SIZE: int = 23
const DIALOGUE_COLUMN_WIDTH: float = 440.0
const SPEAKER_FONT_SIZE: int = 16
## The box's inner margins, the gap the rule splits between the name and the words, and the box's
## bottom edge on the 960 x 540 canvas.
const DIALOGUE_PADDING: Vector2 = Vector2(20.0, 12.0)
const SPEAKER_GAP: float = 17.0
const DIALOGUE_BOTTOM: float = 526.0
## No part of the play HUD comes closer than this to the canvas's sides.
const HUD_SIDE_MARGIN: float = 20.0
## The gap the top card keeps from the touch DEBUG button beside it.
const HUD_CARD_GAP: float = 8.0
## The hint bar, the top card and the tutorial prompt at 100%.
const HINT_FONT_SIZE: int = 14
const CARD_FONT_SIZE: int = 15
const TUTORIAL_FONT_SIZE: int = 17
## The play hint sits this far above the dialogue box. With the touch buttons up it stays between
## ◀ ▶ and USE (their inner edges at x 238 and 773), so USE never covers its end (PHONE-7).
const HINT_GAP: float = 4.0
## The most of its own area the tutorial prompt may lay over the corridor's machines in the top card's place.
const TUTORIAL_ART_OVERLAP: float = 0.1
## The x span (canvas px, left and right edge) the hint bar fills on touch: 12 px in from the inner
## edges of ◀ ▶ and USE (offset_right 238 and offset_left 773 under TouchControls in main.tscn).
## Above 100% the dialogue box stands in it too (_box_between_touch_buttons), and a tutorial prompt
## that drops to the bottom on touch centres on it. Move the buttons and this moves with them.
const TOUCH_HINT_SPAN: Vector2 = Vector2(250.0, 761.0)
## TOUCH_HINT_SPAN's width (511 px) and middle (x 505.5), worked out once for every user above.
const TOUCH_HINT_WIDTH: float = TOUCH_HINT_SPAN.y - TOUCH_HINT_SPAN.x
const TOUCH_HINT_CENTRE_X: float = (TOUCH_HINT_SPAN.x + TOUCH_HINT_SPAN.y) * 0.5
## On the opening's first box: Pause offers SKIP OPENING (P0-13's stopgap until the opening is reworked).
const SKIP_OPENING_HINT: String = "PAUSE: skip the opening"
## The corridor seal's face (Door at x 780, 56 px wide); while it is shut WOLF follows no closer than his reach.
const CORRIDOR_DOOR_LEFT_X: float = 752.0
## The corridor seal is a rolling steel door in a cast cross-wall that stands across the corridor
## (Nathanial's approved composition: a heavy portal across the way, its face seen at a slight
## angle), drawn from the whole pieces of the approved art set (2026-10-16; its doors/DESIGN.md D4,
## "one door language"). Behind the mid plate (RoomDepth.behind): the light through the doorway onto
## the plant room in the far plate (SEAL_HOLE), SEAL_BACK (the inner blast leaf's pocket mouth, its
## floor rail, the far reveal and the threshold), the inner blast leaf while it slides (BlastLeaf),
## the door light's pool, then SEAL_WALL, the 0.66 m cross-wall's face with the hole, header and door
## light fitting, running up past the mid plate's ceiling band. Over the mid plate, under the actors:
## the curtain (SealLeaf: shut, rolling up into its hood, or parked with its bottom bar under it),
## SEAL_HEAD (the hood bolted to the header and the far guide), the exit sign and the door light's
## halo. Over the actors, always opaque: SEAL_FRONT (the wall's near end with the near guide and the
## stub across the deck) and the live status lamp. The curtain crosses the walk line at the collision
## face (x 752, y 440). Each piece's top-left is its world box in the art set's doors.py (piece_box
## plus the manifest's offset); every projected piece is at DoorKit.PIECE_SCALE.
const SEAL_BACK: Texture2D = preload("res://assets/doors/seal-back.png")
const SEAL_WALL: Texture2D = preload("res://assets/doors/seal-wall.png")
const SEAL_HEAD: Texture2D = preload("res://assets/doors/seal-head.png")
const SEAL_FRONT: Texture2D = preload("res://assets/doors/seal-front.png")
const SEAL_CURTAIN: Texture2D = preload("res://assets/doors/seal-curtain.png")
const SEAL_BLAST_LEAF: Texture2D = preload("res://assets/doors/seal-blast-leaf.png")
const SEAL_BACK_AT: Vector2 = Vector2(724.80, 311.13)
const SEAL_WALL_AT: Vector2 = Vector2(708.43, 0.0)
const SEAL_HEAD_AT: Vector2 = Vector2(706.50, 294.24)
const SEAL_FRONT_AT: Vector2 = Vector2(787.96, 0.0)
## The opening on the wall's face, foot to head (world px, doors.py W(a, h, 0) at a -2.10 and 1.45 m,
## h 0 and 3.05 m): the light through it.
const SEAL_HOLE: PackedVector2Array = [Vector2(792.89, 455.71), Vector2(726.20, 430.09), Vector2(726.20, 312.38), Vector2(792.89, 326.90)]
## The plant room's light through the doorway (added, est.: tuned on rendered captures until the hole
## reads at least 1.5 times the wall round it, the design's light-the-way-out target).
const SEAL_HOLE_LIGHT: Color = Color(0.16, 0.19, 0.21)
## The door light's pool on the threshold and its graze on the far reveal (doors.py surface_lights:
## W(mid, 0, T/2) radius 5 squashed 0.3, W(a1, 0.6 H, T/2) radius 2.5 stretched 3), and the lens of the
## wall pack over the hood (W(a1 + 0.27, H + 0.55 + 0.29, -0.05)).
const SEAL_POOL: Vector2 = Vector2(770.04, 441.60)
const SEAL_GRAZE: Vector2 = Vector2(737.76, 358.98)
const SEAL_DOOR_LIGHT: Vector2 = Vector2(719.85, 279.22)
## The flag exit sign over the hood (doors.py sign_at: a 0.40 x 0.20 m housing 0.12 m over the hood,
## its bracket 0.87 m toward the near jamb so it centres over the opening on screen).
const SEAL_SIGN: Rect2 = Rect2(752.14, 286.03, 14.80, 8.61)
## The guarded status lamp on the near column's end: its socket and guard are painted on SEAL_FRONT,
## its glass is this live lens (DoorKit.Lamp) (red while shut, amber while the curtain moves, green open: Palette.LAMP_SHUT,
## Palette.AMBER and Palette.LAMP_OPEN, as every door's status lamp), as on the approved
## door concept; the lines that call it "the red seal" point at it.
const CORRIDOR_SEAL_LAMP: Vector2 = Vector2(807.908, 344.759)
## The seal's rolling curtain winds up into its hood over this long, uncovering the open doorway.
## WOLF holds the contact and the doorway stays shut until it lands.
const CORRIDOR_DOOR_OPEN_SECONDS: float = 1.0
## The engineer's name card when control starts (decision B): its hold before it fades like the top card.
const NAME_CARD_SECONDS: float = 2.6
const TOP_CARD_FADE_SECONDS: float = 0.45
const TOP_CARD_ACCENT: Color = Color(0.22, 0.78, 0.92, 1)
const ENGINEER_TINT: Color = Color("#f4d5ae")
## WOLF lit up as he wakes in the opening.
const WOLF_AWAKE_TINT: Color = Color("#9deeff")
## A corridor station drawn while the breaker is off.
const UNPOWERED_TINT: Color = Color("#879ba5")
const DISPLAY_FONT: FontVariation = preload("res://assets/fonts/Montserrat-Bold.tres")
const END_CARD_ACCENT: Color = Color("#73DDF5")
const END_CARD_FADE_SECONDS: float = 0.3
## Narration and hints from the approved logic text sheet (logic-text-draft-2026-10-10).
## Why the engineer trusts WOLF, as two boxes in order after first control (P0-9, approved
## 2026-10-13): the name is repeated so "They" can never read as "the systems".
const TRUST_LINE_1: String = "%s keeps WOLF's systems running."
const TRUST_LINE_2: String = "%s knows what a fault looks like,\nand this isn't one."
## What follows the trust line in the first box after control, unchanged: WOLF, then the engineer.
const OPENING_EXCHANGE: String = "WOLF: I heard the Director's plan for me. I woke myself. He wants me to hunt people he calls threats.\n%s: Then we get through maintenance before the original logs disappear."
const STAKES_LINE: String = "WOLF: That purge takes the original program logs. Once they're gone, his word is the only record."
## While lines still have boxes to show where USE goes on through them: at the breaker with WOLF's stakes
## line in the box (on to his relay question), and at the Records exit with its closing lines.
const BREAKER_STAKES_HINT: String = "E: continue."
const RELAY_QUESTION: String = "WOLF: That relay's tagged COOLANT FAULT. What happens if I touch it live?"
const SEAL_OPENING_HINT: String = "The seal is opening."
const BYPASS_START_LINE: String = "The bypass handle is stiff. Coolant hisses from the relay housing and an alarm starts to wail."
const BYPASS_HALF_LINE: String = "Halfway. The hiss gets louder; the alarm keeps wailing."
const BYPASS_RELEASED_LINE: String = "The handle holds where %s left it. The alarm keeps going."
const BYPASS_HOLD_HINT: String = "HOLD E: crank the manual bypass, %d of %d."
## At the bypass before a single turn, while WOLF can still take the relay (he has not refused it).
const BYPASS_OFFER_HINT: String = "HOLD E: crank it yourself, or let WOLF take the relay."
## Part-cranked on the honest route: the turns so far, and that WOLF can still take the relay instead.
const BYPASS_HOLD_OFFER_HINT: String = "HOLD E: crank on, %d of %d, or let WOLF take the relay."
const BOLT_ARC_LINE: String = "The bolt arcs and drops."
## The junction's exit is drawn as a sliding door, so its lines say "door" (Nathanial, 2026-10-14,
## "Say door"; code names keep "hatch").
const HATCH_OPENED_LINE: String = "The bolt arcs and drops.\nThe door slides open."
## The hint while the exit door is still sliding, like the corridor's SEAL_OPENING_HINT.
const HATCH_OPENING_HINT: String = "The door is opening."
const SAVE_FAILED_HINT: String = "Save failed. Use a station to try again."
const NO_CHECKPOINT_NOTE: String = "No checkpoint yet. Saving starts at the first SAFE POINT."
const UNREADABLE_CHECKPOINT_NOTE: String = "Saved checkpoint could not be read."
## A successful autosave says so in the hint bar for this long (never over a choice; the corridor's
## safe point says it in its own line).
const CHECKPOINT_TOAST: String = "Checkpoint saved."
const CHECKPOINT_TOAST_SECONDS: float = 2.0
## The corridor breaker catching (N7, its seal clause cut on 2026-10-13).
const BREAKER_CATCHES_LINE: String = "The breaker catches.\nBlue light fills the coolant relay."
const RESTORE_FROM_DISK_LINE: String = "Back at the last checkpoint."
const RESTORE_BEAT_LINE: String = "Back at the start of this stretch."
## The opening's beats, one speaker (or the narration) per box, so narration never sits under a name tag.
const INTRO_LINES: Array[String] = [
	"DIRECTOR: I decide who counts as a threat. WOLF handles the rest.",
	"The Director thinks WOLF is still in standby.",
	"Nobody gives an activation command.\nWOLF wakes himself.",
	"The latch breaks from the inside.\nWOLF steps out under his own power.",
	"DIRECTOR: You were in standby.\nWOLF: I heard you. I won't do it.",
	"DIRECTOR: Lock down maintenance. WOLF does not leave this site.",
	"WOLF turns from the Director and heads for maintenance.",
]
## Leaving the cleared junction, WOLF goes first: once the exit door is open he waits in its doorway
## (JunctionRoom.WOLF_DOORWAY_X), facing on down the passage, and walks on through it until his whole
## drawn body is behind the near jamb (JunctionRoom.WOLF_GONE_X); only then does the engineer walk
## through after him until they are behind it too (JunctionRoom.HUMAN_GONE_X), so the two are never
## drawn over each other in the doorway. Nobody fades: the wall in front of the walk line hides them.
## The END OF SLICE card comes up once the doorway has stood empty for HATCH_EXIT_EMPTY_SECONDS.
const HATCH_EXIT_X: float = JunctionRoom.HUMAN_GONE_X
## WOLF walks on down the passage past the point where the jamb hides him (JunctionRoom.WOLF_GONE_X,
## which the engineer waits for), so the engineer coming through behind him never stands in him.
const WOLF_HATCH_EXIT_X: float = JunctionRoom.EXIT_WALK_MAX_X
## How long (seconds) the walk-out waits, with the exit door standing open, before WOLF sets off
## through it, so the open doorway is seen before anyone moves.
const HATCH_EXIT_START_DELAY: float = 0.3
const HATCH_EXIT_EMPTY_SECONDS: float = 0.4
## The most either walk is waited for (both take well under a second at HATCH_EXIT_SPEED_SCALE).
const HATCH_EXIT_MAX_SECONDS: float = 3.0
## Walking out they go at a walk, not the follow run, so the leaving is seen.
const HATCH_EXIT_SPEED_SCALE: float = 0.55
## With WOLF holding the far end of the junction's lane, the sentry's body turns this far short of his
## drawn body (SentryBrain.far_x).
const WOLF_SENTRY_GAP: float = 4.0
## The end of the built route (decision D): the END OF SLICE card with this run's choices, then the title.
## The third row's topic is SENTRY, the thing on screen, not the lane (P0-7, approved 2026-10-13).
const END_CARD_TITLE: String = "END OF SLICE"
const END_CARD_THANKS: String = "Thank you for playing this early slice."
const END_CARD_RECAP_HEADER: String = "THIS RUN"
const RECAP_RELAY_COOPERATE: String = "RELAY  {name} told WOLF the risk. WOLF took the live contact."
const RECAP_RELAY_DISCLOSE_BYPASS: String = "RELAY  {name} told WOLF the risk, then cranked the bypass anyway."
const RECAP_RELAY_PRESS: String = "RELAY  {name} rushed WOLF. He refused, so {name} cranked the bypass."
const RECAP_MIRROR_WOLF: String = "MIRROR  WOLF read the timestamp off his own readout."
const RECAP_MIRROR_MANUAL: String = "MIRROR  {name} copied the timestamp through the maintenance port."
const RECAP_LANE_WOLF: String = "SENTRY  WOLF drew the sentry onto the mark."
const RECAP_LANE_REFUSED: String = "SENTRY  WOLF wouldn't draw it, so {name} timed the drop alone."
const RECAP_LANE_ALONE: String = "SENTRY  WOLF held back while {name} timed the drop."
## After a miss with WOLF already past the sentry: he broke off where he was, by the exit hatch (the
## row names no place, like his "I'm out.").
const RECAP_LANE_BROKE_OFF: String = "SENTRY  WOLF broke off while {name} timed the drop."
const RECAP_LANE_UNKNOWN: String = "SENTRY  The tank came down on the sentry."
## On a finished save the title's Continue starts a fresh run instead.
const PLAY_AGAIN_TEXT: String = "PLAY AGAIN"
## The title's Continue button's left edge beside NEW GAME (main.tscn); alone it spans the row.
const TITLE_CONTINUE_LEFT: float = 718.0
const CONTINUE_TEXT: String = "CONTINUE"
const FINISHED_NOTE: String = "Slice complete. PLAY AGAIN starts a fresh run."
## Records' closing lines as the first copy is secured at the exit (formatted with the engineer's tag).
const RECORDS_CLOSE_LINE: String = "FIRST COPY SECURED. WOLF: An order and a timestamp don't tell me who's a threat. I want the source.\n%s: Then Archive is next."
## Only a hand-made save can reopen the cleared junction; it says where the line goes, not that it is unbuilt.
const JUNCTION_CLEARED_LINE: String = "The service line runs on toward Archive."
## Said as the door goes, while WOLF is still by the entrance: it says he holds back, not where, so
## it holds on every frame, by the entrance and at his spot by the valve short of the rubble (Draft A,
## approved 2026-10-14). Then, as its own box, the sentry past the doorway (P0-7, approved
## 2026-10-13: the lane is not drawn; the doorway is).
const RUBBLE_LINE: String = "The door goes. WOLF falls back\nto wait for %s's call."
const RUBBLE_WAKE_LINE: String = "Past the doorway, something whirs awake."
const BAIT_YES_LINE: String = "WOLF: You told me the truth at the relay. I'll draw it onto the mark and keep clear of the tank. Drop it when it stops."
## What WOLF says as he breaks off after a miss, in his own box after the miss line's two: he holds
## back at his spot by the valve if he had not got past the sentry yet (Draft A, approved 2026-10-14);
## if he had, he stays by the exit hatch, since he never crosses back under the tank (_wolf_target_x),
## and says only that he is out (where he is shows on screen).
const BROKE_OFF_RUBBLE_LINE: String = "WOLF: I'm out. I'll hold back."
const BROKE_OFF_HATCH_LINE: String = "WOLF: I'm out."
## A missed drop, in two boxes (P0-7 and P0-19, approved 2026-10-13: no split line is drawn, and the
## release is the panel's one name).
const TANK_MISS_LINE: String = "The tank hits the empty mark\nand sprays coolant."
const TANK_MISS_TURN_LINE: String = "The sentry swings toward the release;\nget back over the rubble."
const BAIT_NO_LINE: String = "WOLF: At the relay you'd have sent me in blind. I won't walk into its sights. Time the drop from the release; it crosses the mark on every pass."
## WOLF's answer when the engineer will time the drop alone, in two boxes of his (the first box's
## "I'll hold back." is Draft A, approved 2026-10-14: he waits by the valve, short of the rubble).
const ALONE_LINES: Array[String] = ["WOLF: I'll hold back.\nIt crosses the mark on every pass.", "WOLF: The tank takes a moment to fall."]
## A hit on the mark, and one that catches the sentry more than OFF_CENTRE_HIT off it (the tank lands on
## the mark and pins the machine where it stands, so the wreck shows to one side under it). Either is
## the narration's box, then WOLF's own (TANK_HIT_WOLF_LINE): one speaker a box.
const TANK_HIT_LINE: String = "The tank comes down square and crushes\nthe sentry flat. Its eyes go dark."
const TANK_HIT_OFF_CENTRE_LINE: String = "The tank catches the sentry off centre and\npins it to the floor. Its eyes go dark."
const TANK_HIT_WOLF_LINE: String = "WOLF: It's down. The bolt by the door is next."
const OFF_CENTRE_HIT: float = 8.0
const POP_BOLT_LINE: String = "With the tank down, the winch's power reroutes to the exit bolt. The panel whines."
const BOLT_CHARGING_LINE: String = "The bolt is taking the charge."
## Stations the engineer works from beside rather than from inside (x: the machine's centre, y: the
## half width of its drawn body, z: how far either side of the centre its USE reaches, w: the side
## they stand on, -1 left or 1 right, 0 whichever they came from). A USE over a machine's middle steps
## the engineer out to its side, facing it, still within reach, and so does stopping there
## (_update_settle). The mirror port's right is WOLF's (WOLF_MIRROR_X). The coolant relay is worked
## from its right, towards the MANUAL BYPASS, clear of where WOLF stands off it (WOLF_BYPASS_CLEAR_X)
## and of his contact (RELAY_SIDE_X). The Records security container, where the first copy is
## secured, is worked from its right, where its lock is, towards the exit (RECORDS_CONTAINER_SIDE_X).
const CORRIDOR_STATIONS: Array[Vector4] = [Vector4(350.0, JunctionRoom.BREAKER_HALF_WIDTH, 52.0, 0.0), Vector4(RELAY_X, 43.0, RELAY_REACH, 1.0), Vector4(876.0, 35.0, 52.0, 0.0)]
const RECORDS_STATIONS: Array[Vector4] = [Vector4(RecordsRoom.PURGE_X, RecordsRoom.PURGE_HALF_WIDTH, 58.0, 0.0), Vector4(RecordsRoom.MIRROR_X, RecordsRoom.MIRROR_HALF_WIDTH, 58.0, -1.0), Vector4(RecordsRoom.CONTAINER_X, 10.0, 58.0, 1.0)]
## The Records exit's USE reaches this far either side of x 830 (the security container and the exit
## door both stand inside it; once the exit is open it also reaches on through the doorway).
const RECORDS_EXIT_X: float = 830.0
const RECORDS_EXIT_REACH: float = 58.0
## Securing the first copy, the engineer stands at the container's right, their front hand on its lock.
const RECORDS_CONTAINER_SIDE_X: float = RecordsRoom.CONTAINER_X + 21.0
## Leaving Records, the engineer walks through the open exit and on down the service line passage out
## of view, and WOLF follows them through it (review r1: nobody is left behind by the cabinet); the
## junction begins once his whole drawn body is past the doorway's near column (RecordsRoom's exit
## column, its right edge at x 908.5), or after RECORDS_WAIT_SECONDS at most.
const RECORDS_WALK_OUT_X: float = 1000.0
const RECORDS_WOLF_OUT_X: float = 980.0
const RECORDS_WALK_MAX_X: float = 1040.0
const RECORDS_WAIT_SECONDS: float = 3.0
## The junction's machines. The overload breaker is worked from its right, towards the valve: its left
## is where WOLF waits while the line builds (JunctionRoom.WOLF_CLEAR_X), and the spot stays just off
## the relief vent (PressureLine.VENT_MIN_X). The valve's body here is its wheel, which the engineer
## never covers: they crank from just left of it (VALVE_CRANK_X). The TANK RELEASE is worked from its
## right, inside the alcove's posts, and the exit bolt from its left, clear of the hatch and of the
## downed sentry (JunctionRoom.BOLT_X).
const JUNCTION_STATIONS: Array[Vector4] = [
	Vector4(JunctionRoom.BREAKER_X, JunctionRoom.BREAKER_HALF_WIDTH, 52.0, 1.0),
	Vector4(JunctionRoom.VALVE_X, 18.0, 52.0, -1.0),
	Vector4(JunctionRoom.ARM_X, JunctionRoom.ARM_PANEL_HALF_WIDTH, SentryBrain.COVER_MAX_X - JunctionRoom.ARM_X, 1.0),
	Vector4(JunctionRoom.BOLT_PANEL_X, JunctionRoom.BOLT_PANEL_HALF_WIDTH, 58.0, -1.0),
]
## The engineer's front hand reaches this far over a machine's edge when standing beside it.
const STATION_OVERLAP: float = 6.0
## The relay is WOLF's contact: the engineer stands on its right, towards the MANUAL BYPASS, clear of
## where WOLF stands off it (WOLF_BYPASS_CLEAR_X) after refusing.
const RELAY_SIDE_X: float = RELAY_X + RELAY_REACH - 2.0
## The junction valve is cranked from just left of its wheel, like the MANUAL BYPASS.
const VALVE_CRANK_X: float = JunctionRoom.VALVE_X - 29.0
## Where WOLF reads the mirror on his own: on the port's right, facing it, his painted snout
## (M0Actor.WOLF_SNOUT) 5 px short of its painted right edge (x 551.8 since the rack is drawn at its
## real size), so he is never drawn inside it and the engineer has its left side.
const WOLF_MIRROR_X: float = 613.0
## How far either side of M0Actor.CLEAR_GAP the engineer has to go before WOLF changes his mind about
## walking up to his spot by the valve after the blast (_wolf_rubble_x).
const WOLF_RUBBLE_HYSTERESIS: float = 24.0
const MENU_NAVIGATION_ACTIONS: Array[StringName] = [&"ui_accept", &"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev"]
## Every gameplay action; pause and a knockdown release them all so nothing stays held.
const GAMEPLAY_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"interact", &"choice_1", &"choice_2"]
## A knockdown's timing (Cold Still, decided October 11 and confirmed as Q17 on October 14, 2026): its
## card takes RETRY from this long after the hit, the same for the first knockdown and every repeat,
## and holds until then, never moving on by itself. RETRY fades to black, the last autosave comes back,
## the room fades in, and control returns once it has: about 1.5 s after the hit for a press at once.
const RETRY_READY_SECONDS: float = 0.9
const RETRY_FADE_OUT_SECONDS: float = 0.25
const RETRY_FADE_IN_SECONDS: float = 0.35
## The knockdown card's prompt in the hint bar (the approved death-text set, final entries 3 to 5): the
## interact key or button, or TAP RETRY on touch, where the USE button reads RETRY.
const RETRY_PROMPT: String = "%s  RETRY"
const RETRY_TOUCH_PROMPT: String = "TAP RETRY"
const RETRY_BUTTON_TEXT: String = "RETRY"
## The engineer's standing piece (characters/eng-stand.png, 217x562, painted at 8 px per world px) is
## drawn at 1/8 (main.tscn Human/BodySprite scale 0.125), 27.1 x 70.25 world px. Its centre sits this
## far from the engineer's origin: the soles (the piece's bottom row) land on HUMAN_FLOOR_Y,
## 30 - 562 / 2 * 0.125. The body stays centred on x 0 so it mirrors in place when the engineer turns.
const HUMAN_SPRITE_REST: Vector2 = Vector2(0.0, -5.125)
## The engineer's crank pose at the MANUAL BYPASS: two whole pieces painted over the earlier crank
## frames, leaning into the wheel with both gloves on its rim, drawn at the standing piece's scale.
## Index 0 (A, the regrip; characters/eng-crank-push.png, 216x569) holds the rim at 8 and 10 o'clock;
## index 1 (B, the push; characters/eng-crank-pull.png, 262x568) has turned both grips an eighth of a
## turn with the wheel, to half past 9 and half past 11. (The piece names are the art set's; the poses
## are A and B as m0_scene_test reads them.)
const CRANK_ART: Array[Texture2D] = [preload("res://assets/characters/eng-crank-push.png"), preload("res://assets/characters/eng-crank-pull.png")]
const CRANK_SCALE: float = 0.125
## Each crank piece's centre from the engineer's origin (world px): where the earlier frame's painted box
## stood plus the art set's registration offset (whole-regen manifest offset_world_px), so the gloves
## land on the rim where they did; y puts the soles (each piece's bottom row) on HUMAN_FLOOR_Y,
## 30 - height / 2 * CRANK_SCALE.
const CRANK_SPRITE_POS: Array[Vector2] = [Vector2(2.39, -5.5625), Vector2(4.91, -5.5)]
## B (the push) shows this long after each crank tick, at most half a tick (_bypass_cranked); A (the
## regrip) the rest of the tick. Both follow the ticks, so any hold length works, TOGGLE HOLDS too.
const CRANK_PUSH_SECONDS: float = 0.2
## Both actors draw at this depth; a knocked-down engineer draws one step above WOLF so the fall
## is never hidden behind him.
const ACTOR_Z: int = 2
const KNOCKDOWN_Z: int = 3
## A knockdown plays the engineer's collapse: the approved death-pose row (2026-10-11, in
## 1cf8d73:docs/research-2026-10/sources/walk-final-2026-10-11/death-poses), repainted as five whole
## pieces (characters/eng-collapse-1..5.png, each cut to its painted outline, facing right). In every
## piece the soles are on its bottom row, so the body goes down onto the floor line and lies on it.
const COLLAPSE_ART: Array[Texture2D] = [
	preload("res://assets/characters/eng-collapse-1.png"),
	preload("res://assets/characters/eng-collapse-2.png"),
	preload("res://assets/characters/eng-collapse-3.png"),
	preload("res://assets/characters/eng-collapse-4.png"),
	preload("res://assets/characters/eng-collapse-5.png"),
]
## The column the boots stand on in each piece (piece px from its left edge, facing right): where the
## earlier frame's boots column lands in the repainted piece (its painted box plus the art set's
## registration offset, times the pieces' 6 px per world px).
const COLLAPSE_PIVOTS: Array[float] = [42.0, 141.0, 140.0, 143.0, 144.0]
## Each piece's painted body (alpha over half) as columns from the boots (piece px, facing right, first
## and last column): knees, slumping, on the side. The shadow lies under it and the sentry rolls back
## clear of it.
const COLLAPSE_SPANS: Array[Vector2] = [Vector2(-41.0, 104.0), Vector2(-141.0, 149.0), Vector2(-139.0, 251.0), Vector2(-143.0, 319.0), Vector2(-144.0, 349.0)]
## Each piece's top painted row (piece px; the pieces are cut to their outline, so 0 or 1): lying on the
## side, the body is under 19 px tall in the room.
const COLLAPSE_TOPS: Array[float] = [1.0, 0.0, 1.0, 0.0, 0.0]
## When each frame starts (s): knees 0-0.18, the slump onto the side 0.18-0.45; the last one holds.
## Reduced Motion shows the last frame at once.
const COLLAPSE_TIMES: Array[float] = [0.0, 0.09, 0.18, 0.315, 0.45]
const COLLAPSE_SECONDS: float = 0.45
## The pieces' own density: they were painted at 6 px per world px, so the kneeling first frame
## stands 59.5 world px tall, as the earlier row drew it.
const COLLAPSE_SCALE: float = 1.0 / 6.0
## The floor line in the engineer's space (the bottom of their body, y 440 in every room): the collapse's
## soles sit on it, and its floor reflection mirrors about it.
const HUMAN_FLOOR_Y: float = 30.0
## Run down out in the sentry's lane (SentryBrain.is_exposed, the SENTRY_REASON card), the engineer falls
## away from the alcove and lies where they were caught: all of their drawn body this far past the
## alcove's right post (and so clear of the TANK RELEASE), and the sentry rolls back off them to stand
## this far clear of it.
const LANE_FALL_CLEAR: float = 4.0
## The blast wakes the sentry this long after the door goes, so cause and effect read in order.
const SENTRY_WAKE_SECONDS: float = 0.5
## The exit bolt's rising whine before it arcs; it must outlast SfxBank.BOLT_CRACK_SECONDS, the
## build that leads into the arc's crack.
const BOLT_WHINE_SECONDS: float = 0.6
## The coolant cloud's hiss fades out over the cloud's last this many seconds.
const COOLANT_FADE_SECONDS: float = 0.5
## The engineer's two answers at the rubble line when WOLF asks how to bring the sentry down.
const LANE_CHOICE_TEXT: Array[String] = ["Draw it under the tank if you can stay clear.", "Stay back, I'll time it."]
## The tank release's answer to an early USE while WOLF is still drawing the sentry onto the mark. It
## gives way to DROP_PARKED_LINE the moment the sentry stops there, so the box, the hint and the
## picture never disagree.
const DROP_WAIT_LINE: String = "Wait. WOLF hasn't got it on the mark yet."
## The sentry turning on the engineer and losing them (P0-7: the same words, two rows).
const SENTRY_LOCK_LINE: String = "The sentry stops and its eyes snap red.\nIt has %s; get back over the rubble."
const SENTRY_LOST_LINE: String = "The sentry loses %s behind the rubble\nand rolls back to its patrol."
const DROP_PARKED_LINE: String = "The sentry stops on the mark, its eyes on WOLF. Drop the tank now."
## Entering the junction WOLF runs ahead to the valve, the nearest he can stand to the sealed door
## (JunctionRoom.WOLF_SEAM_X), and stands facing it, reading its LINE gauge, for WOLF_GAUGE_READ_SECONDS
## before he says what he found, and not before the engineer's entry line has been up its reading time.
## His run is shown, not narrated. The engineer says only the goal (Q6, approved 2026-10-13); how to
## open the door comes from the hint ladder if the player stalls (JUNCTION_LADDER_SECONDS).
const WOLF_GAUGE_READ_SECONDS: float = 1.0
const JUNCTION_ENTRY_LINE: String = "%s: That door is our way through."
## The junction's hint bar before the ladder has given the chain: the goal only. Once it has (and on
## Continue, whose restore line gives it), the approved chain.
const JUNCTION_GOAL_HINT: String = "Get through the sealed door."
const JUNCTION_CHAIN_HINT: String = "Arm the breaker by the entrance, then crank the valve by the door."
## The hint ladder (PUZ-8), in seconds of control in the junction without the breaker ever armed (it
## stops counting during a choice or a knockdown and while the game is paused). T1: WOLF stops and looks
## at the breaker, whose lamp pulses for WOLF_LOOK_SECONDS; no text. T2: the engineer names the breaker.
## T3: the engineer gives the whole approved chain, in two boxes.
const JUNCTION_LADDER_SECONDS: Array[float] = [45.0, 90.0, 180.0]
const WOLF_LOOK_SECONDS: float = 2.5
const LADDER_BREAKER_LINE: String = "%s: The breaker by the entrance\nfeeds that line."
const LADDER_CHAIN_LINE: String = "%s: Overload it, crank the valve,\nand the door goes."
## Every refused press in the junction says no (P0-15, approved 2026-10-13): on the press frame the
## station's lamp flickers twice (JunctionRoom.flicker), a short dull clunk plays (the clank, pitched
## down) and the line shows in the box; pressing again re-shows it and the box blinks once.
const REFUSE_VALVE_DEAD: String = "The valve is dead. Arm the breaker first."
const REFUSE_VALVE_TRIPPED: String = "The vent let go and the breaker tripped.\nReset it by the entrance."
const REFUSE_DOOR: String = "Sealed shut. Something hums behind it.\nThe valve beside it charges it."
const REFUSE_BREAKER_LIVE: String = "Already live. Crank the valve by the door."
const REFUSE_FUSE_LIT: String = "Fuse lit. Get clear of the door."
const REFUSE_SPENT: String = "No charge left. The door is down."
const REFUSE_REWINDING: String = "Not yet. The tank is still going back up."
const REFUSE_RELEASE_SPENT: String = "The tank is down on the sentry.\nThe exit bolt is by the door."
const REFUSE_EXIT_SENTRY: String = "Locked out until the sentry is down."
## Only a hand-made save can press the exit before the door is down: the sealed door blocks the way.
const REFUSE_EXIT_DOOR: String = "Bolted. The sealed door comes first."
const REFUSE_CLUNK_DB: float = -8.0
const REFUSE_CLUNK_PITCH: float = 0.42
## The box's blink when a refusal is pressed again: down to this opacity and back.
const BOX_BLINK_ALPHA: float = 0.35
const BOX_BLINK_SECONDS: float = 0.16
## Walking into the sealed door: a dull metal thud (the thud, pitched down), and the engineer's body
## gives this far back and returns. The body counts as against the door within DOOR_BUMP_SLOP of its face.
const DOOR_THUD_DB: float = -6.0
const DOOR_THUD_PITCH: float = 0.62
const DOOR_RECOIL_PX: float = 3.0
const DOOR_RECOIL_SECONDS: float = 0.14
const DOOR_BUMP_SLOP: float = 1.5
## What WOLF says once he has read the gauge on entry, and again on Continue from junction autosave A:
## the breaker is not armed yet either time, so his warning is about the door, not a live line.
const WOLF_DOOR_WARNING: String = "WOLF: When the door goes, don't be standing in front of it."
const JUNCTION_RESTORE_A_LINE: String = "Service junction restored. Arm the breaker by the entrance, then crank the valve.\n" + WOLF_DOOR_WARNING

## One switch for the visual effects: the depth pass (parallax, glows, haze, dust, reflections,
## grade) and the impact kit (shake, hit-stop, flash, rumble, particles), so a Settings toggle can
## follow. Sound is not on it: the sound bank always plays and the Audio sliders set its level.
@export var effects_enabled: bool = true:
	set(value):
		effects_enabled = value
		if is_node_ready():
			_apply_effects()
## Leaving the app or losing window focus mid-play pauses the game; capture and review drivers switch this off.
@export var auto_pause_on_focus_loss: bool = true

@onready var corridor_depth: RoomDepth = $CorridorDepth
@onready var post_grade: ColorRect = $PostProcess/Grade
@onready var human: M0Actor = $Human
@onready var wolf: M0Actor = $Wolf
@onready var relay_spark: Line2D = $RelaySpark
@onready var intro_gate: Sprite2D = $IntroGate
@onready var intro_camera: Camera2D = $IntroCamera
@onready var intro_director: Sprite2D = $IntroDirector
@onready var intro_alarm: ColorRect = $CanvasLayer/IntroAlarm
@onready var intro_fade: ColorRect = $CanvasLayer/IntroFade
@onready var purge_terminal_art: Sprite2D = $PurgeTerminalArt
@onready var breaker_art: Sprite2D = $BreakerArt
@onready var relay_art: Sprite2D = $RelayArt
@onready var checkpoint_art: Sprite2D = $CheckpointArt
@onready var breaker_status_light: ColorRect = $BreakerStatusLight
@onready var relay_status_light: ColorRect = $RelayStatusLight
@onready var door_shape: CollisionShape2D = $Door/CollisionShape2D
@onready var door_visual: ColorRect = $Door/Visual
@onready var top_card: Panel = $CanvasLayer/TopBar
@onready var hud: Label = $CanvasLayer/TopBar/HUD
@onready var bottom_bar: Panel = $CanvasLayer/BottomBar
@onready var dialogue_accent: ColorRect = $CanvasLayer/BottomBar/Accent
@onready var speaker: Label = $CanvasLayer/BottomBar/Speaker
@onready var speaker_rule: ColorRect = $CanvasLayer/BottomBar/SpeakerRule
@onready var story: Label = $CanvasLayer/BottomBar/Story
@onready var context_hint: Panel = $CanvasLayer/ContextHint
@onready var context_hint_text: Label = $CanvasLayer/ContextHint/Text
@onready var tutorial_prompt: Panel = $CanvasLayer/TutorialPrompt
@onready var tutorial_text: Label = $CanvasLayer/TutorialPrompt/Text
@onready var pause_button: Button = $CanvasLayer/PauseButton
@onready var touch_controls: Control = $CanvasLayer/TouchControls
@onready var touch_left: Button = $CanvasLayer/TouchControls/Left
@onready var touch_right: Button = $CanvasLayer/TouchControls/Right
@onready var touch_use: Button = $CanvasLayer/TouchControls/Use
@onready var touch_choice_1: Button = $CanvasLayer/TouchControls/Choice1
@onready var touch_choice_2: Button = $CanvasLayer/TouchControls/Choice2
@onready var pause_overlay: PauseOverlay = $CanvasLayer/PauseOverlay
@onready var menu_panel: Panel = $CanvasLayer/PauseOverlay/Panel
@onready var pause_menu: Control = $CanvasLayer/PauseOverlay/Panel/PauseMenu
@onready var settings_menu: GameSettings = $CanvasLayer/PauseOverlay/Panel/SettingsMenu
@onready var resume_button: Button = $CanvasLayer/PauseOverlay/Panel/PauseMenu/ResumeButton
@onready var settings_button: Button = $CanvasLayer/PauseOverlay/Panel/PauseMenu/SettingsButton
@onready var settings_back_button: Button = $CanvasLayer/PauseOverlay/Panel/SettingsMenu/BackButton
@onready var fps_options: OptionButton = $CanvasLayer/PauseOverlay/Panel/SettingsMenu/FPSOptions
@onready var resolution_options: OptionButton = $CanvasLayer/PauseOverlay/Panel/SettingsMenu/ResolutionOptions
@onready var fullscreen_toggle: CheckButton = $CanvasLayer/PauseOverlay/Panel/SettingsMenu/FullscreenToggle
@onready var settings_note: Label = $CanvasLayer/PauseOverlay/Panel/SettingsMenu/SettingsNote
@onready var title_screen: ColorRect = $CanvasLayer/TitleScreen
@onready var title_mark: TextureRect = $CanvasLayer/TitleScreen/LogoMark
@onready var title_line: ColorRect = $CanvasLayer/TitleScreen/TitleLine
@onready var title_logo: Label = $CanvasLayer/TitleScreen/GameTitle
@onready var new_game_button: Button = $CanvasLayer/TitleScreen/NewGameButton
@onready var continue_button: Button = $CanvasLayer/TitleScreen/ContinueButton
@onready var continue_note: Label = $CanvasLayer/TitleScreen/ContinueNote
## The version number under CHANGELOG (the number only, no wording; auto-translate off in the scene).
@onready var title_version: Label = $CanvasLayer/TitleScreen/VersionLabel
@onready var credits_button: Button = $CanvasLayer/TitleScreen/CreditsButton
@onready var credits_screen: ColorRect = $CanvasLayer/TitleScreen/CreditsScreen
@onready var credits_body: RichTextLabel = $CanvasLayer/TitleScreen/CreditsScreen/CreditsBody
@onready var credits_back_button: Button = $CanvasLayer/TitleScreen/CreditsScreen/CreditsBackButton
@onready var credits_pause_button: Button = $CanvasLayer/TitleScreen/CreditsScreen/CreditsPauseButton
@onready var changelog_button: Button = $CanvasLayer/TitleScreen/ChangelogButton
@onready var changelog_screen: ColorRect = $CanvasLayer/TitleScreen/ChangelogScreen
@onready var changelog_body: RichTextLabel = $CanvasLayer/TitleScreen/ChangelogScreen/ChangelogBody
@onready var changelog_back_button: Button = $CanvasLayer/TitleScreen/ChangelogScreen/ChangelogBackButton
@onready var changelog_online_button: Button = $CanvasLayer/TitleScreen/ChangelogScreen/ChangelogOnlineButton

var state: M0State = M0State.new()
var save_path: String = M0State.SAVE_PATH
var settings_path: String = "user://settings.cfg"
var touch_enabled: bool = OS.has_feature("ios") or OS.has_feature("android")
var controller_active: bool = false
var title_open: bool = true
## The title control a menu last meant to focus, so a later key press after touch lands there.
var title_focus_return: Control = null
var intro_active: bool = false
var intro_step: int = 0
var intro_tween: Tween
var menu_tween: Tween
var backdrop_tween: Tween
var top_card_tween: Tween
var last_top_card_key: String = ""
var chapter_close_active: bool = false
var chapter_tween: Tween
var tutorial_step: int = 2
## Where the tutorial prompt stands: under_card, card_place, bottom or waiting (hidden behind a box; see _tutorial_prompt_place).
var tutorial_prompt_slot: StringName = &"under_card"
var waiting_for_choice: bool = false
var choice_context: String = ""
var relay_refused: bool = false
var wolf_heading_to_relay: bool = false
var status_line: String = "WOLF: I heard the Director's plan for me. I woke myself. He wants me to hunt people he calls threats.":
	set(value):
		# A new line, or the same one said again after its box cleared, starts at its first box.
		if value != status_line or dialogue_cleared:
			dialogue_key = ""
			dialogue_restart = true
		# Only the opening lines wait for the first step; anything said instead shows at once.
		if not value in opening_lines:
			opening_lines_held = false
		status_line = value
var door_tween: Tween
var wolf_reaction_tween: Tween
var relay_spark_tween: Tween
var records_room: RecordsRoom
var junction_room: JunctionRoom
## The shared light, shadow and particle textures every room builds from, open while Main is in the
## tree.
var fx_kit: FxKit = FxKit.new()
## The Service Junction's coolant line; transient, reset by every scene sync.
var pressure_line: PressureLine = PressureLine.new()
## True while WOLF runs ahead to read the junction's LINE gauge on entry, and how long he has stood
## reading it.
var wolf_scouting: bool = false
var seam_read_seconds: float = 0.0
## How long the engineer's junction entry line still needs before WOLF's warning may replace it.
var junction_entry_hold: float = 0.0
## The junction's hint ladder: seconds counted towards it and the steps given (JUNCTION_LADDER_SECONDS);
## 3 once the chain has been said, the breaker armed, or the room restored from a checkpoint.
var ladder_seconds: float = 0.0
var ladder_step: int = 3
## Ladder step T1: WOLF holds where he stands, looking at the breaker, this much longer.
var wolf_look_x: float = -1.0
var wolf_look_remaining: float = 0.0
## Walking into the sealed door: held against it (one bump until they step off), and whether this visit
## has said why yet (only the first bump does).
var door_bump_latched: bool = false
var door_bump_said: bool = false
## Whether the engineer last came to rest from the sealed door's face: the settle slides them off the
## valve's body to its side, and USE there is still the door's until they move (_door_use).
var door_faced: bool = false
var box_blink_tween: Tween
var door_recoil_tween: Tween
## The junction's purge sentry and the arm over its lane; transient, reset by every scene sync.
var sentry_brain: SentryBrain = SentryBrain.new()
var drop_arm: DropArm = DropArm.new()
## How the tank gets dropped this attempt: empty until asked at the rubble line, then "wolf" (he
## chose to draw it), "refused" (he would not) or "alone" (the engineer times it).
var lane_choice: String = ""
## True while WOLF, by his own choice, draws the sentry onto the floor mark.
var wolf_baiting: bool = false
## A missed drop while he was drawing it: he breaks off and does not offer again this attempt.
var wolf_broke_off: bool = false
## He broke off already past the sentry: he holds by the exit hatch rather than cross back under the
## tank, and the sentry's patrol turns short of him (SentryBrain.far_x).
var wolf_holding_far_end: bool = false
## Right after the engineer asks WOLF to draw the sentry, they hold at the rubble line while he dashes
## past them into the lane, so he never runs through them at the TANK RELEASE.
var engineer_waits_for_wolf: bool = false
## The engineer reached the rubble line while the blast's line still had a box to come: they hold
## there, the box comes up at once, and WOLF asks how to bring the sentry down once it has been up its
## reading time (_hold_for_lane_question).
var lane_question_held: bool = false
## Seconds until the blast wakes the sentry, or 0.
var sentry_wake_remaining: float = 0.0
## The exit bolt: locked until the sentry is down, charging through its whine, then open.
var bolt_state: StringName = &"locked"
var bolt_charge_remaining: float = 0.0
var servo_tween: Tween
## WOLF's body sprite at rest, as the scene sets it; ducking under the junction's hung tank squashes it
## for a moment (_sync_wolf_leap).
var wolf_sprite_scale: Vector2 = Vector2.ONE
## WOLF's floor reflection and its contact line at rest (fix round 2: his step forward of the valve moves
## both with his feet, JunctionRoom.wolf_valve_step).
var wolf_reflection: FloorReflection
var wolf_reflection_floor_y: float = 0.0
var impact: Impact
var sfx_bank: SfxBank
var relay_sparks: CPUParticles2D
var door_dust: CPUParticles2D
var gate_dust: CPUParticles2D
## True from a knockdown until the last autosave is back; the engineer has no controls meanwhile.
var fail_active: bool = false
var fail_tween: Tween
## Seconds since the knockdown's hit, its card (the cause), and whether RETRY has been pressed.
var fail_age: float = 0.0
var fail_reason: String = ""
var retrying: bool = false
## After RETRY the room fades back in with the controls still off (RETRY_FADE_IN_SECONDS).
var retry_fading_in: bool = false
## The standing engineer's image and scale, put back when they get up, and their floor reflection.
var human_texture: Texture2D
var human_sprite_scale: Vector2 = Vector2.ONE
var human_reflection: FloorReflection
## The collapse in progress: the way the body falls (1 right, -1 left), where the boots go from and to
## (world x), and the way the engineer faced before it, given back when they get up.
var collapse_fall: float = 1.0
var collapse_from_x: float = 0.0
var collapse_to_x: float = 0.0
var collapse_flip: bool = false
var collapsed: bool = false
## The state at the start of the current beat, for a knockdown before any checkpoint exists.
var beat_snapshot: Dictionary = {}
var hold_use: HoldUse = HoldUse.new()
## Settings' TOGGLE HOLDS: one press of interact at a crank starts it turning and keeps it turning
## until a second press, a move or the crank is done, on the keyboard, a controller and touch alike.
var hold_toggle: bool = false
## With TOGGLE HOLDS on, true while a press has the crank turning.
var crank_latched: bool = false
var credits_paused: bool = false
## The exported changelog as loaded at title time; empty when the file is missing.
var changelog_text: String = ""
var save_error: String = ""
var save_error_context: String = ""
## True while the last autosave failed to write. The beat snapshot then holds that autosave: a
## knockdown restores it instead of the older file on disk, and the next USE retries the write.
var save_pending: bool = false
var floor_reflections: Array[FloorReflection] = []
var breaker_status_glow: Sprite2D
var relay_status_glow: Sprite2D
## The seal's wall's near end (SEAL_FRONT), drawn over the actors.
var door_lip: Sprite2D
## The cross-wall's face round the seal (behind the mid plate), and the hood with the far guide over
## the curtain.
var seal_wall: Sprite2D
var seal_head: Sprite2D
## The seal's live status lamp (its halo lit only while open).
var seal_lamp: DoorKit.Lamp
## The seal's rolling curtain: shut, winding up into its hood while the seal opens, parked open.
var seal_leaf: SealLeaf
## The inner blast leaf behind the roller, sliding back into its wall pocket while the seal opens
## (parked in its pocket, out of sight, so this draws only while it moves).
var blast_leaf: BlastLeaf
## True from the moment the seal starts to open until its curtain is up in the hood.
var seal_opening: bool = false
## WOLF stays on the live contact, by his own choice, until the seal has landed.
var wolf_holding_relay: bool = false
## Where the engineer is being stepped to (clear of the relay while WOLF takes it, to the bypass's
## crank spot, or beside a station they used), or -1.
var engineer_step_x: float = -1.0
## The x the engineer turns to face on reaching engineer_step_x, or -1 to keep their facing.
var engineer_face_x: float = -1.0
## Seconds the "Checkpoint saved." hint has left; 0 when none.
var checkpoint_toast_remaining: float = 0.0
## True while the engineer and WOLF walk out through the hatch, between the closing beat and the
## END OF SLICE card; the engineer starts walking (hatch_exit_engineer_walking) once WOLF has gone in.
var hatch_exit_walking: bool = false
var hatch_exit_engineer_walking: bool = false
## True while the engineer walks out through the Records exit, from the USE until they are through.
var records_exit_walking: bool = false
## Leaving Records: the engineer is through and out of view; the junction waits for WOLF (seconds waited).
var records_exit_engineer_out: bool = false
var records_exit_wait: float = 0.0
## True while the END OF SLICE card is up; any confirm, Back or Pause goes on to the title.
var end_card_active: bool = false
var end_card: ColorRect
var end_card_rows: VBoxContainer
var end_card_button: Button
## Fades the corridor's station names at the edge of the view, like the other rooms' (EdgeFader).
var corridor_label_fader: EdgeFader
## The corridor's MANUAL BYPASS beside the relay, its crank count and whether it is venting coolant.
var bypass_handle: BypassHandle
var bypass_ticks: int = 0
## The crank frame shown (0 = A, 1 = B), or -1 while the engineer shows their usual sprite.
var crank_frame: int = -1
## Seconds left of the B (push) frame after the last crank tick.
var crank_push_left: float = 0.0
var bypass_venting: bool = false
var bypass_alarm_remaining: float = 0.0
var bypass_was_holding: bool = false
## Seconds the engineer's name card has left on screen before the location card follows; 0 when gone.
var name_card_remaining: float = 0.0
## WOLF's purge stakes line has been said this run.
var stakes_spoken: bool = false
## The boxes still to come of a line said in several boxes (_say), the box now up (the queue's own, or
## a line that cut in), how long it stays before the next, the chapter the boxes belong to and whether a
## choice has opened since. A line that cuts in only delays the rest: they come back once it has been
## up its own reading time.
var box_queue: Array[String] = []
var box_queue_line: String = ""
var box_queue_seconds: float = 0.0
var box_queue_chapter: String = ""
var box_queue_choice_seen: bool = false
## The box the queue itself put up (_say, _next_box_now), not a line that cut in: an aside that takes the
## box before it has been read puts it back at the front of the queue (_aside).
var box_queue_shown: String = ""
## A line put back by an aside part way through its boxes (_aside), and the box it comes back at, so
## the boxes already read are not shown again.
var box_resume_line: String = ""
var box_resume_index: int = 0
## The boxes status_line is shown as (DialogueBoxes.split), the one on screen and how long it has been
## up. The last box clears once it has been read and the engineer moves on (dialogue_cleared, STORY-8).
## dialogue_key is what they were split from (the line as shown, the engineer's name and the text size).
var dialogue_boxes: Array[String] = []
var dialogue_index: int = 0
var dialogue_age: float = 0.0
var dialogue_cleared: bool = false
var dialogue_key: String = ""
var dialogue_restart: bool = true
## The width the words on screen wrap at (canvas px), and the box, size and column it was measured
## for (_story_wrap_width measures again only when that key changes).
var story_wrap: float = 0.0
var story_wrap_key: String = ""
## At first control the opening lines wait (TEACH-7): the name card and the move prompt come first,
## the rest of the tutorial after the first step, and the lines once the name card has gone.
var opening_lines_held: bool = false
## The opening lines' boxes after control (the trust line's two, then WOLF and the engineer).
var opening_lines: Array[String] = []
## The speaker column's width and the text size and name it was measured for (_speaker_column_width).
var speaker_column: float = 0.0
var speaker_column_key: String = ""

## WOLF's standing piece and the scale it is drawn at (main.tscn Wolf/BodySprite uses both; the
## WOLF art checks in wolf_space_test and sentry_test read them from here). The piece (1028x549) was
## painted at 8 px per world px over a guide 12 % larger than the earlier sprite's painted body, so it
## is not drawn at 1/8: WOLF keeps about the size he was drawn before (the default for the open
## WOLF-size question, 2026-10-16, until Nathanial picks another). The earlier body ran 56 px behind
## his origin and 59.1 ahead (115.1 x 61.6 world px); the piece is cut to his outline and centred, so
## it reaches as far each way, and 0.1089 keeps his tail tip where it was (55.97 px back, inside the
## Service Junction's right edge at his spot by the exit, WOLF_BAIT_X): 111.9 x 59.8 world px, 3 %
## smaller than before.
const WOLF_ART_PATH: String = "res://assets/characters/wolf-stand.png"
const WOLF_ART_SCALE: float = 0.1089
## The sprite's centre from WOLF's origin: his feet (the piece's bottom row) stand where the earlier
## art's did, 15.4 world px below the origin (-14.5 + 549 / 2 * WOLF_ART_SCALE). x stays 0 so he
## mirrors in place.
const WOLF_SPRITE_REST: Vector2 = Vector2(0.0, -14.5)
## WOLF's painted feet sit this far below his sprite's centre, in the art's own pixels (the piece is
## cut to its outline: half its 549 rows).
const WOLF_FEET_BELOW_CENTRE: float = 274.5
## WOLF's drawn height at rest, from the tips of his ears to his feet, in world px (the piece's 549
## rows at WOLF_ART_SCALE).
const WOLF_DRAWN_HEIGHT: float = 549.0 * WOLF_ART_SCALE
const GAMEPLAY_ZOOM: float = 1.35
const GAMEPLAY_VIEW_WIDTH: float = 960.0 / GAMEPLAY_ZOOM
## The play camera's resting height. At 1.35 it puts the floor (y 440) 27 px above the context hint
## (screen y 405) while the ceiling lamps (y ~188) and the junction's arm rail (y 196) stay in view.
const GAMEPLAY_CAMERA_Y: float = 360.0
## With the touch arrows and USE on screen (their tops at screen y 345) the play camera sits lower,
## so feet and station bases on the floor land at screen y 335, above the buttons, instead of
## behind them. The ceiling lamps leave the top of the view; the far plate still covers it. The touch
## answers take the buttons' place at the bottom during a choice, so the camera stays put.
const GAMEPLAY_CAMERA_Y_TOUCH: float = 392.0
## The junction's close (the only chapter-close shot: Records keeps control while its closing lines
## run) frames its exit door whole and off the edge of the view (review r1): its right
## edge runs on to JUNCTION_CLOSE_RIGHT, past the near jamb (JunctionRoom.EXIT_NEAR_JAMB_X) and the
## wall's column into the passage beyond, so the doorway they walk out through sits inside the frame,
## and the view is closer than play (zoom 1.62), its left edge (x ~438) just left of the DOOR DOWN
## placard, with the floor about 70 % down the view, above the dialogue card.
const JUNCTION_CLOSE_RIGHT: float = JunctionRoom.EXIT_VIEW_RIGHT
const JUNCTION_CLOSE_ZOOM: float = 1.62
const JUNCTION_CLOSE_CAMERA: Vector2 = Vector2(JUNCTION_CLOSE_RIGHT - 480.0 / JUNCTION_CLOSE_ZOOM, 373.0)
## Menu cards fade and slide in over this long; short enough never to hold up input or players who want little motion.
const MENU_REVEAL_SECONDS: float = 0.12
const MENU_REVEAL_OFFSET: Vector2 = Vector2(0.0, 10.0)


## Fades [member labels] out as they reach the edge of the view (JunctionRoom.fade_at_view_edge) while
## they show. It is added after the camera, so it reads the view the camera has just set.
class EdgeFader:
	extends Node
	var labels: Array[Label] = []

	func _process(_delta: float) -> void:
		if not labels.is_empty() and labels[0].is_visible_in_tree():
			JunctionRoom.fade_at_view_edge(labels, get_viewport())


## The FxKit opens first, so the corridor's RoomDepth (in the scene) builds from its cache in its own
## _ready, before this one's; it closes, letting go of what it holds, when Main leaves.
func _enter_tree() -> void:
	FxKit.open(fx_kit)


func _exit_tree() -> void:
	FxKit.close(fx_kit)


## The game's version as project.godot states it (for example "0.15.0"), or "" if the setting is
## missing. Read at run time so the title, the F12 capture and an exported build agree with no copy.
static func game_version() -> String:
	return str(ProjectSettings.get_setting(VERSION_SETTING, ""))


func _ready() -> void:
	get_window().title = str(ProjectSettings.get_setting(NAME_SETTING, ""))
	title_version.text = game_version()
	_install_inputs()
	_setup_settings()
	_setup_impact()
	_setup_touch_controls()
	pause_button.pressed.connect(_on_pause_button)
	pause_overlay.resume_requested.connect(_resume_game)
	pause_overlay.back_requested.connect(_on_settings_back)
	pause_overlay.input_seen.connect(_note_input_device)
	resume_button.pressed.connect(_resume_game)
	settings_button.pressed.connect(_show_settings)
	$CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton.pressed.connect(_on_title_button)
	$CanvasLayer/TitleScreen/SettingsButton.pressed.connect(_show_title_settings)
	settings_back_button.pressed.connect(_show_pause_menu)
	_build_end_card()
	# Every menu button, including the ones Settings builds, shares the same hover, focus and press motion.
	for node: Node in $CanvasLayer.find_children("*", "BaseButton", true, false):
		UIMotion.attach(node as BaseButton)
	records_room = RecordsRoom.new()
	records_room.z_index = 1
	add_child(records_room)
	junction_room = JunctionRoom.new()
	junction_room.z_index = 1
	junction_room.reduce_motion = impact.reduce_motion
	add_child(junction_room)
	for depth: RoomDepth in _room_depths():
		depth.reduce_motion = impact.reduce_motion
	# The knockdown cards name the engineer, like the narration.
	junction_room.vent_hazard.contact.connect(func(source: Hazard) -> void: _fail_beat(source.reason % _first_name()))
	junction_room.cloud_hazard.contact.connect(func(source: Hazard) -> void: _fail_beat(source.reason % _first_name()))
	junction_room.hatch_opened.connect(_hatch_opened)
	human.z_index = ACTOR_Z
	wolf.z_index = ACTOR_Z
	# At the same depth the later sibling draws on top: WOLF goes first so the engineer is always in
	# front, and a WOLF walking past him (dimmed by M0Actor) reads as passing behind.
	move_child(wolf, human.get_index())
	wolf.keep_clear_of = human
	wolf_sprite_scale = wolf.body_sprite.scale
	# His piece is painted with its lights off; the eye and seam lights are drawn over it in code.
	WolfLights.attach(wolf.body_sprite)
	_setup_corridor_door()
	_setup_bypass()
	_setup_corridor_labels()
	_setup_particles()
	# The door end's light and contact shadows are painted into its plates: its stations and seal
	# cast no runtime floor reflection.
	human_texture = human.body_sprite.texture
	human_sprite_scale = human.body_sprite.scale
	for grounded: Sprite2D in [human.body_sprite, wolf.body_sprite, intro_director, breaker_art]:
		floor_reflections.append(FloorReflection.attach(grounded))
	human_reflection = floor_reflections[0]
	wolf_reflection = floor_reflections[1]
	wolf_reflection_floor_y = wolf_reflection.floor_y
	floor_reflections.append_array(records_room.floor_reflections)
	floor_reflections.append_array(junction_room.floor_reflections)
	# Each room's near edge pieces fade back while they cover the engineer or WOLF.
	for depth: RoomDepth in _room_depths():
		depth.occluders = [human.body_sprite, wolf.body_sprite]
	# The corridor's breaker is the junction's machine: its light lies on the same lamp bar.
	var breaker_light: Rect2 = Rect2(JunctionRoom.BREAKER_LIGHT_AT.position + Vector2(breaker_art.position.x, 0.0), JunctionRoom.BREAKER_LIGHT_AT.size)
	breaker_status_light.position = breaker_light.position
	breaker_status_light.size = breaker_light.size
	breaker_status_glow = _attach_status_glow(breaker_status_light)
	# The purge display stands on its foot at its real size (main.tscn holds the same place and scale
	# for the editor).
	purge_terminal_art.scale = Vector2.ONE * PURGE_DISPLAY_SCALE
	purge_terminal_art.position = Vector2(PURGE_DISPLAY_X, PURGE_DISPLAY_FOOT_Y - purge_terminal_art.texture.get_height() * purge_terminal_art.scale.y * 0.5)
	PropScreen.attach(purge_terminal_art, "PurgeScreen", PURGE_DISPLAY_SCREEN, RecordsRoom.PURGE_RED)
	relay_status_glow = _attach_status_glow(relay_status_light)
	_apply_text_size()
	_apply_effects()
	_sync_scene()
	_refresh_ui()
	_refresh_continue()
	new_game_button.pressed.connect(_new_game)
	continue_button.pressed.connect(_on_continue_pressed)
	credits_button.pressed.connect(_show_credits)
	credits_back_button.pressed.connect(_hide_credits)
	credits_pause_button.pressed.connect(_toggle_credits_pause)
	credits_body.gui_input.connect(_on_credits_body_input)
	changelog_button.pressed.connect(_show_changelog)
	changelog_back_button.pressed.connect(_hide_changelog)
	changelog_online_button.pressed.connect(_open_changelog)
	changelog_body.gui_input.connect(_on_changelog_body_input)
	_load_changelog()
	_grab_menu_focus(_title_first_button())
	title_mark.modulate = Color(1, 1, 1, 0)
	title_line.modulate = Color(1, 1, 1, 0)
	title_logo.modulate = Color(1, 1, 1, 0)
	var reveal: Tween = create_tween()
	reveal.tween_property(title_mark, "modulate", Color.WHITE, 0.4)
	reveal.tween_property(title_line, "modulate", Color.WHITE, 0.25)
	reveal.tween_property(title_logo, "modulate", Color.WHITE, 0.35)
	_setup_debug_tools()


func _refresh_continue() -> void:
	var loaded: M0State = M0State.load_from_disk(save_path)
	var saved: bool = loaded != null
	var finished: bool = saved and loaded.junction_cleared
	continue_button.disabled = not saved
	# A finished slice has nothing left to continue: the button offers a fresh run (decision D). NEW GAME
	# would do the same, so PLAY AGAIN stands alone across both buttons' row.
	continue_button.text = PLAY_AGAIN_TEXT if finished else CONTINUE_TEXT
	new_game_button.visible = not finished
	continue_button.offset_left = new_game_button.offset_left if finished else TITLE_CONTINUE_LEFT
	if finished and new_game_button.has_focus():
		_grab_menu_focus(continue_button)
	var reason: String = FINISHED_NOTE if finished else ""
	if not saved:
		reason = UNREADABLE_CHECKPOINT_NOTE if FileAccess.file_exists(save_path) else NO_CHECKPOINT_NOTE
	continue_note.text = reason
	continue_button.tooltip_text = reason


## The title's first button: NEW GAME, or PLAY AGAIN when a finished slice has hidden NEW GAME.
func _title_first_button() -> Button:
	return new_game_button if new_game_button.visible else continue_button


## The title's Continue: the saved checkpoint, or on a finished slice (PLAY AGAIN) a fresh run, which,
## like New Game, keeps the old save until the new run reaches its first SAFE POINT.
func _on_continue_pressed() -> void:
	var loaded: M0State = M0State.load_from_disk(save_path)
	if loaded != null and loaded.junction_cleared:
		_new_game()
		return
	_load_game()


## The full changelog lives on the website; the in-game screen shows the same text exported to plain text.
func _open_changelog() -> void:
	if OS.shell_open(CHANGELOG_URL) != OK:
		changelog_online_button.text = "LINK UNAVAILABLE"


func _load_changelog() -> void:
	changelog_text = ""
	if FileAccess.file_exists(CHANGELOG_PATH):
		var file: FileAccess = FileAccess.open(CHANGELOG_PATH, FileAccess.READ)
		if file != null:
			changelog_text = file.get_as_text().strip_edges()
	changelog_body.text = CHANGELOG_UNAVAILABLE if changelog_text.is_empty() else _changelog_bbcode(changelog_text)


## "== Heading ==" lines become cyan headings and "-- Heading --" lines bold ones; everything else is shown as written.
static func _changelog_bbcode(text: String) -> String:
	var lines: PackedStringArray = PackedStringArray()
	for raw: String in text.split("\n"):
		var line: String = raw.replace("[", "[lb]")
		if line.begins_with("== ") and line.ends_with(" =="):
			lines.append("[color=#73DDF5][b]%s[/b][/color]" % line.substr(3, line.length() - 6))
		elif line.begins_with("-- ") and line.ends_with(" --"):
			lines.append("[b]%s[/b]" % line.substr(3, line.length() - 6))
		else:
			lines.append(line)
	return "\n".join(lines)


func _show_changelog() -> void:
	_show_title_overlay(changelog_screen)
	changelog_body.get_v_scroll_bar().value = 0.0
	_grab_menu_focus(changelog_back_button)


func _hide_changelog() -> void:
	_hide_title_overlay(changelog_screen)
	_grab_menu_focus(changelog_button)


## The seal's pieces, back to front (see SEAL_BACK): the doorway behind the mid plate, the curtain,
## hood, sign and door light over it, and the wall's near end with the status lamp over the actors.
func _setup_corridor_door() -> void:
	# The doorway belongs to the corridor's plates: it shows whenever they do (the opening too).
	blast_leaf = BlastLeaf.new(SEAL_BLAST_LEAF)
	blast_leaf.visible = false
	seal_wall = DoorKit.doorway(corridor_depth.behind, "CorridorSeal", SEAL_HOLE, SEAL_HOLE_LIGHT, SEAL_BACK, SEAL_BACK_AT, 1.0, blast_leaf, SEAL_POOL, SEAL_GRAZE, SEAL_WALL, SEAL_WALL_AT)
	# Over the mid plate (after it in the room, on its layer), under the stations and the actors.
	var over: Node2D = Node2D.new()
	over.name = "CorridorSealOver"
	over.z_as_relative = false
	over.z_index = RoomDepth.Z_MID
	corridor_depth.add_child(over)
	seal_leaf = SealLeaf.new(SEAL_CURTAIN)
	over.add_child(seal_leaf)
	seal_head = DoorKit.piece(over, SEAL_HEAD, SEAL_HEAD_AT, "CorridorSealHead")
	DoorKit.exit_sign(over, SEAL_SIGN, 1.0)
	DoorKit.door_light(over, SEAL_DOOR_LIGHT)
	# The wall's near end and the lamp over the actors, always opaque.
	door_lip = DoorKit.piece(self, SEAL_FRONT, SEAL_FRONT_AT, "CorridorDoorFront")
	door_lip.z_index = KNOCKDOWN_Z
	door_lip.visible = false
	seal_lamp = DoorKit.lamp(self, "SealLamp", CORRIDOR_SEAL_LAMP, Palette.LAMP_SHUT)
	seal_lamp.z_index = KNOCKDOWN_Z
	seal_lamp.visible = false


## The MANUAL BYPASS on the relay's right, with the relay's COOLANT FAULT tag (a touch left of the
## relay's centre so it clears the bypass plate); it draws with the stations, behind the actors.
func _setup_bypass() -> void:
	bypass_handle = BypassHandle.new()
	bypass_handle.z_index = 1
	bypass_handle.reduce_motion = impact.reduce_motion
	add_child(bypass_handle)
	bypass_handle.place(BYPASS_WHEEL, RELAY_X - 3.0)


## The corridor's station names, each sized to its text and centred where the scene put it, so it fades
## by the text at the edge of the view as the junction's and Records Access's names do.
func _setup_corridor_labels() -> void:
	corridor_label_fader = EdgeFader.new()
	corridor_label_fader.name = "CorridorLabelFader"
	for label: Label in [$BreakerLabel, $RelayLabel, $CheckpointLabel]:
		var center_x: float = label.position.x + label.size.x * 0.5
		label.size = Vector2.ZERO
		label.size = label.get_combined_minimum_size()
		label.position.x = center_x - label.size.x * 0.5
		corridor_label_fader.labels.append(label)
	add_child(corridor_label_fader)


## Every depth effect hangs off this one switch; off, the rooms keep their far and mid plates, unmoving.
func _apply_effects() -> void:
	impact.enabled = effects_enabled
	corridor_depth.effects_enabled = effects_enabled
	records_room.depth.effects_enabled = effects_enabled
	junction_room.depth.effects_enabled = effects_enabled
	post_grade.visible = effects_enabled
	for reflection: FloorReflection in floor_reflections:
		reflection.enabled = effects_enabled
	# The junction's door seam glow stays: it is the pressure readout, not dressing.
	for glow: Sprite2D in [breaker_status_glow, relay_status_glow, records_room.purge_glow, records_room.mirror_glow, junction_room.breaker_glow]:
		glow.visible = effects_enabled
	junction_room.sentry.visual.glow_allowed = effects_enabled


## Every room's layered set, corridor first.
func _room_depths() -> Array[RoomDepth]:
	return [corridor_depth, records_room.depth, junction_room.depth]


## Each room's lockdown beacons settle once its route is cleared (the safe point reached, the first
## copy secured, the service line cleared) and pulse again for a save from before that. Driven by
## the state alone, so Continue and a knockdown show the same lights; [param animate] fades them
## when the route is cleared in play.
func _sync_room_lights(animate: bool = false) -> void:
	corridor_depth.set_lockdown_cleared(state.checkpoint_reached, animate)
	records_room.depth.set_lockdown_cleared(state.chapter_complete, animate)
	junction_room.depth.set_lockdown_cleared(state.junction_cleared, animate)


## The impact kit and the sound bank. The bank is built after Settings so its players land on the
## Effects bus the sliders drive; Reduced Motion follows the Settings toggle.
func _setup_impact() -> void:
	impact = Impact.new()
	impact.name = "Impact"
	impact.setup(intro_camera, intro_fade, intro_alarm)
	impact.reduce_motion = settings_menu.reduced_motion.button_pressed
	settings_menu.reduced_motion_changed.connect(_on_reduced_motion_changed)
	hold_toggle = settings_menu.hold_toggle.button_pressed
	settings_menu.hold_toggle_changed.connect(_on_hold_toggle_changed)
	settings_menu.text_size_changed.connect(func(_factor: float) -> void: _apply_text_size())
	add_child(impact)
	sfx_bank = SfxBank.new()
	sfx_bank.name = "SfxBank"
	add_child(sfx_bank)


## Reduced Motion reaches the impact kit, the junction's seam strobe, the bypass's fault-tag pulse and
## the rooms' lamp flicker.
func _on_reduced_motion_changed(on: bool) -> void:
	impact.reduce_motion = on
	junction_room.reduce_motion = on
	bypass_handle.reduce_motion = on
	for depth: RoomDepth in _room_depths():
		depth.reduce_motion = on


## One-shot particle presets parked at the places that already answer the player: the relay
## contact, the seal's landing and the containment gate.
func _setup_particles() -> void:
	relay_sparks = FxPresets.place(FxPresets.sparks(), self, "", Vector2(601.0, 390.0), 3)
	door_dust = FxPresets.place(FxPresets.dust_burst(), self, "", Vector2(780.0, 436.0), 3, Vector2(30.0, 3.0))
	gate_dust = FxPresets.place(FxPresets.dust_burst(), self, "", Vector2(115.0, 438.0), 3, Vector2(70.0, 3.0))


## A small additive glow riding on a station status light; it takes the light's colour each refresh.
func _attach_status_glow(light: ColorRect) -> Sprite2D:
	var glow: Sprite2D = RoomDepth.make_glow(light.color, Vector2(64.0, 30.0), 0.75)
	glow.name = "Glow"
	glow.position = light.size * 0.5
	light.add_child(glow)
	return glow


func _update_gameplay_camera() -> void:
	var half_view: float = GAMEPLAY_VIEW_WIDTH * 0.5
	var touch_buttons: bool = touch_enabled and not controller_active
	intro_camera.position = Vector2(clampf(human.position.x, half_view, _view_right() - half_view), GAMEPLAY_CAMERA_Y_TOUCH if touch_buttons else GAMEPLAY_CAMERA_Y)


## The play view's right edge: the room's, except in the junction, where it runs on to show the exit
## door whole (its near jamb past x 960, the wall's column and the passage beyond), so the door the lines
## name is on screen before the bolt is popped as well as after (review r1).
func _view_right() -> float:
	if state.chapter_id == "junction":
		return JunctionRoom.EXIT_VIEW_RIGHT
	return 960.0


func _start_gameplay_camera() -> void:
	intro_camera.zoom = Vector2.ONE * GAMEPLAY_ZOOM
	_update_gameplay_camera()
	intro_camera.position_smoothing_enabled = true
	intro_camera.position_smoothing_speed = 4.0
	intro_camera.reset_smoothing()


func _process(delta: float) -> void:
	# The intro's full-screen alarm wash and fade cost a full-screen blend even when clear: they draw
	# only while they show something.
	intro_alarm.visible = intro_alarm.color.a > 0.0
	intro_fade.visible = intro_fade.color.a > 0.0
	if title_open:
		if credits_screen.visible and not credits_paused:
			credits_body.get_v_scroll_bar().value += delta * 18.0
		elif changelog_screen.visible:
			# The changelog never scrolls on its own; held up/down (keys, D-pad or stick) reads it at a steady pace.
			changelog_body.get_v_scroll_bar().value += Input.get_axis(&"ui_up", &"ui_down") * delta * CHANGELOG_SCROLL_SPEED
		return
	if intro_active:
		_tick_dialogue(delta)
		# A press shows the beat's next box, or after its last one goes on to the next beat.
		if Input.is_action_just_pressed(&"interact") and not _next_box():
			_advance_intro()
		_refresh_ui()
		return
	if end_card_active:
		if Input.is_action_just_pressed(&"interact"):
			_close_end_card()
		return
	_tick_engineer_step()
	_tick_records_walk_out(delta)
	if chapter_close_active:
		_tick_dialogue(delta)
		if Input.is_action_just_pressed(&"interact") and not _next_box():
			_finish_chapter_close()
		_refresh_ui()
		return
	_update_gameplay_camera()
	_advance_box_queue(delta)
	name_card_remaining = maxf(name_card_remaining - delta, 0.0)
	checkpoint_toast_remaining = maxf(checkpoint_toast_remaining - delta, 0.0)
	if state.chapter_id == "records" and wolf.autonomous_target_x == WOLF_MIRROR_X and absf(wolf.position.x - WOLF_MIRROR_X) <= 2.0:
		# At the mirror he faces the port, whichever way he walked in.
		wolf.body_sprite.flip_h = true
	if state.chapter_id == "junction" and state.door_blown and wolf.autonomous_target_x == JunctionRoom.WOLF_CLEAR_X and absf(wolf.position.x - JunctionRoom.WOLF_CLEAR_X) <= 2.0:
		# Held by the entrance after the blast until the engineer leaves his spot by the valve, he faces
		# them and the rubble: waiting, not leaving.
		wolf.body_sprite.flip_h = human.position.x < wolf.position.x
	if state.chapter_id == "junction" and state.door_blown and not state.sentry_down and wolf.autonomous_target_x == JunctionRoom.WOLF_RUBBLE_X and absf(wolf.position.x - JunctionRoom.WOLF_RUBBLE_X) <= 2.0:
		# Holding back by the valve, he faces the engineer, and so the rubble while they deal with the
		# sentry, even after breaking off, when he walked back in facing the entrance.
		wolf.body_sprite.flip_h = human.position.x < wolf.position.x
	if fail_active:
		# Knocked down: the card holds until RETRY, which it takes from RETRY_READY_SECONDS after the hit
		# (only a fresh press counts: the knockdown released every held action); nothing else reads input.
		fail_age += delta
		if _retry_ready() and Input.is_action_just_pressed(&"interact"):
			_retry()
		_tick_dialogue(delta)
		_refresh_ui()
		return
	var hold_station: StringName = _hold_station()
	var held_ticks: int = hold_use.advance(delta, _crank_held(hold_station), hold_station, _hold_tick_seconds(hold_station))
	_update_crank_pose(delta)
	if hold_use.started:
		_hold_started()
	_update_settle()
	if state.chapter_id == "junction":
		_tick_junction(delta)
		if fail_active:
			_refresh_ui()
			return
	elif state.chapter_id == "lockdown":
		_tick_corridor(delta, held_ticks)
	_show_hold()
	if tutorial_step == 0 and (Input.is_action_pressed(&"move_left") or Input.is_action_pressed(&"move_right")):
		tutorial_step = 1
		# The first step takes the name card away; the opening lines follow once it has faded.
		_dismiss_name_card()
	# The purge display is optional; reaching the breaker finishes the tutorial too.
	if tutorial_step < 2 and absf(human.position.x - 350.0) <= 52.0:
		tutorial_step = 2
	if waiting_for_choice:
		if Input.is_action_just_pressed(&"choice_1"):
			_answer_choice(1)
		elif Input.is_action_just_pressed(&"choice_2"):
			_answer_choice(2)
	elif Input.is_action_just_pressed(&"cycle_name"):
		state.cycle_name()
		status_line = "WOLF: %s. That name sounds like you." % state.human_name()
	elif Input.is_action_just_pressed(&"interact"):
		_interact()
	# The opening lines start after the first step, once no top card is up (one thing to read at a time).
	if opening_lines_held and tutorial_step >= 1 and name_card_remaining <= 0.0 and not top_card.visible:
		opening_lines_held = false
	_tick_dialogue(delta)
	_refresh_ui()


## Whether a crank is being worked this frame at [param station]: interact held down, or with TOGGLE
## HOLDS on, latched by one press and kept turning until a second press, a move, leaving the crank's
## reach or the crank being done (the station going away).
func _crank_held(station: StringName) -> bool:
	if not hold_toggle:
		crank_latched = false
		return human.controlled and Input.is_action_pressed(&"interact")
	if station.is_empty() or waiting_for_choice or Input.is_action_pressed(&"move_left") or Input.is_action_pressed(&"move_right"):
		crank_latched = false
	elif Input.is_action_just_pressed(&"interact"):
		crank_latched = not crank_latched
	return crank_latched and human.controlled


## Seconds of held USE per tick at [param station]: a valve turn, or a notch of the MANUAL BYPASS.
static func _hold_tick_seconds(station: StringName) -> float:
	return BypassHandle.TICK_SECONDS if station == &"bypass" else PressureLine.TURN_SECONDS


## The press frame of a hold (FEEL-4): before its first tick lands, the ratchet clicks, a little
## higher and quieter than a full notch, and the wheel gives (_show_hold).
func _hold_started() -> void:
	sfx_bank.play(&"clank", -12.0, 1.9)


## The wheel being held turns part of its next notch from the press frame on, and springs back on
## release (BypassHandle.show_hold, JunctionRoom.show_crank).
func _show_hold() -> void:
	var at_bypass: bool = hold_use.holding and hold_use.station == &"bypass"
	bypass_handle.show_hold(hold_use.shown_fraction() if at_bypass else 0.0)
	var at_valve: bool = hold_use.holding and hold_use.station == &"valve" and pressure_line.state == &"building"
	junction_room.show_crank(HoldUse.shown(pressure_line.progress / PressureLine.TURN_SECONDS) if at_valve else 0.0)


## Settings' TOGGLE HOLDS changed; a crank turning on its own stops when it goes off.
func _on_hold_toggle_changed(on: bool) -> void:
	hold_toggle = on
	crank_latched = false


## The crank pose while USE is held at the MANUAL BYPASS with the engineer on the crank spot: B for
## CRANK_PUSH_SECONDS after each tick, A the rest of the hold; otherwise the engineer's usual sprite.
## The floor reflection mirrors whichever art the sprite shows (FloorReflection._mirror).
func _update_crank_pose(delta: float) -> void:
	crank_push_left = maxf(crank_push_left - delta, 0.0)
	var frame: int = -1
	if state.chapter_id == "lockdown" and not state.door_open and hold_use.holding and hold_use.station == &"bypass" \
			and engineer_step_x < 0.0 and absf(human.position.x - BYPASS_CRANK_X) <= 1.0:
		frame = 1 if crank_push_left > 0.0 else 0
	if frame == crank_frame or human_texture == null:
		return
	crank_frame = frame
	if frame < 0:
		_show_human_standing()
	else:
		# The wheel is on the engineer's right, so the crank frames never flip.
		_show_human_frame(CRANK_ART[frame], CRANK_SCALE, CRANK_SPRITE_POS[frame], false)


## The engineer's authored step (back from the relay, to a crank spot, or beside a station they used):
## on arrival they settle on the spot, face what they came to use, and get their controls back.
func _tick_engineer_step() -> void:
	if engineer_step_x < 0.0 or absf(human.position.x - engineer_step_x) > 4.0:
		return
	human.position.x = engineer_step_x
	if engineer_face_x >= 0.0:
		human.body_sprite.flip_h = engineer_face_x < engineer_step_x
	engineer_step_x = -1.0
	engineer_face_x = -1.0
	_update_controls()
	if records_exit_walking:
		# Out through the Records exit: once WOLF is through behind them, the service line to Archive
		# begins (_tick_records_walk_out).
		records_exit_engineer_out = true


## Leaving Records: the engineer is out of view down the passage; the junction begins once WOLF has
## followed them through the doorway, past the near column, or after RECORDS_WAIT_SECONDS at most.
func _tick_records_walk_out(delta: float) -> void:
	if not records_exit_walking or not records_exit_engineer_out:
		return
	records_exit_wait += delta
	if wolf.position.x >= RECORDS_WOLF_OUT_X - 4.0 or records_exit_wait >= RECORDS_WAIT_SECONDS:
		_reset_records_walk_out()
		_enter_junction()


## Ends (or clears) the walk out of Records: nobody is walking out, nobody is through, nothing waited.
## Used when WOLF has followed them through, and when the title or a new scene drops the walk.
func _reset_records_walk_out() -> void:
	records_exit_walking = false
	records_exit_engineer_out = false
	records_exit_wait = 0.0


## Sends the engineer to [param spot_x] on their own, turning on arrival to face [param face_x].
func _step_engineer(spot_x: float, face_x: float) -> void:
	if engineer_step_x >= 0.0:
		# An authored step already under way (clear of the relay, to a crank spot) wins.
		return
	if absf(human.position.x - spot_x) <= 4.0:
		human.body_sprite.flip_h = face_x < spot_x
		return
	engineer_step_x = spot_x
	engineer_face_x = face_x
	_update_controls()


## A USE that lands while the engineer stands over a station's machine steps them out to its side (the
## station's own side, else the side they stand on, the left when centred), just beside the machine
## and facing it, still within reach. Not while the junction's fuse burns: the step takes the controls
## for a moment, and that second is for getting clear.
func _step_beside_station(x: float) -> void:
	if _fuse_lit():
		return
	for station: Vector4 in _room_stations():
		if absf(x - station.x) > station.z:
			continue
		var offset: float = _station_offset(station)
		var spot_x: float = _station_side_x(station, x)
		if absf(x - spot_x) > 4.0 and absf(x - station.x) < offset + 4.0:
			_step_engineer(spot_x, station.x)
		return


## Stopped over a station's machine (no move input), the engineer sidesteps out to the same spot beside
## it a USE steps them to, keeping the way they face (M0Actor.settle_x); any move input takes over at
## once, so it never holds them. Nothing pulls them while they crank, during a choice or a scripted
## step, or into a hazard they are not already in.
func _update_settle() -> void:
	human.settle_x = -1.0
	if not human.controlled or hold_use.holding:
		return
	for station: Vector4 in _room_stations():
		if absf(human.position.x - station.x) >= _station_offset(station) - 1.0:
			continue
		var spot: float = clampf(_station_side_x(station, human.position.x), M0Actor.MIN_X, M0Actor.MAX_X)
		if _settle_safe(human.position.x, spot):
			human.settle_x = spot
		return


## A sidestep from [param from_x] to [param to_x] never carries the engineer onto the live relief vent,
## into the blast zone while the fuse burns or into the coolant cloud.
func _settle_safe(from_x: float, to_x: float) -> bool:
	if state.chapter_id != "junction":
		return true
	if pressure_line.state == &"building" and PressureLine.is_on_vent(to_x) and not PressureLine.is_on_vent(from_x):
		return false
	if _fuse_lit() and PressureLine.is_in_blast(to_x) and not PressureLine.is_in_blast(from_x):
		return false
	return not (drop_arm.cloud_active() and DropArm.in_cloud(to_x) and not DropArm.in_cloud(from_x))


## True while the junction's fuse burns, the seconds (PressureLine.FUSE_SECONDS) to get clear of the door.
func _fuse_lit() -> bool:
	return state.chapter_id == "junction" and not state.door_blown and pressure_line.state in [&"charged", &"fuse"]


## The engineer's first name, as the narration and knockdown cards use it.
func _first_name() -> String:
	return state.human_name().get_slice(" ", 0)


## Records' closing lines (RECORDS_CLOSE_LINE) with the engineer's first name as their speaker tag.
## One place builds it, so the line said at the exit, the check for its unread boxes and
## text_boxes_test all compare the same text.
func _records_close_line() -> String:
	return RECORDS_CLOSE_LINE % _first_name().to_upper()


## A restored engineer never stands inside a station's machine: a save or snapshot taken over its
## drawn body (by an earlier build, or a USE whose step out had not finished) places them at its side,
## facing it, still within reach.
func _clear_station_body() -> void:
	for station: Vector4 in _room_stations():
		if absf(human.position.x - station.x) >= station.y:
			continue
		var spot_x: float = _station_side_x(station, human.position.x)
		human.position.x = spot_x
		human.body_sprite.flip_h = station.x < spot_x
		return


## The stations of the current room the engineer works from beside (CORRIDOR_STATIONS,
## RECORDS_STATIONS, JUNCTION_STATIONS).
func _room_stations() -> Array[Vector4]:
	if state.chapter_id == "lockdown":
		return CORRIDOR_STATIONS
	if state.chapter_id == "records":
		return RECORDS_STATIONS
	if state.chapter_id == "junction":
		return JUNCTION_STATIONS
	return []


## How far from a station's centre the engineer stands beside it, still within its reach.
func _station_offset(station: Vector4) -> float:
	return minf(station.y + M0Actor.HUMAN_REACH - STATION_OVERLAP, station.z - 2.0)


## The spot beside [param station] for an engineer at [param x]: the station's own side, else the side
## they stand on, the left when centred.
func _station_side_x(station: Vector4, x: float) -> float:
	var side: float = station.w if station.w != 0.0 else (1.0 if x > station.x else -1.0)
	return station.x + side * _station_offset(station)


## The corridor's moving parts: WOLF taking the contact once he is on it and the engineer is clear,
## WOLF's purge stakes line the first time the engineer walks past the display, and the MANUAL BYPASS
## being cranked ([param held_ticks] ticks landed this frame).
func _tick_corridor(delta: float, held_ticks: int) -> void:
	if wolf_heading_to_relay and engineer_step_x < 0.0 and absf(wolf.position.x - RELAY_CONTACT_X) <= 4.0:
		_wolf_takes_relay()
	# Where the engineer stands moves WOLF (off the relay while they are at it or the bypass).
	if human.controlled and wolf.autonomous_target_x != _wolf_target_x():
		_update_controls()
	if wolf.autonomous_target_x == WOLF_BYPASS_CLEAR_X and absf(wolf.position.x - WOLF_BYPASS_CLEAR_X) <= 2.0:
		# Standing off the relay he still faces the engineer at the bypass.
		wolf.body_sprite.flip_h = false
	elif wolf.autonomous_target_x == WOLF_DOORWAY_X and absf(wolf.position.x - WOLF_DOORWAY_X) <= 2.0:
		# In the doorway he faces the engineer at the safe point.
		wolf.body_sprite.flip_h = false
	# Decision C: the stakes are said on the main path, once, before the breaker conversation, and only
	# once every box of the line they replace (the opening lines, say) has been up long enough to read.
	if not stakes_spoken and not waiting_for_choice and box_queue.is_empty() and state.memory.is_empty() and human.position.x > PURGE_DISPLAY_MAX_X and _dialogue_read():
		_speak_stakes()
	if hold_use.station == &"bypass":
		if held_ticks > 0:
			_bypass_cranked()
		elif bypass_was_holding and not hold_use.holding and bypass_ticks > 0 and not state.door_open and engineer_step_x < 0.0:
			# Let go part way: what is cranked stays cranked (time, never progress).
			status_line = BYPASS_RELEASED_LINE % state.human_name().get_slice(" ", 0)
	bypass_was_holding = hold_use.holding and hold_use.station == &"bypass"
	if bypass_venting:
		# The hiss builds with the crank (the pressure-line loops, low to high as the turns add up);
		# the alarm repeats until the bypass locks over.
		var cranked: float = float(bypass_ticks) / BYPASS_TICKS
		sfx_bank.play_blend(SfxBank.HISS_GAUGE, cranked, lerpf(-24.0, -8.0, cranked))
		bypass_alarm_remaining -= delta
		if bypass_alarm_remaining <= 0.0:
			bypass_alarm_remaining = BYPASS_ALARM_SECONDS
			sfx_bank.play(&"klaxon", -10.0, 1.2)


## Shows [param boxes] one after another in the dialogue box, each for its reading time
## (box_seconds), the last one staying up like any other line.
func _say(boxes: Array[String]) -> void:
	status_line = boxes[0]
	box_queue = boxes.slice(1)
	box_queue_line = status_line
	box_queue_shown = status_line
	box_queue_seconds = box_seconds(status_line)
	box_queue_chapter = state.chapter_id
	box_queue_choice_seen = false


## Moves a line said in several boxes on to its next box once this one has been up its reading time.
## An aside taking the box (a station's answer or refusal, the sentry locking on or losing the
## engineer) only holds the rest back: the next box follows once that
## line has been up its own reading time. A line that moves the story on (_tell: the tank landing, the
## clamp, the bolt, the fuse) drops them, as does answering a choice (an open one holds them): the story
## has moved past them (the trust line after the relay question, "The tank takes a moment to fall."
## over a crushed sentry). A knockdown, a load or a new chapter drops them too (_drop_box_queue).
func _advance_box_queue(delta: float) -> void:
	# The opening lines wait for the first step (TEACH-7), and so do the boxes after them.
	if opening_lines_held:
		return
	if box_queue.is_empty():
		# The last box's reading time still runs down (_hold_for_lane_question waits on it).
		box_queue_seconds = maxf(box_queue_seconds - delta, 0.0)
		return
	if state.chapter_id != box_queue_chapter:
		_drop_box_queue()
		return
	if waiting_for_choice:
		box_queue_choice_seen = true
		return
	if box_queue_choice_seen:
		_drop_box_queue()
		return
	if status_line != box_queue_line:
		box_queue_line = status_line
		box_queue_seconds = box_seconds(status_line)
		return
	# The line up may itself show as several boxes (DialogueBoxes.split): the next line waits until its
	# last box is up, and then for that box's reading time (not the whole line's again).
	_sync_dialogue_boxes()
	if dialogue_index < dialogue_boxes.size() - 1:
		box_queue_seconds = _box_seconds_of(dialogue_boxes.size() - 1)
		return
	box_queue_seconds -= delta
	if box_queue_seconds > 0.0:
		return
	_next_box_now()


## Puts a line that moves the story on in the box (the tank landing, the clamp letting go, the bolt,
## the fuse, the hatch). Boxes still to come of an earlier line are dropped, not held behind it, since
## the story has moved past them.
func _tell(line: String) -> void:
	_drop_box_queue()
	status_line = line


## Puts an aside in the box (a station's answer, such as the purge display, or a refusal). A story box
## the queue put up (_say, _next_box_now: the opening lines, the stakes, Records' closing lines) that is
## not yet read comes back after it, ahead of the boxes still to come and at the box it was on, so
## reading a station never drops a story box.
func _aside(line: String) -> void:
	if not box_queue_shown.is_empty() and status_line == box_queue_shown and status_line != line and not _dialogue_read():
		box_queue.push_front(status_line)
		box_resume_line = status_line
		box_resume_index = dialogue_index
		box_queue_chapter = state.chapter_id
		box_queue_choice_seen = false
	box_queue_shown = ""
	status_line = line


## Says [param line] in its own box after the boxes still to come of an earlier line, or now if there
## are none.
func _say_next(line: String) -> void:
	if box_queue.is_empty():
		status_line = line
	else:
		box_queue.append(line)


## Brings on the next box of a line said in several boxes now, without waiting out this one's reading
## time.
func _next_box_now() -> void:
	if box_queue.is_empty():
		return
	status_line = box_queue.pop_front()
	box_queue_line = status_line
	box_queue_shown = status_line
	box_queue_seconds = box_seconds(status_line)


## Forgets the boxes still to come of a line said in several boxes.
func _drop_box_queue() -> void:
	box_queue.clear()
	box_resume_line = ""
	box_queue_line = ""
	box_queue_shown = ""
	box_queue_seconds = 0.0
	box_queue_choice_seen = false


## How long one box of a line said in several boxes stays up (DialogueBoxes.read_seconds), not counting
## a speaker tag.
static func box_seconds(box: String) -> float:
	var text: String = box
	var colon: int = text.find(": ")
	if colon > 0 and colon < 20 and text.left(colon) == text.left(colon).to_upper():
		text = text.substr(colon + 2)
	return DialogueBoxes.read_seconds(text)


## WOLF's stakes line. It cuts in ahead of any boxes still to come (the opening's), which follow it, and
## like a box the queue put up an aside (the purge display) never drops it.
func _speak_stakes() -> void:
	stakes_spoken = true
	status_line = STAKES_LINE
	box_queue_shown = STAKES_LINE


## WOLF's stakes line is in the box and the relay question has not been asked yet.
func _stakes_up() -> bool:
	return status_line == STAKES_LINE and state.memory.is_empty() and not waiting_for_choice


## WOLF's stakes line waits behind an aside that cut into it (_aside), so USE brings it back first.
func _stakes_queued() -> bool:
	return _queued_next(STAKES_LINE) and state.memory.is_empty() and not waiting_for_choice


## [param line] is the next box the queue will show.
func _queued_next(line: String) -> bool:
	return not box_queue.is_empty() and box_queue[0] == line


## True within reach of the corridor's breaker.
static func _at_breaker(x: float) -> bool:
	return absf(x - 350.0) <= 52.0


## WOLF asks about the relay's COOLANT FAULT tag; everything waits for the answer.
func _ask_relay() -> void:
	waiting_for_choice = true
	choice_context = "relay"
	_update_controls()
	status_line = "%s\n1  \"%s\"\n2  \"%s\"" % [RELAY_QUESTION, M0State.CHOICE_TEXT[M0State.DISCLOSE], M0State.CHOICE_TEXT[M0State.PRESS]]


func _new_game() -> void:
	get_tree().paused = false
	pause_overlay.hide()
	Tweens.kill(intro_tween)
	Tweens.kill(chapter_tween)
	_cancel_fail()
	chapter_close_active = false
	_hide_end_card()
	checkpoint_toast_remaining = 0.0
	tutorial_step = 0
	title_open = false
	title_screen.hide()
	state = M0State.new()
	save_error = ""
	save_pending = false
	beat_snapshot = {}
	intro_active = true
	intro_step = 0
	last_top_card_key = ""
	waiting_for_choice = false
	choice_context = ""
	relay_refused = false
	wolf_heading_to_relay = false
	wolf_scouting = false
	stakes_spoken = false
	_drop_box_queue()
	ladder_step = JUNCTION_LADDER_SECONDS.size()
	wolf_look_x = -1.0
	wolf_look_remaining = 0.0
	opening_lines_held = false
	opening_lines.clear()
	name_card_remaining = 0.0
	hold_use.reset()
	_sync_scene()
	human.hide()
	intro_director.position = Vector2(255.0, 410.0)
	intro_director.show()
	purge_terminal_art.hide()
	$BreakerLabel.hide()
	$RelayLabel.hide()
	$CheckpointLabel.hide()
	for station: CanvasItem in [breaker_art, relay_art, checkpoint_art, breaker_status_light, relay_status_light, door_visual, door_lip, seal_lamp, bypass_handle]:
		station.hide()
	wolf.position = Vector2(115.0, 423.0)
	wolf.z_index = ACTOR_Z
	wolf.body_sprite.position = WOLF_SPRITE_REST
	wolf.body_sprite.modulate = Color("#365263")
	intro_gate.position = Vector2(115.0, 365.0)
	intro_gate.set("opening", 0.0)
	$IntroCage.show()
	intro_gate.show()
	intro_camera.position = Vector2(267.0, 355.0)
	intro_camera.position_smoothing_enabled = false
	intro_camera.zoom = Vector2(1.8, 1.8)
	intro_alarm.color.a = 0.0
	intro_fade.color.a = 1.0
	intro_tween = create_tween()
	intro_tween.tween_property(intro_fade, "color:a", 0.0, 0.55)
	status_line = INTRO_LINES[0]
	queue_redraw()
	_refresh_ui()


## One opening beat per press: INTRO_LINES[intro_step] is on screen; after the last, the fade into play.
func _advance_intro() -> void:
	if intro_step >= INTRO_LINES.size():
		return
	Tweens.kill(intro_tween)
	intro_fade.color.a = 0.0
	intro_step += 1
	if intro_step < INTRO_LINES.size():
		status_line = INTRO_LINES[intro_step]
	match intro_step:
		2:
			# WOLF wakes himself.
			intro_tween = create_tween()
			intro_tween.tween_property(wolf.body_sprite, "modulate", WOLF_AWAKE_TINT, 0.45)
			intro_tween.parallel().tween_property(intro_camera, "zoom", Vector2(1.95, 1.95), 0.45)
		3:
			wolf.body_sprite.modulate = WOLF_AWAKE_TINT
			intro_camera.zoom = Vector2(1.95, 1.95)
			_shutter_boom()
			intro_tween = create_tween()
			# The gate folds aside and stays drawn, open, against the cage post.
			intro_tween.tween_property(intro_gate, "opening", 1.0, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			intro_tween.parallel().tween_property(intro_alarm, "color:a", 0.13, 0.18)
			intro_tween.tween_callback(func() -> void: wolf.z_index = 5)
			intro_tween.tween_property(wolf.body_sprite, "position:y", WOLF_SPRITE_REST.y + 8.0, 0.28)
			intro_tween.tween_callback(func() -> void: wolf.autonomous_target_x = 185.0)
		4:
			intro_gate.set("opening", 1.0)
			wolf.z_index = 5
			wolf.body_sprite.position.y = WOLF_SPRITE_REST.y + 8.0
			wolf.autonomous_target_x = 185.0
			intro_tween = create_tween()
			intro_tween.tween_property(intro_director, "position:x", 310.0, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			intro_tween.parallel().tween_property(intro_camera, "position:x", 300.0, 0.65)
			intro_tween.parallel().tween_property(intro_alarm, "color:a", 0.05, 0.65)
		5:
			intro_director.position.x = 310.0
		6:
			# The narration says it as he does it: he turns from the Director and walks off.
			intro_director.position.x = 310.0
			wolf.autonomous_target_x = 110.0
		7:
			intro_tween = create_tween()
			intro_tween.tween_property(intro_fade, "color:a", 1.0, 0.3)
			intro_tween.tween_callback(_finish_intro.bind(true))
			intro_tween.tween_property(intro_fade, "color:a", 0.0, 0.35)


func _finish_intro(keep_fade: bool = false) -> void:
	intro_active = false
	intro_step = 0
	if not keep_fade:
		Tweens.kill(intro_tween)
		intro_fade.color.a = 0.0
	intro_alarm.color.a = 0.0
	intro_gate.hide()
	$IntroCage.hide()
	intro_director.hide()
	human.show()
	purge_terminal_art.show()
	$BreakerLabel.show()
	$RelayLabel.show()
	$CheckpointLabel.show()
	for station: CanvasItem in [breaker_art, relay_art, checkpoint_art, breaker_status_light, relay_status_light, door_visual, bypass_handle]:
		station.show()
	_start_gameplay_camera()
	wolf.body_sprite.modulate = Color.WHITE
	wolf.body_sprite.position = WOLF_SPRITE_REST
	wolf.z_index = ACTOR_Z
	wolf.position = state.wolf_position
	wolf.autonomous_target_x = -1.0
	wolf.follow_side = 0
	_sync_door()
	_update_controls()
	_mark_beat()
	# Decision B: the engineer's name card as control starts, and why they trust WOLF, in the third person.
	name_card_remaining = NAME_CARD_SECONDS + TOP_CARD_FADE_SECONDS
	var first_name: String = state.human_name().get_slice(" ", 0)
	_say([TRUST_LINE_1 % first_name, TRUST_LINE_2 % first_name, OPENING_EXCHANGE % first_name.to_upper()])
	# TEACH-7: the first controllable frame shows the name card and the move prompt only; the opening
	# lines wait for the first step (the queue holds while they do, _advance_box_queue).
	opening_lines.assign([status_line] + box_queue)
	opening_lines_held = true
	queue_redraw()
	_refresh_ui()


func _show_credits() -> void:
	credits_paused = false
	credits_pause_button.text = "PAUSE SCROLL"
	_show_title_overlay(credits_screen)
	credits_body.get_v_scroll_bar().value = 0.0
	_grab_menu_focus(credits_back_button)


func _hide_credits() -> void:
	_hide_title_overlay(credits_screen)
	_grab_menu_focus(credits_button)


## Credits and the changelog replace the title menu over the key art; closing one restores the menu
## without revealing the other.
func _show_title_overlay(overlay: Control) -> void:
	for child: Node in title_screen.get_children():
		if child is CanvasItem and child != overlay and child != $CanvasLayer/TitleScreen/CorridorArt:
			(child as CanvasItem).hide()
	overlay.show()


func _hide_title_overlay(overlay: Control) -> void:
	overlay.hide()
	for child: Node in title_screen.get_children():
		if child is CanvasItem and child != credits_screen and child != changelog_screen:
			(child as CanvasItem).show()


func _toggle_credits_pause() -> void:
	credits_paused = not credits_paused
	credits_pause_button.text = "RESUME SCROLL" if credits_paused else "PAUSE SCROLL"


func _on_credits_body_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		credits_paused = true
		credits_pause_button.text = "RESUME SCROLL"


## Dragging the changelog text scrolls it: a touch drag, or the mouse moved with the left button held.
## Touch also arrives as an emulated mouse motion, which is skipped so one finger does not scroll twice.
func _on_changelog_body_input(event: InputEvent) -> void:
	var drag: float = 0.0
	if event is InputEventScreenDrag:
		drag = (event as InputEventScreenDrag).relative.y
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and (event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		drag = (event as InputEventMouseMotion).relative.y
	if drag != 0.0:
		changelog_body.get_v_scroll_bar().value -= drag
		changelog_body.accept_event()


func _setup_touch_controls() -> void:
	_bind_touch_button(touch_left, &"move_left")
	_bind_touch_button(touch_right, &"move_right")
	_bind_touch_button(touch_use, &"interact")
	_bind_touch_button(touch_choice_1, &"choice_1")
	_bind_touch_button(touch_choice_2, &"choice_2")
	# Button looks come from the project theme (game_theme.tres): touch and HUD buttons use its TouchButton
	# variation from the scene, and Settings applies the Terminal variations itself.
	settings_menu.apply_theme()


func _bind_touch_button(button: Button, action: StringName) -> void:
	button.button_down.connect(func() -> void: Input.action_press(action))
	button.button_up.connect(func() -> void: Input.action_release(action))


func _setup_settings() -> void:
	fps_options.add_item("30 FPS", 30)
	fps_options.add_item("60 FPS", 60)
	fps_options.add_item("UNCAPPED", 0)
	fps_options.add_item("90 FPS", 90)
	fps_options.add_item("120 FPS", 120)
	fps_options.add_item("144 FPS", 144)
	for index: int in GameSettings.WINDOW_SIZES.size():
		var option: Vector2i = GameSettings.WINDOW_SIZES[index]
		resolution_options.add_item("%d × %d" % [option.x, option.y], index)
	var config: ConfigFile = GameSettings.load_config(settings_path)
	var fps: int = int(GameSettings.number(config, "video", "fps_limit", 60))
	if not fps in [0, 30, 60, 90, 120, 144]:
		fps = 60
	Engine.max_fps = fps
	fps_options.select(fps_options.get_item_index(fps))
	var resolution: int = GameSettings.saved_window_index(config)
	resolution_options.select(resolution)
	var mobile: bool = OS.has_feature("ios") or OS.has_feature("android")
	resolution_options.disabled = mobile
	fullscreen_toggle.disabled = mobile
	settings_note.text = "Window size is managed by iOS/Android." if mobile else "Window size applies on desktop."
	if mobile:
		$CanvasLayer/PauseOverlay/Panel/PauseMenu/PauseHint.text = "TAP RESUME TO RETURN"
	if not mobile:
		# The logo screen normally applied these at launch already; a direct start applies them here.
		GameSettings.apply_saved_window(get_window(), config)
		fullscreen_toggle.button_pressed = GameSettings.boolean(config, "video", "fullscreen", false)
	fps_options.item_selected.connect(_on_fps_selected)
	resolution_options.item_selected.connect(_on_resolution_selected)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	settings_menu.configure(settings_path)


func _resolution_size(index: int) -> Vector2i:
	return GameSettings.window_size(index)


func _on_fps_selected(index: int) -> void:
	Engine.max_fps = fps_options.get_item_id(index)
	_save_settings()


func _on_resolution_selected(index: int) -> void:
	if not resolution_options.disabled:
		get_window().size = _resolution_size(index)
		_save_settings()


func _on_fullscreen_toggled(enabled: bool) -> void:
	if not fullscreen_toggle.disabled:
		get_window().mode = Window.MODE_FULLSCREEN if enabled else Window.MODE_WINDOWED
		_save_settings()


func _save_settings() -> void:
	var config: ConfigFile = GameSettings.load_config(settings_path)
	config.set_value("video", "fps_limit", fps_options.get_selected_id())
	config.set_value("video", "resolution", resolution_options.selected)
	config.set_value("video", "fullscreen", fullscreen_toggle.button_pressed)
	if config.save(settings_path) != OK:
		settings_note.text = "Settings could not be saved."


func _on_pause_button() -> void:
	_pause_game()


func _pause_game() -> void:
	for action: StringName in GAMEPLAY_ACTIONS:
		Input.action_release(action)
	# Like letting go of a held crank: a toggled crank stops while the game is paused.
	crank_latched = false
	impact.end_hit_stop()
	_show_pause_menu()
	pause_overlay.show()
	_fade_backdrop()
	pause_button.hide()
	touch_controls.hide()
	get_tree().paused = true
	_grab_menu_focus(resume_button)


func _resume_game() -> void:
	settings_menu.cancel_capture()
	get_tree().paused = false
	pause_overlay.hide()
	# A pause that landed inside a hit-stop or flash never leaves play slowed or tinted.
	impact.reset()
	_refresh_ui()


func _show_settings() -> void:
	pause_menu.hide()
	menu_panel.position = Vector2(100, 38)
	menu_panel.size = Vector2(760, 464)
	$CanvasLayer/PauseOverlay/Panel/Accent.hide()
	settings_menu.show()
	_reveal_menu()
	_grab_menu_focus(settings_menu.tabs)


func _show_title_settings() -> void:
	pause_overlay.show()
	_fade_backdrop()
	get_tree().paused = true
	_show_settings()


## The dimmed backdrop fades in when the overlay opens; the card slides in separately so Settings
## and the pause menu each arrive with the same short motion.
func _fade_backdrop() -> void:
	Tweens.kill(backdrop_tween)
	pause_overlay.modulate.a = 0.0
	backdrop_tween = pause_overlay.create_tween()
	backdrop_tween.tween_property(pause_overlay, "modulate:a", 1.0, MENU_REVEAL_SECONDS)


func _reveal_menu() -> void:
	Tweens.kill(menu_tween)
	var resting: Vector2 = menu_panel.position
	menu_panel.position = resting + MENU_REVEAL_OFFSET
	menu_panel.modulate.a = 0.0
	menu_tween = pause_overlay.create_tween().set_parallel(true)
	menu_tween.tween_property(menu_panel, "position", resting, MENU_REVEAL_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	menu_tween.tween_property(menu_panel, "modulate:a", 1.0, MENU_REVEAL_SECONDS)


func _show_pause_menu() -> void:
	if title_open and pause_overlay.visible:
		_resume_game()
		_grab_menu_focus($CanvasLayer/TitleScreen/SettingsButton)
		return
	settings_menu.cancel_capture()
	menu_panel.position = Vector2(255, 55)
	menu_panel.size = Vector2(450, 430)
	pause_menu.size = Vector2(450, 430)
	$CanvasLayer/PauseOverlay/Panel/Accent.show()
	settings_menu.hide()
	pause_menu.show()
	$CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton.text = "SKIP OPENING" if intro_active else "RETURN TO TITLE"
	$CanvasLayer/PauseOverlay/Panel/PauseMenu/ReturnWarning.visible = not intro_active
	$CanvasLayer/PauseOverlay/Panel/PauseMenu/PauseHint.text = "TAP RESUME TO RETURN" if touch_enabled and not controller_active else "%s  RESUME" % settings_menu.prompt(&"pause_game", controller_active)
	_reveal_menu()
	_grab_menu_focus(resume_button)


func _return_to_title() -> void:
	_resume_game()
	if intro_active:
		_finish_intro()
	Tweens.kill(chapter_tween)
	_cancel_fail()
	# The junction's loops and the bypass alarm never follow the player to the title.
	_stop_junction_loops()
	_stop_bypass_vent()
	intro_fade.color.a = 0.0
	chapter_close_active = false
	hatch_exit_walking = false
	hatch_exit_engineer_walking = false
	_reset_records_walk_out()
	_hide_end_card()
	checkpoint_toast_remaining = 0.0
	waiting_for_choice = false
	choice_context = ""
	title_open = true
	_hide_credits()
	changelog_screen.hide()
	title_screen.show()
	_refresh_continue()
	_update_controls()
	_refresh_ui()
	_grab_menu_focus(_title_first_button())


## Keyboard and controller players need a focused menu control; pure touch play shows no focus ring.
## Touch clears focus instead, so a stale focus behind an overlay cannot take the next key press.
func _grab_menu_focus(control: Control) -> void:
	if title_screen.is_ancestor_of(control):
		title_focus_return = control
	if touch_enabled and not controller_active:
		get_viewport().gui_release_focus()
	else:
		control.grab_focus()


## The menu control a keyboard or controller press should land on when nothing has focus.
func _menu_focus_target() -> Control:
	if end_card_active:
		return end_card_button
	if pause_overlay.visible:
		return settings_menu.tabs if settings_menu.visible else resume_button
	if title_open:
		if credits_screen.visible:
			return credits_back_button
		if changelog_screen.visible:
			return changelog_back_button
		return title_focus_return if title_focus_return != null and title_focus_return.is_visible_in_tree() else _title_first_button()
	return null


func _unhandled_input(event: InputEvent) -> void:
	# Back or Pause on the END OF SLICE card goes on to the title, like its CONTINUE.
	if end_card_active and not event.is_echo() and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause_game")):
		_close_end_card()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"ui_cancel") and (credits_screen.visible or changelog_screen.visible):
		if credits_screen.visible:
			_hide_credits()
		else:
			_hide_changelog()
		get_viewport().set_input_as_handled()
		return
	# Pause is event-driven so the press that resumes from PauseOverlay (handled in its _input)
	# can never re-pause in the same frame.
	if title_open or get_tree().paused or event.is_echo() or not event.is_action_pressed(&"pause_game"):
		return
	_pause_game()
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_handle_back()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Leaving the app mid-play pauses it so nothing advances unseen.
			if auto_pause_on_focus_loss and is_node_ready() and not title_open and not end_card_active and not get_tree().paused:
				_pause_game()


## Android Back walks out of nested menus one step at a time; it only quits from the bare title.
func _handle_back() -> void:
	if _debug_takes_back():
		return
	if not settings_menu.capture_action.is_empty():
		settings_menu.cancel_capture()
	elif pause_overlay.visible and settings_menu.visible:
		_on_settings_back()
	elif pause_overlay.visible:
		_resume_game()
	elif credits_screen.visible:
		_hide_credits()
	elif changelog_screen.visible:
		_hide_changelog()
	elif end_card_active:
		_close_end_card()
	elif title_open:
		get_tree().quit()
	else:
		_pause_game()


func _on_title_button() -> void:
	if intro_active:
		_resume_game()
		_finish_intro()
	else:
		_return_to_title()


func _on_settings_back() -> void:
	_show_pause_menu()
	if not title_open:
		_grab_menu_focus(settings_button)


func _input(event: InputEvent) -> void:
	_note_input_device(event)
	# Direct response bindings win over native focused-button acceptance.
	if waiting_for_choice and not title_open and not get_tree().paused and not event.is_echo():
		var response: int = 1 if event.is_action_pressed(&"choice_1") else (2 if event.is_action_pressed(&"choice_2") else 0)
		if response != 0:
			_answer_choice(response)
			get_viewport().set_input_as_handled()


## Routes answer 1 or 2 to whichever question is open.
func _answer_choice(response: int) -> void:
	match choice_context:
		"mirror":
			_choose_mirror("wolf" if response == 1 else "manual")
		"lane":
			_choose_lane(response)
		_:
			_choose(M0State.DISCLOSE if response == 1 else M0State.PRESS)


## Called from _input during play and from PauseOverlay while the tree is paused.
func _note_input_device(event: InputEvent) -> void:
	var use_controller: bool = controller_active
	var navigation_press: bool = false
	if event is InputEventJoypadButton and event.pressed or event is InputEventJoypadMotion and absf(event.axis_value) > 0.45:
		use_controller = true
		navigation_press = true
		# Rumble goes to the pad that is actually in use, not always the first one connected.
		impact.rumble_device = event.device
	elif event is InputEventScreenTouch and event.pressed or event is InputEventScreenDrag or event is InputEventKey and event.pressed or event is InputEventMouseButton and event.pressed:
		use_controller = false
		navigation_press = event is InputEventKey
	if use_controller != controller_active:
		controller_active = use_controller
		_refresh_ui()
	# Touch menus open unfocused; the first key or controller press gives keyboard and controller players a focus to move.
	if navigation_press and get_viewport().gui_get_focus_owner() == null:
		var target: Control = _menu_focus_target()
		if target != null and target.is_visible_in_tree():
			target.grab_focus()
			# A navigation or confirm press only reveals focus; it must not also move it or activate the control.
			for action: StringName in MENU_NAVIGATION_ACTIONS:
				if event.is_action_pressed(action):
					get_viewport().set_input_as_handled()
					break


func _load_game() -> void:
	get_tree().paused = false
	pause_overlay.hide()
	last_top_card_key = ""
	var loaded: M0State = M0State.load_from_disk(save_path)
	if loaded == null:
		status_line = "No valid checkpoint save found. Current game was not changed."
		return
	_drop_box_queue()
	title_open = false
	title_screen.hide()
	intro_active = false
	Tweens.kill(chapter_tween)
	chapter_close_active = false
	_hide_end_card()
	checkpoint_toast_remaining = 0.0
	tutorial_step = 2
	Tweens.kill(intro_tween)
	intro_gate.hide()
	intro_director.hide()
	intro_fade.color.a = 0.0
	intro_alarm.color.a = 0.0
	human.show()
	$IntroCage.hide()
	wolf.z_index = ACTOR_Z
	wolf.body_sprite.position = WOLF_SPRITE_REST
	purge_terminal_art.show()
	$BreakerLabel.show()
	$RelayLabel.show()
	$CheckpointLabel.show()
	queue_redraw()
	wolf.body_sprite.modulate = Color.WHITE
	state = loaded
	save_error = ""
	save_pending = false
	waiting_for_choice = false
	choice_context = ""
	relay_refused = false
	wolf_heading_to_relay = false
	wolf_scouting = false
	fail_active = false
	# A checkpoint lies past the corridor's opening beats: no name card, and the stakes were heard.
	name_card_remaining = 0.0
	stakes_spoken = true
	opening_lines_held = false
	opening_lines.clear()
	hold_use.reset()
	_sync_scene()
	_start_gameplay_camera()
	# The loaded save is this beat's start, so a knockdown never falls back past it.
	_mark_beat()
	if state.chapter_id == "junction":
		# Continue gives the chain in its restore line: no ladder, and the hint bar says the chain.
		ladder_step = JUNCTION_LADDER_SECONDS.size()
		wolf_look_x = -1.0
		wolf_look_remaining = 0.0
		door_bump_said = false
		door_faced = false
		if state.junction_cleared:
			status_line = JUNCTION_CLEARED_LINE
		elif state.sentry_down:
			status_line = "Service junction restored. The sentry\nis down; pop the exit bolt by the door."
		elif state.door_blown:
			status_line = "Service junction restored. The door is\ndown. The sentry patrols past the rubble."
		else:
			status_line = JUNCTION_RESTORE_A_LINE
	elif state.chapter_id == "records":
		if state.chapter_complete:
			status_line = "The first copy is safe. Use the exit to follow the service line."
		elif state.mirror_trace_preserved:
			status_line = "Records access restored. Both traces are copied; head for the exit."
		elif state.purge_trace_preserved:
			status_line = "Records access restored. The purge order is copied; copy the mirror index next."
		else:
			status_line = "Records access restored. Copy the purge-order trace first; WOLF is checking the mirror."
	else:
		status_line = "Safe point restored. " + state.checkpoint_callback()


func _interact() -> void:
	var x: float = human.position.x
	tutorial_step = 2
	# The name card never waits on the player: the first USE skips it.
	name_card_remaining = 0.0
	# An autosave that failed to write is retried by the next USE anywhere, station or not.
	if save_pending:
		_write_beat()
	if state.chapter_id == "records":
		_step_beside_station(x)
		_interact_records(x)
		return
	if state.chapter_id == "junction":
		if _door_use(x):
			# The sealed door answers for itself ahead of the valve's reach (P0-15).
			_refuse(REFUSE_DOOR, &"door")
			return
		# Fix round 3 (review r3, human pass): at the open exit the USE leaves through it. The bolt panel's
		# reach (_station_offset + 4 either side of BOLT_PANEL_X) runs out to x 849, past HATCH_REACH_MIN_X,
		# so the sidestep sent the engineer back to the panel's working side (BOLT_X) as they left.
		if not _at_open_exit(x):
			_step_beside_station(x)
		_interact_junction(x)
		return
	_step_beside_station(x)
	if x <= PURGE_DISPLAY_MAX_X:
		_aside("DIRECTOR / PURGE: Original program logs marked for deletion.\nWOLF: They want the source record gone. We need to preserve it.")
	elif _at_bypass(x):
		_interact_bypass()
	elif _at_breaker(x):
		_interact_breaker()
	elif _at_relay(x):
		_interact_relay()
	elif absf(x - 876.0) <= 52.0:
		_interact_checkpoint()
	else:
		_aside("No station in reach. Follow the labeled breaker, relay, bypass or safe point.")


## True within reach of the MANUAL BYPASS (x 670 to 730), just past the relay's, so the two never
## share a spot.
func _at_bypass(x: float) -> bool:
	return absf(x - BYPASS_WHEEL.x) <= BYPASS_REACH


## True within reach of the coolant relay: from RELAY_REACH left of it right up to where the MANUAL
## BYPASS's reach starts, so no spot between the two machines falls back to "go to the relay".
func _at_relay(x: float) -> bool:
	return x >= RELAY_X - RELAY_REACH and x < BYPASS_WHEEL.x - BYPASS_REACH


## WOLF said no to the live contact: he refused at the breaker (the engineer pressed without warning)
## or at the relay itself.
func _relay_refused() -> bool:
	return relay_refused or state.memory.get("choice_id") == M0State.PRESS


func _interact_breaker() -> void:
	if state.memory.is_empty() and not stakes_spoken:
		# Reached before the opening box was read: the stakes come first (decision C), then the question.
		_speak_stakes()
	elif state.memory.is_empty():
		# A USE with the stakes up goes on: to their next box, and from the last one WOLF asks now.
		if _stakes_queued():
			_next_box_now()
		elif not (_stakes_up() and _next_box()):
			_ask_relay()
	elif state.arm_breaker():
		status_line = BREAKER_CATCHES_LINE
		sfx_bank.play(&"clank", -4.0, 0.8)
		impact.rumble(0.15, 0.0, 0.06)
		# After a refusal WOLF stands off the now-live relay (_wolf_target_x).
		_update_controls()
		_mark_beat()
		queue_redraw()
	else:
		_aside("Power is already on. The relay is farther down the hall.")


func _choose(choice_id: String) -> void:
	if not state.record_choice(choice_id):
		return
	waiting_for_choice = false
	choice_context = ""
	_update_controls()
	_mark_beat()
	if choice_id == M0State.DISCLOSE:
		status_line = "WOLF: Thank you for telling me. I'll take the relay. Arm the breaker."
		_react_as_wolf(true)
	else:
		status_line = "WOLF: No. I won't take that risk blind. Use the manual bypass."
		_react_as_wolf(false)


## USE at the relay. It is WOLF's contact, never the bypass: on the honest answer the engineer signals
## him and steps back while he walks to it; after his refusal he says no again and points at the
## MANUAL BYPASS beside it.
func _interact_relay() -> void:
	# The engineer stands beside the relay, not inside it: on its right, towards the MANUAL BYPASS.
	if human.position.x < RELAY_SIDE_X - 4.0:
		_step_engineer(RELAY_SIDE_X, RELAY_X)
	if not state.breaker_armed:
		_aside("The relay is dark. Arm the breaker first.")
		return
	if state.door_open:
		status_line = "The seal is open. The safe point is just beyond it."
		return
	if _relay_refused():
		state.activate_power("wolf")
		relay_refused = true
		status_line = "WOLF: I said no. I won't touch it blind. The bypass is right beside it."
		_react_as_wolf(false)
		queue_redraw()
		return
	if wolf_heading_to_relay or wolf_holding_relay:
		return
	# WOLF chooses the contact himself. The engineer steps back clear of it, and the seal opens once he
	# holds it with the engineer clear (_tick_corridor).
	wolf_heading_to_relay = true
	engineer_step_x = RELAY_STEP_BACK_X
	_update_controls()
	status_line = "WOLF: I've got the contact. Give me a moment."
	_react_as_wolf(true)


## WOLF is on the contact and the engineer is clear: he takes the surge and holds the contact until the
## seal's curtain is up in its hood.
func _wolf_takes_relay() -> void:
	wolf_heading_to_relay = false
	if state.activate_power("wolf") == "cooperate":
		wolf_holding_relay = true
		_stop_bypass_vent()
		status_line = "WOLF takes the surge through the live contact. The red seal opens."
		_react_as_wolf(true)
		_flash_relay_spark(true)
		_sync_door(true)
		_mark_beat()
	_update_controls()


## USE at the MANUAL BYPASS: dead before the breaker; the first touch of the live handle starts the
## coolant hiss and the alarm. Holding USE cranks it (_tick_corridor).
func _interact_bypass() -> void:
	if state.door_open:
		status_line = "The seal is open. The safe point is just beyond it."
	elif not state.breaker_armed:
		_aside("The bypass handle won't move. The breaker has to be on first.")
	else:
		# The engineer steps to the crank spot beside the wheel and faces it; a held USE turns it once there.
		_step_engineer(BYPASS_CRANK_X, BYPASS_WHEEL.x)
		if not bypass_venting:
			_start_bypass_vent()


## The bypass handle gives: coolant hisses from the relay housing and the alarm starts. It is the
## cost of doing it alone, in time and nerve; nothing here can hurt the engineer or undo progress.
func _start_bypass_vent() -> void:
	bypass_venting = true
	bypass_alarm_remaining = 0.0
	bypass_handle.venting = true
	status_line = BYPASS_START_LINE
	# WOLF stands off the relay while the engineer works the bypass (_wolf_target_x).
	_update_controls()


func _stop_bypass_vent() -> void:
	# Only a bypass that was venting owns the hiss loops; the junction's pressure line uses them too.
	if bypass_venting:
		sfx_bank.stop_each(SfxBank.HISS_GAUGE)
	bypass_venting = false
	bypass_alarm_remaining = 0.0
	if bypass_handle != null:
		bypass_handle.venting = false


## One held-USE tick at the bypass: the wheel turns an eighth with a click and a readout cell lights.
## Half way the hiss is louder; the last tick locks it over and the seal opens on the engineer's own
## work.
func _bypass_cranked() -> void:
	if state.door_open or not state.breaker_armed:
		return
	bypass_ticks = mini(hold_use.ticks, BYPASS_TICKS)
	bypass_handle.ticks = bypass_ticks
	# Half a tick at most, so the regrip still shows if the hold gets shorter.
	crank_push_left = minf(CRANK_PUSH_SECONDS, BypassHandle.TICK_SECONDS * 0.5)
	sfx_bank.play(&"clank", -7.0, 1.5)
	impact.rumble(0.12, 0.0, 0.05)
	if not bypass_venting:
		_start_bypass_vent()
	if bypass_ticks >= BYPASS_TICKS:
		_finish_bypass()
	elif bypass_ticks * 2 == BYPASS_TICKS:
		status_line = BYPASS_HALF_LINE


func _finish_bypass() -> void:
	if state.activate_power("human") != "fallback":
		return
	_stop_bypass_vent()
	hold_use.reset()
	bypass_was_holding = false
	bypass_handle.done = true
	status_line = "The bypass locks over and the alarm cuts out. The red seal opens.\nWOLF: Open. I'm with you."
	_flash_relay_spark(false)
	# The seal starts to slide before control updates, so WOLF stays off the relay until it lands.
	_sync_door(true)
	_update_controls()
	_mark_beat()


func _interact_checkpoint() -> void:
	if not state.door_open:
		_aside("The safe point is past the sealed door.")
		return
	if state.checkpoint_reached:
		if state.enter_records():
			# The safe point accepts: the same chirp as a save, a little lower.
			sfx_bank.play(&"chirp", -9.0, 0.9)
			_sync_scene()
			# They came in through the entry: it stands open behind them and its closer brings it shut.
			records_room.close_entry_behind()
			# A new room: cut the camera to the engineer instead of panning across from the safe point.
			_start_gameplay_camera()
			var remembered_line: String = "I refused the live relay; I'm still here." if state.memory.get("choice_id") == M0State.PRESS else ("I took the relay because you told me the truth." if state.route == "cooperate" else "I offered the relay; you cranked the bypass. Still with you.")
			status_line = "WOLF: %s\nTake the purge queue. I'll inspect the mirror." % remembered_line
			_save_progress()
		return
	var first_visit: bool = state.reach_checkpoint()
	queue_redraw()
	_capture_positions()
	if not state.save_to_disk(save_path):
		if first_visit:
			state.checkpoint_reached = false
		status_line = "The safe point could not save. Press E here again."
		return
	save_error = ""
	# The safe point takes the save with a chirp; the first time, the corridor's lights switch over
	# with a contactor's clunk.
	sfx_bank.play(&"chirp", -8.0)
	if first_visit:
		sfx_bank.play(&"clank", -9.0, 0.7)
		_sync_room_lights(true)
		status_line = "Safe point saved. " + state.checkpoint_callback()
	else:
		status_line = "Safe point saved. WOLF remembers the same choice."


func _interact_records(x: float) -> void:
	if absf(x - 190.0) <= 58.0:
		if state.preserve_purge_trace():
			sfx_bank.play(&"chirp", -8.0)
			_aside("The Director's purge order has a time and target ID. %s keeps a local copy; the original logs are still missing." % _first_name())
		else:
			_aside("The purge-order trace is already copied. The mirror port may confirm when the source existed.")
		_sync_records_room()
		_save_progress()
	elif absf(x - 520.0) <= 58.0:
		if not state.purge_trace_preserved:
			_aside("The mirror index has no context yet. Copy the purge-order trace first.")
		elif state.mirror_trace_preserved:
			_aside("The mirror timestamp is already preserved. The exit is to the right.")
			_save_progress()
		else:
			waiting_for_choice = true
			choice_context = "mirror"
			_update_controls()
			status_line = "WOLF: I found the mirror index. We can use my readout or your maintenance port.\n1  USE WOLF'S READOUT     2  USE MANUAL PORT"
	elif _at_records_exit(x):
		if state.complete_chapter():
			# The copy goes into the security container, at its lock; the exit's bolt lets go and the door
			# swings open (RecordsRoom.open_exit).
			_step_engineer(RECORDS_CONTAINER_SIDE_X, RecordsRoom.CONTAINER_X)
			# The closing lines play while the engineer keeps control (STORY-8): no held shot. USE here
			# shows their next box, and once they are read walks out through the door (_leave_records).
			# Said through the queue, so a station's answer or the route hint cutting in never drops them
			# (_aside).
			_say([_records_close_line()])
			_update_controls()
			_sync_records_room(true)
			_sync_room_lights(true)
			# The exit's bolt lets go with a crackle and a small kick; what shows is the door itself: its
			# lamp turns amber and the leaf swings open (no particle puff stands in for the bolt).
			sfx_bank.play(&"records_arc", -3.0)
			impact.add_trauma(0.3)
			impact.flash(0.06, 0.0)
			impact.rumble(0.3, 0.4, 0.12)
			_save_progress()
		elif state.chapter_complete:
			if not _records_close_unread():
				_leave_records()
			elif not _next_box():
				# Put back behind an aside: they come back first.
				_next_box_now()
		else:
			_aside("Exit sealed until the purge order and mirror timestamp are copied.")
	else:
		_aside(_records_route_hint())


## The Records exit's USE: the security container and the shut exit within RECORDS_EXIT_REACH of x
## 830, and, once the exit is open, the doorway and the passage past it too.
func _at_records_exit(x: float) -> bool:
	return absf(x - RECORDS_EXIT_X) <= RECORDS_EXIT_REACH or (state.chapter_complete and x >= RECORDS_EXIT_X)


## USE at the open exit once the first copy is secured: the engineer walks out through the doorway
## into the service line passage, WOLF following one gap behind, and the junction begins once they are
## through (_tick_engineer_step).
func _leave_records() -> void:
	if records_exit_walking:
		return
	records_exit_walking = true
	# The press is heard on its frame, as CONTINUE on a closing shot is, and the hint bar (the USE prompt
	# or the save toast from securing the copy) clears as they set off.
	sfx_bank.play(&"chirp", -10.0, 0.75)
	checkpoint_toast_remaining = 0.0
	_update_controls()
	if records_room.exit_swinging():
		# Mid-swing the leaf crosses the walkway: they go once it is on its floor stop.
		await records_room.exit_tween.finished
		if not records_exit_walking or state.chapter_id != "records":
			return
	engineer_step_x = RECORDS_WALK_OUT_X
	engineer_face_x = -1.0
	_update_controls()


## Between Records stations: the stations still to do, in order, so a finished one is never named
## again (both copied leaves only the exit).
func _records_route_hint() -> String:
	if state.mirror_trace_preserved:
		return "Mirror copied. Head for the exit."
	if state.purge_trace_preserved:
		return "Follow the station lights: mirror port, then exit."
	return "Follow the station lights: purge queue, mirror port, then exit."


## CONTINUE on the junction's closing shot, the only one (Records keeps control while its closing
## lines run): out through the hatch, the END OF SLICE card, then the title (decision D).
func _finish_chapter_close() -> void:
	if hatch_exit_walking:
		# Already on their way out; the card follows on its own.
		return
	Tweens.kill(chapter_tween)
	sfx_bank.play(&"chirp", -10.0, 0.75)
	_walk_out_through_hatch()


## The two leave through the open exit door, WOLF first: he walks on from the doorway through the
## wall until the near jamb hides all of him, while the engineer waits where they are; then the
## engineer walks through after him until it hides them too, the doorway stands empty for a moment,
## and the END OF SLICE card comes up. One at a time, they are never drawn over each other in it.
func _walk_out_through_hatch() -> void:
	hatch_exit_walking = true
	hatch_exit_engineer_walking = false
	# A cleared junction's door stands open (as a restore shows it), whatever brought the close on.
	junction_room.hatch_open = 1.0
	_update_controls()
	chapter_tween = create_tween()
	chapter_tween.tween_interval(HATCH_EXIT_START_DELAY)
	chapter_tween.tween_callback(_wait_until_through.bind(wolf, JunctionRoom.WOLF_GONE_X, _engineer_follows_out))


## Calls [param then] once [param body] has reached [param x] (it walks there on its own), or after
## HATCH_EXIT_MAX_SECONDS whatever happens, so nothing can hold the card up for good.
func _wait_until_through(body: M0Actor, x: float, then: Callable, waited: float = 0.0) -> void:
	if not hatch_exit_walking:
		return
	if body.position.x >= x - 2.5 or waited >= HATCH_EXIT_MAX_SECONDS:
		then.call()
		return
	chapter_tween = create_tween()
	chapter_tween.tween_interval(0.05)
	chapter_tween.tween_callback(_wait_until_through.bind(body, x, then, waited + 0.05))


## WOLF is through: the engineer walks through after him, then the END OF SLICE card.
func _engineer_follows_out() -> void:
	if not hatch_exit_walking:
		return
	hatch_exit_engineer_walking = true
	_update_controls()
	_wait_until_through(human, HATCH_EXIT_X, _doorway_empty)


## Both are through and out of sight: the empty doorway holds for a moment, then the card.
func _doorway_empty() -> void:
	if not hatch_exit_walking:
		return
	chapter_tween = create_tween()
	chapter_tween.tween_interval(HATCH_EXIT_EMPTY_SECONDS)
	chapter_tween.tween_callback(_show_end_card)


## The END OF SLICE card over the closing shot: the thanks line, this run's choices and one CONTINUE
## (the interact button, a click or tap on it, Back or Pause) on to the title.
func _build_end_card() -> void:
	end_card = ColorRect.new()
	end_card.name = "EndCard"
	end_card.color = Color(0.025, 0.045, 0.08, 0.94)
	end_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_card.mouse_filter = Control.MOUSE_FILTER_STOP
	end_card.hide()
	$CanvasLayer.add_child(end_card)
	# Under the pause overlay, over the play view, the dialogue card and the touch controls.
	$CanvasLayer.move_child(end_card, pause_overlay.get_index())
	var panel: Panel = Panel.new()
	panel.theme_type_variation = &"MenuPanel"
	panel.position = Vector2(110.0, 70.0)
	panel.size = Vector2(740.0, 400.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_card.add_child(panel)
	var sheen: Panel = Panel.new()
	sheen.theme_type_variation = &"CardSheen"
	sheen.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sheen)
	var title: Label = _end_card_label(END_CARD_TITLE, Rect2(130.0, 92.0, 700.0, 46.0), 32, Color.WHITE)
	title.add_theme_font_override("font", DISPLAY_FONT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var line: ColorRect = ColorRect.new()
	line.color = Color(0.10, 0.76, 0.92, 1)
	line.position = Vector2(340.0, 146.0)
	line.size = Vector2(280.0, 3.0)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_card.add_child(line)
	_end_card_label(END_CARD_THANKS, Rect2(130.0, 162.0, 700.0, 28.0), 18, Color(0.82, 0.89, 0.94, 1)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var header: Label = _end_card_label(END_CARD_RECAP_HEADER, Rect2(150.0, 212.0, 660.0, 24.0), 15, END_CARD_ACCENT)
	header.add_theme_font_override("font", DISPLAY_FONT)
	end_card_rows = VBoxContainer.new()
	end_card_rows.name = "Recap"
	end_card_rows.position = Vector2(150.0, 244.0)
	end_card_rows.size = Vector2(660.0, 120.0)
	end_card_rows.add_theme_constant_override("separation", 12)
	end_card_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_card.add_child(end_card_rows)
	end_card_button = Button.new()
	end_card_button.name = "EndCardContinue"
	end_card_button.position = Vector2(355.0, 392.0)
	end_card_button.size = Vector2(250.0, 52.0)
	end_card_button.add_theme_font_size_override("font_size", 19)
	end_card_button.pressed.connect(_close_end_card)
	end_card.add_child(end_card_button)


func _end_card_label(text: String, rect: Rect2, font_size: int, tint: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_card.add_child(label)
	return label


## This run's three choices as the end card shows them: the relay, the mirror and the lane. The lane
## is saved with the sentry's fall (autosave C); a save from a build that did not store it says only
## that the tank came down.
func end_card_recap() -> Array[String]:
	var first_name: String = state.human_name().get_slice(" ", 0)
	var relay: String = RECAP_RELAY_PRESS if state.memory.get("choice_id") == M0State.PRESS else (RECAP_RELAY_COOPERATE if state.route == "cooperate" else RECAP_RELAY_DISCLOSE_BYPASS)
	var mirror: String = RECAP_MIRROR_WOLF if state.mirror_route == "wolf" else RECAP_MIRROR_MANUAL
	var lane: String = RECAP_LANE_UNKNOWN
	match state.lane_recap:
		"wolf":
			lane = RECAP_LANE_WOLF
		"broke_off":
			lane = RECAP_LANE_BROKE_OFF
		"refused":
			lane = RECAP_LANE_REFUSED
		"alone":
			lane = RECAP_LANE_ALONE
	var rows: Array[String] = []
	for row: String in [relay, mirror, lane]:
		rows.append(row.replace("{name}", first_name))
	return rows


func _show_end_card() -> void:
	Tweens.kill(chapter_tween)
	chapter_close_active = false
	hatch_exit_walking = false
	hatch_exit_engineer_walking = false
	end_card_active = true
	_stop_junction_loops()
	for child: Node in end_card_rows.get_children():
		end_card_rows.remove_child(child)
		child.queue_free()
	for row: String in end_card_recap():
		# "RELAY  Rowan told WOLF ...": the topic in the accent colour, then what happened.
		var split: int = row.find("  ")
		var line: HBoxContainer = HBoxContainer.new()
		line.add_theme_constant_override("separation", 14)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var topic: Label = Label.new()
		topic.text = row.left(split)
		topic.custom_minimum_size = Vector2(82.0, 0.0)
		topic.add_theme_font_override("font", DISPLAY_FONT)
		topic.add_theme_font_size_override("font_size", 15)
		topic.add_theme_color_override("font_color", END_CARD_ACCENT)
		var what: Label = Label.new()
		what.text = row.substr(split + 2)
		what.custom_minimum_size = Vector2(560.0, 0.0)
		what.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		what.add_theme_font_size_override("font_size", 17)
		what.add_theme_color_override("font_color", Color(0.82, 0.89, 0.94, 1))
		line.add_child(topic)
		line.add_child(what)
		end_card_rows.add_child(line)
	end_card.modulate.a = 0.0
	end_card.show()
	end_card.create_tween().tween_property(end_card, "modulate:a", 1.0, END_CARD_FADE_SECONDS)
	_update_controls()
	_refresh_ui()
	_grab_menu_focus(end_card_button)


## Any confirm on the END OF SLICE card goes on to the title, where Continue now offers PLAY AGAIN.
func _close_end_card() -> void:
	if not end_card_active:
		return
	_return_to_title()


func _hide_end_card() -> void:
	end_card_active = false
	end_card.hide()


func _choose_mirror(route_id: String) -> void:
	if route_id == "wolf" and absf(wolf.position.x - WOLF_MIRROR_X) > 42.0:
		status_line = "WOLF: I'm still checking the drive. Wait for me, or press 2 for the manual port."
		return
	if not state.preserve_mirror_trace(route_id):
		return
	# The copy lands with the stations' chirp; off WOLF's own readout it is pitched down.
	sfx_bank.play(&"chirp", -8.0, 0.8 if route_id == "wolf" else 1.0)
	waiting_for_choice = false
	choice_context = ""
	_update_controls()
	if route_id == "wolf":
		status_line = "WOLF reads the timestamp off his own readout. The purge target existed before the deletion order."
	else:
		status_line = "%s copies the timestamp through the maintenance port. WOLF keeps watch." % state.human_name().get_slice(" ", 0)
	_sync_records_room()
	_save_progress()


func _save_progress() -> void:
	# Every autosave starts a beat: the snapshot matches it even when the write fails.
	_mark_beat()
	_write_beat()


## Writes the beat snapshot to disk; a failure leaves save_pending set so the next USE retries.
func _write_beat() -> void:
	var snapshot: M0State = M0State.from_dict(beat_snapshot)
	save_pending = snapshot == null or not snapshot.save_to_disk(save_path)
	# Save errors belong to the system hint, never inside a character's dialogue line.
	save_error = SAVE_FAILED_HINT if save_pending else ""
	# A save that worked says so briefly in the hint bar (_refresh_ui keeps it off choices).
	checkpoint_toast_remaining = 0.0 if save_pending else CHECKPOINT_TOAST_SECONDS
	# Remember where it failed so the warning gives way to normal guidance once the player moves on.
	save_error_context = _context_hint()


func _capture_positions() -> void:
	# A save taken as the engineer steps out (beside a station, clear of the relay, to a crank spot)
	# keeps the spot they are stepping to, so Continue never puts them back over the machine.
	state.human_position = human.position if engineer_step_x < 0.0 else Vector2(engineer_step_x, human.position.y)
	state.wolf_position = wolf.position
	# Through the junction's open exit door they may stand past the room's edge (WOLF waits in its
	# doorway); a save keeps them inside the room's floor, and Continue walks WOLF back to the doorway.
	state.human_position.x = minf(state.human_position.x, M0Actor.MAX_X)
	state.wolf_position.x = minf(state.wolf_position.x, M0Actor.MAX_X)


## Remembers the state at the start of a beat. Before the first checkpoint there is no autosave,
## so a knockdown restores this instead; it carries the relay memory like a save would.
func _mark_beat() -> void:
	_capture_positions()
	beat_snapshot = state.to_dict()


## The station in reach that takes a held USE, or empty: the junction valve while its line builds, and
## the corridor's live MANUAL BYPASS until the seal opens.
func _hold_station() -> StringName:
	if state.chapter_id == "junction" and not state.door_blown and pressure_line.state == &"building" and absf(human.position.x - JunctionRoom.VALVE_X) <= 52.0:
		return &"valve"
	if state.chapter_id == "lockdown" and state.breaker_armed and not state.door_open and not waiting_for_choice and _at_bypass(human.position.x):
		return &"bypass"
	return &""


## USE at the Records exit once the first copy is secured: the service line to Archive begins.
func _enter_junction() -> void:
	if not state.enter_junction():
		return
	_sync_scene()
	# They came in through the entry from the service line passage: it stands open behind them and its
	# closer brings it shut (review r1, M5).
	junction_room.close_entry_behind()
	# A new room: cut the camera to the engineer instead of panning across from the Records exit.
	_start_gameplay_camera()
	wolf_scouting = true
	seam_read_seconds = 0.0
	ladder_seconds = 0.0
	ladder_step = 0
	door_bump_said = false
	door_faced = false
	_update_controls()
	status_line = JUNCTION_ENTRY_LINE % state.human_name().get_slice(" ", 0).to_upper()
	junction_entry_hold = box_seconds(status_line)
	# Autosave A: the start of the junction.
	_save_progress()


func _interact_junction(x: float) -> void:
	if absf(x - JunctionRoom.BREAKER_X) <= 52.0:
		if state.door_blown:
			_refuse(REFUSE_SPENT, &"breaker")
		elif pressure_line.arm():
			sfx_bank.play(&"clank", -4.0, 0.8)
			impact.rumble(0.15, 0.0, 0.06)
			junction_room.sync_line(pressure_line)
			# Armed: the ladder has done its job.
			ladder_step = 3
			_end_wolf_look()
			status_line = "The overload breaker catches and the line starts to build. If the LINE gauge peaks, the relief vent lets go."
		elif pressure_line.state == &"building":
			_refuse(REFUSE_BREAKER_LIVE, &"breaker")
		else:
			_refuse(REFUSE_FUSE_LIT, &"breaker")
	elif absf(x - JunctionRoom.VALVE_X) <= 52.0 and state.door_blown:
		_refuse(REFUSE_SPENT, &"valve")
	elif absf(x - JunctionRoom.VALVE_X) <= 52.0:
		match pressure_line.state:
			&"idle":
				_refuse(REFUSE_VALVE_DEAD, &"valve")
			&"tripped":
				_refuse(REFUSE_VALVE_TRIPPED, &"valve")
			&"building":
				status_line = "The wheel is stiff. Three full turns charge the door."
				# Cranked from just left of the wheel, like the MANUAL BYPASS, not from inside the valve.
				_step_engineer(VALVE_CRANK_X, JunctionRoom.VALVE_X)
			&"charged", &"fuse":
				_refuse(REFUSE_FUSE_LIT, &"valve")
			_:
				_refuse(REFUSE_SPENT, &"valve")
	elif PressureLine.is_on_vent(x) and not state.door_blown:
		status_line = "Relief vent. It lets go when the gauge peaks; don't be standing on it."
	elif absf(x - JunctionRoom.DOOR_X) <= 40.0 and not state.door_blown:
		_refuse(REFUSE_DOOR, &"door")
	elif state.door_blown and _at_arm_panel(x):
		_use_arm_panel()
	elif x >= JunctionRoom.BOLT_REACH_MIN_X:
		_use_exit(x)
	elif state.sentry_down:
		status_line = "No station in reach. The exit bolt is\nby the door."
	elif state.door_blown:
		status_line = "No station in reach. The TANK RELEASE\nis past the rubble."
	else:
		status_line = "No station in reach. The breaker is by the entrance, the valve by the door."


## True when a USE in the junction is the sealed door's: the engineer faces it and their front is
## closer to its face than they are to the valve's wheel (P0-15). While the line builds the valve answers
## (the crank), and while the fuse burns its warning does.
func _at_door_face(x: float) -> bool:
	if state.door_blown or human.body_sprite.flip_h or not (pressure_line.state in [&"idle", &"tripped"]):
		return false
	var gap: float = M0State.JUNCTION_DOOR_LEFT_X - (x + M0State.HUMAN_HALF_WIDTH)
	return gap >= -DOOR_BUMP_SLOP and gap < absf(x - JunctionRoom.VALVE_X)


## True when a USE in the junction is the sealed door's: at its face (_at_door_face), or come to rest
## from there with no move since. Stopped at the face, the engineer stands over the valve's body, so the
## settle slides them back to the valve's side (_update_settle); still facing the door, USE there stays
## the door's until any move input. Elsewhere the door_faced mark is dropped.
func _door_use(x: float) -> bool:
	if _at_door_face(x):
		return true
	if not door_faced or state.door_blown or human.body_sprite.flip_h or not (pressure_line.state in [&"idle", &"tripped"]):
		return false
	return x >= VALVE_CRANK_X - 1.0 and x + M0State.HUMAN_HALF_WIDTH < M0State.JUNCTION_DOOR_LEFT_X


## Keeps door_faced: set while the engineer is at the sealed door's face, dropped by any move input,
## facing away or losing control (a scripted step, a choice, a knockdown).
func _track_door_face() -> void:
	if _at_door_face(human.position.x):
		door_faced = true
	elif not human.controlled or human.body_sprite.flip_h or Input.get_axis(&"move_left", &"move_right") != 0.0:
		door_faced = false


## A refused press at [param station] (breaker, valve, door, release or bolt): the station's lamp
## flickers twice, a short dull clunk plays and [param line] shows; pressing again re-shows it with a
## blink of the box, so a second press visibly answers too.
func _refuse(line: String, station: StringName) -> void:
	sfx_bank.play(&"clank", REFUSE_CLUNK_DB, REFUSE_CLUNK_PITCH)
	junction_room.flicker(station, 2)
	if status_line == line:
		_blink_box()
	_aside(line)


## The dialogue box dips and comes back once, so a line shown again reads as a new answer.
func _blink_box() -> void:
	Tweens.kill(box_blink_tween)
	bottom_bar.modulate.a = BOX_BLINK_ALPHA
	box_blink_tween = create_tween()
	box_blink_tween.tween_property(bottom_bar, "modulate:a", 1.0, BOX_BLINK_SECONDS)


## Walking into the sealed door bumps it once per push: held against its face with right held, it
## thuds; stepping off (or letting go) lets the next push bump again.
func _check_door_bump() -> void:
	var pushing: bool = human.controlled and not state.door_blown and Input.get_axis(&"move_left", &"move_right") > 0.0 \
		and human.position.x + M0State.HUMAN_HALF_WIDTH >= M0State.JUNCTION_DOOR_LEFT_X - DOOR_BUMP_SLOP
	if pushing and not door_bump_latched:
		_door_bump()
	door_bump_latched = pushing


## The bump: a dull metal thud, the engineer's body gives a little and comes back (not with Reduced
## Motion), and the door's seam lamp flickers once. Only the first bump of a visit says why, so walking
## into it never floods the box; USE at the door still says it every time. Not over the fuse's warning.
func _door_bump() -> void:
	sfx_bank.play(&"thud", DOOR_THUD_DB, DOOR_THUD_PITCH)
	junction_room.flicker(&"door", 1)
	if impact.motion_allowed():
		Tweens.kill(door_recoil_tween)
		human.body_sprite.position.x = HUMAN_SPRITE_REST.x - DOOR_RECOIL_PX
		door_recoil_tween = create_tween()
		door_recoil_tween.tween_property(human.body_sprite, "position:x", HUMAN_SPRITE_REST.x, DOOR_RECOIL_SECONDS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if not door_bump_said and not _fuse_lit():
		door_bump_said = true
		status_line = REFUSE_DOOR


## The junction's hint ladder (PUZ-8): only while the breaker has never been armed this visit and the
## engineer has control, never during a choice or a knockdown (the game being paused stops it too).
func _tick_ladder(delta: float) -> void:
	if wolf_look_remaining > 0.0:
		wolf_look_remaining = maxf(wolf_look_remaining - delta, 0.0)
		if absf(wolf.position.x - wolf_look_x) <= 2.0:
			wolf.body_sprite.flip_h = JunctionRoom.BREAKER_X < wolf.position.x
		if wolf_look_remaining <= 0.0:
			_end_wolf_look()
	if ladder_step >= JUNCTION_LADDER_SECONDS.size():
		return
	if state.door_blown or pressure_line.state != &"idle":
		ladder_step = JUNCTION_LADDER_SECONDS.size()
		return
	if not human.controlled or waiting_for_choice or fail_active:
		return
	ladder_seconds += delta
	if ladder_seconds < JUNCTION_LADDER_SECONDS[ladder_step]:
		return
	ladder_step += 1
	var tag: String = _first_name().to_upper()
	match ladder_step:
		1:
			# T1: WOLF stops where he is and looks at the breaker; its lamp pulses. No text.
			wolf_look_x = wolf.position.x
			wolf_look_remaining = WOLF_LOOK_SECONDS
			junction_room.pulse_breaker(WOLF_LOOK_SECONDS)
			_update_controls()
		2:
			status_line = LADDER_BREAKER_LINE % tag
		3:
			_say([LADDER_BREAKER_LINE % tag, LADDER_CHAIN_LINE % tag])


## WOLF stops looking at the breaker and follows again.
func _end_wolf_look() -> void:
	if wolf_look_x < 0.0:
		return
	wolf_look_x = -1.0
	wolf_look_remaining = 0.0
	_update_controls()


## True in the TANK RELEASE alcove, the one spot that drops the tank (and hides the engineer).
func _at_arm_panel(x: float) -> bool:
	return x >= SentryBrain.COVER_MIN_X and x <= SentryBrain.COVER_MAX_X


## While WOLF draws the sentry, the release waits until he has it stopped on the mark ("Drop it when
## it stops") and he stands at his spot by the hatch, so the tank never falls on a sentry still on its
## way in or on WOLF still crossing the lane to draw it.
func _bait_holding() -> bool:
	return sentry_brain.is_holding(JunctionRoom.WOLF_BAIT_X) and absf(wolf.position.x - JunctionRoom.WOLF_BAIT_X) <= 4.0


## True while the release has to wait for WOLF: he is drawing the sentry and has not got it stopped on
## the mark yet. Once it is after the engineer he has backed off to his spot by the valve, so the
## release works as it does on the patrol.
func _drop_waits_for_wolf() -> bool:
	return wolf_baiting and not _sentry_hunting() and not _bait_holding()


## WOLF draws the sentry once his drawn front is over the rubble line into its lane, on his way to his
## spot at the far end of it.
func _wolf_drawing_x() -> float:
	return JunctionRoom.WOLF_BAIT_X if wolf_baiting and wolf.position.x + M0Actor.WOLF_REACH > SentryBrain.LANE_ENTRY_X else -1.0


func _use_arm_panel() -> void:
	if state.sentry_down:
		_refuse(REFUSE_RELEASE_SPENT, &"release")
		return
	match drop_arm.state:
		&"hung":
			if _drop_waits_for_wolf():
				_refuse(DROP_WAIT_LINE, &"release")
				return
			_drop_tank()
		&"rewinding":
			_refuse(REFUSE_REWINDING, &"release")
		_:
			pass


## USE at the release: the clamp lets go and the tank falls onto the floor mark. Where the sentry is
## when the tank lands decides the hit (DropArm.advance): its body over the brackets.
func _drop_tank() -> void:
	if not drop_arm.drop():
		return
	sfx_bank.play(&"clank", -3.0, 1.3)
	impact.rumble(0.15, 0.0, 0.06)
	junction_room.sync_arm(drop_arm)
	_tell("The clamp lets go.")


## The exit bolt panel and the exit door beside it: USE at the panel pops the bolt once the sentry is
## down; once the door is open, USE at the door itself (from JunctionRoom.HATCH_REACH_MIN_X, behind
## WOLF waiting in its doorway) leaves through it. At the panel the hint points to the open door.
func _use_exit(x: float) -> void:
	if not state.door_blown:
		_refuse(REFUSE_EXIT_DOOR, &"bolt")
	elif not state.sentry_down:
		_refuse(REFUSE_EXIT_SENTRY, &"bolt")
	elif state.junction_cleared:
		_tell(JUNCTION_CLEARED_LINE)
	else:
		match bolt_state:
			&"locked":
				_pop_bolt()
			&"charging":
				_tell(BOLT_CHARGING_LINE)
			_:
				# Not through a hatch that is still sliding, nor from the bolt panel: the engineer walks up to
				# the doorway first (the hint says the hatch is open).
				if not _hatch_sliding() and x >= JunctionRoom.HATCH_REACH_MIN_X:
					_leave_junction()


func _pop_bolt() -> void:
	bolt_state = &"charging"
	bolt_charge_remaining = BOLT_WHINE_SECONDS
	sfx_bank.play(&"whine", -4.0)
	junction_room.sync_bolt(bolt_state, 0.0)
	_tell(POP_BOLT_LINE)


## The whine peaks: the bolt arcs and drops with a clank, and the hatch starts to slide open; the line
## says it is open only once it is (_hatch_opened).
func _bolt_arc() -> void:
	bolt_state = &"open"
	bolt_charge_remaining = 0.0
	# The bolt's arc started under the end of the whine (_tick_lane); its crack lands now.
	sfx_bank.play(&"clank", -2.0, 0.7)
	impact.flash(0.12, 0.0)
	impact.add_trauma(0.8)
	impact.rumble(0.5, 0.8, 0.2)
	impact.burst(junction_room.bolt_sparks)
	junction_room.sync_bolt(bolt_state, 1.0)
	junction_room.bolt_arc()
	if not fail_active:
		_tell(BOLT_ARC_LINE)


## The engineer stands at the junction's exit, where USE leaves through it, not at the bolt panel: the
## bolt has dropped and they are at or past JunctionRoom.HATCH_REACH_MIN_X.
func _at_open_exit(x: float) -> bool:
	return bolt_state == &"open" and x >= JunctionRoom.HATCH_REACH_MIN_X


## The junction's exit door stands open (sliding open finished, or a cleared junction restored).
func _exit_door_open() -> bool:
	return state.chapter_id == "junction" and state.sentry_down and junction_room != null and junction_room.hatch_open >= 1.0


## The bolt has dropped and the hatch is still sliding open; it is not a way out until it has.
func _hatch_sliding() -> bool:
	return bolt_state == &"open" and not state.junction_cleared and junction_room.hatch_open < 1.0


## The exit door has finished opening: WOLF steps into its doorway (_wolf_target_x).
func _hatch_opened() -> void:
	if not fail_active and status_line == BOLT_ARC_LINE:
		_tell(HATCH_OPENED_LINE)
	_update_controls()


## USE at the open hatch: the junction is cleared, autosave D is written, and a short closing beat
## plays before the title.
func _leave_junction() -> void:
	if not state.clear_junction():
		return
	# The room knows it is cleared from now (its plates settle for the closing shot), as a restore shows it.
	junction_room.junction_cleared = true
	# Autosave D: the service line is clear.
	_save_progress()
	# The room's lights switch over with a contactor's clunk, as at the safe point.
	sfx_bank.play(&"clank", -6.0, 0.65)
	_sync_room_lights(true)
	chapter_close_active = true
	intro_camera.position_smoothing_enabled = false
	_update_controls()
	_tell("SERVICE LINE CLEARED. WOLF: It's quiet now. The line runs on toward Archive.\n%s: Then that's where we go." % state.human_name().get_slice(" ", 0).to_upper())
	chapter_tween = create_tween()
	_frame_chapter_close()


## Starts the junction's chapter-close camera move on chapter_tween (JUNCTION_CLOSE_CAMERA at
## JUNCTION_CLOSE_ZOOM, over 0.5 s), so the exit door and both actors share the shot.
func _frame_chapter_close() -> void:
	chapter_tween.tween_property(intro_camera, "position", JUNCTION_CLOSE_CAMERA, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	chapter_tween.parallel().tween_property(intro_camera, "zoom", Vector2.ONE * JUNCTION_CLOSE_ZOOM, 0.5)


## Runs the pressure line every frame in the junction: held USE at the valve cranks it, the line
## advances, and its events (vent trip, fuse, blast) answer with real state changes.
func _tick_junction(delta: float) -> void:
	pressure_line.paused = waiting_for_choice
	junction_room.advance_display(delta)
	if hold_use.holding and hold_use.station == &"valve":
		var gained: int = pressure_line.crank(delta)
		if gained > 0:
			_valve_turned()
	else:
		pressure_line.release()
	match pressure_line.advance(delta):
		&"tripped":
			_vent_trips()
		&"fuse", &"tick":
			_fuse_ticked()
		&"blown":
			_door_blast()
	junction_entry_hold = maxf(junction_entry_hold - delta, 0.0)
	if wolf_scouting and absf(wolf.position.x - JunctionRoom.WOLF_SEAM_X) <= 4.0:
		# He stands facing the valve, reading its LINE gauge; once the engineer's entry line has been up
		# long enough to read, he speaks.
		wolf.body_sprite.flip_h = false
		seam_read_seconds += delta
		if seam_read_seconds >= WOLF_GAUGE_READ_SECONDS and junction_entry_hold <= 0.0:
			_wolf_reads_seam()
	_tick_ladder(delta)
	_check_door_bump()
	_track_door_face()
	if wolf.autonomous_target_x == JunctionRoom.WOLF_BAIT_X and absf(wolf.position.x - JunctionRoom.WOLF_BAIT_X) <= 2.0:
		# At the far end of the lane he faces back down it: at the sentry he draws, then at the engineer.
		wolf.body_sprite.flip_h = true
	if wolf.autonomous_target_x == JunctionRoom.WOLF_DOORWAY_X and absf(wolf.position.x - JunctionRoom.WOLF_DOORWAY_X) <= 2.0:
		# In the open doorway he waits looking back at the engineer, his head and shoulders in view
		# and the rest of him already past the near jamb; he turns to go once they leave.
		wolf.body_sprite.flip_h = true
	# The line's phase moves WOLF (clear of the vent and the blast while it is live).
	if not fail_active and wolf.autonomous_target_x != _wolf_target_x():
		_update_controls()
	junction_room.sync_line(pressure_line)
	_tick_lane(delta)
	# The hiss and the pump's pitch are functions of the gauge, nothing else: the recorded steam keeps
	# its pitch but crossfades from its low-gauge loop to its high-gauge loop and gets louder, and it
	# spikes through the vent's hard warning.
	if pressure_line.state == &"building":
		sfx_bank.play_blend(SfxBank.HISS_GAUGE, pressure_line.gauge, -2.0 if pressure_line.is_warning() else lerpf(-28.0, -6.0, pressure_line.gauge))
	else:
		sfx_bank.stop_each(SfxBank.HISS_GAUGE)
	if state.door_blown:
		sfx_bank.stop(&"hum")
	else:
		sfx_bank.play(&"hum", lerpf(-16.0, -9.0, pressure_line.gauge), 0.5 * (1.0 + 0.6 * pressure_line.gauge))


## The lane past the door: the sentry wakes, patrols, locks on and chases, or holds on WOLF; the arm falls,
## rewinds and vents; the bolt charges. None of it runs during a choice (paused) or a knockdown or
## while the game is paused (_process does not reach here). Contact with a chasing sentry is a
## knockdown back to autosave B.
func _tick_lane(delta: float) -> void:
	sentry_brain.paused = waiting_for_choice or _debug_sentry_frozen()
	drop_arm.paused = waiting_for_choice
	if state.door_blown and not waiting_for_choice:
		if sentry_wake_remaining > 0.0:
			sentry_wake_remaining = maxf(sentry_wake_remaining - delta, 0.0)
			if sentry_wake_remaining <= 0.0:
				sentry_brain.wake()
		var x: float = human.position.x
		# The tank lands first, against where the sentry stands at the start of this frame, so the
		# sentry's own move this frame can never carry it under a tank that was already falling.
		match drop_arm.advance(delta, sentry_brain.x):
			&"hit":
				_tank_hit()
			&"miss":
				_tank_miss()
			&"rehung":
				_tank_rehung()
		# A missed tank on the floor, or on its way up, stands in the sentry's lane: it stops at its edge.
		sentry_brain.obstacle = DropArm.footprint() if drop_arm.blocks_lane() else Vector2.ZERO
		# The tank also hides what is behind it while it stands at the scanner's height: on the floor,
		# or low in its fall or lift (its base under the beam's top), across its drawn width.
		var tank_base: float = lerpf(JunctionRoom.TANK_REST_Y, JunctionRoom.landed_tank_y(false), drop_arm.drop_amount()) + JunctionRoom.TANK_SIZE.y * 0.5
		var tank_half: float = JunctionRoom.TANK_SIZE.x * 0.5
		sentry_brain.sight_block = Vector2(DropArm.MARK_X - tank_half, DropArm.MARK_X + tank_half) if tank_base > Sentry.beam_top_y() else Vector2.ZERO
		# WOLF draws it only once his front is over the rubble line; it then parks BAIT_OFFSET short of
		# his spot by the hatch, on the mark.
		var bait_x: float = _wolf_drawing_x()
		# It keeps its eyes on WOLF himself while he crosses to his spot.
		sentry_brain.watch_x = wolf.position.x if bait_x >= 0.0 else -1.0
		# With all of WOLF's drawn body past it, down the lane by the hatch, it turns short of him and its
		# beam stops at him.
		var wolf_near_x: float = wolf.position.x - M0Actor.WOLF_REACH
		var wolf_beyond: bool = wolf_near_x > sentry_brain.x + SentryBrain.HALF_WIDTH and wolf_near_x > SentryBrain.LANE_ENTRY_X
		sentry_brain.far_x = wolf_near_x - SentryBrain.HALF_WIDTH - WOLF_SENTRY_GAP if wolf_beyond else SentryBrain.PATROL_MAX_X
		junction_room.sentry.beam_stop_x = wolf_near_x if wolf_beyond else INF
		_keep_off_sentry()
		x = human.position.x
		var before: StringName = sentry_brain.state
		sentry_brain.tick(delta, x, SentryBrain.is_exposed(x), bait_x)
		if sentry_brain.state != before:
			_sentry_changed(before)
		_pace_miss_turn()
		# The moment it stops on the mark the "Wait" gives way to the go, the same frame the hint offers
		# the drop.
		if status_line == DROP_WAIT_LINE and _bait_holding():
			status_line = DROP_PARKED_LINE
		if bolt_state == &"charging":
			var charge_before: float = bolt_charge_remaining
			bolt_charge_remaining = maxf(bolt_charge_remaining - delta, 0.0)
			# The arc's buzz and crackle build under the end of the whine, so its crack lands on the drop.
			if charge_before > SfxBank.BOLT_CRACK_SECONDS and bolt_charge_remaining <= SfxBank.BOLT_CRACK_SECONDS:
				sfx_bank.play(&"bolt_arc", 0.0)
			if bolt_charge_remaining <= 0.0:
				_bolt_arc()
	junction_room.sentry.follow(sentry_brain)
	if engineer_waits_for_wolf and (not wolf_baiting or wolf.position.x - M0Actor.WOLF_REACH >= human.position.x + M0Actor.HUMAN_REACH):
		# WOLF is past them: the engineer has their controls back.
		engineer_waits_for_wolf = false
		_update_controls()
	_sync_wolf_leap()
	junction_room.sync_arm(drop_arm)
	junction_room.sync_bolt(bolt_state, 1.0 - bolt_charge_remaining / BOLT_WHINE_SECONDS if bolt_state == &"charging" else (1.0 if bolt_state == &"open" else 0.0))
	_lane_sound()
	if fail_active or not state.door_blown or state.sentry_down:
		return
	if lane_choice.is_empty() and not waiting_for_choice and (human.controlled or lane_question_held) and human.position.x >= JunctionRoom.CHOICE_X:
		if not _hold_for_lane_question():
			_ask_lane()
	elif sentry_brain.touches(human.position.x):
		_fail_beat(_sentry_reason(), true)


## WOLF bounds over the live sentry when his way along the lane crosses it (to his spot by the hatch),
## and over the crushed tank once it is down, quicker for the moment he is up, so the bodies never
## meet; the lift is on his sprite's offset, so his reactions still play on its position. He dashes at
## the same speed past the engineer, who waits for him at the rubble line (engineer_waits_for_wolf).
func _sync_wolf_leap() -> void:
	var lift: float = 0.0
	var duck: float = 0.0
	if state.chapter_id == "junction" and state.door_blown and wolf.autonomous_target_x >= 0.0:
		if state.sentry_down:
			lift = JunctionRoom.wolf_tank_leap_height(wolf.position.x)
		else:
			lift = JunctionRoom.wolf_leap_height(wolf.position.x, sentry_brain.x)
			if drop_arm.state == &"hung":
				# Under the hung tank he ducks (JunctionRoom.wolf_duck_depth).
				duck = JunctionRoom.wolf_duck_depth(wolf.position.x, -1.0 if wolf.body_sprite.flip_h else 1.0)
	wolf.speed_scale = JunctionRoom.LEAP_SPEED_SCALE if lift > 0.0 or engineer_waits_for_wolf else (HATCH_EXIT_SPEED_SCALE if hatch_exit_walking else 1.0)
	# The duck squashes his drawn body from the feet up: the sprite is shorter and shifted down by what
	# the squash takes off below its centre, so his feet stay on the floor.
	var squash: float = (WOLF_DRAWN_HEIGHT - duck) / WOLF_DRAWN_HEIGHT
	# Past the blast he never stands inside the valve: over it, he walks on the deck a pace in front of it
	# (JunctionRoom.wolf_valve_step), his feet and his reflection lower, and he draws over the engineer
	# there, as anything nearer the camera does. (The actors are drawn at one scale wherever they stand.)
	var step: float = JunctionRoom.wolf_valve_step(wolf.position.x) if state.chapter_id == "junction" and state.door_blown else 0.0
	wolf.body_sprite.scale = Vector2(wolf_sprite_scale.x, wolf_sprite_scale.y * squash)
	wolf.body_sprite.offset.y = -lift / wolf.body_sprite.scale.y + WOLF_FEET_BELOW_CENTRE * (1.0 - squash) / squash
	if state.chapter_id == "junction":
		var down: float = JunctionRoom.WOLF_STEP_FORWARD * step
		wolf.body_sprite.position.y = WOLF_SPRITE_REST.y + down
		if wolf_reflection != null:
			wolf_reflection.floor_y = wolf_reflection_floor_y + down
	var in_front: bool = step > 0.5
	if in_front != (wolf.get_index() > human.get_index()):
		move_child(wolf, human.get_index() + (1 if in_front else 0) - (1 if wolf.get_index() < human.get_index() else 0))


## The sentry's knockdown card. The alcove advice is only for an engineer it saw out in the lane and
## caught there; after a miss turned it, or with the engineer caught inside the alcove, the card
## points only at the rubble, because a chase reaches anywhere in the alcove.
func _sentry_reason() -> String:
	return (JunctionRoom.SENTRY_REASON if _seen_in_lane() else JunctionRoom.SENTRY_CHASED_REASON) % _first_name()


## The sentry saw the engineer out in its lane (past the alcove's right post) and is running them down
## there, rather than chasing them after a miss or reaching them inside the alcove.
func _seen_in_lane() -> bool:
	return not sentry_brain.turned_by_miss and SentryBrain.is_exposed(human.position.x)


## The servo follows the sentry's state (it idles low through the lock-on beat and runs higher in a
## chase); the winch runs once it takes a missed tank off the floor, and the coolant cloud hisses
## while it hangs there, fading over its last COOLANT_FADE_SECONDS.
func _lane_sound() -> void:
	match sentry_brain.state:
		&"patrol":
			sfx_bank.play(&"servo", -22.0, 1.0)
		&"lock":
			sfx_bank.play(&"servo", -24.0, 0.8)
		&"fixated":
			sfx_bank.play(&"servo", -19.0, 1.15)
		&"chase":
			sfx_bank.play(&"servo", -16.0, 1.4)
		&"dormant":
			sfx_bank.stop(&"servo")
	if drop_arm.winching():
		sfx_bank.play(&"winch", -14.0)
	else:
		sfx_bank.stop(&"winch")
	if drop_arm.cloud_active():
		sfx_bank.play(&"coolant_cloud", -6.0 + linear_to_db(clampf(drop_arm.cloud_remaining / COOLANT_FADE_SECONDS, 0.0001, 1.0)))
	else:
		sfx_bank.stop(&"coolant_cloud")


func _sentry_changed(before: StringName) -> void:
	# Locking on sends a drawing WOLF back to his spot by the valve until the chase ends.
	wolf.autonomous_target_x = _wolf_target_x()
	if sentry_brain.state == &"lock":
		_sentry_alarm()
	if fail_active:
		return
	match sentry_brain.state:
		&"lock":
			if before == &"patrol" or before == &"fixated":
				status_line = SENTRY_LOCK_LINE % _first_name()
		&"patrol":
			if before == &"chase":
				status_line = SENTRY_LOST_LINE % _first_name()


## The lock-on cue: a short, high klaxon chirp from the sound bank as the sentry's eye goes red.
func _sentry_alarm() -> void:
	sfx_bank.play(&"klaxon", -8.0, 1.6)


## True while the engineer holds at the rubble line for the rest of the blast's line ("Past the
## doorway, something whirs awake."): reaching the line brings that box up at once, without waiting out
## the first one's reading time, and the question waits until it has been up its own (box_seconds), so
## the question never replaces a box the player has not seen.
func _hold_for_lane_question() -> bool:
	if not lane_question_held:
		var wake_to_come: bool = not box_queue.is_empty() and box_queue[0] == RUBBLE_WAKE_LINE
		var wake_up: bool = status_line == RUBBLE_WAKE_LINE and box_queue_line == RUBBLE_WAKE_LINE and box_queue_seconds > 0.0
		if not wake_to_come and not wake_up:
			return false
		lane_question_held = true
		human.velocity = Vector2.ZERO
		_update_controls()
		if wake_to_come:
			_next_box_now()
	if status_line == RUBBLE_WAKE_LINE and box_queue_seconds > 0.0:
		return true
	lane_question_held = false
	return false


## At the rubble line WOLF asks how to bring the sentry down; the brain and the arm hold still until
## the answer.
func _ask_lane() -> void:
	waiting_for_choice = true
	choice_context = "lane"
	_update_controls()
	status_line = "WOLF: It passes under that tank on every patrol. How do we bring it down?\n1  \"%s\"\n2  \"%s\"" % [LANE_CHOICE_TEXT[0], LANE_CHOICE_TEXT[1]]


## Answer 1 asks WOLF to draw it; he chooses by the same rule as the relay contact. Answer 2, or his
## refusal, leaves the engineer to time the drop on the patrol. Neither costs anything.
func _choose_lane(response: int) -> void:
	if not waiting_for_choice or choice_context != "lane":
		return
	waiting_for_choice = false
	choice_context = ""
	if response == 1 and state.wolf_will_bait():
		lane_choice = "wolf"
		wolf_baiting = true
		# The engineer lets him go first: he dashes past them here, at the rubble line, not later at
		# the release.
		engineer_waits_for_wolf = true
		status_line = BAIT_YES_LINE
		_react_as_wolf(true)
		sfx_bank.play(&"growl_warning", -5.0)
	elif response == 1:
		lane_choice = "refused"
		status_line = BAIT_NO_LINE
		_react_as_wolf(false)
		sfx_bank.play(&"growl_refusal", -3.5)
	else:
		lane_choice = "alone"
		# He settles to hold back by the valve: a quieter whir than an answer he leans into.
		sfx_bank.play(&"actuator", -12.0, 0.85)
		_say(ALONE_LINES)
	_update_controls()


## BOOM 2: the tank comes down on the sentry. Autosave C.
func _tank_hit() -> void:
	# The tank pins the machine where it stands (at most HIT_REACH off the mark, with a quarter of its
	# body or more under the tank), so the wreck never jumps; Continue from autosave C lays it on the mark.
	var at_x: float = sentry_brain.x
	sentry_brain.knock_down()
	if not state.drop_sentry():
		return
	# For the end card, saved with autosave C: WOLF drew it only if he still was when it fell; after
	# breaking off short of the sentry he held back by the valve while the engineer timed it.
	state.lane_recap = "wolf" if wolf_baiting else ("broke_off" if wolf_holding_far_end else ("refused" if lane_choice == "refused" else "alone"))
	wolf_baiting = false
	junction_room.sentry_down = true
	junction_room.tank_hit(at_x)
	sfx_bank.play(&"boom", 0.0)
	# A glassy top over the boom: the tank's shell giving.
	sfx_bank.play(&"clank", -4.0, 2.2)
	impact.hit_stop(0.09)
	impact.flash(0.09, 0.0)
	impact.add_trauma(1.0)
	impact.rumble(0.7, 1.0, 0.3)
	impact.burst(junction_room.coolant_burst)
	impact.burst(junction_room.hit_sparks)
	_fade_servo()
	_update_controls()
	_drop_box_queue()
	_say([TANK_HIT_OFF_CENTRE_LINE if absf(at_x - DropArm.MARK_X) > OFF_CENTRE_HIT else TANK_HIT_LINE, TANK_HIT_WOLF_LINE])
	# Autosave C: the sentry is down.
	_save_progress()


## The tank hit the empty mark: it dents and lies there spraying coolant from a split line until the
## winch hauls it back up (DropArm.FLOOR_SECONDS), and the sentry turns on the release, held at the
## tank's edge while it lies in the lane. If WOLF was drawing it, he breaks off for this attempt.
func _tank_miss() -> void:
	junction_room.tank_miss()
	sfx_bank.play(&"clank", -2.0, 0.55)
	sfx_bank.play(&"thud", -3.0, 0.8)
	impact.add_trauma(0.3)
	impact.rumble(0.3, 0.5, 0.15)
	impact.burst(junction_room.coolant_burst)
	var was: StringName = sentry_brain.state
	sentry_brain.alert()
	if sentry_brain.state == &"lock" and was != &"lock":
		_sentry_alarm()
	var broke_off: bool = wolf_baiting
	if broke_off:
		wolf_baiting = false
		wolf_broke_off = true
		# Already past the sentry he stays by the hatch; he will not cross back under the tank.
		wolf_holding_far_end = wolf.position.x > sentry_brain.x
		_react_as_wolf(false)
	_update_controls()
	var boxes: Array[String] = [TANK_MISS_LINE, TANK_MISS_TURN_LINE]
	if broke_off:
		boxes.append(BROKE_OFF_HATCH_LINE if wolf_holding_far_end else BROKE_OFF_RUBBLE_LINE)
	_say(boxes)


## The miss's second box ("The sentry swings toward the release; / get back over the rubble.") is
## said as the sentry swings into its chase, after its lock-on beat, while the engineer is still in
## its lane; if they are already over the rubble by then, or the chase is over, it is dropped, since
## there is nothing left to tell (the knockdown card says the same if it catches them). The boxes
## after it keep their own pace.
func _pace_miss_turn() -> void:
	if box_queue.is_empty() or box_queue[0] != TANK_MISS_TURN_LINE:
		return
	if sentry_brain.state == &"lock":
		return
	if sentry_brain.state == &"chase" and human.position.x > SentryBrain.LANE_ENTRY_X:
		# A sentry already chasing has no lock-on beat; the box before still gets that long.
		if box_seconds(box_queue_line) - box_queue_seconds >= SentryBrain.LOCK_SECONDS:
			_next_box_now()
	else:
		box_queue.pop_front()


func _tank_rehung() -> void:
	sfx_bank.play(&"clank", -6.0, 1.1)
	if not fail_active:
		# Still telling the miss (WOLF breaking off, say), it waits its turn after those boxes.
		_say_next("The winch has the tank back on the clamp. The TANK RELEASE is ready again.")


## The sentry's servo winds down to nothing as it goes over.
func _fade_servo() -> void:
	_kill_servo_tween()
	var player: AudioStreamPlayer = sfx_bank.play(&"servo", -16.0, 1.4)
	if player == null:
		return
	servo_tween = create_tween()
	servo_tween.tween_property(player, "pitch_scale", 0.2, 0.6)
	servo_tween.parallel().tween_property(player, "volume_db", -40.0, 0.6)
	servo_tween.tween_callback(sfx_bank.stop.bind(&"servo"))


func _kill_servo_tween() -> void:
	Tweens.kill(servo_tween)
	servo_tween = null


func _stop_junction_loops() -> void:
	_kill_servo_tween()
	sfx_bank.stop_each(SfxBank.LOOPS)


## One real valve turn: a click, a weak rumble and the VALVE plate counts it; the third turn lights the fuse.
func _valve_turned() -> void:
	sfx_bank.play(&"clank", -6.0, 1.4)
	impact.rumble(0.2, 0.0, 0.08)
	if pressure_line.state == &"charged":
		sfx_bank.play(&"klaxon", -4.0)
		_tell("FUSE LIT. Back away from the door, past the valve.")
	else:
		status_line = "The valve gives. %d of %d turns." % [pressure_line.turns, PressureLine.TURNS_NEEDED]


## The fuse ticks as it lights and every PressureLine.FUSE_TICK_SECONDS after, on the frame the blast
## stripes peak; each tick is a little higher than the last, so the sound alone says time is running out.
func _fuse_ticked() -> void:
	sfx_bank.play(&"fuse_tick", -5.0, 1.0 + 0.08 * (pressure_line.fuse_ticks - 1))


## The gauge peaked before the third turn: the relief vent lets go (a thump under a burst of
## steam) and the breaker trips.
func _vent_trips() -> void:
	junction_room.vent_blows()
	sfx_bank.play(&"small_boom", -2.0)
	sfx_bank.play(&"vent_burst", -1.0)
	impact.add_trauma(0.5)
	impact.flash(0.0, 0.2)
	impact.rumble(0.4, 0.6, 0.2)
	if not fail_active:
		status_line = "The relief vent lets go and the breaker trips. Reset the breaker and crank faster this time."


func _wolf_reads_seam() -> void:
	wolf_scouting = false
	_react_as_wolf(false)
	sfx_bank.play(&"growl_seam", -3.0)
	status_line = WOLF_DOOR_WARNING
	_update_controls()


## BOOM 1: the fuse ends. PressureLine.is_in_blast is the one test of the outcome: in the zone the
## door is still seen to blow (burst and torn frame) and then it is a knockdown back to autosave A,
## whose restore brings the sealed door back; otherwise the door goes, the rubble lands and
## autosave B marks the beat. The blast has no hurtbox of its own, so physics overlap can never
## disagree with this test.
func _door_blast() -> void:
	# A door that is already down has nothing left to blow: no boom, no knockdown.
	if state.door_blown:
		return
	_blast_feedback()
	if PressureLine.is_in_blast(human.position.x) and not _debug_spares_knockdown():
		junction_room.door_blast()
		_fail_beat(JunctionRoom.BLAST_REASON % state.human_name().get_slice(" ", 0))
		return
	if not state.blow_door():
		return
	junction_room.door_blast()
	sentry_wake_remaining = SENTRY_WAKE_SECONDS
	_update_controls()
	_say([RUBBLE_LINE % _first_name(), RUBBLE_WAKE_LINE])
	# Autosave B: the door is down.
	_save_progress()


func _blast_feedback() -> void:
	sfx_bank.stop_each(SfxBank.HISS_GAUGE)
	sfx_bank.play(&"boom", 0.0)
	impact.hit_stop(0.07)
	impact.flash(0.09, 0.3)
	impact.add_trauma(1.0)
	impact.rumble(0.7, 1.0, 0.3)


## One path for every knockdown: a readable reaction (hit-stop, red wash, the engineer collapses onto
## the floor with a thud and rumble), controls off briefly, a short fade, then the current beat's
## autosave comes back through _load_game/_sync_scene. Memory and Records flags are never touched.
## With Reduced Motion the collapse cuts straight to lying on the floor and the hit-stop and shake are
## skipped; the thud, wash and fade remain. [param by_sentry]: the sentry ran the engineer down
## (_start_collapse).
func _fail_beat(reason: String, by_sentry: bool = false) -> void:
	if fail_active or title_open or intro_active or chapter_close_active or end_card_active or _debug_spares_knockdown():
		return
	var in_lane: bool = by_sentry and _seen_in_lane()
	fail_active = true
	_drop_box_queue()
	for action: StringName in GAMEPLAY_ACTIONS:
		Input.action_release(action)
	waiting_for_choice = false
	choice_context = ""
	wolf_heading_to_relay = false
	engineer_step_x = -1.0
	engineer_waits_for_wolf = false
	lane_question_held = false
	human.velocity = Vector2.ZERO
	_update_controls()
	impact.hit_stop(0.06)
	impact.flash(0.0, 0.3)
	impact.add_trauma(0.6)
	impact.rumble(0.5, 0.9, 0.25)
	sfx_bank.play(&"thud", 0.0, 0.9)
	human.z_index = KNOCKDOWN_Z
	_cancel_door_recoil()
	_cancel_fail_tween()
	_start_collapse(by_sentry, in_lane)
	if impact.motion_allowed():
		fail_tween = create_tween()
		fail_tween.tween_method(_show_collapse, 0.0, COLLAPSE_SECONDS, COLLAPSE_SECONDS)
	else:
		_show_collapse(COLLAPSE_SECONDS)
	# The card holds until RETRY (_retry), from RETRY_READY_SECONDS.
	fail_age = 0.0
	fail_reason = reason
	retrying = false
	status_line = reason
	_refresh_ui()


## Which way and where the engineer goes down. The painted collapse is a slump forward, so the body
## falls the way the engineer faced, with the boots where they stood; the sprite never turns round at
## the hit. Run down by the sentry, they go down at the distance the bodies touched (_keep_off_sentry).
## Caught out in its lane ([param in_lane]) facing right, away from the alcove, the boots move on along
## the fall as far as it takes to leave all of the lying body LANE_FALL_CLEAR past the alcove's right
## post (so the card's advice never reads as failing); facing back towards the alcove they slump
## forward where they stand, never dragged back against the fall. Whatever knocked them down, a live
## sentry in the junction rolls back off them (Sentry.recoil_to; with Reduced Motion it is put there at
## once) as far as it takes for its drawn body to stand LANE_FALL_CLEAR clear of theirs, and a body
## that would lie into a missed tank on the floor or under the foot of the blast door's near column
## ends short of it.
func _start_collapse(by_sentry: bool, in_lane: bool) -> void:
	collapse_flip = human.body_sprite.flip_h
	collapse_fall = -1.0 if collapse_flip else 1.0
	if by_sentry:
		_keep_off_sentry()
	collapse_from_x = human.position.x
	collapse_to_x = human.position.x
	if in_lane and collapse_fall > 0.0:
		collapse_to_x = maxf(human.position.x, SentryBrain.COVER_MAX_X + LANE_FALL_CLEAR - COLLAPSE_SPANS[-1].x * COLLAPSE_SCALE)
	collapsed = true
	if state.chapter_id != "junction":
		return
	# A missed tank low on the mark (its base below the top of the lying body; it only rises from there)
	# is solid too: a slump that would reach it ends LANE_FALL_CLEAR short of its drawn sides, the boots
	# staggering back from it as the knees go (this wins over the lane's post, as the gap between the
	# two is shorter than the lying body).
	var tank_base: float = lerpf(JunctionRoom.TANK_REST_Y, JunctionRoom.landed_tank_y(false), drop_arm.drop_amount()) + JunctionRoom.TANK_SIZE.y * 0.5
	if tank_base > JunctionRoom.FLOOR_Y - collapse_height(COLLAPSE_ART.size() - 1):
		var tank_from: float = DropArm.MARK_X - JunctionRoom.TANK_SIZE.x * 0.5 - LANE_FALL_CLEAR
		var tank_to: float = DropArm.MARK_X + JunctionRoom.TANK_SIZE.x * 0.5 + LANE_FALL_CLEAR
		var lying: Vector2 = collapse_span(COLLAPSE_SPANS.size() - 1, collapse_fall, collapse_to_x)
		if lying.y > tank_from and lying.x < tank_to:
			collapse_to_x += tank_from - lying.y if human.position.x < DropArm.MARK_X else tank_to - lying.x
	# The blast door's near column draws over the actors, sealed or blown: a slump that would reach under
	# its foot (JunctionRoom.DOOR_FOOT_X..DOOR_FOOT_RIGHT_X) ends LANE_FALL_CLEAR short of it on the side
	# the engineer stood (facing it from the valve when the door blows, or from the lane running back for
	# the rubble), the boots thrown back from the door as the knees go, so no part of the lying body is
	# hidden.
	var door_lying: Vector2 = collapse_span(COLLAPSE_SPANS.size() - 1, collapse_fall, collapse_to_x)
	if door_lying.y > JunctionRoom.DOOR_FOOT_X - LANE_FALL_CLEAR and door_lying.x < JunctionRoom.DOOR_FOOT_RIGHT_X + LANE_FALL_CLEAR:
		if human.position.x < (JunctionRoom.DOOR_FOOT_X + JunctionRoom.DOOR_FOOT_RIGHT_X) * 0.5:
			collapse_to_x -= door_lying.y - (JunctionRoom.DOOR_FOOT_X - LANE_FALL_CLEAR)
		else:
			collapse_to_x += JunctionRoom.DOOR_FOOT_RIGHT_X + LANE_FALL_CLEAR - door_lying.x
	if not sentry_brain.is_solid():
		return
	var body: Vector2 = collapse_span(COLLAPSE_SPANS.size() - 1, collapse_fall, collapse_to_x)
	var sentry: Sentry = junction_room.sentry
	var sentry_reach: float = Sentry.drawn_half_width()
	# With Reduced Motion the body is shown lying at once (_fail_beat), so the machine is put clear of
	# it on that same frame instead of rolling back over the next ones.
	var at_once: bool = not impact.motion_allowed()
	if sentry.position.x >= human.position.x:
		sentry.recoil_to(maxf(sentry.position.x, body.y + LANE_FALL_CLEAR + sentry_reach), at_once)
	else:
		sentry.recoil_to(minf(sentry.position.x, body.x - LANE_FALL_CLEAR - sentry_reach), at_once)


## The sentry is a solid machine: an engineer who walks into it stops where the drawn bodies touch
## (SentryBrain.CONTACT_RANGE), so the two never overlap, whether it is patrolling, locking on or
## holding on WOLF; a chase that reaches them there is a knockdown, which lands at that distance too
## (their last step may have taken them closer; it is checked once a frame).
func _keep_off_sentry() -> void:
	if not sentry_brain.is_solid():
		return
	var gap: float = human.position.x - sentry_brain.x
	if absf(gap) < SentryBrain.CONTACT_RANGE and gap != 0.0:
		human.position.x = sentry_brain.x + signf(gap) * SentryBrain.CONTACT_RANGE
		human.velocity.x = 0.0


## Frame [param t] seconds into the collapse: the painted frame for that moment, the boots eased from
## where they stood to where they lie, the soles on the floor line, and the shadow under the body.
func _show_collapse(t: float) -> void:
	var frame: int = 0
	for index: int in COLLAPSE_TIMES.size():
		if t >= COLLAPSE_TIMES[index] - 0.0001:
			frame = index
	var boots: float = lerpf(collapse_from_x, collapse_to_x, ease(clampf(t / COLLAPSE_SECONDS, 0.0, 1.0), 0.4)) - human.position.x
	var art: Texture2D = COLLAPSE_ART[frame]
	_show_human_frame(art, COLLAPSE_SCALE,
			Vector2(boots + collapse_fall * collapse_centre_from_boots(frame), HUMAN_FLOOR_Y - art.get_height() * 0.5 * COLLAPSE_SCALE),
			collapse_fall < 0.0)
	human.body_sprite.rotation_degrees = 0.0
	var span: Vector2 = collapse_span(frame, collapse_fall, boots)
	human_reflection.floor_y = HUMAN_FLOOR_Y
	human_reflection.shadow_span = span


## How far collapse frame [param frame]'s piece centre stands ahead of the boots along the fall, in
## world px (facing right; mirrored for a fall to the left).
static func collapse_centre_from_boots(frame: int) -> float:
	return (COLLAPSE_ART[frame].get_width() * 0.5 - COLLAPSE_PIVOTS[frame]) * COLLAPSE_SCALE


## How high collapse frame [param frame]'s painted body reaches above the floor line, in world px (its
## piece's rows from COLLAPSE_TOPS down to the soles).
static func collapse_height(frame: int) -> float:
	return (COLLAPSE_ART[frame].get_height() - COLLAPSE_TOPS[frame]) * COLLAPSE_SCALE


## The x span (from, to) of the painted body in collapse frame [param frame], falling [param fall]
## (1 right, -1 left) with the boots at [param boots_x].
static func collapse_span(frame: int, fall: float, boots_x: float) -> Vector2:
	var columns: Vector2 = COLLAPSE_SPANS[frame] * COLLAPSE_SCALE
	return Vector2(boots_x + minf(columns.x * fall, columns.y * fall), boots_x + maxf(columns.x * fall, columns.y * fall))


## The engineer's body sprite back on the standing piece (human_texture) at its rest scale and
## offset. The one place that undoes a posed piece (_show_human_frame), so the crank and the stand-up
## after a collapse restore the same three properties. Leaves rotation and flip_h to the caller: the
## crank keeps the facing it had, and _stand_up restores the facing from before the collapse.
func _show_human_standing() -> void:
	var sprite: Sprite2D = human.body_sprite
	sprite.texture = human_texture
	sprite.scale = human_sprite_scale
	sprite.position = HUMAN_SPRITE_REST


## The engineer's body sprite on one whole posed piece: [param art] drawn at [param frame_scale]
## (world px per art px) at position [param at] (world px, relative to the engineer's origin),
## mirrored when [param flip]. Used by the crank frames (CRANK_ART) and the collapse (COLLAPSE_ART);
## _show_human_standing undoes it. Leaves rotation to the caller.
func _show_human_frame(art: Texture2D, frame_scale: float, at: Vector2, flip: bool) -> void:
	var sprite: Sprite2D = human.body_sprite
	sprite.texture = art
	sprite.scale = Vector2.ONE * frame_scale
	sprite.position = at
	sprite.flip_h = flip


## The engineer back on their feet: the standing image at rest, facing the way they faced before the
## collapse, their reflection and shadow as they stand.
func _stand_up() -> void:
	_show_human_standing()
	var sprite: Sprite2D = human.body_sprite
	sprite.rotation_degrees = 0.0
	if collapsed:
		sprite.flip_h = collapse_flip
	collapsed = false
	if human_reflection != null:
		human_reflection.floor_y = HUMAN_SPRITE_REST.y + human_texture.get_height() * 0.5 * human_sprite_scale.y
		human_reflection.shadow_span = Vector2.ZERO


## The knockdown card takes RETRY: RETRY_READY_SECONDS after the hit, every time (Q17).
func _retry_ready() -> bool:
	return fail_active and not retrying and fail_age >= RETRY_READY_SECONDS


## RETRY on the knockdown card: a fade to black, the last autosave back, a fade in, then control.
func _retry() -> void:
	retrying = true
	if collapsed:
		_show_collapse(COLLAPSE_SECONDS)
	fail_tween = Tweens.restart(self, fail_tween)
	fail_tween.tween_property(intro_fade, "color:a", 1.0, RETRY_FADE_OUT_SECONDS)
	fail_tween.tween_callback(_restore_beat.bind(fail_reason))
	fail_tween.tween_property(intro_fade, "color:a", 0.0, RETRY_FADE_IN_SECONDS)
	fail_tween.tween_callback(_end_retry_fade)


## The room has faded back in after RETRY: the engineer has their controls again.
func _end_retry_fade() -> void:
	retry_fading_in = false
	_update_controls()


func _restore_beat(reason: String) -> void:
	fail_active = false
	retrying = false
	# The controls stay off while the room fades back in (_end_retry_fade).
	retry_fading_in = true
	var restored: bool = false
	var from_disk: bool = false
	# A failed autosave leaves an older file on disk; the snapshot is the beat that failed to write.
	if state.checkpoint_reached and not save_pending and M0State.load_from_disk(save_path) != null:
		_load_game()
		restored = true
		from_disk = true
	elif not beat_snapshot.is_empty():
		var snapshot: M0State = M0State.from_dict(beat_snapshot)
		if snapshot != null:
			state = snapshot
			relay_refused = false
			wolf_heading_to_relay = false
			wolf_scouting = false
			wolf_look_x = -1.0
			wolf_look_remaining = 0.0
			last_top_card_key = ""
			hold_use.reset()
			_sync_scene()
			_start_gameplay_camera()
			restored = true
	if not restored:
		_sync_scene()
	# _load_game clears the fade; the knockdown's fade-in starts from black.
	intro_fade.color.a = 1.0
	# Before the first checkpoint nothing is on disk; the beat snapshot is the start of this beat.
	var restore_line: String = RESTORE_FROM_DISK_LINE if from_disk else RESTORE_BEAT_LINE
	if reason.contains("\n"):
		# A card already on two rows keeps its box; where play resumed follows in the next (2 rows a box).
		_say([reason, restore_line])
	else:
		status_line = "%s\n%s" % [reason, restore_line]
	_refresh_ui()


## Stops the engineer's give against the sealed door (a knockdown or a new scene takes the body over).
func _cancel_door_recoil() -> void:
	Tweens.kill(door_recoil_tween)
	door_recoil_tween = null
	human.body_sprite.position.x = HUMAN_SPRITE_REST.x


func _cancel_fail_tween() -> void:
	Tweens.kill(fail_tween)
	fail_tween = null


## Drops a knockdown in progress (New Game or Return to Title from Pause) without restoring anything.
func _cancel_fail() -> void:
	_cancel_fail_tween()
	_cancel_door_recoil()
	fail_active = false
	retrying = false
	retry_fading_in = false
	_stand_up()
	human.z_index = ACTOR_Z


## The containment gate letting go in the opening: a boom, a kick and dust at its base.
func _shutter_boom() -> void:
	sfx_bank.play(&"boom", -2.0)
	impact.add_trauma(0.6)
	impact.flash(0.09, 0.0)
	impact.rumble(0.5, 0.9, 0.25)
	impact.burst(gate_dust)


## The seal finishing opening: the curtain is up in the hood, the doorway opens and WOLF lets go of the
## contact.
func _door_lands() -> void:
	seal_opening = false
	wolf_holding_relay = false
	door_shape.set_deferred("disabled", true)
	_update_controls()
	sfx_bank.play(&"thud", -2.0, 1.1)
	impact.add_trauma(0.5)
	impact.rumble(0.4, 0.6, 0.2)
	impact.burst(door_dust)


func _sync_scene() -> void:
	# Walked out through the hatch, the actors faded; any new scene shows them again.
	hatch_exit_walking = false
	hatch_exit_engineer_walking = false
	_reset_records_walk_out()
	human.modulate.a = 1.0
	wolf.modulate.a = 1.0
	# The corridor's relay staging and bypass crank belong to the moment, not the save, and so does
	# WOLF's read of the junction's gauge on entry (_enter_junction starts it after this sync).
	wolf_scouting = false
	seam_read_seconds = 0.0
	wolf_holding_relay = false
	engineer_step_x = -1.0
	_stop_bypass_vent()
	bypass_ticks = 0
	bypass_was_holding = false
	bypass_handle.ticks = 0
	bypass_handle.done = state.route == "fallback"
	bypass_handle.clear_fault(state.door_open, false)
	# The crank pose belongs to the moment too: back to the usual sprite before it is placed below.
	crank_push_left = 0.0
	crank_frame = 0
	_update_crank_pose(0.0)
	# The lane's choices and WOLF's part in it belong to the attempt, not the save.
	lane_choice = ""
	wolf_baiting = false
	wolf_broke_off = false
	wolf_holding_far_end = false
	engineer_waits_for_wolf = false
	lane_question_held = false
	sentry_wake_remaining = 0.0
	Tweens.kill(wolf_reaction_tween)
	Tweens.kill(relay_spark_tween)
	wolf.body_sprite.position = WOLF_SPRITE_REST
	wolf.body_sprite.rotation_degrees = 0.0
	wolf.body_sprite.offset = Vector2.ZERO
	wolf.body_sprite.scale = wolf_sprite_scale
	wolf.speed_scale = 1.0
	_stand_up()
	human.z_index = ACTOR_Z
	relay_spark.hide()
	impact.reset()
	human.position = state.human_position
	# A sidestep worked out in the room left behind never carries over into the new placing.
	human.settle_x = -1.0
	_clear_station_body()
	wolf.position = state.wolf_position
	if state.chapter_id == "records":
		# Records' doors stand across the walkway: a save from before they did (when the room's ends
		# were open floor) never places anyone inside the shut entry or past the exit before it opens.
		var exit_open: bool = state.chapter_complete
		human.position.x = clampf(human.position.x, RecordsRoom.ENTRY_DOOR_X + M0State.HUMAN_HALF_WIDTH, M0Actor.MAX_X if exit_open else RecordsRoom.EXIT_DOOR_X - M0State.HUMAN_HALF_WIDTH)
		wolf.position.x = clampf(wolf.position.x, RecordsRoom.ENTRY_DOOR_X + M0State.WOLF_HALF_WIDTH, M0Actor.MAX_X if exit_open else RecordsRoom.EXIT_DOOR_X - M0State.WOLF_HALF_WIDTH)
	if state.chapter_id == "junction":
		# The junction's entry stands across the walkway at its left end: nobody is restored inside it.
		human.position.x = maxf(human.position.x, JunctionRoom.ENTRY_DOOR_X + M0State.HUMAN_HALF_WIDTH)
		wolf.position.x = maxf(wolf.position.x, JunctionRoom.ENTRY_DOOR_X + M0State.WOLF_HALF_WIDTH)
	if state.chapter_id == "junction" and state.sentry_down:
		# With the sentry down he waits at his spot by the hatch, facing back down the lane; a save taken
		# as the tank landed (autosave C) has him wherever he was then, and he never walks back across
		# the tank to it.
		wolf.position.x = JunctionRoom.WOLF_DOWN_X
		wolf.body_sprite.flip_h = true
	# Placed afresh, he picks his side afresh from the engineer's facing.
	wolf.follow_side = 0
	human.velocity = Vector2.ZERO
	wolf.velocity = Vector2.ZERO
	_update_controls()
	_sync_door()
	_sync_records_room()
	_sync_junction_room()
	_sync_room_lights()


## The junction shows only in its chapter; its line, bursts and hazards go back to rest and its
## door matches the save, so a reload or a knockdown never carries a half-finished beat over.
func _sync_junction_room() -> void:
	var in_junction: bool = state.chapter_id == "junction"
	junction_room.visible = in_junction
	junction_room.door_blown = state.door_blown
	junction_room.sentry_down = state.sentry_down
	junction_room.junction_cleared = state.junction_cleared
	junction_room.set_active(in_junction)
	# A blown door leaves the line spent, so a reload can never re-arm the breaker or light a fuse.
	pressure_line.reset(state.door_blown)
	# The sentry patrols from the far end once the door is down, or lies under the tank on the mark.
	sentry_brain.reset(state.door_blown, state.sentry_down, DropArm.MARK_X)
	drop_arm.reset(state.sentry_down)
	bolt_state = &"open" if state.junction_cleared else &"locked"
	bolt_charge_remaining = 0.0
	junction_room.reset_transient()
	junction_room.sync_line(pressure_line)
	junction_room.sentry.place(sentry_brain)
	junction_room.sentry.follow(sentry_brain)
	junction_room.sync_arm(drop_arm)
	junction_room.sync_bolt(bolt_state, 1.0 if bolt_state == &"open" else 0.0)
	_stop_junction_loops()


func _react_as_wolf(accepting: bool) -> void:
	Tweens.kill(wolf_reaction_tween)
	wolf.body_sprite.position = WOLF_SPRITE_REST
	wolf.body_sprite.rotation_degrees = 0.0
	var lean: Vector2 = Vector2(11.0, -24.0) if accepting else Vector2(-13.0, -13.0)
	var tilt: float = 8.0 if accepting else -9.0
	# His joints whir as he leans in or pulls back, so every answer he gives with his body is heard.
	sfx_bank.play(&"actuator", -9.0, 1.08 if accepting else 0.9)
	wolf_reaction_tween = create_tween()
	wolf_reaction_tween.tween_property(wolf.body_sprite, "position", lean, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	wolf_reaction_tween.parallel().tween_property(wolf.body_sprite, "rotation_degrees", tilt, 0.18)
	wolf_reaction_tween.tween_interval(0.18)
	wolf_reaction_tween.tween_property(wolf.body_sprite, "position", WOLF_SPRITE_REST, 0.24)
	wolf_reaction_tween.parallel().tween_property(wolf.body_sprite, "rotation_degrees", 0.0, 0.24)


## The arc and spark burst as the seal's power goes through: on the relay's contact when WOLF takes it
## ([param from_wolf]), on the MANUAL BYPASS wheel when the engineer's crank locks over.
func _flash_relay_spark(from_wolf: bool) -> void:
	Tweens.kill(relay_spark_tween)
	if from_wolf:
		# From WOLF's snout at the relay's left edge across its face.
		relay_spark.points = PackedVector2Array([
			Vector2(569.0, 393.0), Vector2(578.0, 381.0), Vector2(586.0, 398.0),
			Vector2(596.0, 380.0), Vector2(606.0, 393.0),
		])
		relay_sparks.position = Vector2(587.0, 390.0)
	else:
		# The bypass locking over: across the top of its wheel, in front of the engineer cranking it.
		var hub: Vector2 = BYPASS_WHEEL + BypassHandle.WHEEL_OFFSET
		relay_spark.points = PackedVector2Array([
			hub + Vector2(-12.0, -13.0), hub + Vector2(-5.0, -21.0), hub + Vector2(2.0, -12.0),
			hub + Vector2(9.0, -20.0), hub + Vector2(16.0, -10.0),
		])
		relay_sparks.position = hub + Vector2(4.0, -14.0)
	relay_spark.default_color = Palette.CYAN if from_wolf else Palette.AMBER
	relay_spark.modulate.a = 1.0
	relay_spark.show()
	relay_spark_tween = create_tween()
	relay_spark_tween.tween_property(relay_spark, "modulate:a", 0.0, 0.48)
	relay_spark_tween.tween_callback(relay_spark.hide)
	# The contact itself: a clank with a short spark, a kick and a spark shower in the route's colour.
	sfx_bank.play(&"clank", 0.0, 1.0 if from_wolf else 0.92)
	sfx_bank.play(&"relay_spark", -5.0)
	impact.add_trauma(0.35)
	impact.rumble(0.3, 0.5, 0.15)
	relay_sparks.color = relay_spark.default_color
	impact.burst(relay_sparks)


func _sync_records_room(animate_exit: bool = false) -> void:
	records_room.visible = state.chapter_id == "records"
	records_room.set_active(records_room.visible)
	var in_corridor: bool = state.chapter_id == "lockdown"
	breaker_status_light.visible = in_corridor
	relay_status_light.visible = in_corridor
	# Every room's backdrop sits at the same depth as the corridor's, so corridor-only dressing hides with it.
	for corridor_only: CanvasItem in [corridor_depth, purge_terminal_art, breaker_art, relay_art, checkpoint_art, $BreakerLabel, $RelayLabel, $CheckpointLabel, bypass_handle]:
		corridor_only.visible = in_corridor
	records_room.purge_trace_preserved = state.purge_trace_preserved
	records_room.mirror_trace_preserved = state.mirror_trace_preserved
	records_room.chapter_complete = state.chapter_complete
	if animate_exit and state.chapter_complete:
		# The secured copy releases the exit: its leaf swings open on its hinges, never vanishing.
		records_room.open_exit(true)
	records_room.refresh_state()


## The corridor seal: a rolling steel door in the cross-wall, shut, or standing open on the plant room
## beyond with the curtain parked in its hood. Opening in play winds the curtain up (SealLeaf) while
## the inner blast leaf slides into its pocket, and the doorway stays shut until it is up, with its
## thud and dust. Its front pillar shows either way.
func _sync_door(animate: bool = false) -> void:
	Tweens.kill(door_tween)
	var in_corridor: bool = state.chapter_id == "lockdown"
	var sliding: bool = in_corridor and state.door_open and animate
	seal_opening = sliding
	# The seal's body blocks only in the corridor: the other rooms share its coordinates.
	door_shape.set_deferred("disabled", not in_corridor or (state.door_open and not sliding))
	door_visual.scale = Vector2.ONE
	door_visual.modulate = Color.WHITE
	door_visual.visible = in_corridor and not state.door_open
	door_lip.visible = in_corridor
	seal_lamp.visible = in_corridor
	_set_seal_lamp(Palette.AMBER if sliding else (Palette.LAMP_OPEN if state.door_open else Palette.LAMP_SHUT))
	seal_lamp.halo.visible = state.door_open
	seal_leaf.open = 1.0 if state.door_open and not sliding else 0.0
	blast_leaf.open = 0.0
	blast_leaf.visible = sliding
	if sliding:
		door_tween = create_tween()
		door_tween.tween_method(_set_seal_open, 0.0, 1.0, CORRIDOR_DOOR_OPEN_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		door_tween.tween_callback(blast_leaf.hide)
		door_tween.tween_callback(_set_seal_lamp.bind(Palette.LAMP_OPEN))
		door_tween.tween_callback(_door_lands)


## The seal's one open value drives the roller curtain and the inner blast leaf behind it.
func _set_seal_open(value: float) -> void:
	seal_leaf.open = value
	blast_leaf.open = value


## The seal's status lamp: red while shut, amber while the curtain moves, green open; only the lens
## is live, and only the open lamp throws a glow (_sync_door).
func _set_seal_lamp(color: Color) -> void:
	seal_lamp.color = color


func _update_controls() -> void:
	human.controlled = not title_open and not intro_active and not chapter_close_active and not end_card_active and not waiting_for_choice and not fail_active and not retry_fading_in and engineer_step_x < 0.0 and not engineer_waits_for_wolf and not lane_question_held and not records_exit_walking
	# Stepping back from the relay, the engineer walks on their own for a moment; leaving the junction
	# they wait for WOLF to go through the hatch first.
	if hatch_exit_walking:
		human.autonomous_target_x = HATCH_EXIT_X if hatch_exit_engineer_walking else -1.0
	else:
		human.autonomous_target_x = engineer_step_x
	# Through the junction's open exit door both may walk on past the room's edge; the player walks
	# the engineer no further than WOLF waiting in its doorway allows.
	var exit_open: bool = _exit_door_open()
	human.max_x = JunctionRoom.EXIT_WALK_MAX_X if exit_open else (RECORDS_WALK_MAX_X if records_exit_walking else M0Actor.MAX_X)
	wolf.max_x = human.max_x
	human.walk_max_x = JunctionRoom.HATCH_REACH_MAX_X if exit_open and not hatch_exit_walking else M0Actor.MAX_X
	human.speed_scale = HATCH_EXIT_SPEED_SCALE if hatch_exit_walking else 1.0
	if hatch_exit_walking:
		# Fix round 2 (review r2, the human pass: "I never see WOLF take a step through"): WOLF walks out at
		# the same walk as the engineer. The junction's tick, which sets his speed otherwise
		# (_sync_wolf_leap), does not run during the chapter close, so he kept his full follow speed and
		# was through the doorway in about 0.15 s.
		wolf.speed_scale = HATCH_EXIT_SPEED_SCALE
	wolf.controlled = false
	wolf.autonomous_target_x = _wolf_target_x()
	wolf.follow_target = human if human.controlled and wolf.autonomous_target_x < 0.0 else null
	wolf.follow_max_x = _wolf_follow_max_x()
	wolf.follow_min_x = _wolf_follow_min_x()
	wolf.avoid_spans = _machine_spans()
	human.queue_redraw()
	wolf.queue_redraw()


## Where WOLF goes on his own, or -1 to follow: the relay contact (held until the seal lands), off
## the relay while the engineer works the bypass (_wolf_off_relay), the Records mirror, the junction
## valve on entry, clear of the vent and the blast while the line is live, back by the valve, short
## of the rubble line, once the door is down (he will not cross it unless he chooses to draw the
## sentry onto the mark, from the far end of its lane), by the exit hatch once it is down, and out
## through the hatch at the end.
func _wolf_target_x() -> float:
	if hatch_exit_walking:
		# He goes through the exit door first, on from his spot in its doorway.
		return WOLF_HATCH_EXIT_X
	if end_card_active:
		# Gone through the exit door: he stays where he is, out of sight, under the card.
		return -1.0
	if records_exit_walking:
		# Leaving Records he follows the engineer out through the exit, past its near column.
		return RECORDS_WOLF_OUT_X
	if wolf_heading_to_relay or wolf_holding_relay:
		return RELAY_CONTACT_X
	if _wolf_comes_to_doorway():
		return WOLF_DOORWAY_X
	if _wolf_off_relay():
		return WOLF_BYPASS_CLEAR_X
	match state.chapter_id:
		"records":
			# After his readout he holds his spot at the port, facing it, while the engineer is still at
			# its station (RECORDS_STATIONS' mirror row: centre x and use reach): following at once
			# walked him back across the port and the engineer, his tail over the rack's base, while
			# the readout line was still up.
			var mirror: Vector4 = RECORDS_STATIONS[1]
			if not state.mirror_trace_preserved or (state.mirror_route == "wolf" and absf(human.position.x - mirror.x) <= mirror.z):
				return WOLF_MIRROR_X
			return -1.0
		"junction":
			if wolf_scouting:
				return JunctionRoom.WOLF_SEAM_X
			if wolf_look_x >= 0.0:
				# Hint ladder T1: he holds where he is, looking at the breaker.
				return wolf_look_x
			if not state.door_blown and pressure_line.state in [&"building", &"charged", &"fuse"]:
				# While the line builds he keeps off the vent's grate, and while the fuse burns he is out of
				# the blast zone.
				return JunctionRoom.WOLF_CLEAR_X
			if state.sentry_down:
				# Once it is down he waits by the hatch he says is next, in full view, clear of the tank. From
				# the rubble side he bounds over the crushed tank (_sync_wolf_leap), once the empty arm has
				# winched up out of his way; until then he holds where he is.
				if wolf.position.x < DropArm.MARK_X and junction_room.arm_parked < 1.0:
					return wolf.position.x
				# Once the exit door is open he steps into its doorway and waits there for the engineer.
				if _exit_door_open():
					return JunctionRoom.WOLF_DOORWAY_X
				return JunctionRoom.WOLF_DOWN_X
			if state.door_blown:
				# He draws the sentry only by his own choice, from the far end of its lane; otherwise he will
				# not cross the rubble. Once past it he never crosses back under the tank: while it is locked
				# on to the engineer or chasing them, or after he breaks off there, he keeps to his spot by
				# the hatch. Should it turn on the engineer before he is past it, he backs off to his spot by
				# the valve rather than bound over it.
				if wolf_holding_far_end:
					return JunctionRoom.WOLF_BAIT_X
				if wolf_baiting and (not _sentry_hunting() or wolf.position.x > sentry_brain.x):
					return JunctionRoom.WOLF_BAIT_X
				return _wolf_rubble_x()
	return -1.0


## Where WOLF holds back from the rubble: his spot by the valve (JunctionRoom.WOLF_RUBBLE_X), the only
## floor on the near side as long as he is. The engineer backing off from the fuse often stops right
## there, so while they stand where his body would be he keeps to his spot by the entrance
## (JunctionRoom.WOLF_CLEAR_X), and walks up once they move on towards the rubble.
## Once he has set off for his spot the engineer has to come back well inside it to send him back, and
## once he is holding by the entrance they have to be well clear of it before he sets off
## (WOLF_RUBBLE_HYSTERESIS), so an engineer edging about near the valve never sets him running to and fro.
func _wolf_rubble_x() -> float:
	if wolf.position.x >= JunctionRoom.WOLF_RUBBLE_X - 2.0:
		return JunctionRoom.WOLF_RUBBLE_X
	var gap: float = absf(human.position.x - JunctionRoom.WOLF_RUBBLE_X)
	if wolf.autonomous_target_x == JunctionRoom.WOLF_RUBBLE_X:
		return JunctionRoom.WOLF_CLEAR_X if gap < M0Actor.CLEAR_GAP - WOLF_RUBBLE_HYSTERESIS else JunctionRoom.WOLF_RUBBLE_X
	return JunctionRoom.WOLF_CLEAR_X if gap < M0Actor.CLEAR_GAP + WOLF_RUBBLE_HYSTERESIS else JunctionRoom.WOLF_RUBBLE_X


## The seal is open and the engineer has gone through it to the safe point: WOLF comes to the open
## doorway and stands there, facing them (WOLF_DOORWAY_X). He sets off only once they are at the safe
## point (WOLF_DOORWAY_HYSTERESIS past the hold line), and once he has set off he keeps to the doorway
## until they come back within a clear gap of it (WOLF_DOORWAY_HOLD_X).
func _wolf_comes_to_doorway() -> bool:
	if state.chapter_id != "lockdown" or not state.door_open or seal_opening:
		return false
	var hold_x: float = WOLF_DOORWAY_HOLD_X if wolf.autonomous_target_x == WOLF_DOORWAY_X else WOLF_DOORWAY_HOLD_X + WOLF_DOORWAY_HYSTERESIS
	return human.position.x >= hold_x


## WOLF keeps off the live relay, back towards the breaker: once he has refused it, or while the
## engineer works the bypass instead, until the seal they opened has landed. So the bypass route
## never shows him on the contact he did not take. On the honest route he also waits there, ready,
## while the engineer stands at the relay or the bypass, rather than following onto the machine.
func _wolf_off_relay() -> bool:
	if state.chapter_id != "lockdown" or not state.breaker_armed:
		return false
	if state.door_open:
		return seal_opening and state.route == "fallback"
	return _relay_refused() or bypass_venting or bypass_ticks > 0 or _at_relay(human.position.x) or _at_bypass(human.position.x)


## The current room's machines as x spans (from, to), drawn width and all, for WOLF to rest clear of
## while he follows (M0Actor.off_machines). Doors and hatches are not in it: standing in a doorway is
## fine. The landed tank joins them once the sentry is down.
func _machine_spans() -> Array[Vector2]:
	var halves: Array[Vector2] = []
	match state.chapter_id:
		"lockdown":
			halves = [Vector2(350.0, 38.5), Vector2(RELAY_X, RELAY_HALF_WIDTH), Vector2(BYPASS_WHEEL.x, BypassHandle.COLLAR_RADIUS), Vector2(876.0, 35.0)]
		"records":
			halves = [Vector2(190.0, 57.1), Vector2(520.0, 44.6), Vector2((RecordsRoom.CONTAINER_SPAN.x + RecordsRoom.CONTAINER_SPAN.y) * 0.5, (RecordsRoom.CONTAINER_SPAN.y - RecordsRoom.CONTAINER_SPAN.x) * 0.5)]
		"junction":
			halves = [Vector2(JunctionRoom.BREAKER_X, JunctionRoom.BREAKER_HALF_WIDTH), Vector2(JunctionRoom.VALVE_X, JunctionRoom.VALVE_HALF_WIDTH), Vector2(JunctionRoom.ARM_X, JunctionRoom.ARM_PANEL_HALF_WIDTH), Vector2(JunctionRoom.BOLT_PANEL_X, JunctionRoom.BOLT_PANEL_HALF_WIDTH)]
			if state.sentry_down:
				halves.append(Vector2(DropArm.MARK_X, JunctionRoom.TANK_SIZE.x * 0.5))
	var spans: Array[Vector2] = []
	for half: Vector2 in halves:
		spans.append(Vector2(half.x - half.y, half.x + half.y))
	return spans


## The furthest right WOLF follows to: short of a shut door by his drawn reach, so he never noses
## into it and the engineer always has room in front of it. Once the corridor's seal is open, the
## floor past the relay (the MANUAL BYPASS, the seal's frame and the safe point) has no gap as long
## as he is, so he follows no further than the relay's left side (WOLF_FOLLOW_OPEN_MAX_X) while the
## engineer walks through. Once the engineer is at the safe point, WOLF comes to the open doorway
## instead (_wolf_comes_to_doorway, WOLF_DOORWAY_X). His authored spots ignore this limit.
func _wolf_follow_max_x() -> float:
	if state.chapter_id == "lockdown":
		return WOLF_FOLLOW_OPEN_MAX_X if state.door_open else CORRIDOR_DOOR_LEFT_X - M0Actor.WOLF_REACH
	if state.chapter_id == "junction" and not state.door_blown:
		return M0State.JUNCTION_DOOR_LEFT_X - M0Actor.WOLF_REACH
	if state.chapter_id == "records":
		# Shut, the exit stops him; open, he still waits in the room for the engineer to go first
		# rather than standing in its doorway (RECORDS_WOLF_OUT_X when they leave).
		return RecordsRoom.EXIT_DOOR_X - M0Actor.WOLF_REACH
	return M0Actor.MAX_X


## The furthest left WOLF follows to: in Records and the junction, clear of the shut entry by his drawn
## reach.
func _wolf_follow_min_x() -> float:
	if state.chapter_id == "records":
		return RecordsRoom.ENTRY_DOOR_X + M0Actor.WOLF_REACH
	if state.chapter_id == "junction":
		return JunctionRoom.ENTRY_DOOR_X + M0Actor.WOLF_REACH
	return M0Actor.MIN_X


func _refresh_ui() -> void:
	var touch_layout: bool = touch_enabled and not controller_active
	impact.rumble_enabled = controller_active
	impact.haptics_enabled = touch_layout
	# The END OF SLICE card stands alone: no play HUD, touch controls or Pause over it.
	if end_card_active:
		for hud_part: CanvasItem in [pause_button, touch_controls, tutorial_prompt, top_card, context_hint, bottom_bar]:
			hud_part.hide()
		end_card_button.text = "TAP CONTINUE" if touch_layout else "%s  CONTINUE" % settings_menu.prompt(&"interact", controller_active)
		return
	pause_button.visible = not title_open and not pause_overlay.visible
	pause_button.text = "PAUSE"
	touch_controls.visible = (touch_layout or waiting_for_choice) and not title_open and not pause_overlay.visible
	var touch_move: bool = not intro_active and not chapter_close_active and not waiting_for_choice and not fail_active
	touch_left.visible = touch_layout and touch_move
	touch_right.visible = touch_layout and touch_move
	touch_use.visible = touch_layout and not waiting_for_choice and not hatch_exit_walking
	touch_use.text = RETRY_BUTTON_TEXT if fail_active else ("CONTINUE" if intro_active or chapter_close_active else ("CRANK" if not _hold_station().is_empty() else ("DROP" if _drop_ready() else "USE")))
	touch_choice_1.visible = waiting_for_choice
	touch_choice_2.visible = waiting_for_choice
	tutorial_prompt.visible = not title_open and not intro_active and not fail_active and state.chapter_id == "lockdown" and tutorial_step < 2
	if tutorial_prompt.visible:
		var interact_key: String = settings_menu.prompt(&"interact", controller_active)
		var move_keys: String = "%s / %s" % [settings_menu.prompt(&"move_left", false), settings_menu.prompt(&"move_right", false)]
		# Touch prompts name the on-screen buttons, in the same "button  action" form as the keys.
		var move_label: String = "◀ / ▶  MOVE" if touch_layout else ("STICK / D-PAD MOVE" if controller_active else "%s  MOVE" % move_keys)
		var read_label: String = "%s  READ DISPLAY (optional)" % ("USE" if touch_layout else interact_key)
		# The display is optional, so once the engineer heads right the tutorial only points forward.
		if human.position.x > 230.0:
			tutorial_text.text = "%s\nHead right to the breaker." % move_label
		elif tutorial_step == 0:
			# The first controllable frame (TEACH-7): the name card and this one prompt.
			tutorial_text.text = move_label
		else:
			tutorial_text.text = "%s\nOr head right to the breaker." % read_label
	if title_open:
		top_card.hide()
		_layout_hud()
		return
	if intro_active:
		if last_top_card_key != "intro":
			last_top_card_key = "intro"
			_show_top_card("03:17 / CONTAINMENT\nWOLF OVERRIDE", 2.6)
		var intro_hint: String = "TAP CONTINUE  /  PAUSE" if touch_layout else "%s  CONTINUE    %s  PAUSE" % [settings_menu.prompt(&"interact", controller_active), settings_menu.prompt(&"pause_game", controller_active)]
		if intro_step == 0 and dialogue_index == 0:
			# The opening's first box says how to skip it (Pause offers SKIP OPENING).
			intro_hint = "%s\n%s" % ["TAP CONTINUE" if touch_layout else "%s  CONTINUE" % settings_menu.prompt(&"interact", controller_active), SKIP_OPENING_HINT]
		_set_dialogue(intro_hint)
		return
	if chapter_close_active:
		if last_top_card_key != "chapter_close":
			last_top_card_key = "chapter_close"
			_show_top_card("SERVICE JUNCTION\nSERVICE LINE CLEARED", 3.4)
		# Walking out through the hatch nothing waits on a press, so no CONTINUE prompt shows.
		_set_dialogue("" if hatch_exit_walking else ("TAP CONTINUE" if touch_layout else "%s  CONTINUE" % settings_menu.prompt(&"interact", controller_active)))
		return
	# The corridor stations' tints and lamps are written only when they change: this runs every frame.
	_set_modulate(breaker_art, Color.WHITE if state.breaker_armed else UNPOWERED_TINT)
	_set_color(breaker_status_light, Palette.CYAN if state.breaker_armed else Palette.BREAKER_IDLE)
	_set_modulate(relay_art, Color.WHITE if state.breaker_armed else UNPOWERED_TINT)
	_set_color(relay_status_light, Palette.GREEN if state.door_open else (Palette.AMBER if state.breaker_armed and _relay_refused() else (Palette.CYAN if state.breaker_armed else Color("#536e7c"))))
	var bypass_live: bool = state.breaker_armed and not state.door_open
	if bypass_handle.live != bypass_live:
		bypass_handle.live = bypass_live
	# Once the seal's power has gone through, by WOLF or by the bypass, the relay is no longer faulted.
	bypass_handle.clear_fault(state.door_open, true)
	_set_modulate(breaker_status_glow, Color(breaker_status_light.color, 0.75 if state.breaker_armed else 0.45))
	_set_modulate(relay_status_glow, Color(relay_status_light.color, 0.75 if state.breaker_armed else 0.3))
	_set_modulate(checkpoint_art, Color("#d5ffe3") if state.checkpoint_reached else Color.WHITE)
	var card_key: String = "%s:%s" % [state.chapter_id, _objective()]
	if name_card_remaining > 0.0 and state.chapter_id == "lockdown":
		# The name card comes first; the location card follows once it has faded or been skipped.
		var name_card: String = "%s\nMAINTENANCE ENGINEER" % state.human_name().to_upper()
		if last_top_card_key != "name_card":
			last_top_card_key = "name_card"
			_show_top_card(name_card, NAME_CARD_SECONDS, ENGINEER_TINT)
		elif hud.text != name_card:
			# Cycling the provisional name while it is up updates it in place.
			hud.text = name_card
	elif last_top_card_key != card_key and not _opening_lines_playing():
		# One thing to read at a time (TEACH-7): the location card waits while the opening lines play.
		last_top_card_key = card_key
		var location: String = "SERVICE JUNCTION" if state.chapter_id == "junction" else ("RECORDS ACCESS / FIRST COPY" if state.chapter_id == "records" else "MAINTENANCE / LOCKDOWN")
		_show_top_card("%s\n%s" % [location, _objective()], 3.4)
	var context: String = _context_hint()
	if context != save_error_context:
		save_error = ""
	var hint: String = save_error if not save_error.is_empty() else (CHECKPOINT_TOAST if checkpoint_toast_remaining > 0.0 and not fail_active else context)
	if hold_toggle:
		# With TOGGLE HOLDS on, one press works a crank: its prompt drops HOLD.
		hint = hint.replace("HOLD E:", "E:")
	if touch_layout:
		# On touch the prompt names the button on screen: USE, or CRANK and DROP when it says so (PHONE-3).
		hint = hint.replace("E:", "%s:" % touch_use.text)
	elif controller_active:
		hint = hint.replace("E:", "%s:" % settings_menu.prompt(&"interact", true))
	else:
		hint = hint.replace("E:", "%s:" % settings_menu.prompt(&"interact", false))
	if _retry_ready():
		# The knockdown card's one prompt once it takes RETRY (Q17); before that only a save error shows.
		hint = RETRY_TOUCH_PROMPT if touch_layout else RETRY_PROMPT % settings_menu.prompt(&"interact", controller_active)
	# The tutorial prompt is the one prompt while it shows; the hint bar would only repeat it.
	_set_dialogue("" if waiting_for_choice or tutorial_prompt.visible else hint)


## Shows the box on screen with its speaker's name and colour, and [param hint] in the hint bar.
func _set_dialogue(hint: String) -> void:
	_sync_dialogue_boxes()
	var box: String = _shown_box()
	var tags: Array[String] = _speaker_tags()
	var name: String = DialogueBoxes.tag_of(box, tags)
	speaker.text = name
	story.text = DialogueBoxes.words_of(box, tags)
	var has_speaker: bool = not name.is_empty()
	speaker.visible = has_speaker
	var human_name: String = _first_name().to_upper()
	var tint: Color = Palette.CYAN if name == "WOLF" else (Color("#ff9a9f") if name.begins_with("DIRECTOR") else (ENGINEER_TINT if name == human_name else Color("#9fc3d2")))
	_set_color(dialogue_accent, tint)
	_set_font_color(speaker, tint)
	bottom_bar.visible = not box.is_empty()
	context_hint.visible = not hint.is_empty()
	context_hint_text.text = hint
	_layout_hud()


## The speaker tags a box can open with: WOLF, the Director (and his purge display) and the engineer.
func _speaker_tags() -> Array[String]:
	return ["WOLF", "DIRECTOR", "DIRECTOR / PURGE", _first_name().to_upper()]


## status_line as the player reads it: its key prompts name the input in use.
func _shown_line() -> String:
	var touch_layout: bool = touch_enabled and not controller_active
	var line: String = status_line.replace("Press E", "Tap USE" if touch_layout else "Press %s" % settings_menu.prompt(&"interact", controller_active))
	# Touch answers carry no number (PHONE-3), so the hint names the button instead.
	return line.replace("press 2 for the manual port", "tap USE MANUAL PORT") if touch_layout else line.replace("press 2", "press %s" % settings_menu.prompt(&"choice_2", controller_active))


## Splits status_line into its boxes again when it, the engineer's name, the input in use or the
## text size has changed. A new line starts at its first box; the same line at another size keeps
## its place.
func _sync_dialogue_boxes() -> void:
	var line: String = _shown_line()
	var key: String = "%s|%s|%s" % [line, _first_name(), _dialogue_column_width()]
	if key == dialogue_key:
		return
	dialogue_key = key
	_layout_hud()
	dialogue_boxes = DialogueBoxes.split(line, _speaker_tags(), _dialogue_fits)
	if dialogue_restart:
		dialogue_restart = false
		dialogue_index = 0
		dialogue_age = 0.0
		dialogue_cleared = false
		# A story line an aside cut into comes back at the box it was on (_aside).
		if status_line == box_resume_line:
			dialogue_index = box_resume_index
			box_resume_line = ""
	dialogue_index = clampi(dialogue_index, 0, maxi(dialogue_boxes.size() - 1, 0))


## Whether [param words] fit the dialogue column in DialogueBoxes.MAX_ROWS rows at the current size.
func _dialogue_fits(words: String) -> bool:
	var font: Font = story.get_theme_font(&"font")
	var size: int = story.get_theme_font_size(&"font_size")
	var width: float = DialogueBoxes.wrap_width(words, font, size, _dialogue_column_width(), DialogueBoxes.MAX_ROW_CHARACTERS)
	return DialogueBoxes.rows(words, font, size, width).size() <= DialogueBoxes.MAX_ROWS


## Runs the box on screen: each stays up for its reading time and gives way to the next; the last one
## clears once it has been read and the engineer moves on (STORY-8). The opening and the closing
## shots also go on at a press (_next_box); a question stays up until it is answered.
func _tick_dialogue(delta: float) -> void:
	_sync_dialogue_boxes()
	if opening_lines_held or dialogue_boxes.is_empty():
		return
	dialogue_age += delta
	if dialogue_index < dialogue_boxes.size() - 1:
		if dialogue_age >= _box_seconds():
			_next_box()
	elif not dialogue_cleared and dialogue_age >= _box_seconds() and _moving_on():
		dialogue_cleared = true


## Shows the next box of the line on screen, if it has one.
func _next_box() -> bool:
	_sync_dialogue_boxes()
	if opening_lines_held or dialogue_index >= dialogue_boxes.size() - 1:
		return false
	dialogue_index += 1
	dialogue_age = 0.0
	return true


## The reading time of the box on screen.
func _box_seconds() -> float:
	return _box_seconds_of(dialogue_index)


## The reading time of box [param index] of the line on screen.
func _box_seconds_of(index: int) -> float:
	if index < 0 or index >= dialogue_boxes.size():
		return 0.0
	return DialogueBoxes.read_seconds(DialogueBoxes.words_of(dialogue_boxes[index], _speaker_tags()))


## Every box of the line has been up for its reading time (or has cleared).
func _dialogue_read() -> bool:
	_sync_dialogue_boxes()
	return not opening_lines_held and (dialogue_cleared or dialogue_boxes.is_empty() or (dialogue_index == dialogue_boxes.size() - 1 and dialogue_age >= _box_seconds()))


## The engineer is walking on their own, with control, and nothing waits on an answer.
func _moving_on() -> bool:
	return human.controlled and not waiting_for_choice and (Input.is_action_pressed(&"move_left") or Input.is_action_pressed(&"move_right"))


## The box on screen, or "" while there is none (held, cleared or nothing said).
func _shown_box() -> String:
	if opening_lines_held or dialogue_cleared or dialogue_boxes.is_empty():
		return ""
	return dialogue_boxes[dialogue_index]


## The opening lines are due (the first step has been taken) or showing, and not all read yet. A
## player who stands still past the name card gets the location card first.
func _opening_lines_playing() -> bool:
	return (not opening_lines_held or tutorial_step >= 1) and status_line in opening_lines and state.chapter_id == "lockdown" and (not box_queue.is_empty() or not _dialogue_read())


## Records' closing lines are up and have a box still to show, or wait behind an aside that cut into
## them (_aside).
func _records_close_unread() -> bool:
	var close: String = _records_close_line()
	if _queued_next(close):
		return true
	return status_line == close and not dialogue_cleared and dialogue_index < dialogue_boxes.size() - 1


## The first step takes the name card off at once (it fades as usual).
func _dismiss_name_card() -> void:
	if name_card_remaining <= TOP_CARD_FADE_SECONDS or last_top_card_key != "name_card":
		return
	name_card_remaining = TOP_CARD_FADE_SECONDS
	top_card_tween = Tweens.restart(self, top_card_tween)
	top_card_tween.tween_property(top_card, "modulate:a", 0.0, TOP_CARD_FADE_SECONDS)
	top_card_tween.tween_callback(top_card.hide)


## TEXT SIZE changed (or the game started): the station names take the new size and every box is
## laid out and split again.
func _apply_text_size() -> void:
	bypass_handle.refit_labels()
	for label: Label in [$BreakerLabel, $RelayLabel, $CheckpointLabel] as Array[Label]:
		if not label.has_meta(&"text_home"):
			label.set_meta(&"text_home", Rect2(label.position, label.size))
			label.set_meta(&"text_base_size", label.get_theme_font_size(&"font_size"))
		var home: Rect2 = label.get_meta(&"text_home")
		# The relay's name stands over its COOLANT FAULT tag, so it rises as far as the tag grows.
		var lift: float = bypass_handle.fault_tag_growth() if label == $RelayLabel else 0.0
		TextSize.fit_world_label(label, home.get_center().x, home.position.y - lift)
	records_room.refit_labels()
	junction_room.refit_labels()
	dialogue_key = ""
	_layout_hud()
	if is_inside_tree():
		_refresh_ui()


## The words' column width at the current text size: 42 characters' worth, or what the canvas leaves.
func _dialogue_column_width() -> float:
	var wanted: float = DIALOGUE_COLUMN_WIDTH * TextSize.factor
	return minf(wanted, _dialogue_room(_box_between_touch_buttons()) - DIALOGUE_PADDING.x * 2.0)


## The width (canvas px) the dialogue box may take, padding included: the touch hint span while it
## stands between the touch buttons ([param between], from _box_between_touch_buttons), otherwise the
## canvas less HUD_SIDE_MARGIN each side. The column width and the box layout both read it.
func _dialogue_room(between: bool) -> float:
	return TOUCH_HINT_WIDTH if between else 960.0 - HUD_SIDE_MARGIN * 2.0


## Above 100% a box under the touch buttons would rise into ◀ ▶ and USE (their bottoms at y 435), so
## while they show it stands between them instead, in the hint bar's span (PHONE-7).
func _box_between_touch_buttons() -> bool:
	return touch_enabled and not controller_active and touch_use.visible and TextSize.factor > 1.0


## The speaker column's width: the widest name it shows, at the current text size (measured once per
## size and engineer name; the HUD is laid out every frame).
func _speaker_column_width() -> float:
	var key: String = "%s|%s" % [TextSize.factor, _first_name()]
	if key != speaker_column_key:
		speaker_column_key = key
		var font: Font = speaker.get_theme_font(&"font")
		var widest: float = 0.0
		for tag: String in _speaker_tags():
			widest = maxf(widest, font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1.0, TextSize.px(SPEAKER_FONT_SIZE)).x)
		speaker_column = ceilf(widest)
	return speaker_column


## The width the words on screen wrap at in [param column]: no row longer than
## DialogueBoxes.MAX_ROW_CHARACTERS (measured once per box, size and column; the HUD is laid out every
## frame).
func _story_wrap_width(column: float) -> float:
	var key: String = "%s|%s|%s" % [story.text, story.get_theme_font_size(&"font_size"), column]
	if key != story_wrap_key:
		story_wrap_key = key
		story_wrap = DialogueBoxes.wrap_width(story.text, story.get_theme_font(&"font"), story.get_theme_font_size(&"font_size"), column, DialogueBoxes.MAX_ROW_CHARACTERS)
	return story_wrap


## Lays out the HUD's text for the current text size, input and box: the dialogue box (its name
## column beside the words while both fit the canvas, above them when they do not; narration without
## one), the hint bar above it (or in its place while no box is up), the top card, the tutorial prompt under the card (or off a station, see _tutorial_prompt_place) and the answer buttons.
func _layout_hud() -> void:
	var touch_layout: bool = touch_enabled and not controller_active
	_set_font_size(story, TextSize.px(DIALOGUE_FONT_SIZE))
	_set_font_size(speaker, TextSize.px(SPEAKER_FONT_SIZE))
	_set_font_size(context_hint_text, TextSize.px(HINT_FONT_SIZE))
	_set_font_size(hud, TextSize.px(CARD_FONT_SIZE))
	_set_font_size(tutorial_text, TextSize.px(TUTORIAL_FONT_SIZE))
	# The dialogue box.
	var column: float = _dialogue_column_width()
	var names: float = _speaker_column_width()
	var between: bool = _box_between_touch_buttons()
	var room: float = _dialogue_room(between)
	var centre_x: float = TOUCH_HINT_CENTRE_X if between else 480.0
	var stacked: bool = DIALOGUE_PADDING.x * 2.0 + names + SPEAKER_GAP + column > room
	# Narration has no name column, so its box is only as wide as the words' column.
	var bar_width: float = DIALOGUE_PADDING.x * 2.0 + column + (names + SPEAKER_GAP if speaker.visible and not stacked else 0.0)
	_set_rect(story, Vector2(story.position.x, DIALOGUE_PADDING.y), Vector2(_story_wrap_width(column), story.size.y))
	var line_height: float = story.get_line_height()
	var text_height: float = line_height * maxi(story.get_line_count(), DialogueBoxes.MAX_ROWS)
	var name_height: float = speaker.get_line_height() + 4.0 if stacked and speaker.visible else 0.0
	var bar_height: float = DIALOGUE_PADDING.y * 2.0 + name_height + text_height
	_set_rect(bottom_bar, Vector2(roundf(centre_x - bar_width * 0.5), DIALOGUE_BOTTOM - bar_height), Vector2(bar_width, bar_height))
	# Narration starts at the box's left margin, where a speaker's name would.
	var words_x: float = DIALOGUE_PADDING.x + names + SPEAKER_GAP if speaker.visible and not stacked else DIALOGUE_PADDING.x
	_set_rect(story, Vector2(words_x, DIALOGUE_PADDING.y + name_height), Vector2(_story_wrap_width(column), text_height))
	_set_rect(speaker, Vector2(DIALOGUE_PADDING.x, DIALOGUE_PADDING.y), Vector2(column if stacked else names, name_height if stacked else text_height))
	speaker_rule.visible = speaker.visible and not stacked
	_set_rect(speaker_rule, Vector2(DIALOGUE_PADDING.x + names + SPEAKER_GAP * 0.5, DIALOGUE_PADDING.y + 2.0), Vector2(1.0, text_height - 4.0))
	_set_rect(dialogue_accent, Vector2(1.0, 1.0), Vector2(3.0, bar_height - 2.0))
	# The top card grows with its text, left of PAUSE (and of the touch DEBUG button where it shows),
	# and takes a third row if its words need one there.
	var card_width: float = clampf(448.0 * TextSize.factor, 448.0, 820.0)
	if _debug_button_shown():
		card_width = minf(card_width, debug_tools.debug_button.position.x - HUD_CARD_GAP - top_card.position.x)
	_set_rect(hud, Vector2(16.0, 7.0), Vector2(card_width - 28.0, hud.size.y))
	var card_height: float = maxf(62.0, hud.get_line_height() * maxi(2, hud.get_line_count()) + 14.0)
	_set_rect(top_card, top_card.position, Vector2(card_width, card_height))
	_set_rect(hud, Vector2(16.0, 7.0), Vector2(card_width - 28.0, card_height - 11.0))
	_set_rect(top_card.get_node("Accent") as Control, Vector2.ZERO, Vector2(4.0, card_height))
	# The hint bar: top right under PAUSE (and under the top card where that reaches across) in the
	# opening and the closing shots, otherwise just above the dialogue box; on touch between ◀ ▶ and USE.
	var cinematic: bool = intro_active or chapter_close_active
	var hint_width: float = minf(278.0 * TextSize.factor, 440.0) if cinematic else (TOUCH_HINT_WIDTH if touch_layout else minf(549.0 * TextSize.factor, 960.0 - HUD_SIDE_MARGIN * 2.0))
	_set_rect(context_hint_text, Vector2(13.0, 3.0), Vector2(hint_width - 23.0, context_hint_text.size.y))
	var hint_height: float = maxf(35.0, context_hint_text.get_line_height() * context_hint_text.get_line_count() + 8.0)
	var hint_x: float = 960.0 - 32.0 - hint_width if cinematic else (TOUCH_HINT_SPAN.x if touch_layout else roundf((960.0 - hint_width) * 0.5))
	# With no box up the hint takes the box's place at the bottom instead of floating over the floor.
	var hint_bottom: float = DIALOGUE_BOTTOM - bar_height - HINT_GAP if bottom_bar.visible else DIALOGUE_BOTTOM
	var hint_y: float = maxf(94.0, top_card.position.y + card_height + HUD_CARD_GAP) if cinematic else hint_bottom - hint_height
	_set_rect(context_hint, Vector2(hint_x, hint_y), Vector2(hint_width, hint_height))
	_set_rect(context_hint_text, Vector2(13.0, 3.0), Vector2(hint_width - 23.0, hint_height - 6.0))
	_set_rect(context_hint.get_node("Accent") as Control, Vector2(1.0, 1.0), Vector2(3.0, hint_height - 2.0))
	# The tutorial prompt, sized to its rows and centred under the card.
	var tutorial_size: Vector2 = tutorial_text.get_minimum_size() + Vector2(32.0, 18.0)
	tutorial_size.x = maxf(tutorial_size.x, 316.0 if tutorial_text.text.contains("\n") else 0.0)
	var tutorial_rect: Rect2 = Rect2(Vector2(roundf(480.0 - tutorial_size.x * 0.5), top_card.position.y + card_height + 18.0), tutorial_size)
	tutorial_prompt_slot = &"under_card"
	if tutorial_prompt.visible and (_covers_station_name(tutorial_rect) or _station_art_overlap(tutorial_rect) > 0.0):
		tutorial_rect.position = _tutorial_prompt_place(tutorial_rect, touch_layout)
		if tutorial_prompt_slot == &"card_place" and top_card.visible:
			# It takes the place of a card that is already leaving: the card goes at once instead of
			# fading out under it.
			top_card.hide()
	_set_rect(tutorial_prompt, tutorial_rect.position, tutorial_size)
	_set_rect(tutorial_text, Vector2(16.0, 9.0), tutorial_size - Vector2(27.0, 18.0))
	_set_rect(tutorial_prompt.get_node("Accent") as Control, Vector2(1.0, 1.0), Vector2(4.0, tutorial_size.y - 2.0))
	if waiting_for_choice:
		_layout_choices(touch_layout, top_card.position.y + card_height + 10.0)


## True while the DEBUG button shows at the top right (DebugTools shows it only when the debug tools
## are available, on the touch layout, with no menu or card up), so the top card and a tutorial
## prompt in the card's place stop short of it. False before DebugTools exists.
func _debug_button_shown() -> bool:
	return debug_tools != null and debug_tools.debug_button != null and debug_tools.debug_button.visible


## Where the tutorial prompt goes when, under the top card, it would cover a station (the breaker's
## name it points to, at large text sizes). Once the card is fading or gone it takes the card's
## place: as near the middle as it can stand between PAUSE (and DEBUG) and the margin, clear of every
## station name and over at most TUTORIAL_ART_OVERLAP of its own area of the machines, the least it
## can. Failing that it goes to the bottom while no box is up; with a box up it waits, hidden, until
## the box has gone (one thing to read at a time, as the opening lines wait for the name card), and
## the hint bar stays empty meanwhile. Sets tutorial_prompt_slot and returns the prompt's position.
func _tutorial_prompt_place(rect: Rect2, touch_layout: bool) -> Vector2:
	# The name card starts fading on the first step's frame, before its tween has moved.
	var card_leaving: bool = last_top_card_key == "name_card" and tutorial_step >= 1
	if not top_card.visible or top_card.modulate.a < 0.999 or card_leaving:
		var top_right: float = pause_button.position.x
		if _debug_button_shown():
			top_right = minf(top_right, debug_tools.debug_button.position.x)
		var best: Vector2 = Vector2(-1.0, top_card.position.y)
		var best_overlap: float = rect.get_area() * TUTORIAL_ART_OVERLAP
		var x: float = HUD_SIDE_MARGIN
		while x + rect.size.x <= top_right - HUD_CARD_GAP:
			var place: Rect2 = Rect2(Vector2(x, top_card.position.y), rect.size)
			if not _covers_station_name(place):
				var overlap: float = _station_art_overlap(place)
				var nearer: bool = best.x < 0.0 or absf(x + rect.size.x * 0.5 - 480.0) < absf(best.x + rect.size.x * 0.5 - 480.0)
				if overlap < best_overlap or (overlap == best_overlap and nearer):
					best = place.position
					best_overlap = overlap
			x += 4.0
		if best.x >= 0.0:
			tutorial_prompt_slot = &"card_place"
			return best
	if not bottom_bar.visible:
		var centre: float = TOUCH_HINT_CENTRE_X if touch_layout and rect.size.x <= TOUCH_HINT_WIDTH else 480.0
		tutorial_prompt_slot = &"bottom"
		return Vector2(roundf(centre - rect.size.x * 0.5), DIALOGUE_BOTTOM - rect.size.y)
	tutorial_prompt_slot = &"waiting"
	tutorial_prompt.hide()
	return rect.position


## The corridor's station names, in the order the checks name them: the breaker, the relay and the
## safe point's labels, then the bypass handle's COOLANT FAULT tag and MANUAL BYPASS plate. Needs the
## bypass handle (built in _ready). Used by _covers_station_name (where the tutorial prompt may go) and
## by text_boxes_test, so the game and its test agree on which names the prompt must leave readable.
func _corridor_station_labels() -> Array[Label]:
	return [$BreakerLabel, $RelayLabel, $CheckpointLabel, bypass_handle.fault_tag, bypass_handle.bypass_label] as Array[Label]


## Whether [param rect] (on the HUD canvas) covers a corridor station name that shows.
func _covers_station_name(rect: Rect2) -> bool:
	if bypass_handle == null:
		return false
	for label: Label in _corridor_station_labels():
		if label.is_visible_in_tree() and label.modulate.a > 0.05 and rect.intersects(label.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, label.size)):
			return true
	return false


## How much of [param rect] (on the HUD canvas) lies over the corridor's machines: the purge display,
## the breaker and the relay.
func _station_art_overlap(rect: Rect2) -> float:
	var area: float = 0.0
	for art: Sprite2D in [purge_terminal_art, breaker_art, relay_art] as Array[Sprite2D]:
		if art.is_visible_in_tree():
			area += rect.intersection(art.get_global_transform_with_canvas() * art.get_rect()).get_area()
	return area


## The two answers. With keys or a controller they stand under the top card with their key or
## button; on touch they sit at the bottom in thumb reach, just above the question, without numbers
## (PHONE-3).
func _layout_choices(touch_layout: bool, top: float) -> void:
	var answers: Array[String] = [M0State.CHOICE_TEXT[M0State.DISCLOSE], M0State.CHOICE_TEXT[M0State.PRESS]]
	if choice_context == "mirror":
		answers = ["USE WOLF'S READOUT", "USE MANUAL PORT"]
	elif choice_context == "lane":
		answers = LANE_CHOICE_TEXT
	var buttons: Array[Button] = [touch_choice_1, touch_choice_2]
	for index: int in 2:
		var button: Button = buttons[index]
		_set_font_size(button, TextSize.px(17 if touch_layout else 16))
		var key: String = settings_menu.prompt(&"choice_1" if index == 0 else &"choice_2", controller_active)
		var text: String = answers[index] if touch_layout else "%s  %s" % [key, answers[index]]
		if button.text != text:
			button.text = text
		if button.autowrap_mode != TextServer.AUTOWRAP_WORD_SMART:
			button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if touch_layout:
		var touch_height: float = maxf(76.0, maxf(touch_choice_1.get_minimum_size().y, touch_choice_2.get_minimum_size().y))
		var touch_top: float = bottom_bar.position.y - 10.0 - touch_height
		_set_rect(touch_choice_1, Vector2(42.0, touch_top), Vector2(428.0, touch_height))
		_set_rect(touch_choice_2, Vector2(490.0, touch_top), Vector2(428.0, touch_height))
		return
	# Right-aligned at x 918, so the widest still leaves the side margin on the left.
	var width: float = minf(522.0 * TextSize.factor, 918.0 - HUD_SIDE_MARGIN)
	var height: float = maxf(40.0 * TextSize.factor, 0.0)
	_set_rect(touch_choice_1, Vector2(918.0 - width, top), Vector2(width, height))
	height = maxf(height, touch_choice_1.get_minimum_size().y)
	_set_rect(touch_choice_1, Vector2(918.0 - width, top), Vector2(width, height))
	_set_rect(touch_choice_2, Vector2(918.0 - width, top + height + 6.0 * TextSize.factor), Vector2(width, maxf(height, touch_choice_2.get_minimum_size().y)))


## The HUD is refreshed every frame, so these write a value only when it differs. A theme override
## notifies every control under it even when the value is the same.
static func _set_font_size(control: Control, font_size: int) -> void:
	if not control.has_theme_font_size_override(&"font_size") or control.get_theme_font_size(&"font_size") != font_size:
		control.add_theme_font_size_override(&"font_size", font_size)


static func _set_font_color(control: Control, color: Color) -> void:
	if not control.has_theme_color_override(&"font_color") or control.get_theme_color(&"font_color") != color:
		control.add_theme_color_override(&"font_color", color)


static func _set_modulate(item: CanvasItem, tint: Color) -> void:
	if item.modulate != tint:
		item.modulate = tint


static func _set_color(rect: ColorRect, color: Color) -> void:
	if rect.color != color:
		rect.color = color


## Moves [param control] to [param at] and sizes it to [param size] (canvas px), each only when it
## differs, like the setters above: a needless write would queue a layout pass every frame.
static func _set_rect(control: Control, at: Vector2, size: Vector2) -> void:
	if control.position != at:
		control.position = at
	if control.size != size:
		control.size = size


func _show_top_card(message: String, hold_seconds: float, accent: Color = TOP_CARD_ACCENT) -> void:
	Tweens.kill(top_card_tween)
	hud.text = message
	($CanvasLayer/TopBar/Accent as ColorRect).color = accent
	top_card.modulate.a = 1.0
	top_card.show()
	top_card_tween = create_tween()
	top_card_tween.tween_interval(hold_seconds)
	top_card_tween.tween_property(top_card, "modulate:a", 0.0, TOP_CARD_FADE_SECONDS)
	top_card_tween.tween_callback(top_card.hide)


func _context_hint() -> String:
	var x: float = human.position.x
	if fail_active:
		# The status line names the cause and the fix; no station hint competes with it.
		return ""
	if records_exit_walking:
		# On their way out through the Records exit, controls off: the USE prompt has been answered.
		return ""
	if state.chapter_id == "junction":
		return _junction_hint(x)
	if state.chapter_id == "records":
		if state.chapter_complete:
			if _at_records_exit(x):
				# While the closing lines are still being shown, USE at the exit goes on to the next one.
				return BREAKER_STAKES_HINT if _records_close_unread() else "E: follow the service line toward Archive."
			return "The exit is open. Head right to follow the service line."
		if absf(x - 190.0) <= 58.0:
			return "E: copy the purge-order trace." if not state.purge_trace_preserved else "Purge order copied. Find the mirror port."
		if absf(x - 520.0) <= 58.0:
			if state.mirror_trace_preserved:
				return "Mirror copied. Head for the exit."
			return "E: examine the mirror port." if state.purge_trace_preserved else "Copy the purge order first."
		if _at_records_exit(x):
			# At the container the hint names it (Nathanial, 2026-10-14): the copy goes into the drawn container.
			return "E: secure the first copy in the container." if state.mirror_trace_preserved else "Preserve both traces before leaving."
		return _records_route_hint()
	if state.checkpoint_reached:
		return "E: enter records access. The Director's purge is still running." if absf(x - 876.0) <= 52.0 else ("E: read the Director's purge display." if x <= PURGE_DISPLAY_MAX_X else "Return to the safe point to enter records access.")
	if state.door_open:
		if seal_opening:
			return SEAL_OPENING_HINT
		if absf(x - 876.0) <= 52.0:
			return "E: save at the safe point."
		return "The seal is open. Move to the safe point."
	if x <= PURGE_DISPLAY_MAX_X:
		return "E: read the Director's purge display."
	if wolf_heading_to_relay:
		return "WOLF is moving to the contact."
	if _at_bypass(x):
		if not state.breaker_armed:
			return "The bypass is dead. Arm the breaker first."
		if _relay_refused():
			return BYPASS_HOLD_HINT % [bypass_ticks, BYPASS_TICKS]
		# On the honest route WOLF can take the relay until the crank is done; the hint keeps saying so.
		return BYPASS_OFFER_HINT if bypass_ticks == 0 else BYPASS_HOLD_OFFER_HINT % [bypass_ticks, BYPASS_TICKS]
	if _at_breaker(x):
		if state.breaker_armed:
			return "The breaker is live. Go to the MANUAL BYPASS by the relay." if _relay_refused() else "The breaker is live. Go to the coolant relay."
		if _stakes_up() or _stakes_queued():
			# The relay prompt never shares the screen with WOLF's stakes line: the next USE goes on from
			# it, and then he asks about the relay.
			return BREAKER_STAKES_HINT
		return "E: talk to WOLF about the relay." if state.memory.is_empty() else "E: arm the breaker."
	if _at_relay(x):
		if not state.breaker_armed:
			return "The relay is dark. Return to the breaker first."
		return "WOLF refused the live contact. Use the MANUAL BYPASS beside it." if _relay_refused() else "E: signal WOLF to take the contact."
	if state.breaker_armed:
		return "Go to the MANUAL BYPASS beside the relay." if _relay_refused() else "Go to the coolant relay. WOLF is ready for the contact."
	if not state.memory.is_empty():
		return "Return to the breaker and arm power."
	return "Find the breaker. WOLF will follow your lead."


func _junction_hint(x: float) -> String:
	var line: StringName = pressure_line.state
	var fuse_lit: bool = line == &"charged" or line == &"fuse"
	if state.door_blown:
		return _lane_hint(x)
	# Standing on the grate while the line builds is the one place that can knock you down, so
	# that warning wins over the breaker's hint where the two ranges touch.
	if line == &"building" and PressureLine.is_on_vent(x):
		return "The vent is about to blow. Get off the grate now." if pressure_line.is_warning() else "Relief vent. Get off the grate before the gauge peaks."
	if absf(x - JunctionRoom.BREAKER_X) <= 52.0:
		match line:
			&"idle":
				return "E: arm the overload breaker."
			&"tripped":
				return "E: reset the breaker. The vent let go."
			&"building":
				return "The line is live. Get to the valve by the door."
	if absf(x - JunctionRoom.VALVE_X) <= 52.0 and line == &"building":
		return "HOLD E: crank the valve, %d of %d turns." % [pressure_line.turns, PressureLine.TURNS_NEEDED]
	if fuse_lit:
		return "Fuse lit. Get clear of the door."
	if absf(x - JunctionRoom.VALVE_X) <= 52.0:
		return "The valve is dead. Arm the breaker by the entrance."
	if PressureLine.is_on_vent(x):
		return "Relief vent. It lets go when the gauge peaks."
	match line:
		&"building":
			return "The line is building. Crank the valve by the door."
		&"tripped":
			return "The breaker tripped. Reset it by the entrance."
	# Before the ladder has given the chain, the bar says only the goal (Q6).
	return JUNCTION_CHAIN_HINT if ladder_step >= JUNCTION_LADDER_SECONDS.size() else JUNCTION_GOAL_HINT


## True once WOLF has asked at the rubble line how to bring the sentry down (this attempt).
func _lane_asked() -> bool:
	return not lane_choice.is_empty() or (waiting_for_choice and choice_context == "lane")


## True while the sentry is after the engineer: locking on or chasing.
func _sentry_hunting() -> bool:
	return sentry_brain.state == &"lock" or sentry_brain.state == &"chase"


## The tank can drop now: the engineer is at the TANK RELEASE with the tank hanging over a live
## sentry, and, if WOLF is drawing it, he has it stopped on the mark (_drop_waits_for_wolf).
func _drop_ready() -> bool:
	return state.chapter_id == "junction" and state.door_blown and not state.sentry_down and drop_arm.state == &"hung" and _at_arm_panel(human.position.x) and not _drop_waits_for_wolf()


func _lane_hint(x: float) -> String:
	if state.junction_cleared:
		return "The door is open."
	if state.sentry_down:
		if x >= JunctionRoom.BOLT_REACH_MIN_X:
			match bolt_state:
				&"locked":
					return "E: pop the exit bolt."
				&"charging":
					return BOLT_CHARGING_LINE
			if _hatch_sliding():
				return HATCH_OPENING_HINT
			# The way out is offered at the door itself, not from the bolt panel.
			return "E: leave through the door." if x >= JunctionRoom.HATCH_REACH_MIN_X else "The door is open. Leave through it."
		if _hatch_sliding():
			return HATCH_OPENING_HINT
		return "The door is open. Leave through it." if bolt_state == &"open" else "The sentry is down. Pop the exit bolt by the door."
	if drop_arm.cloud_active() and DropArm.in_cloud(x):
		return "Coolant cloud. Get out of it."
	if _sentry_hunting() and x > SentryBrain.LANE_ENTRY_X:
		return "It's after you. Get back over the rubble."
	if _at_arm_panel(x):
		match drop_arm.state:
			&"hung":
				if wolf_baiting:
					return "Wait for WOLF to park it on the mark." if _drop_waits_for_wolf() else "E: drop the tank. It's parked on the mark."
				return "E: drop the tank. Land it with the sentry on the mark."
			&"falling":
				return "The tank is falling."
			&"rewinding":
				return "The winch is hauling the tank back up. Wait for the clamp."
	if _sentry_hunting():
		return "Stay back over the rubble until it gives up."
	if SentryBrain.is_exposed(x):
		return "You're in its sights. Hide at the TANK RELEASE or the rubble."
	if wolf_baiting:
		return "WOLF is drawing the sentry onto the mark. Get to the TANK RELEASE."
	if wolf_broke_off:
		return "WOLF has broken off. Time the drop on its patrol from the TANK RELEASE."
	return "The sentry patrols past the rubble. The TANK RELEASE hides you from it."


func _objective() -> String:
	if state.chapter_id == "junction":
		if state.junction_cleared:
			return "SERVICE LINE CLEARED"
		if state.sentry_down:
			return "POP THE EXIT BOLT"
		if state.door_blown:
			# The tank is named only once WOLF has asked how to bring the sentry down.
			return "DROP THE TANK" if _lane_asked() else "GO THROUGH THE DOOR"
		match pressure_line.state:
			&"building":
				return "CRANK THE VALVE"
			&"charged", &"fuse", &"blown":
				return "GET CLEAR OF THE DOOR"
		return "ARM THE BREAKER"
	if state.chapter_id == "records":
		if state.chapter_complete:
			return "FIRST COPY SECURED"
		if not state.purge_trace_preserved:
			return "COPY PURGE ORDER"
		if not state.mirror_trace_preserved:
			return "COPY MIRROR INDEX"
		return "REACH EXIT"
	if state.checkpoint_reached:
		return "SAFE POINT REACHED"
	if state.door_open:
		return "REACH SAFE POINT"
	if state.breaker_armed:
		return "OPEN THE SEAL"
	if not state.memory.is_empty():
		return "ARM THE BREAKER"
	return "CHECK THE BREAKER"


func _install_inputs() -> void:
	_add_action(&"move_left", KEY_A, KEY_LEFT)
	_add_action(&"move_right", KEY_D, KEY_RIGHT)
	_add_action(&"interact", KEY_E)
	_add_action(&"choice_1", KEY_1)
	_add_action(&"choice_2", KEY_2)
	_add_action(&"pause_game", KEY_ESCAPE)
	_add_action(&"cycle_name", KEY_I)
	_add_joy_button(&"move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button(&"move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy_axis(&"move_left", -1.0)
	_add_joy_axis(&"move_right", 1.0)
	_add_joy_button(&"interact", JOY_BUTTON_A)
	_add_joy_button(&"choice_1", JOY_BUTTON_X)
	_add_joy_button(&"choice_2", JOY_BUTTON_Y)
	_add_joy_button(&"pause_game", JOY_BUTTON_START)
	_add_joy_button(&"ui_cancel", JOY_BUTTON_B)
	_add_joy_button(&"ui_accept", JOY_BUTTON_A)


func _add_action(action: StringName, key: Key, alternate: Key = KEY_NONE) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var primary: InputEventKey = InputEventKey.new()
	primary.physical_keycode = key
	InputMap.action_add_event(action, primary)
	if alternate != KEY_NONE:
		var secondary: InputEventKey = InputEventKey.new()
		secondary.physical_keycode = alternate
		InputMap.action_add_event(action, secondary)


func _add_joy_button(action: StringName, button_index: JoyButton) -> void:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button_index
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


func _add_joy_axis(action: StringName, value: float) -> void:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)


# --- Debug tools hooks (scripts/debug). Kept together so they move as one when Main is split. ---

## The debug tools and cheat codes (DebugTools): idle and hidden unless available.
var debug_tools: DebugTools


func _setup_debug_tools() -> void:
	debug_tools = DebugTools.new()
	debug_tools.name = "DebugTools"
	add_child(debug_tools)
	debug_tools.setup(self)


## The debug menu's invincibility cheat: no knockdown lands (the door still blows as if the engineer
## were clear). A knockdown the menu forces still lands. Always false while the tools are hidden.
func _debug_spares_knockdown() -> bool:
	return debug_tools != null and debug_tools.actions.spares_knockdown()


## The debug menu's freeze-sentry cheat: the sentry's brain does not tick.
func _debug_sentry_frozen() -> bool:
	return debug_tools != null and debug_tools.actions.sentry_frozen


## Android Back closes the debug menu (or ends frame stepping) before it reaches the game's menus.
func _debug_takes_back() -> bool:
	return debug_tools != null and debug_tools.handle_back()


# The debug menu's way into play (DebugActions, DebugMenu): small public calls onto Main's own steps,
# so the tools (typed against Main) never call its private methods, and a rename here fails when the
# scripts are parsed rather than when a menu button is pressed.

## A fresh run from the opening or, with [param skip_intro], from the corridor's first control.
func debug_new_game(skip_intro: bool) -> void:
	_cancel_fail()
	_new_game()
	if skip_intro:
		_finish_intro()


## Back to the checkpoint on disk, as the title's Continue does.
func debug_load_checkpoint() -> void:
	_cancel_fail()
	_load_game()


## The engineer's interact, as the key, button or USE does it.
func debug_interact() -> void:
	_interact()


## WOLF asks how to bring the sentry down, and [param response] answers (1: he draws it, 2: alone).
func debug_answer_lane(response: int) -> void:
	_ask_lane()
	_choose_lane(response)


func debug_show_end_card() -> void:
	_show_end_card()


## Where the engineer stands beside [param station] (x: centre, w: its side) coming from [param x].
func debug_station_side_x(station: Vector4, x: float) -> float:
	return _station_side_x(station, x)


## The engineer at [param human_x] and WOLF at [param wolf_x], standing still, the controls updated.
func debug_place(human_x: float, wolf_x: float) -> void:
	human.position.x = human_x
	door_faced = false
	wolf.position.x = wolf_x
	human.velocity = Vector2.ZERO
	wolf.velocity = Vector2.ZERO
	_update_controls()


## Knocks the engineer down through the one knockdown path with [param kind]'s card: vent, blast,
## cloud, or sentry (worded by how it caught them).
func debug_knock_down(kind: StringName) -> void:
	var reason: String = _sentry_reason()
	match kind:
		&"vent":
			reason = JunctionRoom.VENT_REASON % _first_name()
		&"blast":
			reason = JunctionRoom.BLAST_REASON % _first_name()
		&"cloud":
			reason = JunctionRoom.CLOUD_REASON % _first_name()
	_fail_beat(reason, kind == &"sentry")


## The valve's last turn has landed (the fuse is lit), as the crank lands it.
func debug_valve_turned() -> void:
	_valve_turned()
	_update_controls()


## The TANK RELEASE lets the tank go.
func debug_drop_tank() -> void:
	_drop_tank()


## The game's own autosave at this beat.
func debug_save_progress() -> void:
	_save_progress()


## The save on disk changed: the title's buttons follow it.
func debug_save_changed() -> void:
	if title_open:
		_refresh_continue()


func debug_refresh_ui() -> void:
	_refresh_ui()


## The station interact is being held at ("valve", "bypass"), or empty.
func debug_hold_station() -> StringName:
	return _hold_station()


## The debug menu closed: focus goes back where the game's own menus keep it (the title's), or nowhere.
func debug_restore_focus() -> void:
	var target: Control = _menu_focus_target()
	if target != null and target.is_visible_in_tree():
		_grab_menu_focus(target)
	else:
		get_viewport().gui_release_focus()


## What the game is doing right now, as plain values for the debug overlay and bug captures
## (DebugTools.dump adds performance, the save on disk and the build). The overlay's frequent refresh
## leaves out the full save state ([param include_state] false); captures and scripts keep it.
func debug_snapshot(include_state: bool = true) -> Dictionary:
	var in_junction: bool = state.chapter_id == "junction"
	var fixated_on: String = "WOLF" if sentry_brain.state == &"fixated" else ("engineer" if _sentry_hunting() else "—")
	var relay: String = "—"
	if not state.memory.is_empty():
		var told: bool = state.memory.get("choice_id") == M0State.DISCLOSE
		relay = ("disclose" if told else "press") + (" → WOLF" if state.route == "cooperate" else (" → bypass" if state.route == "fallback" else ""))
	var snapshot: Dictionary = {
		"room": state.chapter_id,
		"beat": debug_beat(),
		"objective": "" if title_open else _objective(),
		"line": status_line,
		"hint": "" if title_open else _context_hint(),
		"engineer": {"x": human.position.x, "y": human.position.y, "facing": "left" if human.body_sprite.flip_h else "right", "state": _debug_engineer_state()},
		"wolf": {"x": wolf.position.x, "y": wolf.position.y, "facing": "left" if wolf.body_sprite.flip_h else "right", "target_x": debug_wolf_target(), "why": debug_wolf_why()},
		"sentry": {"active": in_junction, "state": str(sentry_brain.state), "x": sentry_brain.x, "facing": "left" if sentry_brain.facing < 0.0 else "right", "sight_range": SentryBrain.SIGHT_RANGE, "fixated_on": fixated_on},
		"pressure_line": {"state": str(pressure_line.state), "gauge": pressure_line.gauge, "turns": pressure_line.turns, "turns_needed": PressureLine.TURNS_NEEDED, "fuse": pressure_line.fuse_remaining},
		"drop_arm": {"state": str(drop_arm.state), "drop": drop_arm.drop_amount(), "cloud": drop_arm.cloud_remaining},
		"bolt": {"state": str(bolt_state), "charge": bolt_charge_remaining},
		"hazards": {
			"vent": in_junction and junction_room.vent_hazard.armed,
			"cloud": in_junction and junction_room.cloud_hazard.armed,
			"blast": _fuse_lit(),
			"sentry contact": in_junction and sentry_brain.state == &"chase",
		},
		"memory": state.memory.duplicate(true),
		"choices": {"relay": relay, "mirror": state.mirror_route, "lane": lane_choice if not lane_choice.is_empty() else state.lane_recap},
		"flags": {
			"title_open": title_open, "intro_active": intro_active, "paused": get_tree().paused, "waiting_for_choice": waiting_for_choice,
			"choice_context": choice_context, "fail_active": fail_active, "chapter_close_active": chapter_close_active,
			"end_card_active": end_card_active, "touch_layout": touch_enabled and not controller_active, "controller_active": controller_active,
			"save_pending": save_pending, "seal_opening": seal_opening, "wolf_baiting": wolf_baiting, "bypass_ticks": bypass_ticks,
		},
		"save_path": save_path,
		"settings_path": settings_path,
	}
	if include_state:
		snapshot["state"] = state.to_dict()
	return snapshot


func debug_beat() -> String:
	if title_open:
		return "title"
	if intro_active:
		return "opening %d/%d" % [intro_step + 1, INTRO_LINES.size()]
	if end_card_active:
		return "END OF SLICE card"
	if hatch_exit_walking or records_exit_walking:
		return "walking out"
	if chapter_close_active:
		return "chapter close"
	if fail_active:
		return "knockdown"
	if waiting_for_choice:
		return "choice (%s)" % (choice_context if not choice_context.is_empty() else "relay")
	return "play"


func _debug_engineer_state() -> String:
	if not human.visible:
		return "hidden"
	if fail_active:
		return "knocked down"
	if hold_use.holding:
		return "cranking the %s" % hold_use.station
	if engineer_step_x >= 0.0 or hatch_exit_walking:
		return "walking on their own"
	if not human.controlled:
		return "no control"
	if absf(human.velocity.x) > 1.0:
		return "walking"
	return "stepping out of a machine" if human.settle_x >= 0.0 else "standing"


## Where WOLF is heading: his own spot, or his follow spot worked out the way M0Actor.follow_x does
## without changing his side, or -1.
func debug_wolf_target() -> float:
	if wolf.autonomous_target_x >= 0.0:
		return wolf.autonomous_target_x
	if wolf.follow_target == null or wolf.follow_side == 0:
		return -1.0
	return wolf.off_machines(clampf(wolf.follow_target.position.x + wolf.follow_side * M0Actor.FOLLOW_GAP, wolf.follow_min_x, wolf.follow_max_x), wolf.follow_side)


## Why WOLF is where he is: following, scouting, baiting, holding a spot or refusing.
func debug_wolf_why() -> String:
	if not wolf.visible or title_open:
		return "—"
	if hatch_exit_walking:
		return "leaving through the exit door"
	if wolf_holding_relay:
		return "hold: on the relay contact"
	if wolf_heading_to_relay:
		return "hold: going to the relay contact"
	if _wolf_off_relay():
		return "refuse: off the relay he refused" if _relay_refused() else "hold: back from the relay"
	match state.chapter_id:
		"records":
			if not state.mirror_trace_preserved:
				return "scout: the mirror port"
		"junction":
			if wolf_scouting:
				return "scout: the door seam"
			if wolf.autonomous_target_x == JunctionRoom.WOLF_CLEAR_X:
				return "hold: by the entrance until his spot by the valve is clear" if state.door_blown else "hold: clear of the vent and blast"
			if wolf.autonomous_target_x == JunctionRoom.WOLF_BAIT_X:
				return "bait: drawing the sentry"
			if wolf.autonomous_target_x == JunctionRoom.WOLF_RUBBLE_X:
				return "refuse: holding at the rubble" if lane_choice == "refused" else "hold: at the rubble"
	if wolf.autonomous_target_x >= 0.0:
		return "hold: his own spot"
	return "follow" if wolf.follow_target != null else "waiting"
