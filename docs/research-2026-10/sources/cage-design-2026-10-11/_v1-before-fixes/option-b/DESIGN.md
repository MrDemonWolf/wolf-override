# Option B: a sealed containment cell for WOLF

Private scratch, written 2026-10-11 against `main` at `7c19ee2`. It answers Nathanial's "Make sure the wolf cagte design makes sense" and his new direction: "Can we add some pin codes and make it feel more like a furttgrue milialry base like iin skynet". The Terminator films are a mood reference only. Nothing here uses their names, logos, machines, designs or text.

**This is a proposal.** Nothing in any Git repository changed. The game keeps today's cage until Nathanial picks a design ("the cage for the wolf should been the same 100% the same before"). Every drawing and render here is a **flat-shaded design render, not final art**, and no AI image generation was used.

Files in this folder:

| File | What it is |
|---|---|
| `strip.png` | The three beats plus the construction drawing on one image |
| `render/construction.png` | Construction drawing: front elevation at game scale with WOLF's real sprite, end section A-A, plan, and an 18-part legend |
| `render/B1-standby.png`, `render/B3a-latch-fails.png`, `render/B3b-steps-out.png` | The three required beats: real 1280x720 captures of main's opening with the cell drawn in, plus a caption band |
| `render/extra-B2-wake.png`, `render/extra-B6-route.png` | Two extra beats |
| `render/phone-check.png` | The three beats shrunk to 534x300 |
| `driver/design.py` → `cell_spec.json` | **The single geometry source**, every part as a primitive in world px. The drawing, the in-game renders and the baked textures all come from it |
| `driver/cell_proto.gd`, `driver/cell_baked.gd`, `driver/driver.gd` | Scratch Godot prototype (vector and baked) and the capture driver |
| `driver/render_lib.py`, `bake.py`, `drawing.py`, `compose.py` | Python renderer, texture bake, drawing and compositing |
| `shots/run5` (vector), `shots/run6-baked`, `shots/main-base` | Raw captures, each with `_log.json` (camera, state and render monitors per shot) |
| `game/` | The scratch export of `7c19ee2` that was rendered (not a Git worktree) |

## 1. What it is

The unit is **a closed steel box that holds WOLF, not a cage.** It is an armoured cell 4.42 m long and 2.76 m tall, anchored to the slab. It has:

- **A solid back wall and roof.** WOLF is seen through two ballistic vision panels. A real secure enclosure has a skin, and a containment seal needs one.
- **One sliding armour leaf.** The leaf is top-hung on an exposed box track. It closes over a gasketed opening on the right half of the front and slides left to park over the fixed left panel. "The gate slides aside" happens literally, and the leaf parks inside the footprint.
- **Lock hardware on a pilaster at the right end.** This is the keeper's side, facing the Director:
  - a fail-secure bolt lock;
  - a PIN keypad and card reader on a tamper-proof backplate at 1.2 m;
  - a three-tier stack light;
  - all wiring in rigid conduit run down into the floor.
- **A ceiling umbilical (power and data)**, plugged into WOLF's shoulders while he is in standby.
- **A fixed camera on an arm** at the far end, watching the door.

Nobody needs to stand near it for it to work: it is a machine-run unit.

How it breaks open: the bolt holds. WOLF forces the leaf, and the **keeper** (the steel bracket on the leaf that the bolt sits in) **tears out of the leaf's edge and falls**. The bolt is left sticking out of the lock box into empty air, the stack and lock lamps go red, the inflatable seal tears at the lock edge, and the free leaf runs along its track. Nobody enters a code; the keypad is lock hardware only.

## 2. Why it makes sense

- **It is held by what really holds dangerous machines.** Secure doors pair a badge or PIN reader outside with a lock that holds without power, a door sensor and a camera, and the wiring sits on the secure side (RESEARCH §4, [15]). For a cell, the secure side is the outside, as zoo rules require for shift-door controls ([11]).
  - The lock is **fail-secure**, meaning spring-locked and power-to-unlock. A maglock would open in a power cut ([29], [34], [35]).
  - The pilaster also carries a manual back-up key ([12]).
- **The opening's words become literal:**
  - **"Containment seal":** an inflatable door seal on the frame ([42]-[44]).
  - **"A blue light answers from inside":** WOLF's own status light, seen through the sealed glass, washing the cell's grey interior blue. On a real quadruped robot, blue means "computers on, motors locked out" ([37]).
  - **"The latch breaks from the inside":** a visible keeper failing while the bolt is still thrown. The research's reading is that "breaks" means the normal order (seal vents, bolt withdraws, door moves) is broken (RESEARCH §8).
  - **"The sound of the seal opening":** the torn seal venting. This needs a sound change; see §6.
