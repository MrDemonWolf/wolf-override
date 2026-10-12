# WOLF//OVERRIDE bulkhead door v2

Generated with Codex built-in imagegen only. No API key, API generation, or CLI generation. References inspected: rejected doors-edge/compare.png, approved composite-1920.png and plate.png, engineer-side-idle.png. No Git repository was written.

## Deliverables

Five scenes: junction-closed.png, junction-opening.png, junction-blown.png, corridor-closed.png, corridor-open.png. Each is native 1672x941.

game-size.png contains five 960x540 scenes in a two-column grid. compare.png contains all five full-resolution scenes with captions outside the art. compose.py performs only user-requested resizing and sheet composition using Pillow; it does not generate or redraw art. Source size and sheet size assertions passed.

## Visual self-check

Each scene was viewed separately at 836x470 (50% width, rounded height). No text inside art.

| Scene | (a) Wall between places? | (b) Closed blocks walkway? | (c) Open means walk right? | (d) Nothing points into screen? |
| --- | --- | --- | --- | --- |
| Junction closed | Yes: dark ceiling-to-floor mass divides blue and amber panels. | Yes: slab reaches threshold. | Not applicable; right room is visible but blocked. | Yes: movement and barrier are side-on. |
| Junction opening | Yes: overhead wall mass and raised slab keep boundary clear. | Not applicable; lower half is open. | Yes: lit floor-level gap leads right; standing engineer must wait for further raising. | Yes: slab rises vertically within wall position. |
| Junction blown | Yes: remaining overhead mass and scorched cut edge mark boundary. | Not applicable; slab is removed. | Yes: clear floor beneath wall leads into amber room; bent leaf lies well to right. | Yes: no front-facing hole remains. |
| Corridor closed | Yes: thinner solid mass separates blue and dim teal spaces. | Yes: shutter reaches threshold. | Not applicable; shutter blocks route. | Yes: horizontal side-view walkway. |
| Corridor open | Yes: header mass divides differently paneled blue and bright teal rooms. | Not applicable; shutter retracted. | Yes: full-height empty gap and teal spill lead right. | Yes: no depth-axis doorway. |

Rejected generations were regenerated: oversized geometry; raised leaf incorrectly offset to right with original slab still blocking; blown hole drawn front-on in background. Final scenes pass the four spatial readability checks. Widths and aperture ratios are approximate generated art, not calibrated production geometry. Some header height, character position and framing drift across states; these are concept scenes, not pixel-registered animation frames. No game-engine collision or animation testing performed.

## Prompts

The initial generation and all corrective prompts are recorded verbatim below. Final selected results: junction closed after geometry correction; junction opening after new-generation gap prompt; junction blown after spatial correction; corridor closed after width correction; corridor open after full retraction edit.

### junction-closed

```text
Use case: stylized-concept. Create ONE full 16:9 game scene, requested 1672x941 or native landscape. WOLF//OVERRIDE 2D SIDE-VIEW CUTAWAY, orthographic side elevation like Inside/Another World. Input 1 approved background style; input 2 engineer identity and size reference. Graphic-painterly flat value planes, crisp silhouettes, cool steel, painterly only in lighting, NO dark drawn outlines. No text anywhere.
The player walks horizontally LEFT TO RIGHT on ONE horizontal walkway at y=74% of image. Small engineer in red jacket, charcoal trousers, brown short hair stands at x=40%, height 17% of image, facing RIGHT in exact side profile.
At x=54% a THICK SOLID STEEL BULKHEAD separating TWO distinct rooms. Its cross-section width on screen is 0.6 times engineer height (about 10% image height), never a pole. Black/dark flat cut-plane steel mass from the TOP EDGE down to the door aperture header; massive stepped-down header housing. Door aperture from walkway upward is 1.3 times engineer height. Raised low threshold plate. Wall and leaf viewed IN CROSS SECTION, traverse goes through wall LEFT TO RIGHT; no front-facing rectangular doorway, no depth-axis corridor, no perspective into the screen. Cyan edge rim on left-facing steel edges.
JUNCTION CLOSED STATE: thick vertical heavy steel slab completely fills aperture from threshold to header, slab same width as bulkhead cross-section, yellow-black chevrons along bottom edge. Small red status lamp on LEFT side beside slab.
Left room: approved plate's cool navy steel panels, horizontal utility pipes, cyan overhead blue lamp. Right room visibly different bronze-gray segmented industrial panels and amber work lamp, very dim with closed door. Floor and ceiling structures must visibly terminate at bulkhead and resume in different room. Keep everything side-on, strongly readable boundary. No other characters, no wolf, no control props, no labels, no arrows.
```

