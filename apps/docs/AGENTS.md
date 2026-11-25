# Website agent instructions (`apps/docs`)

**What this file is for:** the rules that apply only to the public site (Next.js, Fumadocs, Tailwind 4, static export to GitHub Pages). The repository rules in the root [AGENTS.md](../../AGENTS.md) apply first; this file does not repeat them.

## Before you edit

1. Read the [docs style guide](content/docs/development/style-guide.mdx) before writing or changing a page.
2. Look for an existing component, helper or token before adding one.

## Where things live

| Need | Home |
|---|---|
| Guide pages | `content/docs/` (`meta.json` sets the sidebar order) |
| Landing page and shared layout | `app/` |
| Shared helpers (SEO, press kit, version, colours) | `lib/` |
| Colours, fonts and spacing | `@theme` tokens in `app/global.css` |
| Changelog | `content/docs/changelog.mdx` (build checks verify the plain-text copy; see the root file) |

## Rules

- Every page starts with one "What this page is for" line.
- One idea per bullet, numbered steps, short sections, plain words.
- One home per fact. Link to it instead of repeating it.
- Keep pages spoiler-free and leave story wording untouched.
- Style with Tailwind tokens and utilities. Do not add bespoke CSS classes.
- Only say what is playable or downloadable today.
- Link a new or moved page from the docs index or its topic page.
- The site is a static export: no server code, no `/_next/image` optimiser, WOFF2 fonts only.

## Checks

Run these from the repository root after a change:

1. `bun run docs:check` (types)
2. `bun run docs:test` (unit checks)
3. `bun run docs:build` (build, then the export and link checks)

A passing build does not prove a page reads well. Look at the changed page at phone and desktop width with a headless browser, and say what you did not look at.