- **Standby has hardware.** A powered, reeled umbilical reaches him and he ejects it when he wakes, matching docked robots that get power and Ethernet from a dock ([4]). The interior is light grey so the camera can see him.
- **The lamps mean something and change.** The stack light uses the EN/IEC 60204-1 colour meanings: green = normal, yellow = abnormal, red = emergency ([S1], [S2], secondary summaries of the standard). In this cell, green = sealed and locked, amber = the unit's state changed, red = breach. The lock lamp shows the bolt state: green = bonded, red = the leaf is not on the bolt (the BondSTAT idea, [31], [32]).
- **It reads as a near-future military installation** without borrowing anything:
  - armour plate in Gunship-Gray-like values;
  - a stencilled equipment code;
  - caught-between hazard stripes on the moving edge only (OSHA yellow, REAL-LOOK §8 [M9]);
  - a camera, conduit to a floor vault (REAL-LOOK §8 [M17]) and anchor bolts.

  There is no chrome, no glowing seams and no holograms.
- **Everything is grounded:** a base channel, anchor flanges with bolts into the slab, and a contact shadow darkest at the contact line. Nothing floats, which meets REAL-LOOK checklist 4.

## 3. Parts, with dimensions

Scale: 1 m = 39.8 world px, floor y 440 (RESEARCH §1). Numbers match the callouts on `render/construction.png`. "Real" marks a sourced size; "est" marks a design estimate.

| # | Part | Job | World px (x × y range) | Metres |
|---|---|---|---|---|
| — | Overall shell | holds WOLF | x 30-206, y 330-440 (176 × 110); flanges and shadow to x 25-211 | 4.42 × 2.76 m; depth 2.90 m (est, not visible in side view) |
| — | Clear interior | WOLF's space | x 36-194, y 343-440 (158 × 97) | 3.97 × 2.44 m; depth 2.60 m |
| 1 | Lock pilaster | carries the lock, keypad, stack light and their wiring | x 194-206 | 0.30 m wide |
| 2 | Fail-secure bolt lock | holds the leaf without power; lock lamp; manual back-up key | 8.5 × 14 at y 400-414 | 0.21 × 0.35 m, 0.65-1.0 m up |
| 3 | **Bolt keeper (the latch)** | receives the bolt; **the part that fails** | 9 × 10 on the leaf edge, y 400.5-410.5 | 0.23 × 0.25 m |
| — | Bolt | stays thrown after the breach | 8.2 × 2.6 | 0.21 × 0.065 m |
| 4 | PIN keypad and card reader, backplate | access control on the secure (outside) side | face 5 × 9.5 at y 386-395.5; backplate 7.5 × 14 | 0.13 × 0.24 m, centre 1.2 m. Real HID RK40: 85 × 122 mm = 3.4 × 4.9 px ([21]), so drawn about 1.5-1.9× |
| 5 | Stack light (R / A / G) | unit state at a distance | 5 px wide, three 3.6 px tiers, top y 312.6 | 0.13 m wide (real about 70 mm: about 1.8× exaggerated); top 3.20 m |
| 6 | Sliding armour leaf | the door | x 113-196, y 343-439 (83 × 96); travel 81 | 2.09 × 2.41 m, 0.08 m thick (est); travel 2.04 m |
| 7 | Top-hung box track, 2 trolleys, end stop | carries the leaf | y 335-343, x 28-206 | 0.20 m deep |
| 8 | Fixed armour panel, kick plate | the other half of the front | x 36-115 | 1.98 m |
| — | Vision panels (fixed / leaf) | let the camera and people see him | 65 × 59 and 67 × 59, y 357-416 | 1.63 / 1.68 × 1.48 m, sill 0.60 m, head 2.09 m. Hot-cell glazing ([47]); rating not sourced |
| 9 | Inflatable door seal | the "containment seal" | 3-4 px strips around the opening | 0.08-0.10 m |
| — | Clear opening | WOLF's way out | x 115-194, y 343-440 (79 × 97) | 1.98 × 2.44 m |
| 10 | Caught-between stripes | warn at the moving edge | 5.5 px wide, 6 px period | 0.14 m |
| 11 | Interior back wall, floor plate | light grey for the camera | — | — |
| 12 | Umbilical reel and umbilical | standby power and data to his shoulders | reel x 132-148; cable 2.4 px; plug 7 × 7 at (140, 388) | cable about 60 mm; plug 0.18 m |
| 13 | Junction box and conduit from a floor vault | feeds the umbilical | 9 × 12 at y 408-420 | 0.23 × 0.30 m |
| 14 | Lock conduit to a floor box | wiring on the secure side | 2.4 px | about 60 mm |
| 15 | Base channel, anchor flanges and bolts, contact shadow | anchor to the slab | base y 436-440; flanges 5 × 3 | base 0.10 m |
| 16 | Fixed camera on an arm | watches the door | housing 12 × 5 at y 319-326 | 0.30 × 0.13 m (est; the research dome is 0.23 × 0.28 m [16]) |
| 17 | Stencils `CU-01`, `KEEP CLEAR` | equipment ID and keep-clear zone | caps 8 px and 6.4 px | 0.20 and 0.16 m |
| 18 | Threshold plate | flush sill | 1.6 px | 0.04 m |

