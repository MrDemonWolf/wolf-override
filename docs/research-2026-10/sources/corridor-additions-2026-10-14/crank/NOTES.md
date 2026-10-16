# add7 / crank: the engineer's crank pose at the MANUAL BYPASS (item f)

Two Look 2 frames of the engineer turning the wall-mounted handwheel, built from the approved idle frame
(docs/research-2026-10/sources/walk-final-2026-10-11/engineer/eng-idle/frame_00.png):

- **A (frame_00):** the near glove is closed round the rim at 8 o'clock, with the arm reaching forward and down and the head dipped.
- **B (frame_01):** the push. The same rim point has turned one tick (45 degrees clockwise) to about half past 9; the elbow is tucked at the waist and the forearm is level.
- **Both frames:** the far glove is braced flat (back of the hand, fingers together) on the gearbox housing above the wheel. The legs are the approved idle's own pixels, so the boots never slide or boil between idle, A and B.

The checks were headless logic and render.sh stills. Nothing was played by hand, so this makes no claim about how it feels.

## Files (all in add7/crank/)

| File | What |
|---|---|
| deliver/sprites/eng-crank/frame_00.png, frame_01.png | A and B, 256x320 RGBA, the same cell, pivot (x 128) and feet row (lowest opaque row 313) as the approved idle and walk frames |
| deliver/sprites/eng-crank-atlas.png | **ship this one**: 304x308, A at x 0-151 and B at x 152-303 (cell window x 52-203, y 6-313, centred on the cell centre so a centred Sprite2D needs no offset) |
| deliver/sprites/eng-crank-sheet.png | A and B side by side (512x320) |
| deliver/eng-crank-contact.png | contact sheet: idle 00, walk 00/03/06/09, crank A, crank B at 1x on one baseline (cyan) and pivot tick (magenta) |
| deliver/crank-code.diff | the code change (main.gd, floor_reflection.gd) against real-slice/game-slice |
| qa/deliver-wheel.png/.json | each frame over the wheel at its exact in-game size and place; hand centroid to target rim point: A 2.1 cell px (0.5 world px), B 4.0 cell px (1.0 world px) |
| qa/finalize.json | cleanup numbers (colour fit, despill, alpha levels, legs identical to idle: max abs diff 0) |
| qa/ingame-before-after-720-3x.png | render.sh, 720p, before (game-slice) and after (game-crank): at wheel, A, B |
| qa/render-before-720/, render-after-720/, render-after-phone/ | render.sh stills plus a 72-frame sequence each, with crank.json (per-frame sprite record) |
| qa/headless/crank.json | the same record from `godot --headless` |
| qa/notes-check/ | 4x crops at the B quad's left edge (no atlas bleed from A's far glove) |
| tools/ | geometry.py (game numbers to cell px), build_guide*.py, run_codex.sh, register_crank.py, wheel_check.py, finalize_crank.py, contact_sheet.py |
| driver/crank_capture.gd | capture and check driver (route B to the bypass, hold USE, record every frame) |
| raw/ | the 5 Codex originals, byte-identical to ~/.codex/generated_images, each with its caBX (C2PA) chunk |
| game-crank/ | my private game copy with the change installed (not a repository) |

## Geometry (game-slice, unchanged by the door, plume and beacon tracks)

- Wheel hub at world (694, 400): main.gd BYPASS_WHEEL (700, 398) plus bypass_handle WHEEL_OFFSET (-6, 2). The rim tube centre has a radius of 9.375 world px.
- Each tick turns the wheel 45 degrees clockwise, tweened over 0.18 s. HoldUse.TICK_SECONDS is 0.4, and BYPASS_TICKS = 8 is exactly one full turn (3.2 s held).
- The engineer stands at BYPASS_CRANK_X = 674 with Human y 410, facing right; the floor top is y 440.
- Approved frames: 0.254 world px per cell px, so the 277 px figure is 70.4 world px tall, the same as the provisional sprite's 70.3.

