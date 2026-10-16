# Round 8 additions: realism review r2 (adversarial)

2026-10-13. I reviewed round 8 (fix round 1 of the corridor additions, installed in `real-slice/game-add`) against REAL-LOOK.md, including the section 3 AI-tell checklist and section 8 (military). I looked at every after-shot at full size (1280x720 and the 1920x1080 phone frames), then at 2x-8x crops, some with stretched contrast and one in greyscale. I re-measured rule 5, the budgets and the headless tests on my own private copies.

**What this review rests on:**
- Rendered stills only, all made with `tools/render/render.sh` (my runs `r2rev-add`, `r2rev-main`), plus `godot --headless`.
- No window opened on the Mac. Nothing was played by hand, so I make **no feel claims** (motion, pulse, timing).
- I edited nothing except this file and my scratch folder `scratchpad/add7-review-real-r2/`: copies `game-add` and `game-main` (`diff -rq` identical to `real-slice/game-add` and `real-slice/game-main`, without `.godot`), captures in `raw/`, crops in `crops/` and `crops2/`, logs in `logs/`, scripts in `tools/`.

**Verdict: fix-needed.** All eight additions now read as real hardware, and nothing in them hovers, blocks the way or looks generated. I would still not show the door end to Nathanial as real, for two reasons:
1. **Inherited:** the safe-point room can be reached round the near column, so the door looks unnecessary. His newest words were "no missing weird doors" and "think as a human", and the door brief says no corridor floor may continue past the cross-wall except through the opening.
2. **New in round 8:** the shortened luminaire left its wall pool and its floor reflection behind. Both are now about 0.55 m to the right of the fitting.

Rule 5, the budgets and the tests hold.

## Must-fix

### 1. Inherited: the safe point can be reached round the door

**What I see.** In every state and in both shapes, right of the near column, there is a concrete kerb. It runs diagonally from the column's foot (720p s7: x 983, y 523) to the frame's right edge (x 1280, y 637). The corridor's own wet floor continues past the column in front of that kerb, all the way to the frame edge. Above the kerb is the safe-point room's floor, one step up. Its overhead fitting is reflected as a streak on that corridor floor, at x 1185 (`crops2/s7-nearcolumn-kerb-3x.png`, `crops2/s1-floor-br-stretch-2x.png`). A person reads this as "step up the kerb, walk round the column", so cranking the door open looks staged.

**History.** Main closed this side with a foreground pipe column and railing in the near strip. Round 6 dropped it (`near_right_edge = false`), and round 8 inherits that (`crops2/s7-camera-side-gap-main-r6-r8-2x.png`, main | round 6 | round 8). Human r1, real r1 and human r2 all raised it.

**Why it counts here.** The door brief says the cross-wall's foot runs across the floor and "nothing of the corridor floor continues past it on the far side except through the opening". It also says every door must make sense to a person, including why it is there.

**Fix:** close the camera side so DOOR 4B-07 is the only way in. The safe point's plinth and its contact shadow must stay visible.
- **Preferred:** carry the cross-wall toward the camera as a cut section along the existing kerb line, from the near column's foot to the frame's bottom-right edge.
  - Draw it as solid cast concrete with a steel angle on the cut arris. Keep its top at about 0.6-0.7 m. At 720p s7 the kerb is at y 556 under the station's left foot (x 1070), and the top must stay below the station's base line at y 503, so it hides nothing of the station.
  - Stop the corridor's wet floor at the wall's face, with a contact shadow along its foot.
  - Remove the corridor-floor streak that reflects the safe-point room's lamp (x 1185).
  - Keep its value at or below the near column's.
- **Alternative:** bring back a near-strip foreground element on the right edge, as main had, placed on the cross-wall line. That could be a pipe chase or a guard rail on the kerb with a reason to be there (a drop or a trench). It must not cover the safe point or the actors.

This needs new art in the near strip (and the floor of the mid plate), built through the REAL-LOOK pipeline.

### 2. New in round 8: the luminaire's wall pool and floor reflection stayed where the old bar was

**What happened.** The far plate's 1.2 m bar became a 0.6 m fitting, and the fitting was moved left to clear PAUSE in o8. The wall pool under it and its reflection streak on the wet floor were not moved.

