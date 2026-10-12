# UI/UX Review: WOLF//OVERRIDE marketing homepage

**Reviewed:** September 30, 2026 · **Input:** local source and working browser preview · **Method:** NN/g heuristic evaluation and guideline review

## Executive summary
- Cinematic existing artwork introduces the game; story and gameplay copy retains Nathanial's original vision and distinguishes the current source slice from the planned campaign.
- All six planned download channels show Coming soon, semantic unavailable state and descriptive browser-native tooltips. No download, purchase or store URL exists.
- Browser initially suggested macOS correctly. Manual Android and Windows selection changed highlighted channels. Deterministic cases cover Windows, Mac, iPhone, iPad, desktop-mode iPad, Android and unknown Linux.
- No severity 3–4 issues observed in the tested flows. No remaining concrete severity 1–2 defects were identified in this bounded review.

**Findings:** 0 catastrophic · 0 major · 0 minor · 0 cosmetic

## Findings
No unresolved observed finding. This is a bounded review, not an accessibility conformance claim.

## Evidence and tested flows
- Browser viewport previews: 1440×1000, 477px width and 390×844. No horizontal overflow at 1440 and 390. Dark/light hero and download layouts inspected; stacked mobile features inspected.
- Keyboard: Tab from native platform selector reaches first unavailable button; visible focus outline measured 3px. Browser automation intentionally refuses activation of aria-disabled buttons; code has no activation handler or link. Physical touch and assistive technology remain untested.
- Headings: one H1, H2 sections and H3 feature titles. At 390px: 60.8px / 41.6px / 20.8px. Body text 16px with 1.7–1.8 line height. Meaningful hero image has alt text; decorative logo has empty alt.
- Sample text contrast from actual CSS colors: dark muted text 10.75:1 on background / 9.45:1 on surface; light muted text 6.93:1 / 6.26:1; light availability accent 6.10:1 / 5.52:1. These solid-color measurements do not certify every point over artwork.
- No captured browser error logs at final check. Local docs types/build and OS suggestion check passed. No fonts, art, analytics or packages added.
- [NN/g usability heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/): release status stays visible, alternatives remain discoverable, platform choice stays under user control.
- [W3C SC 1.4.13](https://www.w3.org/WAI/WCAG22/Understanding/content-on-hover-or-focus.html): persistent Coming soon labels avoid making availability dependent on hover. Supplementary native title tooltips follow browser behavior.

## Unverified (needs a different input to check)
- Physical iOS/Android, Safari/Firefox and real screen-reader operation.
- OS suggestion with spoofed or reduced user-agent strings in actual browsers; override remains available.
- Native tooltip display duration and touch behavior; visible labels provide the same essential status.
- Full WCAG conformance, performance budget and asset-rights release approval.

## What's working well
- Hero uses registered key art and labels its provisional status.
- Existing light/dark control and guide/credits/changelog links remain discoverable.
- Platform detection is local, makes no network request and never starts a download.

## Quick wins
- [x] Keep status visible beyond tooltip behavior.
- [x] Keep OS selection overridable and unknown OS neutral.
- [x] Carry platform-detection regression into docs CI.
