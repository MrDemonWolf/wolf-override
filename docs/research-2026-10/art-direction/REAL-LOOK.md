# WOLF//OVERRIDE: the real look (art direction)

Private, git-ignored. Written 2026-10-11 to answer Nathanial: "It needs to not look like fucking AI sloop", "We want this game to look real", "Doors on the wall should have a background", "Why is oien oc the controlers and computers in the air", and "Why are we rendering so much ... if it's meant to also run on Android and iOS". He chose **design first, then paint**. If this file and a later explicit decision from him disagree, his decision wins.

Evidence behind every rule (scratch, `real-slice/`): `audit/AUDIT.md` (what is wrong today, measured, with crops), `research/RESEARCH.md` (AI tells, shipped games, mobile GPUs, all sourced), `anatomy/ANATOMY.md` (how the real hardware is built, in metres and game px, with drawings). Perf baseline: `lighter-game/map-perf.md` and `PLAN.md`.

## 1. What "real" means here

A real room is a working industrial space, built and photographed once: seen from one camera, lit by fixtures you can see, made of parts that do a job and are fixed to the building, at the size a person needs to use them. **Scale key:** the engineer is 69.6 world px = 1.75 m, so **1 m ≈ 40 world px** (props at D = 4: 159 source px per metre; room plates: 80 plate px per metre). Every machine is a real kind of object (rolling service door, floor cabinet on a plinth, wall box, handwheel on a gearbox, vapour-tight light) at real size against him. Materials are matte, worn where hands, feet, water and heat wear them and calm everywhere else. Light is painted into the art and comes from somewhere. Nothing is decoration "for flash". The Look 2 characters and stations already have the right material and lighting (matte steel, one key, one accent per object, lamps as separate sprites, no text); they keep their designs and only gain grounding and real scale. WOLF's cage and the opening stay **exactly as on main** (code-drawn cage and gate, no pod; the branch `codex/logic-round-3` hatch pod must never ship).

## 2. Do and do not

**Environments**
- DO use **one projection**: side elevation for everything at walkway depth. The floor is a shallow strip seen from the same eye height; any receding edge meets the plate's one vanishing point.
- DO give every painted pool of light a fixture in the plate above it (vapour-tight fittings 51 x 4 px, chain-hung or surface-mounted). Light falls off softly on wall and floor.
- DO put wear where it comes from: kick plates, handles, thresholds, guide feet, drips under a flange that leaks, damp around a drain. Real wear is uneven.
- DO plan values first: background in 3 low-contrast values, actors and interactables brightest. Detail budget about 80% calm, 20% dense, and the dense part is where the engineer works.
- DO NOT paint lamp light as glowing vertical "icicles", haze cones in sealed rooms, frozen steam, or a cyan rim on both edges of every object.
- DO NOT use uniform drip bands, random paint flecks, rust speckle on every face, rivets on every surface, hazard chevrons on process pipes, scribbled labels, or three gauges in one view.
- DO NOT reuse the same machine, near strip or tunnel across rooms.

**Doors and hatches** (rule 2)
- A door asset is **only frame, leaf and lamps**. Where it is open its pixels are **alpha 0**; nothing is painted in the hole.
- A door is **set into a wall**: the wall plane continues around it, with a reveal showing the wall's thickness. It is not a freestanding gate in front of a wall.
- The space behind the hole is **room background**, painted once as part of the room's far/mid plate, at the room's one vanishing point, lit by its own visible fixtures. Each opening gets its own space; no shared tunnel.
- Build it like the real thing. The corridor seal is a rolling steel service door: slats at real pitch (about 2.7 world px), winding into a plain hood (15 px tall, 17 px deep), running in angle guides 4-5 px wide on the wall, with a bottom bar and astragal. Operator at 2.44 m or higher, push buttons at 1.52 m or higher, status lamp a guarded globe about 8 px tall. Hatches are watertight-door logic: sill coaming, rounded corners, dogs.
- No three-quarter frames, no skewed leaves, no flat navy rectangle as a doorway (Records `_draw_exit`).
- Rule 5: none of this touches the cage or the opening.

