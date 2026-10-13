# WOLF//OVERRIDE through a genre fan's eyes

**Lens:** a player who loves INSIDE, LIMBO, Little Nightmares and Stray. I am not an artist or an engineer. I judge what is on screen.
**Material:** the scripted capture at `baffea4` ([CAPTURE-ROUND1.md](../playthrough/CAPTURE-ROUND1.md)). That is 269 desktop frames (1280x720, keyboard) and 226 phone frames (2400x1080, touch). I read the 24 contact sheets first, then about 60 full frames around every beat. File names below are those of the capture's `desktop/frames/` (D-...) and `phone/frames/` (M-...).
**Written:** 2026-10-12, re-checked against the frames on 2026-10-13 (section 12), for Nathanial Henniges, who created WOLF//OVERRIDE and its story. Research credits are at the end.

**Honesty notes**
- I only see stills, taken about 0.08 s after each change and then once a second. Anything I say about motion, animation or timing is a guess, and I mark it **(guess)**.
- The inputs were scripted, and the reading waits come from a formula. The time I spend "stuck" is the driver's time, not a real person's.
- There was no audio. Several of my complaints (the cage, the alarm, "something whirs awake") could be softened by sound. I can't hear it.
- The DEBUG button on the phone frames comes from the debug build, so I ignore it.

**Tags:** **MUST** means a normal player would notice and it hurts. **SHOULD** means it is noticeable or weakening. **FINE** means it works or is good.

---

## The short version

The Service Junction is the best thing here. It has the richest art, an entry hatch and an exit hatch that read as real doors, a fair blast warning, a fast retry (1.1 s from knockdown to control, D-0186 to D-0187), and one great companion moment: WOLF refuses to bait the sentry because you rushed him at the relay (D-0213). That moment is why I'd keep playing.

The first 90 seconds are the problem, and they are the part a demo player judges.

- You get no control for 41 s (first control at t = 40.9 s in both logs). That stretch is seven text boxes over a nearly still shot.
- The first object you see is a cage that looks like flat vector shapes laid over a painting.
- The corridor then shows five UI panels at once. The things you use are a "MANUAL BYPASS" wheel on a stick with a floating label, and a red "seal" door standing free in the middle of the room. When it opens, the door slab vanishes into a dust blob and you walk past it, not through it.

Across all three rooms the same tells break the "real place" feeling:
- Text labels hang over every machine, and in the junction they change state ("VALVE SPENT", "DOOR DOWN", "TANK DOWN") like a debug overlay.
- Smoke, steam and glow are soft blobs with hard edges, and one covers Rowan's head.
- The knocked-down body is the standing sprite turned sideways and floating above the floor.
- Characters stand inside props or inside each other.
- Doors open into the background while the path carries on sideways.

The game's own research already says to drop most of this ("Persistent HUD 0", "contact shadows 100%", walk-through doorways; `docs/research-2026-10/design-reference-25-games.md` §3, §7). The build has not caught up with it yet.

---

## 1. Title screen (D-0003, M-0003, D-0269)

- **FINE.** It is moody and readable. The painted Rowan and WOLF in a wet corridor sell the premise at once. CONTINUE is greyed out with the reason underneath ("No checkpoint yet. Saving starts at the first SAFE POINT."), which is good manners. After the slice, PLAY AGAIN replaces it with a clear note (D-0269).
- **SHOULD.** The title art is a lush painting with a big Rowan. In game, Rowan is a small sprite about 17% of screen height (D-0048). That is fine for this genre, since INSIDE's boy is tiny too, but the jump from painting to the first in-game shot (the flat cage, below) is jarring.
- **SHOULD (phone).** At 20:9 the game is pillarboxed: 240 px of black on each side (M-0003, every M- frame). On a phone that is wasted width right where the thumbs rest.

## 2. Opening: containment (D-0004 to D-0046; M-0004 to M-0046)

