"""Fix round 4 (M1 follow-up): lift the ~10-degree dip (the room face turning out of the door light before the
lit cross-wall face beyond the hinge jamb reaches it) to the shut leaf's level. Records exit: the cross-wall-face
light x1.25 (its ceiling lamp is too far off to help); Records entry and junction entry: the room's ceiling lamp
x1.3. Writes the new gains and checks them on the software render every 2 degrees. Scratch only.
usage: dipfix.py INPUTS GAINS_IN GAINS_OUT"""
import json, sys, os
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fit as F
inp = json.load(open(sys.argv[1])); gains = json.load(open(sys.argv[2]))
LIFT = {"records-exit": ("wallb", 1.25), "records-entry": ("ceil", 1.3), "junction-entry": ("ceil", 1.3)}
out = {}
for name, g in gains.items():
    knob, k = LIFT[name]
    g2 = dict(g); g2[knob] = g[knob] * k
    out[name] = g2
    x = np.log(np.maximum([g2[q] for q in F.KNOBS], 1e-12))
    r = F.evaluate(name, F.config(name, x), inp[name])
    sw = np.array(r["swing"])
    print(name, knob, k, "bands", ["%.2f" % b for b in r["bands"]], "shut/wall %.2f" % r["shut"], "min/wall %.2f" % np.nanmin(sw), "min/shut %.3f at %d deg" % (np.nanmin(sw[1:]) / r["shut"], F.ANGLES[1:][np.nanargmin(sw[1:])] * 90), flush=True)
json.dump(out, open(sys.argv[3], "w"), indent=1)
