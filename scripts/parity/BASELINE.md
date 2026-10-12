# Parity harness and baseline (S00 and S00a of the lighter-game plan)

The gate for every behaviour-identical step of `docs/research-2026-10/lighter-game/PLAN.md`, with
the corrections in `CRITIQUE.md` applied. It lives outside `res://`, so nothing here ships, and no
Godot window opens on the developer's machine: rendered captures run through
`tools/render/render.sh` (Godot 4.7.2 in a container with a virtual screen and software OpenGL),
and everything else runs with `godot --headless` under an isolated `HOME`.

**Baseline commit: `b98bc94`** ("Open the game on the MrDemonWolf, Inc. logo", main after PRs
#45-#53). Every baseline below (stills, text and audio logs, UI dump, perf "before") was taken from
a `git archive` of that commit's `apps/game`. Before each later step, if `origin/main` has gained
commits that could change pixels, UI text or sound calls, re-take the baseline from the step's
starting commit with this same harness and record the commit here.

## Files

| File | What it does |
|---|---|
| `run.sh` | `capture` (render container), `ui` and `perf` (headless). See its header for arguments and environment. |
| `capture.gd` | Input-driven capture driver: routes R1-R4, fixed seeds, stills, text and audio logs. |
| `parity_sfx_bank.gd` | SfxBank subclass the driver swaps in to log every `play`, `play_blend`, `stop` and `stop_all` by frame. |
| `compare.py` | Compares two capture folders still by still with `magick compare -metric AE -fuzz 0`, and their text and audio logs byte for byte. |
| `ui_dump.gd` | Headless resolved-property dump (rect, alpha, font, size, colour, stylebox, text) of every visible HUD and menu control in 13 states. |
| `perf.gd` | Headless CPU-side probe: startup, per-state frame and `_process` time, `_refresh_ui` microseconds, junction redraws per frame, counts. |
| `perf_summary.py` | Before/after table of perf runs (medians). |
| `surface.py` | The code-size figures and the surface tests and debug tools use on Main (S00a map refresh). |

## Running it

```sh
# Captures: every route, size and variant (36 runs; about 80 minutes with 4 routes at once).
PARITY_NAME=<unique job prefix> PARITY_JOBS=4 scripts/parity/run.sh capture <out>
python3 -I scripts/parity/compare.py <baseline> <out> --diffs <diff folder>

# UI dump and perf (headless; HOME must point at scratch user data).
PARITY_HOME=<scratch home> PARITY_WORK=<scratch> scripts/parity/run.sh ui <file>
PARITY_HOME=<scratch home> PARITY_WORK=<scratch> scripts/parity/run.sh perf <dir> <label>
python3 -I scripts/parity/perf_summary.py <before dir> <after dir>
```

`PARITY_GAME=<folder>` points any command at another copy of `apps/game`, for example a
`git archive` of the baseline commit. Give every capture job its own `PARITY_NAME`: render.sh jobs
with the same name share one cache folder.

## Routes, sizes and variants

Sizes: 960x540, 1280x720 and 2340x1080 (the phone landscape aspect, at full size). Variants:
`kb-fx` (keyboard, effects on), `kb-calm` (keyboard, effects off and Reduced Motion) and `touch-fx`
(touch layout, effects on; choices answered with the on-screen buttons). Each route also takes
controller-prompt stills (a trigger pull, then back to keyboard). 4 routes x 3 sizes x 3 variants
= 36 runs, 160 stills per variant and size, 1,440 stills in all.

| Route | Stills | What it covers |
|---|---:|---|
| R1 title and menus | 21 | Title reveal; Credits at the top and part-scrolled; Changelog at the top and scrolled; title with controller prompts; Settings Display, Audio and Controls tabs, a rebind prompt and the saved binding; Pause during the opening (SKIP OPENING); the opening skipped; the rebound key in a hint; Pause in play, its Settings and back; the title's Continue with a save; Continue to the safe point; END OF SLICE; back to the title. |
| R2 corridor | 49 | The opening beat by beat; Pause while the objective card slides in; first control; a 6-frame camera pan; the breaker; the relay question (resized to 3/4 and back, and with controller prompts); disclose and signal WOLF (seal at 0, mid and open; a resize in play; safe point; the cut to Records as 5 frames); press, the refusal and the manual bypass let go part way, then finished; disclose and crank the bypass without WOLF. |
| R3 Records | 22 | From a Records entry save: the purge copy; the mirror question and WOLF's readout; Continue from a save just after the purge copy; the question again and the manual port; the exit lift; the chapter close (paused while it frames); the cut to the junction as 5 frames. |
| R4 junction to the end | 68 | From a junction entry save: the breaker and the line; the vent knockdown as 6 frames, paused mid-fall, the card and the restore; the valve crank; the fuse (8 frames) and the blast (8 frames); the lane question and WOLF drawing the sentry; the sentry fixated; the tank drop as 10 frames; the bolt, the hatch sliding and open; the walk-out (8 frames); END OF SLICE; then from a post-blast save the engineer alone, the sentry's patrol, chase and knockdown, and the restore. |

The driver fails a run (and `run.sh` reports `FAIL`) when a button it presses is hidden or disabled,
a choice it answers is not open, a beat it waits for never comes, or no new frame was drawn before a
still (critique C13).

## Determinism

- `--fixed-fps 60`, so every frame is 1/60 s of game time whatever the machine does.
- The rooms' lamp flicker generators (`RoomDepth._rng`) are seeded and their motion restarted.
- Every `CPUParticles2D` gets `use_fixed_seed = true` and a fixed `seed` as it enters the tree, so no
  particle rectangle needs masking (the `masks` list in `shots.json` stays empty).
- Saves and settings are fixture files in the container's throwaway user data; the fps limit is off
  and V-Sync off.
- Software rendering in the container is deterministic: two runs, with different render caches,
  produce byte-identical PNGs.

## Thresholds

Critique C3 replaces the plan's effects-on allowance (0.1% / 0.25% of pixels at fuzz 3%): with every
particle seeded, **every still in every route, size and variant must have AE = 0 at fuzz 0**, and
`text.log` (every change of the narration, `_context_hint()`, `_objective()`, the top card, the
speaker, the tutorial prompt, the touch and choice buttons and the pause and continue texts, by
frame) and `audio.log` (every SfxBank call, by frame) must be byte-identical, as must the frame
count of each run. The UI dump must diff empty. Compare render.sh captures only with render.sh
captures.

## Baseline (b98bc94)

Taken on October 12, 2026, on a shared, busy Mac (load average 8-35 while the captures ran; Colima
with 4 CPUs).

**Stills, text and audio logs.** 36 runs, 1,440 stills, in the scratch folder
`parity/baseline/` (not in the repository; 1.6 GB). Frame counts per run, the same in every size:
R1 1,478; R2 3,118; R3 1,431; R4 2,262 (`kb-fx`), 2,256 (`kb-calm`) and 2,260 (`touch-fx`).
Per `kb-fx` run, `audio.log` holds 47 (R1), 568 (R2), 917 (R3) and 10,829 (R4) SfxBank calls and
`text.log` 77, 327, 114 and 189 text changes.

**Stability.** A second full run, from the working tree on a different render cache, compared
against the baseline: `ALL IDENTICAL: 36 run folders, 1440 stills compared` (every still AE = 0;
every text log, audio log and frame count the same). Spot runs of R1 and R3 on two more render
caches, made while the harness was built, were byte-identical too.

**Sensitivity.** Run on a scratch copy with one deliberate change each, R3 `kb-calm` 960x540:
- one character in a context hint (`.` to `!`): `text.log differs` (that hint is never on screen in
  a still, so only the log catches it);
- the Records EXIT plate moved 1 px: 5 stills over AE 0 (44-58 px each), which the plan's original
  0.1% allowance (518 px at this size) would have let through;
- a 1/255 change to the PURGE QUEUE plate's text colour: no pixel changed (the faded 12 px text
  rounds to the same bytes). Colour constants that small are caught by the UI dump only when they
  sit on a HUD or menu control; for world colours, review the diff of the change itself.

