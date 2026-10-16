# Asset map: old to new (WOLF//OVERRIDE, main @ 76d3a50, 2026-10-11)

Read-only analysis. Nothing under the repo or the wt-r3 worktree was touched. Measurements come from the PNG files (Pillow 12.3 in the scratchpad venv, alpha >= 128 for "opaque"), the `.import` files, `project.godot`, a grep of `scripts/`, `scenes/`, `tests/`, the repo root and `apps/docs`, and `assets/manifest.json`. Helper scripts are in this folder: `measure_assets.py`, `totals.py`, `totals2.py` and `cmp_purge.py`.

**What this does not cover.** None of the new art has been imported into Godot, rendered in the engine, played or tested on a device. Every VRAM figure is an estimate: RGBA8 × 4/3 for mipmaps, or 1 byte/px for VRAM-compressed S3TC/ETC2.

## 0. Headline

- `apps/game/assets/` holds 106 files and 26 MB. That is 51 real files plus 52 `.import` files and 3 shader `.uid` files.
- Every texture is referenced by code or a scene, so no image is orphaned today. The only files with no code reference are the two OFL licence texts and `manifest.json`, and all three are kept.
- **Replaceable now.** 21 old images can go once their approved replacements land: 12 stations, the 2 sentry images, the 3 provisional characters and the 4 junction bulkhead images. Their 10 full-size masters in `apps/game/art-source/` (11 MB, gdignored, so they are not in exports) go too.
- **Blocked.**
  - The 7 door images (corridor and junction bulkheads) wait on the **game-ready shutter layers, which do not exist yet**.
  - The 2 hatch images (junction hatch, Records exit hatch) wait on **hatch art, which the HQ batch does not include**.
  - **Update 2026-10-14:** both are done. The corridor's door end (2026-10-12) and the doors of Records Access and the Service Junction (2026-10-14, `../sources/doors-2026-10-14/`) replaced all 7 bulkhead images, their 7 masters, both hatch images and `scripts/prepare_bulkheads.py`, each deleted with its import and manifest entry.
- **Memory, estimated.**
  - **Stations:** 15.4 MiB down to 8.6 MiB.
  - **Sentry:** 8.0 MiB down to 0.86 MiB. The old sentry is 1024x768 drawn at 0.07, which is 14 source px per world px, 3.5x over the bible.
  - **Doors:** 8.8 MiB today. The shutter layers will cost about 1 MiB per layer.
  - **Characters:** 2.6 MiB rises to 36.4 MiB, because the 6 animation sheets replace 3 stills.
  - Net, the game gets lighter on disk and in stations, but the animation sheets make it heavier in VRAM. Section 7 lists the mitigations.
- **Biggest "faster/lighter" win outside the art swap.** Every room's plates and props are `const preload` in `records_room.gd`, `junction_room.gd` and `main.tscn`, and `main.gd:443-446` builds both rooms in `_ready`. So all three rooms (about 13.4 MiB of compressed plates plus every prop) and the 6 MiB title art stay resident from boot. The bible (section 4) asks for current room plus next room only.

## 1. Inventory of `apps/game/assets/` today

Import key: `c0` = lossless, `c2` = VRAM compressed (S3TC + ETC2), `mip` = mipmaps generated. Every texture has `fix_alpha_border=true` and `premult_alpha=false`. Nodes sample with `texture_filter = 4` (LINEAR_WITH_MIPMAPS). The characters also use the `sharp_sprite` material at LOD bias -0.5.

Drawn world size = region × scale. Density = source px per world px (1/scale).

### 1a. Images that get replaced or deleted

