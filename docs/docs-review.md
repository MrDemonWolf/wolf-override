# UI/UX Review: WOLF//OVERRIDE public guide

**Reviewed:** September 30, 2026 · **Input:** source, exported HTML, local browser at 1280×720 and 390×844, private Notion Game Hub/Story · **Method:** NN/g heuristic evaluation + guideline review

## Executive summary
- All seven guide pages were read and rendered; the homepage and sitemap were checked in the production export.
- Separated player onboarding, controls/settings and optional puzzle solutions from developer setup. Save and input behavior were checked against current source.
- Fixed a keyboard skip link that scrolled but did not transfer focus. No remaining severity 3–4 guide issue was observed in tested local flows.
- Eight exported public pages passed canonical, single-heading, focus-target and sitemap checks; 218 internal links/anchors passed. Private plot markers were absent from exported text.
- Custom-domain DNS/TLS is a separate active task. Local build readiness does not certify that hostname or a finished game release.

**Findings:** 0 catastrophic · 0 major in reviewed guide flows · 2 minor fixed · 1 cosmetic fixed

## Findings

### Severity 2 — Minor
#### 1. Player guide mixed audiences and revealed solutions immediately — fixed
- **What:** The original start page combined exact puzzle answers, default inputs, long verification history and developer commands. A new player had no compact spoiler-light entry point.
- **Where:** `apps/docs/content/docs/index.mdx`.
- **Guideline:** Help and documentation should focus on the user's task; page content should be easy to scan.
- **Evidence:** [NN/g: usability heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/) and [How Users Read on the Web](https://www.nngroup.com/articles/how-users-read-on-the-web/).
- **Fix:**
  - [x] Add short Start here, separate Controls and settings, and labeled optional walkthrough.
  - [x] Keep detailed verification and setup on Development.
  - [x] Explain checkpoint replacement, defaults, manual fallback, silent audio and missing downloads accurately.

#### 2. Skip link moved scroll but not keyboard focus — fixed
- **What:** Enter on Skip to content changed the fragment to `#nd-page`; `document.activeElement.id` remained empty. The Fumadocs article was not focusable.
- **Where:** root layout, docs title and homepage heading.
- **Guideline:** Keyboard users need an effective way to bypass repeated navigation.
- **Evidence:** [WCAG: Bypass Blocks](https://www.w3.org/WAI/WCAG22/Understanding/bypass-blocks.html).
- **Fix:**
  - [x] Target `main-content`, a heading with `tabIndex=-1` on home and docs.
  - [x] Add a visible focus outline.
  - [x] Verify Enter leaves `document.activeElement.id` as `main-content` with a solid outline.

### Severity 1 — Cosmetic
#### 3. README described obsolete terminal title styling — fixed
- **What:** README still said both title and settings used the terminal theme after the user limited that direction to Settings.
- **Where:** README presentation paragraph.
- **Guideline:** Consistent descriptions help users form accurate expectations.
- **Evidence:** [NN/g: consistency and standards](https://www.nngroup.com/articles/ten-usability-heuristics/).
- **Fix:**
  - [x] State that the theme belongs to Settings and preserve normal game-title presentation.

## Unverified (needs a different input to check)
- Full assistive-technology/screen-reader testing and physical-device touch usability.
- Complete game routes and physical controller behavior; this task changes documentation and website focus, not gameplay.
- Live custom-domain availability/certificate and post-merge deployment: handled by the concurrent domain task and final deployment checks.
- External research links were retained; GNU's official page fetch timed out. License clarification was checked against repository LICENSE, including its object-code section. No link was marked broken solely due to a fetch failure.
- Campaign-specific guide content remains intentionally private/provisional and has not been invented.

## What's working well
- Local browser: 18px body, 28px line height, 28px h1 and 24px h2. All seven guide pages had one h1 and no horizontal page overflow at desktop and 390px mobile widths.
- Measured body-copy contrast from computed colors: light 6.97:1 (`#3d5873` on `#f4f9fd`); dark 10.22:1 (`#b3c5db` on `#091533`). This is not a complete contrast audit of every UI state.
- Desktop theme toggle and mobile drawer navigation/theme switch worked (as of this review; the landing page's own toggle was removed on October 8, 2026 when the landing became dark only, and the game guide keeps its light/dark setting). Walkthrough's local source-image import loaded and has meaningful alt text and a full-size link; no remote image-size fetch is needed.
- Public source status, rights review and creator attribution are explicit. Private handoff is ignored by Git and outside the public MDX collection.

## Quick wins
- [x] Reorganize the guide around player tasks.
- [x] Fix and verify keyboard skip focus.
- [x] Reuse local screenshot with an enlargement link.
- [x] Check every exported internal link/anchor and public/private boundary.

## Release boundary
Guide content and local build checks passed. PR #30 merged as `38b8ab6`, and post-merge Game checks `36733342008` and Pages deployment `36733342242` passed. Public-host requests returned HTTP 403 during final verification. Custom domain/DNS/TLS is owned by the other active chat. Do not call the live website ready until its exact public host is reachable. No new game/device/export tests were run in this docs-only task.
