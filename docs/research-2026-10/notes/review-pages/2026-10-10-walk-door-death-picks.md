# Walk, door and death picks (review page, October 10, 2026)

Markdown copy of the page "Walk, Door and Death Picks" shown to Nathanial late on October 10, 2026. Scripts and styles are dropped. The page's 27 MB of preview media (room videos, animated loops, JPEG previews) were not kept; each image below points at the tracked or kept file it was made from, and the videos keep their captions with "video not kept".

**Outcome (October 11).**

- **Walking:** painted frame-by-frame cycles (A) for both characters; the jointed rigs (B) are rejected. Movement is walk-then-jog: walk 80, jog 190 after about half a second of holding. The approved cycles were then repainted and fixed: [`../../sources/walk-2026-10-11/`](../../sources/walk-2026-10-11/) (this pass) and [`../../sources/walk-final-2026-10-11/`](../../sources/walk-final-2026-10-11/) (final). The rig option is kept in [`../../sources/walk-rig-rejected-2026-10-10/`](../../sources/walk-rig-rejected-2026-10-10/).
- **Doors:** the edge-on cutaway slab shown here was rejected ([`../../sources/doors-edge-v2-rejected/`](../../sources/doors-edge-v2-rejected/)); after a further rejected round (a door in an angled end wall), the wide steel shutter across the corridor was approved on October 11, round 4 ([`../../sources/doors-shutter-approved/`](../../sources/doors-shutter-approved/)).
- **Death screen:** look A, Cold Still, plus WOLF's cyan eye and light from look B, as recommended. Spec: [`../../data/death-screen-design.json`](../../data/death-screen-design.json); mocks and art: [`../../sources/death-screen-2026-10-11/`](../../sources/death-screen-2026-10-11/).

(Recorded in [`../../README.md`](../../README.md).) Two lines that called WOLF "it" now say "he": WOLF is he/his. The engineer is they/them.

---

*WOLF//OVERRIDE · October 10, 2026*

Three pieces of work finished tonight and each needs your call. Everything here is offline renders and mock frames: nothing on this page is in the game yet, and nothing has been played. Once you pick, each one gets built and judged again from real in-game screenshots.

| Section | What it is | Recommended |
|---|---|---|
| 1. Walking | Painted frames or a jointed rig, and the walking speed. | Painted frames, walk 80 and jog 190. |
| 2. Doors | Doors redrawn edge-on, inside a thick wall between two rooms. | Approve this direction. |
| 3. Death screen | Three looks for the moment the engineer dies. | A, Cold Still. |

## 1. Walking

The first walk cycles jittered and looked choppy. They were redone two ways: **A**, each frame painted with Codex over a pose guide with the hip locked in place, and **B**, a jointed cut-out rig that Godot moves with code.

**Recommendation: painted frames (A) for both characters.** They read as a real person and a real four-legged walk, with weight, cloth and swinging arms. The rigs measure smoother but look like puppets, and they drifted from the approved designs.

Speed matters as much as the drawing. At today's 190 px/s the engineer is running: a walk would have to play at 39 frames a second (6.5 steps a second) and looks frantic. The recommended speeds are a walk at 80 and a jog at 190.

- **A · PAINTED · WALK 80, JOG 190** (video not kept). Standing, walking, then jogging, with WOLF following by the game's own rule. WOLF keeps his 64 px gap.
- **A · PAINTED · TODAY'S 190** (video not kept). The legs cycle too fast, and WOLF falls 275 px behind after three seconds of jogging because he follows at up to 220.
- **B · JOINTED RIG** (video not kept). Smooth at 50 frames a second with planted feet, but stiff, and the engineer reads as a cut-out. This clip uses an older WOLF rig.

In-room stills of the three options: [`ctx-A.webp`](../../sources/walk-rig-rejected-2026-10-10/ctx-A.webp), [`ctx-B1.webp`](../../sources/walk-rig-rejected-2026-10-10/ctx-B1.webp), [`ctx-B2.webp`](../../sources/walk-rig-rejected-2026-10-10/ctx-B2.webp).

### Engineer, twice game size

| Option | Caption | Frames |
|---|---|---|
| A · WALK · 12 FRAMES | Matches the approved design: three-quarter face, no backpack. Height holds within 0.8–2.4%. | [`eng-walk-sheet.png`](../../sources/walk-2026-10-11/sprites/eng-walk-sheet.png) |
| B · WALK · RIG | Feet stay planted, but it is a strict profile with an added backpack, and a red wedge flashes between the thighs. | animation not kept; rig in [`walk-rig-rejected-2026-10-10/`](../../sources/walk-rig-rejected-2026-10-10/) |
| A · JOG · 12 FRAMES | A real jog with a forward lean. The torso drifts slightly more than the target and gets a repaint pass. | [`eng-jog-sheet.png`](../../sources/walk-2026-10-11/sprites/eng-jog-sheet.png) |
| B · JOG · RIG | The far arm floats as a red sleeve behind the hips for three frames, and the shins streak where the mesh stretches. | animation not kept |

