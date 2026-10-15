"""Records doors: Codex edit targets and area maps (doors-r1, records track). Scratch only.

Writes codex/<job>/refs/1-edit-target.png (the flat-shaded construction drawing in the room's real
plates for context), refs/2-areas-to-paint.png (white: the parts to paint) and layout.json (how to
map the painted image back to the design canvases). Jobs:
  records-exit   the right end (cross-wall, door shut, column, stub, passage beyond, container)
  records-entry  the left end (cross-wall, door shut, column, stub, vestibule beyond)
  records-parts  the leaf's three faces and latch edge (flat, in the leaf's plane) and the container
"""
from __future__ import annotations

import json
import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rmodel as M  # noqa: E402
import rdesign as RD  # noqa: E402
import compose as C  # noqa: E402

CODEX = os.path.join(M.TRACK, "..", "codex")
PPW = 4.0


def door_target(side):
    piece = "exit" if side > 0 else "entry"
    job = f"r2-records-{piece}"
    door = M.DoorEnd(side, RD.XC if side > 0 else RD.XE)
    X0 = 757.0 if side > 0 else -53.0
    Y0 = 140.0
    Wd, Hd = 236.0, 355.0
    W, H = int(Wd * PPW), int(Hd * PPW)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    far = Image.open(os.path.join(C.GAME, "assets", "rooms", "records-far.png")).convert("RGBA")
    shift = RD.FAR_SHIFT_RIGHT if side > 0 else RD.FAR_SHIFT_LEFT
    fx0, fy0 = (X0 - shift) * 2, (Y0 - 69.0) * 2
    img.alpha_composite(far.crop((int(fx0), int(fy0), int(fx0 + Wd * 2), int(fy0 + Hd * 2))).resize((W, H), Image.Resampling.BICUBIC))
    dcv_x0 = 770.0 if side > 0 else -40.0
    off = (int((dcv_x0 - X0) * PPW), int((140.0 - Y0) * PPW))
    area = np.zeros((H, W))
    d = os.path.join(M.DESIGN, piece)

    def paste(name, mask_name):
        im = Image.open(os.path.join(d, name)).convert("RGBA")
        img.alpha_composite(im, off)
        m = np.asarray(Image.open(os.path.join(d, "masks", mask_name)), dtype=np.float64) / 255.0
        area[off[1]:off[1] + m.shape[0], off[0]:off[0] + m.shape[1]] = np.maximum(area[off[1]:off[1] + m.shape[0], off[0]:off[0] + m.shape[1]], m)

    paste("design-beyond.png", "beyond--ALPHA.png")
    mid = Image.open(os.path.join(C.GAME, "assets", "rooms", "records-mid.png")).convert("RGBA")
    mcrop = mid.crop((int(X0 * 2), int((Y0 - 69.0) * 2), int((X0 + Wd) * 2), int((Y0 + Hd - 69.0) * 2))).resize((W, H), Image.Resampling.BICUBIC)
    a = np.asarray(mcrop).copy()
    XX, YY = np.meshgrid(X0 + (np.arange(W) + 0.5) / PPW, Y0 + (np.arange(H) + 0.5) / PPW)
    erase = ((YY >= 166.0) & ((XX >= 792.5) | (XX < 160.5))) | (XX >= 905.0) | (XX < 56.0)
    a[..., 3] = np.where(erase, 0, a[..., 3])
    img.alpha_composite(Image.fromarray(a, "RGBA"))
    paste("design-wall.png", "wall--ALPHA.png")
    if side > 0:
        cont = Image.open(os.path.join(M.DESIGN, "container", "design-container.png")).convert("RGBA")
        cs = json.load(open(os.path.join(M.DESIGN, "container", "spec.json")))
        co = (int((cs["canvas"]["x0"] - X0) * PPW), int((cs["canvas"]["y0"] - Y0) * PPW))
        img.alpha_composite(cont, co)
        m = np.asarray(Image.open(os.path.join(M.DESIGN, "container", "masks", "container--ALPHA.png")), dtype=np.float64) / 255.0
        area[co[1]:co[1] + m.shape[0], co[0]:co[0] + m.shape[1]] = np.maximum(area[co[1]:co[1] + m.shape[0], co[0]:co[0] + m.shape[1]], m)
    # fix round 2 (N1): painted OPEN with no leaf: the doorway shows the passage (or vestibule) behind it,
    # painted as itself; the leaf's faces are painted flat on the parts sheet. (Round 1 painted the shut
    # leaf here and the cleanup then built the space behind the doorway from it: a ghost door.)
    paste("design-front.png", "front--ALPHA.png")
    out = os.path.join(CODEX, job)
    os.makedirs(os.path.join(out, "refs"), exist_ok=True)
    os.makedirs(os.path.join(out, "out"), exist_ok=True)
    TW, TH = 1024, 1536
    img.convert("RGB").resize((TW, TH), Image.Resampling.LANCZOS).save(os.path.join(out, "refs", "1-edit-target.png"))
    am = Image.fromarray(((area > 0.02) * 255).astype(np.uint8), "L").resize((TW, TH), Image.Resampling.NEAREST)
    am.save(os.path.join(out, "refs", "2-areas-to-paint.png"))
    json.dump({"world_x0": X0, "world_y0": Y0, "world_w": Wd, "world_h": Hd, "target": [TW, TH]}, open(os.path.join(out, "layout.json"), "w"), indent=1)
    return out


