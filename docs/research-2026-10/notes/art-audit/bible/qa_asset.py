#!/usr/bin/env python3
"""WOLF//OVERRIDE asset QA (art bible section 6). Python 3 stdlib only. Run with `python3 -I`.

usage:
  qa_asset.py FILE.png --family {character,frame,prop,door,sentry,plate-far,plate-mid,plate-near,keyart,site}
              [--scale S | --world-h H] [--zoom 1.35 --zoom 1.8 ...]
              [--baseline ROW] [--key '#ff00ff'] [--bg BG.png --bg-box x0,y0,x1,y1 --disp-h PX]
              [--json OUT.json]
  qa_asset.py DIR --family frame ...     (every *.png in DIR, plus cross-frame baseline/size checks)

Checks (each returns value, threshold, pass):
  A alpha_body      share of interior body pixels at alpha 255; max alpha must be 255
  B holes           semi-transparent pixels >=3 px inside the silhouette; longest run of banded rows
  C fringe          partial-alpha edge pixels 15+ L* darker (matte) or lighter (halo) than the
                    opaque ring 2-4 px inside them; mean a*/b* shift (key spill)
  D baseline        lowest row with >=3 px at alpha>=128, vs --baseline
  E density         source px per screen px at 960x540 / 1280x720 / 1920x1080 / 2560x1440 x each zoom
  F palette         low-chroma pixels must be cool (median b* <= 0); saturated pixels (C*>=25) must lie
                    within dE76 18 of a bible accent swatch (p90); median and p99 L*
  G noise           Immerkaer sigma on luma (0-255) inside the body, at source and at 1080p display size;
                    hf_share = share of luma variance removed by a down/up resample to 1080p display size
  H readability     (with --bg) silhouette 'lost' share (dE76 < 10 vs the background just outside)
                    and median WCAG contrast at display size
Thresholds were calibrated on 2026-10-10 against the measured assets (see calibration.jsonl).
"""
import sys, os, json, math, zlib, struct, argparse, glob

# ---------- PNG I/O ----------
def read_png(p):
    b = open(p, 'rb').read(); assert b[:8] == b'\x89PNG\r\n\x1a\n', p
    i = 8; idat = b''; plte = None
    while i < len(b):
        n, = struct.unpack('>I', b[i:i+4]); t = b[i+4:i+8]; d = b[i+8:i+8+n]; i += 12 + n
        if t == b'IHDR': w, h, bd, ct, _, _, il = struct.unpack('>IIBBBBB', d)
        elif t == b'IDAT': idat += d
    assert bd == 8 and il == 0 and ct in (0, 2, 4, 6), ('unsupported PNG', p, bd, ct, il)
    bpp = {0: 1, 2: 3, 4: 2, 6: 4}[ct]; stride = w * bpp; raw = zlib.decompress(idat)
    out = bytearray(h * stride); prev = bytearray(stride)
    for y in range(h):
        f = raw[y*(stride+1)]; line = bytearray(raw[y*(stride+1)+1:(y+1)*(stride+1)])
        if f == 1:
            for x in range(bpp, stride): line[x] = (line[x] + line[x-bpp]) & 255
        elif f == 2:
            for x in range(stride): line[x] = (line[x] + prev[x]) & 255
        elif f == 3:
            for x in range(stride): line[x] = (line[x] + (((line[x-bpp] if x >= bpp else 0) + prev[x]) >> 1)) & 255
        elif f == 4:
            for x in range(stride):
                a = line[x-bpp] if x >= bpp else 0; c = prev[x-bpp] if x >= bpp else 0; bb = prev[x]
                pp = a + bb - c; pa = abs(pp-a); pb = abs(pp-bb); pc = abs(pp-c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else (bb if pb <= pc else c))) & 255
        out[y*stride:(y+1)*stride] = line; prev = line
    n = w * h; R = bytearray(n); G = bytearray(n); B = bytearray(n); A = bytearray(b'\xff' * n)
    if ct == 6: R[:] = out[0::4]; G[:] = out[1::4]; B[:] = out[2::4]; A[:] = out[3::4]
    elif ct == 2: R[:] = out[0::3]; G[:] = out[1::3]; B[:] = out[2::3]
    elif ct == 4: R[:] = out[0::2]; G[:] = R; B[:] = R; A[:] = out[1::2]
    else: R[:] = out; G[:] = out; B[:] = out
    return w, h, R, G, B, A

