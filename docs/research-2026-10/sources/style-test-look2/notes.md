# Variant 2 — graphic-painterly

Date: 2026-10-10

## Generation and references

- Generated with Codex’s built-in image generation (ChatGPT / gpt-image). No API key or billed CLI path was used.
- Each generation used the seven requested approved references. The built-in tool allows at most five reference paths, so the Rowan/WOLF and breaker/relay references were attached as two composite reference boards. The plate edits used a combined palette/mood/corridor board, the layout guide, both identity/prop boards, and the current plate. No reference was omitted.
- The plate was generated at 1672 × 941 and upscaled in linear RGB with Lanczos to 1920 × 1080 (1.148×). Its selected source placed the wall/floor edge at raw row 702; the upscaled plate was shifted upward 6 px to put the walk line at row 800. The bottom edge was extended with the final row. The plate contains no actors or stations.
- Cut-outs were cleaned at their native alpha, then downscaled only from the larger generated images. Composites use a 2/3 scale with linear-light, premultiplied-alpha Lanczos resampling. The 1280 and 960 previews were resampled in linear light. The 960 2× crop is the lower-center 480 × 270 region at x=240, y=270, enlarged with nearest-neighbor to 960 × 540; this matches the existing V1 crop window.
- review-sheet.png compares the specified current gameplay frame, the existing V1 composite, and this V2 composite. The before frame retains its original UI text; V2 art assets contain no text.

## Prompt record

The summaries below capture the shared call constraints. The full prompt strings from each imagegen call are copied verbatim at the end of this file.

**Plate:** One opaque 1672 × 941 side-elevation slice of the approved Maintenance Corridor, Variant 2 graphic-painterly. Match key art B for palette, lighting, and mood only; match the approved far and mid corridor structure. Wet steel deck with the walk line at row 800 after upscale and reflections below it. Two overhead strip lamps above x≈36% and x≈75%, with the darkest gap behind WOLF’s back half. Far pipes and bulkhead are lighter and flatter; one near dark rib at the left edge, no more than 6% of width. No characters, stations, text, vanishing point, or baked figures. Large flat planes, 3–4 value steps per material, simplified panel lines, minimal texture.

**Engineer:** One transparent full-body side-profile cut-out, facing right in a quiet idle stance, source height 280 px. Match Rowan’s approved identity and costume: short tousled brown hair, hood down, deep-red hooded field jacket, charcoal trousers, black harness/utility belt, small cyan equipment light, gloves, dark boots; two arms and two legs. Add overhead top light and a broad cyan-white rim. Preserve a crisp silhouette, 3–4 value steps, minimal texture; no floor, shadow, text, extra props, or gendered identity.

**WOLF:** One transparent full-body robotic wolf, 460 px long, standing in side view facing right with head turned back toward the engineer. Grey-blue armor plates, visible circular joints, cyan eye and seams, exactly two ears, four legs/four paws, and an articulated segmented tail. Keep WOLF lower and longer than the first attempt; no fur, extra limbs, floor, shadow, text, or motion lines.

**Breaker:** One transparent front-facing dark-steel breaker cabinet, source height 388 px, cool graded with a single amber status lamp. Keep the face simple and readable, crisp shape-designed edges, broad cool rim, and minimal panel detail. No labels, text, floor, cast shadow, extra lights, or extra pipes.

**Coolant relay:** One transparent front-facing dark-steel relay cabinet, source height 356 px, cool graded with one cyan ring accent and a dark inactive top panel. Keep the silhouette and panel planes broad and clean; avoid added cyan bars, labels, text, floor, shadow, or extra fittings.

**Correction prompts:** Plate retries moved the wall/floor boundary down toward the target row; one edit moved it too low and a later edit moved it too high, so the row-702 source was selected. The first engineer result was rejected for a three-quarter pose and dark outline; the side-profile result was selected. The first WOLF result was rejected as too tall at 460 px long; it was regenerated longer/lower. The first relay result had an extra cyan bar/pipe; the second result was selected.

## QA and finishing

Ran the supplied qa_asset.py with python3 -I on all four cut-outs and all four composites. Final results: every cut-out passed A–G; every composite passed its site checks. The complete measurements are in qa/engineer.json, qa/wolf.json, qa/breaker.json, qa/relay.json, qa/composite-1920.json, qa/composite-1280.json, qa/composite-960.json, and qa/crop-960-2x.json.

| Cut-out | Canvas / opaque target | Baseline | Final A–G | H lost share | H contrast median |
|---|---:|---:|---|---:|---:|
| Engineer | 128 × 304 / 280 px tall | 295 | Pass | 0.064 | 1.92 |
| WOLF | 480 × 272 / 460 px long | 263 | Pass | 0.205 | 1.76 |
| Breaker | 288 × 416 / 388 px tall | 407 | Pass | — | — |
| Relay | 336 × 384 / 356 px tall | 375 | Pass | — | — |

