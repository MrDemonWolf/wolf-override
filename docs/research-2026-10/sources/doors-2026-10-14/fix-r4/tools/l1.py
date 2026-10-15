"""Fix round 4 (M1): the gains on the linear model (decomp3.json from lp3.py) as an L1 linear program:
minimise |each band - 0.8| (x the reveal) + |shut - 0.7| (x the wall) + 0.02 x the made-up surfaces' gains, with
the bands at 0.68-0.92, the shut leaf at 0.55-0.85, the swing never below 0.95x the shut value nor 0.5x the wall,
the room's ambient fill at least a tenth of the shut value and the ceiling lamp at 1-5x round 3's.
usage: l1.py OUT_JSON"""
import json, sys, os
import numpy as np
from scipy.optimize import linprog
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fit as F
dec = json.load(open("../decomp3.json"))
R3E = {"records-exit": 0.082, "records-entry": 0.225, "junction-entry": 0.147}
# relaxed after feasibility checks (see DOORS.md round 4): the swing at or above 0.95x its shut value, the
# room's ambient fill at least a tenth of the shut value, the ceiling lamp at 1-5x round 3's
DIP, FILL_SHARE, CEIL_MAX = 0.95, 0.10, 5.0
out = {}
for name, d in dec.items():
    B = np.array(d["B"]); SW = np.array(d["SW"])
    SW = SW[~np.isnan(SW).any(1)]; sh = SW[0]
    K = len(F.KNOBS); ki = {k: i for i, k in enumerate(F.KNOBS)}
    # variables: g (K), e_band (3), e_shut (1)
    n = K + 4
    c = np.zeros(n); c[K:K + 4] = 1.0
    for k in ("pool", "thresh", "wallb"):
        c[ki[k]] = 0.02
    A, b = [], []
    def row(gpart, extra=None):
        r = np.zeros(n); r[:K] = gpart
        if extra:
            for i, v in extra.items():
                r[i] = v
        return r
    for i in range(3):
        A.append(row(B[i], {K + i: -1})); b.append(0.8)       # band - 0.8 <= e
        A.append(row(-B[i], {K + i: -1})); b.append(-0.8)     # 0.8 - band <= e
        A.append(row(-B[i])); b.append(-0.68)
        A.append(row(B[i])); b.append(0.92)
    A.append(row(sh, {K + 3: -1})); b.append(0.7)
    A.append(row(-sh, {K + 3: -1})); b.append(-0.7)
    A.append(row(-sh)); b.append(-0.55)
    A.append(row(sh)); b.append(0.85)
    for j in range(1, len(SW)):
        A.append(row(DIP * sh - SW[j])); b.append(0.0)
        A.append(row(-SW[j])); b.append(-0.5)
    fr = np.zeros(K); fr[ki["fill"]] = sh[ki["fill"]]
    A.append(row(FILL_SHARE * sh - fr)); b.append(0.0)
    bounds = [(0, None)] * n
    bounds[ki["ceil"]] = (R3E[name], CEIL_MAX * R3E[name])
    r = linprog(c, A_ub=np.array(A), b_ub=np.array(b), bounds=bounds)
    print(name, r.status, r.message[:50])
    if r.status != 0:
        continue
    g = r.x[:K]
    out[name] = dict(zip(F.KNOBS, map(float, g)))
    print("   gains", " ".join("%s %.3f" % (k, v) for k, v in out[name].items()))
    print("   bands", np.round(B @ g, 2), "shut %.2f" % (sh @ g), "swing min %.2f" % (SW[1:] @ g).min(), "fill share %.2f" % (g[ki['fill']] * sh[ki['fill']] / (sh @ g)))
json.dump(out, open(sys.argv[1], "w"), indent=1)
