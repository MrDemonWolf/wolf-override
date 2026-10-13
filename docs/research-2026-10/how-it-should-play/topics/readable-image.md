# Readable 2.5D image: figures against backgrounds, layers, light and contact (round 2, topic 12)

WOLF//OVERRIDE is an original game and story by **Nathanial Henniges**. Nathanial's central ask is "make it look real ... no AI slop". The first eleven topics covered doors, floating objects and effects but not whether the characters read against the painted rooms, how the depth layers should behave, or how light and contact tie them together. This note adds that, measured on the capture frames and tied to the project's own art rules (docs/research-2026-10/art-bible.md and art-direction/REAL-LOOK.md), which already set most of the numbers. Written 2026-10-13 by an AI agent (Claude Code by Anthropic); sources opened 2026-10-13.

## 1. Measured: the characters barely separate from the rooms by value

Method (round2/tools/contrast.py in the scratch folder): for each frame, the engineer's and WOLF's boxes are placed from the per-frame log (world position, camera centre and zoom), checked by eye on drawn boxes; "figure" pixels are those whose relative luminance differs from the median of a 12-world-px ring around the box; the ratio is the WCAG contrast ratio of the figure median against the ring median.

| Frame (desktop route D) | Engineer | WOLF |
|---|---|---|
| D-0048 corridor, first control | 1.18:1 | 1.69:1 |
| D-0095 at the bypass | 1.59:1 | 1.32:1 |
| D-0116 Records entry | 1.17:1 | 1.16:1 |
| D-0131 Records mirror | 1.17:1 | 1.39:1 |
| D-0165 junction entry | 1.44:1 | 1.18:1 |
| D-0205 junction lane choice | 1.29:1 | 1.22:1 |
| D-0240 tank drop | 1.40:1 | 1.29:1 |

Range 1.16-1.69:1, median ~1.3:1. The engineer reads by the red jacket (hue), not by value; WOLF, dark steel on dark blue, reads mostly by his cyan seam lights. In greyscale both nearly vanish into the walk band. This repeats the October 10 audit's figure of 1.01-1.18:1 on real frames (art-bible.md §3.7) and the art bible's measured body lightness (Rowan L* 20.6, WOLF 16.4 against a walk band of L* 8.5-12.2, §3.2).

The yardsticks already exist in the project:
- art-bible.md §3.2: actors' bodies at L* 20-32 and at least 12 above the local walk-band median; the mid plate's walk band at L* ≤ 10.
- §3.7: median WCAG contrast ≥ 1.6:1, at least 30% of the perimeter (the rim-lit side) at ≥ 3:1, lost edge ≤ 35%; a silhouette test at 94 px and 188 px tall; a 2 px blur test at 960 × 540.
- WCAG 1.4.11 asks 3:1 for "Parts of graphics required to understand the content" [READABLE-IMAGE-4]; the art bible applies 3:1 only on the rim-lit side, which suits a dark scene.

Only 1 of 14 measurements (WOLF in D-0048) passes the ≥ 1.6:1 median; none was checked for the 30% rim at 3:1 (that needs a with/without-sprite render, as the audit did).

## 2. Layers and parallax

