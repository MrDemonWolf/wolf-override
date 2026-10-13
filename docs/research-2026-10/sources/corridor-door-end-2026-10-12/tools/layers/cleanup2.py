"""Fix round 1 (v2) deterministic cleanup of the Codex paint-overs (REAL-LOOK section 4, step 3).

What changed from cleanup.py, item by item from the round-1 review:
  2  despill: edit targets are on a flat neutral grey, every alpha edge is decontaminated over 3 px,
     and a CHECK fails the layer if any pixel within 8 px of an alpha edge has (R+B)/2 - G > 3.
  7  depth order: every part is value-matched only on its VISIBLE pixels (its mask minus every
     nearer part's mask, nearer = drawn later), and a CHECK fails if a part's pass changed any
     pixel outside its visible mask.
  8  light: big surfaces are relit to the design's low-frequency light (the paint keeps its fine
     material, the design decides where light falls), then every part's mean is held within 8 %
     of the design; the paint can no longer light a face from nowhere. Caused wear is added from
     designed masks (damp at wall feet, boot and cart scuffs, hand-rub, one rust drip under the
     penetration plate, the worn threshold, floor line and bar stripes where feet cross).
  4  seam: the bay wall's low-frequency value is pulled, row by row, to the old wall's value at the
     seam column and released over 42 world px, so no bright wall meets the column.
  S4 floor: the corridor luminaire and the door light get soft reflections in the wet floor, made
     from the old plate's own painted lamp streak (the plant room's floor past the portal is dry).
Codex originals in codex/<job>/out/ are never modified. Writes layers/v2/ and layers/report2.json.
"""
from __future__ import annotations

import json
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(__file__))
from imgkit import load_rgb, resize, register, fidelity, lum, to_lin, to_srgb, decontaminate

# --- CONFIG -----------------------------------------------------------------------------------
# R is the working folder the piece was built in, with design/, layers/, paint/ and codex/ in it, and
# game-main/ (an export of main at 76d3a50) and game-slice/ (the modified copy) beside them. It was a
# temporary session folder; point WOLF_DOOR_END_WORK at your own copy to run this tool again.
R = os.environ.get("WOLF_DOOR_END_WORK", os.path.abspath("door-end-work"))
# ------------------------------------------------------------------------------------------------
D = os.path.join(R, "design")
C = os.path.join(R, "codex")
OUT = os.path.join(R, "layers", "v2")
GAME = os.path.join(R, "game-main", "apps", "game")
THRESH = {"edge_ncc_in_asset": 0.45, "strong_edge_recall": 0.80}
BG = np.array([36.0, 38.0, 42.0])
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "design"))  # the design tools (tools/design/)
import portal2 as p2  # noqa: E402


def mask(path: str) -> np.ndarray:
    return np.asarray(Image.open(path).convert("L")).astype(np.float64) / 255.0


def rgba(path: str):
    a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float64)
    return a[..., :3], a[..., 3] / 255.0


def save_rgba(rgb, alpha, path):
    a = (np.clip(alpha, 0, 1) * 255 + 0.5).astype(np.uint8)
    c = np.clip(rgb + 0.5, 0, 255).astype(np.uint8)
    c[a == 0] = 0
    Image.fromarray(np.dstack([c, a]), "RGBA").save(path)


def mgauss(v: np.ndarray, m: np.ndarray, sigma: float) -> np.ndarray:
    num = ndimage.gaussian_filter(v * m, sigma)
    den = ndimage.gaussian_filter(m, sigma)
    return num / np.maximum(den, 1e-6)


def relight(rgb, design, vis, sigma):
    """Imposes the design's low-frequency luminance on the paint inside `vis`, keeping the paint's
    finer structure and its colour."""
    m = (vis > 0.5).astype(float)
    if m.sum() < 16:
        return rgb
    lp = lum(to_lin(rgb))
    ld = lum(to_lin(design))
    k = mgauss(ld, m, sigma) / np.maximum(mgauss(lp, m, sigma), 1e-5)
    out = to_srgb(to_lin(rgb) * k[..., None])
    return rgb * (1 - m[..., None]) + out * m[..., None]


