# Door family, design A, Look 2 re-render (2026-10-10)

**Repair round 1 (2026-10-10) is applied.** See "Repair round 1" below. The QA table, review sheets and doors.json reflect the repaired files. The v1 files are kept in `_v1/` for comparison.

This covers static files and automated QA only. Nothing was imported into Godot, rendered in the game, played, exported or tested on a device. The repository was not touched.

## What is delivered

All files are 8-bit RGBA PNGs at D = 4 (QA scale 0.25), 576 px tall, with dimensions that are multiples of 16. Every layer of a door shares one canvas and one origin, so the game stacks them at the same position. The baseline (sill) is row 567 on every frame and front lip. `doors.json` lists the canvas, the opening box, the near jamb, the lamp boxes, the draw order and the per-file baseline for each door.

Draw order, back to front: passage, then leaf or debris, then frame-<state>, then actors, then front-lip.

| door | canvas (world px) | opening box (x0,y0,x1,y1) | files |
|---|---|---|---|
| corridor-seal | 368x576 (92x144) | 123,148,261,507 | frame-sealed (red lamps), frame-open (green lamps), front-lip-sealed, front-lip-open, passage, leaf |
| records-west-door | 368x576 (92x144) | 107,150,243,507 | same set as the corridor seal; perspective mirrored (near jamb on the right) |
| archive-lift-hatch | 416x576 (104x144) | 112,165,320,525 | frame-sealed (red), frame-open (green), frame-idle (cyan, as painted), front-lip, passage (lit lift car), leaf (slatted shutter) |
| junction-blast-door | 384x576 (96x144) | 115,144,263,514 | frame-armed (amber lamps), frame-off (lamps dark, for after the blast), front-lip-armed, front-lip-off, passage (the lit sentry lane), leaf-sealed, leaf-breaking, blown-debris |

How to use the layers:
- **Leaf.** The leaf is cut to the opening, grown by 3 px, and sits behind the frame. To open the door, slide it up and clip it at the opening's top row with a region rect or clip_children. Its bottom edge carries a lit lip for the rise.
- **Open, breaking and blown states.** Each one shows a painted, lit passage in the doorway, never the back wall. The blown debris is the torn leaf rim plus fallen chunks. Its centre is transparent so the sentry-lane passage shows through.
- **Front lip.** The front lip is the near jamb (the columns outside the opening on the near side), cut from the same frame. Draw it over actors so they pass behind the near jamb. Its lamps are baked to match the frame state.

Review:
- `review/repair-round1.png` shows each repair before and after (pocket, lift lamp, graded closed states, blown debris next to design A).
- `review-sheet.png` shows every door's composed states on the style-test plate at game size, with the style-test engineer for scale.
- `review/<door>-sheet.png` shows every delivered file alone on mid-grey #808080 and alone on the style-test plate, each at game size (2/3 of source, the plate's D 8/3, which is a 1080p gameplay view) and at 2x (4/3 of source). It also shows the composed states at both sizes.
- On the plate, the sprite's baseline sits on the walk line (row 800), next to the darkest wall gap at x 1180.

## Generation

- **Tool.** Codex's built-in image_gen only, through `codex exec --skip-git-repo-check -s workspace-write --add-dir ... "<prompt>" < /dev/null` from `hq/doors`. No API key, CLI fallback or billed path was used. Each of the 8 sessions was archived with `codex archive` (session ids are below and in `jobs/*.log`).
- **References on every call (5 maximum, assigned in this order):**
  1. the design A board, or the edit target
  2. `refs/style-test-v2-board.png`: a composite of style-test v2 composite-1920, plate, engineer, WOLF, breaker and relay. It stood in for the six style-test images because the tool takes at most five references. notes.md is text, so its rules went into the prompt instead.
  3. `refs/keyart-b.png`
  4. `refs/palette-card.png` (bible)
  5. the design board, for edits. For the lift frame this slot held the junction A board.

  The design boards are `refs/design-A-corridor.png` (sealed, open, front-lip) and `refs/design-A-junction.png` (sealed, breaking, blown, front-lip), built from `art/doors/A/`.
