"""Register painted frames to a fixed hip point and a shared baseline (v2).

The first pass (process.py) placed each frame by fitting its whole silhouette to the
mannequin. Limbs never match the mannequin exactly, so the body jumped by up to 20 px.
This pass keeps process.py's matte and its silhouette fit only as a starting point, then:

1. one scale per row (median silhouette-fit scale), so the figure never changes size;
2. tracks rigid body patches (head, chest, belt for the engineer; head, withers, flank and
   croup for WOLF) by normalised cross-correlation at 2x the final size, and moves each
   frame so the weighted median patch residual against the guide's designed hip path is
   zero: x is locked to the fixed hip pivot, y follows the designed bob;
3. checks contact feet against the baseline and, where the painted legs are longer or
   shorter than designed, splits the difference between hip and foot (see VERT_W);
4. resamples once from the raw painting (premultiplied linear light, Lanczos) into the
   final cell.

usage: register.py ROW [ROW ...]
"""
import json, math, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
import rig
import process as P

ROOT = P.ROOT
G = P.G
SPEC = P.SPEC
WK = 2  # working supersample for tracking

# vertical: weight of the foot-contact snap against the hip path (0 = hip only, 1 = feet only)
VERT_W = 0.0
RESEAT_MAX = 5.0  # cell px
FEET = True


