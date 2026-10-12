"""Measurements on the final registered frames (frames/<row>/frame_XX.png).

Anchor drift: body patches (engineer head + torso; WOLF head, withers, flank, croup) are tracked
frame to frame by normalised cross-correlation at 2x, the loop is closed, and each patch's
position is compared with the guide's designed path (fixed hip x, designed bob). Drift is the
frame-to-frame step of that residual, in final cell px (and 1080p game px). As an independent
check the engineer's cyan belt light and WOLF's cyan eye are located by colour and treated the
same way when they are visible.
Foot slide: for each foot planted in two consecutive frames, the change of its measured contact
point minus the designed ground travel (stride / n per frame). Also reported against the best
single ground speed for the row (the speed the preview and the game should use).
Contact gap: baseline row minus lowest opaque row under each planted foot.
Loop seam: silhouette IoU last->first against the mean consecutive IoU.
Identity: opaque height/length per frame, key-material pixel share and mean colour, edge colour
shift (key spill) against the ring 2-4 px inside.
"""
import json, math, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
import rig
from register import feat, ncc_track, eng_cell, wolf_cell, patches
from process import SPEC

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
G = json.load(open(os.path.join(ROOT, 'guides', 'guides.json')))
GAME = {'eng': 190.0 / 280.0, 'wolf': 310.0 / 460.0}


