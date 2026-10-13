# WOLF//OVERRIDE screen housing generation log

All calls used the built-in image_gen edit flow with transparent output requested. Raw PNGs were copied byte-for-byte; no resizing, matting, or re-encoding was performed.

### raw/pickup-screen-work-order.png (kept)

- Source: `[Codex generated-images store]/01a12829-b4b0-74c1-8b17-73827537e93a/exec-1354b899-6da5-425d-91e9-b4ea706c8ee1.png`
- Mode: built-in image_gen edit with `transparent_background=true`
- Verdict: Kept. Dark screen, thick bezel, edge brackets, and four cyan keys are present; RGBA alpha includes transparent pixels; no text, floor, or second object.
- References:
- Image 1: `apps/game/assets/props/corridor-purge-display.png` — screen-housing design language only; do not copy the console
- Image 2: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, cool grading only
- Image 3: `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, palette only
- Image 4: `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only

Verbatim prompt:

```text
Use case: stylized-concept
Asset type: isolated transparent 2D side-view game prop sprite for WOLF//OVERRIDE; compact log-pickup screen housing, approximately 32 x 24 world pixels in game.
Input images: Image 1, apps/game/assets/props/corridor-purge-display.png, screen-housing design language only; do not copy the console. Image 2, [session scratch, not kept]/hq/props/refs/ref-look2-board.png, rendering, value structure, edge treatment and cool grading only; match the breaker and coolant relay, do not copy its objects or figures. Image 3, apps/game/assets/title-corridor-key-art-provisional.png, mood, light and palette only; do not copy its composition or figures. Image 4, [session scratch, not kept]/hq/props/refs/palette-card.png, colour swatches only.
Scene/backdrop: none; genuinely transparent RGBA background with preserved alpha.
Subject: a compact maintenance wall terminal in straight front elevation, landscape 4:3. Cool dark-steel housing with a thick bezel, small wall-mount bracket visible at the back edges, one large rectangular screen face below the top bezel, and a short strip of exactly four cyan keypad keys under the screen. Keep it chunky and legible as a tiny game prop. Preserve the screen-housing design language of Image 1 without copying the console.
Screen: dark unlit glass, only #07101a to #121f2c, with one faint cool diagonal reflection band contained within the glass; no screen text, letters, numbers, labels, UI, or glow.
Style/medium: approved Look 2 graphic-painterly shape-first painting: crisp shape-designed silhouette, large flat value planes, 3-4 value steps per material, minimal texture. Painterly soft transitions only inside light pools or glows; this object has no glow. Matte, never glossy: no specular hot-spots, chrome or plastic sheen, no smooth gradients along any pipe or tube. Every pipe, tube or box reads as three flat value bands (shadow, mid, lit top) plus the rim. No dark outline or ink contour; define edges through value and rim light. Body fully opaque. Clean 1-2 px anti-aliased silhouette edge, no fringe or halo.
Composition/framing: isolated, centered, straight side elevation with front face toward viewer, no perspective tilt or vanishing point; landscape 4:3, object fills most of frame with about 6% margin on each side.
Lighting/mood: cold overhead top light so upward-facing planes are clearly lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) along top and back edges. Cool, dark corridor values.
Color palette: steel and shadows cool blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty. Keep the body mostly between #121f2c and #2f4d69 and steel chroma low. Saturated colour only on the four keypad keys, using cyan keypad #2091ca. The cyan keys are the only accent.
Materials/textures: matte dark steel and dark unlit glass; minimal broad shapes only. No grain, speckle, rust spots, scratches, tiny bolts or rivets, or fine panel lines; use one broad panel line where the old design had three.
Text (verbatim): none.
Constraints: one object only; thick bezel, edge brackets, large dark screen, exactly four cyan keys. Preserve genuine transparency outside the isolated object.
Avoid: text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection outside the screen, glow outside the silhouette, steam, sparks, a second object, magenta or pink, dark outlines, warm tones, glossy highlights.
```

### raw/rejected-pickup-screen-patrol-log-1.png (rejected)

