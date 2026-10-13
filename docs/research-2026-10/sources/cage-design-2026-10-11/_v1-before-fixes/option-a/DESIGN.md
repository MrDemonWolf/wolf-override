# Option A: a secure barred enclosure, done right

Private scratch, 2026-10-11. This is a proposal for Nathanial to pick from. **Nothing in the game changes until he picks.** Today's cage on `main` (7c19ee2) stays exactly as it is ("the cage for the wolf should been the same 100% the same before"). No Git repository or worktree was edited.

It answers "Make sure the wolf cagte design makes sense" and the new direction ("make it feel more like a furttgrue milialry base"). The Terminator films are a mood reference only: no names, logos, machines or designs from them appear here.

**What you're looking at, and how much it proves**
- `strip.png`: the three required beats plus the construction drawing, in one image.
- `construction-drawing.png`: front elevation at game scale, section A-A, plan, parts legend and lamp language.
- `renders/`: full 1280x720 frames.

I made the renders by exporting `main` into scratch, importing it twice headless and running one normal 1280x720 Godot window at a fixed 60 fps. The driver pressed New Game and tapped `interact` through the opening, so the camera, WOLF, Director, UI, flash, shake and timing all come from main's own code. The driver hid today's `IntroCage` and `IntroGate` and drew this design's flat layers at their real world position and z order. The leaf is moved by main's own `IntroGate.opening` tween. The window closed itself.

The layers are flat-shaded design drawings I made with a Python script (`tools/geom.py`). No AI image generation was used. They are not final art.

These are still frames only. Nobody played them by hand, nothing was listened to, and there was no export or device test. Nothing here proves how it feels in motion.

## 1. What it is

The unit is a large-carnivore holding cage built to military spec. It sits on the same spot as today's cage. Its parts:
- a welded steel frame bolted to the slab;
- solid 6 mm steel plate at the back, ends and roof;
- a barred front made of a fixed panel on the left and one slide leaf on the right;
- an enclosed overhead track the leaf hangs from;
- a **fail-secure hook-bolt lock** with a **card reader and PIN keypad** on the keeper's side, outside the cell and out of WOLF's reach;
- a **guarded lock-status lamp**;
- a **standby dock** inside, with a power and data **umbilical** to WOLF's withers;
- a fixed camera on a wall arm;
- caught-between stripes on the floor guide;
- two short header marks (proposed text only).

**Why it makes sense (the real logic)**
- **What actually holds him is his power state, not the cage.** Real robots are held in lockout: on Spot, "blue light: computers on, motors off (lockout engaged)" (RESEARCH §6). The base keeps WOLF docked, locked out and in standby. The cage is the backup barrier, and its lock is rated for people and for a robot that can't move.
- **The lock is the correct kind.** A cell for a dangerous machine uses a fail-secure lock: spring-locked, power to unlock, monitored, with a lamp and a manual override (RESEARCH §5). It does not use a maglock, which opens in a power cut. The keypad and wiring sit on the secure side, which for a cell is the outside (SCIF and zoo shift-door rules, RESEARCH §3.2 and §4).
- **The weak point is real and visible.** The bolt holds. What gives is the welded **keeper** on the leaf when a waking robot drives a shoulder into the latch end. Nobody built that weld to take it.
- **The gate is a real gate.** One leaf hangs on two trolleys in a box track and is guided at the floor. It parks over the fixed bay. Nothing shrinks and no bars overlap (audit items 3-5).
- **Light carries one meaning per lamp.** Red means locked, amber means forced, green means released by a code. The dock lamp is dark for lockout and blue when WOLF's computers are on.
- **It reads as military.** Hardened steel, a serialised unit, interlocked access control on the lock, a camera, safety-coloured stripes, and conduit run into the slab. There's no sci-fi gloss: no glowing seams, holograms or curved plastic (REAL-LOOK §8).

## 2. Parts

Scale: 1 m = 39.8 world px (the engineer is 69.6 px = 1.75 m). World coordinates have y pointing down, with the floor at y 440. The origin is unchanged at (115, 365).

