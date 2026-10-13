# Newcomer lens: "I rarely play games and this is my first time"

**Game:** WOLF//OVERRIDE, an original game and story by Nathanial Henniges (build `baffea4`).
**What I looked at:** the two scripted captures in `../play/` (desktop route D at 1280x720, phone route M at 2400x1080). I went through the contact sheets in order first. Then I opened the full frames around every beat and read the on-screen text as a player would. Frame names below are the files in `../play/desktop/frames/` (D-) and `../play/phone/frames/` (M-). The capture driver and frame log are the earlier capture pass's work ([CAPTURE-ROUND1.md](../playthrough/CAPTURE-ROUND1.md)). I used the log only to check timings I could not read off the pictures.
**Honesty note:** I only saw still frames. Whenever I say something about motion, timing or "feel", I am guessing from frame times and from the before and after pictures, and I say so. Nobody here has played it by hand. The mistakes in the runs (standing in the blast, walking into the sentry) were planned by the script, so they are not proof that a real newcomer would make them.

**Second pass (2026-10-13):** I re-opened the frames behind every MUST-FIX and the weaker calls. Three earlier calls were wrong because the frame caught a fade or a pile I misread, and I have corrected them below:
- The end card is not see-through. `D-0264` and `M-0221` are its first frame mid fade-in, and it is fully solid and easy to read 1 s later (`D-0265-t0205.0-t.jpg`, `M-0222-t0168.8-t.jpg`).
- The pause panel is the same: `D-0172` is mid-fade, and `D-0177-t0142.0-overlay-pause.png` and the Settings panel (`D-0173`) are solid.
- The sentry under the tank does read as a crushed pile (`D-0246`, `D-0263`). Only the clean, undented tank still looks a bit off.

I also added two small points: "secure the first copy" is pressed at the EXIT pod (section 4), and the desktop Settings page talks about mobile (section 5). Every other call held up on the re-check, including the frame-log timing of the fuse.

Marks: **MUST-FIX** = a normal player would notice and it hurts. **SHOULD-FIX** = noticeable, weaker or easier to live with. **FINE** = works, or is good.

---

## The short version (as a newcomer)

- I understood the basic idea by about the 1-minute mark. A boss ("the Director") wants to use a robot wolf as a weapon. The wolf wakes up and says no. "I" am Rowan, the mechanic, and we sneak through maintenance to save some logs before they are deleted.
- What I was **meant to do** was nearly always clear, because the game tells me in two or three places at once (objective card top-left, hint bar, dialogue). What I was **doing it for** was much less clear. "Mirror port", "purge-order trace", "first copy", "Archive", "the source"... I never really knew what these were. I just pressed E on the glowing thing.
- The scenery looks good: moody, wet, industrial, and nothing looks amateur at a glance. What breaks it is the **doors**. Almost every door in the game either has no clear reason to be there, opens into the back wall while I walk past it sideways, or just disappears. The exit in Records turns into a **flat dark-blue rectangle** that looks like a missing picture.
- WOLF has the best writing in the game. He says no, he remembers what I chose, and he holds it against me later. That made me care. But on screen he keeps **standing inside machines** (the valve, the relay, the door frame), which makes him look like a cut-out sticker rather than something physically there.
- Where I'd most likely quit: the Service Junction. The door blows about **1 second** after "FUSE LIT", and the second death message talks about "the alcove's right post", which I cannot see anywhere. Second most likely: the ~38 seconds of reading at the start before I can move.

---

## 1. Title screen (0-2.5 s)

- **FINE.** `D-0003-t0002.0-title.png`, `M-0003-t0002.0-title.png`. Looks like a real game's title. The big character art makes me want to play. NEW GAME is clearly the button to press. "No checkpoint yet. Saving starts at the first SAFE POINT." is helpful.
- **SHOULD-FIX (small).** The title art shows a big, detailed teenager in a red jacket and a huge wolf. In the game they are tiny figures about a sixth of the screen tall (`D-0048-t0041.0-room-corridor.png`). That is normal for this kind of game, but the drop is big. I spent the first minute squinting to see who was who.

## 2. Opening scene (2.5-41 s, about 38 s with no control)

What I thought was going on: a man in a long coat (the Director) stands next to a cage. Something is in the cage. Text tells me the wolf woke himself and broke out. The wolf refuses the Director, then walks off.

