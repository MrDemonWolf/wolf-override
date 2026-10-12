# PIN option B: Lockdown Access

**Private design material.** Answers Nathanial's request of 2026-10-11: "Can we add some pin codes and make it feel more like a furttgrue milialry base like iin skynet". This is one of several options for him to pick from. Nothing is built into the game, and no Git repository was touched. Every player-facing word below is **proposed, awaiting Nathanial**. The Terminator films' AI-run defence network is a mood reference only: no outside franchise names, logos, designs or text. Keep this file out of Git, public docs, PR text and build output.

Built on: `RESEARCH.md` and `AUDIT.md` in `../research` and `../audit`, the code at `main` `7c19ee2` (`main.gd`, `junction_room.gd`, `records_room.gd`, `m0_state.gd`, `game_settings.gd`, `hold_use.gd`, `debug/*`), `PRIVATE_AGENTS.md`, `PROJECT_CONTEXT.md`, `docs/next-session.md`, `docs/research-2026-10/README.md`, and the approved item, death and logic text.

Files in this folder:
- `strip.png`: one-image summary (six mock frames and a map of where codes are found and used).
- `shots/01-idle.png` … `07-world-local-sealed.png`: 1280x720 mocks rendered by Godot 4.7.2 from an export of `main` at `cfe304f` (logic round 3, where WOLF waits in the hatch doorway once the sentry is down), using the game's own theme (`MenuPanel`, `CardSheen`, `TouchButton`), Montserrat and Roboto, over the real Service Junction at the tank-down beat. `00-baseline.png` is the same frame without the mock. `06-world-lockdown.png` is the reader before the first USE (not in the strip).
- `driver/`: the mock card script, the capture script, `run.sh` and the strip builder. They are mock code, not game code.

**Revised before showing (2026-10-11), after the judge's review.** What changed:
1. WOLF now reads the code on **both** relay routes; only his tone changes. A rushed WOLF no longer holds back a third time, and no case entry is ever required to finish (sections 4 and 8, T7, T8).
2. The narration "by his own choice" is gone; WOLF's action shows it instead (T7, T12a).
3. The lockout no longer uses the `klaxon` or flares the lane beacons; it uses its own procedural reader-lock tone and the reader's lamp. The blast door's DOOR FORCED lamp plays under the blast's own sound, with no klaxon (sections 3 and 5).
4. Captions in the card are 12 px or more; touch keys have 12 px gaps (section 6, `03-denied.png`).
5. Inside the card only `ui_accept` presses keys, joypad `interact` is ignored, and pad X and Y act as delete and known code only for joypad events (section 6).
6. `06-world-lockdown.png` now shows one consistent state: sentry down, reader still LOCKDOWN until the first USE reroutes the winch power, with today's hint and restore line.
7. Every still was re-rendered on `cfe304f`. The world reader shows state by lamp shape and colour only; its tiny world word was removed (2026-10-11 LABELS).
8. "DENIED · 1 OF 3" is stated as a tries count, not a completion count (section 5).

---

## 1. The idea in one paragraph

The Director's approved opening order, "Lock down maintenance", puts every reader on the maintenance network into **LOCKDOWN**. LOCKDOWN readers refuse every code, including the engineer's own. The slice already has the engineer re-routing power: the corridor relay or MANUAL BYPASS, and the junction's tank drop, after which "the winch's power reroutes to the exit bolt" (approved POP_BOLT). In this option, that re-routed power cuts a reader off the locked-down network and drops it to **LOCAL**: the reader wakes in amber and accepts a local override code. The engineer's existing power work is what brings a keypad back. The code then comes from **WOLF**, who reads it off the panel's memory with his readout on either relay route (the relay memory changes only his tone), or from a **tamper-sealed override card** on the same panel that the engineer can break alone.

There is one essential keypad (the junction exit bolt). The other readers only teach the lamp language and sell the base: LOCKDOWN red, LOCAL amber, OPEN green, and DOOR FORCED after the blast.

## 2. Why this is believable (grounding)

