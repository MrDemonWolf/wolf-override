# Phone player lens: WOLF//OVERRIDE slice, route M

**Who wrote this:** a reviewer playing the part of an ordinary player. They hold a phone in landscape, use two thumbs and play in short sessions. They are not an artist or an engineer. Written 2026-10-12 and re-checked frame by frame on 2026-10-13 (second pass: one correction about the ending, five new points, all marked **[2nd pass]**) for Nathanial Henniges. The game, story and credit belong to Nathanial Henniges.

**What I looked at:** I looked at the phone capture from `play-research/play/phone/` (commit baffea4, 2400x1080, on-screen touch buttons, 226 frames over 171.9 s of game time). I read the contact sheets first, then the full PNG beat frames around every beat. I read the on-screen text as a player would and checked it against `_log.jsonl`.

**What this is not:**
- These are scripted inputs rendered in a container, so they are not hands-on play.
- I only see still frames. I can't see motion, animation, timing feel or sound. When I talk about motion, I say I am guessing.
- The `DEBUG` button is a debug-build artefact, so I ignore it.
- The black side bars are the game's real pillarboxing on a 20:9 screen (see the capture notes).

Each point is marked:
- **MUST-FIX:** a normal player would notice it and it hurts.
- **SHOULD-FIX:** noticeable, but I'd keep playing.
- **FINE:** it works.

All frame names are in `play/phone/frames/`.

---

## Quick verdict

I understood what to do almost all the time. The objective card, the hint strip and the big USE button carry you through, and the end card shows that my choices mattered. That part works.

What breaks the spell is how things look:
- Doors that just vanish.
- Doors that face the camera even though I walk past them sideways.
- A console perched high on a wall.
- A flat grey placeholder cage.
- Soft beige "smoke" blobs.
- A glowing orb where a tank should crash.
- A stiff, tipped-over body hanging in the air when I get knocked down.
- [2nd pass] A line hanging in mid-air across the junction, WOLF passing through the sentry, and an ending where WOLF blinks out and nobody walks through the hatch.

On a phone, the text is small and there is often too much of it at once. The choice buttons also move to the top of the screen, away from my thumbs.

---

## Walkthrough, in order

### 1. Title (0–2 s)

`M-0003-t0002.0-title.png`

- **What I think is going on:** a title screen. NEW GAME is lit, and CONTINUE is greyed out with "No checkpoint yet. Saving starts at the first SAFE POINT."
- **What I'm meant to do:** tap NEW GAME. That's obvious.
- **FINE:** the cover art (engineer in a red jacket, robot wolf, sealed door) tells me what the game is.
- **SHOULD-FIX:** the cover art is a smooth painted illustration, but the game itself is chunky pixel-art sprites. It's a small mismatch I noticed on the second screen.
- **SHOULD-FIX:** the "Concept: Nathanial Henniges / AI-assisted development" line is small grey text at the bottom edge. It's readable, but only just on a phone.

### 2. Opening: WOLF in the cage (2.5–41 s, about 9 CONTINUE taps)

`M-0004-t0002.5-room-opening.png`, `M-0014-t0011.6-…`, `M-0022-t0018.8-…`, `M-0024-t0020.0-…`, `M-0031-t0026.4-…`, `M-0036-t0031.2-…`, `M-0041-t0036.0-…`

- **What I think is going on:** a man in a long coat, the Director, talks to a robot wolf in a cage. WOLF wakes himself, breaks out and refuses an order ("I heard you. I won't do it.") Then he walks off toward "maintenance".
- **What I'm meant to do:** tap CONTINUE. The hint "TAP CONTINUE / PAUSE" makes that clear.
- **SHOULD-FIX: who am I?** The character on the title, the engineer, never appears in the opening. I tap through about 38 seconds of story before I control anything. For a phone session that's a long time to sit before playing, and I don't know yet that I'm not the Director. I'd be mildly impatient from about the 5th tap.
- **MUST-FIX: the cage looks fake.**
  - It's a flat grey box with plain bars and a slab roof (`M-0004`, `M-0014`), sitting on a detailed painted wall. It looks like a placeholder shape, not a real object.
  - When "the gate slides aside" (`M-0022`, `M-0024`), the bars bunch up on the left inside the frame and a beige blob appears.
  - The empty frame then stays there (`M-0031`, `M-0041`).
