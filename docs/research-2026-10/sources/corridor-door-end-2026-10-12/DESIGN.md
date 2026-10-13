# Corridor door end: construction design

Scratch only. Follows `docs/research-2026-10/art-direction/REAL-LOOK.md` (sections 1-6 and the military-base section 8) and the measured hardware in `real-slice/anatomy/ANATOMY.md`. Every construction render, mask and spec is drawn by Python from measured numbers; no image tool touched this step. Nothing was played by hand.

## Current design: fix round 5 (v6), 2026-10-12

Fix round 5 (`design/tools/portal6.py`, `design/portal6/`) keeps the v5 model and closes what the round-5 review asked. The v5 section below still describes everything this section does not change. `DESIGN.round4.md` is the round-4 copy of this file.

| Review item | v6 design |
|---|---|
| must 1: the lamp conduit starts in mid-air | The 20 mm rigid conduit up the column's end face (`lamp_conduit_up`, 30 mm proud of the face, centred at t = 0.25 m) now stops at **4.3125 m**, where a standard **90-degree elbow** (centre-line radius 100 mm, `lamp_conduit_elbow`) turns it toward the corner. A **horizontal run at 4.41 m** (`lamp_conduit_run`, the camera conduit's own height) crosses the end face to the arris, held by **one saddle strap** at t = 0.08-0.10 m (`lamp_conduit_strap`). It wraps the corner 20 mm proud of the jamb's 160 mm approach face (`lamp_conduit_corner`) and **enters the side of the camera's wall plate** (its edge at a = A_END4 + 0.01). This is the spec's own intent, "from the camera's box": every end of the run is on a box or a plate (lamp box below, camera wall plate above). In the design the chain touches end to end (`portal6/spec.json`, `lamp_conduit_top.joins_design_px`, contact within 2 design px: lamp cap->vertical 4, vertical->elbow 12, elbow->run 8, run->corner 23, corner->plate 36 px). |
| should 3: a pale strip under the camera housing | Not a design part: the painted wall layer still carried a **ghost of an earlier camera** (a pale silhouette with a dark outline, design x 368..470, y 466..514), offset from the camera drawn now, so its lower edge showed under the housing as if lit from below, and a pale patch showed above the arm. The cleanup paints it out with the wall's own concrete (`layers/tools/cleanup6.py`). No geometry changes. |
| should 2: the tank's lit side faces a hidden fixture | No geometry changes. High-bay B (visible, over the tank's right half, about 2 m behind it and 0.35 m above its crown) now also grazes the shell's right limb from behind: a **faint rim**, at most 4 source px wide, strongest under the head and fading down the shell (`cleanup6.py`). |
| should 1: the parts list named a relay feed that is not drawn | The Parts table's mid-patch row is corrected below. No relay feed is drawn in the installed build (round 1 drew one; round 3's install4 rebuilt the mid plate without it): the relay is fed from the floor through its plinth's brush-strip cable entry, and nothing was added to match the old line. |

**Flat-shaded design render (v6):** `door-end-design-v6-closed.png` and `-open.png` (`design/tools/compose6.py`, as compose5 with the v6 front). Masks: `portal6/masks/front--<part>.png` (39 parts; new: `front--lamp_conduit_elbow.png`, `front--lamp_conduit_run.png`, `front--lamp_conduit_corner.png`, `front--lamp_conduit_strap.png`; `front--lamp_conduit_up.png` is shorter), plus `front--contact_shadow.png`, `front--GLASS_HOLE.png` and `front--ALPHA.png`.

**Layers in the game** (`layers/tools/install6.py`, install4's recipe on `layers/v6/`): the same atlas layout and regions as v5 (`placement.json` identical), with the column's new conduit top and the wall piece without the camera ghost; the far plate with the tank's rim; the mid plate unchanged (md5-identical to v5's).

## Current design: fix round 4 (v5), 2026-10-12

Fix round 4 (`design/tools/portal5.py`, `design/portal5/`) keeps the v4 model and closes what the round-4 review asked. The v4 section below still describes everything this section does not change. `DESIGN.round3.md` is the round-3 copy of this file.

