# Death screen design (October 10-11, 2026)

Three looks for the moment the engineer dies, mocked on the Look 2 corridor and shown to Nathanial on the night of October 10, 2026 ([decision page](../../notes/review-pages/2026-10-10-walk-door-death-picks.md), section 3).

## Decision

**October 11, 2026, Nathanial Henniges:** look A, *Cold Still* (freeze and drain to grey on the killing frame, WOLF the only moving thing, a quiet card, RETRY at 0.9 s, control at about 1.5 s, no flashes), plus WOLF's cyan eye and light from look B (*Last Light*). Look C (*Letterbox*) was not chosen. The written spec is [`../../data/death-screen-design.json`](../../data/death-screen-design.json); the summary is under "Death screen" in [`../../README.md`](../../README.md). The mocks are offline composites, not game renders; nothing here was played.

## Files

| Path | What it is |
|---|---|
| `look-{a,b,c}-{blast-honest,sentry-pressed,coolant-honest-dropped}-1280.png` | The nine mock frames: three looks by three deaths (blast with WOLF trusted, sentry with WOLF pressed, coolant with the dropped-evidence line). |
| `look-{a,b,c}-phone-2340x1080.png`, `look-{a,b,c}-storyboard.png`, `compare-sheet.png` | Phone-size mocks, the first 1.5 seconds of each look, and the side-by-side sheet. |
| `metrics.json` | Measurements of the mocks (generated art placement, browser frames, fonts, frame timings). |
| `art/notes.md` | The generation record for the figure art: every verbatim prompt, the reference images and their roles, and why each attempt was kept or rejected. |
| `art/jobs/common.txt`, `job1.txt`, `job2.txt`, `job3.txt` | The briefs given to Codex for the three jobs: collapse (the engineer down), honest (WOLF beside them, trusted) and pressed (WOLF holding his distance, looking away). |
| `art/originals/exec-a204d2af-bb65-4854-b0f1-b6fdd33c8bef.png` | Selected collapse frame (job 1, attempt 2), byte-for-byte Codex output. |
| `art/originals/honest-attempt-3.png` | Selected honest frame (job 2, attempt 3), byte-for-byte Codex output (Codex file `exec-7859992d-41e2-45ad-b1c2-ce8b3ff6c24b.png`). |
| `art/originals/pressed-attempt-3.png` | Selected pressed frame (job 3, attempt 3), byte-for-byte Codex output (Codex file `exec-bce7fd5b-550c-4bf8-8a25-934dfdcc2372.png`). |

In `art/notes.md`, "art/raw/<file>" names the scratch copy; the three selected files are the ones in `art/originals/`. Paths written as `[session scratch, not kept]/...` pointed into the session scratch folder, which was not kept (layout guides, plate crops and the rejected attempts). Paths starting `docs/` or `apps/` are files in this repository. The prompts call the engineer "Rowan" (a provisional name) and use "his" once for them in job 2; the engineer is non-binary and uses they/them.

SHA-256 of the kept originals:

| File | SHA-256 |
|---|---|
| `exec-a204d2af-bb65-4854-b0f1-b6fdd33c8bef.png` | `b9481065e666e59703614afd9c32ebe235b04203affff7da464eb6b43056471e` |
| `honest-attempt-3.png` | `8b74b8f2c393c0cdb19990d22fcce0f9fa28f0d130a2e215f1962dbc152ee79b` |
| `pressed-attempt-3.png` | `5581369e3e01c9bd5b5a67f27650f2cd628e3fbb4493ee44ddcefc990b0daf7c` |

The rejected attempts and their Codex file ids are listed in `art/notes.md`; their originals stay in the Codex generated-images store and are not in this repository.

## Credits

- **Game, story, characters and the decision:** Nathanial Henniges.
- **Figure art:** Codex's built-in image tool (`image_gen`, edit mode, no API billing), October 11, 2026 (UTC), painting onto the approved Look 2 corridor plate with the Look 2 character sheets ([`../look2-hq/characters/`](../look2-hq/characters/)) and the style test ([`../style-test-look2/`](../style-test-look2/)) as references.
- **C2PA:** each file in `art/originals/` carries its original C2PA manifest in a `caBX` PNG chunk (claim generator ChatGPT / gpt-image, signed by OpenAI; actions created, converted, watermarked). Check with `exiftool -a -G1 <file>` or `c2patool <file>`. The mock frames are composites and carry no C2PA.
- **Mocks, measurements and briefs:** Claude (Claude Code) agents working for Nathanial. The compositing scripts (Python and Node.js) drove one run and were not kept.
- **Typefaces in the mocks:** Roboto (The Roboto Project Authors) and Montserrat (The Montserrat Project Authors), SIL Open Font License 1.1, as credited in `apps/docs/content/docs/credits.mdx`. The font files are not copied here.
- **Design references named in the decision page** (no material copied): Inside (Playdead, 2016) and Limbo (Playdead, 2010), which keep the music going through a death. Sources in [`../../design-reference-25-games.md`](../../design-reference-25-games.md).