**UI dump.** `parity/baseline-ui-b98bc94.txt`, 389 lines over 13 states (census: 197 nodes and 185
controls under CanvasLayer, 554 scene nodes at the title). Two headless runs are identical.

**Perf "before"** (headless, `--fixed-fps 60`, unthrottled, M-series Mac under load; scratch folder
`parity/perf-before/`, five runs taken interleaved with five runs of the working tree,
`parity/perf-after-s00/`):

| Startup (median of 5) | ms |
|---|---:|
| `load(main.tscn)` | 511.2 |
| instantiate | 2.9 |
| `add_child` (every `_ready`) | 62.2 |
| first frame | 11.1 |
| load to first frame | 589.2 |
| SfxBank startup render (main thread) | 29.6 |
| load to SfxBank background clips done | 1,213.0 |

| State | frame p50 ms | frame p99 ms | `_process` span p50 ms | `_refresh_ui` µs | junction redraws / frame |
|---|---:|---:|---:|---:|---:|
| title | 0.153 | 0.271 | 0.046 | 1.8 | 0 |
| corridor start | 0.218 | 0.410 | 0.093 | 26.8 | 0 |
| corridor, relay question up | 0.324 | 0.534 | 0.115 | 77.8 | 0 |
| Records | 0.201 | 0.340 | 0.079 | 20.6 | 0 |
| junction entry | 0.268 | 0.426 | 0.112 | 22.0 | 1 |
| junction, lane question up | 0.391 | 0.666 | 0.148 | 80.6 | 1 |
| junction lane, WOLF drawing the sentry | 0.284 | 0.435 | 0.116 | 25.8 | 1 |

At the end of a run: 558 nodes, about 3,474 objects, 121 resources, 127.6 MB static memory.

