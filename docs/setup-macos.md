# macOS setup handoff — Revision 4
The user installed Godot through Homebrew. `godot --version` reports `4.7.2.stable.official.ed1daf0bf`, matching the M0 target chosen from the official release archive. The older reference's 4.7.2 statement was not a pre-existing project pin.

Homebrew's `godot` cask currently provides 4.7.2 and links `godot` on PATH. Check `brew info --cask godot` before a future reinstall; do not silently upgrade. Export templates were not installed or verified because M0 import/play needs none.

The Godot project lives at `apps/game/project.godot`, with its corridor scene and typed GDScript under `apps/game`. From the repository root, use:

```sh
godot --headless --path apps/game --import
godot --headless --path apps/game --script res://tests/m0_state_test.gd
godot --headless --path apps/game --script res://tests/m0_scene_test.gd
godot --path apps/game
```

Headless import, M0 state and scene tests passed with Godot 4.7.2 after the engineer-only controls and final WOLF spawn fix. The WOLF//OVERRIDE title screen and opening, engineer movement, WOLF following/backtracking, and the cooperative relay were observed in a partial graphical session before the final spawn fix. The final spawn has headless scene coverage only. Switching was observed in an older build before the solo-protagonist direction superseded it. A full hands-on pass of both current routes and checkpoint save/load, exports and devices still needs testing. The separate `apps/docs` check and Pages static export passed locally; verify the deployed site independently.

Detailed existing setup reference: https://app.notion.com/p/3e6d61481c7b81feae70f4ee53249ad2

Live copy-paste/Codex reference: https://app.notion.com/p/3e6d61481c7b81e2ba0df3d09131d479

The user performed the Homebrew install. This task did not accept licenses, change shell/security/signing settings or install export templates. A first sandboxed import emitted user-directory errors despite exit 0; a permitted rerun wrote Godot's normal Library cache and passed cleanly. The initial state test failed two JSON round-trip assertions; after normalizing the loaded memory sequence it passed. See [exports.md](exports.md) for separate target validation.
