# PIN option A: the found code

**Private design material.** Keep it out of Git, public docs, PR text and build output. This option answers Nathanial's request of 2026-10-11: "Can we add some pin codes and make it feel more like a furttgrue milialry base like iin skynet". The Terminator films' AI-run defence network is a mood reference only. Nothing here uses Skynet, Terminator or Cyberdyne names, logos, designs or text. The art side is handled in a separate job. **Nothing was built.** Every player-facing string is **proposed, awaiting Nathanial**. The code `4071` is a placeholder until he approves real digits.

- One-image summary: `strip.png` (in this folder)
- Rendered stills: `shots/mock/` (the Records find; idle, entering, wrong, lockout, accepted and touch without the code; the MANUAL RELEASE crank and its arc). All were re-rendered on `main` at `cfe304f` (logic round 3), where WOLF waits in the hatch doorway once the sentry is down.
- Mock driver: `driver/mock.gd`, `driver/run.sh`, `driver/strip.py`
- Basis: `../research/RESEARCH.md` (sourced research) and `../audit/AUDIT.md` (code audit at `7c19ee2`). Section numbers below such as R1.2 or A2.3 refer to those files. Code line numbers are given at `7c19ee2`, with the `cfe304f` line in brackets where it moved.

**Revised before showing (2026-10-11), after the judge's review.** What changed:
1. MANUAL RELEASE now ends in the same bolt whine, arc, flash, shake and hatch as the code route (section 4.3). Skipping the optional screen never costs the slice's climax (inventory rule 3).
2. The card follows the shared close rule: Esc and Start are both `pause_game`, so the first `pause_game` or `ui_cancel` press closes the card and the next one pauses (section 6.2).
3. The reader's state is shown on a lamp with a distinct shape and colour, not a world text chip (2026-10-11 LABELS). Words appear only in reach and on the card (sections 2.2 and 6.3).
4. The autosave-C restore line (`main.gd:1549`, `1600` at `cfe304f`) is now in the changed lines (J17). Tap and hold at the panel are defined once MANUAL RELEASE is chosen (section 4.3).
5. Lockout and DOOR FORCED use their own procedural tones, not the `klaxon`, which is the sentry's lock-on cue (section 5, item 7).
6. Touch key gaps are 12 canvas px, about 8.6 pt, over Android's 8 dp (section 6.1).
7. Inside the card only `ui_accept` presses keys; `interact` from joypad events is ignored there, so one A press never fires twice (section 6.2).
8. The junction stills were re-rendered on `cfe304f` with WOLF in the hatch doorway, and two stills were added for the MANUAL RELEASE route.
9. "DENIED 1/3" is stated as a tries count, not a completion count (section 4.1).

---

## 0. The idea in one paragraph

In Records Access the engineer can stop at a small wall screen, the **ACCESS SCREEN**, on the walk from the purge queue to the mirror. It shows that the lockdown revoked everyone's personal codes, but one **hatch override** was never changed. Holding USE copies it into the case as a fact named **SERVICE OVERRIDE**. Nothing has to be written down. Two rooms later, with the sentry down, the Service Junction's exit bolt turns out to be a **lockdown reader set to OVERRIDE ONLY**. A player who read the screen enters the code with one press, or types it, and gets the approved bolt whine, arc and hatch with a small "I knew that" moment. A player who skipped the screen, or who types wrong codes until the reader locks, can always use **MANUAL RELEASE**: a short hold-to-crank that sets off a DOOR FORCED alarm. That costs time and nerve, never progress, which is the same promise as the corridor's manual bypass. WOLF can notice the screen when the engineer reads it, and how he reacts depends on the relay memory. He never fetches the code, never says the digits and is never its only source.

---

## 1. The rules this option keeps

| Rule (source) | How option A keeps it |
|---|---|
| The engineer is the only playable character, and WOLF has no request verb (PRIVATE_AGENTS, research README) | Only the engineer reads, enters or cranks. WOLF reacts on his own. |
| Every essential step has an engineer-only route (PRIVATE_AGENTS, inventory rule 2) | The hatch is essential. Two engineer-only routes open it: the found code and MANUAL RELEASE. Neither needs WOLF. |
| WOLF never fetches. He notices or pointedly ignores items (research README "WOLF") | WOLF's only part in the code is a NOTICE line or an IGNORE beat at the moment the engineer reads it. |
| WOLF refuses rarely and meaningfully (2026-10-10 Codex review) | WOLF never refuses anything here. Reading a code costs him nothing, so a refusal would be petty (A1). |
| No optional find gates progress, and rewards are understanding and relationship, never stats (inventory rule 3) | The find opens nothing that MANUAL RELEASE cannot, and both routes end in the same bolt arc, flash and hatch. What it adds is the story beat, the record, WOLF's line and a recap row. It saves about 2 s, which is not a stat (see the risk in section 11). |
| A failure costs at most the current beat (Secure the Evidence) | A wrong code costs about 1 s. Three wrong codes cost 5 s. There is no knockdown, no death and no autosave rollback. |
| Records are facts with no slots (README "Case") | SERVICE OVERRIDE is a LOG entry in the case. It is never spent, counted or selected. |
| No canon numbers; mask or flag them (item brief) | `4071` is a flagged placeholder. It does not come from 03:17, the purge time or the target ID (A0). |
| WOLF "never speaks key names or button instructions" (logic text voice rule) | WOLF never says the digits. They appear only on the screen, in the case and on the keypad. |
| No hidden hitboxes; a label plus its action appears in reach; status shows on lamps (inventory rule 5, the 2026-10-11 LABELS note) | The screen is a lit, code-drawn prop. Its name and verb appear only in reach. The hatch reader's state is a lamp (shape plus colour); its words appear only in reach and on the card. |
| Mobile is a first-slice target; prefer no new input actions | The keypad card uses the existing InputMap and `ui_*` actions plus typed digits (section 6). |
| Lighter game: one shared component (feedback-lighter-game) | One `Keypad` logic class and one `KeypadCard` UI serve this reader and any later one. |
| Keep the timed and risky beats untouched (A2) | The breaker, relay, bypass, valve, tank release, safe points, the containment gate and the sentry get no code. The approved "STAND-DOWN CODE: NO RECORD." stays true. |

