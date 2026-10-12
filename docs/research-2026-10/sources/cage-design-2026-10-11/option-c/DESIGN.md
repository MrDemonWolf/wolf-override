# WOLF's containment, option C: a standby dock in a guarded bay (revision 2)

Private scratch, 2026-10-11. This is a proposal for Nathanial to pick from, nothing more. The game, the cage and the opening on `main` (`7c19ee2`) stay exactly as they are until he chooses ("the cage for the wolf should been the same 100% the same before"). No Git repository or worktree was touched. Every image here is a **design drawing**: flat-shaded layers I constructed by script, not final art, with no AI image generation. All sign text and the keypad are **proposed, awaiting Nathanial**.

Built on `../audit/AUDIT.md` (hard limits, measured on main) and `../research/RESEARCH.md` (sourced; numbers like [9] or [37] below are its source list). Art rules come from `docs/research-2026-10/art-direction/REAL-LOOK.md`, including §8 Military base.

## 0. What changed in revision 2 (the judge's fixes before Nathanial sees it)

The idea is unchanged: WOLF is held by his power state first and by steel second. Revision 1 is kept in `../_v1-before-fixes/option-c/`.

| Judge's fix | What I did | Evidence |
|---|---|---|
| WOLF hard to see in standby (contrast 1.14; main 1.28) | A vapour-tight LED fitting on two stems in the bay roof (part 20). Its light is **painted** onto the back plate, the cabinet lid, the stand and the saddle, with an elliptical falloff from the fitting (no runtime glow). The kick plate drops from 0.30 m to 0.15 m, so his legs and feet read too. | `judge/contrast.py` method: **1.36** at beat 1 (main 1.28). Beat 2: 1.12 (main 1.10). |
| Amber lamp floats: 2 px cable invisible; cradle reads as a lectern | Umbilical 3 px (75 mm), light grey with a lit and a shaded edge, lighter than the lit plate. Connector 7 x 12 px with a light housing, a dark latch band and a strain relief. The cradle is now a **robot stand**: an anchored plinth with a base flange, 2 anchor nuts and gussets, a column, a U saddle with side lips, a rubber contact pad with 2 copper charging contacts, and floor conduit to the cabinet. | `beat1-standby.png`, `shots/design-r2/28-closeup-closed-cradle.png`, `31-review-open.png` |
| Keypad and camera on a 50 mm conduit pole | A **lock pilaster** (part 19, from B): a 0.30 m steel column through-bolted to the latch post, with an anchored base plate. It carries the guard lock, the 1.2 m backplate with the status lamp, the camera (on an arm on its cap, with a sun hood), and one strapped surface conduit down its face into a **floor box** (part 21). The pole is gone. | `27-closeup-closed-lock.png`, `30-closeup-closed-camera.png` |
| Make the bolt a hook bolt (from A) | The handle module throws a **hook bolt** into the guard lock's keeper. WOLF's drive out of the bay (outward, toward the camera) loads it in prying, the lock's mounting bolts shear, and the module tears off and hangs by its cable. After the breach the thrown hook is visible on the stile as the leaves slide away. | Detail E on `construction-drawing.png` |
| Sparks cross the Director's coat at 0.2 s | The spark burst now starts at the lock (199, 399), aims up and back (direction (-0.45, -1), spread 22°, 70-140 px/s). | `logs/r2-sparks-check.txt`: right-most spark x **≤ 198.7** in every frame from 0.03 to 0.27 s (revision 1: up to **250.8**, past the coat at 245.8). |
| Captions over the top card and PAUSE | The beat images carry their caption in a band **below** the frame. | `beat1-standby.png`, `beat3-*.png` |
| No phone-size check; mesh may shimmer | `render/phone-check.png`: the beats shrunk to 534 x 300, plus real renders with the game window at 534 x 300, plus the mesh during beat 2's real camera zoom, frame by frame. Flicker measured (`../fix/shimmer.py`). | Section 6 |
| RF-shield reason; "seal" on a 1 px gasket | The RF reasoning is gone. Part 17 is now a plain rubber closing-edge buffer. Section 2 says plainly that with a mesh front, "containment seal" is a loose phrase. | Section 2 |
| Stencils 6.4 px (under 8 px) | Head beam 0.35 m [14 px]. Stencils are typeset in the bundled Roboto at **8.1 px caps**. A blank-plate version is drawn as well. | `render/layers/frame.png`, `frame_notext.png` |
| Keypad must be optional | The keypad is labelled optional lock hardware. A **blank 1.2 m backplate** (blanking cover, 4 screws, status lamp kept) is drawn and captured as the alternative. With blank plates as well, it needs no exception from Nathanial. | `beat1-standby-no-text-no-keypad.png`, detail F |
| Say what moves the leaf | Section 4 says plainly that nothing on screen moves the leaves once the lock has failed. Moving WOLF to the latch edge first is offered as his decision. | Section 4 |

