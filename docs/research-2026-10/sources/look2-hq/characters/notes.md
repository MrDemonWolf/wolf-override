# Character identity sheets, Look 2 graphic-painterly (batch: characters)

Date: 2026-10-10. Canonical Look 2 identity references for later animation: the engineer (3 views), WOLF (4 poses) and the Director (2 opening poses).

## What is here

| file | canvas | opaque size (px) | baseline row | source attempt | raw→final scale | raw median | rim | QA A–G |
|---|---|---|---|---|---:|---:|---:|---|
| engineer-side-idle.png | 256x320 | 82 x 280 | 311 | engineer-side-idle-a2 | 0.1885 | — | 0.35 | PASS |
| engineer-side-stride.png | 256x320 | 160 x 280 | 311 | engineer-side-stride-a1 | 0.1986 | — | 0.35 | PASS |
| engineer-three-quarter.png | 256x320 | 109 x 280 | 311 | engineer-three-quarter-a3 | 0.1906 | — | 0.35 | PASS |
| wolf-side-stand.png | 512x272 | 460 x 242 | 263 | wolf-side-stand-a3 | 0.3237 | 9 | — | PASS |
| wolf-side-lookback.png | 512x272 | 417 x 240 | 263 | wolf-side-lookback-a3 | 0.2817 | 11 | — | PASS |
| wolf-side-walk.png | 512x272 | 478 x 240 | 263 | wolf-side-walk-a3 | 0.2914 | 9 | — | PASS |
| wolf-sit.png | 512x272 | 311 x 248 | 263 | wolf-sit-a3 | 0.4078 | 7 | — | PASS |
| director-stand-left.png | 256x320 | 82 x 280 | 311 | director-stand-left-a1-2 | 0.1954 | — | — | PASS |
| director-turn-away.png | 256x320 | 102 x 280 | 311 | director-turn-away-a1 | 0.1924 | — | — | PASS |

Also here: `qa/<name>.json` (main QA run, A–G), `qa/supplementary/<name>-H.json` (H readability pre-check), `review-sheet.png`, `raw/` (byte-for-byte copies of every generated image plus `generations.jsonl`), `refs/` (the composite reference boards). `work/` holds scratch previews and per-asset finishing logs (`<name>.finish.json`).

Sizes follow ART_BIBLE section 4 at D = 4: the engineer and the Director are 280 px tall in a 256x320 cell with the feet baseline on row 311 and the hip centroid on x 128; WOLF stands 460 px long (nose to tail tip) in a 512x272 cell with the baseline on row 263, centred; the other WOLF poses use the same body scale (see below). Every canvas is a multiple of 16. Left-facing use is `flip_h`; the Director is authored facing left as requested.

**WOLF scale (changed in the repair).** All four WOLF poses share one body scale, set by the stand at exactly 460 px long (460 x 242, h/w 0.526; ART_BIBLE section 4 gives 460 x 246). The walk (478 x 240) and the look-back (417 x 240) are finished at that same scale rather than each forced to 460 px long: the look-back is naturally shorter (muzzle turned back) and the walk slightly longer (stride), so forcing 460 would have made the look-back 9% larger and the walk 4% smaller than the stand, the same kind of drift this repair fixes. Their scale relative to the stand comes from `hq-tools/relscale.py`, which matches the rear region (tail, rump, hind legs) aligned at tail tip and baseline (walk 0.900, look-back 0.870 of the raw-to-stand factor). The sitting pose is sized by its same-image lineup, as before: the standing copy in that image is scaled to 460 px long (factor 0.4078) and the factor applied to the sitting figure, giving 311 x 248. Cross-check: relscale puts that standing copy at 463 x 246 at the stand scale, within 1% of the stand. Result: WOLF is 240-242 px tall standing, 86% of the engineer height, as in the approved style test (241 px, 86%). If a strict 460 px length per pose is wanted instead, set `rel_scale` to null in `hq-tools/selection.json` and re-run `finalize.py` (look-back would be 460 x 265, walk 460 x 231).

## How it was generated

- Codex built-in `image_gen` (imagegen skill, default built-in mode) in edit mode with local references, driven by `codex exec --skip-git-repo-check -s workspace-write --add-dir hq --add-dir art --add-dir style-test --add-dir art-audit ... < /dev/null` (plus `-C hq/characters`, `--json`, and `-c model_reasoning_effort="medium"`). No API key, CLI fallback or billed path was used.
- One image per Codex job. Each job's output was collected from that session's own folder, `~/.codex/generated_images/<thread_id>/`, and the prompt as sent was read from the session rollout (`image_gen.generation` item, `revisedPrompt`). Every prompt below matched the prompt file verbatim (checked automatically for the repair jobs), except that Codex appended one self-check line to the wolf-sit-a2 prompt (shown in its block).
- Every session was archived with `codex archive <thread_id>` after collection; no session with this cwd remains in `~/.codex/sessions`. Threads: 01a1281b-c908-7313-8efd-d1b686843369, 01a1281b-d0d4-7371-974b-122d3f38760a, 01a1281b-d88a-7451-93b7-bec93bb80358, 01a1281e-d274-7960-a0f2-2c6d7f378d4b, 01a1281e-db19-72f2-b917-0f4c45068c7d, 01a12820-9067-7c83-8c53-2e36e420d0f1, 01a12820-9071-7b91-9b65-aa48a38ced23, 01a12820-9146-7323-95ba-fe001a3c530b, 01a12820-928d-7320-a8fa-3b8b37064367, 01a12822-803a-7d92-959a-2e77e8ec85b6, 01a12822-803a-7ee2-af60-5cb7e7596e75, 01a12822-803b-7722-a491-f94e47c7d794, 01a12824-2261-7121-9375-05a67b81f2ac, 01a12825-a761-70a1-83cf-a01e0cad753e, 01a12831-9df3-76b3-b71a-0d811a5f0b23, 01a12831-a9ca-7db3-aeba-bdb69fc36f20, 01a12833-e4c3-7722-b8c4-d7dd47ed0e4a, 01a12833-ea07-7833-836c-ec21d64934be, 01a12833-f79e-7d02-8c50-d8ffef6fb2ce, 01a12837-a215-7700-bea1-f3d884b1d10d, 01a1283c-f1d0-78b2-bfab-45c1dff2e6e2.
- **Incident, first run.** The first attempt ran three multi-pose Codex jobs in parallel and told them to copy "the new" output; the engineer job copied the Director job's image. All three were stopped before any later pose used the wrong reference, the wrong copy was deleted, the two images already made were re-collected by thread id (engineer-side-idle-a1, director-stand-left-a1-1/-2), and every later job made exactly one image and was collected by thread id. The WOLF job of that run produced no image. Another agent's Codex job (doors batch) was running at the same time and was not touched.

### References (five-image cap, so composite boards were built; `refs/`)

- `ref-identity-engineer.png`: left = `art/sprites/rowan-side-right.png` (approved design), right = the native-resolution source of the approved style-test engineer (raw `a207f79a…`, the image `style-test/v2/engineer.png` was cut from). The 128x304 cut-out itself looked soft when enlarged to board size, so its full-resolution source was used; the cut-out also appears in the style-test board.
- `ref-identity-wolf.png`: left = `art/sprites/wolf-side-right.png`, right = the native source of `style-test/v2/wolf.png` (raw `f88e4fc4…`).
- `ref-identity-director.png`: left = `art/sprites/director-side-left.png`; right = the Look 2 engineer source as a rendering example only (prompts say not to copy that character).
- `ref-style-test-v2.png`: `style-test/v2/composite-1920.png` (top), `plate.png` (bottom left) and the four cut-outs `engineer.png`, `wolf.png`, `breaker.png`, `relay.png` (bottom right). `notes.md` was read for the v2 prompts and finishing precedents; it is text, so it was not attached.
- `art/keyart/keyart-b.png` (mood, light, palette) and `art-audit/bible/palette-card.png` (colour swatches) in every call.
- Pose 2+ of each character used the selected pose-1 raw as Image 1 (identity chain), followed by the identity board, style-test board, key art B and palette card. wolf-side-lookback-a2 used `ref-wolf-lookback-board.png` (identity board on top, the head-turn of wolf-side-stand-a1 below) in the identity-board slot.
- Repair: `ref-v2-wolf-source.png` is a byte-identical copy of the approved style-test WOLF source (`exec-f88e4fc4…`, SHA-256 21288def…, as recorded in `style-test/v2/notes.md`). wolf-side-stand-a3 used `art/sprites/wolf-side-right.png` as Image 1 (precise-edit target, head-forward design) and that v2 source as Image 2 (rendering). The repaired chain (walk-a2/a3, look-back-a3, sit-a3) used wolf-side-stand-a3 as Image 1; look-back-a3 used the v2 source as its head-turn guide. engineer-three-quarter-a2/a3 used engineer-side-idle-a2 as Image 1; a3 added a2 as Image 2 ("rotate further").

## Repair, 2026-10-10 (reviewer defects)

**1. WOLF proportions (stand, walk, look-back, sit).** The first stand (a2) measured 460 x 205 (h/w 0.446) against 0.524 for the approved v2 WOLF and 0.533 for the design sprite; legs were short, the head low and the tail held level, and WOLF reached 73% of the engineer height (approved: 86%). Fix: wolf-side-stand-a3 regenerated in precise-edit mode with the design sprite as Image 1 and an explicit shape lock (same silhouette, leg length, head height, tail angle; change only the rendering). Accepted on the first attempt: raw alpha ≥ 128 box 1424 x 751, h/w 0.527, 243 px at 460 long (window 235-246). Walk, look-back and sit were regenerated from the new stand with a proportion-lock paragraph. Walk a2 was rejected (stretched, h/w 0.487); walk a3 accepted (h/w 0.503). Sit re-cut from its new lineup; it fits the 512x272 cell with the top at row 16.

| asset | previous size (h/w) | new size (h/w) | WOLF height as % of engineer, previous → new |
|---|---|---|---|
| wolf-side-stand | 460 x 205 (0.446) | 460 x 242 (0.526) | 73% → 86% |
| wolf-side-walk | 460 x 202 (0.439) | 478 x 240 (0.502) | 72% → 86% |
| wolf-side-lookback | 460 x 217 (0.472) | 417 x 240 (0.576) | 78% → 86% |
| wolf-sit | 289 x 236 (0.817) | 311 x 248 (0.797) | 84% → 89% |

**2. Engineer three-quarter.** The first version (a1) was a near profile: one eye, profile nose, torso turned only slightly. a2 brought the chest zip, both harness straps, the belt light and the toes toward the viewer and showed both eyes, but turned only about 30 degrees; a3 (selected) used a2 as a "rotate further" reference and turns the face further (far eye larger, nose inside the cheek line, mouth almost frontal). Same costume lock, 280 px tall, baseline 311, hip at x 128, rim 0.35. By eye the torso reads at about 35-40 degrees rather than a full 45. Silhouette IoU against the idle, both placed in the cell: 0.641 (previous 0.662; stride 0.461). For upright figures pinned at the same hip and baseline the outline overlaps heavily whatever the view, so the turn shows mainly inside the silhouette (face, zip, straps, belt light), which the repair panel of the review sheet compares side by side.

