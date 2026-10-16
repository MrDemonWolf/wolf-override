# Doors r1, fix round 4: independent realism review (reviewer "real", round 5)

**Verdict: fix-needed.** The doors themselves now read as real; I found nothing in the art that blocks. What blocks is integration: the package no longer applies to main.

**What fix round 4 closed:**
- **Every review r4 item is closed,** and I re-measured them myself. No swing leaf goes black at any captured angle. The junction entry steam now laps onto the wall instead of stopping on a ruler line. The sentry check holds. The asset register is current.
- **The doors stand across the route.** Each one opens the way the real hardware does, and the leaf goes somewhere: it swings on butt hinges, slides into a pocket, or is torn off its full-surface hinges and lands in the lane.
- **They read as one facility** with the approved corridor door end.

**One must-fix (blocking):**
- `origin/main` moved to **fdd5f7b** (PR #68, merged 09:10 today, three minutes before this package was written).
- `doors-integration.patch` no longer applies.
- Main's new knockdown code and tests depend on the bulkhead door that this patch deletes.

**One should-fix:** the package's evidence for the thrown leaf. Its "20 %" frame is not the 20 % pose.

Scratch only. My only edits are this file and `doors-r1/review-real-r5/`. Nothing was played by hand, so this review makes no feel claims.

**Where my evidence is:**
- the evidence sheet is `review-real-r5/evidence-sheet.png`;
- crops are in `review-real-r5/c/`, tools in `review-real-r5/tools/`, logs in `review-real-r5/logs/`;
- perf is in `review-real-r5/perf/`, and my render.sh captures are in `review-real-r5/captures/`.

## What I checked, and how

- **The AI-tell checklist.** I ran all eleven items of REAL-LOOK section 3 on:
  - every after-shot in `fix-r4/captures/a5-1280/` (66 states, with and without UI) and `a5-phone/` (2400x1080 view, saved 1920x1080), at full size;
  - the 66 package crops;
  - my own 2-8x crops of every door state (`c/`), a greyscale pass on r07 and j11 (`c/grey-r07-j11.png`), and checker views of the junction entry, junction exit and Records atlases (`c/*-checker.png`).
- **Against the approved design language.** I compared each door with the corridor door end (DESIGN.md v6): a cross-wall turned across the walkway, a near column, a stub cutaway, door-only layers with alpha-0 openings, a status lamp, light painted in.
- **Against the real hardware.** I checked each door against the standards' local copies (see Sources).
- **My own render.sh run** of the junction, on main 0c5d1ae and on my patched copy, with perf, for the budget and the early flight.

## Must fix (blocking)

### M1. Rebase onto main fdd5f7b, and re-derive what main now builds on the old bulkhead

**Evidence** (`merge-probe/`, `logs/`):
- `git apply --check` fails on `junction_room.gd`, `main.gd` and `junction_test.gd` against `origin/main` fdd5f7b.
- A 3-way merge (base 0c5d1ae, ours fdd5f7b, theirs the doors patch) leaves **8 conflict hunks**: 5 in `junction_room.gd`, 1 in `main.gd`, 2 in `junction_test.gd`.

**These are not text-only conflicts.** PR #68 adds code that is built on the bulkhead door this patch deletes:
- **The knockdown limit.** `main.gd` (line 3537 after the merge) ends a forward slump short of `JunctionRoom.DOOR_FOOT_X`, "so no part of the lying body is hidden" under the bulkhead's front lip. `DOOR_FOOT_X`, `DOOR_LIP_FOOT_COLUMN`, `DOOR_REGION`, `DOOR_SCALE` and `DOOR_LIP_PROP` exist only on main's side. The doors side deletes them, so taking it leaves `main.gd` and the new `junction_test.gd` checks (lines 792-809 and 889) pointing at constants that no longer exist.
- **The same hazard exists with the new door.** The doors patch draws the near column, the stub and the lying leaf over the actors (`DOOR_FRONT_Z` 2). A knocked-down engineer by the blast door could lie partly under the new stub, which is exactly what PR #68 fixed for the old lip.
- **The bolt panel redraw.** PR #68 adds `PanelFront`, which redraws the exit bolt panel and its lamp over the sentry at the far end of its patrol. The doors patch replaced that exit's art, layers and lamp (and deletes `HatchDoorway` in the same hunk). Nobody has seen these two drawn together.

**Fix:**
1. Rebase the door work onto fdd5f7b. Keep `PanelFront`, drop `HatchDoorway`, and keep main's collapse frames.
2. Derive the knockdown's foot limit from the new door. Use the footprint of the stub or the near column on the floor (`JunctionDoorLayout`), in the rows a lying body fills, as `DOOR_FOOT_X` did for the lip.
3. Port main's front-lip checks in `junction_test` to that footprint.
4. Re-run every suite on the rebased copy.
5. Re-capture with render.sh:
   - j01-j15;
   - a knockdown at the valve facing the blast door, sealed and blown, with Reduced Motion on and off;
   - the sentry at the far end of its patrol behind the exit bolt panel, in j06-j08.
6. Re-measure perf, and regenerate both patches against fdd5f7b.

## Should fix

### S1. The package's flight evidence is wrong at 20 %, and `flight-sequence.png` matches no kept capture

Evidence: panel A of the evidence sheet.

**What the frames show:**
- `pairs/j03-flight-20.png` and `a5-1280/j03-flight-20-clean.png` show the leaf almost flat beside its landing spot (about 25 degrees from horizontal). That is t ≈ 0.79 by the room's own formula (rotation 1.5 · t^1.2).
- The phone frame shows t ≈ 0.53.
- The 45, 70 and 90 frames do match their t.

**Cause (verified):**
- The driver sets `Engine.time_scale = 0` and calls `_set_door_flight(0.2)` in the same frame. That frame's delta was taken before time froze, so the flight tween still steps once afterwards and overwrites the pose.
- My copy of the driver (`review-real-r5/driver/doors_capture.gd`) waits one frame first and logs "flight frozen at t=0.942". That is how far one slow software frame carried the tween.

**The sheet:** `checks/round-4/flight-sequence.png` (09:11) shows a 20 % pose that matches no kept frame. Its run was deleted, so it cannot be reproduced from the package.

**What the true early flight looks like** (my frames `captures/doors-j/j03-flight-10/20/30/31/45`, panels A2-A4):
- At t 0.1 the leaf has left the doorway and is passing behind the near column.
- By 0.2 it is clear of the column.
- At 0.3 it comes in front of the column and the release station.

There is no overlap or pop at the 0.3 layer switch. So the motion design holds up in stills. Only the package misreports it.

**Fix:**
1. Add `await _raw(1)` after `Engine.time_scale = 0.0` in the capture driver, as in my copy.
2. Re-capture j03-flight at 10, 20 and 30 (the part that answers "does it teleport") and at 45, 70 and 90.
3. Rebuild `flight-sequence.png` from the kept run.
4. Correct the DOORS.md line that says j03-flight-20 shows the flight.

### S2. The junction exit's wall-pack shadow still reads as a solid sloped hood

Evidence: panels B1-B2; j08-j14 at 1280 x 1095-1175, y 262-330; phone j13 x 1610-1730, y 325-445.

This was review r4's C3, and it is not done. In the slice's last shot, the dark diagonal from the wall pack's stem down to the operator box reads as a sheet-metal canopy over the door. It is the darkest hard-edged shape on the brightest wall (checklist 3: name what each part does).

**Fix:** let the penumbra widen with distance from the caster (soft at the box end), and lift its value toward the wall's shaded concrete. Or drop it to a short contact shadow under the fitting. Re-capture j08-j14 at both sizes.

## Could fix

- **C1. Copied warm streaks under the exit (review r4 C1).** The orange reflection streaks in the exit floor wedge (j08-j13, about x 1040-1060, y 470-500) still sit under a lamp that turns green.
- **C2. Wear (review r4 C4).**
  - The kick plates read as mottled granite (panel B4, r09 and r01). A satin stainless or painted protection plate shows fine horizontal scratches (ANSI/BHMA A156.6).
  - The leaf scuffs are evenly scattered dashes (`c/jentry-atlas-checker.png`).
  - Both are lost at 1x on 1280; they show on phone.
- **C3. Even speckle on the junction entry cross-wall.** At 3x it carries an even light bug-hole speckle over the whole face (`c/jentry-swing-*.png`; checklist 9). At 1x it reads as rough cast concrete, so this is minor.
- **C4. The landing swap.** At t = 1 the rotated standing leaf is replaced by the lying leaf, which has a different outline: a thin bar becomes a dished plate seen from above. The landing dust covers it in j03-landed, but only play can tell.
- **C5. Still open from r3/r4:** roller scuffs on the exit leaf, the blast column's blotches, smooth hairline cracks, darker blast puffs.

## What passes

### Review r4 items

- **M1 (swing leaves black mid-swing): fixed.**
  - No captured angle shows a black card. That covers 10/20/30/50 % for all three swing doors, plus shut and open (`c/records-entry-states-*.png`, `records-exit-states-*.png`, `jentry-swing-*.png`).
  - My row samples agree with `swing.md`. The Records exit leaf reads sRGB 23-28 shut, 26-48 at 10-20 %, and 33-55 at 50 %, against wall 20-35. The junction entry r10 leaf is now a dark door, not the blackest shape in the frame.
  - Each open leaf falls off about 2x from head to foot (r09 0.074 → 0.032 linear), as a lamp over the door would light it.
  - The Records exit shut leaf is 1.05x its wall. That is within noise, and I accept it.
- **S1 (steam edge): fixed.** The mid plate's steam now feathers onto the cross-wall's corner (`c/steam-r09-4x.png`, `c/phone-r09-left.png`). It no longer stops on a vertical line.
- **S2 (sentry_test race): holds.** It passed in my 19-suite run, 3 at a time.
- **S3 (register): fixed.** All five door atlases are listed, and the bulkhead images are gone.

### The doors against the real thing (rule 2)

- **Records entry, Records exit, junction entry:** 3'0" x 7'0" hollow-metal leaves on three butt hinges at one jamb (SDI 129), at 2.1-2.2 m against the 1.75 m engineer.
  - Each has a surface closer whose arm is visible at the head from the far side in r06 (ICD/ICS 705 TS ch. 3: "an automatic, non-hold door-closer").
  - Each shows a kick plate on the push face.
  - Each passes edge-on at about 31-34 degrees, as this oblique camera requires.
  - Each sets its lamp red when shut.
- **Junction blast door:**
  - Full-surface hinges on the near column. UFGS 08 39 54: "Blast door hinges are normally full surface."
  - After the blast the leaf is torn off and thrown along the lane, away from the charge. SDI 133 Category IV: "The door can become separated from the frame and cause a flying debris hazard". Liu et al. (NDIA 2018): doors "failed outward".
  - It lies bowed with its latch bolts standing out.
  - The torn hinge leaves and keeper pockets stay in the frame, and rubble lies at the column's foot.
- **Junction exit:** a sliding leaf with a striped leading edge, running into a wall pocket, with an operator box and a lamp over the head (UFGS 08 13 73, 2.9.6-2.9.7, top guide and bottom rollers).
- **No leaf fades or vanishes.** The swing leaves close on their closers, the exit leaf slides, and the blast leaf flies and lands.

### The checklist (REAL-LOOK section 3)

| # | Item | Result |
|---|---|---|
| 1 | One projection | The cross-wall feet, heads, form joints and stubs converge consistently in each room. On the Records exit wall, the foot and the joint line both fall toward the near end, as they must for this eye height. |
| 2 | Light logic | Each lit leaf and reveal has its wall pack or batten in frame. Exception: S2. |
| 3 | Every part has a job | Yes, except S2. |
| 4 | Nothing floats | The container stands on the deck, and the EXIT sign hangs on its bracket. The camera and lamps are on arms and conduit. The lying leaf and the rubble are on the deck. The leaf is in the air only during its 0.24 s flight. |
| 5 | Scale | Door heights are as above. The blast leaf lying reads 3.1 m at its 1.25x depth (j06). |
| 6 | Doors | Every opening is alpha 0 in the atlases (checker views). The space beyond each opening is that door's own passage. |
| 7 | No text | There are no letters in any atlas. EXIT, DOOR DOWN and the station names are the game's own plates. The patch adds no new player-facing strings: I diffed the string literals; the only new quoted sentence is a code comment. |
| 8 | Values | The doors carry the contrast at the exits, which guides the eye. Backgrounds stay quiet (greyscale pass). |
| 9 | Wear logic | Acceptable at play size. See C2 and C3. |
| 10 | No repeats | One door type repeats across rooms, as one facility's standard doors should, with different wear. |
| 11 | Rule 5 | No corridor or opening asset or code is changed. The only corridor file removed is the unused `corridor-bulkhead-open.png`. |

### Route and ending

- In my capture the engineer holds at x 848.2 in j12 and j13, as the fix round reports. WOLF walks out first and the engineer second, each passing behind the near column. The doorway is empty before the card (j14-00 to 12).
- No x position, station, camera, text, choice or save changed this round. The closing camera and view-right changes date from round 1 and are documented there.

## Process

### Tests, on a private copy

- I fetched `origin/main` (now fdd5f7b), then made `git archive 0c5d1ae apps/game scripts` and applied `git apply --binary shots/doors-integration.patch`. It applied cleanly, and `diff -rq` against `game-doors/apps/game` is empty.
- **19 of 19 suites pass** (`logs/doors-0c5/SUMMARY.txt`):
  - run 3 at a time with isolated HOMEs under `review-real-r5/homes/`;
  - the first import logged only the 16 known font errors, and the second logged none.
- Against fdd5f7b the patch does not apply (M1).
- No Godot window was opened.

### Budget

My render.sh run at 1280x720 with `--only=junction --perf=1`, main 0c5d1ae against the doors copy, both run by me (`perf/perf-table.md`):

| State | Draw calls p50, main → doors | Additive, main → doors | Texture MB, main → doors |
|---|---|---|---|
| j01 sealed | 94 → 86 | 10 → 9 | 73.37 → 75.25 |
| j04 blown | 98 → 88 | 10 → 9 | 73.37 → 75.25 |
| j06 lane | 105 → 95 | 10 → 9 | 73.37 → 75.25 |
| j08 exit bolt | 98 → 83 | 9 → 8 | 73.37 → 75.25 |
| j11 exit open | 103 → 83 | 9 → 8 | 78.05 → 75.25 |

- Draw calls and additive items are below main in every state.
- Texture memory is +1.88 MB, inside the ~4 MB allowance, and matches `perf.json`.
- My frames match the fix round's within 0.3-1.4 % of pixels (> 8/255). The landed frame is the exception, at 8.2 %, because of dust timing.
- No new full-screen layer.
- For the record: REAL-LOOK section 5's cap of 80 draw calls in the junction lane is still not met in j01-j06 (86-95). That is inherited from main (94-105) and improved by this patch.

### C2PA and provenance

Evidence: `logs/c2pa_check.txt`, `logs/sessions-status.txt`.
- All **33** raw outputs under `codex/**/out/` carry a `caBX` manifest with `c2pa.claim` and `c2pa.signature` (OpenAI).
- All 33 are recorded in `provenance.txt`, and each is byte-identical to its original in `~/.codex/generated_images/`.
- All **24** sessions named in provenance are in `~/.codex/archived_sessions/`, and none is live.
- The image sessions not in this provenance belong to other jobs: seven are `real-slice/add7`, and one is the `cli-ai-conversations` project.
- No Codex session ran for doors-r1 after review r4. The round-4 "no Codex session" entry is present.

### Git

The repository status is clean. I only ran `git fetch`.

## Inherited, not doors (unchanged)

- The mint sentry beam runs through the fallen tank (j10-j14).
- The yellow beam band floats across the alcove (j04, j05).
- The half-faded DOOR DOWN label at the left edge (j13, j14).
- The dialogue box covers the walk-outs and part of the flight.
- Text drafts still await Nathanial ("secure the first copy in the container", "hatch" → "door"). None was shipped.

## Sources

- **UFGS 08 39 54**, *Blast Resistant Doors*: "Blast door hinges are normally full surface"; seating and unseating overpressure. Local copy: `doors-r1/junction/research/dl/ufgs-08-39-54.txt`. https://www.wbdg.org/FFC/DOD/UFGS/UFGS%2008%2039%2054.pdf
- **SDI 133** (ASTM F2927 response categories), Category IV. Local copy: `doors-r1/junction/research/dl/sdi-133.txt`. https://steeldoor.org/wp-content/uploads/2020/02/SDI_133.pdf
- **Liu, Oesterle, Conway and Covino, NDIA 2018**, Kasun Test 6: doors "failed outward"; cracking at wall corners and "along the joints in the concrete at the edges of the steel plates". Local copy: `doors-r1/junction/research/dl/liu-ndia-2018.txt`. https://ndia.dtic.mil/wp-content/uploads/2018/intexpsafety/Liu2Paper.pdf
- **UFGS 08 13 73**, *Sliding Metal Doors*, 2.9.6 top guide rollers and 2.9.7 bottom rollers. Local copy: `doors-r1/hatch/research/ufgs-081373/`. https://www.wbdg.org/FFC/DOD/UFGS/UFGS%2008%2013%2073.pdf
- **SDI 129** (hinges for 1-3/4 in doors). Local copy: `doors-r1/records/research/sdi129.txt`.
- **ICD/ICS 705 Technical Specifications**, ch. 3: "All perimeter SCIF doors shall be equipped with an automatic, non-hold door-closer". Local copy: `doors-r1/records/research/ts-scif.txt`. https://www.dni.gov/files/NCSC/documents/Regulations/Technical-Specifications-SCIF-Construction.pdf
- **ANSI/BHMA A156.6**, *Architectural Door Trim* (protection and kick plates).
- **The game's own records:** REAL-LOOK.md sections 2, 3, 5 and 8; the corridor door end record (DESIGN.md v6); reviews r4 (real and human); DOORS.md (fix round 4); `git log 0c5d1ae..origin/main` (PR #68).