## 1. What it is, in one paragraph

WOLF is parked the way a real military robot is parked: **held by power state first and by steel second** (RESEARCH §6). He stands over a **robot stand** anchored to the floor, which carries his weight while his motors are locked out. A **charging and control umbilical** drops from a spring reel under the roof and plugs into his back. Its **dock lamp** shows his state. Round him is a **guarded bay**: plate back, ends and roof, lit for the camera by one LED fitting in the roof, with a front of four **telescoping mesh leaves** on top tracks (the robot-cell guard pattern, RESEARCH §7). The leaves are held shut by a **fail-secure guard lock** (spring-locked, power-to-unlock [29][34][35]) whose keeper takes a **hook bolt** from the leading leaf. The lock sits outside, out of his reach, on a **lock pilaster** bolted to the latch post. The pilaster also carries a 1.2 m backplate with the status lamp (and, if Nathanial wants it, a card slot and PIN pad), a fixed **camera**, and one conduit into a floor box. At beat 3 WOLF breaks the only part a robot can break from inside: his drive out of the bay pries the hook against the keeper, the lock tears off its mount and hangs by its cable, the status lamp goes to flashing red ("door forced"), the breakaway umbilical lets go, the leaves telescope aside, and he steps out on his own battery. **Nobody enters a code.**

Images:
- `construction-drawing.png`: (A) labelled front elevation at the game's scale, 21 numbered parts, dimensions in m and [world px], WOLF's fit box and the Director for scale; (B) plan; (C) lamp states; (D) actual size at 1280x720; (E) hook-bolt detail; (F) the no-text, no-keypad alternative.
- `beat1-standby.png`, `beat3-latch-fails.png`, `beat3-stepping-out.png`: full 1280x720 frames of main's opening, caption below the frame.
- `beat1-standby-no-text-no-keypad.png`: the same beat with blank plates and a blank backplate.
- `render/phone-check.png`: the 534 x 300 check.
- `strip.png`: the three beats above the construction drawing.

**How the frames were made.** Main was exported to `game-design/`, and `scripts/containment_cage.gd` was swapped in that scratch copy for `driver/containment_unit_design.gd`. That script draws the layer PNGs from `driver/design_art.py` (`render/layers/`) plus a few live parts. A third node (the bay behind WOLF) is added at runtime by `driver/design_opening.gd`, which then plays main's real opening with real `interact` taps at a fixed 60 fps in one normal window. The window is kept on top: macOS stops Godot drawing an occluded window, which stalled two runs. Every window closed itself (exit 0). Everything else in the frames is main: the room, the actors, the camera, the UI, the text, the flash and the shake. They are still frames. Nothing was played by hand.

## 2. Why it makes sense (what it fixes from the audit)

