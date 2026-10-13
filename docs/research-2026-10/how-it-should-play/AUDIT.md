# Playthrough audit: what a first-time player meets

WOLF//OVERRIDE is an original game and story by **Nathanial Henniges**. This audit merges three first-time-player reviews of one scripted capture of the slice into a single, de-duplicated list, ranked by how much each problem would hurt a first-time player. Round 2 (2026-10-13) adds eight findings (41-48) from four new captures and headless press probes: failures, the front end, a controller and display sizes.

**Material:** the scripted capture at `baffea4` ([CAPTURE-ROUND1.md](playthrough/CAPTURE-ROUND1.md)): desktop route D (1280x720, keyboard, 269 frames, 208 s) and phone route M (2400x1080, touch, 226 frames, 172 s), rendered in a container with `tools/render/render.sh`. The game code at `da5c14e` is identical.

**Reviewers** (full notes in [human/](human/)):
- **N**: a newcomer who rarely plays games ([human/newcomer.md](human/newcomer.md)).
- **G**: a genre fan of INSIDE, LIMBO, Little Nightmares and Stray ([human/genre-fan.md](human/genre-fan.md)).
- **P**: a phone player, landscape, two thumbs, short sessions ([human/phone.md](human/phone.md)).

**What this is not.** These are still frames of scripted input, with no audio and no real phone. Anything about motion, timing or feel is a guess from frame times and is marked "(guess)". The two failures in the desktop run (standing in the blast, walking into the sentry's sight) were planned by the script. Nothing here validates game feel; that needs hands-on play (NEEDS.md, TEST).

**How it is ranked.** Tier 1 would make a first-time player quit. Tier 2 breaks their trust that the place is real. Tier 3 confuses or slows them. Tier 4 is phone-only. Tier 5 is polish. Inside each tier the most harmful comes first. Frame names: `D-` desktop, `M-` phone (files in the capture's `frames/` folders, the cited ones kept as WebP in [playthrough/](playthrough/README.md)).

---

## Tier 1: would make a first-time player quit

### 1. About 40 seconds before the player can move, in a near-still scene without the player character
- **Seen by:** N, G, P (each named it a top quit risk; G and P put it first).
- **Frames:** D-0004 to D-0047, M-0004 to M-0046; first control at t = 40.9 s in both logs. Six of twelve 1-second frames between 7.8 and 18.8 s look the same (contact sheet `desktop-02-opening-p1`).
- **What happens:** 7 text boxes (~93-96 words; main.gd:90-98) over a still shot of the Director and the cage. The engineer never appears, so N thought they might be playing the Director. P would be "mildly bored from about 15 s in" on a phone.
- **Breaks:** TEACH-1, PACE-3, STORY-11. **Ask:** Q2.

### 2. The sentry's warning and knockdown card name things nobody can see
- **Seen by:** N (their most likely quit point), G.
- **Frames:** D-0203, D-0222, D-0224, D-0226; code junction_room.gd:213.
- **What happens:** "Get into the release alcove or back over the rubble", then "The sentry spotted Rowan past the alcove's right post ... Keep inside the posts". On screen the "alcove" is a faint cyan floor rectangle with two thin uprights, and the "rubble" is a few glowing shards. After two failures in a row with advice they cannot map to the picture, N would stop.
- **Breaks:** TEACH-5, FAIL-1, PUZ-5.

### 3. The door blows about one second after "FUSE LIT"
- **Seen by:** N (MUST); G calls the blast fair because WOLF warns first and the zone is striped.
- **Frames:** D-0185 (144.6 s) to D-0186 (145.8 s); D-0199 (151.7 s) to D-0200 (152.7 s); M-0168 to M-0169. Code: `FUSE_SECONDS` 1.0 (pressure_line.gd:10).
- **What happens:** the warning "FUSE LIT. Back away from the door, past the valve." (9 words, ~3 s to read) is still being read when the door goes. Both reviewers agree the retry is quick and the card explains the cause. (Timing from frame times.)
- **Breaks:** FAIL-4, TEACH-3. **Ask:** Q13.

### 4. A wall of text on the first frame the player controls
- **Seen by:** N, G, P.
- **Frames:** D-0048, M-0047, M-0052, M-0053.
- **What happens:** a name card, a tutorial box, a hint bar, a 3-line, 267-character dialogue box with three speakers, the PAUSE button and three world labels: G counts eight text elements, N about 60 words. P: "I'd skip most of it and just press ▶." The phone tutorial reads "TAP USE READ DISPLAY (optional)".
- **Breaks:** TEACH-7, STORY-3, STORY-4.

---

## Tier 2: breaks the player's trust that the place is real

### 5. Doors that open into the background while the path goes sideways past them
- **Seen by:** N, G, P (all MUST).
- **Frames:** corridor seal D-0080 → D-0102 → D-0105 → D-0106, M-0081 → M-0086 → M-0089; junction sealed door D-0168 → D-0200 → D-0205, M-0148 → M-0186 → M-0188.
- **What happens:** both doors are free-standing frames angled into the back wall. When they open, a tunnel going into the screen appears, and the player then walks sideways past it. "Why did I blow this door?" has no visual answer (G). Records is entered from the safe-point console, with no door (D-0106; P: "where is Records?").
- **Breaks:** SPACE-1, PUZ-1, PACE-4. The approved fix already exists: a shutter across the corridor (decided October 11, on hold until redone under the REAL-LOOK rules).

### 6. Doors that vanish, and a Records exit that turns into a flat rectangle
- **Seen by:** N, G, P (all MUST; N calls the Records exit "the single most fake-looking thing in the slice").
- **Frames:** seal leaf gone D-0101 → D-0102, M-0086; junction hatch panel gone D-0250 → D-0253, M-0208; Records EXIT pod → green puffs → flat navy rectangle with a mint bar D-0147 → D-0148 → D-0150 / D-0157, M-0131 → M-0132 → M-0142.
- **Code:** the seal swaps textures and hides its leaf (main.gd:46-52, `seal_leaf.hide` at main.gd:3008).
- **Breaks:** SPACE-2.

### 7. WOLF stands inside machines, door frames and the engineer
- **Seen by:** N (MUST), G, P.
- **Frames:** on the bypass wheel D-0105, D-0106; half inside the relay M-0082, M-0084; tail through the seal frame M-0089 to M-0097; inside the valve and blown door frame for ~35 s D-0205, D-0213, D-0240, M-0188; the engineer drawn inside WOLF M-0196; in front of the exit hatch D-0246, M-0208, M-0210.
- **What happens:** "makes him look like a cut-out sticker rather than something physically there" (N). Code: authored WOLF spots bypass the machine-avoidance logic (e.g. `WOLF_RUBBLE_X` 448, junction_room.gd:123; `off_machines`, m0_actor.gd:130-145).
- **Breaks:** WOLF-2.

### 8. The ending: nobody walks out, and WOLF blinks out of existence
- **Seen by:** P (MUST, corrected on the second pass from the log), N.
- **Frames:** M-0208 (USE "leave through the hatch" fires while the engineer is at the bolt console), M-0210 to M-0219, M-0220 (WOLF gone; the log still has him at x 902, hidden in place), M-0221 (card fades in before the engineer reaches the hatch); D-0253 → D-0263 → D-0264.
- **What happens:** the last thing the player sees of their companion is him disappearing. The code intends a fade in the doorway (main.gd:98-106), but it reads as a vanish.
- **Breaks:** WOLF-4, PACE-9, PACE-2.

### 9. Things that float or hang on nothing
- **Seen by:** N, G, P.
- **Frames and code:**
  - the MANUAL BYPASS: a wheel in a ring on a thin post with a tiny foot, tied to the relay by a hairline (D-0080, D-0095, M-0082; crop `human/crops/d095.webp`). G: "exactly the 'hovering item that looks odd' Nathanial asked about";
  - the purge console at head height on a column in the corridor, but standing on the floor in Records (D-0048, M-0047, M-0070 vs D-0116, M-0098);
  - a thin line in mid-air at chest height across the junction from TANK RELEASE to the bolt console, grey, then yellow, then cyan (M-0188, M-0198, M-0200, M-0202, M-0208), also running through the dropped tank (D-0246, D-0253);
  - contact shadows are drawn (a soft 12 px ellipse at ≤ 0.5 alpha, floor_reflection.gd:98-114) but read as a "blue selection bar" (G, D-0048) or a "stray light bar" (P, M-0110, M-0154), not as contact.
- **Breaks:** SPACE-3, SPACE-4, SPACE-7.

### 10. The knocked-down body hangs in the air
- **Seen by:** N, G, P (G and P MUST).
- **Frames:** D-0186, D-0226, M-0169. Code: the standing sprite is rotated 70° and shifted (main.gd:195-196).
- **What happens:** these are the frames that sit under the failure message. G: "the one image a streamer would clip and laugh at".
- **Breaks:** SPACE-3.

### 11. One soft blob for every effect
- **Seen by:** N (MUST: "in every big moment"), G, P.
- **Frames:** beige blob at the cage, seal and blast (D-0022, D-0102, D-0103, D-0186, D-0200, M-0022, M-0086, M-0169, M-0183); hard-edged pale rectangle for the coolant hiss (D-0092 to D-0101); a yellow smear over the engineer's head and a chevron "M" glyph while cranking (D-0101, crop `human/crops/d101.webp`); the same "M" zigzag for WOLF's surge (M-0084); a round cyan glow ball for the tank impact (D-0243, M-0202); mint puffs for the bolt and the Records exit (D-0148, D-0250).
- **Breaks:** SPACE-9.

### 12. A placeholder cage is the first object anyone sees
- **Seen by:** N, G, P (all MUST).
- **Frames:** D-0004, D-0014, D-0022, D-0024, M-0004, M-0024; the empty frame stays (M-0031, M-0041).
- **What happens:** flat grey boxes with a lid in a different perspective, on a painted wall; on release the bars bunch into a strip. The decided replacement (a standby dock in a guarded bay, design C, October 11) is not built.
- **Breaks:** SPACE-7.

### 13. Solid things pass through each other
- **Seen by:** N, G, P.
- **Frames:** the sentry rolls through the engineer's legs (D-0222); the sight beam runs through the bolt panel (D-0222); in the phone bait run WOLF ends up past the sentry in a corridor with no room to pass (M-0198 → M-0200, under 2 s; guess on motion); the cable runs through the tank and the sentry (D-0246).
- **Breaks:** SPACE-8, WOLF-4.

---

## Tier 3: confuses or slows the player

### 14. The engineer never touches what they use, and WOLF's abilities are told, not shown
- **Seen by:** N, G, P.
- **Frames:** cranking with arms at the sides beside the wheel (D-0095, M-0164, M-0167); WOLF's surge is a decal over him standing inside the relay (M-0084); his readout is never shown (M-0121); "WOLF runs ahead to the valve" while he stands at the breaker (D-0165, M-0148; main.gd:220).
- **Breaks:** FEEL-5, WOLF-7, STORY-7.

### 15. Too many named things, and a goal that never becomes concrete
- **Seen by:** N (MUST: 40+ named things in ~3 minutes), P, G.
- **Frames:** D-0120, D-0131, D-0148, M-0102, M-0113, M-0121, M-0131.
- **What happens:** "purge-order trace", "mirror index", "first copy", "the source", "Archive". N: "I just pressed E on the glowing thing." P could not explain the mirror choice.
- **Breaks:** TEACH-5, STORY-11.

### 16. The narration describes things the picture does not show
- **Seen by:** N, G.
- **Frames:** "A blue light answers from inside the containment seal" with no visible light (D-0014); "The Director freezes" with no change (D-0022; guess on animation); "Blue light fills the coolant relay" barely visible (D-0075); WOLF "heads for maintenance" by walking left into his open cage and standing there 4 s (D-0041 to D-0046).
- **Breaks:** STORY-7, TEACH-10.

### 17. The relay choice's second option hides what it means; the mirror choice is blind
- **Seen by:** N (felt "slightly tricked"), G (picked "on tone, not knowledge"), P (the relay choice is fine; the mirror choice is not).
- **Frames:** D-0062, D-0070, D-0131, M-0113, M-0121.
- **What happens:** "Go now. We can talk after." means not telling WOLF the risk, which he then holds against the player. "USE WOLF'S READOUT / USE MANUAL PORT" gives no hint of what each changes, though WOLF's readout reveals more (M-0121 vs D-0139).
- **Breaks:** STORY-5. **Ask:** Q14.

### 18. Labels over every machine, changing to state words
- **Seen by:** G (MUST: "a developer overlay was left on"); N (FINE: "I always knew what to walk to"); see "Where the reviewers disagreed".
- **Frames:** D-0062, D-0095, D-0165, D-0186, D-0243, D-0250, D-0253; faded labels hard to read (RELIEF VENT, D-0226, D-0243); jargon "SPENT", "BOLTED" (D-0243).
- **Breaks:** PUZ-2, PUZ-3, TEACH-5. **Ask:** Q4.

### 19. Dialogue holds the player still or lingers long after it is read
- **Seen by:** N, G.
- **Frames:** ~16 s standing at the Records exit (D-0148 to D-0164); old lines stay up 8-16 s (D-0120 to D-0130; D-0253 to D-0263).
- **Breaks:** STORY-8, PACE-3.

### 20. Several voices crammed into one box; long lines
- **Seen by:** P, N, G.
- **Frames:** "FIRST COPY SECURED. WOLF: ... ROWAN: ..." (D-0150, M-0131); M-0031, M-0089, M-0210. Longest lines are 23-29 words (main.gd:136-147, :220); BAIT_NO_LINE hides its instruction at the end (D-0213).
- **Breaks:** STORY-4, STORY-10.

### 21. Hint-bar noise and three text channels saying the same thing
- **Seen by:** G, N.
- **Frames:** "Checkpoint saved." appears as the hint 17 times (log count; D-0116, D-0120, D-0157); the objective card and hint repeat each other (D-0187); "WOLF refused the live contact" reads like a system log (D-0079).
- **Breaks:** TEACH-6, TEACH-7.

### 22. "Secure the first copy" happens at the EXIT, then a second press leaves
- **Seen by:** N.
- **Frames:** D-0147, D-0148, D-0159.
- **Breaks:** PUZ-1, STORY-8.

### 23. WOLF repeats the menu line word for word
- **Seen by:** N, G, P.
- **Frames:** "You said "Go now. We can talk after." I refused." (D-0106); "You said "The relay may vent coolant. Your call." I chose the relay." (M-0089). G: "A person would say 'You rushed me.'"
- **Breaks:** WOLF-14.

### 24. WOLF is parked in one pose
- **Seen by:** G, P, N (all from stills; guess on idle animation).
- **Frames:** desktop-03-corridor-p2 and desktop-05-junction-p2 contact sheets; M-0089, M-0098, M-0130, M-0148, M-0200. No walk cycle or idle animation exists in code (one still sprite per character).
- **Breaks:** WOLF-13, STORY-12, FEEL-2.

### 25. A stale "COOLANT FAULT" tag
- **Seen by:** N, P.
- **Frames:** D-0106, M-0089, M-0093 (the tag stays after the relay is handled; bypass_handle.gd:101).
- **Breaks:** PUZ-7.

### 26. The sentry's facing is unclear
- **Seen by:** G.
- **Frames:** D-0213, D-0222 (the sight cone points right while the red light is on the left), D-0224.
- **Breaks:** FAIL-1.

### 27. The relief vent arrives without an introduction
- **Seen by:** N.
- **Frames:** D-0179 ("Relief vent. Get off the grate before the gauge peaks." while walking past).
- **Breaks:** TEACH-2.

### 28. The retry silently resets the breaker
- **Seen by:** P (FINE, with a note).
- **Frames:** M-0170, M-0172 to M-0182 (~5 s of redo).
- **Breaks:** FAIL-3.

### 29. Entries and guide lights that are not there
- **Seen by:** G, P.
- **Frames:** the engineer arrives at Records' bare left edge (D-0116); "Follow the station lights" points at lights P could not pick out (M-0110).
- **Breaks:** SPACE-6, SPACE-11.

---

## Tier 4: phone only

### 30. Choice buttons jump to the top of the screen, out of thumb reach, with keyboard numbers
- **Seen by:** P, N, G.
- **Frames:** M-0062, M-0113, M-0188 (the arrows and USE disappear while a choice is up).
- **Breaks:** PHONE-3.

### 31. Small text, and a hint bar that runs under USE
- **Seen by:** P, G.
- **Frames:** M-0031, M-0089, M-0131 (dialogue roughly 24-27 px cap height on a 1080 px screen); the hint is cut by USE at M-0186 and runs under it at M-0052, M-0110, M-0130.
- **Code:** label sizes 13-17 px in a 960 × 540 canvas (main.tscn:231-378) ≈ 9.5-12.4 pt on an iPhone 16.
- **Breaks:** PHONE-4, PHONE-7, STORY-3.

### 32. Black bars where the thumbs rest
- **Seen by:** P, G, N.
- **Frames:** every M- frame (240 px each side on 20:9); stretch aspect is the default `keep` (project.godot).
- **Breaks:** PHONE-6.

### 33. The button and the hint disagree
- **Seen by:** P, N.
- **Frames:** the hint says "HOLD USE" while the button says CRANK (M-0164); CRANK shows while WOLF works the relay (M-0081, M-0082).
- **Breaks:** PHONE-3.

### 34. Touch controls cover the play space; characters are small
- **Seen by:** N, P, G.
- **Frames:** USE covers the junction's right floor marks (M-0148, M-0164); ◀ ▶ cover the purge console's base (M-0121); in the opening the floor sits on the dialogue box (M-0024, M-0036); the engineer is ~180 px tall on 1080 px, about 1.2 cm on a 6.5-inch phone (M-0142, M-0200), while the tighter closing zoom reads better (M-0219).
- **Breaks:** PHONE-7, PHONE-13.

### 35. Settings made for a desktop, shown on a phone (and the reverse)
- **Seen by:** P, N, G.
- **Frames:** window size, fullscreen, V-sync and "GPU: llvmpipe ... Renderer: Compatibility" on the phone (M-0157 to M-0159); "Window size is OS-managed on mobile" on the laptop (D-0173); no text-size, text-speed, hold-toggle or touch options (D-0174 to D-0176, M-0159).
- **Breaks:** PHONE-12, A11Y-1, FEEL-4. **Ask:** Q10.

---

## Tier 5: polish

### 36. The tank lands looking new, inside a glow
- **Seen by:** N, G, P. **Frames:** D-0243, D-0246, D-0263, M-0202 (no dent, tilt or dust; the crushed sentry under it does read well).
- **Breaks:** SPACE-9.

### 37. The title art and the game look different
- **Seen by:** N, G, P. **Frames:** D-0003 vs D-0048, M-0003. A large painted engineer and wolf against small sprites (normal for the genre, but the jump is noticed); the credit line on the title is small on a phone (M-0003).
- **Breaks:** none directly; a note for the art pass.

### 38. "They" can be misread early
- **Seen by:** P. **Frames:** M-0047: "Rowan keeps WOLF's systems running. They know what a fault looks like" (main.gd:62), where "They" can read as "the systems". The engineer's they/them pronouns stay; repeating the name fixes it ("Rowan knows what a fault looks like").
- **Breaks:** STORY-10 (wording).

### 39. Floor brackets with no explanation
- **Seen by:** P, N. **Frames:** M-0188, M-0200 (the yellow dashed bracket is "the mark"; the cyan bracket is never explained); "mark", "brackets" and "floor mark" name one thing (D-0240).
- **Breaks:** TEACH-5, A11Y-3.

### 40. Mixed choice styles
- **Seen by:** P. **Frames:** Records answers are ALL-CAPS commands (M-0113); relay and lane answers are spoken sentences (M-0062, M-0188).
- **Breaks:** STORY-5 (consistency).

---

## Round 2 additions (2026-10-13): what the new captures and probes found

Found by the round-2 agent from the new captures ([CAPTURE-ROUND2.md](playthrough/CAPTURE-ROUND2.md)) and headless press probes, not by the three first-time-player reviewers; frames were looked at directly and numbers come from the logs. Ranked into the same tiers.

### 41. (Tier 2) The characters barely separate from the rooms by value
- **Frames:** D-0048, D-0095, D-0116, D-0131, D-0165, D-0205, D-0240 (measured with tools/contrast.py).
- **What happens:** the engineer's median luminance contrast against the background is 1.17-1.59:1 and WOLF's 1.16-1.69:1; the art bible asks ≥ 1.6:1 with the rim side at ≥ 3:1. The engineer reads by the red jacket's hue, WOLF by his cyan seams; in greyscale both sink into the walk band. This is the "cut-out sticker" look reviewers described (item 7), seen from the light side.
- **Breaks:** READ-1, READ-2, SPACE-7.

### 42. (Tier 3) Wrong presses are silent, and the sealed door does not answer at all
- **Frames and probes:** X-0155, X-0160 to X-0179, X-0334; 156 probed presses.
- **What happens:** every invalid press (valve before the breaker, spent valve, DROP too early, spent release) gets a line within 1 frame but no sound and no light. USE beside the sealed door repeats the valve's line, so a second press changes nothing, and 40 s of walking into the sealed door gave no bump, sound or line. The safe-point secure, the purge copy, the mirror answer, the relay answers and the hatch exit are also silent.
- **Breaks:** PUZ-4, SOUND-2.

### 43. (Tier 3) WOLF says no, but his body does not
- **Probes:** 15 choices over routes D, M, X, C.
- **What happens:** his line appears 1 frame after every answer; his body moves only when the answer sends him somewhere. After the lane refusal and "Stay back, I'll time it" nothing in his body changes for 2 s. A refusal reads as text, not as a decision (the Last Guardian lesson: inconsistency "feels like the controls aren't working").
- **Breaks:** WOLF-5, WOLF-11, STORY-19.

### 44. (Tier 3) The relief vent's card names a grate the steam hides; the sentry's beam vanishes for red-weak eyes
- **Frames:** X-0219 (vent knockdown: the grate sits under the same soft glow as the cloud); X-0297 and X-0219 under protanopia and deuteranopia simulation (the red beam turns dark olive on dark blue; "BREAKER TRIPPED" matches the other labels).
- **Breaks:** FAIL-1, A11Y-3, SPACE-9.

### 45. (Tier 3) A controller player cannot reach BACK in Settings, and the prompts are letters
- **Frames:** C-0185, C-0187; C-0052, C-0069, C-0098.
- **What happens:** in Settings › CONTROLS the D-pad cycles the rebinding rows, the deadzone slider and RESET and never reaches BACK (B does close it). Prompts read "A", "X", "Y", "START", which are wrong on PlayStation and Switch pads.
- **Breaks:** CTRL-1, CTRL-2.

### 46. (Tier 3) The front end hides two things a player needs
- **Frames:** F-0003 (no QUIT on the desktop title), F-0030 → F-0261 (Pause in the opening offers SKIP OPENING, but nothing says so), F-0185 (CONTINUE does not say where it resumes).
- **Breaks:** MENU-2, MENU-3, TEACH-1.

### 47. (Tier 4) On an iPad a quarter of the screen is black and the buttons sit mid-screen
- **Frames:** S-0056, S-0172 (2732 × 2048: 256 px bars top and bottom; ◀ ▶ and USE in the middle third, away from where thumbs rest); S-0057, S-0180 (2556 × 1179: 230 px bars each side).
- **Breaks:** PHONE-6, PHONE-16.

### 48. (Tier 5) 16:10 desktops and the Steam Deck get letterbox bars
- **Frames:** S-0063 (1280 × 800: 40 px top and bottom), S-0064 (1440 × 900: 45 px), S-0066 (2560 × 1600: 80 px): 10% of the screen each time.
- **Breaks:** DISPLAY-1.

### Round 2: works, keep it
- **Flashes are under WCAG's thresholds** on the fuse and blast (the worst 10° window flashes over 10.2% of its area against a 25% limit; no red flash), and Reduced Motion cuts the stripes' transitions from up to 20 to ≤ 7 per pixel per second (burst sequences).
- **Focus loss pauses at once** and freezes the fuse (X-0266, X-0267).
- **Continue is honest:** quitting mid-junction returns to the junction entry with a line saying to arm the breaker again (F-0182 → F-0188); New Game keeps the old save until the first safe point (main.gd:574-575).
- **A controller works end to end:** A, X, Y, START and B do what Apple's conventions expect; holding A cranks; rumble fires on the big beats; analog tilt walks proportionally (route C).
- **Android Back** walks out of overlays one step at a time and quits only from the bare title (main.gd:1452-1469).
- **The logo is short** (2.0 s) and the title is up by 2.25 s.
- **Every knockdown card says what happened and what to do**, and four of five name a visible cause (FAIL-1).

## What works: keep it

- **WOLF's will and memory.** He refuses the Director (D-0031), refuses a rushed request (D-0070, D-0080), says what he thinks (D-0106), remembers it a room later (D-0116) and changes how the junction plays (D-0213 vs M-0196 to M-0200). All three reviewers call this the hook. (NEEDS: STORY-5, WOLF-14.)
- **The Service Junction.** The best-looking and most readable room; its entry and exit hatches read as real doors in real walls; the plan is always visible (N, G, P). (D-0165, D-0185, D-0222.)
- **Fair, fast knockdowns.** WOLF warns first, the zone is striped, the card says what went wrong and what to do, and control returns ~1.1 s later at a safe spot (D-0167, D-0185 to D-0187, M-0169 to M-0170). (FAIL-2, FAIL-7.)
- **The phone DROP moment.** "USE: drop the tank. It's parked on the mark." with the button relabelled DROP: the clearest screen in the capture (M-0200).
- **Context labels on the touch button** (CRANK, DROP, CONTINUE) and counted hold prompts ("HOLD E: crank the valve, 1 of 3 turns", D-0183).
- **The crank meter and kept progress** when the hold is released (D-0095, D-0097).
- **The END OF SLICE card's THIS RUN recap**, which shows that choices mattered and invites a replay (D-0265, M-0222).
- **Pause wording** ("Returning keeps your last checkpoint. Unsaved progress will be lost.", D-0177) and the Controls tab (D-0176).
- **The title screen** and its save note (D-0003, M-0003, D-0269).
- **Background art, lighting and wet floors** in every room; Records is the cleanest room (P).

## Where the reviewers disagreed

- **Labels over machines.** N found them the most helpful thing for a non-gamer; G found them the biggest "this is a diagram, not a place" tell. Both can be right: plates on the equipment plus an in-range prompt keep the help and lose the overlay, with an optional labels setting (Q4, PUZ-3).
- **The blast.** G calls it fair (warning, stripes, fast retry); N expects almost every newcomer to be knocked down at least once because the fuse is ~1 s. The fix keeps what G likes and gives N time to react (FAIL-4).
- **Reading volume.** N found the text short and readable line by line; G found the total far too high for the genre. Both measure different things: line length versus total amount (STORY-10, STORY-11).

## Corrections the reviewers made to themselves

- The end card and the pause panel are not see-through: D-0264, M-0221 and D-0172 caught their fade-in; one second later they are solid (D-0265, M-0222, D-0177). (N, second pass.)
- The sentry under the tank does read as crushed (D-0246, D-0263). (N, second pass.)
- WOLF does not walk out first at the end; the log shows him hidden in place (M-0220). (P, second pass.)

## Not judged here

Motion, animation timing, camera feel, input latency, audio (the capture used a Dummy audio driver; round 2 watched SfxBank's players, not the speakers), real phone and iPad hardware, DPI, safe areas, heat, frame rate and frame pacing, fullscreen layout (the container has no window manager), the credits' auto-scroll (not drawn between saved frames), a real controller's feel and rumble. These need hands-on play and device tests (NEEDS.md, TEST, PERF and DISPLAY-3).

---

*WOLF//OVERRIDE, its story and its characters are by Nathanial Henniges (MrDemonWolf, Inc.). The capture and the three reviews were made by AI agents (Claude Code by Anthropic) on 2026-10-12 and 2026-10-13; this merge was compiled on 2026-10-13, and round 2's findings 41-48 were added the same day. Reference games named by the reviewers are named from play memory, not as sources.*
