# Image generation log

Mode: built-in image_gen edit; transparent_background=true for every call. Reference images were passed in the listed order.

## Attempt 1 — tank-arm (rejected)

- Output file: `raw/rejected-tank-arm-1.png`
- Generated source: `[Codex generated-images store]/01a12820-5692-7861-a5d4-3157b1dca16f/exec-f1ea4ce1-ba88-436d-9c8b-f2d1d7e998e9.png`
- Verdict: Rejected: generated an unrelated wrench-like object and lost the target assembly.
- References:
  1. `[session scratch, not kept]/hq/props/refs/tank-master.png` — edit target; preserve assembly/tank layout and silhouette
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, and palette only
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only
  5. `apps/game/assets/props/junction-tank-arm.png` — hardware design reference; Image 1 controls the exact edit layout

Verbatim prompt:

```text
Use case: precise-object-edit
Asset type: transparent PNG sprite for a 2D side-view sci-fi horror game, named tank-arm.png
Input images, in this exact order:
Image 1, [session scratch, not kept]/hq/props/refs/tank-master.png: edit target; preserve its mechanical assembly layout and silhouette.
Image 2, [session scratch, not kept]/hq/props/refs/ref-look2-board.png: rendering, value structure, edge treatment, and cool grading only; match how the breaker and coolant relay are rendered. Do not copy its objects or figures.
Image 3, apps/game/assets/title-corridor-key-art-provisional.png: mood, light, and palette only; do not copy its composition or figures.
Image 4, [session scratch, not kept]/hq/props/refs/palette-card.png: colour swatches only.
Image 5, apps/game/assets/props/junction-tank-arm.png: hardware design reference only; retain its intended tank-arm design cues, with Image 1 controlling the edit target's exact layout.
Primary request: From Image 1, remove ONLY the tank and its cradle, including the cradle's top lug and its small amber light. Keep the ceiling plate, column, articulated arm, winch, cable, and the shackle hook hanging EMPTY and closed at the bottom of the cable, exactly where they are and at the same scale. Keep the retained components' silhouette, layout, function, position, and colour coding. Nothing below the shackle. Re-render in the approved Look 2 style.
Shared approved style, "Look 2, graphic-painterly":
- shape-first graphic painting: large flat value planes, 3-4 value steps per material, minimal texture, crisp shape-designed silhouette;
- painterly soft transitions only inside light pools and glows; no grain, no speckle, no rust spots, no scratches, no tiny bolts or rivets, no fine panel lines (one broad panel line where the old design had three);
- light: cold overhead top light (upward faces clearly lighter than the body) plus a BROAD cyan-white rim (#82c3e6 to #c3c5d7) on the top and back edges;
- NO dark outline or ink contour anywhere; edges are made by value and rim light; fully opaque body; clean 1-2 px anti-aliased silhouette edge, no matte fringe, no halo;
- cool grading: steel and shadows are cool blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty, so the object sits inside the dark corridor values (body mostly mid-dark, like the breaker and relay in the Look 2 board);
- saturated colour ONLY on the named accent, and only from these swatches: signal red #a01e29 / #ad252d, red glow #ca452f, amber glow #e0936e, amber metal #82510e, dim amber #6e4824, cyan strip #30d0fc, cyan keypad #2091ca, cyan seam #4f8ab8, safe green #56dc69 / #228237 / #17632f;
- MATTE, not glossy: no specular hot-spots, no chrome or plastic sheen, no smooth gradients along pipes; every pipe, tube and box reads as 3 flat value bands (shadow, mid, lit top) plus the rim. Overall value as DARK as the Look 2 breaker: most of the body between #121f2c and #2f4d69, only top faces and the rim lighter. Steel chroma stays LOW (blue-grey, never a saturated or bright blue).
- straight side-elevation game prop (front face toward the viewer, no perspective tilt, no vanishing point), object centred with about 6% margin on every side, filling most of the frame.
- DO NOT: text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, glow outside the silhouette, steam, sparks, a second object, magenta or pink.
Background: genuinely transparent RGBA; preserve generated alpha. No haze around the silhouette. Fully opaque object body.
```

## Attempt 2 — tank-arm (rejected)