def srgb_to_lab(rgb):
    c = rgb / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ M.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def measure(row, frames_dir=None):
    meta = G[row]; char = meta['char']; kind = meta['kind']; n = meta['n']
    sp = SPEC[char]
    fdir = frames_dir or os.path.join(ROOT, 'frames', row)
    frames = [np.asarray(Image.open(os.path.join(fdir, 'frame_%02d.png' % i)).convert('RGBA')) for i in range(n)]
    res = dict(row=row, n=n)
    up = [np.asarray(Image.fromarray(f).resize((f.shape[1] * 2, f.shape[0] * 2), Image.LANCZOS)) for f in frames]
    fts = [feat(u) for u in up]
    names = list(patches(char, kind, 0, n)[1].keys())
    drift = {}
    for nm in names:
        steps = []; scs = []
        for i in range(n):
            j = (i + 1) % n
            ci, size, _ = patches(char, kind, i, n)[1][nm]
            cj = patches(char, kind, j, n)[1][nm][0]
            off, sc = ncc_track(fts[i], fts[j], ci * 2, cj * 2, (size[0] * 2, size[1] * 2), R=36)
            steps.append(off / 2); scs.append(sc)
        st = np.array(steps); clos = st.sum(0)
        stc = st - clos / n
        d = np.linalg.norm(stc, axis=1)
        drift[nm] = dict(max_px=round(float(d.max()), 2), mean_px=round(float(d.mean()), 2), seam_px=round(float(d[-1]), 2),
                         max_dx=round(float(np.abs(stc[:, 0]).max()), 2), max_dy=round(float(np.abs(stc[:, 1]).max()), 2),
                         loop_closure_px=[round(float(c), 2) for c in clos], min_ncc=round(float(min(scs)), 3),
                         steps=[[round(float(a), 2), round(float(b), 2)] for a, b in stc])
    res['anchor_drift_cell_px'] = drift
    body = [nm for nm in names if nm != 'head']
    res['anchor_drift_body_max_cell_px'] = max(drift[nm]['max_px'] for nm in body)
    res['anchor_drift_body_max_game_px'] = round(res['anchor_drift_body_max_cell_px'] * GAME[char], 2)
    res['anchor_drift_head_max_cell_px'] = drift['head']['max_px']
    # independent colour marker
    mk = []
    for i, f in enumerate(frames):
        r, g, b, a = [f[..., c].astype(int) for c in range(4)]
        m = (a > 200) & (b > 150) & (g > 140) & (r < 150) & (b - r > 60)
        if char == 'eng':
            J = rig.eng_pose(kind, i, n); hip = eng_cell(J['hip'])
            box = (int(hip[0] - 40), int(hip[1] - 40), int(hip[0] + 40), int(hip[1] + 12)); pred = hip
        else:
            J = rig.wolf_pose(kind, i, n); T = J['T']
            pred = wolf_cell(T((585, 640)) + np.array([0, J.get('head_dy', 0.0)]))
            box = (int(pred[0] - 30), int(pred[1] - 25), int(pred[0] + 30), int(pred[1] + 25))
        mm = np.zeros_like(m); mm[box[1]:box[3], box[0]:box[2]] = m[box[1]:box[3], box[0]:box[2]]
        lab, k = ndimage.label(mm)
        if k == 0:
            mk.append(None); continue
        sizes = ndimage.sum(mm, lab, range(1, k + 1)); best = 1 + int(np.argmax(sizes))
        ys, xs = np.nonzero(lab == best)
        mk.append((xs.mean() - pred[0], ys.mean() - pred[1], int(len(xs))))
    steps = []
    for i in range(n):
        j = (i + 1) % n
        if mk[i] is not None and mk[j] is not None:
            steps.append(math.hypot(mk[j][0] - mk[i][0], mk[j][1] - mk[i][1]))
    res['marker'] = dict(name='cyan belt light' if char == 'eng' else 'cyan eye', visible=sum(m is not None for m in mk),
                         max_step_px=round(max(steps), 2) if steps else None, mean_step_px=round(float(np.mean(steps)), 2) if steps else None,
                         note='colour centroid; light shape changes with pose and occlusion, so this is an upper bound')
    # foot contact
    alpha = [f[..., 3] >= 128 for f in frames]
    feet = ('near', 'far') if char == 'eng' else ('RH', 'RF', 'LH', 'LF')
    base = sp['base']
    pts = {}  # (frame, foot) -> (measured x, predicted x, kind)
    gaps = []
    for i in range(n):
        al = alpha[i]
        if char == 'eng':
            J = rig.eng_pose(kind, i, n)
            for ft in feet:
                if not J[ft + '_stance']:
                    continue
                heel = eng_cell(J[ft + '_heel']); toe = eng_cell(J[ft + '_toe'])
                pitch = math.degrees(J[ft + '_pitch'])
                x0 = int(min(heel[0], toe[0]) - 10); x1 = int(max(heel[0], toe[0]) + 10)
                band = al[base - 9:base + 2, max(0, x0):x1]
                cols = np.nonzero(band.sum(0) >= 2)[0]
                if not len(cols):
                    gaps.append((i, ft, None)); continue
                if pitch > 4:
                    meas = max(0, x0) + cols.min(); pred = min(heel[0], toe[0]); edge = 'heel'
                else:
                    meas = max(0, x0) + cols.max(); pred = max(heel[0], toe[0]); edge = 'toe'
                rows = np.nonzero(al[:, max(0, x0):x1].sum(1) >= 3)[0]
                gaps.append((i, ft, int(base - rows.max())))
                pts[(i, ft)] = (float(meas), float(pred), edge)
        else:
            J = rig.wolf_pose(kind, i, n)
            for ft in feet:
                if not J[ft + '_stance']:
                    continue
                pc = wolf_cell(J[ft + '_paw'] + np.array([12, 0]))
                x0 = int(pc[0] - 16); x1 = int(pc[0] + 16)
                band = al[base - 7:base + 2, max(0, x0):x1]
                ys, xs = np.nonzero(band)
                if not len(xs):
                    gaps.append((i, ft, None)); continue
                rows = np.nonzero(al[:, max(0, x0):x1].sum(1) >= 3)[0]
                gaps.append((i, ft, int(base - rows.max())))
                pts[(i, ft)] = (float(max(0, x0) + xs.mean()), float(pc[0]), 'paw')
    stride_cell = meta['stride_units'] * (280.0 if char == 'eng' else 460.0 / 1550.0)
    v_design = stride_cell / n if kind != 'idle' else 0.0
    # slide: positions of the planted part of each foot over each stance run (heel edge in heel
    # strike, toe edge in toe-off, NCC of the boot or paw otherwise), in ground coordinates
    from register import foot_track, stance_runs, WK as RWK
    imgs2 = up
    pairs = []
    for ft in feet:
        for run in stance_runs(char, kind, n, ft):
            M, info = foot_track(fts, imgs2, char, kind, n, ft, run, base)
            for k_ in range(len(M) - 1):
                pairs.append((run[k_], ft, M[k_ + 1] - M[k_], info[k_]))
    if pairs:
        meas = np.array([p[2] for p in pairs])
        v_fit = -float(np.median(meas)) if kind != 'idle' else 0.0
        sl = meas + v_design
        sl_fit = meas + v_fit
        res['foot_slide_cell_px'] = dict(max=round(float(np.abs(sl).max()), 2), mean=round(float(np.abs(sl).mean()), 2), count=len(pairs),
                                         note='against the guide ground speed (stride / n per frame)')
        res['ground_speed_cell_px_per_frame'] = dict(designed=round(v_design, 3), best_fit=round(v_fit, 3))
        res['foot_slide_at_best_fit_cell_px'] = dict(max=round(float(np.abs(sl_fit).max()), 2), mean=round(float(np.abs(sl_fit).mean()), 2),
                                                     p90=round(float(np.percentile(np.abs(sl_fit), 90)), 2),
                                                     detail=[dict(frame=p[0], foot=p[1], slide=round(float(s_), 2), method=p[3]) for p, s_ in zip(pairs, sl_fit)])
        res['foot_slide_at_best_fit_game_px'] = dict(max=round(float(np.abs(sl_fit).max()) * GAME[char], 2), mean=round(float(np.abs(sl_fit).mean()) * GAME[char], 2))
    gv = [g[2] for g in gaps if g[2] is not None]
    res['contact_gap_px'] = dict(max_abs=int(max(abs(v) for v in gv)) if gv else None, values=gaps)
    def iou(a, b):
        return float((a & b).sum() / max(1, (a | b).sum()))
    cons = [iou(alpha[i], alpha[(i + 1) % n]) for i in range(n)]
    res['seam'] = dict(iou_last_first=round(cons[-1], 4), mean_consecutive_iou=round(float(np.mean(cons[:-1])), 4),
                       min_consecutive_iou=round(float(np.min(cons[:-1])), 4))
    hs, ws, mats, shifts = [], [], [], []
    for f, al in zip(frames, alpha):
        ys, xs = np.nonzero(al)
        hs.append(int(ys.max() - ys.min() + 1)); ws.append(int(xs.max() - xs.min() + 1))
        r, g, b = [f[..., c].astype(float) for c in range(3)]
        if char == 'eng':
            m = al & (r > 90) & (r > g * 1.8) & (r > b * 1.6)
        else:
            m = al & (np.abs(r - g) < 25) & (b >= g) & (b - r < 40) & (r > 40)
        mats.append((int(m.sum()), [round(float(v[m].mean()), 1) for v in (r, g, b)] if m.sum() else None))
        # edge chroma shift: partial-alpha edge pixels vs the opaque ring 2-4 px inside
        A = f[..., 3]
        edge = (A > 16) & (A < 240)
        din = ndimage.distance_transform_edt(A >= 250)
        ring = (din >= 2) & (din <= 4)
        lab = srgb_to_lab(f[..., :3].astype(float))
        if edge.sum() > 20 and ring.sum() > 20:
            # nearest-ring colour per edge pixel
            _, idx = ndimage.distance_transform_edt(~ring, return_indices=True)
            ref = lab[idx[0], idx[1]]
            dab = np.linalg.norm((lab - ref)[..., 1:], axis=2)[edge]
            shifts.append(float(dab.mean()))
            sa = (lab - ref)[..., 1][edge].mean(); sb = (lab - ref)[..., 2][edge].mean()
            shifts[-1] = (float(dab.mean()), float(sa), float(sb))
    res['identity'] = dict(height_px=hs, width_px=ws, height_cv=round(float(np.std(hs) / np.mean(hs)), 4),
                           key_material=('jacket red' if char == 'eng' else 'armour grey'),
                           material_px=[m[0] for m in mats], material_px_cv=round(float(np.std([m[0] for m in mats]) / max(1, np.mean([m[0] for m in mats]))), 4),
                           material_mean_rgb=[m[1] for m in mats])
    if shifts:
        res['edge'] = dict(mean_ab_shift=round(float(np.mean([s[0] for s in shifts])), 2), mean_da=round(float(np.mean([s[1] for s in shifts])), 2),
                           mean_db=round(float(np.mean([s[2] for s in shifts])), 2),
                           note='mean a*b* difference of semi-transparent edge pixels from the opaque ring 2-4 px inside; negative db = toward blue/cyan, positive da = toward magenta')
    return res


if __name__ == '__main__':
    for row in sys.argv[1:]:
        r = measure(row)
        json.dump(r, open(os.path.join(ROOT, 'qa', row + '-measure.json'), 'w'), indent=1)
        d = r['anchor_drift_cell_px']
        print(row, 'drift max/mean/seam', {k: (v['max_px'], v['mean_px'], v['seam_px']) for k, v in d.items()},
              '| marker', r['marker']['visible'], r['marker']['max_step_px'],
              '| slide', r.get('foot_slide_cell_px', {}).get('max'), r.get('foot_slide_cell_px', {}).get('mean'),
              'bestfit', r.get('foot_slide_at_best_fit_cell_px'), r.get('ground_speed_cell_px_per_frame'),
              '| gap', r['contact_gap_px']['max_abs'], '| seam', r['seam'], '| hcv', r['identity']['height_cv'], '| edge', r.get('edge'))
