# Scripts agent instructions (`scripts`)

**What this file is for:** the rules for the repository's check, export and translation scripts. The repository rules in the root [AGENTS.md](../AGENTS.md) apply first; this file does not repeat them.

## What each script is for

| Script | Job |
|---|---|
| `check-game.sh` | Imports the game and runs every headless suite |
| `check-copies.py` | Fails on copied code (6 or more matching lines in two places) |
| `check-docs-export.sh`, `check-docs-links.py` | Guard the built site in `apps/docs/out` |
| `export_changelog.py` | Copies the website changelog into `apps/game/assets/changelog.txt` |
| `export-game.sh`, `get-godot.sh`, `get-export-templates.sh`, `package_test_build.py` | Builds and test packages |
| `godot-helpers.sh` | Shared shell functions; source it instead of copying them |
| `i18n/` | Translation template and catalog tools |
| `parity/` | Before-and-after captures and performance probes for refactors |

## Rules

- Start every script with a header comment: what it does, its usage line and its environment variables.
- Put a shell function used twice in `godot-helpers.sh`.
- Nothing here may open a window. Use `godot --headless`, or `tools/render/render.sh` when pixels are needed.
- A script that CI runs must fail loudly: `set -euo pipefail`, a non-zero exit and a message that says what to do next.
- Keep scratch output in the git-ignored `.work/` folder and delete it when the job ends.
