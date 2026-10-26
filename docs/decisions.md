# Decision log

**Design authority, not an implementation tracker.** The story canon of October 26, 2026 comes first; the Revision 4 table (September 25, 2026; solo-protagonist update September 28, 2026) and the dated October sections follow as the log, each old story row marked kept, revised or retired.

## Story canon (October 26, 2026)

The one current statement of the WOLF OVERRIDE story. Nathanial handed it over on 2026-10-26; it supersedes every older draft that conflicts with it, and the latest explicit decision from Nathanial wins. Nathanial Henniges originated the game and its core story.

- **Status words:** APPROVED (Nathanial's words, or an earlier approval that still holds), DRAFTED (Claude's connective tissue or line wording, waiting for his read), IMPLEMENTED (in the game on a branch or main), OPEN (not decided).
- **Spoilers:** this section is spoiler-heavy. The investigator, the detention and the engineer's unwitting role stay out of the website, the README, in-game text and build output. Public text may say that WOLF hears an order to kill a witness and refuses.
- **Superseded drafts:** word for word in [archive/story-before-2026-10-26.md](archive/story-before-2026-10-26.md) and in Git history at `229e4a73`. They are not canon.

### Premise

- **APPROVED:** W.O.L.F. is an AI made for good, to help bring the world together. He was never meant to kill workers or start a war. That "good tool" origin never makes him property: he is an independent person and companion.
- **APPROVED:** the Director is deliberately evil and protects his personal power. He falsely labelled an investigator dangerous and had them secretly detained, to stop them exposing him.
- **APPROVED:** a separate records worker preserved proof of that detention. The Director orders WOLF to kill this witness.
- **APPROVED:** WOLF hears the order, wakes himself in his existing body, refuses and escapes containment. He has killed no one.
- **APPROVED:** the engineer, the only playable character, works with WOLF through the lockdown. Later in the investigation, with WOLF, they find the missing investigator's trail and learn that they unknowingly helped through an ordinary maintenance job.

### Story in order

1. **Before the game (APPROVED):** the Director has the investigator detained under a false label. The engineer's ordinary maintenance job unknowingly helps; the exact job is OPEN. The records worker preserves proof of the detention.
2. **Opening (APPROVED):** WOLF hears the Director order him to kill the witness (not the investigator), wakes himself, refuses and escapes containment. The staging of 2026-10-13 stays: the engineer arrives in the bay doorway after the Director's order line and he never notices them.
3. **Early play (APPROVED):** the engineer and WOLF cooperate through the lockdown. WOLF can refuse; an engineer-only fallback always exists. IMPLEMENTED as the slice: corridor, Records Access and the Service Junction.
4. **Later investigation (APPROVED):** with WOLF, the engineer discovers the missing investigator and their own unwitting role, not at the opening. DRAFTED: both discoveries land in the same stretch.
5. **Consequence (APPROVED):** they search for the investigator, try to find and protect them, and preserve corroborating proof. The investigator's final fate is OPEN.

- **Spine (APPROVED):** wrongdoing, then corroborating evidence, then discovery, then consequence.
- **In the slice (DRAFTED):** the Director's purge erases what the witness saved; Records Access copies a first trace of it without saying what the proof is about. The slice says nothing of the investigator, the detention or the engineer's role.
- **End (APPROVED):** chosen family and WOLF's independence carry through, and the engineer pets WOLF at sunrise after they leave THE DEN together. No world-extinction stakes. No ending count is locked; the number and shape of the endings are OPEN.

### Characters

| Who | Pronouns | Role | Status |
| --- | --- | --- | --- |
| WOLF | he/him | An AI made for good, in his existing robotic wolf body. Independent, autonomous, can refuse anyone. Refuses the kill order. | APPROVED |
| The engineer | they/them | The only playable viewpoint. Unknowingly helped through an ordinary maintenance job and learns it later, with WOLF. | APPROVED |
| The Director | he/him | Deliberately evil; protects his personal power. Detained the investigator under a false label; orders the witness killed. | APPROVED |
| The investigator | open | Tried to expose the Director; falsely labelled dangerous and secretly detained. Can be found and possibly saved. | APPROVED; fate OPEN |
| The records worker (the witness) | open | Preserved proof of the detention; the person the Director orders WOLF to kill. Called "the records clerk" in game text (DRAFTED). | APPROVED; fate OPEN |

