# Review, round 1: the corridor's door end (independent, adversarial)

**Verdict: fix needed. Do not show this to Nathanial yet.**

I reviewed the after-shots in `raw/slice/` at full size, in 3-6x crops and in greyscale. For each one I compared the same frame from `raw/main/` as a first-time player would. I ran REAL-LOOK section 3 on the in-game captures. I also re-measured one frame pair myself, re-diffed the opening, checked C2PA on the Codex originals, and checked the installed layers pixel by pixel.

- **Scope:** scratch only. I edited nothing in `real-slice/` except this file.
- **My evidence:** crops, greyscale copies, the probe script and its output are in `scratchpad/review-r1-work/`.
- **Validation:** nothing was played by hand, so I make no feel claims.

The doorway is a real hole onto a real, painted machinery room. The door itself is built like a real rolling steel door. Even so, the piece has eight problems that a first-time player or Nathanial would see. Two of them are compositing artefacts of the kind he calls slop.

## What holds up (verified, not taken from the report)

- **The hole.** Mid plate x 1504..1606, y 533..768 is alpha 0 everywhere. Behind it, the far plate shows its own machinery room: a pump on a skid piped to the expansion tank, with its own pendant fittings. It is not a tunnel and not a copy of another room.
- **The door's construction.** The slats are at real pitch, with a hood, guides, a striped bottom bar and a steel threshold. The curtain winds up into the hood, and the bar stays tucked under it when open. It reads as a real rolling steel door.
- **Look 2 stations.** Every fully opaque Look 2 pixel is unchanged: relay at offset (16,0) and safe point at (16,0), with 0 differing pixels. Only the semi-transparent edges were composited onto the plinths.
- **Text.** `SECTOR 4B` and `DOOR 4B-07` are typeset, with visible stencil bridges, and both are on the approved list. Nothing in the Codex art reads as lettering.
- **Nothing from the films.** There is no Skynet, Terminator or Cyberdyne name, logo, machine or styling. The camera is a generic box camera on a wall arm.
- **Opening (rule 5).** My own diff of o0..o8 agrees with the report:
  - o0..o6: every differing blob is at most 42 px and darker in the slice. That is main's dust. Nothing else differs.
  - o7 and o8: everything differs only right of screen x 994, past world x 540 at screen x 972.
- **C2PA and provenance.**
  - All four used Codex outputs carry a `caBX` chunk with a JUMBF `c2pa` manifest (claim v2, actions v2, hash.data).
  - They are byte-identical to the files in `~/.codex/generated_images/`, and their sha256 values match `provenance.txt`.
  - All three sessions are in `~/.codex/archived_sessions/`.
- **Render numbers reproduce.** I wrote my own probe (`review-r1-work/review_probe.gd`) on the same machine, with another session's Godot process running at about 290% CPU, so frame times are noisy:

| State | Draw calls (main -> slice) | Texture MB | Video MB | Frame ms p50 / p99 | Render CPU p50 | World sprite coverage |
|---|---|---|---|---|---|---|
| s1 door end at rest | 72 -> 57 | 72.0 -> 69.9 | 78.3 -> 76.3 | 2.67/7.39 -> 2.06/7.38 | 0.52 -> 0.44 | 3.63 -> 3.24 |
| s5 door open | 71 (max 75) -> 56 (max 60) | 76.7 -> 69.9 | 83.0 -> 76.3 | 2.77/7.88 -> 2.14/7.42 | 0.56 -> 0.46 | 3.57 -> 3.16 |

- Dust emitters go from 2 to 0, and the haze band is gone from the list of items covering half the view. Both match SLICE.md.
- Frame-time changes are inside desktop noise, as the report says.

## Must fix before Nathanial sees it (ranked)

### 1. The door does not read as blocking the way

As a first-time player you see a grey concrete pier standing against the back wall, with a narrow roller door in its face. Open floor runs in front of the pier, and the lit machinery room with the safe point is plainly visible and reachable to its right.

- The engineer stops at the door's left jamb (x 752) with nothing visible stopping them. It reads as an invisible wall.
- DESIGN.md puts the bulkhead's front face "at walkway depth" (world x 680..838), but collision covers only the door's 56 px. So the actors stand inside solid concrete:
  - the engineer at x 736 in s2, s4 and s5;
  - WOLF at x 692 in s6 and x 743 in s7 (s7: his rear half is drawn over the concrete face left of the door).
