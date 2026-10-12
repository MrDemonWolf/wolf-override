# Audio map: SfxBank (apps/game/scripts/sfx_bank.gd, main at 76d3a50)

Read-only analysis. Measurements ran headless (Godot 4.7.2 editor binary, `--headless`, dummy audio driver) on a copy of apps/game in `scratchpad/lighter/audio/game/`, HOME=`scratchpad/home-lighter`, Apple M1 Pro. Scripts: `measure_sfx.gd`, `measure_rec.gd`, `measure_fmt.gd`, `measure_peak.gd`, `measure_parse.gd`; raw log `lighter/audio/measure.log`, `fmt.log`. Nothing was played by ear; no phone was measured.

## 1. What the bank holds

20 clips, all used by `scripts/main.gd` (47 `sfx_bank.play/stop` call sites, the only caller outside tests).

| Group | Clips | Rate | Built | Bytes in RAM (16-bit PCM) |
|---|---|---|---|---|
| Startup recipes (9) | boom 0.5 s, small_boom 0.3, clank 0.04, thud 0.08, hum 1.0 (loop), klaxon 0.5, servo 1.0 (loop), winch 1.0 (loop), whine 0.6 | 22.05 kHz | main thread in `_ready` | 221,382 |
| Detailed recipes (4) | relay_spark 0.34 s, records_arc 0.65, bolt_arc 0.8, growl_warning 1.2 | 44.1 kHz | WorkerThreadPool task queued in `_ready` | 263,718 |
| Recorded CC0 (7) | hiss_low/mid/high 6.0 s loops, coolant_cloud 8.0 s loop, vent_burst 2.4, growl_seam 0.9, growl_refusal 0.92 | 44.1 kHz | `preload` consts | 2,665,404 |
| **Total** | 20 | | | **3,150,504 (~3.0 MiB)** |

Players: 6 round-robin one-shot voices + 7 dedicated loop players (13 AudioStreamPlayer nodes, all on the Effects bus).

Use counts in main.gd: clank 10, servo 5, thud 3, klaxon 3, boom 3, every other clip once.

## 2. Measured cost

| What | Median (5 runs) | Notes |
|---|---|---|
| `SfxBank._ready` (main thread, what the game pays on boot) | **50.4 ms** (43.8-54.3) | 9 startup clips. Test comment says "near 30 ms"; it is ~50 ms now. |
| Detailed clips on the worker | **1,009 ms** (978-1,063) | One worker core busy ~1 s right after boot. |
| `generate()` single-threaded (tests/tools) | 1,061 ms | |
| Per clip, startup | boom 6.0, small_boom 3.6, clank 0.4, thud 0.8, hum 7.9, klaxon 5.8, servo 7.9, winch 7.1, whine 7.5 ms | about 7-8 ms per second of 22 kHz audio: the per-sample GDScript loop is the whole cost |
| Per clip, detailed | relay_spark 116, records_arc 211, bolt_arc 240, **growl_warning 424 ms** | one `_biquad` pass over 0.8 s @44.1 kHz = 5.3 ms; the growl runs ~30 such passes plus the glottal loop |
| Loading the 7 recorded .sample imports | 9.9 ms total (0.9-2.4 ms each) | uncompressed PCM; load is a memcpy |
| Compiling sfx_bank.gd (CACHE_MODE_IGNORE, editor build) | 38-68 ms | exports use tokenized GDScript, so less, but most of the 1,179 lines are DSP that runs once |
| Retained RAM per bank | +518 KiB static (generated buffers) | recorded clips are counted separately (2.6 MiB) |
| Transient RAM while rendering | not visible above the engine's init peak; estimate 2-4 MiB of PackedFloat32Array scratch (growl: 52,920 frames x 4 B = 207 KiB per buffer, ~15-20 live) | estimate, not measured |

