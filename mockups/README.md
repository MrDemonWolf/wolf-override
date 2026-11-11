# WOLF OVERRIDE UI mockups

**What this is for:** HTML mockups of the game's UI, built from the game's own files, so a design can be judged and tuned before it goes into Godot (design brief section 7).

## What is here

- `index.html` (M00) links every screen.
- `m01-foundations.html` (M01) shows type, colour, sizes, motion and glyphs.
- `shared/wo.css` is the one stylesheet. It holds no numbers or colours of its own.
- `shared/wo.js` is the one script. It reads every value from the game folder.
- `data/<room>.json` holds a room's art list, shared by every page that shows it (`corridor.json`, `records.json`).
- `tools/capture.mjs` is the one capture tool.

## Rules

- Pages hold markup and per-screen data only.
- No inline style values. No CSS or JS copied between pages.
- Every value comes from its one home:
  - `apps/game/ui/ui.tokens.json` (colours, type, sizes, motion, timing);
  - `apps/game/assets/fonts/game_theme.tres` (box metrics, gradients);
  - `apps/game/project.godot` (canvas size);
  - `apps/game/i18n/languages.json` (row length, reading speed);
  - the script or scene that owns a value today (read by `wo.js`, never copied).
- Real art only, by relative path: `../apps/game/assets/...`.
- Words: only lines already in the build. No new story text.

## Serve

Run this from the repo root:

```sh
python3 -m http.server 8000 --bind 127.0.0.1
```

Then open `http://localhost:8000/mockups/`.

- Always use `--bind 127.0.0.1`. Without it the server shares `.git/` and `.work/` with your whole network.
- Never open a page as a file. It shows "Tokens not loaded".
- `localhost` is a secure context, so Copy and a real Xbox pad work there.
- A LAN address has no clipboard and no Gamepad API. Copy then shows a text box and a download link.

## The control strip

The strip at the top sets the URL. A reload or a shared link keeps it.