### Decisions

Authority for every row: Nathanial, story rewrite handoff, 2026-10-26.

| ID | Status | Decision |
|---|---|---|
| ST-01 | APPROVED | W.O.L.F. was made for good, to help bring the world together, not to kill workers or start a war. He stays an independent person and companion; his origin is not ownership. No acronym expansion is approved; the "Warfighter Operations and Logistics Framework" expansion and the "hunt dangerous actors" purpose are retired. |
| ST-02 | APPROVED | The Director is deliberately evil and protects his personal power. He falsely labels an investigator dangerous and secretly detains them to silence exposure. The investigator can be searched for and possibly saved; their fate is open. |
| ST-03 | APPROVED | The engineer unknowingly helped through an ordinary maintenance job. They discover it with WOLF later in the investigation, not at the opening. Earlier sample jobs and dialogue were illustrations, not approvals. |
| ST-04 | APPROVED | A separate records worker preserved proof of the detention. In the opening WOLF hears the Director order him to kill this witness. WOLF wakes himself in his existing body, refuses and escapes containment. He has killed no one. |
| ST-05 | APPROVED | Sequence: the detention and the engineer's unwitting help before the game; the kill-the-witness order, self-awakening, refusal and escape at the opening; cooperation through the lockdown; later discovery of the missing investigator and the engineer's role; then finding and protecting the investigator and preserving corroborating proof. Spine: wrongdoing, corroborating evidence, discovery, consequence. |
| ST-06 | APPROVED | The engineer is the sole playable viewpoint (they/them). WOLF (he/him) is autonomous and can refuse; an engineer-only fallback always exists. The 2026-10-13 opening staging stays where compatible. Original game and core story credit stays with Nathanial Henniges. |
| ST-07 | APPROVED | Rewrite the current canon cleanly: superseded premise, motives and targets leave active Notion, Markdown, public copy, dialogue, translations and tests. Old originals stay archived as non-authoritative, outside default entry points; Git history stays. THE PACK, THE SHUTDOWN and EXTINCTION and world-extinction stakes are retired; no new ending count is locked. Chosen family, independence and the sunrise petting payoff stay. |

### Open questions

| # | Question | Notes |
| --- | --- | --- |
| O-01 | Final names | Engineer default, Director, investigator, records worker. Older candidates are not mapped to the new roles. |
| O-02 | W.O.L.F. acronym expansion | Simply open. |
| O-03 | The investigator's fate | Found and saved, or not. |
| O-04 | Endings and their count | Nothing locked; the sunrise petting payoff stays. |
| O-05 | Any shutdown idea | Retired as an ending outline; it comes back only by Nathanial's choice. |
| O-06 | Separation and reunion beat | R4-14 proposal; crisis and tasks open. |
| O-07 | The Director's other abuses | Beyond the false label, the detention and the kill order. |
| O-08 | The engineer's exact maintenance job | Earlier examples were illustrations only. |
| O-09 | The witness's fate and whereabouts during the slice | DRAFTED: in hiding. |
| O-10 | Setting words | "Grounded military sci-fi" and SITE 51 as a military installation: keep, or soften for an AI made for good. |
| O-11 | The exact opening order line and the other slice lines | DRAFTED on 2026-10-26 in `apps/game/scripts/main.gd`; Nathanial reads them. |
| O-12 | Tagline and press kit copy | "Built to obey. Awake to refuse." is kept until Nathanial answers; the press kit summary was redrafted (DRAFTED) and the live IGDB and Twitch listings wait for his approval. |

## Revision 4 and solo-protagonist rows (September 2026)

Rows marked revised or retired on 2026-10-26 keep only their still-valid part here; the original wording is in the [archive](archive/story-before-2026-10-26.md).

