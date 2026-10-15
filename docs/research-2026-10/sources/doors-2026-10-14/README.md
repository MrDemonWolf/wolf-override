# The doors of Records Access and the Service Junction, October 13-14, 2026

The record of how the doors after the corridor were built: the Records Access entry and exit swing doors and the security container beside the exit, the Service Junction's entry swing door, its blast door (torn off and thrown when it blows, then walked through) and its sliding exit door. It holds the design, the paint, the cleanup, four fix rounds, five rounds of independent review, the approval and the landing on main. Original game, story and creative direction: **Nathanial Henniges**.

These notes are tracked in the public repository by Nathanial's decision of 2026-10-11. They are working notes, not player-facing text: nothing here goes into the website, in-game text or build output.

## What the pieces are

- **Records Access entry and exit** (`records/`): 3'0" x 7'0" hollow-metal leaves on three butt hinges at one jamb (SDI 129), each in a cast-concrete cross-wall turned across the walkway like the corridor's door end, with a near column, a stub cut across the deck, a surface closer, a kick plate on the push face and a status lamp (red shut, amber moving, green open). The exit opens on a slow powered swing (ANSI/BHMA A156.19) once the first copy is secured in the dark security container beside it; the engineer walks out through it and WOLF follows.
- **Service Junction entry** (`junction-entry/`): the same door, closed behind the arriving pair by its closer.
- **Service Junction blast door** (`junction/`): a steel leaf on full-surface hinges (UFGS 08 39 54) in a concrete cross-wall, with a status lamp on its near column. At the blast it breaks, is thrown along the floor (0.24 s, tipping over; SDI 133 / ASTM F2927 category IV) and lands where it then lies, bowed, with its latch bolts standing out; the torn hinge leaves, keeper pockets, spalled corner and rubble stay in the frame.
- **Service Junction exit** (`junction-exit/`): a power-operated sliding steel door (UFGS 08 13 73) in a cross-wall at the room's right end, sliding into a pocket in the far jamb, with an exit bolt housing over its head, a wall pack, a striped leading edge (29 CFR 1910.144) and the service passage beyond. Once the bolt drops WOLF waits in its doorway; on leaving he walks out first and the engineer follows before the END OF SLICE card.

In the game they are four lossless atlases (`apps/game/assets/props/records-doors-atlas.png`, `junction-entry-atlas.png`, `junction-door-atlas.png`, `junction-exit-atlas.png`), edits to the Records and junction far and mid plates, and code in `records_room.gd`, `junction_room.gd`, `junction_door_layout.gd` (generated), `swing_leaf.gd`, `atlas_mesh.gd`, `room_depth.gd` and `main.gd`, with `tests/door_route_test.gd` and checks in the other suites. They replaced `junction-bulkhead-sealed/-breaking/-blown/-front-lip.png`, `corridor-bulkhead-open.png`, `junction-hatch.png` and `records-exit-hatch.png`, their imports and register entries, the bulkheads' full-size originals and `scripts/prepare_bulkheads.py` (all in the Git history).

## How they were made

The method is the corridor door end's (`../corridor-door-end-2026-10-12/`, and `../../art-direction/REAL-LOOK.md` section 8):

1. **Design first.** Python draws every part as an exact shape from measured real hardware, in each room's own camera (`records/tools/rdesign.py`, `junction/tools/jdesign.py`, `junction-exit/tools/design.py` and `geom.py`, `junction-entry/tools/jedesign.py`), with the specs in each `design/` folder. No image tool touches this step, and no part carries lettering.
2. **Paint.** Codex's built-in image generation tool, in edit mode, painted material and light only onto the construction renders, one Codex session per job (`codex/<job>/prompt.txt`, Codex's own notes in `codex/<job>/out/notes.txt`). The raw outputs behind the shipped atlases (fix round 2's, `codex/r2-*/out/`) are kept byte for byte with their C2PA content credentials; earlier rounds' outputs were superseded and are listed with their SHA-256 in `provenance.txt`. Every session is archived; none called an image API.
3. **Cleanup and install.** Deterministic Python (NumPy, SciPy, Pillow) registers each paint to its design, keeps paint only inside the design's masks, re-imposes exact alpha and values, grades to the room and packs the atlases (`*/tools/cleanup*.py`, `install*.py`, `placement.json`).
4. **Fix rounds 1-4** (`fix-r1/` to `fix-r4/`, each with its own tools and its section of `DOORS.md`): changes asked for by each review round. Rounds 3 and 4 ran no Codex session.
5. **Review.** After each round two independent reviewers looked at every rendered frame: one for realism against the hardware and the AI-tell checklist, one as a first-time player (`reviews/`).
6. **Approval.** Nathanial approved round 4 on 2026-10-14 from its frames ("Land them"), with the decisions recorded in `../../../decisions.md` ("Doors landed").
7. **Landing** (`landing/`): the package was ported onto main with a three-way merge and the review r5 fixes. See `landing/NOTES.md`.

## Files

- `DOORS.md`: the running record of every round, newest on top.
- `reviews/`: the realism reviews (`REVIEW-real-r1..r5.md`) and first-time-player reviews (`REVIEW-human-r1..r5.md`), and the package's own budget numbers (`perf-package.json`).
- `provenance.txt`: every Codex session (job, session id, inputs, outputs with SHA-256, C2PA presence, use), with scratch paths shortened to `doors-r1/...` and the home folder to `~`.
- `records/`, `junction/`, `junction-exit/`: each track's notes, design specs, placement and tools as built in round 1 (later rounds' changed tools are in `fix-r1/` to `fix-r4/`); `junction-entry/`: the entry door's notes from fix rounds 1-3 (it was first built in fix round 1) and its tools and design as of fix round 3.
- `fix-r1/` to `fix-r4/`: each fix round's tools and capture driver (fix round 1's entry door and exit door tools in `fix-r1/jentry/tools/` and `fix-r1/hatch/tools/`); `integration/`: the packaging tools.
- `codex/`: prompts and notes for every job, and the raw outputs of fix round 2's jobs.
- `landing/`: the landing's tools (`exit_fixes.py`, `leaf_wear.py`, `speckle.py`), its capture driver and the scripts used to run checks, render, compare budgets and file this folder.

