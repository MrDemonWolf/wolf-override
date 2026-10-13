# Image generation log

## `valve-gauge.png`

- Kept output: `raw/valve-gauge.png`
- Source: `[Codex generated-images store]/01a128a9-bf6b-79f0-ac2e-c9de7a2583a6/exec-9734c0bd-15ee-44dd-875f-507c90545a6c.png`
- Attempt: 1 (kept; no retry)
- References, in order:
  1. `[session scratch, not kept]/hq/props/raw/valve2/raw/valve-gauge.png` — Image 1, edit target; preserve the gauge design and change only the red zone.
  2. `[session scratch, not kept]/hq/props/refs/ref-look2-board.png` — Image 2, Look 2 rendering, value structure, edge treatment and cool grading only.
  3. `apps/game/assets/title-corridor-key-art-provisional.png` — Image 3, mood, light and palette only.
  4. `[session scratch, not kept]/hq/props/refs/palette-card.png` — Image 4, colour swatches only.
  5. `docs/research-2026-10/sources/look2-hq/props/junction-valve.png` — Image 5, valve body context only; do not add or redraw its parts.
- Verdict: Kept; the upper-right red arc is broad and inside the off-white face, with no text or added objects and transparent pixels outside the gauge.

### Verbatim prompt

```text
Use case: precise-object-edit
Asset type: one separate face-on circular 2D game sprite, the Service Junction valve gauge face for a side-view sci-fi horror game.
Input images, in order:
Image 1 is the edit target: preserve its circle, bezel, face layout, framing and existing design.
Image 2 is the approved Look 2 board: use only its graphic-painterly rendering, value structure, edge treatment and cool grading; do not copy any board objects.
Image 3 is mood, light and palette reference only; do not copy its composition or figures.
Image 4 is colour swatches only.
Image 5 is the valve body where this separate gauge face sits; context only, do not add or redraw any valve-body parts.
Primary request: make a precise edit to Image 1, changing ONLY the red zone. Replace the thin red sliver at the far edge with a broad red arc band on the UPPER RIGHT of the off-white gauge face. The band’s radial thickness is about one quarter of the face radius. Keep the entire band inside the off-white face: its outer edge sits a little inside the face’s outer edge and never touches the steel bezel. Sweep about 80 degrees, clockwise from roughly 12:30 to roughly 3 o’clock. Use signal red #a01e29 with a subtle lit edge in #ad252d. Tick bars that cross the red band may remain as short dark bars over it or be removed.
Keep everything else exactly as in Image 1: cool off-white face #c3c5d7, every other broad dark tick bar, dark centre pivot cap, steel bezel rings, exact face-on circle, centring and framing. Keep the gauge as one isolated sprite, about 6% clear margin around it. Ask for and preserve a genuinely transparent RGBA background; all pixels outside the gauge are transparent. Do not substitute any background.
Style: approved Look 2 graphic-painterly rendering with shape-first large flat value planes, 3–4 value steps per material, crisp designed silhouette, matte surfaces, cool blue-grey/blue-black steel and shadows, cold overhead top light and a broad cyan-white rim on the top/back edges. Low steel chroma; body values mostly #121f2c to #2f4d69. No dark ink outline. No grain, speckle, scratches, tiny bolts/rivets, fine panel lines, glossy/specular highlights, chrome/plastic sheen, or smooth gradients on metal. Keep saturated colour only on the named red accent.
No needle. No text, letters, numbers, logos, labels, UI, watermark, guide lines, border, floor, ground plane, cast/contact shadow, reflection, external glow, steam, sparks, second object, magenta or pink.
```
