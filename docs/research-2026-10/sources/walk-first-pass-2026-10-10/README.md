# Walking, first pass (October 10, 2026)

The first walking loops for both characters, made on October 10, 2026 with Codex's built-in image tool through the hatch-pet skill's sprite pipeline: engineer idle, walk and jog; WOLF idle, walk and trot, each right-facing with mirrored left-facing copies. They were for judging the motion only and were shown on the review page of October 10 ([`../../notes/review-pages/2026-10-10-review-batch.md`](../../notes/review-pages/2026-10-10-review-batch.md), section 1).

## Decision

The loops jittered (by up to 14 px) and looked choppy, and the WOLF frames were too small and grainy, so the walk was redone two ways the same night: painted frames (A) and jointed rigs (B) ([`../../notes/review-pages/2026-10-10-walk-door-death-picks.md`](../../notes/review-pages/2026-10-10-walk-door-death-picks.md)). On October 11 Nathanial Henniges chose the painted frames: see [`../walk-2026-10-11/`](../walk-2026-10-11/) and [`../walk-final-2026-10-11/`](../walk-final-2026-10-11/). Nothing from this pass is in the game.

## Files

| Path | What it is |
|---|---|
| `qa.md` | Per-row QA: Codex source file id and SHA-256, frame count, canvas, anchor and drift, foot baseline, loop seam, contact frames and the worker's visual check. |
| `prompts/*.md` | The 16 verbatim prompts: one per row plus the retries. |
| `engineer-contact-sheet.webp`, `wolf-contact-sheet.webp` | Every frame of every row (our contact sheets, WebP quality 80). |

The frames, previews and working files were not kept. Paths written as `[session scratch, not kept]/...` pointed into the session scratch folder.

## Credits

- **Game, characters and the decision:** Nathanial Henniges.
- **Frames:** Codex's built-in image tool, from the October 8 sprites ([`../sprites-2026-10-08/`](../sprites-2026-10-08/)) as identity references.
- **Processing:** the hatch-pet skill's scripts (`extract_strip_frames.py`, `inspect_frames.py`, `despill_chroma_edges.py`, `render_animation_previews.py`, the strip mirroring helper) and Python (Pillow), run by Claude (Claude Code) agents.
- **C2PA:** each source sheet carried a C2PA manifest (a `caBX` PNG chunk, as `qa.md` records per row); the extracted frames were re-encoded without it. The source sheets stay in the Codex generated-images store, identified by the file ids and SHA-256 in `qa.md`.