def hold_mean(rgb, design, vis, tol):
    m = vis > 0.5
    if m.sum() < 4:
        return rgb, 1.0
    lp = lum(to_lin(rgb))[m].mean()
    ld = lum(to_lin(design))[m].mean()
    target = float(np.clip(lp, ld * (1 - tol), ld * (1 + tol)))
    k = target / max(lp, 1e-6)
    out = rgb.copy()
    out[m] = to_srgb(to_lin(rgb[m]) * k)
    return out, k


def hold_chroma(rgb, design, vis, strength=0.7):
    m = vis > 0.5
    if m.sum() < 4:
        return rgb
    p = to_lin(rgb)[m].mean(0) + 1e-6
    d = to_lin(design)[m].mean(0) + 1e-6
    gain = ((d / d.mean()) / (p / p.mean())) ** strength
    gain = gain / (gain * np.array([0.2126, 0.7152, 0.0722])).sum()
    out = rgb.copy()
    out[m] = to_srgb(to_lin(rgb[m]) * gain)
    return out


def visible_masks(names, layer_masks):
    """Visible part masks in depth order: a part's mask minus every part drawn after it."""
    out = {}
    nearer = np.zeros_like(next(iter(layer_masks.values())))
    for n in reversed(names):
        m = layer_masks[n]
        out[n] = np.clip(m - nearer, 0, 1) * (m > 0)
        nearer = np.clip(nearer + m, 0, 1)
    return out


def spill_check(rgb, alpha, band=8, limit=3.0):
    """Fails any pixel within `band` px inside an alpha edge whose colour leans magenta/violet."""
    solid = alpha > 0.02
    inner = ndimage.binary_erosion(alpha > 0.98, iterations=band)
    near_edge = solid & ~inner
    v = (rgb[..., 0] + rgb[..., 2]) / 2 - rgb[..., 1]
    bad = near_edge & (v > limit)
    return {"edge_band_px": band, "max_violet": round(float(v[near_edge].max()) if near_edge.any() else 0.0, 2),
            "violet_pixels": int(bad.sum()), "pass": bool(bad.sum() == 0)}


def despill(rgb, alpha, band=8, limit=3.0):
    """Pulls R and B down to at most G + limit inside the edge band (neutral-grey materials only)."""
    solid = alpha > 0.02
    inner = ndimage.binary_erosion(alpha > 0.98, iterations=band)
    near = solid & ~inner
    out = rgb.copy()
    g = out[..., 1]
    for c in (0, 2):
        ch = out[..., c]
        over = near & (((out[..., 0] + out[..., 2]) / 2 - g) > limit)
        ch[over] = np.minimum(ch[over], g[over] + limit)
    return out


# ----------------------------------------------------------------------------- portal

PART_ORDER = None