**Props and stations** (rule 3: nothing floats)
- Every machine is **either** on the floor with a plinth, skirt or feet, visible anchors and a contact shadow darkest at the contact line, **or** wall-mounted with a backplate, brackets and conduit or cable into the wall or floor.
- Every pipe, cable and conduit ends somewhere real: in the floor, the wall, a tray, or a flange on another pipe. Conduit is strapped within 0.9 m of a box.
- Controls sit where a person can use them: frequent or emergency controls 0.86-1.35 m (34-54 px up); displays read often at 1.27-1.65 m (51-66 px); work surfaces 0.9 m. A cabinet is about 2.0 m, a wall terminal about 0.6 m square.
- Moving parts are separate pieces (wheel, lever, needle), and lamps are unlit sockets plus a live tinted sprite, so nothing is lit twice.
- Fixes already known: the corridor **purge display** (base 2.4 m up, held by nothing) becomes a wall terminal on a backplate with brackets and conduit at 1.2-1.7 m. The **bypass** becomes a 0.4-0.5 m handwheel on a wall gearbox with its centre at 1.05 m (y 398). The junction feed line goes in a floor trench or a clamped wall conduit. The tank release loses its glowing cyan pad.
- DO NOT give props a mirrored copy on the floor. Grounding comes from a contact shadow layer generated from the geometry.

## 3. AI-tell checklist (reviewers run all of it on the in-game capture, not on the loose asset)

1. **Vanishing lines.** Extend receding edges (door, floor seams, ceiling run, plinths). One vanishing point per room, or none for elevations.
2. **One light logic.** Every lit face points at a visible fixture; every shadow falls away from it; contact shadows are darkest at the contact line; no highlight without a source; no glow brighter than its lamp.
3. **Every part has a job.** Name what each bolt, pipe, cable, grille and label does. Anything you cannot explain is painted out.
4. **Nothing floats.** Base on y 440 within 1 px **and** a visible contact shadow (floor right at the base clearly darker than 8-12 px further out; today it reads 0.86-1.01), or a backplate and brackets.
5. **Scale.** Overlay the engineer: lamps, bolts, slats, handles and doors within the real ranges in section 2 (not 3-5x too big).
6. **Doors.** Open area alpha is 0 in the asset; the wall continues around the hole; the space behind is background, not a copy of another room.
7. **No text.** No lettering or text-like marks in art; names are the game's own NamePlates.
8. **Detail and values.** Greyscale the frame: background is quiet, the work face and actors carry the contrast; no even detail everywhere, no plastic airbrushed finish.
9. **Wear logic.** Every stain and chip has a cause (hand, foot, water, heat). No even flecks or speckle.
10. **No repeats.** Nothing duplicated from another room or the other side of this one.
11. **Rule 5.** The cage and opening match main pixel for pixel.

A piece passes only when two reviewers each find zero open items.

## 4. Pipeline: design first, then paint

1. **Construction design (deterministic).** For each piece, a script draws a measured elevation from the ANATOMY tables at D = 4, registered to today's code anchors (floor y 440, door face x 752, collision body 56 x 132 unchanged). Output: a flat value-blocked render, **one mask per part** (frame, leaf, guide, hood, plinth, backplate, conduit, lamp socket, hole), a spec sheet (dimensions, what each part does, light direction from the named fixture), and the contact-shadow layer drawn from the footprint.
2. **Codex paints, only inside the masks.** Codex's built-in image generation in edit mode, given the construction render, masks, light direction, material notes and the Look 2 sheets as the material reference. The prompt forbids changing silhouettes, adding parts, text or greebles, painting in the hole, and stripping metadata (C2PA kept). Each session id and output goes in `real-slice/provenance.txt`; archive the session when done.
3. **Deterministic cleanup.** A script re-applies the masks: pixels outside the masks and inside the hole go to alpha 0, the silhouette snaps back to the construction, lamp sockets are cleared to unlit, values are clamped to the room's plan, the contact shadow is composited from step 1, and the result is trimmed to opaque bounds. Checks fail the piece if silhouette match is under 99%, any hole pixel has alpha, or anything lies outside the masks. The Codex originals are kept untouched with their metadata; the cleaned files are recorded as derived from them.
4. **In-game capture.** In `real-slice/game-slice` (never a Git worktree), import twice headless, then capture fixed states at gameplay zoom 1.35 next to the same states from `game-main`. Close every window opened.
5. **Review.** Two reviewers run section 3 on the captures, with a greyscale copy, a vanishing-line overlay and an engineer-scale overlay. Fix, recapture, re-review. Then Nathanial sees **one piece in the real game** before anything else is painted.

