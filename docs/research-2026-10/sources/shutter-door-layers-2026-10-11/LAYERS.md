# Shutter door layers (scratch, 2026-10-11, v2 after the review)

These are the game-ready layers for the approved shutter design ("Shutter across the corridor", approved 2026-10-11) and the plate fixes, for every door in `MEASURE.md`. This is version 2. It answers the fixes in `REVIEW.md` and Nathanial's decision on its open question.

Everything here is scratch:
- Nothing was written to a Git repository.
- Nothing was imported into the real project and nothing was played.
- The composites are Python paste-ups of the door layers over door-free Godot captures, so they make **no claim about feel**, timing or readability in motion.
- The backgrounds are new captures from the scratch game copy, with the patched plates installed. So the plates in the composites are real Godot renders, and the old `plate_fix` paste-up is gone.

**Art.** Codex built-in image generation in edit mode only: 20 sessions, listed in `provenance.txt` and `manifest-draft.json`.
- All 32 raw outputs are byte-for-byte tool copies, and each keeps its C2PA `caBX` chunk. This was checked by PNG chunk parse with `review/py/chunks.py`.
- The layers are deterministic derivatives, rebuilt by `tools/build_all2.sh` and then `driver/run_bg3.sh`, `tools/compose2.py` and `tools/inventory2.py`. They are new encodings and carry no content credential.

**Density.** Every door layer is D = 4 (4 source px per world px), so use scale 0.25 in Godot. Plates stay 1920x1080 at 0.5.

**Anchors.** Every layer of one door shares one canvas. Place the sprite with `centered = false` at the canvas's world top-left. New in v2: the canvas bottom is the near column's foot, which is below the walk line (y 440). The 3/4 shutter crosses the floor, so the near column stands in front of the walk line.

**Contact sheet:** `composites/sheet.png`. Every state has `composites/<door>-NN-<state>.png` plus a `-boxes.png` debug twin. The twin draws:
- red: enabled hitbox, labelled with its node name (hazards as `hazard:<shape>`)
- grey dashed: disabled hitbox
- orange: Area2D
- yellow: every actor and prop render box, with its z
- cyan: door z 0 layers
- magenta: door z 3 layers
- white: lamp sprites
- green: the opening polygon, the floor y 440 and world-x ticks
- thick red: the **proposed blocking face** (red when it blocks, grey when off)

The v1 composites are kept in `work/v2/composites-v1/`.

## What changed in v2 (review item to fix)

| Review item | Status | What was done |
|---|---|---|
| 2. Corridor leaf face-on, invisible-wall read | fixed (art) | Codex edit-mode repaint of corridor, records and exit hatch in a real three-quarter view (`door-*-skew`). The leaf's hazard edge runs from y 432.5 at the far jamb to y 462.4 at the near jamb (slope 0.385, close to the approved concept's 0.35). It crosses the walk line at **x 751.7**, the existing `CORRIDOR_DOOR_LEFT_X` 752, so no corridor code number changes. The leaf is split at the crossing: `leaf-far` (z 0, behind the walk line) and `leaf-near` (z 3, in front of it). An engineer stopped at the face is overlapped by the leaf's near part. See `corridor-seal-06-engineer-at-face`. |
| 3. Beyond is not where you walk (decision) | done as decided | **Corridor, option (a):** the far plate right of the portal (src x >= 1621) is now the same machinery room as the beyond. The mid plate gains a foreground tank column and a gantry with a yellow rail at x >= 825 (`plate-corridor-machinery`). The safe point console, its lamp and its label are untouched and sit where the code puts them (`CheckpointArt` 841-911, label 840-912). See `corridor-seal-03` and `-05`. **Junction, option (b):** the blown gap now shows a deeper view of the cool pipe bay with the hanging tank rig (`beyond-junction-baybay`), regraded cool. Its accent p90 is 14.9 (pass). The junction's right half is not re-themed. **Records exit and exit hatch** keep their own new spaces. **Entry hatch** stays shut. |
| 4. Exit hatch lamp hidden at the right clamp | fixed (art) | The repainted hatch has a second caged lamp housing in the header, centred at **(886.4, 180.4)**, 23.9 tall. It is in view (top 160) and clear of the near pipe. Drive it with the same `_bolt_light_color()` as the column lamp. Red, amber and white now differ in `junction-exit-hatch-01..03`. |
| 7. Paste-up speckle on the breaker and label, dashed rail remnant | fixed (pipeline) | No more `plate_fix`. The patched plates are rendered by Godot in `bgcap3/`. `junction-*` shots are clean around OVERLOAD BREAKER and the old rail line. |
| 8. Accent flags | measured | The junction beyond now passes (14.9). Hazard yellow still needs a bible swatch (see QA). |
| 9. Scorch too faint (optional) | partly | Both decals are drawn at alpha 1.0 (was 0.6 on the wall) and darkened toward cold soot. Over the dark junction floor they are still subtle at 1280x720. |
| 1. Shut portals can be walked through | code, for integration | No art change is needed. The faces belong at each leaf's walk-line crossing (table below). The `-boxes` twins draw them, and the `*-engineer-at-face` probes show the engineer at each stop. |
| 5. MANUAL BYPASS label under the far column | code, for integration | `work/bypass-label-nudge.diff` (applied only to the scratch game copy) clamps the label's right edge to x 712. It clears the column, but the panel (648-712) now overlaps the right end of "COOLANT RELAY" (555-655) by about 7 world px (`corridor-seal-01`). Integration should narrow the panel or put it under the wheel. |
| 6. In-game debug overlay | out of scope | It is built on `codex/debug-tools`. The `-boxes` twins here add actor and prop render boxes with z, and readable hazard names, for this job's own checking. |