**What I think is going on.** A Director in a long coat stands by a cage. He says he decides who counts as a threat and that WOLF handles the rest. WOLF, a robot wolf, wakes up on his own, breaks out, tells the Director "I won't do it", and walks off toward maintenance. I am not playing anyone yet. I press E, or tap CONTINUE, to read on.

- **MUST: 41 seconds with no control.** Seven text boxes (D-0004 to D-0041) over an almost static frame. Six of the twelve 1-second frames from t = 7.8 to 18.8 s look identical (contact sheet `desktop-02-opening-p1`). The genre I love hands you the character within seconds and tells the story through what you do. A faster reader might take 25 s, but it is still all reading. I'd be skimming by the third box. **(guess on the real pace)**
- **MUST: the cage looks fake.** In D-0004, D-0014 and D-0022 it is clean grey rectangles with a slanted lid in a different perspective from the sides, sitting on a painted, grimy wall. It reads as a placeholder box, and it is the first thing anyone sees.
- **SHOULD: the text names things I can't see.**
  - "A blue light answers from inside the containment seal" (D-0014), but I can't find a blue light; WOLF is a dark shape in the cage.
  - "The gate slides aside" (D-0022 to D-0024): the bars bunch into a narrow column at the left, and a beige dust blob covers the cage floor (D-0022).
  - "The Director freezes at the sound": he looks exactly the same as before. **(guess: he may animate)**
- **SHOULD: I don't know who I am.** The engineer isn't in the opening at all. Rowan first appears 41 s in, introduced by a name card ("ROWAN VALE / MAINTENANCE ENGINEER", D-0048) and a 267-character, three-line box. I'd have liked to see Rowan watching from the doorway.
- **SHOULD: WOLF leaves the wrong way.** "WOLF turns from the Director and heads for maintenance" (D-0041 to D-0046), yet he walks left, back into his own open cage, and stands there for 4 s (D-0042 to D-0046). It reads as if he went back in.
- **FINE.** WOLF's design (the angular plated wolf with blue seams) is the strongest character art in the game, and "I heard you. I won't do it." is a good first line for him (D-0031).

## 3. Corridor: breaker, relay, bypass, seal (D-0047 to D-0115; M-0047 to M-0097)

**What I think I'm meant to do.** Read the purge display if I want (it's optional), walk right to the BREAKER, answer WOLF's question about the COOLANT RELAY, arm the breaker, then either let WOLF take the relay or crank the MANUAL BYPASS. That opens the red seal; then I save at the SAFE POINT. The goal is clear, because the game tells me everything in text.

- **MUST: screen clutter at the first moment of control.** D-0048 has a name card, a tutorial box ("A / D MOVE / E READ DISPLAY (optional)"), a hint bar, a three-line dialogue box and the PAUSE button, plus three world labels. That makes eight text elements before I've taken a step. On the phone, add four big touch buttons, and the hint bar runs under the USE button (M-0052).
- **MUST: labels over machines.** "BREAKER", "COOLANT RELAY", "COOLANT FAULT" (an orange box), "MANUAL BYPASS" with an 8-square progress bar, and "SAFE POINT" all float in the air (D-0062, D-0095). LIMBO, INSIDE and Little Nightmares never label the world. Here the labels make the room read like a diagram instead of a place.
- **MUST: the MANUAL BYPASS is a floating wheel.** It is a yellow wheel inside a thin circular ring on a single thin post with a flat slab base, tied to the relay by a hairline (D-0079, D-0095, crop `crops/d095.webp`). It looks like a UI icon stuck on a stick, not a valve plumbed into anything. It is exactly the "hovering item that looks odd" Nathanial asked about.
- **MUST: Rowan cranks without touching it.** At "HOLD E: crank the manual bypass, 4 of 8" (D-0095), Rowan stands beside the wheel with their arms at their sides. At the next stage (D-0101) a yellow smoke smear covers Rowan's head and an orange chevron "M" glyph floats over the wheel (crop `crops/d101.webp`). It looks like a rendering glitch. **(guess: there may be a crank animation between captures, but none of the beat frames from D-0091 to D-0100 shows one)**
- **MUST: the coolant hiss is a hard-edged rectangle.** The pale blue glow beside the relay (D-0092 to D-0101) has a straight left edge and a straight top. It reads as a sticker, not a vapour jet.
- **MUST: the red seal makes no sense as a door.**
  - It is a standalone frame drawn in three-quarter perspective, standing in front of the back wall and a pipe column, with nothing around it (D-0079, D-0095).
  - When it opens, the slab simply disappears and a beige dust cloud sits on the floor (D-0103). Behind the frame is a painted tunnel going *into* the screen (D-0105).
  - Then Rowan walks *across the front* of the opening to the safe point (D-0105, D-0106) and enters Records from the safe point ("E: enter records access", D-0106), never through the door just opened.
  - So where does the door go, and why did it block me if I don't go through it? A player would try to walk into that tunnel.
