"""Rasteriser for cell_spec.json (scratch). Mirrors cell_proto.gd: same states, groups and motion."""
import json
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFont

FONT = None


def load(path):
    with open(path) as f:
        return json.load(f)


def hexc(h, a=1.0):
    h = h.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    aa = int(h[6:8], 16) / 255 if len(h) == 8 else 1.0
    return (r, g, b, aa * a)


def shown(cond, phase, opening):
    eff = 2 if opening > 0.001 else phase
    return {
        "always": True, "closed": opening <= 0.001, "open": opening > 0.001,
        "p0": eff == 0, "p1": eff == 1, "p2": eff == 2, "p_ge1": eff >= 1,
    }.get(cond, True)


def leaf_s(spec, o):
    a_end, a_frac = spec["stage"]["a_end"], spec["stage"]["a_frac"]
    return a_frac * o / a_end if o < a_end else a_frac + (1 - a_frac) * (o - a_end) / (1 - a_end)


def xf(spec, pt, group, opening):
    x, y = pt
    if group == "leaf":
        x -= spec["travel"] * leaf_s(spec, opening)
    elif group == "keeper_fall":
        kf = spec["keeper_fall"]
        t = min(max(opening / kf["span"], 0.0), 1.0)
        px, py = kf["pivot"]
        a = math.radians(kf["rot_deg"] * t)
        dx, dy = x - px, y - py
        x = px + dx * math.cos(a) - dy * math.sin(a) + kf["end"][0] * t
        y = py + dx * math.sin(a) + dy * math.cos(a) + kf["end"][1] * t * t
    return x, y


class Canvas:
    def __init__(self, view, k, bg=(0, 0, 0, 0), ss=3):
        self.x0, self.y0, self.x1, self.y1 = view
        self.k = k * ss
        self.ss = ss
        self.w = int(round((self.x1 - self.x0) * self.k))
        self.h = int(round((self.y1 - self.y0) * self.k))
        self.img = Image.new("RGBA", (self.w, self.h), bg)

    def P(self, x, y):
        return ((x - self.x0) * self.k, (y - self.y0) * self.k)

    def _comp(self, layer):
        self.img = Image.alpha_composite(self.img, layer)

    def fill(self, draw_fn, rgba):
        r, g, b, a = rgba
        lay = Image.new("RGBA", (self.w, self.h), (r, g, b, 0))
        m = Image.new("L", (self.w, self.h), 0)
        draw_fn(ImageDraw.Draw(m))
        lay.putalpha(m.point(lambda v: int(v * a)))
        self._comp(lay)

    def gtri(self, pts, cols):
        """Gouraud triangle (cols as rgba with alpha 0..1)."""
        P = np.array([self.P(*p) for p in pts], dtype=np.float64)
        xmin, ymin = np.floor(P.min(0)).astype(int)
        xmax, ymax = np.ceil(P.max(0)).astype(int)
        xmin, ymin = max(xmin, 0), max(ymin, 0)
        xmax, ymax = min(xmax, self.w - 1), min(ymax, self.h - 1)
        if xmax < xmin or ymax < ymin:
            return
        ys, xs = np.mgrid[ymin:ymax + 1, xmin:xmax + 1] + 0.5
        (x1, y1), (x2, y2), (x3, y3) = P
        d = (y2 - y3) * (x1 - x3) + (x3 - x2) * (y1 - y3)
        if abs(d) < 1e-9:
            return
        l1 = ((y2 - y3) * (xs - x3) + (x3 - x2) * (ys - y3)) / d
        l2 = ((y3 - y1) * (xs - x3) + (x1 - x3) * (ys - y3)) / d
        l3 = 1 - l1 - l2
        inside = (l1 >= -1e-6) & (l2 >= -1e-6) & (l3 >= -1e-6)
        C = np.array(cols, dtype=np.float64)
        rgb = l1[..., None] * C[0, :3] + l2[..., None] * C[1, :3] + l3[..., None] * C[2, :3]
        al = (l1 * C[0, 3] + l2 * C[1, 3] + l3 * C[2, 3]) * inside
        base = np.asarray(self.img, dtype=np.float64)[ymin:ymax + 1, xmin:xmax + 1]
        ba = base[..., 3:4] / 255
        sa = al[..., None]
        oa = sa + ba * (1 - sa)
        orgb = np.where(oa > 0, (rgb * sa + base[..., :3] * ba * (1 - sa)) / np.maximum(oa, 1e-9), 0)
        out = np.concatenate([orgb, oa * 255], axis=-1).clip(0, 255).astype(np.uint8)
        arr = np.asarray(self.img).copy()
        arr[ymin:ymax + 1, xmin:xmax + 1] = out
        self.img = Image.fromarray(arr, "RGBA")

    def result(self):
        return self.img.resize((self.w // self.ss, self.h // self.ss), Image.LANCZOS)


def font(px, path):
    return ImageFont.truetype(path, max(1, int(round(px))))


def draw_prims(cv, spec, phase, opening, fontpath, keep=lambda p: True):
    for p in spec["prims"]:
        if not keep(p) or not shown(p["cond"], phase, opening):
            continue
        g = p["g"]
        col = hexc(p["c"], p["a"])
        k = p["k"]
        if k == "rect":
            x, y, w, h = p["r"]
            pts = [xf(spec, q, g, opening) for q in [(x, y), (x + w, y), (x + w, y + h), (x, y + h)]]
            cv.fill(lambda d, pts=pts: d.polygon([cv.P(*q) for q in pts], fill=255), col)
        elif k == "poly":
            pts = [xf(spec, q, g, opening) for q in p["pts"]]
            cv.fill(lambda d, pts=pts: d.polygon([cv.P(*q) for q in pts], fill=255), col)
        elif k == "line":
            a = xf(spec, p["p"][0], g, opening)
            b = xf(spec, p["p"][1], g, opening)
            w = max(1, int(round(p["w"] * cv.k)))
            cv.fill(lambda d, a=a, b=b, w=w: d.line([cv.P(*a), cv.P(*b)], fill=255, width=w), col)
        elif k == "circle":
            cx, cy = xf(spec, p["ctr"], g, opening)
            r = p["rad"]
            cv.fill(lambda d, cx=cx, cy=cy, r=r: d.ellipse([*cv.P(cx - r, cy - r), *cv.P(cx + r, cy + r)], fill=255), col)
        elif k == "gpoly":
            pts = [xf(spec, q, g, opening) for q in p["pts"]]
            cols = [hexc(c, p["a"]) for c in p["cols"]]
            cols = [(r / 1, gg / 1, b / 1, a) for r, gg, b, a in cols]
            if p.get("fan"):
                for i in range(1, len(pts) - 1):
                    cv.gtri([pts[0], pts[i], pts[i + 1]], [cols[0], cols[i], cols[i + 1]])
            else:
                for i in range(1, len(pts) - 1):
                    cv.gtri([pts[0], pts[i], pts[i + 1]], [cols[0], cols[i], cols[i + 1]])
        elif k == "text":
            x, y = xf(spec, p["pos"], g, opening)
            f = font(p["cap"] / 0.711 * cv.k, fontpath)
            bx, by = cv.P(x, y)
            cv.fill(lambda d, f=f, bx=bx, by=by, s=p["s"]: d.text((bx, by), s, font=f, fill=255, anchor="ls"), col)
