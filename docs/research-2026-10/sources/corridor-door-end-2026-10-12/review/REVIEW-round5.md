# Review, round 5: the corridor's door end (independent, adversarial)

**Verdict: fix needed, one small item.** Fix round 4 closed both round-4 must-fixes, and I re-measured both. One fault is left that shows on screen: the status lamp's conduit on the near column starts in mid-air, with nothing at its top end. REAL-LOOK's checklist item 3 fails on that, and the design's own spec says the conduit comes "from the camera's box". It is a deterministic fix of a few minutes, then three re-captures. After that I would show this piece to Nathanial as real.

Nothing else I found reads as generated. At full size it is a cast concrete cross-wall across the walkway, with a numbered grey roller door in it and a dim plant room beyond. It is a large step up from main's red sci-fi gate.

**What I reviewed:**
- Every after-shot in `raw5/slice/` against `raw5/main/`: A-720, B-720, A-phone, B-phone, O-720 and O-720-r2.
- Each one at full size, in 3-6x crops, in greyscale and with the contrast stretched. I ran REAL-LOOK section 3 on the in-game frames, not on the loose assets.

**What I ran myself:**
- My own render.sh probe of s1, s5 and s7 in both copies (job names `review-r5-slice` and `review-r5-main`).
- My own opening diff against all three main runs.
- C2PA, sha256 and archive checks on every Codex output.
- All 13 headless tests, on a private copy of the slice so that nothing in `real-slice/` changed.
- Perspective, contact shadows, wheel contrast, and column alpha in the atlas and in game.

**Evidence** is in `scratchpad/review-r5-work/`:
- crops: `crops/`;
- tools: `tools/opening5.py`, `tools/c2pa.py`, `tools/crop.py`, `driver/review_probe5.gd`;
- probe outputs: `probe-slice/`, `probe-main/`, `opening-mine.json`;
- tests: `tests/`;
- my regenerated code diff: `regen.diff`.

**Scope:**
- I edited nothing in `real-slice/` except this file. Godot ran only on my copy (`review-r5-work/slice-copy`) and in the render container.
- No window opened on the Mac.
- The repository is clean at baffea4. This review changed no repository file, so there was nothing to commit or push.
- Nothing was played by hand, so this review makes no feel claims.

## Verified (not taken from the report)

- **The package is regenerated from the final build.**
  - The slice's code last changed at 19:52 (`bypass_handle.gd`) and its art at 19:00.
  - Every slice capture folder in `raw5/slice/` is dated 19:54-20:17, after that change. Main was re-captured 19:18-20:17.
  - The pairs, sheet, opening diff, checks, perf tables and `slice-code.diff` are dated 20:15-20:18. The sheet is labelled fix round 4 and shows this build.
  - The installed atlas and both plates are md5-identical to `layers/v5/game/` and to the import cache's source md5s.
  - `slice-code.diff` matches my regenerated diff line for line; only the `diff` command header differs. It covers every changed file, including `main.tscn`, `room_depth.gd` and `seal_leaf.gd` from earlier rounds.
- **My captures reproduce theirs.**
  - My slice s1 and main s1 are each **pixel-identical** (0 px) to `raw5/*/A-720/s1-door-end-rest.png`.
  - My s5 and s7 differ only where things move: the old bay's light shaft flicker, the beacon pulse and, in main, the dust.
- **The render numbers reproduce exactly** (300 uncapped frames per state, 1280x720, in the container):

  | State | Draw calls p50 (max), main -> slice | Texture MB | Video MB | Emitting particle nodes | Full-screen translucent world sprites |
  |---|---|---|---|---|---|
  | s1 | 72 (72) -> **54 (54)** | 71.97 -> 73.87 | 78.35 -> 80.24 | 2 -> 0 | Haze 0.75 + MidPlate -> Haze 0.62 + MidPlate |
  | s5 | 71 (75) -> **54 (58)** | 76.66 -> 73.87 | 83.03 -> 80.24 | 2 -> 0 | same |
  | s7 | 71 (75) -> **54 (58)** | 76.66 -> 73.87 | 83.03 -> 80.24 | 2 -> 0 | same |

  - Canvas-layer quads: main has Grade, IntroAlarm and IntroFade (the last two at alpha 0); the slice has Grade only.
  - Frame times here are software GL on a shared machine, so they mean nothing.
  - Small mismatch: `perf-table.md` gives s5 "71 (max 71) -> 54 (max 54)", but my run and SLICE.md's own s7 row show the same +4 transient (75 and 58). It is harmless, but the table should say so.
