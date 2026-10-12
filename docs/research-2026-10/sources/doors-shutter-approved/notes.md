# Door round 4

Built with Codex built-in image generation in edit mode. No API, CLI generation, cleanup, watermark removal or metadata editing. No Git repository writes.

## Files and provenance

- corridor-closed.png: red lamp, ribbed steel shutter.
- corridor-open.png: raised shutter, green lamp, machinery chamber.
- junction-closed.png: reinforced blast shutter, amber lamps, electrical junction.
- junction-blown.png: torn armored slats, clear floor-level gap.
- game-size.png: 1920x1080 sheet containing four 960x540 panels, row-major in the above order.
- compare.png: same panels with captions in separate bands outside the art.
- *-half.png: separate half-size inspection derivatives.

Four final scene PNGs are byte-for-byte copies of built-in outputs. SHA-256 equality verified; all contain the original caBX content-credential chunk. Originals were not decoded/reencoded or metadata-modified. Review sheets and half-size previews are newly assembled derivatives, not credential-bearing original assets; original signatures were not transplanted into changed pixels. C2PA signature cryptographic validity was not independently validated.

## Visual self-check at 50% (835x470)

| State | (a) full passage shutter | (b) face/slats/rails/edge | (c) different next space | (d) continuing walkway | (e) corridor style |
|---|---|---|---|---|---|
| Corridor closed | Pass: broad slatted barrier meets floor, structural portal joins ceiling | Pass: broad face, horizontal ribs, guides, hazard edge | Pass: glimpse of tall machinery and separate white lights | Intentionally blocked | Pass: cool steel wall, cyan lamp, pipes, reflective floor retained |
| Corridor open | Pass: same structural portal, shutter stowed overhead | Pass: rails and hazard lower edge visible at header | Pass: tanks, trusses, platforms, white lights | Pass: unobstructed floor across threshold | Pass |
| Junction closed | Pass: heavier armored segments seal passage | Pass: broad armored face, reinforced guides, hazard edge | Pass: electrical cabinets, cable trays, diagonal trusses, warm worklights | Intentionally blocked | Pass |
| Junction blown | Pass: remnants identify same shutter and structural portal | Pass: hanging segmented plates, rails, torn edges | Pass: switchgear hall visible through tear | Pass: clear floor-level gap, debris beside threshold | Pass |

The first engineer was about 36% of image height; regenerated twice. Final engineer is approximately 19%, near but not exact to requested 17%. Corridor shutter face is roughly 1.2 times engineer height; blast version roughly 1.3. Geometry is a concept illustration: actual left-to-right traversal, collision and camera readability are not verified in game. The generation preserves the source visual vocabulary, not pixel-exact original wall/lamp placement. Torn plates read as displaced metal; precise direction of their bend is visually less certain than the clear opening.

## Final prompts

### Corridor closed: initial edit
Use case: compositing / precise-object-edit. Edit image 1, the approved 1920x1080 corridor plate, using image 2 only as engineer identity. Deliver a single 16:9 game scene, no text. Keep the left 60% of image 1's back wall, cyan lamps, overhead and wall pipes, steel floor, side-on camera height and graphic painterly Look 2 style: flat value planes, crisp silhouettes, cool steel, painterly only in lighting, no dark outlines. Engineer red jacket black pants, exact reference identity, standing at x=48%, feet on walkway y=82%, facing RIGHT, height exactly 17% of image. RIGHT of him at x=65-83% create a heavy SHUTTER ACROSS THE CORRIDOR, an obstacle blocking LEFT TO RIGHT travel. It is part of the floor-to-ceiling room structure: thick attached frame columns, deep ceiling header and guide rails. Show broad ribbed steel shutter FACE in slight three-quarter view; screen width 1.4 times engineer height, much wider than a post; full passage height floor to header, horizontal segmented steel slats, visible bottom edge with yellow-black hazard chevrons. No freestanding doorway, no thin pillar, no door on the back wall: this portal crosses the walkway. Corridor narrows into it. Closed shutter fully fills portal from floor to header, RED status lamp on frame. Rightmost 17% gives a small glimpse around structural frame of a genuinely different next space: deep service chamber with vertical machinery, grated catwalk and recessed white worklights, not recolored corridor. Walkway remains one horizontal left-to-right plane. Preserve original art's visual style and floor/camera. No lettering or labels.

