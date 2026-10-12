# Option C: small and optional first

**This is private design material.** Keep it out of Git, public docs, PR text and build output. It answers Nathanial's request of 2026-10-11: "Can we add some pin codes and make it feel more like a furttgrue milialry base like iin skynet". The Terminator films' AI-run defence network is a mood reference only. Nothing here uses Skynet, Terminator or Cyberdyne names, logos, designs or text.

Every player-facing word in this file and in the mocks is **proposed, awaiting Nathanial**. That includes labels, card text, hints, narration, WOLF lines and the code digits. Nothing was built into the game and no Git repository or worktree was edited.

Inputs: `../research/RESEARCH.md` (sourced PIN research) and `../audit/AUDIT.md` (placement audit at `7c19ee2`). I also read `main.gd`, `records_room.gd`, `junction_room.gd`, `m0_state.gd`, `debug_menu.gd`, `debug_actions.gd`, `impact.gd`, the theme, the walkthrough pages, the private design files, the approved logic text and the approved item text.

Files in this folder:
- `strip.png`: a one-image summary with the mocks and a map.
- `mocks/*.png`: the 1280x720 stills.
- `export/apps/game/pin_mock/`: the scratch mock scene that rendered the stills (`tools/run.sh` copies it into `../export-cfe304f` and renders there).
- `tools/`: the strip, text-fit and render scripts.

