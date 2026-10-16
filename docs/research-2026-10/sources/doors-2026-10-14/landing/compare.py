"""Share of pixels (any channel more than 8/255 apart) between two capture folders' -clean frames, per state.
usage: compare.py PACKAGE_DIR AFTER_DIR"""
import os, sys
import numpy as np
from PIL import Image
a_dir, b_dir = sys.argv[1:3]
rows = []
for f in sorted(os.listdir(b_dir)):
    if not f.endswith('-clean.png') or not os.path.exists(os.path.join(a_dir, f)):
        continue
    a = np.array(Image.open(os.path.join(a_dir, f)).convert('RGB')).astype(int)
    b = np.array(Image.open(os.path.join(b_dir, f)).convert('RGB')).astype(int)
    if a.shape != b.shape:
        rows.append((f, None)); continue
    d = (np.abs(a - b).max(-1) > 8).mean() * 100
    rows.append((f[:-10], d))
for f, d in rows:
    print('%-28s %s' % (f, 'size differs' if d is None else '%.1f %%' % d))
