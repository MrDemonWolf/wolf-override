# Round 11 additions: realism review r5 (adversarial)

2026-10-14. I reviewed round 11 (fix round 4 of the corridor additions, installed in `real-slice/game-add`) against REAL-LOOK.md: the section 3 AI-tell checklist, section 8 (military) and Nathanial's two decisions of 2026-10-14. I judged the cut wall against the cutaway convention, as those decisions ask.

**How I looked:**
- Every after-shot at full size: 1280x720 with and without the HUD, and the 1920x1080 phone frames. I looked at them as a first-time player would.
- Then 2x-8x crops, some with stretched contrast and one in greyscale, and the atlas itself.
- I re-measured rule 5, the budgets, the beacon strip and the headless tests on my own private copies.

**What this review rests on:**
- Rendered stills only, all made with `tools/render/render.sh` (my runs `r5realrev-*`, round 8's driver and round 11's pulse driver, unchanged), plus `godot --headless`.
- No window opened on the Mac. Nothing was played by hand, so I make **no feel claims**: motion, the flash rhythm in motion and timing are not judged.
- I edited nothing except this file and my scratch folder `scratchpad/add7-review-real-r5/`:
  - copies `copies/game-add`, `copies/game-add-t` (tests) and `copies/game-main`. Without `.godot`, they are `diff -rq` identical to `real-slice/game-add/apps/game` and to `git archive 76d3a50 apps/game`, checked at 08:31 today;
  - captures in `raw/`, crops in `crops/` and `crops2/`, logs in `logs/`, scripts in `tools/` and `tools2/`.
  - An earlier attempt of this review (05:48-06:01) was cut off before it wrote anything. I reused its copies and its route-A capture after checking both, and re-ran everything else.
- **The package is fresh.** My captures are byte-identical to the package's `raw11/add` frames:
  - A-720, B-720, B-phone and O-720: every frame;
  - O-phone: every frame except o4, which differs by 13,108 px at 2 levels or less (software-render noise);
  - the perf numbers: row for row.
  - My beacon strip (P-720) differs from the package's by about 235 px a frame. That is phase noise, and my measurements on it match the package's.
  - My two new main O-720 runs agree with each other (0 px, apart from 4,922 px of dust in o5) and with the older main runs.
- **Installed art matches provenance:** atlas md5 `14fd7bed…`, identical to `fix4/door/game/`; far plate `a2db51a0…`, unchanged.

## Verdict: pass

I would show round 11 to Nathanial as real.

**Round 4's open items:**
- **The must-fix is closed.** The beacon globe now dims and brightens with its own light.
- **The rhythm should-fix is done.** The lamps flash at 88 a minute, like a real rotating beacon. Whether that feels right can only be judged in play.
- **The new jamb plates** read as anchored steel armour and follow the face's perspective.

**What still holds:**
- Nothing hovers.
- No door blocks the way.
- WOLF's cage and the opening are unchanged apart from main's dust.
- The budgets, the 14 suites and the provenance all hold.

**What is left:**
- **One should-fix, not visible in game.** The atlas carries faint lettering painted by the image tool. It is hidden behind the hood and should be cleaned before the port to main.
- **One nit.**
- **The inherited list,** which is Nathanial's call.

## Round 4's items, checked

### Real r4 MUST 1, the lamp stayed lit while its light faded: closed

I measured my own 60-frame strip (1/30 s apart, `logs/pulse-r5-mine.json`) with my own script, `tools/pulse_r5.py`.

| | Globe, 12 reddest px, trough to peak | Trough / peak | Lit-glass mask, trough / peak | Pearson r, globe against the wall light under it | Flashes a minute |
|---|---|---|---|---|---|
| Left lamp | 70.3 to 192.8 | **0.365** | 0.233 | **0.994** (glass mask 1.000) | **90.0** |
| Right lamp | 92.8 to 234.4 | **0.396** | 0.255 | **0.984** (glass mask 1.000) | **87.8** |

- **Against the limits:** r4 asked for at most half and r of at least 0.9. Both lamps pass.
- **The light's alpha** swings 0.066 to 0.52-0.54. The glow alpha and the lens red correlate at 1.000.
- **Headless** (`room_lights_test`, my run): lens red 0.40 to 1.00, r 1.000, 85.6 flashes a minute.

