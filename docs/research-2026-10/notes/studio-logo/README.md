# Studio logo screen re-review (October 12, 2026)

On October 12 the game gained a studio logo screen (commit b98bc94, "Open the game on the MrDemonWolf, Inc. logo"): the MrDemonWolf, Inc. mascot goes from a smirk to a grin with a small hop, "MrDemonWolf, Inc." fades in under it, it lasts about 2 seconds, any input skips it, and it has no sound. A first independent review found four defects; commit baffea4 ("Keep logo-skip presses off the title and apply saved window at launch") fixed them, and this re-review checked the fix.

**Verdict: pass.** All four earlier defects (a second press starting a New Game, the saved window applied late, the loading bar stuck at about 98%, quitting during the load) were fixed, and no new defect was found. Evidence is headless probes, `tools/render/render.sh` stills and CI; nobody watched or played the logo in a game window or on a device.

## Files

- `2026-10-12-logo-re-review-baffea4.md`: the re-review (earlier defects, re-verified items, notes). Links to its working files now point at the two images kept here; the probe scripts stayed in the session scratch and were not kept.
- `sheet720.webp`: contact sheet of the logo frames at 1280x720 (WebP quality 80 of our own render).
- `bar-crops.webp`: crops of the loading bar's sweeping segment from the key-skip run (WebP quality 80).

The logo is company branding of MrDemonWolf, Inc. and is not covered by the game's GPL licence. The brand source files and their location are deliberately not part of this repository; the game carries only the brand PNGs listed in its asset register.

## Credits

- Game and studio: Nathanial Henniges, MrDemonWolf, Inc. (the mascot and logo are company branding).
- Logo screen code and the review: Claude (Claude Code) agents working for him; renders made with Godot 4.7.2 inside the container of `tools/render/render.sh`.
- No outside sources were used.
