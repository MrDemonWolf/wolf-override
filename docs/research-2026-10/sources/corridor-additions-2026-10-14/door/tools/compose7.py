"""Round 7 previews of the corridor's door end, composed in Python the way the game layers it (no
Godot, no window): far plate (parallax at the right clamp), mid plate, the wall piece, the inner
blast leaf mesh (leafmesh.py), the roller curtain (shut, rising as SealLeaf draws it, or the tucked
bar), the frame, then the near column, camera and stub. These are construction previews of the
layer files, not in-game captures.

usage: compose7.py <layers dir> <out prefix> [o values...]
  layers dir holds portal-wall.png, portal-front.png (CVD canvas), portal-curtain.png,
  portal-curtain-open.png, portal-frame.png (v2 canvas), corridor-far.png, corridor-mid.png,
  leaf-front.png, leaf-edge.png (elevations at EL_PPM, optional).
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
from stack import common, p2, p3  # noqa: E402
import portal7 as d7  # noqa: E402
import leafmesh  # noqa: E402

X0, Y0, X1, Y1, PPW = 676.0, 150.0, 860.0, 480.0, 4.0
W, H = int((X1 - X0) * PPW), int((Y1 - Y0) * PPW)
GAME_PPW = 1.8  # 1280x720 at zoom 1.35


def load(p):
    return np.asarray(Image.open(p).convert("RGBA")).astype(np.float64) / 255.0


def over(dst, src):
    a = src[..., 3:4]
    dst[..., :3] = src[..., :3] * a + dst[..., :3] * (1 - a)
    dst[..., 3:4] = a + dst[..., 3:4] * (1 - a)


def sample(img, fx, fy):
    return np.stack([ndimage.map_coordinates(img[..., c], [fy, fx], order=1, mode="constant", cval=0.0) for c in range(img.shape[2])], -1)


def grid():
    yy, xx = np.mgrid[0:H, 0:W].astype(float)
    return X0 + (xx + 0.5) / PPW, Y0 + (yy + 0.5) / PPW


def on_canvas(img, cx0, cy0, ppw):
    X, Y = grid()
    return sample(img, (X - cx0) * ppw - 0.5, (Y - cy0) * ppw - 0.5)


def plane_coords(plane):
    A, B = p2.rays(common.Canvas("prev", X0, Y0, PPW, W, H))
    nb = (B * plane.n).sum(-1)
    tt = ((plane.o - A) * plane.n).sum() / np.where(np.abs(nb) < 1e-9, 1e-9, nb)
    P = A + B * tt[..., None]
    rel = P - plane.o
    return (rel * plane.e1).sum(-1), (rel * plane.e2).sum(-1)


def leaf_layer(o, front_tex, edge_tex, spec):
    """The leaf at open value o, exact perspective (the game's mesh is this, piecewise affine)."""
    out = np.zeros((H, W, 4))
    al = leafmesh.a_lead(o)
    la, lb = plane_coords(p2.face_plane(d7.T_LF))
    vis = (la >= al) & (la <= d7.A_F) & (lb >= 0) & (lb <= d7.H_OPEN)
    ppm = d7.EL_PPM
    u = (la - al) * ppm - 0.5
    v = (d7.LEAF_H - lb) * ppm - 0.5
    col = sample(front_tex, u, v)
    lt = np.vectorize(lambda a, h: leafmesh.light_front(a, h, spec))(np.clip(la, d7.A_LEAD_SHUT, d7.A_F), np.clip(lb, 0, d7.H_OPEN))
    col[..., :3] *= lt[..., None]
    col[..., 3] = vis * 1.0
    over(out, col)
    ta, tb = plane_coords(p2.side_plane(al))
    vis = (ta >= d7.T_LF) & (ta <= d7.T_LB) & (tb >= 0) & (tb <= d7.H_OPEN)
    col = sample(edge_tex, (ta - d7.T_LF) * ppm - 0.5, (d7.LEAF_H - tb) * ppm - 0.5)
    col[..., :3] *= leafmesh.edge_light(o)
    col[..., 3] = vis * 1.0
    over(out, col)
    return out


def curtain_rising(curt, lift):
    """SealLeaf: a point h up on the curtain plane shows the art from h - lift."""
    la, lb = plane_coords(p2.face_plane(p2.CURT_T))
    src_h = lb - lift
    X, Y = np.zeros_like(la), np.zeros_like(la)
    P = p2.O[None, None, :] + la[..., None] * p2.U + src_h[..., None] * p2.EY + p2.CURT_T * p2.N
    s = common.D0 / (common.D0 + P[..., 2])
    X = common.VPX + (P[..., 0] * common.PX_PER_M - common.VPX) * s
    Y = common.HORIZON + (common.FLOOR_Y - common.HORIZON) * s - src_h * common.PX_PER_M * s
    img = sample(curt, (X - 680.0) * 4.0 - 0.5, (Y - 150.0) * 4.0 - 0.5)
    img[..., 3] *= (lb >= lift) & (lb <= 3.07)
    return img


def compose(L, o, show_leaf=True):
    spec = json.load(open(os.path.join(os.path.dirname(__file__), "..", "design", "spec.json")))
    out = np.zeros((H, W, 4))
    far = load(os.path.join(L, "corridor-far.png"))
    X, Y = grid()
    out = sample(far, (X - common.FAR_SHIFT) * 2 - 0.5, (Y - 78.5) * 2 - 0.5)
    out[..., 3] = 1
    over(out, sample(load(os.path.join(L, "corridor-mid.png")), X * 2 - 0.5, (Y - 51.5) * 2 - 0.5))
    over(out, on_canvas(load(os.path.join(L, "portal-wall.png")), 676.0, 150.0, 4.0))
    lf, le = os.path.join(L, "leaf-front.png"), os.path.join(L, "leaf-edge.png")
    if show_leaf and 0.0 < o < 1.0 and os.path.exists(lf):
        over(out, leaf_layer(o, load(lf), load(le), spec))
    if o <= 0.0:
        over(out, on_canvas(load(os.path.join(L, "portal-curtain.png")), 680.0, 150.0, 4.0))
    elif o < 1.0:
        over(out, curtain_rising(load(os.path.join(L, "portal-curtain.png")), o * 2.935))
    else:
        over(out, on_canvas(load(os.path.join(L, "portal-curtain-open.png")), 680.0, 150.0, 4.0))
    over(out, on_canvas(load(os.path.join(L, "portal-frame.png")), 680.0, 150.0, 4.0))
    front = load(os.path.join(L, "portal-front.png"))
    frame_cvd = np.zeros_like(front)
    fr = load(os.path.join(L, "portal-frame.png"))
    frame_cvd[:fr.shape[0], 16:16 + fr.shape[1]] = fr
    front[..., 3] *= 1.0 - np.clip(frame_cvd[..., 3] * 1.5, 0, 1)
    over(out, on_canvas(front, 676.0, 150.0, 4.0))
    return out


def save(img, path, scale=1.0):
    im = Image.fromarray((np.clip(img[..., :3], 0, 1) * 255 + 0.5).astype(np.uint8), "RGB")
    if scale != 1.0:
        im = im.resize((int(round(im.width * scale)), int(round(im.height * scale))), Image.Resampling.LANCZOS)
    im.save(path)


def main():
    L, pre = sys.argv[1], sys.argv[2]
    os_ = [float(v) for v in sys.argv[3:]] or [0.0, 0.55, 0.75, 1.0]
    for o in os_:
        img = compose(L, o)
        save(img, f"{pre}-o{o:.2f}-4x.png")
        save(img, f"{pre}-o{o:.2f}-game.png", GAME_PPW / PPW)


if __name__ == "__main__":
    main()