---

## 2. Where the keypads are and what each protects

Positions are world x in today's 960 px rooms. The level expansion widens Records and the Junction to about 1,440 px. Place each piece **by beat** and re-measure after each grey box.

### 2.1 Records Access: the ACCESS SCREEN, where the code is found (no keypad)

- **What it is:** a small wall-mounted maintenance screen, lit amber, code-drawn like the purge display. No image art is needed for a first pass. A Look 2 prop can replace it later.
- **Where:** on the back wall between PURGE QUEUE (190 ± 58, so its reach ends at 248) and the planned DATA CARTRIDGE reader (330-400). The mock draws it at x 312-352 with a reach of about 280-345 for the engineer's centre. With the cartridge kept at 360-400 and reach checked by the planned `pickup_overlap` test, the two stay separate. In the expanded room, keep it **on the walk from the purge queue to the mirror**, so nobody has to backtrack to it, and well clear of the planned safe point.
- **Essential?** No. It is an optional read that everyone walks past.
- **Protects:** nothing. It is the code's source.
- **States:** unread, where the amber text lines glow and the label in reach reads ACCESS SCREEN with "Hold E: copy the screen.", and copied, where the label reads ACCESS COPIED in green, matching PURGE COPIED and MIRROR COPIED.
- **Interaction:** hold USE for 2 HoldUse ticks (0.8 s), the same "hold USE to copy" that the approved LOG_CORRIDOR and LOG_LANE placements use. It writes the case entry and its toast reuses the approved toast format: `Logged: SERVICE OVERRIDE`.

### 2.2 Service Junction: the HATCH READER on the exit bolt panel, where the code is used (the one essential keypad)

- **What it is:** today's EXIT BOLT panel (`JunctionRoom.BOLT_PANEL_X` 806, reach from `BOLT_REACH_MIN_X` to the hatch at 880) gains a reader. It gets a code-drawn **status lamp** above the panel and the keypad card on USE. The panel art is unchanged. There is no world text chip (2026-10-11 LABELS: state on lamps, words only in reach). In reach, the station's existing label carries the name and the action, for example `EXIT BOLT · E: use the hatch reader`.
- **WOLF at `cfe304f`:** once the sentry is down, WOLF waits in the hatch doorway at `JunctionRoom.WOLF_DOWN_X` (902), facing back down the lane, just right of the bolt panel. He never walks back across the tank. The card opens on the left half of the screen, so he, the engineer, the lamp and PAUSE stay visible (`shots/mock/1-idle.png`).
- **Protects:** the service hatch, which is the slice's exit. Behind it come autosave D and the END OF SLICE card.
- **Why here:** it is the calm aftermath after the sentry falls (A2.3). The beat is already framed as a lockout ("The exit bolt is locked out while the sentry runs the line."). No timer, sentry or vent is live there.
- **Reader modes follow real state (Lenel and Genetec reader modes, R1.5):**

| Game state | Reader lamp (shape and colour; no world text) | Word, shown only in reach and on the card | USE at the panel |
|---|---|---|---|
| Door not blown | dark | none | unchanged: "The exit hatch is bolted. The lane past the door comes first." |
| Door blown, sentry on the line | steady red padlock | LOCKED | unchanged: "The exit bolt is locked out while the sentry runs the line." No card opens. |
| Sentry down, bolt locked | amber ring with a dot | OVERRIDE ONLY | opens the keypad card |
| Card: wrong code | red cross, blinks twice | DENIED | n/3 on the card |
| Card: three wrong codes | red padlock inside a ring that drains over 5 s | READER LOCKED | the card stays open. The keys are disabled for 5 s. MANUAL RELEASE still works. |
| Code accepted | green tick | GRANTED | the card closes after 0.6 s. Then the approved POP_BOLT, BOLT_CHARGING, BOLT_ARC and HATCH_OPENED lines play unchanged. |
| Manual release chosen or cranking | flashing red warning triangle | DOOR FORCED | hold USE to crank, tap USE to reopen the card (section 4.3) |
| Bolt popped, either route | green tick, then a solid green disc as the hatch opens | OPEN | unchanged: leave through the hatch |

The two padlocks differ by more than colour: LOCKED is a still padlock, READER LOCKED has the draining ring (motion plus shape), and the countdown digits are on the card. With reduced motion the ring is a static three-quarter arc.

- **The coolant cloud:** a tank hit sprays a 3 s cloud at the floor mark (700 ± 52 plus the engineer's half width), which can overlap the left edge of the bolt reach. USE does not open the card while the engineer stands in an active cloud. The existing "Coolant cloud. Get out of it." hint wins. While the card is open it holds the game still, as the answer row and the debug menu do, so nothing can knock the engineer down behind it.

### 2.3 Maintenance corridor: the seal reader lamp (optional dressing, no interaction)

- A small reader lamp on the red seal's portal shows a steady red padlock (LOCKDOWN) from the opening. When power opens the seal it changes: a green disc (OPEN) on the relay route, or the flashing red triangle (DOOR FORCED) for a beat on the manual bypass route, then the green disc. The words appear only in reach, in the seal's own label.
- It teaches the lamp language (shape plus colour; the word in reach) before the junction uses it. It gates nothing, adds no USE station and adds no line to the dialogue box.
- It uses the same lamp shapes as B's door lamps, so the recommended combination (A plus B's lamps) has one lamp language across the corridor seal, the Records exit, the junction blast door and the hatch reader.
- The corridor has only about 20 px of free floor before the shutter (A2.1), and the shutter art belongs to the art job. So this piece is the lamp only, and it waits for the expanded corridor and the art job's portal. **Optional; cut it first if time is short.**

---

## 3. How the engineer learns the code, and what WOLF does

### 3.1 The engineer-only route (always works)

