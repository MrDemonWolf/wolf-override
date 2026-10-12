"""Independent measurements on registered frames.

Anchor drift: frame-to-frame change of (measured body-fixed marker - guide-predicted marker).
  engineer: the cyan belt light (pelvis-fixed) and the head mass centroid.
  WOLF: the cyan flank seam light (torso-fixed) and the cyan eye (head).
Foot slide: for each foot planted in two consecutive frames, change of (measured contact edge -
  guide-predicted contact edge). The guide moves planted feet back at exactly the ground speed, so
  any change is sliding against the floor. Reported in cell px and in 1080p game px.
Loop seam: silhouette IoU last->first versus the mean consecutive IoU; marker jump at the seam.
Identity: per-frame height/length, jacket or armour colour statistics.
"""
import json, math, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
import rig
from process import SPEC

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
G = json.load(open(os.path.join(ROOT, 'guides', 'guides.json')))
GAME = {'eng': 190.0 / 280.0, 'wolf': 310.0 / 460.0}  # cell px -> 1080p game px


def load(row, n):
    return [np.asarray(Image.open(os.path.join(ROOT, 'frames', row, 'frame_%02d.png' % i))) for i in range(n)]


def cyan_blobs(img, region=None):
    r, g, b, a = [img[..., i].astype(int) for i in range(4)]
    m = (a > 200) & (b > 150) & (g > 140) & (r < 140) & (b - r > 60)
    if region is not None:
        x0, y0, x1, y1 = region
        mm = np.zeros_like(m); mm[y0:y1, x0:x1] = m[y0:y1, x0:x1]; m = mm
    lab, n = ndimage.label(m)
    out = []
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        w = (b[ys, xs] + g[ys, xs]).astype(float)
        out.append(dict(n=len(xs), x=float((xs * w).sum() / w.sum()), y=float((ys * w).sum() / w.sum())))
    return sorted(out, key=lambda d: -d['n'])


def eng_pred(kind, f, n):
    J = rig.eng_pose(kind, f, n)
    return J


def to_cell_eng(v):
    return np.array([128 + v[0] * 280.0, 311 - v[1] * 280.0])


def to_cell_wolf(v):
    s = 460.0 / 1550.0
    return np.array([293 + v[0] * s, 263 - v[1] * s])


