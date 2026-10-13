"""Fix round 1: builds the Codex edit targets for the v2 design on a flat NEUTRAL background
(#24262A, close to the plates' dark values) instead of #FF00FF, so no key colour can spill into the
paint (review item 2). Writes codex/paint-portal2/refs, codex/paint-far2/refs, paint/inputs2.json."""
from __future__ import annotations

import json
import os
import shutil

from PIL import Image

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
D = os.path.join(R, "design")
BG = (36, 38, 42)


def main() -> None:
    info = {"background": "#%02X%02X%02X" % BG}
    P = os.path.join(D, "portal2")
    j = os.path.join(R, "codex", "paint-portal2", "refs")
    os.makedirs(j, exist_ok=True)
    for i, (state, names) in enumerate((("closed", ("wall", "curtain", "frame", "wheel-on-canvas", "front")), ("open", ("wall", "frame", "wheel-on-canvas", "front"))), 1):
        c = Image.new("RGBA", (660, 1320), BG + (255,))
        for n in names:
            c.alpha_composite(Image.open(os.path.join(P, f"design-{n}.png")))
        c = c.convert("RGB").resize((768, 1536), Image.Resampling.LANCZOS)
        t = Image.new("RGB", (1024, 1536), BG)
        t.paste(c, (128, 0))
        t.save(os.path.join(j, f"{i}-edit-target-{state}.png"))
    shutil.copy(os.path.join(R, "codex", "paint-portal", "refs", "3-look2-material-reference.png"), os.path.join(j, "3-look2-material-reference.png"))
    info["paint-portal2"] = {"targets": ["1-edit-target-closed.png", "2-edit-target-open.png"], "design_size": [660, 1320], "placed_at": [128, 0, 768, 1536], "target_size": [1024, 1536]}
    j = os.path.join(R, "codex", "paint-far2", "refs")
    os.makedirs(j, exist_ok=True)
    Image.open(os.path.join(D, "far-patch2", "design.png")).convert("RGB").resize((1024, 1024), Image.Resampling.LANCZOS).save(os.path.join(j, "1-edit-target-far.png"))
    shutil.copy(os.path.join(R, "codex", "paint-far", "refs", "2-corridor-wall-reference.png"), os.path.join(j, "2-corridor-wall-reference.png"))
    shutil.copy(os.path.join(R, "codex", "paint-far", "out", "far-painted.png"), os.path.join(j, "3-previous-paint-reference.png"))
    info["paint-far2"] = {"target": "1-edit-target-far.png", "design_size": [808, 808], "target_size": [1024, 1024]}
    json.dump(info, open(os.path.join(R, "paint", "inputs2.json"), "w"), indent=1)
    print(json.dumps(info, indent=1))


if __name__ == "__main__":
    main()
