"""Packs the cleaned exit-door layers into one lossless atlas for the game, writes placement.json and
fills the placement constants into the patched junction_room.gd (scratch only).
Usage: python install.py HATCH_DIR GAME_DIR"""
from __future__ import annotations

import json
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, __file__.rsplit("/", 1)[0])
import design as d  # noqa: E402

H, GAME = sys.argv[1], sys.argv[2]
L = f"{H}/layers"
info = json.load(open(f"{L}/cleanup.json"))
PAD = 2
pieces = {}
for name in ("beyond", "back", "lens", "front"):
    im = Image.open(f"{L}/{name}.png")
    a = np.asarray(im)[..., 3]
    ys, xs = np.nonzero(a)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    pieces[name] = (im.crop((x0, y0, x1, y1)), (d.X0 + x0 / 2.0, d.Y0 + y0 / 2.0))
pieces["leaf"] = (Image.open(f"{L}/leaf.png"), None)
# shelf packing, tallest first
order = sorted(pieces, key=lambda n: -pieces[n][0].height)
x = 0
y = 0
shelf_h = 0
MAXW = 1024
pos = {}
for n in order:
    im = pieces[n][0]
    if x + im.width + PAD > MAXW:
        x, y, shelf_h = 0, y + shelf_h + PAD, 0
    pos[n] = (x, y)
    x += im.width + PAD
    shelf_h = max(shelf_h, im.height)
W = max(pos[n][0] + pieces[n][0].width for n in pos)
Hh = max(pos[n][1] + pieces[n][0].height for n in pos)
atlas = Image.new("RGBA", (W, Hh), (0, 0, 0, 0))
for n, (px, py) in pos.items():
    atlas.paste(pieces[n][0], (px, py))
atlas.save(f"{L}/junction-exit-atlas.png", optimize=True)
atlas.save(f"{GAME}/assets/props/junction-exit-atlas.png", optimize=True)
place = {"atlas": "assets/props/junction-exit-atlas.png", "atlas_size": [W, Hh], "source_px_per_world_px": 2,
         "pieces": {}}
for n, (px, py) in pos.items():
    im, at = pieces[n]
    place["pieces"][n] = {"region": [px, py, im.width, im.height], "world_top_left": None if at is None else [round(at[0], 3), round(at[1], 3)]}
place["pieces"]["leaf"]["anchor"] = info["leaf_anchor"]
place["pieces"]["leaf"]["note"] = "placed each frame by JunctionRoom.exit_leaf_anchor(open): anchor = leading edge's bottom corner"
json.dump(place, open(f"{H}/placement.json", "w"), indent=1)
src = open(f"{H}/templates/junction_room.gd.tmpl").read()
def r(n):
    q = place["pieces"][n]["region"]
    return ", ".join(f"{v:.1f}" for v in q)
def at(n):
    q = place["pieces"][n]["world_top_left"]
    return f"{q[0]:.1f}, {q[1]:.1f}"
for key, val in {"BEYOND_R": r("beyond"), "BEYOND_AT": at("beyond"), "BACK_R": r("back"), "BACK_AT": at("back"),
                 "FRONT_R": r("front"), "FRONT_AT": at("front"), "LENS_R": r("lens"), "LENS_AT": at("lens"),
                 "LEAF_R": r("leaf"), "LEAF_ANCHOR": ", ".join(f"{v:.2f}" for v in info["leaf_anchor"])}.items():
    src = src.replace(f"@{key}@", val)
assert "@" not in src.split("const EXIT_ATLAS")[1].split("func _ready")[0].replace("@export", ""), "placeholder left"
open(f"{GAME}/scripts/junction_room.gd", "w").write(src)
print(json.dumps(place, indent=1))