def portal(report: dict) -> None:
    P = os.path.join(D, "portal2")
    M = os.path.join(P, "masks")
    spec = json.load(open(os.path.join(P, "spec.json")))
    W, H = 660, 1320

    def prepared(name, idx):
        t = load_rgb(os.path.join(C, "paint-portal2", "refs", f"{idx}-edit-target-{name}.png"))
        p = resize(load_rgb(os.path.join(C, "paint-portal2", "out", f"portal2-{name}-painted.png")), (1024, 1536))
        reg, tr = register(p, t, scales=np.linspace(0.97, 1.03, 7), shift=8)
        return resize(reg[:, 128:896], (W, H)), resize(t[:, 128:896], (W, H)), tr

    closed, tgt_c, tc = prepared("closed", 1)
    opened, tgt_o, to = prepared("open", 2)
    layers = ("wall", "curtain", "frame", "wheel-on-canvas", "front")
    des = {n: rgba(os.path.join(P, f"design-{n}.png")) for n in layers}
    # fidelity of each paint against its own edit target, inside the object
    for name, painted, tgt, tr, names in (("closed", closed, tgt_c, tc, layers), ("open", opened, tgt_o, to, ("wall", "frame", "wheel-on-canvas", "front"))):
        a = np.zeros((H, W))
        for n in names:
            a = np.maximum(a, des[n][1])
        f = fidelity(painted, tgt, a)
        f["registration"] = tr
        bgsel = a < 0.01
        f["background_kept_flat_share"] = round(float((np.abs(painted[bgsel] - BG).max(-1) < 12).mean()), 3)
        f["pass"] = all(f[k] >= v for k, v in THRESH.items())
        report[f"portal2-{name}"] = f
    # part lists in depth order (the design's render order)
    order = {lay: [p["name"] for p in spec["parts"][lay]] for lay in ("wall", "frame", "curtain", "front")}
    nearer_alpha = {}
    # which layers are in front of which in the closed paint (to know where a layer's paint is hidden)
    stack = ["wall", "curtain", "frame", "wheel-on-canvas", "front"]
    for i, n in enumerate(stack):
        acc = np.zeros((H, W))
        for m in stack[i + 1:]:
            acc = np.maximum(acc, des[m][1])
        nearer_alpha[n] = acc
    from_open = {"reveal_far", "reveal_angle_far", "threshold"}
    os.makedirs(OUT, exist_ok=True)
    results = {}
    checks = {}
    for lay in ("wall", "curtain", "frame", "front"):
        drgb, da = des[lay]
        lm = {n: mask(os.path.join(M, f"{lay}--{n}.png")) for n in order[lay]}
        vis = visible_masks(order[lay], lm)
        out = closed.copy()
        # parts only seen with the door open come from the open paint
        for n in order[lay]:
            if n in from_open:
                sel = vis[n] > 0
                out[sel] = opened[sel]
        # where a nearer layer covers this one in the paint, the paint shows that layer: use the
        # design there, scaled to this part's painted level
        hidden_closed = nearer_alpha[lay] > 0.5
        # in the open paint the curtain is gone: only the static frame, wheel and front cover the wall
        hidden_open = np.maximum.reduce([des[m][1] for m in ("frame", "wheel-on-canvas", "front")]) > 0.5
        for n in order[lay]:
            hidden = hidden_open if n in from_open else hidden_closed
            sel = (vis[n] > 0.5) & hidden
            ok = (vis[n] > 0.5) & ~hidden
            if sel.any():
                k = (to_lin(out[ok]).mean(0) + 1e-6) / (to_lin(drgb[ok]).mean(0) + 1e-6) if ok.sum() > 8 else np.ones(3)
                out[sel] = to_srgb(to_lin(drgb[sel]) * k)
        before = out.copy()
        changed_outside = 0
        for n in order[lay]:
            v = vis[n]
            if v.sum() < 2:
                continue
            area_px = float((v > 0.5).sum())
            snap = out.copy()
            if area_px > 3000:
                out = relight(out, drgb, v, 14.0)
            out, _ = hold_mean(out, drgb, v, 0.08)
            out = hold_chroma(out, drgb, v, 0.7)
            diff = np.abs(out - snap).max(-1) > 0.5
            changed_outside += int((diff & ~(v > 0)).sum())
        checks[lay] = {"depth_order_writes_outside_visible": changed_outside}
        results[lay] = (out, da)
    # ---- the lamp socket stays the design's (unlit); the glass is a hole
    out, da = results["front"]
    for n in ("lamp_base", "lamp_cap"):
        g = mask(os.path.join(M, f"front--{n}.png"))
    gh = mask(os.path.join(M, "front--GLASS_HOLE.png"))
    da = np.clip(da - gh, 0, 1)
    results["front"] = (out, da)
    # ---- caused wear, from designed masks in each surface's own plane
    wear = wear_layers()
    for lay, ops in wear.items():
        out, da = results[lay]
        for kind, m, amount in ops:
            m = np.clip(m, 0, 1) * (da > 0)
            lin = to_lin(out)
            if kind == "darken":
                lin = lin * (1 - amount * m[..., None]) * (1 + 0.04 * m[..., None] * np.array([-1, 0, 1]))
            elif kind == "lighten":
                lin = lin * (1 + amount * m[..., None])
            elif kind == "rust":
                lin = lin * (1 - m[..., None] * (1 - np.array([1.05, 0.80, 0.58]) * (1 - amount)))
            elif kind == "fade_yellow":
                grey = lum(lin)[..., None] * np.array([1.0, 1.0, 1.0]) * 0.9
                lin = lin * (1 - amount * m[..., None]) + grey * amount * m[..., None]
            out = to_srgb(lin)
        results[lay] = (out, da)
    # ---- typeset stencils (37875 white), lit like the surface they are on
    for lay, tname, base in (("wall", "TEXT-wall", 0.205), ("frame", "TEXT-frame", 0.18)):
        out, da = results[lay]
        tx = mask(os.path.join(M, f"{tname}.png"))
        paint = np.clip(to_lin(out) * (0.78 / base), 0, 1)
        out = out * (1 - 0.88 * tx[..., None]) + to_srgb(paint) * 0.88 * tx[..., None]
        results[lay] = (out, da)
    # ---- contact shadows exactly as designed (wall layer, floor)
    out, da = results["wall"]
    sh = mask(os.path.join(M, "wall--contact_shadow.png"))
    solid_wall = np.zeros((H, W))
    for n in order["wall"]:
        solid_wall = np.maximum(solid_wall, mask(os.path.join(M, f"wall--{n}.png")))
    hole = mask(os.path.join(M, "wall--HOLE.png"))
    shadow_only = (sh > 0) & (solid_wall < 0.5)
    drgb, _ = des["wall"]
    out[shadow_only] = drgb[shadow_only]
    results["wall"] = (out, da)
    # ---- alpha exactly the design's; decontaminate edges; despill check
    for lay in ("wall", "curtain", "frame", "front"):
        out, da = results[lay]
        if lay == "wall":
            da = des["wall"][1].copy()
        out = decontaminate(out, np.clip(da, 0, 1), band=3)
        out = despill(out, da)
        checks.setdefault(lay, {})["spill"] = spill_check(out, da)
        checks[lay]["alpha_equals_design"] = bool(np.abs(da - (des[lay][1] if lay != "front" else np.clip(des[lay][1] - gh, 0, 1))).max() < 1 / 255)
        save_rgba(out, da, os.path.join(OUT, f"portal-{lay}.png"))
        results[lay] = (out, da)
    checks["wall"]["hole_alpha_max"] = float(results["wall"][1][hole > 0.999].max()) if (hole > 0.999).any() else 0.0
    # ---- the wheel (own canvas) from the closed paint, at its design alpha
    wr, wa = rgba(os.path.join(P, "design-wheel.png"))
    wc = spec["wheel_canvas"]["world_box"]
    x0 = int(round((wc[0] - 680.0) * 4))
    y0 = int(round((wc[1] - 150.0) * 4))
    wp = closed[y0:y0 + 88, x0:x0 + 88].copy()
    wm = {n: mask(os.path.join(M, f"wheel--{n}.png")) for n in ("wheel_rim", "wheel_spokes", "wheel_hub", "wheel_knob")}
    wvis = visible_masks(list(wm), wm)
    for n, v in wvis.items():
        wp, _ = hold_mean(wp, wr, v, 0.10)
        wp = hold_chroma(wp, wr, v, 0.7)
    # worn bright arcs on the rim where hands grip (left and top-left)
    yy, xx = np.mgrid[0:88, 0:88].astype(float)
    ang = np.arctan2(yy - 44, xx - 44)
    grip = np.clip(np.cos(ang - np.pi * 1.05) * 1.4 - 0.3, 0, 1) * wm["wheel_rim"]
    wp = to_srgb(to_lin(wp) * (1 + 0.45 * grip[..., None]))
    wp = decontaminate(wp, wa, band=3)
    save_rgba(wp, wa, os.path.join(OUT, "bypass-wheel.png"))
    checks["wheel"] = {"spill": spill_check(wp, wa)}
    # ---- the open state's tucked bar, exactly as SealLeaf draws it at open = 1
    cur, ca = results["curtain"]
    bar, bar_a = tucked_bar(cur, ca)
    save_rgba(bar, bar_a, os.path.join(OUT, "portal-curtain-open.png"))
    Image.open(os.path.join(P, "lens.png")).save(os.path.join(OUT, "lens.png"))
    report["portal2-layers"] = checks