Previous finals, their QA and finishing logs, the previous review sheet and notes are kept in `work/repair/previous/`. Scratch comparisons are in `work/repair/`.

## Finishing (ART_BIBLE 5.4-5.5; `hq-tools/finish.py`, `finalize.py`)

1. Native alpha from the built-in tool (bodies arrive at alpha 250-254). Islands under 64 px dropped; pixels 2+ px inside at alpha ≥ 240, and all pixels 3+ px inside, set to 255 (no translucent regions declared).
2. Partial-alpha edge pixels take the colour of the opaque ring 2-4 px inside (no matte, no key spill).
3. Noise budget only where needed: a median filter on opaque RGB at raw resolution (never at final size, never sharpening). The smallest size in 0/3/5/7/9/11 that clears G was used: WOLF stand and walk 9 (about 2.6-2.9 final px), look-back 11 (about 3.1 final px), sit 7 (about 2.9 final px); humans none. At final size a 3x3 median blurred the joints visibly; the raw-size median kept plate edges crisp (compared at 2x).
4. One downscale in premultiplied linear light with Lanczos3 to the exact target (iterated until the α ≥ 128 bounding box hit 280 px tall / 460 px long exactly). WOLF walk, look-back and sit use a fixed factor instead (see WOLF scale above). No upscaling: raw subjects were 5.0-5.3x the final size for the humans, 3.1-3.6x for WOLF and 2.5x for the sitting WOLF.
5. Engineer only: a tapered cyan-white rim (#82c3e6, strength 0.35, 1-4 px, weighted to top and back normals), the same fix the approved v2 engineer received. Without it the engineer passed A-G but its H contrast median in the lamp pool was 1.26-1.33 (under 1.6); with it, 1.78-2.01.
6. Interior alpha re-normalised, edge colours re-matched to the ring, transparent pixels filled with the nearest body colour, placed on the cell by baseline and pivot, saved as 8-bit RGBA PNG.

## QA (`python3 -I art-audit/bible/qa_asset.py`, thresholds unchanged)

Command per asset: `--family character --scale 0.25 --zoom 1.35 --zoom 1.8 --baseline <311|263>`. All nine pass A-G.

| asset | A alpha body | B holes share | B interior band rows | B edge fade rows | C fringe dark | C fringe halo | C edge chroma shift | C outline dL | C top light dL | D baseline | E density 1080 maxzoom | E density 960 minzoom | F cool neutrals b | F accent dE p90 | G noise display | G hf share |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| engineer-side-idle | 1.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | 0.03 | 12.3 | 26.4 | 311 | 1.111 | 2.963 | -2.78 | 12.5 | 4.11 | 0.119 |
| engineer-side-stride | 1.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | 0.04 | 11.2 | 24.7 | 311 | 1.111 | 2.963 | -2.84 | 12.9 | 4.14 | 0.111 |
| engineer-three-quarter | 1.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | 0.03 | 8.1 | 23.3 | 311 | 1.111 | 2.963 | -3.06 | 13.2 | 4.19 | 0.14 |
| wolf-side-stand | 1.0 | 0.0 | 0 | 0 | 0.0 | 0.0006 | 0.02 | 3.2 | 43.3 | 263 | 1.111 | 2.963 | -6.62 | 14.4 | 5.41 | 0.138 |
| wolf-side-lookback | 1.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | 0.01 | 3.7 | 33.8 | 263 | 1.111 | 2.963 | -6.57 | 16.1 | 5.58 | 0.126 |
| wolf-side-walk | 1.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | 0.0 | 5.0 | 35.7 | 263 | 1.111 | 2.963 | -7.29 | 14.9 | 5.9 | 0.139 |
| wolf-sit | 1.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | 0.03 | 4.7 | 42.5 | 263 | 1.111 | 2.963 | -6.61 | 13.0 | 5.76 | 0.15 |
| director-stand-left | 1.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | 0.01 | 2.1 | 32.1 | 311 | 1.111 | 2.963 | -5.73 | 15.1 | 5.07 | 0.138 |
| director-turn-away | 1.0 | 0.0 | 0 | 0 | 0.0 | 0.0 | 0.02 | 7.9 | 43.6 | 311 | 1.111 | 2.963 | -5.37 | 17.7 | 4.26 | 0.135 |

Body L* median: engineer-side-idle 22.7, engineer-side-stride 22.3, engineer-three-quarter 25.3, wolf-side-stand 25.1, wolf-side-lookback 25.7, wolf-side-walk 24.4, wolf-sit 26.1, director-stand-left 18.8, director-turn-away 17.7.

**Supplementary H (pre-check only, not a pass criterion here).** Background `style-test/v2/qa/plate-960.png` (plate only), engineer and Director box 286,0,406,400 (lamp pool), WOLF box 473,0,593,400 (darkest gap), display height = opaque height / 3 (the 960 composite scale).

| asset | lost share (≤ 0.35) | contrast median (≥ 1.6) | perimeter share ≥ 3:1 (target ≥ 0.30) |
|---|---:|---:|---:|
| engineer-side-idle | 0.053 | 1.85 | 0.18 |
| engineer-side-stride | 0.099 | 1.78 | 0.123 |
| engineer-three-quarter | 0.046 | 2.01 | 0.164 |
| wolf-side-stand | 0.153 | 2.01 | 0.321 |
| wolf-side-lookback | 0.143 | 1.95 | 0.309 |
| wolf-side-walk | 0.165 | 1.99 | 0.295 |
| wolf-sit | 0.155 | 2.75 | 0.435 |
| director-stand-left | 0.266 | 1.62 | 0.219 |
| director-turn-away | 0.165 | 1.6 | 0.326 |

Director density at its close-up zoom 1.95 (separate run): 1.026 at 1080p, 2.05 at 960x540, inside the bible limits. G is computed only when the display scale is above 1.05x, so the main QA uses zoom 1.8 for everyone, as the style test did.

**Manual checks (by eye, raw and final):** engineer: the three-quarter shows both eyes, the chest zip, both harness straps, the belt light facing the viewer and toes angled to the viewer's right; brown tousled hair, hood down, deep-red hooded jacket, black harness and belt, one small cyan belt light, black gloves, charcoal cargo trousers with knee straps, dark boots, two arms and two legs in all three views; no yellow patches or silver knees. WOLF: two ears, four legs and four paws countable in stand, look-back and walk; in the repaired stand and walk the head is forward and the tail sweeps down and back as in the design sprite; in the look-back the muzzle points to screen-left; in the sit, both front paws side by side and the hind paws under the haunch; one segmented tail; cyan eye and a few cyan seams; no fur. Director: grey swept-back hair, long charcoal-blue coat, turtleneck, lanyard badge with one small red mark (stand pose; hidden in the turn), black boots, hands in pockets in both poses; the turn-away pose shows no face. No text, floor, cast shadow or second figure in any final.

## Observations and limits

- Director body L* median 17.7-18.8 sits under the bible 3.2 actor band (20-32). That band is not one of the A-G checks; the Director still passes H in the lamp pool. Lift in the cutscene light or regenerate a lighter coat if it reads too dark in Godot.
- WOLF G noise is 5.4-5.9 against the 4.5 target (fail is > 6.0). The plate seams are the cause; the raw median brought it under the fail line without blurring joints.
- Perimeter share at ≥ 3:1 is under the 0.30 target for the engineer (0.12-0.18), the WOLF walk (0.295) and the Director stand (0.22). The repaired WOLF stand, look-back and sit reach 0.31-0.44. It was measured on a plate composite, not a Godot frame.
- The relative scales of walk and look-back are estimates from a rear-region mask match (rear IoU 0.66 and 0.70; the sit lineup check gave 0.89 and agreed with the stand within 1%). Heights agree within 2 px across stand, walk and look-back, which supports them; they are not exact.
- Evidence limits: headless QA and rendered stills only. Nothing was imported into Godot, played, exported or tested on a device. No Git repository or worktree was written.

## Metadata

All 21 raw outputs carry a C2PA `caBX` chunk (14 from the first pass, 7 from the repair) (kept unchanged in `raw/` and under `~/.codex/generated_images/<thread_id>/`). The nine finals and the review sheet contain only IHDR, IDAT and IEND: no C2PA, EXIF, XMP, text or time chunks.

## Every generation, prompt as sent

### engineer-side-idle-a1

- status: Rejected for side idle: body turned toward the viewer (three-quarter), not a strict profile. Usable as an alternate three-quarter view.
- generation id: `exec-dec1febf-b060-4325-b1e8-d548db8aba0d`; thread `01a1281b-c908-7313-8efd-d1b686843369`
- source: `~/.codex/generated_images/01a1281b-c908-7313-8efd-d1b686843369/exec-dec1febf-b060-4325-b1e8-d548db8aba0d.png`; raw copy `raw/engineer-side-idle-a1.png`
- SHA-256: `bd288b30d90409921329b948b053d710199e504969877546aa9120ee3b364fa0`
- references in order: 1 ref-identity-engineer.png (identity) · 2 ref-style-test-v2.png (rendering/edges) · 3 keyart-b.png (mood/light/palette) · 4 palette-card.png (colour)

~~~text
USE CASE: stylized-concept, new asset from identity references (Look 2 re-render of an approved design; do not redesign)
ASSET: canonical identity cut-out of the WOLF//OVERRIDE engineer, a 2D side-view sci-fi horror game; clean graphic-painterly game art readable at small size.
OUTPUT: one portrait PNG with a genuinely transparent background (real alpha). The full figure fills about 85% of the canvas height, centred, with a clear margin above the hair and below the boots. Final game size will be exactly 280 px tall after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = identity: match the character in both panels exactly (face, hair, costume, proportions). The right panel shows the approved Look 2 rendering of this same character; follow it most closely.
Image 2 = the approved Look 2 style test: copy its rendering, value structure and edge treatment only (flat planes, broad rim, cool grade). Do not copy its composition, background or props.
Image 3 = mood, lighting and palette only (cold blue-black, cyan rim, red jacket); do not copy its composition or figures.
Image 4 = colour swatches only; saturated colour must come from these swatches.
SUBJECT: exactly one engineer in a strict orthographic side profile facing screen-right, quiet idle stance: head, chest, hips and boots all point right; one eye in profile; near arm relaxed at the side, far arm mostly hidden behind the body; both boots flat on one level baseline, near leg slightly in front. Exactly two arms and two legs.
IDENTITY LOCKS: short tousled brown hair, hood down; deep-red hooded field jacket (lit #a01e29, shadow #5f0e17) with a chest pocket flap; black shoulder harness straps and black utility belt; one small cyan equipment light on the belt (the only cyan object); black gloves; charcoal cargo trousers with a thigh pocket and dark knee straps; dark boots. No yellow patches, no silver or shiny knee armour, no helmet, hood not up.
LOOK 2 STYLE: shape-first graphic painting. Flat value planes with 3-4 value steps per material; 6-8 large readable value shapes for the whole figure; minimal texture; crisp, shape-designed silhouette; broad rim shapes; painterly soft blending only inside the lit top planes. No dark outline or inked contour anywhere, on the silhouette or inside it: separate forms with adjacent flat values and broad light shapes. No grain, speckle, fabric microtexture, scratches or tiny details (nothing smaller than 6 px at the final 280 px height).
LIGHTING: cold overhead top light, so top-facing planes (hair top, shoulders, tops of arms and boots) are clearly lighter than the body core; a broad cyan-white rim (#82c3e6 to #c3c5d7) along the top and back edges, about 2-3% of the figure height wide, kept fairly even so the sprite can be mirrored. Shadows cool blue-black (#07101a, #121f2c), never brown or neutral grey. Trousers, gloves and boots are graded cool blue-charcoal so the figure sits inside a dark blue corridor.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo or glow outside the silhouette.
DO NOT: floor, ground plane, cast or contact shadow, reflection, background, extra figure, extra or missing limbs, three-quarter or frontal pose, motion lines, magenta or pink, text.
~~~

### director-stand-left-a1-1

- status: Not selected: shoulders slightly turned toward the viewer; a1-2 is the closer profile with lower display noise (5.07 vs 5.42).
- generation id: `exec-04a604b7-6538-4b31-a3e4-e8f51c430de1`; thread `01a1281b-d88a-7451-93b7-bec93bb80358`
- source: `~/.codex/generated_images/01a1281b-d88a-7451-93b7-bec93bb80358/exec-04a604b7-6538-4b31-a3e4-e8f51c430de1.png`; raw copy `raw/director-stand-left-a1-1.png`
- SHA-256: `6327654de68c35ce02212bfae1d2c370c9e49a13beb886e36a346172ccfc86a2`
- references in order: 1 ref-identity-director.png (identity; left panel only) · 2 ref-style-test-v2.png · 3 keyart-b.png · 4 palette-card.png

~~~text
USE CASE: stylized-concept, new asset from identity references (Look 2 re-render of an approved design; do not redesign)
ASSET: canonical identity cut-out of the Director, the human antagonist in WOLF//OVERRIDE, a 2D side-view sci-fi horror game; clean graphic-painterly game art readable at small size.
OUTPUT: one portrait PNG with a genuinely transparent background (real alpha). The full figure fills about 85% of the canvas height, centred, with a clear margin above the hair and below the boots. Final game size will be exactly 280 px tall after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = identity: the LEFT panel is the Director; match face, hair, coat, proportions and pose exactly. The RIGHT panel is a different character; use it only as an example of the Look 2 rendering of a human figure (flat planes, top light, cyan rim). Do not copy that character's clothes, colours or face.
Image 2 = the approved Look 2 style test: rendering, value structure and edge treatment only. Do not copy its composition, background or props.
Image 3 = mood, lighting and palette only (cold blue-black, cyan rim); do not copy its composition or figures.
Image 4 = colour swatches only.
SUBJECT: exactly one person, the Director, in a strict orthographic side profile facing screen-LEFT, standing still and upright, both hands in the coat pockets, stern expression, both boots flat on one level baseline. Exactly two arms and two legs.
IDENTITY LOCKS: swept-back short grey hair; stern older face with a strong brow; long dark charcoal-blue overcoat to below the knee with wide lapels and cuffed sleeves; dark turtleneck; a lanyard with a small ID badge carrying one small red mark (the only red, a tiny practical accent); dark trousers; black lace-up boots. Low chroma everywhere else.
LOOK 2 STYLE: shape-first graphic painting. Flat value planes with 3-4 value steps per material; 6-8 large readable value shapes for the whole figure; the long coat reads as two or three broad planes; minimal texture; crisp shape-designed silhouette; broad rim shapes; painterly soft blending only inside the lit top planes. No dark outline or inked contour anywhere, on the silhouette or inside it. No grain, speckle, fabric microtexture, scratches or details smaller than 6 px at the final 280 px height.
LIGHTING: cold overhead top light, so the hair, shoulders and top-facing coat planes are clearly lighter than the body core; a broad cyan-white rim (#82c3e6 to #c3c5d7) along the top and back edges (the back is screen-right here), kept fairly even so the sprite can be mirrored. Shadows cool blue-black (#07101a, #121f2c), never brown or neutral grey. The coat is graded cool so the figure sits inside a dark blue corridor while staying readable.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo or glow outside the silhouette.
DO NOT: floor, cast or contact shadow, reflection, background, extra figure, extra or missing limbs, facing right, frontal or three-quarter pose, readable text on the badge, magenta or pink, text.
~~~

### director-stand-left-a1-2

- status: SELECTED -> director-stand-left.png
- generation id: `exec-68b2de19-46ed-4b58-bd58-1e46e131f3cb`; thread `01a1281b-d88a-7451-93b7-bec93bb80358`
- source: `~/.codex/generated_images/01a1281b-d88a-7451-93b7-bec93bb80358/exec-68b2de19-46ed-4b58-bd58-1e46e131f3cb.png`; raw copy `raw/director-stand-left-a1-2.png`
- SHA-256: `ab274c78e5a9709c1f2c857e509be90105239647d0235a1024a778749c0030df`
- references in order: 1 ref-identity-director.png (identity; left panel only) · 2 ref-style-test-v2.png · 3 keyart-b.png · 4 palette-card.png

~~~text
USE CASE: stylized-concept, new asset from identity references (Look 2 re-render of an approved design; do not redesign)
ASSET: canonical identity cut-out of the Director, the human antagonist in WOLF//OVERRIDE, a 2D side-view sci-fi horror game; clean graphic-painterly game art readable at small size.
OUTPUT: one portrait PNG with a genuinely transparent background (real alpha). The full figure fills about 85% of the canvas height, centred, with a clear margin above the hair and below the boots. Final game size will be exactly 280 px tall after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = identity: the LEFT panel is the Director; match face, hair, coat, proportions and pose exactly. The RIGHT panel is a different character; use it only as an example of the Look 2 rendering of a human figure (flat planes, top light, cyan rim). Do not copy that character's clothes, colours or face.
Image 2 = the approved Look 2 style test: rendering, value structure and edge treatment only. Do not copy its composition, background or props.
Image 3 = mood, lighting and palette only (cold blue-black, cyan rim); do not copy its composition or figures.
Image 4 = colour swatches only.
SUBJECT: exactly one person, the Director, in a strict orthographic side profile facing screen-LEFT, standing still and upright, both hands in the coat pockets, stern expression, both boots flat on one level baseline. Exactly two arms and two legs.
IDENTITY LOCKS: swept-back short grey hair; stern older face with a strong brow; long dark charcoal-blue overcoat to below the knee with wide lapels and cuffed sleeves; dark turtleneck; a lanyard with a small ID badge carrying one small red mark (the only red, a tiny practical accent); dark trousers; black lace-up boots. Low chroma everywhere else.
LOOK 2 STYLE: shape-first graphic painting. Flat value planes with 3-4 value steps per material; 6-8 large readable value shapes for the whole figure; the long coat reads as two or three broad planes; minimal texture; crisp shape-designed silhouette; broad rim shapes; painterly soft blending only inside the lit top planes. No dark outline or inked contour anywhere, on the silhouette or inside it. No grain, speckle, fabric microtexture, scratches or details smaller than 6 px at the final 280 px height.
LIGHTING: cold overhead top light, so the hair, shoulders and top-facing coat planes are clearly lighter than the body core; a broad cyan-white rim (#82c3e6 to #c3c5d7) along the top and back edges (the back is screen-right here), kept fairly even so the sprite can be mirrored. Shadows cool blue-black (#07101a, #121f2c), never brown or neutral grey. The coat is graded cool so the figure sits inside a dark blue corridor while staying readable.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo or glow outside the silhouette.
DO NOT: floor, cast or contact shadow, reflection, background, extra figure, extra or missing limbs, facing right, frontal or three-quarter pose, readable text on the badge, magenta or pink, text.
~~~

### engineer-side-idle-a2

- status: SELECTED -> engineer-side-idle.png
- generation id: `exec-72d3373a-aee0-41ab-99f8-d737ad434bd4`; thread `01a1281e-d274-7960-a0f2-2c6d7f378d4b`
- source: `~/.codex/generated_images/01a1281e-d274-7960-a0f2-2c6d7f378d4b/exec-72d3373a-aee0-41ab-99f8-d737ad434bd4.png`; raw copy `raw/engineer-side-idle-a2.png`
- SHA-256: `52abcbf041c324bfdb7dc44e64dd7a1e5b34b7315f60cc8474945ca15573962f`
- references in order: Image 1 = hq/characters/refs/ref-identity-engineer.png (identity: left = original approved design sprite, right = approved Look 2 render of the same character) · Image 2 = hq/characters/refs/ref-style-test-v2.png (rendering and edge treatment: the approved Look 2 style test) · Image 3 = scratchpad/art/keyart/keyart-b.png (mood, light and palette) · Image 4 = hq/characters/refs/palette-card.png (colour swatches)

~~~text
USE CASE: stylized-concept, new asset from identity references (Look 2 re-render of an approved design; do not redesign)
ASSET: canonical identity cut-out of the WOLF//OVERRIDE engineer, a 2D side-view sci-fi horror game; clean graphic-painterly game art readable at small size.
OUTPUT: one portrait PNG with a genuinely transparent background (real alpha). The full figure fills about 85% of the canvas height, centred, with a clear margin above the hair and below the boots. Final game size will be exactly 280 px tall after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = identity: match the character in both panels exactly (face, hair, costume, proportions). The right panel shows the approved Look 2 rendering of this same character; follow it most closely.
Image 2 = the approved Look 2 style test: copy its rendering, value structure and edge treatment only (flat planes, broad rim, cool grade). Do not copy its composition, background or props.
Image 3 = mood, lighting and palette only (cold blue-black, cyan rim, red jacket); do not copy its composition or figures.
Image 4 = colour swatches only; saturated colour must come from these swatches.
SUBJECT: exactly one engineer in a STRICT orthographic side profile facing screen-right, quiet idle stance. This is a true 90-degree side view, not three-quarter: the camera sees the engineer's right flank; the face is a pure profile with one eye, nose and chin on the right edge of the head; the jacket front and zipper edge form the right edge of the torso and the back and harness straps the left edge; the chest and hips point right, not toward the viewer. The near (right) arm hangs relaxed at the side covering the flank; the far arm is almost completely hidden behind the body. Both boots point right and stand flat on one level baseline, the near leg slightly in front of and overlapping the far leg. Exactly two arms and two legs. The Look 2 render in Image 1's right panel shows this exact side view; match its pose.
IDENTITY LOCKS: short tousled brown hair, hood down; deep-red hooded field jacket (lit #a01e29, shadow #5f0e17) with a chest pocket flap; black shoulder harness straps and black utility belt; one small cyan equipment light on the belt (the only cyan object); black gloves; charcoal cargo trousers with a thigh pocket and dark knee straps; dark boots. No yellow patches, no silver or shiny knee armour, no helmet, hood not up.
LOOK 2 STYLE: shape-first graphic painting. Flat value planes with 3-4 value steps per material; 6-8 large readable value shapes for the whole figure; minimal texture; crisp, shape-designed silhouette; broad rim shapes; painterly soft blending only inside the lit top planes. No dark outline or inked contour anywhere, on the silhouette or inside it: separate forms with adjacent flat values and broad light shapes. No grain, speckle, fabric microtexture, scratches or tiny details (nothing smaller than 6 px at the final 280 px height).
LIGHTING: cold overhead top light, so top-facing planes (hair top, shoulders, tops of arms and boots) are clearly lighter than the body core; a broad cyan-white rim (#82c3e6 to #c3c5d7) along the top and back edges, about 2-3% of the figure height wide, kept fairly even so the sprite can be mirrored. Shadows cool blue-black (#07101a, #121f2c), never brown or neutral grey. Trousers, gloves and boots are graded cool blue-charcoal so the figure sits inside a dark blue corridor.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo or glow outside the silhouette.
DO NOT: floor, ground plane, cast or contact shadow, reflection, background, extra figure, extra or missing limbs, three-quarter or frontal pose, visible chest or jacket front facing the viewer, motion lines, magenta or pink, text.
~~~

### wolf-side-stand-a1

- status: Rejected for side stand: head turned back toward screen-left instead of forward. Its head turn became the pose guide for wolf-side-lookback-a2.
- generation id: `exec-44f0c282-9d4c-4074-a78a-e0cebe50e42b`; thread `01a1281e-db19-72f2-b917-0f4c45068c7d`
- source: `~/.codex/generated_images/01a1281e-db19-72f2-b917-0f4c45068c7d/exec-44f0c282-9d4c-4074-a78a-e0cebe50e42b.png`; raw copy `raw/wolf-side-stand-a1.png`
- SHA-256: `8df199e17c44494c7c6b6435ae092a3d7f264f451ae150a00c36453d2d4c6cd6`
- references in order: Image 1 = hq/characters/refs/ref-identity-wolf.png (identity: left = original approved design sprite, right = approved Look 2 render of WOLF) · Image 2 = hq/characters/refs/ref-style-test-v2.png (rendering and edges: the approved Look 2 style test) · Image 3 = scratchpad/art/keyart/keyart-b.png (mood, light and palette) · Image 4 = hq/characters/refs/palette-card.png (colour swatches)

~~~text
USE CASE: stylized-concept, new asset from identity references (Look 2 re-render of an approved design; do not redesign)
ASSET: canonical identity cut-out of WOLF, the robotic wolf companion in WOLF//OVERRIDE, a 2D side-view sci-fi horror game; clean graphic-painterly game art readable at small size.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha). WOLF fills about 88% of the canvas width, centred, fully inside the frame with a clear margin. Final game size will be exactly 460 px long nose-to-tail-tip after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = identity: match WOLF in both panels exactly (head shape, armour plate layout, joints, tail, proportions). The right panel is the approved Look 2 rendering; follow its rendering most closely and the left panel's head-forward profile.
Image 2 = the approved Look 2 style test: rendering, value structure and edge treatment only. Do not copy its composition, background or props.
Image 3 = mood, lighting and palette only (cold blue-black, cyan rim); do not copy its composition or figures.
Image 4 = colour swatches only.
SUBJECT: exactly one fully robotic wolf in a strict orthographic side view facing screen-right, standing still, head forward in profile looking right, ears up. Long, low canine silhouette: nose-to-tail length at least 1.85 times the ear-tip-to-paw height. All four paws flat on one level baseline, near and far legs slightly staggered so all four legs and four paws are countable.
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws; circular mechanical joints at shoulders, hips, elbows and hocks; grey-blue angular armour plates of low chroma (lit about #656a72, mid about #292f37); one articulated, segmented armoured tail; one cyan eye; restrained cyan seam lights (#4f8ab8 to #30d0fc) only on a few plate seams. Fully robotic: no fur, no organic anatomy, no harness, no collar.
LOOK 2 STYLE: shape-first graphic painting. Flat value planes with 3-4 value steps per material; large simplified armour plates; minimal texture; crisp shape-designed silhouette; broad rim shapes; painterly soft blending only inside the lit top planes. No dark outline or inked contour anywhere, on the silhouette or between plates: separate plates with adjacent flat values. No grain, speckle, scratches, tiny bolts or details smaller than 6 px at the final 460 px length.
LIGHTING: cold overhead top light, so the back, head top and top faces of plates are clearly lighter than the body core; a broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edge of the head, neck, back and tail, kept fairly even so the sprite can be mirrored. Shadows cool blue-black (#07101a, #121f2c), never brown or warm.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo or glow outside the silhouette.
DO NOT: floor, cast or contact shadow, reflection, background, extra ears, legs, paws or tails, fur, motion lines, magenta or pink, text.
~~~

### engineer-side-stride-a1

- status: SELECTED -> engineer-side-stride.png
- generation id: `exec-e9688280-4f80-45f4-92f7-bf10ede73c94`; thread `01a12820-9071-7b91-9b65-aa48a38ced23`
- source: `~/.codex/generated_images/01a12820-9071-7b91-9b65-aa48a38ced23/exec-e9688280-4f80-45f4-92f7-bf10ede73c94.png`; raw copy `raw/engineer-side-stride-a1.png`
- SHA-256: `0fe834dbdd0dc69cb64cc5212d1d71478d5e8f63d937eabf69e30ef791f15bb9`
- references in order: Image 1 = scratchpad/hq/characters/raw/engineer-side-idle-a2.png (the new Look 2 identity) · Image 2 = hq/characters/refs/ref-identity-engineer.png · Image 3 = hq/characters/refs/ref-style-test-v2.png · Image 4 = scratchpad/art/keyart/keyart-b.png · Image 5 = hq/characters/refs/palette-card.png

~~~text
USE CASE: stylized-concept, identity-preserving new pose (do not redesign)
ASSET: identity cut-out of the WOLF//OVERRIDE engineer walking, Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one portrait PNG with a genuinely transparent background (real alpha). The full figure fills about 85% of the canvas height, centred, with a clear margin on every side. Final game size will be exactly 280 px tall after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same engineer, same face, hair, costume, colours, proportions, rendering and lighting. Change only the pose.
Image 2 = design source (original sprite left, approved Look 2 render right); use for costume details only.
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: exactly one engineer in a strict orthographic side profile facing screen-right, mid-stride in a calm walk (the contact pose): front leg reaching forward with the heel touching the ground, back leg extended behind with the toe pushing off, both boots touching the same level baseline; arms swing opposite to the legs (near arm back, far arm forward and partly hidden); torso upright, head level, looking right. Exactly two arms and two legs; far-side limbs one value step darker than near-side limbs.
IDENTITY LOCKS: short tousled brown hair, hood down; deep-red hooded field jacket (lit #a01e29, shadow #5f0e17); black shoulder harness straps and utility belt; one small cyan belt equipment light; black gloves; charcoal cargo trousers with thigh pocket and dark knee straps; dark boots. No yellow patches, no silver knee armour.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, 6-8 large value shapes, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top-facing planes lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) on the top and back edges; cool blue-black shadows, never brown or grey.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, motion lines, extra figure, extra or missing limbs, three-quarter pose, magenta or pink, text.
~~~

### director-turn-away-a1

- status: SELECTED -> director-turn-away.png
- generation id: `exec-640e3fed-f208-4667-9314-d5e9278502ff`; thread `01a12820-9067-7c83-8c53-2e36e420d0f1`
- source: `~/.codex/generated_images/01a12820-9067-7c83-8c53-2e36e420d0f1/exec-640e3fed-f208-4667-9314-d5e9278502ff.png`; raw copy `raw/director-turn-away-a1.png`
- SHA-256: `fd7c7a2e47eb78854cc481cbb919387e74cfb5a2b05be59a5cc8aea10e7d80f6`
- references in order: Image 1 = scratchpad/hq/characters/raw/director-stand-left-a1-2.png (the new Look 2 identity) · Image 2 = hq/characters/refs/ref-identity-director.png · Image 3 = hq/characters/refs/ref-style-test-v2.png · Image 4 = scratchpad/art/keyart/keyart-b.png · Image 5 = hq/characters/refs/palette-card.png

~~~text
USE CASE: stylized-concept, identity-preserving new pose (do not redesign)
ASSET: identity cut-out of the Director turning away, Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one portrait PNG with a genuinely transparent background (real alpha). The full figure fills about 85% of the canvas height, centred, with a clear margin on every side. Final game size will be exactly 280 px tall after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same Director, same hair, coat, colours, proportions, rendering and lighting. Change only the pose and viewing angle.
Image 2 = design source: LEFT panel is the Director; the RIGHT panel is a different character shown only as a rendering example. Do not copy the right panel's clothes or colours.
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: exactly one person, the Director, caught mid-turn while turning away from the viewer: previously facing screen-left, now rotating toward the back wall, seen in a rear three-quarter view. The back and one shoulder of the long coat dominate the silhouette; the head is turned away so only the ear, the edge of the jaw and the back of the grey hair are visible, no face. Hands stay in the coat pockets; the coat hem swings slightly with the turn; both boots on one level baseline, one heel lifting as the weight shifts. Exactly two arms and two legs.
IDENTITY LOCKS: swept-back short grey hair; long dark charcoal-blue overcoat to below the knee with wide lapels and cuffed sleeves; dark turtleneck collar; dark trousers; black lace-up boots. The badge may be hidden. Low chroma everywhere.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, 6-8 large value shapes, the coat as two or three broad planes, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top-facing planes lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) along the top and back edges; cool blue-black shadows, never brown or grey.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, motion lines, extra figure, extra or missing limbs, visible face, frontal pose, magenta or pink, text.
~~~

### engineer-three-quarter-a1

- status: Superseded in the repair: near profile (one eye, profile nose, torso turned only 10-15 degrees further than the idle).
- generation id: `exec-06a919e4-cfe2-4940-b6bb-e5e70e8a8be2`; thread `01a12820-9146-7323-95ba-fe001a3c530b`
- source: `~/.codex/generated_images/01a12820-9146-7323-95ba-fe001a3c530b/exec-06a919e4-cfe2-4940-b6bb-e5e70e8a8be2.png`; raw copy `raw/engineer-three-quarter-a1.png`
- SHA-256: `b53bc684e555c44c2d0cb3836fb7274a483d45c4eb0a115b10ac65b231dd52e5`
- references in order: Image 1 = scratchpad/hq/characters/raw/engineer-side-idle-a2.png (the new Look 2 identity) · Image 2 = hq/characters/refs/ref-identity-engineer.png · Image 3 = hq/characters/refs/ref-style-test-v2.png · Image 4 = scratchpad/art/keyart/keyart-b.png · Image 5 = hq/characters/refs/palette-card.png

~~~text
USE CASE: stylized-concept, identity-preserving new view (do not redesign)
ASSET: three-quarter identity view of the WOLF//OVERRIDE engineer, Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one portrait PNG with a genuinely transparent background (real alpha). The full figure fills about 85% of the canvas height, centred, with a clear margin on every side. Final game size will be exactly 280 px tall after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same engineer, same face, hair, costume, colours, proportions, rendering and lighting. Change only the viewing angle.
Image 2 = design source (original sprite left, approved Look 2 render right); its left panel shows the costume from a near three-quarter angle; use it for costume details.
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: exactly one engineer in a front three-quarter view: body turned about 45 degrees toward the viewer while facing screen-right, quiet idle stance, eye level, no perspective distortion. Face visible in three-quarter; both arms relaxed at the sides; both boots flat on one level baseline. The jacket front, harness straps, belt and the small cyan belt light are visible. Exactly two arms and two legs.
IDENTITY LOCKS: short tousled brown hair, hood down; deep-red hooded field jacket (lit #a01e29, shadow #5f0e17); black shoulder harness straps and utility belt; one small cyan belt equipment light; black gloves; charcoal cargo trousers with thigh pocket and dark knee straps; dark boots. No yellow patches, no silver knee armour.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, 6-8 large value shapes, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top-facing planes lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) on the top and back edges; cool blue-black shadows, never brown or grey.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, extra figure, extra or missing limbs, strict side profile, frontal pose, magenta or pink, text.
~~~

### wolf-side-stand-a2

- status: Superseded in the repair: proportions drifted (h/w 0.446; legs short, head low, tail held level), WOLF only 73% of the engineer height.
- generation id: `exec-e3462c88-7bb1-4cdf-b98b-8bf4a9e0aea3`; thread `01a12820-928d-7320-a8fa-3b8b37064367`
- source: `~/.codex/generated_images/01a12820-928d-7320-a8fa-3b8b37064367/exec-e3462c88-7bb1-4cdf-b98b-8bf4a9e0aea3.png`; raw copy `raw/wolf-side-stand-a2.png`
- SHA-256: `2e0e95eb9f8cfafdcf12256e65f580f1ec1477b5fc850398dafadd3ddbe7ebc0`
- references in order: Image 1 = hq/characters/refs/ref-identity-wolf.png (identity: left = original approved design sprite, right = approved Look 2 render of WOLF) · Image 2 = hq/characters/refs/ref-style-test-v2.png (rendering and edges: the approved Look 2 style test) · Image 3 = scratchpad/art/keyart/keyart-b.png (mood, light and palette) · Image 4 = hq/characters/refs/palette-card.png (colour swatches)

~~~text
USE CASE: stylized-concept, new asset from identity references (Look 2 re-render of an approved design; do not redesign)
ASSET: canonical identity cut-out of WOLF, the robotic wolf companion in WOLF//OVERRIDE, a 2D side-view sci-fi horror game; clean graphic-painterly game art readable at small size.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha). WOLF fills about 88% of the canvas width, centred, fully inside the frame with a clear margin. Final game size will be exactly 460 px long nose-to-tail-tip after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = identity: match WOLF in both panels exactly (head shape, armour plate layout, joints, tail, proportions). The right panel is the approved Look 2 rendering: follow its rendering and plate style. The LEFT panel shows the required head-forward pose: copy its pose, head and neck angle.
Image 2 = the approved Look 2 style test: rendering, value structure and edge treatment only. Do not copy its composition, background or props.
Image 3 = mood, lighting and palette only (cold blue-black, cyan rim); do not copy its composition or figures.
Image 4 = colour swatches only.
SUBJECT: exactly one fully robotic wolf in a strict orthographic side view facing screen-right, standing still, with the HEAD FACING FORWARD in pure profile: the muzzle points straight to screen-right, ahead of the chest, exactly like the left panel of Image 1 (the original design sprite). The head is NOT turned back and NOT turned toward the viewer: one eye visible in profile, nose at the far right of the silhouette, ears up and pointing up/back. Long, low canine silhouette: nose-to-tail length at least 1.85 times the ear-tip-to-paw height; the tail extends straight back to screen-left. All four paws flat on one level baseline, near and far legs slightly staggered so all four legs and four paws are countable.
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws; circular mechanical joints at shoulders, hips, elbows and hocks; grey-blue angular armour plates of low chroma (lit about #656a72, mid about #292f37); one articulated, segmented armoured tail; one cyan eye; restrained cyan seam lights (#4f8ab8 to #30d0fc) only on a few plate seams. Fully robotic: no fur, no organic anatomy, no harness, no collar.
LOOK 2 STYLE: shape-first graphic painting. Flat value planes with 3-4 value steps per material; large simplified armour plates; minimal texture; crisp shape-designed silhouette; broad rim shapes; painterly soft blending only inside the lit top planes. No dark outline or inked contour anywhere, on the silhouette or between plates: separate plates with adjacent flat values. No grain, speckle, scratches, tiny bolts or details smaller than 6 px at the final 460 px length.
LIGHTING: cold overhead top light, so the back, head top and top faces of plates are clearly lighter than the body core; a broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edge of the head, neck, back and tail, kept fairly even so the sprite can be mirrored. Shadows cool blue-black (#07101a, #121f2c), never brown or warm.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo or glow outside the silhouette.
DO NOT: head turned back or toward the viewer, floor, cast or contact shadow, reflection, background, extra ears, legs, paws or tails, fur, motion lines, magenta or pink, text.
~~~

### wolf-side-lookback-a1

- status: Rejected: head only slightly turned, muzzle still points right.
- generation id: `exec-e0d0f54a-2e43-4254-b046-be06832c692f`; thread `01a12822-803a-7ee2-af60-5cb7e7596e75`
- source: `~/.codex/generated_images/01a12822-803a-7ee2-af60-5cb7e7596e75/exec-e0d0f54a-2e43-4254-b046-be06832c692f.png`; raw copy `raw/wolf-side-lookback-a1.png`
- SHA-256: `f8144c9c5253deef46d851187caf999091046ca9367c4266d0343b41582c91fd`
- references in order: Image 1 = scratchpad/hq/characters/raw/wolf-side-stand-a2.png (the new Look 2 identity) · Image 2 = hq/characters/refs/ref-identity-wolf.png · Image 3 = hq/characters/refs/ref-style-test-v2.png · Image 4 = scratchpad/art/keyart/keyart-b.png · Image 5 = hq/characters/refs/palette-card.png

~~~text
USE CASE: stylized-concept, identity-preserving new pose (do not redesign)
ASSET: identity cut-out of WOLF, the robotic wolf companion in WOLF//OVERRIDE, looking back; Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha). WOLF fills about 88% of the canvas width, centred, fully inside the frame with a clear margin. Final game size will be exactly 460 px long after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same WOLF, same armour plates, joints, tail, colours, proportions, rendering and lighting. Change only the head and neck pose.
Image 2 = design source (original sprite left, approved Look 2 render right); its right panel shows a turned head.
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; its robotic wolf looks back over its shoulder toward the engineer: use that idea for the head turn only, not its composition.
Image 5 = colour swatches only.
SUBJECT: exactly one robotic wolf, body and legs in a strict side view facing screen-right, standing still on all four paws on one level baseline, with the neck bent and the head turned back over its shoulder so the muzzle points toward screen-left, looking behind itself; the cyan eye and both ears visible; the tail relaxed behind. Long, low silhouette as in Image 1.
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws, all countable; circular mechanical joints; grey-blue low-chroma angular armour plates; one articulated segmented armoured tail; one cyan eye; restrained cyan seam lights only on a few seams. No fur, no harness, no collar.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, large simplified plates, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches, tiny bolts or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top faces lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edges; cool blue-black shadows, never brown.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, extra ears, legs, paws or tails, fur, motion lines, magenta or pink, text.
~~~

### wolf-side-walk-a1

- status: Superseded in the repair (chained from the drifted stand a2).
- generation id: `exec-03fc727b-a6ad-4a45-b2d9-0aadd3537827`; thread `01a12822-803b-7722-a491-f94e47c7d794`
- source: `~/.codex/generated_images/01a12822-803b-7722-a491-f94e47c7d794/exec-03fc727b-a6ad-4a45-b2d9-0aadd3537827.png`; raw copy `raw/wolf-side-walk-a1.png`
- SHA-256: `882fa749e26c6a28b192ec430669c10301860ae9c9c880da35221f5f5ec0c52b`
- references in order: Image 1 = scratchpad/hq/characters/raw/wolf-side-stand-a2.png (the new Look 2 identity) · Image 2 = hq/characters/refs/ref-identity-wolf.png · Image 3 = hq/characters/refs/ref-style-test-v2.png · Image 4 = scratchpad/art/keyart/keyart-b.png · Image 5 = hq/characters/refs/palette-card.png

~~~text
USE CASE: stylized-concept, identity-preserving new pose (do not redesign)
ASSET: identity cut-out of WOLF, the robotic wolf companion in WOLF//OVERRIDE, walking; Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha). WOLF fills about 88% of the canvas width, centred, fully inside the frame with a clear margin. Final game size will be exactly 460 px long after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same WOLF, same armour plates, joints, tail, colours, proportions, rendering and lighting. Change only the leg pose.
Image 2 = design source (original sprite left, approved Look 2 render right).
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: exactly one robotic wolf in a strict side view facing screen-right, mid-stride in a calm walk: near foreleg reaching forward, near hind leg extended back, far legs in the opposite phase; one paw lifted slightly, the other three paws touching one level baseline; back level, head forward in profile looking right, ears up, tail held straight out behind. All four legs and all four paws countable. Long, low silhouette as in Image 1.
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws; circular mechanical joints; grey-blue low-chroma angular armour plates; one articulated segmented armoured tail; one cyan eye; restrained cyan seam lights only on a few seams. No fur, no harness, no collar.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, large simplified plates, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches, tiny bolts or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top faces lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edges; cool blue-black shadows, never brown.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, extra ears, legs, paws or tails, fur, motion lines or blur, magenta or pink, text.
~~~

### wolf-sit-a1

- status: Rejected: far foreleg and its paw hidden behind the near foreleg (paw count not verifiable).
- generation id: `exec-498f34ae-f6fc-4530-b98c-968d42e7e172`; thread `01a12822-803a-7d92-959a-2e77e8ec85b6`
- source: `~/.codex/generated_images/01a12822-803a-7d92-959a-2e77e8ec85b6/exec-498f34ae-f6fc-4530-b98c-968d42e7e172.png`; raw copy `raw/wolf-sit-a1.png`
- SHA-256: `7e68a239522c5618401a946588420b8c6162e71d431f57e908b4ae2cdeecd677`
- references in order: Image 1 = scratchpad/hq/characters/raw/wolf-side-stand-a2.png (the new Look 2 identity) · Image 2 = hq/characters/refs/ref-identity-wolf.png · Image 3 = hq/characters/refs/ref-style-test-v2.png · Image 4 = scratchpad/art/keyart/keyart-b.png · Image 5 = hq/characters/refs/palette-card.png

~~~text
USE CASE: stylized-concept, identity-preserving new pose shown in a same-scale lineup (do not redesign)
ASSET: scale lineup of WOLF, the robotic wolf companion in WOLF//OVERRIDE; Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha), containing exactly two copies of the same WOLF at exactly the same scale, standing on one shared level baseline, separated by a clear empty gap of at least 8% of the canvas width. Both are fully inside the frame with a clear margin. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity and the exact scale reference: the same WOLF, same armour plates, joints, tail, colours, proportions, rendering and lighting.
Image 2 = design source (original sprite left, approved Look 2 render right).
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: LEFT = WOLF standing exactly as in Image 1, strict side view facing screen-right, all four paws on the baseline. RIGHT = the same WOLF at exactly the same scale, sitting upright in strict side view facing screen-right: haunches and hind legs folded on the floor, forelegs straight and vertical with both front paws on the baseline, chest up, head up in profile looking right, ears up, the segmented tail lying along the floor behind and curving forward. In the sitting WOLF, two ears, four legs and four paws remain countable (far legs partly hidden but visible).
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws; circular mechanical joints; grey-blue low-chroma angular armour plates; one articulated segmented armoured tail; one cyan eye; restrained cyan seam lights only on a few seams. No fur, no harness, no collar.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, large simplified plates, minimal texture, crisp shape-designed silhouettes, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches, tiny bolts.
LIGHTING: identical to Image 1: cold overhead top light, top faces lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edges; cool blue-black shadows, never brown.
TRANSPARENCY: fully opaque bodies; crisp 1-2 px anti-aliased edges; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, a third figure, overlapping figures, extra ears, legs, paws or tails, fur, magenta or pink, text.
~~~

### wolf-side-lookback-a2

- status: Superseded in the repair (chained from the drifted stand a2).
- generation id: `exec-4bd77233-ea17-45d9-a212-00e90b17b52f`; thread `01a12824-2261-7121-9375-05a67b81f2ac`
- source: `~/.codex/generated_images/01a12824-2261-7121-9375-05a67b81f2ac/exec-4bd77233-ea17-45d9-a212-00e90b17b52f.png`; raw copy `raw/wolf-side-lookback-a2.png`
- SHA-256: `394d2406b232d220569716dce44cd22cf5e4e11515a62d9ffbade1133ad9cf81`
- references in order: Image 1 = scratchpad/hq/characters/raw/wolf-side-stand-a2.png (the new Look 2 identity) · Image 2 = hq/characters/refs/ref-wolf-lookback-board.png (top: the identity board, original design sprite left and approved Look 2 render right; bottom: a head-turn pose guide) · Image 3 = hq/characters/refs/ref-style-test-v2.png · Image 4 = scratchpad/art/keyart/keyart-b.png · Image 5 = hq/characters/refs/palette-card.png

~~~text
USE CASE: stylized-concept, identity-preserving new pose (do not redesign)
ASSET: identity cut-out of WOLF, the robotic wolf companion in WOLF//OVERRIDE, looking back; Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha). WOLF fills about 88% of the canvas width, centred, fully inside the frame with a clear margin. Final game size will be exactly 460 px long after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same WOLF, same armour plates, joints, tail, colours, proportions, rendering and lighting. Change only the head and neck pose.
Image 2 = design source and pose guide: the top row is the identity board (original sprite left, approved Look 2 render right); the large WOLF in the bottom row shows the REQUIRED head turn: copy its head and neck pose exactly, with the muzzle pointing to screen-left.
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; its robotic wolf looks back over its shoulder toward the engineer: use that idea for the head turn only, not its composition.
Image 5 = colour swatches only.
SUBJECT: exactly one robotic wolf, body and legs in a strict side view facing screen-right, standing still on all four paws on one level baseline. The neck is bent and the head is turned all the way back over the shoulder: the MUZZLE POINTS TO SCREEN-LEFT, toward the tail, so the nose is to the left of the ears and the face is seen in three-quarter from the front, looking behind itself at someone following. The cyan eye(s) and both ears are visible. The tail is relaxed behind. Copy the head-turn pose of the bottom WOLF in Image 2; keep the body, legs and tail of Image 1. Long, low silhouette as in Image 1.
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws, all countable; circular mechanical joints; grey-blue low-chroma angular armour plates; one articulated segmented armoured tail; one cyan eye; restrained cyan seam lights only on a few seams. No fur, no harness, no collar.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, large simplified plates, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches, tiny bolts or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top faces lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edges; cool blue-black shadows, never brown.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: head facing forward or to screen-right, floor, cast or contact shadow, reflection, background, extra ears, legs, paws or tails, fur, motion lines, magenta or pink, text.
~~~

### wolf-sit-a2

- status: Superseded in the repair (scale lineup built on the drifted stand a2).
- generation id: `exec-db69c42a-a173-4db8-826c-96209bf4e817`; thread `01a12825-a761-70a1-83cf-a01e0cad753e`
- source: `~/.codex/generated_images/01a12825-a761-70a1-83cf-a01e0cad753e/exec-db69c42a-a173-4db8-826c-96209bf4e817.png`; raw copy `raw/wolf-sit-a2.png`
- SHA-256: `a4815d7df2c21bec98adcf09bff87802dd2d0efb8f419e6b62883211e7e54d4f`
- references in order: Image 1 = scratchpad/hq/characters/raw/wolf-side-stand-a2.png (the new Look 2 identity) · Image 2 = hq/characters/refs/ref-identity-wolf.png · Image 3 = hq/characters/refs/ref-style-test-v2.png · Image 4 = scratchpad/art/keyart/keyart-b.png · Image 5 = hq/characters/refs/palette-card.png

~~~text
USE CASE: stylized-concept, identity-preserving new pose shown in a same-scale lineup (do not redesign)
ASSET: scale lineup of WOLF, the robotic wolf companion in WOLF//OVERRIDE; Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha), containing exactly two copies of the same WOLF at exactly the same scale, standing on one shared level baseline, separated by a clear empty gap of at least 8% of the canvas width. Both are fully inside the frame with a clear margin. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity and the exact scale reference: the same WOLF, same armour plates, joints, tail, colours, proportions, rendering and lighting.
Image 2 = design source (original sprite left, approved Look 2 render right).
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: LEFT = WOLF standing exactly as in Image 1, strict side view facing screen-right, all four paws on the baseline. RIGHT = the same WOLF at exactly the same scale, sitting upright in strict side view facing screen-right: haunches and hind legs folded on the floor, forelegs straight and vertical with both front paws on the baseline, chest up, head up in profile looking right, ears up, the segmented tail lying along the floor behind and curving forward. In the sitting WOLF all four legs and all four paws must be clearly countable: the far foreleg stands slightly behind and a little to the left of the near foreleg, offset enough that BOTH front paws are visible side by side on the baseline; both folded hind legs show their paws on the floor under the haunch. Two ears.
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws; circular mechanical joints; grey-blue low-chroma angular armour plates; one articulated segmented armoured tail; one cyan eye; restrained cyan seam lights only on a few seams. No fur, no harness, no collar.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, large simplified plates, minimal texture, crisp shape-designed silhouettes, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches, tiny bolts.
LIGHTING: identical to Image 1: cold overhead top light, top faces lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edges; cool blue-black shadows, never brown.
TRANSPARENCY: fully opaque bodies; crisp 1-2 px anti-aliased edges; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, a third figure, overlapping figures, extra ears, legs, paws or tails, fur, magenta or pink, text.
For pose 4 the self-check must confirm: two figures, separated, same scale, right one sitting.
~~~

### wolf-side-stand-a3

- status: REPAIR, SELECTED -> wolf-side-stand.png (raw h/w 0.527, 243 px tall at 460 px long; accepted against the 235-246 window)
- generation id: `exec-3ed43feb-8360-4416-a2b5-f3ba1d94fd58`; thread `01a12831-9df3-76b3-b71a-0d811a5f0b23`
- source: `~/.codex/generated_images/01a12831-9df3-76b3-b71a-0d811a5f0b23/exec-3ed43feb-8360-4416-a2b5-f3ba1d94fd58.png`; raw copy `raw/wolf-side-stand-a3.png`
- SHA-256: `1f33d9388c5347558512f9af7537e5bb58ad3e927f425a314498f8aa1dd2052e`
- references in order: Image 1 = scratchpad/art/sprites/wolf-side-right.png (EDIT TARGET: the approved WOLF design sprite; keep its silhouette and proportions exactly) · Image 2 = hq/characters/refs/ref-v2-wolf-source.png (the approved Look 2 render of WOLF from the style test: rendering only) · Image 3 = hq/characters/refs/ref-style-test-v2.png (the approved Look 2 style test: rendering and edges) · Image 4 = scratchpad/art/keyart/keyart-b.png (mood, light and palette) · Image 5 = hq/characters/refs/palette-card.png (colour swatches)

~~~text
USE CASE: precise-object-edit, style-transfer re-render of an approved design. Change ONLY the rendering; keep the silhouette, pose and proportions of Image 1 exactly.
ASSET: canonical identity cut-out of WOLF, the robotic wolf companion in WOLF//OVERRIDE, a 2D side-view sci-fi horror game; clean graphic-painterly game art readable at small size.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha). WOLF fills about 85% of the canvas width, centred, fully inside the frame with a clear margin on every side. Final game size will be exactly 460 px long nose-to-tail-tip after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = EDIT TARGET and shape lock. Trace it: the same outline, the same pose, the same leg length, the same head size and head height, the same neck angle, the same tail angle and length, the same armour plate layout, joint positions and paw positions. Its overall height is about 0.53 of its nose-to-tail length (ear tips to paws vs nose tip to tail tip) and the result must keep that ratio: long legs that lift the body well off the ground, a raised neck and a head that sits clearly above the line of the back, ear tips the highest point, and the tail sweeping down and back at the same angle as Image 1, not held straight out level. Do not lengthen the tail, shorten the legs, lower the head or flatten the back.
Image 2 = the approved Look 2 rendering of this same WOLF: copy its rendering only (flat grey-blue plate values, top light, cyan rim, clean edges, no texture). Ignore its pose and its turned head.
Image 3 = the approved Look 2 style test: rendering, value structure and edge treatment only. Do not copy its composition, background or props.
Image 4 = mood, lighting and palette only (cold blue-black, cyan rim); do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: exactly one fully robotic wolf in a strict orthographic side view facing screen-right, standing still exactly as in Image 1, head forward in profile looking right, ears up. All four paws on one level baseline, near and far legs staggered as in Image 1 so all four legs and four paws are countable.
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws; circular mechanical joints at shoulders, hips, elbows and hocks; grey-blue angular armour plates of low chroma (lit about #656a72, mid about #292f37); one articulated, segmented armoured tail; one cyan eye; restrained cyan seam lights (#4f8ab8 to #30d0fc) only on a few plate seams. Fully robotic: no fur, no organic anatomy, no harness, no collar.
CHANGE ONLY THE RENDERING: replace Image 1's stone-like surface texture, speckle and dark inked outlines with Look 2 shape-first graphic painting: flat value planes with 3-4 value steps per material; large simplified armour plates; minimal texture; crisp shape-designed silhouette; broad rim shapes; painterly soft blending only inside the lit top planes. No dark outline or inked contour anywhere, on the silhouette or between plates: separate plates with adjacent flat values. No grain, speckle, scratches, tiny bolts or details smaller than 6 px at the final 460 px length.
LIGHTING: cold overhead top light, so the back, head top and top faces of plates are clearly lighter than the body core; a broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edge of the head, neck, back and tail, kept fairly even so the sprite can be mirrored. Shadows cool blue-black (#07101a, #121f2c), never brown or warm.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo or glow outside the silhouette.
DO NOT: change the silhouette or proportions of Image 1, head turned back or toward the viewer, floor, cast or contact shadow, reflection, background, extra ears, legs, paws or tails, fur, motion lines, magenta or pink, text.
~~~

### engineer-three-quarter-a2

- status: Repair, not selected: correct front details (zip, both straps, belt light, toes angled right, both eyes) but the turn is only about 30 degrees; used as the "rotate further" reference for a3.
- generation id: `exec-9dea6ae9-de89-44a1-8a4e-a7ae327272f5`; thread `01a12831-a9ca-7db3-aeba-bdb69fc36f20`
- source: `~/.codex/generated_images/01a12831-a9ca-7db3-aeba-bdb69fc36f20/exec-9dea6ae9-de89-44a1-8a4e-a7ae327272f5.png`; raw copy `raw/engineer-three-quarter-a2.png`
- SHA-256: `016fdc227c3be76908a57e996d3dbb9212017dadaa4791e451ba042a8e44162f`
- references in order: Image 1 = scratchpad/hq/characters/raw/engineer-side-idle-a2.png (the canonical Look 2 identity, seen in side profile) · Image 2 = hq/characters/refs/ref-identity-engineer.png (design source: original sprite left, approved Look 2 render right) · Image 3 = hq/characters/refs/ref-style-test-v2.png (the approved Look 2 style test: rendering and edges) · Image 4 = scratchpad/art/keyart/keyart-b.png (mood, light and palette) · Image 5 = hq/characters/refs/palette-card.png (colour swatches)

~~~text
USE CASE: stylized-concept, identity-preserving new view for a character turnaround sheet (do not redesign)
ASSET: front three-quarter turnaround view of the WOLF//OVERRIDE engineer, Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one portrait PNG with a genuinely transparent background (real alpha). The full figure fills about 85% of the canvas height, centred, with a clear margin on every side. Final game size will be exactly 280 px tall after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same engineer, same face, hair, costume, colours, proportions, rendering and lighting. Image 1 is a SIDE PROFILE; this image must ROTATE the same character about 45 degrees toward the camera. Keep everything except the viewing angle.
Image 2 = design source (original sprite left, approved Look 2 render right); its left panel shows the jacket front, both harness straps and the belt; use it for the costume seen from the front.
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: exactly one engineer in a FRONT THREE-QUARTER view, rotated about 45 degrees from the side profile toward the viewer, facing toward screen-right and toward the camera, as in the classic three-quarter panel of a character turnaround sheet. Quiet idle stance, standing upright, eye level, no perspective distortion. This is NOT a side profile:
- Face: three-quarter face with BOTH EYES visible (the far eye slightly foreshortened), the nose pointing toward the lower right of the face, the mouth and chin seen from the front-right, both cheeks partly visible.
- Torso: the CHEST FRONT faces the viewer at an angle. The jacket's vertical centre zip runs down the torso a little right of centre; the chest pocket flap is visible; BOTH black harness straps run down over the front of both shoulders and the chest; the black utility belt crosses the front of the hips with the one small cyan belt light facing the viewer.
- Arms: both arms relaxed at the sides; the near (left on screen) arm and glove fully visible, the far arm and glove visible beside the body on the right.
- Legs: both legs visible side by side, slightly apart; both boots flat on one level baseline, the TOES ANGLED TOWARD THE VIEWER'S RIGHT (pointing down-right toward the camera, not straight to screen-right).
Exactly two arms and two legs.
IDENTITY LOCKS: short tousled brown hair, hood down; deep-red hooded field jacket (lit #a01e29, shadow #5f0e17) with a chest pocket flap; black shoulder harness straps and black utility belt; one small cyan equipment light on the belt (the only cyan object); black gloves; charcoal cargo trousers with a thigh pocket and dark knee straps; dark boots. No yellow patches, no silver knee armour, no helmet, hood not up.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, 6-8 large value shapes, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top-facing planes (hair top, shoulders, tops of arms and boots) lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) on the top and back edges; cool blue-black shadows, never brown or grey. Trousers, gloves and boots graded cool blue-charcoal.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: side profile, one-eyed profile face, fully frontal pose, back view, floor, cast or contact shadow, reflection, background, extra figure, extra or missing limbs, magenta or pink, text.
~~~

### wolf-side-lookback-a3

- status: REPAIR, SELECTED -> wolf-side-lookback.png (finished at the stand body scale)
- generation id: `exec-4971ba16-4128-42b2-8bf7-b17e36ae4997`; thread `01a12833-ea07-7833-836c-ec21d64934be`
- source: `~/.codex/generated_images/01a12833-ea07-7833-836c-ec21d64934be/exec-4971ba16-4128-42b2-8bf7-b17e36ae4997.png`; raw copy `raw/wolf-side-lookback-a3.png`
- SHA-256: `48da191d939941a2e9760075a2f8375a6814a288ebe6c6f6c572dc41bc66bcb4`
- references in order: Image 1 = scratchpad/hq/characters/raw/wolf-side-stand-a3.png (the corrected Look 2 identity and proportion lock) · Image 2 = hq/characters/refs/ref-v2-wolf-source.png (the approved style-test WOLF: head-turn pose guide) · Image 3 = hq/characters/refs/ref-style-test-v2.png · Image 4 = scratchpad/art/keyart/keyart-b.png · Image 5 = hq/characters/refs/palette-card.png

~~~text
USE CASE: stylized-concept, identity-preserving new pose (do not redesign)
ASSET: identity cut-out of WOLF, the robotic wolf companion in WOLF//OVERRIDE, looking back; Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha). WOLF fills about 85% of the canvas width, centred, fully inside the frame with a clear margin. Final game size will be exactly 460 px long after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same WOLF, same armour plates, joints, legs, tail, colours, proportions, rendering and lighting. Change only the head and neck pose.
Image 2 = the approved Look 2 style-test WOLF, which already looks back over its shoulder: copy its head-and-neck turn and its raised head height exactly (muzzle pointing to screen-left, face in three-quarter from the front). Keep Image 1's body, legs, plates and tail.
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; its robotic wolf looks back over its shoulder toward the engineer: use that idea for the head turn only, not its composition.
Image 5 = colour swatches only.
SUBJECT: exactly one robotic wolf, body and legs in a strict side view facing screen-right, standing still on all four paws on one level baseline, as in Image 1. The neck is raised and bent and the head is turned all the way back over the shoulder: the MUZZLE POINTS TO SCREEN-LEFT, toward the tail, so the nose is to the left of the ears and the face is seen in three-quarter from the front, looking behind itself at someone following. The cyan eye(s) and both ears are visible; the ear tips stay the highest point, as high as in Image 2. The tail sweeps down and back as in Image 1.
PROPORTION LOCK: keep Image 1's proportions exactly: the same leg length (the legs lift the body well off the ground), the same head size, the same raised neck with the head clearly above the line of the back, the same body depth, and the same tail length with the tail sweeping down and back as in Image 1, never held straight out level. Overall height (ear tips to paws) about 0.53 of the nose-to-tail length, as in Image 1. Do not lengthen the tail, shorten the legs, lower the head or flatten the back.
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws, all countable; circular mechanical joints; grey-blue low-chroma angular armour plates; one articulated segmented armoured tail; one cyan eye; restrained cyan seam lights only on a few seams. No fur, no harness, no collar.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, large simplified plates, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches, tiny bolts or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top faces lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edges; cool blue-black shadows, never brown.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: head facing forward or to screen-right, floor, cast or contact shadow, reflection, background, extra ears, legs, paws or tails, fur, motion lines, magenta or pink, text.
~~~

### wolf-side-walk-a2

- status: Repair, rejected: stretched stride and a level tail; h/w 0.487, 499 px long at the stand body scale.
- generation id: `exec-4fcb79d3-7cb8-47e5-b3c5-d968aa8f4035`; thread `01a12833-e4c3-7722-b8c4-d7dd47ed0e4a`
- source: `~/.codex/generated_images/01a12833-e4c3-7722-b8c4-d7dd47ed0e4a/exec-4fcb79d3-7cb8-47e5-b3c5-d968aa8f4035.png`; raw copy `raw/wolf-side-walk-a2.png`
- SHA-256: `19407a440ffb634c7f5513738054d41dc371e8a164fd0800ea62cc3818f8d2e9`
- references in order: Image 1 = scratchpad/hq/characters/raw/wolf-side-stand-a3.png (the corrected Look 2 identity and proportion lock) · Image 2 = hq/characters/refs/ref-identity-wolf.png · Image 3 = hq/characters/refs/ref-style-test-v2.png · Image 4 = scratchpad/art/keyart/keyart-b.png · Image 5 = hq/characters/refs/palette-card.png

~~~text
USE CASE: stylized-concept, identity-preserving new pose (do not redesign)
ASSET: identity cut-out of WOLF, the robotic wolf companion in WOLF//OVERRIDE, walking; Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha). WOLF fills about 85% of the canvas width, centred, fully inside the frame with a clear margin. Final game size will be exactly 460 px long after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same WOLF, same armour plates, joints, tail, colours, proportions, rendering and lighting. Change only the leg pose.
Image 2 = design source (original sprite left, approved Look 2 render right).
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: exactly one robotic wolf in a strict side view facing screen-right, mid-stride in a calm walk: near foreleg reaching forward, near hind leg extended back, far legs in the opposite phase; one paw lifted slightly, the other three paws touching one level baseline; back level, neck raised and head forward in profile looking right, ears up, tail sweeping down and back as in Image 1. All four legs and all four paws countable.
PROPORTION LOCK: keep Image 1's proportions exactly: the same leg length (the legs lift the body well off the ground), the same head size, the same raised neck with the head clearly above the line of the back, the same body depth, and the same tail length with the tail sweeping down and back as in Image 1, never held straight out level. Overall height (ear tips to paws) about 0.53 of the nose-to-tail length, as in Image 1. Do not lengthen the tail, shorten the legs, lower the head or flatten the back.
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws; circular mechanical joints; grey-blue low-chroma angular armour plates; one articulated segmented armoured tail; one cyan eye; restrained cyan seam lights only on a few seams. No fur, no harness, no collar.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, large simplified plates, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches, tiny bolts or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top faces lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edges; cool blue-black shadows, never brown.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, extra ears, legs, paws or tails, fur, motion lines or blur, magenta or pink, text.
~~~

### wolf-sit-a3

- status: REPAIR, SELECTED -> wolf-sit.png (right figure; the left standing figure is only the same-image scale reference)
- generation id: `exec-7618570d-bcf4-4644-a3d1-0cb4f7815fbe`; thread `01a12833-f79e-7d02-8c50-d8ffef6fb2ce`
- source: `~/.codex/generated_images/01a12833-f79e-7d02-8c50-d8ffef6fb2ce/exec-7618570d-bcf4-4644-a3d1-0cb4f7815fbe.png`; raw copy `raw/wolf-sit-a3.png`
- SHA-256: `2695e1b46825c35820c60e25ac6c057a720b911d09b604d5df90a0a280ffaa7e`
- references in order: Image 1 = scratchpad/hq/characters/raw/wolf-side-stand-a3.png (the corrected Look 2 identity and proportion lock) · Image 2 = hq/characters/refs/ref-identity-wolf.png · Image 3 = hq/characters/refs/ref-style-test-v2.png · Image 4 = scratchpad/art/keyart/keyart-b.png · Image 5 = hq/characters/refs/palette-card.png

~~~text
USE CASE: stylized-concept, identity-preserving new pose shown in a same-scale lineup (do not redesign)
ASSET: scale lineup of WOLF, the robotic wolf companion in WOLF//OVERRIDE; Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha), containing exactly two copies of the same WOLF at exactly the same scale, standing on one shared level baseline, separated by a clear empty gap of at least 8% of the canvas width. Both are fully inside the frame with a clear margin. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity and the exact scale and proportion reference: the same WOLF, same armour plates, joints, tail, colours, proportions, rendering and lighting.
Image 2 = design source (original sprite left, approved Look 2 render right).
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: LEFT = WOLF standing exactly as in Image 1 (same pose, same proportions, same tail angle), strict side view facing screen-right, all four paws on the baseline. RIGHT = the same WOLF at exactly the same scale, with the same head size and leg length, sitting upright in strict side view facing screen-right: haunches and hind legs folded on the floor, forelegs straight and vertical with both front paws on the baseline, chest up, head up in profile looking right, ears up, the segmented tail lying along the floor behind and curving forward. In the sitting WOLF all four legs and all four paws must be clearly countable: the far foreleg stands slightly behind and a little to the left of the near foreleg, offset enough that BOTH front paws are visible side by side on the baseline; both folded hind legs show their paws on the floor under the haunch. Two ears.
PROPORTION LOCK: keep Image 1's proportions exactly: the same leg length (the legs lift the body well off the ground), the same head size, the same raised neck with the head clearly above the line of the back, the same body depth, and the same tail length with the tail sweeping down and back as in Image 1, never held straight out level. Overall height (ear tips to paws) about 0.53 of the nose-to-tail length, as in Image 1. Do not lengthen the tail, shorten the legs, lower the head or flatten the back.
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws; circular mechanical joints; grey-blue low-chroma angular armour plates; one articulated segmented armoured tail; one cyan eye; restrained cyan seam lights only on a few seams. No fur, no harness, no collar.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, large simplified plates, minimal texture, crisp shape-designed silhouettes, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches, tiny bolts.
LIGHTING: identical to Image 1: cold overhead top light, top faces lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edges; cool blue-black shadows, never brown.
TRANSPARENCY: fully opaque bodies; crisp 1-2 px anti-aliased edges; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, a third figure, overlapping figures, extra ears, legs, paws or tails, fur, magenta or pink, text.
~~~

### wolf-side-walk-a3

- status: REPAIR, SELECTED -> wolf-side-walk.png (h/w 0.503; finished at the stand body scale)
- generation id: `exec-dedbf8a6-9510-4b22-bc33-fd123d44c21b`; thread `01a12837-a215-7700-bea1-f3d884b1d10d`
- source: `~/.codex/generated_images/01a12837-a215-7700-bea1-f3d884b1d10d/exec-dedbf8a6-9510-4b22-bc33-fd123d44c21b.png`; raw copy `raw/wolf-side-walk-a3.png`
- SHA-256: `2579f321ebbe21bb54cdb1798d45d786b1a2937df6b1e0d3a71b743aecb5daf8`
- references in order: Image 1 = scratchpad/hq/characters/raw/wolf-side-stand-a3.png (the corrected Look 2 identity and proportion lock) · Image 2 = hq/characters/refs/ref-identity-wolf.png · Image 3 = hq/characters/refs/ref-style-test-v2.png · Image 4 = scratchpad/art/keyart/keyart-b.png · Image 5 = hq/characters/refs/palette-card.png

~~~text
USE CASE: stylized-concept, identity-preserving new pose (do not redesign)
ASSET: identity cut-out of WOLF, the robotic wolf companion in WOLF//OVERRIDE, walking; Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha). WOLF fills about 85% of the canvas width, centred, fully inside the frame with a clear margin. Final game size will be exactly 460 px long after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same WOLF, same armour plates, joints, tail, colours, proportions, rendering and lighting. Change only the leg pose.
Image 2 = design source (original sprite left, approved Look 2 render right).
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: exactly one robotic wolf in a strict side view facing screen-right, mid-stride in a calm, short-stepped walk: near foreleg reaching forward, near hind leg extended back, far legs in the opposite phase; one paw lifted slightly, the other three paws touching one level baseline; back level, neck raised and head forward in profile looking right, ears up, tail sweeping down and back as in Image 1. The stride stays compact and under the body: the reaching forepaw stays behind the chest front and the trailing hind paw stays in front of the tail tip. The nose-to-tail-tip length is the SAME as in Image 1 at the same scale, and the tail keeps exactly Image 1's angle, length and tail-tip height, so the whole walking silhouette fits the same bounding box as Image 1 (height about 0.53 of length). All four legs and all four paws countable.
PROPORTION LOCK: keep Image 1's proportions exactly: the same leg length (the legs lift the body well off the ground), the same head size, the same raised neck with the head clearly above the line of the back, the same body depth, and the same tail length with the tail sweeping down and back as in Image 1, never held straight out level. Overall height (ear tips to paws) about 0.53 of the nose-to-tail length, as in Image 1. Do not lengthen the tail, shorten the legs, lower the head or flatten the back.
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws; circular mechanical joints; grey-blue low-chroma angular armour plates; one articulated segmented armoured tail; one cyan eye; restrained cyan seam lights only on a few seams. No fur, no harness, no collar.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, large simplified plates, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches, tiny bolts or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top faces lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edges; cool blue-black shadows, never brown.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, extra ears, legs, paws or tails, fur, motion lines or blur, magenta or pink, text.
~~~

### engineer-three-quarter-a3

- status: REPAIR, SELECTED -> engineer-three-quarter.png
- generation id: `exec-7ad7a8f8-bb20-4f50-96f2-27bd6be2e212`; thread `01a1283c-f1d0-78b2-bfab-45c1dff2e6e2`
- source: `~/.codex/generated_images/01a1283c-f1d0-78b2-bfab-45c1dff2e6e2/exec-7ad7a8f8-bb20-4f50-96f2-27bd6be2e212.png`; raw copy `raw/engineer-three-quarter-a3.png`
- SHA-256: `2d5f367067c097e34b8ca5664f57eed031304fe5b3165c5705d178584b536acb`
- references in order: Image 1 = scratchpad/hq/characters/raw/engineer-side-idle-a2.png (the canonical Look 2 identity, seen in side profile) · Image 2 = scratchpad/hq/characters/raw/engineer-three-quarter-a2.png (the previous attempt: correct costume and front details, but NOT TURNED ENOUGH; rotate further than this) · Image 3 = hq/characters/refs/ref-style-test-v2.png (the approved Look 2 style test: rendering and edges) · Image 4 = scratchpad/art/keyart/keyart-b.png (mood, light and palette) · Image 5 = hq/characters/refs/palette-card.png (colour swatches)

~~~text
USE CASE: stylized-concept, identity-preserving new view for a character turnaround sheet (do not redesign)
ASSET: front three-quarter (45 degree) turnaround view of the WOLF//OVERRIDE engineer, Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one portrait PNG with a genuinely transparent background (real alpha). The full figure fills about 85% of the canvas height, centred, with a clear margin on every side. Final game size will be exactly 280 px tall after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same engineer, same face, hair, costume, colours, proportions, rendering and lighting. Image 1 is a 90-degree side profile.
Image 2 = the previous attempt at this view: keep its costume, front details and rendering, but it is turned only about 30 degrees from profile. ROTATE THE WHOLE FIGURE FURTHER TOWARD THE CAMERA, to a true 45 degrees, halfway between the side profile and a frontal view.
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: exactly one engineer in a true 45-degree FRONT THREE-QUARTER view, facing toward screen-right and toward the camera, quiet idle stance, standing upright, eye level, no perspective distortion. Check every point:
- Face: a clear three-quarter face, not a profile. BOTH EYES clearly visible; the far eye is about two-thirds the width of the near eye. The nose sits INSIDE the outline of the face and does not stick out past the cheek; the mouth is seen almost from the front; the far cheek and jaw line are visible.
- Shoulders and chest: both shoulders visible, the chest front clearly broader than the side of the torso, the jacket's centre zip running down the middle of the visible chest; both black harness straps over the front of both shoulders and down the chest; the chest pocket flap visible.
- Belt: the black utility belt crosses the front of the hips, the one small cyan belt light near the centre, facing the viewer.
- Arms: both arms relaxed at the sides, one each side of the torso, both gloves fully visible.
- Legs: both legs visible side by side, slightly apart, feet about shoulder width; both boots flat on one level baseline with the TOES ANGLED TOWARD THE VIEWER'S RIGHT, so the fronts of the boots face the camera at an angle.
Exactly two arms and two legs.
IDENTITY LOCKS: short tousled brown hair, hood down; deep-red hooded field jacket (lit #a01e29, shadow #5f0e17) with a chest pocket flap; black shoulder harness straps and black utility belt; one small cyan equipment light on the belt (the only cyan object); black gloves; charcoal cargo trousers with a thigh pocket and dark knee straps; dark boots. No yellow patches, no silver knee armour, no helmet, hood not up.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, 6-8 large value shapes, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top-facing planes (hair top, shoulders, tops of arms and boots) lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) on the top and back edges; cool blue-black shadows, never brown or grey. Trousers, gloves and boots graded cool blue-charcoal.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: side profile, profile nose breaking the cheek line, one-eyed face, fully frontal pose, back view, floor, cast or contact shadow, reflection, background, extra figure, extra or missing limbs, magenta or pink, text.
~~~

