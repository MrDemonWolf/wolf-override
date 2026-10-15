"""Round 10: the beacon pulse strip (route P, add7/fix3/driver-pulse; render.sh, 1280x720, HUD hidden):
16 frames 10 frames apart at s1's moment, for main, round 9 (add7/fix3/work/r9-game) and round 10.
Per frame and beacon: the mean red excess (R - (G+B)/2) in a 52x60 px box under the globe and in a
120x110 px box round it, the globe's brightest red, and the glow alpha the game reports. The swing
(max - min over the strip) is what a player sees the alarm do; a still shows one phase only.
Writes add7/shots/pulse.json and crops p-beacon-pulse-<side>-3x.png (rows: round 9, round 10)."""
import json
import os

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

S = "scratchpad/real-slice/add7/shots"
RUNS = {"main": os.path.join(S, "raw10", "main", "P-720"), "round9": os.path.join(S, "raw10", "r9", "P-720"), "round10": os.path.join(S, "raw10", "add", "P-720")}


def globes(im):
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    lab, n = ndimage.label((r > 110) & (r - g > 60) & (r - b > 60))
    cents = []
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        if len(xs) >= 4 and ys.mean() < 260 and all(abs(xs.mean() - c[0]) > 30 for c in cents):
            cents.append((xs.mean(), ys.mean()))
    return sorted(cents)[:2]


def main():
    ref = np.asarray(Image.open(os.path.join(RUNS["round10"], "p00.png")).convert("RGB")).astype(float)
    # anchors from the brightest round-10 frame (all three copies share s1's camera)
    best = None
    for i in range(16):
        im = np.asarray(Image.open(os.path.join(RUNS["round10"], f"p{i:02d}.png")).convert("RGB")).astype(float)
        c = globes(im)
        if len(c) == 2 and (best is None or im[..., 0].sum() > best[0]):
            best = (im[..., 0].sum(), c)
    anchors = best[1]
    out = {"anchors_screen": [[round(x, 1), round(y, 1)] for x, y in anchors], "copies": {}}
    strips = {}
    for tag, d in RUNS.items():
        runj = json.load(open(os.path.join(d, "_run.json")))
        rows = []
        for i in range(16):
            im = np.asarray(Image.open(os.path.join(d, f"p{i:02d}.png")).convert("RGB")).astype(float)
            row = {"frame": i * 10, "glow_alpha": [round(a, 3) for a in runj["shots"][i].get("glow_alpha", [])]}
            for side, (gx, gy) in zip(("left", "right"), anchors):
                below = im[int(gy + 8):int(gy + 68), int(gx - 26):int(gx + 26)]
                round_ = im[int(gy - 50):int(gy + 60), int(gx - 60):int(gx + 60)]
                glb = im[int(gy - 5):int(gy + 6), int(gx - 5):int(gx + 6)]
                row[side] = {"red_excess_below": round(float((below[..., 0] - (below[..., 1] + below[..., 2]) / 2).mean()), 2),
                             "red_excess_round": round(float((round_[..., 0] - (round_[..., 1] + round_[..., 2]) / 2).mean()), 2),
                             "globe_max_R": int(glb[..., 0].max())}
                strips.setdefault((tag, side), []).append(im[int(gy - 50):int(gy + 60), int(gx - 45):int(gx + 45)].astype(np.uint8))
            rows.append(row)
        summ = {}
        for side in ("left", "right"):
            v = [r[side]["red_excess_round"] for r in rows]
            b = [r[side]["red_excess_below"] for r in rows]
            summ[side] = {"round_min": min(v), "round_max": max(v), "round_swing": round(max(v) - min(v), 2), "below_min": min(b), "below_max": max(b), "below_swing": round(max(b) - min(b), 2)}
        out["copies"][tag] = {"summary": summ, "frames": rows}
    for side in ("left", "right"):
        tiles = []
        for tag in ("round9", "round10"):
            row = np.concatenate([np.pad(t, ((0, 0), (0, 2), (0, 0)), constant_values=255) for t in strips[(tag, side)]], 1)
            t = Image.fromarray(row).resize((row.shape[1] * 2, row.shape[0] * 2), Image.NEAREST)
            d = ImageDraw.Draw(t)
            d.rectangle([0, 0, 520, 14], fill=(0, 0, 0))
            d.text((3, 2), f"{tag}: {side} beacon, 16 frames 1/6 s apart (2.67 s), 2x", fill=(230, 230, 230))
            tiles.append(t)
        sheet = Image.new("RGB", (tiles[0].width, sum(t.height for t in tiles) + 6), (255, 0, 255))
        sheet.paste(tiles[0], (0, 0))
        sheet.paste(tiles[1], (0, tiles[0].height + 6))
        sheet.save(os.path.join(S, "crops", f"p-beacon-pulse-{side}-2x.png"))
    json.dump(out, open(os.path.join(S, "pulse.json"), "w"), indent=1)
    print(json.dumps({"anchors": out["anchors_screen"], **{t: c["summary"] for t, c in out["copies"].items()}}, indent=1))


if __name__ == "__main__":
    main()