**Measured** (720p s1 and s5, the door-end camera):

| Item | Round 6 | Round 8 |
|---|---|---|
| Lit diffuser | x 683-767, centre 725 | x 669-706, centre **687.5** |
| Wall pool, y 62-100 | centroid 725-727, peak 715-733 | centroid **729**, peak **731-734** |
| Floor reflection streak, y 560-680 | peak x 725-727 | peak x **725-727** (unchanged) |

So both sit about 40 screen px (about 22 world px, about 0.55 m) right of the new fitting's centre, and 20-28 px beyond its right end. The streak now lies under the conduit and the beacon's back box, not under any lamp (`crops2/luminaire-pool-offset-s5-2x.png`: cyan line = fitting centre, yellow = pool and streak peak; `crops2/luminaire-r6-r8-3x.png`, `crops2/luminaire-r6-r8-stretch-6x.png`).

**Why it matters.** It breaks checklist item 2 (one light logic): the brightest wall and the floor streak have no fitting above them. Light from a fitting just in front of a wall falls off from the point under it, by inverse square with cosine ([S9]). ADD.md also understates the offset: it gives 0.35 m.

**Fix:** move the painted pool on the far plate, and the reflection streak on the floor, about 40 screen px left at the door-end camera, so both peak under the fitting's centre. Do it deterministically, as a shift of the plate's own pixels with an inpaint where they were. The fitting's PAUSE clearance stays as it is. The other way round, moving the fitting back over its old pool, would put it under PAUSE again in o8.

Check with the same column profile: pool and streak peaks within ±5 px of the fitting centre.

## Should-fix and optional (not blocking)

3. **Optional: the crank's frame A at close range.**
   - Both gloves are on the rim, at 8 and 10 o'clock. At 6x, though, both forearms seem to come straight out of the jacket front at belt height, with no near upper arm or elbow drawn along the torso's side (`crops2/phone-crank-AB-6x.png`, left).
   - At 1x, and in frame B, it reads correctly.
   - If the crank is cut again from the approved walk frames, as ADD.md plans, draw the near sleeve from the shoulder to an elbow at the waist in A.
4. **For Nathanial: how faint the coolant spray should be.**
   - Brief (g) asked for a "narrow, faint, directional" plume. The human review asked for more visibility.
   - Measured in my s3 and crank-A frames: the jet's pixels have mean luma 102, p90 146 and max 165, over a background of 55 (392 px, x 713-729, y 470-504). The engineer's jacket reads p90 68.
   - It has a clear source, points down at the floor and is not a disc.
   - Its core is about twice as bright as its surroundings, and brighter than the wet floor right beside the relay (p99 87). It is no brighter than the floor's reflections under the main ceiling lamp (p90 151). So it reads as a pale jet, a little brighter than the light at that spot explains.
   - If he wants it "faint" by the letter, alpha 0.3 -> about 0.2 brings the core to about 100-110.
5. **Doc nits:**
   - ADD.md says the beacon atlas is now 256x160. The installed `corridor-beacons.png` is **256x156** (md5 `5974e955`, which matches provenance). The scene's regions fit it, since their bottom row is 153.
   - ADD.md says the luminaire hangs 0.35 m from its pool. It is about 0.55 m (item 2).

## Each addition against the real thing

### (a) Steel blast frame: pass

**What I see.**
- A continuous painted-steel band runs over the hood, with plate joints, dark anchor heads, a lit top arris and a shadow under each plate.
- A steel strip lines the far jamb, and the near column's approach face carries the band.
- The wall lamp above is whole again, in front of the plates, and lights the band's arris from the right direction (`crops2/headband-r6-r8-5x.png`, `crops2/s1-portal-3x.png`, `crops2/s5-jambs-r6-r8-4x.png`).

**Values and perspective.** In my s1 the band reads mean 40-45 and p90 51-59, against concrete at 23-41 around it. It is plainly steel at 1x and in phone shape. Its edges slope about 0.17 px per px, against about 0.10 for the sign 80 px higher, which is what the face's perspective gives (the screen horizon is at about y -3). I found no AI tells: the joints are regular, the bolts sit on the same pitch per plate, and there is no smearing.

