# Corridor breaker status-lamp edit

No image was kept. Each built-in image_gen call used `transparent_background=true` and returned RGBA output, so no magenta-background fallback was used. All three generated outputs are preserved byte-for-byte under `raw/rejected-breaker-*.png`.

## Call 1 — rejected

- Output file: `raw/rejected-breaker-1.png`
- Generated source: `[Codex generated-images store]/01a12820-5689-70c0-aa51-ae442314c5b0/exec-7f61ab99-c4d2-4513-87f9-e85e29b6b2da.png`
- Attached references, in order:
  1. `[session scratch, not kept]/hq/props/refs/styletest-breaker-raw.png` — approved Look 2 breaker edit target.
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — rendering, values, edges and cool grading only.
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light and palette only.
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — color swatches only.
  5. `apps/game/assets/props/corridor-breaker.png` — original breaker identity only.
- Verbatim prompt sent:
```text
Use case: precise-object-edit
Asset type: isolated, transparent side-view game prop sprite for WOLF//OVERRIDE.
Input images, in this exact order:
Image 1: [session scratch, not kept]/hq/props/refs/styletest-breaker-raw.png — approved Look 2 breaker edit target; preserve its identity, layout, function, silhouette, framing and rendering.
Image 2: [session scratch, not kept]/hq/props/refs/ref-look2-board.png — rendering, value structure, edge treatment and cool grading only; match the breaker and coolant relay rendering; do not copy its objects or figures.
Image 3: apps/game/assets/title-corridor-key-art-provisional.png — mood, light and palette only; do not copy its composition or figures.
Image 4: [session scratch, not kept]/hq/props/refs/palette-card.png — color swatches only.
Image 5: apps/game/assets/props/corridor-breaker.png — original breaker design for identity only.
Scene/backdrop: genuinely transparent RGBA, retaining real transparency and alpha. No background of any kind.
Primary request: change only the status lamp. The small horizontal amber lamp window near the top of the cabinet becomes an unlit lamp socket: retain exactly the same shape, size, position and footprint, but make the complete lamp window/socket surfaces dark cool glass and cool steel (#121f2c to #1d3042), with only a faint cool top highlight and absolutely no glow. Remove all visible amber, yellow, orange or other saturated accent color from the lamp surfaces; the game draws the lit lamp as a separate sprite on top.
Subject: the same single breaker cabinet shown in Image 1. Keep its cabinet, lever, right-hand pipe, feet, silhouette, proportions, layout, pixel dimensions, canvas framing, object size, rendering, lighting and rim light exactly unchanged. Keep the same straight side elevation with the front face toward the viewer, no perspective tilt or vanishing point, centered with the same roughly 6% margin and filling most of the frame. Do not redesign.
Style/medium: approved “Look 2, graphic-painterly”: shape-first graphic painting, large flat value planes, 3–4 value steps per material, minimal texture, crisp shape-designed silhouette. Painterly soft transitions only inside light pools or glows; this unlit socket has no glow. Cold overhead top light, with upward-facing surfaces lighter than the body, plus a broad cyan-white rim (#82c3e6 to #c3c5d7) on top and back edges. No dark outline or ink contour; define edges by value and rim light. Fully opaque object body with a clean 1–2 px antialiased silhouette edge, no matte fringe or halo. Cool steel and shadows in blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty. No grain, speckle, rust spots, scratches, tiny bolts or rivets, or fine panel lines; use one broad panel line where the old design had three. Preserve the existing approved design and do not add details.
Color palette: saturated color is allowed only on named accents and only from these swatches: signal red #a01e29 / #ad252d, red glow #ca452f, amber glow #e0936e, amber metal #82510e, dim amber #6e4824, cyan strip #30d0fc, cyan keypad #2091ca, cyan seam #4f8ab8, safe green #56dc69 / #228237 / #17632f. Use none of these saturated accents on this output; the object must have no saturated accent color.
Text: none. Do not include text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines or borders.
Avoid: any second object, floor, ground plane, cast/contact shadow, reflection, glow outside the silhouette, steam, sparks, magenta or pink, opaque/checkerboard background, or any change outside the status lamp.
```
- Verdict: rejected; colored cyan/magenta fringe remained around the exterior silhouette.

## Call 2 — rejected

