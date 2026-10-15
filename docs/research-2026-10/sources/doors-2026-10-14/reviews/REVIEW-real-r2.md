# Doors r1, fix round 1: independent realism review (reviewer "real", round 2)

**Verdict: fix-needed.** I would not show this to Nathanial as real yet.

The fix round closed most of round 1:
- the thrown leaf, the rubble, the mirrored deck, the sparks and the exit stub are fixed;
- the camera-facing junction hatch is gone;
- every door stands across its route, and the leaf always goes somewhere.

Four things would still make a person looking at the game say "fake":
1. **Two of the open doorways show a painted copy of the shut door.** A third copy exists in the junction entry's art but is hidden. Codex invented them, and the cleanup kept them.
2. **The junction's own machinery shows through the new entry doorway and under the wall's foot.** The wall reads as pasted over the room.
3. **The M1 fix overshot.** The new walls are now near-black voids, darker than the approved corridor wall. The junction exit's face stays black right next to a ceiling fitting that floods the wall beside it. The steel leaves were not darkened with the walls, so they glow pale against them.
4. **The blast damage still does not read at play zoom.** What there is sits under the DOOR DOWN plate.

Scratch only. My only edits are this file and `doors-r1/review-real-r2/`. Nothing was played by hand, so there are no feel claims here.

## What I checked, and how

- **AI-tell checklist.** I ran every item of REAL-LOOK section 3 on every after frame, in this order:
  - `fix-r1/captures/after-1280/*-clean.png` at full size;
  - `after-phone/*-clean.png`;
  - the 31 crops in `shots/crops/`;
  - my own 2x-8x crops, contrast-stretched and high-pass copies, all in `review-real-r2/c/`;
  - every door atlas on a checker background (`c/*-atlas-checker.png`).
- **Source layers.** I compared each track's construction design (`design-*.png`, `masks/`) with its cleaned layers and with the raw Codex output.
- **Reference.** I compared against the approved corridor door end (`docs/research-2026-10/sources/corridor-door-end-2026-10-12/frames/`).
- **Evidence sheet:** `review-real-r2/evidence-sheet.png`, panels A to G.
- **Measurements:** the scripts are in `review-real-r2/tools/`, and the numbers are quoted below.
- **Tests on a private copy.** I made a fresh `git archive origin/main apps/game` (origin/main is still 4bb15b0 after `git fetch`) and applied `shots/doors-integration.patch` with `git apply --binary`. It applied cleanly, and the result is file-identical to `game-doors/apps/game`.
  - I imported it twice headless with an isolated HOME, then ran every suite with its own HOME (`review-real-r2/run-suites.sh`).
  - **17 of 17 pass** (`review-real-r2/logs/SUMMARY.txt`), including `door_route_test` and `press_sound_test` (29 presses, 29 heard).
  - The first import logs only the 16 known font errors. There are no leaks.
- **Budget, C2PA and provenance:** see "Process" at the end.

## Must fix (blocking)

### N1. The Records doorways show a painted copy of the shut door (and the junction entry's art has one too)

Evidence sheet A, B, C:
- `c/r01-entry-pair.png` and `c/walls-highpass.png` (Records entry, r01);
- `c/r07p-exit.png` (Records exit, r07);
- `c/beyond-compare.png`, `c/rec-exit-beyond-vs-design.png` and `c/jentry-beyond-compare.png` (the layers).

**What a player sees.**
- When the Records entry stands open (r01), the doorway shows a second, shut steel door with a lever and a kick plate, beside the real leaf standing open.
- When the Records exit has swung open (r07), the doorway again shows a shut door with a lever. The open leaf beside it is a featureless dark slab, so the eye reads the ghost as "the door" and the open leaf as a black panel.
- Measured: the ghost is brighter than both the wall and the real leaf. It is L 0.023 (entry) and 0.016 (exit), against walls at 0.005 and leaves at 0.014.
- This is the "missing weird doors" and "you don't need to print the background in it" problem Nathanial named, in a new form: one door drawn twice.

**Cause (verified in the layers):**
- The construction designs for the space behind each doorway have no door:
  - `fix-r1/records/design/exit/design-beyond.png` and its masks: back wall, pipes, strut, fitting, floor;
  - `design/entry/design-beyond.png`: wall and fitting only;
  - `fix-r1/jentry/design/entry/design-beyond.png`: the same.
