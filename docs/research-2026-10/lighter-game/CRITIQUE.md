# Critique of PLAN.md (lighter, componentized game)

Read-only review against `map-main.md`, `map-rooms.md`, `map-ui.md`, `map-audio.md`, `map-perf.md` and `map-assets.md`, and Nathanial's two asks. Facts were checked against the repo at 76d3a50 and, read-only, against the uncommitted wt-r3 tree. Size estimates were made with `cwebp -lossless -z 6` in `lighter/critic/`. Nothing was played and nothing was imported into Godot.

**Verdict.** The plan is sound in shape: shims, parity gates, VISUAL and BEHAVIOUR labels, and asset swaps that overwrite files in place. It should not start as written. It has three factual errors that would break tests or invalidate the baselines, and it does not cover the assets that round 3 adds. On the two asks, it leaves several old assets in the game with no route to removal. Its size claim is also not met by its mandatory steps.

---

## A. Blocking corrections

1. **Round 3 adds a new door and new art that the plan does not know about.** The wt-r3 tree is uncommitted and touches 4 scripts. It also adds 6 untracked files:
   - `scripts/opening_hatch.gd`
   - `assets/props/opening-hatch-{frame,leaf,duct}.png`
   - `art-source/opening/opening-hatch-{closed,open}.png`

   That is a fifth door or hatch implementation, the same leaf-in-a-clipped-doorway mechanism as SealLeaf and HatchDoorway. It is also more old-style art that ask 2 has to cover.
   **Amend:** add an **S00a** after r3 merges. It re-runs the asset map and the main map (line counts, shim list, fnranges) on the merged commit. It adds `opening_hatch.gd` to the Shutter "Replaces" list and to the S16 split (see D). It puts the 3 opening-hatch images and 2 masters into the S23 hatch deletion list, or records them as kept, with a reason Nathanial approves.
2. **The baselines are pinned to the wrong commit.** Section 5.2 diffs against `ui-parity/baseline-76d3a50.txt`, and section 4 uses the 76d3a50 perf numbers as "before". Round 3 changes junction staging, the hatch and the textures, so every junction capture, the UI dump and the perf "before" must come from the **post-r3 merge commit**.
   **Amend:** S00 re-records the UI dump, the pixel baselines and the perf "before" on the post-r3 commit. Delete the reference to `baseline-76d3a50.txt`.
3. **S07 cannot "derive the Vector4 consts from the data".** `follow_spacing_test` reads `Main.CORRIDOR_STATIONS`, `RECORDS_STATIONS` and `JUNCTION_STATIONS` as class constants, and GDScript `const` cannot be computed from RefCounted Station objects.
   **Amend:** make the direction the other way round. The const Vector4 tables, plus one new const `*_SPAN_HALF_WIDTHS`, stay the single source, and `Station` records are built from them at load. The test contract is unchanged.
4. **The constant contract is incomplete.** Section 5.1 lists 11 constants. The tests actually read 15 from main: the 11, plus `GAMEPLAY_ZOOM`, `GAMEPLAY_CAMERA_Y_TOUCH` (room_depth_test 33), `VALVE_CRANK_X` (junction_test 283) and `BOLT_WHINE_SECONDS` (sfx_bank_test 57).
   **Amend:** list all 15. S15 must keep `VALVE_CRANK_X` and `BOLT_WHINE_SECONDS` on main, as consts or `const X = JunctionBeats.X`.
5. **S04 would delete constants that gameplay and tests use.**
   - `main.gd` 2333 times the bolt crack with `SfxBank.BOLT_CRACK_SECONDS`.
   - Main also uses `SfxBank.HISS_GAUGE` and `SfxBank.LOOPS`.
   - The tests read `BUS`, `LENGTHS`, `DETAILED`, `RECORDED`, `MIX_RATE`, `DETAIL_RATE`, `ARC_PLANS` and `RING_SEND`.

   **Amend:** the runtime SfxBank keeps `BUS`, `LOOPS`, `HISS_GAUGE`, `BOLT_CRACK_SECONDS`, `LENGTHS` and `DETAILED` (names and seconds only). The render tool reads `BOLT_CRACK_SECONDS` from SfxBank, so the value lives in one place. The `ARC_PLANS` assertions move to the tool's check.
6. **S04 import defaults are lossy.** Godot 4.7 imports new WAVs as QOA by default (`compress/mode=2`). Unless all 13 new `.import` files are committed with `compress/mode=0`, a loop mode and loop begin/end, check-game.sh would create default imports, and the sound would change silently while still being labelled "IDENTICAL".
   **Amend:**
   - Commit the 13 `.import` files.
   - Extend `sfx_bank_test._check_recorded` to all 20 clips: `FORMAT_16_BITS`, rate and loop flags.
   - Add a one-time in-engine check before the recipes are deleted: imported `AudioStreamWAV.data` equals the output of today's `generate()`, within 2 LSB.

