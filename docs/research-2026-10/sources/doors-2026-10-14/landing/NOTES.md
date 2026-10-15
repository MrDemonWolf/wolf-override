# Landing the doors on main (October 14, 2026)

Branch `codex/doors`, from `origin/main` at c5d1d84 (PR #69). Nothing was played by hand, so nothing here is a claim about feel. The evidence is the headless suites and rendered stills from `tools/render/render.sh` (Godot in a container with software OpenGL).

## The port

The package was round 4 of `doors-r1` (`fix-r4/`), built on main 0c5d1ae. Its diff (`4f82ca5..9c219a1`, `apps/game` without `.godot`) was applied to main with `git apply -3`. Main had moved on by PRs #68 (knockdown body on the floor, a true sentry beam, PanelFront over the bolt panel) and #69 (WOLF out of machines). Conflicts and semantic merges:

- **Register:** the doors' entries replace the bulkhead entries.
- **PanelFront and HatchDoorway:** PanelFront (main) stays and still redraws the bolt panel over the sentry; HatchDoorway (the old hatch's sliding leaf) goes with the hatch art. The exit door's lens uses main's `bolt_lamp_color()` (with the refused-press flicker).
- **Knockdown limit (review r5 M1):** main's `DOOR_FOOT_X` came from the old bulkhead's front lip. It now comes from the new door's near column, the only front piece in the rows a lying body fills: `JunctionRoom.DOOR_FOOT_X..DOOR_FOOT_RIGHT_X` (x 487..510), the column's painted foot in the sealed and blown cuts. The stub's painting starts below the floor line (y 447), so it never covers a lying body. `Main._start_collapse` now ends a slump short of the column on either side: from the valve or against the door (falling right), and from the floor beyond the open doorway (falling left). `junction_test` measures the column and stub on the atlas, and knocks the engineer down at the valve and against the door (blast) and just past the blown door (facing back), each with Reduced Motion off and on, counting the column's and stub's painted pixels inside the lying body: none.
- **WOLF by the valve (PR #69):** main's `WOLF_RUBBLE_X` (his spot beside the valve) and his facing the engineer there are kept; the doors' own rubble spot and its "look back" facing are dropped. The doors' step in front of the valve while he walks past it after the blast stays (it does not touch his rest spots).
- **Bolt panel:** the doors moved the bolt panel from x 806 to 796, so the sentry's sight stops at its face at x 757.6 (`SentryBrain.PANEL_FACE_X`, main #68's constant).
- **Tests on main's newer suites:** `wolf_space_test` measures WOLF's rest spots against the new doors (the security container, the shut Records and junction entries and exits, the blast door's leaf and near column, the thrown leaf) and waits for the walk out of Records; `companion_rules_test` walks up to the open exit door before leaving.

## Fixes made while landing

- **Review r5 S1 (capture driver):** one frame's wait after time freezes, so the flight tween's pending step lands before the pose; the thrown leaf is posed at t 0.1, 0.2, 0.3, 0.45, 0.7 and 0.9 (`landing/driver/doors_capture.gd` at dee9996, now `../tools/driver/doors_capture.gd`). The frames now read in order: behind the near column, clear of it, in front of the column and the release, tipping, low and nearly flat.
- **Review r5 S2 (exit wall pack shadow):** `tools/exit_fixes.py` refills the hard diagonal band with the face's own concrete (same row, 14 px along) at 0.9x the lit concrete beside it, its edge softening with distance from the fitting, with a short contact shadow under the housing. Band mean luminance 33.7 -> 40.4 against 44.0 for the lit concrete beside it.
- **C1:** the warm streaks in the exit's floor wedge and carried-on deck take the wall pack's cool white at 0.85x their luminance (4,942 atlas px).
- **C2:** `tools/leaf_wear.py` rebuilds the three push-face kick plates as brushed stainless (mottle standard deviation 38-59 -> 10-13) and fades the evenly scattered scuff dashes outside the wear zones (by the lever, low on the leaf), keeping them there in uneven clusters.
- **C3:** `tools/speckle.py` fades the junction entry wall's isolated specks (4,460 px found) towards the local median, keeping them in uneven patches.
- **Decision (c), the coolant pipe:** `tools/exit_fixes.py` draws two 0.2 m pipes on a strap clamp along the passage's back wall seen through the open exit, at about 1.0-1.4 m, shaded as cylinders lit by the passage's fitting, in the wall's tint, with the grain of the room's own painted pipes. Deterministic image work; no Codex session.
- **DOOR DOWN ghost (inherited):** once the junction is cleared, a station plate caught in the edge fade is hidden instead of hanging half faded through the walk-out; `sentry_test` checks it.
- **Mint line through the tank (inherited):** gone on main since PR #68 moved the bolt feed off the wall; nothing to do.
- **Beam band over the alcove (inherited):** gone on main since PR #68: facing back over the TANK RELEASE the beam now stops at the alcove's right edge, and at the far end of its patrol it starts from behind the bolt panel (stills p01 and p02 from `driver2/panel_capture.gd`, and the phone j03-j04 frames).

## Fixes after the landing's verification

A fresh-clone verification of the branch (render.sh, the touch layout) found these; all fixed on the branch:

- **Grey corner at the junction's right end, touch layout (major):** the junction's play view runs on to `JunctionRoom.EXIT_VIEW_RIGHT` (x 1030), past the mid plate's right bleed (x 976), where only the exit's own pieces cover the far plate. The exit deck ends at y 584, and the touch framing (`Main.GAMEPLAY_CAMERA_Y_TOUCH` 392 at zoom 1.35) shows down to about y 592, so a flat grey block (the far plate) showed in the bottom right of every frame near the right end (j08-j12). The deck's bottom rows are now mirrored on down past its end (`ExitDeckBleed`, 40 world px), as the room's mid plate's bottom bleed does. The same check found that a camera shake there (the bolt's arc at 0.8 trauma shakes up to 6.4 px; `Impact.MAX_SHAKE_PX` is 10) would show the far plate past the passage's and deck's right end (x 1032) in either framing, so their last 12 world px are mirrored on past it too (`ExitBeyondEdgeBleed`, `ExitDeckEdgeBleed`, `ExitDeckBleedEdgeBleed`). Each bleed starts 2 atlas px short of its piece's edge and overlaps it by 1 world px (`EXIT_SEAM_TRIM`): a first version mirrored from the edge itself, and the edge texel, filtered with the transparent atlas gap beside it, let a faint 1 px line of the far plate through at the seam in the touch stills. `room_depth_test` now samples the view right of the mid plate at the junction's right end (keyboard and touch framing, shaken both ways) and requires every point inside an exit piece; with the deck bleed cut to 2 px it fails at (976, 586).
- **Evidence for the corner fix:** render.sh runs `land-doors-fix-phone` (touch layout, saved at 1920x1080) and `land-doors-fix-desk` (1280x720 with the budget), junction j01-j15: no flat far-plate grey and no seam line left in the bottom-right corner of any phone frame (j08-j12 had the block before); the desk frames differ from the earlier branch run only by timing (particles, the blast's shake, the sliding door's moment). Draw calls, objects, additive items and texture memory are unchanged in every junction state (j08 79 calls, j11 79, 77.33 MB). `bun run game:check` passes 21 of 21 suites.
- **Site wording:** the Status page's "Leaving through the hatch" and "the exit hatch" now say door; the Testing page no longer lists the removed hatch doorway among the render boxes, and its knockdown check names the blast door's near column and stub (with the new knockdown just past the doorway) instead of the old bulkhead's pillar.
- **Changelog:** the phone stills are 1920x1080 (the container's size for a 2400x1080 request), not 2400x1080.
- **Register:** `junction-hatch.png` and `corridor-bulkhead-open.png` were deleted on 2026-10-14 by this branch (not 2026-10-13); two plate entries had a missing full stop.
- **Left for Nathanial (design call):** an engineer who stops in the blown doorway at about x 490-505 is almost hidden by the blast door's solid near column (x 487-510), as round 4 drew it; main faded the old bulkhead's pillar in front of a character instead.

## Fixes after the second verification (October 15, 2026)

- Changelog: the four entries moved from main's October 14 section to a new October 15 section (the earliest merge day, since three other branches land first); the in-game changelog is regenerated and the drift check is green.
- Asset register: the junction exit atlas, the Records doors atlas and the Records far plate cited tool scripts under `junction-exit-door-2026-10-13/` and `records-doors-2026-10-13/`, folders that were never filed; they now point at `doors-2026-10-14/junction-exit/tools/` and `doors-2026-10-14/records/tools/`, where the scripts are. A script check of every `docs/` and `apps/` path in the register finds no other missing path from this branch (the one left, `apps/docs/public/fonts`, is main's). The two code comments that named those folders now name the filed ones.
- Asset register: the EXIT BOLT panel entry described the old spot (x 806, cables into the hatch frame); it now gives x 796 left of the sliding exit door, worked from about x 747, its riser to a floor flange in the exit atlas's back layer, and the lamp and feed redrawn over the sentry (BoltPanelFront).
- Not changed: the solid near column that hides an engineer stopped in the blown doorway stays an open call for Nathanial.

## Fixes after the third verification (October 15, 2026)

- Filed fix round 1's own entry door and exit door tools, which the register cites and which differ from the later rounds' copies: `fix-r1/jentry/tools/` (jemodel, jedesign, jeinputs, jeclean, jeinstall) and `fix-r1/hatch/tools/` (geom, design, leaf, noleaf, compose, imgkit, cleanup, hinstall, install, manifest, run_codex.sh), through `file_records.py`, with scratch paths shortened as before.
- Asset register: the junction far plate, the entry atlas, the mid plate and the exit atlas now cite those tools by their full filed path (the mid plate's `jemid.py` at `fix-r2/jentry/jemid.py`, where it is filed), the blast door atlas's `grade.py` at `fix-r1/tools/grade.py`, the entry atlas's `rgrade.py` at `fix-r1/tools/rgrade.py` and one `grade2.py` at `fix-r2/tools/grade2.py`, each with the full `docs/research-2026-10/sources/doors-2026-10-14/` prefix. No path in the register starts at a round folder or a scratch folder any more; every full tool path in it resolves, and bare script names are left only after their round's own filed folder.
- Code comments: `junction_door_layout.gd` names the filed `junction/tools/install.py` and `records_room.gd` the filed `fix-r4/tools/`, not the scratch folders. Comments only; nothing drawn or run changes.

## Wording

See `../../../../decisions.md` ("Doors landed") and `../../../approved/`: every line about the junction exit says "door"; the tank's hit is two one-speaker boxes; the Records container hint names the container.

## Evidence

- Suites: every `apps/game/tests/*_test.gd`, run by `bun run game:check` (twice) on the final branch.
- Stills: `render.sh` (now `../tools/render.sh`) with `landing/driver/doors_capture.gd` at dee9996, before (an untouched `git archive` of `origin/main`) and after (this branch), at 1280x720 (with the budget) and 2400x1080 with the touch layout (`--touch=1`), runs `land-doors-{before,after}-{desk,phone}`; the sentry at the far end of its patrol and its beam facing back over the alcove come from `driver2/panel_capture.gd` (p01, p02).
- Budget: `perf.py` compares the drivers' per-state draw calls, objects, visible additive items and texture memory (p50 and max over 60 frames, 1280x720, software GL):

| State | Draw calls p50 (max), main -> doors | Objects p50 | Additive items (room) | Texture MB |
|---|---|---|---|---|
| r01-arrival | 49 (53) -> 49 (53) | 209 -> 209 | 9 (9) -> 9 (9) | 75.20 -> 77.08 |
| r03-arrival-closed | 49 (49) -> 49 (49) | 209 -> 209 | 9 (9) -> 9 (9) | 75.20 -> 77.08 |
| r04-copy-point | 47 (47) -> 45 (45) | 146 -> 158 | 9 (9) -> 9 (9) | 75.20 -> 77.08 |
| r07-exit-open | 47 (47) -> 45 (45) | 211 -> 208 | 9 (9) -> 9 (9) | 75.20 -> 77.08 |
| r11-entry-shut | 92 (92) -> 82 (82) | 269 -> 244 | 10 (10) -> 9 (9) | 75.45 -> 77.33 |
| j01-sealed | 90 (90) -> 80 (80) | 297 -> 272 | 10 (10) -> 9 (9) | 75.45 -> 77.33 |
| j04-blown | 97 (101) -> 85 (90) | 696 -> 655 | 10 (10) -> 9 (9) | 75.45 -> 77.33 |
| j06-lane-sentry | 104 (105) -> 94 (95) | 355 -> 344 | 10 (10) -> 9 (9) | 75.45 -> 77.33 |
| j08-exit-bolt | 94 (94) -> 79 (79) | 287 -> 263 | 9 (9) -> 8 (8) | 75.45 -> 77.33 |
| j11-hatch-open | 99 (99) -> 79 (79) | 270 -> 248 | 9 (9) -> 8 (8) | 80.13 -> 77.33 |

  Draw calls and additive items are equal or lower in every state; texture memory is +1.88 MB (the package measured the same), and lower in j11, where main still loaded the old hatch passage.
- Against the package frames Nathanial approved (`compare.py`, share of pixels more than 8/255 apart on the frames without UI): median 2.2 % over 65 shared states (main's newer text and UI). The larger ones are explained: j03 (about 40 %) is the blast's camera shake at a different moment and the thrown leaf now posed where review r5 said it should be (S1); j05 (59 %) is WOLF holding back by the valve (PR #69) and a camera a few px further; j10 (22 %) catches the sliding door at a slightly different moment.
- Both phone runs requested 2400x1080 with the touch layout; the container saved them at 1920x1080, as the package's phone runs did. The package's phone frames had no touch layout, so the phone frames differ from them mostly by the touch framing (the camera sits lower) and the touch buttons; they were compared with main's phone frames instead.

## Not done

- No hand play: the thrown leaf, the swing and the walk-outs are unseen in motion.
- Review r5's other could items (C4 the landing swap, C5 roller scuffs, blast column blotches, smooth hairline cracks, darker blast puffs) are left as they are.
