# WOLF//OVERRIDE
**M0 source prototype.** Working title; first Godot checks passed, full playtest pending.

A side-view sci-fi horror game about an engineer and an independent robotic wolf companion escaping a secret facility together.

Detailed story, ending and production drafts live in Notion. The copied local handoff files are working notes, not public repository material.

## M0 source prototype
[apps/game/project.godot](apps/game/project.godot) opens a branded title screen, then one 2D corridor with distinct human and WOLF placeholders, a marked switching zone, a breaker/relay door puzzle, WOLF's possible refusal and a human bypass. One `relay_disagreement` event records the actual reply; WOLF recalls it at the checkpoint. That checkpoint saves actor, positions, draft display name, puzzle and memory state. New Game resets in-memory state.

Target editor: **Godot 4.7.2 stable**, selected from the [official release archive](https://godotengine.org/download/archive/). The user installed 4.7.2 via Homebrew. Headless import, M0 state and scene checks, and a brief headless scene start passed after moving the project to `apps/game`. The scene check drives both puzzle routes and checkpoint save/load with a separate test save. The graphical title screen opened; Continue was disabled with no save, and Enter started New Game. Character switching was observed before the move; complete puzzle routes and save/load still need graphical play. No art/audio assets or exported binaries are included. Mac first; Windows, iPhone, iPad and Android remain unverified targets.

### Controls
- On the title screen, Enter starts New Game. Continue becomes available when a valid checkpoint save exists.
- `A`/`D` or arrow keys: move the active character.
- `E`: interact with a nearby marked station.
- `Tab`: switch characters while the active character is in the amber floor zone.
- `1`/`2`: answer the single breaker disagreement.
- `I`: cycle provisional human display names; stable actor IDs stay unchanged.
- `L` or `F9`: load the saved checkpoint. `N`: start a clean New Game.

The far-right checkpoint saves automatically on interaction. The save file lives under Godot's `user://` directory. The human bypass remains available even when WOLF refuses the relay.

### Run and verify
Homebrew links `godot` on PATH. Run from this repository root:

```sh
godot --headless --path apps/game --import
godot --headless --path apps/game --script res://tests/m0_state_test.gd
godot --headless --path apps/game --script res://tests/m0_scene_test.gd
godot --path apps/game
```

The three headless commands passed on Godot 4.7.2; the last launched the game. Graphical route play, exports and device checks remain separate.

## Public docs
The [docs app](apps/docs/content/docs/index.mdx) uses the same Next.js/Fumadocs structure as WolfWave's docs. It contains public setup information only. Its dependencies and build have not yet been verified.

## Repository boundary
This repository is public. Keep story routes, ending drafts, private handoffs and connected-service notes in Notion. No external art or audio assets were added; record rights before adding any future asset.

## Credits
WOLF//OVERRIDE was conceived by Nathanial Henniges. MrDemonWolf, Inc. is developing the game with help from AI tools.

## License
Copyright 2026 MrDemonWolf, Inc. Game source code and public documentation are licensed under [GPL-3.0-or-later](LICENSE). Future art, audio, and branding need their own recorded terms in [the asset register](apps/game/assets/manifest.json); this prototype contains no acquired art or audio.
