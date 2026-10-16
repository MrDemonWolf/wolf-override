"""Packs the two crank frames into eng-crank-atlas.png: each 384x384 frame trimmed to the union of
both frames' opaque bounds plus a 4 px transparent margin (so filtering and mipmaps never pull in
the other frame), A at x 0 and B at x w. Prints the game constants: the region size, the scale (the
in-game sprite's 0.188) and the sprite position that puts every pixel exactly where the rig put it
(the frame's centre is the usual sprite's centre, drawn at (0, -5))."""
import json
import os

import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
FR = os.path.join(HERE, "..", "frames")
OUT = os.path.join(HERE, "..", "deliver")
SCALE = 0.188
REST = (0.0, -5.0)
M = 4


def main():
    os.makedirs(OUT, exist_ok=True)
    fr = [np.asarray(Image.open(os.path.join(FR, f"frame-{k}.png")).convert("RGBA")) for k in "AB"]
    a = np.maximum(fr[0][..., 3], fr[1][..., 3]) > 0
    ys, xs = np.nonzero(a)
    x0, x1 = max(xs.min() - M, 0), min(xs.max() + 1 + M, 384)
    y0, y1 = max(ys.min() - M, 0), min(ys.max() + 1 + M, 384)
    x0, x1, y0, y1 = int(x0), int(x1), int(y0), int(y1)
    w, h = x1 - x0, y1 - y0
    atlas = np.zeros((h, 2 * w, 4), np.uint8)
    for i, f in enumerate(fr):
        atlas[:, i * w:(i + 1) * w] = f[y0:y1, x0:x1]
    Image.fromarray(atlas, "RGBA").save(os.path.join(OUT, "eng-crank-atlas.png"))
    cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
    pos = (REST[0] + (cx - 192.0) * SCALE, REST[1] + (cy - 192.0) * SCALE)
    info = {"atlas": [2 * w, h], "region_size": [w, h], "trim": [int(x0), int(y0), int(x1), int(y1)], "scale": SCALE,
            "sprite_pos": [round(pos[0], 4), round(pos[1], 4)], "frame_order": ["A (regrip)", "B (push)"],
            "texture_bytes_rgba8_with_mips": int(2 * w * h * 4 * 4 / 3)}
    json.dump(info, open(os.path.join(OUT, "pack.json"), "w"), indent=1)
    print(json.dumps(info))


if __name__ == "__main__":
    main()
