# Relief vent generation log

All three calls used built-in image generation with transparent RGBA requested and the five references below in this order. No magenta fallback was used; outputs contained alpha, but the off-object haze made them unsuitable as cutouts. No kept `relief-vent.png` was produced.

## Call 1

- Output file: `raw/rejected-relief-vent-1.png`
- Source: `[Codex generated-images store]/01a12820-56ac-7da3-a0c3-3f64819fcae4/exec-67b20733-8c19-4263-a845-c852cfd0e391.png`
- Verdict: Rejected: broad translucent halo/haze extends beyond the vent silhouette.
- References:
  1. `apps/game/assets/props/junction-relief-vent.png` — Design reference: old vent identity cues only (slatted grate, hazard-striped end caps, pressure fittings).
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Rendering reference: Look 2 value structure, edge treatment, cool grading only.
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only.
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — Color swatches only.
  5. `[session scratch, not kept]/hq/props/refs/guide-relief-vent.png` — Layout and proportions of the new housing plus engineer scale only; ignore its colors, flat art, engineer, and old vent at top.

### Verbatim prompt

```text
Create a single isolated game prop: a redesigned raised service-junction relief vent for a 2D side-view sci-fi horror game. Use the five references in order and respect their roles: reference 1 is the old flat vent and supplies only its identity cues (slatted grate, short hazard-striped end caps, small pressure fittings); redesign its flat floor-slot shape into a standing housing. Reference 2 supplies only the Look 2 graphic-painterly rendering, value structure, edge treatment, and cool grading; match the breaker and coolant relay rendering, and do not copy any objects or figures. Reference 3 supplies only mood, light, and palette; do not copy its composition or figures. Reference 4 supplies only the color swatches. Reference 5 supplies only the layout and proportions for the new gray housing and engineer scale; ignore the reference's colors, flat drawing, engineer, and old vent shown at the top.

The prop is a squat heavy steel box housing, exactly 3 units wide by 2 units tall, about two-thirds the engineer's height in the guide. Show a straight side-elevation game prop with its front face toward the viewer, no perspective tilt and no vanishing point. Keep the whole object centered, filling most of the frame with about 6% margin on each side. Give it a thick overhanging top lip. Make the front face almost entirely one large grate with 5–6 broad horizontal louvre slats and clearly dark gaps between them. Include two bolted feet/end caps at the bottom corners, each carrying a short hazard-striped band alternating amber metal #82510e with dark steel. Preserve the old vent's small pressure-fitting identity cue as simple chunky fittings integrated into the housing. Center exactly one horizontal lamp socket on the top lip, about 35% of the housing width; its glass is unlit dark cool glass with no glow because the game draws that light separately. Keep the construction simple, chunky, and readable at small size. No steam and no glow from the grate.

Render in Look 2 graphic-painterly style: shape-first graphic painting with large flat value planes, 3–4 value steps per material, minimal texture, and a crisp shape-designed silhouette. Use painterly soft transitions only inside light pools and glows; this prop has no glow. No grain, speckle, rust spots, scratches, tiny bolts or rivets, or fine panel lines; use at most one broad panel line. Light the upward-facing surfaces clearly lighter than the body with cold overhead top light, plus a broad cyan-white rim from #82c3e6 to #c3c5d7 along the top and back edges. Use no dark outline or ink contour; define edges with value and rim light. Keep the body fully opaque with a clean 1–2 px anti-aliased silhouette edge, no matte fringe and no halo. Cool-grade all steel and shadows in blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0); keep the body mostly mid-dark. Saturated color appears only on the named accent: hazard bands use amber metal #82510e alternating with dark steel. All other surfaces, fittings, louvres, and unlit lamp glass are cool dark steel; do not add other saturated accents.

Request a genuinely transparent RGBA background and preserve the generated alpha. Do not add text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, glow outside the silhouette, steam, sparks, another object, magenta, or pink.
```

## Call 2

