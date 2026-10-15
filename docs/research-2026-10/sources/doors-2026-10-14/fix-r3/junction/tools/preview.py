"""Design previews (scratch only): stacks the design layers over main's junction plates and props at
the play framing, with the engineer and WOLF at named gameplay x for scale. Not a game capture:
review-only composites (the game captures come from tools/render/render.sh).

usage: preview.py [design|layers] OUTDIR   (design: design/design-*.png ; layers: layers/final/*.png)
"""
from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(__file__))
import jmodel as M  # noqa: E402

A = os.path.join(M.MAIN, "assets")
S = 4  # preview px per world px


def room(cam_x=480.0):
    W, H = 960 * S, 640 * S
    img = Image.new("RGBA", (W, H), (10, 14, 24, 255))
    far = Image.open(os.path.join(A, "rooms/junction-far.png")).convert("RGBA").resize((960 * S, 540 * S), Image.Resampling.LANCZOS)
    shift = (cam_x - 480.0) * 0.1  # Parallax2D at 0.9 lags the camera
    img.alpha_composite(far, (int(round(shift * S)), 79 * S))
    mid = Image.open(os.path.join(A, "rooms/junction-mid.png")).convert("RGBA").resize((960 * S, 540 * S), Image.Resampling.LANCZOS)
    img.alpha_composite(mid, (0, 52 * S))
    return img


def prop(img, name, region, scale, cx, base=440.0):
    im = Image.open(os.path.join(A, name)).convert("RGBA").crop((int(region[0]), int(region[1]), int(region[0] + region[2]), int(region[1] + region[3])))
    w, h = region[2] * scale * S, region[3] * scale * S
    im = im.resize((int(round(w)), int(round(h))), Image.Resampling.LANCZOS)
    img.alpha_composite(im, (int(round(cx * S - w / 2)), int(round(base * S - h))))


def actor(img, name, x, height, flip=False):
    im = Image.open(os.path.join(A, name)).convert("RGBA")
    im = im.crop(im.getbbox())
    k = height * S / im.height
    im = im.resize((max(1, int(im.width * k)), int(height * S)), Image.Resampling.LANCZOS)
    if flip:
        im = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    img.alpha_composite(im, (int(round(x * S - im.width / 2)), int(round(440 * S - im.height))))


def layer(img, path, x0=M.CV.x0, y0=M.CV.y0, ppw=M.CV.ppw):
    if not os.path.exists(path):
        return
    im = Image.open(path).convert("RGBA")
    k = S / ppw
    if k != 1:
        im = im.resize((int(round(im.width * k)), int(round(im.height * k))), Image.Resampling.LANCZOS)
    img.alpha_composite(im, (int(round(x0 * S)), int(round(y0 * S))))


def props_under(img):
    prop(img, "props/corridor-breaker.png", (81, 46, 342, 433), 0.225, 200)
    prop(img, "props/junction-valve.png", (3, 11, 506, 490), 0.2, 420)
    arm_x = 545 + 354 * 0.14 * 0.5 + 2.0
    prop(img, "props/junction-arm-panel.png", (79, 26, 354, 463), 0.14, arm_x)


def state(kind, src, which, actors=()):
    img = room()
    def L(n):
        if which == "layers":
            for sub in ("sealed", "blown"):
                p = os.path.join(M.WORK, "layers", sub, f"{n}.png")
                if os.path.exists(p):
                    return p
        return os.path.join(M.WORK, "design", f"design-{n}.png")
    if kind == "blown":
        layer(img, L("hole"))
    if kind == "sealed":
        layer(img, L("leaf"))
    if kind == "breaking":
        layer(img, L("leafbreak"))
    layer(img, L("wall"))
    if kind == "breaking":
        layer(img, L("cracks"))
    if kind == "blown":
        layer(img, L("damage"))
    layer(img, L("alcove"))
    props_under(img)
    for (name, x, h, flip) in actors:
        actor(img, name, x, h, flip)
    layer(img, L("front"))
    if kind == "blown":
        layer(img, L("lying"))
    return img


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else "design"
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(M.WORK, "review", "preview")
    os.makedirs(out, exist_ok=True)
    src = os.path.join(M.WORK, "design") if which == "design" else os.path.join(M.WORK, "layers", "final")
    eng, wolf = "rowan-side-right-provisional.png", "wolf-side-right-provisional.png"
    shots = {
        "sealed": [(eng, 438.0, 69.6, False), (wolf, 300.0, 59.0, False)],
        "breaking": [(eng, 330.0, 69.6, True)],
        "blown": [(wolf, 448.0, 59.0, False), (eng, 526.0, 69.6, False)],
        "blown-arm": [(wolf, 448.0, 59.0, False), (eng, 573.0, 69.6, False)],
    }
    for name, act in shots.items():
        kind = name.split("-")[0]
        img = state(kind, src, which, act)
        view = img.crop((int(124.5 * S), 160 * S, int(835.5 * S), 560 * S)).resize((1280, 720), Image.Resampling.LANCZOS)
        view.convert("RGB").save(os.path.join(out, f"{name}-view.png"))
        img.crop((380 * S, 270 * S, 660 * S, 505 * S)).resize((280 * 4, 235 * 4), Image.Resampling.LANCZOS).convert("RGB").save(os.path.join(out, f"{name}-zoom.png"))
    print("previews in", out)


if __name__ == "__main__":
    main()
