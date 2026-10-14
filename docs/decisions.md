# Decision log — Revision 4
**September 25, 2026; solo-protagonist update September 28, 2026. Design authority, not an implementation tracker.**

| ID | Status | Decision |
|---|---|---|
| R4-01 | Adopted direction | Director's intended misuse motivates WOLF's self-awakening and containment escape in his existing body. |
| R4-02 | Adopted direction | Expose responsible people and stop the program using corroborating evidence. |
| R4-03 | Adopted direction | WOLF is an independent companion, possible friend/chosen family, not an object in any route. |
| R4-04 | Adopted direction | Human characters need personal names; Engineer is a job. |
| R4-05 | Adopted payoff | THE PACK includes sunrise and the human petting WOLF. |
| R4-06 | Supported concept | THE SHUTDOWN is voluntary protective sacrifice; a real friend is lost. |
| R4-07 | Provisional scope | Keep three outlines; final two-versus-three count remains open. |
| R4-08 | Preferred draft, not locked | Rowan Vale replaces Nathanial Mercer as the M0 engineer's default display name; stable actor ID remains `human`. |
| R4-09 | Proposed, deferred | Reserve `wolfoverride://` as a possible future URL scheme; M0 registers no platform deep link. |
| R4-10 | Provisional distribution | Windows is planned free; direct macOS download/Homebrew is a candidate, and the US Mac App Store price is proposed at $4.99. Sparkle applies only to a future direct Mac build; store updates use the store. No export or price is configured. |
| R4-11 | Proposed identifier | `com.mrdemonwolf.wolfoverride` is the candidate macOS/Android app ID, not yet registered or configured. Decide Apple universal-purchase structure before any iOS record. |
| R4-12 | Adopted public credit | State that Nathanial Henniges originated the game and core story and MrDemonWolf, Inc. develops it with AI assistance. Track each generated asset's provenance separately. |
| R4-13 | Adopted creative authority | Preserve Nathanial's original story premise. Research may improve pacing, interaction and emotional clarity without replacing the idea or silently establishing new canon. |
| R4-14 | Proposed later beat | Explore a temporary WOLF departure and reunion in Fracture, with his own agency and a viable human-only path. Exact incident and tasks remain open; this is not M0 or a route punishment. |
| S1-01 | Adopted gameplay direction | The engineer is the only playable character throughout the game. WOLF remains an independent companion with authored actions, choices and refusals; remove story-directed and free character switching. |
| S1-02 | Adopted M0 revision | Keep one corridor, the breaker/relay cooperation or manual reroute, one `relay_disagreement` choice, accurate callback and checkpoint, all from the engineer's controls. This revises the earlier switch-zone requirement without adding a campaign system. |
| S1-03 | Adopted identity; provisional art | The playable engineer is non-binary (assigned male at birth), uses they/them with every provisional name and is masculine-presenting (Nathanial, October 12, 2026; they/them since September 28). Current sprite direction is a cohesive deep-red hooded field jacket and charcoal gear; no yellow patches or shiny silver knee armor. The approved Look 2 sprite stays; final appearance remains open. |
| S1-04 | User-preferred direction; mechanism provisional | The Director tries to make WOLF a hitman: public threat protection masks ordered killing of people threatening the program. Recommended draft: an earlier Director-approved false classification harmed or detained an innocent through human security; the report hid his override; a records worker who saved the original becomes WOLF's proposed first hit. WOLF refuses and the Director blames a rogue WOLF for the current altered list/archive breach, not for the earlier harm or a killing WOLF never committed. Victim, outcome, target, motive, exact order, scope and corroboration remain open. |

## Proposed, not locked
Rowan Vale remains provisional, with Alex Bennett/Morgan Reed alternatives; Adrian Shaw, Elena Park, Mara Ellis and the optional MrDemonWolf handle are also proposed. Warfighter Operations and Logistics Framework remains a candidate W.O.L.F. expansion. Exact dialogue, offered-hand/head-lean staging, limited standby sensing, past experiences, original mission/abuse, evidence/witness chain, investigator/custody/epilogue details, chapter incidents and route gates remain open.

