Use your imagegen skill with the built-in image_gen tool (do not use the CLI or any API key). This is an EDIT/reference task: first load the reference image with view_image so it is in context:
  docs/research-2026-10/sources/sprites-2026-10-08/rowan-side-right.png  (Image 1: canonical identity reference of "the engineer", the only playable character of the game WOLF//OVERRIDE)

Generate ONE landscape 1536x1024 image: a CHARACTER PARTS SHEET (cut-out rig parts for 2D skeletal animation) of exactly this engineer, seen in strict SIDE PROFILE facing screen-right. Match Image 1 exactly: the same face, short dark-brown messy hair, deep-red quilted hooded field jacket with dark straps and buckles, belt with pouches and the small cyan equipment light on the belt, black gloves, charcoal cargo trousers with knee straps and a thigh pocket, dark chunky boots with grey toe caps, the same painterly-but-clean material rendering. Do not redesign anything. No yellow patches, no shiny silver knee armour.

Lighting for every part: soft cool top light plus a thin cyan rim light on the back-facing edges, dark cool shadows. NO dark outline strokes around parts. Every part is fully opaque and solid, with crisp clean edges.

Parts (each a separate, complete, unoverlapping piece; all at the SAME scale, as if the assembled figure were about 900 px tall):
Row 1 (top, left to right):
  1. HEAD with hair, in profile facing right, with a short neck stub at the bottom (neck extends 20 px below the jaw so it can tuck under the collar).
  2. TORSO: jacket body from collar to jacket hem, with the hood lying at the back of the collar, belt with the cyan light and pouches at the waist, painted from the side; no arms attached (the shoulder area is complete, jacket fabric only), no head, no legs. Include a little trouser seat/hip below the belt so the hips are covered.
  3. BACKPACK: the slim dark backpack with straps seen from the side, separate.
Row 2: four ARM pieces, each hanging STRAIGHT DOWN vertically, with rounded joint ends that overlap generously:
  4. NEAR upper arm (red jacket sleeve, shoulder to elbow, round shoulder cap on top).
  5. NEAR forearm with gloved hand (red sleeve with dark cuff, then black glove, hand relaxed and slightly curled), elbow end rounded.
  6. FAR upper arm (same as 4, slightly darker in shadow).
  7. FAR forearm with gloved hand (same as 5, slightly darker).
Row 3: four LEG pieces, each hanging STRAIGHT DOWN vertically, rounded joint ends:
  8. NEAR thigh (charcoal trousers with the thigh pocket, hip to knee, round hip cap on top, knee strap at the bottom).
  9. NEAR shin with boot (knee to sole; boot in side profile with toe pointing right; the sole flat and horizontal).
  10. FAR thigh (same as 8 without the pocket, slightly darker).
  11. FAR shin with boot (same as 9, slightly darker, toe pointing right).

Each part must be complete, including the areas that are hidden in the original pose, with extra overlap margin at every joint (rounded caps). Leave at least 40 px of empty space between all parts. Nothing touches the image border.

Background: a perfectly flat, uniform pure magenta #FF00FF everywhere (no gradient, no shadow, no floor, no glow, no text, no labels, no numbers, no guide lines, no borders). Do not use magenta or pink anywhere on the character.

After generating, check the result against Image 1 (identity, colours, profile view, all 11 parts present and separate). If a part is missing, merged with another, or off-model, regenerate once with a corrected prompt.
Save the final image as PNG to: [session scratch, not kept]/walk2/b1/gen/engineer-parts-v1.png  (copy it from $CODEX_HOME/generated_images). Also copy any rejected attempt next to it as engineer-parts-v1-reject-N.png. Then print the final path and the prompt you used.