Left out: the rendered captures, review crops and evidence sheets (large, and reproducible with the drivers), the `.npy` design caches, the scratch game copies, and the local copies of the standards and papers below (cited by link instead).

## Sources

Consulted for plausibility only; none of them is a contributor or endorses the game.

- UFGS 08 39 54, *Blast Resistant Doors* (USACE, NAVFAC, AFCEC): https://www.wbdg.org/ffc/dod/unified-facilities-guide-specifications-ufgs/ufgs-08-39-54
- UFGS 08 13 73, *Sliding Metal Doors*: https://www.wbdg.org/ffc/dod/unified-facilities-guide-specifications-ufgs/ufgs-08-13-73
- SDI 133 (Steel Door Institute), quoting ASTM F2927's door response categories: https://steeldoor.org/wp-content/uploads/2020/02/SDI_133.pdf; ASTM F2927 overview: https://www.intertek.com/building/standards/astm-f2927/
- Liu, Oesterle, Conway and Covino, *Modeling and Simulation of HD 1.3 Thermal Initiation Tests on a Small Reinforced Concrete Storage Structure* (NDIA, 2018): https://ndia.dtic.mil/wp-content/uploads/2018/intexpsafety/Liu2Paper.pdf
- Hartmann Tresore, HET 02 blast door data sheet: https://hartmann-tresore.ch/fileadmin/user_upload/tresore/Explosionsschutzt%C3%BCr/HET02.pdf
- Swiss Federal Office for Civil Protection, shelter closure technical provisions (TPH): https://www.babs.admin.ch/dam/de/sd-web/b3mfmfajan7s/tph19-de.pdf
- ICD/ICS 705 Technical Specifications for Construction and Management of SCIFs (NCSC): https://www.dni.gov/files/NCSC/documents/Regulations/Technical-Specifications-SCIF-Construction.pdf
- SDI 129, Hinge and Strike Spacing: https://steeldoor.org/wp-content/uploads/2020/02/SDI_129.pdf
- University of Michigan master specification 08 11 13, Hollow Metal Doors and Frames: https://umaec.umich.edu/for.archs/masterspec/08/MS081113.pdf
- GSA Class 5 legal size filing cabinets (AA-F-358): https://exwc.navfac.navy.mil/Portals/88/Documents/EXWC/DoD_Locks/PDFs/GSA_Class_5_Legal_Size_Filing_Cabinets.pdf
- ANSI/BHMA A156.19, as summarised at https://www.autodoorandhardware.com/Understanding-ANSI-A156-19-Low-Energy-Door-Operator-Require-s/123397.htm; ANSI/BHMA A156.6 (kick plates) cited by title only.
- OSHA 29 CFR 1910.144, safety colour code: https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.144

## Credits and tools

Original game, story and creative vision: Nathanial Henniges, who directed and approved this work. Built with AI assistance: the paint by Codex's built-in image generation tool (OpenAI) in edit mode; the design, cleanup, fix rounds and the landing by AI coding agents (Codex and Claude Code by Anthropic) under Nathanial's direction, with Python (NumPy, SciPy, Pillow), Godot 4.7.2 (headless checks, and rendered stills through `tools/render/render.sh`, which runs Godot with software rendering in a container) and cwebp for the website image.
