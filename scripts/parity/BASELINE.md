# Parity harness and baseline (S00 and S00a of the lighter-game plan)

The gate for every behaviour-identical step of `docs/research-2026-10/lighter-game/PLAN.md`, with
the corrections in `CRITIQUE.md` applied. It lives outside `res://`, so nothing here ships, and no
Godot window opens on the developer's machine: rendered captures run through
`tools/render/render.sh` (Godot 4.7.2 in a container with a virtual screen and software OpenGL),
and everything else runs with `godot --headless` under an isolated `HOME`.

**Baseline commit: `baffea4`** ("Keep logo-skip presses off the title and apply saved window at
launch"). Every baseline below (stills, text and audio logs, UI dump, perf "before") and the S00a
maps were taken from `apps/game` at that commit (a copy for the perf "before", the identical
working tree for the rest). `origin/main` then gained `da5c14e` (PR #55), which changes
only Markdown under `docs/` and the root notes, so `apps/game` is byte-identical and the baseline
holds for it. The first harness commit was measured on `b98bc94`; `baffea4` moved `RESOLUTIONS` and
`DEFAULT_RESOLUTION` into `GameSettings` and changed the changelog, so everything was re-taken.
Before each later step, if `origin/main` has gained commits that could change pixels, UI text or
sound calls, re-take the baseline from the step's starting commit with this same harness (the
driver at the same version) and record the commit here.

## Files

| File | What it does |
|---|---|
| `run.sh` | `capture` (render container), `ui` and `perf` (headless). See its header for arguments and environment. |
| `capture.gd` | Input-driven capture driver: routes R1-R4, fixed seeds, stills, text and audio logs, controller stills and mid-play device switches. |
| `parity_sfx_bank.gd` | SfxBank subclass the driver swaps in to log every `play`, `play_blend`, `stop` and `stop_all` by frame. |
| `compare.py` | Compares two capture folders still by still with an exact count of changed pixels (any channel, any amount), and their text and audio logs byte for byte. `--self-test` checks the count on known changes. |
| `ui_dump.gd` | Headless resolved-property dump (rect, alpha, font, size, colour, stylebox, text) of every visible HUD and menu control in 13 states. |
| `perf.gd` | Headless CPU-side probe: startup (including `load(main.tscn)`), per-state frame and `_process` time, `_refresh_ui` µs, the junction room's and its Recesses' `_draw` µs, junction redraws per frame, counts. |
| `perf_summary.py` | Before/after table of perf runs (medians). |
| `surface.py` | The code-size figures and the surface tests and debug tools use on Main (S00a map refresh). |

## Running it

```sh
# Captures: every route, size and variant (36 runs; about 100 minutes with 4 routes at once).
PARITY_NAME=<unique job prefix> PARITY_JOBS=4 scripts/parity/run.sh capture <out>
python3 -I scripts/parity/compare.py <baseline> <out> --diffs <diff folder>
python3 -I scripts/parity/compare.py --self-test

# UI dump and perf (headless; HOME must point at scratch user data).
PARITY_HOME=<scratch home> PARITY_WORK=<scratch> scripts/parity/run.sh ui <file>
PARITY_HOME=<scratch home> PARITY_WORK=<scratch> scripts/parity/run.sh perf <dir> <label>
python3 -I scripts/parity/perf_summary.py <before dir> <after dir>
```

`PARITY_GAME=<folder>` points any command at another copy of `apps/game`, for example a
`git archive` of the baseline commit. Give every capture job its own `PARITY_NAME`: render.sh jobs
with the same name share one cache folder. `capture` also takes a route list, a size list and a
variant list (`run.sh capture <out> "R3" "960x540" "kb-calm"`) for spot runs; compare those with
`compare.py --subset`.

## Routes, sizes and variants

Sizes: 960x540, 1280x720 and 2340x1080 (the phone landscape aspect, at full size; the stretch aspect
is "keep", so its stills are the 1920x1080 picture inside the bars). Variants: `kb-fx` (keyboard,
effects on), `kb-calm` (keyboard, effects off and Reduced Motion) and `touch-fx` (touch layout,
effects on; choices answered with the on-screen buttons). 4 routes x 3 sizes x 3 variants = 36 runs,
212 stills per variant and size, 1,908 stills in all.

Every route takes controller-prompt stills (a trigger pull, then back to the variant's own
prompts). R2, R3 and R4 also switch device mid-play at a station (critique C6): from the variant's
own layout to a controller (still), then a screen touch (still), then a key. The driver fails the
run unless the context hint changes to the controller prompts and comes back unchanged after the
touch and after the key, and, in the touch runs, the USE button hides for the controller and
returns for the touch. That catches a prompt cached per device or binding (S01) going stale.

| Route | Stills | What it covers |
|---|---:|---|
| R1 title and menus | 21 | Title reveal; Credits at the top and part-scrolled; Changelog at the top and scrolled; title with controller prompts; Settings Display, Audio and Controls tabs, a rebind prompt and the saved binding; Pause during the opening (SKIP OPENING); the opening skipped; the rebound key in a hint (checked: the hint starts with F); Pause in play, its Settings and back; the title's Continue with a save; Continue to the safe point; END OF SLICE; back to the title. |
| R2 corridor | 51 | The opening beat by beat; Pause while the objective card slides in; first control; a 6-frame camera pan; the breaker, with a device switch; the relay question (resized to 3/4 and back, and with controller prompts); disclose and signal WOLF (seal at 0, mid and open; a resize in play; safe point; the cut to Records as 5 frames); press, the refusal and the manual bypass let go part way, then finished; disclose and crank the bypass without WOLF. |
| R3 Records | 25 | From a Records entry save: the purge queue, with a device switch, and the purge copy; the mirror question (also with controller prompts) and WOLF's readout; Continue from a save just after the purge copy; the question again and the manual port; the exit lift; the chapter close (paused while it frames); the cut to the junction as 5 frames. |
| R4 junction to the end | 115 | From a junction entry save: the breaker and the line; the vent knockdown as 6 frames, paused mid-fall, the card and the restore; the valve, with a device switch, and the crank; the fuse as 32 consecutive frames and the blast (8 frames, every 2nd); the lane question (also with controller prompts) and WOLF drawing the sentry; the sentry fixated; the tank drop as 30 consecutive frames; the bolt, the hatch sliding and open; the walk-out (8 frames); END OF SLICE; then from a post-blast save the engineer alone, the sentry's patrol, chase and knockdown, and the restore. |

The consecutive fuse and tank-drop sequences are what critique C1 asks S02 to compare (the
junction's redraw changes). The driver fails a run (and `run.sh` reports `FAIL`) when a button it
presses is hidden or disabled, a choice it answers is not open, a beat it waits for never comes, a
device switch leaves the wrong prompts, or, before any still, no new frame was drawn or the frame
had 0 draw calls (critique C13). Equal draw-call counts on consecutive stills are normal on a still
screen, so the count itself is not required to change; `shots.json` records it per still.

## Determinism

- `--fixed-fps 60`, so every frame is 1/60 s of game time whatever the machine does.
- The rooms' lamp flicker generators (`RoomDepth._rng`) are seeded and their motion restarted.
- Every `CPUParticles2D` gets `use_fixed_seed = true` and a fixed `seed` as it enters the tree, so no
  particle rectangle needs masking (the `masks` list in `shots.json` stays empty).
- Saves and settings are fixture files in the container's throwaway user data; the fps limit is off
  and V-Sync off.
- Software rendering in the container is deterministic: two runs, with different render caches,
  produce identical stills.

## Thresholds

Critique C3 replaces the plan's effects-on allowance (0.1% / 0.25% of pixels at fuzz 3%): with every
particle seeded, **every still in every route, size and variant must have 0 changed pixels**, and
`text.log` (every change of the narration, `_context_hint()`, `_objective()`, the top card, the
speaker, the tutorial prompt, the touch and choice buttons and the pause and continue texts, by
frame) and `audio.log` (every SfxBank call, by frame) must be byte-identical, as must the frame
count of each run. The UI dump must diff empty. Compare render.sh captures only with render.sh
captures.

How pixels are counted: byte-identical PNGs count as 0. Otherwise ImageMagick takes the absolute
difference of each colour channel and of alpha, keeps the largest per pixel, thresholds it at 0 and
counts the pixels left, so a 1/255 change in one channel of one pixel counts as 1. `magick compare
-metric AE` is not the gate: ImageMagick 7.1.2 (the installed 7.1.2-32 Q16-HDRI) prints a weighted,
fractional AE (one pixel set to white reads 0.72, one channel of one pixel moved by 1/255 reads
0.001), and the first version of this script cut that to a whole number, which reported changed
stills as identical. `compare.py --self-test` checks the count on a 1/255 one-channel change (1), ten
white pixels (10), an alpha-only change (1), a re-encoded identical image (0) and a size mismatch
(fails), and that one changed pixel fails a whole comparison.

Texture memory (`RENDER_TEXTURE_MEM_USED`, taken per still inside the render container, because the
headless renderer reports 0) is printed by `compare.py` when it differs, as information: an
IDENTICAL step may lower it.

## Baseline (baffea4)

Captured on October 12, 2026 (about 100 minutes, 4 routes at once), on a shared, busy Mac (other
agents' builds and renders ran at the same time; Colima with 4 CPUs).

**Stills, text and audio logs.** 36 runs, 1,908 stills, in the scratch folder
`parity/baseline/` (not in the repository; 2.3 GB), taken with `capture.gd` SHA-1 `c1746c4c` and
`parity_sfx_bank.gd` `57cc689b`. Frame counts per run, the same in every size: R1 1,480; R2 3,160;
R3 1,498; R4 2,339 (`kb-fx`), 2,333 (`kb-calm`) and 2,337 (`touch-fx`). Per `kb-fx` run, `audio.log`
holds 47 (R1), 568 (R2), 917 (R3) and 11,278 (R4) SfxBank calls and `text.log` 77, 329, 121 and
196 text changes. Texture memory peaks at 69-99 MB per run (more at the larger sizes). The fewest
draw calls in any still: 28 (R3 `kb-calm`).

**Stability.** A second full run of the same driver and code, under other render.sh
job names (so other render caches), compared against the baseline: `ALL IDENTICAL: 36 run folders,
1908 stills compared` (0 changed pixels in every still; every text log, audio log and frame count
the same), and all 1,908 PNGs are byte-identical to the baseline's. One run of that pass
(R2 `kb-fx` 2340x1080) first failed while four jobs shared the machine; its log was replaced by the
re-run, which passed and matched. The likely cause is the old 1,500 s render time limit, which large
R2 and R4 runs approach under load, so the default is now 2,700 s (`PARITY_TIMEOUT`).

**Sensitivity.** Run on scratch copies of `baffea4`, one deliberate change each, R3 `kb-calm`
960x540, compared with the corrected `compare.py`:
- one character in the Records route hint (`exit.` to `exit!`): `text.log differs`, and 1 still
  with 30 changed pixels (the hint is on screen in `002-records-continued`);
- the Records EXIT plate moved 1 px (x 830 to 831): 5 stills with 364-493 changed pixels each;
- a 1/255 change to the PURGE QUEUE plate's text colour (`#ffc7c7` to `#ffc7c8`, blue channel): 4
  stills with 475 changed pixels each (every still where the plate shows that colour).

So the gate does see colour drift of one step in one channel, which is the change S03 (the shared
Palette and FxKit gradients) is most likely to cause. (The first version of this file said the
1/255 change altered no pixels; that came from the comparator bug above, not from the pixels.)

**UI dump.** `parity/baseline-ui-baffea4.txt`, 389 lines over 13 states (census: 197 nodes and 185
controls under CanvasLayer, 554 scene nodes at the title). Two headless runs are identical. Against
the `b98bc94` dump only the changelog body's text hash changed (`baffea4` added changelog lines).

**Perf "before"** (headless, `--fixed-fps 60`, unthrottled, M-series Mac under heavy load from
other agents, load average 29-42; scratch folder `parity/perf-before/`, five runs of a copy of
`baffea4`'s `apps/game` (identical to the working tree's), taken interleaved before, after, before, after in one session with five runs of the
working tree, `parity/perf-after-s00/`). Medians of the five "before" runs:

| Startup | ms |
|---|---:|
| `load(main.tscn)` | 575.6 |
| instantiate | 3.7 |
| `add_child` (every `_ready`) | 73.2 |
| first frame | 13.5 |
| load to first frame | 698.2 |
| SfxBank startup render (main thread) | 32.2 |
| load to SfxBank background clips done | 1,416.8 |

| State | frame p50 ms | frame p99 ms | `_process` span p50 ms | `_refresh_ui` µs | junction redraws / frame | junction `_draw` µs | Recesses `_draw` µs |
|---|---:|---:|---:|---:|---:|---:|---:|
| title | 0.181 | 0.785 | 0.051 | 1.8 | 0 | - | - |
| corridor start | 0.258 | 2.279 | 0.110 | 28.0 | 0 | - | - |
| corridor, relay question up | 0.342 | 1.829 | 0.135 | 83.8 | 0 | - | - |
| Records | 0.220 | 0.851 | 0.089 | 22.9 | 0 | - | - |
| junction entry | 0.294 | 0.989 | 0.123 | 23.9 | 1 | 22 | 6 |
| junction, lane question up | 0.455 | 1.835 | 0.176 | 89.5 | 1 | 23 | 7 |
| junction lane, WOLF drawing the sentry | 0.319 | 0.813 | 0.128 | 29.4 | 1 | 21 | 6 |

At the end of a run: 558 nodes, 3,474 objects, 121 resources, 127.0 MB static memory. A `_draw`
time runs from the item's `draw` signal (just before `_draw`) to a deferred call queued behind the
redraw (just after it), so about 7 µs of it is the redraw call itself, and the tick is 1 µs; the
junction and Recesses only draw while the junction is on screen. Texture memory is 0 headless; see
the per-still figures in `shots.json` instead.

Noise floor, from this before/after pair (the same game code on both sides, under that load): the
`_process` span agrees within 4%, startup medians within 5% (instantiate and the first frame, a few
milliseconds each, within 15%), `_refresh_ui` within 10%, the `_draw` times within 2 µs, frame p50
within 6% and frame p99 within 65% (single slow frames on a busy machine). Judge a step by the
`_process` span, `_refresh_ui`, `_draw` µs, redraw counts and startup medians, and treat changes
under those margins as noise; take more interleaved runs when a step's change is near them. The
render container's frame counts are only a sanity check (they must not change on an IDENTICAL
step); its frame times mean nothing.

**Headless suites.** `bun run game:check` (isolated HOME) at `baffea4` plus this harness: all
15 suites passed once (107 s). A second run, under heavy load from other agents, failed only
`debug_tools_test` ("the beam's declared box matches what it drew": the box was measured 0.4 px
higher and 2.7 px narrower than drawn), which then passed twice on its own. No file under
`apps/game` differs from `baffea4`, so it is a load-sensitive check, like `studio_logo_test`'s
real-time fade and `sentry_test`'s leaked objects seen at `b98bc94`. Re-run a failing suite alone
before blaming a step.

## S00a: maps refreshed on baffea4

Figures from `python3 -I scripts/parity/surface.py` at `baffea4` (the critique's maps were taken at
76d3a50 and are stale). The script now also counts members tests and the debug tools name directly
(`game.SITE_URL`), methods named as strings (`Callable(game, "_show_changelog")`,
`game.has_method(...)`), and what `debug_tools.gd` reads through its `main` parameter.

What changed against the critique's lists:
- main.gd is 3,740 lines (not 3,310) with 200 top-level functions and 126 constants; `scripts/*.gd`
  is 10,261 lines (not about 9,270), including `studio_logo.gd` (289). Since `b98bc94`, `baffea4`
  moved `RESOLUTIONS` and `DEFAULT_RESOLUTION` from Main to `GameSettings` (no test or debug tool
  reads them on Main).
- Tests read **29** constants from Main, not 15. All of the critique's 15 are still defined;
  `GAMEPLAY_ZOOM` is now only named in a comment (room_depth_test 31), so 14 of them are read, plus
  15 added since: `WOLF_FEET_BELOW_CENTRE`, `WOLF_DRAWN_HEIGHT`, `WOLF_SENTRY_GAP`, `FALL_DEGREES`,
  `FALL_SHIFT`, `BAIT_NO_LINE`, `CHECKPOINT_TOAST`, `FAIL_CONTROLS_OFF_SECONDS`,
  `FAIL_FADE_SECONDS`, `GAMEPLAY_VIEW_WIDTH`, `NO_CHECKPOINT_NOTE`, `RELAY_QUESTION`,
  `RESTORE_FROM_DISK_LINE`, and `SITE_URL` and `CHANGELOG_URL` (read as `game.SITE_URL` and
  `game.CHANGELOG_URL`, ui_controls_test 26). Keep all 29, and `GAMEPLAY_ZOOM`, readable on Main
  (`get_script_constant_map()`, `Main.X` or a member read on the instance).
- Tests use 64 methods on Main (62 private: 62 through `game.call`, plus `_show_changelog` and
  `_open_changelog` named in `Callable(game, ...)`), read 68 properties and set 13 (the plan said
  44, 51 and 12), and use 64 node paths under Main.
- `opening_hatch` and `OpeningHatch` appear only in m0_scene_test 103, which checks they are gone
  (round 3's trial opening hatch was removed), so the critique's opening-hatch items are moot.
- The debug tools (`scripts/debug/`, 3,771 lines) use 60 members of Main (through `game.` and,
  in `debug_tools.gd`, `main.`), 23 constants and the 19-function public `debug_*` surface listed
  below; keep all of them.

### Code size

| File | Lines |
|---|---:|
| `scripts/bypass_handle.gd` | 199 |
| `scripts/containment_cage.gd` | 40 |
| `scripts/drop_arm.gd` | 138 |
| `scripts/floor_reflection.gd` | 115 |
| `scripts/fx_presets.gd` | 98 |
| `scripts/game_settings.gd` | 553 |
| `scripts/hazard.gd` | 59 |
| `scripts/hold_use.gd` | 44 |
| `scripts/impact.gd` | 192 |
| `scripts/junction_room.gd` | 1345 |
| `scripts/m0_actor.gd` | 179 |
| `scripts/m0_state.gd` | 395 |
| `scripts/main.gd` | 3740 |
| `scripts/pause_overlay.gd` | 23 |
| `scripts/pressure_line.gd` | 128 |
| `scripts/records_room.gd` | 149 |
| `scripts/room_depth.gd` | 642 |
| `scripts/seal_leaf.gd` | 58 |
| `scripts/sentry.gd` | 364 |
| `scripts/sentry_brain.gd` | 287 |
| `scripts/sfx_bank.gd` | 1179 |
| `scripts/studio_logo.gd` | 289 |
| `scripts/ui_motion.gd` | 45 |
| **`scripts/*.gd` total** | **10261** |
| `scripts/debug/*.gd` (5 files) | 3771 |
| `tests/*_test.gd` (15 files) | 7355 |
| `scenes/main.tscn` | 911 |
| `scenes/studio_logo.tscn` | 109 |

main.gd: 3740 lines, 200 top-level functions, 126 const, 153 var (including @onready and @export), `status_line =` assigned 94 times, `state.chapter_id` read 40 times.

### Tests: what they use on Main

Methods called with `game.call` (62): `_context_hint` (45), `_refresh_ui` (43), `_finish_intro` (35), `_new_game` (35), `_load_game` (24), `_objective` (22), `_pause_game` (15), `_sync_scene` (13), `_resume_game` (8), `_update_controls` (8), `_fail_beat` (7), `_interact` (6), `_return_to_title` (6), `_save_progress` (6), `_start_gameplay_camera` (6), `_process` (5), `_advance_intro` (4), `_interact_checkpoint` (4), `_resolution_size` (4), `_show_end_card` (4), `_cancel_fail` (3), `_drop_ready` (3), `_finish_chapter_close` (3), `_handle_back` (3), `_note_input_device` (3), `_refresh_continue` (3), `_title_first_button` (3), `_update_gameplay_camera` (3), `debug_snapshot` (3), `end_card_recap` (3), `_bait_holding` (2), `_debug_spares_knockdown` (2), `_hide_title_overlay` (2), `_hold_station` (2), `_input` (2), `_on_fps_selected` (2), `_on_reduced_motion_changed` (2), `_on_settings_back` (2), `_tank_miss` (2), `_answer_choice` (1), `_ask_relay` (1), `_choose` (1), `_close_end_card` (1), `_debug_sentry_frozen` (1), `_door_blast` (1), `_drop_waits_for_wolf` (1), `_enter_junction` (1), `_first_name` (1), `_hide_end_card` (1), `_interact_breaker` (1), `_interact_relay` (1), `_leave_junction` (1), `_on_resolution_selected` (1), `_save_settings` (1), `_sentry_reason` (1), `_show_credits` (1), `_show_pause_menu` (1), `_show_settings` (1), `_show_title_settings` (1), `_stop_junction_loops` (1), `_sync_door` (1), `_tank_hit` (1)

Methods named in `Callable(game, ...)` or `game.has_method(...)` (2): `_open_changelog` (1), `_show_changelog` (1)

Members of Main used directly as `game.<name>` (2): `CHANGELOG_URL` (1), `SITE_URL` (1)

Methods tests use on Main, by either route: 64 (62 private)

Properties read with `game.get` (68): `status_line` (92), `state` (67), `fail_active` (47), `title_open` (38), `intro_active` (16), `save_path` (16), `waiting_for_choice` (16), `junction_room` (15), `sentry_brain` (14), `end_card_active` (10), `bypass_ticks` (9), `impact` (8), `intro_step` (8), `wolf_baiting` (8), `chapter_close_active` (7), `lane_choice` (7), `records_room` (7), `drop_arm` (6), `pause_overlay` (6), `pressure_line` (6), `bypass_handle` (5), `tutorial_step` (5), `wolf_scouting` (5), `engineer_step_x` (4), `seal_opening` (4), `settings_menu` (4), `sfx_bank` (4), `bolt_state` (3), `controller_active` (3), `door_lip` (3), `engineer_waits_for_wolf` (3), `hatch_exit_walking` (3), `wolf_heading_to_relay` (3), `beat_snapshot` (2), `bypass_venting` (2), `choice_context` (2), `continue_button` (2), `credits_paused` (2), `effects_enabled` (2), `relay_refused` (2), `save_pending` (2), `stakes_spoken` (2), `wolf_broke_off` (2), `wolf_holding_far_end` (2), `wolf_sprite_scale` (2), `breaker_status_glow` (1), `bypass_was_holding` (1), `changelog_text` (1), `corridor_depth` (1), `credits_screen` (1), `debug_tools` (1), `door_dust` (1), `door_open_art` (1), `fps_options` (1), `intro_camera` (1), `intro_fade` (1), `intro_tween` (1), `name_card_remaining` (1), `opening_hatch` (1), `post_grade` (1), `relay_sparks` (1), `relay_status_glow` (1), `resolution_options` (1), `save_error` (1), `seal_leaf` (1), `touch_choice_1` (1), `touch_choice_2` (1), `touch_use` (1)

Properties set with `game.set` (13): `touch_enabled` (46), `save_path` (21), `settings_path` (15), `state` (11), `waiting_for_choice` (9), `auto_pause_on_focus_loss` (6), `controller_active` (6), `effects_enabled` (6), `lane_choice` (4), `status_line` (2), `tutorial_step` (2), `bolt_state` (1), `chapter_close_active` (1)

Main constants read (29): `WOLF_FEET_BELOW_CENTRE` (4), `STATION_OVERLAP` (3), `VALVE_CRANK_X` (3), `WOLF_BYPASS_CLEAR_X` (3), `WOLF_DRAWN_HEIGHT` (3), `WOLF_SENTRY_GAP` (3), `BYPASS_CRANK_X` (2), `CORRIDOR_DOOR_LEFT_X` (2), `FALL_DEGREES` (2), `FALL_SHIFT` (2), `JUNCTION_STATIONS` (2), `RECORDS_STATIONS` (2), `WOLF_MIRROR_X` (2), `BAIT_NO_LINE` (1), `BOLT_WHINE_SECONDS` (1), `BYPASS_WHEEL` (1), `CHANGELOG_URL` (1), `CHECKPOINT_TOAST` (1), `CORRIDOR_STATIONS` (1), `FAIL_CONTROLS_OFF_SECONDS` (1), `FAIL_FADE_SECONDS` (1), `GAMEPLAY_CAMERA_Y_TOUCH` (1), `GAMEPLAY_VIEW_WIDTH` (1), `INTRO_LINES` (1), `NO_CHECKPOINT_NOTE` (1), `RELAY_QUESTION` (1), `RELAY_X` (1), `RESTORE_FROM_DISK_LINE` (1), `SITE_URL` (1)

Node paths under Main (64 unique, `game.get_node`): `BreakerArt`, `BreakerLabel`, `BreakerStatusLight`, `CanvasLayer/BottomBar`, `CanvasLayer/BottomBar/Speaker`, `CanvasLayer/BottomBar/Story`, `CanvasLayer/ContextHint`, `CanvasLayer/ContextHint/Text`, `CanvasLayer/EndCard`, `CanvasLayer/IntroAlarm`, `CanvasLayer/IntroFade`, `CanvasLayer/PauseButton`, `CanvasLayer/PauseOverlay`, `CanvasLayer/PauseOverlay/Panel/PauseMenu`, `CanvasLayer/PauseOverlay/Panel/PauseMenu/ResumeButton`, `CanvasLayer/PauseOverlay/Panel/PauseMenu/SettingsButton`, `CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton`, `CanvasLayer/PauseOverlay/Panel/SettingsMenu`, `CanvasLayer/PauseOverlay/Panel/SettingsMenu/BackButton`, `CanvasLayer/PauseOverlay/Panel/SettingsMenu/FPSOptions`, `CanvasLayer/TitleScreen`, `CanvasLayer/TitleScreen/ChangelogButton`, `CanvasLayer/TitleScreen/ChangelogScreen`, `CanvasLayer/TitleScreen/ContinueButton`, `CanvasLayer/TitleScreen/ContinueNote`, `CanvasLayer/TitleScreen/CorridorArt`, `CanvasLayer/TitleScreen/CreditsButton`, `CanvasLayer/TitleScreen/CreditsScreen`, `CanvasLayer/TitleScreen/CreditsScreen/CreditsBackButton`, `CanvasLayer/TitleScreen/CreditsScreen/CreditsPauseButton`, `CanvasLayer/TitleScreen/GameTitle`, `CanvasLayer/TitleScreen/LogoMark`, `CanvasLayer/TitleScreen/NewGameButton`, `CanvasLayer/TitleScreen/SettingsButton`, `CanvasLayer/TopBar`, `CanvasLayer/TopBar/Accent`, `CanvasLayer/TopBar/HUD`, `CanvasLayer/TouchControls`, `CanvasLayer/TouchControls/Choice1`, `CanvasLayer/TouchControls/Choice2`, `CanvasLayer/TouchControls/Use`, `CanvasLayer/TutorialPrompt`, `CanvasLayer/TutorialPrompt/Text`, `CheckpointArt`, `CheckpointLabel`, `CorridorDepth`, `Door/CollisionShape2D`, `Door/Visual`, `Door/Visual/DoorArt`, `Human`, `Human/BodySprite`, `Human/CollisionShape2D`, `IntroCamera`, `IntroDirector`, `IntroGate`, `OpeningHatch`, `PurgeTerminalArt`, `RelayArt`, `RelayLabel`, `RelaySpark`, `RelayStatusLight`, `Wolf`, `Wolf/BodySprite`, `Wolf/CollisionShape2D`

Private methods (leading underscore) tests call (62): `_advance_intro`, `_answer_choice`, `_ask_relay`, `_bait_holding`, `_cancel_fail`, `_choose`, `_close_end_card`, `_context_hint`, `_debug_sentry_frozen`, `_debug_spares_knockdown`, `_door_blast`, `_drop_ready`, `_drop_waits_for_wolf`, `_enter_junction`, `_fail_beat`, `_finish_chapter_close`, `_finish_intro`, `_first_name`, `_handle_back`, `_hide_end_card`, `_hide_title_overlay`, `_hold_station`, `_input`, `_interact`, `_interact_breaker`, `_interact_checkpoint`, `_interact_relay`, `_leave_junction`, `_load_game`, `_new_game`, `_note_input_device`, `_objective`, `_on_fps_selected`, `_on_reduced_motion_changed`, `_on_resolution_selected`, `_on_settings_back`, `_open_changelog`, `_pause_game`, `_process`, `_refresh_continue`, `_refresh_ui`, `_resolution_size`, `_resume_game`, `_return_to_title`, `_save_progress`, `_save_settings`, `_sentry_reason`, `_show_changelog`, `_show_credits`, `_show_end_card`, `_show_pause_menu`, `_show_settings`, `_show_title_settings`, `_start_gameplay_camera`, `_stop_junction_loops`, `_sync_door`, `_sync_scene`, `_tank_hit`, `_tank_miss`, `_title_first_button`, `_update_controls`, `_update_gameplay_camera`

The critique's 15 constants: `BYPASS_CRANK_X` (read by tests, defined), `BYPASS_WHEEL` (read by tests, defined), `CORRIDOR_DOOR_LEFT_X` (read by tests, defined), `CORRIDOR_STATIONS` (read by tests, defined), `INTRO_LINES` (read by tests, defined), `JUNCTION_STATIONS` (read by tests, defined), `RECORDS_STATIONS` (read by tests, defined), `RELAY_X` (read by tests, defined), `STATION_OVERLAP` (read by tests, defined), `WOLF_BYPASS_CLEAR_X` (read by tests, defined), `WOLF_MIRROR_X` (read by tests, defined), `GAMEPLAY_ZOOM` (not read in test code now, defined), `GAMEPLAY_CAMERA_Y_TOUCH` (read by tests, defined), `VALVE_CRANK_X` (read by tests, defined), `BOLT_WHINE_SECONDS` (read by tests, defined)

Used by tests but not defined at the top level of main.gd (inherited or a bug): `opening_hatch`

### Debug tools: what they use on Main

Members of Main used through `game.` or `main.` in scripts/debug (60): `state` (7), `impact` (5), `effects_enabled` (4), `pause_overlay` (4), `pressure_line` (4), `save_path` (4), `title_open` (4), `controller_active` (3), `debug_new_game` (3), `end_card` (3), `human` (3), `junction_room` (3), `debug_interact` (2), `debug_load_checkpoint` (2), `debug_place` (2), `debug_station_side_x` (2), `drop_arm` (2), `intro_camera` (2), `sentry_brain` (2), `touch_choice_1` (2), `touch_choice_2` (2), `touch_enabled` (2), `tutorial_prompt` (2), `wolf` (2), `changelog_screen` (1), `chapter_close_active` (1), `context_hint_text` (1), `credits_screen` (1), `debug_answer_lane` (1), `debug_beat` (1), `debug_drop_tank` (1), `debug_hold_station` (1), `debug_knock_down` (1), `debug_refresh_ui` (1), `debug_restore_focus` (1), `debug_save_changed` (1), `debug_save_progress` (1), `debug_show_end_card` (1), `debug_snapshot` (1), `debug_valve_turned` (1), `debug_wolf_target` (1), `debug_wolf_why` (1), `end_card_active` (1), `fail_active` (1), `hold_use` (1), `hud` (1), `intro_active` (1), `pause_button` (1), `save_pending` (1), `settings_menu` (1), `settings_path` (1), `speaker` (1), `story` (1), `title_mark` (1), `title_screen` (1), `touch_left` (1), `touch_right` (1), `touch_use` (1), `tutorial_text` (1), `waiting_for_choice` (1)

Main constants read in scripts/debug (23): `CORRIDOR_STATIONS` (3), `JUNCTION_STATIONS` (2), `RECORDS_STATIONS` (2), `WOLF_MIRROR_X` (2), `BYPASS_CRANK_X` (1), `BYPASS_REACH` (1), `BYPASS_WHEEL` (1), `CHECKPOINT_TOAST` (1), `CORRIDOR_DOOR_LEFT_X` (1), `GAMEPLAY_ACTIONS` (1), `GAMEPLAY_VIEW_WIDTH` (1), `NO_CHECKPOINT_NOTE` (1), `PURGE_DISPLAY_MAX_X` (1), `RELAY_CONTACT_X` (1), `RELAY_REACH` (1), `RELAY_SIDE_X` (1), `RELAY_STEP_BACK_X` (1), `RELAY_X` (1), `RESTORE_FROM_DISK_LINE` (1), `SAVE_FAILED_HINT` (1), `UNREADABLE_CHECKPOINT_NOTE` (1), `VALVE_CRANK_X` (1), `WOLF_BYPASS_CLEAR_X` (1)

The public debug surface on Main: `debug_answer_lane`, `debug_beat`, `debug_drop_tank`, `debug_hold_station`, `debug_interact`, `debug_knock_down`, `debug_load_checkpoint`, `debug_new_game`, `debug_place`, `debug_refresh_ui`, `debug_restore_focus`, `debug_save_changed`, `debug_save_progress`, `debug_show_end_card`, `debug_snapshot`, `debug_station_side_x`, `debug_valve_turned`, `debug_wolf_target`, `debug_wolf_why`

### main.gd functions (first and last line)

| Function | Lines | Length |
|---|---|---:|
| `_ready` | 469-547 | 79 |
| `_refresh_continue` | 550-566 | 17 |
| `_title_first_button` | 570-571 | 2 |
| `_on_continue_pressed` | 576-581 | 6 |
| `_open_changelog` | 585-587 | 3 |
| `_load_changelog` | 590-596 | 7 |
| `_changelog_bbcode` | 600-610 | 11 |
| `_show_changelog` | 613-616 | 4 |
| `_hide_changelog` | 619-621 | 3 |
| `_setup_corridor_door` | 626-635 | 10 |
| `_setup_bypass` | 640-645 | 6 |
| `_setup_corridor_labels` | 650-659 | 10 |
| `_apply_effects` | 663-674 | 12 |
| `_room_depths` | 678-679 | 2 |
| `_sync_room_lights` | 686-689 | 4 |
| `_setup_impact` | 694-703 | 10 |
| `_on_reduced_motion_changed` | 708-713 | 6 |
| `_setup_particles` | 718-735 | 18 |
| `_attach_status_glow` | 739-744 | 6 |
| `_update_gameplay_camera` | 747-750 | 4 |
| `_start_gameplay_camera` | 753-758 | 6 |
| `_process` | 761-818 | 58 |
| `_tick_engineer_step` | 823-831 | 9 |
| `_step_engineer` | 835-844 | 10 |
| `_step_beside_station` | 851-861 | 11 |
| `_update_settle` | 868-878 | 11 |
| `_settle_safe` | 883-890 | 8 |
| `_fuse_lit` | 894-895 | 2 |
| `_first_name` | 899-900 | 2 |
| `_clear_station_body` | 906-913 | 8 |
| `_room_stations` | 918-925 | 8 |
| `_station_offset` | 929-930 | 2 |
| `_station_side_x` | 935-937 | 3 |
| `_tick_corridor` | 943-974 | 32 |
| `_read_seconds` | 978-979 | 2 |
| `_speak_stakes` | 982-984 | 3 |
| `_stakes_up` | 988-989 | 2 |
| `_at_breaker` | 993-994 | 2 |
| `_ask_relay` | 998-1002 | 5 |
| `_new_game` | 1005-1063 | 59 |
| `_advance_intro` | 1067-1112 | 46 |
| `_finish_intro` | 1115-1148 | 34 |
| `_show_credits` | 1151-1156 | 6 |
| `_hide_credits` | 1159-1161 | 3 |
| `_show_title_overlay` | 1166-1170 | 5 |
| `_hide_title_overlay` | 1173-1177 | 5 |
| `_toggle_credits_pause` | 1180-1182 | 3 |
| `_on_credits_body_input` | 1185-1188 | 4 |
| `_on_changelog_body_input` | 1193-1201 | 9 |
| `_setup_touch_controls` | 1204-1212 | 9 |
| `_bind_touch_button` | 1215-1217 | 3 |
| `_setup_settings` | 1220-1251 | 32 |
| `_resolution_size` | 1254-1255 | 2 |
| `_on_fps_selected` | 1258-1260 | 3 |
| `_on_resolution_selected` | 1263-1266 | 4 |
| `_on_fullscreen_toggled` | 1269-1272 | 4 |
| `_save_settings` | 1275-1281 | 7 |
| `_on_pause_button` | 1284-1285 | 2 |
| `_pause_game` | 1288-1298 | 11 |
| `_resume_game` | 1301-1307 | 7 |
| `_show_settings` | 1310-1317 | 8 |
| `_show_title_settings` | 1320-1324 | 5 |
| `_fade_backdrop` | 1329-1334 | 6 |
| `_reveal_menu` | 1337-1345 | 9 |
| `_show_pause_menu` | 1348-1364 | 17 |
| `_return_to_title` | 1367-1392 | 26 |
| `_grab_menu_focus` | 1397-1403 | 7 |
| `_menu_focus_target` | 1407-1418 | 12 |
| `_unhandled_input` | 1421-1439 | 19 |
| `_notification` | 1442-1449 | 8 |
| `_handle_back` | 1453-1471 | 19 |
| `_on_title_button` | 1474-1479 | 6 |
| `_on_settings_back` | 1482-1485 | 4 |
| `_input` | 1488-1495 | 8 |
| `_answer_choice` | 1499-1506 | 8 |
| `_note_input_device` | 1510-1533 | 24 |
| `_load_game` | 1536-1605 | 70 |
| `_interact` | 1608-1636 | 29 |
| `_at_bypass` | 1641-1642 | 2 |
| `_at_relay` | 1647-1648 | 2 |
| `_relay_refused` | 1653-1654 | 2 |
| `_interact_breaker` | 1657-1673 | 17 |
| `_choose` | 1676-1688 | 13 |
| `_interact_relay` | 1694-1719 | 26 |
| `_wolf_takes_relay` | 1724-1734 | 11 |
| `_interact_bypass` | 1739-1748 | 10 |
| `_start_bypass_vent` | 1753-1759 | 7 |
| `_stop_bypass_vent` | 1762-1767 | 6 |
| `_bypass_cranked` | 1773-1785 | 13 |
| `_finish_bypass` | 1788-1800 | 13 |
| `_interact_checkpoint` | 1803-1829 | 27 |
| `_interact_records` | 1832-1876 | 45 |
| `_records_route_hint` | 1881-1886 | 6 |
| `_finish_chapter_close` | 1889-1903 | 15 |
| `_walk_out_through_hatch` | 1909-1917 | 9 |
| `_engineer_follows_out` | 1922-1931 | 10 |
| `_build_end_card` | 1936-1982 | 47 |
| `_end_card_label` | 1985-1994 | 10 |
| `end_card_recap` | 2000-2017 | 18 |
| `_show_end_card` | 2020-2057 | 38 |
| `_close_end_card` | 2061-2064 | 4 |
| `_hide_end_card` | 2067-2069 | 3 |
| `_choose_mirror` | 2072-2086 | 15 |
| `_save_progress` | 2089-2092 | 4 |
| `_write_beat` | 2096-2104 | 9 |
| `_capture_positions` | 2107-2111 | 5 |
| `_mark_beat` | 2116-2118 | 3 |
| `_hold_station` | 2123-2128 | 6 |
| `_enter_junction` | 2132-2143 | 12 |
| `_interact_junction` | 2146-2188 | 43 |
| `_at_arm_panel` | 2192-2193 | 2 |
| `_bait_holding` | 2199-2200 | 2 |
| `_drop_waits_for_wolf` | 2206-2207 | 2 |
| `_wolf_drawing_x` | 2212-2213 | 2 |
| `_use_arm_panel` | 2216-2229 | 14 |
| `_drop_tank` | 2234-2240 | 7 |
| `_use_exit` | 2245-2261 | 17 |
| `_pop_bolt` | 2264-2269 | 6 |
| `_bolt_arc` | 2274-2286 | 13 |
| `_hatch_sliding` | 2290-2291 | 2 |
| `_hatch_opened` | 2295-2297 | 3 |
| `_leave_junction` | 2302-2314 | 13 |
| `_frame_chapter_close` | 2319-2321 | 3 |
| `_tick_junction` | 2326-2364 | 39 |
| `_tick_lane` | 2371-2432 | 62 |
| `_sync_wolf_leap` | 2439-2455 | 17 |
| `_sentry_reason` | 2461-2462 | 2 |
| `_seen_in_lane` | 2467-2468 | 2 |
| `_lane_sound` | 2474-2493 | 20 |
| `_sentry_changed` | 2496-2509 | 14 |
| `_sentry_alarm` | 2513-2514 | 2 |
| `_ask_lane` | 2519-2523 | 5 |
| `_choose_lane` | 2528-2550 | 23 |
| `_tank_hit` | 2554-2580 | 27 |
| `_tank_miss` | 2586-2605 | 20 |
| `_tank_rehung` | 2608-2611 | 4 |
| `_fade_servo` | 2615-2623 | 9 |
| `_kill_servo_tween` | 2626-2629 | 4 |
| `_stop_junction_loops` | 2632-2634 | 3 |
| `_valve_turned` | 2638-2645 | 8 |
| `_vent_trips` | 2650-2658 | 9 |
| `_wolf_reads_seam` | 2661-2666 | 6 |
| `_door_blast` | 2674-2690 | 17 |
| `_blast_feedback` | 2693-2699 | 7 |
| `_fail_beat` | 2707-2746 | 40 |
| `_lane_fall` | 2753-2765 | 13 |
| `_restore_beat` | 2768-2795 | 28 |
| `_cancel_fail_tween` | 2798-2801 | 4 |
| `_cancel_fail` | 2805-2810 | 6 |
| `_shutter_boom` | 2814-2819 | 6 |
| `_door_lands` | 2824-2832 | 9 |
| `_sync_scene` | 2835-2892 | 58 |
| `_sync_junction_room` | 2897-2917 | 21 |
| `_react_as_wolf` | 2920-2932 | 13 |
| `_flash_relay_spark` | 2937-2967 | 31 |
| `_sync_records_room` | 2970-2984 | 15 |
| `_sync_door` | 2990-3009 | 20 |
| `_update_controls` | 3012-3026 | 15 |
| `_wolf_target_x` | 3034-3070 | 37 |
| `_wolf_off_relay` | 3077-3082 | 6 |
| `_machine_spans` | 3088-3102 | 15 |
| `_wolf_follow_max_x` | 3107-3112 | 6 |
| `_refresh_ui` | 3115-3214 | 100 |
| `_set_dialogue` | 3217-3251 | 35 |
| `_show_top_card` | 3254-3264 | 11 |
| `_context_hint` | 3267-3321 | 55 |
| `_junction_hint` | 3324-3354 | 31 |
| `_lane_asked` | 3358-3359 | 2 |
| `_sentry_hunting` | 3363-3364 | 2 |
| `_drop_ready` | 3369-3370 | 2 |
| `_lane_hint` | 3373-3409 | 37 |
| `_objective` | 3412-3443 | 32 |
| `_install_inputs` | 3446-3463 | 18 |
| `_add_action` | 3466-3476 | 11 |
| `_add_joy_button` | 3479-3483 | 5 |
| `_add_joy_axis` | 3486-3497 | 12 |
| `_setup_debug_tools` | 3500-3504 | 5 |
| `_debug_spares_knockdown` | 3509-3510 | 2 |
| `_debug_sentry_frozen` | 3514-3515 | 2 |
| `_debug_takes_back` | 3519-3525 | 7 |
| `debug_new_game` | 3528-3532 | 5 |
| `debug_load_checkpoint` | 3536-3538 | 3 |
| `debug_interact` | 3542-3543 | 2 |
| `debug_answer_lane` | 3547-3549 | 3 |
| `debug_show_end_card` | 3552-3553 | 2 |
| `debug_station_side_x` | 3557-3558 | 2 |
| `debug_place` | 3562-3567 | 6 |
| `debug_knock_down` | 3572-3582 | 11 |
| `debug_valve_turned` | 3586-3588 | 3 |
| `debug_drop_tank` | 3592-3593 | 2 |
| `debug_save_progress` | 3597-3598 | 2 |
| `debug_save_changed` | 3602-3604 | 3 |
| `debug_refresh_ui` | 3607-3608 | 2 |
| `debug_hold_station` | 3612-3613 | 2 |
| `debug_restore_focus` | 3617-3622 | 6 |
| `debug_snapshot` | 3628-3666 | 39 |
| `debug_beat` | 3669-3684 | 16 |
| `_debug_engineer_state` | 3687-3700 | 14 |
| `debug_wolf_target` | 3705-3710 | 6 |
| `debug_wolf_why` | 3714-3740 | 27 |
