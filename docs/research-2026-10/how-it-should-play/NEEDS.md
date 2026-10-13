# What WOLF//OVERRIDE should and needs to play like

WOLF//OVERRIDE is an original game and story by **Nathanial Henniges**. This list turns eleven fact-checked research topics, a twelfth on the readable image, a round-2 gap pass and three first-time-player reviews into concrete needs for the playable slice (title, opening, corridor, Records, Service Junction, END OF SLICE). The research informs craft. It does not replace Nathanial's premise, and his latest decision wins wherever this list disagrees with one (see [Questions for Nathanial](#questions-for-nathanial)).

**Round 2 (2026-10-13):** a critic's review found 23 gaps; this revision closes them with a gap-pass topic ([topics/gap-pass.md](topics/gap-pass.md)), a twelfth topic on the readable image ([topics/readable-image.md](topics/readable-image.md)), four new captures (failures, front end, controller, display sizes; [CAPTURE-ROUND2.md](playthrough/CAPTURE-ROUND2.md)) and headless press probes. New areas 14-20 and new needs are marked "round 2" in the contents.

**Build checked:** game code at `da5c14e` (identical to the captured `baffea4`; the only later commit changed docs). Paths like `main.gd:970` are in `apps/game/scripts/`. Frames like `D-0048` (desktop, 1280x720) and `M-0062` (phone, 2400x1080) are from the scripted capture described in [CAPTURE-ROUND1.md](playthrough/CAPTURE-ROUND1.md).

**How to read a need**
- **Level:** **MUST** (a first-time player is hurt without it), **SHOULD** (clearly better, do it soon), **COULD** (worth doing later or as an option).
- **Why:** one line, with source ids. Every id is credited in [SOURCES.md](SOURCES.md); the full reasoning and quotes are in [topics/](topics/).
- **Target:** something you can measure. "Derived" means we calculated or proposed it; no shipped game publishes that number. Every timing target still has to be validated by hands-on play.
- **Now:** **MET**, **PARTLY**, **NOT MET** or **UNKNOWN**, with the evidence (a code line or a frame). Evidence from frames is from scripted stills, not hands-on play.
- **Fix:** the concrete change. The order to do them in is in [PLAN.md](PLAN.md).

The engineer (default name Rowan Vale) uses they/them; WOLF is he/his.

