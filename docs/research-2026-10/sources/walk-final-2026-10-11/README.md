# Walking and death poses: final pass (October 11, 2026)

The approved painted walk cycles (from [`../walk-2026-10-11/`](../walk-2026-10-11/)) repainted where the pick page asked (the jog torso, two walk faces, WOLF graded back to dark gunmetal, two paw slips), plus the death poses for the death screen: the engineer's collapse, and WOLF lying down, looking away, and an alternative look-away.

## Decision and review

- **October 11, 2026, Nathanial Henniges:** painted frame-by-frame cycles for both characters, walk 80 and jog 190 (under "Art" in [`../../README.md`](../../README.md)); death screen look A with WOLF's eye and light from look B ([`../death-screen-2026-10-11/`](../death-screen-2026-10-11/)).
- `REVIEW.md` is the independent art review (October 11): round 1 found six fixes (old teal colour on WOLF's death frames, sinking boots in two walk frames, a smudged hand, a dark outline on one trot frame, a warm jog frame); round 2 passed all six with no regression. It was headless measurement and looking at sprites, sheets and stills; nothing was played in the game.

## Files

| Path | What it is |
|---|---|
| `engineer/`, `wolf/`, `death-poses/` | Delivered frames and sheets for every row, with `measurements.json`, `rows-info.json` and `provenance.txt` (tracked earlier). |
| `REVIEW.md` | The independent review, rounds 1 and 2. |
| `prompts/engineer/*.txt`, `prompts/wolf/*.txt`, `prompts/death-poses/*.txt` | The verbatim prompts behind the final cycles, the WOLF trot and walk repairs (`common-overpaint.txt` is the shared leg-repaint brief) and the three death poses. |
| `death-poses/jobs/*-prompt-sent.txt` | The exact instructions sent to Codex for each death-pose job (two collapse, two lie-down, one look-away), with the reference images in order. |
| `wolf/provenance-walk3.txt` | Codex session id, SHA-256 and source file for every WOLF repaint in this pass. |
| `engineer/provenance-walk2.txt` | Codex session ids (and one SHA-256) of the engineer raws carried over from the approved pass. |
| `fix-measurements/death-colour.json` | WOLF death-frame colour before and after the regrade (hue, a*, b*, lightness, chroma). |
| `fix-measurements/eng-measure.json` | Engineer walk and jog motion before and after the fixes (torso and head drift, guide and sole slide, contact gaps, seam). |
| `fix-measurements/stills-metrics.json` | The death-screen stills before and after (engineer box, sentry clearance, brightness and WOLF's eye colour). |
| `deliver-records/engineer-loops.json`, `deliver-records/wolf-loops.json` | Frame counts, frame rates, loop lengths and ground speed of the delivered idle, walk and jog/trot loops (walk 80, jog 190 world px/s). |
| `deliver-records/death-pose-stills-metrics.json`, `deliver-records/death-pose-previews.json` | Text contrast of the death-card stills as rendered (cause line, WOLF line, caption) and the list of death-pose preview renders. |

Paths written as `[session scratch, not kept]/...` pointed into the session scratch folder (pose guides, raw frames, previews). The prompts call the engineer "Rowan" (a provisional name); the engineer is non-binary and uses they/them.

## Credits

- **Game, characters and the decisions:** Nathanial Henniges.
- **Frames:** Codex's built-in image tool (`image_gen`, edit mode over pose guides and repaint masks, no API billing), with the October 8 sprites, the Look 2 character sheets ([`../look2-hq/characters/`](../look2-hq/characters/)) and the approved walk frames as references.
- **Guides, fixes, measurements and review:** Claude (Claude Code) agents working for Nathanial, with Python tools (the walk tools are in [`../walk-2026-10-11/tools/`](../walk-2026-10-11/tools/)) and the art bible's `qa_asset.py` ([`../../notes/art-audit/bible/`](../../notes/art-audit/bible/)).
- **C2PA:** every new raw carried a C2PA manifest (JUMBF `c2pa`; actions created, converted, watermarked), checked in `REVIEW.md`. The raws stay in the Codex generated-images store, identified by the session ids and SHA-256 in the provenance files; the delivered sprites are derived crops and carry no C2PA.
