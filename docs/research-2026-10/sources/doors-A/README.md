# Door A, the first door redesign (October 10, 2026)

The first door round. Two designs were painted over the game's corridor and junction for the October 10 review batch (`../../notes/review-pages/2026-10-10-review-batch.md`):

- **A:** a bulkhead across the walkway in slight perspective, with a front lip: junction sealed, breaking and blown; corridor seal sealed and open.
- **B:** a shutter.

In both, the open or blown door showed a lit passage beyond instead of the back wall. The review page recommended A because it "reads more clearly as something you walk through", and Nathanial picked it: the asset register records it as "approved for integration by Nathanial Henniges on 2026-10-10 as door design A (a pressure bulkhead across the walkway) from an A/B comparison sheet", and the bulkhead art is in the game (`apps/game/assets/props/*-bulkhead-*.png`) as the placeholder until the new doors land. The Look 2 batch then redrew doors as "design A" (`../look2-hq/`). On October 11 the door was revisited: A's freestanding front frame was rejected, and after rounds 1b to 3 (`../doors-rejected-rounds/`, `../doors-edge-v2-rejected/`) Nathanial approved the round-4 shutter across the corridor (`../doors-shutter-approved/`). See the "Art" decision in [`../../README.md`](../../README.md).

## Files

- `corridor-sealed.png`, `corridor-open.png`, `corridor-front-lip.png`, `junction-sealed.png`, `junction-breaking.png`, `junction-blown.png`, `junction-front-lip.png` (tracked earlier): door A's scenes and front-lip pieces.
- `compare-A-vs-B.webp` (added 2026-10-12): the A-over-B comparison sheet (top row A, bottom row B) the pick was made from, re-encoded from the 2.4 MB PNG at WebP quality 80. Door B's single plates were not kept; this sheet is the record of what B looked like. The processed in-game copies of A are in `apps/game/assets/props/` and the full-size originals in `apps/game/art-source/`, each with its asset-register entry.

## Credits

- Game, story and the door decision: Nathanial Henniges.
- Door A and B art: generated with Codex's built-in image tool by a Codex agent working for Nathanial (provenance of the in-game copies in `apps/game/assets/manifest.json`); comparison sheet composed with a Python script by the same run. The WebP copy carries no metadata.
- No third-party material is used.