- **Rule 5 holds** (`opening-mine.json`, my own tool):
  - Left of world x 540 in o0-o8, every differing blob is at most 25 px across (37 in o5, the two overlapping main motes round 4 found). Every one is darker in the slice: it is main's dust, and the slice has none.
  - Two apparent outliers are main differing from itself, not the slice:
    - In o2, main's `O-720-repeat` differs from its other two runs by 74 px.
    - In o7, main's `O-720` differs from the other two by a 265 x 23 px strip at the top.
    - The slice matches the two main runs that agree.
  - **The top-right boxes** (screen x 960-1280, y 0-240):
    - o4, o5 and o6: 0 px differ.
    - o0 and o1: only 5-6 mote-sized blobs, at most 13 px, all darker in the slice.
  - **Right of world x 540:** o4-o6 are identical, and in o0-o3 that span is off-screen. o7 and o8 differ only inside the slice span (screen x 972 and beyond).
  - The slice's two opening runs are identical to each other (0 px).
- **Must 1 from round 4 is closed.**
  - In the atlas's column region over world y 330-446, the only non-opaque pixels between each row's first and last opaque pixel are the 78 under the live lens sprite (world x 806-809.5, y 342-347).
  - In game, over the column's screen box (x 974-1023, y 306-514), s6 and s7 differ from s5 by **0 px**. WOLF's head and the engineer's arm no longer show through.
- **Must 2 from round 4 is closed.** The shut lens is red in s1 and s3, amber while the curtain moves (s2, s4) and green when open (s5-s7). It matches the approved concept's red lamp on the frame.
- **Provenance and C2PA are complete.**
  - All nine Codex outputs in `codex/*/out/` carry a `caBX` chunk with a c2pa JUMBF manifest.
  - All nine are sha256-identical to their recorded hashes and to the originals in `~/.codex/generated_images/`.
  - All seven sessions are recorded in `provenance.txt` and archived (0 live, 1 archived each).
  - No new Codex image or session is dated after round 4, which matches "no new sessions".
- **Headless tests:** 13 of 13 pass on my copy (`tests/`), after two imports. The `m0_scene_test` checks for the column and the plate pass.
- **Perspective checks out.** I fitted the hood's lower edge (slope 0.231) and the bottom bar's top edge (0.391) in s1. They meet at screen (-440, -20), against the design's VP2 at (-410, -3). The slats converge between them, and the stencils follow the hood.
- **Contact shadows are darkest at the contact line** (s1, luma straight down from the plinth):
  - relay: 16 at the contact row, rising to about 33 at 8-12 world px out;
  - safe point: 13 at the contact row, against about 38.
  - Both stand on bolted plinths with a brush-strip cable entry.
- **The bypass wheel reads as a handwheel.** It is 0.47-0.53 m across at 1.0 m. Its rim measures p50 82 / p90 120 against about 20 on the backplate and wall. It hangs on a backplate, with a gearbox and a chain guard up to the operator.

## Must fix before Nathanial sees it

### 1. The lamp conduit on the near column starts in mid-air

The 20 mm conduit that feeds the status lamp and the push-button station runs up the column's end face. It stops at about world y 270 (720p screen x 1002, y 198) with a plain cap: no box, no elbow, no entry into the wall.

The camera's wall plate sits on the jamb edge at the same height, about 0.28 m to the left and round the corner. Nothing joins the two.

`design/portal5/spec.json` names this part `lamp_conduit_up` with the job "from the camera's box". So the render breaks its own design, and REAL-LOOK item 3 ("every pipe, cable and conduit ends somewhere real") fails.

It is a hairline at 1x on 720p. At 1080p it is a clear light line starting from nothing on a dark column, and Nathanial judges from screenshots.

- **Crops:** `review-r5-work/crops/s1p-camera-4x.png` (plain), `s1p-camera-4x-stretch.png` and `s1-colconduit-6x.png`.
- **Fix:** in `design/tools/portal5.py`, give `lamp_conduit_up` a real top end. Either of these works:
  - **(a)** a 90-degree elbow at world y about 270 that runs left across the jamb's 160 mm approach face, in one strap, into the camera's wall plate. This is the spec's intent.
  - **(b)** a small cast pull box (LB fitting) at its top, with the run going on up the end face into the header.
