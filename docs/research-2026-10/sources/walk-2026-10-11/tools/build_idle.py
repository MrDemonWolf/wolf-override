"""WOLF idle v2: one standing key pose repainted by Codex (edit mode) with only breath, head,
ear and tail changes. Paws are locked: every cell is aligned to the key pose on its paw band,
then the paw band of the key pose is used in every frame (feathered), so the stance cannot drift.
Placement: same scale and baseline as the registered rows (fit to the old idle frame 4, which
was itself registered to the fixed hip point and baseline row 263).

usage: build_idle.py
"""
import json, math, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
import process as P

ROOT = P.ROOT
CELLS = [(0, 0, 836, 470), (836, 0, 1672, 470), (0, 470, 836, 940), (836, 470, 1672, 940)]
# order chosen so the head travels key -> up -> key -> slightly low -> low -> key (no up-to-down snap)
SEQ = [('wolf-idle-bA.png', 0), ('wolf-idle-bA.png', 1), ('wolf-idle-bA.png', 2), ('wolf-idle-bB.png', 0),
       ('wolf-idle-bB.png', 1), ('wolf-idle-bA.png', 3), ('wolf-idle-bB.png', 2), ('wolf-idle-bB.png', 3)]
# ms per frame; holds on the breath peak and the floor scan, about 2.85 s per loop
DUR = [400, 300, 450, 300, 350, 300, 450, 300]
KEEP_Y = 0.4  # share of each repaint's torso rise that is kept as breathing
W, H, BASE = 512, 272, 263


def cut(sheet):
    rgb = np.asarray(Image.open(os.path.join(ROOT, 'raw', sheet)).convert('RGB'))
    col, a, rep = P.matte(rgb)
    a, lab, km = P.clean_alpha(a, min_island=600)
    out = []
    labs = ndimage.label(a > 0.5)[0]
    for (x0, y0, x1, y1) in CELLS:
        ids = [i for i in np.unique(labs[y0:y1, x0:x1]) if i > 0]
        own = np.zeros_like(a, bool)
        for i in ids:
            ys, xs = np.nonzero(labs == i)
            if x0 <= xs.mean() < x1 and y0 <= ys.mean() < y1 and len(xs) > 200:
                own |= labs == i
        own = ndimage.binary_dilation(own, iterations=4) & (a > 0)
        aa = np.where(own, a, 0.0)[y0:y1, x0:x1]
        cc = col[y0:y1, x0:x1]
        out.append((cc, aa))
    return out, rep


def shift_img(arr, dx, dy, order=3):
    if arr.ndim == 2:
        return ndimage.shift(arr, (dy, dx), order=order, mode='constant', cval=0.0)
    return np.stack([ndimage.shift(arr[..., c], (dy, dx), order=order, mode='constant', cval=0.0) for c in range(arr.shape[2])], -1)


def paw_band(a):
    ys = np.nonzero((a > 0.5).sum(1) >= 3)[0]
    bot = ys.max(); top = ys.min()
    return int(bot - 0.22 * (bot - top)), int(bot + 2)


def align(ref, cur, band, cols=None):
    """Integer search then parabolic refine of SSD on alpha + luminance inside the paw band."""
    (rc, ra), (cc, ca) = ref, cur
    y0, y1 = band
    rl = (rc.mean(2) / 255.0) * ra
    cl = (cc.mean(2) / 255.0) * ca
    xa, xb = cols if cols else (0, ra.shape[1])
    R = np.dstack([ra, rl])[y0:y1, xa:xb]
    best = None
    for dy in range(-8, 9):
        for dx in range(-14, 15):
            C = np.dstack([np.roll(np.roll(ca, dy, 0), dx, 1), np.roll(np.roll(cl, dy, 0), dx, 1)])[y0:y1, xa:xb]
            e = float(((C - R) ** 2).sum())
            if best is None or e < best[0]:
                best = (e, dx, dy)
    _, bx, by = best

    def err(dx, dy):
        C = np.dstack([shift_img(ca, dx, dy, 1), shift_img(cl, dx, dy, 1)])[y0:y1, xa:xb]
        return float(((C - R) ** 2).sum())
    e0 = err(bx, by)
    ex = [err(bx - 1, by), e0, err(bx + 1, by)]; ey = [err(bx, by - 1), e0, err(bx, by + 1)]
    para = lambda v: 0.0 if (v[0] - 2 * v[1] + v[2]) <= 0 else 0.5 * (v[0] - v[2]) / (v[0] - 2 * v[1] + v[2])
    return bx + float(np.clip(para(ex), -0.5, 0.5)), by + float(np.clip(para(ey), -0.5, 0.5)), e0


