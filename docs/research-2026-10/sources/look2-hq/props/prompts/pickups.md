# Pickup art generation log

Built-in `image_gen` edit mode was used for each call with the listed local references in order and `transparent_background: true`.

**Result:** no asset passed all constraints, so no final pickup was kept. Every generated PNG was copied byte-for-byte into `raw/` as a rejected attempt. No magenta fallback or image post-processing was used.

## pickup-data-cartridge.png — generation 1

- Output file: `raw/rejected-pickup-data-cartridge-1.png`
- Source: `[Codex generated-images store]/01a12820-5692-7861-a5d4-3157b1dca16f/exec-30dec326-22bc-415d-8610-ad1ba804f86a.png`
- References:
  - Image 1: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 2: `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only; do not copy composition or figures.
  - Image 3: `[session scratch, not kept]/hq/props/refs/palette-card.png` — Colour swatches only.
- Verdict: Rejected: diffuse exterior halo/transparent haze; image has no fully opaque pixels and excessive small bevel/detail. Copied byte-for-byte to raw/rejected-pickup-data-cartridge-1.png.

Verbatim prompt sent:

```text
Use case: stylized-concept
Asset type: transparent 2D side-view sci-fi horror game pickup sprite, shown only 20–32 world pixels tall/long
Input images: Image 1 is the Look 2 board for rendering, value structure, edge treatment, and cool grading only; Image 2 is key art for mood, light, and palette only; Image 3 is the palette card for swatches only. Do not copy their objects, figures, or composition.
Scene/backdrop: genuinely transparent RGBA background; no scene or ground.
Subject: one compact cartridge reader pickup assembly, a small dark cool-steel block wider than tall. Front face toward viewer in straight side elevation, no perspective tilt. A horizontal slot on the front holds a cool light-grey cartridge (#8a96a6 lit to #4a5666 shadow), seated with its back third sticking out. The cartridge has one plain scraped blank label patch, without text. Add exactly one tiny cyan activity light (#30d0fc).
Style/medium: match the Look 2 station rendering; shape-first graphic painting with large flat value planes, crisp designed silhouette, minimal texture, and only 3–4 value steps per material. Use painterly soft transitions only inside light pools and glows; no grain, speckle, scratches, tiny bolts, rivets, or fine panel lines.
Composition/framing: object centered and filling most of a 3:2 landscape canvas, with about 6% clear margin on every side; keep all of the pickup inside the canvas.
Lighting/mood: cold overhead top light, upward-facing planes clearly lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) on top and back edges.
Color palette: cool steel and shadows in blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), body mostly mid-dark; grey cartridge and the single named cyan light only. No warm greys or browns.
Materials/textures: fully opaque painted object, clean 1–2 px anti-aliased silhouette, no matte fringe or halo.
Text: none.
Constraints: no dark outline or ink contour; no floor, ground plane, contact/cast shadow, reflection, glow outside the silhouette, steam, sparks, second object, letters, numbers, labels, logos, UI, watermark, guide lines, border, magenta, or pink. Only the reader and its seated cartridge as one assembled pickup. Preserve clean genuine alpha transparency outside the object.
```

## pickup-data-cartridge.png — generation 2

- Output file: `raw/rejected-pickup-data-cartridge-2.png`
- Source: `[Codex generated-images store]/01a12820-5692-7861-a5d4-3157b1dca16f/exec-92093066-fdce-4b3e-a1a5-839eb8c87991.png`
- References:
  - Image 1: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 2: `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only; do not copy composition or figures.
  - Image 3: `[session scratch, not kept]/hq/props/refs/palette-card.png` — Colour swatches only.
- Verdict: Rejected: alpha inspection found a low-alpha blue haze outside the silhouette over nearly the whole canvas (alpha>=1 bounds 0,69–1522,1020). Copied byte-for-byte to raw/rejected-pickup-data-cartridge-2.png.

Verbatim prompt sent:

```text
Use case: stylized-concept
Asset type: transparent 2D side-view sci-fi horror game pickup sprite, shown only 20–32 world pixels tall/long
Input images: Image 1 is the Look 2 board for rendering, value structure, edge treatment, and cool grading only; Image 2 is key art for mood, light, and palette only; Image 3 is the palette card for swatches only. Do not copy their objects, figures, or composition.
Scene/backdrop: genuinely transparent RGBA background; no scene or ground.
Subject: one compact cartridge reader pickup assembly, a small dark cool-steel block wider than tall. Front face toward viewer in straight side elevation, no perspective tilt. A horizontal slot on the front holds a cool light-grey cartridge (#8a96a6 lit to #4a5666 shadow), seated with its back third sticking out. The cartridge has one plain scraped blank label patch, without text. Add exactly one tiny cyan activity light (#30d0fc).
Style/medium: match the Look 2 station rendering; shape-first graphic painting with large flat value planes, crisp designed silhouette, minimal texture, and only 3–4 value steps per material. Use painterly soft transitions only inside light pools and glows; no grain, speckle, scratches, tiny bolts, rivets, or fine panel lines.
Composition/framing: object centered and filling most of a 3:2 landscape canvas, with about 6% clear margin on every side; keep all of the pickup inside the canvas.
Lighting/mood: cold overhead top light, upward-facing planes clearly lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) on top and back edges.
Color palette: cool steel and shadows in blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), body mostly mid-dark; grey cartridge and the single named cyan light only. No warm greys or browns.
Materials/textures: fully opaque painted object, clean 1–2 px anti-aliased silhouette, no matte fringe or halo.
Text: none.
Constraints: no dark outline or ink contour; no floor, ground plane, contact/cast shadow, reflection, glow outside the silhouette, steam, sparks, second object, letters, numbers, labels, logos, UI, watermark, guide lines, border, magenta, or pink. Only the reader and its seated cartridge as one assembled pickup. Preserve clean genuine alpha transparency outside the object.
Targeted retry correction: simplify the reader into a compact pickup made from only a few broad shape planes with no tiny bevels or fine internal contours. Make the reader and cartridge fully opaque; every pixel outside their clean silhouette must be completely transparent alpha 0, with absolutely no exterior haze, rim glow, shadow, or background.
```