| Game element | Real-world basis | Evidence |
|---|---|---|
| LOCKDOWN mode that refuses every credential | Lenel OnGuard reader mode "Locked" shuts out every credential; Genetec threat levels lock doors that were open by schedule and raise the required clearance site-wide. | [F] RESEARCH 1.5 (docs.axxonsoft.com; help.securitycentersaas.genetec.cloud) |
| LOCAL mode when a reader is cut off the network | Lenel reader interfaces support "lock, unlock and facility code" **offline** access modes, used when the reader loses its panel connection. | [S] search-result text only for kb.lenels2.com and the LNL-1320-S3 product page (both returned 403 to fetching). Treat as weaker. |
| Code is four random digits | ICS 705: "four or more random digits, with no known or logical association to the individual". | [F] RESEARCH 1.1 |
| Three tries, then a short lockout | PIV PINs block after 3 tries (YubiKey default); Schlage disables 30 s after 3 wrong codes. | [F] Yubico; [S] Schlage, RESEARCH 1.1-1.2 |
| Tamper-sealed override card beside the door | US security containers record the combination on SF 700, whose combination part is sealed in an envelope and held by the security manager: a sealed, tamper-evident record of the code. Break-glass access for emergencies follows the same idea. | [S] search-result text for exwc.navfac.navy.mil SF 700 page (403 to fetching) |
| DENIED, ACCESS GRANTED, DOOR FORCED as named reader states | Genetec LED/beeper states include Access denied, Access granted, Prompt for PIN, Door forced open. | [F] RESEARCH 1.5 |
| Red/amber/green plus a beep pattern | Typical OSDP reader defaults: standby blue, granted green with a continuous beep, denied red with three short beeps. | [S] RESEARCH 1.5 |

The game takes the shape of these systems, not their names. No brand or product names appear in game text.

## 3. Where the readers are and what each protects

Positions are today's 960 px rooms at `7c19ee2`. The level expansion will move them; keep them tied to the beat, not the x value.

| # | Reader | Room, position | Protects | Gate? | Lamp states | What the player does |
|---|---|---|---|---|---|---|
| R1 | **Seal reader** on the red seal's portal | Corridor, portal at about x 752 | The red seal (opened by power today) | **No** | LOCKDOWN until the relay or bypass lands, a short amber LOCAL flash, then OPEN as the seal rolls up | **Today:** lamp only. The free floor between the bypass reach (ends at 730) and the door face (752) is about 20 px, too small for a station (AUDIT 2.1). **Expanded corridor:** a USE station. The engineer keys their own maintenance code and the reader refuses it: LOCKDOWN, MAINTENANCE ACCESS SUSPENDED. This teaches the lamp and the fact that lockdown refuses codes, at no cost. |
| R2 | **Exit reader** on the Records exit | Records, exit at 830 | The Records exit (unchanged gate: both copies) | No new gate | LOCKDOWN until FIRST COPY SECURED, then OPEN with the existing exit arc | Lamp only. No keypad, no change to the copy beats, no change to approved MIRROR or FIRST COPY text. |
| R3 | **Blast door reader** on the junction's sealed door | Junction, door at 452-480 | Nothing: it explains why the door is blown, not opened | No | LOCKDOWN / SECURE SIDE before the blast; DOOR FORCED (red, flashing for about 3 s, under the blast's own sound; no klaxon) after it, then dark | USE at the door (today: "The door is sealed from the other side. Something hums behind it.") gains the reader detail (line T4). |
| R4 | **Exit bolt reader**, the one keypad | Junction, bolt panel 806, reach from about 741 | The exit bolt and hatch: the way out of the slice | **Yes, essential** | Dead/LOCKDOWN while the sentry runs; LOCAL once the winch power reroutes; DENIED flashes; LOCKOUT drops back to LOCKDOWN for 8 s; OPEN on the right code | Full beat in section 4. |

Where codes must **not** go (kept from AUDIT): the corridor breaker, any safe point, the tank release, WOLF's containment gate, the MANUAL BYPASS, and the sentry (approved LOG_LANE: "STAND-DOWN CODE: NO RECORD."). This option respects all of them. The only essential change is at the exit bolt, in the calm beat after autosave C, where nothing hunts and no timer runs.

## 4. The exit bolt beat (R4), step by step

**Today:** sentry down, autosave C. USE at the bolt: POP_BOLT ("With the tank down, the winch's power reroutes to the exit bolt. The panel whines."), a 0.6 s whine, the bolt arcs, the hatch slides open, USE leaves (autosave D), END OF SLICE.

