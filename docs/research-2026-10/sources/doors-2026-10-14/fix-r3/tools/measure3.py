"""Fix round 2 (review r2, N3): one light logic per door end, measured the reviewer's way. Scratch only.

For each door end, in its render.sh frame: the cross-wall's face AT THE CORNER where it meets the room's
back wall, against that back wall in the same rows (world boxes: the wall box just on the cross-wall
side of the corner, the back-wall box just on the room side; light fittings, signs, pipes and machines
kept out of both). Linear luminance (Rec. 709 weights on linearised sRGB), the median per box; texture is
the standard deviation of a 3 px high-pass (luminance minus its 3 x 3 mean) over the box. Also the
approved corridor cross-wall (s5 frame) for scale.

usage: measure3.py FRAMES_DIR [label]   (FRAMES_DIR holds <slug>-clean.png and _run.json)
Prints a table and writes FRAMES_DIR/../walls-<label>.json."""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

# door end: (frame slug, [(rows y0, y1)], wall x range, back x range)  -- world coordinates
ENDS = {
    "records-exit": ("r04-copy-point", [(190.0, 250.0), (330.0, 372.0)], (812.0, 850.0), (685.0, 712.0)),
    "records-entry": ("r01-arrival", [(190.0, 250.0), (330.0, 372.0)], (95.0, 150.0), (250.0, 290.0)),
    "junction-entry": ("r11-entry-shut", [(150.0, 205.0), (250.0, 320.0)], (60.0, 118.0), (150.0, 300.0)),  # fix round 2: no plain wall right of this corner (machinery); the grade's box
    "junction-blast": ("j01-sealed", [(160.0, 230.0), (250.0, 320.0)], (424.0, 446.0), (395.0, 416.0)),
    "junction-exit": ("j08-exit-bolt", [(180.0, 215.0), (225.0, 280.0)], (876.0, 905.0), (835.0, 866.0)),
}
W709 = np.array([0.2126, 0.7152, 0.0722])


def lin_lum(path):
    a = np.asarray(Image.open(path).convert("RGB")).astype(np.float64) / 255.0
    lin = np.where(a <= 0.04045, a / 12.92, ((a + 0.055) / 1.055) ** 2.4)
    return (lin * W709).sum(-1)


def shot(frames, slug):
    d = json.load(open(os.path.join(frames, "_run.json")))
    for s in d["shots"]:
        if s["slug"] == slug:
            return s, d["size"]
    raise KeyError(slug)


def box_stats(L, s, size, xr, yr):
    sc, tx, ty = s["canvas"][0], s["canvas"][4], s["canvas"][5]
    k = size[0] / 960.0
    x0, x1 = [int(round((x * sc + tx) * k)) for x in xr]
    y0, y1 = [int(round((y * sc + ty) * k)) for y in yr]
    x0, x1 = max(x0, 0), min(x1, L.shape[1])
    y0, y1 = max(y0, 0), min(y1, L.shape[0])
    if x1 - x0 < 3 or y1 - y0 < 3:
        return None
    hp = L - ndimage.uniform_filter(L, 3)
    b = L[y0:y1, x0:x1]
    return {"median": float(np.median(b)), "texture": float(hp[y0:y1, x0:x1].std()), "screen": [x0, y0, x1, y1]}


def measure(frames):
    out = {}
    for end, (slug, rows, wx, bx) in ENDS.items():
        try:
            s, size = shot(frames, slug)
        except KeyError:
            continue
        L = lin_lum(os.path.join(frames, f"{slug}-clean.png"))
        rr = []
        for yr in rows:
            w = box_stats(L, s, size, wx, yr)
            b = box_stats(L, s, size, bx, yr)
            if w is None or b is None:
                continue
            rr.append({"rows": list(yr), "wall": w, "back": b, "ratio": round(w["median"] / max(b["median"], 1e-6), 3),
                       "texture_ratio": round(w["texture"] / max(b["texture"], 1e-6), 3)})
        out[end] = {"frame": slug, "rows": rr}
    return out


def main():
    frames = sys.argv[1]
    label = sys.argv[2] if len(sys.argv) > 2 else os.path.basename(frames.rstrip("/"))
    res = measure(frames)
    lines = ["| Door end | Rows (world y) | Back wall median | Cross-wall median | Ratio | Texture: wall / back | Texture ratio |", "|---|---|---|---|---|---|---|"]
    for end, r in res.items():
        for row in r["rows"]:
            lines.append(f"| {end} ({r['frame']}) | {row['rows'][0]:.0f}-{row['rows'][1]:.0f} | {row['back']['median']:.4f} | {row['wall']['median']:.4f} | **{row['ratio']:.2f}** | {row['wall']['texture']:.4f} / {row['back']['texture']:.4f} | {row['texture_ratio']:.2f} |")
    print("\n".join(lines))
    json.dump(res, open(os.path.join(os.path.dirname(frames.rstrip("/")), f"walls-{label}.json"), "w"), indent=1)
    open(os.path.join(os.path.dirname(frames.rstrip("/")), f"walls-{label}.md"), "w").write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
