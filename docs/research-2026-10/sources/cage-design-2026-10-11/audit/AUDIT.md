# WOLF's containment unit on main: audit

Private scratch. Written 2026-10-11 against `main` at `7c19ee2`, in reply to Nathanial asking to "Make sure the wolf cagte design makes sense". It also feeds his new direction: a near-future, machine-run military base with PIN codes ("make it feel more like a furttgrue milialry base like iin skynet"; the Terminator films are a mood reference only, with no names, logos, machines or designs). Nothing here changes the game. Until Nathanial picks a redesign, the cage and the opening stay exactly as they are on main (REAL-LOOK rule 5; "the cage for the wolf should been the same 100% the same before").

## What I looked at and what kind of evidence this is

- **Code, read in full:** `apps/game/scripts/containment_cage.gd` (40 lines); `main.gd` `_new_game`, `_advance_intro`, `_finish_intro`, `_shutter_boom`, `_setup_particles` and the camera functions; the `IntroCage`, `IntroGate`, `IntroDirector`, `Wolf` and `Floor` nodes in `scenes/main.tscn`; `m0_actor.gd` for walk speed; the opening asserts in `tests/m0_scene_test.gd` and `tests/room_depth_test.gd`.
- **Fresh renders:** I exported `7c19ee2` to `game-main/`, imported it twice headless and ran one normal 1280x720 Godot window with `--fixed-fps 60`. The driver is `driver/opening.gd` (scratch only). It pressed New Game, tapped `interact` through all 7 beats, and captured every beat, 13 frames of the gate opening, and copies with the UI hidden. It then set a fixed **audit camera** (zoom 2.6 and 6, not a game camera) for close-ups, with a measuring overlay drawn in world coordinates. That gives 37 shots plus 9 UI-free copies in `shots/`, with the camera transform, gate value, WOLF and Director state for each shot in `shots/_log.json`. The window closed itself (exit 0). These frames match the final2 captures R1-002 to R1-011.
- **Measurements:** `driver/measure.py` (output in `logs/measure.txt`) and the sprite alpha bounding boxes. Annotated crops are in `crops/C01` to `C13`, built by `driver/crops.py`.
- **Not done:** hands-on play, sound listening, export or device tests. The claims below are about geometry, code and still frames. None of them is about feel.

**Scale used throughout:** the engineer sprite is 69.6 world px tall, which is 1.75 m, so **1 m is about 40 world px** (REAL-LOOK §1). Local coordinates are relative to the cage origin **(115, 365)**. World y grows downward.

## 1. What is on screen today (as built)

| Part | Local geometry | World | Real size |
|---|---|---|---|
| Lid | parallelogram (-88,-64) (-78,-73) (98,-73) (88,-64), #3b4b53 | y 292-301, x 27-213 | 4.4 m wide, top at 3.7 m |
| Lid band | rect -88..88, -64..-52, #18242c | y 301-313 | 0.3 m deep beam |
| Posts (2) | 8 x 150 at x -88 and 80, 1 px light line on the left face | x 27-35 and 195-203, y 301-451 | 0.2 m square, 3.75 m tall |
| Bolt dots | r 2 at y -58 and 80 on each post | | fasten nothing visible |
| Lamps (2) | 10 x 22 black housing with a 3 x 14 red bar, y -37..-15 | y 328-350 | 2.25-2.8 m up, red, static |
| Base | rect -88..88, 76..86, #17232a | y 441-451 | 0.25 m plate |
| Gate (`IntroGate`, `shutter = true`, z 3) | 9 bars 6 x 125 at x -72..72 step 18; 3 rails 5 px at y -49, 16, 68 from x -80 to the last bar + 3 | bars y 312-437 | bars 15 cm thick, 30 cm gaps |
| Frame (`IntroCage`, z 4) | everything above except the gate | outer x 27-203 (lid to 213), y 292-451 | 4.4 x 4.0 m |

There is **no back wall, no side wall, no roof panel, no floor pan, no latch, no lock, no track, no hinge, no cable, no dock, no marking and no shadow**. The only moving part is the gate's `opening` value from 0 to 1.

## 2. What does not make sense, as an engineer