Phone (unmeasured estimate): tight GDScript loops on a mid-range Android core are typically several times slower than an M1 Pro core, so expect very roughly 150-250 ms of first-frame hitch on the main thread and 3-5 s of worker CPU competing with the first scene's loading. Needs an export + device check before quoting.

Side effects of the current design:
- `_exit_tree()` calls `wait_for_detail()`: quitting or freeing Main inside the first ~1 s (phone: several s) blocks until the worker finishes.
- `play()` of a detailed clip before the worker finishes blocks the main thread (`wait_for_detail`). In the current route the first detailed clip is far from boot, so this is latent.
- Tests: main.tscn is instantiated 16 times across the suites (settings 4, chapter 2, m0_scene 2, eight suites x1). Each pays ~50 ms main + ~1 s worker and the exit wait, i.e. roughly 16 s of CPU per `scripts/check-game.sh` run spent re-rendering identical bytes (CI has a 5-minute timeout).

## 3. How the recorded CC0 files are imported

All seven: `.wav`, 1 ch, 44,100 Hz, Int16 (afinfo), imported with `compress/mode=0` (uncompressed PCM, `FORMAT_16_BITS`), `force/mono=false`, `force/max_rate=false`, `edit/normalize=false`. Loops use `edit/loop_mode=2` (forward) with `loop_end` = whole buffer (264,600 / 352,800 frames); one-shots `loop_mode=1` (disabled). Source files: coolant 706 KB, three pressure loops 529 KB each, vent 212 KB, growls 81 KB + 79 KB = 2.67 MB on disk, the same 2.67 MB in the .pck and in RAM.

`tests/sfx_bank_test.gd` `_check_recorded` asserts `FORMAT_16_BITS` and 44.1 kHz and computes the -6 dB peak by decoding s16 from `wav.data` (`SfxBank.peak_of`), so any switch to compressed import needs that test changed (check the peak on the source WAV at build time, assert format == QOA in game).

Godot 4.7's own default for new WAV imports is QOA (`compress/mode=2`); these were set to 0 on purpose.

## 4. Compression measured (same files, imported in the scratch copy)

| Set | PCM (now) | QOA (`compress/mode=2`) | IMA-ADPCM (`compress/mode=1`) |
|---|---|---|---|
| 7 recorded | 2,665,404 B | **539,432 B** (4.9x smaller) | 665,329 B |
| 13 generated, pre-rendered | 485,100 B (RAM only today) | **98,576 B** | 120,629 B |
| All 20 | 3,150,504 B | **638,008 B** | 787,708 B |
| Load time, all 20 | n/a (13 rendered) | 12.3 ms | 7.8 ms |

QOA keeps the format AudioStreamWAV already plays (pitch_scale and forward loops work), decodes cheaply per voice at mix time and stays compressed in RAM. Ogg Vorbis was not measured (Homebrew ffmpeg here lacks libvorbis); it would be smaller still but costs more decode CPU per voice, which matters with 3 hiss loops + hum + servo + coolant running together on a phone. QOA is lossy (~3.2 bits/sample): the arcs' transients and the hiss loops' highs need an ear check on phone speakers and headphones before switching.

## 5. Repetition in the generator code (lines in sfx_bank.gd)

