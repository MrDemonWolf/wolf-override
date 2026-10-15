"""Adds the exit bolt panel's riser continuation to the open-state design, and builds the Codex edit
targets (scratch only).

The exit bolt panel (junction-bolt-panel.png, a station prop, unchanged) has a vertical riser on its
right edge that the image cuts in half and ends at y 416, in mid-air; it used to vanish behind the old
hatch. Its continuation is designed here: the riser's right half up to its cap, then the whole pipe down
into a floor flange on the deck, drawn under the panel (in the back layer).

Usage: python compose.py DESIGN_DIR GAME_ASSETS OUT_DIR
"""
from __future__ import annotations

import json
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, __file__.rsplit("/", 1)[0])
import design as d  # noqa: E402

D, ASSETS, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
PPW = d.PPW
X0, Y0 = d.X0, d.Y0
MAG = (255, 0, 255)

# the panel: BOLT_PANEL_X 806, region (0, 68, 512, 393), scale 0.15, base on the floor
PANEL_X, PANEL_SCALE, PANEL_REGION = 796.0, 0.15, (0, 68, 512, 461)
RISER_X = PANEL_X + (512 - 256) * PANEL_SCALE          # 844.4: the riser's centre is the image edge
RISER_R = 3.1                                          # world px (0.155 m)
RISER_TOP = 440.0 - (461 - 131) * PANEL_SCALE          # its cap (390.5)
FLANGE = (RISER_X - 4.4, 437.4, RISER_X + 4.4, 440.6)  # floor flange on the deck lip


def c(X, Y):
    return (X - X0) * PPW, (Y - Y0) * PPW


def riser_layers(w, h):
    """Masks and a design shading for the riser and its flange (cylinder lit from upper left)."""
    pipe = Image.new("L", (w, h), 0)
    flange = Image.new("L", (w, h), 0)
    dp, df = ImageDraw.Draw(pipe), ImageDraw.Draw(flange)
    x0, y0 = c(RISER_X - RISER_R, RISER_TOP + 1.0)
    x1, y1 = c(RISER_X + RISER_R, 438.0)
    dp.rectangle([x0, y0, x1, y1], fill=255)
    # collar at the top cap
    cx0, cy0 = c(RISER_X - RISER_R - 0.6, RISER_TOP)
    cx1, cy1 = c(RISER_X + RISER_R + 0.6, RISER_TOP + 2.2)
    dp.rectangle([cx0, cy0, cx1, cy1], fill=255)
    fx0, fy0 = c(FLANGE[0], FLANGE[1])
    fx1, fy1 = c(FLANGE[2], FLANGE[3])
    df.rectangle([fx0, fy0, fx1, fy1], fill=255)
    pm = np.asarray(pipe) > 0
    fm = np.asarray(flange) > 0
    ys, xs = np.mgrid[0:h, 0:w].astype(float)
    X = X0 + (xs + 0.5) / PPW
    t = np.clip((X - RISER_X) / RISER_R, -1, 1)
    ncos = np.sqrt(1 - t * t)
    # light from the upper left (the junction fitting), a soft highlight left of centre
    shade = 0.10 + 0.55 * np.clip(-0.45 * t + 0.75 * ncos, 0, 1) ** 1.4
    base = np.array([62, 64, 68], float)
    rgb = np.zeros((h, w, 3))
    rgb[pm] = (base[None, :] * (0.35 + shade[pm, None]))
    rgb[fm] = np.array([58, 60, 64])[None, :] * 0.9
    return pm, fm, rgb


def main():
    o = np.asarray(Image.open(f"{D}/design-open.png")).astype(float)
    h, w = o.shape[:2]
    pm, fm, rrgb = riser_layers(w, h)
    rmask = (pm | fm) & (o[..., 3] < 128)
    o[rmask, :3] = rrgb[rmask]
    o[rmask, 3] = 255
    Image.fromarray(np.clip(o + 0.5, 0, 255).astype(np.uint8), "RGBA").save(f"{OUT}/design-open-full.png")
    Image.fromarray((pm & rmask).astype(np.uint8) * 255).save(f"{OUT}/mask-riser.png")
    Image.fromarray((fm & rmask).astype(np.uint8) * 255).save(f"{OUT}/mask-riser-flange.png")

    # the edit target: the open state on #FF00FF, the bolt panel composited (reference, never painted)
    canvas = Image.new("RGBA", (w, h), MAG + (255,))
    canvas.alpha_composite(Image.fromarray(np.clip(o + 0.5, 0, 255).astype(np.uint8), "RGBA"))
    panel = Image.open(f"{ASSETS}/props/junction-bolt-panel.png").crop(PANEL_REGION)
    pw, ph = panel.size
    sc = PANEL_SCALE * PPW
    panel = panel.resize((round(pw * sc), round(ph * sc)), Image.Resampling.LANCZOS)
    px, py = c(PANEL_X - pw * PANEL_SCALE / 2, 440.0 - ph * PANEL_SCALE)
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    layer.paste(panel, (round(px), round(py)))
    canvas.alpha_composite(layer)
    panel_m = np.asarray(layer)[..., 3] > 0
    # 1024 x 1536 portrait: scale to the height, pad the width with key
    S = 1536 / h
    tw = round(w * S)
    tgt = canvas.convert("RGB").resize((tw, 1536), Image.Resampling.LANCZOS)
    full = Image.new("RGB", (1024, 1536), MAG)
    full.paste(tgt, (0, 0))
    full.save(f"{OUT}/1-edit-target-exit-door.png")
    paint = (o[..., 3] > 128) & ~panel_m
    # the lamp's lens stays as designed (the game lights it live)
    m = Image.fromarray((paint * 255).astype(np.uint8)).resize((tw, 1536), Image.Resampling.NEAREST)
    area = Image.new("L", (1024, 1536), 0)
    area.paste(m, (0, 0))
    area.save(f"{OUT}/2-areas-to-paint.png")
    json.dump({"design_size": [w, h], "scale": S, "target_size": [1024, 1536], "pad_right": 1024 - tw,
               "world_rect": [X0, Y0, d.X1, d.Y1], "design_px_per_world_px": PPW}, open(f"{OUT}/registration.json", "w"), indent=1)

    # the leaf: on its own, at 8 px per world px, centred on a 1024 x 1024 key canvas
    lf = Image.open(f"{D}/leaf-design-8.png")
    lc = Image.new("RGBA", (1024, 1024), MAG + (255,))
    ox, oy = (1024 - lf.size[0]) // 2, (1024 - lf.size[1]) // 2
    lc.alpha_composite(lf, (ox, oy))
    lc.convert("RGB").save(f"{OUT}/1-edit-target-leaf.png")
    la = Image.new("L", (1024, 1024), 0)
    la.paste(Image.fromarray((np.asarray(lf)[..., 3] > 128).astype(np.uint8) * 255), (ox, oy))
    la.save(f"{OUT}/2-areas-to-paint-leaf.png")
    json.dump({"leaf_size": list(lf.size), "offset": [ox, oy], "ppw": 8}, open(f"{OUT}/registration-leaf.json", "w"), indent=1)
    print("targets written", tw)


if __name__ == "__main__":
    main()
