# Service Junction ARM PANEL

Generation provenance for the raw asset. Both calls used built-in image_gen edit mode with the four references below in the listed order and requested a genuinely transparent background. Generated files were copied byte-for-byte; no resize, matte, or re-encoding was applied.

## Attempt 1 — rejected

- Output file: `raw/rejected-arm-panel-1.png`
- Source path: `[Codex generated-images store]/01a12828-51cb-7cd0-a12e-42721304e211/exec-34b58843-2326-47cc-995d-e5548a2dd0d3.png`
- Mode: built-in image_gen edit; transparent_background=true.
- Verdict: Rejected because amber hazard striping also appeared on the recessed bay backing; it did not meet the single-accent constraint. It had no text, extra object, floor, or reflection, and the background alpha was transparent.
- References:
- Image 1 — Design reference and edit target: preserve cabinet silhouette, layout, function, and color coding; re-render in Look 2.
  - apps/game/assets/props/junction-arm-panel.png
- Image 2 — Rendering, value structure, edge treatment, and cool grading only; do not copy objects or figures.
  - [session scratch, not kept]/hq/props/refs/ref-look2-board.png
- Image 3 — Mood, light, and palette only; do not copy composition or figures.
  - apps/game/assets/title-corridor-key-art-provisional.png
- Image 4 — Color swatches only.
  - [session scratch, not kept]/hq/props/refs/palette-card.png

Verbatim prompt sent:

```text
EDIT TARGET (Image 1): Re-render the same Service Junction ARM PANEL control cabinet for the tank arm. Preserve its silhouette, layout, function and color coding: upright rectangular cabinet on stepped feet, a pipe running up the left side, a ribbed conduit on the right, recessed central front bay with one large pull lever whose grip has broad diagonal hazard bands, and a vented lower door. Keep the composition straight side-elevation, front face toward viewer, no perspective tilt or vanishing point; center the single cabinet with about 6% margin on every side, filling most of the square frame.

Render in approved Look 2 graphic-painterly style: shape-first graphic painting, large flat value planes, 3–4 value steps per material, minimal texture, crisp shape-designed silhouette. Painterly soft transitions only inside light pools and glows (there are none here). Use cold overhead top light so upward faces are clearly lighter than the body, plus a broad cyan-white rim (#82c3e6 to #c3c5d7) along the top and back edges. No dark outline or ink contour; define edges through value and rim light. Matte, not glossy: no specular hotspots, chrome, plastic sheen, or smooth gradients along pipes. Each pipe, tube and box reads as three flat value bands: shadow, mid, lit top, plus the rim. Overall as dark as the Look 2 breaker: most body values between #121f2c and #2f4d69; only top faces and rim lighter. Steel is low-chroma cool blue-grey and blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty.

The only saturated accent is the lever grip's broad diagonal hazard bands in amber metal #82510e alternating with dark steel. Make all other parts cool dark steel. Near the top of the cabinet front, include exactly one horizontal lamp socket, a dark cool-glass slot about 25% of cabinet width; it is unlit, with no glow. The game draws this light separately. Keep the lever, socket, recessed bay, side pipes, feet and lower vent readable with broad designed shapes. Avoid fine panel lines; retain at most one broad panel line where the old design had three. Remove rust, scratches, grain, speckles and tiny bolts or rivets.

Reference use: Image 1 is the design reference and edit target; preserve its cabinet silhouette, layout, function and color coding, re-rendered in Look 2. Image 2 is only for rendering, value structure, edge treatment and cool grading; match the breaker and coolant relay on its board without copying any objects or figures. Image 3 is only for mood, light and palette; do not copy its composition or figures. Image 4 is only for color swatches.

Output a single fully opaque cabinet with a genuinely transparent RGBA background. Keep the alpha channel transparent outside the silhouette. Clean 1–2 px anti-aliased silhouette edge, no matte fringe or halo. No text, letters, numbers, labels, logos, warning words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, glow outside the silhouette, steam, sparks, second object, magenta or pink.
```

## Attempt 2 — kept

