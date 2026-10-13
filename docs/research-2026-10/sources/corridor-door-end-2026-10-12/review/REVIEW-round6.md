# Review, round 6: the corridor's door end (independent, adversarial)

**Verdict: pass.** Fix round 5 closes the one must-fix from round 5: the status lamp's conduit now has a real top end. I found no new AI tell, and nothing changed outside the areas the fix names. I would show this piece to Nathanial as real.

Two small items are left, and neither blocks his first look:
- **A nit:** the long vertical lamp conduit has no strap.
- **One new question for him:** the coolant-hiss puff in s3 reads as a glowing disc. It is shared runtime FX and identical on main.

Both are listed below, with the waiting-list items.

**What I reviewed:**
- Every after-shot in `raw6/slice/`: A-720, A-phone, B-720, B-phone, O-720 and O-720-r2.
- Each one at full size and in 3-6x crops, plain and contrast-stretched.
- Every after-shot diffed against round 5's after-shots in `raw5/slice/`. Both sets were made with render.sh.

**What I ran myself:**
- My own opening diff against all three main runs.
- My own render.sh probe of s1, s5 and s7 (job name `review-r6-slice`).
- C2PA, sha256 and archive checks on every Codex output.
- All 13 headless tests, on a private copy of the slice.
- Checks that the package was regenerated after the last change: file times, md5s and a regenerated code diff.

**Evidence** is in `scratchpad/review-r6-work/`:
- crops: `crops/`;
- tools: `tools/diff56.py`, `blobs.py`, `opening6.py`, `pair.py`, `crop.py`, `c2pa.py` and `tests.sh`;
- the probe driver: `driver/review_probe6.gd`;
- outputs: `probe-slice/`, `opening-mine6.json`, `tests/` and `regen.diff`.

**Scope:**
- I edited nothing in `real-slice/` except this file. Godot ran headless on my copy (`review-r6-work/slice-copy`) and in the render container.
- No window opened on the Mac.
- The repository is clean at baffea4, so there was nothing to commit or push.
- Nothing was played by hand, so I make no claims about how it feels to play.

## 1. Round-5 review items, closed or not

| Item | Status | Evidence (mine) |
|---|---|---|
| **Must 1: the lamp conduit starts in mid-air** | **Closed** | See below. |
| Should 1: DESIGN.md lists a relay feed that isn't drawn | **Closed** | DESIGN.md's v6 table (line 14) and its Parts mid-patch row (line 116) now say no relay feed is drawn, and that the relay is fed from the floor through its plinth's brush-strip entry. A note (line 107) marks the Parts table as the round-0 list. SLICE.md lists no relay feed. The installed mid plate is md5-identical to v5's, so nothing changed in game. |
| Should 2: the tank is lit from a hidden fixture | **Done (optional item)** | A faint rim now sits on the tank's right edge from high-bay B. It is at most 4 source px wide, and the layer diff shows only 1,070 far-plate px changed, all along that edge. At 1x it is barely visible, and that is right for a back-rim. In game it shows as +1 to +3 luma along screen x 1195-1212 (720p). The lit left third is unchanged, and that is stated as open. Crops: `s5-tank-r5-vs-r6-3x.png` and `s5p-tank-r5-vs-r6-3x-stretch.png`. |
| Should 3: a pale strip under the camera | **Closed** | The pale patch above the arm and the pale edge under the housing are both gone, at 6x and in stretch (`s1-conduit-r5-vs-r6-6x-stretch.png` and `s1p-camera-conduit-r5-vs-r6-5x-stretch.png`). The cause was a ghost of an earlier camera in the wall layer, as the report says. The atlas changes only in the wall region (1,375 px) and the column region (154 px). |
| Should 4: the flat beacon drawing | Waiting on Nathanial | Unchanged, as it should be. |
| Should 5: the crank pose | Waiting on Nathanial | Unchanged. |
| Should 6: REAL-LOOK section 8's one-yellow, one-red rule | Waiting on Nathanial | Unchanged. |
| Report: perf-table s5 max, and the contact-shadow reference | **Closed** | `perf-table.md` has a "max (all runs)" column. It reads s5 75 -> 58 and s7 75 -> 58, which matches round 5's probe. SLICE.md now defines both shadow references (the band, and the contact row 0.53 / 0.45). |

### Must 1 in detail

