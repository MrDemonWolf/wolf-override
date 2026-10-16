# The corridor door end's additions, October 12-14, 2026

The record of how the end of the maintenance corridor gained its additions: a steel blast frame with bolted jamb plates, a `RESTRICTED AREA` sign, an inner blast door that slides into the wall, two caged red beacons that flash, the engineer's crank pose, a relief valve and discharge pipe on the coolant relay, a shorter ceiling light clear of the PAUSE button, and the safe point room's camera-side wall as a clean cutaway; and how they landed on main with WOLF coming to the doorway. Original game, story and creative direction: **Nathanial Henniges**.

These are working notes, tracked in the public repository by Nathanial's decision. Nothing here goes into the website, in-game text or build output. It follows the door end's first record, `../corridor-door-end-2026-10-12/`, which these additions build on.

## What Nathanial decided

- **2026-10-12:** after approving the rebuilt door end, he chose these follow-ups: a steel blast frame, a `RESTRICTED AREA` sign, an inner blast door, real red beacons, a crank pose for the engineer and a real coolant plume (`../corridor-door-end-2026-10-12/README.md`, "Decisions and dates").
- **2026-10-13:** the roller door is a freight/blast door and keeps its size (about 3 m); the crank frames have to work for any hold length (the bypass hold dropped to about 2 s, with TOGGLE HOLDS).
- **2026-10-14, "Show it as a clean cutaway":** the safe point room's camera-side wall is drawn as an architectural section, one solid dark fill with a clean top, no steel angles or anchors, with the engineer's floor marker drawn above it.
- **2026-10-14, "WOLF comes to the doorway":** when WOLF says "We made it." at the safe point he walks up and stands in the open doorway near the engineer, fully visible, clear of the door frame, the machines and the engineer, facing them. No line changes.
- **2026-10-14, "Land it":** he approved round 11 after seeing its frames.

The project's decision log records the landing under "Corridor door end landed (October 14, 2026)" (`../../../decisions.md`).

## How it was made