| # | Part | Real size | World px / where | Job |
|---|---|---|---|---|
| 1 | Header beam + 6 mm roof plate | 0.30 m deep beam | y 338-350 (roof edge 337), x 27-203 | closes the top; carries the track |
| 2 | Enclosed box track, rubber end stops | 0.15 m | y 350-356, full front | hangs the leaf; stops it at both ends |
| 3 | Slide leaf: 75 mm RHS frame, 3 rails, bars, 2 trolley hangers | 2.11 x 1.96 m | x 115-199, y 357-435; travels 82 px (2.06 m) left | the gate |
| 4 | Fixed bar panel, framed | 1.96 m bay | x 33-111 | front of the left bay; the leaf parks over it |
| 5 | Posts, 150 SHS | 0.15 m | 6 px at x 27, 111, 197 | carry the header, panel and lock |
| 6 | Base plates, anchor bolts | 0.30 m | 12 px at each post, y 437-440 | fix the unit to the slab |
| 7 | Sill / floor guide channel, yellow-black 45 degree stripes | 0.10 m | y 436-440 | guides the leaf; marks the caught-between hazard (OSHA yellow) |
| 8 | Back lining, ends and roof: 6 mm plate | cell 4.12 x 2.50 x 2.11 m clear | seen at x 33-197, y 359-431; cell floor 431-436 | makes it a solid cell you can't see through |
| 9 | Cooling vent, honeycomb | 0.80 x 0.25 m | x 40-72, y 364-374 | air for a charging robot |
| 10 | Standby dock unit + dock lamp | 0.50 x 0.38 m, 1.8 m up | x 120-140, y 361-376; lamp 3 px | power and data; dark = lockout, blue = awake |
| 11 | Umbilical with breakaway coupler | 50 mm cable | 2 px from (130, 376) to WOLF's withers at (134.5, 395), measured from the sprite | keeps him docked; drops when he moves |
| 12 | Keeper, welded to the leaf's leading stile | 0.15 x 0.33 m | x 194-200, y 368-381 | the hook bolt holds it. **The part that fails.** |
| 13 | Fail-secure hook-bolt lock box, key override | 0.25 x 0.43 m, centre 1.65 m | x 203-213, y 366-383 (outer face of the latch post) | spring-locked, power to unlock, monitored |
| 14 | Guarded lock-status lamp | 0.15 m, top 2.08 m | x 205-211, y 357-363 | states the lock: red, amber or green |
| 15 | Card reader + PIN keypad | 0.15 x 0.23 m (1.8x a real 85 x 122 mm reader, so it reads as a keypad) | x 205-211, y 387.5-396.5, centre 1.2 m | access control on the keeper side. **No code is entered in the opening.** |
| 16 | Rigid conduit + floor box, strapped | 50 mm | x 207-209 down to y 440 | lock wiring stays outside and ends in the slab |
| 17 | Fixed camera in a housing on a wall arm | 0.35 x 0.13 m, 2.8 m up | about (207, 329) | watches the cell |
| 18 | Gate position switch | 0.13 m | track, x 190-196 | reports the leaf closed |
| 19 | Header marks (PROPOSED text) | cap height 0.15 m | header | unit code and keep-clear distance |
| — | Contact shadow on the room floor | | 8 px under the front, darkest at y 440 | grounding (REAL-LOOK checklist 4) |

**Fit:**
- **Bars:** 50 mm on 125 mm centres, a **75 mm clear gap** (2 px on 5 px). That is the research's wolf range scaled up 1.6x for WOLF (no more than 80 mm), replacing today's 300 mm gap, which counts as whole-body access.
- **Standing:** WOLF (115 x 62 px, 2.9 x 1.55 m) stands with about 0.45 m above his ears (clear height 2.11 m).
- **Turning round:** he can turn in the 2.50 m clear depth (body 2.3 m). The plan view shows it.
- **Exit:** the gate opening is 2.01 m wide by 2.11 m high.

**Footprint against the audit's hard limits:**
- **Frame:** x 27-203, the same as today.
- **Lock box:** reaches x 213, the same as today's lid overhang.
- **Camera:** reaches up to y 322. That is lower than today's lid top at 292, so the 03:17 card has more headroom.
- **Floor:** the base sits on y 440, with nothing below y 440 except the contact shadow.
- **Director:** the coat at x 245.8 has 33 px clear of the lock box.
- **Visible parts:** everything readable sits above the dialogue box line at y 444.

## 3. The opening, beat by beat

Main's camera, WOLF's start (115, 423), his exit to x 185, the Director's position and every timing are left as on main. The only exceptions are marked **change**.