| Audit finding | This design |
|---|---|
| Lid in a different projection; asymmetric overhang (1) | One projection, a pure side elevation. The cap plate overhangs 2 px on both sides. |
| Frame with one face, see-through (2, 10) | Plate back, ends and roof; only the front is mesh. Open, it shows the empty bay (stand, cabinet, reel), not the room's tank. |
| Bars not held, gate not attached on the latch side, no latch (3, 4) | The leaves hang from 4 top tracks and run in the sill's bottom guide. The leading leaf's hook bolt engages a real guard lock on the latch post and pilaster. |
| Impossible fold, rigid rails shrinking (5) | Telescoping leaves are rigid, overlap on parallel tracks and keep their size. Clear opening 3.00 m. |
| Zoo-crate proportions (6) | Welded mesh, drawn at a 3 px (75 mm) pitch so it reads as mesh. 0.15 m kick plate (a machine needs no anti-reach plate, and his feet should read). |
| Floats: no feet, bolts or shadow (8) | Sill on y 440, anchor plates, the pilaster's anchored base plate, the floor box, the stand's anchored plinth, and a contact shadow darkest at the contact line. Every device on the pilaster sits on a backplate or bracket. |
| Standing pose says nothing about standby (11, 18) | Stand under his belly, umbilical on his back, amber dock lamp. |
| Nothing breaks; dust from the floor (12) | The guard lock visibly tears off and hangs by its cable, with bright scars where it was bolted. A narrow amber spark burst comes from the lock (the existing spark preset replaces the floor dust; nothing is added). |
| Walks through the post (13) | The bay has a whole-front door. He steps forward out of it (main's 8 px step-down reads as "toward camera"), so he is in front of the post when he walks right. |
| Lamps never react (16) | Status lamp: green, then flashing red. Dock lamp: amber, then blue, then off. |
| Blue light is a brighter wolf (17) | A real blue lamp on the connector, with a small blue pool on the plate behind him. |
| Light with no source (REAL-LOOK checklist 2) | Every lit face in the bay points at the visible roof fitting; above the fitting the roof stays in shadow. |

**Why fail-secure, and why it still breaks.** A maglock opens when power fails, so no real cell for a dangerous machine would hang on one [29][30]. Guard locks for machine cells are spring-locked and power-to-unlock, rated at about 2,000 N locking force for the Euchner MGB [35]. Such a cell expects the robot's **motor lockout** to be the primary hold, with the lock as the guard. **WOLF's mass, my estimate:** about 250-350 kg (a ~2.1x linear scale-up of Spot, 32.5 kg [2], discounted for a lighter frame). **Shove:** at 0.7-1 g he pushes about 1.7-3.4 kN, which reaches or passes a 2 kN guard lock. A **hook bolt** resists both sliding and prying (A's reasoning), so his drive out of the bay loads the keeper directly. Once he has woken himself and his motors are live, the steel is under-rated for him: the bolt stays thrown, and the module's mounting lets go (RESEARCH §10 B, "keeper tears out"). Nobody works the keypad, and the lock is out of his reach, so "breaks from the inside" means force from inside, not a hack.

**"Containment seal" is a loose phrase here.** The bay is closed on five sides by steel plate and locked on the sixth by a mesh guard. It is not airtight or sealed in any literal sense; "seal" reads as "the sealed, locked unit". Option B is the one that makes the word literal (an inflatable door seal). Part 17 is only a rubber buffer where the stile lands. No line needs changing for this, but if Nathanial wants the word to be literal, that argues for B's door seal.

## 3. Parts (1 m = 40 world px; local origin = world (115, 365); floor = world y 440)

Numbers match the callouts on `construction-drawing.png`.

| # | Part | Real size | World px | Job |
|---|---|---|---|---|
| 1 | Head beam + cap plate | 4.40 x 0.35 m beam, 4.50 m cap | x 27-203, y 330-344; cap y 328-330 | carries the 4 top tracks; 8 px stencils or blank plates |
| 2 | Posts | 150 mm box section, 2.75 m | 6 px; x 27-33 and 197-203 | frame |
| 3 | Sill / bottom guide | 0.15 m | x 27-203, y 434-440 | leaves run in it; steel threshold |
| 4 | Anchor plates | 0.35 m, 2 bolts each | x 30 and 115 | into the slab (the pilaster base takes the right one) |
| 5 | Leaves (4) | 1.10 x 2.25 m, 0.15 m kick plate | 44 x 90; kick plate y 428-434 | welded mesh in a steel frame; left leaf fixed; open stack x 33-77 |
| 6 | Leading stile + handle module | 0.10 m stile | x 193-197 | crush-point stripes (the one yellow element); throws the hook bolt |
| 7 | **Guard lock** (the part that fails) | 0.20 x 0.35 m, 0.85-1.20 m up | x 195-203, y 392-406 | fail-secure, spring-locked, power-to-unlock, hook bolt monitored; keeper slot; outside, out of reach |
| 8 | Backplate at 1.2 m; **optional** card slot + 12-key pad | backplate 0.20 x 0.55 m; pad drawn 1.5x real | x 203-211, y 380-402; pad centre y 392 | lock hardware only; **no code entered**. Alternative: a blanking cover (`frame_plain.png`) |
| 9 | Status lamp | lens 65 mm | (207, 383.3), 1.42 m | green = locked and bolt monitored; red 2 Hz = door forced |
| 10 | Camera | 0.30 x 0.10 m housing with a sun hood | x 199.4-212.6, y 320.6-327.4, on the pilaster cap | watches the door [15][16]; static art, no glow |
| 11 | Conduit | 45 mm, strapped | x 210-212, y 332-427 | camera, lock and backplate wiring into the floor box |
| 12 | Back plate, ends, roof | 6 mm plate, 3 bolted panels | x 33-197, y 344-440 | closes the bay; lit by part 20 |
| 13 | Charger / cell-controller cabinet | 0.50 x 1.30 m | x 36-56, y 388-440 | power and control for the stand and umbilical |
| 14 | **Robot stand** | plinth 0.70 x 0.35 m, column 0.25 m, saddle 0.65 m, pad top 0.83 m | plinth x 112-140, y 426-440; saddle x 113-139, y 404.5-412.5 | anchored; carries his weight while motors are locked out; rubber pad with 2 charging contacts (idea from Spot Dock [4]); floor conduit to the cabinet |
| 15 | Spring cable reel | 0.40 x 0.20 m | x 124-140, y 348-356 | holds and winds the umbilical |
| 16 | Umbilical + breakaway connector + dock lamp | cable 75 mm; connector 0.18 x 0.30 m | cable x 130.5-133.5; connector x 128.5-135.5, y 385-397 | charge, data and motor lockout; lets go under load; lamp amber / blue / off |
| 17 | Rubber closing-edge buffer | 25 mm | 1 px on the latch post's inner face | where the leading stile lands |
| 18 | Contact shadow | | y 440-445, x 23-214 | grounding |
| 19 | **Lock pilaster** | 0.30 m steel column, anchored base plate | x 201-213, y 332-440 | carries 7-11; through-bolted to the latch post |
| 20 | **Roof fitting** | vapour-tight LED fitting, 1.15 m, on 2 stems | x 75-121, y 349-352 | the one light in the bay; its light is painted in |
| 21 | Floor box | 0.25 x 0.26 m, lockable cover | x 202.5-212, y 427-437.5 | all wiring enters the slab here |

**Fit (measured from the sprite):** WOLF is 115.3 x 61.6 world px (2.90 x 1.55 m) inside a clear interior of 164 x 96 px (4.10 x 2.40 m). The bay is 1.60 m deep with 1.22 m clear. His width of about 0.8 m is an estimate (1.6x Spot's 0.50 m [2]). He docks and leaves by a 0.8 m **sidestep** through the 3.00 m front opening. The side view cannot show that sidestep: on screen it is only main's 8 px step-down.

**Inside every hard limit from AUDIT §6:** the outer extent is x 23-214 (shadow) and x 27-213 (steel), y 320.6-445. That is within today's x 27-213 by y 292-451, and lower at the top, so the card still clears by more than 60 px. The right edge stays at x 213, clear of the Director's coat at 245.8. Nodes stay at (115, 365). WOLF's start, exit x 185, beat 6 x 110 and all his timings are unchanged. The Director stays at (255, 410) and then (310, 410).

## 4. How each beat plays (frames in `shots/design-r2/`)

| Beat | Approved line | What the unit does | Frame |
|---|---|---|---|
| 0 | "DIRECTOR: I decide who counts as a threat. WOLF handles the rest." | Closed. Dark WOLF on the stand against the lit back plate, umbilical on his back with amber lamp, status lamp green. | 01 |
| 1 | "The Director thinks WOLF is still in standby." | Same: amber = standby (docked, charging, motors locked out). | 02, `beat1-standby.png` |
| 2 | "Nobody gives an activation command. WOLF wakes himself. A blue light answers from inside the containment seal." | Dock lamp eases amber to blue over 0.45 s, with a small blue pool behind him. Status lamp stays green. Main's own tint brightens WOLF. | 03, 04 |
| 3 | "The latch breaks from the inside. The gate slides aside. WOLF steps out under his own power. The Director freezes at the sound of the seal opening." | **0-0.15 s (hold):** main's boom, flash and shake fire. The guard lock tears off and swings down by its cable, leaving scars. The status lamp goes to flashing red. The connector lets go and the reel winds it up. A narrow amber spark burst comes from the lock, falling back along the post. The leaves do not move. **0.15-0.65 s:** the leaves telescope left (cubic ease-out, 0.5 s), with the thrown hook bolt visible on the stile. **0.65 s on:** main's z swap, 8 px step-down, then the walk to x 185. | 05-17, `beat3-latch-fails.png` (0.15 s), `beat3-stepping-out.png` (0.80 s) |
| 4-5 | "You were in standby" / lockdown order | Open bay: empty stand, wound-up connector, stacked leaves, the hanging lock, red flashing. | 19-21 |
| 6 | "WOLF turns from the Director and takes the only open route." | Unchanged; problem 20 stays Nathanial's call. | 22, 23 |
| 7 | fade | Unit hidden by `_finish_intro`, as today. | 24, 25 |

**Nothing on screen moves the leaves once the lock has failed.** WOLF stands still in the bay while the leaves slide aside by themselves, and the design has no motor or spring that would open them. (Revision 1's 3 px "jump" of the leading leaf has been removed; it implied a push that nobody makes.) The fix is a staging change, and it is **Nathanial's decision** because it changes beat 3:
- **(a)** WOLF walks about 20 px right to the latch edge during the 0.15 s hold. His drive then visibly loads the hook and starts the slide, and his rear no longer passes the stacked leaves (about 18 px of tail today).
- **(b)** Alternatively, keep his position and add a short forward lurch (a few px) at the start of the slide.

Until he picks, the frames keep main's staging.

**Line changes needed: none.** Each approved line has a part on screen to point at, with "containment seal" loose as explained in section 2.

**Sound (proposal, not made):** a metallic bang at the lock, then the leaves' track rumble over 0.5 s, then a short alarm tick with the red lamp.

## 5. What implementing it would change (for the record; nothing here is done)

- `containment_cage.gd`: three modes on one script. `shutter` (leaves, the existing `IntroGate`, z 3) and the frame (the existing `IntroCage`, z 4) keep their nodes. A new `back` mode needs **one new node**, `IntroBay` (z 1, at (115, 365)), shown and hidden alongside the other two in `_new_game`, `_finish_intro` and `_load_game`.
- One drive value as today: `IntroGate.opening` 0 to 1 stays the only thing main tweens. `m0_scene_test`'s asserts are untouched.
- `wake` 0 to 1: one tween line in beat 2.
- Beat-3 timing: 0.15 s linear (0 to 0.04, the break) plus 0.5 s cubic out (0.04 to 1). The total is still 0.65 s.
- `gate_dust` becomes `FxPresets.sparks(SPARK_AMBER)` at the lock (199, 399), with direction (-0.45, -1), spread 22°, velocity 70-140 and scale 0.4-0.9. One emitter swapped for another.
- One frame layer ships, whichever Nathanial picks: `frame.png` (stencils and keypad), `frame_notext.png` (blank plates, keypad) or `frame_plain.png` (blank plates, blank backplate).
- Art: these flat layers are REAL-LOOK §4 step 1 (construction render and masks). The painted fitting light here is a value plan for the painter, not finish.

## 6. Cost and phone check

**Godot monitors** (desktop, GL Compatibility, M1 Pro; same driver; main baseline from `shots/base/`):

| Frame | main: draw calls / primitives / objects | revision 1 | **revision 2** |
|---|---|---|---|
| beat 1 standby | 71 / 2390 / 202 | 47 / 2072 / 142 | **46 / 2080 / 146** |
| beat 2 wake | 67 / 2008 / 224 | 43 / 1692 / 165 | **42 / 1700 / 169** |
| beat 3, 0.15 s | 68 / 2094 / 252 | 43 / 1796 / 194 | **43 / 1808 / 200** |
| beat 4 open | 67 / 1924 / 182 | 40 / 1606 / 122 | **40 / 1618 / 128** |

- **Glows:** 2 persistent (status lamp, dock lamp), within the budget of 4. The roof fitting's light is painted into the back layer and costs nothing at runtime. The blue pool exists only from beat 2.
- **Runtime effects:** none added, and no full-screen layer. The red flash redraws the frame 4 times a second during beats 3-6 only.
- **Texture memory** for the shipped set (back, leaf, leaf_lead, one frame, lock) at 4 px per world px: 3.08 MB RGBA8 (4.10 MB with mipmaps), about 0.8 MB VRAM-compressed (calc).
- **Red in view:** the unit adds one red element (the status lamp, after the breach). The room's own red beacon at the top of the frame is main's and is unchanged.

**Phone-size check** (`render/phone-check.png`; stills on a Mac, not a device):
- Shrunk to 534 x 300 (as B did): the dark WOLF on the lit bay, the green lamp, the red lamp after the breach and the hanging lock all still read. The keypad reads only as a small grid. The stencils read as words.
- Rendered with the game window at 534 x 300 (Godot drew 533 x 300): the mesh minifies to a fine tone (mipmapped). Watched frame by frame through beat 2's real camera zoom, it shows no moire bands.
- **Flicker** (`../fix/shimmer.py`, `logs/r2-shimmer.txt`): each zoom frame is resampled to world and blurred over one mesh cell, and its second difference in time is measured. In the bay's WOLF-free left end, mesh against a flat tone in the same place: **1.005 vs 0.799** at 1280 x 720, and **1.296 vs 1.109** at 533 x 300 (RMS x 1000 of linear luminance). Main's bars: 0.474 and 0.626, but on a scene 5x darker. Relative to brightness, the mesh flickers 2.0-2.7% against main's 4.6-6.2%. So the mesh adds a small, measurable flicker over a flat tone, about 20% more, and no visible moire. This is a desktop measurement; only a device run proves a phone. If a device shows shimmer, `leaf_plain.png` is the drop-in fallback.

**Readability (calc).** On a 6.1-inch phone in landscape, one world px at zoom 1.95 is about 0.24 mm: the guard lock is 1.9 x 3.3 mm, the status lamp's glow about 3.3 mm, and the 8 px stencil caps about 1.9 mm. Digits for a later PIN puzzle need a close-up or UI.

## 7. Proposed sign and stencil text (awaiting Nathanial; neutral; no story names)

| Text | Where | Size | Why |
|---|---|---|---|
| `CU-01` | head beam, left | 8.1 px caps (0.20 m) | equipment number, "containment unit 1" (REAL-LOOK §8 equipment plates) |
| `KEEP CLEAR` | head beam, right | 8.1 px caps | the keep-clear zone round an energised robot (Spot: 2 m [37]) |

- Typeset in the game's bundled Roboto, colour #A9A6A8 (a lusterless light grey on dark paint), and baked into the frame layer, with no runtime labels.
- **Conflict:** REAL-LOOK checklist 7 says "no text in art", so this needs Nathanial's exception. Without it, `frame_notext.png` has **blank equipment plates** (riveted, no letters) in the same places.
- **Keypad:** REAL-LOOK §8 says "No new keypads or card readers until Nathanial picks the PIN design". The keypad is therefore drawn as **optional lock hardware**. `frame_plain.png` (blank plates and a blank 1.2 m backplate with a blanking cover and the status lamp) needs no exception at all. It is captured in `shots/design-r2-plain/` and `beat1-standby-no-text-no-keypad.png`.

No Skynet, Terminator or Cyberdyne names, logos, machines or designs: no red-eye or skull cues, no chrome, no model numbers. FED-STD-595-derived greys, one yellow element (the striped stile), and red only for the door-forced lamp.

## 8. Risks and open decisions (Nathanial's)

1. **A deliberate change to the cage.** Picking this replaces today's cage. Nothing changes until he says so.
2. **Beat-3 staging** (section 4): WOLF to the latch edge, a short lurch, or leave the leaves sliding unprompted.
3. **Text exception, and keypad or blank backplate** (section 7).
4. **The lit bay.** The painted fitting light is what makes the dark WOLF read. Open, the empty bay is now a lighter grey box than the room (beat 4). The painter should keep a visible falloff from the fitting, and Nathanial may want it dimmer at the cost of standby contrast (1.28 at a gentler wash, measured).
5. **Problem 20** (beat 6 walks left into the bay) is unchanged.
6. **Does the broken bay stay in play?** The default is today's hide at the fade.
7. **Lamp colours.** Green = locked and red = door forced are legibility choices; real readers often idle red. Amber = standby has no source.
8. **The 0.15 s break hold** reads in stills; feel is unverified.
9. **WOLF's mass and width are estimates.** The stand position comes from the sprite's leg gap.
10. **What was not done:**
    - no hands-on play, no audio, no export, no phone or tablet test;
    - every claim about feel or phone readability is unverified;
    - the frames come from scripted runs on a Mac, and the cost numbers are desktop only.

## 9. Files

- `DESIGN.md`, `construction-drawing.png`, `strip.png`, `beat1-standby.png`, `beat3-latch-fails.png`, `beat3-stepping-out.png`, `beat1-standby-no-text-no-keypad.png`, `render/phone-check.png`.
- `render/layers/*.png`: back, leaf, leaf_lead, leaf_plain, leaf_lead_plain, frame, frame_notext, frame_plain and lock, at 4 px per world px. These double as per-part masks.
- `driver/design_art.py` (layers), `driver/sheets.py` (drawing, beats, strip, phone check), `driver/containment_unit_design.gd` (scene script), `driver/design_opening.gd` (capture driver; `--stencils`, `--keypad`, `--mesh`, `--win`, `--mode=motion`).
- `shots/design-r2/` (33 shots plus UI-free copies and `_log.json`), `shots/design-r2-plain/` (the no-text, no-keypad variant), `shots/motion-{mesh,plain,main}-{1280,534}/` (shimmer runs), `shots/base/` (main baseline). Revision 1's shots are kept in `shots/design/`.
- `logs/r2-*.log`, `logs/r2-sparks-check.txt`, `logs/r2-shimmer.txt`.
- `game-design/`, `game-base/`: scratch exports of `7c19ee2`, not Git worktrees.
