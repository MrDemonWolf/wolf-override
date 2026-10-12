"""Pin planted paws/soles to the moving ground on final frames (guide-free).

1. Sole masks: opaque pixels in the bottom `band` rows that reach within 3 px of the baseline.
2. Links: a sole in frame i and one in frame i+1 are the same planted foot when the second,
   moved back by the ground speed v plus a small offset o (|o| <= 16 px), overlaps the first
   with IoU >= 0.45. o is that foot's slide between the two frames.
3. Chains of links are one stance. The cumulative slide along the chain is centred (mean 0)
   and becomes a per-frame horizontal correction, clamped to +-MAXC px.
4. Each correction bends only that foot and the lower leg: a displacement field that is 1 on the
   sole and fades to 0 about 60 px up the leg and 10 px to the sides, warped in premultiplied
   linear light at 3x and reduced with Lanczos. The body, head and tail do not move.

usage: pin_feet.py ROW SPEED SRC_DIR OUT_DIR
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
MAXC = 14.0


def to_lin(c):
    c = c / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def to_srgb(l):
    l = np.clip(l, 0, 1)
    return 255.0 * np.where(l <= 0.0031308, l * 12.92, 1.055 * l ** (1 / 2.4) - 0.055)


def soles(img, base, band):
    al = img[..., 3] >= 128
    m = np.zeros_like(al); m[base - band:base] = al[base - band:base]
    lab, n = ndimage.label(m)
    out = []
    for k in range(1, n + 1):
        mk = lab == k
        ys, xs = np.nonzero(mk)
        if len(xs) < 30 or ys.max() < base - 3:
            continue
        out.append(dict(mask=mk, x0=int(xs.min()), x1=int(xs.max()), cx=float(xs.mean())))
    return out


def shift_x(m, s):
    out = np.zeros_like(m)
    if s > 0: out[:, s:] = m[:, :-s]
    elif s < 0: out[:, :s] = m[:, -s:]
    else: out = m.copy()
    return out


def link(a, b, v):
    best = (0.0, 0)
    for o in range(-16, 17):
        s = int(round(v)) + o
        bs = shift_x(b['mask'], s)
        inter = (a['mask'] & bs).sum(); uni = (a['mask'] | bs).sum()
        iou = inter / max(1, uni)
        if iou > best[0]:
            best = (iou, o)
    return best


def warp(img, fields, base, ss=3):
    """fields: list of (sole bbox x0, x1, shift dx). Returns new uint8 RGBA."""
    Hh, Ww = img.shape[:2]
    a = img[..., 3].astype(np.float64) / 255.0
    lin = to_lin(img[..., :3].astype(np.float64)) * a[..., None]
    up = lambda ch: np.asarray(Image.fromarray(ch.astype(np.float32), 'F').resize((Ww * ss, Hh * ss), Image.LANCZOS))
    A = up(a); L = [up(lin[..., c]) for c in range(3)]
    yy, xx = np.mgrid[0:Hh * ss, 0:Ww * ss].astype(np.float32)
    ycell = (yy + 0.5) / ss; xcell = (xx + 0.5) / ss
    num = np.zeros_like(yy); den = np.zeros_like(yy)
    for x0, x1, dx in fields:
        wy = np.clip(1 - (base - 14 - ycell) / 46.0, 0, 1)  # 1 for the bottom 14 rows, 0 at 60 rows up
        wy = np.where(ycell > base + 2, 0, wy)
        dxl = np.maximum(0, np.maximum((x0 - 4) - xcell, xcell - (x1 + 4)))
        wx = np.clip(1 - dxl / 10.0, 0, 1)
        w = wy * wx
        num += w * dx; den += w
    dxf = np.where(den > 1, num / np.maximum(den, 1e-6), num) * ss
    coords = [yy, xx - dxf]
    A2 = ndimage.map_coordinates(A, coords, order=3, mode='constant')
    L2 = [ndimage.map_coordinates(c, coords, order=3, mode='constant') for c in L]
    down = lambda ch: np.asarray(Image.fromarray(ch.astype(np.float32), 'F').resize((Ww, Hh), Image.LANCZOS))
    Af = np.clip(down(A2), 0, 1); Lf = np.stack([down(c) for c in L2], -1)
    rgb = to_srgb(Lf / np.maximum(Af[..., None], 1e-4))
    A8 = np.round(Af * 255)
    inside = ndimage.distance_transform_edt(A8 >= 128)
    A8 = np.where(inside >= 2.5, 255, A8); A8 = np.where(A8 < 3, 0, A8)
    rgb = np.where(A8[..., None] > 0, rgb, 0)
    # keep untouched pixels bit-exact outside the warp region
    touched = ndimage.binary_dilation(np.asarray(Image.fromarray((np.abs(dxf) > 0.02).astype(np.uint8) * 255).resize((Ww, Hh), Image.BILINEAR)) > 0, iterations=2)
    out = img.copy()
    new = np.dstack([np.round(np.clip(rgb, 0, 255)), A8]).astype(np.uint8)
    out[touched] = new[touched]
    return out


def run(row, v, src, dst, band=None, guide_row=None):
    guide_row = guide_row or row
    eng = row.startswith('eng')
    base = 311 if eng else 263
    band = band or (12 if eng else 10)
    files = sorted(f for f in os.listdir(src) if f.startswith('frame_'))
    ims = [np.asarray(Image.open(os.path.join(src, f)).convert('RGBA')) for f in files]
    n = len(ims)
    S = [soles(im, base, band) for im in ims]
    # links i -> i+1
    # paw identity from the guide rig: a sole belongs to a designed planted paw when its centre
    # is the nearest within 30 px; a sole nearest to two planted paws (merged) is skipped
    import register as R
    meta = R.G[guide_row]; char = meta['char']; kind = meta['kind']; n_ = int(meta['n'])
    assert n_ == n
    feet = ('near', 'far') if char == 'eng' else ('RH', 'RF', 'LH', 'LF')
    assign = {}
    for i in range(n):
        des = {ft: R.foot_patch(char, kind, i, n, ft, base) for ft in feet}
        des = {ft: float(d[0][0]) for ft, d in des.items() if d is not None}
        owner = {}
        for ft, x in des.items():
            if not S[i]:
                continue
            k = int(np.argmin([abs(b['cx'] - x) for b in S[i]]))
            if abs(S[i][k]['cx'] - x) <= 30:
                owner.setdefault(k, []).append(ft)
        for k, fts in owner.items():
            if len(fts) == 1:
                assign[(i, fts[0])] = k
    corr = {i: [] for i in range(n)}
    report = []
    for ft in feet:
        for run in R.stance_runs(char, kind, n, ft):
            # split the run where a frame has no assigned sole or the link fails
            segs, cur, offs = [], [], []
            for a_, b_ in zip(run[:-1], run[1:]):
                ka, kb = assign.get((a_, ft)), assign.get((b_, ft))
                ok = ka is not None and kb is not None
                if ok:
                    iou, o = link(S[a_][ka], S[b_][kb], v)
                    ok = iou >= 0.4 and abs(o) < 16
                if ok:
                    if not cur:
                        cur, offs = [a_], [0.0]
                    cur.append(b_); offs.append(offs[-1] + o)
                else:
                    if len(cur) > 1:
                        segs.append((cur, offs))
                    cur, offs = [], []
            if len(cur) > 1:
                segs.append((cur, offs))
            for fr, of in segs:
                of = np.array(of, float)
                d = np.clip(of - of.mean(), -MAXC, MAXC)
                report.append(dict(foot=ft, frames=fr, slide_steps=[float(x) for x in np.diff(of)], correction=[round(float(x), 2) for x in d]))
                for fi, dx in zip(fr, d):
                    if abs(dx) >= 0.5:
                        sb = S[fi][assign[(fi, ft)]]
                        corr[fi].append((sb['x0'], sb['x1'], float(dx)))
    os.makedirs(dst, exist_ok=True)
    for i, im in enumerate(ims):
        out = warp(im, corr[i], base) if corr[i] else im
        Image.fromarray(out).save(os.path.join(dst, files[i]))
    return dict(row=row, speed=v, chains=report, corrections={i: c for i, c in corr.items() if c})


if __name__ == '__main__':
    row, v, src, dst = sys.argv[1], float(sys.argv[2]), sys.argv[3], sys.argv[4]
    r = run(row, v, src, dst, guide_row=sys.argv[5] if len(sys.argv) > 5 else None)
    json.dump(r, open(os.path.join(ROOT, 'qa', row + '-pin.json'), 'w'), indent=1)
    for c in r['chains']:
        print(c['foot'], c['frames'], 'steps', [round(x, 1) for x in c['slide_steps']], 'corr', c['correction'])
