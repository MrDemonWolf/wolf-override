# WOLF//OVERRIDE art bible: clean HQ redo with Codex (2026-10-10)

Status: draft for Nathanial's approval. Nothing has been generated, imported, rendered in Godot or played under this bible yet. The repository was not touched.

Every number here is labelled:
- **[measured]**: measured on 2026-10-10 by the asset audit, the research pass or this pass.
- **[proposed]**: a target. It must be re-checked against the approved style test.
- **[sourced]**: taken from a cited document (see section 10).

Working files are in `scratchpad/art-audit/bible/`:
- `qa_asset.py` (the automated QA)
- `palette.py`, `regions.py` (palette samplers)
- `palette_card.py`, `palette-card.png` (colour reference)
- `calibration.jsonl` (QA run over 21 current assets)
- `keyart-b-regions.json`, `palette-keyart.jsonl`, `palette-assets.jsonl`

---

## 1. The decisions on one page

1. **Mood reference.** Approved title art B (`scratchpad/art/keyart/keyart-b.png`) sets the look: cold blue-black, wet mirror floor, overhead strip lamps, cyan rim light, red and amber only from practical lights.
2. **Clean means:**
   - readable flat silhouettes
   - no dark outlines
   - a top light plus a cyan rim on every actor
   - fully opaque bodies (alpha 255)
   - 1-2 px anti-aliased edges with no matte or key spill
   - no detail smaller than 2 screen px at 960x540
3. **Density.** One texel density per family, in source px per world px (D):
   - actors, props, doors and the sentry: D = 4
   - mid plates and near pieces: D = 8/3
   - far plates: D = 2
   - the title: 1920x1080 in the game, with a 2560x1440 master
   - Screen px per world px = (window height / 540) x camera zoom.
4. **Generation.**
   - Codex built-in image_gen in edit mode handles characters, props, doors, the sentry and far plates. Its subject is always generated larger than the final size and downscaled, never upscaled.
   - Mid plates at D = 8/3 and the 2560x1440 title need the imagegen CLI path (2560x1440 native). That path needs Nathanial's approval and an API key (question 1).
5. **Transparency.** Use native transparent output when the model offers it. Otherwise use a flat #FF00FF magenta key, not green. The cyan rim light and the green safe-point light make green keys spill. The current engineer frames show a cyan shift of 6.3 ΔE at the edges [measured].
6. **QA gate.** Every file passes `qa_asset.py` (checks A-H) and gets a review sheet before Nathanial sees it. No batch starts before the style test (section 7) is approved.

---

## 2. Framings and the density rule

Base canvas is 960x540 with canvas_items stretch. The camera zooms are:

| shot | zoom |
|---|---|
| gameplay | 1.35 |
| chapter close | 1.55 |
| opening | 1.8 |
| Director close-up | 1.95 |
| title | 1.0 |

`main.gd:398/498/519/1426` [measured].

Density = source px per screen px = D / ((window height / 540) x zoom).
- Below 1 means the art is enlarged and soft.
- Above about 3 means memory is wasted and the image depends on mipmaps.

| framing | D = 4 (actors, props) | D = 8/3 (mid, near) | D = 2 (far) | title 1920 | title 2560 |
|---|---|---|---|---|---|
| 960x540, z 1.35 | 2.96 | 1.98 | 1.48 | 2.00 | 2.67 |
| 1280x720, z 1.35 | 2.22 | 1.48 | 1.11 | 1.50 | 2.00 |
| **1920x1080, z 1.35** | **1.48** | **0.99** | 0.74 | **1.00** | 1.33 |
| 1920x1080, z 1.55 | 1.29 | 0.86 | 0.65 | | |
| 1920x1080, z 1.8 | 1.11 | 0.74 | 0.56 | | |
| 1920x1080, z 1.95 | 1.03 | 0.68 | 0.51 | | |
| 2560x1440, z 1.35 | 1.11 | 0.74 | 0.56 | 0.75 | 1.00 |

**Rules [proposed]:**
- **Actors:** at least 1.0 at 1920x1080 for every zoom they appear in.
- **Mid plates:** at least 1.0 at 1080p gameplay.
- **Far plates:** at least 0.7 at gameplay. Haze hides the softness, which the research pass's aerial-perspective rule supports.
- **Ceiling:** at most 4.5 at 960x540 gameplay.

Today's assets miss these rules in both directions [measured, audit]:
- characters run 10-16 at 960
- the WOLF animation runs 0.37 at 1080p
- plates run 0.74 at 1080p
- the title runs 0.87 at 1080p

**Known limit.** In the opening (zoom 1.8) the D = 8/3 mid plate is still drawn at 0.74 on 1080p. If that shot must be sharp, paint the corridor's first 960 world px at D = 3.6. Question 2 covers this.

---

## 3. Style rules

### 3.1 Palette (hex sampled from approved art) [measured]

**How it was sampled.** Per-pixel median of masked regions:
- key art B: `regions.py`, `palette.py`
- the approved plates and props: `palette-assets.jsonl`

Lab values are CIE L*a*b* (D65). h is the Lab hue angle.

**Value ramp** (key art B L* bands; every band has hue about 266, so the ramp is cold blue):

| role | hex | L* | C* |
|---|---|---|---|
| void / menu side | `#000307` | 0.7 | 1.7 |
| deep shadow | `#07101a` | 4.6 | 7.1 |
| shadow | `#121f2c` | 11.3 | 11.2 |
| wall mid | `#1d3042` | 19.3 | 14.8 |
| lit wall | `#2f4d69` | 32.1 | 22.1 |
| cold highlight | `#4175a0` | 47.9 | 30.0 |
| rim / reflection | `#82c3e6` | 75.8 | 29.7 |
| top highlight | `#ade4fb` | 87.0 | 23.3 |
| lamp core | `#e3f6fe` | 95.6 | 7.6 |

**Light and material:**