The shutdown cause, warnings, alternatives and irreversible cost need design. Do not solve them by arbitrary corruption or a score band. No final title, roster count or artwork is selected here.

## Superseded where conflicting
The unclear-threat-only opening; Engineer as permanent personal name; generic forced shutdown as preferred bittersweet ending; friendship equated with obedience; automatic two-ending removal; irrevocably fixed three-ending count; character switching and playable WOLF sections. Historical terminal/mockup ideas, later body transfer and hidden-backup fourth endings are not current canon.

## Preserved
Godot/GDScript, actual side-view 2D gameplay, Mac-first five-target plan, small independent-identity presets, deterministic memory, optional WOLF speech with fallback, accessible/fair choices, original placeholders and bounded M0. The original self-awakening, Director/evidence mission and chosen-family direction remain. No runtime AI/backend/paid APIs or unauthorized repository/setup changes.

## Deferred implementation
Full evidence/witness/petting systems, ending cinematics, full chapters, polished combat/art and distribution. First prove the corridor. All campaign route checks remain planned, not passed. Use existing Jira MDW-1584 for execution rather than another tracker.

Release work requires a final privacy/data inventory, suitable pre-install license/privacy notices, asset rights, and GPL/App Store legal review before a paid Mac store submission. Private working draft: [legal release](legal-release.md). Distribution research: [exports](exports.md).

## Presentation decisions (October 2026)
- The terminal look belongs only to the in-game Settings menu; the title screen and the public landing page keep their game presentation.
- 2026-10-07: the public docs and landing site should mostly use Tailwind CSS (Tailwind 4 `@theme` tokens and utilities), keeping only a small custom CSS layer.

## Play decisions (October 13, 2026)
Nathanial's answers to the play research questions (docs/research-2026-10/how-it-should-play/NEEDS.md, Q1-Q19). Questions not listed here are still open.
- **Q13 fuse:** the junction fuse lasts about 2.5 s with a tick sound, then is tuned down by play if it proves too easy.
- **Q7 tank drop:** a graze counts as a hit, and the drop window widens to about 0.5 s.
- **Q1 manual bypass:** the crank hold drops from 3.2 s to about 2 s, with a hold-toggle option for keyboard, controller and touch. The alarm and hiss still make the manual route cost time and nerve.
- **Q16 sentry death card:** use the already-approved alternative, "The sentry caught %s short of the rubble." The rubble is drawn; the lane is not.
- **Q2 opening:** the engineer is shown watching from the bay doorway as WOLF wakes. Design C's standby dock stays, and first control comes in 30-45 s. Any cut or rewritten lines are drafted for his approval first.
- **Q4 station labels:** floating labels over machines are replaced by real mounted name plates plus a prompt when in range. The floating labels become an optional Settings switch.
- **Q8 corridor door size:** the corridor's roller door is a freight/blast door and keeps its size (about 3 m).
- **Q14 relay choice wording:** option 2 is reworded so it says plainly what the engineer does (for example "Skip the risk talk. Go now."). The exact line is drafted for his approval.