## Integration (exact)

1. Copy `deliver/sprites/eng-crank-atlas.png` to `apps/game/assets/characters/eng-crank-atlas.png`.
   - Import with the defaults game-crank used: lossless (compress/mode 0), mipmaps on.
   - Import twice headless.
2. Apply `deliver/crank-code.diff`. It touches only these two scripts:
   - **main.gd**:
     - constants `CRANK_ART`, `CRANK_REGION_SIZE (152, 308)`, `CRANK_SCALE 0.254`, `CRANK_SPRITE_POS (0, -8.61)` (baseline row's bottom edge on y 440), `CRANK_PUSH_SECONDS 0.2`;
     - vars `crank_frame`, `crank_push_left`, `human_art`, `human_art_scale`, `human_reflection`, set in `_ready` after the floor reflections are attached;
     - `_update_crank_pose(delta)`, called each physics tick right after `hold_use.advance`;
     - `crank_push_left = CRANK_PUSH_SECONDS` on each bypass tick;
     - a reset in the attempt reset, which restores the usual sprite.
   - **floor_reflection.gd**: new `sync_art()`. It re-reads the source's texture and region and sets the shader's `uv_span`, so the reflection follows the swap.
3. The pose shows only with all of these:
   - chapter "lockdown", door not open;
   - `hold_use.holding` on station `&"bypass"`;
   - no authored step running (`engineer_step_x < 0`);
   - the engineer within 1 px of BYPASS_CRANK_X.

   Otherwise the usual sprite returns: texture, `region_enabled = false`, scale 0.188, position (0, -5).
4. Add an asset-register entry to apps/game/assets/manifest.json (draft below).

No new nodes, no new draw calls: the engineer's Sprite2D and their floor reflection swap texture and region. Texture memory goes up by about 0.5 MB (304x308 RGBA plus mips), well inside the 2 MB budget. The change adds no additive items, no particles and no gameplay or timing changes.

The beacons diff edits room_depth.gd and main.tscn. The door snippet edits `_setup_corridor_door` and `_sync_door`. The plume patch edits bypass_handle.gd and fx_presets.gd. None of them touch the lines above, so the four apply in any order.

### Timing

- Holding USE: A shows from the first frame of the hold.
- Each tick (every 0.4 s): B for 0.2 s, while the wheel turns its 0.18 s eighth, then A (the regrip) for the remaining 0.2 s.
- Per wheel turn that is 8 push/regrip cycles, 16 frame changes, or 2.5 cycles a second.
- On release, at the eighth tick or on reset, the usual sprite returns at once.

These are verified per frame in qa/render-after-720/crank.json:

- B appears with the wheel at 11.4 degrees and holds through 45;
- A returns at seq-37;
- the sprite bottom is at world 440.51 in both frames, against 441.10 for the provisional sprite;
- the reflection's texture and region match the sprite in every frame.

### Draft manifest entry

```
{ "asset_id": "eng-crank-atlas",
  "path": "apps/game/assets/characters/eng-crank-atlas.png",
  "source_or_tool": "Codex built-in image_gen, edit mode (session 01a13361-7b84-7151-8d8e-76e9a12b9f12, 2026-10-12), on a pose guide built from the approved walk-final engineer idle frame_00; cleaned up with Python (Pillow, numpy, scipy)",
  "source_reference": "docs/research-2026-10/sources/walk-final-2026-10-11/engineer/eng-idle/frame_00.png (approved 2026-10-11)",
  "terms_reference": "https://openai.com/policies/terms-of-use/",
  "rights_review_status": "Provisional AI-assisted character art, human review pending. Final commercial asset-rights review open; not covered by the code/docs GPL license.",
  "modifications": "Two-frame crank pose. Colour mapped back onto the idle's palette; legs (rows 218-319) are the idle's own pixels; far glove registered between frames; magenta despill; exact alpha. Packed as a 304x308 two-region atlas. Derived crop, so it carries no C2PA; the original (with C2PA) is kept in the art-source record.",
  "implementation_status": "Shown only while USE is held at the MANUAL BYPASS. Not yet seen in motion by hand." }
```

## Checks run (on game-crank, HOME=scratchpad/home-realslice)

- Two headless imports.
- Headless tests pass: m0_scene_test, m0_state_test, hold_use_test, follow_spacing_test, room_depth_test (logs/test-*.log).
- Headless crank record (qa/headless/crank.json).
- render.sh before (game-slice) and after (game-crank) at 1280x720, and after at 2400x1080 (phone shape).
- Same per-frame record in both shapes: 47 A, 24 B and 3 usual-sprite frames in phone shape, with the release back to the provisional sprite.
- No atlas bleed at B's left edge (qa/notes-check/edge-compare-4x.png).

## Provenance (also in real-slice/add7/provenance.txt)

All five ran Codex's built-in image_gen in edit mode, from add7/codex/crank-<job>/, through tools/run_codex.sh. The prompt said to keep all metadata including C2PA. All five sessions are archived: 0 live, 5 in ~/.codex/archived_sessions (logs/*.archive.txt).

| Job | Session | Use |
|---|---|---|
| crank-1a | 01a1335b-97d0-7c73-8e3f-7a231ef3a513 | Round 1, full repaint of the guide. Kept identity, legs and A's arm. Both far hands came out as a wave (spread palm), and B's fist stopped 10 px short of the rim. Basis of the round-2 guide. |
| crank-1b | 01a1335b-97d0-7110-b5b2-48ccab499e15 | Round 1, not used |
| crank-2a | 01a13361-7b82-74c1-8b25-7a40ce10662c | Round 2, a local fix of only the far hands and B's forearm. Not used. |
| crank-2b | 01a13361-7b7d-7231-a8b6-cc69df739ac8 | Round 2, not used |
| crank-2c | 01a13361-7b84-7151-8d8e-76e9a12b9f12 | **Delivered**. Best far-glove brace and hand-on-rim fit. |

The delivered frames are derived crops (tools/register_crank.py, tools/finalize_crank.py) and carry no C2PA. The originals in raw/ keep it.

## Open issues

1. **Style jump in today's game (the big one).** Main still draws the engineer from the single provisional 3/4-view sprite (rowan-side-right-provisional.png). The approved walk-final frames are not in the game yet. The crank frames match the approved frames (strict profile, lighter detailed trousers, rim-lit hair), so on main the engineer visibly changes art style when the crank starts and changes back on release (qa/ingame-before-after-720-3x.png). At 1x it reads as a pose change, but at 3x it is plainly a different drawing. **Recommendation:** land the crank pose together with, or after, the approved idle, walk and jog frames, so the engineer is that drawing everywhere. Landing it alone gives a pop at the bypass.
2. **No weight shift in the legs.** To guarantee no foot slide, the legs are the idle's exact pixels in both frames. The lean, dipped head and pushing shoulder carry the effort, but the hips and knees do not shift onto the front foot as the brief asked. A real weight shift needs a second leg pose plus a sole-slide check.
3. **One push, not a continuous turn.** The hand jumps to the end of the push when B appears, while the wheel is still tweening its 0.18 s eighth (at most about 1 world px of hand-to-rim gap for those frames). A third in-between frame would smooth it, but it was not made.
4. **The far hand on the housing.** It is the far arm, braced on the gearbox housing above the wheel. In stills it reads as a hand on the machine, but a reviewer should confirm it does not read as a raised arm at phone size.
5. The old coolant-hiss disc (item g) still sits beside the engineer in these captures. The plume track's patch replaces it with a jet from the relay's relief valve at world (649.6, 361), pointing down and away from the crank spot. The two have not been rendered together.
Nothing in this track touched game-slice, game-main, the shared real-slice folders or any repository; game-add was not used.