**Option B:**
1. **Before the sentry is down:** the reader is dark red, LOCKDOWN. USE gives today's line, unchanged: "The exit bolt is locked out while the sentry runs the line."
2. **First USE after the sentry is down:** POP_BOLT plays as today, with the same whine. The whine now ends with the **reader waking** instead of the arc: the lamp goes amber and the panel shows LOCAL OVERRIDE (T6). This is the existing power work bringing the keypad back.
3. **The code: WOLF on both routes (tone only), with an engineer-only route always open.**
   - **WOLF reads it on either relay route.** At `cfe304f` he already waits at his spot in the hatch doorway (`JunctionRoom.WOLF_DOWN_X`, 902) with his snout at the bolt panel's right edge, so he needs no walk and never crosses back over the tank. His cyan readout glows for about a second with a short scan tone, and he reads the local code out of the panel's memory (T7 or T8). He never touches, fetches or carries anything. The case logs a derived record, LOCAL OVERRIDE CODE (T12a), toast "Logged: LOCAL OVERRIDE CODE".
     - **Told the risk at the relay** (`memory.choice_id == DISCLOSE`): the warm line (T7).
     - **Rushed** (`PRESS`): the same read with a cooler, shorter line (T8). Reading a code costs him nothing, and he already refused twice on this route (the relay contact and the lane bait), so a third withholding would add no new story beat. This follows the 2026-10-10 decision that WOLF refuses rarely and meaningfully, and the audit's advice that memory changes his tone, never whether he offers a code.
   - **Engineer alone, on any route:** a red **tamper sleeve** on the panel's side holds the override card. HOLD USE for 3 ticks (1.2 s, `HoldUse` with a new station id `&"seal"`; ticks survive a release, as at the valve and bypass) tears the seal. The reader shows TAMPER LOGGED with a two-tone chirp, and the card goes into the case as OVERRIDE CARD (PRINT, T12b), toast "Logged: OVERRIDE CARD". It works at any time after the reader wakes; if the seal is broken before WOLF's read lands, WOLF does not read the panel. WOLF's read is never required, and neither case entry is required to finish: the slice needs a code on file, from either source.
   - The station is one reach with a USE context, like the bypass: while no code is on file, a tap gives the seal line (T10) and a hold breaks it; once a code is on file, a tap opens the keypad card. No separate floor spot is needed.
4. **USE with a code on file** opens the **keypad card** (section 6). Focus starts on ENTER KNOWN CODE. One press punches the code in (four beeps over about 0.8 s) and submits. Typing it by hand is optional, for players who want the physical feel; the code is shown on the card ("ON FILE: 7294 · WOLF'S READOUT"), so nothing is memorised or written down.
5. **Right code:** ACCESS GRANTED, three green beeps rising, lamp OPEN. The card closes after about 0.6 s and today's approved chain plays: "The bolt is taking the charge." then the arc ("The bolt arcs and drops."), the hatch slides open ("The bolt arcs and drops. The hatch slides open."), and USE leaves as today.
6. **Wrong code:** section 5.

