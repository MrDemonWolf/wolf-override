# Doors r1, fix round 3: independent realism review (reviewer "real", round 4)

**Verdict: fix-needed.** I would not show this to Nathanial as real yet, but only one blocking item is left.

Fix round 3 closed every must-fix from review r3, and I measured each one myself:
- The violet fringe is gone: 0 pixels in all four door atlases.
- The junction header shows 30 near-white pixels, the same as main (round 2 had 315).
- The open leaves are lit at the head.
- The ending holds the engineer at the door (x 849 in j12 and j13).

The doors stand across the route, open the way real ones do, and read as one facility with the corridor door end.

**What still makes the slice look fake:** every swing leaf turns into a **black, featureless card** for part of its swing. The package shows it in **r10**, the junction entry closing behind the player: the leaf measures 0.0020 linear, 0.22x the wall beside it. That is darker than round 2 (0.49x) and darker than the same leaf once it latches (0.0063). This is the same "black flat card" tell that R3-2 was meant to remove. There are two causes in the code, both found and checked:
1. `SwingLeaf` picks the visible face with a parallel test, not with the game's perspective camera, so for 17 to 34 degrees of every swing it draws the face the camera cannot see.
2. The new single exposure crushes the leaf's ambient and fill light along with the door light.

Scratch only. My only edits are this file and `doors-r1/review-real-r4/`. Nothing was played by hand, so this review makes no feel claims.

Evidence sheet: `review-real-r4/evidence-sheet.png`, panels A to D. Crops are in `review-real-r4/c/`, scripts in `review-real-r4/tools/`, and logs in `review-real-r4/logs/` and `perf/`.

## What I checked, and how

- **AI-tell checklist.** I ran every item of REAL-LOOK section 3 on these frames:
  - all 91 frames in `fix-r3/captures/after-1280/` at full size;
  - `after-phone/` (1920x1080);
  - the 45 package crops;
  - my own 3x-8x crops, some contrast-stretched (`c/`), plus a sheet of the swing states (`c/swing-sheet.png`) and a sheet of the ending (`c/ending-sheet.png`).
- **Atlases.** I checked all four door atlases on a magenta/green checker (`c/atlas-*-checker.png`).
- **Reference.** I compared against the approved corridor door end (`docs/research-2026-10/sources/corridor-door-end-2026-10-12/frames/` s1 and s5).
- **Leaf light.** `tools/leafswing.py` copies `SwingLeaf.shade()` and `append_mesh()` with each door's own constants and walks the swing from 0 to 90 degrees. `tools/leaf_vs_reveal.py` is review r3's tool, with the Records entry's columns corrected for these frames.
- **Real hardware.** I checked against the local copies of the standards listed under Sources.

## Must fix (blocking)

### M1. Every swing leaf goes black for part of its swing (one light logic, checklist 2 and 8)

Evidence: panel A (`c/r10-leaf-6x.png`, round 2 `c/r10-leaf-r2-6x.png`), `c/swing-sheet.png`, and `leafswing.txt`.

**On screen (render.sh, 1280x720, linear luminance):**

| Junction entry leaf | Leaf face | Wall beside | Leaf / wall |
|---|---|---|---|
| r10 closing, round 3 | **0.0020** (about sRGB 7) | 0.0092 | **0.22** |
| r10 closing, round 2 | 0.0045 | 0.0092 | 0.49 |
| r11 shut, round 3 | 0.0063 | | |
| r09 open, round 3, mid-face | about 0.021 | | |

In r10 the leaf has no lever, closer or edge. It is the blackest shape in the junction's first beat, while the door closes behind the player.

**Through the swing (`leafswing.txt`, the shipped constants, mid-face):**
- **All three swing leaves** fall to **0.0015-0.0026** between 10 and 20 degrees.
- That is below their shut values (0.0055-0.0086) and far below open (0.013-0.021).
- So every leaf goes from lit to black to dark grey as it closes, and the reverse as it opens.
- The Records leaves' dip is not in the package: r02 is pixel-identical to r03 inside the door, so the Records entry swing was never captured.

**Cause 1: the wrong face is drawn.**
- `swing_leaf.gd append_mesh()` decides `room_shows = n_room.z < 0.0`, which is a view straight along +d.
- `project_in()` is a pinhole camera at x = vpx / 40 m, d = −38 m. These doors are 9.8-11.9 m off its axis, so the view ray is turned about 14-17 degrees.
- With the true ray, the room face stays visible up to **31 degrees** (Records) and **34 degrees** (junction entry). The code switches at 17-18 degrees.
- For **17-31 / 18-34 degrees**, it draws the outside face, which the camera cannot see, lit as a back face.