- **SHOULD-FIX: the release effect is a blob.** The beige "smoke" in `M-0022` is a soft airbrushed oval, nothing like the pixel style. The same blob shows up again later (see 4, 7 and 8).
- **SHOULD-FIX: people stand on the UI.** In the opening the floor sits right at the top edge of the dialogue box (`M-0024`, `M-0036`), so the Director and WOLF look as if they stand on the text box. The bottom of the cage is hidden behind it.
- **SHOULD-FIX: two speaker styles.** Some lines have a speaker column ("DIRECTOR" in red, `M-0004`). Others cram two speakers into the narration box ("DIRECTOR: You were in standby. WOLF: I heard you…", `M-0031`). The second style is harder to follow.
- **FINE:**
  - WOLF's refusal is the best line in the opening, and it makes me like him right away.
  - The lines are short.
  - From the stills, the camera moves in slightly during the opening. My guess is that this is a slow zoom; it looked deliberate.

### 3. Corridor: maintenance lockdown (41–72 s)

`M-0047-t0040.9-world-state.png`, `M-0048-…`, `M-0053-…`, `M-0055-…`, `M-0062-t0052.3-choice-relay.png`, `M-0070-…`, `M-0076-…`, `M-0081-…`, `M-0084-…`, `M-0086-…`, `M-0089-…`

- **What I think is going on:** a hard cut to a corridor. A card says "ROWAN VALE / MAINTENANCE ENGINEER", so now I know I'm Rowan. WOLF is beside me. In order across the screen:
  - a red-screen purge console,
  - a BREAKER,
  - a COOLANT RELAY tagged COOLANT FAULT,
  - a yellow wheel (the manual bypass),
  - a red sealed door,
  - a green SAFE POINT.
- **What I'm meant to do:** walk right, arm the breaker, deal with the relay, get through the seal and save. The objective card ("CHECK THE BREAKER", then "ARM THE BREAKER", then "OPEN THE SEAL", then "REACH SAFE POINT") and the hint strip make this very clear.
- **MUST-FIX: the first playable screen is a wall of text.** `M-0047` and `M-0053` show four text areas at once:
  - the objective card,
  - a tutorial box ("HOLD ◀ / ▶ / TAP USE READ DISPLAY (optional)"),
  - the hint strip,
  - a three-line dialogue box with three different speakers (narrator, WOLF, ROWAN).

  On a phone that's a lot to take in at the exact moment I first get control. I'd skip most of it and just press ▶. The tutorial line "TAP USE READ DISPLAY (optional)" reads like broken English.
- **MUST-FIX: the console floats.** The red-screen purge console sits high up on the wall at head height, with nothing obvious holding it (`M-0047`, `M-0055`, `M-0070`). In the next room the exact same console stands on the floor (`M-0098`), so here it looks stuck on in the wrong place.
- **SHOULD-FIX: the choice buttons are out of thumb reach.** At the relay question (`M-0062`) the arrows and USE disappear, and two wide choice buttons appear across the top of the screen. My thumbs are at the bottom corners, so I have to shift my grip to tap them. The "1" and "2" in front of the answers are keyboard numbers and mean nothing on touch.
- **FINE: the relay choice itself.**
  - "The relay may vent coolant. Your call." against "Go now. We can talk after." is a real, understandable choice.
  - WOLF answers "Thank you for telling me. I'll take the relay." (`M-0070`), and that made me feel he listened.
- **SHOULD-FIX: a button that doesn't match what's happening.** While WOLF says "I've got the contact. Give me a moment." the big button says CRANK (`M-0081`), because I happen to be standing at the bypass wheel. It made me wonder whether I was supposed to crank too.
- **SHOULD-FIX: the surge effect.** The surge is a blue cloud with a cartoon zigzag "M" over WOLF (`M-0084`). It looks like a sticker more than electricity.
- **MUST-FIX: the seal door vanishes, and it's a door you can't go through.**
  - Before: a red-lit door in a frame drawn at an angle, facing the camera (`M-0081`).
  - After: the red door is just gone, and a beige blob sits in front (`M-0086`). The empty frame now shows a corridor going into the screen.
  - Then I walk to the right past the door and stand beside it (`M-0089`). I never go through it.
  - So where did the door go? Up, sideways? And why does the corridor go into the wall when we're walking left to right?

  This is exactly the "weird door" feeling.
