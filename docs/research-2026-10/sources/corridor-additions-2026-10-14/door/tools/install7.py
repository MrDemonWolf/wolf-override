"""Round 7 (add7, track DOOR): builds the game-ready atlas from add7/door/layers exactly as
layers/tools/install4.py builds round 6's (same pieces, same shelf packing, so every existing region
and world position is unchanged), plus two new regions for the inner blast leaf in free space below
the tucked bar. It writes ONLY to add7/door/game/ (install4 also copied into game-slice; this does
not touch any game copy). corridor-far.png and corridor-mid.png are round 6's, unchanged.
"""
from __future__ import annotations

import json
import os
import shutil
import sys

sys.dont_write_bytecode = True
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
LT = "scratchpad/real-slice/layers/tools"
sys.path.insert(0, LT)
import install4 as i4  # noqa: E402  (read-only: only its helpers and constants are used)
from install2 import load, over, down2, trim, save  # noqa: E402
import portal7 as d7  # noqa: E402

ROOT = os.path.abspath(os.path.join(HERE, ".."))
L = os.path.join(ROOT, "layers")
OUT = os.path.join(ROOT, "game")
LEAF_U_PPM = 40.0   # texels per metre along the leaf (the face is foreshortened to ~19 world px per m)
LEAF_H_PPM = 80.0   # texels per metre of height (2 per world px)
GUTTER = 2


def extrude(atlas, x, y, w, h, g=GUTTER):
    """Repeats a region's edge pixels into its gutter so mipmaps and filtering never pull in a
    neighbour."""
    atlas[y:y + h, max(x - g, 0):x] = atlas[y:y + h, x:x + 1]
    atlas[y:y + h, x + w:x + w + g] = atlas[y:y + h, x + w - 1:x + w]
    atlas[max(y - g, 0):y, max(x - g, 0):x + w + g] = atlas[y:y + 1, max(x - g, 0):x + w + g]
    atlas[y + h:y + h + g, max(x - g, 0):x + w + g] = atlas[y + h - 1:y + h, max(x - g, 0):x + w + g]