- Output file: `raw/rejected-relief-vent-2.png`
- Source: `[Codex generated-images store]/01a12820-56ac-7da3-a0c3-3f64819fcae4/exec-2d784b04-b1c6-4e0d-960b-218b4f206f95.png`
- Verdict: Rejected: targeted transparency correction still left broad translucent backdrop glow outside the silhouette.
- References:
  1. `apps/game/assets/props/junction-relief-vent.png` — Design reference: old vent identity cues only (slatted grate, hazard-striped end caps, pressure fittings).
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Rendering reference: Look 2 value structure, edge treatment, cool grading only.
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only.
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — Color swatches only.
  5. `[session scratch, not kept]/hq/props/refs/guide-relief-vent.png` — Layout and proportions of the new housing plus engineer scale only; ignore its colors, flat art, engineer, and old vent at top.

### Verbatim prompt

```text
Create a single isolated game prop: a redesigned raised service-junction relief vent for a 2D side-view sci-fi horror game. Use the five references in order and respect their roles: reference 1 is the old flat vent and supplies only its identity cues (slatted grate, short hazard-striped end caps, small pressure fittings); redesign its flat floor-slot shape into a standing housing. Reference 2 supplies only the Look 2 graphic-painterly rendering, value structure, edge treatment, and cool grading; match the breaker and coolant relay rendering, and do not copy any objects or figures. Reference 3 supplies only mood, light, and palette; do not copy its composition or figures. Reference 4 supplies only the color swatches. Reference 5 supplies only the layout and proportions for the new gray housing and engineer scale; ignore the reference's colors, flat drawing, engineer, and old vent shown at the top.

The prop is a squat heavy steel box housing, exactly 3 units wide by 2 units tall, about two-thirds the engineer's height in the guide. Show a straight side-elevation game prop with its front face toward the viewer, no perspective tilt and no vanishing point. Keep the whole object centered, filling most of the frame with about 6% margin on each side. Give it a thick overhanging top lip. Make the front face almost entirely one large grate with 5–6 broad horizontal louvre slats and clearly dark gaps between them. Include two bolted feet/end caps at the bottom corners, each carrying a short hazard-striped band alternating amber metal #82510e with dark steel. Preserve the old vent's small pressure-fitting identity cue as simple chunky fittings integrated into the housing. Center exactly one horizontal lamp socket on the top lip, about 35% of the housing width; its glass is unlit dark cool glass with no glow because the game draws that light separately. Keep the construction simple, chunky, and readable at small size. No steam and no glow from the grate.

Render in Look 2 graphic-painterly style: shape-first graphic painting with large flat value planes, 3–4 value steps per material, minimal texture, and a crisp shape-designed silhouette. Use painterly soft transitions only inside light pools and glows; this prop has no glow. No grain, speckle, rust spots, scratches, tiny bolts or rivets, or fine panel lines; use at most one broad panel line. Light the upward-facing surfaces clearly lighter than the body with cold overhead top light, plus a broad cyan-white rim from #82c3e6 to #c3c5d7 along the top and back edges. Use no dark outline or ink contour; define edges with value and rim light. Keep the body fully opaque with a clean 1–2 px anti-aliased silhouette edge, no matte fringe and no halo. Cool-grade all steel and shadows in blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0); keep the body mostly mid-dark. Saturated color appears only on the named accent: hazard bands use amber metal #82510e alternating with dark steel. All other surfaces, fittings, louvres, and unlit lamp glass are cool dark steel; do not add other saturated accents.

Request a genuinely transparent RGBA background and preserve the generated alpha. Do not add text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, glow outside the silhouette, steam, sparks, another object, magenta, or pink.

Targeted correction for this retry: put no haze, bloom, halo, backdrop, shadow, or other visible pixels outside the vent. Every pixel outside the vent silhouette must have alpha 0; keep the cyan-white rim confined to the vent's own outer edge.
```

## Call 3