| Review item | v5 design |
|---|---|
| must 1: the see-through slit in the near column | The near guide (three 50 mm angles, 120 mm on the jamb, standing 130 mm off the face) now has its **side return**: the angles' flange from the guide's front (t = -0.13 m) back to the jamb's channel frame (t = -0.02 m) at the guide's camera-side edge (a = A_N - 0.12), over the guide's full 3.05 m. v4 drew the guide's front and the jamb but not this return, which left a 6.9 design px (1.7 world px) gap at design x 456.5..463.4. The return is drawn before the jamb, so it fills exactly that gap and the jamb keeps its painted face. In the design the column has no transparent pixel from the guide's left edge to the chamfer over the guide's height except the lamp's glass (`portal5/spec.json`, `guide_return`). |
| should 3: two bays, two finishes (far plate) | No new geometry. The new bay (right of the seam column) takes the old bay's finish from main's own painted wall at the same pixels: its mottling and the drip stains under the pipe run, where the leak would reach. Its broad light (the pendant's pool, the seam match) is unchanged. Its chroma rises to the old bay's saturation, and the pendant's lens takes the corridor fittings' cool tint (`layers/tools/cleanup5.py`). |
| should 4: the beacon hangs on bare wall (far plate) | The lockdown beacon (the game's live drawing at far x 0.659) gets a real mount: a **0.35 x 0.28 m gunship-grey steel back box** right above its stalk, lit from the pendant above it, with a lid seam, four screws and a short soft shadow straight down the wall. A **25 mm conduit** runs from its top to the ceiling tray in two strap clamps and passes behind the hanging luminaire. |
| must 2: "the red seal" (game) | The guarded status lamp's live lens is **red while shut**, amber while the curtain moves and green open, as on the approved concept (`main.gd` `SEAL_LAMP_SHUT`). No art changes. |
| should 2: the MANUAL BYPASS plate (game) | The plate moves to stand over its wheel's hub (world x about 635.5..699.5, y 279..327). Its right edge stops left of the chain guard (x 702.5) and its bottom stops just above the COOLANT FAULT tag. Those two and the head of the engineer cranking it are why it cannot sit lower. A 1 px leader in the plate's edge colour runs from its bottom edge straight down at the hub's x to the backplate's top (y 384) (`bypass_handle.gd`). |

**Flat-shaded design render (v5):** `door-end-design-v5-closed.png` and `-open.png` (`design/tools/compose5.py`, as compose4 with the v5 front). Masks: `portal5/masks/front--<part>.png` (35 parts, the new one `front--guide_near_side.png`), plus `front--contact_shadow.png`, `front--GLASS_HOLE.png` and `front--ALPHA.png`.

**Layers in the game** (`layers/tools/install5.py`, install4's recipe on `layers/v5/`): the same atlas layout and regions as v4 (`placement.json` byte-identical), with the column's guide return and its closed internal seams; the far plate with the new bay's finish and the beacon's mount; the mid plate unchanged.

## Current design: fix round 3 (v4), 2026-10-12

Fix round 3 (`design/tools/portal4.py`, `design/portal4/`) keeps the v3 model and changes what the round-3 review asked. The v3 section below still describes everything this section does not change. `DESIGN.round2.md` is the round-2 copy of this file.

| Review item | v4 design |
|---|---|
| must 1: a slim near column, no silhouettes | The cross-wall now ends **0.16 m past the near jamb** (`A_END4 = A_N - 0.16`): its approach face is only the jamb's 160 mm steel channel frame. Its end face toward the camera is **0.50 m** of the wall's 0.66 m, and the last 0.16 m is a **45-degree chamfer faced with 10 mm steel plate** on the plant-room corner, a real armoured wall end. On screen, at 1 m height, the column (near guide, frame, end face, chamfer) spans clamp-world **x 790.1..817.5**. The v3 pier spanned 787..831. The engineer at the safe point (x 831, body from about x 820) and anyone using the safe point (it answers from x 824) stand clear of it. The status lamp and the push-button station stay on the end face, centred, at the same heights. The camera stays on the approach face, centred on it, at 4.35 m. Nothing is drawn over the column: the silhouettes are gone. |
| must 2a: the wall's line follows the plate's camera | The cross-wall is turned 17 degrees, so its horizontals run to **VP2 at x 21 on the horizon**, as the door, hood, bar and marks already do. The v3 cut band ran straight down the screen, which no line on this floor does. Past the column the wall is cut down to a **0.15 m concrete stub**: the section of the wall below the cutaway, which reads as a bund curb between the corridor and the plant room. Its top (the wall's full 0.66 m), its corridor-side face, a lit 65 mm steel edge angle on the corridor side and a 50 mm angle on the plant-room side run along the wall's own line, from the column's foot (795.9, 456.9) at slope **0.385** to VP2, and leave the view at the room's right edge (about y 520). The review's 0.93 is the floor's vanishing point, the slope a square-on wall would have; this wall is not square-on. The corridor's wet floor continues on the stub's approach side to the bottom right of the view. The plant room's dry slab is on its other side. In the far plate the two meet at t = 0.55 m across the wall, under the stub, so the far plate's parallax (up to 16 px at the edge of the view) never shows the join: the stub is 25-32 px wide. Footprint contact shadows run along both of the stub's feet and in front of the column's face. The stub's top is held about 10 luma over the brighter floor beside it, falling toward the camera, and its two angles above that, so the curb reads as the wall's cut line, not as a gap. |
| must 2b: the tank head in the plate's camera | The eye is 7.04 m up, the tank top 5.2 m, and the tank 42 m from the eye. So the rim is nearly edge-on: 2.2 source px (1.1 world px) of top surface at the centre. The **0.27 m dished head** shows as a low profile, 19.5 source px tall, above the rim. v3 drew a full ellipse 25 source px tall each side of the rim, about 11 times too open. The head is lit from high-bay B, 0.35 m above the crown and 2 m behind it: brightest on the upper curve, with a thin lit knuckle seam where it meets the shell. |
| bypass (should) | The handwheel's hub moves 1 px left and 2 px down to **(694, 400) = 1.0 m**. The crank stand point is unchanged (x 674), so the engineer's glove lands on the rim at about 8 o'clock. The gearbox's input boss moves with the hub. The rim is lifted to worn bare steel. |

**Flat-shaded design render (v4):** `door-end-design-v4-closed.png` and `-open.png` (`design/tools/compose4.py`; world x 676..984, y 150..560 at 2 px per world px; the far patch's design plate under it, with the v4 tank head). Per-part masks: `portal4/masks/front--<part>.png` (34 parts), plus `front--contact_shadow.png`, `front--GLASS_HOLE.png` and `wall--contact_shadow.png`. Every part's dimensions and job, and the column's and stub's screen numbers: `portal4/spec.json`. The far plate's floor split, wet floor and tank head are made in `layers/tools/cleanup4_far.py`.

**Layers in the game** (`layers/tools/install4.py`):
- far plate: as v3, with the floor split along the stub, the wet floor's soft reflection of high-bay B, the lifted slab, the cooled pool beside the column, and the v4 tank head;
- mid plate: main's plate with the old pipe column and pump erased, and the station contact shadows. The cross-wall is no longer in it. The plate is VRAM-compressed with main's settings, which the opening frames need, and its 5:6:5 blocks turned the concrete's grain into violet and green speckle;
- one lossless atlas `corridor-seal-atlas.png`, in this order of drawing:
  - **wall**: the cross-wall behind the walk line, with the bypass on it (z -3, right after the mid plate, shown with the corridor's plates);
  - **curtain**, **open** (the tucked bar), the rising curtain and **frame**: children of the door body, in that order, so they batch;
  - **column**, **camera** and **stub**, then the lamp lens, over the actors (one batch);
  - **wheel**.

## Current design: fix round 2 (v3), 2026-10-12

The round-0 bulkhead (section "Round 0" below, kept for the record in `DESIGN.round0.md` too) was rejected: it read as a door in a back-wall pier. Fix round 1 (v2, `design/tools/portal2.py`, `design/portal2/`) rebuilt it as the approved concept asks: a **cast-concrete cross-wall standing across the corridor**, its face turned 17 degrees toward the camera (the "slight angle"), with the rolling steel door in it, crossing the walk line at the collision face x 752, y 440. Fix round 2 (v3, `design/tools/portal3.py`, `design/portal3/`) keeps that model and changes what the round-2 review asked:

| Review item | v3 design |
|---|---|
| must-fix 2: the wall must cross the corridor | The near pier's end carries on as the wall's **cut section** (0.66 m, dark cut concrete with 65 mm steel arris angles) from the pier's foot (y 460) straight down past the bottom of the view (y 625), in the front layer, so it is in front of everything at walkway depth. Right of it the **plant room's own dry slab** (`design-slab-cvd.png`, far plate) runs to the bottom of the frame with saw-cut joints at 3 m and 7.5 m and one on the 900 grid line, all at the plate's vanishing point, meeting the plant floor behind at a steel joint. The corridor's wet floor ends at the cut. Contact shadows run down both sides of the cut. |
| must-fix 3: a wall-mounted bypass | A 10 mm steel **backplate** 0.58 x 0.68 m with four M16 anchors on the corridor wall at the cross-wall's corner (world x 685..708, y 384.5..411.5), a gunship-grey **worm gearbox** 0.46 x 0.41 m on it carrying the 0.525 m handwheel with its **hub at (695, 398) = 1.05 m**, and an enclosed **chain guard** 0.15 m wide running **straight up the wall** (x 702.6..708.4) in two U-clamps on stand-off brackets (y 334, 362) to the door operator's underside at y 307 (3.3 m). The floor stand, its diagonal shaft and its floor shadow are gone. The MANUAL BYPASS plate moves left (x 628..692) so the guard and the operator show. |
| must-fix 5: one layer, no pasted rectangle | The far column gets a pour joint at the head line (3.05 m). In the game, the whole near pier with its cut section is one sprite cut from the same pixels as the mid plate at the plate's 2 px per world px, so its edge over continuous concrete matches the plate. Fine grain (+-2.5 levels) on the large calm faces. |
| small 4: yellow floor line | 120 mm wide (the 60 mm line vanished at this scale), along the door line, scuffed where feet cross it. |
| small 5: reds | The push-button station's stop button is grey; the view's reds are the live lockdown beacons. |
| small 2, 3 (far plate) | Plant room regraded to the actors' values with a pool under its high-bay B; the tank's dished head lit from B above it (`layers/tools/cleanup3_far.py`). |

**Flat-shaded design render (v3):** `door-end-design-v3-closed.png` and `door-end-design-v3-open.png` (canvas CVD: world x 676..984, y 150..625 at 4 px per world px; the far patch's design under it). Per-layer renders `portal3/design-{wall,curtain,frame,front,slab-cvd}.png`; one mask per part in `portal3/masks/` (103 files: `<layer>--<part>.png`, plus `HOLE`, `GLASS_HOLE`, `contact_shadow`, `cut_shadow`, the text masks and `SPLIT-wall-upper`); every part's dimensions and job in `portal3/spec.json`. The paint step's edit target and area map are in `codex/paint-v3/refs/`.

**Layers in the game** (`layers/tools/install3.py`):
- far plate: the plant room, its tank, pump, catwalk and high-bays, the slab, the corridor bay wall and its luminaire, all behind the hole;
- mid plate: the cross-wall's parts behind the walk line with the doorway at alpha 0, the bypass on the wall, the near pier (also drawn as the front sprite), the station contact shadows;
- one atlas `corridor-seal-atlas.png`: curtain, tucked bottom bar, frame (far guide, hood, operator), front (near pier and cut, near guide, lamp socket and guard, push buttons, camera), lamp glass, handwheel.


## Round 0 (superseded): the bulkhead design

Scratch only. Follows `docs/research-2026-10/art-direction/REAL-LOOK.md` (sections 1-6 and the military-base section 8) and the measured hardware in `real-slice/anatomy/ANATOMY.md`. Everything here is drawn by Python from measured numbers; no image tool touched this step. Nothing was played by hand.

**Flat-shaded design render:** `door-end-design-closed.png` and `door-end-design-open.png` (world x 540..960, y 140..470 at the camera's right clamp, 2 px per world px). Per-piece renders and masks are in `portal/`, `far-patch/`, `stations/`, `mid-patch/` and `text/`.

## Scale, camera and anchors

- **Scale:** 1 m = 40 world px (engineer 69.6 px = 1.75 m). Room plates use 2 source px per world px. The door pieces and stations use 4.
- **Camera** (measured from the far plate's floor joints, `tools/common.py`): vanishing point at clamp-world (483.9, 158.5). The walkway is 38 m from the eye, so the view is nearly orthographic. The corridor back wall is 2.4 m behind the walkway (floor line y 423.3), and the machinery room's back wall is 8 m behind (floor line y 391).
- **Game anchors kept:**
  - floor y 440
  - seal collision face x 752 and the 56 x 132 body
  - `CORRIDOR_DOOR_LEFT_X`, relay x 605, safe point x 876
  - the labels and camera limits
- **Anchor changed:** the bypass wheel centre moves from (700, 405) to (700, 398), which is 1.05 m, inside the 0.9-1.2 m crank band. Its reach stays x-based, so gameplay is unchanged.
- **Scope:** x < 540 is untouched, so WOLF's cage and the opening are not in this work.

## Composition (how the approved concept was read)

The approved concept shows a heavy portal across the corridor, with the shutter's face seen at a slight angle and a different space glimpsed past it. At this camera a door plane truly across the walkway would project only about 27 px wide, too thin to read as a door. The design therefore uses REAL-LOOK's door rule instead: a **cast-concrete bulkhead** (front face at walkway depth, x 680..838, floor to the overhead rack) with the **door set into it**.

- The **"slight angle"** comes from the bulkhead's left return, the side face going back 2.4 m to the corridor wall (12 px), and the 0.5 m right reveal of the opening.
- No skewed leaves and no three-quarter frame.
- The space beyond is the machinery room Nathanial chose. It is painted once into the corridor's far plate, at the room's own vanishing point, lit by its own two visible high-bays. It shows through the doorway hole and right of the bulkhead, where the safe point stands at its gameplay position.

## Parts (full list with dimensions and jobs: `portal/spec.json`, `far-patch/spec.json`, `stations/spec.json`)

This table is the round-0 list. Where later rounds changed a piece, the current parts, dimensions and jobs are in `portal6/spec.json` (front: column, lamp and its conduit, push-button station, camera, stub) and the sections above; for example the camera now sits at 4.35 m on the column's approach face, not at 3.9 m on the return.

| Piece | Parts (one mask each) | Key real dimensions |
|---|---|---|
| Bulkhead frame (55 parts) | return, wall face, pour joints, corner angles, right reveal + **steel edge angle**, **steel threshold plate**, operator (bracket, body, motor, sprocket), chain guard + 2 clips, bypass backplate + 4 anchors + worm gearbox + blank arrow plate, push-button station (**lockable cover: backplate, hinge, lock**, 2 dark buttons + 1 red stop), guarded lamp (base, unlit globe, 3 guard bars), wall pack (conduit, body, lens), **fixed camera** (wall plate on the return, arm, housing, sunshield, dark window), **junction box** (backplate, box, hinge, padlock hasp, blank plate), operator feed conduit + strap, **3-conduit group into one welded penetration plate**, yellow floor line | 3.05 m opening (top y 318), 0.5 m wall, operator at 3.2 m, push buttons 1.6 m, lamp globe 0.18 m, camera housing 0.36 x 0.14 m at 3.9 m, penetration plate 6 mm with 150 mm margin |
| Curtain (moves) | slat face (2.65 px = 66.7 mm pitch), **bottom bar 115 mm with 45-degree yellow/black stripes**, rubber astragal | Gunship-grey slats |
| Front (over the actors) | 2 guides (4.5 px angle faces), hood 0.38 x 0.43 m, hood lip, idle-end bracket | |
| Handwheel (turns) | rim, 5 spokes, hub, spinner knob | 0.45 m (18 px); bare steel rim, grey spokes |
| Far patch (60 parts) | seam column (W360, base plate) hiding the join to the untouched plate; corridor back wall, dado, 3 service pipes + clamps, chain-hung vapour-tight LED fitting, beacon back-box + conduit (the live lockdown beacon hangs here); machinery room: cast wall with form joints, floor, truss chord, catwalk (deck, grey rails, posts, 2 columns on base plates), 2 pendant high-bays, pump skid (pad, base, motor, grey coupling guard, volute, riser, run, flanges, hanger), 1.4 x 5 m expansion tank on a plinth | Fixtures: corridor LED at (615, 190.5) 1.9 m back; high-bays at 4 m and 6 m back |
| Mid patch | old pipe column and hazard-striped pump erased below the rack right of world x 700; footprint contact shadows under the two station plinths. **No relay feed is drawn** (round 1's mid patch, `design/tools/mid_patch.py`, drew two 25 mm conduits from the ceiling rack to the relay's roof; the mid plate has been rebuilt from main's since round 3, `install4.py`, and they are not in the installed plate). The relay is fed from the floor through its plinth's brush-strip cable entry. | |
| Stations | approved Look 2 relay and safe point, pixels unchanged, on **36081-grey steel plinths** (200 mm / 100 mm) with 2 anchor heads and a dark brush-strip cable entry (cables up from the floor), contact shadow darkest at the contact line | Look 2 art at 4 px per world px |

## Military-base adaptation (REAL-LOOK section 8)

The earlier attempt's sound geometry is kept: door size, slat pitch, hood, guides, bypass gearbox, chain guard, push buttons, lamp, wall pack, reveal, threshold, the far patch and the station plinths. What changed:

- **Materials and colours.**
  - Cast concrete in neutral structural greys (36231) replaces the blue-teal wall.
  - The door slats, hood and guides are 36118 Gunship Gray.
  - Housings are 36081.
  - Bare steel appears only at worn edges.
- **One yellow, one red.**
  - The hazard bands on both guides are gone. Yellow is now only the door's caught-between marking: stripes on the bottom bar plus the floor line at the edge of the door's travel.
  - The catwalk rail and the pump's coupling guard are now grey.
  - The amber handwheel is now steel.
  - The only red is the emergency-stop button. The status lamp's colour is live, not painted.
- **Security hardware:**
  - a fixed camera on a wall arm watching the approach (static art, no glow);
  - a lockable junction box;
  - the operator feed and camera conduit grouped into one welded penetration plate;
  - a lockable cover on the push-button station.
- **The keypad spot** on the latch side at 1.2 m (y 392) is blank wall until Nathanial picks the PIN design.
- **Text** is typeset by `tools/text_layer.py` in the game's own Roboto (weight 700) with script-cut stencil bridges, then composited after cleanup. The image tool drew no letters, and every Codex prompt forbade lettering.
  - `SECTOR 4B`: a stencil in 37875 white, high on the bulkhead, 12 px cap height.
  - `DOOR 4B-07`: a stencil in 37875 on the fixed hood, so it does not scroll with the slats. It is 8.75 px cap height in Roboto Condensed Bold, because 12 px does not fit the 72 px hood.
  - Both marks are **proposed, awaiting Nathanial**. Everything else on the list is left off to keep the view calm. The junction-box plate is blank because a readable mark there would be under 8 px.

## Light (designed here, painted by Codex, nothing added at runtime)

- **Corridor end:** one chain-hung vapour-tight LED fitting (51 x 5 px) lights the new back wall and the relay side.
- **Door:** one LED wall pack over the hood lights the door face and the threshold. It is strongest on the hood and the upper door and falls off downward.
- **Machinery room:** two pendant high-bays. Their light reaches the corridor floor only past the bulkhead, fading in over 50 px.
- **Live elements:** the door's status lens (red shut, amber while moving, green open), the relay status light and the lockdown beacons. These are only lamp colours, plus three small glows (relay, seal lens, beacon), which is within the budget of at most 4.
- **Contact shadows:** generated from the footprints, darkest at the contact line, and baked into the floor (mid plate).

## What to know when reviewing

- The curtain image carries painted light from the wall pack, and the slats carry it with them as they rise for 1 s. A real face would keep the light still. This is accepted for the opening animation and listed in SLICE.md.
- `superseded-pre-military/` keeps the earlier attempt's design outputs and tools for comparison.
