# What WOLF//OVERRIDE should play like: research, audit and plan (October 2026)

WOLF//OVERRIDE is an original game and story by **Nathanial Henniges** (MrDemonWolf, Inc.). This folder answers his October 12, 2026 request: research what a game like this should and needs to play like, think about it as a person playing it, make it look real with no AI slop (no weird doors, no hovering items), keep all the research and notes, and give credit.

It contains a research-backed list of needs, a merged first-time-player audit of the current slice, an ordered plan of fixes, and a full source list. The research informs craft. It does not replace Nathanial's premise or decisions, and where it disagrees with a recorded decision it asks him rather than deciding ([NEEDS.md, Questions for Nathanial](NEEDS.md#questions-for-nathanial)).

The engineer (default name Rowan Vale) uses they/them; WOLF is he/his.

## Files

| File | What it is |
|---|---|
| [NEEDS.md](NEEDS.md) | **Start here.** 193 needs in 20 areas (92 MUST, 76 SHOULD, 25 COULD). Each has a one-line reason with source ids, a measurable target, the game's current status with evidence (a code line, a frame or a probe), and the fix. Ends with where this disagrees with `design-reference-25-games.md` (28 points), a ledger of that study's gaps, where it supports or pushes back on the recorded decisions, and 19 questions for Nathanial. |
| [AUDIT.md](AUDIT.md) | The three first-time-player reviews merged into 40 findings, ranked by how much each would hurt a first-time player (5 tiers), plus 8 round-2 findings (41-48) from the new captures and probes; what works and should stay; where the reviewers disagreed. |
| [PLAN.md](PLAN.md) | The fixes in order: P0 now (23 steps, including a tester build and the first silent playtest after the Tier-1 fixes), P1 next (17), P2 later (10). Each is a small playable step with how to check it. Ends with a table that maps every MUST need to its step (92 of 92 scheduled). |
| [SOURCES.md](SOURCES.md) | Every source from the twelve topics and the round-2 gap pass (470 ids, 406 entries after merging shared URLs), alphabetical by creator, with title, venue, year, URL, accessed date, verified or UNVERIFIED, what it was used for and which needs cite it. |
| [topics/](topics/) | The eleven fact-checked topic notes from round 1, plus [gap-pass.md](topics/gap-pass.md) (controller, front end, desktop display, speakers, primary sources for weak MUSTs, accessibility depth, localization, licences, choice memory, tablets) and [readable-image.md](topics/readable-image.md) (topic 12: figures against backgrounds, layers, light and contact). |
| [drafts-2026-10-13.md](drafts-2026-10-13.md) | Wording drafts for the October 13 play decisions (Q14, Q2 opening, P0-7, P0-9, P0-15, P0-19/Q5, Q6, P0-11b playtest form). Awaiting Nathanial's approval; nothing in them ships until he approves. |
| [human/](human/) | The three first-time-player reviews (newcomer, genre fan, phone player) and two close-up crops. |
| [playthrough/](playthrough/) | The scripted captures: [README.md](playthrough/README.md) (index of the 60 frames kept here), [CAPTURE-ROUND1.md](playthrough/CAPTURE-ROUND1.md) (round 1: routes D and M) and [CAPTURE-ROUND2.md](playthrough/CAPTURE-ROUND2.md) (round 2: failures, front end, controller, display sizes, press probes, flash and colour-vision measurements). Only the frames the audit cites are kept, as WebP. |

The round-1 capture's 495 frames and 24 contact sheets (about 425 MB), round 2's ~1,340 frames (about 1.1 GB), the per-frame logs, press probes, capture drivers, analysis scripts and `data/topic-results.json` (the structured topic results that SOURCES.md was generated from) stayed in the session scratchpad and are not in the repository. [playthrough/](playthrough/) keeps 60 of the frames the audit cites, converted to WebP. To make the full captures again, export `apps/game` at `baffea4` (or any later commit with the same game code) and run the `tools/render/render.sh` commands in [CAPTURE-ROUND1.md](playthrough/CAPTURE-ROUND1.md) and [CAPTURE-ROUND2.md](playthrough/CAPTURE-ROUND2.md). Frame names in the documents (`D-0048`, `M-0062`, `X-0219`, `F-0030`, `C-0185`, `S-0056`) match those files.

