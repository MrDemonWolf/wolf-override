"""Fix round 4 (M1): with each component's unit-gain measures (decomp), the least shut value the targets allow,
as a linear program over the gains (door g, ceiling e, fill f, pool p >= 0)."""
import json, sys, os
import numpy as np
from scipy.optimize import linprog
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fit as F
inp = json.load(open(sys.argv[1]))
for name in inp:
    comp = []
    for k in range(4):
        x = np.full(4, np.log(1e-12)); x[k] = 0.0
        comp.append(F.evaluate(name, F.config(name, x), inp[name]))
    B = np.array([c["bands"] for c in comp]).T          # 3 x 4
    SW = np.nan_to_num(np.array([c["swing"] for c in comp]).T)  # n x 4
    sh = SW[0]
    A, b = [], []
    for i in range(3):
        A.append(-B[i]); b.append(-0.65)
        A.append(B[i]); b.append(0.95)
    for j in range(1, len(SW)):
        A.append(sh - SW[j]); b.append(0.0)          # swing >= shut
        A.append(-SW[j]); b.append(-0.5)             # swing >= 0.5 wall
    A.append(-sh); b.append(-0.5)
    res = linprog(sh, A_ub=np.array(A), b_ub=np.array(b), bounds=[(0, None)] * 4)
    print(name, res.status, res.message[:40])
    if res.status == 0:
        g = res.x
        print("   gains door %.3f ceil %.3f fill %.3f pool %.3f -> shut/wall %.2f bands %s min swing %.2f" % (*g, sh @ g, np.round(B @ g, 2), (SW[1:] @ g).min()))
    print("   pool unit:", "bands", np.round(B[:, 3], 3), "shut %.3f" % sh[3], "swing", np.round(SW[::5, 3], 3))
