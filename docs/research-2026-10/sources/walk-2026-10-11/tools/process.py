"""Extract, matte, register and measure painted animation rows.

usage: process.py ROWKEY [ROWKEY ...]      e.g. eng-walk wolf-trot
Reads guides/guides.json + raw/<sheet>.png, writes frames/<row>/frame_XX.png, sheets,
and qa/<row>.json with registration, drift, slide and seam numbers.
"""
import json, math, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage
from scipy.signal import fftconvolve

sys.path.insert(0, os.path.dirname(__file__))
import rig

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
G = json.load(open(os.path.join(ROOT, 'guides', 'guides.json')))

SPEC = {
    # final cell, baseline row, pivot x, final px per guide px
    'eng': dict(W=256, H=320, base=311, px=128, k=280.0 / 460.0, figure=280),
    'wolf': dict(W=512, H=272, base=263, px=293, k=(460.0 / 1550.0) / (690.0 / 1550.0), figure=460),
}


# ------------------------------------------------------------------ colour
def to_lin(c):
    c = c / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def to_srgb(l):
    l = np.clip(l, 0, 1)
    return np.where(l <= 0.0031308, l * 12.92, 1.055 * l ** (1 / 2.4) - 0.055) * 255.0


def matte(rgb):
    """Unmix a flat magenta key. Returns (colour float RGB 0-255, alpha 0-1, report)."""
    P = rgb.astype(np.float64)
    h, w, _ = P.shape
    border = np.concatenate([P[:6].reshape(-1, 3), P[-6:].reshape(-1, 3), P[:, :6].reshape(-1, 3), P[:, -6:].reshape(-1, 3)])
    K = np.median(border, axis=0)
    noise = float(np.percentile(np.linalg.norm(border - K, axis=1), 99))
    d = np.linalg.norm(P - K, axis=2)
    bg_t = max(noise * 1.6, 18.0)
    fig = d > 110.0
    # deep core: >= 3 px inside the figure; its colours are free of key spill
    core = ndimage.binary_erosion(fig, iterations=3)
    bg = d < bg_t
    dist, idx = ndimage.distance_transform_edt(~core, return_indices=True)
    C = P[idx[0], idx[1]]
    # alpha from the key's magenta signature m = min(R,B) - G, which mixes ~linearly:
    # m(P) = a*m(F) + (1-a)*m(K). m(F) is taken from the nearest deep-core colour, capped,
    # so a cyan rim (m << 0) is not mistaken for partial transparency.
    mK = min(K[0], K[2]) - K[1]
    mP = np.minimum(P[..., 0], P[..., 2]) - P[..., 1]
    mF = np.minimum(np.minimum(C[..., 0], C[..., 2]) - C[..., 1], 30.0)
    a = np.clip((mK - mP) / np.maximum(mK - mF, 1.0), 0, 1)
    a[core] = 1.0
    a[bg] = 0.0
    a[(dist > 6) & ~core] = 0.0
    out = np.where(a[..., None] > 0.02, (P - (1 - a[..., None]) * K) / np.maximum(a[..., None], 0.02), C)
    out = np.clip(out, 0, 255)
    # residual magenta spill on the outer band: remove only the excess along the magenta chroma
    # axis m=(1,-2,1)/sqrt6 relative to the nearest deep-core colour (no push toward green/cyan)
    band = (~core) & (a > 0)
    m = np.array([1.0, -2.0, 1.0]) / math.sqrt(6)
    proj = np.einsum('ijk,k->ij', out - C, m)
    proj = np.where(band & (proj > 0), proj, 0.0)
    out = np.clip(out - proj[..., None] * m, 0, 255)
    # final colour: soft alpha from above, RGB extended outward from >= 2 px inside the figure,
    # so no key colour can remain in edge pixels and no unmixing error can tint them
    inner = ndimage.binary_erosion(fig, iterations=2)
    di, ix = ndimage.distance_transform_edt(~inner, return_indices=True)
    out = np.where(inner[..., None], P, P[ix[0], ix[1]])
    rep = dict(key=[round(float(x), 1) for x in K], bg_noise_p99=round(noise, 2), bg_threshold=round(bg_t, 1), matte='magenta-signature alpha + interior colour extension (2 px)')
    return out, a, rep