## B. Duplication found in the maps but not planned away

| Source | Duplicate | Amendment |
|---|---|---|
| rooms 2.10 | Particle placement (preset, rect emission, extents, overrides, z 3, add_child): about 90 lines in the junction and about 20 in main | Add `FxPresets.place(...)` and a per-room particle table to S03 or S12 |
| rooms 2.11 | Pipe and conduit drawing: `_draw_bolt_feed`, the bypass pipe and post, the arm rods | One `FxKit.draw_conduit()` helper in S12 |
| rooms 2.11 | x-velocity mover in both `M0Actor._approach` and `Sentry._physics_process` | Make it a static `M0Actor.approach()` that Sentry calls (S05) |
| rooms 1 | `M0State` literal bounds 40/920 repeat `M0Actor.MIN_X`/`MAX_X` | Reference the constants. Values are unchanged, so saves still validate (S05) |
| rooms 2.7 | Vent tested twice (Area2D and `is_on_vent`); hazard band drawing ×3 | S17 is optional, so give it a fallback: if HazardZone does not ship, still take the band-drawing helper and one shared vent span const |
| rooms 5.2 | FloorReflection re-mirrors **static** props every frame even in the active room | Mirror once, and refresh only on a visibility, frame or tween change (S02) |
| ui D8/D9 | `TOP_CARD_ACCENT` duplicates the tscn accent; 6 copies of `touch_enabled and not controller_active` | Add `_touch_layout()` to S05; take the accent from the node |
| ui 4 | `pause_overlay` calls `get_node_or_null` on every input event; `UIMotion._scale_to` creates a tween when there is no change | Add both to S01 (perf, no visual change) |
| audio 6 | `sfx_bank_test.RECORDED_SECONDS` restates the clip lengths | The test reads them from the CLIPS table |
| r3 | `opening_hatch.gd` | Fold into Shutter (A1) |
| plan itself | About 70 one-line shims on main, plus aliases on JunctionRoom and Shutter, are themselves duplicate surface | Add **S26 shim retirement**: move the in-repo tests to the component APIs and delete the shims, keeping only the names the out-of-tree capture scripts still need, listed. Without it, main stays at about 900 lines, not 700 |
| rooms 2.11 / S15 | HoldUse and PressureLine accumulators | Already conditional. Record the decision either way in the S15 PR |

## C. Changes that could slip past the gates

1. **S02 dirty-flag redraws can freeze animation.** The junction `_draw` animates from mirrored values that change every frame: `gauge`, `display_gauge`, `fuse_remaining` (the blast-stripe pulse), `tank_drop` (arm rods and cable) and `bolt_charge` (bolt feed). `sync_bolt` redraws on every call today.
   **Amend:**
   - The dirty check compares every value `_draw` and `Recesses._draw` read, listed in the PR.
   - Add a headless test that, during build, fuse, drop and charge, checks that consecutive `_draw` calls see changing inputs.
   - Parity for S02 compares **frame sequences** (for example 30 consecutive frames through the fuse and the drop), not stills.
2. **S02 particles in hidden rooms that "stop emitting"** start cold when the room is re-entered (no plume yet).
   **Amend:** restart with `restart()` and `preprocess` as today, or name it as VISUAL.
3. **The effects-on threshold is too loose.** "≤ 0.1% of pixels at fuzz 3%" is about 518 px at 960x540. A 1 px shift of a station plate, or a slightly different shared glow gradient (S03), passes.
   **Amend:**
   - Use fixed particle seeds, or hide particles in parity mode.
   - Then require AE = 0 on the effects-on frames too, masking only the particle rects that cannot be seeded.
   - The fuzz should never be above 0 for S03.
4. **S03 shares Resources.** If any caller writes to its gradient or material (tint, `blend_mode`, `light_mode`), every instance changes.
   **Amend:** S03 includes a grep or test proving that no shared FxKit resource is written after creation. Callers tint through `modulate`.
5. **Text drift.** The grep of string literals does not catch strings built from tables or format calls.
   **Amend:** the parity driver logs every distinct `status_line`, `_context_hint()`, `_objective()`, top-card key and choice label per frame across R2-R4, and the log must diff empty on every IDENTICAL step.
6. **Controller layout is not in parity.** The HUD prompts change with `controller_active`, and S05 and S08 cache prompts per device.
   **Amend:**
   - Add controller-mode captures to R1-R4.
   - Add a scripted sequence that rebinds USE, returns to play and checks the hint, then switches keyboard → controller → touch mid-play and checks the prompts update.
7. **Resizes are not covered.** The Hud view model is applied only on change, so a window resize or phone rotation with nothing else changing would leave stale layout.
   **Amend:** add a resize mid-play and a resize while a choice is up to R2.
