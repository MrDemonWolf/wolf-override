# Sentry batch: Look 2 graphic-painterly (2026-10-10)

Status: generated, matted and QA'd; repaired once after review (see "Repair 1" below). Not imported into Godot, not rendered in-engine, not played.

## Deliverables

| file | canvas | opaque bbox (x0,y0,x1,y1) | opaque size | baseline row | qa |
|---|---|---|---|---|---|
| `sentry-active.png` | 272x208 | 16,32,255,199 | 240x168 | 199 | `qa/sentry-active.json`: A-H pass |
| `sentry-scanning.png` | 272x208 | 16,31,255,199 | 240x169 | 199 | `qa/sentry-scanning.json`: A-H pass |
| `sentry-wreck.png` | 272x208 | 17,31,255,199 | 239x169 | 199 | `qa/sentry-wreck.json`: A-H pass |

- **Set check:** `qa/set.json` shows the same canvas for all three and a baseline spread of 0.
- **Review sheet:** `review-sheet.png` shows each state:
  - on mid-grey at 1x and 2x
  - on the style-test plate at 1080p game size (2/3 of source) and at 2x
  - on the plate at source 1x
  - against the committed v2 art at the same world scale
  - with the full QA table
- **Facing:** all states face LEFT, as the v2 art did. The game mirrors them.
- **Size:** all three share one scale (0.17991 of raw, D = 4, 60 x 42 world px). The treads match, so state swaps don't jump.
- **Design:** all states keep the approved v2 design: tracked chassis, red front lens and the scanner head on its pedestal. There is no gun.

### Integration numbers (canvas px; divide by 4 for world px)
- **Tread centre:** x 130.0 in all three states. This is the node origin; v2 used ACTIVE_TREAD_X 516 and WRECK_TREAD_X 545 in its own 1024 px source.
- **Visor slit core, active:** about x 96-128, y 63-69. In scanning it is about x 104-140, y 64-68, because the head turns.
- **Code beam:** `sentry.gd` LENS / BEAM_* draws the beam over the slit, so the LENS rect must be re-measured on integration.
- **Wreck hull top:**
  - row 111 over the front hull (cols 30-70)
  - row 101 over the rear box (cols 200-240)
  - the bent mast and head reach row 31
  - WRECK_HULL_TOP needs re-deriving.