## 5. Phone render budget (per room, in the worst state of that room)

Why: `canvas_items` stretch renders every layer at native resolution (an iPhone 15 draws 5.8x the pixels of 960x540). Arm's mass-market example leaves about 8-10 GPU cycles per pixel at 1080p60, and tile-based GPUs only remove hidden **opaque** layers; every translucent layer is paid in full. Imagination says average overdraw above 2.0 starts to hurt. Today each room stacks 3 plates, a haze band, 3 lamp glows, 2 shafts, 2 beacons and glows, 42 dust specks, 3-12 mirrored reflections and a full-screen grade quad, while the plates already paint the same light. Static light belongs in the art (Arm: "pre-bake layers of transparency into a single flattened texture").

| Measure | Today (M1, map-perf) | Budget |
|---|---|---|
| Full-screen (or more than half the screen) translucent layers | far opaque + mid + near + haze + grade, plus shafts | far plate opaque; **at most 2** translucent (the mid plate and one grade/vignette, or bake the grade and keep one). Average overdraw target **at most 2.0** |
| Runtime effects that stay live | glows, shafts, haze, beacons, dust, reflections, status glows | only: status-lamp colour, lamp flicker as one modulate on the painted fixture, beacons during lockdown, blast flash, steam, sparks, coolant cloud, sentry eye. **At most 4** persistent additive glows per room, each trimmed tight (about 64 x 64 world px or less). No haze, shafts or prop reflections |
| Draw calls (`RENDER_TOTAL_DRAW_CALLS_IN_FRAME`) | 55 (Records) to 114 (sentry lane) | **at most 60** per room, **80** in the junction lane. One prop/door atlas per room and one shared additive material |
| Resident texture memory (`RENDER_TEXTURE_MEM_USED`) | 70.8-71.6 MB everywhere (all rooms built at start), 10-24 MB visible | room art **at most 12 MiB** per room (plates about 3.5 MiB VRAM-compressed, the rest one atlas); only the current and next room resident; **at most 45 MB** total |
| Particles | 19 CPUParticles2D nodes, 42 dust per room | **at most 12** ambient motes per room (or none), **at most 2** emitters active outside events, bursts **at most 64** live particles; hidden rooms emit nothing |

Measure it with Godot's own monitors, per state (corridor start, relay, door opening, open, safe point; same for the other rooms): `Performance.get_monitor()` for `RENDER_TOTAL_DRAW_CALLS_IN_FRAME`, `RENDER_TOTAL_OBJECTS_IN_FRAME`, `RENDER_TOTAL_PRIMITIVES_IN_FRAME`, `RENDER_TEXTURE_MEM_USED`, `RENDER_VIDEO_MEM_USED`, `TIME_FPS` and `TIME_PROCESS`, plus `RenderingServer.viewport_get_measured_render_time_cpu` (GPU time reads 0 in GL Compatibility on macOS). Log them with the existing perf driver (`perf_driver.gd`, quiet machine, before and after in the same run), or watch them in the editor's Debugger > Monitors during a remote-debug run on a phone. Godot has no 2D overdraw counter: estimate it by summing the on-screen area of visible translucent canvas items and dividing by the screen area, and confirm on a device with Xcode GPU frame capture or Arm Performance Studio. Desktop numbers do not prove a phone gain; only a device run does. Two levers still need Nathanial and a device test: a lower render scale or 30 fps option on weak phones, and merging the far and mid plates into one opaque plate (one less full-screen layer, but it loses the parallax).

## 6. What the corridor slice must prove

One piece, the corridor, built through section 4 in `game-slice` and shown in the real game before any other room is touched:

