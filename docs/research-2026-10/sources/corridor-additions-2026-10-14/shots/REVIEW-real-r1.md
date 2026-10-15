# Round 7 additions: realism review r1 (adversarial)

2026-10-13. I reviewed the additions in `real-slice/game-add` against REAL-LOOK.md, including the section 3 AI-tell checklist and section 8 (military). I looked at every after-shot at full size (1280x720 and the 2400x1080 phone frames), then at 3x-8x crops, some with stretched contrast. I re-measured rule 5, the budgets and the headless tests on my own private copies.

**What this review rests on:**
- Rendered stills only, all made with `tools/render/render.sh`, plus `godot --headless`.
- No window opened on the Mac. Nothing was played by hand, so I make **no feel claims** (motion, timing, flashing).
- I edited nothing except this file and my own scratch folder, `scratchpad/add7-review-real-r1/` (my copies `game-add` and `game-r6`, my captures in `raw/`, my crops in `crops/` and `crops2/`, my logs in `logs/`).

**Verdict: fix-needed.** I would not show this to Nathanial as real yet. Three of the eight additions fail as a first-time player sees them:
- **(a) The steel blast frame** cannot be seen, and it is drawn over a wall lamp.
- **(c) The inner blast door** reads as a dark partition panel, not a heavier door than the roller.
- **(f) The crank pose** turns the engineer into a different drawing.

The sign (b), the beacons (d), the kept marks (e), the relief valve and jet (g) and the strap (h) are real enough to keep. Rule 5, the budgets and the tests hold.

## Must-fix

### 1. (a) The blast frame is invisible, and it covers the wall lamp

**What I see.** At 1x and in phone shape there is no steel frame. At 4x-8x the "armour plates" over the hood are three panels with the same value and texture as the concrete. You can only find them by a row of 1-px bright bolt specks and two faint seams. The far-jamb strip is the same.

**Measured** (my luma on `raw7/{r6,add}/A-720/s1-door-end-rest-clean.png`):
- **Head-plate zone** (screen x 830-975, y 213-240): mean 41.3 in round 6, **35.7** with the additions. The "steel" is darker than the concrete it replaced.
- **Far jamb:** p90 35.8 -> 33.0.

**It also breaks the light logic.** The plates are drawn **over the small wall lamp under the sign**:
- the lamp's lit lens drops from p90 132.7 / max 243.7 to **p90 55.9 / max 148.8**;
- the lamp's light pool on the wall stays as bright as before.

So the lamp looks half off while it still lights the wall, and a plate bolted flat to the wall sits in front of a fitting mounted on that wall. Neither can happen. In my own phone-shape capture the whole "frame" is a dotted line under a dimmed grey lamp bar (`crops2/phone-s1-s5-doorend-1x.png`). Other crops: `crops2/lamp-plates-r6-add-8x.png`, `crops/s1-headplate-lamp-6x.png`, `crops/s1-doorframe-4x.png`, `crops/s1-farjamb-6x.png`.

**How the real thing is built.** A blast door's frame is structural steel, anchored into the reinforced-concrete wall so that it carries the blast load into the structure ([S1], [S2]). Shielded doors are steel with metal thresholds ([M11] in REAL-LOOK). From the room you see a steel liner lining the head and the jambs, a different material from the concrete, with plates, welds and anchor heads.