- Output file: `raw/rejected-tank-arm-2.png`
- Generated source: `[Codex generated-images store]/01a1282a-6a80-7c23-977c-c90c15bd76c3/exec-40722823-0145-48ad-ab16-0ce7743828bd.png`
- Verdict: Rejected: correct rig and empty closed shackle, but a broad translucent blue haze remained outside the silhouette.
- References:
  1. `[session scratch, not kept]/hq/props/refs/tank-master.png` — edit target; preserve assembly/tank layout and silhouette
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, and palette only
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only
  5. `apps/game/assets/props/junction-tank-arm.png` — hardware design reference; Image 1 controls the exact edit layout

Verbatim prompt:

```text
Use case: precise-object-edit
Asset type: transparent PNG sprite for a 2D side-view sci-fi horror game, named tank-arm.png
Input images, in this exact order:
Image 1, [session scratch, not kept]/hq/props/refs/tank-master.png: edit target; preserve its mechanical assembly layout and silhouette.
Image 2, [session scratch, not kept]/hq/props/refs/ref-look2-board.png: rendering, value structure, edge treatment, and cool grading only; match how the breaker and coolant relay are rendered. Do not copy its objects or figures.
Image 3, apps/game/assets/title-corridor-key-art-provisional.png: mood, light, and palette only; do not copy its composition or figures.
Image 4, [session scratch, not kept]/hq/props/refs/palette-card.png: colour swatches only.
Image 5, apps/game/assets/props/junction-tank-arm.png: hardware design reference only; retain its intended tank-arm design cues, with Image 1 controlling the edit target's exact layout.
Primary request: From Image 1, remove ONLY the tank and its cradle, including the cradle's top lug and its small amber light. Keep the ceiling plate, column, articulated arm, winch, cable, and the shackle hook hanging EMPTY and closed at the bottom of the cable, exactly where they are and at the same scale. Keep the retained components' silhouette, layout, function, position, and colour coding. Nothing below the shackle. Re-render in the approved Look 2 style.
Correction for this attempt: The previous attempt lost the target and made an unrelated wrench-like object. Restore the complete ceiling-mounted lifting rig shown in Image 1: the broad horizontal ceiling plate, central vertical column, articulated diagonal support arm, right-side cylindrical cable winch, hanging vertical cable, and empty closed shackle. Preserve those exact connected parts and their relative positions; remove only the lower tank and all of its cradle assembly. Do not make a wrench, lever, standalone beam, or any isolated object.
Shared approved style, "Look 2, graphic-painterly":
- shape-first graphic painting: large flat value planes, 3-4 value steps per material, minimal texture, crisp shape-designed silhouette;
- painterly soft transitions only inside light pools and glows; no grain, no speckle, no rust spots, no scratches, no tiny bolts or rivets, no fine panel lines (one broad panel line where the old design had three);
- light: cold overhead top light (upward faces clearly lighter than the body) plus a BROAD cyan-white rim (#82c3e6 to #c3c5d7) on the top and back edges;
- NO dark outline or ink contour anywhere; edges are made by value and rim light; fully opaque body; clean 1-2 px anti-aliased silhouette edge, no matte fringe, no halo;
- cool grading: steel and shadows are cool blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty, so the object sits inside the dark corridor values (body mostly mid-dark, like the breaker and relay in the Look 2 board);
- saturated colour ONLY on the named accent, and only from these swatches: signal red #a01e29 / #ad252d, red glow #ca452f, amber glow #e0936e, amber metal #82510e, dim amber #6e4824, cyan strip #30d0fc, cyan keypad #2091ca, cyan seam #4f8ab8, safe green #56dc69 / #228237 / #17632f;
- MATTE, not glossy: no specular hot-spots, no chrome or plastic sheen, no smooth gradients along pipes; every pipe, tube and box reads as 3 flat value bands (shadow, mid, lit top) plus the rim. Overall value as DARK as the Look 2 breaker: most of the body between #121f2c and #2f4d69, only top faces and the rim lighter. Steel chroma stays LOW (blue-grey, never a saturated or bright blue).
- straight side-elevation game prop (front face toward the viewer, no perspective tilt, no vanishing point), object centred with about 6% margin on every side, filling most of the frame.
- DO NOT: text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, glow outside the silhouette, steam, sparks, a second object, magenta or pink.
Background: genuinely transparent RGBA; preserve generated alpha. No haze around the silhouette. Fully opaque object body.
```

