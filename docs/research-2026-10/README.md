# Research and approved specs, October 2026 (private)

Private working material from the October 8-10, 2026 sessions. This folder is inside the Git-ignored `docs/` directory and must never be committed or copied into public docs, PR text or build output. The latest explicit decision by Nathanial Henniges wins over anything written here.

## Read first

| File | What it is |
|---|---|
| `design-reference-25-games.md` | Fact-checked study of 25 shipped games (586 sources, 220 corrections): companion design, levels and camera, death and saves, inventory and evidence, action and impact, presentation and UI, audio, mobile. The 20 changes it supports and the open questions. |
| `codex-design-review.md` | Codex's second-opinion review of the plans: contradictions found, 10 refinements, risks, cuts, questions. |
| `art-bible.md` | The high-quality art plan: per-family size and density rules, palette sampled from title art B, matting rules, the automatic QA checks (`qa_asset.py` lived in the session scratchpad), the style-test brief, and the batch order. |
| `approved/item-text-2026-10-09.json` | The eight evidence-case items, approved as drafted (key `final`). |
| `approved/death-text-2026-10-10.json` | Death cards, safe-point prompts, case statuses and WOLF's reaction lines, approved as drafted (key `final`). |

## Data behind the decisions (`data/`)

| File | Contents |
|---|---|
| `death-safe-points.json` | "Secure the Evidence" death and safe-point design (key `judged`) and its research. |
| `level-expansion.json` | Wider rooms with height, doorways, WOLF route graph, art pipeline, phases (key `plan`, `rooms`). Note: room widths must be re-sized to 1.5-2 camera views (about 1,070-1,420 world px) per the Codex review. |
| `real-inventory-design.json` | Real-feel systems (footsteps, room tone, weight, breathing, look-at) and the evidence case. |
| `audit.json` | Pixelation root cause, measured GPU/CPU/RAM, level-feel audit. |
| `game-research.json` | Every dossier, fact-check, synthesis and the gap research behind the design reference. |
| `sound-audition.json`, `sound-redo.json` | Measurements of every generated sound; the redone hiss, arc and growl candidates with licences. |
| `action-design.json`, `blowback-spec.md`, `game-finish.json`, `art-bible.json` | Earlier design and review outputs. |

## Decisions recorded (October 8-10, 2026)

