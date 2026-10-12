# UI/UX Review: researched landing-page follow-up

**Reviewed:** September 30, 2026 · **Input:** source, live baseline and local browser preview · **Method:** NN/g heuristic evaluation and official game-site research with three agents

## Executive summary
- Two observed minor issues resolved; no confirmed severity 3–4 issue.
- The page now explains concrete player actions and shows a genuine Godot-rendered source frame with explicit provisional status.
- Selected-platform channels appear first. Native disclosure keeps every other planned channel reachable. Unavailable controls no longer suggest outbound navigation.
- Original concept, story and creative vision remain Nathanial Henniges's; no external art or copy was acquired.

**Findings:** 0 catastrophic · 0 major · 2 minor (fixed) · 0 cosmetic

## Findings
### Severity 2 — Minor
#### 1. Unavailable channels imitated active external links (fixed)
- **What:** six focusable aria-disabled cards used external-link arrows but had no destination or action.
- **Where:** `apps/docs/app/downloads.tsx`, previous channel map.
- **Trigger/impact:** browsing planned channels implied navigation and added six no-op keyboard stops.
- **Evidence:** [NN/g: Button States](https://www.nngroup.com/articles/button-states-communicate-interaction/) — action appearance should communicate its availability.
- **Fix:**
  - [x] Use actual disabled controls; remove external-link arrows.
  - [x] Retain visible Coming soon and supplementary native wrapper tooltip.
  - [x] Provide working guide/changelog links and prioritize the selected platform.

#### 2. Gameplay presentation contained only concept artwork (fixed)
- **What:** hero art was honestly labeled concept art, but the gameplay section had no genuine source-game image.
- **Where:** `apps/docs/app/page.tsx`, gameplay section.
- **Trigger/impact:** visitors could read mechanics without seeing their current presentation.
- **Evidence:** [NN/g: Homepage Design Principles](https://www.nngroup.com/articles/homepage-design-principles/) — homepages should explain the offering and support understanding of it.
- **Fix:**
  - [x] Capture current source in the normal Godot 4.7.2 renderer with isolated settings/save.
  - [x] Add captioned frame, alt text, lazy loading and provenance; preserve concept-art distinction.

## Unverified (needs a different input to check)
- Physical mobile devices, Safari/Firefox and actual screen-reader experience.
- Native tooltip timing; essential status remains visible without tooltips.
- Gameplay feel and full routes: renderer capture is not hands-on acceptance.
- Complete accessibility conformance and performance budgets.

## What's working well
- 390×844 browser preview: primary See the game action begins at y=744.6 and is visible in the viewport. Mobile hero reduced from fixed 850px minimum / 20rem top padding to content sizing / 14rem padding.
- No horizontal overflow at 320px, 390px or 1440px tested layouts. Desktop and mobile dark/light states inspected.
- Keyboard Tab skips disabled channels and reaches summary; Enter opens disclosure. Six channels then visible. Android override and Mac suggestion verified.
- Source image loaded at native 960px width; caption keeps art/UI provisional. Original asset register entries preserved.

## Research sources and application
- [Stray / Annapurna Interactive](https://annapurnainteractive.com/games/stray): concise player premise, clear platform destinations.
- [Planet of Lana / Wishfully](https://www.planetoflana.com/): relationship-focused game imagery; current site promotes Lana II.
- [REPLACED / Thunderful](https://thunderfulgames.com/games/replaced/): game media and factual availability structure.
- Sources inform website presentation, not game authorship; no borrowed assets, wording or endorsement.

## Quick wins
- [x] Replace false-action download affordances.
- [x] Show genuine source-game media.
- [x] Put useful guide/changelog destinations near unavailable downloads.

## Duplicate audit
Separate read-only report: `docs/duplicates-audit.md`. 0 HIGH, 1 MEDIUM, 1 LOW. Repeated scene-test input drivers and repeated website asset prefix are maintenance candidates; neither blocks release. No speculative consolidation performed.