- `device=desktop|ally|iphone|deck|ipad|android|uw21|uw32`
- `input=mouse|keyboard|pad|touch` (empty: each frame's profile default)
- `text=100..200` (TEXT SIZE; empty: the profile default)
- `motion=reduced`, `hits=1`, `tune=1`
- `clean=1` hides the strip and the Tune panel, for captures
- Page extras: `speaker=portrait`, `touch=tapwalk`, `flashing=reduced`, `loading`, `load`, `tip`, `art`, `scene`
- Android only: `cutout=` and `edge=` widths in canvas px (not measured yet). They widen that frame's safe edges.
- Still states for captures: `tab=<key>` (open a settings tab), `list=<name>` (open a list), `at=<moment>:<ms>` and `press=` (M04 clock), `t=`, `load=`, `skip=` (M02 boot clock), `reveal=<ms>` (part-typed line), `countdown=<ms>` (keep-or-revert), `bind=interact=RT` (a remap)

## Shared pieces a page can use

Write the markup; `wo.js` and `wo.css` do the rest. Never copy CSS or JS into a page.

Frames and templates:

- `data-wo-template="a b"` on any element appends each `<template>` in order. `page.html#id` takes another page's template.
- A `<script type="application/json" data-wo-include-set>` child changes the included copy only: `{"selector": {"attr": "value" | null}}`.
- `data-wo-input="pad"` on a `.mk-device` pins that frame's input.
- `data-wo-node="studio_logo.tscn:LoadBar"` places an element at a scene node's rect (inside `.wo-scene-base`).
- `data-wo-when="loading=|m04"` shows an element only for those URL values. Start it `hidden`.
- `.mk-device-row.is-one` lets one frame reach the device's width; `.is-two` puts two frames side by side.

Focus, overlays and input:

- `data-wo-current="<data-wo-id>"` on a `.wo-frame` names the item that holds focus. An `autofocus` in a template does the same.
- `data-wo-overlay` on a layer makes it a pause or dialog: B, Esc and Menu close it, the pause key and Menu open it.
- `data-wo-close` on an item closes its overlay; `data-wo-open-overlay` opens the frame's overlay.
- `data-wo-guard` on an overlay swallows taps for `timing.resume-card.guard` after it opens.
- `data-wo-open="screen"` plays the screen-open motion (`motion.screen.in`).
- `data-wo-only="desktop handheld"` and `data-wo-only-input="touch"` show an item on those profiles or inputs only.
- `data-wo-answer="1"` and `"2"` on answer cards: X and Y, the 1 and 2 keys, A and taps all pick them.
- Hover looks show only while the input is the mouse.

Settings (one shell for M08, M09, M10, M11):

- `.wo-settings` on `.wo-safe.wo-terminal-panel` (handheld, phone) or `.wo-settings-card.wo-terminal-panel` (desktop).
- Inside: `.wo-settings-head`, `.wo-tabs`, `.wo-settings-body` (scrolls), `.wo-footer`. Phones get a left tab rail.
- `.wo-tab[data-wo-tab="audio"]` shows `[data-wo-page="audio"]`. LB, RB, clicks and taps switch tabs.
- `.wo-row` is label | control. The whole row is the tap target.
- `.wo-slider` reads `aria-valuenow`, `aria-valuemin` and `aria-valuemax`.
- `data-wo-hold` fills while held (`timing.hold-confirm`); `data-wo-value="0.6"` draws a still.
- `.wo-popup` in a `.wo-row-control` opens under its `.wo-select` (or above it, `.is-above`). `data-wo-list="name"` names it.
- `data-wo-countdown` counts `timing.keep-revert`; put the seconds in `[data-wo-countdown-left]`.
- `data-wo-scroll="0.15"` opens a scroller part-way down. `data-wo-min-refresh="119"` hides a choice on slower screens.
- `data-wo-scheme="pad|tapwalk"` follows the Phone controls switch.
- `.wo-modal` (backdrop and a centred card) and `.wo-plate` (a full-frame cover picture) are shared layers.

Worlds:

- `data-wo-world="data/corridor.json"` draws a shared room. The page's JSON adds actors at a slot and changes pieces by `id`.
- Pieces may name a script constant: `"brightness": "door_kit.gd:WALL_LIFT"`.

Clocks:

- M02's boot (`data-wo-boot*`) and M04's screen changes (`data-wo-seq*`) run on one clock. Both take presses from one `wo:press` event.

## Tune

1. Press **Tune** (or add `tune=1`).
2. Move a proposal slider. Every open mockup tab updates at once.
3. Locked rows are sourced or today's values. Tick "unlock" only for an experiment.
4. Type sizes show their floors per device. Red means under a hard floor.
5. The URL keeps every tuned value as `t.<token>=` or `lang.<code>.<field>=`.

## Send a tune back into the game

1. Press **Copy JSON diff** and paste it into the chat.
2. The agent saves it as `.work/<job>/tune.json`.
3. The agent runs `python3 scripts/export_ui_tokens.py --apply .work/<job>/tune.json`.
4. The agent runs `scripts/check-game.sh` and renders stills.
5. The same pull request adds a changelog line.

The diff is an RFC 6902 patch: a `test` and a `replace` per value. If the file changed since you tuned, nothing is applied.

## Capture

Start the server first. Then:

```sh
WO_PORT=8000 node mockups/tools/capture.mjs m01-foundations.html desktop,ally,iphone .work/<job>/captures --full
```

- Devices and their sizes come from the token file.
- Output: `<page>__<device>[__<state>].png`.
- `--states "tuned:t.dialogue.backing=0.4;pad:input=pad"` adds one capture per state.
- In a state, `@` keys are actions: `@hover=`, `@click=`, `@key=`, `@tap=`, `@pad=A`, `@wait=`, `@tick=`, `@eval=`, `@freeze=`.
- `--hover <selector>`, `--press <keys>` and `--input "key:Space@300;tap@300;padA@300"` act in every state.
- `--eval "WO.probe()"` writes font sizes and rects of `[data-wo-probe]` elements as JSON.
- `--chrome` keeps the strip. `--allow-not-loaded` captures the no-fallback notice.
- It fails on any console error, failed request or HTTP error.
- It needs `playwright-core` in the repo's `node_modules` and a headless Chromium (`--chromium` or `WO_CHROMIUM`). It never opens a window.

## Live reload

Each page re-reads the token and language files once a second. An applied tune shows on every open page, on every device, within two seconds.
