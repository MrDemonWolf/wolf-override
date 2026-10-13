# Art audit and the art bible's QA tools (October 10, 2026)

On October 10, 2026, every art asset in the game and on the website was measured: how sharp it is at each screen size and zoom (source pixels per screen pixel), its alpha and edge fringe, colour against the rooms, noise, compression and how readable it is in real 960x540 game frames. The results ranked the 26 worst problems and fed the art bible ([`../../art-bible.md`](../../art-bible.md)), which turned them into one rule set and an automatic check, `qa_asset.py`, that every later asset had to pass. The art bible says these tools "lived in the session scratchpad"; they are now kept here.

## Decision

The audit led to the high-quality redo. Nathanial Henniges approved a style test first and picked Look 2 on October 10, 2026 ([`../review-pages/2026-10-10-style-test.md`](../review-pages/2026-10-10-style-test.md)); every asset was then redone in Look 2 and checked with `qa_asset.py` ([`../../sources/look2-hq/`](../../sources/look2-hq/), [`../../sources/walk-final-2026-10-11/`](../../sources/walk-final-2026-10-11/)). The summary and the bible are also in [`../../data/art-bible.json`](../../data/art-bible.json).

## Files

| Path | What it is |
|---|---|
| `assets.json` | Per-asset audit of the game art at the time: file, where the game uses it (node, scale, zoom, mipmaps), size, memory, and the measurements. |
| `ranking.json` | The 26 worst problems, ranked, with the measured defect. |
| `readability.json` | For each sprite in each real game frame: how well the silhouette separates from what is behind it (colour difference, edge band, lightness). |
| `fringe_compression.json` | Edge fringe with premultiplied alpha, and compression quality (desktop S3TC and mobile ETC2, decoded through Godot). |
| `defect_points.json` | The located defects per asset. |
| `site.json` | The website's images: size and bytes. |
| `evidence/sources.json` | Every outside source the audit read, with its URL and what it was used for (listed under Credits). |
| `evidence/measure.json`, `evidence/band-contrast.json` | Room, character and prop measurements, and contrast by band. |
| `bible/qa_asset.py` | The automatic QA, Python 3 standard library only: checks A (solid body), B (holes), C (fringe and key spill), D (baseline), E (density per screen size and zoom), F (palette), G (noise) and H (readability against a background). Usage is in its header. |
| `bible/palette.py`, `bible/regions.py` | Palette samplers (per lightness band and per region of key art B). They import `../tools/measure.py`, kept for that reason. |
| `bible/palette_card.py`, `bible/palette-card.webp` | The script and the colour-only palette card attached to every Codex call (WebP quality 80 copy of the 1520x512 PNG; regenerate the PNG with the script). |
| `bible/calibration.jsonl`, `bible/cal/*.json` | The QA run over 21 current assets that set the thresholds. |
| `bible/palette-assets.jsonl`, `bible/palette-keyart.jsonl`, `bible/keyart-b-regions.json` | The palettes sampled from the assets and from key art B. |
| `tools/measure.py` | PNG reading and measurement helpers used by the palette samplers. |

Paths starting `apps/` are files in this repository as they were on October 10 (several have since been replaced). Paths written as `[session scratch, not kept]/...` pointed into the session scratch folder (captured frames and scratch art). Run the tools with `python3 -I`. The audit's JavaScript analysis scripts and the captured frames drove one run and were not kept. The audit calls the engineer by the provisional name Rowan; the engineer is non-binary and uses they/them.

## Credits

- **Game, art direction and decisions:** Nathanial Henniges.
- **Audit, art bible and tools:** Claude (Claude Code) agents working for Nathanial; measurements in Python 3 and Node.js, game frames from Godot 4.7.
- **Outside sources the audit relied on** (from `evidence/sources.json`; read, not copied):
  - Godot Engine documentation: "Importing images" (<https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html>), "CanvasItem" (<https://docs.godotengine.org/en/stable/classes/class_canvasitem.html>), "Multiple resolutions" (<https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html>), "2D lights and shadows" (<https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html>).
  - Android Developers, "Optimize textures" (<https://developer.android.com/games/optimize/textures>).
  - Khronos Group, OpenGL ES 3.0 reference, `glGet` (`GL_MAX_TEXTURE_SIZE`) (<https://registry.khronos.org/OpenGL-Refpages/es3.0/html/glGet.xhtml>).
  - Mitchell, J., Francke, M. and Eng, D., "Illustrative Rendering in Team Fortress 2", NPAR 2007, Valve (<https://cdn.cloudflare.steamstatic.com/apps/valve/2007/NPAR07_IllustrativeRenderingInTeamFortress2.pdf>).
  - Gritton and van Leeuwen, "The Art of Ori and the Will of the Wisps", GDC 2021 (abstract only) (<https://gdcvault.com/play/1027035/The-Art-of-Ori-and>); Xbox Wire on Ori and the Blind Forest (<https://news.xbox.com/en-us/?p=4339>); Wikipedia, "Ori and the Blind Forest" and "Ori and the Will of the Wisps".
  - Gjøl, M. and Svendsen, M. (Playdead), "Low Complexity, High Fidelity: INSIDE Rendering", GDC 2016 (<https://www.gdcvault.com/play/1023002/Low-Complexity-High-Fidelity-INSIDE>); Wikipedia, "Inside (video game)".
  - Unity, "Made with Unity: Hollow Knight" (<https://unity.com/madewith/hollow-knight>); Wikipedia, "Hollow Knight" and "Ari Gibson".
  - Wikipedia: "Child of Light", "Darkest Dungeon", "Jen Zee", "Planet of Lana", "Aerial perspective".
  - Game Developer, "Art Design Deep Dive: Using a 3D pipeline for 2D animation in Dead Cells" (<https://www.gamedeveloper.com/production/art-design-deep-dive-using-a-3d-pipeline-for-2d-animation-in-i-dead-cells-i->).
  - OpenAI, "Image prompting" guide (<https://developers.openai.com/api/docs/guides/image-prompting>).
- **Methods in `qa_asset.py`:** CIE 1976 L\*a\*b\* colour and ΔE76 (D65); Immerkær, J. (1996), "Fast Noise Variance Estimation", *Computer Vision and Image Understanding* 64(2); W3C, WCAG 2.1, Success Criterion 1.4.11 Non-text Contrast (<https://www.w3.org/TR/WCAG21/#non-text-contrast>).