**Fix:**
- Put the lamp back in front: draw it after the plates, or stop the plates at least 2 px below its backplate. The lamp's lens pixels must match round 6.
- Make the frame steel at 1x:
  - **Shape:** a continuous liner 0.25-0.30 m wide (10-12 world px) around the head and the visible jamb.
  - **Paint and value:** 36118 Gunship Gray, lifted to about luma 45-55 under this light (concrete is about 35, the roller 21, the engineer's jacket 43).
  - **Thickness:** a 1-px lit arris on the top edge facing the lamp, and a 1-px shadow under each plate's lower edge, to show 25-50 mm plate.
- Bolts:
  - anchor heads at about 0.3 m pitch (12 world px), dark with one highlight each, not bright specks;
  - plate joints every 1.2-1.5 m at most.
- Judge it at 1x and in phone shape, not only at 6x.

### 2. (c) The inner blast door does not read as a blast door

**What works.** The motion makes sense to a person (`crops/leaf-seq-add-4x.png`, `crops/c-inner-leaf-s4-3x.png`, `-s4b-`, `-s5-`):
- a second door behind the shutter slides back along the cross-wall into a pocket at the far jamb;
- it waits until the roller is 40 % up and is driven by the seal's own open value;
- it parks behind the walk line (test: foot at world y 429.6 against 440), and nothing blocks the way when it is open;
- the floor rail across the threshold explains how it moves.

**What a first-time player sees.** The leaf itself is a flat, near-black slab.
- **Value:** luma 22-26 in s4 (grid in my notes). The roller's slats are 11-21 and the jacket 43.
- **Detail:** two vertical seams and nothing else. It shows no edge thickness except the striped band, and no seal, carriage, wheels, welds or bolts.
- **Bottom edge:** at 8x it is a hard black stair-stepped line. The mesh is drawn without antialiasing (`crops2/leaf-bottom-s4-8x.png`).
- **Read:** it looks like a thin dark partition, so it does not read as "clearly heavier than the roller".

**How the real thing is built:**
- Sliding blast doors are reinforced steel leaves with steel skins, in an engineered frame and restraint system, running on heavy tracks or trolleys and locked shut ([S1]).
- Their perimeter is sealed with rubber-impregnated canvas belting or spring-bronze seals ([S3]).
- Heavy sliding shielding doors overlap the opening on all sides and roll on rails ([S4]).
- REAL-LOOK section 8: Titan II leaves were 3-ton concrete-and-steel ([M2]); the Minuteman capsule door weighs 8 tons ([M3], [M4]).

**Fix (no change to timing, collision or the opening value):**
1. **Thickness:** a leading edge of 0.30-0.45 m (it is 0.24 m now), with a 1-2 px lit arris on its near top corner.
2. **Seals:** a dark rubber seal strip, about 2 px, down the leading edge and along the foot.
3. **Carriage:** two bogie housings at the leaf's foot sitting on the rail, about 0.3 m tall, so you can see what it rolls on.
4. **Plates:** horizontal plate seams about every 1 m, with weld lines or one bolt row each, and locking-bolt receivers on the leading edge.
5. **Value:** lift the face to about luma 30-34, so its plate detail reads against the roller and stays under the actors.
6. **Bottom edge:** replace the hard aliased foot line with a 1-px feathered contact shadow from the atlas.

**A note, not a fix.** By `blast_leaf.gd`'s own camera, the corridor's back wall at the cross-wall is about a = 2.5 m, and the 3.65 m leaf parks between a = 1.46 m and a = 5.1 m. Its pocket therefore runs about 2.6 m into the structure behind the corridor's back wall. That is buildable and never seen. A player sees "it slides into the wall" and accepts it.

### 3. (f) The crank pose is a different person, and the far hand floats

**What I see.** When cranking starts, the engineer turns from the broad 3/4 sprite into a slimmer, strict-profile figure:
- lighter grey trousers;
- a different face and hair, with a cyan rim light on the hair that the usual sprite never has.

It is visible at 1x in the laptop frame and in phone shape (`crops/phone-crank-1x.png`, `crops2/crank-4up-5x.png`, `crops/f-crank-A-3x.png`, `crops/f-crank-B-3x.png`).

**The hands:**
- The near glove is on the rim: 9 o'clock in B, 8 o'clock in A. The test measures it at 0.87 world px or less off the rim line in every frame, which I confirmed in 11 runs.
- The far glove is an open flat hand held in the air above the wheel, against the dark gearbox. At 1x it reads as a raised hand, not a grip or a brace.
- The torso stays upright with no lean, so it reads as touching the wheel rather than heaving on a stiff valve.

**The feet.** They do not slide between A and B. On the switch from the usual sprite, the stance narrows: the back boot moves about 4 world px and the front toe about 2 px (measured on my 5x crop). That is a small pop on top of the style change.

**Fix:**
- Draw the A and B crank frames from the same sprite the rest of the game uses: the same proportions, trouser value, hair and lighting. Or hold the crank pose back until the approved idle, walk and jog frames land together.
- Put both hands on the rim, for example near hand at 9 o'clock and far hand at 12-1 o'clock, and lean the torso 5-10 degrees into the wheel.
- Keep both boots on the usual sprite's foot positions.

Until then I would keep round 6's standing pose.

## Should-fix

4. **Test stability.** `m0_scene_test` failed once in my 12 runs on the additions copy: "letting go keeps the turns made; the alarm keeps going". This was my first run, sampling A 69 / B 29 frames, while render jobs ran alongside. It then passed 11 times in a row; the round 6 copy passed 8 of 8.
   - **Likely cause:** an inherited race in `main.gd` (lines 1061-1065 here; the same `elif` is at main 917 and round 6 1005). If a hold tick lands on the frame USE is released, `held_ticks > 0` takes the `if` branch, `bypass_was_holding` then goes false, and the "The handle holds..." line is never set.
   - **Fix:** set the released line whenever holding ends with fewer than 8 ticks, even on a frame that also ticked, so the check cannot flake. This is a code fix, not art.

## Additions that pass

**(b) RESTRICTED AREA sign: pass.**
- The text is exactly `RESTRICTED AREA`, from the approved list, typeset in the bundled Roboto. The image tool painted no lettering.
- It is legible at 1x and in phone shape, on a plate with corner bolts.
- It follows the face's perspective: slope 0.093, against about 0.108 from `blast_leaf.gd`'s camera, so within 1.5 px over its width.
- Its value is plain paint, not a glow: plate p90 57 against the concrete's 46.

Three points for Nathanial, none blocking:
1. It is a printed plate with solid letters, which is what REAL-LOOK asks for on plates. It is not a stencil with bridges, though he said "stencilled".
2. It hangs over the hood, about 4.5-5 m up, not beside the door at eye level, because the wall beside the door is a 17 px column.
3. Real US restricted-area signs are usually red and white, "WARNING / RESTRICTED AREA / KEEP OUT" ([S5]). Only `RESTRICTED AREA` is approved, so keep it as it is unless he wants red.

**(d) Beacons: pass** (`crops/s1-beacon-left-5x.png`, `crops/s1-beacon-left-stretch-5x.png`, `crops2/beacon-right-s1-r6-add-6x.png`, `crops2/beacon-left-s1-r6-add-6x.png`).
- Each is a real guarded fitting: base, red globe and guard, at about 0.14 m. That is the real scale of a jelly-jar warning light.
- **Right beacon:** it hangs from the underside of the existing back box, which has a conduit up to the ceiling.
- **Left beacon:** it hangs on a conduit pendant with couplings from the ceiling tray. Pendant, ceiling and wall mounts are all standard for these lights ([S6]).
- Nothing hovers, the lenses are still red, and the flat chips with pink rims are gone.
- **Optional:** Nathanial chose "wall mounts". A wall bracket for the left one, or a strap to the pilaster halfway down its 1.5 m stem, would match his word, and the stem would stop reading as a hanging wire at 1x.
- Do not make the lenses bigger to sell the alarm: real scale is right. Use the live colour pulse, which I could not judge from stills.

**(e) SECTOR 4B and DOOR 4B-07: kept, pass.** The seal lamp is still red when shut.

**(g) Relief valve and jet: pass.**
- The glowing disc is gone.
- A brass relief valve with a gooseneck tailpipe sits on the relay's side pipe and reads as a real fitting (`crops/s3-valve-6x.png`, `crops/g-relief-jet-s3-3x.png`).
- The jet (`FxPresets.relief_jet()`) is narrow, faint and directional, and comes from the tailpipe's mouth: 16 streaks, colour alpha 0.18, falling straight down, life 0.36 s, normal blend. At 1x it is a faint line, which is what "faint" asked for.
- **Optional, real practice:** relief discharge is piped downward to a safe point, ends 150-600 mm above the floor, and is never aimed at a work position ([S7], [S8]). This outlet is at about 2.0 m and about 0.6 m from where the engineer stands to crank.
  - If you want it by the book, run the tailpipe down the relay's side, with one clip, to about 0.3-0.5 m above the floor, and put the jet and a small damp patch there.
  - If the danger to the operator is part of the story, keep it as it is.

**(h) Strap: pass.** A 1-2 px saddle strap at about 3.45 m (`crops/s1-strap-8x.png`), invisible at 1x as expected.

## AI-tell checklist (section 3), additions only

| # | Check | Result |
|---|---|---|
| 1 | Vanishing lines | Pass. The sign, bolt row, leaf foot and rail converge with the face's lines. |
| 2 | One light logic | **Fail: the head plates cut the wall lamp while its pool stays (item 1).** Beacon pools and the sign are fine. |
| 3 | Every part has a job | Pass: plates, anchors, rail, parked edge, valve, tailpipe, strap, box and pendant. |
| 4 | Nothing floats | Pass, apart from the crank's far hand held in the air (item 3). |
| 5 | Scale | Pass: globe 0.14 m, valve about 0.4 x 0.26 m with its tailpipe, sign about 1.4 x 0.6 m, letters about 0.25 m. |
| 6 | Doors | Pass. The opening stays clear, the leaf parks in a pocket, and the room behind is round 6's background. |
| 7 | No painted text | Pass. All three marks are typeset; the Codex art has no lettering. |
| 8 | Detail and values | **Fail: the frame plates are valueless, and the leaf is a flat untextured slab (items 1, 2).** |
| 9 | Wear logic | Pass. |
| 10 | No repeats | Pass. The two beacons are the same fitting, as real installations are, on different mounts. |
| 11 | Rule 5 | Pass (below). |

There are no franchise references and no generic sci-fi greebles.

**AI tells I found:**
- the plates in front of the lamp;
- the leaf's flat slab and its aliased foot;
- the crank sprite's different drawing, with its own rim light;
- the evenly spaced bright bolt specks, which read as noise at 1x.

## Re-measured on my own copies

**Copies.** `game-add` and `game-r6` are `diff -rq`-identical to `real-slice/game-add` and `game-slice` (without `.godot`). I imported each twice headless.

### Rule 5: the opening

My own render.sh capture of the additions' route O (`raw/add/O-720`) gives these results (`opening-mine-vs-r6-add.json`, script `tools/opening.py`, threshold 3 levels):

**Against the package's two additions runs:**
- o0-o7 are **0 px** different.
- o8 differs from `O-720` only by the known lamp-flicker noise (269 px, at most 4 levels), and is **0 px** against `O-720-r2`.

**Against round 6 (`raw6/slice/O-720`, `-r2`):**
- Left of world x 540, the only blobs are the two beacon zones (18,600-23,400 px each frame in o0-o6) and the left beacon's conduit stem where it meets the ceiling (15 px in o7 and o8; `crops2/o7-stemtop-r6-add-8x.png`).
- Apart from those, there are at most 24 isolated pixels of at most 4 levels.
- Right of x 540 in o4-o6: **0 px**.

**Against main.** I compared with `raw5/main/O-720` and `-repeat` (`opening-int-add-vs-refs.json`, `opening-mine-vs-mymain.json`), and with a fresh main capture of my own (`raw/main/O-720`). That fresh capture gives the same o0-o7 blob lists as main's `O-720-repeat`. Its o8 differs only by a lamp-flicker band, 24,272 px at the top right, which is absent against `-repeat`. In detail:
- Outside the beacon zones and left of x 540, every blob in o0-o6 is brighter in main. These are main's soft round dust motes, and the largest (550 px in o5) is shown in `crops2/o5-dust-main-add-6x.png`.
- No blob is brighter in the additions except the beacon stem top (15 px) and, in o7, a 4,883 px band of the ceiling lamps' glow at the top edge, at most 13 levels. Main's own `O-720-repeat` and `O-720-r3` differ from its first run in that band by the same amount (4,897 px, max 13), so it is run-to-run lamp-flicker noise in main.

**WOLF's cage is untouched.** In o1 the beacon zone is screen x 636-832, y 0-146, while the cage spans x 65-490, y 210-590 (`raw/add/O-720/o1-standby.png`).

### Every other change belongs to an addition

My diff of the additions against round 6 (`raw/{add,r6}/A-720-perf`, s1-s7) finds only:
- the beacons (about 15,000 px each);
- the sign (x 866-975, y 113-171);
- the head plates (x 837-986, y 209-269);
- the jamb strip (x 837-850);
- the valve (x 691-726, y 341-366);
- the strap (x 998-1008, y 267-275, 6 px);
- the leaf in s4, and the parked edge and rail in s5-s7;
- 21 px of the column piece at s2's subpixel camera.

### Budgets

My render.sh runs at 1280x720 hold 300 frames per state.

| State | Draw calls p50 (max): round 6 -> additions | Additive items | Texture MB | Full-screen translucent layers | Overdraw estimate |
|---|---|---|---|---|---|
| s1 at rest | 54 (54) -> **47 (47)** | 7 -> 7 | 73.87 -> 74.38 | 2 -> 2 | 3.54 -> 3.46 |
| s2 relay beat | 60 -> **54** | 7 -> 7 | 73.87 -> 74.38 | 2 | 3.47 -> 3.39 |
| s4 roller half up | 56 -> **50** | 7 -> 7 | 73.87 -> 74.38 | 2 | 3.49 -> 3.41 |
| s4b leaf sliding | 56 -> **50** | 7 -> 7 | 73.87 -> 74.38 | 2 | 3.46 -> 3.38 |
| s5 open | 54 -> **47** | 7 -> 7 | 73.87 -> 74.38 | 2 | 3.49 -> 3.41 |
| s6 walking through | 54 -> **47** | 7 -> 7 | 73.87 -> 74.38 | 2 | 3.45 -> 3.37 |
| s7 safe point | 54 (58) -> **46 (50)** | 7 -> 7 | 73.87 -> 74.38 | 2 | 3.44 -> 3.36 |
| s3, 300-frame hold (the package's method) | 58 (63) -> **51 (57)** | 7 -> 7 | 73.87 -> 74.38 | 2 | 3.48 -> 3.40 |
| s3 while the crank is turning (my 8-frame hold, jet emitting) | 55 (55) -> **48 (48)** | 7 -> 7 | 73.87 -> 74.38 | 2 | 3.51 -> 3.43 |

- **The s3 row in the package measures the wrong state.** Its driver keeps USE held through a 330-frame hold at `--fixed-fps 60`. The last four ticks take about 90 frames, so most of the "cranking" row is the seal opening and then standing open, and the driver's emitter count reads 0 at the end. I ran a copy of the driver that holds only 8 frames (`driver-crankperf/`, `raw/{add,r6}/B-720-crankperf`). While the crank turns and the jet emits (1 emitter), the additions draw 48 calls, against round 6's 55, with 7 additive items.
- **Fix the driver for later rounds:** pause the hold-use ticks during the perf hold, or measure the crank with a short hold, so the cranking row is a real cranking state.
- **Draw calls** are within round 6's 54 at s1.
- **Additive items** hold at 7.
- **Texture memory** grows by **+0.51 MB**, inside the 2 MB limit.
- **Nodes:** 434 against 433.
- **Particles:** 0 emitting at rest.
- **Inherited, outside this round:** the overdraw estimate (3.4) and the 74 MB resident textures are still over REAL-LOOK's targets of 2.0 and 45 MB.

### Headless tests

- After two imports, all 14 suites pass on my copy: round 6's 13 plus `corridor_additions_test`.
- `m0_scene_test` passed 11 of 12 runs. The one failure is item 4.
- In every passing run the crank check reads 0.87 world px off the rim and 0 usual-sprite frames.

### Provenance

All eight add7 Codex originals named in `add7/provenance.txt` still carry their `caBX` C2PA chunk (21,881 or 23,654 bytes; checked by parsing the PNG chunks).

## Inherited, for Nathanial (not the additions)

- The safe-point room's floor continues to the right of the near column, on the camera side, so a person may ask why not walk round the door. The human review r1 raised this too (its point 7).
- SECTOR 4B is set level, while the face's other lines slope. The expected drop is about 4 px across its width at 720p.
- The open view has three yellows (the parked edge, the roller's bar and the floor line) and the shut view three reds. These are Nathanial's choices, but REAL-LOOK asks for one of each.

## Sources

The REAL-LOOK [M] sources are cited as listed there. The others:
- [S1] International Security Expo, sliding blast door product page (reinforced steel leaves with steel skins, engineered frame and restraint system transferring blast loads into the structure, heavy-duty overhead tracks, locking): https://www.internationalsecurityexpo.com/exhibitor-products/sliding-blast-door
- [S2] UFC 3-340-02 practice as summarised by blast-door suppliers (frames connected to the wall reinforcement and embedded in concrete): https://www.internationalsecurityexpo.com/exhibitor-products/single-blast-door ; SDI-133, Guideline for Specifying Steel Doors & Frames for Blast Resistance: https://steeldoor.org/sdi-133/
- [S3] DTIC AD0688173, blast door study (sliding-door seals of rubber-impregnated canvas belting or spring bronze; 9/16-5/8 in steel plate leaves): https://apps.dtic.mil/sti/pdfs/AD0688173.pdf
- [S4] Radioprotection bunker sliding doors overlapping the opening on all four sides, rolling on rails in a covered trench: https://healthmanagement.org/products/view/hospital-door-laboratory-sliding-automatic-dib-radioprotection
- [S5] Restricted-area sign wording, red and white: https://www.compliancesigns.com/pd/restricted-area-keep-out-title-18-u-s-c-1382-sign-nhe-16114
- [S6] Federal Signal 27XL warning light, pendant, ceiling and wall mounting with an optional dome guard: https://vanmeterinc.com/product/federal-27xl-120-240r-mod-7369936
- [S7] AIChE Process Safety Beacon, March 2006 (relief discharge aimed down at work areas is a hazard): https://www.aiche.org/sites/default/files/cep/20060318.pdf
- [S8] WAC 296-104-320 and similar rules (discharge piped downward to a safe point, independently supported, end 6 in to 2 ft above the floor): https://www.law.cornell.edu/regulations/washington/WAC-296-104-320

The DTIC, healthmanagement and expo pages refused or timed out when fetched. Their points come from the search engine's summaries of those pages, so treat [S1], [S3] and [S4] as leads to confirm, not as checked quotations.
