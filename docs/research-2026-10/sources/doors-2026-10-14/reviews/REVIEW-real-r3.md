# Doors r1, fix round 2: independent realism review (reviewer "real", round 3)

**Verdict: fix-needed.** This is close, but I would not show it to Nathanial as real yet.

Fix round 2 closed most of review r2:
- The ghost doors are gone.
- The junction entry wall now stands on the floor in front of the room.
- The exit wall is lit by the fitting beside it.
- The sliding door really goes into a pocket you can see.
- WOLF no longer stands in the valve or in the exit jamb.

Three things would still make someone looking at the game say "fake" or "generated":
1. **A violet fringe** outlines the junction exit's shut leaf. It is a matte edge and is plain to see on a phone.
2. **Two of the three open swing leaves are black, flat cards.** They sit next to the bright jamb they hang on, and the same door light falls on both. Identical doors in the slice disagree with each other.
3. **The first frame of the junction has new paste marks** where the header pipe meets the entry wall:
   - a bare white lamp lens, clipped by the wall;
   - a white smear under the pipe;
   - a hard seam where the pasted pipe meets the plate.

Scratch only. My only edits are this file and `doors-r1/review-real-r3/`. Nothing was played by hand, so this review makes no feel claims.

Evidence sheet: `review-real-r3/evidence-sheet.png`, panels A to F. All crops are in `review-real-r3/c/`, and the scripts are in `review-real-r3/tools/`.

## What I checked, and how

- **AI-tell checklist.** I ran every item of REAL-LOOK section 3 on the after frames:
  - `fix-r2/captures/after-1280/*-clean.png` at full size;
  - `after-phone/`;
  - the 49 crops in `shots/crops/`;
  - my own 3x-8x crops, plus contrast-stretched copies.
- **Atlases.** I checked all four door atlases on a checker background (`c/atlas-*-checker.png`).
- **Reference.** I compared against the approved corridor door end (`docs/research-2026-10/sources/corridor-door-end-2026-10-12/frames/`, s1 and s5).
- **Construction.** I compared the designs and masks with the cleaned layers where a finding needed it: the junction entry wall and the exit door's v8 masks.
- **Real hardware.** I checked the doors against the local copies of these standards and papers (see Sources): UFGS 08 39 54, UFGS 08 13 73, SDI 133 (ASTM F2927), Liu et al. (NDIA 2018), SDI 129 and the ICD 705 Technical Specifications.

## Must fix (blocking)

### R3-1. A violet fringe around the junction exit's shut leaf

Evidence panel A: `c/phone-j08-violet-5x.png` and `c/jexit-slide-6x.png`.

- **Where it is.** `junction-exit-atlas.png`, region `EXIT_LEAF` (870, 0, 120, 236), has **858 violet pixels** along the leaf's left and bottom edges. Examples: RGB (66, 42, 100) at alpha 190, and (51, 42, 85). The other three atlases have none.
- **On screen** it shows in three frames:

| Frame | Violet px, 1280x720 | Violet px, phone |
|---|---|---|
| j08 | 84 | 151 |
| j09 | 84 | 151 |
| j10 | 24 | 61 |

- **Why it matters.** It draws a lavender line under and beside the door the text sends the player to. A coloured matte edge is a textbook "composited / generated" tell.
- **Fix:**
  1. In the exit cleanup, replace the RGB of the edge pixels with the leaf's own neighbouring interior colour. Alternatively, erode the leaf alpha by 1 px.
  2. Add a check that fails any atlas pixel where alpha > 0, b − g > 20 and r − g > 8. Run it on all four door atlases.

### R3-2. Open swing leaves read as black, flat cards beside the lit jamb they hang on (one light logic, checklist 2 and 8)

Evidence panels B and B2: `c/r07-exit-6x.png`, `c/r09-door-6x.png`, `c/rexit-closed-open-noleaf-4x.png`. Measured with `tools/leaf_vs_reveal.py`.

When a leaf is open 90 degrees, its camera face and the far-jamb reveal it is hinged to face the same way. The door light over the head lights both at nearly the same angle (the Lambert term is about 0.32-0.33 for both at 1.5 m). In linear light, measured in the same rows:

| Door (frame) | Rows | Leaf | Reveal | Leaf / reveal |
|---|---|---|---|---|
| Records exit (r07) | 350-490 | 0.0054-0.0100 | 0.028-0.074 | **0.14-0.19** |
| Junction entry (r09) | 350-490 | 0.0054-0.0147 | 0.035-0.094 | **0.16-0.17** |
| Records entry (r01) | 350-490 | 0.023-0.045 | 0.025-0.057 | 0.80-1.02 |

