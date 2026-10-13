# Walking, painted frames: approved pass (October 10-11, 2026)

Track A of the walk redo: each frame painted by Codex over a grey pose guide with the hip locked in place, for the engineer (idle, walk, jog) and WOLF (idle, walk, trot). It was compared with two jointed rigs on the pick page of October 10 ([`../../notes/review-pages/2026-10-10-walk-door-death-picks.md`](../../notes/review-pages/2026-10-10-walk-door-death-picks.md), section 1).

## Decision

**October 11, 2026, Nathanial Henniges:** walking uses the painted frame-by-frame cycles for both characters (the rigs are rejected, [`../walk-rig-rejected-2026-10-10/`](../walk-rig-rejected-2026-10-10/)), with walk-then-jog movement: walk 80, jog 190 after about half a second of holding. The approved cycles were then repainted and fixed in the final pass, [`../walk-final-2026-10-11/`](../walk-final-2026-10-11/). Summary and the four track reports: [`../../data/walk-redo.json`](../../data/walk-redo.json).

## Files

| Path | What it is |
|---|---|
| `sprites/` | The delivered frames and sheets for every row, and `rows-info.json`. |
| `measurements.json` | Drift, foot slide, contact and playback measurements behind the pick page's table. |
| `tools/` | The Python and shell tools that built the guides, registered, measured and finished the frames. |
| `prompts/*.txt` | The 17 verbatim prompts behind the painted cycles, including the WOLF walk retries (`aE` to `aH2`) and the anchored variants. |

Paths written as `[session scratch, not kept]/...` pointed into the session scratch folder. The raw Codex frames were not kept; their Codex session ids (and SHA-256 where recorded) are in [`../walk-final-2026-10-11/wolf/provenance.txt`](../walk-final-2026-10-11/wolf/provenance.txt) and [`../walk-final-2026-10-11/engineer/provenance-walk2.txt`](../walk-final-2026-10-11/engineer/provenance-walk2.txt).

## Credits

- **Game, characters and the decision:** Nathanial Henniges.
- **Frames:** Codex's built-in image tool (`image_gen`, edit mode over pose guides, no API billing), with the October 8 sprites and the Look 2 character sheets ([`../look2-hq/characters/`](../look2-hq/characters/)) as identity references.
- **Guides, registration, measurements and tools:** Claude (Claude Code) agents, Python 3 and shell.
- **C2PA:** the raw Codex frames carried C2PA manifests; the delivered sprites are derived crops and carry none. The raws stay in the Codex generated-images store.
