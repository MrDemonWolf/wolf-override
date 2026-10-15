"""Construction design for the corridor's two lockdown beacons (add7 item d; round 8 copy in add7/fix1/beacons:
the left lamp's conduit straps are wider one-hole straps with lit tops so the feed reads as fixed to the wall).

Deterministic. Every part is an exact shape in far-plate pixels (80 px per metre), modelled on a
hazardous-location LED luminaire with a red glass globe and a cast guard on a wall bracket
(Eaton Crouse-Hinds EV LED, wall mount, guard, red globe: 7.25 in wide, 16.81 in tall, 12.56 in
deep, 3/4 in conduit entry). Outputs, under design/:
  spec.json                       every part, its size in metres and what it does
  masks/b{0,1}--<part>.png        1x coverage masks on each beacon's canvas (plate px)
  codex-target.png, codex-areas.png   the 16x edit target and its paint map for Codex
  codex-layout.json               where each beacon's window sits in the 16x target
  construction-b{0,1}-8x.png      the flat construction drawn on the real plate, for review
"""
import json
import os
import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RS = "scratchpad/real-slice"
FAR = os.path.join(RS, "game-slice/apps/game/assets/rooms/corridor-far.png")
OUT = os.path.join(ROOT, "design")
SS = 16                     # supersampling for masks and for the Codex target
PX_PER_M = 80.0

# Fixture centre column c (the centre line is c + 0.5) and the bracket top row T, in plate px.
# Anchors in the game: warning_lamps (0.341, 0.27) and (0.659, 0.27) of the 1920x1080 far plate.
BEACONS = [
    {"name": "b0", "anchor": [0.341 * 1920, 0.27 * 1080], "c": 656, "T": 275,
     "canvas": [636, 176, 676, 326], "conduit_top": 183, "straps": [204, 228, 252]},
    {"name": "b1", "anchor": [0.659 * 1920, 0.27 * 1080], "c": 1266, "T": 275,
     "canvas": [1246, 266, 1286, 326], "nipple": [273, 275]},
]
# The Codex window around each fixture (relative to c, T): 30 x 56 plate px.
WIN = (-14, -6, 16, 50)


def rounded_rect(u, v, x0, y0, x1, y1, r):
    inside = (u >= x0) & (u <= x1) & (v >= y0) & (v <= y1)
    cx = np.clip(u, x0 + r, x1 - r)
    cy = np.clip(v, y0 + r, y1 - r)
    return inside & (((u - cx) ** 2 + (v - cy) ** 2) <= r * r)


def parts(u, v, b):
    """Boolean masks of every part, on a grid of local coordinates (u across from the centre
    line, v down from the bracket top), all in plate px."""
    m = {}
    m["bracket_plate"] = rounded_rect(u, v, -5.5, 0.0, 5.5, 14.0, 1.5)
    m["anchor_bolts"] = (((u - 3.5) ** 2 + (v - 2.2) ** 2) <= 0.85 ** 2) | (((u + 3.5) ** 2 + (v - 2.2) ** 2) <= 0.85 ** 2)
    m["arm_hub"] = rounded_rect(u, v, -2.6, 4.5, 2.6, 10.5, 1.0)
    half = 6.0 + np.clip(v - 10.0, 0, 9) / 9.0 * 1.5
    m["housing"] = (v >= 10.0) & (v <= 19.0) & (np.abs(u) <= half)
    fins = np.zeros_like(u, dtype=bool)
    for fv in (12.6, 14.6, 16.6):
        fins |= (np.abs(v - fv) <= 0.28)
    m["housing_fins"] = m["housing"] & fins & (np.abs(u) <= half - 0.6)
    m["collar"] = (np.abs(u) <= 6.6) & (v >= 19.0) & (v <= 21.0)
    upper = (v >= 21.0) & (v <= 28.0) & (np.abs(u) <= 5.3)
    lower = (v > 28.0) & (((u / 5.3) ** 2 + ((v - 28.0) / 4.2) ** 2) <= 1.0)
    m["globe"] = upper | lower
    k = np.where(v <= 28.0, 1.0, np.sqrt(np.clip(1.0 - ((v - 28.0) / 4.9) ** 2, 0.0, 1.0)))
    bars = np.zeros_like(u, dtype=bool)
    for x0 in (-5.85, -2.42, 2.42, 5.85):
        bars |= (np.abs(u - x0 * k) <= 0.43) & (v >= 21.0) & (v <= 32.9)
    m["guard_bars"] = bars
    m["guard_ring"] = (np.abs(v - 27.0) <= 0.45) & (np.abs(u) <= 6.27)
    m["guard_cap"] = rounded_rect(u, v, -2.4, 32.4, 2.4, 34.2, 0.8) | rounded_rect(u, v, -0.9, 34.0, 0.9, 35.2, 0.4)
    if "nipple" in b:
        n0, n1 = b["nipple"]
        m["conduit_nipple"] = (np.abs(u) <= 1.5) & (v >= n0 - b["T"]) & (v < n1 - b["T"])
    if "conduit_top" in b:
        top = b["conduit_top"] - b["T"]
        m["conduit"] = (np.abs(u) <= 1.5) & (v >= top + 3.0) & (v < 0.0)
        m["conduit_fitting"] = rounded_rect(u, v, -2.5, top, 2.5, top + 3.0, 0.6)
        m["conduit_hub"] = rounded_rect(u, v, -2.1, -1.6, 2.1, 0.4, 0.5)
        straps = np.zeros_like(u, dtype=bool)
        for sy in b["straps"]:
            straps |= rounded_rect(u, v, -3.4, sy - b["T"] - 1.2, 3.4, sy - b["T"] + 1.2, 0.4)
        m["conduit_straps"] = straps
    return m