- **SHOULD-FIX: a stale label.** The relay still says COOLANT FAULT after WOLF fixed it and the seal opened (`M-0089`, `M-0093`).
- **SHOULD-FIX: WOLF stands inside the door frame.** He's half in front of the post and half behind it, with his tail through it (`M-0089` to `M-0097`).
- **SHOULD-FIX: WOLF quotes me back.** "Safe point saved. WOLF: You said 'The relay may vent coolant. Your call.' I chose the relay." (`M-0089`). Repeating my words in quotes sounds like a computer log, not a friend. A phrase like "You were straight with me" would feel more human.
- **FINE:** the safe point is easy to read. Green light, "SAFE POINT REACHED", "Safe point saved."
- **SHOULD-FIX: where is Records?** The hint says "USE: enter records access", but I can't see a doorway to Records on screen. The only door is the one I just walked past. I'd guess and tap USE, which apparently works.

### 4. Records room (79–118 s)

`M-0098-…`, `M-0101-…`, `M-0102-…`, `M-0110-…`, `M-0113-t0090.8-choice-mirror.png`, `M-0121-…`, `M-0130-…`, `M-0131-…`, `M-0132-t0108.5-t.jpg`, `M-0142-…`

- **What I think is going on:** a server room. I copy the Director's purge order at the PURGE QUEUE console, and WOLF finds a MIRROR PORT. Then I choose: "Use WOLF's readout" or "Use manual port". After that we leave through the EXIT.
- **What I'm meant to do:** walk to each labelled machine and tap USE. Labels change from PURGE QUEUE to PURGE COPIED and from MIRROR PORT to MIRROR COPIED (shown in green). That's clear and satisfying.
- **FINE:**
  - It's the cleanest-looking room. Machines stand on the floor and the background has depth.
  - WOLF is already at the mirror port when I arrive ("Take the purge queue. I'll inspect the mirror."). From the stills it reads as WOLF splitting the work with me, which is companion-like.
- **SHOULD-FIX: "Follow the station lights".** The hint "Follow the station lights: mirror port, then exit." (`M-0110`) talks about lights I can't pick out. I see red wall lamps, but nothing that reads as a guide line.
- **SHOULD-FIX: the story words are dense.** "purge order", "target ID", "local copy", "original logs", "mirror index", "maintenance port", "timestamp", "deletion order", "first copy", "source", "Archive" all arrive inside about 30 seconds (`M-0102`, `M-0113`, `M-0121`, `M-0131`). I got the gist: the Director is deleting proof. I could not explain the mirror choice. I picked an option without knowing what changes.
- **MUST-FIX: the exit door becomes a blank box.** The EXIT is a red-glowing pod door (`M-0113`, `M-0130`). When I secure the copy:
  - it bursts into green puffs (`M-0131`),
  - then becomes a flat, plain dark-navy rectangle with a thin outline (`M-0132`, `M-0142`).

  That looks like a missing texture, not an open door. A thin green bar lies at its bottom edge, and I don't know what it is.
- **SHOULD-FIX: long caption, mixed speakers.** "FIRST COPY SECURED. WOLF: An order and a timestamp don't tell me who's a threat. I want the source. ROWAN: Then Archive is next." (`M-0131`) is three voices in one box. I'd read the first half and tap.
- **SHOULD-FIX: the hint strip runs under USE.** Its right end slides under the big USE button (`M-0110`, `M-0130`). Text isn't cut off here, but in the junction it is (see 5).
- **SHOULD-FIX: a stray line under my feet.** A thin light bar sits on the floor under Rowan in nearly every frame (for example `M-0110`, `M-0154`). I guess it marks the player, or what I can USE, but nothing explains it, so it looks like a leftover line.