### Corridor closed: first correction
Edit this scene only to correct game scale: shrink engineer to exactly 17% of entire image height (currently 36%), preserve identity and facing right, feet at same floor y, standing left of shutter. Reduce shutter face width to 1.4 times new engineer HEIGHT, about 24% image height or 13.5% image width; keep tall floor-to-ceiling shutter and structural header, rails, hazard edge. Keep original corridor camera, backwall lamps pipes floor style unchanged. Shutter blocks entire narrowed corridor cross-section and shows broad slatted face, no post. Distinct service chamber at right remains. No text.

### Corridor closed: final correction
Precise scale correction only. Engineer must be 160 pixels tall in this 941 pixel high scene, feet at y=710, top of hair y=550. Currently he is 225 pixels tall: shrink him by 29%. Shutter broad visible face should be 215 pixels wide, currently 320: narrow it by one third, bring left guide rail rightward leaving right rail fixed. Keep floor-to-ceiling height, red lamp, slats, hazard lower edge, ceiling structural header; preserve all surrounding original corridor and different space on right. No text. Single scene.

### Corridor open
Edit only shutter STATE in this scene: raise ALL steel slats fully into existing ceiling header. Portal now completely clear from floor to header, side guide rails remain visible, hazard bottom edge is tucked at header. Change red status lamp to GREEN, including reflection. Through clear opening show genuinely different deep machinery service chamber, vertical cylindrical tanks, cross-braced steel structures, recessed white worklights, grated side platforms. A solid walkable floor extends horizontally LEFT TO RIGHT through portal, same height, no drop or steps. Keep exact small engineer pose identity scale location, entire left corridor back wall, pipes, cyan lamp, floor, camera, graphic painterly style. No text. 16:9.

### Junction closed
Edit this closed corridor scene into JUNCTION CLOSED. Keep exact left corridor backwall pipes cyan lamps steel floor camera and small red-jacket engineer facing right unchanged. Keep same broad floor-to-ceiling shutter portal position attached structurally. Upgrade shutter to heavier blast shutter: thick overlapping horizontal armored steel segments, reinforced side guide rails and deeper bolted structural header, visible broad three-quarter face and hazard chevron bottom edge fully sealing whole narrowed passage. AMBER status lamps on both frame sides, amber reflections. Beyond right of frame glimpse a genuinely DIFFERENT junction: deep electrical switchgear hall with square cabinet banks, overhead cable trays, diagonal roof trusses and its own warm worklights, not cylinder service room and not tinted left corridor. Graphic painterly flat planes crisp silhouettes cool steel, light only painterly, no dark outlines. No text.

### Junction blown
Edit only shutter damage STATE of this junction scene. Heavy blast shutter blown open: middle and bottom armored horizontal segments violently buckled and torn toward the NEXT SPACE on RIGHT, not toward engineer. Upper broken segments hang from header, jagged scorched side remnants reveal thickness and horizontal slat construction. Leave a clearly visible walkable opening at least twice engineer height high from floor, fully clear at walkway center; small scattered scorch debris beside gap not blocking passage. Through tear reveal deep electrical junction with square switchgear cabinets, cable trays diagonal trusses own warm lights, different construction from cool corridor left. Keep reinforced rails deep header amber lamps, exact small engineer scale identity pose facing right, left wall cyan lamp pipes floor and camera unchanged. Straight same-height LEFT TO RIGHT floor continues visibly through torn shutter and into junction. Graphic painterly flat steel value planes crisp silhouettes painterly lighting no dark outlines. No text.