**Cause 2: the ambient light is crushed.**
- `AMBIENT` and the floor-bounce light are multiplied by the same exposure that was fitted to make the strong 0.5 m door light match the reveal: 0.082, 0.225 and 0.147.
- So any face the door light does not reach gets only 8-22% of its fill.
- That covers the room face at 5-17 degrees and the lower body of every open leaf.

**The same cause leaves R3-2 only met at the head.** Open leaf near the hinge against the reveal it hangs on, in the same rows (`leaf_vs_reveal.txt`):

| Door | Rows 350-380 | 400-440 | 460-490 |
|---|---|---|---|
| Records exit (r07) | 0.68 | 0.43 | 0.26 |
| Records entry (r01) | 0.54 | 0.29 | **0.11** |
| Junction entry (r09) | 0.81 | 0.44 | 0.26 |

The leaf and the reveal are a few centimetres apart, face the same way and share the same lights and floor bounce. Yet low down the reveal reads 4-9x brighter: panel B, the bright jamb strip beside a dark door. The fix round's `leafcheck.py` measures only the head box and only the fully open frames, so it could not catch this.

**Fix:**
1. In `append_mesh()`, choose the face with the real camera: `n_room.dot(face_centre - camera) < 0`, with `camera = Vector3(vpx / PX_PER_M, 0, -D0)`. Do the same for the arm's face choice.
2. Give the leaf its own ambient and fill, not scaled by the door light's fit. Either fit the exposure on ambient plus fill first (so a face turned away from the door light reads like the wall's shaded concrete) and then fit the door light's intensity, or carry a separate ambient exposure. Targets:
   - the visible face is **≥ 0.45x the wall beside it at every angle**, and never below its own shut value;
   - the open leaf near the hinge is **0.6-1.0x the reveal in rows 350-490**, not only at the head.
3. Capture every swing leaf at open = 0.1, 0.2, 0.3 and 0.5 (including the Records entry, which has no mid-swing frame now), and extend `leafcheck.py` to those frames and to the rows above.

## Should fix

- **S1. Junction entry: the painted steam is cut by a ruler at the cross-wall's far edge** (panel C, `c/phone-r09-left.png`, `c/r09-steam-4x.png` against `c/r09-steam-main-4x.png`).
  - It is the mid plate's static steam cloud by the header elbow. It ends in a dead-straight vertical edge where the wall meets the back wall:
    - 1280: x 223 in r09-r11, x 160 in j01-j04, y 140-240;
    - phone r09: x 335, y 200-330.
  - It is at the top left of the junction, where the eye lands first.
  - Steam piling against a wall laps onto its face; it does not stop on a line. REAL-LOOK section 2 also lists frozen steam as a "do not".
  - **Fix:** paint the cloud out within about 1 m of the corner, or feather it onto the wall face over 6-10 px with falloff. Re-capture r09-r11 and j01-j04 at both sizes.
- **S2. A door-added `sentry_test` check is racy, and DOORS.md blames the flake on main alone.**
  - In my parallel run (4 suites at once, beside two render.sh containers), `sentry_test` failed **"in the doorway he waits looking back at the engineer, his head and shoulders in view"** (`logs/sentry_test.log`). Three sequential reruns passed (`logs/sentry-rerun/`).
  - This check exists only in the doors patch; main has 0 copies of it.
  - `main.gd` sets `wolf.body_sprite.flip_h` in the per-frame update, but the test reads it after one `physics_frame`. Under load, physics can step twice before a process frame.
  - **Fix:**
    1. `_wait_until(func() -> bool: return wolf.body_sprite.flip_h, 30)` before the check.
    2. Correct DOORS.md's sentence that the load flake is "main's own timing flake, not a door change". One of the three flaky checks seen this round is the doors' own.
- **S3. The asset register's top-level `status` is stale.**
  - The per-asset entries are right: all 62 paths exist, and the 12 deleted files are gone from the list.
  - But `manifest.json` `status` still says the register holds "the pressure bulkheads in door design A (the junction's sealed, breaking, blown and front-lip images, with their full-size approved originals under apps/game/art-source/doors/)". This patch deletes all of those.
  - It does not mention the Records doors atlas, the junction blast door atlas or the junction entry atlas.
  - **Fix:** rewrite that clause to list the four door atlases, and drop the bulkheads.

## Could fix

