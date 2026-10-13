# Service Junction valve image-generation log

All calls used the built-in image_gen tool with `transparent_background: true`. The three raw PNG copies were SHA-256 checked against their generated source files and retain alpha. No magenta fallback was needed.

## Attempt 1 — `raw/rejected-valve-master-1.png`

- Source path: `[Codex generated-images store]/01a12820-563a-7dc2-a375-12a6c3c38dab/exec-2d65b052-3823-4432-a466-1b792835599a.png`
- Reference paths and roles:
  - Image 1 — job design reference; preserve silhouette, layout, function and colour coding: `apps/game/assets/props/junction-valve.png`
  - Image 2 — Look 2 rendering, value structure, edge treatment and cool grading only; do not copy objects or figures: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png`
  - Image 3 — mood, light and palette only; do not copy composition or figures: `apps/game/assets/title-corridor-key-art-provisional.png`
  - Image 4 — colour swatches only: `[session scratch, not kept]/hq/props/refs/palette-card.png`
- Verdict: Rejected: visible micro-fasteners, cyan fringe outside the silhouette and contour-like dark edging. PNG alpha is present; retried.

Verbatim prompt:

```text
Create a clean game-ready 2D side-view sci-fi horror prop asset with a GENUINELY TRANSPARENT RGBA background; keep the generated alpha. Shared approved style Look 2, graphic-painterly: shape-first graphic painting, large flat value planes, 3-4 value steps per material, minimal texture, crisp shape-designed silhouette; painterly soft transitions only inside light pools and glows; no grain, speckle, rust spots, scratches, tiny bolts or rivets, or fine panel lines (use one broad panel line where the old design had three). Cold overhead top light, upward-facing surfaces clearly lighter than the body, plus a BROAD cyan-white rim (#82c3e6 to #c3c5d7) on top and back edges. NO dark outline or ink contour anywhere; define edges with value and rim light; fully opaque object body; clean 1-2 px anti-aliased silhouette edge, no matte fringe or halo. Cool grading: steel and shadows are cool blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty; body mostly mid-dark to sit within dark corridor values. Saturated colour ONLY on the named accents, using these swatches: signal red #a01e29 / #ad252d, red glow #ca452f, amber glow #e0936e, amber metal #82510e, dim amber #6e4824, cyan strip #30d0fc, cyan keypad #2091ca, cyan seam #4f8ab8, safe green #56dc69 / #228237 / #17632f. Straight side elevation, front face toward viewer, no perspective tilt or vanishing point. Center the object with about 6% margin on each side and fill most of the frame. Absolutely no text, letters, numbers, labels, logos, warning words, UI, watermark, guide lines, borders, floor, ground plane, cast/contact shadow, reflection, glow outside the silhouette, steam, sparks, second object, magenta or pink.

Image roles: Image 1 is the valve design reference; preserve its silhouette, layout, function and colour coding, re-rendering it in this style. Image 2 is rendering/value structure/edge treatment/cool grading reference only; match the breaker and coolant relay rendering but copy no objects or figures. Image 3 is mood, light and palette reference only; copy no composition or figures. Image 4 is colour swatches only.

Subject: Service Junction valve master. Re-render the design as one central valve body on a squat stand with exactly two legs and a base plate; large elbow pipes leave left and right and turn down to flanged ends; a big front handwheel with a round rim, five spokes and central hub; a round pressure gauge on a short stem on top; a small riser pipe on the right with a narrow amber sight glass. Keep the design reference silhouette and layout. Use amber as the sole accent hue: handwheel in amber metal (#82510e lit to #6e4824 shadow), worn but flat-shaded with no rust texture; sight glass has a dim amber glow (#e0936e); one broad diagonal hazard band on each stand leg, alternating amber metal (#82510e) and dark steel. Gauge face is plain cool off-white (#c3c5d7), empty with no needle, no ticks and no numbers. All other metal is cool dark blue-grey. One object only, completely isolated by genuine transparency.
```

## Attempt 2 — `raw/rejected-valve-master-2.png`

- Source path: `[Codex generated-images store]/01a12820-563a-7dc2-a375-12a6c3c38dab/exec-84adbb63-c619-4727-9448-09ef2984c716.png`
- Reference paths and roles:
  - Image 1 — job design reference; preserve silhouette, layout, function and colour coding: `apps/game/assets/props/junction-valve.png`
  - Image 2 — Look 2 rendering, value structure, edge treatment and cool grading only; do not copy objects or figures: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png`
  - Image 3 — mood, light and palette only; do not copy composition or figures: `apps/game/assets/title-corridor-key-art-provisional.png`
  - Image 4 — colour swatches only: `[session scratch, not kept]/hq/props/refs/palette-card.png`
- Verdict: Rejected: micro-detail was reduced, but cyan fringe and contour-like edging remained. PNG alpha is present; retried.

Verbatim prompt:

```text
Create a clean game-ready 2D side-view sci-fi horror prop asset with a GENUINELY TRANSPARENT RGBA background; keep the generated alpha. Shared approved style Look 2, graphic-painterly: shape-first graphic painting, large flat value planes, 3-4 value steps per material, minimal texture, crisp shape-designed silhouette; painterly soft transitions only inside light pools and glows; no grain, speckle, rust spots, scratches, tiny bolts or rivets, or fine panel lines (use one broad panel line where the old design had three). Cold overhead top light, upward-facing surfaces clearly lighter than the body, plus a BROAD cyan-white rim (#82c3e6 to #c3c5d7) on top and back edges. NO dark outline or ink contour anywhere; define edges with value and rim light; fully opaque object body; clean 1-2 px anti-aliased silhouette edge, no matte fringe or halo. Cool grading: steel and shadows are cool blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty; body mostly mid-dark to sit within dark corridor values. Saturated colour ONLY on the named accents, using these swatches: signal red #a01e29 / #ad252d, red glow #ca452f, amber glow #e0936e, amber metal #82510e, dim amber #6e4824, cyan strip #30d0fc, cyan keypad #2091ca, cyan seam #4f8ab8, safe green #56dc69 / #228237 / #17632f. Straight side elevation, front face toward viewer, no perspective tilt or vanishing point. Center the object with about 6% margin on each side and fill most of the frame. Absolutely no text, letters, numbers, labels, logos, warning words, UI, watermark, guide lines, borders, floor, ground plane, cast/contact shadow, reflection, glow outside the silhouette, steam, sparks, second object, magenta or pink.

Image roles: Image 1 is the valve design reference; preserve its silhouette, layout, function and colour coding, re-rendering it in this style. Image 2 is rendering/value structure/edge treatment/cool grading reference only; match the breaker and coolant relay rendering but copy no objects or figures. Image 3 is mood, light and palette reference only; copy no composition or figures. Image 4 is colour swatches only.

Subject: Service Junction valve master. Re-render the design as one central valve body on a squat stand with exactly two legs and a base plate; large elbow pipes leave left and right and turn down to flanged ends; a big front handwheel with a round rim, five spokes and central hub; a round pressure gauge on a short stem on top; a small riser pipe on the right with a narrow amber sight glass. Keep the design reference silhouette and layout. Use amber as the sole accent hue: handwheel in amber metal (#82510e lit to #6e4824 shadow), worn but flat-shaded with no rust texture; sight glass has a dim amber glow (#e0936e); one broad diagonal hazard band on each stand leg, alternating amber metal (#82510e) and dark steel. Gauge face is plain cool off-white (#c3c5d7), empty with no needle, no ticks and no numbers. All other metal is cool dark blue-grey. One object only, completely isolated by genuine transparency.

Targeted correction for this retry: eliminate all tiny fasteners, screws and dark contour strokes; render structure using only broad value planes, and keep the cyan-white rim strictly on the silhouette with no color fringe outside the transparent alpha. Preserve the valve silhouette, position and every required component.
```

## Attempt 3 — `raw/rejected-valve-master-3.png`

- Source path: `[Codex generated-images store]/01a12820-563a-7dc2-a375-12a6c3c38dab/exec-bcfe2747-f023-491e-ad06-bf9dc046cea5.png`
- Reference paths and roles:
  - Image 1 — job design reference; preserve silhouette, layout, function and colour coding: `apps/game/assets/props/junction-valve.png`
  - Image 2 — Look 2 rendering, value structure, edge treatment and cool grading only; do not copy objects or figures: `[session scratch, not kept]/hq/props/refs/ref-look2-board.png`
  - Image 3 — mood, light and palette only; do not copy composition or figures: `apps/game/assets/title-corridor-key-art-provisional.png`
  - Image 4 — colour swatches only: `[session scratch, not kept]/hq/props/refs/palette-card.png`
- Verdict: Rejected: visible cyan fringe outside the silhouette and contour-like edging remain after the final retry. PNG alpha is present. No master was kept.

Verbatim prompt:

```text
Create a clean game-ready 2D side-view sci-fi horror prop asset with a GENUINELY TRANSPARENT RGBA background; keep the generated alpha. Shared approved style Look 2, graphic-painterly: shape-first graphic painting, large flat value planes, 3-4 value steps per material, minimal texture, crisp shape-designed silhouette; painterly soft transitions only inside light pools and glows; no grain, speckle, rust spots, scratches, tiny bolts or rivets, or fine panel lines (use one broad panel line where the old design had three). Cold overhead top light, upward-facing surfaces clearly lighter than the body, plus a BROAD cyan-white rim (#82c3e6 to #c3c5d7) on top and back edges. NO dark outline or ink contour anywhere; define edges with value and rim light; fully opaque object body; clean 1-2 px anti-aliased silhouette edge, no matte fringe or halo. Cool grading: steel and shadows are cool blue-grey to blue-black (#07101a, #121f2c, #1d3042, #2f4d69, #4175a0), never warm grey, brown or rusty; body mostly mid-dark to sit within dark corridor values. Saturated colour ONLY on the named accents, using these swatches: signal red #a01e29 / #ad252d, red glow #ca452f, amber glow #e0936e, amber metal #82510e, dim amber #6e4824, cyan strip #30d0fc, cyan keypad #2091ca, cyan seam #4f8ab8, safe green #56dc69 / #228237 / #17632f. Straight side elevation, front face toward viewer, no perspective tilt or vanishing point. Center the object with about 6% margin on each side and fill most of the frame. Absolutely no text, letters, numbers, labels, logos, warning words, UI, watermark, guide lines, borders, floor, ground plane, cast/contact shadow, reflection, glow outside the silhouette, steam, sparks, second object, magenta or pink.

Image roles: Image 1 is the valve design reference; preserve its silhouette, layout, function and colour coding, re-rendering it in this style. Image 2 is rendering/value structure/edge treatment/cool grading reference only; match the breaker and coolant relay rendering but copy no objects or figures. Image 3 is mood, light and palette reference only; copy no composition or figures. Image 4 is colour swatches only.

Subject: Service Junction valve master. Re-render the design as one central valve body on a squat stand with exactly two legs and a base plate; large elbow pipes leave left and right and turn down to flanged ends; a big front handwheel with a round rim, five spokes and central hub; a round pressure gauge on a short stem on top; a small riser pipe on the right with a narrow amber sight glass. Keep the design reference silhouette and layout. Use amber as the sole accent hue: handwheel in amber metal (#82510e lit to #6e4824 shadow), worn but flat-shaded with no rust texture; sight glass has a dim amber glow (#e0936e); one broad diagonal hazard band on each stand leg, alternating amber metal (#82510e) and dark steel. Gauge face is plain cool off-white (#c3c5d7), empty with no needle, no ticks and no numbers. All other metal is cool dark blue-grey. One object only, completely isolated by genuine transparency.

Targeted correction for this final retry: remove all outline strokes and exterior cyan fringe; keep the broad cyan-white light as a painted band entirely inside the opaque object's top and back edge, with a crisp clean alpha boundary. Preserve the valve silhouette, position and every required component.
```

## Pipeline status

No master met the stated acceptance checks after the two allowed retries. The body, wheel, gauge and needle calls were not made because each depends on a kept master image.