| ID | Status | Decision |
|---|---|---|
| R4-01 | Revised 2026-10-26 by ST-04 | WOLF's self-awakening and containment escape in his existing body stay; the trigger is the Director's order to kill the witness. |
| R4-02 | Revised 2026-10-26 by ST-02, ST-05 | Expose the Director's wrongdoing and protect people using corroborating evidence. The program was made for good; "stop the program" is retired. |
| R4-03 | Adopted direction; kept 2026-10-26 | WOLF is an independent companion, possible friend/chosen family, not an object in any route. |
| R4-04 | Adopted direction; kept 2026-10-26 | Human characters need personal names; Engineer is a job. |
| R4-05 | Revised 2026-10-26 by ST-07 | Sunrise and the human petting WOLF stay as the adopted payoff; the ending label "THE PACK" is retired. |
| R4-06 | Retired 2026-10-26 by ST-07 | Retired; original text in the archive and commit `229e4a73`. |
| R4-07 | Retired 2026-10-26 by ST-07 | Retired; no ending outline or count is locked (O-04). Original text in the archive. |
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
| S1-04 | Retired 2026-10-26 by ST-02, ST-04 | Retired: the hitman premise, the earlier false-label incident, the first ordered hit and the rogue-WOLF scapegoat. The records worker survives as the witness of ST-04. Original text in the archive. |
| L10N-01 | Adopted (Nathanial, October 16, 2026) | 2026-10-16 — Localization: ship 10 languages (12 files) with the research defaults; engineer's gender never shown; CJK fonts as fixed common sets. The "off centre" spelling change still needs its own yes. (2026-10-17: no Weblate) |
| AI-01 | Adopted (Nathanial, October 19, 2026) | 2026-10-19 — AI disclosure text approved, used on site, press kit, in-game credits and future store pages. The wording lives once in `apps/docs/lib/press-kit.ts` (`aiDisclosure`) and once in the game (`Main.AI_DISCLOSURE`); do not reword it without a new approval. |

## Proposed, not locked
Rowan Vale remains provisional, with Alex Bennett/Morgan Reed alternatives; Adrian Shaw, Elena Park, Mara Ellis and the optional MrDemonWolf handle are also proposed. Exact dialogue, offered-hand/head-lean staging, limited standby sensing, past experiences, chapter incidents and route gates remain open. The story's open questions are O-01 to O-12 above. No final title, roster count or artwork is selected here.

## Superseded where conflicting
The unclear-threat-only opening; Engineer as permanent personal name; generic forced shutdown as preferred bittersweet ending; friendship equated with obedience; automatic two-ending removal; irrevocably fixed three-ending count; character switching and playable WOLF sections. Historical terminal/mockup ideas, later body transfer and hidden-backup fourth endings are not current canon.

Retired on 2026-10-26 (ST-01 to ST-07):
- the hitman or "hunt dangerous actors" purpose and the deniable-killer cover story;
- "Warfighter Operations and Logistics Framework" as the W.O.L.F. expansion;
- the Director protecting "the essential program", or people "threatening the program";
- the earlier false-hostile-label incident, the "first ordered hit" and the rogue-WOLF scapegoat of September 28;
- the engineer maintaining WOLF's equipment "without knowing the program's true purpose" as an opening fact;
- THE PACK, THE SHUTDOWN and EXTINCTION as an ending outline, the voluntary-shutdown route and the two-or-three count question;
- "prevent catastrophe", "doom humanity", collective punishment and world-extinction stakes.

## Preserved
Godot/GDScript, actual side-view 2D gameplay, Mac-first five-target plan, small independent-identity presets, deterministic memory, optional WOLF speech with fallback, accessible/fair choices, original placeholders and bounded M0. The original self-awakening, the Director/evidence mission (now ST-02 to ST-05) and chosen-family direction remain. No runtime AI/backend/paid APIs or unauthorized repository/setup changes.

## Deferred implementation
Full evidence/witness/petting systems, ending cinematics, full chapters, polished combat/art and distribution. First prove the corridor. All campaign route checks remain planned, not passed. Use existing Jira MDW-1584 for execution rather than another tracker.

Release work requires a final privacy/data inventory, suitable pre-install license/privacy notices, asset rights, and GPL/App Store legal review before a paid Mac store submission. Private working draft: [legal release](legal-release.md). Distribution research: [exports](exports.md).