### junction-closed_refine

```text
Use case: precise-object-edit. Refine this side-view cutaway game scene. Preserve camera, composition, style and engineer identity. No text. Make engineer smaller: 160 pixels tall at 1672x941, feet on walkway y=690, stand left facing right idle. Rebuild central bulkhead cross-section: steel wall mass x=845..941 (96 pixels wide =0.6 engineer height), extends from top edge down to massive stepped header at y=482. Door aperture y=482..690, 208 pixels tall =1.3 engineer height. Heavy slab fills aperture completely x=845..941; chevrons bottom, small RED wall lamp on its left edge at y=535. Low threshold plate no trip-height pedestal. Absolutely side elevation, wall width is CROSS SECTION not front door face. Left blue steel room. Right distinct amber room with smaller segmented square panels, dim amber work lamp at 25% current intensity: closed state next room DIM. One horizontal walk right path, no perspective depth. Flat dark cut planes, crisp silhouettes and cyan rims, painterly light only, no outlines.
```

### junction-closed_geometry

```text
Edit only central wall geometry in reference. CRITICAL: lower the massive solid header all the way to engineer head height plus 30%. Engineer height 175px, feet y=680. The BOTTOM OF HEADER MUST BE y=450, NOT y=250. Solid opaque wall cross-section from TOP of canvas to y=450, full solid dark value mass. Only lower 230px from y450 to y680 is sliding door slab with bottom hazard stripe. Narrow wall overall to 105px width (0.6 human height). Red lamp at y520 on left of wall. Preserve engineer, rooms, side elevation and lighting. No text. This is a thick wall cutaway, no front-facing door. Door must be only 1.3 human heights tall.
```

### junction-opening

```text
Use case: precise-object-edit. Make JUNCTION OPENING state of this exact scene. Preserve geometry, engineer pose/size, camera, walls and style pixel-composition. Door aperture y430..665. Lift ONLY the sliding thick steel slab halfway UP into solid overhead housing: bottom hazard stripe now at y545, top inside housing. Bottom half aperture y545..665 must be completely EMPTY and show right room's background continuing through a horizontal left-to-right passage. Warm amber light spills UNDER lifted slab across threshold and walkway BOTH left and right. Intensify right room amber light. Red wall status lamp remains. Bulkhead solid cross-section stays full thickness 105px, dark flat planes with cyan rim, stepped header, low threshold. Entire action in side elevation, nothing points into screen. No text.
```

### junction-opening_correction

```text
Correct failed door edit. Reference has erroneous raised door to RIGHT of wall and original slab still closed. REMOVE erroneous rectangle x940..1140 y200..420 entirely, restore amber wall panels there. At x830..920, ORIGINAL doorway: REMOVE lower half of original slab y545..655, make EMPTY AIR revealing amber back wall through it. Keep upper half slab x830..920 y430..545, bottom yellow-black stripe at y530..545. Thus sliding leaf stays aligned DIRECTLY VERTICALLY underneath central bulkhead x810..940, half retracted into that header, NEVER shifted to right. Floor path goes horizontally through empty 110px-high gap underneath leaf. Warm light spills through that gap onto BOTH sides. Keep all other pixels/composition/engineer, red status light. No text.
```

### junction-opening_final