- **How the conduit runs now (3-6x crops):** the 20 mm conduit leaves the push-button box and runs up the column's end face through the lamp box. A 90-degree elbow at 4.31 m turns it toward the corner. It crosses the face at 4.41 m in one saddle strap, wraps the arris and enters the side of the camera's wall plate.
- **It holds in every frame:** s1, s5 and s7 at 720p and in phone shape.
- **Measured in game:** the run reads 31.6 luma against 22.0 on the concrete just above it (720p, rows at world y 269.5), and 33.4 against 22.2 in phone shape. That matches the vertical conduit's own 32-33, so the run and the vertical read as one piece of steel. In round 5's frames the same pixels read 22.1 against 22.0: bare concrete.
- **Report vs my numbers:** SLICE.md's 35.8 uses a different row band. Its conclusion holds.
- **My render.sh probe** (my own build of the slice) draws the same new pixels: the conduit and camera region matches the fixer's s1 capture, and differs from round 5's probe there.
- **Headless:** the new `m0_scene_test` check samples this path and passes on my copy.
- **Crops:** `s1-conduit-r5-vs-r6-6x(-stretch).png`, `s5-conduit-r5-vs-r6-6x.png`, `s7-conduit-r5-vs-r6-6x.png`, `s1p/s5p/s7p-conduit-r5-vs-r6-*.png`, `s1p-camera-conduit-r5-vs-r6-5x(-stretch).png`, `s1-door-column-3x(-stretch).png` and `s1p-column-conduit-3x-stretch.png`.

## 2. Round-to-round diff: raw6 after-shots against raw5 after-shots

I diffed every after-shot against the round-5 file with the same name. I counted a pixel only if a channel changed by more than 2, then merged the changed pixels into regions (`tools/diff56.py`, `tools/blobs.py`).

| Frames | What changed | Where (720p screen) | Named by the fix? |
|---|---|---|---|
| s1-s7, A and B, 720p and phone | The tank's right edge | x 1195-1212, y 125-451 (phone x 1796-1815, y 190-677). +1.5 to +3.4 mean, max 17 | Yes (should 2) |
| s1-s7, A and B, 720p and phone | The conduit elbow and run, and the camera ghost painted out | x 928-1013, y 185-220 (phone x 1395-1516, y 280-328). Max 24-27 | Yes (must 1, should 3) |
| s2 (both shapes) | Only the same two regions, with slightly different pixel counts because of the live surge effect | - | Yes |
| o0-o7, both opening runs | **Nothing** (0 px) | - | - |
| o8, `O-720` only | A 282 x 98 px region at the top (x 676-994, y 0-105), 3.6 darker | The old bay lamp's flicker glow | Run-to-run noise: `O-720-r2` o8 is byte-identical to round 5's, and the flicker wait is random (`room_depth.gd` `flicker_steps`) |

Nothing else changed in any frame. The stations, door, floor, plant room, seam column, bypass and actors are pixel-identical to round 5.

## 3. AI-tell checklist (REAL-LOOK section 3, on every after-shot)

I ran every item on the full frames and in 3x crops. The crops are `s5-beyond-3x(-stretch)`, `s1-relay-base-3x`, `s1-safepoint-base-3x`, `s1-seam-3x`, `s1-ceiling-3x`, `s1-bypass-4x`, `s1-floor-door-3x`, `s5-right-edge-3x`, `s3-crank-main-vs-slice-3x` and `o7-right-main-vs-slice-2x`.

