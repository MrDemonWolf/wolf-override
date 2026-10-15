# WOLF//OVERRIDE: lighter, componentized game (plan)

Base: `main` at 76d3a50, Godot 4.7.2, `apps/game`. Planning only: nothing in the repo was changed for this.
Inputs: `map-main.md`, `map-rooms.md`, `map-ui.md`, `map-audio.md`, `map-perf.md` and `map-assets.md` in this folder.

Nathanial's two asks (2026-10-11):
1. Remove duplicated code, make components, make the game lighter and faster, and keep the UI the same.
2. Delete the old assets and replace them with the approved new ones.

Ground rules for every step:
- Each step is one PR that can be played on its own.
- `scripts/check-game.sh` must pass.
- Screenshot parity on the four routes (section 5) must pass at the thresholds given there.
- The only exceptions are the steps marked **VISUAL** or **BEHAVIOUR** below. Each of those names its visible or audible change and gets a reviewed new baseline.
- Strings stay byte-identical. About 125 test assertions match narration and hint text.
- No scene node is reparented or renamed unless the step says so.
- Tested private names on `main` stay available as one-line shims.

Hard gate: `codex/logic-round-3` (junction staging and the opening hatch, in `wt-r3`) **merges first**. Every step that touches junction code, `main.gd` junction beats, `HatchDoorway`, `bolt_arc` or the hatch assets waits for it. That covers S11-S16, S21 and S23. Steps S01-S10 do not touch those areas, but they will still conflict textually with `main.gd`. The simplest order is to merge r3 and then start S00.

---

## 1. Component architecture

### 1.1 Folder layout

- Existing scripts **stay at their current `res://scripts/*.gd` paths**. Tests `preload` them by path, and so do the 56 capture scripts.
- New code goes into subfolders:

```
scripts/
  main.gd                 (shrinks to the flow and mode state machine, see 1.6)
  m0_state.gd, m0_actor.gd, impact.gd, sfx_bank.gd, ...   (stay; gain small helpers)
  flow/   run_flags.gd, choice.gd, intro_sequence.gd, beat_saver.gd, input_defaults.gd
  rooms/  room.gd (base), room_beats.gd (beats interface), corridor_room.gd,
          corridor_beats.gd, records_beats.gd, junction_beats.gd, station.gd
  world/  name_plate.gd, plate_fader.gd, status_lamp.gd, shutter.gd, turn_wheel.gd,
          hazard_zone.gd, actor_sprite.gd, prop_spec.gd
  fx/     palette.gd, fx_kit.gd, tweens.gd
  ui/     hud.gd, title_screen.gd, title_overlay.gd, card_panel.gd, end_card.gd
scenes/ui/  end_card.tscn, end_card_row.tscn, settings_menu.tscn
assets/fonts/settings_theme.tres
```

### 1.2 World components (`scripts/world`, `scripts/fx`, `scripts/rooms`)

| Component | What it is | Replaces (dedup source) | Notes |
|---|---|---|---|
| **Palette** (`fx/palette.gd`, const only) | Named colours: AMBER, GREEN, STEEL, CYAN `#8be3ff`, EXIT_GREEN `#a4f0c4`, LABEL_TEXT `#b0d1de`, LABEL_MUTED `#8fa6b2`, LABEL_ALERT `#ffc7c7`, PLATE_BG, PLATE_EDGE, SKIN `#f4d5ae` and others | About 60 repeated colour literals in junction_room, records_room, bypass_handle, room_depth, sentry, fx_presets, containment_cage and main | Exact same values. The near-identical UI tints (0.59/0.61/0.67/0.68/0.69) stay separate on purpose. |
| **FxKit** (`fx/fx_kit.gd`) | Cached GradientTexture2D keyed by (stops, colours, size, fill), plus one shared additive CanvasItemMaterial | 74 per-instance gradients (2.19 MB, about 6 distinct shapes) in floor_reflection, fx_presets, room_depth and junction_room; about 15 separate additive materials | Cache owned by a `FxKit` node under Main and cleared in `_exit_tree`. check-game.sh fails on leaks, so no bare static Resource cache. |
| **Tweens** (`fx/tweens.gd`) | `static kill(t)` and `static restart(owner, t) -> Tween` | 19 kill sites in main plus about 13 in junction_room, room_depth, sentry, bypass_handle and impact | One deliberate form: `is_valid()`. |
| **NamePlate** (Label subclass) | caption, tint, anchor (centre x, top y), font size (12/13/8 per room), optional shared plate StyleBox, wrap/foot. `set_state(text, colour)` re-fits only when something changed. | 5 label builders: `JunctionRoom._add_station_label/_fit_label`, `RecordsRoom._add_station_label/_fit_label`, `main._setup_corridor_labels`, the `BypassHandle._plate` and the plate/caption parts of `junction_room` 470-503 | Attached to the **existing** corridor Label nodes (BreakerLabel, RelayLabel, CheckpointLabel), so their paths stay. |
| **PlateFader** (one node) | The per-frame edge fade for the plates of the room in play | `main.EdgeFader`, `RecordsRoom._process`, `JunctionRoom._process` and the `BypassHandle._process` fade | Keeps `JunctionRoom.edge_alpha` / `fade_at_view_edge` as static aliases, because follow_spacing_test calls them. |
| **StatusLamp** | Socket rect, `color` property with early-out, lit or dim alpha, optional glow child in group `status_glow` | ColorRect lamps (BreakerStatusLight, RelayStatusLight), `_attach_status_glow`, `RecordsRoom` PURGE/MIRROR lights, the junction breaker, arm panel, bolt panel and 2 hatch lamps drawn in `_draw` | Phase 1 (S12): a script on the existing ColorRects plus a drawn variant, same pixels. Phase 2 (S19, VISUAL): a tinted `status-lamp-*.png` sprite. The `color` property stays, so tests that read `.color` keep working. |
| **Station** (`rooms/station.gd`, RefCounted data) | id, centre_x, half_width, reach, side, span_half_width, label spec, lamp spec, prop spec | The `*_STATIONS` Vector4 tables, `_machine_spans` (drifted copies), about 25 `absf(x - N) <= R` checks, and the Records 190/520/830 literals | `Room.station_at(x) -> StringName` and `Room.machine_spans()`. The Vector4 consts stay on main, derived from the data, because follow_spacing_test reads them. |
| **PropSpec** (`world/prop_spec.gd`, one data table) | File, region, scale (0.25 for D=4), baseline and sockets (from look2-hq `parts.json`) | About 30 REGION/SCALE/LIGHT constants in junction_room, records_room, sentry, bypass_handle and the main.tscn prop nodes | Makes the asset swap a data change. Adds `RoomDepth.cut(tex, region, scale)` and `Room.add_prop()`, which handles z, add_child and the FloorReflection together. |
| **TurnWheel** (Sprite2D) | `steps_per_rev`, `step` setter, 0.18 s cubic tween (snaps at 0) | The junction ValveWheel and the BypassHandle Wheel (same texture, region, mask, tween) | S16 keeps the current cut and mask, compiled once and shared. S19 switches to `junction-valve-wheel.png`, which removes WHEEL_MASK and both `Shader.new()` calls. |
| **Shutter** (Node2D, layer-driven) | Layers: frame (one per state), leaf clipped to a doorway, passage, front lip registered in `RoomDepth.pillars`, StatusLamp, collision body (on only while the room is active and the door closed), `face_x`, `open_to(amount, secs)`, `blast()`, `opened` / `landed` signals, dust and spark bursts, reflections | Corridor `Door` / `Visual` / `DoorArt`, `_setup_corridor_door`, `_sync_door`, `_door_lands`, seal_leaf.gd; `JunctionRoom._build_door`, `_show_door`, `door_blast`; `HatchDoorway`, `bolt_arc`, `_sync_hatch`, the entry hatch; Records `_draw_exit` and the exit lift | S16 builds it around the **current** bulkhead art, pixel-identical. S22 and S23 drop in the new layers (VISUAL). The corridor door node keeps the name `Door`, with children `CollisionShape2D`, `Visual` and `Visual/DoorArt`. |
| **HazardZone** (optional, S17) | x-span, body-widened span, `armed`, reason, `contains(x)`, `arm_for(s)`, optional drawn band | `hazard.gd` Area2D for vent and cloud, `_draw_blast_zone`, `_draw_alcove_floor`, `_draw_floor_mark`, `_arm_hazard`, and the range tests in pressure_line, drop_arm and sentry_brain | Changes contact from the physics frame to the process frame. It ships only if the junction suites and frame-sliced knockdown tests pass unchanged. Otherwise it stays as a drawing helper only. |
| **ActorSprite** (on Human/Wolf/IntroDirector `BodySprite`) | `rest_pose()`, `react(accepting)`, `knock_down(facing)`, per-actor rest offset; after S21 it also runs the idle, walk and jog/trot SpriteFrames, and FloorReflection follows the frame and region | Pose resets at 6 sites, `_react_as_wolf`, the knockdown tilt in `_fail_beat`, and WOLF/HUMAN_SPRITE_REST | Node paths `Human/BodySprite` and `Wolf/BodySprite` stay. |
| **Room** (base, `rooms/room.gd`, Node2D) | Depth spec builds RoomDepth; `add_prop`, `stations`, `doors`, `plates`, `hazards`; `set_active(on)` sets visibility, door bodies, hazards, fader, **turns reflection processing off when hidden**, and handles lazy art; passes down `effects_enabled` and `reduce_motion`; `set_lockdown_cleared`; `apply_state(M0State)` | Main's per-room plumbing: `_apply_effects`, `_room_depths`, `_sync_room_lights`, `_on_reduced_motion_changed` loops, the field-by-field `_sync_records_room` / `_sync_junction_room` copies, and the 4 corridor show/hide lists | Subclasses: **CorridorRoom** (new; at first a script that holds references to the existing loose main.tscn nodes, no reparenting), RecordsRoom (existing view), JunctionRoom (existing view, minus the utility library). |