def render_cell(col, a, kk, ox, oy):
    """final = raw * kk + (ox, oy), premultiplied linear light, Lanczos."""
    PADR = 400
    col = np.pad(col, ((PADR, PADR), (PADR, PADR), (0, 0)), mode='edge')
    a = np.pad(a, PADR)
    bx0 = (0 - ox) / kk + PADR; by0 = (0 - oy) / kk + PADR
    box = (bx0, by0, bx0 + W / kk, by0 + H / kk)
    lin = P.to_lin(col).astype(np.float32) * a[..., None].astype(np.float32)
    ch = [np.asarray(Image.fromarray(np.ascontiguousarray(lin[..., c]), 'F').resize((W, H), Image.LANCZOS, box=box)) for c in range(3)]
    A = np.clip(np.asarray(Image.fromarray(a.astype(np.float32), 'F').resize((W, H), Image.LANCZOS, box=box)), 0, 1)
    rgb = P.to_srgb(np.stack(ch, -1) / np.maximum(A[..., None], 1e-4))
    A8 = np.round(A * 255)
    inside = ndimage.distance_transform_edt(A8 >= 128)
    A8 = np.where(inside >= 2.5, 255, A8)
    A8 = np.where(A8 < 3, 0, A8)
    rgb = np.where(A8[..., None] > 0, rgb, 0)
    return np.dstack([np.round(np.clip(rgb, 0, 255)), A8]).astype(np.uint8)