**In the stills** (`crops/beacons-peak-to-trough-6x.png`): at the trough each jelly-jar globe reads as unlit dark-red glass behind its guard. At the peak the globe and its pool on the wall come up together. On the right lamp, the pipe below even catches a red highlight. That is the light logic a real lamp has ([S9]).

**Code** (`fix4-code.diff`):
- `_pulse` tweens the glow alpha and `Beacon.lens` in one sequence, with the same durations and eases.
- It is scoped by `beacon_lens_trough` (0.6 in the corridor only). Records and the junction keep a steady lens, which the test checks.
- The cleared-route state is unchanged.

### Real r4 SHOULD 2, the 2.6 s breathe: done (needs play)

- **What it does now:** a 0.17 s rise and a 0.51 s fall, one flash every 0.68 s. The second lamp runs 0.29 s behind the first.
- **Against real beacons:** that is 88 a minute, inside the 80-90 of real red rotating beacons ([S21]). At about 1.5 a second it is well under WCAG's three flashes a second.
- **Reduced Motion** holds both lamps lit and steady, and turning it off brings the flash back. The test checks both.
- **The flash shape:** the globe dims evenly rather than sweeping. A 12 px globe cannot show a sweep, so this reads as a flashing beacon, which is also a real product.
- **For Nathanial:** whether 1.5 a second feels urgent or nervous needs play. `beacon_flash = false` brings back the slow breathe, and the lens fix stays either way.

### Real r4 NIT 3 (marker over the column in s6): left as is

That was my suggestion, and it is unchanged.

### Real r4 NIT 4, the ADD.md note: closed

I diffed round 9's and round 10's installed atlases. The column region's foot changed by 1,292 px at atlas x 962-1014, y 582-607, exactly as the corrected note now says.

### Real r4 NIT 5, the cutaway refinement: left for Nathanial

It is unchanged, and it is his call.

## The new change: the steel blast frame's jamb plates

I diffed round 10's and round 11's atlases myself.
- **The pixels:** 12,206 changed, 0 alpha changed, in two places only: the far plate (atlas x 725-754, y 254-562, 7,425 px) and the near plate (x 963-980, y 282-585, 4,781 px).
- **In game:** against round 10, the frames change only at the beacons, the far plate (screen x 831-857) and the near plate (x 985-1000), in s1 and s5-s7.

**Against the real thing:**
- **The spec:** a blast door's "frames and anchors must be capable of transferring blast reactions to the adjacent supporting structure". Steel-to-concrete connections are anchor bolts with ASTM F844/F436 washers (UFGS 08 39 53, sections 1.2, 2.1.4 and 3.1.2 [S22]; [D1]).
- **Similar products:** pre-cast openings get a "four sided steel frame" ([S10]). Wall arrises get galvanised edge-protection steel ([S16]).
- **What round 11 shows:**
  - a painted 36118 plate on the far column's face, with M30 heads on square plate washers at 300 mm pitch;
  - a bare galvanised plate on the near column, carrying the status lamp, the push-button box and their conduit;
  - with the riveted head plate, a steel frame on all sides of the opening.
- **Function:** every bolt anchors a plate. The far plate's inner row sits under the roller's guide, which bolts through it.
  - On the near plate, bolts are missing only where the push-button box covers the row (2 bolts) and next to a joint (1 bolt, an edge-distance gap).
  - Nothing is decorative (`crops2/farplate-s5-r10-r11-6x.png`, `crops2/nearplate-s1-r10-r11-6x.png`).
- **Perspective:** the far plate sits on the cross-wall's receding face, so its joints must slope toward that face's vanishing point. In the atlas they slope 12.3° (upper joint) and 14.0° (lower).
  - The face's own line family predicts 12.9° and 16.3° at those heights. The family is SECTOR 4B, the sign's edges, the head band and the floor line, all of which fit one vanishing point.
  - The lower joint is 2° shallow, which is about 1 px across the plate at 720p and not visible. Pass.
- **At 1x:** a lighter bolted band on each side of the shutter. It is calm, matte and no brighter than the actors where they pass (s6 and s7). The near column stays solid in front of them.
- **Greyscale** (`crops/doorend-grey-s1-s6-s7-2x.png`): the background stays quiet and the actors carry the contrast.

## Each addition against the real thing

Sources [S1]-[S21] are those cited in reviews r1-r4, [M1]-[M17] are in REAL-LOOK.md, and [D1] is in `add7/door/NOTES.md`. [S22] is new.