### 5. Service Junction: the Blowback beat (124–158 s)

`M-0148-…`, `M-0151-…`, `M-0154-…`, `M-0162-…`, `M-0164-…`, `M-0167-…`, `M-0168-…`, `M-0169-t0131.8-knockdown-knockdown.png`, `M-0170-…`, `M-0183-…`, `M-0186-…`, `M-0188-t0142.2-choice-lane.png`, `M-0196-…`, `M-0200-…`, `M-0201-…`, `M-0202-…`, `M-0204-…`, `M-0207-…`, `M-0208-…`, `M-0210-…`, `M-0220-…`

- **What I think is going on:** a pipe room with a row of labelled machines: OVERLOAD BREAKER, RELIEF VENT, VALVE (with a LINE gauge), SEALED DOOR, TANK RELEASE. A tank hangs from a crane claw on the right. The plan is spelled out:
  1. Arm the breaker.
  2. Crank the valve three turns.
  3. Get clear, and the door blows.
  4. A sentry robot patrols beyond it under the tank.
  5. WOLF draws it onto the mark and I DROP the tank.
  6. The power reroutes to the exit bolt, and I pop it and leave through the hatch.
- **What I'm meant to do:** follow the cards ("ARM THE BREAKER", "CRANK THE VALVE", "GET CLEAR OF THE DOOR", "CHECK THE LANE", "DROP THE TANK", "POP THE EXIT BOLT"). This is the most fun part, and it reads like a little action puzzle.
- **FINE: you can always see the plan.**
  - The labels show where I am in it: VALVE 0/3, 1/3, 2/3, then FUSE LIT, DOOR DOWN, TANK DOWN, EXIT OPEN.
  - "Get off the grate before the gauge peaks" (`M-0162`) is clear.
  - The red-and-black danger strip on the floor when the fuse lights (`M-0168`) is a great signal of where not to stand.
- **FINE: a fair knockdown with a fast retry.**
  - "The door went with Rowan in front of it. When the fuse lights, back away past the valve." (`M-0169`) tells me what I did wrong and how to fix it.
  - I'm back at the entrance about 1 s later (`M-0170`). I lose roughly 10 seconds, so I wouldn't be annoyed.
  - **[2nd pass] FINE, with a note:** the retry puts the breaker back to unarmed ("ARM THE BREAKER" again, `M-0170`, `M-0172`), so I redo the breaker and all three turns (`M-0172` to `M-0182`, about 5 s). That's short enough. A hint like "Back at the junction entrance. Arm the breaker again." would stop me wondering why the label went back.
- **MUST-FIX: the knockdown body hangs in the air.** In `M-0169` Rowan is the standing sprite tipped over about 70°, rigid, floating at waist height in front of the valve with nothing under them. I only have this one still and the motion may look better. As a still it looks like a cardboard cut-out falling over, which is exactly the "odd floating" thing.
- **SHOULD-FIX: CRANK versus "HOLD USE".** While I crank, the button says CRANK, but the hint says "HOLD USE: crank the valve, 0 of 3 turns" (`M-0164`). On a phone there is no "USE" button at that moment, so it should say "Hold CRANK".
- **SHOULD-FIX: nobody touches the wheel.** Rowan just stands next to the valve wheel the whole time (`M-0164`, `M-0167`). Their hands are never on it. From stills I can't tell whether there is a cranking animation. If there isn't, cranking will feel like nothing is happening.
- **MUST-FIX: the junction door also faces the camera, and I walk past it.**
  - The SEALED DOOR is drawn at an angle facing me (`M-0148`).
  - After the blast it's a burnt frame with a corridor going into the screen (`M-0186`).
  - But the "lane beyond" is to the right, and I just walk sideways past the door to get there (`M-0188`, `M-0196`). I never go through it.
  - So what did blowing the door open? Physically it doesn't block the path I take.

  This is the same problem as the corridor seal.