- **C1. Copied reflections under the exit.** The floor wedge at the junction exit is the deck copied from 1.5 m along. It carries orange reflection streaks (j08-j13, about x 1040-1060, y 470-500; panel D) with no orange source above them, under a lamp that is green from j10 on (checklist 2). Clone from a stretch of deck without warm reflections, or damp the warm hue in the wedge.
- **C2. The blast leaf has no flight.** The blast door leaf shows broken for `DOOR_BREAK_SECONDS` (0.15 s), then appears lying 3 m away in the lane. It never fades, but it has no in-flight pose. Two or three frames of the leaf in flight, or a smeared leaf during the flash, would sell the throw.
- **C3. The exit's wall-pack shadow reads as a sloped hood.** The long diagonal shadow from the wall pack and bolt box to the head (j08-j14) is physically right for the corner fitting's grazing light. But its hard edge makes it read as a sloped hood at 1x. Widen the penumbra with distance from the caster.
- **C4. The leaf-face wear is too even.**
  - The cart scrapes on the leaf faces are short dashes scattered evenly over the face (`c/jentry-leaf-atlas-4x.png`, `c/records-leaf-atlas-3x.png`). Real scuffs cluster in a band at cart-rail height on the latch side.
  - The kick plate reads as mottled granite. A protection plate is satin metal with fine horizontal scratches (ANSI/BHMA A156.6).
  - Most of this is lost at play size.
- **C5. Still open from r3:**
  - roller scuffs on the exit leaf;
  - the blast column's white blotches;
  - smooth hairline cracks;
  - darker blast puffs.

## What passes

- **R3-1 (violet fringe): fixed.**
  - `tools/fringe.py` finds 0 strict and 0 loose magenta pixels in all four door atlases and in the corridor atlas, including at alpha edges.
  - On screen in j08-j10 I see none.
- **R3-3 (junction header): fixed.** Near-white pixels at the header box (x 150-300, y 90-230):

| Frame | Main | Round 2 | Round 3 |
|---|---|---|---|
| r09, r10, r11, j04 | 30 | 314-315 | **30** |
| j01 | 65 | 297 | **65** |

  The room's own elbow is back.
- **Human r3 must-fix (the ending): fixed.**
  - My render shows engineer x **849.2 / 849.2** in j12 and j13, with WOLF at 934. That matches the fix round's capture.
  - `door_route_test` passes in my copy.
  - The fix round's no-fix log fails at 746.6.
- **The other r3 should-fix items:**
  - **S1 threshold:** the plate is now the deck's dark value (0.021 linear, it was 0.0625), not a pale plank.
  - **S2 collars:** the pipes visibly run into rings on the face (phone `c/phone-j08-pipes-4x.png`). The 0.48x ellipse is correct. The wall's face normal is about 58 degrees from the view ray at that corner, and cos 58° = 0.53. Review r3's 0.3x ignored the camera's off-axis ray.
  - **S3 thrown leaf:** it is bowed, has a crushed corner, shows its latch bolts standing off the far edge, and lies clear of the stub.
  - **S4 blast damage:** the torn keeper pockets and torn hinge leaves now read at 5x without stretching. The DOOR DOWN plate over the head is still Nathanial's call.
  - **S5 provenance:** fixed (see Process).
- **Human r3 should-fix items:**
  - The screen-edge battens read 0 near-white pixels in r01, r03, r04 and r07 (round 2: 5 / 5 / 40 / 40).
  - The exit floor wedge is wet deck, not a flat grey patch (but see C1).
- **Doors make sense (rule 2):**
  - All five doors stand across the route. The actors walk through each one and pass behind its near column: r08 and j14-walk-out-00 to 09, with the doorway empty before j15.
  - The swing leaves hang on three butt hinges at the far jamb (SDI 129) and have a surface closer with a regular arm on the pull side. ICD 705 TS ch. 3 requires "an automatic, non-hold door-closer" on perimeter SCIF doors.
  - The Records exit's push face is blank, which is a normal exit-only trim.
  - The blast door has full-surface hinges. UFGS 08 39 54 says "Blast door hinges are normally full surface".
  - The blast leaf is thrown clear of the frame. SDI 133 / ASTM F2927 Category IV: "The door can become separated from the frame and cause a flying debris hazard".
  - The blast damage sits where Liu et al. found it: cracking at the wall corners, failure "along the joints in the concrete at the edges of the steel plates".
  - The sliding exit leaf runs into a real pocket, with its striped edge left in the mouth, on bottom rollers (UFGS 08 13 73 2.9.6-2.9.7).
  - No leaf fades.
- **Checklist items:**
  - **One projection (1):** the cross-wall joints, heads and feet converge consistently with each room's camera. I checked the Records exit's wall slopes against its design and the head against the base.
  - **No text (7):** there are no painted letters in any atlas. EXIT, DOOR DOWN and the station names are the game's own name plates.
  - **Openings (6):** every opening is alpha 0, and every space beyond is that room's own passage.
  - **Scale (5):** the 3'0" x 7'0" leaves read 2.14-2.19 m against the 1.75 m engineer.
  - **Nothing floats (4):** every new item stands on the deck or hangs on visible hardware: the lamps on conduit, the EXIT sign on its flag bracket, the camera on its arm, the container, the rubble and the thrown leaf.
  - **No repeats (10):** across rooms, the door type repeats as one facility should, but the wear patterns differ.