**Time added to the slice end** (estimates, unplayed): about 3-4 s on either relay route (WOLF's read plus one card press); about 4-5 s if the player breaks the seal instead (the 1.2 s hold plus one card press). Doing it yourself costs time, never progress, which is the approved framing for the corridor bypass.

### Route matrix (the essential-objective gate from the Codex review)

| Relay memory | Lane outcome | Code source | Extra cost | Can finish? |
|---|---|---|---|---|
| Told, WOLF took the contact | any (wolf, alone, broke off) | WOLF's readout, warm line (or the seal, if the player is first) | ~3 s | Yes |
| Told, engineer cranked the bypass | any | WOLF's readout, warm line (or the seal) | ~3 s | Yes |
| Rushed (WOLF refused the relay) | refused, alone | WOLF's readout, cool line (or the seal) | ~3 s | Yes |
| Any, player breaks the seal first | any | Tamper seal (OVERRIDE CARD) | ~4-5 s | Yes |
| Any, after quit and Continue at autosave C | — | The code learned earlier is still on file (saved as its own beat, section 8); the reader re-wakes on the next USE | none beyond the re-pop | Yes |
| Any, after quit and Continue before the code was learned | — | As on first arrival | as above | Yes |
| Any, after three wrong codes | — | Same source, after the 8 s lockout | 8 s | Yes |

No row leaves the engineer without a way out, no row depends on WOLF, and no row needs a case entry to finish. At `cfe304f` WOLF is at his doorway spot in every row once the sentry is down (a restore at autosave C puts him there too), so his read is always available but never required.

## 5. Wrong codes: a military consequence that costs seconds

- **1st and 2nd wrong code:** the readout shows DENIED · 1 OF 3 (then 2 OF 3), which counts tries before the lockout, not the "1 of 5" kind of completion count the item rules forbid; the digits turn red; one TRIES pip fills; three short low beeps (the OSDP denied pattern); the card nudges 4 px sideways (off when screen shake is off); the in-world lamp blinks red; the digits clear after 0.8 s. Narration T15. Cost: about a second.
- **3rd wrong code: LOCKOUT.** The reader drops back to **LOCKDOWN**: lamp red, card header MODE: LOCKDOWN, keys greyed, readout LOCKOUT · READER RESET with a countdown, LOCAL POWER BACK IN 0:08. One new procedural **reader-lock tone** plays (two falling low notes, about 0.5 s). It does **not** use the `klaxon`, which is the sentry's lock-on cue (`_sentry_alarm`, `main.gd:2403-2404` at `7c19ee2`, `2522-2524` at `cfe304f`), and the lane's lockdown beacons do **not** flare: next to a downed sentry either would suggest it is waking, a consequence that never comes. After 8 s the winch feed re-wakes the reader with the existing whine; it comes back in LOCAL with the tries reset (T17). The card may be closed during the lockout; walking away changes nothing.
- **What it never does:** no knockdown, no death, no new threat, no sentry restart, no alarm that changes later rooms, no lost code, no lost case item, no permanent lock, no save write. The cost stays inside the current beat (at most 8 s). No moral reading: WOLF gets one optional, capped line (T18) on the told route only.
- **Brute force:** 10,000 codes at 3 tries per 8 s is not a practical route, and it is never needed because the code is always on file before the card opens.

## 6. The keypad card (touch, controller, keyboard)

Mocked in `shots/` and `strip.png`. One card component, used by any future reader (the "lighter game" rule: one shared component, no per-room copies).

**Layout (960x540 canvas units):** a `MenuPanel` card with `CardSheen` at (24, 86), 594x356, left of the engineer so the panel, the engineer and the hatch stay visible on the right. It sits between the top card and the dialogue box (y 444), and the dialogue box stays readable for WOLF's and the narrator's lines. A light veil dims only the world above the dialogue box. The context hint row hides while the card is open; the card carries its own hints.
- Header: EXIT BOLT, a small READER · SERVICE JUNCTION subtitle, the mode chip (lamp plus MODE: LOCKDOWN / LOCAL / OPEN), CLOSE.
- Left column: the reader's screen (state line, four digit cells 50x54 with Montserrat Bold 36, the next empty cell outlined, a sub-line); TRIES pips; the mode legend, where each mode has a word, a colour and a lamp shape (square LOCKDOWN, rounded LOCAL, round OPEN), never colour alone; ON FILE with the digits and their source; a wide ENTER KNOWN CODE button; device hints.
- Right column: a 3x4 **phone-layout** keypad (1-2-3 on top, DEL-0-OK at the bottom; RESEARCH 3), keys 90x66 with 8 px gaps.

**Touch:** keys are 90x66 canvas px with **12 px gaps** (the card widens to 602x368; `03-denied.png`). On a phone 390 pt tall in landscape the canvas scales by about 0.72, giving about 65x48 pt keys, above Apple's 44 pt and Android's 48 dp minimums, and gaps of about 8.6 pt, over Android's 8 dp. (The first mock's 8 px gaps were about 6 pt, under it.) They are smaller than the 56 dp the Codex review asked for the main USE button; that applies to USE, not to a 12-key pad, but it must be checked on a real phone. Movement and USE hide while the card is open (as they do for a choice); PAUSE stays. CLOSE, Android Back or a tap outside the card closes it. Haptics: one short `Input.vibrate_handheld` tick per key, a longer one for DENIED, both behind the existing effect switches.

**Controller:** D-pad or stick moves focus over the grid with explicit focus neighbours that wrap (`_link_focus` from the debug menu), plus a link from the left edge of the grid to ENTER KNOWN CODE. **A** presses through `ui_accept` only: joypad A is also `interact`, so the card ignores `interact` from `InputEventJoypadButton` events and one press never fires twice. **X** deletes and **Y** enters the known code, but X and Y arrive as `choice_1` and `choice_2`, the same actions as keyboard 1 and 2. The card therefore treats `choice_1` and `choice_2` as delete and known code **only when the event is an `InputEventJoypadButton`**; from a key event, the card's own digit capture already consumed it as a digit. A player who binds `choice_1` to a letter key therefore never deletes digits with it. **B** (`ui_cancel`) or **Start** closes. Focus uses the theme's 2 px focus border (visible in `02-entering.png` on the 9 key). Focus starts on ENTER KNOWN CODE.

**Keyboard:** digits are read from `InputEventKey.unicode` ('0'-'9') and from `KEY_KP_0`-`KEY_KP_9`, so AZERTY keyboards (Shift for top-row digits) work. Backspace deletes, Enter or keypad Enter submits (with nothing typed, Enter enters the known code), E presses the focused key, Esc closes. Arrow keys move focus too.

**No new input actions.** The card reads raw digit keys in its own `_input` and marks them handled, so the `1` and `2` keys (default `choice_1`/`choice_2`) never reach `Main._input`. The card sets its own mode flag, not `waiting_for_choice`, and gates `human.controlled` the same way. Every hint label comes from `GameSettings.prompt(action, controller)` so rebinding shows correctly. Other interplay, decided here so it can be tested: Esc, Start and the PAUSE button close the card first; the next press pauses. The debug menu cannot open over the card. The press that opened the card releases `GAMEPLAY_ACTIONS`, so joypad A does not also press a key.

