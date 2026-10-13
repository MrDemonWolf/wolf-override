LOGFILE = director-log.md. Two poses, generated in this order. Pose 1 becomes the identity reference for pose 2.

=== POSE 1: director-stand-left ===
References for pose 1, in order:
- Image 1 = CHARDIR/refs/ref-identity-director.png (identity: LEFT panel = the approved Director design; the RIGHT panel is a different character, the engineer, shown only as an example of the approved Look 2 rendering of a human figure)
- Image 2 = CHARDIR/refs/ref-style-test-v2.png (rendering and edges: the approved Look 2 style test)
- Image 3 = apps/game/assets/title-corridor-key-art-provisional.png (mood, light and palette)
- Image 4 = CHARDIR/refs/palette-card.png (colour swatches)

IMAGE PROMPT (pose 1):
~~~text
USE CASE: stylized-concept, new asset from identity references (Look 2 re-render of an approved design; do not redesign)
ASSET: canonical identity cut-out of the Director, the human antagonist in WOLF//OVERRIDE, a 2D side-view sci-fi horror game; clean graphic-painterly game art readable at small size.
OUTPUT: one portrait PNG with a genuinely transparent background (real alpha). The full figure fills about 85% of the canvas height, centred, with a clear margin above the hair and below the boots. Final game size will be exactly 280 px tall after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = identity: the LEFT panel is the Director; match face, hair, coat, proportions and pose exactly. The RIGHT panel is a different character; use it only as an example of the Look 2 rendering of a human figure (flat planes, top light, cyan rim). Do not copy that character's clothes, colours or face.
Image 2 = the approved Look 2 style test: rendering, value structure and edge treatment only. Do not copy its composition, background or props.
Image 3 = mood, lighting and palette only (cold blue-black, cyan rim); do not copy its composition or figures.
Image 4 = colour swatches only.
SUBJECT: exactly one person, the Director, in a strict orthographic side profile facing screen-LEFT, standing still and upright, both hands in the coat pockets, stern expression, both boots flat on one level baseline. Exactly two arms and two legs.
IDENTITY LOCKS: swept-back short grey hair; stern older face with a strong brow; long dark charcoal-blue overcoat to below the knee with wide lapels and cuffed sleeves; dark turtleneck; a lanyard with a small ID badge carrying one small red mark (the only red, a tiny practical accent); dark trousers; black lace-up boots. Low chroma everywhere else.
LOOK 2 STYLE: shape-first graphic painting. Flat value planes with 3-4 value steps per material; 6-8 large readable value shapes for the whole figure; the long coat reads as two or three broad planes; minimal texture; crisp shape-designed silhouette; broad rim shapes; painterly soft blending only inside the lit top planes. No dark outline or inked contour anywhere, on the silhouette or inside it. No grain, speckle, fabric microtexture, scratches or details smaller than 6 px at the final 280 px height.
LIGHTING: cold overhead top light, so the hair, shoulders and top-facing coat planes are clearly lighter than the body core; a broad cyan-white rim (#82c3e6 to #c3c5d7) along the top and back edges (the back is screen-right here), kept fairly even so the sprite can be mirrored. Shadows cool blue-black (#07101a, #121f2c), never brown or neutral grey. The coat is graded cool so the figure sits inside a dark blue corridor while staying readable.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo or glow outside the silhouette.
DO NOT: floor, cast or contact shadow, reflection, background, extra figure, extra or missing limbs, facing right, frontal or three-quarter pose, readable text on the badge, magenta or pink, text.
~~~

=== POSE 2: director-turn-away ===
References for pose 2, in order:
- Image 1 = the SELECTED pose-1 file in CHARDIR/raw/ (the new Look 2 identity)
- Image 2 = CHARDIR/refs/ref-identity-director.png
- Image 3 = CHARDIR/refs/ref-style-test-v2.png
- Image 4 = apps/game/assets/title-corridor-key-art-provisional.png
- Image 5 = CHARDIR/refs/palette-card.png

IMAGE PROMPT (pose 2):
~~~text
USE CASE: stylized-concept, identity-preserving new pose (do not redesign)
ASSET: identity cut-out of the Director turning away, Look 2 graphic-painterly game art for a 2D side-view sci-fi horror game.
OUTPUT: one portrait PNG with a genuinely transparent background (real alpha). The full figure fills about 85% of the canvas height, centred, with a clear margin on every side. Final game size will be exactly 280 px tall after one downscale. No text, letters, numbers, logos, UI, watermark, guide lines or borders.
REFERENCE ROLES:
Image 1 = the canonical identity: the same Director, same hair, coat, colours, proportions, rendering and lighting. Change only the pose and viewing angle.
Image 2 = design source: LEFT panel is the Director; the RIGHT panel is a different character shown only as a rendering example. Do not copy the right panel's clothes or colours.
Image 3 = the approved Look 2 style test: rendering, value structure and edges only; ignore its composition and props.
Image 4 = mood, lighting and palette only; do not copy its composition or figures.
Image 5 = colour swatches only.
SUBJECT: exactly one person, the Director, caught mid-turn while turning away from the viewer: previously facing screen-left, now rotating toward the back wall, seen in a rear three-quarter view. The back and one shoulder of the long coat dominate the silhouette; the head is turned away so only the ear, the edge of the jaw and the back of the grey hair are visible, no face. Hands stay in the coat pockets; the coat hem swings slightly with the turn; both boots on one level baseline, one heel lifting as the weight shifts. Exactly two arms and two legs.
IDENTITY LOCKS: swept-back short grey hair; long dark charcoal-blue overcoat to below the knee with wide lapels and cuffed sleeves; dark turtleneck collar; dark trousers; black lace-up boots. The badge may be hidden. Low chroma everywhere.
LOOK 2 STYLE: identical to Image 1: flat value planes with 3-4 value steps per material, 6-8 large value shapes, the coat as two or three broad planes, minimal texture, crisp shape-designed silhouette, broad rim shapes, painterly only inside the lit top planes. No dark outline or inked contour anywhere. No grain, speckle, scratches or details smaller than 6 px at the final size.
LIGHTING: identical to Image 1: cold overhead top light, top-facing planes lighter than the core; broad cyan-white rim (#82c3e6 to #c3c5d7) along the top and back edges; cool blue-black shadows, never brown or grey.
TRANSPARENCY: fully opaque body; crisp 1-2 px anti-aliased edge; no matte, no dark fringe, no halo.
DO NOT: floor, cast or contact shadow, reflection, background, motion lines, extra figure, extra or missing limbs, visible face, frontal pose, magenta or pink, text.
~~~
