# Image generation log

## pickup-cracked-gauge.png

- Output file: `raw/pickup-cracked-gauge.png`
- Source path: `[Codex generated-images store]/01a1283b-63b6-75b1-a695-3e127854aa20/exec-e682e5a4-7dc3-481a-bcaa-568d11ee7421.png`
- References:
  1. `[session scratch, not kept]/hq/props/refs/cracked-gauge-fixed.png` — Image 1, edit target; preserve silhouette, layout, function, color coding, tilt, and framing.
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Image 2, rendering, value structure, edge treatment, and cool grading only.
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — Image 3, mood, lighting, and palette only.
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — Image 4, colour swatches only.
- Verbatim prompt:

```text
Use case: precise-object-edit
Asset type: single pickup prop sprite for a 2D side-view sci-fi horror game, designed to remain readable at 24–30 world pixels tall.
Input images: Image 1 is the exact cracked-gauge edit target; preserve its silhouette, layout, function, diagonal tilt, framing, and existing color coding. Image 2 is rendering, value structure, edge treatment, and cool grading reference only; match the graphic-painterly rendering of the breaker and coolant relay, not their objects. Image 3 is mood, lighting, and palette reference only; do not copy its composition or figures. Image 4 is colour swatches only.
Primary request: make exactly two changes to Image 1. (1) Re-render the bezel ring and threaded stem as bright clean pale cool steel catching the overhead light: #9fb0c0 mid, #c3c5d7 lit, top edge near-white #e3f6fe, with only a slim #6f8396 mid-grey-blue shade on the lower outer edge. The bezel must not be darker than the face, and there must be no dark ring around the silhouette. Keep this steel matte, with broad value bands and no glossy hotspots. (2) Simplify the cracked glass to exactly 4–5 broad pale crack wedges radiating from one impact point on the left side of the face; use a few wide shapes only, with no thin hairlines or fine shards.
Keep unchanged: the cool off-white gauge face; the broad red zone arc on the upper right; the bold dark needle pointing past the red zone toward 4–5 o’clock, with its round hub; the existing silhouette, function, diagonal tilt, layout, framing, and centered placement. Make the gauge read as one bright, simple object with very few broad marks at 24–30 world pixels tall. Do not redesign it or add anything.
Style/medium: approved “Look 2, graphic-painterly” style. Shape-first graphic painting with large flat value planes, 3–4 value steps per material, minimal texture, and a crisp shape-designed silhouette. Painterly soft transitions only inside light pools and glows. No grain, speckles, rust, scratches, tiny bolts or rivets, or fine panel lines. Cold overhead top light so upward-facing surfaces are lighter than the body, plus a broad cyan-white rim (#82c3e6 to #c3c5d7) along the top and back edges. No dark outline or ink contour; define edges by value and rim light. Body fully opaque with a clean 1–2 px antialiased silhouette edge, no matte fringe or halo. Cool steel and shadows (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0); keep steel chroma low. Saturated colour only on the existing red zone, using signal red #a01e29 / #ad252d and red glow #ca452f. Mostly matte, dark overall, with broad value bands and no specular hotspots, chrome or plastic sheen.
Composition/framing: straight-on gauge face toward viewer with the original diagonal tilt preserved; object centered, about 6% margin on every side, filling most of a square frame.
Lighting/mood: cold overhead top light and restrained cyan-white top/back rim; dark corridor-ready values.
Scene/backdrop: genuinely transparent RGBA background.
Text (verbatim): none.
Constraints: keep the object itself fully opaque and preserve the alpha transparency outside its silhouette. No glow outside the silhouette.
Avoid: any text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, external glow, steam, sparks, a second object, magenta or pink.
```

- Verdict: kept; five broad crack wedges are visible, the bezel and stem are bright pale steel, and the existing gauge layout is retained. No retry was needed.

