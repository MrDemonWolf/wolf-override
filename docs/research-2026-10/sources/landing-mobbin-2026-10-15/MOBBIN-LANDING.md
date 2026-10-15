# WOLF//OVERRIDE landing-page design brief

Research-only brief for Nathanial Henniges, owner of WOLF//OVERRIDE (MrDemonWolf, Inc.).  
Date: 2026-10-15

## Executive direction

Keep the current dark, cinematic foundation. The page already has a strong key-art hero, honest build status, clear authorship, responsive imagery, accessible landmarks, a visible focus ring, and a restrained cyan accent. The largest opportunity is not a rebrand: it is to show more of the real game, make the current playable status easier to understand, and give visitors a clearer path from interest to gameplay proof to source-build instructions.

Mobbin was useful for entertainment heroes, title-detail hierarchy, galleries, download matrices, changelogs, community calls to action, FAQs, and footers. It was not strong for game-studio sites specifically, and the mobile-navigation web query returned mostly desktop pages. The recommendations below therefore combine inspected shipped-product patterns with the actual repository, not an invented claim that Mobbin contained 32 game sites.

## What the page has today

### Sections in order

1. Floating header: WOLF//OVERRIDE lockup; Story, Gameplay, Get the build, and Game guide; compact menu at 980 px and below.
2. Cinematic hero: provisional corridor key art, title, premise, two CTAs, development/release-status copy, genre label, and an explicit “not gameplay” disclosure.
3. Story: “Built to obey. Awake to refuse.” with two premise paragraphs and a world link.
4. Gameplay: current-room summary, one real 16:9 corridor capture, three mechanic cards, and a first-steps link.
5. Get the build: source-build explanation, primary source-build link, and four planned platforms, all marked “no release date.”
6. Follow the build: current-scope paragraph plus changelog and developer-setup links.
7. Footer: brand/credits, Explore, Player guide, Project, GitHub source, copyright, and provisional-status disclosure.

### Current headline, copy, CTAs, and imagery

- Hero eyebrow: “Sci-fi horror · In development.”
- H1: “WOLF//OVERRIDE.”
- Hero hook: “WOLF has a will of his own.”
- Hero premise: the engineer explores THE DEN; WOLF may help or refuse; the engineer retains a manual route.
- Hero CTAs: “See gameplay” and “Get the source build.”
- Hero imagery: provisional 16:9 key art with 640, 1024, and 1672 px WebP variants (29 KB, 66 KB, and 137 KB).
- Gameplay imagery: one 1600×900 source-build frame with 480, 960, and 1600 px WebP variants (24 KB, 68 KB, and 139 KB).
- Additional unused landing-ready captures exist for the title screen and Service Junction at 480 and 960 px.

### Type, colour, spacing, and responsive behaviour

- Roboto is body text; Montserrat is headings and labels.
- Existing tokens: ink `#080f1b`, surface `#101e2c`, text `#edf5f7`, muted `#b2c5cd`, line `#385363`, strong line `#5a7896`, accent `#8be3ff`, and panel/navy `#091533`.
- H1 scales from roughly 72–131 px on desktop and 48–72 px on phone. Section headings scale from 41.6–67.2 px. Body is 16 px; labels are 14 px; captions are 12.8 px.
- The content container is capped at 1200 px with 32 px desktop gutters and 16 px phone gutters.
- Major desktop sections use about 96–112 px vertical padding; phone sections use about 72 px.
- At 700 px and below, two-column areas and feature cards stack, hero art becomes a 320 px-tall top crop, hero actions become full width, and footer/navigation grids reduce.
- At 980 px and below, desktop navigation is replaced by a disclosure menu. Controls already target at least 44 px; hero/build actions are 52 px tall.

### Weak spots

- One gameplay frame carries too much proof even though two more real captures already exist.
- The hero, gameplay intro, build section, and progress section repeat “source build/in development” without progressively adding much new information.
- Planned platforms all have the same status, so the current definition list is honest but visually flat and not especially decision-useful.
- “Follow the build” is text-only and does not show dated proof of momentum.
- The current premise section is visually quiet after a strong hero; it needs one image or a stronger editorial rhythm.
- There is no FAQ for the predictable questions: Is this released? What can I play? Which platforms are planned? Is WOLF playable?
- There is no clear community/follow path beyond GitHub. This should only be added if Nathanial approves a real public destination.
- The page has good foundational accessibility, but any gallery, FAQ, or motion added later must preserve it.