- **Method.** One frame per door was generated with an empty, genuinely transparent opening. The passage, leaf, breaking leaf and blown debris were then made as edits of that frame that fill only the opening.
  - The edits re-render the whole image; the Codex log records that the frame pixels drifted. So only the pixels inside the opening were used.
  - Each edit was registered to the fitted frame: silhouette IoU outside the opening, or luma difference on the jamb band for the hazy junction leaf edits, searched over ±8 px and ±1% scale. It was then cut to the opening grown by 3 px.
  - The 3 px margin was refilled from the nearest pixel inside the opening, so no frame paint from the edit survives.
  - The Records west door frame is an edit of the mirrored corridor frame, so it shares that silhouette (it is the other side of the same join). The edit added a cyan keypad and a cable loom and removed the hazard bands.
- **New designs.** The task allowed the archive lift hatch to be a new design. It uses guide-rail jambs and a winch-housing crown with two cable sheaves, so its outline differs from the access doors. The blast door was prompted broader than the corridor seal. The result is only modestly wider (opaque 364 px against 338 px).
- **Prompts.** The full prompts are in `jobs/*.txt`, in a shared preamble (`jobs/_preamble.txt`). Codex's verbatim image_gen prompts, its attempts and its rejections are in `raw/log.md`.

## Finishing (scripted, `work/`)

1. **`fit_frame.py`:**
   - Crop to the alpha bbox.
   - Downscale once, in linear light with Lanczos, so the body is 560 px tall. The raw subjects were 1355-1436 px tall (scale 0.39-0.41), so nothing was upscaled.
   - Place the frame with its baseline on row 567.
   - Bible 5.4 step 4: drop islands under 64 px, zero alpha under 16, and set the interior to 255.
   - Set every partial-alpha edge pixel's RGB to the median of the opaque ring 2-4 px inside. This removes the black matte fringe the A drafts had.
   - Find the opening as the enclosed transparent region.
2. **`finish_frame.py`:**
   - Detect the lamp lenses by hue, chroma and a bright core, filling their holes.
   - The base gets unlit cool glass. Lamp spill around the lenses was desaturated: 4 px on the red and amber doors, 10 px on the lift's cyan lamp.
   - The lit lens pixels were palette-snapped and hue-shifted for the green, red and cyan variants. They were then composited back to make the baked frame-<state> files.
   - Cut the front lip.
3. **`extract_layer.py`:** registration and the cut to the opening, as described under Generation.
4. **`package.py`:**
   - Palette-snap saturated pixels to within ΔE 11 of the nearest bible accent: lamps, seams, hazard bands and cracks.
   - Leaves, passages and debris get a lit bevel band on the inside of the silhouette, strongest on the top and cyan-tinted on the sides. The width and strength per layer are in `RIM` in `package.py`. The edge match runs again after it.
   - The blown debris had a 3x3 median on opaque RGB to lower display noise, as the style test did for WOLF.
   - Copy to delivery names and run `qa_asset.py`. Output PNGs carry no metadata chunks (IHDR, IDAT, IEND only).
5. **`door_rmse.py` and `review.py`:** silhouette RMSE and the review sheets.

## QA (`python3 -I art-audit/bible/qa_asset.py FILE --family door --scale 0.25 --zoom 1.35 --zoom 1.8 --baseline B`)

**All 26 delivered files pass A-G (re-run after repair round 1).** The baseline B is 567 for frames and lips, and the opening bottom + 3 for the other layers. Density is 1.111 at 1080p and zoom 1.8, and 2.963 at 960 and zoom 1.35. Nothing was re-calibrated. Per-file JSON is in `qa/`.

