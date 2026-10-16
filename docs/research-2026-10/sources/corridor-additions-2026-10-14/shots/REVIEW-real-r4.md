# Round 10 additions: realism review r4 (adversarial)

2026-10-14. I reviewed round 10 (fix round 3 of the corridor additions, installed in `real-slice/game-add`) against REAL-LOOK.md, including the section 3 AI-tell checklist and section 8 (military), and against Nathanial's two decisions of 2026-10-14. I judged the cut wall against the cutaway convention, as those decisions ask, not as a wall. I looked at every after-shot at full size (1280x720 and the 1920x1080 phone frames) as a first-time player would. Then I looked at 2x-8x crops, some with stretched contrast and one in greyscale. I re-measured rule 5, the budgets and the headless tests on my own private copies.

**What this review rests on:**
- Rendered stills only, all made with `tools/render/render.sh` (my runs `r4realrev-add-*` and `r4realrev-main-O`, round 8's driver), plus `godot --headless`.
- No window opened on the Mac. Nothing was played by hand, so I make **no feel claims**: motion, the beacon pulse in motion and timing are not judged.
- I edited nothing except this file and my scratch folder `scratchpad/add7-review-real-r4/`:
  - copies `copies/game-add`, `copies/game-add-t` (tests) and `copies/game-main`, each `diff -rq` identical (without `.godot`) to `real-slice/game-add/apps/game` and `real-slice/game-main/apps/game` when made;
  - captures in `raw/`, crops in `crops/`, logs in `logs/`, scripts in `tools/`.
- **The package is fresh.** My captures are byte-identical to the package's `raw10/add` frames:
  - A-720, B-720 and A-phone: every frame;
  - O-720 and O-phone: every frame, apart from 2,878 px at 1 level in O-720 o4;
  - the perf numbers: row for row.
  - My new main O-720 run is byte-identical to `raw8/main/O-720`, so main has not moved.
- **Installed art:** the md5 sums match ADD.md and `add7/provenance.txt` (atlas 16e54f8a…, far plate a2db51a0…, beacons 72efa04f…).

**Verdict: fix-needed.** Every round-3 item that belongs to the additions is closed:
- **The luminaire's dark box is gone.** The column-mean step is 0.62 and 0.71, against a limit of 1.5. The two sides of the conduit are 1.0 apart, against a limit of 2. The pool is a plateau centred on the fitting.
- **The marker is whole at the safe point.**
- **The crank test held** in 8 of 8 runs, 4 of them in parallel with render.sh jobs.

Both of Nathanial's decisions are in and follow their convention. Nothing hovers, no door blocks the way, and rule 5, the budgets, the tests and the provenance all hold.

I would still not show it to him as real, for one reason, and that reason is new in round 10:

1. **The beacon globes stay fully lit while their light on the wall swings about 8x.** Round 10 deepened the light's pulse, from a 0.55 dip to a 0.12 trough, but left the lamp itself steady. At the bottom of each pulse a bright red lamp casts almost no light, and at the top the same lamp lights a big red pool. So the lamp never "goes off". Only a halo around it breathes. Fixing it is a small code change, with no new art and no new draw items.

There is also one should-fix that needs play (the pulse is about 4x slower than a real warning beacon) and three small nits.

## Must-fix

### 1. New in round 10: the lamp stays lit while its light pulses (light logic)

**What I see.** Compare the 16-frame pulse strip (`raw10/add/P-720`, 1/6 s apart) at its trough (p04) and its peak (p13). At the trough, both red globes are as bright as at the peak, but their wall light is nearly gone. At the peak, the same globes have a wide red pool. See `crops/MUST1-beacon-globe-steady-vs-light-6x.png` (round 9 trough and peak, then round 10 trough and peak, left and right lamps) and `crops/beacons-trough-peak-4x.png`.

**Measured** on the package's strip (my render.sh frames are byte-identical, so its strip stands):

| | Light alpha, trough to peak (`pulse.json`) | Light swing | Globe, mean R of its 12 reddest px, trough to peak | Globe swing |
|---|---|---|---|---|
| Left, round 10 | 0.066 to 0.549 | 8.3x | 159 to 193 | 1.21x |
| Right, round 10 | 0.069 to 0.550 | 8.0x | 210 to 231 | 1.10x |
| Left, round 9 | 0.22 to 0.40 | 1.8x | 176 to 187 | 1.06x |

The globe's small swing is only the additive light spilling over its own glass. In code, `RoomDepth._pulse` tweens only the glow's `modulate:a`. The Beacon's `lens` colour is set once in `_settle_beacons` and never pulses.

**Why it matters:**
- **Checklist item 2, one light logic.** The light a lamp casts on a wall is proportional to how bright the lamp is ([S9], inverse-square-cosine). A steady lamp cannot cast a light that fades almost to nothing.
- **How real lamps behave.** In a real flashing or rotating warning lamp the lens itself flashes or sweeps ([S6], [S21]).
- **The previous version hid it.** Round 9's shallow dip (1.8x) kept the mismatch out of sight. Round 10's 8x swing exposes it.
- **It undoes the fix's own aim.** Human r3 asked for the beacons to read as "an alarm going off", and the lamp itself still never changes.
- **How it looks:**
  - in a still, a lit bulb with no spill;
  - in motion, a pulsing halo around a lamp that stays on, which is a stock game-glow look rather than a lamp.

**Fix** (`scripts/room_depth.gd` only; same nodes, same draw items):
- In `_pulse`, tween the matching `Beacon.lens` in the same sequence as the glow, so the two move together:
  - from `warning_color` at the peak to a dimmed lens at the trough;
  - same durations, `TRANS_SINE`/`EASE_IN_OUT` and phase.
- For the trough lens, about `warning_color.darkened(0.6)` fits: unlit red glass of a jelly-jar globe reads dark red.
- Pass the beacon index into `_pulse`, or tween a small array.
- **Scope:** keep it to the corridor's painted beacons, either through a new export such as `beacon_lens_trough` set in `main.tscn` next to `beacon_peak_alpha` and `beacon_trough`, or only when `beacon_atlas` is set. The code-drawn housings in Records and the junction then keep their look.
- **Keep the other states:**
  - lockdown cleared still settles to `SETTLED_LENS_DARKEN`;
  - with reduce motion on, the lamp stays steady at the peak (`_motion_running` false), as today.

**Check:**
- On a new 16-frame strip, the globe's lit glass (mean R over the glass mask, not the halo) at the trough is no more than half its peak. Its frame-to-frame curve runs in phase with the light (Pearson r of at least 0.9 over the 16 frames).
- Draw calls (47 at s1) and additive items (7) are unchanged.
- The settled state and reduce-motion state are unchanged.
- Rule 5 still holds outside the beacon zones.

## Should-fix (needs play; for Nathanial)

### 2. The pulse is about 4x slower than a real warning beacon

- **The game:** `BEACON_PULSE_SECONDS = 1.3` gives one smooth sine cycle every 2.6 s, about 23 per minute.
- **Real beacons:** a red rotating warning beacon makes 80-90 flashes per minute, with a reflector sweeping round the bulb ([S21]: TORK TA47RN5 90 fpm, TA52RN5 80-90 fpm, Federal Signal at 90 rpm).
- **How it reads:** a 2.6 s sine reads as breathing, the rhythm of a UI pulse, while the line says "the alarm keeps wailing".
- **This is a matter of feel:** it can only be judged in motion, and nothing here was played.

**Options for Nathanial:**
- Keep the slow breathe as mood.
- Give the corridor a real beacon rhythm, set per room so the other rooms keep theirs:
  - an export such as `beacon_pulse_seconds`, about 0.33-0.35 s per half cycle;
  - a quick rise and a slower fall (`TRANS_EXPO`, `EASE_OUT`);
  - the globe tied to the light as in must-fix 1;
  - steady under reduce motion;
  - at about 1.4 Hz it stays well under WCAG's three flashes a second.
- Either way, decide it by playing the corridor.

## Nits (not blocking)

3. **The control marker now crosses the near column in s6.**
   - Drawing the marker at z 4 puts it above the column as well as the cut. In s6 (walking through) the right 24 screen px of the line lie over the column's foot and the start of the poché (96 new marker px at x 969-992 against round 9, `crops/s6-marker-column-6x.png`).
   - UI drawn over an occluder is a common convention, and the decision asked only for the marker above the cutaway, so I would leave it unless Nathanial minds.
   - A z swap alone would cut it again at s7. The column sprite carries the poché's first 26 world px (atlas x 962-1015, y 582-608), and the s7 marker overlaps that strip by about 21 screen px. So a fix would move the strip from the column region into the stub region and then put the column above the marker.
4. **ADD.md says only the atlas's stub region changed.** The column region's foot changed too: atlas x 962-1015, y 582-608, 1,292 px. The stub's start inside the column sprite went from round 9's galvanised angle to the poché (`crops/atlas-column-foot-r9-r10-8x.png`). That is correct art, but the note is wrong.
5. **For Nathanial, cutaway refinement (optional).** In drafting convention, only material cut by the section plane is poché, and surfaces seen beyond it are drawn lighter ([S19]). Round 10 fills both the cut top and the corridor-facing face with one poché.
   - That matches his words ("a solid dark section edge") and avoids the knee-wall read.
   - But in greyscale the face (14.3) is nearly the same value as the dark wet floor below it (12.0, measured at x 1000-1150, y 620-700), so the band's lower edge fades out toward the right (`crops/s7-grey-1x.png`). In colour it separates by hue and texture.
   - If the band ever reads to him as a black kerb, the alternative is a poché top only, over a plain concrete face at about 20.

## Round 3's items, checked

### Real r3 MUST 1, the dark box round the luminaire: closed

I measured my 720p s1 and s5 captures with my own script (`tools/lum_r4.py`).

| | Round 9 | Round 10 | Limit |
|---|---|---|---|
| Largest step between adjacent column means, x 655-668, rows 28-50 (s1 / s5) | 3.84 / 3.34 | **0.62 / 0.71** | 1.5 |
| Conduit sides, x 707-711 against 716-720 | 28.0 / 24.2 (3.8 apart) | **27.3 / 26.3 (1.0 apart)** | 2 |

**The pool:** rows 62-95 peak at x 682 with the centroid at 685.9. The wall within 3 levels of the top runs from x 681 to 693, so it is a plateau whose centre is 687, against the fitting's centre at 687.5. The single brightest column is a concrete texture feature on a flat plateau, so the "5.5 px" left in ADD.md is not a light-logic fault. I count it as closed.

**At 4x with stretched contrast,** the rectangle is gone. The wall above the fitting dims evenly. A thin dark line to the right of the conduit is its shadow from the fitting on its left, which is consistent (`crops/lum-r9-r10-4x-and-stretch.png`).

### Real r3 SHOULD 2, the marker cut at the safe point: closed

- In s7 the line is whole above the poché (`crops/s7-door-3x.png`, `crops/phone-s7-poche-left-4x.png`).
- My capture is byte-identical to the package's, whose count is 288 px (round 8: 240, round 9: 136).
- Side effect in s6: nit 3.

### Real r3 SHOULD 3, the flaky crank check: closed

- `m0_scene_test` passed in my 14-suite run and in 7 more runs: 3 one after another, then 4 in parallel while my render.sh jobs loaded the machine.
- Every run: "usual 0 frames (lead-in 0)", A 60-62 and B 34-37 frames, worst grip 0.80 world px off the rim line and 0.81 from the grip point.
- The stricter rule (0 usual frames once cranking starts) did not flake.

### Decision 1, "Show it as a clean cutaway": done, judged as a cutaway

**What it is now:**
- one flat section fill (atlas sRGB 15/17/20, std 1.3-2.1 over 19,920 opaque px);
- a faint top arris visible only with stretched contrast;
- a soft footprint shadow on the wet floor;
- no angles, anchors, ties, joints or damp (`crops/atlas-stub-2x-x5.png`).

**In game:**
- face and top read 13.2 and 13.6 (package, `measure10.json`); my own box on the face reads 14.3;
- the poché's left end butts solidly against the column's foot, with no gap at 8x (`crops/s1-poche-corner-8x-b.png`);
- the edges are clean at 4x in phone shape.

**Against the convention:** dark, solid, without material, with clean edges, cut low so it never hides the room. This is how This War of Mine opens its buildings to show a cross-section ([S20]), and how sections are drawn ([S19]).
- The engineer and the SAFE POINT machine are whole (engineer box 0 px against round 9).
- The marker is drawn above it.
- Its geometry is round 9's: it is the cross-wall carried toward the camera along a receding line that meets the corridor's vanishing point.

**As a first-time player:** it now reads as the cut edge of the room's wall, not as a step with steel edges. Nathanial's knee-wall worry is answered. The one refinement is nit 5.

### Decision 2, "WOLF comes to the doorway": done

In my s7 capture, WOLF's changed pixels span world x 660.0-774.4. That leaves 11 world px to the near column's drawn edge at about 785.6, and ADD.md's reach figure leaves 2 px.
- **In the opening:** his head and forelegs are in it, over the threshold past the yellow travel line, with his front paws level with his hind paws on the floor.
- **Facing the engineer:** about 43 px from nose to body.
- **Clear of the relay:** its housing and relief tailpipe.
- **Fully visible:** `crops/phone-s7-wolf-3x.png` and `crops/s7-door-3x.png`.
- **What he stands in front of:** the MANUAL BYPASS wheel. It is bolted to the back wall behind the walkway, so it is behind him, not under him.
- **The striped leading edge** of the parked inner leaf sits behind his shoulders. At 1x he still reads clearly against it.
- **The line is unchanged.**
- **To a person,** this reads as the companion coming to the door after them, which answers human r3's should-fix.

### Human r3 SHOULD, the beacons as a few red pixels

- The light now swings about 2.7x more: red excess 17.6 and 14.9, against 6.5 and 5.5 in round 9.
- In the phone frames at the bright phase they read as alarm lamps at 1x.
- But see must-fix 1 (the lamp should swing with its light) and should-fix 2 (rhythm).

## Each addition against the real thing

Sources [S1]-[S18] and [M1]-[M17] are those cited in reviews r1-r3 and in REAL-LOOK.md. New sources are [S19]-[S21], listed at the end. My state diffs against round 9 (A-720, B-720) show changes only in these places:
- the poché (screen x 963-1280, y 504-622);
- the two beacons' light (x 133-197 and 682-747, y 99-171);
- the wall round the luminaire (x 630-782, y 32-62);
- WOLF's old and new spots and their floor reflections in s7;
- the marker over the column in s6.

So every addition below is pixel-identical to the reviewed round 9 except where noted.

- **(a) Steel blast frame: pass, unchanged.**
  - The liner band with plate joints and anchor heads over the hood, the far-jamb strip and the band on the near column's approach face read as a four-sided steel frame anchored into the concrete opening ([S10], [S2]).
  - Old nit: the thin conduit at x 852 runs behind the band's top-left corner (1 px at 1x).
- **(b) RESTRICTED AREA sign: pass, unchanged.**
  - Exactly `RESTRICTED AREA`, typeset, legible at 1x in both shapes, a light plate with dark letters bolted at the corners and following the face's slope (`crops/phone-s1-top-3x.png`).
  - Wording is as on real restricted-area signs ([S5]).
  - Nathanial's open choices remain: printed rather than stencilled, over the door, black only.
- **(c) Inner blast door: pass, unchanged.**
  - **How it moves:** a thick grey leaf with panel joints, a striped leading edge, bolt receivers and a bogie box rides behind the rising roller and slides back into the pocket at the far jamb. In s5-s7 only its striped edge shows and the opening is clear (`crops/phone-door-s1-s4-s4b-s5-2x.png`).
  - **Against the real thing:** a gasket-sealed, multi-point-locked sliding blast leaf on rails ([S1], [S3], [S4], [S10], [S11]).
  - **Driven by the seal:** in all 8 of my m0 runs, 31-33 sliding frames, "in step true, doorway blocked while in the opening true".
  - **Where the leaf goes:** the pocket would have to run on into the mass behind the corridor's back wall. A hardened site has that mass, so I read it as plausible, as human r3 did.
  - Old nit: the bogie box reads like a vent box.
- **(d) Beacons: the hardware passes, the light fails (must-fix 1).**
  - **Hardware:** a guarded red jelly-jar globe ([S13]). The left one hangs on a strapped conduit drop from the ceiling tray, the right one under a wall back box fed from the ceiling. Bracket, conduit, guard and lens are all there and fixed, at 0.14 m, and nothing hovers (`crops/left-beacon-peak-r9-r10-6x.png`).
  - **The light sprites** fade to 1/255 at their borders, so there is no rectangle edge even at alpha 0.55. The pool on the pilaster stops at its edges, which reads as the pilaster face catching the light.
  - **The seal lamp** is still red when shut.
- **(e) SECTOR 4B and DOOR 4B-07: kept, pass.** SECTOR 4B is still set level against the face's slope (inherited).
- **(f) Crank pose: pass, unchanged.**
  - **Grip:** both gloves are on the left of the rim in A, and the near arm reaches over in B.
  - **Same character:** the same person with the same clothes.
  - **No foot slide:** the boots' outlines are identical between A, B and the hold. Only the texture of the two drawings differs, by at most 19 levels (`crops/crank-boots-A-B-diff-6x.png`).
  - **Grip, headless:** 0.80 world px in every run.
  - The re-cut from the approved walk frames is still to come.
- **(g) Relief port and jet: pass, unchanged.**
  - A clamped tailpipe from a brass relief valve on the relay's side pipe ends about 0.4 m above the floor ([S8]: 6 in to 2 ft).
  - The jet falls from its open end and fans a little at the floor. It is directional, normally blended and has no disc (`crops/crank-A-B-hold-4x.png`).
- **(h) Strap on the lamp conduit: pass, unchanged.**

## AI-tell checklist (section 3) on round 10

| # | Check | Result |
|---|---|---|
| 1 | Vanishing lines | Pass. The poché keeps round 9's lines to the corridor's vanishing point. Nothing else moved. |
| 2 | One light logic | **Fail: must-fix 1** (the globe stays steady while its light swings 8x). The luminaire's box is gone and the pool sits under the fitting. The poché's contact shadow is darkest at its foot. |
| 3 | Every part has a job | Pass. The poché is a drawing convention (the cut), not a part. |
| 4 | Nothing floats | Pass. WOLF stands on the floor in the doorway, and the poché lies on the floor with its footprint shadow. |
| 5 | Scale | Pass, unchanged. |
| 6 | Doors | Pass. The roller and the leaf are clear when open, DOOR 4B-07 is still the only way in, and WOLF stands in the open doorway, not in a moving door's path. |
| 7 | No painted text | Pass. No new text, and no Codex session this round (none live, none new under `~/.codex/sessions`). |
| 8 | Detail and values | Pass. In greyscale (`crops/s7-grey-1x.png`) the actors carry the door end: engineer 41.7 mean (p90 60), WOLF 38.2 (p90 76), safe point 46.9. The plant room through the door is 33.9 and the near column 25.9. The poché is the darkest thing (14.3). |
| 9 | Wear logic | Pass. The poché is a flat cut and the relit wall keeps its old wear. |
| 10 | No repeats | Pass. |
| 11 | Rule 5 | Pass (below). |

There are no franchise references and no generic sci-fi.

## Re-measured on my own copies

### Rule 5: the opening

`tools/opening_r4.py` is independent of the package's script:
- **Screen mapping:** from each frame's camera and zoom.
- **Noise:** main's run-to-run noise is left out pixel by pixel.
- **Beacon zones:** placed round every changed red cluster in the add frame or main's lens, in the upper quarter of the frame. Red that is unchanged, such as the purge screen and the cage lamps, is not zoned.
- **Dust:** a blob counts as dust only if main is brighter on at least 90% of it and it is no larger than 30x30 px at 1280 wide.

Results: `logs/opening-r4-720.json`, `logs/opening-r4-phone.json`. Maps (pink and orange over main's frame): `crops/opening-r4-720/`, `crops/opening-r4-phone/`.

**720p, against my fresh main run and the four older main runs:**
- **Left of world x 540, outside the beacon zones:** only main's dust, 7-14 blobs per frame, every one brighter in main. The one blob over 30 px is in o5 (37x22 px at x 515, y 526). It is two of main's soft motes merged (`crops/o5-blob-main-r10-6x.png`), the same blob review r3 found in phone shape.
- **WOLF's cage box** (world x 27-205, y 292-451): 0-111 px, in at most 2 blobs, all brighter in main. That is dust.
- **Right of x 540:** o0-o6 are 0 px.

**Against round 9:**
- **Outside the beacon zones:** 0 px in every frame.
- **Right of x 540:** o0-o6 are 0 px. o7 and o8 differ by 3,579 and 872 px: the luminaire wall and the right beacon, which sits right of x 540 there.

**Phone shape** (1920x1080 game image, against `raw8/main/O-phone`, whose 720p sibling is byte-identical to my new main run):
- the same picture: dust only, 7-15 blobs, all brighter in main;
- the o5 merged blob is 52x34 px;
- the cage is 0-253 px of dust;
- against round 9, 0 px outside the zones.

### Budgets (my render.sh perf runs, 1280x720, 300 frames per held state)

| State | Draw calls p50 (max) | Additive items | Texture MB | Video MB | Full-screen translucent world layers | Emitters on | Nodes |
|---|---|---|---|---|---|---|---|
| s1 at rest | 47 (47) | 7 | 74.70 | 81.07 | 2 | 0 | 436 |
| s2 relay beat | 54 (54) | 7 | 74.70 | 81.08 | 2 | 0 | 436 |
| s3 cranking | 48 (48) | 7 | 74.70 | 81.07 | 2 | 1 (the jet) | 436 |
| s4 roller half up | 50 (50) | 7 | 74.70 | 81.08 | 2 | 0 | 436 |
| s4b leaf sliding | 50 (50) | 7 | 74.70 | 81.07 | 2 | 0 | 436 |
| s5 open | 47 (47) | 7 | 74.70 | 81.07 | 2 | 0 | 436 |
| s6 walking through | 47 (47) | 7 | 74.70 | 81.07 | 2 | 0 | 436 |
| s7 safe point | 46 (50) | 7 | 74.70 | 81.07 | 2 | 0 | 436 |

- **Against the limits:**
  - **Draw calls:** 47 at s1, against round 6's 54. Pass.
  - **Additive items:** 7, the same as round 6. Pass.
  - **Texture memory:** +0.83 MB on round 6, inside the 2 MB limit. Pass.
  - **Matches the package:** these equal its `perf-table.md` row for row.
- **Inherited:**
  - overdraw (about 3.4) and texture memory are still over REAL-LOOK's 2.0 and 45 MB;
  - the round-6 haze (0.62) is still one of the two full-screen translucent layers.
- **CPU times:** not re-measured. Frame times in the container mean nothing.

### Headless tests

Run on `copies/game-add-t` after two headless imports. The first import shows the usual fresh-copy errors (16 lines) and the second is clean.
- **Full run:** 14 of 14 suites pass (`logs/tests/`), with no `ERROR:`, `SCRIPT ERROR` or leak lines.
- **`m0_scene_test`:** 8 of 8 runs pass (`logs/m0-repeat/`; figures under should-fix 3 above).

### Provenance

- No Codex session was used this round, and `add7/provenance.txt` records that.
- No live session under `~/.codex/sessions` belongs to this job. The two from 2026-10-13 and the recently touched older ones all run in another repository.
- The installed files' md5 sums match provenance.
- Round 9's `paint-cut9b` detail is no longer in the atlas: the stub region is a flat fill.

## Inherited, for Nathanial (not this round's defects)

- COOLANT FAULT stays up through "Safe point saved" (fixed on main by PR #63; check after the port).
- The shutter's slats sit nearly level while the hood and bottom bar follow the slope.
- SECTOR 4B is set level.
- When open, the roller's striped bottom bar shows under the right end of the hood.
- Three yellows when open and three reds when shut.
- Overdraw and texture memory are over budget.
- The Records and junction beacons are still drawn in code.
- The bogie box reads as a vent box.
- The RESTRICTED AREA plate choices.
- The crank re-cut from the approved walk frames.

## Sources

New in this review:
- [S19] Studio Matrx, *What is a section drawing* (poché: the cut material is filled solid; things beyond the cut are drawn lighter as seen lines; search summary): https://www.studiomatrx.org/students/drawing-fundamentals/what-is-a-section-drawing
- [S20] 80.lv, *This War of Mine: a game about civilians in war* (buildings cut away to show a cross-section of the people inside; search summary): https://80.lv/articles/this-war-of-mine-a-game-about-civilians-in-war
- [S21] TORK TA47RN5 rotating beacon, red, 90 flashes per minute; TA52RN5 compact rotating beacon, 80-90 fpm; Federal Signal rotating warning light at 90 rpm (search summaries): https://www.nsiindustries.com/product/rotating-beacon-red-100w-117v/ and https://nsiindustries.com/product/tork-ta52rn5-compact-rotating-beacon-red-25w-117vac