H thresholds are lost share ≤0.35 and contrast median ≥1.6. Engineer and WOLF both pass. The visual review confirms WOLF has two ears and four paws, the engineer matches the costume lock, and the V2 plate/composite has no generated text.

First QA found these failures: engineer fringe-dark 0.1287, fringe-halo 0.3374, edge chroma shift 11.85, and H contrast 1.40; WOLF fringe-dark 0.3237, edge chroma shift 4.65, accent ΔE p90 18.2, and display noise 8.6; breaker fringe-halo 0.1387, edge chroma shift 5.45, and accent ΔE p90 30.5; relay outline ΔL −10.3 and accent ΔE p90 28.0. Fixes preserved alpha and sharpened none of the images: partial-alpha edge RGB was matched to its opaque interior ring, saturated out-of-palette pixels were mapped to the nearest bible accent, WOLF’s opaque RGB received a 3 × 3 median pass to reduce display noise, the relay’s dark silhouette rim was lifted, and the engineer received a tapered cyan rim. The engineer edge was rematched after adding that rim. Final QA was rerun after those changes and after stripping incidental PNG metadata.

The H checks used qa/plate-960.png as a plate-only background. Engineer: --bg-box 286,0,406,400 and --disp-h 93. WOLF: --bg-box 473,0,593,400 and --disp-h 80. Cut-out checks used --scale 0.25, --zoom 1.35, --zoom 1.8, and the listed baseline. Composite checks used --family site.

## Metadata and raw-output provenance

Yes, metadata was removed from the delivered PNGs. All 13 raw generated source files had a C2PA caBX chunk. The final cut-outs, plate, previews, crop, and review sheet contain no C2PA, EXIF, XMP, timestamp, or text chunks. Raw generated sources remain unchanged under ~/.codex/generated_images/01a127ac-2818-7fc0-8a60-f4c5364ee7b4. Raw SHA-256 hashes:

| Raw output ID | Selection / outcome | SHA-256 |
|---|---|---|
| 25b4510d-d800-485f-a0cb-dbc7e37b323d | Plate attempt 1; walk line too high | 9694710f3defd82eb9a7e0c0f08ff4440e973fb4e917b6fb1c1c5049880ad358 |
| acbc4dad-d2c0-4876-856f-6571307a58a1 | Plate attempt 2; walk line too high | 000c42bada23c7cee97e4e30d0f236685beaf1970b8713ef8ec244d2f753aba0 |
| 7c8f628e-0449-4e55-b45e-0c433138f54a | Plate attempt 3; walk line too high | a07610ed7a256ca2b3ab5488479d9dc3ca83eee6deab2357187e710301c8d97f |
| 4538cd59-d287-4051-a978-3825303dff1e | Plate edit 1; walk line too low | 0a7219241d831f13b770e2b2700829bba0082c160eb41400ad8f4a671bc2bc09 |
| 26a00a6c-88e8-4073-98a3-0661a69c1043 | Selected plate source | 19a162d07e0ff34b98815ff53addcad26471a120edc37bdddd2a4d0dcc0ffbb7 |
| 08961380-248b-4bea-aedc-690a3999f80a | Plate edit 3; walk line too high | 18994a32c746e7c6c0eef243a23c0a67efceb1c32fe706366384fe51728f9dda |
| 32a49bb3-c2d4-4ac4-b31a-826f42119026 | Engineer attempt 1; three-quarter pose/outline | 6e54f3fe3f4a3e441a2f5e1d5d0aff7e539fef38dd9582910bc5ff235bea0c82 |
| a207f79a-461c-4176-9122-deb72a1e68cb | Selected engineer | d7c349a96949138ce609a8f282ae7ff8c469805ec1c08964e155abd85684fd98 |
| 003f7762-7dd0-4be2-b110-8f4b6dbf1e56 | WOLF attempt 1; too tall | 7e2e1731b68d6e1cd35ca99108bc0caa86f4b83bf5a307e61cee9864c687a215 |
| f88e4fc4-b226-448c-a490-053b33a1d773 | Selected WOLF | 21288def6acaf3b4f7d5155788f8caf3680d3b5446ff4f6c8500da8d9de49f73 |
| d69997f5-4b7b-40cb-b224-9cc64903e0c4 | Selected breaker | 90c0d3b2a4ffe9d703cd34a2b601fb2723d90f4ee8d217ace7a9c68ed888d2ed |
| de8cfc3d-ab00-4c33-bb4b-d4497f916899 | Relay attempt 1; extra cyan bar/pipe | 0bc644b2deef9fae80d1e525cb533ae71beb4831a7e3b1c9aa588dd3b464c1fa |
| ccb5dea9-3c21-424c-aba1-4e22dd582cc2 | Selected relay | 30bc243f7d7226dc1689a5db9bba9de4a6d7bbe97f6a02c9e210df7233322ce9 |

