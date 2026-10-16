# The brief Codex was given (October 15, 2026)

The exact prompt for the one Codex chat. The scratch folder path is shortened to `<scratch>/landing-mobbin/`.

```text
One research chat for Nathanial Henniges, owner of WOLF//OVERRIDE (MrDemonWolf, Inc.). Research only.

GOAL: use Mobbin (your connected, signed-in Mobbin MCP) to research and write a detailed, practical design brief for making the WOLF//OVERRIDE landing page better.

THE PAGE TODAY: the public site lives in this repository at apps/docs (Next.js 16 static export, Fumadocs, Tailwind CSS 4). The landing page is apps/docs/app/page.tsx with its parts. Read downloads.tsx, marketing-navigation.tsx, landing-classes.ts, layout.tsx, global.css and its @theme tokens, and look at the images under apps/docs/app/images and apps/docs/public. The live page is https://wolfoverride.mrdemonwolf.dev/; you may fetch its HTML with curl, but do not open a browser. Read docs/decisions.md for the site decisions already made, for example:
- the docs site is mostly Tailwind;
- the terminal look belongs only to the in-game Settings, never the site;
- the landing page's theme.
WOLF//OVERRIDE is a Godot side-view cinematic sci-fi game. The engineer (they/them) is the only playable character; WOLF (he/his) is an independent robot-wolf companion.

RULES:
1. Read-only on the repository. Create, edit or delete no file in it, run no git command that changes anything, and install nothing.
2. Write only into OUT = <scratch>/landing-mobbin/ (it already exists).
3. Open no windows on this Mac: no browser, no Finder, no "open" command, no screen captures. Do not search the whole disk or home folder (the repo's AGENTS.md says the same).
4. Mobbin screenshots are third-party material. Do not download or save them; cite each reference by its Mobbin URL plus the product and screen name.
5. Keep story spoilers out: use only what the public landing page and public docs already say. Label any new player-facing wording you suggest as a DRAFT for Nathanial's approval.
6. Touch no other connector (no Notion, GitHub, Discord or others).
7. Be honest about limits. If a Mobbin search returns little, say so. Never invent references or numbers.

STEPS:
A. Read the current landing page and list what it has now:
   - sections in order;
   - headline and copy;
   - CTAs and imagery;
   - type, colours and spacing;
   - mobile behaviour, as far as the code shows it;
   - its weak spots.
B. Search Mobbin for strong real references. Start with web patterns, and use apps where useful. Prefer shipped products. Collect at least 25 relevant screens from at least 12 different products. Record every query in OUT/queries.txt. Look for:
   - game, studio and publisher landing pages;
   - entertainment and streaming heroes built on key art;
   - story or premise sections;
   - screenshot and media galleries;
   - early-access, wishlist or "get the build" download sections with platform status;
   - dev log or changelog teasers;
   - community and follow CTAs (Discord, newsletter);
   - FAQ;
   - footers with legal and credits;
   - mobile navigation;
   - dark themes with a single accent colour.
C. Write OUT/MOBBIN-LANDING.md, easy to scan, with these parts:
   1. Summary: the 10 changes that would most improve the page, ranked, each in one or two lines with the reference behind it.
   2. Recommended page structure for desktop and for phone (390 px): the section order and what each section holds.
   3. Section by section:
      - layout, content and imagery;
      - CTA labels;
      - type scale and spacing in px or rem, and colour use;
      - how to build it with Tailwind 4 utilities and the existing @theme tokens (no new bespoke CSS).
   4. Phone specifics: navigation, thumb reach, tap targets of 44 px or more, image crops.
   5. Performance and accessibility:
      - an LCP budget and image sizes;
      - motion that respects prefers-reduced-motion;
      - contrast, focus and landmarks.
   6. What to avoid: generic SaaS-template looks, AI-art and AI-copy tells, terminal styling, fake numbers or testimonials.
   7. A references table: product, screen, Mobbin URL, pattern, and exactly what to borrow.
   8. Open questions for Nathanial.
   End with this credits line: "Research by Codex (OpenAI) using references found on Mobbin (mobbin.com), 2026-10-15. Mobbin screens belong to their owners and are cited, not copied."
D. Also write OUT/references.json: an array of {product, screen, mobbin_url, pattern, borrow}.
E. Finish by printing the three output paths and the number of references.
```