**Against the real thing.** Blast door sets have a four-sided steel frame fitted to the concrete opening and anchored into it ([S10]; [S1], [S2] in r1). The jamb we cannot see, the near reveal, faces away from the camera, so head, far jamb and approach face are all the frame that can show. As the human review says, it reads more as a steel header than as a full frame, but that is honest to the geometry.

### (b) RESTRICTED AREA sign: pass (unchanged from round 7; r1 notes stand)

- The text is exactly `RESTRICTED AREA`, typeset, and legible at 1x and in phone shape. It is bolted at the corners and follows the face's slope.
- It is a printed plate, not a bridged stencil.
- It hangs over the door rather than beside it, and it is black on light only.
- All three are Nathanial's call.

### (c) Inner blast door: pass

**What a person sees.**
- In s4, behind the half-raised roller, there is a grey steel leaf at mean 34.2 (x 915-950, y 400-470). The roller's slats read 16.8 and the jacket 45.6.
- The leaf has weld seams, a bolted bogie housing at its foot, a rubber sweep and a thin feathered contact shadow.
- In s4b the leaf slides back toward the corridor's back wall. Its 0.36 m leading edge faces the camera with yellow-black striping, a seal and locking-bolt receivers.
- In s5-s7 only that striped nose stands in the pocket's mouth at the far jamb, with three receivers, and the opening is clear.

Crops: `crops2/s4-leaf-4x.png`, `s4b-leaf-4x.png`, `s5-door-4x.png`, `s4-leaf-foot-8x.png`, `s4b-nose-8x.png`, `phone-s4b-s7-door-2x.png`.

**Against the real thing.**
- **Thickness and build:** a 0.36 m steel-faced concrete leaf. Hartmann's steel-and-reinforced-concrete blast door uses a 100 or 150 mm concrete plate ([S11]), and Titan II's leaves were 3-ton concrete and steel ([M2]). At 0.36 m the leaf is on the heavy side, which suits a door that must read heavier than the roller.
- **Locking:** multi-point locking with high-tensile bolts at the head and three jamb points is standard on blast door sets ([S10]), so three receivers on the nose is right.
- **Rails, seals, edge marking:** sliding blast and shielding doors run on rails or trolleys, overlap the opening, and are gasket-sealed ([S1], [S3], [S4] in r1; [S11]). Yellow-black on the leading edge is OSHA's caught-between marking ([M9]).
- **Where the leaf goes:** it parks into a pocket in the back wall, behind the walk line. The geometry is consistent: its nose faces +z, so the camera sees it face-on, and the leaf's broad face recedes with the cross-wall.

**Drive and blocking.** `blast_leaf.gd` is driven only by the seal's existing `open` value and starts at 0.4. `m0_scene_test` confirms the doorway is blocked while the leaf is in the opening and clear once it is open (31-33 sliding frames, "in step true").

A nit, not worth a round: the bogie housing reads more as a bolted box than as wheels.

### (d) Beacons: pass

- **Left beacon:** a guarded red globe on a conduit drop from the ceiling tray, held to the pilaster by three straps, with a red pool on the pilaster and wall below.
- **Right beacon:** hangs under its wall back box, which is fed by conduit from the ceiling.
- **Read:** no flat chips or pink rims remain, nothing hovers, and the lenses are red. The seal lamp is red shut, amber opening and green open.
- **Against the real thing:** jelly-jar hazardous-location lights have a glass globe under a guard and come in pendant (3/4 in NPT), ceiling and wall mounts ([S13]; [S6] in r1). The globe stays at its real size, about 0.14 m.
- **Pool:** it now reaches the pipes at 3x-6x stretched (`crops2/beacon-left-r8-stretch-6x.png`, `beacon-right-r8-stretch-6x.png`, `beacon-left-main-r8-6x.png`, `beacon-right-main-r8-6x.png`). At 1x it is faint, but the live pulse was not judged from stills.
- **Box edge:** the left pool's edge follows the pilaster's edges. That reads as the pilaster face catching the light, not as a box, and some red also falls on the wall beside it.

### (e) SECTOR 4B and DOOR 4B-07: kept, pass

SECTOR 4B is still set level against the face's slope. That is inherited, and minor at 1x.

### (f) Crank pose: pass (optional item 3 above)

