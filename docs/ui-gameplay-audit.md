# UI and gameplay audit — September 30, 2026

## Scope and ownership
Three agents reviewed all current game scripts and tests, representative rendered UI states, and consulted outside design research. Nathanial Henniges owns the original concept, core story and creative vision. Research informs craft; cited developers are not project contributors or endorsers. This file is ignored private production documentation.

## Coverage
| Surface | Evidence and result |
| --- | --- |
| Title / New Game / Continue | Rendered and source reviewed; clean restart and checkpoint restoration checked |
| In-game credits | Rendered; attribution, tools, provisional art and reviewed references updated |
| Intro / containment / Continue / Skip | Rendered and native-event checks; B-remapped Continue no longer skips |
| Tutorial / context / location slate | Rendered; checkpoint prompt now appears only near the interaction |
| Dialogue and choices | Desktop/controller/touch stills; direct remapped response overrides native focused acceptance |
| Corridor cooperation / refusal / fallback | Deterministic scene routes; actual-route memory preserved and engineer fallback retained |
| Records and closing | Both deterministic routes; settled close rendered and camera framed above dialogue |
| Checkpoint / save / load / restart | State/scene regressions; title recovery reachable from touch/controller pause menu |
| Pause / Return to Title | Rendered; unsaved-progress warning, New Game focus and Continue eligibility checked |
| Display / Audio / Controls | All tabs and scrolled controls reviewed; native input tests; dropdown themed |
| Touch / larger aspect | Rendered examples; not a device acceptance test |
| Launch/loading | Source uses preloaded assets and existing transitions; no timed startup benchmark or separate loading-system acceptance |

## Fixed findings
- Remapped B Continue could invoke intro Skip through menu Back.
- Remapped response could select focused first choice instead of intended second choice.
- Remembered corridor line could claim WOLF cooperated after the engineer used the bypass.
- Checkpoint prompt claimed Records entry outside its interaction range.
- Controller/touch users lacked a menu path to restart or checkpoint recovery.
- Cinematic context chip and response cards obscured actors.
- Settled closing camera placed feet under bottom dialogue.
- Settings dropdown used default gray styling outside the navy/cyan theme.

## Consulted research and application
- Fumito Ueda / The Last Guardian developer interview: companion behavior and visual storytelling. Keep WOLF's purposeful reactions and engineer-only fallback; additional animation remains work.
  https://blog.playstation.com/2016/06/21/the-last-guardian-5-storytelling-secrets/
- Naughty Dog / The Last of Us Part II accessibility overview: remapping, readable presentation, speaker information. Reviewed as craft reference; configurable text size/background is proposed, not shipped.
  https://www.naughtydog.com/blog/the_last_of_us_part_ii_accessibility_features_detailed
- Game Accessibility Guidelines: input-paced consequential text and recognizable interactions. Existing text remains player-paced; location slate timing is separate.
  https://gameaccessibilityguidelines.com/allow-players-to-progress-through-text-prompts-at-their-own-pace/
  https://gameaccessibilityguidelines.com/give-a-clear-indication-that-interactive-elements-are-interactive/

## Actual checks and limits
44 unique normal-renderer stills inspected, including final closing-camera and themed-dropdown recaptures. PR #23 merged as `8077ae8` with three focused commits (`ff2fe03`, `aa6d8d4`, `0f486bb`). Final Godot, docs build and GitGuardian checks passed; CodeRabbit was pending at merge. Post-merge deployment not yet verified. Local main fast-forwarded cleanly. Notion Build Plan updated explicitly; Jira MDW-1584 unchanged.

Godot 4.7.2 state, corridor, chapter, UI/controls and settings tests passed. Native input probes reproduced and verified remapped response fixes. Docs typecheck, Pages build and whitespace check passed. Rendered stills are visual evidence, not hands-on route acceptance. Native UI tooling could not attach to the CLI game process in the previous pass. Physical controller, full manual routes, touch devices, audio playback, exports and startup/performance benchmarks remain unverified. Engine pin and populated asset register unchanged.

## Priorities after this pass
1. Hands-on both complete routes with separate saves, checking input/focus and pacing.
2. Configurable readable dialogue size/background, with layout checks at largest size.
3. Directional WOLF sprites, then other characters; deliberate contact/refusal/withdrawal animations.
4. Sound, device/export checks and measured startup performance.
