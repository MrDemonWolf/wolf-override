# PIN codes: the three options judged

**Private design material.** Keep it out of Git, public docs, PR text and build output. This file answers Nathanial's request of 2026-10-11: "Can we add some pin codes and make it feel more like a furttgrue milialry base like iin skynet". The Terminator films' AI-run defence network is a mood reference only, so no Skynet, Terminator or Cyberdyne names, logos, designs or text appear anywhere. Nothing is built. Every player-facing word in the options is **proposed, awaiting Nathanial**, and every set of digits is a placeholder.

- Pick sheet: `sheet.png` (in this folder). It stacks the three strips, each with its name, a one-line pitch, a score and a verdict, and marks the recommended option.
- Inputs: `research/RESEARCH.md`, `audit/AUDIT.md`, `option-a/`, `option-b/` and `option-c/` (each folder's DESIGN.md, strip and every mock still).
- Sheet builder: `judge/make_sheet.py`.
- **Revision (2026-10-11):** every fix in section 7 has been applied to the option folders, every still was re-rendered on `main` at `cfe304f` (shared scratch export `export-cfe304f/`), the three strips and `sheet.png` were rebuilt, and new or changed lines were measured against the game's fonts (`fixlogs/fit_new.py`). Section 7 says what changed for each item. The scores are the review's, given before the fixes; no option was re-scored.

---

## 1. The verdict

**Recommended: A, the found code, plus B's door lamps.** A is the only design where the player actually *finds* a code and later uses it. That is the moment players love in this genre: a code read in a quiet room and used later, with nothing to write down. A also keeps an engineer-only way through and never makes WOLF a source. B is the best at making the base feel like a military site run by automated systems, but its keypad is ceremony: the code is always handed over before the keypad opens. Its lamp language is the part to keep. C is the safest, but it barely answers the request: most players would never meet a keypad on the main path.

| Rank | Option | Score | One-line verdict |
|---|---|---|---|
| 1 | **A. The found code** | **7.5 / 10** | The only real found code, with an engineer-only way out. Fixed: the hand-cranked route now ends in the same bolt arc and flash, and the reader's state is a lamp. |
| 2 | B. Lockdown access | 6 / 10 | Best military feel, thinnest PIN play: the code is always on file before the card opens. Fixed: WOLF reads it on both routes, only his tone changes. Take its door lamps. |
| 3 | C. Small and optional first | 5 / 10 | Safest, but it barely answers the request: phase 1 is one optional locker opened in one press. Fixed: K2 is one stop at the terminal and fits round 3, but still has no floor until the junction rebuild. |

---

## 2. What I checked, and how

- I read all three DESIGN.md files, the research and the audit, and viewed every mock still at full size. That covered the strips plus A's `shots/mock/*`, B's `shots/*` (including `00-baseline` and `06-world-lockdown`, which are not in its strip) and C's `mocks/*`.
- I checked the options against the rules in `PRIVATE_AGENTS.md`, `PROJECT_CONTEXT.md`, `docs/next-session.md`, the private research README, the approved item, death and logic text, and `data/real-inventory-design.json` (inventory rules 1-13).
- I checked their code claims against `main` at `7c19ee2`: bolt panel 806, hatch 880, the input map, the uses of the `klaxon` sound, the pause bindings and the current bolt lines. All of these checked out except where a finding below says otherwise. Line numbers in this file are at `7c19ee2`; the option files give the `cfe304f` line in brackets where it moved.
- **Main moved during this job.** Logic round 3 merged as PR #47 (`cfe304f`). In the junction, after the sentry falls, WOLF now waits in the hatch doorway at `WOLF_DOWN_X` = 700 + 202 = 902, by the bolt panel, and "never walks back across" the tank. In the revision every still was re-rendered on `cfe304f`, so they now show this, and C's K2 was reworked to fit it.
- **Not done:** the review ran no Godot. The revision ran Godot only to render mock stills (one window per run, closed by its own script, isolated HOME). Nothing was played, exported or device-tested, and no headless game test was run. No Git repository, worktree, Notion or Jira page was touched. Scores are judgement, not playtest results. No option's game feel has been validated by anyone.

---

## 3. Option A: the found code (7.5 / 10)

**The design.** In Records, an optional lit ACCESS SCREEN sits between the purge queue and the mirror. It reads "LOCKDOWN: PERSONAL CODES REVOKED. HATCH OVERRIDE: 4071. CHANGE: OVERDUE." Holding USE copies it into the case. At the junction exit, once the sentry is down, the bolt panel becomes an OVERRIDE ONLY reader. The keypad card offers ENTER 4 0 7 1 in one press, typing, or MANUAL RELEASE: a 2.4 s hand crank that sets off a DOOR FORCED alarm and then ends in the same bolt arc as the code route (revised). The reader's state is a lamp on the panel (revised).

**What works**
- It has a real find-then-use loop. The code becomes a fact in the case and is shown on the keypad, so nothing is written down or memorised. Knowledge is a key: a replaying player can type 4071 without reading the screen.
- Every essential step has an engineer-only route: the screen is read by the engineer, and MANUAL RELEASE needs nobody.
- WOLF never fetches, never says the digits and is never a source. He gets a NOTICE or IGNORE beat and an authored protective action during the alarm. This avoids stacking another withholding on the rushed route.
- The worst case is about 10 s: three wrong codes, a 5 s lockout and the crank. MANUAL RELEASE never locks, so there is no dead end.
- "CHANGE: OVERDUE" is a good machine-voice wrong note, grounded in ICS 705's rule that default codes must be changed. It hints without revealing.
- It has the best touch sizing: 92x78 canvas-px keys, about 56 pt, which meets the 78 px target from the Codex review.
- It keeps the approved bolt lines (POP_BOLT, BOLT_CHARGING, BOLT_ARC, HATCH_OPENED) unchanged on the code route.

**Where it fails**
1. **The hand-cranked route lost the slice's climax.** On MANUAL RELEASE, POP_BOLT and BOLT_ARC were skipped, so only players who found the screen saw the arc, flash and shake, against the spirit of inventory rule 3. **Fixed:** at 6/6 the crank hands over to `_pop_bolt()` and `_bolt_arc()`, so the whine, arc, flash, shake and the four approved lines play on both routes (A §4.3, `shots/mock/8-manual-arc.png`).
2. **Players who skip the screen meet a keypad they can't use.** The card still says ENTER OVERRIDE in amber, above a full number pad, with no code to enter. That invites guessing (1234, 0000) and lockouts, and it reads as "you missed something" even though no text says so. The genre accepts this (Prey), but it should be a conscious choice. **Not changed** (it was not on the fix list); A now records it as risk 12, with the option to collapse the pad behind a TYPE A CODE button. Alternative: put the screen on the essential path in Records, so every player types a code.
3. **The Esc and Start rule couldn't be built as written.** Esc and Start are the same `pause_game` action (`main.gd:3275`, `3284` at `7c19ee2`). **Fixed:** A now uses B and C's rule: the first `pause_game` or `ui_cancel` press closes the card and the next `pause_game` pauses.
4. **Its world text chip broke the LABELS decision.** **Fixed:** the chip is gone. The reader's state is a lamp on the bolt panel with a distinct shape per state (padlock, ring, cross, draining-ring padlock, tick, warning triangle, disc), and the words appear only in reach and on the card.
5. **The klaxon read as the sentry waking.** **Fixed:** the lockout plays a new reader-lock tone and DOOR FORCED a repeating door-alarm tone (a slow hi-lo). Neither reuses the `klaxon`, the sentry's lock-on cue (`_sentry_alarm`, `main.gd:2403-2404`), and the lockout no longer pulses the room's beacons.
6. **Its list of changed lines missed one.** **Fixed:** the autosave-C restore line (`main.gd:1549`, `1600` at `cfe304f`) is now J17: "Service junction restored. The sentry is down; the hatch reader is by the exit."
7. **Tap and hold at the panel were undefined.** **Fixed:** once MANUAL RELEASE is chosen, holding USE cranks (only from a fresh press), and a tap released before the first 0.4 s tick reopens the card on release with the ticks kept. A correct code after some cranking still wins.
8. **Smaller points:**
   - Touch gaps of about 8 px were about 6 pt, under Android's 8 dp. **Fixed:** 12 px on touch.
   - A Records screen showing a hatch override for a room two rooms away in plain text is a little convenient. "SERVICE LINE / ACCESS" carries it.
   - The screen's reach (280-345) pushes the approved DATA CARTRIDGE reader from 330-400 to 360-400, which is an approved-placement change.
   - It depends on the evidence case and save v5, or costs about 1 day more without them.

**Cost:** about 7.25-7.75 days to build, plus 1-1.5 days for play passes.

---

## 4. Option B: lockdown access (6 / 10)

**The design.** Every door reader shows LOCKDOWN. The junction's existing winch reroute (approved POP_BOLT) wakes the exit bolt's reader to LOCAL. The code then comes one of two ways:
- WOLF reads it off the panel from his spot in the hatch doorway, on either relay route; the memory changes only his line (revised; the first draft gated this on the relay memory).
- Or the engineer holds USE for 1.2 s to tear a tamper-sealed override card.

The code is always on file before the card opens, and wrong codes lead to an 8 s lockout. The other doors get lamps only.

**What works**
- It has the strongest military-base read of the three. One networked lockdown shows on every door in all three rooms (LOCKDOWN / LOCAL / OPEN / DOOR FORCED), and each door teaches a different way through: bypassed, forced, overridden. "The automated network, not a person, decides who gets through" is the mood Nathanial pointed at.
- The keypad grows out of existing play (the winch's power) instead of being bolted on.
- The engineer-only code source is at the same station, so there is no errand.
- The door lamps are cheap (about 0.75 day). They fit the LABELS decision (state on lamps) and the approved shutter art, which already has a status lamp.

**Where it fails**
1. **The PIN play is ceremony.** The code is on file before the card opens, so nearly every player presses ENTER KNOWN CODE once. The 8 s lockout is reachable only by deliberately typing something else while the right code sits on screen (see `04-lockout.png`: "ON FILE: 7294"). That spends about 3 days of keypad card for one button press. B admits this is "the wrong option if Nathanial wants a real code puzzle".
2. **A rushed WOLF held back a third time.** **Fixed:** WOLF now reads the code on both relay routes, with a cooler line when rushed (T8: "WOLF puts his readout to the panel without a word. / WOLF: Local code. On my readout."). At `cfe304f` he reads it from his spot in the hatch doorway, with no walk.
3. **The code sits in a sleeve beside its own lock.** It is grounded in break-glass practice, but players will ask why the lock exists at all, and the tamper sleeve is a tiny red rectangle at game scale (`07-world-local-sealed.png`).
4. **It made a case entry required to finish.** **Fixed as a side effect of item 2:** with WOLF reading on every route, the OVERRIDE CARD is only one of two sources and nothing in the case is required.
5. **It is the heaviest text load:** T1-T25. It changes the blast-door line. **Fixed:** the narration "by his own choice" is gone; T7 now shows the action ("WOLF puts his readout to the panel.").
6. **Controls:**
   - Keys are 90x66 canvas px, about 48 pt. That is at the floor and below the 78 px target (**not changed**). Touch gaps are now 12 px (**fixed**).
   - Captions were 10-11 px. **Fixed:** every caption is at least 12 px (`03-denied.png`).
   - Pad X and Y share `choice_1` and `choice_2` with keyboard 1 and 2. **Fixed:** the card treats them as delete and known code only for joypad events.
7. **One mock state contradicted itself.** **Fixed:** `shots/06-world-lockdown.png` now shows one state: sentry down, reader still LOCKDOWN before the first USE, with today's hint "E: pop the exit bolt." and the autosave-C restore line. The world reader also lost its tiny painted word; its state is the lamp shape.
8. **Pacing:** it adds 3-5 s (up to 13 s with a lockout) after the tank-drop climax. **Fixed:** the lockout uses a reader-lock tone, not the klaxon, and no longer flares the beacons.

**Cost:** about 7.5-8.5 days, before play passes.

---

## 5. Option C: small and optional first (5 / 10)

**The design.** Two optional keypads:
- **K1, MEDIA LOCKER (Records).** It holds the DATA CARTRIDGE and takes the engineer's own MAINT code, which is known from the start.
- **K2, LANE TERMINAL (junction, phase 2).** It holds the SENTRY PATROL LOG. Its code is pulled over the terminal's paired link to the downed sentry with one hold at the terminal, or WOLF offers to read the link from the hatch doorway (revised; the first draft sent the engineer or WOLF to the sentry and back).

A wrong code costs at most 6 s. The essential path never asks for a code.

**What works**
- It has the lowest risk: no essential route changes. It teaches the keypad in the hazard-free room, as the audit suggests.
- It is the only option that measured every line against the game's fonts.
- K2's payoff, "STAND-DOWN CODE: NO RECORD" (approved text), is the best mood beat in any option. The machine had a pairing code but no off switch.
- K2 copies the approved MIRROR PORT pattern and offers on both relay routes, with only WOLF's tone changing. That respects the "refuses rarely" decision.
- Its plan to grow in phases, and to play the card before adding more keypads, is the right discipline.

**Where it fails**
1. **It barely answers the request.** Nathanial asked to add PIN codes and make the base feel military. In phase 1 that becomes one optional locker whose code is the engineer's own, shown on the card and entered in one press. A player who skips it never sees a code, and the main path gains nothing military until phase 3.
2. **It puts friction on the first pickup.** K1 moves the approved DATA CARTRIDGE, the planned first, tap-USE pickup, behind a keypad. That adds steps to the pickup meant to teach the case, and it changes an approved placement.
3. **K2 was an errand loop** (terminal, walk to the sentry's port, hold, walk back, enter). **Fixed:** the pairing code is pulled at the terminal over its paired link with one 1.2 s hold, so the engineer never leaves the terminal. It is still two steps (refused, then hold) where the approved LOG_LANE was one hold.
4. **K2 conflicted with round 3.** **Fixed:** WOLF's offer and read happen from his spot in the hatch doorway (x 902); he never crosses back over the tank. K2 still has no floor in today's junction.
5. **K2 invites an awkward question.** Why could a pairing code be pulled from the sentry's link but no stand-down code? C flags this itself (not changed).
6. **Cost against payoff:** 5.5-6.5 days for phase 1 delivers one optional, mostly ceremonial locker. Phases 1 and 2 now cost about 7-8.5 days (K2 is cheaper without the port station), and K2 is blocked on the junction rebuild.
7. **Mock issues, all fixed:**
   - The K1 stills now show WOLF at the mirror (`k1-0-room.png`).
   - The K2 terminal is a wall-mounted schematic that no longer overlaps the tank, with WOLF in the doorway (`k2-1-idle.png`).
   - Touch gaps are now 12 px (`k1-3-wrong.png`).
   - K1's code moved from 4072 to 6138, so it is no longer a near-twin of A's 4071.

---

## 6. The recommendation: A, plus B's door lamps (and C's discipline)

**From A, take:**
- the ACCESS SCREEN in Records as the code's source, kept on the walk from the purge queue to the mirror;
- the SERVICE OVERRIDE case fact (the save stores the id only; the digits live in a code table);
- one essential keypad at the junction exit bolt, in the calm beat after the sentry falls, where the reader mode follows real state;
- the keypad card at A's touch sizes, with the known-code button first;
- MANUAL RELEASE as the engineer-only fallback;
- the 5 s lockout that never blocks MANUAL RELEASE;
- WOLF as a noticer only: his NOTICE or IGNORE line at the screen, and turning to the lane during the alarm.

**Leave out of A:** the world text chip (use a lamp instead) and the WOLF-reads-the-reader variant.

**From B, take:**
- the lockdown lamp language on the other doors, shown on each door's own status lamp with a distinct shape per state:
  - corridor seal: LOCKDOWN, then OPEN;
  - Records exit: LOCKDOWN until FIRST COPY, then OPEN;
  - junction blast door: LOCKDOWN / SECURE SIDE, then DOOR FORCED after the blast;
- later, once the wider corridor exists, the seal reader's USE refusal of the engineer's own maintenance code (B's T1). It is the cleanest set-up for A's "PERSONAL CODES REVOKED".

**Leave out of B:**
- WOLF's code read (now on both routes, but A never makes WOLF a source);
- the tamper-sealed card;
- the reader waking to LOCAL;
- the 8 s lockout.

**From C, take:**
- the build order: logic class, then the card, then one keypad, then a hands-on pass on desktop, controller and a real phone before any second keypad;
- measuring the fit of every line against the game's fonts;
- consuming digit keys before `Main._input`.

**Keep for later:** K2's "no stand-down code" beat, once the junction is rebuilt, the errand is removed and round 3's WOLF route allows it.

**Fixes that are part of the pick:**
- the arc and flash play on both routes;
- a door-alarm tone that is not the sentry's klaxon;
- lamps instead of text chips;
- `pause_game` and `ui_cancel` close the card first.

**Order and cost (rough engineer days, one person):**
1. Door lamps on today's doors and the approved shutter art: about 0.75-1 day. No save change, and it ships before anything else.
2. Keypad logic class, card, hatch reader, MANUAL RELEASE (with the arc on that route too), lockout and sounds: about 5-5.5 days.
3. The ACCESS SCREEN, the case fact, WOLF's reactions and the save inside v5: about 1.25 days. It waits for the evidence case, or costs about 1 day more with a minimal known-codes fact.
4. Debug hooks, recap row and docs: about 1.25 days.
5. Play passes on desktop, controller and phone, with fixes: 1-1.5 days.
6. Later: the corridor seal refusal, about 0.25 day once the wider corridor exists.

**Total: about 9-10.5 days** including the play passes.

---

## 7. Fixes before Nathanial sees them: what was done

Each option keeps its own idea; only the listed problems were fixed. Every still was re-rendered in a normal Godot 4.7.2 window from a scratch export of `cfe304f` (`export-cfe304f/`, imported headless twice, then once more after adding the mock scripts, `HOME` set to `home-pin`; each window quit itself). The strips and `sheet.png` were rebuilt. Each DESIGN.md opens with a "Revised before showing" list.

1. **A, the arc on both routes. Done.** At 6/6 MANUAL RELEASE hands over to `_pop_bolt()` and `_bolt_arc()`: the alarm stops, then POP_BOLT, the whine, BOLT_ARC (flash, shake, sparks, rumble) and HATCH_OPENED play exactly as on the code route. Old line J12 is removed. New stills: `7-manual-crank.png` (mock crank, DOOR FORCED lamp) and `8-manual-arc.png` (the game's own arc at `cfe304f`, set off by today's bolt USE).
2. **A, Esc and Start. Done.** The first `pause_game` (Esc or Start) or `ui_cancel` (B, Android Back) press closes the card; the next `pause_game` pauses. The legend now reads ESC CLOSE.
3. **A, lamps not a world chip. Done.** The chip is gone from the design and the stills. A code-drawn lamp on the bolt panel shows LOCKED (still padlock), OVERRIDE ONLY (ring and dot), DENIED (cross), READER LOCKED (padlock in a draining ring), GRANTED (tick), DOOR FORCED (flashing triangle) and OPEN (disc). Words appear only in reach and on the card (J5). The corridor seal lamp uses the same shapes, so A plus B's lamps share one lamp language.
4. **A, the restore line and tap versus hold. Done.** J17 replaces the autosave-C line (`main.gd:1549`; `1600` at `cfe304f`): "Service junction restored. The sentry is down; the hatch reader is by the exit." (1 row, 571/855, measured). Once MANUAL RELEASE is chosen, a hold cranks (only from a fresh press) and a tap released before the first tick reopens the card on release, keeping the ticks (J13: "Hold E: crank the manual release. Tap E: keypad.", 299/526).
5. **A and B, a door-alarm tone. Done.** A: a reader-lock tone for the lockout and a repeating hi-lo door-alarm tone for DOOR FORCED; the lockout no longer pulses the room's beacons. B: a reader-lock tone, no klaxon and no beacon flare; the blast door's DOOR FORCED lamp plays under the blast's own sound. C (same concern, though not listed): K2's lockout no longer strobes the lane beacons. No keypad path uses the `klaxon` in any option, and each test plan now checks that.
6. **All three, touch gaps. Done.** A: 92x78 keys with 12 px gaps (card 596 wide at x 40). B: 90x66 with 12 px gaps (card 602x368). C: 84x74 with 12 px gaps. 12 px is about 8.6 pt at a 390 pt phone's 0.72 scale, over Android's 8 dp. Shown in A's `6-touch-unknown.png`, B's `03-denied.png` and C's `k1-3-wrong.png`. Still to be checked on a real phone.
7. **All three, joypad A firing twice. Done.** Each design now says: inside the card only `ui_accept` presses keys, and `interact` arriving from a joypad event is ignored; keyboard E (`interact` from a key event) still presses the focused key. Each test plan checks that one A press presses a key exactly once.
8. **All three, re-rendered on `cfe304f`. Done.** A and B keep WOLF where round 3 puts him (`WOLF_DOWN_X`, the hatch doorway, snout at the bolt panel's right edge). B's WOLF read now happens from there, with no walk. A's J14 became "WOLF keeps his eyes on the lane while the alarm sounds.", since he already faces the lane there.
9. **B, the contradictory still and the rest. Done.** `06-world-lockdown.png` now shows one consistent state (sentry down, reader LOCKDOWN until the first USE, today's hint and restore line). WOLF reads the code on both relay routes; only his line changes (T7 warm, T8 cool: 2 rows, 385/715). Captions are at least 12 px. Pad X and Y act as delete and known code only for joypad events. The world reader's tiny painted word was removed (LABELS). The "by his own choice" narration is gone.
10. **C, K2 and the K1 stills. Done.** K2's errand is gone: the code is pulled at the terminal over its paired link with one hold, or WOLF reads the link from his doorway spot without crossing the tank. New lines were measured (offers 451/715 and 356/715, read 568/855, hint 258/526). K2 costs about 1.5-2 days instead of 2-2.5. The K1 stills now show WOLF at the mirror, and the K2 terminal no longer overlaps the tank.
11. **All three, "DENIED 1/3". Done.** Each design now says it counts tries before the lockout, not the "1 of 5" kind of completion count the item rules forbid, and the sheet repeats it. Nathanial should still confirm he reads it that way.
12. **Digit sets. Done.** C's maintenance code moved from 4072 to 6138, so it is no longer a near-twin of A's 4071. The placeholders are now A 4071, B 7294 and C 6138; if options are combined, keep one set.

**Not changed, on purpose:** A's number pad when no code is known (problem 2 under A; now A's risk 12), B's 90x66 key size and its ceremony, C's phase-1 scope and K2's missing floor. None of these was on the fix list, and changing them would change the option's idea.

**Checks behind this revision:** rendered stills only, looked at by eye. Line fits measured with Pillow against the game's Roboto (`fixlogs/fit_new.py`). Nothing was played, no headless game test was run, and nothing was exported or tried on a device. The scores in section 1 are the review's, from before the fixes.

---

## 8. Questions this leaves for Nathanial

1. A plus B's lamps, or one option as drafted?
2. Should the ACCESS SCREEN stay optional (a reward for exploring, with MANUAL RELEASE for the rest) or sit on the essential path in Records, so every player types a code?
3. The digits: approve a code (4071 is a placeholder), a 0451 homage, or a •••• mask? A's find needs real digits.
4. New story facts that all three options share: the engineer has a personal maintenance code, and the lockdown revoked it. Do you approve them?
5. MANUAL RELEASE now sets off a DOOR FORCED alarm (its own tone, not the klaxon) and then plays the same bolt arc as the code route. Keep both?
6. Approve the new reader-lock and door-alarm tones, so the klaxon stays the sentry's cue?
