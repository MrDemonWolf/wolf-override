# Title art A, not chosen (October 9-10, 2026)

`keyart-a.png` is variant A of the redone title key art, generated with Codex's built-in image tool late on October 9, 2026 (C2PA timestamp 2026-10-10 04:40 UTC). Variants A and B both replaced the old title art's furry wolf with the plated robot WOLF of the sprites.

## Decision

Nathanial Henniges chose **title art B** ("Art: title art B now", under "Decisions recorded" in [`../../README.md`](../../README.md)). B is in [`../title-art-b/`](../title-art-b/) and became the palette source of the art bible ([`../../art-bible.md`](../../art-bible.md)). The art audit measured A as the cleaner of the two (noise sigma 0.62 against B's 0.83) but both at 1672x941, still too small for 1080p ([`../../notes/art-audit/`](../../notes/art-audit/), ranking item 25).

## Files

| File | What it is |
|---|---|
| `keyart-a.png` | Variant A, 1672x941, the original Codex output copied byte-for-byte. SHA-256 `24d6a9e03b049ebd0e51430d4cfb4075fc62af72b9294a98d5d19deeeec0ac59`. |

The prompts for both variants (A's initial prompt and corrections) are in [`../title-art-b/generation-prompts.txt`](../title-art-b/generation-prompts.txt) and [`../title-art-b/generation-corrections.txt`](../title-art-b/generation-corrections.txt).

## Credits

- **Game, characters and the decision:** Nathanial Henniges.
- **Image:** Codex's built-in image tool (edit mode), with the previous title key art, the October 8 sprites ([`../sprites-2026-10-08/`](../sprites-2026-10-08/)) and the corridor plates as references.
- **C2PA:** the original manifest is embedded in the PNG's `caBX` chunk (claim generator ChatGPT / gpt-image, signed by OpenAI; actions created, converted, watermarked; 2026-10-10 04:40:20 UTC). Check with `exiftool -a -G1 keyart-a.png` or `c2patool keyart-a.png`.