**Revised before showing (2026-10-11), after the judge's review.** What changed:
1. **K2 no longer has an errand loop and no longer conflicts with logic round 3** (`cfe304f`). The pairing code is pulled at the terminal itself, over its paired link to the downed sentry: one hold at the terminal for the engineer, or WOLF's readout from his spot in the hatch doorway, where round 3 has him wait. Nobody walks to the sentry and WOLF never crosses back over the tank (section 2.2).
2. The K1 stills now show WOLF at the mirror, where the design puts him.
3. K1's placeholder code is now **6138**. The old 4072 was one digit off option A's 4071; if options are combined, the codes must not be near-twins (section 6).
4. On touch the keys are 84 wide with **12 px gaps** (about 8.6 pt, over Android's 8 dp), shown in `k1-3-wrong.png`.
5. Inside the card only `ui_accept` presses keys; `interact` from joypad events is ignored there, so one A press never fires twice (section 5).
6. K2's lockout no longer strobes the lane beacons beside the downed sentry; the terminal's own lamp carries it (section 3).
7. Every still was re-rendered on `cfe304f`, and the K2 terminal no longer overlaps the tank (it is a wall-mounted schematic; its real spot still needs the wider junction).

---

## 0. The pitch in six lines

1. **Two optional keypads, each guarding one approved evidence item.** Nothing on the essential path asks for a code, so skipping both changes nothing.
2. **K1, Records Access, MEDIA LOCKER (access level MAINT).** It holds the approved DATA CARTRIDGE. The engineer's own maintenance code still works here because the lockdown cut the network, and this locker runs on its own controller. K1 teaches the keypad in the one room with no hazards.
3. **K2, Service Junction, LANE TERMINAL (access level SECURITY), phase 2.** It holds the approved SENTRY PATROL LOG. It refuses the maintenance code. The downed sentry holds the terminal's pairing code. The engineer can pull it over the terminal's paired link with one hold at the terminal, or WOLF can offer to read the link with his readout from where he already waits. The log inside says "STAND-DOWN CODE: NO RECORD", so getting in reveals that nobody could have called the machine off.
4. **A wrong code costs seconds, never the beat.** Each miss shows DENIED with a count. The third miss locks the keypad for 6 seconds. Nothing else happens: no death, no alarm that brings anything, no lost progress.
5. **One keypad card works with every input and needs no new actions.** Each player can type the code, move focus with a D-pad or tap. When the code is already known, one press enters it, so nobody has to write anything down.
6. **It can grow later.** The same keypad logic and card can later carry the corridor seal's "access revoked" flavour beat, and then essential keypads once the evidence case and save v5 exist and hands-on play has proved the card.

---

## 1. Why this shape (grounding)

| Choice | Grounding |
|---|---|
| Optional first, essential later | AUDIT §6: the cheapest coherent set changes no essential route, and AUDIT §7.6 recommends "small optional first" (a Records locker). It also follows AGENT.md: "Do not add a new system merely to dress up one scene". Keep the system small until it is played. |
| Records first | AUDIT §2.2: the room has no hazards, the free span 248-462 already has the planned cartridge reader at 330-400, and AUDIT notes one station could have two beats: open the locker, then take the cartridge. |
| The code is a known fact, entered with one press | RESEARCH §2.3 and §4.1: players hate writing codes down and having to backtrack. Prey shows a found code beside the panel. This matches the decision that the case holds facts with no slots. |
| Four digits; three tries, then a short lockout | RESEARCH §1.1-1.2: ICS 705 requires four or more random digits. PIV cards block after 3 tries, and Schlage keypads lock for 30 s after 3. Here the lockout is 6 s because this is a game. |
| Access levels and reader modes as the military flavour | RESEARCH §1.5: Lenel reader modes (Locked, Card only, PIN and card), Genetec threat levels that raise the minimum clearance, and OSDP LED and beep states. ICS 705 F.1 also allows standalone combination locks, such as UNICAN and Simplex, which a network lockdown cannot reach. That gives K1's "local controller" a real-world basis. |
| WOLF reads, never fetches; the engineer always has a route | The private design: WOLF notices or ignores and never fetches, refuses rarely and meaningfully, and has no player request verb. AUDIT §3.3: memory should change his tone, not whether a code is available. K2 copies the approved MIRROR PORT pattern, "my readout or your maintenance port". |
| No new input actions | The task rules and AUDIT §4. The card reads digits as typed text (`unicode`, so AZERTY keyboards work) and the numeric keypad, and uses the built-in `ui_*` focus actions. |

---

## 2. The keypads

| | **K1 MEDIA LOCKER** (phase 1) | **K2 LANE TERMINAL** (phase 2) |
|---|---|---|
| Room and beat | Records Access, any time after entry. It is reachable before or after the purge queue and the mirror. | Service Junction, only after `sentry_down`, in the calm aftermath before the exit bolt. No timed beat is running then. |
| Where (today's 960 px rooms) | Centre x 365, USE reach ±40 (325-405), inside the free span 248-462. It stays clear of PURGE QUEUE reach (≤248) and MIRROR PORT reach (≥462). It replaces the planned bare DATA_RECORDS reader at 330-400; the reader moves inside the locker. | The planned LOG_LANE spot. **Today there is no floor:** the coolant-cloud span (700 ± 52) and the bolt reach (from about 741) leave nothing between them. It needs the expanded junction (1440 px). Place it by beat and measure after the grey box. |
| What it protects | The approved **DATA CARTRIDGE** (item text unchanged). | The approved **SENTRY PATROL LOG** (item text unchanged). |
| Access level stencil | MAINT (cyan band) | SECURITY (red band) |
| Reader mode line | LOCKDOWN · LOCAL CONTROLLER | LOCKDOWN · SECURITY CODES ONLY |
| Code | The engineer's own maintenance code. It is known from New Game and never stored. | The terminal's pairing code. It is learned in the room and stored as a fact. |
| Engineer-only source | Already known, so there is no errand. | The terminal's own **paired link**: HOLD E at the terminal for 3 HoldUse ticks (about 1.2 s) pulls the code from the downed sentry. No walking. |
| If WOLF helps | No new role. He is at the mirror by his own choice (`k1-0-room.png` shows him there). His approved cartridge notice and ignore lines still play. | He offers his readout once, as at the mirror. If accepted, he reads the paired link **from his spot in the hatch doorway** (`JunctionRoom.WOLF_DOWN_X`, 902, at `cfe304f`), and the code appears on his readout. He never walks back across the tank and never says the digits. |
| Essential? | No | No |

### 2.1 K1 flow (MEDIA LOCKER)

1. **In reach:** the station label MEDIA LOCKER appears, using the same style as PURGE QUEUE and MIRROR PORT. The keypad lamp is standby blue, and the hint reads "E: open the media locker."
2. **USE:** the keypad card opens on the side of the screen away from the locker, right in today's room, so the locker and the engineer stay visible (mock `k1-1-idle.png`). The engineer stops. Gameplay actions are released so the USE press does not also press a key. The world keeps running; nothing in Records is timed.
3. The card shows **YOUR MAINT CODE 6 1 3 8** (placeholder digits, §6) as its first focused key. One press (A, E, Enter or a tap) types the four digits with a key beep each, about 0.8 s in total, then submits.
4. **ACCESS GRANTED** (mock `k1-5-accepted.png`): a green tick, a long tone and a mag-lock clunk. The card closes after about 0.8 s, the door swings open (`k1-6-after.png`), and the label changes to LOCKER OPEN.
5. **Narration (new):** "The locker runs on its own controller; the lockdown never reached it." The approved DATA_RECORDS examine text follows, and the case shows "Logged: DATA CARTRIDGE". WOLF's approved reactions apply: the notice line if he was told the truth at the relay, the ignore beat if he was rushed, and silence if he is out of range.
6. **Typing by hand** is always allowed. It is the only way to get a wrong code and the 6 s lockout (§3).
7. **Skipping it** costs nothing. The exit, FIRST COPY and the junction work exactly as now.

### 2.2 K2 flow (LANE TERMINAL)

The flow keeps the approved MIRROR PORT pattern (WOLF offers his readout, the engineer always has a port, and both routes give the same fact), but everything happens **at the terminal**: no walk to the sentry and back. This removes the errand loop and fits logic round 3 (`cfe304f`), where WOLF waits in the hatch doorway once the sentry is down and "never walks back across" the tank.

1. **In reach, code unknown, first USE:** no card yet. The terminal prints its refusal as machine text (new): "LANE TERMINAL / ACCESS: SECURITY\nMAINTENANCE CODE REFUSED. CODE HELD BY PAIRED UNIT: LANE SENTRY." The lamp turns red once, with three short beeps.
2. **WOLF's offer**, if the terminal is within about 160 px of his spot in the hatch doorway in the rebuilt junction (he does not move for it). The existing answer row opens:
   - The new WOLF line has two tones by relay memory:
     - told the truth (disclose): "WOLF: The sentry's still paired to it. I can read the link, or you pull it."
     - rushed (press), including the lane "refused" route: "WOLF: It's paired to the sentry. My readout or your pull."
   - The answer row reads "1  USE WOLF'S READOUT     2  PULL IT FROM THE LINK".
   - The card is not open here, so keys 1 and 2 (`choice_1`, `choice_2`) work as normal.
3. **Answer 1, WOLF's readout:** WOLF stays in the doorway and turns his head to the terminal; his readout glows for about 1 s. Narration: "WOLF reads the pairing code off the terminal's link. It shows on his readout." The code is now known.
4. **Answer 2, or no offer:** the hint at the terminal reads "HOLD E: pull the code over the paired link." A HoldUse of 3 ticks at the terminal is needed, and the ticks survive releasing USE, as at the bypass. Narration: "The terminal pulls the pairing code from the downed sentry." The engineer never leaves the terminal.
5. **USE at the terminal, code known:** the card opens on the left (mock `k2-1-idle.png`, re-rendered on `cfe304f` with WOLF in the doorway), with **LANE CODE 8 1 4 3** focused. One press enters it, and ACCESS GRANTED follows.
6. **Reward:** the approved SENTRY PATROL LOG text, "Logged: SENTRY PATROL LOG", and WOLF's approved notice ("WOLF: Nobody could have called it off.") or ignore beat. The approved placement said "hold USE to copy". The code entry replaces that hold, so the copy happens on ACCESS GRANTED. This placement change needs Nathanial.
7. **Code unknown, later USEs:** the card opens without the known-code key, so a player can type freely. This is pointless but harmless, and the lockout applies.
8. **Leaving without it:** the exit bolt and hatch work exactly as now.

**WOLF route matrix for K2** (each case leads to the same unlocked log):

| Relay memory | Lane recap | WOLF in range | What happens |
|---|---|---|---|
| disclose | wolf / alone / broke off | yes (in the doorway) | Warm offer. Answer 1 means WOLF reads the link from where he stands; answer 2 means the engineer holds at the terminal. |
| press | refused / alone | yes (in the doorway) | Cool offer, but the same two options. He does not refuse: reading a code costs him nothing, so a refusal would be petty, and BAIT_NO already gave his refusal on this route. |
| any | any | no (the rebuilt room puts the terminal out of his range, or he is still waiting for the arm to park) | No offer. The hint points to the hold at the terminal. This is the engineer-only route. |
| empty (debug jumps only) | — | — | The disclose wording is the neutral default. |

---

## 3. A wrong code

The rules follow the death model ("a failure costs at most the current beat") and AGENT.md ("do not show fake consequences").

| Event | What the player sees and hears | Cost |
|---|---|---|
| Miss 1 or 2 | The digits turn red and shake for 0.2 s (skipped when motion is reduced). A cross icon shows "DENIED 1/3" or "DENIED 2/3", the accent bar turns red and three short beeps play. If enabled, a short tick plays through the existing `impact.rumble` switches. The digits clear after 0.6 s. | About 0.6 s |
| Miss 3 | An amber warning triangle shows **LOCKED OUT 0:06**, counting down. Keys and the known-code key grey out, and focus moves to BACK. One two-tone chirp plays (never the `klaxon`, which is the sentry's lock-on cue). The world lamp flashes amber. The lane's beacons do **not** strobe at K2: beside the downed sentry that would suggest it is waking. Card caption: "The keypad locks itself for a few seconds. Nothing else changes." | 6 s |
| After the lockout | The counter resets, and the known-code key (if known) is focused again. | — |

What a wrong code **never** does:
- kill or knock down the engineer;
- wake, spawn or alert anything;
- cost a save or a found code;
- change WOLF's memory or tone;
- lock the station for longer than 6 s;
- make the station unusable.

Typed digits, the miss count and the lockout timer are not saved, so Continue starts them fresh. Closing the card does not reset the miss count; nothing is worth exploiting there.

---

## 4. How it reads as a military base

All text is code-typeset from a list Nathanial approves. No sign text is painted by the image tool. Nothing uses any Terminator-franchise name.

1. **Access levels on everything.** Each keypad carries a stencilled band: **MAINT** in cyan (the art bible's "keypad cyan" `#2091ca` family) and **SECURITY** in red. The same badge sits in the card's corner. Colour always comes with the word. This sets up the base's rule: maintenance badges open maintenance doors, not security doors.
2. **Reader modes driven by the lockdown.** The opening's approved line "Lock down maintenance" now has a mechanism. Networked readers stop taking maintenance codes (K2: SECURITY CODES ONLY), while a standalone controller the network cannot reach still takes them (K1: LOCAL CONTROLLER). These are real behaviours (RESEARCH §1.5, ICS 705 F.1).
3. **Reader lamps and beeps from real readers:** standby blue, entering amber, denied red with three short beeps, granted green with a long tone, lockout flashing amber. These match the OSDP default states in RESEARCH §1.5.
4. **Lockout like a real keypad**, as a timed self-disable (§3), shortened for play.
5. **Paired machines.** A security sentry paired to its lane terminal is how a base would manage automated defences. The payoff log, "STAND-DOWN CODE: NO RECORD", turns the code hunt into the mood beat: the machine had a pairing code but no off switch.
6. **Room tie-ins already in the art:** Records and the junction already have lockdown beacons (K2's lockout leaves them alone, so nothing near the downed sentry changes). Title art B already shows a cyan keypad.
7. **Phase 3 flavour (corridor):** a reader beside the red seal that answers USE with "ACCESS REVOKED / LOCKDOWN". It gates nothing; it teaches that the network has dropped the engineer. It needs floor that today's corridor does not have (AUDIT §2.1).

---

## 5. The keypad card (touch, controller, keyboard)

**Mocks** were rendered in the real game: `main.tscn` at `7c19ee2`, reached through the debug jumps, with the game's own theme and fonts, at 1280x720. The card uses `MenuPanel`, `CardSheen`, the theme's Button styles, Montserrat Bold and Semibold, Roboto and `UIMotion`. The locker and terminal are code-drawn placeholders in the mocks.
- `mocks/k1-1-idle.png`: idle, controller focus on YOUR MAINT CODE.
- `mocks/k1-2-entering.png`: entering digits ("4 0 – –"), with the 0 key shown pressed and the keyboard hint.
- `mocks/k1-3-wrong.png`: wrong code ("4 0 7 7", DENIED 1/3), with the touch hint.
- `mocks/k1-4-lockout.png`: the third miss (LOCKED OUT 0:06).
- `mocks/k1-5-accepted.png`: accepted (ACCESS GRANTED; the locker in the room swings open).
- `mocks/k1-0-room.png` and `mocks/k1-6-after.png`: the station in the room before and after.
- `mocks/k2-1-idle.png`: K2 on the left side of the screen, SECURITY level, known LANE CODE, with WOLF in the hatch doorway as at `cfe304f`. The terminal is a wall-mounted schematic behind the engineer, clear of the tank; its real spot needs the wider junction.
- All stills were re-rendered on `main` at `cfe304f`.

**Layout in the 960x540 canvas:**
- The card is `Rect2(404, 84, 540, 446)`, the same rect as the debug menu's `MENU_RECT`. It sits under PAUSE (which stays visible and tappable) and above the bottom edge.
- When the station is on the right half of the screen, the card moves to x 16, so the station and the engineer are never covered.
- The bottom dialogue bar and the hint bar hide while the card is open, and the card carries its own status.
- **Left column (200 px):**
  - a readout of four digit cells in Montserrat Bold 36, with an en dash for empty cells;
  - a status row: an icon plus a word in Montserrat Bold 16;
  - the known-code key (200x92), two lines: the name and the digits;
  - BACK (200x84).
- **Right column:** a phone-layout 3x4 grid with 1-2-3 on top and CLR, 0, ENT on the bottom row (RESEARCH §3). Each key is 88x74 with 8 px gaps on desktop; on touch, 84x74 with 12 px gaps (`k1-3-wrong.png`). Digit keys use 28 px type, CLR and ENT 17 px.
- **Bottom line:** a hint for the device in use (13 px).
- **Each state has a word, a shape and a colour:**
  - ENTER CODE: ring and dot, cyan
  - ENTERING: square, amber
  - DENIED: boxed cross, red
  - ACCESS GRANTED: circled tick, green
  - LOCKED OUT: warning triangle, amber
- Every state also has its own sound (§3), so none relies on one sense (GAG, WCAG 1.4.1).

**Per device** (no new InputMap actions):

| Device | While the card is open |
|---|---|
| Keyboard | Typed digits come from `InputEventKey.unicode` '0'-'9', so French AZERTY users get digits with Shift as usual, plus `KEY_KP_0`-`KEY_KP_9`. After each typed digit, focus moves to ENT, so Enter submits. Backspace or Delete removes the last digit. Enter, KP Enter and Space press the focused key (`ui_accept`), and E (`interact` from a key event) does the same. Esc closes the card first (the debug-menu precedent); a second Esc pauses. |
| Controller | D-pad or left stick moves focus over an explicit focus-neighbour graph: the left column's right neighbours are rows 2 and 4, and the grid's left edge goes back to them. A presses through `ui_accept` only; joypad A is also `interact`, and the card ignores `interact` from joypad events, so one press never fires twice. B (`ui_cancel`) closes. Start closes the card, and a second Start pauses. Focus starts on the known-code key, or on 5 when no code is known (RESEARCH §4.6). The focus ring is the theme's `Button_focus`, inside the key's borders as AGENT.md requires. |
| Touch | Tap keys. Left, Right and USE hide; PAUSE stays. Tapping outside the card or Android Back closes it. No focus ring shows on touch (the existing `_grab_menu_focus` rule). On a landscape phone about 390 pt tall, the canvas scale is about 0.72, so keys are about 63x53 pt, above Apple's 44 pt and Android's 48 dp. The desktop 8 px gaps would be about 6 pt, under Android's 8 dp, so **on touch the gap is 12 px with keys 84 wide** (about 8.6 pt; `k1-3-wrong.png`). This needs checking on a real phone. |

**Engineering edge cases** (from AUDIT §4.2, resolved here):
1. **Keys 1 and 2 are `choice_1` and `choice_2`.** The card consumes every digit key in its own `_input` before `Main._input`. It uses its own `keypad_active` flag (gating `human.controlled` like `waiting_for_choice`) and never sets `waiting_for_choice`.
2. **Joypad A is both `interact` and `ui_accept`.** Inside the card only `ui_accept` presses keys; `interact` arriving from an `InputEventJoypadButton` is ignored, so one A press fires once. On open, release `GAMEPLAY_ACTIONS` (as Pause and knockdown do), and ignore `ui_accept` for the first frame.
3. **The debug menu** must not open over the card. `DebugMenu.open()` also checks `keypad_active`.
4. **Pause:** Esc or Start closes the card first. Losing window focus auto-pauses with the card still open, and resuming returns to it.
5. **Rebinding:** a player who binds a game action to a digit key loses that digit in the card. This goes on the Controls page.
6. **Timed beats:** neither keypad can be reached during a timed beat. K1 is in a room with no hazards, and K2 spawns only after `sentry_down`.
7. **Lighter game:** build one shared `KeypadCard`. Extract the debug menu's `_grid`, `_button` and `_link_focus` helpers into a small shared helper instead of copying them. Closed, the card has no process and draws nothing, like the debug menu.

---

## 6. The codes (digits need Nathanial)

The digits are new canon numbers (approved item brief: do not invent canon numbers; AUDIT §7.1). They avoid 1234, 0000, repeated digits, 19xx, 2580, 0317 (03:17) and anything tied to the purge time or target ID.

| Code | Mock placeholder | Alternatives | Note |
|---|---|---|---|
| K1 engineer's maintenance code | 6138 | 2709, 5824 | It shows on the card as the engineer's own code. It is the same for every name. (Changed from 4072, which was one digit off option A's 4071. If A and C are combined, pick one digit set with no near-twins.) |
| K2 lane pairing code | 8143 | 5261, 3907 | It shows on the card only after it is learned. WOLF never says digits aloud; they appear on his readout (logic text voice rule). |
| Homage option | 0451 | — | The cross-studio 0451 nod (RESEARCH §2.1). **Not recommended:** at a grim military site it reads as a wink. |

Codes do not change per run. Optional content does not need anti-spoiler randomisation, and fixed codes keep the walkthrough simple.

---

## 7. Lines (every one is **proposed, awaiting Nathanial**)

Fit was measured with Pillow against the game's fonts, using the method of the approved logic text: dialogue at Roboto 17 is 855 px wide without a speaker tag and 715 px with one, up to 3 rows; the hint bar is 526 px at 14 px. Worst-case name: Morgan.

**New lines**

| ID | Where / trigger | Speaker | Proposed text | Fit |
|---|---|---|---|---|
| PIN_K1_LABEL | Records station label | LABEL | MEDIA LOCKER | label |
| PIN_K1_LABEL_OPEN | after ACCESS GRANTED | LABEL | LOCKER OPEN | label |
| PIN_K1_STENCIL | locker band, card badge | LABEL | MAINT / ACCESS: MAINT | — |
| PIN_K1_HINT | in reach, closed | HINT | E: open the media locker. | 155/526 |
| PIN_K1_HINT_OPEN | in reach, open | HINT | The media locker is open. | 159/526 |
| PIN_K1_MODE | card mode line | CARD | LOCKDOWN · LOCAL CONTROLLER | — |
| PIN_K1_KNOWN | known-code key | CARD | YOUR MAINT CODE + digits | — |
| PIN_K1_GRANTED | after ACCESS GRANTED, before the approved cartridge text | NARRATION | The locker runs on its own controller; the lockdown never reached it. | 2 rows with the cartridge text (759/855) |
| PIN_K2_LABEL | junction station label | LABEL | LANE TERMINAL | label |
| PIN_K2_LABEL_DONE | after the log is copied | LABEL | LOG COPIED | label |
| PIN_K2_STENCIL | band, badge | LABEL | SECURITY / ACCESS: SECURITY | — |
| PIN_K2_MODE | card mode line | CARD | LOCKDOWN · SECURITY CODES ONLY | — |
| PIN_K2_HINT | in reach, code unknown | HINT | E: use the lane terminal. | 148/526 |
| PIN_K2_HINT_KNOWN | in reach, code known | HINT | E: enter the lane code. | 137/526 |
| PIN_K2_HINT_DONE | in reach, copied | HINT | The lane terminal's log is copied. | 202/526 |
| PIN_K2_REFUSED | first USE, code unknown (machine text) | NARRATION | LANE TERMINAL / ACCESS: SECURITY<br>MAINTENANCE CODE REFUSED. CODE HELD BY PAIRED UNIT: LANE SENTRY. | 2 rows (586/855) |
| PIN_K2_OFFER_DISCLOSE | after REFUSED, WOLF in range of his doorway spot, disclose | WOLF | WOLF: The sentry's still paired to it. I can read the link, or you pull it. | 1 row (451/715) |
| PIN_K2_OFFER_PRESS | same, press | WOLF | WOLF: It's paired to the sentry. My readout or your pull. | 1 row (356/715) |
| PIN_K2_CHOICE | answer row | LABEL | 1  USE WOLF'S READOUT     2  PULL IT FROM THE LINK | as MIRROR |
| PIN_K2_WOLF_READ | answer 1, readout done (he stays in the doorway) | NARRATION | WOLF reads the pairing code off the terminal's link. It shows on his readout. | 568/855 |
| PIN_K2_HINT_LINK | at the terminal, code unknown | HINT | HOLD E: pull the code over the paired link. | 258/526 |
| PIN_K2_HINT_LINK_PROGRESS | while holding | HINT | HOLD E: pull the code over the paired link, {ticks} of {needed}. | 300/526 (USE form 317) |
| PIN_K2_LINK_READ | link pulled | NARRATION | The terminal pulls the pairing code from the downed sentry. | 448/855 |

The K2 offer, link and lockout lines are new in this revision; their fits were measured with `../fixlogs/fit_new.py` against the same fonts and limits. The removed lines (WOLF_GOING, PORT_LABEL, HINT_PORT, PORT_READ and its variants) belonged to the old errand route.
| PIN_K2_KNOWN | known-code key | CARD | LANE CODE + digits | — |
| PIN_K2_LOCKOUT | third miss at K2 (status line after the card closes) | NARRATION | The terminal's lamp flashes amber while it locks itself. | 408/855 |
| PIN_CARD_STATES | card status row | CARD | ENTER CODE · ENTERING · DENIED 1/3 · DENIED 2/3 · LOCKED OUT 0:06 · ACCESS GRANTED | — |
| PIN_CARD_KEYS | card keys | CARD | 0-9 · CLR · ENT · BACK | — |
| PIN_CARD_LOCKOUT_NOTE | card caption during lockout | CARD | The keypad locks itself for a few seconds. Nothing else changes. | — |
| PIN_CARD_HINT_KEYS | card hint, keyboard | CARD | 0-9: type     BACKSPACE: delete     ENTER: submit     ESC: back | — |
| PIN_CARD_HINT_PAD | card hint, controller | CARD | D-PAD / STICK: move     A: press     B: back | uses `settings_menu.prompt` labels in the build |
| PIN_CARD_HINT_TOUCH | card hint, touch | CARD | Tap a key. BACK or a tap outside the card closes it. | — |

Alternatives for Nathanial:
- LOCKED OUT 0:06 could be "TAMPER LOCKOUT 0:06".
- MEDIA LOCKER could be "RETENTION LOCKER".
- LANE TERMINAL could be "LANE CONSOLE".
- The narration on the "mock room" still (`k1-0-room.png`) is a capture caption only, not a proposed line.

Voice checks:
- WOLF's lines are short, first person, with contractions.
- No key names, button names or digits are spoken.
- The engineer is never gendered.
- No square brackets (RichTextLabel-safe).
- No exclamation marks.
- No promise of later use and no grading.
- "DENIED 1/3" is a lockout count, not an item count. Flag it in case Nathanial reads the "no counts" item rule broadly.

**Changes to approved material** (each needs Nathanial):
1. **DATA_RECORDS placement:** "secondary console reader at about x 330-400 ... tap USE" becomes "inside the MEDIA LOCKER at x 365; USE opens the keypad first". The examine text and WOLF lines are unchanged.
2. **LOG_LANE placement:** "lane panel ... hold USE to copy" becomes "LANE TERMINAL behind a SECURITY keypad; copied on ACCESS GRANTED". The text and WOLF lines are unchanged. The approved "STAND-DOWN CODE: NO RECORD" stays and is now the payoff.
3. **New canon facts to confirm:**
   - the engineer has a personal maintenance code;
   - the lockdown dropped maintenance codes from the network, but not from standalone controllers;
   - the lane sentry is paired to a terminal that holds its log;
   - the digits themselves.

No approved line's wording changes.

---

## 8. Save impact

Today the save is `SAVE_VERSION` 4. Save v5 (the evidence case) is decided but not built.

- **Ship PIN state inside v5, alongside the case, not as its own version.** K1's reward is a case item, so phase 1 depends on the case. Building PINs first would force an extra version just for one flag.
- **New v5 fields** (sorted, unique string-id arrays, like the case's planned arrays):
  - `keypads_open`: `["lane_terminal", "media_locker"]`, the stations unlocked this run. A locker stays open even if its content is later lost under the death model.
  - `codes_known`: `["lane_terminal"]`. K1's code is always known and never stored.
  - Digits are **never** saved. They live in a code table beside the item catalogue, so changing them never breaks a save (as `memory.selected_text` is kept).
- **Not saved:** typed digits, the miss count, the lockout timer, and which route revealed K2's code. The recap does not use it. If Nathanial wants a case annotation by route (like REC_MIRROR), add `lane_code_route: "wolf" | "manual"`.
- **Validation order**, extending the planned v5 chain:
  1. Every id is known, unique and sorted.
  2. `"media_locker"` in `keypads_open` requires that Records has been entered (`chapter_id` is records or junction).
  3. `"lane_terminal"` in either array requires `sentry_down`.
  4. `"lane_terminal"` in `keypads_open` requires it in `codes_known`.
  5. v1-4 load with both arrays empty.
  6. The future-version fixture moves to 6, as already planned.
- **Persistence** follows the approved pickup rule: patch only the field in `beat_snapshot`, and call `_write_beat()` only once a checkpoint exists.
  - Learning K2's code is a fact. It must survive a knockdown restore, so it is written immediately.
  - Opening a keypad writes `keypads_open` together with the case entry it reveals.
  - Records has no hazards, so no restore happens there. The junction after `sentry_down` has no timed hazard, but the rule still protects against a forced knockdown.
- **Death model:** codes and open keypads are facts and never drop. Only the evidence item inside follows the drop and loss rules of "Secure the Evidence".

---

## 9. Test impact

| Suite | New or changed checks |
|---|---|
| New `keypad_test.gd` (pure `Keypad` class, headless) | Typing more than 4 digits is ignored; delete and clear; submitting right or wrong; DENIED counts 1 then 2; the third miss locks for 6 s on a fake clock; the lockout ends and the counter resets; the known code fills and submits; the code table looks up ids; there are no runtime digits in the save. |
| `m0_state_test.gd` | v5 round trip with both arrays; v4 loads empty; rejections for an unknown id, a duplicate, an unsorted array, a lane id before `sentry_down`, an open K2 without its code, and a locker before Records; the future-version fixture is 6. |
| `chapter_scene_test.gd` | K1 opened before and after each Records station; DATA CARTRIDGE logged once; skipping K1 leaves the exit and FIRST COPY unchanged; the card blocks movement and releases it on close; WOLF's approved reaction by memory. |
| `junction_test.gd` | K2 absent before `sentry_down`. Route matrix: relay (disclose or press) × lane recap (wolf, alone, refused, broke off) × WOLF in or out of range × answer 1 or 2, each leading to `codes_known` and then the log. WOLF never leaves `WOLF_DOWN_X` for K2 and never crosses the tank; the engineer never leaves the terminal's reach. A forced knockdown after learning keeps the code. A lockout touches no hazard, sentry, beacon or save and never plays `klaxon`. Skipping K2 leaves the bolt and hatch unchanged. |
| `ui_controls_test.gd` | The focus graph covers every key, with no dead ends; the start focus is the known key, or 5 when none is known. Digit keys 1 and 2 do not fire `choice_1` or `choice_2` while the card is open. The opening USE or A press does not press a key, and one A press inside the card presses a key exactly once (`interact` from joypad ignored). Touch gaps are at least 11 px. Esc, B, Back and a tap outside close the card. Pause after closing; auto-pause on focus loss. The debug menu cannot open over the card. AZERTY-style `unicode` digits and numpad digits work. Touch hides movement and USE but keeps PAUSE. Rebinding an action to a digit is documented, not blocked. |
| `sfx_bank_test.gd` | Key beep, denied triple beep, granted tone with clunk, lockout chirp: lengths, levels, no clipping. |
| `debug_tools_test.gd` | The CHOICES or CHEATS toggle (codes none, known or open); the F3 state page and F12 dump show `keypads_open` and `codes_known`; the `tank_down` and `end_of_slice` jumps build consistent arrays. |
| Hands-on (required before any feel claim) | One normal window, separate test save: K1 and K2 by keyboard, by controller, and on a real phone by touch, including a lockout on each. Record what was played and what was not. Headless checks and these stills do not prove feel. |
| Docs, when shipped | Walkthrough Records and Junction pages get the codes inside the existing spoiler-labelled solutions. The Controls page covers the card and digit keys (and digit rebinding). Changelog and in-game changelog. Keep private story out. |

---

## 10. Build cost

These are rough engineering days for one person. They include headless tests and debug hooks. They exclude Look 2 art (a locker prop and a terminal prop with manifest entries), Nathanial's text review, the hands-on and phone passes, and docs. The foundation figures follow AUDIT §6.

| Part | Days |
|---|---|
| `Keypad` pure logic class | 0.5 |
| Keypad card (model C) with a shared helper extracted from the debug menu; focus graph; digit capture; Back, Pause and debug interplay | 2.5-3 |
| Code-drawn station and lamp states, shared by both stations | 0.5 |
| Procedural sounds in SfxBank | 0.25 |
| Save fields inside v5 (assumes the case's v5 work exists) | 0.5 |
| Debug hooks | 0.5 |
| **K1 MEDIA LOCKER** (placement, flow, reward wiring to the case, tests) | 0.75-1 |
| **Phase 1 total (foundation + K1)** | **about 5.5-6.5** |
| **K2 LANE TERMINAL** (paired-link HoldUse at the terminal 0.25; WOLF offer and readout action from his doorway spot, tone and range handling 0.5; terminal lamp 0.25; route-matrix tests 0.5) | **1.5-2** |
| Phase 1 + 2 | about 7-8.5 |

**A cheaper first step, if wanted:** use model A from AUDIT §4.2 for phase 1. USE makes the engineer punch the known code into the world keypad with beeps and lamps, with no card. That is about 2-2.5 days, with the card added later for 2.5-3 days. The trade-off is no typed codes and no wrong code at first, so less of a PIN "feel".

Runtime cost: one Control tree, built once and hidden when closed, with no processing. There are no textures until Look 2 props are made. Sounds are procedural.

---

## 11. Risks

1. **K1 may feel like a ceremony** (a known code, one press). Mitigations: it is the teaching beat, typing stays open, and K2 brings the find-the-code loop. Hands-on play decides. Fallback: move K1's code to the corridor LOCKOUT TAG, which changes approved text (AUDIT §3.2).
2. **Dependency on the evidence case and v5.** K1's reward has nowhere to go without the case.
3. **K2 has no floor in today's junction.** It waits for the expanded room and its grey box (AUDIT §2.3, level-expansion plan).
4. **Approved-material changes** (DATA_RECORDS and LOG_LANE placement) and **new canon** (§7) need Nathanial's sign-off before any build.
5. **Contradiction risk:** a player may ask why a pairing code could be pulled from the sentry's link but there was no stand-down code. The approved log answers it ("NO RECORD"), but Nathanial should confirm that the pairing code and stand-down code being different things is acceptable canon.
6. **Input conflicts:** digit keys versus `choice_1` and `choice_2`; A as both `interact` and `ui_accept`; the debug menu and Pause over the card; rebinding to digits (§5). Each has a test above.
7. **Touch:** gaps under Android's 8 dp at 8 px, and the card covering half the screen. These need a real-phone pass. Do not claim touch works from stills.
8. **"Alarm" reading as a consequence:** the lockout's lamp and chirp must not suggest that something is coming. The lane beacons no longer strobe and the `klaxon` (the sentry's lock-on cue) is never used. The caption says nothing else changes. Hands-on play should check how it reads.
9. **The WOLF offer stacking on the press route** after BAIT_NO. It is kept as a tone change only, so the press route is never pricier. Nathanial may prefer no offer on the press route.
10. **Scope:** Nathanial asked for PIN codes and a military-base feel. This option keeps codes off the main path at first. If he wants codes in every room now, this is the foundation, and phase 3 or the audit's fuller set applies.
11. **Logic round 3 is merged** (`cfe304f`). This revision read it: once the sentry is down WOLF waits in the hatch doorway (`WOLF_DOWN_X`, 902) and never walks back across the tank. K2 now keeps him there and keeps the engineer at the terminal. The terminal's real spot, and whether it is within his range, wait for the junction rebuild.
12. **Mood reference:** keep every term generic (access levels, readers, lockdown). No franchise words, red-eye logos or lookalike UI.

---

## 12. Growing it later

- **Phase 1:** keypad logic, the card, K1. Then a hands-on play on desktop, controller and phone before anything else.
- **Phase 2:** K2, its paired-link hold and WOLF's offer from the hatch doorway, built after the junction grey box.
- **Phase 3, flavour:** the corridor seal reader showing "ACCESS REVOKED / LOCKDOWN" (gates nothing). It needs the expanded corridor.
- **Phase 4, essential (only if wanted after play):** the Records exit or the junction exit bolt keypads, with engineer-only sources in the same room (AUDIT R-EXIT and J-BOLT). They reuse the same card, logic and save arrays. Never a code on the breaker, bypass, tank release, any safe point or WOLF's containment gate, and never a stand-down code (AUDIT §0).

---

## 13. Questions for Nathanial

1. Is optional-first acceptable as the answer to "add some pin codes", with essential keypads only after play?
2. Should K1's code be the engineer's own (cheapest, no errand), or should it be found (the LOCKOUT TAG, an approved-text change)?
3. Are the new canon facts acceptable: a personal maintenance code; network lockdown versus a standalone controller; a sentry paired to a terminal?
4. Which digits (§6)? Is 0451 an option or a no?
5. On the press route, should WOLF offer his readout with a cooler line (proposed), or not offer at all?
6. Are the names right (MEDIA LOCKER or RETENTION LOCKER; LANE TERMINAL or LANE CONSOLE; LOCKED OUT or TAMPER LOCKOUT)?
7. Model C card now (about 5.5-6.5 days for phase 1), or model A first (about 2-2.5 days) with the card later?

---

## Evidence label

- **Read:** the source and private design at `7c19ee2`.
- **Rendered:** stills, by running the real `main.tscn` in Godot 4.7.2 (Compatibility renderer, one window, closed by the script). The first set ran from a scratch `git archive` export of `7c19ee2`; this revision re-rendered every still from an export of `cfe304f` (`../export-cfe304f`, imported headless twice, then once more after adding the mock scene), with `HOME` pointed at `scratchpad/home-pin`. The Records and junction states came from `DebugActions.jump`, which wrote a checkpoint into the scratch HOME only.
- **Overlays:** the keypad card, locker and terminal in the stills are scratch mock code (`export/apps/game/pin_mock/`), not game code.
- **Measured:** text fit with Pillow against the game's fonts.
- **Not done:** hands-on play, headless tests of the design (nothing was built), exports or device tests.
- **Not touched:** no Git repository, worktree, Notion or Jira page.