## Contents
1. [Loop and pacing](#1-loop-and-pacing-pace)
2. [Controls, feel and camera](#2-controls-feel-and-camera-feel)
3. [Teaching](#3-teaching-teach)
4. [Puzzles and interactions](#4-puzzles-and-interactions-puz)
5. [Spaces and doors](#5-spaces-and-doors-space)
6. [WOLF in play](#6-wolf-in-play-wolf)
7. [Failure and retry](#7-failure-and-retry-fail)
8. [Story in play](#8-story-in-play-story)
9. [Phone](#9-phone-phone)
10. [Sound](#10-sound-sound)
11. [Performance](#11-performance-perf)
12. [Accessibility](#12-accessibility-a11y)
13. [Checking with real players](#13-checking-with-real-players-test) (added: the playtesting research did not fit the other areas)
14. [Controller](#14-controller-ctrl) (round 2)
15. [Front end and session flow](#15-front-end-and-session-flow-menu) (round 2)
16. [Desktop display](#16-desktop-display-display) (round 2)
17. [Evidence case](#17-evidence-case-case) (round 2)
18. [Readable image](#18-readable-image-read) (round 2, topic 12)
19. [Credits and licences](#19-credits-and-licences-cred) (round 2)
20. [Localization](#20-localization-loc) (round 2)
- [Where this disagrees with design-reference-25-games.md](#where-this-disagrees-with-design-reference-25-gamesmd)
- [Gaps from the 25-games study: ledger](#gaps-from-the-25-games-study-ledger)
- [Against the recorded decisions](#against-the-recorded-decisions)
- [Questions for Nathanial](#questions-for-nathanial)

---

## 1. Loop and pacing (PACE)

### PACE-1 · MUST · Something new every 5-10 s of movement, triggered by position
- **Why:** Half-Life placed content by distance, not by clock, so a moving player finds that "within a few seconds something will happen"; Halo's innermost loop is 3 s; pace holds while threat, tension or movement impetus is high [LOOP-PACING-1] [LOOP-PACING-12] [LOOP-PACING-18]. A beat can be a readable story vignette, not only an interaction [LEVEL-ARCHITECTURE-1] [LEVEL-ARCHITECTURE-24].
- **Target:** at most ~10 s of player movement without a new sound, light change, WOLF glance or reveal. One 711 px view takes ~4.0 s held under walk-then-jog and ~8.9 s if the player keeps tapping at walk speed (derived). An authored quiet tension stretch counts as a beat.
- **Now:** UNKNOWN for movement (rooms are one 960 px width and nobody has stopwatch-played them). NOT MET for standing and reading: ~38 s of a near-still opening (D-0004 to D-0047) and ~16 s standing at the Records exit (D-0148 to D-0164).
- **Fix:** keep beats tied to x positions; when rooms widen to 1.5-2 views, give each view-width a beat; time every beat with a stopwatch in play (TEST-5).

### PACE-2 · MUST · After every threat peak, change the mode
- **Why:** constant combat fatigues and long inactivity bores; Valve fixed fatigue six times with a change of mode [LOOP-PACING-2] [LOOP-PACING-3] [LOOP-PACING-11a] [LOOP-PACING-11b]; Portal did it the other way round, with simple timed tasks between slow puzzles [LOOP-PACING-17].
- **Target:** a peak is held ~3-5 s, then threat stays minimal for ~30-45 s or until the next safe point (Left 4 Dead's measured cycle) [FAILURE-DIFFICULTY-5]. Nothing intense follows the Blowback junction before a quiet beat.
- **Now:** PARTLY. The junction ends with the closing line and the END OF SLICE card (D-0253 to D-0264); there is no quiet shared moment, and WOLF disappears before it (M-0219 to M-0220).
- **Fix:** after the bolt, give the pair a short quiet beat (the walk-out in PACE-9), then the card.

### PACE-3 · MUST · Protect the first 10 minutes from dead time
- **Why:** Steam funnels for acclaimed linear narrative games lose ~42-62% of starters, with the steepest drops in the first chapter or two [LOOP-PACING-10a] [LOOP-PACING-10b] [LOOP-PACING-10c] [LOOP-PACING-10d] [FAILURE-DIFFICULTY-11]; pacing means "no dead points or frustration points" [LOOP-PACING-13a]; Meier: "You almost cannot reward the player enough" in the first 15 minutes [FAILURE-DIFFICULTY-10].
- **Target:** no stretch over ~10 s where the player can neither move nor make a choice, except the opening (TEACH-1). Zero obscure deaths in the first 5 minutes (TEACH-3).
- **Now:** NOT MET. Opening: first control at 40.9 s (both logs). Records exit: ~16 s of standing while lines play (D-0148 to D-0164). All three reviewers named the opening as a quit risk.
- **Fix:** TEACH-1 for the opening; STORY-8 (walk-and-talk) for Records.

### PACE-4 · MUST · No padding and no dead backtracking; thresholds you pass through
- **Why:** limiting backtracking "gives them confidence to venture forward" [LOOP-PACING-11a]; Valve added a gunship to a forced second trip [LOOP-PACING-3]; Little Nightmares "got in and got out" [LOOP-PACING-8]; Apple: restore state so people never retrace steps [LOOP-PACING-15b].
- **Target:** 0 forced returns without new content; every opened threshold is walked through and seals the way back visibly.
- **Now:** PARTLY. The route is linear left to right (MET), but the opened doors are walked past, not through (D-0105, D-0205; see SPACE-1), and Records is entered from the safe-point console (D-0106).
- **Fix:** SPACE-1.

### PACE-5 · MUST · Measure pacing by playing it, before painting
- **Why:** Uncharted 2's sluggish monastery showed up only after final art; one tester repeated a fight 27 times [LOOP-PACING-4a]; Druckmann would iterate levels "many more times" before final art [LOOP-PACING-4c]; Valve watched a player every week [LOOP-PACING-3] and ran 200+ playtests [LOOP-PACING-1].
- **Target:** every beat timed with a stopwatch on desktop and phone; flag any beat where a fresh tester retries more than 3 times or is stuck more than 2 minutes (derived).
- **Now:** NOT MET. No hands-on play of the complete slice has happened (docs/next-session.md: "One next task ... the first hands-on play session").
- **Fix:** run TEST-1 to TEST-7 now; grey-box new rooms and phone-test them before paint (already decided).

### PACE-6 · SHOULD · One idea per room, in four steps
- **Why:** Nintendo's kishoutenketsu (learn, develop, twist, show mastery) [LOOP-PACING-6] [PUZZLES-11]; Halo's 3-minute loop "is always different" [LOOP-PACING-12]; a puzzle "preps the mindset" for a harder use later [LOOP-PACING-9].
- **Target:** each room ~1-3 min; no room repeats the previous room's mode.
- **Now:** PARTLY. Corridor (breaker, relay, bypass, seal) and junction (overload, crank, blast, drop, bolt) follow the arc; Records repeats the corridor's walk-USE-choose mode. Scripted times: corridor ~38-53 s, Records ~44-45 s, junction ~43-66 s (logs; the desktop junction includes Pause and two knockdowns).
- **Fix:** keep the arc; give Records a different texture (a short timed copy, or a quiet WOLF moment) when it is rebuilt.

### PACE-7 · SHOULD · A slow, quiet approach before a new threat type
- **Why:** Valve slowed the Ravenholm entry because players were "dropped into combat ... without any room for tension building" [LOOP-PACING-3]; Chahi placed threats "a little bit like a music score" [LOOP-PACING-5]; high tension itself slows players [LOOP-PACING-18].
- **Target:** before the sentry acts, a few seconds of sound and light (whir, lamp) and WOLF's posture change, with no threat yet. No measured duration exists; tune by play.
- **Now:** NOT MET. The sentry "whirs awake" in the same line as the door blast (main.gd:136 `RUBBLE_LINE`) and wakes after 0.5 s (main.gd:203 `SENTRY_WAKE_SECONDS`).
- **Fix:** split the blast aftermath from the sentry reveal: dust settles, WOLF's ears go up, a sound off-screen right, then the sentry rolls into view.

### PACE-8 · SHOULD · Warmth and reprieve on the main path
- **Why:** quiet moments keep a story from feeling "relentless" (Druckmann, secondary; wording UNVERIFIED) [LOOP-PACING-13d]; "bars of rest after bars of fury" [LOOP-PACING-13c]; Valve's "vistas" [LOOP-PACING-11a]; playtesters all wanted Uncharted's peaceful elephant ride [LOOP-PACING-13e].
- **Target:** at least one non-optional, non-threat WOLF moment per room (derived).
- **Now:** NOT MET. The slice has strong WOLF lines but no shared quiet moment; the decided "WOLF moment" at safe points is not built.
- **Fix:** build the safe-point WOLF moment (decided October 10) and the walk-out (PACE-9).

### PACE-9 · SHOULD · End the slice as a sequence, not a cut
- **Why:** finale staging kept Alyx "mostly silent" so players watched the event [LOOP-PACING-11a]; a short goal-restating scene "feels like a small reward" [LOOP-PACING-11b]; cinematics "give emphasis to a major event" (Chahi) [LOOP-PACING-5].
- **Target:** set-piece peak, short release, a quiet image where WOLF is silent and the world speaks, then the END OF SLICE recap. Seconds, not minutes.
- **Now:** NOT MET. USE "leave through the hatch" fires while the engineer is still at the bolt console (M-0208); WOLF is hidden in place, not walked off (M-0219 to M-0220, log); the card fades in before anyone reaches the hatch (M-0221, D-0263 to D-0264). The code intends a fade in the doorway (main.gd:98-106) but it reads as vanishing.
- **Fix:** WOLF walks through the open hatch and out of sight; the engineer follows; a 1-2 s hold on the empty, quiet junction; then the card.

### PACE-10 · SHOULD · Wide rooms look open but run in one reliable order
- **Why:** Valve keeps "a fairly reliable progression of events, so that we can fine tune pacing" [LOOP-PACING-11b]; Asobo found opening up spaces cost narrative rhythm [LOOP-PACING-14a]; "choice requires thought and thought slows movement impetus" [LOOP-PACING-18].
- **Target:** each 1.5-2-view room has one main order of beats, even when it shows two routes.
- **Now:** MET for today's one-view rooms; watch it during the room expansion.
- **Fix:** write the beat order into each room brief (SPACE-6).

### PACE-11 · COULD · A stopwatch mix target per slice
- **Why:** Naughty Dog planned Uncharted 2 as "60% action, 40% adventure" [LOOP-PACING-13b].
- **Target:** about 40% tension or action to 60% exploration, puzzle and story (derived; validate by play).
- **Now:** UNKNOWN.
- **Fix:** log time per mode in the playtest observer sheet (TEST-5).

### PACE-12 · COULD · A light intensity state for the sentry
- **Why:** Left 4 Dead raises intensity on damage, then forces a relax window; set pieces sit outside it [LOOP-PACING-2] [FAILURE-DIFFICULTY-5].
- **Target:** after a sighting or knockdown, ~30-45 s of reduced sentry pressure; the tank drop stays authored.
- **Now:** NOT MET (no intensity state in sentry_brain.gd).
- **Fix:** later, only if playtests show repeated sentry deaths.

### PACE-13 · COULD · Once per chapter, lull and then startle, readably
- **Why:** "We like to lull players into a trance, then startle them"; clues before an ambush "create a sense of growing apprehension" [LOOP-PACING-11b].
- **Target:** one per chapter (derived).
- **Now:** NOT MET (the slice has no chapters yet).
- **Fix:** plan it when chapters are scripted.

---

## 2. Controls, feel and camera (FEEL)

### FEEL-1 · MUST · Every input answers within ~100 ms
- **Why:** real-time control needs the computer's half of the loop under ~100 ms (Swink via England) [CONTROLS-FEEL-8]; 0.1 s feels instant [CONTROLS-FEEL-27] [COMPANION-PLAY-40]; shipped 60 fps games measured 50-67 ms of game-side latency [CONTROLS-FEEL-9] [CONTROLS-FEEL-10]; phones add 35-140 ms of touch and display latency [CONTROLS-FEEL-31] [CONTROLS-FEEL-24].
- **Target:** a visible or audible first response to MOVE, USE, a hold and any request to WOLF within ~100 ms end to end; the game's own share 4 frames (67 ms) or less at 60 fps.
- **Now:** PARTLY. Movement sets velocity on the press frame (m0_actor.gd:67). The crank shows no wheel motion until the first 0.4 s tick (hold_use.gd:8). Never measured.
- **Fix:** first-frame response for holds (FEEL-4); measure press-to-pixel (PERF-4).

### FEEL-2 · MUST · Response wins over animation
- **Why:** Playdead: the player "should always be in direct control", the button is pressed "NOW", the boy runs in place while code moves him [CONTROLS-FEEL-14]; a velocity impulse placed mid-animation "might look better, but it feels bad" [CONTROLS-FEEL-10] [CONTROLS-FEEL-29].
- **Target:** code owns position; painted cycles play in place at playback rate = speed ÷ stride; foot slide 0; USE takes effect on the press frame with the reach as an overlay; input locks only for knockdowns and blasts.
- **Now:** PARTLY. Code owns position (m0_actor.gd:62-95). There is no walk cycle in code yet: each character is one still sprite, and every still shows the same pose (genre fan, phone review). The approved painted cycles (October 11) are not wired.
- **Fix:** wire the approved cycles with rate locked to speed; never gate the first response on an animation event.

### FEEL-3 · MUST · Walk 80 / jog 190 with short ramps, not an instant snap
- **Why:** Celeste reaches full run and stops in 0.09 s [CONTROLS-FEEL-4]; Prince of Persia's committed 6-13-frame moves read as lag unless the level is built for them [CONTROLS-FEEL-21] [CONTROLS-FEEL-22]; Mario "sped up gradually" [CONTROLS-FEEL-6]; INSIDE blends walk and run for its jog [CONTROLS-FEEL-14].
- **Target (derived):** reach walk and stop from walk in ~0.1-0.15 s; after ~0.5 s held, ramp to jog over ~0.2-0.3 s; reverse within ~0.1-0.2 s; a turn clip plays over the reversal and never gates it.
- **Now:** NOT MET. One speed, 0 to 190 px/s instantly (m0_actor.gd:31, :67). Walk-then-jog was decided on October 11.
- **Fix:** add walk/jog speeds and acceleration curves; check the curves headless and the feel by hand.

### FEEL-4 · MUST · Holds respond at once, stay short, and can be toggled
- **Why:** XAG 107's own example of an exclusionary mechanic is a 3 s hold to open a door, and it flags holds of "2-3 seconds or more" [CONTROLS-FEEL-25] [FAILURE-DIFFICULTY-8]; avoid or offer alternatives to held buttons [CONTROLS-FEEL-28] [FAILURE-DIFFICULTY-19]; TLOU2 turns every hold into a toggle [PUZZLES-5] [FAILURE-DIFFICULTY-29]; progress feedback keeps flow [CONTROLS-FEEL-27].
- **Target:** the wheel moves and a ratchet clicks on the press frame; default holds ≤ ~2 s (the safe-point secure hold ≤ 1.5 s); a hold-to-toggle option; completed ticks survive a release; no mashing.
- **Now:** PARTLY. Ticks survive a release (MET, hold_use.gd). The MANUAL BYPASS needs 8 × 0.4 s = 3.2 s (bypass_handle.gd:11, hold_use.gd:8), above XAG's line; first motion at ~0.4 s; Settings has no toggle (game_settings.gd).
- **Fix:** animate partial progress from the first frame; add the toggle; keep the bypass's cost in the alarm and hiss, not the hold length (see Q1).

### FEEL-5 · MUST · Hands meet the thing they use
- **Why:** every attempt "must be rewarded with an animation" [CONTROLS-FEEL-14]; art, sound and animation must communicate the puzzle logic [PUZZLES-8]. The earlier study's target "visible contact before effect" covered only WOLF; the frames show the engineer needs it too.
- **Target:** at every station the engineer's pose reaches the control (hand on the wheel, lever, panel) for 100% of uses.
- **Now:** NOT MET. The engineer stands beside the bypass and the valve with arms down while cranking (D-0095, M-0164, M-0167).
- **Fix:** a reach/crank pose per station type (wheel, lever, panel), overlaid on the press frame (FEEL-2).

### FEEL-6 · SHOULD · Camera dead zone and look-ahead
- **Why:** a camera window moves only when the player pushes its edge [CONTROLS-FEEL-1] [CONTROLS-FEEL-2]; Godot smoothing at 4.0 trails a 190 px/s walker by ~44 px [CONTROLS-FEEL-13] [CONTROLS-FEEL-12].
- **Target (derived):** window ~±36 px (drag margin ~0.1); forward focus 0 px at rest, ~60-90 px at jog, eased; ~0.3 s hysteresis before the focus changes sides; fixed zoom during free movement; 26-29 px crank auto-steps never move the camera.
- **Now:** NOT MET. Pure centring with smoothing 4.0 (main.gd:756-757); no drag margins or look-ahead.
- **Fix:** add the window and look-ahead; validate on desktop and phone by hand.

### FEEL-7 · SHOULD · Point the frame at what matters, without taking control
- **Why:** attractors and region focus give "preset framing with solid perceived control" [CONTROLS-FEEL-1].
- **Target:** bias the frame toward the alerted sentry, a scouting WOLF and a door as it opens; never during a hold.
- **Now:** NOT MET (the camera follows the engineer only).
- **Fix:** small authored camera targets at those beats.

### FEEL-8 · SHOULD · Forgive the player's intent at interactions
- **Why:** Celeste fudges "everything ... a tiny bit in the player's favor": 0.1 s coyote time, 4 px corner correction [CONTROLS-FEEL-3] [CONTROLS-FEEL-4] [FAILURE-DIFFICULTY-18] [FAILURE-DIFFICULTY-20]; Braid caches a press for 0.23 s [CONTROLS-FEEL-7].
- **Target:** USE buffered ~0.1 s before entering range or while a line finishes; USE accepted ~0.1 s after leaving range; generous ranges; auto-step to crank spots kept.
- **Now:** PARTLY. Ranges of 30-58 px and auto-steps exist (main.gd:21, :24, :158-178); no input buffer found in code.
- **Fix:** add a short USE buffer and grace window.

### FEEL-9 · SHOULD · Keep the impact kit restrained
- **Why:** Playdead's mentors said "Turn it down 90%" and the deck turns it up "once" [CONTROLS-FEEL-16]; Nuclear Throne's freeze is 10-20 ms per hit [CONTROLS-FEEL-18]; the trauma shake model [CONTROLS-FEEL-19] [CONTROLS-FEEL-20].
- **Target:** full-strength shake (10 world px ≈ 13.5 screen px) and hit-stops (0.06-0.09 s) only on knockdown, blast and tank drop; everything else turned down; toggles kept.
- **Now:** PARTLY. Values are in impact.gd:9-16 and used on the big beats; Reduced Motion exists (game_settings.gd:212); the effects themselves read as blobs (SPACE-9).
- **Fix:** keep the values; redo the effect art (SPACE-9).

### FEEL-10 · COULD · An additive look-at and breathing layer for the engineer
- **Why:** INSIDE's look-around system and audio-driven breathing give "a huge amount of life" with no input latency [CONTROLS-FEEL-14] [AUDIO-FEEL-8].
- **Target:** head and upper spine turn toward WOLF, the sentry or a live panel; breathing over the walk and crank cycles.
- **Now:** NOT MET (decided as a real-feel item, not built).
- **Fix:** after the walk cycles land.

---

## 3. Teaching (TEACH)

### TEACH-1 · MUST · Control fast; the opening stays short, skippable and player-paced
- **Why:** Valve split Episode One's opening into three scenes because even after "heroic pruning" it "still felt too long" [ONBOARDING-30]; Apple: people should understand a game "simply by experiencing it" and "Teach through play" [ONBOARDING-15] [ONBOARDING-16]; Portal's player moves from second 0 [ONBOARDING-7].
- **Target:** first movement input ≤ 60 s from NEW GAME (aim 30-45 s; a proposal, no source gives a number); show the engineer in the opening; put extra story after first control.
- **Now:** PARTLY. 7 beats (~93-96 words), player-paced, first control at 40.9 s with the capture's reading formula (main.gd:90-98; D-0004 to D-0047). The engineer does not appear until D-0048. All three reviewers named it the first quit risk; the genre fan would want ~10 s (his judgement, unsourced). Pause during the opening already offers SKIP OPENING, which lands on the first controllable frame (F-0030 → F-0261, main.gd:1360), but nothing tells a first-time player it exists. PROJECT_CONTEXT.md already asks that WOLF's self-awakening be "legible from the engineer's viewpoint"; today's opening has the Director and WOLF on screen and no engineer.
- **Fix:** Nathanial decides (Q2, which lists each option's cost against design C's standby dock). Meanwhile, show "PAUSE: skip the opening" on the opening's first box. **Check:** a headless timing test from NEW GAME to the first `move_*` input using the capture's reading formula (1.2 s + 0.05 s per character, ≤ 7 s), plus render.sh stills of the first controllable frame (PLAN P0-13).

### TEACH-2 · MUST · One new verb per beat; use it ~3 times before combining
- **Why:** Nintendo introduces elements "one by one" and says "Use one element three times" [ONBOARDING-3] [ONBOARDING-5]; Valve's show, confirm, challenge [ONBOARDING-11]; Portal added two chambers before one overloaded puzzle [ONBOARDING-6] [LOOP-PACING-17]; build the endpoint first, then the beats that teach it [LOOP-PACING-3]; Episode Two's crank-and-gear puzzle had to be simplified [LOOP-PACING-11b] [PUZZLES-31].
- **Target:** 0 verbs met for the first time in combination. The junction's verbs (overload, crank, blast, drop, dump) each have a safe solo use first; the vent hazard and the timing act are never first taught at the same station.
- **Now:** PARTLY. The corridor teaches move, USE and choice. Hold-to-crank is taught only on the engineer-only route: on the WOLF route the corridor crank is never used (phone route M), so the junction valve is the first crank. The relief vent is first met as a hint while walking past (D-0179). The tank drop is first used for real.
- **Fix:** teach the hold on every route before the junction (the decided safe-point secure hold does this); show the vent venting on nothing first; show one safe, slow drop or swing of the tank before it must be timed.

### TEACH-3 · MUST · No unreadable or precision deaths in the first ~5 minutes
- **Why:** Episode Two's testers fell "numerous times in the first five minutes", so Valve "optimized for perceived rather than actual danger" [ONBOARDING-12] [LOOP-PACING-11b]; Nintendo allows an early loss only when the cause is plain [ONBOARDING-1]; Limbo shows early deaths work only when cheap and readable [ONBOARDING-41]; good deaths and bad deaths (Halo 3) [FAILURE-DIFFICULTY-28].
- **Target:** first failures non-lethal and readable; 0 failures a fresh player cannot explain afterwards.
- **Now:** PARTLY. The corridor has no hazard (MET). The first knockdown comes at ~145 s and is explained (D-0186), but the 1.0 s fuse (pressure_line.gd:10) leaves a newcomer reading when it goes (FAIL-5).
- **Fix:** FAIL-5.

### TEACH-4 · MUST · Objective and controls reviewable any time; key lines re-readable
- **Why:** players should "review tasks and objectives at any given time", and a static controls screen is not a tutorial (XAG 109) [ONBOARDING-18]; replayable narrative [ONBOARDING-19]; character beats beat a pause-menu reminder as the main reminder [ONBOARDING-10]; "The game kept track of goals" separated high- from low-ranked games [PLAYTESTING-HUMAN-24].
- **Target:** current objective and controls on the pause screen; an in-world reminder (WOLF or a station) as the first layer; a log of the last 20 lines on the pause screen (derived; STORY-6 uses the same log). **Check:** headless test that the pause screen shows the current objective and that the log holds the last 20 shown lines in order.
- **Now:** PARTLY. The objective card shows for 3.4 s at each change (main.gd:3203) and the Controls tab exists (D-0176); the pause screen has no objective (D-0177) and there is no line log.
- **Fix:** add the objective and a recent-lines log to the pause screen.

### TEACH-5 · MUST · Name only what the player can see
- **Why:** goals must be clear [PUZZLES-2]; shorten by "compacting phrases" without losing information [NARRATIVE-IN-PLAY-35]; ask testers to tell the story back [PLAYTESTING-HUMAN-11] [ONBOARDING-7].
- **Target:** every noun in a hint or a knockdown card points at something drawn and recognisable on screen; one word per thing; at most one new proper noun per beat (derived).
- **Now:** NOT MET. "The alcove's right post", "Keep inside the posts", "get back over the rubble" (junction_room.gd:213; D-0222, D-0226) name things that read as a faint cyan floor rectangle and a few shards. "Mark", "brackets" and "floor mark" name one thing (D-0240). The newcomer counted 40+ named things in ~3 minutes; "first copy", "the source" and "Archive" never became concrete (D-0120, D-0148, M-0121). State words "SPENT" and "BOLTED" are jargon (D-0243).
- **Fix:** build the alcove as a real recess with two physical uprights, or reword to point at what is drawn; one term per object; plain state words (new lines need Nathanial's approval).

### TEACH-6 · SHOULD · Fade prompts as the player learns
- **Why:** in a 45,000-player study, tutorials did little in simple, conventional games [ONBOARDING-13]; Valve's shipped lessons mostly retire after 1 success (Half-Life: Alyx 43 of 58) [ONBOARDING-39] [ONBOARDING-40]; Portal's voice explained only the hardest concept [ONBOARDING-6].
- **Target:** full text for the first 1-2 uses, then a glyph, then nothing; walk and USE retire after 1 success, hold-to-crank after 2-3; instruction is spent on the tank timing.
- **Now:** NOT MET. Hints never fade ("E: arm the breaker." every time); "Checkpoint saved." appears 17 times in the hint bar (genre-fan log count; main.gd:85), training players to ignore it.
- **Fix:** per-verb success counters; show "Checkpoint saved." as a small icon, not hint text.

### TEACH-7 · SHOULD · One thing to read at a time, and never during a chase
- **Why:** attention is a spotlight; a fighting Fortnite player did "not even look at" a message; 3 items is "THE MAXIMUM when in learning mode" (Hodent's rule of thumb) [PLAYTESTING-HUMAN-12] [PLAYTESTING-HUMAN-13] [PLAYTESTING-HUMAN-14].
- **Target:** on the first controllable frame, at most one text element plus one prompt; no essential line while the sentry chases or the fuse burns.
- **Now:** NOT MET. D-0048 shows a name card, a tutorial box, a hint, a 3-line 267-character dialogue box, PAUSE and three world labels; on the phone the hint also runs under USE (M-0047, M-0052). The tutorial reads "TAP USE READ DISPLAY (optional)" (M-0052).
- **Fix:** stagger them: name card, then move, then dialogue; tutorial after the first step; fix the tutorial wording.

### TEACH-8 · SHOULD · First meaningful choice in the first ~2 minutes, with information
- **Why:** first-hour engagement needs "intrigue and information" as well as fun [ONBOARDING-14]; Steam refunds under 2 hours [ONBOARDING-34].
- **Target:** first choice within ~2 min; the player knows who they are and why they help WOLF before it.
- **Now:** PARTLY. The relay choice comes at 52.6 s (D-0062, MET), but the engineer first appears at D-0048 and option 2 hides what it means (STORY-5).
- **Fix:** TEACH-1 and STORY-5.

### TEACH-9 · SHOULD · Teach with staging and gates, not text
- **Why:** Portal's "gate" is a mandatory pause with motion and a loud noise [ONBOARDING-6] [PUZZLES-32]; Valve introduced threats "at a safe distance" [ONBOARDING-10]; staged examples teach sawblades and grubs [ONBOARDING-12]; a forced window exit taught window escapes [PUZZLES-31].
- **Target:** one forced look per room at the key change (the seal opening, WOLF taking the contact), marked by motion and sound.
- **Now:** PARTLY. The seal opening is a texture swap behind a dust blob (D-0101 to D-0102); WOLF's surge is a decal (M-0084).
- **Fix:** SPACE-2 and WOLF-9.

### TEACH-10 · SHOULD · In the first rooms, moving right means progress
- **Why:** "move to the right" gives "a sense of relief" (Nintendo) [ONBOARDING-4]; a tester turned the wrong way for half an hour [ONBOARDING-12].
- **Target:** every first-room route runs left to right.
- **Now:** MET in all three rooms (D-0048 to D-0263). In the opening WOLF "heads for maintenance" by walking left into his open cage (D-0041 to D-0046).
- **Fix:** have WOLF leave the opening to the right or through a visible exit.

---

## 4. Puzzles and interactions (PUZ)

### PUZ-1 · MUST · Show the problem before the tool, and make the obstacle a real obstacle
- **Why:** a clear end goal and "the crevice should be found before the rope" (Gilbert) [PUZZLES-2] [PUZZLES-12]; "figuring out ... how to do it", not what [PUZZLES-9]; Valve shrank a level so players saw the problem before the fight [PUZZLES-30] [LOOP-PACING-11a]; four steps with a twist [PUZZLES-11].
- **Target:** the sealed door, the overloaded line and the sentry lane are seen as blocking the way before the valve, tank or bolt matters.
- **Now:** PARTLY. The junction shows all its parts at entry (D-0165), but the sealed door does not block the route on screen: after the blast the path goes sideways past it (D-0205), so "why blow it" has no visual answer. In Records the goal never becomes concrete (TEACH-5).
- **Fix:** put the blast door across the walking line (SPACE-1).
- **Check:** a pass/fail item on the TEST-5 observer sheet: before touching the valve, a fresh tester can point to what blocks the way (pass) or cannot (fail); target ≥ 5 of 6 testers (derived).

### PUZ-2 · MUST · At most 3-4 live interactables per view, and only the next one lit
- **Why:** working memory holds "about four chunks" [PUZZLES-29]; a good puzzle has "almost no extraneous elements" [PUZZLES-9]; Limbo moved a trap away because players fixated on it [PUZZLES-20].
- **Target (derived):** 3-4 live interactables per view, 1-2 relevant to the current step; lamps lit only on the next node; no decoy beside the real problem.
- **Now:** NOT MET. All 6-7 junction USE points (breaker x 200 to hatch x 880) fit one ~711 px view, all labelled at once (D-0165).
- **Fix:** light only the current node; dim spent and not-yet nodes (with PUZ-3).

### PUZ-3 · MUST · Show what is usable in layers, cheapest first; names live on the equipment
- **Why:** players should know "instantly that it was a puzzle" [PUZZLES-3]; consistent world rules over paint [PUZZLES-4]; Portal's warm key light and shadows point at the box [PUZZLES-32]; powered lines change colour [PUZZLES-9]; a ceiling wire guided players [PUZZLES-30]; sound cues [PUZZLES-20]; high contrast for interactive objects [PUZZLES-5] [PUZZLES-18] [PUZZLES-19]; real equipment carries mounted plates [LEVEL-ARCHITECTURE-10].
- **Target:** (1) diegetic state (lamp, hum, needle), (2) light or conduit leading to the live object, (3) WOLF looks at it, (4) a world-anchored prompt only in USE range, (5) optional high-contrast mode. Prompt contrast ≥ 4.5:1; high-contrast mode 7:1.
- **Now:** PARTLY. Floating labels hang over every machine in every room and change to state words (D-0062, D-0165, D-0186, D-0243). The genre fan reads them as a debug overlay; the newcomer found them helpful ("I always knew what to walk to", D-0080). The in-range hint bar exists.
- **Fix:** mounted name plates on equipment plus the in-range prompt, objective on the pause screen; a "station labels" option for players who want them (Q4).

### PUZ-4 · MUST · Every wrong attempt says no, never, and why
- **Why:** each wrong attempt must show "that the solution did not work, that it never will work ... and why" (Carlsen) [PUZZLES-7]; players take "a long time" to return to an idea they discarded [PUZZLES-20]; a clearly impossible route reads wrong at once [PUZZLES-9]; reactions within the first-response budget [CONTROLS-FEEL-14] [CONTROLS-FEEL-27].
- **Target:** every invalid USE (sealed door, spent panel, valve before breaker, DROP too early) gets a short reaction in light and sound plus a hint, starting within ~100 ms.
- **Now:** PARTLY, measured (headless probes, routes D/M/X/C, round-2 capture): every invalid press gets a **text** reaction within 1 frame, but **none makes a sound** and none changes a light. Valve before the breaker: "The valve is dead. Arm the overload breaker by the entrance first." (X-0155). Breaker while the line builds: "The line is live. Crank the valve...". Spent valve: "The valve is spent. The door is down.". DROP too early: "Wait. WOLF hasn't got it on the mark yet." (X-0334). Spent release: "The tank is down on the sentry...". **USE at the sealed door gives no reaction of its own:** the valve's reach covers it and repeats the same line, so the second press changes nothing on screen; walking into the sealed door for 40 s produced no bump, sound or line (X-0160 to X-0179).
- **Fix:** give each station × invalid state a light flicker and a short refusal sound (a dull clunk) on the press frame, plus its line; give the sealed door its own line ("Sealed. The valve opens it.") and a bump when walked into; re-show a line on a repeated press. **Check:** headless table of every station × state with the frame of the first sound, light and text change (≤ 6 frames; PLAN P0-15).

### PUZ-5 · MUST · Never require a death to learn a step
- **Why:** "It is bad design ... to require a player to die in order to learn what not to do" (Gilbert) [PUZZLES-2]; Limbo is "learning-by-dying" but has no evidence to lose [PUZZLES-20]; difficulty spikes need a sanity check [PUZZLES-39]; introduce hazards where they only knock down first [FAILURE-DIFFICULTY-32] [FAILURE-DIFFICULTY-28].
- **Target:** every lethal hazard is first shown working on something else, or from safety; retries logged per node in test builds.
- **Now:** PARTLY. WOLF warns about the door and the zone is striped (D-0167, D-0185). The sentry's reach ("the posts") is first learned by being caught (D-0226; a planned mistake in the capture).
- **Fix:** show the sentry running something down from cover (a maintenance drone, a crate) before the lane opens to the engineer.

### PUZ-6 · MUST · Timing puzzles repeat and are easy to execute
- **Why:** Braid's one-moment puzzle "felt more like a trick than a revelation" [PUZZLES-9]; "the correct solution is fairly easy to execute" [PUZZLES-20]; tune set pieces until players "consistently" scramble through "at the last moment" [LOOP-PACING-11b]; a ticking sound cued timed action [LOOP-PACING-17].
- **Target:** the sentry crosses the mark on every pass (it does); the drop window is tuned on desktop and phone until fresh players hit it within ~2-3 tries; a tick or alarm says "now".
- **Now:** PARTLY. Repeating window MET (main.gd:143). The window is about 0.34 s against the 140 px/s patrol and 0.21 s against the 230 px/s chase (2 × `HIT_RANGE` 24 ÷ speed; drop_arm.gd:16, :20; sentry_brain.gd:33-34; derived). The 25-games study's 0.63/0.38 s figures are stale.
- **Fix:** widen the hit range or slow the sentry over the mark; count a graze as a hit (Q7); tune on a phone.

### PUZ-7 · MUST · Station states match the world
- **Why:** tie feedback to real state changes (AGENT.md); signifiers must be reliable [PUZZLES-1].
- **Target:** every state tag clears or changes the moment its cause is resolved.
- **Now:** NOT MET. "COOLANT FAULT" stays after WOLF takes the surge or the bypass locks over (D-0106, M-0089; bypass_handle.gd:101).
- **Fix:** clear the tag when the relay is handled.

### PUZ-8 · SHOULD · A tiered, state-aware WOLF hint ladder
- **Why:** it was "much more satisfying" when Alyx "stated a goal and then stepped aside" [PUZZLES-30]; God of War Ragnarök's first hint was "too aggressive" [PUZZLES-6] [PUZZLES-24] [PUZZLES-25]; Return to Monkey Island's hint book "knows where you are" [PUZZLES-13]; a narrator is "a natural way to deliver hints" [PUZZLES-22].
- **Target (derived):** T0 on entry, the goal only; T1 at ~45-60 s without progress on the current node, WOLF looks at it and its sound pulses; T2 at ~90-120 s, one short line naming the object; T3 at ~180 s or on request, an explicit line. No timer during chases or choices.
- **Now:** NOT MET. The junction entry states the whole chain at once, in Rowan's voice: "Overload it, crank the valve, and the door goes." (main.gd:220).
- **Fix:** build the ladder; decide whether the entry line states the goal only (Q6).

### PUZ-9 · SHOULD · No always-visible hint button; hint options in the pause menu
- **Why:** a help button cut levels completed by 12% in a simple puzzle game, though it helped in a complex one [PUZZLES-42]; all four hint designs lowered performance in a 50,000-player study [PUZZLES-26]; Santa Monica added Reduced Puzzle Hints [PUZZLES-24] [PUZZLES-44]; TLOU2 ships Skip Puzzle [PUZZLES-5]; 9.5 million Uncharted 4 players used an accessibility option [PUZZLES-27].
- **Target:** hint frequency Normal / Fewer / Off and "Skip this step" in the pause menu; hints never depend on WOLF's trust.
- **Now:** NOT MET (no hint options).
- **Fix:** with A11Y-1.

### PUZ-10 · SHOULD · Real maintenance logic, planned with a dependency chart
- **Why:** real-world problems can be more fun than arbitrary puzzles (an open-ended-games argument, so loose support) [PUZZLES-10]; design backwards from goals and chart the dependencies [PUZZLES-12] [PUZZLES-2].
- **Target:** one dependency chart per room; each node has its own signifier and feedback.
- **Now:** PARTLY. The junction is isolate, overload, crank, blast; no chart is written down.
- **Fix:** add a chart to each room brief (SPACE-6).

### PUZ-11 · SHOULD · Keep story-game puzzles easy; put hard variants in optional detours
- **Why:** Brothers' early puzzles "were too hard" for its pace [PUZZLES-40]; Valve "kept simplifying" a crank puzzle [PUZZLES-31].
- **Target:** main-path puzzles solved by most fresh testers without help (TEST).
- **Now:** MET by design; unverified by testers.
- **Fix:** keep it; check in TEST rounds.

---

## 5. Spaces and doors (SPACE)

### SPACE-1 · MUST · Doors sit in walls, lead somewhere real, and are walked through
- **Why:** England's door questions: can every door open, how does the player know, where does it go [LEVEL-ARCHITECTURE-6]; players "automatically know if there is something off" [LEVEL-ARCHITECTURE-25]; anything that looks like an exit and is not must say so [LEVEL-ARCHITECTURE-12]. Decided October 11: doors are a wide steel shutter across the corridor in a heavy portal, with walk-through bulkhead doorways.
- **Target:** every door is set in a wall or bulkhead running floor to ceiling, crosses the walking line, and the player walks through every door they open; nothing behind a door is a painted tunnel into the screen.
- **Now:** NOT MET. The corridor seal and the junction sealed door are free-standing three-quarter frames that open into the screen while the path goes sideways past them (D-0102, D-0105, D-0200, D-0205, M-0086, M-0089, M-0188). Records is entered from the safe-point console, not a door (D-0106). The approved shutter design is on hold until redone under the REAL-LOOK rules.
- **Fix:** build the approved shutter across the corridor (one piece in the real game first), and the same rule for the junction blast door; the player walks through each.

### SPACE-2 · MUST · Doors show their state and move when they open
- **Why:** "What tells a player a door is locked and will open, as opposed to a door that they will never open?" [LEVEL-ARCHITECTURE-6]; block paths with things that fit the world [LEVEL-ARCHITECTURE-9]; "minimize disconnects" [LEVEL-ARCHITECTURE-2]. Decided: every door's lamp shows the lockdown by shape.
- **Target:** a status lamp on the latch side, visible bolts or leaf position, and an opening that moves (slide, swing, roll) over ~0.5-1 s; doors never vanish or turn into flat rectangles.
- **Now:** NOT MET. The seal leaf is swapped and hidden (main.gd:46-52, `seal_leaf.hide`; D-0101 to D-0102); the junction hatch panel disappears (D-0250 to D-0253, M-0208); the Records EXIT becomes a flat navy rectangle with a mint bar (D-0150, D-0157, M-0132, M-0142), the reviewers' "most fake-looking thing".
- **Fix:** animate each leaf into its pocket; give the Records exit real door art and a visible space beyond.

### SPACE-3 · MUST · Nothing floats
- **Why:** without a shadow or interreflection people judge contact at chance [PLAYTESTING-HUMAN-15] [PLAYTESTING-HUMAN-16] [LEVEL-ARCHITECTURE-29]; floating objects held the eye longer than any other scene error tested [PLAYTESTING-HUMAN-5] [PLAYTESTING-HUMAN-6]; "if there was a floor here, then there'd be a pillar somewhere to support it" (Miyamoto) [PUZZLES-46] [PLAYTESTING-HUMAN-26]; floating and unsupported objects are an AI-image tell [PLAYTESTING-HUMAN-7]. Decided October 11: every machine stands on a real base with a contact shadow or is wall-mounted with brackets and conduit.
- **Target:** 0 px between a floor object's base and its dark contact shadow; every wall object has a backplate, fixings and a service line; every hung object traces to structure; a knocked-down body lies on the floor line.
- **Now:** PARTLY. Actors and props get a soft radial shadow 12 px tall at ≤ 0.5 alpha (floor_reflection.gd:98-114; main.gd:512), which reviewers did not read as contact (D-0048, D-0095). Floating items in the frames: the MANUAL BYPASS wheel on a thin post tied by a hairline (D-0080, D-0095, M-0082); the purge console at head height on a column, which stands on the floor in Records (D-0048, M-0047, D-0116); a line hanging in mid-air across the junction (M-0188, M-0198, M-0202); the knocked-down body tipped 70° and hovering (main.gd:195-196; D-0186, D-0226, M-0169).
- **Fix:** mount the bypass on the relay with a real pipe; wall-mount the console with a bracket and conduit or give it a floor stand; run the cable along the floor or wall; drop the knocked-down body onto the floor line; darken and tighten contact shadows.

### SPACE-4 · MUST · Pipes and cables go somewhere, and say what they carry
- **Why:** real specs label pipes near valves, branches, wall penetrations and equipment, with service name and flow arrow [LEVEL-ARCHITECTURE-19]; rotary valves open counterclockwise with double-ended arrows [LEVEL-ARCHITECTURE-10].
- **Target:** every pipe starts and ends at something or leaves the frame; beat-relevant lines (the coolant line, the bolt feed) carry a stencil and flow arrow; labels at most every ~600 px (15 m) of run.
- **Now:** PARTLY. The junction's painted pipes are plausible; the bypass hairline and the release-to-bolt line in mid-air are not (D-0095, M-0188). The cable also runs through the dropped tank (D-0246).
- **Fix:** route both as real conduit; stencil the coolant line so the overload route reads before acting.

### SPACE-5 · MUST · A short facility brief before grey box or paint
- **Why:** Arkane knew "where everybody's sleeping quarters are, where they eat, where they work" [LEVEL-ARCHITECTURE-21]; Alien: Isolation built from 1:1 blueprints and a style guide [LEVEL-ARCHITECTURE-28]; "you do not break them!" [LEVEL-ARCHITECTURE-37]; Control rooted its building in real ones [LEVEL-ARCHITECTURE-39]; geography carries story [LEVEL-ARCHITECTURE-25].
- **Target:** one paragraph per room (what it does, who worked there, how they got in, which services run through, what changed at lockdown), anchored to a real facility type; every object traces back to it.
- **Now:** NOT MET (no briefs found; level-expansion.json lists rooms and sizes only).
- **Fix:** write briefs for corridor, Records and junction before their grey boxes.

### SPACE-6 · MUST · Room edges are physical
- **Why:** "Put a car or some rubble in the way!"; a chain-link fence for see-through blocks [LEVEL-ARCHITECTURE-9] [LEVEL-ARCHITECTURE-7].
- **Target:** each room's ends are a wall, shutter, rubble or fence; no invisible clamp.
- **Now:** PARTLY. Actors are clamped at x 40 and 920 (m0_actor.gd:53-54); the engineer enters Records from the bare left edge (D-0116).
- **Fix:** an entry door or hatch on each room's entry side; physical end caps.

### SPACE-7 · MUST · A "look real" pass at 100% zoom before every playtest round
- **Why:** floating and out-of-place objects did not draw the eye before they were looked at directly, so a quick screenshot pass misses them [PLAYTESTING-HUMAN-5]; AI-image tells include objects that cannot function and parts "cut out from different scenes" [PLAYTESTING-HUMAN-7]; if something can't be made natural, remove it [PLAYTESTING-HUMAN-26]. Decided October 11: design exact functional shapes first, paint second, then a reviewer hunts AI tells.
- **Target:** run the project's own checklists on the in-game capture: REAL-LOOK.md §3 (the 11-item AI-tell checklist: vanishing lines, one light logic, every part has a job, nothing floats with the base on y 440 within 1 px and a visible contact shadow, scale, doors, no painted text, greyscale values, wear logic, no repeats, the cage rule) and art-bible.md §3.7 (silhouette at 94 and 188 px, greyscale body L* ≥ 12 above the walk band, median contrast ≥ 1.6:1, 2 px blur). A piece passes when two reviewers each find zero open items (REAL-LOOK's rule). The figure-ground measurements are READ-1.
- **Now:** NOT MET as a routine. The reviewers found ~15 tells in one capture (AUDIT.md). The placeholder cage is the first object anyone sees (D-0004, D-0022; the decided standby dock, design C, is not built).
- **Fix:** add the checklist to every render.sh review; build the dock.

### SPACE-8 · MUST · Solid things stay solid
- **Why:** consistent world rules [LEVEL-ARCHITECTURE-37] [LEVEL-ARCHITECTURE-2]; characters passing through props read as layers, not space (reviews).
- **Target:** 0 frames where the sentry overlaps the engineer, a beam passes through a solid prop, or a cable passes through the tank; WOLF covered by WOLF-2.
- **Now:** NOT MET. The sentry rolls through the engineer's legs (D-0222); its beam runs through the bolt panel (D-0222); the cable runs through the tank and sentry (D-0246, D-0253).
- **Fix:** knockdown triggers at contact distance before overlap; occlude beams by solid props; reroute the cable.
- **Check:** a headless overlap test over every logged frame of routes D, M and X: sentry body span ∩ engineer span = ∅ while the engineer stands; beam segment ∩ prop spans (bolt panel, tank) = ∅; cable polyline ∩ tank footprint = ∅; plus stills (PLAN P0-16).

### SPACE-9 · MUST · Effects look physical
- **Why:** effects "can't be distracting" and should be turned down [CONTROLS-FEEL-16]; mismatched parts are an AI tell [PLAYTESTING-HUMAN-7]. Decided October 11: static light, haze and shafts are painted; only changing effects stay live.
- **Target:** each effect has a direction vector (from its cause), a falloff and floor occlusion; no single soft blob reused for every event. **Check:** a 5-frame render.sh strip per effect (0.08 s apart) where a reviewer can draw the direction and see the floor cut it (derived test).
- **Now:** NOT MET. One flat beige blob stands in for the cage release, the seal and the blast (D-0022, D-0102, D-0186, D-0200, M-0169); a hard-edged pale rectangle for the coolant hiss (D-0092 to D-0101); a cyan glow ball for the tank impact with no dent or dust (D-0243, M-0202); a clip-art "M" zigzag for WOLF's surge (M-0084, D-0101); mint puffs for the bolt and Records exit (D-0148, D-0250). Round 2: the relief vent and the coolant cloud are the same soft round glow, which hides the grate the vent card names (X-0219, X-0317).
- **Fix:** design each effect from its cause (a directional steam jet, a debris burst that settles, a dust ring and dent at the tank, arcs along WOLF's body seams), under Reduced Motion and photosensitivity limits (A11Y-2).

### SPACE-10 · SHOULD · Human scale for doors
- **Why:** MIL-STD-1472H's minimum hinged door is 2.0-2.1 m; large doors "may jam", so add a personnel door [LEVEL-ARCHITECTURE-10]; engines exaggerate doors to 1.25-1.56× player height [LEVEL-ARCHITECTURE-31]; ADA hardware height [LEVEL-ARCHITECTURE-15].
- **Target:** personnel doors ~84-98 px (1.2-1.4 × the 70 px engineer); the 136-144 px family only for freight or blast doors, with a personnel door beside or inside.
- **Now:** UNKNOWN for the new art; art-bible.md assigns the 136-144 px family to the corridor seal, Records west door, archive lift hatch, junction blast door and hatches (~2 × the engineer).
- **Fix:** Q8.

### SPACE-11 · SHOULD · Guide with light and landmarks
- **Why:** "Light for player progression, and highlight exits / critical path" [LEVEL-ARCHITECTURE-8]; "a landmark in the distance" [LEVEL-ARCHITECTURE-9]; Lynch's paths, edges and landmarks [LEVEL-ARCHITECTURE-32]; flow from layout and lighting [LEVEL-ARCHITECTURE-23]; light steers attention, subtly [LEVEL-ARCHITECTURE-33]; exits lit as real egress [LEVEL-ARCHITECTURE-12].
- **Target:** one landmark visible from each entrance; the exit is the brightest motivated light in its half of the room.
- **Now:** PARTLY. "Follow the station lights" points at lights the phone reviewer could not pick out (M-0110).
- **Fix:** light the exit and the next station; drop hints that name lights nobody can see.

### SPACE-12 · SHOULD · Sealed areas use real vestibule and interlock logic
- **Why:** airlock doors "should not be opened simultaneously" and get interlocks or warnings (EU GMP Annex 1, a guideline) [LEVEL-ARCHITECTURE-17]; BSL-3's "two consecutive self-closing doors" [LEVEL-ARCHITECTURE-18]; SCIF door types [LEVEL-ARCHITECTURE-20]; exits open from inside "without keys, tools, or special knowledge" [LEVEL-ARCHITECTURE-11].
- **Target:** a sealed area has two doors, a status light each, a gauge or airflow indicator, a plate and a short delay; a lockdown that traps staff reads as wrongdoing.
- **Now:** NOT MET (not built; fits the decided PIN-code and door-lamp design).
- **Fix:** later rooms. This is for sealed areas added later; it does not change the approved single corridor shutter (round 4, October 11) unless Nathanial decides so (Q8).

### SPACE-13 · SHOULD · Real dimensions for ceilings, rails and stairs
- **Why:** OSHA ceiling 7 ft 6 in; MIL-STD rails, toe boards, stair 30-50° and ramp 7-15° ranges [LEVEL-ARCHITECTURE-10] [LEVEL-ARCHITECTURE-11].
- **Target:** ceilings ≥ 92 px; overhead clearance 82 px; rails at 44 px with mid rail and toe board; stairs 30-50° (38° preferred) with equal risers.
- **Now:** NOT MET in the plan: level-expansion.json has a 96 px rise over a 290 px run (~18°), between the ramp and stair ranges. The plan's own 30° option fixes it.
- **Fix:** Q9.

### SPACE-14 · SHOULD · WOLF's routes are real service structures sized for him
- **Why:** at 40 px/m WOLF is about 2.9 m long and 1.5 m tall; a vent he fits through breaks the scale [LEVEL-ARCHITECTURE-10] [LEVEL-ARCHITECTURE-6].
- **Target:** catwalks, cable galleries or pipe-rack tops with ≥ ~65-70 px clear height; never an air vent.
- **Now:** NOT MET (WOLF routes are planned, not built).
- **Fix:** in the room expansion.

### SPACE-15 · SHOULD · One "what happened here" chain per room; damage persists
- **Why:** environmental storytelling is "staging player-space" to be read as a whole [LEVEL-ARCHITECTURE-1] [LEVEL-ARCHITECTURE-2]; "It has to be possible to miss some things" [LEVEL-ARCHITECTURE-3]; most players run through a room, so essentials never live only in a vignette (Walker's estimate) [LEVEL-ARCHITECTURE-24]; "Any changes that I made in the game world persisted" [PLAYTESTING-HUMAN-24]; [LEVEL-ARCHITECTURE-26] [LEVEL-ARCHITECTURE-37].
- **Target:** one missable, wordless vignette per room tied to the purge or WOLF's escape; Blowback damage stays when the player returns.
- **Now:** PARTLY. The blown door persists (decided and built). No vignettes yet; the two approved environmental purge hints are not built.
- **Fix:** build the two purge hints.

### SPACE-16 · SHOULD · Safe points are refuges
- **Why:** prospect and refuge; height feels secure with railings, vertigo without [LEVEL-ARCHITECTURE-5] [LEVEL-ARCHITECTURE-4].
- **Target:** each safe point sits in an alcove with a lower ceiling, warm light, the player's back to a wall and a view of the route.
- **Now:** NOT MET. The safe point is a console in the open corridor (D-0105).
- **Fix:** in the corridor rebuild.

### SPACE-17 · SHOULD · Real safety colours; no repeated prop in one view
- **Why:** red means fire, danger and stop; yellow means caution [LEVEL-ARCHITECTURE-14] [LEVEL-ARCHITECTURE-16]; players notice "repeated clutter first" [LEVEL-ARCHITECTURE-22] [LEVEL-ARCHITECTURE-30].
- **Target:** hazard striping only where there is a hazard; no prop sprite twice in one view unless a deliberate row of 3+.
- **Now:** PARTLY. The junction breaker and release now use different art (junction_room.gd:20, :32), fixing the level-architecture audit's repeat; the purge console is reused at two heights across rooms (D-0048, D-0116); striping use not audited.
- **Fix:** check in the look-real pass.

### SPACE-18 · COULD · Clear floor in front of panels and doors
- **Why:** OSHA working space and MIL-STD free floor [LEVEL-ARCHITECTURE-13] [LEVEL-ARCHITECTURE-10].
- **Target:** ~36-48 px of clear floor in front of every panel; nothing in a doorway or door swing.
- **Now:** UNKNOWN.
- **Fix:** check during grey box.

---

## 6. WOLF in play (WOLF)

### WOLF-1 · MUST · WOLF follows by default, never nags, never sets the pace
- **Why:** Alyx's "Hurry up!" lines: "after about three minutes ... make the player hate Alyx", so she moved to "almost always following" [COMPANION-PLAY-9] [LOOP-PACING-11a] [ONBOARDING-11] [NARRATIVE-IN-PLAY-6] [PUZZLES-30]; she is "always content to proceed at whatever pace the player chooses"; scenes "gently pause and wait" [LOOP-PACING-3]; Uncharted 4 buddies lead on splines with wait points and hysteresis [COMPANION-PLAY-33] [COMPANION-PLAY-34] [COMPANION-PLAY-41]; a scripted buddy can drive pace when authored [LOOP-PACING-18].
- **Target:** 0 urgency lines; leads only in authored beats, waiting silently.
- **Now:** MET in the text (no hurry lines found; m0_actor.gd follow logic). Not checked in play.
- **Fix:** keep it as a writing rule. **Check:** a headless test that greps every WOLF line constant for urgency words (hurry, quick, come on, keep moving, faster, now!) and fails on any (PLAN P0-17).

### WOLF-2 · MUST · WOLF never stands in the way or inside anything
- **Why:** Ellie's spots are rated on "not being in front of the player" and she prefers "the same room" [COMPANION-PLAY-1]; Valve's formations keep line of sight and spacing [COMPANION-PLAY-29].
- **Target:** at rest, WOLF's body never overlaps a station, a door frame, the engineer or the engineer's USE spot, and never stands across a doorway from the engineer (check every beat in a render.sh still).
- **Now:** NOT MET. On the bypass wheel (D-0105); half inside the relay (M-0084); inside the valve and blown door frame for ~35 s of the lane (D-0205, D-0213, D-0240, M-0188); the engineer drawn inside WOLF (M-0196); in front of the exit hatch (D-0246, M-0208). `off_machines` exists (m0_actor.gd:130-145) but authored targets bypass it (e.g. `WOLF_RUBBLE_X` 448, junction_room.gd:123).
- **Fix:** move every authored WOLF spot to clear floor; a headless test that asserts no overlap at rest.

### WOLF-3 · MUST · Gait follows distance, and stays below the player's top speed
- **Why:** Alyx "looks and feels the best when she's moving faster than the player's normal speed, but slower than the player's sprint speed" [COMPANION-PLAY-9] [ONBOARDING-30]; Valve walks allies within 190 units [COMPANION-PLAY-29]; Ellie's animation scales up to 25% instead of flicking gaits [COMPANION-PLAY-1] [COMPANION-PLAY-33].
- **Target:** near the engineer WOLF matches their gait; far away he runs above walk and below the top player speed; animation scaled up to ±25%.
- **Now:** PARTLY. `FOLLOW_SPEED` 220 vs 190 (1.16×, inside the band; m0_actor.gd:31-32). No gaits. Once walk 80 / jog 190 ships, 220 exceeds the jog.
- **Fix:** add a walk or trot for WOLF with the walk/jog work (FEEL-3).

### WOLF-4 · MUST · No vanishing or teleporting on camera
- **Why:** Naughty Dog refused teleports for keeping up (footsteps jump, sides swap) [COMPANION-PLAY-1]; Irrational, Santa Monica and Valve teleported only where unseen [COMPANION-PLAY-6] [COMPANION-PLAY-18] [COMPANION-PLAY-42] [COMPANION-PLAY-11]; Atreus's "three four second rule" for arriving [COMPANION-PLAY-18].
- **Target:** WOLF enters and leaves the frame by walking; an authored assist puts him in frame within ~3-4 s; every move he makes for a beat is long enough to be seen.
- **Now:** NOT MET. He is hidden in place at the end (M-0219 to M-0220, log); his bait run lasts under 2 s and appears to pass through the sentry (M-0198 to M-0200).
- **Fix:** walk-out (PACE-9); route the bait run around the sentry (behind it, or over the rubble) and give it ~2-4 s on screen.

### WOLF-5 · MUST · Acknowledge every request at once, even a no
- **Why:** Game Informer's Last Guardian review: telling Trico to jump "three times, only to have it stare at you ... then oblige on your fourth try" left the reviewer stuck ~15 minutes and "feels like the controls aren't working" [GAP-PASS-20]; Ueda meant Trico to "frustrate and delight" [GAP-PASS-21]; the same reception summarised [COMPANION-PLAY-15]; Atreus's response "needs to happen" every time [COMPANION-PLAY-18]; 0.1 s and 1 s limits [COMPANION-PLAY-40] [CONTROLS-FEEL-27].
- **Target:** a visible acknowledgement (ear or head snap, eye brightening, chirp) within 0.1 s; his decision readable within ~1 s.
- **Now:** PARTLY, measured (headless choice probes, routes D/M/X/C): his spoken answer appears **1 frame (17 ms)** after every choice. His body acts at frame 1 only when the choice sends him somewhere (the mirror readout, the bait run; he turns at frame 66-83). After the relay refusal his sprite flips at frame 1 and nothing else; after the lane refusal and "Stay back, I'll time it" there is no body change within 2 s (120 frames). A growl plays on both lane answers; the relay answers are silent.
- **Fix:** a short head-and-eye "heard you" reaction on every request, before the line. **Check:** the same headless probe, extended to WOLF's pose state: first visible pose change ≤ 6 frames after the press on every choice (PLAN P0-18).

### WOLF-6 · MUST · No babysitting, and he never wrecks the plan
- **Why:** "You should not have to babysit him" (Atreus pillar) [COMPANION-PLAY-18]; forced rescues made Ellie "tedious" [COMPANION-PLAY-1]; "not obligated to take care of her" [COMPANION-PLAY-7]; a buddy who ruins the plan "just once" undoes the work [COMPANION-PLAY-1]; Left 4 Dead bots cannot cause some events [COMPANION-PLAY-42].
- **Target:** WOLF cannot die, be captured or need rescue in the slice; the sentry ignores him except in the authored bait.
- **Now:** MET (no WOLF fail state; sentry_brain.gd targets the engineer; the bait is authored).
- **Fix:** keep it. **Check:** a headless test that the sentry's sight and contact never target WOLF outside the authored bait (sentry_brain.gd), and that no state can fail or capture him (PLAN P0-17).

### WOLF-7 · MUST · His help is rare, visible and in frame
- **Why:** "if the player doesn't see what they are doing, then it is wasted effort"; Ellie's gifts "every minute" devalued them [COMPANION-PLAY-1]; Atreus was ignored until his presence and impact were readable [COMPANION-PLAY-18]; companion tasks must "finish quickly" [ONBOARDING-11].
- **Target:** 100% of WOLF-caused world changes show contact on screen before the effect (the earlier study's target, agreed).
- **Now:** NOT MET. The surge is a decal over WOLF standing inside the relay (M-0084); his readout is never shown (M-0121); "WOLF runs ahead to the valve" while he stands at the breaker (D-0165, M-0148; main.gd:220).
- **Fix:** a contact pose and arc along his body at the relay; a projected readout at the mirror; make him actually run to the valve.

### WOLF-8 · MUST · He doesn't steal the fun
- **Why:** it was "much more satisfying" when Alyx stated the goal and stepped aside [COMPANION-PLAY-9]; she "is careful not to steal the player's fun" [COMPANION-PLAY-10]; boss fights are the player's "hero moments"; Atreus never surpasses Kratos [COMPANION-PLAY-18]; she sometimes thinks she solved it [PUZZLES-31].
- **Target:** WOLF never completes a step the engineer is working on; he shows goals and steps aside.
- **Now:** MET. He works his own stations (relay, readout, bait); the drop, crank and bolt stay the engineer's.
- **Fix:** keep it. **Check:** a headless test that no WOLF action sets the engineer's step flags (valve turns, tank drop, bolt) on any route (PLAN P0-17).

### WOLF-9 · MUST · A speech and sound budget
- **Why:** Valve cut lines where Alyx "sounded impatient or frustrated"; its shipped ally speech manager rate-limits idle talk [COMPANION-PLAY-30] [COMPANION-PLAY-9]; callouts of unseen enemies "reflected badly on Ellie's intelligence" [COMPANION-PLAY-1]; salience-based barks pick the most specific matching line and start from broad defaults [NARRATIVE-IN-PLAY-34] [NARRATIVE-IN-PLAY-40]; separate bark subtitles [NARRATIVE-IN-PLAY-8].
- **Target:** starting values from Valve's shipped code: a global idle gap of 10-20 s; a repeat window per cue (danger 5 s, watch-out 30 s); once-only lines; danger cues never blocked; callouts only for things the player can see. Tune in play.
- **Now:** NOT MET (no bark system; every line is an authored beat).
- **Fix:** a small rule table (trigger, conditions, cooldown, once, priority) when barks are added.

### WOLF-10 · MUST · Off screen: sound plus an edge marker, never a mood bar
- **Why:** Planet of Lana's separated icon shows direction and whether Mui is "sitting or moving towards you" [COMPANION-PLAY-24]; Elizabeth's off-screen "sigh" or "hmm" [COMPANION-PLAY-4]; Ueda resisted "an icon above the girl's head" [COMPANION-PLAY-21]; a real share of phone players play without sound (27% in one 2013 metric; magnitude UNVERIFIED) [COMPANION-PLAY-43] [COMPANION-PLAY-44] [COMPANION-PLAY-45]. Decided: off-screen WOLF is shown by sound plus a small edge marker.
- **Target:** the marker shows only while WOLF is out of frame, with direction and one of 3-4 state poses; it works with the sound off.
- **Now:** NOT MET (not needed yet: every room fits one view; required once rooms widen).
- **Fix:** build with the room expansion.

### WOLF-11 · MUST · A refusal reads as a decision, and the other route is visible
- **Why:** Trico's inconsistency "feels like the controls aren't working" [GAP-PASS-20] [COMPANION-PLAY-15]; "if you can't control it at all it becomes a nuisance" (Ueda) [COMPANION-PLAY-13]; story-driven disobedience on a button the player relies on "feels like a really bad companion" [COMPANION-PLAY-18]; Trico vocalises a request when space blocks him [COMPANION-PLAY-12].
- **Target:** a distinct refusal pose and sound that start within 6 frames (0.1 s) of the choice and hold at least 1 s (derived), his head turned to the thing he refuses; the engineer-only route lit when he refuses.
- **Now:** PARTLY. The words land (D-0070, D-0080 "The bypass is right beside it.", D-0213); no body language visible in the stills.
- **Fix:** refusal pose and sound; light the bypass when he refuses.

### WOLF-12 · SHOULD · No shuffling: a dead band and an arrival tolerance
- **Why:** Valve resets a formation only after the leader moves 36 units and repaths after 60 [COMPANION-PLAY-29]; Ellie moves only when "absolutely necessary" [COMPANION-PLAY-1].
- **Target:** re-target only after the engineer moves ~36 px (derived starting value).
- **Now:** NOT MET. `_approach` re-targets every frame and stops within 2 px (m0_actor.gd:157-161).
- **Fix:** add the dead band.

### WOLF-13 · SHOULD · Idle business and a head-first look-at
- **Why:** Yorda "strolls around, follows birds and points to things" [COMPANION-PLAY-20]; Ellie explores placed points of interest [COMPANION-PLAY-1]; Elizabeth's look-at markers [COMPANION-PLAY-5]; Trico's interest levels and "lion-dance" look-at [COMPANION-PLAY-12].
- **Target:** 2-4 interest points per room (interest, dwell, max distance, cooldown; starting value UNVERIFIED); he looks at the engineer when they talk.
- **Now:** NOT MET. In every still he holds the same stride pose (genre fan, phone review).
- **Fix:** after the walk cycles: idle poses, sniff, look-at.

### WOLF-14 · SHOULD · He witnesses and remembers, in a person's words
- **Why:** Alyx's praise means "someone witnessed and appreciated their heroics" [COMPANION-PLAY-9]; Brothers' flower interaction matures [COMPANION-PLAY-23]; "The worst thing you can do is just move on" [NARRATIVE-IN-PLAY-14] [NARRATIVE-IN-PLAY-15].
- **Target:** a short reaction to each success; memory callbacks paraphrase, never quote the menu.
- **Now:** PARTLY. Memory works across rooms (D-0106, D-0116, D-0213, M-0198, end card). Two callbacks quote the menu line verbatim: "You said "Go now. We can talk after." I refused." (D-0106, M-0089).
- **Fix:** rewrite the callbacks ("You rushed me." / "You were straight with me."), for Nathanial's approval.

### WOLF-15 · SHOULD · Each room has something only WOLF can do and something only the engineer can do
- **Why:** B-12 "naturally complete[s] the cat's natural skills" [COMPANION-PLAY-26]; Mui crawls, jumps and chews where Lana can't [COMPANION-PLAY-24].
- **Target:** ≥ 1 WOLF-only and ≥ 1 engineer-only ability per room. WOLF-only abilities are optional or faster routes; every essential step keeps an engineer-only route (AGENTS.md: "essential progress needs an engineer-only fallback").
- **Now:** MET in design (relay / bypass; readout / port; bait / drop), but WOLF's half is not shown (WOLF-7).
- **Fix:** WOLF-7.

### WOLF-16 · COULD · Some air between WOLF and the engineer
- **Why:** Valve's default slot leaves ~64-88 units between bodies [COMPANION-PLAY-29]; Ellie stays close [COMPANION-PLAY-1].
- **Target:** check the gap in stills and by play.
- **Now:** 4 px of air (`FOLLOW_GAP` 88 − `CLEAR_GAP` 84; m0_actor.gd:41-44).
- **Fix:** try 16-24 px of air in a still, then by hand.

### WOLF-17 · COULD · Ask WOLF for a hint
- **Why:** players disliked unsolicited hints but "did want to be able to explicitly request help" [PUZZLES-30] [ONBOARDING-11]; the data on on-demand help is mixed (+12% play time in one game, −12% levels in another) [ONBOARDING-13].
- **Target:** USE on WOLF when nothing else is in range asks for a hint; he answers in character.
- **Now:** NOT MET, by decision ("no player request verb yet").
- **Fix:** Q3; revisit only if deaths or stalls cluster at one node.

---

## 7. Failure and retry (FAIL)

### FAIL-1 · MUST · Every hazard shows its cause first; every card names it and how to avoid it
- **Why:** players who blamed themselves rated the game higher than those who blamed difficulty (p < 0.016) [FAILURE-DIFFICULTY-2]; "Whenever something random happens to the player, paranoia sets in" [FAILURE-DIFFICULTY-10] [FAILURE-DIFFICULTY-21]; good and bad deaths (Halo 3) [FAILURE-DIFFICULTY-28].
- **Target:** the drawn sight beam equals the real sight range; a readable alert beat before any chase; a facing that is clear; every card names a visible cause and a visible fix.
- **Now:** PARTLY. All five knockdown reasons were captured (rounds 1 and 2). Each card names a cause; whether it is visible:
  - BLAST (D-0186, C-0196): "The door went with Rowan in front of it": the door is drawn. Visible.
  - VENT (X-0219): "The relief vent let go under Rowan ... stay off the grate": the vent is labelled, but the grate is hidden under the same soft glow as the cloud. Partly.
  - SENTRY, seen in the lane (D-0226): "past the alcove's right post ... Keep inside the posts": posts not readable (TEACH-5). Not visible.
  - SENTRY, chased after a miss (X-0298): "The sentry ran Rowan down. Once its eyes go red, only the rubble is safe": the red eyes and beam are drawn; the rubble is a few shards. Partly.
  - CLOUD (X-0318): "The coolant cloud caught Rowan. Let it clear before crossing the mark": cloud and yellow mark visible. Visible.
  Cards say what happened and what to do (junction_room.gd:206-215). The drawn beam reaches the real sight range (sentry.gd:90) but fades to near-invisible at its tip; a 0.5 s lock before chase exists (sentry_brain.gd:44). The sentry's cone and red light point opposite ways (D-0213, D-0222). The sentry card names "posts" nobody can see (TEACH-5).
- **Fix:** align the cone with the lamp and add a hard beam tip at the real sight range; make the facing obvious; draw the vent grate above the steam; keep the beam readable without red (it nearly vanishes under protanopia and deuteranopia simulation, A11Y-3); TEACH-5 for the words. **Check:** stills of all five cards; a headless check that the drawn beam end equals `SIGHT_RANGE` (PLAN P0-16).

### FAIL-2 · MUST · Retry is near-instant and lands facing the goal
- **Why:** "Remove lives, reduce respawn time, keep the levels short and keep the goal always in sight" [FAILURE-DIFFICULTY-25]; difficulty = chance of death × penalty [FAILURE-DIFFICULTY-14]; flow needs control [FAILURE-DIFFICULTY-1].
- **Target:** keep the approved Cold Still screen (RETRY at 0.9 s, control at ~1.5 s, never auto-advances); respawn facing the goal and the hazard.
- **Now:** PARTLY. Knockdown to control is ~1.1 s in the capture (D-0186 at 145.8 s to D-0187 at 146.9 s), within the ~1.45 s budget (main.gd:186-187). The Cold Still death screen is decided but not built.
- **Fix:** build Cold Still for deaths; keep knockdowns as they are. Note: the approved death-card set (docs/research-2026-10/approved/death-text-2026-10-10.json, key `final`) carries no input delay; a "2.4 s first death, 0.8 s repeat" delay appears only in an earlier draft note, which predates Cold Still (Q17).

### FAIL-3 · MUST · Restore at most one beat back, and say what was reset
- **Why:** Crash turned a crate into a continue point after repeated deaths, to "help weaker players without changing the game for the better players" [FAILURE-DIFFICULTY-4]; Hamlet counts deaths at a location [FAILURE-DIFFICULTY-3]; TLOU2 ships checkpoint frequency [FAILURE-DIFFICULTY-29]; "Save Early, Save Often" [FAILURE-DIFFICULTY-35].
- **Target:** ≤ ~20 s of replay (decided); after ~3 deaths at the same beat (a design value to test), quietly move the restore point closer, never on the first death.
- **Now:** PARTLY. The blast retry restarts at the junction entry and resets the breaker (~5-10 s of replay; M-0170 to M-0182) without saying so; the sentry retry lands behind the rubble (D-0227). No adaptive restore.
- **Fix:** say "Back at the junction entrance. Arm the breaker again."; add the repeated-death restore.

### FAIL-4 · MUST · Time pressure is the most forgiving lever; the fuse must be readable
- **Why:** "the shortest time limits were the most disengaging of any design factor" (10K and 70K players) [FAILURE-DIFFICULTY-13]; "Do not make precise timing essential" [FAILURE-DIFFICULTY-19]; tune until players scramble "at the last moment" [LOOP-PACING-11b]; a ticking sound says act now [LOOP-PACING-17].
- **Target:** the fuse is long enough that a fresh player who starts moving on the klaxon and stripes clears the zone at the last moment, on desktop and phone (derived starting point: ~2.5 s, then tune down by observed near-misses); a tick synced to the fuse.
- **Now:** NOT MET. `FUSE_SECONDS` 1.0 (pressure_line.gd:10). The warning "FUSE LIT. Back away from the door, past the valve." (main.gd:2643) is 9 words, ~3 s to read at 180 wpm; the door goes ~1 s after it appears (D-0185 to D-0186, D-0199 to D-0200, M-0168 to M-0169).
- **Fix:** lengthen the fuse, add the tick, and tune by play.

### FAIL-5 · MUST · Help after repeated failure, never before the first try
- **Why:** Assist Blocks "show up after five misses" [ONBOARDING-22]; Miyamoto would be "intensely irritated" by help offered at the start [ONBOARDING-2]; in NSMB Wii, Miyamoto found the help block insulting from the start and still annoying after three lost turns ("Leave me alone!"); the team weighed five against ten and chose eight [GAP-PASS-23] [PUZZLES-45] [ONBOARDING-2]; hints after "no progress after a period of time" [ONBOARDING-18].
- **Target:** after ~3 knockdowns at one hazard (a proposal to test: Nintendo chose 8 lost turns in a game with ~5 lives per session, but a junction retry costs ~20 s, not a level), WOLF offers one short, optional line; never a "make it easier?" popup [FAILURE-DIFFICULTY-1].
- **Now:** NOT MET (every card explains, but nothing escalates).
- **Fix:** a per-hazard death counter feeding one WOLF line.

### FAIL-6 · SHOULD · Bias hazard edges slightly toward the player
- **Why:** Celeste's "fudged a tiny bit in the player's favor" margins [FAILURE-DIFFICULTY-18] [FAILURE-DIFFICULTY-20] [CONTROLS-FEEL-3].
- **Target:** hazard hit areas a few px inside the art; ~0.1 s grace at timing-window edges.
- **Now:** UNKNOWN. A graze at the tank brackets' edge counts as a miss by default (decided: "a hit = its body overlaps the brackets").
- **Fix:** Q7.

### FAIL-7 · SHOULD · A quiet stretch after every knockdown
- **Why:** Left 4 Dead adjusts pacing, not difficulty, and leaves set pieces alone [FAILURE-DIFFICULTY-5].
- **Target:** respawn spots are threat-free; authored beats keep their timing.
- **Now:** MET (the junction entry and behind the rubble are safe; D-0187, D-0227).
- **Fix:** keep it.

### FAIL-8 · SHOULD · The route choice is the main difficulty dial
- **Why:** Chen's active difficulty puts choices inside play; frequent "easier?" choices broke flow [FAILURE-DIFFICULTY-1].
- **Target:** asking WOLF is faster; doing it yourself is slower; neither is a menu.
- **Now:** MET (relay, mirror and lane choices).
- **Fix:** keep it.

### FAIL-9 · COULD · An opt-in assist that grows with failure, and a calmer sentry
- **Why:** Hades' God Mode (+2% resistance per death, cap 80%), though its creator doubts it transfers to linear games [FAILURE-DIFFICULTY-6B] [FAILURE-DIFFICULTY-6]; Alien: Isolation's Novice alien is slower and less adaptive [FAILURE-DIFFICULTY-16]; TLOU2's stealth grace period [FAILURE-DIFFICULTY-29].
- **Target:** a calmer-sentry option (slower chase, longer lock, shorter lose time; knobs in sentry_brain.gd:33-46).
- **Now:** NOT MET.
- **Fix:** part of A11Y-1.

### FAIL-10 · COULD · Keep the evidence-drop cost on optional finds, and make no-death runs a rare badge
- **Why:** difficulty is a means to accomplishment [FAILURE-DIFFICULTY-15]; only 2.5% of Limbo owners finish with five or fewer deaths [FAILURE-DIFFICULTY-24].
- **Target:** key records never drop (decided); optional finds may.
- **Now:** NOT MET (decided "Secure the Evidence", not built).
- **Fix:** keep the decided rule.

---

## 8. Story in play (STORY)

### STORY-1 · MUST · Keep control with the player during story
- **Why:** Valve's rule of "never – or at least very rarely - taking control away from the player" [NARRATIVE-IN-PLAY-5]; Oxenfree had no cutscenes [NARRATIVE-IN-PLAY-19]; God of War's director: "The vocabulary of film is camera cuts ... But games are different. We don't really need to do that" [GAP-PASS-24]; experiential density [NARRATIVE-IN-PLAY-4].
- **Target:** after first control, no non-interactive sequence longer than ~10 s and at most one per room (derived); each is skippable and flows into play from the same frame; the opening is the one long exception and stays player-paced.
- **Now:** PARTLY. The opening is player-paced (MET); the Records exit holds the player for ~16 s of lines (D-0148 to D-0164).
- **Fix:** STORY-8.

### STORY-2 · MUST · Auto-timed lines at a human reading speed
- **Why:** BBC subtitles run at 160-180 wpm with a minimum of ~0.3 s per word [NARRATIVE-IN-PLAY-1]; Netflix events last 5/6 s to 7 s [NARRATIVE-IN-PLAY-2] [NARRATIVE-IN-PLAY-3]; adult silent reading averages 238 wpm (range 175-300) [NARRATIVE-IN-PLAY-10].
- **Target:** ≥ 0.33 s per word plus a base, minimum ~1.2-1.5 s, maximum 7 s per box; USE always advances early.
- **Now:** NOT MET (latent). `READ_SECONDS_PER_WORD` 0.15 = 400 wpm (main.gd:39, :978-979). Today it only gates the stakes line (main.gd:959), so lines can vanish unread if it becomes the walk-and-talk timer.
- **Fix:** change it to 0.33 s per word plus a base before any walk-and-talk.

### STORY-3 · MUST · Text sized and shaped like good subtitles
- **Why:** players' main subtitle complaints are size, contrast and amount of text [NARRATIVE-IN-PLAY-9] [NARRATIVE-IN-PLAY-13]; 37-42 characters and 2 lines [NARRATIVE-IN-PLAY-1] [NARRATIVE-IN-PLAY-2] [NARRATIVE-IN-PLAY-8]; Apple's 17 pt default and 11 pt minimum [NARRATIVE-IN-PLAY-33].
- **Scope:** auto-timed and story boxes (the bottom dialogue box, the hint bar, cards). Player-paced inspect panels (the planned evidence case) have their own target in CASE-2; the approved examine texts are 99-123 characters each.
- **Target:** ≤ 40-42 characters per line, ≤ 2 lines per box (3 only at choices), ≥ ~23-24 px at 540p (46 px at 1080p), a text-size option 100-200%, an opaque or adjustable backing option. **Check:** headless measurement of every shown box's line count and characters per row at the default and 200% sizes, plus stills at 960 × 540, 1280 × 720 and 2400 × 1080 (PLAN P0-9).
- **Now:** NOT MET. The Story label is 17 px (main.tscn:352) with rows of ~97-118 characters (headless measurement); the longest box is 3 lines and 267 characters (D-0048); 48 of 58 distinct dialogue lines exceed 40 characters (genre-fan log count). No text-size option.
- **Fix:** narrower column, larger type, a size setting.

### STORY-4 · MUST · One speaker per box, named at every change
- **Why:** name the speaker "each time a new speaker begins talking" [NARRATIVE-IN-PLAY-8]; colour is "the preferred method for identifying speakers" [NARRATIVE-IN-PLAY-1] [NARRATIVE-IN-PLAY-9]; Valve's captions made it "clear who was speaking" [NARRATIVE-IN-PLAY-5].
- **Target:** one speaker per box, WOLF in a fixed colour plus his name, a direction cue when he is off-screen.
- **Now:** PARTLY. Single-speaker lines use the speaker column (M-0062); many boxes cram 2-3 voices inline ("FIRST COPY SECURED. WOLF: ... ROWAN: ...", D-0150, M-0131; also M-0031, M-0089).
- **Fix:** split multi-speaker strings into consecutive boxes.

### STORY-5 · MUST · Choices say what the engineer does, and WOLF answers at once
- **Why:** "The worst thing you can do is just move on" (Meier) [NARRATIVE-IN-PLAY-14]; the highest felt agency came from immediate feedback plus later callbacks [NARRATIVE-IN-PLAY-15]; Telltale iterated in "choice notifications" and found "smaller, more intimate details" beat big branches [GAP-PASS-25]; 75% saved Carley and 25% Doug because players had not been given "the chance to learn who Doug is" [GAP-PASS-26].
- **Target:** options are distinct values written as what the engineer does; WOLF reacts visibly at once; a few choices are called back later.
- **Now:** PARTLY. Acknowledgement and callbacks are strong (D-0070, M-0070, D-0213, end card). Option 2 at the relay, "Go now. We can talk after.", hides that it means not telling WOLF the risk, so his refusal felt like a trick (D-0062, D-0070); the mirror choice has no visible stakes (D-0131, M-0113).
- **Fix:** reword the options (for Nathanial's approval) and show what each mirror route costs.

### STORY-6 · MUST · Text is player-paced and can be read again
- **Why:** "progress through text prompts at their own pace" and "Allow all narrative ... to be replayed" [NARRATIVE-IN-PLAY-32]; [NARRATIVE-IN-PLAY-8].
- **Target:** no hidden choice timer; a pause-menu log of the last 20 lines (derived; shared with TEACH-4).
- **Now:** PARTLY. Player-paced and untimed (MET); no log.
- **Fix:** with TEACH-4.

### STORY-7 · MUST · Point the eye at reveals without taking control
- **Why:** players miss even huge set pieces: "staring at a tire"; Alyx "mentions the citadel while pointing at it"; birds were added because the Citadel was "often missed" [NARRATIVE-IN-PLAY-5] [NARRATIVE-IN-PLAY-6].
- **Target:** every narrated visual change is visible on screen when the line appears, in the walking direction.
- **Now:** NOT MET. "A blue light answers from inside the containment seal" shows no blue light (D-0014); "The Director freezes" while nothing changes (D-0022); "Blue light fills the coolant relay" is barely visible (D-0075); "WOLF runs ahead to the valve" while he stays at the breaker (D-0165).
- **Fix:** make each narrated change happen on screen, or cut the line. **Check:** a line-by-line table of every narration line that describes a visible change against the frame where the change shows (or "not shown"), redone each capture (PLAN P0-19).

### STORY-8 · MUST · Never hold the player still for dialogue; run it on the walk
- **Why:** in Portal 2 "every player made a beeline for the opening", so the dialogue was cut [NARRATIVE-IN-PLAY-18]; Oxenfree sizes each line to the walk from A to B [NARRATIVE-IN-PLAY-19] [NARRATIVE-IN-PLAY-20].
- **Target:** lines after a beat play while the player walks to the next one; the box clears after its reading time.
- **Now:** NOT MET. Old dialogue lingers 8-16 s (D-0120 to D-0130, D-0148 to D-0164, D-0253 to D-0263).
- **Fix:** let movement continue through closing lines; clear the box after `_read_seconds` (with STORY-2's fixed rate).

### STORY-9 · MUST · Story and play agree
- **Why:** BioShock's "powerful dissonance" between game and story, in Clint Hocking's own post [NARRATIVE-IN-PLAY-29]; WOLF's theme is belonging with, not to.
- **Target:** the engineer's verbs are maintenance verbs; no command verb for WOLF; no visible trust meter; the engineer-only route costs time, never progress.
- **Now:** MET (no meter, no command verb; the end card is a story recap).
- **Fix:** keep it. **Check:** headless tests that no meter node exists in the HUD and that the engineer-only route reaches every essential step with WOLF refusing everything (PLAN P0-17).

### STORY-10 · SHOULD · Short lines
- **Why:** a 120-150-character line is 3-4 subtitle rows, which every standard splits [NARRATIVE-IN-PLAY-1] [NARRATIVE-IN-PLAY-10] [NARRATIVE-IN-PLAY-8]; cut by compacting phrases [NARRATIVE-IN-PLAY-35].
- **Target:** split every line of 20+ words at a sentence break; WOLF's spoken lines ≤ ~15 words.
- **Now:** NOT MET. `BAIT_NO_LINE` 29 words, `JUNCTION_ENTRY_LINE` 28, `TANK_HIT_OFF_CENTRE_LINE` 26, `BAIT_YES_LINE` 26, `TANK_HIT_LINE` 23, `RUBBLE_LINE` 20 (main.gd:136-147, :220); `BAIT_NO_LINE` hides the instruction (time the drop) at the end.
- **Fix:** split them; put instructions first.

### STORY-11 · SHOULD · Show before telling
- **Why:** Another World has "no HUD or dialog"; Inside is "mostly silent"; Journey's only voice is "a musical chime" [NARRATIVE-IN-PLAY-26] [NARRATIVE-IN-PLAY-28] [NARRATIVE-IN-PLAY-23] [NARRATIVE-IN-PLAY-24] [NARRATIVE-IN-PLAY-25]; Portal "crammed a lot of little details into the environments" [NARRATIVE-IN-PLAY-17]; Jensen dislikes stories that say "It's like that" [NARRATIVE-IN-PLAY-22]; show, don't tell, and keep the early tone gentle [ONBOARDING-29] [ONBOARDING-27].
- **Target:** words carry only what pictures cannot (who ordered what, how WOLF feels).
- **Now:** NOT MET. 46 dialogue texts (4,037 characters) and 47 hints in 208 s (genre-fan log count), in a genre its fans love for being near-wordless.
- **Fix:** Q2 and Q5: Nathanial decides what to show instead of say.

### STORY-12 · SHOULD · WOLF's body carries subtext
- **Why:** Wheatley's calm, nervousness and fear are read from head moves, eye aperture and rhythm (Karen Prell) [NARRATIVE-IN-PLAY-18].
- **Target:** calm, uneasy, afraid and working each have a readable head, optic and body grammar.
- **Now:** NOT MET (one pose in every still).
- **Fix:** with WOLF-13.

### STORY-13 · SHOULD · Story stations wait for the engineer
- **Why:** "the scene had to gently pause and wait for them to return"; players "wouldn't explore until they were sure they wouldn't miss" a performance [NARRATIVE-IN-PLAY-5].
- **Target:** a scene pauses when the engineer walks away and resumes on return; a line says when it is safe to look around.
- **Now:** UNKNOWN.
- **Fix:** check during the walk-and-talk work.

### STORY-14 · SHOULD · A quiet beat after a death before WOLF speaks
- **Why:** Portal 2 co-op leaves "a two second beat" before GLaDOS speaks (a co-op reason, so an analogy) [NARRATIVE-IN-PLAY-18].
- **Target:** ~2 s; matches Cold Still.
- **Now:** PARTLY (the card text appears at once; WOLF's capped death lines are approved but not built).
- **Fix:** with Cold Still.

### STORY-15 · SHOULD · Soft physical slowdowns buy time for a line
- **Why:** a zombie over an exit slows the player "just long enough for Alyx to finish her lines" [NARRATIVE-IN-PLAY-6].
- **Target:** a tight gap, a crouch or a heavy hatch where a line must land.
- **Now:** NOT MET (not used yet).
- **Fix:** use in the room expansion.

### STORY-16 · COULD · Choices while walking, and silence as an answer
- **Why:** Oxenfree lets players "wait ... interrupt, or ... remain silent"; Firewatch lets them not answer; The Walking Dead counts silence [NARRATIVE-IN-PLAY-19] [NARRATIVE-IN-PLAY-21] [NARRATIVE-IN-PLAY-36] [NARRATIVE-IN-PLAY-16].
- **Target:** choice buttons stay up while the engineer walks.
- **Now:** NOT MET. A choice freezes the engineer (main.gd:3013 `waiting_for_choice`).
- **Fix:** later, after testing the current choices.

### STORY-17 · COULD · Optional extra story on approach
- **Why:** control over how much story, "without it blocking progress" [NARRATIVE-IN-PLAY-5].
- **Target:** WOLF or a terminal says more if the engineer lingers.
- **Now:** PARTLY (the optional purge display read; D-0048).
- **Fix:** keep the pattern.

### STORY-18 · COULD · A later beat told through the controls
- **Why:** Brothers' final swim, "pushing the button for the other brother" [NARRATIVE-IN-PLAY-39] [NARRATIVE-IN-PLAY-25].
- **Target:** e.g. the engineer performs WOLF's half of a routine during the provisional Fracture separation.
- **Now:** NOT MET (no Fracture chapter yet).
- **Fix:** keep for Fracture.

### STORY-19 · SHOULD · Show that WOLF remembered, without a meter or a notice
- **Why:** Telltale used on-screen "choice notifications" and found "smaller, more intimate details" worked best [GAP-PASS-25]; players followed the characters they had spent time with [GAP-PASS-26]; acknowledgement at once plus a later callback gave the highest felt agency [NARRATIVE-IN-PLAY-15]; STORY-9 rules out a trust meter.
- **Target:** every choice WOLF will remember gets (1) a body reaction within 6 frames (WOLF-5), (2) one changed later beat that refers back in a person's words (WOLF-14), and no "WOLF will remember that" text.
- **Now:** PARTLY. The words land 1 frame after the choice (headless probes) and the callbacks exist (D-0106, D-0213, the END OF SLICE recap); the body reaction is missing after refusals (WOLF-5).
- **Fix:** with WOLF-5 and WOLF-14.

---

## 9. Phone (PHONE)

### PHONE-1 · MUST · Touch targets big enough, with real spacing
- **Why:** Apple 44 × 44 pt with ~12 pt padding [MOBILE-PERFORMANCE-1] [MOBILE-PERFORMANCE-2] [MOBILE-PERFORMANCE-8] [CONTROLS-FEEL-26] [CONTROLS-FEEL-32] [ONBOARDING-17]; Android 48 dp (~9 mm) [MOBILE-PERFORMANCE-9] [MOBILE-PERFORMANCE-10] [PUZZLES-35]; thumb studies 9.2-9.6 mm [MOBILE-PERFORMANCE-14]; XAG 107 suggests 15 × 15 mm on phones [MOBILE-PERFORMANCE-48] [CONTROLS-FEEL-25]; [MOBILE-PERFORMANCE-12] [MOBILE-PERFORMANCE-13] [MOBILE-PERFORMANCE-42] [PUZZLES-34] [FAILURE-DIFFICULTY-17].
- **Target:** MOVE and USE ≥ 44 pt and 48 dp (MET), aiming at 15 mm; the LEFT-RIGHT gap ≥ ~12 pt (~2 mm).
- **Now:** PARTLY. LEFT/RIGHT 96 × 90 px and USE 155 × 90 px in the 960 × 540 canvas (main.tscn:425-450) ≈ 70 × 66 pt (11.6 × 10.9 mm) and 113 × 66 pt on an iPhone 16 [MOBILE-PERFORMANCE-36]: pass Apple and Android, but ~10.9 mm tall against 15 mm. The 14 px gap is ~10 pt (1.7 mm).
- **Fix:** taller buttons and a wider gap; resizable (PHONE-9).

### PHONE-2 · MUST · Two thumbs work at once, verified
- **Why:** Godot 4.7 added finger-index multitouch to Buttons (PR #110893), but hiding a held button clears its touch without `button_up`, which may swallow the next press after resume (inferred from engine source) [MOBILE-PERFORMANCE-49] [MOBILE-PERFORMANCE-27]; plan which controls are used together [MOBILE-PERFORMANCE-8]. PRIVATE_AGENTS.md: verify simultaneous touches on devices before claiming support.
- **Target:** a headless test with touch indices 0 and 1 holding MOVE and USE together; a device test; the first press after a pause, choice or interruption always registers.
- **Now:** UNKNOWN. Buttons map `button_down`/`button_up` to `Input.action_press`/`action_release` (main.gd:1215-1217).
- **Fix:** the headless test; release held actions explicitly when buttons hide.

### PHONE-3 · MUST · Buttons show presses, name the action, and sit under the thumbs
- **Why:** "Always include visible and tactile press states"; avoid "A, X, or R1" naming; label with the action [MOBILE-PERFORMANCE-2] [MOBILE-PERFORMANCE-8] [CONTROLS-FEEL-32] [ONBOARDING-17]; Planet of Lana patched in menu press feedback [MOBILE-PERFORMANCE-41].
- **Target:** a press state visible around the thumb, a click and a light haptic; prompts match the button ("Hold CRANK", not "HOLD USE"); touch choices sit at the bottom in thumb reach with no "1"/"2".
- **Now:** PARTLY. Context labels work (CRANK, DROP, CONTINUE; M-0082, M-0200). The hint says "HOLD USE" while the button says CRANK (M-0164); CRANK shows while WOLF works the relay (M-0081); choices move to the top of the screen and keep "1"/"2" (M-0062, M-0113, M-0188).
- **Fix:** device-matched prompt text; bottom choice buttons on touch without numbers; press state plus haptic.

### PHONE-4 · MUST · Readable text on a phone
- **Why:** Apple's 17 pt default and 11 pt minimum for iOS text [MOBILE-PERFORMANCE-1] [MOBILE-PERFORMANCE-3] [MOBILE-PERFORMANCE-8]; XAG 101 mobile body text [MOBILE-PERFORMANCE-19]; 28 px at 1080p as a floor [MOBILE-PERFORMANCE-20].
- **Target:** dialogue ~17 pt (~23-24 viewport px), nothing below 11 pt (~15-16 px), text size up to 200%.
- **Now:** NOT MET. On an iPhone 16 (0.728 pt per viewport px): world labels 13 px ≈ 9.5 pt (main.tscn:231-251), hint 14 px ≈ 10.2 pt (:378), HUD and speaker 15 px ≈ 10.9 pt (:303, :336), dialogue 17 px ≈ 12.4 pt (:352). The phone reviewer would hold the phone closer.
- **Fix:** with STORY-3.

### PHONE-5 · MUST · Interruptions cost nothing
- **Why:** games pause on resign-active, and must not rely on transitions alone to save; iOS gives ~5 s in the background [MOBILE-PERFORMANCE-31] [MOBILE-PERFORMANCE-32] [MOBILE-PERFORMANCE-33] [MOBILE-PERFORMANCE-6]; Android's quality bar restores "the exact state" [MOBILE-PERFORMANCE-11]; XAG 108 and Apple Multitasking [FAILURE-DIFFICULTY-7] [FAILURE-DIFFICULTY-34]; restore state on relaunch [LOOP-PACING-15b].
- **Target:** pause in place on a call or app switch; a resume point saved within the ~5 s window and at normal checkpoints; resume into the pause menu, never into a live hazard; exact room and beat restored.
- **Now:** PARTLY. Auto-pause on `NOTIFICATION_APPLICATION_PAUSED` and focus loss is built (main.gd:235, :1446-1448); measured in round 2: a focus-out mid-fuse pauses at once and the fuse holds (0.633 s left before and 2 s later; X-0266, X-0267). No save on backgrounding was found; if the OS ends the app, progress returns to the last safe point or autosave.
- **Fix:** save a resume snapshot on backgrounding; restore into the pause menu.

### PHONE-6 · SHOULD · Fill the screen and respect the safe area
- **Why:** Apple asks for 16:10, 19.5:9 and 4:3 support and both landscape directions [MOBILE-PERFORMANCE-3] [MOBILE-PERFORMANCE-4] [MOBILE-PERFORMANCE-5]; Godot recommends `expand` for tall phones [MOBILE-PERFORMANCE-44]; safe areas [MOBILE-PERFORMANCE-45] [MOBILE-PERFORMANCE-18]; Google allows only minor letterboxing (a rule about configuration changes) [MOBILE-PERFORMANCE-11].
- **Target:** stretch aspect `expand`; HUD and controls inside `DisplayServer.get_display_safe_area()`; sensor landscape; 4:3 iPads.
- **Now:** NOT MET. Stretch mode `canvas_items` with the default aspect `keep` (project.godot) gives 240 px bars on each side of a 20:9 screen (every M- frame), ~18% of the width.
- **Fix:** switch to `expand` and anchor the HUD to the safe area; check stills at several aspect ratios.

### PHONE-7 · SHOULD · Controls stay off the play space; pause in a corner
- **Why:** frequent actions around the thumbs, secondary controls at the top, the centre kept clear [MOBILE-PERFORMANCE-2] [MOBILE-PERFORMANCE-8].
- **Target:** no touch control covers a floor mark, a station or the hint bar; PAUSE ≥ 28 pt in a top corner clear of the Dynamic Island.
- **Now:** PARTLY. PAUSE is 88 × 56 px top-right (main.tscn:407-416, MET). USE covers the junction's right floor marks and the end of the hint bar (M-0148, M-0164, M-0186); ◀ ▶ cover the purge console's base (M-0121); in the opening the floor sits on the dialogue box (M-0024, M-0036).
- **Fix:** with PHONE-6 the controls move into the side margins; raise the hint bar clear of USE.

### PHONE-8 · SHOULD · A floating movement pad on the left
- **Why:** Apple suggests a thumbstick "wherever the player lands their thumb" and one control for walking and sprinting [MOBILE-PERFORMANCE-2]; Limbo's invisible pad lost the thumb [MOBILE-PERFORMANCE-38]; dynamic sticks [MOBILE-PERFORMANCE-43].
- **Target:** a pad that appears under the thumb, draws its ring, picks walk or jog by distance and re-centres if the thumb drifts; fixed buttons kept as a preset.
- **Now:** NOT MET (fixed ◀ ▶ only).
- **Fix:** with walk/jog (FEEL-3).

### PHONE-9 · SHOULD · Layout presets and adjustable controls
- **Why:** Into the Dead's four layouts were each used by ~25% of players [MOBILE-PERFORMANCE-43]; XAG 107 asks for adjustable size, spacing and position [MOBILE-PERFORMANCE-48]; Dead Cells mobile [MOBILE-PERFORMANCE-40].
- **Target:** floating pad, fixed buttons and a left-handed mirror; resize and move MOVE and USE.
- **Now:** NOT MET. Settings has no touch section (M-0159).
- **Fix:** a TOUCH tab in Settings.

### PHONE-10 · SHOULD · Touch-specific timing
- **Why:** Playdead shortened animations for touch and rejected auto-complete; the sentry-gun sections were a "Challenging change when timing was important" [CONTROLS-FEEL-15]; platform long-press defaults (0.5 s iOS, 400 ms Android) [MOBILE-PERFORMANCE-16] [MOBILE-PERFORMANCE-17]; Limbo iOS got no touch tuning and a timing puzzle got harder [MOBILE-PERFORMANCE-38].
- **Target:** first visible response on the first frame of a touch hold; first tick at 0.4 s; no extra hold-detection delay; the tank drop and fuse tuned on a real phone; never auto-complete.
- **Now:** PARTLY. `TICK_SECONDS` 0.4 matches Android's long press (hold_use.gd:8); ticks survive a release; no phone timing test.
- **Fix:** phone playtest of the junction (TEST-7).

### PHONE-11 · SHOULD · Natural stopping points for short sittings
- **Why:** mobile session medians of 5-6 min (2024 data) and 3.1-3.5 min (2025 data), casual-dominated, so a floor [LOOP-PACING-15a] [LOOP-PACING-15d] [MOBILE-PERFORMANCE-34]; Monument Valley's ~9 minutes per level [MOBILE-PERFORMANCE-35]; Autosave Dangerous commits only after the player survives [LOOP-PACING-3].
- **Target:** a safe point or room exit at least every ~5 minutes; beats of ~2-5 minutes.
- **Now:** MET roughly (safe point after ~86 s; junction autosave on entry; the slice is ~3-4 minutes).
- **Fix:** keep the spacing in the room expansion.

### PHONE-12 · SHOULD · Settings that make sense on each device
- **Why:** players adjust controls for how they actually play [MOBILE-PERFORMANCE-48]; Planet of Lana patched settings persistence and phone layout [MOBILE-PERFORMANCE-41].
- **Target:** on phones, hide window size, fullscreen and V-sync, and add touch options; on desktop, hide the mobile note; no developer lines (GPU string) in player settings.
- **Now:** NOT MET. The phone shows WINDOW SIZE, FULLSCREEN, V-SYNC and the GPU line (M-0157 to M-0159); the desktop shows "Window size is OS-managed on mobile" (D-0173); the terminal subtitle "THE DEN / LOCAL CONFIGURATION" is the decided Settings look (Q10).
- **Fix:** per-platform rows; move the GPU line behind a debug flag.

### PHONE-13 · SHOULD · Characters readable at phone size
- **Why:** WOLF's reactions are the point, and the phone reviewer could not read faces or hands at ~1.2 cm tall (M-0142, M-0200); the tighter closing zoom read much better (M-0219). Ori deliberately kept its hero "very small on the screen" for scale [READABLE-IMAGE-2], and Somerville's pulled-back shots "show the scale" [GAP-PASS-28]; both trade body reading for scale, which this game cannot afford for WOLF. No sourced size number; the decided "tighter zoom" direction applies.
- **Target:** test a tighter phone zoom against the camera look-ahead (FEEL-6).
- **Now:** NOT MET (one zoom, 1.35, on all screens; main.gd:434). On an iPhone 16 (2556 × 1179, 460 ppi) the engineer is ~11 mm and WOLF ~8.5 mm tall (derived from sprite heights; READ-4).
- **Fix:** try a phone-specific zoom in render.sh stills, then by hand.

### PHONE-14 · COULD · Direct interaction alongside the buttons
- **Why:** Apple suggests tapping objects, but never as the only way [MOBILE-PERFORMANCE-2] [MOBILE-PERFORMANCE-47]; the puzzles research warns against making players tap small world objects [PUZZLES-34] [PUZZLES-35].
- **Target:** optional tap or swipe toward a station; the USE button always stays.
- **Now:** NOT MET.
- **Fix:** later, as an option.

### PHONE-15 · COULD · A pre-release check for known port faults
- **Why:** Planet of Lana fixed overflowing text, foldable layouts, settings persistence and menu press feedback after launch [MOBILE-PERFORMANCE-41].
- **Target:** test those four before any mobile release.
- **Now:** NOT MET (not started).
- **Fix:** add to the export checklist.

### PHONE-16 · SHOULD · iPad: thumb reach, keyboard, trackpad and controller
- **Why:** Apple lists iPadOS's default input as touch with "Game controller, keyboard, mouse, trackpad, Apple Pencil" as additional methods [GAP-PASS-5]; frequent controls ≥ 44 × 44 pt within thumb reach, clear of system areas [GAP-PASS-2]; Apple asks for 4:3 support [MOBILE-PERFORMANCE-3].
- **Target:** on a 4:3 iPad the touch controls sit within thumb reach of the lower corners (they do not scale up into the middle of a 10-13-inch screen); a hardware keyboard, trackpad or controller switches the prompts and hides the touch buttons, as on Mac.
- **Now:** UNKNOWN until a device test. Stills of the 4:3 and 19.5:9 layouts are in route S-touch ([CAPTURE-ROUND2.md](playthrough/CAPTURE-ROUND2.md)); with today's `keep` aspect a 2732 × 2048 iPad shows the 16:9 picture with ~256 px bars top and bottom (25% of the height, derived from the viewport size).
- **Fix:** with PHONE-6 and PHONE-9; test on an iPad with a keyboard and a controller.

### PHONE-17 · SHOULD · Android Back walks out one step at a time
- **Why:** Android keeps a back stack, and "We strongly recommend" supporting predictive back (Android 13+) [GAP-PASS-18]; Google's core quality bar expects Back to return to the previous screen [MOBILE-PERFORMANCE-11].
- **Target:** Back closes the innermost overlay (settings capture, Settings, Pause, credits, changelog, end card), pauses during play, and quits only from the bare title.
- **Now:** MET in code (main.gd:1452-1469 does exactly this). Predictive-back animation under Godot: UNKNOWN until a device test.
- **Fix:** keep it; add a device check to the export checklist.

---

## 10. Sound (SOUND)

### SOUND-1 · MUST · Fix the silent manual bypass
- **Why:** the bypass's cost is meant to be felt through hiss and alarm (decided October 10); sound is part of polish that tells players what things are [AUDIO-FEEL-22].
- **Target:** every clip name used in scripts exists in SfxBank; per-frame sounds go to a loop player.
- **Now:** NOT MET (bug). main.gd:970 plays `&"hiss"` every frame and main.gd:1767 stops it, but SfxBank only has `hiss_low`, `hiss_mid` and `hiss_high` (sfx_bank.gd:21-48); `play()` returns null without a warning (sfx_bank.gd:96-100). Only the klaxon is heard.
- **Fix:** play the hiss loops (as `play_blend` does) and warn on unknown clip names in debug builds.

### SOUND-2 · MUST · Every state-changing press makes a sound on the same frame
- **Why:** sound early is noticed at ~45 ms, sound late at ~125 ms [AUDIO-FEEL-3]; Android low-latency output is ≤ 45 ms [AUDIO-FEEL-4]; Godot's default output latency is 15 ms [AUDIO-FEEL-5]; co-design visual, audio and haptics, and use haptics to confirm state changes [AUDIO-FEEL-20]; polish carries weight and material [AUDIO-FEEL-22].
- **Target:** USE accepted, each ratchet tick, valve turn, relay throw, safe-point secure and door-lamp change each have a sound on the visual's frame; phones add a 10-20 ms haptic tick.
- **Now:** PARTLY, measured (headless probes of 156 presses over routes D/M/X/C/F; the probe watches SfxBank's voice round-robin and loop players). A sound starts within 1-3 frames on the breaker (clank), the bypass start (klaxon), the junction entry (hum), the tank release (clank), the bolt (whine), the lane answers (growls) and the cage release (boom); Records' first-copy press is inconsistent (records_arc on some routes, none on others). **No sound** on: the safe-point secure ("Safe point saved"), the purge-queue copy, the mirror answer, the relay answers, WOLF taking the relay (at the press), leaving through the hatch, and every invalid press (PUZ-4). Haptics exist only for impacts (impact.gd:172).
- **Fix:** add the missing sounds and haptic ticks. **Check:** keep the probe as a headless test: every state-changing press starts an SfxBank sound within 1 frame (PLAN P0-14).

### SOUND-3 · MUST · Footsteps from the painted cycles' contact frames
- **Why:** Celeste fires steps on contact frames and reads the surface under the feet [AUDIO-FEEL-13]; INSIDE picks steps from a matrix of movement keys, with takeoff and brake variants [AUDIO-FEEL-8]; no-repeat randomisers [AUDIO-FEEL-26] [AUDIO-FEEL-6].
- **Target:** a step on each contact frame; surface from the floor (grating, plate, wet); at least 4 variants per surface and never the same variant twice in a row (derived); start and stop variants; WOLF's paw and servo steps. **Check:** headless log of step events against contact frames (0-frame offset) and of variant repeats (0).
- **Now:** NOT MET (no footstep code; decided as a real-feel item).
- **Fix:** with the walk cycles.

### SOUND-4 · MUST · Room tone everywhere; never digital silence
- **Why:** silence "is psychologically jarring" [AUDIO-FEEL-23]; zone beds crossfade at exits with random sweeteners [AUDIO-FEEL-24]; film ambience "never disappears" [AUDIO-FEEL-14]; INSIDE keeps audio playing through load with updates paused [AUDIO-FEEL-9]; Dead Space ambient tracks run 2-3 minutes [AUDIO-FEEL-28].
- **Target:** a bed per room (corridor HVAC, Records server fans, junction pumps), crossfaded at doorways, with sweeteners every ~5-10 s; ambience keeps sounding through knockdown and respawn with its state frozen.
- **Now:** NOT MET (no room beds; a `hum` loop exists).
- **Fix:** three beds and a sweetener player.

### SOUND-5 · MUST · Mix by loudness, not peak
- **Why:** "sample peak metering does not serve as a good indicator of the perceived loudness" (Sony ASWG-R001: home −24 ±2 LKFS, portable −18 ±2, true peak ≤ −1 dBTP) [AUDIO-FEEL-1]; [AUDIO-FEEL-21].
- **Target:** integrated loudness measured over a long representative capture; separate desktop and phone targets; true peak ≤ −1 dBTP.
- **Now:** NOT MET. Every clip is normalised to −6 dB peak, but loudness spans 12.4 LU (klaxon −9.1 LUFS, growl_refusal −21.5); true peak runs up to 0.7 dB above sample peak (measured twice, headless).
- **Fix:** gain-stage by LUFS; measure the mix from a render.sh recording (SOUND-13).

### SOUND-6 · MUST · Impacts that survive small speakers
- **Why:** phone, tablet and laptop micro speakers resonate at ~320-600 Hz and fall off below that (PUI Audio's 15 × 11 mm parts "below 600 Hz", 18 × 13 mm "320 Hz") [GAP-PASS-19]; the exact cut-off per device is UNVERIFIED; polish conveys weight [AUDIO-FEEL-22].
- **Target:** every big impact (tank, door, vent) has a layer above ~600 Hz (metal ring, debris; the ~1-4 kHz band is derived, not sourced). **Check:** in the container recording (SOUND-13), the share of each impact's energy above 600 Hz ≥ 30% (derived starting value; tune by ear on a phone).
- **Now:** NOT MET. `thud` has 99.3% of its energy below 150 Hz; `boom` 90.6% (measured).
- **Fix:** add the layers.

### SOUND-7 · MUST · Every essential sound has a visual twin, and a haptic one on phones
- **Why:** Godot's iOS default session is Ambient, silenced by the Ring/Silent switch, and Apple expects silent mode to silence game sounds [AUDIO-FEEL-5] [AUDIO-FEEL-29] [MOBILE-PERFORMANCE-7] [MOBILE-PERFORMANCE-23]; XAG 105 names players "with device sound off" [AUDIO-FEEL-7]; TLOU2's cues [AUDIO-FEEL-25]; pair audio cues with visual ones [PUZZLES-34]; [AUDIO-FEEL-20].
- **Target:** keep the Ambient category; every gameplay-essential sound (fuse, sentry alert, WOLF off-screen) also has a visual and, on phones, a haptic cue; a first-run note that sound is recommended.
- **Now:** PARTLY. Most cues have text or light twins (the striped blast zone, labels); no haptic cues except impacts.
- **Fix:** audit the essential cues; add haptic twins on phone.

### SOUND-8 · MUST · Separate volumes and a mono option
- **Why:** XAG 105 separates gameplay-critical effects from background ambience, lists 6 categories and asks for stereo-to-mono [AUDIO-FEEL-7].
- **Target:** Master, Music, Effects, Ambience and Voice sliders that each control the right sounds; a mono toggle.
- **Now:** PARTLY. Master, Music, Effects and Voice sliders exist, but every SfxBank player goes to the Effects bus (sfx_bank.gd:8, :163), so Music and Voice control nothing yet; no Ambience bus; no mono.
- **Fix:** route WOLF's growls to Voice and beds to a new Ambience bus; add mono. **Check:** in the container recording, fold L+R to mono and confirm no essential cue drops more than 3 dB (derived) and each slider moves only its own sounds.

### SOUND-9 · SHOULD · WOLF's voice on top of the mix
- **Why:** mixing is "a series of choices about what to hear at any particular moment" [AUDIO-FEEL-14]; Godot's compressor has a sidechain [AUDIO-FEEL-6].
- **Target:** a Voice bus that ducks Ambience, Music and Effects while WOLF speaks; choice growls audible over alarms (duck depth from any shipped game UNVERIFIED; tune by ear).
- **Now:** NOT MET. Choice growls sit ~8-12 LU under the klaxons (derived from clip LUFS and call gains).
- **Fix:** sidechain duck; raise the growls.

### SOUND-10 · SHOULD · Breath and effort for the engineer
- **Why:** the Dead Space remake's A.L.I.V.E. drives breathing and line states from adrenaline [AUDIO-FEEL-2]; INSIDE's breath sequencer: 1 breath per 2 steps, intensity from exhaustion, "useful for indicating proximity to danger" [AUDIO-FEEL-8] [AUDIO-FEEL-9].
- **Target:** calm, exerted, shaken and working states; breath locked to steps when jogging.
- **Now:** NOT MET (decided as a real-feel item).
- **Fix:** after footsteps.

### SOUND-11 · SHOULD · Mix snapshots and a death filter
- **Why:** default, ducking and override snapshots [AUDIO-FEEL-14]; 140's low-pass and echo "Death filter" masks transitions [AUDIO-FEEL-10]; INSIDE holds audio state through respawn [AUDIO-FEEL-9].
- **Target:** explore, WOLF speaks, action, sentry alert and death snapshots that crossfade; a low-pass filter for Cold Still instead of a cut.
- **Now:** NOT MET.
- **Fix:** with Cold Still.

### SOUND-12 · SHOULD · Let the machines be the score, and tie warnings to the logic clock
- **Why:** Limbo morphed foundry sound into orchestra [AUDIO-FEEL-11]; Dead Space's score plays at "room tone" level, mixed by fear emitters on enemies [AUDIO-FEEL-15] [AUDIO-FEEL-27] [AUDIO-FEEL-28]; 140's hazard rhythm "Must correspond exactly to game logic timing" [AUDIO-FEEL-10] [AUDIO-FEEL-26]; a ticking sound cued timed action [LOOP-PACING-17].
- **Target:** hums tuned to one key per room; a quiet music layer mixed by distance to threat; a survival stinger after the sentry; the fuse tick and the sentry sweep driven by the same clock as their logic.
- **Now:** PARTLY. The three hiss loops are locked together (audio notes); no fuse tick; no music ("No music or voice yet", credits).
- **Fix:** the fuse tick first (FAIL-4); the rest later. The music layer and the survival stinger are not covered by any decision (credits: "No music or voice yet"): Q18.

### SOUND-13 · SHOULD · Check audio without listening on Nathanial's Mac
- **Why:** INSIDE's 256-sample dropouts were "only detectable using audio recordings" and easy to spot in a spectrogram [AUDIO-FEEL-9]; Godot can record the Master bus [AUDIO-FEEL-26]; measure loudness over a long capture [AUDIO-FEEL-1].
- **Target:** record the Master bus inside the render container on a scripted route; check the spectrogram for gaps; measure LUFS and true peak.
- **Now:** NOT MET (the capture used the Dummy audio driver).
- **Fix:** add a recording option to the capture driver.

### SOUND-14 · SHOULD · Procedural sounds driven by the mechanism
- **Why:** treat "sound as a process, rather than as data" [AUDIO-FEEL-17]; [AUDIO-FEEL-16] [AUDIO-FEEL-18].
- **Target:** crank speed drives ratchet rate, gauge drives hiss blend, motor load drives pitch.
- **Now:** PARTLY (clips are generated at startup in 31-112 ms; their parameters are fixed).
- **Fix:** expose parameters to the game state.

### SOUND-15 · COULD · Cloth and idle sounds
- **Why:** INSIDE tracked a single elbow for cloth [AUDIO-FEEL-8]; Celeste stops idle sounds when the animation changes [AUDIO-FEEL-13].
- **Target:** one cloth brush per stride; idle sounds that stop on interruption.
- **Now:** NOT MET.
- **Fix:** later.

### SOUND-16 · COULD · Speaker-aware panning and the player's own music
- **Why:** Godot's default panning "is tuned for headphones" [AUDIO-FEEL-26] [AUDIO-FEEL-5]; Apple's Ambient category lets people play their own music [AUDIO-FEEL-29].
- **Target:** lower panning on speakers; mute the music layer when other audio plays (feasibility UNVERIFIED).
- **Now:** NOT MET.
- **Fix:** later.

---

## 11. Performance (PERF)

### PERF-1 · MUST · A steady frame rate on phones
- **Why:** uneven frame times read as stutter and add latency [MOBILE-PERFORMANCE-21]; Apple gives games priority at 30 and 60 Hz, and a 120 Hz request that can't keep up "may render poorly" [MOBILE-PERFORMANCE-22]; Godot 4.7.2 allows 120 Hz on ProMotion by default [MOBILE-PERFORMANCE-23] [MOBILE-PERFORMANCE-24]; Google's bar is 16 ms frames, and a session is slow when > 25% of frames exceed 50 ms [MOBILE-PERFORMANCE-11] [MOBILE-PERFORMANCE-26].
- **Target:** steady 60 fps on phones, a steady 30 fps battery option, never floating between 40 and 60; on phones offer only 30 and 60.
- **Now:** NOT MET. FPS options 30, 60, uncapped, 90, 120 and 144 on every platform (main.gd:1221-1226); never measured on a device.
- **Fix:** platform-specific options; measure on a phone.

### PERF-2 · SHOULD · Soak-test phones for heat
- **Why:** Apple's thermal states say to drop 60 to 30 fps and particles at "serious" [MOBILE-PERFORMANCE-28]; Google's ADPF guidance: test 15+ minutes and change settings gradually [MOBILE-PERFORMANCE-29] [MOBILE-PERFORMANCE-30].
- **Target:** 15+ minute runs from a cool and a warm phone; at iOS "serious" or Android headroom ~0.85-0.95, step down particles, then the floor reflection, then 60 to 30, only at a safe beat.
- **Now:** NOT MET (no device runs).
- **Fix:** after the first device builds.

### PERF-3 · SHOULD · A phone render budget per room
- **Why:** the frame-time bar above [MOBILE-PERFORMANCE-11] [MOBILE-PERFORMANCE-26]. Decided October 11: only the current room loaded; static light painted in; a phone render budget per room.
- **Target:** ≤ 16 ms per frame on the slowest target phone, with headroom (derived).
- **Now:** UNKNOWN on phones.
- **Fix:** measure each room as it is rebuilt.

### PERF-4 · COULD · Measure input latency before tuning engine settings
- **Why:** describe "the frame-by-frame path" of a button press; film it with a fast camera [CONTROLS-FEEL-9] [CONTROLS-FEEL-10]; physics interpolation "increases latency"; double-buffered V-Sync is not available on `gl_compatibility` [CONTROLS-FEEL-11].
- **Target:** written frame paths for MOVE and USE; press-to-pixel filmed on a Mac and a phone; only then consider physics above 60 Hz or `Input.set_use_accumulated_input(false)`.
- **Now:** NOT MET.
- **Fix:** later, once walk/jog ships.

### PERF-5 · COULD · Launch fast
- **Why:** people sometimes "don't want to wait more than a couple of seconds" [LOOP-PACING-15b]; Android expects feedback within 2 s of start [MOBILE-PERFORMANCE-11].
- **Target:** title interactive within ~2 s of the logo on a phone (derived).
- **Now:** UNKNOWN on phones. Desktop measured: launch to the first title frame 0.93-1.17 s on an M1 Pro (repo audit, docs/research-2026-10/data/audit.json `perf`); in the container the logo ran 2.0 s and the title buttons were drawn at 2.25 s (F-logo frames).
- **Fix:** measure on a device.

---

## 12. Accessibility (A11Y)

Accessibility needs that live in other areas: holds and toggle (FEEL-4), text size and backing (STORY-3, PHONE-4), touch targets (PHONE-1), sound twins and volumes (SOUND-7, SOUND-8), objective review (TEACH-4), hint options (PUZ-9).

### A11Y-1 · MUST · Player-controlled assists in the first slice
- **Why:** XAG 108: "ideally four or more" presets, change "at any time without losing game progress", per-mechanic assists, an ultra-low narrative mode, no names like "Wimp Mode" [FAILURE-DIFFICULTY-7]; game speed and bypass options [FAILURE-DIFFICULTY-19] [FAILURE-DIFFICULTY-35]; Celeste's "Cheat Mode" felt "judgmental" and was renamed [FAILURE-DIFFICULTY-9]; TLOU2's 5 presets plus Custom [FAILURE-DIFFICULTY-29] [FAILURE-DIFFICULTY-30]; Alien: Isolation still had to add Novice ~9 weeks after launch [FAILURE-DIFFICULTY-16] [FAILURE-DIFFICULTY-37].
- **Target:** game speed (50-100%), wider timing windows, hold-to-toggle, a calmer sentry, a Story assist (hazards only knock down), and a skip for the junction action beat that plays it as a short scripted sequence; all changeable any time, named without judgement.
- **Now:** NOT MET. Only Reduced Motion exists (game_settings.gd:212).
- **Fix:** an ASSIST tab (Q11). A Story assist interacts with the decided Secure the Evidence cost (unsecured evidence drops on death): Q11 asks whether evidence still drops under it. XAG 116's "up to at least ten times" rule for timed UI [GAP-PASS-10] is a sensible reach for game speed.

### A11Y-2 · MUST · Stay under photosensitivity limits
- **Why:** WCAG 2.3.1: no more than 3 flashes in any second above the area threshold [FAILURE-DIFFICULTY-27]; XAG 118: ~3 flashes per second, ~20% of the screen, saturated red; removal "is preferred over splash-screen warnings" [FAILURE-DIFFICULTY-36].
- **Target:** the impact flash, red wash, blast stripes and sentry alert never exceed 3 flashes per second or ~20% of the screen; no saturated full-screen red.
- **Now:** MET on a still-frame estimate (render.sh, two 180-frame 60 fps sequences of the fuse and blast knockdown, analysed at 640 × 360 against WCAG's definitions [GAP-PASS-14]): Reduced Motion off, the stripes reach up to 20 luminance transitions per pixel in a second, but the area flashing more than 3 times a second peaks at 2.4% of the screen and 10.2% of the worst 10° window (limit 25%); no saturated-red flash; the largest one-frame change covers 6.6% of the screen. Reduced Motion on: ≤ 7 transitions per pixel, 0.02% of a window. Not yet checked on a real display or phone, and only for the 1.0 s fuse (a longer fuse pulses longer). Cold Still has no flashes (MET by design).
- **Fix:** keep the measurement as a check (round2/tools/flash.py, render.sh `--name a11y-flash`) and rerun it whenever the fuse, stripes or impact flash change; slowing the stripes to ≤ 2 Hz is still worth doing if the fuse grows (P0-6).

### A11Y-3 · MUST · No essential information by colour or sound alone
- **Why:** Game Accessibility Guidelines (basic) [FAILURE-DIFFICULTY-19] [PUZZLES-19]; XAG 105 [AUDIO-FEEL-7]; AGENT.md pairs colour with a label, shape or motion.
- **Target:** every coloured state also changes shape, label or motion; every essential sound has a visual twin (SOUND-7).
- **Now:** PARTLY. Labels pair colour and text; the junction's yellow dashed bracket and plain cyan bracket differ by shape as well as colour, but the cyan one is never explained (M-0188).
- **Fix:** explain or remove the cyan bracket; check each state in a greyscale still. Round 2 colour-vision simulation (Machado et al. 2009, severity 1.0 [GAP-PASS-15]): the closest state-colour pairs fall from ΔE 34.6 to 16.4 (protanopia, GREEN/MARK_LIT), 17.2 (deuteranopia, AMBER/SEAM_RED) and 18.0 (tritanopia, GREEN/COOLANT); on frames the sentry's red sight beam almost vanishes for protanopia and deuteranopia (X-0297), and the red "BREAKER TRIPPED" label matches the other labels. Give the beam a light core or a dashed edge, and states a shape or icon. **Check:** rerun round2/tools/cvd.py on each round's stills (A11Y-10).

### A11Y-4 · MUST · Motion and shake switches
- **Why:** XAG 108 and the decided "shake and flash switches" [FAILURE-DIFFICULTY-7] [CONTROLS-FEEL-16].
- **Target:** separate shake and flash toggles, or one Reduced Motion that covers both and is described as such.
- **Now:** PARTLY. Reduced Motion exists and steadies the stripes (game_settings.gd:212; junction_room.gd:1248); measured: it cuts the stripes' transitions from up to 20 to ≤ 7 per pixel per second (X bursts). Its tooltip says "No camera shake or hit-stop; screen flashes are shorter" (game_settings.gd:208). No separate flash toggle.
- **Fix:** add a flash toggle or document what Reduced Motion covers.

### A11Y-5 · COULD · Tag interactables now for a high-contrast mode and audio cues later
- **Why:** "It was absolutely critical that we planned for these features so early"; every interactable "had to be tagged" [FAILURE-DIFFICULTY-30]; [FAILURE-DIFFICULTY-29] [PUZZLES-5] [PUZZLES-18].
- **Target:** every interactable and hazard carries a tag a high-contrast shader and a Ledge-Guard-style cue can use.
- **Now:** NOT MET.
- **Fix:** add tags as stations are rebuilt.

### A11Y-6 · COULD · Captions for important non-speech sounds, and an audio-cue assist
- **Why:** XAG 104's captions and separate bark toggle; Valve's HL2 captions covered "all game sounds" [NARRATIVE-IN-PLAY-8] [NARRATIVE-IN-PLAY-5]; TLOU2's traversal cues and off-screen speaker arrows [AUDIO-FEEL-25].
- **Target:** captions with direction for the alarm, the sentry whir and WOLF's growl; an optional ping when an interactable comes into reach.
- **Now:** NOT MET.
- **Fix:** later.

### A11Y-7 · SHOULD · Accessibility settings at first launch and from every menu
- **Why:** XAG 112: reachable "From the game's initial launch", for example as the first screen [GAP-PASS-7]; Apple: defaults from "the player's accessibility settings" [GAP-PASS-5].
- **Target:** MENU-5's first-launch screen, and the same rows under Settings from the title and from Pause.
- **Now:** NOT MET (MENU-5).
- **Fix:** with MENU-5.

### A11Y-8 · SHOULD · Timed text and timed UI can be lengthened
- **Why:** XAG 116: for text that times out on screen, players can lengthen it "up to at least ten times the length of the default limit", or turn it off [GAP-PASS-10].
- **Target:** a text-speed setting (1×, 2×, 4×, until dismissed) for the objective card (3.4 s today, main.gd:3203), toasts and auto-timed boxes (STORY-2); the fuse and the tank window are core-mechanic limits handled by A11Y-1's game speed and wider windows.
- **Now:** NOT MET.
- **Fix:** with A11Y-1.

### A11Y-9 · COULD · Menu narration through Godot's AccessKit support
- **Why:** XAG 106 screen narration [GAP-PASS-12]; Godot 4.5 added "screen reader support to Control nodes", still "in its experimental phase" [GAP-PASS-13]; the game runs Godot 4.7.2.
- **Target:** menus, settings and the end card readable by VoiceOver and Narrator.
- **Now:** UNKNOWN (not tried).
- **Fix:** a short test on Mac with VoiceOver by Nathanial or a tester.

### A11Y-10 · SHOULD · A colour-vision check every round
- **Why:** colour alone must not carry information [FAILURE-DIFFICULTY-19]; Machado et al.'s simulation matrices [GAP-PASS-15].
- **Target:** every state colour pair keeps ΔE ≥ 15 under protanopia, deuteranopia and tritanopia simulation (derived), and every hazard shape (the sentry beam) stays visible.
- **Now:** PARTLY: pairs stay ≥ 16.4 apart, but the sentry beam nearly vanishes under protanopia and deuteranopia (A11Y-3).
- **Fix:** run round2/tools/cvd.py on each round's stills.

### A11Y-11 · COULD · A plainer font option
- **Why:** players vary (Apple: "give players the ability to customize parameters like type size" [GAP-PASS-5]); no source opened in this pass shows a measured benefit for any particular "dyslexia" font (UNVERIFIED), so this stays an option, not a default.
- **Target:** an option to swap the display face (Montserrat) for the body face (Roboto) in all game text, with the text-size setting.
- **Now:** NOT MET.
- **Fix:** later.

---

## 13. Checking with real players (TEST)

### TEST-1 · MUST · First-time players, early and often, starting at the grey box
- **Why:** developers and players hold different mental models [PLAYTESTING-HUMAN-12]; "Get data early, get data often" [PLAYTESTING-HUMAN-1]; Playdead "learned so much just sitting and watching people" [PLAYTESTING-HUMAN-23] [PUZZLES-16]; "Teams often leave playtests too late" [PLAYTESTING-HUMAN-29]; Portal ran a fresh tester every week [PUZZLES-17] [ONBOARDING-7]; a solo designer goes "blind to the difficulty" [PUZZLES-15]; "Playtesting is just proof to you" [PUZZLES-33] [ONBOARDING-8]; [ONBOARDING-9] [ONBOARDING-38].
- **Target:** a fresh-tester round for every slice and after every repaint of a room with interactables; screenshot audits and agent passes never stand in for players.
- **Now:** NOT MET. No hands-on play of the slice by anyone; this study is built from scripted stills.
- **Fix:** run the first round now (PLAN.md P0).

### TEST-2 · MUST · Small repeated rounds, enough testers per platform
- **Why:** five users find ~85% of problems on average [PLAYTESTING-HUMAN-2], but an unlucky five found 55% [PLAYTESTING-HUMAN-8]; six people catch major understanding issues [PLAYTESTING-HUMAN-29]; RITE fixes between testers, then confirms [PLAYTESTING-HUMAN-27].
- **Target:** rounds of ~6 fresh testers (3 desktop keyboard, 3 phone); a slice is "readable" only after ≥ 10 fresh testers per platform (derived from the unlucky-five data in [PLAYTESTING-HUMAN-8]); the same failure in a 3rd or 4th group is a design bug [ONBOARDING-8].
- **Now:** NOT MET.
- **Fix:** see PLAN.md.

### TEST-3 · MUST · Watch in silence; survey before discussion
- **Why:** think-aloud can "Interfere with gameplay" [PLAYTESTING-HUMAN-1]; untrained prompting changes behaviour [PLAYTESTING-HUMAN-3]; Playdead asked nothing [PLAYTESTING-HUMAN-23]; retrospective think-aloud found fewer problems in twice the time [PLAYTESTING-HUMAN-28].
- **Target:** silence during the junction and sentry; think-aloud only in calm rooms; survey, then individual questions, then any group talk.
- **Now:** NOT MET.
- **Fix:** the protocol in topics/playtesting-human.md.

### TEST-4 · MUST · Test whether the story lands
- **Why:** open questions over "is this clear?"; "everyone only gets one shot" at a story [PLAYTESTING-HUMAN-11] [PLAYTESTING-HUMAN-10]; Portal asked testers "to tell us the story back" [ONBOARDING-7].
- **Target:** at the opening, the relay choice and END OF SLICE, ask "What was happening? Why? What did you expect next?"; never reuse a story tester.
- **Now:** NOT MET.
- **Fix:** add the three questions to the session sheet.

### TEST-5 · MUST · A timestamped observer log
- **Why:** "Importance of what people do—not what they say" [PLAYTESTING-HUMAN-1]; floating objects show up as stares [PLAYTESTING-HUMAN-5]; per-step funnels find invisible churn [ONBOARDING-42]; death clusters led to level fixes in Halo 3 [FAILURE-DIFFICULTY-28].
- **Target:** time to first move, USE and hold; every stop over ~30 s (proposal); every death with its cause and whether the tester can name it; missed inputs, and whether one read as WOLF refusing; stares at or comments on non-interactive objects; text read or skipped; each choice and its reason; time per mode (PACE-11).
- **Now:** NOT MET.
- **Fix:** a one-page sheet per session.

### TEST-6 · MUST · Rate severity with three people
- **Why:** "Severity ratings from a single evaluator are too unreliable"; the mean of three is "satisfactory" [PLAYTESTING-HUMAN-4].
- **Target:** 0-4 scale by three raters; fix all 3s and 4s before the next round; anything 2 of 6 testers call fake or floating is fixed first (proposal).
- **Now:** NOT MET.
- **Fix:** after each round.

### TEST-7 · MUST · Phone tests on testers' own phones
- **Why:** phone players are a separate group; iOS screen recording with the microphone and Android "Show taps" make missed touches visible [PLAYTESTING-HUMAN-17] [PLAYTESTING-HUMAN-18] [PLAYTESTING-HUMAN-30]; TestFlight and Play internal testing are free official channels [PLAYTESTING-HUMAN-19] [PLAYTESTING-HUMAN-20] [PLAYTESTING-HUMAN-21].
- **Target:** real phones held in the hand at default brightness, recorded with touches shown.
- **Now:** NOT MET (no phone build tested).
- **Fix:** after the first touch export.

### TEST-8 · SHOULD · A heuristic pass and a short survey
- **Why:** Desurvire's PLAY principles separated high- from low-ranked games (correlates, not causes) [PLAYTESTING-HUMAN-24] [PLAYTESTING-HUMAN-25]; Valve's 1-7 scales [PLAYTESTING-HUMAN-1].
- **Target:** 12 PLAY-derived checks before spending testers; 8 of them as a 1-7 survey ("I understood why WOLF did or didn't help"; "When I was knocked down, I knew what did it").
- **Now:** NOT MET.
- **Fix:** with the session sheet.

### TEST-9 · SHOULD · Logs are opt-in, local and separate
- **Why:** the public privacy page says the game has no telemetry; Valve's stats help but "Averages hide extreme examples" [PLAYTESTING-HUMAN-1]; death logs found Halo 3's bad deaths [FAILURE-DIFFICULTY-28].
- **Target:** playtest builds only; logs stay on the device until the tester sends them; recordings of testers never enter the repo.
- **Now:** NOT MET (not built).
- **Fix:** Q12.

### TEST-10 · SHOULD · Recruit beyond people who already know the story
- **Why:** community members are "less-ideal participants"; story testers should play "the right kind of narrative games" [PLAYTESTING-HUMAN-10] [PLAYTESTING-HUMAN-11].
- **Target:** per round, ≥ 2 testers who have finished a side-view narrative game and ≥ 1 who rarely plays; a list of who played which build.
- **Now:** NOT MET.
- **Fix:** recruit outside the Discord.

### TEST-11 · COULD · Steam Playtest for larger desktop rounds
- **Why:** free and separate from a store page, but "Collecting feedback from players is up to you" [PLAYTESTING-HUMAN-22].
- **Target:** once a store page exists.
- **Now:** NOT MET (no store page yet).
- **Fix:** later.

### TEST-12 · COULD · Watch the watcher
- **Why:** "the people standing around watching the game have also got to be able to enjoy it" (Miyamoto) [PLAYTESTING-HUMAN-26].
- **Target:** note whether a second person watching stays engaged.
- **Now:** NOT MET.
- **Fix:** add to the sheet.

---

## 14. Controller (CTRL)

Added in round 2: the game ships joypad play, rebinding, a stick deadzone and rumble, and Mac and Windows are the first targets. Evidence: route C (headless and render.sh, injected joypad events; [CAPTURE-ROUND2.md](playthrough/CAPTURE-ROUND2.md)) and [topics/gap-pass.md](topics/gap-pass.md) §1.

### CTRL-1 · MUST · Everything reachable with a controller alone, with B as Back
- **Why:** Steam Deck Verified: the default controller configuration "must provide users with the ability to access all content" with no setting changed [GAP-PASS-3]; XAG 112: the UI "fully navigable by keyboard and controller digital input alone", "'A' to select, 'B' for back" [GAP-PASS-7]; Apple: A activates, B returns, Menu pauses [GAP-PASS-2]; XAG 113: focus always visible and never on an off-screen element [GAP-PASS-8].
- **Target:** every menu button reachable by D-pad from where focus lands; B backs out of every overlay; START pauses from every state.
- **Now:** PARTLY. The title focuses NEW GAME and A starts it; Pause focuses RESUME; one D-pad down reaches SETTINGS; B closes Settings (route C). **In Settings › CONTROLS, D-pad down cycles the eight rebinding rows, the deadzone slider and RESET and never reaches BACK; up goes to the tab bar** (C-0185, probe `pad_menu`). Not tested: the credits and changelog screens by pad.
- **Fix:** make BACK the focus neighbour below RESET (and wrap); show "B BACK" on every overlay. **Check:** a headless focus-walk test from each overlay's first focus to every button (PLAN P1-14).

### CTRL-2 · MUST · Prompts match the controller in the player's hands
- **Why:** "On-screen glyphs must match the inputs being used" and keyboard glyphs hidden when not active [GAP-PASS-3]; "use the connected controller's labeling scheme"; "Prefer using symbols, not text" [GAP-PASS-2].
- **Target:** prompts switch to the pad on its first press and back on a key press (already true); they show the pad's own symbols (Xbox A/B/X/Y, PlayStation ✕/○/□/△, Nintendo layout) as glyph images.
- **Now:** PARTLY. Prompts switch device correctly and the approved death prompts already use the device path (DEATH_CONTINUE_CONTROLLER), but they are letters ("A READ DISPLAY", "X The relay may vent coolant", "HOLD A: crank", C-0052, C-0069, C-0098; game_settings.gd:495-501), wrong on PlayStation and Switch pads.
- **Fix:** read `Input.get_joy_name()` and map to a glyph set; keep letters as the fallback. **Check:** headless test per joypad name → glyph set; stills (route C).

### CTRL-3 · SHOULD · Rumble that can be turned down, never the only cue
- **Why:** XAG 110: turn haptics off and "Adjust the strength", and never the only channel [GAP-PASS-6]; Microsoft: the left motor is low-frequency and the right high-frequency, set independently [GAP-PASS-1].
- **Target:** a rumble strength slider (0-100%) beside the on/off; every rumble has a sound and a visual twin.
- **Now:** PARTLY. Rumble is logged on 10 beats in route C (cage release 0.5/0.9 for 0.25 s, blast 0.7/1.0 for 0.3 s, breaker 0.15/0 for 0.06 s ...), all with a sound and a visual; there is no strength setting.
- **Fix:** add the slider to Settings › CONTROLS.

### CTRL-4 · SHOULD · Use the stick's analog range for walk and jog
- **Why:** XInput's left-stick dead zone is 7849/32767 ≈ 0.24 and the range past it should be rescaled to 0-1, optionally on a curve for "more precision in the lower ranges" [GAP-PASS-1]; walk-then-jog is decided (FEEL-3).
- **Target:** keep the 0.25 default (≈ XInput's); map partial tilt to the walk band and full tilt (after FEEL-3's ~0.5 s) to jog.
- **Now:** measured: speed = 190 × (|v| − 0.25) / 0.75 px/s (0.3 → 12.7, 0.5 → 63.3, 0.8 → 139.3, 1.0 → 190); there is no walk/jog split yet.
- **Fix:** with FEEL-3. **Check:** the same headless analog sweep.

### CTRL-5 · SHOULD · Holds on a face button, with the same toggle
- **Why:** XAG 107's hold limits and the toggle (FEEL-4) apply to every device [CONTROLS-FEEL-25].
- **Target:** hold-to-crank on A works and the hold-to-toggle option covers the pad.
- **Now:** PARTLY. Holding A cranks the bypass and the valve, and progress survives a release (C-0098 to C-0108); no toggle yet (FEEL-4).
- **Fix:** with FEEL-4.

---

## 15. Front end and session flow (MENU)

Added in round 2. Evidence: route F, which started from `studio_logo.tscn` like a real launch (render.sh), and route X's focus-loss test; [topics/gap-pass.md](topics/gap-pass.md) §2.

### MENU-1 · MUST · An interactive title within a couple of seconds
- **Why:** "Launch instantly ... sometimes they don't want to wait more than a couple of seconds" [GAP-PASS-4] [LOOP-PACING-15b]; Android expects feedback within 2 s [MOBILE-PERFORMANCE-11].
- **Target:** title buttons usable ≤ ~3 s after launch on desktop (derived from Apple's "couple of seconds" plus a 2 s logo); any press skips the logo once the title is ready.
- **Now:** MET on desktop: the repo audit measured launch to the first title frame at 0.93-1.17 s (M1 Pro); the logo runs 2.0 s and the buttons are drawn at 2.25 s, the wordmark by ~3.0 s (F-logo-00.25s to 03.50s); presses skip it (changelog, October 12). Phones UNKNOWN (PERF-5).
- **Fix:** keep it; measure on phones.

### MENU-2 · MUST · A way to quit from the desktop title
- **Why:** on Windows and Steam Deck the game's own menu is how players leave (derived; no platform rule opened, so UNVERIFIED as a requirement); Steam Deck asks for full controller navigability of everything the player needs [GAP-PASS-3].
- **Target:** a QUIT button on the desktop title (hidden on iOS, where apps do not quit themselves; Android keeps Back).
- **Now:** NOT MET. The title has NEW GAME, CONTINUE, CREDITS, SETTINGS and CHANGELOG (main.tscn:542-583; F-0003). Esc on the bare title does nothing (main.gd:1421-1438); Android Back quits from the bare title (main.gd:1468-1469); otherwise only closing the window.
- **Fix:** add QUIT on desktop builds. **Check:** headless test that QUIT exists on desktop and not on iOS (PLAN P1-15).

### MENU-3 · MUST · Continue says where it resumes
- **Why:** "Restore the previous state ... Avoid making people retrace steps" [GAP-PASS-4]; quick resume after interruptions [MOBILE-PERFORMANCE-11].
- **Target:** CONTINUE names the place (for example "Service junction, entrance"); after loading, one line says what was reset.
- **Now:** PARTLY. Quitting mid-junction (breaker armed, line building, x 248) and pressing CONTINUE puts the engineer at the junction entry (x 120) with the line idle and says "Service junction restored. Arm the breaker by the entrance, then crank the valve." (F-0182 → F-0188): honest, ~5-10 s of replay. The title's CONTINUE gives no place (F-0185).
- **Fix:** add the place to the CONTINUE button's note.

### MENU-4 · SHOULD · Say what New Game does to the old save
- **Why:** XAG 115: before stored data changes, let players review or reverse it [GAP-PASS-9].
- **Target:** with a save present, NEW GAME's note says the checkpoint is kept until the new run's first safe point.
- **Now:** PARTLY. The behaviour is already safe: New Game and PLAY AGAIN keep the old save "until the new run reaches its first SAFE POINT" (main.gd:574-575), but nothing on screen says so; after the slice the title reads "Slice complete. PLAY AGAIN starts a fresh run." (F-0250).
- **Fix:** one line under NEW GAME when a save exists.

### MENU-5 · SHOULD · Ask for the few settings that matter at first launch
- **Why:** XAG 112: accessibility settings reachable "From the game's initial launch", for example as the first screen [GAP-PASS-7]; Apple: "Provide great default settings ... and the player's accessibility settings" [GAP-PASS-5].
- **Target:** on first launch only, one screen with text size, subtitles/speaker names, Reduced Motion and "sound recommended"; skippable in one press.
- **Now:** NOT MET (no first-launch prompt; Settings has no text-size row; F-0025).
- **Fix:** after STORY-3's text-size setting exists.

### MENU-6 · SHOULD · Pause from every state, including focus loss
- **Why:** pause on resign-active [MOBILE-PERFORMANCE-31]; XAG 116 for timed beats [GAP-PASS-10].
- **Target:** Pause (key, START, the on-screen button, focus loss) works during choices, the fuse, the chase and the knockdown card, and freezes their timers.
- **Now:** PARTLY. Measured: focus-out mid-fuse pauses at once and freezes the fuse (X-0266, X-0267); Pause in the opening offers SKIP OPENING (F-0030). Pause during a choice and during a chase was not tested.
- **Fix:** add both to the route-X capture.

---

## 16. Desktop display (DISPLAY)

Added in round 2. Evidence: route S (render.sh, the paused game resized to each window) and the repo's measured perf audit; [topics/gap-pass.md](topics/gap-pass.md) §3.

### DISPLAY-1 · SHOULD · Fill 16:10 screens, or choose the bars on purpose
- **Why:** Steam Deck's screen is 1280 × 800 and Valve prefers 1280 × 800 [GAP-PASS-3]; MacBooks are 16:10; Godot's `expand` aspect fills other ratios [MOBILE-PERFORMANCE-44].
- **Target:** one decision for desktop and phone together (PHONE-6): `expand` with the HUD anchored to a safe 16:9 core, or keep the letterbox deliberately.
- **Now:** measured: 1280 × 800 → 40 px bars top and bottom; 1440 × 900 → 45 px; 2560 × 1600 → 80 px (10% of the screen each time); 960 × 540 and 1920 × 1080 fill the screen (S-0062 to S-0066).
- **Fix:** decide with PHONE-6; recheck the same stills.

### DISPLAY-2 · MUST · Smallest text above the platform floors
- **Why:** Steam Deck: the smallest character "should never fall below 9 pixels in height at 1280x800" [GAP-PASS-3]; Apple: macOS game text 13 pt default, 10 pt minimum [GAP-PASS-5].
- **Target:** at a 960 × 540 window, nothing below 13 px; at 1280 × 800, nothing below ~12 px of glyph height.
- **Now:** MET for the platform floors (labels 13 px at 960 × 540 are 17.3 px at 1280 × 800; dialogue 17 px is 22.7 px), but the hint and label sizes are still below STORY-3's subtitle target.
- **Fix:** with STORY-3.

### DISPLAY-3 · SHOULD · Steady frame pacing on 60, 120 and 144 Hz desktops
- **Why:** uneven frame times read as stutter [MOBILE-PERFORMANCE-21]; the FPS options go up to 144 on every platform (main.gd:1221-1226).
- **Target:** at each FPS option on a 60 Hz and a 120 Hz (ProMotion) display, frame times within ±1 ms of the target 95% of the time (derived); the 60 cap reaches 60.
- **Now:** UNKNOWN. The repo audit measured huge headroom (worst p95 2.95 ms at 1920 × 937) but read 44-51 fps under the shipped 60 cap plus V-Sync with the screen locked, which it marks unverified (docs/research-2026-10/data/audit.json `perf`).
- **Fix:** a hands-on run on an awake Mac (Nathanial's, or a tester's) with Godot's frame-time monitor; never on Nathanial's Mac by an agent.

---

## 17. Evidence case (CASE)

Added in round 2 for the decided case (save v5; decided, not built). The 25-game study already set its targets (design-reference-25-games.md §5); they are carried over here rather than re-researched. The eight approved items (docs/research-2026-10/approved/item-text-2026-10-09.json, key `final`) and their examine-text lengths with "Rowan": PURGE-ORDER TRACE 115, MIRROR TIMESTAMP 115, DATA CARTRIDGE 99, RELAY WORK ORDER 121 (four lines, longest 37), LOCKOUT TAG 112, CRACKED GAUGE 104, SENTRY PATROL LOG 99 (four lines, longest 36), WHEEL RATCHET 123. Names are 11-17 characters (limit 24).

### CASE-1 · MUST · Open from Pause only, by tap or press, never during a hazard
- **Why:** the study's targets: a fixed list of ≤ ~6 plus one tool, no grid, no sustained holds to open or examine ("tap from Pause"), secured records never lost (Signalis, Resident Evil, LN2 and Lana criticism) (design-reference-25-games.md §5).
- **Target:** the case opens only from Pause (so time is frozen), in one press, within ~0.2 s (derived); closes with B, Esc or the on-screen back.
- **Now:** NOT MET (not built).
- **Fix:** build with save v5.

### CASE-2 · MUST · Inspect text readable on a phone
- **Why:** XAG 101 sizes for body text [MOBILE-PERFORMANCE-19]; Apple's 17 pt default and 11 pt minimum [NARRATIVE-IN-PLAY-33]; subtitle line lengths of 37-42 characters [NARRATIVE-IN-PLAY-1].
- **Target:** player-paced panels of ≤ 3 lines of ≤ 42 characters per page at the default size (each approved text fits: 99-123 characters is 3 lines), paging at larger text sizes; the same text-size setting as STORY-3.
- **Now:** NOT MET (not built).
- **Fix:** with CASE-1. **Check:** headless page count per item at 100% and 200% text size.

### CASE-3 · SHOULD · Touch, controller and keyboard navigation
- **Why:** rows ≥ 44 pt on touch [GAP-PASS-2]; D-pad and B behaviour and visible focus [GAP-PASS-7] [GAP-PASS-8].
- **Target:** list rows ≥ 44 pt tall on phones; D-pad moves, A opens, B closes; focus ring always visible.
- **Now:** NOT MET (not built).
- **Fix:** with CASE-1.

---

## 18. Readable image (READ)

Added in round 2 (topic 12: [topics/readable-image.md](topics/readable-image.md)). "Look real" also means the characters read against the rooms, the depth layers behave and one light ties it together. The project's art bible already sets the numbers; these needs make them checks on the rendered game.

### READ-1 · MUST · Characters separate from the background by value, not only by hue
- **Why:** WCAG 1.4.11 asks 3:1 for "Parts of graphics required to understand the content" [READABLE-IMAGE-4]; art-bible.md §3.7 sets median contrast ≥ 1.6:1, ≥ 30% of the perimeter (rim side) at ≥ 3:1 and lost edge ≤ 35%, and §3.2 a body L* ≥ 12 above the walk band; Ori's artists kept a layered look "very readable ... at the service of the gameplay" [READABLE-IMAGE-3].
- **Target:** art-bible §3.7's numbers, measured on render.sh frames of every room each round.
- **Now:** NOT MET. Measured on seven desktop frames (round2/tools/contrast.py): engineer 1.17-1.59:1, WOLF 1.16-1.69:1, median ~1.3:1; only WOLF in D-0048 reaches 1.6:1. The audit's October 10 reading was 1.01-1.18:1.
- **Fix:** the art bible's lighting (READ-2) and value bands; keep the walk band of the mid plate at L* ≤ 10. **Check:** contrast.py on each round's stills, plus the greyscale still (PLAN P1-16).

### READ-2 · MUST · One light logic: actors top-lit and rimmed like the props
- **Why:** art-bible.md §3.3 (overhead strip lamps every 300-400 px; actors top-lit, rim 4-8 source px; cold blue-black shadows) and REAL-LOOK.md §3 item 2 ("one light logic"); INSIDE authored diffuse, specular and bounce light separately with analytic ambient occlusion [READABLE-IMAGE-1].
- **Target:** actors' top-rim lightness above their core (the bible's C_top_light_dL > 0), matching the props' +3.9 to +5.9.
- **Now:** NOT MET. The bible measured Rowan −12 and WOLF −12.9 ("unlit cut-outs"); the repaint batches are not built.
- **Fix:** the bible's batches; one character first, in the real game.

### READ-3 · SHOULD · Three depth bands that never cover the play
- **Why:** the art bible's ordering (far lightest and lowest contrast, mid carries play, near darkest) [art-bible.md §3.2]; Ori gave each graphic its own "lighting, color, and movement sets" [READABLE-IMAGE-2]; motion settings [GAP-PASS-11].
- **Target:** far plate parallax ~0.3-0.5 × camera, near pieces ~1.2-1.5 × and only at room edges, never over an actor or station (derived); Reduced Motion locks parallax to 1.0.
- **Now:** UNKNOWN in motion (stills only); the rooms are one view wide today, so parallax barely shows.
- **Fix:** in the room expansion; still strips and hands-on.

### READ-4 · SHOULD · WOLF's pose readable at phone size
- **Why:** WOLF's body carries his answers (WOLF-5, WOLF-11, STORY-12); art-bible.md §3.7's silhouette test at 94 and 188 px; Ori and Somerville chose small figures for scale [READABLE-IMAGE-2] [GAP-PASS-28].
- **Target:** a reviewer names WOLF's state (calm, refusing, working, afraid) from a phone-size still in 2 s, 4 of 4 (derived from the bible's silhouette test).
- **Now:** UNKNOWN (one pose exists). At zoom 1.35 on an iPhone 16 he is ~8.5 mm tall.
- **Fix:** with PHONE-13 and WOLF-13.

---

## 19. Credits and licences (CRED)

### CRED-1 · MUST · Ship the Godot licence and its third-party notices
- **Why:** Godot: "the only requirement is to include the license text somewhere in your game", with the line "Copyright (c) 2014-present Godot Engine contributors. Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur." and the third-party notices (`COPYRIGHT.txt`, `Engine.get_license_info()`) [GAP-PASS-17].
- **Target:** a LICENCES screen (or the end of the credits) with Godot's MIT text, its third-party notices and the SIL OFL notices for Roboto and Montserrat; the same on the site's credits page.
- **Now:** NOT MET. The in-game credits list "Godot 4.7.2 / GDScript" under BUILT WITH, with no licence text (main.tscn:651); apps/docs/content/docs/credits.mdx has none either.
- **Fix:** add it before any distributed build (PLAN P0-20; the site and in-game credit edits are proposals for Nathanial).

### CRED-2 · SHOULD · Credit the research references in the public credits
- **Why:** AGENT.md and the October 12 request ("give credits"); the in-game credits name ~7 references and none of the 378 + round-2 entries.
- **Target:** a short, spoiler-safe "Research references (October 2026)" list of the most-cited primary sources on the site's credits page, linking to the full list once the research folder is copied into docs/research-2026-10, and one matching line in the in-game credits.
- **Now:** NOT MET.
- **Fix:** proposal for Nathanial's approval (PLAN P1-17).

---

## 20. Localization (LOC)

### LOC-1 · COULD · Leave room for translation, if any language is planned
- **Why:** W3C (Ishida, citing IBM): English strings of 11-20 characters grow 180-200% in translation, 31-50 → 140-160%, over 70 → 130%; "avoid small fixed-width containers" [GAP-PASS-16].
- **Target (only after Q19):** a pseudo-localization headless test that lengthens every string by 30-40% (and short labels by 100%) and checks the 42-character column, the 24-character item names and every button; a glyph-coverage check of the bundled fonts for the chosen languages.
- **Now:** NOT MET. No decision records target languages. The 11-17-character item names would run ~20-34 characters (over the 24 limit). Roboto covers Latin, Greek, Cyrillic and Vietnamese; Montserrat Latin, Cyrillic and Vietnamese; neither has CJK, Arabic, Hebrew, Devanagari or Thai; Roboto lacks ◀ ▶ (fc-query).
- **Fix:** Q19 first.

---

## Where this disagrees with design-reference-25-games.md

The 25-game study (docs/research-2026-10/design-reference-25-games.md) still holds on most points; the topics confirm it with primary sources (companion follows rather than leads, nagging, no persistent HUD, contact shadows, walk-through doorways, visible contact before WOLF's effects, toggles over auto-complete, near-instant retry). These are the places where the new research disagrees, refines or corrects it. Each is argued in its topic note.

1. **"≤ 3.7 s of walking without a beat"** was computed at 190 px/s. Under the decided walk-then-jog a held crossing of one view is ~4.0 s, but a player tapping at walk takes ~8.9 s. State the rule in player seconds (5-10 s), trigger by position, and count authored quiet as a beat (PACE-1; loop-pacing, onboarding).
2. **"Width only if every view carries a beat"**: a beat can be a story vignette or a readable service element, not only an interaction (PACE-1, SPACE-15; level-architecture).
3. **"Two readable approaches per wide room"** should stay inside one reliable order of events (PACE-10; loop-pacing).
4. **Tank-drop windows of 0.63 s / 0.38 s are stale.** With `HIT_RANGE` 24 they are ~0.34 s / 0.21 s (PUZ-6; loop-pacing, failure-difficulty).
5. **"Secure action: hold USE ~1-3 s"**: XAG 107 treats holds of 2-3 s or more as a barrier; keep holds ≤ ~2 s (secure hold ≤ 1.5 s) or offer a toggle (FEEL-4; controls-feel, failure-difficulty).
6. **No easy or assist mode.** XAG 108, the Game Accessibility Guidelines, Celeste, TLOU2 and Alien: Isolation all argue for assists in the first slice (A11Y-1; failure-difficulty).
7. **Fresh-tester readability tests under "Later".** The evidence puts them now and after every repaint (TEST-1; puzzles, playtesting-human).
8. **Stuck players: the engineer-only path as the primary fallback.** That path answers WOLF refusing, not a player who doesn't understand the chain; puzzles need their own hint ladder (PUZ-8; puzzles).
9. **Scale is missing.** The art bible's 136-144 px door family is ~2 × the engineer, freight or blast scale (SPACE-10; level-architecture).
10. **Stairs are missing.** level-expansion.json's ~18° stair is outside both stair and ramp ranges (SPACE-13; level-architecture).
11. **"Input to WOLF acknowledgement: no source gives seconds."** Nielsen's 0.1 s and 1 s limits (general HCI, used as a ceiling) and the Last Guardian reception give a target (WOLF-5; companion-play, controls-feel).
12. **Stale current-state rows.** `FOLLOW_GAP` is 88, not 64; SfxBank has 6 voices and 7 loops, not 4 and 4 (WOLF-16, SOUND-1).
13. **Elizabeth's teleport is listed without its counterpoint.** Naughty Dog refused teleports; others teleported only where unseen. So: no on-camera teleport (WOLF-4; companion-play).
14. **"Visible, anchored controls are safer."** Apple and the Game Accessibility Guidelines endorse a stick that appears under the thumb; Limbo's failed because it was invisible (PHONE-8; mobile-performance).
15. **INSIDE iOS at 30 fps as the model.** Target a steady 60 with 30 as a fallback (PERF-1; mobile-performance).
16. **"Respawn never breaks audio, 0 ms gap"** is refined: keep the ambience sounding and freeze its state (SOUND-4; audio-feel).
17. **"Turn it Down 90%"** is a Playdead visual-effects talk, not an audio one (FEEL-9; audio-feel, controls-feel).
18. **"Persistent HUD 0"** needs a floor: XAG 109 asks for objectives reviewable at any time, so put the objective on the pause screen (TEACH-4; onboarding, playtesting-human).
19. **"≲ 20 s replay"** suits later rooms; in the first ~5 minutes, no unreadable deaths at all (TEACH-3; onboarding).
20. **No dialogue-delivery targets** (reading speed, line length, text size). Added in STORY-2, STORY-3 and STORY-10 (narrative-in-play; genre-fan review).
21. **"Track treatment silently and show it as behaviour"** is incomplete: acknowledge at once and call back later (STORY-5; narrative-in-play).
22. **Critics' review quotes as player evidence.** They are hypotheses to test with WOLF//OVERRIDE's own players (TEST-1; playtesting-human).
23. **Route screenshot QA** helps with regressions but cannot replace watching players, and needs the 100% zoom checklist (SPACE-7; playtesting-human).
24. **"Music only at authored beats"** holds for melodic cues, but Dead Space ran a room-tone-level score throughout (SOUND-12; audio-feel).
25. **"Visible, anchored controls are safer" also needs a pad.** The study had no controller targets; Steam Deck Verified and Apple ask for full controller reach and matching glyphs (CTRL-1, CTRL-2; gap-pass).
26. **Flip-screen to scroll, now sourced.** The study listed it as uncovered; New 'n' Tasty's lead says the scrolling camera lets players "see farther in front" and change course without dying, which supports look-ahead (FEEL-6) and seeing a hazard before it acts (PUZ-5) (gap-pass §10b).
27. **"No speaker-specific mix targets" is partly filled.** Micro speakers resonate at ~320-600 Hz (manufacturer sheet), so impacts need energy above ~600 Hz (SOUND-6); laptop targets are still open.
28. **The CASE targets are carried over, not changed** (≤ ~6 plus one tool, no grid, tap from Pause, 0 secured records lost); round 2 adds the inspect-text and navigation targets the study did not have (CASE-1 to CASE-3).

## Gaps from the 25-games study: ledger

The study listed what no input covered (design-reference-25-games.md, header and §8-9). Where each stands after round 2:

| Gap the study listed | Status | Where |
|---|---|---|
| Camera look-ahead values (Keren's "Scroll Back", GMTK) | **Filled** in round 1: Keren's talk and article are cited in FEEL-6 [CONTROLS-FEEL-1] [CONTROLS-FEEL-2]; New 'n' Tasty adds support in round 2 | FEEL-6, FEEL-7 |
| Touch target sizes | **Filled** (Apple 44 pt, Android 48 dp, thumb studies, XAG 107) | PHONE-1 |
| Procedural-audio technique sources (Farnell, Weir) | **Filled** in round 1: [AUDIO-FEEL-17] (Farnell) and [AUDIO-FEEL-18] (Weir, No Man's Sky) are cited in SOUND-14 | SOUND-14 |
| Flip-screen-to-scroll lessons (New 'n' Tasty, Flashback remake) | **Partly filled:** New 'n' Tasty (Gilray) in round 2; Flashback 2018 not found | FEEL-6, PUZ-5 |
| Dead Space's ALIVE breathing | **Filled** in round 1 [AUDIO-FEEL-2] | SOUND-10 |
| Speaker-specific mix targets for laptops or phones | **Partly filled:** phone/tablet micro-speaker resonance (PUI Audio); laptop response still open | SOUND-6 |
| Somerville and Flashback cards | **Partly filled:** Somerville via one review (pulled-back scale shots); no developer interview found; Flashback open | READ-4, PHONE-13 |
| Oddworld card | **Partly filled:** New 'n' Tasty camera only | FEEL-6 |
| Unravel and Gris cards | **Open:** searched, no primary source on readability or layering found | readable-image §4 |
| Mobile ports | **Filled** in round 1 (Limbo iOS, INSIDE iOS, Planet of Lana patches, Dead Cells) | PHONE-8 to PHONE-15 |
| Robot or dog companion cards beyond Stray | **Partly filled:** The Last Guardian's command responsiveness (Game Informer review, Ueda via Edge); no robot-dog game card | WOLF-5, WOLF-11 |
| Silent Hill 2 | **Open:** not researched in either round | none |
| Session-length data | **Filled** in round 1 | PHONE-11 |
| The truncated audio synthesis and companion gap dossier | **Superseded** by the round-1 audio-feel and companion-play topics | section 6, section 10 |

## Against the recorded decisions

The recorded decisions are in docs/decisions.md and docs/research-2026-10/README.md (October 8-11). The research **supports** most of them: walk-then-jog movement (FEEL-3); the Cold Still death screen with control at ~1.5 s and no flashes (FAIL-2, A11Y-2); Secure the Evidence with key records that never drop (FAIL-10); WOLF never rescues, refuses rarely and meaningfully, and is shown off screen by sound plus an edge marker (WOLF-6, WOLF-10, WOLF-11); full-strength impact effects only for big moments, with switches (FEEL-9, A11Y-4); doors as a shutter across the corridor, walk-through doorways, and nothing floating (SPACE-1 to SPACE-3); grey boxes phone-tested before paint (PACE-5); mobile as a first-slice target (section 9); the required stakes line and the END OF SLICE recap (STORY-5, PACE-9).

The research also **supports** a direction already in PROJECT_CONTEXT.md: WOLF's self-awakening should be "legible from the engineer's viewpoint". Today's opening shows the Director and WOLF with no engineer for ~41 s (TEACH-1), which works against that recorded direction; Q2 now names each option's cost.

It **pushes back** on these, each turned into a question below:
- The MANUAL BYPASS's "few seconds of hold-to-crank" (October 10) is 3.2 s, above XAG 107's line (Q1).
- "No player request verb yet" for WOLF: research supports hints on request, with mixed data (Q3).
- The default tank hit rule ("its body overlaps the brackets") with ~0.34 s / 0.21 s windows (Q7).
- The art bible's 136-144 px door family for personnel doors (Q8) and level-expansion.json's ~18° stair (Q9).
- The decided Settings terminal look shows developer lines to players (Q10).
- The public "no telemetry" privacy statement versus death logs for playtests (Q12).
- **The approved death-card set** (docs/research-2026-10/approved/death-text-2026-10-10.json, key `final`): DEATH_CARD_SENTRY reads "The sentry caught %s in the lane. It did not slow.", and "lane" names nothing drawn (TEACH-5); its approved alternative "The sentry caught %s short of the rubble." names the drawn rubble (Q16). (An earlier draft read "ran %s down in its lane"; the final text is the one above.) The "2.4 s first death, 0.8 s repeat" input delay appears only in a draft note, not in the final entries, and conflicts with Cold Still (RETRY at 0.9 s, control at ~1.5 s) (Q17).
- **The approved round-4 corridor shutter** is in the art bible's 136-144 px family; SPACE-10's personnel-door scale (84-98 px) would change it, so P1-1 waits for Q8. SPACE-12's two-door vestibule is for later sealed areas and does not replace the single approved shutter.
- **Design C's standby dock** (October 11): Q2's "start in the corridor" option would drop or move the dock scene and its opened, empty bay.
- **A Story assist** (A11Y-1) would interact with the decided Secure the Evidence cost (Q11).
- **Music:** no decision covers a music layer or a survival stinger; the credits say "No music or voice yet" (SOUND-12, Q18).
- **WOLF-only abilities** (WOLF-15) must stay optional or faster routes: AGENTS.md requires an engineer-only fallback for essential progress.

## Questions for Nathanial

These touch recorded decisions (docs/decisions.md, docs/research-2026-10/README.md, the approved text files) or his story. Q15-Q19 were added in round 2. His latest decision wins; each is framed as a question with what the research suggests.

- **Q1. MANUAL BYPASS hold length.** Decided October 10: "a few seconds of hold-to-crank". Today it is 3.2 s; XAG 107 flags holds of 2-3 s or more. Keep the cost in the alarm and hiss, and shorten the hold to ~2 s with a toggle option? (FEEL-4)
- **Q2. The opening.** 7 beats, ~41 s before control, and the engineer isn't in it; PROJECT_CONTEXT.md already asks that WOLF's self-awakening be "legible from the engineer's viewpoint". Options and their costs: (a) **show Rowan at the doorway** watching the awakening: keeps design C's standby dock and fits the recorded viewpoint direction; (b) **merge beats** to reach control in 30-45 s: keeps everything, cuts words; (c) **start in the corridor** and let the awakening be heard and seen from there: fastest to control, but drops or moves the dock scene, so should the opened, empty bay be seen later instead? Until you decide, the existing Pause › SKIP OPENING can be pointed out on the first box. (TEACH-1, STORY-11)
- **Q3. Asking WOLF for a hint.** Recorded: "no player request verb yet". Keep that for this slice and revisit only if testers stall at one node? (WOLF-17)
- **Q4. Labels over machines.** The newcomer found them helpful; the genre fan read them as a debug overlay; the 25-game study targets 0 persistent HUD. Replace them with mounted name plates plus the in-range prompt, objective on the pause screen, and an optional "station labels" setting? (PUZ-3)
- **Q5. How much to say.** 46 dialogue texts in ~3.5 minutes. Which lines can become pictures (the blue light, the Director freezing, the surge)? Line rewrites need your approval. (STORY-7, STORY-10, STORY-11)
- **Q6. The junction entry line.** Rowan states the whole chain ("Overload it, crank the valve, and the door goes."). Keep it for an action beat, or state the goal only and let the hint ladder teach the rest? (PUZ-8)
- **Q7. Tank hit rule.** Default decided: "a hit = its body overlaps the brackets". Count a graze as a hit and widen the window, given the ~0.34 s / 0.21 s windows? (PUZ-6, FAIL-6)
- **Q8. Door scale.** The approved round-4 corridor shutter (October 11) is in the 136-144 px family (~2 × the engineer). Is that shutter a personnel door (then 84-98 px, 1.2-1.4 × the engineer), or a blast or freight door with a personnel door beside or inside it? P1-1 (build the shutter) waits for this answer. (SPACE-10, SPACE-12)
- **Q9. Stair angle.** Pick 30° (the plan's own option) or 38° instead of ~18°? (SPACE-13)
- **Q10. Settings look.** The terminal look for Settings is decided. Keep "THE DEN / LOCAL CONFIGURATION" but drop the GPU line and the mobile note on desktop? (PHONE-12)
- **Q11. Assists.** Add an ASSIST tab to the first slice (game speed, wider windows, hold toggle, calmer sentry, Story assist, junction skip)? No recorded decision covers this. A Story assist ("hazards only knock down") interacts with the decided Secure the Evidence cost: should unsecured evidence still drop under it (keeps the stakes), or not drop (keeps the assist gentle)? (A11Y-1, FAIL-10)
- **Q12. Playtest logs.** The privacy page says no telemetry. Allow an opt-in, local-only log in separate playtest builds? (TEST-9)
- **Q13. Fuse length.** Not a recorded decision, but a feel choice: lengthen the 1.0 s fuse to ~2.5 s and tune down by play? (FAIL-4)
- **Q14. Choice wording.** Reword the relay's option 2 so it says what Rowan does (for example "Skip the risk talk. Go now.")? (STORY-5)
- **Q15. Build path for the first playtest round.** Option A: you run each session on your Mac in a Godot window you open yourself, with a separate test save path (PRIVATE_AGENTS.md); no export needed. Option B: an unsigned debug export for testers' Macs or Windows PCs, which needs the Godot 4.7.2 export templates installed (your authorization) and leaves Gatekeeper and signing open (docs/exports.md). Which for round 1? (TEST-1, PLAN P0-11b)
- **Q16. The approved sentry death card.** DEATH_CARD_SENTRY reads "The sentry caught %s in the lane. It did not slow.", and the lane is not drawn as a lane. Use its approved alternative "The sentry caught %s short of the rubble." (the rubble is drawn), or a new line? (TEACH-5, FAIL-1)
- **Q17. Death-card input delay.** A draft note in the approved death-text file mentions "2.4 s first death, 0.8 s repeat"; the final entries carry no delay, and Cold Still (October 11) puts RETRY at 0.9 s and control at ~1.5 s. Confirm Cold Still's timing wins? (FAIL-2)
- **Q18. Music.** Keep the machines-only soundscape, or add a quiet music layer mixed by distance to the threat and a short survival stinger after the sentry (SOUND-12)? No decision covers music; the credits say "No music or voice yet".
- **Q19. Languages.** Which languages, if any, for release? Translation needs room in the 42-character lines and the 24-character item names, and fonts with the right glyphs (LOC-1).

---

*WOLF//OVERRIDE, its story and its characters are by Nathanial Henniges (MrDemonWolf, Inc.). Research sources are credited in SOURCES.md; referenced developers informed craft and are not contributors or endorsers. Compiled 2026-10-13 with AI assistance (Claude Code by Anthropic); revised the same day in round 2 to close a critic's 23 gaps.*