## Attempt 3 — tank-arm (kept as best)

- Output file: `raw/tank-arm.png`
- Generated source: `[Codex generated-images store]/01a1282a-6a80-7c23-977c-c90c15bd76c3/exec-220092b6-b6b2-4866-ba38-058b73b25de7.png`
- Verdict: Kept: correct rig and empty closed shackle; this had less external haze than attempt 2, though some soft haze remains.
- References:
  1. `[session scratch, not kept]/hq/props/refs/tank-master.png` — edit target; preserve assembly/tank layout and silhouette
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, and palette only
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only
  5. `apps/game/assets/props/junction-tank-arm.png` — hardware design reference; Image 1 controls the exact edit layout

Verbatim prompt:

```text
Use case: precise-object-edit
Asset type: transparent PNG sprite for a 2D side-view sci-fi horror game, named tank-arm.png
Input images, in this exact order:
Image 1, [session scratch, not kept]/hq/props/refs/tank-master.png: edit target; preserve its mechanical assembly layout and silhouette.
Image 2, [session scratch, not kept]/hq/props/refs/ref-look2-board.png: rendering, value structure, edge treatment, and cool grading only; match how the breaker and coolant relay are rendered. Do not copy its objects or figures.
Image 3, apps/game/assets/title-corridor-key-art-provisional.png: mood, light, and palette only; do not copy its composition or figures.
Image 4, [session scratch, not kept]/hq/props/refs/palette-card.png: colour swatches only.
Image 5, apps/game/assets/props/junction-tank-arm.png: hardware design reference only; retain its intended tank-arm design cues, with Image 1 controlling the edit target's exact layout.
Primary request: From Image 1, remove ONLY the tank and its cradle, including the cradle's top lug and its small amber light. Keep the ceiling plate, column, articulated arm, winch, cable, and the shackle hook hanging EMPTY and closed at the bottom of the cable, exactly where they are and at the same scale. Keep the retained components' silhouette, layout, function, position, and colour coding. Nothing below the shackle. Re-render in the approved Look 2 style.
Correction for this final attempt: Preserve the correct complete lifting rig from the previous attempt, but remove its broad translucent blue haze and all background glow outside the silhouette. The canvas outside the object must be genuinely transparent RGBA with zero background pixels, not black, blue, or a vignette; retain only a clean 1-2 px anti-aliased edge. Do not change or remove any part of the rig.
Shared approved style, "Look 2, graphic-painterly":
- shape-first graphic painting: large flat value planes, 3-4 value steps per material, minimal texture, crisp shape-designed silhouette;
- painterly soft transitions only inside light pools and glows; no grain, no speckle, no rust spots, no scratches, no tiny bolts or rivets, no fine panel lines (one broad panel line where the old design had three);
- light: cold overhead top light (upward faces clearly lighter than the body) plus a BROAD cyan-white rim (#82c3e6 to #c3c5d7) on the top and back edges;
- NO dark outline or ink contour anywhere; edges are made by value and rim light; fully opaque body; clean 1-2 px anti-aliased silhouette edge, no matte fringe, no halo;
- cool grading: steel and shadows are cool blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty, so the object sits inside the dark corridor values (body mostly mid-dark, like the breaker and relay in the Look 2 board);
- saturated colour ONLY on the named accent, and only from these swatches: signal red #a01e29 / #ad252d, red glow #ca452f, amber glow #e0936e, amber metal #82510e, dim amber #6e4824, cyan strip #30d0fc, cyan keypad #2091ca, cyan seam #4f8ab8, safe green #56dc69 / #228237 / #17632f;
- MATTE, not glossy: no specular hot-spots, no chrome or plastic sheen, no smooth gradients along pipes; every pipe, tube and box reads as 3 flat value bands (shadow, mid, lit top) plus the rim. Overall value as DARK as the Look 2 breaker: most of the body between #121f2c and #2f4d69, only top faces and the rim lighter. Steel chroma stays LOW (blue-grey, never a saturated or bright blue).
- straight side-elevation game prop (front face toward the viewer, no perspective tilt, no vanishing point), object centred with about 6% margin on every side, filling most of the frame.
- DO NOT: text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, glow outside the silhouette, steam, sparks, a second object, magenta or pink.
Background: genuinely transparent RGBA; preserve generated alpha. No haze around the silhouette. Fully opaque object body.
```