- Source: `[Codex generated-images store]/01a12829-b4b0-74c1-8b17-73827537e93a/exec-3736371c-04d3-4043-8998-ce83597ebbad.png`
- Mode: built-in image_gen edit with `transparent_background=true`
- Verdict: Rejected from final due to a reference-order execution error: Image 3 and Image 4 were passed as palette card then key art, opposite the required order. Raw attempt retained; corrected call follows.
- References:
- Image 1: `apps/game/assets/props/corridor-purge-display.png` — screen-housing design language only; do not copy the console
- Image 2: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, cool grading only
- Image 3: `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only; passed in the third slot by mistake
- Image 4: `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, palette only; passed in the fourth slot by mistake
- Image 5: `[session scratch, not kept]/hq/props/raw/screens/raw/pickup-screen-work-order.png` — kept work-order terminal; family rendering and materials only

Verbatim prompt:

```text
Use case: stylized-concept
Asset type: isolated transparent 2D side-view game prop sprite for WOLF//OVERRIDE; compact log-pickup lane-panel screen housing, approximately 32 x 24 world pixels in game.
Input images: Image 1, apps/game/assets/props/corridor-purge-display.png, screen-housing design language only; do not copy the console. Image 2, [session scratch, not kept]/hq/props/refs/ref-look2-board.png, rendering, value structure, edge treatment and cool grading only; match the breaker and coolant relay, do not copy its objects or figures. Image 3, apps/game/assets/title-corridor-key-art-provisional.png, mood, light and palette only; do not copy its composition or figures. Image 4, [session scratch, not kept]/hq/props/refs/palette-card.png, colour swatches only. Image 5, [session scratch, not kept]/hq/props/raw/screens/raw/pickup-screen-work-order.png, kept work-order terminal; use only for shared family rendering and materials, while making this object's silhouette clearly distinct.
Scene/backdrop: none; genuinely transparent RGBA background with preserved alpha.
Subject: a rugged armoured LANE PANEL screen for a sentry lane, straight front elevation, landscape 4:3. Make its silhouette visibly different from the work-order terminal: heavier angular housing, a protective hood projecting over the top of the screen, and chamfered corners. One large dark unlit screen and one small round red indicator set into the lower right corner of the bezel. No keypad. Keep it chunky and legible as a tiny game prop.
Screen: dark unlit glass, only #07101a to #121f2c, with one faint cool diagonal reflection band contained within the glass; no screen text, letters, numbers, labels, UI, or glow.
Style/medium: approved Look 2 graphic-painterly shape-first painting: crisp shape-designed silhouette, large flat value planes, 3-4 value steps per material, minimal texture. Painterly soft transitions only inside light pools or glows; this object has no glow. Matte, never glossy: no specular hot-spots, chrome or plastic sheen, no smooth gradients along any pipe or tube. Every pipe, tube or box reads as three flat value bands (shadow, mid, lit top) plus the rim. No dark outline or ink contour; define edges through value and rim light. Body fully opaque. Clean 1-2 px anti-aliased silhouette edge, no fringe or halo.
Composition/framing: isolated, centered, straight side elevation with front face toward viewer, no perspective tilt or vanishing point; landscape 4:3, object fills most of frame with about 6% margin on each side.
Lighting/mood: cold overhead top light so upward-facing planes are clearly lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) along top and back edges. Cool, dark corridor values.
Color palette: steel and shadows cool blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty. Keep the body mostly between #121f2c and #2f4d69 and steel chroma low. Saturated colour only on one small round indicator at the lower right bezel, using signal red #ad252d. This red indicator is the only accent; no cyan keypad or cyan accent.
Materials/textures: matte dark steel and dark unlit glass; minimal broad shapes only. No grain, speckle, rust spots, scratches, tiny bolts or rivets, or fine panel lines; use one broad panel line where the old design had three.
Text (verbatim): none.
Constraints: one object only; heavier angular armored silhouette, top protective hood, chamfered corners, large dark screen, single small round red indicator at lower right of bezel, distinct from Image 5. Preserve genuine transparency outside the isolated object.
Avoid: text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection outside the screen, glow outside the silhouette, steam, sparks, a second object, magenta or pink, cyan keys, extra accents, dark outlines, warm tones, glossy highlights.
```

### raw/pickup-screen-patrol-log.png (kept)

