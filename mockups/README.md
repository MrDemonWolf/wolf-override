# WOLF OVERRIDE UI mockups

**What this is for:** HTML mockups of the game's UI, built from the game's own files, so a design can be judged and tuned before it goes into Godot (design brief section 7).

## What is here

- `index.html` (M00) links every screen.
- `m01-foundations.html` (M01) shows type, colour, sizes, motion and glyphs.
- `shared/wo.css` is the one stylesheet. It holds no numbers or colours of its own.
- `shared/wo.js` is the one script. It reads every value from the game folder.
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
- Page extras: `speaker=portrait`, `touch=tapwalk`, `flashing=reduced`, `loading`, `load`, `tip`, `art`
- Android only: `cutout=` and `edge=` widths in canvas px (not measured yet)

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
- `--eval "WO.probe()"` writes font sizes and rects of `[data-wo-probe]` elements as JSON.
- `--chrome` keeps the strip. `--allow-not-loaded` captures the no-fallback notice.
- It fails on any console error, failed request or HTTP error.
- It needs `playwright-core` in the repo's `node_modules` and a headless Chromium (`--chromium` or `WO_CHROMIUM`). It never opens a window.

## Live reload

Each page re-reads the token and language files once a second. An applied tune shows on every open page, on every device, within two seconds.
