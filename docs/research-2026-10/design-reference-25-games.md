# WOLF//OVERRIDE design reference: lessons from shipped games

Built 2026-10-10 from the research dossiers, their fact-check corrections, six dimension syntheses, three gap-fill dossiers and the completeness critic. Read-only: no repo files were changed. Current-state numbers were re-checked against `apps/game/scripts` on this date.

---

## 0. Pipeline status

Nathanial asked for all the other agents to run again. That partly happened, and it changed the conclusions.

- **New this run:** gap-fill dossiers on death and saves (Hollow Knight, Silksong, Celeste, Dark Souls, Alien: Isolation, RE1/RE2R/RE4R, Signalis, Amnesia: The Bunker / Dark Descent, Oddworld) and on inventory and deduction (Signalis, RE, Obra Dinn, Outer Wilds, Her Story). A companion gap dossier covered Half-Life 2 episodes, BioShock Infinite, The Last Guardian, Ico, Fable II, MGSV, Plague Tale, Brothers and Titanfall 2. The full Stray, Last Guardian/Ico and Brothers/Plague Tale game cards also arrived. These sources overturn the earlier syntheses' "no precedent" findings on drop-on-death, safe rooms, capped inventories, deduction and companion scouting.
- **Still truncated in the input this step received:**
  - The **audio** synthesis stops partway through its recommendations, so its principles and targets are complete but its later recommendations are missing.
  - The **companion gap dossier** stops in its source list, so only its summary paragraph is usable.
  - The **critic's weak-claims list** is cut off.
  - The **game cards** stop partway through Brothers/Plague Tale. No cards arrived for Somerville/Another World/Flashback, Unravel/Gris, mobile ports, robot/dog companions or Dead Space/Silent Hill 2.
- **Still not covered by any input:**
  - Camera look-ahead values (Itay Keren's GDC 2015 "Scroll Back", GMTK).
  - Touch target sizes.
  - Procedural-audio technique sources.
  - Flip-screen-to-scroll lessons (New 'n' Tasty, Flashback remake).
  - Dead Space's ALIVE breathing system.

  Anything below that depends on these is marked as a gap.
- The first gap dossier reported that an earlier run hit a usage limit, and that the "18 dossiers, ~445 sources, 168 corrections" counts could not be checked on disk. Those counts are **UNVERIFIED**.

**What a further re-run should fix:** the full audio synthesis, the full companion gap dossier, the full critic output, the missing game cards (Somerville/Flashback, Oddworld card, Unravel/Gris, mobile ports), and a dedicated camera look-ahead and touch-layout pass.

---

## 1. Current state (checked in code, 2026-10-10)

| Item | Value | File |
|---|---|---|
| Room width | `ROOM_WIDTH = 960.0` (global const) | `room_depth.gd:15` |
| Play zoom / visible width | `GAMEPLAY_ZOOM = 1.35`, view = 960/1.35 ≈ **711 px** | `main.gd:184-185` |
| Camera | centred on the engineer, smoothing 4.0, no look-ahead, clamp hard-coded to 960 | `main.gd` ~392-401 (synthesis reading) |
| Engineer walk | `WALK_SPEED = 190` px/s → current room ≈ 5.05 s to cross | `m0_actor.gd:11` |
| WOLF follow | `FOLLOW_GAP = 64`, `FOLLOW_SPEED = 220` | `m0_actor.gd:12-13` |
| Sentry | `SIGHT_RANGE = 180`, `PATROL_SPEED = 140`, `CHASE_SPEED = 230`, `LOSE_SECONDS = 2.5` | `sentry_brain.gd` |
| Sentry visible beam | `BEAM_LENGTH = 34`, fading to 0 alpha | `sentry.gd:32` |
| Tank drop | `HIT_RANGE = 44`, `FALL_SECONDS = 0.45` → ~0.63 s window vs patrol, ~0.38 s vs chase (derived) | `drop_arm.gd` |
| Knockdown | hit-stop 0.06 s, controls off `0.7`, fade `0.4`, fade-in 0.35 → **~1.45 s** to control | `main.gd:21-22, ~1732` |
| Saves | autosave A on entering the Junction, B when the door is blown; manual SAFE POINT plays WOLF's memory callback; a knockdown never touches Memory/Records flags | `main.gd`, `m0_state.gd` (synthesis reading) |
| Evidence | booleans `purge_trace_preserved`, `mirror_trace_preserved`; Records exit opens "once the first copy is secured"; no CASE UI | `m0_state.gd` |
| Audio | 12 procedural clips (mono, 22.05 kHz, -6 dB peak), 4 shared one-shot voices, 4 loops (hiss, hum, servo, winch), buses Master/Music/Effects/Voice; no footsteps, room tone, breathing or music | `sfx_bank.gd` (synthesis reading) |

---

## 2. Companion design (WOLF)

### Principles

1. **WOLF is never a second player.** Planet of Lana ruled out co-op because "that magic really disappears as soon as another human being takes control over her" (developer commentary; **UNVERIFIED**, captions could not be re-pulled). For LN2, the publisher's producer Lucas Roussel (Bandai Namco Europe, not Tarsier) said co-op was "discarded" and "players are never fully in charge of Six' destiny". Tarsier cut a whistle mechanic for herding enemies (Compher via Push Square). Asobo cut "Do this, go here, grab that" commands because they made Hugo feel "too much like a robot", and kept two verbs (Plague Tale card).
2. **Moment-to-moment reliability earns praise. Drama belongs in authored beats.** LN2 reviews: "you'll never feel like you're fighting the underlying code" (Push Square), "an unusually reliable companion" (PSLS). The negatives are all about latency: Six "would take too long to take a cue/get into position" (Shacknews). Critics said Trico's realism "hampered the gameplay causing impatience and frustration due to lack of immediate action by Trico when giving commands", and Sony skipped a live E3 demo because the AI "could be sporadic" (Wikipedia, citing previews). Ueda set the limit himself: if you can't control it at all, "it becomes a nuisance, a barrier to progression" (companion gap dossier summary; quote as relayed).
3. **Spend the budget on expression, not cognition.** Trico's animation director Tanaka: the AI "was not as technically elaborate as to allow for it to have its own will. Instead, we expressed its will with animations, staging". Trico chooses an object by interest level, walks to it, then picks an action based on the space available (Famitsu CEDEC 2017). INSIDE's Huddle: "every impulse is just a vote", tuned "by observing the expression of the total system"; on adding rough stick arms, "It does not take much to completely change the perception."
4. **Asymmetric bodies build both the puzzles and the bond.** Mui fits through tunnels, bites rope and is "afraid of water". Lana swims and moves boxes. Puzzles are "built around what Lana can do and what Mui can do and what they can do together and separately" (commentary, **UNVERIFIED**). LN2: Six boosts Mono and carries the second item. Ueda framed the boy, Trico and the guards as "a game of rock-paper-scissors that changes throughout the game".
5. **Keep the verb set tiny and let it grow with the relationship.** Lana uses one button for two verbs (tap B = stay, hold B = follow), and pointing unlocks only after the bond forms. Trico has no commands until the first bond; R1 tap = call, R1 + face button = praise/scold/jump (TLG card). Fable II's dog had no command button. Its barks signalled how important something was, and its job was to "lead you off the breadcrumb trail" (Molyneux, via the companion gap dossier summary).
6. **Scouting and leading have shipped precedent.** This replaces the earlier "evidence gap" finding.
   - The Last Guardian: "new areas can be discovered by letting Trico wander independently", and "the boy learns to command Trico to leap onto ledges or head in a certain direction" (Wikipedia).
   - Alien: Isolation uses two brains: "while the director always knows where you are, the alien has to figure it out for itself". Its behaviour tree has "over 100 nodes" with parts "locked off" at the start (Tommy Thompson, Game Developer).
   - MGSV's D-Dog marks enemies automatically. The marking range grows with the bond (60 m to 120 m per a strategy guide; guide data, **not primary**), and its marks are temporary until the player confirms them.
   - BioShock Infinite's Elizabeth stays "goal-side", teleports out of sight, and uses an "icon spotlight" for callouts (GamesBeat report of Abercrombie's GDC 2014 talk).
   - Valve's commentary documents changing Alyx from leading to following, her run speed, and that nagging made players resent her quickly (dossier summary; the exact node wording did not reach this step).