# Draw order (back to front); the guard parts are the "cage front", drawn over the lens in game.
ORDER = ["conduit", "conduit_fitting", "conduit_straps", "conduit_hub", "conduit_nipple",
         "bracket_plate", "anchor_bolts", "arm_hub", "housing", "housing_fins", "collar", "globe",
         "guard_ring", "guard_bars", "guard_cap"]
CAGE = ["guard_ring", "guard_bars", "guard_cap"]
SHADOW_CASTERS = ["arm_hub", "housing", "collar", "globe", "guard_ring", "guard_bars", "guard_cap"]

SPEC = {
    "reference": "hazardous-location LED luminaire, red heat- and impact-resistant glass globe, cast guard, wall bracket "
                 "(Eaton Crouse-Hinds EV LED EVLEDBX2C201R: 7.25 in W x 16.81 in H x 12.56 in D, 3/4 in conduit entry)",
    "scale": "80 far-plate px per metre (far plate drawn at 0.5, so 40 world px per metre)",
    "parts": {
        "bracket_plate": ["11 x 14 px", "0.14 x 0.175 m", "cast wall bracket plate, flush on the wall, carries the arm"],
        "anchor_bolts": ["2 x 1.7 px", "M10 anchors", "fix the bracket to the concrete (lower pair hidden by the housing)"],
        "arm_hub": ["5.2 x 6 px", "0.065 x 0.075 m", "front end of the bracket arm (0.32 m out from the wall) where the luminaire hangs"],
        "housing": ["12-15 x 9 px", "0.15-0.19 x 0.11 m", "finned cast driver housing (LED driver, heat sink)"],
        "housing_fins": ["3 grooves", "", "cooling fins"],
        "collar": ["13.2 x 2 px", "0.165 x 0.025 m", "threaded guard collar that holds globe and guard"],
        "globe": ["10.6 x 11.2 px", "0.13 x 0.14 m", "red heat- and impact-resistant glass globe; the lamp"],
        "guard_bars": ["8 bars, 4 in front", "6 mm cast bars", "guard against knocks"],
        "guard_ring": ["12.5 px", "", "mid ring of the guard"],
        "guard_cap": ["4.8 x 2.8 px", "0.06 m", "guard foot ring and drain boss"],
        "conduit_nipple": ["3 x 2 px", "3/4 in rigid conduit", "b1: from the existing back box into the bracket's top hub"],
        "conduit": ["3 px wide", "3/4 in rigid conduit (OD 26.7 mm, drawn at the corridor's 25 mm conduit width)", "b0: feed from the ceiling cable tray"],
        "conduit_fitting": ["5 x 3 px", "", "b0: connector into the tray"],
        "conduit_straps": ["6.8 x 2.4 px", "", "b0: one-hole straps at 0.29, 0.59 and 0.89 m above the bracket (within 0.9 m of a box), lit tops"],
        "conduit_hub": ["4.2 x 2 px", "", "b0: threaded hub on the bracket top"],
    },
    "height_total_px": 35.2, "height_total_m": 0.44,
    "light": "b1: pendant fitting directly above (plate y 225): top faces lit, short shadow straight down the wall. "
             "b0: no fitting near it; dim ambient from both bay lamps, soft shadow straight down.",
}


def grid(x0, y0, x1, y1, ss, c, T):
    xs = (np.arange((x1 - x0) * ss) + 0.5) / ss + x0
    ys = (np.arange((y1 - y0) * ss) + 0.5) / ss + y0
    X, Y = np.meshgrid(xs, ys)
    return X - (c + 0.5), Y - T


