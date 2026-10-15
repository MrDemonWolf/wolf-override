"""Records doors: flat-shaded design previews of each door end in the room's real plates (far plate
at the camera clamp's parallax, mid plate), with the leaf at a given swing angle and the engineer
(the provisional Look 2 sprite at the game's scale) for scale. Usage: compose.py <srcdir> [tag]
where <srcdir> holds the layer PNGs to preview (design/ or layers/). Scratch only."""
from __future__ import annotations

import math
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rmodel as M  # noqa: E402
import rdesign as RD  # noqa: E402

GAME = os.path.join(M.TRACK, "..", "main-records", "apps", "game")
PPW = 4.0


def find_coeffs(dst, src):
    """PIL perspective coefficients mapping output (dst) points to input (src) points."""
    A = []
    for (x, y), (u, v) in zip(dst, src):
        A.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        A.append([0, 0, 0, x, y, 1, -v * x, -v * y])
    A = np.array(A, float)
    B = np.array([c for p in src for c in p], float)
    return np.linalg.solve(A, B)


def place_leaf(canvas_img, x0, y0, door, theta, faces_dir, out_face):
    """Draws the leaf's visible face (room face while it shows, else the outside face) warped onto
    its swing position, with the leaf's per-vertex light (here: a flat factor from rmodel.shade at
    its centre, enough for a preview)."""
    room_n = door.leaf_normal_room(theta)
    use_room = room_n[2] < 0
    face = "room" if use_room else out_face
    fp = os.path.join(faces_dir, f"clean-{face}.png")
    tex = Image.open(fp if os.path.exists(fp) else os.path.join(faces_dir, f"design-{face}.png")).convert("RGBA")
    corners = door.leaf_corners(theta, "room" if use_room else "out")
    pts = [M.scr(c) for c in corners]
    W, H = tex.size
    # hinge-bottom, free-bottom, free-top, hinge-top in texture px (u right, v up)
    src = [(0, H), (W, H), (W, 0), (0, 0)]
    if not use_room:
        src = [(0, H), (W, H), (W, 0), (0, 0)]
    dst = [((x - x0) * PPW, (y - y0) * PPW) for x, y in pts]
    coeffs = find_coeffs(dst, src)
    warped = tex.transform(canvas_img.size, Image.Transform.PERSPECTIVE, coeffs, Image.Resampling.BICUBIC)
    # light: shade at the leaf centre vs the reference exposure
    _, lamps, _, _ = RD.lamps_for(door.side)
    c = sum(corners) / 4
    n = room_n if use_room else -room_n
    L = M.shade(c[None, :], n[None, :], lamps)[0]
    k = float(np.clip(M.to_srgb_u8(np.array(M.GUNSHIP) * L).mean() / max(M.to_srgb_u8(np.array(M.GUNSHIP)).mean(), 1), 0.15, 1.2))
    arr = np.asarray(warped).astype(np.float64)
    arr[..., :3] *= k
    # mask to the quad (transform fills outside with transparent already)
    canvas_img.alpha_composite(Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA"))


def compose(srcdir, tag, side, theta_deg, out_path, wall_name="design-wall.png", front_name="design-front.png", beyond_name="design-beyond.png", faces_dir=None, container_img=None, far_override=None, mid_override=None):
    piece = "exit" if side > 0 else "entry"
    door = M.DoorEnd(side, RD.XC if side > 0 else RD.XE)
    x0, y0 = (700.0, 140.0) if side > 0 else (-20.0, 140.0)
    w, h = 280, 360
    img = Image.new("RGBA", (int(w * PPW), int(h * PPW)), (0, 0, 0, 255))
    far = Image.open(far_override or os.path.join(GAME, "assets", "rooms", "records-far.png")).convert("RGBA")
    shift = RD.FAR_SHIFT_RIGHT if side > 0 else RD.FAR_SHIFT_LEFT
    # far plate: world X = sx / 2 + shift, Y = sy / 2 + 69
    fx0, fy0 = (x0 - shift) * 2, (y0 - 69.0) * 2
    crop = far.crop((int(fx0), int(fy0), int(fx0 + w * 2), int(fy0 + h * 2))).resize(img.size, Image.Resampling.BICUBIC)
    img.alpha_composite(crop)
    by = os.path.join(srcdir, piece, beyond_name)
    if far_override is None and os.path.exists(by):
        b = Image.open(by).convert("RGBA")
        img.alpha_composite(b, (int((door_cv_x0(side) - x0) * PPW), int((140.0 - y0) * PPW)))
    mid = Image.open(mid_override or os.path.join(GAME, "assets", "rooms", "records-mid.png")).convert("RGBA")
    mx0, my0 = x0 * 2, (y0 - 69.0) * 2
    mcrop = mid.crop((int(mx0), int(my0), int(mx0 + w * 2), int(my0 + h * 2))).resize(img.size, Image.Resampling.BICUBIC)
    if mid_override is None:
        # preview of the mid-plate erasures (the real ones are made by the install step)
        a = np.asarray(mcrop).copy()
        X = x0 + (np.arange(a.shape[1]) + 0.5) / PPW
        Y = y0 + (np.arange(a.shape[0]) + 0.5) / PPW
        XX, YY = np.meshgrid(X, Y)
        erase = ((YY >= 166.0) & ((XX >= 792.5) | (XX < 160.5))) | (XX >= 905.0) | (XX < 56.0)
        a[..., 3] = np.where(erase, 0, a[..., 3])
        mcrop = Image.fromarray(a, "RGBA")
    img.alpha_composite(mcrop)
    wl = Image.open(os.path.join(srcdir, piece, wall_name)).convert("RGBA")
    img.alpha_composite(wl, (int((door_cv_x0(side) - x0) * PPW), int((140.0 - y0) * PPW)))
    if container_img is not None and side > 0:
        ci, cx0, cy0 = container_img
        img.alpha_composite(ci, (int((cx0 - x0) * PPW), int((cy0 - y0) * PPW)))
    place_leaf(img, x0, y0, door, math.radians(theta_deg), faces_dir or os.path.join(M.DESIGN, "leaf"), "out-exit" if side > 0 else "out-entry")
    # the engineer for scale, standing at the door stop (exit) or at the room's entry point
    eng = Image.open(os.path.join(GAME, "assets", "rowan-side-right-provisional.png")).convert("RGBA")
    bbox = eng.getbbox()
    eng = eng.crop(bbox)
    sc = 69.6 * PPW / eng.size[1]
    eng = eng.resize((int(eng.size[0] * sc), int(eng.size[1] * sc)), Image.Resampling.BICUBIC)
    ex = 861.0 if side > 0 else 128.0
    img.alpha_composite(eng, (int((ex - x0) * PPW - eng.size[0] / 2), int((440.0 - y0) * PPW - eng.size[1])))
    fr = Image.open(os.path.join(srcdir, piece, front_name)).convert("RGBA")
    img.alpha_composite(fr, (int((door_cv_x0(side) - x0) * PPW), int((140.0 - y0) * PPW)))
    img.convert("RGB").save(out_path)


def door_cv_x0(side):
    return 770.0 if side > 0 else -40.0


if __name__ == "__main__":
    src = sys.argv[1] if len(sys.argv) > 1 else M.DESIGN
    tag = sys.argv[2] if len(sys.argv) > 2 else "design"
    outd = os.path.join(M.TRACK, "previews")
    os.makedirs(outd, exist_ok=True)
    cont = Image.open(os.path.join(M.DESIGN, "container", "design-container.png")).convert("RGBA")
    cspec = __import__("json").load(open(os.path.join(M.DESIGN, "container", "spec.json")))
    for side in (1, -1):
        for th in (0, 45, 90):
            compose(src, tag, side, th, os.path.join(outd, f"{tag}-{'exit' if side > 0 else 'entry'}-{th:02d}.png"),
                    container_img=(cont, cspec["canvas"]["x0"], cspec["canvas"]["y0"]))
    print("ok")
