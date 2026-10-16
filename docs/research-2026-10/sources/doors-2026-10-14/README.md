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
3. **Cleanup and install.** Deterministic Python (NumPy, SciPy, Pillow) registers each paint to its design, keeps paint only inside the design's masks, re-imposes exact alpha and values, grades to the room and packs the atlases (`*/tools/cleanup.py`, `*/tools/*install.py`, `placement.json`).
4. **Fix rounds 1-4** (each with its section of `DOORS.md`): changes asked for by each review round. Rounds 3 and 4 ran no Codex session. Each track's tools as they stand now, after the rounds that changed them, are in its own `tools/` folder; the tools several rounds used are in `tools/`; `fix-r1/` to `fix-r4/` keep what only that round used.
5. **Review.** After each round two independent reviewers looked at every rendered frame: one for realism against the hardware and the AI-tell checklist, one as a first-time player (`reviews/`).
6. **Approval.** Nathanial approved round 4 on 2026-10-14 from its frames ("Land them"), with the decisions recorded in `../../../decisions.md` ("Doors landed").
7. **Landing** (`landing/`): the package was ported onto main with a three-way merge and the review r5 fixes. See `landing/NOTES.md`.

## Files

- `DOORS.md`: the running record of every round, newest on top.
- `reviews/`: the realism reviews (`REVIEW-real-r1..r5.md`) and first-time-player reviews (`REVIEW-human-r1..r5.md`), and the package's own budget numbers (`perf-package.json`).
- `provenance.txt`: every Codex session (job, session id, inputs, outputs with SHA-256, C2PA presence, use), with scratch paths shortened to `doors-r1/...` and the home folder to `~`.
- `records/`, `junction/`, `junction-exit/`, `junction-entry/`: each track's notes (`NOTES.md`), design specs and placement as built in round 1 (the entry door's from fix round 1, when it was first built), and in `tools/` the track's tools in their current version: the one that made the shipped atlas. Earlier versions that differ are cited by commit in the tool map below.
- `tools/`: one copy of each tool more than one round used: the grading, measuring, ghost-check and packaging tools, `rebuild.sh`, and the render wrapper (`render.sh`), suite runner (`suite.sh`), Codex job runner (`run_codex.sh`) and capture driver (`driver/doors_capture.gd`, in its own folder because `render.sh --driver` copies the whole folder into the game).
- `fix-r1/` to `fix-r4/`: the tools, data and notes only that round used (for example `fix-r3/tools/leafwear.py`, `fix-r4/tools/steamlap.py` and round 4's `rebuild.sh`).
- `codex/`: prompts and notes for every job, and the raw outputs of fix round 2's jobs.
- `landing/`: the landing's tools (`landing/tools/exit_fixes.py`, `leaf_wear.py`, `speckle.py`), the panel capture driver (`landing/driver2/`) and the scripts used to compare budgets, make sheets and file this folder (`file_records.py`, which filed the layout before the consolidation below).

## Tool map (October 15, 2026)

Until October 15 each fix round filed its own copy of every tool it ran, so most tools were here two to four times, mostly byte for byte. AGENTS.md's "Don't duplicate code" rule keeps one current copy of each; `landing/NOTES.md` ("Shared code") has the counts. Every earlier version that differs is cited as `<path> at <commit>`: read it with `git show <commit>:docs/research-2026-10/sources/doors-2026-10-14/<path>`. dee9996 is the commit that filed these records and 7d55687 the one that filed fix round 1's entry and exit door tools; both are in the branch history.

"At bc1b51e" says where each kept file's bytes were just before the consolidation (bc1b51e, the doors branch head before October 15, is in the history too): moved here with `git mv`, already here, or copied over this path's earlier version from a fix round's copy, and which same-bytes copies were removed. A filed script that calls a tool by its round path names the file this column gives: for example `fix-r4/rebuild.sh` runs `$R3/rebuild.sh`, that is `fix-r3/rebuild.sh`, now `tools/rebuild.sh`.

| Kept | Blob | Same-bytes copies removed | At bc1b51e | Earlier versions, cited |
|---|---|---|---|---|
| `records/tools/cleanup.py` | 00e71c7a | 1 | copied over this path's earlier version from `fix-r3/records/tools/cleanup.py` (removed); same bytes removed: `fix-r2/records/cleanup.py` | `records/tools/cleanup.py` at dee9996 |
| `records/tools/compose.py` | 858ffad9 | 2 | here; same bytes removed: `fix-r2/records/compose.py`, `fix-r3/records/tools/compose.py` | - |
| `records/tools/install.py` | 75a80f3b | 1 | copied over this path's earlier version from `fix-r3/records/tools/install.py` (removed); same bytes removed: `fix-r2/records/install.py` | `records/tools/install.py` at dee9996 |
| `records/tools/paint_inputs.py` | b67e17cc | 1 | copied over this path's earlier version from `fix-r3/records/tools/paint_inputs.py` (removed); same bytes removed: `fix-r2/records/paint_inputs.py` | `records/tools/paint_inputs.py` at dee9996 |
| `records/tools/preview_clean.py` | acdaf573 | 2 | here; same bytes removed: `fix-r2/records/preview_clean.py`, `fix-r3/records/tools/preview_clean.py` | - |
| `records/tools/rbbox.py` | 2cd72e83 | 1 | moved here from `fix-r2/records/rbbox.py`; same bytes removed: `fix-r3/records/tools/rbbox.py` | - |
| `records/tools/rdesign.py` | f666afc7 | 1 | copied over this path's earlier version from `fix-r3/records/tools/rdesign.py` (removed); same bytes removed: `fix-r2/records/rdesign.py` | `records/tools/rdesign.py` at dee9996 |
| `records/tools/rmodel.py` | 350d3b96 | 1 | copied over this path's earlier version from `fix-r3/records/tools/rmodel.py` (removed); same bytes removed: `fix-r2/records/rmodel.py` | `records/tools/rmodel.py` at dee9996 |
| `records/tools/rules.txt` | 4aabb2a7 | 1 | here; same bytes removed: `fix-r3/records/tools/rules.txt` | - |
| `junction/tools/bbox.py` | 3120e610 | 1 | moved here from `fix-r2/junction/bbox.py`; same bytes removed: `fix-r3/junction/tools/bbox.py` | - |
| `junction/tools/cleanup.py` | e0997672 | 1 | copied over this path's earlier version from `fix-r3/junction/tools/cleanup.py` (removed); same bytes removed: `fix-r2/junction/cleanup.py` | `junction/tools/cleanup.py` at dee9996 |
| `junction/tools/codex_inputs.py` | 5304f598 | 1 | copied over this path's earlier version from `fix-r3/junction/tools/codex_inputs.py` (removed); same bytes removed: `fix-r2/junction/codex_inputs.py` | `junction/tools/codex_inputs.py` at dee9996 |
| `junction/tools/install.py` | 06867f40 | 0 | copied over this path's earlier version from `fix-r3/junction/tools/install.py` (removed) | `junction/tools/install.py` at dee9996; `fix-r2/junction/install.py` at dee9996 |
| `junction/tools/jdesign.py` | ab05ac2c | 1 | copied over this path's earlier version from `fix-r3/junction/tools/jdesign.py` (removed); same bytes removed: `fix-r2/junction/jdesign.py` | `junction/tools/jdesign.py` at dee9996 |
| `junction/tools/jgrade.py` | 2ecb41d4 | 1 | moved here from `fix-r2/junction/jgrade.py`; same bytes removed: `fix-r3/junction/tools/jgrade.py` | - |
| `junction/tools/jgrade2.py` | 35d0ff42 | 0 | moved here from `fix-r3/junction/tools/jgrade2.py` | `fix-r2/junction/jgrade2.py` at dee9996 |
| `junction/tools/jmodel.py` | a40018f1 | 1 | copied over this path's earlier version from `fix-r3/junction/tools/jmodel.py` (removed); same bytes removed: `fix-r2/junction/jmodel.py` | `junction/tools/jmodel.py` at dee9996 |
| `junction/tools/preview.py` | e8a45d90 | 2 | here; same bytes removed: `fix-r2/junction/preview.py`, `fix-r3/junction/tools/preview.py` | - |
| `junction/tools/lying3.py` | ab1d9c79 | 0 | moved here from `fix-r3/junction/tools/lying3.py` | - |
| none: it carried game code, which is in `apps/game` and the history |  | 0 | - | `integration/patch_game.py` at dee9996; `junction/tools/patch_game.py` at dee9996; `fix-r2/junction/patch_game.py` at dee9996; `fix-r3/junction/tools/patch_game.py` at dee9996 |
| none: it carried game code, which is in `apps/game` and the history |  | 0 | - | `integration/patch_extra.py` at dee9996; `junction/tools/patch_extra.py` at dee9996; `fix-r2/junction/patch_extra.py` at dee9996; `fix-r3/junction/tools/patch_extra.py` at dee9996 |
| none: it carried game code, which is in `apps/game` and the history |  | 2 | - | `records/tools/patch_main.py` at dee9996 (the same file as `fix-r2/records/patch_main.py` at dee9996 and `fix-r3/records/tools/patch_main.py` at dee9996) |
| none: it carried game code, which is in `apps/game` and the history |  | 0 | - | `junction-exit/templates/junction_room.gd.tmpl` at dee9996 |
| `../corridor-door-end-2026-10-12/tools/layers/imgkit.py` (main's copy) | 94a33458 | 7 | removed: `fix-r1/hatch/tools/imgkit.py`, `fix-r2/hatch/imgkit.py`, `fix-r2/junction/imgkit.py`, `fix-r3/hatch/tools/imgkit.py`, `fix-r3/junction/tools/imgkit.py`, `junction-exit/tools/imgkit.py`, `junction/tools/imgkit.py` | - |
| `junction-exit/tools/cleanup.py` | a8df00fe | 0 | copied over this path's earlier version from `fix-r3/hatch/tools/cleanup.py` (removed) | `junction-exit/tools/cleanup.py` at dee9996; `fix-r1/hatch/tools/cleanup.py` at 7d55687; `fix-r2/hatch/cleanup.py` at dee9996 |
| `junction-exit/tools/compose.py` | 3b8f56fb | 1 | copied over this path's earlier version from `fix-r3/hatch/tools/compose.py` (removed); same bytes removed: `fix-r2/hatch/compose.py` | `junction-exit/tools/compose.py` at dee9996; `fix-r1/hatch/tools/compose.py` at 7d55687 |
| `junction-exit/tools/design.py` | df2f0bf0 | 1 | copied over this path's earlier version from `fix-r3/hatch/tools/design.py` (removed); same bytes removed: `fix-r2/hatch/design.py` | `junction-exit/tools/design.py` at dee9996; `fix-r1/hatch/tools/design.py` at 7d55687 |
| `junction-exit/tools/geom.py` | fb0b639e | 1 | copied over this path's earlier version from `fix-r3/hatch/tools/geom.py` (removed); same bytes removed: `fix-r2/hatch/geom.py` | `junction-exit/tools/geom.py` at dee9996; `fix-r1/hatch/tools/geom.py` at 7d55687 |
| `junction-exit/tools/hinstall.py` | bf7fd006 | 1 | moved here from `fix-r2/hatch/hinstall.py`; same bytes removed: `fix-r3/hatch/tools/hinstall.py` | `fix-r1/hatch/tools/hinstall.py` at 7d55687 |
| `junction-exit/tools/install.py` | be78771c | 3 | here; same bytes removed: `fix-r1/hatch/tools/install.py`, `fix-r2/hatch/install.py`, `fix-r3/hatch/tools/install.py` | - |
| `junction-exit/tools/leaf.py` | c3067d59 | 3 | here; same bytes removed: `fix-r1/hatch/tools/leaf.py`, `fix-r2/hatch/leaf.py`, `fix-r3/hatch/tools/leaf.py` | - |
| `junction-exit/tools/manifest.py` | 7ce34281 | 3 | here; same bytes removed: `fix-r1/hatch/tools/manifest.py`, `fix-r2/hatch/manifest.py`, `fix-r3/hatch/tools/manifest.py` | - |
| `junction-exit/tools/noleaf.py` | f5cd073b | 3 | here; same bytes removed: `fix-r1/hatch/tools/noleaf.py`, `fix-r2/hatch/noleaf.py`, `fix-r3/hatch/tools/noleaf.py` | - |
| `junction-entry/tools/jeclean.py` | 20bce038 | 2 | here; same bytes removed: `fix-r2/jentry/jeclean.py`, `fix-r3/jentry/tools/jeclean.py` | `fix-r1/jentry/tools/jeclean.py` at 7d55687 |
| `junction-entry/tools/jedesign.py` | a58d27e3 | 2 | here; same bytes removed: `fix-r2/jentry/jedesign.py`, `fix-r3/jentry/tools/jedesign.py` | `fix-r1/jentry/tools/jedesign.py` at 7d55687 |
| `junction-entry/tools/jeinputs.py` | 595e8eaf | 2 | here; same bytes removed: `fix-r2/jentry/jeinputs.py`, `fix-r3/jentry/tools/jeinputs.py` | `fix-r1/jentry/tools/jeinputs.py` at 7d55687 |
| `junction-entry/tools/jeinstall.py` | 797c8d42 | 1 | here; same bytes removed: `fix-r3/jentry/tools/jeinstall.py` | `fix-r1/jentry/tools/jeinstall.py` at 7d55687; `fix-r2/jentry/jeinstall.py` at dee9996 |
| `junction-entry/tools/jemid.py` | 2b97ae95 | 1 | here; same bytes removed: `fix-r3/jentry/tools/jemid.py` | `fix-r2/jentry/jemid.py` at dee9996 |
| `junction-entry/tools/jemodel.py` | 03640720 | 3 | here; same bytes removed: `fix-r1/jentry/tools/jemodel.py`, `fix-r2/jentry/jemodel.py`, `fix-r3/jentry/tools/jemodel.py` | - |
| `tools/grade.py` | 2d3aa3d9 | 2 | moved here from `fix-r1/tools/grade.py`; same bytes removed: `fix-r2/tools/grade.py`, `fix-r3/tools/grade.py` | - |
| `tools/grade2.py` | e52eef95 | 1 | moved here from `fix-r2/tools/grade2.py`; same bytes removed: `fix-r3/tools/grade2.py` | - |
| `tools/rgrade.py` | e6234551 | 2 | moved here from `fix-r1/tools/rgrade.py`; same bytes removed: `fix-r2/tools/rgrade.py`, `fix-r3/tools/rgrade.py` | - |
| `tools/rgrade2.py` | 769d7adf | 0 | moved here from `fix-r3/tools/rgrade2.py` | `fix-r2/tools/rgrade2.py` at dee9996 |
| `tools/feedback.py` | bc66b406 | 1 | moved here from `fix-r2/tools/feedback.py`; same bytes removed: `fix-r3/tools/feedback.py` | - |
| `tools/ghostcheck.py` | fe28dc22 | 1 | moved here from `fix-r2/tools/ghostcheck.py`; same bytes removed: `fix-r3/tools/ghostcheck.py` | - |
| `tools/manifest_r2.py` | 820d0630 | 1 | moved here from `fix-r2/tools/manifest_r2.py`; same bytes removed: `fix-r3/tools/manifest_r2.py` | - |
| `tools/measure3.py` | 6334c17a | 1 | moved here from `fix-r2/tools/measure3.py`; same bytes removed: `fix-r3/tools/measure3.py` | - |
| `tools/measure4.py` | c0b59a8b | 1 | moved here from `fix-r2/tools/measure4.py`; same bytes removed: `fix-r3/tools/measure4.py` | - |
| `tools/measure_r2.py` | fade0d9d | 2 | moved here from `fix-r1/tools/measure_r2.py`; same bytes removed: `fix-r2/tools/measure_r2.py`, `fix-r3/tools/measure_r2.py` | - |
| `tools/package.py` | d1663468 | 0 | moved here from `fix-r4/tools/package.py` | `integration/package.py` at dee9996; `fix-r1/tools/package.py` at dee9996; `fix-r2/tools/package.py` at dee9996; `fix-r3/tools/package.py` at dee9996 |
| `tools/perftable.py` | 58cc1b51 | 0 | moved here from `fix-r4/tools/perftable.py` | `fix-r3/tools/perftable.py` at dee9996 |
| `tools/sentry-load.sh` | 493354f5 | 0 | moved here from `fix-r4/tools/sentry-load.sh` | `fix-r3/tools/sentry-load.sh` at dee9996 |
| `tools/render.sh` | 40a683c5 | 0 | moved here from `landing/render.sh` | `fix-r1/render.sh` at dee9996; `fix-r2/render.sh` at dee9996; `fix-r3/render.sh` at dee9996; `fix-r4/render.sh` at dee9996 |
| `tools/suite.sh` | c944c442 | 0 | moved here from `landing/suite.sh` | `records/tools/run_suites.sh` at dee9996; `junction/tools/run_checks.sh` at dee9996; `fix-r1/run-suites.sh` at dee9996; `fix-r2/run-suites.sh` at dee9996; `fix-r3/records/tools/run_suites.sh` at dee9996; `fix-r3/junction/tools/run_checks.sh` at dee9996; `fix-r3/run-suites.sh` at dee9996; `fix-r4/run-suites.sh` at dee9996 |
| `tools/run_codex.sh` | 8643f8fe | 2 | moved here from `fix-r1/run_codex.sh`; same bytes removed: `fix-r2/run_codex.sh`, `fix-r3/run_codex.sh` | `records/tools/run_job.sh` at dee9996; `junction-exit/tools/run_codex.sh` at dee9996; `fix-r1/hatch/tools/run_codex.sh` at 7d55687; `fix-r3/hatch/tools/run_codex.sh` at dee9996; `fix-r3/records/tools/run_job.sh` at dee9996 |
| `tools/rebuild.sh` | aca17d4e | 0 | moved here from `fix-r3/rebuild.sh` | `fix-r2/rebuild.sh` at dee9996 |
| `tools/driver/doors_capture.gd` | 8f7c9ec6 | 0 | moved here from `landing/driver/doors_capture.gd`, then given the blast-frame fix | `landing/driver/doors_capture.gd` at dee9996 (the landing's stills; before the October 15 blast-frame fix); `integration/doors_capture.gd` at dee9996; `fix-r1/driver/doors_capture.gd` at dee9996; `fix-r2/driver/doors_capture.gd` at dee9996; `fix-r3/driver/doors_capture.gd` at dee9996; `fix-r4/driver/doors_capture.gd` at dee9996 |
| `DOORS.md` |  | 4 | here | the fix rounds' `fix-r1/doors-section.md` at dee9996 to `fix-r4/doors-section.md` at dee9996 were copies of its sections (every line is in it) |
| `junction-entry/NOTES.md` |  | 3 | moved here from `junction-entry/NOTES-fix-r3.md`, then updated | was `junction-entry/NOTES-fix-r3.md` at dee9996; `junction-entry/NOTES-fix-r1.md` at dee9996, `junction-entry/NOTES-fix-r2.md` at dee9996 and `fix-r3/jentry/NOTES.md` at dee9996 were wholly contained in it |

The tools import their siblings by name (`sys.path`), and some read their round's scratch layout (`doors-r1/...`), so a re-run needs them put back in that layout, with `imgkit.py` from `../corridor-door-end-2026-10-12/tools/layers/` beside them. The patch scripts and the junction_room template are not kept: they carried the game code they inserted, which is in `apps/game`.

## Scratch names

The notes, `provenance.txt` and the reviews were written in the scratch run and keep its names; paths that start with `doors-r1/` name the scratch run and are left as written. A tool path in `provenance.txt` or a review names the tool as it was in that session's round (for example round 1's sessions cite `records/tools/rdesign.py`, which is `records/tools/rdesign.py` at dee9996 here); the tool map gives every earlier version:

| Scratch name | Filed as |
|---|---|
| `hatch/` | `junction-exit/` |
| `jentry/` (in `fix-r1/` to `fix-r3/`) | `junction-entry/` |
| `shots/integration-tools/` | `integration/` at dee9996 (removed on October 15; each of its files is cited in the tool map) |
| `shots/fix-rN-tools/`, `fix-rN-tools/` | `fix-rN/` |
| `driver/` in a round | `tools/driver/` (one driver; each round's own at dee9996) |

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