- **(a) Steel blast frame: pass.**
  - Head plate, far and near jamb plates, anchored as above ([S22], [D1], [S10]).
  - The chain guard runs from the bypass gearbox up into the hood's end box, so the handwheel visibly drives the door ([S14]; `crops2/bypass-chain-s1-4x.png`).
  - The thin vertical line under the MANUAL BYPASS tag is the nameplate's UI leader line, not art.
- **(b) RESTRICTED AREA sign: pass, unchanged.**
  - Exactly `RESTRICTED AREA`, typeset, and legible at 1x in both shapes ([S5]).
  - Its slope matches the face's line family, so it is in the wall's perspective. Only the short SECTOR 4B looks level.
- **(c) Inner blast door: pass, unchanged.**
  - **Thickness and build:** a 0.36 m leaf with panel joints, a hazard-striped closing edge with bolt receivers, and a bogie box at its foot.
  - **Perspective:** drawn in the face's perspective, with joints and bottom edge sloping like the roller's bottom bar (`crops2/leaf-s4-s4b-5x.png`).
  - **Where the leaf goes:** it slides into the far-side pocket. Open, only its striped closing edge shows, behind the walk line. The opening is clear, and actors draw in front of it in s5-s7.
  - **Against real doors:** a horizontal sliding blast door on trolleys, gasket-sealed, with jamb latching points ([S22] sections 2.2.1 and 2.2.11; [S3], [S10]).
  - **Driven by the seal:** my 6 extra `m0_scene_test` runs give 31-33 sliding frames, "in step true, doorway blocked while in the opening true".
- **(d) Beacons: pass** (above).
  - Hardware is unchanged. The left lamp hangs on a strapped conduit drop and the right one under a bolted back box, each with a guard and a red jelly-jar globe ([S13], [S6]).
  - The seal lamp is red when shut, amber while opening and green when open.
- **(e) SECTOR 4B and DOOR 4B-07: kept, pass.**
- **(f) Crank pose: pass, unchanged.**
  - **Grip:** both gloves are on the rim in A and B. In B the near arm reaches up over the wheel (`crops/pk-crank-A-B-hold-4x.png`).
  - **Same character, no foot slide:** the same engineer, with the boots in the same place.
  - **Headless:** worst grip 0.80 world px off the rim line in all 6 of my runs, 0 usual frames.
  - **Scale:** the wheel is about 0.45 m with its centre at about 1.0 m.
- **(g) Relief port and jet: pass, unchanged.**
  - A clamped tailpipe from the brass relief valve on the relay's side pipe ends about 0.4 m above the floor ([S8]).
  - The jet is narrow, faint and falls from its open end to the floor. There is no disc. Main and round 6 had a pale glowing disc there (`crops/g-relief-spray-s3-3x.png`).
- **(h) Strap on the lamp conduit: pass, unchanged.**

## AI-tell checklist (section 3) on round 11

| # | Check | Result |
|---|---|---|
| 1 | Vanishing lines | Pass. The new plate joints converge with the face's line family, and the inner leaf is drawn in the same perspective. The inherited roller-slat item is below. |
| 2 | One light logic | Pass. The globes now dim and brighten with their light (r 0.98-1.00), and the plates take the light the round-10 art carries. |
| 3 | Every part has a job | Pass. Each plate and bolt anchors the frame, and the chain guard drives the door. |
| 4 | Nothing floats | Pass. Every machine stands on a base or hangs on visible hardware. That covers the lamps, camera, sign, wall light, wheel, tailpipe, both beacons, the station plinths, and the safe room's tank and rail. |
| 5 | Scale | Pass. Bolt pitch is 21.6 screen px (300 mm), the globes are 0.14 m and the wheel is 0.45 m. |
| 6 | Doors | Pass. Open pixels are alpha 0, both leaves have somewhere to go, and DOOR 4B-07 is the only way in. |
| 7 | No painted text | **Pass in game; should-fix 1 in the atlas** (hidden image-tool lettering under the hood). Round 11's one Codex session added no text that is used. |
| 8 | Detail and values | Pass. The actors carry the contrast, and the plates are calm. |
| 9 | Wear logic | Pass. The worn arris is on the near plate's corner, where carts and shoulders pass. |
| 10 | No repeats | Pass. |
| 11 | Rule 5 | Pass (below). |

