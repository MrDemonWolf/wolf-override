"""Fix round 4 (M1): refines l1.py's gains on the full software render (fit.evaluate): bands 0.8x the reveal
(hard 0.71-0.94), shut 0.75x the wall (hard 0.55-0.90), the swing at or above 0.97x the shut value and 0.5x the
wall; the room's ambient fill kept at least l1's,
the ceiling lamp at 1-5x round 3's. usage: refine.py INPUTS GAINS_IN GAINS_OUT"""
import json, sys, os
import numpy as np
from scipy.optimize import minimize
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fit as F
inp = json.load(open(sys.argv[1])); gains = json.load(open(sys.argv[2]))
out = {}
R3E = {"records-exit": 0.082, "records-entry": 0.225, "junction-entry": 0.147}
for name, g in gains.items():
    on = [k for k in F.KNOBS if g[k] > 1e-4]
    base = {k: max(g[k], 1e-12) for k in F.KNOBS}
    def cfg_of(x):
        gg = dict(base); gg.update({k: float(np.exp(v)) for k, v in zip(on, x)})
        return gg, F.config(name, np.log([gg[k] for k in F.KNOBS]))
    def loss(x):
        gg, cfg = cfg_of(x)
        r = F.evaluate(name, cfg, inp[name])
        sw = np.array(r["swing"][1:]); sw = sw[~np.isnan(sw)]
        L = sum(np.log(b / 0.8) ** 2 for b in r["bands"]) + 0.5 * np.log(r["shut"] / 0.75) ** 2
        L += 20 * sum(max(0, np.log(0.71 / b)) ** 2 + max(0, np.log(b / 0.94)) ** 2 for b in r["bands"])
        L += 20 * (max(0, np.log(R3E[name] / gg["ceil"])) ** 2 + max(0, np.log(gg["ceil"] / (5.0 * R3E[name]))) ** 2)
        L += 20 * (max(0, np.log(0.55 / r["shut"])) ** 2 + max(0, np.log(r["shut"] / 0.90)) ** 2)
        L += 40 * max(0, np.log(max(0.5, 0.97 * r["shut"]) / sw.min())) ** 2
        L += 20 * max(0, np.log(g["fill"] / gg["fill"])) ** 2
        return L
    x0 = np.log([base[k] for k in on])
    res = minimize(loss, x0, method="Nelder-Mead", options={"maxiter": 160, "xatol": 2e-3, "fatol": 1e-6})
    gg, cfg = cfg_of(res.x)
    r = F.evaluate(name, cfg, inp[name])
    sw = np.array(r["swing"][1:])
    out[name] = {k: float(v) for k, v in gg.items()}
    print(name, "loss %.4f" % res.fun, "gains", " ".join("%s %.3f" % (k, gg[k]) for k in F.KNOBS))
    print("   bands", ["%.2f" % b for b in r["bands"]], "shut %.2f" % r["shut"], "swing min %.2f (%.2fx shut)" % (np.nanmin(sw), np.nanmin(sw) / r["shut"]))
    json.dump(out, open(sys.argv[3], "w"), indent=1)