- Output file: `raw/arm-panel.png`
- Source path: `[Codex generated-images store]/01a12828-51cb-7cd0-a12e-42721304e211/exec-b610a1f4-9abf-4282-9c32-c4642d5ca162.png`
- Mode: built-in image_gen edit; transparent_background=true.
- Verdict: Kept: the bay backing is cool dark steel and amber hazard bands remain on the lever grip only; the cabinet layout and transparent background are present. The rendering has stronger bevels and more metallic highlights than the approved Look 2 target, but no further retry-worthy content issue.
- References:
- Image 1 — Design reference and edit target: preserve cabinet silhouette, layout, function, and color coding; re-render in Look 2.
  - apps/game/assets/props/junction-arm-panel.png
- Image 2 — Rendering, value structure, edge treatment, and cool grading only; do not copy objects or figures.
  - [session scratch, not kept]/hq/props/refs/ref-look2-board.png
- Image 3 — Mood, light, and palette only; do not copy composition or figures.
  - apps/game/assets/title-corridor-key-art-provisional.png
- Image 4 — Color swatches only.
  - [session scratch, not kept]/hq/props/refs/palette-card.png

Verbatim prompt sent:

```text
EDIT TARGET (Image 1): Re-render the same Service Junction ARM PANEL control cabinet for the tank arm. Preserve its silhouette, layout, function and color coding: upright rectangular cabinet on stepped feet, a pipe running up the left side, a ribbed conduit on the right, recessed central front bay with one large pull lever whose grip has broad diagonal hazard bands, and a vented lower door. Keep the composition straight side-elevation, front face toward viewer, no perspective tilt or vanishing point; center the single cabinet with about 6% margin on every side, filling most of the square frame.

Render in approved Look 2 graphic-painterly style: shape-first graphic painting, large flat value planes, 3–4 value steps per material, minimal texture, crisp shape-designed silhouette. Painterly soft transitions only inside light pools and glows (there are none here). Use cold overhead top light so upward faces are clearly lighter than the body, plus a broad cyan-white rim (#82c3e6 to #c3c5d7) along the top and back edges. No dark outline or ink contour; define edges through value and rim light. Matte, not glossy: no specular hotspots, chrome, plastic sheen, or smooth gradients along pipes. Each pipe, tube and box reads as three flat value bands: shadow, mid, lit top, plus the rim. Overall as dark as the Look 2 breaker: most body values between #121f2c and #2f4d69; only top faces and rim lighter. Steel is low-chroma cool blue-grey and blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty.

The only saturated accent is the lever grip's broad diagonal hazard bands in amber metal #82510e alternating with dark steel. Make all other parts cool dark steel. Near the top of the cabinet front, include exactly one horizontal lamp socket, a dark cool-glass slot about 25% of cabinet width; it is unlit, with no glow. The game draws this light separately. Keep the lever, socket, recessed bay, side pipes, feet and lower vent readable with broad designed shapes. Avoid fine panel lines; retain at most one broad panel line where the old design had three. Remove rust, scratches, grain, speckles and tiny bolts or rivets.

Reference use: Image 1 is the design reference and edit target; preserve its cabinet silhouette, layout, function and color coding, re-rendered in Look 2. Image 2 is only for rendering, value structure, edge treatment and cool grading; match the breaker and coolant relay on its board without copying any objects or figures. Image 3 is only for mood, light and palette; do not copy its composition or figures. Image 4 is only for color swatches.

Output a single fully opaque cabinet with a genuinely transparent RGBA background. Keep the alpha channel transparent outside the silhouette. Clean 1–2 px anti-aliased silhouette edge, no matte fringe or halo. No text, letters, numbers, labels, logos, warning words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, glow outside the silhouette, steam, sparks, second object, magenta or pink.

Targeted correction for this retry: remove the amber diagonal stripe pattern from the recessed bay backing entirely; make the bay backing uniform cool dark steel. Keep amber-and-dark diagonal hazard bands only on the lever grip. Preserve all other design, lighting, rendering, and transparency requirements.
```


