"""Deterministic cleanup and split of the painted beacons (add7 item d).

Reads codex/paint-beacons/out/beacons-painted.png (never modified) and the construction in
tools/design.py, and writes under layers/:
  b{0,1}-fixture.png  static fixture: conduit, bracket, housing, collar, wall contact shadow (RGBA)
  b{0,1}-globe.png    greyscale glass, drawn tinted by the live lens colour (RGBA)
  b{0,1}-guard.png    the cage in front of the globe (RGBA)
  b{0,1}-light.png    the lamp's light: glass, a faint bloom and the red spill on the wall (white RGB,
                      strength in alpha; drawn additive, tinted by warning_color, pulsed in game)
  corridor-beacons.png  the atlas of all eight, with 2 px gutters
  placement.json        atlas regions, offsets from each anchor, world rects, code values
  report.json           checks (silhouette, holes, value plan) and measurements
  preview-*.png         the static and lit composites on the real far plate, 8x
Every pixel's coverage comes from the construction masks; Codex's colour is only sampled inside them.
"""
import json
import os
import sys
import numpy as np
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import design as D  # noqa: E402

ROOT = D.ROOT
OUT = os.path.join(ROOT, "layers")
PAINT = os.path.join(ROOT, "codex/paint-beacons/out/beacons-painted.png")
SS = D.SS
WARN = np.array([1.0, 0x4a / 255.0, 0x46 / 255.0])
BEACON_ALPHA = 0.4
SETTLED_ALPHA = 0.1