| Beat | Line (approved) | What the unit shows |
|---|---|---|
| 0 | Director: "I decide who counts as a threat..." | Closed unit. Lock lamp **red** (locked). Dock lamp dark. Umbilical plugged into WOLF's withers. Dark WOLF reads as a silhouette against the lighter lining, behind 75 mm bars. |
| 1 | "The Director thinks WOLF is still in standby." | The same. Standby now has hardware behind it: dock, cable and lockout lamp. Render: `renders/beat1-standby.png`. |
| 2 | "Nobody gives an activation command. WOLF wakes himself. A blue light answers from inside the containment seal." | **Change:** the dock lamp turns **blue**, with one tight additive glow on the lining. It fades in with main's existing 0.45 s cyan tint on WOLF. This is the Spot convention: computers on, motors locked out. Render: `renders/beat2-wake-extra.png`. |
| 3 | "The latch breaks from the inside. The gate slides aside. WOLF steps out under his own power. The Director freezes at the sound of the seal opening." | **Change** on the tap: WOLF lunges 6 px forward into the latch end (0.07 s out, 0.22 s back). Main's boom, flash and shake fire. The **keeper tears off the leaf** and drops by the post foot, leaving torn weld marks on the stile. The **hook bolt is left thrown** out of the post face. The lock lamp goes **amber, flashing**. The umbilical's coupler breaks away and the cable swings, then hangs. Main's gate emitter fires **sparks at the keeper** instead of dust along the floor. The leaf rolls left on main's own 0.65 s ease-out (it was shoved, then coasts) and stops on the rubber end stop over the fixed bay. Then main's own z 5 swap, 8 px forward step and walk to x 185. Renders: `renders/beat3-latch-fails.png` (3 frames after the tap, leaf 28% across) and `renders/beat3-open-wolf-steps-out.png` (+1.07 s). |
| 4-6 | "You were in standby" / lockdown / "takes the only open route" | Open unit, amber lamp, hanging cable, keeper on the floor. All stay visible at x 54-546. At beat 6 WOLF walks to x 110 **in front of** the parked leaf (he is at z 5 with feet at 446), so he no longer reads as walking back inside. The missing exit at the left (problem 20) is unchanged and stays your call. |
| 7 | fade | As on main: the unit is hidden at play start. |

**Optional timing change, not rendered:** a 0.1 s hold between the boom and the leaf starting to move would show hit, break, slide as three separate things. Today the leaf is already 28% open 3 frames after the tap. It would delay WOLF's arrival at x 185 by 0.1 s.

**Sound (proposal, not built or listened to):** today the beat plays a "boom". It should be a heavy steel clang with a short metal tear, the clack of the keeper landing, trolley rumble, then a thud at the end stop. With no gasket there's no seal hiss.

## 4. Wording: the smallest changes this option needs (you approve all wording)

The unit is barred, so it has no seal. Two words don't match it:
1. **Beat 2:** "A blue light answers from inside the containment **seal**." Proposed: "...from inside the containment **unit**." The alternative is to keep it and accept "seal" used loosely.
2. **Beat 3:** "The Director freezes at the sound of the **seal opening**." Proposed: "...at the sound of the **gate opening**." Alternative: "...at the sound of the lock giving way."

These need no change:
- "The latch breaks from the inside": the latch (bolt and keeper) visibly fails from inside.
- "The gate slides aside": it does.
- "Steps out under his own power": he does.
- The "03:17 / CONTAINMENT" card.
- Beat 6 has your already-approved replacement, INTRO_LOCKDOWN ("...heads for maintenance"). That isn't on main yet, and this design doesn't depend on it.

**Proposed marks (awaiting you, both neutral, no story names):**
- `CU-01`: containment unit 1, an equipment code.
- `KEEP CLEAR 2 M`: Spot's real "stay at least 2 m away" distance once motors are on.

They conflict with REAL-LOOK checklist rule 7 (no text in art) unless you allow them. REAL-LOOK §8 already proposes script-typeset text from an approved list for doors, and these could join that list. The unit works without them: they are one layer, set by script, and drawn last.

## 5. Cost on phones

Drawn as code, the unit is about 290 primitives across 4 canvas items:

| Layer | Primitives |
|---|---|
| Back | 77 |
| Frame | 107 |
| Leaf | 52 |
| Top | 56 |

Today's cage is about 40 primitives. The vent's hole grid is about half the back layer's count and could be one flat patch.

**Recommended for shipping:** bake the static parts into textures, the same way the room art is going. That gives:
- 3 static sprites: back at z 1, frame at z 3, top at z 4;
- 1 moving leaf sprite at z 4;
- 1 small keeper sprite;
- 2 small additive glows (blue dock about 68 x 52 world px, amber or red lamp about 16 px).

