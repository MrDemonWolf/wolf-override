# Look picks (review page, October 8, 2026)

Markdown copy of the review sheet "WOLF//OVERRIDE Look Picks" shown to Nathanial on October 8, 2026. The images are our own renders of the game build and trial art composites, re-encoded as WebP in [`look-picks/`](look-picks/). Outcome: the picks shipped in PR #42 (merged): the dimensional menu theme, the depth pass, gameplay zoom 1.35 and layered room art (see `docs/next-session.md` and the presentation research in [`../reviews/2026-10-08-presentation-research.json`](../reviews/2026-10-08-presentation-research.json)).

---

*Review sheet · October 8, 2026*

Every image here is a rendered still from the source build or a trial art composite. None of it has been played by hand yet, so this page compares appearance only, not feel.

## Pick 1. Menus and HUD: one dimensional style

Left is the build before the pass. Right is the committed theme: layered gradients, drop shadows, a lit top edge, a filled focus state, and hover and press motion. Settings keeps its squared terminal identity and gains the same depth.

| Before | After |
|---|---|
| ![Title screen before: flat buttons on the key art](look-picks/ui-title-before.webp) **Title · before.** Flat cards on the key art. | ![Title screen after: lifted buttons with shadow and a veil behind the menu column](look-picks/ui-title-after.webp) **Title · after.** Lifted buttons, a veil behind the menu column, caption under Continue. |
| ![Pause menu before](look-picks/ui-pause-before.webp) **Pause · before.** Flat panel, outlined buttons. | ![Pause menu after: a card with shadow and sheen, filled focus on Resume](look-picks/ui-pause-after.webp) **Pause · after.** Card with shadow and sheen; Resume shows the filled focus. |
| ![Settings before](look-picks/ui-settings-before.webp) **Settings · before.** Terminal look, flat. | ![Settings after: the terminal look with depth](look-picks/ui-settings-after.webp) **Settings · after.** Same terminal identity, same depth treatment. |

**Your call:** Keep this direction, push it further (stronger gradients, glow, bigger motion), or pull it back?

## Pick 2. Rooms: depth with the art we already have

Same paintings, new presentation layer: lamp glows that flicker, drifting light shafts, dust, a haze that pushes the back wall away, reflections and contact shadows on the wet floor, near-edge pillars, and a vignette with a cold grade. All of it sits behind one switch. The limit: with a single flat painting the parallax shift is small, and the floor slides slightly against the characters. Real depth needs the layered art in section 4.

| Before | After |
|---|---|
| ![Corridor start before the depth pass](look-picks/depth-corridor-before.webp) **Corridor · before** | ![Corridor start after the depth pass with lamp glow, haze and floor reflections](look-picks/depth-corridor-after.webp) **Corridor · after** |
| ![Relay and safe point before](look-picks/depth-relay-before.webp) **Relay and safe point · before** | ![Relay and safe point after](look-picks/depth-relay-after.webp) **Relay and safe point · after** |
| ![Records Access before](look-picks/depth-records-before.webp) **Records Access · before** | ![Records Access after](look-picks/depth-records-after.webp) **Records Access · after** |

**Your call:** Keep it on as the default look? Anything too much (vignette, haze, glow) or not enough?

## Pick 3. Gameplay zoom: 1.18 (today) · 1.35 · 1.5

Rendered from the current build with the depth pass on. Tighter zoom shows more of the painted detail and makes the characters larger; it also shrinks the visible room, so the camera travels more and the characters sit closer to the dialogue panel. The art has headroom: the paintings are 1672 px wide, so 1.5 is still sharp.

| 1.18 (today) | 1.35 | 1.5 |
|---|---|---|
| ![Corridor at zoom 1.18](look-picks/zoom-1.18-corridor.webp) | ![Corridor at zoom 1.35](look-picks/zoom-1.35-corridor.webp) | ![Corridor at zoom 1.5](look-picks/zoom-1.5-corridor.webp) |
| ![Relay at zoom 1.18](look-picks/zoom-1.18-relay.webp) | ![Relay at zoom 1.35](look-picks/zoom-1.35-relay.webp) | ![Relay at zoom 1.5](look-picks/zoom-1.5-relay.webp) |

**Your call:** 1.18, 1.35 or 1.5? (A new value also means re-tuning where the camera rests vertically so the characters stay above the dialogue panel.)

## Pick 4. Layered art: real parallax from regenerated paintings

Trial sets made with Codex's image tool from the existing paintings as references: a far wall, a mid layer of machinery with transparency, and near silhouettes at the edges. Stacked, each set reads as one room in the same style; moved at different speeds they show no seams. These are trial files in the scratchpad, not in the game. If you like them, the next step is regenerating both rooms as layers plus consistent character sprites, with provenance in the asset register and the rights review still open.

| | |
|---|---|
| ![Corridor trial layers stacked](look-picks/layers-corridor.webp) **Corridor · three layers stacked** | ![Records Access trial layers stacked](look-picks/layers-records.webp) **Records Access · three layers stacked** |
| ![Corridor mid layer alone, machinery with transparency](look-picks/layers-corridor-mid.webp) **Corridor · mid layer alone.** Transparent where the far wall shows through. | ![Corridor near layer alone, silhouettes at the edges](look-picks/layers-corridor-near.webp) **Corridor · near layer alone.** Edges and floor only; the play area stays clear. |

**Your call:**
- Approve regenerating both rooms as layered sets (and the station props on transparency)?
- Regenerate the character sprites in the same pass for consistency, or keep the current ones for now?

Not shown: the title screen's cinematic art, which was fixed earlier (two ears) and left as is.

---

Credits: page, renders and composites by Claude (Claude Code) for Nathanial Henniges, rendered with Godot; the layered trial art was made with Codex's built-in image tool from the game's existing paintings (the layered room art that later shipped is recorded in `apps/game/assets/manifest.json`).