**Construction**

1. **The lid uses a different projection from everything else** (C01). The lid shows its top face, receding 10 px right and 9 px up. The posts, rails and base are a flat side elevation with no depth, and nothing else recedes with the lid. The lid top is 3.7 m up and the room's eye is near person height, so a real lid would show its underside if it showed any face at all. The receding edge meets no vanishing point in the room plate (REAL-LOOK checklist 1). The lid also overhangs the right post by 10 px and the left post by none, so it looks pushed sideways.
2. **The unit is a frame with one face** (C06, C10). Once the gate folds you can see straight through to the room plate's tank and pipes. A containment unit that is open at the back, sides and top contains nothing, and a "seal" is impossible on a lattice with no skin.
3. **The bars are not held at either end** (C03). Bars and the bottom rail stop at y 437-438. The base top is at y 441, which leaves a 3 px open strip all along the bottom. There is no top track, bottom guide or hinge anywhere, so nothing holds the gate in the frame.
4. **The gate is not attached on the latch side** (C02). When closed, the rails end at local x 75 (world 190) and the right post starts at 80 (world 195), a 5 px (12 cm) gap with nothing in it. There is no latch, keeper, bolt or lock to break, and no keypad or reader.
5. **The gate's motion is physically impossible** (C05, C06). As `opening` goes 0 to 1, the nine bars converge to a 3.5 px pitch and overlap each other, because they are 6 px wide. The three rigid rails shorten from 155 to 37 px. Rigid rails cannot shorten: a real folding gate is a scissor lattice, and a sliding gate is one leaf on a track. The stack stops inside the frame (world x 38-72), so the clear opening is 123 of the 160 px.
6. **The proportions read as a zoo crate, not a robot enclosure.** At this scale the bars are 15 cm thick at a 45 cm pitch, which is closer to bridge members than cage bars. The 30 cm gaps are about the height of WOLF's head near the muzzle (about 12 px, 0.3 m, measured from the sprite). The interior is 4.0 x 3.2 m for a machine 1.55 m tall: 1.6 m of headroom above his ears, with no reason given for the size.
7. **The surface finish is flat fills** with a single 1 px light line on the posts and rails. No light or shadow from the room's fixtures falls on it. The room plates are painted and lit; the cage is vector-flat. That makes it the least "real" object in the shot.

**Grounding** (C03)

8. **It is not held to the floor.** The base plate is drawn over the floor art at y 441-451, so it sits 1-11 px below the floor collision top (y 440). It has no feet, plinth, anchor bolts into the slab or contact shadow (the script draws no shadow at all). The floor paint itself varies 0.82-1.07 between the near and far bands, so the frame cannot be read as grounded or as floating from the pixels; it just sits there. The Director, 1 m away, gets a floor reflection. The cage gets nothing (REAL-LOOK checklist 4 fails: no contact shadow).

**Does WOLF fit?** (C04)

9. **WOLF's measured sprite:** the opaque box at scale 0.18325 is **115.3 x 61.6 world px**, 2.9 m nose to tail tip and 1.55 m to the ear tip. His back is about 46 px up (1.15 m), his body without the tail is about 89 px (2.2 m), and his muzzle depth near the nose is about 12 px (0.3 m). His collision box is 62 x 34 px.
10. **Standing:** he fits in the 160 x 128 px clear interior with 45 px of length and 64 px of headroom to spare. **Lying down** (about 92 x 24 px, 2.3 x 0.6 m) fits easily. **Turning round** needs a depth of about his body length (2.2-2.4 m). A side elevation cannot show depth, and the fake lid implies only about 0.3 m of depth (10 px in oblique projection). The drawing never tells the player that he could turn.
11. **His pose says nothing about standby.** He stands mid-stride, in the same walking frame used in play, with his feet hidden behind the bottom rail and base plate (feet at y 438.4, base top at y 441). Standby is shown only by darkening the whole sprite (`modulate #365263`).

**Latch, gate, path out**

