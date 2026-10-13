## Summary

Debug tools for testing the slice and for reading exactly what the game is doing, by a person or by an AI looking at captures.

- **Access:** always on in debug builds. In any other build they stay hidden until a code is entered on the title screen: `WOLFDEN` on a keyboard, a D-pad sequence on a controller, or seven taps on the logo. The unlock is saved in the settings file and can be locked again from the menu.
- **F3 overlay**, four pages:
  - performance (fps, frame and process time, memory, nodes, draw calls);
  - live state (room, beat and objective, both characters' positions, WOLF's target and why, the junction machines, the choices made, the save and checkpoint);
  - zones: use ranges, hazard reaches, every collision shape, WOLF's spots and follow distance, camera and door limits;
  - hitboxes and render boxes, with each node's name, draw depth and layer.

  **F5–F7**, a legend tap or **LB/RB/View** switch each layer on and off.
- **F12 bug capture:** a screenshot plus a JSON file with the state and full screen geometry (rects, depth, visibility, text). Capture drivers can call `capture_with_boxes()`.
- **Debug menu** (backquote, L3+R3, or a small DEBUG button beside PAUSE in touch play). It offers:
  - jumps to any point of the slice, with a choice of the earlier decisions;
  - cheats: invincibility, frozen sentry, instant cranks, slow motion, frame stepping;
  - forced knockdowns, with the same flash and shake as in play, and the junction's big moments;
  - save, reload or clear the checkpoint;
  - effect, shake and flash switches.

  It works with keyboard, controller and touch, and holds the game still while open.
- **Cost:** when hidden it neither processes nor draws. The zones page costs about 2.9 ms a frame in the junction lane while it is shown.
- **Docs:** a "Debug tools and cheat codes" section on the Testing page and two changelog bullets; `changelog.txt` regenerated.

## Testing

- `bun run game:check`: all 14 suites pass, including the new `debug_tools_test`, and the second import is clean.
- `bun run docs:check`, `bun run docs:test` and `bun run docs:build` pass, including the 26-page export check.
- Rendered stills from scripted runs at 1280×720 and in a phone-shaped window. macOS capped that window at 1386×780.
- Not played by hand. No real phone, controller or exported build was tested.

## Notes

- `main.gd` gains a small public `debug_*` surface plus four one-line checks inside gameplay functions: knockdown, door-blast range, sentry update and Android Back. The open logic round-3 branch also edits `main.gd`, so main will be merged into it after this lands.
- Things drawn in custom `_draw()` code only report their bounds in editor builds. In exported builds only the sentry's beam declares its own box.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
