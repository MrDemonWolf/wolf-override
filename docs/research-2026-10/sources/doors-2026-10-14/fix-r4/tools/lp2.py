"""Fix round 4 (M1): for a given shut value s (x the wall), the gains that maximise the swing's lowest value m
(x the wall) with the open leaf near the hinge at 0.65-0.95x the reveal in all three bands. Prints the curve
and the worst angles, per leaf."""
import json, sys, os
import numpy as np
from scipy.optimize import linprog
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fit as F
inp = json.load(open(sys.argv[1]))
lo, hi = float(sys.argv[2]) if len(sys.argv) > 2 else 0.65, float(sys.argv[3]) if len(sys.argv) > 3 else 0.95
out = {}
for name in inp:
    comp = []
    for k in range(4):
        x = np.full(4, np.log(1e-12)); x[k] = 0.0
        comp.append(F.evaluate(name, F.config(name, x), inp[name]))
    B = np.array([c["bands"] for c in comp]).T
    SW = np.nan_to_num(np.array([c["swing"] for c in comp]).T)
    sh = SW[0]
    out[name] = {"B": B.tolist(), "SW": SW.tolist()}
    print(name)
    for s in (0.6, 0.7, 0.8, 0.9, 1.0, 1.1):
        # variables g(4), m ; maximise m
        A, b = [], []
        for i in range(3):
            A.append(list(-B[i]) + [0]); b.append(-lo)
            A.append(list(B[i]) + [0]); b.append(hi)
        for j in range(1, len(SW)):
            A.append(list(-SW[j]) + [1]); b.append(0.0)
        res = linprog([0, 0, 0, 0, -1], A_ub=A, b_ub=b, A_eq=[list(sh) + [0]], b_eq=[s], bounds=[(0, None)] * 4 + [(None, None)])
        if res.status != 0:
            print("   shut %.1f: infeasible" % s); continue
        g = res.x[:4]; m = res.x[4]
        sw = SW @ g
        worst = np.argsort(sw[1:])[:3] + 1
        print("   shut %.1f: min swing %.2f (%.2fx shut) at %s deg; gains door %.2f ceil %.2f fill %.2f pool %.2f; bands %s" % (s, m, m / s, [int(F.ANGLES[w] * 90) for w in worst], *g, np.round(B @ g, 2)))
json.dump(out, open("../decomp.json", "w"))
