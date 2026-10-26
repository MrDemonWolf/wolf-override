# Sources and verification — Revision 4
## Creative authority
Nathanial Henniges originated the game and core story. The current story canon is Nathanial's handoff of October 26, 2026 ([decisions](decisions.md), "Story canon (October 26, 2026)"); his earlier conversations are the source for the Director/evidence mission, natural-name direction, WOLF's companion/chosen-family identity and sunrise petting. Rowan Vale is the user's preferred provisional M0 engineer name. The acronym expansion is open. `wolfoverride://` is a proposed future URL scheme, with no M0 platform registration.

## Story craft research, not story ownership or new canon
- [Game Developer on history, mystery and story in opening cinematics](https://www.gamedeveloper.com/design/history-mystery-and-story-games-and-the-10-minute-rule): informed the opening's threat-list mystery (informed the superseded September 28 draft) and quick handoff to play. This is a craft reference, not a source for the game's plot.
- [Game Developer on what opening cutscenes accomplish](https://www.gamedeveloper.com/design/the-rules-of-the-game-cutting-cut-scenes): informed the choice to stage the escape in the same Godot corridor art used for gameplay, with visible action instead of a separate higher-fidelity movie.
- [Godot 4.7 Tween reference](https://docs.godotengine.org/en/4.7/classes/class_tween.html): confirms the lightweight camera, gate, character and fade sequencing used in the opening.
- [Fumito Ueda on The Last Guardian's companion relationship](https://blog.playstation.com/2016/06/21/the-last-guardian-5-storytelling-secrets/): quiet shared moments and a changing relationship informed the proposed idea of establishing a routine before WOLF's absence. This is an inference for our story, not a borrowed scene.
- [Bouquet et al. on nonplayer character companion design](https://www.medien.ifi.lmu.de/pubdb/publications/pub/bouquet2018mindtrek/bouquet2018mindtrek.pdf): companion individuality, autonomy and personal goals support giving WOLF a credible decision of his own. The specific Fracture incident remains ours to write.
- [A Fold Apart developer account](https://blog.playstation.com/2020/05/18/a-fold-apart-explores-the-emotions-of-a-long-distance-relationship-in-a-folding-paper-world-out-tomorrow-on-ps4/): separation can be felt in interaction and both perspectives can matter. Apply that craft principle without copying its romantic plot or folding mechanic.

The temporary departure/reunion in [story-map.md](https://github.com/MrDemonWolf/wolf-override/blob/1cf8d73c4703f8d8dfb693c41fc57c62c43118e3/docs/story-map.md) is a **proposal** for a later chapter. Exact crisis, tasks, duration, dialogue and route rules remain open; M0 does not include it.

## Cover-up research, not fictional fact or new canon
- [DOJ case involving an assault followed by false reports that the victim attacked first](https://www.justice.gov/archives/opa/pr/former-federal-prison-lieutenant-sentenced-using-excessive-force-and-obstructing): supports the plausibility of a sanitized threat narrative. The game incident is fictional and still undecided (informed the superseded September 28 draft).
- [NARA Universal Electronic Records Management Requirements](https://www.archives.gov/records-mgmt/policy/universalermrequirements): records have lifecycle and metadata requirements; the proposed investigation compares original authorization, altered summary and an independent source rather than one magic file (informed the superseded September 28 draft).
- [NIST AI Risk Management Framework Core](https://airc.nist.gov/airmf-resources/airmf/5-sec-core/): leadership responsibility for deployment risk informs the question of who authorized the target classification, even if the Director blames WOLF (informed the superseded September 28 draft).
- [GAO review of VA whistleblower protections](https://files.gao.gov/reports/GAO-25-106780/index.html): retaliation allegations and evidence gaps inform why a fictional records worker might fear coming forward. It does not establish the game's victim, witness or outcome (informed the superseded September 28 draft; still fits the witness of the October 26 canon).

## Live records read back during this update
- Hub: https://app.notion.com/p/3e6d61481c7b818b9a39d4641d781bdb
- Story walkthrough: https://app.notion.com/p/3e6d61481c7b81caa03dc2e3d0fd0ec2
- Build handoff: https://app.notion.com/p/3e6d61481c7b810d956eef52c00f76ec
- Copy-paste/Codex reference: https://app.notion.com/p/3e6d61481c7b81e2ba0df3d09131d479
- Existing Jira issue: https://mrdemonwolf.atlassian.net/browse/MDW-1584

The retrieved pages contain revision-4 direction. Jira description and comments reflect it; the task remains To Do with prototype acceptance unverified. The reference's revised story/Codex sections are present despite a later redundant replacement attempt returning a no-match error. Content readback, not an assumed clean API history, establishes the saved state.

In the local M0 source session, the hub, story, build handoff and reference pages were fetched and updated for the public repository/private-document boundary. The story page gained a provisional first-corridor encounter and current `relay_disagreement` ID. Rowan Vale and Godot status were then written to all four Notion pages and read back. ChatGPT Project instructions were separately updated and read back; these services do not sync automatically. Jira was not changed.

Existing separate macOS guide: https://app.notion.com/p/3e6d61481c7b81feae70f4ee53249ad2

## Technical verification boundary
The earlier story update did not establish an engine version. For M0, the [official release archive](https://godotengine.org/download/archive/) was checked and Godot 4.7.2 stable was chosen as a target. The user installed that version via Homebrew; import, state test and brief headless scene start passed after the project moved to `apps/game` and gained its title overlay. The older 4.7.2 reference was not a pre-existing project pin. The public `apps/docs` Fumadocs skeleton has not had dependencies installed or a build run. No SDK requirement, voice, offline behavior or export was verified. Use official matching-version sources for later platform work:
- https://godotengine.org/download/macos/
- https://docs.godotengine.org/
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html
- https://docs.godotengine.org/en/stable/tutorials/audio/text_to_speech.html
- https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html
- https://docs.godotengine.org/en/4.7/tutorials/io/saving_games.html
- https://docs.godotengine.org/en/4.7/classes/class_renderingserver.html

The 4.7 command-line and save references informed M0. A clean import and state test are recorded separately from incomplete graphical route play. Before the logo revision, the title was visible, Continue was disabled without a save, and New Game opened. The revised logo layout, full graphical routes and checkpoint restoration remain unverified. A later headless scene test drove movement and input through both door routes, including refusal, fallback, checkpoint and save/load. It also checked the logo resource and New Game/Continue button signals with an isolated test save; [Game checks for `049b550`](https://github.com/MrDemonWolf/wolf-override/actions/runs/36227626860) passed. This is automated evidence, not a graphical playtest. A later one-window graphical attempt ended when the Mac locked; the existing checkpoint save remained unchanged. Moving stable documentation is not a reason to upgrade a pinned project.

Godot 4.7's RenderingServer reference says `--headless` disables rendering and returns dummy values for most rendering calls. It can verify scene logic, but cannot supply a trustworthy rendered title screenshot to replace the locked-Mac graphical check.

[Bun's lockfile documentation](https://bun.sh/docs/pm/lockfile) recommends committing `bun.lock` for reproducibility. Its [install documentation](https://bun.sh/docs/pm/cli/install) says `--frozen-lockfile` can install from `package.json` when no lockfile exists, without creating one. Therefore the local Pages workflow's missing lockfile does not by itself prove that CI would fail. The project still has no dependency install, docs build or export to verify; publishing the workflow remains pending. A live GitHub API check found Pages configured for workflow builds but no deployment, while the direct site fetch was blocked by automatic approval review and cannot establish a current HTTP result.

## Historical and local material
Older MACHINE//ONLINE terminal mockups/downloads remain historical; they were not overwritten or adopted as current gameplay. Unrelated Library artwork was not used as game assets. These files began as a newly authored Markdown snapshot rather than a byte-for-byte Notion export. They were later copied into this local Git checkout; no older implementation was present here to merge against.

The September 25 package's own validation notes, its Codex handoff prompt and its ChatGPT project instructions were removed on October 11, 2026 as stale. Current local checks are recorded in [next-session.md](next-session.md). No complete graphical route play, export or device check was run.