### WOLF, twice game size

| Option | Caption | Frames |
|---|---|---|
| A · WALK · 12 FRAMES | A natural four-beat walk that keeps the approved shape: long legs, feathered plate tail, two ears. It needs a colour pass back to dark gunmetal. | [`wolf-walk-sheet.png`](../../sources/walk-2026-10-11/sprites/wolf-walk-sheet.png) |
| B · WALK · RIG | Perfect foot contact, but short legs, a deep chest and a tail that became a ringed hose. It keeps the dark outlines the art bible bans. | animation not kept |
| A · TROT · 12 FRAMES | Diagonal trot for keeping up. One front paw slips at frame 10. | [`wolf-trot-sheet.png`](../../sources/walk-2026-10-11/sprites/wolf-trot-sheet.png) |
| B · TROT · RIG | Reads as a low crouched crawl, and the dark body nearly disappears against the floor at game size. | animation not kept |

| Loop | A · body drift | A · worst foot slide | B · foot slide | A plays at |
|---|---|---|---|---|
| Engineer walk | 0.4 px | 1.1 px | 0.04 px | 16 fps |
| Engineer jog | 1.6 px | a few px at one landing | 0.07 px | 23 fps |
| WOLF walk | 1.8 px | 5.5 px at the loop wrap | under 1 px | 20 fps |
| WOLF trot | 1.3 px | one front paw slip | under 1 px | 30 fps |