- **SHOULD-FIX: smoke blobs again.** The blast smoke is the same soft beige oval (`M-0169`, `M-0183`), and it hides the door at the exact moment I want to see it go.
- **SHOULD-FIX: characters stack into a mush.** At the lane choice (`M-0188`) and just after (`M-0196`), WOLF, Rowan and the broken door frame are drawn on top of each other. I could not tell where WOLF's body ends.
- **FINE: the lane choice.**
  - "Draw it under the tank if you can stay clear." against "Stay back, I'll time it." is clear and has a real risk to it.
  - WOLF answering "You told me the truth at the relay. I'll draw it onto the mark…" (`M-0196`) is the moment WOLF feels most like a partner who remembers.
- **SHOULD-FIX: the choice buttons are at the top again** (`M-0188`), with the same thumb problem as in the corridor.
- **SHOULD-FIX: floor brackets with no explanation.** There's a cyan bracket on the floor by the TANK RELEASE and a dashed yellow bracket under the tank (`M-0188`, `M-0200`). I worked out that the yellow one is "the mark". I never learned what the cyan one means, though I guess it's "stand here to drop".
- **[2nd pass] SHOULD-FIX: WOLF goes through the sentry, not around it.** After I pick "Draw it under the tank", WOLF is standing on the yellow mark with the sentry still to his right (`M-0198`). Less than a second later he is past it, at the far right by the hatch, and the sentry is on the mark (`M-0200`). In a side-on corridor there is no room to pass, so from the stills he walks straight through the robot. The whole bait takes under 2 seconds (149.4 s to 151.2 s), so it's over before I see WOLF "draw" anything. I'm guessing about the motion, but the "brave decoy" moment I chose doesn't get any screen time.
- **[2nd pass] SHOULD-FIX: a line floating at chest height.** A thin straight line runs through the air from the TANK RELEASE console, behind the tank, to the exit-bolt console (grey in `M-0188`, `M-0198`, `M-0200`; yellow in `M-0202`; cyan in `M-0208`, `M-0219`). It has no hooks, no pipe and no wall behind it, and it crosses the space where Rowan stands. I guess it's meant to be the power "rerouting to the exit bolt", but it reads like a laser tripwire or a leftover guide line. A cable lying on the floor, or a conduit on the back wall that lights up, would read as real.
- **FINE: DROP.** In `M-0200` the sentry sits on the yellow mark under the tank, the button turns into DROP, and the hint says "It's parked on the mark." That's the clearest moment in the slice.
- **SHOULD-FIX: the tank becomes a glowing ball.** The impact frame is a big soft cyan glowing ball (`M-0202`), and the tank itself isn't visible. It reads as a placeholder flash. In the next frame (`M-0204`) the tank sits on the crushed sentry, which looks fine.
- **MUST-FIX: the exit hatch vanishes too.**
  - The hatch is a closed round-wheel door (`M-0201`).
  - "The hatch slides open" (`M-0208`), but in the still the door panel is simply gone. Where did it slide to?
  - Again it's drawn as a frame facing me with a corridor going into the screen.

  I can't see motion, so it may slide in the animation, but the open state shows no door anywhere.
- **SHOULD-FIX: WOLF blocks the exit.** He stands in front of the open hatch (`M-0208`, `M-0210`, `M-0219`), so the exit is half hidden.
- **[2nd pass, corrects the first pass] MUST-FIX: nobody walks out, and WOLF just vanishes.** I first guessed WOLF walked out ahead of me. Checking the frames and the capture log, he didn't:
  - USE "leave through the hatch" works while Rowan is still standing at the bolt console, nowhere near the hatch (`M-0208`).
  - Then the arrows and USE disappear and I sit on the closing line with only CONTINUE for about 9 s (`M-0210` to `M-0219`). That wait is the driver's reading time, not the game's.
  - When I tap CONTINUE, WOLF is simply gone from the doorway one second later (`M-0220`). The log still has him standing in the same spot, so he was hidden, not walked off.
  - Rowan takes a step or two to the right, overlapping the bolt console, and the END OF SLICE card fades in before they reach the hatch (`M-0220`, `M-0221`).

  So the last thing I see of my companion is him blinking out of existence, and the "walk out" I was promised never happens on screen. A short shot of WOLF going through the hatch and Rowan following, then the card, would end the slice properly.