- **Same drawing:** it is the in-game engineer, with the same face, hair, jacket, trousers and lighting. The legs are the sprite's own pixels.
- **Boots:** they do not move between the usual sprite, A and B (720p and phone: `crops2/s3-crank-AB-5x.png`, `crops2/phone-crank-AB-6x.png`).
- **Pose:** the torso leans into the wheel, with both gloves on the rim, at 8 and 10 o'clock in A and about 9:30 and 11:30 in B.
- **Grip, headless:** in all 8 of my `m0_scene_test` runs, every crank frame has both gloves at most 0.80 world px off the rim line, and 0 frames show the usual sprite (A 60-61 frames, B 35-37).
- **Mechanism:** a handwheel on a gearbox, with a shaft up to the door head, is how manual operation of a rolling door works ([S14]).

### (g) Relief port and discharge: pass (for Nathanial: item 4)

- The brass relief valve's tailpipe is carried down the relay's side in two clamps to an open end low over the floor, with a faint damp patch under it (`crops2/relay-drop-s1-s3-6x.png`, `crops2/s5-relay-right-8x.png`).
- The spray comes from that end and falls to the floor. It is narrow, directional and normal-blended, not a disc, and well away from the engineer's head.
- **Against the real thing:** discharge points down and ends between 6 in and 2 ft above the floor ([S8], quoted from WAC 296-104-320).

### (h) Strap on the lamp conduit: pass

It is still there, and at 1x it is invisible, as expected.

### New this round: luminaire by PAUSE

- **The fitting:** a real 0.6 m fitting on two rods, with no AI tells, and the old bar is cleanly inpainted.
- **PAUSE clearance:** it clears PAUSE in o8 (`crops2/o8-pause-main-r8-3x.png`).
- **The fault:** its light was left behind (must-fix 2).

### New this round: WOLF's waiting spot (not a realism defect)

- WOLF now stands at x 490 in s1 and s5-s7, fully in view and not overlapping any machine.
- Whether he should stay behind while the engineer goes through is a presentation choice for Nathanial. The human review flags the "We made it" line.

## AI-tell checklist (section 3), round-8 changes

| # | Check | Result |
|---|---|---|
| 1 | Vanishing lines | Pass. The band, leaf foot, rail and sign follow the face's perspective (band slope 0.17 against 0.10 for the sign higher up, as expected). |
| 2 | One light logic | **Fail: the luminaire's pool and floor streak are about 0.55 m right of the fitting (must-fix 2).** The band's arris faces the wall lamp, and the beacon pools sit under their globes. |
| 3 | Every part has a job | Pass: liner plates and anchors, leaf seams, bogies, receivers, sweep, rail, straps, clamps, union and tailpipe, fitting rods. |
| 4 | Nothing floats | Pass. Every new part is on the floor, on a rail, or fixed to the wall or ceiling with visible hardware. |
| 5 | Scale | Pass: leaf edge 0.36 m, globe 0.14 m, band 0.30 m showing, fitting 0.6 m, discharge end about 0.4-0.6 m up. |
| 6 | Doors | Leaf and roller pass. **The door end as a whole fails on the way round (must-fix 1).** |
| 7 | No painted text | Pass. No new text, and the Codex art has no lettering. |
| 8 | Detail and values | Pass. Greyscale (`crops2/s4b-grey-doorend-1x.png`): the leaf at 34 sits between the roller and the actors. The band is the brightest static architecture at the door end, but it is small and high. |
| 9 | Wear logic | Pass. The damp patch is under the discharge, the threshold is worn and the plates are calm. |
| 10 | No repeats | Pass. |
| 11 | Rule 5 | Pass (below). |

There are no franchise references and no generic sci-fi (no hex panels, glowing seams or holograms).

## Re-measured on my own copies

### Rule 5: the opening

`tools/opening_r2b.py`, `opening-r2b.json`. My render.sh capture of round 8's route O (`raw/add/O-720`) is byte-identical to the package's `raw8/add/O-720` in o0-o2 and o4-o7. o3 differs by a 2-level lamp-flicker band, and o8 by the known flicker. I compared it against my own fresh main capture (`raw/main/O-720`) and four older main runs (`raw8/main/O-720`, `shots/raw5/main/O-720`, `-repeat`, `-r3`). For each comparison, the noise floor is taken from the other main runs.

