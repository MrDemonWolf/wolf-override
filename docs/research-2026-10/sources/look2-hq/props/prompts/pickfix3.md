# Cracked Gauge Imagegen Record

Built-in imagegen edit mode. The references were supplied in the listed order for every call.

## Attempt 1 — raw/rejected-pickup-cracked-gauge-1.png

- Source: `[Codex generated-images store]/01a1284b-0d30-7573-bba4-53ff683e9794/exec-8d87557c-d7e6-49e3-a54a-3cc19242b65b.png`
- Tool option: `transparent_background=not set`
- References:
  1. `[session scratch, not kept]/hq/props/raw/pickfix2/raw/pickup-cracked-gauge.png` — Image 1 — exact design/edit target; preserve silhouette, layout, function, tilt, framing, red arc, needle and hub.
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Image 2 — Look 2 rendering, values, edges and cool grading only; do not copy objects or figures.
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — Image 3 — mood, light and palette only; do not copy composition or figures.
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — Image 4 — colour swatches only.
- Verdict: Rejected: opaque checkerboard background; file is RGB with no alpha channel.

Verbatim prompt:

```text
Use case: precise-object-edit
Asset type: one 2D side-view sci-fi horror game pickup sprite, intended to shrink to about 110 px tall.
Input images: Image 1 is the exact edit target; preserve its silhouette, layout, function, diagonal tilt, framing, red arc, needle and hub. Image 2 is rendering/value/edge/cool-grading reference only; match the breaker and coolant relay rendering, and do not copy its objects or figures. Image 3 is mood, light and palette reference only; do not copy its composition or figures. Image 4 is colour swatches only.
Scene/backdrop: no scene; export a PNG with genuinely transparent RGBA background and retain alpha. Do not render black, white, checkerboard, or any coloured background.
Subject: the single cracked round gauge from Image 1, facing the viewer in straight side elevation, with its threaded stem angled down-right.
Primary request: Precisely re-render the target with only these three design corrections:
1. CRACKS — Replace the pale fracture marks with a star break of 4–5 DARK cool wedges radiating from one impact point on the left half of the face. Use #4a5666 at the core and #6f8396 at the edges. Each is a solid tapered shape, at least 1/12 of the face diameter wide near the impact point, and extends far enough to cross most of the face. Add one small dark chipped pit at the impact point. The broken glass must read clearly when the sprite is reduced to an icon. Use broad shapes only: no hairlines, fine shards, pale or white crack marks.
2. BEZEL AND STEM — Render as matte cool steel, never chrome or polished: no mirror reflections, gloss, or specular hotspots. Use exactly three flat value bands on both bezel and threaded stem: lower outer shadow #626c76, mid #7b8590, upper lit #949faa. Add a broad cyan-white rim along the bezel’s top edge, shifting between #c3c5d7 and #82c3e6. Keep the gauge’s existing geometry and stem threads.
3. FACE VALUE — Replace paper white with dim cool grey #a2acb8, slightly lighter #b0b9c4 in the upper region under the overhead top light. Add a shaded #7b8590 band just inside the bezel so the face edge is no lighter than the bezel. The face remains the object’s lightest plane while sitting within a dark room’s values.
Keep exactly the existing broad upper-right red zone arc in signal red #a01e29 / #ad252d, and the bold dark needle pointing past the red zone toward 4–5 o’clock with its round hub. Preserve the target’s exact silhouette, layout, diagonal tilt, framing and proportions; do not redesign.
Style/medium: Look 2 graphic-painterly, shape-first painting with large flat value planes, 3–4 value steps per material, minimal texture and a crisp shape-designed silhouette. Painterly soft transitions only inside light pools or glows; this object has no external glow. Cold overhead top light makes upward-facing surfaces clearly lighter than the body, plus a broad cyan-white rim on top and back edges. No dark outline or ink contour anywhere; define edges with value and rim light. Body fully opaque with a clean 1–2 px antialiased silhouette edge, no matte fringe or halo.
Color palette: cool steel and shadows only in cool blue-grey to blue-black values such as #07101a, #121f2c, #1d3042, #2f4d69, #4175a0; keep body mostly mid-dark, like the Look 2 breaker, and keep steel chroma low. Saturated colour only on the named red gauge arc and only in its specified signal-red swatches. No warm grey, brown, rust, pink or magenta.
Materials/textures: matte, not glossy. Use flat value bands, not smooth gradients along metal. No grain, speckle, rust spots, scratches, tiny bolts, rivets or fine panel lines.
Composition/framing: straight side elevation, face toward viewer with no perspective tilt or vanishing point beyond preserving the target’s existing diagonal object orientation; keep the gauge centered, filling most of the frame with about 6% margin, while retaining the target framing.
Text (verbatim): none.
Constraints / avoid: exactly one object; no text, letters, numbers, labels, logos, warning words, UI, watermark, guide lines, borders, floor, ground plane, cast/contact shadow, reflection, steam, sparks, second object, glow outside the silhouette, magenta or pink. Keep the body opaque and the background actually transparent.
```

