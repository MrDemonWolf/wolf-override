# WOLF//OVERRIDE: what makes art read as generated, how real-looking side-view games are built, and how to render it cheaply on phones

Scratch research, 2026-10-11. Nothing in any Git repository was edited. Every claim below carries the URL it came from. When I could only see a search-index summary of a page, and not the page itself, the claim is marked **[snippet only]**. Treat those as leads, not facts. Numbers I worked out myself are marked **(calc)**.

Game facts used here come from `docs/research-2026-10/lighter-game/map-perf.md` (main at 76d3a50, measured on an M1 Pro, not on a phone), from the earlier door study `scratchpad/shutter-assets/MEASURE.md`, and from reading `apps/game` read-only.

---

## Part A. What makes images read as AI-generated, and how professional artists avoid each tell

### A1. The tells, with sources

**1. Geometry is right locally but wrong globally.**
- Hany Farid (UC Berkeley image forensics) checked vanishing points in 25 DALL-E 2 kitchens. The floor tiles converged correctly, but the counter-tops did not share a vanishing point with them. "While the perspective in these images is – impressively – locally consistent, it is not globally consistent. This same pattern was found in each of 25 synthesized kitchen images." https://ar5iv.labs.arxiv.org/html/2206.14617
- In the same paper, all 25 "three cubes on a sunny sidewalk" images had cast shadows that were "not physically consistent with a scene illuminated by a single light source." Only 3 of 25 mirror images had plausible reflections. https://ar5iv.labs.arxiv.org/html/2206.14617

**2. Each object is lit by its own private sun.**
- Farid's lighting study found that lighting environments estimated from different objects in the same generated image correlate weakly (R² 0.54 for the zeroth-order term, against 0.80 for global consistency). The front/back terms are the worst. https://ar5iv.labs.arxiv.org/html/2207.13744
- A comics-trained essayist puts it in an artist's terms: "Even when there is heavy shadow/light, AI images have puddles of light from random sources." https://vocal.media/art/why-does-all-ai-art-look-like-that (same essay as https://medium.com/@keithkisser/why-does-all-ai-art-look-like-that-f74e2a9e1c87)

**3. Machinery, text and instruments that cannot work.**
- The 2024 Magic: The Gathering promo background was AI-generated, and Wizards of the Coast later admitted it. Fans caught it from:
  - gauge markings that "become increasingly messy to the point where they are almost illegible"
  - "pages blending into each other"
  - "compressed-looking pipework that makes little sense"
  - https://mtgrocks.com/wizards-of-the-coast-accused-of-using-ai-art-in-mtg-promotion-again/
  - The admission: https://vice.com/en/article/magic-the-gathering-publisher-denies-then-admits-using-ai-art-in-promo-image
- Merging is also a tell: objects melt into one another because the model does not treat them as separate things. https://isitai.com/blog/how-to-spot-ai-art (detection-site blog, low authority)

**4. Decoration without purpose, and design that ignores use.**
- Senior concept artist Miguel Nogueira cleaned up AI output for a client. "I removed most decorations that AI tries to add for flash in exchange for realism." He also found that "the bridges it previously built led nowhere, the social purpose of a plaza was off, and some of these design choices were flat-out dangerous if they were a real piece of architecture." https://80.lv/articles/should-you-hire-an-ai-artist-or-a-concept-artist
- Greebles are surface detail that "imply mechanical function without necessarily having any real purpose." https://en.wikipedia.org/wiki/Greeble **[snippet only]**
- That is exactly the fantasy-sci-fi detail Nathanial does not want.

**5. Detail and finish everywhere, so nothing is the subject.**
- "There's no foreshortening or blurring, no focal point." https://vocal.media/art/why-does-all-ai-art-look-like-that
- "AI art has no concept of fore-middle-background, so everything looks flat." (same essay)
- Materials look as if they were "made from injection-molded plastic." (same essay)

**6. A shared "AI look": saturated, dramatic, airbrushed.**
- Farid ties the sameness to aesthetic filtering: "Most models have an 'aesthetic' filter on both the input and output … almost certainly a big part of why AI-generated images all have a certain ethereal quality." https://www.ischool.berkeley.edu/news/2024/certain-ethereal-quality-hany-farid-explains-why-ai-art-looks-way-it-does
- Players also spot tampered paintings. Elder Scrolls Online players flagged "nonsensical artifacts and paint overs" in loading screens that had been altered, apparently upscaled with AI. https://forums.elderscrollsonline.com/en/discussion/681310/concerned-about-the-potential-use-of-ai-on-loading-screen-artwork **[snippet only]**

