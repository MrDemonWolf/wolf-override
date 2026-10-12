# main.gd map (WOLF//OVERRIDE, main at 76d3a50)

File: /Users/nathanialhenniges/Developer/mrdemonwolf/wolf-override/apps/game/scripts/main.gd
Read-only analysis. Nothing in the repo was changed.

## 1. Shape

- 3,310 lines. 172 top-level `func` (the brief's 169 is close; my count includes the 3 static funcs), plus the inner class `EdgeFader` (413-421).
- 115 `const`, 79 `var`, 66 `@onready`. 439 comment lines, 352 blank lines. About 2,360 lines sit inside function bodies.
- `status_line = ...` is assigned 94 times. Every narration and hint string is inline or a const in this file.
- `state.chapter_id` is compared 33 times, and the literals "lockdown", "records" and "junction" appear 36 times. Every per-room behaviour is an if/elif or match on the chapter id, spread across about 12 functions.
- Script helpers already exist: RecordsRoom (149 lines) and JunctionRoom (1,243) are view nodes for their rooms. PressureLine, SentryBrain, DropArm, HoldUse, Impact, SfxBank, BypassHandle, SealLeaf, GameSettings, PauseOverlay (23 lines), UIMotion and FxPresets are separate too. The corridor has no room script: its art, door, labels, lights, bypass, particles and logic all live in main.tscn and main.gd.

## 2. Responsibilities and line ranges

Body lines are the summed function lengths (fnranges.tsv in this folder has every function's range).

| # | Responsibility | Functions and line ranges | Body lines |
|---|---|---|---|
| A | Constants: URLs and changelog | 3-11 | (const) |
| A | Corridor geometry (relay, bypass, door, purge display) | 12-51, 159-167 | (const) |
| A | Card and look constants | 52-59, 383-410 (camera, zoom, choice row, menu reveal, resolutions) | (const) |
| A | Narration, hint and recap text | 60-136, 186-192 (INTRO_LINES 89-97, RECAP_* 108-116) | (const) |
| A | Station tables (Vector4 x, half width, reach, side) | 137-157 (CORRIDOR_STATIONS, RECORDS_STATIONS, JUNCTION_STATIONS) | (const) |
| A | Actor constants | 168-185 | (const) |
| B | Exports, node refs and run state | 194-381 | 188 |
| C | EdgeFader inner class (fades corridor labels at the view edge) | 413-421 | 9 |
| D | Boot and wiring | `_ready` 424-500 | 77 |
| E | Title screen: continue/play again, credits, changelog | `_refresh_continue` 503-519, `_title_first_button` 523, `_on_continue_pressed` 529-534, `_open_changelog` 538, `_load_changelog` 543-549, `_changelog_bbcode` 553-563, `_show/_hide_changelog` 566-574, `_show/_hide_credits` 1104-1114, `_show/_hide_title_overlay` 1119-1130, `_toggle_credits_pause` 1133, `_on_credits_body_input` 1138, `_on_changelog_body_input` 1146-1154; title branch of `_process` 715-721 | 88 + 7 |
| F | Corridor set-up (bulkhead art, bypass, labels, particles, status glows) | `_setup_corridor_door` 579-588, `_setup_bypass` 593-598, `_setup_corridor_labels` 603-612, `_setup_particles` 671-688, `_attach_status_glow` 692-697 | 50 |
| G | Effects and depth glue (effects switch, reduced motion, room lights) | `_apply_effects` 616-627, `_room_depths` 631, `_sync_room_lights` 639-642, `_setup_impact` 647-656, `_on_reduced_motion_changed` 661-666 | 34 |
| H | Camera | `_update_gameplay_camera` 700-703, `_start_gameplay_camera` 706-711, `_frame_chapter_close` 2255-2257 | 13 |
| I | Main loop (state router: title, intro, end card, chapter close, fail, hold-use, per-room tick, tutorial, choice keys, name cycle, interact) | `_process` 714-771 | 58 |
| J | Engineer stepping and station geometry (step beside, settle, clear body) | `_tick_engineer_step` 776, `_step_engineer` 788, `_step_beside_station` 804, `_update_settle` 821, `_settle_safe` 836, `_fuse_lit` 847, `_first_name` 852, `_clear_station_body` 859, `_room_stations` 871, `_station_offset` 882, `_station_side_x` 888 (776-890) | 74 |
| K | Corridor beats (stakes line, breaker, relay question, relay, WOLF contact, bypass crank, safe point, seal door) | `_tick_corridor` 896-927, `_read_seconds` 931, `_speak_stakes` 935, `_stakes_up` 941, `_at_breaker` 946, `_ask_relay` 951-955, corridor part of `_interact` 1579-1591, `_at_bypass` 1596, `_at_relay` 1602, `_relay_refused` 1608, `_interact_breaker` 1612-1628, `_choose` 1631-1643, `_interact_relay` 1649-1674, `_wolf_takes_relay` 1679-1689, `_interact_bypass` 1694-1703, `_start/_stop_bypass_vent` 1708-1722, `_bypass_cranked` 1728-1740, `_finish_bypass` 1743-1755, `_interact_checkpoint` 1758-1784, `_door_lands` 2677-2685, `_flash_relay_spark` 2775-2805, `_sync_door` 2828-2847, `_wolf_off_relay` 2896-2901. Also corridor hints 3105-3140, corridor objective 3254-3262, corridor station tinting in `_refresh_ui` 3000-3007 | 290 + about 60 in the HUD |
| L | Intro (opening beats) | `_new_game` 958-1016, `_advance_intro` 1020-1065, `_finish_intro` 1068-1101, `_shutter_boom` 2667-2672 | 145 |
| M | Touch buttons and video-settings glue | `_setup_touch_controls` 1157-1165, `_bind_touch_button` 1168, `_setup_settings` 1173-1209, `_resolution_size` 1212, `_on_fps_selected` 1216, `_on_resolution_selected` 1221, `_on_fullscreen_toggled` 1227, `_save_settings` 1233-1239 | 69 |
| N | Pause, menus, focus, input routing, Android back | `_on_pause_button` 1242, `_pause_game` 1246-1256, `_resume_game` 1259-1265, `_show_settings` 1268, `_show_title_settings` 1278, `_fade_backdrop` 1287, `_reveal_menu` 1295, `_show_pause_menu` 1306-1322, `_return_to_title` 1325-1349, `_grab_menu_focus` 1354, `_menu_focus_target` 1364, `_unhandled_input` 1378, `_notification` 1399, `_handle_back` 1410, `_on_title_button` 1429, `_on_settings_back` 1437, `_input` 1443, `_answer_choice` 1454, `_note_input_device` 1465-1488 | 203 |
| O | Saves, beats, knockdown and restore | `_load_game` 1491-1560, `_save_progress` 2028, `_write_beat` 2035-2043, `_capture_positions` 2046, `_mark_beat` 2055, `_fail_beat` 2586-2618, `_restore_beat` 2621-2648, `_cancel_fail_tween` 2651, `_cancel_fail` 2658-2663 | 162 |
| P | Records beats | `_interact_records` 1787-1831, `_records_route_hint` 1836-1841, `_choose_mirror` 2011-2025, `_sync_records_room` 2808-2822. Also the mirror-facing code in `_process` 740-742, Records hints 3093-3104, Records objective 3246-3253 and Records restore lines in `_load_game` 1550-1558 | 81 + about 30 |
| Q | Chapter close, hatch walk-out and END OF SLICE card | `_finish_chapter_close` 1844-1858, `_walk_out_through_hatch` 1863-1873, `_build_end_card` 1878-1924, `_end_card_label` 1927, `end_card_recap` 1942-1957, `_show_end_card` 1960-1996, `_close_end_card` 2000, `_hide_end_card` 2006 | 143 |
| R | Junction beats (pressure line, valve, vent, blast, lane choice, sentry, tank, bolt, hatch, loops) | `_hold_station` 2062 (shared), `_enter_junction` 2071-2081, `_interact_junction` 2084-2126, `_at_arm_panel` 2130, `_bait_holding` 2136, `_drop_waits_for_wolf` 2143, `_wolf_drawing_x` 2148, `_use_arm_panel` 2152-2165, `_drop_tank` 2170, `_use_exit` 2181-2197, `_pop_bolt` 2200, `_bolt_arc` 2210-2222, `_hatch_sliding` 2226, `_hatch_opened` 2231, `_leave_junction` 2238-2250, `_tick_junction` 2262-2293, `_tick_lane` 2300-2346, `_sentry_reason` 2352, `_lane_sound` 2360-2379, `_sentry_changed` 2382-2395, `_sentry_alarm` 2399, `_ask_lane` 2405, `_choose_lane` 2414-2433, `_tank_hit` 2437-2463, `_tank_miss` 2468-2485, `_tank_rehung` 2488, `_fade_servo` 2495-2503, `_kill_servo_tween` 2506, `_stop_junction_loops` 2512, `_valve_turned` 2518, `_vent_trips` 2530, `_wolf_reads_seam` 2541, `_door_blast` 2554-2570, `_blast_feedback` 2573, `_sync_junction_room` 2735-2755, `_junction_hint` 3143-3173, `_lane_asked` 3177, `_sentry_hunting` 3182, `_drop_ready` 3188, `_lane_hint` 3192-3228. Also the junction objective 3232-3245 and junction restore lines in `_load_game` 1541-1549 | 493 + about 35 |
| S | Scene sync and actor control (where WOLF goes, follow limits, machine spans, reactions) | `_sync_scene` 2688-2730, `_react_as_wolf` 2758-2770, `_update_controls` 2850-2860, `_wolf_target_x` 2867-2889, `_machine_spans` 2907-2921, `_wolf_follow_max_x` 2926-2931 | 111 |
| T | HUD: top card, dialogue box and speaker tags, context hint, tutorial prompt, touch and choice buttons, key prompts | `_refresh_ui` 2934-3033, `_set_dialogue` 3036-3070, `_show_top_card` 3073-3083, `_context_hint` 3086-3140, `_objective` 3231-3262 | 233 (about 95 of it is per-room hint and objective text) |
| U | Input map install | `_install_inputs` 3265-3282, `_add_action` 3285, `_add_joy_button` 3298, `_add_joy_axis` 3305 | 40 |

Toasts: the checkpoint toast is `checkpoint_toast_remaining` (358) plus `_write_beat` 2041 and the `_refresh_ui` hint pick at 3026. The name card is `name_card_remaining` (376) plus 1097 and 3010-3018. Both are timers that `_process` counts down at 738-739.

Where the size sits: corridor (K + F + corridor HUD) is about 400 lines, junction (R) about 530, the HUD (T) 233, pause and menus (N) 203, saves and restore (O) 162, intro (L) 145 and the end card (Q) 143.

## 3. Repeated patterns

### P1. Per-room if/elif ladders keyed on `chapter_id` (the biggest one)
Every one of these switches on the chapter, then on station x, then on state:
- interact: `_interact` 1563-1591 (corridor, inline), `_interact_records` 1787-1831, `_interact_junction` 2084-2126.
- context hint: `_context_hint` 3086-3140 (Records 3093-3104, corridor 3105-3140), `_junction_hint` 3143-3173, `_lane_hint` 3192-3228.
- objective: `_objective` 3231-3262 (three blocks).
- restore line on load: `_load_game` 1541-1560 (three blocks).
- location card and close card text: 2996 and 3021.
- WOLF target: `_wolf_target_x` 2875-2888. Machine spans: `_machine_spans` 2909-2917. Follow limit: `_wolf_follow_max_x` 2927-2931. Room stations: `_room_stations` 871-878. Hold station: `_hold_station` 2062-2067. Settle safety: `_settle_safe` 836-843. Per-room tick: `_process` 749-755.
- Room visibility sync: `_sync_records_room` 2808-2822 (which also hides corridor-only props), `_sync_junction_room` 2735-2755 and `_sync_door` 2828-2847.

About 600 lines. Proposal: one room-controller interface (`RoomController`, with CorridorRoom, RecordsRoom and JunctionRoom) providing `stations()`, `machine_spans()`, `interact(x)`, `hint(x)`, `objective()`, `restore_line()`, `location_card()`, `close_card()`, `wolf_target_x()`, `follow_max_x()`, `hold_station(x)`, `settle_safe(from, to)`, `tick(delta, held_ticks)`, `sync(state, animate)` and `stop_loops()`. main keeps a `rooms: Dictionary` keyed by chapter id and calls `rooms[state.chapter_id].x()`. Only the corridor needs a new controller. RecordsRoom and JunctionRoom already exist, but they are view-only, so their beat logic moves from main into them, or into a sibling logic class each (RecordsBeats, JunctionBeats) so the view files do not grow.

### P2. Station data written three times, with reach checks by hand
- The `*_STATIONS` Vector4 tables (144-157) hold x, half width, reach and side.
- `_machine_spans` (2911-2915) re-types the same half widths with small drift: 38.5 vs 38, 43.1 vs 43, 57.1 vs 56, 44.6 vs 45 and 37.8 vs 38.
- About 25 hand-written reach checks repeat the same numbers: 350/52 (breaker; 759, 947), 876/52 (safe point; 1588, 3106, 3110), 190, 520 and 830/58 (Records; 1788, 1795, 1806, 3095-3102), BREAKER_X and VALVE_X/52 (2063, 2085, 2097, 2099, 3152, 3160, 3164), and DOOR_X/40 (2115). The literal 230.0 at 2978 is PURGE_DISPLAY_MAX_X.

Proposal: one station record per machine (id, x, half_width, reach, side, span_half_width) in the room's data, and `station_at(x) -> StringName` to replace the ladders' x tests. Interact and hint then become `match station_at(x)`. Keep the Vector4 consts, or update follow_spacing_test (see section 5).

### P3. Run-state resets copied across six entry points
The same groups of fields are reset by hand in `_new_game` 958-988, `_load_game` 1491-1536, `_restore_beat` 2630-2640, `_return_to_title` 1325-1349, `_fail_beat` 2592-2596 and `_sync_scene` 2688-2730:
- `waiting_for_choice = false; choice_context = ""`: 7 places (980, 1341, 1528, 1635, 2018, 2418, 2593).
- `relay_refused`, `wolf_heading_to_relay`, `wolf_scouting`: 981-983, 1529-1531, 2634-2636.
- `hold_use.reset()`: 988, 1536, 1747, 2638. `last_top_card_key = ""`: 978, 1494, 2637.
- `chapter_close_active = false; _hide_end_card(); checkpoint_toast_remaining = 0`: 966-968, 1336-1339, 1504-1506.
- Unpause and hide the overlay: 959-960, 1492-1493. `title_open = false; title_screen.hide()`: 970-971, 1499-1500.
- Kill intro and chapter tweens: 961-964, 1023, 1071, 1329, 1502, 1508, 1848, 1961.

About 90 lines. Proposal: move the attempt-scoped fields into one `RunFlags` object (a RefCounted with `reset()`), or one `_reset_attempt()` plus `_leave_title()`. Each entry point then makes two or three calls. Watch the field-level differences: `stakes_spoken` is true on load and false on a new game, and `tutorial_step` is 2 or 0.

### P4. Corridor props listed in four places
The same breaker, relay and checkpoint art, status lights, labels, door visual, bypass handle and purge terminal are listed at 993-998 (intro hide), 1080-1085 (finish-intro show), 1518-1521 (load show) and 2811-2815 (corridor-only visibility). Proposal: one `corridor_props: Array[CanvasItem]` built in `_ready`, or a CorridorRoom node. Reparenting them under a node would break the test node paths (`BreakerArt`, `RelayArt`, `CheckpointArt`, `BreakerLabel`, `RelayLabel`, `CheckpointLabel`, `BreakerStatusLight`, `RelayStatusLight`, `PurgeTerminalArt`, `Door/...`, `RelaySpark`). Use an array, or a controller that holds references without moving the nodes, unless the tests are updated in the same change.

### P5. Impact cues: sound plus shake, flash, rumble and burst, 15 hand-written sites
1621-1622 and 2089-2090 are identical (clank -4/0.8 with rumble .15/0/.06). The other sites are 1733-1734, 1815-1819, 2173-2174, 2214-2218, 2450-2458, 2470-2474, 2489, 2519-2522, 2532-2536, 2575-2579, 2598-2602, 2668-2672, 2682-2685 and 2800-2805. About 70 lines. Proposal: a data table of named cues (`{sounds: [[clip, db, pitch]], trauma, flash: [white, red], rumble: [weak, strong, secs], hit_stop}`) and one `Impact.cue(name, burst := null)`, or a `FxCue` resource. The behaviour stays identical, and each site shrinks to one line.

### P6. Tween kill-before-restart, 19 sites
`if t != null and t.is_running(): t.kill()` appears at 961, 963, 1023, 1071, 1288, 1296, 1329, 1502, 1508, 1848, 1961, 2706, 2708, 2759, 2776, 2829 and 3074, plus the `is_valid` variant at 2507 and 2652. Proposal: a static `_kill(t: Tween)` helper, or a `restart_tween(slot)` helper. The tween vars (intro, menu, backdrop, top card, chapter, door, WOLF reaction, relay spark, servo, fail) also belong with their owner components. The `is_running` and `is_valid` forms differ, so pick one deliberately.

### P7. Sprite pose reset and reaction tweens
Pose resets (position = REST, rotation = 0) appear at 1001, 1088, 1517, 2710-2713, 2661-2662 and 2761-2762. The lean-and-return tween is in `_react_as_wolf` 2758-2770, and the knockdown tilt in `_fail_beat` 2609-2612. Proposal: move `rest_pose()`, `react(accepting)` and `knock_down(facing)` onto M0Actor, using the actor's own rest offset (WOLF_SPRITE_REST and HUMAN_SPRITE_REST become per-actor exports).

### P8. Choice open, answer and close repeated three times; answer text duplicated
- Open: `_ask_relay` 951-955, the mirror choice inline at 1802-1805 and `_ask_lane` 2405-2409 all set waiting = true and context = X, call `_update_controls` and build `question\n1 ...\n2 ...`.
- Close: `_choose` 1634-1636, `_choose_mirror` 2017-2019 and `_choose_lane` 2417-2418 + 2433.
- Answer labels are built again in `_refresh_ui` 2962-2970. The mirror answers "USE WOLF'S READOUT" and "USE MANUAL PORT" are typed at both 1805 and 2966. `_set_dialogue` strips the `\n1  ` tail again at 3037.

Proposal: a `Choice` data record (id, question, answers[2], handler) with `_open_choice(choice)` and `_close_choice()`. The buttons and the box read the record, so the answers live in one place. Keep the `status_line` text exactly as it is, because tests compare it.

### P9. Room entry and chapter close repeated
- Entering a room: 1763-1769 (corridor to Records) and 2071-2081 (Records to junction) both do `state.enter_X()`, `_sync_scene()`, `_start_gameplay_camera()`, set the status line and call `_save_progress()`.
- Chapter close: the Records exit (1807-1825) and `_leave_junction` 2238-2250 both set `chapter_close_active = true`, turn smoothing off, call `_update_controls`, set the status line, create `chapter_tween` and call `_frame_chapter_close()`, plus a save and the room lights.

Proposal: `_enter_room(line)` and `_begin_chapter_close(line)`. About 25 lines.

### P10. Key-prompt substitution scattered
The `settings_menu.prompt(...)` plus touch, controller or keyboard pick is repeated at 1320, 2943, 2973-2976, 2991, 2998, 3027-3032 and 3038-3039. Proposal: one `_key(action) -> String` that returns "TAP"/"USE" or the bound key, and one `_localise(text)` for the "E:", "Press E" and "press 2" swaps. Cache the result per device and binding change (see the perf notes).

### P11. First name derived 14 times while `_first_name()` exists
`state.human_name().get_slice(" ", 0)` appears at 919, 1098, 1790, 1808, 1943, 2023, 2079, 2247, 2392, 2395, 2561, 2568, 3008 and 3043. `_first_name()` at 852 already does this. Better still, put `first_name()` on M0State.

### P12. The relay outcome is derived three ways
The route checks are `state.memory.get("choice_id") == M0State.PRESS`, `state.route == "cooperate"`, and otherwise the disclose-plus-bypass route. They appear in the remembered line 1767, `end_card_recap` 1944 and `_relay_refused` 1608. Proposal: `M0State.relay_outcome() -> &"press" | &"cooperate" | &"disclose_bypass"`.

### P13. Labels and glows built three ways
- Corridor: `_setup_corridor_labels` 603-612 and the EdgeFader class 413-421.
- RecordsRoom: `_add_station_label`, `_fit_label` and `_process` fading (records_room.gd 87-111).
- JunctionRoom: `_add_station_label`, `_fit_label` and `_process` (junction_room.gd 675-705).
- Glows: `_attach_status_glow` (main.gd 692) vs `RecordsRoom._add_glow` (77).

Proposal: one `StationLabels` helper or component (fit, centre and edge fade) used by all three rooms, which removes EdgeFader. This crosses into the room scripts' area.

### P14. Strings repeated verbatim
- "The seal is open. The safe point is just beyond it." (1657, 1696)
- "Fuse lit. Get clear of the door." (2096, 2110, 3163)
- "The valve is spent. The door is down." (2098, 2112)
- "Mirror copied. Head for the exit." (1838, 3100)
- "No station in reach. ..." (four variants)
- Colour literals: #8be3ff at 2793, 3001, 3003 and 3062. #f4d5ae at 56 and 3062. #a4f0c4 at 3003.

Proposal: move the text into a per-room lines table (const Dictionary, or a .gd data script). The game gets lighter to read but not faster. The text must stay byte-identical, because about 125 test assertions match `status_line`, `_context_hint()` or `_objective()` text.

### P15. Intro and load teardown duplicated
`_finish_intro` 1075-1092 and `_load_game` 1510-1523 both hide the gate, cage and Director, clear the fade and alarm, show the human and corridor props, and reset WOLF's z, sprite and modulate. Proposal: one `_clear_intro_staging()`. That also removes P4's second and third copies.

### P16. Setters on the sync path
`_sync_records_room` writes three flags then `refresh_state()`, and `_sync_junction_room` writes four flags then sync calls. Proposal: give each room a `sync(state)` that reads M0State itself.

## 4. What should become what

### Components (scripts on existing scene nodes, so node paths stay the same)
1. **Hud** (script on `CanvasLayer`, or on a new child that holds references): `_refresh_ui`'s presentation part, `_set_dialogue`, `_show_top_card` and its tween, the speaker tag and tint, context-hint placement, tutorial prompt, touch and choice button layout, the checkpoint toast and name card timers, and the key-prompt helper. Its input is a small view model (status line, hint, objective, card key, choice answers, mode flags) that main or the room controller computes. It changes things only when values change. About 230 lines out of main.
2. **TitleScreen** (script on `CanvasLayer/TitleScreen`): continue and play again, credits (scroll, pause), changelog (load, bbcode, drag, held scroll, open online) and overlay switching. It emits `new_game_requested`, `continue_requested` and `settings_requested`. About 100 lines out of main.
3. **PauseMenu and settings glue**: fold `_pause_game`, `_resume_game`, `_show_settings`, `_show_title_settings`, `_fade_backdrop`, `_reveal_menu` and `_show_pause_menu` into PauseOverlay (pause_overlay.gd is 23 lines today). Move the video options (`_setup_settings`, `_resolution_size`, `_on_fps_selected`, `_on_resolution_selected`, `_on_fullscreen_toggled`, `_save_settings`) into GameSettings, which already owns the other settings and the config file. About 130 lines out of main.
4. **EndCard** (a small scene or a script building the same nodes, named `EndCard` and `EndCardContinue` under `CanvasLayer`): `_build_end_card`, `_end_card_label`, `_show_end_card` and its row building, plus `_hide_end_card`. `end_card_recap()` can stay as data on M0State or main. About 100 lines out of main.
5. **IntroSequence** (a data-driven beat list): `INTRO_LINES` plus per-step actions in `_advance_intro`, staging and teardown (P15). About 80 lines out of main.
6. **Knockdown/BeatSaver**: `_save_progress`, `_write_beat`, `_mark_beat`, `_capture_positions`, `_fail_beat`, `_restore_beat` and `_cancel_fail`. It needs hooks back into main for `_load_game` and `_sync_scene`. Medium value. Keep `_fail_beat`, `_save_progress` and `_load_game` callable on main, because the tests use them.
7. **Actor pose helpers on M0Actor**: P7.
8. **Impact.cue table**: P5.
9. **StationLabels helper**: P13.

### Per-room controllers (P1)
- **CorridorRoom** (new): owns the corridor beats K, the corridor set-up F, the bulkhead and seal door (`_sync_door`, `_door_lands`), the bypass, `_flash_relay_spark`, status lights and glows, the stakes line, the corridor hints, objective and restore line, `_wolf_off_relay`, and the corridor WOLF targets and spans. It holds references to the existing scene nodes, so paths do not move. About 450 lines out of main.
- **Records logic**: `_interact_records`, `_choose_mirror`, `_records_route_hint`, the Records hint, objective and restore line, the mirror-facing tweak and the WOLF mirror target. About 110 lines.
- **Junction logic**: all of R (`_tick_junction`, `_tick_lane`, sentry and tank events, bolt and hatch, lane choice, hints, objective, restore line, sound loops). This is the largest move, about 530 lines. JunctionRoom is already 1,243 lines of view code, so put this in a separate `JunctionBeats` script that owns PressureLine, SentryBrain, DropArm and the bolt state, and drives JunctionRoom.
- Each controller talks back to main through a narrow context: `say(line)`, `save()`, `mark_beat()`, `fail(reason)`, `open_choice(choice)`, `step_engineer(x, face)`, `update_controls()`, `begin_chapter_close(line)`, `enter_room()`, plus `state`, `human`, `wolf`, `impact` and `sfx`.

### Data
- Station records per room (P2). Location and close-card text per room. Restore lines per room and progress step. Objectives as an ordered list of (predicate, text) per room. Hint text per station and state.
- The choice definitions (relay, mirror, lane) (P8). The intro beat list (P15/L). The impact cue table (P5). The recap rows.
- Input defaults (U): `_install_inputs` could become the `[input]` section of project.godot. Caution: GameSettings.configure snapshots InputMap defaults (game_settings.gd 35), and `_add_action` skips existing actions. The ui_cancel and ui_accept joypad additions also need to land as `[input]` overrides of the built-in ui actions. Verify the rebinding reset path before doing this.

Expected result: main.gd at about 700-900 lines (boot, the mode state machine for title, intro, play, close, end and fail, room routing, actor control, saves), with the rest in about eight focused files. The total line count across files drops by about 400-600 from P1-P16 deduplication. The bigger win is that each file is readable on its own. Runtime "faster" comes mostly from the perf notes below, not from the split.

## 5. Test contract (what headless tests touch on main)

Eleven suites instantiate `res://scenes/main.tscn`: chapter_scene, junction, room_lights, ui_controls, impact, m0_scene, follow_spacing, room_depth, sentry, settings and sfx_bank. hold_use_test and m0_state_test do not use main. The tests use `game.call("name")`, `game.get` and `game.set`, `get_node` paths, and the script's constant map. Renaming or moving any of these breaks them unless main keeps a forwarding shim or the test changes in the same commit.

**Methods called (call count across suites):** _context_hint (43), _refresh_ui (33), _finish_intro (23), _new_game (22), _objective (17), _load_game (16), _sync_scene (13), _pause_game (10), _fail_beat (7), _save_progress (6), _interact (6), _process (5), _start_gameplay_camera (4), _resolution_size (4), _interact_checkpoint (4), _update_gameplay_camera (3), _show_end_card (3), _return_to_title (3), _resume_game (3), _refresh_continue (3), _note_input_device (3), _finish_chapter_close (3), _drop_ready (3), _advance_intro (3), _update_controls (2), _title_first_button (2), _on_reduced_motion_changed (2), _on_fps_selected (2), _input (2), _hold_station (2), _handle_back (2), _tank_miss, _sync_door, _stop_junction_loops, _show_pause_menu, _on_resolution_selected, _leave_junction, _interact_relay, _interact_breaker, _enter_junction, _drop_waits_for_wolf, _door_blast, _close_end_card, _choose (1 each).

**Properties read:** beat_snapshot, bolt_state, breaker_status_glow, bypass_handle, bypass_ticks, bypass_venting, changelog_text, chapter_close_active, choice_context, controller_active, corridor_depth, credits_paused, door_dust, door_lip, door_open_art, drop_arm, end_card_active, engineer_step_x, fail_active, fps_options, hatch_exit_walking, impact, intro_active, intro_step, intro_tween, junction_room, lane_choice, name_card_remaining, pause_overlay, pressure_line, records_room, relay_refused, relay_sparks, relay_status_glow, resolution_options, save_error, save_path, save_pending, seal_leaf, seal_opening, sentry_brain, settings_menu, sfx_bank, stakes_spoken, state, status_line, title_open, tutorial_step, waiting_for_choice, wolf_baiting, wolf_broke_off, wolf_heading_to_relay, wolf_scouting.

**Properties set:** auto_pause_on_focus_loss, bolt_state, chapter_close_active, controller_active, effects_enabled, lane_choice, save_path, settings_path, state, status_line, touch_enabled, waiting_for_choice.

**Constants read** (via `get_script_constant_map()` or `preload("res://scripts/main.gd")`): CORRIDOR_DOOR_LEFT_X, CORRIDOR_STATIONS, RECORDS_STATIONS, JUNCTION_STATIONS, STATION_OVERLAP, INTRO_LINES, WOLF_MIRROR_X, BYPASS_CRANK_X, BYPASS_WHEEL, WOLF_BYPASS_CLEAR_X, RELAY_X.

**Node paths (under Main):** BreakerArt, BreakerLabel, BreakerStatusLight, CheckpointArt, CheckpointLabel, CorridorDepth, Door/CollisionShape2D, Door/Visual, Door/Visual/DoorArt, Human, Human/BodySprite, Human/CollisionShape2D, IntroCamera, IntroDirector, IntroGate, PurgeTerminalArt, RelayArt, RelayLabel, RelaySpark, RelayStatusLight, Wolf, Wolf/BodySprite, Wolf/CollisionShape2D. Under CanvasLayer:
- BottomBar, BottomBar/Speaker, BottomBar/Story
- ContextHint, ContextHint/Text
- EndCard (and its EndCardContinue child)
- IntroAlarm, IntroFade, PauseButton
- PauseOverlay, Panel/PauseMenu and its ResumeButton, SettingsButton and TitleButton
- Panel/SettingsMenu and its BackButton and FPSOptions (ResolutionOptions is read too)
- TitleScreen and its ChangelogButton, ChangelogScreen (with ChangelogBody, ChangelogBackButton, ChangelogOnlineButton and ChangelogNote), ContinueButton, ContinueNote, CorridorArt, CreditsButton, CreditsScreen (with CreditsBody, CreditsBackButton and CreditsPauseButton), GameTitle, LogoMark, NewGameButton and SettingsButton
- TopBar, TopBar/Accent, TopBar/HUD
- TouchControls with Left, Right, Use, Choice1 and Choice2
- TutorialPrompt, TutorialPrompt/Text

Reflection nodes are found by name (`BreakerArtReflection`).

**Text:** about 125 assertions compare `status_line`, `_context_hint()` or `_objective()` output by `==`, `begins_with`, `ends_with` or `contains`. Moving text to data is safe only if every string stays byte-identical.

**Out-of-tree drivers (not the contract, but they will break):** the 56 capture and review scripts in scratchpad/capture-scripts use the same private API. The heaviest calls are `_sync_scene` (58), `_start_gameplay_camera` (49), `_new_game` and `_finish_intro` (45 each), `_save_progress`, `_objective`, `_advance_intro`, `_resume_game`, `_refresh_ui`, `_update_gameplay_camera`, `_sync_door`, `_show_credits`, `_hide_credits`, `_show_changelog`, `_show_pause_menu` and `_return_to_title`. They also get credits_body, changelog_body, sentry_brain, drop_arm, pressure_line and wolf_scouting, and set credits_paused.

Contract strategy: keep a thin facade on main for every name above. A property can become a getter or setter that forwards to the component, because `game.get("x")` resolves GDScript properties with `get:`. A method can forward in one line. Where a test reads internals of moved logic (for example `bolt_state`, `lane_choice`, `wolf_baiting` or `bypass_ticks`), forward the property, or update the test in the same PR. Test file updates are allowed, but each one changes what "same behaviour" is checked against, so prefer shims in the first pass.

## 6. Performance notes (phones are a target)

- `_process` calls `_refresh_ui()` every frame in every gameplay mode (725, 735, 745, 752 and 771). `_refresh_ui` rebuilds the whole HUD each frame. It calls `_objective()` (string building for `card_key`), `_context_hint()` (string ladders) and `settings_menu.prompt()` 1-4 times (it iterates InputMap events and builds strings), and runs `String.replace` on the hint. `_set_dialogue` then splits and slices the line and walks it for speaker detection. Fix: a dirty flag, or compare a small view-model tuple and apply only on change. Cache the prompts per input device and binding change.
- Theme overrides are re-applied every frame. `speaker.add_theme_color_override(...)` at 3064 runs every play frame, and during a choice `touch_choice_1/2.add_theme_font_size_override` runs every frame at 2960-2961. In Godot 4 each `add_theme_*_override` sends NOTIFICATION_THEME_CHANGED, which marks the Label's font dirty and re-queues a minimum-size update and redraw, so the text is reshaped each frame. Fix: set these only when the tint or layout changes. This is cheap and keeps the UI the same.
- `story.offset_left`, the `context_hint` position and size, and the `context_hint_text` size are written every frame (3061, 3067-3069). Write them only on mode change.
- The station tints, `bypass_handle.live`, the glow modulates and `human_tag.text` are reassigned every frame (3000-3008), even outside the corridor.
- The junction tick drives JunctionRoom every frame. `sync_line`, `advance_display`, `sync_arm` and `sync_bolt` each call `queue_redraw()` unconditionally (junction_room.gd 731-830), so the junction's large `_draw` runs every frame even at rest. This belongs to the junction-room area, but main triggers it.
- `_update_controls` allocates new arrays (`_machine_spans`) and calls `queue_redraw` on both actors. `_tick_corridor` and `_tick_junction` call it only when WOLF's target changes, which is fine. `_sentry_changed` sets it directly.
- Three per-frame label faders (EdgeFader, RecordsRoom._process and JunctionRoom._process) are cheap. Merging them is a cleanliness gain, not a speed gain.
- Other per-frame work (`_update_settle`, the per-station loops, `hold_use.advance`) is small. Splitting main into components does not by itself make the game faster. The HUD dirty-checking above is where measurable frame time is saved.

## 7. Risks

- **Ordering inside `_process`.** The sequence is: engineer step, camera, timers, mirror facing, fail gate, hold-use, settle, room tick, fail re-check, tutorial, choice keys, interact, then `_refresh_ui`. It is load-bearing: one frame of difference changes hints, holds and knockdowns that the tests assert. Keep this exact order when routing to controllers.
- **`_sync_scene` is the reset funnel.** It is used by load, restore, new game, room entry and tests. It resets attempt-scoped state (bypass, lane choice, WOLF baiting, reaction tweens, poses) before positioning. Split it carefully so each controller's `sync()` runs in the same order: door, Records, junction, lights.
- **Node-path stability.** Reparenting corridor props or HUD nodes breaks about 60 test paths and the capture scripts. Attach scripts to existing nodes rather than restructuring the scene.
- **Signal and tween ownership.** Tweens created with `create_tween()` on main are bound to main. Moving them onto a component changes which node's pause mode and lifetime governs them. `pause_overlay.create_tween()` is deliberate, because it must run while paused.
- **Text identity.** About 125 text assertions. Any rewording during the move is a test failure and a behaviour change.
- **Leaks.** check-game.sh fails a suite that leaks at exit. New RefCounted and Node components must be freed with the scene: add them as children, avoid static caches.
- **Merge collisions.** The round-3 branch (wt-r3, junction staging and opening hatch) touches the junction beats in main.gd. Refactor after it lands, or the merge will be painful.
- **Asset swap interaction.** The corridor bulkhead consts (45-48, the CORRIDOR_DOOR_* preloads) and `RoomDepth.make_bulkhead` are the "old door" art that the approved shutter-door concepts replace. Data-driving the door through a CorridorRoom controller makes that swap one place. Don't do both in the same step.
- **InputMap move to project.godot.** GameSettings snapshots the defaults at configure time. Ordering and duplication could change the rebinding reset behaviour.

## 8. Suggested order (small, playable steps)

1. Pure helpers with no contract change: P11 first_name, P12 relay_outcome, P6 tween kill, P10 key prompt (cached), P5 impact cues. Then the HUD dirty-checking (perf).
2. P3 run-state reset, P15 intro teardown, P4 corridor-prop list, P9 enter room and chapter close.
3. Extract TitleScreen, PauseOverlay or settings glue, and EndCard as components, keeping main shims for tested names.
4. P2 station records plus `station_at`, then P1 room controllers in this order: Records (smallest), corridor, junction (after round 3 lands).
5. Optional: text tables, InputMap to project.godot, a shared StationLabels helper.

Run `scripts/check-game.sh` after each step. Hints and choices are UI-visible, so take rendered stills of the HUD per mode: title, intro, corridor, choice (touch and keyboard), Records, junction, end card.