- **SHOULD: the relay choice comes too early.** WOLF asks "What happens if I touch it live?" with "1 The relay may vent coolant. Your call. / 2 Go now. We can talk after." (D-0062). This is before the breaker is armed and before I know what the relay does or what WOLF's part in it is. I picked an answer on tone, not knowledge. It works as a character test, but I'd want to see the hissing relay first.
- **SHOULD: WOLF taking the surge is shown as a decal.** On the phone route (M-0084), WOLF stands *inside* the relay cabinet's outline, with a cyan cloud and the same chevron "M" glyph used on Rowan's crank. It is the big trust payoff and it looks like a status icon. **(guess on motion)**
- **SHOULD: the hint says "WOLF refused the live contact" (D-0079).** That reads like a system log. WOLF's own line, "I said no. I won't touch it blind." (D-0080), already says it with feeling.
- **SHOULD: no contact shadows.** Rowan has a thin blue selection bar under their feet (D-0048, D-0095), which reads as a cursor. Neither character casts a shadow, so both look pasted on the wet floor, even though the floor has reflections.
- **FINE.** The breaker and relay cabinets are heavy and sit on their bases. The wet floor and the overhead cones of light look good (D-0075). The safe point (a green beacon on a console) is easy to read. "Next time, tell me what it costs." (D-0106) is a good WOLF line.

## 4. Records (D-0116 to D-0164; M-0098 to M-0147)

**What I think I'm meant to do.** Copy the purge order at the red terminal, then copy the mirror index (choosing WOLF's readout or my own port), then leave by the EXIT. Easy to follow.

- **MUST: the exit door changes into a blank rectangle.** First it is a narrow red-lit pod with an "EXIT" label (D-0147). The moment the copy is secured, a see-through grey outline and green puffs appear over it (D-0148), and then it becomes a flat navy box with a grey border and a mint bar at the bottom (D-0157). That looks unfinished. It's the plainest "this is a placeholder" frame in the capture.
- **SHOULD: I arrive from nowhere.** Rowan appears at the far left edge (D-0116) with no door, hatch or opening behind them. The room should show the way I came in.
- **SHOULD: the same terminal again.** The "PURGE QUEUE" console (D-0116) is the same red-screen machine as the corridor's purge display (D-0052). I noticed straight away.
- **SHOULD: using things is just standing near them.** Rowan stands beside the purge console, not at it (D-0120). With WOLF's readout chosen, WOLF stands behind the mirror port and the text says he reads the timestamp off his own readout (M-0121), but nothing on screen shows a readout. WOLF's special ability is never seen.
- **SHOULD: the mirror choice is blind.** "1 USE WOLF'S READOUT / 2 USE MANUAL PORT" (D-0131) gives no hint what either costs. WOLF's readout also tells you the purge target existed before the deletion order (M-0121), while the manual port doesn't (D-0139). That's a real difference I couldn't have guessed.
- **SHOULD: "Checkpoint saved." appears constantly.** It shows as the hint text at 17 different moments on desktop (log count), including three times in this one room (D-0116, D-0120, D-0157). After the second time I stopped reading the hint bar, which is a problem because real instructions also appear there.
- **SHOULD: about 16 s standing at the exit.** From "FIRST COPY SECURED..." (D-0148, t = 121.5) to the room change (t = 138.1), Rowan and WOLF stand still at the exit while I read and press on (`desktop-04-records-p2`). **(guess: a real reader might be faster)**
- **FINE.** The room art (server racks, cross-braced steel, a single cold light) is good and readable. WOLF and Rowan splitting the work ("Take the purge queue. I'll inspect the mirror.", D-0116) is the right companion idea.