There are no franchise references and no generic sci-fi.

## Should-fix (not visible in game; do before the port to main)

### 1. Image-tool lettering hidden in the atlas behind the hood

**What is there.** Inside the corridor atlas's **wall** region, in the blast-frame head plate, sits a faint, full "DOOR 4B-07" (atlas x about 735-830, y about 300-335; `crops2/atlas-ghost-r11-5x.png`). It runs letter for letter under the typeset stencil on the hood.

**Where it came from:**
- It is not in round 6's atlas.
- It came in with round 7's head-plate liner, painted in Codex sessions 01a13367… and 01a134ac…, and round 8 strengthened it. The high-pass detail in that box is 2.2 in round 6, 4.3 in round 7 and 5.9 in rounds 8-11 (`crops2/atlas-hidden-lettering-r6-r7-r8-r11-4x.png`).
- Round 7's prompt said "NO lettering". The edit target showed the hood's text over the plate, and the image tool painted it into the plate.
- The edit targets still carry that lettering. Round 11's Codex output changed it too: it erased DOOR 4B-07 outside its paint map. `cleanup11.py` correctly threw that away.

**Why it matters, even though no player sees it:**
- I mapped its 749 detail pixels into world space against the hood's alpha. 720 lie under fully opaque hood pixels and 5 under its anti-aliased edge. The other 24 are an edge line and a highlight at the hood's border, not letter strokes.
- The hood never moves, so the lettering is covered in every state. The in-game frames show the stencil once and clean.
- But Nathanial's rule is that text is "never painted by the image tool". This atlas will be committed to a public repository, and the asset register says the text is typeset. It would also show the moment the hood is ever re-cut, resized or moved.

**Fix:**
- In the installed atlas, repaint atlas x 728-840, y 296-338 (wall region only), inside the head plate's mask, with the plate's own clean paint. Take it from the plate just above the letters (y 285-295) with the same joints and bolt row, or regenerate that strip from the round-7 design's flat plate value plus the luma-only grain used elsewhere.
- Keep alpha unchanged.
- Note it in the asset register and in `add7/provenance.txt`.

**Check:**
- In-game frames s1-s7 and o0-o8 are byte-identical to round 11 (0 px).
- High-pass std in that box is 3 or less.
- No letter shapes show in a stretched 5x crop.

## Nits (not blocking)

2. **Blank the hood text in Codex's edit targets.** The input scripts (such as `codex_inputs11.py`) composite the hood over the wall for Codex's edit target. They should blank the hood's typeset text in that composite, so no future paint round can copy or alter it.

## Re-measured on my own copies

### Rule 5: the opening

I used `tools/opening_r5.py`, written independently of the package's script. The phone copy is `tools2/opening_r5b.py`, which takes its size from the saved image.
- **Screen mapping:** from each frame's camera and zoom.
- **Noise:** main's run-to-run noise is left out pixel by pixel.
- **Beacon zones:** the two beacons' world boxes.
- **Dust:** a blob counts as dust if main is brighter on at least 90% of it and it is no larger than 30x30 px at 1280 wide.