def block_mean(img, w, ss):
    """Mean of img over each ss x ss block, weighted by w (0 where w sums to 0)."""
    h, wd = w.shape
    ws = w.reshape(h // ss, ss, wd // ss, ss).sum(axis=(1, 3))
    if img.ndim == 3:
        num = (img * w[..., None]).reshape(h // ss, ss, wd // ss, ss, img.shape[2]).sum(axis=(1, 3))
        return np.where(ws[..., None] > 0, num / np.maximum(ws, 1e-9)[..., None], 0.0)
    num = (img * w).reshape(h // ss, ss, wd // ss, ss).sum(axis=(1, 3))
    return np.where(ws > 0, num / np.maximum(ws, 1e-9), 0.0)


def fill_rows(img, hole, keep):
    """Fill hole pixels row by row by linear interpolation between kept pixels (globe under bars)."""
    out = img.copy()
    for y in range(img.shape[0]):
        k = np.nonzero(keep[y])[0]
        hcols = np.nonzero(hole[y])[0]
        if k.size < 2 or hcols.size == 0:
            continue
        for ch in range(img.shape[2]):
            out[y, hcols, ch] = np.interp(hcols, k, img[y, k, ch])
    return out


def gauss_blur(a, sigma):
    if sigma <= 0:
        return a
    r = int(np.ceil(sigma * 3))
    k = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2)
    k /= k.sum()
    p = np.pad(a, r, mode="constant")
    p = np.apply_along_axis(lambda m: np.convolve(m, k, mode="valid"), 0, p)
    p = np.apply_along_axis(lambda m: np.convolve(m, k, mode="valid"), 1, p)
    return p


def paste_clip(dst, src, dy, dx):
    """dst[dy:, dx:] = src, clipped to dst's bounds (offsets may be negative)."""
    H, W = dst.shape[:2]
    h, w = src.shape[:2]
    y0, x0 = max(dy, 0), max(dx, 0)
    y1, x1 = min(dy + h, H), min(dx + w, W)
    if y1 > y0 and x1 > x0:
        dst[y0:y1, x0:x1] = src[y0 - dy:y1 - dy, x0 - dx:x1 - dx]


def luma(rgb):
    return rgb[..., 0] * 0.299 + rgb[..., 1] * 0.587 + rgb[..., 2] * 0.114


def main():
    os.makedirs(OUT, exist_ok=True)
    paint_img = Image.open(PAINT).convert("RGB")
    report = {"paint_size": paint_img.size}
    if paint_img.size != (1024, 1024):
        paint_img = paint_img.resize((1024, 1024), Image.LANCZOS)
    paint = np.asarray(paint_img).astype(float)
    target = np.asarray(Image.open(os.path.join(ROOT, "design/codex-target.png")).convert("RGB")).astype(float)
    layout = json.load(open(os.path.join(ROOT, "design/codex-layout.json")))
    far = np.asarray(Image.open(D.FAR).convert("RGB")).astype(float)
    layers = {}
    for i, b in enumerate(D.BEACONS):
        name = b["name"]
        c, T = b["c"], b["T"]
        lay = layout["beacons"][i]
        ox, oy = lay["offset"]
        wx0, wy0, wx1, wy1 = lay["plate_window"]
        pw = paint[oy:oy + (wy1 - wy0) * SS, ox:ox + (wx1 - wx0) * SS]
        tw = target[oy:oy + (wy1 - wy0) * SS, ox:ox + (wx1 - wx0) * SS]
        U, V = D.grid(wx0, wy0, wx1, wy1, SS, c, T)
        m = D.parts(U, V, b)
        cage = m["guard_ring"] | m["guard_bars"] | m["guard_cap"]
        globe = m["globe"] & ~cage
        fixture = np.zeros_like(cage)
        for k, mk in m.items():
            if k not in ("globe", "guard_ring", "guard_bars", "guard_cap") and not k.startswith("conduit"):
                fixture |= mk
        # Value plan: Codex's fixture luma against the construction's, per beacon; pull back any drift
        # beyond +-20% with one gain (keeps Codex's material, restores the plan's brightness).
        lp, lt = luma(pw)[fixture].mean(), luma(tw)[fixture].mean()
        gain = float(np.clip(lt / max(lp, 1e-6), 0.8, 1.25)) if abs(lp / lt - 1) > 0.2 else 1.0
        report[f"{name}_fixture_luma_codex"] = round(float(lp), 1)
        report[f"{name}_fixture_luma_plan"] = round(float(lt), 1)
        report[f"{name}_fixture_gain"] = round(gain, 3)
        cage_lp = luma(pw)[cage].mean()
        report[f"{name}_cage_luma_codex"] = round(float(cage_lp), 1)
        # 1x layers on the window grid
        fx_rgb = block_mean(np.clip(pw * gain, 0, 255), fixture.astype(float), SS)
        fx_a = D.down(fixture.astype(float), SS)
        gl_src = fill_rows(pw, m["globe"] & cage, globe)
        gl_rgb = block_mean(gl_src, m["globe"].astype(float), SS)
        gl_a = D.down(m["globe"].astype(float), SS)
        # The cage is neutral steel: Codex's value, its red cast removed (the live light adds it back).
        cg = pw.copy()
        cl = luma(cg)
        cg = np.stack([cl, cl * 1.04 + 1, cl * 1.12 + 2], -1)
        cg_rgb = block_mean(np.clip(cg * gain, 0, 255), cage.astype(float), SS)
        cg_a = D.down(cage.astype(float), SS)
        # The globe as greyscale tint: red channel over 255, so lens * #ff4a46 gives Codex's red back.
        g = np.clip(gl_rgb[..., 0] / 255.0, 0, 1)
        gmax = g[gl_a > 0.5].max()
        g = np.clip(g / max(gmax, 1e-6), 0, 1)
        report[f"{name}_globe_red_max"] = round(float(gmax * 255), 1)
        layers[name] = {"window": [wx0, wy0, wx1, wy1], "fx": (fx_rgb, fx_a), "globe": g, "globe_a": gl_a, "cage": (cg_rgb, cg_a), "masks": m}
        # sanity: silhouettes are the construction's by construction; record coverage sums
        report[f"{name}_coverage_px"] = {"fixture": round(float(fx_a.sum()), 1), "globe": round(float(gl_a.sum()), 1), "guard": round(float(cg_a.sum()), 1)}

    atlas_parts = []
    previews = []
    for i, b in enumerate(D.BEACONS):
        name = b["name"]
        L = layers[name]
        c, T = b["c"], b["T"]
        x0, y0, x1, y1 = b["canvas"]
        H, W = y1 - y0, x1 - x0
        # Full-canvas masks (conduit included) at 1x.
        Uc, Vc = D.grid(x0, y0, x1, y1, SS, c, T)
        mc = D.parts(Uc, Vc, b)
        wx0, wy0, wx1, wy1 = L["window"]

        def place(arr, fill=0.0):
            out = np.full((H, W) + arr.shape[2:], fill, dtype=float)
            out[wy0 - y0:wy1 - y0, wx0 - x0:wx1 - x0] = arr
            return out

        fx_rgb, fx_a = place(L["fx"][0]), place(L["fx"][1])
        lit = name == "b1"
        # Deterministic conduit parts: the corridor's own 3 px conduit profile and strap steel
        # (sampled from the far plate's existing conduit above the right box), scaled to this wall.
        prof = np.array([[58, 75, 79], [56, 72, 75], [47, 61, 63]], dtype=float)
        strap = np.array([53, 75, 86], dtype=float)
        k = 1.0 if lit else 0.36
        for part in [p for p in D.ORDER if p.startswith("conduit") and p in mc]:
            cov = D.down(mc[part].astype(float), SS)
            col = np.zeros((H, W, 3))
            xs = np.arange(W) + x0 - (c + 0.5)
            idx = np.clip(np.floor(xs + 1.5).astype(int), 0, 2)
            col[:] = prof[idx][None, :, :] * k
            if part in ("conduit_straps", "conduit_fitting", "conduit_hub"):
                ys = np.nonzero(cov.max(axis=1) > 0)[0]
                col[:] = strap * k * 0.85
                for y in ys:  # lit top row of each strap / fitting run
                    if y == 0 or cov[y - 1].max() == 0:
                        col[y] = strap * k * 1.15
            # conduit below fixture-hub level is behind the fixture's own layer (drawn first)
            a_new = cov * (1 - fx_a)
            fx_rgb = (fx_rgb * fx_a[..., None] + col * a_new[..., None]) / np.maximum(fx_a + a_new, 1e-6)[..., None]
            fx_a = np.clip(fx_a + a_new, 0, 1)
        # Contact shadow on the wall: the parts that stand off the wall (hub, housing, collar, globe,
        # guard) dropped straight down by the light above, soft; plus a 1 px line under the flush
        # bracket plate. b1 sits under a pendant (short, firmer); b0 in dim ambient (softer, fainter).
        cast = np.zeros((H * SS, W * SS), dtype=bool)
        for p in D.SHADOW_CASTERS:
            cast |= mc[p]
        cov = D.down(cast.astype(float), SS)
        drop, sigma, strength = (5, 1.4, 0.55) if lit else (3, 2.0, 0.35)
        sh = np.zeros_like(cov)
        sh[drop:] = cov[:-drop]
        sh = np.clip(gauss_blur(sh, sigma) * 1.3, 0, 1) * strength
        plate_cov = D.down(mc["bracket_plate"].astype(float), SS)
        lip = np.zeros_like(plate_cov)
        lip[1:] = plate_cov[:-1]
        lip = np.clip(lip - plate_cov, 0, 1) * 0.45
        sh = np.clip(np.maximum(sh, lip), 0, 1)
        # fixture over shadow (shadow is black)
        a_out = fx_a + sh * (1 - fx_a)
        rgb_out = np.where(a_out[..., None] > 0, fx_rgb * fx_a[..., None] / np.maximum(a_out, 1e-6)[..., None], 0)
        base = np.dstack([rgb_out, a_out * 255])
        globe_l = np.dstack([np.repeat(place(L["globe"])[..., None], 3, -1) * 255, place(L["globe_a"]) * 255])
        cg_rgb, cg_a = place(L["cage"][0]), place(L["cage"][1])
        guard = np.dstack([cg_rgb, cg_a * 255])
        # Light: glass emission + faint bloom + spill on the wall from a globe 0.32 m (25.6 px) off the
        # wall, sampled as points in the glass, each blocked above by the housing and collar (a
        # cylinder of radius 7 px over v 10..21 at the same stand-off), falling as d / r^3.
        lx0, lx1 = c - 40, c + 41
        ly0, ly1 = T - 14, T + 82
        LW, LH = lx1 - lx0, ly1 - ly0
        xs = np.arange(LW) + lx0 + 0.5 - (c + 0.5)
        ys = np.arange(LH) + ly0 + 0.5 - T
        X, Y = np.meshgrid(xs, ys)
        dwall = 25.6
        pts = [(su, sv, sz) for su in (-3.5, 0.0, 3.5) for sv in (23.0, 26.0, 29.5) for sz in (-3.0, 0.0, 3.0)]
        E = np.zeros_like(X)
        for su, sv, sz in pts:
            dz = dwall + sz
            dx, dy = X - su, Y - sv
            r2 = dx * dx + dy * dy + dz * dz
            e = dz / r2 ** 1.5
            # housing: the ray leaves the axis' cylinder (radius 7) at t = 7 / horizontal distance
            hd = np.sqrt(dx * dx + dz * dz)
            t = np.clip(7.0 / np.maximum(hd, 1e-6), 0, 1)
            vexit = sv + dy * t
            e = np.where((vexit < 21.0) & (dy < 0), e * 0.06, e)
            E += e
        E /= E.max()
        # the wall's own texture modulates what it reflects (stains darker), from the far plate
        wall = luma(far[ly0:ly1, lx0:lx1])
        smooth = gauss_blur(wall, 4.0)
        tex = np.clip(wall / np.maximum(smooth, 1.0), 0.6, 1.4)
        R = np.sqrt((X / (LW / 2.0)) ** 2 + ((Y - 26.0) / (LH * 0.62)) ** 2)
        window = np.clip(1 - R ** 2, 0, 1) ** 2
        # 0.8: a red lockdown lamp bright enough to put a readable pool on the wall at the pulse peak
        spill = 0.8 * E * tex * window
        # glass emission and bloom (globe greyscale on the light grid)
        gl_full = np.zeros((LH, LW))
        ga_full = np.zeros((LH, LW))
        gy0, gx0 = y0 - ly0, x0 - lx0
        paste_clip(gl_full, place(L["globe"]) * place(L["globe_a"]), gy0, gx0)
        paste_clip(ga_full, place(L["globe_a"]), gy0, gx0)
        bloom = gauss_blur(gl_full, 2.2) * 0.30
        light = np.maximum(spill, 0) * (1 - ga_full) + gl_full + bloom * (1 - ga_full)
        # surfaces of the fixture that face away from the glass take little of its light
        fxa_full = np.zeros((LH, LW))
        paste_clip(fxa_full, fx_a, gy0, gx0)
        cga_full = np.zeros((LH, LW))
        paste_clip(cga_full, cg_a, gy0, gx0)
        above = (Y < 21.0)
        light = light * (1 - fxa_full * np.where(above, 0.85, 0.5)) * (1 - cga_full * 0.65)
        light = np.clip(light, 0, 1)
        light_l = np.dstack([np.full((LH, LW, 3), 255.0), light * 255])
        for part, arr, dest in (("fixture", base, (x0, y0)), ("globe", globe_l, (x0, y0)), ("guard", guard, (x0, y0)), ("light", light_l, (lx0, ly0))):
            # trim to opaque bounds
            a = arr[..., 3]
            ys_, xs_ = np.nonzero(a > 0.5)  # alpha in 0..255
            if ys_.size == 0:
                raise SystemExit(f"empty {name} {part}")
            t0, t1, l0, l1 = ys_.min(), ys_.max() + 1, xs_.min(), xs_.max() + 1
            crop = arr[t0:t1, l0:l1]
            img = Image.fromarray(np.clip(np.round(crop), 0, 255).astype(np.uint8), "RGBA")
            img.save(os.path.join(OUT, f"{name}-{part}.png"))
            atlas_parts.append({"beacon": i, "part": part, "img": img, "dest": [dest[0] + int(l0), dest[1] + int(t0)]})
        previews.append((b, base, globe_l, guard, light_l, (x0, y0), (lx0, ly0)))

    # Pack the atlas: lights first (largest), then the rest, shelf packing with 2 px gutters.
    order = sorted(range(len(atlas_parts)), key=lambda j: -atlas_parts[j]["img"].size[1])
    AW = 256
    x = y = shelf = 0
    G = 2
    for j in order:
        w, h = atlas_parts[j]["img"].size
        if x + w + G > AW:
            x, y, shelf = 0, y + shelf + G, 0
        atlas_parts[j]["region"] = [x + G, y + G, w, h]
        x += w + G
        shelf = max(shelf, h + G)
    AH = y + shelf + G
    AH = int(np.ceil(AH / 4.0) * 4)
    atlas = Image.new("RGBA", (AW, AH), (0, 0, 0, 0))
    for p in atlas_parts:
        img = p["img"]
        if p["part"] == "light":
            # white RGB everywhere in the light's padded box so filtering never pulls in black
            pad = Image.new("RGBA", (img.size[0] + 2 * G, img.size[1] + 2 * G), (255, 255, 255, 0))
            atlas.paste(pad, (p["region"][0] - G, p["region"][1] - G))
        atlas.paste(img, (p["region"][0], p["region"][1]))
    atlas.save(os.path.join(OUT, "corridor-beacons.png"))
    report["atlas_size"] = [AW, AH]
    report["atlas_bytes_rgba8"] = AW * AH * 4

    anchors = [b["anchor"] for b in D.BEACONS]
    placement = {"atlas": "res://assets/props/corridor-beacons.png", "atlas_size": [AW, AH],
                 "plate_to_world": 0.5, "far_plate_px": [1920, 1080],
                 "far_rect_world": {"position": [0.0, 78.5], "size": [960.0, 540.0]},
                 "parts_order": ["fixture", "globe", "guard", "light"], "beacons": []}
    regions, offsets = [], []
    for i, b in enumerate(D.BEACONS):
        ax, ay = anchors[i]
        entry = {"name": b["name"], "replaces": f"RoomDepth Beacon{i} (code-drawn housing, Beacon._draw) and WarningGlow{i} (90x90 radial glow)",
                 "warning_lamps_fraction": [round(ax / 1920, 4), round(ay / 1080, 4)],
                 "anchor_plate_px": [round(ax, 2), round(ay, 2)],
                 "anchor_world_backdrop": [round(ax * 0.5, 2), round(78.5 + ay * 0.5, 2)], "parts": {}}
        for part in placement["parts_order"]:
            p = next(q for q in atlas_parts if q["beacon"] == i and q["part"] == part)
            off = [round(p["dest"][0] - ax, 2), round(p["dest"][1] - ay, 2)]
            entry["parts"][part] = {"atlas_region": p["region"], "dest_plate_px": p["dest"], "offset_from_anchor_plate_px": off,
                                    "world_rect_backdrop": [p["dest"][0] * 0.5, 78.5 + p["dest"][1] * 0.5, p["region"][2] * 0.5, p["region"][3] * 0.5]}
            regions.append(p["region"])
            offsets.append(off)
        placement["beacons"].append(entry)
    placement["tscn"] = {
        "beacon_atlas": "ExtResource(\"23_beacons\")",
        "beacon_regions": "Array[Rect2]([" + ", ".join("Rect2(%d, %d, %d, %d)" % tuple(r) for r in regions) + "])",
        "beacon_offsets": "PackedVector2Array(" + ", ".join("%g, %g" % tuple(o) for o in offsets) + ")",
    }
    json.dump(placement, open(os.path.join(OUT, "placement.json"), "w"), indent=1)

    # Previews on the real far plate (static; lit at the pulse peak; settled), 8x.
    for b, base, globe_l, guard, light_l, (x0, y0), (lx0, ly0) in previews:
        for state, lens_col, alpha in (("lockdown-peak", WARN, BEACON_ALPHA), ("lockdown-trough", WARN, BEACON_ALPHA * 0.55), ("settled", WARN * 0.4, SETTLED_ALPHA), ("plate-only", None, None)):
            LW, LH = light_l.shape[1], light_l.shape[0]
            ux0, uy0 = min(x0, lx0), min(y0, ly0)
            ux1, uy1 = max(x0 + base.shape[1], lx0 + LW), max(y0 + base.shape[0], ly0 + LH)
            canvas = far[uy0:uy1, ux0:ux1].copy()
            if state != "plate-only":
                def over(dst, src, dx, dy, tint=None):
                    h, w = src.shape[:2]
                    a = src[..., 3:4] / 255.0
                    col = src[..., :3] * (tint if tint is not None else 1.0)
                    dst[dy:dy + h, dx:dx + w] = dst[dy:dy + h, dx:dx + w] * (1 - a) + col * a
                over(canvas, base, x0 - ux0, y0 - uy0)
                over(canvas, globe_l, x0 - ux0, y0 - uy0, lens_col)
                over(canvas, guard, x0 - ux0, y0 - uy0)
                add = np.zeros_like(canvas)
                paste_clip(add, (light_l[..., 3:4] / 255.0) * 255 * WARN * alpha, ly0 - uy0, lx0 - ux0)
                canvas = canvas + add
            Image.fromarray(np.clip(canvas, 0, 255).astype(np.uint8)).resize(((ux1 - ux0) * 8, (uy1 - uy0) * 8), Image.NEAREST).save(os.path.join(OUT, f"preview-{b['name']}-{state}-8x.png"))
    # measurements for the report
    for i, (b, base, globe_l, guard, light_l, _, _) in enumerate(previews):
        la = light_l[..., 3] / 255.0
        report[f"{b['name']}_light_peak_add_R_at_pulse_peak"] = round(float(la.max() * 255 * BEACON_ALPHA), 1)
        report[f"{b['name']}_light_size_plate_px"] = [la.shape[1], la.shape[0]]
    json.dump(report, open(os.path.join(OUT, "report.json"), "w"), indent=1)
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