1. **The seal is a real door in a wall.** A rolling service door built from the anatomy, in the wall plane, closed, opening (0, 0.5, 1) and open. Open pixels are alpha 0 in the asset, and the space behind the hole is the corridor's own background, not a tunnel or another room.
2. **Nothing floats.** The purge display is wall-mounted (backplate, brackets, conduit); the relay and safe point keep their Look 2 designs on plinths with anchors, a conduit and a contact shadow; the bypass is a handwheel on a wall gearbox at 1.05 m. Every base passes checklist item 4.
3. **The light is painted.** The corridor's runtime haze, shafts, static glows, dust cloud and prop reflections are gone and the frame still reads lit; only the live list in section 5 remains.
4. **It fits the budget,** measured with the monitors above against main's corridor numbers from the same machine (desktop only, stated as such).
5. **Nothing else moved.** Cage and opening match main pixel for pixel; collision face x 752, the 56 x 132 body, labels, camera limits and saves unchanged; the headless tests pass.
6. **It passes review:** zero open items from two reviewers, then Nathanial's yes.

No feel claims: nothing in this pipeline is played by hand until he plays it.

## 7. Open decisions for Nathanial

- Door height: 3.05 m (fits the 132 px body) or 2.44 m (the "1.4x the engineer" brief).
- What MANUAL BYPASS drives: the door through a chain guard, or a valve on the relay's pipe (explains the coolant hiss).
- Merge far and mid plates per room (cheaper, no parallax) or keep the parallax.
- Actor floor reflections: keep for the engineer and WOLF on wet floors only, or replace with contact shadows everywhere.
- A render-scale or 30 fps option for low-end phones.
- If the Look 2 engineer frames differ in height from the provisional sprite, every px value here is rescaled.

## 8. Military base (direction added 2026-10-11)

Nathanial: "Can we add some pin codes and make it feel more like a furttgrue milialry base like iin skynet". The facility reads as a **near-future hardened military installation run by automated systems**: built for security and war, cold, machine-run, made of today's hardware a little newer. The AI defence network in the Terminator films is a **mood reference only**. Everything here sits on top of sections 1-7; nothing in it changes the door geometry, collision, the cage or the opening. Sources are listed at the end as [M1]-[M17].

**How the real ones are built.** Hardening means mass, isolation and locks: Cheyenne Mountain's main entrance is a 25-ton blast door, and its fifteen three-storey buildings stand on more than 1,000 springs [M1]. Titan II blast doors were 3-ton concrete-and-steel leaves, interlocked in pairs so one of each pair was always shut, with a lock room about 10 ft long between them [M2]. Crews were first held in an entrapment "cage" and identified by sound and video [M2]. A Minuteman capsule has 4 ft concrete walls lined with 1/4 in steel plate and an 8-ton door [M3, M4]. Services run in racks hung from the ceiling: the Titan cableway rack carried cables and chilled-water pipes on 54 pairs of springs [M2]. Where cables pass a shielded wall, they go through one welded 6 mm steel penetration plate that extends at least 150 mm past the penetrations, air goes through honeycomb waveguide vents (cells at most 100 mm across the diagonal), and shielded doors are steel with metal thresholds [M11]. Security is plain grey hardware: high-security door switches on the frame, keypads and card readers (a PIN alone is weak, so card plus PIN, or scramble keypads that reshuffle their digits each use), arm/disarm keypads wall-mounted at 1.2 m, panels in lockable, tamper-switched enclosures, smoked or clear dome cameras or fixed cameras in vandal-resistant housings, and sally ports whose inner door opens only when the outer one is shut [M10]. Retrofitted security devices and conduit end up surface-mounted [M10]. Microwave and seismic sensors watched Minuteman sites [M3]. A sign and a yellow line across the floor marked the capsule's no-lone zone, and the launch keys sat in a red, padlocked steel box [M3]. Military vehicle bays use motorized overhead coiling doors and bridge cranes [M16]; one repair shop moved its power into floor vaults to clear cable runs from work areas [M17]. Maintenance bays are lit to 300 lux with stem-hung fittings, each bay zoned, and dim by at least 50% after 20 minutes empty [M12]. Red light preserves night vision, so submarines "rig for red" and cockpits use dim red [M14].