1. The engineer passes the ACCESS SCREEN between the purge queue and the mirror. Its label and verb appear in reach.
2. Holding USE (0.8 s) copies it. The dialogue box shows the screen text (section 7, line R2). The hint bar shows `Logged: SERVICE OVERRIDE`.
3. The case gains a LOG entry, SERVICE OVERRIDE, found in RECORDS ACCESS, with the same text. The planned Pause CASE tab can re-read it at any time. The digits never have to be remembered.
4. At the junction reader, the card shows the known code as a button, **ENTER 4 0 7 1**, under "FROM YOUR CASE: SERVICE OVERRIDE", and gives it focus. One press of USE, A, Enter or a tap enters it: the digits fill one by one with a beep each (about 0.6 s in total), then ACCESS GRANTED. Typing it on the pad works too.
5. If the engineer skipped the screen, the card shows no known-code row, and focus starts on **MANUAL RELEASE**, the route that works. Under it a muted note says honestly what it costs: "Crank the bolt back by hand. It sets off the door alarm." Nothing says "you missed something", because no text grades the player (item brief).
6. **Knowledge is a key** (Prey, R2.1). A replaying player who remembers 4071 can type it without having read the screen this run, and the reader accepts it. The case does not gain the record, because the record is the screen. The recap says so (section 7, line J15).

### 3.2 WOLF: notices, never fetches, memory-gated tone only

WOLF's own skills here are physical and machine reading: he scouts the seam, reads gauges and reads the mirror. In this option, reading a maintenance screen is the engineer's skill as the base's systems engineer. That divides the work between them instead of making WOLF a code dispenser.

| Moment | Relay memory: disclosed ("The relay may vent coolant. Your call.") | Relay memory: pressed ("Go now. We can talk after.") |
|---|---|---|
| The engineer copies the ACCESS SCREEN | NOTICE, one line when the engineer steps away from the screen, so the screen text gets read first: "WOLF: They revoked everything but that." | IGNORE beat (narrator): "WOLF doesn't look at the screen." |
| In the case, re-read later | optional timeless annotation: "WOLF: They revoked everything but that." | none (derived-record precedent: no ignore beat in the case) |
| The engineer enters the known code and the reader grants | "WOLF: The one they forgot." | none |
| MANUAL RELEASE alarm (any route, code known or not) | narrator action: "WOLF keeps his eyes on the lane while the alarm sounds." At `cfe304f` he already waits in the hatch doorway facing back down the lane, so he stays put; no walk is needed. | the same line. Protecting is his own choice whatever the memory, so a cold version would read as sulking. |

- WOLF is never a code source, so the essential route never depends on him (inventory rule 2).
- He never says digits (voice rule) and never points at the screen before it is read, because he is not a detector (item brief).
- Memory changes only his tone, never what the engineer can do (A1, "a refusal would be petty").
- **What changes if WOLF helps:** on the disclosed route the player gets an extra authored WOLF line twice, which is the relationship reward inventory rule 3 asks for. Progress is identical on both routes.

### 3.3 A variant for Nathanial (not the default): WOLF reads the reader

If Nathanial wants WOLF to act at the reader as well, the precedent is the mirror port. When the code is not known and the relay memory is disclosed, WOLF offers his readout. The answer row reads "1 USE WOLF'S READOUT / 2 MANUAL RELEASE", and the reader's last accepted entry appears on his readout and goes into the case. **Not recommended as the default.** It makes the find redundant on the disclosed route, adds a second memory-gated help in the same room as the lane question, and "it would log me on the Director's network" (a tempting reason for WOLF to hesitate) would be a new story fact. If wanted anyway: 1 day more, two new lines and the route matrix doubles at the reader.

---

## 4. What a wrong code does

### 4.1 One wrong code

- The readout digits turn red, the readout border turns red, a cross lamp lights and **DENIED 1/3** shows with "CODE NOT ACCEPTED". "1/3" counts tries before the lockout. It is not the "1 of 5" kind of completion count the item rules forbid; Nathanial should confirm he reads it that way. The reader plays three short low beeps, the common OSDP denied pattern (R1.5, [S]). An optional 60 ms buzz follows if haptics are on. On a controller the existing `impact.rumble` gives a short low rumble.
- After 0.8 s the readout clears for the next try. Focus stays where it was. Cost: about 1 s.

### 4.2 Three wrong codes: the military lockout

- Real readers lock out after about 3 wrong tries (PIV after 3; Schlage for 30 s after 3, [S]; R1.1-1.2). The game uses **READER LOCKED** for **5 s**:
  - The keypad keys and the known-code button are disabled and dimmed, with a visible countdown (0:05 … 0:01).
  - The reader's own lamp shows the padlock in a draining ring. One new procedural **reader-lock tone** plays: two falling low square-wave notes, about 0.5 s. It is **not** the `klaxon`, which is the sentry's lock-on cue (`_sentry_alarm`, `main.gd:2403-2404`, `2523-2524` at `cfe304f`), so nothing next to the downed sentry suggests it is waking.
  - The room's lockdown beacons do not change, for the same reason.
- **MANUAL RELEASE never locks** and gets focus during the lockout, so there is never a dead end.
- After the countdown the counter resets to 0/3 and the reader returns to OVERRIDE ONLY.
- What it never does:
  - wake the sentry or spawn any threat;
  - knock the engineer down or kill them;
  - roll back an autosave;
  - write anything to the save;
  - show a fake consequence such as "SECURITY NOTIFIED". AGENT.md: "Do not show fake ... consequences".
- **Worst case:** 3 wrong codes plus a 5 s lockout plus about 2.4 s of manual release, roughly 10 s. That is well inside the current beat.

### 4.3 MANUAL RELEASE: the engineer-only fallback

- Choosing MANUAL RELEASE closes the card. The panel becomes a hold station: `_hold_station()` returns `&"bolt_release"` while the sentry is down, the bolt is locked, MANUAL RELEASE has been chosen and the card is closed. It uses HoldUse's existing 0.4 s ticks and needs **6 ticks (2.4 s)**. Ticks survive a release, a pause or stepping away, as at the bypass.
- **Tap versus hold at the panel, once MANUAL RELEASE is chosen:**
  - Holding USE cranks. Cranking starts only on a fresh press, so the press that chose MANUAL RELEASE on the card never makes a tick (the card releases `GAMEPLAY_ACTIONS` as it closes).
  - A tap, meaning USE released before the first 0.4 s tick lands, **reopens the keypad card** on release, with the crank ticks kept. A player who changes their mind, or remembers the code, can still enter it. The card opens on release, not on press, so a hold never flashes the card open.
  - A correct code entered after some cranking still wins: the ticks are discarded and the code route plays.
  - Before MANUAL RELEASE is chosen, any USE press opens the card, as in section 2.2.
