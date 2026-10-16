"""Fix round 4 (M1): each light component's share of the fit's measures (unit gain), to see what can meet the
targets (medians are near-additive on these smooth fields; the fit closes on full renders)."""
import json, sys, os
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fit as F
inp = json.load(open(sys.argv[1]))
NAMES = ["door", "ceil", "fill", "pool"]
for name in inp:
    rows = {}
    for k in range(4):
        x = np.full(4, np.log(1e-9)); x[k] = 0.0
        r = F.evaluate(name, F.config(name, x), inp[name])
        rows[NAMES[k]] = r
    print(name, "wall %.4f" % inp[name]["wall"], "reveal", ["%.4f" % b["reveal"] for b in inp[name]["bands"]])
    for k, r in rows.items():
        print("  %-5s bands %s shut %.3f swing(0,10,..90) %s" % (k, " ".join("%.3f" % b for b in r["bands"]), r["shut"], " ".join("%.3f" % s for s in r["swing"][::5])))