### 1.3 Room controllers (beats), the biggest `main.gd` reduction

`RoomBeats` interface (`rooms/room_beats.gd`), one implementation per chapter id:

```
stations() machine_spans() station_at(x)
interact(x) -> bool     hint(x) -> String     objective() -> String
restore_line() -> String location_card() close_card()
wolf_target_x() follow_max_x() hold_station(x) settle_safe(from, to)
tick(delta, held_ticks)   sync(state, animate)   stop_loops()
```

| Controller | Moves out of main.gd | Approx. lines |
|---|---|---|
| **CorridorBeats** | Stakes, breaker, relay question, relay, WOLF contact, bypass crank, safe point, seal door, relay spark, `_wolf_off_relay`, corridor hints, objective, restore line, tints, WOLF targets and spans | ~400 |
| **RecordsBeats** | `_interact_records`, `_choose_mirror`, `_records_route_hint`, hint, objective, restore lines, mirror facing, the WOLF mirror target | ~110 |
| **JunctionBeats** | Pressure line, valve, vent, blast, lane choice, sentry, tank, bolt, hatch, sound loops, `_junction_hint`, `_lane_hint`, objective, restore lines, `_sentry_changed`; it owns PressureLine, SentryBrain, DropArm and `bolt_state`, and drives the view-only JunctionRoom | ~530 (after r3) |

**Host contract.** Main passes itself as `host` (duck-typed, GDScript 4 allows the cycle):
- `say(line)`, `save()`, `mark_beat()`, `fail(reason)`
- `open_choice(Choice)`, `close_choice()`
- `step_engineer(x, face)`, `update_controls()`
- `enter_room(id, line)`, `begin_chapter_close(line)`
- `cue(name)` (Impact cue table) and `sfx`
- fields `state`, `human`, `wolf`, `impact`

Main calls `rooms[state.chapter_id].x()` in place of the 33 chapter-id comparisons. **The order of operations inside `_process` stays exactly as it is now.** Only the room-specific calls inside it are routed.

### 1.4 Flow helpers (`scripts/flow`)

- **RunFlags**: the attempt-scoped fields:
  - `waiting_for_choice`, `choice_context`
  - `relay_refused`, `wolf_heading_to_relay`, `wolf_scouting`
  - `last_top_card_key`, `chapter_close_active`, `checkpoint_toast_remaining`
  - `reset(for_load: bool)`, which keeps the `stakes_spoken` and `tutorial_step` differences between new game and load

  It also adds `_leave_title()`, `_clear_intro_staging()`, `_enter_room(line)` and `_begin_chapter_close(line)`. Together these replace the copies across six entry points and the duplicated intro teardown. Main forwards the tested names as properties.
- **Choice**: a record with id, question, answers[2] and handler, plus `_open_choice` and `_close_choice`. The relay, mirror and lane choices become 3 records. Each answer string exists once, so "USE WOLF'S READOUT" is no longer typed twice.
- **IntroSequence**: the INTRO_LINES beat list (the `INTRO_LINES` const stays on main for tests), per-step actions, staging and teardown, `_shutter_boom`.
- **BeatSaver**:
  - It handles `_save_progress`, `_write_beat`, `_mark_beat`, `_capture_positions`, `_fail_beat`, `_restore_beat` and `_cancel_fail`, plus the knockdown tilt via `ActorSprite.knock_down`.
  - Main keeps the shims `_save_progress`, `_fail_beat` and `_load_game`.
  - M0State gains `first_name()` and `relay_outcome()`, replacing 14 and 3 inline derivations.