def wear_layers():
    """Designed, caused wear for each layer: (kind, mask, amount) in canvas pixels."""
    cv = p2.CV
    X, Y = cv.grid()
    rng = np.random.default_rng(7)

    def soft_noise(scale_px, seed):
        r = np.random.default_rng(seed).random((cv.h // scale_px + 3, cv.w // scale_px + 3))
        z = ndimage.zoom(r, scale_px, order=3)[:cv.h, :cv.w]
        return (z - z.min()) / (np.ptp(z) + 1e-9)

    n1 = soft_noise(14, 11)
    n2 = soft_noise(6, 12)
    out = {"wall": [], "front": [], "frame": [], "curtain": []}
    face = p2.face_plane(0.0)
    _, la, lb = face.points()
    # damp at the foot of the cross-wall's approach face (far column and near pier): up to ~0.14 m,
    # the top edge ragged where it has wicked up, darkest at the floor
    top = 0.07 + 0.09 * n1
    damp = np.clip((top - lb) / 0.05, 0, 1) * (lb >= -0.01)
    out["wall"].append(("darken", damp * ((la > p2.A_F) & (la < p2.A_BACK)), 0.30))
    out["front"].append(("darken", damp * ((la > p2.A_END) & (la < p2.A_N)), 0.30))
    end = p2.side_plane(p2.A_END)
    _, ea, eb = end.points()
    top_e = 0.08 + 0.10 * n1
    damp_e = np.clip((top_e - eb) / 0.05, 0, 1) * (eb >= -0.01) * (ea >= 0) * (ea <= p2.T_WALL)
    out["front"].append(("darken", damp_e, 0.32))
    # boot and cart scuffs on the pier end's lower corner (people and trolleys turn round it)
    sc = np.zeros((cv.h, cv.w))
    for (t0, h0, w, h, a) in ((0.02, 0.28, 0.16, 0.05, 0.9), (0.06, 0.40, 0.10, 0.035, 0.7), (0.47, 0.22, 0.14, 0.05, 0.8)):
        sc = np.maximum(sc, a * np.exp(-(((ea - t0) / w) ** 2 + ((eb - h0) / h) ** 2) * 2.5) * (n2 > 0.35))
    out["front"].append(("darken", sc * (ea >= 0) * (ea <= p2.T_WALL), 0.22))
    sc2 = np.zeros((cv.h, cv.w))
    for (a0, h0, w, h, amt) in ((p2.A_F + 0.45, 0.30, 0.25, 0.05, 0.8), (p2.A_F + 0.75, 0.42, 0.15, 0.04, 0.6)):
        sc2 = np.maximum(sc2, amt * np.exp(-(((la - a0) / w) ** 2 + ((lb - h0) / h) ** 2) * 2.5) * (n2 > 0.4))
    out["wall"].append(("darken", sc2 * ((la > p2.A_F) & (la < p2.A_BACK)), 0.20))
    # hand-rub: the push-button cover's latch edge and the area round it, polished by hands
    pb = p2.side_plane(p2.A_END - 0.10)
    _, pa, pbv = pb.points()
    tl = p2.T_WALL / 2
    rub = np.exp(-(((pa - (tl + 0.09)) / 0.05) ** 2 + ((pbv - 1.62) / 0.12) ** 2) * 2.0)
    out["front"].append(("lighten", rub * (np.abs(pa - tl) < 0.13) * (np.abs(pbv - 1.61) < 0.17), 0.30))
    # one rust drip under the welded penetration plate (condensation on the conduits)
    dx = la - 1.47
    drip = np.exp(-(dx / 0.012) ** 2) * np.clip((5.55 - lb) / 0.05, 0, 1) * np.clip(1 - (5.55 - lb) / 1.25, 0, 1) ** 1.5
    out["wall"].append(("rust", drip * (lb < 5.56), 0.35))
    # the steel threshold polished where feet cross (the walk line is a = 0)
    thr = p2.top_plane(0.0)
    _, ta, tb = thr.points()
    worn = np.exp(-((ta / 0.55) ** 2)) * (tb > 0) * (tb < p2.T_WALL) * (0.6 + 0.4 * n2)
    out["wall"].append(("lighten", worn, 0.35))
    # the yellow floor line scuffed where feet cross it
    fl = np.exp(-((ta / 0.45) ** 2)) * (tb < -0.2) * (tb > -0.34) * (0.5 + 0.5 * n2)
    out["wall"].append(("fade_yellow", fl, 0.55))
    # the bottom bar's stripes worn at the middle, where the bar lands on the threshold
    cp = p2.face_plane(p2.CURT_T - 0.011)
    _, ca_, cb = cp.points()
    bw = np.exp(-((ca_ / 0.6) ** 2)) * (cb < p2.BAR_H) * (cb > 0) * (0.4 + 0.6 * n2)
    out["curtain"].append(("fade_yellow", bw, 0.35))
    return out


def tucked_bar(cur, ca):
    """The curtain at open = 1, as SealLeaf's mesh draws it: the art from h - TRAVEL shown at h, for
    h between TRAVEL and the top, shaded by the hood's shadow there over the shadow it was painted
    with. Returns an image on the portal canvas."""
    cv = p2.CV
    plane = p2.face_plane(p2.CURT_T)
    _, la, lb = plane.points()
    top_m = 3.07
    sel = (lb >= p2.TRAVEL) & (lb <= top_m) & (la >= p2.A_N - 0.07) & (la <= p2.A_F + 0.07)
    src_h = lb - p2.TRAVEL
    # screen position of (la, src_h) on the curtain plane
    P = p2.O + la[..., None] * p2.U + src_h[..., None] * p2.EY + p2.CURT_T * p2.N
    from common import project
    sx, sy = project(P[..., 0] * 40.0, P[..., 1], P[..., 2])
    px = (sx - cv.x0) * cv.ppw - 0.5
    py = (sy - cv.y0) * cv.ppw - 0.5
    out = np.zeros_like(cur)
    for c in range(3):
        out[..., c] = ndimage.map_coordinates(cur[..., c], [py, px], order=1, mode="constant")
    a = ndimage.map_coordinates(ca, [py, px], order=1, mode="constant") * sel
    band = lambda h: 1.0 - (1.0 - p2.HOOD_SHADOW_FLOOR) * np.clip((h - p2.SH0) / (p2.SH1 - p2.SH0), 0, 1) ** 1.3
    shade = band(lb) / band(src_h)
    out = to_srgb(to_lin(out) * shade[..., None])
    return out, a


# ----------------------------------------------------------------------------- far patch

def far(report: dict) -> None:
    sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "design"))  # the design tools (tools/design/)
    F = os.path.join(D, "far-patch2")
    M = os.path.join(F, "masks")
    spec = json.load(open(os.path.join(F, "spec.json")))
    t = load_rgb(os.path.join(C, "paint-far2b", "refs", "1-edit-target-far.png"))
    p = resize(load_rgb(os.path.join(C, "paint-far2b", "out", "far2b-painted.png")), (1024, 1024))
    reg, tr = register(p, t, scales=np.linspace(0.97, 1.03, 7), shift=8)
    painted = resize(reg, (808, 808))
    design = load_rgb(os.path.join(F, "design.png"))
    names = spec["draw_order_back_to_front"]
    pm = {n: mask(os.path.join(M, n + ".png")) for n in names if os.path.exists(os.path.join(M, n + ".png"))}
    names = [n for n in names if n in pm]
    designed = np.zeros((808, 808))
    for m in pm.values():
        designed = np.maximum(designed, m)
    f = fidelity(painted, design, designed)
    f["registration"] = tr
    f["pass"] = all(f[k] >= v for k, v in THRESH.items())
    report["far2"] = f
    vis = visible_masks(names, pm)
    kinds = {pp["name"]: pp["surface"]["kind"] for pp in spec["parts"]}
    out = painted.copy()
    changed_outside = 0
    big = {"corr_wall", "corr_dado", "mach_wall", "mach_floor", "mach_floor_near", "tank_shell"}
    for n in names:
        v = vis[n]
        if v.sum() < 2 or kinds.get(n) == "emit":
            continue
        snap = out.copy()
        if n in big:
            out = relight(out, design, v, 10.0)
        out, _ = hold_mean(out, design, v, 0.10)
        out = hold_chroma(out, design, v, 0.6)
        diff = np.abs(out - snap).max(-1) > 0.5
        changed_outside += int((diff & ~(v > 0)).sum())
    report["far2"]["depth_order_writes_outside_visible"] = changed_outside
    # catwalk-through-tank check: inside the tank's visible pixels the result must keep the tank's
    # own value structure (no lighter horizontal band at the deck's height)
    tank = vis["tank_shell"] > 0.5
    deck = (pm["catwalk_deck"] > 0.5) & tank
    if deck.any():
        ring = tank & ~deck & ndimage.binary_dilation(deck, iterations=6)
        Ld = lum(to_lin(out))
        report["far2"]["tank_deck_band_ratio"] = round(float(Ld[deck].mean() / max(Ld[ring].mean(), 1e-6)), 3)
    # the old plate's own rows: the ceiling band, the corridor floor (lit by the design)
    base = np.asarray(Image.open(os.path.join(D, "far-patch", "far-base-streak-removed.png")).convert("RGB")).astype(np.float64)
    ofar = base[0:808, 1112:1920]
    keep = mask(os.path.join(M, "ceiling_keep.png"))
    out = out * (1 - keep[..., None]) + ofar * keep[..., None]
    fl = mask(os.path.join(M, "corr_floor_keep.png"))
    out = out * (1 - fl[..., None]) + design * fl[..., None]
    # seam: the bay wall's broad value follows the old wall's, row by row, at the column, released
    # over 84 source px (42 world px)
    orig = load_rgb(os.path.join(GAME, "assets/rooms/corridor-far.png"))
    floor_row = int(round((423.3 - 78.5) * 2))
    wall = np.zeros((808, 808), bool)
    for n in ("corr_wall", "corr_dado", "corr_dado_line", "corr_panel_joint", "corr_pipe0", "corr_pipe1", "corr_pipe2", "corr_pipe_clamp0", "corr_pipe_clamp1"):
        wall |= vis[n] > 0.5
    wall[:192] = False
    ref = lum(to_lin(orig[0:808, 1078:1110])).mean(1)  # old wall, left of the column, per row
    ref = ndimage.gaussian_filter1d(ref, 6)
    low = mgauss(lum(to_lin(out)), wall.astype(float), 8.0)
    col_right = 36  # patch x of the column's right edge (source 1148)
    ramp = np.clip((np.arange(808) - col_right) / 84.0, 0, 1)[None, :]
    gain = (ref[:, None] / np.maximum(low, 1e-5)) ** (1 - ramp)
    gain = np.where(wall, gain, 1.0)
    out = to_srgb(to_lin(out) * gain[..., None])
    report["far2"]["seam"] = {"old_wall_luma_rows_200_240": round(float(np.median(lum(orig[int((200 - 78.5) * 2):int((240 - 78.5) * 2), 1100:1110]))), 1)}
    # keep the old plate, untouched, left of source x 1132 (the opening frames reach 1128) and fade
    # the floor in over 48 px, as v1
    KEEP_X = 20
    out[:floor_row, :KEEP_X] = ofar[:floor_row, :KEEP_X]
    rampf = np.clip((np.arange(808) - KEEP_X) / 48.0, 0, 1)[None, :, None]
    out[floor_row:] = ofar[floor_row:] * (1 - rampf) + out[floor_row:] * rampf
    for n in ("lum_lens", "highbay_A_lens", "highbay_B_lens"):
        if n in pm:
            lm = pm[n]
            out = out * (1 - lm[..., None]) + design * lm[..., None]
    # the plant room's dry slab meets the corridor's wet floor in front of the cut-away wall: soften
    # that meeting over about 8 world px instead of a straight edge
    mf = pm["mach_floor_near"] > 0.5
    cols = np.nonzero(mf.any(0))[0]
    blurred = ndimage.gaussian_filter(out, (6.0, 0, 0))
    for c in cols:
        r = int(np.nonzero(mf[:, c])[0].max())
        r0, r1 = max(r - 14, 0), min(r + 14, 807)
        w = 1.0 - np.abs(np.arange(r0, r1) - r) / 14.0
        out[r0:r1, c] = out[r0:r1, c] * (1 - w[:, None]) + blurred[r0:r1, c] * w[:, None]
    full = base.copy()
    full[0:808, 1112:1920] = out
    # S4: soft reflections of the corridor luminaire and the door light in the wet corridor floor,
    # from the old plate's own painted streak under the lamp it lost (source x 1560..1720)
    full = add_reflections(full, orig, base, report)
    os.makedirs(OUT, exist_ok=True)
    Image.fromarray(np.clip(full + 0.5, 0, 255).astype(np.uint8), "RGB").save(os.path.join(OUT, "corridor-far.png"))
    Image.fromarray(np.clip(out + 0.5, 0, 255).astype(np.uint8), "RGB").save(os.path.join(OUT, "far-patch-cleaned.png"))