- When the engineer "walks through" (s6, s7), they walk past a back-wall door. The corridor's wet walkway floor also continues behind the wall inside the hole.
- Main's gaudy gate at least stands across the path.

**Fix (a composition decision for Nathanial; SLICE.md already lists the angle question as open):**

- **(a) Cutaway cross-wall.** Draw the bulkhead's flanks (x 680..752 and 808..838) and a wall section down across the whole visible floor strip in the front layer, over the actors. The walkway then visibly ends at the wall, and the actors can only be seen passing through the hole. Inside the hole, show a sill or threshold, not the corridor's wet floor. This moves the relay-beat stand point (x 736) left of 680, which is a gameplay position, so it needs his yes.
- **(b) The approved "slight angle".** Show the door frame and curtain in the actors' plane with the face about 60-80 px wide. This needs his explicit OK against REAL-LOOK's no-three-quarter rule.

Either way:

- Consider a wider doorway than the 56 px collision body. A 1.4 m x 3.05 m roller door is a lift-door proportion; real service and vehicle coiling doors are about as wide as they are tall, or wider.
- Keep the machinery room visible only where the cutaway logic allows.

### 2. A purple key-colour fringe outlines the bulkhead and the doorway

This magenta spill is baked into the installed `assets/rooms/corridor-mid.png`. Codex painted on a magenta edit target, and cleanup re-imposed the alpha but never removed the spill from the colour.

