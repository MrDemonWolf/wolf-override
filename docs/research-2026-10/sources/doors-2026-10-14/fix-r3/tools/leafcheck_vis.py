"""Draws leafcheck's zones on each frame (red leaf, yellow head-by-hinge, cyan reveal, green free-low)."""
import sys, json, os, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import leafcheck as LC
from PIL import Image
from scipy import ndimage
fr, out = sys.argv[1], sys.argv[2]
run = json.load(open(fr + "/_run.json")); shots = {s["slug"]: s for s in run["shots"]}
tiles = []
for end, (a, b, win, side) in LC.LEAVES.items():
    A = np.asarray(Image.open(f"{fr}/{a}-clean.png").convert("RGB")).astype(int); B = np.asarray(Image.open(f"{fr}/{b}-clean.png").convert("RGB")).astype(int)
    outline = ndimage.binary_erosion(LC.leaf_outline(end, shots[a], run["size"], A.shape[:2]), iterations=1)
    same = np.abs(A - B).sum(-1) <= 2
    m = outline & ~ndimage.binary_dilation(same & ndimage.binary_opening(same, iterations=2), iterations=1)
    head, rev, low, _ = LC.zones(m, side)
    v = A.astype(float)
    for msk, col, w in ((m, (255, 0, 0), 0.35), (head, (255, 255, 0), 0.7), (rev, (0, 255, 255), 0.7), (low, (0, 255, 0), 0.7)):
        v[msk] = v[msk] * (1 - w) + np.array(col) * w
    ys, xs = np.nonzero(outline)
    x0, x1, y0, y1 = max(xs.min() - 30, 0), xs.max() + 30, max(ys.min() - 20, 0), ys.max() + 10
    t = Image.fromarray(v[y0:y1, x0:x1].astype(np.uint8)); tiles.append(t.resize((t.width * 3, t.height * 3), Image.NEAREST))
W = sum(t.width for t in tiles) + 10 * len(tiles); H = max(t.height for t in tiles)
sheet = Image.new("RGB", (W, H), (20, 20, 20)); x = 0
for t in tiles: sheet.paste(t, (x, 0)); x += t.width + 10
sheet.save(out)