12. **Nothing breaks from the inside.** At beat 3 the code plays `_shutter_boom()`: a `boom` sample, a 0.09 s white flash, camera trauma 0.6, a rumble, and a 16-particle beige dust burst spread along 140 px of floor (x 45-185, y 438), not at a latch (C09). WOLF does not move, strike or push. The gate then glides with a cubic ease-out over 0.65 s: half open after 0.1 s and 94% after 0.37 s.
13. **The path out does not match the gate** (C07). The gate opens the front face, toward the camera. WOLF waits until the gate is fully open (z swap at 0.65 s), drops his sprite 8 px over 0.28 s, then walks **right** 70 px to x 185 in about 0.3 s, drawn on top of the right post (z 5 over the cage's z 4). On screen he leaves through the side of the frame, where there is a post, not through the opening. The 8 px drop is the only hint that he "steps forward". It puts his feet at y 446.4, on the front lip of the base plate and 6 px below the floor line. At gameplay start his sprite is back at -15, so his floor contact jumps 8 px across the fade.
14. **At beat 3 he ends nose to coat with the Director.** WOLF's opaque right edge reaches x 243.8 and the Director's coat starts at x 245.8, a 2 px gap. Beat 4 then slides the Director back to x 310. This may be intended staging, but the cage gives him no space to come out into.
15. **"The only open route" leads back into the cage** (C10; open problem 20 in the logic audit). At beat 6 WOLF walks **left** to x 110, onto the cage base and over the folded gate stack, toward the left wall where no exit is drawn. The room is open to the right, past the Director. At the beat 4-6 framing (camera x 300, zoom 1.95), the cage's left 27 px are off screen and WOLF's nose touches the frame edge.

**Lamps, light, power**

16. **The lamps never react** (C08, C13). Both post lamps read RGB 204,77,57 in beats 0, 1, 2, 3, 4 and 6. No colour or state change happens when WOLF wakes, when the "latch breaks" or when the gate opens, and nothing says what red means (locked, occupied, armed). The only reaction anywhere is the full-screen red `IntroAlarm` tint (alpha 0.13, then 0.05 from beat 4), a screen overlay rather than a lamp.
17. **The "blue light" is a brighter wolf, not a light** (C08). Beat 2 tweens WOLF's sprite modulate from #365263 to #9deeff in 0.45 s. Inside the same world box his mean RGB goes from 18,32,39 to 26,45,54, about 40% brighter with the same hue. The bars beside him (15,25,32, then 15,25,31) and the floor in front do not change. No light falls on the cage, so nothing "answers from inside the seal".
18. **No power or standby dock reaches him.** There is no cable, umbilical, charging plate, cradle, dock or restraint. Nothing explains how a machine held in standby is kept in standby, or what he wakes up from.

**Continuity**

19. **The unit vanishes** (C11). `_finish_intro` hides `IntroCage` and `IntroGate`. At control start the purge display (texture region 105 x 102 world px, centred at (158, 294.5), so x 105-211, y 243-346) hangs where the cage's upper half was. WOLF stands at x 72 and Rowan at x 160, both inside the old footprint. A broken-open containment unit leaves no trace in the room it stood in.

## 3. What does not make sense, as a first-time player

- "Is that a dog kennel?" It reads as a big animal crate in a boiler room. Nothing says military, robot, dangerous or expensive.
- "What are the red lights?" They look like decoration, because they never change.
- "Was he switched off?" The only cue is that he is darker. The line says "standby", but there is no dock, cable or resting pose.
- "Where's the latch? Where's the seal?" The text names both and the art shows neither. The bang comes from the floor, not from a lock.
- "Why can I see through the back of it?" Once the gate folds, it is an empty frame.
- "He walked through the post." Then "he walked back into his cage." Then "the cage disappeared."
- "Why is the Director standing a metre from a combat robot's bars with no barrier, line or camera?" Nothing shows how the site watches or controls this unit.

## 4. Approved lines versus what is drawn

The text is approved by Nathanial and is not up for change here. The drawing has to come to the text.

| Approved line (beat) | What the screen shows | Mismatch |
|---|---|---|
| "The Director thinks WOLF is still in standby." (1) | Darkened sprite, standing pose, no dock or cable, red lamps | Nothing reads as standby. No standby lamp, no dock, no resting pose |
| "Nobody gives an activation command. WOLF wakes himself." (2) | Sprite brightens and the camera zooms 1.8 to 1.95 | Works as a beat, but the cage does not register it |
| "A blue light answers from inside the containment seal." (2) | Whole-sprite cyan modulate | No light source, no light on the bars or floor, and no seal exists |
| "The latch breaks from the inside." (3) | Boom, flash, shake, floor dust; no latch drawn | Nothing to break, no point of failure, WOLF does not act |
| "The gate slides aside." (3) | Bars converge and overlap, rails shrink | Closest match, but impossible mechanics and no track |
| "WOLF steps out under his own power." (3) | 8 px drop, then a walk right through the post | Exit path contradicts the opening |
| "The Director freezes at the sound of the seal opening." (3) | `boom` sample | An explosion, not a seal (clunk, hiss, motor) |
| "DIRECTOR: You were in standby." (4) | as beat 1 | as beat 1 |
| "WOLF turns from the Director and takes the only open route." (6) | WOLF walks left into the cage footprint | No open route is shown (problem 20, Nathanial's call) |
| Top card "03:17 / CONTAINMENT" (0) | Open-backed crate | "Containment" implies a sealed, controlled unit |

## 5. What the new military direction will need (gap list, not a design)

Today's unit has none of the following. The redesign pass (separate subfolders) should ground each item in real installations, with sources.

- **Armoured enclosure** with a skin (walls, roof, floor pan) rather than a lattice, and viewing apertures where a person needs to see in.
- **Interlocked access hardware on the lock side**: a latch or bolt with a visible keeper (the thing that "breaks from the inside"), a lock status lamp, and a PIN keypad or card reader as part of the lock. **The opening must still play with no code entered.** PIN gameplay is designed separately.
- **A real door mechanism** that matches "slides aside": one leaf on a top track and a bottom guide, parking beside the opening, behind or in front of the frame, not inside the clear width.
- **A standby dock or cradle** with a power or data umbilical, so "standby" and "wakes himself" have hardware to show them: the dock lamp changes and the cable drops.
- **Status lamps that mean something** (sealed, standby, breached), with unlit sockets and a live tinted sprite per REAL-LOOK §2, inside the phone budget of at most 4 persistent glows per room.
- **Anchoring** with a plinth or base frame, anchor bolts into the slab, and a contact shadow.
- **Stencilled equipment and hazard markings and a camera**, kept short and neutral, and listed as proposed for Nathanial. REAL-LOOK checklist 7 currently says "no text in art", so any stencil needs his explicit yes as an exception.

## 6. Hard constraints any redesign must keep

**Nodes and code contract**

- `IntroCage` (`Node2D`, z 4) and `IntroGate` (`Sprite2D` with `containment_cage.gd`, `shutter = true`, z 3), both at **(115, 365)**, both hidden until `_new_game` and hidden again by `_finish_intro` (also reached by Skip Opening) and `_load_game`.
- `opening` is a float clamped 0..1 whose setter calls `queue_redraw()`. Main tweens it 0 to 1 over **0.65 s**, `TRANS_CUBIC` `EASE_OUT`, and snaps it to 1 at beat 4. `m0_scene_test` asserts that `IntroGate` is visible with `opening == 1.0` after 1.2 s of beat 3 and during beat 4, and hidden after the opening. A redesign should keep this one property as the drive, or the test change is part of what Nathanial approves.
- The cage is code-drawn (`_draw`, about 40 primitives, no textures). Any replacement must stay inside the REAL-LOOK §5 budget: at most 4 persistent additive glows per room (lamps count) and no new full-screen translucent layer.

**Space** (world px)

- **Footprint today:** outer x 27-203 (lid to 213), y 292-451. Clear interior x 35-195, y 313-441.
- **Floor:** collision top **y 440**. Actor feet: WOLF 438.4 at sprite y -15, 446.4 at -7; Director 445.2; Rowan 439.8. The cage base runs to 451.
- **Left:** the room starts at x 0. The beat 0-2 view starts at x 0.3 (zoom 1.8), then x 20.8 (zoom 1.95); beats 4-6 start at x 53.8. Anything left of x 54 is cut off from beat 4 on.
- **Right:** the Director's coat starts at x 245.8 (he stands at 255 until beat 4, then 310). WOLF's nose reaches 243.8 at beat 3. Anything right of about x 203-213 crowds this exchange.
- **Up:** the top card (beat 0, 2.6 s plus fade) covers world x 10-259, y 214-248 at zoom 1.8 (y 225-256 at 1.95). The lid top today is y 292, so about 36-44 px of headroom remain.
- **Down:** the dialogue box top is world **y 451.7 at zoom 1.8 and y 444.2 at zoom 1.95**. Anything below y 444 is hidden from beat 2 on.
- **Play:** the purge display occupies x 105-211, y 243-346 (REAL-LOOK plans to move it to a wall terminal at 1.2-1.7 m, about y 372-392). Rowan spawns at x 160 and WOLF at x 72. If any part of a redesigned unit stays visible in play, it has to clear these, and that is Nathanial's decision. Today nothing stays.

**Camera per beat** (`IntroCamera`; `room_depth_test` checks plate coverage at (267, 355) z 1.8 and (300, 355) z 1.95)

| Beat | Line | Camera | Visible world |
|---|---|---|---|
| start | fade in 0.55 s | (267, 355), z 1.8, smoothing off | x 0-534, y 205-505 |
| 0 | Director: "I decide..." | same | same; top card up 2.6 s |
| 1 | standby narration | same | same |
| 2 | wakes himself, blue light | z 1.8 to 1.95 over 0.45 s | x 21-513, y 217-494 |
| 3 | latch, gate, steps out | z 1.95, trauma 0.6 | same |
| 4 | "You were in standby" / "I won't do it" | x 267 to 300 over 0.65 s; Director 255 to 310 | x 54-546 |
| 5 | lockdown order | same | same |
| 6 | turns, only open route | same | same |
| 7 | fade 0.3 s, then play | (355.6, 360), z 1.35, smoothing 4 | x 0-711, y 160-560 |

**WOLF's timeline**

- Start at **(115, 423)**, facing right, sprite y -15, modulate #365263, z 2 (behind the gate and frame).
- Beat 2: modulate to #9deeff over 0.45 s.
- Beat 3, from the tap: gate 0.65 s, then z 5, then sprite y -15 to -7 over 0.28 s, then walk to **x 185** at up to 220 px/s, arriving about 1.2 s after the tap.
- Beat 6: walk to **x 110**, flipped left, in about 0.35 s.
- After the fade: (72, 423), sprite y -15, white, z 2.
- A tap during beat 3 jumps to beat 4, which snaps the gate, z and sprite drop to their end values; WOLF still walks to x 185 then, so a fast tapper sees the walk under the beat-4 line.

**Other actors and effects**

- Director at **(255, 410)**, scale 0.188, z 2, facing left, opaque x 245.8-266.3 and y 375.6-445.2. Beat 4 moves him to (310, 410).
- Gate dust emitter at (115, 438), emission rect 70 x 3 half-extents, z 3. `_shutter_boom` plays `boom` at -2 dB.

**Frames that must stay readable**

- Beats 0-1: the closed unit, the dark WOLF clearly inside it, and the Director to the right, all above the dialogue box and below the card.
- Beat 2: the wake visible on WOLF, and on the unit once it can react.
- Beat 3: the moment of breaking and the opening, readable in the first 0.1-0.4 s, followed by WOLF's exit.
- Beats 4-6: WOLF, the Director and the open unit within x 54-546.

**Rules**

- No text change without Nathanial.
- No PIN entry in the opening.
- No Skynet, Terminator or Cyberdyne names, logos, designs, machines or text.
- No AI image generation for these drawings.
- Today's cage stays until Nathanial picks.

## Files

- `shots/`: 37 captures from `7c19ee2` plus UI-free copies, and `_log.json` with the per-shot camera transform and state.
- `crops/C01`-`C13`: the annotated evidence for the findings above.
- `driver/opening.gd`, `driver/measure.py`, `driver/crops.py`: scratch tools, never part of the repository.
- `logs/`: import, run and measurement logs.
- `game-main/`: the `7c19ee2` export (scratch, not a Git worktree).