- **Where:** the last 3-4 opaque pixels along the whole outer silhouette (left, right, bottom, and the return's foot) and all round the hole.
- **Mid-plate examples:**
  - right edge at y 600: (36,40,45) -> (40,37,48) -> (44,36,51) -> (49,35,57);
  - bottom at x 1400: (17,17,19) -> (27,16,30);
  - hole left edge at y 700: (29,23,42);
  - hole right edge: (56,50,73).
- **In game:** screen columns 755-757 and 1057-1059 carry a purple tint ((R+B)/2 - G up to +10.6) down the full height, on 70-100% of rows. At 1x it shows as a thin violet line round the pier and the doorway, a classic compositing tell. Crops: `review-r1-work/crops/s5-base-left.png`, `s1-safe.png` (left edge), `s5-doorway.png`.

**Fix:**

- Despill an 8 px band inside every alpha edge of the bulkhead and the hole: pull R and B down to at most G plus the local interior offset, or extend interior colour outward and re-apply the alpha.
- Add a cleanup check that fails any pixel within 8 px of an alpha edge where (R+B)/2 - G > 3.
- For future edit targets, use a neutral background close to the plate's values, not magenta.

### 3. A hard vertical seam line runs down the floor at the seam column

`haze_end = 0.596` cuts the haze quad with a straight edge. The wall hides it behind the column, but the haze band reaches down onto the floor.

- **Where:** screen x 602-604 (world about 581), from y 505 to about 660.
- **How strong:** the floor right of the line is 13-44% darker than main (slice/main luminance ratio 0.56-0.87 to its right, 0.92-1.00 to its left).
- **Why it matters:** a straight vertical cut through a receding floor is exactly what the brief said must not show. Crop: `crops/floor-seam.png`.

**Fix:** remove the haze from the whole corridor, which is cheaper and REAL-LOOK says no haze. Failing that, end it with a soft gradient (at least 80 world px) that never shows a straight edge on the floor. Then re-capture and check that no 4 px step on the floor exceeds a 5% luminance change.

### 4. The new wall light stops dead at the column

The new chain-hung LED (screen x 615-700, y 55) lights the new wall right of the column to luminance 103 (rows 60-140). The old wall 10-50 px left of the column, at the same height, stays at 20, so there is a 5x step across a 12 px column.

- A column that thin cannot stop light from a fitting hung in front of the wall.
- The step is visible in every corridor shot and in the opening's o7/o8 framing (`crops/o8-main-over-slice.png`).
- The old wall cannot change, because the opening must stay identical.

**Fix:** move the fitting to the middle of the new bay (over the relay, about world 640-660), and paint its pool so it falls to the old wall's value (luminance 20-25) by the time it reaches the column. Alternatively, make the column a deep pilaster whose lit right face and cast shadow explain the step. Either way, there should be no bright wall within about 40 px of the column.

### 5. The contact shadows fail checklist item 4, and are weaker than main's

I measured mean luminance 1-2 world px below the base line against 8-12 world px further out, across each base:

- **Relay:** 21.8 vs 23.4, ratio **0.93**. Main is 0.81.
- **Safe point:** 38.8 vs 38.8, ratio **1.00**. Main is 0.79.

REAL-LOOK names 0.86-1.01 as today's failing range. What is there is a 1 px dark line (row 504) and nothing more, so both stations look set down on a thin tray (`crops/safe-base.png`).

**Fix:** composite a footprint contact shadow 4-8 world px deep, darkest at the contact line (at most 0.6x the floor's value), fading out. Re-measure until the ratio is at most 0.8.

### 6. The bypass does not read, and the crank pose does not touch it

- **Size and value.** The wheel is 18 world px (32 screen px), mid-dark on a dark backplate. It is not the brightest thing on its wall, as REAL-LOOK requires for interactables. Its chain guard reads as a black diagonal stick, mostly hidden under the MANUAL BYPASS plate.
- **The crank.** In s3 the engineer's hand hangs about 5 world px left of the rim and below it, so nothing touches. In main their hand is on the rim (`crops/crank-main-vs-slice.png`). As a still, "cranking the bypass" reads as standing next to a disc.

**Fix:**

- Place the wheel so its rim sits under the hand of the existing crank stand (hub about 4-6 px left of and 2-4 px below its current (700, 398), still about 0.95-1.05 m), or shift the stand point to match.
- Give the rim worn bare steel where hands go, so it out-values the wall.
- Route the chain guard so it is not under the name plate, or confirm with Nathanial that the plate may carry the read.

### 7. The catwalk deck is drawn through the opaque tank

A lighter horizontal band crosses the expansion tank at the deck's height (screen y about 230-245, x 1115-1205), while the rails stop at the tank's edges.

- It is not in the design render or in Codex's output. `layers/tools/cleanup.py` introduced it, by re-imposing per-part values without depth order: the deck mask covers pixels behind the tank (`crops/far-design-codex-clean.png`).
- An object that is half in front and half behind is a classic generated-image tell.

**Fix:** composite the part masks back to front (tank over deck and rails) in cleanup, and add a check that no part's value pass writes into a nearer part's mask.

### 8. The pier is a big, evenly lit, airbrush-smooth slab with no source and no wear

- **Light from nowhere.** The edit target was dark above the wall pack. Codex lit the whole upper face, and cleanup's ±20% value clamp kept that.
  - In game, at y 150 the face sits at luminance 26-45 evenly across 300 px.
  - Its only fixture is the downward wall pack at y 235.
- **Values.** In greyscale it is the largest uniform mid-value mass in the frame, and it competes with the engineer standing in front of it (s2-s6). REAL-LOOK wants a quiet background and the actors carrying the contrast.
- **Finish.** It has form-tie dots and two pour joints, but no kick marks at the base, no damp line at a wet floor, no rubbing at the bypass and no drip under the conduit plate. Next to the weathered corridor it reads as a CG block pasted into a painting, which is the "plastic airbrushed finish" item.

**Fix:**

- Re-clamp the upper face to the design's planned values (about 60% of now) with the pool falling off within about 1 m of the wall pack.
- Add caused wear only: a damp band and dirt at the floor line, scuffs at about 0.3 m where boots and carts hit, hand-rub round the bypass and push buttons, and one rust drip under the penetration plate.
- Carry the corridor's cold ambient light into the concrete near the seam, so the pier and the corridor share one light.

## Smaller items (fix in the same pass)

1. **The seal lens is a flat-colour vector ellipse.** It is a `Polygon2D` drawn over the painted guard, so it reads as a flat red pill with no guard bars. Draw it under the guard (move the guard bars into the front layer) and use a small shaded lens texture tinted by modulate.
2. **The painted wall-pack highlight rides up with the slats** while the door opens (s4: the curtain right under the hood is dark mid-opening). Keep the light still: a fixed, painted light band on the front layer just under the hood, or a curtain painted without the pool.
3. **Too many reds.** When shut, the slice span shows three reds: the lockdown beacon housing, the seal lens and the e-stop. Section 8 allows one per view. Suggestion: the shut lens unlit (amber moving, green open), leaving the beacon as the live alert and the e-stop cap as the only painted red.
4. **The wet floor reflects only the actors.** It is still painted mirror-wet, and the engineer and WOLF reflect in it, but the green safe-point lamp, the high-bays and the wall pack give nothing. Either paint soft, baked reflections of those fixed lights into the floor, or make the floor in the door end drier (wet only where a leak explains it).
5. **The relay's conduits are invisible.** They run beside the seam column and land under the COOLANT RELAY / FAULT labels, so the relay's only visible feed is the brush strip. That grounding is enough, so either drop the conduits or move them where they read.
6. **A mirrored repeat at the right edge.** The near-strip pipe column at the right edge (screen x 1235-1280, inside world 540..960) is the left strip flipped, which fails checklist item 10. It is also teal-lit in front of a neutral grey room.
7. **`DOOR 4B-07` is 8.75 px tall.** Section 8 asks for 12 px. Flag it to Nathanial with the proposed marks, as the report does.
8. **The military read is only partial.** The camera, stencils and concrete help. A thin roller shutter in a pier, beside a pump room, still reads as a secure industrial plant rather than a hardened base. Without new text or keypads, mass would help: a heavier steel frame or armour angle round the opening, and a visibly thicker wall at the reveal. The approved marks such as `RESTRICTED AREA` stay Nathanial's call.
9. **Report accuracy.**
   - SLICE.md says "full-screen translucent layers 2 -> 1, plus the grade quad". My probe finds three full-screen quads in CanvasLayers in both copies during play: `PostProcess/Grade`, plus `CanvasLayer/IntroAlarm` and `CanvasLayer/IntroFade`, which stay visible at colour alpha 0. They are pre-existing on main and not this slice's art, but they are full-screen blends paid every frame on phones. Hide them when their alpha is 0, and correct the count.
   - Average world coverage (about 3.2) is still well over the 2.0 overdraw budget.
   - Draw calls reach the 60 budget exactly: s2 and s3 sit at 60, and s5 peaks at 60. There is no headroom.

## AI-tell checklist, item by item (in-game captures)

| # | Item | Result |
|---|---|---|
| 1 | Vanishing lines | Pass. The return's foot recedes correctly, the right reveal shows inside the hole, and the machinery room is in elevation. |
| 2 | One light logic | **Fail.** The upper pier face is lit from nowhere (8), light stops at the column (4), the curtain's light moves with the slats (small 2), and the wet floor reflects only the actors (small 4). |
| 3 | Every part has a job | Pass with a note: the relay conduits are invisible (small 5), and the catwalk has no visible access (acceptable). |
| 4 | Nothing floats | **Fail** on contact shadows (5): ratios 0.93 and 1.00. Plinths, backplates and arms are present. |
| 5 | Scale | Pass with a note: the door is 1.4 x 3.05 m, a lift-door proportion (1). |
| 6 | Doors | Pass on the alpha-0 hole and its own background space. **Fail** on reading as a door across the way (1). |
| 7 | No text | Pass. The marks are typeset and on the list. |
| 8 | Detail and values | **Fail.** The pier is the largest flat mid-value mass, has an airbrushed finish and competes with the actors (8). |
| 9 | Wear logic | **Fail.** There is no caused wear on the pier or the bar (8). |
| 10 | No repeats | **Fail.** The mirrored near-strip column is in view (small 6). |
| 11 | Rule 5 | Pass (independently re-diffed). |
| - | Compositing | **Fail.** Magenta spill outline (2), floor seam line (3), deck drawn through the tank (7). |

## Before and after, as a first-time player

| State | What changes |
|---|---|
| s1 at rest | Before: a garish gate that clearly stands across the floor. After: calmer and more believable materials, but a door in a pier that blocks nothing visible, with a purple edge on the pier and a dark/bright step at the column. |
| s2 relay beat | The engineer stands over the pier's concrete face. The stations sit on thin plinths with no real shadow. |
| s3 crank | Before: the hand is on a big wheel. After: they stand beside a small dark disc. The crank no longer reads. |
| s4 opening | It reads as a roller door going up, and a real room appears behind it. Good. The light under the hood goes dark as the slats move. |
| s5 open | The best frame: a real hole with a real room beyond. |
| s6 and s7 | The engineer passes the doorway in front of the wall. WOLF is drawn over solid concrete. It does not read as going through. |
| Seam | Hidden geometrically by the column, but visible as a value step (20 vs 103), as a straight line down the floor, and as grimy-old against airbrushed-new. |