**720p, against six main runs** (my two new runs, `raw8/main/O-720`, review r4's main run, and `raw5/main/O-720` and its repeat; `logs/opening-r5-720.json`):
- **Left of world x 540, outside the beacon zones:** 814-1,597 px a frame, all main's dust. Every blob is brighter in main.
  - The only blobs over 30 px are o5's 37x23 at screen (515, 525) and o6's 24x40 at (519, 501). Both are main's soft motes, merged; the slice has none there (`crops2/o6-o5-blob-add-main-6x.png`).
  - The extra blobs against `raw5/main/O-720*` alone (o2 and o7, at the top edge) are differences between main's own runs.
- **WOLF's cage box:** 0-119 px a frame, and in every one main is the brighter. That is main's dust; the cage itself is identical (o3 side by side, add and main).
- **Right of x 540:** o0-o6 are 0 px. In o7 and o8, right of x 540 is the door end, the round-6 piece that replaced main's door. It differs from main by design, and the package shows it differs from round 10 only by the right beacon's flash and the far plate's edge.

**Phone shape** (against `raw8/main/O-phone`; `logs/opening-r5-phone.json`):
- the same picture: dust only;
- the o5 merged mote is 53x35 px, brighter in main;
- the cage is 0-265 px of main's dust;
- right of x 540, o0-o6 are 0 px.

### Budgets (my render.sh perf runs, 1280x720, 300 frames per held state)

| State | Draw calls p50 (max) | Additive items | Texture MB | Video MB | Full-screen translucent world layers | Emitters on | Nodes |
|---|---|---|---|---|---|---|---|
| s1 at rest | 47 (47) | 7 | 74.70 | 81.07 | 2 (Haze 0.62, MidPlate) | 0 | 436 |
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
  - **Texture memory:** +0.83 MB on round 6's 73.87, inside 2 MB. Pass.
- **Matches the package:** these equal its `perf-table.md` round-11 column row for row.
- **Still over REAL-LOOK's budget (inherited):** overdraw (about 3.4 against 2.0) and texture memory (74.7 MB against 45 MB).
- **CPU:** frame times in the container mean nothing, and I did not re-measure CPU.

### Headless tests

Run on `copies/game-add-t` after two headless imports, both exit 0 with no `ERROR:` lines.
- **Full run:** 14 of 14 suites pass (`logs/tests/`), with no `ERROR:`, `SCRIPT ERROR` or leak lines. The 05:48 run on the same copy also passed 14 of 14 (`logs/tests-0548/`).
- **`m0_scene_test`:** 6 more runs pass, 3 one after another and 3 in parallel while my render.sh jobs ran (`logs/m0-repeat/`). Every run: usual 0 frames (lead-in 0), worst grip 0.80 world px, blast leaf 31-33 frames in step.

### Provenance

- **The session:** round 11's one Codex session, `01a139d9-1863-7681-8bc9-ab42ca7191c0`, is archived. It is in `~/.codex/archived_sessions` and not in `~/.codex/sessions`.
- **Its outputs:** both images are in `~/.codex/generated_images/01a139d9…`. The used one's sha256 (`b3b66a50…`) matches `fix4/codex/paint-jamb11/out/jamb11-painted.png` and carries its caBX (C2PA) chunk. The unused one (`6b707cb9…`) is recorded as unused.
- **The prompt** told Codex to keep all metadata, including C2PA.
- **The atlas:** cleanup kept Codex's paint only as clamped detail inside the plates' masks. No pixel changed outside them, which I checked against round 10's atlas.

## Inherited, for Nathanial (not this round's defects; all unchanged)

- COOLANT FAULT stays up through "Safe point saved" (fixed on main by PR #63; check after the port).
- WOLF's relay surge in s2 reads as a clip-art cloud (main draws it).
- The ceiling light's streaky "dripping" blue light sits left of x 540 in main's plate, so rule 5 keeps it. REAL-LOOK section 2 lists that look as a don't, for a later room pass.
- The roller's slats against the sloping hood and bottom bar. My atlas measure is ambiguous because the slat pitch aliases the correlation: one pair reads about 8°, the others about 17°. It is inherited from the round-6 piece he approved.
- When open, the roller's striped bottom bar shows under the right end of the hood.
- Three yellows when open and three reds when shut.
- Overdraw and texture memory are over budget, and the haze is still a full-screen layer.
- The Records and junction beacons are still drawn in code.
- The bogie box reads as a vent box.
- The thin conduit at x 852 runs behind the band's corner.
- The RESTRICTED AREA plate's open choices.
- The crank re-cut from the approved walk frames.
- The beacon flash rhythm, to be judged in play.

## Sources

New in this review:
- [S22] UFGS 08 39 53 (February 2019, change 1 05/20), *Blast Resistant Doors (Earth Covered Magazines)*, USACE/NAVFAC/AFCEC. Downloaded and read: section 1.2 ("Frames and anchors must be capable of transferring blast reactions to the adjacent supporting structure"; side-hinged or horizontal sliding doors), 2.1.4 (ASTM A307 anchor bolts, F844/F436 washers), 2.2.1 (trolleys for sliding doors), 2.2.11 (rubber perimeter gasket seals) and 3.1.2 (anchor bolts between the steel and the concrete): https://www.wbdg.org/FFC/DOD/UFGS/UFGS%2008%2039%2053.pdf (text in `scratchpad/add7-review-real-r5/research/ufgs/`)

Cited from earlier reviews: [S3], [S5], [S6], [S8], [S9], [S10], [S13], [S14], [S16] and [S21] (REVIEW-real-r1 to r4), and [D1] (`add7/door/NOTES.md`).
