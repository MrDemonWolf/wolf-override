"""Round 11: the beacon pulse strips (route P, add7/fix4/driver-pulse; render.sh, 1280x720, HUD hidden): 60
frames 2 game frames apart (1/30 s at the fixed 60 fps, 2.0 s) at s1's moment and camera, for round 10 (add7/fix4/work/r10-game,
raw11/r10/P-720) and round 11 (raw11/add/P-720), with the glow alpha and lens colour the game reports.

Per frame and beacon:
  glass_R    the mean red of the globe's glass: the pixels within 5 px of the globe's centre that are
             lit red glass in the strip's per-pixel brightest image (R > 120, R - G > 60); the halo
             round the globe is left out, but the lamp's own additive light over its glass is in it;
             glass_top12_R is the mean of the 12 reddest px within 7 px (the real review r4's measure)
  light      the mean red excess R - (G + B) / 2 over a 52 x 60 px box under the globe (the wall the
             lamp lights; round 10's measure), the glass left out; light_round is the same over a
             120 x 110 px box round the globe
Then per beacon: glass trough / peak, the Pearson r of glass_R against light over the 60 frames, the
light's swing, and the flashes a minute (rises through the middle of the light's swing).
The real review r4's check: glass at the trough at most half its peak, in phase with the light (r >= 0.9).

Writes add7/shots/pulse.json and crops p-beacon-pulse-<side>-2x.png (round 10 above round 11, frames
0-19 = one 0.67 s stretch) and p-beacon-curves.png (glass and light per frame)."""
import json
import os

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

S = "scratchpad/real-slice/add7/shots"
RUNS = {"round10": os.path.join(S, "raw11", "r10", "P-720"), "round11": os.path.join(S, "raw11", "add", "P-720")}
N = 60


def frames(d):
    return [np.asarray(Image.open(os.path.join(d, f"p{i:02d}.png")).convert("RGB")).astype(float) for i in range(N)]


def globes(im):
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    lab, n = ndimage.label((r > 110) & (r - g > 60) & (r - b > 60))
    cents = []
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        if len(xs) >= 4 and ys.mean() < 260 and all(abs(xs.mean() - c[0]) > 30 for c in cents):
            cents.append((xs.mean(), ys.mean()))
    return sorted(cents)[:2]


def pearson(a, b):
    a, b = np.asarray(a, float), np.asarray(b, float)
    a, b = a - a.mean(), b - b.mean()
    return float((a * b).sum() / max(np.sqrt((a * a).sum() * (b * b).sum()), 1e-9))


def per_minute(series, fps=30.0):
    v = np.asarray(series, float)
    mid = (v.min() + v.max()) / 2
    rises = [i for i in range(1, len(v)) if v[i - 1] < mid <= v[i]]
    if len(rises) < 2:
        return None, rises
    return round(60.0 * (len(rises) - 1) / ((rises[-1] - rises[0]) / fps), 1), rises


