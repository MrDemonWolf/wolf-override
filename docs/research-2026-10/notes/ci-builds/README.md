# CI audit, test-build research and branch ruleset (October 8 and 12, 2026)

On October 12 Nathanial wanted automatic macOS and Windows test builds, with the debug tools on. Before building them, one agent audited the existing CI read-only (`CI-AUDIT.md`: the workflows, GitHub settings, the last 30 runs, the first-import font errors, cache use, and 15 ranked risks with exact fixes) and another researched how to export unsigned debug builds of the Godot 4.7.2 project from a Linux runner (`BUILD-RESEARCH.md`: debug against release exports and `OS.is_debug_build()`, export templates and their checksums, macOS ad-hoc signing and Gatekeeper, Windows SmartScreen, export filters, the licence notices a build must carry, artifact retention, concurrency and permissions). The result landed as PR #51 (test builds plus check fixes) and PR #53 (follow-up fixes), both merged on October 12; the PR description is in [`../pull-requests/pr-51-ci-test-builds.md`](../pull-requests/pr-51-ci-test-builds.md).

**Decisions:** the builds are debug exports so the debug tools are on without an unlock code, they are unsigned (macOS ad-hoc only), kept for 14 days, and made for pushes to main and pull requests from branches of the repository, never from forks. The GitHub settings the audit recommends (read-only default workflow token, only GitHub-owned actions plus setup-bun, approval of workflow runs for all outside contributors) are Nathanial's to change and were not changed by any agent.

`solo-main-protection-ruleset.json` is the "Solo Main Protection" branch ruleset as set up on October 8: deletion and force-pushes of the default branch blocked, the `godot` and `build` checks required, and repository admins allowed to bypass. It holds no secrets.

## Files

- `CI-AUDIT.md`: the read-only CI/CD audit of main at 74a94c9 (2026-10-12).
- `BUILD-RESEARCH.md`: the export and packaging research (2026-10-12), with every claim linked to its source at a pinned version. No export was run while researching.
- `data/game-runs-100.tsv`: the recent "Game checks" runs as listed by `gh run list` with a limit of 100 (49 runs: run id, event, branch, conclusion, commit, start time), the timing data behind the audit's headroom and flakiness findings.
- `data/jobs.txt`: per-step timings of the audited jobs.
- `solo-main-protection-ruleset.json`: the branch ruleset.

Failed-run logs, failure artifacts and the downloaded documentation pages stayed in the session scratch and were not kept; the pages are cited below instead.

## Credits

- Project owner, the request and the settings decisions: Nathanial Henniges.
- Audit, research, workflows and scripts: AI agents (Claude Code and Codex) working for him, using the GitHub CLI (`gh api`, `gh run`) read-only and the Godot 4.7.2 release assets.
- Software: Godot Engine 4.7.2 (MIT licence, Godot Engine contributors), GitHub Actions (GitHub), Bun.

### Sources cited in these notes

Every page below is linked at the point it is used in `BUILD-RESEARCH.md` (Godot links point at the `4.7.2-stable` tag so the line numbers stay stable). Accessed October 12, 2026.

- **Godot Engine documentation (Godot Engine contributors)**
  - <https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html> (`BUILD-RESEARCH.md`)
  - <https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html> (`BUILD-RESEARCH.md`)
  - <https://docs.godotengine.org/en/4.7/tutorials/export/feature_tags.html> (`BUILD-RESEARCH.md`)
  - <https://docs.godotengine.org/en/4.7/classes/class_os.html> (`BUILD-RESEARCH.md`)
  - <https://docs.godotengine.org/en/4.7/tutorials/io/data_paths.html> (`BUILD-RESEARCH.md`)
  - <https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html> (`BUILD-RESEARCH.md`)
  - <https://docs.godotengine.org/en/4.7/tutorials/export/running_on_macos.html> (`BUILD-RESEARCH.md`)
  - <https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_windows.html> (`BUILD-RESEARCH.md`)
  - <https://docs.godotengine.org/en/4.7/about/complying_with_licenses.html> (`BUILD-RESEARCH.md`)
  - <https://docs.godotengine.org/en/4.7/classes/class_engine.html> (`BUILD-RESEARCH.md`)
