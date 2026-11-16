# Render tool agent instructions (`tools/render`)

**What this file is for:** the rules for making rendered captures of the game. How the tool works is in [README.md](README.md); the repository rules are in the root [AGENTS.md](../../AGENTS.md).

- `render.sh` is the only way to get pixels. It runs Godot in a container, so no window opens on Nathanial's Mac.
- Give every run its own `--name`, so two jobs never share a cache folder.
- Write captures to a job folder under the git-ignored `.work/`, and delete the folder and the run's cache when the job ends.
- A still shows layout and readability. It does not show game feel; do not claim it does.
- After changing the tool, run `self_test.sh`.
