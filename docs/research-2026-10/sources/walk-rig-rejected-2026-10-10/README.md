# Walking, jointed rigs: the rejected option (October 10, 2026)

Track B of the walk redo: cut-out rigs that Godot moves with code instead of painted frames. **B1** is the engineer rig (parts painted by Codex as a parts sheet, then a jointed, procedurally driven rig with two-bone IK, rendered in Godot 4.7.2 at 50 fps); **B2** is a WOLF rig built the same way from a Codex body and a legs-and-tail parts sheet.

## Decision

**October 11, 2026, Nathanial Henniges:** the painted frames (track A) won; the rigs are rejected. They measured smoother (planted feet, foot slide under 0.1 px for the engineer) but read as puppets and drifted from the approved designs: a strict profile with an added backpack, a red wedge flashing between the thighs, a WOLF with short legs, a deep chest and a tail like a ringed hose, and dark outlines the art bible bans. Pick page: [`../../notes/review-pages/2026-10-10-walk-door-death-picks.md`](../../notes/review-pages/2026-10-10-walk-door-death-picks.md); track reports in [`../../data/walk-redo.json`](../../data/walk-redo.json).

## Files

| Path | What it is |
|---|---|
| `prompts/engineer-parts.md`, `engineer-parts-v2.md`, `wolf-parts.md` | The verbatim Codex prompts for the parts sheets. |
| `parts/engineer/{def,rig}.json`, `parts/wolf/{def,rig}.json` | B1's part definitions (cut boxes, pivots) and rig definitions. |
| `b2-rig.json` | B2's WOLF rig: part order, pivots, scale and foot spacing. |
| `godot/*.gd` | The Godot rig scripts: `rig_base.gd` (part loading, bones, two-bone IK), `engineer_rig.gd`, `wolf_rig.gd`, `gait_leg.gd`, and the render and still drivers. |
| `ctx-A.webp`, `ctx-B1.webp`, `ctx-B2.webp` | The painted frames (A) and the two rigs in the corridor, as shown for the pick (our renders, WebP quality 80). |

The parts sheets, rendered frames, videos and working folders were not kept. `godot/render.gd` defaults its output to `/tmp/b1`.

## Credits

- **Game, characters and the decision:** Nathanial Henniges.
- **Parts sheets:** Codex's built-in image tool (`image_gen`, edit mode) from the October 8 sprites ([`../sprites-2026-10-08/`](../sprites-2026-10-08/)).
- **Rigs and renders:** Godot 4.7.2 (GL Compatibility renderer), GDScript written by Claude (Claude Code) agents working for Nathanial.
- **C2PA:** the parts-sheet originals carried C2PA manifests and stay in the Codex generated-images store; nothing kept here is a generated original.
