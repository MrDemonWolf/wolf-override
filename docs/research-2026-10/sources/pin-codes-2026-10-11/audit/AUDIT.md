# PIN codes in the slice: where they could go (audit)

**This is private design material.** It answers Nathanial's request of 2026-10-11: "Can we add some pin codes and make it feel more like a furttgrue milialry base like iin skynet". This file maps where PIN codes could fit the slice as it stands on `main` at `7c19ee2`. Nothing in the game was changed. Every player-facing string here is **proposed, awaiting Nathanial**. Story hooks are marked as hooks, not canon. Keep this file out of Git, public docs and PR text.

What I read: `apps/game/scripts/{main,records_room,junction_room,m0_state,game_settings,hold_use,pause_overlay,ui_motion,sentry_brain,drop_arm,pressure_line}.gd`, `scripts/debug/{debug_tools,debug_menu}.gd`, `scenes/main.tscn` (touch and pause nodes), `assets/fonts/game_theme.tres`, the three walkthrough pages, `PRIVATE_AGENTS.md`, `PROJECT_CONTEXT.md`, `docs/next-session.md`, `docs/research-2026-10/README.md`, the approved item text, death text and logic text, `data/real-inventory-design.json`, `data/death-safe-points.json`, `data/level-expansion.json`, and the 2026-10 direction memory.

How sure each claim is: positions, states, inputs and the save format come from reading the code. Nothing was run or played for this audit. Costs are estimates.

---

## 0. Summary

- **The slice already gives a reason for codes.** The opening's approved line is "DIRECTOR: Lock down maintenance. WOLF does not leave this site." (`main.gd:90-98`). A base-wide lockdown is exactly when a military site's keypads stop taking normal codes. The approved title art B already shows a cyan keypad (`#2091ca`, "keypad cyan" in `art-bible.md`), so a keypad prop matches art that has already shipped.
- **Every room has one natural PIN spot that does not touch the timed or risky beats:**
  - Corridor: the sealed shutter, which reads "lockdown, codes revoked". This is flavour and teaching, not a gate.
  - Records Access: the exit shutter (essential), or an optional locker by the planned cartridge reader. Records is the hazard-free room.
  - Service Junction: the exit bolt panel, the calm beat after the sentry is down.
- **Places that must not get a PIN gate:**
  - The corridor breaker, which holds the one remembered relay choice.
  - Any safe point, which is "always safe".
  - The tank release, which is timed under threat.
  - A sentry "stand-down" code. That contradicts the approved LOG_LANE text, "STAND-DOWN CODE: NO RECORD."
  - The containment gate. WOLF wakes and breaks the latch himself.
  - The MANUAL BYPASS. A code there would make the refusal route harder than the WOLF route.
- **A code can come from an existing or approved source, with no new errands:**
  - an evidence-case record the player already gets;
  - WOLF's readout (he already reads the mirror index and the line gauge);
  - an approved object such as the LOCKOUT TAG.
  - Rules: the code must never be WOLF-only (`real-inventory-design.json` inv rule 2), and the player must never have to memorise it. The keypad shows codes the player already knows.
- **No new input actions are needed** (§4). There are three entry models, from cheapest up:
  - (A) auto-entry on USE, which matches inventory rule 7, "used where they belong through USE context";
  - (B) a digit dial on the existing move/USE inputs;
  - (C) a real 3×4 keypad card built from the debug menu's button grid and focus code.
- **The save needs little or nothing new** if PIN state goes into the planned **v5**, alongside the evidence case. Most unlocks can be derived from flags that already exist.
- **One fixed constraint:** the approved item brief says not to invent canon numbers, such as the purge order's time or target ID. Any PIN digits are a new fact that Nathanial must approve. Never derive them from the purge time, the target ID or the 03:17 containment card.

---

## 1. Rules that bind any PIN design (from the private design and approved text)

