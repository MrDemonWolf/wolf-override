"""Builds the game-ready slice files from the cleaned layers and copies them into game-slice.

- corridor-mid.png: the mid-plate patch (old column and pump erased, relay conduits) with the
  cast bulkhead frame (layers/door/seal-frame.png, 4 -> 2 source px per world px) under the
  ceiling rack, and the two stations' contact shadows on the floor. The bulkhead is architecture
  at walkway depth, so it lives in the play-plane plate: no extra layer, no extra texture.
- corridor-far.png: the cleaned far plate (layers/room/corridor-far.png).
- corridor-seal-curtain.png, corridor-seal-front.png: the door's moving curtain and its guides,
  hood and stencilled number, trimmed to their opaque bounds (4 px per world px).
- corridor-bypass-wheel.png: the handwheel, 80 x 80 centred on its axis.
- corridor-coolant-relay.png, corridor-safe-point.png: the approved Look 2 stations on their
  plinths, cut at the floor line (their shadows are on the floor, in the mid plate).
Writes layers/game/ and layers/game/placement.json, then copies into game-slice/apps/game/assets.
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
L = os.path.join(R, "layers")
D = os.path.join(R, "design")
OUT = os.path.join(L, "game")
GS = os.path.join(R, "game-slice", "apps", "game", "assets")
MID_TOP = 51.5


def load(path: str) -> np.ndarray:
    return np.asarray(Image.open(path).convert("RGBA")).astype(np.float64) / 255.0


def over(dst: np.ndarray, src: np.ndarray, x: int, y: int) -> None:
    """Premultiplied 'src over dst' of src placed at (x, y) in dst, in place (straight alpha in/out)."""
    h, w = src.shape[:2]
    d = dst[y:y + h, x:x + w]
    sa = src[..., 3:4]
    da = d[..., 3:4]
    oa = sa + da * (1 - sa)
    rgb = (src[..., :3] * sa + d[..., :3] * da * (1 - sa)) / np.maximum(oa, 1e-9)
    d[..., :3] = rgb
    d[..., 3:4] = oa


def down2(a: np.ndarray) -> np.ndarray:
    """Halves an RGBA image with premultiplied box filtering."""
    h, w = a.shape[0] // 2 * 2, a.shape[1] // 2 * 2
    a = a[:h, :w]
    pm = a[..., :3] * a[..., 3:4]
    pm = pm.reshape(h // 2, 2, w // 2, 2, 3).mean((1, 3))
    al = a[..., 3].reshape(h // 2, 2, w // 2, 2).mean((1, 3))
    rgb = pm / np.maximum(al[..., None], 1e-9)
    return np.dstack([rgb, al])


def trim(a: np.ndarray) -> tuple[np.ndarray, tuple[int, int, int, int]]:
    ys, xs = np.nonzero(a[..., 3] > 0)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    return a[y0:y1, x0:x1], (int(x0), int(y0), int(x1), int(y1))


def save(a: np.ndarray, path: str) -> None:
    u = (np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8)
    u[u[..., 3] == 0, :3] = 0
    Image.fromarray(u, "RGBA").save(path)


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    place = {}
    # ---- mid plate: frame under the rack, then the stations' contact shadows
    mid = load(os.path.join(D, "mid-patch", "corridor-mid-patched.png"))
    frame = down2(load(os.path.join(L, "door", "seal-frame.png")))
    fx, fy = int(646 * 2), int(round((140 - MID_TOP) * 2))
    base = np.zeros_like(mid)
    base[fy:fy + frame.shape[0], fx:fx + frame.shape[1]] = frame
    over(base, mid, 0, 0)
    mid = base
    spec = json.load(open(os.path.join(D, "stations", "spec.json")))
    for name, s in spec.items():
        sh = np.asarray(Image.open(os.path.join(D, "stations", "masks", f"{name}--contact_shadow.png")).convert("L")).astype(np.float64) / 255.0
        W, H = s["size"]
        fr = s["floor_row"]
        sh = sh[fr:, :]
        rgba = np.zeros(sh.shape + (4,))
        rgba[..., :3] = np.array([2, 5, 8]) / 255.0
        rgba[..., 3] = sh
        small = down2(rgba)
        left_world = s["centre_world_x"] - s["sprite_centre_px_x"] / 4.0
        x = int(round(left_world * 2))
        y = int(round((440 - MID_TOP) * 2))
        over(mid, small, x, y)
    save(mid, os.path.join(OUT, "corridor-mid.png"))
    shutil.copy(os.path.join(L, "room", "corridor-far.png"), os.path.join(OUT, "corridor-far.png"))
    # ---- curtain and front, trimmed (canvas origin world (646, 140), 4 px per world px)
    for src, dst in (("seal-curtain-canvas.png", "corridor-seal-curtain.png"), ("seal-front-canvas.png", "corridor-seal-front.png")):
        a, (x0, y0, x1, y1) = trim(load(os.path.join(L, "door", src)))
        save(a, os.path.join(OUT, dst))
        place[dst] = {"world_top_left": [646 + x0 / 4, 140 + y0 / 4], "size_px": [x1 - x0, y1 - y0], "scale": 0.25}
    shutil.copy(os.path.join(L, "door", "bypass-wheel.png"), os.path.join(OUT, "corridor-bypass-wheel.png"))
    place["corridor-bypass-wheel.png"] = {"centre_world": [700.0, 398.0], "size_px": [80, 80], "scale": 0.25}
    # ---- stations, cut at the floor line
    for name, fname in (("relay", "corridor-coolant-relay.png"), ("safe-point", "corridor-safe-point.png")):
        s = spec[name]
        a = load(os.path.join(L, "stations", f"{name}-grounded.png"))[: s["floor_row"]]
        save(a, os.path.join(OUT, fname))
        W = a.shape[1]
        place[fname] = {"size_px": [W, s["floor_row"]], "scale": 0.25,
                        "position_centered": [s["centre_world_x"] + (W / 2 - s["sprite_centre_px_x"]) / 4.0, 440.0 - s["floor_row"] / 8.0]}
    json.dump(place, open(os.path.join(OUT, "placement.json"), "w"), indent=1)
    # ---- into the slice copy
    for f in ("corridor-far.png", "corridor-mid.png"):
        shutil.copy(os.path.join(OUT, f), os.path.join(GS, "rooms", f))
    for f in ("corridor-seal-curtain.png", "corridor-seal-front.png", "corridor-bypass-wheel.png", "corridor-coolant-relay.png", "corridor-safe-point.png"):
        shutil.copy(os.path.join(OUT, f), os.path.join(GS, "props", f))
    print(json.dumps(place, indent=1))


if __name__ == "__main__":
    main()
