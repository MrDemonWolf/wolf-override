LOGFILE = wolf-log.md. Four poses, generated in this order. Pose 1 becomes the identity reference for poses 2, 3 and 4.

Shared blocks used inside every WOLF image prompt below (they are already written out in full in each prompt).

=== POSE 1: wolf-side-stand ===
References for pose 1, in order:
- Image 1 = CHARDIR/refs/ref-identity-wolf.png (identity: left = original approved design sprite, right = approved Look 2 render of WOLF)
- Image 2 = CHARDIR/refs/ref-style-test-v2.png (rendering and edges: the approved Look 2 style test)
- Image 3 = apps/game/assets/title-corridor-key-art-provisional.png (mood, light and palette)
- Image 4 = CHARDIR/refs/palette-card.png (colour swatches)

IMAGE PROMPT (pose 1):
~~~text
USE CASE: stylized-concept, new asset from identity references (Look 2 re-render of an approved design; do not redesign)
ASSET: canonical identity cut-out of WOLF, the robotic wolf companion in WOLF//OVERRIDE, a 2D side-view sci-fi horror game; clean graphic-painterly game art readable at small size.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha). WOLF fills about 88% of the canvas width, centred, fully inside the frame with a clear margin. Final game size will be exactly 460 px long nose-to-tail-tip after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = identity: match WOLF in both panels exactly (head shape, armour plate layout, joints, tail, proportions). The right panel is the approved Look 2 rendering; follow its rendering most closely and the left panel's head-forward profile.
Image 2 = the approved Look 2 style test: rendering, value structure and edge treatment only. Do not copy its composition, background or props.
Image 3 = mood, lighting and palette only (cold blue-black, cyan rim); do not copy its composition or figures.
Image 4 = colour swatches only.
SUBJECT: exactly one fully robotic wolf in a strict orthographic side view facing screen-right, standing still, head forward in profile looking right, ears up. Long, low canine silhouette: nose-to-tail length at least 1.85 times the ear-tip-to-paw height. All four paws flat on one level baseline, near and far legs slightly staggered so all four legs and four paws are countable.
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws; circular mechanical joints at shoulders, hips, elbows and hocks; grey-blue angular armour plates of low chroma (lit about #656a72, mid about #292f37); one articulated, segmented armoured tail; one cyan eye; restrained cyan seam lights (#4f8ab8 to #30d0fc) only on a few plate seams. Fully robotic: no fur, no organic anatomy, no harness, no collar.
LOOK 2 STYLE: shape-first graphic painting. Flat value planes with 3-4 value steps per material; large simplified armour plates; minimal texture; crisp shape-designed silhouette; broad rim shapes; painterly soft blending only inside the lit top planes. No dark outline or inked contour anywhere, on the silhouette or between plates: separate plates with adjacent flat values. No grain, speckle, scratches, tiny bolts or details smaller than 6 px at the final 460 px length.
LIGHTING: cold overhead top light, so the back, head top and top faces of plates are clearly lighter than the body core; a broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edge of the head, neck, back and tail, kept fairly even so the sprite can be mirrored. Shadows cool blue-black (#07101a, #121f2c), never brown or warm.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo or glow outside the silhouette.
DO NOT: floor, cast or contact shadow, reflection, background, extra ears, legs, paws or tails, fur, motion lines, magenta or pink, text.
~~~

=== POSE 2: wolf-side-lookback ===
References for poses 2, 3 and 4, in order:
- Image 1 = the SELECTED pose-1 file in CHARDIR/raw/ (the new Look 2 identity)
- Image 2 = CHARDIR/refs/ref-identity-wolf.png
- Image 3 = CHARDIR/refs/ref-style-test-v2.png
- Image 4 = apps/game/assets/title-corridor-key-art-provisional.png
- Image 5 = CHARDIR/refs/palette-card.png

IMAGE PROMPT (pose 2):
~~~text
USE CASE: stylized-concept, identity-preserving new pose (do not redesign)
ASSET: identity cut-out of WOLF, the robotic wolf companion in WOLF//OVERRIDE, looking back; Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha). WOLF fills about 88% of the canvas width, centred, fully inside the frame with a clear margin. Final game size will be exactly 460 px long after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same WOLF, same armour plates, joints, tail, colours, proportions, rendering and lighting. Change only the head and neck pose.
Image 2 = design source (original sprite left, approved Look 2 render right); its right panel shows a turned head.
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; its robotic wolf looks back over its shoulder toward the engineer: use that idea for the head turn only, not its composition.
Image 5 = colour swatches only.
SUBJECT: exactly one robotic wolf, body and legs in a strict side view facing screen-right, standing still on all four paws on one level baseline, with the neck bent and the head turned back over its shoulder so the muzzle points toward screen-left, looking behind itself; the cyan eye and both ears visible; the tail relaxed behind. Long, low silhouette as in Image 1.
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws, all countable; circular mechanical joints; grey-blue low-chroma angular armour plates; one articulated segmented armoured tail; one cyan eye; restrained cyan seam lights only on a few seams. No fur, no harness, no collar.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, large simplified plates, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches, tiny bolts or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top faces lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edges; cool blue-black shadows, never brown.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, extra ears, legs, paws or tails, fur, motion lines, magenta or pink, text.
~~~

=== POSE 3: wolf-side-walk ===
References: same five references and order as pose 2.

IMAGE PROMPT (pose 3):
~~~text
USE CASE: stylized-concept, identity-preserving new pose (do not redesign)
ASSET: identity cut-out of WOLF, the robotic wolf companion in WOLF//OVERRIDE, walking; Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha). WOLF fills about 88% of the canvas width, centred, fully inside the frame with a clear margin. Final game size will be exactly 460 px long after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same WOLF, same armour plates, joints, tail, colours, proportions, rendering and lighting. Change only the leg pose.
Image 2 = design source (original sprite left, approved Look 2 render right).
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: exactly one robotic wolf in a strict side view facing screen-right, mid-stride in a calm walk: near foreleg reaching forward, near hind leg extended back, far legs in the opposite phase; one paw lifted slightly, the other three paws touching one level baseline; back level, head forward in profile looking right, ears up, tail held straight out behind. All four legs and all four paws countable. Long, low silhouette as in Image 1.
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws; circular mechanical joints; grey-blue low-chroma angular armour plates; one articulated segmented armoured tail; one cyan eye; restrained cyan seam lights only on a few seams. No fur, no harness, no collar.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, large simplified plates, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches, tiny bolts or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top faces lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edges; cool blue-black shadows, never brown.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, extra ears, legs, paws or tails, fur, motion lines or blur, magenta or pink, text.
~~~

=== POSE 4: wolf-sit (scale lineup) ===
This one is a two-figure SCALE LINEUP on purpose: the standing WOLF on the left is only a scale reference that will be cropped away; the sitting WOLF on the right is the asset. References: same five references and order as pose 2.

IMAGE PROMPT (pose 4):
~~~text
USE CASE: stylized-concept, identity-preserving new pose shown in a same-scale lineup (do not redesign)
ASSET: scale lineup of WOLF, the robotic wolf companion in WOLF//OVERRIDE; Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one wide landscape PNG with a genuinely transparent background (real alpha), containing exactly two copies of the same WOLF at exactly the same scale, standing on one shared level baseline, separated by a clear empty gap of at least 8% of the canvas width. Both are fully inside the frame with a clear margin. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity and the exact scale reference: the same WOLF, same armour plates, joints, tail, colours, proportions, rendering and lighting.
Image 2 = design source (original sprite left, approved Look 2 render right).
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: LEFT = WOLF standing exactly as in Image 1, strict side view facing screen-right, all four paws on the baseline. RIGHT = the same WOLF at exactly the same scale, sitting upright in strict side view facing screen-right: haunches and hind legs folded on the floor, forelegs straight and vertical with both front paws on the baseline, chest up, head up in profile looking right, ears up, the segmented tail lying along the floor behind and curving forward. In the sitting WOLF, two ears, four legs and four paws remain countable (far legs partly hidden but visible).
DESIGN LOCKS: exactly 2 triangular ears; exactly 4 mechanical legs with exactly 4 paws; circular mechanical joints; grey-blue low-chroma angular armour plates; one articulated segmented armoured tail; one cyan eye; restrained cyan seam lights only on a few seams. No fur, no harness, no collar.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, large simplified plates, minimal texture, crisp shape-designed silhouettes, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches, tiny bolts.
LIGHTING: identical to Image 1: cold overhead top light, top faces lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) along the top edges; cool blue-black shadows, never brown.
TRANSPARENCY: fully opaque bodies; crisp 1-2 px anti-aliased edges; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, a third figure, overlapping figures, extra ears, legs, paws or tails, fur, magenta or pink, text.
~~~
For pose 4 the self-check must confirm: two figures, separated, same scale, right one sitting.