Noise floor, from the S00 before/after pair (the same game code on both sides): `_refresh_ui` and
the `_process` span agree within 3%; frame p50 within 14% and frame p99 within 31% (single slow
frames on a busy machine), so judge a step by `_refresh_ui`, the `_process` span, redraw counts and
startup medians, and treat frame-time changes under those margins as noise. The render container's
frame counts are only a sanity check (they must not change on an IDENTICAL step); its frame times
mean nothing.

**Headless suites.** `bun run game:check` (isolated HOME) passed all 15 suites at b98bc94 plus this
harness. A first run while four render jobs were running failed `studio_logo_test` (a real-time fade
measured 0.66 s) and reported 2 leaked objects in `sentry_test`; neither involves this change (no
file under `apps/game` changed) and both passed on the rerun with less load. Treat them as
load-sensitive.

## S00a: maps refreshed on b98bc94

Figures from `python3 -I scripts/parity/surface.py` at b98bc94 (the critique's maps were taken at
76d3a50 and are stale):

What changed against the critique's lists:
- main.gd is 3,750 lines (not 3,310) with 200 top-level functions; `scripts/*.gd` is 10,179 lines
  (not about 9,270), including the new `studio_logo.gd` (225).
- Tests read **27** constants from Main, not 15. All of the critique's 15 are still defined;
  `GAMEPLAY_ZOOM` is now only named in a comment (room_depth_test 31), so 14 of them are read, plus
  13 added since: `WOLF_FEET_BELOW_CENTRE`, `WOLF_DRAWN_HEIGHT`, `WOLF_SENTRY_GAP`, `FALL_DEGREES`,
  `FALL_SHIFT`, `BAIT_NO_LINE`, `CHECKPOINT_TOAST`, `FAIL_CONTROLS_OFF_SECONDS`,
  `FAIL_FADE_SECONDS`, `GAMEPLAY_VIEW_WIDTH`, `NO_CHECKPOINT_NOTE`, `RELAY_QUESTION` and
  `RESTORE_FROM_DISK_LINE`. Keep all 27, and `GAMEPLAY_ZOOM`, readable on Main
  (`get_script_constant_map()` or `Main.X`).
- Tests call 62 methods on Main (60 private), read 68 properties and set 13 (the plan said 44, 51
  and 12), and use 64 node paths under Main.