7. **Attachment comes from constant small idle business plus a two-way voice.** Mui's pre-jump "butt wiggle" (RPS), "you can pet Mui at any time" (GamesRadar). Eriksson: "we decided that we needed one more layer of emotional expression" (Game Developer). Ico left Yorda's language untranslated to protect the hand-holding bond.
8. **Putting the companion at risk by choice creates feeling, and remembering it pays that off.** Players "feel a bit bad about using her as bait... that's exactly what we want" (Lana commentary, **UNVERIFIED**). LN's hugged Nomes gather in the ending (12 hugged, the 13th eaten). The INSIDE Huddle shader fades in bruises from 9 of 26 rigidbodies.
9. **Never make the companion the fail state or the only key.** Ico ends the game if Yorda is engulfed. WOLF must not copy that. Stray's B-12 carries the inventory and the Defluxor. Kotaku called B-12's ending "a completely meaningless ignoble sacrifice", and reception said he overshadowed the protagonist's agency. Plague Tale: a left-behind Hugo "will panic, he will shout, he will call for Amicia, and that will probably attract guards". That is absence made loud and diegetic, not a game over.
10. **Off-camera state needs sound plus a minimal locator.** Lana shows an icon only when separated, giving direction and "if she is sitting or moving towards you" (Xbox Wire). LN: "the breathing helps to indicate their presence".

### Measurable targets

| Metric | Target | Basis |
|---|---|---|
| Input to WOLF acknowledgement | Immediate (same beat). The decision animation follows. | Trico and Six latency criticism. **No source gives seconds.** The earlier "0.5 s" figure comes from Limbo's hand-placement look-ahead and does not transfer; treat it as a value to tune by play. |
| Hard abilities per room | ≥1 WOLF-only, ≥1 engineer-only | Lana, LN2, Asobo designing every room with and without powers |
| Player-to-WOLF verbs | The existing 2 choice buttons plus context. Any new verb overloads tap vs hold. | Lana B tap/hold; Plague Tale's 2 commands; Trico's R1 modifiers |
| Off-screen WOLF | Every state (waiting, coming, scouting, refusing) has a sound, plus an edge cue only while he is out of frame | Lana's separated-only icon |
| Visible contact before effect | 100% of WOLF-caused world changes | INSIDE Huddle |
| WOLF sound density | Readable alongside up to 3 machine sources | Lana "got rid of 80%" of the robot layers |
| Stuck-player fallback | The engineer-only path is visible in the room. A slow idle nudge is a secondary fallback only. | TLG idle hint at ~5 min (TLG card) is missable and slow |

### Now / next / later

- **Now:** an intent-vote brain (Follow, Scout, Lead, Hold/Refuse, Protect) with Trico-style interest targets; head-first look-at (head to the target first, then the neck and body follow); a breathing/servo idle layer; instant acknowledgement then a visible decision; effects gated on contact.
- **Next:**
  - Scouting off-camera, reported by sound and posture. WOLF has director-level knowledge of the room, but should visibly sniff, listen and look before he leads (Alien two-brain).
  - Two halves per room, one only WOLF can do and one only the engineer can do.
  - Record the Service Junction bait choice (`WOLF_BAIT_X`) as a second stable memory, paid off with one authored line or a visible mark.
  - A location-clamped vocal intensity (INSIDE "Useful for indicating proximity to danger").
  - The engineer audibly answers WOLF.
