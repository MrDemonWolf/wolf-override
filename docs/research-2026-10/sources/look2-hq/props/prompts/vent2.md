# Relief Vent Image Generation Log

All calls used the built-in image_gen tool with `transparent_background: true` and the five references in the order recorded below.

## Call 1 — `relief-vent.png`

- Source path: `[Codex generated-images store]/01a12826-7671-7cc3-9453-7968ec585320/exec-2e62585f-a7d7-4ec0-9f70-3968c6f5c188.png`
- References and roles (in call order):
  1. `[session scratch, not kept]/hq/props/refs/vent-attempt-2.png` — design reference/edit target.
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, and palette only.
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only.
  5. `[session scratch, not kept]/hq/props/refs/guide-relief-vent.png` — proportion guide only; ignore colours, engineer, and old vent.
- Verdict: Kept as the best attempt: RGBA with transparent edge pixels and the closest silhouette ratio (1.74:1 at alpha >128); it still has five rather than six louvres and remains wider than the 3:2 target. The preview shows low-alpha blue tint beyond the silhouette.

Verbatim prompt:

```text
Use case: precise-object-edit. Re-render the single 2D side-view sci-fi horror game prop from Image 1 for WOLF//OVERRIDE.

REFERENCE ROLES (use only these five references, in this exact order):
Image 1 is the edit target and controls the prop's design, silhouette, layout, function, and colour coding. Keep its overhanging top lip with a central lamp socket, louvred grate face, side pipe elbows, and hazard-striped corner feet.
Image 2 controls Look 2 rendering only: value structure, edge treatment, and cool grading. Match the breaker and coolant relay rendering, without copying their objects or figures.
Image 3 controls mood, light, and palette only. Do not copy its composition or figures.
Image 4 controls the colour swatches only.
Image 5 is only a proportion guide: match the grey blockout's overall proportion; ignore its colours, the engineer, and the old vent at the top.

Make exactly one design change: make the full prop silhouette from top lip to feet taller so its width-to-height ratio is exactly 3:2 (height = 0.67 × width), matching the blockout proportion in Image 5. Preserve the prop's width and design. Achieve the added height by changing the grate from five to exactly six broad horizontal louvre slats and making the hazard-striped feet slightly taller. Keep the louvres broad and their gaps dark. Preserve the top lip, central lamp socket, side pipe elbows, frame, and corner feet placement. Keep the central lamp socket unlit dark glass. Keep the feet hazard stripes alternating amber metal #82510e with dark steel.

Render in approved “Look 2, graphic-painterly” style: shape-first graphic painting; large flat value planes; 3–4 value steps per material; minimal texture; crisp shape-designed silhouette; painterly soft transitions only inside contained light pools or glows, with no grain or speckle. Use cold overhead top light so upward faces are clearly lighter than the body, plus a broad cyan-white rim (#82c3e6 to #c3c5d7) along the top and back silhouette edges. No dark outline or ink contour; define edges through value and rim light. The object body is fully opaque, with a clean 1–2 px anti-aliased silhouette.

Keep cool steel and shadows blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown, or rusty. Keep most of the body mid-dark like the Look 2 breaker (#121f2c to #2f4d69); only top faces and rim are lighter. Steel chroma stays low. Use a matte finish, no specular hot-spots, chrome, plastic sheen, or smooth gradients along pipes. Each pipe, tube, and box reads as three flat value bands (shadow, mid, lit top) plus the rim. Saturated colour is restricted to these accents and swatches: signal red #a01e29 / #ad252d, red glow #ca452f, amber glow #e0936e, amber metal #82510e, dim amber #6e4824, cyan strip #30d0fc, cyan keypad #2091ca, cyan seam #4f8ab8, safe green #56dc69 / #228237 / #17632f. Preserve the target's colour coding; do not introduce other saturated colours. The lamp stays dark and unlit.

Straight side elevation, front face toward the viewer, no perspective tilt or vanishing point. Center the single prop and fill most of the frame with about 6% margin on each side where compatible with the exact 3:2 prop silhouette. The exterior background must be genuinely transparent RGBA; keep the generated alpha. The silhouette edge must be clean, with no halo or matte fringe.

Do not include text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, haze, steam, sparks, a second object, magenta, or pink. No glow outside the silhouette.
```

## Call 2 — `rejected-relief-vent-1.png`

- Source path: `[Codex generated-images store]/01a12826-7671-7cc3-9453-7968ec585320/exec-24b3b3ab-d114-4325-8507-f8b9957a2421.png`
- References and roles (in call order):
  1. `[session scratch, not kept]/hq/props/refs/vent-attempt-2.png` — design reference/edit target.
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, and palette only.
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only.
  5. `[session scratch, not kept]/hq/props/refs/guide-relief-vent.png` — proportion guide only; ignore colours, engineer, and old vent.