def extract(rowkey):
    """Matte every frame of the row and get the silhouette fit (from process.py)."""
    meta = G[rowkey]
    frames = []
    for sheet in meta['sheets']:
        rawp = os.path.join(ROOT, 'raw', sheet['file'])
        im = Image.open(rawp).convert('RGB')
        gim = Image.open(os.path.join(ROOT, 'guides', sheet['file'])).convert('RGB')
        sx = im.width / gim.width; sy = im.height / gim.height
        if abs(sx - 1) > 1e-6 or abs(sy - 1) > 1e-6:
            gim = gim.resize(im.size, Image.LANCZOS)
        rgb = np.asarray(im)
        col, a, mrep = P.matte(rgb)
        a, lab, km = P.clean_alpha(a, min_island=int(600 * sx * sy))
        g = np.asarray(gim).astype(int)
        gmask = np.abs(g - [255, 0, 255]).sum(2) > 90
        labs = ndimage.label(a > 0.5)[0]
        for fr in sheet['frames']:
            if fr.get('anchor_of') is not None:
                continue  # an approved painting placed as a reference, not a new frame
            x0, y0, x1, y1 = fr['cell']
            X0, Y0, X1, Y1 = x0 * sx, y0 * sy, x1 * sx, y1 * sy
            wx0, wy0, wx1, wy1 = int(X0), int(Y0), int(math.ceil(X1)), int(math.ceil(Y1))
            ids = np.unique(labs[wy0:wy1, wx0:wx1]); ids = ids[ids > 0]
            own = np.zeros_like(a, bool)
            for i in ids:
                ys, xs = np.nonzero(labs == i)
                cx, cy = xs.mean(), ys.mean()
                if X0 <= cx < X1 and Y0 <= cy < Y1 and len(xs) > 200 * sx * sy:
                    own |= labs == i
            own = ndimage.binary_dilation(own, iterations=4) & (a > 0)
            fa = np.where(own, a, 0.0)
            m = 40
            wy0m, wy1m = max(0, wy0 - m), min(a.shape[0], wy1 + m)
            wx0m, wx1m = max(0, wx0 - m), min(a.shape[1], wx1 + m)
            pm = (fa[wy0m:wy1m, wx0m:wx1m] > 0.5).astype(np.float32)
            gm = np.zeros_like(pm)
            gcell = gmask[int(Y0):int(Y1), int(X0):int(X1)]
            gm[int(Y0) - wy0m:int(Y0) - wy0m + gcell.shape[0], int(X0) - wx0m:int(X0) - wx0m + gcell.shape[1]] = gcell
            half = lambda z: np.asarray(Image.fromarray((z * 255).astype(np.uint8)).resize((z.shape[1] // 2, z.shape[0] // 2), Image.BILINEAR)) / 255.0
            ph, gh = (half(pm) > 0.5).astype(np.float32), (half(gm) > 0.5).astype(np.float32)
            s, tx, ty, iou = P.iou_fit(ph, gh, np.arange(0.80, 1.305, 0.02))
            s2, tx2, ty2, iou2 = P.iou_fit(pm, gm, np.arange(s - 0.02, s + 0.021, 0.005))
            frames.append(dict(frame=fr['frame'], sheet=sheet['file'], fr=fr, col=col, a=fa, pm=pm, gm=gm,
                               win=(wx0m, wy0m), fit_free=(s2, tx2, ty2, iou2), sx=sx, sy=sy, matte=mrep))
    frames.sort(key=lambda d: d['frame'])
    return frames


def render(f, W, H, px, base, kk, rx, ry, dx=0.0, dy=0.0):
    """final = (raw - (rx, ry)) * kk + (px + dx, base + dy)."""
    bx0 = rx + (0 - px - dx) / kk
    by0 = ry + (0 - base - dy) / kk
    bx1 = bx0 + W / kk; by1 = by0 + H / kk
    a_full = f['a'].astype(np.float32)
    Pd = 16
    cx0 = int(math.floor(bx0)) - Pd; cy0 = int(math.floor(by0)) - Pd
    cx1 = int(math.ceil(bx1)) + Pd; cy1 = int(math.ceil(by1)) + Pd
    hh, ww = a_full.shape
    a = np.zeros((cy1 - cy0, cx1 - cx0), np.float32)
    colw = np.zeros((cy1 - cy0, cx1 - cx0, 3), np.float64)
    sx0, sy0, sx1, sy1 = max(0, cx0), max(0, cy0), min(ww, cx1), min(hh, cy1)
    a[sy0 - cy0:sy1 - cy0, sx0 - cx0:sx1 - cx0] = a_full[sy0:sy1, sx0:sx1]
    colw[sy0 - cy0:sy1 - cy0, sx0 - cx0:sx1 - cx0] = f['col'][sy0:sy1, sx0:sx1]
    box = (bx0 - cx0, by0 - cy0, bx1 - cx0, by1 - cy0)
    lin = P.to_lin(colw).astype(np.float32) * a[..., None]
    chans = [np.asarray(Image.fromarray(np.ascontiguousarray(lin[..., c]), 'F').resize((W, H), Image.LANCZOS, box=box)) for c in range(3)]
    A = np.clip(np.asarray(Image.fromarray(a, 'F').resize((W, H), Image.LANCZOS, box=box)), 0, 1)
    rgb = np.stack(chans, -1) / np.maximum(A[..., None], 1e-4)
    rgb = P.to_srgb(rgb)
    A8 = np.round(A * 255)
    inside = ndimage.distance_transform_edt(A8 >= 128)
    A8 = np.where(inside >= 2.5, 255, A8)
    A8 = np.where(A8 < 3, 0, A8)
    rgb = np.where(A8[..., None] > 0, rgb, 0)
    return np.dstack([np.round(np.clip(rgb, 0, 255)), A8]).astype(np.uint8)


# ------------------------------------------------------------- body patches
def eng_cell(v):
    return np.array([128 + v[0] * 280.0, 311 - v[1] * 280.0])


def wolf_cell(v):
    s = 460.0 / 1550.0
    return np.array([293 + v[0] * s, 263 - v[1] * s])


def patches(char, kind, i, n):
    """Designed patch centres (final-cell px), sizes (cell px) and weights for frame i.
    Patches cover rigid body parts only (no limbs)."""
    if char == 'eng':
        J = rig.eng_pose(kind, i, n)
        hip = eng_cell(J['hip']); sh = eng_cell(J['shoulder']); hd = eng_cell(J['head'])
        return hip, {
            'head': (hd + [0, -2], (50, 50), 0.0 if kind != 'jog' else 0.5),
            'torso': (hip + (sh - hip) * 0.5 + ([-6, 0] if kind == 'jog' else [0, 0]), ((40, 70) if kind == 'jog' else (52, 70)), 2.0),
        }
    J = rig.wolf_pose(kind, i, n)
    T = J['T']; hd = J.get('head_dy', 0.0)
    hip = wolf_cell(J['hip'])
    s = 460.0 / 1550.0
    return hip, {
        'head': (wolf_cell(T((520, 630)) + np.array([0, hd])), (150 * s, 130 * s), 0.0),
        'withers': (wolf_cell(T((230, 560))), (170 * s, 110 * s), 1.0),
        'flank': (wolf_cell(T((10, 520))), (190 * s, 110 * s), 1.5),
        'croup': (wolf_cell(T((-210, 550))), (150 * s, 100 * s), 1.0),
    }


def feat(img):
    a = img[..., 3].astype(np.float32) / 255.0
    lum = (0.2126 * img[..., 0] + 0.7152 * img[..., 1] + 0.0722 * img[..., 2]).astype(np.float32) * a
    # emphasise structure: luma plus a scaled alpha channel
    return np.stack([lum, a * 120.0], -1)


def ncc_track(ref, cur, c_ref, c_cur, size, R):
    """Find where the patch of ref centred at c_ref (working px) lies in cur, searching
    around c_cur within +-R. Returns (offset of the found centre from c_cur, score)."""
    w, h = int(round(size[0])), int(round(size[1]))
    x0 = int(round(c_ref[0] - w / 2)); y0 = int(round(c_ref[1] - h / 2))
    tpl = ref[y0:y0 + h, x0:x0 + w]
    if tpl.shape[0] != h or tpl.shape[1] != w:
        return None, -1
    tz = tpl - tpl.mean(axis=(0, 1)); tn = np.sqrt((tz ** 2).sum()) + 1e-9
    ex = int(round(c_cur[0] - w / 2)); ey = int(round(c_cur[1] - h / 2))
    sc = np.full((2 * R + 1, 2 * R + 1), -1.0)
    for dy in range(-R, R + 1):
        yy = ey + dy
        if yy < 0 or yy + h > cur.shape[0]:
            continue
        for dx in range(-R, R + 1):
            xx = ex + dx
            if xx < 0 or xx + w > cur.shape[1]:
                continue
            win = cur[yy:yy + h, xx:xx + w]
            wz = win - win.mean(axis=(0, 1))
            sc[dy + R, dx + R] = (wz * tz).sum() / (np.sqrt((wz ** 2).sum()) * tn + 1e-9)
    iy, ix = np.unravel_index(np.argmax(sc), sc.shape)

    def para(a, b, c):
        d = a - 2 * b + c
        return 0.0 if d >= 0 else 0.5 * (a - c) / d
    fx = para(sc[iy, ix - 1], sc[iy, ix], sc[iy, ix + 1]) if 0 < ix < 2 * R else 0.0
    fy = para(sc[iy - 1, ix], sc[iy, ix], sc[iy + 1, ix]) if 0 < iy < 2 * R else 0.0
    off = np.array([ix - R + fx + (ex + w / 2 - c_cur[0]), iy - R + fy + (ey + h / 2 - c_cur[1])])
    return off, float(sc[iy, ix])


def wmedian(vals, w):
    o = np.argsort(vals); v = np.asarray(vals)[o]; ww = np.asarray(w)[o]
    c = np.cumsum(ww) / ww.sum()
    return float(v[np.searchsorted(c, 0.5)])


def contact_low(rgba, char, kind, i, n, scale=1.0):
    """Lowest opaque row under each planted foot (cell px) for frame i."""
    al = rgba[..., 3] >= 128
    out = {}
    if char == 'eng':
        J = rig.eng_pose(kind, i, n)
        for ft in ('near', 'far'):
            if not J[ft + '_stance']:
                continue
            hx = eng_cell(J[ft + '_heel'])[0]; tx = eng_cell(J[ft + '_toe'])[0]
            x0 = int((min(hx, tx) - 6) * scale); x1 = int((max(hx, tx) + 6) * scale)
            rows = np.nonzero(al[:, max(0, x0):x1].sum(1) >= 3 * scale)[0]
            if len(rows):
                out[ft] = rows.max() / scale
    else:
        J = rig.wolf_pose(kind, i, n)
        for ft in ('RH', 'RF', 'LH', 'LF'):
            if not J[ft + '_stance']:
                continue
            pc = wolf_cell(J[ft + '_paw'] + np.array([12, 0]))
            x0 = int((pc[0] - 14) * scale); x1 = int((pc[0] + 14) * scale)
            rows = np.nonzero(al[:, max(0, x0):x1].sum(1) >= 3 * scale)[0]
            if len(rows):
                out[ft] = rows.max() / scale
    return out


def head_mask(char, kind, i, n, W, H):
    c = patches(char, kind, i, n)[1]['head'][0]
    if char == 'eng':
        r1, r2 = 30.0, 46.0
    else:
        r1, r2 = 40.0, 62.0
    yy, xx = np.mgrid[0:H, 0:W]
    d = np.hypot(xx - c[0], yy - c[1])
    m = np.clip((r2 - d) / (r2 - r1), 0, 1)
    return m * m * (3 - 2 * m)


def foot_mask(char, cx, W, H, base, shift=0.0):
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    if char == 'eng':
        hx, fx, y_full, y_zero = 28.0, 12.0, 28.0, 85.0
    else:
        hx, fx, y_full, y_zero = 17.0, 10.0, 22.0, 75.0
    # cover both the old and the new position so nothing is left behind
    cx = cx + shift / 2.0; hx = hx + abs(shift) / 2.0
    mx = np.clip((hx + fx - np.abs(xx - cx)) / fx, 0, 1)
    up = base - yy
    my = np.clip((y_zero - up) / (y_zero - y_full), 0, 1)
    m = mx * my
    return m * m * (3 - 2 * m)


def render_lin(f, W, H, px, base, kk, rx, ry, dx=0.0, dy=0.0):
    """Premultiplied linear colour (H, W, 3) and alpha (H, W), float, no quantisation."""
    bx0 = rx + (0 - px - dx) / kk
    by0 = ry + (0 - base - dy) / kk
    bx1 = bx0 + W / kk; by1 = by0 + H / kk
    a_full = f['a'].astype(np.float32)
    Pd = 16
    cx0 = int(math.floor(bx0)) - Pd; cy0 = int(math.floor(by0)) - Pd
    cx1 = int(math.ceil(bx1)) + Pd; cy1 = int(math.ceil(by1)) + Pd
    hh, ww = a_full.shape
    a = np.zeros((cy1 - cy0, cx1 - cx0), np.float32)
    colw = np.zeros((cy1 - cy0, cx1 - cx0, 3), np.float64)
    sx0, sy0, sx1, sy1 = max(0, cx0), max(0, cy0), min(ww, cx1), min(hh, cy1)
    a[sy0 - cy0:sy1 - cy0, sx0 - cx0:sx1 - cx0] = a_full[sy0:sy1, sx0:sx1]
    colw[sy0 - cy0:sy1 - cy0, sx0 - cx0:sx1 - cx0] = f['col'][sy0:sy1, sx0:sx1]
    box = (bx0 - cx0, by0 - cy0, bx1 - cx0, by1 - cy0)
    lin = P.to_lin(colw).astype(np.float32) * a[..., None]
    chans = [np.asarray(Image.fromarray(np.ascontiguousarray(lin[..., c]), 'F').resize((W, H), Image.LANCZOS, box=box)) for c in range(3)]
    A = np.asarray(Image.fromarray(a, 'F').resize((W, H), Image.LANCZOS, box=box))
    return np.stack(chans, -1), A


def finish(lin, A):
    A = np.clip(A, 0, 1)
    rgb = P.to_srgb(np.clip(lin, 0, None) / np.maximum(A[..., None], 1e-4))
    A8 = np.round(A * 255)
    inside = ndimage.distance_transform_edt(A8 >= 128)
    A8 = np.where(inside >= 2.5, 255, A8)
    A8 = np.where(A8 < 3, 0, A8)
    rgb = np.where(A8[..., None] > 0, rgb, 0)
    return np.dstack([np.round(np.clip(rgb, 0, 255)), A8]).astype(np.uint8)


def render_local(f, sp, char, kind, i, n, ss=2):
    """Body transform plus local re-seats (head, planted feet) applied as one smooth
    displacement field (a bend, not a cross-fade, so nothing is doubled). Rendered at ss x,
    warped with cubic sampling in premultiplied linear light, then reduced with Lanczos."""
    W, H = sp['W'], sp['H']
    regions = []
    rs = f.get('reseat', np.zeros(2))
    if np.hypot(*rs) >= 0.15:
        regions.append((np.asarray(rs, float), head_mask(char, kind, i, n, W, H)))
    for fr in f.get('foot_reseat', []):
        sh = np.array(fr['shift'], float)
        if np.hypot(*sh) >= 0.15:
            regions.append((sh, foot_mask(char, fr['cx'], W, H, sp['base'], sh[0])))
    lin, A = render_lin(f, W * ss, H * ss, sp['px'] * ss, sp['base'] * ss, f['kk'] * ss, f['rx'], f['ry'], f['dx'] * ss, f['dy'] * ss)
    if regions:
        ms = np.stack([r[1] for r in regions], 0)
        tot = ms.sum(0)
        ms = np.where(tot[None] > 1, ms / np.maximum(tot[None], 1e-6), ms)
        dxf = sum(r[0][0] * m for r, m in zip(regions, ms)); dyf = sum(r[0][1] * m for r, m in zip(regions, ms))
        # displacement field at ss resolution
        dxs = np.asarray(Image.fromarray(dxf.astype(np.float32), 'F').resize((W * ss, H * ss), Image.BILINEAR)) * ss
        dys = np.asarray(Image.fromarray(dyf.astype(np.float32), 'F').resize((W * ss, H * ss), Image.BILINEAR)) * ss
        yy, xx = np.mgrid[0:H * ss, 0:W * ss].astype(np.float32)
        coords = [yy - dys, xx - dxs]
        A = ndimage.map_coordinates(A, coords, order=3, mode='constant', cval=0.0)
        lin = np.stack([ndimage.map_coordinates(lin[..., c], coords, order=3, mode='constant', cval=0.0) for c in range(3)], -1)
    # reduce to the final cell
    chans = [np.asarray(Image.fromarray(np.ascontiguousarray(lin[..., c]).astype(np.float32), 'F').resize((W, H), Image.LANCZOS)) for c in range(3)]
    A = np.asarray(Image.fromarray(np.ascontiguousarray(A).astype(np.float32), 'F').resize((W, H), Image.LANCZOS))
    return finish(np.stack(chans, -1), A)


def foot_patch(char, kind, i, n, ft, base):
    if char == 'eng':
        J = rig.eng_pose(kind, i, n)
        if not J[ft + '_stance']:
            return None
        heel = eng_cell(J[ft + '_heel']); toe = eng_cell(J[ft + '_toe'])
        return np.array([(heel[0] + toe[0]) / 2, base - 11.0]), (abs(toe[0] - heel[0]) + 10, 24)
    J = rig.wolf_pose(kind, i, n)
    if not J[ft + '_stance']:
        return None
    pc = wolf_cell(J[ft + '_paw'] + np.array([12, 0]))
    return np.array([pc[0], base - 9.0]), (32, 20)


def stance_runs(char, kind, n, ft):
    st = []
    for i in range(n):
        st.append(foot_patch(char, kind, i, n, ft, 0) is not None)
    if all(st):
        return [list(range(n))]
    # rotate so frame list starts right after a swing frame
    start = next(i for i in range(n) if not st[i])
    runs, cur = [], []
    for k in range(1, n + 1):
        i = (start + k) % n
        if st[i]:
            cur.append(i)
        elif cur:
            runs.append(cur); cur = []
    if cur:
        runs.append(cur)
    return runs


def eng_edges(img, base, lo, hi, scale=1):
    """Heel (min x) and toe (max x) of the sole touching the ground in [lo, hi] (cell px)."""
    al = img[..., 3] >= 128
    y0 = int((base - 5) * scale); y1 = int((base + 1) * scale)
    x0 = max(0, int(lo * scale)); x1 = int(hi * scale)
    cols = np.nonzero(al[y0:y1, x0:x1].sum(0) >= 2 * scale)[0]
    if not len(cols):
        return None
    return (x0 + cols.min()) / scale, (x0 + cols.max() + 1) / scale


def foot_track(fts, imgs, char, kind, n, ft, run, base):
    """Positions (cell px, absolute) of the planted part of one foot over a stance run.
    Engineer: heel edge across heel-strike steps, toe edge across toe-off steps, NCC of the
    boot across flat steps. WOLF: NCC of the paw."""
    M = [None]
    p0 = foot_patch(char, kind, run[0], n, ft, base)
    M[0] = float(p0[0][0])
    info = []
    for a_, b_ in zip(run[:-1], run[1:]):
        pa = foot_patch(char, kind, a_, n, ft, base); pb = foot_patch(char, kind, b_, n, ft, base)
        r = M[-1] - pa[0][0]  # current residual (measured - designed centre)
        mode = 'ncc'
        if char == 'eng':
            Ja = rig.eng_pose(kind, a_, n); Jb = rig.eng_pose(kind, b_, n)
            pta = math.degrees(Ja[ft + '_pitch']); ptb = math.degrees(Jb[ft + '_pitch'])
            if pta > 4 or ptb > 4:
                mode = 'heel'
            elif pta < -4 or ptb < -4:
                mode = 'toe'
        step = None
        if mode != 'ncc':
            ea = []; 
            for i_, J_, pp in ((a_, Ja, pa), (b_, Jb, pb)):
                hx = eng_cell(J_[ft + '_heel'])[0]; tx = eng_cell(J_[ft + '_toe'])[0]
                lo, hi = min(hx, tx) + r - 12, max(hx, tx) + r + 12
                e = eng_edges(imgs[i_], base, lo, hi, scale=WK)
                ea.append(None if e is None else (e[0] - min(hx, tx), e[1] - max(hx, tx)))
            if ea[0] is not None and ea[1] is not None:
                k_ = 0 if mode == 'heel' else 1
                # residual change of the planted edge, converted to a centre step
                step = (pb[0][0] - pa[0][0]) + (ea[1][k_] - ea[0][k_])
            else:
                mode = 'ncc'
        if step is None:
            ca = np.array([M[-1], pa[0][1]])
            off, sc = ncc_track(fts[a_], fts[b_], ca * WK, np.array([pb[0][0] + r, pb[0][1]]) * WK,
                                (pa[1][0] * WK, pa[1][1] * WK), R=22)
            if off is None or sc < 0.3:
                off = np.zeros(2)
            step = (pb[0][0] - pa[0][0]) + off[0] / WK
        M.append(M[-1] + step)
        info.append(mode)
    return M, info


def feet_stage(frames, char, kind, n, sp, max_shift=16.0, max_dy=5.0, passes=3):
    """Re-seat planted feet so each stays fixed on the moving ground. Iterative: measure on the
    current result, add the remaining correction, repeat."""
    base = sp['base']
    feet = ('near', 'far') if char == 'eng' else ('RH', 'RF', 'LH', 'LF')
    runs = {ft: stance_runs(char, kind, n, ft) for ft in feet}
    for f in frames:
        f['foot_reseat'] = []
    v = None
    for ps in range(passes):
        finals = [render_local(f, sp, char, kind, i, n) for i, f in enumerate(frames)]
        imgs = [np.asarray(Image.fromarray(im).resize((im.shape[1] * WK, im.shape[0] * WK), Image.LANCZOS)) for im in finals]
        fts = [feat(im) for im in imgs]
        meas = {}; steps = []
        for ft in feet:
            for run in runs[ft]:
                M, info = foot_track(fts, imgs, char, kind, n, ft, run, base)
                steps += list(np.diff(M))
                meas[(ft, tuple(run))] = M
        if v is None:
            v = 0.0 if kind == 'idle' or not steps else -float(np.median(steps))
        for (ft, run), M in meas.items():
            M = np.array(M); k = np.arange(len(M))
            A_ = float(np.mean(M + v * k))
            c = A_ - v * k - M
            for kk_, i in enumerate(run):
                ent = next((e for e in frames[i]['foot_reseat'] if e['foot'] == ft), None)
                if ent is None:
                    cxm = float(M[kk_])
                    if char == 'eng':
                        J = rig.eng_pose(kind, i, n)
                        hx_ = eng_cell(J[ft + '_heel'])[0]; tx_ = eng_cell(J[ft + '_toe'])[0]
                        r_ = M[kk_] - (hx_ + tx_) / 2
                        e = eng_edges(imgs[i], base, min(hx_, tx_) + r_ - 16, max(hx_, tx_) + r_ + 16, scale=WK)
                        if e is not None:
                            cxm = (e[0] + e[1]) / 2
                            if J[ft + '_pitch'] < math.radians(-4):
                                cxm -= 10.0  # toe-off: the raised heel sits behind the sole contact
                    ent = dict(foot=ft, cx=cxm, shift=[0.0, 0.0]); frames[i]['foot_reseat'].append(ent)
                    sx_now = 0.0
                else:
                    sx_now = ent['shift'][0]
                ent['shift'][0] = float(np.clip(sx_now + c[kk_] * (1.0 if ps < passes - 1 else 1.0), -max_shift, max_shift))
                # vertical: the planted foot must touch the baseline
                cur_x = M[kk_] + c[kk_]
                x0 = int((cur_x - 22) * WK); x1 = int((cur_x + 22) * WK)
                al = imgs[i][..., 3] >= 128
                rows = np.nonzero(al[:, max(0, x0):x1].sum(1) >= 3 * WK)[0]
                gy = (base - (rows.max() + 1) / WK + 0.5) if len(rows) else 0.0
                ent['shift'][1] = float(np.clip(ent['shift'][1] + gy, -max_dy, max_dy))
    out = sorted((i, e['foot'], round(e['shift'][0], 2), round(e['shift'][1], 2)) for i, f in enumerate(frames) for e in f['foot_reseat'])
    return v, out


def register(rowkey, iters=7, vert_w=VERT_W, ref_frame=0):
    meta = G[rowkey]; char = meta['char']; kind = meta['kind']; n = meta['n']
    sp = SPEC[char]
    frames = extract(rowkey)
    s_row = float(np.median([f['fit_free'][0] for f in frames]))
    k = sp['k']
    for f in frames:
        s = s_row
        _, tx, ty, iou = P.iou_fit(f['pm'], f['gm'], [s])
        ox, oy = f['fr']['origin']
        gx = ox * f['sx'] - f['win'][0]; gy = oy * f['sy'] - f['win'][1]
        f['rx'] = s * gx + tx + f['win'][0]; f['ry'] = s * gy + ty + f['win'][1]
        f['kk'] = k / (s * f['sx']); f['iou_row_scale'] = iou
        f['dx'] = 0.0; f['dy'] = 0.0
    W2, H2 = sp['W'] * WK, sp['H'] * WK
    log = []
    for it in range(iters):
        imgs = [render(f, W2, H2, sp['px'] * WK, sp['base'] * WK, f['kk'] * WK, f['rx'], f['ry'], f['dx'] * WK, f['dy'] * WK) for f in frames]
        fts = [feat(im) for im in imgs]
        names = list(patches(char, kind, 0, n)[1].keys())
        pos = {}; wts = {}; recs = [dict() for _ in range(n)]
        for nm in names:
            steps = []; scs = []
            for i in range(n):
                j = (i + 1) % n
                ci, size, wt = patches(char, kind, i, n)[1][nm]
                cj = patches(char, kind, j, n)[1][nm][0]
                off, sc = ncc_track(fts[i], fts[j], ci * WK, cj * WK, (size[0] * WK, size[1] * WK), R=36)
                if off is None:
                    off, sc = np.zeros(2), 0.0
                steps.append(off / WK); scs.append(sc)
                recs[j][nm] = (round(float(off[0] / WK), 2), round(float(off[1] / WK), 2), round(sc, 3))
            st = np.array(steps); clos = st.sum(0)
            # loop closure: spread the summed error evenly over the steps
            p = np.cumsum(np.vstack([[0.0, 0.0], st[:-1] - clos / n]), 0)
            # p[i] is the residual of frame i relative to frame 0
            pos[nm] = p - p.mean(0)
            wts[nm] = wt * max(0.05, float(np.mean(scs))) ** 2
            recs[0].setdefault('_closure', {})[nm] = [round(float(c), 2) for c in clos]
        tot = sum(wts.values())
        res = sum(pos[nm] * wts[nm] for nm in names) / tot
        scale_log = None
        if char == 'wolf' and it < 3:
            # per-sheet size: the withers-to-croup distance must be the same in every sheet
            Ld = float((patches(char, kind, 0, n)[1]['withers'][0] - patches(char, kind, 0, n)[1]['croup'][0])[0])
            L = pos['withers'][:, 0] - pos['croup'][:, 0]
            sheets = sorted(set(f['sheet'] for f in frames))
            scale_log = {}
            for sh in sheets:
                idx = [i for i, f in enumerate(frames) if f['sheet'] == sh]
                fac = 1.0 - float(np.mean(L[idx])) / Ld
                scale_log[sh] = round(fac, 4)
                for i in idx:
                    frames[i]['kk'] *= fac
        damp = 1.0 if it == 0 else 0.7
        for i, f in enumerate(frames):
            f['dx'] -= damp * res[i, 0]
            f['dy'] -= damp * res[i, 1]
            f['track'] = recs[i]
        log.append(dict(iter=it, weights={k: round(v / tot, 3) for k, v in wts.items()},
                        max_abs_residual=[round(float(v), 2) for v in np.abs(res).max(0)], sheet_scale=scale_log,
                        patch_residual_x={nm: [round(float(v), 1) for v in pos[nm][:, 0]] for nm in names},
                        patch_residual_y={nm: [round(float(v), 1) for v in pos[nm][:, 1]] for nm in names}))
    # head re-seat: the head may sit a few px off the body in some painted frames (the sheets
    # were painted separately). Keep only the smooth once-per-step part of the head's motion
    # relative to the body (harmonic KEEP of the cycle) and move the head by the rest.
    hres = pos['head'].copy()
    keep = 1 if kind == 'idle' else 0
    t = np.arange(n) / n
    smooth_part = np.zeros_like(hres)
    for c in range(2 if keep else 0):
        z = hres[:, c]
        a = 2 * np.mean(z * np.cos(2 * np.pi * keep * t)); b = 2 * np.mean(z * np.sin(2 * np.pi * keep * t))
        smooth_part[:, c] = a * np.cos(2 * np.pi * keep * t) + b * np.sin(2 * np.pi * keep * t)
    reseat = np.clip(-(hres - smooth_part), -RESEAT_MAX, RESEAT_MAX)
    for i, f in enumerate(frames):
        f['reseat'] = reseat[i]
    log.append(dict(head_reseat_x=[round(float(v), 2) for v in reseat[:, 0]], head_reseat_y=[round(float(v), 2) for v in reseat[:, 1]],
                    head_kept_x=[round(float(v), 2) for v in smooth_part[:, 0]], head_kept_y=[round(float(v), 2) for v in smooth_part[:, 1]]))
    # vertical: contact feet vs baseline
    imgs = [render(f, sp['W'] * WK, sp['H'] * WK, sp['px'] * WK, sp['base'] * WK, f['kk'] * WK, f['rx'], f['ry'], f['dx'] * WK, f['dy'] * WK) for f in frames]
    gaps = []
    for i, (f, im) in enumerate(zip(frames, imgs)):
        lows = contact_low(im, char, kind, i, n, scale=WK)
        # a planted foot must touch: the lowest planted foot defines the ground contact
        gaps.append(sp['base'] - max(lows.values()) if lows else None)
    gv = np.array([g for g in gaps if g is not None], float)
    row_shift = float(np.median(gv)) if len(gv) else 0.0  # one shift for the whole row
    foot = []
    for i, g in enumerate(gaps):
        # per-frame residual after the row shift; only a share is applied (vert_w)
        foot.append((g - row_shift) if g is not None else None)
    # flight frames: interpolate the per-frame foot term from neighbours (cyclic)
    fv = np.array([np.nan if v is None else v for v in foot], float)
    if np.isnan(fv).any() and (~np.isnan(fv)).any():
        idx = np.arange(n); good = ~np.isnan(fv)
        fv = np.interp(idx, np.concatenate([idx[good] - n, idx[good], idx[good] + n]),
                       np.concatenate([fv[good]] * 3))
    elif np.isnan(fv).all():
        fv = np.zeros(n)
    for i, f in enumerate(frames):
        f['dy'] += row_shift + vert_w * fv[i]
    v_fit, foot_log = feet_stage(frames, char, kind, n, sp) if FEET else (None, [])
    out_dir = os.path.join(ROOT, 'frames', rowkey); os.makedirs(out_dir, exist_ok=True)
    finals = []
    for i, f in enumerate(frames):
        rgba = render_local(f, sp, char, kind, i, n)
        Image.fromarray(rgba).save(os.path.join(out_dir, 'frame_%02d.png' % f['frame']))
        finals.append(rgba)
    cols = 4; rows = int(math.ceil(n / cols))
    sheet = Image.new('RGBA', (sp['W'] * cols, sp['H'] * rows), (0, 0, 0, 0))
    for i, im in enumerate(finals):
        sheet.paste(Image.fromarray(im), ((i % cols) * sp['W'], (i // cols) * sp['H']))
    sheet.save(os.path.join(ROOT, 'frames', rowkey + '-sheet.png'))
    rep = dict(row=rowkey, method='register.py v2: row scale + body-patch NCC hip lock + contact baseline',
               s_row=round(s_row, 4), vert_w=vert_w, row_shift=round(row_shift, 2), log=log,
               matte=frames[0]['matte'],
               frames=[dict(frame=f['frame'], sheet=f['sheet'], free_scale=round(float(f['fit_free'][0]), 4), iou=round(float(f['iou_row_scale']), 4),
                            dx=round(float(f['dx']), 2), dy=round(float(f['dy']), 2), kk=round(float(f['kk']), 5), head_reseat=[round(float(v), 2) for v in f.get('reseat', [0, 0])], foot_gap_before=None if gaps[i] is None else round(float(gaps[i]), 2),
                            track=f['track']) for i, f in enumerate(frames)])
    rep['mean_snap'] = 0.0
    rep['ground_cell_px_per_frame'] = v_fit
    rep['foot_reseat'] = foot_log
    json.dump(rep, open(os.path.join(ROOT, 'qa', rowkey + '-process.json'), 'w'), indent=1)
    return rep


if __name__ == '__main__':
    vw = VERT_W
    rows = []
    for a in sys.argv[1:]:
        if a.startswith('--vert='):
            vw = float(a.split('=')[1])
        else:
            rows.append(a)
    for r in rows:
        rep = register(r, vert_w=vw)
        print(r, 's_row', rep['s_row'], 'row_shift', rep['row_shift'], rep['log'])
        for fr in rep['frames']:
            print('  ', fr['frame'], 'dx', fr['dx'], 'dy', fr['dy'], 'gap', fr['foot_gap_before'], fr['track'])
