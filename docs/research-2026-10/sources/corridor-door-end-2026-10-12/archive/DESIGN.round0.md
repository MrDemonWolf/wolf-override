# Corridor door end: construction design (step 1 of the real slice)

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

| Piece | Parts (one mask each) | Key real dimensions |
|---|---|---|
| Bulkhead frame (55 parts) | return, wall face, pour joints, corner angles, right reveal + **steel edge angle**, **steel threshold plate**, operator (bracket, body, motor, sprocket), chain guard + 2 clips, bypass backplate + 4 anchors + worm gearbox + blank arrow plate, push-button station (**lockable cover: backplate, hinge, lock**, 2 dark buttons + 1 red stop), guarded lamp (base, unlit globe, 3 guard bars), wall pack (conduit, body, lens), **fixed camera** (wall plate on the return, arm, housing, sunshield, dark window), **junction box** (backplate, box, hinge, padlock hasp, blank plate), operator feed conduit + strap, **3-conduit group into one welded penetration plate**, yellow floor line | 3.05 m opening (top y 318), 0.5 m wall, operator at 3.2 m, push buttons 1.6 m, lamp globe 0.18 m, camera housing 0.36 x 0.14 m at 3.9 m, penetration plate 6 mm with 150 mm margin |
| Curtain (moves) | slat face (2.65 px = 66.7 mm pitch), **bottom bar 115 mm with 45-degree yellow/black stripes**, rubber astragal | Gunship-grey slats |
| Front (over the actors) | 2 guides (4.5 px angle faces), hood 0.38 x 0.43 m, hood lip, idle-end bracket | |
| Handwheel (turns) | rim, 5 spokes, hub, spinner knob | 0.45 m (18 px); bare steel rim, grey spokes |
| Far patch (60 parts) | seam column (W360, base plate) hiding the join to the untouched plate; corridor back wall, dado, 3 service pipes + clamps, chain-hung vapour-tight LED fitting, beacon back-box + conduit (the live lockdown beacon hangs here); machinery room: cast wall with form joints, floor, truss chord, catwalk (deck, grey rails, posts, 2 columns on base plates), 2 pendant high-bays, pump skid (pad, base, motor, grey coupling guard, volute, riser, run, flanges, hanger), 1.4 x 5 m expansion tank on a plinth | Fixtures: corridor LED at (615, 190.5) 1.9 m back; high-bays at 4 m and 6 m back |
| Mid patch | old pipe column and hazard-striped pump erased below the rack right of x 700; **relay feed**: two 25 mm rigid conduits from the ceiling rack to the relay's roof (strut clamp, one coupling) | |
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
