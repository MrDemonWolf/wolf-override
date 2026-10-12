# Duplicate-code audit

September 30, 2026. Read-only audit of authored game scripts/tests, docs application/configuration and GitHub workflows. Generated imports, static asset bytes, dependencies, build output and private story drafts excluded. Rechecked during the camera and terminal-menu pass; line references describe that working tree. No application or test code changed by this audit.

Followed `audit-duplicates` skill and repository `AGENT.md`. Compared repeated blocks, definitions, callers, current helpers and deterministic checks. Similar syntax alone was not treated as a finding.

## Findings

### [MEDIUM] Scene tests duplicate the same input-driver behavior

**Duplicated in:**
- `apps/game/tests/chapter_scene_test.gd` (lines 153–171)
- `apps/game/tests/m0_scene_test.gd` (lines 262–280)

**What it does:** Advances scene frames, presses/releases actions, and walks an actor toward a target with the same 300-physics-frame limit and 12-unit tolerance.

**Impact:** Both independently maintained helpers drive the real scene; frame-order fixes, input release changes or movement-tolerance corrections must be copied across both suites. Chapter tests have 10 tap and 6 walk callers; M0 tests have 23 tap and 10 walk callers. Changing only one driver could make one route suite stop exercising the same interaction contract. This is a maintenance risk, not an observed current failure.

**Suggested helper:**
```gdscript
static func tap(tree: SceneTree, action: StringName) -> void
static func walk_to(tree: SceneTree, actor: M0Actor, target_x: float) -> bool
```

**Where to put it:** `apps/game/tests/scene_input.gd`, one test-only script preloaded by the two runners. Keep their different assertions, error prefixes and failure/quit policies local. Do not introduce a test framework or common base runner.

**Relevant verification after an authorized refactor:** Run `m0_scene_test.gd` and `chapter_scene_test.gd` with pinned Godot 4.7.2; preserve action release even when the frame limit expires. This audit did not run or modify tests.

---

### [LOW] Website raw-asset paths repeat the deployment-prefix rule

**Duplicated in:**
- `apps/docs/app/page.tsx` (line 7; value consumed by logo and artwork image sources)
- `apps/docs/app/layout.tsx` (line 13; favicon image source)

**What it does:** Maps `GITHUB_PAGES=true` to `/wolf-override`, otherwise an empty prefix, for files that do not pass through Next's Link routing.

**Impact:** A host/base-path change can update page artwork without updating the favicon, or vice versa. The conditional is small and correct today; no broken asset was observed by this source audit.

**Suggested helper:**
```typescript
export const publicAssetPrefix: string;
```

**Where to put it:** `apps/docs/lib/site.ts`, imported by these two server components only if the next deployment change actually touches this rule. `apps/docs/next.config.mjs:8` is the corresponding build-time `basePath` setting; keep it explicit unless a simple shared configuration already exists. Do not import the MDX-wrapped Next configuration into React or add a generalized URL builder.

**Relevant verification after an authorized refactor:** Check docs types and build with `GITHUB_PAGES=true`, then verify exported hero/logo/favicon paths and local-host paths.

---

## Reviewed repetition that should stay

- `GameSettings.number()` and `GameSettings.boolean()` already serve display and extra-preference readers. No parallel numeric/boolean preference validator needs extraction.
- Narrative state transitions and save validation serve different trust boundaries: runtime transitions prevent invalid progression; `M0State.from_dict()` rejects malformed saves. Collapsing them would weaken clarity or validation.
- Displayed dialogue and remembered-choice callbacks are distinct authored presentation. Similar conditions alone do not justify sharing prose or moving story into a generic formatter.
- Touch/pause button styles in `main.gd` differ intentionally from settings styles in `game_settings.gd` (translucency, borders, size and focus policy). Not identical design behavior; no universal theme factory recommended.
- The new `_update_gameplay_camera()` is the single gameplay camera target shared across corridor and Records Access. Intro and closing camera transitions intentionally use different authored framing.
- InputMap actions in project configuration are engine defaults, while the settings action list is the explicit subset users may remap. The list is not a copied implementation.
- Test assertions, unique save-file setup/cleanup, and independent failure messages are short and locally understandable. No shared fixture framework warranted.
- Docs/game CI share checkout syntax but use distinct toolchains, artifacts and permissions. No reusable workflow or composite action needed.
- Credits and changelog repeat facts intentionally across game/site. That editorial consistency is not duplicate source logic.
- Download-platform detection lives in one exported function exercised by `downloads.test.ts`; channel cards render from one registry. No duplicate platform algorithm found.

## Evidence boundary

Source and caller inspection only. No refactor applied, no runtime tests run by this audit, and no claim that these suggestions improve gameplay or visual quality. Existing landing-page work is preserved. `git check-ignore docs/duplicates-audit.md` confirms this report remains ignored locally.

**Summary: 0 HIGH, 1 MEDIUM, 1 LOW.** Neither finding blocks the landing-page release. Prioritize the shared test driver when input-test behavior next changes; defer the two-line asset-prefix cleanup until hosting configuration changes.