## Attempt 1 — tank (kept as best)

- Output file: `raw/tank.png`
- Generated source: `[Codex generated-images store]/01a1282a-6a80-7c23-977c-c90c15bd76c3/exec-43fd03a9-12f3-455c-bd37-bae1e7961ca1.png`
- Verdict: Kept: tank, cradle, top lug, hazard bands, and cyan lights are present without the shackle; this had less external haze than the later attempts, though some haze remains.
- References:
  1. `[session scratch, not kept]/hq/props/refs/tank-master.png` — edit target; preserve assembly/tank layout and silhouette
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, and palette only
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only
  5. `apps/game/assets/props/junction-tank.png` — tank and cradle design reference; Image 1 controls the exact layout

Verbatim prompt:

```text
Use case: precise-object-edit
Asset type: transparent PNG sprite for a 2D side-view sci-fi horror game, named tank.png
Input images, in this exact order:
Image 1, [session scratch, not kept]/hq/props/refs/tank-master.png: edit target; preserve the tank and cradle layout and silhouette.
Image 2, [session scratch, not kept]/hq/props/refs/ref-look2-board.png: rendering, value structure, edge treatment, and cool grading only; match how the breaker and coolant relay are rendered. Do not copy its objects or figures.
Image 3, apps/game/assets/title-corridor-key-art-provisional.png: mood, light, and palette only; do not copy its composition or figures.
Image 4, [session scratch, not kept]/hq/props/refs/palette-card.png: colour swatches only.
Image 5, apps/game/assets/props/junction-tank.png: tank and cradle design reference only; retain its design cues, with Image 1 controlling the exact layout.
Primary request: From Image 1, remove ONLY the ceiling plate, column, articulated arm, winch, cable, and the shackle hook and chain. Keep the tank inside its cradle, including the cradle's top lug, exactly as in the master: same size, same design, same hazard bands, and small cyan side lights. The tank and cradle must be the only object; the retained top lug is the uppermost part. Preserve their silhouette, layout, function, position, and colour coding. Re-render in the approved Look 2 style.
Shared approved style, "Look 2, graphic-painterly":
- shape-first graphic painting: large flat value planes, 3-4 value steps per material, minimal texture, crisp shape-designed silhouette;
- painterly soft transitions only inside light pools and glows; no grain, no speckle, no rust spots, no scratches, no tiny bolts or rivets, no fine panel lines (one broad panel line where the old design had three);
- light: cold overhead top light (upward faces clearly lighter than the body) plus a BROAD cyan-white rim (#82c3e6 to #c3c5d7) on the top and back edges;
- NO dark outline or ink contour anywhere; edges are made by value and rim light; fully opaque body; clean 1-2 px anti-aliased silhouette edge, no matte fringe, no halo;
- cool grading: steel and shadows are cool blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty, so the object sits inside the dark corridor values (body mostly mid-dark, like the breaker and relay in the Look 2 board);
- saturated colour ONLY on the named accent, and only from these swatches: signal red #a01e29 / #ad252d, red glow #ca452f, amber glow #e0936e, amber metal #82510e, dim amber #6e4824, cyan strip #30d0fc, cyan keypad #2091ca, cyan seam #4f8ab8, safe green #56dc69 / #228237 / #17632f;
- MATTE, not glossy: no specular hot-spots, no chrome or plastic sheen, no smooth gradients along pipes; every pipe, tube and box reads as 3 flat value bands (shadow, mid, lit top) plus the rim. Overall value as DARK as the Look 2 breaker: most of the body between #121f2c and #2f4d69, only top faces and the rim lighter. Steel chroma stays LOW (blue-grey, never a saturated or bright blue).
- straight side-elevation game prop (front face toward the viewer, no perspective tilt, no vanishing point), object centred with about 6% margin on every side, filling most of the frame.
- DO NOT: text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, glow outside the silhouette, steam, sparks, a second object, magenta or pink.
Background: genuinely transparent RGBA; preserve generated alpha. No haze around the silhouette. Fully opaque object body.
```

## Attempt 2 — tank (rejected)

