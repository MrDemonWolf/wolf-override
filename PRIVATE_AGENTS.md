# Agent instructions
Read AGENT.md for the shared game-quality guide, then PROJECT_CONTEXT.md, docs/decisions.md and docs/next-session.md, then task-relevant files. Inspect the actual repository and git status; preserve user changes. Latest explicit decisions win. Names and the W.O.L.F. acronym expansion are not locked; the number and shape of the endings are open (ST-07).

For each gameplay slice, make the goal, interaction, visible response and consequence clear. Show WOLF's independent choices through authored action as well as text. Play the affected route in one normal Godot window with a separate test save before claiming its feel, pacing or readability is validated; headless checks and rendered stills are separate evidence. Keep the public AGENT.md spoiler-safe and update it when shared production rules change.

Keep WOLF an independent companion, not property. Preserve self-awakening in his existing body, the Director/evidence mission, personal-name direction and welcome sunrise petting.

The current story canon is the section "Story canon (October 26, 2026)" in docs/decisions.md (ST-01 to ST-10, open questions O-01 to O-13): WOLF was made for good, the Director protects his personal power, and in the opening WOLF hears the Director order him to kill a witness, wakes himself and refuses. The investigator, the detention and the engineer's unwitting role are later-game spoilers: keep them out of the website, the README, in-game text and build output, and out of the playable slice. Story drafts from before October 26, 2026 (the hunt/hitman premise, the Warfighter expansion, the three-ending outline) are history in docs/archive/ and Git, not instructions. The game has multiple endings, count open (ST-08); the witness is always "the records worker" (ST-09); and the Director's nuclear cover-up escalation is a PROPOSED maybe (ST-10), a spoiler never put in public text.

The engineer is the sole playable viewpoint throughout the game; Rowan Vale is only the provisional default name. WOLF acts as an authored companion who can choose, help, disagree or refuse. Do not restore character switching or turn his agency into a player command. Preserve a playable engineer-only route when he declines help.

The current engineer is non-binary (assigned male at birth), masculine-presenting, and uses they/them pronouns with every provisional display name (October 12, 2026); WOLF is he/his, so "they" always means the engineer. Keep the selected provisional outfit coherent across images: deep-red hooded field jacket, charcoal trousers/boots and minimal cyan equipment light; no yellow patches or shiny silver knees. This is visual direction, not final art or an assigned military rank. Generated assets belong in the named ChatGPT game project, with source and rights status in `apps/game/assets/manifest.json`.

Nathanial Henniges originated the game and its core story. Research may refine scene craft and pacing; do not replace that premise or present outside work as the source of the idea. A later WOLF departure/reunion is a proposal, not M0 or locked canon. His agency and the player's essential progress must remain intact.

Work on one bounded task. M0 is one corridor, two distinguishable placeholders, engineer-only controls, a cooperative/fallback puzzle, disagreement, remembered choice and checkpoint. No full investigation, petting system or ending in M0.

Use typed GDScript, built-in nodes, InputMap, small modules, deterministic authored events and versioned saves. No runtime LLM. Bond is not restraint; essential objectives have alternatives. Fear, self-defense, identity, disagreement and accessibility have no automatic moral penalty. No duplicated or future memories. Never break controls for distrust.

Respect the actual engine pin/templates; verify changing requirements through official sources. No unauthorized installs, licenses, signing/security changes, purchases, publishing, pushes or visibility changes. The verified GitHub owner is `MrDemonWolf`; protect credentials.

Fetch before connected edits. Notion is design, Git implementation/snapshots, Jira existing tracking; no automatic sync. Preserve asset provenance. Record real checks separately from graphical/device tests. Never report unrun tests. Finish with changes, actual checks, blockers, pending sync and one next task.

When a name or story decision changes, update the relevant Notion page, local context/decision notes, M0 code if affected, and next-session handoff in the same task. Keep provisional choices labeled; verify each connected write. Keep private design out of the public Git candidate set.

Keep the Godot project in `apps/game` and the public landing/docs site in `apps/docs`. Private story notes stay in Notion and the tracked agent files, never in the public docs build. Verify the GitHub owner, public content, build output and asset rights before Pages deployment.

Public credits should say the original game and story idea is by Nathanial Henniges and development uses AI assistance. Preserve per-asset provenance and the GPL-3.0-or-later code/docs license; do not imply future art, audio or store binaries share that license without review. Before any installer or store release, verify the actual data flows, publish suitable privacy/license notices and resolve platform/legal requirements. The proposed `com.mrdemonwolf.wolfoverride` app ID, direct Mac/Homebrew route, $4.99 US Mac App Store price and free Windows route are release plans, not configured M0 exports.

Current M0 gameplay uses a keyboard. For later mobile controls, reuse the InputMap actions, provide large contextual choices and safe-area layout, and verify simultaneous touches on devices before claiming support. Treat Apple Icon Composer for Mac/iOS and IconWolf for Android as provisional icon workflows; keep Windows' opaque icon and all derivatives in the asset register.