## Proposed blocking faces (review item 1, for the code step)

With a 3/4 leaf, the visible place where the shutter meets the floor is the walk-line crossing, not the far jamb. Put each face there, so the engineer's hitbox touches the leaf where it visibly crosses his path. Engineer half-width 14; WOLF half-width 31; `WOLF_REACH` 67.

| Door | Face x (world) | Active while | Engineer limit | WOLF limit | Checks |
|---|---|---|---|---|---|
| corridor-seal | 752 (crossing 751.7, unchanged) | as now (body until `_door_lands`) | max 738 | `follow_max_x` 685 (as now) | The bypass crank at 674 still fits. |
| records-exit | 833 (crossing 833.3) | `_exit_open` false, until the leaf has lifted | max 819 | max 766 by the corridor rule (face - 67); 802 is the bare body limit | USE `abs(x - 830) <= 58` covers 819. |
| junction-exit-hatch | 881 (crossing 881.1) | until `hatch_open` = 1 | max 867 | max 814 (face - 67); 850 body | Bolt reach from `BOLT_REACH_MIN_X` 790 is fine. The walk-out to 886 needs the face off, as planned. |
| junction-entry-hatch | 79 (crossing 78.9), fixed | always | min 93 | min 110 (body) | Spawns at 120 / WOLF 208 still work; nothing interactive lies left of 160. |
| junction-blast | 452 (unchanged) | as now | as now | as now | It passed the review (9 px overlap). |

Add tests for the three new bounds. Also update `m0_scene_test` 222-237, which pins the old `seal_leaf` / `door_open_art` / `door_lip` structure.

## Shared draw order (per door)

1. `*-beyond.png`: z 0, lowest. The different space, clipped to the opening.
2. `*-leaf-far.png`: z 0. Position y = -open x `leaf_travel_world`, clipped by `*-opening-mask.png`. At open = 1 it is fully clipped, so hide it. There is no `leaf-stowed` layer any more: the painted hazard lip under the drum is the tucked edge.
3. `*-back.png`: z 0. The frame, with the opening transparent. The header hides the rising leaf.
4. Actors: z 2.
5. `*-leaf-near.png`: z 3, under the front layer. Same offset and clip as `leaf-far`. It is the part of the leaf in front of the walk line, so it overlaps an actor stopped at the face. Hide it at open = 1.
6. `*-front.png`: z 3. The near column and its jamb only. Fade it to 0.5 while it covers an actor (as `door_lip` does now).
7. Lamp sprite, then additive glow: z 3, centred on the painted housing.

The junction blast door keeps its v1 layers (it passed review), apart from its new beyond.

## Measured geometry (from the painted layers)