def clean_alpha(a, min_island):
    m = a > 0.5
    lab, n = ndimage.label(m)
    sizes = ndimage.sum(m, lab, range(1, n + 1))
    keep = np.zeros(n + 1, bool)
    keep[1:] = sizes >= min_island
    km = keep[lab]
    # pixels of partial alpha attached to kept components
    grown = ndimage.binary_dilation(km, iterations=3)
    a = np.where(grown, a, 0.0)
    # solid interior: >=2 px inside and alpha>=0.94 -> 1; >=3 px inside -> 1
    inside = ndimage.distance_transform_edt(a > 0.5)
    a = np.where((inside >= 2) & (a >= 0.94), 1.0, a)
    a = np.where(inside >= 3, 1.0, a)
    # fill enclosed holes (accidental see-through)
    # only tiny enclosed specks (<= 12 px) are treated as accidental holes; larger enclosed
    # key areas (between legs, arm and body) stay transparent
    holes = ndimage.binary_fill_holes(a > 0.5) & (a <= 0.5)
    hl, hn = ndimage.label(holes)
    if hn:
        hs = ndimage.sum(holes, hl, range(1, hn + 1))
        small = np.zeros(hn + 1, bool); small[1:] = hs <= 12
        a = np.where(small[hl] & holes, 1.0, a)
    return a, lab, km


# ------------------------------------------------------------------ fitting
def iou_fit(pm, gm, scales):
    """pm: painted mask (cell window), gm: guide mask (same window). Find s, t maximising
    IoU of pm against gm scaled by s about the window origin then shifted by t. Returns
    (s, tx, ty, iou) with painted ~ s*guide + t."""
    best = None
    Ap = pm.sum()
    for s in scales:
        gs = np.asarray(Image.fromarray((gm * 255).astype(np.uint8)).resize(
            (max(1, int(round(gm.shape[1] * s))), max(1, int(round(gm.shape[0] * s)))), Image.BILINEAR)) > 127
        Ag = gs.sum()
        corr = fftconvolve(pm.astype(np.float32), gs[::-1, ::-1].astype(np.float32), mode='full')
        iy, ix = np.unravel_index(np.argmax(corr), corr.shape)
        inter = corr[iy, ix]
        iou = inter / (Ap + Ag - inter)
        ty = iy - (gs.shape[0] - 1); tx = ix - (gs.shape[1] - 1)
        if best is None or iou > best[3]:
            best = (s, float(tx), float(ty), float(iou))
    return best


def subpixel_refine(pm, gm, s, tx, ty):
    # refine translation to 0.25 px with a small search on the distance-weighted overlap
    gs = np.asarray(Image.fromarray((gm * 255).astype(np.uint8)).resize(
        (int(round(gm.shape[1] * s)), int(round(gm.shape[0] * s))), Image.BILINEAR)).astype(np.float32) / 255
    best = (-1, tx, ty)
    H, W = pm.shape
    for dy in np.arange(-1, 1.01, 0.25):
        for dx in np.arange(-1, 1.01, 0.25):
            M = np.float32([[1, 0, tx + dx], [0, 1, ty + dy]])
            g2 = ndimage.affine_transform(gs, np.array([[1, 0], [0, 1]]), offset=(-(ty + dy), -(tx + dx)),
                                          output_shape=(H, W), order=1)
            inter = np.minimum(g2, pm).sum(); uni = np.maximum(g2, pm).sum()
            v = inter / uni
            if v > best[0]:
                best = (v, tx + dx, ty + dy)
    return best[1], best[2], float(best[0])