**7. Missing design thinking.**
- Concept artists surveyed said clients bringing AI references "haven't considered how their concept works, or how it looks from different angles." https://www.gamespot.com/articles/video-game-concept-artists-say-genai-isnt-making-things-easier/1100-6537107/ **[snippet only; the page returned 403]**

### A2. How professionals avoid each tell

| Tell | What professionals do instead | Source |
|---|---|---|
| Machinery that cannot work | Design from function first. Ron Cobb (Alien's Nostromo): "my obsession became how to infuse believability into even my most fantastic designs." Pascal Blanche on Cobb: "practical and down to the little details that makes the world more believable." | https://www.heavymetal.com/post/ron-cobb-designer-of-nostromo-and-mcflys-delorean-1937-2020 |
| Free-floating style | A hard construction rule. Alien: Isolation: "we wouldn't build anything that couldn't have been built on the original set in 1979." | https://www.hudsandguis.com/home/2014/06/04/alien-isolation |
| Generic sci-fi | Take real reference apart. Jude Bond: "a really dogged … obsessive deconstruction of the original film," "how these atomic parts were put together"; about 95% of what you see is new, but it is built from those parts. | https://www.thesixthaxis.com/2014/06/10/talking-alien-isolation-with-the-creative-assemblys-jude-bond/ |
| Sterile, digital-clean surfaces | Push the image through a real physical process. Alistair Hope: "When it's digital, it can quite often feel very cold." They ran the UI through VHS and tube TVs and put magnets on the TVs: "We broke two VCRs and at least two TVs." | https://www.engadget.com/2014-10-07-alien-isolation-launch-interview.html |
| Spaces with no logic | Lay out spaces by what they are for. Dead Space remake: "everything we did, we did because it made sense, because it fit" (Roy Tuazon). The bridge is at the front and engineering at the back (Philip Duchamp). | https://www.ea.com/ea-studios/motive/news/inside-dead-space-3-aboard-the-ishimura and https://gamesbeat.com/dead-space-interview-fleshing-out-the-usg-ishimura/ |
| Lived-in but empty | Add human traces with restraint. Bond: "people don't live in mechanical spaces like machines. They want to make them into homes." | https://www.thesixthaxis.com/2014/06/10/talking-alien-isolation-with-the-creative-assemblys-jude-bond/ |
| Detail everywhere | Budget the detail. Brendon Chung (Blendo Games): "80% of an asset should be 'flat', and 20% should use high-density detail"; "There is a 'budget' for player attention, and it didn't make sense to spend it on a standard wall." | https://blendogames.com/news/post/2025-07-02-skindeep_art/ |
| No focal point | Plan values, then shade. Use "only 3 or 4 values"; "Merge unimportant areas into a single, quiet value"; put the strongest contrast at the focus. | https://brooks-newsletter-359c19.beehiiv.com/p/design-your-values-don-t-just-shade |
| Random light puddles | One light logic per scene, and check it. Farid's own tests make good QA tools: extend parallel edges and see whether they meet; trace each cast shadow back to its light. | https://ar5iv.labs.arxiv.org/html/2206.14617 |
| Noise | Take things away. Arnt Jensen (Limbo, Inside): "I really enjoy getting rid of everything to see what works. It should be working when it's very naked." About 70% of Limbo's ideas were cut. | https://www.killscreen.com/must-read-history-limbo/ (citing Edge's "The making of Limbo") |

### A3. What this means for WOLF//OVERRIDE (Part A)

**AI-tell checklist for reviewers.** Run it on every Codex-painted piece before it reaches the game.
- **Vanishing lines.** Draw the receding edges: door frame, floor seams, ceiling pipe run, station plinths. In a side view almost everything should be frontal. Any receding edges must meet at the room's one vanishing point, which the plates already set. A door painted with its own private perspective is tell 1.
- **One light logic.**
  - Every lit face must point at a visible fixture.
  - Every cast shadow must fall away from that fixture.
  - Contact shadows must sit under the object, darkest at the contact line.
  - Any highlight with no source is tell 2.
- **Every part must have a job.** Mark every bolt, pipe, cable, grille and label, and say what each one does: what it carries, where it goes, what it fastens. Paint over anything you cannot explain. That is Nogueira's cleanup and Cobb's rule. Pipes must run into the wall or floor or into another fitting, never end in mid-air. Gauges get real ticks or none.
- **No text, or real text.** Generated labels turn to mush (tell 3). Either remove the lettering or set it later as real type: the game already draws NamePlates in code.
- **Detail budget.**
  - About 20% of each asset is dense: the working face, meaning the handle, lamps and hinge.
  - About 80% is calm: plain sheet metal with even wear.
  - On the plates, the busiest area goes where the engineer works. The rest becomes a quiet value group.