| role | hex | L* | source |
|---|---|---|---|
| lamp shaft (in air) | `#385d85` | 38.6 | key art B, under the lamps |
| wet floor mid | `#1e2e3c` | 18.5 | key art B floor band |
| wet floor reflection | `#73a9cc` | 67.5 | key art B floor band |
| character top rim | `#c3c5d7` | 78.2 | key art B, actors at L* ≥ 70 |
| WOLF armour, lit | `#656a72` | 44.6 | key art B (C* 6) |
| WOLF armour, mid | `#292f37` | 18.9 | key art B |
| WOLF seam light | `#4f8ab8` | 55.3 | key art B |
| keypad cyan | `#2091ca` | 56.9 | key art B |
| door light strip | `#30d0fc` | 77.7 | key art B |

**Accents** (the only saturated colours allowed):

| role | hex | L* | C* | source |
|---|---|---|---|---|
| engineer jacket, lit | `#a01e29` | 35.3 | 58.2 | key art B |
| engineer jacket, shadow | `#5f0e17` | 19.4 | 39.3 | key art B |
| red practical / alarm | `#ad252d` | 38.6 | 61.8 | key art B |
| red-orange lamp glow | `#ca452f` | 48.6 | 48.7 | key art B wall lamps |
| amber glow (bright) | `#e0936e` | 67.9 | 41.2 | key art B |
| amber reflection on wet floor | `#c89876` | 66.9 | 26.7 | key art B |
| amber metal (breaker) | `#82510e` | 39.7 | 39.0 | approved breaker prop |
| amber, dim (plates) | `#6e4824` | 34.8 | 27.9 | junction-mid plate |
| rust red (plates) | `#82290f` | 30.3 | 51.7 | junction-mid plate |
| safe-point green (lamp) | `#56dc69` | 78.9 | | approved safe-point prop |
| safe-point green (mid) | `#228237` | 47.8 | | approved safe-point prop |
| safe-point green (dark) | `#17632f` | 36.5 | | approved safe-point prop |

`palette-card.png` (1520x512, three rows: value ramp, accents, materials) is the colour-only reference attached to every Codex call.

**Rules [proposed]:**
- **Cool neutrals.** Low-chroma pixels (C* < 12) must lean cool, with median b* ≤ -1. Measured values:
  - plates -1.6 to -4.3
  - key art B -2.1
  - Rowan -4.8
  - today's props +0.35 to -0.9, which is too warm or neutral
- **Accents from the palette.** Saturated pixels (C* ≥ 25, L* ≥ 15) must sit within ΔE76 18 of an accent swatch at the 90th percentile. Measured values:
  - key art B 11.3, corridor-far 12.8, Rowan 14.7
  - props 27.6-49.6
  - door redraw A (orange-glow junction door) 45.3
- **Accent area:**
  - plates: about 1% saturated area (measured 1.0-1.4%)
  - key art: about 6%
  - stations: one accent each, under 12% of the body
  - the engineer's red jacket is the only large saturated area in the game, so the player reads first. Inside used colour sparingly to highlight the player [sourced: wiki-inside].
- **Banned colours.** No magenta or pink anywhere; it is reserved for the key. No yellow clothing patches and no silver knee armour on the engineer (from the existing correction prompts).

### 3.2 Value bands per depth layer

L* is measured on opaque pixels. The current values come from `evidence/measure.json` and `band-contrast.json`.

| layer | target median L* | target p95 L* | chroma | detail (mean L* gradient, `measure.py`) | current (measured) |
|---|---|---|---|---|---|
| far plate | 8-12, the lightest plate layer, lifted by haze | ≤ 40 | C* ≤ 10 | ≤ 4.0 | median 5.7-6.1, detail 3.6-5.0 |
| mid plate, overall | 5-10 | ≤ 45 (lamps exempt) | C* ≤ 12 | ≤ far detail + 1 | junction mid 8.2 median, detail 9.3 (inverted) |
| mid plate, walk band (world y 300-440, behind actors) | ≤ 10 and ≤ the far median | ≤ 30 | | ≤ 4.0 | 8.5-12.2 |
| near pieces | ≤ 4 | ≤ 20 | C* ≤ 10 | ≤ 3.0 | 2.0 median |
| actors' bodies (engineer, WOLF, Director, sentry) | 20-32, and ≥ 12 above the local walk-band median | top rim 65-85 | jacket red only | | Rowan 20.6, WOLF 16.4 |
| interactive stations | 18-28 | status light 55-80 | 1 accent | | props 17.7-24.2 |
| inactive props, doors | 12-22 | | | | |
| title / hero | 1-4 | menu side (right 45%) p95 ≤ 6 | | | key art B: 1.8 median, menu side p95 4.5 |

**Ordering:** far is lightest and lowest in contrast, mid carries the playfield, near is darkest and simplest [sourced: aerial perspective; TF2 NPAR07 distant scenery low-detail].

**Black level:**
- Plates and key art may reach L* 0.
- Actors and stations may have at most 3% of pixels below L* 3. Every current asset clips its darkest 1% to 0 [measured].

### 3.3 Lighting

1. **Key light:** overhead cold strip lamps (`#e3f6fe` core, `#385d85` shaft), pooled every 300-400 world px. Each pool lights the floor and the tops of objects.
   - Every actor and prop is top-lit.
   - The top-facing rim is lighter than the core, which `qa_asset.py` checks as C_top_light_dL.
   - Measured today:
     - props: +3.9 to +5.9
     - new engineer frames: +11.2 (good)
     - Rowan -12, WOLF -12.9, Director -17.1, sentry -16, door redraw B -10.5 (unlit cut-outs)
2. **Rim light:** cyan-white (`#82c3e6` to `#c3c5d7`), 4-8 source px wide at D = 4 (about 1.5-3 screen px at 1080p), on the top and back edges.
   - It must be symmetric enough that left-facing frames can use `flip_h` instead of mirrored files.
   - TF2 emphasises silhouettes "with rim highlights rather than dark outlines" [sourced: tf2-npar07].
3. **Practicals:** red, amber and green light comes only from emissive sources:
   - status lamps
   - door strips
   - the safe-point lamp
   - alarm beacons

   Each source spills at most about 40 world px of tinted light onto nearby surfaces and onto the wet floor.
4. **Shadows:** go to cold blue-black (`#07101a`, `#121f2c`), never neutral grey or brown. Use warm-to-cool shading [sourced: tf2-npar07].
5. **Floor:** wet plate.
   - Reflections stay below the walk line, are vertically stretched and are brightest under lamps.
   - The plates contain no reflections of actors or props; the game's `floor_reflection` shader draws those.
   - Lamp reflections in the plate are allowed.