- **FINE:** "SERVICE LINE CLEARED. WOLF: It's quiet now. The line runs on toward Archive. ROWAN: Then that's where we go." It's a decent closing beat, though it's three voices in one box again.

### 6. Pause and Settings on the phone (paused at 128.1 s)

`M-0155-t0128.1-overlay-pause.png`, `M-0157-…settings-tab-0.png`, `M-0158-…`, `M-0159-…settings-tab-2.png`

- **FINE:** the pause menu is big and clear. "Returning keeps your last checkpoint. Unsaved progress will be lost." is honest and helpful.
- **SHOULD-FIX: the Settings screen isn't made for a phone.**
  - The Display tab shows WINDOW SIZE 1280×720, FULLSCREEN and V-SYNC. These mean nothing on a phone; there's even a footnote saying "Window size is OS-managed on mobile".
  - It shows "GPU: llvmpipe (LLVM 15.0.6, 128 bits) / Renderer: Compatibility", which is developer information.
  - The Controls tab lists only keyboard and controller. There's nothing about touch, the button layout or the button size, so I can't change anything for the way I actually play.
- **SHOULD-FIX: redundant footer.** "TAP RESUME TO RETURN" under a RESUME button is redundant.

### 7. End card and back to title (167–172 s)

`M-0221-t0167.8-overlay-endcard.png`, `M-0223-t0169.8-t.jpg`, `M-0226-…`

- **FINE: the end card is the best moment for showing that choices mattered.** "THIS RUN" lists:
  - RELAY: Rowan told WOLF the risk. WOLF took the live contact.
  - MIRROR: WOLF read the timestamp off his own readout.
  - LANE: WOLF drew the sentry onto the mark.

  I'd want to replay it to see the other lines.
- **FINE: the fade-in.** In one frame the end card fades in over the room labels and they overlap (`M-0221`). It's a single in-between frame, so it's fine.
- **FINE:** back at the title, PLAY AGAIN replaces NEW GAME with "Slice complete." That's clear.

---

## Cross-cutting points

### Text on a phone

- **SHOULD-FIX: the text is small.** Dialogue text is roughly 24 px tall on a 1080-px-tall screen. On a typical 6.5-inch phone that is noticeably smaller than normal phone body text, and the hint strip is smaller again. I could read it, but I'd hold the phone closer. Players with weaker eyes would struggle.
- **MUST-FIX on the first screen, SHOULD-FIX elsewhere: too many text boxes at once.**
  - Up to four boxes (card, tutorial, hint, dialogue) compete in `M-0047`.
  - Two or three compete in most frames.
  - The dialogue often runs two to three lines with several speakers.

  In a short phone session I'd skim the hint strip and ignore the rest.
- **SHOULD-FIX: text cut off by the USE button.** The hint strip is cut off by the USE button when the line is long: "…in the alcove just inside." runs into the button edge (`M-0186`).
- **SHOULD-FIX: "They".** "Rowan keeps WOLF's systems running. They know what a fault looks like" (`M-0047`). Rowan uses they/them and that's right to keep. But that early, with "WOLF's systems" just before it, "They" is easy to read as "the systems". Using the name again, as in "Rowan knows what a fault looks like", avoids the slip.

### Touch controls

- **FINE: the buttons themselves.**
  - The ◀ ▶ buttons at bottom-left and USE at bottom-right are big, sit where my thumbs rest, and are labelled with what they do (USE, CRANK, DROP, CONTINUE). That's good.
  - PAUSE is top-right and easy to find.
- **[2nd pass] SHOULD-FIX: the characters are small on a phone.** Rowan is about 180 px tall on a 1080 px screen (`M-0142`, `M-0200`), roughly 1.2 cm on a 6.5-inch phone. I can follow them, but faces and hands are unreadable, which matters for a cinematic story game where WOLF's "reactions" are the point. The tighter zoom in the closing beat (`M-0219`) looks much better.
- **[2nd pass] FINE, small nit: choice text styles differ.** The Records answers are ALL CAPS commands ("1 USE WOLF'S READOUT", `M-0113`), while the relay and lane answers are spoken sentences (`M-0062`, `M-0188`). Spoken sentences feel more like talking to WOLF. Using one style would be tidier.
- **SHOULD-FIX: the black side bars.** The game sits in a 16:9 box with black bars on a 20:9 phone, so the buttons sit inward from the edges, and the outer strip of the screen (where thumbs naturally rest) does nothing.
- **SHOULD-FIX: choice buttons move to the top** (`M-0062`, `M-0113`, `M-0188`), and the bottom buttons disappear while a choice is up.