- The art bible fixes three depth bands: far plate (lightest, low contrast, haze), mid plate (carries the playfield), near pieces (darkest, simplest) (§3.2, "Ordering", sourced to aerial perspective and Team Fortress 2's NPAR07 paper).
- Ori and the Blind Forest's lead artists: "we can give each graphic different lighting, color, and movement sets" and they wanted Ori "very small on the screen"; the game holds over 7,000 hand-painted graphics [READABLE-IMAGE-2]. Airborn Studios, who defined Ori's look: "a layered painterly look that has depth to it and doesn't look as flat as 2D games often do. While remaining very readable, the outcome is always at the service of the gameplay", built over "rough blockouts to test and refine the gameplay" [READABLE-IMAGE-3].
- No source opened gives parallax speeds or layer counts as numbers. Derived proposal: the far plate scrolls at ~0.3-0.5 × the camera, the mid (play) plate at 1.0, near pieces at ~1.2-1.5 × and only at the room edges, so they never cover an actor or a station; test it in a still strip and by hand (motion sickness is checked under XAG 117 [GAP-PASS-11]).
- Small-on-screen is a choice with a phone cost: Ori chose small for scale; WOLF//OVERRIDE's story rests on reading WOLF's body (WOLF-5, WOLF-11). On an iPhone 16 (2556 × 1179, 460 ppi) with today's `keep` stretch and zoom 1.35, the engineer is ~206 device px ≈ 11 mm tall and WOLF ~8.5 mm tall (derived from the 70 px / 52 px sprite heights).

## 3. Light and contact

- INSIDE's rendering talk (Playdead, GDC 2016) authored lighting "as entirely separate diffuse, specular and bounce-light entities" with "analytic primitive-based ambient occlusion" [READABLE-IMAGE-1]; only the session description was readable (the slides are members-only), so this is the approach, not numbers.
- The art bible's lighting rules (§3.3): overhead cold strip lamps every 300-400 world px light floors and the tops of objects; every actor and prop is top-lit with a lighter top rim; a cyan-white rim 4-8 source px on top and back edges; shadows "cold blue-black ... never neutral grey". Measured there: the actors' top-rim lightness is −12 (Rowan) and −12.9 (WOLF), "unlit cut-outs", against +3.9 to +5.9 on props.
- REAL-LOOK.md §3 items 2 and 4: one light logic; "contact shadows are darkest at the contact line"; "Nothing floats. Base on y 440 within 1 px and a visible contact shadow (floor right at the base clearly darker than 8-12 px further out; today it reads 0.86-1.01)".
- Perception research already in SOURCES: without a shadow or interreflection people judge contact at chance [PLAYTESTING-HUMAN-15] [PLAYTESTING-HUMAN-16] [LEVEL-ARCHITECTURE-29]. The game's soft 12 px contact ellipse at ≤ 0.5 alpha (floor_reflection.gd:98-114) was read by two reviewers as a "blue selection bar" (AUDIT 9).

## 4. Where this agrees or disagrees with the project's rules

- **Agrees** with art-bible §3.2, §3.3 and §3.7 and REAL-LOOK §3; the capture confirms the bible's measured problem has not changed since October 10 (the repaint batches are not built).
- **Adds:** a per-room greyscale test on rendered frames (not loose assets), done the same way each round with contrast.py; and a phone-size check of WOLF's body language (READ-4).
- **Somerville** (pulled-back establishing shots that "show the scale" [GAP-PASS-28]) and **Ori** (small hero) show the tension between scale and reading a companion's body; for this game the companion's body wins on phones.
- Still open: Little Nightmares, Unravel and Gris readability talks (searched; no primary source on figure-ground or layering was found in this pass).

## Sources (topic 12)

| Id | Creator | Title | Venue, year | URL |
|---|---|---|---|---|
| READABLE-IMAGE-1 | Mikkel Gjøl and Mikkel Svendsen (Playdead) | Low Complexity, High Fidelity: INSIDE Rendering | GDC 2016, GDC Vault session page (description only; slides members-only) | https://gdcvault.com/play/1023002/Low-Complexity-High-Fidelity-INSIDE |
| READABLE-IMAGE-2 | Xbox Wire Staff, quoting Max Degen and Johannes Figlhuber (lead artists) | The Art of Ori and the Blind Forest | Xbox Wire, 2015 | https://news.xbox.com/en-us/?p=4339 |
| READABLE-IMAGE-3 | Airborn Studios | Ori and the Blind Forest (project page) | airborn-studios.com, 2015 | https://airborn-studios.com/projects/ori |
| READABLE-IMAGE-4 | W3C (WAI) | Understanding Success Criterion 1.4.11: Non-text Contrast | WCAG 2.2 Understanding, current 2026 | https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html |

Project documents (not outside sources): docs/research-2026-10/art-bible.md §3.2, §3.3, §3.7; docs/research-2026-10/art-direction/REAL-LOOK.md §3.

*Compiled 2026-10-13 with AI assistance (Claude Code by Anthropic) for Nathanial Henniges.*