## 5. Service Junction: the Blowback beat (D-0165 to D-0263; M-0148 to M-0219)

**What I think I'm meant to do.** Arm the overload breaker by the entrance, crank the valve three turns, and get clear before the sealed door blows. Then deal with the sentry patrolling the lane, by dropping the hanging tank on it when it's on the floor mark, alone or with WOLF as bait. Then pop the exit bolt and leave through the hatch. The text spells this out ("Overload it, crank the valve, and the door goes.", D-0165), so I never felt lost here.

- **FINE: the best-looking room.** Pipes, gauges and hazard stripes are dense and consistent. The entry hatch (round wheel door, left, D-0165) and the exit hatch (D-0222, D-0253) look like real doors set into real walls, and the exit opens onto a tunnel I actually walk toward. The hanging tank on its claw is clear and reads as a threat from the moment you enter (D-0185).
- **FINE: the blast is fair.**
  - WOLF warns you first: "When the door goes, don't be standing in front of it." (D-0167).
  - The striped red floor zone appears when the fuse lights (D-0185).
  - The retry is quick: knockdown at t = 145.8, control again at t = 146.9.
  - You restart only about 3 s of walking back, at the entrance (D-0187).
  - This is the LIMBO-style "you understood why you died" I want.
- **MUST: the labels turn into a debug readout.** Five labels sit over the machines ("OVERLOAD BREAKER / RELIEF VENT / VALVE / SEALED DOOR / TANK RELEASE", D-0165), and they change state as you play: "BREAKER LIVE", "FUSE LIT", "BREAKER SPENT", "VALVE SPENT", "DOOR DOWN", "RELEASE SPENT", "TANK DOWN", "EXIT BOLT", "EXIT OPENING", "EXIT OPEN" (D-0185, D-0186, D-0243, D-0250, D-0253). There is even a small "LINE" tag on the gauge. It looks like a developer overlay was left on, and it does the player's looking for them.
- **MUST: the knocked-down body floats.** Both knockdowns show Rowan's standing sprite turned onto its side, hovering roughly at waist height (D-0186, D-0226, M-0169). No one would read that as a body on the floor. It's the one image a streamer would clip and laugh at.
- **MUST: the blown door is a doorway into the background, but the route goes sideways.** Like the corridor seal, the sealed door is a three-quarter-perspective frame. After the blast it shows a lit tunnel going into the screen (D-0205, D-0213). Yet the way on is to the *right*, along the front, past it. I would walk up to that tunnel and press USE. "Why did I blow this door?" has no visual answer, because it was never in my way on screen.
- **MUST: the text names things that aren't drawn.** "Get back over the rubble", "WOLF heads for the rubble", "the alcove just inside", "past the alcove's right post", "Keep inside the posts" (D-0203, D-0224, D-0226). I can find no rubble pile you'd climb (just a few glowing shards by the door frame, D-0213) and no alcove (just a see-through cyan rectangle on the floor with two thin uprights, D-0222). I died once because "inside the posts" meant that faint rectangle (D-0226). The yellow-and-black dashed bracket for the drop mark is clearer, though "brackets" (D-0240) still took me a second.
- **SHOULD: the effects are blobs.**
  - The door blast is a flat beige cloud with yellow dots (D-0186, D-0200, M-0169).
  - The tank impact is a perfectly round cyan glow ball (D-0243, M-0202).
  - The bolt pop is a teal puff (D-0250).
  - In motion they may read better **(guess)**, but in every still they look like soft stickers on top of a detailed painting.