- Output file: `raw/rejected-breaker-2.png`
- Generated source: `[Codex generated-images store]/01a12820-5689-70c0-aa51-ae442314c5b0/exec-b94a6d9b-e41d-427d-bcbb-ef0ba79d6799.png`
- Attached references, in order: same five paths and roles as Call 1.
- Verbatim prompt sent:
```text
Use case: precise-object-edit
Asset type: isolated, transparent side-view game prop sprite for WOLF//OVERRIDE.
Input images, in this exact order:
Image 1: [session scratch, not kept]/hq/props/refs/styletest-breaker-raw.png — approved Look 2 breaker edit target; preserve its identity, layout, function, silhouette, framing and rendering.
Image 2: [session scratch, not kept]/hq/props/refs/ref-look2-board.png — rendering, value structure, edge treatment and cool grading only; match the breaker and coolant relay rendering; do not copy its objects or figures.
Image 3: apps/game/assets/title-corridor-key-art-provisional.png — mood, light and palette only; do not copy its composition or figures.
Image 4: [session scratch, not kept]/hq/props/refs/palette-card.png — color swatches only.
Image 5: apps/game/assets/props/corridor-breaker.png — original breaker design for identity only.
Scene/backdrop: genuinely transparent RGBA, retaining real transparency and alpha. No background of any kind.
Primary request: change only the status lamp. The small horizontal amber lamp window near the top of the cabinet becomes an unlit lamp socket: retain exactly the same shape, size, position and footprint, but make the complete lamp window/socket surfaces dark cool glass and cool steel (#121f2c to #1d3042), with only a faint cool top highlight and absolutely no glow. Remove all visible amber, yellow, orange or other saturated accent color from the lamp surfaces; the game draws the lit lamp as a separate sprite on top.
Subject: the same single breaker cabinet shown in Image 1. Keep its cabinet, lever, right-hand pipe, feet, silhouette, proportions, layout, pixel dimensions, canvas framing, object size, rendering, lighting and rim light exactly unchanged. Keep the same straight side elevation with the front face toward the viewer, no perspective tilt or vanishing point, centered with the same roughly 6% margin and filling most of the frame. Do not redesign.
Style/medium: approved “Look 2, graphic-painterly”: shape-first graphic painting, large flat value planes, 3–4 value steps per material, minimal texture, crisp shape-designed silhouette. Painterly soft transitions only inside light pools or glows; this unlit socket has no glow. Cold overhead top light, with upward-facing surfaces lighter than the body, plus a broad cyan-white rim (#82c3e6 to #c3c5d7) on top and back edges. No dark outline or ink contour; define edges by value and rim light. Fully opaque object body with a clean 1–2 px antialiased silhouette edge, no matte fringe or halo. Cool steel and shadows in blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty. No grain, speckle, rust spots, scratches, tiny bolts or rivets, or fine panel lines; use one broad panel line where the old design had three. Preserve the existing approved design and do not add details.
Color palette: saturated color is allowed only on named accents and only from these swatches: signal red #a01e29 / #ad252d, red glow #ca452f, amber glow #e0936e, amber metal #82510e, dim amber #6e4824, cyan strip #30d0fc, cyan keypad #2091ca, cyan seam #4f8ab8, safe green #56dc69 / #228237 / #17632f. Use none of these saturated accents on this output; the object must have no saturated accent color.
Text: none. Do not include text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines or borders.
Avoid: any second object, floor, ground plane, cast/contact shadow, reflection, glow outside the silhouette, steam, sparks, magenta or pink, opaque/checkerboard background, or any change outside the status lamp.
Targeted retry correction: clean only the exterior silhouette alpha. Remove every cyan or magenta pixel fringe, stray pixel, halo or matte color outside the breaker. Keep only a clean 1–2 px antialiased silhouette edge and make all pixels outside it fully transparent. Preserve the broad cyan-white rim entirely on the object's top and back edges. Keep every object interior pixel and every object detail exactly as in the approved target and the previous edit, especially the now-dark unlit lamp; do not recolor, reshape or relight the cabinet, lever, pipe, feet, or any other part.
```
- Verdict: rejected; the edit was otherwise correct and transparent, but four magenta edge pixels remained with alpha 1, 1, 1 and 4 at (387,99), (390,100), (433,122) and (860,1079).

## Call 3 — rejected

- Output file: `raw/rejected-breaker-3.png`
- Generated source: `[Codex generated-images store]/01a12820-5689-70c0-aa51-ae442314c5b0/exec-433b11d0-fff4-4301-910f-08fb6d92dd9c.png`
- Prompt-declared references were the same five paths and roles as Calls 1–2. Actual attached order was:
  1. `[session scratch, not kept]/hq/props/refs/styletest-breaker-raw.png` — target.
  2. `apps/game/assets/title-corridor-key-art-provisional.png` — mood/light/palette reference, mistakenly attached at Image 2.
  3. `[session scratch, not kept]/hq/props/refs/palette-card.png` — palette reference, mistakenly attached at Image 3.
  4. `apps/game/assets/props/corridor-breaker.png` — design identity reference, mistakenly attached at Image 4.
  5. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering reference, mistakenly attached at Image 5.