| Rule | Source | What it means for PINs |
|---|---|---|
| The engineer is the only playable character; WOLF acts on his own and has no request verb yet | PRIVATE_AGENTS, research README ("no player request verb yet") | The player cannot ask WOLF for the code. He offers it at authored moments, such as the first time the engineer uses a keypad without the code. |
| Every essential step has an engineer-only route | PRIVATE_AGENTS, inv rule 2 | An essential keypad needs a code source the engineer reaches alone, or a fallback (manual override). WOLF is never the only source. |
| WOLF never fetches or carries; he notices items or pointedly ignores them | README "WOLF" bullet, item brief | WOLF cannot bring a keycard or a slip of paper. He can **read**: a panel's memory, a readout, a worn keypad. |
| WOLF refuses rarely and meaningfully | 2026-10-10 Codex-review refinements | Reading a code costs him nothing, so a refusal there would be petty. Relay memory should change only his **tone** at a keypad (notice vs pointed ignore), never whether a code is available. |
| No moral penalty for fear or refusal | PROJECT_CONTEXT | A code gate must not land only on the press/refused route (see the MANUAL BYPASS, §2.1). |
| A failure costs at most the current beat; facts are never lost | death model, "Secure the Evidence" | A wrong code costs seconds at most. A known code and an unlocked door are facts that a knockdown or death must not undo (§5). |
| The evidence case is facts with no slots; items are never spent, required or counted; used through USE context; no select-then-use; no hauling | inv rules 1, 3, 7; README "Case" | A found code is a case **record** or a derived fact, not an inventory key you select. The keypad uses it on USE. |
| No canon numbers; mask a needed value and flag it | item brief voice rules | The PIN digits need Nathanial's approval. Leave them out of the purge time, the target ID and 03:17. |
| WOLF "never speaks key names or button instructions" | logic text voice rules | WOLF must not say "press 4, 1, 7". If he gives the code, it shows on his readout or as narration ("The panel's last entry shows on WOLF's readout"). Nathanial should rule on whether WOLF may say digits in-world. |
| Mood reference only: no Skynet, Terminator or Cyberdyne names, logos or designs; sign text is typeset from an approved list, never painted by the image tool | 2026-10-11 night memory | Keypad legends, "ACCESS DENIED" and similar stencils are code-typeset labels from a list Nathanial approves. |
| No permanent name banners; a small name plus its action appears in reach; status shows on lamps | 2026-10-11 LABELS | A keypad shows its state on a red, amber or green lamp, and its label appears only in reach (for example "KEYPAD · E: enter code"). |
| Mobile is a first-slice target; prefer no new input actions | README, task rules | §4 |
| Lighter game: one shared component, old assets replaced | feedback-lighter-game | Build one keypad component used in every room, not a copy per room. |

---

## 2. Room by room: what a military base would lock, what it does today, and how a PIN would fit

Positions are world x in today's 960 px rooms. The level-expansion plan (corridor 1680 px; Records and Junction 1440 px) will move all of them. Place PIN beats **by beat**, and measure them again after each grey box.

### 2.1 Maintenance corridor (`chapter_id "lockdown"`)

Order today: opening (Director, cage, lockdown) → name card → purge display (optional) → BREAKER (relay question, then arm) → COOLANT RELAY (WOLF route) or MANUAL BYPASS (engineer route, hold-crank) → red seal opens → SAFE POINT (first save; a second USE enters Records).

