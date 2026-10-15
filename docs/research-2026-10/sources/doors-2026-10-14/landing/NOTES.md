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

- **Review r5 S1 (capture driver):** one frame's wait after time freezes, so the flight tween's pending step lands before the pose; the thrown leaf is posed at t 0.1, 0.2, 0.3, 0.45, 0.7 and 0.9 (`driver/doors_capture.gd`). The frames now read in order: behind the near column, clear of it, in front of the column and the release, tipping, low and nearly flat.
- **Review r5 S2 (exit wall pack shadow):** `tools/exit_fixes.py` refills the hard diagonal band with the face's own concrete (same row, 14 px along) at 0.9x the lit concrete beside it, its edge softening with distance from the fitting, with a short contact shadow under the housing. Band mean luminance 33.7 -> 40.4 against 44.0 for the lit concrete beside it.
- **C1:** the warm streaks in the exit's floor wedge and carried-on deck take the wall pack's cool white at 0.85x their luminance (4,942 atlas px).
- **C2:** `tools/leaf_wear.py` rebuilds the three push-face kick plates as brushed stainless (mottle standard deviation 38-59 -> 10-13) and fades the evenly scattered scuff dashes outside the wear zones (by the lever, low on the leaf), keeping them there in uneven clusters.
- **C3:** `tools/speckle.py` fades the junction entry wall's isolated specks (4,460 px found) towards the local median, keeping them in uneven patches.
- **Decision (c), the coolant pipe:** `tools/exit_fixes.py` draws two 0.2 m pipes on a strap clamp along the passage's back wall seen through the open exit, at about 1.0-1.4 m, shaded as cylinders lit by the passage's fitting, in the wall's tint, with the grain of the room's own painted pipes. Deterministic image work; no Codex session.
- **DOOR DOWN ghost (inherited):** once the junction is cleared, a station plate caught in the edge fade is hidden instead of hanging half faded through the walk-out; `sentry_test` checks it.
- **Mint line through the tank (inherited):** gone on main since PR #68 moved the bolt feed off the wall; nothing to do.
- **Beam band over the alcove (inherited):** see the PR's open issues and the stills.

## Wording

See `../../../../decisions.md` ("Doors landed") and `../../../approved/`: every line about the junction exit says "door"; the tank's hit is two one-speaker boxes; the Records container hint names the container.

## Evidence

- Suites: every `apps/game/tests/*_test.gd`, run by `bun run game:check` (twice) on the final branch.
- Stills: `render.sh` with `driver/doors_capture.gd`, before (an untouched `git archive` of `origin/main`) and after (this branch), at 1280x720 (with the budget) and 2400x1080 with the touch layout (`--touch=1`), runs `land-doors-{before,after}-{desk,phone}`.
- Budget: `perf.py` compares the drivers' per-state draw calls, objects, visible additive items and texture memory (the PR body has the table).

## Not done

- No hand play: the thrown leaf, the swing and the walk-outs are unseen in motion.
- Review r5's other could items (C4 the landing swap, C5 roller scuffs, blast column blotches, smooth hairline cracks, darker blast puffs) are left as they are.