8. **Pause can change tween timing.** Moving tweens into components (S08-S11) can change their pause mode.
   **Amend:** pause during the top-card tween, the chapter-close tween and the knockdown tilt, wait 1 s, and capture. The frames must match the unpaused moment.
9. **Saves and settings compatibility are not tested.** RunFlags, BeatSaver and the move of the video settings (S06, S09, S11) can change save or settings keys, or fresh-profile defaults (fps 60, V-Sync on).
   **Amend:** commit fixture `save` and `settings` files written by the post-r3 commit, one per checkpoint. A test must load each, and fresh-profile defaults must match.
10. **S12 PlateFader timing.** Four `_process` faders become one node, which can fade one frame after the camera moves.
    **Amend:** pin PlateFader's `process_priority` and tree position so it runs where the old faders did, and add one frame-sliced capture during a camera pan.
11. **S18 lazy residency has unhandled cases.**
    - (a) `load_threaded_get` on a path that was never requested errors; it does not block. Fall back to `load()`.
    - (b) Some art is shared across rooms: `junction-valve` and the bypass wheel are corridor art, `corridor-breaker` is used by the junction, and `corridor-bulkhead-open` is the junction hatch passage. Room sets must include these.
    - (c) A PropSpec table that `preload`s its files keeps everything resident, which defeats S18. PropSpec must hold **paths**.
    - (d) A pop or a black frame on room entry or on return to the title is not caught by settled stills. Capture the first 5 frames after each entry.
12. **S19 hides a code behaviour change inside an art step.** It unifies the drifted span half-widths (WOLF rest spots move up to 1 px).
    **Amend:** move that into its own BEHAVIOUR step **before** S19, so it is reviewed without new art around it.
13. **The parity harness can record frozen frames.** The perf map shows that an occluding `--always-on-top` window froze drawing.
    **Amend:** the capture driver asserts `Engine.get_frames_drawn()` advanced, and that the draw-call monitor is not stuck, before each capture. Otherwise it retries or renders through a SubViewport.

## D. Steps too big to verify one at a time

Each split below is one PR with one parity run:

| Step | Split |
|---|---|
| S03 | S03a Palette (pure constant substitution) · S03b FxKit cache · S03c Tweens helper |
| S05 | S05a M0State `first_name` and `relay_outcome`, `_touch_layout` · S05b `Impact.cue` · S05c ActorSprite pose helpers · S05d Choice record · S05e text tables |
| S09 | S09a TitleScreen and TitleOverlay · S09b PauseOverlay · S09c video settings into GameSettings (with the C9 fixtures) |
| S10 | S10a CardPanel · S10b EndCard scenes · S10c theme variations and dead-override removal · S10d `settings_menu.tscn` and `settings_theme.tres`, the riskiest because of theme lookup order |
| S12 | S12a NamePlate and PlateFader · S12b StatusLamp (ColorRect-compatible) · S12c Room base and utility-library move |
| S16 | S16a corridor seal (SealLeaf) · S16b junction blast door · S16c junction hatches, opening hatch and Records exit |
| S19 | S19a corridor stations, plus the junction breaker that shares the file · S19b Records and the purge dedupe · S19c valve, wheel, needle and bypass wheel (removes `WHEEL_MASK`) · S19d tank and arm re-hang · S19e relief vent · S19f lamp sprites |
| S21 | S21a sheets and ActorSprite at today's 190 px/s · S21b walk 80 then jog 190 (BEHAVIOUR). This keeps the art review apart from the timing re-baseline |

**Gate list.** The plan lists S11-S16, S21 and S23 as waiting on r3, but S02 (`junction_room` sync), S03 (`soft_texture`), S07 (`JUNCTION_STATIONS`), S08 (`_junction_hint`), S19 and S20 also touch junction code. S00 is already gated on r3, so state simply that **every step starts after r3 merges**.

## E. Ask 2: old assets left behind, and approved assets not used

**Old assets with no route to removal in the plan:**
1. **Title key art and its published copies.**
   - `title-corridor-key-art-provisional.png` was painted from the old `rowan`/`wolf` provisional sprites, according to its manifest `source_reference`.
   - Its published copies are `apps/docs/public/title-corridor-key-art-provisional-{640,1024,1672}.webp` and `share-card.jpg`.

   The plan lists it as "kept unchanged". After S21 and S22, the title shows the old characters and the old door look.
   **Amend:** add S24a, "title key art": a decision for Nathanial (re-paint from the new sprites and doors, or keep it with a stated reason). If replaced, the 4 published copies are regenerated as well.
