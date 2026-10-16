"""Mock frames: round 6's s3 capture (before) and the same frame with the disc removed, the relief
valve on the relay and the simulated jet (after). Mocks only; the real check is render.sh.
usage: mock.py <shape 720|phone> [frames]
"""
import json
import os
import sys

import numpy as np
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import jet_sim  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = "scratchpad/real-slice/shots/raw6/slice"
CAM = (604.444, 360.0)
OUTLET = (649.625, 361.0)
ART_ORIGIN = (561.625, 338.0)
SHAPES = {"720": (1280, 720, 1.8, "B-720"), "phone": (1920, 1080, 2.7, "B-phone")}
LUM = np.array([0.299, 0.587, 0.114])


def w2s(wx, wy, scale, W, H):
    return ((wx - CAM[0]) * scale + W / 2, (wy - CAM[1]) * scale + H / 2)


def place_layer(frame, layer_path, scale, W, H):
    """Draws the valve layer (relay art px, 4 per world px) at its world place, like a Sprite2D
    with linear mipmaps (approximated by an area resample at a fine sub-pixel grid)."""
    lay = Image.open(layer_path).convert("RGBA")
    ox, oy = w2s(*ART_ORIGIN, scale, W, H)
    f = scale / 4.0
    # supersample 4x on the screen grid, then box-filter down
    k = 4
    big_w = int(round(lay.width * f * k)); big_h = int(round(lay.height * f * k))
    big = np.array(lay.resize((big_w, big_h), Image.BOX)).astype(float)
    # premultiply
    big[..., :3] *= big[..., 3:4] / 255.0
    fx0 = ox * k; fy0 = oy * k
    ix0 = int(np.floor(fx0)); iy0 = int(np.floor(fy0))
    canvas = np.zeros((H * k + k, W * k + k, 4))
    canvas[iy0:iy0 + big_h, ix0:ix0 + big_w] = big
    small = canvas[:H * k, :W * k].reshape(H, k, W, k, 4).mean(axis=(1, 3))
    a = small[..., 3:4] / 255.0
    frame[:] = small[..., :3] + frame * (1 - a)
    return frame


def main(shape, nframes=3):
    W, H, scale, run = SHAPES[shape]
    before = np.array(Image.open(os.path.join(RAW, run, "s3-bypass-crank-clean.png")).convert("RGB")).astype(float)
    base = np.array(Image.open(os.path.join(ROOT, "work", "s3-%s-nodisc.png" % shape)).convert("RGB")).astype(float)
    base = place_layer(base.copy(), os.path.join(ROOT, "layer", "relief-valve-layer.png"), scale, W, H)
    os.makedirs(os.path.join(ROOT, "mock"), exist_ok=True)
    Image.fromarray(np.clip(np.round(base), 0, 255).astype(np.uint8)).save(os.path.join(ROOT, "mock", "s3-%s-valve-nojet.png" % shape))
    p = jet_sim.P
    origin = w2s(*OUTLET, scale, W, H)
    stats = []
    for i in range(nframes):
        parts = jet_sim.simulate(p, seconds=1.5 + i * 0.137, seed=11 + i)
        img = base.copy()
        A = jet_sim.render(img, parts, p, origin, scale)
        Image.fromarray(np.clip(np.round(img), 0, 255).astype(np.uint8)).save(os.path.join(ROOT, "mock", "s3-%s-after-%d.png" % (shape, i)))
        lift = img @ LUM - base @ LUM
        vis = A > 0.04
        ys, xs = np.where(vis)
        st = {
            "frame": i,
            "peak_luma": float((img @ LUM)[vis].max()) if vis.any() else 0,
            "peak_lift": float(lift.max()),
            "mean_lift_in_jet": float(lift[vis].mean()) if vis.any() else 0,
            "peak_alpha": float(A.max()),
            "visible_px": int(vis.sum()),
            "visible_length_world": float((ys.max() - origin[1]) / scale) if vis.any() else 0,
            "visible_width_world": float((xs.max() - xs.min() + 1) / scale) if vis.any() else 0,
            "right_edge_world": float(CAM[0] + (xs.max() + 1 - W / 2) / scale) if vis.any() else 0,
            "left_edge_world": float(CAM[0] + (xs.min() - W / 2) / scale) if vis.any() else 0,
        }
        stats.append(st)
    before_peak = float((before @ LUM)[int(origin[1]) - int(30 * scale):int(origin[1]) + int(60 * scale), int(origin[0]) - int(40 * scale):int(origin[0]) + int(20 * scale)].max())
    rep = {"shape": shape, "params": p, "outlet_screen": origin, "frames": stats, "before_peak_luma_near_relay": before_peak}
    with open(os.path.join(ROOT, "mock", "stats-%s.json" % shape), "w") as f:
        json.dump(rep, f, indent=1)
    print(json.dumps(stats, indent=1))


if __name__ == "__main__":
    main(sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 3)
