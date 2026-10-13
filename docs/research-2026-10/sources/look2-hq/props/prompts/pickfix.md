# Image generation record

Built-in imagegen edit mode; transparent output requested and preserved.

## pickup-cracked-gauge.png

- Output file: `raw/pickup-cracked-gauge.png`
- Source: `[Codex generated-images store]/01a12834-8f22-7483-a380-0d391a56c8f6/exec-1efb4c5e-8b5f-4717-b152-abf2224f9eb9.png`
- References, in call order:
  1. `[session scratch, not kept]/hq/props/refs/cracked-gauge-attempt-2.png` — Image 1, edit target; preserve the gauge design and alter only the needle.
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Image 2, rendering/value/edge-treatment/cool-grading reference only.
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — Image 3, mood/light/palette reference only.
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — Image 4, color swatches only.
- Attempt 1 verdict: Kept; needle points down-right past the red zone at about 4:30, no forbidden content, and alpha ranges from transparent to opaque.
- Verbatim prompt sent:

```text
Use case: precise-object-edit
Asset type: transparent 2D side-view sci-fi horror game evidence pickup.
Input images, in order:
- Image 1, edit target: keep this cracked gauge's silhouette, layout, function, color coding, star-cracked glass, bezel, off-white face, red zone, threaded stem, tilt, framing, and transparent background.
- Image 2, rendering reference only: match the approved Look 2 graphic-painterly value structure, crisp edge treatment, and cool grading; do not copy its objects or figures.
- Image 3, mood/light/palette reference only; do not copy its composition or figures.
- Image 4, color swatches only.
Primary request: make exactly one change: replace/reposition only the needle so it points clearly clockwise past the red zone's clockwise end, down-right at about 4:30 (between 4 and 5 o'clock), so it reads as pressure running past red. Make it a bold, easy-to-read dark blue-black shape (#121f2c) with a round hub.
Preserve every other part of Image 1 exactly: the star-cracked glass, bezel, off-white face, red zone, threaded stem, tilt, framing, lighting, materials, and transparency. Do not redesign or repaint the rest of the gauge.
For the changed needle, follow Look 2: shape-first graphic painting, crisp silhouette, matte, and 3-4 flat value steps where needed; no grain, speckles, rust spots, scratches, fine panel lines, tiny bolts or rivets, glossy sheen, chrome, specular hot-spots, smooth pipe gradients, or dark ink outlines. Keep the gauge steel cool blue-grey to blue-black and low-chroma, never warm grey, brown, rusty, bright blue, or saturated blue. Keep the existing red zone unchanged; saturated color only on that named accent. Retain cold overhead top light and the broad cyan-white top/back rim (#82c3e6 to #c3c5d7) as already present, without changing other pixels. Keep the body opaque and the silhouette edge clean with 1-2 px antialiasing.
Composition and background: preserve the exact target framing and tilt; object remains centered and fills most of the canvas. Use a genuinely transparent RGBA background. No floor, ground plane, cast/contact shadow, reflection, glow outside the silhouette, steam, sparks, second object, magenta or pink, border, or guide lines.
No text, letters, numbers, labels, logos, warning signs with words, UI, or watermark.
```
