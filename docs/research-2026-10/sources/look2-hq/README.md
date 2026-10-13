# Look 2 high-quality asset batch (October 10, 2026)

After Nathanial picked Look 2 in the style test, every character, station, pickup, door and the sentry was remade in it on October 10, 2026, from the approved designs, with Codex's built-in image tool. Each family went through the art bible's automatic checks, an independent review and a repair round, and was shown to Nathanial on [`../../notes/review-pages/2026-10-10-look2-assets.md`](../../notes/review-pages/2026-10-10-look2-assets.md).

## Decision

- **October 10, 2026:** the batch follows Nathanial Henniges's pick of Look 2 for every asset, using Codex's built-in image tool only (no API billing).
- **October 11, 2026 (evening), Nathanial:** the doors, the opening hatch and the rooms read as AI slop; "the characters and stations are fine". Every further piece goes design first, then paint ([`../../art-direction/REAL-LOOK.md`](../../art-direction/REAL-LOOK.md)). The design A doors here were replaced by the shutter door approved on October 11, round 4 ([`../doors-shutter-approved/`](../doors-shutter-approved/)).
- The characters here are the identity reference for the walking frames ([`../walk-final-2026-10-11/`](../walk-final-2026-10-11/)) and the death-screen art ([`../death-screen-2026-10-11/`](../death-screen-2026-10-11/)).

## Files

| Path | What it is |
|---|---|
| `characters/`, `props/`, `sentry/`, `doors/` (`*.png`, `notes.md`) | The final transparent PNGs and each family's notes: sizes, QA results, review fixes and the SHA-256 of the Codex originals (tracked earlier). |
| `hq-results.json` | The batch record: for each family the generation result, the independent review (verdict and defects) and the repair result. |
| `characters/review-sheet.webp`, `props/review-sheet-{1-stations,2-junction,3-pickups-lamps}.webp`, `sentry/review-sheet.webp`, `doors/review-sheet.webp` | The review sheets Nathanial saw: each asset on grey and on the style-test corridor, at game size and 2x (our composites, WebP quality 80). |
| `characters/prompts/common-header.md`, `single-header.md` | The shared Codex brief: built-in `image_gen` in edit mode, transparent background, byte-for-byte copies and a log line per image. |
| `characters/prompts/engineer.md`, `wolf.md`, `director.md` | The per-character pose plans and verbatim image prompts. |
| `characters/prompts/*-a1.txt` … `*-a3.txt`, `*.txt` | The prompt sent for each attempt of each pose. |
| `characters/prompts/selection.json` | Which attempt was picked for each pose, and the rim-light setting used in finishing. |
| `props/prompts/<job>.md` | The 22 prop jobs (stations, junction pieces, pickups, lamps and their fix rounds): verbatim prompts, references in order with their roles, the Codex file of every output and why it was kept or rejected. |
| `props/parts.json` | Where the separate parts sit: valve wheel, gauge and needle centres, the tank and its arm, and the status-lamp sockets of each station. |
| `doors/doors.json` | Door kit geometry: canvas, world size, density, baseline row, opening box, near jamb, front-lip cut and lamp boxes. |
| `doors/generation-log.md` | Every door generation: Codex image id and file, SHA-256, size and alpha, and the exact prompt. |

Paths written as `[session scratch, not kept]/...`, `scratchpad/...` or `CHARDIR/...` pointed into the session scratch folder (reference boards, raws and work files, not kept). Paths starting `docs/` or `apps/` are files in this repository. The prompts call the engineer "Rowan" (a provisional name); the engineer is non-binary and uses they/them. The Codex originals of this batch (about 150 MB) are not in the repository; the finals here are processed from them, and the notes and logs keep their ids and SHA-256.

## Credits

- **Game, characters and the decisions:** Nathanial Henniges.
- **Art:** Codex's built-in image tool (`image_gen`, edit mode with transparent output, no API billing). References: the approved October 8-9 sprites, props, junction art and sentry v2, the Look 2 style test ([`../style-test-look2/`](../style-test-look2/)), title art B ([`../title-art-b/`](../title-art-b/)) and the art bible's palette card ([`../../notes/art-audit/bible/palette-card.webp`](../../notes/art-audit/bible/palette-card.webp)).
- **Checks, reviews, finishing and sheets:** Claude (Claude Code) agents working for Nathanial, which also ran the Codex sessions, with the art bible's `qa_asset.py` ([`../../notes/art-audit/bible/`](../../notes/art-audit/bible/)) and Python scripts.
- **C2PA:** the Codex originals carried C2PA manifests and stay in the Codex generated-images store, identified by the ids and SHA-256 in the notes and logs. The finals here were cut, matted and resized, so they carry no C2PA.
