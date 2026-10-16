"""Clean up the chosen crank pair and write the delivered frames, sheet and atlas.

Source: frames/crank-2c (raw/crank-2c.png, registered by register_crank.py). Steps:
1. colour: each frame's RGB is mapped onto the approved idle frame's colours with a per-channel gain
   and offset fitted (least squares, 2 % trimmed) on the legs, rows 215-311, where the crank frames
   repeat the idle's own legs pixel for pixel in place (Codex's two passes drifted them warmer:
   about +4 R, +5 G, -3.5 B);
2. legs: rows 218-319 are the approved idle frame's own pixels (RGB and alpha), blended in over rows
   208-218 in premultiplied light, so the boots are identical in idle, A and B (no foot slide, no
   boil); the idle's two hanging gloves end above row 208;
3. the far hand is braced on the wall, so it must not move: B's far glove and cuff (x >= 172, rows
   94-119) are shifted onto A's by an integer x found by alpha/luma correlation;
4. magenta despill on edge pixels (any pixel whose min(R, B) - G exceeds that of its nearest opaque
   interior colour by > 12 takes that interior colour), then stray islands under 120 px removed
   (walk2/A/tools/finalize.py clean, read only);
5. alpha: interior 255, a 1-2 px soft edge from the resample, 0 elsewhere (RGB zeroed under alpha 0).
Writes deliver/sprites/eng-crank/frame_00.png (A), frame_01.png (B), eng-crank-sheet.png (512x320),
deliver/sprites/eng-crank-atlas.png (304x308: the two frames' windows x 52-203, y 6-313 side by
side, each centred on the cell's centre) and qa/finalize.json.
"""
import json, os, sys
import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
CRANK = os.path.abspath(os.path.join(HERE, '..'))
sys.path.insert(0, 'scratchpad/walk2/A/tools')
from finalize import clean  # noqa: E402 (read only)

SRC = os.path.join(CRANK, 'frames', 'crank-2c')
IDLE = os.path.join(CRANK, 'refs', 'anchor-eng-idle-frame_00.png')
OUT = os.path.join(CRANK, 'deliver', 'sprites')
WIN = (52, 6, 204, 314)  # atlas window per frame, cell px (x0, y0, x1, y1): centred on the cell centre (128, 160), so a centred Sprite2D needs no offset
LEG_BLEND = (208, 218)


def load(p):
    return np.asarray(Image.open(p).convert('RGBA')).astype(np.float64)


def colour_fit(X, ref, rows=(215, 312)):
    m = (X[rows[0]:rows[1], :, 3] > 250) & (ref[rows[0]:rows[1], :, 3] > 250)
    xs = X[rows[0]:rows[1]][m][:, :3]; rs = ref[rows[0]:rows[1]][m][:, :3]
    fit = []
    for c in range(3):
        x, r = xs[:, c], rs[:, c]
        res = r - x; lo, hi = np.percentile(res, [2, 98]); k = (res >= lo) & (res <= hi)
        A = np.vstack([x[k], np.ones(k.sum())]).T
        g, o = np.linalg.lstsq(A, r[k], rcond=None)[0]
        fit.append((float(g), float(o)))
    return fit


def apply_fit(X, fit):
    Y = X.copy()
    for c, (g, o) in enumerate(fit):
        Y[..., c] = np.clip(X[..., c] * g + o, 0, 255)
    return Y


def blend_legs(X, ref):
    y = np.arange(X.shape[0])[:, None, None]
    w = np.clip((y - LEG_BLEND[0]) / (LEG_BLEND[1] - LEG_BLEND[0]), 0, 1)
    ax, ar = X[..., 3:4] / 255, ref[..., 3:4] / 255
    pm = X[..., :3] * ax * (1 - w) + ref[..., :3] * ar * w
    a = ax * (1 - w) + ar * w
    rgb = pm / np.maximum(a, 1e-6)
    return np.dstack([np.where(a > 0, rgb, 0), a * 255])


def far_glove_dx(A, B, box=(172, 94, 205, 120)):
    x0, y0, x1, y1 = box
    def feat(X):
        s = X[y0:y1, x0 - 12:x1 + 12]
        return (s[..., 3] / 255) * (255 - s[..., :3].mean(2)) / 255  # opaque and dark = the glove
    fa, fb = feat(A), feat(B)
    best = None
    for d in range(-8, 9):
        sh = np.roll(fb, d, axis=1)
        v = float((sh * fa).sum() / np.sqrt((sh * sh).sum() * (fa * fa).sum() + 1e-9))
        if best is None or v > best[0]:
            best = (v, d)
    return best[1], best[0]


