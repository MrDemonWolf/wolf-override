"""Fix round 1 (v2): builds the game-ready files from layers/v2 and copies them into game-slice.

- corridor-mid.png: main's mid plate with the old pipe column and hazard pump erased (as v1), NO
  relay conduits (review S5), the cross-wall's parts behind the walk line (layers/v2/portal-wall,
  4 -> 2 source px per world px) and the near pier's upper part (above y SPLIT_Y, where no actor
  passes) under the ceiling rack, and the stations' footprint contact shadows (review item 5).
- corridor-far.png: layers/v2/corridor-far.png.
- props (4 source px per world px, trimmed to their opaque bounds):
  corridor-seal-curtain.png  the closed curtain (DoorArt, and SealLeaf's art)
  corridor-seal-open.png     the bottom bar tucked under the hood (CorridorDoorOpen)
  corridor-seal-frame.png    far guide, hood, operator (over the curtain, under the actors)
  corridor-seal-front.png    the near pier, near guide, lamp socket and guard, push buttons (over
                             the actors; transparent where the hood is in front of it)
  corridor-seal-lens.png     the lamp's glass (tinted live)
  corridor-bypass-wheel.png  the handwheel, centred on its hub
Writes layers/v2/game/ and placement.json, then copies into game-slice/apps/game/assets.
"""
from __future__ import annotations

import json
import os
import shutil

import numpy as np
from PIL import Image

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
L = os.path.join(R, "layers", "v2")
OUT = os.path.join(L, "game")
GS = os.path.join(R, "game-slice", "apps", "game", "assets")
GM = os.path.join(R, "game-main", "apps", "game", "assets")
MID_TOP = 51.5
CV_X0, CV_Y0, PPW = 680.0, 150.0, 4.0
SPLIT_Y = 236.0  # world y: the near pier above this goes into the mid plate (no actor reaches it)


def load(path: str) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGBA")).astype(np.float64) / 255.0


def over(dst: np.ndarray, src: np.ndarray, x: int, y: int) -> None:
    h, w = src.shape[:2]
    d = dst[y:y + h, x:x + w]
    sa = src[..., 3:4]
    da = d[..., 3:4]
    oa = sa + da * (1 - sa)
    d[..., :3] = (src[..., :3] * sa + d[..., :3] * da * (1 - sa)) / np.maximum(oa, 1e-9)
    d[..., 3:4] = oa


