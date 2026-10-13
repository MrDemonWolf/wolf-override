# Image generation record

## pickup-cracked-gauge.png

Output file: pickup-cracked-gauge.png
Source path: [Codex generated-images store]/01a128a9-b5c6-7fa2-9dbb-4337fbd93b69/exec-426d4ce7-ee76-42fd-888b-82fc8c15803c.png

References, in the order supplied:
1. [session scratch, not kept]/hq/props/raw/pickfix3/raw/pickup-cracked-gauge.png — edit target; preserve its gauge design, cracks, layout, color coding, stem attachment, and framing.
2. [session scratch, not kept]/hq/props/refs/ref-look2-board.png — Look 2 rendering, value structure, edge treatment, and cool grading only.
3. apps/game/assets/title-corridor-key-art-provisional.png — mood, light, and palette only.
4. [session scratch, not kept]/hq/props/refs/palette-card.png — colour swatches only.
5. docs/research-2026-10/sources/look2-hq/props/junction-valve.png — same-room matte, low-chroma steel values.

Verdict: Kept; the cracked gauge design and red arc remain intact, the values are darker and matte, the background has alpha, and there is no text, floor, second object, or coloured backdrop; small edge specks are within the stated tolerance.

Verbatim prompt:
```text
Use case: precise-object-edit.
Asset type: one transparent 2D side-view sci-fi horror game pickup sprite, the cracked gauge evidence item, used at only 24–30 world pixels tall in a dark room.
Primary request: edit Image 1 with a value and material correction only. Darken and matte the existing gauge so it sits inside the dark room values. Preserve its exact design, gauge silhouette and proportions, round face and bezel layout, impact location, broad red arc, needle and hub, threaded stem, diagonal stem attachment, framing, and transparent canvas. Do not redesign, add, remove, move, or rotate any part.
Input images, in exact order: Image 1 is the edit target; keep its silhouette, layout, function, color coding, diagonal stem attachment, and framing. Image 2 is the Look 2 board; use only its graphic-painterly rendering, value structure, edge treatment, and cool grading, matching the breaker and coolant relay, not its objects or figures. Image 3 is keyart mood, light, and palette only; do not copy composition or figures. Image 4 is colour swatches only. Image 5 is the finished junction valve from this same room; match its matte, low-chroma steel values.
Scene/backdrop: genuinely transparent RGBA with the generated alpha preserved. No visible background, floor, deck, ground plane, cast or contact shadow, reflection, environment, border, guide line, or glow outside the object silhouette. Keep the body fully opaque.
Style/medium: Look 2, shape-first graphic painting with large flat value planes, 3–4 value steps per material, minimal texture, and a crisp shape-designed silhouette. Use painterly soft transitions only inside light pools or glows. Matte, never glossy: no specular hotspots, chrome, polished metal, mirror reflections, plastic sheen, or smooth gradients along the stem. Steel and shadows stay cool blue-grey to blue-black, never warm grey, brown, or rusty. The body remains mostly mid-dark like the Look 2 breaker, with most body values between #121f2c and #2f4d69; keep steel chroma low.
Lighting: cold overhead top light, with upward-facing parts lighter than the body. Use a broad cyan-white rim from #82c3e6 to #c3c5d7 on the top/back silhouette edges, restricted on this gauge to the top edge of the bezel only. No dark outline or ink contour; edges come from value and rim light. Clean 1–2 px antialiased silhouette, no matte fringe or halo.
Exact face correction: matte dim cool grey, clearly darker than the current face. Use #8a94a1 over most of the face, slightly lighter #97a1ae in the upper part reached by top light, and a shaded band #64707e just inside the bezel. No white or near-white anywhere on the face. Keep the four or five broad star-break wedges radiating from the same single impact point on the left half, plus the small chipped pit. Make cracks darker so they remain distinct on the darker face: #2c3846 cores and #435265 edges. Each wedge is a solid tapered shape at least one tenth of the face diameter wide near the impact point. No hairlines, fine shards, or pale crack lines.
Exact metal correction: bezel and threaded stem are matte, low-chroma cool steel like Image 5, with exactly three flat bands: lower outer shadow #34414f, mid #4c5b6c, upper lit #66788c. Add the broad cyan-white rim only along the top edge of the bezel.
Keep the broad red zone arc on the upper right exactly in place and shape, using only #a01e29 and #ad252d. Keep the bold dark needle #121f2c pointing past the red zone toward 4–5 o’clock, with its existing round hub.
Composition: straight side-elevation, gauge face toward the viewer, no perspective tilt or vanishing point; retain the existing design’s diagonal threaded stem attachment. Keep the object centered with about 6% margin on every side, filling most of the frame.
Use only the named saturated accents: signal red #a01e29 / #ad252d, red glow #ca452f, amber glow #e0936e, amber metal #82510e, dim amber #6e4824, cyan strip #30d0fc, cyan keypad #2091ca, cyan seam #4f8ab8, safe green #56dc69 / #228237 / #17632f. Do not add any other saturated accent. Do not add grain, speckle, rust spots, scratches, tiny bolts, rivets, or fine panel lines; retain at most one broad panel line if one exists in the original.
Avoid: any text, letters, numbers, labels, logos, warning signs with words, UI, watermark, dark outline, floor or ground plane, cast/contact shadow, reflection, external glow, steam, sparks, second object, magenta or pink, or any white/near-white on the face.
```

## Correction by the orchestrating agent (2026-10-10)

This job ran in parallel with `wheelfix2` and `gaugefix`. Codex copied the newest file under `generated_images/` instead of its own output, so the file it saved as `raw/pickup-cracked-gauge.png` was really `wheelfix2` attempt 1 (`01a128a9-b5c6-.../exec-426d4ce7-....png`). That file was renamed `raw/misfiled-copy-of-wheelfix2-attempt-1.png`. This job's real `image_gen` output is the only file in its own session folder, `[Codex generated-images store]/01a128a9-c6e2-7110-b753-cb80330515de/exec-1be34599-823a-4c96-8154-15f311ce7e10.png`. It was copied byte-for-byte to `raw/pickup-cracked-gauge.png`. The prompt and references above apply to it.