- Verbatim prompt sent:
```text
Use case: precise-object-edit
Asset type: isolated, transparent side-view game prop sprite for WOLF//OVERRIDE.
Input images, in this exact order:
Image 1: [session scratch, not kept]/hq/props/refs/styletest-breaker-raw.png — approved Look 2 breaker edit target; preserve its identity, layout, function, silhouette, framing and rendering.
Image 2: [session scratch, not kept]/hq/props/refs/ref-look2-board.png — rendering, value structure, edge treatment and cool grading only; match the breaker and coolant relay rendering; do not copy its objects or figures.
Image 3: apps/game/assets/title-corridor-key-art-provisional.png — mood, light and palette only; do not copy its composition or figures.
Image 4: [session scratch, not kept]/hq/props/refs/palette-card.png — color swatches only.
Image 5: apps/game/assets/props/corridor-breaker.png — original breaker design for identity only.
Scene/backdrop: genuinely transparent RGBA, retaining real transparency and alpha. No background of any kind.
Primary request: change only the status lamp. The small horizontal amber lamp window near the top of the cabinet becomes an unlit lamp socket: retain exactly the same shape, size, position and footprint, but make the complete lamp window/socket surfaces dark cool glass and cool steel (#121f2c to #1d3042), with only a faint cool top highlight and absolutely no glow. Remove all visible amber, yellow, orange or other saturated accent color from the lamp surfaces; the game draws the lit lamp as a separate sprite on top.
Subject: the same single breaker cabinet shown in Image 1. Keep its cabinet, lever, right-hand pipe, feet, silhouette, proportions, layout, pixel dimensions, canvas framing, object size, rendering, lighting and rim light exactly unchanged. Keep the same straight side elevation with the front face toward the viewer, no perspective tilt or vanishing point, centered with the same roughly 6% margin and filling most of the frame. Do not redesign.
Style/medium: approved “Look 2, graphic-painterly”: shape-first graphic painting, large flat value planes, 3–4 value steps per material, minimal texture, crisp shape-designed silhouette. Painterly soft transitions only inside light pools or glows; this unlit socket has no glow. Cold overhead top light, with upward-facing surfaces lighter than the body, plus a broad cyan-white rim (#82c3e6 to #c3c5d7) on top and back edges. No dark outline or ink contour; define edges by value and rim light. Fully opaque object body with a clean 1–2 px antialiased silhouette edge, no matte fringe or halo. Cool steel and shadows in blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty. No grain, speckle, rust spots, scratches, tiny bolts or rivets, or fine panel lines; use one broad panel line where the old design had three. Preserve the existing approved design and do not add details.
Color palette: saturated color is allowed only on named accents and only from these swatches: signal red #a01e29 / #ad252d, red glow #ca452f, amber glow #e0936e, amber metal #82510e, dim amber #6e4824, cyan strip #30d0fc, cyan keypad #2091ca, cyan seam #4f8ab8, safe green #56dc69 / #228237 / #17632f. Use none of these saturated accents on this output; the object must have no saturated accent color.
Text: none. Do not include text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines or borders.
Avoid: any second object, floor, ground plane, cast/contact shadow, reflection, glow outside the silhouette, steam, sparks, magenta or pink, opaque/checkerboard background, or any change outside the status lamp.
Targeted retry correction: clean only the exterior silhouette alpha. Remove every cyan or magenta pixel fringe, stray pixel, halo or matte color outside the breaker. Keep only a clean 1–2 px antialiased silhouette edge and make all pixels outside it fully transparent. Preserve the broad cyan-white rim entirely on the object's top and back edges. Keep every object interior pixel and every object detail exactly as in the approved target and the previous edit, especially the now-dark unlit lamp; do not recolor, reshape or relight the cabinet, lever, pipe, feet, or any other part.
Final targeted correction: remove the four residual magenta pixels with nonzero alpha from the previous result, including the near-invisible edge pixels. No magenta or pink RGB may remain at any pixel whose alpha is greater than zero. Make all exterior pixels fully transparent; keep the intentional cool rim only inside the silhouette and preserve the dark unlit lamp.
```
- Verdict: rejected; the generated result cannot be accepted because its reference images were passed out of order.

## Raw byte-copy check

- Each `raw/rejected-breaker-*.png` file compared byte-for-byte equal to its listed generated source.
- No post-processing, resizing, matting or re-encoding was performed.