- Source: `[Codex generated-images store]/01a12829-b4b0-74c1-8b17-73827537e93a/exec-bb2950f9-3916-41bc-9efb-54dfd2fe4a6b.png`
- Mode: built-in image_gen edit with `transparent_background=true`
- Verdict: Kept. Distinct armored hood and chamfered silhouette, dark screen, and one lower-right red indicator are present; RGBA alpha includes transparent pixels; no text, floor, or second object.
- References:
- Image 1: `apps/game/assets/props/corridor-purge-display.png` — screen-housing design language only; do not copy the console
- Image 2: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, cool grading only
- Image 3: `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, palette only
- Image 4: `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only
- Image 5: `[session scratch, not kept]/hq/props/raw/screens/raw/pickup-screen-work-order.png` — kept work-order terminal; family rendering and materials only

Verbatim prompt:

```text
Use case: stylized-concept
Asset type: isolated transparent 2D side-view game prop sprite for WOLF//OVERRIDE; compact log-pickup lane-panel screen housing, approximately 32 x 24 world pixels in game.
Input images: Image 1, apps/game/assets/props/corridor-purge-display.png, screen-housing design language only; do not copy the console. Image 2, [session scratch, not kept]/hq/props/refs/ref-look2-board.png, rendering, value structure, edge treatment and cool grading only; match the breaker and coolant relay, do not copy its objects or figures. Image 3, apps/game/assets/title-corridor-key-art-provisional.png, mood, light and palette only; do not copy its composition or figures. Image 4, [session scratch, not kept]/hq/props/refs/palette-card.png, colour swatches only. Image 5, [session scratch, not kept]/hq/props/raw/screens/raw/pickup-screen-work-order.png, kept work-order terminal; use only for shared family rendering and materials, while making this object's silhouette clearly distinct.
Scene/backdrop: none; genuinely transparent RGBA background with preserved alpha.
Subject: a rugged armoured LANE PANEL screen for a sentry lane, straight front elevation, landscape 4:3. Make its silhouette visibly different from the work-order terminal: heavier angular housing, a protective hood projecting over the top of the screen, and chamfered corners. One large dark unlit screen and one small round red indicator set into the lower right corner of the bezel. No keypad. Keep it chunky and legible as a tiny game prop.
Screen: dark unlit glass, only #07101a to #121f2c, with one faint cool diagonal reflection band contained within the glass; no screen text, letters, numbers, labels, UI, or glow.
Style/medium: approved Look 2 graphic-painterly shape-first painting: crisp shape-designed silhouette, large flat value planes, 3-4 value steps per material, minimal texture. Painterly soft transitions only inside light pools or glows; this object has no glow. Matte, never glossy: no specular hot-spots, chrome or plastic sheen, no smooth gradients along any pipe or tube. Every pipe, tube or box reads as three flat value bands (shadow, mid, lit top) plus the rim. No dark outline or ink contour; define edges through value and rim light. Body fully opaque. Clean 1-2 px anti-aliased silhouette edge, no fringe or halo.
Composition/framing: isolated, centered, straight side elevation with front face toward viewer, no perspective tilt or vanishing point; landscape 4:3, object fills most of frame with about 6% margin on each side.
Lighting/mood: cold overhead top light so upward-facing planes are clearly lighter than the body; broad cyan-white rim (#82c3e6 to #c3c5d7) along top and back edges. Cool, dark corridor values.
Color palette: steel and shadows cool blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty. Keep the body mostly between #121f2c and #2f4d69 and steel chroma low. Saturated colour only on one small round indicator at the lower right bezel, using signal red #ad252d. This red indicator is the only accent; no cyan keypad or cyan accent.
Materials/textures: matte dark steel and dark unlit glass; minimal broad shapes only. No grain, speckle, rust spots, scratches, tiny bolts or rivets, or fine panel lines; use one broad panel line where the old design had three.
Text (verbatim): none.
Constraints: one object only; heavier angular armored silhouette, top protective hood, chamfered corners, large dark screen, single small round red indicator at lower right of bezel, distinct from Image 5. Preserve genuine transparency outside the isolated object.
Avoid: text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection outside the screen, glow outside the silhouette, steam, sparks, a second object, magenta or pink, cyan keys, extra accents, dark outlines, warm tones, glossy highlights.
```

