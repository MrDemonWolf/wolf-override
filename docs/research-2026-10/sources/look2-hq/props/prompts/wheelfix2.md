# Valve wheel repaint

## Attempt 1

- Output: `raw/rejected-valve-wheel-1.png`
- Source: `[Codex generated-images store]/01a128a9-b5c6-7fa2-9dbb-4337fbd93b69/exec-426d4ce7-ee76-42fd-888b-82fc8c15803c.png`
- Verdict: Rejected because the amber surfaces still read glossy and retained dark contouring, despite matching the wheel layout.

References:
- Image 1 — edit target, original wheel; preserve geometry/layout: `[session scratch, not kept]/hq/props/raw/valve2/raw/valve-wheel.png`
- Image 2 — Look 2 rendering/value/edge/cool grading only: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png`
- Image 3 — mood, light and palette only: `apps/game/assets/title-corridor-key-art-provisional.png`
- Image 4 — colour swatches only: `[session scratch, not kept]/hq/props/refs/palette-card.png`
- Image 5 — finished valve body; match steel values and matte rendering: `docs/research-2026-10/sources/look2-hq/props/junction-valve.png`

Verbatim prompt:
```text
Use case: precise-object-edit
Asset type: transparent sprite for a 2D side-view sci-fi horror game
Primary request: Repaint Image 1, the separate Service Junction valve handwheel, so it matches the matte, low-chroma valve body in Image 5. This is a repaint only.
Input images: Image 1 is the exact edit target; preserve its wheel geometry and layout. Image 2 is rendering, value structure, edge treatment and cool grading only; match the breaker and coolant relay rendering, but do not copy any object or figure. Image 3 is mood, light and palette only; do not copy its composition or figures. Image 4 is colour swatches only. Image 5 is the finished valve body the wheel mounts on; match its steel values and matte rendering exactly.
Scene/backdrop: none; output a genuinely transparent RGBA canvas, preserving alpha. The space between all five spokes and all space around the wheel must be transparent.
Subject and composition: a straight-on, face-on circular valve handwheel, centred exactly as in Image 1, with the same canvas framing, silhouette, round rim, exactly five spokes, hub size and placement. The wheel rotates around the canvas centre in game. Keep the exact face-on circle and framing identical to Image 1. Change only paint; do not redesign or move, resize, rotate, add, or remove any part.
Style/medium: Look 2 graphic-painterly shape-first game prop. Use large flat value planes, 3–4 value steps per material, minimal texture and a crisp shape-designed silhouette. Painterly soft transitions only inside light pools or glows; this object has no glow. No grain, speckle, rust, scratches, tiny bolts or rivets, fine panel lines, or extra detailing. No dark outline or ink contour anywhere. Edges are made by value and rim light, with a clean 1–2 px antialiased silhouette edge, no matte fringe or halo. The body is fully opaque.
Lighting/mood: cold overhead top light, with upward-facing surfaces clearly lighter than the body. Matte and dark, matching the Look 2 breaker in overall value: most body values are dark. No specular hotspots, chrome or plastic sheen, no smooth gradients along any pipe, rim or spoke.
Color palette and exact paint:
- RIM AND ALL FIVE SPOKES: exactly three flat amber paint value bands, with no lengthwise streaks or gradients. Use mid amber #82510e over most of every face; shadow amber #6e4824 on the lower, down-facing side of the rim and of each spoke; lit amber #a5682a on the upper, top-facing edge of the rim and the upper edges of the spokes. Add a broad cyan-white rim light from #82c3e6 to #c3c5d7 along the top outer edge of the rim only.
- HUB: replace the saturated navy-blue hub with low-chroma cool grey-blue steel matching Image 5, not saturated or navy blue. Keep the existing flange ring and raised round cap. Render each in three flat bands: shadow #1a2430, mid #2b3644, and lit top #455569. Add a thin cyan-white top rim to the hub.
Use only these named accent colours and these steel values on the wheel. Steel and shadows stay cool blue-grey to blue-black and low saturation, never warm grey, brown, rusty, bright blue or glossy.
Constraints: no text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, glow outside the silhouette, steam, sparks, a second object, magenta or pink on the object. Nothing else in the image.
```

## Attempt 2 (kept)

- Output: `raw/valve-wheel.png`
- Source: `[Codex generated-images store]/01a128a9-b5c6-7fa2-9dbb-4337fbd93b69/exec-e2952827-dc6e-4915-ba2b-60f99a0b38f2.png`
- Verdict: Kept as the flatter matte result; five-spoke layout and low-chroma steel hub are present, with RGBA transparency requested and no text or extra object.

References:
- Image 1 — edit target, original wheel; preserve geometry/layout: `[session scratch, not kept]/hq/props/raw/valve2/raw/valve-wheel.png`
- Image 2 — Look 2 rendering/value/edge/cool grading only: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png`
- Image 3 — mood, light and palette only: `apps/game/assets/title-corridor-key-art-provisional.png`
- Image 4 — colour swatches only: `[session scratch, not kept]/hq/props/refs/palette-card.png`
- Image 5 — finished valve body; match steel values and matte rendering: `docs/research-2026-10/sources/look2-hq/props/junction-valve.png`

