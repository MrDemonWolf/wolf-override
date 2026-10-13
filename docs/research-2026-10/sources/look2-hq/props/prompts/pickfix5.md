# Image generation record

Both calls used the built-in image_gen edit mode with transparent_background=true and the same five references in this order:

- Image 1: [session scratch, not kept]/hq/props/raw/pickfix4/raw/pickup-cracked-gauge.png — edit target; preserve silhouette, layout, function, colours, tilt, framing, and details.
- Image 2: [session scratch, not kept]/hq/props/refs/ref-look2-board.png — rendering/value/edge style only; do not copy objects or figures.
- Image 3: apps/game/assets/title-corridor-key-art-provisional.png — mood, light, and palette only; do not copy composition or figures.
- Image 4: [session scratch, not kept]/hq/props/refs/palette-card.png — colour swatches only.
- Image 5: docs/research-2026-10/sources/look2-hq/props/junction-valve.png — matte steel values only; do not copy its design.

## Rejected attempt 1

- Output file: raw/rejected-pickup-cracked-gauge-1.png
- Source path: [Codex generated-images store]/01a128af-d29b-7e13-96ba-b7a8f0e3eb34/exec-a0ded8a8-3a1f-4feb-9e0a-2d1f74c9bca5.png
- References in order:
  - Image 1: [session scratch, not kept]/hq/props/raw/pickfix4/raw/pickup-cracked-gauge.png — edit target; preserve silhouette, layout, function, colours, tilt, framing, and details.
  - Image 2: [session scratch, not kept]/hq/props/refs/ref-look2-board.png — rendering/value/edge style only; do not copy objects or figures.
  - Image 3: apps/game/assets/title-corridor-key-art-provisional.png — mood, light, and palette only; do not copy composition or figures.
  - Image 4: [session scratch, not kept]/hq/props/refs/palette-card.png — colour swatches only.
  - Image 5: docs/research-2026-10/sources/look2-hq/props/junction-valve.png — matte steel values only; do not copy its design.
- Verdict: Rejected after visual inspection because several wedge ends were narrower than the requested one-seventh face-width minimum; other gauge details and transparent alpha were preserved.
- Verbatim prompt:

```
Use case: precise-object-edit
Asset type: one transparent 2D side-view sci-fi horror game pickup sprite.
Input images: Image 1 is the edit target and controls the gauge's silhouette, layout, function, colour coding, tilt, framing, and all preserved details. Image 2 is a rendering reference only: match the Look 2 breaker and coolant relay's shape-first graphic-painterly value planes and edge treatment; do not copy its objects or figures. Image 3 is mood, lighting, and palette guidance only; do not copy its composition or figures. Image 4 is colour swatches only. Image 5 is a finished Look 2 prop from the same room and guides matte steel values only; do not copy its design.
Primary request: make one last correction to the cracked gauge by changing only the crack star. Replace the current fine, many-part crack pattern with exactly five dark, solid, broad tapered wedges radiating from the one impact point on the left half of the gauge face. Each wedge has a broad end at least one seventh of the face diameter wide and reaches most of the way to the bezel. Leave clear grey face between neighbouring wedges so all five read as separate shapes. Keep the small dark chipped pit at the impact point. Use the same dark cool values as the current design: #2c3846 cores and #435265 edges. No hairlines, fine shards, thin cracks, or pale crack lines.
Keep exactly as in Image 1: the dim cool-grey face values; matte three-band steel bezel and threaded stem with cyan-white top rim; broad red zone arc on the upper right; bold dark needle pointing past the red zone toward 4–5 o'clock and its round hub; silhouette, diagonal tilt, and framing. Preserve the genuinely transparent RGBA background.
Style: Look 2, graphic-painterly. Shape-first graphic painting with large flat value planes, 3–4 value steps per material, minimal texture, crisp designed silhouette, and painterly soft transitions only inside light pools and glows. Cold overhead top light; upward faces are clearly lighter than the body. Broad cyan-white rim (#82c3e6 to #c3c5d7) along top and back edges. No dark outline or ink contour. Fully opaque object body. Matte, not glossy: no specular hotspots, chrome, plastic sheen, or smooth gradients along pipes. Steel and shadows are cool blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), with low steel chroma; most of the body stays between #121f2c and #2f4d69, with only top faces and rim lighter. Saturated colour only on the red zone accent, using the approved red swatches.
Composition: straight side-elevation game prop, front face toward the viewer, preserving Image 1's diagonal tilt. Gauge centred and filling most of the frame, about 6% margin on every side.
Avoid: any text, letters, numbers, labels, logos, UI, watermark, guide lines, borders, floor, ground plane, cast/contact shadow, reflection, glow outside the silhouette, steam, sparks, a second object, magenta or pink, or any changes outside the crack star.
```