| Door | Canvas (world x0,y0,x1,y1) | Opening bbox (world) | Leaf bottom edge at far, near jamb | Lip at far, near jamb | Walk-line crossing | Front from x | Leaf travel |
|---|---|---|---|---|---|---|---|
| corridor-seal | 716, 141, 842, 467 | 732.25, 218, 809.75, 462.5 | 432.5, 462.4 | 216.6, 233.0 | 751.7 | 809.75 | 229.75 over 1.0 s |
| records-exit | 796, 155.5, 926, 467.5 | 814.5, 228.25, 889.25, 463 | 432.3, 462.9 | 228.0, 241.9 | 833.3 | 889.25 | 221.25 over 0.5 s |
| junction-exit-hatch | 846, 117.75, 958, 457.75 | 862.25, 202.75, 925.5, 453.25 | 434.4, 453.3 | 202.5, 215.8 | 881.1 | 925.5 | 237.75 over 0.5 s (`hatch_open`) |
| junction-entry-hatch | 2, 117.75, 114, 457.75 (exit hatch, flip_h baked) | 34.5, 202.75, 97.75, 453.25 | mirror | mirror | 78.9 | front is x 2-34.5 (left) | static, shut |
| junction-blast | 420, 118, 546, 440 | gap 443.25, 205.75, 513, 440 | - | - | face 452 | 513 | - (frames swap) |

The full opening polygons are in each `<door>-meta.json` (`opening_polygon_world`). The walk-out at 886 is inside the exit opening. The records USE point at 830 is inside its opening. The blown gap's median clear height is 212 world px.

## Lamps

The housings are painted unlit into each frame. Put the lit sprite over the housing, then the additive glow (192 px = 48 world px; the composites use strength 0.55). Sprites: `layers/lamps/lamp-{red,amber,white,green,unlit,broken}-h{24,25,26,27,30,31}.png`. Glows: `glow-{red,amber,white,green}-add.png` (RGB on black, BLEND_MODE_ADD).

| Door | Housing centre (world) | Height | Sprite set | States |
|---|---|---|---|---|
| corridor-seal | 827.2, 329.6 | 25.35 | `h25` | red sealed and opening, green open |
| records-exit | 910.5, 322.3 | 30.25 | `h30` | red sealed and lifting, green open |
| junction-exit-hatch, column | 942.4, 299.0 | 30.74 | `h31` | red bolted, amber bolt live, white charging and opening, green open |
| junction-exit-hatch, **header (new)** | 886.4, 180.4 | 23.93 | `h24` | same colour as the column lamp (`_bolt_light_color()`) |
| junction-entry-hatch | 17.6, 299.0 and 73.6, 180.4 | 30.74 / 23.93 | `h31` / `h24` | green (static) |
| junction-blast near / far | 526, 293 / 426.25, 295 | 27 / 26 | `h27` / `h26` | amber; white when charged; broken / unlit when blown |

## Corridor seal (lockdown chapter)

The machinery service chamber is beyond the portal, and from v2 it is also the room you walk into: see Plates. States:
- **hidden** in the intro: draw nothing (the plate fix still applies)
- **sealed:** leaf at 0, red
- **opening:** leaf 0 to 1 over 1.0 s, body still on, red
- **open:** leaves hidden, green, body off at `_door_lands`
- **hidden** in the other rooms

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/corridor-seal/corridor-seal-back.png` | 504x1304 | 126x326 | 716, 141 | every visible state | z 0 (over the beyond and the leaf, under actors) |
| `layers/corridor-seal/corridor-seal-front.png` | 504x1304 | 126x326 | 716, 141 | every visible state; fade to 0.5 while it covers an actor | z 3 (KNOCKDOWN_Z), over actors |
| `layers/corridor-seal/corridor-seal-leaf-far.png` | 504x1304 | 126x326 | 716, 141 | sealed; opening (offset y = -open * leaf_travel), clipped to opening-mask; hidden at open=1 | z 0, under back and actors |
| `layers/corridor-seal/corridor-seal-leaf-near.png` | 504x1304 | 126x326 | 716, 141 | sealed; opening (same offset and clip as leaf-far); hidden at open=1 | z 3, over actors, under front |
| `layers/corridor-seal/corridor-seal-opening-mask.png` | 504x1304 | 126x326 | 716, 141 | clip only, not drawn | - |
| `layers/corridor-seal/corridor-seal-sealed-full.png` | 504x1304 | 126x326 | 716, 141 | sealed (optional) | z 0 |

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/corridor-seal/corridor-seal-beyond.png` | 504x1304 | 126x326 | 716, 141 | opening, open (and hidden behind the leaf when sealed) | z 0, lowest door layer |