- **SHOULD: things pass through each other.**
  - WOLF stands merged into the valve and the blown door frame (D-0213, D-0240).
  - Rowan stands inside WOLF's body (M-0196).
  - The cable from the release panel to the bolt panel runs straight through the dropped tank (D-0246, D-0253).
  - The sentry overlaps the console behind it (D-0224).
- **SHOULD: the sentry's facing is unclear.** In D-0213 and D-0222 the yellow sight cone points right, toward the exit, while the turret's red light is on the left. I couldn't tell which way it was looking until it turned red (D-0224). **(guess on motion)**
- **FINE, and the best WOLF moment: the lane refusal.** Having rushed WOLF at the relay, I asked him to bait the sentry, and he said "At the relay you'd have sent me in blind. I won't walk into its sights. Time the drop from the panel..." (D-0213). That made me feel my earlier choice mattered, and he still gave me a way forward. On the phone route, where I'd told him the truth, he does bait it ("You told me the truth at the relay. I'll draw it onto the mark...", M-0196 to M-0200). This is the hook of the game.
- **SHOULD: the bait happens too fast to see.** On the phone route WOLF goes from the rubble (x 448) to the exit side (x 902) between t = 149.4 and t = 150.8, and the sentry is parked on the mark by M-0200. From the stills I can't see WOLF *doing* anything brave, only that he ends up by the exit. **(guess: the motion may read)**
- **FINE.** The crushed sentry under the tank (D-0246), with the eye going dark, is a satisfying payoff, and the end card's "THIS RUN" summary (D-0266) is a nice touch.

## 6. Pause, settings and end card (D-0172 to D-0177, D-0264 to D-0266; M-0155 to M-0161)

- **FINE.** The pause menu is clear, and its note ("Returning keeps your last checkpoint. Unsaved progress will be lost.", D-0172) is honest.
- **SHOULD.** Settings is headed "THE DEN / LOCAL CONFIGURATION" and shows "GPU: llvmpipe (LLVM 15.0.6, 128 bits) / Renderer: Compatibility" (D-0174). The first reads as an in-joke and the second as developer info. There is no text-size option, no text-speed option and no hold-to-toggle for the crank (D-0174 to D-0176), and this game is mostly reading and holding.
- **SHOULD.** The first end-card frame is a half-faded overlay whose text collides with the world labels behind it ("THIS RUN" over "DOOR DOWN", D-0264). One second later it's clean (D-0266). That fade may be fine in motion **(guess)**.

---

## 7. Is WOLF a real companion?

**Yes in the writing, not yet on screen.**
- **What works:** he has his own will (he wakes himself and defies the Director). He refuses risky orders and explains why, he remembers how you treated him, and the junction turns that memory into a real change in how you play (D-0213 vs M-0196). That puts him closer to Trico or Lana's Mui than to Stray's B-12, who mostly carries things.
- **What doesn't (all from stills, so partly a guess):**
  - He is posed and parked. Across dozens of 1-second frames he stands in the same pose wherever he was sent (for example `desktop-03-corridor-p2`, `desktop-05-junction-p2`). I never caught him looking at Rowan, sniffing a machine or reacting to the alarm. The 25-game study calls for "constant small idle business"; I can't see any.
  - His abilities are told, not shown: the surge (M-0084) and the readout (M-0121).
  - He quotes your menu text back at you: "You said 'Go now. We can talk after.' I refused." (D-0106). It reads like a log replay. A person would say "You rushed me."
  - With no contact shadow, he floats like Rowan.

## 8. Controls and prompts

