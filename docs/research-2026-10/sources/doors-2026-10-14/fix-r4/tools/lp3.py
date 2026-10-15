"""Fix round 4 (M1): unit-gain measures of each lit source (fit.KNOBS), then for a given shut value s (x the wall)
the gains that maximise the swing's lowest value with the open leaf near the hinge at LO-HI x the reveal."""
import json, sys, os
import numpy as np
from scipy.optimize import linprog
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fit as F
inp = json.load(open(sys.argv[1]))
lo, hi = 0.65, 0.95
use = sys.argv[2].split(",") if len(sys.argv) > 2 else F.KNOBS
res_all = {}
for name in inp:
    K = len(F.KNOBS)
    comp = []
    for k in range(K):
        x = np.full(K, np.log(1e-12)); x[k] = 0.0
        comp.append(F.evaluate(name, F.config(name, x), inp[name]))
    B = np.array([c["bands"] for c in comp]).T
    SW = np.array([c["swing"] for c in comp]).T
    seen = ~np.isnan(SW).any(1)
    print("   angles with no visible face (edge-on):", [int(a * 90) for a in F.ANGLES[~seen]])
    SW = SW[seen]
    sh = SW[0]
    res_all[name] = {"B": B.tolist(), "SW": SW.tolist()}
    print(name)
    for k, kn in enumerate(F.KNOBS):
        print("   %-6s bands %s shut %.3f swing %s" % (kn, np.round(B[:, k], 3), sh[k], np.round(SW[::5, k], 2)))
    bounds = [(0, None) if kn in use else (0, 0) for kn in F.KNOBS]
    for s in (0.6, 0.7, 0.8, 0.9, 1.0):
        A, b = [], []
        for i in range(3):
            A.append(list(-B[i]) + [0]); b.append(-lo)
            A.append(list(B[i]) + [0]); b.append(hi)
        for j in range(1, len(SW)):
            A.append(list(-SW[j]) + [1]); b.append(0.0)
        r = linprog([0] * K + [-1], A_ub=A, b_ub=b, A_eq=[list(sh) + [0]], b_eq=[s], bounds=bounds + [(None, None)])
        if r.status != 0:
            print("   shut %.1f: infeasible" % s); continue
        g = r.x[:K]; m = r.x[K]
        sw = SW @ g
        print("   shut %.1f: min swing %.2f (%.2fx shut); gains %s; bands %s" % (s, m, m / s, " ".join("%s %.2f" % (kn, v) for kn, v in zip(F.KNOBS, g)), np.round(B @ g, 2)))
json.dump(res_all, open("../decomp3.json", "w"))