1. **Startup recipe preamble, 9 copies.** `_boom`, `_clank`, `_thud`, `_hum`, `_klaxon`, `_servo`, `_winch`, `_whine` (and the boom twice) each open with `frames = int(seconds * MIX_RATE)`, `PackedFloat32Array.new + resize`, `dt = 1.0 / MIX_RATE`, `for i in frames: var t = i * dt` (212-347; ~5 lines x 8 = ~40 lines). `_zeros()` already exists but only the detailed recipes use it, and it is hard-wired to nothing rate-specific while `_smooth_noise`, `_comb`, `_n_wave`, `_coeffs` hard-wire DETAIL_RATE.
2. **One-pole low-pass, 6 copies.** `alpha = dt / (1.0 / (TAU * cutoff) + dt); low += alpha * (x - low)` in `_boom` (225), `_thud` (252), `_hum` (269), `_klaxon` (286), `_winch` (322), `_smooth_noise` (761).
3. **Raised-cosine edge fades, 2 copies.** `_arc_finish` 684-690 and `_growl_finish` 1005-1011 are the same loop with different lengths.
4. **Biquad loop, 3 copies.** `_biquad` (1104), `_swept_biquad` (1128) and `_swept_bandpass` (729) all run the same direct-form-I loop; `_swept_bandpass` also re-derives the RBJ band-pass coefficients that `_coeffs(BANDPASS)` already computes (b0 = alpha/(1+alpha), b2 = -b0). It is `_swept_biquad(input, BANDPASS, exponential_freqs, q)`; the arithmetic looks identical (needs the determinism check to confirm byte equality).
5. **Peak scan, 3 copies.** `_peak`, the inline loop in `_wav` (with the finite check), and `peak_of` (s16 version).
6. **Clip lists, 3 places.** `_render_startup` hand-writes `streams[&"x"] = _wav(_x(LENGTHS[&"x"]), loop)` 9 times; `_render_detail` 4 times; loop flags are restated beside `LOOPS`. Lengths live twice: `DETAILED` seconds duplicate `ARC_PLANS[...]["seconds"]` (0.34/0.65/0.8), and `tests/sfx_bank_test.gd` restates the recorded lengths in `RECORDED_SECONDS`.
7. **Call-site repetition in main.gd.** `_lane_sound` 2362-2369: four `play(&"servo", db, pitch)` branches on sentry state (a table of state -> [db, pitch]). Ten `clank` calls with ad-hoc db/pitch pairs.

All of 1-6 disappear from the shipped game if the recipes move to a build-time tool (section 6); if they stay at runtime, 1-5 still trim roughly 100-130 lines without changing output.

## 6. Options

### A. Pre-render to compressed files at build time (recommended)