The same pipeline as the first door end: **design first** (Python draws every part as an exact shape from real dimensions, in the plate's own camera), **paint** (Codex's built-in image generation tool in edit mode paints material inside those shapes only, with rules against new parts, lettering and greebles, and keeps C2PA metadata), **cleanup** (deterministic Python keeps the paint only as clamped luminance detail inside each part's mask, re-imposes alpha and values, draws bolts, joints and shadows), **install** (packs the atlases), then **two independent reviews** per round (one adversarial "does it look real" review against `../../art-direction/REAL-LOOK.md`, one first-time-player look), on rendered stills from `tools/render/render.sh` only. Nothing was played by hand at any stage, so no review or note here claims how the game feels.

Rounds (each one's full report is in `shots/ADD.md`, newest on top):

| Round | Date | What changed |
|---|---|---|
| 7 | 2026-10-12/13 | Four tracks (door, beacons, crank, plume) built separately and integrated into one game copy. |
| 8 (fix 1) | 2026-10-13 | Blast frame reads as steel, heavier inner leaf, crank cut from the engineer's own sprite with both gloves on the rim, stronger beacons, relief discharge piped down the relay, shorter luminaire clear of PAUSE, WOLF kept off the door end at the safe point. |
| 9 (fix 2) | 2026-10-13 | The plant room closed on the camera side with a 0.36 m cut wall; the luminaire's light moved under it; stronger beacon light; fainter jet. |
| 10 (fix 3) | 2026-10-14 | Nathanial's two decisions: the clean cutaway and WOLF in the doorway; the control marker drawn above the cut; the luminaire's relight cleaned up; a deeper beacon pulse. |
| 11 (fix 4) | 2026-10-14 | The beacon globe dims with its light and the lamps flash like rotating beacons (88 a minute, steady under Reduced Motion); heavy bolted jamb plates on both sides of the doorway. Approved. |

## The landing (2026-10-14)

Ported onto main at c5d1d84 (after #63 to #69) on branch `codex/corridor-additions`, by a three-way merge of each changed file (round 6 as landed by #58 as the base, round 11 and main as the two sides). What changed in the port, beyond the package:

- **Main's code kept:** the knockdown body swap (the crank pose uses main's stored sprite and scale, and main's floor reflection already follows a changed texture, so round 11's `FloorReflection.sync_art()` was not needed), main's TOGGLE HOLDS and 0.25 s bypass ticks (the push frame shows for half a tick, 0.125 s), the fault tag clearing, and main's WOLF spacing rules.
- **WOLF in the doorway** replaces main's stopgap at the safe point (`Main.WOLF_DOORWAY_X` 716, held while the engineer is at least a clear gap past it, `WOLF_DOORWAY_HOLD_X` 800; from the relay's left he sets off only once they are 24 px further on, at the safe point's near edge, `WOLF_DOORWAY_HYSTERESIS`, after the landing verification saw him walk to and fro as the engineer edged about at x 800). While the engineer walks through he still follows no further than the relay's left side (`WOLF_FOLLOW_OPEN_MAX_X`), and if they step back into the doorway he leaves it to them.
- **`wolf_space_test`** now measures the doorway spot against the door end as drawn: his head past where the shut curtain crosses the walk line; none of his painted pixels hidden by the pieces drawn over the actors (near column with its jamb plate, cut section, camera, status lamp); the walk line crossing the cross-wall inside its opening and the inner leaf parked in its pocket behind the walk line; the frame, far jamb plate and the wall-mounted MANUAL BYPASS drawn behind him and standing behind the walk line or above the floor; and inside the camera's view. A negative check with the spot moved to x 740 failed it (the near column hid 412 to 536 of his samples), as it should (`landing/logs/wolf-space-negative-x740.txt`; the passing run is `landing/logs/wolf-space-pass.txt`).
- **Review r5's should-fix, the hidden lettering:** the image tool had painted a faint copy of the hood's `DOOR 4B-07` into the head plate behind the always-opaque hood (atlas x 728-840, y 296-338). `landing/atlasfix/repaint_head12.py` rebuilds the plate's flat paint there from its own light (a masked smooth of the plate) and matched luminance grain, only on the plate's design mask (less every joint, bolt, arris, seal and the parked leaf's edge, and round 11's far jamb plate) and only where the hood is opaque within 2 world px all round; alpha unchanged; 1,633 px changed (repaint mask 1,793 px, `report12.json`); no image tool. Checks (`landing/atlasfix/`):
  - Render.sh stills at 1280x720 of every corridor state and opening frame, round 11 and the repaint, same copy, same driver: 0 pixels of the door end changed in any frame; 19 of 29 frames are byte-identical and the other 10 differ only at the top of the screen, in the ceiling lamps' run-to-run flicker (at most 12 levels, screen x 0-660, y 0-121, far from the hood at screen x 760 and up) (`identity12.json`).
  - High-pass detail (the review's measure: Rec. 709 luma minus its 7x7 mean, box x 735-830, y 300-335): on the plate's own flat paint 2.62 in round 11, 1.45 after (round 6's plain wall there: 1.42). Over the whole box it is 5.82 and 5.51: the box also holds the plate joints, the parked leaf's striped edge and the doorway's edge, which round 6 did not have, so the whole-box figure cannot reach round 6's 2.22 without removing designed parts (`hp12.json`).
  - No letter shapes in 5x stretched and high-pass crops (`corridor-seal-atlas-r11-*-5x.png` against `-r12-*`).
- **The edit-target scripts now blank the hood's lettering** (`hood_blank.py`, called by `door/tools/codex_inputs7.py`, `fix1/door/tools/codex_inputs8.py` and `fix4/door/tools/codex_inputs11.py`), so a later paint round cannot copy it. It is filed once, as `door/tools/hood_blank.py`; the two later scripts import it from their own folder, so a re-run of either needs it copied beside them (the byte-identical copies `fix1/door/tools/hood_blank.py` and `fix4/door/tools/hood_blank.py` are at ada83fa). Only those three targets showed the hood; the others (beacons, relay, luminaire, crank, cut wall) do not. The targets the sessions actually used, with the lettering, are kept as they were in each track's `<track>/codex/<job>/refs/` (`door/codex/paint-door7/refs/`, `fix1/codex/paint-door8/refs/` and `fix4/codex/paint-jamb11/refs/`). The filed scripts therefore differ from what ran in exactly that call.

How the landing was checked, and its stills and performance, are in `landing/LANDING.md`.

## Codex sessions

Codex's built-in image generation tool, edit mode, one session per job, every prompt telling it to keep all metadata including C2PA; every session archived. Full record (output paths, SHA-256, what each derived file used): `provenance.txt` (home and session paths shortened to `~/` and `scratchpad/`).

| Job | Session | Output (SHA-256 starts) | In the game? | Output filed here? |
|---|---|---|---|---|
| `beacons/codex/paint-beacons` | 01a1335e-53be-7ca3-bac0-059cf4b5a18d | `beacons-painted.png` (06c89478) | Yes: fixture, globe and guard material | Yes, with C2PA |
| `plume/codex/paint-relief` | 01a1335a-f620-7b42-ae60-ce8dce78c082 | `relief-valve-painted.png` (23626327) | Yes: the relief valve | Yes, with C2PA |
| `door/codex/paint-door7` | 01a13367-ff5e-7032-9f9a-2a89354a3561 | `door7-painted.png` (1b798261) | Yes, detail only: sign plate, parked leaf edge, rail, leaf elevations | Yes, with C2PA |
| `codex/crank-crank-1a`, `-1b`, `-2a`, `-2b`, `-2c` | 01a1335b-97d0-7c73-…, 01a1335b-97d0-7110-…, 01a13361-7b82-…, 01a13361-7b7d-…, 01a13361-7b84-… | `crank-1a` to `crank-2c` | No: round 7's walk-final-style crank, replaced in round 8 | Prompts only (outputs' SHA-256 in `provenance.txt`) |
| `fix1/codex/paint-door8` | 01a134ac-cb13-7733-b679-7230257e0555 | `door8-painted.png` (e9a239f5) | Yes, detail only: blast frame liner, parked edge, leaf elevations | Yes, with C2PA |
| `fix1/codex/paint-crank8-try1` | 01a134bc-6a3b-74d0-9dc7-49fd2b789c28 | `crank8-painted.png` (310fa5da) | No | Prompt and notes only |
| `fix1/codex/paint-crank8` | 01a134c1-4d7e-72a1-8170-134476ae8325 | `crank8-painted.png` (5c613d4f) | Yes: the crank frames' repair zones | Yes, with C2PA |
| `fix1/codex/paint-relay8` | 01a134c3-505a-7132-88f6-8ea5867103a0 | `relay8-painted.png` (181ab3bb) | Yes: the relief discharge drop | Yes, with C2PA |
| `fix1/codex/paint-lum8` | 01a134c9-e14e-7482-aad9-3642fae31b50 | `lum8-painted.png` (ab294c9f) | Yes: the shorter luminaire | Yes, with C2PA |
| `fix2/codex/empty-run-r9` | 01a135c0-104f-7811-824a-7e690e3e25d3 | none (wrong path, empty prompt) | No | Log only |
| `fix2/codex/paint-cut9` | 01a135c0-8eeb-7d02-a132-b3368f2c5a5a | `cut9-painted.png` (f764301c) | No (the 0.42 m try) | Prompt and notes only |
| `fix2/codex/paint-cut9b` | 01a13619-28b8-7c02-91b4-d474e3924572 | `cut9b-painted.png` (ec14d41e) | No longer: replaced by the flat cutaway in round 10 | Prompt and notes only |
| `fix4/codex/paint-jamb11` | 01a139d9-1863-7681-8bc9-ab42ca7191c0 | `jamb11-painted.png` (b3b66a50); a first image (6b707cb9) not used | Yes, detail only: the two jamb plates | Yes (the used one), with C2PA |

The landing started no Codex session. The image tool painted no lettering that is used: `RESTRICTED AREA`, `SECTOR 4B` and `DOOR 4B-07` are typeset by script in the game's Roboto (SIL OFL 1.1), and the copy it painted behind the hood is now gone.

## What is here

- `shots/`: `ADD.md` (every round's report, newest on top), the ten reviews (`REVIEW-real-r1..r5.md`, `REVIEW-human-r1..r5.md`), the code diffs (`add-code.diff` round 6 to 11, `fix1..4-code.diff`), and round 11's measurements (`perf-table.md`, `perf.json`, `measure11.json`, `pulse.json`, `luminaire-check.json`, `opening-diff.json`, `state-diff-*.json`). The raw captures, pairs, crops and sheet they name stayed in scratch (large render captures are not kept in the repository).
- `door/`, `beacons/`, `plume/`, `crank/`: round 7's four tracks: notes (`NOTES.md`, `beacons/research/SOURCES.md`, `door/research/`), design scripts, specs and masks, Codex jobs, cleanup and install tools.
- `integrate/`: round 7's `manifest.before.json` (the asset register before the integration). Its tools, patches and capture driver were later copies of files kept elsewhere and are at ada83fa (see "One current copy of each tool" below).
- `fix1/` to `fix4/`: rounds 8 to 11 (designs and masks per part, Codex jobs, and the tools that made each round's art). The capture and measuring tools are filed once: round 11's `fix4/tools/` and `fix4/driver-pulse/`, and round 9's `fix2/tools/` crop, side and preview helpers. Earlier rounds' copies are at ada83fa.
- `codex/`: round 7's crank prompts and session ids.
- `provenance.txt`: every Codex session and output, and what each installed file was made from.
- `landing/`: the landing's tools (head-plate repaint and checks, the all-routes capture driver, render and dry-run scripts, the comparison and performance tools), small check crops and `LANDING.md`.

### One current copy of each tool

On 2026-10-15 these records were deduplicated under the "Don't duplicate code" rule in the repository's `AGENTS.md`: each round had filed a copy of the previous round's tools, and some files were filed more than once. One current copy of each tool stays, the one that made the filed evidence; the others were removed and stay in the history at ada83fa, the last commit that has them (`git show ada83fa:docs/research-2026-10/sources/corridor-additions-2026-10-14/<path>`). Kept tools and notes still name the removed copies by their as-run paths (`add7/<path>`); the last column maps those. `landing/tools/records-list.sh` lists the filing as it was before this dedupe.

| Removed (at ada83fa) | Kept copy | As-run name |
|---|---|---|
| `door/integration/blast_leaf.gd`, `door/integration/gdcheck/` | none in the records: it landed, revised, as `apps/game/scripts/blast_leaf.gd` | `add7/door/integration/` |
| `integrate/driver/realslice_capture.gd`, `plume/driver/realslice_capture.gd`, `fix1/driver/realslice_capture.gd`, `fix2/driver/realslice_capture.gd` | `landing/driver/realslice_capture.gd` (round 8's driver plus the landing's routes; it made the landing stills) | `add7/integrate/driver`, `add7/plume/driver`, `add7/fix1/driver` (round 8's; the default driver of `fix4/tools/render_run.sh`), `add7/fix2/driver` |
| `fix3/driver-pulse/pulse_capture.gd` | `fix4/driver-pulse/pulse_capture.gd` (made `shots/pulse.json`) | `add7/fix3/driver-pulse` |
| `integrate/tools/state_diff7.py`, `opening_diff7.py`, `perf_table7.py`, `package7.py`; `fix1/tools/state_diff8.py`, `opening_diff8.py`, `perf_table8.py`, `package8.py`; `fix2/tools/state_diff9.py`, `opening_diff9.py`, `perf_table9.py`, `package9.py`; `fix3/tools/state_diff10.py`, `opening_diff10.py`, `perf_table10.py`, `package10.py` | `fix4/tools/state_diff11.py`, `opening_diff11.py`, `perf_table11.py`, `package11.py` | `add7/<round>/tools/` |
| `fix2/tools/luminaire_check9.py`, `measure9.py`; `fix3/tools/luminaire_check10.py`, `measure10.py`, `pulse10.py`, `run_package10.sh` | `fix4/tools/luminaire_check11.py`, `measure11.py`, `pulse11.py`, `run_package11.sh` | `add7/fix2/tools/`, `add7/fix3/tools/` |
| `render_run.sh`, `capture_all.sh`, `headless_perf.sh` and `tests.sh` in `integrate/tools/`, `fix1/tools/`, `fix2/tools/` and `fix3/tools/` | the same four in `fix4/tools/` | `add7/<round>/tools/` |
| `fix1/tools/crop.py`, `fix1/tools/side.py` | `fix2/tools/crop.py`, `fix2/tools/side.py` (byte for byte) | `add7/fix1/tools/` |
| `door/tools/install7.py`, `fix1/door/tools/install8.py`, `fix2/door/tools/install9.py` | `fix3/door/tools/install10.py` | `add7/door/tools/`, `add7/fix1/door/tools/`, `add7/fix2/door/tools/` |
| `fix2/door/tools/cleanup9.py` | `fix3/door/tools/cleanup10.py` (round 10's flat section replaced round 9's painted cut; `fix2/door/tools/cut9.py` stays, since `fix3/door/tools/cleanup10.py` and `cut10.py` import it) | `add7/fix2/door/tools/cleanup9.py` |
| `fix1/door/tools/hood_blank.py`, `fix4/door/tools/hood_blank.py` | `door/tools/hood_blank.py` (one blob; copy it beside `fix1/door/tools/codex_inputs8.py` or `fix4/door/tools/codex_inputs11.py` to re-run them) | `add7/fix1/door/tools/`, `add7/fix4/door/tools/` |
| `fix2/far/tools/far9.py`, `fix3/far/scan/layer-10a/far10-as-run.py` | `fix3/far/tools/far10.py` (the as-run copy was the same blob) | `add7/fix2/far/tools/far9.py` |
| `beacons/tools/design.py`, `beacons/tools/cleanup.py`, `fix1/beacons/tools/design.py`, `fix1/beacons/tools/cleanup.py` | `fix2/beacons/tools/design.py`, `fix2/beacons/tools/cleanup.py` (round 9's; they made the installed `corridor-beacons.png`) | `add7/beacons/tools/`, `add7/fix1/beacons/tools/` |
| `fix1/codex/run_job.sh`, `fix2/codex/run_job.sh`, `door/codex/run_job7.sh`, `beacons/tools/run_codex.sh`, `plume/tools/run_codex.sh` | `fix4/codex/run_job.sh` | the same paths under `add7/` |
| `integrate/patches/beacons.diff`, `integrate/patches/crank.diff` | `beacons/beacons-code.diff`, `crank/deliver/crank-code.diff` (the same diffs with other path headers) | `add7/integrate/patches/` |
| `plume/patch/plume-code.patch` | `plume/patch/plume.patch` (holds every hunk of it, plus the PNG hunk) | `add7/plume/patch/` |

Different tools that share helper code (the capture drivers, the cleanup and portal generations, the Codex input builders) stay as filed. Moving their helpers into one module would change tools that made filed evidence, so it waits until each can be re-run and shown to give identical outputs.

Paths inside the notes and tools are the session's own: `add7/` is this folder, `real-slice/` and `scratchpad/` were the session's scratch folders (with `game-add/`, the round-11 game copy, and `game-slice/`, round 6), and `~/` is the developer's home. Running a tool again means pointing those paths at working copies; the build used Python 3.14 with NumPy 2.5, SciPy and Pillow 12.3, and Godot 4.7.2.

## Who and what made it

- **Nathanial Henniges:** the game, its story and direction; the brief (look real, no AI slop, nothing floating, no door that makes no sense); every decision above and the approval.
- **Claude Code (Anthropic), as AI assistants under his direction:** the design, cleanup and install scripts, the game code and tests, the reviews, the landing and these notes.
- **Codex (OpenAI), its built-in image generation tool in edit mode:** the paint listed above. No image API, CLI fallback or other image tool was used.
- **Software:** Godot 4.7.2 (game, headless tests, and stills through `tools/render/render.sh` in a container), Python with NumPy, SciPy and Pillow, and the Roboto typeface (The Roboto Project Authors, SIL Open Font License 1.1).

## Sources

The real hardware and standards the additions follow. Each note and review names what it took from each source; the reviews cite them as [S1]-[S22], the art direction as [M1]-[M17] (`../../art-direction/REAL-LOOK.md`, section 8) and the door notes as [D1]-[D3] (`door/NOTES.md`). They informed shapes, sizes, colours and light only; none of them is a contributor, no artwork or text was taken from them, and none endorses WOLF//OVERRIDE.

**Military and government (consulted, mostly downloaded and read):**
- UFGS 08 39 53, *Blast Resistant Doors (Earth Covered Magazines)*, USACE/NAVFAC/AFCEC, 2019 c1: frames and anchors transfer blast loads into the structure; anchor bolts and washers; trolleys and gasket seals for sliding doors. https://www.wbdg.org/FFC/DOD/UFGS/UFGS%2008%2039%2053.pdf
- UFGS 08 39 54, *Blast Resistant Doors* (door notes [D1]). https://legacy.wbdg.org/FFC/DOD/UFGS/UFGS%2008%2039%2054.pdf
- UFC 4-021-02 (2025), electronic security systems: surface-mounted retrofit conduit, door hardware, keypads at 1.2 m [M10]. https://www.wbdg.org/FFC/DOD/UFC/ufc_4_021_02_2025.pdf
- UFGS 13 49 20.00 10, HEMP shielding: welded penetration plates, honeycomb vents [M11]. https://www.wbdg.org/FFC/DOD/UFGS/UFGS%2013%2049%2020.00%2010.pdf
- UFC 3-530-01 (2023 c1), interior and exterior lighting: stem-hung fittings in maintenance bays [M12]. https://www.wbdg.org/FFC/DOD/UFC/ufc_3_530_01_2023_c1.pdf
- UFC 3-580-01 (2024), telecommunications labelling [M13]. https://www.wbdg.org/FFC/DOD/UFC/ufc_3_580_01_2024.pdf
- National Park Service: Titan II ICBM Site 8 National Historic Landmark nomination (3-ton blast doors, interlocks, spring-hung cableways) [M2], https://npgallery.nps.gov/NRHP/GetAsset/NHLS/92001234_text ; Minuteman Missile special resource study [M3], https://npshistory.com/publications/mimi/srs/sites.htm ; Delta-01 [M4], https://www.nps.gov/places/delta-01.htm ; HM-69 security, https://www.nps.gov/places/hm-69-security-down-range.htm ; the Minuteman launcher closure door, https://www.minutemanmissile.com/launcherclosuredoor.html
- MIL-STD-130N with Change 1, identification marking [M5]; FED-STD-595C colour chips (36118 Gunship Gray, 36081, 37875) [M7]; TB 746-93-1, Army vehicle colour and marking [M6].
- OSHA 29 CFR 1910.144 (safety colours) and 1910.145 (accident prevention signs). https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.144 , https://www.osha.gov/laws-regs/regulations/standardnumber/1910/1910.145
- US Army Corps of Engineers sign standards (security signs), https://corpslakes.erdc.dren.mil/employees/sign/security.cfm ; a restricted-area sign wording reference [S5].
- DTIC AD0688173, a blast door study (sliding-door seals, leaf plate) [S3]. https://apps.dtic.mil/sti/pdfs/AD0688173.pdf
- ICD/ICS 705 technical specifications for SCIF construction (perimeter walls true floor to true ceiling) [S17].
- DNFSB weekly report on the Pantex blast door interlock (status lights on blast doors). https://dnfsbstg.dnfsb.gov/sites/default/files/document/3784/wr_20070406_34.pdf

**Industry and product data:**
- Eaton Crouse-Hinds EV LED hazardous-location luminaire (the beacons' proportions), Crouse-Hinds EXSO, Federal Signal 27XL and 151XST, Edwards 116 series, a jelly-jar hazardous-location light [S13], a LiftMaster red/green door light; TORK and Federal Signal rotating beacons at 80-90 flashes a minute [S21] (the flash rhythm).
- Rolling-door operators with hand cranks and chain hoists (Amarr) [S14]; sliding blast doors (International Security Expo exhibitors [S1], [S12]; ARA Manufacture Securaguard [S10]; Hartmann Tresore HET 01 [S11]); radioprotection sliding doors [S4].
- PohlCon galvanised edge-protection angles [S16]; NEC 344.30 conduit support; wall-wash light distributions (US patents 4564888 and 9353922) [S9], [S18].
- Washington WAC 296-104-320 (relief discharge piped down, ending 6 in to 2 ft above the floor) [S8]; AIChE Process Safety Beacon, March 2006 (relief discharge aimed at work areas) [S7]; Apollo, Emerson Kunkle and TLV relief-valve and steam references (`plume/NOTES.md`).
- UK HSE secondary containment [S15].

**Games and drawing conventions:** the cut-away buildings of *This War of Mine* (11 bit studios; [S20], https://80.lv/articles/this-war-of-mine-a-game-about-civilians-in-war) and *Fallout Shelter* (Bethesda), and the architectural section drawing's poché [S19], for the clean cutaway. Mood and convention only; nothing was copied.