- The cleaned layers do have one:
  - `fix-r1/records/layers/graded/{exit,entry}/clean-beyond.png`;
  - `fix-r1/jentry/layers/graded/entry/clean-beyond.png`.
- In the cleaned layers, a full door with a lever sits exactly where the shut leaf was painted.
- Codex painted the door end **shut**. `cleanup.py` (and `jeclean.py`) then built the space behind the hole from that same painting. It multiplies the design's flat colour by the paint's high-pass detail, clamped to ±60 % (it was ±35 % in round 1). Any edge Codex puts inside a part survives, including the edges of a leaf that is not part of that layer.
- The same mechanism lets invented parts through anywhere. Nothing in the checks compares the layer's edges with the design's.
- Round 1's exit layer (`doors-r1/records/layers/exit/clean-beyond.png`) has the same ghost. It was missed in review r1 and in the human pass.

**Fix:**
1. Rebuild every space behind a doorway from its own design only:
   - either re-paint it in an **open-state** composition (leaf and frame removed, the opening showing the passage as designed);
   - or, inside the opening's footprint, take no detail from the door-end painting at all. Use the design's colour, with detail sampled from the same part well away from the opening.
2. Add a cleanup check that fails a layer when its high-pass edges line up with another layer's part masks (leaf outline, frame, lever):
   - for example, correlation of |high-pass| with the dilated leaf-mask edge above 0.1 inside the opening;
   - or high-pass energy inside the opening above the passage's own median.
3. Add a capture of each door open with the leaf hidden (a debug toggle in the capture driver only). That frame must show only the designed passage.

### N2. Junction entry: the room's own machinery shows through the doorway and under the wall's foot