| Thing | x / reach | In play now | Essential? | WOLF there | PIN fit |
|---|---|---|---|---|---|
| Containment cage and gate (opening) | intro only | WOLF wakes himself and breaks the latch from inside (INTRO_LINES) | Story | His self-awakening | **No.** A code would undercut "Nobody gives an activation command. WOLF wakes himself." The cage design is under separate review, and the cage stays 100% the same until then. |
| Purge display, DIRECTOR / PURGE | x ≤ 230 (`PURGE_DISPLAY_MAX_X`) | Optional read. The stakes line is required on the path. | No | Sums it up as you pass | **Flavour only.** It could show an "AUTHORIZATION: DIRECTOR" header. Never let a code cancel the purge, because that would rewrite the story. |
| BREAKER | 350 ± 52 (`_at_breaker`, `main.gd:948`) | First USE: the stakes line, then WOLF's relay question (the **one remembered choice**). Next USE arms it. | Yes | Asks the relay question | **No.** A keypad here would crowd the game's key choice beat. |
| COOLANT RELAY (WOLF's contact) | 605, reach 553 to under 670 (`_at_relay`) | Disclose: WOLF takes the live contact. Press: he refuses and points to the bypass. | Yes (one of two routes) | Memory-gated: he takes it only if told the risk | **No.** It is WOLF's action, not a lock. |
| MANUAL BYPASS handle | 700 ± 30 (`BYPASS_WHEEL`, `main.gd:20`) | Engineer-only route: hold USE about 3 s (`BypassHandle.TICKS_NEEDED` × 0.4 s), with hiss and alarm. It works on both routes. | Yes (the engineer-only route) | Stands off the relay | **Not recommended.** A "maintenance override code" fits the military mood. But gating the bypass makes the press/refused route cost more than "time and nerve", which is the approved framing ("never progress"). If it is wanted anyway, the code must come from somewhere on the path before the breaker (the LOG_CORRIDOR screen or the tool spot), and WOLF must not be its source. |
| Red seal / corridor shutter | door face at 752 (`CORRIDOR_DOOR_LEFT_X`) | Opens on power. No station of its own. | Yes (opens by relay or bypass) | Waits | **Good flavour or teaching spot ("lockdown access").** A keypad on the shutter portal reads LOCKDOWN with a red lamp. On USE, the engineer's own maintenance PIN is refused: "codes revoked", which is why you power around it. It is non-gating, so it costs no progress and teaches the keypad and lamp language for later rooms. Geometry: the bypass reach ends at 730, so today there is only about 20 px of free floor before the door. It needs the expanded corridor, or a reach beside the shutter on its right after it opens. |
| SAFE POINT | 876 ± 52 | First save, the WOLF callback, then enter Records. Required once, as the securing tutorial. | Yes | Callback line | **Never.** Safe points are always safe. |
| Planned LOG_CORRIDOR "RELAY WORK ORDER" screen (approved text) | about 520-530 (hold USE to copy) | Not built | No | Neutral before the choice; notice or ignore after | **Possible code source,** but its approved text is fixed ("TECH NOTE: REMOVED."). Adding a code line changes approved text, so it needs Nathanial. |
| Planned OBJECT_CORRIDOR "LOCKOUT TAG" (approved text) | written as 690-740, which **now overlaps the bypass reach (670-730)** and must move | Not built | No | Notice: "That lock isn't holding anything." | **Best physical code source in the corridor.** Real lockout/tagout tags carry a signature and an ID. A code on the back of the tag is plausible and adds no errand, because it is on the path. It is an approved-text change, so it needs Nathanial. |
| Planned TOOL_A "WHEEL RATCHET" | about 460 | Not built | No | — | Not a code source. Its shaft is stamped "MAINT", which is flavour only. |

Corridor summary: use the shutter as a **non-gating keypad that teaches the language**. The LOCKOUT TAG can be the code a later room uses. Leave the breaker, relay, bypass and safe point alone.

### 2.2 Records Access (`chapter_id "records"`): no hazards, so this is the best room to teach

Order today: entry autosave → PURGE QUEUE copy (essential) → MIRROR PORT, with a choice of WOLF's readout or the manual port (essential; WOLF goes to the mirror on his own, **not** memory-gated) → EXIT: first USE secures the first copy and plays the closing beat, the next USE enters the junction (`main.gd:1791-1838`).

| Thing | x / reach | In play now | Essential? | WOLF there | PIN fit |
|---|---|---|---|---|---|
| PURGE QUEUE terminal | 190 ± 58 | Copies the purge-order trace (`preserve_purge_trace`) and autosaves | Yes (first essential beat) | Heads for the mirror | **Low.** A "log in first" PIN on the first essential beat is friction with no story return. Never let a code cancel the purge. |
| MIRROR PORT | 520 ± 58 | A choice of WOLF's readout or the manual port, which copies the timestamp (`preserve_mirror_trace`) and autosaves | Yes | **Reads machine data with his readout,** by his own choice | **Code source, not a lock.** Both routes already produce a copy. The same readout could show the exit's access code, so both routes give it and nothing new is needed. That changes the approved MIRROR records ("Add nothing to these facts"), so it needs Nathanial. |
| EXIT shutter / hatch | 830 ± 58 (`RecordsRoom.EXIT_REST`) | Locked until both traces are copied. Then the closing beat. Then USE leads to the junction. | Yes | Follows | **Strong essential candidate:** a records vault's exit keypad. It already waits on two facts, so a third gate (the code) must come from those same beats (the mirror readout or purge trace) or from the corridor's LOCKOUT TAG. Otherwise it is busywork. On the engineer-only route the manual port must give the code too. |
| Planned DATA_RECORDS "DATA CARTRIDGE" reader (approved text) | 330-400 (free span 248-462) | Not built; the first physical pickup | No | Notice: "The casing's still warm." | **Best optional "small first" spot.** A code-locked drawer or locker holding the cartridge reader. It is hazard-free, so a wrong code costs nothing. It teaches the keypad before anything essential uses it. |
| Planned Records safe point | about 690-700 | Not built | Yes (when built) | WOLF moment | **Never.** |

Free floor today: 248-462 (the cartridge reader goes there) and 578-772 (the safe point goes there). An extra locker fits only by sharing the cartridge station, which is better anyway: one station, two beats (open the locker, take the cartridge).

### 2.3 Service Junction (`chapter_id "junction"`, "Blowback")

Order today: entry autosave A, with WOLF scouting the seam → OVERLOAD BREAKER (200) starts a 6 s gauge → hold USE at the VALVE (420) for three 0.4 s turns before the vent (grate 264-336) lets go → FUSE (1 s); get out of the blast zone (360-540) → door blows, autosave B → step onto the rubble line (`CHOICE_X` 526): WOLF's bait question, memory-gated → TANK RELEASE in the alcove (cover 545-626) drops the tank onto the mark (700) → sentry down, autosave C → EXIT BOLT panel (806; reach from about 741, hatch included): a 0.6 s whine, the bolt arcs, the hatch slides open → USE leaves, autosave D → END OF SLICE.

| Thing | x / reach | In play now | Essential? | WOLF there | PIN fit |
|---|---|---|---|---|---|
| Entry deck | 0-148 | WOLF runs to read the seam (`WOLF_SEAM_X`) | — | **Scouting and reading a gauge** | Planned OBJECT_JUNCTION "CRACKED GAUGE" sits at 60-130. A small optional locker here is possible but low value. |
| OVERLOAD BREAKER | 200 ± 52 | Arms the line, and resets after a vent trip | Yes | Waits clear at 100 (`WOLF_CLEAR_X`) | **Medium.** A military "overload interlock, enter override" is believable. Risk: retry busywork. After a vent trip or a blast knockdown (which restores autosave A) the player must **not** re-enter it, so the unlock must persist as a fact (§5). The code source must sit before it (the entry deck or a corridor/Records find). |
| Relief vent | grate 264-336 | Hazard (knockdown) | — | Keeps off it | **No.** |
| VALVE | 420 ± 52, hold-crank | Three turns charge the door | Yes | Reads the LINE gauge | **No.** It is timed. A modal keypad during "building" would fight `pressure_line.paused = waiting_for_choice` (`main.gd:2267`). |
| SEALED DOOR (pressure bulkhead) | 452-480 | "Sealed from the other side. Something hums behind it." | Yes (blown) | Reads the seam: "It's live." | **Good flavour:** a keypad lamp reading LOCKED, SECURE SIDE. It explains why you blow the door instead of opening it. It is non-gating (inside the blast zone; USE answers "sealed" today). |
| Rubble line / lane question | `CHOICE_X` 526 | WOLF's bait question (draw it if disclosed, refuse if pressed) | Choice | **Memory-gated action** | **No.** |
| TANK RELEASE (alcove) | `ARM_X` (left end of 545-626) | Drops the tank; timed against the sentry | Yes | Draws the sentry if he chose to | **No.** It is timed under threat. A code here would turn tension into fumbling. |
| Sentry / lane | 545-840 | Patrols, locks on, chases | Hazard | — | **No stand-down code.** Approved LOG_LANE: "STAND-DOWN CODE: NO RECORD." It **supports** the military mood: the automated defence has no off switch. |
| Planned LOG_LANE panel | past the rubble, after `sentry_down` | Not built | No | — | Its text is approved. It can serve as flavour (MODE: LOCKDOWN, AUTHORITY: DIRECTOR). Adding a code line needs Nathanial. |
| EXIT BOLT panel + hatch | panel 806; reach from about 741 to the hatch at 880 | "Locked out while the sentry runs the line"; then the bolt pops, arcs and the hatch opens | Yes | Follows (after `sentry_down` he no longer holds at the rubble) | **Strong essential candidate:** the calm aftermath beat. It is already framed as a lockout, so a lockout keypad reads naturally. A source with no busywork: WOLF reads the bolt panel's or the downed sentry's memory (like the mirror readout, and not memory-gated). The engineer-only source must be the code found earlier (LOCKOUT TAG or Records), or a fallback such as a hold-crank "manual release". The approved POP_BOLT line ("the winch's power reroutes to the exit bolt") would gain a step before it. |
| Planned junction safe point (emergency lamp in the blown doorway) | doorway | Not built | Yes | WOLF moment | **Never.** |

---

## 3. Where a found code can come from without new busywork

Ranked by fit with the approved rules:

1. **A derived record in the evidence case (facts, no slots).** The code becomes known as a side effect of a beat the player already does: copying the mirror index, or the purge trace if Nathanial wants the Director tie. It shows as a case line and **on the keypad itself** ("KNOWN: …"). Cost to the player: zero. It needs approved text, and the code reaches the player on both the WOLF route and the manual route.
2. **An approved physical find on the path.** The LOCKOUT TAG (corridor) suits a "maintenance code" that opens maintenance-side things later. No hauling: the tag is on the way. It does not drop on death in a way that matters: the approved death model keeps facts, and a code read off a tag is a fact (§5). It needs the tag text extended, and the tag moved out of the bypass reach.
3. **WOLF reads it.** He already reads machine data in two rooms (the mirror readout; the line gauge and seam). A code read from a panel's memory, or from the keypad's wear and last entry, shows his ability **and his choice** without fetching. Memory gating should only colour his line ("notice" if told the truth, a cool "ignore"-style beat if pressed), never take the code away. It must never be the only source for an essential lock.
4. **Something in the room the engineer can read alone:** a stencilled maintenance panel, a gauge card, worn keys on the keypad. Worn keys are a classic, but they turn into a guessing puzzle of 24 orders for 4 digits. That is fine only for an optional locker, with a WOLF or tag hint.
5. **The engineer already knows it.** They are a maintenance engineer, so they have a maintenance PIN. The lockdown revokes it (a hook for "lockdown access": "ACCESS REVOKED / LOCKDOWN"). This is the cheapest source and fits the opening. Proposed story hook, needs Nathanial.

Busywork guards for any design:
- the keypad shows known codes, so nothing has to be memorised or written down;
- the source is in the same room or directly on the path;
- no backtracking to a terminal for a code;
- a wrong code costs about a second (buzz, red lamp), with no alarm that spawns threats outside the junction;
- no attempt counter that can block an essential door;
- an optional locker can have a short "LOCKOUT 10 s" for mood, and only there.

---

## 4. The input system and what a keypad screen would reuse

### 4.1 What exists (all in code; `project.godot` has no `[input]` section)

- **Actions** (`main.gd:3269 _install_inputs`):
  - `move_left`: A, Left, D-pad left, left stick −
  - `move_right`: D, Right, D-pad right, left stick +
  - `interact`: E, joypad A
  - `choice_1`: **1**, joypad X
  - `choice_2`: **2**, joypad Y
  - `pause_game`: Esc, Start
  - `cycle_name`: I (a hidden name-cycling key)
  - It also adds joypad B to `ui_cancel` and joypad A to `ui_accept`. The built-in `ui_up/down/left/right/accept/cancel/focus_next/prev` drive menus.
- **Rebinding** (`game_settings.gd`): six actions can be rebound. `_binding_conflict` checks every non-`ui_` action. `prompt(action, controller)` gives the label for each device, and hints rewrite `E:` through it (`_refresh_ui`, `main.gd:3031-3036`).
- **Device tracking:** `_note_input_device` (`main.gd:1469`) switches `controller_active` and handles the "first key or pad press only reveals focus" rule through `_menu_focus_target` (`main.gd:1366`). `_grab_menu_focus` (`main.gd:1356`) releases focus on touch and grabs it otherwise.
- **Touch** (`main.tscn:418-468`; `_bind_touch_button` at `main.gd:1170`): Left and Right (96×90 at y 345-435), USE (155×90, relabelled CONTINUE, CRANK or DROP from real state), PAUSE at the top right (854-942, 16-72). The two answer buttons are 428×76 on touch and 522×40 on desktop at `CHOICE_ROW_TOP` 88. All are `TouchButton` variation buttons that press and release actions. `touch_enabled` is true only on iOS and Android.
- **Hold-USE** (`hold_use.gd`): 0.4 s ticks. Ticks made survive a release, a pause or stepping away. It is keyed by a station id from `_hold_station()` (`main.gd:2066`; today `&"valve"` and `&"bypass"`).
- **Modes that freeze play:**
  - `waiting_for_choice` turns off `human.controlled` (`_update_controls`, `main.gd:2854`), pauses the pressure line and the sentry and arm (`main.gd:2267`, `2305-2306`), and hides touch movement.
  - Pause pauses the tree and releases `GAMEPLAY_ACTIONS`.
  - Knockdown sets `fail_active`.
  - Android Back walks out of menus (`_handle_back`, `main.gd:1412`).
  - Losing focus auto-pauses.
- **Debug menu as a reference card** (`scripts/debug/debug_menu.gd`):
  - a backdrop plus a `MenuPanel` card plus `CardSheen`;
  - `GridContainer` buttons built by `_button()` with `UIMotion.attach`, a 40 px height and `_mark_chosen` accent colours;
  - explicit focus neighbours (`_link_focus`);
  - touch releases focus (`_focus_first`);
  - Esc, B, Back or a tap outside closes it;
  - it holds the game still while open;
  - closed, it does not process or draw.
- **Debug code watcher:** `debug_tools.gd` watches typed letters and pad sequences **only on the title screen**, so digit entry in play cannot collide with it.

### 4.2 Three entry models (none needs a new action)

| Model | How each input works | Reuses | Feel | Cost |
|---|---|---|---|---|
| **A. Auto-entry on USE** | Code known: USE makes the engineer punch it in (digits fill the keypad readout with procedural beeps, about 1 s, green lamp). Code unknown: USE gives an "ACCESS DENIED / LOCKDOWN" readout and a hint, or opens the two-answer row: "1 ENTER KNOWN CODE / 2 MANUAL OVERRIDE" (reusing `choice_1/2` and the existing choice buttons). | `_interact` routing, the station hint and touch USE label, SfxBank (a beep is trivial next to `_klaxon`), status lamp | Quick and physical. Matches inventory rule 7 ("used where they belong through USE context"). Least "hacker". | Lowest |
| **B. Digit dial** | Four digit cells. `move_left/right` change the selected digit. `interact` sets it and moves to the next cell. Holding `interact` (HoldUse) on the last cell submits. Touch uses the existing Left, Right and USE buttons (USE relabelled ENTER). Esc, B or Back cancels. | HoldUse, the touch buttons, `_set_dialogue`/hint row; no new Control nodes | Tactile, like a combination dial. Slower (about 10 presses). Works the same on all three devices. | Low to medium |
| **C. Keypad card** | A modal card with a 3×4 grid (1-9, CLR, 0, ENTER) and a 4-cell readout. Keyboard: digits typed directly (raw `KEY_0-9` and `KEY_KP_0-9` read in the card's `_input` and consumed, with no InputMap action), Backspace, Enter. Controller: D-pad or stick focus (`ui_*`) and A, B to close. Touch: tap keys. | The DebugMenu building blocks (`_grid`, `_button`, `_link_focus`, `_focus_first`), `UIMotion`, the `MenuPanel` and `CardSheen` theme, `_grab_menu_focus`/`_menu_focus_target`, the PauseOverlay-style `_input` for cancel | The most "military base terminal". The terminal look stays in Settings, so use the game's menu card rather than the terminal theme. | Highest |

Edge cases for model C:
1. **Digit keys 1 and 2 are the default `choice_1/choice_2`.** The card must consume digit key events before `Main._input` sees them. `Main._input` acts only while `waiting_for_choice`, so the card must not set that flag; it needs its own mode flag that gates `human.controlled` the same way.
2. **Joypad A is both `interact` and `ui_accept`.** On open, release `GAMEPLAY_ACTIONS` (as Pause and knockdown do) so the USE press that opened the card does not also press a key.
3. **The debug menu's `open()` checks only `pause_overlay.visible`.** It would also need to check the keypad mode.
4. **Pause on top of the card.** `_unhandled_input` pauses on `pause_game`. Either Esc/Start closes the card first, as in the debug menu, or Pause opens over it and resumes back into it. Pick one and test it.
5. **Rebinding.** A player who binds a game action to a digit key would see the card take that digit. Acceptable, but document it.
6. **The timed junction beats.** Never open the card while the line is building, the fuse is lit or the sentry is hunting. The placements in §2 avoid this.

**Touch sizing for model C:**
- The 960×540 canvas scales by about 0.72 on a phone that is 390 pt tall in landscape. The 56 dp USE target in the Codex review needs about **78 canvas px** per key.
- A 3×4 grid of about 96×78 keys with 8 px gaps is about 304×336 px. With a readout and a known-code row it does **not** fit the 450×389 Pause panel (`main.tscn:763-767`).
- Use its own card, about 540×450 like the debug menu's `MENU_RECT` (404, 84, 544, 446). Lay it out in two columns: readout and known codes on the left, keypad on the right. Hide the touch movement buttons and keep PAUSE where it is.
- Check it on a real phone before claiming it works.

---

## 5. Save format and how a PIN fits

**Today: `SAVE_VERSION` 4** (`m0_state.gd:4`), written as JSON to `user://m0-save.json`, atomically through `.tmp` with `.tmp` recovery.
- Fields: identity, positions, the relay `memory` (exact text the player saw, 6 keys), the puzzle (`breaker_armed`, `door_open`, `route`), `checkpoint_reached`, `chapter_id`, the Records flags, `door_blown`, `sentry_down`, `junction_cleared`, and the optional `lane_recap`.
- `from_dict` validates in order (v3 block, v4 block, junction ordering, door-position check) and rejects anything unknown.
- Loading accepts only saves with `checkpoint_reached`.
- Autosaves happen at beats (`_save_progress` → `_mark_beat` + `_write_beat`). Knockdowns restore the disk autosave, or `beat_snapshot` before the first checkpoint (`main.gd:2625`).

**Planned v5** (decided, not built): the evidence-case fields (sorted string-id arrays, collected and dropped/lost), with derived records never stored. v1-4 load as empty, and the future-version test fixture moves to 6 (`real-inventory-design.json` shared foundation).

Recommendations:
- **Ship PIN state inside v5, not as a separate bump.**
- **Store code ids, not digits.** The digits live in a code table next to the item catalog, so changing text never breaks a save, in the same way `memory.selected_text` is kept.
- **Derive wherever possible:**
  - A code learned from a derived record is known when that flag is set (for example `mirror_trace_preserved`). It needs no field.
  - An essential door's unlock can be derived when it happens in the same beat as an existing flag. For example, the Records exit unlocked = `chapter_complete`. The junction bolt unlocked is a new fact between `sentry_down` and `junction_cleared`. It can stay unsaved if the code's source and its entry come back together after a restore, or it can be one id in an `unlocked` array.
  - An optional locker opened = its content's id is in `collected`.
- **Validation order** (extends the inv-rule 12 chain): ids known and unique; a door unlocked only once its code is known; a room unlocked only once the chapter has reached it (a junction id requires `chapter_id == "junction"` and the beat order).
- **Persistence:**
  - Follow the approved pickup rule: patch only the relevant field of `beat_snapshot`, and call `_write_beat()` only once a checkpoint exists.
  - An essential unlock that is its own beat calls `_save_progress()`.
  - Under the death model, a code is a fact and **never drops**. A known code or an unlock must survive a knockdown restore, or the junction breaker idea (§2.3) turns into retry busywork. Today's knockdown in the junction restores **autosave A**, which predates anything learned later in the room.
- **Debug tools** need: a known/unlocked toggle on the CHOICES or CHEATS page, the code in the F3 state page and the F12 JSON dump, and jumps that set codes consistently (`debug_actions.gd` `CHECKPOINT_JUMPS`).

---

## 6. Cost of each placement

These are rough engineering days for one person. They include headless tests and the debug hooks. They exclude Look 2 art generation, Nathanial's text review and the hands-on and phone play passes, which every gameplay change still needs before any feel claim.

**Shared foundation (pay once)**

| Part | Cost | Notes |
|---|---|---|
| `Keypad` logic as a pure class (like HoldUse/PressureLine): code id, entered digits, state idle/denied/granted/lockout, `known(code_id)` from state | 0.5 d | Headless tests are frame-independent. |
| Keypad station drawing: lamp states plus code-drawn readout digits (typeset, no painted text) | 0.5 d | Can be code-drawn with no image art (lightest). A Look 2 prop needs a manifest entry. |
| Procedural keypad beeps, denied buzz and granted chirp in SfxBank | 0.25 d | Like the existing `_klaxon`. |
| Model A wiring (USE routing, hint and touch label, optional two-answer fallback) | 0.5 d | |
| Model B dial | +1 d | Reuses HoldUse and the touch buttons. |
| Model C keypad card | +2.5-3 d | Card, focus graph, digit keys, Back/Pause/debug interplay, `ui_controls_test` additions. A phone check is required. |
| Save (inside v5 with the case) | +0.5 d | A standalone v5 before the case: about 1 d (migration, rejections, fixture to 6). |
| Debug hooks (toggle, state page, jumps) | 0.5 d | |

**Each placement (on top of the foundation)**

| ID | Placement | Kind | Code source | Cost | Risk / notes |
|---|---|---|---|---|---|
| C-SHUTTER | Corridor seal keypad: "lockdown, codes revoked" | Flavour and teaching, non-gating | The engineer's own PIN (revoked) | **S: 0.25-0.5 d** | Needs floor beside the shutter (expanded corridor or the open side). No route change. |
| C-BYPASS | MANUAL BYPASS override code | Essential (engineer route) | LOCKOUT TAG or work order before the breaker | M: 1.5 d | **Not recommended:** puts extra cost on the refusal route. |
| R-LOCKER | Records optional locker around the cartridge reader | Optional "small first" | LOCKOUT TAG, WOLF's notice or worn keys | **M: 1-1.5 d** | Hazard-free teaching. The content is the approved DATA CARTRIDGE, so no new item text beyond the keypad lines. |
| R-EXIT | Records exit vault keypad | Essential | The mirror readout (both routes) or the corridor tag | **M: 1.5-2 d** | Changes approved MIRROR/FIRST COPY wording, so it needs Nathanial. Route matrix: WOLF and manual mirror × code known by each source. |
| J-DOOR | Junction sealed door, "LOCKED, SECURE SIDE" | Flavour, non-gating | — | **S: 0.25 d** | Inside the blast zone; a USE readout only. |
| J-BREAKER | Overload interlock code | Essential | An earlier find, or the entry deck | M: 1.5-2 d | Retry busywork unless the unlock survives the autosave-A restore. Adds a step before a timed loop. |
| J-BOLT | Exit bolt lockout keypad | Essential (calm aftermath) | WOLF reads the panel or sentry memory; engineer-only: an earlier find or a hold-crank manual release | **M: 1.5-2 d** | Adds a step before the approved POP_BOLT line. Route matrix: lane wolf, refused or alone × code source. |
| J-SENTRY | Sentry stand-down code | — | — | — | **Blocked by approved text** ("STAND-DOWN CODE: NO RECORD."). |
| X-SAFE | Any safe point | — | — | — | **Never.** |

Docs and site, per placement that ships: the walkthrough pages (codes go in the existing spoiler-labelled solutions), the Controls/Input page (model C's digit keys), the changelog, and the in-game changelog text. Keep private story out.

Cheapest coherent set: C-SHUTTER + R-LOCKER + J-DOOR with model A. That is about 2.5-3.5 days including the foundation. It adds the military access-control language in all three rooms, one optional code puzzle, and no change to any essential route.

Fullest set without breaking a rule: C-SHUTTER, R-LOCKER, R-EXIT, J-DOOR and J-BOLT with model C. That is about 9-11 days plus the art and phone passes.

---

## 7. Open questions for Nathanial

1. The PIN digits are a new canon fact. Approve specific codes, or use a placeholder mask (••••) until you choose?
2. May WOLF say digits aloud, or do codes appear only on his readout or in narration? (The voice rule says he "never speaks key names or button instructions".)
3. Is "lockdown revoked the engineer's own maintenance PIN" acceptable as a story hook?
4. May the approved texts gain a code line? These are LOCKOUT TAG, MIRROR TIMESTAMP and FIRST COPY, and LOG_LANE stays without a stand-down code.
5. Which entry model do you want: A (quick USE), B (dial) or C (keypad card)?
6. Which design: found code, lockdown access, or small optional first? This audit backs "small optional first" (R-LOCKER) as the first thing to build, because it changes no essential route.

---

Evidence label: everything above comes from reading source files and private design documents at `7c19ee2`. No Godot run, rendered still, hands-on play, export or device test was done for this audit. The unmerged branch `codex/logic-round-3` (opening hatch, sentry, tank and knockdown changes) was not audited and may shift junction details.
