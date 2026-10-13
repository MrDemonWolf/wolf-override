"""Option B containment cell: the single geometry source (scratch design, not game code).

Every part is a primitive in WORLD px (1 m = 39.8 px, floor y 440). Each primitive has a layer
(back = behind WOLF, front = fixed shell in front of WOLF, leaf = the sliding door in front of the
shell), a group (how it moves) and a visibility condition (which state shows it). The same JSON
drives the Python construction drawing and the scratch-only Godot prototype (cell_proto.gd).

Revision 2 (judge's fixes): no glare streaks on the glass; the stack light stays green until the breach
(amber never lights); the blue is a pool round WOLF's body lights, not a whole-cell flood; no 6.4 px
KEEP CLEAR; one red element per view from the unit (the stack light at the breach; the lock lamp goes
amber, the reader LED is unlit). B_PLAIN=1 builds the no-text, no-keypad variant (blank plate, blanking
cover).

State: phase 0 = sealed standby, 1 = WOLF awake (cell registers it), 2 = breached;
opening 0..1 = main's IntroGate tween. Effective phase is 2 whenever opening > 0.
"""
import json
import os
import sys

PLAIN = os.environ.get("B_PLAIN") == "1"

PX_PER_M = 39.8
TRAVEL = 81.0  # leaf travel in world px (2.04 m)

# Palette, toned to the corridor plate's values (wall 12-56, floor 18-44 RGB means).
C = {
    "skin": "#2c353b", "skin_hi": "#5a6870", "skin_lo": "#171d21", "post": "#36424a",
    "leaf": "#333e45", "leaf_hi": "#63727a", "track": "#20272c", "steel": "#8d969a",
    "bolt": "#7c868b", "frame": "#161c20", "glass": "#7fa6b8", "streak": "#d6e6ee",
    "back0": "#414b51", "back_seam": "#353d42", "floor_in0": "#283035",
    "back1": "#2f5a6b", "pool1": "#3f7488", "pool2": "#5a98ad", "floor_in1": "#24485a",
    "rubber": "#0b0e10", "knife": "#7f8b90", "haz_y": "#c29a2a", "haz_k": "#16181a",
    "stencil": "#aeaca7", "lamp_off_r": "#3a2321", "lamp_off_a": "#3b3220", "lamp_off_g": "#1e3226",
    "lamp_r": "#ef4630", "lamp_a": "#f2a81c", "lamp_g": "#3fcf68", "cable": "#0f1315",
    "conn": "#3a444a", "led_g": "#59f08a", "led_r": "#ff5a48", "keeper": "#a0a59a",
    "keypad": "#121619", "key": "#6f7a80", "shadow": "#000000",
}

P = []  # primitives


def add(kind, layer, color, cond="always", group="static", alpha=1.0, part=None, **kw):
    d = {"k": kind, "layer": layer, "c": C.get(color, color), "a": alpha, "cond": cond, "g": group}
    if part:
        d["part"] = part
    d.update(kw)
    P.append(d)


def rect(layer, x0, y0, x1, y1, color, **kw):
    add("rect", layer, color, r=[x0, y0, x1 - x0, y1 - y0], **kw)


def poly(layer, pts, color, **kw):
    add("poly", layer, color, pts=[[round(x, 3), round(y, 3)] for x, y in pts], **kw)


def line(layer, a, b, color, w=1.0, **kw):
    add("line", layer, color, p=[list(a), list(b)], w=w, **kw)


def circle(layer, cx, cy, r, color, **kw):
    add("circle", layer, color, ctr=[cx, cy], rad=r, **kw)


def gpoly(layer, pts, cols, **kw):
    """Polygon with one colour per vertex (drawn as a fan of triangles from vertex 0)."""
    add("gpoly", layer, cols[0], pts=[[round(x, 3), round(y, 3)] for x, y in pts], cols=[C.get(c, c) for c in cols], **kw)


def vgrad(layer, x0, y0, x1, y1, top, bottom, **kw):
    gpoly(layer, [(x0, y0), (x1, y0), (x1, y1), (x0, y1)], [top, top, bottom, bottom], **kw)


def radial(layer, cx, cy, rx, ry, inner, outer, n=20, **kw):
    import math
    pts = [(cx, cy)] + [(cx + rx * math.cos(2 * math.pi * i / n), cy + ry * math.sin(2 * math.pi * i / n)) for i in range(n + 1)]
    gpoly(layer, pts, [inner] + [outer] * (n + 1), fan=True, **kw)


