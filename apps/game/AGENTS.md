# Game agent instructions (`apps/game`)

**What this file is for:** the rules that apply only to the Godot project. The repository rules in the root [AGENTS.md](../../AGENTS.md) and the quality guide in [AGENT.md](../../AGENT.md) apply first; this file does not repeat them.

## Before you edit

1. Read `PRIVATE_AGENTS.md`, `PROJECT_CONTEXT.md` and `docs/next-session.md` for story or gameplay changes. They are tracked and public; keep spoilers out of game text that plays before its scene.
2. Check `docs/playtest-bugs-2026-11.md` for the bug number (B1 to B36) your change belongs to.
3. Look for an existing script, test helper or style before writing one.

## Where things live

| Need | Home |
|---|---|
| UI sizes, colours, spacing, timing | `ui/ui.tokens.json`, read through `scripts/ui_tokens.gd` (one token file, shared with `mockups/`) |
| Player-facing text | Story lines are marked in `scripts/story_text.gd`; languages and translation go through `scripts/i18n.gd` and the catalogs in `i18n/` |
| Settings and saved preferences | `scripts/game_settings.gd` |
| Test helpers | `tests/support/` (start with `game_suite.gd`) |
| Asset source and rights | `assets/manifest.json` |

## Rules

- Use the pinned Godot version, typed GDScript, built-in nodes and the existing InputMap.
- Ship one bounded playable change at a time.
- The engineer is the only playable character. WOLF acts on his own. Essential progress needs an engineer-only path.
- `scripts/main.gd` is large and edited by several branches at once. Keep edits there small; put new behaviour in its own script.
- A new or changed player-facing string needs the translation template refreshed (`scripts/i18n/extract_pot.sh`).

## Checks

1. Run the suites your change touches with `godot --headless`, then `scripts/check-game.sh` for the full run.
2. Make rendered stills with `tools/render/render.sh` only. Never open a Godot or game window.
3. Say which of these you did: headless logic, rendered stills. Hands-on play, exports and devices are Nathanial's checks; do not claim them.