| asset | size | pass | A body | fringe dark / halo | edge shift | outline dL | top light dL | baseline | cool b* | accent p90 | sigma | hf |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| archive-lift-hatch-frame-idle | 416x576 | PASS | 1.0 | 0.008 / 0.0072 | 0.04 | 3.1 | 24.2 | 567 | -8.14 | 10.9 | 3.14 | 0.14 |
| archive-lift-hatch-frame-open | 416x576 | PASS | 1.0 | 0.008 / 0.0072 | 0.04 | 3.1 | 24.2 | 567 | -8.14 | 11.0 | 3.16 | 0.14 |
| archive-lift-hatch-frame-sealed | 416x576 | PASS | 1.0 | 0.008 / 0.0072 | 0.04 | 3.2 | 24.2 | 567 | -8.14 | 10.6 | 3.15 | 0.147 |
| archive-lift-hatch-front-lip | 416x576 | PASS | 1.0 | 0.0045 / 0.003 | 0.15 | 2.5 | 15.8 | 567 | -7.49 | 10.0 | 2.5 | 0.153 |
| archive-lift-hatch-leaf | 416x576 | PASS | 1.0 | - / - | - | -0.5 | 11.2 | 528 | -9.57 | 11.1 | 1.08 | 0.099 |
| archive-lift-hatch-passage | 416x576 | PASS | 1.0 | - / - | - | -4.5 | 13.9 | 528 | -8.66 | 9.6 | 2.75 | 0.055 |
| corridor-seal-frame-open | 368x576 | PASS | 1.0 | 0.0161 / 0.0123 | 0.31 | 7.5 | 31.2 | 567 | -7.11 | 11.1 | 3.71 | 0.106 |
| corridor-seal-frame-sealed | 368x576 | PASS | 1.0 | 0.0161 / 0.0123 | 0.23 | 7.6 | 31.3 | 567 | -7.13 | 11.1 | 3.67 | 0.106 |
| corridor-seal-front-lip-open | 368x576 | PASS | 1.0 | 0.0108 / 0.0193 | 0.24 | 4.6 | 28.8 | 567 | -7.08 | 11.1 | 3.21 | 0.114 |
| corridor-seal-front-lip-sealed | 368x576 | PASS | 1.0 | 0.0108 / 0.0193 | 0.24 | 4.7 | 28.9 | 567 | -7.08 | 11.1 | 3.19 | 0.114 |
| corridor-seal-leaf | 368x576 | PASS | 1.0 | - / - | - | -2.0 | 9.1 | 510 | -7.6 | 11.0 | 2.65 | 0.118 |
| corridor-seal-passage | 368x576 | PASS | 1.0 | - / - | - | 11.7 | 3.5 | 510 | -8.26 | 11.0 | 2.88 | 0.064 |
| junction-blast-door-blown-debris | 384x576 | PASS | 1.0 | 0.0101 / 0.0168 | 0.77 | 4.8 | 11.6 | 517 | -7.29 | 11.2 | 3.86 | 0.169 |
| junction-blast-door-frame-armed | 384x576 | PASS | 1.0 | 0.0154 / 0.0224 | 0.58 | 9.6 | 36.3 | 567 | -6.32 | 11.2 | 3.84 | 0.202 |
| junction-blast-door-frame-off | 384x576 | PASS | 1.0 | 0.0145 / 0.032 | 0.56 | 10.0 | 36.9 | 567 | -6.49 | 11.1 | 3.75 | 0.203 |
| junction-blast-door-front-lip-armed | 384x576 | PASS | 1.0 | 0.0105 / 0.0199 | 0.4 | 5.5 | 30.3 | 567 | -5.98 | 11.2 | 3.93 | 0.176 |
| junction-blast-door-front-lip-off | 384x576 | PASS | 1.0 | 0.0105 / 0.0335 | 0.26 | 6.6 | 31.9 | 567 | -6.21 | 11.1 | 3.86 | 0.176 |
| junction-blast-door-leaf-breaking | 384x576 | PASS | 1.0 | - / - | - | -4.6 | 4.2 | 517 | -5.56 | 11.2 | 5.84 | 0.224 |
| junction-blast-door-leaf-sealed | 384x576 | PASS | 1.0 | - / - | - | -1.3 | 4.3 | 517 | -7.84 | 11.2 | 3.82 | 0.242 |
| junction-blast-door-passage | 384x576 | PASS | 1.0 | - / - | - | 5.4 | 8.3 | 517 | -7.22 | 10.8 | 3.16 | 0.075 |
| records-west-door-frame-open | 368x576 | PASS | 1.0 | 0.008 / 0.0118 | 0.1 | 4.8 | 29.9 | 567 | -6.52 | 11.1 | 3.57 | 0.125 |
| records-west-door-frame-sealed | 368x576 | PASS | 1.0 | 0.008 / 0.0118 | 0.06 | 4.9 | 30.0 | 567 | -6.53 | 11.1 | 3.56 | 0.126 |
| records-west-door-front-lip-open | 368x576 | PASS | 1.0 | 0.0117 / 0.0168 | 0.15 | 5.6 | 26.9 | 567 | -6.58 | 11.1 | 3.17 | 0.112 |
| records-west-door-front-lip-sealed | 368x576 | PASS | 1.0 | 0.0117 / 0.0168 | 0.15 | 5.8 | 27.1 | 567 | -6.59 | 11.1 | 3.17 | 0.112 |
| records-west-door-leaf | 368x576 | PASS | 1.0 | - / - | - | -0.9 | 6.0 | 510 | -6.4 | 10.9 | 2.16 | 0.171 |
| records-west-door-passage | 368x576 | PASS | 1.0 | - / - | - | 4.3 | 5.4 | 510 | -9.11 | 10.9 | 3.2 | 0.048 |

