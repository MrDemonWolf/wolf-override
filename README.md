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
replay in the earlier switching build. Engineer-only movement and WOLF's
follow behavior were observed in a partial graphical playtest; full route
playtesting, finished art and audio, exports, and device testing are still ahead.

**Quick play:** You control the engineer while WOLF follows. Go right to the
breaker (**E → 1 or 2 → E**), then the relay, then the safe point (**E** to
save). [The step-by-step guide](https://mrdemonwolf.github.io/wolf-override/docs/)
explains both door routes.

## Features

- **One playable engineer** - Move through the side-view corridor with WOLF
  as an independent companion.
- **Cooperation with a fallback** - Open a powered door together, or use
  the engineer's bypass if WOLF refuses.
- **A remembered choice** - One authored disagreement records the reply
  you select and recalls it at the checkpoint.
- **A story-led corridor** - WOLF and the engineer respond to the Director's
  purge order, weigh the coolant warning, and reach safety with their
  disagreement remembered.
- **Checkpoint save and load** - Restore both characters' positions,
  puzzle state, provisional display name, and choice memory.

These features describe the M0 prototype. The broader story and its
cinematic presentation remain in development.

## Getting Started

The [public game guide](https://mrdemonwolf.github.io/wolf-override/docs/) has
controls. The [developer setup guide](https://mrdemonwolf.github.io/wolf-override/docs/development/)
has the local tools and checks. There is no installer or store release yet; run M0 from source.

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
| A / D or arrow keys | Move the engineer                           |
| E                  | Read the purge display or use a station     |
| 1 / 2              | Answer the breaker disagreement            |
| I                  | Cycle provisional engineer display names   |
| L or F9            | Load the saved checkpoint                   |
| N                  | Start a clean current run                   |

At the relay, choice **1** lets WOLF help: stand toward the right side so
he can reach the contact, then press E. If he asks for room, step right and
press E again. With choice **2**, press E to hear his refusal, then E again
for the engineer's bypass. Interact at the far-right checkpoint to save.
Godot stores the file in its `user://` directory. **N** restarts the
current run without deleting that save.

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
bun install --frozen-lockfile
bun run docs:dev
```

The frozen dependency install, docs type check, and Pages static export
passed locally and in [GitHub Actions](https://github.com/MrDemonWolf/wolf-override/actions/runs/36396158278).
The [public site](https://mrdemonwolf.github.io/wolf-override/) is live.

### Development Scripts

The root `package.json` defines these docs commands:

- `bun run docs:dev` - Start the local docs site.
- `bun run docs:check` - Generate MDX and Next types, then check TypeScript.
- `bun run docs:build` - Build the static public site.

### Code Quality

The game uses typed GDScript and stable event IDs independent of editable
display names. On local Godot 4.7.2, import, state, and scene checks passed
for the engineer-only build. The scene check covers both door routes,
WOLF's follow behavior, stage objectives, title buttons, door retraction,
and checkpoint save/load with a separate test save. A rendered replay of
the earlier switching build was inspected at 960×540, and Continue restored
an existing checkpoint on screen. The engineer-only revision has had a
partial graphical playtest. Full hands-on route playtesting, exports, and
device checks remain open.
Corridor play currently requires a keyboard; touch controls and mobile
exports are not implemented.

## Project Structure

```text
wolf-override/
├── apps/
│   ├── game/       # Godot M0 project, scenes, scripts, tests, asset register
│   └── docs/       # Public landing page and game guide
├── .github/         # Game checks and Pages workflows
├── LICENSE          # GPLv3 license text
├── bun.lock         # Pinned docs dependencies
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
