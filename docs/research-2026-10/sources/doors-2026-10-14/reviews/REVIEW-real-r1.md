# Doors r1: independent realism review (reviewer "real", round 1)

**Verdict: fix-needed.** I would not show this to Nathanial as real yet.

The door logic is right in all four places:
- every door stands across its route, and the route goes through it;
- every leaf goes somewhere (swings, slides into a pocket, or is thrown);
- the art is door-only with alpha-0 openings and a painted space behind each hole;
- there are no painted letters, and nobody fades.

Five things still read as fake or wrong, and a human looking at the frames would catch them:
- the new walls are pale grey slabs that glow brighter than the rooms they stand in;
- the thrown blast door is a clean flat tile lying half inside the wall;
- the blown doorway shows no blast damage;
- the closing shot shows a mirrored floor;
- the junction's entry hatch is still the camera-facing door the playthrough complained about.

Scratch only. I made no edits outside this file and `doors-r1/review-real-r1/`. Nothing was played by hand, so there are no feel claims here.

## What I checked, and how

- **AI-tell checklist.** I ran every item of REAL-LOOK section 3 on every after frame:
  - `integrate/captures/after-1280/*-clean.png` and `after-phone/*`, at full size;
  - the 27 crops in `shots/crops/`;
  - my own 3x and 4x crops and greyscale copies in `review-real-r1/c-*.png`;
  - the three atlases on a checker background (`review-real-r1/*-atlas-checker.png`).
- **Comparison.** I compared against the approved corridor door end frames: `docs/research-2026-10/sources/corridor-door-end-2026-10-12/frames/`.
- **Evidence sheet:** `review-real-r1/evidence-sheet.png`, panels A to G.
- **Value numbers:** `review-real-r1/measure_walls.py`, with output in `measure_walls.txt`.
- **Tests on a private copy.** I made a fresh `git archive origin/main apps/game` at 4bb15b0 and applied `shots/doors-integration.patch` with `git apply --binary`. It applied cleanly, and the result is file-identical to `game-doors/apps/game`.
  - I imported it twice headless with an isolated HOME, then ran all suites, 4 at a time, each with its own HOME (`review-real-r1/run-suites.sh`).
  - **17 of 17 pass**, including `door_route_test` and `press_sound_test`, with no errors and no leaks (`review-real-r1/logs/SUMMARY.txt`).
- **Budget re-measured with render.sh.** Both runs are 1280x720 with the same driver, one on my private copy and one on a fresh main (`--name doors-r1-review-real-junction-after` / `-main`). Results are in `review-real-r1/perf-after/_run.json` and `perf-main/_run.json`. They match `perf.json` exactly:

  | State | Draw calls (p50), main → after | Additive, main → after | Texture MB, main → after |
  |---|---|---|---|
  | junction sealed | 94 → 90 | 10 → 9 | 73.37 → 75.13 |
  | blown | 98 → 92 | 10 → 9 | 73.37 → 75.13 |
  | lane with the sentry | 105 → 96 | 10 → 9 | 73.37 → 75.13 |
  | exit bolt | 98 → 91 | 9 → 8 | 73.37 → 75.13 |
  | exit open | 103 → 89 | 9 → 8 | 78.05 → 75.13 |

  - Draw calls and additive items are at or below today's numbers. Texture memory is +1.76 MB until the exit opens, which is inside the ~4 MB budget.
  - Not a regression, but on the record: the lane, at 96, is still above REAL-LOOK section 5's target of 80.
- **C2PA and provenance.** There are 12 raw outputs under `doors-r1/codex/*/out/`: 10 sessions, and the blown job made two outputs on each of its two tries.
  - Every one carries a `caBX` JUMBF manifest with a `c2pa.claim` and a `c2pa.signature` (ChatGPT / gpt-image).
  - Every one is byte-identical to its original in `~/.codex/generated_images/<session>/`, and its SHA-256 is in `provenance.txt`.
  - All 10 sessions are in `~/.codex/archived_sessions/` and none is still live.
  - Each session used the built-in `image_gen` with input images. No `image_gen.py` or API call appears in any rollout.
  - The other five image sessions from today (`01a134ac…`, `01a134bc…`, `01a134c1…`, `01a134c3…`, `01a134c9…`) belong to `real-slice/add7`, not to doors-r1.
  - Script: `review-real-r1/c2pa_check.py`.
  - **Provenance is complete.**
- **Rule 5.** The patch touches no cage or opening code. `room_depth.gd` only adds `near_left_edge` (default true) and removes the dead bulkhead helpers.

