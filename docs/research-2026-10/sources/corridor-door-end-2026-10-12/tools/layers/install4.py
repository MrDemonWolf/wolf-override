"""Fix round 3 (v4): builds the game-ready files from layers/v4 and copies them into game-slice.

- corridor-mid.png: main's mid plate with the old pipe column and hazard pump erased (as before) and
  the stations' footprint contact shadows. The cross-wall is no longer in it: the plate is VRAM
  compressed (main's settings, which the opening frames need), and its 5:6:5 blocks turned the
  concrete's grain into violet and green speckle (review round 3). The wall now draws from the
  lossless atlas.
- corridor-far.png: layers/v4/corridor-far.png.
- corridor-seal-atlas.png: ONE lossless 1024 x 1024 atlas for every door-end sprite, each piece's
  region and world top-left in placement.json:
    wall      the cross-wall behind the walk line (doorway alpha 0), with the bypass backplate,
              gearbox and chain guard, and main's mid plate baked over it where main's plate is in
              front (2 px per world px; z -3, over the mid plate, under everything else)
    curtain   the closed curtain (DoorArt and SealLeaf's art), 4 px per world px
    open      the bottom bar tucked under the hood (CorridorDoorOpen), 4 px
    frame     far guide, hood, operator (over the curtain, under the actors), 4 px
    column    the near column (guide, frame, end face, chamfer, lamp socket and guard, push buttons),
              2 px, clear where the hood is in front of it
    camera    the camera on its arm, 2 px
    stub      the wall's 0.15 m stub along its line with its contact shadows, 2 px
    lens      the lamp's glass (tinted live), 4 px
    wheel     the handwheel, centred on its hub, 4 px
  column, camera and stub are cut from one image on one 2 px grid; where two pieces meet, each also
  carries its neighbour's fully opaque pixels for 2 px, so the cut never shows (only opaque pixels
  are drawn twice).
"""
from __future__ import annotations

import json
import os
import shutil

import numpy as np
from PIL import Image

from install2 import load, over, down2, trim, save, station_shadow

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
L = os.path.join(R, "layers", "v4")
OUT = os.path.join(L, "game")
GS = os.path.join(R, "game-slice", "apps", "game", "assets")
GM = os.path.join(R, "game-main", "apps", "game", "assets")
MID_TOP = 51.5
CVD_X0, CVD_Y0 = 676.0, 150.0
CV2_X0, CV2_Y0 = 680.0, 150.0
ATLAS = (1024, 1024)
# front pieces (world rects, owner partition): x0, y0, x1, y1
PIECES = {"camera": lambda x, y: (x < 786.0) & (y < 452.0),
          "column": lambda x, y: (x >= 786.0) & (x < 821.0) & (y < 452.0),
          "stub": lambda x, y: (y >= 452.0) | (x >= 821.0)}
OVERLAP = 2  # px


def place_on(canvas_shape, img, x, y):
    out = np.zeros(canvas_shape)
    h, w = img.shape[:2]
    H, W = canvas_shape[:2]
    x0, y0 = max(x, 0), max(y, 0)
    x1, y1 = min(x + w, W), min(y + h, H)
    out[y0:y1, x0:x1] = img[y0 - y:y1 - y, x0 - x:x1 - x]
    return out


