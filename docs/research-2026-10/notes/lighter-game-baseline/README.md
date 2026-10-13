# Lighter-game performance baseline tables (October 11, 2026)

The measured tables behind [`../../lighter-game/map-perf.md`](../../lighter-game/map-perf.md), the "before" figures for the lighter-game pass: main at 76d3a50, measured on October 11, 2026, 16:24 to 16:58 CDT, on an Apple M1 Pro (16 GB) with Godot 4.7.2 (GL Compatibility on Metal), from a throwaway copy of `apps/game` driven through the slice's route by a script. `map-perf.md` explains the method and the headline numbers; these files are the full tables. They are kept here, outside `lighter-game/`, so the lighter-game batch that is still working in that folder is not touched.

The lighter-game rule from Nathanial applies to what these numbers are for: new assets fully replace old ones, duplicated code is merged into components with the same UI, and speed is measured before and after.

## Files

- `tables.md`: per-state frame tables at the shipping default (60 FPS cap plus V-Sync, 1280x720), with V-Sync only, uncapped at 1280x720 and 960x540, and the default at 1920x1080: FPS, frame-time average, p50, p99 and worst, script, physics and render CPU time per frame, process CPU, GPU busy, draw calls, objects and primitives; median of the listed runs.
- `texture_by_file.md`: every texture's GPU memory, size, format and mipmaps, and which room shows it (some, such as `junction-sentry-down.png` at the time, were loaded but never visible).

Raw data (per-frame CSVs, process and GPU samples, export packs) stayed in the session scratch and was not kept. Nothing here was played by hand.

## Credits

- Game and the lighter-game direction: Nathanial Henniges.
- Measurement driver, runs and tables: a Claude (Claude Code) agent working for him, using Godot 4.7.2's `Performance` monitors, macOS `ps` and `footprint`, and Python for the tables.
- No outside sources.
