"""Per frame: designed planted feet vs nearest painted ground-touching sole (cell px), and the
ground-locked painted position (cx + i*v) per foot, which must be constant over a stance.
usage: paw_diag.py ROW SPEED [FRAMES_DIR] [GUIDE_ROW]"""
import os, sys
import numpy as np
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
import register as R
from soles import blobs
row, v = sys.argv[1], float(sys.argv[2])
fdir = sys.argv[3] if len(sys.argv) > 3 else f'frames/{row}'
grow = sys.argv[4] if len(sys.argv) > 4 else row
meta = R.G[grow]; char, kind, n = meta['char'], meta['kind'], int(meta['n'])
base = 311 if char == 'eng' else 263
feet = ('near', 'far') if char == 'eng' else ('RH', 'RF', 'LH', 'LF')
track = {ft: [] for ft in feet}
for i in range(n):
    im = np.asarray(Image.open(f'{fdir}/frame_{i:02d}.png').convert('RGBA'))
    B = blobs(im, base, 10 if char == 'eng' else 8)
    line = []
    for ft in feet:
        p = R.foot_patch(char, kind, i, n, ft, base)
        if p is None:
            continue
        x = float(p[0][0])
        if B:
            k = int(np.argmin([abs(b['cx'] - x) for b in B])); cx = B[k]['cx']
            if abs(cx - x) <= 40:
                line.append(f"{ft}:{cx - x:+.0f}"); track[ft].append((i, round(cx + i * v)))
                continue
        line.append(f'{ft}:MISSING')
    print(i, ' '.join(line), ' soles', [round(b['cx']) for b in B])
for ft, t in track.items():
    print(ft, 'ground-locked', t)
