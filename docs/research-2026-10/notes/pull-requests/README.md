# Pull-request write-ups (October 11 and 12, 2026)

The descriptions of five pull requests, kept as Markdown because they hold the verification summaries: what changed, which checks ran, and what was not verified. Each file was checked on 2026-10-12 against the description on GitHub and is identical to it (including the "Generated with Claude Code" footer each PR carried). GitHub stays the record of the review threads and the diffs.

| File | PR | Title | Merged (US Central) |
|---|---|---|---|
| `pr-44-site-tailwind.md` | #44 | Move the site's styling onto Tailwind | 2026-10-11 |
| `pr-45-logic-fixes.md` | #45 | Polish pass and screenshot-audit logic fixes | 2026-10-11 |
| `pr-46-debug-tools.md` | #46 | Add debug tools: overlay, zones and hitboxes, debug menu and cheats | 2026-10-11 |
| `pr-47-logic-round-3.md` | #47 | Logic round 3: junction staging, lane knockdown and the opening line | 2026-10-11 |
| `pr-51-ci-test-builds.md` | #51 | Add automatic macOS and Windows test builds | 2026-10-12 |

Related notes: the Tailwind move follows Nathanial's October 7 decision that the docs site should mostly use Tailwind; #45 and #47 come from the logic audit in [`../logic/`](../logic/); #51 comes from the CI audit and build research in [`../ci-builds/`](../ci-builds/). The TypeScript 7 dependency PR (#54) is in [`../deps/`](../deps/). Some of these texts describe the slice's story beats, so they stay out of the website and in-game text.

## Credits

- Game, story and the decisions the PRs carry out: Nathanial Henniges; every PR here was opened and merged from his GitHub account.
- Code and descriptions: Claude (Claude Code) and Codex agents working for him.
- No outside sources are cited in these texts beyond the tools they name (Godot, Tailwind CSS, Fumadocs, Next.js, GitHub Actions).
