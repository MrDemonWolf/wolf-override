# WOLF//OVERRIDE: what reads as AI-made or unreal (audit, 2026-10-11)

Scratch audit. Nothing here changed a Git repository, made any art or ran Godot. Nothing was played by hand, so this file makes no claims about feel. Every judgement comes from one of four sources:

- the real captures in `r3-capture/shots/final-b/R1` (with R2-R4 checked for the same frames)
- the main capture `r3-capture/shots/r3c-main/R0/R0-002-room-opening.png`
- the shutter paste-ups in `shutter-assets/composites/`
- the code and PNGs at main `76d3a50`, read-only

Crops are in `crops/`. The measurements are in `props-measured.json`. The scripts that made both are in `tools/`.

## 0. Read this first: what the captures show

- **The `final-b` captures are not main.** They were taken from branch `codex/logic-round-3`: main plus `fa28229` "Add the opening's maintenance hatch art", plus logic commits. `r3-capture/game/` was overwritten at 19:44, after the shots were taken at 19:15, so that folder now holds different code from the build that made them.
  - The only art difference is the **opening hatch pod**: `opening-hatch-frame/leaf/duct.png`, `scripts/opening_hatch.gd`. It is the navy box with a lamp inside WOLF's cage in `R1-002`, `R1-010` and `R1-038` (`crops/o-01-branch-pod-shut-vs-open.png`).
  - **Main has no pod.** On main the opening is the cage and the folding gate, over the corridor's mid-plate tank and pump (`crops/o-00-opening-main-vs-branch.png`, left half).
  - Per rule 5, the cage and the opening must stay exactly as on main. The pod is the "opening hatch" Nathanial called slop, and it must not ship.
- **Corridor, Records and junction art in the captures is identical to main.** `git diff --stat 76d3a50 codex/logic-round-3` shows only three asset changes: the three `opening-hatch-*.png` files, `manifest.json` and `changelog.txt`. Every room plate, station, door and character PNG is the same as main. (`junction_room.gd`, `main.gd` and the sentry scripts also differ, but those are logic changes.)
- **Scale used throughout:** the engineer's opaque height is **69.4 world px**. Taking 1.75 m, that is **1 m = 39.7 px**, rounded here to 40.
- **Screen mapping for the captures:** screen = (world − camera) × 1.8 + (640, 360), with camera y 360. Floor y 440 is screen y 504.

## 1. Headline findings (most damaging first)

1. **Three projections in one frame.** This is the biggest "unreal" signal, and it shows in every room.
   - The far plates paint the floor in one-point perspective: tiles converge and lamp reflections streak toward the viewer (`crops/plates-corridor.png`, `plates-records.png`).
   - Every station is a flat front elevation.
   - The corridor seal and the junction blast door are three-quarter gate frames whose header recedes to the right (`c-04`, `j-03`, `j-04`).
   - The shutter mock-ups add a fourth: a leaf skewed diagonally across the floor (`sh-01`).
   - A real room seen from one camera has one projection.
