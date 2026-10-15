"""Fix round 4 (review r4, M1): fits each swing leaf's light with the face the real camera sees.

Knobs, per leaf (the light positions are the design's; rdesign.py / jedesign.py):
  g  the door light over the head, as the design draws it (reach 1.4 m, down 2.0) but a true Lambert source;
  e  the room's ceiling lamp (key);
  f  the fill: the ambient and the broad floor bounce (rdesign's "the lit wet floor in front");
  p  the door light's own pool on the wet deck just in front of the door (new, a fill light at the deck).
Targets on the predicted screen (leafsim x the render scale c from inputs.py):
  open (90 deg): the leaf within 9 px of its hinge edge at 0.6-1.0x the reveal in rows 350-380, 400-440,
    460-490 (aim 0.8);
  shut: the face at 0.5-0.95x the wall beside it;
  swing (every 2 degrees): the face the camera sees at >= 0.5x the wall and >= its shut value.
usage: fit.py INPUTS_JSON OUT_JSON"""
import json, os, sys
import numpy as np
from scipy import optimize
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import leafsim as S
import inputs as I

DESIGN_REACH, DESIGN_DOWN = 1.4, 2.0
POOL_OUT, POOL_REACH, POOL_WRAP = 0.45, 0.8, 0.25
ANGLES = np.arange(0, 91, 2) / 90.0


# Lit surfaces the leaf sees, in the leaf's own frame (u along the wall toward the back wall from the hinge,
# n into the wall, h up; metres): [u, n, h, reach, wrap]. Each is a visible source in the painted room.
#  pool:   the door light's pool on the wet deck just in front of the doorway;
#  thresh: the lit threshold and passage deck seen through the doorway (the door light and the passage light
#          on it), behind the wall's room face: it reaches the open leaf's outside face, which looks into
#          the doorway, and the reveal beside it, never the room face;
#  wallb:  the cross-wall's own lit face just beyond the hinge jamb (the door light's spill on it), which the
#          room face turns toward as the leaf opens.
SURFACES = {"pool": (-0.457, -0.45, 0.02, 0.8, 0.25), "thresh": (-0.457, 0.30, 0.03, 0.9, 0.05), "wallb": (0.45, -0.02, 1.4, 1.0, 0.05)}
KNOBS = ["door", "ceil", "fill", "pool", "thresh", "wallb"]


def surface_pos(cfg, key):
    u, n, h = SURFACES[key][:3]
    return np.array(cfg["hinge"]) + np.array(cfg["u"]) * u + np.array(cfg["n"]) * n + np.array([0.0, h, 0.0])


def config(name, x, reach=DESIGN_REACH):
    gains = dict(zip(KNOBS, np.exp(np.asarray(x, float))))
    cfg = S.leaf(name)
    door, ceil, bounce = cfg["lights"][:3]
    lamp = np.array(door[0])
    unit = np.array(door[1]) / np.array(door[1]).max()
    lights = [[tuple(lamp), tuple(unit * gains["door"]), reach, DESIGN_DOWN, 0.0, False],
              [ceil[0], tuple(np.array(ceil[1]) * gains["ceil"]), ceil[2], ceil[3], S.WRAP, False],
              [bounce[0], bounce[1], bounce[2], bounce[3], S.WRAP, True]]
    for key in ("pool", "thresh", "wallb"):
        _, _, _, rch, wrp = SURFACES[key]
        lights.append([tuple(surface_pos(cfg, key)), tuple(unit * gains[key]), rch, 0.0, wrp, False])
    cfg["lights"] = lights
    cfg["exposure"] = 1.0
    cfg["fill"] = gains["fill"]
    return cfg


def evaluate(name, cfg, inp):
    c = inp["c"]
    lum, tag = S.render(cfg, 1.0, inp["open_canvas"])
    face = (tag == "room") | (tag == "out")
    bands = []
    (lx0, lx1), _ = I.COLS[name]
    for b in inp["bands"]:
        y0, y1 = b["rows"]
        near = np.zeros_like(face); near[y0:y1, lx0:lx1] = True
        bands.append(c * float(np.nanmedian(lum[near & face])) / b["reveal"])
    swing = []
    for a in ANGLES:
        l, t = S.render(cfg, a, inp["open_canvas"])
        m = (t == "room") | (t == "out")
        swing.append(c * float(np.nanmedian(l[m])) / inp["wall"] if m.sum() > 20 else np.nan)
    shut = swing[0]
    return {"bands": bands, "shut": shut, "swing": swing, "swing_min": float(np.nanmin(swing)), "swing_min_deg": float(ANGLES[int(np.nanargmin(swing))] * 90)}


def loss(x, name, inp):
    r = evaluate(name, config(name, x), inp)
    L = sum(np.log(b / 0.8) ** 2 for b in r["bands"])
    L += 4 * sum(max(0, np.log(0.62 / b)) ** 2 + max(0, np.log(b / 0.98)) ** 2 for b in r["bands"])
    L += 4 * (max(0, np.log(0.5 / r["shut"])) ** 2 + max(0, np.log(r["shut"] / 0.95)) ** 2)
    floor = max(0.5, 1.0 * r["shut"])
    L += 8 * max(0, np.log(floor / r["swing_min"])) ** 2
    L += 0.3 * np.log(r["shut"] / 0.7) ** 2
    return L


if __name__ == "__main__":
    inp = json.load(open(sys.argv[1]))
    names = sys.argv[3:] or list(inp)
    out = json.load(open(sys.argv[2])) if os.path.exists(sys.argv[2]) else {}
    for name in names:
        x0 = np.log([2.0, 0.08, 0.15, 0.3])
        res = optimize.minimize(loss, x0, args=(name, inp[name]), method="Nelder-Mead", options={"maxiter": 500, "xatol": 1e-3, "fatol": 1e-5})
        cfg = config(name, res.x)
        r = evaluate(name, cfg, inp[name])
        g, e, f, p = np.exp(res.x)
        out[name] = {"g": g, "e": e, "f": f, "p": p, "loss": res.fun, "lights": cfg["lights"], "fill": f, **r}
        print(name, "g %.3f e %.4f f %.4f p %.4f loss %.4f" % (g, e, f, p, res.fun))
        print("   bands", ["%.2f" % b for b in r["bands"]], "shut %.2f swing min %.2f at %d deg" % (r["shut"], r["swing_min"], r["swing_min_deg"]))
        print("   swing", " ".join("%.2f" % s for s in r["swing"][::3]))
        json.dump(out, open(sys.argv[2], "w"), indent=1, default=float)