# ---------- colour ----------
LIN = [(i/255/12.92 if i/255 <= 0.04045 else ((i/255+0.055)/1.055)**2.4) for i in range(256)]
_labc = {}
def lab(r, g, b):
    k = (r << 16) | (g << 8) | b; v = _labc.get(k)
    if v: return v
    R, G, B = LIN[r], LIN[g], LIN[b]
    X = (0.4124*R + 0.3576*G + 0.1805*B)/0.95047; Y = 0.2126*R + 0.7152*G + 0.0722*B; Z = (0.0193*R + 0.1192*G + 0.9505*B)/1.08883
    f = lambda t: t**(1/3) if t > 0.008856 else 7.787*t + 16/116
    v = (116*f(Y) - 16, 500*(f(X) - f(Y)), 200*(f(Y) - f(Z)))
    if len(_labc) < 2_000_000: _labc[k] = v
    return v
def hexlab(hx): hx = hx.lstrip('#'); return lab(int(hx[0:2], 16), int(hx[2:4], 16), int(hx[4:6], 16))
def lum(r, g, b): return 0.2126*LIN[r] + 0.7152*LIN[g] + 0.0722*LIN[b]
def wcag(y1, y2): hi, lo = max(y1, y2), min(y1, y2); return (hi + 0.05)/(lo + 0.05)
def pct(v, q):
    if not v: return None
    v = sorted(v); return v[min(len(v)-1, int(len(v)*q))]

# Bible accent swatches (sampled from approved key art B and approved props, see ART_BIBLE.md 3.1)
ACCENTS = {'signal_red': '#a01e29', 'red_shadow': '#5f0e17', 'red_practical': '#ad252d', 'red_glow': '#ca452f',
           'amber_glow': '#e0936e', 'amber_reflect': '#c89876', 'amber_metal': '#82510e',
           'cyan_seam': '#4f8ab8', 'cyan_keypad': '#2091ca', 'cyan_strip': '#30d0fc', 'cyan_rim': '#82c3e6',
           'lamp_shaft': '#385d85', 'cold_hi': '#4175a0', 'safe_green': '#56dc69', 'safe_green_mid': '#228237', 'safe_green_dk': '#17632f', 'amber_dim': '#6e4824', 'rust_red': '#82290f'}
ACC_LAB = [hexlab(v) for v in ACCENTS.values()]

# ---------- thresholds per family ----------
T = {
 'alpha_body_min': 0.99, 'holes_max': 0.005, 'band_rows_max': 3,
 'fringe_dark_max': {'default': 0.10}, 'fringe_light_max': 0.10, 'spill_max': 4.0,
 'palette_p90_max': 18.0, 'cool_b_max': -1.0,
 'noise_disp_max': {'character': 6.0, 'frame': 6.0, 'prop': 6.0, 'door': 6.0, 'sentry': 6.0,
                    'plate-far': 2.5, 'plate-mid': 4.0, 'plate-near': 3.0, 'keyart': 4.0, 'site': 4.0},
 'hf_share_max': {'character': 0.30, 'frame': 0.30, 'prop': 0.30, 'door': 0.30, 'sentry': 0.30,
                  'plate-far': 0.15, 'plate-mid': 0.25, 'plate-near': 0.20, 'keyart': 0.30, 'site': 0.30},
 'density_1080_min': {'plate-far': 0.70, 'default': 1.0}, 'density_960_max': 4.5,
 'lost_max': 0.35, 'contrast_med_min': 1.6,
}
CUTOUT = {'character', 'frame', 'prop', 'door', 'sentry', 'plate-near'}

