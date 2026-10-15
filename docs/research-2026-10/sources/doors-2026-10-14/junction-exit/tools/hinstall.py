"""Fix round 1: packs the cleaned exit-door layers into one lossless atlas and writes placement.json
(the round-1 install.py also rewrote junction_room.gd from a template; the game's EXIT_* constants are
now updated from placement.json by hand). Adds the DECK piece (review r1, M4): the junction's own deck
and its fascia carried on past x 960 to the view's edge, made from the mid plate by a translation along
the room (2.0 m) in the room's camera, so its seams keep running to the room's vanishing point (511, 162),
instead of the mid plate's mirrored bleed (whose seams leaned to a mirrored vanishing point).
Usage: python hinstall.py HATCH_DIR GAME_ASSETS_DIR"""
from __future__ import annotations

import json
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, __file__.rsplit("/", 1)[0])
import design as d  # noqa: E402
import geom as g  # noqa: E402

H, ASSETS = sys.argv[1], sys.argv[2]
L = f"{H}/layers"
info = json.load(open(f"{L}/cleanup.json"))
PAD = 2
DECK_X0, DECK_X1, DECK_Y0, DECK_Y1 = 956.0, 1032.0, 440.0, 584.0
SHIFT_M = 2.0
FEATHER = 8.0


def deck_piece():
    mid = np.asarray(Image.open(f"{ASSETS}/rooms/junction-mid.png").convert("RGB")).astype(np.float64)
    xs = DECK_X0 + (np.arange(int((DECK_X1 - DECK_X0) * 2)) + 0.5) / 2.0
    ys = DECK_Y0 + (np.arange(int((DECK_Y1 - DECK_Y0) * 2)) + 0.5) / 2.0
    X, Y = np.meshgrid(xs, ys)
    s_top = (Y - g.HOR) / (g.FLOOR - g.HOR)
    s_front = g.D0 / (g.D0 + g.DECK_FRONT_Z)
    y_edge = g.HOR + (g.FLOOR - g.HOR) * s_front
    s = np.where(Y < y_edge, s_top, s_front)
    Xs = X - g.PPM * SHIFT_M * s
    sx, sy = Xs * 2.0 - 0.5, (Y - 52.0) * 2.0 - 0.5
    rgb = np.stack([ndimage.map_coordinates(mid[..., c], [sy, sx], order=1, mode="nearest") for c in range(3)], -1)
    a = np.clip((X - DECK_X0) / FEATHER, 0, 1)
    return Image.fromarray(np.dstack([np.clip(rgb + 0.5, 0, 255), a * 255 + 0.5]).astype(np.uint8), "RGBA"), (DECK_X0, DECK_Y0)


pieces = {}
for name in ("beyond", "back", "lens", "front"):
    im = Image.open(f"{L}/{name}.png")
    a = np.asarray(im)[..., 3]
    ys, xs = np.nonzero(a)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    pieces[name] = (im.crop((x0, y0, x1, y1)), (d.X0 + x0 / 2.0, d.Y0 + y0 / 2.0))
pieces["leaf"] = (Image.open(f"{L}/leaf.png"), None)
pieces["deck"] = deck_piece()
order = sorted(pieces, key=lambda n: -pieces[n][0].height)
x = y = shelf_h = 0
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
place = {"atlas": "assets/props/junction-exit-atlas.png", "atlas_size": [W, Hh], "source_px_per_world_px": 2, "camera_vp": [g.VPX, g.HOR], "pieces": {}}
for n, (px, py) in pos.items():
    im, at = pieces[n]
    place["pieces"][n] = {"region": [px, py, im.width, im.height], "world_top_left": None if at is None else [round(at[0], 3), round(at[1], 3)]}
place["pieces"]["leaf"]["anchor"] = info["leaf_anchor"]
place["pieces"]["deck"]["note"] = f"the junction's deck and fascia from x {DECK_X0} to {DECK_X1}: the mid plate translated {SHIFT_M} m along the room in its camera, feathered over its first {FEATHER} px"
spec = json.load(open(f"{H}/design/v8/spec.json"))
place["screen"] = {k: spec["opening"][k] for k in ("near_jamb_floor", "far_jamb_floor", "near_jamb_head", "far_jamb_head")}
place["screen"]["column_end_x"] = [round(float(v), 2) for v in (g.project(g.W(g.A_END, 0.0, 1.0))[0], g.project(g.W(g.A_END, g.T, 1.0))[0])]
place["lamp_globe_centre"] = spec["lamp_globe_centre"]
json.dump(place, open(f"{H}/placement.json", "w"), indent=1)
print(json.dumps(place, indent=1))