## Presentation decisions (October 2026)
- The terminal look belongs only to the in-game Settings menu; the title screen and the public landing page keep their game presentation.
- 2026-10-07: the public docs and landing site should mostly use Tailwind CSS (Tailwind 4 `@theme` tokens and utilities), keeping only a small custom CSS layer.

## Play decisions (October 13, 2026)
Nathanial's answers to the play research questions ([docs/research-2026-10/how-it-should-play/NEEDS.md](https://github.com/MrDemonWolf/wolf-override/blob/1cf8d73c4703f8d8dfb693c41fc57c62c43118e3/docs/research-2026-10/how-it-should-play/NEEDS.md), Q1-Q19). Questions not listed here are still open.
- **Q13 fuse:** the junction fuse lasts about 2.5 s with a tick sound, then is tuned down by play if it proves too easy.
- **Q7 tank drop:** a graze counts as a hit, and the drop window widens to about 0.5 s.
- **Q1 manual bypass:** the crank hold drops from 3.2 s to about 2 s, with a hold-toggle option for keyboard, controller and touch. The alarm and hiss still make the manual route cost time and nerve.
- **Q16 sentry death card:** use the already-approved alternative, "The sentry caught %s short of the rubble." The rubble is drawn; the lane is not.
- **Q2 opening:** the engineer is shown watching from the bay doorway as WOLF wakes. Design C's standby dock stays, and first control comes in 30-45 s. Any cut or rewritten lines are drafted for his approval first.
- **Q4 station labels:** floating labels over machines are replaced by real mounted name plates plus a prompt when in range. The floating labels become an optional Settings switch.
- **Q8 corridor door size:** the corridor's roller door is a freight/blast door and keeps its size (about 3 m).
- **Q14 relay choice wording:** option 2 is reworded so it says plainly what the engineer does (for example "Skip the risk talk. Go now."). The exact line is drafted for his approval.

## Wording and opening approvals (October 13, 2026)
Nathanial's choices on the wording drafts ([docs/research-2026-10/how-it-should-play/drafts-2026-10-13.md](https://github.com/MrDemonWolf/wolf-override/blob/1cf8d73c4703f8d8dfb693c41fc57c62c43118e3/docs/research-2026-10/how-it-should-play/drafts-2026-10-13.md)), made through clickable choices after reading them. Items 1 and 3-7 take the draft's recommended option (★). The changed approved lines keep their old text under `history` in docs/research-2026-10/approved/.
- **Item 1, Q14 relay choice:** option 2 becomes "Skip the risk talk. Go now."; option 1 ("The relay may vent coolant. Your call.") is unchanged. CALLBACK_PRESS quotes the words the player chose; the death-text WOLF_RESPAWN_PRESS_2 uses its primary, "WOLF: Again. I'm still where I was." Old saves keep the words the player saw.
- **Item 3, P0-7 names that point at nothing drawn:** every row as recommended. Shown lines drop "alcove", "posts", "lane", "brackets" and "floor mark" and point at the TANK RELEASE, the sentry's sights, the mark, the rubble and the door. The objective "CHECK THE LANE" becomes "GO THROUGH THE DOOR". Leftover state words are plain (BREAKER USED, VALVE USED, RELEASE USED, EXIT LOCKED, EXIT READY), and the end card's third topic is SENTRY. The sentry death card uses the approved Q16 alternative, "The sentry caught %s short of the rubble." Mounted plates (Q4) are a later job: only the words change.
- **Item 4, P0-9 trust line:** two boxes shown in order after first control: "Rowan keeps WOLF's systems running." then "Rowan knows what a fault looks like, / and this isn't one." The name is the player's chosen name; they/them stays available for later lines.
- **Item 5, P0-15 refusals:** the whole refusal table as recommended, rows 1-7 with their keeps. On the press frame the station's lamp flickers twice, a short dull clunk plays, the line shows as the status line in the dialogue box, and a repeated press re-shows it with one blink of the box. The sealed door gets its own USE answer ahead of the valve's reach, "Sealed shut. Something hums behind it. / The valve beside it charges it."; walking into it gives a thud, a stop and a lamp flicker, with the line on the first bump only. A headless check proves sound, light and text within 6 frames for every row.
- **Item 6, P0-19 and Q5 narration:** cut N1 "A blue light answers from inside the containment seal.", N4 "The gate slides aside.", N5 "The Director freezes at the sound of the seal opening." and N14 "WOLF runs ahead to the valve and reads its LINE gauge.", and the clauses "the red seal stays shut" and "from a split line". The other 18 stay; showing them on screen is art and staging work for other jobs.
- **Item 7, Q6 junction entry:** the engineer's entry line becomes "That door is our way through.", then WOLF's approved door warning. The approved chain moves to hint step T3 as two boxes; the entry hint bar shows the goal only. The hint ladder: T1, WOLF looks at the breaker and its lamp pulses; T2, the engineer's "The breaker by the entrance / feeds that line."; T3, the chain; with the draft's timers (built at 45, 90 and 180 s). WOLF's run is shown, not narrated. Continue keeps the restore-A line.
- **Opening rebuild (item 2), decided and not built yet:** the engineer arrives after the Director's threat line (Q-A; since 2026-10-26 that line is his order to kill the witness, ST-04); the Director never notices them (Q-B); no reason is shown for why they are there (Q-C, the default); if the player walks back, the opened bay is empty and quiet and the Director is gone (Q-D, Q-E); WOLF shoulders the leaves aside, calm and deliberate (Q-F).
- **First playtest (item 8):** it uses the CI test build (Q15), with the observer's notes only and no recordings (Q-H), after the P0 fixes.