Game pixels at 1080p. The first pass jittered by up to 14 px. If painted frames win, the next pass repaints the jog torso and two walk faces, grades WOLF back to gunmetal, fixes the two paw slips, then wires the frames to the real movement. Each new move (crank, pick up, fall, WOLF's hop) needs its own painting rounds.

## 2. Doors

Every door so far was drawn from the front, so its opening pointed into the screen while you walk left to right. That is why they made no sense. A first edge-on try read as a thin pole in the middle of one room. This version puts the door inside a thick wall between two rooms, as Metroid, Hollow Knight and Inside do: the wall is cut away so you see its thickness, the room beyond is a different colour, and the door slides up into the wall.

**Recommendation: approve this direction.** It is the first version where a closed door clearly blocks the walkway and an open one clearly leads into the next room. If you approve, the corridor seal, the Records doors and the junction blast door get drawn this way in Look 2 and replace the front-facing door before the polish work merges.

| Image | Caption |
|---|---|
| ![Junction door closed: a thick wall between a blue room and an amber room, the slab filling the doorway](../../sources/doors-edge-v2-rejected/junction-closed.png) | **JUNCTION · CLOSED.** Red lamp. The amber room beyond is dim. |
| ![Junction door half raised with amber light spilling under it](../../sources/doors-edge-v2-rejected/junction-opening.png) | **JUNCTION · OPENING.** The slab rises into the wall and light spills under it onto both floors. |
| ![Junction door blown: the slab thrown into the amber room, the doorway clear](../../sources/doors-edge-v2-rejected/junction-blown.png) | **JUNCTION · BLOWN.** The slab is thrown into the next room. Scorched edges, smoke, a clear way through. |
| ![Corridor seal closed in a thinner wall with a red lamp](../../sources/doors-edge-v2-rejected/corridor-closed.png) | **CORRIDOR SEAL · CLOSED.** A thinner wall and shutter, red lamp, the teal room beyond dim. |
| ![Corridor seal open with the teal room lit beyond](../../sources/doors-edge-v2-rejected/corridor-open.png) | **CORRIDOR SEAL · OPEN.** Shutter up, lamp green, the next room lit. |
| ![The rejected first edge-on try: a thin pole in one continuous room](../../sources/doors-rejected-rounds/round1b-edge-pole-compare.png) | **REJECTED FIRST TRY.** A thin pole in one continuous room. It read as a pillar, so it never went to you. |

### At the real game size

![All five door scenes scaled to 960 by 540, the game's base size](../../sources/doors-edge-v2-rejected/game-size.png)

Concept scenes, not final sprites: the engineer's position and the header height drift a little between states. In the game, the wall becomes part of the room art at the room's edge and the slab a separate moving piece.

## 3. Death screen

Built on the approved death model and text. All three looks share the same rules: you can press RETRY after 0.9 s and have control back at about 1.5 s, the room sound is muffled under a ringing tone rather than cut (Inside and Limbo keep the music going through a death), there are no flashes, a caption names the ringing tone for players without sound, and WOLF's reaction starts only after the engineer has fallen, so it never looks like a rescue.

**Recommendation: A, Cold Still, with two touches from B.** The world freezes and drains to grey on the frame that killed the engineer, so you can see what did it, and WOLF is the only thing still moving, so rushing in or holding back reads as his choice. It also holds up best on phones and for players sensitive to motion. From B: WOLF's cyan eye keeps its colour through the drain, and when he comes in, his light falls on the engineer.

The door in these mocks is the old front-facing one; it becomes the new door once that is approved. The collapse pose is new Look 2 art and still needs a final version.

### A · COLD STILL

The world freezes and drains to cold grey; a quiet card sits on the wall above.

| Image | Caption |
|---|---|
| ![Look A, blast: frozen grey room, WOLF beside the fallen engineer, cause line above](../../sources/death-screen-2026-10-11/look-a-blast-honest-1280.png) | Blast, WOLF trusted: he comes in fast and stays. |
| ![Look A, sentry: WOLF keeps his distance and looks away](../../sources/death-screen-2026-10-11/look-a-sentry-pressed-1280.png) | Sentry, WOLF pressed earlier: he holds his distance and looks away. |
| ![Look A, coolant: the card adds the dropped-evidence line](../../sources/death-screen-2026-10-11/look-a-coolant-honest-dropped-1280.png) | Coolant, with the dropped-evidence line. |

### B · LAST LIGHT

The room goes dark. Only WOLF's cyan light, a thin rim on the engineer and a dim ember from the hazard stay.

| Image | Caption |
|---|---|
| ![Look B, blast: dark room, WOLF's light on the engineer](../../sources/death-screen-2026-10-11/look-b-blast-honest-1280.png) | Blast, WOLF trusted. |
| ![Look B, sentry: only the sentry's red eye and WOLF's light remain](../../sources/death-screen-2026-10-11/look-b-sentry-pressed-1280.png) | Sentry, WOLF pressed. Hard to read on a phone in daylight. |
| ![Look B, coolant with dropped-evidence line](../../sources/death-screen-2026-10-11/look-b-coolant-honest-dropped-1280.png) | Coolant, with the dropped line. |

### C · LETTERBOX

Black bars close like a film and the card sits in the bars, so no text covers the actors.

| Image | Caption |
|---|---|
| ![Look C, blast: letterbox bars with the cause line in the bottom bar](../../sources/death-screen-2026-10-11/look-c-blast-honest-1280.png) | Blast, WOLF trusted. |
| ![Look C, sentry, WOLF pressed](../../sources/death-screen-2026-10-11/look-c-sentry-pressed-1280.png) | Sentry, WOLF pressed. |
| ![Look C, coolant with dropped line in the bar](../../sources/death-screen-2026-10-11/look-c-coolant-honest-dropped-1280.png) | Coolant. The bottom bar crowds the touch RETRY button when two status lines show. |

### On a phone

| Image | Caption |
|---|---|
| ![Look A on a phone in landscape with the RETRY button](../../sources/death-screen-2026-10-11/look-a-phone-2340x1080.png) | **A.** The USE button becomes RETRY; tapping elsewhere does nothing, so panic taps can't skip the card. |
| ![Look B on a phone](../../sources/death-screen-2026-10-11/look-b-phone-2340x1080.png) | **B.** Relies on darkness, which is the first thing that fails on a phone screen. |
| ![Look C on a phone](../../sources/death-screen-2026-10-11/look-c-phone-2340x1080.png) | **C.** Text moves into the bars and gets tight beside RETRY. |

### The first 1.5 seconds, look A

![Look A storyboard: hit, collapse, drain, card](../../sources/death-screen-2026-10-11/look-a-storyboard.png)

Hit at 0.00 s, collapse by 0.45, drain by 0.75, card from 0.90. The card waits for you and never moves on by itself; Pause and Back keep working.

**Your calls:** Walking approach and speed, the door direction, and the death screen look. I'm asking all four in the chat.

---

## Credits

- Game, story and every decision: Nathanial Henniges.
- Walking frames, door concepts and the death-screen figure art: Codex's built-in image tool (`image_gen`, edit mode over pose and layout guides). Rigs: Godot 4.7 scripts. Mocks, measurements and page: Claude (Claude Code) agents working for Nathanial.
- Games named as design references (no material copied): Metroid (Nintendo), Hollow Knight (Team Cherry, 2017), Inside (Playdead, 2016), Limbo (Playdead, 2010). The fact-checked sources for them are in [`../../design-reference-25-games.md`](../../design-reference-25-games.md) and [`../../data/game-research.json`](../../data/game-research.json).