| # | Item | Result |
|---|---|---|
| 1 | Vanishing lines | **Pass.** The geometry is unchanged from round 5, which fitted the vanishing point. The new run is horizontal on the end face, which faces the camera, so it is correct for that elevation. |
| 2 | One light logic | **Pass.** The new rim on the tank faces the visible high-bay B. The camera's lit-from-below strip is gone. The tank's left third is still lit by hidden high-bay A, which is stated as open. That is defensible, and not an AI tell. |
| 3 | Every part has a job, and every pipe ends somewhere | **Pass.** The lamp circuit runs camera wall plate -> run -> elbow -> lamp box -> push-button box. Every end is on a box or plate, and the plate is a wall box. The other runs are unchanged from round 5 and end somewhere real. **Nit:** the 1.54 m vertical between the lamp box (2.77 m) and the elbow (4.31 m) has no strap, and REAL-LOOK section 2 asks for a strap within 0.9 m of a box (see section 6). |
| 4 | Nothing floats | **Pass.** The plinths and contact shadows are unchanged. The wheel is on a backplate and gearbox, the camera on a wall plate, the beacon on its back box, and the plant-room motor on its base. |
| 5 | Scale | **Pass.** Unchanged: the door is 3.05 m, the wheel about 0.5 m at 1.0 m, and the conduit 20 mm. |
| 6 | Doors | **Pass.** Unchanged: the opening is alpha 0, there is a full reveal, and the plant room is background. |
| 7 | No text | **Pass.** Only `SECTOR 4B` and `DOOR 4B-07` (waiting list). No lettering was added. |
| 8 | Detail and values | **Pass.** The new run is matched to the vertical conduit's value (about 32), and its run across the end face sits at that value too, not as a highlight. |
| 9 | Wear logic | **Pass.** Unchanged. |
| 10 | No repeats | **Pass.** |
| 11 | Rule 5 | **Pass** (section 4). |

There is nothing from the Terminator films, and no new keypad or card reader. The 1.2 m spot is still blank.

## 4. Rule 5, package, provenance and tests (my own runs)

### Opening against main (`opening-mine6.json`)

I diffed both slice runs (`raw6/slice/O-720` and `O-720-r2`) against each of main's three runs (`raw5/main/O-720`, `O-720-repeat` and `O-720-r3`), with the cut at world x 540 computed from each frame's camera. That makes 54 comparisons.

- **Left of world x 540:**
  - o0-o6: every differing blob is at most 25 px across, and none is brighter in the slice. That is main's dust, and the slice has none.
  - o5: one 37 x 23 blob, darker in the slice. It is main's two overlapping motes, as in round 5.
  - The exceptions are main differing from itself: o2 against `O-720-repeat`, and o7 against main's `O-720` (a 265 x 23 strip). The slice matches main's other runs there, with at most 17 px blobs and none brighter.
  - o8: slice run 1 carries the flicker region above. Slice run 2 shows only 17 px dust blobs.
- **Top-right box (screen x 960-1280, y 0-240):**
  - o0: 6 mote-sized blobs (at most 13 px), all darker in the slice.
  - o1: 5 mote-sized blobs, all darker in the slice.
  - o4-o6: **0 px**.
- **Right of world x 540:** o4-o6 show **0 px**, and in o0-o3 that span is off-screen. o7 and o8 differ only inside the slice's own span (screen x 972 and beyond).

### The package is regenerated from the final build

- **Last changes in `game-slice` (outside `.godot`):**
  - art 20:53:47 (atlas, far plate, and the mid plate, whose content is unchanged);
  - `.import` files 20:55;
  - `bypass_handle.gd` 19:52 and `main.gd` 19:01;
  - the capture driver 21:05 and `m0_scene_test.gd` 21:06. Neither affects the captures.
- **Captures:** every slice capture in `raw6/` is dated 21:02-21:38. `pairs/` and `sheet.png` are from 21:38, and `slice-code.diff` from 21:42.
- **Pairs and sheet:** `pairs/s1|s3|s5-*-720.png` contain this round's captures, not round 5's (I found the raw6 conduit patch at the right half, offset (1288, 40)). The sheet is labelled fix round 5 and shows this build.
- **md5s:** the installed atlas, far and mid plates are md5-identical to `layers/v6/game/` and to the import cache's `source_md5`.
- **Code diff:** my regenerated `diff -ru` (`regen.diff`, 892 lines) matches `slice-code.diff` line for line, apart from the `diff` command lines.
- **Main's captures:** `raw5/main/` was not touched after 20:17, and main's code did not change, so reusing it as "before" is sound.

### My render probe (render.sh, `review-r6-slice`, 300 uncapped frames per state, 1280x720)

| State | Draw calls p50 (max) | Texture MB | Video MB | Emitting particle nodes | Full-screen translucent world sprites |
|---|---|---|---|---|---|
| s1 | 54 (54) | 73.87 | 80.24 | 0 | Haze 0.62 + MidPlate |
| s5 | 54 (54) | 73.87 | 80.24 | 0 | Haze 0.62 + MidPlate |
| s7 | 54 (54) | 73.87 | 80.24 | 0 | Haze 0.62 + MidPlate |

