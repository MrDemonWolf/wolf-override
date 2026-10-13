# Performance and pixelation audit, measured data (October 9 and 10, 2026)

The summary tables behind [`../../data/audit.json`](../../data/audit.json), the audit that found why the engineer and WOLF looked pixelated (track A) and measured the game's GPU, CPU and RAM (track B) before and after the presentation branch that became PR #42. `data/audit.json` holds the findings, the recommendations and the skeptics' review; these files are the numbers it quotes. Raw per-frame logs, capture batches and the throwaway game copies stayed in the session scratch and were not kept.

Builds measured: main at e2cccfe against the branch `codex/game-presentation` at 16610a4 (`perf-main` and `perf-b2` / `branch` in the files). Machine: Apple M1 Pro, 16 GB, macOS 27.0.1, Godot 4.7.2 (GL Compatibility on Metal). Main caveat, recorded in `conditions-pass2.txt`: pass 2 ran with the screen locked and the window never focused, which leaves CPU, RAM and Godot's own counters valid but distorts V-Sync, the frame cap and GPU use. None of this is hands-on play.

## Files

- `summary-pass1.csv`, `summary-pass2-all.csv`: one row per run and game state (title, corridor start, relay, safe point, Records, junction entry, blast, sentry lane): frame-time average and percentiles, FPS, process and physics time, CPU, RSS and macOS footprint, GPU use, Godot static, texture, video and buffer memory, draw calls, objects, primitives and nodes, with the run's window size, FPS cap, V-Sync and focus.
- `startup-pass2.txt`: launch to title first frame, cold and warm, for both builds (including the procedural sound bank's generation time on the branch).
- `conditions-pass2.txt`: builds, Godot version, hardware, OS and the display, lock and focus state during pass 2.
- `static-textures-perf-{main,branch,b2}.csv`: every imported texture with its source and imported size, compression, mipmaps, GPU format and estimated video memory.
- `limiter-control-summary.txt`: an empty-scene control run of the FPS cap and V-Sync settings, to separate the engine's frame limiter from the game's own cost.
- `sprite-measurements.json`: track A's per-shot character measurements (shot, window size, stretch variant, zoom, on-screen height of the engineer and WOLF in px, their ratio, source texture size) behind the pixelation finding.

The game state names and the engineer's file names ("rowan") are as they were on October 10.

## Credits

- Game: Nathanial Henniges.
- Audit, capture drivers and measurements: Claude (Claude Code) agents working for him, using Godot 4.7.2's `Performance` monitors, macOS `ps`, `ioreg` and `footprint`, and Python scripts for the tables.
- No outside sources are relied on in these files; the Godot documentation pages behind the audit's recommendations are cited inside `data/audit.json`.
