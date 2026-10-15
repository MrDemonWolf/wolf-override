"""Fix round 4 (review r4, S1): the straight cut where the painted steam met the junction entry wall's far edge.
For each frame, window (x0, x1, y0, y1 in that frame's pixels) and the corner's column (the column where round 3's
cut sat), it reports the mean left-right luminance step (sRGB 0-255) across that column, the rows where that step
exceeds 12 (a ruler-straight edge carries one in most rows), and the widest step at any column 4 px either side.
usage: steamcheck.py LABEL=FRAME:x0,x1,y0,y1,corner ...   Scratch only."""
import sys
import numpy as np
from PIL import Image

print("| Frame | Rows | Corner column | Mean step across it | Rows with a step > 12 | Largest mean step within 4 px |")
print("|---|---|---|---|---|---|")
for arg in sys.argv[1:]:
    label, rest = arg.split("=", 1)
    path, box = rest.rsplit(":", 1)
    x0, x1, y0, y1, cx = (int(v) for v in box.split(","))
    a = np.asarray(Image.open(path).convert("L"), dtype=np.float32)[y0:y1, x0:x1]
    step = np.abs(np.diff(a, axis=1))
    c = cx - x0
    s = step[:, c]
    near = step[:, c - 4:c + 5].mean(0).max()
    print(f"| {label} | {y0}-{y1} | {cx} | {s.mean():.1f} | {int((s > 12).sum())} of {len(s)} | {near:.1f} |")