- **Value plan before paint.**
  - Background: three values with low contrast.
  - Actors and interactables: the brightest values with the highest contrast.
  - Check it by viewing the composite in greyscale. Peter Angstadt's desaturate test: https://www.gamedeveloper.com/design/how-to-reduce-visual-confusion-in-your-game
- **Warmth from process, not filters.** Isolation broke real tube TVs to get its look. The equivalent here is "design first, then paint": exact shapes from measurements first, with Codex adding only material and light on top. Keep that order.

---

## Part B. How shipped side-view and 2.5D games make their worlds look real

### B1. Game by game

**Inside (Playdead, 2016).** From the GDC talk "Low Complexity, High Fidelity", slides by Mikkel Gjøl and Mikkel Svendsen: http://loopit.dk/rendering_inside.pdf
- **Fog carries the look.** "Fog turned out to be very central to our artstyle. Many of the initial scenes in the game were literally just fog + silhouettes." "Simple linear fog!" The fog is clamped "to a max-value to enable bright objects to 'bleed through'" (headlights, spotlights).
- **Contact grounding is deliberate and plentiful.**
  - Characters carry one multiplicative ambient-occlusion capsule per bone. These "ground them to the world, other characters and to themselves."
  - Sphere and box occluders mark contact for round objects and puzzle crates. Box occluders get "sharp falloffs along corners."
  - "Shadow decals … We use it for grounding in scenes with unshadowed lights and ambient lighting." They are kept "very soft, gradieted … on purpose to simplify." "And we use a lot of these!"
- **Bloom must match its source.** "If bloom calculated with a certain intensity, we need to show source pixel with the same intensity." In other words, a glow needs a lamp that is visibly that bright.
- **Banding is fixed with dithering.** They dither after every pass, because dark gradients band in 8-bit.
- **Restraint.** Jensen's "very naked" principle, above. https://www.killscreen.com/must-read-history-limbo/

**Another World (Eric Chahi, 1991).** GDC 2011 postmortem: https://www.gamedeveloper.com/game-platforms/gdc-2011-eric-chahi-s-retro-postmortem-i-another-world-i-
- He spent "a week defining the 16 color palette." A small palette decided early is what holds the world together.
- Backgrounds were painted as bitmaps first ("pixigons" took "hours and hours", so he "resorted to using bitmaps"). Motion was rotoscoped from video using a genlock.
- He relied on suggestion: "The real media is the player's memory and imagination, so seeing it once is enough."

**Flashback (Delphine, 1992).** Paul Cuisset: https://www.nintendolife.com/news/2018/06/feature_freedom_fighter_paul_cuisset_on_the_making_of_flashback
- The rotoscoped animation ran at 24 fps: "we settled on 24 frames per second, as it was really the most beautiful"; "12 fps … just wasn't smooth enough."
- Realistic human motion is the realism anchor.

**Planet of Lana (Wishfully, 2023).** Adam Stjärnljus: https://filmstories.co.uk/features/planet-of-lana-2023s-prettiest-sci-fi-platformer/
- "All the 3D rocks and stuff like that combine with sprites, and all the lighting is hand-painted." He names Flashback and Another World as references.
- The sequel targets 60 fps on every platform, including Switch 2 at 720p handheld: "Given we have a stylized side-scrolling game, this makes sense for us." https://gamingbolt.com/planet-of-lana-2-children-of-the-leaf-interview-art-direction-varied-environments-hybrid-robots-and-more
- So a shipped game with this look paints its light into the art.

