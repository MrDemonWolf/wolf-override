Supersedes #52.

**Version bumps** (same as Dependabot's #52):
- fumadocs-core and fumadocs-ui 16.16.1 -> 16.17.1
- fumadocs-mdx 15.4.6 -> 15.4.7
- next 16.3.8 -> 16.4.0
- typescript 5.9.3 -> 7.0.2
- @types/mdx 2.0.13 -> 2.0.14, @types/node 26.6.4 -> 26.6.5

**Fixes so it builds:**
- `apps/docs/tsconfig.json`: removed `baseUrl` (TypeScript 7 dropped it) and made the collections path relative (`./.source/*`). This clears the TS5102 and TS5090 errors that failed #52.
- `apps/docs/mdx-components.tsx`: fumadocs-ui 16.17 dropped `shadow-sm` from code blocks, so the default `pre` now adds it back with a Tailwind class.
- The Fumadocs 16.17 search changes don't affect this site, because search is turned off.

**Dependabot:** both groups (actions and bun) now take only minor and patch updates, so each major version comes as its own pull request.

**Checks (run locally with bun 1.4.2):** frozen install, `docs:check` (tsc 7.0.2), `docs:test` and a clean `docs:build` all pass, with 26/26 pages exported. A deliberate type error fails `next build`, so the type check really runs under TypeScript 7.

**Before and after:** the export has the same 150 files as main, and all 26 pages have the same markup once script and hash differences are removed. 24 headless screenshot pairs (6 pages, 390 and 1440 wide, dark and light) are pixel-identical. Total JS is about 230 KB smaller.