No Git repository was written.

## Verbatim prompts used

The following are the prompt strings copied from each built-in imagegen call. Reference image roles and output hashes are recorded above and below.

### 25b4510d-d800-485f-a0cb-dbc7e37b323d — plate attempt 1 — rejected: walk line too high

~~~text
USE CASE: new asset (stylized-concept)
ASSET: WOLF//OVERRIDE maintenance-corridor background plate for the Variant 2 graphic-painterly style test.
OUTPUT: one opaque PNG, 16:9 landscape, target raw size 1672x941 for the documented 1.148x Lanczos upscale to 1920x1080. Empty plate only.
REFERENCE ROLES:
Image 1 = key art B: mood, cold palette, wet floor and lighting only; do not copy composition or figures.
Image 2 = approved corridor far layer: hazy pipe/bulkhead language only.
Image 3 = approved corridor mid layer: side-elevation industrial layout and floor treatment only.
Image 4 = split identity board: left is the engineer costume reference; right is WOLF design reference. Design guidance only; do not depict either.
Image 5 = split station board: left is breaker, right is coolant relay. Design guidance only; do not depict either station.
SCENE: a horizontal side-elevation slice of the same maintenance corridor, straight-on, no vanishing point or perspective tilt. Far wall and pipes are hazy, light, and flat. Mid wall is darker, with large readable steel panels and one broad panel line where there might otherwise be three. Wet steel deck; the exact walk line is at row 800 of the final 1080px image. All reflections stay below that line, vertically stretched and sparse. One dark near-layer foreground rib at the extreme left, occupying no more than 6% of the width.
COMPOSITION: two cold overhead strip lamps with soft blue shafts, centered above x=36% and x=75%; keep a deliberate darkest gap behind x=48–63% to test actor separation. No station hardware or station silhouette anywhere. A small, restrained amber reflection may sit below x=21% on the wet floor, with no visible source; it is the sole warm color. No other warm accents.
STYLE: Variant 2 graphic-painterly, shape-first graphic painting: flat value planes in 3–4 steps per material, minimal texture, crisp designed edges, painterly transitions only inside the two light pools and atmosphere. Strong value separation between layers: far layer lightest and flatter, mid layer dark, near rib almost pure silhouette. Broad readable detail at gameplay scale, little visual noise.
PALETTE: cold blue-black wall and shadow (#000307, #07101a, #121f2c, #1d3042), restrained lit steel (#2f4d69, #4175a0), cool cyan-white lamp cores and shafts; wet floor mid #1e2e3c and faint blue reflection #73a9cc. The only warm color is a tiny amber floor reflection near x=21%.
DO NOT: people, humanoids, wolves, animals, robots, stations, cabinets, breaker, relay, screens, controls, doors, text, letters, numerals, logos, watermark, borders, grain, scratches, dense greebles, magenta or pink, extra lamps, bright reflections above the walk line, baked contact shadows from actors or props.
~~~

### acbc4dad-d2c0-4876-856f-6571307a58a1 — plate attempt 2 — rejected: walk line too high

~~~text
USE CASE: new asset (stylized-concept)
ASSET: WOLF//OVERRIDE Maintenance Corridor, Variant 2 graphic-painterly background plate.
OUTPUT: opaque PNG, 16:9 landscape, raw dimensions 1672x941, to be Lanczos-upscaled exactly 1.148x to 1920x1080.
REFERENCE ROLES:
Image 1 = key art B, mood/light/palette only; do not copy its composition or figures.
Image 2 = approved far corridor shapes and haze only.
Image 3 = approved mid corridor wall and floor design only.
Image 4 = left panel is the engineer costume; right panel is WOLF design. Identity guidance only, neither appears here.
Image 5 = left panel is breaker; right panel is coolant relay. Station-design guidance only; neither appears here.
COMPOSITION, exact normalized coordinates on the final 1920x1080 plate:
- side elevation, straight-on, no vanishing point or perspective tilt.
- The painted wall-to-floor walk line is a perfectly level horizontal edge at y=800 (74.07% of frame); raw-generation equivalent y=697 of 941. Do not place it higher.
- Exactly two ceiling strip lamps, centered at x=36% and x=75% of frame, with soft cold shafts. The broad darkest unlit gap spans x=48–63%, behind the future WOLF.
- A single dark near-layer foreground rib only at the extreme left, x=0–6% width maximum; no other near foreground silhouette.
- Hazy far pipes and bulkhead are lighter/flatter than the darker mid wall. Wall surfaces are 3–4 flat value steps per material; only soft painted transitions inside the two lamp pools.
- Wet steel floor begins exactly at y=800. All reflections are below y=800, vertically stretched and sparse. A restrained small amber reflection only around x=21%, no visible source.
STYLE: shape-first graphic painting, minimal texture, crisp broad designed shapes, painterly only in light pools and atmosphere. Strong value separation by depth: far flat/light, mid wall dark, left near rib near-black. Low noise; no tiny scratches, grain, or busy floor speckles. Preserve the recognizable Maintenance Corridor steel panels and overhead pipes.
PALETTE: cold blue-black (#000307, #07101a, #121f2c, #1d3042), restrained cool steel (#2f4d69, #4175a0), cyan-white lamp cores and shafts; wet-floor mid #1e2e3c with faint cool reflections. The sole warm accent is the small amber reflection near x=21%.
DO NOT: characters, humanoids, animals, robotic wolf, stations, cabinets, breaker, relay, doors, controls, screens, text, letters, numerals, logos, watermark, borders, magenta/pink, extra lamps, reflection above the walk line, dense greebles, baked actor/prop shadows.
~~~

### 7c8f628e-0449-4e55-b45e-0c433138f54a — plate attempt 3 — rejected: walk line too high

~~~text
USE CASE: new asset (stylized-concept)
ASSET: WOLF//OVERRIDE Maintenance Corridor, Variant 2 graphic-painterly background plate.
OUTPUT: opaque 16:9 PNG at exactly 1672x941 raw size, to be Lanczos-upscaled exactly 1.148x to 1920x1080.
REFERENCE ROLES: image 1 is key art B for mood/light/palette only; image 2 is approved far corridor; image 3 is approved mid corridor; image 4 has engineer (left) and WOLF (right) for design guidance only; image 5 has breaker (left) and coolant relay (right) for design guidance only. None of the figures or stations appear on this background plate.
LAYOUT — obey these raw-pixel coordinates:
- The perfectly horizontal wall-to-floor walk line is at RAW y=740 of 941. This will land at y=849 if scaled directly, so instead leave the lower 21.5% as floor and place the wall/floor transition at exactly 78.6% height. (Use coordinate y=740, not y=697.) The floor reflection must remain only below that line.
- Place exactly two ceiling strip lamps at x=36% and x=75% of width. Leave the darkest broad wall gap from x=48% through 63%.
- One near-layer foreground rib touches the left edge and stops by x=2.5% of width. No second rib and no bulky side column.
SCENE: straight side elevation of a maintenance corridor, no vanishing point or perspective tilt. Light, flat, hazy far pipes and bulkhead behind a darker mid-wall of large steel panels. Wet steel deck only in lower 21.5% of canvas. Very sparse, long soft reflections below walk line: cyan beneath each ceiling lamp and a tiny amber reflection at x=21%, with no visible source. No other warm color.
VARIANT 2 STYLE: shape-first graphic painting, flat 3–4 value planes per material, minimal texture, crisp designed silhouettes, painterly only in the two lamp pools and atmosphere. No visible grain, speckles, dense scratches, tiny panel detail, or noisy puddle pattern. Strong depth separation: far flat/light, mid darker, near rib almost pure silhouette. Broad clean shapes.
PALETTE: cold blue-black (#000307, #07101a, #121f2c, #1d3042), restrained cool steel (#2f4d69, #4175a0), cyan-white lamp cores and shafts, wet floor mid #1e2e3c and faint reflection #73a9cc. Sole warm accent: small amber reflection #c89876.
DO NOT: people, humanoids, animals, robots, wolf, engineer, stations, cabinets, breaker, relay, doors, controls, screens, text, numbers, logos, watermark, borders, magenta or pink, extra lamps, reflections above the walk line, baked actor or prop shadows.
~~~

### 32a49bb3-c2d4-4ac4-b31a-826f42119026 — engineer attempt 1 — rejected: three-quarter pose and dark outline

~~~text
USE CASE: new asset (stylized-concept)
ASSET: one transparent 2D game cut-out of the WOLF//OVERRIDE engineer, Variant 2 graphic-painterly.
OUTPUT: one PNG with genuine transparent background (RGBA), portrait framing. Raw subject must be at least 350 px tall before the final downscale to 280 px tall. The figure fills about 78% of the canvas height, full body and boots visible with clear margin above and below.
REFERENCE ROLES:
Image 1 = approved identity/source guidance: key art B mood and palette only; ignore its composition and other figure pose.
Image 2 = far corridor atmosphere only.
Image 3 = mid corridor light and cool steel only.
Image 4 = split identity board: use the LEFT figure only for the engineer's exact identity/costume; ignore right WOLF for this generation.
Image 5 = split station board: design context only; do not depict a station.
SUBJECT: exactly one engineer, neutral idle stance, full-body, strict side view facing screen-right, level ground stance with both dark boots flat on the same baseline. Match the reference costume: short tousled brown hair, hood down, deep-red hooded field jacket, black harness and utility belt, one small cyan belt equipment light, charcoal trousers, gloves, dark boots. Exactly two arms and two legs. Keep the engineer's proportions and costume close to the identity reference. Do not gender the engineer.
STYLE: shape-first graphic painting, 3–4 flat value planes per material, minimal texture, crisp silhouette defined by value rather than a dark outline, 6–8 large readable shapes, painterly transitions only inside a few light planes. No grain, speckles, fabric microtexture, or small scratches. D=4 game sprite design, readable at small size.
LIGHTING: cold overhead light, noticeably lighter top-facing edges; broad cyan-white rim along top and back silhouette. Jacket red stays close to #a01e29 / #5f0e17; cyan only on the small belt light and restrained rim; neutral steel and charcoal lean cool blue. Shadows blue-black, never brown/grey.
TRANSPARENCY: clean hard transparent exterior, opaque body with only a 1–2 pixel antialiased edge; no matte, no colored background.
DO NOT: floor, ground plane, cast/contact shadow, reflection, glow outside the silhouette, extra figures, another hand/arm/leg, text, letters, logos, watermark, guide lines, magenta/pink on the subject, yellow clothing patches, silver knee armor, hood covering the head.
~~~

### a207f79a-461c-4176-9122-deb72a1e68cb — selected engineer

~~~text
USE CASE: new asset (stylized-concept)
ASSET: one transparent game cut-out of the WOLF//OVERRIDE engineer, Variant 2 graphic-painterly.
OUTPUT: one genuine transparent RGBA PNG, portrait. Full figure fills 75–80% of canvas height and is comfortably inside the frame. Raw figure height at least 350 px; final cut-out body height will be 280 px.
REFERENCE ROLES: image 1 is key art B for mood/palette only; image 2 far corridor ambience only; image 3 mid corridor light only; image 4's LEFT panel is the exact engineer identity/costume source (ignore the right WOLF); image 5 is station-design context only. Do not depict backgrounds or props.
SUBJECT: one engineer in strict orthographic side profile facing screen-right, not three-quarter view: head, chest, hips and boots all point right; show one eye in profile, one near-side arm and leg clearly, far-side arm and leg only slightly separated/partly occluded so the anatomy remains exactly two arms and two legs. Neutral standing idle pose, both boots flat on one baseline, hands relaxed. Keep the identity close to the left-panel reference: short tousled brown hair, hood down, deep-red hooded field jacket, black harness and utility belt, one small cyan belt equipment light, charcoal trousers, gloves, dark boots. Do not gender the engineer.
VARIANT 2 STYLE: shape-first graphic painting, 3–4 flat value planes per material, large simplified planes, no fine grain, no fabric pattern, no scratches, no glossy photorealism. Crisp designed silhouette. No inked contour, no black outline around the outer edge or interior forms; separate forms with adjacent flat values and broad light shapes instead. Keep all interior lines broad and sparse.
LIGHTING: top-facing planes visibly lighter than the body core; broad cyan-white rim on the top and back edge, not a thin dark contour. Red jacket stays within #a01e29 and #5f0e17; cyan confined to the belt light and restrained rim; cool blue-black shadows.
TRANSPARENCY: actual transparent outside the subject; body opaque, 1–2 px antialiased edge only. No colored matte.
DO NOT: floor, ground plane, contact shadow, reflection, halo, any glow outside silhouette, extra limbs, duplicate/extra hands, frontal or three-quarter pose, text, letters, numbers, logo, watermark, guide lines, magenta/pink, yellow patches, silver knee armour, hood up.
~~~

### 003f7762-7dd0-4be2-b110-8f4b6dbf1e56 — WOLF attempt 1 — rejected: too tall

~~~text
USE CASE: new asset (stylized-concept)
ASSET: one transparent WOLF robotic-wolf game cut-out for WOLF//OVERRIDE, Variant 2 graphic-painterly.
OUTPUT: genuine transparent RGBA PNG, wide landscape. The raw silhouette must be at least 575 px long and comfortably inside the image; final silhouette length will be 460 px after one downscale.
REFERENCE ROLES: image 1 key art B is mood/palette/light only; image 2 far corridor and image 3 mid corridor are atmosphere only; image 4 split identity board, use the RIGHT panel as WOLF design, the left engineer is not in this image; image 5 is station-design context only, no station appears.
SUBJECT: exactly one fully robotic wolf, strict orthographic side view facing screen-right, standing still on four paws. Its body is shorter and lower than the engineer. Head turned back toward screen-left to look at the engineer, like key art B, while the body/tail still faces right. Preserve the approved design: exactly 2 triangular ears, exactly 4 mechanical legs with exactly 4 distinct paws visible (two nearer and two farther, staggered so all four are countable), circular mechanical leg joints, grey-blue angular armor plates with low chroma C*≤8, articulated segmented armored tail, one cyan eye, restrained cyan seam lights. No fur, no organic anatomy, no harness, no extra limbs or paws.
VARIANT 2 STYLE: shape-first graphic painting; 3–4 broad flat value planes per material, minimal texture, crisp silhouette with broad rim shapes. No dark outline or inked contour around the silhouette or joints; form changes use adjacent flat value planes, not black strokes. Keep major armor plates simple and sparse, with no scratches, grain, speckles, or tiny bolts.
LIGHTING: cold overhead top light; top-facing armor planes lighter than body core. Broad cyan-white rim on top/back edges. Cyan only on eye and restrained seams/rim. Shadows cool blue-black, never warm brown.
TRANSPARENCY: genuinely transparent exterior; solid opaque body; only 1–2 px antialiased edge; no backdrop or matte.
DO NOT: floor, contact shadow, reflection, glow outside silhouette, extra ears, extra limbs, any missing paw, duplicated tail, fur, text, letters, numbers, logo, watermark, guide lines, magenta or pink.
~~~

### d69997f5-4b7b-40cb-b224-9cc64903e0c4 — selected breaker

~~~text
USE CASE: new asset (stylized-concept)
ASSET: one transparent breaker-station game cut-out for WOLF//OVERRIDE, Variant 2 graphic-painterly.
OUTPUT: genuine transparent RGBA PNG, portrait framing. The cabinet silhouette must be at least 485 px tall in the raw output so it can be downscaled once to an exact 388 px body height.
REFERENCE ROLES: image 1 key art B is mood/palette/light only; images 2 and 3 are corridor material context only; image 4 is character-design context only, no characters; image 5's LEFT panel is the approved breaker design/silhouette/function, ignore the relay on the right.
SUBJECT: one recognizable breaker station, a freestanding dark steel industrial cabinet with the same general compact upright silhouette/function as the left reference prop: narrow side pipe/handle, central breaker lever, a small amber status lamp in the upper panel. Side elevation, front surface turned only enough to read the lever, no perspective tilt. Keep silhouette simple and close to approved prop. One panel division only, where the existing three busy panels would collapse to a single broad plane. Preserve a clearly readable lever and amber status light.
VARIANT 2 STYLE: shape-first graphic painting; 3–4 large flat value planes per material; simplified, crisp shape-designed edges. Minimal detail; one focal lever and lamp, no tiny bolts/rivets, no scratches, no grain or microtexture. No black ink outline; separate forms with broad value changes and broad cool rim light.
PALETTE/LIGHT: cool-graded deep blue steel and charcoal (#07101a, #121f2c, #1d3042, #2f4d69); overhead top light brighter on upper surfaces and broad cyan-white top/back rim. The only warm color is the small lamp core #e0936e; no yellow or orange metal, no other accent. Keep accent under 12% of body.
TRANSPARENCY: authentic clear RGBA outside; opaque body; crisp 1–2 px antialiased edge. No background.
DO NOT: floor, base shadow, reflection, external glow, wires in empty space, extra controls, text/letters/numbers/labels, logo, watermark, guide lines, magenta/pink, extra lamp, multiple lever panels, busy scratches, a second object.
~~~

### de8cfc3d-ab00-4c33-bb4b-d4497f916899 — relay attempt 1 — rejected: extra cyan bar/pipe

~~~text
USE CASE: new asset (stylized-concept)
ASSET: one transparent coolant-relay station game cut-out for WOLF//OVERRIDE, Variant 2 graphic-painterly.
OUTPUT: genuine transparent RGBA PNG, portrait framing. Relay silhouette at least 445 px tall in raw output so it can be downscaled once to a 356 px body height.
REFERENCE ROLES: image 1 key art B supplies mood/palette/light only; images 2 and 3 are corridor material context; image 4 character-design context only, no figures; image 5 RIGHT panel is the approved coolant-relay design/silhouette/function (ignore breaker at left).
SUBJECT: one recognizable freestanding upright coolant relay, cool dark steel cabinet with the same general broad-square silhouette and function as the reference right-hand prop. Side elevation, front surface turned just enough to read the circular coolant coupling. Keep one broad top status panel and one central circular ring. The cyan light ring #30d0fc is the sole saturated accent, one accent only, under 12% of the body. No text, labels or markings.
VARIANT 2 STYLE: shape-first graphic painting; 3–4 broad flat value planes per material, minimal texture, crisp designed silhouette. Simplify three panel lines to one broad division. One focal ring and a few large plates only. No small bolts, scratches, grain, speckles, or microtexture. No black ink outline or dark contour; use adjacent value planes and a broad rim light.
LIGHTING: cold top light, top-facing planes lighter than core; broad cyan-white top/back rim. Steel and shadows cool blue-grey / blue-black, not brown or warm.
TRANSPARENCY: authentic transparent exterior, opaque body, 1–2 px antialiased edge. No matte/background.
DO NOT: floor, base shadow, reflection, glow outside silhouette, amber/orange/red/green, other lights, extra screens/buttons, text, letters, numbers, logo, watermark, guides, magenta or pink, second object.
~~~

### ccb5dea9-3c21-424c-aba1-4e22dd582cc2 — selected relay

~~~text
USE CASE: new asset (stylized-concept)
ASSET: one transparent coolant-relay station cut-out for WOLF//OVERRIDE, Variant 2 graphic-painterly.
OUTPUT: genuine transparent RGBA portrait PNG. The raw object silhouette must be at least 445 px tall; it will be downscaled to exactly 356 px tall.
REFERENCE ROLES: image 1 key art B supplies mood/palette/light only; images 2 and 3 are corridor material context only; image 4 is character-design context only, no figures; image 5's RIGHT panel is the approved coolant-relay silhouette/function, ignore the breaker on the left.
SUBJECT: one recognizable upright coolant relay: cool dark steel cabinet, broad-square body, one large circular coolant coupling centered on the front, short pipe loop on the right. Match the approved silhouette/function. Strict side-elevation prop with the front plane readable, no perspective tilt.
ONLY ACCENT: a single cyan #30d0fc ring surrounding the central circular coupling. The top rectangular status window is unlit dark steel, the right pipe is plain dark cool steel with no cyan, no blue glow, no light; do not add any other cyan light source.
VARIANT 2 STYLE: shape-first graphic painting, 3–4 broad flat value planes per material, minimal texture, simplified single panel division, crisp silhouette. One focal ring only. No tiny bolts, scratches, grain, speckles, microtexture, black ink outline or dark contour. Broad cool rim light on the top/back exterior edge; top-facing metal planes lighter than core.
PALETTE: cool blue-black / steel (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0); low chroma neutral metal. Cyan exists only on the one central ring. No warm colors.
TRANSPARENCY: authentic transparent exterior, body opaque, 1–2 px antialiased edge, no matte.
DO NOT: floor, base shadow, reflection, halo, glow outside silhouette, blue-lit pipe, cyan top bar or status lamp, amber/orange/red/green, extra screens/buttons/indicators, text, labels, numbers, logos, watermark, guides, magenta or pink, second object.
~~~

### 4538cd59-d287-4051-a978-3825303dff1e — plate edit 1 — rejected: walk line too low

~~~text
USE CASE: precise-object-edit of the existing corridor plate. One composition correction only.
ASSET: WOLF//OVERRIDE Maintenance Corridor, Variant 2 graphic-painterly empty background plate.
OUTPUT: opaque 16:9 PNG, exactly 1672x941 raw pixels. It will be Lanczos-upscaled 1.148x to 1920x1080.
REFERENCE ROLES:
Image 1 = the current plate edit target. Preserve its cold palette, broad graphic-painterly wall/floor treatment, two lamp pools, straight side elevation, dark middle gap, and empty scene.
Image 2 = layout guide only. Match its proportions and positions; ignore its flat colors and simple diagram style.
Image 3 = four-quadrant style/palette source: top-left key art B mood, top-right approved corridor far, bottom-left approved corridor mid, bottom-right palette swatches. Use them only for their respective mood, layer, rendering, and color roles.
Image 4 = engineer (left) and WOLF (right) identity guidance only. Neither is visible.
Image 5 = breaker (left) and coolant relay (right) design guidance only. Neither is visible.
CHANGE ONLY THE COMPOSITION: move the horizontal wall-to-floor walk line down to RAW y=697 of 941, exactly 74.07% of image height. This corresponds to y=800 in the 1080 final. The floor must occupy only the bottom 26% of the image. Keep the floor wholly below that line. Make the single left foreground rib stop by x=84 raw pixels (5% of width).
PRESERVE: two ceiling strip lamps centered at x=36% and x=75%; darkest open wall gap x=48–63%; side-on perspective-free corridor; broad steel panels; haze; sparse reflections below the walk line; same key art B cold blue palette and soft cyan lamp pools; no station or character shapes. Keep minimal graphic-painterly texture and crisp broad values.
DO NOT add/remove anything else. No actors, robots, wolf, engineer, stations, cabinets, breaker, relay, doors, controls, screen, text, letters, numbers, logos, watermark, borders, magenta/pink, extra lamps, bright reflections above the walk line, dense scratches or grain.
~~~

### 26a00a6c-88e8-4073-98a3-0661a69c1043 — selected plate source

~~~text
USE CASE: precise-object-edit. Correct one line only.
ASSET: WOLF//OVERRIDE Variant 2 Maintenance Corridor empty plate.
OUTPUT: opaque PNG, 1672x941. Keep the same scene and visual treatment.
REFERENCE ROLES:
Image 1 = edit target. Image 2 = layout-only guide, exact wall/floor boundary at raw y=697. Image 3 = key art B, corridor far/mid, palette board. Image 4 = engineer and WOLF identities, not to be drawn. Image 5 = breaker and relay designs, not to be drawn.
CHANGE ONLY the horizontal wall-to-floor boundary: it currently sits at approximately raw y=711; move it UP by 14 pixels so the actual walk line lands at exactly raw y=697 of 941 (74.07% height). After the 1.148x upscale, that is row 800 of 1080. Keep the same narrow floor, reflections below it, lamps, rib, wall, shading, palette and texture.
The guide image shows the desired boundary position. Treat its long horizontal wall/floor edge as exact; ignore its simplified colors.
DO NOT alter any other composition element; do not add characters, stations, controls, doors, text, logos, watermark, grain, or new lights.
~~~

### f88e4fc4-b226-448c-a490-053b33a1d773 — selected WOLF

~~~text
USE CASE: new asset (stylized-concept)
ASSET: transparent robotic WOLF game cut-out, WOLF//OVERRIDE Variant 2 graphic-painterly.
OUTPUT: genuine transparent RGBA, wide landscape. Subject at least 575 px long, fully inside frame; final length is 460 px, final height target is at most 246 px.
REFERENCE ROLES: image 1 key art B for mood/palette/light only; images 2 and 3 corridor atmosphere only; image 4 right panel is the exact robotic WOLF design reference (left engineer is not in this image); image 5 station design context only, no stations.
SUBJECT SHAPE: exactly one fully robotic wolf, strict side view facing screen-right, standing with head turned back left toward the engineer. Make it a long, low canine silhouette, not a tall upright wolf: nose-to-tail length at least 1.85 times the top-of-ears-to-paw height. Long horizontal torso and segmented tail, compact legs, low back. At final length 460 px, the full silhouette must be no taller than 246 px.
ANATOMY LOCKS: exactly 2 triangular ears, exactly 4 mechanical legs and 4 clearly countable paws, two near and two far legs staggered slightly. Circular mechanical leg joints. One articulated segmented armored tail. Grey-blue angular armour plates, low chroma C*≤8, one cyan eye and restrained cyan seams. No fur, no organic body, no extra or hidden paws.
VARIANT 2 STYLE: shape-first graphic painting, 3–4 large flat value planes per material, minimal texture, simplified plates, crisp silhouette with broad rim shapes. No black ink outlines or dark contour strokes; define form with neighboring values and planes, not line art. No tiny bolts, grain, scratches, speckles or microtexture.
LIGHTING: cold overhead light, top-facing planes lighter than core; broad cyan-white rim along top/back silhouette. Cyan only at eye/seams/rim; cool blue-black shadows.
TRANSPARENCY: clear transparent exterior; opaque body with only a 1–2 px antialiased edge. No matte.
DO NOT: floor, contact shadow, reflection, exterior glow, extra ears/legs/paws/tails, fur, text, numbers, logos, watermark, guides, magenta/pink.
~~~

### 08961380-248b-4bea-aedc-690a3999f80a — plate edit 3 — rejected: walk line too high

~~~text
USE CASE: precise-object-edit, one small alignment correction.
OUTPUT: same opaque empty corridor plate, 1672x941.
REFERENCE ROLES: image 1 is the plate to edit; image 2 is the exact layout guide; image 3 is the color/style source board; image 4 is identity guidance only; image 5 is station design guidance only.
Move ONLY the single horizontal wall-to-floor boundary upward to raw y=692 of 941 so the resulting plate boundary lands at raw y=697 after rendering. The requested final line is y=800 of the 1920x1080 plate. It is currently around raw y=702; move it up by 10 raw pixels. Preserve everything else exactly: cold graphic-painterly corridor, two lamps at 36% and 75%, dark gap at 48–63%, near rib at ≤5%, same textures, light pools, and sparse reflections below the line.
The lower floor area should begin at raw y=697. No other horizontal wall seam counts as the walk line.
No characters or stations. Do not add objects, details, or text.
~~~
