# WOLF//OVERRIDE CI/CD audit (read-only)

Date: 2026-10-12. Repo: MrDemonWolf/wolf-override (public), main at 74a94c9, clean tree.
Sources: .github/workflows/game.yml, .github/workflows/docs.yml, .github/dependabot.yml, scripts/check-game.sh, scripts/check-docs-export.sh, root and apps/docs package.json, apps/docs/next.config.mjs, apps/docs/app/downloads.test.ts, apps/docs/content/docs/development/testing.mdx, read-only `gh api` / `gh run` calls. Raw evidence (job timings, failed logs, failure artifacts) was in the session scratch (not kept); the run list and job timings are kept in [`data/`](data/).
Nothing was changed in the repo or in GitHub settings. No Godot or game binary was run.

## 1. What exists today

### game.yml ("Game checks", job `godot`)
- Triggers: push to main, every pull_request (no path filter), workflow_dispatch.
- `permissions: contents: read` at workflow level; checkout with `persist-credentials: false`.
- ubuntu-24.04, job `timeout-minutes: 15`; check step `timeout-minutes: 10` (raised from 5 in 69716c8 on 2026-10-11).
- Godot 4.7.2 Linux zip fetched with `curl --retry 3`, SHA-256 verified, not cached (download + unzip is under 3 s).
- `scripts/check-game.sh`: isolates HOME / XDG_DATA_HOME / XDG_CONFIG_HOME in a mktemp dir; verifies the committed changelog export; runs `--import` twice (first with `|| true`); fails the second import on `^ERROR:|SCRIPT ERROR|Parse Error`; runs all 14 `apps/game/tests/*_test.gd` **sequentially, with no per-suite time bound**; fails a suite on non-zero exit, error lines, or `instances were leaked at exit`; fails if any file under apps/game changed.
- On failure or cancel, uploads `wolf-check-logs/` as `game-check-failure-logs` (7 days).
- No concurrency group, no cache, no artifacts on success, no export.

### docs.yml ("Deploy Docs", jobs `build` and `deploy`)
- Triggers: every pull_request (no path filter, needed because `build` is a required check); push to main filtered to `apps/docs/**`, `.github/workflows/docs.yml`, `package.json`, `bun.lock`; workflow_dispatch.
- `permissions: contents: read`; `deploy` alone gets `pages: write` + `id-token: write`.
- `build`: setup-bun 1.4.2 (pinned in workflow and in `packageManager`), `bun install --frozen-lockfile`, `docs:check` (fumadocs-mdx, next typegen, tsc), `docs:test` (downloads.test.ts), `docs:build` (next build static export + check-docs-export.sh). Uploads the Pages artifact only on non-PR runs of main.
- `deploy`: only for non-PR events on refs/heads/main, job-level `concurrency: pages` with `cancel-in-progress: false`, environment `github-pages`.

### dependabot.yml
- `github-actions` and `bun`, both monthly, directory `/`. No groups, no cooldown, default open-PR limit. Godot version and the workflow's `bun-version` are not tracked by Dependabot (manual).

### Action pins (all verified against upstream tags today)
| Action | Pin | Tag | Match |
|---|---|---|---|
| actions/checkout | 3d3c42e5… | v7.0.1 | yes |
| actions/upload-artifact | cf430e03… | v7 | yes (supports `archive: false`) |
| oven-sh/setup-bun | 0c5077e5… | v2 | yes |
| actions/upload-pages-artifact | fc324d35… | v5 | yes |
| actions/configure-pages | 45bfe019… | v6 | yes |
| actions/deploy-pages | 368f8252… | v5 | yes |

No `pull_request_target`, no untrusted `${{ github.event.* }}` interpolated into `run:` scripts.

## 2. GitHub settings (read-only)