## Must fix (blocking)

**M1. The new architecture is brighter than the room it stands in, so it reads as pasted grey-box.** Evidence sheet A/B and `measure_walls.txt` (luminance on plain wall away from fixtures):

| Piece | Cross-wall L | Room back wall L | Ratio |
|---|---|---|---|
| Corridor door end (approved) | 0.102 | 0.142 | **0.72** |
| Records entry (r01) | 0.195 | 0.067 | **2.93** (upper wall 0.140 vs 0.043: 3.3) |
| Records exit (r04) | 0.214 | 0.084 | **2.56** (upper 0.156 vs 0.041: 3.8) |
| Junction blast cross-wall (j06) | 0.115 | 0.054 | **2.12** |
| Junction exit cross-wall (j11) | 0.146 | 0.076 | **1.93** |

- The approved wall sits darker than its room. Every new wall is 2-4x brighter than its room's background, and it covers up to a quarter of the frame (Records left 0-290 and right 975-1280; junction exit 1045-1280).
- REAL-LOOK section 2 says "background in 3 low-contrast values, actors and interactables brightest". Here the biggest bright shapes on screen are plain concrete. The Records passage (L 0.278) and the TANK RELEASE bay (0.246) are brighter still.
- **Fix:**
  - In each track's cleanup, re-grade the cross-wall, the near column, the stub, the Records passages and the release bay to the corridor's relation:
    - wall median at most about 0.75x the room's back-wall median at the same height;
    - an upper-wall fall-off toward the ceiling like the corridor's.
  - Keep the painted pools only under the wall packs and fittings that throw them.
  - Add the wear real use puts there, and nothing else:
    - hand polish at the latch-side jamb at 0.9-1.2 m;
    - a scuffed kick zone at each threshold;
    - a darker damp band at the floor joint;
    - drip lines only under the penetrations.
  - Re-measure with `measure_walls.py` and the `render.sh` frames.

**M2. The thrown blast-door leaf is a clean, flat tile that lies inside the wall's footprint.** Evidence sheet C, `c-j06-phone-stub-leaf.png`, `z-junction-lying.png`.
- Its front face holds one flat value (L 0.078 for 14 rows at x 760, j06): no bow, no dishing, no material.
- The junction NOTES promise "propped on one chunk, bowed, torn hinge knuckles". None of it shows at 1x, 2x or in the atlas.
- Its left end lies flat at deck level across the cross-wall's floor stub (the cut section). That puts it inside the wall, or floating over a kerb.
- Real behaviour: ASTM F2927 Category IV, the category the design itself cites, means "door panel is severely deformed with openings between the door and frame … may separate from the frame, and/or the frame anchorage may fail" (SDI 133-2026). A leaf that has torn off its hinges is bent, not pristine.
- **Fix (design first, then one paint pass):**
  - Model the leaf with a visible bow: at least 3 world px of sag across 2.3 m, plus a dished face.
  - Tilt it about 5-8 degrees, resting on one rubble chunk under the latch end.
  - On the edge toward the camera, show torn hinge knuckles and two bent locking bolts.
  - Move it at least 8 world px right so it clears the stub, or let it rest on the stub, tilted, with a contact shadow on the stub's top face.

**M3. The blown doorway does not read as blown at gameplay zoom.** Evidence sheet D, `c-j06-phone-doorway.png`, j04 and j06.
- The approach face around the opening is uniform, clean concrete. Only the three keeper pockets in the far reveal and a thin bent strip at the head show.
- The NOTES list "spalled round the frame, exposed rebar, latch-side flange peeled, head sags, soot". Not readable in either the 1280 or the phone render.
- Without this the player still cannot see why the door had to be blown, or that it was. That was the newcomer's complaint.
- Real failure: Category IV allows frame-anchorage failure. Liu et al. (NDIA 2018) observed cracking from the wall corners and the steel door failing first.
- **Fix, sized to survive 1.35x (each feature at least 3-4 world px):**
  - an irregular spall bite round the frame on the approach face, deepest at the latch jamb;
  - two or three rebar ends in the bite;
  - cracks from the opening's head corners;
  - the latch-side flange bent out of the plane;
  - a 2-3 px head sag.

  Keep the rest of the wall calm. Since this is a pressure-line blow, add soot only if the fuse is meant to be an explosive charge.

