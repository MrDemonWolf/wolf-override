"""Fix round 4 (M1): the fitted gains on the full software render (fit.evaluate), every 2 degrees."""
import json, sys, os
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fit as F
inp = json.load(open(sys.argv[1])); gains = json.load(open(sys.argv[2]))
for name, g in gains.items():
    x = np.log(np.maximum([g[k] for k in F.KNOBS], 1e-12))
    r = F.evaluate(name, F.config(name, x), inp[name])
    sw = np.array(r["swing"])
    ok = ~np.isnan(sw)
    print(name, "bands", ["%.2f" % b for b in r["bands"]], "shut %.2f" % r["shut"], "min %.2f at %d deg" % (np.nanmin(sw[1:]), F.ANGLES[1:][np.nanargmin(sw[1:])] * 90),
          "min/shut %.2f" % (np.nanmin(sw[1:]) / r["shut"]))
    print("   swing", " ".join("%.2f" % s for s in sw[::3]))
