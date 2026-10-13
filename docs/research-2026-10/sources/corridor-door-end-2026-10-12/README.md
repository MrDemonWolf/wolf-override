# The corridor's door end, October 11-12, 2026

The record of how the end of the maintenance corridor was rebuilt: the research behind it, the design, the paint, the cleanup, six review rounds and the approval. Original game, story and creative direction: **Nathanial Henniges**.

These notes are tracked in the public repository by Nathanial's decision of 2026-10-11. They are working notes, not player-facing text: nothing here goes into the website, in-game text or build output.

## What the piece is

The corridor's sealed door used to be a free-standing red pressure bulkhead in the middle of the walkway, with a small wheel on a floor stand beside the relay as its manual bypass. It is now:

- a **cast-concrete cross-wall** standing across the corridor, its face turned 17 degrees toward the camera (the approved concept's "slight angle"), cut down to a 0.15 m stub toward the camera so the play view stays open;
- a **rolling steel service door** in it (3.05 m opening, 66.7 mm slats, hood, guides, striped bottom bar, threshold), marked `SECTOR 4B` and `DOOR 4B-07` in typeset stencil;
- a slim **near column** with a guarded status lamp (live: red shut, amber moving, green open), its conduit, push buttons and a fixed camera;
- a **wall-mounted MANUAL BYPASS**: a 0.525 m handwheel on a worm gearbox on a steel backplate at the wall's corner, with an enclosed chain guard running up to the door operator;
- a **machinery room** past the doorway (pump skid, expansion tank, catwalk, two high-bays), painted once into the corridor's far plate;
- the **coolant relay and safe point** in their approved Look 2 art, on bolted steel plinths with painted contact shadows.

In the game it is one lossless atlas (`apps/game/assets/props/corridor-seal-atlas.png`), a rebuilt right end of `corridor-far.png`, an edited `corridor-mid.png`, two replaced station props, and code in `main.gd`, `room_depth.gd`, `seal_leaf.gd` and `bypass_handle.gd`. It replaced `corridor-bulkhead-sealed.png` and `corridor-bulkhead-front-lip.png` and their full-size originals (deleted; they are in the Git history). `corridor-bulkhead-open.png` stays because the Service Junction's exit hatch shows a cut of its doorway. Gameplay positions, reaches and rules are unchanged.

## How it was made, step by step

1. **Audit** (2026-10-11, `research/AUDIT.md`, `research/props-measured.json`): what in the game read as AI-made or unreal, from in-game captures, with every machine's grounding and scale measured. The door end was the worst offender.
2. **Research** (2026-10-11, `research/RESEARCH.md`): what makes images read as generated, how shipped side-view games make their worlds look real, and how to render layered 2D cheaply on phones. Every claim carries its source.
3. **Anatomy** (2026-10-11, `research/ANATOMY.md`): real rolling doors, manual overrides, cabinets, conduit, luminaires, safety marking and drains, with dimensions converted to game scale (1 m = 40 world px). The military-base material from the same night lives in `../../art-direction/REAL-LOOK.md` section 8.
4. **Design first** (`DESIGN.md`, `spec.json`, `tools/design/`): Python draws every part as an exact shape from those numbers, in the plate's own measured camera, with a flat light plan. No image tool touches this step. Signs are typeset from the game's own Roboto (OFL).
5. **Paint** (`codex/`, `tools/paint/`, `tools/codex/`): Codex's built-in image generation tool, in **edit mode**, paints material and the designed light onto the construction renders, one Codex session per job, with rules that forbid new parts, lettering, greebles and grunge and require keeping all metadata. Each prompt is in `codex/<job>/prompt.txt`; Codex's own notes with the exact image-tool prompts are in `codex/<job>/out/notes.txt`; the edit targets are in `codex/<job>/refs/`.
6. **Cleanup** (`tools/layers/cleanup*.py`): deterministic Python registers each paint-over to its drawing, keeps paint only inside each part's mask, re-imposes the design's exact alpha, holds values to the light plan, calms large faces, and composites the typeset marks. The Codex originals are never modified.
7. **Install** (`tools/layers/install*.py`): packs the pieces into one atlas and writes the far and mid plates. `install6.py` reproduces the three installed files byte for byte (checked 2026-10-12 when this folder was added).
8. **Review**: after each round an independent, adversarial reviewer looked at every rendered frame as a first-time player, ran the AI-tell checklist, re-measured the numbers and re-checked provenance (`review/`).
9. **Approval and landing**: Nathanial approved the round-6 build on 2026-10-12, and it was ported onto main with a three-way merge and re-rendered to prove the port matches the approved frames.

The tools are kept as they ran, except that the session folder path at the top of each is now a `CONFIG` block (`WOLF_DOOR_END_WORK`, the working folder with `design/`, `layers/`, `paint/`, `codex/`, `game-main/` and `game-slice/`). Running them again needs Python with NumPy, SciPy and Pillow (the build used NumPy 2.5, SciPy 1.18 and Pillow 12.3).

## Who and what made it

- **Nathanial Henniges:** the game, its story and direction; the brief ("look real, no AI slop, no missing weird doors, no hovering items", "think as a human"); the approved shutter concept (`../doors-shutter-approved/`); the choice of a machinery room past the door; the approval of the piece and of the `SECTOR 4B` and `DOOR 4B-07` marks.
- **Claude Code (Anthropic), as AI assistants under his direction:** the audit, research and anatomy notes, the Python design, cleanup and install tools, the game code and tests, the six independent reviews, and this record.
- **Codex (OpenAI), its built-in image generation tool in edit mode:** the paint on the construction renders (seven sessions, below). No API, CLI fallback or other image tool was used.
- **Software:** Godot 4.7.2 (game and headless tests; rendered stills through `tools/render/render.sh` in a container), Python with NumPy, SciPy and Pillow, cwebp (libwebp) for the frames here, and the Roboto typeface (The Roboto Project Authors, SIL Open Font License 1.1).

## Codex sessions and raw outputs

Every output is copied byte for byte from Codex's generated-images folder and keeps its C2PA content credentials (`caBX` chunk with a `c2pa` JUMBF manifest). On 2026-10-12, when this folder was added, all nine were checked: SHA-256 equal to `provenance.txt` and to the session copies, `caBX` present. All seven sessions are archived in Codex.

| Job (folder) | Session | Date | Output (SHA-256 starts) | In the game? |
|---|---|---|---|---|
| `paint-far` | 01a12df6-8cdc-7d03-9375-c4c7b7cbada9 | 2026-10-11 | `far-painted.png` (c42c4d31) | No: round 0, superseded by paint-far2b |
| `paint-portal` | 01a12df6-8cdc-7e72-a1b2-ceeae3965247 | 2026-10-11 | `portal-closed-painted.png` (00bed3c8), `portal-open-painted.png` (b4f17141) | No: round 0 bulkhead, rejected |
| `paint-stations` | 01a12df6-8cdc-7a20-8b51-98a7971a322b | 2026-10-11 | `stations-painted.png` (c286aa93) | Yes: the plinths only (the Look 2 pixels are kept exactly) |
| `paint-far2` | 01a12e59-e7ba-7630-b1dc-9448924148ef | 2026-10-11 | `far2-painted.png` (461867b3) | No: superseded by paint-far2b |
| `paint-far2b` | 01a12e5c-eb97-7f63-b9cf-ec4e75fd8a9a | 2026-10-11 | `far2b-painted.png` (41e2232c) | Yes: the machinery room in the far plate |
| `paint-portal2` | 01a12e59-e7ba-7073-8a77-796f536bcc43 | 2026-10-11 | `portal2-closed-painted.png` (2b05522a), `portal2-open-painted.png` (9a7c71b7) | Yes: the wall, door, frame, column, camera and wheel paint |
| `paint-v3` | 01a1318b-1601-76e2-8de2-0c19430d2c42 | 2026-10-12 | `door-end-v3-painted.png` (44ec168a) | Yes: the bypass, floor line, stub texture and plant slab |

The full record (every output including Codex's own discarded first tries, and which derived file each used output feeds) is `provenance.txt`. Fix rounds 3 to 5 started no Codex session: they moved existing paint onto corrected shapes or added light in Python. Home and session folder paths in `provenance.txt` and the Codex notes were shortened to `~/` and `scratchpad/` when they were copied here.

## Decisions and dates

- **2026-10-11, evening:** the doors, opening hatch and rooms read as AI slop; every piece goes design first, then paint, cleanup and an AI-tell review, one piece shown in the real game first (`../../art-direction/REAL-LOOK.md`). The corridor's door end is that first piece.
- **2026-10-11, night:** a near-future military base, hardened and run by automated systems; short typeset stencils allowed; an AI-defence film franchise is mood only, never its names, logos or designs. Nothing from those films is in this piece.
- **2026-10-11 to 12:** round 0 (a bulkhead in a back-wall pier) was rejected in review; from round 1 the door stands in a cross-wall across the corridor.
- **2026-10-12:** Nathanial saw the rendered before/after frames and chose "Yes, land it" once the last fix (the lamp conduit's top end) passed review round 6, and "Keep them" for `SECTOR 4B` and `DOOR 4B-07`.
- **2026-10-12, follow-ups he chose, made separately and not in this piece:** a steel blast frame, a `RESTRICTED AREA` sign, an inner blast door, real red beacons, a crank pose for the engineer and a real coolant plume.

## Review history

`review/REVIEW-round1.md` to `REVIEW-round6.md` are the independent reviews, kept as written; `SLICE.md` is the final round's report with the earlier rounds' reports below it. Every review looked at rendered stills from `tools/render/render.sh`; nothing was played by hand, so none of them makes a claim about how the game feels.

**Round 1 (fix needed).** The doorway was a real hole onto a painted machinery room and the door was built like a real rolling door, but eight problems remained: the door did not read as blocking the way (a door in a back-wall pier), a purple key-colour fringe outlined the bulkhead, a hard seam ran down the floor, the new wall light stopped dead at a column, contact shadows were weaker than main's, the floor-stand bypass did not read and the crank pose did not touch it, the catwalk was drawn through the tank, and the pier was an airbrush-smooth slab with no light source.

**Round 2 (fix needed).** The door now stood in a concrete cross-wall at a slight angle and the round-1 artefacts were gone, but the near pier turned to glass when an actor passed behind it, the cross-wall still did not cross the corridor, the bypass was not wall-mounted, the opening sequence was no longer pixel-identical to main, compression blocking showed on calm concrete, and the review package and provenance record were out of date (three sessions unrecorded and unarchived).

**Round 3 (fix needed).** The bypass was on the wall, the opening matched main apart from dust, provenance and C2PA were complete and draw calls fell by 15-17 per state. Still wrong: pale "cover silhouettes" lighter than the concrete, a near column that hid whoever used the safe point, and two places where the new art broke the plate's perspective (the wall's cut and the tank head). The crank still did not read, the grain was colour noise, and the plant floor had a hot spot.

**Round 4 (fix needed, close).** The column was slim, the silhouettes gone, the stub followed the wall's vanishing point, the tank head matched the camera. Two faults: a see-through slit in the near column (WOLF's head showed through it), and in-game text calling it "the red seal" while nothing on the door was red. Should-fixes: the bypass plate far from its wheel, two corridor bays with two finishes, a beacon hanging on bare wall.

**Round 5 (fix needed, one item).** Both round-4 faults closed and re-measured. One fault left: the status lamp's conduit started in mid-air with nothing at its top end. Smaller: the design notes listed a relay feed that is not drawn, the tank was lit from a fixture the player never sees, and a pale strip showed under the camera.

**Round 6 (pass).** The conduit now turns through an elbow into the camera's wall plate; the notes match the build, the tank has a faint rim from the visible high-bay, and the camera ghost is painted out. No new AI tell. Left for Nathanial: the long vertical conduit has no strap, and the coolant hiss while cranking reads as a glowing disc (shared effect, identical on main).

## Before and after

`frames/` holds four before/after pairs at 1280x720 each (main at 76d3a50 on the left, the approved round-6 build on the right), rendered with `tools/render/render.sh` and converted to WebP at quality 85: `s1` the door end at rest, `s3` cranking the bypass, `s5` the door open, `s7` at the safe point. They are rendered stills from scripted play, not hand-played.

## What is in this folder

| Path | What it is |
|---|---|
| `README.md` | This file. |
| `DESIGN.md`, `spec.json` | The final construction design (v6 section on top, earlier rounds below it) and the front parts' dimensions and jobs (`design/portal6/spec.json`). |
| `archive/DESIGN.round0.md` ... `round4.md` | The design notes as they stood after each earlier round. |
| `SLICE.md` | The final build report (fix round 5) with the round-4 report kept below it. |
| `review/REVIEW-round1.md` ... `round6.md` | The six independent reviews. |
| `research/RESEARCH.md`, `ANATOMY.md`, `AUDIT.md`, `props-measured.json` | The research, the hardware anatomy, the audit and its measurements. Notes only: the pages and PDFs they cite are linked, not copied. |
| `provenance.txt` | Every Codex session, output, SHA-256 and derived file, round by round. |
| `codex/<job>/` | Each paint job's `prompt.txt`, `session.txt`, edit targets (`refs/`) and raw outputs with C2PA (`out/`, with Codex's `notes.txt`). |
| `tools/design/` | Construction drawings, masks and specs (`portal6.py`, `compose6.py`, the modules they import, and every earlier round's tool). |
| `tools/layers/` | Cleanup and install (`cleanup6.py`, `install6.py`, their modules, and every earlier round's tool). |
| `tools/paint/`, `tools/codex/` | The edit-target builders and their inputs; the Codex job runner, its shared rules and the session archive log (`archive-log.txt`). |
| `frames/` | The four before/after pairs. |

Not kept here: the scratch renders, masks, layers and captures (rebuildable with the tools), the run logs, and every third-party page, PDF or image the research read.

## Credits: outside sources

Everything below was read for this piece and is cited, never copied. Pages marked *summary only* were seen only through a search-index summary and are leads, not facts.

### Real hardware and standards (`research/ANATOMY.md`, `research/RESEARCH.md`)

- Overhead Door Corporation, *Rolling Service Doors 610/620* brochure (C900-103 08/23): https://overheaddoor-production-assets.azureedge.net/assets/docs/default-source/commercial-products/rolling-service-doors/model-610/rolling-service-doors-610---620-brochure.pdf?sfvrsn=fa39521_11
- Cookson (CornellCookson), *Service Door Model ESD10 Technical Details* (6.2017): https://www.cooksondoor.com/docs/default-source/1v-data-sheets/technical-details-sheet/cookson/td_rolling_door_k.pdf?sfvrsn=b0a9476d_32
- Cookson, *How much headroom do you need for a roll-up door?*: https://www.cooksondoor.com/blogs/Cookson/roll-up-door-headroom
- Janus International, *Model 1100* specification (05.14.10): https://www.janusintl.com/hubfs/janus_2019/pdf/model1100.pdf
- Overhead Door, *RSX operator installation instructions*: https://overheaddoor-production-assets.azureedge.net/assets/docs/default-source/general-products/commercial-operators/rsx-operator-rolling-steel-installation-instructions.pdf?sfvrsn=5f63ce90_3
- Overhead Door, *RHX NEMA operator manual*: https://overheaddoor-production-assets.azureedge.net/assets/docs/default-source/owner's-manuals/operator-rhx-nema-manual.pdf?sfvrsn=f0e67fb7_2
- Overhead Door, *RHX commercial door operator* product page: https://www.overheaddoor.com/general-products/rhx-commercial-door-operator
- Cisco-Eagle, *Overhead Door LED Safety Light System*: https://www.cisco-eagle.com/product/193897/overhead-door-led-safety-light-system-for-powered-doors-four-5-led-strips
- U.S. Department of Defense, *MIL-STD-1472F, Human Engineering* (1999), copy hosted by UMTRI: http://mreed.umtri.umich.edu/trucksteps/documents/MIL-STD-1472F.pdf
- BSI, *EN 12570, Industrial valves: method for sizing the operating element* (summary page): https://knowledge.bsigroup.com/products/industrial-valves-method-for-sizing-the-operating-element
- Rittal, *VX25 baying enclosure 8806.000* (Standard Electric Supply listing): https://standardelectricsupply.com/Rittal-8806000-Baying-Enclosure-System
- Rittal, *VX 9680.806* product data: https://www.rittal.com/pdf-creator/variant/ca-en/9680806
- Rittal, *VX25 base/plinth system* accessories: https://rittal.com/com-en/products/PG0002SCHRANK1/PG0026SCHRANK1/PGRP21063SCHRANK1/PGRP26364SCHRANK1/PG23113001ZUB
- RS Components, *Rittal AX wall box 600 x 600 x 210* (RS 202-3917): https://my.rs-online.com/web/p/wall-boxes/2023917
- EC&M, *Stumped by the Code? NEC requirements for using and installing EMT*: https://www.ecmweb.com/national-electrical-code/qa/article/21270216/stumped-by-the-code-nec-requirements-for-using-and-installing-emt
- EC&M, *NEC requirements for working clearances*: https://www.ecmweb.com/national-electrical-code/code-basics/article/21259374/nec-requirements-for-working-clearances
- Steiner Electric, *B-Line 24A12-12-144 ladder cable tray* listing: https://steinerelectric.com/Catalog/ConduitFittings-And-Wireway/Cable-Trays-And-Struts/Cable-Trays/Ladder-Cable-Trays/B-Line-24A12-12-144-CABLE-TRAY-501833 (summary only)
- Eaton, *Metric cable ladder* catalog page: https://www.eaton.com/us/en-us/catalog/support-systems/metric-cable-ladder.html (summary only)
- Agilix, *Understanding NEMA standards for cable tray systems*: https://www.goagilix.com/blog/understanding-nema-standards-for-cable-tray-systems/
- Atkore, cable tray specification quoting NEMA VE 2: https://dam.atkore.com/api/public/content/5d57a58ed81a4f53a4d290c81c11d56e (summary only)
- Graybar, *Unistrut P1000 series solid strut channel*: https://graybar.com/p1000-series-solid-strut-channel-12-ga-steel-extruded-aluminum-10-ft-l-1-5-8-h-x-1-5-8-w-in-/p/92126303
- Elliott Electric Supply, *Lithonia CSVT* and *XVML* vapour-tight luminaire listings: https://elliottelectric.com/P/Item/LIT/CSVTL48AL03MV0LT and https://www.elliottelectric.com/P/Item/LIT/XVMLL485000LMMV0
- Standard Electric Supply, *Hubbell VMAG17 vaporproof globe guard*: https://standardelectricsupply.com/Hubbell-VMAG17-Vaporproof-Globe-Guard; Dixon Electric, *Hubbell VMAG25S* and *VAG-100* guards: https://dixonelectric.ca/products/18-lighting/02-fixtures/03-hazardous-location-vapor-tight-fixtures/02-special-environment-lighting-fixture-accessories/p-S0lMVk1BRzI1Uw==-hubbell-vmag25s-vm-7-34-stainless-guard-lo and https://dixonelectric.ca/products/18-lighting/02-fixtures/03-hazardous-location-vapor-tight-fixtures/02-special-environment-lighting-fixture-accessories/p-S0lMVkFHMTAw-hubbell-vag-100-guard-aluminum-guard-copperfree-aluminum-grayepoxy
- BGN, *ASR A1.3, section 5* (German workplace rule on safety marking): https://vorschriften.bgn-branchenwissen.de/daten/tr/asr_a1_3/5.htm
- Wikipedia, *ISO 3864*: https://en.wikipedia.org/wiki/ISO_3864
- OSHA, standard interpretation of 15 May 1972 on aisle markings: https://osha.gov/laws-regs/standardinterpretations/1972-05-15
- OSHA, *29 CFR 1910.29* and *1910.25*: https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.29 and https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.25
- ACO, *KlassikDrain* brochure: https://www.acodrain.com.au/drain/pdf/klassikdrain.pdf; BuildSite, *ACO KlassikDrain K100/KS100 spec data*: https://www.buildsite.com/pdf/aco/KlassikDrain-K100KS100-Steel-Edge-Rail-Channel-System-4-internal-width-Spec-Data-2914681.pdf (summary only)
- Zurn, *Z415 floor drain* spec sheet (WebstaurantStore copy): https://www.webstaurantstore.com/documents/specsheets/z415s_specs.pdf (summary only)
- CDC National Center for Health Statistics, *FastStats: Body Measurements*: https://www.cdc.gov/nchs/fastats/body-measurements.htm
- Applied Technology Council for FEMA, *FEMA E-74, section 6.4.7.1*: https://femae74.atcouncil.org/docman/abbreviated/section-6-4/56-49-femae-74-chapter6-4-7-1

### What reads as AI-made (`research/RESEARCH.md` part A)

- Hany Farid, *Perspective (In)consistency of Paint by Text* (arXiv 2206.14617): https://ar5iv.labs.arxiv.org/html/2206.14617
- Hany Farid, *Lighting (In)consistency of Paint by Text* (arXiv 2207.13744): https://ar5iv.labs.arxiv.org/html/2207.13744
- UC Berkeley School of Information, *"A certain ethereal quality": Hany Farid explains why AI art looks the way it does*: https://www.ischool.berkeley.edu/news/2024/certain-ethereal-quality-hany-farid-explains-why-ai-art-looks-way-it-does
- 80 Level, *Should you hire an AI artist or a concept artist?* (Miguel Nogueira): https://80.lv/articles/should-you-hire-an-ai-artist-or-a-concept-artist
- MTG Rocks, *Wizards of the Coast accused of using AI art in MTG promotion again*: https://mtgrocks.com/wizards-of-the-coast-accused-of-using-ai-art-in-mtg-promotion-again/
- Vice, *Magic: The Gathering publisher denies, then admits using AI art in promo image*: https://vice.com/en/article/magic-the-gathering-publisher-denies-then-admits-using-ai-art-in-promo-image
- Keith Kisser, *Why does all AI art look like that?* (Vocal Media; also on Medium): https://vocal.media/art/why-does-all-ai-art-look-like-that
- Summary only: GameSpot, *Video game concept artists say GenAI isn't making things easier* (https://www.gamespot.com/articles/video-game-concept-artists-say-genai-isnt-making-things-easier/1100-6537107/); an Elder Scrolls Online forum thread on loading-screen art (https://forums.elderscrollsonline.com/en/discussion/681310/concerned-about-the-potential-use-of-ai-on-loading-screen-artwork); Wikipedia, *Greeble* (https://en.wikipedia.org/wiki/Greeble); isitai.com, *How to spot AI art* (https://isitai.com/blog/how-to-spot-ai-art).

### How shipped games look real (`research/RESEARCH.md` part B)

- Mikkel Gjøl and Mikkel Svendsen (Playdead), *Low Complexity, High Fidelity: The Rendering of INSIDE* (GDC talk slides): http://loopit.dk/rendering_inside.pdf
- Kill Screen, *A must-read history of Limbo*: https://www.killscreen.com/must-read-history-limbo/
- Game Developer, *GDC 2011: Eric Chahi's retro postmortem of Another World*: https://www.gamedeveloper.com/game-platforms/gdc-2011-eric-chahi-s-retro-postmortem-i-another-world-i-
- Nintendo Life, *Freedom fighter: Paul Cuisset on the making of Flashback* (2018): https://www.nintendolife.com/news/2018/06/feature_freedom_fighter_paul_cuisset_on_the_making_of_flashback
- Film Stories, *Planet of Lana: 2023's prettiest sci-fi platformer*: https://filmstories.co.uk/features/planet-of-lana-2023s-prettiest-sci-fi-platformer/
- GamingBolt, *Planet of Lana 2: Children of the Leaf interview*: https://gamingbolt.com/planet-of-lana-2-children-of-the-leaf-interview-art-direction-varied-environments-hybrid-robots-and-more
- HUDS+GUIS, *Alien: Isolation*: https://www.hudsandguis.com/home/2014/06/04/alien-isolation
- TheSixthAxis, *Talking Alien: Isolation with The Creative Assembly's Jude Bond*: https://www.thesixthaxis.com/2014/06/10/talking-alien-isolation-with-the-creative-assemblys-jude-bond/
- Engadget, *Alien: Isolation* launch interview (2014-10-07): https://www.engadget.com/2014-10-07-alien-isolation-launch-interview.html
- Heavy Metal, *Ron Cobb, designer of Nostromo and McFly's DeLorean (1937-2020)*: https://www.heavymetal.com/post/ron-cobb-designer-of-nostromo-and-mcflys-delorean-1937-2020
- EA / Motive, *Inside Dead Space: aboard the Ishimura*: https://www.ea.com/ea-studios/motive/news/inside-dead-space-3-aboard-the-ishimura
- GamesBeat, *Dead Space interview: fleshing out the USG Ishimura*: https://gamesbeat.com/dead-space-interview-fleshing-out-the-usg-ishimura/
- GamingBolt, *Little Nightmares interview: Into the Maw*: https://gamingbolt.com/little-nightmares-interview-into-the-maw
- Brendon Chung (Blendo Games), *Skin Deep art* (2025-07-02): https://blendogames.com/news/post/2025-07-02-skindeep_art/
- Brie Gibson, interviewed by 80 Level, *001AGT: crafting grand, well-balanced environments*: https://80.lv/articles/001agt-crafting-grand-well-balanced-environments
- Game Developer, *How to reduce visual confusion in your game*: https://www.gamedeveloper.com/design/how-to-reduce-visual-confusion-in-your-game
- Brooks (newsletter), *Design your values, don't just shade*: https://brooks-newsletter-359c19.beehiiv.com/p/design-your-values-don-t-just-shade
- Scale Model Shop, *Scale model weathering guide: realism*: https://www.scalemodelshop.co.uk/scale-model-weathering-guide-realism/

### Rendering on phones and in Godot (`research/RESEARCH.md` part C)

- Arm, *Optimization advice for graphics content on mobile devices* (document 102643, issue 01, January 2024): https://documentation-service.arm.com/static/65952df1159ca73387227425
- Android Developers, *Reduce overdraw*: https://developer.android.com/topic/performance/rendering/overdraw
- Imagination Technologies, *PowerVR architecture: hidden surface removal efficiency*: https://docs.imgtec.com/starter-guides/powervr-architecture/html/topics/hidden-surface-removal-efficiency.html
- Imagination Technologies blog, *Improving particle systems on PowerVR*: https://blog.imaginationtech.com/improving-particle-systems-on-powervr/
- Apple Developer, WWDC20 session 10631 (on Apple GPUs' hidden surface removal and tile memory): https://developer.apple.com/videos/play/wwdc2020/10631/
- Real Time VFX forum, *Why are additive shaders so heavy for phones?*: https://realtimevfx.com/t/why-are-additive-shaders-so-heavy-for-phones/23998
- Godot Engine documentation (stable): *Multiple resolutions*, *2D meshes*, *2D lights and shadows*, *Renderers*, *GPU optimization*, *Importing images*, *CanvasGroup*, *Screen-reading shaders*: https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html, https://docs.godotengine.org/en/stable/tutorials/2d/2d_meshes.html, https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html, https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html, https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html, https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html, https://docs.godotengine.org/en/stable/classes/class_canvasgroup.html, https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html
- Godot Engine contributors, `ProjectSettings.xml` class reference (4.5-stable): https://raw.githubusercontent.com/godotengine/godot/4.5-stable/doc/classes/ProjectSettings.xml
- Khronos Group, *Khronos Data Format Specification 1.3*: https://registry.khronos.org/DataFormat/specs/1.3/dataformat.1.3.html
- Arm, *astc-encoder: ASTC format overview*: https://github.com/ARM-software/astc-encoder/blob/main/Docs/FormatOverview.md
- Android Developers Blog, *Efficient game textures with hardware compression* (2015): https://android-developers.googleblog.com/2015/01/efficient-game-textures-with-hardware.html
- Apple Support, *iPhone 15 technical specifications* (page 111831): https://support.apple.com/en-us/111831

The military-base sources (the U.S. Unified Facilities Criteria and guide specifications on WBDG, MIL-STD-130N, the Army's TB 746-93-1 marking bulletin, FED-STD-595C colour data, the National Park Service's Titan II and Minuteman records, and others) are credited in `../../art-direction/REAL-LOOK.md` section 8; their downloaded texts were not copied into the repository.