## Attempt 2 — raw/rejected-pickup-cracked-gauge-2.png

- Source: `[Codex generated-images store]/01a1284b-0d30-7573-bba4-53ff683e9794/exec-5406d37b-ae4a-4db3-81d9-03fb512605ce.png`
- Tool option: `transparent_background=not set`
- References:
  1. `[session scratch, not kept]/hq/props/raw/pickfix2/raw/pickup-cracked-gauge.png` — Image 1 — exact design/edit target; preserve silhouette, layout, function, tilt, framing, red arc, needle and hub.
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Image 2 — Look 2 rendering, values, edges and cool grading only; do not copy objects or figures.
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — Image 3 — mood, light and palette only; do not copy composition or figures.
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — Image 4 — colour swatches only.
- Verdict: Rejected: opaque checkerboard persisted; file is RGB with no alpha channel.

Verbatim prompt:

```text
Use case: precise-object-edit
Asset type: one 2D side-view sci-fi horror game pickup sprite, intended to shrink to about 110 px tall.
Input images, in order: Image 1 is the exact edit target; preserve its silhouette, layout, function, diagonal tilt, framing, red arc, needle and hub. Image 2 is the rendering/value/edge/cool-grading reference only; match the breaker and coolant relay style, and do not copy its objects or figures. Image 3 is mood, light and palette only; do not copy its composition or figures. Image 4 is colour swatches only.
Primary request: Precisely re-render the single gauge from Image 1 with the specified broad dark star-break, matte three-band cool-steel bezel and stem, and dim cool-grey face from the prior detailed edit prompt. Keep the same gauge design: same silhouette, framing, diagonal tilt, broad upper-right signal-red arc, and bold dark needle pointing past that arc toward 4–5 o’clock with its round hub. The cracks are 4–5 solid tapered dark cool wedges from one left-half impact point, broad near the impact and long enough to cross most of the face, with a small dark pit; no pale hairlines or fine shards. Keep the specified matte steel values (#626c76, #7b8590, #949faa) and broad cyan-white top bezel rim (#c3c5d7 to #82c3e6). Face is #a2acb8, slightly lighter #b0b9c4 above, with a #7b8590 inner-edge band. Use the Look 2 graphic-painterly flat planes, cool dark grading, cold overhead light, low-chroma steel, clean silhouette, and no dark outline. No extra texture, gloss, hotspots, scratches, speckles, rust, tiny bolts, text, letters, numbers, logo, shadow, reflection, floor, or second object.
TRANSPARENCY CORRECTION: The previous candidate visibly rendered a checkerboard pattern as opaque pixels. This output must instead have a genuinely transparent alpha channel across the entire background. Do not draw any checkerboard, transparency grid, black, white, magenta, or other background color. The gauge body itself is fully opaque and has clean antialiased edges; no halo or matte fringe.
Composition: straight side elevation facing the viewer, preserving the target’s existing diagonal object orientation, filling most of the frame with about 6% margin.
Avoid: colored/opaque background, checkerboard pattern, floor, cast/contact shadow, reflection, external glow, steam, sparks, second object, text or logos, warm grey, brown, pink or magenta.
```