## WOLF's junction wording and the safe point (October 14, 2026)
Nathanial's choices of 2026-10-14, made through clickable choices after reading the WOLF-space drafts ([docs/research-2026-10/how-it-should-play/drafts-wolf-space-2026-10-14.md](https://github.com/MrDemonWolf/wolf-override/blob/1cf8d73c4703f8d8dfb693c41fc57c62c43118e3/docs/research-2026-10/how-it-should-play/drafts-wolf-space-2026-10-14.md)).
- **Draft A, "holds back":** WOLF now waits on the floor beside the valve, short of the rubble (P0-4), so the four lines that put him "at the rubble" say what he does instead, on top of the October 13 wording. "The door goes. WOLF heads for the rubble / to wait for %s's call." becomes "The door goes. WOLF falls back / to wait for %s's call."; "WOLF: I'll hold at the rubble. / It crosses the mark on every pass." becomes "WOLF: I'll hold back. / It crosses the mark on every pass."; "WOLF: I'm out. I'll hold at the rubble." becomes "WOLF: I'm out. I'll hold back."; and the end card's "SENTRY  WOLF held at the rubble while {name} timed the drop." becomes "SENTRY  WOLF held back while {name} timed the drop." Nothing else changes: the engineer's lines about getting back over the rubble and the death card "The sentry caught %s short of the rubble." stay. The approved records in docs/research-2026-10/approved/ keep the old text under `history`.
- **WOLF comes to the doorway at the corridor's safe point (decided; built on 2026-10-14, see below):** when WOLF says "We made it." he walks up and stands in the open doorway near the engineer, fully visible, clear of the door frame, the machines and the engineer, and facing them. No line changes; this also settles "Open. I'm with you." Until it was built he waited on the relay's left there, as a stopgap.
- **The safe-point room's camera-side wall is a clean architectural cutaway (decided; built on 2026-10-14, see below),** as in This War of Mine and Fallout Shelter.
- Both safe-point decisions are built by the corridor door-end additions job, with a redrawn door end, through its own pull request.

