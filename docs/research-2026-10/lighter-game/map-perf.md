# Performance baseline: main at 76d3a50 (the "before" figures for the lighter pass)

Measured 2026-10-11, 16:24 to 16:58 CDT, on an Apple M1 Pro (10 CPU cores, 16 GB) with a 1920x1080 display at 120 Hz. Godot 4.7.2.stable.official.ed1daf0bf, GL Compatibility running on Metal ("OpenGL API 4.1 Metal - 91.7"). These are scripted runs in a real window: no hands-on play, no device or phone tests, and no full binary export.

## Headline numbers

| What | Baseline | How it was measured |
|---|---|---|
| Launch to title first frame | **1.72 s** median (1.40 to 2.98 s, 6 runs) | Shell epoch time at launch, then epoch time at the first `frame_post_draw` after `main.tscn` was added |
| ...of which engine boot (process start, window, GL) | 1.08 s median | Launch to the driver's `_initialize` |
| ...of which `load("res://scenes/main.tscn")` | **441 ms** median (426 to 493) | `Time.get_ticks_usec` around `load()` |
| ...of which instantiate / add_child + `_ready` / first draw | 3.5 / 53 / 110 ms | Same |
| Title fully revealed (logo tween done) | 1.38 s after the load started | Polled `title_logo.modulate.a` |
| Detailed procedural sounds ready (worker thread) | 1.16 s after the load started | `WorkerThreadPool.is_task_completed` |
| Frame at the shipping default (60 FPS cap + V-Sync) | **42 to 46 FPS**, avg 21.6 to 23.7 ms, p99 up to 30 ms | Per-frame wall time, 10 s per state, median of 3 runs |
| Raw frame cost (cap and V-Sync off), 1280x720 | worst state avg **4.72 ms**, p99 **9.16 ms** (212 to 253 FPS) | Same, 3 runs |
| Same, 960x540 window | worst avg 4.94 ms, p99 9.60 ms | 1 run |
| Main-thread work per frame, worst state | script `_process` 0.32 ms + physics 0.08 ms + render CPU 0.81 ms, so about **1.2 ms** | Timer nodes at process priority -1000 and +1000; `viewport_get_measured_render_time_cpu` |
| CPU, whole process | **12 to 16 % of a core** at the default; 23 to 32 % V-Sync only; 38 to 49 % uncapped | `ps` cputime deltas every 0.5 s |
| Godot static memory | 51.4 MB (title) to 52.5 MB (lane) | `Performance.MEMORY_STATIC` |
| Godot video memory | **77.1 to 78.0 MB** (texture 70.8 to 71.6, buffers 6.3); 84 to 85 MB at 1920x1080 | `RENDER_VIDEO_MEM_USED`, `RENDER_TEXTURE_MEM_USED` |
| Process GPU-side memory (macOS) | about **105 MB** (IOAccelerator 75 + unmapped graphics 12 + IOSurface 18); about 134 MB at 1920x1080 | `footprint -p` every 2 s |
| Process physical footprint | **286 to 309 MB** at 1280x720; 342 MB at 1920x1080 | `footprint -p` (RSS swings 100 to 355 MB under memory compression, so footprint is the steadier figure) |
| Draw calls per frame | **55** (Records) to **114** (sentry lane); title 88 | `RENDER_TOTAL_DRAW_CALLS_IN_FRAME` |
| Nodes in the tree | **439** in every state (387 under Main) | `OBJECT_NODE_COUNT`, plus a tree walk |
| Objects 2,954 · resources 116 · orphan nodes 0 | at the title | `Performance` object monitors |
| Desktop pack (.pck) | **24.96 MB** (23.79 MB of files; 17.1 MB gzipped) | `godot --export-pack` with throwaway Linux, Windows and macOS presets (all identical, S3TC); iOS pack 24.96 MB with ETC2 |
| Imported data (`.godot/imported`) | 35 MB on disk (33.9 MB of files: 10.5 MB S3TC + 10.5 MB ETC2 + 9.7 MB lossless WebP + 2.5 MB audio + 0.6 MB fonts) | `du`, then a per-file breakdown |

### Compared with the earlier figures