**M4. The closing shot shows a mirrored deck past world x 960.** Evidence sheet E, `c-j13-mirrored-deck.png`.
- Cause: `exit_deck` is the mid plate's right edge with `flip_h`. Main never showed it, because its camera stopped at 960. The new play and closing cameras reach 1000.
- Visible result: the deck seams meet in a V (about screen x 1195 in j13 and j14), and the wet reflections repeat as a mirror image.
  - Right of the axis, the seams lean toward a mirrored vanishing point near world x 1409, against the room's (511, 162).
  - That breaks checklist items 1 and 10, in the last frame before END OF SLICE.
- **Fix, either of:**
  - extend the deck to x 1032 from a non-mirrored slice, with seams re-drawn toward (511, 162);
  - end the visible deck under the exit's stub cutaway (S4), so the bleed is never on screen.

**M5. The junction's entry hatch (x 80) is still the camera-facing pressure hatch.** Evidence sheet G.
- The engineer starts the junction standing beside it, not having come through it. It is the same "door faces the camera, route runs past" problem the playthrough named, and the same look the Records entry just lost.
- Nathanial chose "The other doors, the hatch and the rooms then get the same treatment".
- **Fix:** either give it the same cross-wall treatment, standing open behind the arriving pair and shutting like the Records entry, or get Nathanial's explicit OK to defer it.

  Do not present this round as "all doors" while it stays.

## Should fix

**S1. Actors inside door frames.**
- WOLF at the rubble (x 448) has his head inside the near column (j04).
- In `j05-walking-through` the engineer is almost entirely behind the column, so the walk-through itself is not seen.
- The integrator's option (b) needs no x change: WOLF faces back at the engineer at the rubble, as he does at the exit, so his head is in the open.
- Also capture the frame where the engineer clears the column, to show the walk-through, and get it hand-played.

**S2. The valve's outlet now hangs in mid-air in front of the blast wall.**
- `c-j06-phone-doorway.png`: an elbow down to an open flange, about 0.75 m above the deck. The old door hid it.
- The NOTES say the wall has "the charge line's welded penetration plate", but nothing connects the valve to the door, so nothing on screen says how the valve blows it.
- **Fix:** add a short flanged spool from the outlet into a welded penetration plate on the cross-wall's approach face, drawn in the wall design (REAL-LOOK section 8: one welded plate, 6 px margin).

**S3. A point-light shadow at the exit door head.**
- `c-j11-exitdoor.png`, evidence sheet F, and `hatch/design/v6/design-open.png`: a hard-edged black wedge runs about 1.2 m down the wall from the wall pack's box.
- The ray-cast treats the junction's linear ceiling fitting as a point. A roughly 1.2 m fitting gives a penumbra wider than the 0.2 m box, so its shadow would be a faint smudge.
- **Fix:** soften it in proportion to the source size, or drop it.

**S4. The exit wall has no stub cutaway across the deck.**
- The corridor door end and the blast door both carry their wall's cut section to the deck's front edge. The exit wall just stops at the walk line, so open deck runs in front of it and the wall does not visibly close the room.
- **Fix:** add the stub as the blast door has it. It also hides most of M4.

**S5. Records doors: the closer that shuts the entry, and the hinges, are not drawn.**
- ICD/ICS 705 (v1.4, ch. 3) requires "an automatic, non-hold door-closer … installed internal to the SCIF". The design uses it: "its closer brings it shut".
- But no closer body or arm shows on the room-side head of either door, and no hinge knuckles show on the hinge edge: none on the leaf faces (`z-records-leaves.png`), and none at gameplay zoom.
- **Fix:**
  - a surface closer (about 0.30 x 0.06 m body plus arm) on the room side of each head;
  - three 4-1/2 in hinge knuckles, spaced per SDI 129, at least 2 px;
  - the floor stop the exit leaf lands on.

**S6. The two Records end walls are the same layout, mirrored.**
- Camera dome, conduit drop, pour joint and wall pack are all in mirrored places: correlation 0.72 mirrored vs 0.22 unmirrored on the atlas regions (`records-walls-entry-vs-mirrored-exit.png`).
- Checklist item 10 says not from the other side of the same room either.
- **Fix:** vary one without adding devices. For example: no camera on the entry side, the pour joint at another height, the wall pack on a different conduit run.

**S7. The effects still use the "one soft blob".**
- The exit bolt sparks are mint or cyan soft discs (j10).
- The blast dust is one soft grey sheet (j03).
- **Fix:**
  - sparks as 2-4 px hard streaks with gravity and a short life;
  - dust as a directional jet through the doorway into the lane, with a few fragment particles;
  - stay within today's emitter and particle budget (REAL-LOOK section 5).