def down2(a: np.ndarray) -> np.ndarray:
    h, w = a.shape[0] // 2 * 2, a.shape[1] // 2 * 2
    a = a[:h, :w]
    pm = (a[..., :3] * a[..., 3:4]).reshape(h // 2, 2, w // 2, 2, 3).mean((1, 3))
    al = a[..., 3].reshape(h // 2, 2, w // 2, 2).mean((1, 3))
    return np.dstack([pm / np.maximum(al[..., None], 1e-9), al])


def trim(a: np.ndarray):
    ys, xs = np.nonzero(a[..., 3] > 0)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    return a[y0:y1, x0:x1], (int(x0), int(y0), int(x1), int(y1))


def save(a: np.ndarray, path: str) -> None:
    u = (np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8)
    u[u[..., 3] == 0, :3] = 0
    Image.fromarray(u, "RGBA").save(path)


def station_shadow(world_x0: float, world_x1: float) -> np.ndarray:
    """A footprint contact shadow on the floor under a plinth, at 2 px per world px: darkest (alpha
    0.70, the floor at 0.30) on the contact line, gone 14 world px out, soft at the ends."""
    W = int(round((world_x1 - world_x0 + 8) * 2))
    Hh = 30
    yy, xx = np.mgrid[0:Hh, 0:W].astype(float)
    dy = (yy + 0.5) / 2.0
    xw = world_x0 - 4 + (xx + 0.5) / 2.0
    edge = np.clip(np.minimum(xw - (world_x0 - 2.5), (world_x1 + 2.5) - xw) / 2.0, 0, 1)
    a = 0.70 * np.exp(-dy / 4.0) * edge
    rgba = np.zeros((Hh, W, 4))
    rgba[..., :3] = np.array([2, 5, 8]) / 255.0
    rgba[..., 3] = a
    return rgba


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    place = {}
    mid0 = load(os.path.join(GM, "rooms", "corridor-mid.png"))
    mid = mid0.copy()
    mid[200:, 1400:, 3] = 0.0  # the old pipe column and pump (as v1); no relay conduits
    wall = load(os.path.join(L, "portal-wall.png"))
    front = load(os.path.join(L, "portal-front.png"))
    frame = load(os.path.join(L, "portal-frame.png"))
    split_px = int(round((SPLIT_Y - CV_Y0) * PPW))
    upper = front.copy()
    upper[split_px:, :, 3] = 0.0
    lower = front.copy()
    lower[:split_px, :, 3] = 0.0
    # the hood (frame layer) is in front of the near pier: the pier's front layer is clear under it
    lower[..., 3] *= (1.0 - np.clip(frame[..., 3] * 1.5, 0, 1))
    base = np.zeros_like(mid)
    stack = wall.copy()
    over(stack, upper, 0, 0)
    small = down2(stack)
    fx, fy = int(CV_X0 * 2), int(round((CV_Y0 - MID_TOP) * 2))
    base[fy:fy + small.shape[0], fx:fx + small.shape[1]] = small
    over(base, mid, 0, 0)  # the rack and everything else of the plate over the cross-wall
    mid = base
    # stations' contact shadows on the floor (footprints from the v1 station specs)
    spec = json.load(open(os.path.join(R, "design", "stations", "spec.json")))
    shadows = {}
    for name, s in spec.items():
        x0p, _, x1p, _ = s["plinth_px"]
        wx0 = s["centre_world_x"] + (x0p - s["sprite_centre_px_x"]) / 4.0
        wx1 = s["centre_world_x"] + (x1p - s["sprite_centre_px_x"]) / 4.0
        sh = station_shadow(wx0, wx1)
        over(mid, sh, int(round((wx0 - 4) * 2)), int(round((440 - MID_TOP) * 2)))
        shadows[name] = [round(wx0, 2), round(wx1, 2)]
    save(mid, os.path.join(OUT, "corridor-mid.png"))
    shutil.copy(os.path.join(L, "corridor-far.png"), os.path.join(OUT, "corridor-far.png"))
    for src, dst, arr in (("portal-curtain.png", "corridor-seal-curtain.png", None), ("portal-curtain-open.png", "corridor-seal-open.png", None),
                          ("portal-frame.png", "corridor-seal-frame.png", None), ("front-lower", "corridor-seal-front.png", lower)):
        a = arr if arr is not None else load(os.path.join(L, src))
        a, (x0, y0, x1, y1) = trim(a)
        save(a, os.path.join(OUT, dst))
        place[dst] = {"world_top_left": [CV_X0 + x0 / PPW, CV_Y0 + y0 / PPW], "size_px": [x1 - x0, y1 - y0], "scale": 0.25}
    shutil.copy(os.path.join(L, "lens.png"), os.path.join(OUT, "corridor-seal-lens.png"))
    shutil.copy(os.path.join(L, "bypass-wheel.png"), os.path.join(OUT, "corridor-bypass-wheel.png"))
    place["corridor-bypass-wheel.png"] = {"centre_world": [695.0, 403.0], "size_px": [88, 88], "scale": 0.25}
    place["corridor-seal-lens.png"] = {"size_px": [32, 40], "scale": 0.25}
    place["station_contact_shadows_world_x"] = shadows
    json.dump(place, open(os.path.join(OUT, "placement.json"), "w"), indent=1)
    for f in ("corridor-far.png", "corridor-mid.png"):
        shutil.copy(os.path.join(OUT, f), os.path.join(GS, "rooms", f))
    for f in ("corridor-seal-curtain.png", "corridor-seal-open.png", "corridor-seal-frame.png", "corridor-seal-front.png", "corridor-seal-lens.png", "corridor-bypass-wheel.png"):
        shutil.copy(os.path.join(OUT, f), os.path.join(GS, "props", f))
    print(json.dumps(place, indent=1))


if __name__ == "__main__":
    main()
