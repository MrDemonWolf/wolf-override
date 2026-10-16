"""Register a painted crank sheet into final 256x320 cells on the approved rows' scale, baseline and pivot.

1. matte the flat magenta key with the walk pipeline's matte (walk2/A/tools/process.py, read only);
2. SCALE from the anchor (left figure = the approved eng-idle frame_00 placed at K = 2.9): silhouette
   IoU fit of the repainted anchor against the placed anchor's alpha -> sheet scale s; every figure
   uses that one scale (final px per raw px = 1 / (K * s * sx));
3. PLACEMENT from the LEGS only (rows below cell y 200, where the guide kept the idle's own legs):
   a fixed-scale IoU fit of the painted legs to the guide's legs, so the boots land where the idle's
   boots are (no foot slide between idle and crank);
4. one premultiplied linear-light Lanczos resample from the raw painting (walk2/A/tools/register.py
   render), then a sub-pixel x lock of the boots onto the idle's boots (alpha cross-correlation of
   rows 270-312) and a baseline snap of the lowest opaque row (alpha >= 128, >= 3 px wide) onto 311.

usage: register_crank.py RAW.png OUTDIR
Writes OUTDIR/frame_00.png (A), frame_01.png (B), anchor.png and register.json.
"""
import json, math, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
CRANK = os.path.abspath(os.path.join(HERE, '..'))
WALK = 'scratchpad/walk2/A/tools'
sys.path.insert(0, WALK)
import process as P   # noqa: E402 (read only)
import register as R  # noqa: E402 (read only)
sys.path.insert(0, HERE)
import geometry as GEO  # noqa: E402

GUIDE = json.load(open(os.path.join(CRANK, 'guides', 'guide.json')))
IDLE = os.path.join(CRANK, 'refs', 'anchor-eng-idle-frame_00.png')
K = GUIDE['K']
LEG_ROW = 200  # cell row; below it the guide kept the idle's painted legs


def lowest_row(a8, min_w=3):
    rows = np.nonzero((a8 >= 128).sum(1) >= min_w)[0]
    return int(rows.max()) if len(rows) else None


def own_mask(labs, a, x0, x1):
    ids = np.unique(labs[:, int(x0):int(math.ceil(x1))]); ids = ids[ids > 0]
    own = np.zeros_like(a, bool)
    for i in ids:
        ys, xs = np.nonzero(labs == i)
        if x0 <= xs.mean() < x1 and len(xs) > 400:
            own |= labs == i
    return ndimage.binary_dilation(own, iterations=4) & (a > 0)


def boot_dx(img, ref, rows=(270, 312)):
    """Sub-pixel x shift that best lays img's boots onto ref's (alpha correlation)."""
    a = img[rows[0]:rows[1], :, 3].astype(np.float32) / 255
    b = ref[rows[0]:rows[1], :, 3].astype(np.float32) / 255
    best = None
    for d in np.arange(-12, 12.01, 0.25):
        sh = ndimage.shift(a, (0, d), order=1)
        v = float((sh * b).sum() / np.sqrt((sh * sh).sum() * (b * b).sum() + 1e-9))
        if best is None or v > best[0]:
            best = (v, float(d))
    return best[1], best[0]