Verbatim prompt:
```text
Use case: precise-object-edit
Asset type: transparent sprite for a 2D side-view sci-fi horror game
Primary request: Repaint Image 1, the separate Service Junction valve handwheel, so it matches the matte, low-chroma valve body in Image 5. This is a repaint only.
Input images: Image 1 is the exact edit target; preserve its wheel geometry and layout. Image 2 is rendering, value structure, edge treatment and cool grading only; match the breaker and coolant relay rendering, but do not copy any object or figure. Image 3 is mood, light and palette only; do not copy its composition or figures. Image 4 is colour swatches only. Image 5 is the finished valve body the wheel mounts on; match its steel values and matte rendering exactly.
Scene/backdrop: none; output a genuinely transparent RGBA canvas, preserving alpha. The space between all five spokes and all space around the wheel must be transparent.
Subject and composition: a straight-on, face-on circular valve handwheel, centred exactly as in Image 1, with the same canvas framing, silhouette, round rim, exactly five spokes, hub size and placement. The wheel rotates around the canvas centre in game. Keep the exact face-on circle and framing identical to Image 1. Change only paint; do not redesign or move, resize, rotate, add, or remove any part.
Style/medium: Look 2 graphic-painterly shape-first game prop. Use large flat value planes, 3–4 value steps per material, minimal texture and a crisp shape-designed silhouette. Painterly soft transitions only inside light pools or glows; this object has no glow. No grain, speckle, rust, scratches, tiny bolts or rivets, fine panel lines, or extra detailing. No dark outline or ink contour anywhere. Edges are made by value and rim light, with a clean 1–2 px antialiased silhouette edge, no matte fringe or halo. The body is fully opaque.
Lighting/mood: cold overhead top light, with upward-facing surfaces clearly lighter than the body. Matte and dark, matching the Look 2 breaker in overall value: most body values are dark. No specular hotspots, chrome or plastic sheen, no smooth gradients along any pipe, rim or spoke.
Color palette and exact paint:
- RIM AND ALL FIVE SPOKES: exactly three flat amber paint value bands, with no lengthwise streaks or gradients. Use mid amber #82510e over most of every face; shadow amber #6e4824 on the lower, down-facing side of the rim and of each spoke; lit amber #a5682a on the upper, top-facing edge of the rim and the upper edges of the spokes. Add a broad cyan-white rim light from #82c3e6 to #c3c5d7 along the top outer edge of the rim only.
- HUB: replace the saturated navy-blue hub with low-chroma cool grey-blue steel matching Image 5, not saturated or navy blue. Keep the existing flange ring and raised round cap. Render each in three flat bands: shadow #1a2430, mid #2b3644, and lit top #455569. Add a thin cyan-white top rim to the hub.
Use only these named accent colours and these steel values on the wheel. Steel and shadows stay cool blue-grey to blue-black and low saturation, never warm grey, brown, rusty, bright blue or glossy.
Constraints: no text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, glow outside the silhouette, steam, sparks, a second object, magenta or pink on the object. Nothing else in the image.

Targeted correction for this retry: flatten the rim and spokes to the three specified matte amber value bands. Remove the prior glossy highlights, smooth gradients, and dark outline-like contours; define the existing wheel forms with flat value planes and the specified narrow edge lighting only. Preserve the exact wheel geometry, centring, framing, hub construction, and transparent openings.
```