6. **Baked lighting:**
   - Plates are painted neutral-cool. CanvasModulate and additive glow sprites (`room_depth.gd`) add the light that changes with state [sourced: godot-2dlights].
   - Nothing that changes with game state is baked into a plate: beacons, door lights, the tower crown.

### 3.4 Edges and alpha

1. **No dark outlines.** The median L* of the 1-3 px rim minus the core (C_outline_dL) must be above -8. Measured today:
   - Rowan -18.4, Director -17.3, WOLF -16.1, sentry -18.5, door redraw B -20.4
   - new engineer frames +0.3
2. Edges are made by value and rim light. The anti-aliased edge is 1-2 source px of partial alpha. Partial alpha deeper than 3 px is allowed only in declared translucent regions (glass, steam, hair wisps), listed in the review sheet.
3. **Bodies are fully opaque:** alpha 255 for at least 99% of pixels that are 3 or more px inside the silhouette. Today's cut-outs measure 0-0.3%:
   - Generator bodies sit at alpha 252-253, on every current prop, the doors A/B redraws and the characters.
   - Rowan's highest alpha is 254 [measured].
   - The matte step in 5.4 normalises this.
4. No matte fringe and no key spill:
   - dark-fringe share ≤ 10%
   - halo share ≤ 10%
   - mean a*b* shift at the edge ≤ 4

   Today [measured]: sealed door 68%, coolant relay 43%, breaker 39%, safe point 31%, valve 20%; engineer frames have a 6.3 shift (cyan).
5. **No baked contact shadow or floor.** The bottom edge is crisp. The baseline is the lowest row with at least 3 px at alpha ≥ 128.
6. **Transparent pixels:** RGB = the nearest body colour. Godot's `fix_alpha_border` does this at import [sourced: godot-import]; keep it on.

### 3.5 Detail budget per layer

The smallest feature is measured at 960x540 gameplay, the lowest-detail framing.

| layer | smallest feature | texture | where detail may go |
|---|---|---|---|
| actors | ≥ 2 screen px = 6 source px at D = 4 | ±4 L* inside a material plane; no grain or speckle | face, hands, chest light, WOLF seams; 6-8 major value shapes per figure |
| stations, props, doors, sentry | ≥ 6 source px; panel lines ≥ 4 px wide | ±4 L* | one focal element (screen, lamp, lever); bolts and rivets only if ≥ 6 px |
| mid plate | ≥ 4 source px (2 screen px at 960) | ±5 L* | above head height (world y < 300) and at doorways; the walk band carries large forms only |
| far plate | ≥ 6 source px, soft edges | ±3 L* | silhouettes of structure, light shafts |
| near pieces | ≥ 24 source px | none | silhouette plus a 1-2 px cyan rim |

TF2 omits high-frequency detail where possible and keeps visual noise to a minimum [sourced: tf2-npar07]. Hollow Knight pairs clean, simple characters with intricate backgrounds [sourced: wiki-ari-gibson].

**Automated proxies** (section 6):
- G_noise_display: Immerkær σ on luma, at the 1080p display size
- G_hf_share: the share of luma variance that is lost at display size

**Thresholds [proposed, calibrated on 21 assets]:**

| family | σ target | σ fail | hf_share target | hf_share fail |
|---|---|---|---|---|
| actors, props, doors, sentry | ≤ 4.5 | > 6.0 | ≤ 0.20 | > 0.30 |
| mid plate | | > 4.0 | | > 0.25 |
| near pieces | | > 3.0 | | > 0.20 |
| far plate | | > 2.5 | | > 0.15 |

Measured today:
- σ: sentry 8.5-12.3, WOLF 10.2, valve 7.2, coolant relay 6.3, Rowan 5.6, door redraw B 3.9
- hf_share: sentry 0.41-0.44, Rowan 0.32, door B 0.15

### 3.6 Design locks (do not redesign)

- **The engineer (Rowan sprite file):**
  - short tousled brown hair, hood down
  - deep-red hooded field jacket
  - black harness and utility belt
  - small cyan belt light
  - charcoal trousers, gloves, dark boots
  - two arms and two legs
- **WOLF:**
  - a fully robotic wolf
  - grey-blue angular armour plates (C* ≤ 8)
  - circular mechanical leg joints
  - an articulated armoured tail
  - a cyan eye and restrained cyan seam lights
  - exactly 2 triangular ears and 4 legs with 4 paws
  - smaller in height than the engineer
  - no fur

  The current title art's furry wolf is wrong; key art A and B fix it [measured, audit].
- **Sentry:** the approved v2 body with the scanner head (`art/sentry-v2/APPROVED`, 2026-10-09). The redo keeps the design but removes the see-through band at rows 471-500.
- **Stations:** keep each one's current silhouette and function so players can still recognise them. Redraw them clean, cool-graded and top-lit.

### 3.7 Readability tests (every actor and interactive element)

1. **Silhouette:** fill the sprite with flat black at 94 px and 188 px tall. A reviewer must name it, and for animation the pose, in 2 seconds [sourced: tf2-npar07 silhouette validation; xbox-ori silhouette blockouts]. Door families must differ: silhouette RMSE against each sibling must be ≥ 0.25 [proposed]. The level plan measured 0.17 between today's near-duplicates.
2. **Greyscale at 960x540:** the actor's body median L* must be at least 12 above the local walk-band median [proposed; research proposed 15].
3. **Lost edge and contrast:** measured with H_lost_share / H_contrast_median on rendered frames. Render with and without the sprite on a paused frame, as the audit did.
   - lost share (ΔE76 < 10 against the background just outside) ≤ 35%
   - median WCAG contrast ≥ 1.6:1
   - at least 30% of the perimeter (the rim-lit side) at ≥ 3:1 [proposed]

   WCAG's non-text guideline asks for 3:1 [sourced: WCAG 2.1 SC 1.4.11]. For a dark horror scene, the bible requires that only on the rim-lit side.

   Today, in real frames: lost 63-72%, contrast 1.01-1.18 [measured, audit].