def main():
    cells = {}
    reps = {}
    for sh in sorted(set(s for s, _ in SEQ)):
        cells[sh], reps[sh] = cut(sh)
    frames = [cells[s][k] for s, k in SEQ]
    ref = frames[0]
    band = paw_band(ref[1])
    rys_, rxs_ = np.nonzero(ref[1] > 0.5)
    fy0, fy1, fx0, fx1 = rys_.min(), rys_.max(), rxs_.min(), rxs_.max()
    torso_band = (int(fy0 + 0.25 * (fy1 - fy0)), int(fy0 + 0.60 * (fy1 - fy0)))
    torso_cols = (int(fx0 + 0.40 * (fx1 - fx0)), int(fx0 + 0.75 * (fx1 - fx0)))
    log = {'matte': reps, 'band_rows': band, 'frames': []}
    aligned = []
    for i, fr in enumerate(frames):
        dx, dy, e = align(ref, fr, band) if i else (0.0, 0.0, 0.0)
        tx = ty = 0.0
        if i:
            # torso (between the tail root and the shoulder, back to belly) relative to the key
            c1 = shift_img(fr[0], dx, dy); a1 = np.clip(shift_img(fr[1], dx, dy), 0, 1)
            tx, ty, _ = align(ref, (c1, a1), torso_band, cols=torso_cols)
            tx, ty = -tx, -ty  # align() returns the shift that maps cur onto ref; torso offset is its negative
        sx = dx - tx; sy = dy - (1 - KEEP_Y) * ty
        c = shift_img(fr[0], sx, sy); a = np.clip(shift_img(fr[1], sx, sy), 0, 1)
        # residual in the paw band after alignment (mean abs, 0-255, over the union of opaque px)
        y0, y1 = band
        u = (a[y0:y1] > 0.5) | (ref[1][y0:y1] > 0.5)
        res = float(np.abs(c[y0:y1] * a[y0:y1, ..., None] - ref[0][y0:y1] * ref[1][y0:y1, ..., None])[u].mean())
        log['frames'].append(dict(frame=i, src=SEQ[i], paw_align=[round(dx, 2), round(dy, 2)], torso_offset=[round(tx, 2), round(ty, 2)],
                                  applied_shift=[round(sx, 2), round(sy, 2)], paw_band_residual=round(res, 2)))
        aligned.append((c, a))
    # paw lock: below the band top use the key pose, feathered over 14 raw px
    y0, y1 = band
    feather = 14
    ys = np.arange(ref[1].shape[0])[:, None]
    wv = np.clip((ys - (y0 - feather)) / feather, 0, 1)  # 0 above, 1 in the paw band
    # only the leg parts that reach the ground (not the tail tip, which can dip into the band)
    bandm = np.zeros_like(ref[1], bool); bandm[y0 - feather:y1] = ref[1][y0 - feather:y1] > 0.5
    lab, nl = ndimage.label(bandm)
    legs = np.zeros_like(bandm)
    for k in range(1, nl + 1):
        rr = np.nonzero(lab == k)[0]
        if rr.max() >= y1 - 14:
            legs |= lab == k
    legs = ndimage.binary_dilation(legs, iterations=10)
    wlock = np.clip(ndimage.gaussian_filter(legs.astype(float), 3.0) * 1.6, 0, 1) * wv
    log['lock'] = 'key-pose paws: ground-reaching leg components in the bottom 22% of the figure, dilated 10 px, feathered'
    locked = []
    for c, a in aligned:
        A = a * (1 - wlock) + ref[1] * wlock
        Cp = c * a[..., None] * (1 - wlock[..., None]) + ref[0] * ref[1][..., None] * wlock[..., None]
        C = np.where(A[..., None] > 1e-4, Cp / np.maximum(A[..., None], 1e-4), ref[0])
        locked.append((np.clip(C, 0, 255), np.clip(A, 0, 1)))
    # placement: fit the key pose to the old registered idle frame 4 (same painting lineage)
    old = np.asarray(Image.open(os.path.join(ROOT, 'frames-prev', 'wolf-idle', 'frame_04.png')).convert('RGBA'))[..., 3] / 255.0
    oys, oxs = np.nonzero(old > 0.5)
    rys, rxs = np.nonzero(ref[1] > 0.5)
    kk = (oxs.max() - oxs.min() + 1) / (rxs.max() - rxs.min() + 1)
    best = None
    for k in np.linspace(kk * 0.97, kk * 1.03, 13):
        ox = oxs.min() - rxs.min() * k; oy = BASE - (rys.max() + 1) * k
        for ddx in np.arange(-6, 6.5, 1.0):
            img = render_cell(ref[0], ref[1], k, ox + ddx, oy)
            iou = ((img[..., 3] > 127) & (old > 0.5)).sum() / max(1, ((img[..., 3] > 127) | (old > 0.5)).sum())
            if best is None or iou > best[0]:
                best = (iou, k, ox + ddx, oy)
    iou, kk, ox, oy = best
    log['placement'] = dict(kk=round(float(kk), 5), ox=round(float(ox), 2), oy=round(float(oy), 2), iou_vs_old_frame4=round(float(iou), 4))
    od = os.path.join(ROOT, 'frames', 'wolf-idle'); os.makedirs(od, exist_ok=True)
    outs = []
    for i, (c, a) in enumerate(locked):
        img = render_cell(c, a, kk, ox, oy)
        # baseline: lowest row with >= 3 px at alpha >= 128 must be BASE - 1
        rows = np.nonzero((img[..., 3] >= 128).sum(1) >= 3)[0]
        log['frames'][i]['baseline_row'] = int(rows.max())
        Image.fromarray(img).save(os.path.join(od, f'frame_{i:02d}.png'))
        outs.append(img)
    sheet = np.zeros((H * 2, W * 4, 4), np.uint8)
    for i, img in enumerate(outs):
        sheet[(i // 4) * H:(i // 4 + 1) * H, (i % 4) * W:(i % 4 + 1) * W] = img
    Image.fromarray(sheet).save(os.path.join(ROOT, 'frames', 'wolf-idle-sheet.png'))
    log['durations_ms'] = DUR
    json.dump(log, open(os.path.join(ROOT, 'qa', 'wolf-idle-process.json'), 'w'), indent=1)
    print(json.dumps({k: v for k, v in log.items() if k != 'matte'}, indent=0)[:3000])


if __name__ == '__main__':
    main()
