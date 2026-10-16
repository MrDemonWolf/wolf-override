# Round 9 additions: realism review r3 (adversarial)

2026-10-13. I reviewed round 9 (fix round 2 of the corridor additions, installed in `real-slice/game-add`) against REAL-LOOK.md, including the section 3 AI-tell checklist and section 8 (military). I looked at every after-shot at full size (1280x720 and the 1920x1080 phone frames) as a first-time player would, then at 2x-8x crops, some with stretched contrast and one in greyscale. I re-measured rule 5, the budgets and the headless tests on my own private copies.

**What this review rests on:**
- Rendered stills only, all made with `tools/render/render.sh` (my runs `r3realrev-add-*`, `r3realrev-main-O`), plus `godot --headless`.
- No window opened on the Mac. Nothing was played by hand, so I make **no feel claims** (motion, beacon pulse, timing).
- I edited nothing except this file and my scratch folder `scratchpad/add7-review-real-r3/`:
  - copies `game-add`, `game-add-t` (tests) and `game-main`, each `diff -rq` identical to `real-slice/game-add` and `real-slice/game-main` without `.godot` when made;
  - in `game-add-t` only, I added one `print` to `tests/m0_scene_test.gd` for a probe (original kept as `m0_scene_test.orig.gd`), after the full 14-suite run;
  - captures in `raw/`, crops in `crops/mine/` and `crops/pkg/`, logs in `logs/`, scripts in `tools/`.
- **The package is fresh.** My render.sh captures of round 9 are byte-identical to the package's `raw9/add` frames: A-720, B-720 and A-phone in every frame, O-720 in every frame except o6 (5,730 px at 2 levels, the lamp flicker), and the phone s4/s4b frames differ only by a 1-3 level flicker band at the top-left.

**Verdict: fix-needed.** Both round-2 must-fixes are dealt with: the door is now the only way into the safe-point room, and the luminaire's pool and floor streak sit under the fitting. Every addition still reads as real hardware, nothing hovers, no door blocks the way, and rule 5, the budgets and the provenance hold. I would still not show this to Nathanial as real, for one new reason:

1. **New in round 9:** the relight of the far plate left a hard-edged dark rectangle round the shortened luminaire. It shows at 3x on the 720p frame, in phone shape at 2x, and in the opening's last frame next to PAUSE, and it reads as a dark plate pasted behind the light.

There are also three should-fix items: the new wall section hides 60% of the engineer's control marker at the safe point; the crank check in `m0_scene_test` failed once in 36 runs; and the section's height needs Nathanial's decision.

## Must-fix

### 1. New in round 9: a dark, unrelit rectangle round the luminaire

**What I see.** In every door-end state, and in o7 and o8 of the opening, there is a darker rectangle round the shortened 0.6 m fitting. It covers the fitting, its two rods and the wall between and above them, down to the diffuser. Its left and right edges are straight and vertical (`crops/mine/MUST1-luminaire-unrelit-box-s5-4x.png`: round 8 | round 9 | round 9 with contrast x2.5, cyan = the rectangle; `crops/mine/lum-box-r8-r9-s5-3x.png`; `crops/mine/phone-lum-box-r8-r9-s5-2x.png`; `crops/mine/o8-lum-r8r2-r9-3x.png`).
- At 1x on the laptop frame it is faint. At 3x, and in phone shape at 2x, it is plain. In o8 it sits right beside PAUSE, where the eye goes.