| | Earlier | Now (main 76d3a50) | Note |
|---|---|---|---|
| Worst avg frame | 2.4 ms | 4.72 ms uncapped at 1280x720 (4.94 ms at 960x540) | The machine was busy (load average 7 to 13 during clean runs, other agents' Godot, ffmpeg and Python). Main-thread work is only about 1.2 ms, so most of the uncapped frame is GPU, driver and swap time. Don't read this as a regression without a rerun on a quiet machine. |
| p99 | 4.2 ms | 9.16 ms uncapped | Same caveat |
| CPU | 13 to 19 % of a core | 12 to 16 % at the default (60 cap) | Matches |
| RSS | 200 to 290 MB | RSS 100 to 355 MB (median 140 to 264); footprint 286 to 309 MB | Matches; footprint is the steadier figure |
| VRAM | about 100 MB | about 105 MB process GPU-side; Godot's own count 77 to 78 MB | Matches |

## What the numbers say for the lighter pass

1. **The shipping frame limiter costs more smoothness than anything in the content.** The default `fps_limit` of 60 (main.gd:1183) plus V-Sync on a 120 Hz display gives 42 to 46 FPS, with frames clustered at 20 to 22 ms and 24 to 26 ms and none at 16.7 ms. The earlier audit's empty-scene control saw the same thing with the same settings (49 FPS). With the cap off and V-Sync on, the same route holds a steady 120 FPS (8.35 ms, p99 about 12 ms) at 24 to 32 % CPU. This is a settings default, not code duplication, but it is the biggest "feels faster" lever measured. It needs confirming on a 60 Hz display and on a phone before anything changes.
2. **Main-thread CPU is already small**, about 1.2 ms per frame at worst: script `_process` 0.11 to 0.35 ms, physics 0.01 to 0.08 ms, render CPU 0.41 to 0.82 ms. Merging duplicate code will mostly make the game **smaller and faster to load**, not faster per frame. The junction is the most expensive room in every column (render CPU 0.75 to 0.82 ms against 0.48 in Records; draw calls 98 to 114 against 55).
3. **Every room's art is loaded and resident all the time.** All three rooms are built in `_ready`, so 439 nodes and 54.1 MB of file textures (plus 2.2 MB of generated gradients) stay in memory, while only 10 to 24 MB is visible in any one state (Records 10.2 MB, corridor 15.4, title 20.9, junction 23.6). Loading each room's art when the room is entered would cut resident texture memory by roughly 30 MB and shorten the 441 ms scene load.
4. **Scene load is mostly lossless-WebP decode plus script compile.** Per-asset loads (windowed, uncached, median of 4) add up to about 207 ms: the 28 lossless-WebP sprites are about 189 ms of that (title key art 31 ms, the two sentry sheets 15 ms each, hatch 10 ms, every 512x512 prop 5 to 6 ms). The VRAM-compressed room plates take only 5 ms in total, fonts and theme 9 ms, audio 4 ms. Compiling the script graph from source is about 92 ms (`main.gd` with its dependencies); a single fresh compile of `main.gd` alone is the bulk of that. In an export the scripts ship tokenized (`.gdc`), so the in-editor figure is an upper bound.
5. **Lossless sprites cost 4 bytes per pixel in VRAM, plus mipmaps.** The 28 lossless textures account for about 43.6 MB of the 54 MB estimated; the 9 S3TC room plates are 10.5 MB. A 512x512 prop is 1.33 MB on the GPU. Replacing art at about 4 source px per world px (the art bible density) will raise this unless the new props use VRAM compression or are trimmed to their used area.
6. **Several textures are loaded but never on screen on this route:** `junction-sentry-down.png` (4.0 MB), `corridor-bulkhead-open.png` (1.27), `junction-bulkhead-breaking.png` (1.25; it shows only between dumps), `director-side-left-provisional.png` (0.5; intro only). The title key art (4.5 MB) and logo (1.0 MB) stay resident during play.
7. **Generated gradients are made one per instance:** 74 unique `GradientTexture2D` (2.19 MB) from `floor_reflection.gd:_make_shadow`, `fx_presets.gd:_dot_texture`, `room_depth.gd:_radial_texture`/`_linear_texture` and `junction_room.gd:1105`. Many are the same gradient at the same size. A shared cache (one texture per gradient and size) is a natural "component" win: fewer GPU uploads and less code.
8. **Per-frame script hooks are cheap but duplicated:** `FloorReflection._process` runs for every reflected sprite (main, records, junction and sentry each attach their own), and each room has its own `_process` running `JunctionRoom.fade_at_view_edge`, plus `EdgeFader` in main. These are candidates for one shared component; the measured saving would be a fraction of the 0.2 to 0.3 ms script phase.
9. **Room switches are cheap:** `_sync_scene` plus camera cost 0.7 to 2.3 ms to corridor relay or Records; `_enter_junction` cost 4.2 to 5.0 ms, and the worst frame in the next 30 was 25 to 37 ms on entering the junction. There is no hitch worth chasing beyond that junction entry.
10. **Audio is small:** 16 procedural clips total 2.75 MB of PCM (4.4 MB of static memory); the startup clips render in 30 ms on the main thread.

## Startup detail (6 runs, startup only, 1280x720, default settings)

| ms | cold1 | warm1 | warm2 | cold2 | warm3 | warm4 | median |
|---|---:|---:|---:|---:|---:|---:|---:|
| launch to driver init (engine boot) | 1148 | 1406 | 1012 | 847 | 2304 | 813 | 1080 |
| launch to title first frame | 1805 | 2016 | 1629 | 1444 | 2976 | 1397 | **1717** |
| `load(main.tscn)` | 488 | 431 | 448 | 434 | 493 | 426 | **441** |
| instantiate | 3.3 | 10.7 | 3.3 | 3.7 | 6.5 | 3.4 | 3.5 |
| add_child + `_ready` | 53 | 58 | 53 | 53 | 56 | 50 | 53 |
| first frame after `_ready` | 111 | 109 | 112 | 106 | 116 | 103 | 110 |
| load start to title first frame | 656 | 609 | 617 | 597 | 671 | 583 | 613 |
| load start to title reveal done | 1407 | 1355 | 1406 | 1341 | 1421 | 1325 | 1381 |
| load start to detailed sounds ready | 1166 | 1150 | 1217 | 1130 | 1223 | 1098 | 1158 |
| SfxBank startup clips | 30 | 31 | 30 | 30 | 30 | 29 | 30 |

"Cold" runs deleted the user shader cache first. GL Compatibility on macOS showed no cold/warm difference. The full-route runs gave the same picture: `load(main.tscn)` 475 to 503 ms, launch to title 1.68 to 2.25 s. Most of the spread in engine boot is machine load.

## Per-room frame time, CPU and draw calls

The route is title, corridor start, corridor relay (breaker armed), Records, then the junction: entry, the blast actually played (walk to the breaker, USE, walk to the valve, hold USE for three turns, step clear, wait for the door, then 3 s of aftermath), after the blast, and the sentry lane (walk to the rubble, answer 1, WOLF baits, sentry fixates). Each state is held for 10 s: 5 s idle, then 5 s with the engineer walking right and left one second at a time, except the title, junction entry and lane, which are 10 s idle. Every route run ended with `door blown=true`, `lane_choice=wolf`, `sentry=fixated`, `fail_active=false`.

### A. Shipping default: 60 FPS cap + V-Sync, 1280x720 window

Median of runs def-2, def-3, def-4.

| State | FPS | frame avg ms | p50 | p99 | worst | script _process ms/frame | physics ms/frame | render CPU ms/frame | process CPU % of a core | GPU busy % | draw calls | objects drawn | primitives |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Title | 66 | 15.05 | 14.09 | 25.98 | 32.5 | 0.11 | 0.047 | 0.60 | 16 | 44 | 88 | 334 | 4150 |
| Corridor start, idle | 44 | 22.94 | 23.58 | 26.29 | 29.1 | 0.27 | 0.082 | 0.56 | 13 | 41 | 68 | 422 | 3514 |
| Corridor start, walking | 45 | 22.03 | 23.03 | 29.01 | 93.4 | 0.24 | 0.078 | 0.54 | 13 | 40 | 63 | 219 | 2256 |
| Corridor relay, idle | 44 | 22.76 | 21.95 | 26.50 | 69.8 | 0.23 | 0.072 | 0.60 | 13 | 38 | 78 | 282 | 3128 |
| Corridor relay, walking | 45 | 22.38 | 23.35 | 26.04 | 31.7 | 0.23 | 0.076 | 0.57 | 12 | 40 | 74 | 248 | 2634 |
| Records, idle | 44 | 22.97 | 23.72 | 26.50 | 28.2 | 0.21 | 0.073 | 0.48 | 12 | 40 | 55 | 249 | 2288 |
| Records, walking | 46 | 21.64 | 22.18 | 25.84 | 55.1 | 0.20 | 0.071 | 0.49 | 12 | 41 | 55 | 182 | 1728 |
| Junction entry (WOLF scouts) | 44 | 22.82 | 22.61 | 26.51 | 43.1 | 0.26 | 0.082 | 0.75 | 14 | 37 | 98 | 294 | 4038 |
| Junction blast, played (arm, crank, fuse, door, 3 s after) | 42 | 23.73 | 24.36 | 30.12 | 44.3 | 0.32 | 0.069 | 0.78 | 15 | 40 | 102 | 349 | 4578 |
| Junction after blast, idle | 43 | 23.10 | 23.84 | 27.10 | 33.4 | 0.30 | 0.071 | 0.76 | 14 | 40 | 100 | 390 | 4192 |
| Junction after blast, walking | 43 | 23.22 | 23.94 | 26.52 | 52.7 | 0.31 | 0.074 | 0.80 | 15 | 36 | 106 | 398 | 4208 |
| Sentry lane (WOLF baits, sentry fixates) | 43 | 23.05 | 23.65 | 26.23 | 41.1 | 0.27 | 0.069 | 0.81 | 14 | 40 | 109 | 387 | 4186 |

Worst state by average frame: 23.73 ms; worst p99: 30.12 ms; CPU 12 to 16% of a core.

### B. V-Sync only (cap off), 1280x720 window, 120 Hz display

Median of runs vsync-1.

| State | FPS | frame avg ms | p50 | p99 | worst | script _process ms/frame | physics ms/frame | render CPU ms/frame | process CPU % of a core | GPU busy % | draw calls | objects drawn | primitives |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Title | 120 | 8.35 | 8.36 | 12.20 | 17.1 | 0.12 | 0.029 | 0.57 | 24 | 52 | 88 | 334 | 4150 |
| Corridor start, idle | 120 | 8.36 | 8.29 | 12.37 | 17.5 | 0.28 | 0.035 | 0.50 | 25 | 49 | 68 | 415 | 3500 |
| Corridor start, walking | 120 | 8.34 | 8.10 | 11.90 | 18.5 | 0.25 | 0.037 | 0.50 | 26 | 48 | 63 | 219 | 2256 |
| Corridor relay, idle | 120 | 8.33 | 8.32 | 12.42 | 14.6 | 0.23 | 0.031 | 0.53 | 25 | 49 | 78 | 282 | 3128 |
| Corridor relay, walking | 119 | 8.40 | 8.33 | 12.47 | 17.8 | 0.23 | 0.033 | 0.52 | 25 | 48 | 74 | 248 | 2634 |
| Records, idle | 120 | 8.34 | 8.35 | 12.10 | 16.5 | 0.21 | 0.031 | 0.44 | 23 | 50 | 55 | 249 | 2288 |
| Records, walking | 120 | 8.35 | 8.26 | 11.91 | 17.5 | 0.22 | 0.032 | 0.45 | 24 | 48 | 55 | 182 | 1728 |
| Junction entry (WOLF scouts) | 120 | 8.35 | 8.24 | 12.42 | 17.0 | 0.27 | 0.035 | 0.69 | 30 | 49 | 98 | 294 | 4038 |
| Junction blast, played (arm, crank, fuse, door, 3 s after) | 118 | 8.50 | 8.20 | 13.25 | 65.0 | 0.35 | 0.040 | 0.75 | 32 | 50 | 102 | 343 | 4576 |
| Junction after blast, idle | 119 | 8.40 | 8.13 | 12.30 | 28.0 | 0.32 | 0.032 | 0.71 | 31 | 48 | 100 | 394 | 4200 |
| Junction after blast, walking | 116 | 8.65 | 8.05 | 20.28 | 46.9 | 0.33 | 0.034 | 0.74 | 31 | 54 | 104 | 398 | 4208 |
| Sentry lane (WOLF baits, sentry fixates) | 120 | 8.37 | 8.10 | 12.12 | 18.3 | 0.28 | 0.030 | 0.73 | 30 | 51 | 109 | 387 | 4186 |

Worst state by average frame: 8.65 ms; worst p99: 20.28 ms; CPU 23 to 32% of a core.

### C. Uncapped (cap off, V-Sync off), 1280x720 window: raw frame cost

Median of runs unc-2, unc-3, unc-4.

| State | FPS | frame avg ms | p50 | p99 | worst | script _process ms/frame | physics ms/frame | render CPU ms/frame | process CPU % of a core | GPU busy % | draw calls | objects drawn | primitives |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Title | 236 | 4.23 | 4.68 | 7.65 | 28.6 | 0.11 | 0.014 | 0.55 | 38 | 66 | 88 | 334 | 4150 |
| Corridor start, idle | 240 | 4.17 | 3.92 | 7.68 | 13.2 | 0.24 | 0.016 | 0.47 | 40 | 59 | 68 | 415 | 3500 |
| Corridor start, walking | 239 | 4.19 | 3.94 | 7.89 | 12.6 | 0.21 | 0.016 | 0.46 | 40 | 58 | 63 | 219 | 2256 |
| Corridor relay, idle | 235 | 4.25 | 4.64 | 8.07 | 14.7 | 0.20 | 0.015 | 0.51 | 41 | 59 | 78 | 282 | 3128 |
| Corridor relay, walking | 243 | 4.12 | 2.79 | 7.70 | 22.1 | 0.19 | 0.015 | 0.48 | 40 | 59 | 74 | 248 | 2634 |
| Records, idle | 250 | 4.01 | 2.47 | 7.40 | 22.7 | 0.18 | 0.014 | 0.41 | 38 | 59 | 55 | 249 | 2288 |
| Records, walking | 253 | 3.96 | 2.49 | 7.35 | 13.5 | 0.18 | 0.013 | 0.41 | 38 | 59 | 55 | 182 | 1728 |
| Junction entry (WOLF scouts) | 230 | 4.35 | 4.85 | 8.08 | 18.1 | 0.24 | 0.018 | 0.66 | 48 | 58 | 98 | 294 | 4038 |
| Junction blast, played (arm, crank, fuse, door, 3 s after) | 216 | 4.62 | 4.95 | 8.99 | 29.3 | 0.30 | 0.017 | 0.68 | 48 | 58 | 101 | 343 | 4576 |
| Junction after blast, idle | 224 | 4.46 | 4.89 | 8.67 | 16.5 | 0.29 | 0.015 | 0.67 | 48 | 58 | 100 | 394 | 4200 |
| Junction after blast, walking | 212 | 4.72 | 5.19 | 9.16 | 14.6 | 0.30 | 0.018 | 0.70 | 48 | 58 | 107 | 397 | 4208 |
| Sentry lane (WOLF baits, sentry fixates) | 225 | 4.45 | 4.86 | 8.45 | 22.2 | 0.26 | 0.016 | 0.72 | 49 | 58 | 109 | 387 | 4186 |

Worst state by average frame: 4.72 ms; worst p99: 9.16 ms; CPU 38 to 49% of a core.

### D. Uncapped, 960x540 window (the size the earlier figures used)

Median of runs unc-960.

| State | FPS | frame avg ms | p50 | p99 | worst | script _process ms/frame | physics ms/frame | render CPU ms/frame | process CPU % of a core | GPU busy % | draw calls | objects drawn | primitives |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Title | 250 | 4.00 | 2.35 | 7.83 | 29.2 | 0.11 | 0.013 | 0.54 | 39 | 57 | 88 | 334 | 4150 |
| Corridor start, idle | 242 | 4.14 | 2.74 | 7.83 | 13.2 | 0.25 | 0.016 | 0.49 | 43 | 53 | 68 | 415 | 3500 |
| Corridor start, walking | 242 | 4.12 | 2.67 | 8.46 | 14.3 | 0.22 | 0.016 | 0.47 | 42 | 52 | 63 | 219 | 2256 |
| Corridor relay, idle | 252 | 3.97 | 2.40 | 7.72 | 9.5 | 0.20 | 0.013 | 0.50 | 42 | 54 | 78 | 282 | 3128 |
| Corridor relay, walking | 256 | 3.90 | 2.27 | 7.65 | 11.2 | 0.19 | 0.014 | 0.48 | 41 | 54 | 74 | 248 | 2634 |
| Records, idle | 244 | 4.09 | 2.30 | 7.82 | 10.8 | 0.18 | 0.014 | 0.42 | 39 | 53 | 55 | 249 | 2288 |
| Records, walking | 261 | 3.83 | 2.09 | 7.36 | 10.6 | 0.18 | 0.013 | 0.41 | 40 | 53 | 55 | 182 | 1728 |
| Junction entry (WOLF scouts) | 223 | 4.48 | 5.13 | 8.48 | 13.0 | 0.25 | 0.018 | 0.69 | 48 | 51 | 98 | 294 | 4038 |
| Junction blast, played (arm, crank, fuse, door, 3 s after) | 230 | 4.34 | 4.93 | 8.25 | 18.0 | 0.26 | 0.013 | 0.68 | 48 | 52 | 102 | 343 | 4576 |
| Junction after blast, idle | 238 | 4.21 | 4.67 | 7.61 | 9.4 | 0.24 | 0.012 | 0.67 | 48 | 52 | 100 | 394 | 4200 |
| Junction after blast, walking | 226 | 4.42 | 5.05 | 8.47 | 18.0 | 0.28 | 0.014 | 0.69 | 48 | 52 | 104 | 395 | 4202 |
| Sentry lane (WOLF baits, sentry fixates) | 202 | 4.94 | 5.38 | 9.60 | 17.2 | 0.26 | 0.016 | 0.77 | 48 | 50 | 109 | 387 | 4186 |

Worst state by average frame: 4.94 ms; worst p99: 9.60 ms; CPU 39 to 48% of a core.

### E. Shipping default at 1920x1080 window

Median of runs def-1080.

| State | FPS | frame avg ms | p50 | p99 | worst | script _process ms/frame | physics ms/frame | render CPU ms/frame | process CPU % of a core | GPU busy % | draw calls | objects drawn | primitives |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Title | 67 | 14.86 | 11.67 | 25.43 | 29.1 | 0.12 | 0.046 | 0.63 | 16 | 50 | 88 | 334 | 4150 |
| Corridor start, idle | 44 | 22.96 | 22.65 | 25.93 | 27.2 | 0.29 | 0.083 | 0.57 | 12 | 46 | 68 | 422 | 3514 |
| Corridor start, walking | 43 | 23.19 | 23.23 | 25.70 | 26.1 | 0.23 | 0.080 | 0.54 | 12 | 43 | 63 | 218 | 2254 |
| Corridor relay, idle | 44 | 22.98 | 22.91 | 25.82 | 26.2 | 0.22 | 0.069 | 0.58 | 12 | 43 | 78 | 282 | 3128 |
| Corridor relay, walking | 43 | 23.04 | 22.78 | 28.39 | 30.4 | 0.23 | 0.078 | 0.58 | 12 | 44 | 74 | 248 | 2634 |
| Records, idle | 44 | 22.63 | 22.07 | 25.63 | 32.7 | 0.21 | 0.072 | 0.51 | 12 | 39 | 55 | 249 | 2288 |
| Records, walking | 44 | 22.77 | 22.53 | 25.47 | 25.5 | 0.21 | 0.074 | 0.50 | 12 | 43 | 55 | 182 | 1728 |
| Junction entry (WOLF scouts) | 43 | 23.08 | 22.77 | 26.23 | 26.9 | 0.27 | 0.082 | 0.76 | 15 | 42 | 98 | 294 | 4038 |
| Junction blast, played (arm, crank, fuse, door, 3 s after) | 43 | 23.37 | 23.18 | 29.68 | 51.4 | 0.33 | 0.072 | 0.82 | 16 | 38 | 102 | 349 | 4578 |
| Junction after blast, idle | 44 | 22.84 | 22.66 | 26.10 | 27.8 | 0.31 | 0.073 | 0.78 | 15 | 41 | 100 | 390 | 4192 |
| Junction after blast, walking | 43 | 23.30 | 22.90 | 26.50 | 51.9 | 0.32 | 0.076 | 0.80 | 15 | 43 | 104 | 397 | 4206 |
| Sentry lane (WOLF baits, sentry fixates) | 44 | 22.96 | 22.57 | 26.48 | 41.2 | 0.28 | 0.070 | 0.82 | 15 | 40 | 109 | 387 | 4186 |

Worst state by average frame: 23.37 ms; worst p99: 29.68 ms; CPU 12 to 16% of a core.

Columns: "script _process" is the time from the first to the last node `_process` each frame; "physics" sums the physics steps that frame; "render CPU" is `RenderingServer.viewport_get_measured_render_time_cpu`. GPU time is reported as 0 by GL Compatibility on macOS, so the "GPU busy %" column (IOAccelerator Device Utilization, system-wide) stands in for it. "Worst" is the single longest frame across the runs, and those spikes line up with other processes on the machine.

## Memory by state (clean runs, 1280x720)

| State | Static MB | Video MB | Texture MB | Buffer MB | Textures visible / referenced (MB) | Visible canvas items | Visible sprites |
|---|---:|---:|---:|---:|---:|---:|---:|
| Title | 51.4 | 77.1 | 70.8 | 6.3 | 20.9 / 56.3 | 97 | 40 |
| Corridor start / relay | 51.9 | 77.5 | 71.2 | 6.3 | 15.4 / 56.3 | 85 | 38 |
| Records | 51.9 | 77.5 | 71.2 | 6.3 | 10.2 / 56.3 | 73 | 32 |
| Junction (entry, blast, lane) | 52.3 to 52.5 | 77.9 to 78.0 | 71.5 to 71.6 | 6.4 | 23.6 / 56.3 | 116 to 122 | 56 |

Godot's texture count (71 MB) is about 15 MB more than the file and gradient textures found on nodes (56.3 MB). The rest is font glyph atlases, theme and default-theme images, and engine textures.

Node makeup under Main (387): Sprite2D 132, Label 63, Button 34, Node2D 23, ColorRect 21, CPUParticles2D 19 (2 emitting at a time on this route), Panel 16, AudioStreamPlayer 13, HBoxContainer 12, CollisionShape2D 8, Parallax2D 6, HSlider 5, and smaller counts of others. 9 to 10 visible items use additive blend and 8 to 15 use a ShaderMaterial.

## Texture memory by file (GPU image size, desktop S3TC variant)

Sizes come from each texture's `get_image().get_data_size()` (format and mipmaps as uploaded). The "visible in" column comes from the dumps at the end of each state: T title, C corridor, R Records, J junction. "(never)" means not visible at any dump point, not unused.

| MB (GPU image) | px | format | mips | visible in | file |
|---:|---|---|---|---|---|
| 4.50 | 1672x941 | RGB8 | no | T | assets/title-corridor-key-art-provisional.png |
| 4.00 | 1024x768 | RGBA8 | yes | J | assets/props/junction-sentry-side-left.png |
| 4.00 | 1024x768 | RGBA8 | yes | (never) | assets/props/junction-sentry-down.png |
| 2.00 | 512x768 | RGBA8 | yes | J | assets/props/junction-hatch.png |
| 2.00 | 512x768 | RGBA8 | yes | J | assets/props/junction-tank-arm.png |
| 1.98 | 1920x1080 | DXT5 | no | R | assets/rooms/records-mid.png |
| 1.98 | 1920x1080 | DXT5 | no | TC | assets/rooms/corridor-mid.png |
| 1.98 | 1920x1080 | DXT5 | no | J | assets/rooms/junction-mid.png |
| 1.57 | 761x406 | RGBA8 | yes | TCRJ | assets/wolf-side-right-provisional.png |
| 1.33 | 512x512 | RGBA8 | yes | R | assets/props/records-exit-hatch.png |
| 1.33 | 512x512 | RGBA8 | yes | TCJ | assets/props/junction-valve.png |
| 1.33 | 512x512 | RGBA8 | yes | R | assets/props/records-mirror-port.png |
| 1.33 | 512x512 | RGBA8 | yes | R | assets/props/records-purge-queue.png |
| 1.33 | 512x512 | RGBA8 | yes | J | assets/props/junction-arm-panel.png |
| 1.33 | 512x512 | RGBA8 | yes | J | assets/props/junction-bolt-panel.png |
| 1.33 | 512x512 | RGBA8 | yes | TC | assets/props/corridor-safe-point.png |
| 1.33 | 512x512 | RGBA8 | yes | TC | assets/props/corridor-coolant-relay.png |
| 1.33 | 512x512 | RGBA8 | yes | TCJ | assets/props/corridor-breaker.png |
| 1.33 | 512x512 | RGBA8 | yes | TC | assets/props/corridor-purge-display.png |
| 1.27 | 384x648 | RGBA8 | yes | (never) | assets/props/corridor-bulkhead-open.png |
| 1.27 | 384x648 | RGBA8 | yes | TC | assets/props/corridor-bulkhead-sealed.png |
| 1.27 | 384x648 | RGBA8 | yes | TC | assets/props/corridor-bulkhead-front-lip.png |
| 1.25 | 384x640 | RGBA8 | yes | J | assets/props/junction-bulkhead-front-lip.png |
| 1.25 | 384x640 | RGBA8 | yes | J | assets/props/junction-bulkhead-blown.png |
| 1.25 | 384x640 | RGBA8 | yes | (never) | assets/props/junction-bulkhead-breaking.png |
| 1.25 | 384x640 | RGBA8 | yes | J | assets/props/junction-bulkhead-sealed.png |
| 1.00 | 768x256 | RGBA8 | yes | J | assets/props/junction-relief-vent.png |
| 1.00 | 512x512 | RGBA8 | no | T | assets/logo-mark.svg |
| 0.99 | 1920x1080 | DXT1 | no | TC | assets/rooms/corridor-far.png |
| 0.99 | 1920x1080 | DXT1 | no | J | assets/rooms/junction-far.png |
| 0.99 | 1920x1080 | DXT1 | no | R | assets/rooms/records-far.png |
| 0.53 | 512x1080 | DXT5 | no | J | assets/rooms/junction-near.png |
| 0.53 | 512x1080 | DXT5 | no | TC | assets/rooms/corridor-near.png |
| 0.53 | 512x1080 | DXT5 | no | R | assets/rooms/records-near.png |
| 0.50 | 256x384 | RGBA8 | yes | (never) | assets/director-side-left-provisional.png |
| 0.50 | 256x384 | RGBA8 | yes | TCRJ | assets/rowan-side-right-provisional.png |
| 0.41 | 211x382 | RGBA8 | yes | J | assets/props/junction-tank.png |

FILES 37 total 54.09 MB; generated GradientTexture2D: 74 unique, 2.19 MB
STATE title visible 20.9 MB of 56.3 MB referenced
STATE corridor-start visible 15.4 MB of 56.3 MB referenced
STATE corridor-relay visible 15.4 MB of 56.3 MB referenced
STATE records visible 10.2 MB of 56.3 MB referenced
STATE junction-entry visible 23.6 MB of 56.3 MB referenced
STATE junction-blast visible 23.6 MB of 56.3 MB referenced
STATE junction-after-blast visible 23.6 MB of 56.3 MB referenced
STATE junction-lane visible 23.6 MB of 56.3 MB referenced

Offline cross-check from the `.ctex` headers: desktop S3TC 9 files, 10.5 MB; lossless (both platforms) 28 files, about 43.6 MB once decoded to RGBA8 with mipmaps; ETC2 9 files, 10.5 MB (mobile). Biggest lossless items: title key art 1672x941 RGB8 4.5 MB, each sentry sheet 1024x768 4.0 MB, hatch and tank arm 512x768 2.0 MB each, wolf provisional 761x406 1.57 MB, and every 512x512 prop 1.33 MB.

## Pack and import size

- `--export-pack` with Linux, Windows and macOS presets gave identical 24,957,236-byte packs (S3TC); the iOS pack was 24,957,284 bytes (ETC2). The presets lived only in the scratch copy, excluding `tests/*` and the probe scripts. No desktop export template is installed (only `ios.zip`), so there is no full binary; a pack does not need one.
- Pack contents: 154 files. 9 S3TC room plates 10.48 MB, 28 lossless textures 9.73 MB, 7 audio samples 2.54 MB, 2 fonts 0.62 MB, 22 compiled scripts 0.23 MB, `manifest.json` 0.13 MB (it ships in the pack), scene 0.02 MB. gzip -9 of the pack is 17.1 MB.
- Largest pack entries: the three 1920x1080 `*-mid` plates at 2.0 MB each, title key art 1.26 MB, the three `*-far` plates at 1.0 MB each, sentry side and down sheets 0.87 and 0.81 MB, coolant cloud bed audio 0.67 MB, hatch 0.55 MB, the three `*-near` plates at 0.53 MB each, and the three pressure loops at 0.51 MB each.
- `.godot/imported` after two headless imports: 35 MB on disk. Cold import took 10.2 s and the warm re-import 4.7 s, with no errors.

## Code size baseline (for the dedupe pass)

`scripts/*.gd`: 9,266 lines, 405,877 bytes, 22 files (`main.gd` 3,310, `junction_room.gd` 1,243, `sfx_bank.gd` 1,179, `room_depth.gd` 642, `game_settings.gd` 525). `tests/*.gd`: 4,536 lines. `scenes/main.tscn`: 911 lines. Fresh compile time with dependencies: `main.gd` 92 ms, `junction_room.gd` 37, `sfx_bank.gd` 20, then `game_settings`, `sentry`, `room_depth` and `records_room` at 12 to 13 ms each (each row includes its own dependencies, so the rows overlap).

## How it was measured (to repeat for the "after" figures)

- Copy: `rsync -a --delete --exclude .godot apps/game/ scratchpad/lighter/perf/game/`, then two `godot --headless --path game --import`, all with `HOME=scratchpad/home-lighter`. The repository was not touched (`git status` is clean at 76d3a50).
- Driver `scratchpad/lighter/perf/game/perf_driver.gd`, run as `godot --path game -s res://perf_driver.gd -- --out=DIR --size=1280x720 --mode=default|vsync|uncapped --hold=10 --launch_ms=<epoch>`. It times the `main.tscn` load, drives the route through Main's own methods (`_new_game`, `_finish_intro`, `_sync_scene`, `_enter_junction`, `_start_gameplay_camera`) and real inputs (move, interact, choice_1), writes one row per frame to `frames.csv`, and dumps nodes and textures to `state-*.json`. Save and settings go to throwaway `user://perf-lighter-*` files. `auto_pause_on_focus_loss` is off. The window closes itself; no window was left open.
- `default` keeps the game's own settings (`max_fps` 60, V-Sync on, MSAA off). `vsync` and `uncapped` re-assert their limiter every frame, because the game re-applies its settings after the title.
- Wrapper `tools/run_one.sh` waits until no other `godot` process is running (up to 15 min), then samples `ps` every 0.5 s, `ioreg` every 1 s and `footprint` every 2 s (`tools/sysmon.py`). From the second run on, it also logs concurrent Godot processes and the load average. `tools/analyze.py` builds the tables.
- Clean runs used: def-2, def-3, def-4, unc-2, unc-3, unc-4, vsync-1, unc-960, def-1080, and startup-cold1 through warm4. **Excluded:** def-1 and unc-1, whose draw-call and object monitors froze at title values (88 and 334) for the whole route. That fits another agent's `--always-on-top` capture window covering this one, which stops macOS drawing it. The smoke runs are also excluded.
- Extra probes (scratch copy only): `perf_loadprobe.gd` (per-asset load times, windowed, 2 runs), `perf_scriptprobe.gd` (script compile times, headless), `perf_sfxprobe.gd` (sound bank size), `tools/pck_list.py` (pack listing), and `audit/perf-tools/static_textures.py` (offline `.ctex` VRAM estimate, via the scratchpad venv).
- Raw data: `scratchpad/lighter/perf/runs/<run>/` (frames.csv, proc.csv, gpu.csv, footprint.csv, startup.json, switches.json, state-*.json, conditions.txt), `clean.tsv`, `static_textures.csv`, `loadprobe-*.csv`, `export/*.pck`.

## Caveats

- The machine was shared and busy throughout: load average 7 to 17 during clean runs and up to 98 briefly during the smoke run, with Orca, Notion, ffmpeg, Python and other agents' Godot captures. Some clean-run states overlapped with one other Godot process (marked in `clean.tsv`, column `others`). Medians of three runs damp this, but absolute frame times are pessimistic. The comparison with the earlier 2.4/4.2 ms figures needs a rerun on a quiet machine before anyone calls it a regression.
- GPU frame time is not available under GL Compatibility on macOS (it reads 0). GPU busy % is system-wide.
- All of this is desktop (M1 Pro). Phones are a first-slice target, and nothing here was measured on a device. The ETC2 pack size is the only mobile-specific figure.
- The walk-then-jog movement from the walk3 work is not on main (main's `WALK_SPEED` is 190), so these figures predate the new walk cycles and the Look 2 HQ art.
