# Godot project

Read the [current handoff](../../docs/next-session.md) before story or gameplay work. The entry scene is `scenes/main.tscn`. It contains a single empty node while Nathanial decides the next story direction.

- Keep the [asset register](assets/manifest.json) and licence texts for the retired prototype. Historical paths resolve at commit `b4d15656`.
- Keep the existing player save files intact. The empty scene has no save or settings code.
- Use the pinned Godot version. Run `scripts/check-game.sh` from the repository root to check startup headlessly. Nathanial handles hands-on play and device checks.