## Records exit

The maintenance passage toward the junction (warm glow ahead) is beyond. This replaces `records-exit-hatch.png`, the lift-and-fade tween and the `_draw_exit()` rectangles. States:
- **sealed:** red
- **lifting:** open 0 to 1 over 0.5 s during the chapter close
- **open:** green, also on reload

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/records-exit/records-exit-back.png` | 520x1248 | 130x312 | 796, 155.5 | every visible state | z 0 (over the beyond and the leaf, under actors) |
| `layers/records-exit/records-exit-front.png` | 520x1248 | 130x312 | 796, 155.5 | every visible state; fade to 0.5 while it covers an actor | z 3 (KNOCKDOWN_Z), over actors |
| `layers/records-exit/records-exit-leaf-far.png` | 520x1248 | 130x312 | 796, 155.5 | sealed; opening (offset y = -open * leaf_travel), clipped to opening-mask; hidden at open=1 | z 0, under back and actors |
| `layers/records-exit/records-exit-leaf-near.png` | 520x1248 | 130x312 | 796, 155.5 | sealed; opening (same offset and clip as leaf-far); hidden at open=1 | z 3, over actors, under front |
| `layers/records-exit/records-exit-opening-mask.png` | 520x1248 | 130x312 | 796, 155.5 | clip only, not drawn | - |
| `layers/records-exit/records-exit-sealed-full.png` | 520x1248 | 130x312 | 796, 155.5 | sealed (optional) | z 0 |

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/records-exit/records-exit-beyond.png` | 520x1248 | 130x312 | 796, 155.5 | opening, open (and hidden behind the leaf when sealed) | z 0, lowest door layer |

## Junction exit hatch (end of slice)

A long service-line tunnel with a flush rail and green-white guide lights is beyond. It replaces `junction-hatch.png` and the borrowed `corridor-bulkhead-open.png` passage. States:
- **bolted:** red
- **bolt live:** amber
- **charging:** white
- **opening:** `hatch_open` 0 to 1 over 0.5 s, white
- **open:** green
- **cleared:** walk-out to 886

Both lamps follow the state.

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/junction-exit-hatch/junction-exit-hatch-back.png` | 448x1360 | 112x340 | 846, 117.75 | every visible state | z 0 (over the beyond and the leaf, under actors) |
| `layers/junction-exit-hatch/junction-exit-hatch-front.png` | 448x1360 | 112x340 | 846, 117.75 | every visible state; fade to 0.5 while it covers an actor | z 3 (KNOCKDOWN_Z), over actors |
| `layers/junction-exit-hatch/junction-exit-hatch-leaf-far.png` | 448x1360 | 112x340 | 846, 117.75 | sealed; opening (offset y = -open * leaf_travel), clipped to opening-mask; hidden at open=1 | z 0, under back and actors |
| `layers/junction-exit-hatch/junction-exit-hatch-leaf-near.png` | 448x1360 | 112x340 | 846, 117.75 | sealed; opening (same offset and clip as leaf-far); hidden at open=1 | z 3, over actors, under front |
| `layers/junction-exit-hatch/junction-exit-hatch-opening-mask.png` | 448x1360 | 112x340 | 846, 117.75 | clip only, not drawn | - |
| `layers/junction-exit-hatch/junction-exit-hatch-sealed-full.png` | 448x1360 | 112x340 | 846, 117.75 | sealed (optional) | z 0 |

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/junction-exit-hatch/junction-exit-hatch-beyond.png` | 448x1360 | 112x340 | 846, 117.75 | opening, open (and hidden behind the leaf when sealed) | z 0, lowest door layer |

## Junction entry hatch (decoration, always shut)