## pickup-data-cartridge.png — generation 3

- Output file: `raw/rejected-pickup-data-cartridge-3.png`
- Source: `[Codex generated-images store]/01a12820-5692-7861-a5d4-3157b1dca16f/exec-2c18381f-69a4-477b-aa20-bbdc247cddbf.png`
- References:
  - Image 1: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 2: `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only; do not copy composition or figures.
  - Image 3: `[session scratch, not kept]/hq/props/refs/palette-card.png` — Colour swatches only.
- Verdict: Rejected: alpha inspection shows low-alpha haze beyond the silhouette (alpha>=1 bounds 31,67–1504,1000). Copied byte-for-byte to raw/rejected-pickup-data-cartridge-3.png.

Verbatim prompt sent:

```text
Use case: stylized-concept
Asset type: transparent 2D side-view sci-fi horror game pickup sprite, shown only 20–32 world pixels tall/long
Input images: Image 1 is the Look 2 board for rendering, value structure, edge treatment, and cool grading only; Image 2 is key art for mood, light, and palette only; Image 3 is the palette card for swatches only. Do not copy their objects, figures, or composition.
Scene/backdrop: genuinely transparent RGBA background; no scene or ground.
Subject: one compact cartridge reader pickup assembly, a small dark cool-steel block wider than tall. Front face toward viewer in straight side elevation, no perspective tilt. A horizontal slot on the front holds a cool light-grey cartridge (#8a96a6 lit to #4a5666 shadow), seated with its back third sticking out. The cartridge has one plain scraped blank label patch, without text. Add exactly one tiny cyan activity light (#30d0fc).
Style/medium: match the Look 2 station rendering; shape-first graphic painting with large flat value planes, crisp designed silhouette, minimal texture, and only 3–4 value steps per material. Use painterly soft transitions only inside light pools and glows; no grain, speckle, scratches, tiny bolts, rivets, or fine panel lines.
Composition/framing: object centered and filling most of a 3:2 landscape canvas, with about 6% clear margin on every side; keep all of the pickup inside the canvas.
Lighting/mood: cold overhead top light, upward-facing planes clearly lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) on top and back edges.
Color palette: cool steel and shadows in blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), body mostly mid-dark; grey cartridge and the single named cyan light only. No warm greys or browns.
Materials/textures: fully opaque painted object, clean 1–2 px anti-aliased silhouette, no matte fringe or halo.
Text: none.
Constraints: no dark outline or ink contour; no floor, ground plane, contact/cast shadow, reflection, glow outside the silhouette, steam, sparks, second object, letters, numbers, labels, logos, UI, watermark, guide lines, border, magenta, or pink. Only the reader and its seated cartridge as one assembled pickup. Preserve clean genuine alpha transparency outside the object.
Targeted retry correction: simplify the reader into a compact pickup made from only a few broad shape planes with no tiny bevels or fine internal contours. Make the reader and cartridge fully opaque; every pixel outside their clean silhouette must be completely transparent alpha 0, with absolutely no exterior haze, rim glow, shadow, or background.
Final retry correction: treat this as a crisp cutout sprite, not a light effect. Render a solid, opaque body with only a narrow cyan-white highlight band painted on the top/back edge. Do not paint any background, bloom, haze, or shadow. The pixels beyond the 1–2 px anti-aliased silhouette must have alpha exactly 0; keep the cartridge reader shape simple and chunky.
```

## pickup-lockout-tag.png — generation 1

- Output file: `raw/rejected-pickup-lockout-tag-1.png`
- Source: `[Codex generated-images store]/01a12820-5692-7861-a5d4-3157b1dca16f/exec-90c03300-e99d-4a38-be5e-ec0924d4d8b6.png`
- References:
  - Image 1: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 2: `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only; do not copy composition or figures.
  - Image 3: `[session scratch, not kept]/hq/props/refs/palette-card.png` — Colour swatches only.
- Verdict: Rejected: low-alpha exterior haze extends beyond the object; visible dark contour lines also violate the style. Copied byte-for-byte to raw/rejected-pickup-lockout-tag-1.png.

Verbatim prompt sent:

```text
Use case: stylized-concept
Asset type: transparent 2D side-view sci-fi horror game pickup sprite, shown only 20–32 world pixels tall/long
Input images: Image 1 is the Look 2 board for rendering, value structure, edge treatment, and cool grading only; Image 2 is key art for mood, light, and palette only; Image 3 is the palette card for swatches only. Do not copy their objects, figures, or composition.
Scene/backdrop: genuinely transparent RGBA, object only; no wall, environment, floor, or ground.
Subject: one compact lockout-tag pickup assembly in front elevation on a portrait canvas about 1:2. A small steel mounting plate holds a short bent steel wall hook. A closed steel padlock hangs from the hook, with its locked shackle forming an empty loop around nothing. A short steel ring hangs a rectangular signal-red lockout tag (#a01e29 lit, #5f0e17 shadow) from the padlock. The tag is completely blank, with one round open grommet hole. Keep it chunky and readable; no feature smaller than 1/20 of the whole pickup.
Style/medium: match the Look 2 stations: shape-first graphic painting, large flat value planes, crisp shape-designed silhouette, minimal texture, 3–4 value steps per material. Painterly soft transitions only inside material shading; no grain, speckle, rust, scratches, tiny bolts/rivets, or fine panel lines.
Composition/framing: centered, fills most of the portrait canvas with about 6% clear margin on every side; keep the whole assembly inside frame.
Lighting/mood: cold overhead top light with upward planes lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) rendered as a narrow painted highlight on the object's top/back edges, not emitted light.
Color palette: cool blue-grey to blue-black steel (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), with signal red only on the tag. No warm greys, brown, magenta, or pink.
Materials/textures: opaque painted steel and tag; clean 1–2 px anti-aliased outside silhouette; no matte fringe or halo. Pixels beyond the anti-aliased silhouette are fully transparent alpha 0.
Text: none.
Constraints: no dark outline or ink contour; no floor, ground plane, cast/contact shadow, reflection, glow/haze outside silhouette, steam, sparks, second object, text, letters, numbers, labels, symbols, logos, UI, watermark, guide lines, or border. Preserve genuine transparency outside the single assembled pickup.
```

## pickup-lockout-tag.png — generation 2

- Output file: `raw/rejected-pickup-lockout-tag-2.png`
- Source: `[Codex generated-images store]/01a12820-5692-7861-a5d4-3157b1dca16f/exec-9ecd03cf-c778-4a5b-ae33-1346562cdf57.png`
- References:
  - Image 1: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 2: `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only; do not copy composition or figures.
  - Image 3: `[session scratch, not kept]/hq/props/refs/palette-card.png` — Colour swatches only.
- Verdict: Rejected: exterior low-alpha pixels extend to most of the canvas (alpha>=1 bounds 31,15–867,1774), and dark outlines persist. Copied byte-for-byte to raw/rejected-pickup-lockout-tag-2.png.

Verbatim prompt sent:

```text
Use case: stylized-concept
Asset type: transparent 2D side-view sci-fi horror game pickup sprite, shown only 20–32 world pixels tall/long
Input images: Image 1 is the Look 2 board for rendering, value structure, edge treatment, and cool grading only; Image 2 is key art for mood, light, and palette only; Image 3 is the palette card for swatches only. Do not copy their objects, figures, or composition.
Scene/backdrop: genuinely transparent RGBA, object only; no wall, environment, floor, or ground.
Subject: one compact lockout-tag pickup assembly in front elevation on a portrait canvas about 1:2. A small steel mounting plate holds a short bent steel wall hook. A closed steel padlock hangs from the hook, with its locked shackle forming an empty loop around nothing. A short steel ring hangs a rectangular signal-red lockout tag (#a01e29 lit, #5f0e17 shadow) from the padlock. The tag is completely blank, with one round open grommet hole. Keep it chunky and readable; no feature smaller than 1/20 of the whole pickup.
Style/medium: match the Look 2 stations: shape-first graphic painting, large flat value planes, crisp shape-designed silhouette, minimal texture, 3–4 value steps per material. Painterly soft transitions only inside material shading; no grain, speckle, rust, scratches, tiny bolts/rivets, or fine panel lines.
Composition/framing: centered, fills most of the portrait canvas with about 6% clear margin on every side; keep the whole assembly inside frame.
Lighting/mood: cold overhead top light with upward planes lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) rendered as a narrow painted highlight on the object's top/back edges, not emitted light.
Color palette: cool blue-grey to blue-black steel (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), with signal red only on the tag. No warm greys, brown, magenta, or pink.
Materials/textures: opaque painted steel and tag; clean 1–2 px anti-aliased outside silhouette; no matte fringe or halo. Pixels beyond the anti-aliased silhouette are fully transparent alpha 0.
Text: none.
Constraints: no dark outline or ink contour; no floor, ground plane, cast/contact shadow, reflection, glow/haze outside silhouette, steam, sparks, second object, text, letters, numbers, labels, symbols, logos, UI, watermark, guide lines, or border. Preserve genuine transparency outside the single assembled pickup.
Targeted retry correction: fix the silhouette edge treatment only. Keep all light painted inside the object with no exterior fringe or haze; use value planes and narrow highlights instead of dark contour lines. Everything beyond the 1–2 px anti-aliased object edge must be fully transparent alpha 0.
```

## pickup-lockout-tag.png — generation 3

- Output file: `raw/rejected-pickup-lockout-tag-3.png`
- Source: `[Codex generated-images store]/01a12820-5692-7861-a5d4-3157b1dca16f/exec-7a88fe8c-1937-4c23-b608-3cc976dd4dcd.png`
- References:
  - Image 1: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 2: `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only; do not copy composition or figures.
  - Image 3: `[session scratch, not kept]/hq/props/refs/palette-card.png` — Colour swatches only.
- Verdict: Rejected: alpha>=1 haze extends well beyond the silhouette (bounds 41,17–819,1774); the final permitted retry did not remove the exterior fringe. Copied byte-for-byte to raw/rejected-pickup-lockout-tag-3.png.

Verbatim prompt sent:

