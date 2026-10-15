# Repository agent instructions

Read [AGENT.md](AGENT.md) before game, site or README work. It is the shared, public guide for playable quality, credits, asset provenance and honest test claims.

Read `PRIVATE_AGENTS.md`, `PROJECT_CONTEXT.md` and `docs/next-session.md` before story or gameplay changes; design notes and research live under `docs/`. They hold provisional story and design decisions and are tracked in this repository by Nathanial's decision (October 11, 2026), so they are public. Keep spoiler-heavy material out of the website, in-game text and build output. The latest explicit user decision wins.

Inspect Git status and task-relevant source before editing. Work in small, playable steps using the pinned Godot project at `apps/game`; keep the public site at `apps/docs`. WOLF is an independent companion, the engineer is the sole playable character, and essential progress needs an engineer-only fallback. Keep the original game and story credit with Nathanial Henniges.

Never open a Godot or game window on Nathanial's Mac while he works: run tests and checks with `godot --headless`, and make rendered captures with `tools/render/render.sh`, which renders inside a container (see `tools/render/README.md`). Run relevant checks and distinguish headless logic, rendered stills, hands-on play, exports and device tests. Do not claim a game-feel improvement was validated until the affected route was played. Preserve unrelated work and the populated asset register. Fetch connected pages before editing Notion or Jira; they do not sync with Git automatically.

Don't duplicate code. Before you write a script, scene, shader, test helper, style or tool, look for an existing one that does the job and use or extend it. When two places need the same logic, move it into one shared file that both use, and delete the copies in the same change. Jobs that run in parallel name their shared pieces first, so two branches don't each build their own. Research records keep one current copy of each tool and cite earlier versions by path and commit instead of filing a copy for every round. Reviews treat copied code as a defect, and nothing merges with new copies.

Commit in small steps and push your branch to GitHub as you go, so no work exists only on one machine. Land finished work through a pull request; never push to main. Never add Co-Authored-By or other AI attribution lines to commits.

Never search the whole disk or home folder (`find /`, `find ~`, `mdfind` or Spotlight) or open Finder windows to look for files or skills: on Nathanial's Mac that pops up access prompts while he works. Load a skill through your tool's skill loader or from the folder its listing gives, and look for files only inside this repository and your job's own folders.