The exit hatch layers mirrored (flip_h baked in), shut, with green lamps. Canvas x 2-114. The engineer spawns at 120.

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/junction-entry-hatch/junction-entry-hatch-back.png` | 448x1360 | 112x340 | 2, 117.75 | static shut (flip_h of the exit hatch layers) | z 0 (over the beyond and the leaf, under actors) |
| `layers/junction-entry-hatch/junction-entry-hatch-front.png` | 448x1360 | 112x340 | 2, 117.75 | static shut (flip_h of the exit hatch layers) | z 3 (KNOCKDOWN_Z), over actors |
| `layers/junction-entry-hatch/junction-entry-hatch-leaf-far.png` | 448x1360 | 112x340 | 2, 117.75 | static shut (flip_h of the exit hatch layers) | z 0, under back and actors |
| `layers/junction-entry-hatch/junction-entry-hatch-leaf-near.png` | 448x1360 | 112x340 | 2, 117.75 | static shut (flip_h of the exit hatch layers) | z 3, over actors, under front |
| `layers/junction-entry-hatch/junction-entry-hatch-sealed-full.png` | 448x1360 | 112x340 | 2, 117.75 | static shut (flip_h of the exit hatch layers) | z 0 |

## Junction blast door

These are v1 layers, unchanged. Only the beyond is new. It is a heavier armored family:
- about 6 overlapping segments
- bolted rail clamps
- a deep bolted header

The states:
- **Sealed, building, charged and knockdown restore** use `sealed` and `front-sealed`, plus the seam glow and the lamps.
- **Breaking** swaps to `breaking` for 0.15 s. Keep the 1.04/0.94 jolt on the parent.
- **Blown** uses `beyond` + `blown` + `front-blown` + debris + scorch, with the lamps broken (near) and unlit (far).

The seam glow anchor is centre (476.375, 419.25), about 69.25x10 world. It replaces `DOOR_SEAM_X` 196.

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/junction-blast/junction-blast-sealed.png` | 504x1288 | 126x322 | 420, 118 | sealed / building / charged / knockdown-restore | z 0 |
| `layers/junction-blast/junction-blast-breaking.png` | 504x1288 | 126x322 | 420, 118 | breaking | z 0 |
| `layers/junction-blast/junction-blast-blown.png` | 504x1288 | 126x322 | 420, 118 | blown (+ restored-from-save blown) | z 0 |
| `layers/junction-blast/junction-blast-front-sealed.png` | 504x1288 | 126x322 | 420, 118 | sealed/building/charged | z 3, fade 0.5 over actors |
| `layers/junction-blast/junction-blast-front-breaking.png` | 504x1288 | 126x322 | 420, 118 | breaking | z 3 |
| `layers/junction-blast/junction-blast-front-blown.png` | 504x1288 | 126x322 | 420, 118 | blown | z 3, fade 0.5 over actors |
| `layers/junction-blast/junction-blast-gap-mask.png` | 504x1288 | 126x322 | 420, 118 | clip only | - |