**Feedback never relies on one sense.** Every state is a word (ENTER CODE, DENIED · 1 OF 3, LOCKOUT, ACCESS GRANTED), a colour, a shape or pip, and a sound, with optional haptics. Sounds are procedural in `SfxBank` (key beep, denied triple, granted rise, seal tear, reader-lock tone) plus the existing whine. The `klaxon` is never used here: it is the sentry's lock-on cue. Nothing essential is sound-only, colour-only or timed.

**Readability:** every caption in the card is now at least 12 canvas px (the debug menu's caption size), about 8.6 pt on a phone; the first mock used 10-11 px. On touch the keyboard hint row is dropped, and the card shows only "Tap the keys. CLOSE or Back leaves the reader." Measure on a real phone before claiming it reads well.

**Mock states:** `01-idle` (LOCAL, WOLF's code on file after the warm line, focus on ENTER KNOWN CODE), `02-entering` (two digits typed, controller focus on 9, the cool line on the rushed route), `03-denied` (DENIED 1 OF 3, override-card route, touch layout), `04-lockout` (third wrong code), `05-granted` (ACCESS GRANTED), and the world views `06-world-lockdown` (sentry down, reader still LOCKDOWN before the first USE, today's hint and restore line) and `07-world-local-sealed` (reader woken to LOCAL, red tamper sleeve, the hold hint for the engineer-only route). The small in-world reader (housing, key grid, mode lamp, sleeve) is code-drawn in the mock and shows its state only by lamp shape and colour; the shipped one should be a Look 2 prop layer with a code-drawn lamp, and its micro-words typeset from an approved list, never painted by the image tool.

## 7. How it says "near-future military base"

- **Reader modes as a visible system:** LOCKDOWN / LOCAL / OPEN lamps on every door reader in all three rooms, settling with the rooms' existing lockdown beacons (`room_depth.set_lockdown_cleared`).
- **Access is suspended, not broken:** the engineer's own maintenance code is refused (R1). The automated network, not a person, decides who gets through.
- **Escalation through three doors:** the corridor seal is **bypassed** (power around the reader), the junction door is **forced** (DOOR FORCED alarm), and the exit bolt is **overridden locally** (a code and a logged tamper seal). Each door teaches a different way through a lockdown.
- **Tamper evidence and logging:** TAMPER LOGGED when the seal is torn; DENIED counts; LOCKOUT with a countdown.
- **Alarms with discipline:** a short reader-lock tone on lockout and a door-forced lamp, never a spawned threat, and never the sentry's klaxon cue.
- **Stencilled panels:** EXIT BOLT, LOCAL OVERRIDE, BREAK SEAL FOR LOCAL OVERRIDE, SECURE SIDE. All are typeset by code from an approved list.
- **Fits approved text already in the game:** "Lock down maintenance", MAINTENANCE / LOCKDOWN, LOG_LANE's "MODE: LOCKDOWN. AUTHORITY: DIRECTOR." and "STAND-DOWN CODE: NO RECORD."

Not in this option (kept for later, per RESEARCH 4.5): two-reader / second-person integrity (a strong WOLF moment, but it needs its own fallback design), scramble pads (they break controller focus memory), duress codes (an accepted code that secretly alarms feels unfair here), and typing a remembered code on a replay before it is on file.

## 8. Text: every new or changed line (proposed, awaiting Nathanial)

All of these are **proposed, awaiting Nathanial**. The voice follows the approved rules: third-person present narration, the engineer never gendered, WOLF short and dry with no key names, hints using the `E:` prefix the game rewrites per device, and no square brackets. `{name}` is the engineer's first name.

| ID | Where / trigger | Speaker | Proposed text | Alternative |
|---|---|---|---|---|
| T1 | R1 seal reader, USE before power (expanded corridor only) | NARRATION | {name} keys their maintenance code. The reader flashes red: LOCKDOWN. Maintenance access is suspended. | {name}'s maintenance code bounces off the reader. LOCKDOWN. |
| T2 | R1 hint in reach (expanded corridor only) | HINT | E: try the seal reader. | — |
| T3 | R1 after the seal opens, USE | NARRATION | The reader shows LOCAL. The bypass took the seal off the lockdown. | — |
| T4 | R3 blast door, USE before the blast (changes the current unapproved line "The door is sealed from the other side. Something hums behind it.") | NARRATION | Sealed from the other side; its reader shows LOCKDOWN. Something hums behind it. | The door's reader shows LOCKDOWN / SECURE SIDE. No code opens it from here. |
| T5 | R4 before the sentry is down | NARRATION | Unchanged: "The exit bolt is locked out while the sentry runs the line." | — |
| T6 | R4 after the POP_BOLT whine (POP_BOLT itself unchanged) | NARRATION | The bolt's reader drops off the lockdown and comes up amber: LOCAL OVERRIDE. | The bolt's reader wakes on the winch feed. LOCAL OVERRIDE. |
| T7 | R4, relay memory DISCLOSE, WOLF reads | NARRATION + WOLF | WOLF puts his readout to the panel. / WOLF: Lockdown missed the local code. It's on my readout. | WOLF: The local code survived the lockdown. I have it. (If Nathanial prefers WOLF reads the downed sentry instead: "WOLF: The sentry carried the bolt's local code. I have it." This adds a story fact.) |
| T8 | R4, relay memory PRESS: the same read, cooler tone | NARRATION + WOLF | WOLF puts his readout to the panel without a word. / WOLF: Local code. On my readout. (Measured: 2 rows, widest 385/715.) | WOLF: Local code. Yours. |
| T9 | Top card while no code is on file (only if the seal route is in progress) / once one is | CARD | GET THE LOCAL OVERRIDE / ENTER THE LOCAL OVERRIDE | — |
| T10 | R4 hint and tap line while no code is on file | HINT / NARRATION | HINT: HOLD E: break the override seal on the panel. NARRATION (tap): The local override sits in a tamper-sealed sleeve on the panel. The seal has to be broken. | — |
| T11 | R4 seal broken | NARRATION | The seal tears and the reader logs it: TAMPER. The card inside is stamped with the bolt's local code. | — |
| T12a | Case record (derived), WOLF route | RECORD | **LOCAL OVERRIDE CODE**. The exit bolt's local override, read off WOLF's readout. Found in: SERVICE JUNCTION. No WOLF reaction (derived record, like REC_MIRROR). | — |
| T12b | Case item, seal route | PRINT | **OVERRIDE CARD**. A stiff card from a tamper sleeve, stamped LOCAL OVERRIDE / EXIT BOLT. Four digits; the issued-by field is blank. NOTICE (told route): "WOLF: That seal's going on a log somewhere." IGNORE (rushed route): "WOLF doesn't look at the card." | Examine without the wrong note: "...stamped LOCAL OVERRIDE / EXIT BOLT. Four digits under the stamp." |
| T13 | Toasts | TOAST | Logged: LOCAL OVERRIDE CODE / Logged: OVERRIDE CARD | — |
| T14 | R4 hint with a code on file | HINT | E: enter the local override. | — |
| T15 | 1st / 2nd wrong code | NARRATION | DENIED. The reader buzzes and clears. Two tries left before it locks out. / DENIED. One try left before it locks out. | — |
| T16 | 3rd wrong code | NARRATION | Three wrong codes. The reader drops back to LOCKDOWN. | — |
| T17 | Lockout over | NARRATION | The winch feed brings the reader back to LOCAL. | — |
| T18 | Lockout, told route only, once per run (tone, not help) | WOLF | WOLF: It reset. It'll come back. | (none: silence) |
| T19 | Right code | — | Reuses approved BOLT_CHARGING "The bolt is taking the charge.", then BOLT_ARC and HATCH_OPENED. No new line. | — |
| T20 | END card recap (optional new row) | CARD | BOLT  WOLF read the local code off the panel. / BOLT  {name} broke the override seal. | Leave the recap as approved (three rows). |
| T21 | Card labels (typeset) | UI | EXIT BOLT · READER · SERVICE JUNCTION · MODE: LOCKDOWN / LOCAL / OPEN · TRIES · ON FILE: {digits} · WOLF'S READOUT / OVERRIDE CARD · ENTER KNOWN CODE · DEL · OK · CLOSE | — |
| T22 | Reader screen words (typeset) | UI | LOCAL OVERRIDE · ENTER CODE · n OF 4 · DENIED · 1 OF 3 · CODE CLEARS IN A MOMENT · LOCKOUT · READER RESET · LOCAL POWER BACK IN 0:08 · ACCESS GRANTED · BOLT RELEASING · TAMPER LOGGED | — |
| T23 | In-world reader and panel stencils (typeset, never image-tool text) | SIGN | LOCKDOWN · LOCAL · OPEN · SECURE SIDE · DOOR FORCED · MAINTENANCE ACCESS SUSPENDED · LOCAL / SEAL BYPASSED · BREAK SEAL FOR LOCAL OVERRIDE | — |
| T24 | Card device hints (built from `prompt()`; shown as on a default layout) | UI | Keyboard: 0-9 type · BACKSPACE delete · ENTER submit · ESC close. Controller: D-PAD move · A press · X delete · Y known code · B close. Touch: Tap the keys. CLOSE or Back leaves the reader. | — |
| T25 | Restore at autosave C (unchanged, `main.gd:1549` at `7c19ee2`, `1600` at `cfe304f`) | NARRATION | Unchanged: "Service junction restored. The sentry is down; pop the exit bolt by the hatch." B keeps the POP_BOLT step, so the line stays true. | — |

**The digits** are a new canon fact. The mocks use **7294 as a placeholder**: random-looking, not 1234, 0000 or 19xx, and unrelated to 03:17, the purge time or the target ID. Nathanial picks the real digits, or a 0451 homage if he wants one, or a •••• mask in text until he decides. Only the code id is ever saved, never the digits (section 9).

## 9. Save, debug and test impact

**Save (inside the planned v5 with the evidence case, not a separate bump):**
- New field `codes_known`: a sorted array of code ids, here only `"bolt_local"`. The digits live in a code table beside the item catalog, so changing them never breaks a save.
- The source needs no field: if `collected` holds the OVERRIDE CARD id, the seal was broken; otherwise WOLF read it (and LOCAL OVERRIDE CODE is a derived case record, never stored, per the v5 plan).
- Learning the code is its own beat: it calls `_save_progress()` (a C' autosave), so quitting and Continuing never asks for it again, and a death or knockdown never takes it (a key fact; the death model never drops key records).
- Not saved: the reader's mode, the tries count and the lockout timer. On restore, `bolt_state` comes back `locked` as today; the next USE re-runs POP_BOLT and wakes the reader. A lockout never survives a reload.
- Validation (extending the v5 chain): `bolt_local` and the OVERRIDE CARD id require `chapter_id == "junction"`, `door_blown` and `sentry_down`; unknown or duplicate ids are rejected; v1-v4 load with an empty list; the future-version fixture moves to 6 as already planned.

**Debug tools:** a CHOICES toggle for "bolt code on file (WOLF / card / none)"; a new jump "BOLT READER" (tank down, bolt popped, reader in LOCAL); a FORCE entry for "three wrong codes" (lockout); the reader mode, tries and lockout timer on the F3 page and in the F12 JSON; the seal and keypad card reaches in the zone overlay; the keypad card rect in the render-box dump.

**Tests to add:**
- *Headless, logic:* a pure `KeypadLogic` class (like `HoldUse`/`PressureLine`): digit entry capped at 4, delete, submit right/wrong, the 3rd wrong code starts an 8 s lockout, recovery resets the tries, the known-code press, no input during lockout or after GRANTED. Frame-independent.
- *Headless, state:* the v5 `codes_known` round trip; validation rejections; v4 loads empty.
- *Headless, scene:* the route matrix in section 4 (relay press / told-WOLF / told-bypass × lane wolf / alone / refused / broke off): the bolt always opens; WOLF reads the panel on every route with the line matching the memory; the seal works on every route; no route needs a case entry to finish; the lockout never plays `klaxon` or changes the beacons; a seal broken first stops WOLF's read; a lockout recovers and the right code then opens the bolt; quit and Continue after learning keeps the code; the recap row matches.
- *Headless, UI controls:* unicode digits including a shifted AZERTY digit event, keypad digits, `1`/`2` never firing a choice while the card is open, pad X/Y acting as delete/known code only from joypad events (a `choice_1` rebound to a letter key never deletes), one joypad A press pressing a key exactly once (`interact` from joypad ignored), B/Esc/Back/Start close, pause after close, debug menu blocked, touch hiding movement and USE, touch gaps of at least 11 px, captions of at least 12 px, the focus graph with wrap, prompt labels after rebinding.
- *Rendered stills:* all five card states at 960x540 and 1280x720, plus one phone-sized window, inspected by eye.
- *Hands-on play (required before any feel claim):* both routes in one normal window with a separate save, on keyboard and controller; a real phone for key size, thumb reach and caption size.

## 10. Build cost (engineer days, one person, estimates)

Includes headless tests and debug hooks. Excludes Nathanial's text review, Look 2 art, and the hands-on and phone play passes.

| Part | Days |
|---|---|
| `KeypadLogic` pure class and tests | 0.5 |
| Keypad card (one component: layout, focus graph, digit input, close/pause/back/debug interplay, prompts, UI tests) | 2.5-3 |
| Code-drawn reader prop with lamp modes and tamper sleeve, used by all four readers | 0.5 |
| SfxBank: key beep, denied triple, granted rise, seal tear, reader-lock tone | 0.25 |
| Exit bolt beat: wake to LOCAL after POP_BOLT, WOLF's read action with two tones, the seal hold station, lockout and recovery, hints and top card | 1.5-2 |
| Lamp-language touches: corridor seal lamp, Records exit lamp, blast door reader with DOOR FORCED | 0.75 |
| Save inside v5 (field, validation, tests) | 0.5 (about 1 if v5 has not landed) |
| Debug hooks | 0.5 |
| Public docs: walkthrough solution (spoiler-labelled), controls page, changelog and in-game changelog | 0.5 |
| **Total** | **about 7.5-8.5 days** |

**Cheaper variant, "B-lite" (about 3.5-4.5 days):** the same fiction, readers, WOLF/seal sources and lockout, but no keypad card. USE with a code on file makes the engineer punch it in automatically (digits appear on the in-world reader and in the hint row with beeps). This is the audit's model A. Wrong codes then cannot happen through play, so the lockout would only be flavour. The card can be added later without changing the save.

**Expanded-corridor add-on:** R1's USE refusal station, about 0.25 day, once the 1680 px corridor exists.

## 11. Risks

1. **Memory gating (resolved in this revision).** The first draft gated the code on the relay memory, which would have made a rushed WOLF hold back a third time. Now WOLF reads the code on both routes and only his tone changes (the audit's recommendation). If Nathanial wants the gate back, it needs a new story beat to justify it.
2. **"The code is right beside the door" can feel silly.** The sealed, tamper-logged override card is grounded in real sealed-combination practice, but players may still ask why the lock exists. The tamper log and LOCKOUT help it read as a deliberate emergency path. Playtest it.
3. **Light PIN gameplay.** The code is always on file before the card opens, so many players will press ENTER KNOWN CODE once. This is deliberate (no memorisation or note-taking, RESEARCH 2.3), but if Nathanial wants a real puzzle this option is the wrong one.
4. **Pacing at the end of the slice.** It adds 3-5 s (up to 13 s with a lockout) after the tank-drop climax and before END OF SLICE. Only a hands-on play can say if that aftermath feels earned or slow.
5. **Touch and readability.** The card is near the phone size limits (90x66 keys, below the 78 px target the Codex review set for USE). Captions are now 12 px and touch gaps 12 px, but a real phone test is required.
6. **Input edge cases:** digit keys that are also `choice_1`/`choice_2` (and pad X/Y, which share those actions); joypad A as both `interact` and `ui_accept`; Esc/Start closing the card vs pausing; Android Back; a player who rebinds a game action to a digit key will see the card take that digit while it is open. Each has a rule in section 6 and a test in section 9.
7. **New canon facts:** the LOCKDOWN/LOCAL reader fiction, the engineer's suspended maintenance access, the tamper-logged override card, WOLF reading a panel's memory (or the sentry's, if T7's alternative is chosen), and the digits. All need Nathanial's yes.
8. **Moving art.** The approved Look 2 HQ batch and the junction rebuild around the shutter doors may move or replace the bolt panel and hatch. Round 3 is now merged (`cfe304f`): WOLF waits in the hatch doorway with his snout at the panel's right edge, which this revision uses for his read. Place the reader on the beat, then re-measure. The corridor reader's USE station waits for the expanded corridor (about 20 px of free floor today).
9. **Sign text.** Reader micro-words must be typeset from an approved list, never generated into art, and must stay readable at game scale. Under the 2026-10-11 LABELS decision, status belongs on lamps; this option uses lamps for state and shows words only on the reader screen and in reach.
10. **Weak sources.** The Lenel offline-mode and SF 700 points come from search-result text only, because the pages blocked fetching. The design does not depend on them.

## 12. Questions for Nathanial

1. Do you approve the lockdown fiction: readers on the network show LOCKDOWN, and re-routed local power drops a reader to LOCAL so it takes a local override code?
2. WOLF now reads the code on both routes with a cooler tone when rushed (revised draft). Keep that, or gate it on the relay memory (which needs a new story beat)?
3. Engineer-only source: the tamper-sealed override card on the panel (drafted), or the downed sentry's service port, which mirrors the Records "WOLF's readout or the maintenance port" choice?
4. The digits: approve a code (the mock uses 7294 as a placeholder), a 0451 homage, or keep a •••• mask?
5. Entry: the full keypad card (mocked), or B-lite (USE punches the code in, no card)?
6. Is an 8 s lockout with a short reader-lock tone (no klaxon, no beacon flare) the right consequence?
7. Lines T1-T24, including the changed blast door line (T4) and the optional recap row (T20).

---

**Evidence label.** Rendered stills only: Godot 4.7.2 rendered the mock card over the real junction scene, first from an export of `7c19ee2` and, for this revision, from an export of `cfe304f` in `../export-cfe304f` (imported twice headless first, and once more after adding the mock scripts; the capture window quit itself and no Godot window was left open). The card in the stills is mock code, not a game feature: no input, focus or timing was exercised. No headless game tests were run for this design, nothing was played by hand, and no export or device test was done. Time costs and day counts are estimates.