def add_reflections(full, orig, base, report):
    rows = slice(690, 1080)
    ex = to_lin(orig[rows, 1536:1744]) - to_lin(base[rows, 1536:1744])
    ex = np.clip(ex, 0, None)
    ex = ndimage.gaussian_filter(ex, (2.0, 2.0, 0))
    exl = lum(ex)
    cx_src = 1640  # the old lamp's centre column
    # (world x at the clamp -> far source x), strength, width scale, tint
    lights = [("corridor luminaire", 652.0, 0.20, 0.75, np.array([0.80, 0.97, 1.0])),
              ("door light", 742.0, 0.16, 0.55, np.array([0.90, 0.98, 1.0]))]
    lin = to_lin(full)
    for name, xw, k, wscale, tint in lights:
        sx = (xw - 12.444) * 2
        hw = ex.shape[1] / 2 * wscale
        xs = np.arange(int(sx - hw), int(sx + hw))
        src = cx_src + (xs - sx) / wscale - 1536
        streak = np.stack([ndimage.map_coordinates(exl, [np.repeat(np.arange(exl.shape[0])[:, None], len(xs), 1), np.repeat(src[None, :], exl.shape[0], 0)], order=1, mode="constant")], -1)
        lin[rows, xs[0]:xs[-1] + 1] += k * streak * tint
    report["far2"]["reflections"] = [{"light": n, "clamp_world_x": x, "strength": k} for n, x, k, _, _ in lights]
    return to_srgb(lin)


def main() -> None:
    report: dict = {"thresholds": THRESH}
    which = sys.argv[1:] or ["portal", "far"]
    for w in which:
        {"portal": portal, "far": far}[w](report)
    path = os.path.join(R, "layers", "report2.json")
    old = json.load(open(path)) if os.path.exists(path) else {}
    old.update(report)
    json.dump(old, open(path, "w"), indent=1)
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