def shift_region(X, box, dx):
    """Move the pixels of box right by dx (> 0); the dx columns it leaves behind repeat the column
    just left of the box, so the cuff stretches by dx px instead of leaving a gap."""
    x0, y0, x1, y1 = box
    Y = X.copy()
    if dx == 0:
        return Y
    reg = X[y0:y1, x0:x1].copy()
    Y[y0:y1, x0:x1 + dx] = 0
    Y[y0:y1, x0 + dx:x1 + dx] = reg
    for k in range(dx):
        Y[y0:y1, x0 + k] = X[y0:y1, x0 - 1]
    return Y


def despill(X):
    a = X[..., 3]
    core = ndimage.binary_erosion(a >= 250, iterations=2)
    _, (iy, ix) = ndimage.distance_transform_edt(~core, return_indices=True)
    C = X[iy, ix, :3]
    m = lambda P: np.minimum(P[..., 0], P[..., 2]) - P[..., 1]
    spill = (a > 0) & ~core & (m(X[..., :3]) - m(C) > 12)
    spill[LEG_BLEND[1]:] = False  # the idle's own legs stay exactly as approved
    Y = X.copy(); Y[spill, :3] = C[spill]
    return Y, int(spill.sum())


def edge_stats(X):
    a = X[..., 3]
    edge = (a > 0) & (a < 255)
    core = ndimage.binary_erosion(a >= 250, iterations=2)
    _, (iy, ix) = ndimage.distance_transform_edt(~core, return_indices=True)
    C = X[iy, ix, :3]
    lum = lambda P: P[..., :3] @ np.array([0.2126, 0.7152, 0.0722])
    dl = lum(X)[edge] - lum(C)[edge]
    mag = (np.minimum(X[..., 0], X[..., 2]) - X[..., 1])[edge]
    return dict(edge_px=int(edge.sum()), edge_minus_interior_luma_mean=round(float(dl.mean()), 2),
                edge_luma_p05=round(float(np.percentile(dl, 5)), 2), edge_magenta_px=int((mag > 20).sum()),
                alpha_levels=dict(zero=int((a == 0).sum()), partial=int(edge.sum()), full=int((a == 255).sum())))


def to8(X):
    Y = np.clip(np.round(X), 0, 255).astype(np.uint8)
    Y[Y[..., 3] == 0, :3] = 0
    return Y


def main():
    idle = load(IDLE)
    A = load(os.path.join(SRC, 'frame_00.png')); B = load(os.path.join(SRC, 'frame_01.png'))
    rep = {}
    fa, fb = colour_fit(A, idle), colour_fit(B, idle)
    rep['colour_fit'] = dict(A=fa, B=fb)
    A, B = apply_fit(A, fa), apply_fit(B, fb)
    A, B = blend_legs(A, idle), blend_legs(B, idle)
    dx, ncc = far_glove_dx(A, B)
    rep['far_glove'] = dict(B_shift_px=dx, ncc=round(ncc, 4))
    if dx > 0:
        B = shift_region(B, (172, 94, 205, 120), dx)
    out = []
    for name, X in (('A', A), ('B', B)):
        X, n_spill = despill(X)
        X8, n_islands = clean(to8(X))
        rep[name] = dict(despilled_px=n_spill, islands_removed=n_islands, **edge_stats(X8.astype(np.float64)))
        ys, xs = np.nonzero(X8[..., 3] >= 128)
        rep[name]['bbox'] = [int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())]
        rep[name]['lowest_row'] = int(np.nonzero((X8[..., 3] >= 128).sum(1) >= 3)[0].max())
        assert not X8[:WIN[1], :, 3].any() and not X8[WIN[3]:, :, 3].any() and not X8[:, :WIN[0], 3].any() and not X8[:, WIN[2]:, 3].any(), 'figure outside the atlas window'
        out.append(X8)
    d = os.path.join(OUT, 'eng-crank'); os.makedirs(d, exist_ok=True)
    for k, X8 in enumerate(out):
        Image.fromarray(X8).save(os.path.join(d, 'frame_%02d.png' % k), optimize=True)
    Image.fromarray(np.hstack(out)).save(os.path.join(OUT, 'eng-crank-sheet.png'), optimize=True)
    x0, y0, x1, y1 = WIN
    Image.fromarray(np.hstack([X8[y0:y1, x0:x1] for X8 in out])).save(os.path.join(OUT, 'eng-crank-atlas.png'), optimize=True)
    # what changed against the idle below the blend (must be 0) and the legs A vs B
    for name, X8 in (('A', out[0]), ('B', out[1])):
        rep[name]['rows_218_319_vs_idle_max_abs'] = int(np.abs(X8[218:].astype(int) - to8(idle)[218:].astype(int)).max())
    rep['window'] = dict(x0=x0, y0=y0, x1=x1, y1=y1, note='atlas region i = Rect2(152 * i, 0, 152, 308); its centre is the cell centre (128, 160)')
    os.makedirs(os.path.join(CRANK, 'qa'), exist_ok=True)
    json.dump(rep, open(os.path.join(CRANK, 'qa', 'finalize.json'), 'w'), indent=1)
    print(json.dumps(rep, indent=1))


if __name__ == '__main__':
    main()