```text
Use case: stylized-concept
Asset type: transparent 2D side-view sci-fi horror game pickup sprite, shown only 20–32 world pixels tall/long
Input images: Image 1 is the Look 2 board for rendering, value structure, edge treatment, and cool grading only; Image 2 is key art for mood, light, and palette only; Image 3 is the palette card for swatches only. Do not copy their objects, figures, or composition.
Scene/backdrop: genuinely transparent RGBA, object only; no wall, environment, floor, or ground.
Subject: one compact lockout-tag pickup assembly in front elevation on a portrait canvas about 1:2. A small steel mounting plate holds a short bent steel wall hook. A closed steel padlock hangs from the hook, with its locked shackle forming an empty loop around nothing. A short steel ring hangs a rectangular signal-red lockout tag (#a01e29 lit, #5f0e17 shadow) from the padlock. The tag is completely blank, with one round open grommet hole. Keep it chunky and readable; no feature smaller than 1/20 of the whole pickup.
Style/medium: match the Look 2 stations: shape-first graphic painting, large flat value planes, crisp shape-designed silhouette, minimal texture, 3–4 value steps per material. Painterly soft transitions only inside material shading; no grain, speckle, rust, scratches, tiny bolts/rivets, or fine panel lines.
Composition/framing: centered, fills most of the portrait canvas with about 6% clear margin on every side; keep the whole assembly inside frame.
Lighting/mood: cold overhead top light with upward planes lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) rendered as a narrow painted highlight on the object's top/back edges, not emitted light.
Color palette: cool blue-grey to blue-black steel (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), with signal red only on the tag. No warm greys, brown, magenta, or pink.
Materials/textures: opaque painted steel and tag; clean 1–2 px anti-aliased outside silhouette; no matte fringe or halo. Pixels beyond the anti-aliased silhouette are fully transparent alpha 0.
Text: none.
Constraints: no dark outline or ink contour; no floor, ground plane, cast/contact shadow, reflection, glow/haze outside silhouette, steam, sparks, second object, text, letters, numbers, labels, symbols, logos, UI, watermark, guide lines, or border. Preserve genuine transparency outside the single assembled pickup.
Targeted retry correction: fix the silhouette edge treatment only. Keep all light painted inside the object with no exterior fringe or haze; use value planes and narrow highlights instead of dark contour lines. Everything beyond the 1–2 px anti-aliased object edge must be fully transparent alpha 0.
Final retry correction: render the assembly as flat value planes with an opaque, clean silhouette. Remove every dark ink contour and every exterior glow/fringe; all pixels outside the 1–2 px anti-aliased boundary must be fully transparent alpha 0. Keep the hook, empty-loop padlock, blank red tag, and their order unchanged.
```

## pickup-cracked-gauge.png — generation 1

- Output file: `raw/rejected-pickup-cracked-gauge-1.png`
- Source: `[Codex generated-images store]/01a12820-5692-7861-a5d4-3157b1dca16f/exec-ae6a1989-5f2b-410d-bede-9d97aacade2e.png`
- References:
  - Image 1: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 2: `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only; do not copy composition or figures.
  - Image 3: `[session scratch, not kept]/hq/props/refs/palette-card.png` — Colour swatches only.
  - Image 4: `apps/game/assets/props/junction-valve.png` — Gauge shape and its relationship to a valve assembly only; ignore rust and all other contents.
- Verdict: Rejected: alpha>=1 halo extends across almost the full canvas (bounds 0,23–1217,1254) beyond the silhouette. Copied byte-for-byte to raw/rejected-pickup-cracked-gauge-1.png.

Verbatim prompt sent:

```text
Use case: stylized-concept
Asset type: transparent 2D side-view sci-fi horror game pickup sprite, shown only 20–32 world pixels tall/long
Input images: Image 1 is the Look 2 board for rendering, value structure, edge treatment, and cool grading only; Image 2 is key art for mood, light, and palette only; Image 3 is the palette card for swatches only; Image 4 is the junction-valve reference for the gauge shape and its relationship to a valve assembly only. Ignore its rusty rendering and all other contents. Do not copy any reference composition or figures.
Scene/backdrop: genuinely transparent RGBA, object only; no deck, floor, environment, or ground.
Subject: one round pressure gauge pickup fallen on its lower rim and tipped slightly to one side, with its face aimed directly at the viewer and a short threaded steel stem fitting protruding from the bottom. Square canvas. The gauge has a cool off-white face (#c3c5d7), a simple steel bezel, one broad signal-red zone arc (#a01e29) in the upper-right of the dial, and one bold dark blue-black needle pinned just past that red zone. The glass is starred by a few broad, readable crack shapes radiating from one impact point; no fine hairlines. No scale ticks or markings.
Style/medium: match the Look 2 stations: shape-first graphic painting, large flat value planes, crisp designed silhouette, minimal texture, 3–4 value steps per material. Painterly soft transitions only within material shading; no grain, speckle, rust, scratches, tiny bolts/rivets, or fine panel lines.
Composition/framing: centered and filling most of a square canvas, with about 6% clear margin on every side; keep all of the gauge and stem inside frame.
Lighting/mood: cold overhead top light with upward planes lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) as a painted highlight confined to the top/back edge of the solid bezel, not emitted light.
Color palette: cool blue-grey to blue-black steel (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0); cool off-white gauge face; the named signal-red zone only. No warm greys, brown, magenta, or pink.
Materials/textures: opaque painted materials; clean 1–2 px anti-aliased silhouette; no matte fringe or halo. Pixels beyond the anti-aliased silhouette are fully transparent alpha 0.
Text: none.
Constraints: no dark outline or ink contour; no floor, deck, cast/contact shadow, reflection, glow/haze outside silhouette, steam, sparks, second object, text, letters, numbers, labels, logos, UI, watermark, guide lines, or border. Preserve genuine transparency outside the single gauge assembly.
```

## pickup-cracked-gauge.png — generation 2

- Output file: `raw/rejected-pickup-cracked-gauge-2.png`
- Source: `[Codex generated-images store]/01a12820-5692-7861-a5d4-3157b1dca16f/exec-7397a55b-1fc6-43da-af59-62cfbe07e8e9.png`
- References:
  - Image 1: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 2: `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only; do not copy composition or figures.
  - Image 3: `[session scratch, not kept]/hq/props/refs/palette-card.png` — Colour swatches only.
  - Image 4: `apps/game/assets/props/junction-valve.png` — Gauge shape and its relationship to a valve assembly only; ignore rust and all other contents.