def main(raw_path, outdir):
    os.makedirs(outdir, exist_ok=True)
    rgb = np.asarray(Image.open(raw_path).convert('RGB'))
    H, W = rgb.shape[:2]
    gw, gh = GUIDE['sheet']
    sx, sy = W / gw, H / gh
    guide = Image.open(os.path.join(CRANK, 'guides', 'crank-guide.png')).convert('RGB')
    anc = Image.open(os.path.join(CRANK, 'guides', 'anchor-alpha.png'))
    if (W, H) != (gw, gh):
        guide = guide.resize((W, H), Image.LANCZOS); anc = anc.resize((W, H), Image.LANCZOS)
    g = np.asarray(guide).astype(int)
    gmask = np.abs(g - [255, 0, 255]).sum(2) > 90
    amask = np.asarray(anc) > 127
    col, a, mrep = P.matte(rgb)
    a, _, _ = P.clean_alpha(a, min_island=int(600 * sx * sy))
    labs = ndimage.label(a > 0.5)[0]
    rep = dict(raw=raw_path, raw_size=[W, H], guide_scale_ratio=[sx, sy], matte=mrep)
    third = W / 3.0
    # ---- scale from the anchor
    own = own_mask(labs, a, 0, third)
    pm = (np.where(own, a, 0) > 0.5)[:, :int(third)]
    s_a, tx, ty, iou = P.iou_fit(pm, amask[:, :int(third)], np.arange(0.90, 1.1001, 0.0025))
    rep['anchor'] = dict(scale=round(float(s_a), 4), iou=round(float(iou), 4), t=[tx, ty])
    kk = 1.0 / (K * s_a * sx)
    rep['final_px_per_raw_px'] = round(kk, 5)
    idle = np.asarray(Image.open(IDLE).convert('RGBA'))
    outs = {}
    for i, name in enumerate(['anchor', 'crank-a', 'crank-b']):
        x0, x1 = third * i, third * (i + 1)
        own = own_mask(labs, a, x0, x1)
        fa = np.where(own, a, 0.0)
        cell = GUIDE['cells'][i]
        piv = np.array(cell['pivot_sheet']) * [sx, sy]
        if name == 'anchor':
            win = (0, 0); s, t = s_a, (tx, ty)
        else:
            # legs-only fit at the sheet scale
            leg_y = int((GUIDE['top'] + LEG_ROW * K) * sy)
            pmw = (fa > 0.5)[leg_y:, int(x0):int(x1)]
            gmw = gmask[leg_y:, int(x0):int(x1)]
            s, ltx, lty, liou = P.iou_fit(pmw, gmw, [s_a])
            win = (int(x0), leg_y); t = (ltx, lty)
            rep.setdefault('legs_fit', {})[name] = dict(iou=round(float(liou), 4), t=[ltx, lty])
        rx = win[0] + s * (piv[0] - win[0]) + t[0]
        ry = win[1] + s * (piv[1] - win[1]) + t[1]
        f = dict(a=fa, col=col)
        img = R.render(f, GEO.CELL_W, GEO.CELL_H, GEO.PIVOT_X, GEO.BASE_ROW, kk, rx, ry)
        low = lowest_row(img[..., 3]); dy = float(GEO.BASE_ROW - low) if low is not None else 0.0
        dx, ncc = boot_dx(img, idle) if name != 'anchor' else (0.0, None)
        if dx or dy:
            img = R.render(f, GEO.CELL_W, GEO.CELL_H, GEO.PIVOT_X, GEO.BASE_ROW, kk, rx, ry, dx, dy)
        low2 = lowest_row(img[..., 3])
        A8 = img[..., 3]; yy, xx = np.nonzero(A8 >= 128)
        rep.setdefault('frames', {})[name] = dict(baseline_snap_px=dy, boot_lock_dx=dx, boot_ncc=ncc,
                                                   lowest_row=low2, bbox=[int(xx.min()), int(yy.min()), int(xx.max()), int(yy.max())],
                                                   edge_clip=dict(left=int((A8[:, 0] > 0).sum()), right=int((A8[:, -1] > 0).sum()), top=int((A8[0] > 0).sum())))
        outs[name] = img
    Image.fromarray(outs['anchor']).save(os.path.join(outdir, 'anchor.png'))
    Image.fromarray(outs['crank-a']).save(os.path.join(outdir, 'frame_00.png'))
    Image.fromarray(outs['crank-b']).save(os.path.join(outdir, 'frame_01.png'))
    # how faithful the repainted anchor is to the approved idle (mean abs RGB over both-opaque px)
    both = (outs['anchor'][..., 3] > 200) & (idle[..., 3] > 200)
    rep['anchor']['vs_idle_mean_abs_rgb'] = round(float(np.abs(outs['anchor'][..., :3].astype(int) - idle[..., :3].astype(int))[both].mean()), 2)
    a1 = outs['anchor'][..., 3] > 127; a2 = idle[..., 3] > 127
    rep['anchor']['vs_idle_alpha_iou'] = round(float((a1 & a2).sum() / (a1 | a2).sum()), 4)
    json.dump(rep, open(os.path.join(outdir, 'register.json'), 'w'), indent=1)
    print(json.dumps({k: rep[k] for k in ('anchor', 'final_px_per_raw_px', 'legs_fit', 'frames')}, indent=1))


if __name__ == '__main__':
    main(*sys.argv[1:])
