## Summary

Two pieces of work in one branch: the polish pass, and the fixes from a screenshot audit of four full playthroughs (327 captures, 24 problems).

**Polish**
- Title art variant B in the game, on the site hero and on the share card.
- Sharper characters, and a 1280×720 first window, centred.
- WOLF keeps clear of the engineer; cleared rooms' lights settle; lamp flicker is randomised; the sentry's beam is drawn to its real sight with a lock-on beat.
- Junction fixes: name plates, a vent plate, and a painted passage behind the hatch.
- Sound no longer follows the visual-effects switch. Steam, arc and growl are redone: recorded CC0 steam and growls (credited) plus new arc synthesis.

**Logic fixes** (every new line approved by Nathanial)
- Service Junction:
  - A tank hit means the sentry is inside the drawn brackets, which light up when it is.
  - While WOLF baits, the release waits until he has the sentry stopped on the mark.
  - The safe alcove is exactly the tinted floor between two posts.
  - The door blast shows the door blowing, with hazard stripes over the real blast zone.
  - The vent and LINE gauge read honestly.
  - Third-person knockdown cards give the right advice.
- Corridor: the relay has stakes. A COOLANT FAULT tag, and a separate MANUAL BYPASS wheel (eight held turns with coolant hiss and an alarm). The hint follows WOLF's answer.
- Story clarity:
  - A name card for the engineer and a trust line.
  - A required stakes line.
  - Narration is never tagged as the Director.
  - WOLF's baiting answer names the earlier relay choice.
- Flow:
  - "Checkpoint saved." toasts.
  - Continue after the junction works.
  - END OF SLICE card with a recap of the run's choices, and PLAY AGAIN on a finished save.
  - Nobody stands inside a machine; labels fade at the screen edge.
- Merged with main (Tailwind site). The portrait hero and the 1600 px corridor capture are ported to Tailwind.

Known placeholder: the junction's front-facing door stays until the junction is rebuilt around the new shutter door (direction being chosen).

## Test plan

- [x] `bun run game:check` (13 suites)
- [x] `bun run docs:check`, `bun run docs:build` (26 pages, export guard), `bun run docs:test`
- [x] Scripted captures of all four routes after each fix round. 22 of the 24 audit problems are fixed on screen. The stakes line is open by design, and the opening staging is decided and comes next.
- [x] Landing hero captured at 390, 834×1112, 1024×1366 and 1440 after the merge
- [ ] Nobody has played it by hand on desktop, touch or a device; feel and readability are not validated

🤖 Generated with [Claude Code](https://claude.com/claude-code)