**S8. The security container reads as an unshaded clay box.**
- Its geometry is right: GSA Class 5, four legal drawers, 1.486 m, lock at 1.25 m.
- But the front face is one flat value, and the X-10 lock housing (about 0.13 x 0.10 m, so about 5 x 4 world px) is a 2 px dot.
- **Fix:**
  - paint enamel and light from the room fitting and the exit wall pack (edge highlights, a slight top-to-bottom fall-off);
  - make the lock housing and its dial read.

  It is the one new object standing in the open play space.

**S9. Concrete walls stand on the junction's raised steel deck.**
- Both junction cross-walls (0.40 m and 0.66 m of reinforced concrete) end at the deck surface, and the striped steel fascia runs on under them uninterrupted.
- **Fix:** carry the wall's cut section down the fascia face to the structure below, or set each wall on a visible concrete upstand.

## Could fix

- **C1. Two vanishing points in one room.**
  - The blast door uses (511, 162), measured from the junction's deck seams; the track's own seam pairs intersect near world x 509-516. The exit door uses the corridor's (483.9, 158.5).
  - The visible difference is under 1 degree on its lines, but checklist item 1 asks for one per room.
  - Rebuild the exit with (511, 162) at its next paint pass.
- **C2. The sealed blast door reads as an ordinary personnel door** at 34 screen px.
  - The 0.18 m channel-frame flange in the spec renders at about half its width.
  - Make the head and jamb flange read at their full 7 world px, and show the steel threshold plate.
  - The 30-35 degree turn stays Nathanial's call.
- **C3. A half fixture at the Records entry.** The far plate's back-wall lamp at about screen x 285 (r01) is now cut in half by the entry cross-wall. Paint it out, or move it clear of the corner.
- **C4. Honest notes.** The junction NOTES (bowed and propped leaf, torn knuckles, rebar, soot) and the Records notes ("visible hinges") describe things the renders do not show. Correct the notes or the art before filing them under `docs/research-2026-10/sources/`.

## What passes

- **Doors make sense.** The Records exit leaf swings into the room over 3.5 s and stays drawn. The exit slide leaves its striped leading edge in the pocket mouth. The thrown leaf lands within 3 m. The walk-out shows WOLF and then the engineer going through the exit doorway before the END card (j14-00 to j15). `door_route_test` checks all of this frame by frame, and it passes on my copy.
- **Doorways.** Every opening is alpha 0 in the atlases, and each has its own space behind it: the corridor-side space at the Records entry, the service-line passage at the Records exit, the lane at the blast door, and the service passage at the exit. None is a shared tunnel.
- **No text in the art.** There are no letter-like marks in any atlas region. Only the game's NamePlates show text.
- **Grounding.** The container has a contact shadow: L 0.122 at its base vs 0.19-0.22 at 8-12 px out. The thrown leaf has a dark contact line. The status lamps sit on back boxes with conduit.
- **Scale.** The Records doors are 3'0" x 7'0", the container is 1.486 m and the exit opening is 2.0 x 2.4 m, all consistent with the 1.75 m engineer.
- **Process.** The tests, budget, C2PA, archive and register are in order (see above).

## Sources

- ASTM F2927-21 damage categories, as quoted in SDI 133-2026: https://steeldoor.org/wp-content/uploads/2020/02/SDI_133.pdf
- UFGS 08 39 54, *Blast Resistant Doors*. "Blast door hinges are normally full surface"; latching points at the head, sill and jambs: https://legacy.wbdg.org/FFC/DOD/UFGS/UFGS%2008%2039%2054.pdf
- Liu, Oesterle, Conway and Covino, NDIA 2018 (cracking from the wall corners, the steel door fails first): https://ndia.dtic.mil/wp-content/uploads/2018/intexpsafety/Liu2Paper.pdf
- ICD/ICS 705 Technical Specifications v1.4, ch. 3, SCIF door criteria (automatic non-hold closer inside; hinge pins): https://archive.dni.gov/files/NCSC/documents/Regulations/Technical-Specifications-SCIF-Construction.pdf
- SDI 129-24, *Hinge and Strike Spacing* (4-1/2 in hinges, 1-3/4 in doors): https://steeldoor.org/wp-content/uploads/2020/02/SDI_129.pdf
- GSA Class 5 filing cabinets: https://origin-www.gsa.gov/system/files/Class_5_Filing_Cabinets.pdf
- The X-10 lock (FF-L-2740B): https://www.dormakaba.com/us-en/solutions/products/safe-locks/x-0-series/kaba-mas-x-10-449404
- REAL-LOOK.md sections 2, 3, 5 and 8; the corridor door end record (DESIGN.md v6, frames).
