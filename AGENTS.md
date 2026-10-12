# Repository agent instructions

Read [AGENT.md](AGENT.md) before game, site or README work. It is the shared, public guide for playable quality, credits, asset provenance and honest test claims.

Read `PRIVATE_AGENTS.md`, `PROJECT_CONTEXT.md` and `docs/next-session.md` before story or gameplay changes; design notes and research live under `docs/`. They hold provisional story and design decisions and are tracked in this repository by Nathanial's decision (October 11, 2026), so they are public. Keep spoiler-heavy material out of the website, in-game text and build output. The latest explicit user decision wins.

Inspect Git status and task-relevant source before editing. Work in small, playable steps using the pinned Godot project at `apps/game`; keep the public site at `apps/docs`. WOLF is an independent companion, the engineer is the sole playable character, and essential progress needs an engineer-only fallback. Keep the original game and story credit with Nathanial Henniges.

Never open a Godot or game window on Nathanial's Mac while he works: run tests and checks with `godot --headless`, and make rendered captures with `tools/render/render.sh`, which renders inside a container (see `tools/render/README.md`). Run relevant checks and distinguish headless logic, rendered stills, hands-on play, exports and device tests. Do not claim a game-feel improvement was validated until the affected route was played. Preserve unrelated work and the populated asset register. Fetch connected pages before editing Notion or Jira; they do not sync with Git automatically.