## Process

- **Tests, on a private copy:**
  - `git fetch`: origin/main is **8cb4301**. I ran `git archive origin/main apps/game scripts`, then `git apply --binary shots/doors-integration.patch`.
  - The patch applied cleanly, and `diff -rq` against `game-doors/apps/game` is empty.
  - The first import logged only the 16 known font errors; the second logged none.
  - **17 of 18 suites passed** in the parallel run, under heavy load (`run-suites.out`). `sentry_test` failed once (S2), then **passed 3 of 3** run alone.
  - Isolated HOMEs are under `review-real-r4/homes/`.
  - No Godot window was opened.
- **Budget** (render.sh 1280x720, the fix round's driver `--only=junction --perf=1`, main 8cb4301 and my copy, both run by me; `perf/junction-*/_run.json`):

| State | Draw calls p50, main → after | Additive, main → after | Texture MB, main → after |
|---|---|---|---|
| j01 sealed | 94 → 86 | 10 → 9 | 73.37 → 75.25 |
| j04 blown | 98 → 88 | 10 → 9 | 73.37 → 75.25 |
| j06 lane | 105 → 95 | 10 → 9 | 73.37 → 75.25 |
| j08 exit bolt | 98 → 83 | 9 → 8 | 73.37 → 75.25 |
| j11 exit open | 103 → 83 | 9 → 8 | 78.05 → 75.25 |

  - Draw calls and additive items are below main in every state.
  - Texture memory is **+1.88 MB**, inside the ~4 MB budget, and matches `perf.json`.
  - My frames match the fix round's within 0.3-3% of pixels (> 8/255). The exceptions are the blast frame (shake) and the mid-slide frame (timing).
  - No new full-screen layer.
- **C2PA and provenance** (`tools/c2pa_check.py`, glob widened to every `out/` folder; `c2pa_check.txt`):
  - All **33** raw outputs carry a `caBX` manifest with `c2pa.claim` and `c2pa.signature` (OpenAI), and all 33 are in `provenance.txt`. That includes `junction-paint-blown/superseded-r1/out/`, which review r3's glob missed, and `r2-junction-exit/out/attempt-1/`.
  - Each is byte-identical to its original in `~/.codex/generated_images/`.
  - All **24** sessions named in provenance are in `~/.codex/archived_sessions/`, and none is live (`sessions-status.txt`).
  - No image session for this work appeared after review r3. The one newer `generated_images` folder belongs to another project (cwd `cli-ai-conversations`).
  - Round 3's "no Codex session" entry is present.
- **Git:** the repository status is clean; I only ran `git fetch`.

## Sources

- UFGS 08 39 54, *Blast Resistant Doors*, 2.2.1: "Blast door hinges are normally full surface". Local copy: `doors-r1/hatch/research/ufgs-083954/`. https://www.wbdg.org/FFC/DOD/UFGS/UFGS%2008%2039%2054.pdf
- UFGS 08 13 73, *Sliding Metal Doors*, 2.9.6-2.9.7 (top guide rollers, bottom rollers). Local copy: `doors-r1/hatch/research/ufgs-081373/`. https://www.wbdg.org/FFC/DOD/UFGS/UFGS%2008%2013%2073.pdf
- SDI 133 (ASTM F2927 response categories), Category IV. Local copy: `doors-r1/junction/research/dl/sdi-133.txt`. https://steeldoor.org/wp-content/uploads/2020/02/SDI_133.pdf
- Liu, Oesterle, Conway and Covino, NDIA 2018 (blast door field test failure modes). Local copy: `doors-r1/junction/research/dl/liu-ndia-2018.txt`. https://ndia.dtic.mil/wp-content/uploads/2018/intexpsafety/Liu2Paper.pdf
- SDI 129 (hinges for 1-3/4 in doors). Local copy: `doors-r1/records/research/sdi129.txt`.
- ICD/ICS 705 Technical Specifications, ch. 3 (automatic, non-hold door closer). Local copy: `doors-r1/records/research/ts-scif.txt`. https://www.dni.gov/files/NCSC/documents/Regulations/Technical-Specifications-SCIF-Construction.pdf
- ANSI/BHMA A156.6, *Architectural Door Trim* (protection and kick plates).
- Photometry: illuminance on a surface falls with the cosine of incidence and the inverse square of distance (Lambert's cosine law). The ambient and floor bounce on two adjacent surfaces with the same normal are the same, which is the basis of M1's leaf-against-reveal targets.
- REAL-LOOK.md sections 2, 3, 5 and 8; the corridor door end record (DESIGN.md v6, frames); reviews r3 (real and human); DOORS.md (fix round 3).
