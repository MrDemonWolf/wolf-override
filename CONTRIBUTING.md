# Contributing to WOLF//OVERRIDE

Thanks for your interest. WOLF//OVERRIDE is an early, source-only game by
Nathanial Henniges, developed by MrDemonWolf, Inc. with AI assistance
under his direction and review. Contributions are welcome when they keep
the game playable, honest about what has been checked, and free of
private story material. [AGENT.md](AGENT.md) is the shared quality guide
for people and coding agents; read it before gameplay, site or README
work.

## Before you start

- Open an [issue](https://github.com/MrDemonWolf/wolf-override/issues)
  for anything larger than a small fix, so the direction can be agreed
  first. Bug reports should include the OS, Godot version, input method
  and steps.
- Keep the creative direction: WOLF is an independent companion, the
  engineer is the sole playable character, and essential progress always
  has an engineer-only fallback.
- Work in small, playable steps. One focused change per branch.

## Set up and run the checks

You need Godot **4.7.2 stable** (`GODOT_BIN` overrides the binary name),
Python 3 (standard library only) and Bun **1.4.2** for the docs site.

```bash
git clone https://github.com/MrDemonWolf/wolf-override.git
cd wolf-override
bun install --frozen-lockfile
```

Run the game checks and the docs checks from the repository root before
opening a pull request:

```bash
bun run game:check   # changelog export check, Godot import, headless suites
bun run docs:check   # MDX and Next types, then TypeScript
bun run docs:test    # docs unit tests
bun run docs:build   # static export plus the export checks
```

`bun run game:check` uses a temporary user data folder, so your own saves
are untouched. The headless suites prove logic, not feel: if your change
affects movement, pacing, readability or WOLF's behaviour, also play the
affected route in a normal game window and say in the pull request what
you played and what remains unplayed. Do not describe a game-feel change
as validated until the route has been played.

The [setup](https://wolfoverride.mrdemonwolf.dev/docs/development/setup/)
and
[testing](https://wolfoverride.mrdemonwolf.dev/docs/development/testing/)
pages describe the commands and their limits in more detail.

## Branches and pull requests

- Branch from `main` and open a pull request against it. `main` is
  protected by a repository ruleset: it cannot be deleted or force-pushed,
  and the `godot` check (Game checks workflow) and the `build` check
  (Deploy Docs workflow) must pass before a change lands.
- Keep the Godot pin, the stable event IDs, the existing asset sources and
  the engineer-only viewpoint intact.
- When a change is visible to players, add a bullet to
  `apps/docs/content/docs/changelog.mdx` under the current date, run
  `python3 scripts/export_changelog.py` and commit the regenerated
  `apps/game/assets/changelog.txt` in the same pull request. Update the
  affected guide pages (first steps, controls, saving, walkthrough) too.
- Write plain, spoiler-free commit messages and pull request text. If you
  used an AI coding tool, say so in the pull request; the credits page
  lists the tools used in the build.

## Licence of contributions

Game code and public documentation are licensed under
[GPL-3.0-or-later](LICENSE). By submitting a contribution you agree that
your code and docs are offered under the same licence. The bundled Roboto
and Montserrat fonts stay under the SIL Open Font License 1.1, and
artwork is tracked separately (see below).

## Assets and provenance

Every image, sound, font or other media file needs an entry in the
[asset register](apps/game/assets/manifest.json) before it is added to the
game or the site. Each entry records at least the fields the register's
`future_entry_fields` note lists: `asset_id`, `path`, `source_or_tool`,
`terms_reference`, `rights_review_status`, `modifications` and
`implementation_status`. Existing entries also keep a `source_reference`
for the prompt, review sheet or download; follow their example.

AI-generated art is accepted only with a rights note: the tool and date,
the references used, confirmation that a person reviewed and approved it,
and the statement that its commercial rights review is open and that it is
not covered by the code and docs GPL. Do not add music, recorded audio or
third-party art without a licence that allows redistribution, and do not
invent credits for people, music or tools that were not involved.

## Private story material

Detailed story drafts, future plot decisions and private planning notes
live outside this repository (`PRIVATE_AGENTS.md`, `PROJECT_CONTEXT.md`,
`docs/next-session.md` and private notes are ignored locally). Never
commit them, quote them in public docs, issues, pull requests or build
output, or copy spoiler-heavy material into agent files. Public copy
describes what is playable today.

## Credit

The original game concept, core story and creative vision belong to
Nathanial Henniges; keep that credit unchanged in the game, the site and
the README. Research references are craft sources, not contributors.
Contributors are listed in the Git history and, for sustained or notable
work, on the
[credits page](https://wolfoverride.mrdemonwolf.dev/docs/credits/).

Security problems go through [SECURITY.md](SECURITY.md), not public
issues.
