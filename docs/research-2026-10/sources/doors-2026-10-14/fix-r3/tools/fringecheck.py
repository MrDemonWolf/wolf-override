"""Fix round 3 (review r3, R3-1): fails any door atlas holding a key-coloured (violet/magenta) pixel: alpha > 0,
b - g > 20 and r - g > 8 (review r3's test). Scratch only. usage: fringecheck.py ATLAS.png [...]; exit 1 on any hit."""
import sys

import numpy as np
from PIL import Image

bad = 0
for p in sys.argv[1:]:
    a = np.asarray(Image.open(p).convert("RGBA")).astype(int)
    hit = (a[..., 3] > 0) & (a[..., 2] - a[..., 1] > 20) & (a[..., 0] - a[..., 1] > 8)
    n = int(hit.sum())
    print(f"{'FAIL' if n else 'pass'}  {n:5d} violet px  {p}")
    bad += n
sys.exit(1 if bad else 0)