- Output file: `raw/rejected-tank-2.png`
- Generated source: `[Codex generated-images store]/01a1282a-6a80-7c23-977c-c90c15bd76c3/exec-32e9164c-21ba-45bb-8f19-7a33b84f0721.png`
- Verdict: Rejected: retained a D-shaped shackle hook above the cradle's top lug and still had a blue haze.
- References:
  1. `[session scratch, not kept]/hq/props/refs/tank-master.png` — edit target; preserve assembly/tank layout and silhouette
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, and palette only
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only
  5. `apps/game/assets/props/junction-tank.png` — tank and cradle design reference; Image 1 controls the exact layout

Verbatim prompt:

```text
Use case: precise-object-edit
Asset type: transparent PNG sprite for a 2D side-view sci-fi horror game, named tank.png
Input images, in this exact order:
Image 1, [session scratch, not kept]/hq/props/refs/tank-master.png: edit target; preserve the tank and cradle layout and silhouette.
Image 2, [session scratch, not kept]/hq/props/refs/ref-look2-board.png: rendering, value structure, edge treatment, and cool grading only; match how the breaker and coolant relay are rendered. Do not copy its objects or figures.
Image 3, apps/game/assets/title-corridor-key-art-provisional.png: mood, light, and palette only; do not copy its composition or figures.
Image 4, [session scratch, not kept]/hq/props/refs/palette-card.png: colour swatches only.
Image 5, apps/game/assets/props/junction-tank.png: tank and cradle design reference only; retain its design cues, with Image 1 controlling the exact layout.
Primary request: From Image 1, remove ONLY the ceiling plate, column, articulated arm, winch, cable, and the shackle hook and chain. Keep the tank inside its cradle, including the cradle's top lug, exactly as in the master: same size, same design, same hazard bands, and small cyan side lights. The tank and cradle must be the only object; the retained top lug is the uppermost part. Preserve their silhouette, layout, function, position, and colour coding. Re-render in the approved Look 2 style.
Correction for this attempt: Keep the same correct tank and cradle, but remove the broad translucent blue haze and every glow outside the silhouette. Make all exterior background pixels fully transparent; retain only a clean 1-2 px anti-aliased edge around the opaque object, with no colored, black, or blue gradient backdrop.
Shared approved style, "Look 2, graphic-painterly":
- shape-first graphic painting: large flat value planes, 3-4 value steps per material, minimal texture, crisp shape-designed silhouette;
- painterly soft transitions only inside light pools and glows; no grain, no speckle, no rust spots, no scratches, no tiny bolts or rivets, no fine panel lines (one broad panel line where the old design had three);
- light: cold overhead top light (upward faces clearly lighter than the body) plus a BROAD cyan-white rim (#82c3e6 to #c3c5d7) on the top and back edges;
- NO dark outline or ink contour anywhere; edges are made by value and rim light; fully opaque body; clean 1-2 px anti-aliased silhouette edge, no matte fringe, no halo;
- cool grading: steel and shadows are cool blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty, so the object sits inside the dark corridor values (body mostly mid-dark, like the breaker and relay in the Look 2 board);
- saturated colour ONLY on the named accent, and only from these swatches: signal red #a01e29 / #ad252d, red glow #ca452f, amber glow #e0936e, amber metal #82510e, dim amber #6e4824, cyan strip #30d0fc, cyan keypad #2091ca, cyan seam #4f8ab8, safe green #56dc69 / #228237 / #17632f;
- MATTE, not glossy: no specular hot-spots, no chrome or plastic sheen, no smooth gradients along pipes; every pipe, tube and box reads as 3 flat value bands (shadow, mid, lit top) plus the rim. Overall value as DARK as the Look 2 breaker: most of the body between #121f2c and #2f4d69, only top faces and the rim lighter. Steel chroma stays LOW (blue-grey, never a saturated or bright blue).
- straight side-elevation game prop (front face toward the viewer, no perspective tilt, no vanishing point), object centred with about 6% margin on every side, filling most of the frame.
- DO NOT: text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, glow outside the silhouette, steam, sparks, a second object, magenta or pink.
Background: genuinely transparent RGBA; preserve generated alpha. No haze around the silhouette. Fully opaque object body.
```

## Attempt 3 — tank (rejected)

