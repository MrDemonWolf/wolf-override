"""Junction entry door: builds the game layers (doors-r1, fix round 1). Scratch only.
Outputs (jentry/out/):
  assets/props/junction-entry-atlas.png  one lossless atlas: the cross-wall (doorway alpha 0), the near
      column with its lamp socket, the stub, the leaf's junction-side face, its passage-side face, its
      latch edge, and the status lamp's glass (a neutral globe the game tints)
  assets/rooms/junction-far.png  main's plate with the service line passage painted in behind the doorway
      (at the camera's left clamp's parallax)
  assets/rooms/junction-mid.png  main's plate cleared left of the near column and the stub (the cutaway)
  placement.json"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import jedesign as JE  # noqa: E402  (installs jemodel as rmodel)
import jemodel as M  # noqa: E402
import install as RI  # noqa: E402  (records/tools/install.py: to_2ppw, crop_alpha, pack, lens)
from jeinputs import mid_erase  # noqa: E402

GAME = os.path.join(M.TRACK, "..", "main-junction", "apps", "game")
LAYERS = os.path.join(M.TRACK, "layers", "graded")
OUT = os.path.join(M.TRACK, "out")


def main():
    os.makedirs(os.path.join(OUT, "assets", "props"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "assets", "rooms"), exist_ok=True)
    door, lps = JE.lamps()
    spec = json.load(open(os.path.join(M.DESIGN, "entry", "spec.json")))
    cv = spec["canvas"]
    items, place = {}, {}
    wall = RI.to_2ppw(Image.open(os.path.join(LAYERS, "entry", "clean-wall.png")))
    img, tl = RI.crop_alpha(wall, cv["x0"], cv["y0"], 2.0)
    items["wall"], place["wall"] = img, {"world_top_left": [round(tl[0], 3), round(tl[1], 3)], "scale": 0.5}
    front = RI.to_2ppw(Image.open(os.path.join(LAYERS, "entry", "clean-front.png")))
    # the stub runs on to the deck's front edge far left of the room; the view never goes left of x 0
    img, tl = RI.crop_alpha(front, cv["x0"], cv["y0"], 2.0, (-2.0, cv["y0"], 200.0, cv["y0"] + cv["h"] / cv["ppw"]))
    items["front"], place["front"] = img, {"world_top_left": [round(tl[0], 3), round(tl[1], 3)], "scale": 0.5}
    for name in ("room", "out-exit", "edge"):
        items[f"leaf-{name}"] = Image.open(os.path.join(LAYERS, "leaf", f"clean-{name}.png")).convert("RGBA")
    items["lens"] = RI.lens()
    place["lens"] = {"scale": 0.25, "centre": spec["door"]["status_lamp_screen"]}
    atlas, regions = RI.pack(items)
    atlas.save(os.path.join(OUT, "assets", "props", "junction-entry-atlas.png"), optimize=True)
    for n, r in regions.items():
        place.setdefault(n, {})["region"] = list(r)
    # the far plate: the passage painted in at the left clamp's parallax
    far = Image.open(os.path.join(GAME, "assets", "rooms", "junction-far.png")).convert("RGBA")
    b = RI.to_2ppw(Image.open(os.path.join(LAYERS, "entry", "clean-beyond.png")))
    sx = int(round((cv["x0"] - JE.FAR_SHIFT_LEFT) * 2))
    sy = int(round((cv["y0"] - 79.0) * 2))
    layer = Image.new("RGBA", far.size, (0, 0, 0, 0))
    layer.paste(b, (sx, sy))
    Image.alpha_composite(far, layer).convert("RGB").save(os.path.join(OUT, "assets", "rooms", "junction-far.png"), optimize=True)
    # the mid plate: cleared where the passage shows in the cutaway
    mid = Image.open(os.path.join(GAME, "assets", "rooms", "junction-mid.png")).convert("RGBA")
    a = np.asarray(mid).copy()
    h, w = a.shape[:2]
    XX, YY = np.meshgrid((np.arange(w) + 0.5) / 2.0, (np.arange(h) + 0.5) / 2.0 + 52.0)
    er = mid_erase(XX, YY, door)
    a[..., 3] = np.where(er, 0, a[..., 3])
    a[..., :3] = np.where(er[..., None], 0, a[..., :3])
    Image.fromarray(a, "RGBA").save(os.path.join(OUT, "assets", "rooms", "junction-mid.png"), optimize=True)
    place["door"] = {"x_cross": door.xc, "hinge_foot_m": [round(float(v), 5) for v in door.hinge], "axis_u": [round(float(v), 6) for v in door.U], "axis_n": [round(float(v), 6) for v in door.N],
                     "near_jamb_foot": spec["door"]["near_jamb_foot"], "far_jamb_foot": spec["door"]["far_jamb_foot"], "column_end_face_at_1m": spec["door"]["column_end_face_at_1m"],
                     "leaf_lights": [{"name": l.name, "pos_m": [round(float(v), 4) for v in l.pos], "colour_x_intensity": [round(c * l.intensity, 4) for c in l.color], "reach_m": l.reach, "down": l.down}
                                     for l in lps if "passage" not in l.name]}
    place["mid_plate_cleared"] = "left of the near column's back edge above the floor, and left of the stub's lane face below it"
    M.write_json(os.path.join(OUT, "placement.json"), {"atlas": "res://assets/props/junction-entry-atlas.png", "atlas_size": list(atlas.size), "pieces": place})
    print(json.dumps({"atlas": atlas.size, "regions": regions, "front": place["front"], "wall": place["wall"], "lens": place["lens"], "door": place["door"]}, indent=1))


if __name__ == "__main__":
    main()