- **Height change:** the active opaque height is 168, not 175. The 240 px tread width (60 world px, set by SentryBrain.HALF_WIDTH) was kept. The new render is slightly longer and lower than v2 (v2's 626 px height included the fin and the painted beam). DRAWN_HEIGHT becomes about 42 world px instead of 43.8.

## Design decisions
- **Painted beam removed.** The v2 active art had a painted cyan light cone ahead of the scanner. I removed it because:
  - `sentry.gd` already draws the beam and the eye light in the brain's colour (off, amber, red)
  - the bible bans glow outside the silhouette
  - section 4 says stateful lights are never baked

  The visor slit is painted lit cyan, with a lit cyan rim on its housing.
- **Lens.** The red front lens is the only red. In the wreck it is dark and cracked.
- **Hazard stripes and indicator lamps.** The stripes are muted amber, and the two small amber indicator lamps stay tiny.
- **Separation from dark walls:**
  - a cold top light on every upward plane (C_top_light_dL +19.2 active, +20.0 scanning, +16.3 wreck)
  - a cyan-white rim on the top and back edges
  - the lit visor rim
  - H against the style-test plate's darkest wall gap: active lost 25.3%, contrast 1.89, 32% of the perimeter ≥ 3:1. The audit's v2 figure was 64% lost. (Before Repair 1 it read 20.1% / 2.10 / 35%; the reopened hose loop adds inner perimeter against the dark wall, which is the honest silhouette.)
- **Scanning state.** The head is turned about 15 degrees, so a sliver of its front face shows, and the visor is brighter.
  - Only the head, pedestal and hose columns (raw x 500-1210, above a seam at raw row 460, feathered over 12 px) come from the scanning render.
  - Everything else is the active render, pixel for pixel. Below raw row 472 nothing changed.
  - The scanning render was shifted 1 px up to register with the active one.
  - This is the bible 5.3 rule, "composite approved regions locally". Swapping between active and scanning cannot jitter the hull or treads.
- **Wreck.** It keeps v2's damage story:
  - the head knocked forward on a bent mast, with a dark cracked visor
  - a caved-in hull with torn plates, and a dark cracked lens
  - torn hoses with cut wire ends and a few dim amber ember points
  - loose track plates resting on the chassis
  - the rear box still recognisable
- **Wreck band removed.** The v2 semi-transparent band (rows 471-500) is gone: B_holes_share 0.0011, B_interior_band_rows 0, A_alpha_body 0.9986. The designed see-through gaps between head, torn hoses and pedestal stay open (alpha 0), as in the raw and v2.

## References (every generation; five-path limit)
1. **Design reference.** Active used `art/sentry-v2/sentry-side-left.png` as the edit target. Scanning used the Look 2 active raw (`refs/look2-active.png`) as the edit target. Wreck used `art/sentry-v2/sentry-down.png`.
2. **Composite board.** `refs/style-board-look2.png` is built by `work/make_refs.py`. It holds the style-test v2 `composite-1920.png`, a crop of `plate.png`, and the engineer, wolf, breaker and relay cut-outs. It stands in for the five style-test PNGs within the tool's five-reference limit. The rules from `notes.md` went into the prompt text.
3. **Mood.** `art/keyart/keyart-b.png`, for mood, light and palette only.
4. **Colour.** `art-audit/bible/palette-card.png`, for colour only.
5. **Cross-check.** Active used the v2 wreck as an identity cross-check. Scanning used `sentry-side-left.png`. Wreck used the Look 2 active raw, for scale and rendering match.

The full prompts are in `prompts/active-01.txt`, `prompts/scanning-01.txt` and `prompts/wreck-01.txt`; each file is the exact text passed to `codex exec`.

## Generation
- **Tool.** Codex built-in image generation only (`codex exec ... "<prompt>" < /dev/null`, imagegen skill in edit mode). No API key and no billed CLI path were used. Codex reported model gpt-6-luna for the agent.
- **Output.** Every raw is 1536x1024 RGBA with real transparency (alpha tops out at 254).
- **Sessions.** Each session was archived with `codex archive` (scripted in `work/run_codex.sh`).

| raw | Codex session (archived) | original under ~/.codex/generated_images | SHA-256 | C2PA |
|---|---|---|---|---|
| raw/active-01.png (selected) | 01a12818-5340-79d1-82d9-e8f18c81f534 | exec-ddb87387-97fb-4500-8164-3860dbd6149a.png | 835f35ba46b40e06943e4f7b86f4fc49f100f98162b971a97020ed2bc0690f95 | yes |
| raw/scanning-01.png (head used) | 01a1281d-37ef-7ce0-bae0-ce65d8b11aac | exec-867dfe38-7404-46ad-a5c7-4771271c1aed.png | 25ce0664f6d0ccef2728df4a3e2c1e37e2500e09dd202143bf4abb11dd7c42b3 | yes |
| raw/wreck-01.png (selected) | 01a1281d-37ef-7442-9038-356e131e000a | exec-c36ba554-0c29-498b-8373-f459b3dbe624.png | 1e07701ef577afe9b926e61a4121b88d4f05d293834ad8f450c55bcbfb68f3f4 | yes |

The local scanning composite is `work/scanning-composite-raw.png`, SHA-256 a3071936762dced37c6f4e1f0482a00e68cb6c317100849c1d24ed864345a535.

There were no regenerations: each state's first output was usable. The redos, including Repair 1, were in post-processing (below). Repair 1 needed no Codex run: both reviewer defects were introduced by `process.py`, and the raws already hold the correct shapes (open hose loop, flat cracked visor plate).

## Processing (`work/process.py`, deterministic; parameters in `work/proc-*.json`)
1. **Native alpha.** Each raw's own alpha was used; no key was needed. Islands under 64 px were dropped (none existed). Since Repair 1 only enclosed holes under 400 raw px, or holes whose mean raw alpha is ≥ 128, are filled (`--hole-max 400`). Larger holes that show background in the raw stay at alpha 0 and get the normal edge match (step 7). Kept open: active 7495 + 1378 raw px, scanning 7505 + 1296, wreck 9339 + 1255; filled: wreck 2 single-pixel specks.
2. **Opaque interior.** Pixels 2 or more px inside with alpha ≥ 240 were set to 255. Pixels 3 or more px inside were set to 255.
3. **Decontamination.** Every non-opaque pixel takes the nearest opaque colour.
4. **Wreck only: visor touch-up and raw median (Repair 1).**
   - `work/visor_cracks.py` writes `work/wreck-visor-raw.png` (SHA-256 fde58581c56ba777cc67a800f511e2eff660a84d260b026c365f87d5ee5de6d8). It finds the raw's dark visor plate (raw box x 580-810, y 240-390), keeps the raw's own crack lines that sit ≥ 6 px inside it (605 px), and widens them by 2 raw px in a value just under the crack colour (#5e6f85 around #6e839d). Nothing outside the visor plate changes. Result: the flat, cracked visor plate reads at 1x-2x as a dead scanner visor, not a bore.
   - A median of size 7, iterated 3 times, on the raw RGB, skipping the outer 14 raw px so the rim light survives. The whole head (raw x 540-1010, y 50-365: visor plate, housing, mast top, antenna box) gets only a size-3 median, so its flat plates, bevels and slit stay crisp. The iterated small median replaces v1's single size-11 median, which erased the visor plate and rounded the plate edges.
5. **Downscale.** One downscale at 0.17991 in premultiplied linear light (area pre-filter plus bicubic sample), placed on the 272x208 canvas with tread centres aligned and the bottom on row 199. Nothing was upscaled or sharpened.
6. **Accent snap.** Saturated pixels (C* ≥ 25, L* ≥ 15) more than ΔE76 16 from the nearest bible accent were pulled to ΔE 16. This touched 600, 663 and 165 px. It is the same fix the style test used.
7. **Edge match.** Partial-alpha edge pixels take the mean colour of the opaque ring 2-4 px inside them. This is the style test's edge fix: it removes halo, dark matte and spill, and opaque pixels are untouched.
8. **Transparent RGB.** Transparent pixels take the nearest body colour.

## QA (`python3 -I art-audit/bible/qa_asset.py`, unmodified thresholds)
- **Command:** `--family sentry --scale 0.25 --zoom 1.35 --zoom 1.8 --baseline 199 --bg style-test/v2/plate.png --bg-box 900,0,1220,800 --disp-h 112`. The box is the plate's darkest wall gap with the walk line at row 800. 112 px is about the 1080p display height.
- **Final:** all checks A-H pass for all three states (values in the review sheet and `qa/`). `qa/set.json` (directory mode on `work/set`) passes: same canvas, baseline spread 0.

First-pass failures and how they were fixed:
- **Active:** C_fringe_dark 0.144, C_fringe_halo 0.234 and C_edge_chroma_shift 4.22. The 1 px edge carried the bright rim and the dark seams. Step 7 fixed it (0.076 / 0.033 / 0.51).
- **Scanning:** F_accent_dE_p90 was 18.2. The causes were the visor glow fringe, the lens halo and the tan stripes. Step 6 fixed it (16.0). I applied the snap to all states for consistency.
- **Wreck:** G_noise_display 10.0 and G_hf_share 0.309.
  - Step 4 fixed it (4.69 / 0.202).
  - The first median version also thinned the rim, which dropped H contrast to 1.53. Protecting the outer 14 raw px restored it to 1.62.
  - Repair 1 replaced it (see step 4). Tried: single median 7 (G 6.79 FAIL), 5 (7.98 FAIL), 9 (5.74), 11 (4.91); iterated 5x3 (6.89 FAIL), 5x4 (6.60 FAIL), 7x2 (6.01 FAIL), 7x3 (5.58). With the visor touch-up and the larger head box: 7x3 + head 3 = G 5.90 (chosen, crispest head), 7x3 + head 5 = 5.77, 9x1 + head 3 = 6.05 FAIL.

Margins to watch:
- **Wreck H contrast.** It is 1.61 against the 1.6 limit. The wreck has no lit sensor, so it is the dimmest state. Only 25% of its perimeter reaches 3:1, below the 30% the bible proposes for the rim-lit side. Active and scanning reach 32%.
- **Wreck noise.** G_noise_display 5.90 against the 6.0 limit (v1 was 4.69 with the size-11 median that erased the visor). The extra texture is the kept visor cracks and the crisper torn-plate edges.
- **Active and scanning noise.** σ 5.7 is within the 6.0 limit but above the 4.5 target. It comes from the panel seams and bevels. No smoothing was applied, to keep their edges crisp.

## Metadata
- **Final PNGs** (`sentry-*.png`, `review-sheet.png`): no metadata chunks, only IHDR, IDAT and IEND. No C2PA, EXIF, XMP or text.
- **Raw outputs:** all three carry a C2PA caBX chunk and remain unchanged in `raw/` and under ~/.codex/generated_images.
- **Local intermediates** (`work/scanning-composite-raw.png`, `work/wreck-visor-raw.png`) are derived from those raws by local scripts and carry no C2PA; the AI provenance lives with the raws listed above.
- **Repository:** nothing was written to the repository or any worktree.

## Manual checks still needed
- Silhouette naming test (bible 3.7.1).
- A Godot render with and without the sprite in the Service Junction. H here is a pre-check on the style-test plate, not a game frame.
- Re-deriving the `sentry.gd` constants (ACTIVE/WRECK_REGION, TREAD_X, LENS, ART_SCALE 0.07 becomes 0.25 at D = 4, WRECK_HULL_TOP).
- Hands-on play of the junction route before any game-feel claim.

## Repair 1 (2026-10-10, after review)

Reviewer defects and fixes. No Codex regeneration: both defects came from `work/process.py`, not the raws. v1 finals, QA, sheet and notes are kept in `work/repair/v1-finals/`; trial outputs and peeks are in `work/repair/`.

1. **Filled negative space and glow blob (all three states).** v1's `ndi.binary_fill_holes` closed every enclosed hole, so the open loop between the head's rear hose and the pedestal (and the wreck's gaps between head, torn hoses and pedestal) became opaque, and decontamination smeared a soft cyan-blue glow into it.
   - Fix: `--hole-max 400` (default) fills only holes under 400 raw px or with mean raw alpha ≥ 128. The large holes stay alpha 0 and get the normal edge match (step 7).
   - Active changed only inside canvas x 159-193, y 74-100. Scanning still shares every active pixel from row 108 down (hull and treads identical); the head, pedestal and hose still come from the same seam composite (`work/scanning-composite-raw.png`, unchanged).
   - Checked at 5x on grey (`work/repair/peek-holes.png`) and on the review sheet's grey 2x and plate 2x panels: the hose loop is open with the background showing through, and there is no glow.
2. **Wreck visor erased into a gun-barrel read.** v1's size-11 raw median wiped the flat cracked visor plate and softened the plate edges.
   - Fix: see Processing step 4. Note: the reviewer's head box (raw x 380-760, y 100-330) misses most of the head; the measured head is raw x 545-1010, y 55-360 and the visor plate is about x 595-800, y 225-350, so the protected box is x 540-1010, y 50-365.
   - Checked at 1x, 2x and 5x (`work/repair/peek-head2.png`): the head reads as a boxy scanner housing with a flat, cracked, unlit visor plate between two light bars; no bore or muzzle.
   - QA after repair: G_noise_display 5.90 (≤ 6.0), H_contrast_median 1.61 (≥ 1.6), H_lost_share 0.23, all A-H pass.

Integration numbers are unchanged: tread centre x 130.0, active and scanning visor rects, wreck hull tops (row 111 front, 101 rear). Final PNG SHA-256: active f6f6620b…a47da, scanning 05b72891…df8f6, wreck c2f2fbe9…6504d.
