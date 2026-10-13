Use your imagegen skill with the built-in image_gen tool (do not use the CLI or any API key). This is an EDIT/reference task: first load the reference image with view_image so it is in context:
  docs/research-2026-10/sources/sprites-2026-10-08/wolf-side-right.png  (Image 1: canonical identity reference of WOLF, a robotic wolf companion in the game WOLF//OVERRIDE)

Generate ONE landscape 1536x1024 image: a CHARACTER PARTS SHEET (cut-out rig parts for 2D skeletal animation) of exactly this robotic wolf, strict SIDE PROFILE facing screen-right. Match Image 1 exactly: grey-blue faceted armour plates, dark mechanical joints with round bolt hubs, cyan eye and cyan seam lights, exactly two pointed ears, the same head and muzzle shape, the same segmented plated tail. Do not redesign anything.

Lighting for every part: soft cool top light plus a thin cyan rim light on back-facing edges. NO dark outline strokes around parts. Every part fully opaque and solid with crisp clean edges.

Parts (each separate, complete, not overlapping, all at the SAME scale, as if the assembled wolf were about 1100 px long nose to tail tip):
Row 1 (top): 
  1. HEAD with both ears and the cyan eye, profile facing right, with a thick armoured NECK attached that extends back/down about 120 px with a rounded end (so it can tuck into the body).
  2. BODY: the torso only, from the chest/shoulder plates to the hips/rump, with the cyan seam light on the side, the shoulder and hip joint hubs visible; NO legs, NO head, NO tail. Rounded ends so the neck, legs and tail can tuck under it.
Row 2:
  3. TAIL BASE segment (thick, plated, horizontal, rounded front end).
  4. TAIL MIDDLE segment (plated, with the cyan seam light).
  5. TAIL TIP segment (tapering plated tip).
Row 3: leg pieces, each hanging STRAIGHT DOWN vertically, rounded joint ends that overlap generously, each with its round joint hub at the top end:
  6. FRONT upper leg (shoulder to elbow).
  7. FRONT lower leg (elbow to wrist).
  8. FRONT paw (wrist joint and the clawed paw in side profile, toes pointing right, sole flat).
  9. HIND thigh (hip to knee, broad plated thigh).
  10. HIND shin (knee to hock).
  11. HIND foot (hock joint down to the clawed paw, toes pointing right, sole flat).

Each part must be complete, including areas normally hidden by other parts, with extra overlap margin at each joint. Leave at least 40 px of empty space between all parts. Nothing touches the image border.

Background: a perfectly flat, uniform pure magenta #FF00FF everywhere (no gradient, no shadow, no floor, no glow, no text, no labels, no numbers, no guide lines). Do not use magenta or pink on the wolf.

After generating, check the result against Image 1 (identity, colours, profile, all 11 parts present and separate, exactly two ears). If a part is missing, merged, or off-model, regenerate once with a corrected prompt.
Save the final image as PNG to: [session scratch, not kept]/walk2/b1/gen/wolf-parts-v1.png (copy it from $CODEX_HOME/generated_images). Copy any rejected attempt next to it as wolf-parts-v1-reject-N.png. Then print the final path and the prompt you used.