**Left of world x 540:**
- In every frame the only large changed blob is one beacon zone, the left beacon: 24,200-26,700 px in o0-o6, 10,300 and 16,600 px in o7 and o8, always brighter in main, where main's glow and red chip were.
- Everything else is main's dust (7-20 small blobs per frame, all brighter in main), or a 2-level flicker band at the top edge in o2 and o3 that also differs between two runs of the same build.
- One exception, which is my own run's fault: my fresh main o7 caught the old bay lamp mid-flicker. It differs from the other four main runs at the top right, so I left it out.

**WOLF's cage** (world x 27-205, y 292-451, mapped per frame):
- Only 1-214 px differ per frame.
- Every blob is 14 px across or less, and all are brighter in main, so they are main's dust motes. None is brighter in round 8.
- The cage and gate are identical.

**Right of world x 540:** 0 px in o0-o6. In o7 and o8, the round's own door end differs (allowed).

**Phone shape** (`raw/{add,main}/O-phone`, 1920x1080 game image; `tools/opening_r2b_phone.py`, `opening-r2b-phone.json`). This is new: the package checked rule 5 at 720p only.
- My round-8 run is byte-identical to the package's `raw8/add/O-phone`, except o6 (10,805 px at 1 level).
- Against my main run and the package's main run, left of world x 540 the only large blob is the left beacon (54,500-60,200 px in o0-o6, 23,300 and 37,100 px in o7 and o8).
- Everything else is main's dust. That includes two soft motes merged into a 58 px blob in o5 (`crops2/o5-phone-blob-main-r8-4x.png`) and one 14 px mote in o6, plus a band of 3 levels or less at the top of o6 (x 1301-1882).
- The cage box shows only small dust blobs, all brighter in main.

**The other frames.** Against main and round 6 (`raw8/{main,r6}/A-720`), the s1-s7 frames left of world x 540 differ only in two places: the left beacon, and WOLF's new waiting spot in s5 and s7. The one exception is a 21 px mote of main's in s5, which is not in round 6.

### Budgets

My render.sh perf runs on my copy (`raw/add/A-720-perf`, `raw/add/B-720-perf`; 1280x720, 300 frames held per state, with the round-8 driver, whose s3 hold keeps cranking). Round 6 and main come from the package's own runs with the same driver (`raw8/{r6,main}/*-720-perf/_run.json`). Draw calls, memory and item counts are deterministic in the container; frame times there mean nothing.

| State | Draw calls p50 (max): main -> round 6 -> round 8 | Additive items | Texture MB | Full-screen translucent world layers | Emitters on |
|---|---|---|---|---|---|
| s1 at rest | 72 -> 54 -> **47 (47)** | 8 -> 7 -> **7** | 71.97 -> 73.87 -> **74.70** | 2 | 0 |
| s2 relay beat | 77 -> 60 -> **54** | 8 -> 7 -> **7** | **74.70** | 2 | 0 |
| s3 cranking (door still shut after the hold) | 73 -> 55 -> **48 (48)** | 9 -> 7 -> **7** | **74.70** | 2 | 1 (the jet) |
| s4 roller half up | 73 -> 56 -> **50** | 8 -> 7 -> **7** | **74.70** | 2 | 0 |
| s4b leaf sliding | 73 -> 56 -> **50** | 8 -> 7 -> **7** | **74.70** | 2 | 0 |
| s5 open | 71 -> 54 -> **47** | 8 -> 7 -> **7** | **74.70** | 2 | 0 |
| s6 walking through | 71 -> 54 -> **47** | 8 -> 7 -> **7** | **74.70** | 2 | 0 |
| s7 safe point | 71 (75) -> 54 (58) -> **46 (50)** | 8 -> 7 -> **7** | **74.70** | 2 | 0 |

- **Draw calls:** 47 at s1 against round 6's 54. Pass.
- **Additive items:** 7, the same as round 6. Pass.
- **Texture memory:** +0.83 MB against round 6, inside the 2 MB limit. Pass.
- **Matches the package:** my numbers equal `perf-table.md` row for row.
- **Inherited, outside this round:** the overdraw estimate (3.37-3.46) and the 74.7 MB resident textures are still over REAL-LOOK's 2.0 and 45 MB targets.