def main():
    os.makedirs(OUT, exist_ok=True)
    mid0 = load(os.path.join(i4.GM, "rooms", "corridor-mid.png"))
    # the wall sprite: as install4 (main's erased mid plate baked over it where main's plate is in front)
    wall = down2(load(os.path.join(L, "portal-wall.png")))
    fx, fy = int(i4.CVD_X0 * 2), int(round((i4.CVD_Y0 - i4.MID_TOP) * 2))
    main_on_wall = i4.place_on(wall.shape, mid0.copy(), -fx, -fy)
    yy = np.arange(wall.shape[0])[:, None] + fy
    xx = np.arange(wall.shape[1])[None, :] + fx
    erased = (yy >= 200) & (xx >= 1400)
    main_on_wall[..., 3] = np.where(erased, 0.0, main_on_wall[..., 3]) * (wall[..., 3] > 0)
    over(wall, main_on_wall, 0, 0)
    wall_t, (wx0, wy0, _, _) = trim(wall)
    front = load(os.path.join(L, "portal-front.png"))
    frame2 = load(os.path.join(L, "portal-frame.png"))
    frame_on_cvd = np.zeros_like(front)
    frame_on_cvd[:frame2.shape[0], 16:16 + frame2.shape[1]] = frame2
    front[..., 3] *= 1.0 - np.clip(frame_on_cvd[..., 3] * 1.5, 0, 1)
    fs = down2(front)
    pieces = {"curtain": (load(os.path.join(L, "portal-curtain.png")), 4.0, (i4.CV2_X0, i4.CV2_Y0)),
              "open": (load(os.path.join(L, "portal-curtain-open.png")), 4.0, (i4.CV2_X0, i4.CV2_Y0)),
              "frame": (frame2, 4.0, (i4.CV2_X0, i4.CV2_Y0))}
    trimmed = {}
    for key, (img, ppw, (cx, cy)) in pieces.items():
        t, (x0, y0, _, _) = trim(img)
        trimmed[key] = (t, ppw, [cx + x0 / ppw, cy + y0 / ppw])
    trimmed["wall"] = (wall_t, 2.0, [i4.CVD_X0 + wx0 / 2.0, i4.CVD_Y0 + wy0 / 2.0])
    for key, rect in i4.PIECES.items():
        pc = i4.cut(fs, (i4.CVD_X0, i4.CVD_Y0), rect)
        t, (x0, y0, _, _) = trim(pc)
        trimmed[key] = (t, 2.0, [i4.CVD_X0 + x0 / 2.0, i4.CVD_Y0 + y0 / 2.0])
    trimmed["lens"] = (load(os.path.join(L, "lens.png")), 4.0, None)
    trimmed["wheel"] = (load(os.path.join(L, "bypass-wheel.png")), 4.0, None)
    layout = {}
    x = 2
    for key in ("frame", "curtain", "wall", "column"):
        layout[key] = (x, 2)
        x += trimmed[key][0].shape[1] + 2
    row2 = 2 + max(trimmed[k][0].shape[0] for k in ("frame", "curtain", "wall", "column")) + 4
    x = 2
    for key in ("stub", "open", "wheel", "lens", "camera"):
        layout[key] = (x, row2)
        x += trimmed[key][0].shape[1] + 4
    # the leaf's two elevations, resampled to the atlas's texel density, below the tucked bar
    lf = Image.open(os.path.join(L, "leaf-front.png")).convert("RGBA")
    le = Image.open(os.path.join(L, "leaf-edge.png")).convert("RGBA")
    fw, fh = int(round(d7.LEAF_L * LEAF_U_PPM)), int(round(d7.LEAF_H * LEAF_H_PPM))
    ew = int(round((d7.T_LB - d7.T_LF) * LEAF_H_PPM))
    lf = np.asarray(lf.resize((fw, fh), Image.Resampling.LANCZOS)).astype(float) / 255.0
    le = np.asarray(le.resize((ew, fh), Image.Resampling.LANCZOS)).astype(float) / 255.0
    ox, oy = layout["open"]
    leaf_y = oy + trimmed["open"][0].shape[0] + 4
    layout["leaf_front"] = (ox, leaf_y)
    layout["leaf_edge"] = (ox + fw + 2 * GUTTER + 2, leaf_y)
    trimmed["leaf_front"] = (lf, None, None)
    trimmed["leaf_edge"] = (le, None, None)
    atlas = np.zeros((i4.ATLAS[1], i4.ATLAS[0], 4))
    regions = {}
    for key, (img, ppw, tl) in trimmed.items():
        ax, ay = layout[key]
        h, w = img.shape[:2]
        assert ax + w <= i4.ATLAS[0] and ay + h <= i4.ATLAS[1], (key, ax, ay, w, h)
        atlas[ay:ay + h, ax:ax + w] = img
        regions[key] = {"region": [ax, ay, w, h]}
        if ppw is not None:
            regions[key]["scale"] = 1.0 / ppw
        if tl is not None:
            regions[key]["world_top_left"] = [round(tl[0], 4), round(tl[1], 4)]
    for key in ("leaf_front", "leaf_edge"):
        extrude(atlas, *regions[key]["region"])
    # overlap check: no region (with the leaf gutters) overlaps another
    occ = np.zeros(atlas.shape[:2], int)
    for key, r in regions.items():
        x, y, w, h = r["region"]
        g = GUTTER if key.startswith("leaf") else 0
        occ[max(y - g, 0):y + h + g, max(x - g, 0):x + w + g] += 1
    assert occ.max() == 1, "regions overlap"
    save(atlas, os.path.join(OUT, "corridor-seal-atlas.png"))
    for f in ("corridor-far.png", "corridor-mid.png"):
        shutil.copy(os.path.join(L, f), os.path.join(OUT, f))
    regions["leaf_front"]["texels_per_m"] = [LEAF_U_PPM, LEAF_H_PPM]
    regions["leaf_front"]["uv_metres"] = "u = metres back from the leading edge (0..%.2f), v = metres DOWN from the leaf's top (h = %.2f - v)" % (d7.LEAF_L, d7.LEAF_H)
    regions["leaf_edge"]["texels_per_m"] = [LEAF_H_PPM, LEAF_H_PPM]
    regions["leaf_edge"]["uv_metres"] = "u = metres across the edge from the leaf's front face (0..0.24), v as leaf_front"
    json.dump({"atlas": regions}, open(os.path.join(OUT, "atlas-regions.json"), "w"), indent=1)
    # free space left for other tracks (e.g. the beacons): every empty rectangle of the atlas's rows
    used = occ > 0
    print(json.dumps(regions, indent=1))
    print("free rows below y:", int(np.nonzero(used.any(1))[0].max()) + 1, "| free columns right of x at row 705+:", int(np.nonzero(used[705:].any(0))[0].max()) + 1)


if __name__ == "__main__":
    main()