- Output file: `raw/rejected-relief-vent-3.png`
- Source: `[Codex generated-images store]/01a12820-56ac-7da3-a0c3-3f64819fcae4/exec-98089c30-731f-4721-8be7-d783838c9dea.png`
- Verdict: Rejected: final allowed retry still left broad translucent backdrop glow outside the silhouette.
- References:
  1. `apps/game/assets/props/junction-relief-vent.png` — Design reference: old vent identity cues only (slatted grate, hazard-striped end caps, pressure fittings).
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Rendering reference: Look 2 value structure, edge treatment, cool grading only.
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — Mood, light, and palette only.
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — Color swatches only.
  5. `[session scratch, not kept]/hq/props/refs/guide-relief-vent.png` — Layout and proportions of the new housing plus engineer scale only; ignore its colors, flat art, engineer, and old vent at top.

### Verbatim prompt

```text
Create a single isolated game prop: a redesigned raised service-junction relief vent for a 2D side-view sci-fi horror game. Use the five references in order and respect their roles: reference 1 is the old flat vent and supplies only its identity cues (slatted grate, short hazard-striped end caps, small pressure fittings); redesign its flat floor-slot shape into a standing housing. Reference 2 supplies only the Look 2 graphic-painterly rendering, value structure, edge treatment, and cool grading; match the breaker and coolant relay rendering, and do not copy any objects or figures. Reference 3 supplies only mood, light, and palette; do not copy its composition or figures. Reference 4 supplies only the color swatches. Reference 5 supplies only the layout and proportions for the new gray housing and engineer scale; ignore the reference's colors, flat drawing, engineer, and old vent shown at the top.

The prop is a squat heavy steel box housing, exactly 3 units wide by 2 units tall, about two-thirds the engineer's height in the guide. Show a straight side-elevation game prop with its front face toward the viewer, no perspective tilt and no vanishing point. Keep the whole object centered, filling most of the frame with about 6% margin on each side. Give it a thick overhanging top lip. Make the front face almost entirely one large grate with 5–6 broad horizontal louvre slats and clearly dark gaps between them. Include two bolted feet/end caps at the bottom corners, each carrying a short hazard-striped band alternating amber metal #82510e with dark steel. Preserve the old vent's small pressure-fitting identity cue as simple chunky fittings integrated into the housing. Center exactly one horizontal lamp socket on the top lip, about 35% of the housing width; its glass is unlit dark cool glass with no glow because the game draws that light separately. Keep the construction simple, chunky, and readable at small size. No steam and no glow from the grate.

Render in Look 2 graphic-painterly style: shape-first graphic painting with large flat value planes, 3–4 value steps per material, minimal texture, and a crisp shape-designed silhouette. Use painterly soft transitions only inside light pools and glows; this prop has no glow. No grain, speckle, rust spots, scratches, tiny bolts or rivets, or fine panel lines; use at most one broad panel line. Light the upward-facing surfaces clearly lighter than the body with cold overhead top light, plus a broad cyan-white rim from #82c3e6 to #c3c5d7 along the top and back edges. Use no dark outline or ink contour; define edges with value and rim light. Keep the body fully opaque with a clean 1–2 px anti-aliased silhouette edge, no matte fringe and no halo. Cool-grade all steel and shadows in blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0); keep the body mostly mid-dark. Saturated color appears only on the named accent: hazard bands use amber metal #82510e alternating with dark steel. All other surfaces, fittings, louvres, and unlit lamp glass are cool dark steel; do not add other saturated accents.

Request a genuinely transparent RGBA background and preserve the generated alpha. Do not add text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, glow outside the silhouette, steam, sparks, another object, magenta, or pink.

Final targeted correction for this retry: this must be a clean transparent cutout, with no visible background pixels, haze, bloom, halo, backdrop, floor, or shadow anywhere around the vent. Alpha must be 0 everywhere outside the 1–2 px antialiased outer silhouette edge; only the vent itself may be visible.
```