- Verdict: Rejected: faint exterior alpha haze remains (alpha>=1 bounds 0,39–1222,1254), despite transparent corners. Copied byte-for-byte to raw/rejected-pickup-cracked-gauge-2.png.

Verbatim prompt sent:

```text
Use case: stylized-concept
Asset type: transparent 2D side-view sci-fi horror game pickup sprite, shown only 20–32 world pixels tall/long
Input images: Image 1 is the Look 2 board for rendering, value structure, edge treatment, and cool grading only; Image 2 is key art for mood, light, and palette only; Image 3 is the palette card for swatches only; Image 4 is the junction-valve reference for the gauge shape and its relationship to a valve assembly only. Ignore its rusty rendering and all other contents. Do not copy any reference composition or figures.
Scene/backdrop: genuinely transparent RGBA, object only; no deck, floor, environment, or ground.
Subject: one round pressure gauge pickup fallen on its lower rim and tipped slightly to one side, with its face aimed directly at the viewer and a short threaded steel stem fitting protruding from the bottom. Square canvas. The gauge has a cool off-white face (#c3c5d7), a simple steel bezel, one broad signal-red zone arc (#a01e29) in the upper-right of the dial, and one bold dark blue-black needle pinned just past that red zone. The glass is starred by a few broad, readable crack shapes radiating from one impact point; no fine hairlines. No scale ticks or markings.
Style/medium: match the Look 2 stations: shape-first graphic painting, large flat value planes, crisp designed silhouette, minimal texture, 3–4 value steps per material. Painterly soft transitions only within material shading; no grain, speckle, rust, scratches, tiny bolts/rivets, or fine panel lines.
Composition/framing: centered and filling most of a square canvas, with about 6% clear margin on every side; keep all of the gauge and stem inside frame.
Lighting/mood: cold overhead top light with upward planes lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) as a painted highlight confined to the top/back edge of the solid bezel, not emitted light.
Color palette: cool blue-grey to blue-black steel (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0); cool off-white gauge face; the named signal-red zone only. No warm greys, brown, magenta, or pink.
Materials/textures: opaque painted materials; clean 1–2 px anti-aliased silhouette; no matte fringe or halo. Pixels beyond the anti-aliased silhouette are fully transparent alpha 0.
Text: none.
Constraints: no dark outline or ink contour; no floor, deck, cast/contact shadow, reflection, glow/haze outside silhouette, steam, sparks, second object, text, letters, numbers, labels, logos, UI, watermark, guide lines, or border. Preserve genuine transparency outside the single gauge assembly.
Targeted retry correction: remove only the edge glow and outline treatment. Keep the gauge, dial, red arc, needle, cracks, tilt, and stem as shown in the design, but make the bezel's rim a solid painted highlight, with no emitted light or haze outside it; no dark ink contours. All background pixels beyond the 1–2 px anti-aliased silhouette are fully transparent alpha 0.
```

## pickup-cracked-gauge.png — generation 3