def _mix(a, b, t):
    a = C.get(a, a).lstrip("#"); b = C.get(b, b).lstrip("#")
    ca = [int(a[i:i + 2], 16) for i in (0, 2, 4)]; cb = [int(b[i:i + 2], 16) for i in (0, 2, 4)]
    return "#" + "".join("%02x" % round(x + (y - x) * t) for x, y in zip(ca, cb))


def panel(layer, x0, y0, x1, y1, hole, color, bottom=None, **kw):
    """A plate with a rectangular hole (window): four pieces around the hole. With `bottom`, the plate
    is lit from the fixtures above: a vertical gradient from `color` (top) to `bottom`."""
    hx0, hy0, hx1, hy1 = hole
    bottom = bottom or color
    def at(y):
        return _mix(color, bottom, (y - y0) / (y1 - y0))
    vgrad(layer, x0, y0, x1, hy0, at(y0), at(hy0), **kw)
    kw.pop("part", None)
    vgrad(layer, x0, hy1, x1, y1, at(hy1), at(y1), **kw)
    vgrad(layer, x0, hy0, hx0, hy1, at(hy0), at(hy1), **kw)
    vgrad(layer, hx1, hy0, x1, hy1, at(hy0), at(hy1), **kw)


def text(layer, x, y, s, color, cap=8.0, **kw):
    # x, y = left, baseline; cap = capital height in world px.
    add("text", layer, color, pos=[x, y], s=s, cap=cap, **kw)


def clip(poly_pts, x0, y0, x1, y1):
    """Sutherland-Hodgman clip of a polygon to an axis-aligned rect."""
    def _clip(pts, inside, inter):
        out = []
        for i in range(len(pts)):
            cur, prev = pts[i], pts[i - 1]
            if inside(cur):
                if not inside(prev):
                    out.append(inter(prev, cur))
                out.append(cur)
            elif inside(prev):
                out.append(inter(prev, cur))
        return out

    def ix(xv):
        return lambda p, q: (xv, p[1] + (q[1] - p[1]) * (xv - p[0]) / (q[0] - p[0]))

    def iy(yv):
        return lambda p, q: (p[0] + (q[0] - p[0]) * (yv - p[1]) / (q[1] - p[1]), yv)

    pts = poly_pts
    for inside, inter in [
        (lambda p: p[0] >= x0, ix(x0)), (lambda p: p[0] <= x1, ix(x1)),
        (lambda p: p[1] >= y0, iy(y0)), (lambda p: p[1] <= y1, iy(y1)),
    ]:
        if not pts:
            break
        pts = _clip(pts, inside, inter)
    return pts


def stripes(layer, x0, y0, x1, y1, period, **kw):
    rect(layer, x0, y0, x1, y1, "haz_k", **kw)
    h = y1 - y0
    k = x0 - h - period
    while k < x1 + period:
        band = [(k, y1), (k + period / 2, y1), (k + period / 2 + h, y0), (k + h, y0)]
        c = clip(band, x0, y0, x1, y1)
        if len(c) >= 3:
            poly(layer, c, "haz_y", **kw)
        k += period


def glass(layer, x0, y0, x1, y1, group="static"):
    rect(layer, x0, y0, x1, y1, "glass", alpha=0.17, group=group, part="ballistic glazing")
    # Revision 2: no glare streaks (they were highlights with no light source behind them).
    # glazing stop (frame) and bolts
    for r_ in [(x0 - 2, y0 - 2, x1 + 2, y0), (x0 - 2, y1, x1 + 2, y1 + 2), (x0 - 2, y0, x0, y1), (x1, y0, x1 + 2, y1)]:
        rect(layer, *r_, "frame", group=group)
    line(layer, (x0 - 2, y1 + 2.5), (x1 + 2, y1 + 2.5), "skin_hi", 0.6, alpha=0.6, group=group)
    for bx in (x0 - 1, x1 + 1):
        for by in (y0 - 1, y1 + 1):
            circle(layer, bx, by, 0.7, "bolt", group=group)


