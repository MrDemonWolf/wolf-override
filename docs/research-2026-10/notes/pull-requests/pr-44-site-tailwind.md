## Summary

Moves the public site's styling onto Tailwind CSS tokens and utilities, as decided on October 7. The site no longer carries bespoke stylesheets: `marketing.css`, `docs-guide.css` and `glass.css` are gone, and every page loads the one shared stylesheet.

- **Dead CSS removed first** (proved with Chrome's rule-usage tracking across all 23 exported pages, both themes, five viewports, hover, focus and the open menus). One of the dead rules was the docs sidebar glass effect, which has not been showing since Fumadocs 16 switched those hooks to ids.
- **Landing page** on Tailwind utilities, with the navigation, brand lockup and download buttons as small components (`landing-navigation.tsx`, `brand-lockup.tsx`, `landing-classes.ts`).
- **Guide** section cards, download buttons and screenshots on Tailwind via `guide-components.tsx` and the MDX components.
- **Last `marketing-*` names dropped.**
- Rebased onto main after #43, keeping the Privacy footer link and Privacy card.

Two intentional visual changes, both in the changelog: at exactly 700 px wide the lower **Get the source build** button now spans the full width like the others, and guide screenshots fill the top of their frame instead of sitting between two empty bands.

## Test plan

- [x] `bun run docs:check`
- [x] `bun run docs:build` (26 exported pages; export guard passes)
- [x] `bun run docs:test`
- [x] `bun run game:check` (changelog export in sync)
- [x] Deterministic headless Chrome captures (software rendering) before and after each step, pixel-compared: unchanged apart from the two fixes above
- [ ] Nobody has checked it by hand in a browser or on a device

🤖 Generated with [Claude Code](https://claude.com/claude-code)
