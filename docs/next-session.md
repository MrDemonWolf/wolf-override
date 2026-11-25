# WOLF OVERRIDE story reset

Start a conversation with Nathanial about the story he wants to tell. On November 25, 2026 he asked to retire the prototype, keep the main parts, and return to the story later with Claude or Codex. The next session starts here. The previous UI queue and Chapter 1 continuation are historical.

## First conversation

Ask one question and wait for Nathanial's answer: **What moment between the engineer and WOLF would make you want to keep playing?** Write down his words. Then establish which parts of the earlier premise he wants to carry forward. His original concept and story credit belong with him.

Use one scene to explore his answer. Give the engineer one thing to do, give WOLF a reason to act independently, and describe the change the player can see. Mark suggestions as drafts. Let Nathanial choose the premise before drafting dialogue, naming endings or building rooms.

## What survives the review

| Keep available | How to use it |
| --- | --- |
| WOLF OVERRIDE, Nathanial's authorship, license, credits and the asset register | Preserve attribution and rights records, including retired assets. The register has 122 entries at the baseline. |
| The engineer as sole playable viewpoint, WOLF as an independent companion, engineer-only progress | These were explicit creative decisions. Ask Nathanial which story beats still serve that relationship. |
| October 26 canon and October 30 refinements | Consult the [decision log](decisions.md) when Nathanial asks what he previously chose. The implemented dialogue and rooms belong to the previous prototype. |
| Play observations | Start with [B11 and B13](playtest-bugs-2026-11.md) and [Nathanial's play notebook](https://app.notion.com/p/410d61481c7b819b9ed4c3364ef3fc5b). An old status or a passing test needs checking against the relevant build. |

## Proposed cleanup for Nathanial to review

- Retire the opening dock, corridor, Records Access, Service Junction and maintenance annex from the active game. Include their dialogue, prompts, room art, scripted encounters and chapter-specific tests and captures.
- Decide whether the title, studio splash, menu art and settings screens deserve to come forward. Accessibility needs such as readable text, player-paced dialogue and usable controls apply to any replacement. Their current implementation can be evaluated separately.
- Keep the pinned Godot project and build tools. Inspect common input, settings, translation and save code individually. The studio splash loads the chapter scene, and the shared test helper preloads it too. Site press-kit code and tests depend on game art and credit text. Update these consumers, public walkthroughs, changelog and export checks alongside any actual removal.
- Keep existing saves intact. A replacement can use a separate save filename. Review retired material at the baseline commit instead of shipping an archive inside the game.

## Lessons for the next playable scene

1. Draw the room around the action. Nathanial’s November corridor review identified exposed pipe ends and floating station labels. In the archived bypass frame, the label and button prompt are clearer than the physical connection between the wheel and door. Sketch the wall, pipe run, hand-height control and light source together. Review one frame at player scale before commissioning more art.
2. Make the physical action carry the story. Try a greybox where the player can tell what WOLF chose from what he does. Record where Nathanial first hesitates and what he thinks happened before adding a tutorial or another station.
3. Keep proof specific. A scripted route can verify that the engineer gets through a door alone. A still can show whether a control is visible. Nathanial playing the scene on a separate save is how to learn whether the choice reads and feels worthwhile.

## Recovery and evidence

The review started on clean main at [b4d15656](https://github.com/MrDemonWolf/wolf-override/tree/b4d15656eb6313c81623cf7ecd04aed91dd658ba), the merge of PR #154. That tree contains the complete previous prototype and its [October handoff](https://github.com/MrDemonWolf/wolf-override/blob/b4d15656eb6313c81623cf7ecd04aed91dd658ba/docs/next-session.md). For a read-only look at an old file, use `git show b4d15656:path/to/file`.

Astra reviewed the runtime dependencies, repo records and connected Notion hierarchy. All 93 pages linked from the repo notes index were among the 384 retrieved. Close reading focused on the hub, canon, play notes and handoff. Attachments and discussions were outside this pass. The short canon page lags the AI reference on the engineer’s prior work, and the Build Plan still describes already-merged work as open. Use dated owner decisions for the former and Git history for the latter. Existing stills and November play reports informed the review. The review added no new hands-on, export or device evidence. The November 17 local receipts and previews are in `.work/handoff-2026-11-17/` on Nathanial's Mac.

Find the project log in [Notion](https://app.notion.com/p/3e6d61481c7b810d956eef52c00f76ec) and the original design sources in the [notes index](NOTES.md). Older briefs, alternate story outlines and UI implementation queues are reference material. The rewrite has no approved replacement plot yet.

Current cleanup state: handoff prepared on the review branch `docs/story-reset-handoff`. Runtime removals await Nathanial’s choice of what survives. Main still contains the playable prototype at the review baseline.
