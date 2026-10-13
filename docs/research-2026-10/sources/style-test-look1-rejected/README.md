# Style test, Look 1 (not chosen), October 10, 2026

One corridor slice (plate, engineer, WOLF, breaker and coolant relay) redone in "Look 1: today's style, cleaned up": the painterly texture of title art B with half the grain, and bright silver stations that stand apart from the room. It was shown beside Look 2 on the style-test page ([`../../notes/review-pages/2026-10-10-style-test.md`](../../notes/review-pages/2026-10-10-style-test.md)).

## Decision

**October 10, 2026:** Nathanial Henniges picked **Look 2 (graphic-painterly)**, and every asset is redone in it with Codex's built-in image tool only (under "Art" in [`../../README.md`](../../README.md)). Look 2 is in [`../style-test-look2/`](../style-test-look2/).

## Files

| File | What it is |
|---|---|
| `notes.md` | Generation, processing and QA record: references, prompt ledger, cleanup and the art bible's checks. |
| `composite-1280.webp` | The Look 1 slice at 1280x720 (our composite of the generated parts, WebP quality 80). |
| `qa/*.json` | The `qa_asset.py` results that `notes.md` cites: engineer, WOLF, breaker, relay (checks A-H) and the 960 composite (site checks). |

The separate parts and the 960 and 1920 composites were not kept.

## Credits

- **Game, characters and the decision:** Nathanial Henniges.
- **Art:** Codex's built-in image tool (generation and edit modes, no API key), with title art B, the approved corridor plates and the October 8 sprites and props as references; the shared style add-on is quoted from the art bible ([`../../art-bible.md`](../../art-bible.md)). Processing and QA: Claude (Claude Code) agents with Python scripts, checked with `qa_asset.py` ([`../../notes/art-audit/bible/`](../../notes/art-audit/bible/)).
- **C2PA:** the delivered parts were re-encoded during processing, so they and the composite carry no C2PA (`notes.md`, "Metadata and workspace"). The generated originals stay in the Codex generated-images store and are not in this repository.