def build():
    # ---------------- BACK (z 1, behind WOLF): the inside of a closed box ----------------
    vgrad("back", 36, 343, 194, 431, "#2c3438", "back0", part="interior back wall (light grey for the camera)")
    for sx in (76, 116, 156):
        line("back", (sx, 343), (sx, 431), "back_seam", 1.0)
    # WOLF's own body lights pooling on the wall right round him (revision 2: a pool, not a flood).
    radial("back", 150, 398, 30, 22, "#4f8fa6a0", "#4f8fa600", cond="p_ge1", part="blue light from WOLF's body lights on the wall")
    rect("back", 36, 343, 194, 347, "skin_lo", alpha=0.55, part="ceiling shadow")
    rect("back", 36, 431, 194, 440, "floor_in0", part="cell floor plate (seen as a strip)")
    radial("back", 150, 436, 26, 3.5, "#3d728690", "#3d728600", cond="p_ge1")
    line("back", (36, 431), (194, 431), "skin_lo", 1.0)
    rect("back", 132, 343, 148, 350, "track", part="umbilical reel (ceiling)")
    # Umbilical: plugged into his shoulders in standby; he ejects it when he wakes and the reel takes it up.
    line("back", (140, 350), (140, 386), "cable", 2.4, cond="p0", part="power/data umbilical")
    line("back", (139.4, 350), (139.4, 386), "#3c474d", 0.6, cond="p0")
    rect("back", 136.5, 385, 143.5, 392, "conn", cond="p0", part="umbilical plug on WOLF's shoulders")
    rect("back", 136.5, 385, 143.5, 386, "#5c686e", cond="p0")
    circle("back", 140, 388.5, 0.8, "led_g", cond="p0")
    line("back", (140, 350), (142, 365), "cable", 2.4, cond="p_ge1")
    poly("back", [(138.5, 364.5), (145.5, 365.8), (144.6, 372.6), (137.6, 371.3)], "conn", cond="p_ge1")

    # ---------------- FRONT (z 3, IntroCage): fixed shell, lock side hardware ----------------
    # contact shadow (darkest at the contact line)
    for i, a in enumerate([0.55, 0.38, 0.24, 0.13, 0.06]):
        rect("front", 25 - i, 440 + i * 1.6, 211 + i, 441.6 + i * 1.6, "shadow", alpha=a, part="contact shadow" if i == 0 else None)
    # roof edge and top-hung track beam
    rect("front", 30, 330, 206, 335, "skin", part="roof plate edge")
    line("front", (30, 330.5), (206, 330.5), "skin_hi", 1.0)
    rect("front", 28, 335, 206, 343, "track", part="top-hung door track (box track)")
    line("front", (28, 335.5), (206, 335.5), "#3b474e", 1.0)
    line("front", (28, 342.5), (206, 342.5), "skin_lo", 1.0)
    rect("front", 27, 334, 30, 344, "steel", part="end stop")
    for bx in range(40, 206, 22):
        circle("front", bx, 339, 0.8, "bolt")
    # left corner post and fixed panel
    rect("front", 30, 343, 36, 440, "post", part="corner post")
    line("front", (30.5, 343), (30.5, 440), "skin_hi", 1.0, alpha=0.7)
    panel("front", 36, 343, 115, 436, (41, 355, 110, 418), "#36424a", bottom="#20282d", part="fixed armour panel")
    rect("front", 36, 420, 115, 436, "#252d32", part="kick plate")
    line("front", (36, 420.5), (115, 420.5), "skin_lo", 1.0)
    line("front", (36, 343.5), (115, 343.5), "skin_lo", 1.0)
    glass("front", 43, 357, 108, 416)
    if PLAIN:
        rect("front", 43, 346.5, 75, 355.5, "#3f4b52", part="blank equipment plate")
        for rx in (44.2, 73.0):
            for ry in (347.6, 353.6):
                circle("front", rx, ry, 0.6, "bolt")
    else:
        text("front", 44, 354.5, "CU-01", "stencil", cap=8.0, alpha=0.62, part="stencil (proposed)")
    # gasketed door opening: seal strips on the frame (hidden behind the leaf until it moves)
    rect("front", 112, 343, 116, 438, "rubber", part="inflatable door seal")
    line("front", (115.5, 344), (115.5, 438), "knife", 0.8)
    rect("front", 112, 343, 196, 346.5, "rubber")
    line("front", (113, 346), (195, 346), "knife", 0.8)
    rect("front", 192, 343, 196, 438, "rubber")
    line("front", (192.5, 344), (192.5, 438), "knife", 0.8)
    # torn seal section hanging at the lock side once breached
    poly("front", [(192, 396), (195, 396), (197.5, 410), (196.2, 418), (194.5, 417), (195.2, 409)], "rubber",
         cond="open", part="seal torn at the lock edge")
    # base rail, threshold, anchors
    rect("front", 30, 436, 115, 440, "post", part="base channel")
    line("front", (30, 436.5), (115, 436.5), "skin_hi", 1.0, alpha=0.6)
    rect("front", 115, 438.4, 194, 440, "steel", alpha=0.8, part="threshold plate (flush)")
    rect("front", 194, 436, 206, 440, "post")
    for x0, x1 in [(25, 30), (206, 211)]:
        rect("front", x0, 437, x1, 440, "post", part="anchor flange")
        circle("front", (x0 + x1) / 2, 436.6, 1.1, "bolt", part="anchor bolt into slab")
    for bx in (52, 84):
        circle("front", bx, 435.6, 1.0, "bolt")
    # lock pilaster (keeper side)
    rect("front", 194, 330, 206, 436, "post", part="lock pilaster")
    line("front", (205.5, 330), (205.5, 436), "skin_lo", 1.0)
    line("front", (194.5, 331), (194.5, 436), "skin_hi", 1.0, alpha=0.5)
    # PIN keypad + card reader, keeper side, centre 1.2 m (y 392), shown 1.5 x real size
    rect("front", 197.5, 384, 205, 398, "skin_lo", part="tamper-proof backplate")
    if PLAIN:
        rect("front", 198.8, 386, 203.8, 395.5, "#3a454b", part="blanking cover over the keypad cut-out")
        for bx_, by_ in ((199.4, 386.6), (203.2, 386.6), (199.4, 394.9), (203.2, 394.9)):
            circle("front", bx_, by_, 0.4, "bolt")
    else:
        rect("front", 198.8, 386, 203.8, 395.5, "keypad", part="PIN keypad / card reader (1.5x, OPTIONAL)")
        for r_ in range(4):
            for c_ in range(3):
                rect("front", 199.6 + c_ * 1.45, 388.6 + r_ * 1.6, 200.5 + c_ * 1.45, 389.4 + r_ * 1.6, "key")
        circle("front", 201.3, 387.2, 0.55, "#2a2e30", part="reader LED (unlit: nobody presenting)")
    # fail-secure bolt lock box (spring-locked, power-to-unlock)
    rect("front", 197, 400, 205.5, 414, "steel", part="fail-secure bolt lock")
    rect("front", 197.6, 400.6, 205, 413.4, "#5d676c")
    circle("front", 201.3, 410.6, 0.9, "frame", part="manual back-up key")
    rect("front", 199.5, 402.5, 203, 404, "lamp_g", cond="closed", part="bolt-bonded lamp")
    rect("front", 199.5, 402.5, 203, 404, "lamp_a", cond="open")
    # conduit from the lock to the floor (wiring on the secure, outside side)
    rect("front", 200.2, 414, 202.6, 440, "#3f4a50", part="rigid conduit to floor box")
    rect("front", 199.2, 424, 203.6, 425.5, "bolt")
    # left: power/data feed for the umbilical, from a floor vault up into the cell
    rect("front", 31.6, 420, 34.2, 440, "#3f4a50", part="power/data conduit from floor")
    rect("front", 28.5, 408, 37.5, 420, "steel", part="junction box")
    rect("front", 29.1, 408.6, 36.9, 419.4, "#4c565c")
    # stack light on the pilaster: red / amber / green (IEC 60073 meanings)
    rect("front", 199.4, 326, 200.6, 330, "steel", part="stack light")
    rect("front", 197.5, 325, 202.5, 326.2, "track")
    # Revision 2: green stays lit until the breach (no amber warning at beat 2), red only at the breach.
    for y0, off, on, cond in [(313.5, "lamp_off_r", "lamp_r", "p2"), (317.5, "lamp_off_a", None, None), (321.5, "lamp_off_g", "lamp_g", "closed")]:
        rect("front", 197.5, y0, 202.5, y0 + 3.6, off)
        if on is None:
            continue
        rect("front", 197.5, y0, 202.5, y0 + 3.6, on, cond=cond)
        radial("front", 200, y0 + 1.8, 8.0, 8.0, C[on] + "70", C[on] + "00", n=16, cond=cond, glow=True)
    rect("front", 197.2, 312.6, 202.8, 313.6, "track")
    # fixed camera on a wall arm, left roof corner, looking along the front at the door
    line("front", (33, 330), (35, 324.5), "steel", 1.4, part="camera arm")
    poly("front", [(32, 320), (44, 321.4), (44, 325.6), (32, 325)], "#4b565c", part="fixed camera housing")
    poly("front", [(31, 319.3), (45, 320.6), (45, 321.6), (31, 320.3)], "#6c787e")
    circle("front", 44.4, 323.5, 1.2, "frame")

    # ---------------- LEAF (z 4, IntroGate): top-hung sliding door, slides left over the shell ----------------
    L = dict(group="leaf")
    panel("leaf", 113, 343, 196, 439, (118, 355, 189, 418), "#3d4a52", bottom="#252e33", part="sliding armour leaf", **L)
    rect("leaf", 113, 420, 191, 438, "#2b343a", **L)
    line("leaf", (113, 420.5), (191, 420.5), "skin_lo", 1.0, **L)
    line("leaf", (113, 343.5), (196, 343.5), "leaf_hi", 1.0, **L)
    line("leaf", (113.5, 344), (113.5, 439), "skin_lo", 1.0, **L)
    line("leaf", (113, 438.6), (191, 438.6), "skin_lo", 1.0, **L)
    glass("leaf", 120, 357, 187, 416, group="leaf")
    # Revision 2: the 6.4 px KEEP CLEAR is dropped (under REAL-LOOK's 8 px minimum; 8 px does not fit).
    stripes("leaf", 190.5, 343, 196, 439, 6.0, part="caught-between stripes", **L)
    for tx in (125, 182):
        rect("leaf", tx - 3, 338.5, tx + 3, 344, "steel", part="trolley hanger" if tx == 125 else None, **L)
        circle("leaf", tx, 338.2, 2.1, "frame", **L)
        circle("leaf", tx, 338.2, 0.8, "bolt", **L)
    # keeper bracket on the leaf's leading edge, with the bolt thrown into it
    rect("leaf", 186.5, 400.5, 195.5, 410.5, "keeper", cond="closed", part="bolt keeper (the latch)")
    rect("leaf", 187.3, 401.3, 194.7, 409.7, "#7d8379", cond="closed")
    for by in (402.6, 408.4):
        circle("leaf", 188.5, by, 0.7, "frame", cond="closed")
    # sheared bolt stubs left on the leaf after the keeper tears off
    for by in (402.6, 408.4):
        circle("leaf", 188.5, by, 0.8, "#d8dccf", cond="open", **L)
    rect("leaf", 186.5, 400.5, 195.5, 410.5, "skin_lo", alpha=0.6, cond="open", **L)
    # the keeper falling (rotates about its centre and drops to the floor in front of the pilaster)
    poly("leaf", [(186.5, 400.5), (195.5, 400.5), (195.5, 410.5), (186.5, 410.5)], "keeper", cond="open", group="keeper_fall",
         part="torn keeper (falls)")
    poly("leaf", [(187.3, 401.3), (194.7, 401.3), (194.7, 409.7), (187.3, 409.7)], "#7d8379", cond="open", group="keeper_fall")
    # the bolt: stays thrown out of the lock box whatever happens (drawn over the leaf)
    rect("leaf", 189.0, 404.2, 197.2, 406.8, "steel", part="lock bolt (stays thrown)")
    line("leaf", (189.0, 404.6), (197.2, 404.6), "#c4cbcd", 0.7)


def main(out):
    build()
    spec = {
        "units": "world px; 1 m = 39.8 px; floor y 440; node origin (115, 365)",
        "travel": TRAVEL,
        "keeper_fall": {"pivot": [191.0, 405.5], "end": [14.0, 31.0], "rot_deg": 78.0, "span": 0.45},
        "stage": {"a_end": 0.2, "a_frac": 0.04},
        "prims": P,
    }
    with open(out, "w") as f:
        json.dump(spec, f, indent=0)
    print("prims", len(P), {l: sum(1 for p in P if p["layer"] == l) for l in ("back", "front", "leaf")})


if __name__ == "__main__":
    main(sys.argv[1])