def cut(img, origin, owner):
    """The piece of `img` (2 px per world px, top-left at world `origin`) whose pixels `owner`
    claims, plus the fully opaque pixels of its neighbours within OVERLAP px of it."""
    from scipy import ndimage
    H, W = img.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W]
    wx = origin[0] + (xx + 0.5) / 2.0
    wy = origin[1] + (yy + 0.5) / 2.0
    own = owner(wx, wy) & (img[..., 3] > 0)
    near = ndimage.binary_dilation(own, iterations=OVERLAP) & ~own & (img[..., 3] >= 0.999)
    piece = img.copy()
    piece[~(own | near)] = 0.0
    return piece


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    place: dict = {}
    mid0 = load(os.path.join(GM, "rooms", "corridor-mid.png"))
    mid = mid0.copy()
    mid[200:, 1400:, 3] = 0.0  # the old pipe column and pump (as v1-v3)
    spec = json.load(open(os.path.join(R, "design", "stations", "spec.json")))
    shadows = {}
    for name, s in spec.items():
        x0p, _, x1p, _ = s["plinth_px"]
        wx0 = s["centre_world_x"] + (x0p - s["sprite_centre_px_x"]) / 4.0
        wx1 = s["centre_world_x"] + (x1p - s["sprite_centre_px_x"]) / 4.0
        over(mid, station_shadow(wx0, wx1), int(round((wx0 - 4) * 2)), int(round((440 - MID_TOP) * 2)))
        shadows[name] = [round(wx0, 2), round(wx1, 2)]
    save(mid, os.path.join(OUT, "corridor-mid.png"))
    shutil.copy(os.path.join(L, "corridor-far.png"), os.path.join(OUT, "corridor-far.png"))
    # the wall sprite: the wall layer at 2 px, with main's (erased) mid plate over it where main's
    # plate is in front of it (as the v1-v3 plates had it)
    wall = down2(load(os.path.join(L, "portal-wall.png")))
    fx, fy = int(CVD_X0 * 2), int(round((CVD_Y0 - MID_TOP) * 2))
    main_on_wall = place_on(wall.shape, mid0.copy(), -fx, -fy)
    erased = np.zeros(wall.shape[:2], bool)
    yy = np.arange(wall.shape[0])[:, None] + fy
    xx = np.arange(wall.shape[1])[None, :] + fx
    erased = (yy >= 200) & (xx >= 1400)
    main_on_wall[..., 3] = np.where(erased, 0.0, main_on_wall[..., 3]) * (wall[..., 3] > 0)
    over(wall, main_on_wall, 0, 0)
    wall_t, (wx0, wy0, _, _) = trim(wall)
    # the front pieces (column, camera, stub) on one 2 px grid
    front = load(os.path.join(L, "portal-front.png"))
    frame2 = load(os.path.join(L, "portal-frame.png"))
    frame_on_cvd = np.zeros_like(front)
    frame_on_cvd[:frame2.shape[0], 16:16 + frame2.shape[1]] = frame2
    front[..., 3] *= 1.0 - np.clip(frame_on_cvd[..., 3] * 1.5, 0, 1)
    fs = down2(front)
    pieces = {
        "curtain": (load(os.path.join(L, "portal-curtain.png")), 4.0, (CV2_X0, CV2_Y0)),
        "open": (load(os.path.join(L, "portal-curtain-open.png")), 4.0, (CV2_X0, CV2_Y0)),
        "frame": (frame2, 4.0, (CV2_X0, CV2_Y0)),
    }
    trimmed = {}
    for key, (img, ppw, (cx, cy)) in pieces.items():
        t, (x0, y0, _, _) = trim(img)
        trimmed[key] = (t, ppw, [cx + x0 / ppw, cy + y0 / ppw])
    trimmed["wall"] = (wall_t, 2.0, [CVD_X0 + wx0 / 2.0, CVD_Y0 + wy0 / 2.0])
    for key, rect in PIECES.items():
        pc = cut(fs, (CVD_X0, CVD_Y0), rect)
        t, (x0, y0, _, _) = trim(pc)
        trimmed[key] = (t, 2.0, [CVD_X0 + x0 / 2.0, CVD_Y0 + y0 / 2.0])
    trimmed["lens"] = (load(os.path.join(L, "lens.png")), 4.0, None)
    trimmed["wheel"] = (load(os.path.join(L, "bypass-wheel.png")), 4.0, None)
    # shelf packing: the tall pieces in one row, the rest below
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
    atlas = np.zeros((ATLAS[1], ATLAS[0], 4))
    regions = {}
    for key, (img, ppw, tl) in trimmed.items():
        ax, ay = layout[key]
        h, w = img.shape[:2]
        assert ax + w <= ATLAS[0] and ay + h <= ATLAS[1], (key, ax, ay, w, h)
        atlas[ay:ay + h, ax:ax + w] = img
        regions[key] = {"region": [ax, ay, w, h], "scale": 1.0 / ppw}
        if tl is not None:
            regions[key]["world_top_left"] = [round(tl[0], 4), round(tl[1], 4)]
    save(atlas, os.path.join(OUT, "corridor-seal-atlas.png"))
    place["atlas"] = regions
    place["wheel_centre_world"] = [694.0, 400.0]
    place["station_contact_shadows_world_x"] = shadows
    json.dump(place, open(os.path.join(OUT, "placement.json"), "w"), indent=1)
    for f in ("corridor-far.png", "corridor-mid.png"):
        shutil.copy(os.path.join(OUT, f), os.path.join(GS, "rooms", f))
    shutil.copy(os.path.join(OUT, "corridor-seal-atlas.png"), os.path.join(GS, "props", "corridor-seal-atlas.png"))
    print(json.dumps(place, indent=1))


if __name__ == "__main__":
    main()