## How it was made

All the work was done by AI agents (Claude Code by Anthropic) in a scripted workflow, on 2026-10-12 and 2026-10-13, for Nathanial Henniges.

1. **Playthrough capture (2026-10-12).** One agent exported `apps/game` at `baffea4` and drove two complete scripted runs of the slice through `tools/render/render.sh` (a Linux container with a virtual screen; no window was opened on Nathanial's Mac), after headless dry runs with an isolated HOME. Desktop route D: 1280 × 720, keyboard actions, 269 frames over 208.3 s of game time. Phone route M: 2400 × 1080, the on-screen touch buttons, 226 frames over 171.9 s.
2. **Research (2026-10-12).** Eleven agents, one per topic: core loop and pacing; controls, feel and camera; teaching and onboarding; puzzles and readability; believable spaces and doors; the companion in play; failure, retry and difficulty; story told through play; playtesting with people; mobile play and performance; sound. Each built on the earlier 25-game study (`docs/research-2026-10/design-reference-25-games.md`) without repeating it. Rules: every claim needs a source the agent actually opened, credited with creator, title, venue and year; primary sources preferred; real measured numbers; short quotes only; anything unopened marked UNVERIFIED; current game values read from code.
3. **Fact-checking (2026-10-12 and 2026-10-13).** Independent checkers re-opened the sources, matched quotes, recomputed numbers and re-read the game's constants. Corrections are logged at the end of each topic note.
4. **First-time-player reviews (2026-10-12, second pass 2026-10-13).** Three agents judged the capture frames as a newcomer, a fan of INSIDE, LIMBO, Little Nightmares and Stray, and a phone player.
5. **Synthesis (2026-10-13).** One agent merged the topic needs, merged the reviews into a ranked audit, confirmed current behaviour in the game code at `da5c14e`, wrote the plan and generated the source list.
6. **Round 2 (2026-10-13).** A critic found 23 gaps in the synthesis (unscheduled MUSTs, the playtest order, no tester build path, no controller, front-end, desktop-display or readable-image coverage, uncaptured failure branches, unflagged conflicts with approved text and decisions, weak sourcing, needs without numbers). One agent closed them: four new rendered captures (routes X, F, C, S; [CAPTURE-ROUND2.md](playthrough/CAPTURE-ROUND2.md)), headless press and choice probes over all routes, a flash measurement, a colour-vision simulation and a figure-ground contrast measurement on the frames, 33 new sources opened and credited ([topics/gap-pass.md](topics/gap-pass.md), [topics/readable-image.md](topics/readable-image.md)), 32 new needs and edits to 36 existing ones, a reordered plan and the new questions Q15-Q19.

## Where round 2 disagrees with the critic

- **G8:** the critic quoted the sentry death card as "The sentry ran %s down in its lane." That is the draft; the approved `final` text is "The sentry caught %s in the lane. It did not slow." It still names the undrawn lane, so Q16 stands. The "2.4 s first death, 0.8 s repeat" delay is in a draft note only, not in the approved entries; Q17 still asks Nathanial to confirm Cold Still.
- **G18:** Keren's "Scroll Back" is cited in FEEL-6 ([CONTROLS-FEEL-1], [CONTROLS-FEEL-2]) and Farnell and Weir in SOUND-14 ([AUDIO-FEEL-17], [AUDIO-FEEL-18]) since round 1; those gaps were filled. The ledger in NEEDS.md now says so.
- **G16:** A11Y-2 is now measured independent of Q13 and comes out **under** WCAG's flash thresholds on this estimate; the stripe slowdown in P0-6 becomes conditional on a longer fuse.
- **G14 (Valve):** the five most-cited commentary quotes could not be checked against the recordings with the tools available; they are labelled "fan transcript, not re-checked" rather than UNVERIFIED, because none failed a check. Team Fortress 2's caption file shows Valve ships commentary text in the game files, so a check against Half-Life 2's own files is possible on a machine with the game installed.

## Limits: read these before acting

- **Nobody has played it by hand.** Everything about the game comes from scripted still frames, headless probes and code. Motion, animation, camera feel, input latency and pacing were not observed. Where a reviewer talks about motion, they mark it as a guess.
- **The "first-time players" are AI agents**, asked to look at the frames as those players would. They are not real people and do not replace the playtests in [NEEDS.md, section 13](NEEDS.md#13-checking-with-real-players-test). Round 2's findings 41-48 were found by the agent from frames and probes, not by the reviewers.
- **Scripted inputs.** Reading waits followed a formula (1.2 s plus 0.05 s per character, at most 7 s), and the failures were planned. Times such as "first control at 40.9 s" depend on that formula.
- **No sound, no device.** The captures used a Dummy audio driver and a software renderer (Mesa llvmpipe) in a container. The press probes watch the game's sound players, not the speakers; rumble was read from Godot's vibration state with no pad attached; flash and contrast numbers come from container frames. Nothing here measures real phone, iPad, controller or Mac hardware, DPI, safe areas, heat, frame pacing or fullscreen.
- **Derived numbers are proposals.** Targets marked "derived" (for example the ~2.5 s starting fuse, the 3-death help threshold, the camera window, the parallax speeds, the 30% energy above 600 Hz) were calculated or proposed, not taken from a shipped game. Every timing target needs validating by hands-on play on desktop and phone.
- **Some sources are secondary or unverified.** Valve's commentaries were read through fan transcriptions; some reports paraphrase a talk or an interview (Eurogamer via GamingBolt, Edge via Kill Screen); 14 source entries could not be opened and are marked UNVERIFIED. Round-2 sources had one check (by the agent that cited them), not an independent second pass.
- **A snapshot.** Status lines describe the game code at `da5c14e` (unchanged at `36788ff`) on 2026-10-13.

## How to use it

1. Read the Tier 1 and Tier 2 findings in [AUDIT.md](AUDIT.md), including round 2's finding 41, to see what a first-time player meets.
2. Answer the 19 questions at the end of [NEEDS.md](NEEDS.md). Nathanial's latest decision wins.
3. Work through [PLAN.md](PLAN.md) in order: P0-1 to P0-5 (small and unblocked), then P0-6 to P0-9 (the Tier-1 faults), then the first silent playtest round (P0-12) on the build path chosen in Q15 (P0-11b), before any P1 art work.
4. When a need is fixed, update its **Now** line in NEEDS.md with the new evidence, and say which kind of check proved it (headless, still, phone or hands-on). Do not mark a feel, pacing or readability need MET from stills or headless tests alone.
5. Agents: never open a Godot or game window on Nathanial's Mac. Use `godot --headless` with an isolated HOME for logic, and `tools/render/render.sh` with a unique `--name` for every rendered capture.
6. When adding a source, add it to the topic note and to SOURCES.md, in the same format.

Keep spoiler-heavy material from these notes out of the public website, in-game text and build output (AGENTS.md).

## Credits

- **WOLF//OVERRIDE**, its original concept, core story, characters (the engineer, WOLF, the Director) and creative direction: **Nathanial Henniges**. Developed by MrDemonWolf, Inc.
- **Research, fact-checking, reviews, captures and this synthesis:** AI agents using Claude Code by Anthropic, directed by and for Nathanial Henniges.
- **Sources:** every developer, writer, researcher, studio and standards body in [SOURCES.md](SOURCES.md). Their work informed craft; they are not project contributors and do not endorse the game. Short quotations are used for commentary and credited; the full works are linked, not copied.
- **Earlier research this builds on:** the 25-game study, the art bible, the REAL-LOOK rules, the approved text files, the measured performance audit and the decision log in `docs/research-2026-10/` and `docs/decisions.md`.
- **Tools:** Godot 4.7.2 (headless runs and the render container); the project's `tools/render/render.sh`, which runs Godot inside Docker (on macOS through Colima) with Xvfb as the virtual screen and Mesa llvmpipe as the software OpenGL renderer; Python with Pillow and NumPy for the contact sheets (`sheets.py`, `beats.py`, `sheet.py`), the flash measurement, the colour-vision simulation and the contrast measurement; fontconfig's `fc-query` for the font glyph check.

Done in the same pull request: a short, spoiler-free "Research and references" section on the site's credits page (`apps/docs/content/docs/credits.mdx`) that names the main creators and links to [SOURCES.md](SOURCES.md). Still proposed for Nathanial's approval, not done: one line in the in-game credits (PLAN P1-17) and the Godot licence notice in the game and on the site (PLAN P0-20).
