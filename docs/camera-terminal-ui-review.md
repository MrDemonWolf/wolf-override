# UI/UX Review: camera, terminal menus and marketing stills

**Reviewed:** September 30, 2026 · **Input:** Godot 4.7.2 rendered title/settings/corridor stills; local website at desktop and 390×844 mobile · **Method:** NN/g heuristic evaluation and guideline review

## Executive summary

- The title and settings screens now share THE DEN terminal language, with visible section labels and focus treatment.
- A closer scrolling view initially placed the actors behind the dialogue panel. Raising the gameplay camera corrected the rendered overlap.
- The two website stills load at 960×540 source resolution. At 390px width, their embedded labels became too small to read; full-size image links now give visitors a way to inspect them.
- No open severity 3–4 finding was observed in the inspected stills or website viewport. Complete hands-on routes, touch hardware, controller hardware and screen-reader operation remain unverified.

**Findings:** 🟥 0 catastrophic · 🟧 0 major · 🟨 0 open minor · ⬜ 0 cosmetic

## Findings

No open finding after the camera framing and image-enlargement corrections. The mobile image issue was severity 2 before the fix: a 960px gameplay frame rendered at about 358px made baked-in game text too small to read. The image now opens at full resolution through a labeled, keyboard-focusable link. [NN/g's mobile reading research](https://www.nngroup.com/articles/mobile-content/) explains the added reading burden on small screens; this supports offering a detailed view, while the observed small screenshot is local evidence.

## Unverified (needs a different input to check)

- Both complete chapter routes, including the fallback route — stills and headless checks do not establish pacing or feel.
- Real controller, mobile touch and screen-reader interaction — no device or assistive-technology session in this pass.
- The new camera's comfort during continuous movement — scripted rendering and deterministic scene checks are narrower than a player-led session.

## What's working well

- The new gameplay still visibly keeps both actors and the relay stations above the dialogue panel.
- Title actions remain explicit buttons, and the settings screen groups Display, Audio and Controls under a clear terminal heading.
- The marketing stills disclose provisional art and development-build status; no download channel appears live.

## Quick wins

- [ ] Play both complete routes in one normal game window with separate saves; tune camera speed only if motion feels uncomfortable.
- [ ] Check the settings tabs with a controller and touch device before claiming those interactions are validated.