**WOLF's fit** (opaque sprite box at his start (115, 423): x 58.8-174.1, y 376.8-438.4):

| Measure | World px | Metres |
|---|---|---|
| Headroom above the ear tips | 33.8 | 0.85 |
| Clearance, tail tip to the left wall | 22.8 | 0.57 |
| Clearance, nose to the right inner face | 19.9 | 0.50 |

- The AZA crate minimum is 10 cm all round ([9]), so these clearances are generous on purpose: an engineer has to service him in here.
- **Turning:** his body without the tail is about 2.3 m, and a 2.4 m circle fits the 2.60 m clear depth (plan view, estimated).
- **Bar-gap and reach problems** (RESEARCH §3.1, §7) disappear: there are no gaps, only plate and glazing.

**Footprint against the audit's limits.** The unit covers x 25-211, y 312.6-449; the old cage covered x 27-213, y 292-451.

- **Top:** stays 56 px under the top card.
- **Right:** ends 35 px short of the Director's coat (x 245.8).
- **Floor:** the base sits on y 440.
- **Left:** the left 29 px (camera arm, junction box) drop out of view from beat 4, as the old cage's did.
- **Bottom:** everything below y 444 is under the dialogue box from beat 2 on. Only the base and shadow live there.

## 4. How each beat plays

Every beat below was rendered in main's real opening with real taps, camera and timing (`shots/run5`). Only the cell is new, plus the tween easing and spark burst in beat 3 (marked).

| Beat (approved line) | Cell state on screen |
|---|---|
| 0, 1: Director's line, "The Director thinks WOLF is still in standby." | Sealed and locked:<br>• stack light **green**, lock lamp green, reader LED red (locked)<br>• umbilical plugged into WOLF's shoulders, its plug LED green<br>• interior dim grey, WOLF dark behind the glass<br>Card and dialogue clear the unit. `B1-standby.png` |
| 2: "Nobody gives an activation command. WOLF wakes himself. A blue light answers from inside the containment seal." | Main already brightens WOLF. The cell adds three things:<br>• the interior turns blue around him (one opaque vertex-colour fan, no additive layer)<br>• the umbilical is ejected and reeled up<br>• the stack light goes **amber**<br>`extra-B2-wake.png` |
| 3, first 0.2 s: "The latch breaks from the inside." | • main's boom, flash and shake stay<br>• the keeper tears out of the leaf edge and falls to the floor, the bolt stays thrown<br>• stack and lock lamps go **red**<br>• a 16-particle spark burst at the keeper (main's spark preset, smaller particles) replaces the floor dust<br>• the leaf moves only 2 px<br>`B3a-latch-fails.png`, 0.13 s after the tap |
| 3, 0.2-0.65 s: "The gate slides aside." | The leaf runs along its track and parks over the fixed panel. The opening shows the blue-lit interior and the torn seal. |
| 3, then: "WOLF steps out under his own power. The Director freezes at the sound of the seal opening." | Main's staging unchanged: z swap at 0.65 s, 8 px step forward onto the near floor, walk right to x 185. He comes out of the open right half, toward the Director. `B3b-steps-out.png`, 1.0 s after the tap |
| 4, 5: "You were in standby." / lockdown order | Open cell, red stack light, keeper on the floor, bolt still out. A broken unit stays visibly broken. |
| 6: "WOLF turns from the Director and takes the only open route." | He walks left **in front of** the open cell, not back into it, which fixes audit finding 15. The exit direction is still Nathanial's call (problem 20). `extra-B6-route.png` |
| 7: fade into play | Hidden by `_finish_intro`, as today. Leaving the broken cell in the room is Nathanial's decision: it overlaps the purge display and both actors' spawns. |