**Where it comes from.** `fix2/far/tools/far9.py` (at ada83fa; round 10's `fix3/far/tools/far10.py` replaced it) holds `SOURCE_BOX = (1209, 186, 1265, 229)` (plate px) at a gain ratio of 1, so that the fitting itself is not relit. But that box is a rectangle, not the fitting's own pixels. So the wall inside it kept its round-8 values, while the wall all round it was relit: brighter to the left, where the pool moved to, and darker to the right, where it came from.

**Measured** (my 720p s5 capture against round 8's, `raw8/add/A-720`):
- The pixels left unchanged form a rectangle at screen x 662-712, y 25-57. Everything round it changed.
- **Left edge,** rows 30-48: 23.8 at x 660, 21.1 at x 661, 17.6 at x 662. That is a 6-level step over 2 px. In linear light the wall outside is about 1.9x brighter than the wall inside.
- **Right edge,** same rows: outside it went from 28-29 down to 23-24, while inside it stayed at 27-56 (the rods and the conduit).
- **Bottom edge:** it falls on the diffuser's own lower edge (row 57), so it hides there. The edges that show are the left and right sides above the diffuser, rows 25-50.

**Why it matters.**
- Checklist item 2 (one light logic): light falls off softly. A pendant fitting with an opal diffuser lights the wall mostly below and beside itself. The pool brightens most right under the fitting and dims smoothly upward ([S18]). It never has a straight-edged dark frame round the source.
- This is a classic composite tell: a rectangular patch with different exposure round an object.
- It is new this round. Rounds 6 and 8 do not have it.

**Fix** (deterministic, no new paint):
- In `far9.py` (`fix2/far/tools/far9.py` at ada83fa), keep ratio 1 only on the fitting's own mask (body, diffuser, end caps, rods, canopies, from `fix1/luminaire/tools/design.py`), not on its bounding box.
- Feather that mask's edge over 2-3 plate px.
- Fade the pool's gain smoothly upward above the diffuser's level (about plate y 229), the same inside and outside the old box. The wall above the fitting then dims evenly, with no frame round the source.

**Check:**
- At 720p s5, rows 28-50: the wall's luma across the old left edge (x 655-668) changes by no more than 1.5 levels per px.
- On the two sides of the vertical conduit (x 707-711 and x 716-720, same rows), the wall reads within 2 levels. Today it is about 27.5 against 24.
- The pool peak and centroid stay within ±5 px of the fitting's centre (x 687.5). Today they are 680-681 and 686.
- Rule 5 still holds in o7 and o8.

## Should-fix (not blocking on their own)

### 2. The new section hides 60% of the engineer's control marker at the safe point

**What I see.** The cyan line under the controlled actor (`m0_actor.gd` `_draw`, a 40 world px line at the feet) is cut by the new section's top in s7 (`crops/mine/marker-safe-point-r8-r9-s7-4x.png`).
- 720p: 130 marker px in round 8, 46 in round 9. Only x 1052-1072 of 1024-1072 is left.
- Phone: 245 px in round 8, 95 in round 9.

**Why it matters.** The marker is UI ("this is who you control"). A player reads a UI line half-sunk into a wall as a layering bug. ADD.md says the safe point is "identical to round 8's: 0 px differ", but its box (y 387-502 at 720p) stops above the marker at y 509-512.

**Fix:** draw the control marker above the near art. For example, give the marker its own CanvasItem, or raise its z-index above the column, camera and stub layer. That way the section can stay where it is. Check: 130 px at 720p in s7, as in round 8.

### 3. The crank check failed once in 36 runs

**What happened.**
- In my first round of 14 suites, all 14 passed.
- In the three extra `m0_scene_test` runs after it, run 2 failed: "cranking shows the crank pose: A (grip) and B (push) frames, 60 and 35, and 2 usual-sprite frames" (the limit is 1; `logs/tests/m0-repeat-2.log`). That run ran while my render.sh jobs were loading the machine.
- 32 more runs, 8 of them in parallel, all passed with 0 usual frames (`logs/probe/`). They ran with a probe line that would have printed where any usual frame fell.

**Likely cause** (from reading the code, not reproduced). `_sample_crank_grip` samples on `physics_frame`. `_update_crank_pose` runs in `_process`. When the machine is loaded, two or three physics steps can run before the first `_process` after `Input.action_press`, so the first samples still show the usual sprite. That is input latency at the start of the hold, not a pop in the middle of cranking.

**Fix (test only):** after `Input.action_press(&"interact")`, `await process_frame` once before sampling, or count usual frames only after the first crank frame has appeared. The headless claim "14 of 14, m0 3 more passes" is true but not robust.

### 4. For Nathanial: the section's height

**What I see.**
- At 0.36 m the cut section reads as a low concrete wall between the corridor's wet floor and the room, and the floor no longer runs on into the room. That fixes what made the door pointless in round 8 (`crops/mine/phone-s7-section-main-r8-r9-1x.png`, `crops/mine/section-s7-r8-r9-1x.png`).
- But it is finished as a built knee wall, with galvanised edge angles on both top arrises and anchor heads. So a careful player can still read it as "step over it".
- Real secure perimeters run from true floor to true ceiling ([S17]). A knee wall only makes sense here as a cutaway convention, or as a spill bund round coolant plant ([S15]), and a bund does not secure a restricted area.

**Options:**
- Keep 0.36 m. It is honest about the engineer's boots, and the cutaway convention mostly carries it.
- Go to the 0.6-0.7 m that review r2 asked for, and accept up to about 5 world px of the boots hidden behind it at the safe point. That is physically right, since they stand behind it, and the actor still reads.
- Show the cut as a cut: a flat, darker top without edge angles or anchors, like an architectural section.

I would not block on this. It is a presentation choice, and ADD.md raises it plainly.

## Round 2's must-fixes, checked

### MUST 1, the way round the door: fixed, at a lower height than asked

- **The wall:** the wet corridor floor now stops at a cast-concrete face with a real footprint contact shadow. At 720p s7, x 1040-1200, the floor about 2 px below the foot reads 5.6-13.0, against 17-26 10 px further out. In the dark corner at x 1240 it reads 9.1 against 11.6.
- **The stray streak:** the streak that reflected a lamp behind the wall is gone, and the inpaint is clean at 3x, with no smear (`crops/mine/stray-inpaint-r8-r9-s7-3x.png`, and `-stretch`).
- **The junction:** where the section meets the near column, the joint is solid, with no see-through notch (`crops/mine/column-foot-junction-r8-r9-s1-5x.png`).
- **Perspective:** I fitted the section's foot edge in s7 (slope 0.381) and the yellow floor line in s5 (slope 0.39). Both reach the screen horizon (y about -3) at x -425 and -415, so they share the far-left vanishing point within 10 px. The top face widens toward the camera, as it should.
- **Paint:** no AI tells at 4x in phone shape (`crops/mine/phone-section-face-4x-stretch.png`). There is no repeated texture or smearing. The control joints and tie holes sit on a regular pitch, and the damp foot is darkest at the floor.

### MUST 2, the luminaire's light: moved, with the new rectangle (must-fix 1)

My own measure of round 9, at 720p s1 and s5:
- The lit diffuser spans x 669-706, centre 687.5.
- The wall pool, rows 62-100, peaks at x 680-681 with its centroid at 686.0-686.1.
- The floor streak, rows 560-680, peaks at x 686.

All are within ±5 px of the fitting's centre. In round 8 they were at 732, 723.5 and 726 (`crops/mine/pool-r8-r9-s5-4x-stretch.png`, `crops/mine/floorstreak-r8-r9-s5-3x.png`).

## Each addition against the real thing

The sources [S1]-[S14] and [M1]-[M17] are those cited in reviews r1 and r2 and in REAL-LOOK.md. New sources are [S15]-[S18], listed at the end.

### (a) Steel blast frame: pass (unchanged since round 8)

- **What it is:** a liner band over the hood (plate joints, M24 anchor heads, a lit top arris), a far-jamb strip, and the band carried over the near column's approach face. The door light sits whole in front of it (`crops/mine/portal-top-s1-4x.png`).
- **Against the real thing:** a four-sided steel frame anchored into the concrete opening ([S10]). Only the head, the far jamb and the approach face can show from this camera.
- **Nit:** the thin conduit from the junction box down the left of the door light (x 852) now runs behind the band's top-left corner. On a real retrofit it would be carried over the liner plate or through it with a bushing. It is 1 px at 1x, so not worth a round on its own (`crops/mine/doorlight-feed-r6-r9-8x.png`).

### (b) RESTRICTED AREA sign: pass, with Nathanial's open choices

- **Text and fixing:** exactly `RESTRICTED AREA`, typeset, legible at 1x and in phone shape, bolted at the corners and following the face's slope.
- **Open choices, unchanged:**
  - printed letters rather than a bridged stencil;
  - over the door rather than beside it;
  - black only.
- **Inherited:** SECTOR 4B is still set level.

### (c) Inner blast door: pass (unchanged)

- **How it moves:** in s4 and s4b, a grey steel leaf behind the roller slides back in depth. Only its 0.36 m striped leading edge, with seals and bolt receivers, faces the camera.
- **Where it parks:** in s5 it stands parked in the pocket mouth at the far jamb, and the opening is clear (`crops/mine/door-s1-s4-s4b-s5-3x.png`).
- **Against the real thing:** gasket-sealed, multi-point-locked blast leaves on rails ([S10], [S11], [S1]-[S4]).
- **Driven by the seal:** the test confirms it is driven only by the seal's `open` value, and blocked only while it is in the opening. All 36 of my m0 runs show 31-33 sliding frames, "in step true, doorway blocked while in the opening true".

### (d) Beacons: pass

- **Each beacon:** a guarded red jelly-jar globe ([S13]). The left one hangs on a strapped conduit drop from the ceiling tray, and the right one under its wall back box fed from the ceiling. The seal lamp stays red when shut.
- **The light:** round 9's stronger light reads as a red pool round the globe and on the pipe below, with the globes still at their real size (`crops/mine/beacon-left-r8-r9-s1-s4b-6x.png`, `beacon-right-...`).
- **In phone shape** at the pulse's bright phase (s4b), both read as alarm lamps at 1x.
- **The left pool:** it stops at the pilaster's edges. That reads as the pilaster face catching the light.
- **Not judged:** the pulse itself.

### (e) SECTOR 4B and DOOR 4B-07: kept, pass

SECTOR 4B is still level, which is inherited.

### (f) Crank pose: pass

- **Grip:** in A, both gloves are on the left of the rim, at about 7:30 and 9:30. In B, the near arm reaches over to about 10:30.
- **No foot slide:** at 720p the boots (rows 483-503) are pixel-identical between A, B and the s3 hold (`crops/mine/boots-A-B-8x.png`). Only a few trouser pixels above them differ, by at most 19 levels.
- **Grip, headless:** in every m0 run, every crank frame has both gloves at most 0.80 world px off the rim line.
- **Same character:** it is the same person, with the same face, hair, jacket colour and trousers (`crops/mine/crank-s1-A-B-s3-4x.png`). The crank torso is narrower and side-on against the 3/4 walking sprite. That is accepted until the re-cut from the approved walk frames, as ADD.md plans.

### (g) Relief port and jet: pass, faint enough

- **Where it comes from:** it starts at the open end of the brass relief valve's clamped tailpipe, about 0.4 m above the floor ([S8]: 6 in to 2 ft). It falls straight down and fans a little at the floor.
- **Not a disc:** it is directional and normally blended (`crops/mine/relief-s1-s3-A-B-6x.png`).
- **Brightness** at alpha 0.2, crank A: mean 74.9, p90 115.4 and max 139.3 over a background of 41.4 (504 px). It is still brighter than the jacket (p90 about 68). Whether that is "faint" enough is for Nathanial, as before.

### (h) Strap on the lamp conduit: pass

It is unchanged and, as expected, invisible at 1x.

## AI-tell checklist (section 3), round-9 changes

| # | Check | Result |
|---|---|---|
| 1 | Vanishing lines | Pass. The section's foot and the yellow floor line meet the horizon within 10 px of each other (x -425 and -415), and the top face widens toward the camera. |
| 2 | One light logic | **Fail: the unrelit rectangle round the luminaire (must-fix 1).** The pool and the floor streak are now under the fitting, the section's contact shadow is darkest at its foot, and the beacon pools sit under their globes. |
| 3 | Every part has a job | Pass: galvanised edge angles armour the arrises, as on real industrial walls and columns ([S16]); anchors fix them; tie holes and control joints come from casting; and the damp foot sits where the wet floor wicks. |
| 4 | Nothing floats | Pass. The section stands on the floor with a footprint shadow. Nothing new hangs free. |
| 5 | Scale | Pass: section 0.36 m high and 0.66 m thick, angles 50-65 mm, globe 0.14 m. |
| 6 | Doors | Pass. The door is now the only way in, the roller and leaf are clear when open, and the hole is transparent. Nathanial's height choice is item 4. |
| 7 | No painted text | Pass. No new text, and the Codex paint has no lettering. |
| 8 | Detail and values | Pass. In greyscale (`crops/mine/s7-grey-1x.png`) the section sits at or below the column (face 22.3, top 26.8, as measured in the package, against the column's 24.1-33.6). Actors and interactables carry the contrast. |
| 9 | Wear logic | Pass. The damp is at the wall foot by the wet floor, and the plates are calm. |
| 10 | No repeats | Pass. |
| 11 | Rule 5 | Pass (below). |

There are no franchise references and no generic sci-fi.

## Re-measured on my own copies

### Rule 5: the opening

`tools/opening_r3.py` is independent of the package's script. It compares my round-9 capture `raw/add/O-720` against:
- my fresh main capture `raw/main/O-720`;
- two older main runs (`raw8/main/O-720`, `shots/raw5/main/O-720`);
- round 8 (`raw8/add/O-720`).

A change of 1-3 levels counts as flicker. The beacon zones are ±45 x -55..+45 world px round every red cluster that changed, in either frame. Results are in `opening-r3-720.json`, with pink-over-main maps in `opening-r3-720/`.

**Left of world x 540, outside the beacon zones:**
- **Against main:** only main's dust. Every frame has 7-15 blobs of at most 39 px, all brighter in main, with no non-dust blob.
- **Against round 8:** 0 px in o0-o7.
- **o8:** differs from round 8's first run only by the old bay lamp's flicker, at x 670-973, y 0-105, up to 22 levels. Round 8's second run (`O-720-r2`) and round 9's second run are both byte-identical to my run there (0 px).

**WOLF's cage** (world x 27-205, y 292-451):
- Against main, 0-111 px per frame differ, in at most 2 blobs of at most 14 px, all brighter in main. That is main's dust.
- Against round 8: 0 px.
- The cage and the gate are identical.

**Right of world x 540:** o4-o6 are 0 px. o7 and o8 differ only at the door end, which is allowed.

**Phone shape** (`raw/{add,main}/O-phone`, the 1920x1080 game image; `opening-r3-phone.json`, `opening-r3-phone/`):
- My round-9 run is byte-identical to the package's `raw9/add/O-phone` in all nine frames.
- **Against my main run and the package's main run,** left of world x 540 and outside the beacon zones, everything is main's dust: 7-16 blobs per frame, all brighter in main. The one blob over 44 px is in o5 (54x36 px at x 773, y 783), and it is two soft motes of main's merged into one (`crops/mine/o5-phone-blob-main-r9-4x.png`). Review r2 found the same blob.
- **Against round 8:** 0 px outside the beacon zones in every frame.
- **The cage box:** at most 2 blobs of at most 20 px per frame, all brighter in main. Against round 8, 0 px.

### Budgets

These are my render.sh perf runs on my copy (`raw/add/A-720-perf`, `raw/add/B-720-perf`; 1280x720, 300 frames held per state, round 8's driver). Main, round 6 and round 8 come from the package's runs with the same driver (`raw8/*/*-720-perf`). Draw calls, memory and item counts are deterministic in the container; frame times there mean nothing. Summary in `perf-r3.json`.

| State | Draw calls p50 (max): main -> r6 -> r8 -> **r9** | Additive items | Texture MB | Full-screen translucent world layers | Emitters on |
|---|---|---|---|---|---|
| s1 at rest | 72 -> 54 -> 47 -> **47 (47)** | 8 -> 7 -> 7 -> **7** | 71.97 -> 73.87 -> 74.70 -> **74.70** | 2 | 0 |
| s2 relay beat | 77 -> 60 -> 54 -> **54** | **7** | **74.70** | 2 | 0 |
| s3 cranking | 73 -> 55 -> 48 -> **48** | 9 -> 7 -> 7 -> **7** | **74.70** | 2 | 1 (the jet) |
| s4 roller half up | 73 -> 56 -> 50 -> **50** | **7** | **74.70** | 2 | 0 |
| s4b leaf sliding | 73 -> 56 -> 50 -> **50** | **7** | **74.70** | 2 | 0 |
| s5 open | 71 -> 54 -> 47 -> **47** | **7** | **74.70** | 2 | 0 |
| s6 walking through | 71 -> 54 -> 47 -> **47** | **7** | **74.70** | 2 | 0 |
| s7 safe point | 71 (75) -> 54 (58) -> 46 (50) -> **46 (50)** | **7** | **74.70** | 2 | 0 |

- **Draw calls:** 47 at s1, against round 6's 54. Pass.
- **Additive items:** 7, the same as round 6. Pass.
- **Texture memory:** +0.83 MB against round 6, inside the 2 MB limit. Pass.
- **Matches the package:** my numbers equal the package's `raw9/add` perf runs row for row (overdraw estimate 3.38-3.47).
- **Inherited:** overdraw and resident textures are still over REAL-LOOK's 2.0 and 45 MB targets.

### Headless tests

Run on my test copy (`game-add-t`) after two headless imports. The first import shows the usual fresh-copy font errors, and the second is clean.
- **Full run:** 14 of 14 suites pass (`logs/tests/`), with no `ERROR:` lines and no leak warnings.
- **`m0_scene_test`** (36 runs in all): 1 from the full run, 3 more in a row, then 32 with the probe line (24 one after another, 8 in parallel).
  - 35 runs pass. One fails, `m0-repeat-2`, on the crank check's usual-frame count (should-fix 3).
  - Every run gives a worst grip of 0.80 world px off the rim line and 0.81 from the grip point.
  - Every run gives 31-33 leaf frames "in step true, doorway blocked while in the opening true".

### Provenance

- **C2PA:** both round-9 Codex outputs carry their `caBX` C2PA chunk (I parsed the PNG chunks): `cut9-painted.png` 21,881 bytes and `cut9b-painted.png` 23,654 bytes.
- **Hashes:** their sha256 values match `add7/provenance.txt` (f764301c..., ec14d41e...). `cut9b-painted.png` is byte-identical (cmp) to `~/.codex/generated_images/01a13619-.../exec-f90c5973-....png`.
- **Archive:** all three round-9 sessions, including the empty run, are in `~/.codex/archived_sessions`, and 0 are live.
- **Installed files:** `corridor-seal-atlas.png` (271c2da3), `corridor-far.png` (c334eb64) and `corridor-beacons.png` (72efa04f) match the md5 values in provenance.
- **Asset register:** `manifest.json` carries the round-9 notes and the 256x156 correction.

## Inherited, for Nathanial (not this round's defects)

- SECTOR 4B is set level.
- COOLANT FAULT stays up after the relay is dealt with (fixed on main by PR #63).
- When open, the roller's striped bottom bar shows only under the right end of the hood.
- Three yellows when open and three reds when shut.
- Overdraw (about 3.4) and resident textures (74.7 MB) are over REAL-LOOK's 2.0 and 45 MB.
- The Records and junction beacons are still drawn in code.
- WOLF stays at x 490 while saying "We made it" (ADD.md's options (a) and (b)).
- The RESTRICTED AREA plate choices.
- The crank re-cut from the approved walk frames.

## Sources

New in this review:
- [S15] UK HSE, *Secondary containment* (bunds: impermeable floor and walls round tanks, sized at 110% of the largest tank; walls ideally no higher than 1.5 m, and low walls are common; search summary): https://www.hse.gov.uk/Comah/sragtech/techmeascontain.htm. Also Designing Buildings, *Bund*: https://designingbuildings.co.uk/wiki/Bund
- [S16] Edge protection angles for concrete wall and column arrises, hot-dip galvanised, with U-shaped anchors, 50x50 and 75x75 mm (search summaries): PohlCon JKW https://pohlcon.com/en/products/fastening/edge-protection-angles/edge-protection-angles-jkw and Ancon corner guards https://ancon.co.uk/products/channel-bolt-fixings/corner-guards
- [S17] ICD/ICS 705 Technical Specifications for SCIF construction (perimeter walls true floor to true ceiling, permanently and solidly attached; search summary): https://www.dni.gov/files/NCSC/documents/Regulations/Technical-Specifications-SCIF-Construction.pdf
- [S18] US patent 4564888, *Wall-wash lighting fixture* (the scallop of light is most noticeable directly beneath the fixture and falls off with distance; search summary): https://patents.google.com/patent/US4564888A/en
