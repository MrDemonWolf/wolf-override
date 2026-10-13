# Anatomy of the corridor's door end: real hardware at game scale

Scratch research for the "design first, then paint" pass. Nothing in a Git repository or worktree was edited. Godot and Codex were not run for this job, and nothing was played, so this file makes no claims about feel. Every number below comes from a cited manufacturer sheet or standard, from the game's own code, or is marked **calc** (worked out here) or **est** (a design estimate with no source).

Drawings (made here with Pillow from plain shapes; no photos, no generated art), in `drawings/`:

| File | What it shows |
|---|---|
| `fig1-door-end-elevation.png` | The corridor door end, x 540..960, in game world px. Real hardware at real size around today's anchors. |
| `fig2-door-section-and-slats.png` | Rolling door section through the head and the sill, plus three real slat profiles at 4x. |
| `fig3-door-front-elevation.png` | The door face on: hood, guides, side room, operator, hand chain, keeper, push-button station, status strips, jamb striping. |
| `fig4-manual-override.png` | Wall-mounted handwheel on a gearbox (front and side), with the 0.9-1.2 m crank band. |
| `fig5-floor-cabinet.png` | Floor-standing cabinet on a plinth: anchors, brush-strip cable entry, roof conduits, handle, label band, contact shadow. |
| `fig6-wall-terminal.png` | Wall box terminal: brackets, display and control bands, conduit and strap spacing. |
| `fig7-marking-drains-tray-lights.png` | 45-degree safety bands, floor line, trench and point drains, ladder tray on a strut trapeze, luminaires. |

`tools/draw.py <out_dir>` regenerates all seven.

## 1. Scale: what a metre is in this game

Measured from `scenes/main.tscn` and the sprite's alpha at main 76d3a50:

- `Human` is at y 410 with a 28x60 hitbox, so the feet are at **y 440**.
- `BodySprite` is offset (0, -5), scale 0.188, texture `rowan-side-right-provisional.png` 256x384. Its alpha (> 16) spans rows 7..376.
- The visible engineer therefore runs from y 370.2 to y 439.8: **69.6 world px** from soles to the top of the head.
- At 1.75 m, **1 m = 39.8 world px** (1 world px = 25.1 mm). The art bible's D = 4 makes **1 m = 159 source px**.
- WOLF's visible sprite (rows 33..368 at 0.18325) is 61.4 px, so he stands about **1.54 m** high. A 2.44 m door clears him easily.
- At gameplay zoom 1.35, 1 world px is 2.7 screen px at 1080p and 1.8 at 720p. Anything under about 1 world px (a conduit, a strap, a bolt head) is a highlight line, not a shape.

Today's door-end anchors, which the anatomy below keeps:

| Thing | Where it is now | Real size it implies |
|---|---|---|
| Coolant relay art (approved Look 2) | x 562..647, y 351..440 (85 x 89 px) | 2.14 m wide (cabinet plus side pipe) x 2.24 m tall. That fits a 2.0 m cabinet on a 0.2 m plinth. |
| Manual bypass wheel | centre (700, 405); wheel radius 13.8 px; collar radius 17.5 px; post down to the floor | centre 0.88 m up; wheel 0.69 m across; collar 0.88 m |
| Seal door collision | x 752..808, y 308..440 (56 x 132) | the body is 3.3 m tall |
| Safe point art (approved Look 2) | x 841..911, y 328..440 (70 x 112 px) | 1.76 m wide x 2.81 m tall, a tall floor console |
| Room end, actor clamp | x 920, room 960 | |
| Ceiling pipe run on the corridor mid plate | y about 141 | 7.5 m above the floor: a high service hall |

## 2. Dimension tables (metres, world px, source px at D = 4)

Abbreviations: **spec** = manufacturer sheet, **std** = standard or regulation, **calc**, **est**. The bracketed numbers point to section 6.

### A. Commercial rolling steel service door

