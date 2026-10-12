"""Guide-free foot-slide check on final frames.

For every frame, the soles touching the ground are the connected opaque blobs in the bottom
`band` rows above the baseline. Between frame i and i+1 the character moves forward by the
ground speed v (cell px per frame), so a planted sole must appear v px further LEFT in the cell
of frame i+1 (the body is pinned to the hip pivot while the ground moves back). Blobs are
matched by nearest centre after that shift; a match within `tol` px is a planted sole and its
residual is the slide. Unmatched blobs are lift-offs or touch-downs.

usage: soles.py ROW SPEED [N]   (speed in cell px per frame; omit or 0 for idle)
"""
import json, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))


def blobs(img, base, band):
    al = img[..., 3] >= 128
    rows = al[base - band:base]
    lab, n = ndimage.label(rows)
    out = []
    for k in range(1, n + 1):
        ys, xs = np.nonzero(lab == k)
        if len(xs) < 25 or ys.max() < band - 2:  # must touch the ground rows
            continue
        out.append(dict(x0=int(xs.min()), x1=int(xs.max()), cx=float(xs.mean()), n=int(len(xs))))
    return out


def run(row, v, fdir=None, band=None, tol=None):
    fdir = fdir or os.path.join(ROOT, 'frames', row)
    files = sorted(f for f in os.listdir(fdir) if f.startswith('frame_'))
    eng = row.startswith('eng')
    base = 311 if eng else 263
    band = band or (10 if eng else 8)
    tol = tol or (14.0 if eng else 12.0)
    ims = [np.asarray(Image.open(os.path.join(fdir, f)).convert('RGBA')) for f in files]
    B = [blobs(im, base, band) for im in ims]
    n = len(ims)
    res = []
    for i in range(n):
        j = (i + 1) % n
        for a in B[i]:
            best = None
            for b in B[j]:
                # planted: the sole's centre moves back by v; use both edges, take the smaller
                d = min(abs((b['cx'] + v) - a['cx']), abs((b['x0'] + v) - a['x0']), abs((b['x1'] + v) - a['x1']))
                if best is None or d < best[0]:
                    best = (d, b)
            if best and best[0] <= tol:
                b = best[1]
                # signed slide: centre for similar-width blobs, else the nearer edge
                cands = [(b['cx'] + v) - a['cx'], (b['x0'] + v) - a['x0'], (b['x1'] + v) - a['x1']]
                s = min(cands, key=abs)
                res.append(dict(step=f'{i}->{j}', x=round(a['cx'], 1), slide=round(float(s), 2)))
    sl = np.array([abs(r['slide']) for r in res]) if res else np.zeros(1)
    return dict(row=row, speed=v, band_rows=band, planted_pairs=len(res), max=round(float(sl.max()), 2),
                p90=round(float(np.percentile(sl, 90)), 2), mean=round(float(sl.mean()), 2), detail=res,
                soles_per_frame=[len(b) for b in B])


if __name__ == '__main__':
    row = sys.argv[1]; v = float(sys.argv[2]) if len(sys.argv) > 2 else 0.0
    r = run(row, v)
    json.dump(r, open(os.path.join(ROOT, 'qa', row + '-soles.json'), 'w'), indent=1)
    print(row, 'v', v, 'pairs', r['planted_pairs'], 'max', r['max'], 'p90', r['p90'], 'mean', r['mean'], 'soles/frame', r['soles_per_frame'])
    print('  >2px:', [(d['step'], d['x'], d['slide']) for d in r['detail'] if abs(d['slide']) > 2])