- **Impact.cue(name, burst)**: a named cue table (sounds, trauma, flash, rumble, hit_stop) that replaces 15 hand-written cue sites.
- **input_defaults.gd** (optional, last): `_install_inputs` moves here. It does not move into `project.godot` `[input]` unless the rebinding-reset path is verified (GameSettings snapshots the defaults).

### 1.5 UI components (keep the look identical)

| Component | Change | Keeps |
|---|---|---|
| **Hud** (script on the existing `CanvasLayer` node) | Presentation half of `_refresh_ui`, `_set_dialogue`, `_show_top_card` and its tween, speaker tag and tint, context-hint placement, tutorial prompt, touch and choice layout, checkpoint toast, name card. Input is a small **view model** (status, hint, objective, card key, answers, mode flags), applied **only on change**. Theme overrides (speaker `font_color`, Choice1/2 `font_size`) are set only when the value differs. A prompt cache (`key(action)`, `localise(text)`) is invalidated on rebind or device change. | `main._refresh_ui()`, `_context_hint()` and `_objective()` stay as shims: hint and objective content comes from the RoomBeats, and Hud only presents it. All paths stay. |
| **TitleScreen** (script on `CanvasLayer/TitleScreen`) | Continue and play again, overlay switching, signals `new_game_requested`, `continue_requested`, `settings_requested` | Shims: `_refresh_continue`, `_title_first_button`, `_show/_hide_credits`, `_show_changelog`, `credits_body`, `changelog_body`, `credits_paused`, `changelog_text` |
| **TitleOverlay** (script, **attached to both existing** CreditsScreen and ChangelogScreen) | One copy of show/hide, scroll (auto and drag), focus, back, and the 2-button row. Exported node refs, so child names stay. | Credits BBCode verbatim. No path changes. Converting them to an instanced `.tscn` (removes about 70 tscn lines) is optional later; it renames children and needs test edits, so it is listed under S10b. |
| **PauseOverlay** (expanded) | `_pause_game`, `_resume_game`, `_show_settings`, `_show_title_settings`, `_fade_backdrop`, `_reveal_menu`, `_show_pause_menu`; tweens are still created on `pause_overlay` (they must run while paused) | Shims for the 6 tested names |
| **GameSettings** (existing) | Gains the video options: `_setup_settings`, `_resolution_size`, `_on_fps_selected`, `_on_resolution_selected`, `_on_fullscreen_toggled`, `_save_settings`. An authored `scenes/ui/settings_menu.tscn` plus a static `settings_theme.tres` replace the runtime Theme build (4-6 ms) and the ~25 tscn lines that are overwritten on the first frame. | Same tabs, controls, focus ring and button styles (ui_controls_test). Same node names `FPSOptions`, `ResolutionOptions`, `BackButton`. |
| **CardPanel** (Panel subclass) | Draws the CardSheen stylebox (and optionally the accent) in `_draw`; removes 5 Sheen nodes plus the end card's sheen | `TopBar/Accent` stays a ColorRect because tests read it. The other accents keep their exact per-card geometry and colour. |
| **EndCard** (`scenes/ui/end_card.tscn` + `end_card_row.tscn`) | Replaces the imperative build (main 1878-1990) | Names `EndCard` and `EndCardContinue`. It calls `UIMotion.attach` itself if it loads lazily. |
| **Theme variations** in `game_theme.tres` | MenuButtonLarge 21, MenuButton 19, MenuButtonSmall 18, TouchArrow 34, StationLabel, CaptionLabel, MenuNote, MenuBody, DisplayLabel | Exact sizes and colours. These do not apply inside SettingsMenu's local theme, so copy them there if they are needed. |
| Delete | `Human/Tag`, `Wolf/Tag` (always hidden; Human/Tag text is written every frame), the two no-op size-16 overrides, the dead pause-panel initial geometry | Nothing visible |

### 1.6 Audio (`sfx_bank.gd`)

- The 13 generated clips are **pre-rendered** by a headless tool kept **outside `res://`** (repo `scripts/render_sfx.gd`, run with `--script`). That moves about 1,000 recipe lines out of the shipped game.
- SfxBank becomes one `CLIPS` table (name → preloaded stream, loop) plus the existing 6-voice pool, 7 loop players, `play_blend`, `stop*` and `players()`. That is about 120-150 lines, down from 1,179.
- First pass: 16-bit PCM WAV, so the samples are identical and the sound is unchanged.
- QOA is a separate, **audible** decision (S25).
- `_lane_sound` uses a `SERVO_BY_STATE` table.

### 1.7 What `main.gd` shrinks to (target about 800 lines, range 700-900, from 3,310)

| Kept in main | ~lines |
|---|---|
| Constants that tests read (station Vector4s derived from Station data, CORRIDOR_DOOR_LEFT_X, INTRO_LINES, WOLF_MIRROR_X, BYPASS_*, RELAY_X), node refs | 120 |
| `_ready` wiring: build rooms dictionary, Hud, TitleScreen, PauseOverlay, signals | 80 |
| Mode state machine: title → intro → play → chapter close → end card → fail, `_process` in today's order | 120 |
| Room routing: `_interact`, settle and step beside, `_update_controls`, `_sync_scene` funnel (door → Records → junction → lights order kept) | 150 |
| Camera (gameplay and chapter-close framing) | 40 |
| Input routing, Android back, device detection, choice answer routing | 110 |
| Load, new game, return to title (using RunFlags and BeatSaver) | 80 |
| Test and capture shims (one line each, about 70 names) | 100 |

**Line budget.** The GDScript in `scripts/` is about 9,270 lines today. After the plan it is estimated at 6,900-7,400 shipped lines:
- main.gd: -2,400 moved and -400 to -600 removed
- sfx_bank.gd: -1,030, moved to the unshipped tool
- room scripts: -450 to -550 through the components
- new components: +1,800 to 2,200

main.tscn shrinks by about 120-160 lines (Sheen and Tag nodes, dead Settings props, inline overrides moved to theme variations).

---

## 2. Migration order (small steps)

Legend for **parity**:
- `IDENTICAL`: all suites green, headless UI dump diff empty, pixel parity at section 5 thresholds, sound unchanged.
- `VISUAL` / `BEHAVIOUR`: the named change gets a reviewed new baseline.

Each step lists its asset deletions where it has any. Gates are in brackets.

### Phase 0: gate and harness
- **S00 baseline-harness** [after r3 merges]
  - Add `scripts/parity/` at the repo root, outside `res://`:
    - a parity capture driver, built from the out-of-tree `capture.gd` pattern and `ui-parity/ui_dump.gd`
    - a runner shell script
    - a compare script using `magick compare -metric AE`
  - Capture baselines of the four routes (section 5) at 960x540, 1280x720 and 1080x2340 landscape-phone aspect, in both keyboard and touch layouts.
  - Re-run the perf driver (`perf/tools/run_one.sh`, `run_matrix.sh`) on a quiet machine to get a clean "before".
  - No game change.