- **FINE.** The verbs are few and clear: move, USE, hold USE to crank, 1/2 to choose. The hold prompts count progress ("HOLD E: crank the valve, 1 of 3 turns", D-0183), and the touch button relabels itself as CRANK, DROP and CONTINUE in context (M-0082, M-0200, M-0210). That's good.
- **SHOULD.** There are three text channels (the objective card, the hint bar and the dialogue box) plus world labels, and they often say the same thing: "Arm the breaker by the entrance..." in the hint while the card says "ARM THE BREAKER" (D-0187). I stopped knowing where to look.
- **SHOULD (phone).**
  - The ◀ ▶ buttons and USE sit just under the walking line. Their tops are level with the floor marks (M-0148, M-0196).
  - The hint bar runs under USE, so a long hint would be hidden (M-0052, M-0196).
  - The black side bars are where the thumbs would naturally go.
  - Choices keep the keyboard numbers "1" and "2" on touch (M-0062).

## 9. Text: readability and length

- **Measured from the logs:** desktop shows 46 different dialogue texts (4,037 characters) and 47 different hints (1,818 characters) in 208 s. Of the 58 distinct dialogue lines, 48 are longer than 40 characters, 16 are longer than 80, and the mean is 65 characters. The longest box is three lines and 267 characters (D-0048).
- **Benchmark:** the Game Accessibility Guidelines ask for subtitles of at most 40 characters per line and two lines per subtitle (sometimes three), at no less than 46 px at 1080p, on a solid or semi-opaque background.
- **Comparison:** the dialogue text here is roughly 34 px at 1080p equivalent on desktop and roughly 36 px on the phone (estimated from line spacing, not measured exactly). The background is fine.
- **Tags:** **SHOULD** fix the size and line length. **MUST** cut the volume: this is a genre fans love for being nearly wordless.
- **SHOULD:** some phrasing is stiff or jargon:
  - "I refused the live relay; I'm still here." (D-0116)
  - "The door went with Rowan in front of it." (D-0186)
  - "It must land with the sentry in the brackets." (D-0240)
  - "SERVICE LINE CLEARED." (D-0253)

## 10. Where I would quit

- **Most likely: 30 to 60 s in.**
  - It's the end of the click-through opening (D-0041), or the first view of the corridor with eight text elements (D-0048).
  - A Steam-demo player who came for "INSIDE with a robot wolf" sees a fake-looking cage, then a labelled diagram.
  - If I stayed, the junction would win me back.
- **Second risk: the seal door (D-0103 to D-0106).**
  - The door vanishes into a blob and I walk past the opening.
  - Here I stop trusting that the world makes sense, and the "AI slop" impression sets in.
- **I would not quit at the deaths.** They are fair and fast. The floating body (D-0186, D-0226) would make me laugh, not leave.

---

## 11. Agreement and disagreement with the 25-game study (`docs/research-2026-10/design-reference-25-games.md`)

I don't repeat its sources; these are the points where the frames confirm or push on it.

