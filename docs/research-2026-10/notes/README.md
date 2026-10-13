# Notes, reviews and process records (October 6-12, 2026)

Records from the October 2026 sessions that were kept in the session scratch folder and moved here on October 12-13 so they survive: audits, reviews, decision pages, measurements, pull request texts and update texts. Each folder has its own README with dates, the decisions it records, the files and the credits. Outside sources are listed in [`SOURCES.md`](SOURCES.md).

Spoilers: some notes describe the slice's story beats. They stay in `docs/` and never move into the website, in-game text or build output. Older notes call the engineer by a provisional name ("Rowan") and "he"; since October 12 the engineer is non-binary and uses they/them. WOLF is he/his. The latest explicit decision by Nathanial Henniges wins over anything written here.

| Folder | What it is | Dates |
|---|---|---|
| [`review-pages/`](review-pages/) | Markdown copies of the eleven review pages Nathanial made his picks on (look picks, art batches, sound check, review batch, style test, Look 2 assets, logic audit, walk/door/death picks, logic fixes and new lines, shutter door round 4), with the look-picks images | Oct 8-11 |
| [`logic/`](logic/) | The logic audit's per-screenshot game-state log (327 shots), the 43 screenshots the audit page cites, and the before and after verification of all 24 problems (22 fixed, 1 open by design, 1 waiting on Nathanial) with the fix screenshots | Oct 10-11 |
| [`art-audit/`](art-audit/) | The measured asset audit behind the art bible (per-asset measurements, the 26 worst problems ranked, readability, fringe and compression, defects, website images) and the art bible's QA tools, including `qa_asset.py` | Oct 10 |
| [`reviews/`](reviews/) | The 125-issue full review and its dimensions, the 2.5D presentation research with its implement-and-verify results, and the Blowback build records (behind PRs #31, #38-#40 and #42) | Oct 6-9 |
| [`perf-audit/`](perf-audit/) | The summary tables behind `../data/audit.json`: GPU, CPU and RAM passes, startup, static textures, frame-limiter control, sprite measurements | Oct 9-10 |
| [`lighter-game-baseline/`](lighter-game-baseline/) | The full performance tables behind `../lighter-game/map-perf.md` (main at 76d3a50), kept outside `lighter-game/` so that batch's live files are not touched | Oct 11 |
| [`ci-builds/`](ci-builds/) | The read-only CI audit, the macOS and Windows test-build research (behind PRs #51 and #53), the run data and the Solo Main Protection branch ruleset | Oct 8, Oct 12 |
| [`pull-requests/`](pull-requests/) | The descriptions of PRs #44, #45, #46, #47 and #51, identical to GitHub | Oct 11-12 |
| [`deps/`](deps/) | The TypeScript 7 dependency update (PR #54, superseding Dependabot's #52) | Oct 12 |
| [`studio-logo/`](studio-logo/) | The re-review of the studio logo screen fix (baffea4, verdict pass), its contact sheet and loading-bar crops | Oct 12 |
| [`notion/`](notion/) | The three update texts sent to the Notion Build Plan and Game Hub pages (page links replaced by page names) | Oct 8, Oct 12 |
| [`SOURCES.md`](SOURCES.md) | Every outside page, talk, paper and video the research downloaded, cited by title and URL, plus where the other source lists live | Oct 6-12 |

## What was left out

The session scratch folder held about 50 GB. Only the records above (about 20 MB, mostly text) were kept. Left out on purpose:

- **Logs, capture batches and copies:** run logs, raw screenshot and frame batches, repository copies and worktrees, temporary homes, virtual environments, build outputs and exports, and scripts that only drove one capture run.
- **Third-party files:** downloaded web pages, wikitext, PDFs, transcripts, fonts and other games' images. They are cited in [`SOURCES.md`](SOURCES.md) instead.
- **Generated originals of art that never shipped or is on hold** (about 280 MB). Their finals, prompts, file ids and SHA-256 values are kept here or in `../sources/`; the originals stay in the Codex generated-images store.
- **Studio logo source files:** company brand files; the game already carries the brand images.

Personal data was scrubbed on the way in: home-folder and scratch paths became repo-relative paths or "[session scratch, not kept]", paths into the Codex store became "[Codex generated-images store]", and Notion links became page names. No email addresses, tokens, keys or cookies were kept. The only address in this folder tree is the certificate authority's, inside the C2PA signatures of the byte-for-byte generated originals in `../sources/`; it is part of the signature and cannot be removed.

## Credits

- **WOLF//OVERRIDE, its story, characters and every decision recorded here:** Nathanial Henniges.
- **Research, audits, reviews, measurements, drafts and these notes:** Claude (Claude Code) and Codex agents working for Nathanial.
- **Generated art referenced here:** Codex's built-in image tool. The C2PA records stay inside the generated PNGs; see each `../sources/` folder's README.
- **Outside sources:** [`SOURCES.md`](SOURCES.md) and the area READMEs.
