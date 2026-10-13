"""The door end's flat-shaded design render, assembled from the construction layers (no paint):
far patch design + mid patch + bulkhead frame + curtain (closed) + front + wheel + typeset marks +
grounded stations, at the camera's right clamp, world x 540..960, y 140..470, 2 px per world px.
Also an open-state version. Writes design/door-end-design-closed.png and -open.png."""
from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
D = os.path.join(R, "design")
X0, Y0, X1, Y1 = 540, 140, 960, 470
PPW = 2


def main() -> None:
    far = Image.open(os.path.join(D, "far-patch", "far-plate-with-design.png")).convert("RGBA")
    # far plate at the clamp: world X = sx / 2 + 12.444, Y = sy / 2 + 78.5
    sx0 = int(round((X0 - 12.444) * 2))
    sy0 = int(round((Y0 - 78.5) * 2))
    for state in ("closed", "open"):
        out = far.crop((sx0, sy0, sx0 + (X1 - X0) * PPW, sy0 + (Y1 - Y0) * PPW))
        mid = Image.open(os.path.join(D, "mid-patch", "corridor-mid-patched.png")).convert("RGBA")
        my0 = int(round((Y0 - 51.5) * 2))
        out.alpha_composite(mid.crop((X0 * 2, my0, X1 * 2, my0 + (Y1 - Y0) * 2)))
        layers = ["frame"] + (["curtain"] if state == "closed" else []) + ["front"]
        canvas = Image.new("RGBA", (820, 1230), (0, 0, 0, 0))
        for name in layers:
            canvas.alpha_composite(Image.open(os.path.join(D, "portal", f"design-{name}.png")).convert("RGBA"))
        canvas.alpha_composite(Image.open(os.path.join(D, "portal", "design-wheel.png")).convert("RGBA"), ((690 - 646) * 4, (388 - 140) * 4))
        white = Image.new("RGBA", canvas.size, (225, 220, 222, 255))
        for t in ("frame", "front"):
            canvas.paste(white, (0, 0), Image.open(os.path.join(D, "text", f"text-{t}.png")))
        small = canvas.resize((410, 615), Image.Resampling.BOX)
        out.alpha_composite(small, ((646 - X0) * 2, (140 - Y0) * 2))
        spec = json.load(open(os.path.join(D, "stations", "spec.json")))
        for name, s in spec.items():
            im = Image.open(os.path.join(D, "stations", s["file"])).convert("RGBA")
            im = im.resize((im.width // 2, im.height // 2), Image.Resampling.BOX)
            left = s["centre_world_x"] - s["sprite_centre_px_x"] / 4.0
            top = 440 - s["floor_row"] / 4.0
            out.alpha_composite(im, (int(round((left - X0) * 2)), int(round((top - Y0) * 2))))
        out.convert("RGB").save(os.path.join(D, f"door-end-design-{state}.png"))
    print("written")


if __name__ == "__main__":
    main()
