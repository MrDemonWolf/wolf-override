"""Builds the Codex edit targets and references from the design renders (flat value plans on flat
#FF00FF where the asset is transparent). Writes codex/<job>/refs/ and paint/inputs.json."""
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
GAME = os.path.join(R, "game-main", "apps", "game")
L2 = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", "look2-hq", "props"))  # the approved Look 2 props, in this repository
MAG = (255, 0, 255, 255)


def on_magenta(img: Image.Image) -> Image.Image:
    bg = Image.new("RGBA", img.size, MAG)
    bg.alpha_composite(img.convert("RGBA"))
    return bg.convert("RGB")


def main() -> None:
    info = {}
    # far patch
    j = os.path.join(R, "codex", "paint-far", "refs")
    os.makedirs(j, exist_ok=True)
    Image.open(os.path.join(D, "far-patch", "design.png")).convert("RGB").resize((1024, 1024), Image.Resampling.LANCZOS).save(os.path.join(j, "1-edit-target-far.png"))
    far = Image.open(os.path.join(GAME, "assets/rooms/corridor-far.png")).convert("RGB")
    far.crop((300, 0, 1108, 808)).resize((1024, 1024), Image.Resampling.LANCZOS).save(os.path.join(j, "2-corridor-wall-reference.png"))
    sheet = Image.new("RGB", (1024, 512), (52, 56, 62))
    for i, n in enumerate(("corridor-coolant-relay.png", "corridor-safe-point.png")):
        im = Image.open(os.path.join(L2, n)).convert("RGBA")
        im.thumbnail((480, 480))
        s = Image.new("RGBA", sheet.size, (0, 0, 0, 0))
        s.paste(im, (40 + i * 512, 16))
        sheet.paste(s, (0, 0), s)
    sheet.save(os.path.join(j, "3-look2-material-reference.png"))
    info["paint-far"] = {"target": "1-edit-target-far.png", "design": "design/far-patch/design.png", "design_size": [808, 808], "target_size": [1024, 1024]}
    # portal: closed and open composites (frame + curtain + front + wheel), on magenta
    j = os.path.join(R, "codex", "paint-portal", "refs")
    os.makedirs(j, exist_ok=True)
    P = os.path.join(D, "portal")
    wheel = Image.open(os.path.join(P, "design-wheel.png"))
    for state, layers in (("closed", ("frame", "curtain", "front")), ("open", ("frame", "front"))):
        c = Image.new("RGBA", (820, 1230), (0, 0, 0, 0))
        for name in layers:
            c.alpha_composite(Image.open(os.path.join(P, f"design-{name}.png")))
        c.alpha_composite(wheel, (int((690 - 646) * 4), int((388 - 140) * 4)))
        on_magenta(c).resize((1024, 1536), Image.Resampling.LANCZOS).save(os.path.join(j, f"{1 if state == 'closed' else 2}-edit-target-{state}.png"))
    sheet.save(os.path.join(j, "3-look2-material-reference.png"))
    info["paint-portal"] = {"targets": ["1-edit-target-closed.png", "2-edit-target-open.png"], "design_size": [820, 1230], "target_size": [1024, 1536]}
    # stations: the two grounded stations side by side on magenta (1024 x 1024)
    j = os.path.join(R, "codex", "paint-stations", "refs")
    os.makedirs(j, exist_ok=True)
    S = os.path.join(D, "stations")
    spec = json.load(open(os.path.join(S, "spec.json")))
    canvas = Image.new("RGBA", (720, 720), (0, 0, 0, 0))
    place = {}
    x = 8
    for name in ("relay", "safe-point"):
        im = Image.open(os.path.join(S, f"design-{name}.png"))
        y = 720 - 8 - im.height
        canvas.alpha_composite(im, (x, y))
        place[name] = [x, y, im.width, im.height]
        x += im.width + 8
    k = 1024 / 720
    on_magenta(canvas).resize((1024, 1024), Image.Resampling.LANCZOS).save(os.path.join(j, "1-edit-target-stations.png"))
    info["paint-stations"] = {"target": "1-edit-target-stations.png", "sheet_size": [720, 720], "target_size": [1024, 1024], "scale": k, "placement_in_sheet": place}
    json.dump(info, open(os.path.join(R, "paint", "inputs.json"), "w"), indent=1)
    print(json.dumps(info, indent=1))


if __name__ == "__main__":
    main()