**Beyond (new in v2, decision option b):** a deeper view of the cool pipe bay with the hanging tank rig. This is the room that is really right of the door.

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/junction-blast/junction-blast-beyond.png` | 504x1288 | 126x322 | 420, 118 | blown | z 0, lowest |

**Debris and scorch (blown only).** The pieces lie on the floor right of the gap face, behind the actors, with no collision. The rubble line stays at 540. Scorch is now drawn at alpha 1.0 (was 0.6 on the wall).

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/junction-blast/junction-blast-debris-slab-v.png` | 120x54 | 30x13.5 | 522, 427.5 | blown | z 1 (behind actors, out of collision) |
| `layers/junction-blast/junction-blast-debris-hazard-bar.png` | 104x31 | 26x7.75 | 556, 433.25 | blown | z 1 (behind actors, out of collision) |
| `layers/junction-blast/junction-blast-debris-rail-clamp.png` | 48x37 | 12x9.25 | 548, 431.75 | blown | z 1 (behind actors, out of collision) |
| `layers/junction-blast/junction-blast-debris-shard.png` | 68x34 | 17x8.5 | 590, 432.5 | blown | z 1 (behind actors, out of collision) |
| `layers/junction-blast/junction-blast-debris-fragments.png` | 60x45 | 15x11.25 | 578, 429.75 | blown | z 1 (behind actors, out of collision) |
| `layers/junction-blast/junction-blast-debris-scorched-segment.png` | 80x36 | 20x9 | 606, 432 | blown | z 1 (behind actors, out of collision) |

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/junction-blast/junction-blast-scorch-floor.png` | 520x40 | 130x10 | 436, 436 | blown | z -2 |
| `layers/junction-blast/junction-blast-scorch-wall.png` | 104x111 | 26x27.75 | 500, 362 | blown | z 1 |

## Plates

The mid plates are cut-outs over transparency. Integrate by replacing `apps/game/assets/rooms/<plate>.png` with the patched plate. The patch layers and masks show exactly which plate pixels changed.

**New in v2 (corridor, option a): `plate-corridor-machinery`**
- **corridor-far:** src x 1621-1920, all rows, is the machinery room: tanks, braced towers, a railed platform and ceiling lights.
  - The far plate parallaxes at 0.9 (±12 world px), so the 43 px feather at src 1621-1664 (world about 811-832) always sits behind the portal's near column (810-842) or under the beyond.
  - The Codex edit drifted, so it was registered back in `tools/plate_patch2.py`: brightness +50%, back-wall floor line 33 px high (re-mapped to the plate's own floor line). The colour is matched by per-channel mean/std on the untouched part of the strip.
  - The area behind the safe point console and its label was asked to stay calm and mid-dark. In the composites the console, the green lamp and "SAFE POINT" read clearly.
- **corridor-mid:** adds a tall tank column with pipes at the right edge (world x about 902-960, standing just behind the console's right edge and partly behind the near pipe at the right clamp) and an overhead gantry with a yellow rail (world y about 191-262, above the label at 313).
  - Its tank foot was re-mapped onto the walkway row 777.
  - It is graded to chroma 0.6, because the edit came out more saturated than the plate.
  - It also carries the v1 erase of the old column pair and machine.

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/plates/corridor-far.png` | 1920x1080 | 960x540 | as the existing plate node | all | z -4 (far, as now) |
| `layers/plates/corridor-far-patch-machinery-room.png` | 299x1080 | 149.5x540 | plate_src_rect | all | child of the plate node, offset plate_src_rect.xy at the plate scale |
| `layers/plates/corridor-far-patch-machinery-room-mask.png` | 299x1080 | 149.5x540 | plate_src_rect | review | - |
| `layers/plates/corridor-mid.png` | 1920x1080 | 960x540 | as the existing plate node | all | z -3 (as now) |
| `layers/plates/corridor-mid-patch-machinery-room.png` | 270x780 | 135x390 | plate_src_rect | all | child of the plate node, offset plate_src_rect.xy at the plate scale |
| `layers/plates/corridor-mid-patch-machinery-room-mask.png` | 270x780 | 135x390 | plate_src_rect | review | - |

**From v1, unchanged:**
- **records-mid:** the machine right of the truss is erased.
- **junction-mid:**
  - the exit truss is erased
  - the pipe stack is a Codex repaint into a flanged elbow
  - the entry boiler cluster is a Codex repaint

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/plates/corridor-mid-patch-corridor-door-column-and-machine.png` | 480x685 | 240x342.5 | 720, 101.5 | review / alternative to swapping the plate | z -3, over the plate |
| `layers/plates/corridor-mid-patch-corridor-door-column-and-machine-mask.png` | 480x685 | 240x342.5 | 720, 101.5 | review | - |

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/plates/records-mid.png` | 1920x1080 | 960x540 | 0, 69 | all | z -3 (as now) |
| `layers/plates/records-mid-patch-records-exit-machine.png` | 338x248 | 169x124 | 791, 319 | review / alternative to swapping the plate | z -3, over the plate |
| `layers/plates/records-mid-patch-records-exit-machine-mask.png` | 338x248 | 169x124 | 791, 319 | review | - |

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/plates/junction-mid.png` | 1920x1080 | 960x540 | 0, 52 | all | z -3 (as now) |
| `layers/plates/junction-mid-patch-junction-exit-truss.png` | 120x635 | 60x317.5 | 895, 122 | review / alternative to swapping the plate | z -3, over the plate |
| `layers/plates/junction-mid-patch-junction-exit-truss-mask.png` | 120x635 | 60x317.5 | 895, 122 | review | - |
| `layers/plates/junction-mid-patch-junction-door-pipe-stack-mask.png` | 440x568 | 220x284 | 320, 55 | review | - |
| `layers/plates/junction-mid-patch-junction-entry-boiler-cluster-mask.png` | 560x772 | 280x386 | 0, 52 | review | - |

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/plates/junction-mid-patch-junction-door-pipe-stack.png` | 440x568 | 220x284 | 320, 55 | review / alternative to swapping the plate | z -3, over the plate |