- **Same door, different light.** Two identical 3'0" x 7'0" doors under the same kind of fitting disagree five-fold. At the Records exit and the junction entry, the leaf is a near-black rectangle beside a bright steel strip.
- **The faces are flat.** The open-leaf faces measure 0.02-0.06 relative fine texture (`tools/leafflat.py`), against 0.17-0.31 on the walls beside them.
- **What a player sees.** On the phone (r07) the exit leaf is the blackest flat shape in Records, right behind the engineer. That is too close to the "flat rectangle doorway" Nathanial named.
- **Likely cause:**
  - the single exposure multipliers (`RecordsRoom.EXIT_LEAF_EXPOSURE` 0.17 and `JunctionRoom.ENTRY_LEAF_EXPOSURE` 0.33) scale the door light down along with the ambient light;
  - the 73 x 171 face regions are drawn about 2-3x smaller with `LINEAR_WITH_MIPMAPS`, which removes the paint's scuffs.
- **Fix:**
  1. Light the leaf from the door light at the intensity that reproduces the painted reveal. Target leaf / reveal 0.7-1.0 at the head next to the hinge, falling toward the free edge. Keep the leaf at or below the wall where that light does not reach.
  2. Make the face detail survive at play size. Either pre-scale the face regions to their on-screen size or draw the leaf without mipmaps. Target at least 0.12 relative texture, with grime at the bottom rail and wear around the lever.
  3. Add a check comparing leaf and reveal in r01, r07 and r09.

### R3-3. Junction entry: a bare lamp lens, a white smear and a paste seam where the header pipe meets the wall

Evidence panel C: `c/r09-header-before-after-6x.png`, `c/r09-pipeend-8x.png` and the phone frame `after-phone/r09-after-leaving-clean.png`.

This is in every junction frame that shows the left end: r09-r11 and j01-j04, at both sizes. It is the first thing on screen when the junction opens.

- **A bare white lens**, 37 x 8 px at 1280 (min channel > 170; r09 and j04 at x 224-261, y 112-120; j01 at x 160-203).
  - It is the far plate's ceiling lamp 0. `jemid.py` exposed it when it erased the elbow in front of it, and the cross-wall and the pasted pipe now clip it.
  - Its body, clips and bracket do not show. Main shows only a 6 x 6 px highlight there.
  - It reads as the same "stray white dash" the human pass flagged in r2.
- **A white smear under the pasted header's left end**, 29 x 5 px (x 192-221, y 211-216).
  - It is a highlight on the underside of a pipe that is lit from above. Nothing below could light it (checklist 2).
- **The pasted run of header is a rectangle.** Its right end is a hard vertical cut against the plate's old elbow flange, so it reads as a sticker, not as a pipe that runs on into the wall.
- **Fix:**
  1. Either keep the lamp hidden by re-laying the plate's own pipe over it, or show the whole fitting (body, clips, end caps), as the other passages' battens now do.
  2. Value the pasted run from above: lit top, dark underside, no white underside.
  3. End the run on a flange, or join it to the plate's own header with a feathered, value-matched seam. Re-capture r09-r11 and j01-j04 at both sizes.

## Should fix

- **S1. The blast door's threshold is still a pale plank** (panel D, `c/j01-thresh-8x.png`).
  - In j01, rows 494-518, it reads 0.064-0.094 linear, against 0.010-0.025 on the deck beside it: 3-4x the deck.
  - It is still the lightest flat surface at the door in j01, j02 and phone r09/j01. Review r2's S4 is not met on screen.
  - **Fix:** grade it to the deck median ±15 %, with at most a 1 px dull steel edge.
- **S2. The junction exit's pipe collars read as four stacked black knobs** (panel E, `c/j08-pipes-8x.png`).
  - They are at the wall's far edge, j08-j14, about x 995-1010, y 225-305. Each is about as wide as it is tall, and the glossy pipes stop at them, so they read as a signal-lamp stack.
  - The face is turned 17 degrees off the view axis. A collar ring on it projects to a vertical ellipse about 0.3x as wide as it is tall, with the pipe visibly passing into it (checklist 1).
  - **Fix:** draw the collars as foreshortened rings from the model, carry the pipes into them, and value them from the pipes.