- Verdict: Rejected as an alternate: transparent RGBA edges, but still five louvres and a wider 1.88:1 silhouette; it does not improve the kept attempt.

Verbatim prompt:

```text
Use case: precise-object-edit. Re-render the single WOLF//OVERRIDE sci-fi horror game prop, using Image 1 as the edit target. This is a single targeted correction to the prior render: remove the entire opaque blue backdrop, haze, floor-like dark area, and all external glow/shadow so only the prop remains on a genuinely transparent RGBA background with preserved alpha. Do not alter the prop's design, value structure, lighting on its surfaces, or colours.

Keep the full silhouette exactly 3:2 width:height (height = 0.67 × width), matching only the grey blockout proportion in Image 5. The taller silhouette must have exactly six broad horizontal louvres with dark gaps and slightly taller hazard-striped corner feet. Preserve Image 1's overhanging top lip and central dark, unlit glass lamp socket, broad louvred face, side pipe elbows, frame, and corner feet. Keep the amber and dark-steel hazard stripes. Reference roles in order: Image 1 design and target; Image 2 Look 2 graphic-painterly value and edge treatment only; Image 3 mood/light/palette only; Image 4 colour swatches only; Image 5 proportion guide only, ignoring its colours, engineer, and old vent.

Match approved Look 2: shape-first graphic painting, large flat value planes, 3–4 value steps per material, minimal texture, crisp silhouette, painterly transitions only inside contained glows. Cold overhead top light; broad cyan-white rim (#82c3e6 to #c3c5d7) on top and back edges, with no dark outlines. Fully opaque object body, clean 1–2 px anti-aliased edge. Cool dark steel from #07101a, #121f2c, #1d3042, #2f4d69, #4175a0; body mostly #121f2c to #2f4d69, low steel chroma. Matte, no specular hotspots, chrome, plastic sheen, or pipe gradients; use three flat value bands plus rim. Restrict saturated accents to the approved swatches only, preserving Image 1 colour coding. Keep the central lamp unlit and dark.

Straight side elevation, front face toward viewer, no perspective. Center the prop. No text, letters, numbers, labels, logos, worded warning signs, UI, watermark, guides, borders, floor, ground plane, cast/contact shadow, reflection, haze, steam, sparks, second object, magenta, or pink. No glow outside the silhouette.
```

## Call 3 — `rejected-relief-vent-2.png`

- Source path: `[Codex generated-images store]/01a12826-7671-7cc3-9453-7968ec585320/exec-19b2a7be-29b6-4bc3-8c7d-0bb2e4188a52.png`
- References and roles (in call order):
  1. `[session scratch, not kept]/hq/props/refs/vent-attempt-2.png` — design reference/edit target.
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, and palette only.
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only.
  5. `[session scratch, not kept]/hq/props/refs/guide-relief-vent.png` — proportion guide only; ignore colours, engineer, and old vent.
- Verdict: Rejected as an alternate: transparent RGBA edges, but still five louvres and a wider 1.89:1 silhouette; it does not improve the kept attempt.

Verbatim prompt:

```text
Use case: precise-object-edit. Re-render the single prop from Image 1 with one targeted correction: the canvas outside the prop must be genuinely transparent RGBA, not blue, black, grey, or any other filled or gradient colour. Remove the entire environmental backdrop, haze, bottom dark band, external rim glow, ground plane, shadow, and reflection. Preserve alpha transparency around the isolated prop. Keep the object itself fully opaque and retain its original surface lighting.

Maintain the requested taller relief-vent design and 3:2 width-to-height silhouette. Preserve the required six broad horizontal louvres, dark gaps, slightly taller corner feet, overhanging top lip, central lamp socket as dark unlit glass, side pipe elbows, and amber/dark-steel hazard stripes. Keep Image 1's design and layout. References, in order: Image 1 design/edit target; Image 2 Look 2 value structure and edge treatment only; Image 3 mood/light/palette only; Image 4 colour swatches only; Image 5 grey blockout proportions only (ignore its colours, engineer, and old vent).

Approved Look 2 graphic-painterly style: large flat value planes, 3–4 value steps per material, minimal texture, crisp shape-designed silhouette; painterly transitions only inside contained light pools. Cold overhead top light and broad cyan-white rim (#82c3e6 to #c3c5d7) on top/back edges. No dark outlines. Cool, dark, low-chroma blue-grey steel (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0); body mostly #121f2c to #2f4d69. Matte surfaces, no specular hotspots, chrome, plastic sheen, or pipe gradients; each pipe, tube, and box has three flat value bands plus the rim. Preserve Image 1 colour coding and use only the approved saturated accent swatches. Keep the lamp unlit and dark.

Straight side elevation, front face toward viewer, no perspective, prop centered. No text, letters, numbers, labels, logos, worded signs, UI, watermark, guide lines, borders, second object, steam, sparks, magenta, or pink. Do not paint any background pixels outside the prop.
```

