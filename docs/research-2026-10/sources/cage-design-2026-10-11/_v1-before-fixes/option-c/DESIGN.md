# WOLF's containment, option C: a standby dock in a guarded bay

Private scratch, 2026-10-11. This is a proposal for Nathanial to pick from, nothing more. The game, the cage and the opening on `main` (`7c19ee2`) stay exactly as they are until he chooses ("the cage for the wolf should been the same 100% the same before"). No Git repository or worktree was touched. Every image here is a **design drawing**: flat-shaded layers I constructed by script, not final art, with no AI image generation. All sign text is **proposed, awaiting Nathanial**.

Built on `../audit/AUDIT.md` (hard limits, measured on main) and `../research/RESEARCH.md` (sourced; numbers like [9] or [37] below are its source list). Art rules come from `docs/research-2026-10/art-direction/REAL-LOOK.md`, including §8 Military base.

## 1. What it is, in one paragraph

WOLF is parked the way a real military robot is parked: **held by power state first and by steel second** (RESEARCH §6, "Reading for WOLF"). He stands over a **belly cradle** bolted to the floor, which carries his weight while his motors are locked out. A **charging and control umbilical** drops from a spring reel under the roof and plugs into his back, and its **dock lamp** shows his state. Round him is a **guarded bay**: plate back, plate ends and plate roof, with a front of four **telescoping mesh leaves** on a top track (the robot-cell guard pattern, RESEARCH §7). The leaves are held shut by a **fail-secure guard lock** on the latch post (spring-locked, power-to-unlock [29][34][35]). That lock sits outside, out of his reach, next to a **keypad station** (card slot, 12-key PIN pad, status lamp) at 1.2 m. A fixed **camera** watches the door, and one conduit takes all the wiring into the floor. At beat 3 WOLF breaks the only part a robot can break from inside: the lock that holds the leaves. It tears off its mount, the status lamp goes to flashing red ("door forced"), the breakaway umbilical lets go, the leaves telescope aside, and he steps out on his own battery toward the Director. **Nobody enters a code.** The keypad is only lock hardware for now, ready for whatever PIN design Nathanial picks.

Images:
- `construction-drawing.png`: (A) labelled front elevation at the game's scale with 18 numbered parts, dimensions in m and [world px], WOLF's fit box and the Director for scale; (B) plan view showing depth and exit path; (C) lamp states; (D) an actual-size crop at 1280x720.
- `beat1-standby.png`, `beat3-latch-fails.png`, `beat3-stepping-out.png`: full 1280x720 frames of main's opening, each a labelled design render.
- `strip.png`: the three beats above the construction drawing, as one image.

**How the beat frames were made:** main was exported to `game-design/`, and `scripts/containment_cage.gd` was swapped in that scratch copy for `driver/containment_unit_design.gd`. The script draws the design's layer PNGs (`render/layers/`, from `driver/design_art.py`) plus a few live parts. A third node (the bay behind WOLF) was added at runtime by `driver/design_opening.gd`. The same driver then played main's real opening with real `interact` taps in one normal 1280x720 window at a fixed 60 fps. That window closed itself (exit 0). Everything else in the frames is main: the room, the actors, the camera, the UI, the text, the flash and the shake. That makes them real captures of main's opening with the design drawn in at its true position and z-order. They are still frames. Nothing was played by hand.

## 2. Why it makes sense (what it fixes from the audit)