## 1. Ten highest-impact changes, ranked

1. **Turn the single gameplay image into a three-frame “Current build” gallery.** Use the corridor, title, and Service Junction captures already in the repo; the large-frame/simple-control pattern is visible in [Rivian’s gallery](https://mobbin.com/sites/sections/ceb97802-b7e4-4c5c-814c-220c0aea8def) and the cinematic grid rhythm in [Siena Film Foundation](https://mobbin.com/sites/sections/1115875b-e6af-4b8f-b002-d5aa10ec282e).
2. **Make the hero CTA hierarchy explicit and honest.** Keep one cyan primary action—recommended: **DRAFT: “See the current build”**—and one quieter **DRAFT: “Run it from source.”** Entertainment title pages consistently put one dominant action immediately after the premise, as in [HBO Max](https://mobbin.com/sites/sections/f291567d-0f1c-4c71-a3cb-b298fc0f694e) and [Google TV on iPhone](https://mobbin.com/screens/a1f44c0d-58fe-456e-a388-cd11b244a7b5).
3. **Add a compact fact row under the hero.** Show only verified facts such as “Single-player,” “In development,” “Runs from source,” and “Windows / macOS / iPhone & iPad / Android planned.” Borrow the compressed title-metadata hierarchy from [Paramount+](https://mobbin.com/screens/775152ea-3d99-4195-9057-c013f8c019cb), not its entertainment branding.
4. **Give the premise section one visual anchor.** Pair the two short premise paragraphs with the title-screen capture or a restrained crop; [VanMoof](https://mobbin.com/sites/sections/797e281b-ffe2-4d8e-adce-5e5515e54b1b) demonstrates how one wide image, one short premise, and one story link can carry a section.
5. **Replace the generic feature-card trio with “how the relationship plays” beats.** Keep the same truths—engineer-only control, WOLF’s independent choice, engineer-only fallback, remembered decisions—but present them as a numbered sequence beside gameplay frames, borrowing the editorial cadence, not the styling, from [Grail](https://mobbin.com/sites/sections/17a1fab5-defb-422a-ab75-d4e8adc00025).
6. **Make platform status scannable.** Use a compact Desktop/Mobile matrix with “Source build now” versus “Planned · no date”; [Craft](https://mobbin.com/sites/sections/a0b7540c-22d4-479f-830b-eede4bd022b2) is the best reference. Do not show store badges until real store pages exist.
7. **Show three dated development updates.** Pull the latest three real changelog entries at build time or maintain a tiny literal array; [Linear](https://mobbin.com/sites/sections/44c38fe6-0c18-4730-a93d-0baf7dbd4f50) shows why date + title + visual makes progress credible.
8. **Add a short FAQ immediately before the final CTA/footer.** Use four to six questions with native `details/summary`; the restrained open-row pattern in [Locomotive](https://mobbin.com/sites/sections/056c0156-ba82-4238-8b86-5e7049a20103) fits the existing dark theme.
9. **Add one real follow/community destination—or omit the section.** If a public Discord or mailing list is approved, explain what visitors get and use one CTA, as [Framer](https://mobbin.com/sites/sections/ace1b79b-7e61-4193-9486-669f8031143a) does. Never add an empty signup form or vague social icons.
10. **End with a smaller, action-led footer close.** Keep the excellent authorship/legal links, but add one final, honest action above the columns and reduce repeated navigation. [Current](https://mobbin.com/sites/sections/33353d30-cc34-4205-949a-a72e0cde3d6d) demonstrates the action-then-legal rhythm.

## 2. Recommended page structure

### Desktop

1. Header: lockup; Story, Current build, Get the build, Updates; Game guide as the quiet utility link.
2. Hero: key art, genre/status eyebrow, H1, one-line hook, two-sentence premise, one primary CTA, one secondary CTA, four verified facts.
3. Premise: editorial two-column layout with title-screen capture and spoiler-safe story copy.
4. Current build gallery: three real 16:9 captures, labeled by room/screen and capture date/status.
5. How it plays: three relationship/gameplay beats, arranged as one lead beat plus two supporting beats.
6. Get the build: source-build explanation and compact platform/status matrix.
7. Development updates: three dated changelog teasers plus “All updates.”
8. FAQ: four to six release/play/platform/character questions.
9. Community/follow CTA: only if a real destination is approved.
10. Footer: credits, docs, legal, GitHub, status line.

### Phone at 390 px

1. 64–72 px header row with lockup and a 44×44 px menu button.
2. 220–260 px art crop, followed by title/copy in normal document flow.
3. One full-width primary button and one full-width secondary button; 12 px gap.
4. Two-by-two fact grid; each fact at least 44 px tall.
5. Premise text first, then 16:9 image.
6. Horizontal snap gallery with one 342–358 px-wide card visible and the next card peeking by 16–24 px; include text pagination (“1 of 3”) and buttons.
7. Relationship beats stacked.
8. Platform matrix as four full-width rows; never squeeze two columns.
9. Updates as a vertical list.
10. FAQ rows, optional community CTA, then two-column footer links.

## 3. Section-by-section specification

### Header and navigation

**Layout and content**

- Preserve the floating panel and brand lockup.
- Desktop: four section links plus Game guide; keep the build action in the hero, not as a second bright nav button.
- Phone: menu button stays at the top-right. The open menu should be a full-width panel below the header with one link per row.

**CTA labels**

- Story
- Current build
- Get the build
- Updates
- Game guide

**Type, spacing, colour**

- Links: 15–16 px, semibold, minimum 44 px height.
- Header padding: 12–16 px vertical; 16–28 px horizontal.
- Use `bg-panel/94`, `border-accent/24`, `text-text`, and existing accent hover/focus treatment.

**Tailwind 4**

- Reuse `landingWidth`, `navLink`, `rounded-control`, `border-line-strong`, `bg-panel/94`, `backdrop-blur-sm`, `menu:hidden`, and existing `phone:` / `tablet:` variants.
- Use a real `button` with `aria-expanded` and `aria-controls`; preserve the existing client component.

### Hero

**Layout and imagery**

- Keep the key art and right-side desktop copy placement.
- Reduce copy to one hook plus no more than two short sentences.
- Add the fact row beneath actions rather than two separate label rows at the bottom.
- On phone, keep artwork above the copy with a deliberate gradient fade, similar in hierarchy to [HBO Max’s title detail](https://mobbin.com/screens/af95ae3e-1f3b-484b-acd0-7d67bf6a560f).

**DRAFT copy for Nathanial’s approval**

- Eyebrow: **DRAFT: “Side-view sci-fi horror · In development”**
- Hook: **DRAFT: “WOLF was built to obey. He chose not to.”**
- Premise: **DRAFT: “Explore THE DEN as the engineer beside an independent robot-wolf companion. When WOLF refuses, find the manual way forward.”**
- Primary CTA: **DRAFT: “See the current build”**
- Secondary CTA: **DRAFT: “Run it from source”**
- Status: **DRAFT: “Playable from source · No packaged release yet”**

The current public text remains the authority until Nathanial approves any draft.

**Type, spacing, colour**

- H1: keep `clamp(4.5rem,8.8vw,8.2rem)` desktop; 48–64 px phone is enough.
- Hook: 24–32 px desktop; 20–22 px phone.
- Body: 18–19 px desktop, 16–17 px phone, max 38–42ch.
- CTA height: 52 px desktop, 52–56 px phone.
- Fact row: 14 px labels, 16 px values, 16–20 px gaps.
- Cyan is only the slash, primary CTA, eyebrow, and focus state. Avoid cyan borders on every item.

**Tailwind 4**

- Reuse `text-accent`, `bg-accent`, `text-ink`, `bg-surface`, `border-line-strong`, `text-lead`, and `motion-reduce:transition-none`.
- Implement facts with `grid grid-cols-4 gap-px phone:grid-cols-2`; each item can use `border-t border-line py-3`. No new CSS.

### Premise

**Layout and imagery**

- Desktop: 5/7 grid—title/copy on the left, title-screen capture on the right.
- Phone: heading, copy, image, story link.
- Keep spoilers out; no Director plan detail beyond what is already public unless Nathanial explicitly approves it.

**DRAFT labels**

- Eyebrow: **DRAFT: “Inside THE DEN”**
- Heading: keep “Built to obey. Awake to refuse.”
- Link: **DRAFT: “Meet the world”**

**Type, spacing, colour**

- Section heading: existing `text-section`.
- Body: 16–18 px, 1.7–1.8 line height, 52–60ch maximum.
- Desktop padding: 96 px; phone: 64–72 px.
- Use `bg-ink`; let the image and one accent phrase supply contrast.

**Tailwind 4**

- `grid grid-cols-[minmax(0,5fr)_minmax(0,7fr)] gap-16 phone:grid-cols-1 phone:gap-8`
- Image: `aspect-video w-full rounded-card border border-line-strong object-cover shadow-scene`.

### Current build gallery

**Layout and content**

- Use only the existing title-screen, corridor-start, and Service Junction captures.
- Label each with screen/room, capture date if known, and “Source build · provisional art/UI.”
- Desktop: one 2fr lead image and two stacked 1fr images, or a horizontal snap rail. Prefer the static 2+1 grid because it needs no client state.
- Phone: horizontal scroll-snap with previous/next controls that scroll the container; if controls would require disproportionate code, use a vertical stack. Do not add a dependency.

**CTA labels**

- **DRAFT: “Open full-size image”**
- **DRAFT: “How to run the build”**

**Type, spacing, colour**

- Heading: `text-section`; captions 13–14 px.
- Card gaps: 16 px phone, 24 px desktop.
- Image ratio: 16:9; never crop gameplay UI text out of frame.
- `bg-surface`, `border-line-strong`, `text-muted`; accent only on the active index or link.

**Tailwind 4**

- Desktop static grid: `grid grid-cols-2 gap-6`, lead figure `row-span-2`.
- Phone rail option: `flex snap-x snap-mandatory gap-4 overflow-x-auto pb-3`; cards `w-[calc(100vw-3rem)] shrink-0 snap-center`.
- Keep native links to full-size images and descriptive alt text.

### How it plays

**Layout and content**

- Present three numbered beats:
  1. The engineer is the only playable character.
  2. WOLF moves and decides independently; he may refuse.
  3. Essential progress always has an engineer-only manual route; choices can be remembered.
- Do not imply character switching or direct control of WOLF.

**DRAFT heading and CTA**

- Heading: **DRAFT: “Two minds. One way forward.”**
- Link: **DRAFT: “Learn the controls”**

**Type, spacing, colour**

- Numbers/eyebrows: 14 px tracked Montserrat.
- Beat headings: 22–28 px.
- Copy: 16 px, 1.7 line height.
- Use one accent number per beat, not glowing borders.

**Tailwind 4**

- `grid grid-cols-3 gap-6 phone:grid-cols-1`
- Cards: existing `card`, `p-6`, `min-h-full`.
- If paired with small stills, use `aspect-video object-cover` and reuse existing captures rather than generating art.

### Get the build

**Layout and content**

- Left: honest explanation and source-build CTA.
- Right: status matrix:
  - Windows — planned packaged release; source build can be run now if supported by the setup guide.
  - macOS — same.
  - iPhone/iPad — planned; no release date.
  - Android — planned; no release date.
- Nathanial must approve any claim that a particular OS can currently run from source; the existing public text only guarantees a Godot source build generally.

**DRAFT CTA labels**

- Primary: **DRAFT: “Run the source build”**
- Secondary: **DRAFT: “Read setup requirements”**
- Status badges: **DRAFT: “Source build,” “Planned,” “No release date”**

**Type, spacing, colour**

- Matrix rows: 52–56 px minimum.
- Platform: 16 px semibold; status: 14–16 px.
- Use cyan fill for the one available source-build action; planned statuses stay muted and never look clickable.

**Tailwind 4**

- Use `grid min-[701px]:grid-cols-[1.1fr_.9fr] gap-12`.
- Matrix: `divide-y divide-line rounded-card border border-line-strong bg-ink`.
- Row: `grid grid-cols-[1fr_auto] items-center gap-4 px-5 py-4`.
- Do not use disabled buttons for unavailable stores; render plain status text.

### Development updates

**Layout and content**

- Show three latest real changelog items with date, title, one-sentence summary, and optional existing capture.
- If build-time extraction from MDX is awkward, keep a three-item literal array beside the page; this is smaller and clearer than adding content infrastructure.

**DRAFT labels**

- Heading: **DRAFT: “Building in public”**
- Link: **DRAFT: “Read all development updates”**

**Type, spacing, colour**

- Date: 13–14 px label.
- Title: 20–24 px.
- Summary: 15–16 px, max three lines.
- 24 px card gap; 64–96 px section padding.

**Tailwind 4**

- `grid grid-cols-3 gap-6 phone:grid-cols-1`
- Reuse `card`; use `group` and `group-hover:text-accent` for the title only.
- Avoid motion beyond a 1 px lift, and disable it with `motion-reduce`.

### FAQ

**Layout and content**

- Four to six native `details` rows.
- Suggested questions, all DRAFT until approved:
  - **DRAFT: “Can I play WOLF//OVERRIDE now?”**
  - **DRAFT: “Is there a packaged download?”**
  - **DRAFT: “Which platforms are planned?”**
  - **DRAFT: “Do I play as WOLF?”**
  - **DRAFT: “Where can I follow development?”**
- Answers must restate only current public facts.

**Type, spacing, colour**

- Question: 18–20 px, semibold.
- Answer: 16 px, 1.7 line height, max 65ch.
- Summary target: at least 56 px; 16–20 px vertical padding.
- Use dividers and one cyan plus/minus indicator.

**Tailwind 4**

- `divide-y divide-line border-y border-line`
- `summary className="flex min-h-14 cursor-pointer list-none items-center justify-between gap-4 py-4 focus-visible:outline-none"`
- Use `group-open:` utilities for the icon; no JavaScript accordion.

### Community/follow CTA

**Layout and content**

- Add only after Nathanial selects a public destination.
- One short promise, one action, optionally one secondary social link.
- Do not add a newsletter input unless there is a real mailing system and privacy copy.

**DRAFT copy**

- Heading: **DRAFT: “Follow the build.”**
- Body: **DRAFT: “See new rooms, release notes, and playable-build updates as WOLF//OVERRIDE takes shape.”**
- CTA: **DRAFT: “Join the Discord”** or **DRAFT: “Follow development”**, depending on the approved destination.

**Tailwind 4**

- `rounded-card border border-accent/30 bg-surface px-8 py-10 phone:px-5 phone:py-8`
- Use one button with existing `heroAction` styling.

### Footer

**Layout and content**

- Preserve Nathanial’s original concept/core story/creative vision credit, MrDemonWolf, Inc. development credit, AI-assistance disclosure, legal/privacy/credits links, and working-title/provisional-art/no-release-date line.
- Remove only duplicated links if the final CTA already covers them; do not remove legal or credits routes.

**Type, spacing, colour**

- Group heading 12–13 px uppercase; link 15–16 px; legal/status 12–13 px.
- 44 px link targets.
- Desktop four columns; phone two columns, with brand/credit block spanning both.

**Tailwind 4**

- The existing grid is already appropriate. Keep `phone:grid-cols-2`, `col-span-full`, `border-t border-line`, and `text-muted`.

## 4. Phone specifics at 390 px

- Keep every interactive target at least 44×44 px; use 52–56 px for primary actions and FAQ rows.
- Keep the header button within the top-right thumb zone and place the hero CTAs low in the first content block, not over the art.
- Use 16 px page gutters. A full-width action is therefore about 358 px.
- Crop the hero art to preserve the engineer and WOLF together. The current left-anchored phone crop is a sound starting point; verify it at 320, 360, and 390 px before shipping.
- Do not put premise copy on top of the phone art. Use a gradient into `bg-ink`, then normal-flow text.
- Show only the most useful four facts in a 2×2 grid.
- Keep gameplay captures at 16:9. If a horizontal gallery is used, make the next card peek visible and provide a textual position indicator; do not rely on swipe discovery alone.
- Platform rows and update cards stack. Do not create four tiny platform tiles.
- Mobile navigation should close after activation, return focus predictably, lock no page content behind it, and respect Escape where available.
- Avoid a sticky bottom CTA unless analytics or testing shows the normal-flow CTA is missed; it would add obstruction and complexity without evidence.

## 5. Performance and accessibility

### Performance budget

- Target Core Web Vitals: LCP at or below 2.5 seconds at the 75th percentile on mobile; CLS at or below 0.1; INP at or below 200 ms.
- Keep the phone hero candidate at or below 80 KB and desktop hero at or below 180 KB. The current 29/66/137 KB variants already fit.
- Keep total above-the-fold transferred image bytes below roughly 300 KB on a first mobile visit.
- Gallery images: 480 px variant at or below 40 KB and 960 px variant at or below 100 KB when visually acceptable. The existing captures are already close to or within this target.
- Keep explicit `width` and `height` or `aspect-ratio` on every image.
- The hero alone gets `fetchPriority="high"`; gallery, updates, and below-fold art stay `loading="lazy"`.
- Preserve responsive `srcSet`/ `sizes`; do not ship the 1600 px image to a 390 px phone.
- No autoplay video. If a trailer exists later, use a poster image and user-initiated playback.
- No carousel library. Static grid or native scroll-snap is sufficient.

### Motion

- Keep motion functional and under roughly 180–250 ms.
- Allow a subtle 1 px CTA/card lift or gallery-scroll animation only.
- Pair every transition with `motion-reduce:transition-none`; any scripted scroll must switch to instant behaviour under `prefers-reduced-motion: reduce`.
- Never animate text continuously, pulse the CTA, or add parallax to the hero.

### Contrast, focus, semantics

- Preserve the current `header`, `main`, section headings, and `footer` landmarks.
- Keep one H1 and a logical H2/H3 order.
- Preserve the global 3 px focus ring and 2 px offset. Recheck at least 3:1 focus-indicator contrast on every new surface.
- Maintain at least 4.5:1 contrast for body text and 3:1 for large text and meaningful UI graphics.
- Never rely on cyan alone for status: pair colour with “Source build,” “Planned,” or “No release date.”
- Gallery controls need accessible names and visible position text. Full-size links must announce that they open an image/new tab, as the current page does.
- Use native `details/summary` for FAQ and retain keyboard activation.
- Decorative images use empty alt text; gameplay proof gets specific, concise alt text. Do not repeat the visible caption word-for-word.

## 6. What to avoid

- Generic SaaS framing: no “revolutionize your workflow,” pricing-style cards, logo clouds, metrics bands, or fake customer quotes.
- AI-art tells: extra anatomy, incoherent machinery, pseudo-lettering, excessive cyan/orange glow, glossy robot-head branding, or unregistered/generated filler art. Use the existing registered captures and approved assets.
- AI-copy tells: stacked fragments, vague grandeur, “more than a game,” “step into a world,” forced em dashes, or invented emotional claims.
- Terminal styling on the public site. The terminal look belongs only to the in-game Settings UI.
- Fake numbers: no player counts, wishlists, completion percentages, review scores, “award-winning,” or launch dates without a verified source.
- Fake testimonials, press logos, storefront badges, release countdowns, or disabled controls that look actionable.
- Spoiler-heavy story detail, provisional internal names, or claims that WOLF is playable.
- Auto-advancing carousels, autoplay video/audio, parallax, cursor gimmicks, and scroll-jacking.
- New bespoke CSS for this work. Use Tailwind 4 utilities, existing `@theme` tokens, and the existing shared class constants.

## 7. Mobbin references

| Product | Screen | Mobbin URL | Pattern | Exactly what to borrow |
|---|---|---|---|---|
| HBO Max | Black Adam cinematic hero | [Mobbin](https://mobbin.com/sites/sections/f291567d-0f1c-4c71-a3cb-b298fc0f694e) | Key-art hero | Put title, concise premise, and one action in the quiet side of key art with a strong readability gradient. |
| HBO Max | Ready for your next favorite split hero | [Mobbin](https://mobbin.com/sites/sections/305702e6-1b67-4c2d-8e14-83373e5ecb32) | Editorial hero | Use a controlled copy panel beside cinematic images; keep text away from subjects. |
| Apple | Shrinking Apple TV+ carousel hero | [Mobbin](https://mobbin.com/sites/sections/046ff1f9-3dc0-4c80-878c-d403495996c7) | Entertainment hero | Pair a short action and genre hook with dominant imagery; make lower content visibly secondary. |
| Epidemic Sound | Royalty-free cinematic feature | [Mobbin](https://mobbin.com/sites/sections/c8176f29-44c2-4bba-b068-81660d5f7c06) | Dark feature panel | Use one still, one blunt statement, one accent link, and generous negative space. |
| A24 | A24 app launch hero | [Mobbin](https://mobbin.com/sites/sections/c5dcdb53-983a-46ea-8d01-142a6100474b) | Editorial launch | Let title and artwork carry identity; keep platform facts compact. |
| TIDAL | Originals on all devices | [Mobbin](https://mobbin.com/sites/sections/8a841b2a-2d99-4cbf-ac25-5eafec2c113c) | Availability CTA | Combine one availability statement, one image, and one follow-up link. |
| HBO Max | Biggest Movies poster mosaic | [Mobbin](https://mobbin.com/sites/sections/1dd57555-4739-467b-81de-793f12919025) | Media proof strip | Put concise copy beside tightly cropped visual proof. |
| Siena Film Foundation | Film gallery grid | [Mobbin](https://mobbin.com/sites/sections/1115875b-e6af-4b8f-b002-d5aa10ec282e) | Cinematic gallery | Use consistent crops and minimal chrome so multiple frames read as a sequence. |
| Rivian | Vehicle gallery carousel | [Mobbin](https://mobbin.com/sites/sections/ceb97802-b7e4-4c5c-814c-220c0aea8def) | Large gallery | Lead with one large frame, visible position, simple controls, and a full-screen path. |
| Base | Asset collection grid | [Mobbin](https://mobbin.com/sites/sections/d4f3d376-5f46-430f-b7f6-0b3d82a90917) | Media contact sheet | Label visuals with useful metadata; avoid unexplained decorative thumbnails. |
| PayPal | Featured and additional stories | [Mobbin](https://mobbin.com/sites/sections/bfbfa657-cdbd-4f08-8b96-424931e1c7b9) | Lead story plus teasers | Feature one current update and two smaller follow-ups. |
| Grail | About Journey editorial timeline | [Mobbin](https://mobbin.com/sites/sections/17a1fab5-defb-422a-ab75-d4e8adc00025) | Narrative progression | Use numbered beats, short copy, and small frames to create rhythm without spoilers. |
| VanMoof | Live for the movement story panel | [Mobbin](https://mobbin.com/sites/sections/797e281b-ffe2-4d8e-adce-5e5515e54b1b) | Image-led premise | Put one short premise and one story link on a legible portion of a wide image. |
| Discord | Platform download cards | [Mobbin](https://mobbin.com/sites/sections/2809158e-5935-4deb-9d2d-43c1fac39424) | Platform downloads | Give each platform a clear label and status/action. |
| Craft | Desktop and mobile download matrix | [Mobbin](https://mobbin.com/sites/sections/a0b7540c-22d4-479f-830b-eede4bd022b2) | Availability matrix | Group desktop/mobile and make the recommended/current option obvious. |
| Clay | Dark multi-platform download page | [Mobbin](https://mobbin.com/sites/sections/4bc512f1-126c-4b38-88b4-ce21b294ce4e) | Dark downloads | Use labeled platform rows and short support copy without breaking the cinematic palette. |
| Deezer | Mobile platform availability section | [Mobbin](https://mobbin.com/sites/sections/7943de20-3afd-4d54-9f0d-e580747a9c84) | Alternating device rows | One platform heading, sentence, badge/status, and image per row. |
| Linear | Changelog card row | [Mobbin](https://mobbin.com/sites/sections/44c38fe6-0c18-4730-a93d-0baf7dbd4f50) | Update teaser | Show three dated updates with real thumbnails and an all-updates link. |
| Cursor | Compact changelog strip | [Mobbin](https://mobbin.com/sites/sections/56c0a44a-16ef-4f35-ae19-dd3f87be370e) | Text-first changelog | Keep version/date/title visible when strong imagery is unavailable. |
| SpaceXAI | Join the conversation links | [Mobbin](https://mobbin.com/sites/sections/ca39b43a-51d6-41de-9917-afce3db849d9) | Community links | Explain why to join, then list explicit destinations instead of icon-only links. |
| Framer | Join our Discord community card | [Mobbin](https://mobbin.com/sites/sections/ace1b79b-7e61-4193-9486-669f8031143a) | Community CTA | One sentence about the community and one verb-led button. |
| The Leap | Newsletter and footer block | [Mobbin](https://mobbin.com/sites/sections/5a5e734d-0b06-4545-8131-5e421c4560be) | Newsletter close | Put the follow action beside final footer navigation. |
| Locomotive | Dark FAQ accordion | [Mobbin](https://mobbin.com/sites/sections/056c0156-ba82-4238-8b86-5e7049a20103) | Minimal FAQ | Use short questions, one open answer, strong dividers, and large row targets. |
| Dovetail | Questions and answers split layout | [Mobbin](https://mobbin.com/sites/sections/305c3f1c-1497-4d04-9803-7b977805d603) | Split FAQ | Keep the heading stable beside a narrow accordion on desktop. |
| Current | Dark grouped footer with CTA | [Mobbin](https://mobbin.com/sites/sections/33353d30-cc34-4205-949a-a72e0cde3d6d) | Footer conversion/legal | Place one final action before clearly labeled product, legal, and social groups. |
| Resend | Dark multi-column footer | [Mobbin](https://mobbin.com/sites/sections/9301c687-40d0-4d8d-bbb8-b1325bac2679) | Footer hierarchy | Use quiet headings, wide spacing, and a small trust/status item. |
| Square | Make your next move image CTA | [Mobbin](https://mobbin.com/sites/sections/f3b33314-0ee1-476c-b4b8-f1e5d5d0f2a0) | Image CTA | Center one compact visual and limit the area to primary/secondary choices. |
| Google TV | Hijack title detail | [Mobbin](https://mobbin.com/screens/a1f44c0d-58fe-456e-a388-cd11b244a7b5) | Phone title hierarchy | Art, title, compact metadata, short synopsis, full-width action, then secondary actions. |
| Netflix | Wonder title detail | [Mobbin](https://mobbin.com/screens/f7087383-70ec-4e3a-85c7-a4e5428cdc25) | Phone media detail | Keep the principal action full width and immediately below metadata. |
| HBO Max | Game of Thrones title detail | [Mobbin](https://mobbin.com/screens/af95ae3e-1f3b-484b-acd0-7d67bf6a560f) | Poster/content transition | Fade tall artwork into controls so copy never competes with the focal image. |
| Paramount+ | Tracker title detail | [Mobbin](https://mobbin.com/screens/775152ea-3d99-4195-9057-c013f8c019cb) | Compact phone metadata | Put genre, status, and synopsis into a tight block below one dominant action. |
| Apple TV | Argylle title detail | [Mobbin](https://mobbin.com/screens/4def31fa-a9a3-47e9-96e1-bbd7da3a57c3) | Progressive disclosure | Order hero, action, short premise, metadata, then trailers/media. |

## 8. Open questions for Nathanial

- What is the landing page’s primary conversion for the next milestone: viewing gameplay, running the source build, joining a community, or wishlisting later?
- Is there a public Discord destination approved for this game, or should GitHub/changelog remain the only follow path?
- Is a mailing list real and maintained? If not, omit newsletter UI entirely.
- May the title-screen and Service Junction captures be shown publicly on the landing page now, or is one of them too provisional?
- Should “sci-fi horror” remain the lead genre label, or should “narrative adventure” lead?
- Is “single-player” approved public wording?
- Can the source-build guide truthfully name desktop OS support individually today, or should the platform matrix keep “source build” separate from planned packaged releases?
- Which four FAQ answers should be canonical in public copy?
- Should the page show latest changelog entries manually, or should a small build-time reader extract them from existing content?
- Is the provisional key art staying through the next site pass, or should the redesign reserve the hero composition for replacement art?

Research by Codex (OpenAI) using references found on Mobbin (mobbin.com), 2026-10-15. Mobbin screens belong to their owners and are cited, not copied.