def parts_target():
    job = "r2-records-parts"
    out = os.path.join(CODEX, job)
    os.makedirs(os.path.join(out, "refs"), exist_ok=True)
    os.makedirs(os.path.join(out, "out"), exist_ok=True)
    TW, TH = 1024, 1024
    sheet = Image.new("RGB", (TW, TH), (58, 60, 64))
    area = Image.new("L", (TW, TH), 0)
    layout = {"target": [TW, TH], "items": {}}
    k = 3
    x = 16
    for name in ("room", "out-exit", "out-entry"):
        im = Image.open(os.path.join(M.DESIGN, "leaf", f"design-{name}.png")).convert("RGB")
        big = im.resize((im.size[0] * k, im.size[1] * k), Image.Resampling.LANCZOS)
        y = 60
        sheet.paste(big, (x, y))
        area.paste(255, (x, y, x + big.size[0], y + big.size[1]))
        layout["items"][name] = {"xy": [x, y], "scale": k, "size": list(im.size)}
        x += big.size[0] + 16
    e = Image.open(os.path.join(M.DESIGN, "leaf", "design-edge.png")).convert("RGB")
    big = e.resize((e.size[0] * k, e.size[1] * k), Image.Resampling.LANCZOS)
    sheet.paste(big, (x, 60))
    area.paste(255, (x, 60, x + big.size[0], 60 + big.size[1]))
    layout["items"]["edge"] = {"xy": [x, 60], "scale": k, "size": list(e.size)}
    x += big.size[0] + 16
    c = Image.open(os.path.join(M.DESIGN, "container", "design-container.png")).convert("RGBA")
    kc = 1.45
    cb = c.resize((int(c.size[0] * kc), int(c.size[1] * kc)), Image.Resampling.LANCZOS)
    cy = 60 + 513 - cb.size[1]
    bg = Image.new("RGBA", cb.size, (58, 60, 64, 255))
    bg.alpha_composite(cb)
    sheet.paste(bg.convert("RGB"), (x, cy))
    ca = np.asarray(cb)[..., 3] > 20
    am = np.asarray(area).copy()
    am[cy:cy + cb.size[1], x:x + cb.size[0]] = np.maximum(am[cy:cy + cb.size[1], x:x + cb.size[0]], ca * 255)
    area = Image.fromarray(am)
    layout["items"]["container"] = {"xy": [x, cy], "scale": kc, "size": list(c.size)}
    sheet.save(os.path.join(out, "refs", "1-edit-target.png"))
    area.save(os.path.join(out, "refs", "2-areas-to-paint.png"))
    json.dump(layout, open(os.path.join(out, "layout.json"), "w"), indent=1)
    return out


if __name__ == "__main__":
    which = sys.argv[1:] or ["exit", "entry", "parts"]
    if "exit" in which:
        print(door_target(1))
    if "entry" in which:
        print(door_target(-1))
    if "parts" in which:
        print(parts_target())