The leaves and passages show "-" for fringe because their cut edges have no partial alpha. Those edges sit under the frame.

**Silhouette RMSE (bible 6.2.6, `qa/door-rmse.json`).** door_rmse.py was not written by the bible, so the method here is mine:
- closed-state silhouettes at world scale
- baselines aligned, centred
- sqrt of the differing share over the union

| pair | RMSE |
|---|---|
| corridor vs junction | 0.278 |
| corridor vs lift | 0.506 |
| junction vs lift | 0.477 |
| corridor vs records west | 0.449 (only because of the mirroring; they are deliberately the same family across one join) |

All pairs are at or above 0.25. The corridor-junction margin is small.

## Repair round 1 (reviewer defects, 2026-10-10)

Only the junction blown debris was regenerated through Codex. The other three fixes are scripted edits of the existing work files (`work/repair_v2.py`, plus a `GRADE` step in `work/package.py`), followed by a full re-package, QA, `door_rmse.py` and `review.py`. Files the repairs do not touch were re-packaged byte-identical to v1. The 10 changed files are:
- records-west-door-frame-sealed and -frame-open
- corridor-seal-leaf and records-west-door-leaf
- archive-lift-hatch-leaf, -frame-sealed, -frame-open, -frame-idle and -front-lip
- junction-blast-door-blown-debris

**1. Records header pocket (fixed).**
- The defect: 56 px at alpha 0-254 sat inside the cable loop at x 189-203, y 167-173. They were enclosed by the frame but outside the leaf and passage cut, so the back wall showed through.
- The fix: `repair_v2.py pocket` filled them in `work/records-frame.base.png`. The fill is a harmonic in-fill from the opaque surround, seeded with the median ring colour #0b141b (the dark backing plate between the cables), at alpha 255. Partial-alpha edge pixels kept their own paint, composited over the fill. Both baked states (sealed and open) are built from that base. The front lips are unaffected, because the pocket is left of the near-jamb cut at x 243.
- Check: every pixel that is enclosed by the frame and not fully opaque is now opaque in BOTH the leaf and the passage. This holds for every frame state of every door (corridor, Records, lift and junction, including frame-off with passage plus debris), and `repair_v2.py check` reports 0 pocket px on all four frames.

