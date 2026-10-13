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