| Audit finding | This design |
|---|---|
| Lid in a different projection; asymmetric overhang (1) | One projection, a pure side elevation. The cap plate overhangs 2 px on both sides. No receding faces. |
| Frame with one face, see-through, no seal possible (2, 10) | Plate back, ends and roof. Only the front is mesh. Open, it shows the empty bay (cradle, cabinet, reel), not the room's tank. |
| Bars not held, gate not attached on the latch side, no latch (3, 4) | The leaves hang from 4 top tracks in the head beam and run in the sill's bottom guide. The leading leaf's bolt engages a real guard lock on the latch post. |
| Impossible fold, rigid rails shrinking (5) | Telescoping leaves are rigid, overlap on parallel tracks and keep their size. Clear opening 3.00 m when open. |
| Zoo-crate proportions, 0.30 m bar gaps (6) | Welded mesh, drawn at a 3 px (75 mm) pitch so it reads as mesh. That is coarser than a real screen but close to the wolf-fence and tiger-mesh range [7][9]. The 0.30 m kick plate follows the CR 82 plate-lining rule [7]. |
| Floats: no feet, bolts or shadow (8) | Sill on the floor line y 440, 3 anchor plates with 2 bolts each, and a contact shadow darkest at the contact line. |
| Standing pose says nothing about standby (11, 18) | Cradle under his belly, umbilical on his back, amber dock lamp. |
| Nothing breaks; dust from the floor (12) | The guard lock visibly tears off its mount and hangs by its cable, with bright scars where it was bolted. A small amber spark burst comes from the lock (the existing spark preset replaces the floor dust; nothing is added). |
| Walks through the post (13) | The bay has a whole-front door. He steps forward out of it (main's 8 px step-down already reads as "toward camera"), so he is *in front of* the post when he walks right. Plan view B shows this. |
| Lamps never react (16) | Status lamp: green, then flashing red. Dock lamp: amber, then blue, then off. Both change on the beats. |
| Blue light is a brighter wolf (17) | A real blue lamp on the connector at his shoulders, with a small blue pool on the back plate behind him. Main's sprite tint is left as it is. |

**Why fail-secure, and why it still breaks.** A maglock opens when the power fails, so no real cell for a dangerous machine would hang on one [29][30]. Guard locks for machine cells are spring-locked and power-to-unlock, rated at about 2,000 N locking force for the Euchner MGB [35]. Reading that design logic: such a cell expects the robot's **motor lockout** to be the primary hold, with the lock as the guard. **WOLF's mass, by my estimate:** about 250-350 kg. That assumes he is a ~2.1x linear scale-up of Spot (32.5 kg [2]), which works out to roughly 8-9x the volume, discounted for a lighter frame. **Shove force:** at 0.7-1 g he pushes about 1.7-3.4 kN, which reaches or passes a 2 kN guard lock. Once he has woken himself and his motors are live (the approved "wakes himself"), the steel is under-rated for him. The spring-locked bolt stays thrown and the module's mounting lets go, which is the "keeper tears out" option from RESEARCH §10 B. Nobody works the keypad, and the lock is out of his reach, so "breaks from the inside" means force from inside, not a hack.

**Why the bay is plate and the front mesh (the "seal").** A steel box with a fine-mesh front is also an RF-shielded enclosure. The leaves close onto a conductive gasket strip on the latch post (part 17). That gives "containment seal" a physical part: the gasket the leaves seal against. It also explains the umbilical: the only link to him is the wire. This is **construction logic only**. Nothing on screen says why he is shielded, and it adds no story fact. Nathanial can drop the gasket and the meaning without changing anything else.

## 3. Parts (1 m = 40 world px; local origin = world (115, 365); floor = world y 440)

Numbers match the callouts on `construction-drawing.png`.

| # | Part | Real size | World px (world coords) | Job |
|---|---|---|---|---|
| 1 | Head beam + cap plate | 4.40 x 0.30 m beam, 4.50 m cap | x 27-203, y 332-344; cap x 25-205, y 330-332 | carries the 4 top tracks and leaf trolleys; the roof edge |
| 2 | Posts (2 visible of 4) | 150 mm box section, 2.70 m | 6 px; x 27-33 and 197-203, y 332-440 | frame; the latch post carries the lock and gasket |
| 3 | Sill / bottom guide | 0.15 m | x 27-203, y 434-440 | leaves run in it; steel threshold |
| 4 | Anchor plates (3) | 0.35 m, 2 bolts each | 14 px at x 30, 115, 200; y 437-440 | bolted into the slab |
| 5 | Leaves (4) | 1.10 x 2.25 m each, 0.10 m overlap | 44 x 90; closed at x 33, 73, 113, 153; y 344-434 | welded mesh in a steel frame, 0.30 m kick plate (12 px); left leaf fixed; open stack x 33-77 |
| 6 | Leading stile + handle module | 0.10 m stile, module 0.18 x 0.28 m | stripes on x 193-197; module 7 x 11 | crush-point stripes (the one yellow element in the view); bolt into the lock |
| 7 | **Guard lock** (the part that fails) | 0.20 x 0.35 m, 0.85-1.20 m up | 8 x 14, x 196-204, y 392-406 | fail-secure, spring-locked, power-to-unlock, bolt monitored; outside, out of reach |
| 8 | Keypad station | backplate 0.20 x 0.55 m; pad 0.15 x 0.225 m (1.5-1.8x a real 85 x 122 mm reader [21]) | 8 x 22 at x 205-213, y 380-402; pad centre y 392 (1.2 m) | card slot + 12-key PIN pad, tamper-protected, wired on the keeper side [15]; **no code entered in the opening** |
| 9 | Status lamp | lens 65 mm, glow 0.35 m | lens 2.6 px at (209, 383), 1.42 m | green steady = locked and bolt monitored; red 2 Hz = door forced |
| 10 | Camera | 0.23 x 0.13 m housing on an arm | x 203-213, y 332-339, 2.6 m | watches the door [15][16]; static art, no glow |
| 11 | Conduit | 50 mm | 2 px at x 208-210, y 339-440, floor plate | camera, keypad and lock wiring into the floor, strapped twice |
| 12 | Back plate, ends, roof | 6 mm plate, 3 bolted panels | x 33-197, y 344-440 (behind WOLF) | closes the bay; calm backdrop for WOLF |
| 13 | Charger / cell-controller cabinet | 0.50 x 1.30 m | 20 x 52 at x 36-56, y 388-440 | power supply and controller for cradle and umbilical, fed from the floor |
| 14 | Belly cradle | pedestal 0.25 m wide, saddle 0.50 m, top 0.80 m | pedestal x 121-131, y 413-440; saddle x 116-136, y 407-414 | sits in the gap between his fore and hind legs (x 119-133, measured from the sprite); carries his weight while motors are locked out; charging contacts in the pad (idea from Spot Dock [4]) |
| 15 | Spring cable reel | 0.40 x 0.20 m | 16 x 8 at x 124-140, y 348-356 | holds and winds the umbilical; conduit along the roof to the cabinet |
| 16 | Umbilical + breakaway connector + dock lamp | cable 50 mm; connector 0.15 x 0.28 m | cable x 131-133; connector x 129-135, y 386-397 on his back (back line at y 394); retracted to y 359-370 | charge + data + motor lockout; lets go under load like a lanyard-release umbilical (est); lamp amber / blue / off |
| 17 | Gasket strip | 25 mm | 1 px on the latch post's inner face, y 346-433 | the seal the leaves close onto |
| 18 | Contact shadow | | y 440-445, x 23-207 | grounding |

**Fit (measured from the sprite):** WOLF is 115.3 x 61.6 world px (2.90 x 1.55 m) inside a clear interior of 164 x 96 px (4.10 x 2.40 m). That leaves 0.6 m at each end and 0.8 m of headroom above his ears. The bay is 1.60 m deep with 1.22 m clear inside. His width of about 0.8 m is an estimate (1.6x Spot's 0.50 m [2]), which leaves about 0.2 m each side. He docks and leaves by **sidestepping** in and out through the 3.00 m front opening, as quadruped robots can strafe. The cradle sits between his legs along his length, so a sidestep clears it. A plan view can show this; a side view never has to.

**Inside every hard limit from AUDIT §6:** the outer extent is x 23-213, y 330-445, within today's x 27-213 (lid) by y 292-451, and lower at the top. The card clears by more than 70 px. The beat 0-6 framing is unchanged, and the left 27 px are cut off from beat 4 on, as today. The right side stops at x 213, clear of the Director's coat at 245.8. Nodes stay at (115, 365). WOLF's start (115, 423), exit x 185, beat 6 x 110 and all of his timings are unchanged. The Director stays at (255, 410) and then (310, 410).

## 4. How each beat plays (frames in `shots/design/`, same file names as the audit's)

| Beat | Approved line | What the unit does | Frame |
|---|---|---|---|
| 0 | "DIRECTOR: I decide who counts as a threat. WOLF handles the rest." (card "03:17 / CONTAINMENT") | Closed. WOLF dark on the cradle, umbilical on his back with amber lamp, status lamp green. | 01 |
| 1 | "The Director thinks WOLF is still in standby." | Same: amber = standby (docked, charging, motors locked out). | 02, `beat1-standby.png` |
| 2 | "Nobody gives an activation command. WOLF wakes himself. A blue light answers from inside the containment seal." | Dock lamp eases amber to blue over 0.45 s (blue = computers on, motors still locked out: the Spot convention [37]), with a small blue pool on the back plate behind him. The status lamp stays green: the door is still locked. Main's own tint brightens WOLF. | 03, 04 |
| 3 | "The latch breaks from the inside. The gate slides aside. WOLF steps out under his own power. The Director freezes at the sound of the seal opening." | **0-0.15 s:** main's boom, flash and shake fire. The guard lock tears off and swings down by its cable, leaving scars on the post. The status lamp goes to flashing red. The connector lets go and the reel winds it up (lamp out). The leading leaf jumps 3 px. Amber sparks come from the lock. **0.15-0.65 s:** the leaves telescope left (cubic ease-out, 0.5 s) to the stack at x 33-77. **0.65 s on:** main's z swap and 8 px step-down, then the walk to x 185, "under his own power" now literally on battery. | 05-17, `beat3-latch-fails.png` (f009 = 0.15 s), `beat3-stepping-out.png` (f048 = 0.8 s) |
| 4-5 | "You were in standby" / lockdown order | Open bay: empty cradle, wound-up connector, stacked leaves, the hanging lock, red flashing. | 19-21 |
| 6 | "WOLF turns from the Director and takes the only open route." | Unchanged. He walks left to x 110, in front of the open bay. **Problem 20 stays Nathanial's call**; this design neither fixes it nor makes it worse. | 22, 23 |
| 7 | fade | Unit hidden by `_finish_intro`, as today (see open decisions). | 24, 25 |

**Line changes needed: none.** Each approved line now has a part on screen to point at: standby (cradle, umbilical, amber), wakes himself (blue with no command), containment seal (gasket and plate bay), latch breaks from inside (the guard lock), gate slides aside (telescoping leaves), under his own power (umbilical released), the sound of the seal opening, and "03:17 / CONTAINMENT".

**Sound (proposal, not made):** main's `boom` still plays. A closer match to "the sound of the seal opening" would be a metallic bang at the lock, then the leaves' track rumble over 0.5 s, then a short alarm tick with the red lamp. That fits his procedural-audio direction and is not built here.

## 5. What implementing it would change (for the record; nothing here is done)

- `containment_cage.gd`: three modes on one script. `shutter` (leaves, z 3, the existing `IntroGate`) and the default frame (z 4, the existing `IntroCage`) keep their nodes. A new `back` mode needs **one new node**, `IntroBay` (z 1, at (115, 365)), shown and hidden alongside the other two in `_new_game`, `_finish_intro` and `_load_game`.
- One drive value as today. `IntroGate.opening` 0 to 1 stays the only thing main tweens, and the gate forwards it to the frame and the bay. `m0_scene_test`'s asserts (gate visible, `opening == 1.0` during beats 3-4, hidden after) are untouched.
- `wake` 0 to 1: **one tween line** in `_advance_intro` beat 2.
- Beat-3 timing: the 0.65 s tween becomes 0.15 s linear (0 to 0.04, the break) plus 0.5 s cubic out (0.04 to 1). The total is still 0.65 s, so WOLF's z swap, step-down and walk keep their times.
- `gate_dust` (16 large beige dust puffs spread along the floor) becomes `FxPresets.sparks(SPARK_AMBER)` at the lock (198, 400) with particle scale 0.4-0.9. One emitter swapped for another; nothing added.
- Art: in the REAL-LOOK §4 pipeline these flat layers are step 1 (construction render and masks). Codex would paint inside them in step 2, before anything ships.

## 6. Cost (desktop only, same machine, same session, same driver; Godot monitors, GL Compatibility on an M1 Pro)

| Frame | main: draw calls / primitives / objects | option C |
|---|---|---|
| beat 1 standby | 71 / 2390 / 202 | **47 / 2072 / 142** |
| beat 2 wake | 67 / 2008 / 224 | 43 / 1692 / 165 |
| beat 3, 0.15 s | 68 / 2094 / 252 | 43 / 1796 / 194 |
| beat 4 open | 67 / 1924 / 182 | 40 / 1606 / 122 |

- **Fewer draw calls than main.** The textured design costs about 24 fewer draw calls per frame than main's code-drawn cage. A first all-code-drawn version of this design (kept as `driver/containment_unit_codedrawn.gd`) cost about 50 *more*, which is why it was redone as layers.
- **Layers:** 3 textured layers (back, leaves, frame) plus a lock sprite, and about 12 live rects.
- **Glows:** 2 persistent glows (status lamp and dock lamp), within the budget of 4. The blue pool exists only in beat 2.
- **Runtime effects:** none added, and no full-screen layer.
- **Redraws:** the red flash redraws the frame 4 times a second during beats 3-6 only.
- **Texture memory**, at 4 px per world px: 2.97 MB as RGBA8 (3.96 MB with mipmaps), about 1.0 MB VRAM-compressed (calc). In this scratch copy both stencil variants of the frame were loaded; a real build loads one.
- **Phones:** none of this is a device measurement (REAL-LOOK §5).

**Readability (calc, not a device test).** On a 6.1-inch phone in landscape, one world px at zoom 1.95 is about 0.24 mm, so:
- the guard lock is 1.9 x 3.3 mm;
- the status lamp's glow is about 3.3 mm across;
- the keypad is 1.4 x 2.1 mm: it reads as "a box with a key grid", but single keys are not readable.

What carries each beat on a phone is large-scale and colour change: the green-to-red lamp, the lock dropping and tilting, the leaves moving 3 m, the amber/blue lamp on his back and the empty cradle. Anything a later PIN puzzle needs to show digits for must be a close-up or UI. That is Nathanial's PIN decision.

## 7. Proposed sign and stencil text (awaiting Nathanial; neutral; no story names)

| Text | Where | Size | Why |
|---|---|---|---|
| `CU-01` | head beam, left | 6.4 px cap (0.16 m) | equipment number, "containment unit 1" (RESEARCH §10 C; REAL-LOOK §8 equipment plates) |
| `KEEP CLEAR` | head beam, right | 6.4 px cap | the keep-clear zone around an energised robot (Spot: 2 m [37]) |

Both are typeset in the game's bundled Roboto and baked into the frame layer, with no runtime labels. `frame_notext.png` is the same layer with both removed.
- **Conflict:** REAL-LOOK checklist 7 says "no text in art", so Nathanial must allow these as an exception or drop them. The design works without them.
- **Size:** the 6.4 px cap height is under REAL-LOOK §8's 8 px minimum for legible marks, because the 0.30 m beam only fits that. The options are an 8 px cap with a 14 px beam, or no text.

No Skynet, Terminator or Cyberdyne names, logos, machines or designs are used: no red-eye or skull cues, no chrome, no model numbers. The palette is a darkened version of the FED-STD-595 greys (REAL-LOOK §8), with one yellow element (the striped stile) and red only for the door-forced lamp.

## 8. Risks and open decisions (Nathanial's)

1. **A deliberate change to the cage.** Picking this replaces today's cage. Nothing changes until he says so.
2. **Text exception** (section 7).
3. **Problem 20** (beat 6 walks left toward the bay). This is unchanged and needs his staging call; the bay has no rear exit.
4. **Does the broken bay stay in play?** Today the unit disappears at the fade. A broken-open bay that stays would be more real, but it sits where the purge display, the engineer's spawn (x 160) and WOLF's spawn (x 72) are. That is his decision, and the default is to keep today's hide.
5. **Mesh pitch.** It is drawn at a 75 mm pitch to read as mesh. A real RF screen is much finer and would read as a flat tone. At phone scale the 3 px tile may shimmer (moire) while the camera moves. Check on a device, or drop to a plain tone plus frames.
6. **The RF-seal reading** (section 2) is construction logic, not story. Drop it if it suggests more than he wants.
7. **Lamp colours.** Sources support red/green lock-status lamps [31] and Spot's blue/red power lamps [37], but not which colour means "locked". Green = locked, red = door forced is my legibility choice. Real access readers often idle red. Amber = standby is a design choice with no source.
8. **The 0.15 s break hold** changes the beat-3 tween shape: same total time, but a slower first 0.15 s. It reads in stills; feel is unverified.
9. **The sparks** reuse the relay's spark preset at a smaller scale. In one frame (0.2 s) they spray across the Director's coat. A tighter spread may be wanted.
10. **WOLF's body is an estimate:** the mass (250-350 kg) and width (~0.8 m) are not measured. The cradle position comes from the sprite's leg gap, so a different WOLF frame would move it.
11. **What was not done:**
    - no hands-on play, no audio listening, no export, no phone or tablet test;
    - every claim about feel or phone readability is unverified;
    - the frames come from a scripted run in one normal window, and the cost numbers are desktop only.

## 9. Files

- `DESIGN.md`: this file.
- `construction-drawing.png`, `strip.png`, `beat1-standby.png`, `beat3-latch-fails.png`, `beat3-stepping-out.png`.
- `render/layers/*.png`: the flat-shaded layers (back, leaf, leaf_lead, frame, frame_notext, lock) at 4 px per world px. These double as the per-part masks for REAL-LOOK §4.
- `driver/design_art.py`: draws the layers from one table of local coordinates.
- `driver/sheets.py`: builds the construction drawing, the labelled beats and the strip.
- `driver/containment_unit_design.gd`: the scratch scene script (layers plus live parts).
- `driver/containment_unit_codedrawn.gd`: the first, too-expensive all-code version, kept for the cost comparison.
- `driver/design_opening.gd`: the capture driver; `--design=0` gives the main baseline.
- `shots/design/`: 33 shots plus UI-free copies and `_log.json` (camera, gate, WOLF and render monitors per shot).
- `shots/base/`: main baseline, same driver.
- `game-design/`, `game-base/`: scratch exports of `7c19ee2`, not Git worktrees.
- `logs/`: import and run logs, contact sheets.
