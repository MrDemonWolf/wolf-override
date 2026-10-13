# Automatic macOS and Windows test builds: research

Research for WOLF//OVERRIDE (`apps/game`, Godot 4.7.2, GL Compatibility), gathered 2026-10-12.
The aim is to export **debug**, **unsigned** (macOS ad-hoc only) test builds for macOS and Windows on every push to `main` and every PR, from an `ubuntu-24.04` runner, kept for 14 days.

How this was checked: Godot's 4.7 docs, Godot source at the `4.7.2-stable` tag, the 4.7.2 release assets (read through the GitHub API and HTTP range requests; the 1.28 GB template archive was **not** downloaded in full), GitHub, Apple and Microsoft docs. **No export was run.** Every statement about export behaviour comes from the docs and source and still needs a real CI run to confirm. Nobody has played an exported build.

Source links point at the `4.7.2-stable` tag, so line anchors stay stable.

---

## 1. `--export-debug` vs `--export-release`, and `OS.is_debug_build()`

- Command-line export: `--export-release <preset> <path>` "Export the project in release mode using the given preset and output path. The preset name should match one defined in 'export_presets.cfg'. `<path>` should be absolute or relative to the project directory, and include the filename for the binary (e.g. 'builds/game.exe'). The target directory must exist." `--export-debug` is "Like `--export-release`, but use debug template. Implies `--import`." `--headless` is needed where there is no GPU, such as CI. — https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html
- The output path is resolved against the project folder, not the shell's working directory. — https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html
- Exporting with `debug` adds the feature tags `template`, `debug` and `template_debug`; release adds `template`, `release` and `template_release`. — https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform.cpp#L769-L776 and https://docs.godotengine.org/en/4.7/tutorials/export/feature_tags.html
- `OS.is_debug_build()` "Returns `true` if the Godot binary used to run the project is a *debug* export template, or when running in the editor. Returns `false` if the Godot binary used to run the project is a *release* export template." — https://docs.godotengine.org/en/4.7/classes/class_os.html
- **For this repo:** `apps/game/scripts/debug/debug_tools.gd:95` sets `debug_build = OS.is_debug_build()`, and line 242 makes the tools available when `unlocked or (debug_build and not session_locked)`. A `--export-debug` build therefore has the debug tools on with no unlock code, as Nathanial asked. Parts gated on `OS.has_feature("editor")` (for example `debug_zones.gd:879`, and render boxes for props drawn in code) stay off in any export, because export templates are not editor builds (feature tag `editor` = "Running on an editor build"). — https://docs.godotengine.org/en/4.7/tutorials/export/feature_tags.html
- Exit codes: a failed export (missing templates, configuration error or a failed `export_project`) exits with `EXIT_FAILURE`. An export that only **completed with warnings** still exits 0 and prints `Project export for preset "%s" completed with warnings.` — https://github.com/godotengine/godot/blob/4.7.2-stable/editor/editor_node.cpp#L1398-L1424. The workflow should search the export log for that line, because a failed built-in macOS signature is only a **warning** (see section 3).
- Debug Windows exports also copy a console wrapper (`<name>.console.exe`) by default. The `debug/export_console_wrapper` option defaults to `1` ("Debug Only"). — https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform_pc.cpp#L63 and #L185-L195. Testers can run the `.console.exe` to see the log.

## 2. Export templates for 4.7.2

| Item | Value | Source |
| --- | --- | --- |
| Release page | https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable (published 2026-08-18) | GitHub API `repos/godotengine/godot-builds/releases/tags/4.7.2-stable` |
| Templates (standard, not .NET) | https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz | same |
| Size | **1,281,349,702 bytes** (about 1.28 GB) | same (asset `size`) |
| SHA-512 (from `SHA512-SUMS.txt`) | `ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079` | https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/SHA512-SUMS.txt (5,682 bytes) |
| SHA-256 (GitHub asset digest) | `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011` | GitHub API asset `digest` |
| Linux editor already used by `game.yml` | `Godot_v4.7.2-stable_linux.x86_64.zip`, SHA-256 `cadd3204…29e4` (matches the asset digest); SHA-512 `9aa00f7a…ed54c65` | same + `.github/workflows/game.yml` |