2. **Hatches.** Both hatches (`junction-hatch`, `records-exit-hatch`) and the r3 opening-hatch art depend on hatch art that **no approved set contains**. The approved shutter concepts are also 4 concept scenes, not layers. The plan has a "Draw first" table but no step, owner or review gate.
   **Amend:** add art steps:
   - A1: corridor and junction shutter layers from `doors-shutter-approved/`.
   - A2: hatch family (junction entry and exit, opening hatch, Records exit).
   - Each has a D=4 density check and Nathanial's approval before S22 or S23.

   S24 must end with an "old assets remaining" table that is either empty or lists each item with Nathanial's sign-off.
3. **Site captures.** Each has several published sizes: corridor-start 480/960/1600, title 480/960, junction-entry 480/960. S24 must regenerate every size and update the dated `asset_id`s.
4. **Manifest convention.** The register does not just delete retired entries. The successor entry's `source_reference` names what was "retired YYYY-MM-DD and kept in the Git history", as with corridor-mid and the 2026-10-10 entries.
   **Amend:** the swap rules follow that convention instead of plain deletion, and the top-level `status` paragraph is rewritten in the same PR as each phase, not only at S24.
5. **Local leftovers.** Stale `.godot/imported` entries (8.6 MB) should be cleared with a clean reimport after S24, which is local only. Add a one-line `SUPERSEDED` note to `look2-hq/doors/notes.md` rather than deleting research provenance (ask Nathanial first).

**Approved assets the plan leaves unused.** Each needs a recorded decision, not silence:
- `look2-hq/props/corridor-purge-display.png` and `status-lamp-purge-display.png` or `-purge-queue.png` are dropped by the purge dedupe. Name the source file the shared `purge-console.png` is made from (records-purge-queue at 480²), and note in the manifest that the corridor render was approved but not imported because it is the same render.
- `sentry-scanning.png`: SentryBrain already has chase and fixated states it could show. Make it a decision in S20, not a footnote.
- `director-stand-left.png` and `director-turn-away.png`: decide together. turn-away may suit the intro exit.
- `junction-valve-gauge.png`: either import it, or state that the body's painted face replaces it once `_draw_gauge` goes.
- Pickups (6), the identity-reference poses and `death-poses/` stay unimported, which is correct. List them in S24's table as "approved, no consumer yet".

## F. Perf claims: can they be measured?

Mostly yes. Section 4 names the drivers. Gaps:
1. **The download does not get lighter on the mandatory path.** Lossless WebP estimates:

   | Change | Size |
   |---|---|
   | Walk3 sheets add | about 3.45 MB (engineer 1.06, WOLF 2.39) |
   | Old characters removed | about 0.22 MB |
   | New stations, lamps and sentry | about 1.03 MB, against 3.77 MB for the old stations and sentry, so about −2.75 MB |
   | Pre-rendered PCM (S04) | about +0.49 MB |

   The net is about +1.0 MB on the 24.96 MB pack before the doors, so roughly flat or heavier. Only the optional S25a (QOA, −2.0 MB) and S25b (font subsets, −1.1 MB) make it lighter.
   **Amend:** state this in section 4. Put the 8-frame-cycle and trimmed-atlas decisions **before** S21. Ask Nathanial whether QOA and font subsets become part of "lighter" rather than optional.
2. **Phone claims cannot be measured as planned.** There is no `export_presets.cfg`, no Android template (only `ios.zip`) and no device step.
   **Amend:** add S00b: a throwaway Android or iOS preset outside the repo, and one baseline run on a device. Without it, section 4 must not list phone gains.
3. **No per-step regression budget.** The RoomBeats indirection, view-model compares and PlateFader add work.
   **Amend:**
   - Every step records `_refresh_ui` µs, junction `_draw` µs, script `_process` ms, `load(main.tscn)` ms and `RENDER_TEXTURE_MEM_USED` on the same quiet run.
   - A step fails if p50 script time or load time regresses by more than 5% against the previous step.
   - The `_refresh_ui` figures were measured headless; measure them again in a window.
4. **VRAM "45-55 MB after the swap"** depends on S18 holding only the current and next room, and on the sheet-format decision. Report it per state from `static_textures.csv`, not as one number.
5. **Add `check-game.sh` wall time** as a metric. S04 should cut about 16 s of repeated rendering, which the CI 5-minute timeout benefits from.
6. **Frame pacing.** The largest "feels faster" lever is the fps cap (S25c). It was measured only on a 120 Hz Mac. Keep it a decision, and add a 60 Hz display run to the S25c PR.

## G. Smaller fixes

- S04b wording: the vent with no hiss is the **corridor** manual bypass (main.gd 923, 1722), on the disclose-plus-bypass route, not a junction route.
- S10b and the TitleOverlay instance rename paths. Keep them optional as written.
- Hands-on play: the plan asks for it only after phases 3 and 4. Add a short played corridor run after S04b (hiss), S21b (walk and jog feel) and each VISUAL swap PR, per AGENTS.md.