def main():
    data = {tag: frames(d) for tag, d in RUNS.items()}
    # anchors and glass masks from the per-pixel brightest of round 11's 60 frames (the two lamps
    # flash out of step, so no single frame has both at their top; both copies share s1's camera)
    ref = np.max(np.stack(data["round11"]), 0)
    anchors = globes(ref)
    assert len(anchors) == 2, anchors
    masks = []
    H, W = ref.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W]
    for gx, gy in anchors:
        near = np.hypot(xx - gx, yy - gy) <= 5
        lit = (ref[..., 0] > 120) & (ref[..., 0] - ref[..., 1] > 60)
        masks.append(near & lit)
    out = {"anchors_screen": [[round(x, 1), round(y, 1)] for x, y in anchors], "glass_px": [int(m.sum()) for m in masks], "sampling": "60 frames, 2 game frames apart (1/30 s), 2.0 s", "copies": {}}
    curves = {}
    for tag, ims in data.items():
        runj = json.load(open(os.path.join(RUNS[tag], "_run.json")))
        rows = []
        for i, im in enumerate(ims):
            sh = runj["shots"][i]
            row = {"frame": sh["frame"], "glow_alpha": [round(a, 3) for a in sh.get("glow_alpha", [])], "lens_r": [round(l[0], 3) for l in sh.get("lens", [])]}
            for side, (gx, gy), m in zip(("left", "right"), anchors, masks):
                box = np.zeros((H, W), bool)
                box[int(gy - 50):int(gy + 60), int(gx - 60):int(gx + 60)] = True
                box &= ~ndimage.binary_dilation(m, iterations=2)
                ex = im[..., 0] - (im[..., 1] + im[..., 2]) / 2
                below = np.zeros((H, W), bool)
                below[int(gy + 8):int(gy + 68), int(gx - 26):int(gx + 26)] = True
                below &= ~ndimage.binary_dilation(m, iterations=2)
                near = np.hypot(xx - gx, yy - gy) <= 7
                top12 = np.sort(im[..., 0][near])[-12:]
                row[side] = {"glass_R": round(float(im[..., 0][m].mean()), 2), "glass_top12_R": round(float(top12.mean()), 2), "light": round(float(ex[below].mean()), 2), "light_round": round(float(ex[box].mean()), 2)}
            rows.append(row)
        summ = {}
        for side in ("left", "right"):
            gR = [r[side]["glass_R"] for r in rows]
            g12 = [r[side]["glass_top12_R"] for r in rows]
            li = [r[side]["light"] for r in rows]
            fpm, rises = per_minute(li)
            summ[side] = {"glass_R_min": min(gR), "glass_R_max": max(gR), "glass_trough_over_peak": round(min(gR) / max(gR), 3),
                          "top12_R_min": min(g12), "top12_R_max": max(g12), "top12_trough_over_peak": round(min(g12) / max(g12), 3), "pearson_top12_vs_light": round(pearson(g12, li), 3),
                          "light_min": min(li), "light_max": max(li), "light_swing": round(max(li) - min(li), 2),
                          "pearson_glass_vs_light": round(pearson(gR, li), 3), "flashes_per_minute_from_light": fpm, "rises_at_frames": rises}
            curves[(tag, side)] = (gR, li)
        out["copies"][tag] = {"summary": summ, "frames": rows}
    # strips: frames 0-19 (0.67 s), two rows of 10 per copy, 2x
    for side, (gx, gy) in zip(("left", "right"), anchors):
        tiles = []
        for tag in RUNS:
            row_imgs = []
            for half in (0, 1):
                seq = [data[tag][i][int(gy - 50):int(gy + 60), int(gx - 45):int(gx + 45)].astype(np.uint8) for i in range(half * 10, half * 10 + 10)]
                row_imgs.append(np.concatenate([np.pad(t, ((0, 0), (0, 2), (0, 0)), constant_values=255) for t in seq], 1))
            block = np.concatenate([row_imgs[0], np.full((2, row_imgs[0].shape[1], 3), 255, np.uint8), row_imgs[1]], 0)
            t = Image.fromarray(block).resize((block.shape[1] * 2, block.shape[0] * 2), Image.NEAREST)
            d = ImageDraw.Draw(t)
            d.rectangle([0, 0, 700, 14], fill=(0, 0, 0))
            d.text((3, 2), f"{tag}: {side} beacon, frames 0-19, 1/30 s apart (0.67 s), 2x", fill=(230, 230, 230))
            tiles.append(t)
        sheet = Image.new("RGB", (tiles[0].width, sum(t.height for t in tiles) + 6), (255, 0, 255))
        sheet.paste(tiles[0], (0, 0))
        sheet.paste(tiles[1], (0, tiles[0].height + 6))
        sheet.save(os.path.join(S, "crops", f"p-beacon-pulse-{side}-2x.png"))
    # curves
    Wc, Hc, pad = 900, 200, 40
    img = Image.new("RGB", (Wc + 2 * pad, 4 * (Hc + pad) + pad), (16, 18, 20))
    d = ImageDraw.Draw(img)
    for k, ((tag, side), (gR, li)) in enumerate(curves.items()):
        y0 = pad + k * (Hc + pad)
        d.rectangle([pad, y0, pad + Wc, y0 + Hc], outline=(80, 80, 80))
        d.text((pad, y0 - 14), f"{tag} {side}: glass mean R (red) and light red excess (white, scaled), 60 frames at 1/30 s", fill=(220, 220, 220))
        for series, colr, lo, hi in ((gR, (255, 80, 70), 0.0, 255.0), (li, (230, 230, 230), min(li) - 1, max(li) + 1)):
            pts = [(pad + i * Wc / (N - 1), y0 + Hc - (v - lo) / (hi - lo) * Hc) for i, v in enumerate(series)]
            d.line(pts, fill=colr, width=2)
    img.save(os.path.join(S, "crops", "p-beacon-curves.png"))
    json.dump(out, open(os.path.join(S, "pulse.json"), "w"), indent=1)
    print(json.dumps({"anchors": out["anchors_screen"], "glass_px": out["glass_px"], **{t: c["summary"] for t, c in out["copies"].items()}}, indent=1))


if __name__ == "__main__":
    main()
