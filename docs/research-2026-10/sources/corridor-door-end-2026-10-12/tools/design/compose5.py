"""Fix round 4 (v5): compose4.py with the v5 front (the near guide's return closing the slit). Fix round 3 (v4): the door end's flat-shaded design render, from the construction layers only (no
paint): the far patch's design plate at the camera's right clamp, the v3 wall, frame and curtain
(unchanged), the v4 front (slim column, camera, stub, contact shadows) and the handwheel at its v4
hub, on the design canvas CVD (world x 676..984, y 150..625, 4 px per world px), shown at 2 px per
world px. Writes design/door-end-design-v4-closed.png and -open.png."""
from __future__ import annotations

import os

import numpy as np
from PIL import Image
from scipy import ndimage

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
D = os.path.join(R, "design")
X0, Y0, W, H, PPW = 676.0, 150.0, 1232, 1900, 4.0


def main() -> None:
    far = np.asarray(Image.open(os.path.join(D, "far-patch2", "far-plate-with-design.png")).convert("RGB")).astype(float)
    # the v4 tank head (cleanup4_far.py's geometry): the shell up to its rim at 5.2 m, a 0.27 m dished
    # head above it, 2.2 source px of top surface; the old open ellipse's top filled with the wall
    head = np.asarray(Image.open(os.path.join(D, "far-patch2", "masks", "tank_head.png")).convert("L")) > 128
    hy, hx = np.nonzero(head)
    cx, r, y_rim = (hx.min() + hx.max()) / 2.0, (hx.max() - hx.min() + 1) / 2.0, (hy.min() + hy.max()) / 2.0
    py, px = np.mgrid[0:808, 0:808].astype(float)
    u = (px + 0.5 - cx) / r
    w_top = np.sqrt(np.clip(1 - u ** 2, 0, 1))
    inside = np.abs(u) <= 1
    new_head = inside & (py + 0.5 >= y_rim - 19.5 * w_top) & (py + 0.5 <= y_rim + 2.2 * w_top)
    new_shell = inside & (py + 0.5 > y_rim + 2.2 * w_top) & (py <= hy.max() + 1)
    P = far[0:808, 1112:1920]
    wall_c = P[int(hy.min()) + 2, int(hx.min()) - 6].copy()
    shell_rows = P[int(hy.max()) + 3]
    head_c = P[int(y_rim) - 8, int(cx)].copy()
    P[head & ~new_head & ~new_shell] = wall_c
    for x in np.nonzero(new_shell.any(0))[0]:
        P[new_shell[:, x], x] = shell_rows[x]
    P[new_head] = head_c * 1.25
    yy, xx = np.mgrid[0:H, 0:W].astype(float)
    wx, wy = X0 + (xx + 0.5) / PPW, Y0 + (yy + 0.5) / PPW
    fx, fy = (wx - 12.444) * 2 - 0.5, (wy - 78.5) * 2 - 0.5
    base = np.stack([ndimage.map_coordinates(far[..., c], [fy, fx], order=1, mode="nearest") for c in range(3)], -1)
    base = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8)).convert("RGBA")
    sh = np.asarray(Image.open(os.path.join(D, "portal5", "masks", "front--contact_shadow.png")).convert("L"))
    shadow = Image.fromarray(np.dstack([np.full(sh.shape + (3,), (2, 4, 6), np.uint8), sh]), "RGBA")
    wheel = Image.open(os.path.join(D, "portal2", "design-wheel.png")).convert("RGBA")
    for state in ("closed", "open"):
        out = base.copy()
        out.alpha_composite(Image.open(os.path.join(D, "portal3", "design-wall.png")).convert("RGBA"))
        if state == "closed":
            out.alpha_composite(Image.open(os.path.join(D, "portal3", "design-curtain.png")).convert("RGBA"))
        out.alpha_composite(Image.open(os.path.join(D, "portal3", "design-frame.png")).convert("RGBA"))
        out.alpha_composite(wheel, (int(round((694.0 - X0) * PPW - 44)), int(round((400.0 - Y0) * PPW - 44))))
        out.alpha_composite(shadow)
        out.alpha_composite(Image.open(os.path.join(D, "portal5", "design-front.png")).convert("RGBA"))
        out.convert("RGB").resize((W // 2, H // 2), Image.Resampling.BOX).crop((0, 0, W // 2, 820)).save(os.path.join(D, f"door-end-design-v5-{state}.png"))
    print("written")


if __name__ == "__main__":
    main()