## Wording and opening approvals (October 13, 2026)
Nathanial's choices on the wording drafts (docs/research-2026-10/how-it-should-play/drafts-2026-10-13.md), made through clickable choices after reading them. Items 1 and 3-7 take the draft's recommended option (★). The changed approved lines keep their old text under `history` in docs/research-2026-10/approved/.
- **Item 1, Q14 relay choice:** option 2 becomes "Skip the risk talk. Go now."; option 1 ("The relay may vent coolant. Your call.") is unchanged. CALLBACK_PRESS quotes the words the player chose; the death-text WOLF_RESPAWN_PRESS_2 uses its primary, "WOLF: Again. I'm still where I was." Old saves keep the words the player saw.
- **Item 3, P0-7 names that point at nothing drawn:** every row as recommended. Shown lines drop "alcove", "posts", "lane", "brackets" and "floor mark" and point at the TANK RELEASE, the sentry's sights, the mark, the rubble and the door. The objective "CHECK THE LANE" becomes "GO THROUGH THE DOOR". Leftover state words are plain (BREAKER USED, VALVE USED, RELEASE USED, EXIT LOCKED, EXIT READY), and the end card's third topic is SENTRY. The sentry death card uses the approved Q16 alternative, "The sentry caught %s short of the rubble." Mounted plates (Q4) are a later job: only the words change.
- **Item 4, P0-9 trust line:** two boxes shown in order after first control: "Rowan keeps WOLF's systems running." then "Rowan knows what a fault looks like, / and this isn't one." The name is the player's chosen name; they/them stays available for later lines.
- **Item 5, P0-15 refusals:** the whole refusal table as recommended, rows 1-7 with their keeps. On the press frame the station's lamp flickers twice, a short dull clunk plays, the line shows as the status line in the dialogue box, and a repeated press re-shows it with one blink of the box. The sealed door gets its own USE answer ahead of the valve's reach, "Sealed shut. Something hums behind it. / The valve beside it charges it."; walking into it gives a thud, a stop and a lamp flicker, with the line on the first bump only. A headless check proves sound, light and text within 6 frames for every row.
- **Item 6, P0-19 and Q5 narration:** cut N1 "A blue light answers from inside the containment seal.", N4 "The gate slides aside.", N5 "The Director freezes at the sound of the seal opening." and N14 "WOLF runs ahead to the valve and reads its LINE gauge.", and the clauses "the red seal stays shut" and "from a split line". The other 18 stay; showing them on screen is art and staging work for other jobs.
- **Item 7, Q6 junction entry:** the engineer's entry line becomes "That door is our way through.", then WOLF's approved door warning. The approved chain moves to hint step T3 as two boxes; the entry hint bar shows the goal only. The hint ladder: T1, WOLF looks at the breaker and its lamp pulses; T2, the engineer's "The breaker by the entrance / feeds that line."; T3, the chain; with the draft's timers (built at 45, 90 and 180 s). WOLF's run is shown, not narrated. Continue keeps the restore-A line.
- **Opening rebuild (item 2), decided and not built yet:** the engineer arrives after the Director's threat line (Q-A); the Director never notices them (Q-B); no reason is shown for why they are there (Q-C, the default); if the player walks back, the opened bay is empty and quiet and the Director is gone (Q-D, Q-E); WOLF shoulders the leaves aside, calm and deliberate (Q-F).
- **First playtest (item 8):** it uses the CI test build (Q15), with the observer's notes only and no recordings (Q-H), after the P0 fixes.

## WOLF's junction wording and the safe point (October 14, 2026)
Nathanial's choices of 2026-10-14, made through clickable choices after reading the WOLF-space drafts (docs/research-2026-10/how-it-should-play/drafts-wolf-space-2026-10-14.md).
- **Draft A, "holds back":** WOLF now waits on the floor beside the valve, short of the rubble (P0-4), so the four lines that put him "at the rubble" say what he does instead, on top of the October 13 wording. "The door goes. WOLF heads for the rubble / to wait for %s's call." becomes "The door goes. WOLF falls back / to wait for %s's call."; "WOLF: I'll hold at the rubble. / It crosses the mark on every pass." becomes "WOLF: I'll hold back. / It crosses the mark on every pass."; "WOLF: I'm out. I'll hold at the rubble." becomes "WOLF: I'm out. I'll hold back."; and the end card's "SENTRY  WOLF held at the rubble while {name} timed the drop." becomes "SENTRY  WOLF held back while {name} timed the drop." Nothing else changes: the engineer's lines about getting back over the rubble and the death card "The sentry caught %s short of the rubble." stay. The approved records in docs/research-2026-10/approved/ keep the old text under `history`.
- **WOLF comes to the doorway at the corridor's safe point (decided, not built yet):** when WOLF says "We made it." he walks up and stands in the open doorway near the engineer, fully visible, clear of the door frame, the machines and the engineer, and facing them. No line changes; this also settles "Open. I'm with you." Until it is built he waits on the relay's left there, which is a stopgap, not the design.
- **The safe-point room's camera-side wall is a clean architectural cutaway (decided, not built yet),** as in This War of Mine and Fallout Shelter.
- Both safe-point decisions are built by the corridor door-end additions job, with a redrawn door end, through its own pull request.