2. **The "computer in the air" is real, and it is the corridor's PURGE display** (`c-01`).
   - It is a floor-standing console, with its own stepped plinth, placed with its base at **y 345.25, 94.75 px (2.4 m) above the floor**.
   - Nothing holds it up: no shelf, bracket, arm or cable. The mid plate's pipe column only passes behind it.
   - It sits entirely above the engineer's head (his top is at y 370.4).
   - It has no floor reflection or shadow (it is not in main's `grounded` list).
   - Every other sprite prop's painted base is within 0.3 px of y 440 (table in section 2).
3. **The other machines are on the floor line, but they don't read as standing on it.**
   - The contact shadow is a 12 px-tall radial ellipse at most 50% black, centred on the base line, so half of it is hidden behind the prop. On these dark floors it darkens almost nothing.
   - Measured on screen, the floor right in front of each base is **0.86-1.01× as bright as the floor 8-12 px further out** for the breaker, relay, safe point, mirror port, relief vent and entry hatch. That means no visible contact at all.
   - A real object on a floor shows a dark occlusion line at its foot.
   - On top of that, every prop gets an upside-down mirrored copy (`FloorReflection`, strength 0.32) on a floor that already has painted lamp streaks. Everything stands on glass, which reads as floating (`c-03`, `c-07`).
4. **The doors carry painted places inside them** (rule 2).
   - `corridor-bulkhead-open.png` and `junction-bulkhead-blown.png` each have a lit tunnel painted into the door.
   - The junction exit hatch draws `HATCH_PASSAGE`, a crop of the corridor door's tunnel, tinted.
   - So all three openings show **the same receding tunnel with lights down its left side** (`j-08`).
   - None of the doors is set into a wall. Each is a freestanding gate frame in front of a continuous wall (`c-04`, `j-02`, `r-04`).
5. **Light is painted and then stacked again at runtime** (rule 4).
   - The far plates already have each ceiling lamp's light cone and its floor reflection painted in.
   - `RoomDepth` then adds, per room, 3 additive lamp glows, 2 drifting shafts, 2 drawn beacons with 2 pulsing glows, a haze band and 42 dust particles.
   - On top of that come 3-12 `FloorReflection` pairs (mirror sprite + shadow, `_process` every frame) and a full-screen grade quad.
   - The painted light itself is an AI tell: light under each fixture falls as glowing vertical icicle streaks (`c-05`). The dust reads as soft white orbs hanging in the air (`c-02`, `o-02`).
6. **Pipes and cables that go nowhere** (`j-01`, `j-03`, `j-06`, `plates-junction.png`):
   - the valve's two elbows end in open flanges pointing down at nothing
   - the bolt panel's six cables leave both sides and stop in mid-air
   - the junction's central pipe drops end in small hand-valves in mid-air
   - the junction's mid plate has **frozen painted steam** coming out of nothing near the boiler; per rule 4 steam must be live
7. **Kitbash density with no hierarchy, mostly in the junction** (`j-01`, `j-02`):
   - rivets on every surface
   - three gauges on stems within one screen
   - hazard stripes on a horizontal process pipe (real pipes carry colour bands and flow labels, not hazard chevrons)
   - a hatch with a wheel standing in front of a boiler
   - a lattice truss, a junction box and a gauge on the same pipe run
8. **Scale is wrong against the engineer** (section 4).
   - The Records purge console is 2.8 m tall, with its work ledge at about 1.7 m, his eye level. A real operator desk is 0.75-0.9 m.
   - The corridor seal and junction door frames are 4.5 m tall, and the Records exit is a 3.5 m monolith.
9. **Parts that could not work** (section 3):
   - a handwheel on a lollipop post wired to the relay by a flat bar (`c-02`)
   - a breaker lever that never moves when it is thrown
   - an exit "door" with no hinge, track or handle
   - a 4.6 m unsupported feed line at knee height across the junction lane
   - at the Records chapter close, a flat navy rectangle with a grey outline drawn as the doorway (`r-05`)
10. **Repetition that gives the generator away:**
    - the corridor purge display is the Records purge queue (mean abs diff 16/255, same design)
    - the junction's overload breaker is the corridor breaker
    - the entry and exit hatches are one image
    - the corridor and Records near strips are almost the same file (mean abs diff 4.5/255; 3% of alpha differs)
    - the Records mid plate's corner machines repeat the corridor's (same box, tank and pump layout)
    - the same tunnel appears three times

## 2. Grounding: every machine, console, panel, handle, gauge and lamp

Floor y = 440.

- **Code base** is the sprite's region bottom (`position.y + region.h × scale / 2`).
- **Painted base** is the lowest row with alpha ≥ 128 inside the region.
- **Contact** is screen luminance just in front of the base divided by the floor 8-12 world px further forward: 1.0 means no darkening. The far reference includes painted lamp streaks, so treat it as a rough guide.
- "Shadow" is main's `FloorReflection` ellipse plus mirror.

| # | Item (room) | x | What holds it up | Code base | Painted base | Gap to floor | Feet in bottom 4 rows | Contact | Shadow / mount | Verdict |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | **Purge display** (corridor) | 158 | nothing. Its own floor plinth hangs in front of the mid-plate pipe column | 345.5 | 345.25 | **94.75 px (2.4 m)** | full plinth (99%) | n/a, the floor below is lit | **none**: no reflection, shadow, bracket, backplate or cable | **floating** |
| 2 | Breaker (corridor) | 350 | stepped feet with bolts | 440.01 | 440.01 | 0 | 99%, 1 run | 0.93 | ellipse + mirror | on the line, no visible contact |
| 3 | Coolant relay (corridor) | 605 | stepped base | 440.00 | 439.78 | 0.22 | 97% | 1.01 | ellipse + mirror | on the line, no visible contact |
| 4 | MANUAL BYPASS handwheel (corridor, code-drawn) | 700 | 8 px post, 26×4 px foot plate at 436-440, flat bar to the relay at hub height | 440 | 440 | 0 | foot plate | n/a | **no** reflection or shadow; the foot is a flat grey bar | touches, but reads as a sign post (`c-02`, `c-08`) |
| 5 | Safe point (corridor) | 876 | stepped pedestal | 440.02 | 440.02 | 0 | 98% | 0.90 | ellipse + mirror | on the line, faint contact |
| 6 | Seal bulkhead, sealed and open (corridor) | 785 | two jamb feet only (16% of width at the floor) | 440.00 | 439.70 | 0.30 | 2 feet | 0.81 | ellipse + mirror | stands, but freestanding in front of the wall |
| 7 | Purge queue (Records) | 190 | plinth | 440.00 | 439.73 | 0.27 | 100% | 0.72 | ellipse + mirror | grounded, best of the set |
| 8 | Mirror port (Records) | 520 | stepped plinth | 440.00 | 439.76 | 0.24 | 99% | 0.86 | ellipse + mirror | on the line, faint contact |
| 9 | Exit "hatch" (Records) | 830 | slab base | 440.00 | 440.00 | 0 | 99% | 0.67 | ellipse + mirror | grounded, but a monolith, not a door |
| 10 | Overload breaker (junction) | 200 | same art as #2 | 440.00 | 440.00 | 0 | 99% | 0.77 | ellipse + mirror | grounded (deck seam darkens it) |
| 11 | Relief vent (junction) | 300 | low housing, 16.3 px (0.4 m) tall | 440.00 | 439.90 | 0.10 | 98% | 0.96 | ellipse + mirror | on the line, no contact |
| 12 | Valve (junction) | 420 | two legs on a base plate | 440.00 | 439.80 | 0.20 | 66% | 0.80 | ellipse + mirror | grounded; its pipes connect to nothing |
| 13 | Valve handwheel (junction, cut disc) | 420 | the valve stem | n/a | n/a | wheel centre 45.8 px (1.15 m) up | n/a | n/a | n/a | fine height; its 0.93 m diameter is large |
| 14 | LINE gauge (junction, code-drawn over the painted dial) | 420 | a stem on the valve | n/a | n/a | n/a | n/a | n/a | n/a | grounded; it redraws a flat face over the painted one |
| 15 | Tank release / arm panel (junction) | 572 | two feet (57%) | 440.00 | 439.86 | 0.14 | 2 feet | **1.19 (lit from below)** | ellipse + mirror; the cyan alcove-floor rectangle under it lights the floor | reads as hovering on a lit pad (`j-07`) |
| 16 | Exit bolt panel (junction) | 806 | two feet (35%) | 440.00 | 439.85 | 0.15 | 2 feet | 0.80 | ellipse + mirror | on the line; its cables end in mid-air |
| 17 | Entry hatch (junction) | 80 | jamb feet (40%) | 440.00 | 439.79 | 0.21 | 2 feet | 0.91 | ellipse + mirror | freestanding frame in front of a boiler |
| 18 | Exit hatch (junction) | 880 | same image as #17 | 440.00 | 439.79 | 0.21 | 2 feet | 0.67 | ellipse + mirror | freestanding; the painted tunnel is borrowed |
| 19 | Blast door, sealed / breaking / blown (junction) | 480 | jamb feet (16-20%) | 440.00 | 439.70 | 0.30 | 2 feet | 0.65 | ellipse + mirror | stands; 3/4 frame, tunnel painted in |
| 20 | Tank + arm (junction) | 700 | ceiling plate on two 5 px drawn rods from the gantry at y 120, then a winch cable | n/a | n/a | n/a | n/a | n/a | n/a | hung, plausibly; the rods are code lines |
| 21 | Release → bolt feed line (junction, code-drawn) | 591-774 | **nothing**: a line at y 404 (0.9 m) across 183 px (4.6 m) | n/a | n/a | n/a | n/a | n/a | n/a | **unsupported**; it should run in a floor trench or a wall conduit |
| 22 | Status lamps (breaker, relay, purge, mirror, arm panel, bolt panel, hatches) | — | ColorRects / `_draw` rects over the painted lamp windows, plus additive glows | n/a | n/a | n/a | n/a | n/a | n/a | the old art already paints those lamps lit, so each is lit twice |
| 23 | Lockdown beacons (all rooms, code-drawn) | far layer | a 5 px stub bracket on the far plate | n/a | n/a | n/a | n/a | n/a | n/a | mounted, but they ride the 0.9 parallax, so they slide against the mid-plate columns |
| 24 | Ceiling lamps (all rooms, painted on the far plate) | — | painted fixtures | n/a | n/a | n/a | n/a | n/a | n/a | mounted; their light is painted and then added again at runtime |
| 25 | Painted gauges (junction mid: boiler top, junction box, small boiler) | — | stems on pipes | n/a | n/a | n/a | n/a | n/a | n/a | mounted; three in one view is greeble density |
| 26 | Sentry (junction) | lane | treads | 440 | — | — | — | — | ellipse + mirror ×2 | grounded |
| 27 | Containment cage (opening, code-drawn) | 115 | bottom rail drawn 441-451 | — | — | sinks 1-11 px | — | — | — | **keep exactly as on main (rule 5)** |
| 28 | Director (opening) | 255-310 | — | — | 445.2 | **sinks 5.2 px** | — | — | ellipse + mirror | feet below the floor (Look 2 character art, placement only) |
| 29 | WOLF (all) | — | — | — | 438.2 | 1.8 px above | — | — | ellipse + mirror | negligible |
| 30 | Engineer (all) | — | — | — | 439.8 | 0.2 | — | — | ellipse + mirror | grounded |

So, in answer to "why are the controllers and computers in the air": by the numbers, only one is truly in the air, the corridor purge display at 2.4 m. The rest touch y 440 to within a third of a pixel. They still look like they float, for four reasons:

- there is no occlusion line at their feet (the contact ratios above)
- each gets a full mirrored ghost under it
- each is lit with a cyan rim on both edges that separates it from the floor like a cut-out
- the floor under them is painted in perspective while they are flat elevations, so the eye can't place where on the floor they stand

## 3. Room by room

### Corridor (maintenance)

AI tells:

- **Lamp light as icicles** (`c-05`): light under each fixture falls in glowing vertical drips. A runtime additive glow and a drifting shaft sit on top.
- **Wall grime** (`c-06`): uniform drip stains from one horizontal seam, in an even band across the whole wall. There is no reason for water there (no pipe leak, no condensation source) and no wear at hand or foot height.
- **Station paint wear** (`c-03`): yellow flecks scattered evenly over the breaker and relay. Real wear sits on edges, the handle, the kick plate and around fasteners, not in random dots. Rust speckle is uniform over every face.
- **Lighting on the props:** a cyan rim on both silhouette edges plus a neutral frontal fill, while the room's only lights are cool overhead fixtures.
- **Floor:** wet gloss everywhere, plus a mirrored ghost of every station (`c-07`).
- **Dust:** 42 bright soft dots read as orbs (`c-02`, top).

Unreal:

- The purge display hangs at 2.4 m with no support (`c-01`).
- **The bypass** (`c-02`, `c-08`) is a code-drawn disc on an 8 px post, with a flat circular "collar" and a flat bar to the relay. It reads as a UI icon, not a valve handwheel on a pipe. A real manual bypass is a handwheel on a valve body inline on a pipe loop around the relay, or a crank on a gearbox.
- The breaker's knife lever sits behind a window in the cabinet front and never moves when the breaker "catches"; only a lamp rect changes colour.
- The seal is a 3/4 gate frame in front of a flat wall, with a lit tunnel painted inside (`c-04`).

### Records Access

AI tells:

- **Server racks** (`r-03`): every drawer has a scribbled label (text-like marks), with amber dots sprinkled at random. Real rack LEDs line up per unit, in columns.
- **A guard rail** stands in front of the racks at about 1 m and protects nothing.
- **Mid-plate machinery** at both ends repeats the corridor's.
- **The near pipe column** is almost the same file as the corridor's.
- **Neon:** the exit's full-height red neon slit (`r-04`) is a sci-fi glow with no function.

Unreal:

- **Purge queue** (`r-01`): 2.8 m tall, screen above the engineer's head, work ledge at his eye level.
- **Mirror port** (`r-02`): 2.8 m tall, with grab handles that loop into nothing.
- **Exit:** a 3.5 m slab with no hinge, guide track, handle or wall opening.
  - At the chapter close it lifts away entirely.
  - `RecordsRoom._draw_exit()` then draws a flat `#081b2b` rectangle with a 3 px grey outline and a green bar as the doorway (`r-05`). It reads as placeholder UI.

### Service junction

AI tells (`j-01`, `j-02`, `plates-junction.png`):

- **Overhead pipes:** a horizontal main with hazard chevrons painted on it, and vertical drops that end in small hand-valves in mid-air.
- **Gauges:** three gauge-on-stem greebles in one view.
- **Steam:** a plume frozen into the mid plate near the boiler.
- **Fasteners:** rivets at uniform density on every surface.
- **Blown door:** an evenly glowing orange "molten" rim along every torn edge, and random sheet shards hanging from the header. There is no debris on the floor and no scorching on the wall around it (`j-04`).
- **Repeats:** the entry and exit hatch are the same image, and the overload breaker is the corridor's breaker.

Unreal:

- **Valve:** the elbows end in open flanges pointing at the floor, so the valve is on no line. It controls nothing you can see (`j-03`).
- **Bolt panel:** six cables leave it and stop in mid-air (`j-06`).
- **Release → bolt feed:** a 4.6 m bare line at knee height across the lane.
- **Tank release:** stands on a translucent cyan pad, the alcove-floor rectangle, which lights the floor from under it (`j-07`).
- **Entry hatch:** a door frame stood in front of a boiler. You could not open a door into a pressure vessel (`j-02`).
- **Openings:** the blown door and the exit hatch open onto the same tunnel (`j-08`).
- **Deck:** the floor is a raised deck drawn in elevation with a hazard-striped fascia (`j-09`). That is consistent with itself, but different from the perspective floors of the other two rooms.

### Opening

- **On main** (`o-00` left): the code-drawn cage and gate over the corridor's mid-plate tank and pump.
  - The cage is flat-shaded vector art, unlike everything around it, but rule 5 says keep it exactly.
  - The Director's feet are 5.2 px below the floor (`o-02`). That is a placement offset, not art.
- **On the branch** (`o-00` right, `o-01`): the pod is the "opening hatch" Nathanial rejected.
  - It is a navy armoured box filling the cage, with bevelled corners and bolts.
  - Open, it shows a dark tunnel and a lamp that turns green.
  - Its saturated navy matches nothing else in the corridor.
  - It is not on main and must not reach main.

### Shutter mock-ups (`shutter-assets/composites`, `sh-01`, `sh-02`)

These fix the "is it a door" problem. They add new unreal reads:

- **Perspective:** the leaf is skewed across the floor in 3/4 view (hazard edge from y 432.5 to y 462.4), a fourth projection in a flat-elevation room.
- **Corridor open:** shows a whole new machinery hall with its own cool lamps and a tower (`sh-01` right), painted into the door's passage layer. Rule 2 says that space belongs to the room background behind a transparent opening.
- **Junction blown:** repeats the room's own hanging tank rig in the space beyond (`sh-02` right), with torn sheet shards at the top-left of the gap.
- **The shutter leaf** is a smooth gradient with no wear, dents or guide-rail marks, unlike the rough walls around it.
- **The bypass lollipop** is still there in every corridor mock-up.

## 4. Scale against the engineer (1 m ≈ 40 px)

| Item | Height px | Height m | Real-world reference |
|---|---|---|---|
| Engineer | 69.4 | 1.75 | — |
| WOLF | 61.2 | 1.54 (to the ear tips) | big; the story's call |
| Purge display (corridor) | 101 (top at 4.9 m) | 2.5 | a wall terminal is about 0.5 m, centred at 1.5 m |
| Purge queue / mirror port (Records) | 111 | 2.8 | an operator console is about 1.2 m with the desk at 0.75-0.9 m; a rack is 2.0 m |
| Breaker | 97 | 2.4 | a disconnect is 0.6-1.0 m on the wall, handle at 1.2-1.5 m |
| Coolant relay | 88.6 | 2.2 | plausible as a cabinet |
| Safe point | 111.5 | 2.8 | a save beacon pedestal; the lamp sits above head height |
| Valve | 97.8 | 2.45 (gauge top) | wheel centre 1.15 m is right; 0.93 m wheel diameter is large |
| Arm panel / bolt panel | 64.5 / 58.6 | 1.6 / 1.5 | right |
| Relief vent | 16.3 | 0.4 | right for a deck vent |
| Corridor seal / blast door frame | 180 | 4.5 | a heavy door frame is 2.4-3.0 m; the leaf opening (132 px) is 3.3 m |
| Records exit | 139 | 3.5 | a door is 2.1-2.4 m |
| Junction hatch | 144 (leaf 103) | 3.6 (leaf 2.6) | a pressure hatch leaf is about 2.0 m |

The Look 2 stations keep the same footprints, so scale has to be fixed in the layout pass, not by the painter.

## 5. Rendering: what is stacked at runtime (rule 4)

This answers "why are we rendering so much". Per room, from `room_depth.gd`:

- **Plates:** the far plate, the mid plate with 3 mirrored bleed strips, and 2 near strips.
- **Haze:** 1 haze band.
- **Lamp glows:** 3 additive lamp glows that flicker on tweens.
- **Shafts:** 2 drifting light shafts.
- **Beacons:** 2 drawn beacons and 2 pulsing beacon glows.
- **Dust:** 30 far + 12 near dust particles.
- **Reflections:** `FloorReflection` pairs with `_process` every frame: corridor 8, Records 3, junction 12 (23 in all).
- **Station glows:** 1-4 additive status glows per room.
- **Junction extras:** a `_draw` that redraws its lines, labels and markers.
- **Every frame:** the full-screen grade/vignette quad.

All three rooms are built at start. PLAN.md measures about 71 MB of resident textures (10-24 MB visible) and 55-114 draw calls.

What should be painted in instead:

- **Already painted, so drop the runtime copy:** the far plates already contain the lamp cones and their floor reflections. The runtime glows, shafts and haze duplicate them.
- **Replace with art:** the mirrored reflections and the radial-ellipse shadows can become one painted contact shadow (occlusion line plus a soft falloff) per prop.
- **Stays live:** status-lamp colour, the lamp flicker (a single modulate on the painted lamp, not a second glow), steam, sparks, the blast, the coolant cloud, and the sentry's eye.

## 6. What the approved Look 2 characters and stations do right

From `look2-hq/props`, `characters` and `notes.md` (sheets `crops/look2-props-sheet.png`, `look2-characters-sheet.png`):

- **One light, matte steel.** Each surface is three flat value bands plus one cool top rim, with no specular hot spots and no rust speckle or yellow flecks. The value sits inside the room's darks, so a station belongs to the room instead of glowing on top of it.
- **One accent hue per object,** where the function is: amber handwheel, cyan screen, green beacon. Nothing else is saturated.
- **Lamps are unlit sockets in the art.** The light is a separate tintable sprite (`status-lamp-*.png`), so nothing is lit twice.
- **Moving parts are separate parts:** valve wheel, gauge face and needle, tank and arm, each with attach points in `parts.json`. The wheel can turn, and the gauge has no painted needle to contradict the live one.
- **No text, scribbles or logos.** The screens are broad bars.
- **Clean silhouettes with hierarchy:** big shapes first, few fasteners. The bolt panel and valve still carry the "pipes out to the sides" motif, so their cable and elbow ends need endpoints in the layout.
- **Characters:** one side elevation, soft top-left key, cool rim, believable proportions. Feet are drawn as planted, with weight. They are the reference for how stations should be lit.

What Look 2 does not solve, and the layout pass must:

- **No floor or contact shadow in the art.** That was deliberate ("DO NOT ... floor, cast or contact shadow"), so grounding must come from a designed contact-shadow layer.
- **Footprints and heights are unchanged,** so the purge display is still a floor console and the scale problems stay.
- **The Look 2 doors are still freestanding 3/4 frames** with a baked `passage` tunnel (`crops/look2-doors-sheet.png`). Under rule 2 the passage layers should not be used.
- **None of it is in the game.** The game still runs the older rusty station art (`crops/00-prop-sheet.png`).

## 7. Fix list mapped to the rules (for the design-first pass)

1. **Rule 3, the purge display:**
   - Make it a wall terminal on a backplate, with two brackets and a conduit down into the floor or along the wall, at 1.2-1.7 m, about 0.5 m wide.
   - Or make it a floor console at the Records height, after the scale fix.
   - Either way, add it to the grounded list.
2. **Rule 3, everything on the floor:**
   - Give each station a painted contact shadow: a dark occlusion line a few px tall under the feet plus a soft falloff.
   - Drop the mirrored ghost, or make it far weaker and only on the wet area.
   - Draw feet with bolts into the deck.
   - Remove the cyan alcove pad from under the tank release, or make it a painted floor marking.
3. **Rule 3, wall items:**
   - The bypass becomes a handwheel on a real valve in a pipe loop from the relay down into the floor.
   - The release → bolt feed becomes a cable in a floor trench, or a conduit on the wall with clamps.
   - The bolt panel's cables, the valve's elbows and the junction's pipe drops each get a visible end: into the floor, the wall or a flange on another pipe.
4. **One projection:**
   - Side elevation for every door and station.
   - Show a door's depth only as a reveal inside the wall opening, not as a frame receding to the right.
   - Repaint the floors as a shallow strip with the same eye height, or move the stations to stand where the painted floor meets the wall.
5. **Rule 2:**
   - Door art is only frame, leaf and lamps.
   - The open area is transparent.
   - Each door sits in a wall opening, and the space behind it is painted once, as background. It must not be the shared tunnel.
   - Replace the Records `_draw_exit()` rectangle.
6. **Rule 4:**
   - Remove the runtime lamp glows, shafts, haze and dust where the plate already paints them.
   - Repaint lamp light as a falloff on the wall and floor, not icicles.
   - Make the painted steam live, or remove it.
   - Keep the lamp flicker as one modulate.
7. **Rule 1, wear and material:**
   - Wear only where hands, feet, water and heat put it.
   - No random flecks, no hazard chevrons on process pipes, no scribble labels.
   - Rack LEDs in columns.
   - One gauge where one is needed.
8. **Repetition:** give the junction its own breaker design; make the two hatches different, or show only one; don't reuse the near strip between rooms.
9. **Scale:** set heights from section 4 before anything is painted.
10. **Rule 5:** keep main's cage and gate pixel-identical, and keep the branch pod out.

## Files

Everything is under `real-slice/audit/`.

- **`AUDIT.md`:** this file.
- **`props-measured.json`:** per-prop code base, painted base, gap, footprint and size.
- **`tools/`:**
  - `measure.py`: prop bases
  - `contact.py`: contact luminance
  - `crop.py`, `runcrops.py`, `crops.txt`: crops
  - `sheet.py`, `sheet2.py`: contact sheets
  - `plates.py`: plate sheets with the walkway line
- **`crops/`, by room** (c = corridor, r = Records, j = junction, o = opening, sh = shutter mock-ups):
  - corridor: `c-01` … `c-08`
  - Records: `r-01` … `r-05`
  - junction: `j-01` … `j-09`
  - opening: `o-00` (main vs branch), `o-01` (branch pod), `o-02`
  - shutter mock-ups: `sh-01`, `sh-02`
- **`crops/`, plates and sheets:**
  - `plates-*.png`: far, mid and near plates with the walkway line
  - `00-prop-sheet.png`: the props in the game, with their regions
  - `look2-*-sheet.png`: the approved Look 2 art