**Alien: Isolation (Creative Assembly, 2014).**
- The 1979 buildability rule (https://www.hudsandguis.com/home/2014/06/04/alien-isolation).
- Film deconstruction and lived-in homes (https://www.thesixthaxis.com/2014/06/10/talking-alien-isolation-with-the-creative-assemblys-jude-bond/).
- Physical-process artefacts (https://www.engadget.com/2014-10-07-alien-isolation-launch-interview.html).
- The source design it built on was functional. Cobb's Nostromo was an orbital refinery whose logic was translated from power plants and industrial ventilation, with pipes, valves, grilles and cables exposed. https://www.domusweb.it/en/news/2025/09/19/alien-design-nostromo.amp.html **[snippet only; the page returned 403]**

**Dead Space (EA Redwood and Motive).**
- Spaces are laid out by function, and the danger is designed in. Catherine Stewart: spaces "look like they could be lived in—just, maybe designed by a person who seemed to actively denounce health and safety regulations." https://www.ea.com/ea-studios/motive/news/inside-dead-space-3-aboard-the-ishimura
- The ship layout is logical, bridge at the front and engines at the back. https://gamesbeat.com/dead-space-interview-fleshing-out-the-usg-ishimura/

**Little Nightmares (Tarsier).**
- Scale is a mechanic: "The scale difference between Six and the world … helps us to create challenging gameplay experiences that also feel natural." https://gamingbolt.com/little-nightmares-interview-into-the-maw
- The Unreal Engine interview about light and shadow and about artists and designers tuning scale together could not be fetched (403): https://www.unrealengine.com/en-US/developer-interviews/how-little-nightmares-ii-plumbs-the-depths-of-adolescent-angst

**Somerville (Jumpship).**
- I found no developer source on its art method that I could fetch. Reports credit Chris Olsen's "strong graphic framing" and "gigantic scale" (John Harris, Evangelion) **[snippet only, no page verified]**. I make no claims about Somerville beyond that.

### B2. Principles across these games, with numbers where they exist

**Value structure and palette**
- Decide the palette early and keep it small: Chahi used 16 colours.
- Keep backgrounds low-contrast and put the actors in the brightest, highest-contrast band (Angstadt, above).
- Group values by depth: background light, midground grey, foreground dark, or a deliberate inversion. https://faculty.gvsu.edu/KEISTERD/design_principles_art/value_structure.html
- Inside builds whole scenes from fog plus silhouettes.

**Detail hierarchy**
- Chung's 80/20 rule (above).
- "places of high activity and areas of rest for the eye": Brie Gibson, https://80.lv/articles/001agt-crafting-grand-well-balanced-environments
- Jensen cut about 70% of Limbo's ideas.

**Functional design**
- Cobb, Isolation's 1979 rule, and Dead Space's "made sense, because it fit" (above).

**Material logic and wear.** Real subjects weather where physics puts it, and unevenly:
- Vertical streaks from rain and leaks, placed "where fluids would actually collect or run"; "random streaks across flat surfaces tend to look forced."
- Washes around "recessed detail, fasteners and structural lines."
- Chipping around hatches and "crew traffic zones."
- Wear at access areas and leading edges.
- "Real subjects weather unevenly."
- Source: https://www.scalemodelshop.co.uk/scale-model-weathering-guide-realism/

**Motivated light**
- Inside's bloom must match its source.
- Planet of Lana paints all of its light by hand.
- Farid's tests show that unmotivated light is the most measurable tell.

**Grounding**
- Inside uses per-bone AO, box AO with sharp corner falloff, and "a lot" of soft shadow decals.
- A contact shadow is darkest where the object meets the surface. Without it, objects "will appear as if they are hovering." https://oreilly.com/library/view/commercial-photoshop-retouching/059600849X/ch02s05.html **[snippet only]**

**How real installations are fixed in place.** This is the engineering behind "nothing floats".
- FEMA E-74 §6.4.7.1 covers tall floor-mounted control panels, MCCs and switchgear. "The principal objective is to prevent the components from sliding or toppling."
- Supports include "braces, frames, skirts, legs, pedestals." Panels "can be supplied with shop welded brackets or predrilled holes for base or wall anchorage." Tall units are anchored to the floor, with the top also anchored to the wall.
- Conduits use "flexible connections." The typical failure is "Overturning or sliding due to lack of anchorage."
- Even exempt items "must still be positively anchored to the structure."
- Source: the FEMA E-74 chapter 6 section PDF via https://femae74.atcouncil.org/docman/abbreviated/section-6-4/56-49-femae-74-chapter6-4-7-1
- Wall-mounted items: anchor to a structural stud, "not to a gypsum board", or use a horizontal mounting strip anchored to each stud. Items over 20 lb mounted more than 4 ft up need anchorage. https://femae74.atcouncil.org/docman/abbreviated/section-6-6/95-femae-74-chapter-6 **[snippet only]**

**Human scale: real dimensions to measure against the engineer**

| Item | Real value | Source |
|---|---|---|
| Adult man, mean height (US, 2021–2023) | 68.9 in, about 1.75 m | https://www.cdc.gov/nchs/fastats/body-measurements.htm |
| Guardrail top rail | 42 in ± 3 in (107 cm); midrail halfway | https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.29 |
| Standard stair | 30–50°, riser ≤ 9.5 in, tread ≥ 9.5 in, width ≥ 22 in | https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.25 |
| Ship stair | 50–70° | same |
| Ladder | 60–90° | same |
| Electrical working space in front of a panel | ≥ 30 in wide (never less than the equipment), headroom 6½ ft, dedicated space up to 6 ft above the equipment with no foreign pipes or ducts | https://www.ecmweb.com/national-electrical-code/code-basics/article/21259374/nec-requirements-for-working-clearances |
| Reach range for controls | 15 in min to 48 in max above the floor | https://www.access-board.gov/ada/guides/chapter-3-operable-parts/ **[snippet only]** |
| Navy watertight door, stock size | 26 in × 66 in opening, 8 in corner radius, 8 dogs, ¼ in plate | NSN 2040-01-369-1660, https://wbparts.com/rfq/2040-01-369-1660.html **[snippet only; 403]** |

### B3. What this means for WOLF//OVERRIDE (Part B)

**Scale key (calc).**
- The engineer's sprite is about 72 world px tall (MEASURE.md). At 1.75 m that is about **41 world px per metre**, or about 82 source px per metre on the half-scale 1920 plates.
- Real objects at that scale:

| Real object | World px |
|---|---|
| Guardrail (1.07 m) | ≈ 44 |
| Highest control reach (1.22 m) | ≈ 50 |
| Lowest control reach (0.38 m) | ≈ 16 |
| Panel working headroom (1.98 m) | ≈ 81 |
| Panel working width (0.76 m) | ≥ 31 |
| Stair riser (≤ 0.24 m) | ≤ 10 |
| Navy watertight door opening (1.68 × 0.66 m) | ≈ 69 × 27 |

- The navy door opening is shorter than the engineer, so they would duck: real ships really are like that.
- The camera shows about 711 × 400 world px, roughly 17 × 10 m. A room is 960 px, about 23 m.

**Doors**
- A door is frame, leaf and lamps only. Where it is open, its pixels are transparent.
- The space behind the hole is background art drawn at the room's single vanishing point.
- Watertight-door logic gives the "real" read: a coaming sill, rounded corners and dogs around the edge.
- Wear goes where hands and feet go: the handle area, the sill and the dog handles.
- Streaks run down from hinges and dogs.

**Stations (the "floating controllers" fix)**
- Every Look 2 station keeps its design and gains one of two mounts:
  1. **Floor-mounted:** a plinth, skirt or feet with visible anchor bolts, a contact shadow darkest at the floor line, and a conduit or cable into the floor or wall.
  2. **Wall-mounted:** a backplate fixed to the wall structure with brackets, plus a conduit run into the wall.
- Controls go between about 16 and 50 world px above the floor, where the engineer can actually reach them.
- Keep a clear working zone in front of the panel: about 31 px wide and about 81 px tall.

**Grounding, Inside-style**
- Every prop sitting on the floor gets a soft painted shadow, darkest at the contact line.
- Actors already have floor reflections. Check that each also has a contact darkening under its feet, as Inside's capsules and decals do.

**Light**
- Paint the light so every lit area traces back to a fixture that is visible in the plate.
- If a glow stays live at runtime, its lamp pixel must be at least as bright as the glow (Inside's bloom rule).

**Palette and values**
- Fix a small room palette and a value plan per room before any paint pass.
- Keep backgrounds low-contrast so the engineer and WOLF stay the brightest, highest-contrast shapes.

---

## Part C. Rendering a 2D game cheaply on phones

### C1. How tile-based mobile GPUs handle layers

**Each translucent layer is paid for in full.**
- Android: "transparent objects require existing pixels to be drawn first, so that the right blending equation can occur." https://developer.android.com/topic/performance/rendering/overdraw (updated 2026-08-18)
- Imagination (PowerVR): "With PowerVR TBDR, Hidden Surface Removal (HSR) will completely remove overdraw regardless of draw call submission order". Blended elements break that 1:1 ratio. https://docs.imgtec.com/starter-guides/powervr-architecture/html/topics/hidden-surface-removal-efficiency.html
- Imagination again: overdraw should be around 1.0, and "if the Overdraw counter is consistently higher than 2.0 then it may start affecting performance." Their fix is geometry that follows the opaque edge of the texture, so fully transparent texels are never drawn. https://blog.imaginationtech.com/improving-particle-systems-on-powervr/
- Apple (WWDC20 10631): HSR means "we don't shade any fragment that will later be occluded." Blending happens in on-chip tile memory, so a well-written app uses far less bandwidth than on desktop-style GPUs. https://developer.apple.com/videos/play/wwdc2020/10631/
- The saving holds only for opaque layers: every blended layer is still shaded.

**Arm's numbers and rules.** "Optimization advice for graphics content on mobile devices", doc 102643 issue 01, January 2024: https://documentation-service.arm.com/static/65952df1159ca73387227425
- **Pixel budget.** A Mali-G72 MP2 at 600 MHz running 1080p60 has "cyclesPerPixel … = 9.6". That must cover every frame cost, so it is "a usable budget for a 2D game." Dropping to 720p30 gives "over 40 cycles per pixel."
- **Layers add up.** "layers of 2D interface components can quickly accumulate into a high layer count, which is expensive to process even if the layers themselves are simple."
- **High overdraw fixes:**
  - make draws opaque (no blending, no discard)
  - split mixed opaque/transparent elements into two draws
  - "reducing the number of layers, pre-baking layers of transparency into a single flattened texture where possible"
- **Textures.** "Use texture compression … Use mipmaps." Bilinear filtering is twice as fast as trilinear.
- **Heat.** DRAM access costs "approximately 100pJ per byte for LPDDR4." Fewer layers and compressed textures save battery and slow thermal throttling.
- **Draw calls** are CPU cost. Reduce them by culling and batching.

**Practitioners say the same about effects.** "stacking 10 smoke particles … means rendering 11 layers per pixel"; on mobile, keep transparency to single, small layers. https://realtimevfx.com/t/why-are-additive-shaders-so-heavy-for-phones/23998 (forum, practitioner experience)

### C2. Godot 4 specifics (docs for 4.7 stable unless noted)

**Resolution**
- With `canvas_items` stretch, Godot renders "directly at the target resolution". `viewport` mode renders at the base size and then scales up. https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html
- For 2D, the Compatibility renderer "is usually good enough." It has no 2D HDR viewport. https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html

**Large transparent sprites**
- "When drawing large images with transparency, Godot will draw the whole quad to the screen. The large transparent areas will still be drawn."
- This hurts "especially on mobile devices, when drawing very large images (generally screen sized), or layering multiple images on top of each other with large transparent areas (for example, when using ParallaxBackground)."
- The fix is Sprite2D → MeshInstance2D. https://docs.godotengine.org/en/stable/tutorials/2d/2d_meshes.html

**Lights**
- Additive sprites are "much faster to render" than Light2D, "since they don't need to go through a separate rendering pipeline." Larger lights cost more because they cover more pixels. https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html
- The Compatibility renderer allows at most 32 positional lights per frame and 8 per object by default (ProjectSettings `rendering/limits/opengl/*`, Godot `doc/classes/ProjectSettings.xml`).

**Batching**
- Batching groups similar items into one draw call. Godot sees OpenGL driver overhead as the costly part, and in the worst case advises atlases. https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html
- A change of texture or material breaks a batch. https://godotengine.org/article/gles2-renderer-optimization-2d-batching (the 3.x origin; batching has been in the Compatibility renderer since 4.0) **[the second half is snippet only]**

**Texture compression**
- VRAM Compressed means S3TC/BPTC on desktop and ETC2/ASTC on mobile and web, with "4-6x memory reduction."
- For 2D the docs default to Lossless, with mipmaps "only when visibly beneficial"; mipmaps add about 33% memory. https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html
- `import_etc2_astc` uses ETC2 for normal quality and ASTC 4×4 for high quality (`doc/classes/ProjectSettings.xml`, 4.5-stable). The game already has it on (`project.godot` line 35).

**Format sizes**
- ETC2 RGB: 64 bits per 4×4 block (4 bpp). RGBA ETC2: 128 bits (8 bpp). Khronos Data Format spec §22: https://registry.khronos.org/DataFormat/specs/1.3/dataformat.1.3.html
- ASTC: every block is 128 bits. 4×4 = 8.00 bpp, 6×6 = 3.56, 8×8 = 2.00. https://github.com/ARM-software/astc-encoder/blob/main/Docs/FormatOverview.md
- ETC2 needs OpenGL ES 3.0, which the Compatibility renderer already requires. https://android-developers.googleblog.com/2015/01/efficient-game-textures-with-hardware.html

**Screen-reading effects**
- CanvasGroup draws its children through a backbuffer pass. Bigger margins and mipmaps cost more. https://docs.godotengine.org/en/stable/classes/class_canvasgroup.html
- Screen-reading shaders copy the screen; Godot does this once per frame. https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html
- The game uses neither of these.

### C3. What this means for WOLF//OVERRIDE (Part C)

**1. Most of the GPU work is resolution × layers per pixel.**
- `canvas_items` stretch means a phone renders every layer at native resolution (calc):
  - iPhone 15, 2556×1179 (https://support.apple.com/en-us/111831): about 3.0 Mpx, **5.8×** the 960×540 base.
  - A typical 2400×1080 Android: 2.6 Mpx, 5.0×.
- Against Arm's mass-market example (G72 MP2), that Android phone at 60 fps gets about **7.7 cycles per pixel** for the whole frame (calc). Every full-screen translucent layer spends part of that.
- Two levers, both needing a device test:
  - a render-scale option (Godot's docs recommend exposing resolution scaling);
  - 30 fps on low-end phones (Arm: 720p30 gives more than 40 cycles per pixel).

**2. Bake the static light into the plates.** This is Arm's "pre-bake layers of transparency into a single flattened texture", and Planet of Lana's "all the lighting is hand-painted".
- Painted into the art: haze, light shafts at rest, static lamp glows, the vignette (if static), and the static dust haze.
- Stays live, as small and tight-fitting as possible: a status lamp's colour change, flicker, the blast flash, steam, a few dust motes.
- Today `room_depth.gd` builds these at runtime:
  - a haze Sprite2D covering about 56% of the far plate's height;
  - additive drifting shafts;
  - lamp glows;
  - CPUParticles2D dust and effects (the class name appears 40 times across `room_depth`, `junction_room`, `fx_presets`, `main`, `impact` and `bypass_handle`; that is a count of references, not of live emitters);
  - plus floor reflections and the vignette described in the brief.
- Each of those is a translucent layer over the whole area it covers.

**3. Do not draw transparent pixels.**
- Trim every door, prop and near strip to its opaque bounds, or use MeshInstance2D for large ones (Godot docs).
- A door's open hole must not be filled with a full-screen quad.
- The 512×1080 near strips and any plate with a transparent sky or ceiling are the first candidates.
- The far plate parallaxes only about ±12 world px (MEASURE.md). Merging far and mid into one opaque plate per room would remove a whole full-screen layer. That is a trade-off for Nathanial to judge, since it loses the parallax.

**4. Texture memory.**
- Today:
  - 26 images import as Lossless with mipmaps;
  - 9 plates import VRAM-compressed without mipmaps;
  - 1 is Lossless without mipmaps.
  - (Tally of `.import` files in `apps/game/assets`.)
- Per-image costs (calc):

| Image | Format | VRAM |
|---|---|---|
| 1920×1080 plate | Lossless RGBA8 | 7.9 MiB (10.5 with mips) |
| 1920×1080 plate | ETC2 RGBA or ASTC 4×4 | 1.98 MiB |
| 1920×1080 plate, opaque | ETC2 RGB | 0.99 MiB |
| 1920×1080 plate | ASTC 6×6 | 0.88 MiB |
| 512×512 prop | Lossless RGBA8 | 1 MiB, 1.33 with mips (matches map-perf's figure) |

- Steps:
  - Import new props VRAM Compressed unless edges visibly suffer.
  - Keep plates opaque wherever the design allows, so they can use the 4 bpp formats. Check in the import dock whether Godot picks the RGB variant for alpha-free images; I did not verify that.
  - Build each room's art only when the room is entered (PLAN.md estimates about 30 MB less resident).

**5. Draw calls.**
- 55–114 per frame now.
- Batches break on texture or material changes. So:
  - one atlas per room for its props and doors;
  - one shared additive material (already planned as FxKit);
  - fewer separate glow and shaft sprites once they are baked.
- Arm counts draw calls as CPU cost. On M1 the render thread is only about 0.4–0.8 ms per frame, so this matters less than fill.

**6. Keep what is already right.**
- There are no Light2D, CanvasGroup, BackBufferCopy or screen-texture shaders. Godot calls additive sprites the fast path, and the game uses them.
- Keep it that way.
- Avoid WorldEnvironment 2D glow. Every glow should be painted into the art or be a small additive sprite.

**7. Measure on a device before claiming wins.**
- The map-perf figures are M1 desktop numbers.
- Overdraw needs a GPU tool on the phone: Arm Performance Studio / Streamline (named in Arm 102643), Xcode GPU frame capture, or Android's GPU overdraw debug view. Aim for about 1.0–2.0 average layers (Imagination).
- None of this has been tested on a phone yet.

---

## Source index (fetched unless marked)

**AI tells**
- https://ar5iv.labs.arxiv.org/html/2206.14617
- https://ar5iv.labs.arxiv.org/html/2207.13744
- https://www.ischool.berkeley.edu/news/2024/certain-ethereal-quality-hany-farid-explains-why-ai-art-looks-way-it-does
- https://80.lv/articles/should-you-hire-an-ai-artist-or-a-concept-artist
- https://mtgrocks.com/wizards-of-the-coast-accused-of-using-ai-art-in-mtg-promotion-again/
- https://vice.com/en/article/magic-the-gathering-publisher-denies-then-admits-using-ai-art-in-promo-image
- https://vocal.media/art/why-does-all-ai-art-look-like-that
- Snippet only: GameSpot, ESO forums, Wikipedia "Greeble", isitai.com

**Games and art practice**
- http://loopit.dk/rendering_inside.pdf
- https://www.killscreen.com/must-read-history-limbo/
- https://www.gamedeveloper.com/game-platforms/gdc-2011-eric-chahi-s-retro-postmortem-i-another-world-i-
- https://www.nintendolife.com/news/2018/06/feature_freedom_fighter_paul_cuisset_on_the_making_of_flashback
- https://filmstories.co.uk/features/planet-of-lana-2023s-prettiest-sci-fi-platformer/
- https://gamingbolt.com/planet-of-lana-2-children-of-the-leaf-interview-art-direction-varied-environments-hybrid-robots-and-more
- https://www.hudsandguis.com/home/2014/06/04/alien-isolation
- https://www.thesixthaxis.com/2014/06/10/talking-alien-isolation-with-the-creative-assemblys-jude-bond/
- https://www.engadget.com/2014-10-07-alien-isolation-launch-interview.html
- https://www.heavymetal.com/post/ron-cobb-designer-of-nostromo-and-mcflys-delorean-1937-2020
- https://www.ea.com/ea-studios/motive/news/inside-dead-space-3-aboard-the-ishimura
- https://gamesbeat.com/dead-space-interview-fleshing-out-the-usg-ishimura/
- https://gamingbolt.com/little-nightmares-interview-into-the-maw
- https://blendogames.com/news/post/2025-07-02-skindeep_art/
- https://80.lv/articles/001agt-crafting-grand-well-balanced-environments
- https://www.gamedeveloper.com/design/how-to-reduce-visual-confusion-in-your-game
- https://brooks-newsletter-359c19.beehiiv.com/p/design-your-values-don-t-just-shade
- https://www.scalemodelshop.co.uk/scale-model-weathering-guide-realism/

**Real-world standards**
- https://www.cdc.gov/nchs/fastats/body-measurements.htm
- https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.29
- https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.25
- https://www.ecmweb.com/national-electrical-code/code-basics/article/21259374/nec-requirements-for-working-clearances
- FEMA E-74 §6.4.7.1 via https://femae74.atcouncil.org/docman/abbreviated/section-6-4/56-49-femae-74-chapter6-4-7-1
- Snippet only: ADA chapter 3, FEMA E-74 §6.6, the wbparts NSN listing

**Mobile and Godot**
- https://documentation-service.arm.com/static/65952df1159ca73387227425 (Arm 102643)
- https://developer.android.com/topic/performance/rendering/overdraw
- https://docs.imgtec.com/starter-guides/powervr-architecture/html/topics/hidden-surface-removal-efficiency.html
- https://blog.imaginationtech.com/improving-particle-systems-on-powervr/
- https://developer.apple.com/videos/play/wwdc2020/10631/
- https://realtimevfx.com/t/why-are-additive-shaders-so-heavy-for-phones/23998
- https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html
- https://docs.godotengine.org/en/stable/tutorials/2d/2d_meshes.html
- https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html
- https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
- https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html
- https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html
- https://docs.godotengine.org/en/stable/classes/class_canvasgroup.html
- https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html
- https://raw.githubusercontent.com/godotengine/godot/4.5-stable/doc/classes/ProjectSettings.xml
- https://registry.khronos.org/DataFormat/specs/1.3/dataformat.1.3.html
- https://github.com/ARM-software/astc-encoder/blob/main/Docs/FormatOverview.md
- https://android-developers.googleblog.com/2015/01/efficient-game-textures-with-hardware.html
- https://support.apple.com/en-us/111831