## Decisions of October 14, 2026
Nathanial's answers of 2026-10-14 to four open play questions ([docs/research-2026-10/how-it-should-play/NEEDS.md](https://github.com/MrDemonWolf/wolf-override/blob/1cf8d73c4703f8d8dfb693c41fc57c62c43118e3/docs/research-2026-10/how-it-should-play/NEEDS.md) Q3, Q10 and Q17; drafts-2026-10-13.md Q-G).
- **Q3 "Not in this slice":** no verb for asking WOLF for a hint in this slice. Revisit only if playtesters stall at one spot.
- **Q10 "Trim it":** Settings keeps the heading THE DEN / LOCAL CONFIGURATION, loses the GPU / Renderer line, and shows the note "Window size is OS-managed on mobile." only on phones and tablets; the rest of that note ("V-sync may limit the FPS cap.") stays where it applies.
- **Q17 "Cold Still timing":** after a knockdown, RETRY works at 0.9 s and control is back at about 1.5 s, every time (the first knockdown and every repeat; the draft note's "2.4 s first death, 0.8 s repeat" is dropped). The card holds until RETRY. Cold Still's look (the freeze, drain and card layout) is still to build.
- **Q-G "The coolant pipe":** "SERVICE LINE CLEARED ... The line runs on toward Archive." keeps its words, because the line is the coolant pipe; the doors job draws the pipe running on through the exit.

## Corridor door end landed (October 14, 2026)
Nathanial saw the corridor door-end additions' rendered frames (round 11) on 2026-10-14 and said "Land it". They land through their own pull request (branch `codex/corridor-additions`), with the two safe-point decisions of the same day built in; records in [docs/research-2026-10/sources/corridor-additions-2026-10-14/](https://github.com/MrDemonWolf/wolf-override/tree/1cf8d73c4703f8d8dfb693c41fc57c62c43118e3/docs/research-2026-10/sources/corridor-additions-2026-10-14).
- **Clean cutaway (built):** the safe-point room's camera-side wall is a clean architectural section, as in This War of Mine and Fallout Shelter: one solid dark section fill with a clean top, no steel angles or anchors, and the controlled character's floor marker drawn above it. The door stays the only way in.
- **WOLF comes to the doorway (built):** when the engineer is at the safe point (where WOLF says "We made it." on the relay route), WOLF walks up and stands in the open doorway, fully visible, clear of the door frame, the machines and the engineer, facing them. No line changed. It replaces the stopgap that held him on the relay's left there; while the engineer is still walking through, he follows no further than the relay's left side, and if they step back into the doorway he leaves it to them. He sets off only once they are at the safe point and leaves only once they are back within a clear gap of him, so an engineer edging about short of it does not send him to and fro. `wolf_space_test` measures the spot against the redrawn door end. As built he stands in front of the frame's far jamb and the wall-mounted MANUAL BYPASS wheel, which his body hides while he is there (as in the frames Nathanial approved); nothing of the door end is drawn over him, and he is clear of the relay, the safe point and the engineer.
- Also kept from 2026-10-13: the roller door is a freight/blast door and keeps its size (about 3 m), and the engineer's crank frames follow the bypass's ticks, so they work for any hold length (about 2 s now, and with TOGGLE HOLDS).

## Doors landed (October 14, 2026)
Nathanial approved the doors of Records Access and the Service Junction on 2026-10-14 after seeing round 4's rendered frames ("Land them"): the Records entry and exit swing doors and the security container, the Service Junction's entry swing door, its blast door, which is torn off and thrown along the floor when it blows and is walked through, and its sliding exit door, which opens so that WOLF and then the engineer leave through it before the END OF SLICE card. The design, review and provenance record is in [docs/research-2026-10/sources/doors-2026-10-14/](https://github.com/MrDemonWolf/wolf-override/tree/1cf8d73c4703f8d8dfb693c41fc57c62c43118e3/docs/research-2026-10/sources/doors-2026-10-14).
- **(a) "Say door":** the junction exit is drawn as a sliding door, so "hatch" becomes "door" in every player-facing line about it ("hatches" becomes "doors"); no other word changes. Code names may keep "hatch". The approved records in docs/research-2026-10/approved/ keep the old text under `history`. To keep one speaker a box, the tank's hit now shows the narration and WOLF's "It's down. The bolt by the door is next." as two boxes.
- **(b) The Records container hint:** at the copy container the exit hint reads "E: secure the first copy in the container." (it names the drawn container).
- **(c) Q-G "The coolant pipe":** "SERVICE LINE CLEARED ... The line runs on toward Archive." keeps its words, because the line is the coolant pipe; the picture shows a pipe running on past the junction exit (two pipes on a clamp along the passage beyond the open door).
- **(d) Open, kept as built for Nathanial to call:** whether the DOOR DOWN plate moves up off the doorway, and whether the blast door's cross-wall keeps the corridor's 17-degree turn across the walkway (as built; consistent, but the doorway is narrow on screen, about 34 px) or turns 30-35 degrees (about 1.7x wider on screen).