## 5. What would change in the game if he picks it (not done)

1. **Script.** `containment_cage.gd` becomes a cell script with:
   - `layer` (back / front / leaf);
   - `phase` (0 standby, 1 awake);
   - the same `opening` float (0..1, setter redraws) as the single drive.

   The scene test's `IntroGate.opening == 1.0` checks still hold. The front and back layers read `opening` from the gate, or `main.gd` sets it on all three.
2. **Scene.** Add `IntroCellBack` as a child of `IntroCage` (`z_as_relative = false`, z 1, behind WOLF's z 2), and swap the z values: `IntroCage` 4 → 3, `IntroGate` 3 → 4, so the leaf parks in front of the shell.
   - Today the cage's script draws the frame and the gate. Under this option it would draw the back, shell and leaf layers.
   - The tests reference `IntroGate` only for visibility and `opening`, so I checked: no z assertions.
3. **`main.gd`, three small edits:**
   - set `phase = 1` on the cell nodes at beat 2 (and 0 in `_new_game`);
   - change the beat-3 tween from `TRANS_CUBIC, EASE_OUT` to `TRANS_SINE, EASE_IN_OUT`. The duration stays 0.65 s, so WOLF's z swap, drop and walk keep their timing. A heavy leaf starts slowly; cubic ease-out started at full speed and hid the latch under the flash;
   - point `gate_dust` at the keeper as a spark burst (existing `FxPresets.sparks`, 16 particles, scale 0.3-0.6, 90-170 px/s) instead of a 140 px floor dust band. The large dust puff covered the latch entirely when moved there (tried, rejected).
4. **Shipping form: baked layers.** Ship the cell as a few pre-rendered layer textures (then painted through the REAL-LOOK mask pipeline), not as ~180 code-drawn primitives. Per state, at most 5 textures are visible (back, shell, state overlay, leaf, keeper/bolt).
5. **Sound** (proposal, not built or heard). Replace `boom` with a metal tear-and-clack (keeper shearing), then a short hiss as the seal vents, about 0.3-1.0 s (est, RESEARCH §8), then the leaf rumbling on its track.

## 6. Rendering cost (measured on desktop only)

Godot's own monitors were read in the same capture driver, the same window and the same frames (`_log.json` in each run). Runs are on this Mac in GL Compatibility; no phone has been tested.

| Frame | Main's cage today (draw calls / primitives) | Option B, code-drawn prototype | Option B, baked textures |
|---|---|---|---|
| beat 1 standby | 71 / 2390 | 162 / 4262 | **42 / 2054** |
| beat 2 wake | 67 / 2008 | 197 / 3852 | **38 / 1672** |
| beat 3 latch (0.13 s) | 68 / 2094 | 201 / 3944 | **40 / 1760** |
| beat 3 open | 67 / 2062 | 200 / 3912 | **39 / 1728** |
| beat 6 | 67 / 1918 | 200 / 3768 | **39 / 1584** |

- The code-drawn prototype is fine for designing but **over the 60-per-room budget**. The baked version is **cheaper than today's cage**.
- The baked and vector frames differ by a mean of 0.3/255.
- **Texture memory** at 4 texels per world px is 4.7 MB RGBA uncompressed for all 11 layer-states. At 2 texels per px it is about 1.2 MB, before VRAM compression. REAL-LOOK's room budget is 12 MiB.
- **Persistent glows: 1** (the lit stack-light tier, a 16 px soft disc). Budget ≤4.
- **Live effects:** one 16-particle one-shot burst. No new full-screen layer.
- The blue light is an opaque colour change in the back layer, so it adds no overdraw.

## 7. Wording

**No approved line has to change.** All 123 lines stay as approved. Optional changes, each for Nathanial to approve or ignore:

- "The gate slides aside." → "The door slides aside." The leaf is a solid door; "gate" still works for a heavy sliding leaf.
- Beat 6 already has an approved replacement on file, "WOLF turns from the Director and heads for maintenance." It is not on main yet, and this design does not depend on it.

**Proposed stencil text** (all **proposed, awaiting Nathanial**). It conflicts with REAL-LOOK rule 7, "no text in art", so he has to allow an exception for the cell or drop the marks. Text would be typeset by script and baked in, never painted by an image tool.

| Text | Where | Note |
|---|---|---|
| `CU-01` | fixed panel, upper left, 8 px caps | equipment code, "containment unit 1" (RESEARCH §10C) |
| `KEEP CLEAR` | leaf kick panel, 6.4 px caps | **Below REAL-LOOK's 8 px minimum**; at 8 px it does not fit the leaf. Drop it, or replace it with a blank plate |

No story names, real-world identifiers or franchise text appear anywhere.

## 8. Risks and open decisions

1. **WOLF passes in front of the fixed panel when he steps out.** His single side-view sprite (2.9 m with the tail) is longer than the 1.98 m opening.
   - In reality he would turn and walk out nose-first: the plan view shows the 2.4 m turn fits.
   - On screen, his rear half crosses in front of the parked leaf during the 8 px forward step. That reads as "out in front" but is not literally possible.
   - **The fix is a staging change:** a short walk right to about x 140 before the step. It would be the first change to WOLF's beat-3 timing, so it is Nathanial's call.
2. **Readability on a phone** (`phone-check.png`, stills only):
   - **Reads at 534x300:** standby, the red lamps, the blue interior, and the open door with WOLF coming out.
   - **Does not read as a separate event:** the keeper falling, which is about 4 screen px. The latch moment then reads as "bang, lamps go red, sparks at the lock, door runs".
   - The keypad digits are not readable at any opening zoom; it reads as a keypad-shaped box with a red LED. PIN gameplay needs a close-up or UI, as the research found.
3. **Amber at beat 2** says the cell noticed the wake. If the Director is meant to have no warning, keep the stack green at beat 2 and go straight from green to red at the breach.
4. **WOLF is behind glass in beats 0-2,** so he is less crisp than in today's open-front cage. His legs below 0.6 m are behind the kick plates. The windows are as large as the leaf allows.
5. **Opening timing.** The scratch render used `TRANS_SINE, EASE_IN_OUT` (same 0.65 s). With main's cubic ease-out, the leaf is 60% open before the white flash clears and the latch moment is lost (`shots/run1`, `shots/run2`).
6. **Continuity after the fade:** hidden as today, or left in the room broken. That is Nathanial's decision, and leaving it needs the purge display and the spawns moved.
7. **Unsourced numbers:** the glazing rating, leaf thickness, cell depth and the hiss duration are design estimates (est). The stack-light meanings come from secondary summaries of EN/IEC 60204-1, not the standard itself.
8. **The flat-shaded look is a design render.** The real look comes from the REAL-LOOK paint pipeline after he picks: masks per part, painted light, wear where hands and the leaf go.

## 9. What was and was not checked

**Done:**

- Exported `7c19ee2` into scratch (`game/`) and imported it twice headless, plus once more after adding the baked textures.
- Ran the opening in one normal 1280x720 Godot window per run with `--fixed-fps 60` and real `interact` taps (`HOME` set to the scratch `home-cage`). Every window closed itself with exit 0.
- Captured main unchanged (`shots/main-base`, same driver), the vector prototype (`run5`) and the baked prototype (`run6-baked`), with render monitors.
- Compared the Python and Godot renders of the same spec visually; compared vector and baked numerically.

**Not done:**

- No hands-on play.
- No sound designed or listened to.
- No headless test suite run on a modified game: the scratch export's `main.gd` easing edit and the node swaps were applied by the driver, not as a game change.
- No export, phone or device test.
- No claim about feel or pacing in motion.

## Sources

Numbers in brackets refer to `../research/RESEARCH.md` §11 (for example [4] Spot Dock, [9] AZA Tiger Care Manual, [11] Ohio 901:1-4-01.1, [12] Defra zoo standards, [15] ODNI SCIF tech specs, [21] HID RK40, [29] Allegion fail safe/secure, [31]-[32] lock status LEDs, [34]-[35] guard locking, [37] Spot User Guide, [42]-[44] inflatable seals and BSL-4 doors, [47] hot cells), and [M9], [M17] to REAL-LOOK.md §8. Added here:

- [S1] Optraffic, "What do the colors of the tower light mean?" (summary of IEC 60204-1 indicator colours): https://optraffic.com/blog/meanings-of-tower-light-colors/
- [S2] ABB pilot devices catalogue, p. 148 (EN 60204-1 colour table): https://resources.ipd.com.au/Flipbook/ABB_Pilot_Devices%20_Catalogues/files/basic-html/page148.html