```text
Generate a new 1672x941 SIDE ELEVATION cutaway game scene matching reference style and layout. A red jacket engineer, small 175px high, stands left facing RIGHT on horizontal walkway. Blue room left, amber room right. Thick 105px wide steel bulkhead cross-section centered, solid dark mass descending from ceiling to low header 230px above walkway. JUNCTION DOOR HALF OPEN: bottom of sliding slab suspended 115px ABOVE floor. There is a VERY OBVIOUS EMPTY GAP at the BASE OF THE BULKHEAD where steel has lifted off floor. You can see amber wall behind this gap. Slab stays vertically aligned WITHIN wall thickness, half retracted UP into overhead housing. Yellow-black stripe on suspended BOTTOM edge directly above empty gap. Red lamp on left of wall. Amber light flows through gap and across both sides of threshold. No extra leaf to side, no solid steel beneath raised leaf, no floor-to-header pillar blocking gap. Side-on, passage direction purely horizontal left to right. Dark flat cut planes cyan rims, crisp graphic painterly steel like reference, no dark outlines or text.
```

### junction-blown

```text
Use case precise-object-edit. JUNCTION BLOWN state. Preserve exact reference side-on composition, engineer at left, blue room left amber room right. Remove ENTIRE lower sliding leaf below solid bulkhead header. Aperture now completely OPEN empty air from low header (1.3 human heights above walkway) to floor, so engineer can walk horizontally RIGHT under header into amber room. Scorch and bend doorway cut edges OUTWARD sideways, little gray smoke drifting right. Torn-out heavy door slab lies BENT HORIZONTALLY on floor well to RIGHT in next room, x1150..1420, recognizable yellow-black stripe, low enough to step over; keep threshold and aperture clear. Warm amber light spills through opening onto floor both sides. Red damaged status lamp on left wall. Bulkhead solid wall mass remains from ceiling down to low heavy header, width about0.6 human height. Flat dark planes cyan edge lighting. No front-facing door, no depth corridor, nothing points into screen, no text.
```

### junction-blown_final

```text
Fix spatial mistake: REMOVE the right-hand torn vertical edge at x1200 entirely and restore normal amber back wall panels there. The opening is ONLY the 105px-wide CROSS SECTION at x820..930 under the hanging bulkhead header. Remove remaining vertical steel post x810..845 below header so the wall has EMPTY AIR across its entire width below header down to floor. Burnt twisted metal ONLY attached to bottom of hanging header and small threshold, no upright jamb post. This is SIDE VIEW of a wall crossed left-to-right, NOT a hole punched in background wall. Keep bent fallen slab on RIGHT floor, engineer, light and smoke. No front-view arch or portal. No text.
```

### corridor-closed

```text
Use case precise-object-edit. Create CORRIDOR CLOSED variant of reference scene. Preserve side-view cutaway, engineer, blue left room and composition. Central solid wall cross-section and shutter are THINNER: overall steel thickness on screen 70px =0.4 engineer height. Massive solid dark steel from TOP to heavy low HEADER 230px above walkway. CLOSED shutter fills bottom doorway down to low raised threshold, yellow-black hazard bottom stripe, small RED lamp on LEFT face at engineer head height. Right next space is different small industrial wall panels with a muted TEAL work lamp, DIM because closed. Keep cut faces dark flat planes cyan rim lighting, crisp silhouettes graphic painterly light only. Door crossed horizontally LEFT TO RIGHT, no front-facing portal or depth corridor, no text.
```

### corridor-closed_final

```text
Narrow ONLY central entire bulkhead/shutter assembly in reference to HALF its current width, centered at same location. Current width140px must become70px, including solid ceiling-to-header wall mass and shutter. Engineer175px tall unchanged, so wall thickness0.4 human height. Restore matching blue/teal wall panels in vacated side strips. Lower header bottom to y430 so doorway230px tall. Keep red lamp, hazard stripe closed shutter, threshold, all else unchanged. No text.
```

### corridor-open

```text
Use case precise-object-edit. CORRIDOR FULLY OPEN. Reference central narrow70px bulkhead ceiling mass stays exactly. Retract ENTIRE lower shutter FULLY UP inside header housing. Below header all the way to low threshold is EMPTY AIR, no pillar, no upright door tracks across path. Engineer175px tall can walk RIGHT under low header into next teal room. Small status lamp changes RED to GREEN, mounted on LEFT edge of HEADER (because lower shutter gone). Show tiny hazard edge tucked immediately underneath header, NOT suspended down inside aperture. Right teal room lamp becomes bright and teal light SPILLS across empty passage onto walkway BOTH sides. Preserve camera, engineer, room panels, style. Pure side view horizontal passage, not front portal, no text.
```