4. **Blur:** apply a 2 px Gaussian blur at 960x540. Every station's status light and outline must still be distinct.
5. **Motion:** frame-to-frame hip-anchor drift ≤ 2% of the figure's height. The loop seam (last frame to first) must have silhouette IoU ≥ 0.75 for walk and idle; jog and trot flight frames are exempt. The current engineer walk measures 0.79 [measured, anim QA].

---

## 4. Per-family targets, formats and Godot import

**Shared rules:**
- Every texture is PNG RGBA 8-bit sRGB with dimensions that are multiples of 16.
- No texture edge exceeds 2048 px: OpenGL ES 3.0 only guarantees 2048 [sourced: gles3-maxtex].
- Godot 4.7.2 GL Compatibility.
- `process/fix_alpha_border=true`, `premult_alpha=false`.
- `texture_filter = LINEAR_WITH_MIPMAPS` on every node whose texture has mipmaps [sourced: godot-canvasitem].
- The project-wide mipmap bias has no effect in this renderer. A per-sprite canvas shader with LOD bias -0.5 sharpens without aliasing [measured, review/audit.json]. That shader is not in the repo yet; it is part of integration.

| family | world size (from today's scales) | source and canvas | display at 1080p, z 1.35 | import |
|---|---|---|---|---|
| **Engineer animation** (idle 6, walk 8, jog 8; then use-tap 4, hold-use loop 4; knockdown and get-up pending the coolant decision) | 70 world px tall | opaque height 280 ± 4 px; cell 256x320, feet baseline row 311, hip pivot x 128; sheets 4x2 = 1024x640 per 8 frames | 189 px tall, density 1.48 | Lossless (mode 0), mipmaps on, LINEAR_WITH_MIPMAPS, LOD-bias shader. Left-facing via `flip_h`, not mirrored files. About 3.5 MB per sheet. |
| **WOLF animation** (idle 6, walk 8, trot 8; then hop takeoff/air/land 3, perch or sit 4, cover crouch 3, look-back 3, per the plan's route graph) | 115 x 61 world px | opaque length 460 incl. tail, height 246; cell 512x272, baseline row 263; sheets 4x2 = 2048x544 | 310 x 166 px | Same as the engineer. About 5.9 MB per 8-frame sheet. The scratch frames (384x208, WOLF filling about 9%) are rejected. |
| **Director** (cutscene stills, 2-3 poses) | 70 world px tall, shown at zoom 1.95 | opaque height 280; cell 256x320 | 273 px at z 1.95, density 1.03 | Same as the engineer. |
| **Sentry** (active, scanning, down/wreck) | 60 x 44 world px | opaque 240 x 175; canvas 272x208 | 162 x 118 px | Lossless, mipmaps on. Lens is the only red; the hull carries a cyan top rim to fix 64% edge loss. |
| **Stations and props** (all 17, plus the plan's tower crown and lamps, gauge needle, terminals, pickups, the tool) | 59-161 world px tall | D = 4: breaker 388, coolant relay 356, purge display 404, safe point 448, purge queue and mirror port 448, valve 392, tank 336, tank arm 644, arm panel 260, bolt panel 236 px tall. Canvas = opaque bbox + 16 px padding, baseline 8 px above the bottom. **Minimum interactive height 44 world px**, so the relief vent (16 world px tall today) must be redesigned larger. | 159-435 px | Lossless, mipmaps on. Stateful parts (lever, needle, lamps, screen glow) are separate sprites, never baked. |
| **Doors** (corridor seal, Records west door, archive lift hatch, junction blast door sealed / breaking / blown, junction hatches) | about 136-144 world px tall | D = 4: about 544-576 px tall; leaf and frame separate; canvas about 352x576. Replaces the 768x1280 A/B redraws (5.2 MB each). | 367-389 px | Lossless, mipmaps on, about 1.1 MB each. Each family has a distinct silhouette (RMSE ≥ 0.25). |
| **Mid plate** (play plane) per wide room | 1680 or 1440 x 540 world px | D = 8/3 (plate scale 0.375). 1680 room = 4480x1440, 1440 room = 3840x1440. Tiles 1920 src (720 world) wide + 4 px gutters: 1680 = 1920+1920+640, 1440 = 1920+1920. `mid_top` = 50, so the walk rows are whole numbers: floor y 440 at row 1040, catwalk y 344 at row 784, WOLF high run y 296 at row 656. Crop fully transparent tiles. | full screen, density 0.99 | VRAM Compressed (mode 2), as today, mipmaps **on** (density 1.98 at 960). Measured on today's plates: S3TC 34.8-46 dB, ETC2 38-46 dB, no visible blocking at 3x [audit]. Test `high_quality` (BPTC desktop, ASTC mobile [sourced: godot-import; android-textures]) on the style-test plate before choosing. About 8.6 MB per 1680 room (7.4 MB per 1440). Godot advises against VRAM compression for 2D [sourced: godot-import], but lossless would be 34 MB per room, too much for phones. |
| **Far plate** | room width x 540 world px | D = 2: 1680 room = 3360x1080, 1440 room = 2880x1080, tiled at ≤ 1920 | density 0.74 (haze) | VRAM Compressed, mipmaps off (density 1.48 at 960 measured clean: error 0.4-1.2 [audit]). About 4.2-4.8 MB. |
| **Near pieces** (one occluder per room plus edge strips) | ≤ 80 x 540 world px | D = 8/3: ≤ 224x1440 | | Lossless, mipmaps on, about 1.7 MB. |
| **Title key art** | full screen, zoom 1 | master 2560x1440 (CLI path), shipped 1920x1080 (Lanczos down, density 1.0 at 1080p). Built-in fallback: 1672x941 upscaled 1.148x (the cap is 1.25x). | 1920x1080 | Lossless, mipmaps on (density 2.0 at 960). About 11 MB. Never VRAM-compress it: median L* 1.8 bands. Keep the path `title-corridor-key-art-provisional.png` (plan). |
| **Logo** (`logo-mark.svg`) | 88 px at 960 | rasterise at `svg/scale=0.5` (256 px) | 176 px | Mipmaps on. Today's 512 raster without mipmaps gives the worst aliasing measured (error 12.4) [audit]. |
| **Site hero** | CSS `object-fit: cover` | WebP 640 / 1024 / 1672 / 2560 from the 2560 master, plus share-card.jpg 1200x630 | density 0.89 on a 1440 CSS px 2x screen (0.57 today) | WebP quality ≥ 90, PSNR ≥ 40 dB against the master (today 37.0-41.3 dB [audit]). |
| **Site gameplay captures** | | render at 1920x1080 in Godot (today 960x540); WebP 960 / 1920 | density 1.0 on 2x screens (0.5 today) | Captions stay "source-build capture". Render after the rooms land. |

**Memory totals (estimated):**
- characters: about 25-30 MB lossless with mipmaps, about today's 26 MB, but now sharp at 1080p
- per room: plates about 13-15 MB compressed
- Keep only the current room and the next room resident. Device-test before any mobile claim.

---

## 5. Codex generation recipe

### 5.1 Tools [measured from existing art notes]

- **Codex built-in image_gen, edit mode:**
  - Up to 5 local reference images per call (the "tool maximum" in `art/keyart/generation-prompts.txt`).
  - Outputs are about 1.57 MP at the requested aspect: 1672x941, 1448x1086 and 1212x1297 were all observed. There is no size argument, and edits re-render the whole frame (level-expansion research).
  - Raw outputs carry C2PA (anim `qa.md`).
- **imagegen CLI fallback** (`scripts/image_gen.py` in Codex's imagegen skill, per level-expansion.json research):
  - Custom sizes: each edge ≤ 3840, both edges multiples of 16, ratio ≤ 3:1. Above 3,686,400 px (2560x1440) is experimental [sourced: openai-image-prompting].
  - Needs `OPENAI_API_KEY` and Nathanial's explicit approval.
  - The guide documents `background="transparent"` for the GPT Image 2.5 models [sourced]. The earlier research found none on the gpt-image-2 CLI. Check whichever model runs.

**Where each family is generated:**
- **Mid plates and the title:** the CLI at 2560x1440. That is one 960x540-world screen at D = 8/3 natively, so the plan's 960-world segments still apply.
  - 1680 room: segments at world x 0-960, 480-1440 and 720-1680.
  - 1440 room: segments at 0-960 and 480-1440.
  - Built-in fallback: 1672x941 upscaled 1.53x. That only reproduces today's softness, so it is not recommended.
- **Far plates:** built-in at 1672x941, upscaled 1.148x to 1920x1080 per 960 world px.
- **Actors, props, doors, sentry:** built-in at native size, then downscaled.

### 5.2 References to attach (always, in this order, with one role each [sourced: openai-image-prompting "assign roles"])

1. **Identity or edit target.** For actors, the approved identity sheet; build engineer and WOLF turnaround sheets first in batch 1. For props and doors, the current approved design. For plates, the layout guide rendered from the RoomProfile.
2. **Mood, light and palette:** `art/keyart/keyart-b.png`. Prompt it as "lighting, palette and mood only; do not copy its composition or figures".
3. **Colour only:** `bible/palette-card.png`.
4. **Rendering and edges:** the approved style-test winner (after section 7). Before approval, use a cropped region of the matching approved plate.
5. **Layout only (optional):** a grid or cell guide for animation, or a seam anchor (the left 50% of the previous segment) for plates.

### 5.3 Prompt skeleton

```text
USE CASE: <new asset | style-transfer edit | precise-object-edit (change only X)>
ASSET: <family> for WOLF//OVERRIDE, a 2D side-view sci-fi horror game; clean graphic-painterly game art, readable at small size.
OUTPUT: one PNG, <W>x<H>. <Opaque | Perfectly flat uniform #FF00FF magenta background, no gradient, no floor, no shadow>.
  No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
  Image 1 = <identity | edit target | layout guide>: match <list exact features>.
  Image 2 = mood, lighting and palette only (cold blue, wet floor, cyan rim); do not copy its composition or figures.
  Image 3 = colour swatches only; use only these hues for saturated colour.
  Image 4 = rendering and edge treatment only.
  Image 5 = layout only; ignore its colours and lines.
SUBJECT: <what, pose, facing screen-right, side elevation, full figure inside the frame with a 6% margin>.
SIZE ON CANVAS: <subject fills about H px tall / L px long> (≥ 1.25x the final size; see 5.5).
STYLE (CLEAN): large readable value shapes; 6-8 major shapes; painterly but controlled, with soft brush texture only inside light pools;
  no fine grain, no speckle, no scratches smaller than <6 px at final size>; no dark outline: edges defined by value and a cyan-white rim light on the
  top and back edges; fully opaque body; crisp anti-aliased silhouette.
LIGHTING: cold overhead strip light from above (top surfaces lighter), cyan rim from behind, shadows cold blue-black (never brown or grey);
  the only saturated colour is <accent> from <emissive part>.
CONSTRAINTS: <design locks from 3.6>; side view, no perspective tilt; one subject only.
DO NOT: magenta or pink on the subject; a baked floor, shadow or reflection; extra limbs; text; glow outside the silhouette; motion lines.
```

**Rules:**
- One change per edit pass, and list what must stay [sourced: openai-image-prompting].
- Composite approved regions locally instead of re-prompting the whole frame.
- Save every prompt in ignored art notes with the raw output's SHA-256.

**Animation rows:**
- Engineer: 4x2 grid in 1448x1086 (cells 362x543). The figure is about 470 px tall, so the downscale to 280 is 0.6x.
- WOLF: 2x2 grid in 1672x941 (cells 836x470). WOLF is about 700 px long, so the downscale to 460 is 0.66x. 8 frames need 2 calls; send the first call's output as reference 1 of the second.
- Keep the existing prompts' contact-frame wording (00 and 04 contacts), plus "hip pivot fixed at the same point in every cell".

### 5.4 Transparency and matte procedure (deterministic, scripted)

1. If the model returns real alpha (`background="transparent"`), use it and go to step 5.
2. **Key alpha:** d = RGB distance to #FF00FF / 441.7. α = smoothstep(t0, t1, d), starting at t0 = 0.18 and t1 = 0.42. Record the values used per asset.
3. **Decontaminate:** C = (P − (1 − α)·K) / α for α > 0.02, clamped to 0-255. This removes the key colour instead of shifting its hue.
   - Then limit the residual spill on the edge band only (distance ≤ 3 px): s = max(0, min(R, B) − G), R −= s, B −= s.
   - Never despill toward cyan. That was the engineer-frame failure.
4. **Clean up:** drop islands < 64 px that are not connected to the body. Any pixel ≥ 2 px inside with α ≥ 240 becomes 255. Any pixel ≥ 3 px inside with α < 250 becomes 255 unless it is in a declared translucent mask.
5. **Resize:** downscale to target D in premultiplied linear light with an area or Lanczos3 filter. Then quantise, and pad to the canvas (multiples of 16, baseline row as specified).
6. Run `qa_asset.py`. If C_fringe fails, erode 1 px and go back to step 5.

### 5.5 Resizing rules

- **Sprites (actors, props, doors, sentry):** never upscale. The subject in the raw output must be ≥ 1.25x its final size. Downscale only, once, from the raw output.
- **Plates and title:** upscale at most 1.25x, Lanczos3, in linear light. Above that, use the CLI path or tile the image.
- **Sharpening:** none after downscaling. It brings back the crunch the audit measured. If something is soft, regenerate it at a larger size.
- **Wide plates:**
  - chained outpaint with ≥ 960 src of overlap
  - colour-match the new segment to its anchor
  - minimum-error vertical seam, feathered over 48-96 px, away from the walk line, doors and the landmark
  - keep the original pixels left of the seam (plan, art_pipeline 3)
  - never warp to fit the walk line; regenerate instead

### 5.6 Review sheet format (one per asset; one per animation row)

A 1920 px wide PNG plus a JSON sidecar, saved as `review/<batch>/<asset_id>.png` and `.json`. The panels are, left to right and top to bottom:
1. The source at 100% over magenta, black and white, plus its alpha map (alpha in greyscale; semi-transparent pixels tinted).
2. Flat black silhouette at 94 px and 188 px tall (88/176 px for props, by height).
3. In situ on the target plate:
   - 960x540, 1280x720, 1920x1080 and 2560x1440, each cropped 480x270 around the asset, with the 960 crop pixel-doubled
   - for actors, also zoom 1.8
   - rendered in Godot when possible; otherwise with the audit's filter emulation (`tools/analyze.js`)
4. Greyscale version of the 1080p crop, with the walk-band median and the body median printed.
5. The previous version next to the new one at the same scale.
6. Animation only: a contact sheet, an onion-skin overlay of the hip anchor, and 1x and 2x GIF/WebP previews.
7. A QA table: every `qa_asset.py` check with value, threshold and pass or fail, plus density per framing.
8. Provenance: tool and model, date, prompt id, references, raw SHA-256, C2PA present (yes or no), matte parameters, resize factor.

---

## 6. QA checks every generated asset must pass

### 6.1 Automated (written: `bible/qa_asset.py`, stdlib only)

Usage: `python3 -I qa_asset.py FILE --family F --scale S [--zoom Z ...] [--baseline ROW] [--bg BG --bg-box x0,y0,x1,y1 --disp-h PX]`. Pass a directory to check a frame set; that also checks same-canvas and baseline spread. The exit code is non-zero on any failure.

| id | check | threshold [proposed] |
|---|---|---|
| A_alpha_body | share of pixels ≥ 3 px inside at alpha 255 | ≥ 0.99 |
| B_holes_share | semi-transparent (16-249) pixels ≥ 3 px inside | ≤ 0.5% |
| B_interior_band_rows | longest run of rows (body ≥ 25% of sprite width) with > 20% semi-transparent pixels, ≥ 12 rows from the bbox top or bottom | ≤ 3 |
| B_edge_fade_rows | same, at the top or bottom edge (baked contact shadow or fade) | ≤ 6 |
| C_fringe_dark / C_fringe_halo | partial-alpha edge pixels ≥ 15 L* darker or lighter than the opaque ring 2-4 px inside | ≤ 10% each |
| C_edge_chroma_shift | mean a*b* shift of edge pixels against that ring (key spill) | ≤ 4 |
| C_outline_dL | median L* of the 1-3 px rim minus the core | > -8 |
| C_top_light_dL | top-facing rim minus the core | ≥ 0 (target +10) |
| D_baseline | lowest row with ≥ 3 px at alpha ≥ 128 against the spec | ±1 px |
| E_density | source px per screen px at 1080p and max zoom / at 960 and gameplay zoom | ≥ 1.0 (far ≥ 0.7) / ≤ 4.5 |
| F_cool_neutrals_b | median b* of C* < 12 pixels | ≤ -1 |
| F_accent_dE_p90 | p90 ΔE76 from saturated pixels to the nearest accent swatch | ≤ 18 |
| G_noise_display | Immerkær σ on luma (0-255) inside the body at 1080p display size | per family (3.5) |
| G_hf_share | luma variance removed by a down/up resample to 1080p display size | per family (3.5) |
| H_lost_share / H_contrast_median | silhouette perimeter at display size against the background just outside | ≤ 0.35 / ≥ 1.6 (≥ 30% of perimeter at ≥ 3:1) |

**Calibration on current assets** (`bible/calibration.jsonl` [measured]). The checks catch every defect the audit found:

| asset | fails caught | agrees with audit |
|---|---|---|
| sentry-down v2 (committed) | interior band rows 471-500 (30 rows), holes 9.7%, σ 12.2, hf 0.43, warm b* +1.15 | yes (audit: rows 474-500) |
| sentry-down v1 | band 3 rows at a thin antenna tip (passes), but σ 12.3, fringe 16.7% | yes (no hull band) |
| sentry active | halo 20.6%, outline -18.5, top light -16, σ 8.5, hf 0.41 | yes |
| corridor sealed door | dark fringe 67.8% (audit 58%), edge shift 10.1, accent p90 27.8 | yes |
| coolant relay / breaker / safe point / valve | dark fringe 42.6 / 38.8 / 31.4 / 20.3% (audit 32 / 30 / 28 / 25%); accent p90 27.6-49.6; neutrals warm | yes |
| Rowan | alpha 0% at 255 (max 254), outline -18.4, top light -12.0, hf 0.32, density 15.8 at 960 | yes |
| Director | outline -17.3, top light -17.1, halo 13.8% | yes |
| WOLF | outline -16.1, top light -12.9, σ 10.2, density 10.1 at 960 | yes |
| scratch engineer walk 00 | edge shift 6.33 (cyan spill), alpha 91% at 255, baseline 364 against the declared 366; **passes** outline (+0.3) and top light (+11.2) | yes |
| scratch WOLF walk 00 | density 0.37 at 1080p, dark fringe 17% | yes |
| door redraws A/B | alpha body 0.01-0.02%, outline -20.4 (B), accent p90 28-45, density 6.6 at 960 | new finding: their bodies are at 252-253 too |
| key art B / plates | accent p90 11.3-19.2, cool b* -1.6 to -4.3 (pass); density at 1080p 0.56-0.87 (fail) | yes |

**Caveats:**
- H was calibrated on a scratch composite (`art/layers/small-composite-aligned.png`), not a Godot frame. It gives Rowan lost 33% and contrast 1.42. The audit measured 63% in the real corridor frame.
- Use H as a pre-check. The pass criterion is the Godot render with and without the sprite.
- All thresholds are [proposed] until the style-test winner has been measured. Re-calibrate them with the winner and record the change.

### 6.2 Automated checks still to write (specified)

1. **`walkline.py`** (plates): sample the painted walkway top edge per column (the strongest downward L* step within ±16 rows of the profile row). Pass within ±3 room px on flats and ±5 on ramps (plan).
2. **`seam.py`** (plates): along each stitch, mean ΔE76 between columns seam−1 and seam+1 ≤ 3 in the walk band, and ≤ 1.5x the image's median column-to-column ΔE elsewhere. Mean L* and b* of the 96 px on each side must match within 2.
3. **`compress_check`** (reuse `art-audit/tools/fringe_compress.js`):
   - decode the S3TC and ETC2 (or BPTC and ASTC) `.ctex` with Godot's decompressor
   - premultiplied PSNR ≥ 38 dB per tile
   - block-edge to in-block error ratio ≤ 1.3
   - worst 64x64 tile inspected at 3x on the review sheet
4. **`filter_check`** (reuse `tools/analyze.js`): Godot mipmap and trilinear emulation against an ideal area downscale at 4 sub-pixel offsets, at 960x540 and 1080p.
   - error ≤ 6 and shimmer ≤ 4 [proposed]
   - today: logo 12.4 / 10.7, WOLF 8.6 / 5.1
   - for plates, it decides whether mid-plate mipmaps can stay off: off if error ≤ 1.5
5. **`anim_check`**:
   - same canvas for every frame
   - baseline spread 0 px on contact frames
   - hip-anchor drift ≤ 2% of the height
   - loop-seam silhouette IoU ≥ 0.75 (walk and idle)
   - left frames are `flip_h` of the right
6. **`door_rmse`**: silhouette RMSE between door families ≥ 0.25.
7. **`provenance_check`**:
   - a manifest entry exists for every file
   - raw and final SHA-256 recorded
   - C2PA presence noted before stitching strips it
   - prompts are in ignored notes and not in public files (AGENT.md)

### 6.3 Manual (cannot be automated)

- Design locks (3.6): ear, leg and paw counts; costume.
- Silhouette naming test (3.7.1).
- Hands-on play of the affected route before any game-feel claim.
- A real Android or iOS device for ETC2/ASTC banding before any mobile claim.

---

## 7. STYLE TEST brief for Codex (approve before any batch)

**Goal:** one vignette, a slice of the Maintenance Corridor at target density, in two variants. Nathanial picks one or a mix. It becomes reference 4 for every later call, and the QA thresholds are re-calibrated on it.

**Frame:** exactly one 1080p gameplay view: 720 x 405 world px at D = 8/3, so 1920x1080. The engineer appears at the size a 1080p player sees.

**Composition (both variants identical, side elevation, no vanishing point):**
- **Floor:** wet steel deck. The walk line is at row 800 of 1080 (world y 440). Reflections only below it.
- **Breaker station** at x 15-27% (about 350 px tall).
  - Dark steel cabinet, cool-graded.
  - The amber status lamp (`#e0936e` core) is the only warm light, with a small amber reflection on the wet floor.
- **Engineer** at x about 36%: 280 px source, about 186 px tall in the frame. Facing right, idle stance. Red jacket, cyan belt light, top light and cyan rim.
- **WOLF** at x 48-63%: about 307 px long in the frame. Standing, facing right, head turned back to the engineer as in key art B, cyan eye and seams.
- **Coolant relay station** at x 70-80% (about 320 px tall). The cyan ring light (`#30d0fc`) is its accent.
- **Lighting:**
  - two overhead strip lamps with soft shafts, one above the engineer and one above the relay
  - the darkest gap between them sits behind WOLF's back half, to test separation in the worst case
- **Far layer:** pipes and a bulkhead wall in haze, lighter and flatter than the mid layer.
- **Near layer:** one dark foreground rib at the left edge, ≤ 6% of the width.

**Deliverables per variant:**
1. The plate without actors or stations: opaque 1920x1080, generated at 1920x1088 (CLI) or 1672x941 upscaled 1.148x (built-in).
2. Four cut-outs on #FF00FF or transparent, matted per 5.4 at D = 4:
   - engineer, 280 px tall
   - WOLF, 460 px long
   - breaker, 388 px tall
   - coolant relay, 356 px tall
3. A local composite with the cut-outs scaled by 2/3 (D 4 to 8/3) onto the plate, at 1920x1080, 1280x720 and 960x540, plus 2x crops of the 960.
4. `qa_asset.py` JSON for every cut-out, and H on the composite for the engineer and WOLF.
5. One review sheet comparing the two variants, with the current game frame (`art-audit/frames/960/10-corridor-start.png`) as the before.

**Variant 1, "current look, cleaned":**
- the same painterly rendering, texture density and mood as key art B and the approved corridor plates
- with every rule in section 3: no dark outlines, top and rim light, opaque bodies, no detail under 2 screen px at 960, props graded cool
- prompt add-on: "match the painterly brushwork of image 2, reduce fine texture and grain by half, keep large shapes"

**Variant 2, "graphic-painterly":**
- the same palette, light and composition
- 3-4 value steps per material, large flat value planes with soft painted transitions only inside light pools, simplified panel detail (one panel line where there were three)
- crisp shape-designed silhouettes and broad rim shapes
- strong value separation between layers: far flat and light, near a pure silhouette
- prompt add-on: "shape-first graphic painting: flat value planes, minimal texture, crisp silhouettes, painterly only in light and atmosphere"

**Acceptance before showing Nathanial:**
- every cut-out passes A-G
- in the composite at 960x540, engineer and WOLF reach H_lost ≤ 0.35 and contrast median ≥ 1.6
- WOLF has 2 ears and 4 paws; the engineer matches the costume lock
- no text

**Nathanial approves:** V1, V2, or a stated mix (for example "V2 for actors and props, V1 for plates"). After that, the measured values of the winner (L* bands, σ, hf_share) replace the [proposed] thresholds.

---

## 8. Batches, in order, with dependencies

| # | batch | assets | depends on | gate |
|---|---|---|---|---|
| 0 | Style test | section 7 | answers to questions 1-2 | Nathanial picks a variant |
| 1 | Characters and animation | engineer and WOLF identity turnarounds, then engineer idle, walk, jog, use-tap, hold-use; WOLF idle, walk, trot, then hop, perch, cover and look-back; Director stills | batch 0 | review sheets plus anim_check; knockdown waits for the coolant decision; new WOLF poses wait for the route graph node list (plan, shared_tech 8) |
| 2 | Props and stations | the 17 existing ones re-cut at D = 4 and cool-graded; relief vent redesigned ≥ 44 world px; stateful parts as separate sprites | batch 0 | review sheets; the plan's new stations (tower crown, gauge, terminals, pickups, the tool) wait for each room's RoomProfile |
| 3 | Doors | all door families, leaf and frame separate | batch 0 | door_rmse ≥ 0.25; the doorway kit size (plan, shared_tech 7) |
| 4 | Sentry | active, scanning, wreck: the v2 design re-cut without the band | batch 0 | review sheet |
| 5 | Title, hero, logo | key art at 2560x1440, then 1920 game copy, site WebPs, share card; logo `svg/scale` 0.5 with mipmaps | batch 0, question 3 (subject) | Nathanial approves the key art; then alt text, README caption and manifest updates (plan) |
| 6 | Room plates (corridor, then Records, then Junction) | guide from the RoomProfile; far tiles, mid segments (CLI 2560x1440), near occluder; walkline, seam and compression checks | **each room's blockout played and its profile locked**, batch 0; corridor also batch 5 (title art is its style reference) | rendered stills at 3 camera positions per room, desktop and touch framing; then hands-on play |
| 7 | Site gameplay captures | re-render at 1920x1080 | batch 6 integrated | captions stay honest |
| 8 | Integration | imports (section 4), LOD-bias shader, plate scale 0.375 and mid_top 50 in RoomDepth v2, AnimatedSprite2D atlases, `flip_h` | each batch as it lands | Godot stills at 960 / 1280 / 1920 / 2560; play the route; device test for ETC2/ASTC; manifest and changelog |

Batches 1-5 can run in parallel after batch 0. Batch 6 is the only one waiting on level design.

---

## 9. Open questions for Nathanial

1. **CLI image path.** May Codex use the imagegen CLI (your OpenAI API key, billed per image) for the title and the mid plates at 2560x1440? Without it, the mid plates and title stay about as soft at 1080p as today. Everything else can use the built-in tool.
2. **Sharpness or memory.** Should mid plates use 8/3 source px per world px (sharp at 1080p; about 8.6 MB per wide room) or 2 (as today; soft at 1080p; about 4.8 MB)? And should the corridor's opening segment be painted extra-sharp for the zoom-1.8 opening (+80% memory for that segment)?
3. **Title subject.** Should the title repaint key art B's scene at 2560x1440, or the new first room (containment bay and relay tower), as the level plan proposed?
4. **Keep or redo designs.** Should the approved designs be kept and only re-rendered clean (sentry v2, door redraws A/B, the engineer frames' poses), or are fresh designs allowed where the style test suggests them?

---

## 10. Sources

**Fetched by the research pass on 2026-10-10** (`evidence/sources.json`). Not re-fetched in this pass.
- godot-import: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html
- godot-canvasitem: https://docs.godotengine.org/en/stable/classes/class_canvasitem.html
- godot-multires: https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html
- godot-2dlights: https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html
- android-textures: https://developer.android.com/games/optimize/textures
- gles3-maxtex: https://registry.khronos.org/OpenGL-Refpages/es3.0/html/glGet.xhtml
- tf2-npar07: Valve, "Illustrative Rendering in Team Fortress 2", NPAR 2007. https://cdn.cloudflare.steamstatic.com/apps/valve/2007/NPAR07_IllustrativeRenderingInTeamFortress2.pdf (local text `evidence/tf2-npar07.txt`)
- xbox-ori: https://news.xbox.com/en-us/?p=4339
- wiki-inside: https://en.wikipedia.org/wiki/Inside_(video_game)
- wiki-ari-gibson: https://en.wikipedia.org/wiki/Ari_Gibson
- aerial perspective: https://en.wikipedia.org/wiki/Aerial_perspective
- gdc-inside (dithering against banding): https://www.gdcvault.com/play/1023002/Low-Complexity-High-Fidelity-INSIDE

**OpenAI image-prompting guide:** https://developers.openai.com/api/docs/guides/image-prompting. Read this pass from the saved copy `evidence/openai-image-prompting.md`:
- lines 50-60: sizes and limits
- line 66: transparency
- lines 83-90: reference roles, change-only edits, one change per pass

**Cited from memory by the audit and not fetched:**
- WCAG 2.1 SC 1.4.11: https://www.w3.org/TR/WCAG21/#non-text-contrast
- Immerkær, "Fast Noise Variance Estimation", CVIU 64(2), 1996

**Project files:**
- `review/audit.json` (pixelation root cause, LOD bias)
- `review/level-expansion.json` (room widths, walk rows, art pipeline, Codex tool limits)
- `art/keyart/generation-*.txt`
- `art/anim/qa.md`
- `art/sentry-v2/APPROVED`
- `apps/game/scripts/main.gd`, `room_depth.gd`
- the `.import` files
- `manifest.json`

**Evidence limits:** all numbers come from source files and stills. Nothing in this bible was rendered in Godot, played, exported or run on a device.