- `opening_hatch` and `OpeningHatch` appear only in m0_scene_test 103, which checks they are gone
  (round 3's trial opening hatch was removed), so the critique's opening-hatch items are moot.
- The debug tools (`scripts/debug/`, 3,771 lines) use 58 members of Main, 23 constants and the
  19-function public `debug_*` surface listed below; keep all of them.

### Code size

| File | Lines |
|---|---:|
| `scripts/bypass_handle.gd` | 199 |
| `scripts/containment_cage.gd` | 40 |
| `scripts/drop_arm.gd` | 138 |
| `scripts/floor_reflection.gd` | 115 |
| `scripts/fx_presets.gd` | 98 |
| `scripts/game_settings.gd` | 525 |
| `scripts/hazard.gd` | 59 |
| `scripts/hold_use.gd` | 44 |
| `scripts/impact.gd` | 192 |
| `scripts/junction_room.gd` | 1345 |
| `scripts/m0_actor.gd` | 179 |
| `scripts/m0_state.gd` | 395 |
| `scripts/main.gd` | 3750 |
| `scripts/pause_overlay.gd` | 23 |
| `scripts/pressure_line.gd` | 128 |
| `scripts/records_room.gd` | 149 |
| `scripts/room_depth.gd` | 642 |
| `scripts/seal_leaf.gd` | 58 |
| `scripts/sentry.gd` | 364 |
| `scripts/sentry_brain.gd` | 287 |
| `scripts/sfx_bank.gd` | 1179 |
| `scripts/studio_logo.gd` | 225 |
| `scripts/ui_motion.gd` | 45 |
| **`scripts/*.gd` total** | **10179** |
| `scripts/debug/*.gd` (5 files) | 3771 |
| `tests/*_test.gd` (15 files) | 7319 |
| `scenes/main.tscn` | 911 |
| `scenes/studio_logo.tscn` | 109 |

main.gd: 3750 lines, 200 top-level functions, 128 const, 153 var (including @onready and @export), `status_line =` assigned 94 times, `state.chapter_id` read 40 times.

### Tests: what they use on Main

Methods called with `game.call` (62): `_context_hint` (45), `_refresh_ui` (43), `_finish_intro` (35), `_new_game` (35), `_load_game` (24), `_objective` (22), `_pause_game` (15), `_sync_scene` (13), `_resume_game` (8), `_update_controls` (8), `_fail_beat` (7), `_interact` (6), `_return_to_title` (6), `_save_progress` (6), `_start_gameplay_camera` (6), `_process` (5), `_advance_intro` (4), `_interact_checkpoint` (4), `_resolution_size` (4), `_show_end_card` (4), `_cancel_fail` (3), `_drop_ready` (3), `_finish_chapter_close` (3), `_handle_back` (3), `_note_input_device` (3), `_refresh_continue` (3), `_title_first_button` (3), `_update_gameplay_camera` (3), `debug_snapshot` (3), `end_card_recap` (3), `_bait_holding` (2), `_debug_spares_knockdown` (2), `_hide_title_overlay` (2), `_hold_station` (2), `_input` (2), `_on_fps_selected` (2), `_on_reduced_motion_changed` (2), `_on_settings_back` (2), `_tank_miss` (2), `_answer_choice` (1), `_ask_relay` (1), `_choose` (1), `_close_end_card` (1), `_debug_sentry_frozen` (1), `_door_blast` (1), `_drop_waits_for_wolf` (1), `_enter_junction` (1), `_first_name` (1), `_hide_end_card` (1), `_interact_breaker` (1), `_interact_relay` (1), `_leave_junction` (1), `_on_resolution_selected` (1), `_save_settings` (1), `_sentry_reason` (1), `_show_credits` (1), `_show_pause_menu` (1), `_show_settings` (1), `_show_title_settings` (1), `_stop_junction_loops` (1), `_sync_door` (1), `_tank_hit` (1)

Properties read with `game.get` (68): `status_line` (92), `state` (67), `fail_active` (47), `title_open` (38), `intro_active` (16), `save_path` (16), `waiting_for_choice` (16), `junction_room` (15), `sentry_brain` (14), `end_card_active` (10), `bypass_ticks` (9), `impact` (8), `intro_step` (8), `wolf_baiting` (8), `chapter_close_active` (7), `lane_choice` (7), `records_room` (7), `drop_arm` (6), `pause_overlay` (6), `pressure_line` (6), `bypass_handle` (5), `tutorial_step` (5), `wolf_scouting` (5), `engineer_step_x` (4), `seal_opening` (4), `settings_menu` (4), `sfx_bank` (4), `bolt_state` (3), `controller_active` (3), `door_lip` (3), `engineer_waits_for_wolf` (3), `hatch_exit_walking` (3), `wolf_heading_to_relay` (3), `beat_snapshot` (2), `bypass_venting` (2), `choice_context` (2), `continue_button` (2), `credits_paused` (2), `effects_enabled` (2), `relay_refused` (2), `save_pending` (2), `stakes_spoken` (2), `wolf_broke_off` (2), `wolf_holding_far_end` (2), `wolf_sprite_scale` (2), `breaker_status_glow` (1), `bypass_was_holding` (1), `changelog_text` (1), `corridor_depth` (1), `credits_screen` (1), `debug_tools` (1), `door_dust` (1), `door_open_art` (1), `fps_options` (1), `intro_camera` (1), `intro_fade` (1), `intro_tween` (1), `name_card_remaining` (1), `opening_hatch` (1), `post_grade` (1), `relay_sparks` (1), `relay_status_glow` (1), `resolution_options` (1), `save_error` (1), `seal_leaf` (1), `touch_choice_1` (1), `touch_choice_2` (1), `touch_use` (1)

Properties set with `game.set` (13): `touch_enabled` (46), `save_path` (21), `settings_path` (15), `state` (11), `waiting_for_choice` (9), `auto_pause_on_focus_loss` (6), `controller_active` (6), `effects_enabled` (6), `lane_choice` (4), `status_line` (2), `tutorial_step` (2), `bolt_state` (1), `chapter_close_active` (1)

Main constants read (27): `WOLF_FEET_BELOW_CENTRE` (4), `STATION_OVERLAP` (3), `VALVE_CRANK_X` (3), `WOLF_BYPASS_CLEAR_X` (3), `WOLF_DRAWN_HEIGHT` (3), `WOLF_SENTRY_GAP` (3), `BYPASS_CRANK_X` (2), `CORRIDOR_DOOR_LEFT_X` (2), `FALL_DEGREES` (2), `FALL_SHIFT` (2), `JUNCTION_STATIONS` (2), `RECORDS_STATIONS` (2), `WOLF_MIRROR_X` (2), `BAIT_NO_LINE` (1), `BOLT_WHINE_SECONDS` (1), `BYPASS_WHEEL` (1), `CHECKPOINT_TOAST` (1), `CORRIDOR_STATIONS` (1), `FAIL_CONTROLS_OFF_SECONDS` (1), `FAIL_FADE_SECONDS` (1), `GAMEPLAY_CAMERA_Y_TOUCH` (1), `GAMEPLAY_VIEW_WIDTH` (1), `INTRO_LINES` (1), `NO_CHECKPOINT_NOTE` (1), `RELAY_QUESTION` (1), `RELAY_X` (1), `RESTORE_FROM_DISK_LINE` (1)

Node paths under Main (64 unique, `game.get_node`): `BreakerArt`, `BreakerLabel`, `BreakerStatusLight`, `CanvasLayer/BottomBar`, `CanvasLayer/BottomBar/Speaker`, `CanvasLayer/BottomBar/Story`, `CanvasLayer/ContextHint`, `CanvasLayer/ContextHint/Text`, `CanvasLayer/EndCard`, `CanvasLayer/IntroAlarm`, `CanvasLayer/IntroFade`, `CanvasLayer/PauseButton`, `CanvasLayer/PauseOverlay`, `CanvasLayer/PauseOverlay/Panel/PauseMenu`, `CanvasLayer/PauseOverlay/Panel/PauseMenu/ResumeButton`, `CanvasLayer/PauseOverlay/Panel/PauseMenu/SettingsButton`, `CanvasLayer/PauseOverlay/Panel/PauseMenu/TitleButton`, `CanvasLayer/PauseOverlay/Panel/SettingsMenu`, `CanvasLayer/PauseOverlay/Panel/SettingsMenu/BackButton`, `CanvasLayer/PauseOverlay/Panel/SettingsMenu/FPSOptions`, `CanvasLayer/TitleScreen`, `CanvasLayer/TitleScreen/ChangelogButton`, `CanvasLayer/TitleScreen/ChangelogScreen`, `CanvasLayer/TitleScreen/ContinueButton`, `CanvasLayer/TitleScreen/ContinueNote`, `CanvasLayer/TitleScreen/CorridorArt`, `CanvasLayer/TitleScreen/CreditsButton`, `CanvasLayer/TitleScreen/CreditsScreen`, `CanvasLayer/TitleScreen/CreditsScreen/CreditsBackButton`, `CanvasLayer/TitleScreen/CreditsScreen/CreditsPauseButton`, `CanvasLayer/TitleScreen/GameTitle`, `CanvasLayer/TitleScreen/LogoMark`, `CanvasLayer/TitleScreen/NewGameButton`, `CanvasLayer/TitleScreen/SettingsButton`, `CanvasLayer/TopBar`, `CanvasLayer/TopBar/Accent`, `CanvasLayer/TopBar/HUD`, `CanvasLayer/TouchControls`, `CanvasLayer/TouchControls/Choice1`, `CanvasLayer/TouchControls/Choice2`, `CanvasLayer/TouchControls/Use`, `CanvasLayer/TutorialPrompt`, `CanvasLayer/TutorialPrompt/Text`, `CheckpointArt`, `CheckpointLabel`, `CorridorDepth`, `Door/CollisionShape2D`, `Door/Visual`, `Door/Visual/DoorArt`, `Human`, `Human/BodySprite`, `Human/CollisionShape2D`, `IntroCamera`, `IntroDirector`, `IntroGate`, `OpeningHatch`, `PurgeTerminalArt`, `RelayArt`, `RelayLabel`, `RelaySpark`, `RelayStatusLight`, `Wolf`, `Wolf/BodySprite`, `Wolf/CollisionShape2D`

Private methods (leading underscore) tests call (60): `_advance_intro`, `_answer_choice`, `_ask_relay`, `_bait_holding`, `_cancel_fail`, `_choose`, `_close_end_card`, `_context_hint`, `_debug_sentry_frozen`, `_debug_spares_knockdown`, `_door_blast`, `_drop_ready`, `_drop_waits_for_wolf`, `_enter_junction`, `_fail_beat`, `_finish_chapter_close`, `_finish_intro`, `_first_name`, `_handle_back`, `_hide_end_card`, `_hide_title_overlay`, `_hold_station`, `_input`, `_interact`, `_interact_breaker`, `_interact_checkpoint`, `_interact_relay`, `_leave_junction`, `_load_game`, `_new_game`, `_note_input_device`, `_objective`, `_on_fps_selected`, `_on_reduced_motion_changed`, `_on_resolution_selected`, `_on_settings_back`, `_pause_game`, `_process`, `_refresh_continue`, `_refresh_ui`, `_resolution_size`, `_resume_game`, `_return_to_title`, `_save_progress`, `_save_settings`, `_sentry_reason`, `_show_credits`, `_show_end_card`, `_show_pause_menu`, `_show_settings`, `_show_title_settings`, `_start_gameplay_camera`, `_stop_junction_loops`, `_sync_door`, `_sync_scene`, `_tank_hit`, `_tank_miss`, `_title_first_button`, `_update_controls`, `_update_gameplay_camera`

The critique's 15 constants: `BYPASS_CRANK_X` (read by tests, defined), `BYPASS_WHEEL` (read by tests, defined), `CORRIDOR_DOOR_LEFT_X` (read by tests, defined), `CORRIDOR_STATIONS` (read by tests, defined), `INTRO_LINES` (read by tests, defined), `JUNCTION_STATIONS` (read by tests, defined), `RECORDS_STATIONS` (read by tests, defined), `RELAY_X` (read by tests, defined), `STATION_OVERLAP` (read by tests, defined), `WOLF_BYPASS_CLEAR_X` (read by tests, defined), `WOLF_MIRROR_X` (read by tests, defined), `GAMEPLAY_ZOOM` (not read in test code now, defined), `GAMEPLAY_CAMERA_Y_TOUCH` (read by tests, defined), `VALVE_CRANK_X` (read by tests, defined), `BOLT_WHINE_SECONDS` (read by tests, defined)

Used by tests but not defined at the top level of main.gd (inherited or a bug): `opening_hatch`

### Debug tools: what they use on Main

Members of Main used through `game.` in scripts/debug (58): `state` (7), `impact` (5), `effects_enabled` (4), `pause_overlay` (4), `pressure_line` (4), `save_path` (4), `title_open` (4), `controller_active` (3), `debug_new_game` (3), `end_card` (3), `human` (3), `junction_room` (3), `debug_interact` (2), `debug_load_checkpoint` (2), `debug_place` (2), `debug_station_side_x` (2), `drop_arm` (2), `intro_camera` (2), `sentry_brain` (2), `touch_choice_1` (2), `touch_choice_2` (2), `touch_enabled` (2), `wolf` (2), `changelog_screen` (1), `chapter_close_active` (1), `context_hint_text` (1), `credits_screen` (1), `debug_answer_lane` (1), `debug_beat` (1), `debug_drop_tank` (1), `debug_hold_station` (1), `debug_knock_down` (1), `debug_refresh_ui` (1), `debug_restore_focus` (1), `debug_save_changed` (1), `debug_save_progress` (1), `debug_show_end_card` (1), `debug_snapshot` (1), `debug_valve_turned` (1), `debug_wolf_target` (1), `debug_wolf_why` (1), `end_card_active` (1), `fail_active` (1), `hold_use` (1), `hud` (1), `intro_active` (1), `pause_button` (1), `save_pending` (1), `settings_menu` (1), `speaker` (1), `story` (1), `title_screen` (1), `touch_left` (1), `touch_right` (1), `touch_use` (1), `tutorial_prompt` (1), `tutorial_text` (1), `waiting_for_choice` (1)

Main constants read in scripts/debug (23): `CORRIDOR_STATIONS` (3), `JUNCTION_STATIONS` (2), `RECORDS_STATIONS` (2), `WOLF_MIRROR_X` (2), `BYPASS_CRANK_X` (1), `BYPASS_REACH` (1), `BYPASS_WHEEL` (1), `CHECKPOINT_TOAST` (1), `CORRIDOR_DOOR_LEFT_X` (1), `GAMEPLAY_ACTIONS` (1), `GAMEPLAY_VIEW_WIDTH` (1), `NO_CHECKPOINT_NOTE` (1), `PURGE_DISPLAY_MAX_X` (1), `RELAY_CONTACT_X` (1), `RELAY_REACH` (1), `RELAY_SIDE_X` (1), `RELAY_STEP_BACK_X` (1), `RELAY_X` (1), `RESTORE_FROM_DISK_LINE` (1), `SAVE_FAILED_HINT` (1), `UNREADABLE_CHECKPOINT_NOTE` (1), `VALVE_CRANK_X` (1), `WOLF_BYPASS_CLEAR_X` (1)

The public debug surface on Main: `debug_answer_lane`, `debug_beat`, `debug_drop_tank`, `debug_hold_station`, `debug_interact`, `debug_knock_down`, `debug_load_checkpoint`, `debug_new_game`, `debug_place`, `debug_refresh_ui`, `debug_restore_focus`, `debug_save_changed`, `debug_save_progress`, `debug_show_end_card`, `debug_snapshot`, `debug_station_side_x`, `debug_valve_turned`, `debug_wolf_target`, `debug_wolf_why`

### main.gd functions (first and last line)

| Function | Lines | Length |
|---|---|---:|
| `_ready` | 474-552 | 79 |
| `_refresh_continue` | 555-571 | 17 |
| `_title_first_button` | 575-576 | 2 |
| `_on_continue_pressed` | 581-586 | 6 |
| `_open_changelog` | 590-592 | 3 |
| `_load_changelog` | 595-601 | 7 |
| `_changelog_bbcode` | 605-615 | 11 |
| `_show_changelog` | 618-621 | 4 |
| `_hide_changelog` | 624-626 | 3 |
| `_setup_corridor_door` | 631-640 | 10 |
| `_setup_bypass` | 645-650 | 6 |
| `_setup_corridor_labels` | 655-664 | 10 |
| `_apply_effects` | 668-679 | 12 |
| `_room_depths` | 683-684 | 2 |
| `_sync_room_lights` | 691-694 | 4 |
| `_setup_impact` | 699-708 | 10 |
| `_on_reduced_motion_changed` | 713-718 | 6 |
| `_setup_particles` | 723-740 | 18 |
| `_attach_status_glow` | 744-749 | 6 |
| `_update_gameplay_camera` | 752-755 | 4 |
| `_start_gameplay_camera` | 758-763 | 6 |
| `_process` | 766-823 | 58 |
| `_tick_engineer_step` | 828-836 | 9 |
| `_step_engineer` | 840-849 | 10 |
| `_step_beside_station` | 856-866 | 11 |
| `_update_settle` | 873-883 | 11 |
| `_settle_safe` | 888-895 | 8 |
| `_fuse_lit` | 899-900 | 2 |
| `_first_name` | 904-905 | 2 |
| `_clear_station_body` | 911-918 | 8 |
| `_room_stations` | 923-930 | 8 |
| `_station_offset` | 934-935 | 2 |
| `_station_side_x` | 940-942 | 3 |
| `_tick_corridor` | 948-979 | 32 |
| `_read_seconds` | 983-984 | 2 |
| `_speak_stakes` | 987-989 | 3 |
| `_stakes_up` | 993-994 | 2 |
| `_at_breaker` | 998-999 | 2 |
| `_ask_relay` | 1003-1007 | 5 |
| `_new_game` | 1010-1068 | 59 |
| `_advance_intro` | 1072-1117 | 46 |
| `_finish_intro` | 1120-1153 | 34 |
| `_show_credits` | 1156-1161 | 6 |
| `_hide_credits` | 1164-1166 | 3 |
| `_show_title_overlay` | 1171-1175 | 5 |
| `_hide_title_overlay` | 1178-1182 | 5 |
| `_toggle_credits_pause` | 1185-1187 | 3 |
| `_on_credits_body_input` | 1190-1193 | 4 |
| `_on_changelog_body_input` | 1198-1206 | 9 |
| `_setup_touch_controls` | 1209-1217 | 9 |
| `_bind_touch_button` | 1220-1222 | 3 |
| `_setup_settings` | 1225-1261 | 37 |
| `_resolution_size` | 1264-1265 | 2 |
| `_on_fps_selected` | 1268-1270 | 3 |
| `_on_resolution_selected` | 1273-1276 | 4 |
| `_on_fullscreen_toggled` | 1279-1282 | 4 |
| `_save_settings` | 1285-1291 | 7 |
| `_on_pause_button` | 1294-1295 | 2 |
| `_pause_game` | 1298-1308 | 11 |
| `_resume_game` | 1311-1317 | 7 |
| `_show_settings` | 1320-1327 | 8 |
| `_show_title_settings` | 1330-1334 | 5 |
| `_fade_backdrop` | 1339-1344 | 6 |
| `_reveal_menu` | 1347-1355 | 9 |
| `_show_pause_menu` | 1358-1374 | 17 |
| `_return_to_title` | 1377-1402 | 26 |
| `_grab_menu_focus` | 1407-1413 | 7 |
| `_menu_focus_target` | 1417-1428 | 12 |
| `_unhandled_input` | 1431-1449 | 19 |
| `_notification` | 1452-1459 | 8 |
| `_handle_back` | 1463-1481 | 19 |
| `_on_title_button` | 1484-1489 | 6 |
| `_on_settings_back` | 1492-1495 | 4 |
| `_input` | 1498-1505 | 8 |
| `_answer_choice` | 1509-1516 | 8 |
| `_note_input_device` | 1520-1543 | 24 |
| `_load_game` | 1546-1615 | 70 |
| `_interact` | 1618-1646 | 29 |
| `_at_bypass` | 1651-1652 | 2 |
| `_at_relay` | 1657-1658 | 2 |
| `_relay_refused` | 1663-1664 | 2 |
| `_interact_breaker` | 1667-1683 | 17 |
| `_choose` | 1686-1698 | 13 |
| `_interact_relay` | 1704-1729 | 26 |
| `_wolf_takes_relay` | 1734-1744 | 11 |
| `_interact_bypass` | 1749-1758 | 10 |
| `_start_bypass_vent` | 1763-1769 | 7 |
| `_stop_bypass_vent` | 1772-1777 | 6 |
| `_bypass_cranked` | 1783-1795 | 13 |
| `_finish_bypass` | 1798-1810 | 13 |
| `_interact_checkpoint` | 1813-1839 | 27 |
| `_interact_records` | 1842-1886 | 45 |
| `_records_route_hint` | 1891-1896 | 6 |
| `_finish_chapter_close` | 1899-1913 | 15 |
| `_walk_out_through_hatch` | 1919-1927 | 9 |
| `_engineer_follows_out` | 1932-1941 | 10 |
| `_build_end_card` | 1946-1992 | 47 |
| `_end_card_label` | 1995-2004 | 10 |
| `end_card_recap` | 2010-2027 | 18 |
| `_show_end_card` | 2030-2067 | 38 |
| `_close_end_card` | 2071-2074 | 4 |
| `_hide_end_card` | 2077-2079 | 3 |
| `_choose_mirror` | 2082-2096 | 15 |
| `_save_progress` | 2099-2102 | 4 |
| `_write_beat` | 2106-2114 | 9 |
| `_capture_positions` | 2117-2121 | 5 |
| `_mark_beat` | 2126-2128 | 3 |
| `_hold_station` | 2133-2138 | 6 |
| `_enter_junction` | 2142-2153 | 12 |
| `_interact_junction` | 2156-2198 | 43 |
| `_at_arm_panel` | 2202-2203 | 2 |
| `_bait_holding` | 2209-2210 | 2 |
| `_drop_waits_for_wolf` | 2216-2217 | 2 |
| `_wolf_drawing_x` | 2222-2223 | 2 |
| `_use_arm_panel` | 2226-2239 | 14 |
| `_drop_tank` | 2244-2250 | 7 |
| `_use_exit` | 2255-2271 | 17 |
| `_pop_bolt` | 2274-2279 | 6 |
| `_bolt_arc` | 2284-2296 | 13 |
| `_hatch_sliding` | 2300-2301 | 2 |
| `_hatch_opened` | 2305-2307 | 3 |
| `_leave_junction` | 2312-2324 | 13 |
| `_frame_chapter_close` | 2329-2331 | 3 |
| `_tick_junction` | 2336-2374 | 39 |
| `_tick_lane` | 2381-2442 | 62 |
| `_sync_wolf_leap` | 2449-2465 | 17 |
| `_sentry_reason` | 2471-2472 | 2 |
| `_seen_in_lane` | 2477-2478 | 2 |
| `_lane_sound` | 2484-2503 | 20 |
| `_sentry_changed` | 2506-2519 | 14 |
| `_sentry_alarm` | 2523-2524 | 2 |
| `_ask_lane` | 2529-2533 | 5 |
| `_choose_lane` | 2538-2560 | 23 |
| `_tank_hit` | 2564-2590 | 27 |
| `_tank_miss` | 2596-2615 | 20 |
| `_tank_rehung` | 2618-2621 | 4 |
| `_fade_servo` | 2625-2633 | 9 |
| `_kill_servo_tween` | 2636-2639 | 4 |
| `_stop_junction_loops` | 2642-2644 | 3 |
| `_valve_turned` | 2648-2655 | 8 |
| `_vent_trips` | 2660-2668 | 9 |
| `_wolf_reads_seam` | 2671-2676 | 6 |
| `_door_blast` | 2684-2700 | 17 |
| `_blast_feedback` | 2703-2709 | 7 |
| `_fail_beat` | 2717-2756 | 40 |
| `_lane_fall` | 2763-2775 | 13 |
| `_restore_beat` | 2778-2805 | 28 |
| `_cancel_fail_tween` | 2808-2811 | 4 |
| `_cancel_fail` | 2815-2820 | 6 |
| `_shutter_boom` | 2824-2829 | 6 |
| `_door_lands` | 2834-2842 | 9 |
| `_sync_scene` | 2845-2902 | 58 |
| `_sync_junction_room` | 2907-2927 | 21 |
| `_react_as_wolf` | 2930-2942 | 13 |
| `_flash_relay_spark` | 2947-2977 | 31 |
| `_sync_records_room` | 2980-2994 | 15 |
| `_sync_door` | 3000-3019 | 20 |
| `_update_controls` | 3022-3036 | 15 |
| `_wolf_target_x` | 3044-3080 | 37 |
| `_wolf_off_relay` | 3087-3092 | 6 |
| `_machine_spans` | 3098-3112 | 15 |
| `_wolf_follow_max_x` | 3117-3122 | 6 |
| `_refresh_ui` | 3125-3224 | 100 |
| `_set_dialogue` | 3227-3261 | 35 |
| `_show_top_card` | 3264-3274 | 11 |
| `_context_hint` | 3277-3331 | 55 |
| `_junction_hint` | 3334-3364 | 31 |
| `_lane_asked` | 3368-3369 | 2 |
| `_sentry_hunting` | 3373-3374 | 2 |
| `_drop_ready` | 3379-3380 | 2 |
| `_lane_hint` | 3383-3419 | 37 |
| `_objective` | 3422-3453 | 32 |
| `_install_inputs` | 3456-3473 | 18 |
| `_add_action` | 3476-3486 | 11 |
| `_add_joy_button` | 3489-3493 | 5 |
| `_add_joy_axis` | 3496-3507 | 12 |
| `_setup_debug_tools` | 3510-3514 | 5 |
| `_debug_spares_knockdown` | 3519-3520 | 2 |
| `_debug_sentry_frozen` | 3524-3525 | 2 |
| `_debug_takes_back` | 3529-3535 | 7 |
| `debug_new_game` | 3538-3542 | 5 |
| `debug_load_checkpoint` | 3546-3548 | 3 |
| `debug_interact` | 3552-3553 | 2 |
| `debug_answer_lane` | 3557-3559 | 3 |
| `debug_show_end_card` | 3562-3563 | 2 |
| `debug_station_side_x` | 3567-3568 | 2 |
| `debug_place` | 3572-3577 | 6 |
| `debug_knock_down` | 3582-3592 | 11 |
| `debug_valve_turned` | 3596-3598 | 3 |
| `debug_drop_tank` | 3602-3603 | 2 |
| `debug_save_progress` | 3607-3608 | 2 |
| `debug_save_changed` | 3612-3614 | 3 |
| `debug_refresh_ui` | 3617-3618 | 2 |
| `debug_hold_station` | 3622-3623 | 2 |
| `debug_restore_focus` | 3627-3632 | 6 |
| `debug_snapshot` | 3638-3676 | 39 |
| `debug_beat` | 3679-3694 | 16 |
| `_debug_engineer_state` | 3697-3710 | 14 |
| `debug_wolf_target` | 3715-3720 | 6 |
| `debug_wolf_why` | 3724-3750 | 27 |
