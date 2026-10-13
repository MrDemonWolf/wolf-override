## Summary

This is the third pass on the screenshot audit of the slice. Every item was judged from fresh in-game captures.

- **Missed tank drop:** the tank lies on the empty mark for about 0.7 s while it sprays, then winches back up. The sentry stops at its edge instead of driving through it, and **WINCHING UP** only shows once the winch takes it.
- **WOLF drawing the sentry:**
  - he runs to the far end of the lane by the exit hatch and bounds over the sentry on the way;
  - the sentry backs off ahead of him and parks on the mark facing him, with its back to the release;
  - the engineer waits at the rubble line while he dashes past;
  - while the sentry holds on him it shows only its eye, with no beam across the bolt box.
- **After the hit:**
  - WOLF waits in full view by the hatch;
  - on the "stay back" route, the empty arm winches up into its ceiling plate and WOLF bounds over the crushed tank in one arc;
  - Continue from checkpoint C starts him at his spot.
- **Lane knockdown:** when the sentry runs the engineer down out in its lane, the card says so. The body falls past the right post, clear of the release, and the sentry rolls back off it.
- **Lines approved by Nathanial:**
  - the junction entry narration names the **LINE** gauge;
  - WOLF's entry warning and the Continue-A warning are now the same line;
  - the break-off line and its recap row are shorter;
  - the opening's last line says WOLF heads for maintenance.
- **Steam and walk-out:** the vent's steam draws behind the engineer and WOLF. On the walk-out, WOLF leaves through the hatch first and then the engineer follows.
- **Opening:** the opening and WOLF's cage are exactly as on main. A trial maintenance hatch was taken back out and will be redesigned separately.
- **Debug menu (after merging main with #46):** a forced sentry knockdown uses the new lane fall when the engineer is out in the lane.

## Testing

- `bun run game:check`: all 14 suites pass on the branch merged with main, including `debug_tools_test`.
- `bun run docs:check`, `bun run docs:test` and `bun run docs:build` pass, including the 26-page export check. The in-game changelog export matches the public changelog.
- Fresh scripted captures of routes R0–R4, R12 and R13. The opening was compared pixel by pixel with main over the cage's screen rectangle: only drifting dust motes differ.
- Not played by hand. No device or exported-build test.

## Known, left for the junction rebuild

- Chase-card knockdowns (after a miss, or inside the alcove) still drop the head into the release panel.
- The engineer walks behind the crushed tank to reach the bolt.
- WOLF's rubble spot overlaps the spent valve and door frame.
- The sentry is drawn over the **EXIT BOLT** box.
- WOLF stands on the vent grate while he reads the gauge.
- WOLF's bound over the crushed tank is about twice his height, and his hind legs graze the spent release at take-off. Whether it feels right needs hands-on play.
- WOLF is mostly off screen when "I'm out." shows.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
