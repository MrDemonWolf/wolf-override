# WOLF//OVERRIDE - Wake up. Choose who to trust.

<img src="apps/docs/public/wolf-override-mark.svg" alt="WOLF//OVERRIDE robotic wolf mark" width="160">

WOLF//OVERRIDE is a side-view sci-fi game in development. WOLF, a robotic
wolf, wakes himself after overhearing plans to misuse him. He and a human
engineer must work together to protect people and preserve evidence while
finding a way out.

One choice can change what your companion remembers.

**Current status:** M0 is a source prototype, not a downloadable game.
It has one staged corridor, code-drawn prototype characters, an opening
exchange, and one complete puzzle. Both routes passed a rendered scripted
replay; a full hands-on playthrough, finished art and audio, exports, and
device testing are still ahead.

## Features

- **Two playable characters** - Move the engineer and WOLF through one
  side-view corridor, switching in a marked area.
- **Cooperation with a fallback** - Open a powered door together, or use
  the engineer's bypass if WOLF refuses.
- **A remembered choice** - One authored disagreement records the reply
  you select and recalls it at the checkpoint.
- **A story-led corridor** - WOLF and the engineer respond to the Director's
  purge order, weigh the coolant warning, and reach safety with their
  disagreement remembered.
- **Checkpoint save and load** - Restore the active character, positions,
  puzzle state, provisional display name, and choice memory.

These features describe the M0 prototype. The broader story and its
cinematic presentation remain in development.

## Getting Started

The [public game guide](apps/docs/content/docs/index.mdx) has setup and
controls. There is no installer or store release yet; run M0 from source.

1. Get [Godot 4.7.2 stable](https://godotengine.org/download/archive/).
2. Clone the repository:

   ```bash
   git clone https://github.com/MrDemonWolf/wolf-override.git
   cd wolf-override
   ```

3. Open the project in Godot, then press **F5**:

   ```bash
   godot --path apps/game --editor
   ```

To launch the game directly, run `godot --path apps/game`.

## Usage

The title screen offers New Game. Continue is available when a valid
checkpoint save exists.

| Key                | Action                                      |
| ------------------ | ------------------------------------------- |
| Enter              | Start New Game from the title screen        |
| A / D or arrow keys | Move the active character                   |
| E                  | Read the purge display or use a station     |
| Tab                | Switch characters in the amber floor zone  |
| 1 / 2              | Answer the breaker disagreement            |
| I                  | Cycle provisional engineer display names   |
| L or F9            | Load the saved checkpoint                   |
| N                  | Start a clean current run                   |

Interact at the far-right checkpoint to save. Godot stores the file in
its `user://` directory.

## Tech Stack

| Layer          | Technology                                  |
| -------------- | ------------------------------------------- |
| Game           | Godot 4.7.2 stable, typed GDScript, 2D      |
| Game state     | Authored events and versioned local saves   |
| Public site    | Next.js 16.1.1, Fumadocs, MDX, TypeScript   |
| Docs workspace | Bun 1.4.2                                   |

## Development

### Prerequisites

- Godot **4.7.2 stable** for the game.
- Bun **1.4.2** for the public docs app only.

### Setup

From the repository root, run the game checks:

```bash
godot --headless --path apps/game --import
godot --headless --path apps/game --script res://tests/m0_state_test.gd
godot --headless --path apps/game --script res://tests/m0_scene_test.gd
```

To work on the public docs site, install its declared dependencies and
start the local server:

```bash
bun install
bun run docs:dev
```

The docs dependency install, type check, and build have not yet been
verified in this repository.

### Development Scripts

The root `package.json` defines these docs commands:

- `bun run docs:dev` - Start the local docs site.
- `bun run docs:check` - Generate MDX and Next types, then check TypeScript.
- `bun run docs:build` - Build the static public site.

### Code Quality

The game uses typed GDScript and stable event IDs independent of editable
display names. On local Godot 4.7.2, import, state, and scene checks passed.
The scene check covers both door routes, stage objectives, title buttons,
door retraction, and checkpoint save/load with a separate test save. A
renderer-backed replay of that scripted check was inspected at 960×540;
the normal Continue button also restored an existing checkpoint on screen.
Full hands-on route playtesting, exports, and device checks remain open.
Corridor play currently requires a keyboard; touch controls and mobile
exports are not implemented.

## Project Structure

```text
wolf-override/
├── apps/
│   ├── game/       # Godot M0 project, scenes, scripts, tests, asset register
│   └── docs/       # Public landing page and game guide
├── .github/         # Game checks workflow
├── LICENSE          # GPLv3 license text
└── package.json     # Docs workspace commands
```

This public repository contains source and public docs. Detailed story
drafts and production notes live in Notion. Record an asset's origin and
rights in [the asset register](apps/game/assets/manifest.json) before
adding it to the game.

## License

![GitHub license](https://img.shields.io/github/license/mrdemonwolf/wolf-override.svg?style=for-the-badge&logo=github)

Copyright 2026 MrDemonWolf, Inc. Game source code and public docs use
[GPL-3.0-or-later](LICENSE). The provisional logo is separate branding;
its AI-assisted concept and SVG redraw are recorded in
[the asset register](apps/game/assets/manifest.json). Future art, audio,
branding, and store packages need their own rights and release review.

## Contact

- [Open an issue](https://github.com/MrDemonWolf/wolf-override/issues)
- [MrDemonWolf, Inc.](https://www.mrdemonwolf.com)

Original game and story idea by Nathanial Henniges. Developed by MrDemonWolf, Inc. with
AI assistance.

Made with love by [MrDemonWolf, Inc.](https://www.mrdemonwolf.com)
