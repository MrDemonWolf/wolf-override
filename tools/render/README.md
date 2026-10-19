# Off-screen rendering

`render.sh` runs Godot 4.7.2 inside a Linux container with a virtual screen (Xvfb) and software
OpenGL (Mesa llvmpipe). Agents and scripts use it for rendered captures so that no Godot or game
window ever opens on the developer's Mac. Headless work (tests, imports, `--script` checks that
need no pixels) keeps using `godot --headless` directly.

## Requirements

Docker. On macOS this repository uses Colima (`colima start`). The first run builds the
`wolf-godot-render:4.7.2` image from the `Dockerfile` here, which downloads the official Linux
build of Godot 4.7.2 and checks it against its published SHA-512 sum.

## Usage

```sh
tools/render/render.sh [--screen WxH] [--name JOB] [--driver DIR] [--timeout SEC] \
  [--keyboard LAYOUT] PROJECT_DIR OUT_DIR -- GODOT_ARGS...
```

- `PROJECT_DIR` is copied (without its `.godot` folder) to
  `~/Library/Caches/wolf-override-render/JOB/project` and imported there; the real project is never
  touched. The cache keeps its own import between runs, so later runs are quick.
- `--driver DIR` copies capture scripts into the copy as `res://review_capture/`.
- Inside the container the project is `/work/project` and anything written to `/work/out` is
  copied back to `OUT_DIR`.
- `--screen` sets the virtual screen (default 2560x1440). The game picks its own window size at
  start-up, so a capture script that needs another size sets `get_window().size` after the first
  frames.
- `--keyboard LAYOUT` gives the virtual screen another keyboard layout, as an XKB layout name (`fr` is
  French AZERTY, `de` German QWERTZ). Key names then read as on that keyboard. Without it the layout is
  US QWERTY. It works by making LAYOUT the container's default before Xvfb starts, because `setxkbmap`
  does not change this Xvfb's keymap. `scripts/parity/run.sh` passes `PARITY_KEYBOARD` through.
- Every run stops after `--timeout` seconds (default 900, exit status 124). The run's log is kept at
  `~/Library/Caches/wolf-override-render/JOB/run.log`.
- The container has its own throwaway user data, so nothing reaches the host's Godot settings or
  saves.

Smoke test, which saves the title screen to `OUT/smoke.png`:

```sh
mkdir -p /tmp/smoke-driver && cp tools/render/smoke_capture.gd /tmp/smoke-driver/
tools/render/render.sh --driver /tmp/smoke-driver apps/game OUT -- \
  --resolution 1280x720 --script res://review_capture/smoke_capture.gd
```

## Limits

- Software rendering differs slightly from a Mac's GPU. Compare captures only with captures made
  by this tool, never with captures from a window on the Mac.
- Frame times here say nothing about real performance. Measure CPU-side costs with `--headless`,
  and measure frame times on real hardware.
- Mobile texture formats (ETC2) are converted to RGBA8 in the container, which is expected.