That is 2 of the room's 4 allowed persistent glows. There is no new full-screen layer, no haze, no shaft, no new particle emitter (the existing gate emitter is retuned to the existing sparks preset's numbers), and no reflection. The design layers at 4 px per world px total 164 KB as PNG. At about 2 px per world px they'd be under 1 MiB of VRAM, inside the corridor's 12 MiB room budget. All of this is desktop reasoning: no device was measured.

## 6. How it would be built later (only after you pick)

- **`containment_cage.gd`:**
  - keeps the one `opening` float (0..1, clamped, queue_redraw) as the drive, so `m0_scene_test`'s `opening == 1.0` checks still hold;
  - adds `lock_state` (LOCKED / FORCED / RELEASED) and `dock_lit`.
- **Scene changes:**
  - `IntroGate` draws the leaf and moves 82 px left;
  - `IntroCage` draws the frame;
  - a child of `IntroCage` set to z 1 draws the back;
  - a child set to z 4 draws the track and lock side;
  - `IntroGate` moves to z 4 and `IntroCage` to z 3, because the leaf runs in front of the posts.
- **`main.gd`:**
  - beat 2 sets `dock_lit`;
  - beat 3 sets FORCED and adds the 6 px lunge tween;
  - `_setup_particles` moves and retunes `gate_dust` to the keeper (199, 374);
  - the two wording changes, only if you approve them.
- RELEASED (green) is reserved for the separate PIN gameplay, so the opening never needs a code.

## 7. Risks and open points

- **WOLF's rear "pops" forward at the z swap.** The 2.0 m opening is shorter than WOLF (2.9 m), so for the first 0.65 s his rear half is correctly behind the parked bars. When main swaps him to z 5 and steps him 8 px forward, the whole sprite comes in front at once (visible between frames f030 and f040). Main's step-forward drop hides it partly. It could be reduced by walking him about 20 px right inside the cell before the swap (his nose stays inside the post), but that changes his timing. This was judged from still frames only, not in motion.
- **The lunge barely shows.** The sprite has no push pose, so the 6 px lunge is nearly invisible at game scale. The failure reads from the lock (flying keeper, amber lamp, sparks), not from WOLF's body. A proper shoulder-drive frame would need new art.
- **The physics are simplified.** The shoulder drive is mostly outward; the leaf then rolls left. The story is: the keeper's welds tear, and the freed leaf is shoved aside and coasts. That's believable on hung trolleys, but it's not a calculation.
- **Value and finish.** The flat render is lighter and greyer than the painted room, which keeps the dark standby WOLF readable against the lining. Final paint has to bring it into the room's value plan without losing that silhouette.
- **The room's near-plane strip** (z 3, part of today's room depth) shows inside the cell at the far left at some camera positions. The fixed panel's 4.5 px frame stile covers it in every frame I captured. That only covers it; nothing about the strip itself was changed.
- **The unit is shorter than today** (top at y 337 instead of 292). The room's tank and pipes now show above it. That's correct for a real 2.6 m unit, but it changes the composition.
- **Keypad digits can't be read** at game or phone scale, even at 1.8x real size. Any PIN entry needs a close-up or UI. That design is separate.
- **Still open for your decision (unchanged from main):**
  - the unit still vanishes at the fade, and its footprint is where the purge display and both spawns sit;
  - WOLF ends 2 px from the Director's coat at beat 3;
  - beat 6's walk left with no exit (problem 20).
- **Not done:** hands-on play, sound, export, device or performance measurement. Only the opening's still frames from one desktop run.

## Files

All paths are under `[session scratch, not kept]/cage-design/option-a/`.

- `strip.png` and `construction-drawing.png`
- `renders/beat1-standby.png`, `renders/beat3-latch-fails.png`, `renders/beat3-open-wolf-steps-out.png`, and the extra `renders/beat2-wake-extra.png`
- `shots/final/`: 31 frames (beats 0-6, 20 frames of beat 3, close-ups of the lock locked and forced), UI-free copies, and `_log.json` with the camera, gate, WOLF and Director state for each shot
- `tools/geom.py`: single-source geometry
- `tools/layers.py`: runtime layers
- `tools/drawing.py`
- `tools/strip.py`
- `game/apps/game/cage_a/driver.gd`: capture driver, only in the scratch export
- `build/`: layers, review sheets and the phone-size proxy `build/phone_proxy_852.png`
- `logs/`: import and run logs