def measure(row, snap=0.0):
    meta = G[row]; char = meta['char']; kind = meta['kind']; n = meta['n']
    frames = load(row, n)
    res = dict(row=row, n=n)
    alpha = [f[..., 3] >= 128 for f in frames]
    # --- markers: body-fixed patches from frame 0 tracked by normalised cross-correlation
    def prem(f):
        return f[..., :3].astype(float) * (f[..., 3:4].astype(float) / 255.0)
    imgs = [prem(f) for f in frames]
    if char == 'eng':
        def preds(i):
            J = rig.eng_pose(kind, i, n)
            hd = to_cell_eng(J['head']) + [0, snap]
            hp = to_cell_eng(J['hip']) + [0, snap]
            return {'head': (hd, (46, 46)), 'pelvis': (hp + np.array([4, -16]), (60, 28))}
    else:
        def preds(i):
            J = rig.wolf_pose(kind, i, n)
            T = J['T']; hd = J.get('head_dy', 0.0)
            return {'head': (to_cell_wolf(T((510, 640)) + np.array([0, hd])) + [0, snap], (64, 56)),
                    'torso': (to_cell_wolf(T((0, 545))) + [0, snap], (120, 40))}
    names = list(preds(0).keys())
    drift = {}
    for nm in names:
        c0, (w, h) = preds(0)[nm]
        x0 = int(round(c0[0] - w / 2)); y0 = int(round(c0[1] - h / 2))
        tpl = imgs[0][y0:y0 + h, x0:x0 + w]
        tz = tpl - tpl.mean(); tn = np.sqrt((tz ** 2).sum()) + 1e-9
        resid = []
        for i in range(n):
            ci, _ = preds(i)[nm]
            ex = int(round(x0 + ci[0] - c0[0])); ey = int(round(y0 + ci[1] - c0[1]))
            R = 14; sc = np.full((2 * R + 1, 2 * R + 1), -1.0)
            for dy in range(-R, R + 1):
                for dx in range(-R, R + 1):
                    yy, xx = ey + dy, ex + dx
                    if yy < 0 or xx < 0 or yy + h > imgs[i].shape[0] or xx + w > imgs[i].shape[1]:
                        continue
                    win = imgs[i][yy:yy + h, xx:xx + w]
                    wz = win - win.mean()
                    sc[dy + R, dx + R] = (wz * tz).sum() / (np.sqrt((wz ** 2).sum()) * tn + 1e-9)
            iy, ix = np.unravel_index(np.argmax(sc), sc.shape)
            def para(a, b, c):
                d = a - 2 * b + c
                return 0.0 if d >= 0 else 0.5 * (a - c) / d
            sx = para(sc[iy, ix - 1], sc[iy, ix], sc[iy, ix + 1]) if 0 < ix < 2 * R else 0.0
            sy = para(sc[iy - 1, ix], sc[iy, ix], sc[iy + 1, ix]) if 0 < iy < 2 * R else 0.0
            mx = ex + ix - R + sx; my = ey + iy - R + sy
            # predicted top-left of the patch in frame i
            px_ = x0 + ci[0] - c0[0]; py_ = y0 + ci[1] - c0[1]
            resid.append((mx - px_, my - py_, float(sc[iy, ix])))
        r = np.array(resid)
        st = np.diff(np.vstack([r[:, :2], r[:1, :2]]), axis=0)
        d = np.linalg.norm(st, axis=1)
        drift[nm] = dict(max_px=round(float(d.max()), 2), mean_px=round(float(d.mean()), 2), seam_px=round(float(d[-1]), 2),
                         max_dx=round(float(np.abs(st[:, 0]).max()), 2), max_dy=round(float(np.abs(st[:, 1]).max()), 2),
                         min_ncc=round(float(r[:, 2].min()), 3), missing=0,
                         residual_x=[round(float(v), 2) for v in r[:, 0]], residual_y=[round(float(v), 2) for v in r[:, 1]])
    res['anchor_drift_cell_px'] = drift
    # --- foot slide
    slides = []; gaps = []
    if kind != 'idle' or True:
        feet = ('near', 'far') if char == 'eng' else ('RH', 'RF', 'LH', 'LF')
        prev = {}
        for i in list(range(n)) + [0]:
            f = frames[i]; al = f[..., 3] >= 128
            cur = {}
            if char == 'eng':
                J = rig.eng_pose(kind, i, n)
                for ft in feet:
                    if not J[ft + '_stance']:
                        continue
                    heel = to_cell_eng(J[ft + '_heel']); toe = to_cell_eng(J[ft + '_toe'])
                    pitch = math.degrees(J[ft + '_pitch'])
                    y0 = int(311 + snap - 9); y1 = int(311 + snap + 2)
                    x0 = int(min(heel[0], toe[0]) - 10); x1 = int(max(heel[0], toe[0]) + 10)
                    band = al[y0:y1, max(0, x0):x1]
                    cols = np.nonzero(band.any(0))[0]
                    if not len(cols):
                        continue
                    if pitch > 4:      # heel strike: heel edge is the planted point
                        meas = max(0, x0) + cols.min(); pred = min(heel[0], toe[0])
                    else:              # flat or toe roll: toe tip is planted
                        meas = max(0, x0) + cols.max(); pred = max(heel[0], toe[0])
                    rows = np.nonzero(al[:, max(0, x0):x1].any(1))[0]
                    gaps.append(dict(frame=i, foot=ft, gap_px=int(311 + snap - rows.max())))
                    cur[ft] = (meas - pred, 'heel' if pitch > 4 else 'toe')
            else:
                J = rig.wolf_pose(kind, i, n)
                for ft in feet:
                    if not J[ft + '_stance']:
                        continue
                    pc = to_cell_wolf(J[ft + '_paw'] + np.array([12, 0]))
                    y0 = int(263 + snap - 7); y1 = int(263 + snap + 2)
                    x0 = int(pc[0] - 16); x1 = int(pc[0] + 16)
                    band = al[y0:y1, max(0, x0):x1]
                    ys, xs = np.nonzero(band)
                    if not len(xs):
                        gaps.append(dict(frame=i, foot=ft, gap_px=None)); continue
                    meas = max(0, x0) + xs.mean()
                    rows = np.nonzero(al[:, max(0, x0):x1].any(1))[0]
                    gaps.append(dict(frame=i, foot=ft, gap_px=int(263 + snap - rows.max())))
                    cur[ft] = (meas - pc[0], 'paw')
            for ft, (e, kindm) in cur.items():
                if ft in prev and prev[ft][1] == kindm:
                    slides.append(dict(frame=i, foot=ft, slide_px=round(float(e - prev[ft][0]), 2), edge=kindm))
            prev = cur
    sl = np.array([abs(s['slide_px']) for s in slides]) if slides else np.array([0.0])
    res['foot_slide_cell_px'] = dict(max=round(float(sl.max()), 2), mean=round(float(sl.mean()), 2),
                                     p90=round(float(np.percentile(sl, 90)), 2), count=len(slides), detail=slides)
    res['foot_slide_game_px'] = dict(max=round(float(sl.max() * GAME[char]), 2), mean=round(float(sl.mean() * GAME[char]), 2))
    gv = [g['gap_px'] for g in gaps if g['gap_px'] is not None]
    res['contact_gap_px'] = dict(max_abs=int(max(abs(v) for v in gv)) if gv else None,
                                 values=[(g['frame'], g['foot'], g['gap_px']) for g in gaps])
    # --- seam and consecutive IoU
    def iou(a, b):
        return float((a & b).sum() / max(1, (a | b).sum()))
    cons = [iou(alpha[i], alpha[i + 1]) for i in range(n - 1)]
    res['seam'] = dict(iou_last_first=round(iou(alpha[-1], alpha[0]), 4), mean_consecutive_iou=round(float(np.mean(cons)), 4),
                       min_consecutive_iou=round(float(np.min(cons)), 4))
    # --- identity / size
    hs = []; ws = []; reds = []
    for f, al in zip(frames, alpha):
        ys, xs = np.nonzero(al)
        hs.append(int(ys.max() - ys.min() + 1)); ws.append(int(xs.max() - xs.min() + 1))
        r, g, b = [f[..., i].astype(float) for i in range(3)]
        if char == 'eng':
            m = al & (r > 90) & (r > g * 1.8) & (r > b * 1.6)
        else:
            m = al & (np.abs(r - g) < 25) & (b >= g) & (b - r < 40) & (r > 40)
        reds.append(dict(px=int(m.sum()), mean=[round(float(v[m].mean()), 1) for v in (r, g, b)] if m.sum() else None))
    res['identity'] = dict(height_px=hs, width_px=ws,
                           height_cv=round(float(np.std(hs) / np.mean(hs)), 4),
                           key_material=('jacket red' if char == 'eng' else 'armour grey'),
                           material_px=[d['px'] for d in reds],
                           material_px_cv=round(float(np.std([d['px'] for d in reds]) / max(1, np.mean([d['px'] for d in reds]))), 4),
                           material_mean_rgb=[d['mean'] for d in reds])
    return res


if __name__ == '__main__':
    for row in sys.argv[1:]:
        pj = json.load(open(os.path.join(ROOT, 'qa', row + '-process.json')))
        r = measure(row, snap=pj.get('mean_snap', 0.0))
        json.dump(r, open(os.path.join(ROOT, 'qa', row + '-measure.json'), 'w'), indent=1)
        d = r['anchor_drift_cell_px']
        print(row, 'drift', {k: (v['max_px'], v['mean_px'], v['seam_px'], v['missing']) for k, v in d.items()},
              'slide cell max/mean', r['foot_slide_cell_px']['max'], r['foot_slide_cell_px']['mean'],
              'gap', r['contact_gap_px']['max_abs'], 'seam', r['seam'], 'hcv', r['identity']['height_cv'])