def down(mask, ss):
    h, w = mask.shape
    return mask.reshape(h // ss, ss, w // ss, ss).mean(axis=(1, 3))


# Flat construction values (raw plate RGB): the room's plan, before the post grade.
def construction(m, b, u, v):
    lit = b["name"] == "b1"
    base = np.array([50, 56, 66]) if lit else np.array([22, 26, 32])
    top_light = np.array([84, 92, 102]) if lit else np.array([40, 46, 54])
    img = np.zeros(u.shape + (3,))
    a = np.zeros(u.shape)
    for name in ORDER:
        if name not in m:
            continue
        mk = m[name]
        col = np.broadcast_to(base, u.shape + (3,)).astype(float).copy()
        if name in ("housing", "bracket_plate", "arm_hub", "collar", "guard_cap", "conduit_fitting", "conduit_hub", "conduit_straps", "conduit_nipple"):
            # lit from above: brighter on the top 1.2 px of each part, falling darker downward
            ys = v[mk]
            top = ys.min() if ys.size else 0
            f = np.clip((v - top) / 1.2, 0, 1)
            col = top_light[None, None, :] * (1 - f[..., None]) + base[None, None, :] * f[..., None] * (1.0 - 0.15 * np.clip((v - top) / 10.0, 0, 1))[..., None]
        if name == "housing_fins":
            col[:] = base * 0.55
        if name == "anchor_bolts":
            col[:] = top_light * 0.9
        if name == "conduit":
            # the corridor's own 3 px conduit profile (lit side left), scaled to this wall's light
            prof = np.array([[58, 75, 79], [56, 72, 75], [47, 61, 63]]) * (0.42 if not lit else 1.0)
            idx = np.clip(np.floor(u + 1.5).astype(int), 0, 2)
            col = prof[idx]
        if name == "globe":
            r = np.sqrt((u / 5.3) ** 2 + ((v - 26.0) / 6.5) ** 2)
            core = np.clip(1.0 - r, 0, 1)
            col = np.stack([120 + 135 * core, 18 + 90 * core ** 2, 16 + 80 * core ** 2], -1)
        if name in ("guard_bars", "guard_ring"):
            col[:] = base * 0.75
        img[mk] = col[mk]
        a[mk] = 1.0
    return img, a


def main():
    os.makedirs(os.path.join(OUT, "masks"), exist_ok=True)
    far = np.asarray(Image.open(FAR).convert("RGB")).astype(float)
    layout = {"ss": SS, "window": WIN, "beacons": []}
    target = np.zeros((1024, 1024, 3)) + np.array([36, 38, 42])
    areas = np.zeros((1024, 1024))
    spec = dict(SPEC)
    spec["beacons"] = []
    for i, b in enumerate(BEACONS):
        x0, y0, x1, y1 = b["canvas"]
        U, V = grid(x0, y0, x1, y1, SS, b["c"], b["T"])
        m = parts(U, V, b)
        for name, mk in m.items():
            Image.fromarray((down(mk.astype(float), SS) * 255 + 0.5).astype(np.uint8)).save(os.path.join(OUT, "masks", f"{b['name']}--{name}.png"))
        # Codex window at 16x, on the real plate (bicubic) so the light reads in context.
        wx0, wy0, wx1, wy1 = b["c"] + WIN[0], b["T"] + WIN[1], b["c"] + WIN[2], b["T"] + WIN[3]
        Uw, Vw = grid(wx0, wy0, wx1, wy1, SS, b["c"], b["T"])
        mw = parts(Uw, Vw, b)
        img, a = construction(mw, b, Uw, Vw)
        wall = np.asarray(Image.fromarray(far[wy0:wy1, wx0:wx1].astype(np.uint8)).resize(((wx1 - wx0) * SS, (wy1 - wy0) * SS), Image.BICUBIC)).astype(float)
        # lift the window's wall for Codex so it can see the fixture's surroundings (value ratios kept)
        comp = wall * (1 - a[..., None]) + img * a[..., None]
        ox, oy = 16 + i * (30 * SS + 32), 64
        target[oy:oy + comp.shape[0], ox:ox + comp.shape[1]] = comp
        paint = np.zeros(a.shape, dtype=bool)
        for name, mk in mw.items():
            if not name.startswith("conduit"):
                paint |= mk
        areas[oy:oy + comp.shape[0], ox:ox + comp.shape[1]] = paint
        layout["beacons"].append({"name": b["name"], "offset": [ox, oy], "plate_window": [wx0, wy0, wx1, wy1]})
        # review render: construction on the real plate, 8x
        Uc, Vc = grid(x0, y0, x1, y1, SS, b["c"], b["T"])
        imc, ac = construction(m, b, Uc, Vc)
        col = down(imc[..., 0] * ac, SS), down(imc[..., 1] * ac, SS), down(imc[..., 2] * ac, SS)
        al = down(ac, SS)
        base = far[y0:y1, x0:x1]
        rgb = np.stack(col, -1) + base * (1 - al[..., None])
        Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8)).resize(((x1 - x0) * 8, (y1 - y0) * 8), Image.NEAREST).save(os.path.join(OUT, f"construction-{b['name']}-8x.png"))
        spec["beacons"].append({k: b[k] for k in b})
    Image.fromarray(np.clip(target, 0, 255).astype(np.uint8)).save(os.path.join(OUT, "codex-target.png"))
    Image.fromarray((areas * 255).astype(np.uint8)).save(os.path.join(OUT, "codex-areas.png"))
    json.dump(layout, open(os.path.join(OUT, "codex-layout.json"), "w"), indent=1)
    spec["order"] = ORDER
    spec["cage"] = CAGE
    spec["shadow_casters"] = SHADOW_CASTERS
    json.dump(spec, open(os.path.join(OUT, "spec.json"), "w"), indent=1)
    print("ok")


if __name__ == "__main__":
    main()