- The only canvas-layer quad is Grade.
- This run had no +4 transient. That is consistent with the report's "in some runs and not others".
- My probe's route timing differed from the fixer's (the engineer stood at 655.5 against 653.8 in s1), so the frames match the fixer's only in static regions. That includes the changed conduit and camera region.

### Codex provenance

- All nine Codex outputs in `codex/*/out/` carry a `caBX` chunk with a c2pa JUMBF manifest.
- Each one's sha256 appears in `provenance.txt` and matches an original in `~/.codex/generated_images/`.
- All seven session ids are archived: 0 live and 1 archived each.
- No new Codex image or session exists, which matches "no new sessions". The fix-round-5 section in `provenance.txt` lists every derived file.

### Headless tests

13 of 13 pass on my private copy after two imports (`review-r6-work/tests/`), including the new conduit check in `m0_scene_test`.

### The near column stays solid

Over the column's box (720p x 974-1023, y 306-514), s6 matches s5 with 0 px changed. In s7, 7 px change, all at x 1023, the column's right edge: 4 of them are the engineer's cyan floor marker, outside the column's filled span. This agrees with the fixer's 0 of 10,254.

## 5. Report accuracy

- The SLICE.md claims I checked hold:
  - the changed regions;
  - o0-o7 byte-identical to round 5, and o8 as flicker noise;
  - draw calls, texture and video memory;
  - Codex provenance;
  - the code diff;
  - the column.
- Two small things a reader could misread:
  - **The sheet's opening-diff panel** draws the pink diff over **main's** frame, so it shows main's gold wheel at o7's right edge. The slice's o7 shows the new wall valve (`crops/o7-right-main-vs-slice-2x.png`). Add "(over main's frame)" to that label, so Nathanial does not think the gold wheel is still there.
  - **The in-game run luma:** SLICE.md gives 35.8 against 22.4. I read 31.6 against 22.0 one row band over. Both say the run is there. This is not an error.

## 6. For Nathanial, or optional

**New, for Nathanial to decide separately:**
1. **The coolant-hiss puff while cranking (s3) reads as a glowing pale-cyan disc,** not as steam. It has no visible source and is the brightest thing in the frame (core luma about 204). It is the `BypassHandle/CoolantHiss` particles from the shared `FxPresets.steam()`, and main draws the same. Rule 4 lets steam stay live, and the preset is shared FX, so this is his call, not a defect of this slice.
   - **Suggested change:** a narrow, faint plume from a visible relief port on the relay's side pipe or the bypass gearbox. Fewer, smaller and dimmer particles, with a direction.
   - Crop: `s3-crank-main-vs-slice-3x.png`.

**Optional nit (does not block his look):**

2. **The lamp conduit has no strap on its 1.54 m vertical** (2.77 m to 4.31 m; `portal6/spec.json` `lamp_conduit_top.vertical_h`). REAL-LOOK section 2 says conduit is strapped within 0.9 m of a box.
   - The fix is one saddle strap at about 3.4-3.5 m (world y about 300). Paint it from the existing strap's highlight steel, in `portal6.py`, `cleanup6.py` and `install6.py`.
   - At 1x and in phone shape it would be 1-2 px, which is why I do not hold the verdict for it.
   - The run from the lamp to the push-button box is 0.82 m between two boxes, so it is fine.

**Still waiting on Nathanial (unchanged, and not defects for this verdict):**
- the live beacon's flat drawing;
- the crank pose;
- the three reds and the "red seal" lines;
- `SECTOR 4B` and `DOOR 4B-07`;
- the 3.05 m door height;
- the 17-degree cross-wall;
- the stub cutaway;
- the blank 1.2 m keypad spot;
- the actors' floor reflections;
- the MANUAL BYPASS plate and its leader;
- REAL-LOOK section 8's yellow-and-red rule.

**Already stated as open in the hand-off:**
- the tank's left third lit by hidden high-bay A;
- the budgets: s3 peaks at 63 draw calls, overdraw is about 3.5, there are 7 additive items, and texture memory is 73.9 MB against 45 MB;
- no phone or GPU measurement;
- the manifest update before landing;
- Notion and the Codex board.

## What I need to pass it

Nothing more. Must 1 is closed and verified in every frame. Nothing outside the named areas moved. Rule 5 holds, the package is fresh, provenance is complete, and the tests pass.

Show it to Nathanial with the two items in section 6 and the waiting list. REAL-LOOK asks for a second reviewer's zero before it counts as passed.