- Then re-run `cleanup5.py` (paint it with the conduit's existing steel) and `install5.py`.
- Re-capture s1, s5 and s7 at 720p and in phone shape, re-run the opening diff (the plates should not change), and add an `m0_scene_test` or fix-check that the conduit's top touches a box or plate.

## Should fix, or put to Nathanial (none of these blocks his first look)

1. **DESIGN.md lists parts the build does not have.** "Parts" (line 99) gives the mid patch a "relay feed: two 25 mm rigid conduits from the ceiling rack to the relay's roof". The installed `corridor-mid.png` has only the station contact shadows, and no conduit reaches the relay's roof in game. Grounding still passes through the plinth's brush-strip cable entry. Either draw the feed or correct the line.
2. **The tank is lit from a fixture you never see.** Its left third reads 50-66 and its right two-thirds 10-15. The light comes from high-bay A, which the cross-wall hides in every gameplay frame. The visible high-bay B hangs over the tank's right half and lights only its crest. That is physically defensible (B is behind the tank), but checklist item 2 asks for a visible source. Optionally add a faint rim from B on the right shoulder. I do not count it as an AI tell.
3. **A pale strip under the camera housing.** It reads as if lit from below, but the wall pack below it faces down. It is invisible at 1x; drop it when the column is next painted.
4. **The lockdown beacon is a flat code-drawn red rectangle** with a flat pink rim, which reads as a UI chip at 3x. It is live, and main's code draws it the same way. It now hangs under a real back box, which makes the contrast plainer. Changing the drawing also changes the old bay's beacon, which shows in the opening frames. So it is Nathanial's call, or for a later room pass that keeps the opening identical.
5. **The crank pose** (round 4's should 1): the glove rests on the rim at about 8 o'clock, but the arm hangs, so s3 reads as standing by a valve. It needs new Look 2 character art: Nathanial's call, stated in the hand-off and not done.
6. **REAL-LOOK section 8 contradicts itself on safety colours.** It allows "one yellow element and one red element per view", but its own corridor list asks for both the striped bottom bar and the yellow floor line. Put this to Nathanial with the three reds already listed (two beacons and the seal lamp).

## Report accuracy

- The SLICE.md claims I checked hold: capture times, numbers, the opening, the column, the lamp colours, the plate position (world x 635.5-699.5, leader at x 694) and the Codex sessions.
- `perf-table.md` s5: say max 75 -> 58, as in my probe and in SLICE.md's s7 row.
- The SLICE.md and DESIGN.md parts lists: correct the relay feed (should 1).
- SLICE.md "Contact shadows ... relay 0.72, safe point 0.53" uses a different reference row from round 4's 0.44/0.43 and my 0.48/0.34. All of them agree the line is darkest at the contact. State which row the 0.72 comes from.

## Direction, point by point

| Direction | Result |
|---|---|
| A wall across the corridor that the walkway passes through, not a door facing the camera in the back wall | **Pass.** A cast cross-wall turned 17 degrees, the walk line crossing the curtain at x 752. It matches the approved concept's portal. |
| The cross-wall spans the floor depth; no corridor floor on the far side except through the opening | **Pass** with the cutaway convention (Nathanial's call): the column foot, then the 0.15 m stub along VP2 to the frame edge. The wet floor lies only on the corridor side, the plant slab beyond. |
| Far column and header behind the actors | **Pass** (s2, s4, s5, s6). |
| Near column in front of the actors, solid, slim | **Pass.** 0 px see-through with WOLF and the engineer behind it. Slim: the engineer at the safe point stands clear. WOLF is occluded, not ghosted. |
| The rolling steel door fills the opening and rises into the header | **Pass** (s1 shut, s4 at 0.53 with the bar's stripes, s5 open with the tucked bar). |
| Machinery room only as background, at actor values, with its own pool and matched saturation | **Pass.** Dim (about 34) with a pool under high-bay B. As in the approved concept ("a small glimpse around structural frame"), it also shows right of the column, where the safe point keeps its gameplay position. Note: the tank's light comes from a hidden fixture (should 2). |
| MANUAL BYPASS wall-mounted at 1.0-1.1 m, wheel readable, hand on the rim while cranking | **Partial.** Mounting, height, size and rim contrast pass, and the plate now sits over the hub with a leader. The pose is idle (should 5, Nathanial's call). |
| Left of x 540 and the opening identical apart from dust; fix the top-right of o0, o1, o4-o6 | **Pass** (re-measured above). |
| Lossless where mottling showed; draw calls in budget; atlas small textures; real footprint shadows | **Pass:** lossless atlas, p50 54-60, real footprint shadows. Still over budget, and stated: s3's transient 63, overdraw about 3.5, 7 additive items, 73.9 MB of textures. |
| Remove every AI tell the reviews list | **Pass except must 1.** |

## AI-tell checklist (REAL-LOOK section 3, on the in-game captures)

| # | Item | Result |
|---|---|---|
| 1 | Vanishing lines | **Pass.** The hood, bar, slats, pour joint and stub run to VP2. My hood and bar fit meets at (-440, -20) against (-410, -3). |
| 2 | One light logic | **Pass, with a note.** The pendant pools on the new bay, and the wall pack lights the hood and the wall under it. High-bay B lights the tank's crest. The tank's lit flank faces hidden high-bay A (should 2). There is a nit under the camera (should 3). |
| 3 | Every part has a job | **Fail (small):** the lamp conduit starts from nothing (must 1). Everything else ends somewhere real: three conduits into one penetration plate, the junction box to the wall pack and the operator, the chain guard to the operator, the beacon box to the tray, and the vertical line in the plant room is a form joint. |
| 4 | Nothing floats | **Pass.** The plinths have contact shadows (16/33 and 13/38). The wheel is on a backplate, the camera on a wall plate, and the beacon on a back box. |
| 5 | Scale | **Pass.** The door is 3.05 m and the wheel about 0.5 m at 1.0 m. The slats are at real pitch and the lens is 8 px. `DOOR 4B-07` is 8.75 px against section 8's 12 px (flagged for Nathanial). |
| 6 | Doors | **Pass.** The opening is alpha 0, the wall continues round the hole with a full reveal, and the room's own background is behind it. |
| 7 | No text | **Pass.** Only `SECTOR 4B` and `DOOR 4B-07`: typeset, stencil-bridged, from the approved list, still proposals. The other plates are blank. |
| 8 | Detail and values | **Pass.** In greyscale the plant room and cross-wall are quiet, and the stations and actors carry the contrast. No airbrushed finish. |
| 9 | Wear logic | **Pass.** The new bay now takes main's drips under the same pipe run, and the floor line and bar are worn where feet and the landing would wear them. |
| 10 | No repeats | **Pass.** |
| 11 | Rule 5 | **Pass.** |

## Does it read as a near-future military base?

**Partly, unchanged from round 4.** These read as hardened and machine-run:
- the cast cross-wall;
- the numbered gunship-grey door with caught-between stripes;
- `SECTOR 4B`;
- the fixed camera on its arm;
- the padlocked junction box and conduit group into a welded penetration plate;
- the lockable push-button station;
- dim, zoned lighting.

The roller door has no blast mass and the room beyond is a pump and tank hall, so overall it reads as a secured plant room. The options already listed for Nathanial are the right next steps: a steel armour frame round the opening, the inner blast-door vestibule, or `RESTRICTED AREA`. None of them needs a keypad.

**Nothing is taken from the Terminator films:** no names, logos, typefaces, chrome, skulls, red eyes in a skull, model-number styles or franchise wording. No new keypad or card reader was added, and the 1.2 m PIN spot is blank.

## Before and after, as a first-time player

| State | Before (main) | After (slice) |
|---|---|---|
| s1 at rest | A glowing red sci-fi gate standing on the floor, and a gold wheel on a pole | A concrete wall across the way with a grey numbered roller door and a red lamp on its frame, a camera, and a dim plant room past it. Believable, and "the red seal stays shut" now has a red seal lamp. Zoomed in, the lamp's conduit starts from nothing (must 1). |
| s2 relay beat | The engineer by the red gate | The engineer at the door face, the amber lamp lit, and the relay on its plinth with a real shadow. Good. |
| s3 crank | The engineer beside a bright gold wheel | A real wall valve with his glove on the rim, but he stands idle (Nathanial's call). The meter fills on the plate, now tied to the wheel by a leader. |
| s4 opening | The gate folding | The roller door winding up into its hood, stripes on the bar, the room appearing beneath it. Good. |
| s5 open | A gate frame onto a blue tunnel | A true doorway with a reveal, onto a real, dim room, with the green lamp. The best frame. |
| s6 walk through | Walking through the gate | Walking through the doorway; the column now hides him cleanly. |
| s7 safe point | The engineer at the safe point | The engineer at the safe point in the plant room, and WOLF cleanly behind the column. |
| Seam | - | Hidden by the seam column, and the two bays now read as one finish. |

## What I need to pass it

1. Must 1: give the lamp conduit a real top end (an elbow into the camera's wall plate, or a pull box), then re-run cleanup and install.
2. Fresh s1, s5 and s7 at 1280x720 and in phone shape, plus the opening re-diff, which should be unchanged.
3. Should 1 (correct or build the relay feed) and the `perf-table.md` s5 max, both in the same pass.

The other should-fix items can wait for Nathanial's first look, as long as the hand-off lists them, especially the crank pose and the reds and yellows. After must 1, I would show it to him.
