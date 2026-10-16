"""Round 11: composes the door end's atlas pieces as the game layers them (wall, shut curtain, frame,
then the column, camera and stub over the actors' plane), at ppw px per world px, for previews and
the Codex edit target. Not a capture: no far plate, no actors, no runtime light.
usage (module): compose(atlas_rgba_float, x0, y0, x1, y1, ppw, wall=None, column=None)"""
from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image

R = "scratchpad/real-slice"
REG = json.load(open(os.path.join(R, "add7", "fix3", "door", "game", "atlas-regions.json")))["atlas"]
ORDER = ("wall", "curtain", "frame", "column", "camera", "stub")


def piece(atlas, key, override=None):
    x, y, w, h = REG[key]["region"]
    return override if override is not None else atlas[y:y + h, x:x + w]


def compose(atlas, x0, y0, x1, y1, ppw, wall=None, column=None, bg=(0.09, 0.10, 0.11)):
    W, H = int(round((x1 - x0) * ppw)), int(round((y1 - y0) * ppw))
    out = np.zeros((H, W, 3)) + np.array(bg)
    for key in ORDER:
        img = piece(atlas, key, wall if key == "wall" else column if key == "column" else None)
        sc = REG[key]["scale"]
        tlx, tly = REG[key]["world_top_left"] if "world_top_left" in REG[key] else ((762.5, 267.5) if key == "camera" else (0, 0))
        if key == "camera":
            tlx, tly = 762.5, 267.5
        h, w = img.shape[:2]
        tw, th = max(1, int(round(w * sc * ppw))), max(1, int(round(h * sc * ppw)))
        im = Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8), "RGBA").resize((tw, th), Image.Resampling.BILINEAR)
        a = np.asarray(im).astype(float) / 255.0
        ox, oy = int(round((tlx - x0) * ppw)), int(round((tly - y0) * ppw))
        sx0, sy0 = max(0, -ox), max(0, -oy)
        dx0, dy0 = max(0, ox), max(0, oy)
        dx1, dy1 = min(W, ox + tw), min(H, oy + th)
        if dx1 <= dx0 or dy1 <= dy0:
            continue
        sub = a[sy0:sy0 + dy1 - dy0, sx0:sx0 + dx1 - dx0]
        al = sub[..., 3:4]
        out[dy0:dy1, dx0:dx1] = out[dy0:dy1, dx0:dx1] * (1 - al) + sub[..., :3] * al
    return out


def save(arr, path):
    Image.fromarray((np.clip(arr, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB").save(path)