- Output file: `raw/rejected-pickup-cracked-gauge-3.png`
- Source: `[Codex generated-images store]/01a12820-5692-7861-a5d4-3157b1dca16f/exec-b62ffa57-9711-4f55-84b4-f6c2e8373118.png`
- References:
  - Image 1: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 2: `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only; do not copy composition or figures.
  - Image 3: `[session scratch, not kept]/hq/props/refs/palette-card.png` — Colour swatches only.
  - Image 4: `apps/game/assets/props/junction-valve.png` — Gauge shape and its relationship to a valve assembly only; ignore rust and all other contents.
- Verdict: Rejected: low-alpha halo remains outside the silhouette after the final permitted retry (alpha>=1 bounds 0,19–1214,1254). Copied byte-for-byte to raw/rejected-pickup-cracked-gauge-3.png.

Verbatim prompt sent:

```text
Use case: stylized-concept
Asset type: transparent 2D side-view sci-fi horror game pickup sprite, shown only 20–32 world pixels tall/long
Input images: Image 1 is the Look 2 board for rendering, value structure, edge treatment, and cool grading only; Image 2 is key art for mood, light, and palette only; Image 3 is the palette card for swatches only; Image 4 is the junction-valve reference for the gauge shape and its relationship to a valve assembly only. Ignore its rusty rendering and all other contents. Do not copy any reference composition or figures.
Scene/backdrop: genuinely transparent RGBA, object only; no deck, floor, environment, or ground.
Subject: one round pressure gauge pickup fallen on its lower rim and tipped slightly to one side, with its face aimed directly at the viewer and a short threaded steel stem fitting protruding from the bottom. Square canvas. The gauge has a cool off-white face (#c3c5d7), a simple steel bezel, one broad signal-red zone arc (#a01e29) in the upper-right of the dial, and one bold dark blue-black needle pinned just past that red zone. The glass is starred by a few broad, readable crack shapes radiating from one impact point; no fine hairlines. No scale ticks or markings.
Style/medium: match the Look 2 stations: shape-first graphic painting, large flat value planes, crisp designed silhouette, minimal texture, 3–4 value steps per material. Painterly soft transitions only within material shading; no grain, speckle, rust, scratches, tiny bolts/rivets, or fine panel lines.
Composition/framing: centered and filling most of a square canvas, with about 6% clear margin on every side; keep all of the gauge and stem inside frame.
Lighting/mood: cold overhead top light with upward planes lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) as a painted highlight confined to the top/back edge of the solid bezel, not emitted light.
Color palette: cool blue-grey to blue-black steel (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0); cool off-white gauge face; the named signal-red zone only. No warm greys, brown, magenta, or pink.
Materials/textures: opaque painted materials; clean 1–2 px anti-aliased silhouette; no matte fringe or halo. Pixels beyond the anti-aliased silhouette are fully transparent alpha 0.
Text: none.
Constraints: no dark outline or ink contour; no floor, deck, cast/contact shadow, reflection, glow/haze outside silhouette, steam, sparks, second object, text, letters, numbers, labels, logos, UI, watermark, guide lines, or border. Preserve genuine transparency outside the single gauge assembly.
Targeted retry correction: remove only the edge glow and outline treatment. Keep the gauge, dial, red arc, needle, cracks, tilt, and stem as shown in the design, but make the bezel's rim a solid painted highlight, with no emitted light or haze outside it; no dark ink contours. All background pixels beyond the 1–2 px anti-aliased silhouette are fully transparent alpha 0.
Final retry correction: eliminate all halo, bloom, haze, and fringe outside the gauge. No low-alpha glow anywhere in the transparent background: pixels outside the 1–2 px anti-aliased object silhouette must have alpha exactly 0. Keep the outline-free value-plane rendering and preserve the gauge's current face layout.
```

## pickup-cracked-gauge.png — generation 4

- Output file: `raw/rejected-pickup-cracked-gauge-4.png`
- Source: `[Codex generated-images store]/01a12820-5692-7861-a5d4-3157b1dca16f/exec-1b8e7225-1a68-42df-bf93-4a1955e7e539.png`
- References:
  - Image 1: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 2: `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only; do not copy composition or figures.
  - Image 3: `[session scratch, not kept]/hq/props/refs/palette-card.png` — Colour swatches only.
  - Image 4: `apps/game/assets/props/junction-valve.png` — Gauge shape and its relationship to a valve assembly only; ignore rust and all other contents.
- Verdict: Rejected: accidental extra generation after the two-retry limit; low-alpha exterior fringe persists. Copied byte-for-byte to raw/rejected-pickup-cracked-gauge-4.png.

Verbatim prompt sent:

```text
Use case: stylized-concept
Asset type: transparent 2D side-view sci-fi horror game pickup sprite, shown only 20–32 world pixels tall/long
Input images: Image 1 is the Look 2 board for rendering, value structure, edge treatment, and cool grading only; Image 2 is key art for mood, light, and palette only; Image 3 is the palette card for swatches only; Image 4 is the junction-valve reference for the gauge shape and its relationship to a valve assembly only. Ignore its rusty rendering and all other contents. Do not copy any reference composition or figures.
Scene/backdrop: genuinely transparent RGBA, object only; no deck, floor, environment, or ground.
Subject: one round pressure gauge pickup fallen on its lower rim and tipped slightly to one side, with its face aimed directly at the viewer and a short threaded steel stem fitting protruding from the bottom. Square canvas. The gauge has a cool off-white face (#c3c5d7), a simple steel bezel, one broad signal-red zone arc (#a01e29) in the upper-right of the dial, and one bold dark blue-black needle pinned just past that red zone. The glass is starred by a few broad, readable crack shapes radiating from one impact point; no fine hairlines. No scale ticks or markings.
Style/medium: match the Look 2 stations: shape-first graphic painting, large flat value planes, crisp designed silhouette, minimal texture, 3–4 value steps per material. Painterly soft transitions only within material shading; no grain, speckle, rust, scratches, tiny bolts/rivets, or fine panel lines.
Composition/framing: centered and filling most of a square canvas, with about 6% clear margin on every side; keep all of the gauge and stem inside frame.
Lighting/mood: cold overhead top light with upward planes lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) as a painted highlight confined to the top/back edge of the solid bezel, not emitted light.
Color palette: cool blue-grey to blue-black steel (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0); cool off-white gauge face; the named signal-red zone only. No warm greys, brown, magenta, or pink.
Materials/textures: opaque painted materials; clean 1–2 px anti-aliased silhouette; no matte fringe or halo. Pixels beyond the anti-aliased silhouette are fully transparent alpha 0.
Text: none.
Constraints: no dark outline or ink contour; no floor, deck, cast/contact shadow, reflection, glow/haze outside silhouette, steam, sparks, second object, text, letters, numbers, labels, logos, UI, watermark, guide lines, or border. Preserve genuine transparency outside the single gauge assembly.
Targeted retry correction: remove only the edge glow and outline treatment. Keep the gauge, dial, red arc, needle, cracks, tilt, and stem as shown in the design, but make the bezel's rim a solid painted highlight, with no emitted light or haze outside it; no dark ink contours. All background pixels beyond the 1–2 px anti-aliased silhouette are fully transparent alpha 0.
Final retry correction: eliminate all halo, bloom, haze, and fringe outside the gauge. No low-alpha glow anywhere in the transparent background: pixels outside the 1–2 px anti-aliased object silhouette must have alpha exactly 0. Keep the outline-free value-plane rendering and preserve the gauge's current face layout.
Final retry correction: this must be an isolated painted object on genuinely empty transparency. Keep the 1–2 px anti-aliased silhouette, but set every pixel outside it to alpha exactly 0; do not add bloom, fringe, or any light haze. Render the cyan-white rim as opaque paint within the bezel edge, never as a glow. Keep the red arc, single needle, broad starred cracks, and short stem.
```