- Move every recipe (lines ~179-1170, about 1,000 lines) out of the runtime script into a tool, e.g. `apps/game/tools/render_sfx.gd` (`extends SceneTree`, run headless) that writes `assets/audio/generated/<clip>.wav` with a `smpl`/import loop for hum/servo/winch and `.import` files at `compress/mode=2`. `AudioStreamWAV.save_to_wav()` works for this (used in the measurement). Keep the tool out of exports (an export filter, or a folder outside `res://` such as repo-level `scripts/`).
- Runtime `SfxBank` becomes: a `const CLIPS := {&"boom": preload(...), ...}` table plus the existing player pool, `play`, `play_blend`, `stop*`, `players()`: roughly 120-150 lines instead of 1,179. No worker task, no `wait_for_detail`, no `_exit_tree` wait, no `generation_ms`.
- Gains (measured on M1 Pro): about 50 ms off the main thread at boot, ~1 s of worker CPU per boot gone, ~40 ms less GDScript compile in the editor build, generated audio RAM 485 KB -> 99 KB, and with the recorded clips also on QOA total audio RAM 3.0 MiB -> 0.62 MiB and the .pck about 2.0 MB smaller (2.67 MB recorded -> 0.54 MB, +0.10 MB for the newly shipped generated clips). Test suites lose ~16 s of redundant rendering.
- Sync check: add a step to `scripts/check-game.sh` that renders into `$work/` (never into the tree; the script already fails if checks change files under apps/game) and compares against the committed WAV sources. Caution: the recipes call `sin`, `exp`, `tanh`, `pow` from the platform libm; macOS arm64 and the Linux x86_64 CI can differ in the last bit, which may flip an occasional 16-bit LSB. Either compare with a tolerance (max |diff| <= 2 LSB and identical length/loop flags) or store a hash of the recipe source + parameters next to the files and fail when the tool changes without a re-render. The existing determinism test (two renders in one process) only proves same-machine stability.
- Asset rules: the generated clips currently "ship as no file" (manifest entry for the procedural audio). Shipping them makes 13 new files under `assets/audio/`, each needing a manifest entry (or the register's per-file convention), and the procedural entry's text changes. Tests that call `generate()` and `_render_detail` move to the tool's check.
- Behaviour unchanged: same bytes (16-bit before QOA), same rates, same loop points, same player pool, so the UI and in-game sound stay the same except for QOA's lossy step, which needs a listen.

### B. Lazy generation (render on first play)

Not worth it. Every one of the 20 clips is used in the one shipped chapter, so lazy rendering saves almost no memory, and it moves the cost to the worst moment: `growl_warning` would hitch ~424 ms on the Mac (seconds on a phone) the first time WOLF growls, unless pre-warmed per room on a worker, which is the current design with more bookkeeping. The recorded files already load in ~1-2 ms each, so lazy *loading* is also irrelevant.

### C. Keep runtime generation, trim only

Factor the repeats in section 5 (shared `_render(seconds, rate, fn)` frame loop, `_one_pole`, `_edge_fades`, one biquad core, a clip table). Saves ~100-130 lines and nothing at runtime; startup stays ~50 ms + 1 s worker.

### Independent of A/B/C

- Switch the recorded CC0 imports to QOA (`compress/mode=2`): 2.67 MB -> 0.54 MB in RAM and .pck, after an ear check of the three crossfaded hiss loops (their shared length and wrap point are untouched by QOA; the test asserting equal `data.size()` still holds since all three QOA to 107,096 B).

## 7. Bug found while mapping

`main.gd:923` `sfx_bank.play(&"hiss", ...)` and `main.gd:1722` `sfx_bank.stop(&"hiss")` name a clip that no longer exists: the generated `hiss` loop was retired in fc172b3 (replaced by `hiss_low/mid/high`). `play()` returns null for unknown clips, so **the bypass vent (the engineer-only route through the junction's relay) has been silent apart from its klaxon since 2026-10-10**. No test covers it. The fix is to point it at a recorded loop (e.g. `hiss_mid` or `coolant_cloud`) via the loop player, then hear it in play; not done here (read-only task).

## 8. Files

- `/Users/nathanialhenniges/Developer/mrdemonwolf/wolf-override/apps/game/scripts/sfx_bank.gd` (bank, recipes, DSP)
- `/Users/nathanialhenniges/Developer/mrdemonwolf/wolf-override/apps/game/scripts/main.gd` (all 47 call sites; `_setup_impact` 653-656 builds the bank; `_lane_sound` 2360-2378; bypass vent 921-927, 1716-1722)
- `/Users/nathanialhenniges/Developer/mrdemonwolf/wolf-override/apps/game/tests/sfx_bank_test.gd` (timing budget 400 ms, lengths, -6 dB peaks, determinism, recorded format asserts)
- `/Users/nathanialhenniges/Developer/mrdemonwolf/wolf-override/apps/game/assets/audio/*.wav(.import)` (7 recorded, `compress/mode=0`)
- `/Users/nathanialhenniges/Developer/mrdemonwolf/wolf-override/apps/game/assets/manifest.json` (procedural entry ~line 560 says the generated clips "ship as no file"; recorded entries 569-629)
- `/Users/nathanialhenniges/Developer/mrdemonwolf/wolf-override/scripts/check-game.sh` (where a render-and-compare sync step would go; it already fails if checks modify apps/game)
- Measurement scripts and logs: `/private/tmp/claude-501/-Users-nathanialhenniges-Developer-mrdemonwolf-wolf-override/eb713cd4-8931-48d7-8c83-5b0b0d1e9cf3/scratchpad/lighter/audio/` (exported generated WAVs in `wav-out/`)

The r3 worktree does not touch sfx_bank.gd or assets/audio.
