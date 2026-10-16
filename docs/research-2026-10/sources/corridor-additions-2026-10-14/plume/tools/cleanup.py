"""Cleanup of the Codex paint for the relief valve (deterministic).

1. Resample a COPY of the tool's 1254x1254 output to the 1024 frame (the original stays as it is).
2. Register it to the edit target on the locked relay pixels (sub-pixel shift search).
3. Take the crop back to the relay art's resolution by area averaging (8 -> 1).
4. Keep only the designed shapes: alpha is the exact coverage from design/parts.npz; nothing
   outside the masks is used, so no silhouette can move.
5. Values: the steel keeps the paint's values (they sit at the relay pipe's own mean, ~70); the
   bronze comes down 8% and loses 35% of its saturation, to a dull, oxidised cast bronze under the
   corridor's cold light (the paint read slightly gold).
6. Merge into the relay art (straight-alpha 'over'); every relay pixel outside the fitting's mask is
   left byte-identical (checked).
Outputs: layer/relief-valve-layer.png (RGBA, relay canvas size, fitting only),
         layer/corridor-coolant-relay.png (the relay with the valve; drop-in for the game),
         layer/cleanup-report.json, layer/check-8x.png
"""
import json
import os

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAME = "scratchpad/real-slice/game-slice/apps/game"
RELAY = os.path.join(GAME, "assets/props/corridor-coolant-relay.png")
JOB = os.path.join(ROOT, "codex", "paint-relief")
OUT = os.path.join(ROOT, "layer")
CROP = (260, 40, 368, 140)
S = 8
OFF = (80, 112)
LUM = np.array([0.299, 0.587, 0.114])


def main():
    os.makedirs(OUT, exist_ok=True)
    target = np.array(Image.open(os.path.join(JOB, "refs", "1-edit-target-relief-valve.png")).convert("RGB")).astype(float)
    painted_img = Image.open(os.path.join(JOB, "out", "relief-valve-painted.png")).convert("RGB")
    painted = np.array(painted_img.resize((1024, 1024), Image.LANCZOS)).astype(float)
    area = np.array(Image.open(os.path.join(JOB, "refs", "2-areas-to-paint.png"))) > 127
    # registration on the locked relay pixels near the valve
    lock = ~ndimage.binary_dilation(area, iterations=12)
    win = np.zeros_like(lock); win[150:900, 90:700] = True
    lock &= win
    tl = target @ LUM
    best = (1e18, 0.0, 0.0)
    for dy in np.arange(-6, 6.01, 0.5):
        for dx in np.arange(-6, 6.01, 0.5):
            sh = ndimage.shift(painted @ LUM, (dy, dx), order=1, mode="nearest")
            err = float(np.mean((sh[lock] - tl[lock]) ** 2))
            if err < best[0]:
                best = (err, dy, dx)
    err, dy, dx = best
    reg = np.stack([ndimage.shift(painted[..., c], (dy, dx), order=1, mode="nearest") for c in range(3)], -1)
    h = (CROP[3] - CROP[1]) * S; w = (CROP[2] - CROP[0]) * S
    crop = reg[OFF[1]:OFF[1] + h, OFF[0]:OFF[0] + w]
    art = crop.reshape(h // S, S, w // S, S, 3).mean(axis=(1, 3))

    parts = np.load(os.path.join(ROOT, "design", "parts.npz"))
    relay = np.array(Image.open(RELAY).convert("RGBA")).astype(float)
    flat = np.array(Image.open(os.path.join(ROOT, "design", "fitting-flat.png")).convert("RGBA")).astype(float)
    H, W = relay.shape[:2]
    full = np.zeros((H, W, 3)); full[CROP[1]:CROP[3], CROP[0]:CROP[2]] = art
    cov_all = parts["all"]

    # value plan per part group: match mean luma to the construction
    groups = {"bronze": ["body", "outlet", "bonnet", "cap"],
              "steel": ["boss", "weld", "hex", "outlet_hex", "lever", "pivot", "nipple", "union", "elbow", "tail", "tail_lip"]}
    out_rgb = full.copy()
    report = {"registration_shift_px_1024": [float(dx), float(dy)], "registration_rmse": float(np.sqrt(err))}
    for g, names in groups.items():
        m = np.zeros((H, W), bool)
        for n in names:
            m |= parts[n] >= 0.5
        m &= cov_all >= 0.99
        lp = (full[m] @ LUM).mean(); lc = (flat[..., :3][m] @ LUM).mean()
        # the construction's flat plan came out darker than the relay's own pipe (mean ~70 with
        # highlights near 190); the paint's steel sits at the big pipe's values, so steel keeps the
        # paint's values and the bronze comes down a little, toward a dull cast bronze
        gain = {"steel": 1.0, "bronze": 0.92}[g]
        col = full * gain
        if g == "bronze":
            # dull it: pull 35% toward its own grey and cool it slightly under the corridor light
            grey = (col @ LUM)[..., None]
            col = grey + (col - grey) * 0.65
            col = col * np.array([0.98, 1.0, 1.03])
        sel = np.zeros((H, W), bool)
        for n in names:
            sel |= parts[n] > 0
        out_rgb[sel] = col[sel]
        report[g] = {"paint_mean_luma": float(lp), "construction_mean_luma": float(lc), "gain": float(gain)}
    out_rgb = np.clip(out_rgb, 0, 255)

    a = cov_all
    layer = np.dstack([out_rgb, a * 255.0])
    layer[a <= 0] = 0
    Image.fromarray(np.clip(np.round(layer), 0, 255).astype(np.uint8), "RGBA").save(os.path.join(OUT, "relief-valve-layer.png"))
    da = relay[..., 3] / 255.0
    oa = a + da * (1 - a)
    oc = (out_rgb * a[..., None] + relay[..., :3] * (da * (1 - a))[..., None]) / np.maximum(oa, 1e-6)[..., None]
    merged = np.dstack([oc, oa * 255.0])
    merged = np.clip(np.round(merged), 0, 255).astype(np.uint8)
    orig = relay.astype(np.uint8)
    untouched = a <= 0
    merged[untouched] = orig[untouched]
    Image.fromarray(merged, "RGBA").save(os.path.join(OUT, "corridor-coolant-relay.png"), optimize=True)
    changed = np.any(merged != orig, axis=2)
    report["relay_px_changed"] = int(changed.sum())
    report["relay_px_changed_outside_mask"] = int((changed & untouched).sum())
    ys, xs = np.where(changed)
    report["changed_bbox_art"] = [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]
    with open(os.path.join(OUT, "cleanup-report.json"), "w") as f:
        json.dump(report, f, indent=1)
    c = Image.fromarray(merged, "RGBA").crop((270, 40, 368, 140))
    bg = Image.new("RGBA", c.size, (36, 38, 42, 255)); bg.alpha_composite(c)
    bg.resize((c.width * 8, c.height * 8), Image.NEAREST).save(os.path.join(OUT, "check-8x.png"))
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