- **SHOULD-FIX: I can barely see the wolf in the cage.** `D-0004-t0002.5-room-opening.png`, `D-0014-t0011.6-dialogue-nobody-gives-an-activation-command.png`. The text says "A blue light answers from inside the containment seal", but I saw no blue light, only a very dark shape behind the bars. If this is the "WOLF wakes up" moment, I want to see his eyes light up.
- **MUST-FIX: the cage door.** `D-0022-t0018.8-dialogue-the-latch-breaks-from-the.png` → `D-0024-t0020.0-wolf-to-185-arrived.png`. The bars squash into a narrow strip on the left. Behind them a big tank and pipes appear that were "inside" the cage, so it reads as a see-through frame drawn over the wall, not a box with depth. There is also a **beige/tan cloud** low in the cage in `D-0022` that looks like a smudge or a stain, not dust or steam. The same beige blob comes back at every explosion and door (see section 7).
- **SHOULD-FIX: who am I?** I am never shown in the opening. Rowan first appears in the corridor (`D-0048`), with a card saying "ROWAN VALE / MAINTENANCE ENGINEER". For 40 seconds I assumed I might be the man in the coat. Showing Rowan in the opening, even in the background, would fix it.
- **SHOULD-FIX: long and static.** 7 pages of text over 38 s (at the script's reading pace) and the Director never moves (`D-0004` to `D-0041`; contact sheet `desktop-02-opening-p1.png`). After the wolf walks off (`D-0042-t0036.3-wolf-to-110-arrived.png`) there are 5 more seconds of the same picture with "WOLF turns from the Director and heads for maintenance." He walks to the left and half off the screen, through the cage frame. As a newcomer I'd start mashing E here.
- **FINE.** The text itself is short and readable. "I decide who counts as a threat. WOLF handles the rest." is a strong first line.

## 3. Maintenance corridor (41-94 s desktop, 41-79 s phone)

What I thought I was meant to do: walk right, use the breaker, then get the red door open.

- **MUST-FIX: four text boxes at once on the first frame I control.** `D-0048-t0041.0-room-corridor.png`: a name card (top-left), a controls box "A / D MOVE, E READ DISPLAY (optional)" (top-middle), a hint bar "E: read the Director's purge display." and a 3-line dialogue box. That is about 60 words before I've moved. As a newcomer, I didn't know which one to read first.
- **SHOULD-FIX: the red console looks parked on a pipe.** `D-0048`, `M-0070-t0060.1-dialogue-wolf-thank-you-for-telling.png`. The "purge display" box sits up at head height on top of a thin column. It reads as floating or balanced, not mounted. The same console is reused as the "PURGE QUEUE" in Records (`D-0116-t0094.4-room-records.png`), and there it sits on the floor, so it is clearly the same object at two heights.
- **SHOULD-FIX: the choice at the breaker.** `D-0062-t0052.6-choice-relay.png`. I press E to arm the breaker, and instead WOLF asks "That relay's tagged COOLANT FAULT. What happens if I touch it live?" My answers are "1 The relay may vent coolant. Your call." or "2 Go now. We can talk after." I picked 2 on desktop, thinking "hurry, the logs are being deleted". WOLF then says "No. I won't take that risk blind" (`D-0070-t0060.4-dialogue-wolf-no-i-won-t.png`), and later "Next time, tell me what it costs" (`D-0106`). It took me a moment to realise that answer 2 meant *not telling him the risk*. The consequence is good (see WOLF section), but I felt slightly tricked. If the option said what Rowan is doing, for example "Skip the risk talk. Go now.", I'd own the choice.
- **SHOULD-FIX: "the red seal stays shut".** `D-0075-t0065.3-dialogue-the-breaker-catches-blue-light.png`. The seal is off-screen to the right at this point, so I don't know what "the red seal" is yet. "Blue light fills the coolant relay": the relay's lamp changes a little, but I'd never have spotted it without the text.
- **MUST-FIX: the MANUAL BYPASS looks like a road sign.** `D-0080-t0068.0-dialogue-wolf-i-said-no-i.png`, `D-0095-t0080.2-dialogue-halfway-the-hiss-gets-louder.png`. It is a yellow wheel inside a round frame on a thin pole with a tiny foot, joined to the relay by a thin grey line. It doesn't look bolted to anything. In `M-0082-t0068.5-buttons-crank-pause.png` Rowan stands exactly on top of it, so the wheel shows through Rowan's body. When cranking (`D-0092`-`D-0100`) Rowan stands in front of it with their hands nowhere near the wheel. I'm guessing about the motion, but in every still Rowan is just standing.
- **FINE: the crank itself.** "HOLD E: crank the manual bypass, 4 of 8" with a little 8-segment meter under the label is clear (`D-0095`). Letting go at 5 and having it "hold where Rowan left it" is kind. A newcomer won't lose progress.
- **MUST-FIX: the sealed door opens into the wall, and I walk past it.** `D-0080` (closed) → `D-0102-t0084.0-wolf-follow.png` (open) → `D-0106-t0086.1-dialogue-safe-point-saved-wolf-you.png`. The door is a heavy frame standing slightly angled, as if it goes into the back wall. When it "opens", the door panel simply vanishes and a corridor going *into the screen* appears behind the frame, with that beige cloud on the floor. Then the hint says "Move to the safe point", and I walk *past* the open doorway to a green save terminal on the right. Then "E: enter records access" takes me to Records from the save terminal, not through the door. Questions I had as a newcomer:
  - Was the door ever blocking me? I could see the safe point was further right along the same floor.
  - Where did the door go when it opened? It's just gone.
  - Do I go through that doorway or not? (It looks like I go through the save terminal.)
- **SHOULD-FIX: "COOLANT FAULT" stays up after everything is fixed.** `D-0106`, `M-0089-t0071.7-dialogue-safe-point-saved-wolf-you.png`. The orange warning tag never clears, even after WOLF takes the surge or the bypass locks over.
- **MUST-FIX: WOLF standing inside things, corridor.** `D-0106` (WOLF's body on top of the bypass wheel). `M-0082` and `M-0084-t0068.9-dialogue-wolf-takes-the-surge-through.png` (WOLF walks *into* the relay box, half of him inside it). `M-0089` (WOLF over the wheel, tail through the seal frame).
- **SHOULD-FIX: the surge effect.** `M-0084`. When WOLF "takes the surge", a cartoon zig-zag shaped like the letter "M" sits on top of him with a blue puff. It looks like clip-art stuck on, not electricity.
- **FINE.** The labels over each machine (BREAKER, COOLANT RELAY, MANUAL BYPASS, SAFE POINT) mean I always knew what to walk to. For someone who rarely plays, this helps a lot.

## 4. Records (94-138 s desktop)

What I thought I was meant to do: press E on the red machine, then the blue machine, then leave through the exit. I did not know why.

- **SHOULD-FIX: I don't know what I'm collecting.** "Copy the purge-order trace", "The Director's purge order has a time and target ID. Rowan keeps a local copy; the original logs are still missing" (`D-0120`), "I found the mirror index" (`D-0131-t0105.9-choice-mirror.png`), "WOLF reads the timestamp off his own readout. The purge target existed before the deletion order." (`M-0121-t0098.5-dialogue-wolf-reads-the-timestamp-off.png`). Each sentence makes sense alone, but as a non-gamer I couldn't tell you what I'd achieved at the end of the room. "FIRST COPY SECURED" (`D-0148`) sounds important, but I don't know what it is a copy of.
- **SHOULD-FIX: the mirror choice has no visible stakes.** `D-0131`, `M-0113-t0090.8-choice-mirror.png`: "1 USE WOLF'S READOUT / 2 USE MANUAL PORT". I had no reason to pick either. After the corridor I suspected it was a trust test, but nothing told me so. (The end card later says which I picked, so it does matter.)
- **MUST-FIX: the Records exit door.** `D-0147-t0121.1-hint-e-secure-the-first-copy.png` → `D-0148-t0121.5-dialogue-first-copy-secured-wolf-an.png` → `D-0150-t0123.5-t.jpg` / `D-0159-t0132.3-hint-e-follow-the-service-line.png`. Before: a tall, narrow red-lit pod labelled EXIT. When used, green puffs come out of it and a thin grey outline box appears over it. After: the pod is replaced by a **plain flat navy rectangle with a grey border and a mint-green bar at the bottom**. It looks like a picture failed to load, or like a UI button, not an opening. Where did the door go? Where does this lead? This is the single most "fake"-looking thing in the slice.
- **SHOULD-FIX: I "secure the first copy" at the EXIT door.** `D-0147-t0121.1-hint-e-secure-the-first-copy.png`. The hint "E: secure the first copy." comes up while Rowan stands at the red EXIT pod, not at either machine I copied from. As a newcomer I'd ask why saving a copy happens at a door. Then the next E press at the same door means "leave" (`D-0159`).
- **SHOULD-FIX: two separate E presses to leave, and the old dialogue stays up.** After "FIRST COPY SECURED" (`D-0148`), the same 2-line dialogue stays on screen for about 16 s (`D-0148` to `D-0164`, contact sheet `desktop-04-records-p2.png`). I press E CONTINUE, then I have to press E again for "follow the service line toward Archive". As a newcomer I'd wonder if the first press did anything.
- **FINE.** "Follow the station lights: mirror port, then exit." (`D-0128`) is a nice, plain instruction, and the label changes from PURGE QUEUE to "PURGE COPIED" and from MIRROR PORT to "MIRROR COPIED" (`D-0147`) give clear feedback.

## 5. Service Junction "Blowback" (138-204 s desktop, 124-167 s phone)

What I thought was going on: blow open a stuck door with pressure, then crush a patrolling robot with a hanging tank, then open the exit. This was the most fun-looking part; the machines are chunky and readable.

- **FINE: the instructions.** ROWAN: "The breaker by the entrance feeds that line. Overload it, crank the valve, and the door goes." WOLF: "When the door goes, don't be standing in front of it." (`D-0165-t0138.1-room-junction.png`, `D-0168`). Clear, and WOLF warning me is a nice touch.
- **SHOULD-FIX: the narration contradicts the picture.** `D-0165` and `M-0148-t0124.2-room-junction.png` say "WOLF runs ahead to the valve and reads its LINE gauge", but WOLF is standing next to Rowan at the breaker on the far left, nowhere near the valve. (He may have run there and back between frames. I can't tell from stills.)
- **SHOULD-FIX: a row of five labels.** `D-0165`: OVERLOAD BREAKER, RELIEF VENT, VALVE, SEALED DOOR, TANK RELEASE in one evenly spaced line, like a museum display. It helps, but it makes the room look like a diagram. Later they become "BREAKER SPENT", "VALVE SPENT", "RELEASE SPENT", "DOOR DOWN", "TANK DOWN", "EXIT BOLTED", "EXIT OPENING" (`D-0243`, `D-0250`). "Spent" and "bolted" are gamer and engineer words. Some faded labels (RELIEF VENT in `D-0226`, `D-0243`) are hard to read.
- **SHOULD-FIX: "Relief vent. Get off the grate before the gauge peaks."** `D-0179-t0142.4-hint-relief-vent-get-off-the.png`. This pops up as I walk past the grate. I didn't know the gauge was a danger or what "peaks" looks like, and I'd been told nothing about a relief vent before this line.
- **MUST-FIX: the fuse is too short for a newcomer (timing guessed from frame times).** Fuse lit at 144.6 s (`D-0185-t0144.6-dialogue-fuse-lit-back-away-from.png`), knocked down by about 145.5 s (`D-0186-t0145.8-knockdown-knockdown.png` is taken a fraction after the hit). In the clean run: fuse 151.7 s (`D-0199`), door gone by 152.7 s (`D-0200-t0152.7-dialogue-the-door-goes-wolf-heads.png`). So I get roughly **one second**. In that second a new player is still reading "FUSE LIT. Back away from the door, past the valve." The phone run shows the same (`M-0168` → `M-0169-t0131.8-knockdown-knockdown.png`). I expect almost every first-timer to get knocked down here at least once. The good news is the retry is quick (back at the junction entrance about a second later, `D-0187-t0146.9-knockdown-restored.png`), and the message says what went wrong: "The door went with Rowan in front of it. When the fuse lights, back away past the valve."
- **SHOULD-FIX: the knockdown poses float.** `D-0186` and `M-0169`: Rowan is a tilted body hanging in the air. `D-0226-t0174.2-knockdown-knockdown.png`: Rowan is a horizontal body floating at knee height under the sentry's red beam. A thrown body mid-air is fine for a split second, but these are the frames that sit on screen under the failure message, so they look stuck.
- **MUST-FIX: the "sealed door" makes no sense as a door.** `D-0168` (closed) → `D-0200` (blown) → `D-0205-t0156.1-choice-lane.png`. Like the corridor seal, it's a frame angled into the back wall. When it "goes", the door is still standing in its frame with glowing orange cracks and a burst-open corner, and behind it a corridor runs *into the screen*. Then I walk sideways *past* it to the right. So I blew up a door I never go through, and the way forward (to the right) was never blocked by it, as far as I can see. The beige cloud (`D-0186`, `D-0200`, `M-0169`) is the same flat tan blob as at the cage and the corridor seal. It doesn't look like smoke or dust; it looks like a smear on the screen.
- **MUST-FIX: WOLF inside the valve and door for the whole lane section.** `D-0205`, `D-0213-t0163.3-dialogue-wolf-at-the-relay-you.png`, `D-0222`, `D-0240`, `M-0188-t0142.2-choice-lane.png`. WOLF "heads for the rubble", but on screen he stands *inside* the valve machine and the door frame, overlapping both, for about 35 s. The "rubble" itself is a small glowing broken piece beside the door that I'd never have called rubble.
- **MUST-FIX: "the alcove's right post".** The second knockdown message is "The sentry spotted Rowan past the alcove's right post and ran them down. Keep inside the posts, or get back over the rubble." (`D-0226`). The "alcove" on screen is a pale cyan rectangle outlined on the floor (`D-0213`, `D-0240`), and the "posts" are its two thin cyan edge lines. To me that is not an alcove and has no posts. The earlier hint "You're in its lane. Get into the release alcove or back over the rubble." (`D-0222-t0171.8-hint-you-re-in-its-lane.png`) has the same problem. If I'd died here twice, I'd have quit, because I wouldn't know where "safe" was.
- **SHOULD-FIX: the sentry and Rowan overlap.** `D-0222`. The sentry rolls *through* Rowan's legs. The yellow vision cone also tints the machine behind it, which made it look ghosted for a second.
- **SHOULD-FIX: "It must land with the sentry in the brackets."** `D-0240-t0186.6-hint-e-drop-the-tank-it.png`. Once I spotted the yellow dashed bracket under the tank, this was clear. "The tank takes a moment to fall" is a good warning. But "brackets", "mark" and "floor mark" are three names for the same thing across the hints and WOLF's lines.
- **SHOULD-FIX (small): the tank lands looking brand new.** `D-0243-t0188.4-dialogue-the-tank-comes-down-square.png`, `D-0246`, `D-0263`, `M-0202`. When it lands there is a big soft blue glow ball, which looks more like magic than metal hitting metal. Afterwards the sentry *does* read as a crushed pile under the tank, which is good (I got this wrong on my first pass). But the tank has no dent, no tilt and no dust. The cable from the release panel to the exit panel passes behind the tank at waist height, which is fine.
- **FINE: the phone's bait route.** `M-0196`-`M-0200`: "Wait for WOLF to park it on the mark." then "USE: drop the tank. It's parked on the mark." with the button relabelled DROP. Very clear. A newcomer can't really fail it. (WOLF does seem to get from the mark to the far hatch in about a second, `M-0198` → `M-0200`, passing the sentry. I'm guessing at the route.)
- **MUST-FIX: the hatch door vanishes, and WOLF vanishes.** `D-0250-t0192.6-dialogue-the-bolt-arcs-and-drops.png` → `D-0253-t0193.8-dialogue-service-line-cleared-wolf-it.png`. The bolt "arcs" as a **mint-green puff** (the same odd green as the Records exit), and then the round hatch door is simply gone, with a corridor behind it. Where did the door go: slide, swing, roll? Then in `D-0263-t0203.4-t.jpg` WOLF is gone from the room while Rowan stands at the hatch. Maybe he walked through first, but I never see it. The end card then fades in without my seeing either of them go through.
- **FINE: Pause works and doesn't punish.** `D-0172-t0142.0-overlay-pause.png`: RESUME / SETTINGS / RETURN TO TITLE, plus "Returning keeps your last checkpoint. Unsaved progress will be lost." That's honest and clear.
- **FINE (corrected): the Pause and Settings panels are solid.** `D-0172` caught the pause panel mid fade-in, so the room shows through it. By `D-0177-t0142.0-overlay-pause.png` it is solid and easy to read.
- **SHOULD-FIX: the Settings words are for engineers.** "THE DEN / LOCAL CONFIGURATION" and "GPU: llvmpipe (LLVM 15.0.6, 128 bits) / Renderer: Compatibility" (`D-0173-t0142.0-overlay-settings.png`) mean nothing to me; "Edge smoothing" and "V-SYNC" neither. Under the DISPLAY tab on my laptop it also says "Window size is OS-managed on mobile." I'm not on mobile, so that line just confuses me. The CONTROLS tab (`D-0176-t0142.0-settings-tab-2.png`) is the clearest page and is fine.

## 6. End card and back to title (204-208 s)

- **FINE (corrected): the end card is easy to read.** On my first pass I marked it unreadable from `D-0264-t0204.0-overlay-endcard.png` and `M-0221-t0167.8-overlay-endcard.png`. Those are the first frame of its fade-in, with the room's labels showing through. One second later it is a solid panel with clear text (`D-0265-t0205.0-t.jpg`, `D-0266-t0206.0-t.jpg`, `M-0222-t0168.8-t.jpg`). For a fraction of a second "THIS RUN" sits on top of "DOOR DOWN", but I doubt anyone would notice while it moves.
- **FINE.** The idea of "THIS RUN: RELAY / MIRROR / LANE" with one sentence each is great for me as a newcomer. It confirmed my choices mattered. "Thank you for playing this early slice." is a nice touch. Back on the title, PLAY AGAIN with "Slice complete. PLAY AGAIN starts a fresh run." is clear (`D-0269-t0208.3-title-after-end-card.png`).

## 7. Things that look odd, fake, stuck on or floating (all in one place)

| What | Frames | Mark |
|---|---|---|
| Records exit turns into a flat navy rectangle with a grey border | `D-0150`, `D-0159`, contact sheet `desktop-04-records-p2.png` | MUST-FIX |
| Doors that open *into* the back wall while I walk past sideways (corridor seal, junction sealed door) | `D-0102`, `D-0106`, `D-0200`, `D-0205` | MUST-FIX |
| Door panels that just vanish when opened (corridor seal, junction hatch) | `D-0101`→`D-0102`, `D-0250`→`D-0253` | MUST-FIX |
| WOLF standing inside machines (valve, door frame, relay, bypass wheel) | `D-0106`, `D-0205`, `D-0213`, `D-0240`, `M-0082`, `M-0084`, `M-0089`, `M-0188` | MUST-FIX |
| Flat beige/tan blob used for dust, steam and blasts | `D-0022`, `D-0102`, `D-0186`, `D-0200`, `M-0169` | MUST-FIX (it's in every big moment) |
| Mint-green puffs for door/bolt "arcs" | `D-0148`, `D-0250` | SHOULD-FIX |
| "M"-shaped zig-zag for WOLF's surge | `M-0084` | SHOULD-FIX |
| Manual bypass wheel on a thin pole, like a sign | `D-0080`, `D-0095`, `M-0082` | MUST-FIX |
| Purge display console perched on a column at head height | `D-0048`, `M-0070` | SHOULD-FIX |
| Floating knockdown bodies | `D-0186`, `D-0226`, `M-0169` | SHOULD-FIX |
| Tank lands with no dent, tilt or dust (the sentry does read as crushed) | `D-0243`, `D-0246`, `D-0263` | SHOULD-FIX (small) |
| Sentry drives through Rowan | `D-0222` | SHOULD-FIX |
| Rowan standing on the bypass wheel / in front of panels instead of using them | `M-0082`, `D-0240` | SHOULD-FIX |
| End card and pause panels see-through: corrected; those frames are mid-fade and the panels are solid 1 s later | `D-0264`→`D-0265`, `M-0221`→`M-0222`, `D-0172`→`D-0177` | FINE |
| Lighting, walls, pipes, wet floor, machine art in general | all rooms | FINE, looks real and consistent |

## 8. Every door and opening, as a newcomer sees it

| Door | Where it goes? | How it opens | Where the door goes when open | Verdict |
|---|---|---|---|---|
| WOLF's cage (opening) | Nowhere; WOLF steps out sideways | "Gate slides aside": bars squash to the left | Bars stay as a strip on the left; the cage is see-through | MUST-FIX (`D-0022`, `D-0024`) |
| Corridor "red seal" | A corridor going into the screen, but I never use it; I walk past to a save point | Instantly | Disappears | MUST-FIX (`D-0080`, `D-0102`, `D-0106`) |
| Corridor → Records | Pressed E at a *save terminal* ("enter records access") | Cut | n/a | SHOULD-FIX: I expected to walk through the seal |
| Records exit | "Service line toward Archive" | Green puffs, an outline box appears | Replaced by a flat navy rectangle | MUST-FIX (`D-0148`, `D-0150`) |
| Junction entrance hatch (left) | Where I came in, presumably | Never shown opening | n/a | FINE (reads as "I came in here") |
| Junction "sealed door" | A corridor into the screen I never enter; my path continues right | Blown up, but the door still stands in its frame | Stays, cracked and burning | MUST-FIX (`D-0200`, `D-0205`) |
| Junction exit hatch (right) | Toward Archive | Bolt "arcs" (green puff) | Disappears | MUST-FIX (`D-0250`, `D-0253`) |

## 9. Does WOLF feel like a real companion?

- **FINE, and the best part.** He has a will of his own. He refuses the Director (`D-0031`). He refuses me when I dodge his question (`D-0070`, `D-0080`: "I said no. I won't touch it blind. The bypass is right beside it."). He tells me what he thinks afterwards ("You found another way. Next time, tell me what it costs.", `D-0106`). He **remembers** it in the next room ("I refused the live relay; I'm still here.", `D-0116`). He holds it against me at the sentry ("At the relay you'd have sent me in blind. I won't walk into its sights.", `D-0213`). When I was honest, he thanks me ("Thank you for telling me. I'll take the relay.", `M-0070`) and later trusts me with the bait ("You told me the truth at the relay.", `M-0198`). As a newcomer this is what made me care.
- **SHOULD-FIX: the quoting sounds robotic.** "You said "Go now. We can talk after." I refused." (`D-0106`) and "You said "The relay may vent coolant. Your call." I chose the relay." (`M-0089`). Reading my menu line back word for word feels like a computer log. (Maybe that's on purpose because he's a robot, but it reads like the game checking a box.)
- **MUST-FIX (visual): he doesn't feel physically present** because he stands inside the machines (section 7). Also, in the junction he "runs ahead to the valve" in text while staying put in the picture (`D-0165`), and he disappears before the end (`D-0263`).
- **Can't judge from stills:** whether he looks at Rowan, idles, wags, reacts to the alarm or the blast. In every frame he's in the same walking pose, side-on. If he never turns his head toward Rowan when talking, that would make him feel less alive. That's a guess.

## 10. Controls and prompts

- **FINE (desktop).** "A / D MOVE", "E" to use, "HOLD E" to crank, number keys for choices (`D-0048`, `D-0090`, `D-0062`). The hint bar always says the exact key and the exact verb ("E: arm the overload breaker.", `D-0169`). Very newcomer-friendly.
- **SHOULD-FIX (phone): the hint and the button disagree.** The button says CRANK or DROP while the hint says "HOLD USE: crank the valve" (`M-0164-t0129.1-hint-hold-use-crank-the-valve.png`) or "USE: drop the tank" (`M-0200`). On the corridor WOLF route the button turns to CRANK while the hint says "WOLF is moving to the contact" (`M-0082`), which made me think I was supposed to crank.
- **SHOULD-FIX (phone): choice buttons still show "1" and "2"** (`M-0062-t0052.3-choice-relay.png`, `M-0188`). That's keyboard thinking on a touch screen. They also sit at the top of the screen, away from my thumbs, while the move and USE buttons vanish.
- **SHOULD-FIX (phone): the touch buttons sit on the play space.** The USE/CRANK button covers part of the right floor, including the cyan alcove box and the yellow bracket at the junction's right edge (`M-0148`, `M-0164`). The ◀ ▶ buttons cover the bottom of the purge console (`M-0121`). The USE button also overlaps the end of the hint bar (`M-0052-t0044.4-tutorial-tap-use-read-display-optional.png`, every phone frame).
- **SHOULD-FIX (phone): black bars.** 240 px of black at each side on a 20:9 phone (every M- frame), while the bottom third is filled with buttons and text. The actual scene feels small.
- **FINE (phone): the DEBUG button** (every M- frame) is a debug-build thing according to the capture notes. I'm ignoring it.
- **SHOULD-FIX: "TAP USE READ DISPLAY (optional) / Or head right to the breaker."** (`M-0052`). Reads as a grammar slip ("TAP USE" then "READ DISPLAY" run together).

## 11. Is the text readable and not too long?

- **FINE: size and contrast on desktop** for the dialogue and hint bars (`D-0062`, `D-0213`). White on dark navy, a good size at 1280x720.
- **MUST-FIX: too many proper nouns for a newcomer in 3 minutes.** Counting from the frames: Director, WOLF, Rowan, standby, containment seal, maintenance, purge display, original program logs, source record, breaker, coolant relay, coolant fault, live contact, manual bypass, red seal, safe point, records access, purge queue, purge-order trace, target ID, mirror port, mirror index, readout, maintenance port, timestamp, first copy, Archive, the source, service line, overload breaker, relief vent, LINE gauge, valve, fuse, sealed door, rubble, lane, sentry, tank release, alcove, posts, floor mark, brackets, winch, exit bolt, hatch. That's more than 40 named things. I was fine with the ones I could *see* (breaker, valve, tank, hatch). I was lost on the ones I couldn't (mirror index, purge-order trace, the source, Archive).
- **SHOULD-FIX: old dialogue never clears.** The bottom box keeps the last line for a long time while I walk and do other things: "The Director's purge order has a time and target ID..." stays for about 8 s in Records (`D-0120` to `D-0130`), "FIRST COPY SECURED..." for about 16 s (`D-0148` to `D-0164`), and the closing line for about 10 s before the end card (`D-0253` to `D-0263`). With the hint bar right above it, I'm reading two boxes all the time.
- **SHOULD-FIX: some lines run to two lines and carry three ideas.** "The latch breaks from the inside. The gate slides aside. WOLF steps out under his own power. The Director freezes at the sound of the seal opening." (`D-0022`). "WOLF: At the relay you'd have sent me in blind. I won't walk into its sights. Time the drop from the panel; it crosses the mark on every pass." (`D-0213`). Readable, but a newcomer will skim them, and the second one hides the actual instruction (time the drop) at the end.
- **FINE: the objective card** (top-left: "SERVICE JUNCTION / DROP THE TANK") is short and always right.

## 12. Where I would quit

1. **Most likely: the junction sentry, after the second knockdown** (`D-0226`). I'd have been knocked down by the door blast first (about 1 s to react, `D-0185`→`D-0186`), then killed by the sentry with a message about "the alcove's right post" I can't find on screen. Two failures in a row and an instruction I can't map to the picture would be my stopping point. Time spent there in this run: about 50 s from entering the junction to the second knockdown. A real newcomer would take longer.
2. **Possible: the opening.** About 38 s of reading before I can move (`D-0004` to `D-0047`), with a nearly still picture. If I'd come in expecting "a game", I might close it here. If I'd come in expecting "a story", I'd stay.
3. **Not a quit point, but a "huh?" point:** the Records exit turning into a navy box (`D-0150`). I'd keep going, but I'd stop trusting the game looks finished.

## 13. Summary lists

**MUST-FIX**
1. Doors that open into the back wall while the path goes sideways past them (corridor seal, junction sealed door): `D-0102`, `D-0106`, `D-0200`, `D-0205`.
2. Door panels that vanish when "opened" (corridor seal, junction hatch): `D-0101`→`D-0102`, `D-0250`→`D-0253`. The Records exit becoming a flat navy rectangle: `D-0150`, `D-0159`.
3. WOLF standing inside machines (valve, door frame, relay, bypass wheel) for long stretches: `D-0106`, `D-0205`, `D-0213`, `D-0240`, `M-0082`, `M-0084`, `M-0089`, `M-0188`.
4. The flat beige blob used for every dust, steam and blast effect: `D-0022`, `D-0102`, `D-0186`, `D-0200`, `M-0169`.
5. The manual bypass that looks like a wheel on a sign pole: `D-0080`, `D-0095`, `M-0082`.
6. The fuse window of about 1 s, judged from frame times: `D-0185`→`D-0186`, `D-0199`→`D-0200`, `M-0168`→`M-0169`.
7. "Alcove" and "posts" that I can't see on screen in the sentry warnings and failure text: `D-0222`, `D-0226`.
8. Four text boxes and about 60 words on the first controllable frame: `D-0048`.
9. More than 40 named things in 3 minutes; the goal ("first copy", "source", "Archive") never becomes concrete: `D-0120`, `D-0148`, `M-0121`.

**SHOULD-FIX**
- WOLF barely visible in the cage, and no visible "blue light": `D-0004`, `D-0014`.
- Rowan not shown in the opening: `D-0048` is the first sighting.
- The opening is long and still: `desktop-02-opening-p1.png`.
- The breaker choice wording hides what option 2 means: `D-0062`, `D-0070`.
- The mirror choice has no visible stakes: `D-0131`, `M-0113`.
- "COOLANT FAULT" never clears: `D-0106`, `M-0089`.
- The purge console perched at head height on a column: `D-0048`.
- The junction narration says WOLF ran to the valve; the picture shows him at the breaker: `D-0165`, `M-0148`.
- The label row reads like a diagram; "SPENT" and "BOLTED" wording; faded labels: `D-0165`, `D-0243`.
- Floating knockdown bodies: `D-0186`, `D-0226`, `M-0169`.
- The sentry drives through Rowan: `D-0222`.
- The tank lands with no dent or dust, and the landing is a soft blue glow: `D-0243`, `D-0246`.
- "Secure the first copy" is pressed at the EXIT pod: `D-0147`.
- The green puffs and the "M" lightning: `D-0148`, `D-0250`, `M-0084`.
- WOLF vanishes before the walk-out, and nobody is shown going through the hatch: `D-0263`.
- WOLF quoting my menu line word for word: `D-0106`, `M-0089`.
- Phone: button labels and hint labels disagree, "1/2" on touch choices, buttons covering the floor, black side bars: `M-0164`, `M-0200`, `M-0082`, `M-0062`, `M-0148`, `M-0121`.
- Old dialogue lingers on screen: `D-0120`-`D-0130`, `D-0148`-`D-0164`.
- Settings jargon: "THE DEN / LOCAL CONFIGURATION", the GPU line, and "Window size is OS-managed on mobile" on a laptop: `D-0173`.
- Title art scale versus in-game scale: `D-0003` vs `D-0048`.

**FINE**
- The title screen and its save hint: `D-0003`, `M-0003`.
- The machine labels so I always know where to walk: `D-0080`.
- The crank meter, and progress holding when I let go: `D-0095`, `D-0097`.
- Clear hint verbs and keys on desktop: `D-0169`, `D-0090`.
- Quick, explained retries after a knockdown: `D-0187`, `D-0227`.
- The phone bait route's "Wait for WOLF to park it on the mark": `M-0198`, `M-0200`.
- WOLF's will, memory and consequences across rooms: `D-0070`, `D-0106`, `D-0116`, `D-0213`, `M-0070`, `M-0198`.
- Pause menu wording: `D-0172`. The Controls tab: `D-0176`.
- The end card: a solid, readable "THIS RUN" summary of my choices: `D-0265`, `M-0222`.
- The overall background art, lighting and wet-floor look: all rooms.

---

*Credits: WOLF//OVERRIDE game, story and characters by Nathanial Henniges. Capture frames and logs come from the earlier scripted capture pass (`../play/INDEX.md`, driver `../driver/play.gd`), rendered in the container with `tools/render/render.sh`. These notes are a newcomer read of those frames, not a hands-on playtest.*