# ------------------------------------------------------------------ main
def process(rowkey, opts):
    meta = G[rowkey]
    char = meta['char']; kind = meta['kind']; n = meta['n']
    sp = SPEC[char]
    out_dir = os.path.join(ROOT, 'frames', rowkey); os.makedirs(out_dir, exist_ok=True)
    qa_dir = os.path.join(ROOT, 'qa'); os.makedirs(qa_dir, exist_ok=True)
    frames = []
    rep = dict(row=rowkey, sheets=[], frames=[])
    for sheet in meta['sheets']:
        rawp = os.path.join(ROOT, 'raw', sheet['file'])
        im = Image.open(rawp).convert('RGB')
        gim = Image.open(os.path.join(ROOT, 'guides', sheet['file'])).convert('RGB')
        sx = im.width / gim.width; sy = im.height / gim.height
        if abs(sx - 1) > 1e-6 or abs(sy - 1) > 1e-6:
            gim = gim.resize(im.size, Image.LANCZOS)
        rgb = np.asarray(im)
        col, a, mrep = matte(rgb)
        a, lab, km = clean_alpha(a, min_island=int(600 * sx * sy))
        g = np.asarray(gim).astype(int)
        gmask = np.abs(g - [255, 0, 255]).sum(2) > 90
        rep['sheets'].append(dict(file=sheet['file'], raw_size=list(im.size), scale_xy=[sx, sy], **mrep))
        # component ownership by cell (centroid)
        labs = ndimage.label(a > 0.5)[0]
        for fr in sheet['frames']:
            x0, y0, x1, y1 = fr['cell']
            X0, Y0, X1, Y1 = x0 * sx, y0 * sy, x1 * sx, y1 * sy
            # window = cell
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
            # fit (in raw px) on the cell window with margin
            m = 40
            wy0m, wy1m = max(0, wy0 - m), min(a.shape[0], wy1 + m)
            wx0m, wx1m = max(0, wx0 - m), min(a.shape[1], wx1 + m)
            pm = (fa[wy0m:wy1m, wx0m:wx1m] > 0.5).astype(np.float32)
            gm = np.zeros_like(pm)
            gcell = gmask[int(Y0):int(Y1), int(X0):int(X1)]
            gm[int(Y0) - wy0m:int(Y0) - wy0m + gcell.shape[0], int(X0) - wx0m:int(X0) - wx0m + gcell.shape[1]] = gcell
            # IoU fit at half resolution, then refine
            half = lambda z: np.asarray(Image.fromarray((z * 255).astype(np.uint8)).resize((z.shape[1] // 2, z.shape[0] // 2), Image.BILINEAR)) / 255.0
            ph, gh = (half(pm) > 0.5).astype(np.float32), (half(gm) > 0.5).astype(np.float32)
            s, tx, ty, iou = iou_fit(ph, gh, np.arange(0.80, 1.305, 0.02))
            s2, tx2, ty2, iou2 = iou_fit(pm, gm, np.arange(s - 0.02, s + 0.021, 0.005))
            frames.append(dict(frame=fr['frame'], sheet=sheet['file'], fr=fr, col=col, a=fa, pm=pm, gm=gm,
                               win=(wx0m, wy0m), fit_free=(s2, tx2, ty2, iou2), sx=sx, sy=sy))
    frames.sort(key=lambda d: d['frame'])
    s_row = float(np.median([f['fit_free'][0] for f in frames]))
    for f in frames:
        sf = f['fit_free'][0]
        if opts.get('per_frame_scale') or abs(sf / s_row - 1) > 0.03:
            f['fit'] = f['fit_free']
        else:
            f['fit'] = iou_fit(f['pm'], f['gm'], [s_row])
    k = sp['k']
    results = []
    for f in frames:
        fr = f['fr']; s, tx, ty, iou = f['fit']
        s_use = s
        # guide origin (pivot, baseline) in raw coords:  raw = s*(guide_win) + t + win
        ox, oy = fr['origin']
        gx = (ox * f['sx'] - f['win'][0]); gy = (oy * f['sy'] - f['win'][1])
        rx = s * gx + tx + f['win'][0]; ry = s * gy + ty + f['win'][1]
        kk = k / (s_use * f['sx'])
        f.update(rx=rx, ry=ry, kk=kk, s_use=s_use)
    # contact snapping offset (vertical): measure lowest opaque row of contact feet after transform
    rep['s_row'] = s_row
    rendered = []
    for f in frames:
        rgba = render_frame(f, sp, dy=0.0)
        f['rgba0'] = rgba
    # vertical snap per frame (contact frames) and row-mean for flight frames
    snaps = {}
    for f in frames:
        if f['fr']['contacts']:
            lows = []
            for foot, (l, r) in f['fr']['contacts'].items():
                fl = sp['px'] + (l - f['fr']['origin'][0]) * sp['k']
                frr = sp['px'] + (r - f['fr']['origin'][0]) * sp['k']
                al = f['rgba0'][..., 3]
                xs0, xs1 = int(max(0, fl - 6)), int(min(sp['W'], frr + 6))
                cols = al[:, xs0:xs1] >= 128
                rows = np.nonzero(cols.sum(1) >= 3)[0]
                if len(rows):
                    lows.append(rows.max())
            if lows:
                snaps[f['frame']] = float(sp['base'] - max(lows))
    # one vertical offset for the whole row (median of contact-frame snaps): the hip path stays
    # exactly the guide's designed bob; per-frame foot gaps are reported by measure.py
    mean_snap = float(np.median(list(snaps.values()))) if snaps else 0.0
    rep['per_frame_snaps'] = {str(k): v for k, v in snaps.items()}
    for f in frames:
        if opts.get('frame_snap'):
            dy = snaps.get(f['frame'], mean_snap)
        else:
            dy = mean_snap
        f['dy'] = dy
        f['rgba'] = render_frame(f, sp, dy=dy)
        Image.fromarray(f['rgba']).save(os.path.join(out_dir, 'frame_%02d.png' % f['frame']))
    # sheets 4 columns
    cols = 4; rows = int(math.ceil(len(frames) / cols))
    sheet = Image.new('RGBA', (sp['W'] * cols, sp['H'] * rows), (0, 0, 0, 0))
    for f in frames:
        i = f['frame']; sheet.paste(Image.fromarray(f['rgba']), ((i % cols) * sp['W'], (i // cols) * sp['H']))
    sheet.save(os.path.join(ROOT, 'frames', rowkey + '-sheet.png'))
    rep['frames'] = [dict(frame=f['frame'], free_scale=round(f['fit_free'][0], 4), free_iou=round(f['fit_free'][3], 4), iou=round(f['fit'][3], 4),
                          scale_used=round(f['s_use'], 4), snap_dy=round(float(f['dy']), 2)) for f in frames]
    rep['mean_snap'] = mean_snap
    json.dump(rep, open(os.path.join(qa_dir, rowkey + '-process.json'), 'w'), indent=1)
    return rep


def render_frame(f, sp, dy=0.0):
    """Resample the frame's premultiplied linear colour into the final cell with Lanczos (area-ish)."""
    W, H = sp['W'], sp['H']
    kk = f['kk']
    # final = (raw - (rx, ry)) * kk + (px, base + dy)  -> raw box for the final cell
    bx0 = f['rx'] + (0 - sp['px']) / kk
    by0 = f['ry'] + (0 - sp['base'] - dy) / kk
    bx1 = bx0 + W / kk; by1 = by0 + H / kk
    a_full = f['a'].astype(np.float32)
    # crop a padded window that contains the box
    P = 16
    cx0 = int(math.floor(bx0)) - P; cy0 = int(math.floor(by0)) - P
    cx1 = int(math.ceil(bx1)) + P; cy1 = int(math.ceil(by1)) + P
    hh, ww = a_full.shape
    a = np.zeros((cy1 - cy0, cx1 - cx0), np.float32)
    colw = np.zeros((cy1 - cy0, cx1 - cx0, 3), np.float64)
    sx0, sy0, sx1, sy1 = max(0, cx0), max(0, cy0), min(ww, cx1), min(hh, cy1)
    a[sy0 - cy0:sy1 - cy0, sx0 - cx0:sx1 - cx0] = a_full[sy0:sy1, sx0:sx1]
    colw[sy0 - cy0:sy1 - cy0, sx0 - cx0:sx1 - cx0] = f['col'][sy0:sy1, sx0:sx1]
    box = (bx0 - cx0, by0 - cy0, bx1 - cx0, by1 - cy0)
    lin = to_lin(colw).astype(np.float32) * a[..., None]
    chans = []
    for c in range(3):
        chans.append(np.asarray(Image.fromarray(np.ascontiguousarray(lin[..., c]), 'F').resize((W, H), Image.LANCZOS, box=box)))
    A = np.asarray(Image.fromarray(a, 'F').resize((W, H), Image.LANCZOS, box=box))
    A = np.clip(A, 0, 1)
    rgb = np.stack(chans, -1) / np.maximum(A[..., None], 1e-4)
    rgb = to_srgb(rgb)
    A8 = np.round(A * 255)
    # interior solid: >= 2 px inside -> 255
    inside = ndimage.distance_transform_edt(A8 >= 128)
    A8 = np.where(inside >= 2.5, 255, A8)
    A8 = np.where(A8 < 3, 0, A8)
    rgb = np.where(A8[..., None] > 0, rgb, 0)
    out = np.dstack([np.round(rgb), A8]).astype(np.uint8)
    return out


if __name__ == '__main__':
    opts = {}
    keys = [k for k in sys.argv[1:] if not k.startswith('--')]
    for kk in sys.argv[1:]:
        if kk.startswith('--'):
            opts[kk[2:].replace('-', '_')] = True
    for key in keys:
        r = process(key, opts)
        print(key, 's_row=%.3f' % r['s_row'], 'mean_snap=%.2f' % r['mean_snap'])
        for fr in r['frames']:
            print('  ', fr)
