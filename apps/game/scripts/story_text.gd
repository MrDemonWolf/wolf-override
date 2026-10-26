class_name StoryText
extends RefCounted
## The story's text table: every story message kept in a constant (Main's, JunctionRoom's knockdown
## cards and M0State's relay answers), each marked once for the translation template with its
## translator note and its i18n marks. Built in localization PR L7c (research branch
## codex/localization-research, docs/research-2026-10/localization/PLAN.md, "L7c mark-story") as the one
## part of the lighter-game plan's S05 text tables this PR needs, since S05 had not landed: the constants
## stay where they are, byte for byte (tests/approved_wording_test.gd reads them there), and this table is
## where their marks live (DESIGN.md, "How the lighter-game plan's text steps fit": "the text tables are
## where the I18n.KEY.tr marks go, once per table entry"). Story lines written in place in a function are
## marked where they are written instead.
##
## Contract: [method messages] returns every message below in English, unchanged (I18n.KEY.tr hands its
## argument back). Nothing in the game calls it: Godot's template generator reads the KEY.tr() calls
## (extract_pot.sh), and tests/i18n_test.gd checks that every story constant's pieces are in it. The
## game draws these lines through I18n.shown, which looks each message up where it is drawn.
##
## The marks, read by scripts/i18n/i18n_tool.py (MARKS) from the "#." notes the generator writes:
## - story: a story-critical line; `check --release` fails while one is untranslated or fuzzy.
## - speaker=WOLF, DIRECTOR, engineer or narrator: who says it, for translators and the back-translation.
## - engineer=name, you, third or self: how the engineer appears (decision D9: never gendered); the gender
##   gate reads it. A %s or {name} with no mark counts as the name.
## - slot=choice: the %s holds a quoted answer, not the name.
## - keep-breaks: the line break carries meaning, so a translation keeps it; every other break is layout.
## A note must never contain the word the PO loader reads as a fuzzy flag (i18n_tool.py fuzzy_notes).
##
## Gotcha: the generator takes a "# TRANSLATORS:" comment and every comment line after it, up to the code
## line it stands over, as that call's note, so each entry is its own line with its comments right above.


