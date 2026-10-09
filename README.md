# WOLF//OVERRIDE - Wake up. Choose who to trust.

<img src="apps/docs/public/wolf-override-mark.svg" alt="WOLF//OVERRIDE robotic wolf mark" width="160">

WOLF//OVERRIDE is a side-view sci-fi game in development. WOLF, a robotic
wolf, wakes himself after overhearing the Program Director's plan to use him
as a deniable killer under the cover of protecting people. He and a human
engineer work together to protect people, preserve evidence, and find a way
out.

One choice can change what your companion remembers.

![Provisional title art: Rowan and WOLF at a locked research corridor](apps/game/assets/title-corridor-key-art-provisional.png)

**Current status:** The first playable chapter slice runs from source; there
is no download yet. It has a short, skippable opening escape scene, a staged
corridor, a records room and the Service Junction, a third room where the
building is the engineer's only tool. Provisional AI-assisted character,
title, layered room and station art and sound effects generated in code are
in place. Nothing has been played through by hand yet: the routes are checked
by headless tests and rendered stills only, so feel, timing and sound are
unvalidated. Character animation, music, the wider campaign, public export
packages and physical-device testing are still ahead.

The gameplay camera follows the engineer across each room with a close
(1.35x) view. Settings uses THE DEN's local-terminal styling; the title screen
keeps its game presentation.

