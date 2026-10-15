"""Builds the crank paint job's edit target, paint map and reference (codex/paint-crank8/refs/).

1024 x 1024, flat magenta field (keyed out later). Frames A and B (384 x 384 each, rig/frame-*.png)
scaled 1.3x (499 px) side by side at (6, 262) and (519, 262). The wheel's rim is a 1 px cyan circle
(a guide only). Paint map: white only where the rig must be repaired: both arms (dilated), where the
arms left the torso and the legs, and the hip seam; the head, the torso's front and the legs stay.
Reference: the in-game sprite itself, 2x, on the same magenta.
"""
from __future__ import annotations

import json
import os

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
RIG = os.path.abspath(os.path.join(HERE, "..", "rig"))
J = os.path.abspath(os.path.join(HERE, "..", "..", "codex", "paint-crank8"))
SRC = "scratchpad/real-slice/game-add/apps/game/assets/rowan-side-right-provisional.png"
SZ, K = 1024, 1.3
AT = {"A": (6, 262), "B": (519, 262)}
MAG = (255, 0, 255)
PAD = 64


def load_l(p):
    return np.asarray(Image.open(p).convert("L")).astype(float) / 255.0


def zones(key, src_a):
    """Repair zone on the 384x384 frame."""
    z = np.zeros((384, 384), bool)
    for n in ("near_upper", "near_lower", "far_upper", "far_lower"):
        z |= ndimage.binary_dilation(load_l(os.path.join(RIG, "masks", f"{key}-{n}.png")) > 0.05, iterations=4)
    rig = json.load(open(os.path.join(RIG, "rig.json")))
    import rig as R  # noqa: E402
    # where the arms were: the original arm footprints, leaned with the torso (upper body) or not (legs)
    H, W = 384, 256
    for poly in (R.NEAR_ARM, R.FAR_ARM):
        m = R.poly_mask(poly, (H, W)) & (src_a > 0)
        m = np.pad(m, ((0, 0), (PAD, PAD)))
        z |= ndimage.binary_dilation(m, iterations=3)
        lean = rig["frames"][key]["lean"]
        P = (R.PIVOT[0] + PAD, R.PIVOT[1])
        lean_m = np.asarray(Image.fromarray((m * 255).astype(np.uint8)).rotate(-lean, center=P, resample=Image.Resampling.BILINEAR)) > 20
        z |= ndimage.binary_dilation(lean_m, iterations=3)
    # the hip seam where the leaned torso meets the legs
    yy, xx = np.mgrid[0:384, 0:384]
    z |= (yy >= 150) & (yy <= 184) & (xx >= 90 + PAD - 20) & (xx <= 200 + PAD)
    return z


def main():
    import sys
    sys.path.insert(0, HERE)
    os.makedirs(os.path.join(J, "refs"), exist_ok=True)
    src = np.asarray(Image.open(SRC).convert("RGBA"))
    rig = json.load(open(os.path.join(RIG, "rig.json")))
    target = Image.new("RGB", (SZ, SZ), MAG)
    amap = Image.new("L", (SZ, SZ), 0)
    side = int(round(384 * K))
    panels = {}
    for key in ("A", "B"):
        fr = Image.open(os.path.join(RIG, f"frame-{key}.png")).convert("RGBA")
        bg = Image.new("RGBA", fr.size, MAG + (255,))
        bg.alpha_composite(fr)
        d = ImageDraw.Draw(bg)
        hx, hy = rig["hub"][0] + PAD, rig["hub"][1]
        r = rig["rim"]
        d.ellipse([hx - r, hy - r, hx + r, hy + r], outline=(0, 255, 255, 255), width=1)
        big = bg.convert("RGB").resize((side, side), Image.Resampling.LANCZOS)
        target.paste(big, AT[key])
        z = zones(key, src[..., 3])
        zi = Image.fromarray((z * 255).astype(np.uint8)).resize((side, side), Image.Resampling.NEAREST)
        amap.paste(zi, AT[key])
        panels[key] = {"at": AT[key], "px": side, "scale": K, "frame": 384}
    target.save(os.path.join(J, "refs", "1-edit-target-crank.png"))
    amap.convert("RGB").save(os.path.join(J, "refs", "2-areas-to-paint.png"))
    ref = Image.new("RGBA", (256, 384), MAG + (255,))
    ref.alpha_composite(Image.fromarray(src, "RGBA"))
    ref.convert("RGB").resize((512, 768), Image.Resampling.LANCZOS).save(os.path.join(J, "refs", "3-reference-character.png"))
    json.dump({"size": SZ, "panels": panels, "magenta": MAG}, open(os.path.join(J, "panels.json"), "w"), indent=1)
    print(json.dumps(panels))


if __name__ == "__main__":
    main()