## pickup-wheel-ratchet.png — generation 1

- Output file: `raw/rejected-pickup-wheel-ratchet-1.png`
- Source: `[Codex generated-images store]/01a12820-5692-7861-a5d4-3157b1dca16f/exec-b3a63072-e4f6-43dc-b68c-9bc377222d49.png`
- References:
  - Image 1: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 2: `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only; do not copy composition or figures.
  - Image 3: `[session scratch, not kept]/hq/props/refs/palette-card.png` — Colour swatches only.
  - Image 4: `apps/game/assets/props/junction-valve.png` — Square valve-wheel hub/socket relationship only; ignore rust and all other contents.
- Verdict: Rejected: canvas is 3:1 rather than requested 4:1, and alpha>=1 haze extends outside the wrench (bounds 43,31–2152,667). Copied byte-for-byte to raw/rejected-pickup-wheel-ratchet-1.png.

Verbatim prompt sent:

```text
Use case: stylized-concept
Asset type: transparent 2D side-view sci-fi horror game pickup sprite, shown only 20–32 world pixels tall/long
Input images: Image 1 is the Look 2 board for rendering, value structure, edge treatment, and cool grading only; Image 2 is key art for mood, light, and palette only; Image 3 is the palette card for swatches only; Image 4 is the junction-valve reference for the square valve-wheel hub/socket relationship only. Ignore its rusty rendering and all other contents. Do not copy any reference composition or figures.
Scene/backdrop: genuinely transparent RGBA, one object only; no deck, floor, environment, or ground.
Subject: one long-handled ratchet wrench lying flat in straight side elevation, handle perfectly horizontal on a wide 4:1 landscape canvas. At the left is a chunky heavy ratchet head with one large square socket opening sized to fit a valve-wheel hub and one clearly visible simple pawl lever. A long straight handle extends to the right. Paint most of the handle dim amber metal (#82510e with #6e4824 shadow); over the grip at the far-right end, show one broad patch of paint worn away to bare cool steel (#9fb0c0 lit). Use only a few large shapes; no feature smaller than 1/20 of the whole wrench.
Style/medium: match the Look 2 stations: shape-first graphic painting, large flat value planes, crisp designed silhouette, minimal texture, 3–4 value steps per material. Painterly soft transitions only within material shading; no grain, speckle, rust, scratches, tiny bolts/rivets, or fine panel lines.
Composition/framing: centered, fills most of the 4:1 landscape canvas, with about 6% clear margin on every side; keep the full wrench inside frame.
Lighting/mood: cold overhead top light with upward planes lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) as a painted highlight confined to the top/back edge, never emitted light.
Color palette: cool blue-grey to blue-black steel (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0); only the named dim amber handle and bare cool-steel wear patch as accents. No warm greys, brown beyond the named handle swatches, magenta, or pink.
Materials/textures: opaque painted wrench; clean 1–2 px anti-aliased silhouette; no matte fringe or halo. Pixels beyond the anti-aliased silhouette are fully transparent alpha 0.
Text: none.
Constraints: no dark outline or ink contour; no floor/deck, ground plane, cast/contact shadow, reflection, glow/haze outside silhouette, steam, sparks, second object, text, letters, numbers, labels, logos, UI, watermark, guide lines, or border. Preserve genuine transparency outside the single wrench.
```

## pickup-wheel-ratchet.png — generation 2

- Output file: `raw/rejected-pickup-wheel-ratchet-2.png`
- Source: `[Codex generated-images store]/01a12820-5692-7861-a5d4-3157b1dca16f/exec-d587fcb1-29ec-40de-9785-f3a244391f03.png`
- References:
  - Image 1: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 2: `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only; do not copy composition or figures.
  - Image 3: `[session scratch, not kept]/hq/props/refs/palette-card.png` — Colour swatches only.
  - Image 4: `apps/game/assets/props/junction-valve.png` — Square valve-wheel hub/socket relationship only; ignore rust and all other contents.
- Verdict: Rejected: strong red/yellow exterior fringe around the handle plus 3:1 canvas instead of requested 4:1. Copied byte-for-byte to raw/rejected-pickup-wheel-ratchet-2.png.

Verbatim prompt sent:

```text
Use case: stylized-concept
Asset type: transparent 2D side-view sci-fi horror game pickup sprite, shown only 20–32 world pixels tall/long
Input images: Image 1 is the Look 2 board for rendering, value structure, edge treatment, and cool grading only; Image 2 is key art for mood, light, and palette only; Image 3 is the palette card for swatches only; Image 4 is the junction-valve reference for the square valve-wheel hub/socket relationship only. Ignore its rusty rendering and all other contents. Do not copy any reference composition or figures.
Scene/backdrop: genuinely transparent RGBA, one object only; no deck, floor, environment, or ground.
Subject: one long-handled ratchet wrench lying flat in straight side elevation, handle perfectly horizontal on a wide 4:1 landscape canvas. At the left is a chunky heavy ratchet head with one large square socket opening sized to fit a valve-wheel hub and one clearly visible simple pawl lever. A long straight handle extends to the right. Paint most of the handle dim amber metal (#82510e with #6e4824 shadow); over the grip at the far-right end, show one broad patch of paint worn away to bare cool steel (#9fb0c0 lit). Use only a few large shapes; no feature smaller than 1/20 of the whole wrench.
Style/medium: match the Look 2 stations: shape-first graphic painting, large flat value planes, crisp designed silhouette, minimal texture, 3–4 value steps per material. Painterly soft transitions only within material shading; no grain, speckle, rust, scratches, tiny bolts/rivets, or fine panel lines.
Composition/framing: centered, fills most of the 4:1 landscape canvas, with about 6% clear margin on every side; keep the full wrench inside frame.
Lighting/mood: cold overhead top light with upward planes lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) as a painted highlight confined to the top/back edge, never emitted light.
Color palette: cool blue-grey to blue-black steel (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0); only the named dim amber handle and bare cool-steel wear patch as accents. No warm greys, brown beyond the named handle swatches, magenta, or pink.
Materials/textures: opaque painted wrench; clean 1–2 px anti-aliased silhouette; no matte fringe or halo. Pixels beyond the anti-aliased silhouette are fully transparent alpha 0.
Text: none.
Constraints: no dark outline or ink contour; no floor/deck, ground plane, cast/contact shadow, reflection, glow/haze outside silhouette, steam, sparks, second object, text, letters, numbers, labels, logos, UI, watermark, guide lines, or border. Preserve genuine transparency outside the single wrench.
Targeted retry correction: remove only the exterior light effect. The cyan-white rim is a flat painted highlight on the steel edge; do not emit light from it. Keep every pixel outside the wrench's 1–2 px anti-aliased silhouette at alpha exactly 0, with no haze, glow, or shadow.
```

## pickup-wheel-ratchet.png — generation 3

- Output file: `raw/rejected-pickup-wheel-ratchet-3.png`
- Source: `[Codex generated-images store]/01a12820-5692-7861-a5d4-3157b1dca16f/exec-f1ea4ce1-ba88-436d-9c8b-f2d1d7e998e9.png`
- References:
  - Image 1: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 2: `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only; do not copy composition or figures.
  - Image 3: `[session scratch, not kept]/hq/props/refs/palette-card.png` — Colour swatches only.
  - Image 4: `apps/game/assets/props/junction-valve.png` — Square valve-wheel hub/socket relationship only; ignore rust and all other contents.
- Verdict: Rejected: tool returned 3:1 canvas despite exact 4:1 correction, and alpha>=1 haze remains beyond the silhouette (bounds 21,20–2156,636). Copied byte-for-byte to raw/rejected-pickup-wheel-ratchet-3.png.

Verbatim prompt sent:

```text
Use case: stylized-concept
Asset type: transparent 2D side-view sci-fi horror game pickup sprite, shown only 20–32 world pixels tall/long
Input images: Image 1 is the Look 2 board for rendering, value structure, edge treatment, and cool grading only; Image 2 is key art for mood, light, and palette only; Image 3 is the palette card for swatches only; Image 4 is the junction-valve reference for the square valve-wheel hub/socket relationship only. Ignore its rusty rendering and all other contents. Do not copy any reference composition or figures.
Scene/backdrop: genuinely transparent RGBA, one object only; no deck, floor, environment, or ground.
Subject: one long-handled ratchet wrench lying flat in straight side elevation, handle perfectly horizontal on a wide 4:1 landscape canvas. At the left is a chunky heavy ratchet head with one large square socket opening sized to fit a valve-wheel hub and one clearly visible simple pawl lever. A long straight handle extends to the right. Paint most of the handle dim amber metal (#82510e with #6e4824 shadow); over the grip at the far-right end, show one broad patch of paint worn away to bare cool steel (#9fb0c0 lit). Use only a few large shapes; no feature smaller than 1/20 of the whole wrench.
Style/medium: match the Look 2 stations: shape-first graphic painting, large flat value planes, crisp designed silhouette, minimal texture, 3–4 value steps per material. Painterly soft transitions only within material shading; no grain, speckle, rust, scratches, tiny bolts/rivets, or fine panel lines.
Composition/framing: centered, fills most of the 4:1 landscape canvas, with about 6% clear margin on every side; keep the full wrench inside frame.
Lighting/mood: cold overhead top light with upward planes lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) as a painted highlight confined to the top/back edge, never emitted light.
Color palette: cool blue-grey to blue-black steel (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0); only the named dim amber handle and bare cool-steel wear patch as accents. No warm greys, brown beyond the named handle swatches, magenta, or pink.
Materials/textures: opaque painted wrench; clean 1–2 px anti-aliased silhouette; no matte fringe or halo. Pixels beyond the anti-aliased silhouette are fully transparent alpha 0.
Text: none.
Constraints: no dark outline or ink contour; no floor/deck, ground plane, cast/contact shadow, reflection, glow/haze outside silhouette, steam, sparks, second object, text, letters, numbers, labels, logos, UI, watermark, guide lines, or border. Preserve genuine transparency outside the single wrench.
Targeted retry correction: remove only the exterior light effect. The cyan-white rim is a flat painted highlight on the steel edge; do not emit light from it. Keep every pixel outside the wrench's 1–2 px anti-aliased silhouette at alpha exactly 0, with no haze, glow, or shadow.
Final retry correction: fix the overall framing to an exact 4:1 landscape PNG canvas (width exactly four times its height). Center the full horizontal wrench with about 6% transparent margin on every side. Keep all outside pixels fully transparent alpha 0; no glow, haze, fringe, or shadow beyond the silhouette.
```