Evidence sheet C, D: `c/r09p-jentry-before-after.png`, `c/r11-jentry-foot-5x.png`, `c/jmid-left-compare.png` and `c/junction-left-far-mid.png` (far plate | mid plate | the two composited: the new passage, ghost door included, sits entirely behind the mid plate's opaque tank, pipe column and striped rail).

- **Through the open doorway (r09, r10):** the player sees the junction's own yellow-and-black striped pipe and tank. That is the mid plate, the same pipe that runs through the room on the right. It is not the service line passage painted into `junction-far.png`.
- **Below the cross-wall's diagonal foot (r09-r11, both sizes):** the mid plate's tank base, blue panel and pipe foot show, and the wall cuts their tops off along its foot line.
  - Anything below a receding wall's foot line stands on the floor in front of that wall, so it must overlap the wall, not be cut by it.
  - The wall therefore reads as a picture pasted over the room, standing on nothing.
  - This breaks REAL-LOOK section 2 ("the space behind the hole is room background ... no shared tunnel") and checklist items 4 and 6.
- **Cause:**
  - The NOTES say `junction-mid.png` was "cleared left of the column and the stub (the cutaway)". In fact only **546 pixels** changed in the whole plate, all at plate x 0-25. Main and the patch differ nowhere else (`review-real-r2/plate_diff.txt`, from `tools/plate_diff.py`).
  - The machinery behind the wall face, inside the doorway and in the floor triangle under the foot was never erased.
- **Fix:**
  - In `junction-mid.png`, erase everything under the cross-wall's footprint (wall face, doorway, near column) and in the floor triangle between the wall's foot and the walk line.
  - Repaint that triangle as deck in the room's camera, (511, 162), the way the Records track cleared `records-mid.png` at its ends.
  - Then the passage in `junction-far.png` shows through the doorway.
  - Re-capture r09-r11 and j01-j03 at both sizes.

### N3. One light logic: the walls are now black voids and the leaves glow against them

Evidence sheet E: `c/j08-exit-3x.png`, `c/corridor-approved-s5-after.png`, and the numbers below.

**The junction exit's face, beside a lit fitting.** Same rows, a box on the back wall just left of the corner (x 940-985) against a box on the cross-wall face just right of it (x 995-1040), j08, linear luminance:

| Row (screen y) | Back wall | Cross-wall face | Ratio |
|---|---|---|---|
| 100-140 | 0.658 | 0.0073 | 0.011 |
| 180-220 | 0.240 | 0.0039 | 0.016 |
| 260-300 | 0.055 | 0.0034 | 0.062 |
| 340-380 | 0.079 | 0.0059 | 0.075 |

- The fitting hangs at the back wall close to the corner. The cross-wall face there points straight at it.
- A face that sees the lamp is lit at least as strongly as the back wall the lamp grazes. Here it is 1-7 % of it, with a hard vertical value cut at the corner (j08-j14). It reads as a black card over the room.
- This fails checklist item 2 ("every lit face points at a visible fixture"). The fix round lists it as an open issue ("0.16x the lamp-lit wall beside it"). In the closing shot it is the right quarter of the frame.

**Every new wall against the approved corridor wall.** Same method (median of plain wall; texture is the standard deviation of a 3 px high-pass):

| Wall | Median L | Texture |
|---|---|---|
| Corridor cross-wall, approved (s5 frame) | **0.018** | **0.0039** |
| Records exit (r04) | 0.0040 | 0.0009 |
| Records entry (r03) | 0.0039 | 0.0011 |
| Junction blast (j01) | 0.0035 | 0.0049 |
| Junction exit (j08) | 0.0043 | 0.0013 |
| Junction entry (r11) | 0.0029 | 0.0007 |

- The new walls are 4-6x darker than the corridor wall Nathanial approved, and most carry 3-5x less surface.
- Round 1 was 2-4x too bright. This round is 4-6x too dark.
- The "row by row 0.70x the room's back wall" grade depends on where the room is sampled. The fix round's own note says the exit was measured against "the room's dark recess". A wall graded against a dark recess comes out black.

**The leaves were not darkened with the walls.**
- The junction entry's open leaf is **L 0.022 against its wall's 0.005, 4.2x brighter**: a pale flat card in the first frame of the junction (r09).
- The Records open leaves are 2.9x their walls.
- Painted Gunship Gray steel (FED-STD-595 36118, about #5B5E6A, the colour REAL-LOOK section 8 gives doors) is darker than ordinary grey cast concrete. Under the same light, a leaf should sit at or below the wall beside it, not 3-4x above it.

**The door lights stop at the head.** On the Records ends, the wall pack's pool fills the wall above the door and stops dead at the head, while the leaf directly under it gets no light.

**Fix:** one light solve per door end, shared by the wall, the leaf and the beyond.
- Light each face from the fixtures that are actually there (Lambert term and distance fall-off, like `SwingLeaf.shade`). This includes the junction ceiling fitting at the exit's back corner and each door's own wall pack, whose pool continues down the leaf and onto the threshold.
- Then set the walls to the approved corridor's relation: wall median about 0.45-0.75x the back wall it meets at the same height, with texture at least half the room's. Keep the paint's own grain; add no noise.
- Grade the leaves in the same pass, so painted steel sits at or below the concrete.
- Re-measure at the corners as in the table above, not against the rooms' dark recesses.

### N4. The blown doorway still does not show a blast (r1 M3, still open)

Evidence sheet F: `c/j06-doorway-pair.png` and `c/beyond-others-3x.png`.

- The new damage is in the art: torn head piece, cracks, keeper pockets, liner, rubble. But:
  - **Placement.** The head damage, sag and rebar sit at the DOOR DOWN plate's height in every blown frame (j04-j07, j13). Most of it is covered by the plate, and the rest is a dark smear just above it.
  - **Size.** The cracks in `damage.png` are 1-2 atlas px wide. At the atlas's 0.5 scale that is under one world px, so they vanish in play.
  - **Contrast.** The lane seen through the doorway is a flat pale-blue strip, so the opening reads as a lit slot, not as a torn hole.
- A player still sees "a gap in a dark wall and a slab on the floor", not a door torn off by overpressure.
- Real failure: ASTM F2927 Category IV allows the panel to separate from the frame and the frame anchorage to fail (SDI 133). Liu et al. (NDIA 2018) saw cracking from the wall corners. Damage concentrates at the latch jamb and frame, where the bolts shear.
- **Fix:**
  - Put the readable damage where nothing covers it: the latch jamb and the approach face beside it, between 0.3 and 2.0 m. That means a spall bite, the torn-out 300 mm latch plate bent toward the lane, two or three bar ends, and sheared keeper lugs, each at least 3-4 world px.
  - Check the damage's screen rectangle against the NamePlate's rectangle in the capture driver.
  - Give the lane seen through the doorway the lane's own value and surface at that depth.
  - Moving the plate is a UI decision. Ask Nathanial, and do not change its text.

## Should fix

- **S1. The Records open leaves are featureless slabs** (r07 at both sizes, r08).
  - Once N1 removes the ghost, the face the camera sees must carry its hardware at 2 px or more, drawn in the same light as the wall: push plate or lever, the kick plate band, the closer arm.
  - At the exit today (r07), only the ghost shows a lever.
- **S2. The two "pipe penetration plates" on the Records exit wall have no pipe through them** (`c/r04p-plates-pair.png`, evidence G).
  - They are blank rectangles with leach streaks below them, so these are parts without a job (checklist item 3).
  - Either bring the room's two pipe runs visibly into them, with a pipe and a collar through each plate, or remove both plates and their streaks.
- **S3. The sealed blast door still reads as an ordinary personnel door** (`c/j01p-blastdoor.png`).
  - UFGS 08 39 54 (2.2.1): "Blast door hinges are normally full surface". Latching points "can be provided at the head, sill, and jambs" (2.2.2.1).
  - The leaf shows a lever and a thin frame only.
  - Show the full-surface hinges on the hinge jamb, the latch keepers in the frame and the heavier frame, at real size. The 17 vs 30-35 degree turn is still Nathanial's call.
- **S4. The blast door's threshold reads as a pale plank on the deck** (j01, j02, phone `c/j01p-blastdoor.png`).
  - Its place is right: the design's 0.75 m approach strip runs out from the door toward the valve.
  - Its value is wrong: a bright worn nosing is the lightest thing at the door. Nobody crosses a sealed door, so nothing would wear it bright.
  - Set it near the deck's value, with at most a dull steel edge.
- **S5. Even speckle on the blast door's near column.**
  - In the high-pass (j06 and the evidence sheet), white flecks run evenly from top to bottom (checklist item 9).
  - Calm it to the concrete's own mottle. Put wear only at hand height on the latch side and at the foot.
- **S6. The security container is still the flattest, brightest object at the exit end** (r04-r07).
  - Light it in N3's pass, with fall-off top to bottom and edge light from the room fitting. Its geometry is right.
- **S7. The junction exit header.**
  - The wall pack over the exit is an unlit grey dome on a box (j08-j14). It does not read as a fitting.
  - The Records and blast door lights are lit, so the zoning is not consistent.
  - Either light it, so its pool falls on the leaf and threshold, or make it read clearly as a switched-off fitting.

## Could fix

- The blast dust (j03) is still a soft grey cloud, though it is now directional and the sparks and chips are good. A few darker, denser puffs at the doorway would sell the pressure.
- The closer arm draws as a single light line that is brighter than the leaf. Take its colour from the leaf's shade at the head.

## What passes (round 1 items closed)

- **Doors make sense.**
  - Every door stands across its route, and the route goes through it: the Records entry, the Records exit, the junction entry, the blast door and the junction exit.
  - The leaves swing on their hinges, slide into their pocket (the striped leading edge stays visible) or are thrown. Nothing fades.
  - WOLF follows the engineer through the Records exit (r08), and both leave through the junction exit before the card (j13-j15).
  - `door_route_test` checks this frame by frame and passes on my copy.
- **M2, the thrown leaf.** It now reads as a heavy, bowed steel leaf with torn knuckles and bent bolts. It lies on the deck in front of the walk line, clear of the stub, and draws over the actors as an object in front of them should (DOOR_FRONT_Z). The rubble is a real heap.
- **M4, the mirrored deck.** It is gone. The deck piece's seams run to the room's vanishing point, and the exit stub ends the view.
- **M5, the camera-facing hatch.** It is gone, and the junction entry is a cross-wall door end. N2 still needs fixing before that end reads.
- **S2 (r1).** The valve's outlet now has a spool and a riser into the wall.
- **S4 (r1).** The exit has its stub.
- **S7 (r1).** The sparks are hard streaks.
- **C1 (r1).** The exit and the new entry are designed in the junction's own camera: vp (511, 162) in both specs.
- **Openings.** Every atlas opening is alpha 0 on the checker background. The junction exit's passage is its own designed space, with no ghost.
- **No text in the art.** I found no letter-like marks in any atlas. EXIT, DOOR DOWN and the station names are the game's own captions.
- **Scale.** The doors are 3'0" x 7'0" (Records, junction entry) and the blast opening is 2.3 x 2.6 m, consistent with the 1.75 m engineer.
- **Grounding.** The container, the thrown leaf, the rubble and the lamps on their columns are grounded. The exception is N2.

## Process

**Budget** (render.sh 1280x720, the fix round's own driver, `--only=junction --perf=1`; my private copy and a fresh main, both run by me; `review-real-r2/perf/`):

| State | Draw calls p50, main → after | Additive, main → after | Texture MB, main → after |
|---|---|---|---|
| Junction sealed (j01) | 94 → 86 | 10 → 9 | 73.37 → 76.39 |
| Blown (j04) | 98 → 88 | 10 → 9 | 73.37 → 76.39 |
| Lane with the sentry (j06) | 105 → 95 | 10 → 9 | 73.37 → 76.39 |
| Exit bolt (j08) | 98 → 83 | 9 → 8 | 73.37 → 76.39 |
| Exit open (j11) | 103 → 83 | 9 → 8 | 78.05 → 76.39 |

- These match `shots/perf.json` exactly.
- Draw calls and additive items are lower everywhere. No full-screen layer was added.
- Texture memory is +3.02 MB until the exit opens, then −1.66 MB, inside the ~4 MB budget.
- On the record, not a regression: the lane, at 95, is still above REAL-LOOK section 5's target of 80.
- My frames from this run match the fix round's own to within the animated steam and dust (0.3-1.5 % of pixels differ by more than 8/255). The art I reviewed is the art in the patch.
- Fixing N1-N3 should not cost draw calls. It changes pixels in existing atlases and plates, plus at most one leaf shade.

**C2PA and provenance:**
- **Outputs.** There are 22 raw outputs under `doors-r1/codex/*/out/`: 12 from the three tracks (2 of them the superseded first blown try) and 10 from the fix round. Every one:
  - carries a `caBX` JUMBF manifest with `c2pa.claim` and `c2pa.signature` (ChatGPT / gpt-image);
  - is byte-identical to its original in `~/.codex/generated_images/<session>/`;
  - has its SHA-256 in `provenance.txt` (`review-real-r2/c2pa_check.txt`).
- **Sessions.** All seven fix-round sessions are in `~/.codex/archived_sessions/`, and none is still live.
- **No API use.** Their rollouts call only the built-in `image_gen__imagegen` tool. The only `image_gen.py` and `OPENAI_API_KEY` strings in them come from reading the imagegen SKILL.md, not from calls.
- **Provenance is complete.** The content problem in N1 is a cleanup problem, not a provenance one.

**Notes to correct before filing:**
- `fix-r1/jentry/NOTES.md` says `junction-mid.png` was cleared, and DOORS.md says "the service line passage is painted behind it". Neither is true on screen (N2).
- The Records NOTES describe the passage behind the exit with "concrete back wall, two painted pipes, a cable ladder ... and a vapour-tight LED". The cleaned layer also has a door (N1).

## Sources

- UFGS 08 39 54, *Blast Resistant Doors*, 2.2.1 (hinges: "Blast door hinges are normally full surface") and 2.2.2.1 (latching points at head, sill and jambs). Local copy: `doors-r1/hatch/research/ufgs-083954/`. Source: https://legacy.wbdg.org/FFC/DOD/UFGS/UFGS%2008%2039%2054.pdf
- ASTM F2927 damage categories, as quoted in SDI 133 (Category IV: the panel may separate from the frame and the frame anchorage may fail): https://steeldoor.org/wp-content/uploads/2020/02/SDI_133.pdf
- Liu, Oesterle, Conway and Covino, NDIA 2018 (cracking from the wall corners; the steel door fails first): https://ndia.dtic.mil/wp-content/uploads/2018/intexpsafety/Liu2Paper.pdf
- ICD/ICS 705 Technical Specifications v1.4, ch. 3 (SCIF doors, closer inside, vestibule): https://archive.dni.gov/files/NCSC/documents/Regulations/Technical-Specifications-SCIF-Construction.pdf
- FED-STD-595C chip data (36118 Gunship Gray), as used in REAL-LOOK section 8: https://people.csail.mit.edu/jaffer/Color/FED-STD-595C.txt
- REAL-LOOK.md sections 2, 3, 5 and 8; the corridor door end record (DESIGN.md v6, frames); review r1.
