Automatic macOS and Windows test builds on every push to main and every pull request from this repository, plus fixes to the game checks from the CI audit.

## Test builds
- `apps/game/export_presets.cfg`: **macOS** (universal `.zip`, Godot's built-in ad-hoc signing, notarization off, bundle id `dev.mrdemonwolf.wolfoverride`) and **Windows Desktop** (x86_64, pack embedded, console wrapper, Godot's own resource editing for icon/version info, no Wine). Both are exported with `--export-debug`, so the debug tools are on. Tests, tool/review/capture/trial folders, `art-source`, Markdown and the asset register stay out of the pack; `assets/changelog.txt` and the font licences go in.
- `.github/workflows/builds.yml` (job `export-test-builds`, not a required check): pinned Godot 4.7.2 (SHA-256), export templates verified by SHA-512 with only the four needed files kept and cached (each file re-checked by SHA-256), both exports on `ubuntu-24.04`, then `scripts/package_test_build.py` checks each package (executable bit, ad-hoc signature, embedded pack, required/forbidden pack files) and adds a `licenses/` folder (Godot LICENSE and COPYRIGHT pinned by SHA-256, the two OFL texts, a README). Uploads `wolf-override-{macos,windows}-debug-<sha7>.zip` with `archive: false` and `retention-days: 14`; job summary links both and gives the open steps. `permissions: contents: read`, superseded PR runs cancelled, fork PRs get no builds. An export that "completed with warnings" fails the job.
- `scripts/export-game.sh` / `scripts/get-export-templates.sh` run the same thing locally (isolated Godot home).

## Check fixes (from the audit)
- `scripts/check-game.sh` + `scripts/godot-helpers.sh`: per-suite and per-import time limit (`SUITE_TIMEOUT`, default 240 s) using `timeout`, `gtimeout` or a perl fallback on macOS; a hung suite fails with a clear message. Suites run up to four at a time, each with its own user data folder (`CHECK_JOBS=1` for serial). The first import fails on anything other than the 16 known font errors. A leak re-runs the suite with `--verbose` so the log names the objects. Temp folders are cleaned up.
- `chapter_scene_test.gd`: stops the game's audio players before freeing it and waits frames as well as time before quitting (the flaky 2-object leak on main).
- Concurrency groups on `game.yml` and `docs.yml` (main never cancelled; docs deploys run in push order); Dependabot groups.

## Docs
- Testing page: new **Test builds** section (where to download, unsigned debug builds with debug tools on, macOS and Windows open steps, Smart App Control caveat, 14-day retention, anyone signed in to GitHub can download), updated check and CI descriptions. Get the game and Setup mention the builds. Changelog bullet for October 12 and regenerated `changelog.txt`.

## Checks
- `bun run game:check` (14 suites, 99 s locally, 4 at a time), `docs:check`, `docs:test`, `docs:build` pass locally. The hang watchdog was exercised with `SUITE_TIMEOUT=8`.
- Both exports ran headless locally and packaged cleanly. Neither build has been opened on a Mac or a Windows PC.

## Settings to consider (not changed)
- Default workflow token to read, and stop Actions approving PRs.
- Allow only GitHub-owned actions plus `oven-sh/setup-bun`, and require full-SHA pinning.
- Require approval of workflow runs for all outside contributors.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