**Quick play:** The opening shows only WOLF and the Director. Press **E** to
advance WOLF's escape, or **Esc** to pause and choose Skip Opening. You then control the engineer,
who uses they/them pronouns; Rowan Vale is their provisional default name.
The opening tutorial teaches movement and the first interaction as you play.
Open the corridor door, save at the safe point, then press **E** again to enter
Records Access. Copy the purge
trace, use WOLF's mirror readout or the engineer's manual port, and reach the
exit, then use it again to enter the Service Junction: overload the line, hold
**E** at the valve to crank it, blow the sealed door, drop a hanging tank on a
patrolling sentry and pop the exit bolt. [The step-by-step guide](https://wolfoverride.mrdemonwolf.dev/docs/)
shows each step.

## Features

- **One playable engineer** - Move through three side-view rooms while WOLF
  follows and takes an independent task.
- **Cooperation with a fallback** - Open a powered door together, or use
  the engineer's bypass if WOLF refuses.
- **A remembered choice** - One authored disagreement records the reply
  you select and recalls it at the checkpoint.
- **A story-led corridor** - WOLF and the engineer respond to the Director's
  purge order, weigh the coolant warning, and reach safety with their
  disagreement remembered.
- **A first records objective** - Preserve a purge-order trace and a mirror
  timestamp using WOLF's readout or the engineer's maintenance port.
- **The Service Junction** - No weapon, only the building: a held-USE valve,
  a door blast on a one-second fuse, a tank dropped on a patrolling sentry and
  an exit bolt. WOLF reads the room and decides for himself whether to draw
  the sentry onto the mark; the engineer can always time the drop alone.
- **Knockdown and retry** - The vent, the blast, the sentry and a coolant
  cloud can knock the engineer down; play resumes from the room's last
  automatic save with choices intact, losing at most the current step.
- **Impact and sound** - Big moments get generated sound, a short camera
  shake, sparks or dust, rumble and, for the biggest, a flash. A Reduced
  Motion setting turns off the shake and hit-stop.
- **Checkpoint save and load** - Restore both characters' positions,
  puzzle and chapter progress, provisional display name, and choice memory,
  with automatic saves in Records Access and the Service Junction.

This is one chapter slice, not the full investigation or campaign. Its wider
story and cinematic presentation remain in development.

## Getting Started

The [public game guide](https://wolfoverride.mrdemonwolf.dev/docs/) has
controls. The [developer setup guide](https://wolfoverride.mrdemonwolf.dev/docs/development/)
has the local tools and checks. There is no installer or store release yet; run the game from source.

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
checkpoint save exists. Credits and Changelog open in the game; the
changelog screen also has a button that opens the full changelog on the
website. Esc, controller B or Android Back return to the title.

| Key                | Action                                      |
| ------------------ | ------------------------------------------- |
| Enter              | Start New Game from the title screen        |
| A / D or arrow keys | Move the engineer                           |
| E                  | Read, use a station, or enter the next room; hold at the junction valve |
| 1 / 2              | Answer at the breaker, mirror port or rubble line |
| I                  | Cycle provisional engineer display names   |
| Esc                | Pause or resume; Pause offers Skip Opening during the opening |

A basic controller map is available: left stick or D-pad moves, A interacts,
X/Y selects choices 1/2, and Start pauses. On iOS and Android, on-screen
left/right, Use, choice, and Pause buttons appear during play; Use reads
CRANK or DROP where the junction needs it. There are no other buttons. Controller
hardware and physical touch devices have not been tested yet.

The pause menu has Resume, Settings and Return to Title. Settings save a 30 FPS, 60 FPS, or
uncapped limit; desktop builds also offer three window sizes and fullscreen.
Mobile window size is managed by the operating system.

At the relay, choice **1** lets WOLF help: press E and he walks to the
contact himself; the seal opens when he arrives. Press E again while he is
walking to take the engineer's bypass instead. With choice **2**, press E to hear his refusal, then E again
for the engineer's bypass. Press **E** at the far-right checkpoint to save,
then **E** again to enter Records Access. Copy the purge-order trace at the
first station. WOLF heads to the mirror himself; press **E** there, then **1**
after he arrives for his readout or **2** for the manual port. Press **E** at
the exit to secure the first copy, then **E** to continue after the closing beat
and **E** at the exit again to enter the Service Junction. Its four automatic
saves (entry, door blown, sentry down, exit) are what Continue and a knockdown
restore. Continue restores chapter progress. Godot
stores the save in its `user://` directory.

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
- Python 3 (standard library only) for the changelog export check in `bun run game:check`.
- Bun **1.4.2** for the public docs app only.

### Setup

From the repository root, run the game checks:

```bash
bun run game:check
```

This imports the project and runs every headless suite with a temporary user
data folder, so your own saves are untouched. It also regenerates the in-game
changelog text from `apps/docs/content/docs/changelog.mdx` with Python 3 and
fails if `apps/game/assets/changelog.txt` is out of date; after editing the
changelog, run `python3 scripts/export_changelog.py` and commit the result.

To work on the public docs site, install its declared dependencies and
start the local server:

```bash
bun install --frozen-lockfile
bun run docs:dev
```

The frozen dependency install, docs type check, and Pages static export
passed locally and in [GitHub Actions](https://github.com/MrDemonWolf/wolf-override/actions/runs/36396158278).
The [public site](https://wolfoverride.mrdemonwolf.dev/) is live.

### Development Scripts

The root `package.json` defines these docs commands:

- `bun run docs:dev` - Start the local docs site.
- `bun run docs:check` - Generate MDX and Next types, then check TypeScript.
- `bun run docs:build` - Build the static public site.

### Code Quality

The game uses typed GDScript and stable event IDs independent of editable
display names. On local Godot 4.7.2, headless import, state, M0 scene, and
chapter scene checks passed. The scene checks cover both door routes, both
mirror routes, the opening tutorial, the chapter close, and Continue restoring
progress with separate test saves. The purge interaction was checked in a
normal Godot window, and 960×540 tutorial and Records completion frames were
inspected. Full corridor-to-Records routes have not been played by hand.
The Service Junction, the 1.35x camera, the layered room and prop art and the
generated sounds are covered by headless suites and rendered stills only;
none of them has been played by hand.
The new input/settings check also passed. A local iOS simulator export built
and launched on iPhone 17e and iPhone 18 Pro Max simulators; the 17e title
screen was inspected. The full route, controller hardware, touch gestures,
public export packages, and physical devices remain untested.

## Project Structure

```text
wolf-override/
├── apps/
│   ├── game/       # Godot project, scenes, scripts, tests, asset register
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

The [game quality guide](AGENT.md) sets the shared bar for playable scenes,
companion behavior, accessibility and honest playtest claims.

## Credits

Original game and core story idea by Nathanial Henniges. Developed by
MrDemonWolf, Inc. with AI assistance. See the [full credits, research
references, tools, and asset provenance](https://wolfoverride.mrdemonwolf.dev/docs/credits/).

## License

![GitHub license](https://img.shields.io/github/license/mrdemonwolf/wolf-override.svg?style=for-the-badge&logo=github)

Copyright 2026 MrDemonWolf, Inc. Game source code and public docs use
[GPL-3.0-or-later](LICENSE). The provisional logo, character sprites, title
art, layered room plates, and station props are separate assets with AI-assisted provenance
recorded in [the asset register](apps/game/assets/manifest.json); they are not covered
by the code/docs GPL. The bundled Roboto and Montserrat fonts use the SIL
Open Font License 1.1, with the license text beside each copy. Final asset, audio, branding and store-package rights
and release review remain open.

## Contact

- [Open an issue](https://github.com/MrDemonWolf/wolf-override/issues)
- [MrDemonWolf, Inc.](https://www.mrdemonwolf.com)

Made with love by [MrDemonWolf, Inc.](https://www.mrdemonwolf.com)
