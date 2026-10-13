# STATUS LAMP

The built-in image generation tool was used with transparent output enabled. Each copy in `raw/` is byte-for-byte identical to its generated source.

## Call 1 — rejected

- Output file: `raw/rejected-status-lamp-1.png`
- Source path: `[Codex generated-images store]/01a1281e-f2a9-77d3-abf6-0e3f9877d724/exec-6506d32c-d8f3-470c-b662-a101e85b692f.png`
- Verbatim prompt:

    Use case: stylized-concept
    Asset type: isolated 2D side-view sci-fi horror game prop sprite
    Primary request: Re-render only the small horizontal indicator lamp glass lens seen in Image 1, as a separate status-lamp sprite. The game tints this sprite per state, so draw it near-white.
    Input images: Image 1: WOLF//OVERRIDE design reference; use only the breaker’s amber lamp window for this lens’s size and role. Image 2: rendering reference only; match the Look 2 breaker and coolant relay’s shape-first graphic-painterly value structure, edge treatment, and cool grading. Image 3: mood, light, and palette only. Image 4: colour swatches only.
    Scene/backdrop: genuinely transparent RGBA background.
    Subject: ONLY one glowing glass lens, a horizontal rounded-rectangle pill exactly 4 times as wide as it is tall. Center it on a very wide 4:1 canvas, with 10% transparent margin on every side; the lens fills about 80% of canvas width and height.
    Style/medium: Look 2 graphic-painterly, shape-first large flat value planes with 3–4 value steps, minimal texture, crisp shape-designed silhouette. No grain, speckle, rust spots, scratches, tiny bolts, rivets, or fine panel lines.
    Composition/framing: straight side elevation, front face toward the viewer, no perspective tilt or vanishing point. One centered lens, no other objects.
    Lighting/mood: cold overhead top light; upward-facing area clearly lighter than the body. Add a broad cyan-white rim only along the lens’s top and back edges (#82c3e6 to #c3c5d7). Keep all light, highlight, and glow inside the lens silhouette.
    Color palette: lit pale cool white lens, core #e3f6fe, edges #ade4fb, with a slightly brighter soft highlight band along the top third. Keep the body near-white and cool. No magenta or pink.
    Materials/textures: fully opaque glass lens with flat graphic shading and clean 1–2 px antialiased silhouette edge; no matte fringe or halo.
    Text (verbatim): none.
    Constraints: preserve the simple lens-only role from Image 1, but render a separate near-white sprite. No bezel, dark outline, housing, external glow or bloom, floor, ground plane, contact or cast shadow, reflection, steam, sparks, second object, labels, symbols, logos, UI, watermark, guide lines, or border. No text, letters, or numbers. Keep the background genuinely transparent with alpha; do not substitute magenta.

- References:
  - Image 1 — `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — design reference; amber breaker lamp size and role.
  - Image 2 — `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 3 — `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, and palette only.
  - Image 4 — `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only.
- Verdict: Rejected; lens was visibly too elongated and disconnected cyan pixels appeared outside the silhouette.

## Call 2 — rejected

- Output file: `raw/rejected-status-lamp-2.png`
- Source path: `[Codex generated-images store]/01a1281e-f2a9-77d3-abf6-0e3f9877d724/exec-df90fd92-acd9-4d41-921c-ebdb28a1104a.png`
- Verbatim prompt:

    Use case: stylized-concept
    Asset type: isolated 2D side-view sci-fi horror game prop sprite
    Primary request: Render only the small horizontal status-lamp glass lens as a separate sprite, near-white because the game tints it per state. Make one focused geometry correction: the single lens is a simple smooth rounded-rectangle pill exactly 4 times as wide as its total height, with no nested rim, faceted bevel, or disconnected pixels.
    Input images: Image 1: WOLF//OVERRIDE design reference; use only the breaker’s amber lamp window for this lens’s size and role. Image 2: rendering reference only; match the Look 2 breaker and coolant relay’s shape-first graphic-painterly value structure, edge treatment, and cool grading. Image 3: mood, light, and palette only. Image 4: colour swatches only.
    Scene/backdrop: genuinely transparent RGBA.
    Subject: ONLY one glowing glass lens, with pill silhouette width:height exactly 4:1.
    Style/medium: Look 2 graphic-painterly; shape-first large flat value planes, 3–4 value steps, minimal texture, crisp designed silhouette. No grain, speckle, rust spots, scratches, tiny bolts, rivets, or fine panel lines.
    Composition/framing: straight side elevation, front face toward the viewer, no perspective tilt or vanishing point. Center the lens on the widest available horizontal canvas, with at least 10% transparent margin on every side.
    Lighting/mood: cold overhead top light; upward-facing area clearly lighter than the body. A broad cyan-white rim (#82c3e6 to #c3c5d7) only on the top and back edges. Keep the brighter soft highlight band along the top third and every light effect inside the lens silhouette.
    Color palette: lit pale cool white, core #e3f6fe, edges #ade4fb; keep the body near-white and cool. No magenta or pink.
    Materials/textures: fully opaque glass lens with a clean 1–2 px antialiased silhouette edge; no matte fringe or halo.
    Text (verbatim): none.
    Constraints: no bezel, dark outline, housing, external glow or bloom, floor, ground plane, cast or contact shadow, reflection, steam, sparks, second object, labels, symbols, logos, UI, watermark, guide lines, or border. No text, letters, or numbers. All pixels outside the single lens must be fully transparent, with no stray specks. Keep alpha; do not substitute magenta.

- References:
  - Image 1 — `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — design reference; amber breaker lamp size and role.
  - Image 2 — `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 3 — `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, and palette only.
  - Image 4 — `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only.
- Verdict: Rejected; lens remained too elongated and still had disconnected cyan pixels outside the silhouette.

## Call 3 — rejected (final allowed retry)

- Output file: `raw/rejected-status-lamp-3.png`
- Source path: `[Codex generated-images store]/01a1281e-f2a9-77d3-abf6-0e3f9877d724/exec-cb38cc88-dfcb-4513-b5ff-2092900c123f.png`
- Verbatim prompt:

    Use case: stylized-concept
    Asset type: isolated 2D side-view sci-fi horror game prop sprite
    Primary request: Render only the small horizontal status-lamp glass lens as a separate sprite, near-white because the game tints it per state. Final focused correction: make the lens silhouette exactly 4:1; on a 3:1 canvas place the lens from x=10% to x=90% and y=20% to y=80% (80% canvas width by 60% canvas height). Use one simple continuous rounded-rectangle pill with semicircle ends; remove any stray pixels outside the silhouette.
    Input images: Image 1: WOLF//OVERRIDE design reference; use only the breaker’s amber lamp window for this lens’s size and role. Image 2: rendering reference only; match the Look 2 breaker and coolant relay’s shape-first graphic-painterly value structure, edge treatment, and cool grading. Image 3: mood, light, and palette only. Image 4: colour swatches only.
    Scene/backdrop: genuinely transparent RGBA.
    Subject: ONLY one glowing glass lens, total width exactly 4 times its total height.
    Style/medium: Look 2 graphic-painterly; shape-first large flat value planes, 3–4 value steps, minimal texture, crisp designed silhouette. No grain, speckle, rust spots, scratches, tiny bolts, rivets, or fine panel lines.
    Composition/framing: straight side elevation, front face toward the viewer, no perspective tilt or vanishing point. Center the lens on a wide horizontal canvas with at least 10% transparent margin on every side.
    Lighting/mood: cold overhead top light; upward-facing area clearly lighter than the body. A broad cyan-white rim (#82c3e6 to #c3c5d7) only on the top and back edges. Keep all light effects inside the lens silhouette; include a slightly brighter soft highlight band along the top third.
    Color palette: lit pale cool white, core #e3f6fe, edges #ade4fb; keep the body near-white and cool. No magenta or pink.
    Materials/textures: fully opaque glass lens with flat graphic shading and a clean 1–2 px antialiased silhouette edge; no matte fringe or halo.
    Text (verbatim): none.
    Constraints: no bezel, nested rim, faceted bevel, dark outline, housing, external glow or bloom, floor, ground plane, cast or contact shadow, reflection, steam, sparks, second object, labels, symbols, logos, UI, watermark, guide lines, or border. No text, letters, or numbers. Pixels outside the single lens must have alpha zero and contain no stray specks. Keep alpha; do not substitute magenta.

- References:
  - Image 1 — `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — design reference; amber breaker lamp size and role.
  - Image 2 — `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Look 2 rendering, value structure, edge treatment, and cool grading only.
  - Image 3 — `apps/game/assets/title-corridor-key-art-provisional.png` — mood, light, and palette only.
  - Image 4 — `[session scratch, not kept]/hq/props/refs/palette-card.png` — colour swatches only.
- Verdict: Rejected; lens shape still was not 4:1 and cyan/white edge specks were visible outside the silhouette. All three outputs retained alpha.