- **Later:**
  - Unlock any "request" verb as a relationship beat, framed as something WOLF may decline.
  - A one-time Brothers-style beat where a WOLF channel goes dead.
  - Diegetic mood: optic colour and brightness, ear and tail pose, walk cadence (Trico's eye colour). Never a trust bar.
  - Fresh-tester readability play-tests.

---

## 3. Level design and camera

### Principles

1. **The play camera scrolls; framing is authored.** INSIDE's camera "typically points inwards to the screen and only scrolls". Lana chose a fixed side view because "it's much easier to control the camera framing and stage of each scene". Counter-case: LN2 (publisher's producer) "reworked the camera to offer more top views and in-depth character traversals". Reframe on authored beats only.
2. **Size a room by its content.** "Each Puzzle span around 100 meters or 1-3min of gameplay" (INSIDE Unite 2016). Lana drew criticism for "uneventful running". Its sequel varies pace so intense sequences "land with greater impact" while keeping "space for stillness". Requiem opened up "much wider open areas" but "struggled to keep the narrative rhythm" (Plague Tale card).
3. **Height changes must never ask for precision.** "It's very important that the correct solution is fairly easy to execute" (Carlsen). Lana "can't jump up to them if she's too close" (RPS). Stray only lets you jump where a prompt shows, and every jump lands. Critics still disliked Stray "refusing to let you jump on barrels and boxes" that looked climbable.
4. **One readable plane, grounded characters.** LN's shallow Z: "you'll inevitably misjudge your position and perish" (Push Square LN1). For LN2, "The small Z-axis means it's really easy to get slightly the wrong angle when jumping" (PSLS, corrected attribution). INSIDE puts shadow decals "Anchored to boy's feet".
5. **Teach and steer by placement; show the goal first.** Carlsen's rules come via Game Developer's report (paraphrased). INSIDE's fog clamp lets lights read through haze.
6. **Transitions are seamless.** INSIDE's goals were "without loading screens" and "No visual artifacts caused by streaming in content", with "Only reload 'dirty' Gameplay scenes at respawn".
7. **Two readable approaches per wide room.** Plague Tale card: Innocence was "quite narrow, with only one way to approach a situation". Give each room a lit route and a dark route, or an engineer route and a WOLF route, plus one beat that always fires.
8. **Chases end at a hard line the threat cannot cross.** Six "jumps to another balcony beyond the Guests' reach"; gaps "too small" for adults are a recurring visual grammar.
9. **Optional content lives in short detours with varied difficulty.** Lana's shrines run from 41.0% to 6.9% of Steam owners.
10. **Safe points sit at thresholds, not mid-hazard.** Alistair Hope: "in hindsight that perhaps some of the save point locations could be seen to be a little challenging". The Plague Tale card notes that players expect checkpoints at doors.

### Targets

| Metric | Target | Basis |
|---|---|---|
| Room width | 1067 px (1.5 views) to 1422 px (2 views) at zoom 1.35 | Decision plus arithmetic |
| Walk time | 1.5 views ≈ 5.6 s, 2 views ≈ 7.5 s. **No stretch longer than one view (~3.7 s) without a beat.** | Arithmetic. The one-view rule is DERIVED from Lana's criticism; validate by play. |
| Time per room | ~1-3 min including solving | INSIDE |
| Loading screens or fades on the critical path | 0 | INSIDE |
| Fail-able jumps or sweet spots | 0 | Carlsen, Lana, Stray |
| Zoom changes during free movement | 0 (hold 1.35). Reframe only at reveals, choices and cutscenes, using the intro tween pattern (1.8→1.95). | INSIDE, Lana |
| Route screenshot QA | One capture every ~¼ to ½ view on a recorded route, desktop and touch, diffed | INSIDE: "every 5 meters", ~1300 locations. The spacing is derived. |
| Optional detour find rates | Easiest ~40%, hardest <10% | Lana shrines (owner-based) |

### Now / next / later

- **Now:** per-room width wired into the clamp, plates and dust bounds; beat-per-view paper plans; walkable or whole-zone height changes with contact shadows; walk-through doorways; separate immutable environment/backdrop from mutable gameplay.
- **Next:** the room's goal shown as a fog-cutting light visible from the entrance; dark, low-detail foreground silhouettes that never cross characters, interactables or touch buttons; off-screen WOLF cues; a chase design where a 230 px/s sentry can't catch an engineer who reacts on first sight before the hard line; a look-ahead prototype.
- **Later:** optional evidence detours hung off the height change; a route-replay screenshot sweep.
- **Gap:** no input gives camera look-ahead values. Itay Keren's GDC 2015 talk and GMTK were requested but never arrived. Prototype any look-ahead against the centred follow, and accept it only after play on desktop, controller and phone. With a 180 px sight range against a ~356 px half-view, look-ahead is plausible but unproven.

---

## 4. Death, checkpoints and safe points

The earlier syntheses said "no precedent" for the decided rule (dying drops unsecured evidence; safe points secure it). The gap dossiers show that was a truncation artefact. The precedents are below, with the limits that matter for a short, story-led game.

### Precedents for the decided rule

| Game | What is lost | Recovery | Second death | Notes |
|---|---|---|---|---|
| **Hollow Knight** | All carried Geo; SOUL capped at 66 while the Shade lives | Kill the Shade at the death spot, which is marked on the map | "a new Shade appears... and the old one disappears... all the Geo carried by the previous Shade is lost" | A boss death puts the Shade "in a safe location to be recoverable without triggering the boss battle". Jiji summons it for a Rancid Egg. 50 benches; some cost 50 or 150 Geo. Pellen: the idea came from the death animation ("his head falling to the ground and cracking") (Game Informer 2018). |
| **Silksong** | Rosaries and Silk spool extensions (Silk capped at 9) | Break the Cocoon (one hit; it doesn't fight back); a Silkeater retrieves it remotely | Replaced; old Rosaries lost | A gentler later version |
| **Dark Souls** | Souls and humanity | Reach the bloodstain | Lost permanently | Miyazaki: bonfires are "rare places of warmth" |
| **Celeste** | Carried strawberries | None needed: on death the berry flies back to where it was found | N/A | Closest model. The berry is secured only after >0.15 s on safe ground (derived from the unofficial decompile; read for timings only). `Leader.LoseFollowers()` on `Die()` (official Player.cs). |
| **Outer Wilds** | Everything except knowledge | The ship log persists | N/A | "Nothing is brought back... with the exception of the data on the spacecraft's computer" |

### Precedents for the safe point

- **Alien: Isolation:** to save, the player must "locate a terminal in the world, put in your access card, wait for the systems in the fictional machine to warm up, and then wait for the three simple lights to blink off -- all the while knowing that you could be killed at any moment" (Gary Napper, Game Developer). Wikipedia: a "three second pause". The team rejected checkpoints because a live alien makes them either an "infinite loop of dying and respawning" or makes "sprinting to a checkpoint... a valid tactic". Playtesters were "bouncing their knees". Hope: "Saving becomes part of the fabric of the horror". **Counterpoint, Thomas Grip:** save stations "become the biggest objective for you as a player", and being "20 minutes from your last save" turns tension into "anger and frustration".
- **RE / Signalis / The Bunker:** safe rooms pair a save with shared storage. RE2 (2019) safe rooms "cannot be entered by enemies" (Wikipedia, marked citation needed), and its Save Room track "doesn't loop" (wiki). Signalis allows saving only in safe rooms with a storage chest, and The Verge calls them "less punishing". The Bunker's lamp "will light up" when used; on Normal and Hard there are only 2 lamps.
- **Scarcity as difficulty:** ink ribbons only in RE2R Hardcore; Dark Descent Hard Mode charges 4 tinderboxes per save; The Bunker added fuel-cost and no-save modes later.
- **Too sparse:** Abe's Oddysee's checkpoint-only saving was the main complaint. Exoddus added QuikSave, and New 'n' Tasty capped replay at 3 screens (**UNVERIFIED**, Wikipedia citing a podcast that was not fetched).
- **Death as story:** Ian Thomas (Frictional): "game death is pretty dull. It becomes much more interesting when it's a part of a mechanic or of the story." This supports making death cost something.

### Principles

1. Death must be readable before it happens. Everyone dies: Lana's Flawless is 2.4% of owners, about 6.5% of finishers.
2. Respawn should feel like no time passed (INSIDE scene change).
3. A drop the player can recover keeps death informative. A drop that destroys things on a second death is the Souls-style punishment, and it breaks the engineer-only guarantee when the evidence is essential.
4. The safe point can be a tension beat (Alien) or a sanctuary (RE). It cannot be both at once; choose per safe point.
5. Don't let safe points become the goal (Grip). Evidence and WOLF scenes are the goal; safe points are punctuation.

### Targets

| Metric | Target | Basis |
|---|---|---|
| Replay per death | ≲20 s; ≤1 beat; hard cap <5 min | HG101 reviewer estimate (not measured); INSIDE chunks; FGDB definition |
| Death to control | ≤ today's ~1.45 s; optional USE-skip of the flourish | Current code. Celeste is ~2.0-2.1 s, or ~1.1 s skipped (derived, not footage). The ≤1.45 s figure restates current code, not a shipped benchmark. |
| Audio gap across respawn | 0 (room tone continuous) | INSIDE |
| Restore points per wide room | Autosave at entry plus after each beat | Derived |
| Evidence-securing safe points | At doorways, ≤ ~1-2 rooms apart; never inside a hazard | New 'n' Tasty 3-screen cap (UNVERIFIED); Grip; Hope |
| Secure action | Hold USE ~1-3 s with in-world lights as the real progress; cancellable on touch | Alien 3 s; Celeste 0.15 s dwell. The range is a design choice. |
| Dropped-cache placement | Visible and marked, and outside the trigger of the hazard that killed the engineer | Hollow Knight boss rule |
| Essential evidence destroyed by any number of deaths | 0 | Engineer-only rule; Celeste |

### Now / next / later

- **Now:**
  - Keep the `_fail_beat` timing as a ceiling.
  - Keep room tone and junction loops outside what `_restore_beat` and `_sync_scene` reset. Verify by playing that the knockdown path doesn't cut them.
  - Give each cause of death a distinct reaction and sound.
  - Autosave per beat.
- **Next:**
  - The carried/secured split, with the drop as a visible cache.
  - The secure action as a committed USE-hold with real lights.
  - A non-looping safe-point cue and a faint beacon.
  - Never drop evidence in the first room or for chase and timing deaths with no warning.
  - WOLF may offer to fetch a cache when trust is high (the Jiji/Silkeater idea), and an engineer-only path to it always exists.
  - Public docs and changelog updated in the same change, because today's player-facing copy describes copies as secured the moment they are made.
- **Later:**
  - Quit and backgrounding rules: return to the last autosave with unsecured evidence left as a cache, so quitting is neither an exploit nor a harsher penalty.
  - Optional hard mode with scarce saves.
  - Optional low-death recognition (Limbo "five or fewer deaths").

---

## 5. Inventory and evidence (the CASE)

### Principles

1. **An inventory is a cost that has to earn its place.** Jensen: "I insisted on having very few elements and no inventory" and "inventory crap" (Hanging in Limbo, corrected). Limbo, INSIDE, LN and Lana have none, and Stray's is "deliberately tiny".
2. **Small capped carry plus shared storage is the survival-horror answer.** Signalis: "limited to six items on her person, including weapons, ammunition and key items", with storage in safe rooms. RE1 has 6 slots (Chris) or 8 (Jill). RE2R starts at 8, adds +2 per Hip Pouch, maximum 20 (wiki, unreferenced). RE item boxes share contents across all boxes. Ink ribbons took slots, so saving cost carrying space.
3. **Avoid grids and rotation.** The RE4R Attaché Case needs move/rotate/sort buttons that WOLF's input set (hold-to-move, one USE, two choices, Pause) does not have.
4. **Keep key items separate from records.** Key items are physical and reset with the room (INSIDE dirty-scene reload; LN keys "dropped when you climb or grab"). Records persist (Limbo eggs, INSIDE orbs).
5. **Records pay off best as memory, not a percentage counter.** Stray's 27 memories are B-12's memory; LN's Nomes return in the ending; LN2's 18 Remains unlock a secret ending ("No More Remains" at 5.3% on Steam).
6. **Examine text should under-explain.** Mervik: "That's such a perfect example of not saying too much." Eriksson: "creates more questions than answers."
7. **Deduction and logbooks have precedent (earlier "unsupported" finding withdrawn).** Obra Dinn: 60 souls, "validated only in sets of three", the last six in sets of two. Pope "created spreadsheets to link all the various characters and their fates". Outer Wilds: mysteries "organized either by location or in a web of connections". Her Story: 271 clips, keyword search, player tags.
8. **The one tool should buy time, not power.** Mono's flashlight stuns briefly. Roussel: melee kept weak "to avoid the player feeling too much empowered". Alien: tool use "increases the chance of the Alien finding the player". Stray's Defluxor is time-limited and lives on B-12.
9. **Touch and controller interaction should be physical and short, and never auto-completed.** INSIDE iOS: "Tried auto-complete... loses feeling of interaction". Lana mobile patch 1.0.5 fixed "button disappearance during environmental interactions". Hold criticism: "Hand cramp is a real issue" (PSLS, LN2).

### Targets

| Metric | Target | Basis |
|---|---|---|
| CASE slots | Fixed list, ≤ ~6 including key items, plus 1 tool. No grid. | Signalis 6, RE1 6/8. Exact count is Nathanial's call. |
| Unsecured essential items at once | 1-2 | Derived from the no-inventory references and the LN2 second item |
| Optional records | ~2-4 per chapter, ≤1 per room | Derived from Lana, LN, LN2 and Stray counts |
| Find-rate spread | ~40% easiest, ~7-10% hardest; essentials 100% | Lana shrines |
| Secured records lost on death | 0 | All references |
| Sustained holds to open or examine | None; tap from Pause | LN2 and Lana hold criticism |
| Deduction (if built) | Confirm in batches, so brute force fails; a design spreadsheet proves each conclusion is reachable on the engineer-only path | Obra Dinn |

### Now / next / later

- **Now:** the three record states; a pause-only CASE list with a painted thumbnail and one to two lines of text per item; a diegetic "unsecured" light on the engineer's case; short, non-auto-completed copy actions with world-anchored prompts.
- **Next:** the CASE stays with the engineer, and WOLF optionally carries a duplicate; the one tool designed as stun, jam or reveal, noisy enough for the sentry to hear; optional records in height-change or WOLF-scouting detours.
- **Later:** an end-game memory payoff from secured records and WOLF's treatment; a deduction or link-web view only if wanted, prototyped grey-box with Obra Dinn-style batch confirmation.

---

## 6. Action and impact

### Principles

1. **Impact is mostly sound and animation state.** No reference documents hit-stop, shake or flash values. INSIDE fires sounds from an Effect State ("Set land impact parameter to 70, Play land sound"). "Turn it Down 90%" is a Playdead talk title; **only the title was seen**.
2. **Every lethal event reads before it kills.** LN2: "Instant death is a frequent recurrence and never ceases to be frustrating, especially during chase sequences" (PSLS). Lana: "insta-fail stealth grates" (Push Square).
3. **The threat announces its state change on its own channel.** Lilja's stems, the listening duck and the most-aggressive-enemy rule.
4. **Chases are short sprints with a hard end and a release.** Lana's beach run past the collector legs had no music (Furukawa; corrected from "desert"); Limbo has a survival stinger.
5. **Weak, costly action.** A miss should cost time, not a life. LN2's "if you miss it's instant death" was its most criticised point.
6. **Menace needs release.** Alien's director sends the alien "backstage" after peaks ("we need to give players a break after a while").
7. **Shorten timing actions on touch; never auto-complete them.** INSIDE iOS named "Sentry gun in city, Sentry gun in sewers" as the hardest touch spots.

### Targets

| Metric | Target | Basis |
|---|---|---|
| Lethal events with a tell before contact | 100%; fresh testers can name what killed them | Carlsen, Lilja, LN2 |
| Sentry visible tell vs real sight | Equal (today 34 px vs 180 px ≈ 19%) | Code; Lilja |
| Tank-drop window | ≥ today's ~0.63 s in the patrol case; the ~0.38 s chase case is not touch-ready until it has been played on a phone | Code (derived); INSIDE iOS |
| Full-strength shake/hit-stop uses | Counted per room and reserved for climaxes; the values themselves are untested by research | No reference values |
| Threat layers | Each threat readable with 3 audible at once | Lana's 80% cut |

### Now / next / later

- **Now:** a lock-on alert state; the beam matched to the real sight range; the rubble line made a visible, audible hard end; a phone play-test of the tank drop; an impact budget with shake and flash toggles.
- **Next:** threat state stems plus the listening duck in the ARM PANEL alcove (`COVER_MIN_X..COVER_MAX_X`); a quiet → threat → release structure per room; WOLF reacts within a beat in action and never blocks the engineer; a pressure meter that forces calm after peaks (Alien).
- **Later:** a tool whose miss costs time, with a visible wind-up; an optional heartbeat rumble; a skip or simplify option for timing set pieces.

---

## 7. Presentation, UI and art direction

### Principles

1. **Depth from fog, value and silhouettes.** INSIDE: "Many of the initial scenes in the game were literally just fog + silhouettes"; "Simple linear fog!" clamped so bright lights "bleed through"; "you hardly notice the parallax or depth after a certain point". Lana's black foreground silhouettes give "the feeling of looking into a set-piece or theater stage".
2. **Characters contrast with the world.** Six is "stark colour, small frame, and clean, simple shapes" (Mervik). Lana's costume was redone to "pop more". INSIDE's "fake ambient color, that's always there" plus a depth-edge rim light.
3. **Ground everything.** Shadow decals, AO decals, Lana's hidden shadow planes.
4. **State lives on animation, light and sound; UI appears only when actionable.** Lilja: "There's no graphical user interface at all in Little Nightmares". Lana's prompt "will automatically appear above it". Stray shows the USE prompt on the cat's harness with "a small beep-sound" because "you don't always have visibility on the Cat".
5. **One guiding painting; keep it grounded.** Lana's 2017 painting "has been our guiding star". Chan: too-alien trees "didn't quite work".
6. **Weight lives in additive layers, never in input latency.** INSIDE's breathe and look-around layers; Huddle legs driven by velocity "so the feet will not slide". Against: Lana "noticeably floaty" (RPS), "animation fidelity over fluidity" (Push Square). Wishfully dropped grid movement after publisher feedback.
7. **The world remembers.** The Huddle damage shader; the Nomes.
8. **Restraint.** INSIDE split its fog and glow passes because they "interfered too much".
9. **Phones fail on darkness and thumbs first.** INSIDE iOS fitted a brightness curve, yet iMore still found the image "so dark that I can't tell whether there is something to interact with". AppUnwrapper: thumbs "Covering up any element of the screen".
10. **Subtracting design can go too far.** Ueda later said Ico's subtraction "may have taken too much out of the game" and hurt screenshots (Wikipedia). Key art should show the CASE, WOLF's state or the choice buttons.
11. **Comfort check on large screens.** At full screen, Obra Dinn's dither caused motion sickness until Pope changed the rendering.

### Targets

| Metric | Target | Basis |
|---|---|---|
| Persistent HUD | 0; prompts only in USE range; WOLF cue only when off-screen | Limbo, INSIDE, LN, Stray, Lana |
| Contact shadows | 100% of characters on every walkable surface | INSIDE, LN |
| Darkest-area visibility | The engineer and WOLF stay distinguishable on a phone at default brightness (checked by screenshot) | INSIDE, iMore. No numeric ratio is sourced. |
| Foot slide | 0 (playback speed = velocity / stride speed) | Huddle |
| Banding | None in fog and gradients (blue-noise/TPDF dither) | INSIDE: "Spectacularly easy to add" |
| Flipbook repeats | Never the same frame twice in a row | INSIDE: random selection gives "an 11% chance of hitting the same one twice" |
| Shake and flash toggles | Present before the first public build | FGDB; Windows Central on Lana's launch |

### Now / next / later

- **Now:** 3-4 value bands with a fog clamp; contact shadow, ambient floor and rim light; a written contrast rule (engineer and WOLF get an accent the station never uses; threats are dense dark silhouettes); impact-kit audit and toggles.
- **Next:** world-anchored contextual UI; the CASE kept diegetic and pause-only; additive weight layers; WOLF's idle and deciding body language; a distinct light key per room, with the safe point as a warm "secured" light state; dithering.
- **Later:** WOLF's memory shown as wear and posture; a phone pass (brightness calibration, controls placed away from interactables, buttons that never vanish); a quiet, live title view kept away from gameplay; a parallax comfort check on large screens.

---

## 8. Audio

(The audio synthesis's recommendations arrived cut off. Principles and targets are complete.)

### Principles

1. **Room tone is the default soundtrack; music is placed by hand.** Limbo has "only six tracks" (HG101). Lana's score was spotted "as would be done in the case of films", and "the world of Novo would be very quiet" (Furukawa).
2. **Footsteps are a speed-keyed, per-surface system.** INSIDE bands: idle <0.07, sneak <0.37, walk <0.70, jog <0.92, run <1.30, sprint ≥1.30 (engine units), with "brake" and "takeoff_mf" transitions and a decaying wetness value. Stray recorded 28 surfaces. Lana: "Foley was one element that we could keep as extremely realistic".
3. **Repeated steps fade, then recover.** Limbo: "about 15dB in total, without taking distance based attenuation and active mixing into account". Andersen did not normalise his sounds. Note that WOLF's bank normalises every clip to -6 dB, which works against this.
4. **Small protagonist sounds against heavy beds.** "Just the simple fact that Six is barefoot adds a lot to the feeling of being small and vulnerable" (Lilja).
5. **Breathing is a sequencer that drives animation.** "Continuous sequencing results in natural, uneven breathing pattern"; "Voice intensity = lowpass filtered exhaustion"; 1 breath per 2 steps when running; held on a jump; on landing, "soft impact: normal exhale, hard impact: grunt".
6. **Threat state as stems, plus the listening duck.** Stems "just keep looping" with no tempo sync. In the listening state "all background sounds and music are quickly pulled down to a minimum".
7. **Hazards are heard before they are seen,** silenced once passed, and survival is marked with a sound.
8. **Sounds carry through walls and identify the threat.** The Chef's coughs and the Janitor's keys.
9. **Stillness reveals more sound.** Lana: "if the player stays still (doesn't move at all), they'll start to hear new sounds", at the cost of "double the amount of ambiences".
10. **Clarity over density.** Lana's "got rid of 80%"; audio puzzles changed to clean pipe-organ tones after QA.
11. **Respawn never breaks audio.** INSIDE raised its buffer from 512 to 1024 samples to stop glitches.
12. **Fire sounds from character state changes.** INSIDE's Effect Analyzer; LN creak loops up to 30 s modulated by door speed.
13. **The companion answers and the protagonist answers back.** Mui's voice was performed by Ameglio and pitch-shifted.
14. **Positioned emitters, not stereo loops, in wide rooms.** Stray scans each room and spawns independent positioned sources plus "moving bursts of debris".
15. **Verify platform audio early.** Lilja's regret about not researching platform audio APIs early. Stray: "starting an audio file at an arbitrary point was not simply possible on some platforms" cost a month. Safe-room cues: RE2 (2019)'s non-looping Save Room track; Alien stations' "faint and distinct beeping".

### Targets

| Metric | Target | Basis |
|---|---|---|
| Footstep speed bands | ≥3 plus takeoff and brake sounds | INSIDE 6 bands; 3 is derived |
| Adaptive attenuation | Up to ~15 dB | Limbo |
| Surfaces | 1 per floor material actually used; 28 is a ceiling | Stray |
| Running breath:step | 1:2, eased into phase | INSIDE |
| Respawn audio gap | 0 ms | INSIDE |
| Music | Only at authored beats; ≤1 cue per room, often none | Limbo, Lana (cap derived) |
| Listening duck | Fast drop to near-floor; dB and timing UNVERIFIED, tune on device | Lilja |
| Voices | Footsteps and breathing on their own players, never taking the 4 shared Effects voices | Code reading |

### Gaps

- No speaker-specific mix targets for laptops or phones in any input.
- No primary source for procedural-audio technique (e.g. Farnell, or Paul Weir on No Man's Sky). The critic requested these; they never arrived.

---

## 9. Mobile and input notes

- **Touch:** all fingers combine, and opposite swipes cancel. Resting a thumb on screen is allowed. "Swipe toward the object" triggers USE only for objects that block movement (INSIDE iOS).
- **Invisible d-pad:** Limbo iOS's boy "just stop moving mid-jog" (Game Informer). Visible, anchored controls are safer.
- **Inputs:** acknowledge every input instantly; a missed tap must not look like WOLF refusing (gap dossier inference from Trico's critics).
- **Holds:** hold-to-toggle for long holds; QTE and timing set pieces switchable (Lana shipped only that toggle and was criticised).
- **Thermals:** INSIDE's first iOS build ran ~30 fps, and the iPhone X hit 60 only by overheating. Profile on a cool device over long sessions.
- **Celeste-style skip:** USE skips the death flourish.
- **Gap:** touch target sizes, zone layouts and session-length data were not supplied.

---

## 10. Where the research argues against a current decision

1. **Evidence drop on death.** Now **conditionally supported**, no longer contradicted. Precedent: Hollow Knight, Dark Souls, Silksong, Celeste. Frictional's Ian Thomas argues for death that matters. Risks:
   - Everyone dies (Lana Flawless 2.4% of owners).
   - Free instant deaths were still called frustrating in LN2 and Lana.
   - Hollow Knight's double-loss rule would break the engineer-only guarantee for essential evidence.

   It is safe only with: a short unsecured window (~1 room), a visible and recoverable cache outside the hazard, no destruction of essential evidence, near-instant respawn, and readable hazards.
2. **Evidence CASE.** Limbo's director refused an inventory; Playdead, Tarsier and Wishfully shipped none. Survival horror (Signalis, RE) supports a small capped CASE. The research supports a small, pause-only, gridless CASE, not a full inventory.
3. **Frequent WOLF refusal.** The research does not argue against refusal itself. It argues refusals should be rare, telegraphed and fast. Reviewer praise goes to reliable companions, and the strongest companion complaint across the corpus is latency read as disobedience (Trico, Six).
4. **Command-style verbs.** Lana's stay/follow/pointer and Trico's commands make the companion a command executor. Copy only the input economy (tap vs hold, unlock with the bond) and frame it as a request WOLF may decline.
5. **Zero HUD vs wider rooms plus WOLF routes.** Lana had to add a separated-companion icon, and Ueda regretted subtracting too much. Expect a minimal edge cue; keep it audio-first.
6. **Wider rooms.** No source argues for width in itself. Width is supported only if every view-width carries a beat (Lana's "uneventful running"; Requiem's rhythm problems).
7. **Heavy impact kit vs the "Blowback" action direction.** No reference documents shake or hit-stop. The evidence argues for restraint and toggles, not removal.
8. **Engineer-only fallback vs companion dependence.** Lana's bond partly comes from Mui being required. A fallback that is strictly easier could dilute that. Make it costlier, never punishing (design inference).
9. **2.5D depth on the height change.** Any gameplay depth offset invites LN-style misjudged deaths. Keep play on a single plane.
10. **Current sentry code** (instant chase at 230 > 190 px/s, short beam). Not a listed decision, but under an evidence-drop rule it is exactly the unreadable death the research warns against.

---

## 11. Game cards

**Limbo / INSIDE (Playdead).**
- Few elements; the correct solution is easy to execute; teach by placement.
- Deaths cost ~20 s (reviewer estimate).
- The respawn "scene change" keeps audio running.
- Effect State, footstep matrix and breath sequencer architectures.
- Fog plus silhouettes; foot shadow decals; fake ambient plus rim light.
- Huddle vote network and "arm must touch box".
- iOS: no auto-complete; brightness still too dark; screenshot route QA every 5 m.
- Copy the architectures, not the scope (one coder spent three years on Limbo's boy).

**Little Nightmares I/II (Tarsier).**
- Enemy-state stems, listening duck and sounds that carry through walls.
- Chases end at a line the pursuer can't cross.
- Six is reliable, and her betrayal is story, not jank.
- Shallow-Z depth deaths and long trigger holds are the warnings.
- Hugged Nomes are a cheap memory payoff.
- Co-op and the whistle verb were both cut.

**Planet of Lana (Wishfully).**
- Tap/hold companion verbs; the pointer unlocks with the bond.
- Off-screen companion icon only when separated.
- Bait guilt, then role reversal (UNVERIFIED commentary).
- Asymmetry (Mui fears water).
- Stand-still ambience; 80% robot layer cut.
- Spotted music; foreground silhouettes.
- Warnings: floaty movement, uneventful running, insta-fail stealth, launching with one accessibility toggle, and a companion who never refuses or remembers.

**Stray (BlueTwelve).**
- The companion explains the player's extra abilities and carries the tool, with a diegetic budget.
- Diegetic USE prompt plus beep.
- Prompt-gated jumps that always land (but make visibly climbable things climbable).
- 28 surfaces; positioned room-tone emitters.
- Memories double as the companion's memory.
- Warnings: an ending that overshadows the protagonist; save hitches (~120 ms, UNVERIFIED); no official mobile build.

**The Last Guardian / Ico (genDESIGN / Team Ico).**
- Interest → move → act mind; expression over cognition.
- Head-first look-at; refusal shown physically (pawing at the edge).
- Commands gated by the bond; eye colour as mood.
- Wandering that finds routes.
- Warnings: latency read as disobedience; companion-as-game-over (Yorda); subtraction that went too far.

**Brothers / A Plague Tale (Starbreeze / Asobo).**
- Two commands maximum; absence made loud through horror systems.
- Design every room with and without the companion; cap companion power in fiction.
- Track treatment silently and show it as behaviour.
- Use the dead-input trick once.
- Two readable approaches per wide room; safe points at doors.
- (Card truncated.)

**Hollow Knight / Silksong (Team Cherry).**
- The Shade: drop all, temporary SOUL cap, map marker, Shade placed safely after a boss death, paid retrieval.
- Silksong softens it (one-hit Cocoon, remote retrieval).
- Avoid the second-death wipe for essential story evidence.

**Celeste (Maddy Makes Games).**
- The strawberry rule: carried items follow you, are secured after a dwell on safe ground, and return to their origin on death.
- ~2 s death-to-control, skippable to ~1.1 s (derived from code).
- Death counter shown as a badge.
- (Thorson's "Celeste & Forgiveness" returned 403: UNVERIFIED.)

**Dark Souls (FromSoftware).** Bloodstain with one recovery chance; bonfires as warmth and respawn.

**Alien: Isolation (Creative Assembly).**
- Manual 3-second save with live threat and in-world lights as progress.
- Two-brain AI; behaviour branches unlock over time; menace gauge sends the alien "backstage".
- Tools make noise.
- Grip's warning about save-hunting and 20-minute gaps.

**Resident Evil 1 / 2R / 4R (Capcom).**
- Typewriter and item box; shared storage; safe rooms enemies can't enter; non-looping save-room music.
- Ink ribbons only in Hardcore.
- RE4R grid needs too many buttons for WOLF.

**Signalis (rose-engine).** 6-item carry; safe rooms with storage; "less punishing".

**Amnesia: The Bunker / Dark Descent (Frictional).**
- Save lamp that lights up; 2 lamps on Normal and Hard; fuel-cost save modes.
- Hard Mode costs 4 tinderboxes per save.
- "game death is pretty dull" unless it is mechanic or story.

**Oddworld (Abe's Oddysee / Exoddus / New 'n' Tasty).** Sparse checkpoints were the top complaint; QuikSave plus a 3-screen replay cap (UNVERIFIED) fixed it.

**Return of the Obra Dinn / Outer Wilds / Her Story.** Batch-validated deduction; a design spreadsheet proving each conclusion is reachable; the ship log as a web; knowledge that persists through death; minimal database search.

**Half-Life 2 Episodes / BioShock Infinite / Fable II / MGSV (summary-level only; full dossier truncated).**
- Alyx moved from leading to following; nag lines turned players against her.
- Elizabeth stays goal-side, teleports while unseen, uses an icon spotlight.
- Fable II's dog has no command button, barks signal importance, and "lead[s] you off the breadcrumb trail".
- D-Dog's marking grows with the bond, and marks stay temporary until confirmed.

---

## 12. Measurable targets at a glance

| Area | Target |
|---|---|
| Room | 1067-1422 px; ≤3.7 s of walking without a beat; 1-3 min per room |
| Height change | 0 fail-able jumps; single plane; contact shadows |
| Camera | Zoom 1.35 fixed during movement; look-ahead untested |
| Death | ≲20 s replay; ≤1.45 s to control; 0 ms audio gap; 0 essential evidence destroyed |
| Safe point | At doorways, ≤ ~1-2 rooms apart; ~1-3 s committed USE-hold |
| CASE | ≤ ~6 fixed slots plus 1 tool; 1-2 unsecured essentials; no grid; pause-only |
| WOLF | Instant acknowledgement; ≥1 WOLF-only and ≥1 engineer-only ability per room; edge cue only when off-screen |
| Sentry | Visible tell = real sight range; alert beat before chase; hard end line |
| Audio | ≥3 step bands; up to ~15 dB fatigue; 1 breath per 2 steps when running; threats readable 3 at a time |
| Presentation | 0 persistent HUD; 0 foot slide; no banding; shake and flash toggles |

---

## 13. Sources (as supplied by the dossiers; "not fetched" means the researcher could not read it)

**Playdead**
- https://gdcvault.com/play/1013665/Limbo-Balancing-Fun-and-Frustration
- https://www.gamedeveloper.com/game-platforms/gdc-europe-i-limbo-i-s-carlsen-on-making-players-your-worst-enemy-and-your-best-friend
- https://www.gamedeveloper.com/business/hanging-in-limbo
- https://www.gamedeveloper.com/business/playdead-s-intense-i-limbo-i-playtesting
- https://www.gamedeveloper.com/game-platforms/road-to-the-igf-i-limbo-i-s-dino-patti
- https://www.engadget.com/2010-08-16-limbo-sells-300k-design-philosophy-discussed-by-playdead.html
- https://blog.playdead.com/articles/inside_presentations/inside_publications.html
- https://blog.playdead.com/articles/limbo_presentations/limbo_publications.html
- https://github.com/playdeadgames/publications/blob/master/INSIDE/schmid-AES_2016-The_Boy_from_INSIDE.pdf
- https://github.com/playdeadgames/publications/blob/master/INSIDE/schmid-Wwise_2016-INSIDE_Audio.pdf
- https://github.com/playdeadgames/publications/blob/master/INSIDE/schmid-ITU_2016-INSIDE_Audio.pdf
- https://github.com/playdeadgames/publications/blob/master/INSIDE/spilbar2019-schmid-adaptive_audio.pdf
- https://github.com/playdeadgames/publications/blob/master/LIMBO/Martin_Stig_andersen_audio_SoundscapeCompositionInLimbo.pdf
- https://github.com/playdeadgames/publications/blob/master/INSIDE/inside_shipping_on_ios.pdf
- https://github.com/playdeadgames/publications/blob/master/INSIDE/rendering_inside_gdc2016.pdf
- https://github.com/playdeadgames/publications/blob/master/INSIDE/Grontved_Huddle%20Up!%20Making.pdf
- https://docs.google.com/presentation/d/1dew0TynVmtQf8OMLEz_YtRxK32a_0SAZU9-vgyMRPlA/edit
- https://github.com/playdeadgames/publications/blob/master/INSIDE/StarfishRig.pdf
- https://docs.google.com/presentation/d/1QN99FZUQl3KE4c7eg9-GLLEl3Og0FqreJbiTrCc8ZAk
- http://www.gdcvault.com/play/1023731/A-Game-That-Listens-The
- https://gdcvault.com/play/1024126/Huddle-up-Making-the-SPOILER
- https://designingsound.org/2011/08/01/limbo-exclusive-interview-with-martin-stig-andersen/
- https://www.killscreen.com/mad-science-behind-insides-soundtrack/
- https://en.wikipedia.org/wiki/Limbo_(video_game)
- https://en.wikipedia.org/wiki/Inside_(video_game)
- https://www.hardcoregaming101.net/limbo/
- https://gameinformer.com/b/features/archive/2013/07/03/limbo-ios-impressions.aspx
- https://www.appunwrapper.com/2017/12/29/playdeads-inside-ios-review/
- https://www.imore.com/playdeads-inside-review-there-beauty-death
- https://www.speedrun.com/inside
- https://www.speedrun.com/limbo
- Not fetched: Audiokinetic blog, Digital Foundry INSIDE Switch, TouchArcade, GameSpot Limbo interview, "Death in Design" (Vimeo), Konsoll 2017 talk.

**Tarsier / Little Nightmares**
- https://thesoundarchitect.co.uk/?p=18494
- https://blog.playstation.com/archive/2016/11/25/the-abandoned-tech-demo-that-become-the-basis-of-upcoming-ps4-adventure-little-nightmares/
- https://blog.playstation.com/archive/2017/04/28/how-deliciously-dark-ps4-adventure-little-nightmares-took-shape
- https://news.xbox.com/en-us/2021/03/12/little-nightmares-2-interview/
- https://www.escapistmagazine.com/little-nightmares-ii-designer-wanted-to-abandon-the-first-games-protagonist/
- https://gameinformer.com/b/features/archive/2017/05/30/little-nightmares-afterwords.aspx
- https://gamingbolt.com/little-nightmares-2-post-launch-interview-dlc-plans-future-ideas-and-more
- https://www.pcgamesn.com/little-nightmares-interview
- https://www.pushsquare.com/news/2017/03/hands_on_little_nightmares_is_primed_for_greatness
- https://www.pushsquare.com/reviews/ps4/little_nightmares
- https://www.pushsquare.com/reviews/ps4/little_nightmares_ii
- https://www.playstationlifestyle.net/review/843676-little-nightmares-2-review/
- https://www.dreadcentral.com/reviews/481257/little-nightmares-ii-review-big-scares-too-2/
- https://www.shacknews.com/article/122653/little-nightmares-2-review-terror-in-the-big-city
- https://steamcommunity.com/stats/424840/achievements
- https://steamcommunity.com/stats/860510/achievements
- https://en.bandainamcoent.eu/node/8904
- Not fetched: Unreal Engine LN2 interview, Twinfinite, Edge, Digital Foundry.

**Planet of Lana**
- https://www.youtube.com/watch?v=DcESS2l4RY4 (commentary; captions re-pull failed, quotes UNVERIFIED)
- https://news.xbox.com/en-us/?p=185820
- https://www.gamedeveloper.com/design/using-narrative-limitations-to-find-an-emotional-core-in-planet-of-lana
- https://www.gamedeveloper.com/business/exploring-the-art-and-animation-behind-hand-painted-odyssey-i-planet-of-lana-i-
- https://www.asoundeffect.com/planet-of-lana-game-audio/
- https://www.gamesindustry.biz/how-planet-of-lana-became-a-hit-through-dogged-determination-after-being-rejected-hundreds-of-times
- https://www.creativebloq.com/3d/video-game-design/why-ghibli-inspired-planet-of-lana-ii-is-working-against-unity-to-achieve-its-unique-2-5d-aesthetic
- https://www.lacedrecords.co/blogs/blog/takeshi-furukawa-bet-big-on-bold-melodies-for-planet-of-lana
- https://thegameslayer.com/features/exclusive-interview-planet-of-lana-ii-devs-talk-returning-to-lanas-world/
- https://steamcommunity.com/stats/1608230/achievements
- https://www.familygamingdatabase.com/accessibility/Planet+of+Lana
- https://windowscentral.com/gaming/xboxs-planet-of-lana-is-beautiful-wondrous-and-a-bit-unfinished
- https://www.rockpapershotgun.com/planet-of-lana-review
- https://www.gamesradar.com/planet-of-lana-review/
- https://www.pushsquare.com/reviews/ps5/planet-of-lana
- https://www.nintendolife.com/reviews/switch-eshop/planet-of-lana
- https://apps.apple.com/us/app/planet-of-lana/id6739130049
- Not fetched: HowLongToBeat, God is a Geek.

**Stray**
- https://www.asoundeffect.com/stray-game-audio/
- https://www.inverse.com/gaming/stray-cat-game-robots-interview
- https://screenrant.com/swann-martin-raget-interview-stray/
- https://www.videogameschronicle.com/features/stray-preview-interview/
- https://blog.playstation.com/2022/07/15/getting-to-know-strays-leading-feline-out-july-19/
- https://questforux.beehiiv.com/p/game-ux-case-study-stray
- https://www.powerpyx.com/stray-all-collectibles-locations-guide/
- https://kotaku.com/stray-ending-explained-b12-bluetwelve-cat-annapurna-1849366887
- https://kotaku.com/stray-cat-ps5-pc-unreal-engine-4-stutter-performance-1849317334
- https://en.wikipedia.org/wiki/Stray_(video_game)
- Not fetched: Unreal Engine "28 people and two cats", Digital Foundry.

**The Last Guardian / Ico**
- https://www.gendesign.co.jp/qa_01/interview01en.html
- https://www.gendesign.co.jp/qa_01/interview04en.html
- https://www.famitsu.com/news/201709/01140918.html
- https://www.gameanim.com/?p=15474
- https://www.gameanim.com/?p=14214
- https://yufeizheng.myblog.arts.ac.uk/2021/12/15/thesis-research-week-8-appendix/
- https://www.intelligent-artifice.com/2004/04/gdc_2004_game_d
- https://gamedeveloper.com/game-platforms/tgs-reawakening-i-the-last-guardian-i-
- https://www.gamedeveloper.com/design/calling-trico-in-the-last-guardian
- https://www.psu.com/news/the-last-guardian-dev-still-finding-a-balance-with-tricos-actions/
- https://www.playstationlifestyle.net/2017/01/19/psls-help-desk-how-to-control-trico-the-last-guardian/
- https://en.wikipedia.org/wiki/The_Last_Guardian
- https://en.wikipedia.org/wiki/Ico
- Not fetched: The Guardian original interview, Digital Foundry, speedrun.com Ico.

**Death and saves gap dossiers**
- https://hollowknight.wiki/w/Shade
- https://hollowknight.wiki/w/Bench_(Hollow_Knight)
- https://hollowknight.wiki/w/Cocoon
- https://www.gameinformer.com/2018/10/16/the-making-of-hollow-knight
- https://en.wikipedia.org/wiki/Hollow_Knight
- https://raw.githubusercontent.com/NoelFB/Celeste/master/Source/Player/Player.cs
- https://github.com/TheCyndaquilDecompilers/Celeste_Decompiled/tree/master/Celeste (unofficial; timings only)
- https://en.wikipedia.org/wiki/Dark_Souls_(video_game)
- https://www.gamedeveloper.com/design/game-design-deep-dive-the-save-system-of-i-alien-isolation-i-
- https://gameinformer.com/b/features/archive/2014/11/14/afterwords-alien-isolation.aspx
- https://www.gamedeveloper.com/design/the-perfect-organism-the-ai-of-alien-isolation
- https://en.wikipedia.org/wiki/Alien:_Isolation
- https://frictionalgames.com/2014-10-thoughts-on-alien-isolation-and-horror-simulation/
- https://frictionalgames.com/2018-02-qa-with-frictional-writer-ian-thomas/
- https://frictionalgames.com/2018-09-what-is-amnesias-hard-mode/
- https://frictionalgames.com/2023-10-amnesia-the-bunker-halloween-update-launch/
- https://frictionalgames.com/2023-07-amnesia-the-bunker-second-update-1-15/
- https://amnesia.fandom.com/wiki/Lamp_(The_Bunker)
- https://www.pcgamer.com/12-takeaways-after-an-hour-with-the-next-amnesia-game-which-contains-exactly-one-gun/
- https://en.wikipedia.org/wiki/Resident_Evil_2_(2019_video_game)
- https://en.wikipedia.org/wiki/Resident_Evil_(1996_video_game)
- https://residentevil.fandom.com/wiki/Ink_Ribbon
- https://residentevil.fandom.com/wiki/Typewriter
- https://residentevil.fandom.com/wiki/Item_Box
- https://residentevil.fandom.com/wiki/Save_Room
- https://residentevil.fandom.com/wiki/Inventory_(RE2_remake)
- https://residentevil.fandom.com/wiki/Inventory_(RE4_remake)
- https://en.wikipedia.org/wiki/Signalis
- https://www.pcgamer.com/signalis-review/
- https://www.theverge.com/23428239/signalis-review-ps4-xbox-switch-pc
- https://en.wikipedia.org/wiki/Oddworld:_Abe%27s_Exoddus
- https://en.wikipedia.org/wiki/Oddworld:_Abe%27s_Oddysee
- https://en.wikipedia.org/wiki/Oddworld:_New_%27n%27_Tasty!
- Not fetched: Thorson's "Celeste & Forgiveness", USgamer Celeste, GameSpot Bunker preview, Bloody Disgusting Signalis interview, Next Generation #41, the Oddworld developer roundtable.

**Inventory and deduction gap dossier**
- https://en.wikipedia.org/wiki/Return_of_the_Obra_Dinn
- https://en.wikipedia.org/wiki/Outer_Wilds
- https://en.wikipedia.org/wiki/Her_Story_(video_game)
- Not fetched: Pope's TIGSource devlog.

**Companion gap dossier (source list truncated in input)**
- https://combineoverwiki.net/wiki/Developer_commentary/Half-Life_2:_Episode_One
- https://combineoverwiki.net/wiki/Developer_commentary/Half-Life_2:_Episode_Two
- https://gdcvault.com/play/1020831/Bringing-BioShock-Infinite-s-Elizabeth (abstract only)
- https://gamesbeat.com/how-soccer-and-theater-helped-irrational-create-bioshock-infinites-elizabeth/
- https://gamingbolt.com/?p=35700
- https://www.straight.com/life/365621/ken-levine-takes-bioshock-sea-sky-infinite
- https://www.nbcnews.com/tech/tech-news/bioshock-infinite-takes-artificial-out-artificial-intelligence-flna1C8884902
- https://en.wikipedia.org/wiki/BioShock_Infinite
- Not fetched: Eurogamer Levine 2012, PC Gamer 2013. The Fable II, MGSV, Plague Tale and Brothers sources did not reach this step.