**Design language**
- **Materials.** Cast concrete and steel plate. Steel liners at edges and reveals. Heavy frames, welded plates, bolted brackets. Nothing curved or plastic except camera domes.
- **Colour** (FED-STD-595 chips, now AMS-STD-595 [M8]; hex values are approximate screen conversions of the chip data [M7], and the plate's value plan in section 2 still rules). Structure: mid greys 36231 (#7E7E87) and 26270 Interior Haze Gray (#878892). Doors, housings and conduit: 36118 Gunship Gray (#5B5E6A) and 36081 (#4E4F54). Movable army kit only (cases, carts, portable units): olive drab 34088 (#473F37) or dark green 34102 (#565844). Markings: lusterless white 37875 (#F1EAEE) on dark paint, black 37038 (#343236) on light paint, as in the Army marking bulletin [M6]. Safety colours: yellow 33538 (#FFAA07) only for striking and caught-between hazards, and red 31136 (#A0333A) only for fire, emergency stop and danger, as OSHA assigns them [M9]. At most one yellow element and one red element per view.
- **Markings and signs.** Text is **typeset by script** from the approved list below, never painted by the image tool (section 3 item 7 still holds for everything Codex paints). Letters are sans-serif capitals with Arabic numerals, hyphen and slash only [M5]. Use the game's bundled Roboto (OFL, already in the asset register), so no new font. Stencilled marks get bridges cut by the script [M15]. Plates and labels are solid "mechanically printed" type [M13]. The text layer is composited after cleanup and baked into the plate or atlas, with no runtime Label nodes. Script-made wear goes only where use would put it. Sizes: door and sector numbers 12 world px tall (about 300 mm), other legible marks at least 8 px. Anything smaller is a blank plate or a bar, never fake letters. Every mark must be on the list, and reviewers check that.
- **Hardware.** Every device sits on a backplate or bracket, fed by grouped, strapped, surface-mounted rigid conduit (the retrofit logic of an older hardened site that machines took over). Conduit enters walls through one welded penetration plate (6 px margin at 1 m = 40 px). Panels have hinged, lockable covers. Cameras are fixed, in a housing or dome on a wall arm. Vents are honeycomb panels in heavy frames (cells at most 4 px). **No new keypads or card readers until Nathanial picks the PIN design**, which is being designed separately. When he does, it follows [M10]: wall-mounted at 1.2 m (y 392), in a tamper-protected housing.
- **Light.** Vapour-tight LED fittings, zoned and dim where nothing works (a machine-run base needs no light where no one is). Red is for alert only: the red fitting is painted unlit, and lockdown uses the beacon that is already on section 5's live list. No new runtime layers.

**Avoid.** Any Skynet, Terminator, Cyberdyne or other franchise name, logo, typeface, machine or design: chrome endoskeletons, skull faces, red eyes set in a skull (the game's sentry eye stays an industrial sensor lens), hunter-killer silhouettes, model-number styles such as T-, 800, 1000 or 101, and "Judgment Day" or "Resistance" wording. No real-world identifiers: no "U.S.", no service or unit names, flags, insignia, real NSN or CAGE numbers, NORAD or real base names. No story names (base, programme, WOLF or W.O.L.F., characters). No generic sci-fi: hexagon panels, glowing cyan seams, holograms, white curved plastic, LED strips on floor edges, glowing keyboards, invented alphabets, warning glyphs with no meaning.

**The corridor's door end**
1. The rolling door (section 2 geometry unchanged) sits in a cast-concrete portal. The reveal shows the full wall thickness, edged in steel angle, with a steel threshold plate on the floor [M11].
2. The leaf and hood are 36118. The bottom bar's front face carries yellow and black diagonal stripes (caught-between [M9]), worn at the centre where it lands. The door number is stencilled in 37875 on the fixed hood, so it does not scroll with the slats.
3. One yellow line runs across the floor at the edge of the door's travel, scuffed where feet cross it.
4. Above and to one side is a fixed camera in a housing on a wall arm, aimed at the approach, with conduit down to a junction box. It is static art with no live glow. There is a door switch at the head of the frame if it reads at 1-2 px, and is omitted if it does not.
5. The purge terminal and operator box become lockable steel enclosures on backplates (hinge and lock visible), fed by the same conduit group, which enters the wall through one penetration plate.
6. Proposal: the space behind the open door is a short blast-lock vestibule painted as the corridor's own background, with a closed inner door at the back (the Titan interlocked pair, [M2]). This is background only. It is not a new room or tunnel and not gameplay.
7. The latch-side spot at 1.2 m stays blank wall until the PIN decision is made.

**Proposed sign and stencil texts** (each one **proposed, awaiting Nathanial**; no story names)

| Text | Where | Why |
|---|---|---|
| `SECTOR 4B` | wall, high, 12 px | location code; real sites number zones |
| `DOOR 4B-07` | door hood, 12 px | doors are numbered, like Titan's Blast Door Six to Nine [M2] |
| `AUTOMATIC DOOR` / `KEEP CLEAR` | wall beside door, 8 px | a machine-run door moves on its own |
| `KEEP CLEAR` | floor, in front of the yellow line | door travel |
| `RESTRICTED AREA` | wall at the portal | security zone boundary |
| `AUTHORIZED PERSONNEL ONLY` | door-side wall | access control |
| `DANGER` / `HIGH VOLTAGE` | electrical panel, red header | OSHA red for danger [M9] |
| `PNL 4B-2`, `JB 4B-14`, `CAM 4B-03` | equipment plates | equipment identification [M5] |
| `DO NOT BLOCK` | threshold plate | door path |
| `TWO-PERSON ZONE` | only if Nathanial wants it | the no-lone-zone precedent [M3]; it implies a rule the game does not enforce |

**Open for Nathanial:** the texts above; the vestibule behind the door; whether movable kit goes olive drab; the PIN and keypad design (separate).

**Sources.** [M1] https://en.wikipedia.org/wiki/Cheyenne_Mountain_Complex · [M2] Titan II NHL nomination, NPS: https://npgallery.nps.gov/NRHP/GetAsset/NHLS/92001234_text · [M3] Minuteman Missile NHS special resource study, NPS: https://npshistory.com/publications/mimi/srs/sites.htm · [M4] https://www.nps.gov/places/delta-01.htm · [M5] MIL-STD-130N w/Change 1, sections 4.3, 4.4 and 4.7: https://www.camcode.com/wp-content/uploads/2022/01/mil-std-130N-change1-dated-16nov2012.pdf · [M6] TB 746-93-1 (Army vehicle colour and marking; gothic letters; 37875 on dark paint; mirror copy): https://armyradio.com/Colour-and-Marking-of-Military-Vehicles-Section-2.html · [M7] FED-STD-595C chip data (CIE values, names): https://people.csail.mit.edu/jaffer/Color/FED-STD-595C.txt · [M8] https://en.wikipedia.org/wiki/Federal_Standard_595 · [M9] OSHA 29 CFR 1910.144: https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.144 · [M10] UFC 4-021-02 (2025), sections 3-2.1, 3-2.9, 3-2.10, 4-6.7, 4-6.14, 5-2 and 5-2.6, and door hardware: https://www.wbdg.org/FFC/DOD/UFC/ufc_4_021_02_2025.pdf · [M11] UFGS 13 49 20.00 10 (HEMP shielding), sections 2.4.6-2.4.7, 2.6.1, 2.9.1 and 2.10: https://www.wbdg.org/FFC/DOD/UFGS/UFGS%2013%2049%2020.00%2010.pdf · [M12] UFC 3-530-01 (2023 c1), section 3-8.1: https://www.wbdg.org/FFC/DOD/UFC/ufc_3_530_01_2023_c1.pdf · [M13] UFC 3-580-01 (2024), labelling: https://www.wbdg.org/FFC/DOD/UFC/ufc_3_580_01_2024.pdf · [M14] https://en.wikipedia.org/wiki/Adaptation_(eye) · [M15] https://en.wikipedia.org/wiki/Stencil · [M16] https://www.bristol-companies.com/servicelines/vertical-construction/ · [M17] https://www.haskell.com/project/p-947-welding-repair-shop-facility/ . Downloaded texts and the colour conversion live in scratch `real-slice/research-military/`.