### Phase 1: speed with no visible change
- **S01 hud-dirty**
  - Guard the 3 per-frame theme overrides.
  - Write story offset, context-hint rect, station tints, glow modulates and `bypass_handle.live` only on change.
  - Cache `settings_menu.prompt()` per device or binding.
  - Delete the `human_tag.text` write.
  - IDENTICAL. Expected `_refresh_ui` cost: 48-98 → 25-39 µs in play, 193-328 → 35-53 µs with a choice up (measured in scratch).
- **S02 junction-redraw**
  - Dirty flags in `sync_line`, `advance_display`, `sync_arm` and `sync_bolt`, so `_draw` and Recesses redraw only on change.
  - FloorReflection processing is switched off for sprites in hidden rooms (a small `set_reflections_active` until the Room base exists).
  - Particles in hidden rooms stop emitting.
  - IDENTICAL.
- **S03 fx-kit**
  - Palette, FxKit gradient and material cache, Tweens helper.
  - RoomDepth, FxPresets, FloorReflection and soft_texture read from it.
  - IDENTICAL: same gradients produce the same pixels. Leak check must pass.
- **S04 sfx-prerender**
  - Add the render tool.
  - Add 13 `assets/audio/sfx-*.wav` files (16-bit PCM, the same rates, forward-loop import for hum, servo, winch and klaxon).
  - SfxBank becomes the CLIPS table. Delete `_render_startup`, `_render_detail`, the worker task, the `_exit_tree` wait and the recipes.
  - check-game.sh renders to a temp folder and compares within 2 LSB (or a recipe-source hash).
  - sfx_bank_test: lengths, rates, peaks and loop flags still hold. Its 400 ms startup budget becomes a "no render at boot" check.
  - Manifest: 13 new entries, and the "procedural, ships as no file" wording is rewritten.
  - IDENTICAL sound.
- **S04b hiss-fix**
  - `play(&"hiss")` and `stop(&"hiss")` at main.gd 923 and 1722 point at a clip removed in fc172b3.
  - **BEHAVIOUR (audible): the bypass vent hiss comes back** on the engineer-only route.
  - Decision for Nathanial: restore the old recipe as a pre-rendered file, or reuse `junction-pressure-loop-low`.
  - Add a test asserting every clip name played by main exists in CLIPS.

### Phase 2: dedupe inside main (no new nodes)
- **S05 helpers**:
  - `M0State.first_name()` and `relay_outcome()`
  - `Impact.cue` table
  - ActorSprite pose helpers
  - Hud `key()` and `localise()`
  - Choice record
  - per-room text tables (byte-identical)
  - IDENTICAL.
- **S06 run-flags**:
  - RunFlags
  - `_leave_title`, `_clear_intro_staging`
  - `corridor_props` array (it replaces the 4 lists)
  - `_enter_room`, `_begin_chapter_close`
  - IDENTICAL.
- **S07 stations**:
  - Station records and `station_at`.
  - `_machine_spans` reads the same data, using `span_half_width` so today's 38.5/43.1/57.1/44.6/37.8 values stay exactly as they are.
  - The ~25 literal reach checks go.
  - The Vector4 consts are derived from the data.
  - IDENTICAL.

### Phase 3: UI components
- **S08 hud**:
  - Hud script on `CanvasLayer` with a view model.
  - main keeps the `_refresh_ui`, `_context_hint` and `_objective` shims.
  - IDENTICAL (UI dump exact).
- **S09 title-pause-settings**:
  - TitleScreen script, TitleOverlay attached to both existing overlays, expanded PauseOverlay, video settings moved into GameSettings.
  - IDENTICAL.
- **S10 endcard-theme**:
  - EndCard and EndCardRow scenes, CardPanel, theme variations, `settings_menu.tscn` plus `settings_theme.tres`.
  - Delete the Tag nodes and the dead tscn properties.
  - IDENTICAL. Exact pixel diff on every menu and card. If CardPanel's draw order differs, keep the Sheen nodes for that card.
  - *S10b (optional)*: TitleOverlay as an instanced `.tscn`. It renames CreditsBackButton and the other overlay children, so the test paths change in the same PR.
- **S11 intro-beatsaver**:
  - IntroSequence and BeatSaver.
  - IDENTICAL, including frame-sliced knockdown and restore tests.

### Phase 4: rooms
- **S12 room-base**:
  - Room base, NamePlate, PlateFader, StatusLamp (ColorRect-compatible), `RoomDepth.cut`, `Room.add_prop`.
  - RecordsRoom and JunctionRoom extend Room.
  - The utility library moves out of JunctionRoom, leaving aliases behind (`edge_alpha`, `prop_point`, `prop_rect`, `soft_texture`, `LABEL_PLATE`).
  - Delete EdgeFader.
  - IDENTICAL. Plates keep 12/13/8 px fonts and their rows at y 320/309/313.
- **S13 corridor-room**:
  - CorridorRoom script holds references to the existing loose nodes. CorridorBeats takes the corridor beats.
  - Main routes the corridor through `rooms[&"lockdown"]`.
  - IDENTICAL.
- **S14 records-beats**: RecordsBeats. IDENTICAL.
- **S15 junction-beats** [r3 merged]:
  - JunctionBeats owns PressureLine, SentryBrain, DropArm and `bolt_state`.
  - Main shims forward `bolt_state`, `lane_choice`, `wolf_baiting`, `pressure_line`, `sentry_brain` and `drop_arm`.
  - PressureLine consumes HoldUse ticks only if the EPSILON boundary tests still pass; otherwise it stays parallel.
  - IDENTICAL.
