# Logic audit and fixes (October 10 and 11, 2026)

On October 10 a Claude agent drove four full playthroughs of the build (origin/main e54c338) at 1280x720 and took 327 screenshots: both relay choices, both mirror routes, every junction beat with and without WOLF, failures, and Continue from every save. Four reviewers (a first-time player, physical logic, story logic and systems logic) judged the screenshots alone and found 24 problems where what the screen shows does not match what the game does or says. On October 11 the fixes were made and every problem was checked again from 454 fresh screenshots of all four routes played to the end (branch head a66d333): 22 fixed, 1 open by design, 1 waiting on Nathanial. A third round (PR #47) finished the last items.

**Decisions, by Nathanial (October 10):** the corridor's manual bypass becomes its own MANUAL BYPASS handle with a hold-to-crank, coolant hiss and an alarm (asking WOLF is faster; doing it yourself costs time and nerve, never progress); the engineer gets a name card when control starts plus one line on why they trust WOLF, and narration stays in the third person; the core stakes line becomes required on the main path; the slice ends with an END OF SLICE card and a recap of the player's choices, and Continue on a finished save offers a fresh run. Defaults: WOLF's bait answer names the relay choice openly; a tank hit means the sentry's body overlaps the brackets. Claude drafted the new lines and Nathanial approved them (`../../approved/`). The full record is under "Logic audit" in [`../../README.md`](../../README.md).

Evidence here is scripted play with logged positions and still screenshots, not hands-on play. No claim about feel was validated by these files.

## Files

- `2026-10-10-logic-audit-shot-log.json`: the game state behind each of the 327 audit screenshots (build, window size, the four routes and what each one chose, and per shot the file name, the on-screen dialogue, hint and Continue text, the engineer's position and every game-state flag). It is the evidence index for [`../../data/logic-audit.json`](../../data/logic-audit.json). Screenshot paths in it point at the session scratch, which was not kept.
- `audit-shots/*.webp`: the 43 screenshots the published audit page cites, named by their shot id (route R1 to R3, shot number, beat), so they can be matched to the log. WebP quality 80 of our own captures.
- `2026-10-11-logic-fix-verification.json`: the before and after status of all 24 problems on a66d333, with each pair's on-screen text and what the after screenshot shows, the final review and new observations. It supersedes an earlier pass that was not kept.
- `fix-shots/fix-NN-{before,after}.webp`: the eight before and after pairs shown on the fixes page; `fix-shots/R1-*.webp` and `fix-shots/grid.webp`: final-route stills (name card, seal open, junction, door down, end card) and the grid from the verification pass. WebP quality 80.
- The pages that presented this work: [`../review-pages/2026-10-10-logic-audit.md`](../review-pages/2026-10-10-logic-audit.md) and [`../review-pages/2026-10-11-logic-fixes-and-new-lines.md`](../review-pages/2026-10-11-logic-fixes-and-new-lines.md). The pull requests: [`../pull-requests/pr-45-logic-fixes.md`](../pull-requests/pr-45-logic-fixes.md) and [`../pull-requests/pr-47-logic-round-3.md`](../pull-requests/pr-47-logic-round-3.md).

The audit and fix pages and the logs call the engineer "Rowan" and use "he"; since October 12 the engineer is non-binary (they/them). These notes contain story spoilers: keep them out of the website, in-game text and build output.

## Credits

- Game, story, characters and the decisions above: Nathanial Henniges.
- Audit, capture drivers, screenshots, reviews, fixes and verification: Claude (Claude Code) agents working for Nathanial, using Godot 4.7.2 (scripted play and captures) and Python scripts for the logs and comparisons.
- No outside sources were used.