- Output file: `raw/rejected-tank-3.png`
- Generated source: `[Codex generated-images store]/01a1282a-6a80-7c23-977c-c90c15bd76c3/exec-d4f9eb22-5d97-4615-bcfe-1b4992f8a152.png`
- Verdict: Rejected as not best: the tank split was correct, but its external haze was broader than the kept attempt 1.
- References:
  1. `[session scratch, not kept]/hq/props/refs/tank-master.png` — edit target; preserve assembly/tank layout and silhouette
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, and palette only
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only
  5. `apps/game/assets/props/junction-tank.png` — tank and cradle design reference; Image 1 controls the exact layout

Verbatim prompt:

```text
Use case: precise-object-edit
Asset type: transparent PNG sprite for a 2D side-view sci-fi horror game, named tank.png
Input images, in this exact order:
Image 1, [session scratch, not kept]/hq/props/refs/tank-master.png: edit target; preserve the tank and cradle layout and silhouette.
Image 2, [session scratch, not kept]/hq/props/refs/ref-look2-board.png: rendering, value structure, edge treatment, and cool grading only; match how the breaker and coolant relay are rendered. Do not copy its objects or figures.
Image 3, apps/game/assets/title-corridor-key-art-provisional.png: mood, light, and palette only; do not copy its composition or figures.
Image 4, [session scratch, not kept]/hq/props/refs/palette-card.png: colour swatches only.
Image 5, apps/game/assets/props/junction-tank.png: tank and cradle design reference only; retain its design cues, with Image 1 controlling the exact layout.
Primary request: From Image 1, remove ONLY the ceiling plate, column, articulated arm, winch, cable, and the shackle hook and chain. Keep the tank inside its cradle, including the cradle's top lug, exactly as in the master: same size, same design, same hazard bands, and small cyan side lights. The tank and cradle must be the only object; the retained top lug is the uppermost part. Preserve their silhouette, layout, function, position, and colour coding. Re-render in the approved Look 2 style.
Correction for this final attempt: Correct the asset boundary so the tank and cradle alone remain. In particular, remove the D-shaped shackle hook that appeared above the top lug in the previous attempt, plus all cable, chain, and other lifting gear; the cradle's lit top lug stays as the uppermost retained part. Remove all surrounding black-blue vignette and translucent haze so the entire exterior beyond a clean 1-2 px antialiased silhouette is fully transparent. Do not alter the tank, cradle, top lug, hazard bands, or cyan side lights.
Shared approved style, "Look 2, graphic-painterly":
- shape-first graphic painting: large flat value planes, 3-4 value steps per material, minimal texture, crisp shape-designed silhouette;
- painterly soft transitions only inside light pools and glows; no grain, no speckle, no rust spots, no scratches, no tiny bolts or rivets, no fine panel lines (one broad panel line where the old design had three);
- light: cold overhead top light (upward faces clearly lighter than the body) plus a BROAD cyan-white rim (#82c3e6 to #c3c5d7) on the top and back edges;
- NO dark outline or ink contour anywhere; edges are made by value and rim light; fully opaque body; clean 1-2 px anti-aliased silhouette edge, no matte fringe, no halo;
- cool grading: steel and shadows are cool blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty, so the object sits inside the dark corridor values (body mostly mid-dark, like the breaker and relay in the Look 2 board);
- saturated colour ONLY on the named accent, and only from these swatches: signal red #a01e29 / #ad252d, red glow #ca452f, amber glow #e0936e, amber metal #82510e, dim amber #6e4824, cyan strip #30d0fc, cyan keypad #2091ca, cyan seam #4f8ab8, safe green #56dc69 / #228237 / #17632f;
- MATTE, not glossy: no specular hot-spots, no chrome or plastic sheen, no smooth gradients along pipes; every pipe, tube and box reads as 3 flat value bands (shadow, mid, lit top) plus the rim. Overall value as DARK as the Look 2 breaker: most of the body between #121f2c and #2f4d69, only top faces and the rim lighter. Steel chroma stays LOW (blue-grey, never a saturated or bright blue).
- straight side-elevation game prop (front face toward the viewer, no perspective tilt, no vanishing point), object centred with about 6% margin on every side, filling most of the frame.
- DO NOT: text, letters, numbers, labels, logos, warning signs with words, UI, watermark, guide lines, borders, floor, ground plane, cast or contact shadow, reflection, glow outside the silhouette, steam, sparks, a second object, magenta or pink.
Background: genuinely transparent RGBA; preserve generated alpha. No haze around the silhouette. Fully opaque object body.
```