| File | Size (px) | World size | World top-left | State | Draw |
|---|---|---|---|---|---|
| `layers/plates/junction-mid-patch-junction-entry-boiler-cluster.png` | 560x772 | 280x386 | 0, 52 | review / alternative to swapping the plate | z -3, over the plate |

## QA (art bible `qa_asset.py`, family door; plates plate-far / plate-mid)

The full output is in `work/v2/qa.txt`. Highlights:

- **Values.** The v2 doors are graded to the v1 door-band medians (`grade2.py`): sealed L* 18.0 / 18.1 / 18.6, inside the bible's 12-22. Cool neutrals pass everywhere (b* -6.6 to -10.6 on doors, -4.2 / -4.75 on the plate patches). Noise and hf pass.
- **Density.** E_density is 1.48 at 1080p and 2.96 at 960 for the frames. The leaf halves report 1.0-1.1, but they sit on the same D = 4 canvas as the frame; the lower number comes from how the check measures a partial layer.
- **Accent p90.**
  - **Passes** (≤ 18): `corridor-seal-back` 17.5, `-front` 2.9, `-beyond` 7.3, `records-exit-back` 17.6, `-front` 7.2, `-beyond` 15.2, `junction-exit-hatch-sealed-full` 16.9, `-front` 15.1, `-beyond` 13.5, **`junction-blast-beyond` 14.9** (was 20.6), `corridor-far` patch 13.9.
  - **Marginal fails** at 18.1-19.2 on some sealed and leaf layers. These come from **hazard yellow**, which has no bible swatch.
  - With two swatches sampled from the painted hazard bars added, every door layer passes (5.8-16.8; `tools/accent_probe.py` lists the numbers in `work/v2/qa.txt`):
    - `#8a6a3e` (hazard yellow, shade)
    - `#a8844e` (hazard yellow, lit)
  - **Proposal for the bible owner:** add these two accents. This job did not edit the bible, which lives outside this job's scratch folder.
- **Edge flags.** As in v1:
  - C_fringe_halo, and C_outline_dL on the fronts, measure the requested cyan-white rim.
  - C_fringe_dark on back/front is the dark jamb faces at the opening, which sit over the beyond or the leaf in game.
  - Leaf-half edge flags are their cut edges, which sit under the frame or are clipped by the opening mask.
  - Over grey there is no matte or black fringe.
- **Top light.** C_top_light does not apply to the beyond layers, which are interiors seen through an opening.
- **Lamps.** The lamp sprites fail the colour checks because they are emissive lenses.

## Known limits and open points

1. **Composites are paste-ups, not a game render.**
   - The FloorReflection stand-in flips the z 0 stack about the walk line (0.28, fading over 60 px).
   - The blast stripes and strobe are not shown.
   - The large yellow flash at the floor in `junction-blast-04-breaking` is the game's own breaking effect in the capture, not door art.
   - Judge the new leaf split and the plate seam again in a real Godot render after integration.
2. **Label overlap.** The MANUAL BYPASS nudge (`work/bypass-label-nudge.diff`) fixes the column overlap but touches "COOLANT RELAY" by about 7 world px. This is code, for the integration step.
3. **Room expansion.** The coordinates are for the current 960-wide rooms. If the rooms grow, re-anchor the canvases and redo the corridor plate strip.
4. **Intro containment gate.** There is no new door for it (out of scope, as the measurement recommended).

## Delete list once the new art is integrated

See `manifest-draft.json` `delete_list_on_integration`:
- all corridor-bulkhead-* and junction-bulkhead-* props, `junction-hatch.png`, `records-exit-hatch.png` and their .import files
- `art-source/doors/*`
- `scripts/prepare_bulkheads.py`
- their manifest rows
- the `_draw_exit()` rectangles
- the borrowed `HATCH_PASSAGE_PROP`

The superseded raw masters are kept only in scratch for provenance (`used_in_layers: false`) and are not for the repository:
- face-on doors v1-v3
- the warm switchgear beyond

Tests that pin the old structure: `m0_scene_test.gd` 222-237 and `junction_test.gd` 298-349, 556-569, 630-646.