## Kept attempt 2

- Output file: raw/pickup-cracked-gauge.png
- Source path: [Codex generated-images store]/01a128af-d29b-7e13-96ba-b7a8f0e3eb34/exec-bf9f11af-b159-41b5-9524-5a0fac9f81c1.png
- References in order:
  - Image 1: [session scratch, not kept]/hq/props/raw/pickfix4/raw/pickup-cracked-gauge.png — edit target; preserve silhouette, layout, function, colours, tilt, framing, and details.
  - Image 2: [session scratch, not kept]/hq/props/refs/ref-look2-board.png — rendering/value/edge style only; do not copy objects or figures.
  - Image 3: apps/game/assets/title-corridor-key-art-provisional.png — mood, light, and palette only; do not copy composition or figures.
  - Image 4: [session scratch, not kept]/hq/props/refs/palette-card.png — colour swatches only.
  - Image 5: docs/research-2026-10/sources/look2-hq/props/junction-valve.png — matte steel values only; do not copy its design.
- Verdict: Kept; five broader separated crack wedges are visible, the gauge details remain intact, no text or second object is present, and the output has transparent alpha.
- Verbatim prompt:

```
Use case: precise-object-edit
Asset type: one transparent 2D side-view sci-fi horror game pickup sprite.
Input images: Image 1 is the edit target and controls the gauge's silhouette, layout, function, colour coding, tilt, framing, and all preserved details. Image 2 is a rendering reference only: match the Look 2 breaker and coolant relay's shape-first graphic-painterly value planes and edge treatment; do not copy its objects or figures. Image 3 is mood, lighting, and palette guidance only; do not copy its composition or figures. Image 4 is colour swatches only. Image 5 is a finished Look 2 prop from the same room and guides matte steel values only; do not copy its design.
Primary request: make one last correction to the cracked gauge by changing only the crack star. Replace the current fine, many-part crack pattern with exactly five dark, solid, broad tapered wedges radiating from the one impact point on the left half of the gauge face. Make every one of the five wedges unmistakably broad at its bezel-side end: each end must be at least one seventh of the gauge face diameter wide, measured perpendicular to the wedge's radial direction. Treat them as substantial solid triangular sectors, not narrow rays. Let each wedge reach most of the way to the bezel. Leave a generous clear-grey face gap between every neighbouring wedge so all five remain distinct. Keep the small dark chipped pit at the impact point. Use the same dark cool values as the current design: #2c3846 cores and #435265 edges. No hairlines, fine shards, thin cracks, pale crack lines, or additional crack rays.
Keep exactly as in Image 1: the dim cool-grey face values; matte three-band steel bezel and threaded stem with cyan-white top rim; broad red zone arc on the upper right; bold dark needle pointing past the red zone toward 4–5 o'clock and its round hub; silhouette, diagonal tilt, and framing. Preserve the genuinely transparent RGBA background.
Style: Look 2, graphic-painterly. Shape-first graphic painting with large flat value planes, 3–4 value steps per material, minimal texture, crisp designed silhouette, and painterly soft transitions only inside light pools and glows. Cold overhead top light; upward faces are clearly lighter than the body. Broad cyan-white rim (#82c3e6 to #c3c5d7) along top and back edges. No dark outline or ink contour. Fully opaque object body. Matte, not glossy: no specular hotspots, chrome, plastic sheen, or smooth gradients along pipes. Steel and shadows are cool blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), with low steel chroma; most of the body stays between #121f2c and #2f4d69, with only top faces and rim lighter. Saturated colour only on the red zone accent, using the approved red swatches.
Composition: straight side-elevation game prop, front face toward the viewer, preserving Image 1's diagonal tilt. Gauge centred and filling most of the frame, about 6% margin on every side.
Avoid: any text, letters, numbers, labels, logos, UI, watermark, guide lines, borders, floor, ground plane, cast/contact shadow, reflection, glow outside the silhouette, steam, sparks, a second object, magenta or pink, or any changes outside the crack star.
```