def dist_transform(w, h, inside):
    """chessboard distance (capped 8) from each inside pixel to the nearest outside pixel."""
    INF = 8; d = bytearray(w*h)
    for i in range(w*h): d[i] = INF if inside[i] else 0
    for y in range(h):
        for x in range(w):
            i = y*w + x
            if not d[i]: continue
            m = d[i]
            if x > 0: m = min(m, d[i-1] + 1)
            if y > 0:
                m = min(m, d[i-w] + 1)
                if x > 0: m = min(m, d[i-w-1] + 1)
                if x < w-1: m = min(m, d[i-w+1] + 1)
            if x == 0 or y == 0 or x == w-1 or y == h-1: m = min(m, 1)
            d[i] = m
    for y in range(h-1, -1, -1):
        for x in range(w-1, -1, -1):
            i = y*w + x
            if not d[i]: continue
            m = d[i]
            if x < w-1: m = min(m, d[i+1] + 1)
            if y < h-1:
                m = min(m, d[i+w] + 1)
                if x < w-1: m = min(m, d[i+w+1] + 1)
                if x > 0: m = min(m, d[i+w-1] + 1)
            d[i] = m
    return d

def area_resize(w, h, ch, nw, nh):
    """box/area resample of float channels (list of lists) to nw x nh."""
    fx = w/nw; fy = h/nh; out = [[0.0]*(nw*nh) for _ in ch]
    xs = [(int(x*fx), max(int(x*fx)+1, int((x+1)*fx))) for x in range(nw)]
    ys = [(int(y*fy), max(int(y*fy)+1, int((y+1)*fy))) for y in range(nh)]
    for oy, (y0, y1) in enumerate(ys):
        y1 = min(y1, h)
        for ox, (x0, x1) in enumerate(xs):
            x1 = min(x1, w); n = (y1-y0)*(x1-x0)
            for c, src in enumerate(ch):
                s = 0.0
                for yy in range(y0, y1):
                    row = yy*w; s += sum(src[row+x0:row+x1])
                out[c][oy*nw+ox] = s/n
    return out

def immerkaer(w, h, L, mask=None):
    s = 0.0; n = 0
    for y in range(1, h-1):
        r0 = (y-1)*w; r1 = y*w; r2 = (y+1)*w
        for x in range(1, w-1):
            if mask is not None and not (mask[r0+x-1] and mask[r0+x+1] and mask[r2+x-1] and mask[r2+x+1] and mask[r1+x]): continue
            v = (L[r0+x-1] - 2*L[r0+x] + L[r0+x+1] - 2*L[r1+x-1] + 4*L[r1+x] - 2*L[r1+x+1] + L[r2+x-1] - 2*L[r2+x] + L[r2+x+1])
            s += abs(v); n += 1
    return (math.sqrt(math.pi/2) * s/(6*n)) if n else None

