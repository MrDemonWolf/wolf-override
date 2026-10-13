# Shutter door layers (October 11, 2026; on hold)

After Nathanial approved the round-4 shutter across the corridor on October 11 ([`../doors-shutter-approved/`](../doors-shutter-approved/), review page [`../../notes/review-pages/2026-10-11-shutter-door-round-4.md`](../../notes/review-pages/2026-10-11-shutter-door-round-4.md)), a Claude agent measured every door in the game and a Codex agent painted the shutter as game-ready layers for each portal: the corridor seal, the Records exit, the junction blast door and the junction exit and entry hatches. An independent Claude reviewer then checked the paste-up composites, and the layers were redone as version 2.

**Status: on hold, never integrated.** The same evening Nathanial judged that the doors, the opening hatch and the rooms read as AI-made, and all door art went on hold until it is redone design first, then paint (`../../art-direction/REAL-LOOK.md`; "Look real, not AI-made" in [`../../README.md`](../../README.md)). Nothing here is in the game. The work is kept because the measurements, the blocking faces and the review findings still apply to any new door.

## Decisions recorded here

- **Review item 3 (the space through the portal is not the space you walk into):** Nathanial chose option (a) for the corridor (the strip right of the portal is repainted as the same machinery room as the space beyond) and option (b) for the junction (the junction blast gap shows the real pipe bay until the junction rebuild). See `LAYERS.md`, "What changed in v2", and `provenance.txt`. The same decision is summarised under "Art" in the research README.
- The review's verdict was "fix needed": three of five shut portals could be walked through, and the corridor leaf read as an invisible wall. Version 2 fixed the art items; the blocking faces and the label nudge were left as code for the integration step.

## Files

- `MEASURE.md`: door, seal, hatch and gate measurements on main at 76d3a50 (world and camera facts, hitboxes, render boxes, the layers each shutter needs), from scripted Godot captures and code reading. The captures and their annotated crops are not kept.
- `LAYERS.md`: the version-2 layer plan: density, anchors, draw order, proposed blocking faces, measured geometry, lamps, per-door layer tables, plate patches, art-bible QA results, known limits and the delete list for integration.
- `REVIEW.md`: the independent review of the version-1 composites (what passes, four required and five smaller fixes).
- `provenance.txt`: Codex session id, job and output SHA-256 for every image job, and which outputs were used or superseded.
- `codex-prompts/<job>/prompt.txt`: the brief sent to Codex for each of the 21 jobs (verbatim, personal paths scrubbed).
- `codex-prompts/<job>/notes.txt`: Codex's own record per job: the exact image-tool prompts, the original generated file id in the Codex generated-images store, SHA-256, pixel size, and its self-check and limits.
- `composites-sheet.webp`: the version-2 contact sheet of every door state pasted over door-free Godot captures (WebP quality 80 of the 3.2 MB PNG). It is a paste-up, not a game render.
- `measurements/clean-report.json`, `measurements/seam-report.json`: the matte-cleanup and plate-seam measurements of the version-2 layers.

Paths inside these files such as `tools/`, `driver/`, `work/`, `review/py/chunks.py`, `bgcap*/`, `composites/<door>-NN-<state>.png` and `manifest-draft.json` refer to the session scratch and were not kept: they are one-run build and capture scripts, intermediate layers, raw captures and a draft manifest. The 33 generated originals (about 127 MB with their intermediates) were not copied, because the art is on hold and over the size budget; their SHA-256 values are in `provenance.txt` and the `notes.txt` files, and the originals stay in the Codex generated-images store under the listed session and file ids.

The design files here are kept as written on October 11. Where they call the engineer "he", read "they": since October 12 the engineer is non-binary and uses they/them. WOLF is he/his.

## Credits

- Game, story and the decisions above: Nathanial Henniges.
- Measurements, layer plan, composites and review: Claude (Claude Code) agents working for Nathanial, using Godot 4.7.2 for the captures and Python (Pillow) for the paste-ups and measurements.
- Shutter, beyond, lamp, debris and plate-patch art: generated with Codex's built-in image tool (`image_gen`, edit mode, one `codex exec` session per job, no API). Each original kept its C2PA content credential (`caBX` chunk), as checked at the time; the C2PA records live in those originals, not in the WebP sheet here.
- No third-party material is used. The approved shutter concept's references (*Inside* and *Limbo*, Playdead, 2016 and 2010) were named as look references only.