### Headless tests

Run on my copy after two headless imports:
- **Full run:** 14 of 14 suites pass (`logs/tests/`).
- **`m0_scene_test`:** 7 more runs, 7 pass (`logs/tests/m0-repeat-1.log`, `logs/tests2/m0-1..6.log`). My earlier 8-run loop was cut off by a session restart after run 1. The crank grip reads 0.80 world px worst in every run, and the leaf is "in step true" with the doorway "blocked while in the opening true".
- **`corridor_additions_test`:** 2 more runs, both pass.
- **`chapter_scene_test`:** passed once more, with no leak warning.
- **`settings_test`:** prints GDScript backtraces from its own hostile-config checks, but no `ERROR:` line, and it passes.

### Provenance

- **C2PA:** all five round-8 Codex outputs, including the unused `paint-crank8-try1`, carry their `caBX` C2PA chunk (23,654 bytes; I parsed the PNG chunks). Their sha256 values match `add7/provenance.txt`.
- **Archive:** all five sessions are in `~/.codex/archived_sessions`, and 0 are live.
- **Installed files:** the five installed assets' md5 values match the provenance list.
- **Asset register:** `manifest.json` has the corridor-seal-atlas, eng-crank-atlas and corridor-beacons entries.

## Inherited, for Nathanial (not the additions)

- The safe-point gap (must-fix 1).
- SECTOR 4B is set level against the face's slope.
- **Hood and bottom bar:** when open, the roller's striped bottom bar shows only under the right end of the hood (round 6 art). A real bar stays parallel just under the hood.
- **Colour counts:** three yellows when open and three reds when shut.
- **Budgets against REAL-LOOK:** the overdraw estimate (about 3.4) and the resident textures (about 75 MB) are over its 2.0 and 45 MB targets.
- **COOLANT FAULT** stays up after the relay is dealt with (another branch clears it).

## Sources

The REAL-LOOK [M] sources and review r1's [S1]-[S8] are cited as listed there. New in this review:
- [S9] Inverse-square-cosine illuminance and wall luminaire distributions (search summary of US patent 9353922, *Wall wash light fixture and method for lighting a wall*, and similar): https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9353922
- [S10] ARA Manufacture, Securaguard Blast Door Set data sheet (welded steel leaf, "4 point locking system comprising head and three jamb position locking using high tensile locking bolts", "four sided steel frame to suit pre-cast concrete opening"). Downloaded and read: https://manufacture.aragroup.com.au/wp-content/uploads/2022/03/2280-PROD-Design-ARA-Manu-Securaguard-Blast-Door-Set.pdf
- [S11] Hartmann Tresore, HET 01 explosion-protection door ("mixture of high-quality steel and reinforced concrete", reinforced-concrete plate 100 or 150 mm, gear bolt work, gasket seals). Downloaded and read: https://hartmann-tresore.ch/fileadmin/user_upload/tresore/Explosionsschutzt%C3%BCr/HET01.pdf
- [S12] International Security Expo, sliding blast door (reinforced steel leaves, steel skins, engineered frame, heavy-duty tracks; search summary only, the page was not fetched): https://www.internationalsecurityexpo.com/exhibitor-products/sliding-blast-door
- [S13] Jelly-jar hazardous-location lights (glass globe, guard, 3/4 in NPT pendant, ceiling or wall mount; red lens available; search summary): https://www.mcmaster.com/products/ceiling-and-wall-lights/hazardous-location-protection-type~explosion-proof-1/ and https://www.ledlightingsupply.com/industrial-lighting/led-explosion-proof/20-watt-explosion-proof-jelly-jar-light-2800-lumens-class-1-div-2-pendant-mount
- [S14] Rolling steel door operators with a manual chain hoist or hand crank and gear reduction (search summary): https://dealer.amarr.com/us/en/commercial-doors/explore-commercial-products/commercial-operators/opera-ogh and https://patents.google.com/patent/US4721146
- [S8] confirmed by fetching: WAC 296-104-320, where discharge points down and ends "not exceed 2 feet (610 mm) and not less than 6 inches (152 mm) above the ground": https://www.law.cornell.edu/regulations/washington/WAC-296-104-320