## Attempt 3 — raw/pickup-cracked-gauge.png

- Source: `[Codex generated-images store]/01a1284b-0d30-7573-bba4-53ff683e9794/exec-16767718-d3c7-48a8-9191-7e3525cdce0d.png`
- Tool option: `transparent_background=true`
- References:
  1. `[session scratch, not kept]/hq/props/raw/pickfix2/raw/pickup-cracked-gauge.png` — Image 1 — exact design/edit target; preserve silhouette, layout, function, tilt, framing, red arc, needle and hub.
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Image 2 — Look 2 rendering, values, edges and cool grading only; do not copy objects or figures.
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — Image 3 — mood, light and palette only; do not copy composition or figures.
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — Image 4 — colour swatches only.
- Verdict: Kept: genuine RGBA alpha with transparent background; crack star, red arc and needle are preserved. Minor stray pixels/edge alpha are retained as instructed.

Verbatim prompt:

```text
Use case: precise-object-edit
Asset type: one 2D sci-fi horror game pickup sprite.
Input images, in exact order: Image 1 is the edit target; preserve its gauge silhouette, layout, diagonal tilt, red arc, dark needle and hub. Image 2 supplies only the Look 2 breaker/relay rendering, value structure and cool grading. Image 3 supplies only mood, light and palette. Image 4 supplies colour swatches only. Do not copy objects or figures from Images 2–3.
Primary request: Edit only the target gauge. Keep its silhouette, framing, proportions, diagonal orientation, broad upper-right red arc (#a01e29 / #ad252d), and bold dark needle pointing past the red zone toward 4–5 o’clock with round hub. Replace pale cracks with 4–5 solid tapered dark cool wedges (#4a5666 cores, #6f8396 edges) radiating from one impact point on the left half of the face. Each wedge must be at least 1/12 of face diameter wide near the impact, extend across most of the face, and remain clearly readable as a small icon; add a small dark chipped pit. No hairlines, fine shards, or pale/white crack marks. Render bezel and threaded stem as matte cool steel, never chrome or polished: exactly three flat bands, lower shadow #626c76, mid #7b8590, upper lit #949faa, plus a broad cyan-white top rim #c3c5d7 to #82c3e6 along the bezel’s top edge. Face is dim cool grey #a2acb8, slightly lighter #b0b9c4 on its upper part, with a #7b8590 band just inside the bezel; face remains the object’s lightest plane.
Style: Look 2 graphic-painterly, shape-first large flat planes, 3–4 value steps per material, minimal texture, crisp designed silhouette, cold overhead light, broad cyan-white top/back rim, cool blue-grey/blue-black steel with low chroma and dark body values. No dark outline, glossy sheen, mirror reflection, hotspots, gradients along metal, grain, speckles, rust, scratches, tiny bolts/rivets, or fine lines.
Composition: straight side elevation facing the viewer, with only the existing diagonal object orientation; preserve target framing and fill most of frame.
Background requirement: produce a real PNG RGBA alpha channel. Every pixel outside the gauge silhouette is fully transparent. Do not draw checkerboard squares, a transparency grid, a black/white/magenta/colored background, or any other backdrop. The body is opaque with clean antialiased edges, no halo or matte fringe.
Avoid text, letters, numbers, labels, logos, watermark, warning words, UI, guide lines, borders, floor, ground plane, cast/contact shadow, reflection, external glow, steam, sparks, second object, warm grey, brown, pink or magenta.
```