- **Godot Engine source (Godot Engine contributors)**
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform.cpp#L769-L776> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/editor/editor_node.cpp#L1398-L1424> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform_pc.cpp#L63> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/platform/windows/export/export_plugin.cpp#L251-L271> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.cpp#L1669-L1670> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform.cpp#L597-L599> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/editor/file_system/editor_paths.cpp#L75-L76> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/platform/linuxbsd/os_linuxbsd.cpp#L911-L923> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/editor/file_system/editor_paths.cpp#L140-L175> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.cpp#L1680-L1694> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform.cpp#L1970-L2042> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.cpp#L478> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.cpp#L510-L514> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/tree/4.7.2-stable/editor/export> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.cpp#L1191-L1198> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.cpp#L553-L555> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.h#L103-L124> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/core/os/os.cpp#L262-L288> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/main/main.cpp#L2403-L2413> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/platform/windows/export/export_plugin.cpp#L462> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform_pc.cpp#L65> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform_pc.cpp#L177-L195> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/platform/windows/export/export_plugin.cpp#L195-L204> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/tree/4.7.2-stable/platform/windows/export> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform.cpp#L691-L756> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export.cpp#L42-L114> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform.cpp#L616-L628> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.h#L134-L136> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot/blob/4.7.2-stable/platform/windows/export/export.cpp#L55> (`BUILD-RESEARCH.md`)
- **Godot Engine release builds (Godot Engine contributors)**
  - <https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz> (`BUILD-RESEARCH.md`)
  - <https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/SHA512-SUMS.txt> (`BUILD-RESEARCH.md`)
- **GitHub Docs (GitHub)**
  - <https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching#usage-limits-and-eviction-policy> (`BUILD-RESEARCH.md`)
  - <https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching#restrictions-for-accessing-a-cache> (`BUILD-RESEARCH.md`)
  - <https://docs.github.com/en/organizations/managing-organization-settings/configuring-the-retention-period-for-github-actions-artifacts-and-logs-in-your-organization> (`BUILD-RESEARCH.md`)
  - <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository> (`BUILD-RESEARCH.md`)
  - <https://docs.github.com/en/actions/reference/limits> (`BUILD-RESEARCH.md`)
  - <https://docs.github.com/en/billing/concepts/product-billing/github-actions> (`BUILD-RESEARCH.md`)
  - <https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts> (`BUILD-RESEARCH.md`)
  - <https://docs.github.com/en/rest/actions/artifacts#download-an-artifact> (`BUILD-RESEARCH.md`)
  - <https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#concurrency> (`BUILD-RESEARCH.md`)
  - <https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions> (`BUILD-RESEARCH.md`)
  - <https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary> (`BUILD-RESEARCH.md`)
- **GitHub Actions (GitHub), action repositories**
  - <https://github.com/actions/cache/releases> (`BUILD-RESEARCH.md`)
  - <https://github.com/actions/cache/blob/main/README.md> (`BUILD-RESEARCH.md`)
  - <https://github.com/actions/upload-artifact/blob/cf430e030ddbb5b0abf93d22962f4752f3646cd9/README.md#retention-period> (`BUILD-RESEARCH.md`)
- **Apple Developer documentation (Apple)**
  - <https://developer.apple.com/documentation/macos-release-notes/macos-big-sur-11_0_1-universal-apps-release-notes> (`BUILD-RESEARCH.md`)
  - <https://developer.apple.com/news/?id=saqachfa> (`BUILD-RESEARCH.md`)
  - <https://developer.apple.com/library/archive/technotes/tn2206/_index.html> (`BUILD-RESEARCH.md`)
- **Apple Support (Apple)**
  - <https://support.apple.com/en-us/102445> (`BUILD-RESEARCH.md`)
  - <https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac> (`BUILD-RESEARCH.md`)
- **Microsoft Learn (Microsoft)**
  - <https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/smartscreen-reputation> (`BUILD-RESEARCH.md`)
  - <https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/unblock-file> (`BUILD-RESEARCH.md`)
- **University of Wisconsin-Madison KnowledgeBase**
  - <https://kb.wisc.edu/hd-cps/144696> (`BUILD-RESEARCH.md`)
- **Microsoft Support (Microsoft)**
  - <https://support.microsoft.com/en-us/topic/what-is-smart-app-control-285ea03d-fa88-4d56-882e-6698afdb7003> (`BUILD-RESEARCH.md`)
- **Godot Engine documentation source (Godot Engine contributors)**
  - <https://github.com/godotengine/godot-docs/blob/4.7/about/complying_with_licenses.rst> (`BUILD-RESEARCH.md`)
- **Godot Engine source, 4.7.2-stable (Godot Engine contributors)**
  - <https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/LICENSE.txt> (`BUILD-RESEARCH.md`)
  - <https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/COPYRIGHT.txt> (`BUILD-RESEARCH.md`)
- **SIL Open Font License site (SIL International)**
  - <https://openfontlicense.org/open-font-license-official-text/> (`BUILD-RESEARCH.md`)
- **GitHub Changelog (GitHub)**
  - <https://github.blog/changelog/2026-07-17-actions-retention-will-cover-checks-workflow-runs-and-statuses/> (`BUILD-RESEARCH.md`)
  - <https://github.blog/changelog/2026-02-26-github-actions-now-supports-uploading-and-downloading-non-zipped-artifacts/> (`BUILD-RESEARCH.md`)