**2. Lift sealed lamp (fixed).**
- The defect: the red variant had been a hue rotation of the bright cyan lens, so it read salmon.
- The fix: `repair_v2.py liftred` rebuilt `work/lift-frame.lamps-red.png` from the cyan lens. Each pixel keeps its luminance rank and takes the colour at that rank on a monotone ramp: #2a0a10, red_shadow #5f0e17, signal_red #a01e29, red_practical #ad252d, #bc1f1d, red_glow #ca452f, #d53822, #e4624e, #ffa289 and a #fbe6d6 core. The ramp is sampled from the corridor seal's largest sealed lens and snapped to the red accents.
- A first attempt took colours straight from the corridor lens by quantile. It came out speckled, because that lens mixes hues at equal values, so it was replaced.
- Result (reviewer's `lamp.py`): median #ab242c (v1 #d8806d), p90 #dd503a (v1 #f2a48f); nearest accents red_glow, signal_red and red_practical. F accent p90 is 10.6.
- The open (green) and idle (cyan) lamps are unchanged.

**3. Closed-state values (fixed).**
- The fix: `package.py` now applies a linear-light multiply with a cool bias, (0.94, 0.97, 1.0) per channel, before the rim band. The top-light bevel therefore keeps its full lift. Saturated pixels are palette-snapped again afterwards. The factors:
  - corridor leaf 0.72
  - Records leaf 0.72
  - lift leaf 0.72
  - lift frame and front lip 0.85
- The first pass (0.66 and 0.62/0.80) dropped the leaves by 5.5-5.8 L*, more than the asked 3-5, so it was eased.
- Leaf medians alone, before and after: corridor 25.5 to 20.7, Records 25.2 to 20.7, lift 27.4 to 22.7.
- Composed closed states (reviewer's `compL.py`, frame plus leaf):

| state | v1 | now |
|---|---|---|
| corridor sealed | 23.3 | 21.1 |
| Records sealed | 23.7 | 21.1 |
| lift sealed | 25.9 | 21.9 (below the engineer body's 23.6) |
| junction sealed | 21.9 | 21.9 (untouched) |
| corridor open | 19.1 | 19.1 |
| junction blown | 18.7 | 19.0 |

- C top_light stays positive on every changed file: corridor leaf 9.1, Records leaf 6.0, lift leaf 11.2, lift frames 24.2, lift front lip 15.8. Outline dL is -2.0 to 3.2.
- `qa_asset.py` still has no value-band check. These medians come from the reviewer's script.

**4. Junction blown debris (regenerated).**
- Design reference: `art/doors/A/junction-blown.png`. It was not used as the edit target, because its frame differs from the Look 2 frame and could not be registered to it.
- Edit target: the Look 2 sealed-leaf raw (`raw/junction-leaf-sealed.png`). The debris therefore comes from the actual Look 2 leaf.
- References, in order: the edit target, `refs/style-test-v2-board.png`, `refs/keyart-b.png`, `refs/palette-card.png`, design A junction-blown.
- Round 1 (`jobs/junction-blown-v2.txt`, session 01a128aa-7091-7740-8f0b-26d6660d6e59, archived):
  - Outputs: v2a (edit of the sealed leaf) and v2b (extension of the v1 debris raw).
  - Both put a full rim and the hazard chunks around the hole, but painted the right-side chunks over the frame's inner right pillar. The opening cut therefore removed them again, the same failure as v1.
  - Rejected.
- Round 2 (`jobs/junction-blown-v3.txt`, session 01a128af-b816-76e1-8403-72fcee059039, archived):
  - The prompt added an explicit placement rule: inside the leaf area only, the chunks to the left of the inner right pillar, the top rim under the header.
  - Codex made 4 raws: v3a and v3b, each with a self-retried attempt1. All registered at IoU 0.995-0.997 outside the opening, with shift (3,3) and scale 1.0.
  - **v3b was selected.** It has a torn rim on all four sides, including a clear top rim under the header, and hazard-striped fragments on the right. Its tear has an ember edge snapped to amber_glow and red_glow, and a rubble pile with hazard pieces sits on the sill. v3a had bigger hazard chunks but almost no top rim.
  - Fill: the opaque share of the opening went from 19% in v1 to 41%, and the whole-canvas opaque_fill_pct in qa_asset.py is now 10.9%. The centre stays transparent over the sentry-lane passage.
- Finishing (unchanged from v1): `extract_layer.py`, cut to the opening + 3 px with the margin refilled, then `package.py` (3x3 median, rim band (3, 20, 10, 6), palette snap).
- QA: PASS. Outline +4.8, top light 11.6, fringe 0.010 / 0.017, accent p90 11.2, display sigma 3.86, hf 0.169.
- Layer check: opening pixels uncovered by passage plus debris = 0; debris pixels outside the opening that are not under frame-off = 0.

**Silhouette RMSE** was re-run and is unchanged. Corridor-junction is 0.278, and every pair is at or above 0.25.

**5. Doorway kit opening size: ESCALATED to Nathanial, not changed.**
- The bible's batch-3 gate cites the doorway kit (plan, shared_tech 7): a 64 world px opening and a 132 world px leaf.
- The painted design A openings are much smaller (world px, from doors.json `opening_bbox` / 4):

| door | opening (world px, w x h) |
|---|---|
| corridor | 35 x 90 |
| Records | 34 x 89 |
| lift | 52 x 90 |
| junction | 37 x 93 |

- A 132 px leaf cannot fit in a 144 px design A frame together with its header and sill. The engineer (70 world px) does fit through every painted opening.
- Options for Nathanial:
  - **(a)** Amend the doorway kit and the RoomProfile door values to the painted openings. doors.json has the exact boxes.
  - **(b)** Re-render the frames with a taller opening and a thinner header. That means new frame generations and re-cutting every leaf, passage and debris layer, and it would move away from the approved design A proportions.
- Nothing was changed until he decides.

## Redos and fixes

- **First QA failures:**
  - corridor and junction frames: accent p90 21.1 and 31.6, from the lamps and hazard bands. Fixed by the palette snap.
  - small lamp-overlay sprites: dark outline and negative top light, because a lens is brighter than its rim.
  - leaves and passages: dark recess edges, giving top light down to -21.8 and outline down to -25.
  - blown debris: σ 9.5, then outline -10.8, then halo 0.13.
- **Fixes:**
  - The lamp overlays were dropped in favour of baked frame-<state> files (see deviations).
  - The edit's frame paint in the margin was removed.
  - The lit bevel band was added.
  - A median was applied to the debris.
  - The edge match was rerun after the band.
- **Codex retries** (logged in raw/log.md):
  - the corridor frame (alpha halo)
  - the lift frame (filled the canvas)
  - the Records frame
  - junction passage, sealed leaf and breaking leaf (the first attempts had no alpha and a baked checkerboard)
  - the blown debris
  - the lift leaf: 5 slats were asked for, and both attempts gave 4 plus a bottom bar; the second was kept
  - corridor passage and leaf
  - Records passage and leaf: the first attempts were kept
- **Haze on the junction edits.** The junction leaf edits had faint smoky alpha outside the frame. This does not matter, because only the opening is used.

## Deviations and things to check

- **Lamps are baked frame variants, not separate lamp sprites.**
  - Bible 4 says stateful lamps should be separate sprites. The small lens overlays could not meet check C (a glowing lens is always brighter than its edge).
  - So the lamp state is a whole-texture swap: frame-sealed or frame-open, and frame-armed or frame-off, with the matching front lips.
  - The unpackaged overlays are still in `work/*.lamps-*.png` if an additive approach is preferred. They fail C.
- **The lit bevel band** on leaves, passages and debris is partly a QA accommodation:
  - 3 of its 4-7 px sit in the margin hidden under the frame.
  - About 1 px shows as a light inner edge around the opening.
  - On the rising leaf, the band shows as its lit bottom lip.
  - The values are in `package.py` RIM, so the band can be removed if it reads wrong in game.
- **The doorway kit (level-expansion plan) and these doors differ (escalated, see Repair round 1, item 5).** The kit asks for a 64 world px opening and a 132 world px leaf. These openings are about 35-52 world px wide and 90 world px tall (corridor 139x360 source px), because design A's three-quarter frame is deep. The collision and trigger values are separate from the art, but they need checking against the painted opening in Godot.
- **Canvas widths** are 368, 384 and 416, wider than the bible's "about 352", to fit the A design's depth at 560 px tall.
- **Records west door** is a mirrored-perspective sibling of the corridor seal, not flip_h. Its rim light is on the mirrored side.
- **No smoke or steam** is baked into the breaking or blown states. Particles should come from the game.

## Raw sources and provenance

Every raw output had a C2PA caBX chunk. The delivered PNGs and review sheets carry none (IHDR, IDAT, IEND only). The raws are kept unchanged in `raw/`.

| raw | sha256 |
|---|---|
| corridor-frame | ebb91c59d7a96fd96069edd61db8fa382844e2c1cf470f49bfb0ee1a5518b561 |
| corridor-passage | a9301434f5176aeca5426d18a7c175828cf9ff8d3b8688058c6edb2e120953ee |
| corridor-leaf | ce90e5d1395a422e1bb5b05268127af708f6e886ec4a86babe0d7b51b44dd956 |
| records-frame | 88ddaa1298576512e687cbf7fe62e49f0d6b76fc415a2cd6a929df04c25c3522 |
| records-passage | 72e3f7bc47531e62aea3dc94949ab4e8992e90c073d74e54b96630b16074eb15 |
| records-leaf | 3ae4b80a1406960631c9828111cec1fd45dd2d27200ea53193dbe12c14b34b34 |
| lift-frame | fdbde9dc11aec8339e9f337cea3f53d5a06d0b583cf870db5a203caa78ff4354 |
| lift-passage | d3ddf264bf9df9625d80ed4a0b479554cc5900aa28a4ec47c36e6bf3a217525a |
| lift-leaf | cf8c8b67f095682b7bb524d8055c4df8c61b3675cc5c41ac6379b4466ea4eb44 |
| junction-frame | fe893976c6dcc2371a6fc48de7fc8cf514d9dbf6e298980e0e2a4e9c13027b96 |
| junction-passage | 7809aa88898b17d8145121ba1176692a1290a99a732769f573d5f382a77f7a97 |
| junction-leaf-sealed | 69a0ced1d5136ef1d26095c76a347184114f16c417bcf61a28ac1982b0a1d0fd |
| junction-leaf-breaking | 5ad4e8fb5195fbeb0cd6fc725bb7faad7b69219f8d43714cdbf96bcffeecca69 |
| junction-blown-debris (v1, superseded) | bb16fcb3ae43a2c2e69ea0c56458a07c68157fbf38cfd7c7c656503dcd8e6256 |
| junction-blown-debris-v2a (rejected) | 3e5686d2e066454d23d7ab29b5a31462887aec30459ad589a083cfd423eb3e92 |
| junction-blown-debris-v2b (rejected) | 251897a4e9b241a20ef4ce2fbcb4a55d22f64d7c19234b322fb344a53396185f |
| junction-blown-debris-v3a-attempt1 (rejected) | 48162ff3a4fb8ffa011331b61ae42c95ff2f953720e80c6e5788480fe0edfcbf |
| junction-blown-debris-v3a (rejected) | 4192199c24a4296d8889b8653a5e7529d8382c2de43f60b5e9738f6ba2343bdb |
| junction-blown-debris-v3b-attempt1 (rejected) | 1b562c22041b16414b9b16b242d6632c92a509037451b7efee0b4b29ed350449 |
| **junction-blown-debris-v3b (delivered)** | dd86a8c0e4ade2d3d10f11727e06ee4b2809d6d645c107e0de070ba68b5ab6e8 |

**Codex sessions (all archived):**

| job | session id |
|---|---|
| corridor-frame | 01a1281b-435c-7a22-8bd8-8ff6da4b26a7 |
| junction-frame | 01a1281b-4aa4-7573-9850-5385e03fbf7b |
| lift-frame | 01a1281d-6937-7be1-a7d2-375c698b34ff |
| records-frame | 01a12825-b156-75e3-bfc8-65a3ca190ce8 |
| corridor-layers | 01a12825-a521-76f2-936b-edb2d38c8f14 |
| lift-layers | 01a12825-a8a9-7fb3-ab8c-a284e6149085 |
| junction-layers | 01a12825-ae49-7df2-a0d0-b99db89b931c |
| records-layers | 01a12833-b393-78d3-8ae3-ce12a8f7a17f |
| junction-blown-v2 (repair) | 01a128aa-7091-7740-8f0b-26d6660d6e59 |
| junction-blown-v3 (repair) | 01a128af-b816-76e1-8403-72fcee059039 |