- **S3. The thrown leaf reads as a clean slab or pallet** (panel F, `c/j04-leaf-4x.png`; j04-j14).
  - The top is flat, the edges are straight and crisp, and at play zoom there is no visible bow, dent, scrape or scorch. Only the three hinge blocks say "door".
  - ASTM F2927 Category IV (SDI 133) is a door torn from its frame and thrown as flying debris. A 0.3 m concrete-filled leaf thrown about 3 m lands bowed, with a crushed landing corner, a torn hinge edge, scraped paint and soot near the charge.
  - **Fix:** show the bow in its silhouette (at least 3 world px), crush one corner, scrape the face at its leading edge, and add soot on the approach face near the latch.
- **S4. The blown doorway still reads only through the DOOR DOWN plate at 1x** (`c/j06-blown-door-5x-st.png`, j04-j07).
  - The damage is now where it physically belongs:
    - the far reveal's keepers torn out;
    - spall at the head and at the hinge corner;
    - torn hinge leaves on the column.
  - That matches Liu et al. (cracking at the wall corners, failure along the frame's plate edges, little deformation in the steel) and SDI 133.
  - At 0.004-0.02 linear, though, it disappears. Contrast-stretched it reads well; in true values it reads as a dark gap with a grey panel.
  - **Fix:** make fresh fracture faces and torn bare steel (keeper pockets, hinge leaves, spall arrises) lighter than the weathered face, and keep the soot dark. Whether the plate moves is still Nathanial's call.
- **S5. Provenance is missing one output.**
  - The file is `codex/r2-junction-exit/out/attempt-1/r2-junction-exit-leaf-painted.png` (sha256 d72dd17e…, original `exec-df57d913-…png` in session 01a136e0).
  - It is not in `provenance.txt`. It keeps its C2PA and matches its original byte for byte, but it is unused and unrecorded.
  - DOORS.md says 10 outputs; round 2 produced 11.
  - **Fix:** add a provenance line marking it unused, and correct the count.

## Could fix

- **The exit's sliding leaf face is very clean** (0.035 relative texture). Add roller scuffs along the bottom rail and hand wear at the leading edge.
- **The blast door's near column still shows mottled white blotches at 3x and above.** It is better than r2, but still even from top to bottom.
- **The `DoorCracks` hairlines are smooth curves in the atlas.** Real concrete cracks are jagged and branch. They are seen only in the breaking frame.

## What passes

- **Review r2 N1 (ghost doors): fixed.** Every leaf-hidden frame shows only the designed passage, with no second door: r01, r07, r09, j01, j08 and j11 noleaf.
- **Review r2 N2: fixed.**
  - The junction's machinery no longer shows through the entry doorway or under the wall's foot.
  - The floor triangle is deck, and the wall stands on it.
  - The escutcheons are narrow ellipses, which is correct on a wall seen nearly edge-on.
- **Review r2 N3 (walls): fixed.**
  - My own boxes on j08 read 0.41 / 0.71 / 0.67 / 0.62x the back wall, as the fix round says.
  - The Records and junction walls read as concrete in their rooms' light.
  - The leaf issue is R3-2 above.
- **Doors make sense:**
  - All five doors stand across the route, and the actors walk through them (r08, j14).
  - The swing leaves turn on three 4-1/2 in hinges (SDI 129) on the far jamb, on the pull side. Their surface closer has a regular arm. ICD 705 TS requires "an automatic, non-hold door-closer" on perimeter SCIF doors.
  - The blast door has full-surface hinges (UFGS 08 39 54 2.2.1: "Blast door hinges are normally full surface").
  - The exit leaf runs into a real pocket in the far reveal (its slot shows in `j08-noleaf`; open, only the striped edge stays in the mouth), on bottom rollers (UFGS 08 13 73 2.9.7).
  - The blast leaf is thrown into the lane, away from the charge. Nothing fades.
- **Human r2 must-fixes:**
  - WOLF is clear of the exit jamb in j12 and j13, and stands in front of the valve in j04 and j05.
  - The walk-outs show him going through, then the engineer.
- **Checklist items:**
  - **No text (7):** there are no painted letters in any atlas.
  - **Openings (6):** every opening is alpha 0.
  - **Scale (5):**
    - the swing doors are 3'0" x 7'0";
    - the blast opening is 2.3 x 2.6 m;
    - the exit opening is 2.0 x 2.4 m;
    - all three agree with the 1.75 m engineer.
  - **Nothing floats (4):** every new item stands on the deck or is fixed by visible hardware: the lamps on strapped conduit, the battens on clips, the sign on its flag bracket, the container, the rubble and the thrown leaf.
  - **One projection (1):** the door ends share the room's vanishing point in their specs, and the edges in the crops agree. The exception is S2.

## Process

- **Tests, on a private copy:**
  - `git fetch`; origin/main is **cec75f6**. I ran `git archive origin/main apps/game scripts` and applied `shots/doors-integration.patch` with `git apply --binary`. It applied cleanly, and `diff -rq` against `game-doors/apps/game` is empty.
  - The first import logs only the 16 known font errors; the second logs none.
  - **18 of 18 suites pass**, including `door_route_test`, `crank_hold_test` and `sentry_test` (`review-real-r3/logs/`, `run-suites.out`).
- **Budget** (render.sh 1280x720, the fix round's driver `--only=records --perf=1`; main cec75f6 and my copy, both run by me; `review-real-r3/perf/`):

| State | Draw calls p50, main → after | Additive, main → after | Texture MB, main → after |
|---|---|---|---|
| Records arrival (r01) | 53 → 53 | 9 → 9 | 73.12 → 76.42 |
| Records shut (r03) | 49 → 49 | 9 → 9 | 73.12 → 76.42 |
| Copy point (r04) | 47 → 45 | 9 → 9 | 73.12 → 76.42 |
| Exit open (r07) | 47 → 45 | 9 → 9 | 73.12 → 76.42 |
| Junction entry shut (r11) | 96 → 88 | 10 → 9 | 73.37 → 76.67 |

  - Draw calls and additive items are at or below main, and no full-screen layer was added.
  - Texture memory is **+3.30 MB**, inside the ~4 MB budget. This matches `shots/perf.json`.
  - My frames differ from the fix round's by 0.2-2.7 % of pixels (> 8/255), which is dust and steam.
- **C2PA and provenance** (`tools/c2pa_check.py`, `c2pa_check.txt`):
  - All **33** raw outputs under `codex/*/out/` (including `superseded-r1/` and `attempt-1/`) carry a `caBX` manifest with `c2pa.claim` and `c2pa.signature` (OpenAI), and each is byte-identical to its original in `~/.codex/generated_images/`.
  - 32 of the 33 are in `provenance.txt`. The exception is S5.
  - All 24 sessions named in provenance are in `~/.codex/archived_sessions/`, and none is live (`sessions-status.txt`).
  - The seven round-2 rollouts use the built-in `image_gen__imagegen` only, with no shell call to an image API or `image_gen.py` (`rollouts-r2.txt`). The `OPENAI_API_KEY` strings in them are the imagegen skill's text, not calls.

## Sources

- UFGS 08 39 54, *Blast Resistant Doors*, 2.2.1 (full-surface hinges) and 2.2.2.1 (latching points). Local copy: `doors-r1/hatch/research/ufgs-083954/`. https://www.wbdg.org/FFC/DOD/UFGS/UFGS%2008%2039%2054.pdf
- UFGS 08 13 73, *Sliding Metal Doors*, 2.9.6-2.9.7 (top guide and bottom rollers). Local copy: `doors-r1/hatch/research/ufgs-081373/`. https://www.wbdg.org/FFC/DOD/UFGS/UFGS%2008%2013%2073.pdf
- SDI 133 (ASTM F2927 response categories). Category IV: "The door can become separated from the frame and cause a flying debris hazard". Local copy: `doors-r1/junction/research/dl/sdi-133.txt`. https://steeldoor.org/wp-content/uploads/2020/02/SDI_133.pdf
- Liu, Oesterle, Conway and Covino, NDIA 2018: "initial cracking at the corners of the walls"; "the doorframe failed along the joints in the concrete at the edges of the steel plates and little structural deformations occurred in the steel". Local copy: `doors-r1/junction/research/dl/liu-ndia-2018.txt`. https://ndia.dtic.mil/wp-content/uploads/2018/intexpsafety/Liu2Paper.pdf
- SDI 129, hinge and strike sizes for 1-3/4 in doors (4-1/2 in hinges). Local copy: `doors-r1/records/research/sdi129.txt`.
- ICD/ICS 705 Technical Specifications, ch. 3: "All perimeter SCIF doors shall be equipped with an automatic, non-hold door-closer". Local copy: `doors-r1/records/research/ts-scif.txt`. https://www.dni.gov/files/NCSC/documents/Regulations/Technical-Specifications-SCIF-Construction.pdf
- REAL-LOOK.md sections 2, 3, 5 and 8; the corridor door end record (DESIGN.md v6, frames); reviews r1 and r2 (real and human); DOORS.md (fix round 2).