def analyse(path, a):
    fam = a.family; w, h, R, G, B, A = read_png(path); n = w*h
    res = {'file': path, 'family': fam, 'size': [w, h], 'checks': {}}
    C = res['checks']
    def chk(name, value, thr, ok, **kw):
        C[name] = dict(value=value, threshold=thr, ok=bool(ok), **kw)
    cutout = fam in CUTOUT and min(A) < 250
    body = bytearray(1 if A[i] >= 16 else 0 for i in range(n))
    opaque128 = [i for i in range(n) if A[i] >= 128]
    if opaque128:
        ys = [i//w for i in opaque128]; xs = [i % w for i in opaque128]
        bbox = [min(xs), min(ys), max(xs), max(ys)]
    else: bbox = [0, 0, w-1, h-1]
    res['opaque_bbox'] = bbox; bh = bbox[3]-bbox[1]+1
    res['opaque_fill_pct'] = round(100*len(opaque128)/n, 2)

    # A + B: body opacity, interior semi-transparency, bands
    if cutout:
        dt = dist_transform(w, h, body)
        inner = [i for i in range(n) if dt[i] >= 3]
        full = sum(1 for i in inner if A[i] == 255)
        chk('A_alpha_body', round(full/max(1, len(inner)), 4), T['alpha_body_min'], full/max(1, len(inner)) >= T['alpha_body_min'], max_alpha=max(A))
        semi = [i for i in inner if A[i] < 250]
        rows = {}
        for i in inner: rows.setdefault(i//w, [0, 0])[0] += 1
        for i in semi: rows[i//w][1] += 1
        def longest(ys):
            run = best = 0; prev = None; span = None; cur0 = None
            for y in ys:
                run = run + 1 if prev is not None and y == prev + 1 else 1
                if run == 1: cur0 = y
                if run > best: best = run; span = [cur0, y]
                prev = y
            return best, span
        minw = max(20, 0.25*(bbox[2]-bbox[0]+1))   # only rows where the body is at least a quarter of the sprite wide
        banded = sorted(y for y, (t, s) in rows.items() if t >= minw and s/t > 0.20)
        mid = [y for y in banded if bbox[1] + 12 <= y <= bbox[3] - 12]
        edge = [y for y in banded if not (bbox[1] + 12 <= y <= bbox[3] - 12)]
        best, span = longest(mid); ebest, espan = longest(edge)
        share = len(semi)/max(1, len(inner))
        chk('B_holes_share', round(share, 4), T['holes_max'], share <= T['holes_max'])
        chk('B_interior_band_rows', best, T['band_rows_max'], best <= T['band_rows_max'], band_span=span)
        chk('B_edge_fade_rows', ebest, 6, ebest <= 6, band_span=espan, note='soft fade at the top or bottom of the silhouette (baked contact shadow or wisps)')
        # C: fringe vs ring 2-4 px inside
        dark = light = tot = 0; da = db = 0.0
        for y in range(2, h-2):
            for x in range(2, w-2):
                i = y*w + x; al = A[i]
                if al < 32 or al > 224: continue
                ring = [j for j in (i-2, i+2, i-2*w, i+2*w, i-2*w-2, i-2*w+2, i+2*w-2, i+2*w+2, i-3, i+3, i-3*w, i+3*w)
                        if 0 <= j < n and A[j] >= 245 and 2 <= dt[j] <= 4]
                if len(ring) < 2: continue
                f = al/255.0
                L0, a0, b0 = lab(R[i], G[i], B[i])
                rl = sorted(lab(R[j], G[j], B[j]) for j in ring); Lr, ar, br = rl[len(rl)//2]
                tot += 1; dL = L0 - Lr
                if dL <= -15: dark += 1
                elif dL >= 15: light += 1
                da += a0 - ar; db += b0 - br
        if tot:
            chk('C_fringe_dark', round(dark/tot, 4), T['fringe_dark_max']['default'], dark/tot <= T['fringe_dark_max']['default'], edge_px=tot)
            chk('C_fringe_halo', round(light/tot, 4), T['fringe_light_max'], light/tot <= T['fringe_light_max'])
            sa, sb = da/tot, db/tot
            mag = math.hypot(sa, sb)
            chk('C_edge_chroma_shift', round(mag, 2), T['spill_max'], mag <= T['spill_max'], mean_da_db=[round(sa, 2), round(sb, 2)])
        # C2: outline and top light. ring = opaque pixels 1-3 px inside the silhouette; core = 8+ px inside
        ringL = []; topL = []; botL = []; coreL = []
        stp = max(1, int(math.sqrt(n/400000)))
        for y in range(4, h-4, stp):
            for x in range(0, w, stp):
                i = y*w + x
                if A[i] < 245: continue
                if dt[i] >= 8: coreL.append(lab(R[i], G[i], B[i])[0]); continue
                if dt[i] > 3: continue
                L0 = lab(R[i], G[i], B[i])[0]; ringL.append(L0)
                if A[i-4*w] < 16: topL.append(L0)
                elif A[i+4*w] < 16: botL.append(L0)
        if ringL and coreL:
            core = pct(coreL, .5)
            chk('C_outline_dL', round(pct(ringL, .5) - core, 1), -8.0, pct(ringL, .5) - core > -8.0,
                note='median L* of the 1-3 px rim minus the core; strongly negative = dark outline')
            if topL:
                chk('C_top_light_dL', round(pct(topL, .5) - core, 1), 0.0, pct(topL, .5) - core >= 0.0,
                    bottom_dL=round(pct(botL, .5) - core, 1) if botL else None, target=10.0,
                    note='top-facing rim vs core; the bible asks for a top/rim light (target +10)')
    # D baseline
    cnt = {}
    for i in opaque128: cnt[i//w] = cnt.get(i//w, 0) + 1
    base = max([y for y, c in cnt.items() if c >= 3], default=None)
    res['baseline_row'] = base
    if a.baseline is not None:
        chk('D_baseline', base, a.baseline, base is not None and abs(base - a.baseline) <= 1)
    # E density
    scale = a.scale if a.scale else (a.world_h/bh if a.world_h else None)
    if scale:
        dens = {}
        for z in a.zoom:
            for H in (540, 720, 1080, 1440):
                S = H/540*z; dens['%dp@z%g' % (H, z)] = round(1/(scale*S), 3)
        res['density'] = dens
        zmax = max(a.zoom); d1080 = 1/(scale*2*zmax); d960 = 1/(scale*1*min(a.zoom))
        mn = T['density_1080_min'].get(fam, T['density_1080_min']['default'])
        chk('E_density_1080_maxzoom', round(d1080, 3), mn, d1080 >= mn)
        chk('E_density_960_minzoom', round(d960, 3), T['density_960_max'], d960 <= T['density_960_max'])
    # F palette
    step = max(1, int(math.sqrt(n/250000)))
    lowb = []; Ls = []; sat = []; accent_share = 0; m = 0
    for y in range(0, h, step):
        for x in range(0, w, step):
            i = y*w + x
            if A[i] < 250: continue
            L, aa, bb = lab(R[i], G[i], B[i]); Cc = math.hypot(aa, bb); m += 1; Ls.append(L)
            if Cc < 12: lowb.append(bb)
            elif Cc >= 25:
                accent_share += 1
                if L >= 15: sat.append(min(math.sqrt((L-q[0])**2 + (aa-q[1])**2 + (bb-q[2])**2) for q in ACC_LAB))
    res['L_med'] = round(pct(Ls, .5), 1) if Ls else None; res['L_p99'] = round(pct(Ls, .99), 1) if Ls else None
    res['accent_share'] = round(accent_share/max(1, m), 4)
    mb = pct(lowb, .5)
    if mb is not None: chk('F_cool_neutrals_b', round(mb, 2), T['cool_b_max'], mb <= T['cool_b_max'] + 1e-9)
    if sat:
        p90 = pct(sat, .9); chk('F_accent_dE_p90', round(p90, 1), T['palette_p90_max'], p90 <= T['palette_p90_max'], n_sat=len(sat))
    # G noise
    Y = [0.2126*R[i] + 0.7152*G[i] + 0.0722*B[i] for i in range(n)]
    msk = bytearray(1 if A[i] >= 250 else 0 for i in range(n))
    sig = immerkaer(w, h, Y, msk); res['noise_sigma_src'] = round(sig, 2) if sig else None
    dscale = None
    if scale: dscale = 1/(scale*2*max(a.zoom))       # src px per 1080p screen px at max zoom
    elif a.disp_h: dscale = bh/a.disp_h
    if dscale and dscale > 1.05:
        nw, nh = max(8, round(w/dscale)), max(8, round(h/dscale))
        Ap = [A[i]/255.0 for i in range(n)]; Yp = [Y[i]*Ap[i] for i in range(n)]
        Yd, Ad = area_resize(w, h, [Yp, Ap], nw, nh)
        Yd = [Yd[i]/Ad[i] if Ad[i] > 0.004 else 0 for i in range(nw*nh)]
        md = bytearray(1 if Ad[i] >= 0.98 else 0 for i in range(nw*nh))
        sd = immerkaer(nw, nh, Yd, md); res['display_size'] = [nw, nh]
        if sd is not None:
            chk('G_noise_display', round(sd, 2), T['noise_disp_max'][fam], sd <= T['noise_disp_max'][fam])
        # hf share: variance of (src - bilinear(up(down(src)))) / variance(src) on opaque pixels
        num = den = 0.0; mu = sum(Y[i] for i in range(n) if msk[i])/max(1, sum(msk))
        for y in range(0, h, step):
            fy = min(nh-1.0001, max(0, (y+0.5)/dscale - 0.5)); y0 = int(fy); ty = fy - y0
            for x in range(0, w, step):
                i = y*w + x
                if not msk[i]: continue
                fx = min(nw-1.0001, max(0, (x+0.5)/dscale - 0.5)); x0 = int(fx); tx = fx - x0
                j = y0*nw + x0
                v = (Yd[j]*(1-tx) + Yd[j+1]*tx)*(1-ty) + (Yd[j+nw]*(1-tx) + Yd[j+nw+1]*tx)*ty
                num += (Y[i] - v)**2; den += (Y[i] - mu)**2
        if den > 0: chk('G_hf_share', round(num/den, 3), T['hf_share_max'][fam], num/den <= T['hf_share_max'][fam])
    # H readability over a background (display scale)
    if a.bg and (scale or a.disp_h):
        bw, bh2, bR, bG, bB, _ = read_png(a.bg)
        x0, y0, x1, y1 = [int(v) for v in a.bg_box.split(',')] if a.bg_box else (0, 0, bw, bh2)
        tgt_h = a.disp_h if a.disp_h else round(bh/(dscale or 1))
        f = bh/tgt_h; cw, chh = bbox[2]-bbox[0]+1, bh
        nw, nh = max(4, round(cw/f)), max(4, round(chh/f))
        crop = lambda ch: [ch[(bbox[1]+yy)*w + bbox[0] + xx] for yy in range(chh) for xx in range(cw)]
        Ap = [v/255.0 for v in crop(A)]
        ch = [[c*al for c, al in zip([LIN[v] for v in crop(X)], Ap)] for X in (R, G, B)]
        rd, gd, bd_, ad = area_resize(cw, chh, ch + [Ap], nw, nh)
        ox = x0 + ((x1-x0) - nw)//2; oy = y1 - nh      # feet on the bottom of the box
        lost = tot = 0; crs = []
        enc = lambda v: max(0, min(255, round(255*(v*12.92 if v <= 0.0031308 else 1.055*v**(1/2.4) - 0.055))))
        for yy in range(1, nh-1):
            for xx in range(1, nw-1):
                k = yy*nw + xx
                if ad[k] < 0.5: continue
                if min(ad[k-1], ad[k+1], ad[k-nw], ad[k+nw]) >= 0.5: continue
                bx, by = ox + xx, oy + yy
                outs = [(bx+dx, by+dy) for dx, dy in ((-2, 0), (2, 0), (0, -2), (0, 2))
                        if not (0 <= yy+dy < nh and 0 <= xx+dx < nw) or ad[(yy+dy)*nw + xx+dx] < 0.1]
                outs = [(u, v) for u, v in outs if 0 <= u < bw and 0 <= v < bh2]
                if not outs: continue
                u, v = outs[0]; q = v*bw + u
                bl = lab(bR[q], bG[q], bB[q]); bY = lum(bR[q], bG[q], bB[q])
                ar_ = ad[k]; comp = [enc(c + LIN[bc]*(1-ar_)) for c, bc in ((rd[k], bR[by*bw+bx]), (gd[k], bG[by*bw+bx]), (bd_[k], bB[by*bw+bx]))]
                sl = lab(*comp); sY = lum(*comp)
                dE = math.sqrt(sum((p-q2)**2 for p, q2 in zip(sl, bl)))
                tot += 1; lost += dE < 10; crs.append(wcag(sY, bY))
        if tot:
            chk('H_lost_share', round(lost/tot, 3), T['lost_max'], lost/tot <= T['lost_max'], perimeter_px=tot)
            chk('H_contrast_median', round(pct(crs, .5), 2), T['contrast_med_min'], pct(crs, .5) >= T['contrast_med_min'],
                share_ge_3=round(sum(1 for c in crs if c >= 3)/tot, 3))
    res['pass'] = all(c['ok'] for c in C.values())
    return res

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('path'); ap.add_argument('--family', required=True, choices=sorted(T['noise_disp_max']))
    ap.add_argument('--scale', type=float); ap.add_argument('--world-h', type=float)
    ap.add_argument('--zoom', type=float, action='append'); ap.add_argument('--baseline', type=int)
    ap.add_argument('--bg'); ap.add_argument('--bg-box'); ap.add_argument('--disp-h', type=float)
    ap.add_argument('--json')
    a = ap.parse_args(); a.zoom = a.zoom or [1.35]
    files = sorted(glob.glob(os.path.join(a.path, '*.png'))) if os.path.isdir(a.path) else [a.path]
    out = [analyse(f, a) for f in files]
    if len(out) > 1:
        sizes = {tuple(r['size']) for r in out}; bases = [r['baseline_row'] for r in out]
        out.append({'set': a.path, 'same_canvas': len(sizes) == 1, 'baseline_spread': (max(bases)-min(bases)) if None not in bases else None,
                    'pass': len(sizes) == 1})
    s = json.dumps(out if len(out) > 1 else out[0], indent=1)
    if a.json: open(a.json, 'w').write(s)
    print(s)
    sys.exit(0 if all(r['pass'] for r in out) else 1)

if __name__ == '__main__':
    main()
