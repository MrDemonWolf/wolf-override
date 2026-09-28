# WOLF//OVERRIDE game quality guide

This is the public, spoiler-safe guide for people and coding agents working on the game. The local `AGENTS.md` and private Notion pages contain story decisions; do not copy those drafts into this public repository.

## Build a playable scene, not a longer status message

For each bounded gameplay change, identify the player's immediate goal, the action they can take, the response they can see or hear, and the resulting state. When WOLF helps, disagrees or refuses, show an authored action or reaction as well as dialogue. Keep him independent and keep an engineer-only path through essential objectives.

- Make each interactive station recognizable before the player presses a key. Pair color with a label, shape or motion; show idle, available and completed states where those distinctions matter.
- Tie feedback to real state changes. Use a small number of coherent reactions such as a contact light, seal motion, copy confirmation or room transition. Do not show fake loading, progress or consequences.
- Let players read consequential dialogue and choices at their own pace. Keep controls and text readable over the scene. Do not make trust, identity or refusal remove essential controls.
- Give a chapter beat a beginning, escalation and short aftermath. Preserve quiet moments that let the engineer and WOLF feel present together. Do not add a new system merely to dress up one scene.
- Use the existing Godot 4.7 project, typed GDScript, built-in nodes and InputMap. Add audio or art only with source and rights status in `apps/game/assets/manifest.json`; do not invent credits for people, music or tools that were not involved.

## Prove what the player experiences

Run the relevant headless checks after code changes. For a claim about movement, pacing, readability, controls or WOLF's behavior, also play the affected route in one normal game window with a separate test save. Record what was observed and which paths remain unplayed. A still render or headless test does not prove game feel. Exports and devices need their own checks.

Keep public copy accurate about what is playable today. Nathanial Henniges originated the game and core story; research informs craft and does not replace that credit. Detailed story drafts stay in Notion and ignored local files.

## Craft references

- [Game Accessibility Guidelines: identify interactive elements](https://gameaccessibilityguidelines.com/give-a-clear-indication-that-interactive-elements-are-interactive/) and [player-paced text](https://gameaccessibilityguidelines.com/allow-players-to-progress-through-text-prompts-at-their-own-pace/)
- [Fumito Ueda on companion storytelling in *The Last Guardian*](https://blog.playstation.com/2016/06/21/the-last-guardian-5-storytelling-secrets/)
- [Godot 4.7 animation tracks](https://docs.godotengine.org/en/4.7/tutorials/animation/animation_track_types.html)
- [IGDA game crediting guidelines](https://igda.org/resources-archive/igda-game-crediting-guidelines-10-1-march-2023-update/)
