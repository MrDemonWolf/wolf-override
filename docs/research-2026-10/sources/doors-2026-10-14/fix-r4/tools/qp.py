"""Fix round 4 (M1): the gains on the linear model (decomp3.json from lp3.py): bands near 0.8x the reveal
(0.68-0.92), the shut leaf near 0.7x its wall (0.55-0.85), the swing never below the shut value or 0.5x the
wall, the room's ambient fill at least a quarter of the shut value and the ceiling lamp at least round 3's.
usage: qp.py OUT_JSON"""
import json, sys, os
import numpy as np
from scipy.optimize import minimize
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fit as F
dec = json.load(open("../decomp3.json"))
R3E = {"records-exit": 0.082, "records-entry": 0.225, "junction-entry": 0.147}
out = {}
for name, d in dec.items():
    B = np.array(d["B"]); SW = np.array(d["SW"])
    seen = ~np.isnan(SW).any(1)
    SW = SW[seen]; sh = SW[0]
    K = len(F.KNOBS); ki = {k: i for i, k in enumerate(F.KNOBS)}
    def obj(g):
        b = B @ g; s = sh @ g
        return ((b - 0.8) ** 2).sum() + (s - 0.7) ** 2 + 0.002 * (g[ki["pool"]] ** 2 + g[ki["thresh"]] ** 2 + g[ki["wallb"]] ** 2)
    cons = [{"type": "ineq", "fun": lambda g, i=i: B[i] @ g - 0.68} for i in range(3)]
    cons += [{"type": "ineq", "fun": lambda g, i=i: 0.92 - B[i] @ g} for i in range(3)]
    cons += [{"type": "ineq", "fun": lambda g: sh @ g - 0.55}, {"type": "ineq", "fun": lambda g: 0.85 - sh @ g}]
    cons += [{"type": "ineq", "fun": lambda g, j=j: SW[j] @ g - sh @ g} for j in range(1, len(SW))]
    cons += [{"type": "ineq", "fun": lambda g, j=j: SW[j] @ g - 0.5} for j in range(1, len(SW))]
    cons += [{"type": "ineq", "fun": lambda g: g[ki["fill"]] * sh[ki["fill"]] - 0.25 * (sh @ g)}]
    bounds = [(0, None)] * K
    bounds[ki["ceil"]] = (R3E[name], 2.0 * R3E[name])
    # scaled variables (each knob in units that move the shut value or a band by about 1)
    scale = 1.0 / np.maximum(np.maximum(np.abs(B).max(0), np.abs(SW).max(0)), 1e-6)
    g0 = np.array([1.2, R3E[name], R3E[name] * 1.2, 0.0, 0.3, 0.7]) / scale
    sc_cons = [{"type": c["type"], "fun": (lambda x, f=c["fun"]: f(x * scale))} for c in cons]
    sc_bounds = [(lo / s if lo is not None else None, hi / s if hi is not None else None) for (lo, hi), s in zip(bounds, scale)]
    r = minimize(lambda x: obj(x * scale), g0, method="SLSQP", bounds=sc_bounds, constraints=sc_cons, options={"maxiter": 1000, "ftol": 1e-12})
    g = r.x * scale; sw = SW @ g
    out[name] = dict(zip(F.KNOBS, map(float, g)))
    print(name, r.success, r.message)
    print("   gains", " ".join("%s %.3f" % (k, v) for k, v in out[name].items()))
    print("   bands", np.round(B @ g, 2), "shut %.2f" % (sh @ g), "swing min %.2f" % sw[1:].min(), "fill share %.2f" % (g[ki['fill']] * sh[ki['fill']] / (sh @ g)))
json.dump(out, open(sys.argv[1], "w"), indent=1)
