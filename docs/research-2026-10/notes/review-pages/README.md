# Review pages (October 8-11, 2026)

Markdown copies of the review pages that were published to Nathanial Henniges as HTML while he made his picks. Scripts and styles were dropped. Images point at kept or tracked files; where an image, video or sound was not kept, its caption stays with "image not kept" (or "video" or "audio"). Each page opens with a short header giving the outcome and ends with its credits.

The pages are kept as written, including the engineer's earlier provisional name ("Rowan") and pronoun. Since October 12 the engineer is non-binary and uses they/them; WOLF is he/his. Spoilers: the pages describe the slice's story beats. They stay in `docs/` and never move into the website, in-game text or build output.

| File | Page | Outcome |
|---|---|---|
| `2026-10-08-look-picks.md` (+ `look-picks/*.webp`, 22 images) | Menus, depth pass, gameplay zoom and layered art, before and after | Shipped in PR #42: the dimensional menu theme, the depth pass, zoom 1.35 and layered room art |
| `2026-10-08-art-batch.md` | Regenerated sprites, the eight station props, the corridor and Records rooms as parallax layers | Approved for integration on October 8 |
| `2026-10-09-junction-art.md` | Service Junction layers, staged mock, station props, the purge sentry | Approved and integrated; for the sentry Nathanial chose "Redo as scanner"; later superseded by the Look 2 redo |
| `2026-10-10-sound-check.md` | Verdicts on all 69 procedural sounds (29 keep, 39 tweak, 1 redo) with the measured reasons and fixes | The hiss, arc and growl redone the same day; Nathanial picked eleven sounds (`../../sources/sound-picks/LICENCES.md`) |
| `2026-10-10-review-batch.md` | First-pass walking loops, doors A and B, the redone hiss, arc and growl candidates with licences, the high-quality art plan | Walking loops redone; door A picked (later replaced by the round-4 shutter); eleven sounds picked; the style test went ahead |
| `2026-10-10-style-test.md` | Look 1 against Look 2 on one corridor slice | Nathanial picked Look 2 (graphic-painterly) |
| `2026-10-10-look2-assets.md` | The Look 2 asset batch: characters, stations, junction pieces, pickups and lamps, doors (design A), sentry | On October 11 the doors, the opening hatch and the rooms were judged AI-looking (REAL-LOOK); "the characters and stations are fine" |
| `2026-10-10-logic-audit.md` | The logic audit: 24 problems from 327 screenshots, worst first, each with what you see, why it makes no sense and the fix | Nathanial's four decisions (manual bypass handle, name card and trust line, required stakes line, end card and recap); fixed in PRs #45 and #47 |
| `2026-10-10-walk-door-death-picks.md` | Painted walk frames against jointed rigs, the edge-on door, death-screen looks A, B and C | Painted frames won (walk 80, jog 190); edge-on door rejected; death look A with B's eye and light |
| `2026-10-11-logic-fixes-and-new-lines.md` | Door round 3, eight before and after pairs of the fixes, the opening, and the 108 new or changed lines | Door round 3 rejected; the opening hatch tried and later removed; the lines approved |
| `2026-10-11-shutter-door-round-4.md` | The wide steel shutter across the corridor | Approved on October 11; put on hold with all door art under REAL-LOOK the same evening |

## Credits

- **Game, story, characters and every decision recorded here:** Nathanial Henniges.
- **Pages, screenshots, measurements and drafts:** Claude (Claude Code) agents working for Nathanial; screenshots are our own captures of the game, re-encoded as WebP (quality 80).
- **Generated art shown on the pages:** Codex's built-in image tool; see each page's credits and the matching `sources/` folder for prompts and C2PA records.
- **Outside sources** named on the pages are listed in [`../SOURCES.md`](../SOURCES.md) and in the area READMEs.