- **S16 shutter-wheel-code**:
  - The Shutter component wraps the current art: corridor seal (SealLeaf folded in), junction blast door, junction entry and exit hatches, and the Records exit lift.
  - TurnWheel with one shared mask shader.
  - Delete `seal_leaf.gd` (its behaviour now lives in Shutter's leaf layer; `m0_scene_test` 222-237 is re-pointed through the `seal_leaf` shim property).
  - IDENTICAL.
- **S17 hazard-zone** (optional): see 1.2. IDENTICAL or dropped.
- **S18 lazy-residency**:
  - Room art is no longer `const preload`. `Room.set_active(true)` loads it, with `ResourceLoader.load_threaded_request` for the next room on entry.
  - The title key art is freed after the title and reloaded when returning to it.
  - Tests that jump straight to `_enter_junction` still work, because `load_threaded_get` blocks.
  - IDENTICAL pixels. Startup and VRAM gains.

### Phase 5: asset swap (the explicitly visual steps)
- **S19 swap-stations**: VISUAL. Lists in section 3.
- **S20 swap-sentry**: VISUAL.
- **S21 swap-actors** [walk3 fix round re-delivered]: VISUAL + BEHAVIOUR (movement).
- **S22 swap-shutters** [game-ready shutter layers drawn]: VISUAL.
- **S23 swap-hatches** [hatch art drawn, r3 merged]: VISUAL.
- **S24 closeout**:
  - Manifest status paragraph rewritten.
  - `apps/docs` credits.mdx (39, 42, 46), legal.mdx (12) and about.mdx (6) updated.
  - The three site captures re-rendered.
  - README key-art reference checked.
  - Notion and Codex board updated (memory rule).

### Phase 6: optional, each one needs Nathanial's decision
- **S25 options**, each its own PR:
  - (a) QOA for all audio (AUDIBLE, needs an ear check on phone speakers and headphones; `sfx_bank_test`'s s16 peak reads move to the build-time source check)
  - (b) font subsets (identical glyphs, keeps ◀ ▶ × − — ’; new manifest entries)
  - (c) default `fps_limit` (BEHAVIOUR: on a 120 Hz display the 60 cap gives 42-46 FPS; needs testing on a 60 Hz display and a phone)
  - (d) logo `svg/scale=0.5` with mipmaps (sub-pixel VISUAL)
  - (e) export filters excluding `manifest.json` and including `*.txt`, once an export preset exists
  - (f) InputMap defaults moved into `project.godot`

---

## 3. Asset swap

Rules for every swap step:
- Overwrite in place where the role is unchanged, so the `preload` path, the `.import` uid and the manifest `asset_id` stay. Only the PropSpec data changes.
- Delete each `.import` file with its image.
- Rewrite or delete the manifest entry (with source, SHA-256 and modifications) in the same PR.
- Grep must show no `preload`, `load` or tscn `ext_resource` pointing at a deleted file.
- check-game.sh reimports.
- Placement is D=4: scale 0.25, baseline at H-9, the opaque bottom on FLOOR_Y 440.

### 3.1 Draw first (game-ready, not yet existing)

The approved concepts are `doors-shutter-approved/` (four 1671x941 concept scenes). The look2-hq `doors/` folder is **superseded**. The new layers must fill today's door footprint exactly, so the camera framing, labels (`DOOR_LABEL_SHIFT`), follow limits and saves do not move.

| Asset | World box to fill (today) | Canvas at D=4 | Layers (each trimmed to its own opaque box, offsets in a `parts.json`) |
|---|---|---|---|
| **Corridor seal shutter** (left face x = 752, `CORRIDOR_DOOR_LEFT_X`; floor 440) | Today 384x606 px at 0.3 = **115.2 x 181.8 world**. The door body (gameplay) is 56 x 132. The front pillar's outer edge is on the face: 83 canvas px in today, 22.8 world wide. The leaf spans face+20.1 to face+76.5 world, and the doorway top is 130 world above the floor at the left and 111 at the right (slanted header). | Registered canvas **464 x 736** (116 x 184 world, baseline row 727). Face column at x ≈ 100 px, pillar ≈ 91 px wide. Doorway opening ≥ **224 x 528 px** (56 x 132 world) starting at x ≈ 180 px. | `frame` (columns, header, guide rails; z 0, behind actors) · `leaf` (ribbed slats, hazard bottom edge, slides up into the header, ≈ 226 x 528) · `passage` (machinery service chamber, ≈ 226 x 528) · `front` (near column over the actors, z 2-3, registered as a RoomDepth pillar; `BULKHEAD_PILLAR_X/WIDTH` become per-Shutter values ≈ 100/91 px) · lamp socket (tinted StatusLamp sprite, not baked) |
| **Junction blast shutter** (DOOR_X 480, left face = `M0State.JUNCTION_DOOR_LEFT_X`; floor 440) | Today 384x604 at 0.3 = **115.2 x 181.2 world**, body 56 x 132, seam 33.9 world right of the face (`DOOR_SEAM_X` 196 canvas) | **464 x 736**, same face and opening contract; a seam line sockets in `parts.json` | `frame` (heavier rails, bolted header) · `leaf-sealed` (armoured segments) · `leaf-blown` (torn hanging plates) · `debris` (floor, beside the threshold) · `passage` (switchgear hall) · `front` · amber lamps (tinted sprites). **Decision**: a `leaf-breaking` frame for the 0.15 s `DOOR_BREAK_SECONDS`, or cover that moment with the existing flash and particles (saves one texture). |
| **Junction hatch** (entry x ENTRY_X and exit `HATCH_X` 880; one art for both) | Today 403x700 at 0.206 = **83 x 144 world**; leaf 216x498 → 44.5 x 102.6 world | **352 x 592** (332 x 576 opaque) | `frame`, `leaf` (≈ 178 x 410), `passage` (≈ 178 x 410; today it is cut from `corridor-bulkhead-open`, so this removes that cross-room dependency, or it can reuse the corridor shutter `passage` crop), lamp socket (today `HATCH_LAMP` 92x24 source = 19 x 5 world; reuse a status-lamp sprite) |
| **Records exit hatch** | Today 254x479 opaque at 0.291 = **76 x 140 world** | **320 x 576** | `frame`, `leaf` or open state, `passage` (replaces `_draw_exit` rects) |

- Every layer: lossless, mipmaps on, `fix_alpha_border`.
- Estimated VRAM with trimmed layers (RGBA8 + mips):
  - corridor shutter ≈ 3.5 MiB
  - junction shutter ≈ 4.4 MiB
  - hatches ≈ 2.5 MiB
  - total ≈ 10.4 MiB, against 11.3 MiB for today's bulkheads and hatches
- With S18, only one room's doors are resident at a time.
- **Decision**: whether the hatches become a small member of the shutter family or keep a distinct hatch silhouette.
- Still to make, as code rather than art: the corridor purge-display lamp (the new art has an unlit socket), and the gantry shackle placement for the taller arm, using `parts.json` from the HQ scratch batch. That file is not in the repo copy and must be fetched.

### 3.2 Per-step replacement and deletion lists

**S19 swap-stations** (VISUAL: new Look 2 HQ station art; breaker 11 world px narrower, relay 10 narrower, bolt panel 7 wider, tank arm 23 taller and re-hung, relief vent 27 taller as a raised housing, a bolder gauge needle, lamp sprites in place of flat rects)

- **Replace in place** (paths, uids and ids stay; manifest entries rewritten):
  - `props/corridor-breaker`, `corridor-coolant-relay`, `corridor-safe-point`, `records-mirror-port`, `junction-valve` (body only), `junction-tank`, `junction-tank-arm` (arm only), `junction-arm-panel`, `junction-bolt-panel`, `junction-relief-vent`
- **Dedupe the purge console**:
  - One `props/purge-console.png` drawn at 0.25 in Records and 0.225 in the corridor (102.4 x 100.8 world, today 102.8 x 100.8).
  - **Delete** `props/corridor-purge-display.png` and `props/records-purge-queue.png` with both manifest entries, and add one new entry.
- **New files**:
  - `props/junction-valve-wheel.png` (TurnWheel, which deletes `WHEEL_MASK`)
  - `props/junction-valve-needle.png` (replaces `_draw_gauge`)
  - `props/lamps/status-lamp-*.png` (StatusLamp; 7 after the purge dedupe, or 1-2 shared)
- **Do not import**: `junction-valve-gauge` and the pickups (no consumer yet).
- **Gameplay data re-derived**:
  - `BREAKER_HALF_WIDTH`, `BOLT_X` (about 3.6 px), `WOLF_SEAM_X`, `WOLF_CLEAR_X`, the alcove cover
  - `JUNCTION_STATIONS` / Station data. The drifted `span_half_width` values are unified at this point, which can shift WOLF's rest spots by up to about 1 px.
  - The steam emitter, caption and nozzle light at the vent
- **Tests**: `junction_test` 445; `follow_spacing_test` 211-212 and 270; `room_depth_test` 76-77; `m0_scene_test` 43, 217 and 296 (`.color` stays readable through StatusLamp).

**S20 swap-sentry** (VISUAL: Look 2 sentry at bible density, 60 x 42 world against 60 x 44 today)

- **Delete** `props/junction-sentry-side-left.png` and `props/junction-sentry-down.png` with their imports and 2 manifest entries.
- **Add** `props/junction-sentry-active.png` and `props/junction-sentry-wreck.png`.
- Re-derive `ACTIVE_REGION`, `ART_SCALE` 0.25, tread x 130, `LENS`, `DRAWN_HEIGHT` ≈ 42 and `WRECK_HULL_TOP`. Test: `sentry_test` 319.
- `sentry-scanning` is optional: chase and fixated could use it. That would be its own VISUAL decision.

**S21 swap-actors** (VISUAL: painted idle, walk and jog/trot cycles for the engineer and WOLF, the Look 2 Director still. BEHAVIOUR: walk 80 px/s, then jog 190 after about 0.5 s held. Today WALK_SPEED is 190 throughout, so every route timing changes and the parity baseline is re-captured.)

- **Gate**: the walk3 fix round has re-delivered the sheets. Engineer walk frames 1-2, jog frame 6 and WOLF trot frame 0 must be fixed. Record SHA-256 values. Import one copy of the engineer sheets: `wolf/deliver/sprites/eng-*` are duplicates.
- **Add** `characters/engineer-{idle,walk,jog}.png` and `characters/wolf-{idle,walk,trot}.png` as a trimmed SpriteFrames atlas, which saves 20-35% over the raw sheets.
  - Decision: the bible's 8-frame walk and jog instead of 12 would save about 11 MiB.
  - Never VRAM-compressed.
- Node scales: engineer 0.2540 at y ≈ -8.6; WOLF 0.2603 at y ≈ -17.8, with the pivot at column +37, so check `flip_h`.
- **Director** (decision): `characters/director-stand-left.png`.
- **Delete**:
  - `rowan-side-right-provisional.png`, `wolf-side-right-provisional.png`, and `director-side-left-provisional.png` if approved, with their imports and 3 manifest entries
  - `art-source/characters/*-provisional.png` (3 masters, 3 entries)
- ActorSprite drives the animation, and FloorReflection follows the frame and region; otherwise the reflections freeze.
- **Tests**: `junction_test` 613 and 635 (stand-in texture); `room_depth_test` 124-131.
- **Not imported**: the HQ identity-reference side poses and `death-poses/` (for the later death system; the WOLF death-pose colour must be regraded first).

**S22 swap-shutters** (VISUAL: approved shutter doors replace the bulkheads in the corridor and the junction). **Done:** the corridor's door end landed on 2026-10-12 and the junction's blast door on 2026-10-14 (`../sources/doors-2026-10-14/`); every file listed below is deleted, `scripts/prepare_bulkheads.py` included.

- **Add** the 3.1 corridor and junction layers.
- **Delete** these 7 files with their imports and manifest entries:
  - `props/corridor-bulkhead-sealed.png`, `corridor-bulkhead-open.png`, `corridor-bulkhead-front-lip.png`
  - `junction-bulkhead-sealed.png`, `junction-bulkhead-breaking.png`, `junction-bulkhead-blown.png`, `junction-bulkhead-front-lip.png`
- **Also delete**:
  - `art-source/doors/*.png` (7 masters, 7 entries)
  - repo `scripts/prepare_bulkheads.py`
  - `RoomDepth.BULKHEAD_SCALE`, `make_bulkhead`, `bulkhead_center_x`
  - main's `CORRIDOR_DOOR_SEALED/OPEN/LIP/REGION` (`CORRIDOR_DOOR_LEFT_X` stays)
- **Blocker**: `corridor-bulkhead-open` also feeds the junction exit-hatch passage (`junction_room.gd` 37-39 and 392). Either S23 lands first, or the hatch passage temporarily points at the new corridor `passage` layer. Name that as a VISUAL change inside the hatch.
- **Tests**: `room_depth_test` 76-77; `junction_test` 563-565; `m0_scene_test` 222-237, through the `seal_leaf` shim.

**S23 swap-hatches** (VISUAL: new junction entry and exit hatch and Records exit). **Done 2026-10-14:** real doors replaced them (swing doors at the Records entry and exit and the junction entry, a sliding door at the junction exit); both hatch images and their constants are gone.

- **Delete** `props/junction-hatch.png` and `props/records-exit-hatch.png` with their imports and 2 manifest entries.
- **Delete** the constants `HATCH_REGION`, `HATCH_SCALE`, `HATCH_LAMP`, `HATCH_LEAF`, `HATCH_PASSAGE*`, plus Records `EXIT_*` and `_draw_exit`.

**Totals after S19-S23**:
- Deleted: 16 game images (2 purge consoles, 2 sentry, 3 provisional characters, 7 bulkheads, 2 hatches) with their `.import` files, plus 10 art-source masters and `scripts/prepare_bulkheads.py`.
- Rewritten in place: 10.
- Manifest: 26 entries deleted (16 + 10 masters), 10 rewritten, and new entries for every imported part, lamp, sentry state, sheet and door or hatch layer.
- Kept unchanged: the 9 room plates, title key art, logo, fonts, shaders, audio and changelog.

---

## 4. Performance: expected gains and how to prove them

All "before" figures are from `map-perf.md`, measured on an M1 Pro at 1280x720 on a busy machine; re-measure the baseline quietly in S00. "After" figures are **estimates** until they are measured.

| Area | Before (measured) | Expected after | From steps | Reasoning |
|---|---|---|---|---|
| Startup: `load(main.tscn)` | 441 ms (426-493) | ≈ 250-320 ms | S04, S10, S18 | Lossless WebP decode is 189 ms of the load, and Records and junction props plus the sentry are about half of it, deferred by lazy residency. Startup clip rendering takes 30-50 ms on the main thread. The runtime settings Theme build takes 4-6 ms. Script compile is 92 ms in-editor, and sfx_bank alone is 38-68 ms of it. |
| Launch to title first frame | 1.72 s median | ≈ 1.45-1.55 s desktop | same | Engine boot (1.08 s) does not change. |
| Background worker after boot | ≈ 1,009 ms (growl alone 424 ms); `_exit_tree` waits on it | 0 | S04 | Clips are pre-rendered. No worker, and no block on quit or on an early `play()`. |
| Resident texture memory | 70.8-71.6 MB in every state (54.1 MB file textures + 2.19 MB gradients); only 10-24 MB visible | ≈ 35-45 MB before the swap; after the swap ≈ 45-55 MB, because the sheets add ≈ 17-36 MiB depending on trim and frame count | S03, S18, S19-S23 | Current room plus the next room only, and the title art freed (≈ 6 MiB). Gradient cache: 74 textures down to about 6. Stations 15.4 → 8.6 MiB, sentry 8.0 → 0.86 MiB, doors roughly even, characters 2.6 → 17-36 MiB. |
| Per-frame main thread | ≈ 1.2 ms worst (script 0.11-0.35, render CPU 0.41-0.82) | ≈ 0.8-0.95 ms worst | S01, S02, S12 | `_refresh_ui` 2x faster in play and 4-6x faster with a choice up (measured in scratch). The junction `_draw` no longer redraws at rest, so junction render CPU 0.8 ms → ≈ 0.5-0.6. About 23 FloorReflection `_process` calls run only for the active room. One PlateFader replaces four. |
| Draw calls | 55 (Records) - 114 (lane) | Unchanged to slightly lower | S03, S10 | The shared additive material lets GL Compatibility batch glows, and 6 Sheen nodes are gone. Not a goal in itself. |
| Audio memory | 3.15 MB PCM + 2-4 MiB temporary float buffers | 3.15 MB (S04) → 0.64 MB with QOA (S25a) | S04, S25a | No render buffers. QOA is lossy and needs an ear check. |
| Export `.pck` | 24.96 MB (17.1 MB gzipped) | ≈ 22-23 MB before the walk3 sheets; the sheets add back an unmeasured amount of lossless WebP | S19, S20, S25a/b | Sentry sheets 1.7 MB → ≈ 0.2. Purge dedupe. Pre-rendered PCM is +0.49 MB, but QOA would be -2.0 MB on all audio. Font subsets would be -1.1 MB. |
| GDScript shipped | ≈ 9,270 lines | ≈ 6,900-7,400 | all | See 1.7. |
| Frame pacing | 60 cap + V-Sync on 120 Hz gives 42-46 FPS | 120 FPS steady (measured with the cap off) | S25c (decision) | The largest "feels faster" lever. It is a settings default, not code. |
| Phone | Not measured | Proportionally larger gains: the boot hitch (est. 150-250 ms) and 3-5 s of worker time go, and HUD frame cost drops 2-6x | S01, S04, S18 | Must be measured on a device before any claim. |

**Measurements that prove it** (same driver and states, before and after each phase; median of 3 runs; quiet machine; window not occluded):
1. **Startup**: 6 launches with `perf/tools/run_one.sh`. Record launch to first title frame, `load(main.tscn)`, `_ready`, worker completion (should no longer exist), and `perf_loadprobe.gd` per-asset loads.
2. **Frame**: `perf_driver.gd` route over 8 states (title, corridor start, corridor relay, Records, junction entry, blast, after the blast, lane). Record `proc_phase_ms`, `phys_phase_ms`, render CPU, p50/p99 frame time uncapped and at the default, and draw calls. Also add an in-driver µs timer around `_refresh_ui` and around JunctionRoom `_draw`.
3. **Memory**: `RENDER_TEXTURE_MEM_USED`, `RENDER_VIDEO_MEM_USED` and `MEMORY_STATIC` per state; `footprint -p`; the static texture table (`static_textures.csv`) showing which textures are resident.
4. **Size**: `godot --export-pack` with the throwaway presets, using `pck_list.py` for the per-entry breakdown; size of `.godot/imported`.
5. **Audio**: `perf_sfxprobe.gd` (bank `_ready` ms, worker ms; it should report no worker).
6. **Phone** (needed before claiming a phone gain): one Android device with a remote-debug build. Record the Godot monitors per state, startup to first frame, and frame time p99 while walking and during a choice.

Report each after-figure next to the "before" for the same phase. Keep code-only phases (1-4) and asset phases (5) separate so the gains can be attributed.

---

## 5. Test strategy

### 5.1 Headless suites (`scripts/check-game.sh`)
- **Contract kept by shims on main**:
  - all 44 called methods
  - 51 read properties and 12 set properties, forwarded with `get:`/`set:` to RunFlags, the Beats controllers or the Hud
  - 11 constants
  - about 60 node paths
- The 56 out-of-tree capture scripts keep working through the same shims, plus `credits_body`, `changelog_body`, `_show/_hide_credits` and `_show_changelog`.
- **Tests that change** (only where the step says so):

| Step | Test edits |
|---|---|
| S04 | `sfx_bank_test`: startup budget becomes "no render at boot"; determinism moves to the render tool's tolerance check. Add a "every clip main plays exists" test (S04b). |
| S10b (optional) | `ui_controls_test` / `m0_scene_test`: TitleOverlay child paths (CreditsBackButton, CreditsPauseButton, ChangelogBackButton, ChangelogOnlineButton, CreditsBody, ChangelogBody). |
| S12 | None if the aliases hold (`JunctionRoom.edge_alpha`, `station_labels`, `valve_label`, `breaker_label`, `line_caption`, `tank_label`). |
| S15 | `junction_test` and `sentry_test`, only if a forwarded name cannot be shimmed (for example `vent_hazard.armed` if S17 lands). |
| S16 | `m0_scene_test` 222-237 (seal leaf through the shim); `junction_test` door internals (`door_art`, `door_breaking_art`, `door_blown_art`, `door_lip`, `door_shape`, `door_visual`, `hatch_open`) kept as Shutter aliases. |
| S19 | `junction_test` 445; `follow_spacing_test` 211-212 and 270; `room_depth_test` 76-77; `m0_scene_test` 43, 217 and 296 (lamp `.color` stays as a property). |
| S20 | `sentry_test` 319. |
| S21 | `junction_test` 613 and 635; `room_depth_test` 124-131; timing tests that assume 190 px/s walking. |
| S22/S23 | `room_depth_test` 76-77; `junction_test` 563-565. |

- New unit tests come with the components that get them: Station `station_at` boundaries, RunFlags reset parity (new game vs load), Choice open and close, FxKit cache identity, Shutter state machine, TurnWheel steps, and the Hud dirty-check (no theme notification when values are unchanged).

### 5.2 Screenshot parity (the four scripted routes)
- **Driver**: `scripts/parity/capture.gd`, run with `godot --path apps/game --script`.
  - Settings: `--fixed-fps 60`, V-Sync off, a fixed `seed()`, and isolated HOME as in check-game.sh.
  - Particles use `use_fixed_seed` / `seed` in parity mode. Confirm that 4.7.2 CPUParticles2D exposes these; if it does not, mask the particle rects.
  - It is input-driven: synthetic actions, no private calls except to jump to checkpoints.
- **Renderer and sizes**: the real GL Compatibility renderer in a window, at 960x540, 1280x720 and a phone landscape aspect (2340x1080). Run with effects on and with effects off plus Reduced Motion; keyboard and touch layouts.

| Route | Frames captured | Threshold |
|---|---|---|
| **R1 Title & menus** | Title reveal end; Credits (scroll 0 and mid); Changelog; Settings (Display, Audio, Controls tabs, rebind prompt); Pause menu; Pause settings; END OF SLICE card; continue note with a save present | **AE = 0** at fuzz 0, all sizes |
| **R2 Corridor** | Intro beats 1-N; first control; breaker; relay question (keyboard and touch choice buttons); the three outcomes (press, cooperate, disclose with bypass crank); seal opening at 0/0.5/1; safe point; corridor → Records cut | HUD rects (TopBar, BottomBar, ContextHint, TutorialPrompt, TouchControls) **AE = 0**. Whole frame with effects off **AE = 0**. Effects on: ≤ 0.1% of pixels differ at fuzz 3% |
| **R3 Records** | Entry; purge; mirror choice (both answers); mirror copied; exit lift; chapter close framing | as R2 |
| **R4 Junction → end** | Entry; pressure line and hold; valve; vent fire; knockdown card and restore; fuse lit and blast (pre, flash, after); lane choice (WOLF, engineer-only); sentry chase and fixated; tank drop; bolt; hatch open; walk-out; end card; touch framing (camera y 392) | as R2, effects-on limit ≤ 0.25% (lane particles) |

- **Also every step**:
  - `ui-parity/ui_dump.gd` resolved-property diff against `baseline-76d3a50.txt`, which must be empty.
  - An audio fingerprint: the play and stop call log from SfxBank across R2-R4 must match. For S04, the clip PCM must match within 2 LSB.
- **VISUAL / BEHAVIOUR steps**:
  - Produce a side-by-side contact sheet (old | new | diff) per route.
  - The named changes must account for every differing region.
  - Nathanial approves, and then that capture becomes the new baseline.
- **Hands-on**: per AGENTS.md, no "looks the same" or "feels faster" claim without a played route:
  - desktop keyboard play of the corridor, Records and junction after phases 3 and 4
  - a touch play after S08-S10
  - a device test before any phone claim
  - S21 (walk/jog) needs a played route before any feel claim

### 5.3 Risks

1. **`_process` order and the `_sync_scene` funnel** are load-bearing. Routing must keep today's sequence exactly (engineer step → camera → timers → mirror facing → fail gate → hold-use → settle → room tick → fail re-check → tutorial → choice keys → interact → refresh), and the sync order door → Records → junction → lights.
2. **Text identity.** Moving about 94 `status_line` writes into tables risks one-character drift. A grep-based check compares the set of string literals before and after each move.
3. **Node paths.** Reparenting anything breaks about 60 test paths and the capture scripts. Scripts are attached to existing nodes. CorridorRoom does not reparent until a later optional PR with test updates.
4. **Tween ownership and pause.** Tweens moved to components change pause mode and lifetime. Pause and settings tweens stay on `pause_overlay`, and Hud and EndCard tweens use `PROCESS_MODE` as today.
5. **Leaks.** New RefCounted and Node components, the FxKit cache and lazy-loaded resources must be released at exit, or check-game.sh fails. No bare static caches.
6. **Lazy residency (S18).** It can cause a hitch on the first room entry on phones; mitigated by the threaded preload one room ahead. Return-to-title must reload the key art without a black frame.
7. **CardPanel draw order (S10).** If `_draw` lands under the Panel stylebox or over the Accent, the pixels change. Exact diff gate; fall back to keeping the Sheen node.
8. **HoldUse/PressureLine merge and HazardZone.** These change EPSILON and physics-frame timing. Both are optional and gated on unchanged frame-sliced tests.
9. **Asset geometry.** The S19 footprint changes move stations by up to 11 px and WOLF rest spots by about 1 px; follow_spacing_test checks label fade at zoom 1.35 and 1.55.
10. **Pre-rendered audio drift.** macOS arm64 and Linux CI math can differ in the last bit. Compare with a tolerance or a recipe hash, and always render to a temp folder.
11. **Dependency gates.** Round 3 (junction and hatch); the walk3 re-delivery; the shutter and hatch layers not yet drawn; `parts.json` missing from the repo copy; open decisions (Director still, accent-share exception, hatch family, `leaf-breaking`, 8- vs 12-frame cycles, hiss clip, fps cap, QOA).
12. **Shared busy machine.** Perf numbers from a loaded machine are pessimistic, so take before and after on the same quiet run with an unoccluded window.

### 5.4 Visible or audible changes named by this plan (everything else must be identical)
- S04b: the bypass vent hiss is audible again.
- S19: new station art; breaker and relay narrower, bolt panel wider, taller arm and vent; needle sprite; lamp sprites; WOLF rest spots shift by ≤ 1 px.
- S20: new sentry art.
- S21: painted walk, jog and trot cycles, the Director still, and walk-then-jog movement (80 → 190 px/s).
- S22: shutter doors replace the bulkheads (corridor and junction).
- S23: new hatches and Records exit.
- S24: re-rendered site captures.
- S25 options: QOA (audible), fps cap (pacing), logo import (sub-pixel).

## Amendment, October 11, 2026 (Nathanial)

- **Title and website hero repaint (after S21), all with Codex:** use Codex's built-in image generation to repaint title art B from the new Look 2 characters, then regenerate every published copy from it: the website landing hero WebPs (640, 1024 and 1672), the 1200x630 share card and the first-steps title capture. Re-check the hero at 390, 834x1112, 1024x1366 and 1440 so both characters stay clear of the copy, and delete the old derivatives and their manifest entries.
- Frame rate matches the screen by default (60 fps cap kept as a Settings option), sounds use QOA after an A/B check, fonts are subset to Latin.
- Contextual item labels replace the always-on name plates as a named visual step; item states move to the status lamps.