### Does WOLF feel like a real companion?

- **In words, yes.** He refuses the Director, thanks me for honesty, splits work with me, says "When the door goes, don't be standing in front of it", and remembers the relay at the lane. The end card shows that his choices are tied to mine.
- **In the pictures, not yet.**
  - In nearly every still he's in the same mid-stride walking pose (`M-0089`, `M-0098`, `M-0130`, `M-0148`, `M-0200`). He never sits, looks at me or reacts. I'm guessing about idle animations, because I only see stills.
  - He overlaps door frames and Rowan.
  - [2nd pass] His one big action moment (drawing the sentry) is over in under 2 s and seems to pass through the robot, and at the end he vanishes instead of leaving with me (`M-0198`, `M-0200`, `M-0220`).
  - He quotes my exact words back to me in quotation marks.

### Things that look fake or stuck on (Nathanial's list)

| Rating | What | Frames |
|---|---|---|
| MUST-FIX | Doors that vanish when opened: the corridor seal, the Records exit (becomes a blank navy box) and the junction hatch | `M-0086`, `M-0132`, `M-0142`, `M-0208` |
| MUST-FIX | Doors drawn facing the camera with a corridor going into the screen, which the characters walk past sideways instead of through | `M-0089`, `M-0188`, `M-0210` |
| MUST-FIX | Purge console perched high on the wall in the corridor (the same model stands on the floor in Records) | `M-0047`, `M-0070` |
| MUST-FIX | Flat grey placeholder cage in the opening | `M-0004`, `M-0024` |
| MUST-FIX | Knockdown: a rigid tipped-over sprite floating in mid-air | `M-0169` |
| SHOULD-FIX | Soft beige smoke ovals reused for the cage, the seal and the blast | `M-0022`, `M-0086`, `M-0169`, `M-0183` |
| SHOULD-FIX | Cyan glow ball at the tank impact | `M-0202` |
| SHOULD-FIX | Zigzag "M" sticker for WOLF's surge | `M-0084` |
| SHOULD-FIX | Stray light bar under the player; green bar in the Records exit doorway | `M-0110`, `M-0142` |
| MUST-FIX [2nd pass] | WOLF disappears from the hatch doorway at the very end; nobody is shown leaving | `M-0219`, `M-0220`, `M-0221` |
| SHOULD-FIX [2nd pass] | Thin line hanging in mid-air across the junction at chest height | `M-0188`, `M-0198`, `M-0202`, `M-0208` |
| SHOULD-FIX [2nd pass] | WOLF passes through the sentry during the bait | `M-0198`, `M-0200` |
| SHOULD-FIX | Stale COOLANT FAULT tag after the fix | `M-0089` |

### Where I'd be confused, bored or annoyed, and for how long

- **Opening:** 38 s of tapping before I play. I'd be mildly bored from about 15 s in. Story fans would be fine; impatient phone players might quit here.
- **First corridor screen:** about 5–10 s of "what do I read first?" Then I'd just press ▶ and follow the hint.
- **"USE: enter records access":** a few seconds of "where?", because I can't see a Records door.
- **Records mirror choice:** I don't understand what the two options change. I'd just pick one, so it's confusing but doesn't block me.
- **"HOLD USE" while the button says CRANK:** a second of hesitation.
- **Blowback knockdown:** about 10 s lost, and the retry was clear. Not annoying.

### Where I would quit

I would probably **not** quit within this slice. It's about 3 minutes long, it's always clear what to do next, and the junction is fun. The real risk of quitting is the **opening**: on a phone, nearly 40 s of tapping through someone else's conversation before I can move. The second risk is the **first corridor screen's wall of text**. After that the end card's "THIS RUN" summary would make me want to replay with the other choices.
