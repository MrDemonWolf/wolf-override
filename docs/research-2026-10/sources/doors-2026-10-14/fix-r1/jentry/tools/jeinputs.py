"""Junction entry door: the Codex edit targets (doors-r1, fix round 1). Scratch only.
Writes codex/fix-junction-entry/refs: 1-edit-target-entry.png (the flat construction in the junction's
real plates at the left clamp, shut leaf in place), 2-areas-to-paint-entry.png, 3-edit-target-leaf.png
(the leaf's two faces and its edge, flat, on a grey ground) and 4-areas-to-paint-leaf.png; layout.json."""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import jedesign as JE  # noqa: E402  (installs jemodel as rmodel)
import jemodel as M  # noqa: E402
import compose as C  # noqa: E402

GAME = os.path.join(M.TRACK, "..", "main-junction", "apps", "game")
CODEX = os.path.join(M.TRACK, "..", "codex", "fix-junction-entry")
PPW = 4.0
X0, Y0, WD, HD = -60.0, 140.0, 236.0, 355.0


def mid_erase(XX, YY, door):
    """Where the junction's mid plate is cleared for the entry: everything left of the near column
    above the floor (the passage shows there, in the cutaway), and left of the stub's lane face below."""
    col_left = door.s(door.A_END, 1.0, door.T_WALL)[0]
    a = door.stub_far_a(-200.0)
    p0 = door.s(door.A_END, 0.0, door.T_WALL)
    p1 = door.s(a, 0.0, door.T_WALL)
    slope = (p1[1] - p0[1]) / (p1[0] - p0[0])
    line_x = p0[0] + (YY - p0[1]) / slope
    return ((YY < 441.0) & (XX < col_left)) | ((YY >= 441.0) & (XX < line_x))


def main():
    os.makedirs(os.path.join(CODEX, "refs"), exist_ok=True)
    os.makedirs(os.path.join(CODEX, "out"), exist_ok=True)
    door, lps = JE.lamps()
    JE.RD.lamps_for = lambda side: (door, lps, lps[0], lps[2])
    W, H = int(WD * PPW), int(HD * PPW)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    far = Image.open(os.path.join(GAME, "assets", "rooms", "junction-far.png")).convert("RGBA")
    fx0, fy0 = (X0 - JE.FAR_SHIFT_LEFT) * 2, (Y0 - 79.0) * 2
    # the far plate starts at world x = shift: left of it the room's base colour shows
    crop = Image.new("RGBA", (int(WD * 2), int(HD * 2)), (10, 14, 24, 255))
    crop.alpha_composite(far.crop((max(0, int(fx0)), int(fy0), int(fx0 + WD * 2), int(fy0 + HD * 2))), (max(0, -int(fx0)), 0))
    img.alpha_composite(crop.resize((W, H), Image.Resampling.BICUBIC))
    spec = json.load(open(os.path.join(M.DESIGN, "entry", "spec.json")))
    cv = spec["canvas"]
    off = (int((cv["x0"] - X0) * PPW), int((cv["y0"] - Y0) * PPW))
    area = np.zeros((H, W))
    d = os.path.join(M.DESIGN, "entry")

    def paste(name, mask_name):
        im = Image.open(os.path.join(d, name)).convert("RGBA")
        img.alpha_composite(im, off)
        m = np.asarray(Image.open(os.path.join(d, "masks", mask_name)), dtype=np.float64) / 255.0
        h, w = m.shape
        area[off[1]:off[1] + h, off[0]:off[0] + w] = np.maximum(area[off[1]:off[1] + h, off[0]:off[0] + w], m[:H - off[1], :W - off[0]])

    paste("design-beyond.png", "beyond--ALPHA.png")
    mid = Image.open(os.path.join(GAME, "assets", "rooms", "junction-mid.png")).convert("RGBA")
    mcrop = Image.new("RGBA", (int(WD * 2), int(HD * 2)), (0, 0, 0, 0))
    mx0 = int(X0 * 2)
    mcrop.alpha_composite(mid.crop((max(0, mx0), int((Y0 - 52.0) * 2), int((X0 + WD) * 2), int((Y0 + HD - 52.0) * 2))), (max(0, -mx0), 0))
    a = np.asarray(mcrop.resize((W, H), Image.Resampling.BICUBIC)).copy()
    XX, YY = np.meshgrid(X0 + (np.arange(W) + 0.5) / PPW, Y0 + (np.arange(H) + 0.5) / PPW)
    a[..., 3] = np.where(mid_erase(XX, YY, door), 0, a[..., 3])
    img.alpha_composite(Image.fromarray(a, "RGBA"))
    paste("design-wall.png", "wall--ALPHA.png")
    before = np.asarray(img).copy()
    C.place_leaf(img, X0, Y0, door, 0.0, os.path.join(M.DESIGN, "leaf"), "out-exit")
    after = np.asarray(img)
    area = np.maximum(area, (np.abs(after.astype(int) - before.astype(int)).sum(-1) > 0).astype(float))
    paste("design-front.png", "front--ALPHA.png")
    TW, TH = 1024, 1536
    img.convert("RGB").resize((TW, TH), Image.Resampling.LANCZOS).save(os.path.join(CODEX, "refs", "1-edit-target-entry.png"))
    Image.fromarray(((area > 0.02) * 255).astype(np.uint8), "L").resize((TW, TH), Image.Resampling.NEAREST).save(os.path.join(CODEX, "refs", "2-areas-to-paint-entry.png"))
    # the leaf sheet
    sheet = Image.new("RGB", (1024, 1024), (58, 60, 64))
    sarea = Image.new("L", (1024, 1024), 0)
    lay = {"world_x0": X0, "world_y0": Y0, "world_w": WD, "world_h": HD, "target": [TW, TH], "items": {}}
    k, x = 3, 120
    for name in ("room", "out-exit"):
        im = Image.open(os.path.join(M.DESIGN, "leaf", f"design-{name}.png")).convert("RGB")
        big = im.resize((im.size[0] * k, im.size[1] * k), Image.Resampling.LANCZOS)
        sheet.paste(big, (x, 60))
        sarea.paste(255, (x, 60, x + big.size[0], 60 + big.size[1]))
        lay["items"][name] = {"xy": [x, 60], "scale": k, "size": list(im.size)}
        x += big.size[0] + 60
    e = Image.open(os.path.join(M.DESIGN, "leaf", "design-edge.png")).convert("RGB")
    big = e.resize((e.size[0] * k, e.size[1] * k), Image.Resampling.LANCZOS)
    sheet.paste(big, (x, 60))
    sarea.paste(255, (x, 60, x + big.size[0], 60 + big.size[1]))
    lay["items"]["edge"] = {"xy": [x, 60], "scale": k, "size": list(e.size)}
    sheet.save(os.path.join(CODEX, "refs", "3-edit-target-leaf.png"))
    sarea.save(os.path.join(CODEX, "refs", "4-areas-to-paint-leaf.png"))
    json.dump(lay, open(os.path.join(CODEX, "layout.json"), "w"), indent=1)
    print("refs in", CODEX)


if __name__ == "__main__":
    main()