- **Ruleset "Solo Main Protection"** (id 24736703, active, target `~DEFAULT_BRANCH`): rules `deletion`, `non_fast_forward`, `required_status_checks` = `godot` + `build` (integration 15368 = GitHub Actions), `strict_required_status_checks_policy: false`, `do_not_enforce_on_create: false`. No pull-request rule. Bypass: RepositoryRole id 5 (Admin), mode `always`. No classic branch protection.
- **Actions permissions**: enabled; `allowed_actions: all`; `sha_pinning_required: false`.
- **Default workflow token**: `default_workflow_permissions: write`; `can_approve_pull_request_reviews: true`.
- **Fork PR approval**: `first_time_contributors`.
- **Artifact and log retention**: 90 days (maximum 90).
- **Pages**: `build_type: workflow`, custom domain `wolfoverride.mrdemonwolf.dev` (verified), HTTPS enforced, certificate approved (expires 2026-12-29, auto-renews), public. Environment `github-pages`: custom branch policy, only `main`. No environment secrets or variables.
- **Secrets / variables (names only)**: repository secrets 0, repository variables 0, environment secrets 0, Dependabot secrets 0, organization secrets visible to the repo 0.
- **Caches**: 1 active cache, `bun-gmoqYqdUbaYsI0KujeXt7Zg/p0I=` (setup-bun's Bun binary, 34 MB, created 2026-09-28 on main, last used 2026-10-12). Nothing else is cached.
- Repo: merge, squash and rebase merges all allowed; auto-merge off; delete-branch-on-merge off.

## 3. Last 30 workflow runs (2026-10-10 19:25Z to 2026-10-12 05:07Z)

15 "Game checks" runs, 15 "Deploy Docs" runs. Docs: 15/15 success (5 deploys, all success). Game: 12 success, 3 failure.

| Job | Duration range | Recent typical |
|---|---|---|
| `godot` (whole job) | 131–319 s | ~312–319 s |
| of which check step | 122–308 s | ~303–307 s |
| docs `build` | 22–40 s | ~30 s (Next build 10–17 s, install ~4 s) |
| docs `deploy` | 10–17 s | ~12 s |

Check-step growth: 125 s on 2026-10-11 16:56Z, 242 s at 21:02Z, 289 s at 02:02Z, 306 s by 05:07Z (2.4x in about 12 hours of commits, mostly new suites).

Per-suite time on the latest main run (38206566335): follow_spacing 63.8 s, sentry 59.4 s, m0_scene 47.4 s, debug_tools 43.6 s, junction 28.3 s, chapter_scene 23.2 s (includes changelog check and both imports), impact 13.5 s, room_lights 11.2 s, settings 6.2 s, ui_controls 4.3 s, sfx_bank 3.0 s, room_depth 1.7 s, m0_state 0.3 s, hold_use 0.2 s.

### Failures and why
| Run | Event | Commit | Cause |
|---|---|---|---|
| 38196235196 | PR codex/logic-round-3 | 372b724 | Step timeout at the old 5-minute limit. All 14 suites had passed; the last `pass` line (02:38:30.268) came 0.01 s before `##[error]The action 'Import and run headless checks' has timed out after 5 minutes`. Fixed by 69716c8 (10-minute limit). |
| 38175106745 | push main | 76d3a50 | `chapter_scene_test`: "Chapter scene checks passed" then `WARNING: 2 ObjectDB instances were leaked at exit`. Tree is identical to PR head 71924f2, which passed (38174733149). **Flaky.** |
| 38079713104 | push main | e54c338 | Same 2-object leak in `chapter_scene_test`. Tree identical to PR head 1d5ae47, which passed (38079534425). **Flaky.** |

Flaky step: the leak gate (added aba016d on 2026-10-10) has failed 2 of the 19 game runs since then, both on main after a green PR, so main went red twice with no code change. The test's own comment (chapter_scene_test.gd:213) already notes the audio mixer releases a stopped clip "a few steps later" and waits a fixed `create_timer(0.1)` before `quit()`; on a slow runner that is not always enough.

### The 16 first-import font errors
Every run's `import-first.log` (checked in all three failure artifacts) has exactly 16 `ERROR:` lines: the project theme `res://assets/fonts/game_theme.tres` is loaded at startup before `Roboto-Variable.ttf` and `Montserrat-Variable.ttf` have `.fontdata` in `.godot/imported/`, so the chain fails (`.fontdata` missing, `.ttf` load, `Roboto-Regular.tres` / `Montserrat-Semibold.tres` ext_resource parse errors, `game_theme.tres:440`, "Error loading custom project theme"). The second import is clean. They are expected on any fresh checkout, including any export job's first import. Because the first import runs with `|| true` and its log is never inspected, any **new** first-import error or a crash of that pass is invisible.

### Cache use
- docs: setup-bun restores its Bun binary cache on every run (hit). Dependencies are not cached; `bun install` takes about 4 s, so none is needed. Next.js prints "No build cache found"; the build is 10–17 s, so not worth caching.
- game: no cache. Godot download is under 3 s; the two imports take a share of the 23 s attributed to the first suite. An import cache would save little and risks stale `.godot/` state. Not recommended for checks.
- Future exports: the 4.7.2 export template bundle is 1,281,349,702 bytes (1.28 GB, SHA-512 `ca4d71c4…ccb84079` in the release's SHA512-SUMS.txt). That will need a cache (see 5.3).

## 4. Risks and gaps, ranked by impact, with exact fixes

"Repo" = touches only files in the repository and belongs in this job. "Nathanial" = a GitHub setting; reported only.

### R1. Flaky ObjectDB leak in chapter_scene_test reddens main (High, Repo)
Evidence above (2 of 19 runs, both on main). A future export job that `needs: godot` would also be skipped by it.
Fix (apps/game/tests/chapter_scene_test.gd, teardown at lines 212–217): replace the fixed `await create_timer(0.1).timeout` with a bounded wait for the actual condition, e.g. after `game.queue_free()` loop up to ~60 frames (`await process_frame`) until no `AudioStreamPlayer`/`AudioStreamPlayer2D` under root is `playing`, then a further `for i in 5: await process_frame` before `quit()`. To find the real leaked objects, have check-game.sh re-run a suite once with `--verbose` when its only failure is the leak line and keep that log (`$logs/$name.verbose.log`), so the artifact names the two objects. Do not blanket-retry or drop the leak gate. Note: this is a test-file change; whoever owns game tests should make it (separate from the build job if scope is strict).

### R2. No per-suite hang watchdog; local runs are unbounded (High, Repo)
A suite that never calls `quit()` (an `await` on a signal that never fires) burns the whole 10-minute step; the remaining suites never run; the log only shows a partial file with no "TIMEOUT" line. Locally (`bun run game:check`) it hangs forever. The two `--import` calls are also unbounded.
Fix (scripts/check-game.sh): add a portable bound and use it for both imports and each suite:
```bash
suite_limit="${SUITE_TIMEOUT:-180}"   # longest suite today: 64 s on CI
bounded() {
  if command -v timeout >/dev/null 2>&1; then timeout --kill-after=10 "$suite_limit" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout --kill-after=10 "$suite_limit" "$@"
  else perl -e 'alarm shift; exec @ARGV or die' "$suite_limit" "$@"; fi   # macOS has perl, not timeout
}
```
and in the loop capture the exit code: 124 (timeout) or 142 (perl SIGALRM) prints `FAIL  $name (timed out after ${suite_limit}s, see …)`. Keep the 10-minute step limit as the outer guard.

### R3. Check-step headroom is shrinking (Medium-High, Repo)
306 s against 600 s; it already hit the old 300 s limit once and grew 2.4x in a day. One or two more heavy suites put it back near the limit.
Fix (scripts/check-game.sh): run suites in parallel with a per-suite HOME (they share `user://` today: settings.cfg, m0-save.json, debug-captures, so they must not share it when parallel). Give each suite `HOME="$work/home-$name"` and `XDG_DATA_HOME`/`XDG_CONFIG_HOME` under it, run with `xargs -P "${CHECK_JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu)}"` or background jobs plus `wait`, and print results in sorted order. ubuntu-24.04 public runners have 4 vCPUs; expect roughly 100–120 s (bound by follow_spacing + sentry). Keep a `CHECK_JOBS=1` path for debugging. Lower-effort alternative: raise step limit to 12 and job to 18 minutes, which only buys time.

### R4. First import hides new errors (Medium, Repo)
`|| true` and no inspection of `import-first.log`.
Fix (scripts/check-game.sh): after the first import, extract `grep -E '^ERROR:' "$logs/import-first.log"` and compare to an allowlist of the 16 known font/theme lines (store them as patterns in the script, matching `Roboto-Variable|Montserrat-Variable|Roboto-Regular.tres|Montserrat-Semibold.tres|game_theme.tres|custom project theme`); fail if any other `ERROR:`, `SCRIPT ERROR` or `Parse Error` appears, or if the pass is killed by the timeout from R2. Any export script must run the same two-pass import before `--export-debug` and apply the same allowlist to its log.

### R5. Default workflow token is write and Actions may approve PRs (Medium, Nathanial)
Both workflows declare `contents: read`, so today's jobs are fine, but any new workflow that forgets `permissions:` gets a write token, and `can_approve_pull_request_reviews: true` lets a workflow approve PRs.
Fix: Settings > Actions > General > Workflow permissions: "Read repository contents and packages permissions"; untick "Allow GitHub Actions to create and approve pull requests". (API: `PUT /repos/MrDemonWolf/wolf-override/actions/permissions/workflow` with `default_workflow_permissions=read`, `can_approve_pull_request_reviews=false`.) In-repo guard meanwhile: every new workflow keeps a top-level `permissions: contents: read`.

### R6. Any action may run and SHA pinning is not enforced (Medium, Nathanial)
All current actions are pinned and verified, but nothing stops a future unpinned `@v1` or a third-party action.
Fix: Settings > Actions > General: "Allow MrDemonWolf, and select non-MrDemonWolf, actions and reusable workflows", allow actions created by GitHub plus `oven-sh/setup-bun@*`, and enable "Require actions to be pinned to a full-length commit SHA". (API: `PUT …/actions/permissions` with `allowed_actions=selected`, `sha_pinning_required=true`, then `PUT …/actions/permissions/selected-actions` with `github_owned_allowed=true`, `patterns_allowed=["oven-sh/setup-bun@*"]`.) If the build job adds `actions/cache`, it is GitHub-owned and covered.

### R7. Fork PRs could publish downloadable executables built from untrusted code (Medium for the new builds, Repo + Nathanial)
The repo is public; any signed-in user can download artifacts. A build-on-every-PR job would turn a fork PR into a public "WOLF//OVERRIDE" debug binary built from code you have not reviewed; first-time-contributor approval only gates the very first PR.
Fix (Repo): guard the export/upload steps with `if: github.event_name != 'pull_request' || github.event.pull_request.head.repo.full_name == github.repository`. Fix (Nathanial): Settings > Actions > General > "Require approval for all external contributors" (API `PUT …/actions/permissions/fork-pr-contributor-approval` with `approval_policy=all_external_contributors`).

### R8. No concurrency control; superseded PR runs keep going (Medium-Low, Repo)
Window shows overlapping full runs for superseded commits (9a603dd and 69716c8 17 s apart on logic-round-3, both ran ~5 min; af8433a and 494ef44 on track-design-notes). With macOS + Windows builds added this doubles or triples waste.
Fix (game.yml, and the docs `build` job via workflow-level block in docs.yml):
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
```
Main pushes are never cancelled (so every main commit gets its builds). In docs.yml keep the separate `pages` group on `deploy`.

### R9. A required-check name collision is easy to make (Medium-Low, Repo)
The ruleset matches by job name only (`godot`, `build`, any workflow). A new job named `build` (for example "build" for game exports) would satisfy or block the docs requirement unpredictably.
Fix: name export jobs distinctly, e.g. `export-macos` / `export-windows` (or one `export` matrix job with `name: export (${{ matrix.platform }})`). Do not add them to the ruleset in this job (settings change); if Nathanial later wants builds required, he adds those contexts.

### R10. Game checks run on docs-only PRs; main re-runs identical trees (Low, Repo)
Every docs-only PR spends ~5 min on `godot`; each merge re-runs the PR's identical tree on main. Path filters cannot be used on the PR trigger because `godot` is required (a skipped workflow leaves the check pending).
Fix (optional): first step computes `git diff --name-only ${{ github.event.pull_request.base.sha }}...HEAD` (needs `fetch-depth: 0`) and skips the heavy steps when nothing under `apps/game/`, `scripts/check-game.sh`, `scripts/export_changelog.py`, `apps/docs/content/docs/changelog.mdx` or `.github/workflows/game.yml` changed, so the job still reports success. Keep main pushes unconditional (they produce the builds Nathanial asked for and are where the flaky leak showed up).

### R11. Testing page is stale (Low, Repo)
apps/docs/content/docs/development/testing.mdx line 80 says "The check step has a 5-minute limit"; it is 10 minutes since 69716c8. Line 82 says "This pipeline does not create game installers", which the build job will change. Fix: update both when the build job lands, and add the "get and open the builds" section there.

### R12. Pages deploy ordering (Low, Repo)
Deploy is safe in the important ways: PRs never upload a Pages artifact, `deploy` only runs on refs/heads/main, the environment allows only `main`, `pages`/`id-token` write are scoped to `deploy`, no secrets exist, export guard (check-docs-export.sh) blocks broken static output. Residual: two quick main pushes build in parallel; if the older build finishes later, its deploy can run last and leave the older site live until the next push.
Fix: move the deploy serialization to the whole workflow for main pushes, e.g. top-level `concurrency: { group: docs-${{ github.ref }}, cancel-in-progress: ${{ github.event_name == 'pull_request' }} }` (this also satisfies R8 for docs), so build+deploy for main run in order. Optional: push path filter could also include `scripts/check-docs-export.sh`.

### R13. Ruleset posture (Informational, Nathanial)
`strict_required_status_checks_policy: false` and no PR rule: a PR that was green against an older main can merge and break main (caught only by the post-merge push run). Admin bypass is `always`, so direct pushes skip checks. For a solo repo this is a reasonable trade-off; if wanted, enable "Require branches to be up to date before merging". No change recommended in this job.

### R14. Dependabot hygiene (Low, Repo)
Fix (.github/dependabot.yml): add `groups:` per ecosystem (e.g. `actions: { patterns: ["*"] }`, `docs: { patterns: ["*"] }`) and `cooldown: { default-days: 7 }` to cut PR count and avoid same-day releases. Godot 4.7.2 URL + checksum, export templates checksum and `bun-version: 1.4.2` stay manual; consider `bun-version-file: package.json` in setup-bun to keep one source of truth.

### R15. Minor script hygiene (Low, Repo)
check-game.sh's `trap` removes only `$work/home`, leaving `$work` (changelog copy, local logs) in the temp dir on every local run. Fix: when `CHECK_LOG_DIR` is set (CI), `trap 'rm -rf "$work"' EXIT` is safe because logs live outside `$work`; locally, remove `$work` on success and keep it (printing its path) only when a suite failed.

## 5. Notes for the macOS/Windows debug build job

### 5.1 What a failing (or passing) export would and would not catch
Would catch: missing or invalid `export_presets.cfg` preset, missing/mismatched export templates (wrong version dir), invalid bundle identifier, unwritable output, and (only if the log is grepped for `ERROR:`) resources that fail to load or are missing dependencies during packing. Godot's exit code alone is not a reliable signal for resource errors, so also assert the output files exist and are non-trivial in size.
Would not catch: GDScript runtime errors, logic bugs, anything the headless suites miss; whether the game boots on real macOS/Windows; GPU/driver behavior of the GL Compatibility renderer; Gatekeeper/SmartScreen behavior; controller, audio device, save-path and window behavior on each OS; performance. An optional boot smoke on `macos-latest` / `windows-latest` (run the exported binary with `--headless` and a short `--quit-after` frame count, HOME/APPDATA isolated, fail on `ERROR:`/`SCRIPT ERROR` or crash) narrows "does it boot"; it is still not hands-on play and must not be described as such.

### 5.2 Preset and packaging gotchas
- `export_presets.cfg` does not exist yet. macOS preset needs a valid `application/bundle_identifier`; use `codesign/codesign=1` ("Built-in (ad-hoc only)", confirmed in the Godot binary's enum `Disabled,Built-in (ad-hoc only),rcodesign,Xcode codesign`), notarization disabled, universal binary, export to a `.zip`. Apple Silicon will not launch an unsigned arm64 binary at all; ad-hoc signing is required and needs no account.
- Windows preset: `application/modify_resources=false` when exporting from Linux (rcedit needs Wine; otherwise the export errors/warns), `codesign/enable=false`, `binary_format/embed_pck=true` for a single file; debug exports add a `.console.exe` wrapper by default (`debug/export_console_wrapper`), so the Windows artifact is two files unless disabled.
- Include filter `*.txt` is required (testing.mdx line 19): without it `assets/changelog.txt` and the two font OFL licenses are left out. Exclude `tests/*` and keep `*.md` out (apps/game/AGENTS.md). art-source/ has `.gdignore` and is not exported. No private story files live under apps/game.
- Debug tools: `debug_tools.gd` gates on `OS.is_debug_build()`, so `--export-debug` builds have them on, as requested. Some zone drawing is editor-only by design ("editor builds only").
- Templates: install under the isolated data dir, i.e. `$XDG_DATA_HOME/godot/export_templates/4.7.2.stable/` on Linux (or `$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable/` on macOS). Never use the real user dirs (checks already isolate HOME/XDG_*).
- Exporting both platforms from one ubuntu-24.04 job is fastest and reuses one import; macOS runners are slower to queue.
- Do not make the export job `needs: godot`: the flaky leak (R1) would skip builds. Run it in parallel.
- Artifacts: `actions/upload-artifact` zips directories and drops Unix permissions, which breaks the `.app`'s executable bit. Upload Godot's own macOS `.zip` as a single file with `archive: false` (supported by the pinned v7; the file name becomes the artifact name) or wrap in a tar. Set `retention-days: 14`. Include the short SHA in file names.
- Public-repo artifacts are downloadable by any signed-in GitHub user, and logs by anyone. Keep build logs free of story text (do not echo dialogue or state dumps in CI).

### 5.3 Caching templates
Download `Godot_v4.7.2-stable_export_templates.tpz` once, verify SHA-512 `ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079`, extract only `macos.zip`, `windows_debug_x86_64.exe`, `windows_debug_x86_64_console.exe` (and `version.txt`), and cache that small directory with a SHA-pinned `actions/cache` keyed `godot-templates-4.7.2-ca4d71c4`. Caches written on main are readable by PR runs; the first main run seeds it. The repo cache limit (10 GB) is far from reached (34 MB used).

### 5.4 Docs and site constraints
- `apps/docs/app/downloads.test.ts` asserts every planned platform says "no release date" and the primary action goes to `/docs/get-game/`. CI debug builds are test builds, not releases; do not add them to the downloads/platform list or the test fails (and the claim would be wrong).
- The changelog intro says "There is no public game package or automatic updater yet." Word the new bullet as unsigned debug test builds attached to CI runs, kept 14 days, not a release.
- Testing page needs: where to find builds (Actions run > Artifacts, sign-in required), macOS first open (Gatekeeper blocks it; System Settings > Privacy & Security > "Open Anyway", or `xattr -dr com.apple.quarantine` on the unzipped app), Windows first open (SmartScreen "More info" > "Run anyway"), and that these builds include the debug tools and were not played by hand in CI.

## 6. Split: this job versus Nathanial

In this job (repo files only): R1 (test teardown, if in scope), R2 hang watchdog, R3 parallel suites or longer limit, R4 first-import allowlist, R7 same-repo guard on build uploads, R8 concurrency blocks, R9 job naming, R10 optional change detection, R11 testing.mdx, R12 docs workflow concurrency, R14 dependabot groups/cooldown, R15 trap cleanup, plus everything in section 5.

Needs Nathanial (settings; not changed here):
1. Workflow token default to read; disable Actions approving PRs (R5).
2. Restrict allowed actions to GitHub-owned + `oven-sh/setup-bun@*`; require full-SHA pinning (R6).
3. Require approval for all external contributors' workflow runs (R7).
4. Optional: add the new export job names as required checks once they are stable; optional "require branches up to date" (R13).
No secrets, certificates or paid features are needed for unsigned debug builds; Actions minutes on standard hosted runners are free for public repositories.