- **Agree: "Persistent HUD 0; prompts only in USE range"** (§7 targets, from LIMBO, INSIDE, Little Nightmares, Stray and Lana). The build has a persistent objective card, a persistent PAUSE button, a hint bar, and state labels on every machine. The frames are the strongest evidence that the target is right.
- **Agree: "Contact shadows 100%"** (§7). Every frame breaks it, and it's a big part of why the sprites look pasted on.
- **Agree: "walk-through doorways"** (§3 Now). Both the corridor seal and the junction door break it. I'd add a rule the study doesn't state: a door the player opens must sit across the walking line, and the player must pass through it. A door drawn into the back wall is set dressing and should never need opening.
- **Agree: "Visible contact before effect: 100% of WOLF-caused world changes"** (§2, from INSIDE's Huddle). The surge (M-0084) and the readout (M-0121) fail it. So does Rowan's crank (D-0095), which the study doesn't cover: the engineer needs it too.
- **Agree: refusals should be "rare, telegraphed and fast"** (§10.3). In this route WOLF refuses three times in about 2 minutes (D-0070, D-0080, D-0213), but only because the driver used the relay on purpose after the first refusal. The junction refusal is earned and lands well.
- **Push on it: §3's "Room width" and "beat per view" targets are about walking.** The capture shows the bigger pacing problem is *reading*: 41 s before first control and about 16 s of standing at the Records exit. The study has no target for text. Using the guideline above, I'd set one: no dialogue box over 2 lines or about 80 characters, and first control within about 10 s of NEW GAME. The 10 s figure is my judgement as a genre player, not a sourced number.
- **Fills a gap: text size.** The study lists no text size. The Game Accessibility Guidelines' 46 px at 1080p is a sourced floor to use.
- **Fills a gap: phone layout.** The study (§9) says touch target sizes and layouts "were not supplied". From these frames, the buttons are big enough (about 190x180 px on a 1080 px-tall screen), but they crowd the walking line, and the pillarbox wastes the edges. Moving the controls into the side margins, or dropping the 16:9 lock, would help. These are observations, not sourced numbers.

## 12. Second look (2026-10-13)

I re-opened the contact sheets (`desktop-02-opening-p1`, `desktop-03-corridor-p1`, `desktop-05-junction-p1`) and the full frames D-0048, D-0105, D-0157, D-0186, D-0222, M-0084 and M-0200. They match everything above. In particular, the floating knocked-down body (D-0186), the flat navy exit box in Records (D-0157), the open seal leading into the screen while Rowan stands past it at the safe point (D-0105), and the surge chevron drawn over WOLF (M-0084) all look as described. I found a few more things:

- **SHOULD: WOLF parks on top of the bypass wheel.** In D-0105, WOLF stands where the MANUAL BYPASS wheel is. Only a faint ring shows behind his body, so the machine I just cranked has nearly vanished. The label and the full 8-square bar still float above it.
- **SHOULD: the bypass wheel is cut off at the screen edge on the first controllable frame.** In D-0048 it is half off the right edge, with its hairline running to the relay. The tutorial box also sits over the back wall, right where my eye goes first.
- **SHOULD: the sentry's sight beam goes through solid things.** In D-0222 the yellow beam runs from the turret through the bolt panel to the exit hatch. The thin cable from the release panel passes through the sentry's body. Both make the lane read as flat layers, not as a space the sentry looks across.
- **FINE: the phone junction is the most readable screen in the capture (M-0200).** The DROP button names the action, the hint says why ("It's parked on the mark."), and WOLF is visibly away from the tank by the exit. With the labels removed, this frame would almost explain itself.
- **Unchanged verdict:** the junction is worth keeping. The opening (41 s before control) and the corridor seal are where I'd lose a genre fan.

## Credits

- **WOLF//OVERRIDE**, its story, WOLF, Rowan and the Director are by **Nathanial Henniges** (MrDemonWolf, Inc.).
- **Capture:** the scripted play-through and logs in the capture folder ([CAPTURE-ROUND1.md](../playthrough/CAPTURE-ROUND1.md), `_log.jsonl`, contact sheets), driven by `../driver/play.gd`, which was adapted from the Oct 11 audit driver. Rendered with `tools/render/render.sh` in a container.
- **Prior research:** `docs/research-2026-10/design-reference-25-games.md` (the 25-game study and its sources, cited by section above).
- **Game Accessibility Guidelines**, "If any subtitles / captions are used, present them in a clear, easy to read way": 40 characters per line, two lines (sometimes three), at least 46 px at 1080p, solid or semi-opaque background. https://gameaccessibilityguidelines.com/if-any-subtitles-captions-are-used-present-them-in-a-clear-easy-to-read-way/ (fetched 2026-10-12).
- **Reference games, named from my own play memory, not newly sourced here:** INSIDE and LIMBO (Playdead), Little Nightmares (Tarsier Studios), Stray (BlueTwelve Studio), The Last Guardian (genDESIGN / SIE Japan Studio), Planet of Lana (Wishfully).
- **Crops** for close looks: `crops/d095.webp` and `crops/d101.webp`, made from D-0095 and D-0101.
