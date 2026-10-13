# Service Junction art (review page, October 9, 2026)

Markdown copy of the approval sheet "WOLF//OVERRIDE Junction Art" shown to Nathanial on October 9, 2026. Scripts and styles are dropped. The page's images were preview copies of art that is tracked; the captions below point at the tracked files. The sentry comparison made after this review is kept as [`../../sources/sentry-v2/v1-vs-v2-sheet.webp`](../../sources/sentry-v2/v1-vs-v2-sheet.webp).

**Outcome.** The junction layers and station props were approved and integrated (`apps/game/assets/rooms/junction-*.png`, `apps/game/assets/props/`; sources in [`../../sources/junction-art/`](../../sources/junction-art/)). For Check 4, Nathanial chose "Redo as scanner (Recommended)": sentry v2 keeps the approved body and replaces the gun-like emitter with a scanner head ([`../../sources/sentry-v2/APPROVED`](../../sources/sentry-v2/APPROVED), October 9). All of this was later superseded by the Look 2 redo.

---

*Approval sheet · October 9, 2026*

Art for the third room, made with Codex's image tool using the approved corridor and Records layers and the station props as style references. Today the junction borrows the corridor painting with a tint; this would give it its own look. All files are still in the scratchpad: nothing is in the game yet, and the commercial rights review stays open.

## Check 1. The room as parallax layers

The coolant service line runs along the back wall into the middle of the room, with gauges, hazard stripes and a cable gantry over the right half. The walkway sits at the same height as the corridor's, so the characters stand at the same line in every room. No stations are painted in; the game places them as separate sprites.

- **Stacked** (image not kept). Far wall, mid machinery and walkway, near edge silhouettes. Layers: [`junction-far.png`](../../sources/junction-art/layers-junction/junction-far.png), [`junction-mid.png`](../../sources/junction-art/layers-junction/junction-mid.png), [`junction-near.png`](../../sources/junction-art/layers-junction/junction-near.png).
- **Parallax shift preview** (image not kept). Layers moved at different rates; no seams.

## Check 2. Staged mock: how the pieces read together

A rough paste-up at the room's real station positions, before and after the two booms. It is not a game render: the in-game camera is closer (1.35 zoom), so everything appears larger, and final sizes are tuned in the engine.

- **Before** (image not kept). Breaker, relief vent, valve, sealed door, arm panel, hanging tank, sentry, bolt panel, hatch.
- **After** (image not kept). Door blown open; sentry wrecked.

## Check 3. Junction stations

Same rendering as the approved corridor and Records props: valve with gauge, the blast door sealed and blown, the drop arm with its coolant tank, the arm panel, the bolt panel, the exit hatch and the relief vent grate. The junction's breaker reuses the corridor breaker.

**Eight pieces** (image not kept). Transparent backgrounds, no text, no baked shadows. Files: [`../../sources/junction-art/props-junction/`](../../sources/junction-art/props-junction/).

## Check 4. The purge sentry

A tracked security unit with a red sensor eye, and a wrecked version for after the tank drop. In the game it patrols, chases and knocks the engineer down on contact; it never fires. The long cyan emitter on top can read as a gun barrel, which would promise an attack that never comes. A scanner head with a sweeping light would match what it does.

**Wrecked and active** (image not kept). Side view, facing left; the game mirrors it when it turns. Version 1 is the left column of [`v1-vs-v2-sheet.webp`](../../sources/sentry-v2/v1-vs-v2-sheet.webp).

Provenance note for the asset register: the generation tool removed three PNG text metadata chunks from each file during export; no C2PA manifest was present. The register will record the tool, the reference files, the date and this metadata removal.

---

## Credits

- Game and decisions: Nathanial Henniges.
- Art: Codex's built-in image tool (edit mode); provenance per asset in `apps/game/assets/manifest.json`.
- Page: Claude (Claude Code) agent working for Nathanial.
