# Plan: fixes in order, as small playable steps

WOLF//OVERRIDE is an original game and story by **Nathanial Henniges**. This plan orders the fixes from [NEEDS.md](NEEDS.md) and [AUDIT.md](AUDIT.md) into small steps, each of which leaves the slice playable. Nathanial's decisions win: steps that touch a recorded decision or his story wait for the matching question (Q1-Q19 in NEEDS.md).

- **P0 (now):** high harm, small and mostly unblocked. Code, wording splits, tests and the first playtest round.
- **P1 (next):** the bigger look-real, movement, controller, phone and sound work.
- **P2 (later):** the room expansion and the systems that need wider rooms.

**Revised in round 2 (2026-10-13).** Every MUST need in NEEDS.md now has a step (the list at the end checks this). The first playtest round now comes **after** the known Tier-1 faults are fixed (P0-1 to P0-9), so testers find new problems instead of rediscovering known ones; it needs a tester build path (P0-11b, Q15).

**How each step is checked**
- **Headless:** `godot --headless` with an isolated HOME (logic and timing tests; no window).
- **Still:** `tools/render/render.sh` in the container with a unique `--name` per run (rendered frames; no window on the Mac). Judge stills at 100% zoom with the project's look-real checklists (SPACE-7).
- **Phone:** a device build on a real phone (the tester's own, held in the hand, default brightness).
- **Hands-on:** a person plays the route. Agents never open a Godot or game window on Nathanial's Mac; hands-on play is Nathanial's or a tester's, in a normal Godot window with a separate test save (PRIVATE_AGENTS.md). A claim about feel, pacing or readability needs this level.

New or reworded player-facing lines are drafted by Claude and approved by Nathanial before they ship (decided October 10). Pure splits of existing lines into separate boxes are not rewording. Approved text (docs/research-2026-10/approved/) is changed only through a question to Nathanial.

---

## P0: now

### P0-0 · Put the questions to Nathanial
Send Q1-Q19 from NEEDS.md in one batch. Everything below that is not marked "after Qn" can start at once.

### P0-1 · Make the manual bypass audible (SOUND-1)
- Route the bypass hiss to the existing `hiss_low/mid/high` loops (as `play_blend` does) instead of the missing `&"hiss"` (main.gd:970, :1767). Warn in debug builds when `play()` gets an unknown clip.
- **Check:** Headless test that scans the scripts for every clip name passed to `sfx_bank.play`, `stop` and `play_blend` and asserts each exists in SfxBank. Later, the Master-bus recording (P1-11) shows the hiss in the spectrogram.

### P0-2 · Clear the stale "COOLANT FAULT" tag (PUZ-7)
- Hide or change the tag when WOLF takes the surge or the bypass locks over (bypass_handle.gd:101).
- **Check:** Headless scene test on both relay routes asserts the tag is gone at the safe point. Still at the safe point.

### P0-3 · Put the knocked-down body on the floor (SPACE-3, AUDIT 10)
- Rotate the body about its feet to lie on the floor line with its shadow under it, instead of the 70° tilt and shift (main.gd:195-196).
- **Check:** Stills at all five knockdowns (blast, vent, sentry seen, sentry chased, cloud; route X covers them): 0 px gap between body and floor; no part below the floor line.

### P0-4 · Keep WOLF out of machines, doors and the engineer (WOLF-2, AUDIT 7)
- Move every authored WOLF spot to clear floor (relay contact, bypass, mirror, rubble at x 448, lane, hatch), or run authored targets through `off_machines` (m0_actor.gd:130-145).
- **Check:** Headless test: at every authored rest point WOLF's body span overlaps no station span, no door frame and not the engineer. Stills at each beat on both routes.

### P0-5 · A real walk-out and a quiet beat at the end (PACE-9, PACE-2, WOLF-4, AUDIT 8)
- USE at the open hatch (not at the bolt console) starts the exit; WOLF walks through the hatch and out of frame; the engineer follows; a 1-2 s hold on the quiet junction; then END OF SLICE.
- **Check:** Headless test: both actors pass the hatch x before the card shows and neither is hidden while on screen. Still sequence of the last 5 s.

### P0-6 · Give the fuse a readable length and a tick (FAIL-4, TEACH-3, A11Y-2) · *fuse length after Q13*
- Start `FUSE_SECONDS` at ~2.5 s (pressure_line.gd:10); add a tick synced to the fuse; slow the blast-stripe pulse from 4 Hz to ≤ 2 Hz if the longer fuse makes it pulse longer (junction_room.gd:264).
- **Check:** Headless timing test (fuse length, tick count). The flash check runs now and does not wait for Q13: render.sh `--name a11y-flash`, 180 frames at 60 fps from the fuse through the knockdown, analysed with `round2/tools/flash.py` against WCAG's thresholds (round 2: below them, worst 10° window 10.2%). Rerun after any fuse or stripe change. Hands-on and Phone: tune the fuse down until fresh players scramble clear at the last moment (TEST-5 logs knockdowns per tester).

### P0-7 · Name only what is drawn (TEACH-5, FAIL-1 words, STORY-5) · *sentry card after Q16; relay wording after Q14*
- Draft new sentry hint and knockdown lines that point at things on screen, use one word for the drop mark, and replace "SPENT" and "BOLTED" with plain words; or draw the alcove as a recess with two real uprights. Change only lines that are not in the approved files; the approved DEATH_CARD_SENTRY ("... in the lane. It did not slow.") changes only by Q16 (its approved alternative "... short of the rubble." is ready). Reword the relay's option 2 after Q14. Nathanial approves new lines.
- **Check:** Still at the sentry hint and each knockdown card, with every named thing visible. A word list per beat (≤ 1 new proper noun).

### P0-8 · One thing to read on the first controllable frame (TEACH-7, AUDIT 4)
- Show the name card first; the tutorial after the first step; the dialogue after that. Fix "TAP USE READ DISPLAY (optional)".
- **Check:** Still at first control on desktop, controller and phone: at most one text element plus one prompt.

### P0-9 · Text timing, shape and size (STORY-2, STORY-3, STORY-4, STORY-8, STORY-10, PACE-3, STORY-1, DISPLAY-2)
- Change `READ_SECONDS_PER_WORD` from 0.15 to 0.33 plus a base (main.gd:39). Split multi-speaker strings into consecutive one-speaker boxes. Clear a box once its reading time has passed while the player moves on, so the Records exit no longer holds the player ~16 s. Split lines of 20+ words at their sentence breaks. Repeat the engineer's name in the trust line (main.gd:62), keeping they/them.
- **Text shape and size (STORY-3):** narrow the dialogue column to ≤ 42 characters per line (today's rows are ~97-118 characters), raise the dialogue to ≥ 23 px at 540p (17 px today, main.tscn:352), and add a Text Size setting (100-200%) that scales the dialogue, hint, card and labels.
- **Check:** Headless test over every line constant and shown box: one speaker per box, ≤ 2 lines, ≤ 42 characters per row at 100% and the row count at 200%, reading time ≥ 0.33 s per word. Stills at 960 × 540, 1280 × 720 and 2400 × 1080 at the Records exit, the junction close and first control.

### P0-10 · Quick phone layout fixes (PHONE-3, PHONE-7)
- On touch, put the two choice buttons at the bottom in thumb reach without the "1"/"2" prefixes; make hint text name the on-screen button ("Hold CRANK"); keep the hint bar clear of USE.
- **Check:** Stills at 2400 × 1080 and 2556 × 1179 at the relay choice, the valve crank, the lane choice and DROP.

### P0-11 · Holds that answer at once, with a toggle (FEEL-4, FEEL-1, PHONE-10, CTRL-5) · *bypass length after Q1*
- Turn the wheel a little and click on the press frame, before the first 0.4 s tick; add a hold-to-toggle option in Settings that covers keyboard, pad and touch; keep ticks through a release (already done).
- **Check:** Headless test: visible progress on the first frame; with the toggle on, a single press completes the crank. Still of the first frame of a hold. Hands-on for feel.

### P0-11b · A tester build and consent (TEST-1, TEST-7, TEST-9) · *after Q15*
- **Option A (no export):** Nathanial runs each session on his Mac in a Godot window he opens himself, from a clean checkout, with a separate test save and settings path (PRIVATE_AGENTS.md), and resets them between testers.
- **Option B (export):** an unsigned debug export for testers' Macs or Windows PCs. It needs the Godot 4.7.2 export templates installed (Nathanial's authorization) and leaves Mac signing and Gatekeeper open; record date, templates, OS, build id and each observed result as docs/exports.md asks.
- **Consent:** a one-page form before any session: what is recorded (screen, voice, the observer sheet), who sees it, that recordings never enter the repository (TEST-9), how long they are kept, and that the tester can stop at any time; consistent with the site's Privacy page (the game sends nothing over the network).
- **Check:** a dry run of the chosen path with Nathanial as the only player; the form signed before the first tester.

### P0-12 · First silent playtest round (TEST-1 to TEST-6, PACE-5) · *after P0-1 to P0-9 and P0-11b*
- Run it after P0-1 to P0-9, so the round tests new problems, not the four Tier-1 faults that already have code-level fixes. (If Nathanial wants an as-is baseline first, call it "baseline round" and list in its notes which known faults are expected: the ~41 s opening, the sentry words, the 1.0 s fuse, the first-frame text wall.)
- Nathanial plus at least 3 fresh testers on desktop (keyboard; one with a controller if available), who have not seen the story. Silent observation through the junction; the three story questions at the opening, the relay choice and END OF SLICE; a survey before discussion; the observer sheet (TEST-5, including "can point to what blocks the way before touching the valve", PUZ-1); severity rated 0-4 by three people.
- This is also the repo's recorded "one next task" (docs/next-session.md: the first hands-on play session).
- **Check:** the round itself. Fix all severity 3s and 4s before P1's art work.

### P0-13 · Reach first control faster (TEACH-1, PACE-3, STORY-1) · *after Q2*
- Rework the opening to reach first control in 30-45 s with Rowan on screen (the option Nathanial picks in Q2). Until then, show "PAUSE: skip the opening" on the opening's first box (SKIP OPENING already exists, main.gd:1360).
- **Check:** a headless timing test from NEW GAME to the first `move_*` input using the capture's reading formula (1.2 s + 0.05 s per character, ≤ 7 s); stills of the opening and the first controllable frame.

### P0-14 · A sound on every state-changing press (SOUND-2, FEEL-1)
- Add sounds where the round-2 probe found none: the safe-point secure, the purge-queue copy, the mirror answer, the relay answers, WOLF taking the relay, the hatch exit; make Records' first-copy sound consistent.
- **Check:** keep the round-2 press probe as a headless test: every state-changing press starts an SfxBank sound within 1 frame and changes text or light within 1 frame (round 2 measured 1-3 frames where a sound exists).

### P0-15 · Every invalid press says no (PUZ-4)
- A table of every station × invalid state (valve before the breaker, sealed door, breaker while building, spent valve, DROP too early, spent release, exit before the sentry is down) with a light flicker, a short refusal sound and its line on the press frame; the sealed door gets its own line and a bump when walked into; a repeated press re-shows the line.
- **Check:** headless: the first sound, light and text change within 6 frames for every row.

### P0-16 · The sentry reads true, and solid things stay solid (FAIL-1, SPACE-8, A11Y-3)
- Align the sight cone with the lamp; a hard beam tip at the real `SIGHT_RANGE`; a beam that stays visible without red (a light core or dashed edge); the knockdown triggers at contact distance, before the sentry overlaps the engineer; the beam is occluded by solid props (the bolt panel); the release-to-bolt cable rerouted off the tank; the vent grate drawn above the steam.
- **Check:** a headless overlap test over every logged frame of routes D, M and X (sentry ∩ standing engineer = ∅; beam ∩ props = ∅; cable ∩ tank = ∅); a check that the drawn beam end equals `SIGHT_RANGE`; stills of all five cards and their colour-vision simulations.

### P0-17 · Regression tests for what already works (WOLF-1, WOLF-6, WOLF-8, STORY-9)
- Headless tests: no urgency words in any WOLF line; the sentry never targets WOLF outside the bait and WOLF has no fail state; no WOLF action completes an engineer step; no meter node in the HUD; the engineer-only route reaches every essential step with WOLF refusing everything.
- **Check:** the tests themselves, run in CI.

### P0-18 · WOLF answers with his body at once (WOLF-5, WOLF-11, STORY-19)
- A head-and-eye "heard you" pose within 6 frames of every request and choice, before his line; a refusal pose and sound that hold ≥ 1 s, with the engineer-only route lit.
- **Check:** the round-2 choice probe extended to WOLF's pose state (today: line at 1 frame, body only when he is sent somewhere); still sequences at the relay and lane refusals. Hands-on: can a tester say what WOLF decided?

### P0-19 · Narrated changes happen on screen (STORY-7, TEACH-9)
- A line-by-line table of every narration line that describes a visible change (the blue light in the seal, the Director freezing, the relay filling with light, WOLF running to the valve) against the frame where it shows. Make each happen on screen, or cut the line (Q5).
- **Check:** the table, rebuilt from each capture's log.

### P0-20 · Ship the licences (CRED-1)
- A LICENCES screen (or the end of the credits) with Godot's MIT text and copyright line, its third-party notices (`Engine.get_license_info()` / `COPYRIGHT.txt`) and the SIL OFL notices for Roboto and Montserrat; propose the same for the site's credits page. Verify the Godot page's wording again when editing.
- **Check:** headless test that the screen contains Godot's copyright line; a still.

### P0-21 · A fair tank window (PUZ-6, FAIL-6) · *after Q7*
- Widen `HIT_RANGE` or slow the sentry over the mark so the window is ≥ ~0.5 s on patrol (today ~0.34 s; ~0.21 s in a chase), and count a graze as a hit if Nathanial agrees.
- **Check:** a headless window-length test (frames the sentry's body overlaps the brackets per pass); then hands-on on desktop and a phone (PHONE-10).

---

## P1: next

### P1-1 · One door, built for real (SPACE-1, SPACE-2, PACE-4, AUDIT 5-6) · *after Q8*
- Build the approved corridor shutter across the walking line, under the REAL-LOOK process: exact functional shape first, paint second, a cleanup pass, an AI-tell review, and this one piece in the real game before any other door. The leaf moves into its pocket; the engineer walks through it into Records. Q8 settles whether it is a personnel door or a blast door with a personnel door beside it.
- **Check:** Stills closed, half open and open; REAL-LOOK §3 and art-bible §3.7; Hands-on: does the door read as blocking, then as passable?

### P1-2 · The other doors (SPACE-1, SPACE-2, PUZ-1, PACE-4) · *after Q8*
- The junction blast door across the walking line (so blowing it clearly opens the way), the junction exit hatch with a moving leaf, and a real Records exit with a visible space beyond.
- **Check:** as P1-1, per door.

### P1-3 · Grounding pass (SPACE-3, SPACE-4, AUDIT 9)
- Mount the MANUAL BYPASS on the relay with a real pipe; wall-mount the purge console with bracket and conduit or give it a floor stand; route the release-to-bolt cable as conduit on the floor or wall; darken and tighten contact shadows (REAL-LOOK §3 item 4: the floor at the base clearly darker than 8-12 px further out).
- **Check:** Stills at 100% zoom with the look-real checklists; a greyscale still to confirm contact without colour.

### P1-4 · Effects designed from their causes (SPACE-9, AUDIT 11, 36)
- Blast debris and dust that settles, a directional steam jet, a vent burst that does not hide its grate, a coolant cloud distinct from the vent, a dust ring and dent at the tank, arcs along WOLF's body seams for the surge, a real bolt arc; replace the beige blob, glow ball and "M" glyph.
- **Check:** a 5-frame strip per effect where a reviewer can draw its direction and see the floor cut it; the flash check (P0-6); Reduced Motion on and off.

### P1-5 · Walk, jog and the painted cycles (FEEL-2, FEEL-3, WOLF-3, WOLF-12, CTRL-4)
- Walk 80 / jog 190 with ramps; the approved painted cycles at playback rate = speed ÷ stride; WOLF's walk or trot by distance; a ~36 px dead band; partial stick tilt maps to walk.
- **Check:** Headless tests for the velocity curves, the dead band and the analog sweep. Still strips to check foot slide. Hands-on for feel on desktop and controller.

### P1-6 · Visible contact and acknowledgement (FEEL-5, WOLF-7, AUDIT 14)
- Engineer reach and crank poses per station type; WOLF's relay contact, a visible readout at the mirror, a real run to the valve, a 2-4 s bait run that goes around the sentry.
- **Check:** Still sequences per beat; Hands-on: can a tester say what WOLF did and why?

### P1-7 · Camera window and look-ahead (FEEL-6, FEEL-7)
- A ±36 px window, speed-scaled forward focus, side-switch hysteresis; small authored camera targets at the sentry alert and the door.
- **Check:** Headless camera-offset test; Hands-on on desktop and phone.

### P1-8 · Labels, prompts and the pause screen (PUZ-2, PUZ-3, TEACH-4, TEACH-6, STORY-6) · *after Q4*
- Name plates on equipment, the in-range prompt, only the next node lit; the objective and a log of the last 20 lines on the pause screen; optional station labels; prompts that retire after 1-3 successes; "Checkpoint saved." as a small icon.
- **Check:** Headless lesson-counter and log tests; Stills; fresh testers find each station without labels (TEST-5).

### P1-9 · Teach each verb before combining (TEACH-2, PUZ-5, PACE-7)
- The safe-point secure hold (≤ 1.5 s) on every route before the junction; the relief vent seen venting harmlessly first; one safe, slow use of the claw before the timed drop; the sentry seen catching something from cover; a quiet approach before it rolls in.
- **Check:** Headless route tests: both relay routes use a hold before the junction. Stills. Fresh testers (TEST-5): first-attempt success per verb.

### P1-10 · A phone build worth testing (PHONE-1 to PHONE-7, PHONE-12, PHONE-16, PHONE-17, PERF-1, DISPLAY-1)
- Stretch aspect `expand` with HUD and controls inside the safe area (one decision for phones, iPads and 16:10 desktops); taller buttons and a ≥ 12 pt gap; press states, a click and a light haptic; a headless two-thumb test (touch indices 0 and 1) and an explicit release when buttons hide; FPS options 30 and 60 only on phones; per-platform Settings rows; text sizes toward 17 pt; iPad thumb reach and keyboard, trackpad and controller switching; Android Back checked on a device.
- **Check:** Stills at 20:9, 19.5:9, 16:9, 16:10 and 4:3 (route S); the headless multitouch test; Phone: TestFlight or Play internal build, then a phone playtest round with screen recording and "Show taps" (TEST-7).

### P1-11 · Sound basics (SOUND-3 to SOUND-9, SOUND-13)
- Footsteps on contact frames (≥ 4 variants per surface, no immediate repeat); three room beds with sweeteners; loudness gain staging; layers above ~600 Hz on impacts; Voice and Ambience buses, a mono toggle and a sidechain duck under WOLF; the fuse tick.
- **Check:** Master-bus recording inside the render container on the scripted route; a script for LUFS, true peak, spectrogram gaps, each impact's energy share above 600 Hz (≥ 30%, derived) and a mono fold-down (no essential cue down more than 3 dB). Hands-on: Nathanial listens on desktop speakers, headphones and a phone.

### P1-12 · Help that respects the player (A11Y-1, A11Y-8, PUZ-8, PUZ-9, FAIL-3, FAIL-5) · *after Q6 and Q11*
- An ASSIST tab (game speed, wider windows, hold toggle, calmer sentry, Story assist per Q11's evidence rule, junction skip); a text-speed setting; hint options; one WOLF hint line after ~3 knockdowns at one hazard (a starting value; Nintendo chose 8 lost turns); the junction hint ladder; a closer restore point after repeated deaths; a line that says what a retry reset.
- **Check:** Headless tests for each counter and option; testers.

### P1-13 · Second playtest round, desktop, controller and phone (TEST-2, TEST-7)
- ~6 fresh testers (3 desktop, 3 phone; at least one desktop tester on a controller), recruited beyond people who know the story (TEST-10); fix between testers where obvious, then confirm with a block of unchanged sessions.
- **Check:** the round; severity ratings; compare first-try success and stops over 30 s with P0-12.

### P1-14 · Controller polish (CTRL-1, CTRL-2, CTRL-3)
- BACK reachable by D-pad in every Settings tab (and "B BACK" shown on every overlay); glyph images matching the connected pad (Xbox, PlayStation, Nintendo) with letters as the fallback; a rumble strength slider.
- **Check:** a headless focus-walk test from each overlay's first focus to every button; a headless test of joypad name → glyph set; stills from route C.

### P1-15 · Front-end basics (MENU-2, MENU-3, MENU-4, MENU-5, MENU-6, A11Y-7)
- QUIT on the desktop title (not on iOS); CONTINUE names its place; a line under NEW GAME when a save exists ("Your checkpoint is kept until the new run's first safe point"); a first-launch screen for text size, subtitles, Reduced Motion and "sound recommended"; pause during choices and chases.
- **Check:** headless tests per item; route F rerun (render.sh `--name play-research-frontend`).

### P1-16 · Characters that read against the rooms (READ-1, READ-2, SPACE-7)
- The art bible's lighting and value bands for the engineer and WOLF (top-lit, rim light, body L* ≥ 12 above the walk band), one character first in the real game.
- **Check:** `round2/tools/contrast.py` on each round's stills (median ≥ 1.6:1, rim side ≥ 3:1 per art-bible §3.7); greyscale and colour-vision stills.

### P1-17 · Research credits on the site and in the game (CRED-2) · *proposal for Nathanial*
- A short, spoiler-safe "Research references (October 2026)" list on apps/docs/content/docs/credits.mdx of the most-cited primary sources, linking to the full research folder once it is copied into docs/research-2026-10; one matching line in the in-game credits.
- **Check:** the site build; a still of the in-game credits.

---

## P2: later

### P2-1 · The room expansion (SPACE-5, SPACE-6, SPACE-10 to SPACE-16, PACE-1, PACE-5, PACE-6, PACE-10, READ-3)
- Per room: a facility brief and dependency chart; a grey box at 1.5-2 views with a beat per view-width, a landmark from the entrance, physical end caps, a refuge safe point, real dimensions (stairs per Q9, doors per Q8), WOLF's service routes, one vignette, the two approved purge hints, and three depth bands whose near pieces never cover the play; phone-tested before paint (decided).
- **Check:** Stills; stopwatch timings per beat in Hands-on rounds; Phone before paint.

### P2-2 · WOLF when he is off screen (WOLF-10)
- Continuous sound plus an edge marker shown only while he is out of frame, with direction and state.
- **Check:** Stills in wide rooms; testers with sound off.

### P2-3 · Life in the characters (WOLF-13, STORY-12, FEEL-10, SOUND-10, READ-4)
- WOLF's interest points, head-first look-at and body grammar for calm, uneasy, afraid and working, readable at phone size; the engineer's look-at and breathing.
- **Check:** Still sequences; a phone-size pose test; Hands-on: do testers describe WOLF as present?

### P2-4 · Speech and story systems (WOLF-9, STORY-13 to STORY-17)
- A bark rule table with the speech budget; walk-and-talk; story stations that wait; choices while walking (only after testing the current choices).
- **Check:** Headless tests for cooldowns and once-only lines; testers.

### P2-5 · The rest of the sound design (SOUND-11, SOUND-12, SOUND-14 to SOUND-16) · *music after Q18*
- Mix snapshots and a death filter; machines tuned as the score; a quiet music layer and survival stinger only if Q18 says so; procedural parameters; cloth; speaker-aware panning.
- **Check:** recordings as in P1-11; Hands-on listening.

### P2-6 · Death and evidence (FAIL-2, FAIL-10, STORY-14, CASE-1 to CASE-3) · *delay after Q17*
- The approved Cold Still death screen and Secure the Evidence rules (decided), with WOLF's capped lines after a ~2 s quiet; the evidence case opened from Pause with 3-line pages and touch, pad and keyboard navigation.
- **Check:** Headless save tests (key records never drop); the case's page count at 100% and 200% text size; Stills of the death screen and the case; testers.

### P2-7 · Phone robustness (PHONE-5, PHONE-8, PHONE-9, PHONE-13 to PHONE-15, PERF-2 to PERF-5, FEEL-1, MENU-1)
- A resume snapshot within iOS's ~5 s background window, resuming into the pause menu; the floating pad and layout presets; a phone zoom; thermal soak tests; press-to-pixel latency filming; launch time; the pre-release port checklist.
- **Check:** Phone tests (interruptions, 15+ minute soak, high-speed camera).

### P2-8 · Accessibility depth (A11Y-3 to A11Y-6, A11Y-9 to A11Y-11, DISPLAY-3)
- Interactable tags for a high-contrast mode; captions with direction; an audio-cue assist; a separate flash toggle; menu narration through AccessKit; a colour-vision check each round; a plainer font option; frame pacing at 60/120/144 Hz on an awake Mac.
- **Check:** Greyscale, high-contrast and colour-vision stills; testers who use these settings; a hands-on frame-time run.

### P2-9 · Bigger rounds and opt-in logs (TEST-8 to TEST-12) · *logs after Q12*
- The PLAY heuristic pass and survey; opt-in, local playtest logs in separate builds; Steam Playtest once a store page exists.
- **Check:** the rounds.

### P2-10 · Localization readiness (LOC-1) · *only after Q19*
- Pseudo-localization (+30-40% on sentences, +100% on short labels) against the 42-character column, the 24-character item names and every button; a glyph-coverage check of the fonts for the chosen languages.
- **Check:** the headless pseudo-loc test; stills.

---

**One next task:** P0-1 to P0-5 are small and unblocked; then P0-6 to P0-9 (the Tier-1 faults); then the first silent round (P0-12) on the build path Nathanial picks in Q15 (P0-11b). The round should come before any P1 art work, so the art is judged by what players do.

After each milestone, record actual checks separately from unrun ones, and update Notion and the Codex board through the usual Codex process.

## Every MUST, and where it is scheduled

MUST needs whose status is MET keep a regression check (P0-17 or the step named). Generated from NEEDS.md on 2026-10-13.

| MUST | Need | Now | Steps |
|---|---|---|---|
| PACE-1 | Something new every 5-10 s of movement, triggered by position | UNKNOWN | P2-1 |
| PACE-2 | After every threat peak, change the mode | PARTLY | P0-5 |
| PACE-3 | Protect the first 10 minutes from dead time | NOT MET | P0-9, P0-13 |
| PACE-4 | No padding and no dead backtracking; thresholds you pass through | PARTLY | P1-1, P1-2 |
| PACE-5 | Measure pacing by playing it, before painting | NOT MET | P0-12, P2-1 |
| FEEL-1 | Every input answers within ~100 ms | PARTLY | P0-11, P0-14, P2-7 |
| FEEL-2 | Response wins over animation | PARTLY | P1-5 |
| FEEL-3 | Walk 80 / jog 190 with short ramps, not an instant snap | NOT MET | P1-5 |
| FEEL-4 | Holds respond at once, stay short, and can be toggled | PARTLY | P0-11 |
| FEEL-5 | Hands meet the thing they use | NOT MET | P1-6 |
| TEACH-1 | Control fast; the opening stays short, skippable and player-paced | PARTLY | P0-13 |
| TEACH-2 | One new verb per beat; use it ~3 times before combining | PARTLY | P1-9 |
| TEACH-3 | No unreadable or precision deaths in the first ~5 minutes | PARTLY | P0-6 |
| TEACH-4 | Objective and controls reviewable any time; key lines re-readable | PARTLY | P1-8 |
| TEACH-5 | Name only what the player can see | NOT MET | P0-7 |
| PUZ-1 | Show the problem before the tool, and make the obstacle a real obstacle | PARTLY | P0-12, P1-2 |
| PUZ-2 | At most 3-4 live interactables per view, and only the next one lit | NOT MET | P1-8 |
| PUZ-3 | Show what is usable in layers, cheapest first; names live on the equipment | PARTLY | P1-8 |
| PUZ-4 | Every wrong attempt says no, never, and why | PARTLY | P0-15 |
| PUZ-5 | Never require a death to learn a step | PARTLY | P1-9 |
| PUZ-6 | Timing puzzles repeat and are easy to execute | PARTLY | P0-21 |
| PUZ-7 | Station states match the world | NOT MET | P0-2 |
| SPACE-1 | Doors sit in walls, lead somewhere real, and are walked through | NOT MET | P1-1, P1-2 |
| SPACE-2 | Doors show their state and move when they open | NOT MET | P1-1, P1-2 |
| SPACE-3 | Nothing floats | PARTLY | P0-3, P1-3 |
| SPACE-4 | Pipes and cables go somewhere, and say what they carry | PARTLY | P1-3 |
| SPACE-5 | A short facility brief before grey box or paint | NOT MET | P2-1 |
| SPACE-6 | Room edges are physical | PARTLY | P2-1 |
| SPACE-7 | A "look real" pass at 100% zoom before every playtest round | NOT MET | P1-16 |
| SPACE-8 | Solid things stay solid | NOT MET | P0-16 |
| SPACE-9 | Effects look physical | NOT MET | P1-4 |
| WOLF-1 | WOLF follows by default, never nags, never sets the pace | MET | P0-17 |
| WOLF-2 | WOLF never stands in the way or inside anything | NOT MET | P0-4 |
| WOLF-3 | Gait follows distance, and stays below the player's top speed | PARTLY | P1-5 |
| WOLF-4 | No vanishing or teleporting on camera | NOT MET | P0-5 |
| WOLF-5 | Acknowledge every request at once, even a no | PARTLY | P0-18 |
| WOLF-6 | No babysitting, and he never wrecks the plan | MET | P0-17 |
| WOLF-7 | His help is rare, visible and in frame | NOT MET | P1-6 |
| WOLF-8 | He doesn't steal the fun | MET | P0-17 |
| WOLF-9 | A speech and sound budget | NOT MET | P2-4 |
| WOLF-10 | Off screen: sound plus an edge marker, never a mood bar | NOT MET | P2-2 |
| WOLF-11 | A refusal reads as a decision, and the other route is visible | PARTLY | P0-18 |
| FAIL-1 | Every hazard shows its cause first; every card names it and how to avoid it | PARTLY | P0-7, P0-16 |
| FAIL-2 | Retry is near-instant and lands facing the goal | PARTLY | P2-6 |
| FAIL-3 | Restore at most one beat back, and say what was reset | PARTLY | P1-12 |
| FAIL-4 | Time pressure is the most forgiving lever; the fuse must be readable | NOT MET | P0-6 |
| FAIL-5 | Help after repeated failure, never before the first try | NOT MET | P1-12 |
| STORY-1 | Keep control with the player during story | PARTLY | P0-9, P0-13 |
| STORY-2 | Auto-timed lines at a human reading speed | NOT MET | P0-9 |
| STORY-3 | Text sized and shaped like good subtitles | NOT MET | P0-9 |
| STORY-4 | One speaker per box, named at every change | PARTLY | P0-9 |
| STORY-5 | Choices say what the engineer does, and WOLF answers at once | PARTLY | P0-7 |
| STORY-6 | Text is player-paced and can be read again | PARTLY | P1-8 |
| STORY-7 | Point the eye at reveals without taking control | NOT MET | P0-19 |
| STORY-8 | Never hold the player still for dialogue; run it on the walk | NOT MET | P0-9 |
| STORY-9 | Story and play agree | MET | P0-17 |
| PHONE-1 | Touch targets big enough, with real spacing | PARTLY | P1-10 |
| PHONE-2 | Two thumbs work at once, verified | UNKNOWN | P1-10 |
| PHONE-3 | Buttons show presses, name the action, and sit under the thumbs | PARTLY | P0-10, P1-10 |
| PHONE-4 | Readable text on a phone | NOT MET | P1-10 |
| PHONE-5 | Interruptions cost nothing | PARTLY | P1-10, P2-7 |
| SOUND-1 | Fix the silent manual bypass | NOT MET | P0-1 |
| SOUND-2 | Every state-changing press makes a sound on the same frame | PARTLY | P0-14 |
| SOUND-3 | Footsteps from the painted cycles' contact frames | NOT MET | P1-11 |
| SOUND-4 | Room tone everywhere; never digital silence | NOT MET | P1-11 |
| SOUND-5 | Mix by loudness, not peak | NOT MET | P1-11 |
| SOUND-6 | Impacts that survive small speakers | NOT MET | P1-11 |
| SOUND-7 | Every essential sound has a visual twin, and a haptic one on phones | PARTLY | P1-11 |
| SOUND-8 | Separate volumes and a mono option | PARTLY | P1-11 |
| PERF-1 | A steady frame rate on phones | NOT MET | P1-10 |
| A11Y-1 | Player-controlled assists in the first slice | NOT MET | P1-12 |
| A11Y-2 | Stay under photosensitivity limits | MET | P0-6 |
| A11Y-3 | No essential information by colour or sound alone | PARTLY | P0-16, P2-8 |
| A11Y-4 | Motion and shake switches | PARTLY | P2-8 |
| TEST-1 | First-time players, early and often, starting at the grey box | NOT MET | P0-11b, P0-12 |
| TEST-2 | Small repeated rounds, enough testers per platform | NOT MET | P0-12, P1-13 |
| TEST-3 | Watch in silence; survey before discussion | NOT MET | P0-12 |
| TEST-4 | Test whether the story lands | NOT MET | P0-12 |
| TEST-5 | A timestamped observer log | NOT MET | P0-6, P0-12, P1-8, P1-9 |
| TEST-6 | Rate severity with three people | NOT MET | P0-12 |
| TEST-7 | Phone tests on testers' own phones | NOT MET | P0-11b, P1-10, P1-13 |
| CTRL-1 | Everything reachable with a controller alone, with B as Back | PARTLY | P1-14 |
| CTRL-2 | Prompts match the controller in the player's hands | PARTLY | P1-14 |
| MENU-1 | An interactive title within a couple of seconds | MET | P2-7 |
| MENU-2 | A way to quit from the desktop title | NOT MET | P1-15 |
| MENU-3 | Continue says where it resumes | PARTLY | P1-15 |
| DISPLAY-2 | Smallest text above the platform floors | MET | P0-9 |
| CASE-1 | Open from Pause only, by tap or press, never during a hazard | NOT MET | P2-6 |
| CASE-2 | Inspect text readable on a phone | NOT MET | P2-6 |
| READ-1 | Characters separate from the background by value, not only by hue | NOT MET | P1-16 |
| READ-2 | One light logic: actors top-lit and rimmed like the props | NOT MET | P1-16 |
| CRED-1 | Ship the Godot licence and its third-party notices | NOT MET | P0-20 |

92 MUST needs; 92 scheduled.

*WOLF//OVERRIDE, its story and its characters are by Nathanial Henniges (MrDemonWolf, Inc.). Compiled 2026-10-13 with AI assistance (Claude Code by Anthropic); revised in round 2 the same day.*