How it is built: a curtain of interlocking roll-formed steel slats (endlocks on the slat ends stop sideways creep) runs in two wall-mounted guides made of steel angles. At the top it winds onto a barrel that holds torsion springs. The barrel hangs between two end bracket plates bolted to the wall, and a steel hood closes over the coil. The bottom edge is a bottom bar (aluminium extrusion, or two steel angles back to back) with a rubber or PVC astragal that seals to the floor. Small doors are pushed up by hand. Bigger ones use a geared chain hoist, a crank, or an electric operator on the end of the hood. A motorised door keeps a hand-chain or crank override, electrically interlocked. Manual doors lock with slide bolts on the bottom bar. Chain-hoist doors lock with a padlockable chain keeper on the wall. [1][2][3][4][5]

| Part | Real | m | world px | src px | Kind |
|---|---|---|---|---|---|
| Opening, recommended (10 x 10 ft) | 3.05 x 3.05 m | 3.05 | 121.4 | 486 | design choice; within [1] range (max 30'4" x 28'4") |
| Opening, alternative (8 ft high) | 2.44 m | 2.44 | 97.1 | 388 | design choice |
| Slat F-265, flat (OHD 620) | 2-5/8 in rise, 5/8 in deep | 0.0667 / 0.0159 | 2.65 / 0.63 | 11 / 3 | spec [1] |
| Slat C-275, curved (OHD 610) | 2-3/4 in rise, 7/8 in deep | 0.0699 / 0.0222 | 2.8 / 0.9 | 11 / 4 | spec [1] |
| Slat C-600, heavy curved | 6 in rise, 1-3/8 in deep | 0.152 / 0.035 | 6.0 / 1.4 | 24 / 6 | spec [1] |
| Slat, Cookson ESD10 | 2-5/8 in rise, 3/4 in deep | 0.0667 / 0.0191 | 2.65 / 0.76 | 11 / 3 | spec [2] |
| Slat count for a 3.05 m opening | about 46 | | | | calc (3050 / 66.7) |
| Curtain gauge | 22 ga to 15'4" wide; 20 ga to 25'4"; 18 ga to 30'4" | | | | spec [1] |
| Hood headroom A, zone 1 (to about 8 x 8 ft) | 14 in | 0.356 | 14.2 | 57 | spec [2] |
| Hood headroom A, zone 2 (to about 10 x 10 ft) | 15 in | 0.381 | 15.2 | 61 | spec [2] |
| Hood projection B, zone 1 / zone 2 | 16 / 17 in | 0.406 / 0.432 | 16.2 / 17.2 | 65 / 69 | spec [2] |
| Side room C (idle side), zones 1-2 | 5 in | 0.127 | 5.1 | 20 | spec [2] |
| Side room D (drive side), zones 1-2 | 7 in | 0.178 | 7.1 | 28 | spec [2] |
| Hood material | 24 ga galvanised steel | | | | spec [1] |
| Coil diameter, 3.05 m door, rolled up | about 0.29-0.31 m | 0.30 | 11.5-12.4 | 46-49 | calc: D = sqrt(d0^2 + 4Lt/pi), d0 0.114 m (est), L 3.45 m, t 16-19 mm |
| End bracket (head) plate | 14-24 in square | 0.356-0.610 | 14-24 | 57-97 | spec [4] (head-plate detail) |
| Guide width on the wall (4-angle guide) | 3-3/4 to 5-1/4 in | 0.095-0.133 | 3.8-5.3 | 15-21 | spec [2] |
| Guide construction | three structural steel angles (OHD); four angles common with chain, crank or motor (Cookson) | | | | spec [1][2] |
| Curtain depth inside the guide | 2-1/4 in | 0.057 | 2.3 | 9 | spec [3] (sheet-curtain door; analogous) |
| Bottom bar | extruded aluminium to 15'4" wide; back-to-back steel angles over that; e.g. a 2 x 1-1/2 in, 12 ga angle | 0.051 x 0.038 | 2.0 x 1.5 | 8 x 6 | spec [1][3] |
| Astragal | bulb-type PVC or rubber on the bottom bar | about 0.03 | about 1.2 | 5 | spec [3] for type; size est |
| Locks | interior slide bolt (push-up); padlockable chain keeper (chain hoist); dual bottom-bar slide locks | | | | spec [1][3] |
| Manual push-up limit | up to 84 sq ft (7.8 m^2) or 12 x 7 ft; chain hoist above that | | | | spec [1] |
| Operator mounting height, exposed moving parts | at least 8 ft | 2.44 | 97.1 (y 343 or higher) | 388 | spec [4] |
| Operator mounting | front of hood, top of hood, or wall | | | | spec [4] |
| Operator body, bracket outline | 13-9/16 x 11-3/16 in | 0.344 x 0.284 | 13.7 x 11.3 | 55 x 45 | spec [4], read from a mounting figure |
| Push-button station | at least 5 ft up, in sight of the door, clear of moving parts | 1.52 | 60.5 (y 379.5 or higher) | 242 | spec [4] |
| Hand-chain keeper | about 4 ft up, in line with the chain | 1.22 | 48.6 (y 391) | 194 | spec [4] |
| Door status lights | LED strips on the frame sides, 5 ft lengths: solid red closed, flashing red moving, flashing amber before closing, solid green open | 1.52 | 60.5 | 242 | spec [6] |

### B. Wall-mounted manual override (handwheel or crank on a gearbox)

How it is built: a handwheel or crank turns a worm or bevel gearbox. Many easy turns become a few strong turns at the output, which drives the door's sprocket through a chain or shaft (or a valve stem). The gearbox bolts to a backplate anchored to the wall, or to the guide. A plate or the wheel itself carries a direction arrow. A spinner knob is added when the wheel must turn many revolutions. [4][7][8]

| Part | Real | m | world px | src px | Kind |
|---|---|---|---|---|---|
| Crank height, standing operator | 900-1200 mm | 0.90-1.20 | 35.8-47.8 (y 404..392) | 143-191 | std [7] 5.4.2.2.4.4 |
| Emergency / frequent controls | 860-1350 mm | 0.86-1.35 | 34.2-53.7 | 137-215 | std [7] 5.7.2.5 |
| Recommended wheel centre | 1.05 m | 1.05 | 41.8 (y 398) | 167 | design choice inside [7] |
| Bypass wheel centre today | 0.88 m | 0.88 | 35 (y 405) | 140 | code; just under the [7] band |
| Handwheel diameter range (valve operating elements) | 100-1000 mm | 0.1-1.0 | 4-40 | 16-159 | std [8] |
| Recommended handwheel | 400-500 mm | 0.4-0.5 | 15.9-19.9 | 64-80 | est inside [8] |
| Bypass wheel today | 0.69 m across (collar 0.88 m) | 0.69 | 27.5 | 110 | code |
| Crank handle, heavy loads (> 22 N), arm movement | turning radius 190-510 mm (under 100 rpm); grip 75-95 mm long, 25-38 mm across | | 7.6-20.3 | | std [7] fig. 11 |
| Direction marking | handwheels: arrows and legends; valves open counter-clockwise with double-ended arrows | | | | std [7] 5.4.2.2.5.4, 5.4.1.2.4 |
| Backplate | about 400 x 500 mm, 4 anchors | 0.4 x 0.5 | 15.9 x 19.9 | 64 x 80 | est |
| Stand-off of wheel from the wall | about 300 mm | 0.3 | 11.9 | 48 | est |

### C. Floor-standing control or relay cabinet

How it is built: a sheet-steel enclosure frame with a door (or doors), roof plate, rear panel and gland plates. It stands on a separate plinth (corner pieces plus trim panels). A base mounting plate lets the plinth be anchored to the floor without moving the cabinet. Cables come up from the floor through a brush-strip trim panel in the plinth, or down through the roof gland plate from a tray. [9][10][11]

| Part | Real | m | world px | src px | Kind |
|---|---|---|---|---|---|
| Cabinet (VX25 8806.000) | 800 W x 2000 H x 600 D mm | 0.8 / 2.0 / 0.6 | 31.8 / 79.6 / 23.9 | 127 / 318 / 96 | spec [9] |
| Other standard widths | 600, 800, 1200 mm | | 23.9, 31.8, 47.8 | | spec [9][10] |
| Sheet thickness, finish | 1.5 mm steel, dip-coat primer, textured powder coat RAL 7035; IP 54 depending on panels | | | | spec [10] |
| Plinth height | 100 or 200 mm | 0.1 / 0.2 | 4.0 / 8.0 | 16 / 32 | spec [11] |
| Cable entry | brush-strip trim panel in the plinth; gland plates | | | | spec [9][11] |
| Floor fixing | base mounting plate to the floor | | | | spec [11] |
| Labels on large cabinets | standing eye height, 1270-1650 mm | 1.27-1.65 | 50.5-65.7 | 202-263 | std [7] 5.5.6.3 |
| Door handle centre | about 1.0-1.2 m | | 40-48 | | est |
| Anchor bolts | M10-M12 through the base plate | | under 1 px | | est |

### D. Wall-mounted terminal or safe-point console

How it is built: a sheet-steel wall box with a door, mounting plate inside and four wall-mounting brackets screwed on from outside. Cables arrive in conduit through a gland at the bottom (to a floor box) or the top (to the tray). [12][13][7]

| Part | Real | m | world px | src px | Kind |
|---|---|---|---|---|---|
| Wall box (Rittal AX) | 600 x 600 x 210 mm, 22.3 kg, IP66 | 0.6 x 0.6 x 0.21 | 23.9 x 23.9 x 8.4 | 96 x 96 x 33 | spec [12] |
| Other AX sizes | 380 x 600, 600 x 380, 760 x 600 (x 210) | | | | spec [12] |
| Displays, normal | 1040-1780 mm | | 41.4-70.8 | | std [7] 5.7.2.2 |
| Displays, read precisely and often | 1270-1650 mm | | 50.5-65.7 (y 390..374) | | std [7] 5.7.2.3 |
| Controls, normal | 860-1780 mm | | 34.2-70.8 | | std [7] 5.7.2.4 |
| Controls, frequent or emergency | 860-1350 mm | | 34.2-53.7 | | std [7] 5.7.2.5 |
| Work surface | 900-930 mm | | 35.8-37.0 | | std [7] 5.7.2.1 |
| Box centre used in fig 6 | 1.45 m | 1.45 | 57.7 (y 382) | 231 | design choice inside [7] |

### E. Conduit and cable tray

How it is built: EMT conduit is strapped to the wall and runs into boxes through fittings. A ladder tray is two side rails joined by rungs. It hangs on trapeze supports (a strut channel across two threaded rods anchored in the ceiling). The NEMA span class sets how far apart the supports may be. Splices sit between a support and the quarter point of the span. [14][15][16][17]

| Part | Real | m | world px | src px | Kind |
|---|---|---|---|---|---|
| EMT 3/4 in, outside diameter | 0.922 in | 0.0234 | 0.93 | 4 | std ANSI C80.3 value, via search excerpt [18] |
| EMT 1 in, outside diameter | 1.163 in | 0.0295 | 1.17 | 5 | as above |
| EMT strap near a box | within 3 ft of every box, cabinet or fitting | 0.91 | 36.4 | 145 | std [14] |
| EMT strap interval | 10 ft or less | 3.05 | 121.4 | 486 | std [14] |
| Ladder tray side rail | 4 in or 6 in | 0.102 / 0.152 | 4.1 / 6.0 | 16 / 24 | spec [15] |
| Ladder tray width | 6-36 in | 0.152-0.914 | 6.0-36.4 | | spec [15] |
| Rung spacing | 9 or 12 in | 0.229 / 0.305 | 9.1 / 12.1 | 36 / 49 | spec [15] |
| Standard length | 12 ft | 3.66 | 145.7 | 583 | spec [15] |
| Support span by NEMA class | 8, 12, 16 or 20 ft (A/B/C = 50/75/100 lb/ft) | 2.44 / 3.66 / 4.88 / 6.10 | 97 / 146 / 194 / 243 | | std [16] |
| Expansion joint support | a support 2 ft each side | 0.61 | 24.3 | 97 | std [17] |
| Vertical tray runs | supported at 20 ft or less | 6.10 | 242.8 | | std [17] |
| Strut channel (P1000) | 1-5/8 x 1-5/8 in, 12 ga | 0.041 | 1.6 | 7 | spec [19] |

### F. Industrial luminaires and status lamps

How they are built: a corridor or plant room uses sealed linear vapour-tight fittings (polycarbonate lens and housing, gasketed), surface-mounted or chain-hung from the structure or tray. A status lamp is a small cast box with a glass globe in a wire or cast guard (a "jelly jar"), fed by conduit. A door's own status signal is usually LED strips on the frame or a compact red/green signal head. [20][21][6]

| Part | Real | m | world px | src px | Kind |
|---|---|---|---|---|---|
| Vapour-tight LED, 4 ft (Lithonia CSVT) | 50.3 x 5.4 x 3.8 in | 1.278 x 0.137 x 0.097 | 50.9 x 5.5 x 3.9 | 203 x 22 x 15 | spec [20] |
| Vapour-tight LED, 4 ft (Lithonia XVML) | 47-13/16 x 4-1/2 x 3 in | 1.214 x 0.114 x 0.076 | 48.3 x 4.5 x 3.0 | | spec [20] |
| Globe guard, small (Hubbell VAG-100) | 4-1/4 x 4-1/4 x 7 in | 0.178 tall | 7.1 | 28 | spec [21] |
| Globe guard (Hubbell VMAG17) | 7-21/32 x 6-3/4 x 6-3/4 in | 0.194 tall | 7.7 | 31 | spec [21] |
| Globe guard, large (Hubbell VMAG25S) | 9.65 x 8.25 x 8.25 in | 0.245 tall | 9.8 | 39 | spec [21] |
| Door status strip | 5 ft on each frame side | 1.52 | 60.5 | 242 | spec [6] |

### G. Safety marking

| Rule | Value | world px | Kind |
|---|---|---|---|
| Hazard stripes | about 45 degrees, bands 1:1. Yellow/black for permanent obstacles and crush, impact or fall points; red/white for temporary ones. At shear and crush points with relative motion, the stripes on the two parts run opposite ways. Size the marking to the obstacle. | | std [22] ASR A1.3 5.2 |
| Meaning by colour pair | yellow/black hazard; red/white prohibition or fire equipment; blue/white mandatory; green/white safe condition | | std [23] ISO 3864-1 via summary |
| Floor line for traffic routes | at least 5 cm wide, white or yellow, contrasting with the floor | 2.0 | std [22] ASR A1.3 5.3 |
| Aisle lines (US) | 2-6 in recommended, any width of 2 in or more accepted, any colour that defines the aisle; yellow is usual | 2.0-6.0 | std [24] OSHA 1972 letter |
| Stripe band width | no fixed value found; 50-100 mm suits a door jamb | 2.0-4.0 | est |

### H. Floor drains

| Part | Real | m | world px | src px | Kind |
|---|---|---|---|---|---|
| Trench drain (ACO KlassikDrain K100) | 100 mm clear, 130 mm overall, grate flush; precast invert slope 0.5% or neutral; walls at least 13 mm | 0.13 | 5.2 | 21 | spec [25] |
| Point floor drain strainer (Zurn Z415) | 5 x 5 in or 6 x 6 in, nickel bronze, heel-proof | 0.127 / 0.152 | 5.1 / 6.0 | 20 / 24 | spec [26] |

## 3. What this means for the door end (applied, see fig 1)

These keep every code anchor (collision face x 752, `CORRIDOR_DOOR_LEFT_X`, follow limits, labels) unless a line says otherwise.

1. **The door is a door, at door size.** A 3.05 x 3.05 m service door puts the opening top at **y 319** and the hood at **y 304..319** (A 15 px), 17 px deep. The guide face stays at x 752. The 2.44 m option (top at y 343) matches the "1.4x the engineer" brief better, but the code's 132 px body (3.3 m) fits the 3.05 m door more naturally. Either is real. Everything above the hood is wall, lintel, the tray and lights, not more door.
2. **Slats at real pitch.** A 66.7 mm slat is 2.65 world px (about 11 source px at D = 4, 7 screen px at 1080p). That is about 46 slats on a 3.05 m door or 37 on a 2.44 m door. In the approved concept (`doors-shutter-approved/game-size.png`) the engineer is 105 px tall and the leaf is about 5.7 m tall in those units, with roughly 20 slats of about 0.28 m each. That is about four times real pitch, and it is one reason the door reads as a prop.
3. **The leaf disappears into a hood.** A real curtain winds onto a coil about 0.3 m across inside a plain 24 ga box. It does not slide up behind a frame. The open art shows the bottom bar tucked just under the hood.
4. **Guides are angles on the wall,** 4-5 px wide, with endlocks inside them. They are not deep pillars. Side room is 5 px on the idle side and 7 px on the drive side.
5. **Every control is connected to something.** The operator sits on the hood bracket at 2.44 m or higher, with a hand-chain loop down to a keeper at 1.22 m (y 391). The OPEN/CLOSE/STOP station is at 1.52 m or higher (y 379 or above), in sight of the door. The MANUAL BYPASS wheel's drive runs up a chain guard to the door's sprocket, so turning it visibly moves the door. If the design wants the bypass to vent coolant instead, make it a gear-operated valve on the relay's pipe, carried by pipe supports.
6. **The bypass wheel should move up and shrink.** Real cranks sit 0.9-1.2 m up (y 404..392); the code has 0.88 m (y 405). A 0.4-0.5 m wheel is 16-20 px; today's wheel is 27.6 px (0.69 m). A backplate with four anchors replaces the code-drawn post, or the post gets a real base plate and anchors.
7. **Stations keep their approved designs and gain a base and a feed.** The relay (85 x 89 px) reads as a 2.0 m cabinet: give it a 200 mm (8 px) plinth with anchors and a brush-strip entry, run conduit from its roof to the tray, and turn its side pipe down to a floor flange. The safe point (70 x 112 px) gets a 100 mm (4 px) plinth with anchors and a conduit. Every base gets a 1-2 px contact shadow.
8. **Lights come from fixtures you can see.** Vapour-tight fittings are 51 x 4 px, chain-hung under a ladder tray at about 5 m (y 241), with hangers at most 146 px apart. Any painted pool or wall wash must sit under one of them. A door status lamp is a guarded globe about 8 px tall. The concept's red lamp is about 0.96 m tall, roughly five times real. Only its colour changes at runtime.
9. **Marking and water.** A yellow floor line at least 2 px wide crosses the threshold. Yellow/black 45-degree bands (2-4 px each) go on the lower guides, mirrored on the two sides. Coolant and wash water need a 5 px trench grate or a 6 px square drain in front of the relay, with the wet sheen falling towards it.

## 4. AI tells to hunt for (reviewer checklist)

- Slats several times real pitch (more than about 3 world px), or a leaf with no visible hood, coil or guides.
- Lamps, bolts, rivets or vents that are 3-5 times their real size against the 69.6 px engineer.
- Machines that stop above the floor line, sit on nothing, or have pipes and cables that end in the air.
- Symmetric greeble panels, glowing seams or vents with no function, or text-like squiggles.
- Light with no fixture, a haze cone in a sealed room, or rim light on every edge.
- Wear in the wrong places. Real wear goes on the bottom bar, guide feet, handle edges, the floor at the threshold and drain, and drips under the relay's pipe flange.
- Hazard stripes that are not about 45 degrees, have unequal bands, or are on surfaces that cannot hurt anyone.
- Mismatched perspective between the door, its wall and the floor (the door must sit in the wall plane with a real space behind its hole).

## 5. Limits and open points

- I could not read Table IX (handwheel dimensions) of MIL-STD-1472F; it is an image in the copy found. The handwheel range comes from EN 12570's scope (100-1000 mm) as summarised by BSI. The 400-500 mm pick is mine.
- A search excerpt credited AUMA GS 40.2-125.2 gearboxes with handwheels of 250-500 mm. The data sheet would not download, so that figure is not used as a source.
- The C-187 slat depth in the OHD brochure did not extract cleanly, so it is left out.
- Hood headroom and projection rows are Cookson ESD10 values; other makers differ by a few inches (Cookson's own range for service doors is 15-19 in [27]).
- EMT outside diameters are ANSI C80.3 values seen only in search excerpts; at under 1.2 world px they do not change any drawing.
- Handle height, anchor size, astragal size, backplate and stand-off are estimates, marked **est** above.
- "Scale" measures the provisional `rowan` sprite in main. If the Look 2 engineer frames replace it at a different height, redo section 1 and divide every px value by the same factor.

## 6. Sources

1. Overhead Door Corporation, "Rolling Service Doors 610/620" brochure, C900-103 08/23: https://overheaddoor-production-assets.azureedge.net/assets/docs/default-source/commercial-products/rolling-service-doors/model-610/rolling-service-doors-610---620-brochure.pdf?sfvrsn=fa39521_11 (sizes, gauges, slat profiles, hood, guides, bottom bar, astragal, locks, operation).
2. Cookson (CornellCookson), "Service Door Model ESD10 Technical Details", 6.2017: https://www.cooksondoor.com/docs/default-source/1v-data-sheets/technical-details-sheet/cookson/td_rolling_door_k.pdf?sfvrsn=b0a9476d_32 (zone table A/B/C/D, slat 2-5/8 x 3/4 in, guide options).
3. Janus International, "Model 1100" specification, 05.14.10: https://www.janusintl.com/hubfs/janus_2019/pdf/model1100.pdf (2-1/4 in guide depth, bottom bar angle, PVC bulb astragal, slide locks, chain keeper). This is a sheet-curtain door, used only by analogy.
4. Overhead Door, RSX operator installation manual: https://overheaddoor-production-assets.azureedge.net/assets/docs/default-source/general-products/commercial-operators/rsx-operator-rolling-steel-installation-instructions.pdf?sfvrsn=5f63ce90_3 (8 ft operator height, 5 ft control height in sight of the door, keeper about 4 ft, mounting options and bracket outline). Also the RHX NEMA manual: https://overheaddoor-production-assets.azureedge.net/assets/docs/default-source/owner's-manuals/operator-rhx-nema-manual.pdf?sfvrsn=f0e67fb7_2 (head-plate sizes 14-24 in).
5. Overhead Door, RHX product page (front of hood, top of hood, bench and wall mounting): https://www.overheaddoor.com/general-products/rhx-commercial-door-operator
6. Cisco-Eagle, "Overhead Door LED Safety Light System": https://www.cisco-eagle.com/product/193897/overhead-door-led-safety-light-system-for-powered-doors-four-5-led-strips (5 ft strips on the frame; red, flashing red, flashing amber, green).
7. MIL-STD-1472F, Human Engineering (1999), copy at http://mreed.umtri.umich.edu/trucksteps/documents/MIL-STD-1472F.pdf (5.4.1.2.4, 5.4.2.2.4.4, fig. 11, 5.4.2.2.5, 5.5.6.3, 5.7.2.1-5.7.2.5).
8. EN 12570, Industrial valves: method for sizing the operating element (BSI summary): https://knowledge.bsigroup.com/products/industrial-valves-method-for-sizing-the-operating-element (scope 100-1000 mm, including gearbox-mounted).
9. Rittal 8806.000 VX25 baying enclosure, 800 x 2000 x 600 (distributor listing): https://standardelectricsupply.com/Rittal-8806000-Baying-Enclosure-System
10. Rittal VX 9680.806 product data (1.5 mm steel, RAL 7035, IP 54): https://www.rittal.com/pdf-creator/variant/ca-en/9680806
11. Rittal VX25 accessories, base/plinth system (100/200 mm, trim panels with brush strip, base mounting plate): https://rittal.com/com-en/products/PG0002SCHRANK1/PG0026SCHRANK1/PGRP21063SCHRANK1/PGRP26364SCHRANK1/PG23113001ZUB
12. Rittal AX wall box 600 x 600 x 210, RS 202-3917: https://my.rs-online.com/web/p/wall-boxes/2023917 (and AX 380 x 600, 760 x 600 listings on the same site).
13. MIL-STD-1472F, as [7], for the display and control bands.
14. NEC 358.30 (EMT securing and supporting), as explained by EC&M: https://www.ecmweb.com/national-electrical-code/qa/article/21270216/stumped-by-the-code-nec-requirements-for-using-and-installing-emt
15. B-Line (Eaton) ladder cable tray listings, e.g. https://steinerelectric.com/Catalog/ConduitFittings-And-Wireway/Cable-Trays-And-Struts/Cable-Trays/Ladder-Cable-Trays/B-Line-24A12-12-144-CABLE-TRAY-501833 and the Eaton metric ladder page https://www.eaton.com/us/en-us/catalog/support-systems/metric-cable-ladder.html (rails, widths, rung spacing, 12 ft lengths; read through a search summary).
16. Agilix, "Understanding NEMA standards for cable tray systems" (NEMA VE 1 span/load classes): https://www.goagilix.com/blog/understanding-nema-standards-for-cable-tray-systems/
17. NEMA VE 2 installation guidance as quoted in a manufacturer spec (splice location, 2 ft at expansion joints, 20 ft vertical): https://dam.atkore.com/api/public/content/5d57a58ed81a4f53a4d290c81c11d56e (read through a search summary).
18. ANSI C80.3 EMT outside diameters, search excerpt only (no primary page opened).
19. Unistrut P1000 channel, 1-5/8 x 1-5/8 in, 12 ga: https://graybar.com/p1000-series-solid-strut-channel-12-ga-steel-extruded-aluminum-10-ft-l-1-5-8-h-x-1-5-8-w-in-/p/92126303
20. Lithonia CSVT and XVML vapour-tight listings: https://elliottelectric.com/P/Item/LIT/CSVTL48AL03MV0LT and https://www.elliottelectric.com/P/Item/LIT/XVMLL485000LMMV0
21. Hubbell/Killark globe guards: https://standardelectricsupply.com/Hubbell-VMAG17-Vaporproof-Globe-Guard, https://dixonelectric.ca/products/18-lighting/02-fixtures/03-hazardous-location-vapor-tight-fixtures/02-special-environment-lighting-fixture-accessories/p-S0lMVk1BRzI1Uw==-hubbell-vmag25s-vm-7-34-stainless-guard-lo, https://dixonelectric.ca/products/18-lighting/02-fixtures/03-hazardous-location-vapor-tight-fixtures/02-special-environment-lighting-fixture-accessories/p-S0lMVkFHMTAw-hubbell-vag-100-guard-aluminum-guard-copperfree-aluminum-grayepoxy
22. ASR A1.3 (German workplace rule), section 5: https://vorschriften.bgn-branchenwissen.de/daten/tr/asr_a1_3/5.htm (45 degrees, 1:1 bands, yellow/black permanent, opposite stripes at crush points, floor lines at least 5 cm).
23. ISO 3864 summary: https://en.wikipedia.org/wiki/ISO_3864 (45-degree safety markings and colour meanings; the standard itself was not opened).
24. OSHA interpretation, 15 May 1972, aisle markings: https://osha.gov/laws-regs/standardinterpretations/1972-05-15 (2-6 in, 2 in or more acceptable).
25. ACO KlassikDrain K100: https://www.acodrain.com.au/drain/pdf/klassikdrain.pdf and https://www.buildsite.com/pdf/aco/KlassikDrain-K100KS100-Steel-Edge-Rail-Channel-System-4-internal-width-Spec-Data-2914681.pdf (read through a search summary).
26. Zurn Z415 floor drain spec sheet: https://www.webstaurantstore.com/documents/specsheets/z415s_specs.pdf (read through a search summary).
27. Cookson, "How much headroom do you need for a roll-up door?": https://www.cooksondoor.com/blogs/Cookson/roll-up-door-headroom

Game facts: `apps/game/scenes/main.tscn`, `scripts/main.gd` (`BYPASS_WHEEL`, `CORRIDOR_DOOR_LEFT_X`, `RELAY_X`), `scripts/bypass_handle.gd`, `scripts/junction_room.gd` (`VALVE_WHEEL_RADIUS`, `VALVE_SCALE`), the sprite PNGs at main 76d3a50, and the earlier `shutter-assets/MEASURE.md` and `LAYERS.md`. Concept measurements come from `docs/research-2026-10/sources/doors-shutter-approved/game-size.png`.