- **Gameplay:** Blowback slice (Service Junction); disabling a machine is fine; the relay memory gates WOLF's help, with an engineer-only path always available.
- **Death:** Secure the Evidence. Big hazards kill; steam knocks down; quick nearby retry, with the death card skippable to control in about 1.5 s and a full retry replay of at most about 20 s. Unsecured evidence drops where you died and can be recovered once; a second death loses optional finds for good; key records never drop; a blast death leaves the door blown open.
- **Safe points:** always safe; a short committed hold secures the case, saves and gives a WOLF moment; the first corridor safe point stays required once as the tutorial.
- **WOLF:** never rescues; short capped lines after deaths; refuses rarely and meaningfully; no player request verb yet; off-screen shown by sound plus a small edge marker; notices or pointedly ignores items, never fetches.
- **Case:** evidence plus one tool (the wheel ratchet); no slots or scarcity in this slice.
- **Levels:** wider rooms (1.5-2 camera views) with one walkable height change each, built room by room, grey-boxed and played on a phone before painting; walk-through bulkhead doorways; WOLF's own routes; two environmental purge hints approved.
- **Mobile:** a first-slice target.
- **Feel:** footsteps, room tone, weight, breathing and look-at first; impact effects at full strength only for big moments, with shake and flash switches.
- **Art:** title art B now; doors are a wide steel SHUTTER ACROSS THE CORRIDOR in a heavy portal, face visible at a slight angle, a different space beyond (approved October 11, round 4; rejected: door A's freestanding front frame, an edge-on cutaway slab, a door in an angled end wall; concepts in `sources/doors-shutter-approved/`; past the shutter, October 11: the corridor seal opens into a new machinery room that the strip to its right is repainted as, the junction blast gap shows the real pipe bay until the junction rebuild, and the Records exit and junction exit hatch show the places they lead to); every asset redone in the style test's Look 2 (graphic-painterly) with Codex's built-in image tool only (no API billing); walking uses the painted frame-by-frame cycles for both characters (October 11; rigs rejected), with walk-then-jog movement (walk 80, jog 190 after about half a second of holding).
- **Sound:** recorded CC0 steam set (Joseph Sardin, BigSoundBank, attribution requested), new arc synthesis, recorded CC0 growl through a machine body.
- **Logic audit (October 10, from 327 real screenshots, 24 problems; `data/` and the published page):** the corridor's manual bypass becomes its own MANUAL BYPASS handle with a few seconds of hold-to-crank, coolant hiss and an alarm (asking WOLF is faster; doing it yourself costs time and nerve, never progress); the engineer gets a name card when control starts plus one line on why they trust WOLF, and narration stays in the third person; the core stakes line becomes required on the main path; the slice ends with an END OF SLICE card and a short recap of the player's choices, and Continue on a finished save offers a fresh run. Defaults: WOLF's bait answer names the relay choice openly; the tank is dropped when the sentry stops (a hit = its body overlaps the brackets). Claude drafts the new lines; Nathanial approves them.
- **Death screen (October 11):** look A, Cold Still (freeze and drain to grey on the killing frame, WOLF the only moving thing, quiet card, RETRY at 0.9 s, control at about 1.5 s, no flashes), plus WOLF's cyan eye and light from look B. Spec and mocks: `data/death-screen-design.json`, `sources/death-screen-2026-10-11/`. Walk frames: final approved-and-fixed cycles and death poses in `sources/walk-final-2026-10-11/` (earlier pass in `sources/walk-2026-10-11/`), `data/walk-redo.json`.
- **Process:** Notion and Codex's project memory are updated through Codex after each milestone; finished Codex sessions are archived.
- **Look real, not AI-made (October 11, evening):** the doors, the opening hatch and the rooms read as AI slop; the characters and stations are fine. Every piece goes design first, then paint: exact functional shapes from measurements and real hardware, Codex paints only inside them, a cleanup pass, a reviewer hunting AI tells, and one piece shown in the real game before the rest. Rules: `art-direction/REAL-LOOK.md`. Doors are door-only art with a real transparent opening; what shows through comes from the room's background, and a door in a wall gets a real space behind it. Nothing floats: every machine stands on a real base with a contact shadow or is wall-mounted with brackets and conduit. Static light, haze and shafts are painted in; only changing effects stay live, only the current room is loaded, and each room gets a phone render budget. The shutter door art made so far is on hold until redone this way.
- **Near-future military base (October 11, night):** hardened, utilitarian, run by automated systems, grounded in real installations; an AI-defence film franchise is a mood reference only, never its names, logos or designs. Short equipment and hazard stencils are allowed, typeset (never painted by the image tool) and readable on a phone.
- **PIN codes (October 11, night):** design A plus B's door lamps (`sources/pin-codes-2026-10-11/`): an optional access screen in Records logs the one unchanged hatch override as a case fact; one keypad at the junction exit offers it in one press; a hand-cranked manual release with its own door alarm is the engineer-only route; WOLF only notices. Every door's lamp shows the lockdown by shape. Lines and the real digits wait for Nathanial; the keypad waits for the evidence case.
- **WOLF's containment (October 11, night):** design C, a standby dock in a guarded bay (`sources/cage-design-2026-10-11/`): a floor-anchored robot stand with a charging umbilical, a dock lamp that goes amber, blue, off, telescoping mesh panels, and a guard lock on a lock pilaster that WOLF visibly tears off by pushing it. The opened, empty bay stays in the room after the opening. Until it is built, today's cage stays exactly as it is.
- **Commits (October 11):** no Co-Authored-By line in any commit; these notes are tracked in the public repository by Nathanial's choice.