## Every story message kept in a constant, marked for the translation template (see the class notes).
static func messages() -> Array[String]:
	return [
		# The opening (INTRO_LINES). Its untagged beats are whole messages; the Director's and WOLF's words
		# are kept apart from their tags.
		# TRANSLATORS: The Director, the opening's first line: an order to WOLF, whom he thinks is in standby, to kill a witness, the records worker. The worker's gender is not given: use a neutral form where the language has one.
		# i18n: story speaker=DIRECTOR
		I18n.KEY.tr(Main.INTRO_ORDER_WORDS),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.INTRO_LINES[1]),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.INTRO_LINES[2]),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.INTRO_LINES[3]),
		# TRANSLATORS: The Director to WOLF, who has woken on his own.
		# i18n: story speaker=DIRECTOR
		I18n.KEY.tr(Main.INTRO_STANDBY_WORDS),
		# TRANSLATORS: WOLF's answer to the Director: he heard the order to kill the witness and refuses it.
		# i18n: story speaker=WOLF
		I18n.KEY.tr(Main.INTRO_REFUSAL_WORDS),
		# TRANSLATORS: The Director's order after WOLF refuses.
		# i18n: story speaker=DIRECTOR
		I18n.KEY.tr(Main.INTRO_LOCKDOWN_WORDS),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.INTRO_LINES[6]),
		# First control: why the engineer trusts WOLF, then the opening exchange.
		# TRANSLATORS: %s is the engineer's first name. They are non-binary: no gendered words about them.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(Main.TRUST_LINE_1),
		# TRANSLATORS: %s is the engineer's first name. They are non-binary: no gendered words about them.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(Main.TRUST_LINE_2),
		# TRANSLATORS: WOLF to the engineer, who arrived after the Director's order.
		# i18n: story speaker=WOLF
		I18n.KEY.tr(Main.OPENING_WOLF_WORDS),
		# TRANSLATORS: The engineer answers WOLF (their name stands over the line). No gendered forms for the speaker. "He" is the Director; the witness's gender is not given.
		# i18n: story speaker=engineer engineer=self
		I18n.KEY.tr(Main.OPENING_ENGINEER_WORDS),
		# The corridor.
		# TRANSLATORS: i18n: story speaker=WOLF
		I18n.KEY.tr(Main.STAKES_WORDS),
		# TRANSLATORS: WOLF's question at the coolant relay; the engineer answers with one of two choices. COOLANT FAULT is the tag painted on the relay.
		# i18n: story speaker=WOLF
		I18n.KEY.tr(Main.RELAY_QUESTION_WORDS),
		# TRANSLATORS: An answer the engineer can give WOLF at the relay (a button). WOLF may quote it later.
		# i18n: story speaker=engineer engineer=self
		I18n.KEY.tr(M0State.CHOICE_TEXT[M0State.DISCLOSE]),
		# TRANSLATORS: An answer the engineer can give WOLF at the relay (a button). WOLF may quote it later.
		# i18n: story speaker=engineer engineer=self
		I18n.KEY.tr(M0State.CHOICE_TEXT[M0State.PRESS]),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.BREAKER_CATCHES_LINE),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.BYPASS_START_LINE),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.BYPASS_HALF_LINE),
		# TRANSLATORS: %s is the engineer's first name. Avoid a past tense with the engineer as its subject ("left"): it shows their gender in Polish and Russian. Rephrase.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(Main.BYPASS_RELEASED_LINE),
		# Coming back to a checkpoint or the start of a stretch (knockdowns and Continue).
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.RESTORE_FROM_DISK_LINE),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.RESTORE_BEAT_LINE),
		# Records Access.
		# TRANSLATORS: An answer the engineer can give WOLF at the mirror port (a button, in capitals).
		# i18n: story speaker=engineer engineer=self
		I18n.KEY.tr(Main.MIRROR_CHOICE_TEXT[0]),
		# TRANSLATORS: An answer the engineer can give WOLF at the mirror port (a button, in capitals).
		# i18n: story speaker=engineer engineer=self
		I18n.KEY.tr(Main.MIRROR_CHOICE_TEXT[1]),
		# TRANSLATORS: The narration's card as the first copy is secured; WOLF speaks next.
		# i18n: story speaker=narrator
		I18n.KEY.tr(Main.RECORDS_SECURED_WORDS),
		# TRANSLATORS: i18n: story speaker=WOLF
		I18n.KEY.tr(Main.RECORDS_CLOSE_WOLF_WORDS),
		# TRANSLATORS: The engineer answers WOLF (their name stands over the line). Archive is the next place.
		# i18n: story speaker=engineer engineer=self
		I18n.KEY.tr(Main.RECORDS_CLOSE_ENGINEER_WORDS),
		# The Service Junction.
		# TRANSLATORS: The engineer, entering the junction (their name stands over the line).
		# i18n: story speaker=engineer engineer=self
		I18n.KEY.tr(Main.JUNCTION_ENTRY_WORDS),
		# TRANSLATORS: The engineer names the next step when the player stalls (their name stands over the line).
		# i18n: story speaker=engineer engineer=self
		I18n.KEY.tr(Main.LADDER_BREAKER_WORDS),
		# TRANSLATORS: The engineer gives the whole chain when the player stalls (their name stands over the line).
		# i18n: story speaker=engineer engineer=self
		I18n.KEY.tr(Main.LADDER_CHAIN_WORDS),
		# TRANSLATORS: i18n: story speaker=WOLF
		I18n.KEY.tr(Main.WOLF_DOOR_WARNING_WORDS),
		# TRANSLATORS: Continue's restore line in the junction before the door is down; WOLF's warning follows.
		# i18n: story speaker=narrator
		I18n.KEY.tr(Main.JUNCTION_RESTORE_A_WORDS),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.JUNCTION_CLEARED_LINE),
		# The refused presses: each station's answer when it cannot do anything yet.
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.REFUSE_VALVE_DEAD),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.REFUSE_VALVE_TRIPPED),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.REFUSE_DOOR),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.REFUSE_BREAKER_LIVE),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.REFUSE_FUSE_LIT),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.REFUSE_SPENT),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.REFUSE_REWINDING),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.REFUSE_RELEASE_SPENT),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.REFUSE_EXIT_SENTRY),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.REFUSE_EXIT_DOOR),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.DROP_WAIT_LINE),
		# The door going and the sentry.
		# TRANSLATORS: %s is the engineer's first name, as an object ("for their call"): keep the name in the nominative (no case ending), and no gendered words about them.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(Main.RUBBLE_LINE),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.RUBBLE_WAKE_LINE),
		# TRANSLATORS: An answer the engineer can give WOLF at the rubble (a button): WOLF draws the sentry under the tank.
		# i18n: story speaker=engineer engineer=self
		I18n.KEY.tr(Main.LANE_CHOICE_TEXT[0]),
		# TRANSLATORS: An answer the engineer can give WOLF at the rubble (a button): the engineer times the drop.
		# i18n: story speaker=engineer engineer=self
		I18n.KEY.tr(Main.LANE_CHOICE_TEXT[1]),
		# TRANSLATORS: WOLF to the engineer, who told him the relay's risk. Avoid a past tense that shows the engineer's gender ("you told me"): rephrase.
		# i18n: story speaker=WOLF engineer=you
		I18n.KEY.tr(Main.BAIT_YES_WORDS),
		# TRANSLATORS: WOLF to the engineer, who pressed him at the relay without warning. Avoid a form that shows the engineer's gender ("you'd have sent me"): rephrase.
		# i18n: story speaker=WOLF engineer=you
		I18n.KEY.tr(Main.BAIT_NO_WORDS),
		# TRANSLATORS: WOLF, when the engineer will time the drop alone.
		# i18n: story speaker=WOLF
		I18n.KEY.tr(Main.ALONE_HOLD_WORDS),
		# TRANSLATORS: i18n: story speaker=WOLF
		I18n.KEY.tr(Main.ALONE_FALL_WORDS),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.DROP_PARKED_LINE),
		# TRANSLATORS: %s is the engineer's first name, as an object: keep the name in the nominative (no case ending), and no gendered words about them.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(Main.SENTRY_LOCK_LINE),
		# TRANSLATORS: %s is the engineer's first name, as an object: keep the name in the nominative (no case ending), and no gendered words about them.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(Main.SENTRY_LOST_LINE),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.TANK_MISS_LINE),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.TANK_MISS_TURN_LINE),
		# TRANSLATORS: WOLF breaks off after a missed drop, short of the sentry.
		# i18n: story speaker=WOLF
		I18n.KEY.tr(Main.BROKE_OFF_RUBBLE_WORDS),
		# TRANSLATORS: WOLF breaks off after a missed drop, already past the sentry.
		# i18n: story speaker=WOLF
		I18n.KEY.tr(Main.BROKE_OFF_HATCH_WORDS),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.TANK_HIT_LINE),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.TANK_HIT_OFF_CENTRE_LINE),
		# TRANSLATORS: i18n: story speaker=WOLF
		I18n.KEY.tr(Main.TANK_HIT_WOLF_WORDS),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.POP_BOLT_LINE),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.BOLT_CHARGING_LINE),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.BOLT_ARC_LINE),
		# TRANSLATORS: i18n: story speaker=narrator
		I18n.KEY.tr(Main.HATCH_OPENED_LINE),
		# The knockdown cards: what knocked the engineer down, then how to avoid it.
		# TRANSLATORS: A knockdown card. %s is the engineer's first name, as an object: keep the name in the nominative (no case ending), and no gendered words about them.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(JunctionRoom.VENT_REASON),
		# TRANSLATORS: A knockdown card. %s is the engineer's first name, as an object: keep the name in the nominative (no case ending), and no gendered words about them.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(JunctionRoom.BLAST_REASON),
		# TRANSLATORS: A knockdown card. %s is the engineer's first name, as an object: keep the name in the nominative (no case ending), and no gendered words about them. TANK RELEASE is a station's name plate.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(JunctionRoom.SENTRY_REASON),
		# TRANSLATORS: A knockdown card. %s is the engineer's first name, as an object: keep the name in the nominative (no case ending), and no gendered words about them.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(JunctionRoom.SENTRY_CHASED_REASON),
		# TRANSLATORS: A knockdown card. %s is the engineer's first name, as an object: keep the name in the nominative (no case ending), and no gendered words about them.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(JunctionRoom.CLOUD_REASON),
		# The END OF SLICE card: its heading, thanks, the recap's heading, each row's topic and its words.
		# TRANSLATORS: The end card's title, in capitals: the end of this early part of the game.
		# i18n: story
		I18n.KEY.tr(Main.END_CARD_TITLE),
		# TRANSLATORS: i18n: story
		I18n.KEY.tr(Main.END_CARD_THANKS),
		# TRANSLATORS: The heading over this run's choices on the end card, in capitals.
		# i18n: story
		I18n.KEY.tr(Main.END_CARD_RECAP_HEADER),
		# TRANSLATORS: An end-card topic, in capitals: the coolant relay.
		# i18n: story
		I18n.KEY.tr(Main.RECAP_RELAY_TOPIC),
		# TRANSLATORS: An end-card topic, in capitals: the mirror port.
		# i18n: story
		I18n.KEY.tr(Main.RECAP_MIRROR_TOPIC),
		# TRANSLATORS: An end-card topic, in capitals: the sentry machine.
		# i18n: story
		I18n.KEY.tr(Main.RECAP_LANE_TOPIC),
		# TRANSLATORS: An end-card row. {name} is the engineer's first name; keep {name} as written. Avoid a past tense with the engineer as its subject ("told"): it shows their gender in Polish and Russian. Rephrase.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(Main.RECAP_RELAY_COOPERATE_WORDS),
		# TRANSLATORS: An end-card row. {name} is the engineer's first name; keep {name} as written. Avoid a past tense with the engineer as its subject ("told", "cranked"): rephrase.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(Main.RECAP_RELAY_DISCLOSE_BYPASS_WORDS),
		# TRANSLATORS: An end-card row. {name} is the engineer's first name; keep {name} as written. Avoid a past tense with the engineer as its subject ("rushed", "cranked"): rephrase.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(Main.RECAP_RELAY_PRESS_WORDS),
		# TRANSLATORS: An end-card row.
		# i18n: story speaker=narrator
		I18n.KEY.tr(Main.RECAP_MIRROR_WOLF_WORDS),
		# TRANSLATORS: An end-card row. {name} is the engineer's first name; keep {name} as written. Avoid a past tense with the engineer as its subject ("copied"): rephrase.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(Main.RECAP_MIRROR_MANUAL_WORDS),
		# TRANSLATORS: An end-card row.
		# i18n: story speaker=narrator
		I18n.KEY.tr(Main.RECAP_LANE_WOLF_WORDS),
		# TRANSLATORS: An end-card row. {name} is the engineer's first name; keep {name} as written. Avoid a past tense with the engineer as its subject ("timed") and an agreeing word for "alone" (solo/sola, seul/seule): rephrase.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(Main.RECAP_LANE_REFUSED_WORDS),
		# TRANSLATORS: An end-card row. {name} is the engineer's first name; keep {name} as written. Avoid a past tense with the engineer as its subject ("timed"): rephrase.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(Main.RECAP_LANE_ALONE_WORDS),
		# TRANSLATORS: An end-card row. {name} is the engineer's first name; keep {name} as written. Avoid a past tense with the engineer as its subject ("timed"): rephrase.
		# i18n: story speaker=narrator engineer=name
		I18n.KEY.tr(Main.RECAP_LANE_BROKE_OFF_WORDS),
		# TRANSLATORS: An end-card row, for a save that did not store how the sentry came down.
		# i18n: story speaker=narrator
		I18n.KEY.tr(Main.RECAP_LANE_UNKNOWN_WORDS),
	]