- The touch USE label becomes CRANK, as it already does at the valve and bypass. The hint in reach reads "Hold E: crank the manual release. Tap E: keypad." (J13; prompt substitution makes it the right key or button).
- While cranking:
  - The **DOOR FORCED** alarm runs: the reader lamp flashes the red triangle and a new procedural **door-alarm tone** repeats about every 1.2 s. It is a slow two-tone hi-lo (about 620 and 465 Hz, soft square), not the `klaxon`. The `klaxon` stays the sentry's lock-on cue and the corridor bypass alarm, so nothing at the hatch promises a consequence that never comes.
  - Each tick plays a ratchet click (the TOOL_A ratchet sound when it exists).
- **At 6/6 the route hands over to the code route's chain.** The bolt is cranked free of the reader's lock, so the winch feed reaches it: the alarm stops, and `_pop_bolt()` plays POP_BOLT and its 0.6 s whine, then `_bolt_arc()` plays BOLT_ARC with the arc, flash, sparks, shake and rumble, then HATCH_OPENED. All four approved lines play unchanged. The climax is identical on both routes; only the step before it differs (`shots/mock/8-manual-arc.png` is the game's own arc at `cfe304f`).
- This is the same promise as the approved bypass framing: "doing it yourself costs time and nerve, never progress".

---

## 5. What makes it feel like a near-future military base

Every item below comes from real access control (R1). All of it is typeset in code, so no text is painted by the image tool.

1. **Lockdown reader modes tied to real state**: LOCKED, then OVERRIDE ONLY, then GRANTED or DOOR FORCED (Lenel Locked mode and Genetec threat levels, R1.5). They show on the reader's lamp as distinct shapes and colours, so the reader reads as a networked base system, not a puzzle box. The words appear in reach and on the card.
2. **Personal codes revoked**: the opening's approved order "Lock down maintenance" already implies it. The ACCESS SCREEN says it outright, and the corridor seal lamp shows the LOCKDOWN padlock from the start.
3. **A real procedural lapse as the "wrong note"**: "CHANGE: OVERDUE". ICS 705 requires administrators to change default maintenance and master PINs (R1.1, [F]). The override that was never changed is plausible, quietly unsettling and story-neutral. It does not say who or why, following the item brief's "hint, never reveal".
4. **Four random digits** (ICS 705 minimum, R1.1). The placeholder avoids the codes people actually pick (1234, 0000, 19xx; R1.6) and any number already in the story.
5. **Lockout after three tries and a door-forced alarm** (R1.2, R1.5), with an amber, red and green lamp, a beep pattern and a named state, as real readers show.
6. **Stencils and furniture**: the card header SERVICE HATCH / LOCKDOWN, a RESTRICTED AREA tag, a thin amber hazard band, a 3×4 phone-layout pad and big readout digits. It uses the game's MenuPanel card, CardSheen and Montserrat and Roboto fonts, so it looks like the game and not the Settings terminal.
7. **Sound**: procedural, in SfxBank like the existing `klaxon` and `whine`. A 1.2 kHz key beep with a small pitch jitter, a denied triple beep, a granted rising chirp, a **reader-lock tone** for the lockout and a repeating **door-alarm tone** for DOOR FORCED. Neither reuses the `klaxon`: it is the sentry's lock-on cue (`main.gd:2403-2404` at `7c19ee2`), the corridor bypass alarm and the fuse cue, and beside a downed sentry it would promise a consequence that never comes (AGENT.md: no fake consequences).

**Deferred on purpose:**
- Duress codes, which feel unfair in a slice.
- Scramble pads, which break focus memory and hurt readers who transpose digits (R2.4).
- Card plus PIN, which would add a badge item. The item set caps it ("no ID or badge").
- The two-person rule, which would need WOLF at a second reader and is a separate design.

---

## 6. The keypad card (touch, controller, keyboard)

Rendered stills at 1280×720 in the game's own theme and fonts: `shots/mock/1-idle.png`, `2-entering.png`, `3-wrong.png`, `4-lockout.png`, `5-accepted.png` and `6-touch-unknown.png`. They are mocks drawn over a frozen real frame and were not played.

### 6.1 Layout (960×540 canvas units)

- **Card:** a `MenuPanel` plus `CardSheen` at x 72 on desktop (576×410) and x 40 on touch (596×428, wider for the gaps). It sits left of the panel, so the engineer, WOLF in the hatch doorway, the reader lamp and PAUSE stay visible. While it is open, a dim backdrop covers the world, and the dialogue box, hint bar and touch movement buttons hide. The top objective card stays (section 7, line J1).
- **Header:** SERVICE HATCH / LOCKDOWN (Montserrat Bold 19), the RESTRICTED AREA tag, and a 5 px amber hazard band.
- **Left column (238 wide):**
  - a readout of four big digit cells (Montserrat Bold 38) with a cyan underline under the next cell;
  - a state row: lamp shape plus word, for example ENTER OVERRIDE or DENIED 1/3;
  - a muted sub-line, for example MODE: OVERRIDE ONLY;
  - the known-code button **ENTER 4 0 7 1** under "FROM YOUR CASE: SERVICE OVERRIDE" (only when known);
  - **MANUAL RELEASE**;
  - **BACK**.
- **Right column:** a 3×4 **phone-layout** pad (1-2-3 on top, 0 centred below; R3: slightly faster in Bell Labs tests and the layout wall keypads use) with DEL, 0 and ENTER on the bottom row.
  - Keys are 88×72 with 8 px gaps on desktop and **92×78 with 12 px gaps on touch**. At the 0.72 scale of a 390 pt landscape phone, 78 canvas px is about 56 pt, above Apple's 44 pt and Android's 48 dp, and a 12 px gap is about 8.6 pt, over Android's 8 dp spacing (R3, A4.2). The old 8 px touch gap was about 6 pt, under it.
  - A one-line key legend sits under the pad on desktop. It comes from `settings_menu.prompt()`, so it shows controller glyph names when a pad is active.

### 6.2 Input. No new InputMap actions.

| Device | How it works |
|---|---|
| Keyboard | Digits typed directly. The card's `_input` reads `InputEventKey.unicode` "0"-"9" and `KEY_KP_0..9` and consumes them before `Main._input`, so AZERTY users can type Shift-digits (R3). Backspace deletes. Enter or KP Enter submits. Arrow keys move focus. Space (`ui_accept`) presses the focused key; E (`interact` from a key event) does too. The first Esc (`pause_game`) closes the card; the next one pauses. |
| Controller | D-pad or left stick move focus (`ui_*`) through an explicit focus graph over pad, known-code, MANUAL RELEASE and BACK. A presses through `ui_accept` only. B (`ui_cancel`) or the first Start (`pause_game`) closes the card; the next Start pauses. |
| Touch | Tap keys. No focus ring is shown (`_grab_menu_focus` already releases focus on touch). Tapping the dim backdrop closes the card, as the debug menu does. Android Back closes it. PAUSE stays at the top right. |

- **Starting focus:** the known code if there is one, otherwise MANUAL RELEASE. During a lockout, MANUAL RELEASE.
- **Submitting:** after the fourth digit nothing auto-submits. The player presses ENTER, so a wrong last digit can be fixed with DEL. One exception: the known-code button types its four digits and submits on its own.
- **Edge cases** (from A4.2, each needs a test):
  1. Digit keys 1 and 2 are the default `choice_1`/`choice_2`. The card consumes digit events before `Main._input`. It sets its own `keypad_open` mode, not `waiting_for_choice`, and that gates `human.controlled` the same way.
  2. Joypad A is both `interact` and `ui_accept`. Inside the card only `ui_accept` presses keys, and `interact` arriving from an `InputEventJoypadButton` is ignored, so one A press never fires twice. On open, release `GAMEPLAY_ACTIONS`, as Pause and knockdown do, so the press that opened the card does not also press a key.
  3. `DebugMenu.open()` must also refuse while `keypad_open`.
  4. Close and pause: Esc and Start are the **same** `pause_game` action (`main.gd:3275` and `3284` at `7c19ee2`; `3462` and `3471` at `cfe304f`), so they cannot be split without raw key checks that break rebinding. The rule is the one B and C use: the first `pause_game` or `ui_cancel` press closes the card, and the next `pause_game` press pauses. Losing window focus still auto-pauses over the open card, and Resume returns to it with focus restored through `_menu_focus_target`.
  5. Rebinding: if a player binds a game action to a digit key, the card still takes that digit while it is open. Note this in the Controls guide.
  6. Losing window focus auto-pauses as it does today. The open card is kept.

### 6.3 Feedback: never one sense alone

| State | Text | Shape | Colour | Sound | Haptic (optional; the existing switches) |
|---|---|---|---|---|---|
| Waiting | ENTER OVERRIDE / MODE: OVERRIDE ONLY | ring with a dot | amber | none | none |
| Key press | the digit appears | the cell fills and the underline moves | white | key beep | 15 ms tick (touch) |
| Denied | DENIED n/3 / CODE NOT ACCEPTED | cross | red | 3 short low beeps | 60 ms buzz or rumble |
| Locked out | READER LOCKED 0:05 | padlock in a draining ring | red | reader-lock tone once (not the klaxon) | 120 ms rumble |
| Granted | ACCESS GRANTED / BOLT RELEASING | tick | green | rising chirp | none (the bolt arc's own impact follows) |
| Door forced | DOOR FORCED (in reach only; the world shows the lamp) | warning triangle, flashing | red | repeating door-alarm tone (not the klaxon) | the arc's rumble when the bolt pops |

Typed digits are **not masked**. This is a game and the screen is the engineer's own. Masking would hurt readers who transpose digits (R2.4). Reduced motion turns off the readout shake on denied. Its text, shape, colour and sound remain.

---

## 7. Every new or changed line: **proposed, awaiting Nathanial**

The format follows the approved files: narrator in the third person and present tense, the engineer as they/them, WOLF short and dry with no key names, no square brackets, and caps for screens and labels. Fits are estimated against the approved measurements: the dialogue box holds 3 rows at 855 px (Roboto 17), the hint bar 526 px (Roboto 14), and WOLF notices are 40 characters or fewer including the prefix.

### Records Access

| ID | Where / trigger | Proposed | Alternatives | Notes |
|---|---|---|---|---|
| R1 | Station label in reach, unread / copied | `ACCESS SCREEN` / `ACCESS COPIED` | `SERVICE SCREEN` | Matches PURGE QUEUE/COPIED. |
| R2 | Dialogue box on copy (narration, untagged) | `SERVICE LINE / ACCESS`<br>`LOCKDOWN: PERSONAL CODES REVOKED.`<br>`HATCH OVERRIDE: 4071. CHANGE: OVERDUE.` | B: `MAINTENANCE / ACCESS`<br>`LOCKDOWN: PERSONAL CODES REVOKED.`<br>`SERVICE HATCH OVERRIDE: 4071. ROTATION MISSED.` | 3 of 3 rows. Rendered in `0-records-find.png`. It follows the found-log format: an ALL-CAPS header with " / " and terse system lines that never editorialise. **The digits need approval.** No clock time. |
| R3 | Hint in reach, unread | `Hold E: copy the access screen.` | `Hold E: copy the screen.` | `E:` is rewritten by the prompt substitution. |
| R4 | Hint in reach, copied | `Access screen copied. Head for the mirror port.` / once the mirror is copied: `Access screen copied. Head for the exit.` | — | Never names a finished station again, like `_records_route_hint`. |
| R5 | Toast | `Logged: SERVICE OVERRIDE` | — | Uses the approved toast format. |
| R6 | Case entry: name, kind, examine | `SERVICE OVERRIDE`, LOG, examine = R2 text, `Found in: RECORDS ACCESS` | name `HATCH OVERRIDE` | 16 characters. Fits a 64 px row. |
| R7 | WOLF NOTICE (disclosed), when the engineer steps away from the screen | `WOLF: They revoked everything but that.` | `WOLF: Nobody changed that one.` | 39 characters. Names the thing, not its meaning. |
| R8 | WOLF IGNORE (pressed), same moment | `WOLF doesn't look at the screen.` | `WOLF keeps walking.` | Narrator action, cool but not sulky, and true from any position. |
| R9 | Case annotation (disclosed only) | `WOLF: They revoked everything but that.` | — | Timeless, per the derived-record rule. |

### Service Junction

| ID | Where / trigger | Proposed | Alternatives | Notes |
|---|---|---|---|---|
| J1 | Top objective card after `sentry_down` | `SERVICE JUNCTION` / `OPEN THE HATCH` | keep `POP THE EXIT BOLT` | Changed. "Pop the bolt" no longer describes the first step. |
| J2 | Hint near the bolt, sentry down, bolt locked | `E: use the hatch reader.` | `E: open the hatch.` | **Changed** from `E: pop the exit bolt.` (`main.gd:3203`, `3390` at `cfe304f`) |
| J3 | Hint elsewhere in the lane, sentry down | `The sentry is down. The hatch reader is by the exit.` | — | **Changed** from `The sentry is down. Pop the exit bolt by the hatch.` (`main.gd:3209`, `3396` at `cfe304f`). 50 characters. |
| J4 | Station label above the panel (unchanged names) | `EXIT BOLT` / `EXIT OPENING` / `EXIT OPEN` | — | Unchanged. The reader's state is the lamp; its word (J5) joins the label only in reach. |
| J5 | Reader state words: on the card's state row, and in reach after the label (never as a world chip) | `LOCKED` · `OVERRIDE ONLY` · `DENIED` · `READER LOCKED` · `GRANTED` · `DOOR FORCED` · `OPEN` | `LOCKDOWN` for `LOCKED` | In the world the lamp shape shows the state (section 2.2). |
| J6 | Card header and tag | `SERVICE HATCH / LOCKDOWN` · `RESTRICTED AREA` | `SERVICE HATCH / OVERRIDE` | |
| J7 | Card state and sub-lines | `ENTER OVERRIDE` + `MODE: OVERRIDE ONLY`; `DENIED 1/3` (2/3) + `CODE NOT ACCEPTED`; `READER LOCKED 0:05` + `3 WRONG CODES. WAIT, OR RELEASE BY HAND.`; `ACCESS GRANTED` + `BOLT RELEASING` | `ACCESS DENIED` | All rendered. |
| J8 | Known-code row | caption `FROM YOUR CASE: SERVICE OVERRIDE`; button `ENTER 4 0 7 1` | `USE SERVICE OVERRIDE` (hides the digits) | Shown only when known. |
| J9 | Fallback and close buttons | `MANUAL RELEASE`; note when no code is known: `Crank the bolt back by hand. It sets off the door alarm.`; `BACK` | `RELEASE BY HAND` | The note is honest about the cost and does not grade the player. |
| J10 | Pad keys and legend | `1`-`9`, `0`, `DEL`, `ENTER`; legend `0-9 TYPE · BKSP DELETE · ENTER SUBMIT · ESC BACK` (from prompts) | `CLR` for `DEL` | |
| J11 | Dialogue box on MANUAL RELEASE start (narration) | `The manual release fights back. An alarm sounds: DOOR FORCED.` | `The release is stiff. The door alarm starts.` | 1 row. |
| J12 | (removed) | — | — | The old "The bolt grinds back by hand. The hatch slides open." is gone: at 6/6 the approved POP_BOLT, BOLT_CHARGING, BOLT_ARC and HATCH_OPENED lines play, as on the code route. |
| J13 | Hint in reach once MANUAL RELEASE is chosen; while cranking | `Hold E: crank the manual release. Tap E: keypad.`; `Hold E: crank the manual release. {ticks} / {needed}` | `Hold E: crank. Tap E: keypad.` | Uses the bypass's tick placeholders. Measured: 299/526 and 239/526 (Roboto 14). |
| J14 | WOLF during the alarm (narration, any memory) | `WOLF keeps his eyes on the lane while the alarm sounds.` | `WOLF watches the downed sentry.` | Authored action. Appended as a second row (with J11: 2 rows, widest 496/855, measured). At `cfe304f` he already stands in the hatch doorway facing the lane, so the line describes what he does there. |
| J15 | WOLF on grant, code read (disclosed only) | `WOLF: The one they forgot.` | `WOLF: Nobody rotated it.` | 26 characters. Appended under POP_BOLT as a second row. POP_BOLT itself is unchanged. |
| J16 | End card recap rows (new row `HATCH`) | `HATCH  {name} entered the override from the access screen.` · `HATCH  {name} entered the override from memory.` · `HATCH  {name} cranked the manual release.` | — | The end card is kept under 855 px. Stored as `hatch_recap` (section 8). |
| J17 | Autosave-C restore line (narration) | `Service junction restored. The sentry is down; the hatch reader is by the exit.` | `Service junction restored. The sentry is down; open the hatch.` | **Changed** from `Service junction restored. The sentry is down; pop the exit bolt by the hatch.` (`main.gd:1549` at `7c19ee2`, `1600` at `cfe304f`). Without it the restore would contradict J2 and J3. Measured: 1 row, 571/855. |

**Unchanged on purpose:**
- POP_BOLT, BOLT_CHARGING, BOLT_ARC, HATCH_OPENED (now played on **both** routes), LOG_LANE ("STAND-DOWN CODE: NO RECORD.").
- The approved mirror and purge records, because the code is a separate record, so no approved record text changes.
- `The exit bolt is locked out while the sentry runs the line.`

---

## 8. Save impact

- **Ship inside the planned v5** with the evidence case. Do not bump the version separately (A5).
- **New stored data:**
  - The case's `collected` array gains the id `LOG_ACCESS`. That is the whole "code known" fact. The digits live in a code table next to the item catalog (`CODE_TABLE["hatch_override"] = {"digits": "4071", "source": "LOG_ACCESS"}`), so changing the digits never breaks a save.
  - `hatch_recap: String` in `"" | "case" | "typed" | "manual"`. It is written only by autosave D (`clear_junction`). It is validated in order: it must be in the set, and non-empty requires `junction_cleared` (the same pattern as `lane_recap`, `m0_state.gd:302-305`).
- **Never stored:** wrong-try counts, the lockout timer, half-typed digits, manual-release ticks (HoldUse ticks are not saved today either) and the bolt state (today a restore at autosave C relocks the bolt).
- **Validation** (the inventory rule 12 chain):
  - `LOG_ACCESS` is a known, unique id;
  - its room is reached by chapter order: it requires `checkpoint_reached` and that Records was entered;
  - `hatch_recap` must be consistent: "case" requires `LOG_ACCESS` in `collected`.
- **Persistence:**
  - Copying the screen patches only `beat_snapshot`'s `collected` field and writes the beat if a checkpoint exists (the approved pickup rule). It never calls `_save_progress()`.
  - Records is past its entry autosave, so the find is on disk at once.
  - Under Secure the Evidence, a log is optional and unsecured until a safe point, but Records has no hazards, so nothing can drop it there. In the Junction it is already part of the Records autosave and the junction autosaves (A to D). **Recommendation:** treat SERVICE OVERRIDE as a key record that never drops, because losing it would turn the reader into retry busywork. The approved rule "key records never drop" covers it.
- **Migration:** v1-v4 load with an empty case and `hatch_recap` "". Such a run reaches the reader with no code known, and MANUAL RELEASE works. The future-version fixture moves to 6 as planned.

---

## 9. Test impact

Headless (new and extended suites):
1. `keypad_test.gd` covers a pure `Keypad` class (like HoldUse and PressureLine), frame-independent:
   - digit entry up to 4, DEL, submit;
   - correct, wrong and n/3 counting;
   - a lockout at 3 for exactly 5 s, then reset;
   - keys refused during the lockout while manual release is still allowed;
   - the known-code fill and submit;
   - a typed correct code accepted with no record.
2. `m0_state_test.gd`:
   - v5 round trip with `LOG_ACCESS` and `hatch_recap`;
   - every rejection (unknown id, duplicate, room not reached, "case" recap without the id, recap before `junction_cleared`);
   - v4 migrating empty;
   - the future-version fixture at 6.
3. `chapter_scene_test.gd` (Records):
   - the copy at the screen with hold and release;
   - the overlap test against PURGE QUEUE, the cartridge reader and MIRROR;
   - WOLF NOTICE versus IGNORE by memory;
   - the toast, the label and the hint text.
4. `junction_test.gd`, full routes on both relay memories:
   - (a) code read, then known-code entry, the grant, the approved bolt lines, the hatch and autosave D with recap "case";
   - (b) not read, then MANUAL RELEASE for 6 ticks, DOOR FORCED, then the same `_pop_bolt` and `_bolt_arc` (flash, shake, rumble, the four approved lines), the hatch and recap "manual";
   - (b2) after MANUAL RELEASE is chosen: a tap reopens the card with ticks kept, a hold cranks, the choosing press makes no tick, and a correct code after some ticks still plays the code route;
   - (c) not read, the correct code typed, recap "typed";
   - (d) 3 wrong codes, the lockout, MANUAL RELEASE during the lockout;
   - (e) the card refused before `sentry_down` and inside an active coolant cloud;
   - (f) a knockdown restore at autosave C keeps `LOG_ACCESS` and shows J17, not the old "pop the exit bolt" line;
   - (g) the card holds the game still.
5. `ui_controls_test.gd`:
   - the card's focus graph (every key reachable; starting focus by state);
   - digits 1 and 2 never reaching `choice_1`/`choice_2`;
   - joypad A not double-pressing on open, and one A press inside the card pressing a key exactly once (`interact` from joypad ignored);
   - the first `pause_game` (Esc or Start) or `ui_cancel` (B, Android Back) closing the card, and the next `pause_game` pausing;
   - auto-pause on focus loss over the card, and Resume returning focus;
   - touch keys at least 78 canvas px with gaps of at least 11 px;
   - the debug menu refused while open.
6. `sfx_bank_test.gd`: the new beep, denied, chirp, reader-lock and door-alarm clips exist, have the right lengths and play no repeats; no keypad or hatch path calls `klaxon`.
7. `debug_tools_test.gd`:
   - a CHOICES toggle for "access screen copied";
   - a JUMP target "hatch reader" (sentry down at the panel);
   - the F3 state page showing code known, tries and lockout;
   - the F12 dump including them.

Graphical and hands-on, required before any feel claim:
- One normal window with a separate test save, playing both relay memories × {read, skipped} on keyboard and on a controller.
- One phone pass (touch sizes, safe area, the backdrop tap, Back).
- Rendered stills do not count as play. Neither do these mocks.

Docs (public, spoiler-safe):
- The Junction walkthrough's spoiler-labelled solution: the code and where it is found.
- The Records walkthrough: an optional-find mention.
- The Controls page: typing digits in the reader, and the controller and touch usage.
- The changelog and the in-game changelog.

---

## 10. What it costs to build

Rough engineering days for one person, including headless tests and debug hooks. They exclude Nathanial's text review, any Look 2 art, and the hands-on and phone passes, which are listed separately. They assume the evidence case's shared foundation (ItemCatalog, v5, the CASE tab) exists. If it does not, this option either waits for it or ships a minimal "known codes" fact in v5 for about 1 day more.

| Part | Days |
|---|---|
| `Keypad` pure logic class plus tests | 0.5 |
| `KeypadCard` UI: layout, focus graph, digit input, touch and desktop sizes, Back/Pause/debug interplay, UI tests | 2.5-3 |
| Reader station: lamp shapes and states, in-reach label words, hint and label wiring in `_use_exit`/`_lane_hint`, the J17 restore line | 0.5 |
| MANUAL RELEASE hold station plus DOOR FORCED alarm (HoldUse, tap-to-reopen, door-alarm loop, lamp flash, hand-over to `_pop_bolt`) | 0.75 |
| Lockout: lamp ring, reader-lock tone, timer | 0.25 |
| Procedural sounds (beep, denied, chirp, reader-lock tone, door-alarm tone) in SfxBank | 0.25 |
| Records ACCESS SCREEN: code-drawn prop, hold-to-copy, case entry, WOLF notice and ignore, overlap test | 0.75 |
| Save: `collected` id, `hatch_recap`, validation, migration (inside v5) | 0.5 |
| Debug hooks (toggle, jump, F3/F12) | 0.5 |
| Recap row and end card | 0.25 |
| Docs and changelogs | 0.5 |
| **Subtotal, build** | **7.25-7.75** |
| Hands-on desktop and controller pass, plus a phone pass, with fixes | 1-1.5 |
| Optional corridor seal lamp (section 2.3), after the corridor grey box and the art job's portal | +0.25 |
| Optional WOLF-reads-the-reader variant (section 3.3) | +1 |

A cheaper first cut is possible. It keeps the found code and the reader but uses the audit's **model A** and has no card:
- With the code known, USE at the reader makes the engineer punch it in. The digits fill on the panel's code-drawn readout with beeps, and the reader grants.
- Without the code, USE turns the panel straight into the MANUAL RELEASE hold station.
- Nobody types, so there are no wrong codes and no lockout.

That cut costs about 3.5-4 days. It loses the hands-on "punch in a PIN" feel Nathanial asked for. **The recommendation is the full card**, because typing a code is the request.

---

## 11. Risks

1. **The payoff tension with inventory rule 3.** Optional finds should reward understanding and relationship, not stats. Here the find also saves about 2 s at the reader. Mitigation: the outcome is identical, MANUAL RELEASE is short, and the extra value is the WOLF line, the record and the recap. If Nathanial reads it as gating anyway, move the screen onto the critical path (for example, make it the Records exit's own side panel, read on the first exit USE). The code then becomes guaranteed, and the "exploring pays off" part shrinks to the WOLF line.
2. **Players skip the screen and never see the best moment.** It is on the path and lit, and the label appears in reach, but some players will walk past it. They still get a complete, honest fallback. Play-testing should note how many read it.
3. **The digits are canon.** `4071` is a placeholder. The final digits must avoid every story number (03:17, the purge time, the target ID, any mirror timestamp) and the codes people pick most (R1.6). A 0451 homage is Nathanial's call.
4. **Dependency on the evidence case and v5.** They are planned but not built. Building this first means building a slice of the case first.
5. **Input collisions.** Digit keys are answer keys, joypad A is both accept and interact, Esc and Start are one `pause_game` action, and the debug menu and Android Back all touch it (section 6.2). Each has a rule and a test, and the phone pass must confirm simultaneous touches.
6. **Screen space on phones.** The card takes most of the canvas, so the PAUSE button and safe areas must be checked on a real device before claiming touch support.
7. **The approved bolt lines gain a step.** POP_BOLT still plays after the grant, but the beat is longer, so pacing must be judged by play, not by these stills.
8. **The manual route's pacing.** Fixed: the arc, flash, shake and sparks now play on both routes. What remains is pacing: the manual route adds 2.4 s of crank before the same 0.6 s whine. Judge it by play.
9. **Room expansion and art.** The widened Records and Junction will move both the screen and the reader. Positions here are for today's rooms. Re-check after each grey box, and coordinate the prop look with the art job's military-base pass.
10. **Fake-consequence creep.** Wording such as "SECURITY NOTIFIED" or "ATTEMPT LOGGED" must not ship unless something real follows (AGENT.md).
11. **Mood reference safety.** No Skynet, Terminator or Cyberdyne names, designs or text anywhere, including in stencils, sound names or commit text.
12. **Players who skip the screen still see a number pad.** On that route the card leads with MANUAL RELEASE and its honest note, but the pad is there and invites guesses such as 1234. The lockout makes that harmless, and it is how the genre works (Prey), but it is a conscious choice. If Nathanial prefers, collapse the pad behind a TYPE A CODE button when no code is known.
13. **Round 3 moved WOLF.** At `cfe304f` WOLF waits in the hatch doorway at x 902, beside the bolt panel and the hatch. The stills now show this. Check in play that the lamp, the card and WOLF never overlap at phone scale.

---

## 12. Questions for Nathanial

1. Approve this design: one found code (Records ACCESS SCREEN) opening one essential reader (the Junction hatch), with MANUAL RELEASE as the engineer-only fallback?
2. The digits: approve `4071`, choose others, or show them masked (••••) on the screen? Masking would break the found-code idea, so this option needs real digits. If parts of options are combined, keep one digit set with no near-twins (option C's code was moved from 4072 to 6138 for this reason).
3. Approve the R and J lines in section 7, or pick alternatives. In particular the screen's wrong note, "CHANGE: OVERDUE", and the objective change to OPEN THE HATCH.
4. WOLF: keep him as a noticer only (default), or add the variant where he reads the reader (section 3.3)?
5. The MANUAL RELEASE route now ends in the same whine, arc and hatch as the code route (recommended and drafted). Keep that, and keep the DOOR FORCED alarm before it?
6. The corridor seal lamp (LOCKDOWN, then OVERRIDE: POWER or DOOR FORCED): yes now, after the corridor grey box, or not at all?
7. Treat SERVICE OVERRIDE as a key record that never drops (recommended)?

---

## 13. What was actually done for this design

- Read the private design files, the approved text, the PIN research and the audit, plus `records_room.gd`, the Records, mirror, exit-bolt and hatch code in `main.gd`, the junction constants, `debug_actions.gd`, `debug_menu.gd`, the theme and `project.godot` at `7c19ee2`.
- Exported `main` at `7c19ee2` into this folder (`export/`, scratch only) and imported it twice headless with an isolated HOME. For the revision, exported `main` at `cfe304f` into `../export-cfe304f/` (scratch only), imported it twice headless, and re-rendered every still there.
- Rendered **stills** in a normal Godot 4.7.2 window at 1280×720:
  - The real game was jumped to the `records_mirror` and `tank_down` checkpoints through the debug actions, then frozen. In the junction, WOLF was left where `cfe304f` places him (`WOLF_DOWN_X`, the hatch doorway).
  - The mock ACCESS SCREEN, the reader lamp and the keypad card were drawn over it with the game's own `MenuPanel`, `CardSheen`, Button styles and Montserrat and Roboto fonts.
  - `8-manual-arc.png` is the game's own bolt arc at `cfe304f`, set off by today's bolt USE, to show the moment MANUAL RELEASE hands over to. The crank itself is a mock (`7-manual-crank.png`).
  - The status and hint text on the frozen frames were set by the driver.
  - The window was closed by the driver (`quit`).
- **Not done:** no gameplay was built, no route was played, and no headless test, export or device test was run. Touch sizes were calculated, not measured on a phone. No Git repository or worktree was edited.