**Verify:** pin the SHA-512 in the workflow (as `game.yml` does with the editor's SHA-256), rather than trusting a sums file downloaded from the same place:
`printf '%s  %s\n' ca4d71c4…84079 "$RUNNER_TEMP/templates.tpz" | sha512sum --check`

**What is in the archive** (central directory read with range requests; sizes uncompressed/compressed in bytes). Only these entries are needed:

| Entry | Uncompressed | Compressed |
| --- | --- | --- |
| `templates/macos.zip` (holds `godot_macos_debug.universal` and the release binary) | 123,597,580 | 122,879,307 |
| `templates/windows_debug_x86_64.exe` | 103,176,704 | 34,252,108 |
| `templates/windows_debug_x86_64_console.exe` | 188,928 | 76,459 |
| `templates/windows_release_x86_64.exe` (only for a later release build) | 109,268,480 | 37,890,306 |
| `templates/version.txt` (contents `4.7.2.stable\n`) | 13 | 13 |

The archive contains no ANGLE, D3D12 or accesskit DLLs. The Windows exporter copies them only when it finds them next to the template (https://github.com/godotengine/godot/blob/4.7.2-stable/platform/windows/export/export_plugin.cpp#L251-L271), so this project's export is one `.exe` (plus the console wrapper). The macOS template binary name is `"godot_macos_" + ("debug"|"release") + "." + architecture`. — https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.cpp#L1669-L1670

**Where Godot looks for templates:** `<editor data dir>/export_templates/<GODOT_VERSION_FULL_CONFIG>/<file>`, which is `…/export_templates/4.7.2.stable/`. — https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform.cpp#L597-L599 and https://github.com/godotengine/godot/blob/4.7.2-stable/editor/file_system/editor_paths.cpp#L75-L76
- On Linux the editor data dir is `$XDG_DATA_HOME/godot`, or `$HOME/.local/share/godot` when that variable is unset. A relative `XDG_DATA_HOME` is ignored. — https://github.com/godotengine/godot/blob/4.7.2-stable/platform/linuxbsd/os_linuxbsd.cpp#L911-L923 and https://docs.godotengine.org/en/4.7/tutorials/io/data_paths.html
- Alternative: in self-contained mode (a `_sc_` or `._sc_` file next to the editor binary), data goes to `editor_data/` beside the binary, so templates would go in `editor_data/export_templates/4.7.2.stable/`. — https://github.com/godotengine/godot/blob/4.7.2-stable/editor/file_system/editor_paths.cpp#L140-L175 and https://docs.godotengine.org/en/4.7/tutorials/io/data_paths.html
- **Recommendation:** keep the repo's isolation pattern from `scripts/check-game.sh`. Export with `HOME=$RUNNER_TEMP/godot-home`, `XDG_DATA_HOME=$RUNNER_TEMP/godot-home/.local/share` and `XDG_CONFIG_HOME=…/.config`, and extract the needed entries flat into `$XDG_DATA_HOME/godot/export_templates/4.7.2.stable/`, for example `unzip -j templates.tpz templates/macos.zip templates/windows_debug_x86_64.exe templates/windows_debug_x86_64_console.exe templates/version.txt -d "$dest"`.
- The docs describe only the editor's template manager and installing from a `.tpz` through it. — https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html. Extracting the files into that folder by hand is what the manager does; this is inferred from the source paths above.

**Caching with `actions/cache`:**
- Cache the **extracted subset** (about 227 MB uncompressed; `macos.zip` is already compressed, so the cache entry will be about 160 MB), not the 1.28 GB `.tpz`. Key: `godot-templates-4.7.2-ca4d71c4-macos-win64-debug-v1`. On a miss, download, verify SHA-512, extract, and let the post step save the cache.
- Cache limits: 10 GB per repository by default, and entries not accessed in over 7 days are removed. — https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching#usage-limits-and-eviction-policy
- Scope: runs restore caches from their own branch or the default branch. A cache created by a `pull_request` run is stored for the merge ref only and "can only be restored by re-runs of the pull request". — https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching#restrictions-for-accessing-a-cache. A `main` push should therefore populate the cache; PRs then restore it.
- Do not put secrets in caches: "Anyone who can open a pull request against your repository can read the contents of caches in the base branch." Templates are public, so this does not apply here. — same page.
- Latest `actions/cache`: `v6.1.0`, released 2026-06-26, a lightweight tag at commit `55cc8345863c7cc4c66a329aec7e433d2d1c52a9` (`git ls-remote`; https://github.com/actions/cache/releases). v5+ runs on Node 24 and needs runner ≥ 2.327.1. — https://github.com/actions/cache/blob/main/README.md. Pin by SHA; Dependabot already covers github-actions.

## 3. macOS export from a Linux runner

- **Formats:** the exporter accepts a path ending `.zip` or `.app`. `.dmg` and `.pkg` work only when exporting from a macOS host (`#ifdef MACOS_ENABLED`). — https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.cpp#L1680-L1694. The docs say: "single 'Universal 2' binary `.app` bundle… packed in a ZIP archive, or packed in a DMG disk image (only supported when exporting from macOS)". — https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html
- **Use `.zip`.** The docs warn that "`.app` bundles exported from Windows lack the `executable` flag and won't run on macOS. Projects exported as `.zip` are not affected by this issue." — https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html. Godot's zip writer stores Unix permissions in `external_fa`. — https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform.cpp#L1970-L2042
- **Universal binary:** `binary_format/architecture` is one of `universal,x86_64,arm64`, default `universal`. — https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.cpp#L478. Minimum macOS defaults: `11.00` (x86_64) and `13.00` (arm64). — same file, #L493-L494
- **Code signing:** `codesign/codesign` is `Disabled, Built-in (ad-hoc only), rcodesign[, Xcode codesign]`. On non-macOS hosts the default is **1 = Built-in (ad-hoc only)**. — https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.cpp#L510-L514. The docs describe it this way: built-in ad-hoc is for users without a Developer ID certificate, and "Godot will use an ad-hoc signature, which will make running an exported app easier for the end users". — https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_macos.html. It is implemented in `editor/export/codesign.cpp`, so no external tool is needed: https://github.com/godotengine/godot/tree/4.7.2-stable/editor/export
- **A failed built-in signature is only a warning:** `"Built-in CodeSign failed with error \"%s\"."` is an `EXPORT_MESSAGE_WARNING`. — https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.cpp#L1191-L1198. Combined with section 1, an unsigned app could export with exit code 0. **Fail the job if the export log contains `completed with warnings`**, or at least report it.
- **Notarization off:** `notarization/notarization` = `0` (Disabled), the default. — https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.cpp#L553-L555. Notarization with an ad-hoc signature is rejected anyway ("Notarization with an ad-hoc signature is not supported."). — same file, #L125-L128
- **Bundle identifier is required:** it must be non-empty and use only ASCII letters, digits, `-` and `.`. Otherwise `has_valid_project_configuration` fails. — https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.h#L103-L124 and export_plugin.cpp #L105-L111, #L2510+. Use, for example, `dev.mrdemonwolf.wolfoverride`.
- **App name:** the bundle is named after `application/config/name`, passed through `get_safe_dir_name`, which turns `/` and `\` (and `: * ? " < > |`) into `-`. **`WOLF//OVERRIDE` therefore becomes `WOLF--OVERRIDE.app`.** — https://github.com/godotengine/godot/blob/4.7.2-stable/core/os/os.cpp#L262-L288 and export_plugin.cpp #L1672-L1697. The tester instructions should use that name.
- **Apple Silicon:** "on Macs with Apple silicon… the operating system enforces that any executable must be signed before it's allowed to run… a simple ad-hoc signature is sufficient." Ad-hoc signatures "do not bear any valid identity, binaries signed this way cannot pass through Gatekeeper". — https://developer.apple.com/documentation/macos-release-notes/macos-big-sur-11_0_1-universal-apps-release-notes. So the ad-hoc universal app **runs natively on Apple Silicon**, but a downloaded copy is stopped by Gatekeeper until the tester approves it. Godot's own table agrees: ad-hoc signed and not notarized means the user must use Open Anyway; fully unsigned on Apple Silicon also needs `codesign -s - --force --deep`. — https://docs.godotengine.org/en/4.7/tutorials/export/running_on_macos.html
- **What Gatekeeper shows (macOS 15 and later):** an alert that Apple cannot check the app for malicious software, with **Move to Trash** and **Done**. The tester then goes to System Settings → Privacy & Security and clicks **Open Anyway**. — https://support.apple.com/en-us/102445. Since macOS Sequoia, "users will no longer be able to Control-click to override Gatekeeper when opening software that isn't signed correctly or notarized. They'll need to visit System Settings > Privacy & Security" (Apple, 2024-08-06). — https://developer.apple.com/news/?id=saqachfa. Godot's 4.7 page still lists right-click → Open, which is out of date for macOS 15 and later. — https://docs.godotengine.org/en/4.7/tutorials/export/running_on_macos.html
- **Tester steps (current Apple guide):** "choose Apple menu > System Settings, then click Privacy & Security… Go to Security, then click Open… Click Open Anyway… Enter your login password, then click OK." The button "is available for about an hour after you try to open the app." — https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac
- **Terminal alternative:** `xattr -dr com.apple.quarantine "WOLF--OVERRIDE.app"`. — https://docs.godotengine.org/en/4.7/tutorials/export/running_on_macos.html
- **Do not add files inside the `.app` after export.** "Bundles should be treated as read-only once they have been signed… If you modify a signed bundle, you must re-sign it afterwards." — https://developer.apple.com/library/archive/technotes/tn2206/_index.html. Licence files go **beside** the `.app` inside the zip (section 6).
- **Renderer note:** `rendering/gl_compatibility/driver.macos` defaults to `opengl3`, with `fallback_to_angle` set to true. — https://github.com/godotengine/godot/blob/4.7.2-stable/main/main.cpp#L2403-L2413. Nothing to configure for a first test build.

## 4. Windows export from a Linux runner

- **Architecture:** `binary_format/architecture` is `x86_64,x86_32,arm64`, default `x86_64`. — https://github.com/godotengine/godot/blob/4.7.2-stable/platform/windows/export/export_plugin.cpp#L462 and https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_windows.html
- **Embedded or separate PCK:** `binary_format/embed_pck` defaults to `false`. — https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform_pc.cpp#L65. Embedding works only for executables up to about 3.89 GB, including the PCK. — https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_windows.html. This game is far below that (`apps/game/assets` is 26 MB). **Recommendation: `embed_pck=true`.** Testers then get one `.exe`, and the debug console wrapper still finds it, because it launches the same-named `.exe` (https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform_pc.cpp#L177-L195).
- **No rcedit or Wine:** in 4.7.2, `application/modify_resources` (default `true`) runs Godot's own `TemplateModifier` (`platform/windows/export/template_modifier.cpp`), which writes the icon and version info into the PE file. — https://github.com/godotengine/godot/blob/4.7.2-stable/platform/windows/export/export_plugin.cpp#L195-L204, #L474, #L539 and https://github.com/godotengine/godot/tree/4.7.2-stable/platform/windows/export. Neither file mentions `rcedit` or `wine`. The icon comes from `application/icon`, then `application/config/windows_native_icon`, then `application/config/icon` (this project: `res://assets/logo-mark.svg`). SVG is accepted. — same file, #L475 and #L512-L520. The docs: Godot "will automatically use whatever image is set as your project's icon… and convert it to an ICO file". — https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_windows.html
- **Code signing off:** `codesign/enable` defaults to `false`. — export_plugin.cpp #L464. Leave it off. Signing from Linux would need osslsigncode and a certificate. — https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_windows.html
- **SmartScreen on Windows 11:** for a file with "No signature", the user sees "Windows protected your PC" and "User must choose 'Run anyway' before the app can run. Enterprise policy can prevent continuation entirely." Unsigned files start with no reputation in every new version. — https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/smartscreen-reputation. The usual path is to click **More info**, then **Run anyway**. — https://kb.wisc.edu/hd-cps/144696 (a third-party help page; Microsoft's page names only "Run anyway").
- **Smart App Control can block it outright:** "If the app is unsigned, or the signature is invalid, Smart App Control will consider it untrusted and block it… There is currently no way to bypass Smart App Control protection for individual apps." — https://support.microsoft.com/en-us/topic/what-is-smart-app-control-285ea03d-fa88-4d56-882e-6698afdb7003. "Smart App Control signature checks apply to all executable files, not just those downloaded from the Internet." — https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/smartscreen-reputation. A tester whose PC has Smart App Control on cannot run an unsigned test build. The Testing page must say so.
- **Optional unblock:** before extracting, right-click the downloaded zip → **Properties** → **Unblock**. This removes the `Zone.Identifier` download mark, the same thing PowerShell's `Unblock-File` does. — https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/unblock-file

## 5. Export filters (what goes in the pack)

- Filters are comma-separated globs, matched case-insensitively against both `res://path` and the path without `res://`. `*` crosses folders. — https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform.cpp#L691-L756. The docs: the include filter "allows non-resource files such as `.txt`, `.json` and `.csv` to be exported", and the exclude filter removes files of a type. — https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html
- `export_presets.cfg` keys per `[preset.N]`: `name`, `platform`, `dedicated_server`, `custom_features`, `export_filter` (`all_resources`…), `include_filter`, `exclude_filter`, `export_path`, `script_export_mode`, and others. Options go in `[preset.N.options]`. Unlisted options take the platform default, because the preset is created from `get_export_options()` before the file's values are applied. Secret options go to `.godot/export_credentials.cfg`. — https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export.cpp#L42-L114 and #L300-L425, plus https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform.cpp#L616-L628. Platform names are `macOS` and `Windows Desktop`. — https://github.com/godotengine/godot/blob/4.7.2-stable/platform/macos/export/export_plugin.h#L134-L136 and https://github.com/godotengine/godot/blob/4.7.2-stable/platform/windows/export/export.cpp#L55
- **This repo:**
  - `art-source/` already has a `.gdignore`, so Godot never imports or exports it.
  - `apps/game/AGENTS.md` and other `.md` files are not resources, so they are skipped unless an include filter adds them.
  - `tests/*.gd` **are** resources and would be packed under `all_resources`, so **exclude `tests/*`**.
  - Nothing else in the repo is a capture driver. The debug tools' bug capture lives in `scripts/debug/` and must stay, because it is part of the debug build. Capture and playtest scripts written in future should live under `tests/` or a `.gdignore`d folder so this filter keeps covering them.
  - **Must include `assets/changelog.txt`**, which `main.gd:9`/`:598` reads with `FileAccess`. The Testing page already says presets "must add `*.txt` to its include filter". `*.txt` also packs the two OFL files, which is harmless.
  - `assets/manifest.json` is not read at runtime. It is not a resource, so it stays out unless included.
- Suggested values: `include_filter="*.txt"` and `exclude_filter="tests/*, *.md"`. After the first export, list the PCK contents to check, for example with `godot --headless --path apps/game --script` and `ProjectSettings.load_resource_pack`, or by grepping the export log. This has not been tested here.

## 6. Licence notices a test build must carry

- **Godot (MIT):** "The license text must be made available to the user." Acceptable ways include a credits screen, a licences screen, the output log, "a file containing the license text… added to the software that is installed to the user PC", or a link to `godotengine.org/license` in the game's documentation or credits. — https://docs.godotengine.org/en/4.7/about/complying_with_licenses.html (source: https://github.com/godotengine/godot-docs/blob/4.7/about/complying_with_licenses.rst)
- **Godot's third-party components:** these are "compatible with, but not covered by Godot's MIT license". "A good option… is to include this [COPYRIGHT.txt] file in your project's distribution, which you can e.g. rename to `GODOT_COPYRIGHT.txt`". The page also points to `Engine.get_license_info()` and `Engine.get_copyright_info()`. — same page.
  - `Engine.get_license_text()` "Returns the full Godot license text".
  - `get_license_info()` returns a Dictionary of licence names to texts.
  - `get_copyright_info()` returns "an Array of dictionaries with copyright information for every component".
  - Source: https://docs.godotengine.org/en/4.7/classes/class_engine.html
  - The 4.7.2 files: https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/LICENSE.txt (1,149 B, SHA-256 `b0435e3b3e4e55238f05f4b306f30524a1b2e20147810d436eaa554fa6855c80`) and https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/COPYRIGHT.txt (100,108 B, SHA-256 `cb1980c88089573bcacd7221d777c689bb8bbd778799f24c27fca0fe5f774d6d`; 107 `Files:` stanzas, mostly Expat, BSD-3, Apache-2.0, Zlib and OFL).
- **Fonts (SIL OFL 1.1, condition 2):** "Original or Modified Versions of the Font Software may be bundled, redistributed and/or sold with any software, provided that each copy contains the above copyright notice and this license. These can be included either as stand-alone text files, human-readable headers or in the appropriate machine-readable metadata fields within text or binary files as long as those fields can be easily viewed by the user." — `apps/game/assets/fonts/Roboto-OFL.txt` lines 56-61 and https://openfontlicense.org/open-font-license-official-text/. Copies packed inside a PCK are not "easily viewed by the user", so ship the two OFL files as plain files.
- Godot's page also says to list notices for assets "such as textures, models, sounds, music and fonts". The CC0 recordings need no notice, and the in-game Credits already name them and the typefaces (`scenes/main.tscn:651`).
- **Simplest compliant approach for test builds:** after export, add a `licenses/` folder **beside** the game in each downloadable zip, containing:
  - `GODOT_LICENSE.txt` and `GODOT_COPYRIGHT.txt`
  - `Roboto-OFL.txt` and `Montserrat-OFL.txt` (copied from `apps/game/assets/fonts/`)
  - a short spoiler-free `README.txt` naming the build (commit, debug, unsigned) and pointing to `wolfoverride.mrdemonwolf.dev/docs/credits/`

  For the Godot files, either download them at the tag and check the SHA-256s above (two pinned constants), or generate them with the same Godot binary using a tiny headless script that writes `Engine.get_license_text()` and the formatted `get_copyright_info()`/`get_license_info()` (no network, always matches the engine). For macOS, append the folder to Godot's zip (Python `zipfile` in mode `"a"` leaves the existing entries and their permission bits alone), never inside the `.app`. Optional later: add "Godot Engine — godotengine.org/license" to the in-game Credits. This is an in-game text change, so it needs a changelog bullet.

## 7. GitHub artifacts

- **Retention:** "Artifacts are retained for 90 days by default." `retention-days` must be between 1 and 90. — https://github.com/actions/upload-artifact/blob/cf430e030ddbb5b0abf93d22962f4752f3646cd9/README.md#retention-period. A public repo's setting can be 1–90 days. — https://docs.github.com/en/organizations/managing-organization-settings/configuring-the-retention-period-for-github-actions-artifacts-and-logs-in-your-organization. **Use `retention-days: 14` per upload and do not change the repository setting.** From 2026-10-01 that setting also governs checks, workflow runs and commit statuses, not only artifacts and logs. — https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/enabling-features-for-your-repository/managing-github-actions-settings-for-a-repository and https://github.blog/changelog/2026-07-17-actions-retention-will-cover-checks-workflow-runs-and-statuses/
- **Pinned version:** the repo pins `actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9` with the comment `# v7`. That commit is tag **v7.0.2** (`git ls-remote`), which has `archive`.
- **Zip-in-zip:** by default an artifact is zipped on upload and downloads as a zip. Uploading Godot's macOS `.zip` that way gives a zip inside a zip. v7 adds `archive: false`: "If 'false', only a single file can be uploaded. The name of the file will be used as the artifact name (the 'name' parameter is ignored)". — README above (Inputs) and https://github.blog/changelog/2026-02-26-github-actions-now-supports-uploading-and-downloading-non-zipped-artifacts/. **Upload each platform's finished zip with `archive: false`**, so the tester downloads exactly one zip.
- **Permissions:** zipped uploads reset modes to 755/644. To keep modes, tar the files or upload one file with `archive: false`. — README "Permission Loss". Godot's own macOS zip keeps the executable bit inside it, so `archive: false` keeps the app runnable.
- **Limits:**
  - 500 artifacts per job.
  - Storage quota per plan (GitHub Free 500 MB): https://docs.github.com/en/actions/reference/limits. That quota applies to private repositories; "GitHub Actions usage is free for… public repositories that use standard GitHub-hosted runners" and "For private repositories, each GitHub account receives a quota of… artifact storage". — https://docs.github.com/en/billing/concepts/product-billing/github-actions
  - No per-artifact size limit is stated in the v7 README (only the 500-per-job and quota limits).
  - Expected size per run: Windows about 35–50 MB compressed (103 MB debug template plus the PCK); macOS over 60 MB (one universal debug binary plus the PCK). These are estimates, not measured.
- **Re-runs:** artifacts are immutable. With `overwrite: false` the action "will fail if an artifact for the given name already exists". — README (Inputs). Set `overwrite: true`, or put `run_attempt` in the file name.
- **Who can download:** "Read access to the repository is required". — https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts. The `artifact-url` output: "Users must be logged-in in order for this URL to work." — upload-artifact README (Outputs). For this **public** repo, that means **anyone signed in to GitHub**. Anonymous visitors cannot download, and only users with write access see the delete icon. The REST download needs a token ("OAuth tokens and personal access tokens (classic) need the repo scope"). — https://docs.github.com/en/rest/actions/artifacts#download-an-artifact. **Nothing secret or spoiler-heavy may go into these builds**, because any GitHub user can fetch them for 14 days.
- CLI: `gh run download RUN_ID -n <artifact name>`. — https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts

## 8. Concurrency, permissions, job summary

- **Concurrency:** a group admits one running and, by default, one pending run. "any existing `pending` job or workflow in the same concurrency group will be canceled". `cancel-in-progress` can be an expression. Group names must be unique across workflows, for example `${{ github.workflow }}-${{ github.ref }}`. `github.head_ref` exists only on `pull_request` events. — https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#concurrency
  - To keep **every `main` push's build** while cancelling superseded PR builds, use:
    ```yaml
    concurrency:
      group: ${{ github.workflow }}-${{ github.event_name == 'pull_request' && github.head_ref || github.sha }}
      cancel-in-progress: ${{ github.event_name == 'pull_request' }}
    ```
    A plain `${{ github.ref }}` group on `main` would cancel a pending `main` build whenever a third push arrives.
- **Permissions:** "If you specify the access for any of these permissions, all of those that are not specified are set to `none`." `contents: read` "permits an action to list the commits". — https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#permissions. `upload-artifact` and `actions/cache` do not need extra `GITHUB_TOKEN` scopes. This repo's `game.yml` already uploads its failure logs under `permissions: contents: read`. Keep `persist-credentials: false` on checkout, as `game.yml` does.
- **Job summary:** append GitHub-flavoured Markdown to `$GITHUB_STEP_SUMMARY`. Each step is capped at 1 MiB, and at most 20 step summaries show per job. — https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-commands#adding-a-job-summary. Use the upload steps' `artifact-url` outputs (README, Outputs) for direct links. Keep the text spoiler-free: name, commit, "debug, unsigned", the open steps and the 14-day expiry.
- **Rulesets:** a new job name is not a required check unless the ruleset lists it. The ruleset needs no change, and adding the build job to it is **not** recommended, so an export hiccup does not block merges.

## 9. Repository and docs follow-ups (not done here)

- `export_presets.cfg` does not exist yet, and nothing in `.gitignore` excludes it. Commit it. Ideally create it once in the editor so Godot writes its exact format, then edit the filters and options by hand.
- `apps/docs/content/docs/changelog.mdx` says "There is no public game package or automatic updater yet." Reword it to say that unsigned debug **test builds** for macOS and Windows are attached to CI runs for 14 days and are not releases. Then run `python3 scripts/export_changelog.py` and commit `apps/game/assets/changelog.txt`.
- The Testing page (`apps/docs/content/docs/development/testing.mdx`) should cover:
  - where builds are (Actions → run → Artifacts; you must be signed in)
  - the macOS steps (unzip, open `WOLF--OVERRIDE.app`, Done, System Settings → Privacy & Security → Open Anyway within about an hour, or the `xattr` command)
  - the Windows steps (Extract All, run the `.exe`, More info → Run anyway, or the `.console.exe` for logs; blocked outright if Smart App Control is on)
  - that debug tools are on in these builds
  - that these builds share the normal user data folder, so testers who want a clean save should know where `user://` is (https://docs.godotengine.org/en/4.7/tutorials/io/data_paths.html)
- Recommended outside this task (no action taken): none required. Signing (Apple Developer ID plus notarization, Microsoft Artifact Signing from $9.99/month per https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/smartscreen-reputation) would remove the warnings, but needs accounts and secrets, which are out of scope.

## 10. Recommended workflow outline

New file `.github/workflows/builds.yml` (separate from `game.yml`, so the required `godot` check is untouched):

```yaml
name: Test builds
on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:
permissions:
  contents: read
concurrency:
  group: ${{ github.workflow }}-${{ github.event_name == 'pull_request' && github.head_ref || github.sha }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
jobs:
  export:
    runs-on: ubuntu-24.04
    timeout-minutes: 25
    defaults: { run: { shell: bash } }
    env:
      GODOT_VERSION: 4.7.2
      TEMPLATES_SHA512: ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079
    steps:
      - checkout (pinned SHA, persist-credentials: false)
      - Get pinned Godot 4.7.2 editor (same curl + sha256 as game.yml)
      - Isolate Godot data: HOME=$RUNNER_TEMP/godot-home, XDG_DATA_HOME=…/.local/share, XDG_CONFIG_HOME=…/.config  (export to $GITHUB_ENV)
      - actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9 # v6.1.0
          path: ${{ runner.temp }}/godot-home/.local/share/godot/export_templates/4.7.2.stable
          key: godot-templates-4.7.2-ca4d71c4-macos-win64-debug-v1
      - if cache miss: curl the .tpz -> sha512sum --check against TEMPLATES_SHA512 ->
          unzip -j only macos.zip, windows_debug_x86_64.exe, windows_debug_x86_64_console.exe, version.txt -> delete the .tpz
      - Import twice (first may error on fonts, as in check-game.sh; second must be clean), each under `timeout`
      - mkdir -p $RUNNER_TEMP/out/{macos,windows}
      - timeout 600 godot --headless --path apps/game --export-debug "macOS" $RUNNER_TEMP/out/macos/WOLF-OVERRIDE-macos.zip  | tee log
      - timeout 600 godot --headless --path apps/game --export-debug "Windows Desktop" $RUNNER_TEMP/out/windows/WOLF-OVERRIDE.exe | tee log
      - Fail if either log has "completed with warnings", "ERROR:" or "SCRIPT ERROR"; check that zipinfo shows the
        Contents/MacOS binary as -rwx and Contents/_CodeSignature/CodeResources exists (ad-hoc signature written)
      - Notices: build licenses/ (Godot LICENSE + COPYRIGHT from the same Godot or pinned files, both OFL files, README.txt)
      - Package: append licenses/ beside the .app in the macOS zip (python3 -I zipfile mode "a");
        zip WOLF-OVERRIDE.exe + WOLF-OVERRIDE.console.exe + licenses/ into the Windows zip
        names: wolf-override-<macos|windows>-debug-<short sha>.zip
      - actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # v7.0.2  (x2)
          path: <one zip>, archive: false, retention-days: 14, if-no-files-found: error, overwrite: true
      - Job summary to $GITHUB_STEP_SUMMARY: commit, "debug build, debug tools on, unsigned", the two artifact-url links,
        "sign in to GitHub to download, expires in 14 days", short macOS and Windows open steps, link to the Testing page
      - On failure: upload the export logs (retention 7, like game.yml)
```

Preset sketch (`apps/game/export_presets.cfg`; let the editor fill in the rest):

```ini
[preset.0]
name="macOS"
platform="macOS"
export_filter="all_resources"
include_filter="*.txt"
exclude_filter="tests/*, *.md"
[preset.0.options]
binary_format/architecture="universal"
application/bundle_identifier="dev.mrdemonwolf.wolfoverride"
codesign/codesign=1
notarization/notarization=0

[preset.1]
name="Windows Desktop"
platform="Windows Desktop"
export_filter="all_resources"
include_filter="*.txt"
exclude_filter="tests/*, *.md"
[preset.1.options]
binary_format/architecture="x86_64"
binary_format/embed_pck=true
application/modify_resources=true
debug/export_console_wrapper=1
codesign/enable=false
```

Still to verify in the first real run: that the export succeeds headless on `ubuntu-24.04` with only those template files; the actual artifact sizes; the PCK contents (tests excluded, `changelog.txt` present); that `CodeResources` exists in the macOS zip; and the time taken with a cold versus a warm cache. Any hands-on opening on macOS 15+ or Windows 11 has to be done and reported by a person. It has not been done.
