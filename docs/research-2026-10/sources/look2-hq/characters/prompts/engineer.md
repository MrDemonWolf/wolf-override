LOGFILE = engineer-log.md. Three poses, generated in this order. Pose 1 becomes the identity reference for poses 2 and 3.

=== POSE 1: engineer-side-idle ===
References for pose 1, in order:
- Image 1 = CHARDIR/refs/ref-identity-engineer.png (identity: left = original approved design sprite, right = approved Look 2 render of the same character)
- Image 2 = CHARDIR/refs/ref-style-test-v2.png (rendering and edge treatment: the approved Look 2 style test)
- Image 3 = apps/game/assets/title-corridor-key-art-provisional.png (mood, light and palette)
- Image 4 = CHARDIR/refs/palette-card.png (colour swatches)

IMAGE PROMPT (pose 1):
~~~text
USE CASE: stylized-concept, new asset from identity references (Look 2 re-render of an approved design; do not redesign)
ASSET: canonical identity cut-out of the WOLF//OVERRIDE engineer, a 2D side-view sci-fi horror game; clean graphic-painterly game art readable at small size.
OUTPUT: one portrait PNG with a genuinely transparent background (real alpha). The full figure fills about 85% of the canvas height, centred, with a clear margin above the hair and below the boots. Final game size will be exactly 280 px tall after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = identity: match the character in both panels exactly (face, hair, costume, proportions). The right panel shows the approved Look 2 rendering of this same character; follow it most closely.
Image 2 = the approved Look 2 style test: copy its rendering, value structure and edge treatment only (flat planes, broad rim, cool grade). Do not copy its composition, background or props.
Image 3 = mood, lighting and palette only (cold blue-black, cyan rim, red jacket); do not copy its composition or figures.
Image 4 = colour swatches only; saturated colour must come from these swatches.
SUBJECT: exactly one engineer in a strict orthographic side profile facing screen-right, quiet idle stance: head, chest, hips and boots all point right; one eye in profile; near arm relaxed at the side, far arm mostly hidden behind the body; both boots flat on one level baseline, near leg slightly in front. Exactly two arms and two legs.
IDENTITY LOCKS: short tousled brown hair, hood down; deep-red hooded field jacket (lit #a01e29, shadow #5f0e17) with a chest pocket flap; black shoulder harness straps and black utility belt; one small cyan equipment light on the belt (the only cyan object); black gloves; charcoal cargo trousers with a thigh pocket and dark knee straps; dark boots. No yellow patches, no silver or shiny knee armour, no helmet, hood not up.
LOOK 2 STYLE: shape-first graphic painting. Flat value planes with 3-4 value steps per material; 6-8 large readable value shapes for the whole figure; minimal texture; crisp, shape-designed silhouette; broad rim shapes; painterly soft blending only inside the lit top planes. No dark outline or inked contour anywhere, on the silhouette or inside it: separate forms with adjacent flat values and broad light shapes. No grain, speckle, fabric microtexture, scratches or tiny details (nothing smaller than 6 px at the final 280 px height).
LIGHTING: cold overhead top light, so top-facing planes (hair top, shoulders, tops of arms and boots) are clearly lighter than the body core; a broad cyan-white rim (#82c3e6 to #c3c5d7) along the top and back edges, about 2-3% of the figure height wide, kept fairly even so the sprite can be mirrored. Shadows cool blue-black (#07101a, #121f2c), never brown or neutral grey. Trousers, gloves and boots are graded cool blue-charcoal so the figure sits inside a dark blue corridor.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo or glow outside the silhouette.
DO NOT: floor, ground plane, cast or contact shadow, reflection, background, extra figure, extra or missing limbs, three-quarter or frontal pose, motion lines, magenta or pink, text.
~~~

=== POSE 2: engineer-side-stride ===
References for pose 2, in order:
- Image 1 = the SELECTED pose-1 file in CHARDIR/raw/ (the new Look 2 identity)
- Image 2 = CHARDIR/refs/ref-identity-engineer.png
- Image 3 = CHARDIR/refs/ref-style-test-v2.png
- Image 4 = apps/game/assets/title-corridor-key-art-provisional.png
- Image 5 = CHARDIR/refs/palette-card.png

IMAGE PROMPT (pose 2):
~~~text
USE CASE: stylized-concept, identity-preserving new pose (do not redesign)
ASSET: identity cut-out of the WOLF//OVERRIDE engineer walking, Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one portrait PNG with a genuinely transparent background (real alpha). The full figure fills about 85% of the canvas height, centred, with a clear margin on every side. Final game size will be exactly 280 px tall after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same engineer, same face, hair, costume, colours, proportions, rendering and lighting. Change only the pose.
Image 2 = design source (original sprite left, approved Look 2 render right); use for costume details only.
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: exactly one engineer in a strict orthographic side profile facing screen-right, mid-stride in a calm walk (the contact pose): front leg reaching forward with the heel touching the ground, back leg extended behind with the toe pushing off, both boots touching the same level baseline; arms swing opposite to the legs (near arm back, far arm forward and partly hidden); torso upright, head level, looking right. Exactly two arms and two legs; far-side limbs one value step darker than near-side limbs.
IDENTITY LOCKS: short tousled brown hair, hood down; deep-red hooded field jacket (lit #a01e29, shadow #5f0e17); black shoulder harness straps and utility belt; one small cyan belt equipment light; black gloves; charcoal cargo trousers with thigh pocket and dark knee straps; dark boots. No yellow patches, no silver knee armour.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, 6-8 large value shapes, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top-facing planes lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) on the top and back edges; cool blue-black shadows, never brown or grey.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, motion lines, extra figure, extra or missing limbs, three-quarter pose, magenta or pink, text.
~~~

=== POSE 3: engineer-three-quarter ===
References for pose 3: same five references and order as pose 2.

IMAGE PROMPT (pose 3):
~~~text
USE CASE: stylized-concept, identity-preserving new view (do not redesign)
ASSET: three-quarter identity view of the WOLF//OVERRIDE engineer, Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one portrait PNG with a genuinely transparent background (real alpha). The full figure fills about 85% of the canvas height, centred, with a clear margin on every side. Final game size will be exactly 280 px tall after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same engineer, same face, hair, costume, colours, proportions, rendering and lighting. Change only the viewing angle.
Image 2 = design source (original sprite left, approved Look 2 render right); its left panel shows the costume from a near three-quarter angle; use it for costume details.
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: exactly one engineer in a front three-quarter view: body turned about 45 degrees toward the viewer while facing screen-right, quiet idle stance, eye level, no perspective distortion. Face visible in three-quarter; both arms relaxed at the sides; both boots flat on one level baseline. The jacket front, harness straps, belt and the small cyan belt light are visible. Exactly two arms and two legs.
IDENTITY LOCKS: short tousled brown hair, hood down; deep-red hooded field jacket (lit #a01e29, shadow #5f0e17); black shoulder harness straps and utility belt; one small cyan belt equipment light; black gloves; charcoal cargo trousers with thigh pocket and dark knee straps; dark boots. No yellow patches, no silver knee armour.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, 6-8 large value shapes, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top-facing planes lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) on the top and back edges; cool blue-black shadows, never brown or grey.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, extra figure, extra or missing limbs, strict side profile, frontal pose, magenta or pink, text.
~~~