| file | bytes | px (opaque) | import | drawn world px (scale, density) | referenced at | manifest id | verdict |
|---|---:|---|---|---|---|---|---|
| `rowan-side-right-provisional.png` | 90,197 | 256x384 (145x369) | c0 mip | 27x69 (0.188, D 5.3) | `scenes/main.tscn:7` (Human/BodySprite L107); `tests/junction_test.gd:613,635`; `tests/room_depth_test.gd:129` (size and height asserts) | `rowan-side-right-provisional` | DELETE → engineer sheets |
| `wolf-side-right-provisional.png` | 231,549 | 761x406 (628x334) | c0 mip | 115x61 (0.18325, D 5.5) | `main.tscn:6` (Wolf/BodySprite L132); `room_depth_test.gd:130` | `wolf-side-right-provisional` | DELETE → WOLF sheets |
| `director-side-left-provisional.png` | 63,856 | 256x384 (108x370) | c0 mip | 20x70 (0.188) | `main.tscn:10` (IntroDirector L163); `room_depth_test.gd:131` | `director-side-left-provisional` | DELETE → `director-stand-left` (**decision**: the HQ characters are labelled identity reference, but this is the only Look 2 Director) |
| `props/corridor-breaker.png` | 295,111 | 512² (336x431) | c0 mip | 77x97 (0.225) | `main.tscn:20` (BreakerArt L178); `junction_room.gd:20,416` | `corridor-breaker` | REPLACE in place |
| `props/corridor-coolant-relay.png` | 333,373 | 512² (385x401) | c0 mip | 86x90 (0.221) | `main.tscn:21` (RelayArt L187) | `corridor-coolant-relay` | REPLACE in place |
| `props/corridor-purge-display.png` | 357,021 | 512² (414x404) | c0 mip | 105x102 (0.25) | `main.tscn:11` (PurgeTerminalArt L169) | `corridor-purge-display` | REPLACE (or dedupe, see section 6) |
| `props/corridor-safe-point.png` | 226,355 | 512² (274x446) | c0 mip | 70x112 (0.25) | `main.tscn:22` (CheckpointArt L196) | `corridor-safe-point` | REPLACE in place |
| `props/records-purge-queue.png` | 355,297 | 512² (411x405) | c0 mip | 114x112 (0.274, D 3.65) | `records_room.gd:7,56` | `records-purge-queue` | REPLACE in place |
| `props/records-mirror-port.png` | 335,442 | 512² (368x464) | c0 mip | 89x112 (0.239) | `records_room.gd:8,57` | `records-mirror-port` | REPLACE in place |
| `props/junction-valve.png` | 334,044 | 512² (506x489) | c0 mip | 101x98 (0.2, D 5) | `junction_room.gd:21,418,437,448-449`; `bypass_handle.gd:83,92-93` (wheel cut + mask) | `junction-valve` | REPLACE (body, plus new wheel, gauge and needle parts) |
| `props/junction-tank-arm.png` | 365,781 | 512x768 (387x733) | c0 mip | arm 85x77 (0.22) | `junction_room.gd:29,623` | `junction-tank-arm` | REPLACE. Today the image still holds the tank (rows 361-743), which is never drawn, so half the texture is wasted |
| `props/junction-tank.png` | 165,450 | 211x382 | c0 mip | 46x84 (0.22) | `junction_room.gd:31,613` | `junction-tank` (a derivative crop of tank-arm) | REPLACE |
| `props/junction-arm-panel.png` | 323,190 | 512² (352x461) | c0 mip | 50x65 (0.14, D 7.1) | `junction_room.gd:32,419` | `junction-arm-panel` | REPLACE |
| `props/junction-bolt-panel.png` | 341,364 | 512² (512x391) | c0 mip | 77x59 (0.15, D 6.7) | `junction_room.gd:33,420` | `junction-bolt-panel` | REPLACE |
| `props/junction-relief-vent.png` | 262,829 | 768x256 (749x168) | c0 mip | 72x18 (0.0969, D 10.3) | `junction_room.gd:28,417` | `junction-relief-vent` | REPLACE (redesigned as a raised housing) |
| `props/junction-sentry-side-left.png` | 882,897 | 1024x768 (854x625) | c0 mip | 60x44 (0.07, **D 14.3**) | `sentry.gd:15,111` | `junction-sentry-side-left` | DELETE → `sentry-active` |
| `props/junction-sentry-down.png` | 817,912 | 1024x768 (842x622) | c0 mip | 59x44 (0.07) | `sentry.gd:16,112` | `junction-sentry-down` | DELETE → `sentry-wreck` |
| `props/corridor-bulkhead-sealed.png` | 333,471 | 384x648 (308x602) | c0 mip | 115x182 canvas (0.3, D 3.3) | `main.tscn:9` (Door/Visual/DoorArt L89); `main.gd:45,584`; `seal_leaf.gd` LEAF/DOORWAY rects | `corridor-bulkhead-sealed` | **DELETED 2026-10-12** with its import, manifest entry and master (the corridor door end, `../sources/corridor-door-end-2026-10-12/`) |
| `props/corridor-bulkhead-open.png` | 347,459 | 384x648 (312x602) | c0 mip | same | `main.gd:46,580`; **also** `junction_room.gd:37,392` (the junction exit hatch's passage is a cut of this image) | `corridor-bulkhead-open` | **DELETED 2026-10-14** with its import and manifest entry (the doors landed: `../sources/doors-2026-10-14/`); the junction exit's passage is now its own piece of the exit door's atlas |
| `props/corridor-bulkhead-front-lip.png` | 119,225 | 384x648 (115x601) | c0 mip | same | `main.gd:47,581` | `corridor-bulkhead-front-lip` | **DELETED 2026-10-12** with its import, manifest entry and master (the corridor door end) |
| `props/junction-bulkhead-sealed.png` | 335,605 | 384x640 (307x599) | c0 mip | 115x181 (0.3) | `junction_room.gd:24,546` | `junction-bulkhead-sealed` | **DELETED 2026-10-14** with its import and manifest entry (the doors landed: `../sources/doors-2026-10-14/`) |
| `props/junction-bulkhead-breaking.png` | 354,752 | 384x640 | c0 mip | same | `junction_room.gd:25,547` | `junction-bulkhead-breaking` | **DELETED 2026-10-14** with its import and manifest entry (the doors landed: `../sources/doors-2026-10-14/`) |
| `props/junction-bulkhead-blown.png` | 362,949 | 384x640 | c0 mip | same | `junction_room.gd:26,548` | `junction-bulkhead-blown` | **DELETED 2026-10-14** with its import and manifest entry (the doors landed: `../sources/doors-2026-10-14/`) |
| `props/junction-bulkhead-front-lip.png` | 134,506 | 384x640 (126x593) | c0 mip | same | `junction_room.gd:27,553` | `junction-bulkhead-front-lip` | **DELETED 2026-10-14** with its import and manifest entry (the doors landed: `../sources/doors-2026-10-14/`) |
| `props/junction-hatch.png` | 595,185 | 512x768 (401x698) | c0 mip | 83x144 (0.206) | `junction_room.gd:34,421,422,429` (entry hatch, exit hatch, HatchDoorway leaf) | `junction-hatch` | **DELETED 2026-10-14** with its import and manifest entry (the doors landed: `../sources/doors-2026-10-14/`); the junction's entry and exit are now swing and sliding doors |
| `props/records-exit-hatch.png` | 253,361 | 512² (254x479) | c0 mip | 76x140 (0.291, D 3.4) | `records_room.gd:9,58` | `records-exit-hatch` | **DELETED 2026-10-14** with its import and manifest entry (the doors landed: `../sources/doors-2026-10-14/`); the Records exit is now a swing door |

### 1b. Files to keep

None of these has a clear new replacement in the approved set.

| file | bytes | detail | import | referenced at | manifest id |
|---|---:|---|---|---|---|
| `rooms/corridor-far.png` | 2,683,776 | 1920x1080 | c2, no mip (≈2 MiB VRAM) | `main.tscn:17` | `corridor-far` |
| `rooms/corridor-mid.png` | 1,038,487 | 1920x1080 | c2, no mip | `main.tscn:18` | `corridor-mid` |
| `rooms/corridor-near.png` | 267,408 | 512x1080 | c2, no mip | `main.tscn:19` | `corridor-near` |
| `rooms/records-far/mid/near.png` | 2,388,741 / 1,051,421 / 270,902 | same sizes | c2, no mip | `records_room.gd:4-6` | `records-far/-mid/-near` |
| `rooms/junction-far/mid/near.png` | 2,337,859 / 2,242,853 / 470,648 | same sizes | c2, no mip | `junction_room.gd:17-19` | `junction-far/-mid/-near` |
| `title-corridor-key-art-provisional.png` | 1,801,160 | 1672x941 | c0, **no mip** (6 MiB VRAM) | `main.tscn:8` (TitleScreen L486); `tests/m0_scene_test.gd:51`; `README.md:13` | `title-corridor-key-art-provisional` |
| `logo-mark.svg` | 1,902 | 512 raster | c0, no mip, `svg/scale=1.0` | `main.tscn:5`; `project.godot:16` (icon); `m0_scene_test.gd:53` | `wolf-override-logo-mark` |
| `fonts/Montserrat-Variable.ttf` | 744,936 | | | `Montserrat-Bold.tres:3`, `Montserrat-Semibold.tres:3` | `montserrat-variable-font` |
| `fonts/Roboto-Variable.ttf` | 488,584 | | | `Roboto-Regular.tres:3` | `roboto-variable-font` |
| `fonts/Montserrat-Bold.tres` | 236 | | | `main.tscn:15`, `main.gd:57`, `game_settings.gd:6` | `montserrat-bold-variation` |
| `fonts/Montserrat-Semibold.tres` | 236 | | | `game_theme.tres:4`, `game_settings.gd:5` | `montserrat-semibold-variation` |
| `fonts/Roboto-Regular.tres` | 232 | | | `game_theme.tres:3`, `game_settings.gd:4` | `roboto-regular-variation` |
| `fonts/game_theme.tres` | 17,086 | | | `project.godot:29`, `game_settings.gd:290`, `main.gd:1163` | `game-ui-theme` |
| `fonts/Montserrat-OFL.txt`, `fonts/Roboto-OFL.txt` | 4,400 / 4,394 | licence text | not a resource | **no code reference** (licence; keep) | `montserrat-ofl-text`, `roboto-ofl-text` |
| `shaders/floor_reflection.gdshader` (+.uid) | 1,065 | | | `floor_reflection.gd:10` | `floor-reflection-shader` |
| `shaders/post_grade.gdshader` (+.uid) | 590 | | | `main.tscn:23` | `post-grade-shader` |
| `shaders/sharp_sprite.gdshader` (+.uid) | 774 | | | `main.tscn:24`, `room_depth_test.gd:140` | `sharp-sprite-shader` |
| `audio/junction-pressure-loop-low/mid/high.wav` | 529,312 ×3 | mono 16-bit 44.1 kHz, 6 s | PCM (`compress/mode=0`), loop 2 | `sfx_bank.gd:46-48` | `junction-pressure-loop-*` |
| `audio/junction-coolant-cloud-bed.wav` | 705,712 | 8 s | PCM, loop | `sfx_bank.gd:49` | `junction-coolant-cloud-bed` |
| `audio/junction-relief-vent-burst.wav` | 211,724 | 2.4 s | PCM | `sfx_bank.gd:50` | `junction-relief-vent-burst` |
| `audio/wolf-growl-seam.wav`, `wolf-growl-refusal.wav` | 79,424 / 81,188 | 0.9 s | PCM | `sfx_bank.gd:51,52` | `wolf-growl-seam`, `wolf-growl-refusal` |
| `changelog.txt` | 42,556 | text | not a resource; an export preset must include `*.txt` (`main.gd:5-8`) | `main.gd:8,545` | `changelog-text-export` |
| `manifest.json` | 131,444 | register | probably loads as a JSON resource, so it may ship in exports; confirm with a test export | **no code reference** (keep; consider an export exclude filter) | not registered (by design) |

### 1c. Outside `assets/` but part of the old art

| path | size | notes | manifest id |
|---|---|---|---|
| `apps/game/art-source/characters/{rowan-side-right,wolf-side-right,director-side-left}-provisional.png` | part of 11 MB | full-size masters of the 3 provisional sprites; `.gdignore` | `*-provisional-master` (3) |
| `apps/game/art-source/doors/{corridor-sealed,corridor-open,corridor-front-lip,junction-sealed,junction-breaking,junction-blown,junction-front-lip}.png` | | door A masters | `door-a-*-master` (7) |
| `scripts/prepare_bulkheads.py` (repo root) | | only built bulkheads from `art-source/doors`; **deleted 2026-10-14** with the last of them | — |
| `apps/docs/app/images/{corridor-start,service-junction-entry,title-screen}-capture.png` | | marketing captures of the old art; re-render after the swap (bible: site captures), do not delete | `*-capture-*` (3) |
| local `.godot/imported/` (8.6 MB, not committed) | | stale entries such as `maintenance-props-provisional`; a clean reimport clears them | — |

## 2. REPLACEMENT LIST (new file → target, size at D = 4, which component uses it)

**Source roots:**
- `HQ` = `docs/research-2026-10/sources/look2-hq/`
- `W3` = `scratchpad/walk3/`

**Placement rule (props, sentry, Director):**
- Draw at scale **0.25**, which is D = 4.
- Every HQ canvas is a multiple of 16 with about 8 px of padding. The baseline row is H-9, so the opaque bottom = baseline + 1.
- Cut each region to the opaque box below so the existing `make_prop()` floor placement and the `*_HALF_WIDTH` maths still work.

**Path strategy:** overwrite in place where the role is unchanged. That keeps every `preload` path, `.import` uid and manifest `asset_id`. Only the REGION, SCALE and light-rect constants change. The same pixels-out, pixels-in result is what Nathanial asked for ("old assets deleted, new assets replace them").

### 2a. Stations and props (`assets/props/`)

| new file (HQ/props) | canvas | opaque box (x,y,w,h) | world px at 0.25 | old drawn world px | Δ | target path | used by |
|---|---|---|---|---|---|---|---|
| `corridor-breaker.png` | 288x416 | 12,19,264,389 | 66.0 x 97.3 | 77.0 x 97.4 | **11 narrower**: `BREAKER_HALF_WIDTH` and the station x/reach values move (`junction_test.gd:445`, `follow_spacing_test.gd:211`) | `props/corridor-breaker.png` | corridor BreakerArt (`main.tscn`) and junction `breaker_art` |
| `corridor-coolant-relay.png` | 336x384 | 16,20,304,356 | 76.0 x 89.0 | 86.2 x 89.5 | 10 narrower | `props/corridor-coolant-relay.png` | corridor RelayArt |
| `corridor-purge-display.png` | 432x432 | 11,21,411,403 | 102.8 x 100.8 | 105 x 102 | ≈ | `props/corridor-purge-display.png` (or dedupe, section 6) | corridor PurgeTerminalArt |
| `corridor-safe-point.png` | 304x480 | 12,25,281,447 | 70.3 x 111.8 | 70 x 112.3 | ≈ | `props/corridor-safe-point.png` | corridor CheckpointArt |
| `records-purge-queue.png` | 480x480 | 12,24,455,448 | 113.8 x 112.0 | 114.3 x 112.1 | ≈ | `props/records-purge-queue.png` | Records PurgeArt |
| `records-mirror-port.png` | 384x480 | 14,24,356,448 | 89.0 x 112.0 | 89.1 x 111.9 | ≈ | `props/records-mirror-port.png` | Records MirrorArt |
| `junction-valve.png` (body, wheel removed) | 432x416 | 14,15,403,393 | 100.8 x 98.3 | 101.2 x 98 | ≈ | `props/junction-valve.png` | junction ValveArt |
| `junction-valve-wheel.png` | 176x176 | centred on pivot | 36.3 x 36.0 | 36.8 dia (masked disc) | ≈ | `props/junction-valve-wheel.png` (new) | **one ValveWheel component** for `junction_room` ValveWheel and `bypass_handle` Wheel; plain rotation, which drops `WHEEL_MASK` and both runtime `Shader.new()` calls |
| `junction-valve-needle.png` | 80x32 | 30,10,35,13 | 8.8 x 3.3 | code line 1.4 wide | bolder | `props/junction-valve-needle.png` (new) | `_draw_gauge()` → needle sprite (pivot per `parts.json`) |
| `junction-valve-gauge.png` | 80x80 | 14,14,52,52 | 13 x 13 | dial 14.8 dia | ≈ | optional | **unused today.** The body already has an empty face. Import it only if the code stops drawing the face band |
| `junction-tank.png` | 208x368 | 16,24,176,336 | 44.0 x 84.0 | 46.4 x 84 | ≈ | `props/junction-tank.png` | DropArm tank |
| `junction-tank-arm.png` (arm only) | 352x432 | 10,23,329,401 | 82.3 x 100.3 | 85.4 x 77.4 | **23 taller**: re-hang it on the gantry (shackle and lug points in `HQ/props/parts.json`, which is not in the repo copy; take it from the HQ scratch batch) | `props/junction-tank-arm.png` | junction `arm_art` |
| `junction-arm-panel.png` | 224x288 | 13,19,197,261 | 49.3 x 65.3 | 49.6 x 64.8 | ≈ | `props/junction-arm-panel.png` | `arm_panel_art` |
| `junction-bolt-panel.png` | 368x256 | 16,13,336,235 | 84.0 x 58.8 | 76.8 x 59 | **7 wider**: `BOLT_X` moves about 3.6 (`follow_spacing_test.gd:212`) | `props/junction-bolt-panel.png` | `bolt_panel_art` |
| `junction-relief-vent.png` | 320x208 | 15,21,289,179 | 72.3 x 44.8 | 72 x 17.7 | **27 taller** (raised housing): move the steam emitter, the RELIEF VENT caption and the nozzle light; `vent_scale()` becomes 0.25 | `props/junction-relief-vent.png` | `vent_art` |
| `status-lamp-{breaker,relay,purge-display,purge-queue,mirror-port,arm-panel,bolt-panel,relief-vent}.png` | 64-80 x 32 | 44-62 x 9-12 | 11-15.5 x 2.2-3 | ColorRect / `draw_rect` 16-20 x 4-5 | ≈ | `props/lamps/*.png` (new, 8, or 1-2, see section 6) | **one StatusLamp component** (sprite + `modulate` + the existing additive glow). It replaces BreakerStatusLight/RelayStatusLight (`main.tscn:200-216`), `records_room.gd:140-141` and `junction_room.gd:1046,1160,1179`. Keep the node names and colours so the HUD and tests read the same (tests check `.color` at `m0_scene_test.gd:43,217,296`, which would become `.modulate`) |

### 2b. Sentry (`assets/props/` or a new `assets/sentry/`)

| new (HQ/sentry) | canvas | opaque | world at 0.25 | old | target | used by |
|---|---|---|---|---|---|---|
| `sentry-active.png` | 272x208 | 16,32,240,168 | 60 x 42 | 59.9 x 43.8 | `props/junction-sentry-active.png` | `Sentry` Body. Re-derive `ACTIVE_REGION`, `ART_SCALE` (0.25), `ACTIVE_TREAD_X` (130), `LENS` (about 96-128, 63-69) and `DRAWN_HEIGHT` (about 42; `sentry_test.gd:319`, `TANK_REST_Y` comment) |
| `sentry-wreck.png` | 272x208 | 17,31,239,169 | 59.8 x 42.3 | 59.1 x 43.6 | `props/junction-sentry-wreck.png` | `Sentry` Wreck. Tread x 130; `WRECK_HULL_TOP` is about 101-111, re-derive it |
| `sentry-scanning.png` | 272x208 | 16,31,240,169 | 60 x 42 | — | optional `props/junction-sentry-scanning.png` | **No consumer today.** `SentryBrain` has dormant, patrol, chase, fixated and down, but the art has 2 states. It could show for chase/fixated (hull and treads are pixel-identical to active, so swapping cannot jitter) |

### 2c. Characters (new `assets/characters/`)

Walk3 placement:
- Node scale = walk3 `game_scale` ÷ 2.7 (1080p × zoom 1.35). That gives **engineer 0.2540** (D 3.94) and **WOLF 0.2603** (D 3.84), which keeps today's world size.
- Engineer feet: the cell baseline is row 311, so the BodySprite y is about **-8.6**, keeping today's foot line at +29.8 below Human's origin.
- WOLF feet: the cell baseline is row 263, so the BodySprite y is about **-17.8**, keeping today's +15.2. WOLF's pivot column is 293, which is the cell centre + 37 (walk3 `rows-info`), so check `flip_h` with that offset.

| new | sheet | frames / fps | world | old | target | used by |
|---|---|---|---|---|---|---|
| `W3/engineer/deliver/sprites/eng-idle-sheet.png` | 1024x640 (4x2 of 256x320) | 8, loop 2.32 s | 70.4 tall (opaque 277) | 69.4 | `characters/engineer-idle.png` | **ActorSprite component** (AnimatedSprite2D or Sprite2D hframes/vframes) on Human/BodySprite |
| `.../eng-walk-sheet.png` | 1024x960 (4x3) | 12 @ 15.30 fps (80 px/s) | | | `characters/engineer-walk.png` | same |
| `.../eng-jog-sheet.png` | 1024x960 (4x3) | 12 @ 22.83 fps (190 px/s after about 0.5 s held) | | | `characters/engineer-jog.png` | same |
| `W3/wolf/deliver/sprites/wolf-idle-sheet.png` | 2048x544 (4x2 of 512x272) | 8, loop 3.15 s | 114.8 x 62.7 | 115.1 x 61.2 | `characters/wolf-idle.png` | ActorSprite on Wolf/BodySprite |
| `.../wolf-walk-sheet.png` | 2048x816 (4x3) | 12 @ 19.76 fps | | | `characters/wolf-walk.png` | same |
| `.../wolf-trot-sheet.png` | 2048x816 (4x3) | 12 @ 29.83 fps | | | `characters/wolf-trot.png` | same |
| `HQ/characters/director-stand-left.png` | 256x320 (opaque 82x280, base 311) | still | 70 tall at 0.25 | 69.6 | `characters/director-stand-left.png` | IntroDirector (**decision**, see 1a) |

**Walk3 caveats:**
- A fix round is still running. `W3/REVIEW.md` lists 5 fixes: engineer walk frames 1-2 (boots sink, hand smudge), engineer jog frame 6, WOLF trot frame 0, and the WOLF death-pose colour. The fixed frames are in `W3/engineer/frames/*fix/`, but the delivered sheets are still the 12:33 and 13:13 versions. **Take the sheets only after the fix round re-delivers them, and record their SHA-256 values in the manifest.**
- `wolf/deliver/sprites/eng-*-sheet.png` are byte-identical copies of the engineer sheets. Import one copy only.
- **`FloorReflection._mirror()` copies position, scale, rotation, flip and modulate every frame, but not the frame, region or texture.** An animated BodySprite needs the reflection to follow the current frame. Fold that into the ActorSprite component, because a reflection frozen on frame 0 would look wrong.

## 3. DELETION LIST

For each item, delete:
- the file
- its `.import` file
- its manifest entry, or rewrite the entry when the file is overwritten in place
- the code references listed

Then run `scripts/check-game.sh`, which reimports and fails on stray errors.

### Phase A: as soon as the HQ stations, sentry and walk3 sheets land

| delete | + .import | manifest entry | code / test references to change |
|---|---|---|---|
| `props/junction-sentry-side-left.png` | yes | `junction-sentry-side-left` | `sentry.gd:15` and the constants at `sentry.gd:17-30` (`ACTIVE_REGION`, `ART_SCALE` 0.07, `ACTIVE_TREAD_X` 516, `LENS`, `DRAWN_HEIGHT`); `sentry_test.gd:319` |
| `props/junction-sentry-down.png` | yes | `junction-sentry-down` | `sentry.gd:16`; `WRECK_REGION`, `WRECK_TREAD_X` 545, `WRECK_HULL_TOP` 340 |
| `rowan-side-right-provisional.png` | yes | `rowan-side-right-provisional` | `main.tscn:7` ext_resource and Human/BodySprite scale 0.188, pos (0,-5); `junction_test.gd:613,635` (stand-in preload, so use a generated placeholder texture or the idle sheet); `room_depth_test.gd:124-131` (expects 256x384 and 1536×0.047 world height) |
| `wolf-side-right-provisional.png` | yes | `wolf-side-right-provisional` | `main.tscn:6` and Wolf/BodySprite scale 0.18325, pos (0,-15); `room_depth_test.gd:130` (761x406, 1015×0.0733) |
| `director-side-left-provisional.png` (if approved) | yes | `director-side-left-provisional` | `main.tscn:10`, IntroDirector L163; `room_depth_test.gd:131` |
| `art-source/characters/*.png` (3) | — | `*-provisional-master` (3) | comment at `room_depth_test.gd:124` |
| overwritten in place (old pixels gone): `props/corridor-breaker`, `corridor-coolant-relay`, `corridor-purge-display`, `corridor-safe-point`, `records-purge-queue`, `records-mirror-port`, `junction-valve`, `junction-tank`, `junction-tank-arm`, `junction-arm-panel`, `junction-bolt-panel`, `junction-relief-vent` | reimported | rewrite all 12 entries (new source, SHA, modifications) | `main.tscn` region_rect and scale on PurgeTerminalArt (L169), BreakerArt (L178), RelayArt (L187) and CheckpointArt (L196); `junction_room.gd:47-85` (all `*_REGION`, `*_SCALE`, `*_LIGHT`, `VALVE_WHEEL_*`, `VALVE_DIAL_*`, `TANK_REGION`, `ARM_REGION`, `HATCH_*` stays), `:224-230` `WHEEL_MASK`, `:434-451` wheel cut, `:510-511` `vent_scale`, `:628` arm hang; `bypass_handle.gd:79-94`; `records_room.gd:12-24`; `main.gd:692` status glow; tests `junction_test.gd:445`, `follow_spacing_test.gd:211-212,270` |

### Phase B: only after the game-ready shutter layers exist (done: corridor 2026-10-12, junction 2026-10-14)

| delete | + .import | manifest | code / test references |
|---|---|---|---|
| `props/corridor-bulkhead-sealed.png` | yes | `corridor-bulkhead-sealed` | `main.tscn:9` (Door/Visual/DoorArt region (0,42,384,606), scale 0.3), `main.gd:45,584`; `seal_leaf.gd` (LEAF and DOORWAY are in this canvas's pixels) |
| `props/corridor-bulkhead-open.png` | yes | `corridor-bulkhead-open` | `main.gd:46,580`; **`junction_room.gd:37-39,392` (HATCH_PASSAGE cut)**, so it needs a new passage piece first |
| `props/corridor-bulkhead-front-lip.png` | yes | `corridor-bulkhead-front-lip` | `main.gd:47,581` |
| `props/junction-bulkhead-{sealed,breaking,blown,front-lip}.png` | yes | 4 entries | `junction_room.gd:22-27,60-67` (`DOOR_REGION`, `DOOR_SCALE`, `DOOR_SEAM_X`, `DOOR_BREAK_SECONDS`), `:546-553` |
| `art-source/doors/*.png` (7) | — | `door-a-*-master` (7) | `scripts/prepare_bulkheads.py` (delete it) |
| — | | | `room_depth.gd:74` `BULKHEAD_SCALE` 0.3, `make_bulkhead` / `bulkhead_center_x` (the registered-canvas assumption); tests `room_depth_test.gd:76-77`, `junction_test.gd:563-565`, `m0_scene_test.gd:222-237` (SealLeaf behaviour: keep it, re-pointed at the shutter leaf) |

### Phase C: only after new hatch art exists (done 2026-10-14: the doors replaced the hatches)

| delete | + .import | manifest | code |
|---|---|---|---|
| `props/junction-hatch.png` | yes | `junction-hatch` | `junction_room.gd:34,78-86` (`HATCH_REGION`, `HATCH_SCALE`, `HATCH_LAMP`, `HATCH_LEAF`), `:363-395` HatchDoorway, `:421-429`, `:1120-1122`. **Merge after codex/logic-round-3**, which is reworking the opening hatch in this file. |
| `props/records-exit-hatch.png` | yes | `records-exit-hatch` | `records_room.gd:9,18-21,58` |

**Manifest housekeeping.**
- After all three phases, 24 entries are deleted and 12 are rewritten in place.
  - Deleted: 5 in phase A (2 sentry and 3 provisional characters) plus 3 character masters, 7 bulkheads plus 7 door masters, and 2 hatches.
  - Rewritten: the 12 stations replaced in place.
  - New entries cover each imported HQ part, lamp, sentry state and character sheet.
- The top-level `status` paragraph has to be rewritten, because it counts "three provisional character images", "sixteen station prop images", "two pressure bulkheads", "two sentry images" and "the valve wheel's inline disc mask".
- The public docs describe the old art and need updating in the same PR:
  - `apps/docs/content/docs/credits.mdx:39,42,46`
  - `legal.mdx:12`
  - `about.mdx:6` ("provisional static art")

## 4. Unused or not-to-ship

- **Today's game:** no texture is orphaned. Two files have no code reference: `fonts/*-OFL.txt` (licence) and `manifest.json` (register). Keep both. List them, plus `changelog.txt`, in the export filters when a preset is added. There is no `export_presets.cfg` yet.
- **Approved but no consumer, so do not import yet** (lighter build):
  - `HQ/props/pickup-*` (6). No pickup system exists.
  - `HQ/characters/engineer-side-idle`, `engineer-side-stride`, `engineer-three-quarter`, `wolf-side-stand`, `wolf-side-walk`, `wolf-side-lookback`, `wolf-sit` and `director-turn-away`. These are identity references; the walk3 sheets supersede the side poses.
  - `junction-valve-gauge` (optional).
  - `sentry-scanning` (optional third state).
  - `W3/death-poses/*`, for the later death system. REVIEW fix 1 says the WOLF death frames must be regraded first.
  - `HQ/doors/*`, which are **superseded**. Do not import them.

## 5. Still to make

1. **Shutter door layers.** Game-ready, at D = 4, about 136-144 world px tall (544-576 px), canvas about 352x576, frame and leaf separate. Lossless, mipmaps on. The design comes from `doors-shutter-approved/` (corridor-closed/open, junction-closed/blown). Those four files are 1671x941 concept scenes, not layers.
   - **Corridor seal:**
     - `frame`: portal columns, header, guide rails; behind the actors.
     - `leaf`: ribbed slats with a hazard bottom edge, sliding up into the header. This replaces the SealLeaf cut.
     - `passage`: the machinery service chamber behind the doorway.
     - `front`: the near column, drawn over the actors and fading (RoomDepth pillars).
     - The red and green lamp should be a lamp sprite tinted in code, not baked.
   - **Junction blast door:**
     - `frame` (heavier rails, bolted header)
     - `leaf-sealed` (armoured segments)
     - `leaf-blown` (torn hanging plates)
     - `debris` (floor, beside the threshold)
     - `passage` (switchgear hall)
     - `front`
     - amber lamps as tinted sprites
     - **Decision:** whether to keep a `leaf-breaking` frame for the 0.15 s blast moment (`DOOR_BREAK_SECONDS`), or cover it with the existing flash and particles, which saves one texture.
2. **Hatches.** The HQ batch has none.
   - Junction hatch: one image serves the entry and exit hatches. It needs frame + leaf + lamp socket, plus the exit hatch's **passage** piece that today is cut from `corridor-bulkhead-open`.
   - Records exit hatch.
   - Decision: make them a small member of the shutter family or keep a hatch silhouette (the bible needs each family distinct).
3. **A hatch status lamp sprite.** There is no `status-lamp-hatch*`, and `HATCH_LAMP` is a 92x24 source rect today. One of the 8 lamp sprites scaled may do.
4. **Corridor purge-display indicator.** The new art has an unlit socket, so the corridor needs a lamp drawn where the old art had it baked (`status-lamp-purge-display`). This is new code, not new art.
5. **Gantry rods and shackle placement** for the taller arm: code, using `parts.json` from the HQ scratch batch (it is not in the repo's `look2-hq/props`).
6. **Pending decisions from the HQ notes:**
   - the accent-share exception: the purge consoles are at 14.7% and the safe point at 15.6%, against the 12% limit
   - the Director still (above)

## 6. Asset-level duplication (this is how assets get "componentized")

- **Purge console in two files.** `corridor-purge-display` (432² canvas) and `records-purge-queue` (480²) are the **same render** at 404 vs 448 px, per the HQ notes. I checked by eye and by measurement: alpha differs by 0.97/255 on average after resampling, and the RGB differences sit in transparent edge fill. Ship one texture, `props/purge-console.png`, drawn at 0.25 in Records and **0.225** in the corridor: 455x448 × 0.225 = 102.4 x 100.8 world, which matches today's 102.8 x 100.8. The density is 4.4, still at or above the bible. That saves 0.95 MiB VRAM, one manifest entry and one lamp sprite.
- **Status lamps.** The 8 lamp sprites are one Codex lens render fitted to 8 socket sizes. Each is under 650 bytes, so this is about files, not memory. One component can tint any of them. Keeping the 8 avoids the bible's G_hf_share edge case on thin sprites, so the saving is optional.
- **Breaker** is already shared between the corridor and the junction (one file). Keep it that way. The **junction hatch** image already serves the entry and exit hatches; keep that too.
- **The tank was in the tank-arm image.** Old: the arm image also held the tank, and a duplicate crop held the tank again. New: separate sprites, so that duplication is gone.

## 7. Import settings and performance notes

- **Bible section 4 vs today:**
  - Props and characters already match: lossless, mipmaps, LINEAR_WITH_MIPMAPS, `fix_alpha_border`. Keep that for every new prop, door and sheet.
  - Plates: c2 with no mipmaps today; the bible asks for mipmaps **on** for mid plates at c2. Out of scope; keep the plates.
  - Title: no mipmaps today, bible says on. Keep its path.
  - **Logo:** `svg/scale=1.0`, no mipmaps; the bible wants `svg/scale=0.5` plus mipmaps (aliasing error 12.4). It is a one-line import fix, and the asset stays.
- **Residency (biggest runtime win).**
  - Room textures are `const preload`, and both rooms are built in `main.gd:_ready` (`:443,446`), so every plate and prop of all three rooms is in VRAM from boot.
  - The title key art (6 MiB lossless, `main.tscn:8`) stays resident through play.
  - Fix: load each room's art when the room is entered, with a threaded load request for the next room, and free the title texture after the title.
  - Keeps the UI identical.
- **The animation sheets are the new memory cost: about 36 MiB of RGBA8 + mips for 6 sheets.** Options, all of which need Nathanial's decision:
  - Bible frame counts (idle 6, walk 8, jog/trot 8 in 4x2 sheets) instead of the delivered 12-frame walk and jog. That saves about 11 MiB.
  - A trimmed atlas: engineer frames fill about 55-70% of their 256x320 cells, WOLF about 75-80% of 512x272. A SpriteFrames atlas with per-frame margins saves roughly 20-35%.
  - Do **not** VRAM-compress the character sheets: the bible bans it, and the edges suffer.
- **Old waste removed by the swap.**
  - The sentry was 14.3 source px per world px.
  - The vent was 10.3 and the arm and bolt panels 6.7-7.1.
  - The 512² padded canvases were 20-35% empty.
  - Two runtime-compiled copies of `WHEEL_MASK`.
- **Audio (keep):** 2.6 MB of mono 16-bit PCM WAV. Optional: `compress/mode` QOA or IMA-ADPCM on the loops cuts memory about 4x. Verify loop seams by ear before claiming it.
- **Fonts (keep):** 1.2 MB of variable TTFs. Latin subsetting is optional and should keep the same look.

## 8. Risks and ordering

1. Merge **codex/logic-round-3** first. It edits `junction_room.gd` (junction staging and the opening hatch), which overlaps the hatch constants, HatchDoorway and station x values that this swap changes. The worktree had no commits or changes when I checked.
2. Station footprint changes move gameplay x values and their tests:
   - breaker 11 narrower
   - relay 10 narrower
   - bolt panel 7 wider
   - arm 23 taller
   - vent 27 taller
   `JUNCTION_STATIONS`, `BOLT_X`, `WOLF_SEAM_X`, `WOLF_CLEAR_X` and the alcove cover all derive from the `*_HALF_WIDTH` values. Re-run the follow-spacing and junction tests, and play the routes before claiming feel.
3. **Doors cannot be deleted before the shutter layers exist.** Doing so would leave the corridor seal and the junction blast door with no art. The same applies to `corridor-bulkhead-open`, which the junction exit hatch passage still uses.
4. Walk3 is mid-fix. Do not import the current sheets.
5. None of the HQ art has been checked in the engine. Validation still needed: Godot stills at 960x540, 1280x720 and 1920x1080, hands-on play of the corridor, Records and junction routes, and a phone test.
