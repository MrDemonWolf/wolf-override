# WOLF//OVERRIDE - Wake up. Choose who to trust.

![WOLF//OVERRIDE robotic wolf mark](apps/docs/public/wolf-override-mark.svg)

WOLF//OVERRIDE is a side-view 2D sci-fi game in development. WOLF, a
robotic wolf, wakes himself after overhearing the Program Director's plan
to use him as a deniable killer under the cover of protecting people. You
play the engineer who meets him; together you preserve evidence, protect
people and look for a way out while WOLF keeps his own will.

One choice can change what your companion remembers.

![Provisional title art: the engineer and WOLF at a locked research corridor](apps/game/assets/title-corridor-key-art-provisional.png)

**Status:** the first chapter slice runs from source in Godot 4.7.2.
There is no download, installer or release date. Headless checks pass and
rendered stills have been inspected, but complete routes have not been
played by hand; controller hardware, touch devices and export packages
are untested.

## Features

- **One playable engineer** - Move through two side-view rooms while
  WOLF follows and takes his own tasks.
- **Cooperation with a fallback** - Open a powered door together, or use
  the engineer's bypass when WOLF refuses or you would rather not wait.
- **A remembered choice** - One authored disagreement records your reply
  and WOLF recalls it at the safe point.
- **A first records objective** - Copy a purge-order trace and a mirror
  timestamp through WOLF's readout or the engineer's maintenance port.
- **Checkpoints and automatic saves** - The safe point and every Records
  Access station save; Continue restores the room, positions, puzzle
  state, display name and choice memory.
- **Input and settings** - Keyboard, controller and touch mappings,
  six rebindable actions, FPS limit, V-sync, MSAA, window size and
  audio sliders.

This is one chapter slice with provisional art and no audio, not the
full investigation or campaign.

## Getting Started

The [public game guide](https://wolfoverride.mrdemonwolf.dev/docs/) has
the first-steps tutorial, controls and an optional walkthrough. There is
no packaged release; run the game from source.

1. Install [Godot 4.7.2 stable](https://godotengine.org/download/archive/).
2. Clone the repository:

   ```bash
   git clone https://github.com/MrDemonWolf/wolf-override.git
   cd wolf-override
   ```

3. Import and open the project, then press **F5** to run it:

   ```bash
   godot --path apps/game --editor
   ```

After the first import, `godot --path apps/game` launches the game
directly.

## Usage

The title screen offers New Game, Continue (when a valid checkpoint
exists), Credits, Settings and a link to the public changelog. The
opening is player-paced; Pause offers Skip Opening during it. Defaults:

| Action                     | Keyboard             | Controller          | Touch                        |
| -------------------------- | -------------------- | ------------------- | ---------------------------- |
| Move                       | A / D or arrow keys  | Left stick or D-pad | Hold the on-screen arrows    |
| Interact / continue a beat | E                    | A                   | USE (CONTINUE during a beat) |
| Answer 1 / Answer 2        | 1 / 2 or click       | X / Y               | Tap the response             |
| Pause or resume            | Esc                  | Start               | PAUSE; tap RESUME to return  |
| Back in menus              | Esc                  | B                   | Android Back                 |
| Cancel a rebind            | Esc or CANCEL REBIND | -                   | Android Back                 |
| Cycle the provisional name | I (not rebindable)   | -                   | -                            |

Move, Interact, both answers and Pause can be rebound in Settings. The
pause menu has Resume, Settings and Return to Title (Skip Opening during
the opening); Return to Title keeps the last checkpoint. On Android, Back
steps out of menus and pauses play; it only quits from the title screen.
Switching away from the game during play pauses it.

Saves live in Godot's user data folder (`m0-save.json` and
`settings.cfg` under `Godot/app_userdata/WOLF--OVERRIDE/`). The
[saving guide](https://wolfoverride.mrdemonwolf.dev/docs/controls/saves/)
lists the folder per platform; the
[walkthrough](https://wolfoverride.mrdemonwolf.dev/docs/walkthrough/)
has the puzzle solutions.

## Tech Stack

| Layer          | Technology                                                            |
| -------------- | --------------------------------------------------------------------- |
| Game           | Godot 4.7.2 stable, typed GDScript, 2D                                |
| Game state     | Authored events and versioned JSON saves                              |
| Public site    | Next.js 16.1.1, Fumadocs UI 16.4.6, Tailwind CSS 4.1, MDX, TypeScript |
| Docs workspace | Bun 1.4.2                                                             |

## Development

### Prerequisites

- Godot **4.7.2 stable** for the game (`GODOT_BIN` overrides the
  binary name).
- Bun **1.4.2** for the public docs app only.

### Setup

1. Run the game checks from the repository root. This imports the
   project and runs every headless suite in `apps/game/tests` with a
   temporary user data folder, so your own saves are untouched:

   ```bash
   bun run game:check
   ```

2. Install the pinned dependencies for the public site:

   ```bash
   bun install --frozen-lockfile
   ```

3. Start the local docs server:

   ```bash
   bun run docs:dev
   ```

### Development Scripts

The root `package.json` defines these commands:

- `bun run game:check` - Import the Godot project and run the headless
  state, scene, settings and UI suites.
- `bun run docs:dev` - Start the local docs site.
- `bun run docs:check` - Generate MDX and Next types, then check
  TypeScript.
- `bun run docs:test` - Run the docs unit tests.
- `bun run docs:build` - Build the static site, then check the export
  (no image optimiser, skip-link target, one robots meta, WOFF2-only
  fonts).
- `bun run docs:check-export` - Re-run that export check on the last
  build.

### Code Quality

The game uses typed GDScript, the built-in InputMap and stable event IDs
that do not depend on editable display names. CI runs a checksum-pinned
Godot 4.7.2 import plus the headless suites on every pull request, and
the docs type check, tests and Pages build before deployment. Headless
checks cover both door routes, both mirror routes, settings validation
and Continue; they do not establish how a route feels. Complete
corridor-to-Records routes have not been played by hand.

## Project Structure

```text
wolf-override/
├── apps/
│   ├── game/       # Godot project, scenes, scripts, tests, asset register
│   └── docs/       # Public landing page and game guide (Next.js)
├── scripts/        # check-game.sh and check-docs-export.sh
├── .github/        # Game checks and Pages workflows
├── AGENT.md        # Shared game quality guide
├── LICENSE         # GPLv3 license text
├── bun.lock        # Pinned docs dependencies
└── package.json    # Workspace commands
```

Record an asset's origin and rights in
[the asset register](apps/game/assets/manifest.json) before adding it to
the game. Detailed story drafts stay out of this public repository.

## Credits

Original concept, core story and creative vision: Nathanial Henniges.
Developed by MrDemonWolf, Inc. with AI-assisted development under his
direction and review. The
[credits page](https://wolfoverride.mrdemonwolf.dev/docs/credits/) lists
research references, tools and asset provenance.

## License

![GitHub license](https://img.shields.io/github/license/mrdemonwolf/wolf-override.svg?style=for-the-badge&logo=github)

Copyright 2026 MrDemonWolf, Inc. Game source code and public docs use
[GPL-3.0-or-later](LICENSE). The bundled Roboto and Montserrat fonts use
the SIL Open Font License 1.1, with the license text beside each copy.
The provisional logo, sprites, title art, room backgrounds and machine
props are separate assets with AI-assisted provenance recorded in
[the asset register](apps/game/assets/manifest.json); they are not
covered by the code/docs GPL and their final rights review is open.

## Contact

- [Open an issue](https://github.com/MrDemonWolf/wolf-override/issues)
- [Join my server](https://mrdwolf.net/discord)
- [MrDemonWolf, Inc.](https://www.mrdemonwolf.com)

Made with love by [MrDemonWolf, Inc.](https://www.mrdemonwolf.com)
