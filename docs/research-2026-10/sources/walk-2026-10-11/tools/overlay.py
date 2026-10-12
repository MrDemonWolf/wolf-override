import sys
import numpy as np
from PIL import Image
raw, guide, out = sys.argv[1:4]
r = Image.open(raw).convert('RGB'); g = Image.open(guide).convert('RGB').resize(r.size)
ga = np.asarray(g).astype(int); m = (np.abs(ga - [255, 0, 255]).sum(2) > 60)
ra = np.asarray(r).astype(float)
o = ra.copy(); o[m] = o[m] * 0.45 + np.array([0, 255, 120]) * 0.55
Image.fromarray(o.astype(np.uint8)).resize((r.width // 2, r.height // 2)).save(out)
